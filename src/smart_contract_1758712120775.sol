Here's a smart contract written in Solidity, incorporating advanced concepts for a decentralized cognitive network. It aims to be creative and distinct from common open-source projects by focusing on reputation-weighted data verification and "cognitive service" provision.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title CognitoNet: A Decentralized Cognitive Network for Verified Information & Predictive Insights
 * @author AI (Developed by a large language model)
 * @notice This contract establishes CognitoNet, a decentralized network where participants (CognitoNodes)
 *         contribute and verify data, offer "cognitive services" (e.g., sentiment analysis, trend prediction),
 *         and earn rewards based on accuracy and consensus. Users can query this network for aggregated,
 *         verified insights and predictions, paying fees in the native $COG token. The system incorporates
 *         a reputation mechanism, staked submissions, and decentralized challenge/arbitration.
 *         It aims to provide a trustless, community-driven oracle for complex, subjective, and predictive data.
 *         All data/outputs are referenced via URIs (e.g., IPFS), keeping on-chain data minimal.
 *         This contract uses advanced concepts like staked economic security, dynamic reputation updates,
 *         reputation-weighted voting for dispute resolution, and a multi-stage challenge process.
 */

// --- OUTLINE ---
// 1.  **Core Structures & State Variables**
//     *   Defines structs for Nodes, Topics, Insight Assertions, Challenges, Cognitive Services, Service Outputs, and Governance Proposals.
//     *   Manages counters for unique IDs and global protocol parameters.
// 2.  **Access Control & Modifiers**
//     *   Utilizes OpenZeppelin's `Ownable` and `Pausable` for administrative control.
//     *   Custom modifiers for `onlyCognitoNode`, `onlyActiveNode`, and `onlyTopicCreator`.
// 3.  **CognitoNode Management**
//     *   Handles node registration, staking/unstaking (with cooldowns), and deregistration, ensuring stake locking for active tasks.
// 4.  **Topic Management**
//     *   Allows creation of new topics for focused data collection, each with specific parameters.
// 5.  **Insight/Assertion Submission & Verification**
//     *   Facilitates submission of data points/insights by nodes with a locked stake.
//     *   Implements a challenge mechanism for insights, followed by reputation-weighted voting and finalization.
// 6.  **Cognitive Service Provision & Output**
//     *   Enables nodes to register and offer specialized "cognitive services" (e.g., AI model outputs, advanced analytics).
//     *   Manages the submission of service outputs, which are also subject to challenges and verification.
// 7.  **Querying & Data Retrieval**
//     *   Allows users to pay COG tokens to query aggregated, verified insights/service outputs for a topic.
//     *   Fees contribute to a reward pool for nodes.
// 8.  **Reputation System**
//     *   Dynamically updates node reputation based on the outcome of challenges (winning/losing).
//     *   Reputation influences voting power in challenges and governance.
// 9.  **Tokenomics & Rewards**
//     *   Manages COG token flow for staking, challenge stakes, rewards, and query fees.
//     *   Nodes can claim accumulated rewards from successful contributions and challenges.
// 10. **Governance & Parameters**
//     *   Implements a simplified DAO-like system where nodes can propose changes to protocol parameters.
//     *   Proposals are voted on by nodes, weighted by reputation, and can be executed by the owner if passed.
// 11. **Internal Helper Functions** (Not explicitly public, but implied for complex logic)

// --- FUNCTION SUMMARY ---

// **I. Core Setup & Management**
// 1.  `constructor(address _initialCogToken)`: Initializes the contract with deployer as owner and the $COG token address. Sets default global protocol parameters.
// 2.  `pauseContract()`: Pauses core contract functionality in emergency situations (owner only).
// 3.  `unpauseContract()`: Unpauses the contract, restoring normal operations (owner only).
// 4.  `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: Allows the contract owner to update global configuration parameters, such as minimum node stake or challenge periods.

// **II. CognitoNode Management**
// 5.  `registerCognitoNode(string memory _metadataURI)`: Registers `msg.sender` as a CognitoNode by transferring a `MIN_NODE_STAKE` of $COG tokens to the contract. Associates a metadata URI.
// 6.  `updateNodeMetadata(string memory _newMetadataURI)`: Allows an active CognitoNode to update their associated metadata URI.
// 7.  `stakeNodeTokens(uint256 _amount)`: Enables an active CognitoNode to increase their total staked $COG tokens.
// 8.  `requestUnstakeNodeTokens(uint256 _amount)`: Initiates a request to unstake a specified `_amount` of $COG tokens from the node's *available* stake, starting a cooldown period.
// 9.  `completeUnstakeNodeTokens()`: Finalizes an unstake request after its cooldown period, transferring the requested tokens back to the node. Updates node status.
// 10. `deregisterCognitoNode()`: Initiates the process for a CognitoNode to fully deregister, requiring all locked stakes to be released and a cooldown period.

