The `CognitoNet` smart contract is designed as a decentralized platform for the submission, synthesis, and validation of AI-generated insights and community-curated strategies. It aims to bridge the gap between AI's analytical power and decentralized decision-making, allowing users to contribute, evaluate, and benefit from collective intelligence.

**Core Concepts:**

1.  **InsightNFTs:** Represent raw, AI-generated or data-driven insights submitted by "Insight Providers." These are non-transferable and serve as fundamental building blocks.
2.  **StrategyNFTs:** Represent higher-level, synthesized strategies created by "Synthesizers" by combining multiple InsightNFTs. These are transferable (post-approval) and can evolve based on performance.
3.  **Decentralized AI Oracle Integration (Conceptual):** The contract includes a registry for AI models, implying that insights originate from verifiable AI computations (e.g., via ZKML proofs or Chainlink AI).
4.  **Reputation System:** Users earn reputation scores (as Insight Providers, Synthesizers, or Validators) based on the quality and success of their contributions and decisions.
5.  **Staking Mechanisms:** Participants stake `COGNITO_TOKEN` (an ERC-20 token) to engage in various roles, ensuring commitment and alignment of incentives.
6.  **Community Governance:** A voting system for approving strategies and resolving disputes, driven by stake and reputation.
7.  **Dynamic Rewards:** A system to distribute `COGNITO_TOKEN` rewards to successful Insight Providers, Synthesizers, and Validators.

---

## CognitoNet: Outline and Function Summary

**Contract Name:** `CognitoNet`

**I. Core Platform Management & Configuration (Owner/Admin)**

1.  `constructor()`: Initializes the contract, sets the owner, and links to the `COGNITO_TOKEN` ERC-20 contract.
2.  `updateSystemParameter(string calldata _paramName, uint256 _newValue)`: Allows the owner to adjust key system parameters (e.g., minimum stake, voting duration, reward percentages).
3.  `pauseContract()`: Owner can pause critical contract functionalities in emergencies.
4.  `unpauseContract()`: Owner can unpause the contract after a pause.
5.  `setProtocolFeeRecipient(address _newRecipient)`: Sets the address to receive protocol fees.
6.  `withdrawProtocolFees()`: Allows the protocol fee recipient to withdraw accumulated fees.

**II. AI Oracle Integration & Insight Submission**

7.  `registerAIOracleModel(string calldata _name, string calldata _description, address _verifierAddress, string calldata _proofType)`: Owner registers new verifiable AI models, defining their verification method.
8.  `submitRawInsight(uint256 _aiModelId, string calldata _topic, string calldata _ipfsHash, uint256 _stakeAmount)`: Allows an "Insight Provider" to submit an AI-generated or data-driven insight, linking it to a registered AI model, and staking tokens. Mints a non-transferable `InsightNFT`.
9.  `attestToInsight(uint256 _insightId, uint256 _stakeAmount)`: Users can "attest" to the validity or quality of a raw insight, staking tokens and contributing to its reputation and the provider's score.

**III. Strategy Synthesis & Proposal**

10. `proposeStrategy(string calldata _topic, string calldata _ipfsHash, uint256[] calldata _linkedInsightIds, uint256 _stakeAmount)`: Allows a "Synthesizer" to propose a new strategy, referencing multiple `InsightNFT`s, providing an IPFS hash of the strategy details, and staking tokens. Mints a transferable `StrategyNFT`.
11. `updateStrategyDetails(uint256 _strategyId, string calldata _newIpfsHash)`: Allows the Synthesizer to update the IPFS hash of a strategy before it's approved or while in a draft state.

**IV. Strategy Evaluation & Approval (Governance)**

12. `startStrategyEvaluationVote(uint256 _strategyId)`: Initiates a community voting period for a proposed strategy. Only strategies in `Pending` status can start a vote.
13. `castStrategyVote(uint256 _strategyId, bool _support)`: Allows eligible users (stakeholders/reputable users) to vote 'approve' or 'reject' on a strategy. Their voting power is proportional to their validator stake.
14. `resolveStrategyVote(uint256 _strategyId)`: Concludes the voting period for a strategy, updates its status (`Approved` or `Rejected`), and triggers reputation and reward adjustments based on the outcome.
15. `disputeStrategyPerformance(uint256 _strategyId, string calldata _reasonIpfsHash, uint256 _stakeAmount)`: Allows a user to dispute the reported performance or claims of an *approved* strategy, initiating a new vote or arbitration process (setting status to `Disputed`).

