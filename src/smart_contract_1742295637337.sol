```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Skill Marketplace - SkillVerse
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace where users can offer and request services based on skills,
 * with a built-in reputation system, skill verification, dynamic pricing, and advanced governance features.
 *
 * Outline & Function Summary:
 *
 * 1.  **User Profile Management:**
 *     - `registerUser(string _userName, string _profileDescription)`: Allows users to register with a username and profile description.
 *     - `updateUserProfile(string _profileDescription)`: Allows registered users to update their profile description.
 *     - `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 *     - `setUsername(string _newUsername)`: Allows users to change their username.
 *
 * 2.  **Skill Management:**
 *     - `addSkillCategory(string _categoryName)`: Platform admin can add new skill categories (e.g., "Programming", "Design", "Writing").
 *     - `addSkill(uint256 _categoryId, string _skillName)`: Platform admin can add specific skills within a category (e.g., "Solidity Development" in "Programming").
 *     - `listSkills()`: Retrieves a list of all skill categories and skills within them.
 *     - `addUserSkill(uint256 _skillId)`: Users can add skills to their profile to showcase their expertise.
 *     - `removeUserSkill(uint256 _skillId)`: Users can remove skills from their profile.
 *     - `getUserSkills(address _userAddress)`: Retrieves a list of skills associated with a user.
 *
 * 3.  **Service Offering and Requesting:**
 *     - `createServiceOffer(uint256 _skillId, string _serviceDescription, uint256 _pricePerUnit, string _unitOfService)`: Users can create service offers based on their skills, defining description, price, and unit of service.
 *     - `updateServiceOffer(uint256 _offerId, string _serviceDescription, uint256 _pricePerUnit, string _unitOfService)`: Allow service providers to update their existing offers.
 *     - `cancelServiceOffer(uint256 _offerId)`: Allows service providers to cancel their service offers.
 *     - `requestService(uint256 _offerId, uint256 _unitsRequested, string _requestDetails)`: Users can request a service based on an offer, specifying units and details.
 *     - `acceptServiceRequest(uint256 _requestId)`: Service providers can accept a service request.
 *     - `submitServiceCompletion(uint256 _requestId, string _completionDetails)`: Service providers submit proof of service completion.
 *     - `approveServiceCompletion(uint256 _requestId)`: Service requesters approve service completion and release payment.
 *     - `rejectServiceCompletion(uint256 _requestId, string _rejectionReason)`: Service requesters can reject completion if not satisfied, initiating a dispute process.
 *
 * 4.  **Reputation and Review System:**
 *     - `submitReview(uint256 _requestId, uint8 _rating, string _reviewText)`: After service completion, both requesters and providers can submit reviews and ratings for each other.
 *     - `getAverageRating(address _userAddress)`: Retrieves the average rating of a user based on reviews received.
 *     - `getUserReviews(address _userAddress)`: Retrieves a list of reviews received by a user.
 *
 * 5.  **Dispute Resolution (Simplified):**
 *     - `openDispute(uint256 _requestId, string _disputeReason)`: Service requesters can open a dispute if service completion is rejected.
 *     - `resolveDispute(uint256 _requestId, bool _providerWins)`: Platform admin (or a decentralized governance mechanism in a more advanced version) can resolve disputes.
 *
 * 6.  **Platform Administration & Settings:**
 *     - `setPlatformFee(uint256 _feePercentage)`: Platform admin can set a platform fee percentage on service transactions.
 *     - `withdrawPlatformFees()`: Platform admin can withdraw accumulated platform fees.
 *     - `pauseContract()`: Platform admin can pause the contract in case of emergency.
 *     - `unpauseContract()`: Platform admin can unpause the contract.
 *     - `addPlatformAdmin(address _newAdmin)`: Platform admin can add new platform administrators.
 *     - `removePlatformAdmin(address _adminToRemove)`: Platform admin can remove platform administrators.
 */

