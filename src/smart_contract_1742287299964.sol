```solidity
/**
 * @title Dynamic Reputation and Reward System with On-Chain Governance
 * @author Bard (AI-generated example - for educational purposes only, not audited for production)
 * @dev A smart contract implementing a dynamic reputation system for on-chain users,
 * with various mechanisms to earn and lose reputation, integrated with a reward system
 * and basic on-chain governance for parameter adjustments.
 *
 * **Contract Outline:**
 *
 * **1. User Registration & Reputation Core:**
 *    - registerUser(): Allows users to register in the system.
 *    - getReputation(address user): Retrieves a user's reputation score.
 *    - getReputationLevel(address user): Returns the user's reputation level based on score.
 *    - reputationLevels(uint level): View function to get the name and threshold of a reputation level.
 *    - reputationScoreThresholds(uint level): View function to get the reputation threshold for a level.
 *
 * **2. Reputation Earning Mechanisms:**
 *    - contributeToProject(uint projectId):  Users earn reputation for contributing to a project.
 *    - participateInEvent(uint eventId): Users earn reputation for participating in an event.
 *    - provideHelpfulFeedback(address targetUser, string memory feedbackText): Users earn reputation for giving positive feedback.
 *    - stakeTokens(uint amount): Users earn reputation for staking tokens in the contract.
 *    - proposeFeature(string memory featureDescription): Users earn reputation for proposing valuable features (governance approved).
 *
 * **3. Reputation Loss Mechanisms:**
 *    - reportMaliciousActivity(address reportedUser, string memory reportReason): Users can report malicious activity, potentially leading to reputation loss for the reported user (governance reviewed).
 *    - penalizeUser(address user, uint penaltyPoints): Owner/Governance function to manually penalize a user.
 *    - reputationDecay():  Function to periodically decay reputation for inactive users.
 *
 * **4. Reward System (Reputation-Based Access/Benefits):**
 *    - accessPremiumFeature(uint featureId):  Allows users with sufficient reputation to access premium features.
 *    - claimReward(uint rewardId):  Users with sufficient reputation can claim rewards.
 *    - getAvailableRewards(): View function to see available rewards and required reputation.
 *
 * **5. On-Chain Governance (Simple Parameter Adjustment):**
 *    - proposeReputationLevelChange(uint level, string memory newName, uint newThreshold): Propose a change to a reputation level.
 *    - proposeRewardChange(uint rewardId, string memory newDescription, uint newReputationRequirement): Propose a change to a reward.
 *    - voteOnProposal(uint proposalId, bool vote): Users with sufficient reputation can vote on proposals.
 *    - executeProposal(uint proposalId): Owner/Governance function to execute an approved proposal.
 *    - getProposalDetails(uint proposalId): View function to get details of a proposal.
 *
 * **6. Administrative & Utility Functions:**
 *    - setReputationGainForContribution(uint points): Owner function to set reputation gain for contributions.
 *    - setReputationGainForEvent(uint points): Owner function to set reputation gain for event participation.
 *    - setReputationGainForFeedback(uint points): Owner function to set reputation gain for helpful feedback.
 *    - setStakingReputationRatio(uint ratio): Owner function to set the reputation gain ratio for staking.
 *    - setDecayRate(uint rate): Owner function to set the reputation decay rate.
 *    - addReward(string memory description, uint reputationRequirement): Owner function to add new rewards.
 *    - pauseContract(): Owner function to pause the contract.
 *    - unpauseContract(): Owner function to unpause the contract.
 *    - ownerWithdraw(address payable recipient, uint amount): Owner function to withdraw contract balance.
 *
 * **Function Summary:**
 *
 * **User Registration & Reputation Core:**
 * - `registerUser()`: Allows a user to register in the system if not already registered. Emits `UserRegistered` event.
 * - `getReputation(address user) view returns (uint)`: Returns the reputation score of a given user.
 * - `getReputationLevel(address user) view returns (string memory)`: Returns the reputation level name of a user based on their score.
 * - `reputationLevels(uint level) view returns (string memory name, uint threshold)`: Returns the name and reputation threshold for a given reputation level index.
 * - `reputationScoreThresholds(uint level) view returns (uint)`: Returns the reputation threshold for a given reputation level index.
 *
 * **Reputation Earning Mechanisms:**
 * - `contributeToProject(uint projectId)`: Allows a registered user to contribute to a project (project IDs are assumed to be managed externally). Increases user's reputation and emits `ReputationEarned` event.
 * - `participateInEvent(uint eventId)`: Allows a registered user to participate in an event (event IDs are assumed to be managed externally). Increases user's reputation and emits `ReputationEarned` event.
 * - `provideHelpfulFeedback(address targetUser, string memory feedbackText)`: Allows a registered user to give feedback to another registered user. Increases giver's reputation and emits `ReputationEarned` event.
 * - `stakeTokens(uint amount)`: Allows a registered user to stake tokens in the contract. Increases reputation based on staked amount and `stakingReputationRatio`. Emits `ReputationEarned` and `TokensStaked` events.
 * - `proposeFeature(string memory featureDescription)`: Allows a registered user to propose a new feature. Creates a governance proposal. Emits `FeatureProposed` and `ProposalCreated` events.
 *
 * **Reputation Loss Mechanisms:**
 * - `reportMaliciousActivity(address reportedUser, string memory reportReason)`: Allows a registered user to report another user for malicious activity. Creates a governance proposal for review. Emits `MaliciousActivityReported` and `ProposalCreated` events.
 * - `penalizeUser(address user, uint penaltyPoints) onlyOwner`: Owner-only function to manually penalize a user by reducing their reputation. Emits `ReputationLost` event.
 * - `reputationDecay()`:  Callable by anyone (or can be automated off-chain) to periodically reduce reputation of inactive users based on `decayRate`. Emits `ReputationDecayed` event.
 *
 * **Reward System (Reputation-Based Access/Benefits):**
 * - `accessPremiumFeature(uint featureId)`: Allows users with sufficient reputation to access a premium feature (feature IDs are assumed to be managed externally). Requires reputation check. Emits `FeatureAccessed` event.
 * - `claimReward(uint rewardId)`: Allows users with sufficient reputation to claim a reward (if available). Requires reputation and reward availability check. Emits `RewardClaimed` event.
 * - `getAvailableRewards() view returns (Reward[] memory)`: Returns a list of available rewards and their reputation requirements.
 *
 * **On-Chain Governance (Simple Parameter Adjustment):**
 * - `proposeReputationLevelChange(uint level, string memory newName, uint newThreshold)`: Allows registered users to propose changes to reputation level names or thresholds. Creates a governance proposal. Emits `ReputationLevelChangeProposed` and `ProposalCreated` events.
 * - `proposeRewardChange(uint rewardId, string memory newDescription, uint newReputationRequirement)`: Allows registered users to propose changes to reward descriptions or reputation requirements. Creates a governance proposal. Emits `RewardChangeProposed` and `ProposalCreated` events.
 * - `voteOnProposal(uint proposalId, bool vote)`: Allows registered users with sufficient reputation (e.g., at least 'Novice') to vote on a proposal. Emits `VoteCast` event.
 * - `executeProposal(uint proposalId) onlyOwner`: Owner-only function to execute a proposal after a voting period and if approved (simple majority assumed for this example). Emits `ProposalExecuted` event and specific event based on proposal type (e.g., `ReputationLevelChanged`, `RewardChanged`).
 * - `getProposalDetails(uint proposalId) view returns (Proposal memory)`: Returns details of a specific proposal.
 *
 * **Administrative & Utility Functions:**
 * - `setReputationGainForContribution(uint points) onlyOwner`: Owner-only function to set the reputation points gained for contributing to projects.
 * - `setReputationGainForEvent(uint points) onlyOwner`: Owner-only function to set the reputation points gained for participating in events.
 * - `setReputationGainForFeedback(uint points) onlyOwner`: Owner-only function to set the reputation points gained for providing helpful feedback.
 * - `setStakingReputationRatio(uint ratio) onlyOwner`: Owner-only function to set the ratio of staked tokens to reputation points gained.
 * - `setDecayRate(uint rate) onlyOwner`: Owner-only function to set the reputation decay rate (percentage to reduce reputation by).
 * - `addReward(string memory description, uint reputationRequirement) onlyOwner`: Owner-only function to add a new reward to the system.
 * - `pauseContract() onlyOwner`: Owner-only function to pause the contract, preventing most non-view functions from being executed.
 * - `unpauseContract() onlyOwner`: Owner-only function to unpause the contract.
 * - `ownerWithdraw(address payable recipient, uint amount) onlyOwner`: Owner-only function to withdraw contract balance (e.g., staked tokens if applicable, or any fees collected, though this example doesn't explicitly collect fees).
 */
pragma solidity ^0.8.0;

contract DynamicReputationSystem {
    // State Variables

    // User Registration and Reputation
    mapping(address => bool) public isRegisteredUser;
    mapping(address => uint) public userReputation;
    uint public reputationGainForContribution = 10;
    uint public reputationGainForEvent = 5;
    uint public reputationGainForFeedback = 3;
    uint public stakingReputationRatio = 100; // Tokens per reputation point
    uint public reputationDecayRate = 5; // Percentage decay per decay period
    uint public lastDecayTimestamp;
    uint public decayPeriod = 30 days;

    struct ReputationLevel {
        string name;
        uint threshold;
    }
    ReputationLevel[] public reputationLevels;

    // Rewards System
    struct Reward {
        uint id;
        string description;
        uint reputationRequirement;
        bool isActive;
    }
    Reward[] public rewards;
    uint public nextRewardId = 1;

    // Governance Proposals
    enum ProposalType { REPUTATION_LEVEL_CHANGE, REWARD_CHANGE, FEATURE_PROPOSAL, MALICIOUS_ACTIVITY_REPORT }
    struct Proposal {
        uint id;
        ProposalType proposalType;
        address proposer;
        string description;
        uint votingEndTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
        // Specific proposal data (using bytes to store encoded data, can be decoded in functions)
        bytes proposalData;
    }
    mapping(uint => Proposal) public proposals;
    uint public nextProposalId = 1;
    uint public votingPeriod = 7 days;
    uint public requiredVotesPercentage = 50; // Simple majority for now

    // Contract Administration
    address public owner;
    bool public paused;

    // Events
    event UserRegistered(address user);
    event ReputationEarned(address user, uint points, string reason);
    event ReputationLost(address user, uint points, string reason);
    event ReputationDecayed(address user, uint previousReputation, uint newReputation, uint decayPercentage);
    event TokensStaked(address user, uint amount);
    event FeatureAccessed(address user, uint featureId);
    event RewardClaimed(address user, uint rewardId, address claimer);

    // Governance Events
    event ProposalCreated(uint proposalId, ProposalType proposalType, address proposer, string description);
    event VoteCast(uint proposalId, address voter, bool vote);
    event ProposalExecuted(uint proposalId, ProposalType proposalType, bool success);
    event ReputationLevelChangeProposed(uint proposalId, uint level, string newName, uint newThreshold);
    event ReputationLevelChanged(uint level, string newName, uint newThreshold);
    event RewardChangeProposed(uint proposalId, uint rewardId, string newDescription, uint newReputationRequirement);
    event RewardChanged(uint rewardId, string newDescription, uint newReputationRequirement);
    event FeatureProposed(uint proposalId, string featureDescription);
    event MaliciousActivityReported(uint proposalId, address reportedUser, address reporter, string reportReason);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isRegisteredUser[msg.sender], "User must be registered.");
        _;
    }

    modifier sufficientReputation(uint requiredReputation) {
        require(userReputation[msg.sender] >= requiredReputation, "Insufficient reputation.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        paused = false;
        lastDecayTimestamp = block.timestamp;

        // Initialize Reputation Levels
        reputationLevels.push(ReputationLevel("Beginner", 0));
        reputationLevels.push(ReputationLevel("Novice", 100));
        reputationLevels.push(ReputationLevel("Advanced", 500));
        reputationLevels.push(ReputationLevel("Expert", 1000));
        reputationLevels.push(ReputationLevel("Master", 2500));

        // Initialize some example rewards
        addReward("Early Access Pass", 500);
        addReward("Premium Support", 1000);
        addReward("Exclusive Content", 2000);
    }

    // ------------------------------------------------------------------------
    // 1. User Registration & Reputation Core
    // ------------------------------------------------------------------------

    function registerUser() external whenNotPaused {
        require(!isRegisteredUser[msg.sender], "User already registered.");
        isRegisteredUser[msg.sender] = true;
        emit UserRegistered(msg.sender);
    }

    function getReputation(address user) external view returns (uint) {
        return userReputation[user];
    }

    function getReputationLevel(address user) external view returns (string memory) {
        uint reputation = userReputation[user];
        for (uint i = reputationLevels.length; i > 0; i--) {
            if (reputation >= reputationLevels[i-1].threshold) {
                return reputationLevels[i-1].name;
            }
        }
        return reputationLevels[0].name; // Should always at least be "Beginner"
    }

    function reputationLevels(uint level) external view returns (string memory name, uint threshold) {
        require(level < reputationLevels.length, "Invalid reputation level index.");
        return (reputationLevels[level].name, reputationLevels[level].threshold);
    }

    function reputationScoreThresholds(uint level) external view returns (uint) {
        require(level < reputationLevels.length, "Invalid reputation level index.");
        return reputationLevels[level].threshold;
    }

    // ------------------------------------------------------------------------
    // 2. Reputation Earning Mechanisms
    // ------------------------------------------------------------------------

    function contributeToProject(uint projectId) external whenNotPaused onlyRegisteredUser {
        userReputation[msg.sender] += reputationGainForContribution;
        emit ReputationEarned(msg.sender, reputationGainForContribution, "Project Contribution");
    }

    function participateInEvent(uint eventId) external whenNotPaused onlyRegisteredUser {
        userReputation[msg.sender] += reputationGainForEvent;
        emit ReputationEarned(msg.sender, reputationGainForEvent, "Event Participation");
    }

    function provideHelpfulFeedback(address targetUser, string memory feedbackText) external whenNotPaused onlyRegisteredUser {
        require(isRegisteredUser[targetUser], "Target user must be registered.");
        userReputation[msg.sender] += reputationGainForFeedback;
        emit ReputationEarned(msg.sender, reputationGainForFeedback, "Helpful Feedback");
    }

    function stakeTokens(uint amount) external payable whenNotPaused onlyRegisteredUser {
        // In a real scenario, you would manage actual token staking logic here.
        // For this example, we are just simulating token staking for reputation.
        require(amount > 0, "Stake amount must be positive.");
        uint reputationGain = amount / stakingReputationRatio;
        userReputation[msg.sender] += reputationGain;
        emit ReputationEarned(msg.sender, reputationGain, "Token Staking");
        emit TokensStaked(msg.sender, amount);
    }

    function proposeFeature(string memory featureDescription) external whenNotPaused onlyRegisteredUser {
        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.FEATURE_PROPOSAL,
            proposer: msg.sender,
            description: featureDescription,
            votingEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposalData: bytes("") // No specific data needed for feature proposal
        });
        emit ProposalCreated(proposalId, ProposalType.FEATURE_PROPOSAL, msg.sender, featureDescription);
        emit FeatureProposed(proposalId, featureDescription);
    }

    // ------------------------------------------------------------------------
    // 3. Reputation Loss Mechanisms
    // ------------------------------------------------------------------------

    function reportMaliciousActivity(address reportedUser, string memory reportReason) external whenNotPaused onlyRegisteredUser {
        require(isRegisteredUser[reportedUser], "Reported user must be registered.");
        require(reportedUser != msg.sender, "Cannot report yourself.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.MALICIOUS_ACTIVITY_REPORT,
            proposer: msg.sender,
            description: reportReason,
            votingEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposalData: abi.encode(reportedUser) // Store reported user address in proposal data
        });
        emit ProposalCreated(proposalId, ProposalType.MALICIOUS_ACTIVITY_REPORT, msg.sender, reportReason);
        emit MaliciousActivityReported(proposalId, reportedUser, msg.sender, reportReason);
    }

    function penalizeUser(address user, uint penaltyPoints) external whenNotPaused onlyOwner {
        require(isRegisteredUser[user], "User must be registered.");
        require(userReputation[user] >= penaltyPoints, "User reputation is lower than penalty points.");
        userReputation[user] -= penaltyPoints;
        emit ReputationLost(user, penaltyPoints, "Admin Penalty");
    }

    function reputationDecay() external whenNotPaused {
        require(block.timestamp >= lastDecayTimestamp + decayPeriod, "Decay period not elapsed yet.");
        lastDecayTimestamp = block.timestamp;

        for (uint i = 0; i < reputationLevels.length; i++) {
            for (address user in getUsersInLevel(i)) { // Assuming you have a way to track users per level - simplified here
                if (userReputation[user] > 0) {
                    uint decayAmount = (userReputation[user] * reputationDecayRate) / 100;
                    uint previousReputation = userReputation[user];
                    userReputation[user] -= decayAmount;
                    emit ReputationDecayed(user, previousReputation, userReputation[user], reputationDecayRate);
                }
            }
        }
    }

    // Placeholder function to get users in a reputation level - in a real scenario, you'd need to maintain this mapping.
    function getUsersInLevel(uint level) private view returns (address[] memory) {
        // In a real implementation, you would need to maintain a mapping or list of users per reputation level
        // For simplicity of this example, this is just a placeholder and won't return actual users.
        return new address[](0);
    }

    // ------------------------------------------------------------------------
    // 4. Reward System (Reputation-Based Access/Benefits)
    // ------------------------------------------------------------------------

    function accessPremiumFeature(uint featureId) external view whenNotPaused onlyRegisteredUser sufficientReputation(getFeatureReputationRequirement(featureId)) returns (bool) {
        // In a real scenario, you would implement the logic for accessing the premium feature here.
        // For this example, we are just checking reputation and returning true if access is granted.
        emit FeatureAccessed(msg.sender, featureId);
        return true;
    }

    function getFeatureReputationRequirement(uint featureId) private pure returns (uint) {
        // Placeholder function - in a real system, feature reputation requirements would be managed.
        // For this example, just returning a fixed value for demonstration.
        if (featureId == 1) return 200;
        if (featureId == 2) return 800;
        return 0; // Default, no requirement
    }

    function claimReward(uint rewardId) external whenNotPaused onlyRegisteredUser {
        require(rewardId > 0 && rewardId <= rewards.length, "Invalid reward ID.");
        Reward storage reward = rewards[rewardId - 1]; // Adjust index to be 0-based
        require(reward.isActive, "Reward is not active.");
        require(userReputation[msg.sender] >= reward.reputationRequirement, "Insufficient reputation for reward.");

        reward.isActive = false; // Mark reward as claimed (one-time reward in this example)
        emit RewardClaimed(rewardId, msg.sender, msg.sender);
        // In a real system, you would likely transfer a token or perform some other reward action here.
    }

    function getAvailableRewards() external view returns (Reward[] memory) {
        Reward[] memory availableRewards = new Reward[](rewards.length);
        uint count = 0;
        for (uint i = 0; i < rewards.length; i++) {
            if (rewards[i].isActive) {
                availableRewards[count] = rewards[i];
                count++;
            }
        }
        // Resize the array to remove empty slots if needed (if rewards were removed)
        Reward[] memory resizedRewards = new Reward[](count);
        for (uint i = 0; i < count; i++) {
            resizedRewards[i] = availableRewards[i];
        }
        return resizedRewards;
    }

    // ------------------------------------------------------------------------
    // 5. On-Chain Governance (Simple Parameter Adjustment)
    // ------------------------------------------------------------------------

    function proposeReputationLevelChange(uint level, string memory newName, uint newThreshold) external whenNotPaused onlyRegisteredUser {
        require(level > 0 && level < reputationLevels.length, "Cannot change Beginner level or invalid level index."); // Cannot change Beginner level
        require(newThreshold > reputationLevels[level-1].threshold, "New threshold must be higher than previous level threshold.");
        require(newThreshold < (level + 1 < reputationLevels.length ? reputationLevels[level+1].threshold : type(uint).max), "New threshold must be lower than next level threshold.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.REPUTATION_LEVEL_CHANGE,
            proposer: msg.sender,
            description: "Propose to change reputation level " + string(abi.encodePacked(level)) + " to '" + newName + "' with threshold " + string(abi.encodePacked(newThreshold)),
            votingEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposalData: abi.encode(level, newName, newThreshold)
        });
        emit ProposalCreated(proposalId, ProposalType.REPUTATION_LEVEL_CHANGE, msg.sender, "Change reputation level");
        emit ReputationLevelChangeProposed(proposalId, level, newName, newThreshold);
    }

    function proposeRewardChange(uint rewardId, string memory newDescription, uint newReputationRequirement) external whenNotPaused onlyRegisteredUser {
        require(rewardId > 0 && rewardId <= rewards.length, "Invalid reward ID.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.REWARD_CHANGE,
            proposer: msg.sender,
            description: "Propose to change reward " + string(abi.encodePacked(rewardId)) + " to '" + newDescription + "' with reputation requirement " + string(abi.encodePacked(newReputationRequirement)),
            votingEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposalData: abi.encode(rewardId, newDescription, newReputationRequirement)
        });
        emit ProposalCreated(proposalId, ProposalType.REWARD_CHANGE, msg.sender, "Change reward");
        emit RewardChangeProposed(proposalId, rewardId, newDescription, newReputationRequirement);
    }

    function voteOnProposal(uint proposalId, bool vote) external whenNotPaused onlyRegisteredUser sufficientReputation(reputationLevels[1].threshold) { // Novice level or higher can vote
        require(proposals[proposalId].votingEndTime > block.timestamp, "Voting period has ended.");
        require(!proposals[proposalId].executed, "Proposal already executed.");
        require(msg.sender != proposals[proposalId].proposer, "Proposer cannot vote on their own proposal."); // Proposer cannot vote

        if (vote) {
            proposals[proposalId].yesVotes++;
        } else {
            proposals[proposalId].noVotes++;
        }
        emit VoteCast(proposalId, msg.sender, vote);
    }

    function executeProposal(uint proposalId) external whenNotPaused onlyOwner {
        require(proposals[proposalId].votingEndTime <= block.timestamp, "Voting period not ended yet.");
        require(!proposals[proposalId].executed, "Proposal already executed.");

        Proposal storage proposal = proposals[proposalId];
        uint totalVotes = proposal.yesVotes + proposal.noVotes;
        bool approved = (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= requiredVotesPercentage); // Simple majority

        proposal.executed = true;

        if (approved) {
            emit ProposalExecuted(proposalId, proposal.proposalType, true);
            if (proposal.proposalType == ProposalType.REPUTATION_LEVEL_CHANGE) {
                (uint levelToChange, string memory newName, uint newThreshold) = abi.decode(proposal.proposalData, (uint, string, uint));
                reputationLevels[levelToChange].name = newName;
                reputationLevels[levelToChange].threshold = newThreshold;
                emit ReputationLevelChanged(levelToChange, newName, newThreshold);
            } else if (proposal.proposalType == ProposalType.REWARD_CHANGE) {
                (uint rewardIdToChange, string memory newDescription, uint newReputationRequirement) = abi.decode(proposal.proposalData, (uint, string, uint));
                rewards[rewardIdToChange - 1].description = newDescription; // Adjust index
                rewards[rewardIdToChange - 1].reputationRequirement = newReputationRequirement;
                emit RewardChanged(rewardIdToChange, newDescription, newReputationRequirement);
            } else if (proposal.proposalType == ProposalType.FEATURE_PROPOSAL) {
                // Feature proposals are just for tracking, no on-chain execution in this simplified example.
                // In a real system, this might trigger off-chain actions or further on-chain logic.
            } else if (proposal.proposalType == ProposalType.MALICIOUS_ACTIVITY_REPORT) {
                (address reportedUser) = abi.decode(proposal.proposalData, (address));
                // If report is approved, penalize the reported user (e.g., reduce reputation significantly)
                if (isRegisteredUser[reportedUser]) {
                    uint penalty = 200; // Example penalty for malicious activity
                    if (userReputation[reportedUser] >= penalty) {
                        userReputation[reportedUser] -= penalty;
                        emit ReputationLost(reportedUser, penalty, "Malicious Activity Penalty (Governance Approved)");
                    } else {
                        userReputation[reportedUser] = 0;
                        emit ReputationLost(reportedUser, userReputation[reportedUser], "Malicious Activity Penalty (Governance Approved, all reputation)");
                    }
                }
            }
        } else {
            emit ProposalExecuted(proposalId, proposal.proposalType, false);
        }
    }

    function getProposalDetails(uint proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    // ------------------------------------------------------------------------
    // 6. Administrative & Utility Functions
    // ------------------------------------------------------------------------

    function setReputationGainForContribution(uint points) external onlyOwner {
        reputationGainForContribution = points;
    }

    function setReputationGainForEvent(uint points) external onlyOwner {
        reputationGainForEvent = points;
    }

    function setReputationGainForFeedback(uint points) external onlyOwner {
        reputationGainForFeedback = points;
    }

    function setStakingReputationRatio(uint ratio) external onlyOwner {
        stakingReputationRatio = ratio;
    }

    function setDecayRate(uint rate) external onlyOwner {
        require(rate <= 100, "Decay rate must be between 0 and 100.");
        reputationDecayRate = rate;
    }

    function addReward(string memory description, uint reputationRequirement) external onlyOwner {
        rewards.push(Reward({
            id: nextRewardId++,
            description: description,
            reputationRequirement: reputationRequirement,
            isActive: true
        }));
    }

    function pauseContract() external onlyOwner {
        paused = true;
    }

    function unpauseContract() external onlyOwner {
        paused = false;
    }

    function ownerWithdraw(address payable recipient, uint amount) external onlyOwner {
        payable(recipient).transfer(amount);
    }

    receive() external payable {} // To allow receiving ETH for staking (in a real system, token staking logic would be more complex)
}
```