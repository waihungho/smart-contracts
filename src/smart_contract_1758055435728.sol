This smart contract, "DRIN (Decentralized Research & Innovation Nexus)", aims to create a dynamic, self-sustaining ecosystem for collaborative research and innovation. It goes beyond typical DeFi or NFT projects by integrating a multi-faceted reputation system, internal Soulbound Tokens (SBTs) for achievements, and a simulated AI Oracle integration for advanced governance or evaluation, all within an epoch-based operational model.

---

## Contract Outline: Decentralized Research & Innovation Nexus (DRIN)

This contract facilitates a decentralized platform for proposing, funding, researching, and validating innovative research topics. It incorporates advanced concepts such as:
- **Dynamic, Multi-faceted Reputation System:** Users earn different types of reputation (research, validation, proposal) that influence their standing and privileges.
- **Soulbound Tokens (SBTs) for Achievements:** Non-transferable tokens are minted by the contract to acknowledge significant contributions and milestones, serving as verifiable credentials.
- **Simulated AI Oracle Integration:** The contract provides an interface for a trusted off-chain AI Oracle to submit verifiable hashes of its computations or feedback, which can then influence governance decisions or automated processes.
- **Epoch-based Validator Selection & Activity Tracking:** The system operates in epochs, with validator eligibility and selection dynamically adjusted based on reputation, stake, and recent activity.
- **On-chain Governance:** Token holders can propose and vote on changes to system parameters, ensuring decentralized evolution.
- **Staking Mechanisms:** Participants stake native DRIN tokens for various actions (proposing, contributing, validating), aligning incentives and ensuring commitment.

## Function Summary:

### I. Core Platform Operations (Research & Contribution Lifecycle)
1.  `proposeResearchTopic(string calldata _title, bytes32 _descriptionHash, uint256 _fundingGoal, uint256 _submissionDeadline, uint256 _reviewDeadline)`: Initiates a new research challenge, requiring a stake from the proposer.
2.  `fundResearchTopic(uint256 _topicId)`: Allows users to contribute funding towards a proposed topic's goal.
3.  `approveResearchTopic(uint256 _topicId)`: (Governor-only) Marks a sufficiently funded topic as "Approved", making it open for contributions.
4.  `submitContribution(uint256 _topicId, bytes32 _contentHash)`: Submits research output or a solution to an active topic, requiring a stake.
5.  `registerAsValidator(uint256 _stakeAmount)`: Stakes DRIN tokens to become eligible for reviewing contributions, requiring a minimum reputation.
6.  `deregisterAsValidator()`: Allows an active validator to unstake their tokens and exit the validator pool, subject to conditions (e.g., no active reviews).
7.  `submitValidationOutcome(uint256 _contributionId, int256 _score, bytes32 _feedbackHash)`: Validators submit their review scores and feedback hashes for assigned contributions.
8.  `finalizeContributionEvaluation(uint256 _contributionId)`: Aggregates validator scores, updates contributor/validator reputations, and prepares rewards for successful contributions.
9.  `challengeValidationOutcome(uint256 _contributionId, bytes32 _reasonHash)`: Allows a contributor to dispute the evaluation of their submission, initiating a re-evaluation or governance review process.
10. `updateTopicStatus(uint256 _topicId, TopicStatus _newStatus)`: (Governor-only) Allows manual adjustment of a topic's status for exceptional cases.

### II. Reputation & Soulbound Credentials
11. `getUserReputation(address _user)`: Retrieves a user's current multi-dimensional reputation scores.
12. `mintResearchAchievementSBC(address _recipient, bytes32 _metadataHash)`: (Internal) Awards a Soulbound Token for significant research achievements.
13. `mintValidatorMeritSBC(address _recipient, bytes32 _metadataHash)`: (Internal) Awards a Soulbound Token for excellent validation performance.
14. `getSoulboundCredentialDetails(address _owner, uint256 _credentialId)`: Retrieves details of a specific Soulbound Token owned by an address.

### III. Governance & AI Oracle Integration
15. `submitGovernanceProposal(bytes32 _proposalHash, bytes calldata _callData, address _targetContract, string calldata _description)`: Proposes system parameter changes or actions, requiring a stake.
16. `voteOnProposal(uint256 _proposalId, bool _voteYes)`: Allows token holders to vote on active governance proposals.
17. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed and met its quorum requirements.
18. `updateAIOracleAddress(address _newOracleAddress)`: (Governor-only) Sets the trusted address for the AI Oracle, which can post verifiable feedback.
19. `registerAIOracleFeedbackHash(bytes32 _contextHash, bytes32 _feedbackHash)`: Allows the registered AI Oracle to post a verifiable hash of its off-chain feedback for later use (e.g., for automated parameter tuning suggestions or dispute resolution insights).

### IV. Token Staking & Rewards
20. `depositNativeTokenForStaking(uint256 _amount)`: Users deposit the native DRIN ERC-20 token into the contract to participate in staking.
21. `withdrawStakedNativeToken(uint256 _amount)`: Allows users to unstake and withdraw their DRIN tokens, subject to cool-down or unbonding periods if active in roles.
22. `claimRewards()`: Allows users to claim their accumulated rewards from successful contributions and accurate validations.
23. `distributeTopicPayouts(uint256 _topicId)`: (Governor-only or internal trigger) Distributes the collected funding of a completed topic to its successful contributors.

### V. View & Utility Functions
24. `getTopicDetails(uint256 _topicId)`: Retrieves comprehensive details for a specific research topic.
25. `getContributionDetails(uint256 _contributionId)`: Retrieves comprehensive details for a specific contribution.
26. `getValidatorProfile(address _validator)`: Retrieves a validator's current profile information and stake.
27. `getCurrentEpoch()`: Returns the current operational epoch of the contract.
28. `getTotalStakedTokens()`: Returns the total amount of DRIN tokens currently staked within the contract.
29. `getValidatorPool()`: Returns an array of addresses of currently active and eligible validators.

Total Functions: 29

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for arithmetic operations

