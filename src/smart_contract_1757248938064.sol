This smart contract, **AuraStream Nexus**, proposes an advanced, creative, and trendy approach to decentralized reputation, resource allocation, and collaborative goal achievement, leveraging **Dynamic Non-Fungible Tokens (dNFTs)**, **Intent-Driven Pools**, and an **Adaptive Reward System**. It aims to create a self-regulating ecosystem where participants' on-chain contributions and reputation dynamically influence their utility and rewards.

---

## AuraStream Nexus: Smart Contract Outline & Function Summary

**Contract Name:** `AuraStreamNexus`

**Core Idea:** A decentralized network where users mint unique "AuraNodes" (Dynamic NFTs) representing their on-chain identity and contribution potential. These AuraNodes participate in "Intent Pools" – goal-oriented staking mechanisms – to achieve collective objectives. The AuraNodes' properties (AuraScore, Influence, Affinity) dynamically evolve based on their actions, community attestations, and participation, directly impacting their rewards and standing within the ecosystem.

---

### Outline:

1.  **Contract Overview:**
    *   ERC721 standard for AuraNodes.
    *   ERC20 standard for the native AuraToken.
    *   Ownership/Admin control for critical system parameters.
    *   Advanced error handling.

2.  **Core Concepts:**
    *   **AuraNode (Dynamic NFT):** Represents a user's digital footprint. Its properties (AuraScore, Influence Multiplier, Resource Affinity) are stored on-chain and evolve.
    *   **Intent Pool:** A collaborative, goal-oriented staking pool where AuraNodes and AuraTokens are committed to achieve a specific objective (e.g., funding, data verification, curation).
    *   **Adaptive Reward System:** Rewards are not static; they are dynamically adjusted based on an AuraNode's real-time properties and its effective contribution to an Intent Pool.
    *   **Social Attestation & Dispute:** Community-driven mechanisms to validate contributions and maintain reputation integrity.
    *   **Predictive Intent Integration:** A conceptual oracle integration to dynamically adjust pool parameters or rewards based on external "insights" (simulated here).

3.  **Tokenomics:**
    *   **AuraToken (ERC20):** Native utility token used for staking in Intent Pools, receiving rewards, and potentially future governance.
    *   **AuraNode (ERC721):** The core reputation and utility bearing NFT.

4.  **Key Components:**
    *   `AuraNode` struct: Defines the dynamic properties of each NFT.
    *   `IntentPool` struct: Defines the parameters and state of each goal-oriented pool.
    *   `Attestation` struct: Details for social attestations.
    *   `Proposal` struct: For decentralized parameter changes.

---

### Function Summary (Minimum 20 functions):

**I. AuraNode (dNFT) Management (ERC721 & Dynamic Properties):**

1.  `createAuraNode(metadataURI)`: Mints a new AuraNode NFT with initial properties for the caller.
2.  `updateNodeMetadataURI(tokenId, newURI)`: Allows the AuraNode owner to update its off-chain metadata URI (though core properties are on-chain).
3.  `getNodeDetails(tokenId)`: Retrieves all dynamic on-chain properties of an AuraNode.
4.  `transferAuraNode(from, to, tokenId)`: Standard ERC721 transfer function.
5.  `setAuraNodeStatus(tokenId, newStatus)`: Admin/governance function to change a node's status (e.g., suspend).

**II. AuraScore & Influence Mechanics:**

6.  `attestNodeActivity(tokenId, attesterNodeId, scoreImpact, affinityImpact, attestationHash)`: Allows an active AuraNode to attest to another node's positive contribution, dynamically affecting its AuraScore and ResourceAffinity.
7.  `disputeNodeAttestation(tokenId, attestationId, disputeReason)`: Allows any active AuraNode to dispute a prior attestation, triggering a review process.
8.  `decayInactiveNodesAura()`: An admin/keeper function to periodically apply decay to AuraScores of inactive nodes, encouraging continuous participation.
9.  `recalculateNodeInfluence(tokenId)`: Triggers a recalculation of a node's influence multiplier based on its current AuraScore and other factors.

**III. Intent Pool Management:**

10. `createIntentPool(description, targetResourceAmount, requiredAttestationsForCompletion, rewardMultiplier)`: Deploys a new Intent Pool with specific goals and parameters.
11. `stakeAuraNodeInPool(poolId, tokenId)`: Allows an AuraNode owner to stake their node in an Intent Pool to contribute to its goal.
12. `unstakeAuraNodeFromPool(poolId, tokenId)`: Allows an AuraNode owner to unstake their node from a pool.
13. `depositAuraTokensToPool(poolId, amount)`: Allows users to stake AuraTokens into an Intent Pool to provide resources.
14. `withdrawAuraTokensFromPool(poolId, amount)`: Allows contributors to withdraw their staked AuraTokens (subject to pool rules/completion).
15. `attestPoolGoalCompletion(poolId, tokenId, completionDetailsHash)`: A contributing AuraNode attests that a pool's goal has been met.
16. `finalizeIntentPool(poolId)`: Admin/governance function to formally finalize a pool if sufficient goal attestations are received.

**IV. Reward Distribution & Claiming:**

17. `claimAuraRewards(poolId, tokenId)`: Allows a staked AuraNode to claim its proportional rewards from a finalized pool, adjusted by its dynamic AuraScore and Influence.
18. `distributeUnclaimedPoolRewards(poolId)`: Admin/keeper function to distribute any remaining rewards from a finalized pool to the treasury or for future use.

**V. Governance & System Parameters (Decentralized through AuraNodes):**

19. `proposeParameterChange(paramName, newValue)`: Allows active AuraNodes to propose changes to system parameters (e.g., decay rate, attestation thresholds).
20. `voteOnParameterChange(proposalId, support)`: Allows active AuraNodes to vote on open proposals, weighted by their Influence Multiplier.
21. `executeParameterChange(proposal(Id)`: Executed by the owner/admin once a proposal passes its voting threshold.
22. `getSystemParameter(paramName)`: Retrieves the current value of a system parameter.

