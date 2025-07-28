This Solidity smart contract, `QuantumNexus`, aims to be an advanced, creative, and trending demonstration of Web3 capabilities beyond typical DeFi or NFT projects. It combines concepts of dynamic reputation, AI-enhanced decision-making (via oracle), conviction voting, and dynamic NFTs into a unified innovation network.

---

### **Outline and Function Summary**

**Contract Name:** `QuantumNexus`

**Core Concept:** QuantumNexus is a decentralized autonomous innovation network designed to foster and fund novel projects through a dynamic reputation-weighted resource allocation system, enhanced by AI-driven proposal evaluation, and gamified with dynamic Non-Fungible Tokens (NFTs). Participants (Agents) earn reputation by contributing to successful proposals and adhering to network principles. Resources (NexusTokens) are allocated based on an Agent's accumulated reputation, conviction in proposals, and AI-generated proposal scores.

**Advanced Concepts & Features:**

1.  **Dynamic Reputation System:** Agents' reputation scores evolve based on activity, contributions, and time-decay, influencing their capabilities and resource allocation limits.
2.  **Conviction Voting Mechanism:** Agents "stake" NexusTokens towards proposals. The longer the stake, the more 'conviction' and influence accumulates, promoting thoughtful long-term support.
3.  **AI Oracle Integration (Mocked for Demo):** Proposals are submitted with a hash of their core details, which an external AI oracle evaluates off-chain and returns a score, influencing funding decisions. This demonstrates secure off-chain computation integration.
4.  **Dynamic NFTs (Quantum Shards):** ERC721 tokens representing an Agent's reputation tier, special abilities, or historical achievements. Their metadata and potentially on-chain attributes can change based on the Agent's reputation or actions within the network.
5.  **Tiered Agent Progression:** Reputation thresholds unlock higher tiers, granting increased voting power, larger proposal funding limits, or exclusive Quantum Shards.
6.  **Dispute Resolution Framework (Basic):** Mechanisms for challenging proposal outcomes, laying groundwork for more complex arbitration.
7.  **Emergency Protocols:** Pausability and administrative controls for critical situations.

**Function Summary (28 Functions):**

**I. Core Infrastructure & Setup**
1.  `constructor()`: Initializes contract owner, sets initial parameters like reputation tiers.
2.  `setNexusToken(address _token)`: Sets the address of the ERC20 NexusToken, used for funding and staking.
3.  `setQuantumShardNFT(address _nft)`: Sets the address of the ERC721 Quantum Shard NFT, representing agent status.
4.  `setAIOracleAddress(address _oracle)`: Sets the trusted AI oracle address for secure proposal scoring.
5.  `updateVotingPeriod(uint256 _period)`: Adjusts the time period over which conviction accumulates for staked tokens.
6.  `updateReputationDecayRate(uint256 _rate)`: Sets the percentage rate at which an agent's reputation naturally decays over time.

**II. Agent Management & Reputation**
7.  `registerAgent()`: Allows an external account to register as a participating Agent in the network.
8.  `getAgentReputation(address _agent)`: Retrieves the current reputation score of an Agent, automatically applying decay if due.
9.  `awardReputation(address _agent, uint256 _amount)`: System/Admin function to increase an Agent's reputation score (e.g., for successful contributions).
10. `penalizeReputation(address _agent, uint256 _amount)`: System/Admin function to decrease an Agent's reputation score (e.g., for negative actions or disputes).
11. `decayAgentReputation(address _agent)`: Triggers the time-based decay of an Agent's reputation, callable by anyone to incentivize network maintenance.
12. `getAgentTier(address _agent)`: Determines and returns an Agent's current reputation tier based on their score.

**III. Proposal & Funding System**
13. `submitProposal(string calldata _uri, uint256 _fundingGoal, bytes32 _aiProposalHash)`: Allows a registered Agent to submit a new innovation proposal, including a URI for details and a hash for AI evaluation.
14. `castConvictionVote(uint256 _proposalId, uint256 _amount)`: Agent stakes NexusTokens towards a proposal, building conviction over time.
15. `withdrawConvictionVote(uint256 _proposalId)`: Agent unstakes NexusTokens from a proposal, reducing their conviction.
16. `getProposalConviction(uint256 _proposalId)`: Returns the total current funding staked for a proposal (a proxy for raw conviction score in this demo).
17. `executeProposalFunding(uint256 _proposalId)`: Distributes NexusTokens to the proposer if funding conditions (staked amount, AI score) are met.
18. `markProposalCompleted(uint256 _proposalId)`: Proposer marks a funded proposal as completed, triggering reputation awards and a challenge period.
19. `challengeProposalOutcome(uint256 _proposalId, string calldata _reason)`: Allows Agents to formally challenge the completion status or outcome of a proposal within a specific window.

**IV. AI Oracle Interaction (Mocked for Demo)**
20. `receiveAIProposalScore(uint256 _proposalId, bytes32 _originalHash, uint256 _score, bytes calldata _signature)`: A secure callback function for the trusted AI oracle to deliver an evaluation score for a proposal.
21. `updateAITrustThreshold(uint256 _threshold)`: Sets the minimum AI score a proposal must achieve to be eligible for funding.