// Contract Outline: Decentralized Research & Innovation Nexus (DRIN)
//
// This contract facilitates a decentralized platform for proposing, funding,
// researching, and validating innovative research topics. It incorporates
// advanced concepts such as:
// - Dynamic, multi-faceted Reputation System
// - Soulbound Tokens (SBTs) for achievements and credentials
// - Simulated AI Oracle integration for governance or evaluation assistance
// - Epoch-based validator selection and activity tracking
// - On-chain Governance for system parameters and proposals
// - Staking mechanisms for participation and quality assurance
//
// Function Summary:
//
// I. Core Platform Operations (Research & Contribution Lifecycle)
//    1. proposeResearchTopic: Initiates a new research challenge.
//    2. fundResearchTopic: Contributes funding to a proposed topic.
//    3. approveResearchTopic: Marks a funded topic as "Approved" (governor-only).
//    4. submitContribution: Submits research output/solution to an active topic.
//    5. registerAsValidator: Stakes tokens to become eligible for validating.
//    6. deregisterAsValidator: Removes oneself from the validator pool.
//    7. submitValidationOutcome: Validators submit their review scores and feedback.
//    8. finalizeContributionEvaluation: Aggregates validation, updates reputation, prepares rewards.
//    9. challengeValidationOutcome: Allows contributors to dispute evaluation outcomes.
//    10. updateTopicStatus: Governor function to manually change a topic's status.
//
// II. Reputation & Soulbound Credentials
//    11. getUserReputation: Retrieves a user's multi-dimensional reputation score.
//    12. mintResearchAchievementSBC: Internally triggered to award Soulbound Tokens for research milestones.
//    13. mintValidatorMeritSBC: Internally triggered to award Soulbound Tokens for validation excellence.
//    14. getSoulboundCredentialDetails: Retrieves details of a specific SBT.
//
// III. Governance & AI Oracle Integration
//    15. submitGovernanceProposal: Proposes changes to system parameters or actions.
//    16. voteOnProposal: Allows token holders to vote on active proposals.
//    17. executeProposal: Executes a passed governance proposal.
//    18. updateAIOracleAddress: Sets the trusted address for AI Oracle interactions (governor-only).
//    19. registerAIOracleFeedbackHash: Allows the AI Oracle to post a verifiable hash of its off-chain feedback.
//
// IV. Token Staking & Rewards
//    20. depositNativeTokenForStaking: Users stake DRIN tokens to participate.
//    21. withdrawStakedNativeToken: Allows users to unstake their DRIN tokens.
//    22. claimRewards: Claim accumulated rewards from contributions and validations.
//    23. distributeTopicPayouts: Transfers accumulated topic funding to successful contributors.
//
// V. View & Utility Functions
//    24. getTopicDetails: Retrieves comprehensive details for a research topic.
//    25. getContributionDetails: Retrieves comprehensive details for a contribution.
//    26. getValidatorProfile: Retrieves a validator's profile information.
//    27. getCurrentEpoch: Returns the current operational epoch.
//    28. getTotalStakedTokens: Returns the total amount of DRIN tokens staked in the contract.
//    29. getValidatorPool: Returns a list of active validators.
//
// Total Functions: 29


