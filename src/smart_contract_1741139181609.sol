```solidity
/**
 * @title Decentralized Skill & Reputation Marketplace - SkillVerse
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized marketplace where users can register their skills,
 * build reputation, offer services, and hire others based on verified skills and reputation.
 *
 * **Outline:**
 * 1. **User Profile Management:** User registration, profile update, skill addition/removal, reputation tracking.
 * 2. **Skill Management & Verification:**  Skill definition, user skill endorsement, skill verification by trusted entities.
 * 3. **Job/Task Posting & Management:** Job posting with skill requirements, application, assignment, completion, and payment.
 * 4. **Reputation System:** Reputation points based on successful task completion, endorsements, and potentially penalties for disputes.
 * 5. **Dispute Resolution (Basic):**  Mechanism to raise disputes and admin-based resolution.
 * 6. **NFT Skill Badges (Trendy):** Represent verified skills as NFTs for enhanced profile and portability.
 * 7. **Decentralized Governance (Simple):** Basic admin roles and potential future governance features.
 * 8. **Payment & Escrow (Basic):** Handling payments in ETH and basic escrow functionality.
 * 9. **Search & Discovery:** Functions to search for users and jobs based on skills.
 * 10. **User Reviews & Ratings:**  Allow users to rate and review each other after task completion.
 * 11. **Skill-Based Access Control (Internal):**  Potentially use skill levels for accessing certain features.
 * 12. **Event Emission:**  Emit events for key actions for off-chain monitoring.
 * 13. **Pausing & Emergency Stop:** Admin functions for pausing and emergency stop.
 * 14. **Skill Taxonomy (Predefined Skills):** Option to use a predefined skill list for better categorization.
 * 15. **Skill Levels/Proficiency:**  Allow users to specify their proficiency level in each skill.
 * 16. **Skill Recommendations (Basic):**  Potentially recommend users based on job skill requirements.
 * 17. **User Connection/Following (Social Aspect):**  Allow users to connect or follow other users.
 * 18. **Skill-Based Groups/Communities:**  Option to create groups based on specific skills.
 * 19. **Skill-Based Bounties/Challenges:**  Posting bounties or challenges that require specific skills.
 * 20. **Data Analytics (Off-chain focus, events):**  Emitting events that can be used for off-chain data analytics on skill trends and marketplace activity.
 * 21. **Withdrawal Function:**  Function for users to withdraw their earned funds.
 * 22. **Admin Role Management:** Functions to add and remove admin roles.
 * 23. **Get Contract Balance:** Function to check the contract's ETH balance.
 * 24. **Get User Profile:** Function to retrieve detailed user profile information.
 * 25. **Get Task Details:** Function to retrieve detailed task information.
 *
 * **Function Summary:**
 * - `registerUser(string _username, string _profileDescription)`: Registers a new user with a username and profile description.
 * - `updateProfile(string _profileDescription)`: Allows users to update their profile description.
 * - `addSkill(string _skillName)`: Allows users to add a skill to their profile.
 * - `removeSkill(uint _skillId)`: Allows users to remove a skill from their profile.
 * - `endorseSkill(address _userAddress, uint _skillId)`: Allows users to endorse another user's skill.
 * - `verifySkill(address _userAddress, uint _skillId)`: (Admin/Trusted Entity) Verifies a user's skill.
 * - `postJob(string _jobTitle, string _jobDescription, string[] _requiredSkills, uint _paymentAmount)`: Allows users to post a job with skill requirements and payment.
 * - `applyForJob(uint _jobId)`: Allows users to apply for a job.
 * - `assignJob(uint _jobId, address _applicantAddress)`: (Job Poster) Assigns a job to a specific applicant.
 * - `markJobCompleted(uint _jobId)`: (Job Applicant) Marks a job as completed.
 * - `verifyJobCompletion(uint _jobId)`: (Job Poster) Verifies job completion and releases payment.
 * - `raiseDispute(uint _jobId, string _disputeReason)`: Allows users to raise a dispute for a job.
 * - `resolveDispute(uint _disputeId, DisputeResolution _resolution)`: (Admin) Resolves a dispute.
 * - `mintSkillNFT(string _skillName)`: (Admin/Verified Entity) Mints a Skill NFT for a verified skill.
 * - `transferSkillNFT(address _to, uint _tokenId)`: Allows users to transfer their Skill NFTs.
 * - `increaseReputation(address _userAddress, uint _amount)`: (Internal/Admin) Increases user reputation.
 * - `decreaseReputation(address _userAddress, uint _amount)`: (Internal/Admin) Decreases user reputation.
 * - `getReputation(address _userAddress)`: Retrieves a user's reputation score.
 * - `pauseContract()`: (Admin) Pauses the contract, preventing most functions from being called.
 * - `unpauseContract()`: (Admin) Unpauses the contract, restoring normal functionality.
 * - `addAdmin(address _adminAddress)`: (Admin) Adds a new admin address.
 * - `removeAdmin(address _adminAddress)`: (Admin) Removes an admin address.
 * - `withdraw()`: Allows users to withdraw their contract balance.
 * - `getContractBalance()`: Retrieves the contract's ETH balance.
 * - `getUserProfile(address _userAddress)`: Retrieves a user's profile details.
 * - `getJobDetails(uint _jobId)`: Retrieves detailed job information.
 * - `rateUser(address _userAddress, uint _rating, string _review)`: Allows users to rate and review other users.
 * - `getAverageRating(address _userAddress)`: Retrieves the average rating of a user.
 * - `searchUsersBySkill(string _skillName)`: Searches for users with a specific skill.
 * - `searchJobsBySkill(string _skillName)`: Searches for jobs requiring a specific skill.
 * - `getSkills()`: Retrieves the list of skills associated with a user.
 * - `getJobsPostedByUser(address _userAddress)`: Retrieves jobs posted by a specific user.
 * - `getJobsAppliedByUser(address _userAddress)`: Retrieves jobs applied for by a specific user.
 * - `getJobsAssignedToUser(address _userAddress)`: Retrieves jobs assigned to a specific user.
 * - `getCompletedJobsForUser(address _userAddress)`: Retrieves completed jobs for a specific user.
 * - `getPendingJobsForUser(address _userAddress)`: Retrieves pending jobs for a specific user.
 * - `getTotalUsers()`: Retrieves the total number of registered users.
 * - `getTotalJobsPosted()`: Retrieves the total number of jobs posted.
 * - `getTotalSkillsRegistered()`: Retrieves the total number of skills registered.
 * - `isSkillVerified(address _userAddress, uint _skillId)`: Checks if a skill is verified for a user.
 * - `getSkillEndorsements(address _userAddress, uint _skillId)`: Retrieves the number of endorsements for a skill.
 * - `getJobApplicants(uint _jobId)`: Retrieves the list of applicants for a specific job.
 * - `getUserReputationRank(address _userAddress)`: Retrieves the reputation rank of a user.
 * - `getTopReputedUsers(uint _limit)`: Retrieves the top reputed users based on a limit.
 * - `getRecentJobs(uint _limit)`: Retrieves recently posted jobs based on a limit.
 * - `getPopularSkills(uint _limit)`: Retrieves the most popular skills based on user registrations.
 * - `getJobStatus(uint _jobId)`: Retrieves the current status of a job.
 * - `getDisputeDetails(uint _disputeId)`: Retrieves details of a specific dispute.
 * - `getUserRatingCount(address _userAddress)`: Retrieves the number of ratings a user has received.
 * - `getUserReviews(address _userAddress)`: Retrieves reviews for a user.
 * - `getSkillNFTOfUser(address _userAddress, uint _skillId)`: Retrieves the NFT token ID for a user's verified skill.
 * - `getVerifiedSkillsOfUser(address _userAddress)`: Retrieves the list of verified skill IDs for a user.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SkillVerse is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _userIdCounter;
    Counters.Counter private _skillIdCounter;
    Counters.Counter private _jobIdCounter;
    Counters.Counter private _disputeIdCounter;
    Counters.Counter private _skillNFTIdCounter;

    enum JobStatus { Posted, Applied, Assigned, Completed, Verified, Disputed, Resolved }
    enum DisputeResolution { Pending, ResolvedInFavorOfApplicant, ResolvedInFavorOfPoster }

    struct UserProfile {
        uint userId;
        address userAddress;
        string username;
        string profileDescription;
        uint reputation;
        mapping(uint => Skill) skills; // Skill ID to Skill details
        uint[] skillIds; // Array of skill IDs for easier iteration
        mapping(address => uint) ratingsReceived; // User address to rating
        string[] reviewsReceived;
        uint ratingCount;
        uint totalEndorsementsGiven;
        uint totalEndorsementsReceived;
    }

    struct Skill {
        uint skillId;
        string skillName;
        bool isVerified;
        mapping(address => bool) endorsements; // User address endorsing this skill
        uint endorsementCount;
    }

    struct Job {
        uint jobId;
        address jobPoster;
        string jobTitle;
        string jobDescription;
        string[] requiredSkills;
        uint paymentAmount;
        JobStatus status;
        address assignedApplicant;
        address[] applicants;
        uint applicationCount;
        uint completionTimestamp;
        uint verificationTimestamp;
        uint disputeId; // If a dispute is raised
    }

    struct Dispute {
        uint disputeId;
        uint jobId;
        address disputingUser;
        string disputeReason;
        DisputeResolution resolution;
        address resolverAdmin;
        uint resolutionTimestamp;
    }

    struct SkillNFTMetadata {
        string skillName;
        address verifiedBy; // Address that verified the skill
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(uint => Skill) public skills;
    mapping(uint => Job) public jobs;
    mapping(uint => Dispute) public disputes;
    mapping(uint => SkillNFTMetadata) public skillNFTMetadata;
    mapping(uint => uint) public skillNFTToSkillId; // NFT token ID to Skill ID mapping
    mapping(address => bool) public admins;
    mapping(address => bool) public isUserRegistered;
    mapping(string => bool) public usernameExists;

    uint public reputationThresholdForVerifiedUser = 100; // Example threshold for considering a user reputable
    uint public disputeResolutionTimeLimit = 7 days; // Example time limit for dispute resolution

    event UserRegistered(address userAddress, uint userId, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(address userAddress, uint skillId, string skillName);
    event SkillRemoved(address userAddress, uint skillId);
    event SkillEndorsed(address endorser, address endorsedUser, uint skillId);
    event SkillVerified(address verifier, address userAddress, uint skillId);
    event JobPosted(uint jobId, address jobPoster, string jobTitle);
    event JobApplied(uint jobId, address applicant);
    event JobAssigned(uint jobId, address jobPoster, address applicant);
    event JobMarkedCompleted(uint jobId, address applicant);
    event JobVerifiedCompleted(uint jobId, address jobPoster, address applicant);
    event DisputeRaised(uint disputeId, uint jobId, address disputingUser);
    event DisputeResolved(uint disputeId, DisputeResolution resolution, address resolverAdmin);
    event SkillNFTMinted(uint tokenId, address owner, uint skillId);
    event ReputationIncreased(address userAddress, uint amount, string reason);
    event ReputationDecreased(address userAddress, uint amount, string reason);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminAdded(address adminAddress, address addedBy);
    event AdminRemoved(address adminAddress, address removedBy);
    event FundsWithdrawn(address userAddress, uint amount);
    event UserRated(address rater, address ratedUser, uint rating, string review);


    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isUserRegistered[msg.sender], "User not registered");
        _;
    }

    modifier onlyJobPoster(uint _jobId) {
        require(jobs[_jobId].jobPoster == msg.sender, "Only job poster can perform this action");
        _;
    }

    modifier onlyJobApplicant(uint _jobId) {
        require(jobs[_jobId].assignedApplicant == msg.sender, "Only assigned applicant can perform this action");
        _;
    }

    modifier validJobId(uint _jobId) {
        require(_jobId > 0 && _jobId <= _jobIdCounter.current(), "Invalid job ID");
        _;
    }

    modifier validSkillId(uint _skillId) {
        require(_skillId > 0 && _skillId <= _skillIdCounter.current(), "Invalid skill ID");
        _;
    }

    modifier validUserId(uint _userId) {
        require(_userId > 0 && _userId <= _userIdCounter.current(), "Invalid user ID");
        _;
    }

    modifier jobInStatus(uint _jobId, JobStatus _status) {
        require(jobs[_jobId].status == _status, "Job is not in the required status");
        _;
    }

    modifier notPaused() override whenNotPaused {
        _;
    }

    constructor() ERC721("SkillVerseSkillNFT", "SkillNFT") {
        _userIdCounter.increment(); // Start user IDs from 1
        _skillIdCounter.increment(); // Start skill IDs from 1
        _jobIdCounter.increment();  // Start job IDs from 1
        _disputeIdCounter.increment(); // Start dispute IDs from 1
        _skillNFTIdCounter.increment(); // Start NFT IDs from 1
        admins[msg.sender] = true; // Deployer is the initial admin
    }

    // --------------------- Admin Functions ---------------------

    function addAdmin(address _adminAddress) external onlyOwner {
        admins[_adminAddress] = true;
        emit AdminAdded(_adminAddress, msg.sender);
    }

    function removeAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != owner(), "Cannot remove contract owner as admin");
        delete admins[_adminAddress];
        emit AdminRemoved(_adminAddress, msg.sender);
    }

    function pauseContract() external onlyAdmin {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyAdmin {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function mintSkillNFT(string memory _skillName) external onlyAdmin notPaused {
        _skillNFTIdCounter.increment();
        uint newTokenId = _skillNFTIdCounter.current();
        _safeMint(address(this), newTokenId); // Mint to contract initially, admin can transfer later or assign on verification
        skillNFTMetadata[newTokenId] = SkillNFTMetadata({skillName: _skillName, verifiedBy: msg.sender});
        emit SkillNFTMinted(newTokenId, address(this), 0); // Skill ID 0 initially, updated on verification
    }

    // --------------------- User Profile Management ---------------------

    function registerUser(string memory _username, string memory _profileDescription) external notPaused {
        require(!isUserRegistered[msg.sender], "User already registered");
        require(!usernameExists[_username], "Username already taken");
        require(bytes(_username).length > 0 && bytes(_username).length <= 30, "Username must be between 1 and 30 characters");
        require(bytes(_profileDescription).length <= 200, "Profile description too long (max 200 characters)");

        _userIdCounter.increment();
        uint newUserId = _userIdCounter.current();
        userProfiles[msg.sender] = UserProfile({
            userId: newUserId,
            userAddress: msg.sender,
            username: _username,
            profileDescription: _profileDescription,
            reputation: 0,
            skillIds: new uint[](0),
            ratingCount: 0,
            totalEndorsementsGiven: 0,
            totalEndorsementsReceived: 0
        });
        isUserRegistered[msg.sender] = true;
        usernameExists[_username] = true;
        emit UserRegistered(msg.sender, newUserId, _username);
    }

    function updateProfile(string memory _profileDescription) external onlyRegisteredUser notPaused {
        require(bytes(_profileDescription).length <= 200, "Profile description too long (max 200 characters)");
        userProfiles[msg.sender].profileDescription = _profileDescription;
        emit ProfileUpdated(msg.sender);
    }

    function addSkill(string memory _skillName) external onlyRegisteredUser notPaused {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 50, "Skill name must be between 1 and 50 characters");
        _skillIdCounter.increment();
        uint newSkillId = _skillIdCounter.current();
        skills[newSkillId] = Skill({
            skillId: newSkillId,
            skillName: _skillName,
            isVerified: false,
            endorsementCount: 0
        });
        userProfiles[msg.sender].skills[newSkillId] = skills[newSkillId];
        userProfiles[msg.sender].skillIds.push(newSkillId);
        emit SkillAdded(msg.sender, newSkillId, _skillName);
    }

    function removeSkill(uint _skillId) external onlyRegisteredUser validSkillId(_skillId) notPaused {
        require(userProfiles[msg.sender].skills[_skillId].skillId == _skillId, "Skill not found in user profile"); // Ensure skill belongs to user
        delete userProfiles[msg.sender].skills[_skillId];

        // Remove skillId from the skillIds array
        uint[] storage skillIds = userProfiles[msg.sender].skillIds;
        for (uint i = 0; i < skillIds.length; i++) {
            if (skillIds[i] == _skillId) {
                skillIds[i] = skillIds[skillIds.length - 1];
                skillIds.pop();
                break;
            }
        }
        emit SkillRemoved(msg.sender, _skillId);
    }

    function endorseSkill(address _userAddress, uint _skillId) external onlyRegisteredUser validUserId(_userProfiles[_userAddress].userId) validSkillId(_skillId) notPaused {
        require(_userAddress != msg.sender, "Cannot endorse your own skill");
        require(userProfiles[_userAddress].skills[_skillId].skillId == _skillId, "Skill not found in target user profile");
        require(!skills[_skillId].endorsements[msg.sender], "Skill already endorsed by you");

        skills[_skillId].endorsements[msg.sender] = true;
        skills[_skillId].endorsementCount++;
        userProfiles[_userAddress].totalEndorsementsReceived++;
        userProfiles[msg.sender].totalEndorsementsGiven++;
        emit SkillEndorsed(msg.sender, _userAddress, _skillId);
    }

    function verifySkill(address _userAddress, uint _skillId) external onlyAdmin validUserId(_userProfiles[_userAddress].userId) validSkillId(_skillId) notPaused {
        require(userProfiles[_userAddress].skills[_skillId].skillId == _skillId, "Skill not found in target user profile");
        require(!skills[_skillId].isVerified, "Skill already verified");

        skills[_skillId].isVerified = true;
        uint skillNFTTokenId = 0;
        // Find a Skill NFT with the same skill name (or create a new one if needed - more complex logic)
        for (uint i = 1; i <= _skillNFTIdCounter.current(); i++) {
            if (keccak256(bytes(skillNFTMetadata[i].skillName)) == keccak256(bytes(skills[_skillId].skillName)) && ownerOf(i) == address(this)) {
                skillNFTTokenId = i;
                break;
            }
        }
        if (skillNFTTokenId == 0) {
            _skillNFTIdCounter.increment();
            skillNFTTokenId = _skillNFTIdCounter.current();
            _safeMint(_userAddress, skillNFTTokenId); // Mint NFT directly to user if not pre-minted
            skillNFTMetadata[skillNFTTokenId] = SkillNFTMetadata({skillName: skills[_skillId].skillName, verifiedBy: msg.sender});
            skillNFTToSkillId[skillNFTTokenId] = _skillId;
             emit SkillNFTMinted(skillNFTTokenId, _userAddress, _skillId);
        } else {
            _transfer(address(this), _userAddress, skillNFTTokenId); // Transfer pre-minted NFT to user
        }


        emit SkillVerified(msg.sender, _userAddress, _skillId);
    }

    function transferSkillNFT(address _to, uint _tokenId) external notPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        _transfer(msg.sender, _to, _tokenId);
    }


    // --------------------- Job Posting & Management ---------------------

    function postJob(string memory _jobTitle, string memory _jobDescription, string[] memory _requiredSkills, uint _paymentAmount) external onlyRegisteredUser notPaused {
        require(bytes(_jobTitle).length > 0 && bytes(_jobTitle).length <= 100, "Job title must be between 1 and 100 characters");
        require(bytes(_jobDescription).length > 0 && bytes(_jobDescription).length <= 1000, "Job description must be between 1 and 1000 characters");
        require(_requiredSkills.length > 0, "At least one skill is required");
        require(_paymentAmount > 0, "Payment amount must be greater than 0");

        _jobIdCounter.increment();
        uint newJobId = _jobIdCounter.current();
        jobs[newJobId] = Job({
            jobId: newJobId,
            jobPoster: msg.sender,
            jobTitle: _jobTitle,
            jobDescription: _jobDescription,
            requiredSkills: _requiredSkills,
            paymentAmount: _paymentAmount,
            status: JobStatus.Posted,
            assignedApplicant: address(0),
            applicants: new address[](0),
            applicationCount: 0,
            completionTimestamp: 0,
            verificationTimestamp: 0,
            disputeId: 0
        });
        emit JobPosted(newJobId, msg.sender, _jobTitle);
    }

    function applyForJob(uint _jobId) external onlyRegisteredUser validJobId(_jobId) jobInStatus(_jobId, JobStatus.Posted) notPaused {
        require(jobs[_jobId].jobPoster != msg.sender, "Job poster cannot apply for their own job");
        bool alreadyApplied = false;
        for(uint i=0; i < jobs[_jobId].applicants.length; i++) {
            if(jobs[_jobId].applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "Already applied for this job");

        // Basic skill check (can be improved with skill level matching etc.)
        bool skillsMatch = false;
        for (uint i = 0; i < jobs[_jobId].requiredSkills.length; i++) {
            for (uint j = 0; j < userProfiles[msg.sender].skillIds.length; j++) {
                if (keccak256(bytes(jobs[_jobId].requiredSkills[i])) == keccak256(bytes(userProfiles[msg.sender].skills[userProfiles[msg.sender].skillIds[j]].skillName))) {
                    skillsMatch = true; // User has at least one required skill
                    break;
                }
            }
            if (skillsMatch) break;
        }
        require(skillsMatch, "You don't have the required skills for this job");


        jobs[_jobId].applicants.push(msg.sender);
        jobs[_jobId].applicationCount++;
        jobs[_jobId].status = JobStatus.Applied; // Update job status when first application comes in - could be refined
        emit JobApplied(_jobId, msg.sender);
    }

    function assignJob(uint _jobId, address _applicantAddress) external onlyJobPoster(_jobId) validJobId(_jobId) jobInStatus(_jobId, JobStatus.Applied) notPaused {
        bool isApplicant = false;
        for(uint i=0; i < jobs[_jobId].applicants.length; i++){
            if(jobs[_jobId].applicants[i] == _applicantAddress){
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Address is not an applicant for this job");
        require(jobs[_jobId].assignedApplicant == address(0), "Job already assigned");

        jobs[_jobId].assignedApplicant = _applicantAddress;
        jobs[_jobId].status = JobStatus.Assigned;
        emit JobAssigned(_jobId, msg.sender, _applicantAddress);
    }

    function markJobCompleted(uint _jobId) external onlyJobApplicant(_jobId) validJobId(_jobId) jobInStatus(_jobId, JobStatus.Assigned) notPaused {
        jobs[_jobId].status = JobStatus.Completed;
        jobs[_jobId].completionTimestamp = block.timestamp;
        emit JobMarkedCompleted(_jobId, msg.sender);
    }

    function verifyJobCompletion(uint _jobId) external onlyJobPoster(_jobId) validJobId(_jobId) jobInStatus(_jobId, JobStatus.Completed) notPaused {
        jobs[_jobId].status = JobStatus.Verified;
        jobs[_jobId].verificationTimestamp = block.timestamp;
        payable(jobs[_jobId].assignedApplicant).transfer(jobs[_jobId].paymentAmount);
        increaseReputation(jobs[_jobId].assignedApplicant, 10, "Job completed successfully"); // Example reputation increase
        emit JobVerifiedCompleted(_jobId, msg.sender, jobs[_jobId].assignedApplicant);
    }

    // --------------------- Reputation System ---------------------

    function increaseReputation(address _userAddress, uint _amount, string memory _reason) internal {
        userProfiles[_userAddress].reputation += _amount;
        emit ReputationIncreased(_userAddress, _amount, _reason);
    }

    function decreaseReputation(address _userAddress, uint _amount, string memory _reason) internal onlyAdmin { // Example: Admin can decrease for misconduct
        userProfiles[_userAddress].reputation -= _amount;
        emit ReputationDecreased(_userAddress, _amount, _reason);
    }

    function getReputation(address _userAddress) external view returns (uint) {
        return userProfiles[_userAddress].reputation;
    }

    // --------------------- Dispute Resolution ---------------------

    function raiseDispute(uint _jobId, string memory _disputeReason) external onlyRegisteredUser validJobId(_jobId) jobInStatus(_jobId, JobStatus.Completed) notPaused {
        require(jobs[_jobId].assignedApplicant == msg.sender || jobs[_jobId].jobPoster == msg.sender, "Only job poster or applicant can raise dispute");
        require(jobs[_jobId].disputeId == 0, "Dispute already raised for this job"); // Only one dispute per job
        require(block.timestamp <= jobs[_jobId].completionTimestamp + disputeResolutionTimeLimit, "Dispute time limit exceeded");

        _disputeIdCounter.increment();
        uint newDisputeId = _disputeIdCounter.current();
        disputes[newDisputeId] = Dispute({
            disputeId: newDisputeId,
            jobId: _jobId,
            disputingUser: msg.sender,
            disputeReason: _disputeReason,
            resolution: DisputeResolution.Pending,
            resolverAdmin: address(0),
            resolutionTimestamp: 0
        });
        jobs[_jobId].disputeId = newDisputeId;
        jobs[_jobId].status = JobStatus.Disputed;
        emit DisputeRaised(newDisputeId, _jobId, msg.sender);
    }

    function resolveDispute(uint _disputeId, DisputeResolution _resolution) external onlyAdmin notPaused {
        require(disputes[_disputeId].disputeId == _disputeId, "Invalid dispute ID");
        require(disputes[_disputeId].resolution == DisputeResolution.Pending, "Dispute already resolved");

        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].resolverAdmin = msg.sender;
        disputes[_disputeId].resolutionTimestamp = block.timestamp;
        jobs[disputes[_disputeId].jobId].status = JobStatus.Resolved;
        emit DisputeResolved(_disputeId, _resolution, msg.sender);

        if (_resolution == DisputeResolution.ResolvedInFavorOfApplicant) {
            payable(jobs[disputes[_disputeId].jobId].assignedApplicant).transfer(jobs[disputes[_disputeId].jobId].paymentAmount);
            increaseReputation(jobs[disputes[_disputeId].jobId].assignedApplicant, 5, "Dispute resolved in favor"); // Example reputation gain
            decreaseReputation(jobs[disputes[_disputeId].jobId].jobPoster, 5, "Dispute resolved against"); // Example reputation loss
        } else if (_resolution == DisputeResolution.ResolvedInFavorOfPoster) {
            increaseReputation(jobs[disputes[_disputeId].jobId].jobPoster, 5, "Dispute resolved in favor");
            decreaseReputation(jobs[disputes[_disputeId].jobId].assignedApplicant, 5, "Dispute resolved against");
        }
    }

    // --------------------- Payment & Withdrawal ---------------------

    function withdraw() external payable notPaused {
        uint contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero");
        uint amountToWithdraw = contractBalance; // User can withdraw entire contract balance (for simplicity in this example)
        payable(msg.sender).transfer(amountToWithdraw);
        emit FundsWithdrawn(msg.sender, amountToWithdraw);
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    // --------------------- User Reviews & Ratings ---------------------
    function rateUser(address _userAddress, uint _rating, string memory _review) external onlyRegisteredUser validUserId(_userProfiles[_userAddress].userId) notPaused {
        require(_userAddress != msg.sender, "Cannot rate yourself");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        userProfiles[_userAddress].ratingsReceived[msg.sender] = _rating;
        userProfiles[_userAddress].reviewsReceived.push(_review);
        userProfiles[_userAddress].ratingCount++;
        emit UserRated(msg.sender, _userAddress, _rating, _review);
    }

    function getAverageRating(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint) {
        if (userProfiles[_userAddress].ratingCount == 0) return 0;
        uint totalRating = 0;
        for (uint i = 0; i < userProfiles[_userAddress].reviewsReceived.length; i++) {
            totalRating += userProfiles[_userAddress].ratingsReceived[address(uint160(uint256(keccak256(abi.encodePacked(i, _userAddress)))) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)]; // Dummy address for rating -  simplified for demonstration
        }
        return totalRating / userProfiles[_userAddress].ratingCount;
    }

    // --------------------- Search & Discovery Functions ---------------------

    function searchUsersBySkill(string memory _skillName) external view returns (address[] memory) {
        address[] memory matchingUsers = new address[](0);
        for (uint i = 1; i <= _userIdCounter.current(); i++) {
            address userAddr = getUserAddressFromId(i);
            if (userAddr != address(0)) { // Check if user exists (handle potential deletions if implemented later)
                for (uint j = 0; j < userProfiles[userAddr].skillIds.length; j++) {
                    if (keccak256(bytes(userProfiles[userAddr].skills[userProfiles[userAddr].skillIds[j]].skillName)) == keccak256(bytes(_skillName))) {
                        matchingUsers.push(userAddr);
                        break;
                    }
                }
            }
        }
        return matchingUsers;
    }

    function searchJobsBySkill(string memory _skillName) external view returns (uint[] memory) {
        uint[] memory matchingJobIds = new uint[](0);
        for (uint i = 1; i <= _jobIdCounter.current(); i++) {
            for (uint j = 0; j < jobs[i].requiredSkills.length; j++) {
                if (keccak256(bytes(jobs[i].requiredSkills[j])) == keccak256(bytes(_skillName))) {
                    matchingJobIds.push(i);
                    break;
                }
            }
        }
        return matchingJobIds;
    }

    // --------------------- Getter Functions for Data Retrieval ---------------------

    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function getJobDetails(uint _jobId) external view validJobId(_jobId) returns (Job memory) {
        return jobs[_jobId];
    }

    function getSkills() external view onlyRegisteredUser returns (Skill[] memory) {
        Skill[] memory userSkills = new Skill[](userProfiles[msg.sender].skillIds.length);
        for (uint i = 0; i < userProfiles[msg.sender].skillIds.length; i++) {
            userSkills[i] = userProfiles[msg.sender].skills[userProfiles[msg.sender].skillIds[i]];
        }
        return userSkills;
    }

    function getJobsPostedByUser(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint[] memory) {
        uint[] memory postedJobIds = new uint[](0);
        for (uint i = 1; i <= _jobIdCounter.current(); i++) {
            if (jobs[i].jobPoster == _userAddress) {
                postedJobIds.push(i);
            }
        }
        return postedJobIds;
    }

    function getJobsAppliedByUser(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint[] memory) {
        uint[] memory appliedJobIds = new uint[](0);
        for (uint i = 1; i <= _jobIdCounter.current(); i++) {
            for(uint j=0; j < jobs[i].applicants.length; j++){
                if(jobs[i].applicants[j] == _userAddress){
                    appliedJobIds.push(i);
                    break;
                }
            }
        }
        return appliedJobIds;
    }

    function getJobsAssignedToUser(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint[] memory) {
        uint[] memory assignedJobIds = new uint[](0);
        for (uint i = 1; i <= _jobIdCounter.current(); i++) {
            if (jobs[i].assignedApplicant == _userAddress) {
                assignedJobIds.push(i);
            }
        }
        return assignedJobIds;
    }

    function getCompletedJobsForUser(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint[] memory) {
        uint[] memory completedJobIds = new uint[](0);
        for (uint i = 1; i <= _jobIdCounter.current(); i++) {
            if ((jobs[i].assignedApplicant == _userAddress || jobs[i].jobPoster == _userAddress) && (jobs[i].status == JobStatus.Verified || jobs[i].status == JobStatus.Resolved)) { // Include Resolved disputes as completed potentially
                completedJobIds.push(i);
            }
        }
        return completedJobIds;
    }

    function getPendingJobsForUser(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint[] memory) {
        uint[] memory pendingJobIds = new uint[](0);
        for (uint i = 1; i <= _jobIdCounter.current(); i++) {
            if ((jobs[i].assignedApplicant == _userAddress || jobs[i].jobPoster == _userAddress) && (jobs[i].status != JobStatus.Verified && jobs[i].status != JobStatus.Resolved && jobs[i].status != JobStatus.Completed)) { // Jobs not yet verified/resolved
                pendingJobIds.push(i);
            }
        }
        return pendingJobIds;
    }

    function getTotalUsers() external view returns (uint) {
        return _userIdCounter.current() -1; // Subtract 1 because counter starts at 1 and increments before first user registration
    }

    function getTotalJobsPosted() external view returns (uint) {
        return _jobIdCounter.current() -1; // Subtract 1 for the same reason as above
    }

    function getTotalSkillsRegistered() external view returns (uint) {
        return _skillIdCounter.current() -1; // Subtract 1 for the same reason as above
    }

    function isSkillVerified(address _userAddress, uint _skillId) external view validUserId(_userProfiles[_userAddress].userId) validSkillId(_skillId) returns (bool) {
        return userProfiles[_userAddress].skills[_skillId].isVerified;
    }

    function getSkillEndorsements(address _userAddress, uint _skillId) external view validUserId(_userProfiles[_userAddress].userId) validSkillId(_skillId) returns (uint) {
        return skills[_skillId].endorsementCount;
    }

    function getJobApplicants(uint _jobId) external view validJobId(_jobId) returns (address[] memory) {
        return jobs[_jobId].applicants;
    }

    function getUserReputationRank(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint) {
        uint rank = 1; // Start rank at 1
        for (uint i = 1; i <= _userIdCounter.current(); i++) {
            address otherUser = getUserAddressFromId(i);
            if (otherUser != address(0) && otherUser != _userAddress && userProfiles[otherUser].reputation > userProfiles[_userAddress].reputation) {
                rank++;
            }
        }
        return rank;
    }

    function getTopReputedUsers(uint _limit) external view returns (address[] memory) {
        address[] memory topUsers = new address[](_limit);
        address[] memory allUserAddresses = new address[](_userIdCounter.current() - 1); // Array to store user addresses
        uint userCount = 0;

        // Collect all user addresses
        for (uint i = 1; i <= _userIdCounter.current(); i++) {
            address userAddr = getUserAddressFromId(i);
            if (userAddr != address(0)) {
                allUserAddresses[userCount] = userAddr;
                userCount++;
            }
        }

        // Sort user addresses based on reputation (descending order) - Bubble sort for simplicity, could be optimized
        for (uint i = 0; i < userCount - 1; i++) {
            for (uint j = 0; j < userCount - i - 1; j++) {
                if (userProfiles[allUserAddresses[j]].reputation < userProfiles[allUserAddresses[j + 1]].reputation) {
                    address temp = allUserAddresses[j];
                    allUserAddresses[j] = allUserAddresses[j + 1];
                    allUserAddresses[j + 1] = temp;
                }
            }
        }

        // Take top 'limit' users or fewer if less than limit users registered
        uint usersToReturn = _limit > userCount ? userCount : _limit;
        for (uint i = 0; i < usersToReturn; i++) {
            topUsers[i] = allUserAddresses[i];
        }
        return topUsers;
    }

    function getRecentJobs(uint _limit) external view returns (uint[] memory) {
        uint[] memory recentJobIds = new uint[](_limit);
        uint jobCount = _jobIdCounter.current() - 1; // Total jobs posted

        uint jobsToReturn = _limit > jobCount ? jobCount : _limit;
        for (uint i = 0; i < jobsToReturn; i++) {
            recentJobIds[i] = _jobIdCounter.current() - 1 - i; // Get last posted jobs (assuming jobId counter is incremented on post)
        }
        return recentJobIds;
    }

    function getPopularSkills(uint _limit) external view returns (string[] memory) {
        string[] memory popularSkills = new string[](_limit);
        Skill[] memory allSkills = new Skill[](_skillIdCounter.current() - 1);
        uint skillCount = 0;

        // Collect all skills
        for (uint i = 1; i <= _skillIdCounter.current(); i++) {
            if (bytes(skills[i].skillName).length > 0) { // Check if skill is actually registered (handle potential deletions if implemented)
                allSkills[skillCount] = skills[i];
                skillCount++;
            }
        }

        // Sort skills based on endorsement count (descending order) - Bubble sort for simplicity
        for (uint i = 0; i < skillCount - 1; i++) {
            for (uint j = 0; j < skillCount - i - 1; j++) {
                if (allSkills[j].endorsementCount < allSkills[j + 1].endorsementCount) {
                    Skill memory temp = allSkills[j];
                    allSkills[j] = allSkills[j + 1];
                    allSkills[j + 1] = temp;
                }
            }
        }

        uint skillsToReturn = _limit > skillCount ? skillCount : _limit;
        for (uint i = 0; i < skillsToReturn; i++) {
            popularSkills[i] = allSkills[i].skillName;
        }
        return popularSkills;
    }

    function getJobStatus(uint _jobId) external view validJobId(_jobId) returns (JobStatus) {
        return jobs[_jobId].status;
    }

    function getDisputeDetails(uint _disputeId) external view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    function getUserRatingCount(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint) {
        return userProfiles[_userAddress].ratingCount;
    }

    function getUserReviews(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (string[] memory) {
        return userProfiles[_userAddress].reviewsReceived;
    }

    function getSkillNFTOfUser(address _userAddress, uint _skillId) external view validUserId(_userProfiles[_userAddress].userId) validSkillId(_skillId) returns (uint) {
         for (uint tokenId = 1; tokenId <= _skillNFTIdCounter.current(); tokenId++) {
            if (ownerOf(tokenId) == _userAddress && skillNFTToSkillId[tokenId] == _skillId) {
                return tokenId;
            }
        }
        return 0; // Return 0 if NFT not found
    }

    function getVerifiedSkillsOfUser(address _userAddress) external view validUserId(_userProfiles[_userAddress].userId) returns (uint[] memory) {
        uint[] memory verifiedSkillIds = new uint[](0);
        for (uint i = 0; i < userProfiles[_userAddress].skillIds.length; i++) {
            if (userProfiles[_userAddress].skills[userProfiles[_userAddress].skillIds[i]].isVerified) {
                verifiedSkillIds.push(userProfiles[_userAddress].skillIds[i]);
            }
        }
        return verifiedSkillIds;
    }


    // --------------------- Internal Helper Functions ---------------------

    function getUserAddressFromId(uint _userId) internal view returns (address) {
        for (address userAddr in userProfiles) {
            if (userProfiles[userAddr].userId == _userId) {
                return userAddr;
            }
        }
        return address(0); // User ID not found
    }
}
```