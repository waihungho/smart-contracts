This is an ambitious request, and I love the challenge! We'll design a contract called "GenesisNexus Collective" – a decentralized, self-evolving collective where participants (represented by dynamic NFTs) cultivate on-chain reputation, contribute to a regenerative fund, and influence resource allocation based on verifiable impact.

The core idea is: **Dynamic, Self-Evolving Digital Entities (NFTs) driven by On-Chain Reputation and Off-Chain Verifiable Impact, collectively funding Regenerative Initiatives.**

This design aims to be unique by intertwining:
1.  **Dynamic NFTs:** Node attributes (visuals, "power level") change based on on-chain actions and reputation.
2.  **Reputation System:** Multi-faceted (score, karma, decay, verifiable claims).
3.  **Oracle Integration:** For verifiable external data (e.g., impact reports, real-world achievements).
4.  **Regenerative Finance:** A mechanism for collectively funding positive-impact projects.
5.  **Gamified Mechanics:** Node evolution, karma redemption, activity tracking.
6.  **Modular & Upgradable:** Designed with future expansion in mind.

---

## GenesisNexus Collective Smart Contract

**Contract Name:** `GenesisNexusCollective`

**Description:**
The `GenesisNexusCollective` is a pioneering decentralized autonomous collective where participants interact through unique, dynamic NFTs called "Nodes." Each Node possesses a mutable `reputationScore` and `karmaPoints` that evolve based on on-chain activity, verifiable claims, and participation in the collective's governance. The collective's primary objective is to cultivate a regenerative fund, allowing Nodes to propose, vote on, and fund real-world impact projects. Oracles play a crucial role in verifying external data and project impact, linking the on-chain collective to tangible, positive change in the world. The contract is designed to be upgradable, ensuring future adaptability.

**Core Concepts:**
*   **Dynamic Nodes (ERC721):** NFTs representing members, with attributes directly tied to their on-chain reputation and actions.
*   **Reputation Mechanics:** A sophisticated system involving a decayable `reputationScore`, redeemable `karmaPoints`, and oracle-verified `claims`.
*   **Regenerative Fund:** A communal pool of assets allocated to impact projects voted on by the Nodes.
*   **Oracle Integration:** Trusted entities (oracles) provide verifiable external data to influence Node reputation and project impact assessments.
*   **Tiered Evolution:** Nodes ascend through tiers based on reputation, unlocking new privileges and visual dynamism.
*   **Gamified Incentives:** Encouraging active participation through karma, reputation boosts, and node evolution.
*   **Role-Based Access Control:** Differentiating between owners, oracles, and managers for specific administrative tasks.

---

### Outline and Function Summary

**I. Core Components & Access Control**
*   `constructor`: Initializes the contract, setting the owner and initial parameters.
*   `addOracle(address _oracle)`: Grants oracle privileges to an address.
*   `removeOracle(address _oracle)`: Revokes oracle privileges.
*   `addManager(address _manager)`: Grants manager privileges (for operational aspects of the fund).
*   `removeManager(address _manager)`: Revokes manager privileges.
*   `pauseContract()`: Pauses the contract in emergencies.
*   `unpauseContract()`: Unpauses the contract.

**II. Node (ERC721) Management**
*   `mintGenesisNode(string memory _initialAttributesURI)`: Allows a new user to mint their first Node NFT, becoming part of the collective.
*   `evolveNodeTier(uint256 _nodeId)`: Allows a Node owner to trigger their Node's tier evolution if its reputation meets the threshold.
*   `updateNodeActivity(uint256 _nodeId)`: Marks a Node as active, resetting its activity cooldown and potentially earning Karma.
*   `burnDormantNode(uint256 _nodeId)`: Allows the owner or an authorized manager to burn a Node that has been dormant for an extended period, freeing up resources.
*   `transferNodeOwnership(address _from, address _to, uint256 _nodeId)`: Standard ERC721 transfer, but potentially with reputation implications. (Inherited from ERC721, but explicitly mentioned for context).
*   `proposeNodeAttributeType(string memory _attributeName)`: Allows any Node owner to propose a new dynamic attribute type for Nodes (e.g., 'wisdom', 'creativity'). Requires manager approval or collective vote.
*   `addNodeDynamicAttribute(uint256 _nodeId, string memory _attributeName, string memory _attributeValue)`: Oracles or managers can assign dynamic attributes to a Node, reflecting specific achievements or characteristics.
*   `getNodeDetails(uint256 _nodeId)`: Retrieves all core details of a specific Node.
*   `getNodeDynamicAttribute(uint256 _nodeId, string memory _attributeName)`: Retrieves a specific dynamic attribute for a Node.