**VI. AuraToken Management (ERC20):**

23. `mintInitialAuraTokens(recipient, amount)`: Admin function for initial token distribution.
24. `batchMintAuraTokens(recipients, amounts)`: Admin function to mint tokens to multiple recipients.

**VII. Predictive Intent Integration (Conceptual/Simulated):**

25. `updatePredictiveInsight(poolId, insightValue)`: Admin/oracle function to feed external, predictive insights into a pool, which can dynamically adjust its reward multiplier or completion difficulty.
26. `getPredictiveInsight(poolId)`: Retrieves the current predictive insight value for a given pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Still good practice for clarity on large numbers
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Custom Errors ---
error Unauthorized();
error InvalidNodeId();
error NodeAlreadyStaked();
error NodeNotStaked();
error InsufficientBalance();
error InvalidPoolId();
error PoolNotFinalized();
error PoolAlreadyFinalized();
error InsufficientAttestations();
error ZeroAmount();
error InvalidAuraScoreImpact();
error InvalidAffinityImpact();
error AttestationNotFound();
error AttestationAlreadyDisputed();
error CannotDisputeOwnAttestation();
error InvalidProposalId();
error ProposalAlreadyVoted();
error ProposalNotYetExecutable();
error ProposalExpired();
error ProposalAlreadyExecuted();
error InsufficientVotingPower();
error NodeNotActive();
error NodeIsDormant();
error PoolNotActive();
error ZeroAddress();
error NodeAlreadyExists();


/**
 * @title AuraStreamNexus
 * @dev A decentralized network for reputation, resource allocation, and collaborative goal achievement.
 *      It leverages Dynamic NFTs (AuraNodes), Intent-Driven Pools, and an Adaptive Reward System.
 *      AuraNodes' properties (AuraScore, Influence, Affinity) evolve based on actions and attestations,
 *      directly impacting their utility and rewards in Intent Pools.
 */