// **III. Topic & Insight Management**
// 11. `createTopic(string memory _name, string memory _description, uint256 _minAssertionStake)`: Creates a new public topic for which insights and services can be contributed. Sets a minimum stake for submitting insights to this topic.
// 12. `submitInsightAssertion(uint256 _topicId, string memory _assertionDataURI, uint256 _confidenceScore)`: Allows an active CognitoNode to submit a data point or "insight" for a specific `_topicId`, locking a `_minAssertionStake` amount of their $COG tokens.
// 13. `challengeInsightAssertion(uint256 _insightId, string memory _reasonURI)`: Allows any user to challenge the accuracy of a submitted insight, staking $COG tokens as a bond and providing a reason.
// 14. `voteOnChallenge(uint256 _challengeId, bool _isAccurate)`: Allows active CognitoNodes (excluding challenger/submitter) to vote on an active challenge, determining if the challenged insight/output is accurate (`_isAccurate = true`) or inaccurate (`_isAccurate = false`). Votes are weighted by reputation.
// 15. `finalizeChallenge(uint256 _challengeId)`: Finalizes a challenge after its voting period ends. Distributes the total staked tokens (challenger's + submitter's) based on voting outcome and updates reputations.

// **IV. Cognitive Service Provision & Output**
// 16. `registerCognitiveService(uint256 _topicId, string memory _serviceType, string memory _schemaURI, uint256 _baseFee)`: Allows an active CognitoNode to register a specific cognitive service (e.g., an AI model) for a `_topicId`, providing its type, schema, and base query fee.
// 17. `submitServiceOutput(uint256 _serviceId, string memory _outputURI)`: Allows a registered cognitive service provider node to submit an output from their service, locking a portion of their stake.
// 18. `challengeServiceOutput(uint256 _serviceOutputId, string memory _reasonURI)`: Allows any user to challenge the validity of a submitted cognitive service output, similar to challenging an insight.

// **V. Querying & Rewards**
// 19. `queryTopicInsights(uint256 _topicId, string memory _queryParametersURI, uint256 _feeAmount)`: Allows users to pay `_feeAmount` in $COG tokens to query for aggregated, verified insights or service outputs related to a specific `_topicId`. Returns a URI to the (assumed off-chain) aggregated result.
// 20. `claimNodeRewards()`: Enables active CognitoNodes to claim their accumulated $COG rewards from successful insight/service submissions, winning challenges, and their share of query fees.

// **VI. Reputation & Status Retrieval**
// 21. `getReputation(address _nodeAddress)`: Returns the current reputation score for a given CognitoNode address.
// 22. `getNodeStatus(address _nodeAddress)`: Provides a detailed view of a CognitoNode's status, including staked amounts, reputation, and pending actions.

// **VII. Governance (Simplified DAO)**
// 23. `proposeProtocolChange(bytes32 _paramName, uint256 _newValue, string memory _proposalURI)`: Allows active CognitoNodes (with sufficient reputation) to propose changes to global protocol parameters, referencing a detailed proposal document via URI.
// 24. `voteOnProposal(uint256 _proposalId, bool _approve)`: Enables active CognitoNodes to vote on a governance proposal, with their vote weight determined by their reputation.
// 25. `executeProposal(uint256 _proposalId)`: Allows the contract owner to execute a governance proposal once its voting period has ended, provided it has passed (more 'for' reputation votes than 'against').

