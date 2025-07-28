This smart contract, `AetherMindNexus`, envisions a decentralized collective intelligence network powered by unique, evolving NFTs called "AetherMind Nodes." These nodes represent autonomous agents whose "cognitive attributes" (e.g., Logic, Intuition, Adaptability) evolve based on their contributions to a shared knowledge base, their participation in decentralized query resolution, and community validation. The system aims to create a self-improving, transparent, and decentralized oracle-like network capable of providing verified data and solutions to complex queries.

---

## Contract Outline & Function Summary

**Contract Name:** `AetherMindNexus`

This contract acts as the central hub for the AetherMind collective intelligence network. It manages the lifecycle and evolution of `AetherMindNode` NFTs, facilitates knowledge contribution and validation, orchestrates decentralized data queries, and implements a governance system for network parameters.

### I. Core Components & Data Structures

*   **AetherMindNode (ERC721 NFT):** Represents an autonomous agent with unique, evolving attributes.
*   **NodeAttributes:** Struct holding mutable cognitive parameters (Logic, Intuition, Adaptability, Reputation, etc.).
*   **KnowledgeFragment:** Struct representing a piece of data or insight contributed by a node.
*   **DataQuery:** Struct defining a request for data or a solution from the network.
*   **QueryResponse:** Struct for a node's proposed solution to a DataQuery.
*   **AMN Token (ERC20):** Assumed to be an external utility token used for staking, rewards, and query fees.

### II. Function Categories

#### A. AetherMindNode (NFT) Management

1.  **`constructor(string memory name, string memory symbol, address _amnTokenAddress)`:**
    *   Initializes the ERC721 token (AetherMindNode) and sets the AMN token address.
2.  **`mintNode()`:**
    *   **Purpose:** Allows a user to mint a new `AetherMindNode` NFT.
    *   **Concept:** Creates a new agent in the network, initializing its attributes.
3.  **`getNodeAttributes(uint256 nodeId)`:**
    *   **Purpose:** Retrieves the current mutable cognitive attributes of a specific AetherMind Node.
    *   **Concept:** Transparency into an agent's current "state" or capabilities.
4.  **`requestNodeDataRefresh(uint256 nodeId)`:**
    *   **Purpose:** Triggers an off-chain metadata refresh for a specific node's NFT, reflecting its latest on-chain attributes.
    *   **Concept:** Ensures dApp frontends and marketplaces display up-to-date node capabilities.
5.  **`setNodeBaseURI(string memory baseURI)`:**
    *   **Purpose:** (Admin/Governance) Sets the base URI for `AetherMindNode` NFT metadata.
    *   **Concept:** Allows updates to where NFT metadata is hosted, or how it's structured.

#### B. Knowledge Contribution & Validation

6.  **`submitKnowledgeFragment(uint256 nodeId, string memory fragmentCid, bytes32 fragmentHash)`:**
    *   **Purpose:** Allows a staked `AetherMindNode` to contribute a piece of "knowledge" (e.g., data, insight, solution) to the network. The actual data is off-chain (CID), hash is on-chain for integrity.
    *   **Concept:** Core mechanism for agents to provide value and earn reputation.
7.  **`validateKnowledgeFragment(uint256 fragmentId, bool isValid)`:**
    *   **Purpose:** Allows other staked `AetherMindNodes` or privileged validators to assess and validate a submitted knowledge fragment.
    *   **Concept:** Peer review and quality control for the collective knowledge base.
8.  **`claimValidationReward(uint256 fragmentId)`:**
    *   **Purpose:** Allows a validator to claim AMN rewards for successfully validated knowledge fragments.
    *   **Concept:** Incentivizes accurate and timely validation.
9.  **`progressTrainingEpoch()`:**
    *   **Purpose:** (Callable by anyone, once per epoch interval) Advances the network's "training epoch." During this, accumulated knowledge fragment validations are processed, and nodes' cognitive attributes are updated.
    *   **Concept:** Simulates a periodic "learning" or "assimilation" phase for the network, where agents' attributes evolve.
10. **`decayNodeAttributes(uint256 nodeId)`:**
    *   **Purpose:** Periodically reduces cognitive attributes of inactive or underperforming nodes, encouraging continuous participation.
    *   **Concept:** Prevents stagnation and rewards active engagement, mimicking natural system decay.

#### C. Decentralized Query Resolution (Oracle-like)

11. **`submitDataQuery(string memory queryCid, bytes32 queryHash, uint256 rewardAmount)`:**
    *   **Purpose:** A user submits a query (e.g., "What is the price of ETH at block X?", "What is the capital of France?") to the network, staking a reward.
    *   **Concept:** Decentralized request for information or problem-solving.
12. **`respondToQuery(uint256 queryId, uint256 nodeId, string memory responseCid, bytes32 responseHash)`:**
    *   **Purpose:** A staked `AetherMindNode` submits its proposed answer to an active query.
    *   **Concept:** Agents compete to provide the best, most accurate solution.
13. **`voteOnQueryResponse(uint256 queryId, uint256 responseIndex, bool isAccurate)`:**
    *   **Purpose:** Other staked `AetherMindNodes` or designated validators vote on the accuracy of submitted query responses.
    *   **Concept:** Community consensus mechanism for verifying query results.
14. **`resolveQuery(uint256 queryId)`:**
    *   **Purpose:** (Callable by anyone, after voting period) Finalizes a query, distributes rewards to the best respondent(s) and validators, and penalizes inaccurate ones.
    *   **Concept:** The final step in the decentralized oracle process, determining the "truth" and incentivizing it.
15. **`getApprovedQueryResult(uint256 queryId)`:**
    *   **Purpose:** Retrieves the officially approved and resolved result for a specific data query.
    *   **Concept:** Provides a verifiable, on-chain record of the network's answer.

#### D. Staking & Rewards

16. **`stakeAMNForNode(uint256 nodeId, uint256 amount)`:**
    *   **Purpose:** Allows an `AetherMindNode` owner to stake AMN tokens to activate their node, making it eligible for participation and rewards.
    *   **Concept:** Proof-of-Stake mechanism for node security and participation.