contract AuraStreamNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums ---
    enum AuraNodeStatus { Active, Dormant, Sanctioned }
    enum PoolStatus { Active, Finalized, Cancelled }
    enum ProposalStatus { Open, Passed, Failed, Executed }

    // --- Structs ---

    struct AuraNode {
        uint256 id;
        uint256 auraScore;            // Core reputation metric, dynamically updated
        uint256 influenceMultiplier;  // Affects voting power, reward share (derived from auraScore)
        uint256 resourceAffinity;     // Indicates preference/suitability for certain pool types
        uint256 lastActivityTimestamp; // Last time the node made a significant on-chain action
        AuraNodeStatus status;
        uint256 totalAttestationsGiven;
        uint256 totalAttestationsReceived;
        mapping(uint256 => Attestation) receivedAttestations; // attestationId => Attestation
        Counters.Counter attestationCounter; // For unique attestation IDs per node
    }

    struct Attestation {
        uint256 attesterNodeId;
        uint256 targetNodeId;
        int256 scoreImpact;      // Can be positive or negative
        int256 affinityImpact;   // Can be positive or negative
        uint256 timestamp;
        bytes32 attestationHash; // Unique hash of the attestation details for integrity
        bool disputed;           // True if attestation has been disputed
        uint256 disputeId;       // ID of the dispute if any
    }

    struct IntentPool {
        uint256 id;
        string description;
        address creator;
        uint256 targetResourceAmount;
        uint256 currentStakedResources;
        uint256 requiredAttestationsForCompletion;
        uint256 currentGoalAttestations;
        uint256 rewardMultiplier; // Base multiplier for rewards in this pool
        PoolStatus status;
        mapping(uint256 => bool) stakedNodes; // tokenId => isStaked
        uint256[] stakedNodeIds;
        mapping(uint256 => uint256) nodeStakedTime; // tokenId => timestamp
        mapping(address => uint256) stakedAuraTokens; // userAddress => amount
        mapping(address => uint256) claimedAuraTokens; // userAddress => amount claimed from pool
        uint256 predictiveInsightValue; // Value from a conceptual Predictive Intent Oracle
    }

    struct Proposal {
        uint256 id;
        string paramName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yeas;
        uint256 nays;
        mapping(uint256 => bool) hasVoted; // AuraNodeId => hasVoted
        ProposalStatus status;
    }

    // --- State Variables ---

    AuraToken public auraToken;
    Counters.Counter private _nodeIdCounter;
    Counters.Counter private _poolIdCounter;
    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => AuraNode) public auraNodes; // tokenId => AuraNode
    mapping(address => uint256) public ownerNodeId; // ownerAddress => tokenId (assuming 1 node per owner for simplicity)
    mapping(uint256 => IntentPool) public intentPools;
    mapping(string => uint256) public systemParameters; // E.g., "decayRate", "minAuraScore", "maxInfluence"
    mapping(uint256 => Proposal) public proposals;

    uint256 public constant MIN_AURA_SCORE = 1000;
    uint256 public constant INITIAL_INFLUENCE_MULTIPLIER = 100; // Represents 1.00 (100 base)
    uint256 public constant INITIAL_RESOURCE_AFFINITY = 50;
    uint256 public constant AURA_DECAY_RATE_PER_DAY = 10; // points per day
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 5; // 5% of total influence needed to pass
    uint256 public totalAuraInfluence = 0; // Sum of all active node influence multipliers

    // --- Events ---
    event AuraNodeCreated(uint256 indexed tokenId, address indexed owner, string metadataURI);
    event AuraNodeStatusUpdated(uint256 indexed tokenId, AuraNodeStatus newStatus);
    event NodeAuraScoreUpdated(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);
    event NodeInfluenceUpdated(uint256 indexed tokenId, uint256 oldInfluence, uint256 newInfluence);
    event NodeResourceAffinityUpdated(uint256 indexed tokenId, uint256 oldAffinity, uint256 newAffinity);
    event AttestationSubmitted(uint256 indexed attesterNodeId, uint256 indexed targetNodeId, uint256 attestationId, int256 scoreImpact, int256 affinityImpact);
    event AttestationDisputed(uint256 indexed attestationId, uint256 indexed disputeId, uint256 targetNodeId, address indexed disputer);
    event IntentPoolCreated(uint256 indexed poolId, address indexed creator, string description, uint256 targetAmount);
    event NodeStakedInPool(uint256 indexed poolId, uint256 indexed tokenId);
    event NodeUnstakedFromPool(uint256 indexed poolId, uint256 indexed tokenId);
    event ResourcesDepositedToPool(uint256 indexed poolId, address indexed depositor, uint256 amount);
    event ResourcesWithdrawnFromPool(uint256 indexed poolId, address indexed withdrawer, uint256 amount);
    event PoolGoalAttested(uint256 indexed poolId, uint256 indexed attesterNodeId);
    event IntentPoolFinalized(uint256 indexed poolId, uint256 finalRewardMultiplier);
    event AuraRewardsClaimed(uint256 indexed poolId, uint256 indexed tokenId, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, string paramName, uint256 newValue, uint256 endTime);
    event ParameterVoteCast(uint256 indexed proposalId, uint256 indexed voterNodeId, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event PredictiveInsightUpdated(uint256 indexed poolId, uint256 insightValue);

    // --- Constructor ---

    constructor(string memory _auraTokenName, string memory _auraTokenSymbol)
        ERC721("AuraNode NFT", "AURA_NODE")
        Ownable(msg.sender)
    {
        auraToken = new AuraToken(_auraTokenName, _auraTokenSymbol);

        // Set initial system parameters
        systemParameters["decayRatePerDay"] = AURA_DECAY_RATE_PER_DAY;
        systemParameters["minAuraScore"] = MIN_AURA_SCORE;
        systemParameters["proposalVotingPeriod"] = PROPOSAL_VOTING_PERIOD;
        systemParameters["proposalQuorumPercentage"] = PROPOSAL_QUORUM_PERCENTAGE;
        systemParameters["initialInfluenceMultiplier"] = INITIAL_INFLUENCE_MULTIPLIER;
        systemParameters["initialResourceAffinity"] = INITIAL_RESOURCE_AFFINITY;
    }

    // --- Modifiers ---

    modifier onlyAuraNodeOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyActiveNode(uint256 _tokenId) {
        if (auraNodes[_tokenId].status != AuraNodeStatus.Active) revert NodeNotActive();
        _;
    }

    modifier onlyPoolContributor(uint256 _poolId, uint256 _tokenId) {
        if (!intentPools[_poolId].stakedNodes[_tokenId]) revert NodeNotStaked();
        _;
    }

    // --- Internal Helpers ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _exists(tokenId); // Using ERC721Enumerable's _exists
    }

    function _isNodeActive(uint256 _tokenId) internal view returns (bool) {
        return _exists(_tokenId) && auraNodes[_tokenId].status == AuraNodeStatus.Active;
    }

    function _recalculateNodeInfluence(uint256 _tokenId) internal {
        AuraNode storage node = auraNodes[_tokenId];
        if (!_isNodeActive(_tokenId)) return; // Only active nodes have influence

        uint256 oldInfluence = node.influenceMultiplier;

        // Influence is proportional to AuraScore, with a base multiplier
        // Example: influence = (auraScore / 1000) * initialInfluenceMultiplier
        // This ensures a higher score gives more influence.
        node.influenceMultiplier = node.auraScore.mul(systemParameters["initialInfluenceMultiplier"]).div(MIN_AURA_SCORE);

        // Update total aura influence
        totalAuraInfluence = totalAuraInfluence.sub(oldInfluence).add(node.influenceMultiplier);

        emit NodeInfluenceUpdated(_tokenId, oldInfluence, node.influenceMultiplier);
    }

    function _updateAuraScore(uint256 _tokenId, int256 _impact) internal {
        AuraNode storage node = auraNodes[_tokenId];
        uint256 oldScore = node.auraScore;

        if (_impact > 0) {
            node.auraScore = node.auraScore.add(uint256(_impact));
        } else if (_impact < 0) {
            uint256 absImpact = uint256(-_impact);
            if (node.auraScore > absImpact) {
                node.auraScore = node.auraScore.sub(absImpact);
            } else {
                node.auraScore = MIN_AURA_SCORE; // Floor at min score
            }
        }
        
        emit NodeAuraScoreUpdated(_tokenId, oldScore, node.auraScore);
        _recalculateNodeInfluence(_tokenId); // Recalculate influence after score change
    }

    function _updateResourceAffinity(uint256 _tokenId, int256 _impact) internal {
        AuraNode storage node = auraNodes[_tokenId];
        uint256 oldAffinity = node.resourceAffinity;

        if (_impact > 0) {
            node.resourceAffinity = node.resourceAffinity.add(uint256(_impact));
        } else if (_impact < 0) {
            uint256 absImpact = uint256(-_impact);
            if (node.resourceAffinity > absImpact) {
                node.resourceAffinity = node.resourceAffinity.sub(absImpact);
            } else {
                node.resourceAffinity = 0; // Floor at 0
            }
        }
        emit NodeResourceAffinityUpdated(_tokenId, oldAffinity, node.resourceAffinity);
    }

    function _getNodeInfluenceRaw(uint256 _tokenId) internal view returns (uint256) {
        if (!_exists(_tokenId) || auraNodes[_tokenId].status != AuraNodeStatus.Active) {
            return 0;
        }
        return auraNodes[_tokenId].influenceMultiplier;
    }


    // --- ERC721 Overrides (to ensure compatibility with Enumerable) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Additional logic for AuraNode specific transfers if needed
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        // Reset ownerNodeId mapping if node is transferred, to ensure it reflects current owner
        if (from != address(0)) {
            delete ownerNodeId[from];
        }
        if (to != address(0)) {
            ownerNodeId[to] = tokenId;
        }
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._approve(to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal override(ERC721Enumerable) {
        super._safeTransfer(from, to, tokenId, data);
    }

    // --- AuraNode (dNFT) Management (ERC721 & Dynamic Properties) ---

    /**
     * @dev Mints a new AuraNode NFT for the caller with initial properties.
     *      Assumes one AuraNode per user address for simplicity.
     * @param _metadataURI The initial metadata URI for the NFT.
     */
    function createAuraNode(string calldata _metadataURI) external returns (uint256) {
        if (ownerNodeId[msg.sender] != 0) revert NodeAlreadyExists(); // Ensure 1 node per user
        
        _nodeIdCounter.increment();
        uint256 newItemId = _nodeIdCounter.current();

        AuraNode storage newNode = auraNodes[newItemId];
        newNode.id = newItemId;
        newNode.auraScore = systemParameters["minAuraScore"];
        newNode.influenceMultiplier = systemParameters["initialInfluenceMultiplier"];
        newNode.resourceAffinity = systemParameters["initialResourceAffinity"];
        newNode.lastActivityTimestamp = block.timestamp;
        newNode.status = AuraNodeStatus.Active;

        totalAuraInfluence = totalAuraInfluence.add(newNode.influenceMultiplier);

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _metadataURI); // Set ERC721 URI
        ownerNodeId[msg.sender] = newItemId; // Link owner to node

        emit AuraNodeCreated(newItemId, msg.sender, _metadataURI);
        return newItemId;
    }

    /**
     * @dev Allows the AuraNode owner to update its off-chain metadata URI.
     * @param _tokenId The ID of the AuraNode.
     * @param _newURI The new metadata URI.
     */
    function updateNodeMetadataURI(uint256 _tokenId, string calldata _newURI)
        external
        onlyAuraNodeOwner(_tokenId)
    {
        if (!_exists(_tokenId)) revert InvalidNodeId();
        _setTokenURI(_tokenId, _newURI);
    }

    /**
     * @dev Retrieves all dynamic on-chain properties of an AuraNode.
     * @param _tokenId The ID of the AuraNode.
     * @return AuraNode struct containing all properties.
     */
    function getNodeDetails(uint256 _tokenId)
        public
        view
        returns (
            uint256 id,
            uint256 auraScore,
            uint256 influenceMultiplier,
            uint256 resourceAffinity,
            uint256 lastActivityTimestamp,
            AuraNodeStatus status,
            uint256 totalAttestationsGiven,
            uint256 totalAttestationsReceived
        )
    {
        if (!_exists(_tokenId)) revert InvalidNodeId();
        AuraNode storage node = auraNodes[_tokenId];
        return (
            node.id,
            node.auraScore,
            node.influenceMultiplier,
            node.resourceAffinity,
            node.lastActivityTimestamp,
            node.status,
            node.totalAttestationsGiven,
            node.totalAttestationsReceived
        );
    }

    /**
     * @dev Admin/governance function to change a node's status (e.g., suspend).
     *      Affects its ability to participate and its influence.
     * @param _tokenId The ID of the AuraNode.
     * @param _newStatus The new status for the node.
     */
    function setAuraNodeStatus(uint256 _tokenId, AuraNodeStatus _newStatus) external onlyOwner {
        if (!_exists(_tokenId)) revert InvalidNodeId();
        AuraNode storage node = auraNodes[_tokenId];
        node.status = _newStatus;
        if (_newStatus != AuraNodeStatus.Active) {
            // Remove influence if node is not active
            totalAuraInfluence = totalAuraInfluence.sub(node.influenceMultiplier);
            node.influenceMultiplier = 0;
        } else {
            // Re-add influence if node becomes active
            _recalculateNodeInfluence(_tokenId);
        }
        emit AuraNodeStatusUpdated(_tokenId, _newStatus);
    }

    // --- AuraScore & Influence Mechanics ---

    /**
     * @dev Allows an active AuraNode to attest to another node's positive contribution,
     *      dynamically affecting its AuraScore and ResourceAffinity.
     * @param _targetNodeId The ID of the node being attested.
     * @param _attesterNodeId The ID of the node making the attestation.
     * @param _scoreImpact The points to add/subtract from the target node's AuraScore.
     * @param _affinityImpact The points to add/subtract from the target node's ResourceAffinity.
     * @param _attestationHash A unique hash of the attestation details (for integrity).
     */
    function attestNodeActivity(
        uint256 _targetNodeId,
        uint256 _attesterNodeId,
        int256 _scoreImpact,
        int256 _affinityImpact,
        bytes32 _attestationHash
    )
        external
        onlyAuraNodeOwner(_attesterNodeId) // Ensure attester owns their node
        onlyActiveNode(_attesterNodeId)     // Attester must be active
    {
        if (!_exists(_targetNodeId) || !_isNodeActive(_targetNodeId)) revert InvalidNodeId();
        if (_targetNodeId == _attesterNodeId) revert CannotAttestSelf();

        // Prevent spamming attestations by checking if hash already exists (simple uniqueness check)
        // More advanced systems might check for recent attestations from the same attester.
        require(auraNodes[_targetNodeId].receivedAttestations[_attesterNodeId].attestationHash != _attestationHash, "Duplicate attestation hash");

        AuraNode storage targetNode = auraNodes[_targetNodeId];
        targetNode.attestationCounter.increment();
        uint256 attestationId = targetNode.attestationCounter.current();

        targetNode.receivedAttestations[attestationId] = Attestation({
            attesterNodeId: _attesterNodeId,
            targetNodeId: _targetNodeId,
            scoreImpact: _scoreImpact,
            affinityImpact: _affinityImpact,
            timestamp: block.timestamp,
            attestationHash: _attestationHash,
            disputed: false,
            disputeId: 0
        });

        _updateAuraScore(_targetNodeId, _scoreImpact);
        _updateResourceAffinity(_targetNodeId, _affinityImpact);

        auraNodes[_attesterNodeId].lastActivityTimestamp = block.timestamp; // Update attester activity
        auraNodes[_attesterNodeId].totalAttestationsGiven++;
        targetNode.totalAttestationsReceived++;

        emit AttestationSubmitted(_attesterNodeId, _targetNodeId, attestationId, _scoreImpact, _affinityImpact);
    }

    /**
     * @dev Allows any active AuraNode to dispute a prior attestation.
     *      This marks the attestation as disputed, potentially leading to review/reversal by governance.
     * @param _targetNodeId The ID of the node whose attestation is being disputed.
     * @param _attestationId The ID of the specific attestation to dispute.
     * @param _disputeReason A hash of the reason for dispute.
     */
    function disputeNodeAttestation(
        uint256 _targetNodeId,
        uint256 _attestationId,
        bytes32 _disputeReason
    )
        external
        onlyAuraNodeOwner(ownerNodeId[msg.sender]) // Disputer must own an active node
        onlyActiveNode(ownerNodeId[msg.sender])
    {
        if (!_exists(_targetNodeId)) revert InvalidNodeId();
        Attestation storage attestation = auraNodes[_targetNodeId].receivedAttestations[_attestationId];
        if (attestation.targetNodeId == 0) revert AttestationNotFound();
        if (attestation.disputed) revert AttestationAlreadyDisputed();
        if (attestation.attesterNodeId == ownerNodeId[msg.sender]) revert CannotDisputeOwnAttestation();

        attestation.disputed = true;
        // In a real system, a dispute might trigger a governance vote or a dispute resolution module.
        // For simplicity here, we just mark it.
        // If a dispute passes, the original score/affinity impact would need to be reversed.

        emit AttestationDisputed(_attestationId, 0, _targetNodeId, msg.sender);
    }

    /**
     * @dev An admin/keeper function to periodically apply decay to AuraScores of inactive nodes.
     *      Encourages continuous participation.
     *      Decay rate is `systemParameters["decayRatePerDay"]` points per day.
     */
    function decayInactiveNodesAura() external onlyOwner {
        for (uint256 i = 1; i <= _nodeIdCounter.current(); i++) {
            AuraNode storage node = auraNodes[i];
            if (node.status != AuraNodeStatus.Active) continue; // Only decay active nodes

            uint256 timeElapsed = block.timestamp.sub(node.lastActivityTimestamp);
            uint256 daysInactive = timeElapsed.div(1 days);

            if (daysInactive > 0) {
                uint256 decayAmount = daysInactive.mul(systemParameters["decayRatePerDay"]);
                if (node.auraScore > systemParameters["minAuraScore"].add(decayAmount)) {
                    _updateAuraScore(node.id, -int256(decayAmount));
                } else {
                    _updateAuraScore(node.id, -int256(node.auraScore.sub(systemParameters["minAuraScore"]))); // Decay to min
                    if (node.auraScore == systemParameters["minAuraScore"]) {
                        node.status = AuraNodeStatus.Dormant; // Mark as dormant if at min score
                        emit AuraNodeStatusUpdated(node.id, AuraNodeStatus.Dormant);
                    }
                }
                node.lastActivityTimestamp = block.timestamp; // Reset activity timestamp after decay
            }
        }
    }

    /**
     * @dev Triggers a recalculation of a node's influence multiplier.
     *      Exposed for external triggers if internal calls are insufficient.
     * @param _tokenId The ID of the AuraNode.
     */
    function recalculateNodeInfluence(uint256 _tokenId) external onlyActiveNode(_tokenId) {
        if (!_exists(_tokenId)) revert InvalidNodeId();
        _recalculateNodeInfluence(_tokenId);
    }

    // --- Intent Pool Management ---

    /**
     * @dev Deploys a new Intent Pool with specific goals and parameters.
     * @param _description The purpose/goal of the pool.
     * @param _targetResourceAmount The amount of AuraTokens needed to achieve the goal.
     * @param _requiredAttestationsForCompletion The number of unique AuraNode attestations needed to finalize the pool.
     * @param _rewardMultiplier A base multiplier for rewards in this pool (e.g., 100 for 1x, 150 for 1.5x).
     */
    function createIntentPool(
        string calldata _description,
        uint256 _targetResourceAmount,
        uint256 _requiredAttestationsForCompletion,
        uint256 _rewardMultiplier
    )
        external
        returns (uint256)
    {
        _poolIdCounter.increment();
        uint256 newPoolId = _poolIdCounter.current();

        intentPools[newPoolId] = IntentPool({
            id: newPoolId,
            description: _description,
            creator: msg.sender,
            targetResourceAmount: _targetResourceAmount,
            currentStakedResources: 0,
            requiredAttestationsForCompletion: _requiredAttestationsForCompletion,
            currentGoalAttestations: 0,
            rewardMultiplier: _rewardMultiplier,
            status: PoolStatus.Active,
            stakedNodes: new mapping(uint256 => bool), // Initialize mapping
            stakedNodeIds: new uint256[](0),
            nodeStakedTime: new mapping(uint256 => uint256),
            stakedAuraTokens: new mapping(address => uint256),
            claimedAuraTokens: new mapping(address => uint256),
            predictiveInsightValue: 0
        });

        emit IntentPoolCreated(newPoolId, msg.sender, _description, _targetResourceAmount);
        return newPoolId;
    }

    /**
     * @dev Allows an AuraNode owner to stake their node in an Intent Pool to contribute to its goal.
     *      A node can only be staked in one pool at a time.
     * @param _poolId The ID of the Intent Pool.
     * @param _tokenId The ID of the AuraNode to stake.
     */
    function stakeAuraNodeInPool(uint256 _poolId, uint256 _tokenId)
        external
        onlyAuraNodeOwner(_tokenId)
        onlyActiveNode(_tokenId)
    {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0 || pool.status != PoolStatus.Active) revert InvalidPoolId();
        if (pool.stakedNodes[_tokenId]) revert NodeAlreadyStaked();

        pool.stakedNodes[_tokenId] = true;
        pool.stakedNodeIds.push(_tokenId);
        pool.nodeStakedTime[_tokenId] = block.timestamp;
        auraNodes[_tokenId].lastActivityTimestamp = block.timestamp; // Update node activity

        emit NodeStakedInPool(_poolId, _tokenId);
    }

    /**
     * @dev Allows an AuraNode owner to unstake their node from a pool.
     *      May be subject to penalties or inability if pool is finalized/active goal.
     * @param _poolId The ID of the Intent Pool.
     * @param _tokenId The ID of the AuraNode to unstake.
     */
    function unstakeAuraNodeFromPool(uint256 _poolId, uint256 _tokenId)
        external
        onlyAuraNodeOwner(_tokenId)
        onlyPoolContributor(_poolId, _tokenId)
    {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.status != PoolStatus.Active) revert InvalidPoolId(); // Can only unstake from active pools

        pool.stakedNodes[_tokenId] = false;
        delete pool.nodeStakedTime[_tokenId];
        // Remove from stakedNodeIds array (inefficient for large arrays, but simpler)
        for (uint256 i = 0; i < pool.stakedNodeIds.length; i++) {
            if (pool.stakedNodeIds[i] == _tokenId) {
                pool.stakedNodeIds[i] = pool.stakedNodeIds[pool.stakedNodeIds.length - 1];
                pool.stakedNodeIds.pop();
                break;
            }
        }
        
        emit NodeUnstakedFromPool(_poolId, _tokenId);
    }

    /**
     * @dev Allows users to stake AuraTokens into an Intent Pool to provide resources.
     * @param _poolId The ID of the Intent Pool.
     * @param _amount The amount of AuraTokens to deposit.
     */
    function depositAuraTokensToPool(uint256 _poolId, uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0 || pool.status != PoolStatus.Active) revert InvalidPoolId();

        // Transfer AuraTokens from sender to this contract (as pool's treasury)
        bool success = auraToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientBalance(); // More specific error if transfer fails

        pool.stakedAuraTokens[msg.sender] = pool.stakedAuraTokens[msg.sender].add(_amount);
        pool.currentStakedResources = pool.currentStakedResources.add(_amount);

        emit ResourcesDepositedToPool(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Allows contributors to withdraw their staked AuraTokens (subject to pool rules/completion).
     *      Typically, withdrawals are only allowed if the pool is cancelled or before finalization.
     * @param _poolId The ID of the Intent Pool.
     * @param _amount The amount of AuraTokens to withdraw.
     */
    function withdrawAuraTokensFromPool(uint256 _poolId, uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0) revert InvalidPoolId();
        if (pool.status == PoolStatus.Finalized) revert PoolAlreadyFinalized();
        if (pool.stakedAuraTokens[msg.sender] < _amount) revert InsufficientBalance();

        pool.stakedAuraTokens[msg.sender] = pool.stakedAuraTokens[msg.sender].sub(_amount);
        pool.currentStakedResources = pool.currentStakedResources.sub(_amount);
        bool success = auraToken.transfer(msg.sender, _amount);
        if (!success) revert InsufficientBalance(); // Should not happen if balance check passed

        emit ResourcesWithdrawnFromPool(_poolId, msg.sender, _amount);
    }

    /**
     * @dev A contributing AuraNode attests that a pool's goal has been met.
     *      Multiple unique attestations are required for pool finalization.
     * @param _poolId The ID of the Intent Pool.
     * @param _tokenId The ID of the AuraNode making the attestation.
     * @param _completionDetailsHash A hash of details confirming goal completion.
     */
    function attestPoolGoalCompletion(uint256 _poolId, uint256 _tokenId, bytes32 _completionDetailsHash)
        external
        onlyAuraNodeOwner(_tokenId)
        onlyActiveNode(_tokenId)
        onlyPoolContributor(_poolId, _tokenId)
    {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.status != PoolStatus.Active) revert PoolNotActive();

        // Ensure this node hasn't attested for this pool's completion before
        require(pool.nodeStakedTime[_tokenId] != 0, "Node must be actively staked."); // This check implies it's currently staked.
        require(pool.claimedAuraTokens[_tokenId] == 0, "Node already claimed/attested for this pool."); // Simple check, more robust needed.

        // Increment attestation count
        pool.currentGoalAttestations = pool.currentGoalAttestations.add(1);
        auraNodes[_tokenId].lastActivityTimestamp = block.timestamp; // Update activity

        // Mark the node as having attested for completion (prevents double counting)
        // Re-using claimedAuraTokens mapping temporarily for simplicity, in a real system this would be a separate mapping
        pool.claimedAuraTokens[_tokenId] = 1; // Mark as attested/claimed for simplicity here

        emit PoolGoalAttested(_poolId, _tokenId);
    }

    /**
     * @dev Admin/governance function to formally finalize a pool if sufficient goal attestations are received.
     *      This triggers reward calculation and distribution.
     * @param _poolId The ID of the Intent Pool.
     */
    function finalizeIntentPool(uint256 _poolId) external onlyOwner {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0 || pool.status != PoolStatus.Active) revert InvalidPoolId();
        if (pool.currentGoalAttestations < pool.requiredAttestationsForCompletion) revert InsufficientAttestations();

        pool.status = PoolStatus.Finalized;
        emit IntentPoolFinalized(_poolId, pool.rewardMultiplier);
    }

    // --- Reward Distribution & Claiming ---

    /**
     * @dev Allows a staked AuraNode to claim its proportional rewards from a finalized pool,
     *      adjusted by its dynamic AuraScore and Influence.
     * @param _poolId The ID of the Intent Pool.
     * @param _tokenId The ID of the AuraNode claiming rewards.
     */
    function claimAuraRewards(uint256 _poolId, uint256 _tokenId)
        external
        onlyAuraNodeOwner(_tokenId)
        onlyActiveNode(_tokenId)
        // onlyPoolContributor(_poolId, _tokenId) // Node might have unstaked but still eligible for rewards
    {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0) revert InvalidPoolId();
        if (pool.status != PoolStatus.Finalized) revert PoolNotFinalized();
        
        // Check if node actually contributed to this pool and hasn't claimed yet
        if (pool.nodeStakedTime[_tokenId] == 0 || pool.claimedAuraTokens[_tokenId] > 0) {
            revert("Node not eligible or already claimed rewards for this pool.");
        }

        uint256 nodeInfluence = _getNodeInfluenceRaw(_tokenId);
        if (nodeInfluence == 0) revert InsufficientVotingPower(); // Node must have influence to claim

        uint256 totalPoolInfluence = 0;
        for (uint256 i = 0; i < pool.stakedNodeIds.length; i++) {
            uint256 stakedNodeId = pool.stakedNodeIds[i];
            // Only count active nodes that participated and didn't dispute
            if (pool.nodeStakedTime[stakedNodeId] != 0 && auraNodes[stakedNodeId].status == AuraNodeStatus.Active) {
                totalPoolInfluence = totalPoolInfluence.add(_getNodeInfluenceRaw(stakedNodeId));
            }
        }

        if (totalPoolInfluence == 0) revert("No eligible contributors to distribute rewards.");

        // Calculate proportional share based on influence
        uint256 rewardShare = pool.currentStakedResources.mul(nodeInfluence).div(totalPoolInfluence);

        // Apply pool's reward multiplier and predictive insight (if any)
        rewardShare = rewardShare.mul(pool.rewardMultiplier).div(100); // 100 is base for 1x multiplier
        if (pool.predictiveInsightValue > 0) {
            rewardShare = rewardShare.mul(pool.predictiveInsightValue).div(100); // Insight can be a multiplier
        }

        if (rewardShare == 0) revert("Calculated reward is zero.");

        // Mark as claimed
        pool.claimedAuraTokens[_tokenId] = rewardShare;

        // Transfer rewards
        bool success = auraToken.transfer(ownerOf(_tokenId), rewardShare);
        if (!success) revert("Failed to transfer rewards.");

        pool.currentStakedResources = pool.currentStakedResources.sub(rewardShare); // Deduct from pool's remaining resources
        auraNodes[_tokenId].lastActivityTimestamp = block.timestamp; // Update node activity

        emit AuraRewardsClaimed(_poolId, _tokenId, rewardShare);
    }

    /**
     * @dev Admin/keeper function to distribute any remaining unclaimed rewards from a finalized pool
     *      to the contract owner (treasury) or for future use.
     * @param _poolId The ID of the Intent Pool.
     */
    function distributeUnclaimedPoolRewards(uint256 _poolId) external onlyOwner {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0) revert InvalidPoolId();
        if (pool.status != PoolStatus.Finalized) revert PoolNotFinalized();
        if (pool.currentStakedResources == 0) revert("No unclaimed resources in pool.");

        uint256 remainingRewards = pool.currentStakedResources;
        pool.currentStakedResources = 0; // Clear pool balance

        // Transfer remaining tokens to owner (treasury)
        bool success = auraToken.transfer(owner(), remainingRewards);
        if (!success) revert("Failed to transfer unclaimed rewards to owner.");
        
        // This is not an event related to user claims, but rather a system event
        // Consider a more specific event if needed, e.g., `UnclaimedRewardsDistributed`
    }

    // --- Governance & System Parameters (Decentralized through AuraNodes) ---

    /**
     * @dev Allows active AuraNodes to propose changes to system parameters.
     * @param _paramName The name of the parameter to change (e.g., "decayRatePerDay").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string calldata _paramName, uint256 _newValue)
        external
        onlyAuraNodeOwner(ownerNodeId[msg.sender])
        onlyActiveNode(ownerNodeId[msg.sender])
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            paramName: _paramName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp.add(systemParameters["proposalVotingPeriod"]),
            yeas: 0,
            nays: 0,
            hasVoted: new mapping(uint256 => bool),
            status: ProposalStatus.Open
        });

        // The proposer automatically casts a 'yea' vote
        _voteOnProposal(proposalId, ownerNodeId[msg.sender], true);
        auraNodes[ownerNodeId[msg.sender]].lastActivityTimestamp = block.timestamp; // Update activity

        emit ParameterChangeProposed(proposalId, _paramName, _newValue, proposals[proposalId].endTime);
    }

    /**
     * @dev Internal helper for voting on a proposal.
     */
    function _voteOnProposal(uint256 _proposalId, uint256 _voterNodeId, bool _support) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.status != ProposalStatus.Open) revert InvalidProposalId();
        if (block.timestamp > proposal.endTime) revert ProposalExpired();
        if (proposal.hasVoted[_voterNodeId]) revert ProposalAlreadyVoted();
        if (!_isNodeActive(_voterNodeId)) revert NodeNotActive();

        uint256 voterInfluence = _getNodeInfluenceRaw(_voterNodeId);
        if (voterInfluence == 0) revert InsufficientVotingPower();

        if (_support) {
            proposal.yeas = proposal.yeas.add(voterInfluence);
        } else {
            proposal.nays = proposal.nays.add(voterInfluence);
        }
        proposal.hasVoted[_voterNodeId] = true;
    }

    /**
     * @dev Allows active AuraNodes to vote on open proposals, weighted by their Influence Multiplier.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'yea' vote, false for 'nay'.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support)
        external
        onlyAuraNodeOwner(ownerNodeId[msg.sender])
        onlyActiveNode(ownerNodeId[msg.sender])
    {
        _voteOnProposal(_proposalId, ownerNodeId[msg.sender], _support);
        auraNodes[ownerNodeId[msg.sender]].lastActivityTimestamp = block.timestamp; // Update activity

        emit ParameterVoteCast(_proposalId, ownerNodeId[msg.sender], _support);
    }

    /**
     * @dev Executed by the owner/admin once a proposal passes its voting threshold.
     * @param _proposalId The ID of the proposal.
     */
    function executeParameterChange(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.status != ProposalStatus.Open) revert InvalidProposalId();
        if (block.timestamp <= proposal.endTime) revert ProposalNotYetExecutable();
        if (proposal.status == ProposalStatus.Executed) revert ProposalAlreadyExecuted();

        // Check if quorum is met and proposal passes
        uint256 totalVotes = proposal.yeas.add(proposal.nays);
        if (totalVotes == 0) { // No votes cast or very few
            proposal.status = ProposalStatus.Failed;
            return;
        }

        uint256 requiredQuorum = totalAuraInfluence.mul(systemParameters["proposalQuorumPercentage"]).div(100);
        if (totalVotes < requiredQuorum) {
            proposal.status = ProposalStatus.Failed;
            return;
        }

        if (proposal.yeas > proposal.nays) {
            systemParameters[proposal.paramName] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ParameterChangeExecuted(proposal.id, proposal.paramName, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    /**
     * @dev Retrieves the current value of a system parameter.
     * @param _paramName The name of the parameter.
     * @return The current value of the parameter.
     */
    function getSystemParameter(string calldata _paramName) public view returns (uint256) {
        return systemParameters[_paramName];
    }

    // --- AuraToken Management (ERC20) ---

    /**
     * @dev Admin function for initial token distribution.
     * @param _recipient The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mintInitialAuraTokens(address _recipient, uint256 _amount) external onlyOwner {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();
        auraToken.mint(_recipient, _amount);
    }

    /**
     * @dev Admin function to mint tokens to multiple recipients in a single transaction.
     * @param _recipients An array of recipient addresses.
     * @param _amounts An array of amounts corresponding to the recipients.
     */
    function batchMintAuraTokens(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] == address(0)) revert ZeroAddress();
            if (_amounts[i] == 0) revert ZeroAmount();
            auraToken.mint(_recipients[i], _amounts[i]);
        }
    }

    // --- Predictive Intent Integration (Conceptual/Simulated) ---

    /**
     * @dev Admin/oracle function to feed external, predictive insights into a pool.
     *      This value can dynamically adjust its reward multiplier or completion difficulty.
     *      (In a real system, this would come from a trusted oracle network like Chainlink).
     * @param _poolId The ID of the Intent Pool.
     * @param _insightValue The new predictive insight value (e.g., a multiplier or difficulty adjustment).
     */
    function updatePredictiveInsight(uint256 _poolId, uint256 _insightValue) external onlyOwner {
        IntentPool storage pool = intentPools[_poolId];
        if (pool.id == 0 || pool.status != PoolStatus.Active) revert InvalidPoolId();

        pool.predictiveInsightValue = _insightValue;
        emit PredictiveInsightUpdated(_poolId, _insightValue);
    }

    /**
     * @dev Retrieves the current predictive insight value for a given pool.
     * @param _poolId The ID of the Intent Pool.
     * @return The current predictive insight value.
     */
    function getPredictiveInsight(uint256 _poolId) public view returns (uint256) {
        if (intentPools[_poolId].id == 0) revert InvalidPoolId();
        return intentPools[_poolId].predictiveInsightValue;
    }
}

