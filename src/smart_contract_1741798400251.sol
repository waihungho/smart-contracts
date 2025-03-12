```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Skill-Based NFT Marketplace with Gamified Learning
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev A smart contract for a dynamic NFT marketplace where NFT properties are tied to user reputation and skills,
 *      and incorporates gamified learning elements to enhance user engagement and skill development.
 *
 * **Outline and Function Summary:**
 *
 * **NFT Core Functions (Dynamic Skill NFTs - DS-NFT):**
 * 1.  `mintSkillNFT(string memory _skillName, string memory _skillDescription, string memory _baseURI)`: Allows admin to mint new Skill NFT types.
 * 2.  `awardSkillNFT(address _recipient, uint256 _skillNFTTypeId)`: Awards a specific Skill NFT to a user, starting at Level 1.
 * 3.  `getSkillNFTLevel(uint256 _tokenId)`: Returns the current level of a given Skill NFT.
 * 4.  `getSkillNFTType(uint256 _tokenId)`: Returns the type ID of a given Skill NFT.
 * 5.  `getSkillNFTMetadataURI(uint256 _tokenId)`: Returns the dynamic metadata URI for a Skill NFT, reflecting its level and skill.
 * 6.  `transferSkillNFT(address _to, uint256 _tokenId)`: Transfers ownership of a Skill NFT.
 * 7.  `burnSkillNFT(uint256 _tokenId)`: Burns a Skill NFT (admin/specific cases).
 *
 * **Reputation and Experience System:**
 * 8.  `getUserReputation(address _user)`: Returns the reputation points of a user.
 * 9.  `earnReputation(address _user, uint256 _points)`: Allows admin/contract to award reputation points to a user.
 * 10. `spendReputation(address _user, uint256 _points)`: Allows users to spend reputation points (e.g., for marketplace discounts).
 * 11. `getSkillExperience(address _user, uint256 _skillNFTTypeId)`: Returns the experience points a user has in a specific skill.
 * 12. `addSkillExperience(address _user, uint256 _skillNFTTypeId, uint256 _experiencePoints)`: Adds experience points to a user for a specific skill, potentially leveling up their Skill NFT.
 *
 * **Gamified Learning Modules:**
 * 13. `createLearningModule(string memory _moduleName, string memory _moduleDescription, uint256 _skillNFTTypeId, uint256 _reputationReward, uint256 _experienceReward)`: Allows admin to create learning modules associated with specific Skill NFTs.
 * 14. `startLearningModule(uint256 _moduleId)`: Allows a user to start a learning module.
 * 15. `completeLearningModule(uint256 _moduleId)`: Allows a user to complete a learning module (requires external verification/oracle integration in a real-world scenario).
 * 16. `getModuleStatus(uint256 _moduleId, address _user)`: Returns the status of a learning module for a user (Not Started, Started, Completed).
 *
 * **Dynamic NFT Marketplace:**
 * 17. `listItem(uint256 _tokenId, uint256 _price)`: Allows users to list their Skill NFTs for sale.
 * 18. `buyItem(uint256 _listingId)`: Allows users to buy listed Skill NFTs.
 * 19. `cancelListing(uint256 _listingId)`: Allows users to cancel their NFT listings.
 * 20. `getListingsBySkillType(uint256 _skillNFTTypeId)`: Returns a list of active listings for a specific Skill NFT type.
 * 21. `getMarketplaceFee()`: Returns the current marketplace fee percentage.
 * 22. `setMarketplaceFee(uint256 _feePercentage)`: Allows admin to update the marketplace fee percentage.
 * 23. `withdrawMarketplaceFees()`: Allows admin to withdraw accumulated marketplace fees.
 *
 * **Admin and Utility Functions:**
 * 24. `setBaseMetadataURI(string memory _baseURI)`: Allows admin to set the base URI for Skill NFT metadata.
 * 25. `pauseContract()`: Pauses core contract functionalities (security feature).
 * 26. `unpauseContract()`: Resumes contract functionalities.
 * 27. `isContractPaused()`: Returns the current paused state of the contract.
 * 28. `setAdmin(address _newAdmin)`: Allows the current admin to change the contract administrator.
 * 29. `getAdmin()`: Returns the current contract administrator address.
 */

contract DynamicSkillNFTMarketplace {
    // --- State Variables ---

    // Admin of the contract
    address public admin;

    // Paused state of the contract
    bool public paused;

    // Base URI for Skill NFT metadata
    string public baseMetadataURI;

    // Marketplace fee percentage (e.g., 200 = 2%)
    uint256 public marketplaceFeePercentage = 200; // Default 2%

    // Skill NFT type information
    struct SkillNFTType {
        string skillName;
        string skillDescription;
        string baseURI; // Base URI specific to this skill type
        uint256 nextTokenIdCounter;
    }
    mapping(uint256 => SkillNFTType) public skillNFTTypes;
    uint256 public nextSkillNFTTypeId = 1;

    // Skill NFT ownership and level mapping
    mapping(uint256 => address) public skillNFTOwner;
    mapping(uint256 => uint256) public skillNFTLevel; // TokenId => Level
    mapping(uint256 => uint256) public skillNFTTypeMapping; // TokenId => SkillNFTTypeId

    // User Reputation Points
    mapping(address => uint256) public userReputation;

    // User Skill Experience Points
    mapping(address => mapping(uint256 => uint256)) public skillExperience; // User => SkillNFTTypeId => Experience Points

    // Learning Module Information
    struct LearningModule {
        string moduleName;
        string moduleDescription;
        uint256 skillNFTTypeId;
        uint256 reputationReward;
        uint256 experienceReward;
        uint256 moduleId;
    }
    mapping(uint256 => LearningModule) public learningModules;
    uint256 public nextModuleId = 1;

    enum ModuleStatus { NotStarted, Started, Completed }
    mapping(uint256 => mapping(address => ModuleStatus)) public moduleUserStatus; // ModuleId => User => Status

    // Marketplace Listing Information
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId = 1;
    mapping(uint256 => bool) public activeListings; // ListingId => isActive

    // Accumulated marketplace fees
    uint256 public marketplaceFeesCollected;

    // --- Events ---
    event SkillNFTTypeMinted(uint256 skillNFTTypeId, string skillName, string skillDescription);
    event SkillNFTAwarded(uint256 tokenId, address recipient, uint256 skillNFTTypeId);
    event SkillNFTTransferred(uint256 tokenId, address from, address to);
    event SkillNFTBurned(uint256 tokenId);
    event ReputationEarned(address user, uint256 points);
    event ReputationSpent(address user, uint256 points);
    event SkillExperienceAdded(address user, uint256 skillNFTTypeId, uint256 experiencePoints);
    event LearningModuleCreated(uint256 moduleId, string moduleName, uint256 skillNFTTypeId);
    event LearningModuleStarted(uint256 moduleId, address user);
    event LearningModuleCompleted(uint256 moduleId, address user);
    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address oldAdmin, address newAdmin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validSkillNFTType(uint256 _skillNFTTypeId) {
        require(_skillNFTTypeId > 0 && _skillNFTTypeId < nextSkillNFTTypeId, "Invalid Skill NFT Type ID.");
        _;
    }

    modifier validSkillNFT(uint256 _tokenId) {
        require(skillNFTOwner[_tokenId] != address(0), "Invalid Skill NFT Token ID.");
        _;
    }

    modifier onlyOwnerOfSkillNFT(uint256 _tokenId) {
        require(skillNFTOwner[_tokenId] == msg.sender, "Not the owner of this Skill NFT.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Invalid or inactive listing.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Admin Functions ---

    /**
     * @dev Sets a new admin for the contract.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /**
     * @dev Returns the current admin address.
     * @return address The current admin address.
     */
    function getAdmin() external view onlyAdmin returns (address) {
        return admin;
    }

    /**
     * @dev Sets the base URI for Skill NFT metadata.
     * @param _baseURI The new base URI string.
     */
    function setBaseMetadataURI(string memory _baseURI) external onlyAdmin {
        baseMetadataURI = _baseURI;
    }

    /**
     * @dev Sets the marketplace fee percentage.
     * @param _feePercentage The new fee percentage (e.g., 200 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyAdmin {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100% (10000).");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /**
     * @dev Returns the current marketplace fee percentage.
     * @return uint256 The current marketplace fee percentage.
     */
    function getMarketplaceFee() external view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /**
     * @dev Allows the admin to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() external onlyAdmin {
        uint256 amount = marketplaceFeesCollected;
        marketplaceFeesCollected = 0;
        payable(admin).transfer(amount);
        emit MarketplaceFeesWithdrawn(amount, admin);
    }

    /**
     * @dev Pauses the contract, restricting core functionalities.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring core functionalities.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return bool True if paused, false otherwise.
     */
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    // --- Skill NFT Type Management Functions ---

    /**
     * @dev Allows admin to mint a new Skill NFT type.
     * @param _skillName The name of the skill.
     * @param _skillDescription A description of the skill.
     * @param _baseURI Base URI for metadata for NFTs of this skill type.
     */
    function mintSkillNFTType(
        string memory _skillName,
        string memory _skillDescription,
        string memory _baseURI
    ) external onlyAdmin whenNotPaused returns (uint256 skillNFTTypeId) {
        skillNFTTypeId = nextSkillNFTTypeId++;
        skillNFTTypes[skillNFTTypeId] = SkillNFTType({
            skillName: _skillName,
            skillDescription: _skillDescription,
            baseURI: _baseURI,
            nextTokenIdCounter: 1
        });
        emit SkillNFTTypeMinted(skillNFTTypeId, _skillName, _skillDescription);
    }

    // --- Skill NFT Core Functions ---

    /**
     * @dev Awards a specific Skill NFT to a user. Starts at Level 1.
     * @param _recipient The address to receive the Skill NFT.
     * @param _skillNFTTypeId The ID of the Skill NFT type to award.
     */
    function awardSkillNFT(address _recipient, uint256 _skillNFTTypeId)
        external
        onlyAdmin
        whenNotPaused
        validSkillNFTType(_skillNFTTypeId)
        returns (uint256 tokenId)
    {
        tokenId = skillNFTTypes[_skillNFTTypeId].nextTokenIdCounter++;
        skillNFTOwner[tokenId] = _recipient;
        skillNFTLevel[tokenId] = 1; // Start at Level 1
        skillNFTTypeMapping[tokenId] = _skillNFTTypeId;
        emit SkillNFTAwarded(tokenId, _recipient, _skillNFTTypeId);
    }

    /**
     * @dev Returns the current level of a given Skill NFT.
     * @param _tokenId The ID of the Skill NFT token.
     * @return uint256 The level of the Skill NFT.
     */
    function getSkillNFTLevel(uint256 _tokenId) external view validSkillNFT(_tokenId) returns (uint256) {
        return skillNFTLevel[_tokenId];
    }

    /**
     * @dev Returns the type ID of a given Skill NFT.
     * @param _tokenId The ID of the Skill NFT token.
     * @return uint256 The Skill NFT type ID.
     */
    function getSkillNFTType(uint256 _tokenId) external view validSkillNFT(_tokenId) returns (uint256) {
        return skillNFTTypeMapping[_tokenId];
    }

    /**
     * @dev Returns the dynamic metadata URI for a Skill NFT, reflecting its level and skill.
     *      In a real-world scenario, this would likely point to a server that dynamically generates metadata.
     * @param _tokenId The ID of the Skill NFT token.
     * @return string The metadata URI.
     */
    function getSkillNFTMetadataURI(uint256 _tokenId) external view validSkillNFT(_tokenId) returns (string memory) {
        uint256 skillType = getSkillNFTType(_tokenId);
        uint256 level = getSkillNFTLevel(_tokenId);
        string memory skillName = skillNFTTypes[skillType].skillName;
        string memory skillBaseURI = skillNFTTypes[skillType].baseURI;

        // Example dynamic URI construction - adjust as needed for your metadata server
        return string(abi.encodePacked(skillBaseURI, "/", skillName, "-Level", Strings.toString(level), ".json"));
    }

    /**
     * @dev Transfers ownership of a Skill NFT.
     * @param _to The address to transfer the Skill NFT to.
     * @param _tokenId The ID of the Skill NFT token.
     */
    function transferSkillNFT(address _to, uint256 _tokenId)
        external
        whenNotPaused
        validSkillNFT(_tokenId)
        onlyOwnerOfSkillNFT(_tokenId)
    {
        require(_to != address(0), "Cannot transfer to zero address.");
        address from = skillNFTOwner[_tokenId];
        skillNFTOwner[_tokenId] = _to;
        emit SkillNFTTransferred(_tokenId, from, _to);
    }

    /**
     * @dev Burns a Skill NFT (Admin function or for specific game mechanics).
     * @param _tokenId The ID of the Skill NFT token to burn.
     */
    function burnSkillNFT(uint256 _tokenId) external onlyAdmin whenNotPaused validSkillNFT(_tokenId) {
        address owner = skillNFTOwner[_tokenId];
        delete skillNFTOwner[_tokenId];
        delete skillNFTLevel[_tokenId];
        delete skillNFTTypeMapping[_tokenId];
        emit SkillNFTBurned(_tokenId);
    }

    // --- Reputation and Experience System Functions ---

    /**
     * @dev Returns the reputation points of a user.
     * @param _user The address of the user.
     * @return uint256 The user's reputation points.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Allows admin/contract to award reputation points to a user.
     * @param _user The address of the user to award reputation to.
     * @param _points The number of reputation points to award.
     */
    function earnReputation(address _user, uint256 _points) external onlyAdmin whenNotPaused {
        userReputation[_user] += _points;
        emit ReputationEarned(_user, _points);
    }

    /**
     * @dev Allows users to spend reputation points (e.g., for marketplace discounts, features, etc.).
     * @param _points The number of reputation points to spend.
     */
    function spendReputation(address _user, uint256 _points) external whenNotPaused {
        require(userReputation[_user] >= _points, "Not enough reputation points.");
        userReputation[_user] -= _points;
        emit ReputationSpent(_user, _points);
    }

    /**
     * @dev Returns the experience points a user has in a specific skill type.
     * @param _user The address of the user.
     * @param _skillNFTTypeId The ID of the Skill NFT type.
     * @return uint256 The user's experience points in the skill.
     */
    function getSkillExperience(address _user, uint256 _skillNFTTypeId)
        external
        view
        validSkillNFTType(_skillNFTTypeId)
        returns (uint256)
    {
        return skillExperience[_user][_skillNFTTypeId];
    }

    /**
     * @dev Adds experience points to a user for a specific skill, potentially leveling up their Skill NFT.
     *      Leveling logic would be implemented here based on experience thresholds.
     * @param _user The address of the user.
     * @param _skillNFTTypeId The ID of the Skill NFT type.
     * @param _experiencePoints The number of experience points to add.
     */
    function addSkillExperience(
        address _user,
        uint256 _skillNFTTypeId,
        uint256 _experiencePoints
    ) external onlyAdmin whenNotPaused validSkillNFTType(_skillNFTTypeId) {
        skillExperience[_user][_skillNFTTypeId] += _experiencePoints;

        // --- Example Leveling Logic (Simple - Adjust as needed) ---
        uint256 currentLevel = 0;
        uint256 tokenId = 0;
        // Find the Skill NFT token owned by the user of this type (assuming only one per type for simplicity in example)
        for (uint256 i = 1; i < skillNFTTypes[_skillNFTTypeId].nextTokenIdCounter; i++) {
            if (skillNFTOwner[i] == _user && skillNFTTypeMapping[i] == _skillNFTTypeId) {
                tokenId = i;
                currentLevel = skillNFTLevel[i];
                break; // Assuming only one NFT of this type per user for simplicity
            }
        }

        if (tokenId != 0) { // User owns an NFT of this type
            uint256 experienceThreshold = currentLevel * 1000; // Example: 1000 exp per level
            if (skillExperience[_user][_skillNFTTypeId] >= experienceThreshold) {
                skillNFTLevel[tokenId]++; // Level up!
                // Potentially emit an event for level up
            }
        }

        emit SkillExperienceAdded(_user, _skillNFTTypeId, _experiencePoints);
    }

    // --- Gamified Learning Module Functions ---

    /**
     * @dev Allows admin to create a new learning module.
     * @param _moduleName The name of the learning module.
     * @param _moduleDescription A description of the learning module.
     * @param _skillNFTTypeId The Skill NFT type associated with this module.
     * @param _reputationReward Reputation points awarded upon completion.
     * @param _experienceReward Experience points awarded upon completion.
     */
    function createLearningModule(
        string memory _moduleName,
        string memory _moduleDescription,
        uint256 _skillNFTTypeId,
        uint256 _reputationReward,
        uint256 _experienceReward
    ) external onlyAdmin whenNotPaused validSkillNFTType(_skillNFTTypeId) returns (uint256 moduleId) {
        moduleId = nextModuleId++;
        learningModules[moduleId] = LearningModule({
            moduleName: _moduleName,
            moduleDescription: _moduleDescription,
            skillNFTTypeId: _skillNFTTypeId,
            reputationReward: _reputationReward,
            experienceReward: _experienceReward,
            moduleId: moduleId
        });
        emit LearningModuleCreated(moduleId, _moduleName, _skillNFTTypeId);
    }

    /**
     * @dev Allows a user to start a learning module.
     * @param _moduleId The ID of the learning module to start.
     */
    function startLearningModule(uint256 _moduleId) external whenNotPaused {
        require(learningModules[_moduleId].moduleId != 0, "Invalid Module ID.");
        require(moduleUserStatus[_moduleId][msg.sender] == ModuleStatus.NotStarted, "Module already started or completed.");
        moduleUserStatus[_moduleId][msg.sender] = ModuleStatus.Started;
        emit LearningModuleStarted(_moduleId, msg.sender);
    }

    /**
     * @dev Allows a user to complete a learning module and claim rewards.
     *      **Important:** In a real-world scenario, completion verification would need to be more robust,
     *      potentially using oracles or off-chain verification to prevent cheating. This is a simplified example.
     * @param _moduleId The ID of the learning module to complete.
     */
    function completeLearningModule(uint256 _moduleId) external whenNotPaused {
        require(learningModules[_moduleId].moduleId != 0, "Invalid Module ID.");
        require(moduleUserStatus[_moduleId][msg.sender] == ModuleStatus.Started, "Module not started or already completed.");
        moduleUserStatus[_moduleId][msg.sender] = ModuleStatus.Completed;

        uint256 reputationReward = learningModules[_moduleId].reputationReward;
        uint256 experienceReward = learningModules[_moduleId].experienceReward;
        uint256 skillNFTTypeId = learningModules[_moduleId].skillNFTTypeId;

        if (reputationReward > 0) {
            earnReputation(msg.sender, reputationReward);
        }
        if (experienceReward > 0) {
            addSkillExperience(msg.sender, skillNFTTypeId, experienceReward);
        }

        emit LearningModuleCompleted(_moduleId, msg.sender);
    }

    /**
     * @dev Returns the status of a learning module for a user.
     * @param _moduleId The ID of the learning module.
     * @param _user The address of the user.
     * @return ModuleStatus The status of the module for the user.
     */
    function getModuleStatus(uint256 _moduleId, address _user) external view returns (ModuleStatus) {
        return moduleUserStatus[_moduleId][_user];
    }

    // --- Dynamic NFT Marketplace Functions ---

    /**
     * @dev Allows a user to list their Skill NFT for sale in the marketplace.
     * @param _tokenId The ID of the Skill NFT token to list.
     * @param _price The listing price in wei.
     */
    function listItem(uint256 _tokenId, uint256 _price)
        external
        whenNotPaused
        validSkillNFT(_tokenId)
        onlyOwnerOfSkillNFT(_tokenId)
    {
        require(_price > 0, "Price must be greater than zero.");
        require(skillNFTOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(!activeListings[listings[_tokenId].listingId], "NFT is already listed."); // Prevent relisting same NFT without cancelling

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        activeListings[listingId] = true;
        emit ItemListed(listingId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to buy a Skill NFT listed in the marketplace.
     * @param _listingId The ID of the marketplace listing.
     */
    function buyItem(uint256 _listingId) external payable whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy item.");
        require(listing.seller != msg.sender, "Cannot buy your own listing.");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate marketplace fee
        uint256 feeAmount = (price * marketplaceFeePercentage) / 10000;
        uint256 sellerAmount = price - feeAmount;

        // Transfer NFT ownership
        skillNFTOwner[tokenId] = msg.sender;

        // Transfer funds to seller and collect marketplace fee
        payable(seller).transfer(sellerAmount);
        marketplaceFeesCollected += feeAmount;

        // Update listing status
        listing.isActive = false;
        activeListings[_listingId] = false;
        delete activeListings[listings[tokenId].listingId]; // Clean up old listing mapping if needed

        emit ItemBought(_listingId, tokenId, msg.sender, price);
    }

    /**
     * @dev Allows a user to cancel their Skill NFT listing in the marketplace.
     * @param _listingId The ID of the marketplace listing to cancel.
     */
    function cancelListing(uint256 _listingId)
        external
        whenNotPaused
        validListing(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only the seller can cancel the listing.");

        listing.isActive = false;
        activeListings[_listingId] = false;
        delete activeListings[listings[listing.tokenId].listingId]; // Clean up old listing mapping if needed

        emit ListingCancelled(_listingId, listing.tokenId, msg.sender);
    }

    /**
     * @dev Returns a list of active listings for a specific Skill NFT type.
     *      In a real-world scenario, consider implementing pagination or more efficient indexing for large marketplaces.
     * @param _skillNFTTypeId The ID of the Skill NFT type to filter listings for.
     * @return Listing[] An array of active listings for the specified skill type.
     */
    function getListingsBySkillType(uint256 _skillNFTTypeId)
        external
        view
        validSkillNFTType(_skillNFTTypeId)
        returns (Listing[] memory)
    {
        uint256 listingCount = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive && skillNFTTypeMapping[listings[i].tokenId] == _skillNFTTypeId) {
                listingCount++;
            }
        }

        Listing[] memory skillListings = new Listing[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive && skillNFTTypeMapping[listings[i].tokenId] == _skillNFTTypeId) {
                skillListings[index++] = listings[i];
            }
        }
        return skillListings;
    }
}

// --- Helper Library for String Conversion (Solidity < 0.8) ---
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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
```