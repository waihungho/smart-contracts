```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This smart contract implements a decentralized marketplace for Dynamic NFTs,
 * incorporating advanced features like NFT evolution, on-chain randomness for mystery boxes,
 * reputation system, conditional sales, subscription-based access, and more.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Management & Dynamics:**
 *   - `mintDynamicNFT(string memory _baseURI, uint256 _initialLevel)`: Mints a new Dynamic NFT with an initial level and base URI.
 *   - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the metadata URI of an NFT (can be dynamic).
 *   - `evolveNFT(uint256 _tokenId)`: Allows NFT holders to evolve their NFTs to the next level (based on predefined criteria).
 *   - `getNFTLevel(uint256 _tokenId)`: Returns the current level of a Dynamic NFT.
 *   - `setEvolutionCriteria(uint256 _level, uint256 _requiredXP)`: Sets the experience points required to evolve to a specific level.
 *   - `grantXP(uint256 _tokenId, uint256 _xp)`: Grants experience points to an NFT, potentially triggering evolution.
 *
 * **2. Marketplace Core Functions:**
 *   - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *   - `buyNFT(uint256 _listingId)`: Allows anyone to purchase an NFT listed on the marketplace.
 *   - `cancelListing(uint256 _listingId)`: Allows the seller to cancel an NFT listing.
 *   - `getListingDetails(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 *   - `getAllListings()`: Returns a list of all active NFT listings.
 *   - `purchaseNFTWithSubscription(uint256 _listingId, uint256 _subscriptionMonths)`: Allows purchasing an NFT with a subscription period granting access to exclusive features.
 *
 * **3. Advanced & Creative Features:**
 *   - `createMysteryBox(string memory _mysteryBoxName, uint256[] memory _nftTokenIds, uint256[] memory _probabilities)`: Creates a mystery box containing a set of NFTs with associated probabilities.
 *   - `openMysteryBox(uint256 _mysteryBoxId)`: Allows users to open a mystery box and receive a random NFT based on probabilities.
 *   - `setConditionalSale(uint256 _listingId, address _conditionContract, bytes memory _conditionCalldata)`: Sets a condition that must be met before an NFT can be purchased from a listing (e.g., holding another NFT).
 *   - `fulfillConditionalSale(uint256 _listingId)`: Allows a buyer to fulfill the condition and purchase the NFT if conditions are met.
 *   - `stakeNFTForReputation(uint256 _tokenId)`: Allows users to stake their NFTs to gain reputation points within the marketplace.
 *   - `unstakeNFTForReputation(uint256 _tokenId)`: Allows users to unstake their NFTs and claim their reputation points.
 *   - `getRedemptionCode(uint256 _tokenId)`: Generates a unique, time-limited redemption code associated with an NFT for off-chain benefits (e.g., access to content).
 *   - `redeemCode(uint256 _redemptionCodeHash)`: Verifies and redeems a code, marking it as used and providing potential off-chain access.
 *
 * **4. Utility & Admin Functions:**
 *   - `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 *   - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 *   - `pauseMarketplace()`: Pauses core marketplace functionalities.
 *   - `unpauseMarketplace()`: Resumes marketplace functionalities.
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---

    string public contractName = "Dynamic NFT Marketplace";

    // NFT Contract Address (assuming an external ERC721 or similar contract)
    address public nftContractAddress;

    // Marketplace Fee Percentage (e.g., 200 for 2%)
    uint256 public marketplaceFeePercentage = 200; // Default 2%

    // Contract Owner
    address public owner;

    // Listing struct
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
        address conditionContract; // Address of the condition contract (if any)
        bytes conditionCalldata;     // Calldata for condition verification
        bool conditionFulfilled;     // Flag if the condition is fulfilled
        uint256 subscriptionMonths; // Optional subscription period
    }

    // Mapping of listing IDs to Listing structs
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId = 1;
    uint256 public listingCount = 0;

    // Dynamic NFT level mapping
    mapping(uint256 => uint256) public nftLevels;
    mapping(uint256 => uint256) public nftExperiencePoints;
    mapping(uint256 => uint256) public evolutionCriteria; // Level => Required XP

    // Mystery Box struct
    struct MysteryBox {
        uint256 mysteryBoxId;
        string name;
        uint256[] nftTokenIds;
        uint256[] probabilities; // Probabilities (out of 10000, e.g., 1000 = 10%)
        bool isOpen;
    }
    mapping(uint256 => MysteryBox) public mysteryBoxes;
    uint256 public nextMysteryBoxId = 1;

    // Reputation Points mapping
    mapping(address => uint256) public reputationPoints;
    mapping(uint256 => uint256) public nftStakers; // tokenId => timestamp of staking

    // Redemption Codes (Hash of code => isRedeemed)
    mapping(bytes32 => bool) public redemptionCodes;
    mapping(bytes32 => uint256) public redemptionCodeTimestamps; // Hash of code => timestamp of generation
    uint256 public redemptionCodeValidityPeriod = 7 days; // Codes valid for 7 days

    // Paused State
    bool public paused = false;

    // --- Events ---
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event DynamicNFTMinted(uint256 tokenId, address minter, string baseURI, uint256 initialLevel);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadata);
    event NFTEvolved(uint256 tokenId, uint256 newLevel);
    event XPGranted(uint256 tokenId, uint256 xpAmount);
    event MysteryBoxCreated(uint256 mysteryBoxId, string name, uint256[] nftTokenIds);
    event MysteryBoxOpened(uint256 mysteryBoxId, address opener, uint256 awardedTokenId);
    event ConditionalSaleSet(uint256 listingId, address conditionContract, bytes conditionCalldata);
    event ConditionalSaleFulfilled(uint256 listingId, address buyer);
    event NFTStakedForReputation(uint256 tokenId, address staker);
    event NFTUnstakedFromReputation(uint256 tokenId, address unstaker);
    event RedemptionCodeGenerated(bytes32 codeHash, uint256 tokenId);
    event RedemptionCodeRedeemed(bytes32 codeHash, address redeemer);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event FeesWithdrawn(address owner, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    // --- Constructor ---
    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
        // Set default evolution criteria (Level 2 requires 100 XP, Level 3 requires 300 XP, etc.)
        evolutionCriteria[2] = 100;
        evolutionCriteria[3] = 300;
        evolutionCriteria[4] = 700;
        evolutionCriteria[5] = 1500;
    }

    // --- 1. NFT Management & Dynamics ---

    /**
     * @dev Mints a new Dynamic NFT.
     * @param _baseURI Base URI for the NFT metadata.
     * @param _initialLevel Initial level of the NFT (default 1).
     */
    function mintDynamicNFT(string memory _baseURI, uint256 _initialLevel) public whenNotPaused returns (uint256 tokenId) {
        // Assume external NFT contract has a mint function, e.g., mintTo(address recipient, string memory _uri)
        // For simplicity, we'll just simulate minting and tracking level here.
        // In a real implementation, you'd interact with your NFT contract.
        tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, totalSupply()))); // Simple tokenId generation
        nftLevels[tokenId] = _initialLevel == 0 ? 1 : _initialLevel; // Default to level 1 if 0 is provided
        // In a real implementation, call nftContract.mintTo(msg.sender, _baseURI);
        emit DynamicNFTMinted(tokenId, msg.sender, _baseURI, nftLevels[tokenId]);
        return tokenId;
    }

    function totalSupply() private pure returns (uint256) {
        // In a real implementation, this would query your NFT contract's totalSupply() or equivalent.
        // For this example, we'll just return a placeholder (not truly accurate).
        return block.number % 10000; // Placeholder - Replace with actual NFT contract logic
    }

    /**
     * @dev Updates the metadata URI of a Dynamic NFT.
     * @param _tokenId ID of the NFT to update.
     * @param _newMetadata New metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public whenNotPaused {
        // Check ownership (or allow contract owner to update metadata - depending on design)
        // For simplicity, allowing anyone to update for demonstration purposes.
        // In a real implementation, restrict access based on ownership or roles.
        // In a real implementation, you'd call nftContract.setTokenURI(_tokenId, _newMetadata);
        emit NFTMetadataUpdated(_tokenId, _newMetadata);
    }

    /**
     * @dev Allows NFT holders to evolve their NFTs to the next level.
     * @param _tokenId ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused {
        require(isNFTOwner(msg.sender, _tokenId), "Not NFT owner.");
        uint256 currentLevel = nftLevels[_tokenId];
        uint256 requiredXP = evolutionCriteria[currentLevel + 1]; // Get XP for next level
        require(requiredXP > 0, "Max level reached or evolution criteria not set for next level.");
        require(nftExperiencePoints[_tokenId] >= requiredXP, "Not enough experience points to evolve.");

        nftLevels[_tokenId]++;
        nftExperiencePoints[_tokenId] -= requiredXP; // Deduct XP used for evolution
        emit NFTEvolved(_tokenId, nftLevels[_tokenId]);
        // Optionally update NFT metadata to reflect level change here.
    }

    /**
     * @dev Returns the current level of a Dynamic NFT.
     * @param _tokenId ID of the NFT.
     * @return Current level of the NFT.
     */
    function getNFTLevel(uint256 _tokenId) public view returns (uint256) {
        return nftLevels[_tokenId];
    }

    /**
     * @dev Sets the experience points required to evolve to a specific level.
     * @param _level Level number.
     * @param _requiredXP Experience points required.
     */
    function setEvolutionCriteria(uint256 _level, uint256 _requiredXP) public onlyOwner {
        evolutionCriteria[_level] = _requiredXP;
    }

    /**
     * @dev Grants experience points to an NFT, potentially triggering evolution.
     * @param _tokenId ID of the NFT.
     * @param _xp Experience points to grant.
     */
    function grantXP(uint256 _tokenId, uint256 _xp) public whenNotPaused {
        // Example: Only marketplace owner or authorized entities can grant XP
        require(msg.sender == owner, "Only authorized entities can grant XP.");

        nftExperiencePoints[_tokenId] += _xp;
        emit XPGranted(_tokenId, _xp);

        // Automatically trigger evolution if criteria are met
        uint256 currentLevel = nftLevels[_tokenId];
        uint256 requiredXP = evolutionCriteria[currentLevel + 1];
        if (requiredXP > 0 && nftExperiencePoints[_tokenId] >= requiredXP) {
            evolveNFT(_tokenId); // Auto-evolve if conditions are met
        }
    }

    // --- 2. Marketplace Core Functions ---

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId ID of the NFT to list.
     * @param _price Sale price in Wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(isNFTOwner(msg.sender, _tokenId), "Not NFT owner.");
        require(_price > 0, "Price must be greater than zero.");

        // In a real implementation, you'd need to handle NFT approval/transferFrom logic from the NFT contract.
        // For simplicity, assuming ownership check is sufficient for demonstration.

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true,
            conditionContract: address(0), // No conditional sale by default
            conditionCalldata: bytes(""),
            conditionFulfilled: true, // No condition, so always fulfilled
            subscriptionMonths: 0 // No subscription by default
        });
        emit NFTListed(nextListingId, _tokenId, msg.sender, _price);
        nextListingId++;
        listingCount++;
    }

    /**
     * @dev Allows anyone to purchase an NFT listed on the marketplace.
     * @param _listingId ID of the listing to purchase.
     */
    function buyNFT(uint256 _listingId) public payable whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(msg.value >= listing.price, "Insufficient payment.");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");
        require(listing.conditionFulfilled, "Conditional sale not fulfilled.");

        // Transfer NFT to buyer (In real implementation, call nftContract.transferFrom(seller, buyer, tokenId))
        // For simplicity, just updating ownership tracking here.
        // In a real implementation, you'd integrate with your NFT contract.

        // Calculate marketplace fee
        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 10000;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        // Transfer proceeds to seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer marketplace fee to contract owner
        payable(owner).transfer(marketplaceFee);

        listing.isActive = false; // Mark listing as inactive
        listingCount--;

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    /**
     * @dev Allows the seller to cancel an NFT listing.
     * @param _listingId ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) public whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only seller can cancel listing.");

        listing.isActive = false; // Mark listing as inactive
        listingCount--;
        emit ListingCancelled(_listingId, listing.tokenId, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _listingId ID of the listing.
     * @return Listing details.
     */
    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @dev Returns a list of all active NFT listings.
     * @return Array of active listing IDs.
     */
    function getAllListings() public view returns (uint256[] memory) {
        uint256[] memory activeListings = new uint256[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive) {
                activeListings[index] = i;
                index++;
            }
        }
        return activeListings;
    }

    /**
     * @dev Allows purchasing an NFT with a subscription period granting access to exclusive features.
     * @param _listingId ID of the listing to purchase.
     * @param _subscriptionMonths Number of subscription months.
     */
    function purchaseNFTWithSubscription(uint256 _listingId, uint256 _subscriptionMonths) public payable whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(msg.value >= listing.price, "Insufficient payment.");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");
        require(listing.conditionFulfilled, "Conditional sale not fulfilled.");
        require(_subscriptionMonths > 0 && _subscriptionMonths <= 24, "Subscription months must be between 1 and 24.");

        // Transfer NFT, calculate fees, transfer funds (same as buyNFT) - omitted for brevity.

        listing.isActive = false;
        listing.subscriptionMonths = _subscriptionMonths; // Record subscription period
        listingCount--;

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
        // In a real application, you would likely trigger off-chain processes to manage subscription access.
    }


    // --- 3. Advanced & Creative Features ---

    /**
     * @dev Creates a mystery box containing a set of NFTs with probabilities.
     * @param _mysteryBoxName Name of the mystery box.
     * @param _nftTokenIds Array of NFT token IDs in the box.
     * @param _probabilities Array of probabilities for each NFT (out of 10000).
     */
    function createMysteryBox(string memory _mysteryBoxName, uint256[] memory _nftTokenIds, uint256[] memory _probabilities) public onlyOwner {
        require(_nftTokenIds.length == _probabilities.length, "Token IDs and probabilities arrays must have the same length.");
        require(_nftTokenIds.length > 0, "Mystery box must contain at least one NFT.");
        uint256 totalProbability = 0;
        for (uint256 i = 0; i < _probabilities.length; i++) {
            totalProbability += _probabilities[i];
        }
        require(totalProbability <= 10000, "Total probability cannot exceed 10000.");

        mysteryBoxes[nextMysteryBoxId] = MysteryBox({
            mysteryBoxId: nextMysteryBoxId,
            name: _mysteryBoxName,
            nftTokenIds: _nftTokenIds,
            probabilities: _probabilities,
            isOpen: false
        });
        emit MysteryBoxCreated(nextMysteryBoxId, _mysteryBoxName, _nftTokenIds);
        nextMysteryBoxId++;
    }

    /**
     * @dev Allows users to open a mystery box and receive a random NFT based on probabilities.
     * @param _mysteryBoxId ID of the mystery box to open.
     */
    function openMysteryBox(uint256 _mysteryBoxId) public whenNotPaused returns (uint256 awardedTokenId) {
        MysteryBox storage box = mysteryBoxes[_mysteryBoxId];
        require(!box.isOpen, "Mystery box already opened.");
        require(box.nftTokenIds.length > 0, "Mystery box is empty.");

        uint256 randomNumber = generateRandomNumber(); // Get on-chain randomness (using Chainlink VRF or similar in production)
        uint256 probabilitySum = 0;
        uint256 selectedIndex = 0;

        for (uint256 i = 0; i < box.probabilities.length; i++) {
            probabilitySum += box.probabilities[i];
            if (randomNumber <= probabilitySum) {
                selectedIndex = i;
                break;
            }
        }

        awardedTokenId = box.nftTokenIds[selectedIndex];
        box.isOpen = true; // Mark box as opened

        // In a real implementation, transfer the awarded NFT to the opener (nftContract.transferFrom from box owner to opener)
        // For simplicity, just emitting event and returning token ID.
        emit MysteryBoxOpened(_mysteryBoxId, msg.sender, awardedTokenId);
        return awardedTokenId;
    }

    function generateRandomNumber() private view returns (uint256) {
        // In a real production environment, use Chainlink VRF or a secure on-chain randomness solution.
        // This is a VERY insecure placeholder for demonstration purposes ONLY.
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 10000;
    }

    /**
     * @dev Sets a condition that must be met before an NFT can be purchased from a listing.
     * @param _listingId ID of the listing.
     * @param _conditionContract Address of the contract to verify the condition.
     * @param _conditionCalldata Calldata to pass to the condition contract's verification function.
     */
    function setConditionalSale(uint256 _listingId, address _conditionContract, bytes memory _conditionCalldata) public whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only seller can set conditional sale.");
        require(_conditionContract != address(0), "Condition contract address cannot be zero.");

        listing.conditionContract = _conditionContract;
        listing.conditionCalldata = _conditionCalldata;
        listing.conditionFulfilled = false; // Condition needs to be fulfilled
        emit ConditionalSaleSet(_listingId, _conditionContract, _conditionCalldata);
    }

    /**
     * @dev Allows a buyer to fulfill the condition and purchase the NFT if conditions are met.
     * @param _listingId ID of the listing with a conditional sale.
     */
    function fulfillConditionalSale(uint256 _listingId) public whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(!listing.conditionFulfilled, "Conditional sale already fulfilled.");
        require(listing.conditionContract != address(0), "No conditional sale set for this listing.");

        // Call the condition contract and verify if condition is met.
        (bool conditionMet,) = listing.conditionContract.call(listing.conditionCalldata);
        require(conditionMet, "Condition not met.");

        listing.conditionFulfilled = true; // Mark condition as fulfilled
        emit ConditionalSaleFulfilled(_listingId, msg.sender);
    }

    /**
     * @dev Allows users to stake their NFTs to gain reputation points within the marketplace.
     * @param _tokenId ID of the NFT to stake.
     */
    function stakeNFTForReputation(uint256 _tokenId) public whenNotPaused {
        require(isNFTOwner(msg.sender, _tokenId), "Not NFT owner.");
        require(nftStakers[_tokenId] == 0, "NFT already staked."); // Prevent double staking

        nftStakers[_tokenId] = block.timestamp; // Record staking timestamp
        reputationPoints[msg.sender] += 10; // Example: +10 reputation points for staking
        emit NFTStakedForReputation(_tokenId, msg.sender);
        // In a real implementation, consider locking the NFT (e.g., using ERC721's safeTransferFrom and transferring to this contract).
    }

    /**
     * @dev Allows users to unstake their NFTs and claim their reputation points.
     * @param _tokenId ID of the NFT to unstake.
     */
    function unstakeNFTForReputation(uint256 _tokenId) public whenNotPaused {
        require(isNFTOwner(msg.sender, _tokenId), "Not NFT owner.");
        require(nftStakers[_tokenId] != 0, "NFT is not staked.");

        delete nftStakers[_tokenId]; // Remove staking record
        reputationPoints[msg.sender] += 5; // Example: Bonus +5 reputation points for unstaking (could be time-based rewards)
        emit NFTUnstakedFromReputation(_tokenId, msg.sender);
        // In a real implementation, transfer the NFT back to the owner (nftContract.safeTransferFrom from this contract to owner).
    }

    /**
     * @dev Generates a unique, time-limited redemption code associated with an NFT for off-chain benefits.
     * @param _tokenId ID of the NFT.
     * @return Redemption code (for off-chain use).
     */
    function getRedemptionCode(uint256 _tokenId) public whenNotPaused returns (string memory redemptionCode) {
        require(isNFTOwner(msg.sender, _tokenId), "Not NFT owner.");

        // Generate a unique code (using a more robust method in production)
        redemptionCode = string(abi.encodePacked("REDEEM-", block.timestamp, msg.sender, _tokenId));
        bytes32 codeHash = keccak256(bytes(redemptionCode));

        require(!redemptionCodes[codeHash], "Redemption code already generated for this NFT recently.");

        redemptionCodes[codeHash] = false; // Mark as not redeemed yet
        redemptionCodeTimestamps[codeHash] = block.timestamp; // Record generation timestamp
        emit RedemptionCodeGenerated(codeHash, _tokenId);
        return redemptionCode;
    }

    /**
     * @dev Verifies and redeems a code, marking it as used and providing potential off-chain access.
     * @param _redemptionCodeHash Hash of the redemption code (received off-chain).
     */
    function redeemCode(bytes32 _redemptionCodeHash) public whenNotPaused {
        require(redemptionCodes[_redemptionCodeHash] == false, "Invalid or already redeemed code.");
        require(block.timestamp <= redemptionCodeTimestamps[_redemptionCodeHash] + redemptionCodeValidityPeriod, "Redemption code expired.");

        redemptionCodes[_redemptionCodeHash] = true; // Mark code as redeemed
        emit RedemptionCodeRedeemed(_redemptionCodeHash, msg.sender);
        // In a real application, trigger off-chain processes to grant access based on redemption.
    }


    // --- 4. Utility & Admin Functions ---

    /**
     * @dev Sets the marketplace fee percentage.
     * @param _feePercentage New fee percentage (e.g., 200 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FeesWithdrawn(owner, balance);
    }

    /**
     * @dev Pauses core marketplace functionalities.
     */
    function pauseMarketplace() public onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Resumes marketplace functionalities.
     */
    function unpauseMarketplace() public onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Checks if an address is the owner of an NFT.
     * @param _address Address to check.
     * @param _tokenId ID of the NFT.
     * @return True if the address is the owner, false otherwise.
     */
    function isNFTOwner(address _address, uint256 _tokenId) internal view returns (bool) {
        // In a real implementation, query your NFT contract's ownerOf(_tokenId) function.
        // For simplicity, we are just assuming the caller is the owner for demonstration.
        // **IMPORTANT: Replace this with actual NFT contract interaction in production.**
        return true; // Placeholder - Replace with NFT contract owner check.
    }

    // --- Fallback and Receive (for fee collection) ---
    receive() external payable {}
    fallback() external payable {}
}
```

**Explanation of Advanced Concepts and Creative Functions:**

1.  **Dynamic NFTs (`mintDynamicNFT`, `updateNFTMetadata`, `evolveNFT`, `getNFTLevel`, `setEvolutionCriteria`, `grantXP`):**
    *   NFTs are not static. They can evolve and change over time.
    *   `nftLevels` and `nftExperiencePoints` track the progression of NFTs.
    *   `evolveNFT` function allows NFTs to level up based on `evolutionCriteria`.
    *   `grantXP` function can be used to reward NFT holders with experience, leading to evolution.
    *   `updateNFTMetadata` allows for changing the NFT's metadata URI, potentially reflecting its level or other dynamic attributes.

2.  **Mystery Boxes (`createMysteryBox`, `openMysteryBox`):**
    *   Introduces gamification and chance into the marketplace.
    *   `createMysteryBox` allows the contract owner to create boxes containing different NFTs with specified probabilities.
    *   `openMysteryBox` uses a pseudo-random number generation (replace with Chainlink VRF in production for security) to determine which NFT a user receives.

3.  **Conditional Sales (`setConditionalSale`, `fulfillConditionalSale`):**
    *   Adds flexibility to NFT listings.
    *   `setConditionalSale` allows sellers to specify conditions (via an external contract and calldata) that buyers must meet before purchasing.
    *   `fulfillConditionalSale` allows buyers to trigger the condition check and purchase if met. This could be used for whitelisting, requiring ownership of another NFT, or other complex conditions.

4.  **Reputation System (`stakeNFTForReputation`, `unstakeNFTForReputation`, `reputationPoints`):**
    *   Encourages user engagement and community participation.
    *   `stakeNFTForReputation` allows users to stake their NFTs to earn reputation points.
    *   `unstakeNFTForReputation` allows unstaking and potentially rewards users further.
    *   `reputationPoints` can be used for various purposes within the marketplace (e.g., access to exclusive features, voting rights, discounts).

5.  **Redemption Codes (`getRedemptionCode`, `redeemCode`, `redemptionCodes`, `redemptionCodeTimestamps`):**
    *   Bridges the gap between NFTs and off-chain benefits/experiences.
    *   `getRedemptionCode` generates unique, time-limited codes associated with NFTs.
    *   `redeemCode` verifies and redeems these codes, allowing NFT holders to access off-chain content, events, or services linked to their NFTs.
    *   The codes are time-limited using `redemptionCodeValidityPeriod`.

6.  **Subscription-Based NFT Purchase (`purchaseNFTWithSubscription`):**
    *   Combines NFT ownership with subscription models.
    *   `purchaseNFTWithSubscription` allows users to buy an NFT and simultaneously subscribe for a certain period, granting access to exclusive features or content related to the NFT for the subscription duration.

7.  **Marketplace Pausing (`pauseMarketplace`, `unpauseMarketplace`):**
    *   Provides an emergency brake for the contract owner to temporarily halt marketplace activity in case of issues or upgrades.

8.  **Marketplace Fee Management (`setMarketplaceFee`, `withdrawMarketplaceFees`):**
    *   Standard marketplace functionality to manage fees collected from sales.

**Important Notes:**

*   **Security:** This is an example contract for demonstrating concepts. **It is not audited and should NOT be used in production without thorough security review and testing.**  Specifically, the random number generation in `generateRandomNumber` is insecure and needs to be replaced with a secure solution like Chainlink VRF for production.
*   **NFT Contract Interaction:**  This contract assumes interaction with an external NFT contract (ERC721 or similar). The `isNFTOwner` function and comments indicate where you would need to integrate with your actual NFT contract (e.g., using `IERC721` interface and calling `ownerOf` and `transferFrom`).  The minting logic is also simplified and needs to be adapted to your specific NFT contract's minting function.
*   **Gas Optimization:** This contract is written for clarity and demonstration of features, not necessarily for extreme gas optimization. In a production environment, you would need to optimize gas usage.
*   **Error Handling and User Experience:** More robust error handling, input validation, and user-friendly events would be needed for a real-world application.
*   **Off-Chain Integration:** Features like redemption codes and subscriptions often require off-chain components to manage access and benefits based on on-chain events. This contract provides the on-chain logic, but off-chain systems would need to be built to complement it.
*   **Conditional Sales Implementation:** The `setConditionalSale` and `fulfillConditionalSale` functions provide a framework. The actual condition contract and calldata would need to be designed based on the specific conditional logic you want to implement.

This example provides a starting point for building a more complex and feature-rich decentralized NFT marketplace with innovative functionalities beyond basic listing and selling. Remember to prioritize security, thorough testing, and user experience in any real-world deployment.