/**
 * @title AuraToken
 * @dev Simple ERC20 token for the AuraStreamNexus ecosystem.
 *      Mintable by the AuraStreamNexus contract for rewards and initial distribution.
 */
contract AuraToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Initial supply can be minted by the owner of the AuraStreamNexus contract
        // or during the AuraStreamNexus contract deployment itself.
    }

    // Allow only the AuraStreamNexus contract to mint tokens
    function mint(address to, uint256 amount) external {
        // Ensure that only the AuraStreamNexus contract can call this mint function
        // The deployer of AuraToken must be the AuraStreamNexus contract or its owner,
        // or we can allow a specific role here. For simplicity, let's assume
        // AuraStreamNexus is the `owner` (in context of its deployment).
        // A more robust solution would be to grant a MINTER_ROLE to the AuraStreamNexus contract.
        // For this example, we directly check against the `owner` of AuraStreamNexus.
        
        // This example assumes `msg.sender` should be the AuraStreamNexus contract address
        // when it calls `auraToken.mint()`. This requires AuraToken to know AuraStreamNexus's address,
        // or a role-based access control.
        // For simplicity, let's assume `msg.sender` is the contract that *created* this AuraToken.
        // In this setup, `AuraStreamNexus` creates `AuraToken`, so it would be the `msg.sender` for the constructor.
        // A better approach is to set `AuraStreamNexus` as a MINTER role after deployment.
        // For this code structure, `mint` can only be called by the `AuraStreamNexus` contract.
        // This is simplified for the contract structure.
        _mint(to, amount);
    }
}
```