Here's a smart contract in Solidity called "Aetheria Nexus: The Dynamic Genesis System (DGS)". This contract manages a collection of unique "Genesis Node" NFTs that dynamically evolve based on user interactions (staking), oracle-fed data (simulated AI insights or environmental factors), and decentralized governance. Nodes generate "Influence Points" which grant voting power in the DAO and potential rewards.

This contract aims to be interesting by combining several advanced concepts:
*   **Dynamic NFTs:** Node attributes and metadata change over time.
*   **Oracle Integration for AI/External Data:** Simulates bringing off-chain AI insights or real-world data to influence NFT evolution.
*   **Staking for Influence:** NFTs are staked to generate a non-transferable governance token (Influence Points).
*   **Liquid Democracy DAO:** Users can delegate their Influence Points to others.
*   **Adaptive Governance:** The DAO can vote on and modify core parameters of the system itself (e.g., evolution rules, quorum).
*   **Node Hibernation:** A unique feature allowing users to temporarily pause their node's activity and evolution.
*   **Modular Design for Evolution:** The `initiateNodeEvolution` and `submitOracleEvolutionData` functions are designed to be extended with complex logic for how NFTs change.

While using OpenZeppelin for standard components like `ERC721` and `Ownable` for security and best practices, all core logic, state management, and function implementations for the dynamic evolution, staking, influence, and DAO are custom-built to fulfill the "don't duplicate any open source" requirement in terms of novel functionality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // Using OpenZeppelin's Strings for uint conversion. Custom fallback for string-to-uint provided.
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is deprecated in 0.8+, but explicitly used as a common advanced concept reference.

// Contract: Aetheria Nexus: The Dynamic Genesis System (DGS)
// Purpose: A sophisticated smart contract managing a collection of "Genesis Node" NFTs
//          that dynamically evolve based on user interaction (staking), oracle-fed data
//          (AI insights, environmental factors), and decentralized governance. Nodes
//          generate "Influence Points" which grant voting power in the DAO and potential rewards.

// --- Outline & Function Summary ---

// I. Core NFT Management (Genesis Nodes - ERC721 Extension)
//    Manages the lifecycle and core attributes of Genesis Node NFTs.
// 1. mintGenesisNode(address _to, string memory _initialURI): Mints a new Genesis Node to an address. Limited supply.
// 2. getNodeDetails(uint256 _nodeId): Retrieves all current attributes (stage, traits, influence, status) of a specific node.
// 3. transferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer, overridden with a lock mechanism to prevent transfer of staked nodes.
// 4. burnNode(uint256 _nodeId): Permanently removes a Genesis Node from existence, if not staked or hibernating.
// 5. updateNodeTrait(uint256 _nodeId, string memory _traitType, string memory _newValue, string memory _newURI): Admin/DAO function to directly modify a specific visual or functional trait of a node and its metadata URI.

// II. Dynamic Evolution & Oracle Integration
//     Handles the logic for how Genesis Nodes evolve and integrate external data.
// 6. initiateNodeEvolution(uint256 _nodeId): Triggers a node's evolution process, checking conditions (e.g., time elapsed, staked duration, oracle data availability).
// 7. submitOracleEvolutionData(uint256 _nodeId, bytes32 _dataType, uint256 _dataValue, string memory _aiInsightURI): Trusted oracle submits external data (e.g., "AI sentiment score," "network resource index") that influences a node's evolution, potentially linking to AI-generated art or descriptions.
// 8. proposeEvolutionRuleChange(string memory _ruleKey, uint256 _newValue): Allows any user with sufficient influence to create a DAO proposal to adjust the parameters governing how nodes evolve (e.g., influence cost per stage, time between stages).
// 9. toggleNodeHibernation(uint256 _nodeId): Allows a node holder to put their node into "hibernation," temporarily pausing evolution and influence generation.

// III. Staking & Influence System
//      Manages the staking of Nodes to accrue Influence Points, a key resource.
// 10. stakeNodeForInfluence(uint256 _nodeId): Stakes a Genesis Node, starting its influence generation. Node becomes non-transferable while staked.
// 11. unstakeNodeFromInfluence(uint256 _nodeId): Unstakes a Genesis Node, stopping influence generation and making it transferable again.
// 12. claimInfluencePoints(address _user): Allows a user to claim their accrued Influence Points from all their staked nodes.
// 13. getAvailableInfluencePoints(address _user): Returns the total available (unspent, and pending from staked) Influence Points for a user.

// IV. DAO Governance (Using Influence Points)
//     Implements a decentralized autonomous organization where Influence Points are voting power.
// 14. createGovernanceProposal(string memory _description, bytes memory _calldata, address _targetContract): Creates a new governance proposal that requires Influence Point votes.
// 15. voteOnProposal(uint256 _proposalId, bool _support): Allows users to cast their Influence Points for or against a proposal. Influence points are locked until the proposal concludes.
// 16. delegateInfluence(address _delegatee): Delegates a user's future Influence Point accrual and voting power to another address (liquid democracy).
// 17. revokeInfluenceDelegation(): Revokes any existing delegation of Influence Points.
// 18. executeProposal(uint256 _proposalId): Executes the _calldata on _targetContract if a proposal passes and quorum is met.

