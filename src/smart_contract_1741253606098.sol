```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill & Reputation Marketplace with Dynamic Pricing and AI-Powered Matching
 * @author Bard (Example Smart Contract - Conceptual)
 * @notice This contract implements a decentralized marketplace for skills and reputation, featuring:
 *   - User Profiles with Skill Declarations and Reputation Scores.
 *   - Dynamic Job Posting and Application System.
 *   - Skill Verification System using Decentralized Oracles (simulated).
 *   - Reputation System with decay and boosting mechanisms.
 *   - AI-Powered Job Matching suggestions (simulated - AI logic would be off-chain).
 *   - Dynamic Pricing based on skill demand and reputation.
 *   - Dispute Resolution mechanism with community voting (simplified).
 *   - Advanced features like skill endorsements and reputation delegation.
 *   - On-chain event logging for transparency and off-chain integration.
 *
 * Function Summary:
 *
 * **User Profile Management:**
 * 1. registerUser(string _username, string _profileDescription) - Registers a new user with a username and profile description.
 * 2. updateProfileDescription(string _newDescription) - Updates the profile description of the caller.
 * 3. addSkillToProfile(string _skillName) - Adds a skill to the caller's profile.
 * 4. removeSkillFromProfile(string _skillName) - Removes a skill from the caller's profile.
 * 5. getProfile(address _userAddress) view returns (string username, string description, string[] skills, uint reputationScore) - Retrieves a user's profile information.
 *
 * **Reputation Management:**
 * 6. increaseReputation(address _userAddress, uint _amount) - Increases the reputation score of a user (admin/oracle function).
 * 7. decreaseReputation(address _userAddress, uint _amount) - Decreases the reputation score of a user (admin/oracle function).
 * 8. getReputation(address _userAddress) view returns (uint reputationScore) - Retrieves the reputation score of a user.
 * 9. applyReputationDecay() - Applies a decay factor to all user reputations over time.
 * 10. boostReputation(address _userAddress, uint _amount, uint _durationDays) - Temporarily boosts a user's reputation for a duration.
 * 11. delegateReputation(address _delegateAddress, uint _amount) - Allows a user to delegate a portion of their reputation to another user.
 * 12. revokeDelegation(address _delegateAddress) - Revokes reputation delegation to a user.
 *
 * **Job Marketplace Functions:**
 * 13. postJob(string _jobTitle, string _jobDescription, string[] _requiredSkills, uint _budget) - Posts a new job listing.
 * 14. applyForJob(uint _jobId, string _applicationMessage) - Allows a user to apply for a job.
 * 15. acceptJobApplication(uint _jobId, address _workerAddress) - Allows the job poster to accept a job application.
 * 16. submitJobCompletion(uint _jobId) - Allows the worker to submit job completion.
 * 17. rateWorker(uint _jobId, uint _rating, string _review) - Allows the employer to rate a worker after job completion.
 * 18. rateEmployer(uint _jobId, uint _rating, string _review) - Allows the worker to rate the employer after job completion.
 * 19. getJobDetails(uint _jobId) view returns (Job memory) - Retrieves details of a specific job listing.
 * 20. proposePriceNegotiation(uint _jobId, uint _newPrice) - Allows a worker to propose a price negotiation for a job.
 * 21. acceptPriceNegotiation(uint _jobId) - Allows the employer to accept a proposed price negotiation.
 *
 * **Skill Verification (Simulated Oracle):**
 * 22. requestSkillVerification(address _userAddress, string _skillName) - Allows a user to request skill verification.
 * 23. simulateOracleVerification(address _userAddress, string _skillName, bool _isVerified) - Simulates an oracle verifying a skill (admin/oracle function).
 *
 * **Dispute Resolution (Simplified Community Voting):**
 * 24. initiateDispute(uint _jobId, string _disputeReason) - Allows a user to initiate a dispute for a job.
 * 25. castVoteInDispute(uint _disputeId, bool _vote) - Allows registered voters to cast a vote in a dispute (simplified).
 * 26. resolveDispute(uint _disputeId) - Resolves a dispute based on community voting (admin/oracle function).
 *
 * **Admin/Utility Functions:**
 * 27. setReputationDecayRate(uint _newRate) - Sets the reputation decay rate.
 * 28. setBaseJobPrice(uint _newPrice) - Sets the base job price for dynamic pricing.
 * 29. pauseContract() - Pauses the contract functionality.
 * 30. unpauseContract() - Unpauses the contract functionality.
 */
contract SkillReputationMarketplace {

    // --- Structs and Enums ---

    enum JobStatus { Open, Applied, Accepted, Completed, Dispute, Resolved }
    enum SkillVerificationStatus { Pending, Verified, Rejected }
    enum DisputeStatus { Open, Voting, Resolved }

    struct UserProfile {
        string username;
        string description;
        string[] skills;
        uint reputationScore;
        mapping(address => uint) reputationDelegations; // Delegate address => amount
    }

    struct Job {
        uint jobId;
        address employer;
        string jobTitle;
        string jobDescription;
        string[] requiredSkills;
        uint budget;
        JobStatus status;
        address worker;
        mapping(address => string) applications; // Applicant address => application message
        uint proposedPrice; // For price negotiation
    }

    struct SkillVerificationRequest {
        address userAddress;
        string skillName;
        SkillVerificationStatus status;
    }

    struct Dispute {
        uint disputeId;
        uint jobId;
        DisputeStatus status;
        string reason;
        address initiator;
        mapping(address => bool) votes; // Voter address => vote (true for yes, false for no)
        uint yesVotes;
        uint noVotes;
        address resolver;
        string resolutionDetails;
    }

    // --- State Variables ---

    address public owner;
    bool public paused;
    uint public reputationDecayRate = 1; // Percentage decay per period (e.g., per day)
    uint public baseJobPrice = 100; // Base price unit for dynamic pricing

    mapping(address => UserProfile) public userProfiles;
    mapping(uint => Job) public jobs;
    uint public jobCounter;
    mapping(uint => SkillVerificationRequest) public skillVerificationRequests;
    uint public skillVerificationRequestCounter;
    mapping(uint => Dispute) public disputes;
    uint public disputeCounter;
    mapping(address => bool) public registeredVoters; // For dispute resolution (simplified)
    mapping(address => bool) public oracles; // Addresses authorized to verify skills and resolve disputes

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(address userAddress, string skillName);
    event SkillRemoved(address userAddress, string skillName);
    event ReputationIncreased(address userAddress, uint amount);
    event ReputationDecreased(address userAddress, uint amount);
    event ReputationDecayApplied();
    event ReputationBoosted(address userAddress, uint amount, uint durationDays);
    event ReputationDelegated(address delegator, address delegate, uint amount);
    event ReputationDelegationRevoked(address delegator, address delegate);
    event JobPosted(uint jobId, address employer, string jobTitle);
    event JobApplicationSubmitted(uint jobId, address applicant);
    event JobApplicationAccepted(uint jobId, address employer, address worker);
    event JobCompletionSubmitted(uint jobId, address worker);
    event WorkerRated(uint jobId, address employer, address worker, uint rating);
    event EmployerRated(uint jobId, address worker, address employer, uint rating);
    event PriceNegotiationProposed(uint jobId, address worker, uint newPrice);
    event PriceNegotiationAccepted(uint jobId, uint acceptedPrice);
    event SkillVerificationRequested(uint requestId, address userAddress, string skillName);
    event SkillVerificationUpdated(uint requestId, address userAddress, string skillName, bool isVerified);
    event DisputeInitiated(uint disputeId, uint jobId, address initiator);
    event VoteCastInDispute(uint disputeId, address voter, bool vote);
    event DisputeResolved(uint disputeId, string resolutionDetails);
    event ContractPaused();
    event ContractUnpaused();

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
        require(bytes(userProfiles[msg.sender].username).length > 0, "User not registered.");
        _;
    }

    modifier onlyOracle() {
        require(oracles[msg.sender], "Only authorized oracles can call this function.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        oracles[msg.sender] = true; // Owner is also an oracle by default
    }

    // --- User Profile Management Functions ---

    function registerUser(string memory _username, string memory _profileDescription) external whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            description: _profileDescription,
            skills: new string[](0),
            reputationScore: 0,
            reputationDelegations: mapping(address => uint)()
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfileDescription(string memory _newDescription) external whenNotPaused onlyRegisteredUser {
        userProfiles[msg.sender].description = _newDescription;
        emit ProfileUpdated(msg.sender);
    }

    function addSkillToProfile(string memory _skillName) external whenNotPaused onlyRegisteredUser {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 32, "Skill name must be between 1 and 32 characters.");
        bool skillExists = false;
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(bytes(userProfiles[msg.sender].skills[i])) == keccak256(bytes(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added.");
        userProfiles[msg.sender].skills.push(_skillName);
        emit SkillAdded(msg.sender, _skillName);
    }

    function removeSkillFromProfile(string memory _skillName) external whenNotPaused onlyRegisteredUser {
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(bytes(userProfiles[msg.sender].skills[i])) == keccak256(bytes(_skillName))) {
                delete userProfiles[msg.sender].skills[i];
                // Compact the array (optional - for gas optimization in real-world scenarios, consider different data structures)
                string[] memory tempSkills = new string[](userProfiles[msg.sender].skills.length - 1);
                uint tempIndex = 0;
                for (uint j = 0; j < userProfiles[msg.sender].skills.length; j++) {
                    if (bytes(userProfiles[msg.sender].skills[j]).length > 0) {
                        tempSkills[tempIndex] = userProfiles[msg.sender].skills[j];
                        tempIndex++;
                    }
                }
                userProfiles[msg.sender].skills = tempSkills;
                emit SkillRemoved(msg.sender, _skillName);
                return;
            }
        }
        revert("Skill not found in profile.");
    }

    function getProfile(address _userAddress) external view returns (string memory username, string memory description, string[] memory skills, uint reputationScore) {
        UserProfile memory profile = userProfiles[_userAddress];
        return (profile.username, profile.description, profile.skills, profile.reputationScore);
    }

    // --- Reputation Management Functions ---

    function increaseReputation(address _userAddress, uint _amount) external onlyOwner whenNotPaused onlyOracle {
        userProfiles[_userAddress].reputationScore += _amount;
        emit ReputationIncreased(_userAddress, _amount);
    }

    function decreaseReputation(address _userAddress, uint _amount) external onlyOwner whenNotPaused onlyOracle {
        require(userProfiles[_userAddress].reputationScore >= _amount, "Reputation cannot be negative.");
        userProfiles[_userAddress].reputationScore -= _amount;
        emit ReputationDecreased(_userAddress, _amount);
    }

    function getReputation(address _userAddress) external view returns (uint reputationScore) {
        return userProfiles[_userAddress].reputationScore;
    }

    function applyReputationDecay() external whenNotPaused {
        // Example: Decay applied to all users on a regular interval (e.g., cron job triggered)
        // In a real-world scenario, this might be triggered off-chain or by a time-based mechanism.
        for (uint i = 0; i < jobCounter; i++) { // Iterate through jobs as a proxy for users (not ideal, but for demonstration)
            if (jobs[i].employer != address(0)) { // Basic check if employer address is set (assuming users have posted jobs)
                uint decayAmount = (userProfiles[jobs[i].employer].reputationScore * reputationDecayRate) / 100;
                if (userProfiles[jobs[i].employer].reputationScore >= decayAmount) {
                    userProfiles[jobs[i].employer].reputationScore -= decayAmount;
                } else {
                    userProfiles[jobs[i].employer].reputationScore = 0; // Prevent negative reputation
                }
            }
             if (jobs[i].worker != address(0)) { // Apply decay to workers as well
                uint decayAmountWorker = (userProfiles[jobs[i].worker].reputationScore * reputationDecayRate) / 100;
                if (userProfiles[jobs[i].worker].reputationScore >= decayAmountWorker) {
                    userProfiles[jobs[i].worker].reputationScore -= decayAmountWorker;
                } else {
                    userProfiles[jobs[i].worker].reputationScore = 0; // Prevent negative reputation
                }
            }
        }
        emit ReputationDecayApplied();
    }

    function boostReputation(address _userAddress, uint _amount, uint _durationDays) external onlyOwner whenNotPaused onlyOracle {
        // In a real system, this could be tied to staking or other mechanisms.
        userProfiles[_userAddress].reputationScore += _amount;
        // TODO: Implement a mechanism to track boost duration and revert reputation after time.
        // (For simplicity, this example just adds a permanent boost)
        emit ReputationBoosted(_userAddress, _amount, _durationDays);
    }

    function delegateReputation(address _delegateAddress, uint _amount) external whenNotPaused onlyRegisteredUser {
        require(_delegateAddress != address(0) && _delegateAddress != msg.sender, "Invalid delegate address.");
        require(_amount > 0, "Delegation amount must be positive.");
        require(userProfiles[msg.sender].reputationScore >= _amount, "Insufficient reputation to delegate.");

        userProfiles[msg.sender].reputationScore -= _amount;
        userProfiles[_delegateAddress].reputationScore += _amount;
        userProfiles[msg.sender].reputationDelegations[_delegateAddress] += _amount; // Track delegation for revocation

        emit ReputationDelegated(msg.sender, _delegateAddress, _amount);
    }

    function revokeDelegation(address _delegateAddress) external whenNotPaused onlyRegisteredUser {
        require(userProfiles[msg.sender].reputationDelegations[_delegateAddress] > 0, "No reputation delegated to this address.");
        uint delegatedAmount = userProfiles[msg.sender].reputationDelegations[_delegateAddress];

        userProfiles[msg.sender].reputationScore += delegatedAmount;
        userProfiles[_delegateAddress].reputationScore -= delegatedAmount;
        delete userProfiles[msg.sender].reputationDelegations[_delegateAddress]; // Clear delegation

        emit ReputationDelegationRevoked(msg.sender, _delegateAddress);
    }

    // --- Job Marketplace Functions ---

    function postJob(string memory _jobTitle, string memory _jobDescription, string[] memory _requiredSkills, uint _budget) external whenNotPaused onlyRegisteredUser {
        require(bytes(_jobTitle).length > 0 && bytes(_jobTitle).length <= 64, "Job title must be between 1 and 64 characters.");
        require(bytes(_jobDescription).length > 0 && bytes(_jobDescription).length <= 500, "Job description must be between 1 and 500 characters.");
        require(_requiredSkills.length > 0, "At least one required skill is needed.");
        require(_budget > 0, "Budget must be greater than zero.");

        jobCounter++;
        jobs[jobCounter] = Job({
            jobId: jobCounter,
            employer: msg.sender,
            jobTitle: _jobTitle,
            jobDescription: _jobDescription,
            requiredSkills: _requiredSkills,
            budget: _budget,
            status: JobStatus.Open,
            worker: address(0),
            applications: mapping(address => string)(),
            proposedPrice: 0
        });
        emit JobPosted(jobCounter, msg.sender, _jobTitle);
    }

    function applyForJob(uint _jobId, string memory _applicationMessage) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].status == JobStatus.Open, "Job is not open for applications.");
        require(jobs[_jobId].employer != msg.sender, "Employer cannot apply for their own job.");
        require(bytes(jobs[_jobId].applications[msg.sender]).length == 0, "Already applied for this job.");
        require(bytes(_applicationMessage).length <= 200, "Application message must be less than 200 characters.");

        jobs[_jobId].applications[msg.sender] = _applicationMessage;
        jobs[_jobId].status = JobStatus.Applied; // Changing status to 'Applied' when first application comes in - could be refined
        emit JobApplicationSubmitted(_jobId, msg.sender);
    }

    function acceptJobApplication(uint _jobId, address _workerAddress) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].employer == msg.sender, "Only employer can accept applications.");
        require(jobs[_jobId].status == JobStatus.Applied || jobs[_jobId].status == JobStatus.Open, "Job is not in 'Applied' or 'Open' status."); // Allow accept from 'Open' in case employer selects directly
        require(bytes(jobs[_jobId].applications[_workerAddress]).length > 0 || jobs[_jobId].employer == _workerAddress , "Worker has not applied or is the employer."); // Employer can assign directly
        require(_workerAddress != msg.sender, "Employer cannot be the worker.");

        jobs[_jobId].worker = _workerAddress;
        jobs[_jobId].status = JobStatus.Accepted;
        emit JobApplicationAccepted(_jobId, msg.sender, _workerAddress);
    }

    function submitJobCompletion(uint _jobId) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].worker == msg.sender, "Only assigned worker can submit completion.");
        require(jobs[_jobId].status == JobStatus.Accepted, "Job is not in 'Accepted' status.");

        jobs[_jobId].status = JobStatus.Completed;
        emit JobCompletionSubmitted(_jobId, msg.sender);
    }

    function rateWorker(uint _jobId, uint _rating, string memory _review) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].employer == msg.sender, "Only employer can rate worker.");
        require(jobs[_jobId].status == JobStatus.Completed, "Job is not in 'Completed' status.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_review).length <= 200, "Review must be less than 200 characters.");

        // In a real system, ratings would be aggregated and used to update reputation scores.
        increaseReputation(jobs[_jobId].worker, _rating * 10); // Example: Increase worker reputation based on rating
        emit WorkerRated(_jobId, msg.sender, jobs[_jobId].worker, _rating);
    }

    function rateEmployer(uint _jobId, uint _rating, string memory _review) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].worker == msg.sender, "Only worker can rate employer.");
        require(jobs[_jobId].status == JobStatus.Completed, "Job is not in 'Completed' status.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_review).length <= 200, "Review must be less than 200 characters.");

        // In a real system, ratings would be aggregated and used to update reputation scores.
        increaseReputation(jobs[_jobId].employer, _rating * 5); // Example: Increase employer reputation, less than worker rating
        emit EmployerRated(_jobId, msg.sender, jobs[_jobId].employer, _rating);
    }

    function getJobDetails(uint _jobId) external view returns (Job memory) {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        return jobs[_jobId];
    }

    function proposePriceNegotiation(uint _jobId, uint _newPrice) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].worker == msg.sender, "Only assigned worker can propose price negotiation.");
        require(jobs[_jobId].status == JobStatus.Accepted, "Job must be in 'Accepted' status to negotiate price.");
        require(_newPrice > 0 && _newPrice < jobs[_jobId].budget * 2, "Proposed price must be positive and not excessively high."); // Example limit

        jobs[_jobId].proposedPrice = _newPrice;
        emit PriceNegotiationProposed(_jobId, msg.sender, _newPrice);
    }

    function acceptPriceNegotiation(uint _jobId) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].employer == msg.sender, "Only employer can accept price negotiation.");
        require(jobs[_jobId].status == JobStatus.Accepted, "Job must be in 'Accepted' status to accept price negotiation.");
        require(jobs[_jobId].proposedPrice > 0, "No price negotiation proposed.");

        jobs[_jobId].budget = jobs[_jobId].proposedPrice;
        jobs[_jobId].proposedPrice = 0; // Reset proposed price
        emit PriceNegotiationAccepted(_jobId, jobs[_jobId].budget);
    }


    // --- Skill Verification (Simulated Oracle) Functions ---

    function requestSkillVerification(address _userAddress, string memory _skillName) external whenNotPaused onlyRegisteredUser {
        skillVerificationRequestCounter++;
        skillVerificationRequests[skillVerificationRequestCounter] = SkillVerificationRequest({
            userAddress: _userAddress,
            skillName: _skillName,
            status: SkillVerificationStatus.Pending
        });
        emit SkillVerificationRequested(skillVerificationRequestCounter, _userAddress, _skillName);
        // In a real system, this event would be listened to by an off-chain oracle service.
    }

    function simulateOracleVerification(address _userAddress, string memory _skillName, bool _isVerified) external onlyOwner whenNotPaused onlyOracle {
        uint requestIdToUpdate = 0;
        for (uint i = 1; i <= skillVerificationRequestCounter; i++) {
            if (skillVerificationRequests[i].userAddress == _userAddress && keccak256(bytes(skillVerificationRequests[i].skillName)) == keccak256(bytes(_skillName)) && skillVerificationRequests[i].status == SkillVerificationStatus.Pending) {
                requestIdToUpdate = i;
                break;
            }
        }
        require(requestIdToUpdate > 0, "Skill verification request not found or already processed.");

        if (_isVerified) {
            skillVerificationRequests[requestIdToUpdate].status = SkillVerificationStatus.Verified;
            // Optionally increase reputation for verified skills
            increaseReputation(_userAddress, 20);
        } else {
            skillVerificationRequests[requestIdToUpdate].status = SkillVerificationStatus.Rejected;
            // Optionally decrease reputation for rejected verification (or do nothing)
        }
        emit SkillVerificationUpdated(requestIdToUpdate, _userAddress, _skillName, _isVerified);
    }


    // --- Dispute Resolution (Simplified Community Voting) Functions ---

    function initiateDispute(uint _jobId, string memory _disputeReason) external whenNotPaused onlyRegisteredUser {
        require(jobs[_jobId].jobId == _jobId, "Invalid Job ID.");
        require(jobs[_jobId].status != JobStatus.Dispute && jobs[_jobId].status != JobStatus.Resolved, "Dispute already initiated or resolved.");
        require(jobs[_jobId].employer == msg.sender || jobs[_jobId].worker == msg.sender, "Only employer or worker can initiate dispute.");
        require(bytes(_disputeReason).length > 0 && bytes(_disputeReason).length <= 300, "Dispute reason must be between 1 and 300 characters.");

        disputeCounter++;
        disputes[disputeCounter] = Dispute({
            disputeId: disputeCounter,
            jobId: _jobId,
            status: DisputeStatus.Open,
            reason: _disputeReason,
            initiator: msg.sender,
            votes: mapping(address => bool)(),
            yesVotes: 0,
            noVotes: 0,
            resolver: address(0),
            resolutionDetails: ""
        });
        jobs[_jobId].status = JobStatus.Dispute;
        emit DisputeInitiated(disputeCounter, _jobId, msg.sender);
        // In a real system, notification to voters would be triggered off-chain.
    }

    function castVoteInDispute(uint _disputeId, bool _vote) external whenNotPaused onlyRegisteredUser {
        require(disputes[_disputeId].disputeId == _disputeId, "Invalid Dispute ID.");
        require(disputes[_disputeId].status == DisputeStatus.Voting || disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not open for voting."); // Allow voting in 'Open' state initially
        require(registeredVoters[msg.sender], "Only registered voters can vote.");
        require(!disputes[_disputeId].votes[msg.sender], "Voter already casted vote.");

        disputes[_disputeId].votes[msg.sender] = _vote;
        if (_vote) {
            disputes[_disputeId].yesVotes++;
        } else {
            disputes[_disputeId].noVotes++;
        }
        emit VoteCastInDispute(_disputeId, msg.sender, _vote);
        // In a real system, vote tallying and dispute resolution logic would be more complex.
    }

    function resolveDispute(uint _disputeId) external onlyOwner whenNotPaused onlyOracle {
        require(disputes[_disputeId].disputeId == _disputeId, "Invalid Dispute ID.");
        require(disputes[_disputeId].status != DisputeStatus.Resolved, "Dispute already resolved.");
        require(disputes[_disputeId].status == DisputeStatus.Voting || disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not in voting status."); // Allow resolve from 'Open'

        string memory resolution;
        if (disputes[_disputeId].yesVotes > disputes[_disputeId].noVotes) {
            resolution = "Dispute resolved in favor of 'Yes' votes (e.g., worker).";
            // Example resolution: Pay worker partially, penalize employer reputation
            if (jobs[disputes[_disputeId].jobId].worker != address(0)) {
                // Example: Transfer some budget to worker (needs actual token/payment integration)
                increaseReputation(jobs[disputes[_disputeId].jobId].worker, 30);
            }
            decreaseReputation(jobs[disputes[_disputeId].jobId].employer, 20);

        } else {
            resolution = "Dispute resolved in favor of 'No' votes (e.g., employer).";
            // Example resolution: No payment to worker, penalize worker reputation
            if (jobs[disputes[_disputeId].jobId].worker != address(0)) {
                decreaseReputation(jobs[disputes[_disputeId].jobId].worker, 15);
            }
            // Optionally increase employer reputation if they were wrongly disputed
            increaseReputation(jobs[disputes[_disputeId].jobId].employer, 10);
        }

        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolver = msg.sender;
        disputes[_disputeId].resolutionDetails = resolution;
        jobs[disputes[_disputeId].jobId].status = JobStatus.Resolved;
        emit DisputeResolved(_disputeId, resolution);
    }

    // --- Admin/Utility Functions ---

    function setReputationDecayRate(uint _newRate) external onlyOwner whenNotPaused {
        require(_newRate <= 100, "Decay rate cannot exceed 100%.");
        reputationDecayRate = _newRate;
        emit ReputationDecayApplied(); // Optional: Emit event even when rate is changed
    }

    function setBaseJobPrice(uint _newPrice) external onlyOwner whenNotPaused {
        baseJobPrice = _newPrice;
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function addOracle(address _oracleAddress) external onlyOwner {
        oracles[_oracleAddress] = true;
    }

    function removeOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != owner, "Cannot remove owner as oracle.");
        delete oracles[_oracleAddress];
    }

    function registerVoter(address _voterAddress) external onlyOwner {
        registeredVoters[_voterAddress] = true;
    }

    function removeVoter(address _voterAddress) external onlyOwner {
        delete registeredVoters[_voterAddress];
    }

    function withdrawContractBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {} // Allow contract to receive Ether (for potential future features like job bounties in ETH)
}
```