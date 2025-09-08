This smart contract, `AetherweaveNexus`, creates a unique ecosystem of dynamic, evolving NFTs called "Aetherweave Nodes." These nodes interact, consume resources ("Aetherweave Threads" - an ERC20 token), and evolve based on a set of on-chain rules. The evolution parameters themselves are subject to decentralized governance, where users with sufficient reputation can propose and vote on changes, potentially influenced by reports from a designated AI Oracle.

---

## Outline and Function Summary

**Contract Name:** `AetherweaveNexus`

**Description:** A dynamic, evolving NFT ecosystem where "Aetherweave Nodes" (ERC721 NFTs) interact, consume "Aetherweave Threads" (ERC20 tokens), and evolve based on on-chain rules. The ecosystem's parameters are governed by a decentralized system, influenced by user reputation and potential recommendations from an AI Oracle.

**Key Concepts:**
*   **Dynamic NFTs:** Node attributes (genes, power, energy, reputation) and their associated metadata evolve over time based on on-chain interactions and rules.
*   **On-chain Ecosystem Simulation:** Implements rules for nodes to evolve, interact, reproduce, consume resources, and even decay, creating a living, simulated environment.
*   **Reputation System:** Users earn reputation for positive contributions (e.g., resource provision, successful proposals), granting them greater influence in governance. Nodes also accrue reputation based on their survival and interactions.
*   **Decentralized Governance:** A DAO-like system allowing high-reputation users to propose and vote on changes to the core evolutionary parameters of the ecosystem.
*   **AI Oracle Integration:** An authorized off-chain AI entity can submit reports with optimized ecosystem parameters, which serve as data points for community-led governance proposals.

---

**I. Core NFT (AetherweaveNode) Management (ERC721 Extended)**

1.  **`constructor`**: Initializes the contract, sets initial parameters, deploys the `AetherThread` ERC20 token, and mints initial nodes and resources for the owner.
2.  **`mintNode(string memory initialGeneCode)`**: Mints a new Aetherweave Node with initial attributes. Requires a payment in `AetherThread` tokens.
3.  **`transferNode(address from, address to, uint256 nodeId)`**: Standard ERC721 function to transfer ownership of an Aetherweave Node.
4.  **`getNodeDetails(uint256 nodeId)`**: Retrieves all current attributes and state of a specific node.
5.  **`getOwnerNodes(address owner)`**: Returns an array of Node IDs owned by a specific address (iterative search, less efficient for very large collections).
6.  **`tokenURI(uint256 nodeId)`**: Generates a dynamic JSON metadata URI for an Aetherweave Node, reflecting its current attributes.
7.  **`setBaseURI(string memory baseURI)`**: Sets the base URI for NFT metadata (e.g., an IPFS gateway), callable only by the contract owner.

**II. Node Evolution & Interaction**

8.  **`evolveNode(uint256 nodeId)`**: Triggers a node's evolution, potentially changing its gene code and power, based on time, resource consumption, and current rules. Requires `AetherThread` payment.
9.  **`interactNodes(uint256 node1Id, uint256 node2Id, string memory interactionType)`**: Facilitates interaction between two nodes. Can lead to attribute changes, resource transfer, or prepare for reproduction. Requires `AetherThread` payment.
10. **`mutateNode(uint256 nodeId)`**: Triggers a rare, significant mutation in a node's attributes. Requires the calling user to have high reputation or meet specific conditions.
11. **`reproduceNode(uint256 parent1Id, uint256 parent2Id, string memory initialGenePrefix)`**: Creates a new node from one (asexual) or two (sexual) parent nodes, inheriting and combining attributes. Requires parent nodes to meet cooldowns and `AetherThread` payment.
12. **`consumeResource(uint256 nodeId, uint256 amount)`**: Allows a node to consume `AetherThread` tokens, typically to boost its energy level and potentially power.
13. **`getEvolutionHistory(uint256 nodeId)`**: Retrieves a simplified historical log of a node's attribute changes (returns current state as a placeholder for a more complex history storage).
14. **`decayNode(uint256 nodeId)`**: A mechanism for nodes to lose energy and power over time due to neglect or resource depletion, potentially leading to its eventual "death" (burn).

**III. Resource (AetherweaveThread) Management (ERC20 Extended)**

15. **`mintAetherThread(address to, uint256 amount)`**: Mints new `AetherThread` tokens to a specified address. Only callable by the `AetherweaveNexus` owner.
16. **`transferAetherThread(address to, uint256 amount)`**: Standard ERC20 function to transfer `AetherThread` tokens.
17. **`getAetherThreadBalance(address owner)`**: Retrieves the `AetherThread` token balance for an address.
18. **`burnAetherThread(address from, uint256 amount)`**: Burns `AetherThread` tokens from an address.

**IV. Reputation System**

19. **`updateUserReputation(address user, int256 amount)` (Internal)**: Adjusts a user's reputation score. Called internally by other functions (e.g., successful proposals, resource contributions).
20. **`getUserReputation(address user)`**: Retrieves the reputation score of a specific user address.
21. **`_updateNodeReputation(uint256 nodeId, int256 amount)` (Internal)**: Adjusts a node's reputation. Called internally during node lifecycle events.
22. **`getNodeReputation(uint256 nodeId)`**: Retrieves the reputation score of a specific node.

**V. Decentralized Governance & AI Oracle Integration**

23. **`proposeEvolutionRuleChange(string memory description, EvolutionParameters memory newParams)`**: Allows high-reputation users to propose changes to the global ecosystem's evolutionary parameters.
24. **`voteOnProposal(uint256 proposalId, bool support)`**: Enables users with positive reputation to vote 'yes' or 'no' on active governance proposals.
25. **`executeProposal(uint256 proposalId)`**: Executes a successfully voted-on proposal once the voting period ends and quorum is met, applying the new rules to the ecosystem.
26. **`submitAIOptimizationReport(string memory reportHash, EvolutionParameters memory recommendedParams)`**: An authorized AI Oracle can submit a report with recommended evolution parameters. This report serves as a data point for community members to consider in their proposals.
27. **`getCurrentEvolutionRules()`**: Retrieves the currently active global evolution parameters.
28. **`setAIOperator(address _aiOperator)`**: Sets or updates the address authorized to act as the AI Oracle. Only callable by the contract owner.