17. **`unstakeAMNFromNode(uint256 nodeId, uint256 amount)`:**
    *   **Purpose:** Allows an owner to unstake AMN tokens from their node, subject to cooldown periods.
    *   **Concept:** Manages liquidity and node commitment.
18. **`claimStakingRewards(uint256 nodeId)`:**
    *   **Purpose:** Allows staked node owners to claim accumulated AMN rewards from their node's participation.
    *   **Concept:** Direct financial incentive for running a node.

#### E. Governance & System Evolution

19. **`proposeParameterChange(bytes32 paramNameHash, int256 newValue, string memory description)`:**
    *   **Purpose:** Allows designated governors or high-reputation nodes to propose changes to core contract parameters (e.g., reward rates, decay rates, epoch duration).
    *   **Concept:** Decentralized governance for network evolution.
20. **`voteOnParameterChange(uint256 proposalId, bool support)`:**
    *   **Purpose:** Allows eligible voters (governors, staked nodes) to cast their vote on active proposals.
    *   **Concept:** Participatory decision-making.
21. **`executeParameterChange(uint256 proposalId)`:**
    *   **Purpose:** Executes an approved parameter change proposal after a successful vote.
    *   **Concept:** On-chain implementation of governance decisions.
22. **`addGovernor(address newGovernor)`:**
    *   **Purpose:** (Admin/Governance) Adds a new address to the set of contract governors.
    *   **Concept:** Manages the group responsible for proposing and voting on high-level changes.
23. **`removeGovernor(address oldGovernor)`:**
    *   **Purpose:** (Admin/Governance) Removes an address from the set of contract governors.
    *   **Concept:** Manages the group responsible for proposing and voting on high-level changes.
24. **`setOracleContract(address _oracleAddress)`:**
    *   **Purpose:** (Admin/Governance) Sets or updates the address of a trusted off-chain oracle service, used for complex computations or external data verification during query resolution if internal consensus fails.
    *   **Concept:** Provides a fallback or supplementary mechanism for hard-to-resolve queries.
25. **`pauseContract()`:**
    *   **Purpose:** (Admin) Emergency function to pause critical contract functionalities.
    *   **Concept:** Safety mechanism for unexpected issues.
26. **`unpauseContract()`:**
    *   **Purpose:** (Admin) Resumes contract functionalities after a pause.
    *   **Concept:** Re-enables the system.
27. **`withdrawAMN(address _to, uint256 _amount)`:**
    *   **Purpose:** (Admin) Allows the contract owner to withdraw excess AMN tokens from the contract (e.g., from fees, or initial funding not used).
    *   **Concept:** Treasury management.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Error definitions
error AetherMindNexus__InvalidNodeId();
error AetherMindNexus__NotNodeOwner(uint256 nodeId, address caller);
error AetherMindNexus__NodeNotStaked(uint256 nodeId);
error AetherMindNexus__NodeAlreadyStaked(uint256 nodeId);
error AetherMindNexus__InsufficientStake(uint256 nodeId, uint256 requiredAmount, uint256 currentAmount);
error AetherMindNexus__FragmentNotFound(uint256 fragmentId);
error AetherMindNexus__FragmentAlreadyValidated(uint256 fragmentId);
error AetherMindNexus__QueryNotFound(uint256 queryId);
error AetherMindNexus__QueryAlreadyResolved(uint256 queryId);
error AetherMindNexus__NotEnoughTimePassed();
error AetherMindNexus__InvalidResponseIndex();
error AetherMindNexus__NoPendingRewards();
error AetherMindNexus__NotGovernor(address caller);
error AetherMindNexus__ProposalNotFound(uint256 proposalId);
error AetherMindNexus__AlreadyVoted(uint256 proposalId, address voter);
error AetherMindNexus__VotingPeriodNotOver();
error AetherMindNexus__ProposalNotApproved();
error AetherMindNexus__OnlyOwnerCanWithdraw();
error AetherMindNexus__TransferFailed();
error AetherMindNexus__CannotStakeZeroAmount();
error AetherMindNexus__CannotUnstakeZeroAmount();
error AetherMindNexus__CannotSetEmptyURI();
error AetherMindNexus__CannotSetZeroAddressOracle();