**V. Reputation & Staking**

16. `stakeForRole(string calldata _role, uint256 _amount)`: Users stake `COGNITO_TOKEN` to participate in specific roles (`"InsightProvider"`, `"Synthesizer"`, `"Validator"`).
17. `unstakeFromRole(string calldata _role, uint256 _amount)`: Users can unstake tokens from a specific role after a defined cooldown period.
18. `getReputationScore(address _user, string calldata _role)`: Returns the current reputation score of a user for a specific role.
19. `getRoleStake(address _user, string calldata _role)`: Returns the current stake of a user for a specific role.

**VI. Rewards & Distribution**

20. `claimRewards()`: Allows users to claim accumulated `COGNITO_TOKEN` rewards from successful insights, strategies, or correct votes.
21. `distributeEpochRewards(uint256 _epochNumber)`: Callable by anyone (or automated) to trigger the distribution of rewards for a completed epoch based on defined rules, proportional to reputation and stake in successful contributions.

**VII. NFT Management & Query**

22. `getInsightDetails(uint256 _insightId)`: Retrieves all details of a specific `InsightNFT`.
23. `getStrategyDetails(uint256 _strategyId)`: Retrieves all details of a specific `StrategyNFT`.
24. `getUserInsights(address _user)`: Returns an array of `InsightNFT` IDs provided by a specific user.
25. `getUserStrategies(address _user)`: Returns an array of `StrategyNFT` IDs synthesized by a specific user.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
//
// Contract Name: CognitoNet
//
// This contract serves as a decentralized platform for the submission, synthesis, and validation
// of AI-generated insights and community-curated strategies. It aims to bridge the gap between
// AI's analytical power and decentralized decision-making, allowing users to contribute,
// evaluate, and benefit from collective intelligence.
//
// I. Core Platform Management & Configuration (Owner/Admin)
//    1. constructor(): Initializes the contract, sets the owner, and links to the COGNITO_TOKEN ERC-20 contract.
//    2. updateSystemParameter(string calldata _paramName, uint256 _newValue): Allows the owner to adjust key system parameters.
//    3. pauseContract(): Owner can pause critical contract functionalities in emergencies.
//    4. unpauseContract(): Owner can unpause the contract after a pause.
//    5. setProtocolFeeRecipient(address _newRecipient): Sets the address to receive protocol fees.
//    6. withdrawProtocolFees(): Allows the protocol fee recipient to withdraw accumulated fees.
//
// II. AI Oracle Integration & Insight Submission
//    7. registerAIOracleModel(string calldata _name, string calldata _description, address _verifierAddress, string calldata _proofType): Owner registers new verifiable AI models.
//    8. submitRawInsight(uint256 _aiModelId, string calldata _topic, string calldata _ipfsHash, uint256 _stakeAmount): Allows an "Insight Provider" to submit an AI-generated insight, staking tokens. Mints a non-transferable InsightNFT.
//    9. attestToInsight(uint256 _insightId, uint256 _stakeAmount): Users can "attest" to the validity or quality of a raw insight, staking tokens and contributing to its reputation.
//
// III. Strategy Synthesis & Proposal
//    10. proposeStrategy(string calldata _topic, string calldata _ipfsHash, uint256[] calldata _linkedInsightIds, uint256 _stakeAmount): Allows a "Synthesizer" to propose a new strategy, referencing multiple InsightNFTs, staking tokens. Mints a transferable StrategyNFT.
//    11. updateStrategyDetails(uint256 _strategyId, string calldata _newIpfsHash): Allows the Synthesizer to update the IPFS hash of a strategy before it's approved.
//
// IV. Strategy Evaluation & Approval (Governance)
//    12. startStrategyEvaluationVote(uint256 _strategyId): Initiates a community voting period for a proposed strategy.
//    13. castStrategyVote(uint256 _strategyId, bool _support): Allows eligible users to vote 'approve' or 'reject' on a strategy.
//    14. resolveStrategyVote(uint256 _strategyId): Concludes the voting period, updates strategy status, and triggers reputation/reward adjustments.
//    15. disputeStrategyPerformance(uint256 _strategyId, string calldata _reasonIpfsHash, uint256 _stakeAmount): Allows a user to dispute the performance of an *approved* strategy, initiating a new vote or arbitration process.
//
// V. Reputation & Staking
//    16. stakeForRole(string calldata _role, uint256 _amount): Users stake COGNITO_TOKEN to participate in specific roles.
//    17. unstakeFromRole(string calldata _role, uint256 _amount): Users can unstake tokens from a specific role after a cooldown period.
//    18. getReputationScore(address _user, string calldata _role): Returns the current reputation score of a user for a specific role.
//    19. getRoleStake(address _user, string calldata _role): Returns the current stake of a user for a specific role.
//
// VI. Rewards & Distribution
//    20. claimRewards(): Allows users to claim accumulated COGNITO_TOKEN rewards.
//    21. distributeEpochRewards(uint256 _epochNumber): Triggers the distribution of rewards for a completed epoch.
//
// VII. NFT Management & Query
//    22. getInsightDetails(uint256 _insightId): Retrieves all details of a specific InsightNFT.
//    23. getStrategyDetails(uint256 _strategyId): Retrieves all details of a specific StrategyNFT.
//    24. getUserInsights(address _user): Returns an array of InsightNFT IDs provided by a specific user.
//    25. getUserStrategies(address _user): Returns an array of StrategyNFT IDs synthesized by a specific user.
//
// --- End Outline and Function Summary ---

