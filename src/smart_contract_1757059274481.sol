The `NeuralNexus` smart contract introduces a network of "Self-Sovereign Digital Entities" called `NexusNodes`. Each `NexusNode` is a dynamic NFT (ERC721) with evolving traits, energy levels, and a "complexity score." These nodes adapt and change based on various factors: external data feeds (simulated oracles), internal time-based processing, and interactions with other nodes or their owners.

The contract aims to explore advanced concepts such as:
*   **Dynamic NFTs:** Node metadata changes over time, reflecting its evolution.
*   **On-chain "Adaptive Intelligence":** Nodes evolve their `traitVector` and `influenceScore` through on-chain logic, simulating a basic adaptive system.
*   **Simulated Oracle Integration:** Nodes can subscribe to "Sensor Feeds" (data streams) that influence their evolution.
*   **Inter-Node Interaction:** Nodes can influence each other, potentially leading to "Quantum Entanglement" – a special, high-impact state.
*   **Verifiable External Computations:** A mechanism to submit and conceptually "verify" outputs from off-chain processes (e.g., AI model inference, complex simulations) influencing a node's environment.
*   **Modular & Extensible Design:** Although simplified, the structure hints at how complex systems could be built.

---

## NeuralNexus Smart Contract

### Contract Outline

1.  **Libraries/Interfaces:** ERC721, Ownable.
2.  **State Variables:**
    *   `nexusNodes`: Mapping of `nodeId` to `NexusNode` struct.
    *   `sensorFeeds`: Mapping of `feedId` to `SensorFeed` struct.
    *   `nodeOwners`: Standard ERC721 owner mapping.
    *   `nodeApprovals`, `operatorApprovals`: ERC721.
    *   `totalSupply`, `nextTokenId`.
    *   `oracleAddress`: Address authorized to update sensor feeds.
    *   `coreParameters`: Struct holding system-wide adjustable constants.
    *   `nodeToSensorSubscriptions`: Mapping `nodeId` -> `feedId` -> `bool`.
    *   `ownerToNodes`: Mapping `owner` -> `nodeId[]` (for easy lookup).
    *   `activeProposals`: Mapping `proposalId` -> `Proposal` struct.
    *   `nextProposalId`.
    *   `nodeVotedOnProposal`: Mapping `nodeId` -> `proposalId` -> `bool`.
    *   `_interfaceId_ERC721`, `_interfaceId_ERC721Metadata`.
3.  **Events:** `NodeMinted`, `NodeProcessed`, `SensorFeedUpdated`, `SubscriptionToggled`, `InteractionInitiated`, `EntanglementToggled`, `EnergyRecharged`, `ComplexityUpgraded`, `TraitTuned`, `ProofSubmitted`, `ProposalCreated`, `VoteCast`, `ProposalResolved`.
4.  **Enums:** `ProposalState`.
5.  **Structs:**
    *   `NexusNode`: Defines an individual digital entity.
    *   `SensorFeed`: Defines a data stream from an oracle.
    *   `CoreParameters`: Global adjustable contract settings.
    *   `Proposal`: For network-level governance.
6.  **Modifiers:** `onlyOracle`, `onlyNodeOwnerOrApproved`, `onlyActiveNode`.
7.  **Functions:** (Detailed below)

---

### Function Summary

**I. Core Setup & Administration (Owner Only)**

1.  `constructor()`: Initializes the contract, sets up ERC721 details, and initial parameters.
2.  `setOracleAddress(address _oracleAddress)`: Sets the authorized address for updating sensor feeds.
3.  `registerSensorFeedType(bytes32 _feedId, uint256 _updateInterval)`: Defines a new type of external data feed.
4.  `updateCoreParameters(uint256 _maxComplexity, uint256 _baseEnergyDecay, uint256 _evolutionFactor)`: Adjusts system-wide constants for node behavior.
5.  `togglePause(bool _paused)`: Pauses/unpauses core contract functionality for maintenance.

**II. ERC721 Standard Functions**

6.  `balanceOf(address owner) view returns (uint256)`: Returns the number of nodes owned by `owner`.
7.  `ownerOf(uint256 tokenId) view returns (address)`: Returns the owner of the `tokenId`.
8.  `approve(address to, uint256 tokenId)`: Grants approval for `to` to manage `tokenId`.
9.  `getApproved(uint256 tokenId) view returns (address)`: Returns the approved address for `tokenId`.
10. `setApprovalForAll(address operator, bool approved)`: Grants/revokes operator approval.
11. `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks operator approval.
12. `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of `tokenId`.
13. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver).
14. `supportsInterface(bytes4 interfaceId) view returns (bool)`: ERC165 interface detection.

**III. NexusNode Management & Evolution**

