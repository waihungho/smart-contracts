Okay, let's design a smart contract system focused on dynamic NFT-like assets that require resources, produce yield, decay over time, and can be upgraded or even merged. This incorporates elements of gaming, resource management, and DeFi, aiming for complexity and uniqueness.

We'll call this system the "Decentralized Synthesizer Network" (DSN). Users will own "Synthesizer Nodes" represented by NFTs. These nodes consume an "Energy Token" (ERC20) and produce a "Synth Token" (ERC20). Nodes decay over time if not maintained, reducing their production or even stopping. Users can stake nodes to automate resource consumption and yield production within the contract.

**Key Concepts:**

1.  **Synthesizer Nodes (SN):** ERC721 tokens representing the core asset. Each SN has parameters (Level, Health, Efficiency, Decay Rate).
2.  **Energy Token (ET):** ERC20 token consumed by SNs.
3.  **Synth Token (ST):** ERC20 token produced by SNs.
4.  **Decay:** SNs health decreases over time if not maintained. Lower health reduces efficiency.
5.  **Maintenance:** Users pay ET to restore SN health and prevent decay. Can be manual or automatic via staking.
6.  **Staking:** Users lock SN NFTs in the contract to enable automatic maintenance (drawing from user's ET balance) and automated ST yield accumulation.
7.  **Upgrading:** Users can pay tokens/resources to increase an SN's Level, improving efficiency and potentially reducing decay.
8.  **Merging:** Users can combine multiple SNs (burning them) to create a more powerful, higher-level SN (minting a new one or significantly upgrading one of the inputs).
9.  **Internal Balances:** Users deposit ET into the contract and claim ST from an internal balance, simplifying interactions for staked nodes.
10. **Governance:** Parameters (rates, costs, decay factors) can be adjusted by a governing address (or DAO in a more complex version).

**Outline & Function Summary:**

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max
import "@openzeppelin/contracts/utils/Pausable.sol"; // For emergency pause

// --- Contract: DecentralizedSynthesizerNetwork ---
// Manages SynthesizerNode NFTs (ERC721), EnergyToken (ERC20), and SynthToken (ERC20).
// Handles node lifecycle: adding, staking, unstaking, maintenance, upgrading, merging.
// Manages resource consumption (ET), yield production (ST), and node decay.
// Provides internal balance management for users interacting with staked nodes.
// Allows governance over key parameters.

// State Variables:
// - Addresses of associated token contracts (SN_NFT, ET, ST).
// - Global parameters (decay rates, base efficiency, upgrade costs, merge costs, maintenance interval).
// - Mapping for NodeState: stores per-node dynamic data (lastProcessedTime, health, level, efficiency, staked, owner).
// - Mapping for userEnergyBalance: stores user's deposited ET within the contract.
// - Mapping for userSynthBalance: stores user's accumulated ST within the contract.
// - Mapping for nodeOwner: Tracks original owner when NFT is staked in the contract.

// Events:
// - NodeAdded, NodeRemoved, NodeStaked, NodeUnstaked, NodeMaintenance, NodeUpgraded, NodesMerged,
// - EnergyDeposited, EnergyWithdrawn, SynthClaimed,
// - ParameterChanged, Paused, Unpaused.

// Modifiers:
// - onlyGovernor: Restricts access to governance functions.
// - whenNotPaused: Prevents execution when paused.
// - whenPaused: Allows execution only when paused.

// --- Function Summary (Total: 25+ functions) ---

// --- Core Node Management (Requires NFT Ownership/Staking) ---
// 1.  addNodeToNetwork(uint256 nodeId): User transfers SN_NFT to contract to enable interactions.
// 2.  removeNodeFromNetwork(uint256 nodeId): User receives SN_NFT back (must be unstaked).
// 3.  stakeNode(uint256 nodeId): Locks node in contract for automatic management.
// 4.  unstakeNode(uint256 nodeId): Unlocks node, processes state, makes it eligible for removal.
// 5.  performManualMaintenance(uint256 nodeId): User pays ET manually to restore health.
// 6.  upgradeNode(uint256 nodeId): Increases node level, improving stats (consumes resources/tokens).
// 7.  mergeNodes(uint256 nodeId1, uint256 nodeId2, uint256 targetNodeId): Combines two nodes into one, upgrading the target (burns nodeId1, burns nodeId2, upgrades targetNodeId).

// --- Token Management (ET & ST) ---
// 8.  depositEnergy(uint256 amount): User deposits ET into their internal contract balance.
// 9.  withdrawEnergy(uint256 amount): User withdraws ET from their internal contract balance.
// 10. claimSynth(): User claims accumulated ST from their internal contract balance.

// --- State Processing & Calculation (Internal Helpers & Views) ---
// 11. _processNodeState(uint256 nodeId): Internal function to update a node's state (decay, consume, produce) based on time elapsed. Called before state-changing operations on a node.
// 12. _calculateEnergyCost(uint256 nodeId, uint256 timeElapsed): Internal view to estimate ET cost for a duration.
// 13. _calculateSynthProduction(uint256 nodeId, uint256 timeElapsed): Internal view to estimate ST production for a duration.
// 14. _applyDecay(uint256 nodeId, uint256 timeElapsed): Internal function to reduce node health based on time and decay rate.
// 15. _deductEnergy(address user, uint256 amount): Internal function to manage user's internal ET balance.
// 16. _addSynth(address user, uint256 amount): Internal function to manage user's internal ST balance.
// 17. getNodeState(uint256 nodeId): View function to get a node's current dynamic state.
// 18. getUserEnergyBalance(address user): View function for internal ET balance.
// 19. getUserClaimableSynth(address user): View function for internal ST balance.
// 20. calculateNodePotentialYield(uint256 nodeId, uint256 duration): View to estimate future yield.
// 21. calculateNodePotentialCost(uint256 nodeId, uint256 duration): View to estimate future cost.

// --- Governance Functions (onlyGovernor) ---
// 22. setEnergyToken(address tokenAddress): Set ET contract address.
// 23. setSynthToken(address tokenAddress): Set ST contract address.
// 24. setSynthNodeNFT(address tokenAddress): Set SN_NFT contract address.
// 25. setBaseProductionRate(uint256 rate): Set base ST production per unit time/health/efficiency.
// 26. setBaseConsumptionRate(uint256 rate): Set base ET consumption per unit time/health/efficiency.
// 27. setBaseDecayRate(uint256 rate): Set base health decay rate.
// 28. setMaintenanceCostRate(uint256 rate): Set ET cost per health point restored.
// 29. setUpgradeCost(uint256 level, uint256 costET, uint256 costST): Set upgrade costs for a given level.
// 30. setMergeCost(uint256 costET, uint256 costST): Set merge costs.
// 31. setMaintenanceInterval(uint256 interval): Set minimum time between maintenance actions.
// 32. setDecayPenaltyFactor(uint256 factor): Set how decay affects production/consumption.
// 33. pause(): Pause core activities.
// 34. unpause(): Unpause activities.
// 35. withdrawGovernanceFees(IERC20 token, uint256 amount): Withdraw collected fees (if fees were implemented, not explicitly added in basic version but good to include as a governance function type). Let's add a simple mechanism where upgrade/merge costs go to the contract.

// Note: Some functions (like _processNodeState) might be called internally by multiple external functions,
// ensuring state is always up-to-date when a user interacts with a node.
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max
import "@openzeppelin/contracts/utils/Pausable.sol"; // For emergency pause
import "@openzeppelin/contracts/utils/Address.sol"; // For ERC20/ERC721 safe transfers

// --- Contract: DecentralizedSynthesizerNetwork ---
// Manages SynthesizerNode NFTs (ERC721), EnergyToken (ERC20), and SynthToken (ERC20).
// Handles node lifecycle: adding, staking, unstaking, maintenance, upgrading, merging.
// Manages resource consumption (ET), yield production (ST), and node decay.
// Provides internal balance management for users interacting with staked nodes.
// Allows governance over key parameters.

contract DecentralizedSynthesizerNetwork is Ownable, ERC721Holder, Pausable {
    using Address for address;

    // --- State Variables ---

    IERC721 public synthesizerNodeNFT;
    IERC20 public energyToken;
    IERC20 public synthToken;

    // Node State: Dynamic data per node
    struct NodeState {
        uint64 lastProcessedTime; // Timestamp of the last state update
        uint16 health;            // Current health (0-1000, 1000 is max)
        uint8 level;              // Upgrade level (influences rates)
        uint16 efficiency;         // Current efficiency (0-1000, based on health and level)
        bool staked;              // Is the node currently staked?
        address owner;            // The original owner when staked
    }

    mapping(uint256 => NodeState) public nodeStates;
    mapping(uint256 => bool) public nodeExists; // Tracks if a node has been added to the network
    mapping(address => uint256) public userEnergyBalance; // User's internal ET balance
    mapping(address => uint256) public userSynthBalance;  // User's internal ST balance

    // Global Parameters (Configurable by Governance)
    uint256 public baseProductionRatePerEfficiencyPerSec; // ST per sec per 1000 efficiency
    uint256 public baseConsumptionRatePerEfficiencyPerSec; // ET per sec per 1000 efficiency
    uint256 public baseDecayRatePerSecPerNode;            // Health decay per sec per node
    uint256 public decayPenaltyFactor;                  // How much decay affects efficiency (e.g., 10 = 10% health loss reduces efficiency by 1 unit)
    uint256 public maintenanceCostPerHealthPoint;         // ET cost to restore 1 health point
    uint32 public maintenanceInterval;                   // Minimum time between manual maintenance actions (seconds)

    // Upgrade Costs (Level => CostET, CostST)
    struct UpgradeCost {
        uint256 costET;
        uint256 costST;
    }
    mapping(uint8 => UpgradeCost) public upgradeCosts;

    // Merge Costs
    uint256 public mergeCostET;
    uint256 public mergeCostST;

    // Governance Address (using Ownable for simplicity)
    address private governor;

    // --- Events ---

    event NodeAdded(uint256 indexed nodeId, address indexed owner);
    event NodeRemoved(uint256 indexed nodeId, address indexed owner);
    event NodeStaked(uint256 indexed nodeId, address indexed owner);
    event NodeUnstaked(uint256 indexed nodeId, address indexed owner);
    event NodeMaintenance(uint256 indexed nodeId, address indexed owner, uint256 etPaid, uint16 healthRestored);
    event NodeUpgraded(uint256 indexed nodeId, address indexed owner, uint8 newLevel);
    event NodesMerged(uint256 indexed nodeId1, uint256 indexed nodeId2, uint256 indexed targetNodeId, address indexed owner, uint8 newLevel);

    event EnergyDeposited(address indexed user, uint256 amount);
    event EnergyWithdrawn(address indexed user, uint256 amount);
    event SynthClaimed(address indexed user, uint256 amount);

    event ParameterChanged(string paramName, uint256 newValue);
    event TokenAddressChanged(string tokenName, address newAddress);

    // --- Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == owner(), "DSN: Only governor");
        _;
    }

    modifier nodeMustExist(uint256 nodeId) {
        require(nodeExists[nodeId], "DSN: Node does not exist in network");
        _;
    }

    modifier nodeMustBeOwnedOrStaked(uint256 nodeId) {
        require(synthesizerNodeNFT.ownerOf(nodeId) == msg.sender || nodeStates[nodeId].owner == msg.sender, "DSN: Not node owner or staked owner");
        _;
    }

    modifier nodeMustBeStaked(uint256 nodeId) {
        require(nodeStates[nodeId].staked, "DSN: Node must be staked");
        require(nodeStates[nodeId].owner == msg.sender, "DSN: Caller is not the owner of the staked node");
        _;
    }

    modifier nodeMustBeUnstaked(uint256 nodeId) {
        require(!nodeStates[nodeId].staked, "DSN: Node must be unstaked");
        _;
    }

    // --- Constructor ---

    constructor(address _synthesizerNodeNFT, address _energyToken, address _synthToken) Ownable(msg.sender) Pausable(false) {
        synthesizerNodeNFT = IERC721(_synthesizerNodeNFT);
        energyToken = IERC20(_energyToken);
        synthToken = IERC20(_synthToken);
        governor = msg.sender; // Initial governor is deployer

        // Set some initial default parameters (governor should fine-tune these)
        baseProductionRatePerEfficiencyPerSec = 1; // Example: 1 ST per second per 1000 efficiency
        baseConsumptionRatePerEfficiencyPerSec = 1; // Example: 1 ET per second per 1000 efficiency
        baseDecayRatePerSecPerNode = 1;             // Example: 1 health loss per second per node
        decayPenaltyFactor = 10;                  // Example: 1 health loss reduces efficiency by 1 unit (10 health loss = 10 efficiency loss)
        maintenanceCostPerHealthPoint = 10;       // Example: 10 ET per health point restored
        maintenanceInterval = 1 days;             // Example: Minimum 1 day between manual maintenance
        mergeCostET = 1000 * (10**18); // Example: 1000 ET
        mergeCostST = 500 * (10**18);  // Example: 500 ST

        // Example initial upgrade costs (governor should set proper values)
        // Level 1 cost is 0 (starting level)
        upgradeCosts[2] = UpgradeCost(100 * (10**18), 50 * (10**18)); // Level 2 cost
        upgradeCosts[3] = UpgradeCost(300 * (10**18), 150 * (10**18)); // Level 3 cost
        // Add more levels as needed...
    }

    // Override Ownable transferOwnership to ensure governor is updated
    function transferOwnership(address newOwner) public override onlyOwner {
        governor = newOwner;
        super.transferOwnership(newOwner);
    }

    // --- Core Node Management ---

    /**
     * @notice Allows a user to add their Synthesizer Node NFT to the network.
     * Node must be transferred to the contract. Initial state is set (full health, level 1).
     * @param nodeId The ID of the Synthesizer Node NFT.
     */
    function addNodeToNetwork(uint256 nodeId) external whenNotPaused {
        require(!nodeExists[nodeId], "DSN: Node already in network");
        require(synthesizerNodeNFT.ownerOf(nodeId) == msg.sender, "DSN: Caller is not NFT owner");

        // Transfer NFT to this contract
        synthesizerNodeNFT.safeTransferFrom(msg.sender, address(this), nodeId);

        // Initialize node state
        nodeStates[nodeId] = NodeState({
            lastProcessedTime: uint64(block.timestamp),
            health: 1000, // Max health
            level: 1,
            efficiency: 1000, // Max efficiency at full health level 1
            staked: false,
            owner: msg.sender // Store original owner
        });
        nodeExists[nodeId] = true;

        emit NodeAdded(nodeId, msg.sender);
    }

     /**
     * @notice Allows a user to remove their Synthesizer Node NFT from the network.
     * Node must be unstaked. NFT is transferred back to the user.
     * @param nodeId The ID of the Synthesizer Node NFT.
     */
    function removeNodeFromNetwork(uint256 nodeId) external whenNotPaused nodeMustExist(nodeId) nodeMustBeOwnedOrStaked(nodeId) nodeMustBeUnstaked(nodeId) {
         // Only the original owner can remove
        require(nodeStates[nodeId].owner == msg.sender, "DSN: Only original owner can remove");

        // Clear node state and existence flag
        delete nodeStates[nodeId];
        delete nodeExists[nodeId];

        // Transfer NFT back to original owner
        synthesizerNodeNFT.safeTransferFrom(address(this), msg.sender, nodeId);

        emit NodeRemoved(nodeId, msg.sender);
    }

    /**
     * @notice Stakes a node, enabling automatic maintenance and yield accumulation.
     * The node must exist in the network and be owned by the caller (or already added but unstaked).
     * @param nodeId The ID of the Synthesizer Node NFT.
     */
    function stakeNode(uint256 nodeId) external whenNotPaused nodeMustExist(nodeId) nodeMustBeOwnedOrStaked(nodeId) nodeMustBeUnstaked(nodeId) {
        // Ensure the node is currently owned by the caller or already held by the contract and unstaked
        require(synthesizerNodeNFT.ownerOf(nodeId) == msg.sender || synthesizerNodeNFT.ownerOf(nodeId) == address(this), "DSN: Node not owned by caller or contract");

        // If the node is not yet held by the contract, transfer it
        if (synthesizerNodeNFT.ownerOf(nodeId) == msg.sender) {
             require(nodeStates[nodeId].owner == msg.sender, "DSN: Node not initialized for this owner"); // Should be initialized during addNodeToNetwork
            synthesizerNodeNFT.safeTransferFrom(msg.sender, address(this), nodeId);
        } else {
             require(nodeStates[nodeId].owner == msg.sender, "DSN: Staked node owner mismatch"); // Ensure original owner is caller
        }

        // Process state before staking to calculate pending yield/cost
        _processNodeState(nodeId);

        // Update state to staked
        nodeStates[nodeId].staked = true;
        // nodeStates[nodeId].owner remains the original owner

        emit NodeStaked(nodeId, msg.sender);
    }

    /**
     * @notice Unstakes a node, stopping automatic management.
     * Processes final state updates for yield/cost.
     * Node remains in the contract until removed via removeNodeFromNetwork.
     * @param nodeId The ID of the Synthesizer Node NFT.
     */
    function unstakeNode(uint256 nodeId) external whenNotPaused nodeMustExist(nodeId) nodeMustBeStaked(nodeId) {
        // Process state before unstaking to calculate final yield/cost
        _processNodeState(nodeId);

        // Update state to unstaked
        nodeStates[nodeId].staked = false;

        emit NodeUnstaked(nodeId, msg.sender);
    }

    /**
     * @notice Allows a user to perform manual maintenance on their node (staked or unstaked in network).
     * Pays ET to restore health up to max. Limited by maintenanceInterval.
     * @param nodeId The ID of the Synthesizer Node.
     */
    function performManualMaintenance(uint256 nodeId) external whenNotPaused nodeMustExist(nodeId) nodeMustBeOwnedOrStaked(nodeId) {
        NodeState storage node = nodeStates[nodeId];
        address nodeOwner = node.staked ? node.owner : msg.sender; // Determine who pays

        // If staked, process state first to update health and efficiency
        if (node.staked) {
            _processNodeState(nodeId);
        }

        require(block.timestamp >= node.lastProcessedTime + maintenanceInterval, "DSN: Maintenance interval not passed");
        require(node.health < 1000, "DSN: Node already at max health");

        uint16 healthNeeded = 1000 - node.health;
        uint256 cost = uint256(healthNeeded) * maintenanceCostPerHealthPoint;

        // Deduct cost from user's internal balance
        _deductEnergy(nodeOwner, cost);

        // Restore health and update state
        node.health = 1000;
        node.lastProcessedTime = uint64(block.timestamp); // Update time to reset interval
        // Recalculate efficiency based on new health (level doesn't change)
        node.efficiency = uint16(Math.min(1000, uint256(node.health) * 1000 / (1000 - decayPenaltyFactor) )); // Simplified penalty

        emit NodeMaintenance(nodeId, nodeOwner, cost, healthNeeded);
    }

    /**
     * @notice Upgrades a node's level, increasing its potential efficiency.
     * Requires payment in ET and/or ST. Processes state before upgrading.
     * @param nodeId The ID of the Synthesizer Node.
     */
    function upgradeNode(uint256 nodeId) external whenNotPaused nodeMustExist(nodeId) nodeMustBeOwnedOrStaked(nodeId) {
        NodeState storage node = nodeStates[nodeId];
        address nodeOwner = node.staked ? node.owner : msg.sender; // Determine who pays

        // Process state before upgrading
        _processNodeState(nodeId);

        uint8 currentLevel = node.level;
        uint8 nextLevel = currentLevel + 1;
        UpgradeCost storage cost = upgradeCosts[nextLevel];

        require(cost.costET > 0 || cost.costST > 0, "DSN: No upgrade cost defined for next level");

        // Deduct costs from user's internal balance
        if (cost.costET > 0) {
            _deductEnergy(nodeOwner, cost.costET);
        }
        if (cost.costST > 0) {
            _addSynth(nodeOwner, cost.costST); // Deducting ST requires adding negative, or better, a separate deduction function
             require(userSynthBalance[nodeOwner] >= cost.costST, "DSN: Insufficient ST balance for upgrade");
             userSynthBalance[nodeOwner] -= cost.costST;
        }

        // Apply upgrade
        node.level = nextLevel;
        // Efficiency recalculates based on new level and current health
        node.efficiency = uint16(Math.min(1000, uint256(node.health) * (1000 + nextLevel * 100) / (1000 - decayPenaltyFactor) )); // Example: Level adds 10% base efficiency potential per level

        emit NodeUpgraded(nodeId, nodeOwner, nextLevel);
    }

     /**
     * @notice Merges two nodes into one, significantly upgrading the target node.
     * The source node is burned (transferring to address(0)). The target node's level is increased.
     * Requires payment in ET and/or ST. Nodes must be owned by caller and in the network.
     * @param nodeId1 The ID of the first Synthesizer Node (will be burned).
     * @param nodeId2 The ID of the second Synthesizer Node (will be burned).
     * @param targetNodeId The ID of the node to be upgraded (must be one of nodeId1 or nodeId2).
     */
    function mergeNodes(uint256 nodeId1, uint256 nodeId2, uint256 targetNodeId) external whenNotPaused {
        require(nodeId1 != nodeId2, "DSN: Cannot merge a node with itself");
        require(targetNodeId == nodeId1 || targetNodeId == nodeId2, "DSN: Target node must be one of the source nodes");

        // Get node owners and ensure caller is owner of both
        address owner1 = synthesizerNodeNFT.ownerOf(nodeId1);
        address owner2 = synthesizerNodeNFT.ownerOf(nodeId2);
        require(owner1 == msg.sender && owner2 == msg.sender, "DSN: Caller must own both nodes");
        require(nodeExists[nodeId1] && nodeExists[nodeId2], "DSN: Both nodes must be in the network");
        require(!nodeStates[nodeId1].staked && !nodeStates[nodeId2].staked, "DSN: Nodes must be unstaked to merge"); // Can only merge unstaked nodes held by user

        // Process state for both nodes before merging (claims pending yield/cost)
        _processNodeState(nodeId1);
        _processNodeState(nodeId2);

        // Deduct merge costs from user's internal balance
        if (mergeCostET > 0) {
            _deductEnergy(msg.sender, mergeCostET);
        }
        if (mergeCostST > 0) {
             require(userSynthBalance[msg.sender] >= mergeCostST, "DSN: Insufficient ST balance for merge");
             userSynthBalance[msg.sender] -= mergeCostST;
        }

        // Burn the two source NFTs
        synthesizerNodeNFT.transferFrom(msg.sender, address(0), nodeId1);
        synthesizerNodeNFT.transferFrom(msg.sender, address(0), nodeId2);

        // Remove source nodes from network state
        delete nodeStates[nodeId1];
        delete nodeExists[nodeId1];
        delete nodeStates[nodeId2];
        delete nodeExists[nodeId2];

        // Upgrade the target node (which must have been one of the inputs, but we still need its state)
        // Since the NFT was just transferred to address(0), we can't get its state by ID directly
        // We need to re-add and re-initialize the target node's state first, or handle it differently.
        // Alternative Merge Logic: Don't burn and re-initialize. Burn two, significantly UPGRADE one *already in the network and owned by the user*.
        // Let's refine merge: Merge two *unstaked* nodes user holds -> burn both, upgrade a *different* target node already in the network (owned by user, can be staked or unstaked). This simplifies state management.

        // --- Refined Merge Logic (requires 3 nodes: 2 sacrifice, 1 target) ---
        require(nodeId1 != nodeId2 && nodeId1 != targetNodeId && nodeId2 != targetNodeId, "DSN: Merge nodes must be distinct");
        require(synthesizerNodeNFT.ownerOf(nodeId1) == msg.sender && synthesizerNodeNFT.ownerOf(nodeId2) == msg.sender, "DSN: Caller must own both sacrifice nodes");
        require(nodeExists[nodeId1] && nodeExists[nodeId2], "DSN: Sacrifice nodes must be in the network (unstaked)");
        require(!nodeStates[nodeId1].staked && !nodeStates[nodeId2].staked, "DSN: Sacrifice nodes must be unstaked");

        // Target node must exist in network and be owned by caller (staked or unstaked)
        require(nodeExists[targetNodeId], "DSN: Target node must exist in network");
        require(synthesizerNodeNFT.ownerOf(targetNodeId) == msg.sender || nodeStates[targetNodeId].owner == msg.sender, "DSN: Caller must own or have staked target node");
        address targetNodeOwner = nodeStates[targetNodeId].staked ? nodeStates[targetNodeId].owner : msg.sender; // Determine target node owner for processing/payments
        require(targetNodeOwner == msg.sender, "DSN: Target node owner must be caller"); // Ensure caller owns target node

        NodeState storage targetNode = nodeStates[targetNodeId];

        // Process state for all three nodes before merging
        _processNodeState(nodeId1);
        _processNodeState(nodeId2);
        _processNodeState(targetNodeId);

        // Deduct merge costs from user's internal balance
        if (mergeCostET > 0) {
            _deductEnergy(msg.sender, mergeCostET); // Costs paid by caller
        }
        if (mergeCostST > 0) {
             require(userSynthBalance[msg.sender] >= mergeCostST, "DSN: Insufficient ST balance for merge");
             userSynthBalance[msg.sender] -= mergeCostST; // Costs paid by caller
        }

        // Burn the two source NFTs
        synthesizerNodeNFT.transferFrom(msg.sender, address(0), nodeId1);
        synthesizerNodeNFT.transferFrom(msg.sender, address(0), nodeId2);

        // Remove source nodes from network state
        delete nodeStates[nodeId1];
        delete nodeExists[nodeId1];
        delete nodeStates[nodeId2];
        delete nodeExists[nodeId2];

        // Significantly upgrade the target node
        uint8 newLevel = targetNode.level + 2; // Example: Merge adds 2 levels
        targetNode.level = newLevel;
        // Efficiency recalculates based on new level and current health
        targetNode.efficiency = uint16(Math.min(1000, uint256(targetNode.health) * (1000 + newLevel * 100) / (1000 - decayPenaltyFactor) )); // Example: Level adds 10% base efficiency potential per level
         // Also restore some health upon merge? Let's say full health.
        targetNode.health = 1000;

        // Update target node's last processed time
        targetNode.lastProcessedTime = uint64(block.timestamp);


        emit NodesMerged(nodeId1, nodeId2, targetNodeId, msg.sender, newLevel);
    }

    // --- Token Management ---

    /**
     * @notice Allows a user to deposit Energy Tokens into their internal contract balance.
     * User must first approve this contract to spend the tokens.
     * @param amount The amount of ET to deposit.
     */
    function depositEnergy(uint256 amount) external whenNotPaused {
        require(amount > 0, "DSN: Deposit amount must be positive");
        energyToken.safeTransferFrom(msg.sender, address(this), amount);
        userEnergyBalance[msg.sender] += amount;
        emit EnergyDeposited(msg.sender, amount);
    }

    /**
     * @notice Allows a user to withdraw Energy Tokens from their internal contract balance.
     * @param amount The amount of ET to withdraw.
     */
    function withdrawEnergy(uint256 amount) external whenNotPaused {
        require(amount > 0, "DSN: Withdraw amount must be positive");
        _deductEnergy(msg.sender, amount); // Uses the internal function with balance check
        energyToken.safeTransfer(msg.sender, amount);
        emit EnergyWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Allows a user to claim accumulated Synth Tokens from their internal balance.
     * Processes state for all staked nodes owned by the user before claiming.
     */
    function claimSynth() external whenNotPaused {
        // To claim synth, user must iterate/know which nodes they own/have staked
        // A simpler approach for claiming all: iterate through *all* nodes owned by user in network
        // However, iterating mappings is not gas efficient.
        // A better pattern for claim: _processNodeState is called on specific node interactions.
        // The claim function just transfers the balance accumulated by those interactions.

        uint256 amount = userSynthBalance[msg.sender];
        require(amount > 0, "DSN: No synth tokens to claim");

        userSynthBalance[msg.sender] = 0;
        synthToken.safeTransfer(msg.sender, amount);

        emit SynthClaimed(msg.sender, amount);
    }

    // Internal helper to safely deduct ET from user's internal balance
    function _deductEnergy(address user, uint256 amount) internal {
        require(userEnergyBalance[user] >= amount, "DSN: Insufficient internal ET balance");
        userEnergyBalance[user] -= amount;
    }

    // Internal helper to safely add ST to user's internal balance
    function _addSynth(address user, uint256 amount) internal {
        userSynthBalance[user] += amount; // Simple addition, potential overflow handled by Solidity 0.8+
    }


    // --- State Processing & Calculation ---

    /**
     * @notice Internal function to update a node's state based on time elapsed since last processing.
     * Calculates and applies decay, consumes ET (if staked & available), and produces ST (if staked & healthy).
     * Updates node's health, efficiency, and lastProcessedTime. Updates user's internal balances.
     * @param nodeId The ID of the Synthesizer Node.
     */
    function _processNodeState(uint256 nodeId) internal nodeMustExist(nodeId) {
        NodeState storage node = nodeStates[nodeId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - node.lastProcessedTime;

        if (timeElapsed == 0) {
            return; // Nothing to process if no time has passed
        }

        // --- Apply Decay ---
        uint256 decayAmount = uint256(baseDecayRatePerSecPerNode) * timeElapsed;
        uint16 oldHealth = node.health;
        node.health = uint16(Math.max(0, int256(node.health) - int256(decayAmount))); // Health cannot go below 0

        // Recalculate efficiency based on new health and level
        node.efficiency = uint16(Math.min(1000, uint256(node.health) * (1000 + node.level * 100) / (1000 - decayPenaltyFactor) )); // Example formula

        // --- Process Staked Node Activity (Consumption & Production) ---
        if (node.staked) {
            // Consumption calculation based on efficiency and time
            // Use 1000 as max efficiency unit for calculation
            uint256 energyCost = uint256(node.efficiency) * baseConsumptionRatePerEfficiencyPerSec * timeElapsed / 1000;

            // Production calculation based on efficiency and time
            uint256 synthProduced = uint256(node.efficiency) * baseProductionRatePerEfficiencyPerSec * timeElapsed / 1000;

            // Check if user has enough energy, only consume/produce what's possible
            uint256 energyToConsume = Math.min(energyCost, userEnergyBalance[node.owner]);

            // Only produce if sufficient energy was consumed (or if decay is the limiting factor)
            // Let's simplify: Produce only if energyCost is met OR node health > 0.
            // If energyToConsume < energyCost, production is proportionally reduced.
            uint256 actualSynthProduced = synthProduced * energyToConsume / energyCost;

            // Deduct consumed energy from user's balance
            if (energyToConsume > 0) {
                userEnergyBalance[node.owner] -= energyToConsume;
            }

            // Add produced synth to user's balance
            if (actualSynthProduced > 0) {
                userSynthBalance[node.owner] += actualSynthProduced;
            }
        }

        // Update last processed time
        node.lastProcessedTime = currentTime;
    }

    /**
     * @notice Calculates the estimated Energy Token cost for a node over a duration.
     * This is a view function and does not change state. Assumes constant efficiency over the duration.
     * @param nodeId The ID of the Synthesizer Node.
     * @param duration The time duration in seconds.
     * @return Estimated ET cost.
     */
    function calculateNodePotentialCost(uint256 nodeId, uint256 duration) external view nodeMustExist(nodeId) returns (uint256) {
         NodeState memory node = nodeStates[nodeId];
         // Calculate current effective efficiency (might be reduced by decay)
         uint16 currentEfficiency = uint16(Math.min(1000, uint256(node.health) * (1000 + node.level * 100) / (1000 - decayPenaltyFactor) ));

         // Simple calculation assuming efficiency remains constant
         return uint256(currentEfficiency) * baseConsumptionRatePerEfficiencyPerSec * duration / 1000;
    }

     /**
     * @notice Calculates the estimated Synth Token production for a node over a duration.
     * This is a view function and does not change state. Assumes constant efficiency and sufficient energy over the duration.
     * @param nodeId The ID of the Synthesizer Node.
     * @param duration The time duration in seconds.
     * @return Estimated ST production.
     */
    function calculateNodePotentialYield(uint256 nodeId, uint256 duration) external view nodeMustExist(nodeId) returns (uint256) {
         NodeState memory node = nodeStates[nodeId];
         // Calculate current effective efficiency (might be reduced by decay)
         uint16 currentEfficiency = uint16(Math.min(1000, uint256(node.health) * (1000 + node.level * 100) / (1000 - decayPenaltyFactor) ));

         // Simple calculation assuming efficiency remains constant and energy is available
         return uint256(currentEfficiency) * baseProductionRatePerEfficiencyPerSec * duration / 1000;
    }

    /**
     * @notice Gets the current state of a specific node.
     * @param nodeId The ID of the Synthesizer Node.
     * @return NodeState struct.
     */
    function getNodeState(uint256 nodeId) external view nodeMustExist(nodeId) returns (NodeState memory) {
        // Note: This view function returns the state *as it was* at the last processing time.
        // To get the state *now*, you'd need to simulate _processNodeState.
        // For simplicity here, we return the stored state. A more advanced version might include
        // a helper view function that calculates the state at block.timestamp without saving it.
        // Example of calculating current (simulated) state:
        // NodeState memory currentState = nodeStates[nodeId];
        // uint64 timeElapsed = uint64(block.timestamp) - currentState.lastProcessedTime;
        // uint16 simulatedHealth = uint16(Math.max(0, int256(currentState.health) - int256(uint256(baseDecayRatePerSecPerNode) * timeElapsed)));
        // currentState.health = simulatedHealth; // Update health in the memory struct
        // currentState.efficiency = uint16(Math.min(1000, uint256(simulatedHealth) * (1000 + currentState.level * 100) / (1000 - decayPenaltyFactor) ));
        // currentState.lastProcessedTime = uint64(block.timestamp); // Update time in memory struct
        // return currentState;
        return nodeStates[nodeId]; // Returning stored state for simplicity
    }

    /**
     * @notice Gets the internal Energy Token balance for a user.
     * @param user The address of the user.
     * @return User's internal ET balance.
     */
    function getUserEnergyBalance(address user) external view returns (uint256) {
        return userEnergyBalance[user];
    }

    /**
     * @notice Gets the internal claimable Synth Token balance for a user.
     * @param user The address of the user.
     * @return User's internal ST balance.
     */
    function getUserClaimableSynth(address user) external view returns (uint256) {
        return userSynthBalance[user];
    }

    // --- Governance Functions ---

    function setEnergyToken(address tokenAddress) external onlyGovernor {
        require(tokenAddress != address(0), "DSN: Invalid address");
        energyToken = IERC20(tokenAddress);
        emit TokenAddressChanged("EnergyToken", tokenAddress);
    }

    function setSynthToken(address tokenAddress) external onlyGovernor {
        require(tokenAddress != address(0), "DSN: Invalid address");
        synthToken = IERC20(tokenAddress);
        emit TokenAddressChanged("SynthToken", tokenAddress);
    }

    function setSynthesizerNodeNFT(address tokenAddress) external onlyGovernor {
        require(tokenAddress != address(0), "DSN: Invalid address");
        synthesizerNodeNFT = IERC721(tokenAddress);
        emit TokenAddressChanged("SynthesizerNodeNFT", tokenAddress);
    }

    function setBaseProductionRate(uint256 rate) external onlyGovernor {
        baseProductionRatePerEfficiencyPerSec = rate;
        emit ParameterChanged("baseProductionRatePerEfficiencyPerSec", rate);
    }

    function setBaseConsumptionRate(uint256 rate) external onlyGovernor {
        baseConsumptionRatePerEfficiencyPerSec = rate;
        emit ParameterChanged("baseConsumptionRatePerEfficiencyPerSec", rate);
    }

    function setBaseDecayRate(uint256 rate) external onlyGovernor {
        baseDecayRatePerSecPerNode = rate;
        emit ParameterChanged("baseDecayRatePerSecPerNode", rate);
    }

    function setDecayPenaltyFactor(uint256 factor) external onlyGovernor {
        require(factor < 1000, "DSN: Decay penalty factor too high"); // Prevent division by zero/near zero
        decayPenaltyFactor = factor;
        emit ParameterChanged("decayPenaltyFactor", factor);
    }


    function setMaintenanceCostRate(uint256 rate) external onlyGovernor {
        maintenanceCostPerHealthPoint = rate;
        emit ParameterChanged("maintenanceCostPerHealthPoint", rate);
    }

    function setMaintenanceInterval(uint32 interval) external onlyGovernor {
        maintenanceInterval = interval;
        emit ParameterChanged("maintenanceInterval", interval);
    }

    function setUpgradeCost(uint8 level, uint256 costET, uint256 costST) external onlyGovernor {
        require(level > 1, "DSN: Cannot set cost for base level 1");
        upgradeCosts[level] = UpgradeCost(costET, costST);
        emit ParameterChanged(string(abi.encodePacked("upgradeCostLevel", level)), costET + costST); // Log combined cost
    }

     function setMergeCost(uint256 costET, uint256 costST) external onlyGovernor {
        mergeCostET = costET;
        mergeCostST = costST;
        emit ParameterChanged("mergeCostET", costET);
        emit ParameterChanged("mergeCostST", costST);
    }


    /**
     * @notice Emergency pause function. Stops core activities like adding, staking, transactions.
     * Governance functions and withdrawals/claims might still be possible depending on implementation.
     * Here, most user interactions are paused.
     */
    function pause() external onlyGovernor whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause the contract.
     */
    function unpause() external onlyGovernor whenPaused {
        _unpause();
    }

     /**
     * @notice Allows governance to withdraw accumulated tokens (e.g., from upgrade/merge costs).
     * @param token The address of the token to withdraw (ET or ST).
     * @param amount The amount to withdraw.
     */
    function withdrawGovernanceFunds(IERC20 token, uint256 amount) external onlyGovernor {
        require(amount > 0, "DSN: Amount must be positive");
        require(address(token) == address(energyToken) || address(token) == address(synthToken), "DSN: Can only withdraw ET or ST");
        token.safeTransfer(msg.sender, amount);
    }

    // --- ERC721Holder required function ---
    // This contract can receive ERC721 tokens (the Synthesizer Nodes)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Basic check: ensure this is from the correct NFT contract and being sent from a user.
        // More robust checks could be added based on `data` if needed for specific workflows.
        require(msg.sender == address(synthesizerNodeNFT), "DSN: Only configured NFT can be received");
        // We don't explicitly check `from` here as `safeTransferFrom` from the user handles permissions.
        // The `addNodeToNetwork` function ensures the node isn't already tracked.
        // The `stakeNode` function handles nodes already held by the contract.
        return this.onERC721Received.selector;
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFT State:** The `NodeState` struct associated with each `nodeId` allows the NFT to have dynamic properties (`health`, `level`, `efficiency`) that change over time and through contract interactions, rather than being static metadata.
2.  **Resource Management and Decay:** The inclusion of an `EnergyToken` and a decay mechanism adds a cost and a challenge for users. Nodes aren't passive yield generators; they require active management (maintenance) or sufficient deposited resources (staking). This mirrors resource management mechanics in games.
3.  **Time-Based Mechanics:** Decay, consumption, and production are explicitly calculated based on time elapsed (`lastProcessedTime`). This lazy evaluation (`_processNodeState`) means calculations only happen when a user interacts with a specific node, saving gas compared to a system that might process all nodes every block.
4.  **Staking for Automation:** The staking mechanism (`stakeNode`) provides a convenient way for users to have the contract automatically handle resource consumption and yield accumulation from their internal balance, simplifying user interaction for active nodes.
5.  **Internal Token Balances:** Depositing tokens into the contract (`userEnergyBalance`, `userSynthBalance`) keeps operational funds separate from a user's main wallet, potentially improving gas efficiency for frequent small transactions within the network and simplifying the logic for staked node interactions.
6.  **NFT Merging/Burning for Upgrade:** The `mergeNodes` function introduces a mechanism where NFTs (nodes) are burned to facilitate a significant upgrade on another NFT. This is a common pattern in advanced NFT systems (gaming, collectibles) but requires careful handling of NFT ownership and state transitions within the contract.
7.  **Parametric Governance:** Key economic and operational parameters (rates, costs, intervals) are exposed via governance functions (`onlyGovernor`). This allows for tuning the system dynamics post-deployment, essential for complex simulations or economies. While using `Ownable` is simple, this structure is designed to be easily swapped for a more complex DAO governance module.
8.  **Layered Efficiency Calculation:** Node `efficiency` is not a static value but is derived from its `health` and `level`, introducing non-linear dynamics where decay directly impacts yield and cost. The `decayPenaltyFactor` adds another tunable layer.
9.  **Conditional Production/Consumption:** Staked nodes only produce/consume *if* they have health and *if* the user has sufficient internal energy (consumption limits production).
10. **ERC721Holder Pattern:** Properly implementing `onERC721Received` ensures the contract can safely receive and hold the Node NFTs, a standard but necessary pattern for contracts that custody NFTs.
11. **Pausable Functionality:** Includes an emergency `pause`/`unpause` mechanism, a standard but crucial safety feature for complex contracts.

This contract is significantly more complex than a basic ERC20/ERC721 or simple staking contract. It involves multiple token standards interacting with dynamic state variables associated with NFTs, resource flow, time-based mechanics, and destructive operations (merging/burning). The design prioritizes calculating state changes only upon interaction with a specific node (`_processNodeState`), which is a common pattern for gas efficiency in systems with many stateful items.

**Important Considerations for a Production System:**

*   **Gas Costs:** Complex calculations within `_processNodeState` could be expensive for long periods of inactivity. Optimizing this logic is crucial.
*   **Precision:** Using integer arithmetic throughout requires careful scaling (e.g., using 1e18 for rates, though here we used simpler units like 1000 for efficiency for clarity). Fixed-point math libraries could be used for more precision.
*   **Upgradeability:** For a real-world system, this contract would likely need to be upgradeable (using proxies like UUPS or Transparent).
*   **Robust Governance:** The `onlyGovernor` pattern is centralized. A decentralized system would integrate a DAO for parameter changes.
*   **Error Handling & Edge Cases:** More comprehensive `require` statements and error messages would be needed.
*   **Front-running:** While less critical for most functions here, state-changing functions could potentially be subject to minor front-running influencing the outcome of the `_processNodeState` calculation based on timestamp.
*   **Scalability:** Storing state for *every* node in mappings is standard, but querying/listing all nodes owned by a user requires external indexing (like The Graph) as iterating mappings in Solidity is not feasible.
*   **Auditing:** A contract this complex requires rigorous auditing.