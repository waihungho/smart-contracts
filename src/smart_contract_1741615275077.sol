```solidity
/**
 * @title Dynamic Skill Badge NFT Lending Platform with Reputation System
 * @author Gemini AI
 * @dev A smart contract that implements a dynamic NFT for skill badges,
 *      combined with a lending platform and a reputation system.
 *      NFTs can level up based on on-chain activity, and can be lent/borrowed.
 *      Reputation is built based on lending/borrowing history and affects lending terms.
 *
 * **Outline:**
 *
 * **Contracts:**
 *   - `SkillBadgeNFT`: ERC721 contract for Skill Badges with dynamic levels.
 *   - `SkillBadgeLendingPlatform`: Core contract for lending, borrowing, and reputation.
 *
 * **Function Summary (SkillBadgeNFT):**
 *   1. `mintSkillBadge(address _to, string memory _skillName)`: Mints a new Skill Badge NFT to a user. (Admin only)
 *   2. `levelUpSkillBadge(uint256 _tokenId)`: Increases the level of a Skill Badge based on some criteria (simulated here). (Admin/Internal)
 *   3. `getSkillBadgeLevel(uint256 _tokenId)`: Returns the current level of a Skill Badge. (View)
 *   4. `setBaseURI(string memory _newBaseURI)`: Sets the base URI for NFT metadata. (Admin only)
 *
 * **Function Summary (SkillBadgeLendingPlatform):**
 *   5. `setSkillBadgeContractAddress(address _skillBadgeContractAddress)`: Sets the address of the SkillBadgeNFT contract. (Admin only)
 *   6. `listNFTForLending(uint256 _tokenId, uint256 _lendingRatePerDay, uint256 _minLendingDuration)`: Allows NFT owner to list their Skill Badge for lending.
 *   7. `unlistNFTForLending(uint256 _tokenId)`: Allows NFT owner to unlist their Skill Badge from lending.
 *   8. `lendNFT(uint256 _tokenId, uint256 _lendingDuration)`: Allows a user to borrow a listed Skill Badge for a specified duration.
 *   9. `returnNFT(uint256 _tokenId)`: Allows a borrower to return a borrowed Skill Badge before the due time.
 *   10. `claimLendingFees(uint256 _tokenId)`: Allows the lender to claim accumulated lending fees after the lending period.
 *   11. `getNFTLendingInfo(uint256 _tokenId)`: Returns information about the lending status of a specific NFT. (View)
 *   12. `getUserReputation(address _user)`: Returns the reputation score of a user. (View)
 *   13. `updateReputation(address _user, int256 _reputationChange)`: Updates the reputation score of a user. (Internal/Admin, but logic is triggered by lending events)
 *   14. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for lending. (Admin only)
 *   15. `withdrawPlatformFees()`: Allows the admin to withdraw accumulated platform fees. (Admin only)
 *   16. `setBaseLendingRateMultiplier(uint256 _multiplier)`: Sets a base multiplier for lending rates, adjustable by admin. (Admin only)
 *   17. `setMinReputationForBorrowing(uint256 _minReputation)`: Sets the minimum reputation required to borrow NFTs. (Admin Only)
 *   18. `pauseContract()`: Pauses the lending platform contract, disabling lending/borrowing. (Admin Only)
 *   19. `unpauseContract()`: Unpauses the lending platform contract. (Admin Only)
 *   20. `isContractPaused()`: Checks if the contract is currently paused. (View)
 *   21. `getPlatformBalance()`: Returns the current balance of the platform contract. (View)
 *   22. `getUserLendingHistory(address _user)`: Returns a list of token IDs borrowed or lent by a user. (View)
 *   23. `setAdmin(address _newAdmin)`: Changes the admin of the contract. (Admin Only)
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ----------------------------------------------------------------------------
// SkillBadgeNFT Contract
// ----------------------------------------------------------------------------
contract SkillBadgeNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseURI;
    mapping(uint256 => uint256) public skillBadgeLevels; // TokenId => Level
    mapping(uint256 => string) public skillNames; // TokenId => Skill Name

    constructor(string memory _name, string memory _symbol, string memory baseURI) ERC721(_name, _symbol) {
        _baseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Sets the base URI for all token metadata. Only callable by the contract owner.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI = _newBaseURI;
    }

    /**
     * @dev Mints a new Skill Badge NFT to the specified address. Only callable by the contract owner.
     * @param _to The address to mint the NFT to.
     * @param _skillName The name of the skill for this badge.
     * @return The tokenId of the minted NFT.
     */
    function mintSkillBadge(address _to, string memory _skillName) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        skillBadgeLevels[newItemId] = 1; // Initial level is 1
        skillNames[newItemId] = _skillName;
        return newItemId;
    }

    /**
     * @dev Increases the level of a Skill Badge NFT. Can be triggered by the contract owner or internal logic.
     * @param _tokenId The ID of the Skill Badge NFT to level up.
     */
    function levelUpSkillBadge(uint256 _tokenId) public onlyOwner { // Example: Owner initiated level up
        require(_exists(_tokenId), "SkillBadgeNFT: Token does not exist");
        skillBadgeLevels[_tokenId]++;
        // In a real application, level up logic might be based on on-chain actions, oracle data, etc.
        // For example, track user activity related to the skill and level up automatically.
    }

    /**
     * @dev Gets the current level of a Skill Badge NFT.
     * @param _tokenId The ID of the Skill Badge NFT.
     * @return The level of the Skill Badge.
     */
    function getSkillBadgeLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "SkillBadgeNFT: Token does not exist");
        return skillBadgeLevels[_tokenId];
    }

    // Supports Interface - for NFT marketplaces and standards
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// ----------------------------------------------------------------------------
// SkillBadgeLendingPlatform Contract
// ----------------------------------------------------------------------------
contract SkillBadgeLendingPlatform is Ownable, Pausable {
    using Counters for Counters.Counter;

    address public skillBadgeContractAddress;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public baseLendingRateMultiplier = 100; // Base multiplier for lending rate calculation
    uint256 public minReputationForBorrowing = 0; // Minimum reputation to borrow

    struct LendingListing {
        uint256 tokenId;
        address lender;
        uint256 lendingRatePerDay; // in wei per day
        uint256 minLendingDuration; // in days
        uint256 listingTime;
        bool isActive;
    }

    struct LendingAgreement {
        uint256 tokenId;
        address borrower;
        address lender;
        uint256 startTime;
        uint256 endTime; // calculated based on lendingDuration
        uint256 lendingRatePerDay;
        bool isActive;
    }

    mapping(uint256 => LendingListing) public lendingListings; // tokenId => LendingListing
    mapping(uint256 => LendingAgreement) public activeLendings; // tokenId => LendingAgreement
    mapping(address => int256) public userReputation; // userAddress => reputation score
    mapping(address => uint256[]) public userLendingHistory; // userAddress => array of tokenIds involved in lending (as lender or borrower)

    event NFTListed(uint256 tokenId, address lender, uint256 lendingRatePerDay, uint256 minLendingDuration);
    event NFTUnlisted(uint256 tokenId, address lender);
    event NFTLent(uint256 tokenId, address lender, address borrower, uint256 endTime);
    event NFTReturned(uint256 tokenId, address lender, address borrower);
    event LendingFeesClaimed(uint256 tokenId, address lender, uint256 amount);
    event ReputationUpdated(address user, int256 reputationChange, int256 newReputation);
    event PlatformFeeSet(uint256 feePercentage);
    event BaseLendingRateMultiplierSet(uint256 multiplier);
    event MinReputationForBorrowingSet(uint256 minReputation);

    constructor() {
        // Initialize reputation for the contract deployer (admin)
        userReputation[msg.sender] = 100; // Starting reputation for admin
    }

    /**
     * @dev Sets the address of the SkillBadgeNFT contract. Only callable by the contract owner.
     * @param _skillBadgeContractAddress The address of the SkillBadgeNFT contract.
     */
    function setSkillBadgeContractAddress(address _skillBadgeContractAddress) public onlyOwner {
        skillBadgeContractAddress = _skillBadgeContractAddress;
    }

    /**
     * @dev Sets the platform fee percentage for lending. Only callable by the contract owner.
     * @param _feePercentage The platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "SkillBadgeLendingPlatform: Fee percentage cannot exceed 100%");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Sets the base multiplier for lending rates. Only callable by the contract owner.
     * @param _multiplier The base lending rate multiplier.
     */
    function setBaseLendingRateMultiplier(uint256 _multiplier) public onlyOwner {
        baseLendingRateMultiplier = _multiplier;
        emit BaseLendingRateMultiplierSet(_multiplier);
    }

    /**
     * @dev Sets the minimum reputation score required to borrow NFTs. Only callable by the contract owner.
     * @param _minReputation The minimum reputation score.
     */
    function setMinReputationForBorrowing(uint256 _minReputation) public onlyOwner {
        minReputationForBorrowing = _minReputation;
        emit MinReputationForBorrowingSet(_minReputation);
    }

    /**
     * @dev Lists a Skill Badge NFT for lending. Only callable by the NFT owner.
     * @param _tokenId The ID of the Skill Badge NFT to list.
     * @param _lendingRatePerDay The daily lending rate in wei.
     * @param _minLendingDuration The minimum lending duration in days.
     */
    function listNFTForLending(uint256 _tokenId, uint256 _lendingRatePerDay, uint256 _minLendingDuration) public whenNotPaused {
        require(skillBadgeContractAddress != address(0), "SkillBadgeLendingPlatform: SkillBadge contract address not set");
        SkillBadgeNFT nftContract = SkillBadgeNFT(skillBadgeContractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "SkillBadgeLendingPlatform: Not NFT owner");
        require(!lendingListings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT already listed");
        require(!activeLendings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT is currently lent");

        lendingListings[_tokenId] = LendingListing({
            tokenId: _tokenId,
            lender: msg.sender,
            lendingRatePerDay: _lendingRatePerDay,
            minLendingDuration: _minLendingDuration,
            listingTime: block.timestamp,
            isActive: true
        });

        // Approve this contract to handle transfer of the NFT
        IERC721(skillBadgeContractAddress).approve(address(this), _tokenId);

        emit NFTListed(_tokenId, msg.sender, _lendingRatePerDay, _minLendingDuration);
    }

    /**
     * @dev Unlists a Skill Badge NFT from lending. Only callable by the NFT owner.
     * @param _tokenId The ID of the Skill Badge NFT to unlist.
     */
    function unlistNFTForLending(uint256 _tokenId) public whenNotPaused {
        require(lendingListings[_tokenId].lender == msg.sender, "SkillBadgeLendingPlatform: Not listing owner");
        require(lendingListings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT not listed");
        require(!activeLendings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT is currently lent");

        lendingListings[_tokenId].isActive = false;
        emit NFTUnlisted(_tokenId, msg.sender);
    }

    /**
     * @dev Allows a user to borrow a listed Skill Badge NFT.
     * @param _tokenId The ID of the Skill Badge NFT to borrow.
     * @param _lendingDuration The duration to borrow in days.
     */
    function lendNFT(uint256 _tokenId, uint256 _lendingDuration) public payable whenNotPaused {
        require(lendingListings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT not listed for lending");
        require(!activeLendings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT is currently lent");
        require(_lendingDuration >= lendingListings[_tokenId].minLendingDuration, "SkillBadgeLendingPlatform: Lending duration below minimum");
        require(userReputation[msg.sender] >= minReputationForBorrowing, "SkillBadgeLendingPlatform: Reputation too low to borrow");

        uint256 lendingCost = lendingListings[_tokenId].lendingRatePerDay * _lendingDuration;
        require(msg.value >= lendingCost, "SkillBadgeLendingPlatform: Insufficient payment for lending");

        LendingListing storage listing = lendingListings[_tokenId];
        activeLendings[_tokenId] = LendingAgreement({
            tokenId: _tokenId,
            borrower: msg.sender,
            lender: listing.lender,
            startTime: block.timestamp,
            endTime: block.timestamp + (_lendingDuration * 1 days),
            lendingRatePerDay: listing.lendingRatePerDay,
            isActive: true
        });
        listing.isActive = false; // Deactivate listing once lent

        // Transfer NFT to borrower (contract holds it during lending)
        SkillBadgeNFT nftContract = SkillBadgeNFT(skillBadgeContractAddress);
        nftContract.safeTransferFrom(listing.lender, address(this), _tokenId);

        // Distribute funds
        uint256 platformFee = (lendingCost * platformFeePercentage) / 100;
        uint256 lenderPayment = lendingCost - platformFee;
        payable(listing.lender).transfer(lenderPayment);
        // Platform fees are kept in the contract balance until withdrawn by admin

        // Update reputation - positive for lender, potentially slightly negative for borrower (risk-taking)
        updateReputation(listing.lender, 1);
        updateReputation(msg.sender, -1); // Slightly negative for borrower, can be adjusted based on risk model

        // Record lending history
        userLendingHistory[listing.lender].push(_tokenId);
        userLendingHistory[msg.sender].push(_tokenId);

        emit NFTLent(_tokenId, listing.lender, msg.sender, activeLendings[_tokenId].endTime);
    }

    /**
     * @dev Allows a borrower to return a borrowed Skill Badge NFT before the lending period ends.
     * @param _tokenId The ID of the Skill Badge NFT to return.
     */
    function returnNFT(uint256 _tokenId) public whenNotPaused {
        require(activeLendings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT is not currently lent");
        require(activeLendings[_tokenId].borrower == msg.sender, "SkillBadgeLendingPlatform: Not the borrower");

        LendingAgreement storage agreement = activeLendings[_tokenId];

        // Transfer NFT back to lender
        SkillBadgeNFT nftContract = SkillBadgeNFT(skillBadgeContractAddress);
        nftContract.safeTransferFrom(address(this), agreement.lender, _tokenId);

        agreement.isActive = false;
        emit NFTReturned(_tokenId, agreement.lender, msg.sender);

        // Update reputation - positive for borrower for returning on time (or early)
        updateReputation(msg.sender, 2); // Positive reputation for returning
    }

    /**
     * @dev Allows the lender to claim accumulated lending fees after the lending period ends or after return.
     * @param _tokenId The ID of the Skill Badge NFT for which to claim fees.
     */
    function claimLendingFees(uint256 _tokenId) public whenNotPaused {
        require(!lendingListings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT is still listed, unlist first."); // Ensure not still listed
        require(!activeLendings[_tokenId].isActive, "SkillBadgeLendingPlatform: NFT is still lent, return first."); // Ensure not still lent
        require(lendingListings[_tokenId].lender == msg.sender || activeLendings[_tokenId].lender == msg.sender, "SkillBadgeLendingPlatform: Not the lender"); // Either from listing or agreement

        LendingListing storage listing = lendingListings[_tokenId]; // Try listing first
        LendingAgreement storage agreement = activeLendings[_tokenId]; // Then agreement

        address lender = listing.lender != address(0) ? listing.lender : agreement.lender; // Determine lender from listing or agreement
        require(lender == msg.sender, "SkillBadgeLendingPlatform: Not the lender");

        uint256 amountToClaim = 0;

        // Calculate fees if lending agreement was active (fees are already transferred upon lending in this version)
        if (agreement.isActive == false && agreement.lender != address(0)) { // Check if agreement was ever active and ended
            // In this version, fees are paid upfront, so nothing to claim here.
            // In a different implementation, fees might be calculated and claimed later.
            amountToClaim = 0; // Example: Calculate based on elapsed time if not paid upfront.
        } else if (listing.isActive == false && listing.lender != address(0)) {
            // No fees to claim if only listed and never lent in this upfront fee model.
            amountToClaim = 0;
        }

        require(amountToClaim == 0, "SkillBadgeLendingPlatform: No fees to claim in this version (fees paid upfront)");

        // In a real scenario where fees are not paid upfront, you would transfer 'amountToClaim' here.
        // For this example, fees are transferred at the time of lending itself.

        emit LendingFeesClaimed(_tokenId, msg.sender, amountToClaim); // amountToClaim will be 0 in this version.
    }

    /**
     * @dev Gets information about the lending status of a specific NFT.
     * @param _tokenId The ID of the Skill Badge NFT.
     * @return Lending status details.
     */
    function getNFTLendingInfo(uint256 _tokenId) public view returns (
        bool isListed,
        bool isLent,
        address lender,
        address borrower,
        uint256 lendingRatePerDay,
        uint256 minLendingDuration,
        uint256 endTime
    ) {
        isListed = lendingListings[_tokenId].isActive;
        isLent = activeLendings[_tokenId].isActive;
        lender = lendingListings[_tokenId].isActive ? lendingListings[_tokenId].lender : activeLendings[_tokenId].lender;
        borrower = activeLendings[_tokenId].borrower;
        lendingRatePerDay = lendingListings[_tokenId].isActive ? lendingListings[_tokenId].lendingRatePerDay : activeLendings[_tokenId].lendingRatePerDay;
        minLendingDuration = lendingListings[_tokenId].minLendingDuration;
        endTime = activeLendings[_tokenId].endTime;
        return (isListed, isLent, lender, borrower, lendingRatePerDay, minLendingDuration, endTime);
    }

    /**
     * @dev Gets the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    /**
     * @dev Updates the reputation score of a user. Internal function triggered by lending events.
     * @param _user The address of the user.
     * @param _reputationChange The amount to change the reputation by (positive or negative).
     */
    function updateReputation(address _user, int256 _reputationChange) internal {
        userReputation[_user] += _reputationChange;
        emit ReputationUpdated(_user, _reputationChange, userReputation[_user]);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Pauses the contract, preventing new lending/borrowing. Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing lending/borrowing to resume. Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused();
    }

    /**
     * @dev Gets the current balance of the platform contract.
     * @return The contract balance in wei.
     */
    function getPlatformBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the lending history for a user (token IDs they lent or borrowed).
     * @param _user The address of the user.
     * @return An array of token IDs.
     */
    function getUserLendingHistory(address _user) public view returns (uint256[] memory) {
        return userLendingHistory[_user];
    }

    /**
     * @dev Allows the admin to change the contract administrator.
     * @param _newAdmin The address of the new administrator.
     */
    function setAdmin(address _newAdmin) public onlyOwner {
        transferOwnership(_newAdmin);
    }

    // Fallback function to receive Ether for lending payments
    receive() external payable {}
}
```