```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill & Reputation Marketplace - SkillVerse
 * @author Bard (AI Assistant)
 * @notice A smart contract enabling a decentralized marketplace for users to showcase skills,
 * build reputation, offer services, and collaborate on projects.
 *
 * **Outline & Function Summary:**
 *
 * **1. User Profile Management:**
 *    - `registerUser(string _username, string _profileHash)`: Allows users to register a profile with a unique username and IPFS hash for detailed profile data.
 *    - `updateProfileHash(string _newProfileHash)`: Allows registered users to update their profile information stored on IPFS.
 *    - `getUsername(address _userAddress) view returns (string)`: Retrieves the username associated with a user address.
 *    - `getProfileHash(address _userAddress) view returns (string)`: Retrieves the IPFS profile hash associated with a user address.
 *    - `isUserRegistered(address _userAddress) view returns (bool)`: Checks if an address is registered as a user in the marketplace.
 *
 * **2. Skill Management:**
 *    - `addSkill(string _skillName)`: Allows registered users to add skills to their profile. Skills are unique and managed on-chain.
 *    - `removeSkill(string _skillName)`: Allows registered users to remove skills from their profile.
 *    - `getUserSkills(address _userAddress) view returns (string[] memory)`: Retrieves the list of skills associated with a user address.
 *    - `getAllSkills() view returns (string[] memory)`: Retrieves a list of all unique skills registered in the marketplace (for discovery/browsing).
 *
 * **3. Reputation & Endorsement System:**
 *    - `endorseSkill(address _targetUser, string _skillName)`: Allows registered users to endorse another user's skill. Endorsements contribute to reputation.
 *    - `getSkillEndorsements(address _userAddress, string _skillName) view returns (uint256)`: Retrieves the number of endorsements a user has for a specific skill.
 *    - `getUserReputation(address _userAddress) view returns (uint256)`: Calculates and returns a user's overall reputation score based on endorsements and other factors.
 *
 * **4. Service Offering & Job Board:**
 *    - `offerService(string _serviceTitle, string _serviceDescription, string[] memory _requiredSkills, uint256 _pricePerUnit, string _unitOfWork)`: Allows users to offer services, specifying details like title, description, required skills, price, and unit of work.
 *    - `updateServicePrice(uint256 _serviceId, uint256 _newPrice)`: Allows service providers to update the price of their offered service.
 *    - `deactivateService(uint256 _serviceId)`: Allows service providers to deactivate a service offering, making it unavailable for new orders.
 *    - `activateService(uint256 _serviceId)`: Allows service providers to reactivate a previously deactivated service offering.
 *    - `getServiceDetails(uint256 _serviceId) view returns (ServiceOffer memory)`: Retrieves detailed information about a specific service offering.
 *    - `getUserServices(address _userAddress) view returns (uint256[] memory)`: Retrieves a list of service IDs offered by a specific user.
 *    - `getAllActiveServices() view returns (uint256[] memory)`: Retrieves a list of IDs of all currently active service offerings.
 *
 * **5. Collaboration & Project Management (Simplified):**
 *    - `requestCollaboration(address _providerAddress, uint256 _serviceId, string _projectDescription, uint256 _unitsRequested)`: Allows users to request collaboration on a service, specifying units and project details.
 *    - `acceptCollaborationRequest(uint256 _requestId)`: Allows service providers to accept a collaboration request.
 *    - `markCollaborationCompleted(uint256 _requestId)`: Allows the service requester to mark a collaboration as completed, initiating payment (simplified).
 *
 * **6. Reputation Feedback & Dispute Resolution (Basic):**
 *    - `submitFeedback(uint256 _requestId, string _feedbackText, uint8 _rating)`: Allows requesters to submit feedback and a rating after a collaboration is completed.
 *    - `raiseDispute(uint256 _requestId, string _disputeReason)`: Allows users to raise a dispute for a collaboration request if issues arise (basic dispute mechanism).
 *
 * **7. Platform Management (Admin - Owner):**
 *    - `setPlatformFee(uint256 _newFeePercentage)`: Allows the contract owner to set a platform fee percentage for service transactions.
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows the contract owner to pause the entire contract for maintenance or emergencies.
 *    - `unpauseContract()`: Allows the contract owner to unpause the contract, resuming normal operations.
 */
contract SkillVerse {
    // --- State Variables ---

    address public owner;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    bool public paused = false;

    mapping(address => UserProfile) public userProfiles;
    mapping(string => bool) public registeredUsernames;
    string[] public allSkills; // List of unique skills
    mapping(string => bool) public skillExists; // Track if a skill exists
    mapping(address => mapping(string => uint256)) public skillEndorsements; // User -> Skill -> Endorsement Count

    ServiceOffer[] public serviceOffers;
    mapping(uint256 => CollaborationRequest) public collaborationRequests;
    uint256 public nextServiceOfferId = 0;
    uint256 public nextRequestId = 0;

    // --- Structs ---

    struct UserProfile {
        string username;
        string profileHash; // IPFS hash for detailed profile information
        string[] skills;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct ServiceOffer {
        uint256 id;
        address provider;
        string title;
        string description;
        string[] requiredSkills;
        uint256 pricePerUnit;
        string unitOfWork;
        bool isActive;
    }

    struct CollaborationRequest {
        uint256 id;
        address requester;
        uint256 serviceId;
        address provider; // Redundant, but helpful for lookup
        string projectDescription;
        uint256 unitsRequested;
        bool isAccepted;
        bool isCompleted;
        bool hasDispute;
        string disputeReason;
        string feedbackText;
        uint8 rating;
    }

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress, string newProfileHash);
    event SkillAdded(address userAddress, string skillName);
    event SkillRemoved(address userAddress, string skillName);
    event SkillEndorsed(address endorser, address endorsedUser, string skillName);
    event ServiceOffered(uint256 serviceId, address provider, string title);
    event ServicePriceUpdated(uint256 serviceId, uint256 newPrice);
    event ServiceDeactivated(uint256 serviceId);
    event ServiceActivated(uint256 serviceId);
    event CollaborationRequested(uint256 requestId, address requester, uint256 serviceId);
    event CollaborationAccepted(uint256 requestId);
    event CollaborationCompleted(uint256 requestId);
    event FeedbackSubmitted(uint256 requestId, address requester, uint8 rating);
    event DisputeRaised(uint256 requestId, address requester, string disputeReason);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ContractPaused(address owner);
    event ContractUnpaused(address owner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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
        require(userProfiles[msg.sender].isRegistered, "User must be registered.");
        _;
    }

    modifier validServiceId(uint256 _serviceId) {
        require(_serviceId < serviceOffers.length, "Invalid service ID.");
        _;
    }

    modifier serviceIsActive(uint256 _serviceId) {
        require(serviceOffers[_serviceId].isActive, "Service is not active.");
        _;
    }

    modifier validRequestId(uint256 _requestId) {
        require(_requestId < collaborationRequests.length, "Invalid request ID.");
        _;
    }

    modifier requestNotCompleted(uint256 _requestId) {
        require(!collaborationRequests[_requestId].isCompleted, "Request already completed.");
        _;
    }

    modifier requestNotDisputed(uint256 _requestId) {
        require(!collaborationRequests[_requestId].hasDispute, "Request already has a dispute.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- 1. User Profile Management ---

    function registerUser(string memory _username, string memory _profileHash) external whenNotPaused {
        require(!userProfiles[msg.sender].isRegistered, "User already registered.");
        require(!registeredUsernames[_username], "Username already taken.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be 1-32 characters long.");
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty.");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            skills: new string[](0), // Initialize with empty skill list
            reputationScore: 0,
            isRegistered: true
        });
        registeredUsernames[_username] = true;

        emit UserRegistered(msg.sender, _username);
    }

    function updateProfileHash(string memory _newProfileHash) external onlyRegisteredUser whenNotPaused {
        require(bytes(_newProfileHash).length > 0, "New profile hash cannot be empty.");
        userProfiles[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender, _newProfileHash);
    }

    function getUsername(address _userAddress) external view returns (string memory) {
        return userProfiles[_userAddress].username;
    }

    function getProfileHash(address _userAddress) external view returns (string memory) {
        return userProfiles[_userAddress].profileHash;
    }

    function isUserRegistered(address _userAddress) external view returns (bool) {
        return userProfiles[_userAddress].isRegistered;
    }

    // --- 2. Skill Management ---

    function addSkill(string memory _skillName) external onlyRegisteredUser whenNotPaused {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 50, "Skill name must be 1-50 characters long.");
        require(!skillExists[_skillName], "Skill already exists in the marketplace.");

        for (uint256 i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(bytes(userProfiles[msg.sender].skills[i])) == keccak256(bytes(_skillName))) {
                revert("Skill already added to your profile.");
            }
        }

        userProfiles[msg.sender].skills.push(_skillName);
        skillExists[_skillName] = true;
        allSkills.push(_skillName); // Add to the list of all skills

        emit SkillAdded(msg.sender, _skillName);
    }

    function removeSkill(string memory _skillName) external onlyRegisteredUser whenNotPaused {
        bool skillRemoved = false;
        string[] memory currentSkills = userProfiles[msg.sender].skills;
        string[] memory updatedSkills = new string[](currentSkills.length - 1);
        uint256 updatedIndex = 0;

        for (uint256 i = 0; i < currentSkills.length; i++) {
            if (keccak256(bytes(currentSkills[i])) != keccak256(bytes(_skillName))) {
                updatedSkills[updatedIndex] = currentSkills[i];
                updatedIndex++;
            } else {
                skillRemoved = true;
            }
        }

        require(skillRemoved, "Skill not found in your profile.");
        userProfiles[msg.sender].skills = updatedSkills;
        emit SkillRemoved(msg.sender, _skillName);
    }

    function getUserSkills(address _userAddress) external view returns (string[] memory) {
        return userProfiles[_userAddress].skills;
    }

    function getAllSkills() external view returns (string[] memory) {
        return allSkills;
    }


    // --- 3. Reputation & Endorsement System ---

    function endorseSkill(address _targetUser, string memory _skillName) external onlyRegisteredUser whenNotPaused {
        require(userProfiles[_targetUser].isRegistered, "Target user is not registered.");
        bool skillFound = false;
        for (uint256 i = 0; i < userProfiles[_targetUser].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_targetUser].skills[i])) == keccak256(bytes(_skillName))) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Target user does not have this skill.");
        require(msg.sender != _targetUser, "Cannot endorse your own skill.");

        skillEndorsements[_targetUser][_skillName]++;
        emit SkillEndorsed(msg.sender, _targetUser, _skillName);
    }

    function getSkillEndorsements(address _userAddress, string memory _skillName) external view returns (uint256) {
        return skillEndorsements[_userAddress][_skillName];
    }

    function getUserReputation(address _userAddress) external view returns (uint256) {
        uint256 totalEndorsements = 0;
        string[] memory userSkills = userProfiles[_userAddress].skills;
        for (uint256 i = 0; i < userSkills.length; i++) {
            totalEndorsements += skillEndorsements[_userAddress][userSkills[i]];
        }
        // Basic reputation calculation - can be customized (e.g., weight different skills, endorsements from high-reputation users, etc.)
        return totalEndorsements;
    }


    // --- 4. Service Offering & Job Board ---

    function offerService(
        string memory _serviceTitle,
        string memory _serviceDescription,
        string[] memory _requiredSkills,
        uint256 _pricePerUnit,
        string memory _unitOfWork
    ) external onlyRegisteredUser whenNotPaused {
        require(bytes(_serviceTitle).length > 0 && bytes(_serviceTitle).length <= 100, "Service title must be 1-100 characters long.");
        require(bytes(_serviceDescription).length > 0 && bytes(_serviceDescription).length <= 1000, "Service description must be 1-1000 characters long.");
        require(_requiredSkills.length > 0, "At least one required skill is needed.");
        require(_pricePerUnit > 0, "Price per unit must be greater than 0.");
        require(bytes(_unitOfWork).length > 0 && bytes(_unitOfWork).length <= 50, "Unit of work must be 1-50 characters long.");

        // Check if user has all required skills (optional - can be removed for a more open marketplace)
        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            bool hasSkill = false;
            for (uint256 j = 0; j < userProfiles[msg.sender].skills.length; j++) {
                if (keccak256(bytes(userProfiles[msg.sender].skills[j])) == keccak256(bytes(_requiredSkills[i]))) {
                    hasSkill = true;
                    break;
                }
            }
            require(hasSkill, "You do not possess all required skills for this service.");
        }


        serviceOffers.push(ServiceOffer({
            id: nextServiceOfferId,
            provider: msg.sender,
            title: _serviceTitle,
            description: _serviceDescription,
            requiredSkills: _requiredSkills,
            pricePerUnit: _pricePerUnit,
            unitOfWork: _unitOfWork,
            isActive: true
        }));

        emit ServiceOffered(nextServiceOfferId, msg.sender, _serviceTitle);
        nextServiceOfferId++;
    }

    function updateServicePrice(uint256 _serviceId, uint256 _newPrice) external onlyRegisteredUser validServiceId(_serviceId) whenNotPaused {
        require(serviceOffers[_serviceId].provider == msg.sender, "Only service provider can update price.");
        require(_newPrice > 0, "New price must be greater than 0.");
        serviceOffers[_serviceId].pricePerUnit = _newPrice;
        emit ServicePriceUpdated(_serviceId, _newPrice);
    }

    function deactivateService(uint256 _serviceId) external onlyRegisteredUser validServiceId(_serviceId) whenNotPaused serviceIsActive(_serviceId) {
        require(serviceOffers[_serviceId].provider == msg.sender, "Only service provider can deactivate service.");
        serviceOffers[_serviceId].isActive = false;
        emit ServiceDeactivated(_serviceId);
    }

    function activateService(uint256 _serviceId) external onlyRegisteredUser validServiceId(_serviceId) whenNotPaused {
        require(serviceOffers[_serviceId].provider == msg.sender, "Only service provider can activate service.");
        require(!serviceOffers[_serviceId].isActive, "Service is already active.");
        serviceOffers[_serviceId].isActive = true;
        emit ServiceActivated(_serviceId);
    }

    function getServiceDetails(uint256 _serviceId) external view validServiceId(_serviceId) returns (ServiceOffer memory) {
        return serviceOffers[_serviceId];
    }

    function getUserServices(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory userServices = new uint256[](0);
        for (uint256 i = 0; i < serviceOffers.length; i++) {
            if (serviceOffers[i].provider == _userAddress) {
                uint256[] memory temp = new uint256[](userServices.length + 1);
                for (uint256 j = 0; j < userServices.length; j++) {
                    temp[j] = userServices[j];
                }
                temp[userServices.length] = serviceOffers[i].id;
                userServices = temp;
            }
        }
        return userServices;
    }

    function getAllActiveServices() external view returns (uint256[] memory) {
        uint256[] memory activeServices = new uint256[](0);
        for (uint256 i = 0; i < serviceOffers.length; i++) {
            if (serviceOffers[i].isActive) {
                uint256[] memory temp = new uint256[](activeServices.length + 1);
                for (uint256 j = 0; j < activeServices.length; j++) {
                    temp[j] = activeServices[j];
                }
                temp[activeServices.length] = serviceOffers[i].id;
                activeServices = temp;
            }
        }
        return activeServices;
    }

    // --- 5. Collaboration & Project Management (Simplified) ---

    function requestCollaboration(
        address _providerAddress,
        uint256 _serviceId,
        string memory _projectDescription,
        uint256 _unitsRequested
    ) external onlyRegisteredUser validServiceId(_serviceId) whenNotPaused serviceIsActive(_serviceId) {
        require(_providerAddress != msg.sender, "Cannot request service from yourself.");
        require(serviceOffers[_serviceId].provider == _providerAddress, "Provider address does not match service provider.");
        require(_unitsRequested > 0, "Units requested must be greater than 0.");
        require(bytes(_projectDescription).length > 0 && bytes(_projectDescription).length <= 500, "Project description must be 1-500 characters long.");

        collaborationRequests.push(CollaborationRequest({
            id: nextRequestId,
            requester: msg.sender,
            serviceId: _serviceId,
            provider: _providerAddress,
            projectDescription: _projectDescription,
            unitsRequested: _unitsRequested,
            isAccepted: false,
            isCompleted: false,
            hasDispute: false,
            disputeReason: "",
            feedbackText: "",
            rating: 0
        }));

        emit CollaborationRequested(nextRequestId, msg.sender, _serviceId);
        nextRequestId++;
    }

    function acceptCollaborationRequest(uint256 _requestId) external onlyRegisteredUser validRequestId(_requestId) whenNotPaused requestNotCompleted(_requestId) requestNotDisputed(_requestId) {
        require(collaborationRequests[_requestId].provider == msg.sender, "Only service provider can accept request.");
        require(!collaborationRequests[_requestId].isAccepted, "Request already accepted.");
        collaborationRequests[_requestId].isAccepted = true;
        emit CollaborationAccepted(_requestId);
    }

    function markCollaborationCompleted(uint256 _requestId) external onlyRegisteredUser validRequestId(_requestId) whenNotPaused requestNotCompleted(_requestId) requestNotDisputed(_requestId) {
        require(collaborationRequests[_requestId].requester == msg.sender, "Only requester can mark collaboration as completed.");
        require(collaborationRequests[_requestId].isAccepted, "Request must be accepted before completion.");
        collaborationRequests[_requestId].isCompleted = true;

        // In a real application, payment logic would be here, potentially using escrow or other mechanisms.
        // For simplicity, this example skips direct payment within the contract.

        emit CollaborationCompleted(_requestId);
    }


    // --- 6. Reputation Feedback & Dispute Resolution (Basic) ---

    function submitFeedback(uint256 _requestId, string memory _feedbackText, uint8 _rating) external onlyRegisteredUser validRequestId(_requestId) whenNotPaused requestNotCompleted(_requestId) requestNotDisputed(_requestId) {
        require(collaborationRequests[_requestId].requester == msg.sender, "Only requester can submit feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_feedbackText).length <= 500, "Feedback text too long (max 500 chars).");
        require(collaborationRequests[_requestId].isAccepted, "Feedback can only be submitted after request is accepted.");

        CollaborationRequest storage request = collaborationRequests[_requestId];
        request.feedbackText = _feedbackText;
        request.rating = _rating;

        // In a more advanced system, feedback would contribute to provider's reputation more significantly.

        emit FeedbackSubmitted(_requestId, msg.sender, _rating);
    }


    function raiseDispute(uint256 _requestId, string memory _disputeReason) external onlyRegisteredUser validRequestId(_requestId) whenNotPaused requestNotCompleted(_requestId) requestNotDisputed(_requestId) {
        require(collaborationRequests[_requestId].requester == msg.sender || collaborationRequests[_requestId].provider == msg.sender, "Only requester or provider can raise dispute.");
        require(bytes(_disputeReason).length > 0 && bytes(_disputeReason).length <= 500, "Dispute reason must be 1-500 characters long.");
        require(collaborationRequests[_requestId].isAccepted, "Dispute can only be raised after request is accepted.");

        collaborationRequests[_requestId].hasDispute = true;
        collaborationRequests[_requestId].disputeReason = _disputeReason;
        emit DisputeRaised(_requestId, msg.sender, _disputeReason);

        // In a real-world scenario, a more complex dispute resolution mechanism would be implemented,
        // potentially involving a DAO or admin intervention. For this example, it's just flagged.
    }


    // --- 7. Platform Management (Admin - Owner) ---

    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        // In a real application, fees would be collected during service transactions.
        // This is a placeholder for fee withdrawal logic.
        uint256 contractBalance = address(this).balance;
        payable(owner).transfer(contractBalance); // Simple withdrawal of entire balance for demonstration
        emit PlatformFeesWithdrawn(owner, contractBalance);
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Fallback and Receive (Optional - for receiving ETH if needed) ---
    receive() external payable {}
    fallback() external payable {}
}
```