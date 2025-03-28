```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation & Skill Marketplace Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a decentralized reputation and skill marketplace.
 * It allows users to create profiles, showcase skills, earn reputation,
 * offer services, and discover talents within a decentralized ecosystem.
 *
 * Function Summary:
 *
 * **Profile Management:**
 * 1. `createProfile(string _name, string _description, string _profileHash)`: Allows users to create a profile.
 * 2. `updateProfileDetails(string _name, string _description, string _profileHash)`: Allows users to update their profile details.
 * 3. `getProfile(address _user)`: Retrieves profile information for a given user.
 * 4. `deactivateProfile()`: Allows users to deactivate their profile (soft delete).
 * 5. `reactivateProfile()`: Allows users to reactivate their deactivated profile.
 *
 * **Skill & Service Management:**
 * 6. `addSkill(string _skillName, string _skillDescription)`: Allows users to add skills to their profile.
 * 7. `removeSkill(uint _skillId)`: Allows users to remove skills from their profile.
 * 8. `getSkills(address _user)`: Retrieves the list of skills for a user.
 * 9. `offerService(uint _skillId, string _serviceDescription, uint256 _price)`: Allows users to offer a service based on a skill.
 * 10. `updateServicePrice(uint _serviceId, uint256 _newPrice)`: Allows users to update the price of their service.
 * 11. `getServicesBySkill(uint _skillId)`: Retrieves services offered for a specific skill.
 * 12. `getAllServices()`: Retrieves all services offered on the platform.
 *
 * **Reputation & Endorsement:**
 * 13. `endorseSkill(address _targetUser, uint _skillId, string _endorsementText)`: Allows users to endorse another user's skill.
 * 14. `getSkillEndorsements(address _user, uint _skillId)`: Retrieves endorsements for a specific skill of a user.
 * 15. `reportUser(address _targetUser, string _reportReason)`: Allows users to report other users for inappropriate behavior.
 * 16. `getUserReputationScore(address _user)`: Calculates and retrieves a user's reputation score (based on endorsements and reports).
 *
 * **Marketplace & Discovery:**
 * 17. `searchProfilesBySkill(string _skillName)`: Searches for profiles based on skills (basic keyword search).
 * 18. `filterServicesByPriceRange(uint256 _minPrice, uint256 _maxPrice)`: Filters services based on price range.
 * 19. `getTrendingSkills()`: Retrieves a list of trending skills (based on service offerings and endorsements - simple heuristic).
 *
 * **Admin & Utility:**
 * 20. `setPlatformFee(uint256 _feePercentage)`: Allows the contract admin to set a platform fee for services.
 * 21. `withdrawPlatformFees()`: Allows the contract admin to withdraw accumulated platform fees.
 * 22. `pauseContract()`: Allows the contract admin to pause the contract in case of emergency.
 * 23. `unpauseContract()`: Allows the contract admin to unpause the contract.
 */

contract DecentralizedSkillMarketplace {
    // --- State Variables ---

    address public admin;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    bool public paused = false;

    struct UserProfile {
        string name;
        string description;
        string profileHash; // IPFS hash or similar for profile data
        bool isActive;
        uint256 reputationScore;
    }

    struct Skill {
        uint id;
        string name;
        string description;
    }

    struct Service {
        uint id;
        address provider;
        uint skillId;
        string description;
        uint256 price; // Price in wei
        bool isActive;
    }

    struct Endorsement {
        address endorser;
        string text;
        uint timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => Skill[]) public userSkills;
    mapping(uint => Service) public services;
    mapping(address => mapping(uint => Endorsement[])) public skillEndorsements;
    mapping(address => uint) public reputationScores; // Directly store reputation scores
    mapping(string => uint) public skillNameToId; // Map skill names to IDs for easier searching
    mapping(uint => string) public skillIdToName; // Map skill IDs back to names
    uint public nextSkillId = 1;
    uint public nextServiceId = 1;
    uint public totalPlatformFees;

    // --- Events ---

    event ProfileCreated(address indexed user, string name);
    event ProfileUpdated(address indexed user);
    event ProfileDeactivated(address indexed user);
    event ProfileReactivated(address indexed user);
    event SkillAdded(address indexed user, uint skillId, string skillName);
    event SkillRemoved(address indexed user, uint skillId);
    event ServiceOffered(uint serviceId, address provider, uint skillId, uint256 price);
    event ServicePriceUpdated(uint serviceId, uint256 newPrice);
    event SkillEndorsed(address indexed targetUser, address indexed endorser, uint skillId, string endorsementText);
    event UserReported(address indexed reporter, address indexed targetUser, string reason);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].isActive, "Profile does not exist or is deactivated");
        _;
    }

    modifier skillExists(uint _skillId) {
        require(_skillId > 0 && _skillId < nextSkillId, "Skill does not exist");
        _;
    }

    modifier serviceExists(uint _serviceId) {
        require(services[_serviceId].isActive, "Service does not exist or is deactivated");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- Profile Management Functions ---

    /// @notice Creates a user profile.
    /// @param _name The name of the user.
    /// @param _description A short description of the user.
    /// @param _profileHash Hash of the user's detailed profile data (e.g., IPFS hash).
    function createProfile(
        string memory _name,
        string memory _description,
        string memory _profileHash
    ) public whenNotPaused {
        require(!userProfiles[msg.sender].isActive, "Profile already exists");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            description: _description,
            profileHash: _profileHash,
            isActive: true,
            reputationScore: 0 // Initial reputation
        });
        emit ProfileCreated(msg.sender, _name);
    }

    /// @notice Updates the details of an existing user profile.
    /// @param _name The new name of the user.
    /// @param _description The new description of the user.
    /// @param _profileHash The new hash of the user's detailed profile data.
    function updateProfileDetails(
        string memory _name,
        string memory _description,
        string memory _profileHash
    ) public whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].description = _description;
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Retrieves the profile information of a given user.
    /// @param _user The address of the user whose profile to retrieve.
    /// @return UserProfile struct containing profile details.
    function getProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    /// @notice Deactivates the user's profile (soft delete).
    function deactivateProfile() public whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].isActive = false;
        emit ProfileDeactivated(msg.sender);
    }

    /// @notice Reactivates a previously deactivated profile.
    function reactivateProfile() public whenNotPaused {
        require(!userProfiles[msg.sender].isActive, "Profile is already active");
        userProfiles[msg.sender].isActive = true;
        emit ProfileReactivated(msg.sender);
    }

    // --- Skill & Service Management Functions ---

    /// @notice Adds a skill to the user's profile.
    /// @param _skillName The name of the skill.
    /// @param _skillDescription A description of the skill.
    function addSkill(string memory _skillName, string memory _skillDescription) public whenNotPaused profileExists(msg.sender) {
        require(skillNameToId[_skillName] == 0, "Skill name already exists globally. Use a more specific name.");
        uint skillId = nextSkillId++;
        Skill memory newSkill = Skill({
            id: skillId,
            name: _skillName,
            description: _skillDescription
        });
        userSkills[msg.sender].push(newSkill);
        skillNameToId[_skillName] = skillId;
        skillIdToName[skillId] = _skillName;
        emit SkillAdded(msg.sender, skillId, _skillName);
    }

    /// @notice Removes a skill from the user's profile.
    /// @param _skillId The ID of the skill to remove.
    function removeSkill(uint _skillId) public whenNotPaused profileExists(msg.sender) skillExists(_skillId) {
        bool removed = false;
        Skill[] storage skills = userSkills[msg.sender];
        for (uint i = 0; i < skills.length; i++) {
            if (skills[i].id == _skillId) {
                // Shift elements to remove the skill (preserves order, could optimize if order doesn't matter)
                for (uint j = i; j < skills.length - 1; j++) {
                    skills[j] = skills[j + 1];
                }
                skills.pop();
                removed = true;
                break;
            }
        }
        require(removed, "Skill not found in user's profile");
        emit SkillRemoved(msg.sender, _skillId);
    }

    /// @notice Retrieves the list of skills for a given user.
    /// @param _user The address of the user.
    /// @return An array of Skill structs.
    function getSkills(address _user) public view returns (Skill[] memory) {
        return userSkills[_user];
    }

    /// @notice Allows a user to offer a service based on one of their skills.
    /// @param _skillId The ID of the skill the service is based on.
    /// @param _serviceDescription A description of the service being offered.
    /// @param _price The price of the service in wei.
    function offerService(
        uint _skillId,
        string memory _serviceDescription,
        uint256 _price
    ) public whenNotPaused profileExists(msg.sender) skillExists(_skillId) {
        bool hasSkill = false;
        for (uint i = 0; i < userSkills[msg.sender].length; i++) {
            if (userSkills[msg.sender][i].id == _skillId) {
                hasSkill = true;
                break;
            }
        }
        require(hasSkill, "User does not have the specified skill");

        services[nextServiceId] = Service({
            id: nextServiceId,
            provider: msg.sender,
            skillId: _skillId,
            description: _serviceDescription,
            price: _price,
            isActive: true
        });
        emit ServiceOffered(nextServiceId, msg.sender, _skillId, _price);
        nextServiceId++;
    }

    /// @notice Updates the price of an offered service.
    /// @param _serviceId The ID of the service to update.
    /// @param _newPrice The new price of the service in wei.
    function updateServicePrice(uint _serviceId, uint256 _newPrice) public whenNotPaused serviceExists(_serviceId) {
        require(services[_serviceId].provider == msg.sender, "Only service provider can update price");
        services[_serviceId].price = _newPrice;
        emit ServicePriceUpdated(_serviceId, _newPrice);
    }

    /// @notice Retrieves all services offered for a specific skill.
    /// @param _skillId The ID of the skill.
    /// @return An array of Service IDs.
    function getServicesBySkill(uint _skillId) public view skillExists(_skillId) returns (uint[] memory) {
        uint[] memory serviceIds = new uint[](nextServiceId); // Maximum possible size
        uint count = 0;
        for (uint i = 1; i < nextServiceId; i++) {
            if (services[i].isActive && services[i].skillId == _skillId) {
                serviceIds[count++] = i;
            }
        }
        // Resize the array to the actual number of services found
        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = serviceIds[i];
        }
        return result;
    }

    /// @notice Retrieves all active services offered on the platform.
    /// @return An array of Service IDs.
    function getAllServices() public view returns (uint[] memory) {
        uint[] memory serviceIds = new uint[](nextServiceId); // Maximum possible size
        uint count = 0;
        for (uint i = 1; i < nextServiceId; i++) {
            if (services[i].isActive) {
                serviceIds[count++] = i;
            }
        }
        // Resize the array to the actual number of services found
        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = serviceIds[i];
        }
        return result;
    }


    // --- Reputation & Endorsement Functions ---

    /// @notice Allows a user to endorse another user's skill.
    /// @param _targetUser The address of the user whose skill is being endorsed.
    /// @param _skillId The ID of the skill being endorsed.
    /// @param _endorsementText Textual endorsement message.
    function endorseSkill(
        address _targetUser,
        uint _skillId,
        string memory _endorsementText
    ) public whenNotPaused profileExists(msg.sender) profileExists(_targetUser) skillExists(_skillId) {
        require(msg.sender != _targetUser, "Cannot endorse your own skill");
        bool targetUserHasSkill = false;
        for (uint i = 0; i < userSkills[_targetUser].length; i++) {
            if (userSkills[_targetUser][i].id == _skillId) {
                targetUserHasSkill = true;
                break;
            }
        }
        require(targetUserHasSkill, "Target user does not have the specified skill");

        skillEndorsements[_targetUser][_skillId].push(Endorsement({
            endorser: msg.sender,
            text: _endorsementText,
            timestamp: block.timestamp
        }));

        // Simple reputation score update - can be made more sophisticated
        reputationScores[_targetUser] += 1; // Increase reputation on endorsement
        emit SkillEndorsed(_targetUser, msg.sender, _skillId, _endorsementText);
    }

    /// @notice Retrieves endorsements for a specific skill of a user.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return An array of Endorsement structs.
    function getSkillEndorsements(address _user, uint _skillId) public view skillExists(_skillId) returns (Endorsement[] memory) {
        return skillEndorsements[_user][_skillId];
    }

    /// @notice Allows a user to report another user for inappropriate behavior.
    /// @param _targetUser The address of the user being reported.
    /// @param _reportReason The reason for the report.
    function reportUser(address _targetUser, string memory _reportReason) public whenNotPaused profileExists(msg.sender) profileExists(_targetUser) {
        require(msg.sender != _targetUser, "Cannot report yourself");
        // In a real-world scenario, you'd want to store and process reports more formally,
        // potentially involving moderation and reputation penalties.
        // For this example, we just emit an event.
        emit UserReported(msg.sender, _targetUser, _reportReason);
        // In a more advanced system, you might decrease reputation score based on reports after review.
    }

    /// @notice Calculates and retrieves a user's reputation score.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getUserReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    // --- Marketplace & Discovery Functions ---

    /// @notice Searches for user profiles based on a skill name (basic keyword search).
    /// @param _skillName The name of the skill to search for.
    /// @return An array of addresses of users who possess the skill.
    function searchProfilesBySkill(string memory _skillName) public view returns (address[] memory) {
        uint skillId = skillNameToId[_skillName];
        if (skillId == 0) {
            return new address[](0); // Skill not found
        }

        address[] memory matchingProfiles = new address[](address(this).balance / 100 wei); // Initial estimate - can be improved
        uint count = 0;
        for (uint i = 1; i < nextServiceId; i++) { // Iterate through services to find providers - inefficient for large scale, index in real app
            if (services[i].isActive && services[i].skillId == skillId) {
                address provider = services[i].provider;
                bool alreadyAdded = false;
                for (uint j = 0; j < count; j++) {
                    if (matchingProfiles[j] == provider) {
                        alreadyAdded = true;
                        break;
                    }
                }
                if (!alreadyAdded && userProfiles[provider].isActive) { // Ensure profile is active
                    matchingProfiles[count++] = provider;
                }
            }
        }

        // Resize the array to the actual number of profiles found
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = matchingProfiles[i];
        }
        return result;
    }

    /// @notice Filters services by price range.
    /// @param _minPrice The minimum price.
    /// @param _maxPrice The maximum price.
    /// @return An array of Service IDs within the price range.
    function filterServicesByPriceRange(uint256 _minPrice, uint256 _maxPrice) public view returns (uint[] memory) {
        uint[] memory filteredServices = new uint[](nextServiceId); // Maximum possible size
        uint count = 0;
        for (uint i = 1; i < nextServiceId; i++) {
            if (services[i].isActive && services[i].price >= _minPrice && services[i].price <= _maxPrice) {
                filteredServices[count++] = i;
            }
        }
        // Resize the array
        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = filteredServices[i];
        }
        return result;
    }

    /// @notice Retrieves a list of trending skills based on service offerings and endorsements.
    /// @dev Simple heuristic: skills with more services and endorsements are considered trending.
    /// @return An array of trending skill names.
    function getTrendingSkills() public view returns (string[] memory) {
        // This is a very basic implementation. In a real application, trending algorithms can be much more complex.
        mapping(string => uint) skillScores;
        for (uint i = 1; i < nextServiceId; i++) {
            if (services[i].isActive) {
                string memory skillName = skillIdToName[services[i].skillId];
                skillScores[skillName] += 1; // Count service offerings
                // Also consider endorsements - but need to aggregate endorsements per skill name (not skillId)
                // This would require iterating through endorsements and mapping back to skill names, which can be inefficient.
                // For simplicity, we only consider service offerings for this basic trending example.
            }
        }

        string[] memory trendingSkills = new string[](skillNameToId.length); // Max possible skills
        uint count = 0;
        uint maxScore = 0; // Find the maximum score to normalize (optional)

        for (uint skillId = 1; skillId < nextSkillId; skillId++) {
            string memory skillName = skillIdToName[skillId];
            if (skillScores[skillName] > 0) { // Only consider skills with services
                trendingSkills[count++] = skillName;
                if (skillScores[skillName] > maxScore) {
                    maxScore = skillScores[skillName];
                }
            }
        }

        // Sort trending skills by score (descending) - bubble sort for simplicity, could use more efficient sorting
        for (uint i = 0; i < count - 1; i++) {
            for (uint j = 0; j < count - i - 1; j++) {
                if (skillScores[trendingSkills[j]] < skillScores[trendingSkills[j + 1]]) {
                    string memory temp = trendingSkills[j];
                    trendingSkills[j] = trendingSkills[j + 1];
                    trendingSkills[j + 1] = temp;
                }
            }
        }

        // Resize to actual trending skills found
        string[] memory result = new string[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = trendingSkills[i];
        }
        return result;
    }


    // --- Admin & Utility Functions ---

    /// @notice Sets the platform fee percentage. Only admin can call this function.
    /// @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) public onlyAdmin whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows the admin to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyAdmin whenNotPaused {
        uint256 amount = totalPlatformFees;
        totalPlatformFees = 0;
        payable(admin).transfer(amount);
        emit PlatformFeesWithdrawn(amount, admin);
    }

    /// @notice Pauses the contract, preventing most state-changing operations. Only admin can call this.
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Unpauses the contract, restoring normal functionality. Only admin can call this.
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Fallback function to accept Ether transfers (if needed for service payments - not fully implemented in this example).
    receive() external payable {}
}
```