**VI. Administrative & Utility Functions**

29. **`pauseContract()`**: Emergency function to pause critical contract operations (mints, evolutions, interactions, governance). Only callable by the contract owner.
30. **`unpauseContract()`**: Unpauses the contract, restoring normal operations. Only callable by the contract owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // For fungible resources

// --- Outline and Function Summary ---
//
// Contract Name: Aetherweave Nexus
// Description: A dynamic, evolving NFT ecosystem where "Aetherweave Nodes" (ERC721 NFTs)
//              interact, consume "Aetherweave Threads" (ERC20 tokens), and evolve based on
//              on-chain rules. The ecosystem's parameters are governed by a decentralized
//              system, influenced by user reputation and potential recommendations from
//              an AI Oracle.
//
// Key Concepts:
// - Dynamic NFTs: Node attributes and metadata evolve over time.
// - On-chain Ecosystem Simulation: Nodes have "genes" and "power" that change based on interactions and resources.
// - Reputation System: Users gain reputation for positive actions, enabling higher governance participation.
// - Decentralized Governance: DAO-like system for proposing and voting on evolutionary rule changes.
// - AI Oracle Integration: An authorized oracle can submit reports influencing governance decisions.
//
// I. Core NFT (AetherweaveNode) Management (ERC721 extended)
// 1. constructor: Initializes contract, sets initial parameters, mints initial nodes and resources.
// 2. mintNode: Mints a new Aetherweave Node with initial attributes.
// 3. transferNode: Allows transfer of an Aetherweave Node (standard ERC721 transfer).
// 4. getNodeDetails: Retrieves all current attributes and state of a specific node.
// 5. getOwnerNodes: Returns an array of Node IDs owned by a specific address.
// 6. tokenURI: Generates a dynamic JSON metadata URI for an Aetherweave Node.
// 7. setBaseURI: Sets the base URI for NFT metadata (for IPFS or centralized storage).
//
// II. Node Evolution & Interaction
// 8. evolveNode: Triggers a node's evolution, changing attributes based on resources, time, and rules.
// 9. interactNodes: Facilitates interaction between two nodes, potentially affecting their attributes or creating new resources.
// 10. mutateNode: Introduces a random, significant change to a node's attributes (requires high reputation or specific conditions).
// 11. reproduceNode: Creates a new node from one or two parent nodes, inheriting combined attributes.
// 12. consumeResource: Allows a node to consume Aetherweave Thread tokens, potentially affecting its state or evolution.
// 13. getEvolutionHistory: Retrieves a historical log of a node's attribute changes (simplified).
// 14. decayNode: A mechanism for nodes to lose attributes or even be burned if neglected or resource-depleted.
//
// III. Resource (AetherweaveThread) Management (ERC20 extended)
// 15. mintAetherThread: Mints new Aetherweave Thread tokens to a specified address.
// 16. transferAetherThread: Transfers Aetherweave Thread tokens (standard ERC20 transfer).
// 17. getAetherThreadBalance: Retrieves the Aetherweave Thread token balance for an address.
// 18. burnAetherThread: Burns Aetherweave Thread tokens from an address.
//
// IV. Reputation System
// 19. updateUserReputation (internal): Adjusts a user's reputation score based on their actions.
// 20. getUserReputation: Retrieves the reputation score of a specific user address.
// 21. _updateNodeReputation (internal): Adjusts a node's reputation based on its interactions, survival, or contributions.
// 22. getNodeReputation: Retrieves the reputation score of a specific node.
//
// V. Decentralized Governance & AI Oracle Integration
// 23. proposeEvolutionRuleChange: Allows high-reputation users to propose changes to global ecosystem parameters.
// 24. voteOnProposal: Users can vote on active governance proposals.
// 25. executeProposal: Executes a successfully voted-on proposal, applying the new rules.
// 26. submitAIOptimizationReport: An authorized AI Oracle submits a report with recommended rule parameters, influencing future proposals.
// 27. getCurrentEvolutionRules: Retrieves the currently active global evolution parameters.
// 28. setAIOperator: Sets or updates the address authorized to act as the AI Oracle.
//
// VI. Administrative & Utility Functions
// 29. pauseContract: Emergency function to pause critical contract operations.
// 30. unpauseContract: Unpauses the contract after an emergency.

// --- Smart Contract Code ---

