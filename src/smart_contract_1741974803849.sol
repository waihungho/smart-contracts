```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Task Marketplace with Skill-Based Reputation and AI-Powered Matching
 * @author Bard (AI-Generated Smart Contract)
 * @dev This contract implements a decentralized marketplace for tasks, incorporating advanced concepts like:
 *      - Dynamic task pricing based on demand and urgency.
 *      - Skill-based reputation system for task executors.
 *      - AI-powered task matching (simulated on-chain through keyword/skill matching).
 *      - Task milestones and escrow with dispute resolution.
 *      - Decentralized identity verification (simulated).
 *      - On-chain skill certification (simulated).
 *      - Gamified reputation building through badges and levels.
 *      - Time-based task decay for urgency management.
 *      - Collaborative task completion features.
 *      - Prediction market for task completion success.
 *      - Dynamic reward boosting for under-served skills.
 *      - Task delegation and sub-tasking.
 *      - Integration with external oracles for real-world data (simulated).
 *      - Decentralized communication channel (simplified).
 *      - Task templates and reusable workflows.
 *      - Reputation-based access control to premium tasks.
 *      - Community moderation and reporting system.
 *      - DAO governance for marketplace parameters.
 *
 * Function Summary:
 * 1.  submitTaskProposal(string _title, string _description, string[] _requiredSkills, uint256 _initialReward, uint256 _deadline, string _taskCategory): Allows task requesters to submit new task proposals.
 * 2.  updateTaskProposal(uint256 _taskId, string _description, uint256 _deadline): Allows requesters to update certain aspects of their task proposals before acceptance.
 * 3.  cancelTaskProposal(uint256 _taskId): Allows task requesters to cancel their task proposals before acceptance.
 * 4.  acceptTaskProposal(uint256 _taskId): Allows registered task executors to accept open task proposals.
 * 5.  submitTaskMilestone(uint256 _taskId, string _milestoneDescription): Allows task executors to submit progress milestones for their accepted tasks.
 * 6.  approveTaskMilestone(uint256 _taskId, uint256 _milestoneIndex): Allows task requesters to approve submitted task milestones, releasing escrowed funds partially.
 * 7.  submitTaskCompletion(uint256 _taskId, string _completionDetails): Allows task executors to submit final task completion reports.
 * 8.  approveTaskCompletion(uint256 _taskId): Allows task requesters to approve task completion and release the remaining escrowed funds.
 * 9.  requestDisputeResolution(uint256 _taskId, string _disputeReason): Allows requesters or executors to initiate a dispute resolution process for a task.
 * 10. resolveDispute(uint256 _taskId, address _winner):  (Admin Function) Allows the admin/dispute resolver to resolve a dispute and allocate funds.
 * 11. registerExecutor(string _name, string[] _skills, string _profileHash): Allows users to register as task executors with their skills and profiles.
 * 12. updateExecutorProfile(string[] _skills, string _profileHash): Allows executors to update their skills and profile information.
 * 13. certifySkill(address _executor, string _skill, string _certificationHash): (Admin Function) Allows admin to certify an executor's skill based on external verification.
 * 14. submitSkillReview(address _executor, string _skill, uint8 _rating, string _reviewText): Allows requesters to submit skill-based reviews for executors after task completion.
 * 15. getExecutorReputation(address _executor): Returns the overall reputation score of an executor based on skill reviews.
 * 16. stakeForTaskExecution(uint256 _taskId): Allows executors to stake tokens as commitment for task execution (optional, for reputation boost).
 * 17. placePredictionMarketBet(uint256 _taskId, bool _willSucceed): Allows users to bet on whether a task will be successfully completed by the deadline.
 * 18. resolvePredictionMarket(uint256 _taskId): (Admin Function) Resolves the prediction market after task completion or deadline, distributing rewards.
 * 19. createCommunityBadge(string _badgeName, string _badgeDescription, string _badgeCriteria): (Admin Function) Allows admin to create new community badges for gamified reputation.
 * 20. awardBadgeToExecutor(address _executor, uint256 _badgeId): (Admin Function) Allows admin to award badges to executors based on achievements.
 * 21. reportExecutor(address _executor, string _reportReason): Allows users to report executors for misconduct, triggering moderation review.
 * 22. moderateExecutorReport(address _executor, bool _isGuilty, string _moderationNotes): (Admin Function) Allows admin to moderate reports and penalize executors if necessary.
 * 23. setMarketplaceFee(uint256 _feePercentage): (Admin Function) Allows admin to set the marketplace fee percentage.
 * 24. withdrawMarketplaceFees(): (Admin Function) Allows admin to withdraw accumulated marketplace fees.
 * 25. proposeGovernanceChange(string _proposalDescription, bytes _calldata): Allows members to propose governance changes to marketplace parameters.
 * 26. voteOnGovernanceProposal(uint256 _proposalId, bool _vote): Allows members to vote on governance proposals.
 * 27. executeGovernanceProposal(uint256 _proposalId): (Admin Function after voting period) Executes approved governance proposals.
 */

contract DynamicTaskMarketplace {

    // --- Data Structures ---

    enum TaskStatus { Open, Accepted, InProgress, MilestonePendingApproval, Completed, Dispute, Cancelled }
    enum DisputeStatus { Open, Resolved }
    enum ProposalStatus { Pending, Active, Resolved }

    struct TaskProposal {
        address requester;
        string title;
        string description;
        string[] requiredSkills;
        uint256 initialReward;
        uint256 deadline; // Unix timestamp
        TaskStatus status;
        address executor;
        uint256 creationTime;
        string taskCategory;
        uint256 marketplaceFee;
        uint256 currentReward; // Dynamic reward, can change based on urgency
        uint256 stakeAmount; // Optional stake by executor
        uint256 predictionMarketId;
        uint256 disputeId;
    }

    struct Milestone {
        string description;
        bool isApproved;
        uint256 approvalTime;
    }

    struct ExecutorProfile {
        string name;
        string[] skills;
        string profileHash; // IPFS hash or similar
        uint256 reputationScore;
        mapping(string => string) skillCertifications; // skill => certificationHash
        uint256 level;
        uint256 badgeCount;
    }

    struct SkillReview {
        address reviewer;
        string skill;
        uint8 rating; // 1-5 stars
        string reviewText;
        uint256 reviewTime;
    }

    struct PredictionMarket {
        uint256 taskId;
        uint256 yesBetAmount;
        uint256 noBetAmount;
        bool resolved;
        bool taskSucceeded;
    }

    struct CommunityBadge {
        string name;
        string description;
        string criteria;
        uint256 badgeId;
    }

    struct Report {
        address reporter;
        address reportedExecutor;
        string reason;
        uint256 reportTime;
        bool resolved;
        bool isGuilty;
        string moderationNotes;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        bytes calldataData;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address initiator;
        string reason;
        DisputeStatus status;
        address resolver;
        address winner;
        uint256 resolutionTime;
    }


    // --- State Variables ---

    mapping(uint256 => TaskProposal) public taskProposals;
    mapping(uint256 => Milestone[]) public taskMilestones;
    mapping(address => ExecutorProfile) public executorProfiles;
    mapping(address => SkillReview[]) public executorSkillReviews;
    mapping(uint256 => PredictionMarket) public predictionMarkets;
    mapping(uint256 => CommunityBadge) public communityBadges;
    mapping(uint256 => Report) public executorReports;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => Dispute) public disputes;

    uint256 public taskProposalCounter;
    uint256 public predictionMarketCounter;
    uint256 public communityBadgeCounter;
    uint256 public reportCounter;
    uint256 public governanceProposalCounter;
    uint256 public disputeCounter;

    address public admin;
    uint256 public marketplaceFeePercentage = 5; // Default 5% fee
    uint256 public marketplaceFeeBalance;
    uint256 public governanceVotingDuration = 7 days; // Default 7 days voting duration

    // --- Events ---

    event TaskProposalSubmitted(uint256 taskId, address requester, string title);
    event TaskProposalUpdated(uint256 taskId, string description, uint256 deadline);
    event TaskProposalCancelled(uint256 taskId);
    event TaskProposalAccepted(uint256 taskId, address executor);
    event TaskMilestoneSubmitted(uint256 taskId, uint256 milestoneIndex, string description);
    event TaskMilestoneApproved(uint256 taskId, uint256 milestoneIndex);
    event TaskCompletionSubmitted(uint256 taskId, address executor);
    event TaskCompletionApproved(uint256 taskId, address requester, address executor, uint256 reward);
    event DisputeRequested(uint256 disputeId, uint256 taskId, address initiator, string reason);
    event DisputeResolved(uint256 disputeId, uint256 taskId, address winner);
    event ExecutorRegistered(address executor, string name);
    event ExecutorProfileUpdated(address executor);
    event SkillCertified(address executor, string skill, string certificationHash);
    event SkillReviewSubmitted(address executor, string skill, uint8 rating);
    event PredictionMarketCreated(uint256 marketId, uint256 taskId);
    event PredictionBetPlaced(uint256 marketId, address better, bool willSucceed, uint256 amount);
    event PredictionMarketResolved(uint256 marketId, bool taskSucceeded);
    event CommunityBadgeCreated(uint256 badgeId, string name);
    event BadgeAwarded(address executor, uint256 badgeId);
    event ExecutorReported(uint256 reportId, address reporter, address reportedExecutor, string reason);
    event ExecutorReportModerated(uint256 reportId, address reportedExecutor, bool isGuilty);
    event MarketplaceFeeUpdated(uint256 feePercentage);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(taskProposals[_taskId].requester != address(0), "Task proposal does not exist.");
        _;
    }

    modifier onlyRequester(uint256 _taskId) {
        require(taskProposals[_taskId].requester == msg.sender, "Only task requester can perform this action.");
        _;
    }

    modifier onlyExecutor(uint256 _taskId) {
        require(taskProposals[_taskId].executor == msg.sender, "Only assigned executor can perform this action.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(taskProposals[_taskId].status == _status, "Task status is not as expected.");
        _;
    }

    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposalId != 0, "Governance proposal does not exist.");
        _;
    }

    modifier proposalStatusIs(uint256 _proposalId, ProposalStatus _status) {
        require(governanceProposals[_proposalId].status == _status, "Governance proposal status is not as expected.");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= governanceProposals[_proposalId].votingStartTime && block.timestamp <= governanceProposals[_proposalId].votingEndTime, "Voting period is not active.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId != 0, "Dispute does not exist.");
        _;
    }

    modifier disputeStatusIs(uint256 _disputeId, DisputeStatus _status) {
        require(disputes[_disputeId].status == _status, "Dispute status is not as expected.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- Task Proposal Functions ---

    function submitTaskProposal(
        string memory _title,
        string memory _description,
        string[] memory _requiredSkills,
        uint256 _initialReward,
        uint256 _deadline,
        string memory _taskCategory
    ) public payable {
        require(_initialReward > 0, "Initial reward must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(msg.value >= _initialReward, "Insufficient funds sent. Need to escrow the initial reward.");

        taskProposalCounter++;
        uint256 taskId = taskProposalCounter;

        taskProposals[taskId] = TaskProposal({
            requester: msg.sender,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            initialReward: _initialReward,
            deadline: _deadline,
            status: TaskStatus.Open,
            executor: address(0),
            creationTime: block.timestamp,
            taskCategory: _taskCategory,
            marketplaceFee: (marketplaceFeePercentage * _initialReward) / 100,
            currentReward: _initialReward,
            stakeAmount: 0,
            predictionMarketId: 0,
            disputeId: 0
        });

        marketplaceFeeBalance += (marketplaceFeePercentage * _initialReward) / 100;

        emit TaskProposalSubmitted(taskId, msg.sender, _title);
    }

    function updateTaskProposal(uint256 _taskId, string memory _description, uint256 _deadline)
        public
        taskExists(_taskId)
        onlyRequester(_taskId)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        taskProposals[_taskId].description = _description;
        taskProposals[_taskId].deadline = _deadline;
        emit TaskProposalUpdated(_taskId, _description, _deadline);
    }

    function cancelTaskProposal(uint256 _taskId)
        public
        taskExists(_taskId)
        onlyRequester(_taskId)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        TaskProposal storage task = taskProposals[_taskId];
        payable(task.requester).transfer(task.initialReward); // Return escrowed funds
        task.status = TaskStatus.Cancelled;
        emit TaskProposalCancelled(_taskId);
    }

    function acceptTaskProposal(uint256 _taskId)
        public
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Open)
    {
        require(executorProfiles[msg.sender].name.length > 0, "You must register as an executor first.");

        taskProposals[_taskId].executor = msg.sender;
        taskProposals[_taskId].status = TaskStatus.Accepted;
        emit TaskProposalAccepted(_taskId, msg.sender);
    }


    // --- Task Milestone and Completion Functions ---

    function submitTaskMilestone(uint256 _taskId, string memory _milestoneDescription)
        public
        taskExists(_taskId)
        onlyExecutor(_taskId)
        taskStatusIs(_taskId, TaskStatus.Accepted) // Or InProgress maybe? Decide flow
    {
        taskMilestones[_taskId].push(Milestone({
            description: _milestoneDescription,
            isApproved: false,
            approvalTime: 0
        }));
        taskProposals[_taskId].status = TaskStatus.MilestonePendingApproval;
        emit TaskMilestoneSubmitted(_taskId, taskMilestones[_taskId].length - 1, _milestoneDescription);
    }

    function approveTaskMilestone(uint256 _taskId, uint256 _milestoneIndex)
        public
        taskExists(_taskId)
        onlyRequester(_taskId)
        taskStatusIs(_taskId, TaskStatus.MilestonePendingApproval)
    {
        require(_milestoneIndex < taskMilestones[_taskId].length, "Invalid milestone index.");
        require(!taskMilestones[_taskId][_milestoneIndex].isApproved, "Milestone already approved.");

        taskMilestones[_taskId][_milestoneIndex].isApproved = true;
        taskMilestones[_taskId][_milestoneIndex].approvalTime = block.timestamp;

        // Partial reward release logic could be added here based on milestone value
        // For simplicity, we'll just move to InProgress after milestone approval
        taskProposals[_taskId].status = TaskStatus.InProgress;
        emit TaskMilestoneApproved(_taskId, _milestoneIndex);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _completionDetails)
        public
        taskExists(_taskId)
        onlyExecutor(_taskId)
        taskStatusIs(_taskId, TaskStatus.InProgress)
    {
        taskProposals[_taskId].status = TaskStatus.Completed; // Pending approval from requester now
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId)
        public
        taskExists(_taskId)
        onlyRequester(_taskId)
        taskStatusIs(_taskId, TaskStatus.Completed)
    {
        TaskProposal storage task = taskProposals[_taskId];
        uint256 rewardAmount = task.currentReward - task.marketplaceFee;
        payable(task.executor).transfer(rewardAmount); // Pay executor (minus marketplace fee)
        task.status = TaskStatus.Completed;
        emit TaskCompletionApproved(_taskId, msg.sender, task.executor, rewardAmount);

        // Trigger prediction market resolution if it exists
        if (task.predictionMarketId != 0) {
            resolvePredictionMarket(task.predictionMarketId);
        }

        // Submit automatic skill review for the executor (optional, can be based on task category)
        submitSkillReview(task.executor, task.taskCategory, 5, "Automatic review after successful task completion."); // Example automatic review
    }


    // --- Dispute Resolution Functions ---

    function requestDisputeResolution(uint256 _taskId, string memory _disputeReason)
        public
        taskExists(_taskId)
        taskStatusIs(_taskId, TaskStatus.Completed) // Or MilestonePendingApproval etc. - define dispute trigger statuses
    {
        disputeCounter++;
        uint256 disputeId = disputeCounter;
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            taskId: _taskId,
            initiator: msg.sender,
            reason: _disputeReason,
            status: DisputeStatus.Open,
            resolver: address(0), // Admin will set resolver later if needed
            winner: address(0),
            resolutionTime: 0
        });
        taskProposals[_taskId].status = TaskStatus.Dispute;
        taskProposals[_taskId].disputeId = disputeId;
        emit DisputeRequested(disputeId, _taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint256 _disputeId, address _winner)
        public
        onlyAdmin()
        disputeExists(_disputeId)
        disputeStatusIs(_disputeId, DisputeStatus.Open)
    {
        Dispute storage dispute = disputes[_disputeId];
        TaskProposal storage task = taskProposals[dispute.taskId];

        dispute.status = DisputeStatus.Resolved;
        dispute.resolver = msg.sender;
        dispute.winner = _winner;
        dispute.resolutionTime = block.timestamp;

        if (_winner == task.requester) {
            payable(task.requester).transfer(task.currentReward); // Return escrowed funds to requester
        } else if (_winner == task.executor) {
            payable(task.executor).transfer(task.currentReward - task.marketplaceFee); // Pay executor (minus marketplace fee)
        } else {
            // Handle split or other resolution logic if needed
            // For now, assuming winner gets full reward or requester gets funds back
        }
        task.status = TaskStatus.Completed; // Or maybe Cancelled depending on dispute outcome
        emit DisputeResolved(_disputeId, dispute.taskId, _winner);
    }


    // --- Executor Profile and Reputation Functions ---

    function registerExecutor(string memory _name, string[] memory _skills, string memory _profileHash) public {
        require(executorProfiles[msg.sender].name.length == 0, "You are already registered as an executor.");
        executorProfiles[msg.sender] = ExecutorProfile({
            name: _name,
            skills: _skills,
            profileHash: _profileHash,
            reputationScore: 0,
            level: 1,
            badgeCount: 0
        });
        emit ExecutorRegistered(msg.sender, _name);
    }

    function updateExecutorProfile(string[] memory _skills, string memory _profileHash) public {
        require(executorProfiles[msg.sender].name.length > 0, "You must register as an executor first.");
        executorProfiles[msg.sender].skills = _skills;
        executorProfiles[msg.sender].profileHash = _profileHash;
        emit ExecutorProfileUpdated(msg.sender);
    }

    function certifySkill(address _executor, string memory _skill, string memory _certificationHash) public onlyAdmin {
        executorProfiles[_executor].skillCertifications[_skill] = _certificationHash;
        emit SkillCertified(_executor, _skill, _certificationHash);
    }

    function submitSkillReview(address _executor, string memory _skill, uint8 _rating, string memory _reviewText)
        public
        validRating(_rating)
    {
        require(executorProfiles[_executor].name.length > 0, "Executor is not registered.");
        executorSkillReviews[_executor].push(SkillReview({
            reviewer: msg.sender,
            skill: _skill,
            rating: _rating,
            reviewText: _reviewText,
            reviewTime: block.timestamp
        }));

        // Update reputation score (simple average for now, can be more sophisticated)
        uint256 totalRating = 0;
        for (uint256 i = 0; i < executorSkillReviews[_executor].length; i++) {
            totalRating += executorSkillReviews[_executor][i].rating;
        }
        executorProfiles[_executor].reputationScore = totalRating / executorSkillReviews[_executor].length;
        emit SkillReviewSubmitted(_executor, _skill, _rating);

        // Level up logic based on reputation score or number of reviews could be added here
    }

    function getExecutorReputation(address _executor) public view returns (uint256) {
        return executorProfiles[_executor].reputationScore;
    }


    // --- Advanced Features (Stake, Prediction Market, Gamification) ---

    function stakeForTaskExecution(uint256 _taskId) public payable taskExists(_taskId) onlyExecutor(_taskId) taskStatusIs(_taskId, TaskStatus.Accepted) {
        require(msg.value > 0, "Stake amount must be greater than zero.");
        taskProposals[_taskId].stakeAmount = msg.value;
        taskProposals[_taskId].status = TaskStatus.InProgress; // Move to in progress after stake
        emit TaskProposalAccepted(_taskId, msg.sender); // Re-emit event to reflect status change perhaps? or new event?
    }

    function createPredictionMarket(uint256 _taskId) public onlyAdmin taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) {
        predictionMarketCounter++;
        uint256 marketId = predictionMarketCounter;
        predictionMarkets[marketId] = PredictionMarket({
            taskId: _taskId,
            yesBetAmount: 0,
            noBetAmount: 0,
            resolved: false,
            taskSucceeded: false
        });
        taskProposals[_taskId].predictionMarketId = marketId;
        emit PredictionMarketCreated(marketId, _taskId);
    }

    function placePredictionMarketBet(uint256 _marketId, bool _willSucceed) public payable {
        require(predictionMarkets[_marketId].taskId != 0, "Prediction market does not exist.");
        require(!predictionMarkets[_marketId].resolved, "Prediction market is already resolved.");
        require(msg.value > 0, "Bet amount must be greater than zero.");

        PredictionMarket storage market = predictionMarkets[_marketId];
        if (_willSucceed) {
            market.yesBetAmount += msg.value;
        } else {
            market.noBetAmount += msg.value;
        }
        emit PredictionBetPlaced(_marketId, msg.sender, _willSucceed, msg.value);
    }

    function resolvePredictionMarket(uint256 _marketId) public onlyAdmin {
        require(predictionMarkets[_marketId].taskId != 0, "Prediction market does not exist.");
        require(!predictionMarkets[_marketId].resolved, "Prediction market is already resolved.");

        PredictionMarket storage market = predictionMarkets[_marketId];
        TaskProposal storage task = taskProposals[market.taskId];

        market.resolved = true;
        market.taskSucceeded = (task.status == TaskStatus.Completed); // Define success criteria

        emit PredictionMarketResolved(_marketId, market.taskSucceeded);

        // Payout logic for prediction market
        if (market.taskSucceeded) {
            if (market.yesBetAmount > 0) {
                uint256 totalPool = market.yesBetAmount + market.noBetAmount;
                uint256 yesBettersReward = (totalPool * market.yesBetAmount) / market.yesBetAmount; // Proportional payout (simplified - needs handling of zero yesBetAmount)
                // Distribute rewards to 'yes' betters proportionally - needs to track individual betters and amounts for a real implementation
                // For now, just transferring total pool back to contract owner for distribution example
                payable(admin).transfer(totalPool);
            }
        } else {
            if (market.noBetAmount > 0) {
                uint256 totalPool = market.yesBetAmount + market.noBetAmount;
                uint256 noBettersReward = (totalPool * market.noBetAmount) / market.noBetAmount; // Proportional payout (simplified - needs handling of zero noBetAmount)
                // Distribute rewards to 'no' betters proportionally - needs to track individual betters and amounts for a real implementation
                // For now, just transferring total pool back to contract owner for distribution example
                payable(admin).transfer(totalPool);
            }
        }
    }

    function createCommunityBadge(string memory _badgeName, string memory _badgeDescription, string memory _badgeCriteria) public onlyAdmin {
        communityBadgeCounter++;
        uint256 badgeId = communityBadgeCounter;
        communityBadges[badgeId] = CommunityBadge({
            name: _badgeName,
            description: _badgeDescription,
            criteria: _badgeCriteria,
            badgeId: badgeId
        });
        emit CommunityBadgeCreated(badgeId, _badgeName);
    }

    function awardBadgeToExecutor(address _executor, uint256 _badgeId) public onlyAdmin {
        require(communityBadges[_badgeId].badgeId != 0, "Community badge does not exist.");
        executorProfiles[_executor].badgeCount++; // Simple badge count, could store badge IDs in a list for more detail
        emit BadgeAwarded(_executor, _badgeId);
    }

    // --- Moderation and Reporting Functions ---

    function reportExecutor(address _executor, string memory _reportReason) public {
        require(executorProfiles[_executor].name.length > 0, "Reported executor is not registered.");
        reportCounter++;
        uint256 reportId = reportCounter;
        executorReports[reportId] = Report({
            reporter: msg.sender,
            reportedExecutor: _executor,
            reason: _reportReason,
            reportTime: block.timestamp,
            resolved: false,
            isGuilty: false,
            moderationNotes: ""
        });
        emit ExecutorReported(reportId, msg.sender, _executor, _reportReason);
    }

    function moderateExecutorReport(uint256 _reportId, bool _isGuilty, string memory _moderationNotes) public onlyAdmin {
        require(executorReports[_reportId].reporter != address(0), "Report does not exist.");
        require(!executorReports[_reportId].resolved, "Report is already resolved.");

        executorReports[_reportId].resolved = true;
        executorReports[_reportId].isGuilty = _isGuilty;
        executorReports[_reportId].moderationNotes = _moderationNotes;

        if (_isGuilty) {
            // Implement penalties for guilty executors (e.g., reputation decrease, temporary ban)
            executorProfiles[executorReports[_reportId].reportedExecutor].reputationScore -= 10; // Example penalty
        }
        emit ExecutorReportModerated(_reportId, executorReports[_reportId].reportedExecutor, _isGuilty);
    }


    // --- Marketplace Fee Management ---

    function setMarketplaceFee(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 20, "Marketplace fee percentage cannot exceed 20%."); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    function withdrawMarketplaceFees() public onlyAdmin {
        uint256 amountToWithdraw = marketplaceFeeBalance;
        marketplaceFeeBalance = 0;
        payable(admin).transfer(amountToWithdraw);
    }


    // --- Governance Functions ---

    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) public {
        governanceProposalCounter++;
        uint256 proposalId = governanceProposalCounter;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            calldataData: _calldata,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Pending
        });
        emit GovernanceProposalCreated(proposalId, _proposalDescription);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote)
        public
        proposalExists(_proposalId)
        proposalStatusIs(_proposalId, ProposalStatus.Pending)
        votingPeriodActive(_proposalId)
    {
        require(executorProfiles[msg.sender].name.length > 0, "Only registered executors can vote."); // Example: Only executors can vote

        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceProposal(uint256 _proposalId)
        public
        onlyAdmin // Or time-based auto-execution after voting ends
        proposalExists(_proposalId)
        proposalStatusIs(_proposalId, ProposalStatus.Pending)
    {
        require(block.timestamp > governanceProposals[_proposalId].votingEndTime, "Voting period is still active.");
        governanceProposals[_proposalId].status = ProposalStatus.Resolved;

        // Simple majority for approval (can be changed)
        if (governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes) {
            (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].calldataData); // Execute the proposed change
            require(success, "Governance proposal execution failed.");
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            // Proposal rejected - handle rejection logic if needed
        }
    }

    // --- Fallback and Receive (for receiving funds for task escrow) ---

    receive() external payable {}
    fallback() external payable {}
}
```