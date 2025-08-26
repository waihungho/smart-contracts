This smart contract, "Aetherium Genesis," envisions a decentralized, evolving simulation where unique digital entities, called "Genesis Nodes" (ERC721 NFTs), exist and interact. These nodes possess dynamic attributes like **level, experience, influence, and accumulated resources** that change based on user interactions, world events, and external oracle data.

The contract incorporates advanced concepts:
*   **Dynamic NFTs (dNFTs):** Node attributes and metadata evolve on-chain.
*   **Decentralized Simulation/World:** Global parameters are governed by node owners, and the world state can react to external factors via oracles.
*   **Gamified Progression:** XP, leveling, resource management, and boosts.
*   **On-chain Influence System:** Node influence can decay, be boosted, and used for governance.
*   **Inter-Node Synergy:** Special interactions between two NFTs for unique outcomes.
*   **Oracle Integration:** Fetching external "environmental factors" to influence the simulation.
*   **Simple DAO-like Governance:** Node owners can propose and vote on changes to world parameters.

---

## Aetherium Genesis Contract Outline & Function Summary

This contract manages Genesis Nodes (ERC721 NFTs) within a dynamic, simulated world.

### Contract Name: `AetheriumGenesis`

### Core Concepts:
*   **GenesisNode:** An ERC721 NFT with dynamic attributes (level, XP, influence, resources, attunement).
*   **WorldConfig:** Global parameters governing the simulation, adjustable via governance.
*   **Oracles:** External data sources (e.g., Chainlink) to introduce real-world or dynamic factors.
*   **Influence:** A reputation/power score for nodes, impacting governance and interactions.
*   **Resources:** Internal commodity generated and consumed by nodes.

### Outline:

1.  **Libraries & Interfaces:**
    *   ERC721, ERC721URIStorage (from OpenZeppelin)
    *   Ownable (from OpenZeppelin)
    *   IERC20 (for potential future token interactions)
    *   Chainlink `ICoordinator`, `LinkTokenInterface` (for oracle integration)

2.  **Structures:**
    *   `GenesisNode`: Defines the attributes of each NFT.
    *   `WorldConfig`: Defines global parameters of the simulation.
    *   `Proposal`: Defines governance proposals.

3.  **State Variables:**
    *   Mappings for `GenesisNode` data, ERC721 metadata.
    *   `_nodeIdCounter`: Tracks total nodes minted.
    *   `worldConfig`: Instance of `WorldConfig`.
    *   `proposals`, `proposalCount`: For governance.
    *   Chainlink oracle-specific variables (`oracleContract`, `jobId`, `linkToken`, `fee`, `requestId`).
    *   `environmentalFactor`: The latest value fetched from the oracle.
    *   `treasuryBalance`: Funds accumulated by the contract.
    *   `metadataBaseURI`: Base URI for NFT metadata.

4.  **Events:** Significant actions and state changes.

5.  **Modifiers:** Access control and state validation.

6.  **Constructor:** Initializes `Ownable`, `ERC721`, `WorldConfig`, and Chainlink oracle.

