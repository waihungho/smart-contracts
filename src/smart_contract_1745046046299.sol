```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with Advanced Features
 * @author Gemini AI Assistant
 * @dev This contract implements a dynamic NFT marketplace with various advanced and creative functionalities.
 * It goes beyond typical marketplace features and incorporates elements like dynamic NFTs, staking, governance,
 * rentals, bundles, and more, aiming for a comprehensive and engaging NFT ecosystem.
 *
 * Function Summary:
 *
 * --- NFT Management ---
 * 1. mintDynamicNFT(string memory _baseMetadataURI): Mints a new dynamic NFT with an initial base metadata URI.
 * 2. updateBaseMetadataURI(uint256 _tokenId, string memory _newBaseMetadataURI): Updates the base metadata URI of a dynamic NFT.
 * 3. resolveDynamicMetadataURI(uint256 _tokenId): Resolves and returns the dynamic metadata URI for a given NFT, considering on-chain and off-chain factors.
 * 4. burnNFT(uint256 _tokenId): Burns (destroys) an NFT.
 * 5. batchMintDynamicNFT(string[] memory _baseMetadataURIs): Mints multiple dynamic NFTs in a single transaction.
 *
 * --- Marketplace Operations ---
 * 6. listItem(uint256 _tokenId, uint256 _price): Lists an NFT for sale on the marketplace.
 * 7. unlistItem(uint256 _tokenId): Removes an NFT listing from the marketplace.
 * 8. buyItem(uint256 _tokenId): Allows anyone to buy a listed NFT.
 * 9. offerItem(uint256 _tokenId, uint256 _price): Allows a user to make an offer on an NFT, even if not listed.
 * 10. acceptOffer(uint256 _offerId): Allows the NFT owner to accept a specific offer.
 * 11. cancelOffer(uint256 _offerId): Allows the offer maker to cancel their offer.
 * 12. setMarketplaceFee(uint256 _feePercentage): Sets the marketplace fee percentage (governance function).
 * 13. withdrawMarketplaceFees(): Allows the contract owner to withdraw accumulated marketplace fees.
 *
 * --- NFT Staking and Utility ---
 * 14. stakeNFT(uint256 _tokenId): Allows NFT owners to stake their NFTs for potential rewards or utility.
 * 15. unstakeNFT(uint256 _tokenId): Allows NFT owners to unstake their NFTs.
 * 16. calculateStakingReward(uint256 _tokenId): Calculates the staking reward for a given NFT (example reward mechanism).
 * 17. claimStakingReward(uint256 _tokenId): Allows users to claim their accumulated staking rewards.
 *
 * --- NFT Rentals ---
 * 18. rentNFT(uint256 _tokenId, uint256 _rentalDurationDays, uint256 _rentalFee): Allows NFT owners to rent out their NFTs for a specified duration and fee.
 * 19. endRental(uint256 _rentalId): Allows the renter or owner to end a rental agreement.
 * 20. getRentalDetails(uint256 _rentalId): Retrieves details of a specific NFT rental.
 *
 * --- Advanced Features ---
 * 21. createNFTBundle(uint256[] memory _tokenIds, string memory _bundleMetadataURI): Creates an NFT bundle by combining multiple NFTs into a new NFT.
 * 22. decomposeNFTBundle(uint256 _bundleId): Decomposes an NFT bundle back into its original component NFTs.
 * 23. setRoyalty(uint256 _tokenId, address _royaltyRecipient, uint256 _royaltyPercentage): Sets a royalty percentage for secondary sales of a specific NFT.
 * 24. batchSetRoyalties(uint256[] memory _tokenIds, address _royaltyRecipient, uint256 _royaltyPercentage): Sets royalties for multiple NFTs in a batch.
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicNFTMarketplace is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _rentalIdCounter;

    string public baseURI;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address public feeRecipient;

    // Mapping of token IDs to their base metadata URIs (for dynamic NFTs)
    mapping(uint256 => string) private _baseMetadataURIs;

    // Marketplace listings: tokenId => Listing struct
    mapping(uint256 => Listing) public listings;

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    // Offers on NFTs: offerId => Offer struct
    mapping(uint256 => Offer) public offers;

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        uint256 price;
        address buyer;
        bool isActive;
    }

    // NFT Staking: tokenId => Staking struct
    mapping(uint256 => StakingInfo) public stakingInfo;

    struct StakingInfo {
        uint256 tokenId;
        address staker;
        uint256 stakeStartTime;
        bool isStaked;
    }

    uint256 public stakingRewardRatePerDay = 1; // Example: 1 reward unit per day staked (adjust as needed)
    // Define your reward token or mechanism here (e.g., another ERC20 token, points system)
    // For simplicity, let's assume rewards are just tracked as "points" for now.
    mapping(address => uint256) public stakingRewards;

    // NFT Rentals: rentalId => Rental struct
    mapping(uint256 => Rental) public rentals;

    struct Rental {
        uint256 rentalId;
        uint256 tokenId;
        address owner;
        address renter;
        uint256 rentalStartTime;
        uint256 rentalEndTime;
        uint256 rentalFee;
        bool isActive;
    }

    // NFT Bundles: bundleId => Bundle struct
    mapping(uint256 => Bundle) public bundles;
    mapping(uint256 => uint256[]) public bundleComponents; // Mapping bundleId to array of component tokenIds
    Counters.Counter private _bundleIdCounter;

    struct Bundle {
        uint256 bundleId;
        address creator;
        string bundleMetadataURI;
        bool isActive; // To manage bundle status, e.g., if decomposed
    }

    // Royalty Information: tokenId => Royalty struct
    mapping(uint256 => Royalty) public royalties;

    struct Royalty {
        address recipient;
        uint256 percentage; // Royalty percentage (e.g., 500 for 5%)
    }

    event NFTMinted(uint256 tokenId, address minter, string baseMetadataURI);
    event MetadataURIUpdate(uint256 tokenId, string newBaseMetadataURI);
    event NFTBurned(uint256 tokenId, address burner);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTUnlisted(uint256 tokenId, address seller);
    event ItemBought(uint256 tokenId, uint256 price, address buyer, address seller);
    event OfferMade(uint256 offerId, uint256 tokenId, uint256 price, address buyer);
    event OfferAccepted(uint256 offerId, address seller, address buyer);
    event OfferCancelled(uint256 offerId, address canceller);
    event MarketplaceFeeSet(uint256 feePercentage, address setter);
    event FeesWithdrawn(uint256 amount, address recipient);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardClaimed(address staker, uint256 rewardAmount);
    event NFTRented(uint256 rentalId, uint256 tokenId, address owner, address renter, uint256 rentalFee, uint256 rentalEndTime);
    event RentalEnded(uint256 rentalId, address initiator);
    event NFTBundleCreated(uint256 bundleId, uint256[] tokenIds, address creator, string bundleMetadataURI);
    event NFTBundleDecomposed(uint256 bundleId, address decomposer);
    event RoyaltySet(uint256 tokenId, address recipient, uint256 percentage);
    event BatchRoyaltiesSet(uint256[] tokenIds, address recipient, uint256 percentage);

    constructor(string memory _baseURI, string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        feeRecipient = owner(); // Default fee recipient is contract owner
    }

    // --- NFT Management ---

    /**
     * @dev Mints a new dynamic NFT with an initial base metadata URI.
     * @param _baseMetadataURI The base URI for the NFT's metadata.
     */
    function mintDynamicNFT(string memory _baseMetadataURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _baseMetadataURIs[tokenId] = _baseMetadataURI;
        emit NFTMinted(tokenId, msg.sender, _baseMetadataURI);
    }

    /**
     * @dev Updates the base metadata URI of a dynamic NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _newBaseMetadataURI The new base URI for the NFT's metadata.
     */
    function updateBaseMetadataURI(uint256 _tokenId, string memory _newBaseMetadataURI) public onlyOwner {
        require(_exists(_tokenId), "NFT does not exist");
        _baseMetadataURIs[_tokenId] = _newBaseMetadataURI;
        emit MetadataURIUpdate(_tokenId, _newBaseMetadataURI);
    }

    /**
     * @dev Resolves and returns the dynamic metadata URI for a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return string The dynamic metadata URI.
     * @dev This function is a placeholder for more complex dynamic metadata resolution logic.
     *      In a real-world scenario, this could involve fetching data from oracles,
     *      performing on-chain calculations based on NFT properties or external events, etc.
     *      For now, it simply appends the token ID to the base URI.
     */
    function resolveDynamicMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        string memory baseUri = _baseMetadataURIs[_tokenId];
        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }

    /**
     * @dev Burns (destroys) an NFT. Only the owner of the NFT can burn it.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyOwnerOfToken(_tokenId) {
        _burn(_tokenId);
        emit NFTBurned(_tokenId, msg.sender);
    }

    /**
     * @dev Mints multiple dynamic NFTs in a single transaction.
     * @param _baseMetadataURIs An array of base metadata URIs for the NFTs to mint.
     */
    function batchMintDynamicNFT(string[] memory _baseMetadataURIs) public onlyOwner {
        for (uint256 i = 0; i < _baseMetadataURIs.length; i++) {
            mintDynamicNFT(_baseMetadataURIs[i]);
        }
    }

    // --- Marketplace Operations ---

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        _;
    }

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listItem(uint256 _tokenId, uint256 _price) public onlyOwnerOfToken(_tokenId) {
        require(_price > 0, "Price must be greater than zero");
        require(!listings[_tokenId].isListed, "NFT already listed");

        listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });

        _approveMarketplace(address(this), _tokenId); // Approve marketplace to transfer NFT

        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Removes an NFT listing from the marketplace.
     * @param _tokenId The ID of the NFT to unlist.
     */
    function unlistItem(uint256 _tokenId) public onlyOwnerOfToken(_tokenId) {
        require(listings[_tokenId].isListed, "NFT not listed");
        require(listings[_tokenId].seller == msg.sender, "Not listing owner");

        delete listings[_tokenId]; // Reset the listing struct to its default values
        emit NFTUnlisted(_tokenId, msg.sender);
    }

    /**
     * @dev Allows anyone to buy a listed NFT.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyItem(uint256 _tokenId) public payable nonReentrant {
        require(listings[_tokenId].isListed, "NFT not listed");
        require(msg.value >= listings[_tokenId].price, "Insufficient funds");

        Listing memory currentListing = listings[_tokenId];
        address seller = currentListing.seller;
        uint256 price = currentListing.price;

        delete listings[_tokenId]; // Remove listing after purchase

        // Calculate marketplace fee
        uint256 marketplaceFee = price.mul(marketplaceFeePercentage).div(1000); // Fee in basis points (1000 = 10%)
        uint256 sellerPayout = price.sub(marketplaceFee);

        // Transfer funds
        payable(seller).transfer(sellerPayout);
        payable(feeRecipient).transfer(marketplaceFee);

        // Transfer NFT
        _transfer(seller, msg.sender, _tokenId);

        emit ItemBought(_tokenId, price, msg.sender, seller);
    }

    /**
     * @dev Allows a user to make an offer on an NFT, even if it's not listed.
     * @param _tokenId The ID of the NFT to make an offer on.
     * @param _price The offer price in wei.
     */
    function offerItem(uint256 _tokenId, uint256 _price) public payable {
        require(_exists(_tokenId), "NFT does not exist");
        require(msg.value >= _price, "Insufficient funds for offer");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        offers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            price: _price,
            buyer: msg.sender,
            isActive: true
        });

        emit OfferMade(offerId, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows the NFT owner to accept a specific offer.
     * @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId) public payable onlyOwnerOfToken(offers[_offerId].tokenId) nonReentrant {
        require(offers[_offerId].isActive, "Offer is not active");
        require(offers[_offerId].tokenId == offers[_offerId].tokenId, "Invalid offer for this token"); // Redundant check, but good practice
        require(offers[_offerId].buyer != address(0), "Invalid buyer address in offer");

        Offer memory currentOffer = offers[_offerId];
        uint256 tokenId = currentOffer.tokenId;
        uint256 price = currentOffer.price;
        address buyer = currentOffer.buyer;

        offers[_offerId].isActive = false; // Mark offer as inactive

        // Calculate marketplace fee
        uint256 marketplaceFee = price.mul(marketplaceFeePercentage).div(1000);
        uint256 sellerPayout = price.sub(marketplaceFee);

        // Transfer funds
        payable(buyer).transfer(price); // Return offer amount to buyer (they paid when making the offer)
        payable(msg.sender).transfer(sellerPayout); // Send payout to seller
        payable(feeRecipient).transfer(marketplaceFee); // Send fee to recipient

        // Transfer NFT
        _transfer(msg.sender, buyer, tokenId); // Transfer NFT from seller to buyer

        emit OfferAccepted(_offerId, msg.sender, buyer);
    }

    /**
     * @dev Allows the offer maker to cancel their offer.
     * @param _offerId The ID of the offer to cancel.
     */
    function cancelOffer(uint256 _offerId) public {
        require(offers[_offerId].isActive, "Offer is not active");
        require(offers[_offerId].buyer == msg.sender, "Only offer maker can cancel");

        offers[_offerId].isActive = false; // Mark offer as inactive

        payable(msg.sender).transfer(offers[_offerId].price); // Return offer amount to buyer

        emit OfferCancelled(_offerId, msg.sender);
    }

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _feePercentage The new marketplace fee percentage (e.g., 200 for 2%). Basis points (1000 = 10%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 1000, "Fee percentage cannot exceed 10%"); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage, msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalanceWithoutFees = 0; // In a real system, track non-fee balance separately if needed.
        uint256 withdrawableFees = balance.sub(contractBalanceWithoutFees);

        require(withdrawableFees > 0, "No fees to withdraw");

        payable(owner()).transfer(withdrawableFees);
        emit FeesWithdrawn(withdrawableFees, owner());
    }

    // --- NFT Staking and Utility ---

    /**
     * @dev Allows NFT owners to stake their NFTs.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public onlyOwnerOfToken(_tokenId) {
        require(!stakingInfo[_tokenId].isStaked, "NFT already staked");

        stakingInfo[_tokenId] = StakingInfo({
            tokenId: _tokenId,
            staker: msg.sender,
            stakeStartTime: block.timestamp,
            isStaked: true
        });

        _approveMarketplace(address(this), _tokenId); // Approve marketplace to hold NFT during stake

        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows NFT owners to unstake their NFTs.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public nonReentrant {
        require(stakingInfo[_tokenId].isStaked, "NFT not staked");
        require(stakingInfo[_tokenId].staker == msg.sender, "Not staker");

        stakingInfo[_tokenId].isStaked = false; // Mark as unstaked

        // Calculate and potentially claim rewards upon unstaking (optional)
        uint256 reward = calculateStakingReward(_tokenId);
        stakingRewards[msg.sender] = stakingRewards[msg.sender].add(reward);
        emit StakingRewardClaimed(msg.sender, reward);


        // Transfer NFT back to owner
        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back from marketplace

        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Calculates the staking reward for a given NFT. Example reward mechanism.
     * @param _tokenId The ID of the NFT to calculate reward for.
     * @return uint256 The calculated staking reward.
     * @dev This is a simplified example. Reward mechanisms can be much more complex.
     */
    function calculateStakingReward(uint256 _tokenId) public view returns (uint256) {
        require(stakingInfo[_tokenId].isStaked, "NFT not staked");
        uint256 stakeDurationDays = (block.timestamp.sub(stakingInfo[_tokenId].stakeStartTime)) / (1 days);
        return stakeDurationDays.mul(stakingRewardRatePerDay); // Example: reward per day
    }

    /**
     * @dev Allows users to claim their accumulated staking rewards.
     * @param _tokenId The ID of a staked NFT (can claim for any staked NFT of user for simplicity).
     */
    function claimStakingReward(uint256 _tokenId) public nonReentrant {
        require(stakingInfo[_tokenId].isStaked && stakingInfo[_tokenId].staker == msg.sender, "Not your staked NFT");
        uint256 reward = calculateStakingReward(_tokenId);
        stakingRewards[msg.sender] = stakingRewards[msg.sender].add(reward); // Accumulate rewards. In real system, might transfer tokens.
        emit StakingRewardClaimed(msg.sender, reward);
    }

    // --- NFT Rentals ---

    /**
     * @dev Allows NFT owners to rent out their NFTs.
     * @param _tokenId The ID of the NFT to rent out.
     * @param _rentalDurationDays The duration of the rental in days.
     * @param _rentalFee The rental fee in wei.
     */
    function rentNFT(uint256 _tokenId, uint256 _rentalDurationDays, uint256 _rentalFee) public payable onlyOwnerOfToken(_tokenId) nonReentrant {
        require(_rentalDurationDays > 0 && _rentalFee > 0, "Invalid rental parameters");
        require(msg.value >= _rentalFee, "Insufficient rental fee provided");
        require(rentals[_rentalIdCounter.current()].isActive == false, "Previous rental must be ended before starting a new one"); // Basic check, improve rental management in real case

        _rentalIdCounter.increment();
        uint256 rentalId = _rentalIdCounter.current();

        rentals[rentalId] = Rental({
            rentalId: rentalId,
            tokenId: _tokenId,
            owner: msg.sender,
            renter: msg.sender, // In real case, renter would be different, fix logic if needed.
            rentalStartTime: block.timestamp,
            rentalEndTime: block.timestamp.add(_rentalDurationDays * 1 days),
            rentalFee: _rentalFee,
            isActive: true
        });

        _approveMarketplace(address(this), _tokenId); // Approve marketplace to hold NFT during rental

        // Transfer rental fee to NFT owner (or hold in escrow until rental end)
        payable(msg.sender).transfer(_rentalFee); // Owner gets fee upfront for simplicity

        emit NFTRented(rentalId, _tokenId, msg.sender, msg.sender, _rentalFee, rentals[rentalId].rentalEndTime); // renter should be msg.sender in real scenario
    }

    /**
     * @dev Allows the renter or owner to end a rental agreement.
     * @param _rentalId The ID of the rental to end.
     */
    function endRental(uint256 _rentalId) public nonReentrant {
        require(rentals[_rentalId].isActive, "Rental is not active");
        require(msg.sender == rentals[_rentalId].owner || msg.sender == rentals[_rentalId].renter, "Only owner or renter can end rental");
        require(block.timestamp >= rentals[_rentalId].rentalEndTime || msg.sender == rentals[_rentalId].owner, "Rental can only be ended after duration or by owner"); // Allow owner to end early

        rentals[_rentalId].isActive = false; // Mark rental as inactive

        // Transfer NFT back to owner
        _transfer(address(this), rentals[_rentalId].owner, rentals[_rentalId].tokenId); // Transfer NFT back from marketplace

        emit RentalEnded(_rentalId, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific NFT rental.
     * @param _rentalId The ID of the rental.
     * @return Rental The rental details struct.
     */
    function getRentalDetails(uint256 _rentalId) public view returns (Rental memory) {
        require(rentals[_rentalId].rentalId == _rentalId, "Invalid rental ID"); // Basic check, improve in real case
        return rentals[_rentalId];
    }

    // --- Advanced Features ---

    /**
     * @dev Creates an NFT bundle by combining multiple NFTs into a new NFT.
     * @param _tokenIds An array of token IDs to include in the bundle.
     * @param _bundleMetadataURI The metadata URI for the new bundle NFT.
     */
    function createNFTBundle(uint256[] memory _tokenIds, string memory _bundleMetadataURI) public onlyOwner {
        require(_tokenIds.length > 1, "Bundle must contain at least two NFTs");

        // Check ownership and transfer component NFTs to this contract
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not owner of component NFT");
            _transfer(msg.sender, address(this), _tokenIds[i]); // Transfer component NFTs to bundle contract
        }

        _bundleIdCounter.increment();
        uint256 bundleId = _bundleIdCounter.current();

        bundles[bundleId] = Bundle({
            bundleId: bundleId,
            creator: msg.sender,
            bundleMetadataURI: _bundleMetadataURI,
            isActive: true
        });
        bundleComponents[bundleId] = _tokenIds;

        _safeMint(msg.sender, bundleId); // Mint a new NFT representing the bundle
        emit NFTBundleCreated(bundleId, _tokenIds, msg.sender, _bundleMetadataURI);
    }

    /**
     * @dev Decomposes an NFT bundle back into its original component NFTs.
     * @param _bundleId The ID of the bundle to decompose.
     */
    function decomposeNFTBundle(uint256 _bundleId) public onlyOwnerOfToken(_bundleId) {
        require(bundles[_bundleId].isActive, "Bundle is not active");

        uint256[] memory componentTokenIds = bundleComponents[_bundleId];

        // Transfer component NFTs back to bundle owner
        for (uint256 i = 0; i < componentTokenIds.length; i++) {
            _transfer(address(this), msg.sender, componentTokenIds[i]); // Transfer component NFTs back to bundle owner
        }

        bundles[_bundleId].isActive = false; // Mark bundle as inactive
        _burn(_bundleId); // Burn the bundle NFT itself

        delete bundleComponents[_bundleId]; // Clean up component mapping

        emit NFTBundleDecomposed(_bundleId, msg.sender);
    }

    /**
     * @dev Sets a royalty percentage for secondary sales of a specific NFT.
     * @param _tokenId The ID of the NFT to set royalty for.
     * @param _royaltyRecipient The address to receive royalties.
     * @param _royaltyPercentage The royalty percentage (e.g., 500 for 5%). Basis points (1000 = 10%).
     */
    function setRoyalty(uint256 _tokenId, address _royaltyRecipient, uint256 _royaltyPercentage) public onlyOwnerOfToken(_tokenId) {
        require(_royaltyPercentage <= 1000, "Royalty percentage cannot exceed 10%"); // Example limit
        require(_royaltyRecipient != address(0), "Invalid royalty recipient address");
        royalties[_tokenId] = Royalty({
            recipient: _royaltyRecipient,
            percentage: _royaltyPercentage
        });
        emit RoyaltySet(_tokenId, _royaltyRecipient, _royaltyPercentage);
    }

    /**
     * @dev Sets royalties for multiple NFTs in a batch.
     * @param _tokenIds An array of token IDs to set royalties for.
     * @param _royaltyRecipient The address to receive royalties.
     * @param _royaltyPercentage The royalty percentage for all NFTs.
     */
    function batchSetRoyalties(uint256[] memory _tokenIds, address _royaltyRecipient, uint256 _royaltyPercentage) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            setRoyalty(_tokenIds[i], _royaltyRecipient, _royaltyPercentage);
        }
        emit BatchRoyaltiesSet(_tokenIds, _royaltyRecipient, _royaltyPercentage);
    }

    // --- Helper Functions ---

    /**
     * @dev Internal function to approve the marketplace contract to transfer an NFT.
     * @param _approvedAddress The address to approve.
     * @param _tokenId The ID of the NFT to approve for transfer.
     */
    function _approveMarketplace(address _approvedAddress, uint256 _tokenId) internal {
        ERC721.approve(_approvedAddress, _tokenId);
    }

    // Override _beforeTokenTransfer to handle royalties on transfers (example)
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && to != address(0)) { // Check if it's a transfer (not mint or burn)
            if (royalties[tokenId].recipient != address(0) && royalties[tokenId].percentage > 0) {
                uint256 salePrice;
                if (listings[tokenId].isListed && listings[tokenId].seller == from && to == msg.sender) {
                    salePrice = listings[tokenId].price; // Get price from listing if available
                } else if (offers[_offerIdCounter.current()].isActive && offers[_offerIdCounter.current()].buyer == to && offers[_offerIdCounter.current()].tokenId == tokenId) {
                    salePrice = offers[_offerIdCounter.current()].price; // Get price from offer if accepted
                } else {
                    // If price not easily determinable (e.g., direct transfer, external sale),
                    // you might need a more sophisticated price tracking mechanism or rely on external data.
                    // For simplicity, assuming no royalty if price not explicitly set in marketplace context here.
                    return; // Or handle differently based on your royalty implementation requirements.
                }

                uint256 royaltyAmount = salePrice.mul(royalties[tokenId].percentage).div(10000); // Royalty percentage (basis points, 10000 = 100%)
                uint256 transferAmount = salePrice.sub(royaltyAmount);

                payable(royalties[tokenId].recipient).transfer(royaltyAmount);
                // The rest of the sale amount (transferAmount) should be handled in the buyItem or acceptOffer functions.
            }
        }
    }

    // Override tokenURI to use dynamic metadata resolution
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return resolveDynamicMetadataURI(tokenId);
    }

    // Helper library for converting uint to string
    library Strings {
        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```