15. `mintGenesisNode(address _owner, uint256[8] memory _initialTraitVector)`: Creates a new `NexusNode` (NFT).
16. `getNodeDetails(uint256 _nodeId) view returns (NexusNode memory)`: Retrieves all details of a `NexusNode`.
17. `tokenURI(uint256 _nodeId) view returns (string memory)`: Generates dynamic JSON metadata URI for the NFT.
18. `processNodeEvolution(uint256 _nodeId)`: The core function that updates a node's internal state (traits, energy) based on time and sensor inputs.
19. `feedSensorData(bytes32 _feedId, uint256 _newValue)`: (Called by Oracle) Updates a specific sensor feed's latest value.
20. `subscribeNodeToSensor(uint256 _nodeId, bytes32 _feedId)`: Allows a node owner to subscribe their node to a sensor feed.
21. `unSubscribeNodeFromSensor(uint256 _nodeId, bytes32 _feedId)`: Allows a node owner to unsubscribe their node.
22. `initiateInterNodeInteraction(uint256 _nodeIdA, uint256 _nodeIdB)`: Triggers a special interaction between two nodes, potentially affecting their traits or `influenceScore`.
23. `toggleQuantumEntanglement(uint256 _nodeId, bool _activate)`: Activates/deactivates a special "Quantum Entangled" state for a node, based on complex conditions.

**IV. Resource & Trait Manipulation**

24. `rechargeNodeEnergy(uint256 _nodeId, uint256 _amount)`: Allows owner to add energy to their node (simulated cost).
25. `upgradeNodeComplexity(uint256 _nodeId)`: Allows owner to increase a node's `complexityScore`, unlocking more potent evolution.
26. `tuneTraitVector(uint256 _nodeId, uint256 _traitIndex, int256 _biasAmount)`: Allows owner to attempt to influence a specific trait's evolution direction.

**V. Verifiable External Computations (Simulated)**

27. `submitEnvironmentalProof(uint256 _nodeId, bytes32 _proofHash, uint256 _expectedResult)`: Allows users to submit a "proof" (e.g., from an off-chain AI calculation or ZKP) and an expected result, which can influence a node's state if verified.

**VI. Network Governance (Simplified)**

28. `proposeNetworkParameterChange(string memory _description, bytes memory _calldata)`: Nodes with high `influenceScore` can propose changes to contract parameters.
29. `castInfluenceVote(uint256 _nodeId, uint256 _proposalId, bool _approve)`: A node casts its vote on a proposal, weighted by its `influenceScore`.
30. `resolveProposal(uint256 _proposalId)`: Finalizes a proposal if it meets quorum/threshold, applying the changes (if valid).

**VII. Query Functions**

31. `getSensorFeedValue(bytes32 _feedId) view returns (uint256, uint256)`: Get current value and last update time of a sensor feed.
32. `getNetworkStats() view returns (uint256, uint256)`: Returns total nodes and total active subscriptions.
33. `getNodesByOwner(address _owner) view returns (uint256[] memory)`: Returns an array of node IDs owned by `_owner`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For potentially complex trait calculations
import "@openzeppelin/contracts/utils/Address.sol"; // For general address utilities

/**
 * @title NeuralNexus
 * @dev A network of Self-Sovereign Digital Entities (NexusNodes) as dynamic NFTs.
 *      Each NexusNode evolves its traits, energy, and influence based on time,
 *      external sensor data (oracles), and interactions within the network.
 *      It explores dynamic NFTs, simulated on-chain AI-like adaptive logic,
 *      inter-node interactions, verifiable external computation concepts,
 *      and a simplified governance mechanism.
 */