contract DRIN is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable DRIN_TOKEN; // The native ERC-20 token for staking and rewards

    // --- Configuration Parameters (Governor controlled) ---
    uint256 public minStakeForProposingTopic = 100 ether; // Example: 100 DRIN tokens
    uint256 public minStakeForContributing = 50 ether;
    uint256 public minStakeForValidating = 200 ether;
    uint256 public minReputationForValidating = 100; // Minimum overall reputation score
    uint256 public validationRewardPerScorePoint = 1 ether; // Rewards per point of score, e.g., 1 DRIN per point
    uint224 public proposalVotingPeriod = 3 days;
    uint224 public proposalMinQuorum = 500 ether; // Minimum total stake required to pass a proposal
    uint256 public epochDuration = 7 days; // Duration of one epoch
    uint256 public validatorSelectionCount = 3; // Number of validators selected per contribution

    address public aiOracleAddress; // Trusted address for AI Oracle integration

    // --- Enums ---
    enum TopicStatus { Proposed, Funded, Approved, InProgress, Review, Completed, Cancelled }
    enum ContributionStatus { Submitted, InReview, Approved, Rejected, Challenged }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum CredentialType { ResearchAchievement, ValidationMerit, GovernanceParticipant } // For Soulbound Tokens

    // --- Structs ---

    struct ResearchTopic {
        address proposer;
        string title; // Hashed string for content/metadata IPFS CID
        bytes32 descriptionHash; // IPFS CID or similar (e.g., of a detailed proposal document)
        uint256 fundingGoal;
        uint256 currentFunding;
        TopicStatus status;
        uint256 creationTime;
        uint256 submissionDeadline; // For contributions
        uint256 reviewDeadline;     // For validations
        uint256 proposerStake;      // Stake from the proposer
        address[] contributors;
        uint256[] contributionIds;  // IDs of contributions for this topic
    }

    struct Contribution {
        uint256 topicId;
        address contributor;
        bytes32 contentHash; // IPFS CID of the solution/research output
        ContributionStatus status;
        uint256 submissionTime;
        uint256 contributorStake;   // Stake from the contributor
        uint256 finalScore;         // Aggregated validation score
        address[] assignedValidators; // Validators assigned to review this contribution
        mapping(address => bytes32) validatorFeedbackHashes; // Validator address => their specific hash of review
        mapping(address => int256) validatorScores; // Individual validator scores
        uint256 rewardsClaimable; // Rewards calculated for this contribution
        bool disputed;
    }

    struct ValidatorProfile {
        uint256 stake; // Amount of DRIN token staked
        uint256 lastActivityEpoch; // Last epoch validator performed an action
        uint256 eligibilityScore; // Combination of reputation, stake, and activity
        bool isActive; // True if actively registered and eligible
    }

    struct UserReputation {
        uint256 overallScore; // General reputation, weighted
        uint256 researchScore; // For submitting good research
        uint256 validationScore; // For accurate and timely validations
        uint256 proposalScore; // For proposing good topics/governance proposals
        uint256 stakingScore; // For consistent long-term staking
        uint256 recentActivityScore; // Decay-based, for recent engagement
    }

    struct SoulboundCredential {
        uint256 id;
        address recipient;
        CredentialType credentialType;
        address issuer; // The DRIN contract itself
        uint256 issueTime;
        bytes32 metadataHash; // IPFS CID of the credential details
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        bytes32 proposalHash; // IPFS CID of proposal details
        uint256 submissionTime;
        uint256 votingDeadline;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        bytes callData; // Encoded function call for execution
        address targetContract; // Target contract for execution
        string description;
    }

    // --- Mappings ---
    mapping(uint256 => ResearchTopic) public topics;
    mapping(uint256 => Contribution) public contributions;
    mapping(address => ValidatorProfile) public validatorProfiles;
    mapping(address => UserReputation) public userReputations;
    mapping(address => mapping(uint256 => SoulboundCredential)) public userSoulboundCredentials; // userAddress => credentialId => SBT
    mapping(address => uint256) public stakedTokens; // User's total staked DRIN tokens
    mapping(address => uint256) public pendingRewards; // User's accumulated rewards
    mapping(uint256 => GovernanceProposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // userAddress => proposalId => voted
    mapping(bytes32 => bytes32) public aiOracleFeedback; // contextHash => feedbackHash

    // --- Counters ---
    uint256 private nextTopicId = 1;
    uint256 private nextContributionId = 1;
    uint256 private nextSBCId = 1;
    uint256 private nextProposalId = 1;
    uint256 private totalStaked = 0; // Total DRIN tokens staked in the contract

    // --- Arrays for iteration/lookup ---
    address[] public activeValidators; // List of active validators
    uint256[] public approvedTopics;   // List of topic IDs that are approved for contributions
    uint256[] public activeProposals;  // List of active governance proposal IDs

    // --- Events ---
    event TopicProposed(uint256 indexed topicId, address indexed proposer, uint256 fundingGoal, uint256 submissionDeadline);
    event TopicFunded(uint256 indexed topicId, address indexed funder, uint256 amount, uint256 currentFunding);
    event TopicApproved(uint256 indexed topicId);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed topicId, address indexed contributor);
    event ValidatorRegistered(address indexed validator, uint256 stake);
    event ValidatorDeregistered(address indexed validator);
    event ValidationSubmitted(uint256 indexed contributionId, address indexed validator, int256 score);
    event ContributionEvaluated(uint256 indexed contributionId, uint256 finalScore, ContributionStatus status);
    event ValidationChallenged(uint256 indexed contributionId, address indexed challenger, bytes32 reasonHash);
    event ReputationUpdated(address indexed user, uint256 overallScore, uint256 researchScore, uint256 validationScore);
    event SBCMinted(address indexed recipient, CredentialType indexed credentialType, uint256 indexed sbcId, bytes32 metadataHash);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 proposalHash);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteYes);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIOracleAddressUpdated(address indexed newAddress);
    event AIOracleFeedbackRegistered(bytes32 indexed contextHash, bytes32 indexed feedbackHash);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event TopicPayoutsDistributed(uint256 indexed topicId, uint256 totalAmount);

    // --- Modifiers ---
    modifier onlyGovernor() {
        require(msg.sender == owner(), "DRIN: Only governor can call this function.");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "DRIN: Only AI Oracle can call this function.");
        _;
    }

    modifier topicStatus(uint256 _topicId, TopicStatus _expectedStatus) {
        require(topics[_topicId].status == _expectedStatus, "DRIN: Topic is not in the expected status.");
        _;
    }

    modifier contributionStatus(uint256 _contributionId, ContributionStatus _expectedStatus) {
        require(contributions[_contributionId].status == _expectedStatus, "DRIN: Contribution is not in the expected status.");
        _;
    }

    // --- Constructor ---
    constructor(address _drinTokenAddress) {
        require(_drinTokenAddress != address(0), "DRIN: DRIN token address cannot be zero.");
        DRIN_TOKEN = IERC20(_drinTokenAddress);
    }

    // --- I. Core Platform Operations (Research & Contribution Lifecycle) ---

    /// @notice Allows a user to propose a new research topic. Requires a stake.
    /// @param _title The title of the research topic.
    /// @param _descriptionHash IPFS CID or hash of the detailed topic description.
    /// @param _fundingGoal The target funding amount for this topic in DRIN tokens.
    /// @param _submissionDeadline Timestamp when contribution submissions close.
    /// @param _reviewDeadline Timestamp when validator reviews must be submitted.
    function proposeResearchTopic(
        string calldata _title,
        bytes32 _descriptionHash,
        uint256 _fundingGoal,
        uint256 _submissionDeadline,
        uint256 _reviewDeadline
    ) external nonReentrant {
        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), minStakeForProposingTopic), "DRIN: Token transfer failed for proposal stake.");
        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(minStakeForProposingTopic);
        totalStaked = totalStaked.add(minStakeForProposingTopic);

        uint256 id = nextTopicId++;
        topics[id] = ResearchTopic({
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            status: TopicStatus.Proposed,
            creationTime: block.timestamp,
            submissionDeadline: _submissionDeadline,
            reviewDeadline: _reviewDeadline,
            proposerStake: minStakeForProposingTopic,
            contributors: new address[](0),
            contributionIds: new uint256[](0)
        });

        emit TopicProposed(id, msg.sender, _fundingGoal, _submissionDeadline);
    }

    /// @notice Allows users to contribute funding to a proposed research topic.
    /// @param _topicId The ID of the topic to fund.
    function fundResearchTopic(uint256 _topicId) external payable nonReentrant {
        ResearchTopic storage topic = topics[_topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        require(topic.status == TopicStatus.Proposed || topic.status == TopicStatus.Funded, "DRIN: Topic cannot be funded in its current status.");
        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), msg.value), "DRIN: Token transfer failed for funding.");

        topic.currentFunding = topic.currentFunding.add(msg.value);
        if (topic.currentFunding >= topic.fundingGoal && topic.status == TopicStatus.Proposed) {
            topic.status = TopicStatus.Funded; // Automatically moves to Funded
        }
        emit TopicFunded(_topicId, msg.sender, msg.value, topic.currentFunding);
    }

    /// @notice (Governor-only) Approves a funded topic, making it ready for contributions.
    /// @param _topicId The ID of the topic to approve.
    function approveResearchTopic(uint256 _topicId) external onlyGovernor topicStatus(_topicId, TopicStatus.Funded) {
        ResearchTopic storage topic = topics[_topicId];
        require(topic.currentFunding >= topic.fundingGoal, "DRIN: Topic funding goal not met.");
        topic.status = TopicStatus.Approved;
        approvedTopics.push(_topicId); // Add to list of approved topics for easy lookup
        emit TopicApproved(_topicId);
    }

    /// @notice Submits a research contribution or solution to an approved topic. Requires a stake.
    /// @param _topicId The ID of the topic to contribute to.
    /// @param _contentHash IPFS CID or hash of the contribution content.
    function submitContribution(uint256 _topicId, bytes32 _contentHash) external nonReentrant {
        ResearchTopic storage topic = topics[_topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        require(topic.status == TopicStatus.Approved || topic.status == TopicStatus.InProgress, "DRIN: Topic not open for contributions.");
        require(block.timestamp <= topic.submissionDeadline, "DRIN: Submission deadline has passed.");
        
        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), minStakeForContributing), "DRIN: Token transfer failed for contribution stake.");
        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(minStakeForContributing);
        totalStaked = totalStaked.add(minStakeForContributing);
        topic.totalStakedForTopic = topic.totalStakedForTopic.add(minStakeForContributing);

        uint256 id = nextContributionId++;
        contributions[id] = Contribution({
            topicId: _topicId,
            contributor: msg.sender,
            contentHash: _contentHash,
            status: ContributionStatus.Submitted,
            submissionTime: block.timestamp,
            contributorStake: minStakeForContributing,
            finalScore: 0,
            assignedValidators: new address[](0),
            rewardsClaimable: 0,
            disputed: false
        });

        topic.contributors.push(msg.sender);
        topic.contributionIds.push(id);
        topic.status = TopicStatus.InProgress; // Move topic to InProgress if not already

        _selectValidatorsForContribution(id); // Assign validators immediately

        emit ContributionSubmitted(id, _topicId, msg.sender);
    }

    /// @notice Allows a user to stake DRIN tokens and register as a validator.
    /// @param _stakeAmount The amount of DRIN tokens to stake.
    function registerAsValidator(uint256 _stakeAmount) external nonReentrant {
        require(_stakeAmount >= minStakeForValidating, "DRIN: Insufficient stake for validator registration.");
        require(userReputations[msg.sender].overallScore >= minReputationForValidating, "DRIN: Insufficient reputation to become a validator.");
        require(!validatorProfiles[msg.sender].isActive, "DRIN: Already an active validator.");

        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "DRIN: Token transfer failed for validator stake.");
        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(_stakeAmount);
        totalStaked = totalStaked.add(_stakeAmount);

        validatorProfiles[msg.sender] = ValidatorProfile({
            stake: _stakeAmount,
            lastActivityEpoch: getCurrentEpoch(),
            eligibilityScore: _calculateValidatorEligibility(msg.sender), // Initial eligibility
            isActive: true
        });
        activeValidators.push(msg.sender); // Add to global active validator list

        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    /// @notice Allows an active validator to unstake their tokens and deregister.
    function deregisterAsValidator() external nonReentrant {
        ValidatorProfile storage profile = validatorProfiles[msg.sender];
        require(profile.isActive, "DRIN: Not an active validator.");
        // Add checks here: e.g., ensure no active assigned contributions
        // For simplicity, we allow immediate deregistration here
        
        uint256 amountToUnstake = profile.stake;
        profile.isActive = false;
        profile.stake = 0;

        // Remove from activeValidators array (simple but potentially gas-intensive)
        for (uint i = 0; i < activeValidators.length; i++) {
            if (activeValidators[i] == msg.sender) {
                activeValidators[i] = activeValidators[activeValidators.length - 1];
                activeValidators.pop();
                break;
            }
        }

        stakedTokens[msg.sender] = stakedTokens[msg.sender].sub(amountToUnstake);
        totalStaked = totalStaked.sub(amountToUnstake);
        require(DRIN_TOKEN.transfer(msg.sender, amountToUnstake), "DRIN: Failed to return validator stake.");
        emit ValidatorDeregistered(msg.sender);
    }

    /// @notice Validators submit their review scores and feedback hashes for assigned contributions.
    /// @param _contributionId The ID of the contribution being validated.
    /// @param _score The score given by the validator (e.g., -100 to 100).
    /// @param _feedbackHash IPFS CID or hash of the detailed feedback document.
    function submitValidationOutcome(uint256 _contributionId, int256 _score, bytes32 _feedbackHash) external {
        Contribution storage contribution = contributions[_contributionId];
        ResearchTopic storage topic = topics[contribution.topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        require(contribution.contributor != address(0), "DRIN: Contribution does not exist.");
        require(block.timestamp <= topic.reviewDeadline, "DRIN: Review deadline has passed.");
        require(contribution.status == ContributionStatus.InReview, "DRIN: Contribution not in review state.");

        bool isAssigned = false;
        for (uint i = 0; i < contribution.assignedValidators.length; i++) {
            if (contribution.assignedValidators[i] == msg.sender) {
                isAssigned = true;
                break;
            }
        }
        require(isAssigned, "DRIN: You are not assigned to validate this contribution.");
        require(contribution.validatorScores[msg.sender] == 0, "DRIN: You have already submitted a score for this contribution.");

        contribution.validatorScores[msg.sender] = _score;
        contribution.validatorFeedbackHashes[msg.sender] = _feedbackHash;
        validatorProfiles[msg.sender].lastActivityEpoch = getCurrentEpoch();
        _updateReputation(msg.sender, "validationActivity", 1); // Minor reputation boost for activity

        emit ValidationSubmitted(_contributionId, msg.sender, _score);
    }

    /// @notice Aggregates validator scores, updates reputations, and calculates rewards for a contribution.
    /// @param _contributionId The ID of the contribution to finalize.
    function finalizeContributionEvaluation(uint256 _contributionId) external nonReentrant {
        Contribution storage contribution = contributions[_contributionId];
        ResearchTopic storage topic = topics[contribution.topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        require(contribution.contributor != address(0), "DRIN: Contribution does not exist.");
        require(contribution.status == ContributionStatus.InReview, "DRIN: Contribution not in review state.");
        require(block.timestamp > topic.reviewDeadline, "DRIN: Review deadline not yet passed.");
        
        uint256 totalScore = 0;
        uint256 validatedCount = 0;

        for (uint i = 0; i < contribution.assignedValidators.length; i++) {
            address validator = contribution.assignedValidators[i];
            int256 score = contribution.validatorScores[validator];
            if (score != 0) { // Only count submitted scores
                totalScore = totalScore.add(uint256(score > 0 ? score : 0)); // Only positive scores contribute to overall score
                validatedCount++;
                _updateReputation(validator, "validationAccuracy", uint252(score)); // Update validator's reputation
            } else {
                 _updateReputation(validator, "validationInactivity", 1); // Penalize inactive validators
            }
        }

        require(validatedCount > 0, "DRIN: No validator scores submitted yet.");
        
        // Calculate average positive score
        uint256 averageScore = totalScore.div(validatedCount);
        contribution.finalScore = averageScore;

        // Determine status and rewards
        if (averageScore >= 50) { // Example threshold for approval
            contribution.status = ContributionStatus.Approved;
            uint256 rewardAmount = averageScore.mul(validationRewardPerScorePoint);
            contribution.rewardsClaimable = rewardAmount;
            pendingRewards[contribution.contributor] = pendingRewards[contribution.contributor].add(rewardAmount);
            _updateReputation(contribution.contributor, "researchSuccess", averageScore);
            _mintResearchAchievementSBC(contribution.contributor, keccak256(abi.encodePacked("Research Success for Topic ", contribution.topicId)));
        } else {
            contribution.status = ContributionStatus.Rejected;
            _updateReputation(contribution.contributor, "researchFailure", 1); // Minor penalty for rejected contribution
        }
        
        // Unstake contributor's initial stake if not challenged
        if (!contribution.disputed) {
             _releaseContributorStake(contribution.contributor, contribution.contributorStake);
        }

        emit ContributionEvaluated(_contributionId, contribution.finalScore, contribution.status);

        // If all contributions for the topic are evaluated, consider topic as completed
        bool allContributionsEvaluated = true;
        for(uint i=0; i < topic.contributionIds.length; i++) {
            if(contributions[topic.contributionIds[i]].status == ContributionStatus.Submitted || 
               contributions[topic.contributionIds[i]].status == ContributionStatus.InReview) {
                allContributionsEvaluated = false;
                break;
            }
        }
        if(allContributionsEvaluated) {
            topic.status = TopicStatus.Review; // Topic moves to review before final completion/payout
        }
    }

    /// @notice Allows a contributor to dispute the evaluation of their submission. Requires a stake.
    /// @param _contributionId The ID of the contribution being challenged.
    /// @param _reasonHash IPFS CID or hash of the detailed reason for the challenge.
    function challengeValidationOutcome(uint256 _contributionId, bytes32 _reasonHash) external nonReentrant {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor != address(0), "DRIN: Contribution does not exist.");
        require(msg.sender == contribution.contributor, "DRIN: Only the contributor can challenge.");
        require(contribution.status == ContributionStatus.Approved || contribution.status == ContributionStatus.Rejected, "DRIN: Contribution not in a final evaluation status.");
        require(!contribution.disputed, "DRIN: Contribution evaluation already disputed.");
        
        // Require a stake to challenge (e.g., equivalent to contributor's initial stake)
        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), contribution.contributorStake), "DRIN: Token transfer failed for challenge stake.");
        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(contribution.contributorStake);
        totalStaked = totalStaked.add(contribution.contributorStake);

        contribution.disputed = true;
        contribution.status = ContributionStatus.Challenged;
        
        // Trigger re-evaluation process or move to governance for review
        // For simplicity, we'll mark it as challenged. A governance proposal could be submitted off-chain
        // or a re-evaluation process (e.g., with new validators) could be triggered.
        
        emit ValidationChallenged(_contributionId, msg.sender, _reasonHash);
    }

    /// @notice (Governor-only) Allows manual adjustment of a topic's status.
    /// @param _topicId The ID of the topic.
    /// @param _newStatus The new status to set for the topic.
    function updateTopicStatus(uint256 _topicId, TopicStatus _newStatus) external onlyGovernor {
        ResearchTopic storage topic = topics[_topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        topic.status = _newStatus;
        // Additional logic could be added here for specific status changes, e.g., refund if cancelled.
    }

    // --- II. Reputation & Soulbound Credentials ---

    /// @notice Retrieves a user's current multi-dimensional reputation scores.
    /// @param _user The address of the user.
    /// @return overallScore, researchScore, validationScore, proposalScore, stakingScore, recentActivityScore
    function getUserReputation(address _user) external view returns (uint256 overallScore, uint256 researchScore, uint256 validationScore, uint256 proposalScore, uint256 stakingScore, uint256 recentActivityScore) {
        UserReputation storage rep = userReputations[_user];
        return (rep.overallScore, rep.researchScore, rep.validationScore, rep.proposalScore, rep.stakingScore, rep.recentActivityScore);
    }

    /// @notice (Internal) Awards a Soulbound Token for significant research achievements.
    /// @param _recipient The address to receive the SBC.
    /// @param _metadataHash IPFS CID or hash of the SBC metadata.
    function _mintResearchAchievementSBC(address _recipient, bytes32 _metadataHash) internal {
        uint256 sbcId = nextSBCId++;
        userSoulboundCredentials[_recipient][sbcId] = SoulboundCredential({
            id: sbcId,
            recipient: _recipient,
            credentialType: CredentialType.ResearchAchievement,
            issuer: address(this),
            issueTime: block.timestamp,
            metadataHash: _metadataHash
        });
        emit SBCMinted(_recipient, CredentialType.ResearchAchievement, sbcId, _metadataHash);
    }

    /// @notice (Internal) Awards a Soulbound Token for excellent validation performance.
    /// @param _recipient The address to receive the SBC.
    /// @param _metadataHash IPFS CID or hash of the SBC metadata.
    function _mintValidatorMeritSBC(address _recipient, bytes32 _metadataHash) internal {
        uint256 sbcId = nextSBCId++;
        userSoulboundCredentials[_recipient][sbcId] = SoulboundCredential({
            id: sbcId,
            recipient: _recipient,
            credentialType: CredentialType.ValidationMerit,
            issuer: address(this),
            issueTime: block.timestamp,
            metadataHash: _metadataHash
        });
        emit SBCMinted(_recipient, CredentialType.ValidationMerit, sbcId, _metadataHash);
    }

    /// @notice Retrieves details of a specific Soulbound Token owned by an address.
    /// @param _owner The address of the SBC owner.
    /// @param _credentialId The ID of the SBC.
    /// @return id, recipient, credentialType, issuer, issueTime, metadataHash
    function getSoulboundCredentialDetails(address _owner, uint256 _credentialId) external view returns (uint256 id, address recipient, CredentialType credentialType, address issuer, uint256 issueTime, bytes32 metadataHash) {
        SoulboundCredential storage sbc = userSoulboundCredentials[_owner][_credentialId];
        require(sbc.recipient == _owner, "DRIN: SBC does not exist for this owner and ID.");
        return (sbc.id, sbc.recipient, sbc.credentialType, sbc.issuer, sbc.issueTime, sbc.metadataHash);
    }

    // --- III. Governance & AI Oracle Integration ---

    /// @notice Proposes changes to system parameters or actions, requiring a stake.
    /// @param _proposalHash IPFS CID or hash of the detailed proposal.
    /// @param _callData Encoded function call for the proposed action.
    /// @param _targetContract The address of the contract to call for execution.
    /// @param _description A brief description of the proposal.
    function submitGovernanceProposal(
        bytes32 _proposalHash,
        bytes calldata _callData,
        address _targetContract,
        string calldata _description
    ) external nonReentrant {
        // Require a minimum stake to propose (similar to topic proposal)
        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), minStakeForProposingTopic), "DRIN: Token transfer failed for proposal stake.");
        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(minStakeForProposingTopic);
        totalStaked = totalStaked.add(minStakeForProposingTopic);

        uint256 id = nextProposalId++;
        proposals[id] = GovernanceProposal({
            id: id,
            proposer: msg.sender,
            proposalHash: _proposalHash,
            submissionTime: block.timestamp,
            votingDeadline: block.timestamp.add(proposalVotingPeriod),
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            callData: _callData,
            targetContract: _targetContract,
            description: _description
        });
        activeProposals.push(id);
        _updateReputation(msg.sender, "proposalActivity", 1); // Minor reputation boost

        emit GovernanceProposalSubmitted(id, msg.sender, _proposalHash);
    }

    /// @notice Allows token holders to vote on active governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _voteYes True for a 'Yes' vote, false for 'No'.
    function voteOnProposal(uint256 _proposalId, bool _voteYes) external {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "DRIN: Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "DRIN: Proposal is not in pending status for voting.");
        require(block.timestamp <= proposal.votingDeadline, "DRIN: Voting period has ended.");
        require(!hasVoted[msg.sender][_proposalId], "DRIN: You have already voted on this proposal.");
        require(stakedTokens[msg.sender] > 0, "DRIN: Voter must have staked tokens.");

        hasVoted[msg.sender][_proposalId] = true;
        if (_voteYes) {
            proposal.yesVotes = proposal.yesVotes.add(stakedTokens[msg.sender]);
        } else {
            proposal.noVotes = proposal.noVotes.add(stakedTokens[msg.sender]);
        }
        emit Voted(_proposalId, msg.sender, _voteYes);
    }

    /// @notice Executes a governance proposal that has passed and met its quorum requirements.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "DRIN: Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "DRIN: Proposal is not in pending status.");
        require(block.timestamp > proposal.votingDeadline, "DRIN: Voting period has not ended yet.");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        require(totalVotes >= proposalMinQuorum, "DRIN: Proposal did not meet quorum.");
        require(proposal.yesVotes > proposal.noVotes, "DRIN: Proposal did not pass.");

        proposal.status = ProposalStatus.Approved; // Temporarily mark as approved before execution

        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "DRIN: Proposal execution failed.");

        proposal.status = ProposalStatus.Executed;
        // Optionally refund proposer's stake
        _releaseContributorStake(proposal.proposer, minStakeForProposingTopic);

        // Remove from activeProposals array
        for (uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == _proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }

        emit ProposalExecuted(_proposalId);
    }

    /// @notice (Governor-only) Sets the trusted address for the AI Oracle.
    /// @param _newOracleAddress The new address for the AI Oracle.
    function updateAIOracleAddress(address _newOracleAddress) external onlyGovernor {
        require(_newOracleAddress != address(0), "DRIN: AI Oracle address cannot be zero.");
        aiOracleAddress = _newOracleAddress;
        emit AIOracleAddressUpdated(_newOracleAddress);
    }

    /// @notice Allows the registered AI Oracle to post a verifiable hash of its off-chain feedback.
    /// This feedback can be used by governance or other automated processes.
    /// @param _contextHash A hash identifying the context of the feedback (e.g., topicId, proposalId).
    /// @param _feedbackHash IPFS CID or hash of the detailed AI feedback.
    function registerAIOracleFeedbackHash(bytes32 _contextHash, bytes32 _feedbackHash) external onlyAIOracle {
        aiOracleFeedback[_contextHash] = _feedbackHash;
        emit AIOracleFeedbackRegistered(_contextHash, _feedbackHash);
    }

    // --- IV. Token Staking & Rewards ---

    /// @notice Users deposit the native DRIN ERC-20 token into the contract to participate in staking.
    /// @param _amount The amount of DRIN tokens to stake.
    function depositNativeTokenForStaking(uint256 _amount) external nonReentrant {
        require(_amount > 0, "DRIN: Amount must be greater than zero.");
        require(DRIN_TOKEN.transferFrom(msg.sender, address(this), _amount), "DRIN: Token transfer failed for staking.");
        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);
        _updateReputation(msg.sender, "stakingActivity", _amount); // Reputation for staking
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows users to unstake and withdraw their DRIN tokens.
    /// Subject to cool-down or unbonding periods if active in roles (not implemented for simplicity).
    /// @param _amount The amount of DRIN tokens to unstake.
    function withdrawStakedNativeToken(uint256 _amount) external nonReentrant {
        require(_amount > 0, "DRIN: Amount must be greater than zero.");
        require(stakedTokens[msg.sender] >= _amount, "DRIN: Insufficient staked tokens.");

        // TODO: Add checks for active roles (e.g., if validator, if contributor with active submissions)
        // For simplicity, we allow immediate withdrawal here.
        
        stakedTokens[msg.sender] = stakedTokens[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        require(DRIN_TOKEN.transfer(msg.sender, _amount), "DRIN: Failed to withdraw staked tokens.");
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Allows users to claim their accumulated rewards from successful contributions and accurate validations.
    function claimRewards() external nonReentrant {
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "DRIN: No pending rewards to claim.");

        pendingRewards[msg.sender] = 0;
        require(DRIN_TOKEN.transfer(msg.sender, rewards), "DRIN: Failed to transfer rewards.");
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice (Governor-only or internal trigger) Distributes the collected funding of a completed topic to its successful contributors.
    /// @param _topicId The ID of the topic whose funding is to be distributed.
    function distributeTopicPayouts(uint256 _topicId) external onlyGovernor {
        ResearchTopic storage topic = topics[_topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        require(topic.status == TopicStatus.Review, "DRIN: Topic not ready for payouts.");

        uint256 totalApprovedScore = 0;
        // Sum up all positive final scores from approved contributions
        for (uint i = 0; i < topic.contributionIds.length; i++) {
            Contribution storage contribution = contributions[topic.contributionIds[i]];
            if (contribution.status == ContributionStatus.Approved) {
                totalApprovedScore = totalApprovedScore.add(contribution.finalScore);
            }
        }

        require(totalApprovedScore > 0, "DRIN: No approved contributions with positive scores to distribute funding.");

        uint256 remainingFunding = topic.currentFunding; // Remaining after any potential refunds
        
        for (uint i = 0; i < topic.contributionIds.length; i++) {
            Contribution storage contribution = contributions[topic.contributionIds[i]];
            if (contribution.status == ContributionStatus.Approved) {
                uint256 payout = remainingFunding.mul(contribution.finalScore).div(totalApprovedScore);
                pendingRewards[contribution.contributor] = pendingRewards[contribution.contributor].add(payout);
                topic.currentFunding = topic.currentFunding.sub(payout); // Deduct from topic's remaining funding
            }
        }
        topic.status = TopicStatus.Completed; // Mark topic as completed after payouts
        
        // Refund proposer's stake if topic completed successfully
        _releaseContributorStake(topic.proposer, topic.proposerStake);

        emit TopicPayoutsDistributed(_topicId, remainingFunding);
    }

    // --- V. View & Utility Functions ---

    /// @notice Retrieves comprehensive details for a specific research topic.
    /// @param _topicId The ID of the topic.
    /// @return All fields of the ResearchTopic struct.
    function getTopicDetails(uint256 _topicId) external view returns (
        address proposer,
        string memory title,
        bytes32 descriptionHash,
        uint256 fundingGoal,
        uint256 currentFunding,
        TopicStatus status,
        uint256 creationTime,
        uint256 submissionDeadline,
        uint256 reviewDeadline,
        uint256 proposerStake,
        address[] memory contributors,
        uint256[] memory contributionIds
    ) {
        ResearchTopic storage topic = topics[_topicId];
        require(topic.proposer != address(0), "DRIN: Topic does not exist.");
        return (
            topic.proposer,
            topic.title,
            topic.descriptionHash,
            topic.fundingGoal,
            topic.currentFunding,
            topic.status,
            topic.creationTime,
            topic.submissionDeadline,
            topic.reviewDeadline,
            topic.proposerStake,
            topic.contributors,
            topic.contributionIds
        );
    }

    /// @notice Retrieves comprehensive details for a specific contribution.
    /// @param _contributionId The ID of the contribution.
    /// @return All fields of the Contribution struct (excluding internal mappings).
    function getContributionDetails(uint256 _contributionId) external view returns (
        uint256 topicId,
        address contributor,
        bytes32 contentHash,
        ContributionStatus status,
        uint256 submissionTime,
        uint256 contributorStake,
        uint256 finalScore,
        address[] memory assignedValidators,
        uint256 rewardsClaimable,
        bool disputed
    ) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor != address(0), "DRIN: Contribution does not exist.");
        return (
            contribution.topicId,
            contribution.contributor,
            contribution.contentHash,
            contribution.status,
            contribution.submissionTime,
            contribution.contributorStake,
            contribution.finalScore,
            contribution.assignedValidators,
            contribution.rewardsClaimable,
            contribution.disputed
        );
    }

    /// @notice Retrieves a validator's current profile information.
    /// @param _validator The address of the validator.
    /// @return stake, lastActivityEpoch, eligibilityScore, isActive
    function getValidatorProfile(address _validator) external view returns (uint256 stake, uint256 lastActivityEpoch, uint256 eligibilityScore, bool isActive) {
        ValidatorProfile storage profile = validatorProfiles[_validator];
        return (profile.stake, profile.lastActivityEpoch, profile.eligibilityScore, profile.isActive);
    }

    /// @notice Returns the current operational epoch of the contract.
    /// @return The current epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return block.timestamp.div(epochDuration);
    }

    /// @notice Returns the total amount of DRIN tokens currently staked within the contract.
    /// @return The total staked amount.
    function getTotalStakedTokens() external view returns (uint256) {
        return totalStaked;
    }

    /// @notice Returns a list of addresses of currently active and eligible validators.
    /// @return An array of active validator addresses.
    function getValidatorPool() external view returns (address[] memory) {
        return activeValidators;
    }

    // --- Internal/Private Functions ---

    /// @dev Selects and assigns validators to a new contribution based on eligibility.
    ///      For simplicity, it picks `validatorSelectionCount` eligible validators.
    /// @param _contributionId The ID of the contribution needing validators.
    function _selectValidatorsForContribution(uint256 _contributionId) internal {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor != address(0), "DRIN: Contribution does not exist.");
        
        address[] memory eligibleValidators = new address[](activeValidators.length);
        uint256 eligibleCount = 0;

        // Filter active and eligible validators, excluding the contributor
        for (uint i = 0; i < activeValidators.length; i++) {
            address validatorAddr = activeValidators[i];
            ValidatorProfile storage profile = validatorProfiles[validatorAddr];
            if (profile.isActive && validatorAddr != contribution.contributor && profile.eligibilityScore >= minReputationForValidating) {
                 eligibleValidators[eligibleCount++] = validatorAddr;
            }
        }

        require(eligibleCount >= validatorSelectionCount, "DRIN: Not enough eligible validators available.");

        // Simple selection: pick first `validatorSelectionCount` eligible validators (can be made more sophisticated with sorting/randomness)
        for (uint i = 0; i < validatorSelectionCount; i++) {
            contribution.assignedValidators.push(eligibleValidators[i]);
        }
        contribution.status = ContributionStatus.InReview;
    }

    /// @dev Calculates a validator's eligibility score based on stake, reputation, and activity.
    /// @param _validator The address of the validator.
    /// @return The calculated eligibility score.
    function _calculateValidatorEligibility(address _validator) internal view returns (uint256) {
        UserReputation storage rep = userReputations[_validator];
        ValidatorProfile storage profile = validatorProfiles[_validator];

        // Example weighting: (validationScore * 2) + overallScore + (stake / 100 ether) + (recentActivityScore / 10)
        uint256 score = rep.validationScore.mul(2).add(rep.overallScore);
        score = score.add(profile.stake.div(100 ether)); // Convert stake to points
        score = score.add(rep.recentActivityScore.div(10)); // Add some recent activity

        // Decay eligibility if inactive for many epochs
        if (getCurrentEpoch() > profile.lastActivityEpoch.add(1)) {
            score = score.sub(score.div(10).mul(getCurrentEpoch().sub(profile.lastActivityEpoch).sub(1))); // Penalize for inactivity
            if (score < 0) score = 0;
        }
        return score;
    }

    /// @dev Updates a user's reputation scores based on their actions.
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _type The type of action (e.g., "researchSuccess", "validationAccuracy", "stakingActivity").
    /// @param _value The value associated with the action (e.g., score, amount, 1 for simple activity).
    function _updateReputation(address _user, string memory _type, uint256 _value) internal {
        UserReputation storage rep = userReputations[_user];

        // Decay mechanism (simple: apply decay at the start of each update)
        // More advanced: decay based on last update timestamp
        if (block.timestamp > rep.recentActivityScore.div(100).add(epochDuration)) { // if > 1 epoch since last activity
            rep.recentActivityScore = rep.recentActivityScore.div(2); // Halve recent activity
            rep.overallScore = rep.overallScore.mul(9).div(10); // 10% decay
            rep.researchScore = rep.researchScore.mul(9).div(10);
            rep.validationScore = rep.validationScore.mul(9).div(10);
            rep.proposalScore = rep.proposalScore.mul(9).div(10);
            rep.stakingScore = rep.stakingScore.mul(9).div(10);
        }

        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("researchSuccess"))) {
            rep.researchScore = rep.researchScore.add(_value);
            rep.overallScore = rep.overallScore.add(_value.mul(2)); // Research success boosts overall more
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("researchFailure"))) {
            rep.researchScore = rep.researchScore.sub(_value);
            if (rep.researchScore < 0) rep.researchScore = 0;
            rep.overallScore = rep.overallScore.sub(_value);
            if (rep.overallScore < 0) rep.overallScore = 0;
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("validationAccuracy"))) {
            rep.validationScore = rep.validationScore.add(_value);
            rep.overallScore = rep.overallScore.add(_value.mul(1));
            // Consider minting a merit SBC if validationScore reaches a threshold
            if (rep.validationScore >= 500 && userSoulboundCredentials[_user][0].credentialType != CredentialType.ValidationMerit) { // Simple check for first SBC
                 _mintValidatorMeritSBC(_user, keccak256(abi.encodePacked("Excellent Validator: ", rep.validationScore)));
            }
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("validationInactivity"))) {
            rep.validationScore = rep.validationScore.sub(_value.mul(10)); // Heavier penalty
            if (rep.validationScore < 0) rep.validationScore = 0;
            rep.overallScore = rep.overallScore.sub(_value.mul(5));
            if (rep.overallScore < 0) rep.overallScore = 0;
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("proposalActivity"))) {
            rep.proposalScore = rep.proposalScore.add(_value);
            rep.overallScore = rep.overallScore.add(_value.mul(10));
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("stakingActivity"))) {
            rep.stakingScore = rep.stakingScore.add(_value.div(100 ether)); // Points for stake amount
            rep.overallScore = rep.overallScore.add(_value.div(50 ether));
        }
        
        rep.recentActivityScore = rep.recentActivityScore.add(10); // Boost for any recent activity
        if (rep.overallScore > 10000) rep.overallScore = 10000; // Cap scores
        if (rep.researchScore > 5000) rep.researchScore = 5000;
        if (rep.validationScore > 5000) rep.validationScore = 5000;
        if (rep.proposalScore > 5000) rep.proposalScore = 5000;
        if (rep.stakingScore > 5000) rep.stakingScore = 5000;
        if (rep.recentActivityScore > 1000) rep.recentActivityScore = 1000;

        emit ReputationUpdated(_user, rep.overallScore, rep.researchScore, rep.validationScore);
    }

    /// @dev Releases a staked amount back to the user or adds to pending rewards.
    /// @param _user The address of the user.
    /// @param _amount The amount to release.
    function _releaseContributorStake(address _user, uint256 _amount) internal {
        stakedTokens[_user] = stakedTokens[_user].sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        pendingRewards[_user] = pendingRewards[_user].add(_amount); // Return stake as pending reward
    }
}
```