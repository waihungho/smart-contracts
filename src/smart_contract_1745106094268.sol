```solidity
/**
 * @title Decentralized Skill & Reputation Marketplace - SkillVerse
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace where users can showcase their skills,
 * build reputation, offer services, and engage in skill-based collaborations.
 *
 * **Outline & Function Summary:**
 *
 * **1. Skill Management:**
 *   - `addSkillCategory(string _categoryName)`: Allows admin to add new skill categories.
 *   - `addSkill(string _categoryName, string _skillName)`: Allows admin to add skills within a category.
 *   - `getUserSkills(address _user)`: Retrieves the skills associated with a user.
 *   - `listSkillCategories()`: Returns a list of all available skill categories.
 *   - `listSkillsInCategory(string _categoryName)`: Returns a list of skills within a specific category.
 *
 * **2. User Profile & Skill Endorsement:**
 *   - `createUserProfile(string _username, string _bio)`: Allows a user to create their profile.
 *   - `updateUserProfile(string _username, string _bio)`: Allows a user to update their profile.
 *   - `getUserProfile(address _user)`: Retrieves a user's profile information.
 *   - `endorseSkill(address _userToEndorse, string _skillName)`: Allows users to endorse each other's skills.
 *   - `getSkillEndorsements(address _user, string _skillName)`: Gets the number of endorsements for a specific skill of a user.
 *   - `getMyEndorsementsGiven()`: Retrieves a list of skills endorsed by the caller.
 *
 * **3. Service Offering & Job Posting:**
 *   - `offerService(string _skillName, string _description, uint256 _hourlyRate)`: Allows users to offer services based on their skills.
 *   - `updateServiceOffer(uint256 _offerId, string _description, uint256 _hourlyRate)`: Allows users to update their service offer.
 *   - `getServiceOffer(uint256 _offerId)`: Retrieves details of a specific service offer.
 *   - `getUserServiceOffers(address _user)`: Retrieves all service offers of a user.
 *   - `postJobRequest(string _skillName, string _description, uint256 _budget)`: Allows users to post job requests for specific skills.
 *   - `updateJobRequest(uint256 _requestId, string _description, uint256 _budget)`: Allows users to update their job request.
 *   - `getJobRequest(uint256 _requestId)`: Retrieves details of a specific job request.
 *   - `getAllJobRequests()`: Retrieves a list of all active job requests.
 *
 * **4. Reputation & Verification (Advanced Concept):**
 *   - `requestSkillVerification(string _skillName, string _evidenceURI)`: Allows users to request verification of a skill by the community (or oracles - concept).
 *   - `voteOnVerification(uint256 _verificationRequestId, bool _approve)`: Allows authorized users (e.g., reputation holders, DAOs - concept) to vote on skill verifications.
 *   - `getVerificationRequestStatus(uint256 _verificationRequestId)`: Retrieves the status of a skill verification request.
 *
 * **5. Utility & Admin Functions:**
 *   - `setAdmin(address _newAdmin)`: Allows current admin to set a new admin.
 *   - `withdrawContractBalance()`: Allows admin to withdraw contract's ether balance (e.g., fees - concept).
 */
pragma solidity ^0.8.0;

contract SkillVerse {

    // --- Structs & Enums ---

    struct UserProfile {
        string username;
        string bio;
        bool exists;
    }

    struct ServiceOffer {
        uint256 id;
        address provider;
        string skillName;
        string description;
        uint256 hourlyRate;
        bool isActive;
    }

    struct JobRequest {
        uint256 id;
        address requester;
        string skillName;
        string description;
        uint256 budget;
        bool isActive;
    }

    struct SkillVerificationRequest {
        uint256 id;
        address requester;
        string skillName;
        string evidenceURI;
        uint256 upvotes;
        uint256 downvotes;
        VerificationStatus status;
    }

    enum VerificationStatus {
        PENDING,
        APPROVED,
        REJECTED
    }

    // --- State Variables ---

    address public admin;
    uint256 public nextServiceOfferId;
    uint256 public nextJobRequestId;
    uint256 public nextVerificationRequestId;

    mapping(string => bool) public skillCategories; // Category Name -> Exists
    mapping(string => mapping(string => bool)) public skillsInCategory; // Category -> Skill Name -> Exists
    mapping(address => UserProfile) public userProfiles; // User Address -> Profile
    mapping(address => mapping(string => uint256)) public skillEndorsements; // User Address -> Skill Name -> Endorsement Count
    mapping(address => mapping(address => mapping(string => bool))) public endorsementsGiven; // Endorser -> Endorsee -> Skill -> Given
    mapping(uint256 => ServiceOffer) public serviceOffers; // Offer ID -> Service Offer
    mapping(uint256 => JobRequest) public jobRequests; // Request ID -> Job Request
    mapping(uint256 => SkillVerificationRequest) public verificationRequests; // Verification Request ID -> Request Data
    mapping(address => bool) public authorizedVerifiers; // Address authorized to vote on verifications (concept)


    // --- Events ---

    event AdminSet(address indexed newAdmin, address indexed oldAdmin);
    event SkillCategoryAdded(string categoryName);
    event SkillAddedToCategory(string categoryName, string skillName);
    event UserProfileCreated(address indexed user, string username);
    event UserProfileUpdated(address indexed user, string username);
    event SkillEndorsed(address indexed endorser, address indexed endorsee, string skillName);
    event ServiceOfferCreated(uint256 indexed offerId, address indexed provider, string skillName);
    event ServiceOfferUpdated(uint256 indexed offerId);
    event ServiceOfferDeactivated(uint256 indexed offerId);
    event JobRequestCreated(uint256 indexed requestId, address indexed requester, string skillName);
    event JobRequestUpdated(uint256 indexed requestId);
    event JobRequestDeactivated(uint256 indexed requestId);
    event SkillVerificationRequested(uint256 indexed requestId, address indexed requester, string skillName);
    event VerificationVoteCast(uint256 indexed requestId, address indexed voter, bool approved);
    event VerificationStatusUpdated(uint256 indexed requestId, VerificationStatus status);
    event ContractBalanceWithdrawn(address indexed admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].exists, "User profile does not exist.");
        _;
    }

    modifier skillCategoryExists(string _categoryName) {
        require(skillCategories[_categoryName], "Skill category does not exist.");
        _;
    }

    modifier skillExistsInCategory(string _categoryName, string _skillName) {
        require(skillsInCategory[_categoryName][_skillName], "Skill does not exist in this category.");
        _;
    }

    modifier serviceOfferExists(uint256 _offerId) {
        require(serviceOffers[_offerId].provider != address(0), "Service offer does not exist.");
        _;
    }

    modifier jobRequestExists(uint256 _requestId) {
        require(jobRequests[_requestId].requester != address(0), "Job request does not exist.");
        _;
    }

    modifier verificationRequestExists(uint256 _requestId) {
        require(verificationRequests[_requestId].requester != address(0), "Verification request does not exist.");
        _;
    }

    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Not an authorized verifier."); // Concept - expand authorization logic
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        emit AdminSet(admin, address(0));
    }

    // --- 1. Skill Management Functions ---

    function setAdmin(address _newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminSet(_newAdmin, oldAdmin);
    }

    function addSkillCategory(string memory _categoryName) external onlyAdmin {
        require(!skillCategories[_categoryName], "Skill category already exists.");
        skillCategories[_categoryName] = true;
        emit SkillCategoryAdded(_categoryName);
    }

    function addSkill(string memory _categoryName, string memory _skillName) external onlyAdmin skillCategoryExists(_categoryName) {
        require(!skillsInCategory[_categoryName][_skillName], "Skill already exists in this category.");
        skillsInCategory[_categoryName][_skillName] = true;
        emit SkillAddedToCategory(_categoryName, _skillName);
    }

    function getUserSkills(address _user) external view profileExists(_user) returns (string[] memory) {
        string[] memory userSkillList = new string[](0); // Initialize empty array
        for (string memory categoryName : getSkillCategories()) {
            for (string memory skillName : getSkillsInCategory(categoryName)) {
                if (skillEndorsements[_user][skillName] > 0) { // Consider skills with endorsements as "user skills"
                    userSkillList = _arrayPush(userSkillList, skillName);
                }
            }
        }
        return userSkillList;
    }

    function listSkillCategories() external view returns (string[] memory) {
        return getSkillCategories();
    }

    function listSkillsInCategory(string memory _categoryName) external view skillCategoryExists(_categoryName) returns (string[] memory) {
        return getSkillsInCategory(_categoryName);
    }

    // --- 2. User Profile & Skill Endorsement Functions ---

    function createUserProfile(string memory _username, string memory _bio) external {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this user.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            exists: true
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    function updateUserProfile(string memory _username, string memory _bio) external profileExists(msg.sender) {
        userProfiles[msg.sender].username = _username;
        userProfiles[msg.sender].bio = _bio;
        emit UserProfileUpdated(msg.sender, _username);
    }

    function getUserProfile(address _user) external view profileExists(_user) returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function endorseSkill(address _userToEndorse, string memory _skillName) external profileExists(_userToEndorse) {
        require(msg.sender != _userToEndorse, "Cannot endorse yourself.");
        require(!endorsementsGiven[msg.sender][_userToEndorse][_skillName], "Skill already endorsed by you for this user.");

        bool skillFound = false;
        for (string memory categoryName : getSkillCategories()) {
            if (skillsInCategory[categoryName][_skillName]) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Skill does not exist in any category.");

        skillEndorsements[_userToEndorse][_skillName]++;
        endorsementsGiven[msg.sender][_userToEndorse][_skillName] = true;
        emit SkillEndorsed(msg.sender, _userToEndorse, _skillName);
    }

    function getSkillEndorsements(address _user, string memory _skillName) external view profileExists(_user) returns (uint256) {
        return skillEndorsements[_user][_skillName];
    }

    function getMyEndorsementsGiven() external view profileExists(msg.sender) returns (string[] memory) {
        string[] memory endorsedSkills = new string[](0);
        address endorsee;
        string memory skillName;
        for (string memory categoryName : getSkillCategories()) {
            for (string memory currentSkillName : getSkillsInCategory(categoryName)) {
                if (endorsementsGiven[msg.sender][msg.sender][currentSkillName]) { // Iterate through potential endorsees - in efficient, needs improvement in real app
                    endorsedSkills = _arrayPush(endorsedSkills, currentSkillName);
                }
            }
        }
        return endorsedSkills;
    }


    // --- 3. Service Offering & Job Posting Functions ---

    function offerService(string memory _skillName, string memory _description, uint256 _hourlyRate) external profileExists(msg.sender) {
        bool skillFound = false;
        for (string memory categoryName : getSkillCategories()) {
            if (skillsInCategory[categoryName][_skillName]) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Skill does not exist in any category.");

        uint256 offerId = nextServiceOfferId++;
        serviceOffers[offerId] = ServiceOffer({
            id: offerId,
            provider: msg.sender,
            skillName: _skillName,
            description: _description,
            hourlyRate: _hourlyRate,
            isActive: true
        });
        emit ServiceOfferCreated(offerId, msg.sender, _skillName);
    }

    function updateServiceOffer(uint256 _offerId, string memory _description, uint256 _hourlyRate) external profileExists(msg.sender) serviceOfferExists(_offerId) {
        require(serviceOffers[_offerId].provider == msg.sender, "You are not the provider of this service offer.");
        serviceOffers[_offerId].description = _description;
        serviceOffers[_offerId].hourlyRate = _hourlyRate;
        emit ServiceOfferUpdated(_offerId);
    }

    function deactivateServiceOffer(uint256 _offerId) external profileExists(msg.sender) serviceOfferExists(_offerId) {
        require(serviceOffers[_offerId].provider == msg.sender, "You are not the provider of this service offer.");
        serviceOffers[_offerId].isActive = false;
        emit ServiceOfferDeactivated(_offerId);
    }

    function getServiceOffer(uint256 _offerId) external view serviceOfferExists(_offerId) returns (ServiceOffer memory) {
        return serviceOffers[_offerId];
    }

    function getUserServiceOffers(address _user) external view profileExists(_user) returns (ServiceOffer[] memory) {
        ServiceOffer[] memory userOffers = new ServiceOffer[](0);
        for (uint256 i = 0; i < nextServiceOfferId; i++) {
            if (serviceOffers[i].provider == _user && serviceOffers[i].isActive) {
                userOffers = _arrayPush(userOffers, serviceOffers[i]);
            }
        }
        return userOffers;
    }

    function postJobRequest(string memory _skillName, string memory _description, uint256 _budget) external profileExists(msg.sender) {
        bool skillFound = false;
        for (string memory categoryName : getSkillCategories()) {
            if (skillsInCategory[categoryName][_skillName]) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Skill does not exist in any category.");
        require(_budget > 0, "Budget must be greater than zero.");

        uint256 requestId = nextJobRequestId++;
        jobRequests[requestId] = JobRequest({
            id: requestId,
            requester: msg.sender,
            skillName: _skillName,
            description: _description,
            budget: _budget,
            isActive: true
        });
        emit JobRequestCreated(requestId, msg.sender, _skillName);
    }

    function updateJobRequest(uint256 _requestId, string memory _description, uint256 _budget) external profileExists(msg.sender) jobRequestExists(_requestId) {
        require(jobRequests[_requestId].requester == msg.sender, "You are not the requester of this job.");
        jobRequests[_requestId].description = _description;
        jobRequests[_requestId].budget = _budget;
        emit JobRequestUpdated(_requestId);
    }

    function deactivateJobRequest(uint256 _requestId) external profileExists(msg.sender) jobRequestExists(_requestId) {
        require(jobRequests[_requestId].requester == msg.sender, "You are not the requester of this job.");
        jobRequests[_requestId].isActive = false;
        emit JobRequestDeactivated(_requestId);
    }

    function getJobRequest(uint256 _requestId) external view jobRequestExists(_requestId) returns (JobRequest memory) {
        return jobRequests[_requestId];
    }

    function getAllJobRequests() external view returns (JobRequest[] memory) {
        JobRequest[] memory allRequests = new JobRequest[](0);
        for (uint256 i = 0; i < nextJobRequestId; i++) {
            if (jobRequests[i].isActive) {
                allRequests = _arrayPush(allRequests, jobRequests[i]);
            }
        }
        return allRequests;
    }


    // --- 4. Reputation & Verification Functions (Advanced Concept) ---

    function requestSkillVerification(string memory _skillName, string memory _evidenceURI) external profileExists(msg.sender) {
        bool skillFound = false;
        for (string memory categoryName : getSkillCategories()) {
            if (skillsInCategory[categoryName][_skillName]) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Skill does not exist in any category.");

        uint256 requestId = nextVerificationRequestId++;
        verificationRequests[requestId] = SkillVerificationRequest({
            id: requestId,
            requester: msg.sender,
            skillName: _skillName,
            evidenceURI: _evidenceURI,
            upvotes: 0,
            downvotes: 0,
            status: VerificationStatus.PENDING
        });
        emit SkillVerificationRequested(requestId, msg.sender, _skillName);
    }

    function voteOnVerification(uint256 _verificationRequestId, bool _approve) external onlyAuthorizedVerifier verificationRequestExists(_verificationRequestId) {
        require(verificationRequests[_verificationRequestId].status == VerificationStatus.PENDING, "Verification request is not pending.");
        SkillVerificationRequest storage request = verificationRequests[_verificationRequestId];
        if (_approve) {
            request.upvotes++;
        } else {
            request.downvotes++;
        }
        emit VerificationVoteCast(_verificationRequestId, msg.sender, _approve);

        // Simple majority rule for example, can be more complex DAO/reputation based logic
        if (request.upvotes > request.downvotes * 2) { // Example: 2:1 upvote ratio
            request.status = VerificationStatus.APPROVED;
            emit VerificationStatusUpdated(_verificationRequestId, VerificationStatus.APPROVED);
        } else if (request.downvotes > request.upvotes * 2) { // Example: 2:1 downvote ratio
            request.status = VerificationStatus.REJECTED;
            emit VerificationStatusUpdated(_verificationRequestId, VerificationStatus.REJECTED);
        }
    }

    function getVerificationRequestStatus(uint256 _verificationRequestId) external view verificationRequestExists(_verificationRequestId) returns (VerificationStatus) {
        return verificationRequests[_verificationRequestId].status;
    }


    // --- 5. Utility & Admin Functions ---

    function withdrawContractBalance() external onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit ContractBalanceWithdrawn(admin, balance);
    }

    // --- Helper Functions (Private/Internal) ---

    function getSkillCategories() private view returns (string[] memory) {
        string[] memory categories = new string[](0);
        for (uint256 i = 0; i < 20; i++) { // Limit to prevent infinite loop in case of large data
            string memory categoryName;
            uint256 index = 0;
            for (bytes memory keyBytes in skillCategories.keys()) { // Iterate through keys - gas intensive for large maps
                if (index == i) {
                    assembly {
                        categoryName := mload(add(keyBytes, 32)) // Assuming string is stored at offset 32
                    }
                    if (skillCategories[categoryName]) { // Double check existence
                        categories = _arrayPush(categories, categoryName);
                    }
                    break; // Exit inner loop once found
                }
                index++;
            }
             if (index == 0 && i > 0) break; // Optimization: if no keys, and not first iteration, break
        }
        return categories;
    }

    function getSkillsInCategory(string memory _categoryName) private view skillCategoryExists(_categoryName) returns (string[] memory) {
        string[] memory skills = new string[](0);
        for (uint256 i = 0; i < 100; i++) { // Limit to prevent infinite loop
            string memory skillName;
            uint256 index = 0;
             for (bytes memory keyBytes in skillsInCategory[_categoryName].keys()) { // Iterate through keys - gas intensive for large maps
                if (index == i) {
                    assembly {
                        skillName := mload(add(keyBytes, 32)) // Assuming string is stored at offset 32
                    }
                    if (skillsInCategory[_categoryName][skillName]) { // Double check existence
                         skills = _arrayPush(skills, skillName);
                    }
                    break; // Exit inner loop once found
                }
                index++;
            }
            if (index == 0 && i > 0) break; // Optimization: if no keys, and not first iteration, break
        }
        return skills;
    }


    function _arrayPush(string[] memory _array, string memory _value) private pure returns (string[] memory) {
        string[] memory newArray = new string[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }

    function _arrayPush(ServiceOffer[] memory _array, ServiceOffer memory _value) private pure returns (ServiceOffer[] memory) {
        ServiceOffer[] memory newArray = new ServiceOffer[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }

    function _arrayPush(JobRequest[] memory _array, JobRequest memory _value) private pure returns (JobRequest[] memory) {
        JobRequest[] memory newArray = new JobRequest[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }
}
```