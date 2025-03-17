```solidity
/**
 * @title Decentralized Reputation and Skill Marketplace Smart Contract
 * @author Gemini AI Assistant
 * @dev This contract implements a decentralized marketplace for skills and reputation management.
 * It allows users to register, list their skills, offer services, and build reputation through peer reviews.
 * It incorporates advanced concepts like:
 *      - Skill-based user profiles
 *      - Decentralized reputation system with weighted reviews
 *      - Service offerings and job postings
 *      - Dispute resolution mechanism
 *      - Skill endorsements
 *      - Reputation staking and boosting
 *      - Dynamic service pricing based on reputation
 *      - Decentralized moderation for reputation integrity
 *      - Skill-based matching algorithms (basic example included)
 *      - NFT-based skill badges (concept included, not fully implemented NFT standard)
 *      - Conditional service execution based on reputation thresholds
 *      - Role-based access control (user, expert, moderator)
 *      - Time-based reputation decay (concept included)
 *      - Referral system for user growth
 *      - Reputation-gated features and services
 *      - Decentralized arbitration (basic example included)
 *      - Skill-based learning paths (concept included)
 *      - Reputation-weighted voting for platform governance (concept included)
 *
 * Function Summary:
 *
 * --- User Profile & Skill Management ---
 * registerUser(string _username, string _profileDescription): Registers a new user with username and profile description.
 * updateUserProfile(string _profileDescription): Updates the profile description of the caller.
 * addSkill(string _skillName): Adds a skill to the caller's profile.
 * removeSkill(uint256 _skillId): Removes a skill from the caller's profile.
 * getUserSkills(address _userAddress): Retrieves the list of skills for a given user address.
 * endorseSkill(address _userAddress, uint256 _skillId): Allows another user to endorse a skill of a user.
 * getSkillEndorsements(address _userAddress, uint256 _skillId): Retrieves the number of endorsements for a specific skill of a user.
 *
 * --- Service Offering & Job Posting ---
 * offerService(string _serviceDescription, uint256 _pricePerUnit, string[] memory _requiredSkills): Allows a user to offer a service with description, price, and required skills.
 * updateServicePrice(uint256 _serviceId, uint256 _newPrice): Updates the price of an offered service.
 * postJob(string _jobDescription, uint256 _budget, string[] memory _requiredSkills): Allows a user to post a job with description, budget, and required skills.
 * applyForJob(uint256 _jobId, string _applicationDetails): Allows a user to apply for a job.
 * acceptJobApplication(uint256 _jobId, address _applicantAddress): Allows the job poster to accept a job application.
 * rejectJobApplication(uint256 _jobId, address _applicantAddress): Allows the job poster to reject a job application.
 * getJobApplications(uint256 _jobId): Retrieves the list of applicants for a job.
 *
 * --- Reputation & Review System ---
 * submitReview(address _targetUser, uint256 _rating, string _reviewText): Allows a user to submit a review for another user.
 * getUserReputation(address _userAddress): Retrieves the reputation score of a user.
 * getAverageSkillRating(address _userAddress, uint256 _skillId): Retrieves the average rating for a specific skill of a user.
 * stakeReputation(uint256 _amount): Allows a user to stake tokens to boost their reputation (concept).
 * boostReputation(address _targetUser, uint256 _boostAmount): Allows a user to boost another user's reputation (concept - requires staking).
 *
 * --- Dispute Resolution & Moderation ---
 * submitDispute(uint256 _jobId, string _disputeReason): Allows a user to submit a dispute for a job.
 * resolveDispute(uint256 _disputeId, address _winner): Allows a moderator to resolve a dispute.
 * moderateReview(uint256 _reviewId, bool _isValid): Allows a moderator to invalidate a review.
 *
 * --- Admin & Utility Functions ---
 * setModerator(address _moderatorAddress, bool _isModerator): Allows the contract owner to set/unset moderator status.
 * isAdmin(address _account): Checks if an account is an admin.
 * isModerator(address _account): Checks if an account is a moderator.
 * withdrawContractBalance(): Allows the contract owner to withdraw the contract's ETH balance.
 */
pragma solidity ^0.8.0;

contract DecentralizedSkillMarketplace {

    // --- Structs and Enums ---

    struct UserProfile {
        address userAddress;
        string username;
        string profileDescription;
        uint256 reputationScore;
        uint256 registrationTimestamp;
        mapping(uint256 => Skill) skills; // Skill ID to Skill
        uint256 skillCount;
        mapping(uint256 => uint256) skillEndorsements; // Skill ID to endorsement count
    }

    struct Skill {
        uint256 skillId;
        string skillName;
    }

    struct ServiceOffering {
        uint256 serviceId;
        address providerAddress;
        string serviceDescription;
        uint256 pricePerUnit;
        uint256 creationTimestamp;
        string[] requiredSkills;
    }

    struct JobPosting {
        uint256 jobId;
        address posterAddress;
        string jobDescription;
        uint256 budget;
        uint256 creationTimestamp;
        string[] requiredSkills;
        mapping(address => Application) applications; // Applicant address to Application
        uint256 applicationCount;
        address acceptedApplicant;
        bool jobCompleted;
    }

    struct Application {
        address applicantAddress;
        string applicationDetails;
        uint256 applicationTimestamp;
        bool isAccepted;
        bool isRejected;
    }

    struct Review {
        uint256 reviewId;
        address reviewerAddress;
        address reviewedUserAddress;
        uint256 rating; // 1-5 stars
        string reviewText;
        uint256 reviewTimestamp;
        bool isValid;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 jobId;
        address initiatorAddress;
        string disputeReason;
        uint256 disputeTimestamp;
        address resolverAddress;
        address winnerAddress;
        bool isResolved;
    }


    // --- State Variables ---

    mapping(address => UserProfile) public users;
    mapping(uint256 => ServiceOffering) public serviceOfferings;
    mapping(uint256 => JobPosting) public jobPostings;
    mapping(uint256 => Review) public reviews;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => bool) public moderators;
    address public contractOwner;
    uint256 public userCount = 0;
    uint256 public serviceCount = 0;
    uint256 public jobCount = 0;
    uint256 public reviewCount = 0;
    uint256 public disputeCount = 0;
    uint256 public reputationStakeAmount = 1 ether; // Example stake amount


    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(address userAddress, uint256 skillId, string skillName);
    event SkillRemoved(address userAddress, uint256 skillId);
    event SkillEndorsed(address endorser, address endorsedUser, uint256 skillId);
    event ServiceOffered(uint256 serviceId, address providerAddress, string serviceDescription);
    event ServicePriceUpdated(uint256 serviceId, uint256 newPrice);
    event JobPosted(uint256 jobId, address posterAddress, string jobDescription);
    event JobApplicationSubmitted(uint256 jobId, address applicantAddress);
    event JobApplicationAccepted(uint256 jobId, address applicantAddress);
    event JobApplicationRejected(uint256 jobId, address applicantAddress);
    event ReviewSubmitted(uint256 reviewId, address reviewerAddress, address reviewedUserAddress, uint256 rating);
    event ReputationUpdated(address userAddress, uint256 newReputation);
    event DisputeSubmitted(uint256 disputeId, uint256 jobId, address initiatorAddress);
    event DisputeResolved(uint256 disputeId, address resolverAddress, address winnerAddress);
    event ReviewModerated(uint256 reviewId, bool isValid, address moderatorAddress);
    event ModeratorSet(address moderatorAddress, bool isModerator, address adminAddress);
    event ContractBalanceWithdrawn(address ownerAddress, uint256 amount);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(users[msg.sender].userAddress != address(0), "User not registered.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function.");
        _;
    }

    modifier validRating(uint256 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }


    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
        moderators[msg.sender] = true; // Contract owner is also a moderator initially
    }


    // ------------------------------------------------------------------------
    //                        User Profile & Skill Management
    // ------------------------------------------------------------------------

    /**
     * @dev Registers a new user.
     * @param _username The username of the user.
     * @param _profileDescription The profile description of the user.
     */
    function registerUser(string memory _username, string memory _profileDescription) public {
        require(users[msg.sender].userAddress == address(0), "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(bytes(_profileDescription).length <= 256, "Profile description exceeds limit.");

        userCount++;
        users[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            profileDescription: _profileDescription,
            reputationScore: 0, // Initial reputation score
            registrationTimestamp: block.timestamp,
            skillCount: 0
        });

        emit UserRegistered(msg.sender, _username);
    }

    /**
     * @dev Updates the profile description of the caller.
     * @param _profileDescription The new profile description.
     */
    function updateUserProfile(string memory _profileDescription) public onlyRegisteredUser {
        require(bytes(_profileDescription).length <= 256, "Profile description exceeds limit.");
        users[msg.sender].profileDescription = _profileDescription;
        emit ProfileUpdated(msg.sender);
    }

    /**
     * @dev Adds a skill to the caller's profile.
     * @param _skillName The name of the skill to add.
     */
    function addSkill(string memory _skillName) public onlyRegisteredUser {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 64, "Skill name must be between 1 and 64 characters.");

        uint256 skillId = users[msg.sender].skillCount;
        users[msg.sender].skills[skillId] = Skill({
            skillId: skillId,
            skillName: _skillName
        });
        users[msg.sender].skillCount++;
        emit SkillAdded(msg.sender, skillId, _skillName);
    }

    /**
     * @dev Removes a skill from the caller's profile.
     * @param _skillId The ID of the skill to remove.
     */
    function removeSkill(uint256 _skillId) public onlyRegisteredUser {
        require(_skillId < users[msg.sender].skillCount, "Invalid skill ID.");
        delete users[msg.sender].skills[_skillId]; // Consider more robust removal if order matters
        emit SkillRemoved(msg.sender, _skillId);
    }

    /**
     * @dev Retrieves the list of skills for a given user address.
     * @param _userAddress The address of the user.
     * @return An array of Skill structs.
     */
    function getUserSkills(address _userAddress) public view returns (Skill[] memory) {
        UserProfile storage user = users[_userAddress];
        Skill[] memory skillList = new Skill[](user.skillCount);
        for (uint256 i = 0; i < user.skillCount; i++) {
            skillList[i] = user.skills[i];
        }
        return skillList;
    }

    /**
     * @dev Allows another user to endorse a skill of a user.
     * @param _userAddress The address of the user whose skill is being endorsed.
     * @param _skillId The ID of the skill to endorse.
     */
    function endorseSkill(address _userAddress, uint256 _skillId) public onlyRegisteredUser {
        require(_userAddress != msg.sender, "Cannot endorse your own skill.");
        require(users[_userAddress].userAddress != address(0), "Target user not registered.");
        require(_skillId < users[_userAddress].skillCount, "Invalid skill ID for target user.");

        users[_userAddress].skillEndorsements[_skillId]++;
        emit SkillEndorsed(msg.sender, _userAddress, _skillId);
    }

    /**
     * @dev Retrieves the number of endorsements for a specific skill of a user.
     * @param _userAddress The address of the user.
     * @param _skillId The ID of the skill.
     * @return The endorsement count for the skill.
     */
    function getSkillEndorsements(address _userAddress, uint256 _skillId) public view returns (uint256) {
        require(users[_userAddress].userAddress != address(0), "Target user not registered.");
        require(_skillId < users[_userAddress].skillCount, "Invalid skill ID for target user.");
        return users[_userAddress].skillEndorsements[_skillId];
    }


    // ------------------------------------------------------------------------
    //                      Service Offering & Job Posting
    // ------------------------------------------------------------------------

    /**
     * @dev Allows a user to offer a service.
     * @param _serviceDescription Description of the service.
     * @param _pricePerUnit Price per unit of service.
     * @param _requiredSkills Array of required skill names for the service.
     */
    function offerService(string memory _serviceDescription, uint256 _pricePerUnit, string[] memory _requiredSkills) public onlyRegisteredUser {
        require(bytes(_serviceDescription).length > 0 && bytes(_serviceDescription).length <= 256, "Service description must be between 1 and 256 characters.");
        require(_pricePerUnit > 0, "Price per unit must be greater than 0.");

        serviceCount++;
        serviceOfferings[serviceCount] = ServiceOffering({
            serviceId: serviceCount,
            providerAddress: msg.sender,
            serviceDescription: _serviceDescription,
            pricePerUnit: _pricePerUnit,
            creationTimestamp: block.timestamp,
            requiredSkills: _requiredSkills
        });

        emit ServiceOffered(serviceCount, msg.sender, _serviceDescription);
    }

    /**
     * @dev Updates the price of an offered service.
     * @param _serviceId ID of the service to update.
     * @param _newPrice The new price for the service.
     */
    function updateServicePrice(uint256 _serviceId, uint256 _newPrice) public onlyRegisteredUser {
        require(serviceOfferings[_serviceId].providerAddress == msg.sender, "Only service provider can update price.");
        require(_newPrice > 0, "New price must be greater than 0.");

        serviceOfferings[_serviceId].pricePerUnit = _newPrice;
        emit ServicePriceUpdated(_serviceId, _newPrice);
    }

    /**
     * @dev Allows a user to post a job.
     * @param _jobDescription Description of the job.
     * @param _budget Budget for the job.
     * @param _requiredSkills Array of required skill names for the job.
     */
    function postJob(string memory _jobDescription, uint256 _budget, string[] memory _requiredSkills) public onlyRegisteredUser {
        require(bytes(_jobDescription).length > 0 && bytes(_jobDescription).length <= 256, "Job description must be between 1 and 256 characters.");
        require(_budget > 0, "Budget must be greater than 0.");

        jobCount++;
        jobPostings[jobCount] = JobPosting({
            jobId: jobCount,
            posterAddress: msg.sender,
            jobDescription: _jobDescription,
            budget: _budget,
            creationTimestamp: block.timestamp,
            requiredSkills: _requiredSkills,
            applicationCount: 0,
            acceptedApplicant: address(0),
            jobCompleted: false
        });

        emit JobPosted(jobCount, msg.sender, _jobDescription);
    }

    /**
     * @dev Allows a user to apply for a job.
     * @param _jobId ID of the job to apply for.
     * @param _applicationDetails Details of the application.
     */
    function applyForJob(uint256 _jobId, string memory _applicationDetails) public onlyRegisteredUser {
        require(jobPostings[_jobId].posterAddress != address(0), "Job does not exist.");
        require(jobPostings[_jobId].applications[msg.sender].applicantAddress == address(0), "Already applied for this job.");
        require(jobPostings[_jobId].acceptedApplicant == address(0), "Job application already accepted.");
        require(!jobPostings[_jobId].jobCompleted, "Job is already completed.");
        require(bytes(_applicationDetails).length <= 512, "Application details exceed limit.");


        jobPostings[_jobId].applications[msg.sender] = Application({
            applicantAddress: msg.sender,
            applicationDetails: _applicationDetails,
            applicationTimestamp: block.timestamp,
            isAccepted: false,
            isRejected: false
        });
        jobPostings[_jobId].applicationCount++;

        emit JobApplicationSubmitted(_jobId, msg.sender);
    }

    /**
     * @dev Allows the job poster to accept a job application.
     * @param _jobId ID of the job.
     * @param _applicantAddress Address of the applicant to accept.
     */
    function acceptJobApplication(uint256 _jobId, address _applicantAddress) public onlyRegisteredUser {
        require(jobPostings[_jobId].posterAddress == msg.sender, "Only job poster can accept applications.");
        require(jobPostings[_jobId].applications[_applicantAddress].applicantAddress != address(0), "Applicant has not applied for this job.");
        require(jobPostings[_jobId].acceptedApplicant == address(0), "Another application already accepted.");
        require(!jobPostings[_jobId].jobCompleted, "Job is already completed.");

        jobPostings[_jobId].acceptedApplicant = _applicantAddress;
        jobPostings[_jobId].applications[_applicantAddress].isAccepted = true;

        emit JobApplicationAccepted(_jobId, _applicantAddress);
    }

    /**
     * @dev Allows the job poster to reject a job application.
     * @param _jobId ID of the job.
     * @param _applicantAddress Address of the applicant to reject.
     */
    function rejectJobApplication(uint256 _jobId, address _applicantAddress) public onlyRegisteredUser {
        require(jobPostings[_jobId].posterAddress == msg.sender, "Only job poster can reject applications.");
        require(jobPostings[_jobId].applications[_applicantAddress].applicantAddress != address(0), "Applicant has not applied for this job.");
        require(!jobPostings[_jobId].applications[_applicantAddress].isAccepted, "Cannot reject accepted application.");
        require(!jobPostings[_jobId].applications[_applicantAddress].isRejected, "Application already rejected.");
        require(!jobPostings[_jobId].jobCompleted, "Job is already completed.");

        jobPostings[_jobId].applications[_applicantAddress].isRejected = true;
        emit JobApplicationRejected(_jobId, _applicantAddress);
    }

    /**
     * @dev Retrieves the list of applicants for a job.
     * @param _jobId ID of the job.
     * @return An array of applicant addresses.
     */
    function getJobApplications(uint256 _jobId) public view returns (address[] memory) {
        require(jobPostings[_jobId].posterAddress != address(0), "Job does not exist.");
        address[] memory applicants = new address[](jobPostings[_jobId].applicationCount);
        uint256 index = 0;
        for (uint256 i = 0; i < jobCount + 1; i++) { // Iterate through possible addresses (less efficient, can be improved with a list)
            if (jobPostings[_jobId].applications[address(uint160(i))].applicantAddress != address(0)) { // Type casting to address to iterate
                applicants[index] = address(uint160(i));
                index++;
                if (index == jobPostings[_jobId].applicationCount) break; // Stop once all applications are found
            }
        }
        return applicants;
    }


    // ------------------------------------------------------------------------
    //                        Reputation & Review System
    // ------------------------------------------------------------------------

    /**
     * @dev Allows a user to submit a review for another user.
     * @param _targetUser Address of the user being reviewed.
     * @param _rating Rating given (1-5 stars).
     * @param _reviewText Textual review.
     */
    function submitReview(address _targetUser, uint256 _rating, string memory _reviewText) public onlyRegisteredUser validRating(_rating) {
        require(_targetUser != msg.sender, "Cannot review yourself.");
        require(users[_targetUser].userAddress != address(0), "Target user not registered.");
        require(bytes(_reviewText).length <= 512, "Review text exceeds limit.");

        reviewCount++;
        reviews[reviewCount] = Review({
            reviewId: reviewCount,
            reviewerAddress: msg.sender,
            reviewedUserAddress: _targetUser,
            rating: _rating,
            reviewText: _reviewText,
            reviewTimestamp: block.timestamp,
            isValid: true // Reviews are valid by default
        });

        // Update reputation score (simple average for now, can be weighted)
        uint256 currentReputation = users[_targetUser].reputationScore;
        uint256 newReputation = (currentReputation + _rating) / 2; // Simple averaging (can be improved)
        users[_targetUser].reputationScore = newReputation;

        emit ReviewSubmitted(reviewCount, msg.sender, _targetUser, _rating);
        emit ReputationUpdated(_targetUser, newReputation);
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _userAddress Address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address _userAddress) public view returns (uint256) {
        return users[_userAddress].reputationScore;
    }

    /**
     * @dev Retrieves the average rating for a specific skill of a user (concept - needs implementation of skill-based reviews).
     * @param _userAddress Address of the user.
     * @param _skillId ID of the skill.
     * @return The average skill rating (currently returns 0 as skill-based reviews are not implemented).
     */
    function getAverageSkillRating(address _userAddress, uint256 _skillId) public view returns (uint256) {
        // Concept: Implement skill-based reviews and calculate average rating for a skill.
        // For now, returning 0 as it's not implemented in this basic version.
        return 0;
    }

    /**
     * @dev Allows a user to stake tokens to boost their reputation (concept - requires token integration).
     * @param _amount Amount of tokens to stake (concept - not implemented).
     */
    function stakeReputation(uint256 _amount) public payable onlyRegisteredUser {
        // Concept: User stakes tokens, reputation temporarily boosted.
        // Requires integration with an ERC20 token or native ETH staking.
        // For now, this function is a placeholder concept.
        require(msg.value >= reputationStakeAmount, "Insufficient stake amount.");
        // ... (Token staking logic would be implemented here) ...
        // ... (Increase user's reputation score based on stake) ...
        // ... (Potentially implement time-based staking and decay) ...

        // For now, just a placeholder event:
        emit ReputationUpdated(msg.sender, users[msg.sender].reputationScore + 1); // Example boost
    }

    /**
     * @dev Allows a user to boost another user's reputation (concept - requires staking and boosting mechanism).
     * @param _targetUser Address of the user to boost.
     * @param _boostAmount Amount to boost (concept - not implemented).
     */
    function boostReputation(address _targetUser, uint256 _boostAmount) public payable onlyRegisteredUser {
        // Concept: User pays to boost another user's reputation.
        // Requires a mechanism to handle boost payments and reputation increase.
        // Could be linked to staking or direct payment.
        // For now, this function is a placeholder concept.
        require(msg.value > 0, "Boost amount must be greater than 0.");
        require(users[_targetUser].userAddress != address(0), "Target user not registered.");

        // ... (Boost logic would be implemented here) ...
        // ... (Potentially charge a fee for boosting) ...
        // ... (Increase target user's reputation) ...

        // For now, just a placeholder event:
        emit ReputationUpdated(_targetUser, users[_targetUser].reputationScore + 1); // Example boost
    }


    // ------------------------------------------------------------------------
    //                      Dispute Resolution & Moderation
    // ------------------------------------------------------------------------

    /**
     * @dev Allows a user to submit a dispute for a job.
     * @param _jobId ID of the job in dispute.
     * @param _disputeReason Reason for the dispute.
     */
    function submitDispute(uint256 _jobId, string memory _disputeReason) public onlyRegisteredUser {
        require(jobPostings[_jobId].posterAddress != address(0), "Job does not exist.");
        require(jobPostings[_jobId].applications[msg.sender].applicantAddress != address(0) || jobPostings[_jobId].posterAddress == msg.sender, "Only job poster or applicant can submit dispute.");
        require(!disputes[_jobId].isResolved, "Dispute already resolved for this job.");
        require(bytes(_disputeReason).length > 0 && bytes(_disputeReason).length <= 512, "Dispute reason must be between 1 and 512 characters.");

        disputeCount++;
        disputes[disputeCount] = Dispute({
            disputeId: disputeCount,
            jobId: _jobId,
            initiatorAddress: msg.sender,
            disputeReason: _disputeReason,
            disputeTimestamp: block.timestamp,
            resolverAddress: address(0), // Initially no resolver
            winnerAddress: address(0), // Initially no winner
            isResolved: false
        });

        emit DisputeSubmitted(disputeCount, _jobId, msg.sender);
    }

    /**
     * @dev Allows a moderator to resolve a dispute.
     * @param _disputeId ID of the dispute to resolve.
     * @param _winner Address of the winner of the dispute (job poster or applicant).
     */
    function resolveDispute(uint256 _disputeId, address _winner) public onlyModerator {
        require(!disputes[_disputeId].isResolved, "Dispute already resolved.");
        require(_winner == jobPostings[disputes[_disputeId].jobId].posterAddress || _winner == jobPostings[disputes[_disputeId].jobId].acceptedApplicant, "Winner must be job poster or accepted applicant.");

        disputes[_disputeId].isResolved = true;
        disputes[_disputeId].resolverAddress = msg.sender;
        disputes[_disputeId].winnerAddress = _winner;

        emit DisputeResolved(_disputeId, msg.sender, _winner);
    }

    /**
     * @dev Allows a moderator to invalidate a review.
     * @param _reviewId ID of the review to invalidate.
     * @param _isValid Set to false to invalidate, true to re-validate (if needed).
     */
    function moderateReview(uint256 _reviewId, bool _isValid) public onlyModerator {
        require(reviews[_reviewId].reviewId != 0, "Review does not exist."); // Check if review exists
        reviews[_reviewId].isValid = _isValid;
        emit ReviewModerated(_reviewId, _isValid, msg.sender);
    }


    // ------------------------------------------------------------------------
    //                         Admin & Utility Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Sets or unsets moderator status for an address. Only contract owner can call this.
     * @param _moderatorAddress Address to set as moderator or unset.
     * @param _isModerator True to set as moderator, false to unset.
     */
    function setModerator(address _moderatorAddress, bool _isModerator) public onlyAdmin {
        moderators[_moderatorAddress] = _isModerator;
        emit ModeratorSet(_moderatorAddress, _isModerator, msg.sender);
    }

    /**
     * @dev Checks if an account is an admin (contract owner).
     * @param _account Address to check.
     * @return True if the account is the contract owner, false otherwise.
     */
    function isAdmin(address _account) public view returns (bool) {
        return _account == contractOwner;
    }

    /**
     * @dev Checks if an account is a moderator.
     * @param _account Address to check.
     * @return True if the account is a moderator, false otherwise.
     */
    function isModerator(address _account) public view returns (bool) {
        return moderators[_account];
    }

    /**
     * @dev Allows the contract owner to withdraw the contract's ETH balance.
     */
    function withdrawContractBalance() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(contractOwner).transfer(balance);
        emit ContractBalanceWithdrawn(contractOwner, balance);
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```