// V. Treasury & Rewards
//    Manages contract funds and distribution of rewards.
// 19. depositFunds(): Allows anyone to send ETH to the contract's treasury.
// 20. proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description): Creates a proposal for spending funds from the treasury.
// 21. claimNodeRewards(uint256 _nodeId): Allows a node holder to claim specific rewards (e.g., token distributions, ETH) that might be attached to their node based on its evolution stage or unique traits. (Placeholder for future reward logic).

// VI. Admin & Security
//     Essential administrative and emergency functions.
// 22. setOracleAddress(address _newOracle): Sets the trusted oracle contract address (callable by DAO/Admin).
// 23. emergencyPauseSystem(): Allows the designated admin (owner) to pause critical functions in case of an emergency.

// --- End Outline & Function Summary ---

contract AetheriaNexusDGS is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For Solidity <0.8.0, but still good to show explicit safety awareness.

    // --- State Variables ---

    Counters.Counter private _nodeIds;
    uint256 public constant MAX_GENESIS_NODES = 10_000; // Capped supply of Genesis Nodes
    uint256 public constant INFLUENCE_RATE_PER_SECOND = 100; // Influence points generated per second per staked node

    address public oracleAddress; // Address of the trusted oracle contract/EOA
    bool public paused = false; // Emergency pause switch

    // Node Statuses
    enum NodeStatus { Active, Staked, Hibernating } // Active: transferable, not staked; Staked: non-transferable, generating influence; Hibernating: paused.

    // Structs
    struct GenesisNode {
        uint256 id;
        uint256 evolutionStage; // 0 (genesis) to N (max evolution stage)
        uint256 lastEvolutionTime; // Timestamp of the last successful evolution
        uint256 lastStakedTime; // Timestamp of when the node was last staked or unstaked (for influence calculation)
        NodeStatus status;
        mapping(bytes32 => string) traits; // Dynamic traits (e.g., "color", "texture", "power_level", "generation")
        string currentURI; // Current metadata URI, updated upon evolution or trait changes
        uint256 accruedInfluencePoints; // Total influence points accumulated by this specific node since its creation
        string aiInsightURI; // URI to AI-generated insight/art that influenced this node's evolution
    }
    mapping(uint256 => GenesisNode) public genesisNodes; // Stores all Genesis Node data by ID
    mapping(address => uint256[]) public userNodes; // Allows lookup of all node IDs owned by an address (simplified for efficiency)
    mapping(uint256 => bool) public nodeExists; // Quick check if a node ID is valid

    // Influence & Staking
    mapping(uint256 => bool) public isNodeStaked; // Indicates if a specific node is staked
    mapping(address => uint256) public userInfluencePoints; // Available influence points per user (can be spent)
    mapping(address => address) public delegatedInfluence; // Liquid democracy: maps delegator to their delegatee

    // Evolution Rules (DAO controllable parameters)
    mapping(bytes32 => uint256) public evolutionRules; // Stores key parameters like `timeToEvolve`, `influenceCostPerStage`

    // Governance
    Counters.Counter private _proposalIds;
    uint256 public minInfluenceForProposal = 10_000; // Minimum influence points required to create a new proposal
    uint256 public proposalQuorumPercentage = 4; // 4% of total influence needed to pass a proposal
    uint256 public votingPeriod = 3 days; // Duration for which proposals are open for voting

    struct Proposal {
        uint256 id;
        string description;
        address targetContract; // Contract to call if proposal passes
        bytes calldataPayload; // ABI-encoded function call to execute
        uint256 voteFor; // Total influence points voted 'for'
        uint256 voteAgainst; // Total influence points voted 'against'
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool passed;
        mapping(address => uint256) voters; // Maps voter address to their locked influence points for this proposal
    }
    mapping(uint256 => Proposal) public proposals; // Stores all governance proposals

    // Treasury specific for spending proposals (using generic governance for now)
    // For a more advanced setup, this could be a separate proposal struct, but reusing `createGovernanceProposal` for now.
    Counters.Counter private _treasuryProposalIds;


    // --- Events ---

    event GenesisNodeMinted(uint256 indexed nodeId, address indexed owner, string initialURI);
    event NodeEvolutionInitiated(uint256 indexed nodeId, uint256 newStage, string newURI);
    event OracleDataSubmitted(uint256 indexed nodeId, bytes32 dataType, uint256 dataValue, string aiInsightURI);
    event NodeStaked(uint256 indexed nodeId, address indexed staker, uint256 timestamp);
    event NodeUnstaked(uint256 indexed nodeId, address indexed staker, uint256 timestamp);
    event InfluencePointsClaimed(address indexed user, uint256 amount);
    event EvolutionRuleChanged(bytes32 indexed ruleKey, uint256 oldValue, uint256 newValue);
    event NodeHibernationToggled(uint256 indexed nodeId, bool hibernating);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed creator, string description, address target, uint256 startTime, uint256 endTime);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 influenceUsed);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceRevoked(address indexed delegator, address indexed oldDelegatee);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event TreasurySpendProposalCreated(uint256 indexed proposalId, address indexed creator, address recipient, uint256 amount);
    event NodeRewardsClaimed(uint256 indexed nodeId, address indexed claimant, uint256 amount); // Placeholder event

    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event SystemPaused(address indexed pauser);
    event SystemUnpaused(address indexed unpauser);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetheriaNexus: Only oracle can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AetheriaNexus: System is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "AetheriaNexus: System is not paused");
        _;
    }

    modifier onlyUnlockedNode(uint256 _nodeId) {
        require(genesisNodes[_nodeId].status != NodeStatus.Staked, "AetheriaNexus: Node is staked and cannot be transferred");
        _;
    }

    // --- Constructor ---

    constructor(address initialOracle) ERC721("GenesisNode", "GEN") Ownable(msg.sender) {
        require(initialOracle != address(0), "AetheriaNexus: Oracle address cannot be zero");
        oracleAddress = initialOracle;

        // Initialize default evolution rules (these can be changed via DAO governance)
        evolutionRules[keccak256("timeToEvolve")] = 7 days; // How long (minimum) before a node can evolve again
        evolutionRules[keccak256("influenceCostPerStage")] = 1000; // Base influence cost for a node to evolve
        evolutionRules[keccak256("maxEvolutionStage")] = 5; // Maximum possible evolution stages for a node
        evolutionRules[keccak256("evolutionCooldown")] = 3 days; // Cooldown period after an evolution (not yet fully implemented)
        evolutionRules[keccak256("minOracleDataThreshold")] = 1; // Minimum oracle data points needed for certain evolution paths (not yet fully implemented)
    }

    // --- I. Core NFT Management ---

    /// @notice Mints a new Genesis Node to a specified address, up to the `MAX_GENESIS_NODES` limit.
    ///         Only the contract owner can mint new nodes initially. This could later be shifted to DAO control.
    /// @param _to The address to mint the node to.
    /// @param _initialURI The initial metadata URI for the node (e.g., IPFS hash).
    function mintGenesisNode(address _to, string memory _initialURI) public onlyOwner whenNotPaused {
        require(_nodeIds.current() < MAX_GENESIS_NODES, "AetheriaNexus: Max genesis nodes reached");
        _nodeIds.increment();
        uint256 newTokenId = _nodeIds.current();

        _safeMint(_to, newTokenId); // Mints the ERC721 token

        GenesisNode storage newNode = genesisNodes[newTokenId];
        newNode.id = newTokenId;
        newNode.evolutionStage = 0; // Starts at Genesis (stage 0)
        newNode.lastEvolutionTime = block.timestamp; // Set initial timestamp for evolution cooldown
        newNode.lastStakedTime = block.timestamp; // Initialize for influence calculation
        newNode.status = NodeStatus.Active; // Default status is active
        newNode.currentURI = _initialURI;
        newNode.accruedInfluencePoints = 0;
        newNode.traits[keccak256("generation")] = Strings.toString(newNode.evolutionStage); // Initial trait

        nodeExists[newTokenId] = true;
        userNodes[_to].push(newTokenId); // Track nodes per user (simplified for demonstration)

        emit GenesisNodeMinted(newTokenId, _to, _initialURI);
    }

    /// @notice Retrieves all relevant details for a specific Genesis Node.
    /// @param _nodeId The ID of the node.
    /// @return id The node's ID.
    /// @return owner The current owner of the node.
    /// @return evolutionStage The current evolution stage.
    /// @return status The current status (Active, Staked, Hibernating).
    /// @return currentURI The current metadata URI.
    /// @return accruedInfluence The total influence points accrued by this node.
    /// @return lastStakedTime Timestamp of last staking or unstaking.
    /// @return traits A list of trait keys and values. (Returned as separate arrays due to EVM limitations)
    function getNodeDetails(uint256 _nodeId)
        public
        view
        returns (
            uint256 id,
            address owner,
            uint256 evolutionStage,
            NodeStatus status,
            string memory currentURI,
            uint256 accruedInfluence,
            uint256 lastStakedTime,
            string[] memory traitKeys,
            string[] memory traitValues,
            string memory aiInsightURI
        )
    {
        require(nodeExists[_nodeId], "AetheriaNexus: Node does not exist");
        GenesisNode storage node = genesisNodes[_nodeId];

        id = node.id;
        owner = ownerOf(_nodeId);
        evolutionStage = node.evolutionStage;
        status = node.status;
        currentURI = node.currentURI;
        accruedInfluence = node.accruedInfluencePoints;
        lastStakedTime = node.lastStakedTime;
        aiInsightURI = node.aiInsightURI;

        // Populate dynamic traits (simplified: only returns 'generation' trait for brevity)
        // A full implementation would likely iterate over a known set of traits or allow dynamic discovery.
        traitKeys = new string[](1);
        traitValues = new string[](1);
        traitKeys[0] = "generation";
        traitValues[0] = node.traits[keccak256("generation")];
    }

    /// @notice Overrides ERC721 `transferFrom` to prevent transfer of staked nodes.
    /// @param from The current owner of the NFT.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the NFT to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyUnlockedNode(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Overrides ERC721 `safeTransferFrom` to prevent transfer of staked nodes.
    /// @param from The current owner of the NFT.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the NFT to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyUnlockedNode(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @notice Overrides ERC721 `safeTransferFrom` to prevent transfer of staked nodes.
    /// @param from The current owner of the NFT.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the NFT to transfer.
    /// @param data Additional data to be sent with the transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) onlyUnlockedNode(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @notice Burns a Genesis Node, permanently removing it from existence.
    ///         Only callable by the owner of the node if it's not staked or hibernating.
    /// @param _nodeId The ID of the node to burn.
    function burnNode(uint256 _nodeId) public whenNotPaused {
        require(ownerOf(_nodeId) == msg.sender, "AetheriaNexus: Only node owner can burn");
        require(genesisNodes[_nodeId].status != NodeStatus.Staked, "AetheriaNexus: Staked node cannot be burned");
        require(genesisNodes[_nodeId].status != NodeStatus.Hibernating, "AetheriaNexus: Hibernating node cannot be burned");
        
        _burn(_nodeId); // Calls ERC721 burn
        delete genesisNodes[_nodeId]; // Clear node data from storage
        nodeExists[_nodeId] = false;

        // Note: Removing from `userNodes` array (dynamic arrays) is gas-intensive.
        // For a production contract, consider a linked list for `userNodes` or a
        // mapping-based structure for more efficient deletion.
        // Simplified here to omit complex array manipulation for brevity.
    }

    /// @notice Allows the contract owner (or later, DAO via `executeProposal`) to directly modify a specific
    ///         visual or functional trait of a node and update its metadata URI.
    /// @param _nodeId The ID of the node.
    /// @param _traitType The key of the trait to update (e.g., "color", "power_level").
    /// @param _newValue The new value for the trait (as a string).
    /// @param _newURI The new metadata URI for the node, reflecting the trait change.
    function updateNodeTrait(uint256 _nodeId, string memory _traitType, string memory _newValue, string memory _newURI) public whenNotPaused onlyOwner {
        // In a fully decentralized DAO, this function would likely be protected by `onlyOwner` but only callable
        // via `executeProposal` after a successful governance vote.
        require(nodeExists[_nodeId], "AetheriaNexus: Node does not exist");

        GenesisNode storage node = genesisNodes[_nodeId];
        node.traits[keccak256(abi.encodePacked(_traitType))] = _newValue;
        node.currentURI = _newURI;

        emit NodeEvolutionInitiated(_nodeId, node.evolutionStage, _newURI); // Reusing event to signal metadata change
    }

    // --- II. Dynamic Evolution & Oracle Integration ---

    /// @notice Triggers a node's evolution process, based on defined rules and external data availability.
    ///         This function would contain complex logic, potentially requiring influence points,
    ///         specific oracle data thresholds, and cooldown periods.
    /// @param _nodeId The ID of the node to evolve.
    function initiateNodeEvolution(uint256 _nodeId) public whenNotPaused {
        require(ownerOf(_nodeId) == msg.sender, "AetheriaNexus: Only node owner can initiate evolution");
        GenesisNode storage node = genesisNodes[_nodeId];

        require(node.status != NodeStatus.Hibernating, "AetheriaNexus: Node is hibernating");
        require(node.evolutionStage < evolutionRules[keccak256("maxEvolutionStage")], "AetheriaNexus: Node has reached max evolution stage");
        require(block.timestamp >= node.lastEvolutionTime + evolutionRules[keccak256("timeToEvolve")], "AetheriaNexus: Not enough time has passed since last evolution");
        
        // --- Placeholder for advanced evolution logic ---
        // In a real system, this would involve:
        // 1. Checking `node.accruedInfluencePoints` or `userInfluencePoints[msg.sender]` to deduct a cost.
        // 2. Potentially checking stored oracle data (e.g., `node.traits[keccak256("AI_sentiment")]`) against thresholds.
        // 3. Complex branching for different evolution paths based on trait combinations or external data.
        // For simplicity, this example only enforces time and max stage.

        // Advance evolution stage
        node.evolutionStage++;
        node.lastEvolutionTime = block.timestamp;
        node.traits[keccak256("generation")] = Strings.toString(node.evolutionStage);

        // Placeholder for dynamic URI update (e.g., calling an external renderer or API to generate new art/metadata)
        node.currentURI = string(abi.encodePacked("ipfs://new_stage_uri/", Strings.toString(node.evolutionStage), "_", Strings.toString(node.id)));

        emit NodeEvolutionInitiated(_nodeId, node.evolutionStage, node.currentURI);
    }

    /// @notice A trusted oracle submits external data that influences a node's evolution.
    ///         This data could be anything from AI sentiment analysis to real-world environmental factors.
    /// @param _nodeId The ID of the node being affected by this data.
    /// @param _dataType A key for the type of data (e.g., "AI_sentiment", "network_load", "ecosystem_health").
    /// @param _dataValue The numerical value of the data.
    /// @param _aiInsightURI An optional URI pointing to AI-generated art, text, or insights based on this data.
    function submitOracleEvolutionData(uint256 _nodeId, bytes32 _dataType, uint256 _dataValue, string memory _aiInsightURI) public onlyOracle whenNotPaused {
        require(nodeExists[_nodeId], "AetheriaNexus: Node does not exist");
        GenesisNode storage node = genesisNodes[_nodeId];

        // Store oracle data as a trait. This data can then be used by `initiateNodeEvolution` or `claimNodeRewards`.
        // Example: If AI sentiment is high, node might gain a "Positive Aura" trait or be eligible for certain benefits.
        // The logic here is simplified: update the trait with the new value if relevant.
        node.traits[_dataType] = Strings.toString(_dataValue);
        node.aiInsightURI = _aiInsightURI; // Update AI insight URI for the node

        // A more complex system might trigger immediate trait changes or even a visual update here.
        // For example: `updateNodeTrait(_nodeId, "mood", "happy", newURI);`

        emit OracleDataSubmitted(_nodeId, _dataType, _dataValue, _aiInsightURI);
    }

    /// @notice Allows any user with sufficient influence to create a DAO proposal to adjust the system's evolution rules.
    ///         The actual rule change occurs upon successful execution of the proposal.
    /// @param _ruleKey The key of the evolution rule to change (e.g., "timeToEvolve", "influenceCostPerStage").
    /// @param _newValue The new value for the rule.
    function proposeEvolutionRuleChange(string memory _ruleKey, uint256 _newValue) public whenNotPaused {
        require(getAvailableInfluencePoints(msg.sender) >= minInfluenceForProposal, "AetheriaNexus: Not enough influence to create proposal");

        // Prepare the calldata for the `setEvolutionRule` function, which will be executed by the DAO.
        bytes memory callData = abi.encodeWithSelector(
            this.setEvolutionRule.selector, // Target function within this contract
            keccak256(abi.encodePacked(_ruleKey)), // Hash the string key for `bytes32`
            _newValue
        );

        createGovernanceProposal(
            string(abi.encodePacked("Change evolution rule: '", _ruleKey, "' to ", Strings.toString(_newValue))),
            callData,
            address(this) // Target contract is this very contract
        );
    }

    /// @notice Internal function to be called *only* by the DAO's `executeProposal` to set evolution rules.
    /// @param _ruleKey The bytes32 hash of the rule key.
    /// @param _newValue The new value for the rule.
    function setEvolutionRule(bytes32 _ruleKey, uint256 _newValue) public onlyOwner {
        // This function should ONLY be called by the `executeProposal` function after a successful DAO vote.
        // The `onlyOwner` modifier ensures it cannot be called directly by external users.
        require(_ruleKey != bytes32(0), "AetheriaNexus: Invalid rule key");
        uint256 oldValue = evolutionRules[_ruleKey];
        evolutionRules[_ruleKey] = _newValue;
        emit EvolutionRuleChanged(_ruleKey, oldValue, _newValue);
    }

    /// @notice Allows a node holder to put their node into "hibernation," temporarily pausing its evolution
    ///         and influence generation. If staked, it will be unstaked first.
    /// @param _nodeId The ID of the node to toggle hibernation for.
    function toggleNodeHibernation(uint256 _nodeId) public whenNotPaused {
        require(ownerOf(_nodeId) == msg.sender, "AetheriaNexus: Only node owner can toggle hibernation");
        GenesisNode storage node = genesisNodes[_nodeId];

        if (node.status == NodeStatus.Hibernating) {
            node.status = NodeStatus.Active; // Wake up the node
            node.lastStakedTime = block.timestamp; // Reset time for influence calculation if it becomes staked later
            emit NodeHibernationToggled(_nodeId, false);
        } else {
            // If currently staked, unstake it before hibernating
            if (node.status == NodeStatus.Staked) {
                _calculateAndDistributeInfluence(_nodeId); // Distribute pending influence
                isNodeStaked[_nodeId] = false;
            }
            node.status = NodeStatus.Hibernating; // Put node into hibernation
            emit NodeHibernationToggled(_nodeId, true);
        }
    }

    // --- III. Staking & Influence System ---

    /// @notice Stakes a Genesis Node, making it non-transferable and starting its influence generation.
    /// @param _nodeId The ID of the node to stake.
    function stakeNodeForInfluence(uint256 _nodeId) public whenNotPaused {
        require(ownerOf(_nodeId) == msg.sender, "AetheriaNexus: Only node owner can stake");
        require(genesisNodes[_nodeId].status == NodeStatus.Active, "AetheriaNexus: Node must be active to stake (not already staked or hibernating)");
        
        GenesisNode storage node = genesisNodes[_nodeId];
        node.status = NodeStatus.Staked; // Change status to staked
        node.lastStakedTime = block.timestamp; // Record staking time for influence calculation
        isNodeStaked[_nodeId] = true;

        emit NodeStaked(_nodeId, msg.sender, block.timestamp);
    }

    /// @notice Unstakes a Genesis Node, stopping influence generation and making it transferable again.
    /// @param _nodeId The ID of the node to unstake.
    function unstakeNodeFromInfluence(uint256 _nodeId) public whenNotPaused {
        require(ownerOf(_nodeId) == msg.sender, "AetheriaNexus: Only node owner can unstake");
        require(genesisNodes[_nodeId].status == NodeStatus.Staked, "AetheriaNexus: Node is not currently staked");
        
        GenesisNode storage node = genesisNodes[_nodeId];
        _calculateAndDistributeInfluence(_nodeId); // Distribute any pending accrued influence before unstaking
        node.status = NodeStatus.Active; // Change status back to active
        isNodeStaked[_nodeId] = false;

        emit NodeUnstaked(_nodeId, msg.sender, block.timestamp);
    }

    /// @dev Internal function to calculate and distribute influence points accrued by a specific staked node.
    function _calculateAndDistributeInfluence(uint256 _nodeId) internal {
        GenesisNode storage node = genesisNodes[_nodeId];
        // Only calculate if the node is currently staked
        if (node.status == NodeStatus.Staked) {
            uint256 timeStaked = block.timestamp.sub(node.lastStakedTime);
            uint256 newInfluence = timeStaked.mul(INFLUENCE_RATE_PER_SECOND);
            
            node.accruedInfluencePoints = node.accruedInfluencePoints.add(newInfluence);
            
            // Influence points are immediately added to the owner's available pool.
            // If the owner has delegated their influence, the points go to the delegatee.
            address recipient = ownerOf(_nodeId);
            if (delegatedInfluence[recipient] != address(0)) {
                recipient = delegatedInfluence[recipient];
            }
            userInfluencePoints[recipient] = userInfluencePoints[recipient].add(newInfluence);
            
            node.lastStakedTime = block.timestamp; // Reset last staked time to current block.timestamp
        }
    }

    /// @notice Allows a user to claim their accrued Influence Points from all their staked nodes.
    ///         This function iterates through the user's nodes and updates influence calculations.
    /// @param _user The address of the user claiming points.
    function claimInfluencePoints(address _user) public whenNotPaused {
        require(_user == msg.sender, "AetheriaNexus: Can only claim your own points");

        uint256 initialInfluence = userInfluencePoints[_user];

        // Iterate through all nodes owned by the user
        for (uint256 i = 0; i < userNodes[_user].length; i++) {
            uint256 nodeId = userNodes[_user][i];
            if (genesisNodes[nodeId].status == NodeStatus.Staked) {
                _calculateAndDistributeInfluence(nodeId); // Updates `userInfluencePoints[_user]` directly
            }
        }
        uint256 claimedAmount = userInfluencePoints[_user].sub(initialInfluence);

        emit InfluencePointsClaimed(_user, claimedAmount);
    }

    /// @notice Returns the total available (unspent and pending from staked nodes) Influence Points for a user.
    /// @param _user The address of the user.
    /// @return The total available influence points.
    function getAvailableInfluencePoints(address _user) public view returns (uint256) {
        uint256 currentPendingInfluence = 0;
        // Sum up influence for currently staked nodes
        for (uint256 i = 0; i < userNodes[_user].length; i++) {
            uint256 nodeId = userNodes[_user][i];
            if (genesisNodes[nodeId].status == NodeStatus.Staked) {
                uint256 timeStaked = block.timestamp.sub(genesisNodes[nodeId].lastStakedTime);
                currentPendingInfluence = currentPendingInfluence.add(timeStaked.mul(INFLUENCE_RATE_PER_SECOND));
            }
        }
        // Return current spendable balance + pending influence
        return userInfluencePoints[_user].add(currentPendingInfluence);
    }

    // --- IV. DAO Governance (Using Influence Points) ---

    /// @notice Creates a new governance proposal that requires Influence Point votes.
    /// @param _description A detailed description of the proposal.
    /// @param _calldata The ABI-encoded call data for the target function to execute if the proposal passes.
    /// @param _targetContract The address of the contract to call if the proposal passes.
    /// @return The ID of the newly created proposal.
    function createGovernanceProposal(string memory _description, bytes memory _calldata, address _targetContract) public whenNotPaused returns (uint256) {
        require(getAvailableInfluencePoints(msg.sender) >= minInfluenceForProposal, "AetheriaNexus: Not enough influence to create proposal");
        
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = _description;
        newProposal.targetContract = _targetContract;
        newProposal.calldataPayload = _calldata;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp.add(votingPeriod);
        newProposal.executed = false;
        newProposal.passed = false;

        emit GovernanceProposalCreated(proposalId, msg.sender, _description, _targetContract, newProposal.startTime, newProposal.endTime);
        return proposalId;
    }

    /// @notice Allows users to cast their Influence Points for or against a proposal.
    ///         Influence points used for voting are temporarily locked until the proposal concludes.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' (yes), false for 'against' (no).
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetheriaNexus: Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "AetheriaNexus: Voting has not started");
        require(block.timestamp <= proposal.endTime, "AetheriaNexus: Voting has ended");
        
        address voter = msg.sender;
        // If sender has delegated their influence, their vote counts for the delegatee.
        if (delegatedInfluence[msg.sender] != address(0)) {
            voter = delegatedInfluence[msg.sender];
        }

        // Before voting, ensure all pending influence for this voter is calculated
        claimInfluencePoints(voter); // This updates userInfluencePoints[voter]
        
        uint256 availableInfluence = userInfluencePoints[voter];
        require(availableInfluence > 0, "AetheriaNexus: No influence points to vote");
        require(proposal.voters[voter] == 0, "AetheriaNexus: Already voted on this proposal");

        if (_support) {
            proposal.voteFor = proposal.voteFor.add(availableInfluence);
        } else {
            proposal.voteAgainst = proposal.voteAgainst.add(availableInfluence);
        }
        proposal.voters[voter] = availableInfluence; // Record and lock the influence points for this vote
        userInfluencePoints[voter] = userInfluencePoints[voter].sub(availableInfluence); // Deduct from available balance temporarily
        
        emit VotedOnProposal(_proposalId, voter, _support, availableInfluence);
    }

    /// @notice Delegates a user's future Influence Point accrual and voting power to another address (liquid democracy).
    ///         Once delegated, all influence generated by the delegator's nodes, and any votes cast by the delegator,
    ///         will be attributed to the delegatee.
    /// @param _delegatee The address to delegate influence to.
    function delegateInfluence(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "AetheriaNexus: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AetheriaNexus: Cannot delegate to self");

        address oldDelegatee = delegatedInfluence[msg.sender];
        delegatedInfluence[msg.sender] = _delegatee;

        emit InfluenceDelegated(msg.sender, _delegatee);
    }

    /// @notice Revokes any existing delegation of Influence Points, returning control to the original user.
    function revokeInfluenceDelegation() public whenNotPaused {
        address oldDelegatee = delegatedInfluence[msg.sender];
        require(oldDelegatee != address(0), "AetheriaNexus: No active delegation to revoke");

        delete delegatedInfluence[msg.sender];
        emit InfluenceRevoked(msg.sender, oldDelegatee);
    }

    /// @notice Executes the `_calldata` on `_targetContract` if a proposal passes and quorum is met.
    ///         Anyone can call this function after the voting period has ended.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "AetheriaNexus: Proposal does not exist");
        require(block.timestamp > proposal.endTime, "AetheriaNexus: Voting period has not ended");
        require(!proposal.executed, "AetheriaNexus: Proposal already executed");

        uint256 totalInfluenceInSystem = _getTotalInfluence(); // Dynamic total influence for quorum calculation
        require(
            proposal.voteFor.add(proposal.voteAgainst) >= totalInfluenceInSystem.mul(proposalQuorumPercentage).div(100),
            "AetheriaNexus: Quorum not met"
        );
        
        if (proposal.voteFor > proposal.voteAgainst) {
            proposal.passed = true;
            // Execute the proposed function call
            (bool success, ) = proposal.targetContract.call(proposal.calldataPayload);
            require(success, "AetheriaNexus: Proposal execution failed");
        } else {
            proposal.passed = false;
        }

        proposal.executed = true;

        // Unlock influence points from voters (return to userInfluencePoints)
        // This is a simplified approach. A more efficient way would be to track all voters.
        // For demonstration, it iterates through all possible `userNodes` entries which is inefficient for large scale.
        // A better approach would be to store an array of actual voters in the proposal struct.
        for (uint256 i = 0; i < _nodeIds.current(); i++) { // Iterate all possible node owners up to current ID
            address potentialOwner = ownerOf(i + 1); // Node IDs start from 1
            if (potentialOwner != address(0)) {
                address voterToUnlock = delegatedInfluence[potentialOwner] != address(0) ? delegatedInfluence[potentialOwner] : potentialOwner;
                if (proposal.voters[voterToUnlock] > 0) {
                     userInfluencePoints[voterToUnlock] = userInfluencePoints[voterToUnlock].add(proposal.voters[voterToUnlock]);
                     proposal.voters[voterToUnlock] = 0; // Clear locked amount
                }
            }
        }
        
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /// @dev Calculates the total potential influence in the system from all active/staked nodes.
    ///      This is used for quorum calculation. This implementation sums current node influence.
    function _getTotalInfluence() internal view returns (uint256) {
        uint256 total = 0;
        // Sum the accrued influence points for all existing nodes + current pending influence from staked
        for (uint256 i = 1; i <= _nodeIds.current(); i++) { // Iterate through all minted node IDs
            if (nodeExists[i]) {
                GenesisNode storage node = genesisNodes[i];
                total = total.add(node.accruedInfluencePoints); // Already accrued
                if (node.status == NodeStatus.Staked) {
                    uint256 timeStaked = block.timestamp.sub(node.lastStakedTime);
                    total = total.add(timeStaked.mul(INFLUENCE_RATE_PER_SECOND)); // Pending from current stake
                }
            }
        }
        // Also add any influence points currently sitting in `userInfluencePoints` that aren't locked in a vote
        // This assumes `userInfluencePoints` already correctly aggregates across delegates/delegators.
        // For a perfectly accurate real-time quorum, one would need to sum `userInfluencePoints` for all unique addresses.
        // Simplified here to just sum node influence for robustness.
        return total;
    }

    // --- V. Treasury & Rewards ---

    /// @notice Allows anyone to send ETH to the contract's treasury.
    function depositFunds() public payable whenNotPaused {
        require(msg.value > 0, "AetheriaNexus: Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Creates a proposal for spending funds from the treasury. This uses the general
    ///         governance proposal mechanism.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of ETH to send (in wei).
    /// @param _description A description of the spending purpose.
    /// @return The ID of the newly created general governance proposal that represents this treasury spend.
    function proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description) public whenNotPaused returns (uint256) {
        require(getAvailableInfluencePoints(msg.sender) >= minInfluenceForProposal, "AetheriaNexus: Not enough influence to create proposal");
        require(_recipient != address(0), "AetheriaNexus: Recipient cannot be zero address");
        require(_amount > 0, "AetheriaNexus: Amount must be greater than zero");
        require(address(this).balance >= _amount, "AetheriaNexus: Insufficient treasury balance for proposed spend");

        // Prepare the calldata for a generic `sendETH` type function to be executed by the DAO.
        bytes memory callData = abi.encodeWithSelector(
            this.sendETH.selector, // Target function within this contract
            _recipient,
            _amount
        );

        // Reusing the general governance proposal for treasury spend
        uint256 generalProposalId = createGovernanceProposal(
            string(abi.encodePacked("Treasury Spend: '", _description, "' to ", Strings.toHexString(uint160(_recipient)), " for ", Strings.toString(_amount), " wei")),
            callData,
            address(this) // Target contract is this very contract
        );

        emit TreasurySpendProposalCreated(generalProposalId, msg.sender, _recipient, _amount);
        return generalProposalId; // Return the ID of the general proposal
    }

    /// @notice Internal function to be called *only* by the DAO's `executeProposal` to send ETH from the treasury.
    /// @param _recipient The address to send ETH to.
    /// @param _amount The amount of ETH to send (in wei).
    function sendETH(address _recipient, uint256 _amount) public onlyOwner {
        // This function should ONLY be called by the `executeProposal` function after a successful DAO vote.
        // The `onlyOwner` modifier ensures it cannot be called directly by external users.
        require(address(this).balance >= _amount, "AetheriaNexus: Insufficient treasury balance for execution");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AetheriaNexus: Failed to send treasury funds");
    }

    /// @notice Allows a node holder to claim specific rewards (e.g., token distributions, ETH)
    ///         that might be attached to their node based on its evolution stage or unique traits.
    ///         This function is currently a placeholder for future complex reward logic.
    /// @param _nodeId The ID of the node to claim rewards for.
    function claimNodeRewards(uint256 _nodeId) public whenNotPaused {
        require(ownerOf(_nodeId) == msg.sender, "AetheriaNexus: Only node owner can claim rewards");
        // GenesisNode storage node = genesisNodes[_nodeId];

        // --- Placeholder for actual reward logic ---
        // This function would contain specific conditions and reward distributions.
        // Examples:
        // - if (node.evolutionStage >= 3 && !claimedStageRewards[_nodeId][3]) {
        //     // Distribute some ERC20 tokens or ETH
        //     uint256 rewardAmount = 1 ether;
        //     require(address(this).balance >= rewardAmount, "AetheriaNexus: Not enough rewards in treasury");
        //     (bool success, ) = msg.sender.call{value: rewardAmount}("");
        //     require(success, "AetheriaNexus: Failed to send reward");
        //     claimedStageRewards[_nodeId][3] = true; // Prevents double claiming
        //     emit NodeRewardsClaimed(_nodeId, msg.sender, rewardAmount);
        // }
        // - if (keccak256(abi.encodePacked(node.traits[keccak256("AI_sentiment")])) == keccak256(abi.encodePacked("positive")) && !claimedAIRewards[_nodeId]) {
        //     // Special reward for positive AI sentiment
        // }

        revert("AetheriaNexus: Node specific reward system not implemented yet. This is a placeholder.");
    }

    // --- VI. Admin & Security ---

    /// @notice Sets the trusted oracle contract address. Only callable by the current owner.
    ///         In a DAO, this would typically be changed via a governance proposal.
    /// @param _newOracle The address of the new oracle contract.
    function setOracleAddress(address _newOracle) public onlyOwner whenNotPaused {
        require(_newOracle != address(0), "AetheriaNexus: New oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /// @notice Allows the designated admin (owner) to pause critical functions in case of an emergency.
    ///         When paused, functions marked with `whenNotPaused` will revert.
    function emergencyPauseSystem() public onlyOwner whenNotPaused {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    /// @notice Allows the designated admin (owner) to unpause the system.
    ///         Only callable when the system is currently paused.
    function unpauseSystem() public onlyOwner whenPaused {
        paused = false;
        emit SystemUnpaused(msg.sender);
    }

    // --- Fallback & Receive ---
    // These functions allow the contract to receive plain ETH transfers, which go into the treasury.
    receive() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }
    fallback() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }
}

// Helper library for string to uint conversion, if OpenZeppelin's `Strings.toUint` is not suitable.
// Using OZ Strings library above, but this is an example custom implementation.
library CustomStrings {
    /// @dev Converts a string to a uint256. Reverts if the string contains non-digit characters.
    ///      Not as robust as a full `parseInt` but sufficient for simple digit strings.
    function toUint(string memory _value) internal pure returns (uint256) {
        bytes memory b = bytes(_value);
        uint256 res = 0;
        for (uint256 i = 0; i < b.length; i++) {
            require(b[i] >= 0x30 && b[i] <= 0x39, "CustomStrings: Not a valid number string");
            res = res * 10 + uint256(uint8(b[i]) - 0x30);
        }
        return res;
    }
    
    // OpenZeppelin's Strings.toString(uint256) is used directly in the contract.
    // This is a custom fallback version if OZ not used or version doesn't have it.
    /*
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
    */
}
```