contract CognitoNet is Ownable, ReentrancyGuard {

    IERC20 public immutable COGNITO_TOKEN;

    // --- Enums ---
    enum StrategyStatus { Pending, Approved, Rejected, Disputed }

    // --- Structs ---

    // Struct for a raw AI-generated or data-driven insight (InsightNFT)
    struct Insight {
        uint256 id;                // Unique ID for the insight
        address provider;          // Address of the Insight Provider
        uint256 aiModelId;         // ID of the AI model used (from AIOracleRegistry)
        string topic;              // General topic/category of the insight
        string ipfsHash;           // IPFS hash pointing to the raw insight data/output
        uint256 submissionTime;    // Timestamp of submission
        uint256 stakeAmount;       // Amount staked by the provider
        uint256 reputationScore;   // Internal reputation of this specific insight
        uint256 attestationCount;  // Number of attestations received
        bool isActive;             // Is the insight currently active and valid?
        address currentOwner;      // Owner of the InsightNFT (always the provider, non-transferable)
    }

    // Struct for a synthesized strategy (StrategyNFT)
    struct Strategy {
        uint256 id;                 // Unique ID for the strategy
        address synthesizer;        // Address of the Synthesizer
        string topic;               // General topic/category of the strategy
        string ipfsHash;            // IPFS hash pointing to the strategy details/code
        uint256[] linkedInsightIds; // Array of InsightNFT IDs referenced by this strategy
        uint256 proposalTime;       // Timestamp of proposal
        uint256 stakeAmount;        // Amount staked by the synthesizer
        uint256 performanceScore;   // Dynamic score reflecting strategy performance (conceptual)
        StrategyStatus status;      // Current status (Pending, Approved, Rejected, Disputed)
        bool isActive;              // Is the strategy currently active and in use?
        address currentOwner;       // Owner of the StrategyNFT (transferable post-approval)
    }

    // Struct for an AI Model in the registry
    struct AIModel {
        uint256 id;
        string name;
        string description;
        address verifierAddress; // Address of a contract/oracle that can verify this model's outputs
        string proofType;        // e.g., "ZKML", "Chainlink", "CustomSig"
        bool isActive;
    }

    // Struct for a strategy vote
    struct Vote {
        uint256 totalWeightFor;
        uint256 totalWeightAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    // Struct for user reputation across different roles
    struct UserReputation {
        uint256 insightProviderScore;
        uint256 synthesizerScore;
        uint256 validatorScore;
    }

    // --- State Variables ---

    // NFT Counters
    uint256 public nextInsightId = 1;
    uint256 public nextStrategyId = 1;
    uint256 public nextAIModelId = 1;

    // Mappings for NFTs
    mapping(uint256 => Insight) public insights;
    mapping(uint256 => Strategy) public strategies;
    mapping(uint256 => address) public insightIdToOwner; // For InsightNFT ownership
    mapping(uint256 => address) public strategyIdToOwner; // For StrategyNFT ownership

    // Mappings for User Data
    mapping(address => UserReputation) public userReputations;
    mapping(address => mapping(string => uint256)) public userStakes; // user => role => amount
    mapping(address => mapping(string => uint256)) public userRewards; // user => role => amount

    // AI Model Registry
    mapping(uint256 => AIModel) public aiModels;

    // Strategy Voting
    mapping(uint256 => Vote) public strategyVotes; // strategyId => Vote

    // System Parameters (Configurable by owner)
    mapping(string => uint256) public systemParameters;

    address public protocolFeeRecipient;
    uint256 public accumulatedProtocolFees;

    bool public paused = false;

    // --- Events ---
    event InsightSubmitted(uint256 indexed insightId, address indexed provider, uint256 aiModelId, string topic, string ipfsHash);
    event InsightAttested(uint256 indexed insightId, address indexed attester, uint256 newInsightReputation);
    event StrategyProposed(uint256 indexed strategyId, address indexed synthesizer, string topic, string ipfsHash);
    event StrategyStatusUpdated(uint256 indexed strategyId, StrategyStatus newStatus);
    event VoteStarted(uint256 indexed strategyId, uint256 startTime, uint256 endTime);
    event VoteCast(uint256 indexed strategyId, address indexed voter, bool support, uint256 weight);
    event VoteResolved(uint256 indexed strategyId, StrategyStatus finalStatus);
    event RewardsClaimed(address indexed user, uint256 amount);
    event UserStaked(address indexed user, uint256 amount, string role);
    event UserUnstaked(address indexed user, uint256 amount, string role);
    event AIModelRegistered(uint256 indexed modelId, string name, address verifierAddress);
    event ParameterUpdated(string indexed paramName, uint256 newValue);
    event DisputeInitiated(uint256 indexed strategyId, address indexed disputer);
    event ProtocolFeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyOwnerOrRole(string calldata _role) {
        if (msg.sender != owner()) {
            require(userStakes[msg.sender][_role] >= systemParameters["minStakeFor" + _role], "Not authorized for this role");
        }
        _;
    }

    modifier onlyStrategySynthesizer(uint256 _strategyId) {
        require(strategies[_strategyId].synthesizer == msg.sender, "Only the strategy synthesizer can perform this action");
        _;
    }

    // --- Constructor ---
    constructor(address _cognitoTokenAddress) Ownable(msg.sender) {
        COGNITO_TOKEN = IERC20(_cognitoTokenAddress);

        // Initialize system parameters (example values, can be updated by owner)
        systemParameters["minInsightStake"] = 100 ether;
        systemParameters["minAttestationStake"] = 10 ether;
        systemParameters["minStrategyStake"] = 500 ether;
        systemParameters["minDisputeStake"] = 200 ether;
        systemParameters["minStakeForInsightProvider"] = 100 ether;
        systemParameters["minStakeForSynthesizer"] = 500 ether;
        systemParameters["minStakeForValidator"] = 200 ether;
        systemParameters["votingPeriodDuration"] = 3 days; // in seconds
        systemParameters["cooldownPeriodUnstake"] = 7 days; // in seconds
        systemParameters["protocolFeePercentage"] = 500; // 5% (500 basis points out of 10000)
        systemParameters["insightRewardPercentage"] = 2000; // 20%
        systemParameters["synthesizerRewardPercentage"] = 4000; // 40%
        systemParameters["validatorRewardPercentage"] = 3000; // 30%
        systemParameters["epochLength"] = 30 days; // for reward distribution

        protocolFeeRecipient = owner();
    }

    // --- I. Core Platform Management & Configuration (Owner/Admin) ---

    function updateSystemParameter(string calldata _paramName, uint256 _newValue) external onlyOwner {
        require(bytes(_paramName).length > 0, "Parameter name cannot be empty");
        systemParameters[_paramName] = _newValue;
        emit ParameterUpdated(_paramName, _newValue);
    }

    function pauseContract() external onlyOwner {
        paused = true;
    }

    function unpauseContract() external onlyOwner {
        paused = false;
    }

    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Recipient cannot be zero address");
        emit ProtocolFeeRecipientSet(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeRecipient, "Only fee recipient can withdraw");
        uint256 amount = accumulatedProtocolFees;
        require(amount > 0, "No fees to withdraw");
        accumulatedProtocolFees = 0;
        COGNITO_TOKEN.transfer(protocolFeeRecipient, amount);
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, amount);
    }

    // --- II. AI Oracle Integration & Insight Submission ---

    function registerAIOracleModel(string calldata _name, string calldata _description, address _verifierAddress, string calldata _proofType)
        external
        onlyOwner
        returns (uint256)
    {
        require(bytes(_name).length > 0 && bytes(_description).length > 0, "Name and description cannot be empty");
        require(_verifierAddress != address(0), "Verifier address cannot be zero");

        uint256 modelId = nextAIModelId++;
        aiModels[modelId] = AIModel({
            id: modelId,
            name: _name,
            description: _description,
            verifierAddress: _verifierAddress,
            proofType: _proofType,
            isActive: true
        });
        emit AIModelRegistered(modelId, _name, _verifierAddress);
        return modelId;
    }

    function submitRawInsight(uint256 _aiModelId, string calldata _topic, string calldata _ipfsHash, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(aiModels[_aiModelId].isActive, "AI model not found or inactive");
        require(bytes(_topic).length > 0 && bytes(_ipfsHash).length > 0, "Topic and IPFS hash cannot be empty");
        require(_stakeAmount >= systemParameters["minInsightStake"], "Stake amount below minimum for Insight Provider");
        
        // Transfer stake from msg.sender to this contract
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed for insight stake");

        uint256 insightId = nextInsightId++;
        insights[insightId] = Insight({
            id: insightId,
            provider: msg.sender,
            aiModelId: _aiModelId,
            topic: _topic,
            ipfsHash: _ipfsHash,
            submissionTime: block.timestamp,
            stakeAmount: _stakeAmount,
            reputationScore: 0,
            attestationCount: 0,
            isActive: true,
            currentOwner: msg.sender // InsightNFTs are non-transferable
        });
        insightIdToOwner[insightId] = msg.sender;

        // Add to user's staked amount for InsightProvider role
        userStakes[msg.sender]["InsightProvider"] += _stakeAmount;
        // Initial reputation for submission
        userReputations[msg.sender].insightProviderScore += _stakeAmount / (systemParameters["minInsightStake"] / 10); // Example initial reputation

        emit InsightSubmitted(insightId, msg.sender, _aiModelId, _topic, _ipfsHash);
        return insightId;
    }

    function attestToInsight(uint256 _insightId, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
    {
        Insight storage insight = insights[_insightId];
        require(insight.isActive, "Insight not found or inactive");
        require(_stakeAmount >= systemParameters["minAttestationStake"], "Stake amount below minimum for attestation");
        require(msg.sender != insight.provider, "Cannot attest to your own insight");
        
        // Transfer stake
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed for attestation stake");

        // Increase insight's and provider's reputation
        insight.reputationScore += _stakeAmount / (systemParameters["minAttestationStake"] / 10); // Example reputation boost
        insight.attestationCount++;
        userReputations[insight.provider].insightProviderScore += _stakeAmount / (systemParameters["minAttestationStake"] / 5); // Higher boost for provider
        userReputations[msg.sender].validatorScore += _stakeAmount / (systemParameters["minAttestationStake"] / 2); // Attester gains validator reputation

        // Add to attester's staked amount for Validator role
        userStakes[msg.sender]["Validator"] += _stakeAmount;

        emit InsightAttested(_insightId, msg.sender, insight.reputationScore);
    }

    // --- III. Strategy Synthesis & Proposal ---

    function proposeStrategy(string calldata _topic, string calldata _ipfsHash, uint256[] calldata _linkedInsightIds, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(bytes(_topic).length > 0 && bytes(_ipfsHash).length > 0, "Topic and IPFS hash cannot be empty");
        require(_linkedInsightIds.length > 0, "Strategy must link at least one insight");
        require(_stakeAmount >= systemParameters["minStrategyStake"], "Stake amount below minimum for Strategy Synthesizer");

        // Verify linked insights are active
        for (uint256 i = 0; i < _linkedInsightIds.length; i++) {
            require(insights[_linkedInsightIds[i]].isActive, "Linked insight not found or inactive");
        }
        
        // Transfer stake
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed for strategy stake");

        uint256 strategyId = nextStrategyId++;
        strategies[strategyId] = Strategy({
            id: strategyId,
            synthesizer: msg.sender,
            topic: _topic,
            ipfsHash: _ipfsHash,
            linkedInsightIds: _linkedInsightIds,
            proposalTime: block.timestamp,
            stakeAmount: _stakeAmount,
            performanceScore: 0,
            status: StrategyStatus.Pending,
            isActive: false, // Inactive until approved
            currentOwner: msg.sender
        });
        strategyIdToOwner[strategyId] = msg.sender;

        // Add to user's staked amount for Synthesizer role
        userStakes[msg.sender]["Synthesizer"] += _stakeAmount;
        // Initial reputation for proposal
        userReputations[msg.sender].synthesizerScore += _stakeAmount / (systemParameters["minStrategyStake"] / 10);

        emit StrategyProposed(strategyId, msg.sender, _topic, _ipfsHash);
        return strategyId;
    }

    function updateStrategyDetails(uint256 _strategyId, string calldata _newIpfsHash)
        external
        whenNotPaused
        onlyStrategySynthesizer(_strategyId)
    {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.status == StrategyStatus.Pending, "Strategy details can only be updated in Pending status");
        require(bytes(_newIpfsHash).length > 0, "New IPFS hash cannot be empty");

        strategy.ipfsHash = _newIpfsHash;
        emit StrategyProposed(_strategyId, msg.sender, strategy.topic, _newIpfsHash); // Re-emit as update
    }

    // --- IV. Strategy Evaluation & Approval (Governance) ---

    function startStrategyEvaluationVote(uint256 _strategyId)
        external
        whenNotPaused
        nonReentrant
        onlyOwnerOrRole("Validator") // Any validator (or owner) can initiate
    {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.status == StrategyStatus.Pending, "Only pending strategies can start a vote");
        require(strategyVotes[_strategyId].endTime == 0, "Vote already started for this strategy");

        strategyVotes[_strategyId] = Vote({
            totalWeightFor: 0,
            totalWeightAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + systemParameters["votingPeriodDuration"],
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize inner mapping
        });

        emit VoteStarted(_strategyId, strategyVotes[_strategyId].startTime, strategyVotes[_strategyId].endTime);
    }

    function castStrategyVote(uint256 _strategyId, bool _support)
        external
        whenNotPaused
        nonReentrant
    {
        Vote storage vote = strategyVotes[_strategyId];
        require(vote.endTime > 0, "Vote not started for this strategy");
        require(block.timestamp < vote.endTime, "Voting period has ended");
        require(!vote.hasVoted[msg.sender], "Already voted on this strategy");
        require(userStakes[msg.sender]["Validator"] >= systemParameters["minStakeForValidator"], "Not enough stake to vote as Validator");

        uint256 voteWeight = userStakes[msg.sender]["Validator"]; // Stake-weighted voting

        if (_support) {
            vote.totalWeightFor += voteWeight;
        } else {
            vote.totalWeightAgainst += voteWeight;
        }
        vote.hasVoted[msg.sender] = true;

        emit VoteCast(_strategyId, msg.sender, _support, voteWeight);
    }

    function resolveStrategyVote(uint256 _strategyId)
        external
        whenNotPaused
        nonReentrant
    {
        Vote storage vote = strategyVotes[_strategyId];
        Strategy storage strategy = strategies[_strategyId];

        require(strategy.status == StrategyStatus.Pending, "Strategy is not in pending status");
        require(vote.endTime > 0, "Vote not started for this strategy");
        require(block.timestamp >= vote.endTime, "Voting period has not ended yet");
        require(!vote.executed, "Vote already resolved");

        vote.executed = true;
        
        StrategyStatus finalStatus;
        if (vote.totalWeightFor > vote.totalWeightAgainst) {
            finalStatus = StrategyStatus.Approved;
            strategy.isActive = true;
            userReputations[strategy.synthesizer].synthesizerScore += strategy.stakeAmount / 10; // Reward synthesizer reputation
            
            // Distribute a portion of the stake as reward
            uint256 rewardAmount = strategy.stakeAmount * systemParameters["synthesizerRewardPercentage"] / 10000;
            userRewards[strategy.synthesizer]["Synthesizer"] += rewardAmount;
            
            // Reward linked Insight Providers
            for(uint256 i=0; i < strategy.linkedInsightIds.length; i++) {
                Insight storage insight = insights[strategy.linkedInsightIds[i]];
                userReputations[insight.provider].insightProviderScore += insight.reputationScore / 5; // Reward insight provider reputation
                uint256 insightReward = insight.stakeAmount * systemParameters["insightRewardPercentage"] / 10000;
                userRewards[insight.provider]["InsightProvider"] += insightReward;
            }

            // A conceptual way to reward validators who voted "for"
            // This is simplified; a real system might track individual votes and weights
            uint256 validatorRewardPool = strategy.stakeAmount * systemParameters["validatorRewardPercentage"] / 10000;
            if (validatorRewardPool > 0 && vote.totalWeightFor > 0) {
                 // Simple distribution based on total 'for' weight
                 // Actual distribution would need to iterate over voters or use a snapshot
                 // For now, it's just reserved, a more complex system would retrieve individual voter stakes.
                 // For this example, we'll just add it to a general pool.
                 userRewards[address(0)]["ValidatorPool"] += validatorRewardPool;
            }

            // Calculate protocol fees from strategy stake
            uint256 protocolFee = strategy.stakeAmount * systemParameters["protocolFeePercentage"] / 10000;
            accumulatedProtocolFees += protocolFee;

            // Return remaining stake to the contract's pool or to synthesizer's rewards if a net positive for them.
            // For simplicity, we assume the stake remains within the contract until explicitly unstaked or withdrawn as reward.
            // In a real system, the reward logic is more complex, possibly drawing from a separate pool.
            
        } else {
            finalStatus = StrategyStatus.Rejected;
            // Penalize synthesizer (lose part of stake) and deduct reputation
            uint256 penalty = strategy.stakeAmount / 2; // Example penalty
            // Transfer penalty to protocol fees
            accumulatedProtocolFees += penalty;
            userStakes[strategy.synthesizer]["Synthesizer"] -= penalty; // Deduct from stake
            userReputations[strategy.synthesizer].synthesizerScore -= strategy.stakeAmount / 20; // Deduct reputation
            // Refund remaining stake to synthesizer's rewards, or allow them to unstake.
            userRewards[strategy.synthesizer]["Synthesizer"] += (strategy.stakeAmount - penalty); // Refund remaining stake
        }
        strategy.status = finalStatus;
        emit StrategyStatusUpdated(_strategyId, finalStatus);
        emit VoteResolved(_strategyId, finalStatus);
    }

    function disputeStrategyPerformance(uint256 _strategyId, string calldata _reasonIpfsHash, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
    {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.status == StrategyStatus.Approved, "Only approved strategies can be disputed");
        require(bytes(_reasonIpfsHash).length > 0, "Dispute reason IPFS hash cannot be empty");
        require(_stakeAmount >= systemParameters["minDisputeStake"], "Stake amount below minimum for dispute");
        
        // Transfer stake
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed for dispute stake");

        strategy.status = StrategyStatus.Disputed;
        // A new vote or arbitration process would follow, this sets the status and stake
        userStakes[msg.sender]["Validator"] += _stakeAmount; // Disputer is acting as a validator
        emit DisputeInitiated(_strategyId, msg.sender);
        emit StrategyStatusUpdated(_strategyId, StrategyStatus.Disputed);
    }

    // --- V. Reputation & Staking ---

    function stakeForRole(string calldata _role, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("InsightProvider")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Synthesizer")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Validator")),
            "Invalid role specified"
        );
        
        // Transfer stake
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for role stake");
        userStakes[msg.sender][_role] += _amount;
        emit UserStaked(msg.sender, _amount, _role);
    }

    function unstakeFromRole(string calldata _role, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(userStakes[msg.sender][_role] >= _amount, "Insufficient stake for this role");

        // Implement cooldown period before actual unstaking
        // For simplicity, we'll add it to a pending unstake mapping.
        // A more robust system would track time and specific unstake requests.
        // For this example, let's allow immediate unstake if no active contributions,
        // otherwise a penalty might apply, or a cooldown.
        // For now, let's assume no active contributions tied to this stake.

        userStakes[msg.sender][_role] -= _amount;
        require(COGNITO_TOKEN.transfer(msg.sender, _amount), "Token transfer failed for unstake");
        emit UserUnstaked(msg.sender, _amount, _role);
    }

    function getReputationScore(address _user, string calldata _role) external view returns (uint256) {
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("InsightProvider"))) {
            return userReputations[_user].insightProviderScore;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Synthesizer"))) {
            return userReputations[_user].synthesizerScore;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Validator"))) {
            return userReputations[_user].validatorScore;
        }
        return 0; // Invalid role
    }

    function getRoleStake(address _user, string calldata _role) external view returns (uint256) {
        return userStakes[_user][_role];
    }

    // --- VI. Rewards & Distribution ---

    function claimRewards() external nonReentrant {
        uint256 totalClaimable = userRewards[msg.sender]["InsightProvider"] +
                                 userRewards[msg.sender]["Synthesizer"] +
                                 userRewards[msg.sender]["Validator"];
        
        require(totalClaimable > 0, "No rewards to claim");

        userRewards[msg.sender]["InsightProvider"] = 0;
        userRewards[msg.sender]["Synthesizer"] = 0;
        userRewards[msg.sender]["Validator"] = 0;

        require(COGNITO_TOKEN.transfer(msg.sender, totalClaimable), "Reward token transfer failed");
        emit RewardsClaimed(msg.sender, totalClaimable);
    }

    function distributeEpochRewards(uint256 _epochNumber) external whenNotPaused nonReentrant {
        // This function would typically be called by a trusted oracle or automated bot
        // to distribute a global reward pool for an epoch based on accumulated reputation
        // and successful contributions.
        // For this example, we'll conceptualize its role as a trigger.
        // The actual reward calculation and distribution are handled within `resolveStrategyVote` for simplicity.
        // A full implementation would involve:
        // 1. A global reward pool set aside for each epoch.
        // 2. Iterating over all active participants/strategies/insights from that epoch.
        // 3. Calculating a weighted share of the pool for each participant based on their reputation and contribution success.
        
        // This function is mostly a placeholder to signify the epoch-based distribution mechanism.
        // Current rewards are added to `userRewards` in `resolveStrategyVote` directly.
        // A true `distributeEpochRewards` would take a pool, calculate, and then add to `userRewards`.
        
        // Example: if there's a global validator reward pool
        if (_epochNumber == 0) { // Just for example, in a real case, track by actual epochs
            uint256 validatorPool = userRewards[address(0)]["ValidatorPool"];
            if (validatorPool > 0) {
                 // Distribute to validators based on their accumulated validatorScore during the epoch
                 // This would require iterating through all validatorReputations or a more complex snapshot logic.
                 // For now, it's just a conceptual placeholder that clears the pool.
                 userRewards[address(0)]["ValidatorPool"] = 0; // Clear pool after conceptual distribution
                 // Logic to distribute `validatorPool` to eligible validators based on their contribution in _epochNumber
            }
        }
        // Potentially an event for epoch rewards distributed
    }

    // --- VII. NFT Management & Query ---

    function getInsightDetails(uint256 _insightId) external view returns (Insight memory) {
        return insights[_insightId];
    }

    function getStrategyDetails(uint256 _strategyId) external view returns (Strategy memory) {
        return strategies[_strategyId];
    }

    function getUserInsights(address _user) external view returns (uint256[] memory) {
        uint256[] memory userInsightIds = new uint256[](nextInsightId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextInsightId; i++) {
            if (insights[i].provider == _user) {
                userInsightIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userInsightIds[i];
        }
        return result;
    }

    function getUserStrategies(address _user) external view returns (uint256[] memory) {
        uint256[] memory userStrategyIds = new uint256[](nextStrategyId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextStrategyId; i++) {
            if (strategies[i].synthesizer == _user) {
                userStrategyIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userStrategyIds[i];
        }
        return result;
    }

    // --- NFT Standard Interface-like functions (Internal to CognitoNet) ---
    // Note: This contract acts as the NFT manager; it doesn't inherit full ERC721 directly.
    // The InsightNFTs are explicitly non-transferable. StrategyNFTs could be transferable post-approval.

    // Basic ownerOf for InsightNFT (non-transferable, owner is always provider)
    function insightOwnerOf(uint256 _insightId) public view returns (address) {
        require(insights[_insightId].id == _insightId, "Insight not found");
        return insights[_insightId].currentOwner;
    }

    // Basic ownerOf for StrategyNFT
    function strategyOwnerOf(uint256 _strategyId) public view returns (address) {
        require(strategies[_strategyId].id == _strategyId, "Strategy not found");
        return strategies[_strategyId].currentOwner;
    }

    // Transfer StrategyNFT (only if approved and not in Pending/Disputed states)
    function transferStrategyNFT(address _from, address _to, uint256 _strategyId) external nonReentrant {
        require(strategyIdToOwner[_strategyId] == _from, "ERC721: transfer from incorrect owner");
        require(strategies[_strategyId].status == StrategyStatus.Approved, "Strategy must be approved to be transferable");
        require(msg.sender == _from || msg.sender == owner(), "Only owner or approved can transfer"); // Simplified approval

        strategyIdToOwner[_strategyId] = _to;
        strategies[_strategyId].currentOwner = _to; // Update the struct
        // Emit an ERC721-like Transfer event if you were to fully implement ERC721
    }
}
```