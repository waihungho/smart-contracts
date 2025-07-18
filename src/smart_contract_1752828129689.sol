This Solidity smart contract, **CognitoNet**, envisions a decentralized knowledge and influence network. Users mint non-transferable "CognitoNodes" (akin to Soulbound Tokens) that represent their on-chain persona and expertise. These nodes can submit and curate "KnowledgeParticles" (data units), vote on their truthfulness and relevance, form connections with other nodes, and earn rewards based on their contributions and influence. The nodes themselves can evolve by gaining "Experience Points" (XP) and leveling up, enhancing their capabilities and influence.

The core idea is to create an on-chain reputation and knowledge graph that is self-regulating and economically incentivized, distinguishing itself by integrating dynamic SBTs, a decentralized content curation model, and a layered influence/reward system.

---

## **CognitoNet: Decentralized Knowledge & Influence Network**

### **Outline:**

1.  **Contract Overview**: Introduction to CognitoNet's purpose and core concepts.
2.  **State Variables**: Mappings, structs, and counters for managing nodes, particles, and connections.
3.  **Events**: For off-chain monitoring of significant actions.
4.  **Errors**: Custom error types for clearer feedback.
5.  **Access Control**: `Ownable` for contract administration, and custom modifiers for node-specific roles (e.g., Guardian).
6.  **Node Management (CognitoNode SBTs)**:
    *   Minting, updating domain, bonding/unbonding tokens, leveling up, deactivation.
7.  **Knowledge Particle Management**:
    *   Submitting new particles, voting on truth/relevance, disputing, and resolving disputes.
8.  **Network Dynamics & Connections**:
    *   Proposing, accepting, and breaking node connections.
9.  **Reputation & Rewards System**:
    *   XP granting, influence calculation (internal), and reward distribution/claiming.
10. **Read-Only / Utility Functions**:
    *   Fetching detailed information about nodes, particles, and connections.

### **Function Summary (Total: 23 Functions)**

**I. Core Setup & Administration**
1.  `constructor(address _rewardTokenAddress)`: Initializes the contract with the address of the ERC20 reward token.
2.  `updateRewardToken(address _newRewardTokenAddress)`: (Owner-only) Updates the address of the reward token.

**II. CognitoNode Management (SBT-like)**
3.  `mintCognitoNode(string calldata _initialDomainHash)`: Mints a new, non-transferable CognitoNode for the caller. Only one node per address.
4.  `updateNodeDomain(uint256 _nodeId, string calldata _newDomainHash)`: Allows a node owner to update their node's declared domain of expertise (limited updates).
5.  `bondTokensToNode(uint256 _nodeId, uint256 _amount)`: Allows a node owner to stake `CognitoRewardToken`s to boost their node's influence.
6.  `unbondTokensFromNode(uint256 _nodeId, uint256 _amount)`: Allows a node owner to unstake `CognitoRewardToken`s previously bonded.
7.  `levelUpNode(uint256 _nodeId)`: Allows a node owner to level up their node if sufficient XP is accumulated. Consumes XP.
8.  `deactivateNode(uint256 _nodeId)`: (Guardian/Owner) Deactivates a node, preventing it from participating in the network, typically for rule violations.
9.  `reactivateNode(uint256 _nodeId)`: (Guardian/Owner) Reactivates a previously deactivated node.

**III. Knowledge Particle Curation**
10. `submitKnowledgeParticle(uint256 _creatorNodeId, string calldata _contentHash, string calldata _topicTagHash)`: Allows a node to submit a new KnowledgeParticle (a piece of data/information).
11. `voteOnTruthfulness(uint256 _particleId, bool _isTrue)`: Allows a node to vote on the truthfulness of a KnowledgeParticle.
12. `voteOnRelevance(uint256 _particleId, uint8 _score)`: Allows a node to vote on the relevance of a KnowledgeParticle (score 1-10).
13. `disputeKnowledgeParticle(uint256 _particleId)`: Allows a node to formally dispute a KnowledgeParticle, requiring a stake.
14. `resolveDisputedParticle(uint256 _particleId, bool _isValid)`: (Guardian/Owner) Resolves a disputed KnowledgeParticle, distributing or burning dispute stakes.

**IV. Network Dynamics & Connections**
15. `proposeNodeConnection(uint256 _fromNodeId, uint256 _toNodeId, bytes32 _connectionType)`: Allows a node to propose a connection to another node.
16. `acceptNodeConnection(uint256 _proposalId)`: Allows the recipient node to accept a pending connection proposal.
17. `breakNodeConnection(uint256 _connectionId)`: Allows either party of a connection to break it.

**V. Reputation & Rewards**
18. `grantXP(uint256 _nodeId, uint256 _amount)`: (Owner/System) Grants Experience Points (XP) to a specific node for predefined achievements or contributions.
19. `distributeInfluenceRewards()`: Callable by anyone (permissionless), triggers the distribution of accumulated rewards to eligible nodes based on their influence. Includes a cooldown.
20. `claimNodeRewards(uint256 _nodeId)`: Allows a node owner to claim their accrued `CognitoRewardToken` rewards.