contract AetherweaveNexus is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nodeIds;

    // --- Events ---
    event NodeMinted(uint256 indexed nodeId, address indexed owner, string initialGeneCode);
    event NodeEvolved(uint256 indexed nodeId, string oldGeneCode, string newGeneCode, uint256 newPower);
    event NodesInteracted(uint256 indexed node1Id, uint256 indexed node2Id, string interactionType);
    event NodeMutated(uint256 indexed nodeId, string oldGeneCode, string newGeneCode, string mutationDescription);
    event NodeReproduced(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newNodeId);
    event ResourceConsumed(uint256 indexed nodeId, uint256 indexed resourceId, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event NodeReputationUpdated(uint256 indexed nodeId, uint256 newReputation);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIOptimizationReportSubmitted(address indexed aiOperator, uint256 timestamp, string reportHash);

    // --- Data Structures ---

    // Node Attributes: Represents the dynamic state of an Aetherweave Node
    struct NodeAttributes {
        uint256 birthTime;       // Timestamp of creation
        string  geneCode;        // A string representing the node's genetic makeup (e.g., "A1B2C3")
        uint256 power;           // A measure of the node's strength, efficiency, or influence
        uint256 lastEvolveTime;  // Last timestamp of evolution
        uint256 lastInteractionTime; // Last timestamp of interaction
        uint256 energyLevel;     // A resource pool internal to the node, consumed during actions
        uint256 reproductionCooldown; // Timestamp when node can reproduce again
        uint256 decayRate;       // Rate at which node attributes decay if not maintained
        uint256 nodeReputation;  // Reputation specific to this node
    }

    mapping(uint256 => NodeAttributes) public nodeAttributes; // NodeId => Attributes

    // User Reputation
    mapping(address => uint256) public userReputation; // UserAddress => Reputation Score

    // Evolution Parameters (Global state, can be changed via governance)
    struct EvolutionParameters {
        uint256 minReputationForProposal;
        uint256 votingPeriod; // in seconds
        uint256 minQuorumVotes;
        uint256 reproductionCostAether; // cost in AetherThread tokens
        uint256 evolveCostAether;
        uint256 interactionCostAether;
        uint256 mutationChanceBasisPoints; // 100 = 1%, 10000 = 100%
        uint256 baseDecayRate; // Base decay of energy per unit time
        uint256 initialNodeEnergy;
        uint256 reproductionCooldownDuration; // In seconds
        uint256 evolveCooldownDuration; // In seconds
        uint256 interactionCooldownDuration; // In seconds
    }
    EvolutionParameters public currentEvolutionParams;

    // Governance Proposals
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 creationTime;
        uint256 expirationTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // User => Voted (true/false)
        bool executed;
        EvolutionParameters newParams; // The proposed new parameters
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;

    address public aiOperator; // Address authorized to submit AI optimization reports
    bool public paused; // Contract pause switch

    // --- AetherThread (ERC20 Resource) ---
    AetherThread public aetherThread;

    // --- Modifiers ---
    modifier onlyAIOperator() {
        require(msg.sender == aiOperator, "Only AI Operator can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address initialAIOperator
    ) ERC721(name, symbol) Ownable(msg.sender) { // Using msg.sender as initial owner
        _setBaseURI(baseURI);
        aiOperator = initialAIOperator;

        aetherThread = new AetherThread(); // Deploy AetherThread ERC20

        // Initialize default evolution parameters
        currentEvolutionParams = EvolutionParameters({
            minReputationForProposal: 100,
            votingPeriod: 7 days,
            minQuorumVotes: 5,
            reproductionCostAether: 100 * (10 ** aetherThread.decimals()),
            evolveCostAether: 10 * (10 ** aetherThread.decimals()),
            interactionCostAether: 5 * (10 ** aetherThread.decimals()),
            mutationChanceBasisPoints: 50, // 0.5% chance
            baseDecayRate: 10, // 10 energy per day (example)
            initialNodeEnergy: 1000,
            reproductionCooldownDuration: 7 days,
            evolveCooldownDuration: 1 hours,
            interactionCooldownDuration: 30 minutes
        });

        // Mint initial AetherThread for the contract owner
        aetherThread.mint(msg.sender, 100000 * (10 ** aetherThread.decimals()));

        // Mint a few initial nodes for the owner
        _mintInitialNode(msg.sender, "INITIAL_NODE_GENE_A");
        _mintInitialNode(msg.sender, "INITIAL_NODE_GENE_B");
    }

    // --- I. Core NFT (AetherweaveNode) Management ---

    // Internal helper for initial node minting
    function _mintInitialNode(address to, string memory initialGeneCode) internal {
        _nodeIds.increment();
        uint256 newNodeId = _nodeIds.current();
        _safeMint(to, newNodeId);

        nodeAttributes[newNodeId] = NodeAttributes({
            birthTime: block.timestamp,
            geneCode: initialGeneCode,
            power: 100, // Initial power
            lastEvolveTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            energyLevel: currentEvolutionParams.initialNodeEnergy,
            reproductionCooldown: 0, // No cooldown for initial nodes
            decayRate: currentEvolutionParams.baseDecayRate,
            nodeReputation: 0
        });

        emit NodeMinted(newNodeId, to, initialGeneCode);
    }

    /// @notice Mints a new Aetherweave Node. Requires AetherThread payment.
    /// @param initialGeneCode A starting gene code for the new node.
    /// @return The ID of the newly minted node.
    function mintNode(string memory initialGeneCode) public whenNotPaused returns (uint256) {
        require(aetherThread.balanceOf(msg.sender) >= currentEvolutionParams.reproductionCostAether, "Insufficient AetherThread to mint node");
        aetherThread.burn(msg.sender, currentEvolutionParams.reproductionCostAether); // Burn cost

        _nodeIds.increment();
        uint256 newNodeId = _nodeIds.current();
        _safeMint(msg.sender, newNodeId);

        nodeAttributes[newNodeId] = NodeAttributes({
            birthTime: block.timestamp,
            geneCode: initialGeneCode,
            power: 50, // New nodes start with less power
            lastEvolveTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            energyLevel: currentEvolutionParams.initialNodeEnergy,
            reproductionCooldown: block.timestamp + currentEvolutionParams.reproductionCooldownDuration, // Cooldown for new nodes
            decayRate: currentEvolutionParams.baseDecayRate,
            nodeReputation: 0
        });

        emit NodeMinted(newNodeId, msg.sender, initialGeneCode);
        return newNodeId;
    }

    /// @notice Transfers ownership of an Aetherweave Node.
    /// @param from The current owner of the node.
    /// @param to The recipient of the node.
    /// @param nodeId The ID of the node to transfer.
    function transferNode(address from, address to, uint256 nodeId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, nodeId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, nodeId);
    }

    /// @notice Retrieves all current attributes and state of a specific node.
    /// @param nodeId The ID of the node to query.
    /// @return A struct containing all node attributes.
    function getNodeDetails(uint256 nodeId) public view returns (NodeAttributes memory) {
        require(_exists(nodeId), "Node does not exist");
        return nodeAttributes[nodeId];
    }

    /// @notice Returns an array of Node IDs owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of Node IDs.
    function getOwnerNodes(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        uint256 counter = 0;
        // This loop iterates through all potential token IDs.
        // For a very large number of tokens, this can be gas-expensive.
        // A more gas-efficient approach for large scale would involve maintaining
        // a mapping of address to token ID arrays or using external subgraphs.
        for (uint256 i = 0; i < _nodeIds.current(); i++) {
            if (_exists(i + 1) && ownerOf(i + 1) == owner) {
                tokens[counter] = i + 1;
                counter++;
            }
        }
        return tokens;
    }

    /// @notice Generates a dynamic JSON metadata URI for an Aetherweave Node.
    /// @dev This function dynamically generates metadata based on the node's current attributes.
    /// @param nodeId The ID of the node.
    /// @return A data URI containing JSON metadata.
    function tokenURI(uint256 nodeId) public view override returns (string memory) {
        require(_exists(nodeId), "ERC721Metadata: URI query for nonexistent token");

        NodeAttributes storage node = nodeAttributes[nodeId];
        string memory name = string(abi.encodePacked("Aetherweave Node #", Strings.toString(nodeId)));
        string memory description = string(abi.encodePacked(
            "An Aetherweave Node with gene code ", node.geneCode,
            ", power level ", Strings.toString(node.power),
            ", energy ", Strings.toString(node.energyLevel / (10 ** aetherThread.decimals())), // Display as whole units
            ", and reputation ", Strings.toString(node.nodeReputation),
            ". Born on ", Strings.toString(node.birthTime)
        ));

        // This would typically point to an image hosted on IPFS or similar
        // For simplicity, we'll use a placeholder or derive from geneCode
        string memory image = string(abi.encodePacked(
            _baseURI(),
            "node/", Strings.toString(nodeId),
            "/", node.geneCode, ".png"
        ));

        // Construct JSON metadata
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', name,
                            '","description":"', description,
                            '","image":"', image,
                            '","attributes": [',
                                '{"trait_type": "Gene Code", "value": "', node.geneCode, '"},',
                                '{"trait_type": "Power", "value": ', Strings.toString(node.power), '},',
                                '{"trait_type": "Energy Level", "value": ', Strings.toString(node.energyLevel / (10 ** aetherThread.decimals())), '},',
                                '{"trait_type": "Node Reputation", "value": ', Strings.toString(node.nodeReputation), '},',
                                '{"trait_type": "Birth Time", "value": ', Strings.toString(node.birthTime), '}',
                            ']}'
                        )
                    )
                )
            )
        );
    }

    /// @dev Sets the base URI for NFT metadata. Can only be called by the contract owner.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    // --- II. Node Evolution & Interaction ---

    /// @notice Triggers a node's evolution. Node consumes AetherThread and potentially changes attributes.
    /// @dev Evolution consumes energy and resources. Node's power and gene code can change.
    /// @param nodeId The ID of the node to evolve.
    function evolveNode(uint256 nodeId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, nodeId), "Not authorized to evolve this node");
        NodeAttributes storage node = nodeAttributes[nodeId];
        require(block.timestamp >= node.lastEvolveTime + currentEvolutionParams.evolveCooldownDuration, "Node cannot evolve yet (cooldown)");
        require(node.energyLevel >= currentEvolutionParams.evolveCostAether, "Node has insufficient energy to evolve");
        require(aetherThread.balanceOf(msg.sender) >= currentEvolutionParams.evolveCostAether, "Insufficient AetherThread to evolve node");

        aetherThread.burn(msg.sender, currentEvolutionParams.evolveCostAether);
        node.energyLevel -= currentEvolutionParams.evolveCostAether;

        string memory oldGeneCode = node.geneCode;
        uint256 oldPower = node.power;

        // Basic evolution logic: change gene code and power
        node.geneCode = _generateNewGeneCode(node.geneCode);
        node.power = node.power + (node.energyLevel / (10 ** aetherThread.decimals())); // Power increases with consumed energy
        if (node.power > 1000) node.power = 1000; // Cap power

        node.lastEvolveTime = block.timestamp;
        _updateNodeReputation(nodeId, 1); // Reward for evolving

        emit NodeEvolved(nodeId, oldGeneCode, node.geneCode, node.power);
    }

    /// @notice Facilitates interaction between two nodes. Can lead to attribute changes, resource transfer.
    /// @dev Both owners must authorize the interaction, or one owner interacts their two nodes.
    /// @param node1Id The ID of the first node.
    /// @param node2Id The ID of the second node.
    /// @param interactionType A string describing the type of interaction (e.g., "MATE", "COMPETE", "COLLABORATE").
    function interactNodes(uint256 node1Id, uint256 node2Id, string memory interactionType) public whenNotPaused {
        require(_exists(node1Id) && _exists(node2Id), "One or both nodes do not exist");
        require(node1Id != node2Id, "Nodes must be distinct for interaction");

        address owner1 = ownerOf(node1Id);
        address owner2 = ownerOf(node2Id);

        // Ensure msg.sender is authorized for both nodes if they have different owners
        if (owner1 != owner2) {
            require(_isApprovedOrOwner(msg.sender, node1Id), "Not authorized for node1");
            require(_isApprovedOrOwner(msg.sender, node2Id), "Not authorized for node2");
        } else { // Same owner, only need authorization for one
            require(_isApprovedOrOwner(msg.sender, node1Id), "Not authorized for node1 (or node2)");
        }

        NodeAttributes storage node1 = nodeAttributes[node1Id];
        NodeAttributes storage node2 = nodeAttributes[node2Id];

        require(block.timestamp >= node1.lastInteractionTime + currentEvolutionParams.interactionCooldownDuration, "Node 1 cannot interact yet (cooldown)");
        require(block.timestamp >= node2.lastInteractionTime + currentEvolutionParams.interactionCooldownDuration, "Node 2 cannot interact yet (cooldown)");
        require(node1.energyLevel >= currentEvolutionParams.interactionCostAether && node2.energyLevel >= currentEvolutionParams.interactionCostAether, "One or both nodes have insufficient energy to interact");

        uint256 totalInteractionCost = currentEvolutionParams.interactionCostAether * 2; // Cost for both nodes
        if (owner1 == owner2) {
            require(aetherThread.balanceOf(owner1) >= totalInteractionCost, "Insufficient AetherThread for interaction");
            aetherThread.burn(owner1, totalInteractionCost);
        } else {
            require(aetherThread.balanceOf(owner1) >= currentEvolutionParams.interactionCostAether, "Owner 1 insufficient AetherThread");
            require(aetherThread.balanceOf(owner2) >= currentEvolutionParams.interactionCostAether, "Owner 2 insufficient AetherThread");
            aetherThread.burn(owner1, currentEvolutionParams.interactionCostAether);
            aetherThread.burn(owner2, currentEvolutionParams.interactionCostAether);
        }

        node1.energyLevel -= currentEvolutionParams.interactionCostAether;
        node2.energyLevel -= currentEvolutionParams.interactionCostAether;

        uint256 oldPowerOfNode1 = node1.power;
        uint256 oldPowerOfNode2 = node2.power;

        // --- Interaction Logic (highly simplified) ---
        if (keccak256(abi.encodePacked(interactionType)) == keccak256(abi.encodePacked("MATE"))) {
            // Logic for mating, potentially leading to reproduction
            if (node1.power > 50 && node2.power > 50 && block.timestamp >= node1.reproductionCooldown && block.timestamp >= node2.reproductionCooldown) {
                // If conditions met, enable reproduction by setting new cooldowns
                node1.reproductionCooldown = block.timestamp + currentEvolutionParams.reproductionCooldownDuration;
                node2.reproductionCooldown = block.timestamp + currentEvolutionParams.reproductionCooldownDuration;
                // Owner of node1/node2 can now call reproduceNode
            }
        } else if (keccak256(abi.encodePacked(interactionType)) == keccak256(abi.encodePacked("COMPETE"))) {
            // Logic for competition
            if (node1.power > node2.power) {
                node1.power += 5; // Winner gains power
                node2.power = node2.power > 5 ? node2.power - 5 : 0; // Loser loses power
            } else if (node2.power > node1.power) {
                node2.power += 5;
                node1.power = node1.power > 5 ? node1.power - 5 : 0;
            }
            // Update node reputation based on outcome
            _updateNodeReputation(node1Id, node1.power > oldPowerOfNode1 ? 1 : -1);
            _updateNodeReputation(node2Id, node2.power > oldPowerOfNode2 ? 1 : -1);
        }
        // Add more interaction types and complex logic here

        node1.lastInteractionTime = block.timestamp;
        node2.lastInteractionTime = block.timestamp;
        _updateNodeReputation(node1Id, 1); // Reward for interaction
        _updateNodeReputation(node2Id, 1);

        emit NodesInteracted(node1Id, node2Id, interactionType);
    }


    /// @notice Triggers a mutation in a node, significantly altering its attributes.
    /// @dev Can be triggered by high user reputation, rare chance, or specific environmental factors.
    /// @param nodeId The ID of the node to mutate.
    function mutateNode(uint256 nodeId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, nodeId), "Not authorized to mutate this node");
        require(userReputation[msg.sender] >= currentEvolutionParams.minReputationForProposal * 2, "Insufficient reputation to force mutation"); // High reputation cost

        NodeAttributes storage node = nodeAttributes[nodeId];
        string memory oldGeneCode = node.geneCode;

        // A more dramatic change than normal evolution
        node.geneCode = _generateHighlyMutatedGeneCode(node.geneCode);
        node.power = node.power + (uint256(keccak256(abi.encodePacked(block.timestamp, nodeId))) % 200) - 100; // Random power change
        if (node.power < 0) node.power = 0; // Ensure non-negative
        if (node.power > 1500) node.power = 1500; // Cap

        _updateNodeReputation(nodeId, 5); // Significant reward for mutation

        emit NodeMutated(nodeId, oldGeneCode, node.geneCode, "Forced Mutation by High Reputation User");
    }

    /// @notice Creates a new node from one or two parent nodes, inheriting combined attributes.
    /// @dev Requires parent nodes to be ready for reproduction (cooldowns met, sufficient power).
    /// @param parent1Id The ID of the first parent node.
    /// @param parent2Id The ID of the second parent node (optional, use 0 for asexual reproduction).
    /// @param initialGenePrefix A string prefix for the new node's gene code.
    /// @return The ID of the newly reproduced node.
    function reproduceNode(uint256 parent1Id, uint256 parent2Id, string memory initialGenePrefix) public whenNotPaused returns (uint256) {
        require(_isApprovedOrOwner(msg.sender, parent1Id), "Not authorized to use parent1 for reproduction");
        NodeAttributes storage parent1 = nodeAttributes[parent1Id];
        require(block.timestamp >= parent1.reproductionCooldown, "Parent 1 is on reproduction cooldown");
        require(parent1.energyLevel >= currentEvolutionParams.reproductionCostAether, "Parent 1 has insufficient energy for reproduction");

        string memory newGeneCode;
        uint256 newPower;
        uint256 totalReproductionCost = currentEvolutionParams.reproductionCostAether;

        if (parent2Id != 0) { // Sexual reproduction
            require(_isApprovedOrOwner(msg.sender, parent2Id), "Not authorized to use parent2 for reproduction");
            NodeAttributes storage parent2 = nodeAttributes[parent2Id];
            require(block.timestamp >= parent2.reproductionCooldown, "Parent 2 is on reproduction cooldown");
            require(parent2.energyLevel >= currentEvolutionParams.reproductionCostAether, "Parent 2 has insufficient energy for reproduction");

            newGeneCode = _combineGeneCodes(parent1.geneCode, parent2.geneCode, initialGenePrefix);
            newPower = (parent1.power + parent2.power) / 2;
            parent2.energyLevel -= currentEvolutionParams.reproductionCostAether;
            parent2.reproductionCooldown = block.timestamp + currentEvolutionParams.reproductionCooldownDuration; // Reset cooldown
            totalReproductionCost += currentEvolutionParams.reproductionCostAether;
        } else { // Asexual reproduction
            newGeneCode = _combineGeneCodes(parent1.geneCode, "", initialGenePrefix);
            newPower = parent1.power * 9 / 10; // Asexual offspring might be slightly weaker
        }

        require(aetherThread.balanceOf(msg.sender) >= totalReproductionCost, "Insufficient AetherThread for reproduction");
        aetherThread.burn(msg.sender, totalReproductionCost);

        parent1.energyLevel -= currentEvolutionParams.reproductionCostAether;
        parent1.reproductionCooldown = block.timestamp + currentEvolutionParams.reproductionCooldownDuration; // Reset cooldown

        _nodeIds.increment();
        uint256 newNodeId = _nodeIds.current();
        _safeMint(msg.sender, newNodeId);

        nodeAttributes[newNodeId] = NodeAttributes({
            birthTime: block.timestamp,
            geneCode: newGeneCode,
            power: newPower,
            lastEvolveTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            energyLevel: currentEvolutionParams.initialNodeEnergy,
            reproductionCooldown: block.timestamp + currentEvolutionParams.reproductionCooldownDuration,
            decayRate: currentEvolutionParams.baseDecayRate,
            nodeReputation: 0
        });

        _updateNodeReputation(parent1Id, 3); // Reward parents
        if (parent2Id != 0) _updateNodeReputation(parent2Id, 3);
        _updateUserReputation(msg.sender, 2); // Reward user

        emit NodeReproduced(parent1Id, parent2Id, newNodeId);
        emit NodeMinted(newNodeId, msg.sender, newGeneCode);
        return newNodeId;
    }

    /// @notice Allows a node to consume Aetherweave Thread tokens, typically to boost its energy or attributes.
    /// @param nodeId The ID of the node that will consume resources.
    /// @param amount The amount of AetherThread tokens to consume.
    function consumeResource(uint256 nodeId, uint256 amount) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, nodeId), "Not authorized to provide resources to this node");
        require(amount > 0, "Amount must be positive");
        require(aetherThread.balanceOf(msg.sender) >= amount, "Insufficient AetherThread balance");

        aetherThread.burn(msg.sender, amount); // Burn resources from user

        NodeAttributes storage node = nodeAttributes[nodeId];
        node.energyLevel += amount; // Energy increases directly with consumed AetherThread
        node.power += (amount / (10 ** aetherThread.decimals())) / 10; // Small power boost
        if (node.power > 1500) node.power = 1500; // Cap power

        _updateNodeReputation(nodeId, (amount / (10 ** aetherThread.decimals())) / 50); // Reward for feeding node
        _updateUserReputation(msg.sender, (amount / (10 ** aetherThread.decimals())) / 100); // Reward user for contribution

        emit ResourceConsumed(nodeId, aetherThread.getResourceId(), amount);
    }

    /// @notice Retrieves a historical log of a node's attribute changes. (Simplified for this example).
    /// @dev In a full implementation, this might store events or state snapshots. Here, it returns last 3 states.
    /// @param nodeId The ID of the node.
    /// @return An array of strings representing past states.
    function getEvolutionHistory(uint256 nodeId) public view returns (string[] memory) {
        require(_exists(nodeId), "Node does not exist");
        // For a full history, would need an array of structs or a separate event logger.
        // This is a placeholder that might return current state + a simplified previous state from logs.
        // For simplicity, let's just return the current state as a 'history' element.
        string[] memory history = new string[](1);
        NodeAttributes storage node = nodeAttributes[nodeId];
        history[0] = string(abi.encodePacked(
            "Current State - Gene: ", node.geneCode,
            ", Power: ", Strings.toString(node.power),
            ", Energy: ", Strings.toString(node.energyLevel / (10 ** aetherThread.decimals())),
            ", Last Evolve: ", Strings.toString(node.lastEvolveTime)
        ));
        return history;
    }

    /// @notice A mechanism for nodes to lose attributes or even be burned if neglected or resource-depleted.
    /// @dev This is called periodically (e.g., by a keeper network or after a certain time passes in user actions).
    /// @param nodeId The ID of the node to check for decay.
    function decayNode(uint256 nodeId) public whenNotPaused {
        require(_exists(nodeId), "Node does not exist");
        NodeAttributes storage node = nodeAttributes[nodeId];

        // Ensure sufficient time has passed since last decay check
        // Using lastEvolveTime as a general "activity" timestamp for this check
        uint256 timeSinceLastCheck = block.timestamp - node.lastEvolveTime;
        if (timeSinceLastCheck < 1 days) { // Allow check once per day
             // If not enough time passed, update lastEvolveTime to prevent repeated rapid decay calculation
             // without affecting evolution cooldowns etc.
            return;
        }

        uint256 elapsedDays = timeSinceLastCheck / 1 days;
        if (elapsedDays > 0) {
            uint256 energyLoss = node.decayRate * elapsedDays * (10 ** aetherThread.decimals()); // Apply decay rate based on days
            
            if (node.energyLevel > energyLoss) {
                node.energyLevel -= energyLoss;
            } else {
                node.energyLevel = 0;
                // If energy drops to zero, start losing power rapidly or be burned
                if (node.power > 10) {
                    node.power -= 10; // Lose power
                } else {
                    node.power = 0;
                    // Node is effectively dead, owner can choose to burn
                    if (ownerOf(nodeId) == msg.sender) {
                        _burn(nodeId);
                        _updateUserReputation(msg.sender, -5); // Penalty for letting node die
                    } else {
                        // Allow anyone to burn a truly dead, unowned (or ownerless) node in a more advanced system
                        // For simplicity, this example requires owner to burn.
                    }
                }
            }
            node.lastEvolveTime = block.timestamp; // Reset decay check timestamp
        }
    }


    // --- III. Resource (AetherweaveThread) Management ---

    /// @notice Mints new Aetherweave Thread tokens to a specified address. Only callable by owner.
    /// @param to The recipient address.
    /// @param amount The amount of AetherThread tokens to mint.
    function mintAetherThread(address to, uint256 amount) public onlyOwner {
        aetherThread.mint(to, amount);
    }

    /// @notice Transfers Aetherweave Thread tokens. (Standard ERC20 transfer).
    /// @param to The recipient address.
    /// @param amount The amount of AetherThread tokens to transfer.
    /// @return True if transfer was successful.
    function transferAetherThread(address to, uint256 amount) public returns (bool) {
        return aetherThread.transfer(to, amount);
    }

    /// @notice Retrieves the Aetherweave Thread token balance for an address.
    /// @param owner The address to query.
    /// @return The balance of AetherThread tokens.
    function getAetherThreadBalance(address owner) public view returns (uint256) {
        return aetherThread.balanceOf(owner);
    }

    /// @notice Burns Aetherweave Thread tokens from an address.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of AetherThread tokens to burn.
    function burnAetherThread(address from, uint256 amount) public {
        // Allow owner to burn their own or approved sender to burn on their behalf
        require(msg.sender == from || aetherThread.allowance(from, msg.sender) >= amount, "ERC20: burn caller is not owner nor approved");
        aetherThread.burn(from, amount);
    }

    // --- IV. Reputation System ---

    /// @notice Adjusts a user's reputation score based on their actions.
    /// @dev Can be called internally by other functions (e.g., successful proposal, resource contribution).
    /// @param user The address whose reputation to update.
    /// @param amount The amount to add or subtract from reputation.
    function updateUserReputation(address user, int256 amount) internal {
        if (amount > 0) {
            userReputation[user] += uint256(amount);
        } else {
            if (userReputation[user] < uint256(-amount)) {
                userReputation[user] = 0;
            } else {
                userReputation[user] -= uint256(-amount);
            }
        }
        emit ReputationUpdated(user, userReputation[user]);
    }

    /// @notice Retrieves the reputation score of a specific user address.
    /// @param user The address to query.
    /// @return The reputation score.
    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    /// @notice Adjusts a node's reputation based on its interactions, survival, or contributions.
    /// @dev Internal function called during node lifecycle events.
    /// @param nodeId The ID of the node whose reputation to update.
    /// @param amount The amount to add or subtract from reputation.
    function _updateNodeReputation(uint256 nodeId, int256 amount) internal {
        NodeAttributes storage node = nodeAttributes[nodeId];
        if (amount > 0) {
            node.nodeReputation += uint256(amount);
        } else {
            if (node.nodeReputation < uint256(-amount)) {
                node.nodeReputation = 0;
            } else {
                node.nodeReputation -= uint256(-amount);
            }
        }
        emit NodeReputationUpdated(nodeId, node.nodeReputation);
    }

    /// @notice Retrieves the reputation score of a specific node.
    /// @param nodeId The ID of the node to query.
    /// @return The node's reputation score.
    function getNodeReputation(uint256 nodeId) public view returns (uint256) {
        require(_exists(nodeId), "Node does not exist");
        return nodeAttributes[nodeId].nodeReputation;
    }

    // --- V. Decentralized Governance & AI Oracle Integration ---

    /// @notice Allows high-reputation users to propose changes to global ecosystem parameters.
    /// @param description A brief description of the proposal.
    /// @param newParams The new set of evolution parameters proposed.
    /// @return The ID of the newly created proposal.
    function proposeEvolutionRuleChange(string memory description, EvolutionParameters memory newParams) public whenNotPaused returns (uint256) {
        require(userReputation[msg.sender] >= currentEvolutionParams.minReputationForProposal, "Insufficient reputation to propose");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            proposer: msg.sender,
            creationTime: block.timestamp,
            expirationTime: block.timestamp + currentEvolutionParams.votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            newParams: newParams
        });

        _updateUserReputation(msg.sender, 5); // Reward for proposing
        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    /// @notice Users can vote on active governance proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp < proposal.expirationTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(userReputation[msg.sender] > 0, "Requires positive reputation to vote");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        _updateUserReputation(msg.sender, 1); // Reward for voting
        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /// @notice Executes a successfully voted-on proposal, applying the new rules.
    /// @dev Can be called by anyone after the voting period ends and quorum is met.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.expirationTime, "Voting period not yet ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes >= currentEvolutionParams.minQuorumVotes, "Quorum not met");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass (more no votes or tied)");

        currentEvolutionParams = proposal.newParams;
        proposal.executed = true;

        _updateUserReputation(proposal.proposer, 10); // Reward proposer for success
        emit ProposalExecuted(proposalId);
    }

    /// @notice An authorized AI Oracle submits a report with recommended rule parameters.
    /// @dev This data can be used by high-reputation users to formulate governance proposals.
    /// @param reportHash IPFS hash or similar identifier of the detailed AI report.
    /// @param recommendedParams AI's recommended evolution parameters.
    function submitAIOptimizationReport(string memory reportHash, EvolutionParameters memory recommendedParams) public onlyAIOperator {
        // Store the AI's recommendations. These are not directly applied but serve as input for human proposals.
        // For simplicity, we'll just emit an event. A more complex system might store these recommendations
        // in a dedicated mapping (e.g., `latestAIRecommendation = recommendedParams;`) for later retrieval
        // by users proposing changes.
        emit AIOptimizationReportSubmitted(msg.sender, block.timestamp, reportHash);
        // Note: The `recommendedParams` are not directly stored on-chain in this minimal implementation,
        // but would typically be part of a more sophisticated oracle system or data structure
        // that governance members can consult when crafting proposals.
    }

    /// @notice Retrieves the currently active global evolution parameters.
    /// @return A struct containing the current EvolutionParameters.
    function getCurrentEvolutionRules() public view returns (EvolutionParameters memory) {
        return currentEvolutionParams;
    }

    /// @notice Sets or updates the address authorized to act as the AI Oracle.
    /// @param _aiOperator The new address for the AI Oracle.
    function setAIOperator(address _aiOperator) public onlyOwner {
        require(_aiOperator != address(0), "AI Operator cannot be zero address");
        aiOperator = _aiOperator;
    }

    // --- VI. Administrative & Utility Functions ---

    /// @notice Emergency function to pause critical contract operations.
    /// @dev Only the contract owner can pause. Prevents new mints, evolutions, interactions, and governance.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
    }

    /// @notice Unpauses the contract after an emergency.
    /// @dev Only the contract owner can unpause.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
    }

    // --- Internal/Helper Functions ---

    /// @dev Helper to generate a new gene code. This is very basic.
    /// In a real system, this could be a complex function based on node attributes,
    /// a random seed, or even external inputs (off-chain computation hash).
    function _generateNewGeneCode(string memory oldGeneCode) internal view returns (string memory) {
        bytes memory geneBytes = bytes(oldGeneCode);
        bytes memory newGeneBytes = new bytes(geneBytes.length);

        for (uint i = 0; i < geneBytes.length; i++) {
            byte currentByte = geneBytes[i];
            // Simple shift/alteration for demonstration.
            // In reality, this would be more sophisticated, possibly
            // using a hash of block data for pseudo-randomness.
            newGeneBytes[i] = byte(uint8(currentByte) + (block.timestamp % 2 == 0 ? 1 : 2));
        }
        return string(abi.encodePacked("EVO-", string(newGeneBytes)));
    }

    /// @dev Helper to generate a highly mutated gene code.
    function _generateHighlyMutatedGeneCode(string memory oldGeneCode) internal view returns (string memory) {
        bytes memory geneBytes = bytes(oldGeneCode);
        bytes memory newGeneBytes = new bytes(geneBytes.length);

        for (uint i = 0; i < geneBytes.length; i++) {
            byte currentByte = geneBytes[i];
            newGeneBytes[i] = byte(uint8(currentByte) + (uint8(keccak256(abi.encodePacked(block.timestamp, i, msg.sender))) % 20) - 10);
        }
        return string(abi.encodePacked("MUT-", string(newGeneBytes)));
    }

    /// @dev Helper to combine gene codes for reproduction.
    function _combineGeneCodes(string memory gene1, string memory gene2, string memory prefix) internal view returns (string memory) {
        // Simple concatenation for demonstration
        string memory combinedGenes = string(abi.encodePacked(prefix, "_", gene1, gene2));
        return string(abi.encodePacked(combinedGenes, Strings.toString(block.timestamp % 1000))); // Add randomness
    }
}

