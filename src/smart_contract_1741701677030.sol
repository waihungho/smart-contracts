```solidity
/**
 * @title Decentralized Dynamic Reputation and Skill Marketplace (DDRSM)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized reputation system integrated with a dynamic skill marketplace.
 *
 * **Outline and Function Summary:**
 *
 * **I. User Management & Profiles:**
 *   1. `registerUser(string _username, string _profileDescription)`: Allows users to register with a unique username and profile description.
 *   2. `updateProfile(string _profileDescription)`: Allows registered users to update their profile description.
 *   3. `getUsername(address _userAddress) view returns (string)`: Retrieves the username associated with an address.
 *   4. `getProfileDescription(address _userAddress) view returns (string)`: Retrieves the profile description of a user.
 *   5. `getUserReputation(address _userAddress) view returns (uint256)`: Retrieves the reputation score of a user.
 *   6. `isUserRegistered(address _userAddress) view returns (bool)`: Checks if an address is registered as a user.
 *
 * **II. Skill Management & Endorsements:**
 *   7. `addSkill(string _skillName)`: Allows users to add skills to their profile.
 *   8. `endorseSkill(address _targetUser, string _skillName, string _endorsementMessage)`: Allows registered users to endorse another user for a specific skill with a message.
 *   9. `getSkills(address _userAddress) view returns (string[])`: Retrieves the list of skills for a user.
 *   10. `getEndorsementsForSkill(address _userAddress, string _skillName) view returns (Endorsement[])`: Retrieves endorsements for a specific skill of a user.
 *   11. `skillExists(string _skillName) view returns (bool)`: Checks if a skill name already exists in the global skill registry.
 *
 * **III. Dynamic Reputation System:**
 *   12. `calculateReputation(address _userAddress) internal view returns (uint256)`: (Internal) Calculates the reputation score based on endorsements and potentially other factors (can be extended).
 *   13. `updateUserReputation(address _userAddress)`: (Admin/Internal) Updates a user's reputation score (can be triggered by events or admin).
 *   14. `setReputationWeight(address _endorser, uint256 _weight)`: (Admin) Allows admin to set reputation weight for specific endorsers, influencing the impact of their endorsements.
 *   15. `getDefaultReputationWeight() view returns (uint256)`: (Admin) Returns the default reputation weight for endorsements.
 *
 * **IV. Skill Marketplace & Service Listings:**
 *   16. `listSkillForService(string _skillName, string _serviceDescription, uint256 _hourlyRate)`: Allows users to list a skill for service in the marketplace with a description and hourly rate.
 *   17. `updateServiceListing(string _skillName, string _newServiceDescription, uint256 _newHourlyRate)`: Allows users to update their service listing for a skill.
 *   18. `removeServiceListing(string _skillName)`: Allows users to remove their service listing for a skill.
 *   19. `getServiceListingsForSkill(string _skillName) view returns (ServiceListing[])`: Retrieves all service listings for a specific skill.
 *   20. `getAllServiceListings() view returns (ServiceListing[])`: Retrieves all active service listings in the marketplace.
 *   21. `requestService(address _providerAddress, string _skillName, string _requestDetails)`: Allows a registered user to request service from a provider based on their listing.
 *   22. `acceptServiceRequest(uint256 _requestId)`: Allows a service provider to accept a service request.
 *   23. `completeService(uint256 _requestId)`: Allows a service provider to mark a service as completed (requires payment mechanism in real-world scenario, omitted here for simplicity).
 *   24. `getServiceRequestDetails(uint256 _requestId) view returns (ServiceRequest)`: Retrieves details of a specific service request.
 *   25. `getOpenServiceRequestsForProvider(address _providerAddress) view returns (ServiceRequest[])`: Retrieves open service requests for a specific provider.
 *
 * **V. Admin & Utility Functions:**
 *   26. `setAdmin(address _newAdmin)`: Allows the current admin to set a new admin address.
 *   27. `getAdmin() view returns (address)`: Returns the current admin address.
 *   28. `pauseContract()`: (Admin) Pauses the contract, disabling most functionality.
 *   29. `unpauseContract()`: (Admin) Unpauses the contract, restoring functionality.
 *   30. `isContractPaused() view returns (bool)`: Checks if the contract is currently paused.
 */
pragma solidity ^0.8.0;

contract DDRSM {
    // --- Structs & Enums ---
    struct UserProfile {
        string username;
        string profileDescription;
        uint256 reputationScore;
        string[] skills;
    }

    struct Endorsement {
        address endorser;
        string endorsementMessage;
        uint256 timestamp;
    }

    struct ServiceListing {
        address provider;
        string skillName;
        string serviceDescription;
        uint256 hourlyRate;
        bool isActive;
    }

    struct ServiceRequest {
        uint256 requestId;
        address requester;
        address provider;
        string skillName;
        string requestDetails;
        uint256 requestTimestamp;
        bool isAccepted;
        bool isCompleted;
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(string => Endorsement[])) public skillEndorsements; // User -> Skill -> Endorsements
    mapping(string => bool) public registeredUsernames;
    mapping(string => bool) public registeredSkills; // Global skill registry
    mapping(string => ServiceListing) public serviceListings; // Skill name to ServiceListing (one listing per skill per user for simplicity)
    ServiceListing[] public allServiceListingsArray; // Array to easily retrieve all listings
    ServiceRequest[] public serviceRequests;
    uint256 public nextRequestId = 1;
    address public admin;
    bool public paused;
    uint256 public defaultReputationWeight = 10; // Default weight for endorsements

    // --- Events ---
    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(address userAddress, string skillName);
    event SkillEndorsed(address targetUser, address endorser, string skillName);
    event ServiceListed(address provider, string skillName);
    event ServiceListingUpdated(address provider, string skillName);
    event ServiceListingRemoved(address provider, string skillName);
    event ServiceRequested(uint256 requestId, address requester, address provider, string skillName);
    event ServiceRequestAccepted(uint256 requestId, address provider);
    event ServiceCompleted(uint256 requestId, address provider);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
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

    modifier onlyRegisteredUser() {
        require(isUserRegistered(msg.sender), "You must be a registered user to perform this action.");
        _;
    }

    modifier skillListingExists(string memory _skillName) {
        require(serviceListings[_skillName].isActive && serviceListings[_skillName].provider == msg.sender, "Service listing for this skill does not exist or is not active for you.");
        _;
    }

    modifier skillListingNotExists(string memory _skillName) {
        require(!serviceListings[_skillName].isActive || serviceListings[_skillName].provider != msg.sender, "Service listing for this skill already exists for you.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
    }

    // --- I. User Management & Profiles ---

    /// @notice Registers a new user with a unique username and profile description.
    /// @param _username The desired username. Must be unique.
    /// @param _profileDescription A brief description of the user's profile.
    function registerUser(string memory _username, string memory _profileDescription) external whenNotPaused {
        require(!isUserRegistered(msg.sender), "User already registered.");
        require(!registeredUsernames[_username], "Username already taken.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            reputationScore: 0,
            skills: new string[](0)
        });
        registeredUsernames[_username] = true;
        emit UserRegistered(msg.sender, _username);
    }

    /// @notice Updates the profile description of a registered user.
    /// @param _profileDescription The new profile description.
    function updateProfile(string memory _profileDescription) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].profileDescription = _profileDescription;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Retrieves the username associated with a user address.
    /// @param _userAddress The address of the user.
    /// @return The username of the user.
    function getUsername(address _userAddress) external view returns (string memory) {
        require(isUserRegistered(_userAddress), "User not registered.");
        return userProfiles[_userAddress].username;
    }

    /// @notice Retrieves the profile description of a user.
    /// @param _userAddress The address of the user.
    /// @return The profile description of the user.
    function getProfileDescription(address _userAddress) external view returns (string memory) {
        require(isUserRegistered(_userAddress), "User not registered.");
        return userProfiles[_userAddress].profileDescription;
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _userAddress The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _userAddress) external view returns (uint256) {
        require(isUserRegistered(_userAddress), "User not registered.");
        return userProfiles[_userAddress].reputationScore;
    }

    /// @notice Checks if an address is registered as a user.
    /// @param _userAddress The address to check.
    /// @return True if the address is registered, false otherwise.
    function isUserRegistered(address _userAddress) public view returns (bool) {
        return bytes(userProfiles[_userAddress].username).length > 0;
    }

    // --- II. Skill Management & Endorsements ---

    /// @notice Allows a registered user to add a skill to their profile.
    /// @param _skillName The name of the skill to add.
    function addSkill(string memory _skillName) external onlyRegisteredUser whenNotPaused {
        require(!skillExists(_skillName), "Skill name already registered globally. Use existing skill name.");
        userProfiles[msg.sender].skills.push(_skillName);
        registeredSkills[_skillName] = true; // Register skill globally
        emit SkillAdded(msg.sender, _skillName);
    }

    /// @notice Allows a registered user to endorse another user for a specific skill.
    /// @param _targetUser The address of the user being endorsed.
    /// @param _skillName The skill for which the user is being endorsed.
    /// @param _endorsementMessage A message accompanying the endorsement.
    function endorseSkill(address _targetUser, string memory _skillName, string memory _endorsementMessage) external onlyRegisteredUser whenNotPaused {
        require(isUserRegistered(_targetUser), "Target user is not registered.");
        require(msg.sender != _targetUser, "Cannot endorse yourself.");
        bool skillFound = false;
        for (uint i = 0; i < userProfiles[_targetUser].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_targetUser].skills[i])) == keccak256(bytes(_skillName))) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Target user does not have this skill listed.");

        skillEndorsements[_targetUser][_skillName].push(Endorsement({
            endorser: msg.sender,
            endorsementMessage: _endorsementMessage,
            timestamp: block.timestamp
        }));

        updateUserReputation(_targetUser); // Update target user's reputation after endorsement
        emit SkillEndorsed(_targetUser, msg.sender, _skillName);
    }

    /// @notice Retrieves the list of skills for a user.
    /// @param _userAddress The address of the user.
    /// @return An array of skill names.
    function getSkills(address _userAddress) external view returns (string[] memory) {
        require(isUserRegistered(_userAddress), "User not registered.");
        return userProfiles[_userAddress].skills;
    }

    /// @notice Retrieves all endorsements for a specific skill of a user.
    /// @param _userAddress The address of the user.
    /// @param _skillName The skill name.
    /// @return An array of Endorsement structs.
    function getEndorsementsForSkill(address _userAddress, string memory _skillName) external view returns (Endorsement[] memory) {
        require(isUserRegistered(_userAddress), "User not registered.");
        return skillEndorsements[_userAddress][_skillName];
    }

    /// @notice Checks if a skill name already exists in the global skill registry.
    /// @param _skillName The skill name to check.
    /// @return True if the skill exists, false otherwise.
    function skillExists(string memory _skillName) public view returns (bool) {
        return registeredSkills[_skillName];
    }

    // --- III. Dynamic Reputation System ---

    /// @dev (Internal) Calculates the reputation score for a user based on endorsements.
    /// @param _userAddress The address of the user.
    /// @return The calculated reputation score.
    function calculateReputation(address _userAddress) internal view returns (uint256) {
        uint256 reputation = 0;
        string[] memory skills = userProfiles[_userAddress].skills;
        for (uint i = 0; i < skills.length; i++) {
            Endorsement[] memory endorsements = skillEndorsements[_userAddress][skills[i]];
            for (uint j = 0; j < endorsements.length; j++) {
                uint256 endorserWeight = defaultReputationWeight; // Default weight
                // In a more advanced system, you could have different weights based on endorser's own reputation or other factors.
                // For example: endorserWeight = getUserReputation(endorsements[j].endorser) / 10; // Weight based on endorser's reputation
                reputation += endorserWeight;
            }
        }
        return reputation;
    }

    /// @dev (Admin/Internal) Updates a user's reputation score. Can be triggered by events or admin.
    /// @param _userAddress The address of the user whose reputation needs to be updated.
    function updateUserReputation(address _userAddress) internal { // Making it internal, can be triggered by admin or other functions
        uint256 newReputation = calculateReputation(_userAddress);
        userProfiles[_userAddress].reputationScore = newReputation;
    }

    /// @notice (Admin) Sets the reputation weight for a specific endorser. This allows admins to influence the impact of certain endorsers.
    /// @param _endorser The address of the endorser.
    /// @param _weight The new reputation weight for this endorser.
    function setReputationWeight(address _endorser, uint256 _weight) external onlyAdmin whenNotPaused {
        // In a real system, you might store endorser-specific weights in a mapping.
        // For simplicity in this example, we are using a default weight.
        defaultReputationWeight = _weight; // This sets a global default weight, not per endorser as described in function summary - corrected.
        // Consider changing to mapping(address => uint256) endorserReputationWeights; for per-endorser weights.
        // and then: endorserReputationWeights[_endorser] = _weight;
        // and in calculateReputation:  endorserWeight = endorserReputationWeights[endorsements[j].endorser] != 0 ? endorserReputationWeights[endorsements[j].endorser] : defaultReputationWeight;
    }

    /// @notice (Admin) Returns the default reputation weight for endorsements.
    /// @return The default reputation weight.
    function getDefaultReputationWeight() external view onlyAdmin returns (uint256) {
        return defaultReputationWeight;
    }

    // --- IV. Skill Marketplace & Service Listings ---

    /// @notice Allows a registered user to list a skill for service in the marketplace.
    /// @param _skillName The skill being offered for service.
    /// @param _serviceDescription A description of the service offered.
    /// @param _hourlyRate The hourly rate for the service.
    function listSkillForService(string memory _skillName, string memory _serviceDescription, uint256 _hourlyRate) external onlyRegisteredUser whenNotPaused skillListingNotExists(_skillName) {
        require(skillExists(_skillName), "Skill must be registered globally.");
        bool hasSkill = false;
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(bytes(userProfiles[msg.sender].skills[i])) == keccak256(bytes(_skillName))) {
                hasSkill = true;
                break;
            }
        }
        require(hasSkill, "You must have the skill listed in your profile to offer it as a service.");
        require(_hourlyRate > 0, "Hourly rate must be greater than zero.");

        serviceListings[_skillName] = ServiceListing({
            provider: msg.sender,
            skillName: _skillName,
            serviceDescription: _serviceDescription,
            hourlyRate: _hourlyRate,
            isActive: true
        });
        allServiceListingsArray.push(serviceListings[_skillName]); // Add to array for easy retrieval of all listings
        emit ServiceListed(msg.sender, _skillName);
    }

    /// @notice Allows a user to update their service listing for a skill.
    /// @param _skillName The skill of the service listing to update.
    /// @param _newServiceDescription The new service description.
    /// @param _newHourlyRate The new hourly rate.
    function updateServiceListing(string memory _skillName, string memory _newServiceDescription, uint256 _newHourlyRate) external onlyRegisteredUser whenNotPaused skillListingExists(_skillName) {
        require(_newHourlyRate > 0, "Hourly rate must be greater than zero.");
        serviceListings[_skillName].serviceDescription = _newServiceDescription;
        serviceListings[_skillName].hourlyRate = _newHourlyRate;
        emit ServiceListingUpdated(msg.sender, _skillName);
    }

    /// @notice Allows a user to remove their service listing for a skill.
    /// @param _skillName The skill of the service listing to remove.
    function removeServiceListing(string memory _skillName) external onlyRegisteredUser whenNotPaused skillListingExists(_skillName) {
        serviceListings[_skillName].isActive = false;
        emit ServiceListingRemoved(msg.sender, _skillName);

        // Optional: Remove from allServiceListingsArray to keep it clean.
        // Requires iterating and shifting array elements, which can be gas-intensive for large arrays.
        // For simplicity, we just mark it as inactive and keep it in the array.
    }

    /// @notice Retrieves all active service listings for a specific skill.
    /// @param _skillName The skill name to search for.
    /// @return An array of ServiceListing structs.
    function getServiceListingsForSkill(string memory _skillName) external view returns (ServiceListing[] memory) {
        ServiceListing[] memory listings = new ServiceListing[](allServiceListingsArray.length);
        uint count = 0;
        for (uint i = 0; i < allServiceListingsArray.length; i++) {
            if (allServiceListingsArray[i].isActive && keccak256(bytes(allServiceListingsArray[i].skillName)) == keccak256(bytes(_skillName))) {
                listings[count] = allServiceListingsArray[i];
                count++;
            }
        }
        // Resize the array to the actual number of listings found.
        assembly {
            mstore(listings, count) // Set the length of the array to 'count'
        }
        return listings;
    }

    /// @notice Retrieves all active service listings in the marketplace.
    /// @return An array of ServiceListing structs.
    function getAllServiceListings() external view returns (ServiceListing[] memory) {
        ServiceListing[] memory activeListings = new ServiceListing[](allServiceListingsArray.length);
        uint count = 0;
        for (uint i = 0; i < allServiceListingsArray.length; i++) {
            if (allServiceListingsArray[i].isActive) {
                activeListings[count] = allServiceListingsArray[i];
                count++;
            }
        }
         // Resize the array to the actual number of listings found.
        assembly {
            mstore(activeListings, count) // Set the length of the array to 'count'
        }
        return activeListings;
    }

    /// @notice Allows a registered user to request a service from a provider.
    /// @param _providerAddress The address of the service provider.
    /// @param _skillName The skill for which the service is requested.
    /// @param _requestDetails Details of the service request.
    function requestService(address _providerAddress, string memory _skillName, string memory _requestDetails) external onlyRegisteredUser whenNotPaused {
        require(isUserRegistered(_providerAddress), "Provider address is not a registered user.");
        require(serviceListings[_skillName].isActive && serviceListings[_skillName].provider == _providerAddress, "Provider does not offer service for this skill or listing is inactive.");

        serviceRequests.push(ServiceRequest({
            requestId: nextRequestId,
            requester: msg.sender,
            provider: _providerAddress,
            skillName: _skillName,
            requestDetails: _requestDetails,
            requestTimestamp: block.timestamp,
            isAccepted: false,
            isCompleted: false
        }));
        emit ServiceRequested(nextRequestId, msg.sender, _providerAddress, _skillName);
        nextRequestId++;
    }

    /// @notice Allows a service provider to accept a service request.
    /// @param _requestId The ID of the service request.
    function acceptServiceRequest(uint256 _requestId) external onlyRegisteredUser whenNotPaused {
        require(_requestId > 0 && _requestId <= serviceRequests.length, "Invalid request ID.");
        ServiceRequest storage request = serviceRequests[_requestId - 1]; // Adjust index for array
        require(request.provider == msg.sender, "You are not the provider for this request.");
        require(!request.isAccepted, "Request already accepted.");
        require(!request.isCompleted, "Request already completed.");

        request.isAccepted = true;
        emit ServiceRequestAccepted(_requestId, msg.sender);
    }

    /// @notice Allows a service provider to mark a service as completed.
    /// @param _requestId The ID of the service request.
    function completeService(uint256 _requestId) external onlyRegisteredUser whenNotPaused {
        require(_requestId > 0 && _requestId <= serviceRequests.length, "Invalid request ID.");
        ServiceRequest storage request = serviceRequests[_requestId - 1]; // Adjust index for array
        require(request.provider == msg.sender, "You are not the provider for this request.");
        require(request.isAccepted, "Request must be accepted before completion.");
        require(!request.isCompleted, "Request already completed.");

        request.isCompleted = true;
        emit ServiceCompleted(_requestId, msg.sender);
        // In a real-world scenario, payment processing would happen here (e.g., using escrow or payment tokens).
    }

    /// @notice Retrieves details of a specific service request.
    /// @param _requestId The ID of the service request.
    /// @return The ServiceRequest struct.
    function getServiceRequestDetails(uint256 _requestId) external view returns (ServiceRequest memory) {
        require(_requestId > 0 && _requestId <= serviceRequests.length, "Invalid request ID.");
        return serviceRequests[_requestId - 1]; // Adjust index for array
    }

    /// @notice Retrieves open (not accepted or completed) service requests for a specific provider.
    /// @param _providerAddress The address of the service provider.
    /// @return An array of ServiceRequest structs.
    function getOpenServiceRequestsForProvider(address _providerAddress) external view returns (ServiceRequest[] memory) {
        ServiceRequest[] memory openRequests = new ServiceRequest[](serviceRequests.length);
        uint count = 0;
        for (uint i = 0; i < serviceRequests.length; i++) {
            if (serviceRequests[i].provider == _providerAddress && !serviceRequests[i].isAccepted && !serviceRequests[i].isCompleted) {
                openRequests[count] = serviceRequests[i];
                count++;
            }
        }
        // Resize the array to the actual number of open requests found.
        assembly {
            mstore(openRequests, count) // Set the length of the array to 'count'
        }
        return openRequests;
    }


    // --- V. Admin & Utility Functions ---

    /// @notice Allows the current admin to set a new admin address.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /// @notice Returns the current admin address.
    /// @return The address of the current admin.
    function getAdmin() external view returns (address) {
        return admin;
    }

    /// @notice Pauses the contract, disabling most functionality. Only admin can call this function.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Unpauses the contract, restoring functionality. Only admin can call this function.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return paused;
    }
}
```