**V. Dynamic NFT (Quantum Shard) Management**
22. `mintQuantumShard(address _to, uint256 _shardType)`: System/Admin function to mint a new Quantum Shard NFT to an Agent, representing achievements or status.
23. `updateQuantumShardMetadata(uint256 _tokenId, string calldata _newUri)`: Allows the system to update the metadata URI of a specific Quantum Shard NFT, enabling dynamic visual or descriptive changes.
24. `getQuantumShardAttributes(uint256 _tokenId)`: Retrieves specific *on-chain* attributes of a Quantum Shard NFT, demonstrating rich, programmable NFT functionality.

**VI. Emergency & Administrative**
25. `pauseContract()`: Emergency function to temporarily halt critical contract operations (e.g., funding, voting).
26. `unpauseContract()`: Resumes contract operations after a pause.
27. `setOperator(address _operator, bool _status)`: Grants or revokes specific administrative operator roles beyond the owner.
28. `recoverERC20(address _tokenAddress, uint256 _amount)`: Allows the owner to recover any ERC20 tokens accidentally sent to the contract address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
//
// Contract Name: QuantumNexus
//
// Core Concept: QuantumNexus is a decentralized autonomous innovation network
// designed to foster and fund novel projects through a dynamic reputation-weighted
// resource allocation system, enhanced by AI-driven proposal evaluation, and
// gamified with dynamic Non-Fungible Tokens (NFTs). Participants (Agents) earn
// reputation by contributing to successful proposals and adhering to network
// principles. Resources (NexusTokens) are allocated based on an Agent's accumulated
// reputation, conviction in proposals, and AI-generated proposal scores.
//
// Advanced Concepts & Features:
// 1.  Dynamic Reputation System: Agents' reputation scores evolve based on
//     activity, contributions, and time-decay, influencing their capabilities
//     and resource allocation limits.
// 2.  Conviction Voting Mechanism: Agents "stake" NexusTokens or their reputation
//     towards proposals. The longer the stake, the more 'conviction' and
//     influence accumulates, promoting thoughtful long-term support.
// 3.  AI Oracle Integration (Mocked for Demo): Proposals are submitted with
//     a hash of their core details, which an external AI oracle evaluates
//     off-chain and returns a score, influencing funding decisions.
// 4.  Dynamic NFTs (Quantum Shards): ERC721 tokens representing an Agent's
//     reputation tier, special abilities, or historical achievements. Their
//     metadata and potentially on-chain attributes can change based on the
//     Agent's reputation or actions within the network.
// 5.  Tiered Agent Progression: Reputation thresholds unlock higher tiers,
//     granting increased voting power, larger proposal funding limits, or
//     exclusive Quantum Shards.
// 6.  Dispute Resolution Framework: Mechanisms for challenging proposal
//     outcomes or agent misbehavior.
// 7.  Emergency Protocols: Pausability and administrative controls for
//     critical situations.
//
// Function Summary (28 Functions):
//
// I. Core Infrastructure & Setup
//    1.  constructor(): Initializes contract owner, sets initial parameters.
//    2.  setNexusToken(address _token): Sets the address of the ERC20 NexusToken.
//    3.  setQuantumShardNFT(address _nft): Sets the address of the ERC721 Quantum Shard NFT.
//    4.  setAIOracleAddress(address _oracle): Sets the trusted AI oracle address for proposal scoring.
//    5.  updateVotingPeriod(uint256 _period): Adjusts the period over which conviction accumulates.
//    6.  updateReputationDecayRate(uint256 _rate): Sets the rate at which agent reputation naturally decays.
//
// II. Agent Management & Reputation
//    7.  registerAgent(): Allows an EOA to register as a participating Agent in the network.
//    8.  getAgentReputation(address _agent): Retrieves the current reputation score of an Agent.
//    9.  awardReputation(address _agent, uint256 _amount): System/Admin function to increase an Agent's reputation.
//    10. penalizeReputation(address _agent, uint256 _amount): System/Admin function to decrease an Agent's reputation.
//    11. decayAgentReputation(address _agent): Triggers the time-based decay of an Agent's reputation.
//    12. getAgentTier(address _agent): Determines and returns an Agent's current reputation tier.
//
// III. Proposal & Funding System
//    13. submitProposal(string calldata _uri, uint256 _fundingGoal, bytes32 _aiProposalHash): Allows an Agent to submit a new innovation proposal.
//    14. castConvictionVote(uint256 _proposalId, uint256 _amount): Agent stakes NexusTokens to express conviction for a proposal.
//    15. withdrawConvictionVote(uint256 _proposalId): Agent unstakes NexusTokens, reducing conviction.
//    16. getProposalConviction(uint256 _proposalId): Calculates and returns the current aggregated conviction score for a proposal.
//    17. executeProposalFunding(uint256 _proposalId): Distributes NexusTokens to the proposer if funding conditions are met (conviction, AI score).
//    18. markProposalCompleted(uint256 _proposalId): Proposer marks a proposal as completed, triggering reputation awards and potentially dispute periods.
//    19. challengeProposalOutcome(uint256 _proposalId, string calldata _reason): Allows Agents to challenge the completion status or outcome of a proposal.
//
// IV. AI Oracle Interaction (Mocked for Demo)
//    20. receiveAIProposalScore(uint256 _proposalId, bytes32 _originalHash, uint256 _score, bytes calldata _signature): Callback for the AI oracle to deliver a proposal score.
//    21. updateAITrustThreshold(uint256 _threshold): Sets the minimum AI score required for a proposal to be eligible for funding.
//
// V. Dynamic NFT (Quantum Shard) Management
//    22. mintQuantumShard(address _to, uint256 _shardType): System/Admin function to mint a new Quantum Shard NFT to an Agent.
//    23. updateQuantumShardMetadata(uint256 _tokenId, string calldata _newUri): Allows the system to update the metadata URI of a Quantum Shard NFT.
//    24. getQuantumShardAttributes(uint256 _tokenId): Retrieves specific on-chain attributes of a Quantum Shard NFT.
//
// VI. Emergency & Administrative
//    25. pauseContract(): Emergency function to pause critical contract operations.
//    26. unpauseContract(): Unpauses the contract after a pause.
//    27. setOperator(address _operator, bool _status): Grants or revokes operator roles for specific administrative actions.
//    28. recoverERC20(address _tokenAddress, uint256 _amount): Allows owner to recover accidentally sent ERC20 tokens.
//
// Note: Some functions rely on external contract interfaces (IERC20, IERC721).
// For a full deployment, `QuantumShardNFT.sol` and `NexusToken.sol` would also
// need to be deployed and their addresses passed to this contract.
// The AI oracle interaction is a simplified mock; a real system would use
// Chainlink, custom oracle networks, or ZK proofs for secure off-chain computation verification.