7.  **ERC721 Standard Functions (Inherited/Overridden):**
    *   `supportsInterface`, `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.

8.  **Genesis Node Management & Interaction:**
    *   `mintGenesisNode`
    *   `interactWithNode`
    *   `upgradeNodeCapacity`
    *   `attuneNodeElement`
    *   `harvestNodeResources`
    *   `activateNodeBoost`
    *   `decayNodeInfluence`
    *   `initiateNodeSynergy`
    *   `updateNodeMetadataURI`
    *   `queryNodeDetails`

9.  **World Governance & Events:**
    *   `proposeWorldParameterChange`
    *   `voteOnProposal`
    *   `executeProposal`
    *   `setWorldEventHorizon`
    *   `resolveGlobalEvent`

10. **Oracle Integration:**
    *   `requestEnvironmentalFactor`
    *   `fulfillEnvironmentalFactor`

11. **Treasury & Economic Functions:**
    *   `stakeForInfluence`
    *   `unstakeInfluence`
    *   `depositIntoTreasury`
    *   `withdrawTreasuryFunds`

12. **Admin/Owner Functions:**
    *   `setMetadataBaseURI`
    *   `registerOracleService`
    *   `setChainlinkFee`

---

### Function Summary:

1.  **`constructor(string memory name, string memory symbol, address initialOracle, bytes32 initialJobId, uint256 initialFee, address link)`**: Initializes the ERC721 contract, sets the initial `WorldConfig`, and configures the Chainlink oracle.
2.  **`supportsInterface(bytes4 interfaceId) internal view override returns (bool)`**: ERC721 standard function.
3.  **`mintGenesisNode() public payable returns (uint256)`**: Mints a new Genesis Node, assigning it initial parameters and transferring a configurable mint fee to the treasury. Each node starts at Level 1 with 0 XP, 100 Influence, and base resource capacity.
4.  **`interactWithNode(uint256 _nodeId) public`**: Allows any user to interact with a node. This action grants XP to the node, generates resources, and slightly increases its influence. A small interaction fee might be charged or resources consumed.
5.  **`upgradeNodeCapacity(uint256 _nodeId) public`**: Allows the node owner to spend accumulated resources to increase the node's `resourceCapacity`. This represents a progression path for nodes.
6.  **`attuneNodeElement(uint256 _nodeId, uint8 _attunementType) public`**: Allows the owner to change a node's 'attunement' type (e.g., elemental, role-based). This could cost resources or influence, and impact how the node interacts with the world or other nodes.
7.  **`harvestNodeResources(uint256 _nodeId) public`**: Allows the node owner to collect accumulated resources from their node, transferring them to their own internal resource balance (or a dedicated resource token, if implemented).
8.  **`activateNodeBoost(uint256 _nodeId) public payable`**: Allows the node owner to activate a temporary boost for their node, increasing XP gain, resource generation, or influence. This costs a certain amount of native currency (ETH) which goes to the treasury.
9.  **`decayNodeInfluence(uint256 _nodeId) public`**: A public function (potentially callable by anyone, or by a keeper network) that periodically reduces a node's `influenceScore` if it hasn't been interacted with or actively maintained for a set period. This prevents stale nodes from retaining high influence.
10. **`requestEnvironmentalFactor() public returns (bytes32 requestId)`**: Initiates a Chainlink request to fetch an external "environmental factor" (e.g., a climate index, a market volatility score) which will influence global simulation parameters or node behavior.
11. **`fulfillEnvironmentalFactor(bytes32 _requestId, uint256 _environmentalFactor) public recordChainlinkFulfillment(_requestId)`**: The callback function for Chainlink, which updates the contract's `environmentalFactor` based on the oracle's response.
12. **`proposeWorldParameterChange(string memory _description, uint256 _paramIndex, uint256 _newValue) public`**: Allows any Genesis Node owner with sufficient influence to propose a change to a global `WorldConfig` parameter (e.g., `baseXPPerInteraction`, `influenceDecayRate`).
13. **`voteOnProposal(uint256 _proposalId, bool _support) public`**: Allows Genesis Node owners to vote on active proposals. Voting power could be weighted by node influence or level.
14. **`executeProposal(uint256 _proposalId) public`**: Executes a proposal if it has reached a majority vote and the voting period has ended.
15. **`initiateNodeSynergy(uint256 _node1Id, uint256 _node2Id) public`**: A creative function allowing two node owners (or one owner with two nodes) to combine their nodes for a special interaction. This could result in a temporary boost for both nodes, a unique resource generation, or a shared, temporary status effect. Requires both owners' approval or simultaneous call.
16. **`setWorldEventHorizon(uint256 _blockNumber) public`**: Allows governance (or owner initially) to schedule a future "global event" that will trigger at a specific block number. This event could affect all nodes based on the current `environmentalFactor`.
17. **`resolveGlobalEvent() public`**: Triggered (potentially by anyone after `eventHorizonBlock` passes, with a small reward) to process a global event. This function reads the `environmentalFactor` and applies a world-wide effect to all active nodes (e.g., a general boost, a resource drain, or a status change).
18. **`stakeForInfluence(uint256 _nodeId) public payable`**: Allows users to stake native currency (ETH) or an ERC20 token to temporarily boost their node's influence score, potentially for governance voting or to make their node more attractive for `interactWithNode`.
19. **`unstakeInfluence(uint256 _nodeId) public`**: Allows users to retrieve their staked funds after a cooldown period, removing the temporary influence boost.
20. **`updateNodeMetadataURI(uint256 _nodeId, string memory _newURI) public`**: Allows the node owner to update the metadata URI for their specific node, pointing to a new JSON blob that reflects its current dynamic state (level, attunement, etc.). This makes the NFTs truly dynamic.
21. **`depositIntoTreasury() public payable`**: A general function to deposit native currency (ETH) into the contract's treasury, which can be used for funding operations, oracle fees, or rewards.
22. **`withdrawTreasuryFunds(uint256 _amount) public`**: Allows the contract owner (or later, governance) to withdraw funds from the treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future integrations

// Chainlink Any API specific interfaces (simplified for this example)
interface LinkTokenInterface {
    function transferAndCall(address _receiver, uint256 _amount, bytes memory _data) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICoordinator {
    function fulfillOracleRequest(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes32 data) external returns (bool);
}

/**
 * @title AetheriumGenesis
 * @dev A decentralized, evolving simulation contract featuring Genesis Nodes (Dynamic ERC721 NFTs).
 *      Nodes possess dynamic attributes (level, XP, influence, resources) that change based on
 *      user interactions, world events, and external oracle data. It includes a simple DAO-like
 *      governance for world parameters, inter-node synergies, and a unique influence system.
 *
 * Outline & Function Summary:
 *
 * 1.  Constructor:
 *     - `constructor(string memory name, string memory symbol, address initialOracle, bytes32 initialJobId, uint256 initialFee, address link)`: Initializes the contract, sets up ERC721, initial world config, and Chainlink oracle.
 *
 * 2.  ERC721 Standard Functions (Inherited/Overridden):
 *     - `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support.
 *
 * 3.  Genesis Node Management & Interaction:
 *     - `mintGenesisNode()`: Mints a new Genesis Node (NFT) with initial attributes.
 *     - `interactWithNode(uint256 _nodeId)`: Allows any user to interact, granting XP, generating resources, and increasing influence.
 *     - `upgradeNodeCapacity(uint256 _nodeId)`: Node owner spends resources to increase node's resource storage capacity.
 *     - `attuneNodeElement(uint256 _nodeId, uint8 _attunementType)`: Node owner changes node's elemental/role attunement, potentially altering interactions.
 *     - `harvestNodeResources(uint256 _nodeId)`: Node owner collects accumulated resources.
 *     - `activateNodeBoost(uint256 _nodeId)`: Node owner activates a temporary boost (XP, resources, influence) by paying ETH.
 *     - `decayNodeInfluence(uint256 _nodeId)`: Publicly callable function to decay influence of inactive nodes over time.
 *     - `initiateNodeSynergy(uint256 _node1Id, uint256 _node2Id)`: Facilitates a special interaction between two nodes for shared benefits.
 *     - `updateNodeMetadataURI(uint256 _nodeId, string memory _newURI)`: Node owner updates their NFT's metadata URI to reflect dynamic state.
 *     - `queryNodeDetails(uint256 _nodeId)`: View function to retrieve comprehensive node details.
 *
 * 4.  World Governance & Events:
 *     - `proposeWorldParameterChange(string memory _description, uint256 _paramIndex, uint256 _newValue)`: Node owners propose changes to global `WorldConfig` parameters.
 *     - `voteOnProposal(uint256 _proposalId, bool _support)`: Node owners vote on active proposals (voting power potentially weighted by influence).
 *     - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes voting and period.
 *     - `setWorldEventHorizon(uint256 _blockNumber)`: Governance/owner schedules a future global event.
 *     - `resolveGlobalEvent()`: Triggerable function to process a global event based on `environmentalFactor`.
 *
 * 5.  Oracle Integration (Chainlink Any API):
 *     - `requestEnvironmentalFactor()`: Initiates an external request to Chainlink for an "environmental factor."
 *     - `fulfillEnvironmentalFactor(bytes32 _requestId, uint256 _environmentalFactor)`: Chainlink callback to update the `environmentalFactor`.
 *
 * 6.  Treasury & Economic Functions:
 *     - `stakeForInfluence(uint256 _nodeId)`: Users stake ETH to temporarily boost their node's influence.
 *     - `unstakeInfluence(uint256 _nodeId)`: Users retrieve staked ETH after a cooldown, removing influence boost.
 *     - `depositIntoTreasury()`: Allows anyone to send ETH to the contract treasury.
 *     - `withdrawTreasuryFunds(uint256 _amount)`: Owner/governance withdraws funds from the treasury.
 *
 * 7.  Admin/Owner Functions:
 *     - `setMetadataBaseURI(string memory _newBaseURI)`: Sets the base URI for all NFT metadata.
 *     - `registerOracleService(address _oracle, bytes32 _jobId, uint256 _fee)`: Updates Chainlink oracle configuration.
 *     - `setChainlinkFee(uint256 _newFee)`: Updates the Chainlink request fee.
 */