**VI. Read-Only / Utility**
21. `getMutableNodeInfo(uint256 _nodeId)`: Retrieves dynamic information about a CognitoNode.
22. `getKnowledgeParticleInfo(uint256 _particleId)`: Retrieves detailed information about a KnowledgeParticle.
23. `getNodeIdByOwner(address _owner)`: Retrieves the `nodeId` associated with a given wallet address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CognitoNet
 * @dev A decentralized knowledge and influence network built on evolving Soulbound Tokens (CognitoNodes).
 *      Users mint non-transferable CognitoNodes, which can submit KnowledgeParticles (data units),
 *      vote on their truthfulness/relevance, form connections, and earn rewards based on influence and contribution.
 *      Nodes gain XP and level up, enhancing their capabilities within the network.
 *
 * Outline:
 * 1.  Contract Overview: Introduction to CognitoNet's purpose and core concepts.
 * 2.  State Variables: Mappings, structs, and counters for managing nodes, particles, and connections.
 * 3.  Events: For off-chain monitoring of significant actions.
 * 4.  Errors: Custom error types for clearer feedback.
 * 5.  Access Control: Ownable for contract administration, and custom modifiers for node-specific roles (e.g., Guardian).
 * 6.  Node Management (CognitoNode SBTs): Minting, updating domain, bonding/unbonding tokens, leveling up, deactivation.
 * 7.  Knowledge Particle Management: Submitting new particles, voting on truth/relevance, disputing, and resolving disputes.
 * 8.  Network Dynamics & Connections: Proposing, accepting, and breaking node connections.
 * 9.  Reputation & Rewards System: XP granting, influence calculation (internal), and reward distribution/claiming.
 * 10. Read-Only / Utility Functions: Fetching detailed information about nodes, particles, and connections.
 */