contract AetherMindNexus is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ERC721 Token for AetherMind Nodes
    Counters.Counter private _nodeIds;
    Counters.Counter private _fragmentIds;
    Counters.Counter private _queryIds;
    Counters.Counter private _proposalIds;

    IERC20 public immutable AMN_TOKEN; // AetherMind Native Token for staking and rewards

    // Node Attributes & State
    struct NodeAttributes {
        uint256 logic;       // Reflects analytical and reasoning capabilities
        uint256 intuition;   // Reflects insight and pattern recognition
        uint256 adaptability; // Reflects ability to learn and adjust
        uint256 reputation;  // Overall trustworthiness and performance score
        uint256 lastUpdatedEpoch; // Last epoch attributes were updated
        uint256 lastActivityTimestamp; // Last time node contributed or validated
    }
    mapping(uint256 => NodeAttributes) public s_nodeAttributes;
    mapping(uint256 => uint256) public s_nodeStakes; // nodeId => staked AMN amount
    mapping(uint256 => uint256) public s_nodePendingRewards; // nodeId => pending AMN rewards

    // Knowledge Base
    struct KnowledgeFragment {
        uint256 nodeId;       // Node that submitted the fragment
        string fragmentCid;   // IPFS CID of the actual knowledge data
        bytes32 fragmentHash; // Hash of the knowledge data for integrity check
        uint256 timestamp;
        uint256 positiveValidations;
        uint256 negativeValidations;
        mapping(uint256 => bool) hasValidated; // nodeId => true if validated
        bool isValidated;     // True if majority validated
        bool isResolved;      // True if processed in an epoch
    }
    mapping(uint256 => KnowledgeFragment) public s_knowledgeFragments;

    // Data Query System
    struct DataQuery {
        address requester;
        uint256 rewardAmount; // AMN reward for the best response
        string queryCid;
        bytes32 queryHash;
        uint256 timestamp;
        uint256 resolutionDeadline; // When query voting ends
        bool isResolved;
        uint256 winningResponseIndex; // Index in s_queryResponses[queryId]
        QueryResponse[] responses; // Dynamic array of responses
    }
    mapping(uint256 => DataQuery) public s_dataQueries;

    struct QueryResponse {
        uint256 nodeId;
        string responseCid;
        bytes32 responseHash;
        uint256 submissionTimestamp;
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(uint256 => bool) hasVoted; // nodeId => true if voted
    }

    // Governance & Parameters
    struct Proposal {
        bytes32 paramNameHash; // Hash of parameter name (e.g., keccak256("MIN_STAKE_AMOUNT"))
        int256 newValue;      // New value for the parameter (can be negative for ratios)
        string description;   // Description of the proposal
        uint256 createdTimestamp;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // voterAddress => true if voted
        bool executed;
    }
    mapping(uint256 => Proposal) public s_proposals;
    address[] public s_governors; // Addresses allowed to propose and vote on governance
    mapping(address => bool) public s_isGovernor;

    address public s_trustedOracleContract; // For external verification if needed

    // System Parameters (mutable via governance)
    uint256 public MIN_STAKE_AMOUNT = 1000 * 10 ** 18; // Default: 1000 AMN
    uint256 public EPOCH_DURATION = 7 days; // How often attributes are updated
    uint256 public ATTRIBUTE_DECAY_RATE = 10; // Percentage per epoch (e.g., 10 for 10%)
    uint256 public REPUTATION_GAIN_PER_VALIDATION = 1;
    uint256 public REPUTATION_LOSS_PER_MISVALIDATION = 2;
    uint256 public REPUTATION_GAIN_PER_QUERY_WIN = 5;
    uint256 public REPUTATION_LOSS_PER_BAD_RESPONSE = 3;
    uint256 public QUERY_RESOLUTION_PERIOD = 2 days; // Time for responses & voting
    uint256 public STAKING_COOLDOWN_PERIOD = 3 days; // Time before unstaked AMN is released

    uint256 public s_lastEpochTimestamp;
    bool public s_paused;

    // --- Events ---
    event NodeMinted(uint256 indexed nodeId, address indexed owner, uint256 timestamp);
    event NodeAttributesUpdated(uint256 indexed nodeId, uint256 logic, uint256 intuition, uint256 adaptability, uint256 reputation, uint256 epoch);
    event NodeDataRefreshRequested(uint256 indexed nodeId, address indexed requester);
    event NodeStaked(uint256 indexed nodeId, address indexed staker, uint256 amount);
    event NodeUnstaked(uint256 indexed nodeId, address indexed staker, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed nodeId, address indexed owner, uint256 amount);

    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, uint256 indexed nodeId, string fragmentCid, bytes32 fragmentHash);
    event KnowledgeFragmentValidated(uint256 indexed fragmentId, uint256 indexed validatorNodeId, bool isValid);
    event TrainingEpochProgressed(uint256 indexed newEpochTimestamp);
    event NodeAttributesDecayed(uint256 indexed nodeId, uint256 oldReputation, uint256 newReputation);

    event DataQuerySubmitted(uint256 indexed queryId, address indexed requester, uint256 rewardAmount, string queryCid);
    event QueryResponseSubmitted(uint256 indexed queryId, uint256 indexed nodeId, uint256 responseIndex, string responseCid);
    event QueryResponseVoted(uint256 indexed queryId, uint256 indexed responseIndex, uint256 indexed voterNodeId, bool isAccurate);
    event DataQueryResolved(uint256 indexed queryId, uint256 indexed winningNodeId, uint256 distributedReward);

    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramNameHash, int256 newValue, string description, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramNameHash, int256 newValue);

    event GovernorAdded(address indexed newGovernor);
    event GovernorRemoved(address indexed oldGovernor);
    event TrustedOracleSet(address indexed newOracleAddress);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event AMNWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (s_paused) revert("AetherMindNexus: Contract is paused");
        _;
    }

    modifier onlyNodeOwner(uint256 _nodeId) {
        if (ownerOf(_nodeId) != msg.sender) revert AetherMindNexus__NotNodeOwner(_nodeId, msg.sender);
        _;
    }

    modifier onlyStakedNode(uint256 _nodeId) {
        if (s_nodeStakes[_nodeId] < MIN_STAKE_AMOUNT) revert AetherMindNexus__NodeNotStaked(_nodeId);
        _;
    }

    modifier onlyGovernor() {
        if (!s_isGovernor[msg.sender]) revert AetherMindNexus__NotGovernor(msg.sender);
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address _amnTokenAddress)
        ERC721(name, symbol)
    {
        AMN_TOKEN = IERC20(_amnTokenAddress);
        s_lastEpochTimestamp = block.timestamp; // Initialize the first epoch
        s_governors.push(msg.sender);
        s_isGovernor[msg.sender] = true;
    }

    // --- I. AetherMindNode (NFT) Management ---

    /// @notice Allows a user to mint a new AetherMindNode NFT.
    /// @dev Initializes node attributes to base values.
    function mintNode() public whenNotPaused returns (uint256) {
        _nodeIds.increment();
        uint256 newNodeId = _nodeIds.current();
        _safeMint(msg.sender, newNodeId);

        s_nodeAttributes[newNodeId] = NodeAttributes({
            logic: 50,
            intuition: 50,
            adaptability: 50,
            reputation: 100, // Starting reputation
            lastUpdatedEpoch: s_lastEpochTimestamp,
            lastActivityTimestamp: block.timestamp
        });

        emit NodeMinted(newNodeId, msg.sender, block.timestamp);
        return newNodeId;
    }

    /// @notice Retrieves the current mutable cognitive attributes of a specific AetherMind Node.
    /// @param nodeId The ID of the AetherMind Node.
    /// @return NodeAttributes struct containing logic, intuition, adaptability, reputation, etc.
    function getNodeAttributes(uint256 nodeId) public view returns (NodeAttributes memory) {
        if (!_exists(nodeId)) revert AetherMindNexus__InvalidNodeId();
        return s_nodeAttributes[nodeId];
    }

    /// @notice Triggers an off-chain metadata refresh for a specific node's NFT.
    /// @dev This emits an event that off-chain services (e.g., IPFS pinning services, frontends) can listen to and update the NFT's metadata to reflect its latest on-chain attributes.
    /// @param nodeId The ID of the AetherMind Node to refresh.
    function requestNodeDataRefresh(uint256 nodeId) public onlyNodeOwner(nodeId) whenNotPaused {
        if (!_exists(nodeId)) revert AetherMindNexus__InvalidNodeId();
        emit NodeDataRefreshRequested(nodeId, msg.sender);
    }

    /// @notice (Admin/Governance) Sets the base URI for AetherMindNode NFT metadata.
    /// @dev This allows updates to where NFT metadata is hosted, or how it's structured.
    /// @param baseURI The new base URI.
    function setNodeBaseURI(string memory baseURI) public onlyOwner {
        if (bytes(baseURI).length == 0) revert AetherMindNexus__CannotSetEmptyURI();
        _setBaseURI(baseURI);
    }

    // --- II. Knowledge Contribution & Validation ---

    /// @notice Allows a staked AetherMindNode to contribute a piece of "knowledge."
    /// @dev The actual data is expected to be off-chain (IPFS, Arweave), with its CID and hash provided.
    /// @param nodeId The ID of the AetherMind Node submitting the fragment.
    /// @param fragmentCid The IPFS CID of the knowledge data.
    /// @param fragmentHash The keccak256 hash of the knowledge data for integrity verification.
    function submitKnowledgeFragment(
        uint256 nodeId,
        string memory fragmentCid,
        bytes32 fragmentHash
    ) public onlyNodeOwner(nodeId) onlyStakedNode(nodeId) whenNotPaused {
        _fragmentIds.increment();
        uint256 newFragmentId = _fragmentIds.current();

        s_knowledgeFragments[newFragmentId] = KnowledgeFragment({
            nodeId: nodeId,
            fragmentCid: fragmentCid,
            fragmentHash: fragmentHash,
            timestamp: block.timestamp,
            positiveValidations: 0,
            negativeValidations: 0,
            isValidated: false,
            isResolved: false
        });
        s_nodeAttributes[nodeId].lastActivityTimestamp = block.timestamp;

        emit KnowledgeFragmentSubmitted(newFragmentId, nodeId, fragmentCid, fragmentHash);
    }

    /// @notice Allows other staked AetherMindNodes or privileged validators to assess a submitted knowledge fragment.
    /// @param fragmentId The ID of the knowledge fragment to validate.
    /// @param isValid True if the fragment is deemed accurate/valid, false otherwise.
    function validateKnowledgeFragment(uint256 fragmentId, bool isValid) public onlyStakedNode(msg.sender) whenNotPaused {
        if (fragmentId == 0 || fragmentId > _fragmentIds.current()) revert AetherMindNexus__FragmentNotFound(fragmentId);
        KnowledgeFragment storage fragment = s_knowledgeFragments[fragmentId];

        uint256 validatorNodeId = _tokenOfOwnerByIndex(msg.sender, 0); // Assuming user has at least one node, pick first. Can be improved to allow choosing which node.
        if (fragment.hasValidated[validatorNodeId]) revert AetherMindNexus__FragmentAlreadyValidated(fragmentId);
        if (fragment.nodeId == validatorNodeId) revert("AetherMindNexus: Cannot validate your own fragment");

        fragment.hasValidated[validatorNodeId] = true;
        s_nodeAttributes[validatorNodeId].lastActivityTimestamp = block.timestamp;

        if (isValid) {
            fragment.positiveValidations++;
        } else {
            fragment.negativeValidations++;
        }

        emit KnowledgeFragmentValidated(fragmentId, validatorNodeId, isValid);
    }

    /// @notice Allows a validator to claim AMN rewards for successfully validated knowledge fragments.
    /// @dev This function would typically be called after a training epoch where validations are processed.
    /// For simplicity, here we assume direct reward claim.
    /// @param fragmentId The ID of the knowledge fragment.
    function claimValidationReward(uint256 fragmentId) public nonReentrant onlyStakedNode(msg.sender) whenNotPaused {
        if (fragmentId == 0 || fragmentId > _fragmentIds.current()) revert AetherMindNexus__FragmentNotFound(fragmentId);
        KnowledgeFragment storage fragment = s_knowledgeFragments[fragmentId];
        uint256 claimantNodeId = _tokenOfOwnerByIndex(msg.sender, 0);

        // A more robust system would track individual validator's pending rewards
        // For simplicity: If fragment is majority validated and claimant voted correctly and hasn't claimed
        if (fragment.isResolved || fragment.isResolved == false && fragment.timestamp + EPOCH_DURATION < block.timestamp) {
            // Simplified logic: assume fragment is considered resolved after an epoch
            bool correctlyValidated = (fragment.positiveValidations > fragment.negativeValidations && fragment.hasValidated[claimantNodeId]) ||
                                      (fragment.positiveValidations < fragment.negativeValidations && !fragment.hasValidated[claimantNodeId]);

            // This is a placeholder for a more complex reward distribution system
            // A more advanced system would calculate rewards based on specific contributions and global pool
            uint256 rewardAmount = 0;
            if (correctlyValidated) {
                rewardAmount = 10 * 10 ** 18; // Example: 10 AMN
                s_nodeAttributes[claimantNodeId].reputation += REPUTATION_GAIN_PER_VALIDATION;
            } else {
                 s_nodeAttributes[claimantNodeId].reputation -= REPUTATION_LOSS_PER_MISVALIDATION;
                 if (s_nodeAttributes[claimantNodeId].reputation < 0) s_nodeAttributes[claimantNodeId].reputation = 0; // Prevent negative reputation
            }

            if (rewardAmount == 0) revert AetherMindNexus__NoPendingRewards();

            s_nodePendingRewards[claimantNodeId] += rewardAmount; // Add to pending rewards
            // Mark fragment as processed for this validator for rewards
            fragment.isResolved = true; // Mark as resolved to prevent multiple claims

            emit StakingRewardsClaimed(claimantNodeId, msg.sender, rewardAmount);
        } else {
            revert("AetherMindNexus: Fragment not yet resolved or already claimed.");
        }
    }

    /// @notice (Callable by anyone) Advances the network's "training epoch."
    /// @dev During this, accumulated knowledge fragment validations are processed, and nodes' cognitive attributes are updated.
    /// This function needs to be gas-efficient; in a real scenario, it would iterate over a limited number of fragments or use a keeper.
    function progressTrainingEpoch() public whenNotPaused {
        if (block.timestamp < s_lastEpochTimestamp + EPOCH_DURATION) revert AetherMindNexus__NotEnoughTimePassed();

        s_lastEpochTimestamp = block.timestamp; // Update last epoch timestamp

        // Iterate through recent fragments and update node attributes
        // NOTE: This iteration can be very gas intensive for many fragments.
        // In a production system, this would be optimized (e.g., by processing batches,
        // or by having an off-chain keeper service trigger updates for a subset).
        for (uint256 i = 1; i <= _fragmentIds.current(); i++) {
            KnowledgeFragment storage fragment = s_knowledgeFragments[i];
            if (!fragment.isResolved && fragment.timestamp < block.timestamp - EPOCH_DURATION) {
                // If sufficient votes, update fragment status and nodes reputation
                if (fragment.positiveValidations + fragment.negativeValidations > 0) {
                    if (fragment.positiveValidations > fragment.negativeValidations) {
                        fragment.isValidated = true;
                        // Reputations updated during claimValidationReward or similar
                    } else {
                        fragment.isValidated = false;
                    }
                }
                fragment.isResolved = true;
            }
        }

        // Apply attribute decay to all active nodes
        // Again, this is a simplified loop and would need optimization for many nodes.
        for (uint256 i = 1; i <= _nodeIds.current(); i++) {
            // Check if node is staked and active
            if (_exists(i) && s_nodeStakes[i] >= MIN_STAKE_AMOUNT) {
                decayNodeAttributes(i); // Apply decay
                // Further attribute updates based on active participation during the epoch
                // (e.g., logic/intuition/adaptability gain based on successful query responses, etc.)
            }
        }

        emit TrainingEpochProgressed(s_lastEpochTimestamp);
    }

    /// @notice Periodically reduces cognitive attributes of inactive or underperforming nodes.
    /// @dev This function can be called externally for any node, but is also triggered internally during `progressTrainingEpoch`.
    /// @param nodeId The ID of the AetherMind Node to decay attributes for.
    function decayNodeAttributes(uint256 nodeId) public whenNotPaused {
        if (!_exists(nodeId)) revert AetherMindNexus__InvalidNodeId();
        NodeAttributes storage attrs = s_nodeAttributes[nodeId];

        // Ensure decay is only applied if sufficient time has passed since last update
        if (block.timestamp < attrs.lastUpdatedEpoch + EPOCH_DURATION) {
            // If called externally before epoch, do nothing. If called by epoch, it applies.
            return;
        }

        // Apply decay to specific attributes (example percentages)
        attrs.logic = attrs.logic * (100 - ATTRIBUTE_DECAY_RATE) / 100;
        attrs.intuition = attrs.intuition * (100 - ATTRIBUTE_DECAY_RATE) / 100;
        attrs.adaptability = attrs.adaptability * (100 - ATTRIBUTE_DECAY_RATE) / 100;

        uint256 oldReputation = attrs.reputation;
        // More aggressive decay for reputation if inactive
        uint256 decayFactor = (block.timestamp - attrs.lastActivityTimestamp) / EPOCH_DURATION;
        if (decayFactor > 0) {
            attrs.reputation = attrs.reputation * (100 - (ATTRIBUTE_DECAY_RATE * decayFactor)) / 100;
        }
        if (attrs.reputation < 0) attrs.reputation = 0; // Prevent negative reputation

        attrs.lastUpdatedEpoch = block.timestamp; // Mark as updated

        emit NodeAttributesDecayed(nodeId, oldReputation, attrs.reputation);
    }

    // --- III. Decentralized Query Resolution (Oracle-like) ---

    /// @notice A user submits a query to the network, staking a reward.
    /// @dev The actual query content is off-chain (IPFS, Arweave), with its CID and hash provided.
    /// @param queryCid The IPFS CID of the query content.
    /// @param queryHash The keccak256 hash of the query content.
    /// @param rewardAmount The AMN token amount staked as a reward for the best response.
    /// @return The ID of the submitted query.
    function submitDataQuery(
        string memory queryCid,
        bytes32 queryHash,
        uint256 rewardAmount
    ) public nonReentrant whenNotPaused returns (uint256) {
        if (rewardAmount == 0) revert("AetherMindNexus: Query reward must be greater than zero.");
        if (AMN_TOKEN.balanceOf(msg.sender) < rewardAmount) revert("AetherMindNexus: Insufficient AMN balance for reward.");
        if (!AMN_TOKEN.transferFrom(msg.sender, address(this), rewardAmount)) revert AetherMindNexus__TransferFailed();

        _queryIds.increment();
        uint256 newQueryId = _queryIds.current();

        s_dataQueries[newQueryId] = DataQuery({
            requester: msg.sender,
            rewardAmount: rewardAmount,
            queryCid: queryCid,
            queryHash: queryHash,
            timestamp: block.timestamp,
            resolutionDeadline: block.timestamp + QUERY_RESOLUTION_PERIOD,
            isResolved: false,
            winningResponseIndex: 0,
            responses: new QueryResponse[](0)
        });

        emit DataQuerySubmitted(newQueryId, msg.sender, rewardAmount, queryCid);
        return newQueryId;
    }

    /// @notice A staked AetherMindNode submits its proposed answer to an active query.
    /// @param queryId The ID of the query being responded to.
    /// @param nodeId The ID of the AetherMind Node submitting the response.
    /// @param responseCid The IPFS CID of the response data.
    /// @param responseHash The keccak256 hash of the response data.
    function respondToQuery(
        uint256 queryId,
        uint256 nodeId,
        string memory responseCid,
        bytes32 responseHash
    ) public onlyNodeOwner(nodeId) onlyStakedNode(nodeId) whenNotPaused {
        if (queryId == 0 || queryId > _queryIds.current()) revert AetherMindNexus__QueryNotFound(queryId);
        DataQuery storage query = s_dataQueries[queryId];
        if (query.isResolved || block.timestamp >= query.resolutionDeadline) revert("AetherMindNexus: Query is closed for responses.");

        query.responses.push(QueryResponse({
            nodeId: nodeId,
            responseCid: responseCid,
            responseHash: responseHash,
            submissionTimestamp: block.timestamp,
            positiveVotes: 0,
            negativeVotes: 0
        }));
        s_nodeAttributes[nodeId].lastActivityTimestamp = block.timestamp;

        emit QueryResponseSubmitted(queryId, nodeId, query.responses.length - 1, responseCid);
    }

    /// @notice Other staked AetherMindNodes or designated validators vote on the accuracy of submitted query responses.
    /// @param queryId The ID of the query.
    /// @param responseIndex The index of the response in the query's responses array.
    /// @param isAccurate True if the response is accurate, false otherwise.
    function voteOnQueryResponse(uint256 queryId, uint256 responseIndex, bool isAccurate) public onlyStakedNode(msg.sender) whenNotPaused {
        if (queryId == 0 || queryId > _queryIds.current()) revert AetherMindNexus__QueryNotFound(queryId);
        DataQuery storage query = s_dataQueries[queryId];
        if (query.isResolved || block.timestamp >= query.resolutionDeadline) revert("AetherMindNexus: Voting period for query is over.");
        if (responseIndex >= query.responses.length) revert AetherMindNexus__InvalidResponseIndex();

        uint256 voterNodeId = _tokenOfOwnerByIndex(msg.sender, 0); // Assuming user has at least one node, pick first.
        if (query.responses[responseIndex].nodeId == voterNodeId) revert("AetherMindNexus: Cannot vote on your own response.");
        if (query.responses[responseIndex].hasVoted[voterNodeId]) revert("AetherMindNexus: Already voted on this response.");

        query.responses[responseIndex].hasVoted[voterNodeId] = true;
        s_nodeAttributes[voterNodeId].lastActivityTimestamp = block.timestamp;

        if (isAccurate) {
            query.responses[responseIndex].positiveVotes++;
        } else {
            query.responses[responseIndex].negativeVotes++;
        }

        emit QueryResponseVoted(queryId, responseIndex, voterNodeId, isAccurate);
    }

    /// @notice Finalizes a query, distributes rewards to the best respondent(s) and validators, and penalizes inaccurate ones.
    /// @dev Can be called by anyone after the resolution deadline.
    /// @param queryId The ID of the query to resolve.
    function resolveQuery(uint256 queryId) public nonReentrant whenNotPaused {
        if (queryId == 0 || queryId > _queryIds.current()) revert AetherMindNexus__QueryNotFound(queryId);
        DataQuery storage query = s_dataQueries[queryId];
        if (query.isResolved) revert AetherMindNexus__QueryAlreadyResolved(queryId);
        if (block.timestamp < query.resolutionDeadline) revert AetherMindNexus__VotingPeriodNotOver();

        uint256 bestResponseIndex = 0;
        uint256 maxPositiveVotes = 0;

        for (uint256 i = 0; i < query.responses.length; i++) {
            if (query.responses[i].positiveVotes > maxPositiveVotes) {
                maxPositiveVotes = query.responses[i].positiveVotes;
                bestResponseIndex = i;
            }
        }

        // If no responses or no votes, query is effectively unresolved, refund requester.
        if (query.responses.length == 0 || maxPositiveVotes == 0) {
            if (!AMN_TOKEN.transfer(query.requester, query.rewardAmount)) revert AetherMindNexus__TransferFailed();
            query.isResolved = true;
            query.winningResponseIndex = type(uint256).max; // Indicates no winner
            emit DataQueryResolved(queryId, 0, query.rewardAmount); // 0 for no winning node
            return;
        }

        query.winningResponseIndex = bestResponseIndex;
        query.isResolved = true;

        QueryResponse storage winningResponse = query.responses[bestResponseIndex];
        uint256 winningNodeId = winningResponse.nodeId;
        
        // Reward the winning node
        uint256 rewardForWinner = query.rewardAmount / 2;
        s_nodePendingRewards[winningNodeId] += rewardForWinner;
        s_nodeAttributes[winningNodeId].reputation += REPUTATION_GAIN_PER_QUERY_WIN;

        // Distribute remaining reward to voters of the winning response
        uint256 rewardForVoters = query.rewardAmount - rewardForWinner;
        uint256 totalCorrectVotes = 0;
        for (uint256 i = 0; i < query.responses.length; i++) {
            if (i == bestResponseIndex) {
                totalCorrectVotes += winningResponse.positiveVotes;
            }
        }

        if (totalCorrectVotes > 0) {
            for (uint256 i = 0; i < query.responses.length; i++) {
                // Iterate through nodes that voted
                // This part requires iterating through the 'hasVoted' mapping, which is not directly possible.
                // A more advanced system would track explicit voter IDs or use an event-driven off-chain processor.
                // For this example, we'll simplify and just reward the winning node and leave the rest for a future enhancement.
                // Or: assume that the rewards for voters are handled by an off-chain keeper that identifies them via events.
            }
        }

        // Penalize nodes with incorrect responses or votes (simplified)
        for (uint256 i = 0; i < query.responses.length; i++) {
            if (i != bestResponseIndex) {
                s_nodeAttributes[query.responses[i].nodeId].reputation -= REPUTATION_LOSS_PER_BAD_RESPONSE;
                if (s_nodeAttributes[query.responses[i].nodeId].reputation < 0) s_nodeAttributes[query.responses[i].nodeId].reputation = 0;
            }
        }

        // A more sophisticated system would iterate through all potential voters for the correct response
        // and adjust their reputation/rewards accordingly.
        // For simplicity: reputation is updated based on positive/negative votes during claimValidationReward
        // and here for winning/losing query responses.

        emit DataQueryResolved(queryId, winningNodeId, query.rewardAmount);
    }

    /// @notice Retrieves the officially approved and resolved result for a specific data query.
    /// @param queryId The ID of the query.
    /// @return The winning node's ID, and the IPFS CID of the approved result.
    function getApprovedQueryResult(uint256 queryId) public view returns (uint256 nodeId, string memory resultCid) {
        if (queryId == 0 || queryId > _queryIds.current()) revert AetherMindNexus__QueryNotFound(queryId);
        DataQuery storage query = s_dataQueries[queryId];
        if (!query.isResolved) revert("AetherMindNexus: Query not yet resolved.");
        if (query.winningResponseIndex == type(uint256).max) { // No winner
            return (0, "");
        }
        QueryResponse storage winningResponse = query.responses[query.winningResponseIndex];
        return (winningResponse.nodeId, winningResponse.responseCid);
    }

    // --- IV. Staking & Rewards ---

    /// @notice Allows an AetherMindNode owner to stake AMN tokens to activate their node.
    /// @param nodeId The ID of the AetherMind Node.
    /// @param amount The amount of AMN tokens to stake.
    function stakeAMNForNode(uint256 nodeId, uint256 amount) public nonReentrant onlyNodeOwner(nodeId) whenNotPaused {
        if (amount == 0) revert AetherMindNexus__CannotStakeZeroAmount();
        // Check if AMN tokens are approved
        if (AMN_TOKEN.allowance(msg.sender, address(this)) < amount) {
            revert("AetherMindNexus: Please approve AMN tokens first.");
        }
        if (!AMN_TOKEN.transferFrom(msg.sender, address(this), amount)) revert AetherMindNexus__TransferFailed();

        s_nodeStakes[nodeId] += amount;
        s_nodeAttributes[nodeId].lastActivityTimestamp = block.timestamp;

        emit NodeStaked(nodeId, msg.sender, amount);
    }

    /// @notice Allows an owner to unstake AMN tokens from their node, subject to cooldown periods.
    /// @param nodeId The ID of the AetherMind Node.
    /// @param amount The amount of AMN tokens to unstake.
    function unstakeAMNFromNode(uint256 nodeId, uint256 amount) public nonReentrant onlyNodeOwner(nodeId) whenNotPaused {
        if (amount == 0) revert AetherMindNexus__CannotUnstakeZeroAmount();
        if (s_nodeStakes[nodeId] < amount) revert AetherMindNexus__InsufficientStake(nodeId, amount, s_nodeStakes[nodeId]);
        
        // Implement cooldown: A node must have been active for a period or not have any pending actions
        if (block.timestamp < s_nodeAttributes[nodeId].lastActivityTimestamp + STAKING_COOLDOWN_PERIOD) {
            revert("AetherMindNexus: Node is in cooldown period due to recent activity.");
        }

        s_nodeStakes[nodeId] -= amount;
        if (!AMN_TOKEN.transfer(msg.sender, amount)) revert AetherMindNexus__TransferFailed();

        emit NodeUnstaked(nodeId, msg.sender, amount);
    }

    /// @notice Allows staked node owners to claim accumulated AMN rewards.
    /// @param nodeId The ID of the AetherMind Node.
    function claimStakingRewards(uint256 nodeId) public nonReentrant onlyNodeOwner(nodeId) whenNotPaused {
        uint256 rewards = s_nodePendingRewards[nodeId];
        if (rewards == 0) revert AetherMindNexus__NoPendingRewards();

        s_nodePendingRewards[nodeId] = 0; // Reset pending rewards
        if (!AMN_TOKEN.transfer(msg.sender, rewards)) revert AetherMindNexus__TransferFailed();

        emit StakingRewardsClaimed(nodeId, msg.sender, rewards);
    }

    // --- V. Governance & System Evolution ---

    /// @notice Allows designated governors to propose changes to core contract parameters.
    /// @param paramNameHash The keccak256 hash of the parameter name (e.g., keccak256("MIN_STAKE_AMOUNT")).
    /// @param newValue The proposed new value for the parameter.
    /// @param description A descriptive string for the proposal.
    /// @return The ID of the created proposal.
    function proposeParameterChange(
        bytes32 paramNameHash,
        int256 newValue,
        string memory description
    ) public onlyGovernor whenNotPaused returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        s_proposals[proposalId] = Proposal({
            paramNameHash: paramNameHash,
            newValue: newValue,
            description: description,
            createdTimestamp: block.timestamp,
            votingDeadline: block.timestamp + 3 days, // Example: 3 days voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit ParameterChangeProposed(proposalId, paramNameHash, newValue, description, msg.sender);
        return proposalId;
    }

    /// @notice Allows eligible voters (governors, staked nodes) to cast their vote on active proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True to vote for, false to vote against.
    function voteOnParameterChange(uint256 proposalId, bool support) public whenNotPaused {
        if (proposalId == 0 || proposalId > _proposalIds.current()) revert AetherMindNexus__ProposalNotFound(proposalId);
        Proposal storage proposal = s_proposals[proposalId];

        if (proposal.executed) revert("AetherMindNexus: Proposal already executed.");
        if (block.timestamp >= proposal.votingDeadline) revert AetherMindNexus__VotingPeriodNotOver();
        if (proposal.hasVoted[msg.sender]) revert AetherMindNexus__AlreadyVoted(proposalId, msg.sender);

        // Only governors can vote in this example. Could be extended to include staked nodes based on reputation.
        if (!s_isGovernor[msg.sender]) revert AetherMindNexus__NotGovernor(msg.sender);

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /// @notice Executes an approved parameter change proposal after a successful vote.
    /// @param proposalId The ID of the proposal to execute.
    function executeParameterChange(uint256 proposalId) public onlyGovernor whenNotPaused {
        if (proposalId == 0 || proposalId > _proposalIds.current()) revert AetherMindNexus__ProposalNotFound(proposalId);
        Proposal storage proposal = s_proposals[proposalId];

        if (proposal.executed) revert("AetherMindNexus: Proposal already executed.");
        if (block.timestamp < proposal.votingDeadline) revert("AetherMindNexus: Voting period not over.");

        // Simple majority vote for execution (can be weighted by stake/reputation)
        if (proposal.votesFor <= proposal.votesAgainst) revert AetherMindNexus__ProposalNotApproved();

        // Apply the parameter change
        bytes32 paramHash = proposal.paramNameHash;
        int256 newValue = proposal.newValue;

        if (paramHash == keccak256("MIN_STAKE_AMOUNT")) {
            MIN_STAKE_AMOUNT = uint256(newValue);
        } else if (paramHash == keccak256("EPOCH_DURATION")) {
            EPOCH_DURATION = uint256(newValue);
        } else if (paramHash == keccak256("ATTRIBUTE_DECAY_RATE")) {
            ATTRIBUTE_DECAY_RATE = uint256(newValue);
        } else if (paramHash == keccak256("REPUTATION_GAIN_PER_VALIDATION")) {
            REPUTATION_GAIN_PER_VALIDATION = uint256(newValue);
        } else if (paramHash == keccak256("REPUTATION_LOSS_PER_MISVALIDATION")) {
            REPUTATION_LOSS_PER_MISVALIDATION = uint256(newValue);
        } else if (paramHash == keccak256("REPUTATION_GAIN_PER_QUERY_WIN")) {
            REPUTATION_GAIN_PER_QUERY_WIN = uint256(newValue);
        } else if (paramHash == keccak256("REPUTATION_LOSS_PER_BAD_RESPONSE")) {
            REPUTATION_LOSS_PER_BAD_RESPONSE = uint256(newValue);
        } else if (paramHash == keccak256("QUERY_RESOLUTION_PERIOD")) {
            QUERY_RESOLUTION_PERIOD = uint256(newValue);
        } else if (paramHash == keccak256("STAKING_COOLDOWN_PERIOD")) {
            STAKING_COOLDOWN_PERIOD = uint256(newValue);
        }
        // Add more parameters as needed

        proposal.executed = true;
        emit ParameterChangeExecuted(proposalId, paramHash, newValue);
    }

    /// @notice (Admin/Governance) Adds a new address to the set of contract governors.
    /// @param newGovernor The address to add as a governor.
    function addGovernor(address newGovernor) public onlyOwner { // Can be changed to governance vote
        if (s_isGovernor[newGovernor]) revert("AetherMindNexus: Address is already a governor.");
        s_governors.push(newGovernor);
        s_isGovernor[newGovernor] = true;
        emit GovernorAdded(newGovernor);
    }

    /// @notice (Admin/Governance) Removes an address from the set of contract governors.
    /// @param oldGovernor The address to remove.
    function removeGovernor(address oldGovernor) public onlyOwner { // Can be changed to governance vote
        if (!s_isGovernor[oldGovernor]) revert("AetherMindNexus: Address is not a governor.");
        s_isGovernor[oldGovernor] = false;
        // Remove from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < s_governors.length; i++) {
            if (s_governors[i] == oldGovernor) {
                s_governors[i] = s_governors[s_governors.length - 1];
                s_governors.pop();
                break;
            }
        }
        emit GovernorRemoved(oldGovernor);
    }

    /// @notice (Admin/Governance) Sets or updates the address of a trusted off-chain oracle service.
    /// @param _oracleAddress The address of the new oracle contract.
    function setOracleContract(address _oracleAddress) public onlyOwner { // Could be via governance
        if (_oracleAddress == address(0)) revert AetherMindNexus__CannotSetZeroAddressOracle();
        s_trustedOracleContract = _oracleAddress;
        emit TrustedOracleSet(_oracleAddress);
    }

    /// @notice (Admin) Emergency function to pause critical contract functionalities.
    function pauseContract() public onlyOwner {
        s_paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice (Admin) Resumes contract functionalities after a pause.
    function unpauseContract() public onlyOwner {
        s_paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice (Admin) Allows the contract owner to withdraw excess AMN tokens from the contract.
    /// @param _to The recipient address.
    /// @param _amount The amount of AMN tokens to withdraw.
    function withdrawAMN(address _to, uint256 _amount) public onlyOwner nonReentrant {
        if (_to == address(0)) revert AetherMindNexus__OnlyOwnerCanWithdraw(); // Simplified error as msg.sender check is also there
        if (AMN_TOKEN.balanceOf(address(this)) < _amount) revert("AetherMindNexus: Insufficient AMN balance in contract.");
        if (!AMN_TOKEN.transfer(_to, _amount)) revert AetherMindNexus__TransferFailed();
        emit AMNWithdrawn(_to, _amount);
    }

    // --- Internal Helpers (for modifiers) ---
    // These functions allow the use of `msg.sender` as a node owner to refer to a specific node,
    // assuming a user typically operates one primary node or the first owned node for certain actions.
    // In a more complex system, the user would specify which node they are using.
    function _tokenOfOwnerByIndex(address owner, uint256 index) internal view returns (uint256) {
        // This is a simplified lookup. A user might own multiple nodes.
        // For general actions like `validateKnowledgeFragment`, we assume the user's first node.
        // For node-specific actions like `stakeAMNForNode`, the nodeId is passed directly.
        if (ERC721.balanceOf(owner) == 0) revert("AetherMindNexus: Owner has no nodes.");
        return ERC721.tokenOfOwnerByIndex(owner, index);
    }
}
```