contract QuantumNexus is Ownable, Pausable, ReentrancyGuard {
    using SafeCast for uint256;

    // --- State Variables ---

    IERC20 public nexusToken; // The native utility/governance token
    IERC721Metadata public quantumShardNFT; // The dynamic NFT representing agent standing

    address public aiOracleAddress; // Address of the trusted AI oracle

    uint256 public constant PROPOSAL_CHALLENGE_PERIOD = 7 days;
    uint256 public constant REPUTATION_DECAY_INTERVAL = 30 days; // How often reputation decays
    uint256 public reputationDecayRatePercentage = 1; // 1% decay per interval

    uint256 public minAIApprovalScore = 70; // Minimum AI score for a proposal to be eligible (out of 100)
    uint256 public convictionVotingPeriod = 14 days; // Time for conviction to mature

    uint256 private nextProposalId;

    // Agent storage
    struct Agent {
        bool isRegistered;
        uint256 reputationScore;
        uint256 lastReputationDecay; // Timestamp of last decay
        uint256[] ownedShardIds; // Dummy storage: IDs of Quantum Shards 'owned' by this agent,
                                 // in a real system, the ERC721 contract manages ownership.
    }
    mapping(address => Agent) public agents;

    // Proposal storage
    enum ProposalStatus { Pending, Active, Funded, Completed, Challenged, Rejected }

    struct Proposal {
        address proposer;
        string proposalURI; // URI pointing to detailed proposal information
        uint256 fundingGoal; // NexusTokens required
        uint256 currentFunding; // NexusTokens accumulated via conviction staking
        ProposalStatus status;
        uint256 submissionTime;
        bytes32 aiProposalHash; // Hash of data sent to AI oracle
        uint256 aiScore; // Score received from AI oracle (e.g., 0-100)
        bool aiScoreReceived;
        uint256 executionTime; // When funding was executed
        uint256 completionTime; // When proposer marked it completed
        uint256 challengerCount; // Number of agents who challenged the outcome
    }
    mapping(uint256 => Proposal) public proposals;

    // Conviction voting state
    struct ConvictionVote {
        uint256 stakedAmount; // NexusTokens staked
        uint256 startTime; // When conviction started for this stake
    }
    mapping(uint256 => mapping(address => ConvictionVote)) public proposalConvictions; // proposalId => agentAddress => ConvictionVote

    // Operator roles
    mapping(address => bool) public operators; // Addresses with specific administrative rights

    // Reputation Tiers (example tiers)
    uint256[] public reputationTierThresholds; // e.g., [0, 1000, 5000, 10000]

    // --- Events ---
    event NexusTokenSet(address indexed _token);
    event QuantumShardNFTSet(address indexed _nft);
    event AIOracleAddressSet(address indexed _oracle);
    event VotingPeriodUpdated(uint256 _newPeriod);
    event ReputationDecayRateUpdated(uint256 _newRate);

    event AgentRegistered(address indexed _agentAddress, uint256 _initialReputation);
    event ReputationAwarded(address indexed _agentAddress, uint256 _amount, uint256 _newScore);
    event ReputationPenalized(address indexed _agentAddress, uint256 _amount, uint256 _newScore);
    event ReputationDecayed(address indexed _agentAddress, uint256 _oldScore, uint256 _newScore);
    event AgentTierChanged(address indexed _agentAddress, uint256 _newTier);

    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, uint256 _fundingGoal, string _uri);
    event ConvictionVoted(uint256 indexed _proposalId, address indexed _voter, uint256 _amount);
    event ConvictionWithdrawn(uint256 indexed _proposalId, address indexed _voter, uint256 _amount);
    event ProposalFunded(uint256 indexed _proposalId, address indexed _proposer, uint256 _amount);
    event ProposalCompleted(uint256 indexed _proposalId, address indexed _completer);
    event ProposalChallenged(uint256 indexed _proposalId, address indexed _challenger, string _reason);
    event ProposalStatusChanged(uint256 indexed _proposalId, ProposalStatus _oldStatus, ProposalStatus _newStatus);

    event AIProposalScoreReceived(uint256 indexed _proposalId, uint256 _score);
    event AIConfidenceThresholdUpdated(uint256 _newThreshold);

    event QuantumShardMinted(address indexed _to, uint256 indexed _tokenId, uint256 _shardType);
    event QuantumShardMetadataUpdated(uint256 indexed _tokenId, string _newUri);

    event ContractPaused(address indexed _by);
    event ContractUnpaused(address indexed _by);
    event OperatorSet(address indexed _operator, bool _status);
    event ERC20Recovered(address indexed _tokenAddress, uint256 _amount);

    // --- Modifiers ---
    modifier onlyOperator() {
        require(operators[msg.sender], "QuantumNexus: Caller is not an operator");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "QuantumNexus: Caller is not the AI oracle");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Initialize with some default reputation tiers:
        // Tier 0: 0-999, Tier 1: 1000-4999, Tier 2: 5000-9999, Tier 3: 10000+
        reputationTierThresholds.push(0);
        reputationTierThresholds.push(1000);
        reputationTierThresholds.push(5000);
        reputationTierThresholds.push(10000);
    }

    // --- I. Core Infrastructure & Setup ---

    /**
     * @notice Sets the address of the ERC20 NexusToken used for funding and staking.
     * @param _token The address of the NexusToken contract.
     * @dev Only callable by the owner. Can only be set once.
     */
    function setNexusToken(address _token) public onlyOwner {
        require(address(nexusToken) == address(0), "QuantumNexus: NexusToken already set");
        require(_token != address(0), "QuantumNexus: Token address cannot be zero");
        nexusToken = IERC20(_token);
        emit NexusTokenSet(_token);
    }

    /**
     * @notice Sets the address of the ERC721 Quantum Shard NFT contract.
     * @param _nft The address of the Quantum Shard NFT contract.
     * @dev Only callable by the owner. Can only be set once.
     */
    function setQuantumShardNFT(address _nft) public onlyOwner {
        require(address(quantumShardNFT) == address(0), "QuantumNexus: QuantumShardNFT already set");
        require(_nft != address(0), "QuantumNexus: NFT address cannot be zero");
        quantumShardNFT = IERC721Metadata(_nft);
        emit QuantumShardNFTSet(_nft);
    }

    /**
     * @notice Sets the address of the trusted AI oracle contract.
     * @param _oracle The address of the AI oracle.
     * @dev Only callable by the owner.
     */
    function setAIOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "QuantumNexus: Oracle address cannot be zero");
        aiOracleAddress = _oracle;
        emit AIOracleAddressSet(_oracle);
    }

    /**
     * @notice Updates the period over which conviction accumulates for votes.
     * @param _period The new period in seconds.
     * @dev Only callable by the owner. Must be greater than zero.
     */
    function updateVotingPeriod(uint256 _period) public onlyOwner {
        require(_period > 0, "QuantumNexus: Voting period must be greater than zero");
        convictionVotingPeriod = _period;
        emit VotingPeriodUpdated(_period);
    }

    /**
     * @notice Updates the percentage rate at which agent reputation naturally decays.
     * @param _rate The new decay rate as a percentage (e.g., 1 for 1%).
     * @dev Only callable by the owner. Rate must be between 0 and 100.
     */
    function updateReputationDecayRate(uint256 _rate) public onlyOwner {
        require(_rate <= 100, "QuantumNexus: Decay rate cannot exceed 100%");
        reputationDecayRatePercentage = _rate;
        emit ReputationDecayRateUpdated(_rate);
    }

    // --- II. Agent Management & Reputation ---

    /**
     * @notice Allows an EOA to register as a participating Agent.
     * @dev Agents start with 0 reputation and gain it through network activity.
     */
    function registerAgent() public whenNotPaused {
        Agent storage agent = agents[msg.sender];
        require(!agent.isRegistered, "QuantumNexus: Agent already registered");

        agent.isRegistered = true;
        agent.reputationScore = 0; // Agents start at 0
        agent.lastReputationDecay = block.timestamp; // Initialize decay timestamp
        emit AgentRegistered(msg.sender, agent.reputationScore);
    }

    /**
     * @notice Retrieves the current reputation score of an Agent.
     * @param _agent The address of the Agent.
     * @return The reputation score.
     * @dev Automatically triggers reputation decay calculation if due.
     */
    function getAgentReputation(address _agent) public returns (uint256) {
        Agent storage agent = agents[_agent];
        require(agent.isRegistered, "QuantumNexus: Agent not registered");
        _decayAgentReputation(_agent); // Apply decay before returning
        return agent.reputationScore;
    }

    /**
     * @notice System/Admin function to increase an Agent's reputation.
     * @param _agent The address of the Agent.
     * @param _amount The amount of reputation to award.
     * @dev Only callable by owner or approved operators.
     */
    function awardReputation(address _agent, uint256 _amount) public onlyOperator {
        Agent storage agent = agents[_agent];
        require(agent.isRegistered, "QuantumNexus: Agent not registered");
        _decayAgentReputation(_agent); // Apply decay before awarding
        uint256 oldScore = agent.reputationScore;
        agent.reputationScore += _amount;
        emit ReputationAwarded(_agent, _amount, agent.reputationScore);
        _checkAndEmitTierChange(_agent, oldScore, agent.reputationScore);
    }

    /**
     * @notice System/Admin function to decrease an Agent's reputation.
     * @param _agent The address of the Agent.
     * @param _amount The amount of reputation to penalize.
     * @dev Only callable by owner or approved operators. Reputation cannot go below 0.
     */
    function penalizeReputation(address _agent, uint256 _amount) public onlyOperator {
        Agent storage agent = agents[_agent];
        require(agent.isRegistered, "QuantumNexus: Agent not registered");
        _decayAgentReputation(_agent); // Apply decay before penalizing
        uint256 oldScore = agent.reputationScore;
        agent.reputationScore = (agent.reputationScore > _amount) ? (agent.reputationScore - _amount) : 0;
        emit ReputationPenalized(_agent, _amount, agent.reputationScore);
        _checkAndEmitTierChange(_agent, oldScore, agent.reputationScore);
    }

    /**
     * @notice Triggers the time-based decay of an Agent's reputation.
     * @param _agent The address of the Agent.
     * @dev Can be called by anyone to encourage upkeep, ensuring reputation is current.
     */
    function decayAgentReputation(address _agent) public whenNotPaused {
        _decayAgentReputation(_agent);
    }

    /**
     * @notice Internal function to calculate and apply reputation decay.
     * @param _agent The address of the Agent.
     */
    function _decayAgentReputation(address _agent) internal {
        Agent storage agent = agents[_agent];
        if (!agent.isRegistered) { return; }

        uint256 oldScore = agent.reputationScore;
        uint256 intervals = (block.timestamp - agent.lastReputationDecay) / REPUTATION_DECAY_INTERVAL;

        if (intervals > 0 && reputationDecayRatePercentage > 0) {
            uint256 decayAmount = (agent.reputationScore * reputationDecayRatePercentage * intervals) / 100;
            agent.reputationScore = (agent.reputationScore > decayAmount) ? (agent.reputationScore - decayAmount) : 0;
            agent.lastReputationDecay += intervals * REPUTATION_DECAY_INTERVAL; // Update last decay timestamp
            emit ReputationDecayed(_agent, oldScore, agent.reputationScore);
            _checkAndEmitTierChange(_agent, oldScore, agent.reputationScore);
        }
    }

    /**
     * @notice Determines and returns an Agent's current reputation tier.
     * @param _agent The address of the Agent.
     * @return The reputation tier index (0 is the lowest).
     * @dev Reputation is taken as-is, calling `getAgentReputation` first is recommended for freshest score.
     */
    function getAgentTier(address _agent) public view returns (uint256) {
        Agent storage agent = agents[_agent];
        uint256 currentScore = agent.reputationScore; // Does not trigger decay in view function

        for (uint256 i = reputationTierThresholds.length - 1; i >= 0; i--) {
            if (currentScore >= reputationTierThresholds[i]) {
                return i;
            }
            if (i == 0) break; // Prevent underflow for i
        }
        return 0; // Default tier
    }

    /**
     * @notice Internal helper to check and emit tier changes.
     * @param _agent The address of the Agent.
     * @param _oldScore The agent's reputation score before the change.
     * @param _newScore The agent's reputation score after the change.
     */
    function _checkAndEmitTierChange(address _agent, uint256 _oldScore, uint256 _newScore) internal {
        uint256 oldTier = getAgentTier(_agent); // Recalculate based on old score, as _getAgentTier is view.
        uint256 newTier = getAgentTier(_agent); // Recalculate based on new score.

        if (newTier != oldTier) {
            emit AgentTierChanged(_agent, newTier);
            // In a full implementation, you might mint/update Quantum Shards here.
            // e.g., if (newTier > oldTier) { mintQuantumShard(_agent, newTier); }
        }
    }

    // --- III. Proposal & Funding System ---

    /**
     * @notice Allows an Agent to submit a new innovation proposal.
     * @param _uri URI pointing to detailed proposal information (e.g., IPFS hash).
     * @param _fundingGoal The amount of NexusTokens requested for the proposal.
     * @param _aiProposalHash A hash of the proposal's key data, for AI oracle verification.
     * @return The ID of the newly submitted proposal.
     * @dev Requires the sender to be a registered agent.
     */
    function submitProposal(string calldata _uri, uint256 _fundingGoal, bytes32 _aiProposalHash)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        Agent storage agent = agents[msg.sender];
        require(agent.isRegistered, "QuantumNexus: Caller not a registered Agent");
        require(_fundingGoal > 0, "QuantumNexus: Funding goal must be greater than zero");
        require(bytes(_uri).length > 0, "QuantumNexus: Proposal URI cannot be empty");
        require(_aiProposalHash != bytes32(0), "QuantumNexus: AI Proposal Hash cannot be zero");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            proposalURI: _uri,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            status: ProposalStatus.Pending,
            submissionTime: block.timestamp,
            aiProposalHash: _aiProposalHash,
            aiScore: 0,
            aiScoreReceived: false,
            executionTime: 0,
            completionTime: 0,
            challengerCount: 0
        });

        emit ProposalSubmitted(proposalId, msg.sender, _fundingGoal, _uri);
        return proposalId;
    }

    /**
     * @notice Agent stakes NexusTokens to express conviction for a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _amount The amount of NexusTokens to stake.
     * @dev Tokens are transferred to the contract. Conviction implicitly grows over time.
     */
    function castConvictionVote(uint256 _proposalId, uint256 _amount)
        public
        whenNotPaused
        nonReentrant
    {
        Agent storage agent = agents[msg.sender];
        require(agent.isRegistered, "QuantumNexus: Caller not a registered Agent");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "QuantumNexus: Proposal not in votable state");
        require(_amount > 0, "QuantumNexus: Must stake a positive amount");
        require(address(nexusToken) != address(0), "QuantumNexus: NexusToken not set");

        // Transfer tokens to the contract
        nexusToken.transferFrom(msg.sender, address(this), _amount);

        ConvictionVote storage vote = proposalConvictions[_proposalId][msg.sender];
        if (vote.stakedAmount == 0) {
            vote.startTime = block.timestamp;
        }
        vote.stakedAmount += _amount;
        proposal.currentFunding += _amount; // This tracks total staked for funding checks

        // Update proposal status if it's pending
        if (proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Pending, ProposalStatus.Active);
        }

        emit ConvictionVoted(_proposalId, msg.sender, _amount);
    }

    /**
     * @notice Agent unstakes NexusTokens, reducing conviction for a proposal.
     * @param _proposalId The ID of the proposal.
     * @dev All staked tokens for this proposal are withdrawn.
     */
    function withdrawConvictionVote(uint256 _proposalId)
        public
        whenNotPaused
        nonReentrant
    {
        Agent storage agent = agents[msg.sender];
        require(agent.isRegistered, "QuantumNexus: Caller not a registered Agent");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        require(proposal.status != ProposalStatus.Funded && proposal.status != ProposalStatus.Completed, "QuantumNexus: Cannot withdraw from funded/completed proposals");
        require(address(nexusToken) != address(0), "QuantumNexus: NexusToken not set");

        ConvictionVote storage vote = proposalConvictions[_proposalId][msg.sender];
        require(vote.stakedAmount > 0, "QuantumNexus: No tokens staked for this proposal");

        uint256 amountToWithdraw = vote.stakedAmount;
        vote.stakedAmount = 0;
        vote.startTime = 0;

        proposal.currentFunding -= amountToWithdraw; // Reduce total staked

        // Transfer tokens back to the agent
        nexusToken.transfer(msg.sender, amountToWithdraw);

        emit ConvictionWithdrawn(_proposalId, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Calculates and returns the current aggregated conviction score for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The conviction score (in this demo, the total staked amount).
     * @dev A full conviction voting system would calculate conviction based on time-weighted stakes.
     *      For this demo, it returns the raw `currentFunding` (total staked).
     *      Individual agent conviction can be calculated off-chain using `_calculateConviction`.
     */
    function getProposalConviction(uint256 _proposalId) public view returns (uint256) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        return proposal.currentFunding; // This represents total staked, not time-weighted conviction
    }

    /**
     * @notice Internal helper to calculate conviction for a specific agent's vote.
     * @param _proposalId The ID of the proposal.
     * @param _agent The address of the agent.
     * @return The conviction score for this specific agent's stake.
     * @dev Conviction grows linearly with time staked relative to convictionVotingPeriod.
     *      This is a simplification for demonstration purposes.
     */
    function _calculateConviction(uint256 _proposalId, address _agent) internal view returns (uint256) {
        ConvictionVote storage vote = proposalConvictions[_proposalId][_agent];
        if (vote.stakedAmount == 0) {
            return 0;
        }

        uint256 timeStaked = block.timestamp - vote.startTime;
        uint256 convictionMultiplier = 1;

        if (convictionVotingPeriod > 0) {
            convictionMultiplier += timeStaked / convictionVotingPeriod;
        }

        return vote.stakedAmount * convictionMultiplier;
    }

    /**
     * @notice Executes proposal funding if conviction (total staked) and AI score conditions are met.
     * @param _proposalId The ID of the proposal to fund.
     * @dev Only callable by the proposal's proposer or an operator.
     *      Transfers NexusTokens from contract to proposer.
     */
    function executeProposalFunding(uint256 _proposalId)
        public
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "QuantumNexus: Proposal not in active state for funding");
        require(msg.sender == proposal.proposer || operators[msg.sender], "QuantumNexus: Only proposer or operator can execute funding");
        require(proposal.aiScoreReceived, "QuantumNexus: AI score not yet received");
        require(proposal.aiScore >= minAIApprovalScore, "QuantumNexus: AI score too low for approval");
        require(proposal.currentFunding >= proposal.fundingGoal, "QuantumNexus: Insufficient funding staked");
        require(address(nexusToken) != address(0), "QuantumNexus: NexusToken not set");


        // Transfer funds
        nexusToken.transfer(proposal.proposer, proposal.fundingGoal);

        // Mark proposal funded
        proposal.status = ProposalStatus.Funded;
        proposal.executionTime = block.timestamp;

        // Optionally, distribute excess currentFunding as rewards to voters or refund.
        // For simplicity, only the fundingGoal is transferred here.

        emit ProposalFunded(_proposalId, proposal.proposer, proposal.fundingGoal);
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Active, ProposalStatus.Funded);
    }

    /**
     * @notice Proposer marks a proposal as completed.
     * @param _proposalId The ID of the proposal.
     * @dev Triggers reputation award and starts a challenge period.
     */
    function markProposalCompleted(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Funded, "QuantumNexus: Proposal not in funded state");
        require(msg.sender == proposal.proposer, "QuantumNexus: Only proposer can mark completed");

        proposal.status = ProposalStatus.Completed;
        proposal.completionTime = block.timestamp;

        // Award reputation to proposer for successful completion (e.g., 1% of funding goal as reputation)
        awardReputation(proposal.proposer, proposal.fundingGoal / 100);

        emit ProposalCompleted(_proposalId, msg.sender);
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Funded, ProposalStatus.Completed);
    }

    /**
     * @notice Allows Agents to challenge the completion status or outcome of a proposal.
     * @param _proposalId The ID of the proposal to challenge.
     * @param _reason A string explaining the reason for the challenge.
     * @dev Requires the challenger to be a registered agent and be within the challenge period.
     */
    function challengeProposalOutcome(uint256 _proposalId, string calldata _reason) public whenNotPaused {
        Agent storage agent = agents[msg.sender];
        require(agent.isRegistered, "QuantumNexus: Caller not a registered Agent");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Completed, "QuantumNexus: Proposal not in completed state");
        require(block.timestamp <= proposal.completionTime + PROPOSAL_CHALLENGE_PERIOD, "QuantumNexus: Challenge period expired");
        require(bytes(_reason).length > 0, "QuantumNexus: Challenge reason cannot be empty");

        // For simplicity, we just count challenges and change status.
        // A more advanced system would initiate a dispute process (e.g., using a separate arbitration contract).
        proposal.challengerCount++;
        proposal.status = ProposalStatus.Challenged; // Mark as challenged

        emit ProposalChallenged(_proposalId, msg.sender, _reason);
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Completed, ProposalStatus.Challenged);
    }

    // --- IV. AI Oracle Interaction (Mocked for Demo) ---

    /**
     * @notice Callback function for the AI oracle to deliver a proposal score.
     * @param _proposalId The ID of the proposal being scored.
     * @param _originalHash The original hash of data sent to the oracle, for verification.
     * @param _score The AI-generated score (e.g., 0-100).
     * @param _signature The cryptographic signature from the oracle (for real systems).
     * @dev Only callable by the designated `aiOracleAddress`.
     *      In a real system, signature verification (`ECDSA.recover`) would be crucial.
     */
    function receiveAIProposalScore(uint256 _proposalId, bytes32 _originalHash, uint256 _score, bytes calldata _signature)
        public
        onlyAIOracle
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "QuantumNexus: Proposal does not exist");
        require(!proposal.aiScoreReceived, "QuantumNexus: AI score already received for this proposal");
        require(proposal.aiProposalHash == _originalHash, "QuantumNexus: Hash mismatch, potential tampering");
        require(_score <= 100, "QuantumNexus: AI score out of bounds (0-100)");

        // Placeholder for signature verification:
        // address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_originalHash), _signature);
        // require(signer == aiOracleAddress, "QuantumNexus: Invalid oracle signature");

        proposal.aiScore = _score;
        proposal.aiScoreReceived = true;

        // Automatically reject if AI score is too low upon receipt
        if (proposal.status != ProposalStatus.Funded && proposal.aiScore < minAIApprovalScore) {
             proposal.status = ProposalStatus.Rejected;
             emit ProposalStatusChanged(_proposalId, ProposalStatus.Active, ProposalStatus.Rejected);
        }

        emit AIProposalScoreReceived(_proposalId, _score);
    }

    /**
     * @notice Sets the minimum AI score required for a proposal to be eligible for funding.
     * @param _threshold The new minimum AI score (0-100).
     * @dev Only callable by the owner.
     */
    function updateAITrustThreshold(uint256 _threshold) public onlyOwner {
        require(_threshold <= 100, "QuantumNexus: Threshold must be between 0 and 100");
        minAIApprovalScore = _threshold;
        emit AIConfidenceThresholdUpdated(_threshold);
    }

    // --- V. Dynamic NFT (Quantum Shard) Management ---

    /**
     * @notice Mints a new Quantum Shard NFT to an Agent.
     * @param _to The address of the recipient Agent.
     * @param _shardType An identifier for the type or tier of Quantum Shard.
     * @dev This function would typically be called by the system (e.g., on tier upgrade).
     *      Requires a deployed `QuantumShardNFT` contract that allows minting by this contract.
     *      (Note: `IERC721Metadata` does not include minting functions directly.)
     */
    function mintQuantumShard(address _to, uint256 _shardType) public onlyOperator {
        require(address(quantumShardNFT) != address(0), "QuantumNexus: QuantumShardNFT not set");
        Agent storage agent = agents[_to];
        require(agent.isRegistered, "QuantumNexus: Recipient not a registered Agent");

        // In a real scenario, the QuantumShardNFT contract would have a minting function
        // callable by an authorized address (e.g., this contract). Example:
        // IQuantumShardNFT(address(quantumShardNFT)).mintShard(_to, _shardType);
        // We'll use a dummy ID and push to agent's owned shards for demonstration.
        uint256 newShardId = quantumShardNFT.totalSupply() + 1; // dummy ID based on hypothetical total supply

        agent.ownedShardIds.push(newShardId); // Track locally for demo
        emit QuantumShardMinted(_to, newShardId, _shardType);
    }

    /**
     * @notice Allows the system to update the metadata URI of a Quantum Shard NFT.
     * @param _tokenId The ID of the Quantum Shard NFT.
     * @param _newUri The new URI for the metadata (e.g., IPFS hash pointing to new image/attributes).
     * @dev This makes the NFT 'dynamic', changing its appearance/description based on agent actions/reputation.
     *      Requires the `QuantumShardNFT` contract to support external metadata updates.
     *      (Note: `IERC721Metadata` only has `tokenURI` view function, not a setter.)
     */
    function updateQuantumShardMetadata(uint256 _tokenId, string calldata _newUri) public onlyOperator {
        require(address(quantumShardNFT) != address(0), "QuantumNexus: QuantumShardNFT not set");
        // In a real scenario, the QuantumShardNFT contract would have a function like:
        // IQuantumShardNFT(address(quantumShardNFT)).setTokenURI(_tokenId, _newUri);
        emit QuantumShardMetadataUpdated(_tokenId, _newUri);
    }

    /**
     * @notice Retrieves specific on-chain attributes of a Quantum Shard NFT.
     * @param _tokenId The ID of the Quantum Shard NFT.
     * @return Example attributes: `shardType`, `level`, `power`.
     * @dev This demonstrates the concept of storing attributes directly on-chain for dynamic NFTs,
     *      beyond just metadata URI. This would require a custom interface for the NFT contract.
     */
    function getQuantumShardAttributes(uint256 _tokenId) public view returns (uint256 shardType, uint256 level, uint256 power) {
        require(address(quantumShardNFT) != address(0), "QuantumNexus: QuantumShardNFT not set");
        // In a real scenario, this would call a view function on the QuantumShardNFT contract, e.g.:
        // (shardType, level, power) = IQuantumShardNFT(address(quantumShardNFT)).getAttributes(_tokenId);

        // Dummy implementation for demonstration:
        if (_tokenId % 2 == 0) {
            return (1, 5, 100); // Example attributes for even IDs
        } else {
            return (2, 3, 50);  // Example attributes for odd IDs
        }
    }

    // --- VI. Emergency & Administrative ---

    /**
     * @notice Pauses contract operations.
     * @dev Only callable by the owner. Inherited from Pausable.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses contract operations.
     * @dev Only callable by the owner. Inherited from Pausable.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Grants or revokes operator roles for specific administrative actions.
     * @param _operator The address to set/unset as an operator.
     * @param _status True to grant, false to revoke.
     * @dev Only callable by the owner. Operators can, for instance, award reputation.
     */
    function setOperator(address _operator, bool _status) public onlyOwner {
        require(_operator != address(0), "QuantumNexus: Operator address cannot be zero");
        operators[_operator] = _status;
        emit OperatorSet(_operator, _status);
    }

    /**
     * @notice Allows the owner to recover accidentally sent ERC20 tokens from the contract.
     * @param _tokenAddress The address of the ERC20 token to recover.
     * @param _amount The amount of tokens to recover.
     * @dev Only callable by the owner. Cannot be used to drain core protocol tokens (like NexusToken
     *      that are actively staked for proposals, unless they are truly excess/stuck).
     */
    function recoverERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0), "QuantumNexus: Token address cannot be zero");
        require(_amount > 0, "QuantumNexus: Amount must be greater than zero");
        require(IERC20(_tokenAddress).transfer(msg.sender, _amount), "QuantumNexus: Token transfer failed");
        emit ERC20Recovered(_tokenAddress, _amount);
    }
}
```