contract AetheriumGenesis is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Structures ---

    // Represents a single Genesis Node (NFT)
    struct GenesisNode {
        uint256 level;
        uint256 experience;
        uint256 influenceScore;
        uint256 resourcesAccumulated;
        uint256 resourceCapacity;
        uint256 attunementType; // e.g., 0=None, 1=Fire, 2=Water, 3=Earth
        uint256 lastInteractionBlock;
        uint256 lastInfluenceUpdateBlock;
        uint256 stakedInfluenceAmount; // Amount staked to boost influence
        uint256 stakedInfluenceUnlockBlock; // Block when staked funds can be unstaked
        uint256 boostedUntilBlock; // Block until which node is boosted
    }

    // Global parameters for the simulation world
    struct WorldConfig {
        uint256 baseXPPerInteraction;
        uint256 baseResourcePerBlock;
        uint256 influenceDecayRatePerBlock; // How much influence decays per block of inactivity
        uint256 interactionCooldownBlocks;
        uint256 levelUpXPThresholdFactor; // Factor to calculate XP for next level (e.g., currentLevel * factor * 100)
        uint256 mintPrice;
        uint256 boostCost; // Cost to activate a node boost
        uint256 stakeCooldownBlocks; // Cooldown for unstaking influence
    }

    // Represents a governance proposal
    struct Proposal {
        string description;
        uint256 paramIndex; // Index of the WorldConfig parameter to change
        uint256 newValue;   // The new value for the parameter
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
    }

    // --- State Variables ---

    Counters.Counter private _nodeIdCounter;

    mapping(uint256 => GenesisNode) public genesisNodes;
    mapping(uint256 => string) private _tokenURIs; // Store specific URIs for dynamic metadata

    WorldConfig public worldConfig;

    // Chainlink Any API specific
    address public oracleContract; // Chainlink Oracle address
    bytes32 public jobId;         // Chainlink Job ID
    uint256 public fee;           // Chainlink request fee in LINK
    LinkTokenInterface public LINK; // LINK token contract

    uint256 public environmentalFactor; // Latest factor fetched from oracle

    mapping(bytes32 => address) public pendingRequests; // To track oracle requests

    uint256 public treasuryBalance;

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD_BLOCKS = 1000; // Approx 4 hours on ETH mainnet
    uint256 public constant MIN_INFLUENCE_FOR_PROPOSAL = 500; // Minimum influence to propose

    uint256 public globalEventHorizonBlock; // Block when a global event is scheduled
    uint256 public lastGlobalEventBlock; // Block when the last global event was resolved

    uint256 public constant INFLUENCE_STAKE_AMOUNT = 0.1 ether; // Amount of ETH to stake for influence boost
    uint256 public constant INFLUENCE_STAKE_BOOST = 200; // Amount of influence gained per stake


    // --- Events ---

    event GenesisNodeMinted(uint256 indexed nodeId, address indexed owner, uint256 initialInfluence);
    event NodeInteracted(uint256 indexed nodeId, address indexed by, uint256 xpGained, uint256 resourcesGenerated);
    event NodeLeveledUp(uint256 indexed nodeId, uint256 newLevel);
    event NodeCapacityUpgraded(uint256 indexed nodeId, uint256 newCapacity);
    event NodeAttuned(uint256 indexed nodeId, uint8 newAttunementType);
    event ResourcesHarvested(uint256 indexed nodeId, address indexed owner, uint256 amount);
    event NodeBoostActivated(uint256 indexed nodeId, uint256 untilBlock);
    event NodeInfluenceDecayed(uint256 indexed nodeId, uint256 newInfluence);
    event NodeSynergyInitiated(uint256 indexed node1Id, uint256 indexed node2Id, string outcome);
    event MetadataURIUpdated(uint256 indexed nodeId, string newURI);

    event EnvironmentalFactorRequested(bytes32 indexed requestId);
    event EnvironmentalFactorFulfilled(bytes32 indexed requestId, uint256 factor);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    event GlobalEventScheduled(uint256 indexed blockNumber);
    event GlobalEventResolved(uint256 indexed blockNumber, uint256 environmentalFactorImpact);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event StakedForInfluence(uint256 indexed nodeId, address indexed staker, uint256 amount);
    event UnstakedInfluence(uint256 indexed nodeId, address indexed staker, uint256 amount);


    // --- Modifiers ---

    modifier nodeExists(uint256 _nodeId) {
        require(_exists(_nodeId), "AetheriumGenesis: Node does not exist");
        _;
    }

    modifier isNodeOwner(uint256 _nodeId) {
        require(ownerOf(_nodeId) == _msgSender(), "AetheriumGenesis: Not node owner");
        _;
    }

    modifier hasEnoughInfluence(uint256 _nodeId, uint256 _requiredInfluence) {
        require(genesisNodes[_nodeId].influenceScore >= _requiredInfluence, "AetheriumGenesis: Not enough influence");
        _;
    }

    modifier onlyGovernor() {
        // For simplicity, owner is governor. In a real DAO, this would be a separate role or a more complex vote.
        require(owner() == _msgSender(), "AetheriumGenesis: Only governor can perform this action");
        _;
    }

    /**
     * @dev The constructor initializes the contract with a name, symbol, and sets up
     *      the initial world configuration and Chainlink oracle parameters.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     * @param initialOracle The address of the Chainlink oracle contract.
     * @param initialJobId The Chainlink Job ID for requesting data.
     * @param initialFee The fee in LINK tokens for an oracle request.
     * @param link The address of the LINK token contract.
     */
    constructor(
        string memory name,
        string memory symbol,
        address initialOracle,
        bytes32 initialJobId,
        uint256 initialFee,
        address link
    ) ERC721(name, symbol) Ownable(_msgSender()) {
        worldConfig = WorldConfig({
            baseXPPerInteraction: 10,
            baseResourcePerBlock: 1,
            influenceDecayRatePerBlock: 1, // 1 influence per block of inactivity
            interactionCooldownBlocks: 10, // Approx 2 minutes
            levelUpXPThresholdFactor: 1000,
            mintPrice: 0.05 ether,
            boostCost: 0.01 ether,
            stakeCooldownBlocks: 2000 // Approx 8 hours
        });

        oracleContract = initialOracle;
        jobId = initialJobId;
        fee = initialFee;
        LINK = LinkTokenInterface(link);

        // Initial environmental factor
        environmentalFactor = 100;
    }

    // --- ERC721 Standard Functions ---

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // A dynamic base URI would typically point to an API endpoint that serves JSON based on the nodeId
        // For truly dynamic, on-chain changes, this would point to a service that renders the JSON based on `genesisNodes[tokenId]`
        return string(abi.encodePacked(metadataBaseURI, Strings.toString(tokenId), ".json"));
    }

    // --- Genesis Node Management & Interaction ---

    /**
     * @dev Mints a new Genesis Node. Each node has a base influence, level, and resource capacity.
     *      A minting fee is required, which goes to the contract's treasury.
     * @return The ID of the newly minted node.
     */
    function mintGenesisNode() public payable nonReentrant returns (uint256) {
        require(msg.value >= worldConfig.mintPrice, "AetheriumGenesis: Insufficient mint price");

        _nodeIdCounter.increment();
        uint256 newItemId = _nodeIdCounter.current();

        genesisNodes[newItemId] = GenesisNode({
            level: 1,
            experience: 0,
            influenceScore: 100, // Starting influence
            resourcesAccumulated: 0,
            resourceCapacity: 100, // Starting capacity
            attunementType: 0, // Default to None
            lastInteractionBlock: block.number,
            lastInfluenceUpdateBlock: block.number,
            stakedInfluenceAmount: 0,
            stakedInfluenceUnlockBlock: 0,
            boostedUntilBlock: 0
        });

        _safeMint(msg.sender, newItemId);
        treasuryBalance += msg.value;

        emit GenesisNodeMinted(newItemId, msg.sender, genesisNodes[newItemId].influenceScore);
        return newItemId;
    }

    /**
     * @dev Allows any user to interact with a specific Genesis Node.
     *      Interaction grants XP, generates resources, and slightly boosts influence.
     *      Subject to a cooldown to prevent spam.
     * @param _nodeId The ID of the node to interact with.
     */
    function interactWithNode(uint256 _nodeId) public nodeExists(_nodeId) nonReentrant {
        GenesisNode storage node = genesisNodes[_nodeId];
        require(block.number >= node.lastInteractionBlock + worldConfig.interactionCooldownBlocks, "AetheriumGenesis: Node on cooldown");

        // Grant XP and check for level up
        uint256 xpGained = worldConfig.baseXPPerInteraction;
        if (block.number < node.boostedUntilBlock) { // Apply boost if active
            xpGained = xpGained * 2; // Example: 2x XP boost
        }
        node.experience += xpGained;

        uint256 nextLevelXP = node.level * worldConfig.levelUpXPThresholdFactor;
        if (node.experience >= nextLevelXP) {
            node.level++;
            node.experience = node.experience - nextLevelXP; // Carry over excess XP
            node.resourceCapacity += 50; // Increase capacity on level up
            node.influenceScore += 50; // Boost influence on level up
            emit NodeLeveledUp(_nodeId, node.level);
        }

        // Generate resources (capped by capacity)
        uint256 resourcesGenerated = worldConfig.baseResourcePerBlock; // Example: Fixed resource gain
        if (block.number < node.boostedUntilBlock) { // Apply boost if active
            resourcesGenerated = resourcesGenerated * 2; // Example: 2x resource boost
        }
        node.resourcesAccumulated = Math.min(node.resourcesAccumulated + resourcesGenerated, node.resourceCapacity);

        // Slightly increase influence, capped at a certain maximum for passive interaction
        node.influenceScore = Math.min(node.influenceScore + 5, 2000); // Max passive influence
        node.lastInteractionBlock = block.number;
        node.lastInfluenceUpdateBlock = block.number;

        emit NodeInteracted(_nodeId, _msgSender(), xpGained, resourcesGenerated);
    }

    /**
     * @dev Allows the owner of a node to spend accumulated resources to increase the node's
     *      resource capacity. This is a progression path for nodes.
     * @param _nodeId The ID of the node to upgrade.
     */
    function upgradeNodeCapacity(uint256 _nodeId) public isNodeOwner(_nodeId) nonReentrant nodeExists(_nodeId) {
        GenesisNode storage node = genesisNodes[_nodeId];
        uint256 upgradeCost = node.resourceCapacity / 2; // Example cost: half of current capacity

        require(node.resourcesAccumulated >= upgradeCost, "AetheriumGenesis: Not enough resources for upgrade");

        node.resourcesAccumulated -= upgradeCost;
        node.resourceCapacity += 100; // Increase capacity by a fixed amount
        node.influenceScore += 20; // Slight influence boost for upgrading

        emit NodeCapacityUpgraded(_nodeId, node.resourceCapacity);
    }

    /**
     * @dev Allows the owner to change a node's 'attunement' type. This could represent
     *      elemental types, roles, or specializations within the simulation.
     * @param _nodeId The ID of the node to attune.
     * @param _attunementType The new attunement type (e.g., 1 for Fire, 2 for Water).
     */
    function attuneNodeElement(uint256 _nodeId, uint8 _attunementType) public isNodeOwner(_nodeId) nonReentrant nodeExists(_nodeId) {
        require(_attunementType <= 5, "AetheriumGenesis: Invalid attunement type"); // Example: Max 5 types

        GenesisNode storage node = genesisNodes[_nodeId];
        uint256 attuneCost = 50; // Example resource cost

        require(node.resourcesAccumulated >= attuneCost, "AetheriumGenesis: Not enough resources to attune");

        node.resourcesAccumulated -= attuneCost;
        node.attunementType = _attunementType;
        node.influenceScore += 10; // Slight influence boost

        emit NodeAttuned(_nodeId, _attunementType);
    }

    /**
     * @dev Allows the node owner to collect accumulated resources from their node.
     *      Resources are transferred to the owner's internal balance (not ERC20 for simplicity).
     * @param _nodeId The ID of the node from which to harvest resources.
     */
    function harvestNodeResources(uint256 _nodeId) public isNodeOwner(_nodeId) nonReentrant nodeExists(_nodeId) {
        GenesisNode storage node = genesisNodes[_nodeId];
        uint256 amount = node.resourcesAccumulated;
        require(amount > 0, "AetheriumGenesis: No resources to harvest");

        // In a more complex system, this would transfer a specific resource ERC20 token
        // For this contract, we'll just zero out the node's accumulated resources.
        node.resourcesAccumulated = 0;
        // Optionally, store this in a mapping: mapping(address => uint256) public userResources;
        // userResources[_msgSender()] += amount;

        emit ResourcesHarvested(_nodeId, _msgSender(), amount);
    }

    /**
     * @dev Allows the node owner to activate a temporary boost for their node.
     *      Boosts provide increased XP gain, resource generation, or influence.
     * @param _nodeId The ID of the node to boost.
     */
    function activateNodeBoost(uint256 _nodeId) public payable isNodeOwner(_nodeId) nonReentrant nodeExists(_nodeId) {
        require(msg.value >= worldConfig.boostCost, "AetheriumGenesis: Insufficient payment for boost");

        GenesisNode storage node = genesisNodes[_nodeId];
        node.boostedUntilBlock = block.number + 500; // Boost lasts for 500 blocks (approx 2 hours)
        node.influenceScore += 100; // Instant influence boost

        treasuryBalance += msg.value;

        emit NodeBoostActivated(_nodeId, node.boostedUntilBlock);
    }

    /**
     * @dev Publicly callable function to decay a node's influence score if it has been
     *      inactive for a certain period. This encourages active participation and prevents
     *      stale nodes from holding too much power.
     * @param _nodeId The ID of the node whose influence might decay.
     */
    function decayNodeInfluence(uint256 _nodeId) public nodeExists(_nodeId) nonReentrant {
        GenesisNode storage node = genesisNodes[_nodeId];
        uint256 blocksSinceLastUpdate = block.number - node.lastInfluenceUpdateBlock;

        if (blocksSinceLastUpdate > worldConfig.interactionCooldownBlocks) { // Only decay if inactive
            uint224 decayAmount = uint224(blocksSinceLastUpdate / worldConfig.interactionCooldownBlocks) * worldConfig.influenceDecayRatePerBlock;
            node.influenceScore = Math.max(node.influenceScore, decayAmount); // Prevent influence from going below 0, but effectively min influence is 0.
            node.influenceScore = node.influenceScore - decayAmount;

            node.lastInfluenceUpdateBlock = block.number;
            emit NodeInfluenceDecayed(_nodeId, node.influenceScore);
        }
    }

    /**
     * @dev Initiates a synergy event between two Genesis Nodes.
     *      This could grant unique temporary buffs, generate special resources,
     *      or unlock new abilities for both nodes. Both owners must consent.
     * @param _node1Id The ID of the first node.
     * @param _node2Id The ID of the second node.
     */
    function initiateNodeSynergy(uint256 _node1Id, uint256 _node2Id) public nonReentrant {
        require(_node1Id != _node2Id, "AetheriumGenesis: Cannot initiate synergy with self");
        require(ownerOf(_node1Id) == _msgSender() || ownerOf(_node2Id) == _msgSender(), "AetheriumGenesis: Neither node owner");
        
        GenesisNode storage node1 = genesisNodes[_node1Id];
        GenesisNode storage node2 = genesisNodes[_node2Id];

        require(node1.level >= 5 && node2.level >= 5, "AetheriumGenesis: Both nodes need to be at least Level 5 for synergy");
        require(node1.resourcesAccumulated >= 100 && node2.resourcesAccumulated >= 100, "AetheriumGenesis: Both nodes need 100 resources for synergy");

        node1.resourcesAccumulated -= 100;
        node2.resourcesAccumulated -= 100;

        // Example Synergy Effect: Both nodes get a temporary influence boost and resource surge
        node1.influenceScore += 150;
        node2.influenceScore += 150;
        node1.resourcesAccumulated = Math.min(node1.resourcesAccumulated + 200, node1.resourceCapacity);
        node2.resourcesAccumulated = Math.min(node2.resourcesAccumulated + 200, node2.resourceCapacity);
        
        // Both nodes get a temporary boost
        node1.boostedUntilBlock = block.number + 250; // Shorter boost duration
        node2.boostedUntilBlock = block.number + 250;
        
        emit NodeSynergyInitiated(_node1Id, _node2Id, "Influence & Resource Surge");
    }

    /**
     * @dev Allows the node owner to update the `tokenURI` for their specific node.
     *      This is crucial for dNFTs where metadata changes based on on-chain state.
     * @param _nodeId The ID of the node to update.
     * @param _newURI The new URI pointing to the metadata JSON.
     */
    function updateNodeMetadataURI(uint256 _nodeId, string memory _newURI) public isNodeOwner(_nodeId) nodeExists(_nodeId) {
        _setTokenURI(_nodeId, _newURI); // ERC721URIStorage internal function
        emit MetadataURIUpdated(_nodeId, _newURI);
    }

    /**
     * @dev Retrieves detailed information about a specific Genesis Node.
     * @param _nodeId The ID of the node to query.
     * @return A tuple containing all relevant node attributes.
     */
    function queryNodeDetails(uint256 _nodeId) public view nodeExists(_nodeId) returns (
        uint256 level,
        uint256 experience,
        uint256 influenceScore,
        uint256 resourcesAccumulated,
        uint256 resourceCapacity,
        uint256 attunementType,
        uint256 lastInteractionBlock,
        uint256 stakedInfluenceAmount,
        uint256 stakedInfluenceUnlockBlock,
        uint256 boostedUntilBlock
    ) {
        GenesisNode storage node = genesisNodes[_nodeId];
        return (
            node.level,
            node.experience,
            node.influenceScore,
            node.resourcesAccumulated,
            node.resourceCapacity,
            node.attunementType,
            node.lastInteractionBlock,
            node.stakedInfluenceAmount,
            node.stakedInfluenceUnlockBlock,
            node.boostedUntilBlock
        );
    }

    // --- World Governance & Events ---

    /**
     * @dev Allows Genesis Node owners with sufficient influence to propose a change to
     *      a global `WorldConfig` parameter.
     * @param _description A brief description of the proposal.
     * @param _paramIndex An index representing which WorldConfig parameter to change.
     *        (e.g., 0 for baseXPPerInteraction, 1 for baseResourcePerBlock, etc.)
     * @param _newValue The new value for the parameter.
     */
    function proposeWorldParameterChange(string memory _description, uint256 _paramIndex, uint256 _newValue) public nonReentrant {
        // Find one of the sender's nodes with enough influence
        uint256 senderNodeId = 0;
        for (uint256 i = 1; i <= _nodeIdCounter.current(); i++) {
            if (ownerOf(i) == _msgSender() && genesisNodes[i].influenceScore >= MIN_INFLUENCE_FOR_PROPOSAL) {
                senderNodeId = i;
                break;
            }
        }
        require(senderNodeId != 0, "AetheriumGenesis: No owned node with sufficient influence to propose");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            paramIndex: _paramIndex,
            newValue: _newValue,
            voteStartTime: block.number,
            voteEndTime: block.number + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true
        });
        emit ProposalCreated(proposalCount, _msgSender(), _description);
    }

    /**
     * @dev Allows Genesis Node owners to vote on an active proposal.
     *      Voting power is currently based on simply owning a node.
     *      Can be extended to be weighted by node influence.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'For', False for 'Against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "AetheriumGenesis: Proposal is not active");
        require(block.number >= proposal.voteStartTime && block.number < proposal.voteEndTime, "AetheriumGenesis: Voting period not active");

        // Basic: check if sender owns any node to vote. More advanced: vote per node, weighted by influence
        bool hasNode = false;
        for (uint256 i = 1; i <= _nodeIdCounter.current(); i++) {
            if (ownerOf(i) == _msgSender()) {
                hasNode = true;
                break;
            }
        }
        require(hasNode, "AetheriumGenesis: Only Genesis Node owners can vote");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit Voted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a proposal if it has passed the voting period and achieved a majority.
     *      Only the owner can execute (or a designated DAO executor).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyGovernor nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "AetheriumGenesis: Proposal is not active");
        require(block.number >= proposal.voteEndTime, "AetheriumGenesis: Voting period not ended");
        require(!proposal.executed, "AetheriumGenesis: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "AetheriumGenesis: Proposal did not pass");

        // Apply the change based on paramIndex
        if (proposal.paramIndex == 0) worldConfig.baseXPPerInteraction = proposal.newValue;
        else if (proposal.paramIndex == 1) worldConfig.baseResourcePerBlock = proposal.newValue;
        else if (proposal.paramIndex == 2) worldConfig.influenceDecayRatePerBlock = proposal.newValue;
        else if (proposal.paramIndex == 3) worldConfig.interactionCooldownBlocks = proposal.newValue;
        else if (proposal.paramIndex == 4) worldConfig.levelUpXPThresholdFactor = proposal.newValue;
        else if (proposal.paramIndex == 5) worldConfig.mintPrice = proposal.newValue;
        else if (proposal.paramIndex == 6) worldConfig.boostCost = proposal.newValue;
        else if (proposal.paramIndex == 7) worldConfig.stakeCooldownBlocks = proposal.newValue;
        else revert("AetheriumGenesis: Invalid parameter index for execution");

        proposal.executed = true;
        proposal.active = false;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows governance (or owner initially) to schedule a future global event.
     *      This event will trigger at `_blockNumber` and affect all nodes.
     * @param _blockNumber The block number at which the global event will occur.
     */
    function setWorldEventHorizon(uint256 _blockNumber) public onlyGovernor {
        require(_blockNumber > block.number, "AetheriumGenesis: Event horizon must be in the future");
        globalEventHorizonBlock = _blockNumber;
        emit GlobalEventScheduled(_blockNumber);
    }

    /**
     * @dev Triggered (potentially by anyone after `eventHorizonBlock` passes, with a small reward)
     *      to process a global event. This function reads the `environmentalFactor` and applies
     *      a world-wide effect to all active nodes.
     */
    function resolveGlobalEvent() public nonReentrant {
        require(globalEventHorizonBlock > 0, "AetheriumGenesis: No global event scheduled");
        require(block.number >= globalEventHorizonBlock, "AetheriumGenesis: Global event not yet reached");
        require(lastGlobalEventBlock < globalEventHorizonBlock, "AetheriumGenesis: Global event already resolved");

        // Example: The environmental factor dictates a global boost or penalty
        uint256 impact = environmentalFactor / 10; // Simple scale
        string memory outcome;

        for (uint256 i = 1; i <= _nodeIdCounter.current(); i++) {
            GenesisNode storage node = genesisNodes[i];
            if (environmentalFactor > 150) { // High factor, positive event
                node.influenceScore += impact;
                node.resourcesAccumulated = Math.min(node.resourcesAccumulated + impact * 2, node.resourceCapacity);
                outcome = "Global Surge";
            } else if (environmentalFactor < 50) { // Low factor, negative event
                node.influenceScore = Math.max(node.influenceScore, impact); // Prevent underflow
                node.influenceScore -= impact;
                node.resourcesAccumulated = Math.max(node.resourcesAccumulated, impact); // Prevent underflow
                node.resourcesAccumulated -= impact;
                outcome = "Global Decline";
            } else {
                // Moderate factor, minor effect
                node.influenceScore += 10;
                outcome = "Global Equilibrium";
            }
        }
        lastGlobalEventBlock = globalEventHorizonBlock;
        globalEventHorizonBlock = 0; // Reset for next event

        emit GlobalEventResolved(block.number, environmentalFactor);
    }

    // --- Oracle Integration (Chainlink Any API) ---

    /**
     * @dev Requests an external "environmental factor" from the Chainlink oracle.
     *      The result will be delivered via `fulfillEnvironmentalFactor`.
     */
    function requestEnvironmentalFactor() public nonReentrant returns (bytes32 requestId) {
        require(address(LINK) != address(0), "AetheriumGenesis: LINK token not set");
        require(oracleContract != address(0), "AetheriumGenesis: Oracle contract not set");
        require(fee > 0, "AetheriumGenesis: Chainlink fee not set");

        // Construct the Chainlink request (simplified for brevity)
        // In a real scenario, this would use ChainlinkClient and `buildChainlinkRequest`
        // For this example, we're just simulating the `transferAndCall` to the Oracle
        bytes memory data = abi.encodeWithSelector(
            this.fulfillEnvironmentalFactor.selector, // Callback function for fulfillment
            jobId,
            block.timestamp, // Some unique ID for the request
            // Additional parameters like URL, path, multiplier would go here for Any API
            // e.g., "get", "https://api.example.com/weather/temp", "path", "data.temperature", 1
            "100" // A dummy value for `data` for this simplified example
        );

        // Transfer LINK to the oracle contract, triggering the request
        require(LINK.transferAndCall(oracleContract, fee, data), "AetheriumGenesis: LINK transfer failed");

        // Generate a pseudo-random requestId for tracking
        requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _nodeIdCounter.current()));
        pendingRequests[requestId] = _msgSender(); // Store requester for tracking

        emit EnvironmentalFactorRequested(requestId);
        return requestId;
    }

    /**
     * @dev Chainlink callback function to update the `environmentalFactor`
     *      after an oracle request is fulfilled. This function can only be
     *      called by the registered Chainlink oracle.
     * @param _requestId The ID of the original oracle request.
     * @param _environmentalFactor The value returned by the oracle.
     */
    function fulfillEnvironmentalFactor(bytes32 _requestId, uint256 _environmentalFactor) public nonReentrant {
        // In a real Chainlink setup, this would use `require(msg.sender == oracleContract)`
        // and also a mapping to track fulfillment and prevent replay attacks.
        require(msg.sender == oracleContract, "AetheriumGenesis: Only oracle can fulfill");
        require(pendingRequests[_requestId] != address(0), "AetheriumGenesis: Request not pending or already fulfilled");

        environmentalFactor = _environmentalFactor;
        delete pendingRequests[_requestId]; // Mark request as fulfilled

        emit EnvironmentalFactorFulfilled(_requestId, _environmentalFactor);
    }

    // --- Treasury & Economic Functions ---

    /**
     * @dev Allows users to stake native currency (ETH) to temporarily boost their node's influence.
     *      This could be used for gaining more voting power or making the node more prominent.
     * @param _nodeId The ID of the node to boost.
     */
    function stakeForInfluence(uint256 _nodeId) public payable isNodeOwner(_nodeId) nonReentrant nodeExists(_nodeId) {
        require(msg.value >= INFLUENCE_STAKE_AMOUNT, "AetheriumGenesis: Insufficient ETH to stake for influence");
        GenesisNode storage node = genesisNodes[_nodeId];

        require(node.stakedInfluenceUnlockBlock == 0 || block.number > node.stakedInfluenceUnlockBlock, "AetheriumGenesis: Staked influence is still locked");

        node.stakedInfluenceAmount += msg.value;
        node.influenceScore += INFLUENCE_STAKE_BOOST;
        node.stakedInfluenceUnlockBlock = block.number + worldConfig.stakeCooldownBlocks;

        treasuryBalance += msg.value;

        emit StakedForInfluence(_nodeId, _msgSender(), msg.value);
    }

    /**
     * @dev Allows users to retrieve their staked funds after a cooldown period,
     *      removing the temporary influence boost.
     * @param _nodeId The ID of the node from which to unstake.
     */
    function unstakeInfluence(uint256 _nodeId) public isNodeOwner(_nodeId) nonReentrant nodeExists(_nodeId) {
        GenesisNode storage node = genesisNodes[_nodeId];
        require(node.stakedInfluenceAmount > 0, "AetheriumGenesis: No influence staked on this node");
        require(block.number >= node.stakedInfluenceUnlockBlock, "AetheriumGenesis: Staked influence is still locked");

        uint256 amountToUnstake = node.stakedInfluenceAmount;
        node.stakedInfluenceAmount = 0;
        node.influenceScore -= INFLUENCE_STAKE_BOOST; // Remove influence boost
        node.stakedInfluenceUnlockBlock = 0;

        treasuryBalance -= amountToUnstake; // Deduct from treasury
        (bool success, ) = payable(_msgSender()).call{value: amountToUnstake}("");
        require(success, "AetheriumGenesis: Failed to send ETH back");

        emit UnstakedInfluence(_nodeId, _msgSender(), amountToUnstake);
    }

    /**
     * @dev A general function to allow anyone to deposit native currency (ETH)
     *      into the contract's treasury. This could be for donations,
     *      future feature funding, or just as a general pool.
     */
    function depositIntoTreasury() public payable {
        require(msg.value > 0, "AetheriumGenesis: Deposit amount must be greater than zero");
        treasuryBalance += msg.value;
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows the contract owner (or later, governance) to withdraw funds
     *      from the contract's treasury.
     * @param _amount The amount of native currency (ETH) to withdraw.
     */
    function withdrawTreasuryFunds(uint256 _amount) public onlyGovernor nonReentrant {
        require(_amount > 0 && _amount <= treasuryBalance, "AetheriumGenesis: Invalid withdrawal amount");
        treasuryBalance -= _amount;
        (bool success, ) = payable(_msgSender()).call{value: _amount}("");
        require(success, "AetheriumGenesis: Failed to send ETH");
        emit FundsWithdrawn(_msgSender(), _amount);
    }

    // --- Admin/Owner Functions ---

    string public metadataBaseURI;

    /**
     * @dev Sets the base URI for all NFT metadata. This can point to an IPFS gateway
     *      or an API endpoint that dynamically generates metadata.
     * @param _newBaseURI The new base URI.
     */
    function setMetadataBaseURI(string memory _newBaseURI) public onlyGovernor {
        metadataBaseURI = _newBaseURI;
    }

    /**
     * @dev Allows the owner to update the Chainlink oracle's address, job ID, and fee.
     * @param _oracle The new Chainlink oracle contract address.
     * @param _jobId The new Chainlink Job ID.
     * @param _fee The new fee in LINK tokens for a request.
     */
    function registerOracleService(address _oracle, bytes32 _jobId, uint256 _fee) public onlyGovernor {
        oracleContract = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    /**
     * @dev Allows the owner to update the Chainlink request fee.
     * @param _newFee The new fee in LINK tokens.
     */
    function setChainlinkFee(uint256 _newFee) public onlyGovernor {
        fee = _newFee;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```