contract CognitoNet is Ownable, Pausable {
    IERC20 public COG_TOKEN;

    // --- Events ---
    event CognitoNodeRegistered(address indexed nodeAddress, uint256 totalStakedAmount, string metadataURI);
    event CognitoNodeStaked(address indexed nodeAddress, uint256 amount);
    event CognitoNodeUnstakeRequested(address indexed nodeAddress, uint256 amount, uint256 unlockTime);
    event CognitoNodeUnstaked(address indexed nodeAddress, uint256 amount);
    event CognitoNodeDeregistered(address indexed nodeAddress);
    event TopicCreated(uint256 indexed topicId, address indexed creator, string name);
    event InsightAssertionSubmitted(uint256 indexed insightId, uint256 indexed topicId, address indexed submitter, uint256 stake);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed targetId, ChallengeTargetType targetType, address indexed challenger, uint256 stake);
    event ChallengeVoteCast(uint256 indexed challengeId, address indexed voter, bool isAccurate);
    event ChallengeFinalized(uint256 indexed challengeId, ChallengeStatus status, uint256 rewardPool);
    event CognitiveServiceRegistered(uint256 indexed serviceId, uint256 indexed topicId, address indexed nodeAddress, string serviceType);
    event ServiceOutputSubmitted(uint256 indexed serviceOutputId, uint256 indexed serviceId, address indexed submitter, uint256 stake);
    event QueryExecuted(uint256 indexed topicId, address indexed querier, uint256 feePaid, string queryParametersURI, string resultURI);
    event NodeRewardsClaimed(address indexed nodeAddress, uint256 amount);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool approve);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Enums ---
    enum NodeStatus { Inactive, Active, UnstakingRequested, Deregistering }
    enum ChallengeTargetType { InsightAssertion, ServiceOutput }
    enum ChallengeStatus { Active, ResolvedAccurate, ResolvedInaccurate, FailedToChallenge }
    enum ProposalStatus { Active, Passed, Rejected, Executed }

    // --- Structs ---
    struct Node {
        string metadataURI;
        uint256 totalStakedAmount; // Total COG tokens the node has staked in the contract
        uint256 lockedStakeAmount; // Portion of totalStakedAmount locked in active submissions/challenges
        uint256 reputation; // Higher is better
        NodeStatus status;
        uint256 unstakeRequestAmount;
        uint256 unstakeUnlockTime; // Timestamp when unstake cooldown ends
        uint256 deregisterUnlockTime; // Timestamp when deregister cooldown ends
        uint256 pendingRewards;
    }

    struct Topic {
        address creator;
        string name;
        string description;
        uint256 minAssertionStake;
        uint256 totalQueryFeesCollected; // Accumulates fees for this topic (for later distribution)
        uint256 insightsCounter; // To track insights for this topic
    }

    struct InsightAssertion {
        uint256 topicId;
        address submitter;
        string assertionDataURI;
        uint256 confidenceScore; // 0-100, indicates submitter's confidence
        uint256 stake; // This is the stake amount locked from the submitter for THIS specific insight
        uint256 challengeId; // 0 if not challenged
        ChallengeStatus status; // Status specific to the insight
    }

    struct Challenge {
        uint256 targetId;             // ID of the InsightAssertion or ServiceOutput being challenged
        ChallengeTargetType targetType; // Type of the target (enum)
        address challenger;
        string reasonURI;
        uint256 challengeStake; // This is the stake amount provided by the challenger
        uint256 votesForInaccurate;   // Raw vote count for the target being INACCURATE
        uint256 votesForAccurate;     // Raw vote count for the target being ACCURATE
        uint256 totalReputationForInaccurate; // Sum of reputation scores for nodes voting INACCURATE
        uint256 totalReputationForAccurate;   // Sum of reputation scores for nodes voting ACCURATE
        mapping(address => bool) hasVoted; // Tracks if a node has voted
        uint256 startTime;
        uint256 endTime;              // When voting period ends
        ChallengeStatus status;
        uint256 rewardPool;           // Total stake (target submitter's stake + challenger's stake)
    }

    struct CognitiveService {
        uint256 topicId;
        address nodeAddress; // The CognitoNode providing this service
        string serviceType; // e.g., "SentimentAnalysis", "TrendPrediction"
        string schemaURI;   // URI to the service's input/output schema
        uint256 baseFee;    // Base fee to query this specific service (in COG)
        bool isActive;
        uint256 outputsCounter; // To track outputs for this service
    }

    struct ServiceOutput {
        uint256 serviceId;
        address submitter;
        string outputURI;
        uint256 stake; // This is the stake amount locked from the submitter for THIS specific output
        uint256 challengeId; // 0 if not challenged
        ChallengeStatus status; // Status specific to the service output
    }

    struct Proposal {
        address proposer;
        bytes32 paramName;
        uint256 newValue;
        string proposalURI;
        uint256 votesFor; // Raw vote count for the proposal
        uint256 votesAgainst; // Raw vote count against the proposal
        uint256 totalReputationFor; // Weighted reputation votes for the proposal
        uint256 totalReputationAgainst; // Weighted reputation votes against the proposal
        mapping(address => bool) hasVoted; // Tracks if a node has voted
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
    }

    // --- State Variables ---
    uint256 public nextChallengeId = 1;
    uint256 public nextTopicId = 1;
    uint256 public nextInsightId = 1;
    uint256 public nextServiceId = 1;
    uint256 public nextServiceOutputId = 1;
    uint256 public nextProposalId = 1;

    mapping(bytes32 => uint256) public protocolParameters; // Global configurable parameters

    mapping(address => Node) public nodes;
    mapping(uint256 => Topic) public topics;
    mapping(uint256 => InsightAssertion) public insights;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => CognitiveService) public cognitiveServices;
    mapping(uint256 => ServiceOutput) public serviceOutputs;
    mapping(uint256 => Proposal) public proposals;

    // --- Modifiers ---
    modifier onlyCognitoNode() {
        require(nodes[msg.sender].status == NodeStatus.Active, "CognitoNet: Caller is not an active CognitoNode");
        _;
    }

    modifier onlyActiveNode(address _nodeAddress) {
        require(nodes[_nodeAddress].status == NodeStatus.Active, "CognitoNet: Node must be active");
        _;
    }

    modifier onlyTopicCreator(uint256 _topicId) {
        require(topics[_topicId].creator == msg.sender, "CognitoNet: Caller is not the topic creator");
        _;
    }

    constructor(address _initialCogToken) Ownable(msg.sender) {
        require(_initialCogToken != address(0), "CognitoNet: COG token address cannot be zero");
        COG_TOKEN = IERC20(_initialCogToken);

        // Initialize default protocol parameters
        protocolParameters["MIN_NODE_STAKE"] = 10_000 * (10**18); // Example: 10,000 COG (assuming 18 decimals)
        protocolParameters["UNSTAKE_COOLDOWN_PERIOD"] = 7 days;
        protocolParameters["DEREGISTER_COOLDOWN_PERIOD"] = 14 days;
        protocolParameters["CHALLENGE_VOTING_PERIOD"] = 3 days;
        protocolParameters["PROPOSAL_VOTING_PERIOD"] = 7 days;
        protocolParameters["INITIAL_REPUTATION"] = 1000;
        protocolParameters["REPUTATION_CHANGE_FACTOR"] = 100; // How much reputation changes on win/loss
        protocolParameters["QUERY_FEE_SHARE_NODE"] = 70; // 70% of query fees go to nodes
        protocolParameters["QUERY_FEE_SHARE_PROTOCOL"] = 30; // 30% of query fees go to protocol treasury (owner for now)
        protocolParameters["MIN_CHALLENGE_STAKE_FACTOR"] = 1; // 1x target stake for challenge stake
    }

    // --- I. Core Setup & Management ---

    /**
     * @notice Pauses core functionality in emergencies (owner only).
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract (owner only).
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Owner updates global protocol parameters.
     * @param _paramName The name of the parameter to update (e.g., "MIN_NODE_STAKE").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        require(_newValue > 0, "CognitoNet: Parameter value must be greater than zero");
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    // --- II. CognitoNode Management ---

    /**
     * @notice Registers an address as a CognitoNode by staking `MIN_NODE_STAKE` COG tokens.
     * @param _metadataURI URI pointing to node's public profile/metadata (e.g., IPFS hash).
     */
    function registerCognitoNode(string memory _metadataURI) public whenNotPaused {
        require(nodes[msg.sender].status == NodeStatus.Inactive, "CognitoNet: Node already active or pending");
        uint256 minStake = protocolParameters["MIN_NODE_STAKE"];
        require(COG_TOKEN.transferFrom(msg.sender, address(this), minStake), "CognitoNet: COG token transfer failed for stake");

        nodes[msg.sender] = Node({
            metadataURI: _metadataURI,
            totalStakedAmount: minStake,
            lockedStakeAmount: 0,
            reputation: protocolParameters["INITIAL_REPUTATION"],
            status: NodeStatus.Active,
            unstakeRequestAmount: 0,
            unstakeUnlockTime: 0,
            deregisterUnlockTime: 0,
            pendingRewards: 0
        });

        emit CognitoNodeRegistered(msg.sender, minStake, _metadataURI);
    }

    /**
     * @notice Updates a node's associated metadata URI.
     * @param _newMetadataURI The new URI for the node's metadata.
     */
    function updateNodeMetadata(string memory _newMetadataURI) public onlyCognitoNode {
        nodes[msg.sender].metadataURI = _newMetadataURI;
    }

    /**
     * @notice Increases a node's total staked COG tokens.
     * @param _amount The amount of COG tokens to stake.
     */
    function stakeNodeTokens(uint256 _amount) public onlyCognitoNode {
        require(_amount > 0, "CognitoNet: Stake amount must be greater than zero");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), _amount), "CognitoNet: COG token transfer failed for additional stake");
        nodes[msg.sender].totalStakedAmount += _amount;
        emit CognitoNodeStaked(msg.sender, _amount);
    }

    /**
     * @notice Initiates an unstaking request for a specified amount from available stake, starting a cooldown.
     * @param _amount The amount of COG tokens to request unstake.
     */
    function requestUnstakeNodeTokens(uint256 _amount) public onlyCognitoNode {
        require(_amount > 0, "CognitoNet: Unstake amount must be greater than zero");
        Node storage node = nodes[msg.sender];
        require(node.totalStakedAmount - node.lockedStakeAmount >= _amount, "CognitoNet: Insufficient available stake for unstake");
        require(node.unstakeRequestAmount == 0, "CognitoNet: Pending unstake request already exists");

        node.unstakeRequestAmount = _amount;
        node.unstakeUnlockTime = block.timestamp + protocolParameters["UNSTAKE_COOLDOWN_PERIOD"];
        node.status = NodeStatus.UnstakingRequested; // Temporarily change status to reflect pending unstake
        emit CognitoNodeUnstakeRequested(msg.sender, _amount, node.unstakeUnlockTime);
    }

    /**
     * @notice Finalizes an unstake request after the cooldown period, transferring tokens back.
     *         Resets node status if no other pending actions and stake is sufficient.
     */
    function completeUnstakeNodeTokens() public whenNotPaused {
        Node storage node = nodes[msg.sender];
        require(node.unstakeRequestAmount > 0, "CognitoNet: No pending unstake request");
        require(block.timestamp >= node.unstakeUnlockTime, "CognitoNet: Unstake cooldown period not over");

        uint256 amountToUnstake = node.unstakeRequestAmount;
        node.totalStakedAmount -= amountToUnstake;
        node.unstakeRequestAmount = 0;
        node.unstakeUnlockTime = 0;

        require(COG_TOKEN.transfer(msg.sender, amountToUnstake), "CognitoNet: COG token transfer failed for unstake");

        // If no other pending actions, revert to Active status if total stake is still above minimum
        if (node.deregisterUnlockTime == 0 && node.lockedStakeAmount == 0) {
             if (node.totalStakedAmount < protocolParameters["MIN_NODE_STAKE"]) {
                 node.status = NodeStatus.Inactive; // Node becomes inactive if below min stake after unstake
             } else {
                 node.status = NodeStatus.Active;
             }
        }
        emit CognitoNodeUnstaked(msg.sender, amountToUnstake);
    }

    /**
     * @notice Initiates deregistration, removing node status after cooldown and *all* locked stakes are released.
     *         Requires zero locked stake to proceed.
     */
    function deregisterCognitoNode() public onlyCognitoNode {
        Node storage node = nodes[msg.sender];
        require(node.lockedStakeAmount == 0, "CognitoNet: Cannot deregister with locked stake in active submissions/services.");
        require(node.deregisterUnlockTime == 0, "CognitoNet: Pending deregistration already exists");

        node.deregisterUnlockTime = block.timestamp + protocolParameters["DEREGISTER_COOLDOWN_PERIOD"];
        node.status = NodeStatus.Deregistering;
        // After cooldown, if no locked stakes, the node can fully unstake its remaining `totalStakedAmount`.
        // This would require a separate `finalizeDeregistration` call, or allowing `completeUnstakeNodeTokens`
        // to handle the full amount if unstakeRequestAmount is set to totalStakedAmount during deregistration.
        emit CognitoNodeDeregistered(msg.sender); // Event signals intent
    }

    // --- III. Topic & Insight Management ---

    /**
     * @notice Creates a new topic for data collection/prediction.
     * @param _name The name of the topic.
     * @param _description A description of the topic.
     * @param _minAssertionStake Minimum COG tokens required to submit an insight for this topic.
     * @return topicId The ID of the newly created topic.
     */
    function createTopic(string memory _name, string memory _description, uint256 _minAssertionStake) public whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "CognitoNet: Topic name cannot be empty");
        require(_minAssertionStake > 0, "CognitoNet: Min assertion stake must be positive");

        uint256 topicId = nextTopicId++;
        topics[topicId] = Topic({
            creator: msg.sender,
            name: _name,
            description: _description,
            minAssertionStake: _minAssertionStake,
            totalQueryFeesCollected: 0,
            insightsCounter: 0
        });

        emit TopicCreated(topicId, msg.sender, _name);
        return topicId;
    }

    /**
     * @notice Active nodes submit a data point/insight for a topic, locking a portion of their stake.
     * @param _topicId The ID of the topic.
     * @param _assertionDataURI URI pointing to the actual data/insight.
     * @param _confidenceScore Submitter's confidence in the assertion (0-100).
     * @return insightId The ID of the submitted insight.
     */
    function submitInsightAssertion(uint256 _topicId, string memory _assertionDataURI, uint256 _confidenceScore) public onlyCognitoNode whenNotPaused returns (uint256) {
        require(topics[_topicId].creator != address(0), "CognitoNet: Topic does not exist");
        require(_confidenceScore <= 100, "CognitoNet: Confidence score must be 0-100");

        uint256 assertionStake = topics[_topicId].minAssertionStake;
        Node storage node = nodes[msg.sender];
        require(node.totalStakedAmount - node.lockedStakeAmount >= assertionStake, "CognitoNet: Not enough available stake for assertion");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), assertionStake), "CognitoNet: COG token transfer failed for assertion stake");

        node.lockedStakeAmount += assertionStake; // Lock this portion of stake

        uint256 insightId = nextInsightId++;
        insights[insightId] = InsightAssertion({
            topicId: _topicId,
            submitter: msg.sender,
            assertionDataURI: _assertionDataURI,
            confidenceScore: _confidenceScore,
            stake: assertionStake,
            challengeId: 0,
            status: ChallengeStatus.Active // Active means not challenged yet
        });

        emit InsightAssertionSubmitted(insightId, _topicId, msg.sender, assertionStake);
        return insightId;
    }

    /**
     * @notice Any user can challenge the accuracy of an existing insight, staking tokens.
     * @param _insightId The ID of the insight to challenge.
     * @param _reasonURI URI pointing to the reason/evidence for the challenge.
     * @return challengeId The ID of the newly created challenge.
     */
    function challengeInsightAssertion(uint256 _insightId, string memory _reasonURI) public whenNotPaused returns (uint256) {
        InsightAssertion storage insight = insights[_insightId];
        require(insight.submitter != address(0), "CognitoNet: Insight does not exist");
        require(insight.challengeId == 0, "CognitoNet: Insight already under challenge");
        require(insight.submitter != msg.sender, "CognitoNet: Cannot challenge your own insight");

        uint256 challengeStakeAmount = insight.stake * protocolParameters["MIN_CHALLENGE_STAKE_FACTOR"];
        require(COG_TOKEN.transferFrom(msg.sender, address(this), challengeStakeAmount), "CognitoNet: COG token transfer failed for challenge stake");

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            targetId: _insightId,
            targetType: ChallengeTargetType.InsightAssertion,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            challengeStake: challengeStakeAmount,
            votesForInaccurate: 0,
            votesForAccurate: 0,
            totalReputationForInaccurate: 0,
            totalReputationForAccurate: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + protocolParameters["CHALLENGE_VOTING_PERIOD"],
            status: ChallengeStatus.Active,
            rewardPool: insight.stake + challengeStakeAmount // Total potential reward pool
        });

        insight.challengeId = challengeId; // Link insight to challenge
        emit ChallengeInitiated(challengeId, _insightId, ChallengeTargetType.InsightAssertion, msg.sender, challengeStakeAmount);
        return challengeId;
    }

    /**
     * @notice Active nodes vote on whether the challenged target (insight or service output) is accurate or inaccurate.
     *         Votes are weighted by node reputation.
     * @param _challengeId The ID of the challenge.
     * @param _isAccurate True if the voter believes the target is accurate, false otherwise.
     */
    function voteOnChallenge(uint256 _challengeId, bool _isAccurate) public onlyCognitoNode whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "CognitoNet: Challenge not active for voting");
        require(block.timestamp < challenge.endTime, "CognitoNet: Challenge voting period has ended");
        require(!challenge.hasVoted[msg.sender], "CognitoNet: Node has already voted on this challenge");
        require(msg.sender != challenge.challenger, "CognitoNet: Challenger cannot vote on their own challenge");

        address targetSubmitter;
        if (challenge.targetType == ChallengeTargetType.InsightAssertion) {
            targetSubmitter = insights[challenge.targetId].submitter;
        } else if (challenge.targetType == ChallengeTargetType.ServiceOutput) {
            targetSubmitter = serviceOutputs[challenge.targetId].submitter;
        }
        require(msg.sender != targetSubmitter, "CognitoNet: Target submitter cannot vote on their own submission's challenge");

        uint256 voterReputation = nodes[msg.sender].reputation;

        if (_isAccurate) {
            challenge.votesForAccurate++;
            challenge.totalReputationForAccurate += voterReputation;
        } else {
            challenge.votesForInaccurate++;
            challenge.totalReputationForInaccurate += voterReputation;
        }
        challenge.hasVoted[msg.sender] = true;
        emit ChallengeVoteCast(_challengeId, msg.sender, _isAccurate);
    }

    /**
     * @notice Finalizes a challenge based on vote consensus, distributing stakes/rewards and updating reputations.
     *         Can be called by any user after the voting period ends.
     * @param _challengeId The ID of the challenge to finalize.
     */
    function finalizeChallenge(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "CognitoNet: Challenge not active");
        require(block.timestamp >= challenge.endTime, "CognitoNet: Challenge voting period not over");

        address targetSubmitter;
        uint256 targetStake = 0;
        if (challenge.targetType == ChallengeTargetType.InsightAssertion) {
            InsightAssertion storage insight = insights[challenge.targetId];
            targetSubmitter = insight.submitter;
            targetStake = insight.stake;
            insight.challengeId = 0; // Unlink challenge from insight
        } else if (challenge.targetType == ChallengeTargetType.ServiceOutput) {
            ServiceOutput storage serviceOutput = serviceOutputs[challenge.targetId];
            targetSubmitter = serviceOutput.submitter;
            targetStake = serviceOutput.stake;
            serviceOutput.challengeId = 0; // Unlink challenge from service output
        }
        require(targetSubmitter != address(0), "CognitoNet: Target submitter address invalid");
        require(nodes[targetSubmitter].lockedStakeAmount >= targetStake, "CognitoNet: Target submitter's stake already released or incorrect.");

        bool challengerWins = (challenge.totalReputationForInaccurate > challenge.totalReputationForAccurate);

        uint256 reputationChange = protocolParameters["REPUTATION_CHANGE_FACTOR"];

        // Release the submitter's locked stake
        nodes[targetSubmitter].lockedStakeAmount -= targetStake;

        if (challengerWins) {
            challenge.status = ChallengeStatus.ResolvedInaccurate;

            // Challenger wins: Target submitter loses stake and reputation, challenger gains stake and reputation.
            nodes[challenge.challenger].pendingRewards += challenge.rewardPool; // Challenger gets both stakes
            nodes[challenge.challenger].reputation += reputationChange;
            
            nodes[targetSubmitter].reputation = nodes[targetSubmitter].reputation > reputationChange ? nodes[targetSubmitter].reputation - reputationChange : 0;

            // Set the insight/service output status to inaccurate
            if (challenge.targetType == ChallengeTargetType.InsightAssertion) {
                insights[challenge.targetId].status = ChallengeStatus.ResolvedInaccurate;
            } else if (challenge.targetType == ChallengeTargetType.ServiceOutput) {
                serviceOutputs[challenge.targetId].status = ChallengeStatus.ResolvedInaccurate;
            }

        } else {
            challenge.status = ChallengeStatus.ResolvedAccurate;

            // Target submitter wins: Challenger loses stake and reputation, target submitter gains stake and reputation.
            nodes[targetSubmitter].pendingRewards += challenge.rewardPool; // Target submitter gets both stakes
            nodes[targetSubmitter].reputation += reputationChange;
            
            nodes[challenge.challenger].reputation = nodes[challenge.challenger].reputation > reputationChange ? nodes[challenge.challenger].reputation - reputationChange : 0;

            // Set the insight/service output status to accurate
            if (challenge.targetType == ChallengeTargetType.InsightAssertion) {
                insights[challenge.targetId].status = ChallengeStatus.ResolvedAccurate;
            } else if (challenge.targetType == ChallengeTargetType.ServiceOutput) {
                serviceOutputs[challenge.targetId].status = ChallengeStatus.ResolvedAccurate;
            }
        }
        emit ChallengeFinalized(_challengeId, challenge.status, challenge.rewardPool);
    }

    // --- IV. Cognitive Service Provision & Output ---

    /**
     * @notice An active node registers to offer a specific cognitive service for a topic.
     * @param _topicId The ID of the topic for which the service is offered.
     * @param _serviceType A string identifying the type of service (e.g., "SentimentAnalysis").
     * @param _schemaURI URI pointing to the service's input/output schema.
     * @param _baseFee Base fee to query this specific service (in COG).
     * @return serviceId The ID of the registered cognitive service.
     */
    function registerCognitiveService(uint256 _topicId, string memory _serviceType, string memory _schemaURI, uint256 _baseFee) public onlyCognitoNode whenNotPaused returns (uint256) {
        require(topics[_topicId].creator != address(0), "CognitoNet: Topic does not exist");
        require(bytes(_serviceType).length > 0, "CognitoNet: Service type cannot be empty");
        require(_baseFee > 0, "CognitoNet: Base fee must be positive");

        // Could add a minimum stake requirement for registering a service here.

        uint256 serviceId = nextServiceId++;
        cognitiveServices[serviceId] = CognitiveService({
            topicId: _topicId,
            nodeAddress: msg.sender,
            serviceType: _serviceType,
            schemaURI: _schemaURI,
            baseFee: _baseFee,
            isActive: true,
            outputsCounter: 0
        });

        emit CognitiveServiceRegistered(serviceId, _topicId, msg.sender, _serviceType);
        return serviceId;
    }

    /**
     * @notice A registered service node submits the output of a cognitive service, locking a portion of their stake.
     *         This output can then be queried or challenged.
     * @param _serviceId The ID of the cognitive service.
     * @param _outputURI URI pointing to the service's output data.
     * @return serviceOutputId The ID of the submitted service output.
     */
    function submitServiceOutput(uint256 _serviceId, string memory _outputURI) public onlyCognitoNode whenNotPaused returns (uint256) {
        CognitiveService storage service = cognitiveServices[_serviceId];
        require(service.nodeAddress == msg.sender, "CognitoNet: Caller is not the service provider for this service ID");
        require(service.isActive, "CognitoNet: Service is not active");

        // Use the minAssertionStake of the topic as the service output stake
        uint256 outputStake = topics[service.topicId].minAssertionStake;
        Node storage node = nodes[msg.sender];
        require(node.totalStakedAmount - node.lockedStakeAmount >= outputStake, "CognitoNet: Not enough available stake for service output");
        require(COG_TOKEN.transferFrom(msg.sender, address(this), outputStake), "CognitoNet: COG token transfer failed for service output stake");

        node.lockedStakeAmount += outputStake; // Lock this portion of stake

        uint256 serviceOutputId = nextServiceOutputId++;
        serviceOutputs[serviceOutputId] = ServiceOutput({
            serviceId: _serviceId,
            submitter: msg.sender,
            outputURI: _outputURI,
            stake: outputStake,
            challengeId: 0,
            status: ChallengeStatus.Active
        });

        emit ServiceOutputSubmitted(serviceOutputId, _serviceId, msg.sender, outputStake);
        return serviceOutputId;
    }

    /**
     * @notice Challenges a submitted service output, similar to insight challenges.
     * @param _serviceOutputId The ID of the service output to challenge.
     * @param _reasonURI URI pointing to the reason/evidence for the challenge.
     * @return challengeId The ID of the newly created challenge.
     */
    function challengeServiceOutput(uint256 _serviceOutputId, string memory _reasonURI) public whenNotPaused returns (uint256) {
        ServiceOutput storage serviceOutput = serviceOutputs[_serviceOutputId];
        require(serviceOutput.submitter != address(0), "CognitoNet: Service output does not exist");
        require(serviceOutput.challengeId == 0, "CognitoNet: Service output already under challenge");
        require(serviceOutput.submitter != msg.sender, "CognitoNet: Cannot challenge your own service output");

        uint256 challengeStakeAmount = serviceOutput.stake * protocolParameters["MIN_CHALLENGE_STAKE_FACTOR"];
        require(COG_TOKEN.transferFrom(msg.sender, address(this), challengeStakeAmount), "CognitoNet: COG token transfer failed for challenge stake");

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            targetId: _serviceOutputId,
            targetType: ChallengeTargetType.ServiceOutput,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            challengeStake: challengeStakeAmount,
            votesForInaccurate: 0,
            votesForAccurate: 0,
            totalReputationForInaccurate: 0,
            totalReputationForAccurate: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + protocolParameters["CHALLENGE_VOTING_PERIOD"],
            status: ChallengeStatus.Active,
            rewardPool: serviceOutput.stake + challengeStakeAmount
        });

        serviceOutput.challengeId = challengeId;
        emit ChallengeInitiated(challengeId, _serviceOutputId, ChallengeTargetType.ServiceOutput, msg.sender, challengeStakeAmount);
        return challengeId;
    }

    // --- V. Querying & Rewards ---

    /**
     * @notice Users pay `_feeAmount` in COG tokens to query aggregated insights or service outputs for a topic.
     *         The contract assumes an off-chain API service that aggregates recent, validated insights/outputs.
     *         The fee is distributed among contributors and the protocol.
     * @param _topicId The ID of the topic to query.
     * @param _queryParametersURI URI describing the specific query parameters (e.g., date range, sentiment filter).
     * @param _feeAmount The amount of COG tokens to pay for the query.
     * @return resultURI URI pointing to the aggregated query result.
     */
    function queryTopicInsights(uint256 _topicId, string memory _queryParametersURI, uint256 _feeAmount) public whenNotPaused returns (string memory resultURI) {
        Topic storage topic = topics[_topicId];
        require(topic.creator != address(0), "CognitoNet: Topic does not exist");
        require(_feeAmount > 0, "CognitoNet: Query fee must be positive");

        // The user must approve this contract to spend COG tokens beforehand.
        require(COG_TOKEN.transferFrom(msg.sender, address(this), _feeAmount), "CognitoNet: COG token transfer failed for query fee");

        topic.totalQueryFeesCollected += _feeAmount; // Accumulate fees in the topic pool

        // For simplicity, query fees are accumulated in the topic and can be claimed later.
        // A more advanced system would have off-chain logic to attribute fees to specific
        // contributors (nodes) whose validated data or services were used in the query.
        // The protocol share (e.g., protocolParameters["QUERY_FEE_SHARE_PROTOCOL"]) would also be
        // transferred to the owner/treasury, but for this simplified example, it's also accumulated.

        // Placeholder for off-chain aggregation logic:
        // In a real system, the `resultURI` would be provided by an off-chain API service that
        // aggregates insights from active, high-reputation nodes. This contract only records the payment.
        resultURI = "ipfs://Qmbn7J7C7T7R7V7X7Y7Z7A7B7C7D7E7F7G7H7I7J7K7L7M7N7O7P7Q7R7S7T7U7V7W7X7Y7Z7A7B7C7D7E7F7G7H7I7J7K7L7M7N7O7P7Q7R7S7T7U7V7W7X7Y7Z"; // Placeholder

        emit QueryExecuted(_topicId, msg.sender, _feeAmount, _queryParametersURI, resultURI);
        return resultURI;
    }

    /**
     * @notice CognitoNodes claim accumulated rewards from accurate submissions, successful challenges, and potentially query fees.
     *         (The distribution of `totalQueryFeesCollected` to individual nodes' `pendingRewards` is implicitly handled
     *         by an off-chain accounting system that then allows nodes to pull their share here. Alternatively, for
     *         simplicity in this contract, assume `pendingRewards` are updated through winning challenges.)
     */
    function claimNodeRewards() public onlyCognitoNode whenNotPaused {
        Node storage node = nodes[msg.sender];
        uint256 amount = node.pendingRewards;
        require(amount > 0, "CognitoNet: No pending rewards to claim");

        node.pendingRewards = 0;
        require(COG_TOKEN.transfer(msg.sender, amount), "CognitoNet: COG token transfer failed for rewards");

        emit NodeRewardsClaimed(msg.sender, amount);
    }

    // --- VI. Reputation & Status Retrieval ---

    /**
     * @notice Returns the current reputation score of a node.
     * @param _nodeAddress The address of the node.
     * @return The reputation score.
     */
    function getReputation(address _nodeAddress) public view returns (uint256) {
        return nodes[_nodeAddress].reputation;
    }

    /**
     * @notice Returns the detailed status of a CognitoNode, including total and locked stake.
     * @param _nodeAddress The address of the node.
     * @return Node struct containing all details.
     */
    function getNodeStatus(address _nodeAddress) public view returns (Node memory) {
        return nodes[_nodeAddress];
    }

    // --- VII. Governance (Simplified DAO) ---

    /**
     * @notice Active nodes can propose changes to global protocol parameters.
     *         Requires a minimum reputation to propose.
     * @param _paramName The name of the parameter to change.
     * @param _newValue The proposed new value.
     * @param _proposalURI URI pointing to a detailed proposal document.
     * @return proposalId The ID of the created proposal.
     */
    function proposeProtocolChange(bytes32 _paramName, uint256 _newValue, string memory _proposalURI) public onlyCognitoNode whenNotPaused returns (uint256) {
        require(nodes[msg.sender].reputation >= protocolParameters["INITIAL_REPUTATION"], "CognitoNet: Insufficient reputation to propose"); // Example: require min reputation

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            proposalURI: _proposalURI,
            votesFor: 0,
            votesAgainst: 0,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + protocolParameters["PROPOSAL_VOTING_PERIOD"],
            status: ProposalStatus.Active
        });
        emit ProposalCreated(proposalId, msg.sender, _paramName, _newValue);
        return proposalId;
    }

    /**
     * @notice Active nodes vote on active governance proposals, weighted by reputation.
     * @param _proposalId The ID of the proposal.
     * @param _approve True to vote for the proposal, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public onlyCognitoNode whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CognitoNet: Proposal not active for voting");
        require(block.timestamp < proposal.endTime, "CognitoNet: Proposal voting period has ended");
        require(!proposal.hasVoted[msg.sender], "CognitoNet: Node has already voted on this proposal");

        uint256 voterReputation = nodes[msg.sender].reputation;

        if (_approve) {
            proposal.votesFor++;
            proposal.totalReputationFor += voterReputation;
        } else {
            proposal.votesAgainst++;
            proposal.totalReputationAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;
        emit ProposalVoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice The owner executes a passed governance proposal after its voting period.
     *         A proposal passes if `totalReputationFor` > `totalReputationAgainst`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CognitoNet: Proposal is not active or already resolved");
        require(block.timestamp >= proposal.endTime, "CognitoNet: Proposal voting period not over");

        bool passed = (proposal.totalReputationFor > proposal.totalReputationAgainst);

        if (passed) {
            protocolParameters[proposal.paramName] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ProtocolParameterUpdated(proposal.paramName, proposal.newValue);
            emit ProposalExecuted(_proposalId, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalExecuted(_proposalId, false);
        }
    }
}
```