contract CognitoNet is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public cognitoRewardToken; // ERC20 token used for staking and rewards

    uint256 public nextNodeId;
    uint256 public nextParticleId;
    uint256 public nextConnectionId;
    uint256 public nextConnectionProposalId;

    // CognitoNode represents an evolving Soulbound Token (SBT)
    struct CognitoNode {
        address owner;
        uint256 level;
        uint256 xp; // Experience points
        string domainHash; // IPFS hash representing the node's declared knowledge domain/expertise
        uint256 influenceScore; // Dynamically calculated based on contributions, bonds, level, etc.
        uint256 bondedTokens; // Amount of cognitoRewardToken staked by this node
        uint256 lastActivityTimestamp; // Timestamp of the last significant on-chain activity
        bool isActive; // Can be deactivated by Guardians/Owner for violations
        bool isGuardian; // Special status for dispute resolution and network oversight
        uint256 rewardsAccumulated; // Tokens waiting to be claimed by the node owner
    }

    // KnowledgeParticle represents a curated piece of information or data
    struct KnowledgeParticle {
        uint256 creatorNodeId;
        string contentHash; // IPFS hash of the actual knowledge content
        string topicTagHash; // IPFS hash representing topic classification/tags
        uint256 creationTimestamp;
        uint256 aggregateTruthScore; // Sum of influence-weighted truth votes
        uint256 aggregateRelevanceScore; // Influence-weighted average relevance score (1-10)
        bool isDisputed;
        uint256 disputeStakeAmount; // Amount of cognitoRewardToken staked to dispute this particle
        uint256 disputerNodeId; // The node that initiated the dispute
        uint256 resolvedByNodeId; // Guardian node that resolved the dispute (0 if not resolved)
        mapping(uint256 => bool) truthVotes; // nodeId => isTrue
        mapping(uint256 => uint8) relevanceVotes; // nodeId => score (1-10)
        mapping(uint256 => bool) hasVoted; // nodeId => true if voted on this particle
    }

    // NodeConnection represents a link between two CognitoNodes
    struct NodeConnection {
        uint256 fromNodeId;
        uint256 toNodeId;
        bytes32 connectionType; // e.g., keccak256("COLLABORATOR"), keccak256("MENTOR")
        uint256 strength; // Dynamic strength based on shared activity, endorsements
        uint256 timestamp;
        bool accepted; // True if the connection proposal has been accepted by toNode
    }

    struct ConnectionProposal {
        uint256 fromNodeId;
        uint256 toNodeId;
        bytes32 connectionType;
        uint256 timestamp;
    }

    mapping(uint256 => CognitoNode) public cognitoNodes;
    mapping(address => uint256) public ownerToNodeId; // Enforces one node per address
    mapping(uint256 => KnowledgeParticle) public knowledgeParticles;
    mapping(uint256 => NodeConnection) public nodeConnections;
    mapping(uint256 => ConnectionProposal) public connectionProposals;

    // XP thresholds for leveling up
    uint256[] public xpThresholds = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000]; // Level 0-9 thresholds

    // Reward distribution parameters
    uint256 public constant REWARD_DISTRIBUTION_INTERVAL = 7 days; // How often rewards can be distributed
    uint256 public lastRewardDistributionTimestamp;
    uint256 public totalInfluenceWeightedXP = 0; // Sum of (XP * Influence) for all active nodes

    // Dispute parameters
    uint256 public constant MIN_DISPUTE_STAKE = 1 ether; // Minimum token amount to stake for a dispute

    // --- Events ---

    event CognitoNodeMinted(uint256 indexed nodeId, address indexed owner, string domainHash);
    event NodeDomainUpdated(uint256 indexed nodeId, string newDomainHash);
    event TokensBonded(uint256 indexed nodeId, address indexed owner, uint256 amount);
    event TokensUnbonded(uint256 indexed nodeId, address indexed owner, uint256 amount);
    event NodeLeveledUp(uint256 indexed nodeId, uint256 newLevel);
    event NodeDeactivated(uint256 indexed nodeId, address indexed by);
    event NodeReactivated(uint256 indexed nodeId, address indexed by);
    event GuardianStatusChanged(uint256 indexed nodeId, bool isGuardian);

    event KnowledgeParticleSubmitted(uint256 indexed particleId, uint256 indexed creatorNodeId, string contentHash, string topicTagHash);
    event TruthVoteCasted(uint256 indexed particleId, uint256 indexed voterNodeId, bool isTrue);
    event RelevanceVoteCasted(uint256 indexed particleId, uint256 indexed voterNodeId, uint8 score);
    event KnowledgeParticleDisputed(uint256 indexed particleId, uint256 indexed disputerNodeId, uint256 stakeAmount);
    event KnowledgeParticleResolved(uint256 indexed particleId, uint256 indexed resolverNodeId, bool isValid);

    event ConnectionProposed(uint256 indexed proposalId, uint256 indexed fromNodeId, uint256 indexed toNodeId, bytes32 connectionType);
    event ConnectionAccepted(uint256 indexed connectionId, uint256 indexed fromNodeId, uint256 indexed toNodeId);
    event ConnectionBroken(uint256 indexed connectionId, uint256 indexed fromNodeId, uint256 indexed toNodeId);

    event XPGranted(uint256 indexed nodeId, uint256 amount);
    event RewardsDistributed(uint256 totalDistributedAmount);
    event RewardsClaimed(uint256 indexed nodeId, uint256 amount);

    // --- Errors ---

    error NodeAlreadyExists();
    error NodeNotFound();
    error NotNodeOwner();
    error NotActiveNode();
    error InvalidDomainHash();
    error InsufficientXP();
    error MaxLevelReached();
    error InsufficientBondAmount();
    error ExcessiveUnbondAmount();
    error SelfBondNotAllowed();
    error SelfConnectionNotAllowed();
    error ConnectionAlreadyExists();
    error NodeNotGuardian();
    error ParticleNotFound();
    error AlreadyVoted();
    error InvalidVoteScore();
    error ParticleNotDisputed();
    error ParticleAlreadyDisputed();
    error InsufficientDisputeStake();
    error InvalidConnectionProposal();
    error ConnectionProposalNotFound();
    error ConnectionNotAccepted();
    error InvalidResolveStatus();
    error RewardsNotAvailable();
    error RewardsCooldownActive(uint256 remainingTime);
    error NoRewardsToClaim();


    // --- Modifiers ---

    modifier onlyNodeOwner(uint256 _nodeId) {
        if (cognitoNodes[_nodeId].owner != msg.sender) revert NotNodeOwner();
        _;
    }

    modifier onlyActiveNode(uint256 _nodeId) {
        if (!cognitoNodes[_nodeId].isActive) revert NotActiveNode();
        _;
    }

    modifier onlyGuardian(uint256 _nodeId) {
        if (!cognitoNodes[_nodeId].isGuardian) revert NodeNotGuardian();
        _;
    }

    // --- Constructor ---

    constructor(address _rewardTokenAddress) Ownable(msg.sender) {
        require(_rewardTokenAddress != address(0), "Invalid reward token address");
        cognitoRewardToken = IERC20(_rewardTokenAddress);
        nextNodeId = 1; // Node IDs start from 1
        nextParticleId = 1; // Particle IDs start from 1
        nextConnectionId = 1; // Connection IDs start from 1
        nextConnectionProposalId = 1; // Connection proposal IDs start from 1
        lastRewardDistributionTimestamp = block.timestamp;
    }

    // --- I. Core Setup & Administration ---

    /**
     * @dev (Owner-only) Updates the address of the ERC20 reward token.
     * @param _newRewardTokenAddress The new address for the reward token contract.
     */
    function updateRewardToken(address _newRewardTokenAddress) external onlyOwner {
        require(_newRewardTokenAddress != address(0), "New reward token address cannot be zero.");
        cognitoRewardToken = IERC20(_newRewardTokenAddress);
    }

    /**
     * @dev (Owner-only) Sets or unsets a node as a Guardian. Guardians can resolve disputes and deactivate nodes.
     * @param _nodeId The ID of the node to modify.
     * @param _isGuardian True to set as Guardian, false to unset.
     */
    function setGuardianStatus(uint256 _nodeId, bool _isGuardian) external onlyOwner {
        require(_nodeId > 0 && _nodeId < nextNodeId, "Node does not exist.");
        cognitoNodes[_nodeId].isGuardian = _isGuardian;
        emit GuardianStatusChanged(_nodeId, _isGuardian);
    }

    // --- II. CognitoNode Management (SBT-like) ---

    /**
     * @dev Mints a new, non-transferable CognitoNode for the caller.
     *      Each address can only own one CognitoNode.
     * @param _initialDomainHash IPFS hash representing the node's initial declared knowledge domain.
     */
    function mintCognitoNode(string calldata _initialDomainHash) external {
        if (ownerToNodeId[msg.sender] != 0) revert NodeAlreadyExists();
        if (bytes(_initialDomainHash).length == 0) revert InvalidDomainHash();

        uint256 newNodeId = nextNodeId++;
        cognitoNodes[newNodeId] = CognitoNode({
            owner: msg.sender,
            level: 0,
            xp: 0,
            domainHash: _initialDomainHash,
            influenceScore: 0, // Calculated dynamically
            bondedTokens: 0,
            lastActivityTimestamp: block.timestamp,
            isActive: true,
            isGuardian: false,
            rewardsAccumulated: 0
        });
        ownerToNodeId[msg.sender] = newNodeId;
        emit CognitoNodeMinted(newNodeId, msg.sender, _initialDomainHash);
    }

    /**
     * @dev Allows a node owner to update their node's declared domain of expertise.
     * @param _nodeId The ID of the node to update.
     * @param _newDomainHash The new IPFS hash for the node's domain.
     */
    function updateNodeDomain(uint256 _nodeId, string calldata _newDomainHash) external onlyNodeOwner(_nodeId) onlyActiveNode(_nodeId) {
        if (bytes(_newDomainHash).length == 0) revert InvalidDomainHash();
        cognitoNodes[_nodeId].domainHash = _newDomainHash;
        cognitoNodes[_nodeId].lastActivityTimestamp = block.timestamp;
        emit NodeDomainUpdated(_nodeId, _newDomainHash);
    }

    /**
     * @dev Allows a node owner to stake CognitoRewardTokens to boost their node's influence.
     *      Tokens are transferred from the caller to this contract.
     * @param _nodeId The ID of the node to bond tokens to.
     * @param _amount The amount of tokens to bond.
     */
    function bondTokensToNode(uint256 _nodeId, uint256 _amount) external nonReentrant onlyNodeOwner(_nodeId) onlyActiveNode(_nodeId) {
        if (_amount == 0) revert InsufficientBondAmount();

        // Ensure the contract has allowance to pull tokens
        require(cognitoRewardToken.allowance(msg.sender, address(this)) >= _amount, "Check token allowance");
        require(cognitoRewardToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        cognitoNodes[_nodeId].bondedTokens = cognitoNodes[_nodeId].bondedTokens.add(_amount);
        cognitoNodes[_nodeId].lastActivityTimestamp = block.timestamp;
        emit TokensBonded(_nodeId, msg.sender, _amount);
    }

    /**
     * @dev Allows a node owner to unstake CognitoRewardTokens.
     *      Tokens are transferred from this contract back to the caller.
     * @param _nodeId The ID of the node to unbond tokens from.
     * @param _amount The amount of tokens to unbond.
     */
    function unbondTokensFromNode(uint256 _nodeId, uint256 _amount) external nonReentrant onlyNodeOwner(_nodeId) {
        if (_amount == 0 || cognitoNodes[_nodeId].bondedTokens < _amount) revert ExcessiveUnbondAmount();

        cognitoNodes[_nodeId].bondedTokens = cognitoNodes[_nodeId].bondedTokens.sub(_amount);
        cognitoNodes[_nodeId].lastActivityTimestamp = block.timestamp;
        require(cognitoRewardToken.transfer(msg.sender, _amount), "Token transfer failed");
        emit TokensUnbonded(_nodeId, msg.sender, _amount);
    }

    /**
     * @dev Allows a node owner to level up their node if sufficient XP is accumulated.
     *      XP is consumed upon leveling up.
     * @param _nodeId The ID of the node to level up.
     */
    function levelUpNode(uint256 _nodeId) external onlyNodeOwner(_nodeId) onlyActiveNode(_nodeId) {
        CognitoNode storage node = cognitoNodes[_nodeId];
        uint256 currentLevel = node.level;

        if (currentLevel >= xpThresholds.length - 1) revert MaxLevelReached();

        uint256 xpRequired = xpThresholds[currentLevel + 1];
        if (node.xp < xpRequired) revert InsufficientXP();

        node.xp = node.xp.sub(xpRequired); // Consume XP
        node.level = currentLevel.add(1);
        node.lastActivityTimestamp = block.timestamp;
        emit NodeLeveledUp(_nodeId, node.level);
    }

    /**
     * @dev (Guardian/Owner) Deactivates a node, preventing it from participating.
     *      Used for nodes violating network rules.
     * @param _nodeId The ID of the node to deactivate.
     */
    function deactivateNode(uint256 _nodeId) external {
        require(_nodeId > 0 && _nodeId < nextNodeId, "Node does not exist.");
        require(cognitoNodes[ownerToNodeId[msg.sender]].isGuardian || msg.sender == owner(), "Only Guardian or Owner can deactivate.");
        require(cognitoNodes[_nodeId].isActive, "Node is already inactive.");

        cognitoNodes[_nodeId].isActive = false;
        emit NodeDeactivated(_nodeId, msg.sender);
    }

    /**
     * @dev (Guardian/Owner) Reactivates a previously deactivated node.
     * @param _nodeId The ID of the node to reactivate.
     */
    function reactivateNode(uint256 _nodeId) external {
        require(_nodeId > 0 && _nodeId < nextNodeId, "Node does not exist.");
        require(cognitoNodes[ownerToNodeId[msg.sender]].isGuardian || msg.sender == owner(), "Only Guardian or Owner can reactivate.");
        require(!cognitoNodes[_nodeId].isActive, "Node is already active.");

        cognitoNodes[_nodeId].isActive = true;
        emit NodeReactivated(_nodeId, msg.sender);
    }

    // --- III. Knowledge Particle Curation ---

    /**
     * @dev Allows an active node to submit a new KnowledgeParticle.
     * @param _creatorNodeId The ID of the node submitting the particle.
     * @param _contentHash IPFS hash of the actual knowledge content.
     * @param _topicTagHash IPFS hash of topic classification/tags.
     */
    function submitKnowledgeParticle(
        uint256 _creatorNodeId,
        string calldata _contentHash,
        string calldata _topicTagHash
    ) external onlyNodeOwner(_creatorNodeId) onlyActiveNode(_creatorNodeId) {
        if (bytes(_contentHash).length == 0 || bytes(_topicTagHash).length == 0) revert ParticleNotFound(); // Using particle not found for invalid hashes

        uint256 newParticleId = nextParticleId++;
        knowledgeParticles[newParticleId] = KnowledgeParticle({
            creatorNodeId: _creatorNodeId,
            contentHash: _contentHash,
            topicTagHash: _topicTagHash,
            creationTimestamp: block.timestamp,
            aggregateTruthScore: 0,
            aggregateRelevanceScore: 0,
            isDisputed: false,
            disputeStakeAmount: 0,
            disputerNodeId: 0,
            resolvedByNodeId: 0,
            truthVotes: new mapping(uint256 => bool)(),
            relevanceVotes: new mapping(uint256 => uint8)(),
            hasVoted: new mapping(uint256 => bool)()
        });

        // Grant XP for contributing knowledge
        _grantXP(_creatorNodeId, 5); // Example XP value
        cognitoNodes[_creatorNodeId].lastActivityTimestamp = block.timestamp;
        emit KnowledgeParticleSubmitted(newParticleId, _creatorNodeId, _contentHash, _topicTagHash);
    }

    /**
     * @dev Allows an active node to vote on the truthfulness of a KnowledgeParticle.
     * @param _particleId The ID of the particle to vote on.
     * @param _isTrue True if the voter believes the particle is true, false otherwise.
     */
    function voteOnTruthfulness(uint256 _particleId, bool _isTrue) external onlyActiveNode(ownerToNodeId[msg.sender]) {
        KnowledgeParticle storage particle = knowledgeParticles[_particleId];
        if (particle.creatorNodeId == 0) revert ParticleNotFound();
        if (particle.hasVoted[ownerToNodeId[msg.sender]]) revert AlreadyVoted();

        particle.truthVotes[ownerToNodeId[msg.sender]] = _isTrue;
        particle.hasVoted[ownerToNodeId[msg.sender]] = true;
        // Logic to update aggregateTruthScore based on voter's influence will happen during reward distribution
        // or through a separate calculation function to save gas. For simplicity, direct update is omitted here.
        cognitoNodes[ownerToNodeId[msg.sender]].lastActivityTimestamp = block.timestamp;
        _grantXP(ownerToNodeId[msg.sender], 1); // Example XP for voting
        emit TruthVoteCasted(_particleId, ownerToNodeId[msg.sender], _isTrue);
    }

    /**
     * @dev Allows an active node to vote on the relevance of a KnowledgeParticle (score 1-10).
     * @param _particleId The ID of the particle to vote on.
     * @param _score The relevance score (1-10).
     */
    function voteOnRelevance(uint256 _particleId, uint8 _score) external onlyActiveNode(ownerToNodeId[msg.sender]) {
        KnowledgeParticle storage particle = knowledgeParticles[_particleId];
        if (particle.creatorNodeId == 0) revert ParticleNotFound();
        if (particle.hasVoted[ownerToNodeId[msg.sender]]) revert AlreadyVoted(); // Assuming a single vote type

        if (_score < 1 || _score > 10) revert InvalidVoteScore();

        particle.relevanceVotes[ownerToNodeId[msg.sender]] = _score;
        particle.hasVoted[ownerToNodeId[msg.sender]] = true;
        // Logic to update aggregateRelevanceScore based on voter's influence will happen during reward distribution
        cognitoNodes[ownerToNodeId[msg.sender]].lastActivityTimestamp = block.timestamp;
        _grantXP(ownerToNodeId[msg.sender], 1); // Example XP for voting
        emit RelevanceVoteCasted(_particleId, ownerToNodeId[msg.sender], _score);
    }

    /**
     * @dev Allows an active node to formally dispute a KnowledgeParticle, requiring a stake.
     *      The stake is held until a Guardian resolves the dispute.
     * @param _particleId The ID of the particle to dispute.
     */
    function disputeKnowledgeParticle(uint256 _particleId) external nonReentrant onlyActiveNode(ownerToNodeId[msg.sender]) {
        KnowledgeParticle storage particle = knowledgeParticles[_particleId];
        if (particle.creatorNodeId == 0) revert ParticleNotFound();
        if (particle.isDisputed) revert ParticleAlreadyDisputed();

        uint256 disputerNodeId = ownerToNodeId[msg.sender];
        if (disputerNodeId == particle.creatorNodeId) revert SelfBondNotAllowed(); // Cannot dispute own particle

        require(cognitoRewardToken.allowance(msg.sender, address(this)) >= MIN_DISPUTE_STAKE, "Check token allowance for dispute stake");
        require(cognitoRewardToken.transferFrom(msg.sender, address(this), MIN_DISPUTE_STAKE), "Dispute stake transfer failed");

        particle.isDisputed = true;
        particle.disputeStakeAmount = MIN_DISPUTE_STAKE;
        particle.disputerNodeId = disputerNodeId;
        cognitoNodes[disputerNodeId].lastActivityTimestamp = block.timestamp;
        emit KnowledgeParticleDisputed(_particleId, disputerNodeId, MIN_DISPUTE_STAKE);
    }

    /**
     * @dev (Guardian/Owner) Resolves a disputed KnowledgeParticle.
     *      If isValid is true, the disputer gets their stake back + bonus.
     *      If isValid is false, the disputer loses their stake (burned or distributed).
     * @param _particleId The ID of the particle to resolve.
     * @param _isValid True if the particle is deemed valid, false if invalid.
     */
    function resolveDisputedParticle(uint256 _particleId, bool _isValid) external nonReentrant {
        KnowledgeParticle storage particle = knowledgeParticles[_particleId];
        if (particle.creatorNodeId == 0) revert ParticleNotFound();
        if (!particle.isDisputed) revert ParticleNotDisputed();

        uint256 resolverNodeId = ownerToNodeId[msg.sender];
        if (!cognitoNodes[resolverNodeId].isGuardian && msg.sender != owner()) revert NotGuardian();

        particle.isDisputed = false; // Mark as resolved
        particle.resolvedByNodeId = resolverNodeId;
        cognitoNodes[resolverNodeId].lastActivityTimestamp = block.timestamp;

        if (!_isValid) {
            // Disputer was wrong, stake is burned or sent to a treasury/pool
            // For simplicity, let's burn it or send to owner for now
            cognitoRewardToken.transfer(owner(), particle.disputeStakeAmount); // Owner receives the stake
            _grantXP(resolverNodeId, 10); // Reward Guardian for correct resolution
            _grantXP(particle.creatorNodeId, 5); // Reward original creator if dispute was invalid
        } else {
            // Disputer was right, refund stake + bonus (example bonus: 10% of stake)
            uint256 rewardAmount = particle.disputeStakeAmount.add(particle.disputeStakeAmount.div(10));
            require(cognitoRewardToken.transfer(cognitoNodes[particle.disputerNodeId].owner, rewardAmount), "Failed to refund disputer stake");
            _grantXP(resolverNodeId, 10); // Reward Guardian for correct resolution
            _grantXP(particle.disputerNodeId, 15); // Reward disputer for accurate dispute
        }

        particle.disputeStakeAmount = 0; // Clear stake amount
        emit KnowledgeParticleResolved(_particleId, resolverNodeId, _isValid);
    }

    // --- IV. Network Dynamics & Connections ---

    /**
     * @dev Allows an active node to propose a connection to another active node.
     * @param _fromNodeId The ID of the proposing node.
     * @param _toNodeId The ID of the node to connect to.
     * @param _connectionType A bytes32 hash representing the type of connection (e.g., keccak256("COLLABORATOR")).
     */
    function proposeNodeConnection(
        uint256 _fromNodeId,
        uint256 _toNodeId,
        bytes32 _connectionType
    ) external onlyNodeOwner(_fromNodeId) onlyActiveNode(_fromNodeId) onlyActiveNode(_toNodeId) {
        if (_fromNodeId == _toNodeId) revert SelfConnectionNotAllowed();
        if (cognitoNodes[_toNodeId].owner == address(0)) revert NodeNotFound(); // Ensure target node exists

        // Prevent duplicate pending proposals
        for (uint256 i = 1; i < nextConnectionProposalId; i++) {
            ConnectionProposal storage existing = connectionProposals[i];
            if (existing.fromNodeId == _fromNodeId && existing.toNodeId == _toNodeId && existing.connectionType == _connectionType) {
                revert ConnectionAlreadyExists();
            }
        }

        // Prevent duplicate accepted connections (simplified check)
        for (uint256 i = 1; i < nextConnectionId; i++) {
            NodeConnection storage existingConn = nodeConnections[i];
            if (existingConn.accepted && existingConn.fromNodeId == _fromNodeId && existingConn.toNodeId == _toNodeId && existingConn.connectionType == _connectionType) {
                revert ConnectionAlreadyExists();
            }
        }

        uint256 newProposalId = nextConnectionProposalId++;
        connectionProposals[newProposalId] = ConnectionProposal({
            fromNodeId: _fromNodeId,
            toNodeId: _toNodeId,
            connectionType: _connectionType,
            timestamp: block.timestamp
        });
        cognitoNodes[_fromNodeId].lastActivityTimestamp = block.timestamp;
        emit ConnectionProposed(newProposalId, _fromNodeId, _toNodeId, _connectionType);
    }

    /**
     * @dev Allows the recipient node to accept a pending connection proposal.
     * @param _proposalId The ID of the connection proposal to accept.
     */
    function acceptNodeConnection(uint256 _proposalId) external onlyActiveNode(ownerToNodeId[msg.sender]) {
        ConnectionProposal storage proposal = connectionProposals[_proposalId];
        if (proposal.fromNodeId == 0) revert ConnectionProposalNotFound();
        if (proposal.toNodeId != ownerToNodeId[msg.sender]) revert InvalidConnectionProposal();

        uint256 newConnectionId = nextConnectionId++;
        nodeConnections[newConnectionId] = NodeConnection({
            fromNodeId: proposal.fromNodeId,
            toNodeId: proposal.toNodeId,
            connectionType: proposal.connectionType,
            strength: 1, // Initial strength
            timestamp: block.timestamp,
            accepted: true
        });

        // Clear the proposal after acceptance (optional, can also keep history)
        delete connectionProposals[_proposalId];
        cognitoNodes[proposal.toNodeId].lastActivityTimestamp = block.timestamp;
        _grantXP(proposal.fromNodeId, 2); // XP for successful connection initiation
        _grantXP(proposal.toNodeId, 2); // XP for accepting a connection
        emit ConnectionAccepted(newConnectionId, proposal.fromNodeId, proposal.toNodeId);
    }

    /**
     * @dev Allows either party of an accepted connection to break it.
     * @param _connectionId The ID of the connection to break.
     */
    function breakNodeConnection(uint256 _connectionId) external {
        NodeConnection storage connection = nodeConnections[_connectionId];
        if (connection.fromNodeId == 0) revert ConnectionNotFound();
        if (connection.ownerOf(connection.fromNodeId) != msg.sender && connection.ownerOf(connection.toNodeId) != msg.sender) {
            revert NotNodeOwner(); // Simplified, should be `ownerToNodeId[msg.sender]`
        }
        if (!connection.accepted) revert ConnectionNotAccepted();

        uint256 fromNode = connection.fromNodeId;
        uint256 toNode = connection.toNodeId;

        delete nodeConnections[_connectionId];
        cognitoNodes[ownerToNodeId[msg.sender]].lastActivityTimestamp = block.timestamp;
        emit ConnectionBroken(_connectionId, fromNode, toNode);
    }

    // Helper for `breakNodeConnection` to get node owner (since Solidity doesn't allow mapping in struct)
    function ownerOf(uint256 _nodeId) private view returns (address) {
        return cognitoNodes[_nodeId].owner;
    }


    // --- V. Reputation & Rewards ---

    /**
     * @dev Internal function to grant XP to a node. Used by other functions as rewards.
     * @param _nodeId The ID of the node to grant XP to.
     * @param _amount The amount of XP to grant.
     */
    function _grantXP(uint256 _nodeId, uint256 _amount) internal {
        if (_nodeId == 0 || _nodeId >= nextNodeId) revert NodeNotFound();
        CognitoNode storage node = cognitoNodes[_nodeId];
        node.xp = node.xp.add(_amount);
        emit XPGranted(_nodeId, _amount);
    }

    /**
     * @dev Callable by anyone. Triggers the distribution of accumulated rewards to eligible nodes
     *      based on their influence. Can only be called after a cooldown period.
     */
    function distributeInfluenceRewards() external nonReentrant {
        if (block.timestamp < lastRewardDistributionTimestamp.add(REWARD_DISTRIBUTION_INTERVAL)) {
            revert RewardsCooldownActive(lastRewardDistributionTimestamp.add(REWARD_DISTRIBUTION_INTERVAL).sub(block.timestamp));
        }

        uint256 totalRewardsAvailable = cognitoRewardToken.balanceOf(address(this));
        if (totalRewardsAvailable == 0) revert RewardsNotAvailable();

        // Recalculate total influence for all active nodes
        uint256 currentTotalInfluence = 0;
        for (uint256 i = 1; i < nextNodeId; i++) {
            if (cognitoNodes[i].isActive) {
                // Simplified influence calculation: (level * 10) + (bondedTokens / 1e18) * 5 + (XP / 10) + (isGuardian ? 100 : 0)
                uint256 nodeInfluence = cognitoNodes[i].level.mul(10);
                nodeInfluence = nodeInfluence.add(cognitoNodes[i].bondedTokens.div(1e18).mul(5)); // Assuming 1 token = 1 ether
                nodeInfluence = nodeInfluence.add(cognitoNodes[i].xp.div(10));
                if (cognitoNodes[i].isGuardian) {
                    nodeInfluence = nodeInfluence.add(100); // Guardians get an influence boost
                }
                cognitoNodes[i].influenceScore = nodeInfluence; // Update influence score on node
                currentTotalInfluence = currentTotalInfluence.add(nodeInfluence);
            }
        }

        if (currentTotalInfluence == 0) revert RewardsNotAvailable(); // No active nodes with influence

        // Distribute rewards proportionally
        for (uint256 i = 1; i < nextNodeId; i++) {
            if (cognitoNodes[i].isActive && cognitoNodes[i].influenceScore > 0) {
                uint256 share = (totalRewardsAvailable.mul(cognitoNodes[i].influenceScore)).div(currentTotalInfluence);
                cognitoNodes[i].rewardsAccumulated = cognitoNodes[i].rewardsAccumulated.add(share);
            }
        }

        lastRewardDistributionTimestamp = block.timestamp;
        emit RewardsDistributed(totalRewardsAvailable);
    }

    /**
     * @dev Allows a node owner to claim their accrued CognitoRewardToken rewards.
     * @param _nodeId The ID of the node to claim rewards for.
     */
    function claimNodeRewards(uint256 _nodeId) external nonReentrant onlyNodeOwner(_nodeId) {
        CognitoNode storage node = cognitoNodes[_nodeId];
        if (node.rewardsAccumulated == 0) revert NoRewardsToClaim();

        uint256 amountToClaim = node.rewardsAccumulated;
        node.rewardsAccumulated = 0; // Reset accumulated rewards
        node.lastActivityTimestamp = block.timestamp;

        require(cognitoRewardToken.transfer(msg.sender, amountToClaim), "Reward token transfer failed");
        emit RewardsClaimed(_nodeId, amountToClaim);
    }

    // --- VI. Read-Only / Utility Functions ---

    /**
     * @dev Retrieves dynamic information about a CognitoNode.
     * @param _nodeId The ID of the node.
     * @return owner The wallet address owning the node.
     * @return level The current level of the node.
     * @return xp The current experience points of the node.
     * @return influenceScore The calculated influence score of the node.
     * @return bondedTokens The amount of tokens bonded to the node.
     * @return lastActivityTimestamp The timestamp of the node's last significant activity.
     * @return isActive True if the node is active, false otherwise.
     * @return isGuardian True if the node has Guardian status.
     * @return rewardsAccumulated Amount of rewards waiting to be claimed.
     */
    function getMutableNodeInfo(
        uint256 _nodeId
    ) public view returns (
        address owner,
        uint256 level,
        uint256 xp,
        uint256 influenceScore,
        uint256 bondedTokens,
        uint256 lastActivityTimestamp,
        bool isActive,
        bool isGuardian,
        uint256 rewardsAccumulated
    ) {
        if (_nodeId == 0 || _nodeId >= nextNodeId) revert NodeNotFound();
        CognitoNode storage node = cognitoNodes[_nodeId];
        return (
            node.owner,
            node.level,
            node.xp,
            node.influenceScore,
            node.bondedTokens,
            node.lastActivityTimestamp,
            node.isActive,
            node.isGuardian,
            node.rewardsAccumulated
        );
    }

    /**
     * @dev Retrieves detailed information about a KnowledgeParticle.
     * @param _particleId The ID of the knowledge particle.
     * @return creatorNodeId The ID of the node that created this particle.
     * @return contentHash IPFS hash of the content.
     * @return topicTagHash IPFS hash of topic tags.
     * @return creationTimestamp When the particle was created.
     * @return aggregateTruthScore Aggregate truth score (needs dynamic calculation outside this view for current info).
     * @return aggregateRelevanceScore Aggregate relevance score (needs dynamic calculation).
     * @return isDisputed True if the particle is currently under dispute.
     * @return disputeStakeAmount Amount staked for dispute.
     * @return disputerNodeId The node that disputed it.
     * @return resolvedByNodeId The guardian node that resolved it (0 if not resolved).
     */
    function getKnowledgeParticleInfo(
        uint256 _particleId
    ) public view returns (
        uint256 creatorNodeId,
        string memory contentHash,
        string memory topicTagHash,
        uint256 creationTimestamp,
        uint256 aggregateTruthScore,
        uint256 aggregateRelevanceScore,
        bool isDisputed,
        uint256 disputeStakeAmount,
        uint256 disputerNodeId,
        uint256 resolvedByNodeId
    ) {
        if (_particleId == 0 || _particleId >= nextParticleId) revert ParticleNotFound();
        KnowledgeParticle storage particle = knowledgeParticles[_particleId];
        return (
            particle.creatorNodeId,
            particle.contentHash,
            particle.topicTagHash,
            particle.creationTimestamp,
            particle.aggregateTruthScore,
            particle.aggregateRelevanceScore,
            particle.isDisputed,
            particle.disputeStakeAmount,
            particle.disputerNodeId,
            particle.resolvedByNodeId
        );
    }

    /**
     * @dev Retrieves information about a specific node connection.
     * @param _connectionId The ID of the connection.
     * @return fromNodeId The ID of the source node.
     * @return toNodeId The ID of the target node.
     * @return connectionType The type of connection (bytes32 hash).
     * @return strength The strength of the connection.
     * @return timestamp When the connection was established.
     * @return accepted True if the connection is active.
     */
    function getNodeConnection(
        uint256 _connectionId
    ) public view returns (
        uint256 fromNodeId,
        uint256 toNodeId,
        bytes32 connectionType,
        uint256 strength,
        uint256 timestamp,
        bool accepted
    ) {
        if (_connectionId == 0 || _connectionId >= nextConnectionId) revert ConnectionNotFound();
        NodeConnection storage connection = nodeConnections[_connectionId];
        return (
            connection.fromNodeId,
            connection.toNodeId,
            connection.connectionType,
            connection.strength,
            connection.timestamp,
            connection.accepted
        );
    }

    /**
     * @dev Retrieves the total number of minted CognitoNodes.
     * @return The total count of nodes.
     */
    function getTotalNodes() public view returns (uint256) {
        return nextNodeId.sub(1); // Since node IDs start from 1
    }

    /**
     * @dev Retrieves the nodeId associated with a given wallet address.
     * @param _owner The wallet address.
     * @return The nodeId owned by the address, or 0 if no node is owned.
     */
    function getNodeIdByOwner(address _owner) public view returns (uint256) {
        return ownerToNodeId[_owner];
    }
}
```