contract DecentralizedSkillMarketplace {
    // --- Structs and Enums ---
    struct UserProfile {
        address userAddress;
        string userName;
        string profileDescription;
        uint256 registrationTimestamp;
    }

    struct SkillCategory {
        uint256 categoryId;
        string categoryName;
    }

    struct Skill {
        uint256 skillId;
        uint256 categoryId;
        string skillName;
    }

    struct ServiceOffer {
        uint256 offerId;
        address providerAddress;
        uint256 skillId;
        string serviceDescription;
        uint256 pricePerUnit;
        string unitOfService;
        bool isActive;
        uint256 creationTimestamp;
    }

    enum ServiceRequestStatus {
        Pending,
        Accepted,
        Completed,
        Approved,
        Rejected,
        DisputeOpened,
        DisputeResolved
    }

    struct ServiceRequest {
        uint256 requestId;
        uint256 offerId;
        address requesterAddress;
        address providerAddress; // Redundant but useful for quick access
        uint256 unitsRequested;
        string requestDetails;
        ServiceRequestStatus status;
        uint256 requestTimestamp;
        uint256 completionTimestamp;
        string completionDetails;
        string rejectionReason;
        uint256 disputeOpenTimestamp;
        string disputeReason;
        bool disputeResolvedInFavorOfProvider;
    }

    struct Review {
        address reviewerAddress;
        address reviewedAddress;
        uint256 requestId;
        uint8 rating; // 1-5 stars
        string reviewText;
        uint256 reviewTimestamp;
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => SkillCategory) public skillCategories;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => ServiceOffer) public serviceOffers;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => Review) public reviews;
    mapping(address => mapping(uint256 => bool)) public userSkills; // Mapping user address to skillId to boolean (hasSkill)
    mapping(address => uint256[]) public userReviewIds; // Store review IDs for each user

    uint256 public platformFeePercentage = 5; // 5% default platform fee
    address public platformOwner;
    bool public paused = false;

    uint256 private _userIdCounter = 1;
    uint256 private _skillCategoryIdCounter = 1;
    uint256 private _skillIdCounter = 1;
    uint256 private _serviceOfferIdCounter = 1;
    uint256 private _serviceRequestIdCounter = 1;
    uint256 private _reviewIdCounter = 1;

    address[] public platformAdmins;

    // --- Events ---
    event UserRegistered(address userAddress, string userName);
    event UserProfileUpdated(address userAddress);
    event UsernameUpdated(address userAddress, string newUsername);
    event SkillCategoryAdded(uint256 categoryId, string categoryName);
    event SkillAdded(uint256 skillId, uint256 categoryId, string skillName);
    event UserSkillAdded(address userAddress, uint256 skillId);
    event UserSkillRemoved(address userAddress, uint256 skillId);
    event ServiceOfferCreated(uint256 offerId, address providerAddress, uint256 skillId);
    event ServiceOfferUpdated(uint256 offerId);
    event ServiceOfferCancelled(uint256 offerId);
    event ServiceRequested(uint256 requestId, uint256 offerId, address requesterAddress);
    event ServiceRequestAccepted(uint256 requestId);
    event ServiceCompletionSubmitted(uint256 requestId);
    event ServiceCompletionApproved(uint256 requestId);
    event ServiceCompletionRejected(uint256 requestId);
    event ReviewSubmitted(uint256 reviewId, address reviewerAddress, address reviewedAddress, uint256 requestId);
    event DisputeOpened(uint256 requestId);
    event DisputeResolved(uint256 requestId, bool providerWins);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address adminAddress, uint256 amount);
    event ContractPaused(address adminAddress);
    event ContractUnpaused(address adminAddress);
    event PlatformAdminAdded(address newAdmin);
    event PlatformAdminRemoved(address removedAdmin);

    // --- Modifiers ---
    modifier onlyPlatformAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _msgSender()) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only platform admins can perform this action.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userProfiles[_msgSender()].userAddress != address(0), "User must be registered.");
        _;
    }

    modifier serviceOfferExists(uint256 _offerId) {
        require(serviceOffers[_offerId].offerId == _offerId, "Service offer does not exist.");
        _;
    }

    modifier serviceRequestExists(uint256 _requestId) {
        require(serviceRequests[_requestId].requestId == _requestId, "Service request does not exist.");
        _;
    }

    modifier onlyServiceProvider(uint256 _offerId) {
        require(serviceOffers[_offerId].providerAddress == _msgSender(), "Only the service provider of this offer can perform this action.");
        _;
    }

    modifier onlyServiceRequester(uint256 _requestId) {
        require(serviceRequests[_requestId].requesterAddress == _msgSender(), "Only the service requester can perform this action.");
        _;
    }

    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        platformOwner = _msgSender();
        platformAdmins.push(platformOwner);
    }

    // --- 1. User Profile Management ---
    function registerUser(string memory _userName, string memory _profileDescription) external notPaused {
        require(userProfiles[_msgSender()].userAddress == address(0), "User already registered.");
        require(bytes(_userName).length > 0 && bytes(_userName).length <= 32, "Username must be between 1 and 32 characters.");
        userProfiles[_msgSender()] = UserProfile({
            userAddress: _msgSender(),
            userName: _userName,
            profileDescription: _profileDescription,
            registrationTimestamp: block.timestamp
        });
        emit UserRegistered(_msgSender(), _userName);
    }

    function updateUserProfile(string memory _profileDescription) external onlyRegisteredUser notPaused {
        userProfiles[_msgSender()].profileDescription = _profileDescription;
        emit UserProfileUpdated(_msgSender());
    }

    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function setUsername(string memory _newUsername) external onlyRegisteredUser notPaused {
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 32, "Username must be between 1 and 32 characters.");
        userProfiles[_msgSender()].userName = _newUsername;
        emit UsernameUpdated(_msgSender(), _newUsername);
    }

    // --- 2. Skill Management ---
    function addSkillCategory(string memory _categoryName) external onlyPlatformAdmin notPaused {
        require(bytes(_categoryName).length > 0, "Category name cannot be empty.");
        skillCategories[_skillCategoryIdCounter] = SkillCategory({
            categoryId: _skillCategoryIdCounter,
            categoryName: _categoryName
        });
        emit SkillCategoryAdded(_skillCategoryIdCounter, _categoryName);
        _skillCategoryIdCounter++;
    }

    function addSkill(uint256 _categoryId, string memory _skillName) external onlyPlatformAdmin notPaused {
        require(skillCategories[_categoryId].categoryId == _categoryId, "Skill category does not exist.");
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        skills[_skillIdCounter] = Skill({
            skillId: _skillIdCounter,
            categoryId: _categoryId,
            skillName: _skillName
        });
        emit SkillAdded(_skillIdCounter, _categoryId, _skillName);
        _skillIdCounter++;
    }

    function listSkills() external view returns (SkillCategory[] memory, Skill[] memory) {
        SkillCategory[] memory categories = new SkillCategory[](_skillCategoryIdCounter - 1);
        Skill[] memory allSkills = new Skill[](_skillIdCounter - 1);
        uint256 categoryIndex = 0;
        uint256 skillIndex = 0;
        for (uint256 i = 1; i < _skillCategoryIdCounter; i++) {
            categories[categoryIndex] = skillCategories[i];
            categoryIndex++;
        }
        for (uint256 i = 1; i < _skillIdCounter; i++) {
            allSkills[skillIndex] = skills[i];
            skillIndex++;
        }
        return (categories, allSkills);
    }

    function addUserSkill(uint256 _skillId) external onlyRegisteredUser notPaused {
        require(skills[_skillId].skillId == _skillId, "Skill does not exist.");
        require(!userSkills[_msgSender()][_skillId], "User already has this skill.");
        userSkills[_msgSender()][_skillId] = true;
        emit UserSkillAdded(_msgSender(), _skillId);
    }

    function removeUserSkill(uint256 _skillId) external onlyRegisteredUser notPaused {
        require(skills[_skillId].skillId == _skillId, "Skill does not exist.");
        require(userSkills[_msgSender()][_skillId], "User does not have this skill.");
        delete userSkills[_msgSender()][_skillId];
        emit UserSkillRemoved(_msgSender(), _skillId);
    }

    function getUserSkills(address _userAddress) external view returns (Skill[] memory) {
        uint256 skillCount = 0;
        for (uint256 i = 1; i < _skillIdCounter; i++) {
            if (userSkills[_userAddress][i]) {
                skillCount++;
            }
        }
        Skill[] memory userSkillList = new Skill[](skillCount);
        uint256 index = 0;
        for (uint256 i = 1; i < _skillIdCounter; i++) {
            if (userSkills[_userAddress][i]) {
                userSkillList[index] = skills[i];
                index++;
            }
        }
        return userSkillList;
    }

    // --- 3. Service Offering and Requesting ---
    function createServiceOffer(
        uint256 _skillId,
        string memory _serviceDescription,
        uint256 _pricePerUnit,
        string memory _unitOfService
    ) external onlyRegisteredUser notPaused {
        require(skills[_skillId].skillId == _skillId, "Skill does not exist.");
        require(userSkills[_msgSender()][_skillId], "User does not have the required skill.");
        require(bytes(_serviceDescription).length > 0, "Service description cannot be empty.");
        require(_pricePerUnit > 0, "Price per unit must be greater than 0.");
        require(bytes(_unitOfService).length > 0, "Unit of service cannot be empty.");

        serviceOffers[_serviceOfferIdCounter] = ServiceOffer({
            offerId: _serviceOfferIdCounter,
            providerAddress: _msgSender(),
            skillId: _skillId,
            serviceDescription: _serviceDescription,
            pricePerUnit: _pricePerUnit,
            unitOfService: _unitOfService,
            isActive: true,
            creationTimestamp: block.timestamp
        });
        emit ServiceOfferCreated(_serviceOfferIdCounter, _msgSender(), _skillId);
        _serviceOfferIdCounter++;
    }

    function updateServiceOffer(
        uint256 _offerId,
        string memory _serviceDescription,
        uint256 _pricePerUnit,
        string memory _unitOfService
    ) external onlyRegisteredUser serviceOfferExists(_offerId) onlyServiceProvider(_offerId) notPaused {
        require(serviceOffers[_offerId].isActive, "Service offer is not active.");
        require(bytes(_serviceDescription).length > 0, "Service description cannot be empty.");
        require(_pricePerUnit > 0, "Price per unit must be greater than 0.");
        require(bytes(_unitOfService).length > 0, "Unit of service cannot be empty.");

        serviceOffers[_offerId].serviceDescription = _serviceDescription;
        serviceOffers[_offerId].pricePerUnit = _pricePerUnit;
        serviceOffers[_offerId].unitOfService = _unitOfService;
        emit ServiceOfferUpdated(_offerId);
    }

    function cancelServiceOffer(uint256 _offerId) external onlyRegisteredUser serviceOfferExists(_offerId) onlyServiceProvider(_offerId) notPaused {
        require(serviceOffers[_offerId].isActive, "Service offer is already inactive.");
        serviceOffers[_offerId].isActive = false;
        emit ServiceOfferCancelled(_offerId);
    }

    function requestService(uint256 _offerId, uint256 _unitsRequested, string memory _requestDetails) external payable onlyRegisteredUser serviceOfferExists(_offerId) notPaused {
        require(serviceOffers[_offerId].isActive, "Service offer is not active.");
        require(serviceOffers[_offerId].providerAddress != _msgSender(), "Provider cannot request their own service.");
        require(_unitsRequested > 0, "Units requested must be greater than 0.");
        require(msg.value >= serviceOffers[_offerId].pricePerUnit * _unitsRequested * (100 + platformFeePercentage) / 100, "Insufficient funds sent to cover service and platform fees.");

        ServiceOffer storage offer = serviceOffers[_offerId];
        uint256 totalAmount = offer.pricePerUnit * _unitsRequested;
        uint256 platformFee = totalAmount * platformFeePercentage / 100;

        payable(offer.providerAddress).transfer(totalAmount - platformFee);
        // Platform fee is retained in the contract balance until withdrawn by admin

        serviceRequests[_serviceRequestIdCounter] = ServiceRequest({
            requestId: _serviceRequestIdCounter,
            offerId: _offerId,
            requesterAddress: _msgSender(),
            providerAddress: offer.providerAddress,
            unitsRequested: _unitsRequested,
            requestDetails: _requestDetails,
            status: ServiceRequestStatus.Pending,
            requestTimestamp: block.timestamp,
            completionTimestamp: 0,
            completionDetails: "",
            rejectionReason: "",
            disputeOpenTimestamp: 0,
            disputeReason: "",
            disputeResolvedInFavorOfProvider: false
        });
        emit ServiceRequested(_serviceRequestIdCounter, _offerId, _msgSender());
        _serviceRequestIdCounter++;
    }

    function acceptServiceRequest(uint256 _requestId) external onlyRegisteredUser serviceRequestExists(_requestId) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.Pending, "Service request is not in pending status.");
        require(serviceRequests[_requestId].providerAddress == _msgSender(), "Only the service provider can accept this request.");
        serviceRequests[_requestId].status = ServiceRequestStatus.Accepted;
        emit ServiceRequestAccepted(_requestId);
    }

    function submitServiceCompletion(uint256 _requestId, string memory _completionDetails) external onlyRegisteredUser serviceRequestExists(_requestId) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.Accepted, "Service request must be in accepted status.");
        require(serviceRequests[_requestId].providerAddress == _msgSender(), "Only the service provider can submit completion.");
        require(bytes(_completionDetails).length > 0, "Completion details cannot be empty.");
        serviceRequests[_requestId].status = ServiceRequestStatus.Completed;
        serviceRequests[_requestId].completionDetails = _completionDetails;
        serviceRequests[_requestId].completionTimestamp = block.timestamp;
        emit ServiceCompletionSubmitted(_requestId);
    }

    function approveServiceCompletion(uint256 _requestId) external onlyRegisteredUser serviceRequestExists(_requestId) onlyServiceRequester(_requestId) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.Completed, "Service request must be in completed status.");
        serviceRequests[_requestId].status = ServiceRequestStatus.Approved;
        emit ServiceCompletionApproved(_requestId);
    }

    function rejectServiceCompletion(uint256 _requestId, string memory _rejectionReason) external onlyRegisteredUser serviceRequestExists(_requestId) onlyServiceRequester(_requestId) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.Completed, "Service request must be in completed status.");
        require(bytes(_rejectionReason).length > 0, "Rejection reason cannot be empty.");
        serviceRequests[_requestId].status = ServiceRequestStatus.Rejected;
        serviceRequests[_requestId].rejectionReason = _rejectionReason;
        emit ServiceCompletionRejected(_requestId);
    }

    // --- 4. Reputation and Review System ---
    function submitReview(uint256 _requestId, uint8 _rating, string memory _reviewText) external onlyRegisteredUser serviceRequestExists(_requestId) validRating(_rating) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.Approved || serviceRequests[_requestId].status == ServiceRequestStatus.Rejected || serviceRequests[_requestId].status == ServiceRequestStatus.DisputeResolved, "Service request must be in a final status to submit a review.");
        require(reviews[_reviewIdCounter].reviewId == 0, "Review already submitted for this request (one review per request per user)."); // Basic check, can be improved

        address reviewedUser;
        address reviewerUser = _msgSender();
        if (reviewerUser == serviceRequests[_requestId].requesterAddress) {
            reviewedUser = serviceRequests[_requestId].providerAddress;
        } else if (reviewerUser == serviceRequests[_requestId].providerAddress) {
            reviewedUser = serviceRequests[_requestId].requesterAddress;
        } else {
            revert("Only requester or provider can submit a review.");
        }
        require(reviewedUser != address(0), "Invalid reviewed user address.");

        reviews[_reviewIdCounter] = Review({
            reviewId: _reviewIdCounter,
            reviewerAddress: reviewerUser,
            reviewedAddress: reviewedUser,
            requestId: _requestId,
            rating: _rating,
            reviewText: _reviewText,
            reviewTimestamp: block.timestamp
        });
        userReviewIds[reviewedUser].push(_reviewIdCounter);
        emit ReviewSubmitted(_reviewIdCounter, reviewerUser, reviewedUser, _requestId);
        _reviewIdCounter++;
    }

    function getAverageRating(address _userAddress) external view returns (uint256) {
        uint256 totalRating = 0;
        uint256 reviewCount = 0;
        for (uint256 i = 0; i < userReviewIds[_userAddress].length; i++) {
            totalRating += reviews[userReviewIds[_userAddress][i]].rating;
            reviewCount++;
        }
        if (reviewCount == 0) {
            return 0;
        }
        return totalRating / reviewCount;
    }

    function getUserReviews(address _userAddress) external view returns (Review[] memory) {
        uint256 reviewCount = userReviewIds[_userAddress].length;
        Review[] memory userReviews = new Review[](reviewCount);
        for (uint256 i = 0; i < reviewCount; i++) {
            userReviews[i] = reviews[userReviewIds[_userAddress][i]];
        }
        return userReviews;
    }

    // --- 5. Dispute Resolution (Simplified) ---
    function openDispute(uint256 _requestId, string memory _disputeReason) external onlyRegisteredUser serviceRequestExists(_requestId) onlyServiceRequester(_requestId) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.Rejected, "Dispute can only be opened after service rejection.");
        require(bytes(_disputeReason).length > 0, "Dispute reason cannot be empty.");
        require(serviceRequests[_requestId].status != ServiceRequestStatus.DisputeOpened, "Dispute already opened.");

        serviceRequests[_requestId].status = ServiceRequestStatus.DisputeOpened;
        serviceRequests[_requestId].disputeReason = _disputeReason;
        serviceRequests[_requestId].disputeOpenTimestamp = block.timestamp;
        emit DisputeOpened(_requestId);
    }

    function resolveDispute(uint256 _requestId, bool _providerWins) external onlyPlatformAdmin serviceRequestExists(_requestId) notPaused {
        require(serviceRequests[_requestId].status == ServiceRequestStatus.DisputeOpened, "Dispute must be opened to be resolved.");
        serviceRequests[_requestId].status = ServiceRequestStatus.DisputeResolved;
        serviceRequests[_requestId].disputeResolvedInFavorOfProvider = _providerWins;
        emit DisputeResolved(_requestId, _providerWins);
        // In a real advanced system, this would involve more complex dispute resolution mechanisms (e.g., decentralized jurors, voting, etc.)
    }

    // --- 6. Platform Administration & Settings ---
    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin notPaused {
        require(_feePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() external onlyPlatformAdmin notPaused {
        uint256 balance = address(this).balance;
        payable(platformOwner).transfer(balance);
        emit PlatformFeesWithdrawn(_msgSender(), balance);
    }

    function pauseContract() external onlyPlatformAdmin notPaused {
        paused = true;
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() external onlyPlatformAdmin {
        paused = false;
        emit ContractUnpaused(_msgSender());
    }

    function addPlatformAdmin(address _newAdmin) external onlyPlatformAdmin notPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        bool alreadyAdmin = false;
        for (uint256 i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _newAdmin) {
                alreadyAdmin = true;
                break;
            }
        }
        require(!alreadyAdmin, "Address is already a platform admin.");
        platformAdmins.push(_newAdmin);
        emit PlatformAdminAdded(_newAdmin);
    }

    function removePlatformAdmin(address _adminToRemove) external onlyPlatformAdmin notPaused {
        require(_adminToRemove != platformOwner, "Cannot remove the platform owner.");
        for (uint256 i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _adminToRemove) {
                delete platformAdmins[i];
                // Shift array elements to remove the gap (optional, but good practice for smaller arrays)
                for (uint256 j = i; j < platformAdmins.length - 1; j++) {
                    platformAdmins[j] = platformAdmins[j + 1];
                }
                platformAdmins.pop(); // Remove the last element which would be a duplicate or zero address
                emit PlatformAdminRemoved(_adminToRemove);
                return;
            }
        }
        revert("Address is not a platform admin.");
    }

    // --- Fallback and Receive Functions (Optional, for accepting ETH directly if needed) ---
    receive() external payable {}
    fallback() external payable {}
}
```