**III. Reputation & Karma System**
*   `updateReputationScore(uint256 _nodeId, int256 _delta, string memory _reasonHash)`: Oracles can adjust a Node's reputation score based on verified external actions or impact.
*   `decayReputation(uint256 _nodeId)`: A mechanism (callable by anyone, incentivized by gas, or via keeper) to periodically decay a Node's reputation score if not actively maintained.
*   `distributeKarma(uint256 _nodeId, uint256 _amount, string memory _reasonHash)`: Oracles or managers can award Karma points for positive contributions.
*   `redeemKarmaForReputationBoost(uint256 _nodeId, uint256 _karmaAmount)`: Allows Node owners to spend Karma to receive a temporary boost to their reputation score.
*   `verifyClaimForNode(uint256 _nodeId, bytes32 _claimHash)`: Oracles verify an off-chain claim (e.g., participation in an event, real-world achievement) linked to a Node, which can then influence reputation.

**IV. Regenerative Fund & Project Governance**
*   `depositToFund()`: Allows anyone to contribute funds to the collective's regenerative treasury.
*   `proposeImpactProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal)`: Active Nodes can propose new impact projects for collective funding.
*   `voteOnProject(uint256 _projectId, bool _voteFor)`: Active Nodes with sufficient reputation can vote for or against proposed projects.
*   `executeProjectFunding(uint256 _projectId)`: After a successful vote and impact assessment, this function releases funds to a project.
*   `submitProjectImpactReport(uint256 _projectId, uint256 _impactScore, string memory _reportHash)`: Oracles submit verified impact reports for funded projects, influencing future funding decisions and collective reputation.
*   `updateProjectStatus(uint256 _projectId, ProjectStatus _newStatus)`: Managers or Oracles can update a project's status (e.g., InProgress, Completed, Failed).
*   `withdrawFundsAsManager(address _to, uint256 _amount)`: Allows a manager to withdraw funds for pre-approved, collective operational costs (highly restricted and auditable).

**V. System Configuration & Queries**
*   `setNodeMintPrice(uint256 _newPrice)`: Sets the price to mint a new Genesis Node.
*   `setReputationDecayRate(uint256 _newRate)`: Adjusts how quickly reputation decays.
*   `setNodeTierThresholds(uint256[] memory _newThresholds)`: Configures the reputation scores required for each Node tier.
*   `setNodeActivityCooldown(uint256 _newCooldown)`: Sets the minimum time between activity updates for a Node.
*   `getFundBalance()`: Retrieves the current balance of the regenerative fund.
*   `getProjectDetails(uint256 _projectId)`: Retrieves details of a specific impact project.
*   `isNodeActive(uint256 _nodeId)`: Checks if a Node is currently active (not dormant).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Custom Errors ---
error NodeNotFound(uint256 nodeId);
error NodeNotActive(uint256 nodeId);
error NodeReputationTooLow(uint256 nodeId, uint256 currentRep, uint256 requiredRep);
error Unauthorized();
error InsufficientFunds(uint256 required, uint256 available);
error InvalidProjectStatus();
error ProjectNotFound(uint256 projectId);
error AlreadyVoted(uint256 projectId, uint256 nodeId);
error VotingPeriodExpired();
error InsufficientVotes();
error AlreadyVerified();
error InvalidAttributeName();
error NodeAlreadyActive(uint256 nodeId);
error NodeNotDormant(uint256 nodeId);
error CannotBurnActiveNode();
error NoKarmaToRedeem(uint256 nodeId);
error InsufficientKarma(uint256 nodeId, uint256 currentKarma, uint256 requiredKarma);
error NodeIsUpToDate(uint256 nodeId);

/**
 * @title GenesisNexusCollective
 * @dev A pioneering decentralized autonomous collective where participants interact through unique, dynamic NFTs (Nodes).
 * Each Node's reputation and attributes evolve based on on-chain activity and oracle-verified impact.
 * The collective funds real-world impact projects via a regenerative fund.
 * Designed for upgradability, allowing for future feature expansion.
 */