contract NeuralNexus is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeMath for int256;

    // --- Events ---
    event NodeMinted(uint256 indexed nodeId, address indexed owner, uint256 genesisTimestamp);
    event NodeProcessed(uint256 indexed nodeId, uint256 oldEnergy, uint256 newEnergy, uint256 lastProcessedTimestamp);
    event SensorFeedUpdated(bytes32 indexed feedId, uint256 newValue, uint256 lastUpdateTimestamp);
    event SubscriptionToggled(uint256 indexed nodeId, bytes32 indexed feedId, bool subscribed);
    event InteractionInitiated(uint256 indexed nodeIdA, uint256 indexed nodeIdB, string interactionType);
    event EntanglementToggled(uint256 indexed nodeId, bool activated, uint256 complexityThreshold);
    event EnergyRecharged(uint256 indexed nodeId, uint256 amount, address indexed by);
    event ComplexityUpgraded(uint256 indexed nodeId, uint256 oldComplexity, uint256 newComplexity, address indexed by);
    event TraitTuned(uint256 indexed nodeId, uint256 traitIndex, int256 biasAmount, address indexed by);
    event ProofSubmitted(uint256 indexed nodeId, bytes32 indexed proofHash, uint256 expectedResult);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposerNodeOwner, uint256 proposerNodeId, string description);
    event VoteCast(uint256 indexed proposalId, uint256 indexed nodeId, bool approve, uint256 influenceWeight);
    event ProposalResolved(uint256 indexed proposalId, bool passed, ProposalState finalState);
    event CoreParametersUpdated(uint256 maxComplexity, uint256 baseEnergyDecay, uint256 evolutionFactor);
    event Paused(address account);
    event Unpaused(address account);

    // --- Enums ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct NexusNode {
        address owner;
        uint256 genesisTimestamp;
        uint256 lastProcessedTimestamp; // Last time processNodeEvolution was called
        uint256 coreEnergy;             // Resource for processing and actions
        uint256 complexityScore;        // Influences evolution speed and power
        uint256 influenceScore;         // Determines weight in governance and interactions
        uint256[8] traitVector;         // Array of evolving attributes (e.g., resilience, adaptability)
        bool isQuantumEntangled;        // Special state, high impact
    }

    struct SensorFeed {
        bytes32 feedId;
        uint256 latestValue;
        uint256 lastUpdateTimestamp;
        uint256 updateInterval;         // Minimum time between updates from oracle
    }

    struct CoreParameters {
        uint256 maxComplexity;          // Max complexity a node can reach
        uint256 baseEnergyDecay;        // Base energy decay per second
        uint256 evolutionFactor;        // Multiplier for trait evolution speed
        uint256 entanglementComplexityThreshold; // Min complexity for entanglement
        uint256 interactionEnergyCost;  // Energy cost for inter-node interaction
        uint256 complexityUpgradeCost;  // Cost (in base units) to upgrade complexity
        uint256 minInfluenceForProposal; // Min influenceScore for a node to propose
        uint256 proposalVoteThreshold;  // % of total influence needed to pass
        uint256 proposalDuration;       // How long a proposal is active
        uint256 baseEnergyRechargeCost; // Base cost to recharge energy
    }

    struct Proposal {
        string description;
        bytes calldataPayload;          // The actual function call to execute if passed
        address proposerAddress;        // Owner of the node that proposed
        uint256 proposerNodeId;
        uint256 creationTimestamp;
        uint256 totalInfluenceYes;
        uint256 totalInfluenceNo;
        ProposalState state;
        mapping(uint256 => bool) hasNodeVoted; // nodeID => voted
    }

    // --- State Variables ---

    mapping(uint256 => NexusNode) public nexusNodes;
    mapping(bytes32 => SensorFeed) public sensorFeeds;
    mapping(uint256 => mapping(bytes32 => bool)) public nodeToSensorSubscriptions; // nodeId => feedId => subscribed
    mapping(address => uint256[]) private _ownerToNodes; // Helper for getNodesByOwner

    uint256 private _nextTokenId;
    address public oracleAddress;
    CoreParameters public coreParameters;
    bool public paused;

    mapping(uint256 => Proposal) public activeProposals;
    uint256 private _nextProposalId;

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "NeuralNexus: Not authorized as oracle");
        _;
    }

    modifier onlyNodeOwnerOrApproved(uint256 _nodeId) {
        require(_isApprovedOrOwner(msg.sender, _nodeId), "NeuralNexus: Not owner nor approved for node");
        _;
    }

    modifier onlyActiveNode(uint256 _nodeId) {
        require(nexusNodes[_nodeId].genesisTimestamp > 0, "NeuralNexus: Node does not exist");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "NeuralNexus: Contract is paused");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("NeuralNexus", "NNX") Ownable(msg.sender) {
        _nextTokenId = 1; // Node IDs start from 1
        oracleAddress = address(0x0); // Must be set by owner
        paused = false;

        // Initialize default core parameters
        coreParameters = CoreParameters({
            maxComplexity: 100,
            baseEnergyDecay: 10, // Energy decay per second (simplified unit)
            evolutionFactor: 5,  // How much traits change per process cycle
            entanglementComplexityThreshold: 50, // Minimum complexity for quantum entanglement
            interactionEnergyCost: 500,
            complexityUpgradeCost: 1000, // Simulated token cost
            minInfluenceForProposal: 100,
            proposalVoteThreshold: 5000, // 50% (5000 / 10000)
            proposalDuration: 3 days,
            baseEnergyRechargeCost: 100 // Simulated token cost
        });
        _nextProposalId = 1;

        _interfaceId_ERC721 = type(IERC721).interfaceId;
        _interfaceId_ERC721Metadata = type(IERC721Metadata).interfaceId;
    }

    // --- I. Core Setup & Administration (Owner Only) ---

    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "NeuralNexus: Oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
    }

    function registerSensorFeedType(bytes32 _feedId, uint256 _updateInterval) public onlyOwner {
        require(sensorFeeds[_feedId].feedId == bytes32(0), "NeuralNexus: Sensor feed already registered");
        require(_updateInterval > 0, "NeuralNexus: Update interval must be positive");
        sensorFeeds[_feedId] = SensorFeed({
            feedId: _feedId,
            latestValue: 0,
            lastUpdateTimestamp: block.timestamp,
            updateInterval: _updateInterval
        });
    }

    function updateCoreParameters(
        uint256 _maxComplexity,
        uint256 _baseEnergyDecay,
        uint256 _evolutionFactor,
        uint256 _entanglementComplexityThreshold,
        uint256 _interactionEnergyCost,
        uint256 _complexityUpgradeCost,
        uint256 _minInfluenceForProposal,
        uint256 _proposalVoteThreshold,
        uint256 _proposalDuration,
        uint256 _baseEnergyRechargeCost
    ) public onlyOwner {
        coreParameters.maxComplexity = _maxComplexity;
        coreParameters.baseEnergyDecay = _baseEnergyDecay;
        coreParameters.evolutionFactor = _evolutionFactor;
        coreParameters.entanglementComplexityThreshold = _entanglementComplexityThreshold;
        coreParameters.interactionEnergyCost = _interactionEnergyCost;
        coreParameters.complexityUpgradeCost = _complexityUpgradeCost;
        coreParameters.minInfluenceForProposal = _minInfluenceForProposal;
        coreParameters.proposalVoteThreshold = _proposalVoteThreshold;
        coreParameters.proposalDuration = _proposalDuration;
        coreParameters.baseEnergyRechargeCost = _baseEnergyRechargeCost;

        emit CoreParametersUpdated(_maxComplexity, _baseEnergyDecay, _evolutionFactor);
    }

    function togglePause(bool _paused) public onlyOwner {
        paused = _paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    // --- II. ERC721 Standard Functions ---
    // (Implementations for these are mostly inherited or slightly modified from OpenZeppelin)

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return nexusNodes[tokenId].genesisTimestamp > 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Update _ownerToNodes helper array
        if (from != address(0)) {
            // Remove from old owner's list
            uint256[] storage nodes = _ownerToNodes[from];
            for (uint256 i = 0; i < nodes.length; i++) {
                if (nodes[i] == tokenId) {
                    nodes[i] = nodes[nodes.length - 1];
                    nodes.pop();
                    break;
                }
            }
        }
        if (to != address(0)) {
            // Add to new owner's list
            _ownerToNodes[to].push(tokenId);
        }
        nexusNodes[tokenId].owner = to;
    }

    // Overriding internal _transfer to update our custom struct
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        require(ERC721._isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        require(from == ERC721.ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        ERC721._approve(address(0), tokenId);

        _beforeTokenTransfer(from, to, tokenId, 1);
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId, 1);
    }

    // We keep these simple and rely on inherited OpenZeppelin logic for _safeTransfer
    // and basic approvals. No complex modifications here beyond updating `NexusNode.owner`.

    // --- III. NexusNode Management & Evolution ---

    function mintGenesisNode(address _owner, uint256[8] memory _initialTraitVector) public onlyOwner whenNotPaused returns (uint256) {
        require(_owner != address(0), "NeuralNexus: Owner cannot be zero address");
        uint256 nodeId = _nextTokenId++;
        uint256 timestamp = block.timestamp;

        // Simple validation for initial traits (e.g., within a range, not all zero)
        bool hasValidTrait = false;
        for (uint256 i = 0; i < _initialTraitVector.length; i++) {
            if (_initialTraitVector[i] > 0) {
                hasValidTrait = true;
                break;
            }
        }
        require(hasValidTrait, "NeuralNexus: Initial trait vector cannot be all zeros");


        nexusNodes[nodeId] = NexusNode({
            owner: _owner,
            genesisTimestamp: timestamp,
            lastProcessedTimestamp: timestamp,
            coreEnergy: 1000, // Initial energy
            complexityScore: 1, // Start with minimal complexity
            influenceScore: 10, // Base influence
            traitVector: _initialTraitVector,
            isQuantumEntangled: false
        });

        _mint(_owner, nodeId); // ERC721 minting
        emit NodeMinted(nodeId, _owner, timestamp);
        return nodeId;
    }

    function getNodeDetails(uint256 _nodeId) public view onlyActiveNode(_nodeId) returns (NexusNode memory) {
        return nexusNodes[_nodeId];
    }

    function tokenURI(uint256 _nodeId) public view override onlyActiveNode(_nodeId) returns (string memory) {
        NexusNode storage node = nexusNodes[_nodeId];
        string memory name = string(abi.encodePacked("NeuralNexus Node #", _nodeId.toString()));
        string memory description = string(abi.encodePacked("A self-sovereign digital entity. Complexity: ", node.complexityScore.toString(), ", Energy: ", node.coreEnergy.toString(), "."));

        // Build traits string
        string[] memory traitStrings = new string[](8);
        for (uint256 i = 0; i < node.traitVector.length; i++) {
            traitStrings[i] = string(abi.encodePacked('{"trait_type": "Trait ', (i + 1).toString(), '", "value": ', node.traitVector[i].toString(), '}'));
        }
        string memory attributes = string(abi.encodePacked("[",
            traitStrings[0], ",", traitStrings[1], ",", traitStrings[2], ",", traitStrings[3], ",",
            traitStrings[4], ",", traitStrings[5], ",", traitStrings[6], ",", traitStrings[7],
            ",", '{"trait_type": "Complexity", "value": ', node.complexityScore.toString(), '}',
            ",", '{"trait_type": "Energy", "value": ', node.coreEnergy.toString(), '}',
            ",", '{"trait_type": "Influence", "value": ', node.influenceScore.toString(), '}',
            ",", '{"trait_type": "Entangled", "value": "', (node.isQuantumEntangled ? "True" : "False"), '"}'
        , "]"));


        string memory json = string(abi.encodePacked(
            '{"name": "', name, '", "description": "', description, '", "image": "ipfs://QmbP8Jd4z9L5K7X6gG2H0Q1V2N3M4L5K6J7I8H9G0F1E2", "attributes": ', attributes, '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function processNodeEvolution(uint256 _nodeId) public whenNotPaused onlyActiveNode(_nodeId) {
        NexusNode storage node = nexusNodes[_nodeId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime.sub(node.lastProcessedTimestamp);

        // Calculate energy decay
        uint256 energyDecay = coreParameters.baseEnergyDecay.mul(timeElapsed).mul(node.complexityScore.add(1)); // More complex nodes decay faster
        if (node.coreEnergy < energyDecay) {
            node.coreEnergy = 0;
        } else {
            node.coreEnergy = node.coreEnergy.sub(energyDecay);
        }

        // Only process evolution if there's sufficient energy
        if (node.coreEnergy > 0) {
            uint256 evolutionMagnitude = (timeElapsed.mul(coreParameters.evolutionFactor).mul(node.complexityScore)).div(100);
            if (evolutionMagnitude == 0) evolutionMagnitude = 1; // Ensure some minimum evolution

            // Trait evolution influenced by sensor inputs
            for (uint256 i = 0; i < node.traitVector.length; i++) {
                int256 delta = 0;
                // Basic "adaptive" logic: traits gravitate towards (or away from) sensor values
                // For simplicity, we'll use a specific sensor for specific traits, or just a general one.
                // Here, let's say sensor "environment" influences traits 0,1,2 and sensor "market" influences 3,4,5
                uint256 sensorVal = 0;
                if (i < 3 && nodeToSensorSubscriptions[_nodeId]["environment"]) {
                    sensorVal = sensorFeeds["environment"].latestValue;
                } else if (i >= 3 && i < 6 && nodeToSensorSubscriptions[_nodeId]["market"]) {
                    sensorVal = sensorFeeds["market"].latestValue;
                } else if (nodeToSensorSubscriptions[_nodeId]["global_state"]) {
                    sensorVal = sensorFeeds["global_state"].latestValue;
                }

                if (sensorVal > 0) {
                    // Tend towards sensor value, but with stochasticity/complexity influence
                    if (node.traitVector[i] < sensorVal) {
                        delta = int256(evolutionMagnitude.div(10)); // Gentle increase
                    } else if (node.traitVector[i] > sensorVal) {
                        delta = -int256(evolutionMagnitude.div(10)); // Gentle decrease
                    }
                    // Add complexity factor for more pronounced changes
                    delta = delta.mul(int256(node.complexityScore));
                }

                // Apply the delta, ensuring traits stay positive
                if (node.traitVector[i] > 0 || delta > 0) {
                    node.traitVector[i] = uint256(int256(node.traitVector[i]).add(delta).max(0)); // Traits can't be negative
                }
            }

            // Influence score evolution (more complex nodes gain influence faster)
            node.influenceScore = node.influenceScore.add(node.complexityScore.mul(evolutionMagnitude.div(100)));
            if (node.isQuantumEntangled) {
                node.influenceScore = node.influenceScore.add(node.complexityScore.mul(evolutionMagnitude.div(20))); // Boost for entangled nodes
            }
        }

        node.lastProcessedTimestamp = currentTime;
        emit NodeProcessed(_nodeId, node.coreEnergy.add(energyDecay), node.coreEnergy, currentTime);
    }

    function feedSensorData(bytes32 _feedId, uint256 _newValue) public onlyOracle whenNotPaused {
        SensorFeed storage feed = sensorFeeds[_feedId];
        require(feed.feedId != bytes32(0), "NeuralNexus: Sensor feed not registered");
        require(block.timestamp >= feed.lastUpdateTimestamp.add(feed.updateInterval), "NeuralNexus: Sensor feed update too soon");

        feed.latestValue = _newValue;
        feed.lastUpdateTimestamp = block.timestamp;
        emit SensorFeedUpdated(_feedId, _newValue, block.timestamp);
    }

    function subscribeNodeToSensor(uint256 _nodeId, bytes32 _feedId) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        require(sensorFeeds[_feedId].feedId != bytes32(0), "NeuralNexus: Sensor feed not registered");
        require(!nodeToSensorSubscriptions[_nodeId][_feedId], "NeuralNexus: Node already subscribed");

        nodeToSensorSubscriptions[_nodeId][_feedId] = true;
        emit SubscriptionToggled(_nodeId, _feedId, true);
    }

    function unSubscribeNodeFromSensor(uint256 _nodeId, bytes32 _feedId) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        require(sensorFeeds[_feedId].feedId != bytes32(0), "NeuralNexus: Sensor feed not registered");
        require(nodeToSensorSubscriptions[_nodeId][_feedId], "NeuralNexus: Node not subscribed");

        nodeToSensorSubscriptions[_nodeId][_feedId] = false;
        emit SubscriptionToggled(_nodeId, _feedId, false);
    }

    function initiateInterNodeInteraction(uint256 _nodeIdA, uint256 _nodeIdB) public whenNotPaused {
        require(_nodeIdA != _nodeIdB, "NeuralNexus: Cannot interact with self");
        require(_exists(_nodeIdA) && _exists(_nodeIdB), "NeuralNexus: One or both nodes do not exist");
        require(nexusNodes[_nodeIdA].coreEnergy >= coreParameters.interactionEnergyCost, "NeuralNexus: Node A lacks energy");

        // Simulate a "cost" for interaction
        nexusNodes[_nodeIdA].coreEnergy = nexusNodes[_nodeIdA].coreEnergy.sub(coreParameters.interactionEnergyCost);

        // Example interaction logic: Influence transfer based on complexity difference
        if (nexusNodes[_nodeIdA].complexityScore > nexusNodes[_nodeIdB].complexityScore) {
            uint256 influenceTransfer = (nexusNodes[_nodeIdA].influenceScore.mul(10)).div(100); // 10% influence
            nexusNodes[_nodeIdA].influenceScore = nexusNodes[_nodeIdA].influenceScore.sub(influenceTransfer);
            nexusNodes[_nodeIdB].influenceScore = nexusNodes[_nodeIdB].influenceScore.add(influenceTransfer);
        } else if (nexusNodes[_nodeIdB].complexityScore > nexusNodes[_nodeIdA].complexityScore) {
            uint256 influenceTransfer = (nexusNodes[_nodeIdB].influenceScore.mul(10)).div(100);
            nexusNodes[_nodeIdB].influenceScore = nexusNodes[_nodeIdB].influenceScore.sub(influenceTransfer);
            nexusNodes[_nodeIdA].influenceScore = nexusNodes[_nodeIdA].influenceScore.add(influenceTransfer);
        }

        // Random chance for "Quantum Entanglement" based on combined complexity
        // This is a simplified probabilistic on-chain event.
        if ( (nexusNodes[_nodeIdA].complexityScore.add(nexusNodes[_nodeIdB].complexityScore)).add(block.timestamp % 100) > coreParameters.entanglementComplexityThreshold.mul(2) ) {
            // High complexity and a bit of luck might trigger entanglement
            if (!nexusNodes[_nodeIdA].isQuantumEntangled && nexusNodes[_nodeIdA].complexityScore >= coreParameters.entanglementComplexityThreshold) {
                 nexusNodes[_nodeIdA].isQuantumEntangled = true;
                 emit EntanglementToggled(_nodeIdA, true, nexusNodes[_nodeIdA].complexityScore);
            }
            if (!nexusNodes[_nodeIdB].isQuantumEntangled && nexusNodes[_nodeIdB].complexityScore >= coreParameters.entanglementComplexityThreshold) {
                nexusNodes[_nodeIdB].isQuantumEntangled = true;
                emit EntanglementToggled(_nodeIdB, true, nexusNodes[_nodeIdB].complexityScore);
            }
        }

        emit InteractionInitiated(_nodeIdA, _nodeIdB, "Influence Transfer & Potential Entanglement");
    }

    function toggleQuantumEntanglement(uint256 _nodeId, bool _activate) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        NexusNode storage node = nexusNodes[_nodeId];
        require(node.complexityScore >= coreParameters.entanglementComplexityThreshold, "NeuralNexus: Node not complex enough for entanglement");
        
        // This function allows direct control, but with a high energy cost for activation/deactivation
        uint256 entanglementCost = coreParameters.interactionEnergyCost.mul(node.complexityScore); // More complex means more costly to manage
        require(node.coreEnergy >= entanglementCost, "NeuralNexus: Not enough energy to toggle entanglement");
        
        node.coreEnergy = node.coreEnergy.sub(entanglementCost);

        node.isQuantumEntangled = _activate;
        emit EntanglementToggled(_nodeId, _activate, node.complexityScore);
    }

    // --- IV. Resource & Trait Manipulation ---

    function rechargeNodeEnergy(uint252 _nodeId, uint256 _amount) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        // In a real scenario, this would involve transferring an ERC20 token or ETH
        // For this example, it's a simulated cost.
        require(_amount > 0, "NeuralNexus: Recharge amount must be positive");
        
        uint256 cost = _amount.mul(coreParameters.baseEnergyRechargeCost).div(100); // Example: 100 base units per 100 energy
        // require(msg.sender.balance >= cost, "NeuralNexus: Not enough ETH for recharge"); // Example with ETH
        // payable(owner()).transfer(cost); // Send cost to contract owner

        nexusNodes[_nodeId].coreEnergy = nexusNodes[_nodeId].coreEnergy.add(_amount);
        emit EnergyRecharged(_nodeId, _amount, msg.sender);
    }

    function upgradeNodeComplexity(uint256 _nodeId) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        NexusNode storage node = nexusNodes[_nodeId];
        require(node.complexityScore < coreParameters.maxComplexity, "NeuralNexus: Node already at max complexity");
        
        // Simulate a token cost
        uint256 upgradeCost = coreParameters.complexityUpgradeCost.mul(node.complexityScore); // Cost increases with current complexity
        // require(msg.sender.balance >= upgradeCost, "NeuralNexus: Not enough ETH for upgrade");
        // payable(owner()).transfer(upgradeCost);

        uint256 oldComplexity = node.complexityScore;
        node.complexityScore = node.complexityScore.add(1);
        emit ComplexityUpgraded(_nodeId, oldComplexity, node.complexityScore, msg.sender);
    }

    function tuneTraitVector(uint256 _nodeId, uint256 _traitIndex, int256 _biasAmount) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        NexusNode storage node = nexusNodes[_nodeId];
        require(_traitIndex < node.traitVector.length, "NeuralNexus: Invalid trait index");
        require(_biasAmount != 0, "NeuralNexus: Bias amount cannot be zero");

        // High energy cost for direct trait manipulation, especially for complex nodes
        uint256 tuningCost = node.complexityScore.mul(100);
        require(node.coreEnergy >= tuningCost, "NeuralNexus: Not enough energy to tune traits");
        node.coreEnergy = node.coreEnergy.sub(tuningCost);

        // Apply bias, ensuring trait remains non-negative
        if (node.traitVector[_traitIndex] > 0 || _biasAmount > 0) {
            node.traitVector[_traitIndex] = uint256(int256(node.traitVector[_traitIndex]).add(_biasAmount).max(0));
        }
        
        emit TraitTuned(_nodeId, _traitIndex, _biasAmount, msg.sender);
    }

    // --- V. Verifiable External Computations (Simulated) ---

    function submitEnvironmentalProof(uint256 _nodeId, bytes32 _proofHash, uint256 _expectedResult) public whenNotPaused {
        // This function simulates the submission and *simplified* verification of an external proof.
        // In a real advanced system, _proofHash would be a ZKP (Zero-Knowledge Proof)
        // and its verification would involve a complex precompiled contract or an on-chain verifier.
        // For this example, we simply record the submission and assume a hypothetical off-chain
        // or a future on-chain verifier would use _proofHash to update _nodeId's state.

        require(_exists(_nodeId), "NeuralNexus: Node does not exist");

        // Hypothetical verification logic:
        // In a real scenario, this would call a precompiled ZKP verifier or a custom verifier contract.
        // For simplicity here, let's say the proofhash is verified if a specific pattern exists,
        // and the expectedResult influences a trait.
        bool proofIsValid = (_proofHash[0] == 0x42 && _proofHash[31] == 0x77); // Dummy verification
        
        if (proofIsValid) {
            NexusNode storage node = nexusNodes[_nodeId];
            uint256 impact = _expectedResult.div(10).mul(node.complexityScore.add(1));
            // Apply impact to a specific trait or energy based on the "verified" result
            node.traitVector[0] = node.traitVector[0].add(impact); // Example: boost first trait
            node.coreEnergy = node.coreEnergy.add(impact.div(2)); // Boost energy too
        }

        emit ProofSubmitted(_nodeId, _proofHash, _expectedResult);
    }

    // --- VI. Network Governance (Simplified) ---

    function proposeNetworkParameterChange(uint256 _proposerNodeId, string memory _description, bytes memory _calldataPayload) public onlyNodeOwnerOrApproved(_proposerNodeId) whenNotPaused {
        NexusNode storage proposerNode = nexusNodes[_proposerNodeId];
        require(proposerNode.influenceScore >= coreParameters.minInfluenceForProposal, "NeuralNexus: Node lacks sufficient influence to propose");

        uint256 proposalId = _nextProposalId++;
        activeProposals[proposalId] = Proposal({
            description: _description,
            calldataPayload: _calldataPayload,
            proposerAddress: msg.sender,
            proposerNodeId: _proposerNodeId,
            creationTimestamp: block.timestamp,
            totalInfluenceYes: 0,
            totalInfluenceNo: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, msg.sender, _proposerNodeId, _description);
    }

    function castInfluenceVote(uint256 _nodeId, uint256 _proposalId, bool _approve) public onlyNodeOwnerOrApproved(_nodeId) whenNotPaused {
        Proposal storage proposal = activeProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "NeuralNexus: Proposal not active");
        require(block.timestamp < proposal.creationTimestamp.add(coreParameters.proposalDuration), "NeuralNexus: Voting period ended");
        require(!proposal.hasNodeVoted[_nodeId], "NeuralNexus: Node already voted on this proposal");

        NexusNode storage voterNode = nexusNodes[_nodeId];
        uint256 influenceWeight = voterNode.influenceScore;

        if (_approve) {
            proposal.totalInfluenceYes = proposal.totalInfluenceYes.add(influenceWeight);
        } else {
            proposal.totalInfluenceNo = proposal.totalInfluenceNo.add(influenceWeight);
        }
        proposal.hasNodeVoted[_nodeId] = true;

        emit VoteCast(_proposalId, _nodeId, _approve, influenceWeight);
    }

    function resolveProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = activeProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "NeuralNexus: Proposal not active");
        require(block.timestamp >= proposal.creationTimestamp.add(coreParameters.proposalDuration), "NeuralNexus: Voting period still active");

        uint256 totalNetworkInfluence = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) {
             if (_exists(i)) {
                 totalNetworkInfluence = totalNetworkInfluence.add(nexusNodes[i].influenceScore);
             }
        }
        
        bool passed = false;
        if (totalNetworkInfluence > 0) { // Avoid division by zero
            // Calculate percentage of influence for 'yes' votes
            uint256 yesPercentage = proposal.totalInfluenceYes.mul(10000).div(totalNetworkInfluence); // Times 10000 for 2 decimal places

            if (yesPercentage >= coreParameters.proposalVoteThreshold) {
                passed = true;
                proposal.state = ProposalState.Succeeded;
                // Attempt to execute the calldata payload
                (bool success, ) = address(this).call(proposal.calldataPayload);
                if (success) {
                    proposal.state = ProposalState.Executed;
                } else {
                    // If execution fails, it still succeeded, but couldn't apply
                    // Could add specific error handling here
                }
            } else {
                proposal.state = ProposalState.Failed;
            }
        } else {
            // No nodes, or total influence is 0, proposal cannot pass
            proposal.state = ProposalState.Failed;
        }

        emit ProposalResolved(_proposalId, passed, proposal.state);
    }

    // --- VII. Query Functions ---

    function getSensorFeedValue(bytes32 _feedId) public view returns (uint256 latestValue, uint256 lastUpdateTimestamp) {
        SensorFeed storage feed = sensorFeeds[_feedId];
        require(feed.feedId != bytes32(0), "NeuralNexus: Sensor feed not registered");
        return (feed.latestValue, feed.lastUpdateTimestamp);
    }

    function getNetworkStats() public view returns (uint256 totalNodes, uint256 totalActiveSubscriptions) {
        totalNodes = totalSupply();
        totalActiveSubscriptions = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (_exists(i)) {
                // This would be very gas intensive if there are many sensor feeds and nodes
                // For a real-world scenario, this would need to be optimized or moved off-chain
                // For this example, we iterate over known feeds or make this count simplified.
                // Let's assume a few specific feeds we'd count for demo purposes.
                if (nodeToSensorSubscriptions[i]["environment"]) {
                    totalActiveSubscriptions++;
                }
                if (nodeToSensorSubscriptions[i]["market"]) {
                    totalActiveSubscriptions++;
                }
                if (nodeToSensorSubscriptions[i]["global_state"]) {
                    totalActiveSubscriptions++;
                }
            }
        }
        return (totalNodes, totalActiveSubscriptions);
    }

    function getNodesByOwner(address _owner) public view returns (uint256[] memory) {
        return _ownerToNodes[_owner];
    }
}
```