// --- AetherThread ERC20 Token (for fungible resources) ---
// This ERC20 contract will be deployed by AetherweaveNexus.
// It includes a simple `mint` function restricted to the AetherweaveNexus owner.
contract AetherThread is ERC20, Ownable {
    constructor() ERC20("AetherThread", "AETH") Ownable(msg.sender) {} // Deployer of AetherThread becomes its owner

    uint256 public constant RESOURCE_ID = 1; // Example for a single resource type

    // The AetherweaveNexus contract will mint these tokens.
    // Restricting minting to the AetherweaveNexus contract's owner.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // A getter for the resource ID (if we wanted multiple types via ERC1155)
    function getResourceId() public pure returns (uint256) {
        return RESOURCE_ID;
    }

    // Function to burn tokens, accessible publicly
    function burn(address from, uint256 amount) public {
        require(msg.sender == from || allowance(from, msg.sender) >= amount, "ERC20: burn caller is not owner nor approved");
        _burn(from, amount);
    }
}

// --- Base64 Encoding Library (from OpenZeppelin's ERC721 metadata implementation) ---
// Used for encoding JSON metadata into a data URI.
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not to waste gas from multiple calls
        string memory table = _TABLE;

        // allocate 3/4 of the length of the input data
        // (each 3 bytes of input data becomes 4 bytes of base64 but for the last non-padded chunk)
        bytes memory buffer = new bytes(data.length * 4 / 3 + 3);
        uint256 ptr = 0;
        uint256 idx = 0;

        for (idx = 0; idx < data.length - 2; idx += 3) {
            buffer[ptr++] = table[uint8(data[idx] >> 2)];
            buffer[ptr++] = table[uint8((data[idx] & 0x03) << 4 | (data[idx + 1] >> 4))];
            buffer[ptr++] = table[uint8((data[idx + 1] & 0x0F) << 2 | (data[idx + 2] >> 6))];
            buffer[ptr++] = table[uint8(data[idx + 2] & 0x3F)];
        }

        if (data.length - idx == 1) {
            buffer[ptr++] = table[uint8(data[idx] >> 2)];
            buffer[ptr++] = table[uint8((data[idx] & 0x03) << 4)];
            buffer[ptr++] = '=';
            buffer[ptr++] = '=';
        } else if (data.length - idx == 2) {
            buffer[ptr++] = table[uint8(data[idx] >> 2)];
            buffer[ptr++] = table[uint8((data[idx] & 0x03) << 4 | (data[idx + 1] >> 4))];
            buffer[ptr++] = table[uint8((data[idx + 1] & 0x0F) << 2)];
            buffer[ptr++] = '=';
        }

        return string(buffer);
    }
}
```