contract GenesisNexusCollective is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // NFT Node Data
    struct Node {
        address owner;
        uint256 nodeId; // ERC721 token ID
        uint256 reputationScore;
        uint256 karmaPoints;
        uint256 lastActivityTimestamp;
        uint256 tier; // 0 = Genesis, 1 = Ascendant, 2 = Luminary, etc.
        NodeStatus status; // Active, Dormant, Ascendant (awaiting evolution)
        mapping(string => string) dynamicAttributes; // Key-value pairs for dynamic properties
    }

    enum NodeStatus { Active, Dormant, Ascendant } // Ascendant means ready for evolution
    enum ProjectStatus { Proposed, Voting, Approved, Rejected, InProgress, Completed, Failed }

    // Project Data
    struct Project {
        uint256 projectId;
        string name;
        string description;
        address proposerAddress;
        uint256 proposerNodeId;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 impactScore; // Oracle-verified
        uint256 votingEndTime;
        ProjectStatus status;
        address recipientAddress; // Address to receive funds if approved
    }

    Counters.Counter private _nodeIds;
    Counters.Counter private _projectIds;

    mapping(uint256 => Node) public nodes;
    mapping(address => uint256) public nodeByOwner; // Tracks if an address owns a node (first node)
    mapping(uint256 => Project) public projects;
    mapping(address => bool) public oracles; // Addresses authorized to verify claims/impact
    mapping(address => bool) public managers; // Addresses authorized for specific operational tasks
    mapping(uint256 => mapping(uint256 => bool)) public nodeVotedForProject; // nodeId => projectId => hasVoted

    uint256 public genesisNodeMintPrice; // Price to mint a new Genesis Node
    uint256 public nodeActivityCooldown; // Time in seconds before a node can update activity again
    uint256 public reputationDecayRate; // Percentage (e.g., 100 = 1%) per decay period
    uint256 public constant REPUTATION_DECAY_PERIOD = 30 days; // How often reputation decays if not active
    uint256[] public nodeTierThresholds; // Reputation scores required for each tier (e.g., [1000, 5000, 10000])
    uint256 public constant PROJECT_VOTING_PERIOD = 7 days; // How long a project is open for voting
    uint256 public constant MIN_VOTING_NODES = 3; // Minimum number of nodes that must vote for a project to pass

    // Valid dynamic attribute types that can be added to nodes
    mapping(string => bool) public validNodeAttributeTypes;

    // --- Events ---
    event NodeMinted(uint256 indexed nodeId, address indexed owner, uint256 initialReputation);
    event NodeTierEvolved(uint256 indexed nodeId, uint256 newTier, uint256 newReputation);
    event NodeActivityUpdated(uint256 indexed nodeId, uint256 newTimestamp, uint256 karmaEarned);
    event NodeBurnt(uint256 indexed nodeId, address indexed owner);
    event ReputationUpdated(uint256 indexed nodeId, int256 delta, uint256 newReputation, string reasonHash);
    event KarmaDistributed(uint256 indexed nodeId, uint256 amount, uint256 newKarma, string reasonHash);
    event KarmaRedeemed(uint256 indexed nodeId, uint256 karmaAmount, uint256 reputationBoost);
    event ClaimVerified(uint256 indexed nodeId, bytes32 indexed claimHash, address indexed oracle);
    event FundDeposited(address indexed depositor, uint256 amount, uint256 newBalance);
    event ProjectProposed(uint256 indexed projectId, uint256 indexed proposerNodeId, string name, uint256 fundingGoal);
    event ProjectVoted(uint256 indexed projectId, uint256 indexed nodeId, bool voteFor);
    event ProjectFundingExecuted(uint256 indexed projectId, uint256 amountFunded);
    event ProjectImpactReported(uint256 indexed projectId, uint256 impactScore, string reportHash, address indexed oracle);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event NodeAttributeTypeProposed(string indexed attributeName, address indexed proposer);
    event NodeDynamicAttributeAdded(uint256 indexed nodeId, string indexed attributeName, string attributeValue);
    event NodeMintPriceSet(uint256 newPrice);
    event ReputationDecayRateSet(uint256 newRate);
    event NodeTierThresholdsSet(uint256[] newThresholds);
    event NodeActivityCooldownSet(uint256 newCooldown);

    // --- Constructor ---
    constructor(
        address initialOracle,
        address initialManager,
        uint256 _genesisNodeMintPrice,
        uint256 _nodeActivityCooldown,
        uint256 _reputationDecayRate,
        uint256[] memory _nodeTierThresholds
    ) ERC721("GenesisNexusNode", "GNN") Ownable(msg.sender) {
        if (initialOracle == address(0) || initialManager == address(0)) {
            revert Unauthorized(); // Ensure initial roles are valid
        }
        oracles[initialOracle] = true;
        managers[initialManager] = true;
        genesisNodeMintPrice = _genesisNodeMintPrice;
        nodeActivityCooldown = _nodeActivityCooldown;
        reputationDecayRate = _reputationDecayRate;
        nodeTierThresholds = _nodeTierThresholds; // Example: [1000, 5000, 10000] for T1, T2, T3
        _addOwnerAttribute(); // Add "owner" as a default valid attribute
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (!oracles[msg.sender]) revert Unauthorized();
        _;
    }

    modifier onlyManager() {
        if (!managers[msg.sender]) revert Unauthorized();
        _;
    }

    modifier onlyActiveNode(uint256 _nodeId) {
        if (nodes[_nodeId].owner == address(0)) revert NodeNotFound(_nodeId);
        if (nodes[_nodeId].owner != msg.sender) revert Unauthorized();
        if (nodes[_nodeId].status != NodeStatus.Active && nodes[_nodeId].status != NodeStatus.Ascendant) revert NodeNotActive(_nodeId);
        _;
    }

    // --- Access Control & System Management ---

    /**
     * @dev Adds an address to the list of authorized oracles.
     * Only the contract owner can call this.
     * @param _oracle The address to grant oracle privileges.
     */
    function addOracle(address _oracle) external onlyOwner {
        oracles[_oracle] = true;
    }

    /**
     * @dev Removes an address from the list of authorized oracles.
     * Only the contract owner can call this.
     * @param _oracle The address to revoke oracle privileges from.
     */
    function removeOracle(address _oracle) external onlyOwner {
        oracles[_oracle] = false;
    }

    /**
     * @dev Adds an address to the list of authorized managers.
     * Managers can perform specific operational tasks like executing funding.
     * Only the contract owner can call this.
     * @param _manager The address to grant manager privileges.
     */
    function addManager(address _manager) external onlyOwner {
        managers[_manager] = true;
    }

    /**
     * @dev Removes an address from the list of authorized managers.
     * Only the contract owner can call this.
     * @param _manager The address to revoke manager privileges from.
     */
    function removeManager(address _manager) external onlyOwner {
        managers[_manager] = false;
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Only the contract owner or an authorized pauser can call this.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Only the contract owner or an authorized pauser can call this.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the price required to mint a new Genesis Node.
     * Only the contract owner can call this.
     * @param _newPrice The new mint price in wei.
     */
    function setNodeMintPrice(uint256 _newPrice) external onlyOwner {
        genesisNodeMintPrice = _newPrice;
        emit NodeMintPriceSet(_newPrice);
    }

    /**
     * @dev Sets the rate at which Node reputation decays per period.
     * (e.g., 100 for 1%, 500 for 5%)
     * Only the contract owner can call this.
     * @param _newRate The new reputation decay rate percentage (multiplied by 100).
     */
    function setReputationDecayRate(uint256 _newRate) external onlyOwner {
        reputationDecayRate = _newRate;
        emit ReputationDecayRateSet(_newRate);
    }

    /**
     * @dev Sets the reputation score thresholds required for Nodes to evolve to higher tiers.
     * The array must be sorted in ascending order.
     * Only the contract owner can call this.
     * @param _newThresholds An array of reputation scores for each tier.
     */
    function setNodeTierThresholds(uint256[] memory _newThresholds) external onlyOwner {
        nodeTierThresholds = _newThresholds;
        emit NodeTierThresholdsSet(_newThresholds);
    }

    /**
     * @dev Sets the cooldown period for updating Node activity.
     * Only the contract owner can call this.
     * @param _newCooldown The new cooldown period in seconds.
     */
    function setNodeActivityCooldown(uint256 _newCooldown) external onlyOwner {
        nodeActivityCooldown = _newCooldown;
        emit NodeActivityCooldownSet(_newCooldown);
    }

    // --- Node (ERC721) Management ---

    /**
     * @dev Allows a user to mint their first Genesis Node NFT, becoming a member.
     * Requires payment equal to `genesisNodeMintPrice`.
     * @param _initialAttributesURI A URI pointing to initial (non-dynamic) metadata for the Node.
     */
    function mintGenesisNode(string memory _initialAttributesURI) external payable whenNotPaused {
        if (msg.value < genesisNodeMintPrice) revert InsufficientFunds(genesisNodeMintPrice, msg.value);
        if (nodeByOwner[msg.sender] != 0) revert("Node already owned by this address."); // Limit to one genesis node per owner directly linked.

        _nodeIds.increment();
        uint256 newTokenId = _nodeIds.current();

        Node storage newNode = nodes[newTokenId];
        newNode.owner = msg.sender;
        newNode.nodeId = newTokenId;
        newNode.reputationScore = 100; // Starting reputation
        newNode.karmaPoints = 50; // Starting karma
        newNode.lastActivityTimestamp = block.timestamp;
        newNode.tier = 0; // Genesis tier
        newNode.status = NodeStatus.Active;
        // Set dynamic attributes
        newNode.dynamicAttributes["creationTimestamp"] = Strings.toString(block.timestamp);
        newNode.dynamicAttributes["initialURI"] = _initialAttributesURI;
        newNode.dynamicAttributes["ownerAddress"] = Strings.toHexString(uint160(msg.sender), 20);

        _safeMint(msg.sender, newTokenId);
        nodeByOwner[msg.sender] = newTokenId; // Map owner to their genesis node ID

        emit NodeMinted(newTokenId, msg.sender, newNode.reputationScore);
    }

    /**
     * @dev Allows a Node owner to trigger their Node's tier evolution.
     * The Node's reputation must meet the threshold for the next tier.
     * This function should be called by the Node owner.
     * @param _nodeId The ID of the Node to evolve.
     */
    function evolveNodeTier(uint256 _nodeId) external onlyActiveNode(_nodeId) whenNotPaused {
        Node storage node = nodes[_nodeId];

        if (node.tier >= nodeTierThresholds.length) revert("Node already at max tier.");
        
        uint256 requiredReputation = nodeTierThresholds[node.tier];
        if (node.reputationScore < requiredReputation) {
            revert NodeReputationTooLow(_nodeId, node.reputationScore, requiredReputation);
        }

        node.tier++;
        node.status = NodeStatus.Ascendant; // Mark as ascendant, potentially triggering visual update off-chain
        node.reputationScore = node.reputationScore / 2 + (nodeTierThresholds[node.tier-1] / 10); // Reputation reset with a boost
        node.karmaPoints = node.karmaPoints + 100; // Bonus karma for evolving

        emit NodeTierEvolved(_nodeId, node.tier, node.reputationScore);
        // Off-chain systems would monitor this event to update NFT metadata/visuals
    }

    /**
     * @dev Marks a Node as active, resetting its activity cooldown and potentially earning Karma.
     * Can be called by the Node owner.
     * @param _nodeId The ID of the Node.
     */
    function updateNodeActivity(uint256 _nodeId) external onlyActiveNode(_nodeId) whenNotPaused {
        Node storage node = nodes[_nodeId];

        if (block.timestamp < node.lastActivityTimestamp + nodeActivityCooldown) {
            revert NodeAlreadyActive(_nodeId); // Node is already active enough
        }

        node.lastActivityTimestamp = block.timestamp;
        node.status = NodeStatus.Active; // Ensure status is active

        uint256 karmaEarned = 5; // Base karma for activity
        if (node.tier > 0) karmaEarned += node.tier * 2; // Tier bonus
        node.karmaPoints += karmaEarned;

        emit NodeActivityUpdated(_nodeId, block.timestamp, karmaEarned);
    }

    /**
     * @dev Allows the owner or an authorized manager to burn a Node that has been dormant for an extended period.
     * This helps clean up inactive nodes and potentially free up resources/token IDs (though not strictly necessary for ERC721).
     * @param _nodeId The ID of the Node to burn.
     */
    function burnDormantNode(uint256 _nodeId) external whenNotPaused {
        Node storage node = nodes[_nodeId];
        if (node.owner == address(0)) revert NodeNotFound(_nodeId);
        
        // Owner can burn their own node if dormant or if they choose
        bool canBurn = false;
        if (msg.sender == node.owner) {
            canBurn = true; // Owner can always burn their node
        } else if (managers[msg.sender] && node.status == NodeStatus.Dormant) {
            // Manager can only burn if the node is dormant AND owner hasn't acted in a very long time
            // For a real contract, define a much longer dormancy period for manager burn
            if (block.timestamp >= node.lastActivityTimestamp + (REPUTATION_DECAY_PERIOD * 5)) { // 5x the decay period
                 canBurn = true;
            }
        }
        
        if (!canBurn) revert CannotBurnActiveNode(); // Generic error for now, could be more specific

        _burn(_nodeId);
        delete nodeByOwner[node.owner]; // Remove the link if it was their primary node
        delete nodes[_nodeId]; // Clear node data

        emit NodeBurnt(_nodeId, node.owner);
    }

    /**
     * @dev Allows any Node owner to propose a new dynamic attribute type for Nodes.
     * This proposal needs to be approved by a manager or through collective governance.
     * For simplicity, this version requires manager approval.
     * @param _attributeName The name of the new attribute (e.g., "wisdom", "creativity").
     */
    function proposeNodeAttributeType(string memory _attributeName) external onlyActiveNode(nodeByOwner[msg.sender]) {
        // In a more complex system, this would trigger a DAO vote.
        // For this example, we'll assume manager approval is implicit or a separate function.
        // The owner of the contract (admin) or a manager would call `_addValidNodeAttributeType` after a proposal.
        emit NodeAttributeTypeProposed(_attributeName, msg.sender);
    }

    /**
     * @dev Internal function to add a valid dynamic attribute type.
     * Should be called after proposal and approval.
     */
    function _addValidNodeAttributeType(string memory _attributeName) internal onlyOwner {
        validNodeAttributeTypes[_attributeName] = true;
    }

    /**
     * @dev Oracles or Managers can assign dynamic attributes to a Node, reflecting specific achievements or characteristics.
     * This is how Nodes become truly dynamic.
     * @param _nodeId The ID of the Node to update.
     * @param _attributeName The name of the dynamic attribute. Must be a valid type.
     * @param _attributeValue The value for the attribute.
     */
    function addNodeDynamicAttribute(uint256 _nodeId, string memory _attributeName, string memory _attributeValue) external whenNotPaused {
        if (!oracles[msg.sender] && !managers[msg.sender]) revert Unauthorized();
        if (nodes[_nodeId].owner == address(0)) revert NodeNotFound(_nodeId);
        // Ensure the attribute type is a recognized/approved one
        if (!validNodeAttributeTypes[_attributeName]) revert InvalidAttributeName();

        nodes[_nodeId].dynamicAttributes[_attributeName] = _attributeValue;
        emit NodeDynamicAttributeAdded(_nodeId, _attributeName, _attributeValue);
        // Off-chain systems would monitor this event to update NFT metadata/visuals
    }

    /**
     * @dev Retrieves all core details of a specific Node.
     * @param _nodeId The ID of the Node.
     * @return Node struct containing all details.
     */
    function getNodeDetails(uint256 _nodeId) public view returns (Node memory) {
        if (nodes[_nodeId].owner == address(0)) revert NodeNotFound(_nodeId);
        return nodes[_nodeId];
    }

    /**
     * @dev Retrieves a specific dynamic attribute for a Node.
     * @param _nodeId The ID of the Node.
     * @param _attributeName The name of the attribute to retrieve.
     * @return The string value of the attribute.
     */
    function getNodeDynamicAttribute(uint256 _nodeId, string memory _attributeName) public view returns (string memory) {
        if (nodes[_nodeId].owner == address(0)) revert NodeNotFound(_nodeId);
        return nodes[_nodeId].dynamicAttributes[_attributeName];
    }

    // --- Reputation & Karma System ---

    /**
     * @dev Oracles can adjust a Node's reputation score based on verified external actions or impact.
     * Positive delta for positive actions, negative for negative.
     * @param _nodeId The ID of the Node.
     * @param _delta The amount to change the reputation score by. Can be positive or negative.
     * @param _reasonHash A hash or identifier for the reason/source of the reputation change.
     */
    function updateReputationScore(uint256 _nodeId, int256 _delta, string memory _reasonHash) external onlyOracle whenNotPaused {
        Node storage node = nodes[_nodeId];
        if (node.owner == address(0)) revert NodeNotFound(_nodeId);

        if (_delta > 0) {
            node.reputationScore += uint256(_delta);
        } else {
            if (node.reputationScore < uint256(-_delta)) {
                node.reputationScore = 0; // Prevent underflow, set to 0 if delta is too large
            } else {
                node.reputationScore -= uint256(-_delta);
            }
        }
        // Keep reputation non-negative
        if (node.reputationScore < 0) node.reputationScore = 0;

        emit ReputationUpdated(_nodeId, _delta, node.reputationScore, _reasonHash);
    }

    /**
     * @dev A mechanism to periodically decay a Node's reputation score if not actively maintained.
     * Callable by anyone; gas costs could be incentivized off-chain or by a keeper network.
     * Only decays if `REPUTATION_DECAY_PERIOD` has passed since last activity.
     * @param _nodeId The ID of the Node to decay.
     */
    function decayReputation(uint256 _nodeId) external whenNotPaused {
        Node storage node = nodes[_nodeId];
        if (node.owner == address(0)) revert NodeNotFound(_nodeId);

        uint256 timeSinceLastActivity = block.timestamp - node.lastActivityTimestamp;
        if (timeSinceLastActivity < REPUTATION_DECAY_PERIOD) {
            revert NodeIsUpToDate(_nodeId); // Not enough time passed for decay
        }

        uint256 decayPeriods = timeSinceLastActivity / REPUTATION_DECAY_PERIOD;
        uint256 decayAmount = (node.reputationScore * reputationDecayRate * decayPeriods) / 10000; // reputation / 100 * rate / 100
        
        if (node.reputationScore <= decayAmount) {
            node.reputationScore = 0;
            node.status = NodeStatus.Dormant; // Mark as dormant if reputation hits zero
        } else {
            node.reputationScore -= decayAmount;
        }
        
        node.lastActivityTimestamp = block.timestamp; // Update timestamp to prevent immediate re-decay
        
        emit ReputationUpdated(_nodeId, -int256(decayAmount), node.reputationScore, "reputation_decay");
    }

    /**
     * @dev Oracles or managers can award Karma points for positive contributions.
     * Karma is a soft currency that can be redeemed for boosts.
     * @param _nodeId The ID of the Node to award Karma to.
     * @param _amount The amount of Karma to distribute.
     * @param _reasonHash A hash or identifier for the reason/source of the Karma.
     */
    function distributeKarma(uint256 _nodeId, uint256 _amount, string memory _reasonHash) external whenNotPaused {
        if (!oracles[msg.sender] && !managers[msg.sender]) revert Unauthorized();
        Node storage node = nodes[_nodeId];
        if (node.owner == address(0)) revert NodeNotFound(_nodeId);

        node.karmaPoints += _amount;
        emit KarmaDistributed(_nodeId, _amount, node.karmaPoints, _reasonHash);
    }

    /**
     * @dev Allows Node owners to spend Karma to receive a temporary boost to their reputation score.
     * This provides a utility for Karma points.
     * @param _nodeId The ID of the Node.
     * @param _karmaAmount The amount of Karma to redeem.
     */
    function redeemKarmaForReputationBoost(uint256 _nodeId, uint256 _karmaAmount) external onlyActiveNode(_nodeId) whenNotPaused {
        Node storage node = nodes[_nodeId];
        if (_karmaAmount == 0) revert NoKarmaToRedeem(_nodeId);
        if (node.karmaPoints < _karmaAmount) {
            revert InsufficientKarma(_nodeId, node.karmaPoints, _karmaAmount);
        }

        node.karmaPoints -= _karmaAmount;
        uint256 reputationBoost = _karmaAmount / 10; // Example: 10 Karma = 1 Reputation
        node.reputationScore += reputationBoost;

        emit KarmaRedeemed(_nodeId, _karmaAmount, reputationBoost);
        emit ReputationUpdated(_nodeId, int256(reputationBoost), node.reputationScore, "karma_redemption");
    }

    /**
     * @dev Oracles verify an off-chain claim (e.g., participation in an event, real-world achievement)
     * linked to a Node. This claim can then influence reputation or unlock other features.
     * @param _nodeId The ID of the Node associated with the claim.
     * @param _claimHash A unique hash identifying the off-chain claim/proof.
     */
    function verifyClaimForNode(uint256 _nodeId, bytes32 _claimHash) external onlyOracle whenNotPaused {
        Node storage node = nodes[_nodeId];
        if (node.owner == address(0)) revert NodeNotFound(_nodeId);

        // A simple check, a real system would verify a more complex proof structure
        // This mapping tracks if a claim has already been verified for this node
        // (For a truly advanced system, this would be a more robust ZK-proof verification)
        if (node.dynamicAttributes[Strings.toHexString(uint256(uint160(_claimHash)), 32)] != "") { // Check if claimHash exists as an attribute
            revert AlreadyVerified();
        }

        // Add the claim as a dynamic attribute to the node, e.g., "claim_ABC123": "verified"
        addNodeDynamicAttribute(_nodeId, string(abi.encodePacked("claim_", Strings.toHexString(uint256(uint160(_claimHash)), 32))), "verified");

        // Optionally, immediately grant reputation/karma for a verified claim
        updateReputationScore(_nodeId, 50, "claim_verified");
        distributeKarma(_nodeId, 25, "claim_verified");

        emit ClaimVerified(_nodeId, _claimHash, msg.sender);
    }

    // --- Regenerative Fund & Project Governance ---

    /**
     * @dev Allows anyone to contribute funds to the collective's regenerative treasury.
     * These funds will be used for approved impact projects.
     */
    function depositToFund() external payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InsufficientFunds(1, 0); // Must send some value
        emit FundDeposited(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev Active Nodes can propose new impact projects for collective funding.
     * @param _projectName The name of the project.
     * @param _projectDescription A detailed description of the project.
     * @param _fundingGoal The amount of funds requested for the project.
     * @param _recipientAddress The address that will receive the funds if the project is approved.
     */
    function proposeImpactProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _fundingGoal,
        address _recipientAddress
    ) external onlyActiveNode(nodeByOwner[msg.sender]) whenNotPaused {
        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        projects[newProjectId] = Project({
            projectId: newProjectId,
            name: _projectName,
            description: _projectDescription,
            proposerAddress: msg.sender,
            proposerNodeId: nodeByOwner[msg.sender],
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            votesFor: 0,
            votesAgainst: 0,
            impactScore: 0,
            votingEndTime: block.timestamp + PROJECT_VOTING_PERIOD,
            status: ProjectStatus.Proposed,
            recipientAddress: _recipientAddress
        });

        emit ProjectProposed(newProjectId, nodeByOwner[msg.sender], _projectName, _fundingGoal);
    }

    /**
     * @dev Active Nodes with sufficient reputation can vote for or against proposed projects.
     * Voting power can be weighted by reputation.
     * @param _projectId The ID of the project to vote on.
     * @param _voteFor True to vote for, false to vote against.
     */
    function voteOnProject(uint256 _projectId, bool _voteFor) external onlyActiveNode(nodeByOwner[msg.sender]) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Proposed && project.status != ProjectStatus.Voting) revert InvalidProjectStatus();
        if (block.timestamp > project.votingEndTime) revert VotingPeriodExpired();
        if (nodeVotedForProject[nodeByOwner[msg.sender]][_projectId]) revert AlreadyVoted(_projectId, nodeByOwner[msg.sender]);

        // Reputation-weighted voting (example: 1 vote per 100 reputation points, min 1 vote)
        uint256 votingPower = nodes[nodeByOwner[msg.sender]].reputationScore / 100;
        if (votingPower == 0) votingPower = 1; // Minimum 1 vote

        if (_voteFor) {
            project.votesFor += votingPower;
        } else {
            project.votesAgainst += votingPower;
        }
        nodeVotedForProject[nodeByOwner[msg.sender]][_projectId] = true;

        // Transition project to Voting status if it's the first vote
        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Voting;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Proposed, ProjectStatus.Voting);
        }

        emit ProjectVoted(_projectId, nodeByOwner[msg.sender], _voteFor);
    }

    /**
     * @dev After a successful vote and optional impact assessment, this function
     * releases funds to a project. Requires manager or owner permission.
     * @param _projectId The ID of the project to fund.
     */
    function executeProjectFunding(uint256 _projectId) external onlyManager whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.Voting && project.status != ProjectStatus.Approved) revert InvalidProjectStatus();
        if (block.timestamp <= project.votingEndTime && project.status == ProjectStatus.Voting) revert("Voting period not over yet.");
        if (project.votesFor == 0 || project.votesFor <= project.votesAgainst) revert InsufficientVotes(); // Must have more votes for than against
        if (project.votesFor + project.votesAgainst < MIN_VOTING_NODES) revert InsufficientVotes(); // Ensure enough participation
        if (address(this).balance < project.fundingGoal) revert InsufficientFunds(project.fundingGoal, address(this).balance);

        // Final approval logic: Can be more complex (e.g., minimum percentage of total reputation)
        // For simplicity: requires more 'for' votes than 'against' and minimum participants.

        project.status = ProjectStatus.InProgress;
        project.currentFunding = project.fundingGoal;

        (bool success, ) = project.recipientAddress.call{value: project.fundingGoal}("");
        if (!success) {
            project.status = ProjectStatus.Failed; // Mark as failed if transfer fails
            revert("Failed to transfer funds to project recipient.");
        }

        emit ProjectFundingExecuted(_projectId, project.fundingGoal);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Voting, ProjectStatus.InProgress);
    }

    /**
     * @dev Oracles submit verified impact reports for funded projects, influencing future funding decisions and collective reputation.
     * This is crucial for the "regenerative" aspect.
     * @param _projectId The ID of the project.
     * @param _impactScore A numerical score representing the project's impact (e.g., 0-100).
     * @param _reportHash A hash or URI pointing to the detailed off-chain impact report.
     */
    function submitProjectImpactReport(uint256 _projectId, uint256 _impactScore, string memory _reportHash) external onlyOracle whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert ProjectNotFound(_projectId);
        if (project.status != ProjectStatus.InProgress) revert InvalidProjectStatus(); // Only report for in-progress projects

        project.impactScore = _impactScore;
        // Optionally, influence the proposer's reputation or the collective's overall standing based on impact
        updateReputationScore(project.proposerNodeId, int256(_impactScore / 2), "project_impact_report"); // Give half of impact score as reputation
        distributeKarma(project.proposerNodeId, _impactScore, "project_impact_bonus");

        project.status = ProjectStatus.Completed; // Assuming report signifies completion
        
        emit ProjectImpactReported(_projectId, _impactScore, _reportHash, msg.sender);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.InProgress, ProjectStatus.Completed);
    }

    /**
     * @dev Managers or Oracles can update a project's status (e.g., InProgress, Completed, Failed).
     * @param _projectId The ID of the project.
     * @param _newStatus The new status for the project.
     */
    function updateProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external whenNotPaused {
        if (!oracles[msg.sender] && !managers[msg.sender]) revert Unauthorized();
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert ProjectNotFound(_projectId);
        if (_newStatus == ProjectStatus.Proposed || _newStatus == ProjectStatus.Voting) revert InvalidProjectStatus(); // Cannot revert to these states manually

        ProjectStatus oldStatus = project.status;
        project.status = _newStatus;
        emit ProjectStatusUpdated(_projectId, oldStatus, _newStatus);
    }

    /**
     * @dev Allows a manager to withdraw funds for pre-approved, collective operational costs.
     * This function should be used with extreme caution and ideally linked to a separate, multi-sig approval process.
     * For this example, it's directly callable by a manager.
     * @param _to The address to send funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawFundsAsManager(address _to, uint252 _amount) external onlyManager whenNotPaused nonReentrant {
        if (address(this).balance < _amount) revert InsufficientFunds(_amount, address(this).balance);
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert("Failed to withdraw funds.");

        emit FundsWithdrawn(_to, _amount);
    }

    // --- Query Functions ---

    /**
     * @dev Returns the current balance of the regenerative fund.
     * @return The current balance in wei.
     */
    function getFundBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves details of a specific impact project.
     * @param _projectId The ID of the project.
     * @return Project struct containing all details.
     */
    function getProjectDetails(uint256 _projectId) public view returns (Project memory) {
        if (projects[_projectId].projectId == 0) revert ProjectNotFound(_projectId);
        return projects[_projectId];
    }

    /**
     * @dev Checks if a Node is currently considered 'active' based on its last activity timestamp.
     * @param _nodeId The ID of the Node.
     * @return True if the Node is active, false otherwise.
     */
    function isNodeActive(uint256 _nodeId) public view returns (bool) {
        Node storage node = nodes[_nodeId];
        if (node.owner == address(0)) return false; // Node doesn't exist
        return (block.timestamp < node.lastActivityTimestamp + nodeActivityCooldown);
    }

    /**
     * @dev Internal function to add the "ownerAddress" as a default valid attribute type.
     */
    function _addOwnerAttribute() private {
        validNodeAttributeTypes["ownerAddress"] = true;
        validNodeAttributeTypes["creationTimestamp"] = true;
        validNodeAttributeTypes["initialURI"] = true;
        validNodeAttributeTypes["reputationScore"] = true;
        validNodeAttributeTypes["karmaPoints"] = true;
        validNodeAttributeTypes["tier"] = true;
        validNodeAttributeTypes["status"] = true;
        validNodeAttributeTypes["lastActivityTimestamp"] = true;
        // These are examples; in a real dapp, a more sophisticated metadata resolver would handle dynamic attributes.
    }

    // --- ERC721 Overrides (Minimal for dynamic NFTs) ---
    // A real dApp would implement a more sophisticated tokenURI that fetches
    // dynamic attributes via an API and generates JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (nodes[tokenId].owner == address(0)) revert NodeNotFound(tokenId);
        // This is a placeholder. In a real dynamic NFT, this would point to an API
        // that dynamically generates metadata based on the Node's on-chain attributes.
        return string(abi.encodePacked("ipfs://YOUR_BASE_URI/", Strings.toString(tokenId), "/metadata.json"));
    }
}

```