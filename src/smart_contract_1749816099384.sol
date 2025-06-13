Okay, here is a Solidity smart contract incorporating several advanced and creative concepts, focusing on dynamic NFT state, interaction, staking, and yield generation within a simulated environment. This is designed to be distinct from standard ERC20/ERC721 extensions or simple staking/farming contracts.

The theme is a "Dynamic Node Network" where NFTs (Nodes) have mutable attributes, can be staked upon with a custom fungible token (Shards), and can undergo complex interactions (Synthesis) or yield generation (Harvest) based on their state and vitality, which also decays over time.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleOfTheShiftingSands
 * @dev A smart contract managing dynamic NFTs (Nodes) and a custom fungible token (Shards).
 * Nodes have states, vitality, and purity, which change based on actions, staking, and decay.
 * Users can mint Nodes, stake Shards on them (Nurture), synthesize Nodes, and harvest Shards.
 * This contract demonstrates dynamic NFT state, staking on NFTs, complex interactions,
 * decay mechanics, and integrated tokenomics beyond standard interfaces.
 *
 * Concepts Demonstrated:
 * 1. Dynamic NFT State: Node attributes (state, vitality, purity) are mutable.
 * 2. NFT Staking: Users stake a fungible token (Shards) directly on an individual NFT.
 * 3. Decay Mechanic: Node vitality decreases over time if not nurtured.
 * 4. State Evolution: Nodes can evolve to different states based on criteria.
 * 5. Complex Interaction (Synthesis): Two NFTs can interact, potentially changing states, burning, minting, and distributing rewards based on specific rules.
 * 6. Yield Generation (Harvest): NFTs can generate yield based on their attributes and state.
 * 7. Integrated Custom Token: A simplified ERC20-like token ('Shards') is managed within the same contract for simplicity (in a real dApp, this would be separate).
 * 8. Pausable and Ownable features for contract management.
 * 9. Detailed state tracking per NFT.
 */

/**
 * @title NodeState
 * @dev Represents the different phases or states a Node can be in.
 */
enum NodeState {
    Embryonic,   // Initial fragile state
    Nascent,     // Developing state, requires nurture
    Evolving,    // Active state, potential for synthesis/harvest
    Dormant,     // Inactive state, reduced decay but limited actions
    Primal       // Rare/Powerful state, high yield, complex synthesis
}

/**
 * @title NodeAttributes
 * @dev Stores the dynamic data associated with each Node NFT.
 */
struct NodeAttributes {
    uint256 id;
    address owner;
    NodeState state;
    uint256 vitality; // Represents health/energy, decays over time
    uint256 purity;   // Represents quality/potential, influenced by actions
    uint256 creationTime;
    uint256 lastStateChangeTime;
    uint256 lastVitalityUpdateTime; // Timestamp when vitality was last calculated/modified
    uint256 stakedShards; // Amount of Shards staked on this specific Node
    uint256 nurtureStakeEndTime; // Timestamp when current nurture staking period ends
    uint256 lastHarvestTime; // Timestamp of the last harvest
    bool canHarvest; // Whether this node is currently ready to be harvested
}

/**
 * @title SynthesisConfig
 * @dev Configuration for different synthesis outcomes based on input states.
 */
struct SynthesisConfig {
    NodeState state1; // Input state 1
    NodeState state2; // Input state 2
    NodeState resultState; // Resulting state (for one node, or a new node)
    uint256 shardsReward; // Shards distributed upon successful synthesis
    uint256 vitalityCost1; // Vitality cost for node1
    uint256 vitalityCost2; // Vitality cost for node2
    bool burnNode1; // Whether to burn node1
    bool burnNode2; // Whether to burn node2
    bool mintNewNode; // Whether to mint a new node as a result
}

/**
 * @title NurtureConfig
 * @dev Configuration for nurturing benefits per state.
 */
struct NurtureConfig {
    uint256 vitalityGainPerShard; // Vitality gained per shard staked
    uint256 yieldPerShardPerSecond; // Shards yield rate from staking
    uint256 durationIncreasePerShard; // How long staking duration increases per shard
}


// --- ERC721 Simplified Interface (manual implementation below) ---
interface IERC721Simplified {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// --- ERC20 Simplified Interface (manual implementation below) ---
interface IERC20Simplified {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// --- Pausable and Ownable (basic implementations, could use OpenZeppelin for robustness) ---
contract Pausable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function _pause() internal {
        require(!_paused, "Pausable: paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal {
        require(_paused, "Pausable: not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract ChronicleOfTheShiftingSands is IERC721Simplified, IERC20Simplified, Pausable, Ownable {

    // --- ERC721 State ---
    mapping(uint256 => address) private _owners; // tokenId => owner address
    mapping(address => uint256) private _balances; // owner address => balance (count)
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved
    uint256 private _nextTokenId = 1; // Counter for unique node IDs

    // --- ERC20 (Shards) State ---
    string public constant SHARDS_NAME = "Shifting Shards";
    string public constant SHARDS_SYMBOL = "SHRDS";
    uint8 public constant SHARDS_DECIMALS = 18;
    mapping(address => uint256) private _shardsBalances; // holder address => balance
    mapping(address => mapping(address => uint256)) private _shardsAllowances; // owner => spender => allowance
    uint256 private _shardsTotalSupply;

    // --- Node State ---
    mapping(uint256 => NodeAttributes) public nodes; // tokenId => Node data
    mapping(NodeState => NurtureConfig) public nurtureConfigs; // State => Nurture rules
    SynthesisConfig[] public synthesisConfigs; // Array of possible synthesis outcomes

    // --- Global Parameters ---
    uint256 public baseDecayRatePerSecond = 1; // Vitality lost per second (base)
    uint256 public harvestCooldown = 7 days; // Time required between harvests

    // --- ERC721 Implementations ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Ensures token exists
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token"); // Checks existence
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        // Check token existence and ownership
        require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Check approval
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        // Perform transfer
        _transfer(from, to, tokenId);
    }

    // Simplified safeTransferFrom (no receiver hook check for brevity, use _transfer)
    // function safeTransferFrom(address from, address to, uint256 tokenId) public { ... }
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public { ... }

    // Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approvals
        _approve(address(0), tokenId);

        // Update balances and ownership
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // Update node data owner
        nodes[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    // Helper to check if sender is owner or approved
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Internal approval logic
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // Internal minting logic (simplified)
    function _mint(address to, uint256 tokenId, NodeState initialState, uint256 initialVitality, uint256 initialPurity) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _owners[tokenId] = to;
        _balances[to]++;
        _nextTokenId = tokenId + 1; // Auto-increment next ID

        // Initialize Node Attributes
        nodes[tokenId] = NodeAttributes({
            id: tokenId,
            owner: to,
            state: initialState,
            vitality: initialVitality,
            purity: initialPurity,
            creationTime: block.timestamp,
            lastStateChangeTime: block.timestamp,
            lastVitalityUpdateTime: block.timestamp,
            stakedShards: 0,
            nurtureStakeEndTime: 0,
            lastHarvestTime: 0,
            canHarvest: false // Cannot harvest immediately after mint
        });

        emit Transfer(address(0), to, tokenId);
    }

    // Internal burning logic (simplified)
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Ensures token exists

        // Clear approvals
        _approve(address(0), tokenId);

        // Update balances and ownership
        _balances[owner]--;
        delete _owners[tokenId]; // Delete ownership
        delete _tokenApprovals[tokenId]; // Delete token approval
        delete nodes[tokenId]; // Delete node data

        emit Transfer(owner, address(0), tokenId);
    }

    // --- ERC20 (Shards) Implementations ---

    function totalSupply() public view override returns (uint256) {
        return _shardsTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _shardsBalances[account];
    }

    function transfer(address to, uint256 value) public override whenNotPaused returns (bool) {
        _transferShards(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _shardsAllowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override whenNotPaused returns (bool) {
        _approveShards(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = _shardsAllowances[from][msg.sender];
        require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");
        _transferShards(from, to, value);
        _approveShards(from, msg.sender, currentAllowance - value);
        return true;
    }

    // Internal Shard transfer logic
    function _transferShards(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _shardsBalances[from];
        require(senderBalance >= value, "ERC20: transfer amount exceeds balance");
        unchecked {
            _shardsBalances[from] = senderBalance - value;
        }
        _shardsBalances[to] += value;
        emit Transfer(from, to, value);
    }

    // Internal Shard minting logic
    function _mintShards(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _shardsTotalSupply += value;
        _shardsBalances[account] += value;
        emit Transfer(address(0), account, value);
    }

    // Internal Shard burning logic
    function _burnShards(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _shardsBalances[account];
        require(accountBalance >= value, "ERC20: burn amount exceeds balance");
        unchecked {
            _shardsBalances[account] = accountBalance - value;
        }
        _shardsTotalSupply -= value;
        emit Transfer(account, address(0), value);
    }

    // Internal Shard approval logic
    function _approveShards(address owner, address spender, uint256 value) internal {
        _shardsAllowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    // --- Core Node Logic Functions ---

    /**
     * @dev Mints a new Node NFT. Only callable by owner initially, could be public with cost/limit.
     * @param to The address to mint the node to.
     * @param initialPurity The initial purity value for the new node.
     */
    function mintNode(address to, uint256 initialPurity) public onlyOwner whenNotPaused {
        uint256 tokenId = _nextTokenId;
        // Initial state is Embryonic, initial vitality is determined by purity or a base value
        _mint(to, tokenId, NodeState.Embryonic, initialPurity * 100, initialPurity); // Example: vitality = purity * 100
    }

    /**
     * @dev Nurtures a Node by staking Shards. Increases vitality and staking duration.
     * @param tokenId The ID of the Node to nurture.
     * @param amount The amount of Shards to stake.
     */
    function nurtureNode(uint256 tokenId, uint256 amount) public whenNotPaused {
        NodeAttributes storage node = nodes[tokenId];
        require(_owners[tokenId] == msg.sender, "Not the owner of the node");
        require(node.state != NodeState.Dormant, "Cannot nurture a dormant node");
        require(amount > 0, "Must stake a positive amount");

        // Apply decay before calculating new vitality/stake end
        _applyDecay(tokenId);

        // Transfer Shards from sender to contract
        _transferShards(msg.sender, address(this), amount);

        // Add to staked amount
        node.stakedShards += amount;

        // Update vitality and stake end time based on config
        NurtureConfig memory config = nurtureConfigs[node.state];
        node.vitality += amount * config.vitalityGainPerShard;

        uint256 durationIncrease = amount * config.durationIncreasePerShard;
        uint256 currentTime = block.timestamp;

        if (node.nurtureStakeEndTime < currentTime) {
            // If stake had expired, new stake starts from now
            node.nurtureStakeEndTime = currentTime + durationIncrease;
        } else {
            // If stake is active, extend the end time
            node.nurtureStakeEndTime += durationIncrease;
        }

        node.lastVitalityUpdateTime = currentTime; // Vitality changed, update timestamp

        emit Nurtured(tokenId, msg.sender, amount, node.vitality, node.nurtureStakeEndTime);
    }

    /**
     * @dev Claims the staked Shards and any earned yield from a Node.
     * @param tokenId The ID of the Node to claim from.
     */
    function claimNurtureStake(uint256 tokenId) public whenNotPaused {
        NodeAttributes storage node = nodes[tokenId];
        require(_owners[tokenId] == msg.sender, "Not the owner of the node");
        require(node.stakedShards > 0, "No Shards staked on this node");

        // Apply decay before calculating yield/vitality
        _applyDecay(tokenId);

        uint256 currentTime = block.timestamp;
        uint256 stakeAmount = node.stakedShards;
        uint256 yieldAmount = 0;

        // Calculate yield only if staking was active or is currently active and past nurtureStakeEndTime
        if (node.nurtureStakeEndTime > node.lastVitalityUpdateTime) { // Check if staking was effectively active in the last period
            uint256 activeStakeDuration = (currentTime > node.nurtureStakeEndTime) ? (node.nurtureStakeEndTime - node.lastVitalityUpdateTime) : (currentTime - node.lastVitalityUpdateTime);
             // Prevent overflow and handle potential large durations
            if (activeStakeDuration > 0 && node.stakedShards > 0) {
                 // Calculate yield based on staked amount and active duration since last update, using yield rate
                yieldAmount = (node.stakedShards * nurtureConfigs[node.state].yieldPerShardPerSecond * activeStakeDuration) / 1e18; // Assuming rate is in fixed point like 1e18
            }
        }

        // Transfer staked amount + yield back to user
        uint256 totalClaimAmount = stakeAmount + yieldAmount;
        node.stakedShards = 0; // Reset staked amount
        node.nurtureStakeEndTime = 0; // Reset stake end time
        node.lastVitalityUpdateTime = currentTime; // Mark vitality/yield calc time

        _transferShards(address(this), msg.sender, totalClaimAmount);

        emit StakeClaimed(tokenId, msg.sender, stakeAmount, yieldAmount);
    }

    /**
     * @dev Attempts to synthesize two Nodes. Outcomes depend on node states and synthesis configurations.
     * Costs vitality and potentially Shards. Can result in state changes, burning, or minting.
     * @param node1Id The ID of the first Node.
     * @param node2Id The ID of the second Node.
     */
    function synthesizeNodes(uint256 node1Id, uint256 node2Id) public whenNotPaused {
        require(node1Id != node2Id, "Cannot synthesize a node with itself");
        NodeAttributes storage node1 = nodes[node1Id];
        NodeAttributes storage node2 = nodes[node2Id];

        require(_owners[node1Id] == msg.sender, "Not the owner of node1");
        require(_owners[node2Id] == msg.sender, "Not the owner of node2");
        require(node1.state != NodeState.Embryonic && node2.state != NodeState.Embryonic, "Embryonic nodes cannot be synthesized");

        // Apply decay before synthesis checks/costs
        _applyDecay(node1Id);
        _applyDecay(node2Id);

        require(node1.vitality > 0 && node2.vitality > 0, "Nodes must have vitality to synthesize");

        // Find matching synthesis config (order matters, or check both permutations)
        SynthesisConfig memory config;
        bool configFound = false;
        bool reverseOrder = false;

        for(uint i = 0; i < synthesisConfigs.length; i++) {
            if (synthesisConfigs[i].state1 == node1.state && synthesisConfigs[i].state2 == node2.state) {
                config = synthesisConfigs[i];
                configFound = true;
                break;
            } else if (synthesisConfigs[i].state1 == node2.state && synthesisConfigs[i].state2 == node1.state) {
                 // Handle permutations if config is state-order independent
                 // For this example, we'll assume a match in reverse order also works,
                 // but apply costs/effects based on which node matches state1/state2 in config.
                 // A more complex system could have asymmetric synthesis.
                config = synthesisConfigs[i];
                configFound = true;
                reverseOrder = true; // Track if nodes were matched in reverse
                break;
            }
        }

        require(configFound, "No synthesis configuration found for these node states");

        uint256 vitalityCost1 = reverseOrder ? config.vitalityCost2 : config.vitalityCost1;
        uint256 vitalityCost2 = reverseOrder ? config.vitalityCost1 : config.vitalityCost2;

        require(node1.vitality >= vitalityCost1, "Node1 vitality too low for synthesis");
        require(node2.vitality >= vitalityCost2, "Node2 vitality too low for synthesis");

        // Deduct vitality costs
        node1.vitality -= vitalityCost1;
        node2.vitality -= vitalityCost2;
        node1.lastVitalityUpdateTime = block.timestamp;
        node2.lastVitalityUpdateTime = block.timestamp;

        // Apply synthesis effects based on config
        if (config.burnNode1) {
            _burn(node1Id);
        } else {
             node1.state = config.resultState; // Node 1 potentially changes state
             node1.lastStateChangeTime = block.timestamp;
        }

        if (config.burnNode2) {
            _burn(node2Id);
        } else {
            node2.state = config.resultState; // Node 2 potentially changes state
            node2.lastStateChangeTime = block.timestamp;
        }

        if (config.mintNewNode) {
            // Mint a new node resulting from synthesis
            // Attributes of the new node could be derived from parents' purity/vitality/state
            uint256 newPurity = (node1.purity + node2.purity) / 2; // Example derivation
            uint256 newVitality = (node1.vitality + node2.vitality) / 2; // Example derivation
             // State of new node is the resultState
            _mint(msg.sender, _nextTokenId, config.resultState, newVitality, newPurity);
        }

        // Distribute Shard reward if configured
        if (config.shardsReward > 0) {
            _distributeShards(msg.sender, config.shardsReward); // Mint/transfer reward
        }

        emit NodesSynthesized(node1Id, node2Id, msg.sender, config.resultState, config.burnNode1, config.burnNode2, config.mintNewNode, config.shardsReward);
    }

    /**
     * @dev Harvests Shards from a Node based on its current state and attributes.
     * Node must meet criteria and not be on cooldown.
     * @param tokenId The ID of the Node to harvest from.
     */
    function harvestNode(uint256 tokenId) public whenNotPaused {
        NodeAttributes storage node = nodes[tokenId];
        require(_owners[tokenId] == msg.sender, "Not the owner of the node");
        require(node.state != NodeState.Embryonic && node.state != NodeState.Dormant, "Node state cannot be harvested");

        // Apply decay before checking harvest eligibility
        _applyDecay(tokenId);

        require(node.vitality > 0, "Node has no vitality to harvest");
        require(node.canHarvest, "Node is not ready to harvest or on cooldown");

        // Calculate harvest amount (example: vitality + purity * state multiplier)
        uint256 harvestAmount = node.vitality + node.purity * (uint256(node.state) + 1); // Example multiplier
        harvestAmount = harvestAmount / 10; // Scale down example

        // Deduct vitality (example: harvest costs vitality)
        node.vitality = node.vitality > (node.vitality / 2) ? node.vitality / 2 : 0; // Example cost

        // Distribute Shards
        _distributeShards(msg.sender, harvestAmount);

        // Set harvest cooldown
        node.lastHarvestTime = block.timestamp;
        node.canHarvest = false; // Cannot harvest again immediately
        node.lastVitalityUpdateTime = block.timestamp; // Vitality changed, update timestamp

        emit Harvested(tokenId, msg.sender, harvestAmount, node.vitality);
    }

    /**
     * @dev Attempts to evolve a Node to the next state if criteria are met (e.g., vitality, time in state).
     * @param tokenId The ID of the Node to evolve.
     */
    function evolveNode(uint256 tokenId) public whenNotPaused {
        NodeAttributes storage node = nodes[tokenId];
        require(_owners[tokenId] == msg.sender, "Not the owner of the node");
        require(node.state != NodeState.Primal && node.state != NodeState.Dormant, "Node cannot evolve from this state");

        // Apply decay before checking evolution criteria
        _applyDecay(tokenId);

        // Check evolution criteria
        // Example: vitality > threshold AND timeInState > requiredDuration
        uint256 timeInState = block.timestamp - node.lastStateChangeTime;

        bool canEvolve = false;
        NodeState nextState = node.state;

        // Example evolution rules:
        if (node.state == NodeState.Embryonic && node.vitality >= 500 && timeInState >= 1 days) {
            canEvolve = true;
            nextState = NodeState.Nascent;
        } else if (node.state == NodeState.Nascent && node.vitality >= 1000 && timeInState >= 3 days) {
            canEvolve = true;
            nextState = NodeState.Evolving;
        } else if (node.state == NodeState.Evolving && node.vitality >= 2000 && node.purity >= 50 && timeInState >= 7 days) {
            canEvolve = true;
            nextState = NodeState.Primal;
        }
        // Add rules for Dormant state transition if applicable (e.g., from Dormant back to Nascent with sufficient nurture)
         else if (node.state == NodeState.Dormant && node.stakedShards > 0 && node.vitality >= 200 && timeInState >= 1 days) {
            canEvolve = true;
            nextState = NodeState.Nascent; // Evolve from Dormant back to Nascent
        }


        require(canEvolve, "Node does not meet evolution criteria");

        // Perform evolution
        node.state = nextState;
        node.lastStateChangeTime = block.timestamp;
        // Vitality might be reset or adjusted upon evolution
        // node.vitality = node.vitality / 2; // Example adjustment

        emit NodeEvolved(tokenId, nextState, node.vitality);
    }

     /**
      * @dev Burns (destroys) a Node NFT. Can have conditions (e.g., minimum vitality, specific state).
      * @param tokenId The ID of the Node to burn.
      */
     function burnNode(uint256 tokenId) public whenNotPaused {
         require(_owners[tokenId] == msg.sender, "Not the owner of the node");
         // Optional: Add conditions like require(nodes[tokenId].state == NodeState.Dormant, "Only Dormant nodes can be burned");
         // Optional: Add conditions like require(nodes[tokenId].vitality == 0, "Only nodes with 0 vitality can be burned");

         // Refund any staked shards before burning
         if (nodes[tokenId].stakedShards > 0) {
             uint256 staked = nodes[tokenId].stakedShards;
             nodes[tokenId].stakedShards = 0;
              // Transfer staked amount back to owner
             _transferShards(address(this), msg.sender, staked);
             emit StakeClaimed(tokenId, msg.sender, staked, 0); // Emit stake claimed event for refund
         }

         _burn(tokenId); // Use internal burning logic
     }


    // --- Internal Helper Functions ---

    /**
     * @dev Applies vitality decay to a node based on the time elapsed since last update.
     * Called internally by state-changing functions to ensure up-to-date vitality.
     * @param tokenId The ID of the Node to apply decay to.
     */
    function _applyDecay(uint256 tokenId) internal {
        NodeAttributes storage node = nodes[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - node.lastVitalityUpdateTime;

        if (timeElapsed == 0) return; // No time elapsed, no decay

        uint256 decayRate = baseDecayRatePerSecond; // Base rate

        // Adjust decay rate based on state (example: Dormant decays slower, Embryonic decays faster)
        if (node.state == NodeState.Embryonic) decayRate = decayRate * 2;
        else if (node.state == NodeState.Dormant) decayRate = decayRate / 2;
        // States like Evolving and Primal could have their own rates

        uint256 decayAmount = timeElapsed * decayRate;

        if (node.vitality > decayAmount) {
            node.vitality -= decayAmount;
        } else {
            node.vitality = 0;
        }

        // Check if harvest is ready based on cooldown
        if (!node.canHarvest && currentTime >= node.lastHarvestTime + harvestCooldown) {
             node.canHarvest = true; // Make node harvestable again after cooldown
        }

         // Optional: Transition to Dormant state if vitality hits 0
         if (node.vitality == 0 && node.state != NodeState.Dormant) {
             node.state = NodeState.Dormant;
             node.lastStateChangeTime = currentTime; // Mark transition time
             emit NodeEvolved(tokenId, NodeState.Dormant, node.vitality);
         }


        node.lastVitalityUpdateTime = currentTime; // Update timestamp for next calculation
        emit VitalityDecayed(tokenId, node.vitality, decayAmount);
    }

     /**
      * @dev Internal function to handle Shard distribution (minting or transferring from contract balance).
      * Simplification: Assumes contract can mint Shards. In a real system, rewards might come from
      * a pre-funded pool or revenue generated by the protocol.
      * @param to The address to receive Shards.
      * @param amount The amount of Shards to distribute.
      */
     function _distributeShards(address to, uint256 amount) internal {
        // In a real system, you might check contract balance first:
        // if (_shardsBalances[address(this)] >= amount) {
        //     _transferShards(address(this), to, amount);
        // } else {
             // Mint new shards if needed (requires careful tokenomics design)
             _mintShards(to, amount);
        // }
     }


    // --- View Functions ---

    /**
     * @dev Gets the full attributes of a specific Node, applying decay before returning.
     * @param tokenId The ID of the Node.
     * @return A struct containing the Node's attributes.
     */
    function getNodeAttributes(uint256 tokenId) public view returns (NodeAttributes memory) {
        require(_owners[tokenId] != address(0), "Node does not exist");
        NodeAttributes memory node = nodes[tokenId]; // Read from storage

        // Calculate current vitality including decay *conceptually* for the view
        uint256 timeElapsed = block.timestamp - node.lastVitalityUpdateTime;
        uint256 decayRate = baseDecayRatePerSecond;
        if (node.state == NodeState.Embryonic) decayRate = decayRate * 2;
        else if (node.state == NodeState.Dormant) decayRate = decayRate / 2;

        uint256 decayAmount = timeElapsed * decayRate;
        node.vitality = node.vitality > decayAmount ? node.vitality - decayAmount : 0;

        // Check if harvest is ready based on cooldown *conceptually* for the view
        if (!node.canHarvest && block.timestamp >= node.lastHarvestTime + harvestCooldown) {
             node.canHarvest = true;
        }

        return node;
    }

    /**
     * @dev Calculates the current vitality of a node, accounting for decay up to the current timestamp.
     * This is a view function and does not alter state.
     * @param tokenId The ID of the Node.
     * @return The current calculated vitality.
     */
    function calculateCurrentVitality(uint256 tokenId) public view returns (uint256) {
        require(_owners[tokenId] != address(0), "Node does not exist");
        NodeAttributes memory node = nodes[tokenId];
        uint256 timeElapsed = block.timestamp - node.lastVitalityUpdateTime;
        uint256 decayRate = baseDecayRatePerSecond;
         if (node.state == NodeState.Embryonic) decayRate = decayRate * 2;
         else if (node.state == NodeState.Dormant) decayRate = decayRate / 2;

        uint256 decayAmount = timeElapsed * decayRate;
        return node.vitality > decayAmount ? node.vitality - decayAmount : 0;
    }

     /**
      * @dev Estimates the Shard yield if a Node were harvested *now*. Accounts for current vitality after decay.
      * This is an estimate and the actual amount may vary slightly depending on timing.
      * @param tokenId The ID of the Node.
      * @return The estimated Shard yield from harvesting.
      */
     function calculateHarvestYield(uint256 tokenId) public view returns (uint256) {
         require(_owners[tokenId] != address(0), "Node does not exist");
         NodeAttributes memory node = nodes[tokenId];
         if (node.state == NodeState.Embryonic || node.state == NodeState.Dormant) return 0; // Cannot harvest these states
         if (!node.canHarvest && block.timestamp < node.lastHarvestTime + harvestCooldown) return 0; // On cooldown

         uint256 currentVitality = calculateCurrentVitality(tokenId);
         if (currentVitality == 0) return 0;

         // Example harvest amount calculation
         return (currentVitality + node.purity * (uint256(node.state) + 1)) / 10;
     }

    /**
     * @dev Estimates the potential Shard yield earned from staking on a node since the last update.
     * @param tokenId The ID of the Node.
     * @return The estimated Shard yield from nurture staking.
     */
    function calculateNurtureYield(uint256 tokenId) public view returns (uint256) {
        NodeAttributes memory node = nodes[tokenId];
        if (node.stakedShards == 0) return 0;

        uint256 currentTime = block.timestamp;
        uint256 yieldAmount = 0;

        // Calculate yield only if staking was active or is currently active and past nurtureStakeEndTime
        if (node.nurtureStakeEndTime > node.lastVitalityUpdateTime) { // Check if staking was effectively active in the last period
            uint256 activeStakeDuration = (currentTime > node.nurtureStakeEndTime) ? (node.nurtureStakeEndTime - node.lastVitalityUpdateTime) : (currentTime - node.lastVitalityUpdateTime);
             // Prevent overflow and handle potential large durations
            if (activeStakeDuration > 0 && node.stakedShards > 0) {
                 // Calculate yield based on staked amount and active duration since last update, using yield rate
                yieldAmount = (node.stakedShards * nurtureConfigs[node.state].yieldPerShardPerSecond * activeStakeDuration) / 1e18; // Assuming rate is in fixed point like 1e18
            }
        }
         return yieldAmount;
    }


    /**
     * @dev Estimates the Shard cost of synthesizing two nodes based on configured synthesis rules.
     * Note: This example synthesis doesn't have a Shard cost, only vitality cost and potential reward.
     * This function is included as a placeholder for more complex synthesis mechanics.
     * @param node1Id The ID of the first Node.
     * @param node2Id The ID of the second Node.
     * @return The estimated Shard cost. Returns 0 in this example.
     */
    function calculateEstimatedSynthesisCost(uint256 node1Id, uint256 node2Id) public view returns (uint256) {
         require(_owners[node1Id] != address(0) && _owners[node2Id] != address(0), "Nodes do not exist");
         // In this example, synthesis has no direct Shard cost, only vitality cost.
         // A more advanced version could look up the SynthesisConfig and return a Shard cost.
        return 0; // Placeholder: Replace with actual cost calculation based on config if applicable
    }

     /**
      * @dev Checks if a Node meets the criteria to evolve to the next state based on current (calculated) vitality and time in state.
      * This is a view function.
      * @param tokenId The ID of the Node.
      * @return True if the node can evolve, false otherwise.
      * @return The potential next state if it can evolve.
      */
     function checkEvolutionCriteria(uint256 tokenId) public view returns (bool, NodeState) {
         require(_owners[tokenId] != address(0), "Node does not exist");
         NodeAttributes memory node = nodes[tokenId];

         if (node.state == NodeState.Primal || node.state == NodeState.Dormant) return (false, node.state); // Cannot evolve from these states (except Dormant back to Nascent)

         uint256 currentTime = block.timestamp;
         uint256 timeInState = currentTime - node.lastStateChangeTime;
         uint256 currentVitality = calculateCurrentVitality(tokenId);

         // Example evolution rules (must match evolveNode logic)
         if (node.state == NodeState.Embryonic && currentVitality >= 500 && timeInState >= 1 days) {
             return (true, NodeState.Nascent);
         } else if (node.state == NodeState.Nascent && currentVitality >= 1000 && timeInState >= 3 days) {
             return (true, NodeState.Evolving);
         } else if (node.state == NodeState.Evolving && currentVitality >= 2000 && node.purity >= 50 && timeInState >= 7 days) {
             return (true, NodeState.Primal);
         } else if (node.state == NodeState.Dormant && node.stakedShards > 0 && currentVitality >= 200 && timeInState >= 1 days) {
             return (true, NodeState.Nascent); // Evolve from Dormant back to Nascent
         }


         return (false, node.state); // No evolution possible
     }

     /**
      * @dev Returns the current state of a Node. Applies decay conceptually for vitality check if needed for future view functions.
      * @param tokenId The ID of the Node.
      * @return The NodeState enum value.
      */
     function getNodeState(uint256 tokenId) public view returns (NodeState) {
         require(_owners[tokenId] != address(0), "Node does not exist");
         // Although decay is not applied in a view function to persistent state,
         // a real application might want to factor potential decay when displaying state status.
         // For this function, we just return the stored state.
         return nodes[tokenId].state;
     }

    /**
     * @dev Gets the balance of Shards for an account.
     * @param account The address to query.
     * @return The Shard balance.
     */
    function getShardsBalance(address account) public view returns (uint256) {
        return balanceOf(account); // Use ERC20 balanceOf implementation
    }

    /**
     * @dev Gets the allowance of Shards granted by an owner to a spender.
     * @param owner The address that owns the Shards.
     * @param spender The address that is approved to spend.
     * @return The amount of Shards allowed.
     */
    function getShardsAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender); // Use ERC20 allowance implementation
    }

     /**
      * @dev Gets the balance of Shards held by this contract. Useful for checking reward pools etc.
      * @return The contract's Shard balance.
      */
     function getContractShardsBalance() public view returns (uint256) {
         return _shardsBalances[address(this)];
     }


    // --- Admin/Control Functions (Owner-only) ---

    /**
     * @dev Sets the configuration for a specific NodeState's nurture benefits.
     * @param state The NodeState to configure.
     * @param vitalityGainPerShard Vitality increase per Shard staked.
     * @param yieldPerShardPerSecond Shard yield rate per second per Shard staked (scaled, e.g., * 1e18).
     * @param durationIncreasePerShard Staking duration extension per Shard staked.
     */
    function setNurtureConfig(NodeState state, uint256 vitalityGainPerShard, uint256 yieldPerShardPerSecond, uint256 durationIncreasePerShard) public onlyOwner {
        nurtureConfigs[state] = NurtureConfig(vitalityGainPerShard, yieldPerShardPerSecond, durationIncreasePerShard);
        emit NurtureConfigUpdated(state, vitalityGainPerShard, yieldPerShardPerSecond, durationIncreasePerShard);
    }

     /**
      * @dev Adds a new Synthesis configuration rule.
      * @param config The SynthesisConfig struct defining the rule.
      */
    function addSynthesisConfig(SynthesisConfig memory config) public onlyOwner {
         // Add validation if needed, e.g., ensure no duplicate state combinations
        synthesisConfigs.push(config);
        emit SynthesisConfigAdded(config.state1, config.state2, config.resultState, config.shardsReward);
    }

     /**
      * @dev Removes a Synthesis configuration rule by index. Use with caution.
      * @param index The index of the configuration to remove.
      */
    function removeSynthesisConfig(uint256 index) public onlyOwner {
        require(index < synthesisConfigs.length, "Index out of bounds");
        // Shift elements to fill the gap (inefficient for large arrays, consider mapping if many configs)
        for (uint i = index; i < synthesisConfigs.length - 1; i++) {
            synthesisConfigs[i] = synthesisConfigs[i + 1];
        }
        synthesisConfigs.pop();
        emit SynthesisConfigRemoved(index);
    }

    /**
     * @dev Sets a global parameter like the base decay rate or harvest cooldown.
     * @param paramName The name of the parameter ("baseDecayRatePerSecond", "harvestCooldown").
     * @param value The new value for the parameter.
     */
    function setGlobalParameter(string calldata paramName, uint256 value) public onlyOwner {
        bytes32 paramHash = keccak256(abi.encodePacked(paramName));
        if (paramHash == keccak256("baseDecayRatePerSecond")) {
            baseDecayRatePerSecond = value;
            emit GlobalParameterUpdated("baseDecayRatePerSecond", value);
        } else if (paramHash == keccak256("harvestCooldown")) {
            harvestCooldown = value;
            emit GlobalParameterUpdated("harvestCooldown", value);
        } else {
            revert("Unknown parameter name");
        }
    }


    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing state-changing operations again.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any Shards held by the contract.
     * Useful for managing reward pools or correcting errors.
     * @param amount The amount of Shards to withdraw.
     */
    function withdrawShards(uint256 amount) public onlyOwner {
        _transferShards(address(this), msg.sender, amount);
        emit ShardsWithdrawn(msg.sender, amount);
    }

    // --- Events ---

    event Nurtured(uint256 indexed tokenId, address indexed nurturer, uint256 amount, uint256 newVitality, uint256 nurtureStakeEndTime);
    event StakeClaimed(uint256 indexed tokenId, address indexedclaimer, uint256 stakedAmount, uint256 yieldAmount);
    event NodesSynthesized(uint256 indexed node1Id, uint256 indexed node2Id, address indexed synthesiser, NodeState resultState, bool node1Burned, bool node2Burned, bool newNodeMinted, uint256 shardsReward);
    event Harvested(uint256 indexed tokenId, address indexed harvester, uint256 amount, uint256 newVitality);
    event NodeEvolved(uint256 indexed tokenId, NodeState indexed newState, uint256 newVitality);
    event VitalityDecayed(uint256 indexed tokenId, uint256 currentVitality, uint256 decayAmount);
    event NurtureConfigUpdated(NodeState indexed state, uint256 vitalityGainPerShard, uint256 yieldPerShardPerSecond, uint256 durationIncreasePerShard);
    event SynthesisConfigAdded(NodeState indexed state1, NodeState indexed state2, NodeState resultState, uint256 shardsReward);
    event SynthesisConfigRemoved(uint256 indexed index);
    event GlobalParameterUpdated(string paramName, uint256 value);
    event ShardsWithdrawn(address indexed receiver, uint256 amount);

}
```

**Function Summary (matching the code above):**

1.  `constructor()`: Initializes the contract owner.
2.  `mintNode(address to, uint256 initialPurity)`: Mints a new Node NFT with initial attributes. Owner-only.
3.  `balanceOf(address owner)`: (ERC721) Returns the number of Nodes owned by an address.
4.  `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of a specific Node.
5.  `approve(address to, uint256 tokenId)`: (ERC721) Approves an address to manage a specific Node.
6.  `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for a Node.
7.  `setApprovalForAll(address operator, bool approved)`: (ERC721) Approves/disapproves an operator for all owner's Nodes.
8.  `isApprovedForAll(address owner, address operator)`: (ERC721) Checks if an operator is approved for all owner's Nodes.
9.  `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers a Node using owner or approved address. Pausable.
10. `nurtureNode(uint256 tokenId, uint256 amount)`: Stakes `amount` of Shards on `tokenId`, increasing vitality and nurture duration. Requires Node ownership. Applies decay. Pausable.
11. `claimNurtureStake(uint256 tokenId)`: Claims staked Shards and earned yield from `tokenId`. Requires Node ownership. Applies decay. Pausable.
12. `synthesizeNodes(uint256 node1Id, uint256 node2Id)`: Attempts to synthesize two Nodes owned by the caller based on configured rules. Consumes vitality, can burn nodes, mint new ones, and distribute rewards. Applies decay. Pausable.
13. `harvestNode(uint256 tokenId)`: Claims Shard rewards from `tokenId` if eligible (state, vitality, cooldown). Consumes vitality. Applies decay. Pausable.
14. `evolveNode(uint256 tokenId)`: Attempts to evolve a Node to the next state if criteria (vitality, time in state) are met. Requires Node ownership. Applies decay. Pausable.
15. `burnNode(uint256 tokenId)`: Burns (destroys) a Node NFT. Refunds staked Shards. Requires Node ownership. Pausable.
16. `getNodeAttributes(uint256 tokenId)`: (View) Returns the full attributes of a Node, including vitality calculated with potential decay.
17. `calculateCurrentVitality(uint256 tokenId)`: (View) Calculates a Node's vitality at the current time, accounting for decay.
18. `calculateHarvestYield(uint256 tokenId)`: (View) Estimates Shard yield from harvesting a Node *now*.
19. `calculateNurtureYield(uint256 tokenId)`: (View) Estimates Shard yield earned from current nurture staking *since last update*.
20. `calculateEstimatedSynthesisCost(uint256 node1Id, uint256 node2Id)`: (View) Estimates the Shard cost of a potential synthesis. Placeholder, returns 0 in this example.
21. `checkEvolutionCriteria(uint256 tokenId)`: (View) Checks if a Node meets the requirements to evolve and returns the potential next state.
22. `getNodeState(uint256 tokenId)`: (View) Returns the current state of a Node.
23. `getShardsBalance(address account)`: (View) Returns the Shard balance for an account.
24. `getShardsAllowance(address owner, address spender)`: (View) Returns the Shard allowance granted by `owner` to `spender`.
25. `getContractShardsBalance()`: (View) Returns the total balance of Shards held by the contract.
26. `setNurtureConfig(NodeState state, uint256 vitalityGainPerShard, uint256 yieldPerShardPerSecond, uint256 durationIncreasePerShard)`: Owner-only. Sets parameters for nurturing benefits per NodeState.
27. `addSynthesisConfig(SynthesisConfig memory config)`: Owner-only. Adds a rule for Node synthesis outcomes.
28. `removeSynthesisConfig(uint256 index)`: Owner-only. Removes a synthesis rule by its index.
29. `setGlobalParameter(string calldata paramName, uint256 value)`: Owner-only. Sets contract-wide parameters like decay rate or harvest cooldown.
30. `pause()`: Owner-only. Pauses state-changing functions.
31. `unpause()`: Owner-only. Unpauses state-changing functions.
32. `withdrawShards(uint256 amount)`: Owner-only. Allows the owner to withdraw Shards from the contract's balance.
33. `totalSupply()`: (ERC20) Returns the total supply of Shards.
34. `balanceOf(address account)`: (ERC20) Alias for `getShardsBalance`.
35. `transfer(address to, uint256 value)`: (ERC20) Transfers Shards from sender to another address. Pausable.
36. `allowance(address owner, address spender)`: (ERC20) Alias for `getShardsAllowance`.
37. `approve(address spender, uint256 value)`: (ERC20) Approves a spender to transfer Shards on behalf of the sender. Pausable.
38. `transferFrom(address from, address to, uint256 value)`: (ERC20) Transfers Shards using an allowance. Pausable.

*(Note: The manual ERC721/ERC20 implementations included here are simplified for demonstration purposes and might not cover all edge cases or optimizations of standard libraries like OpenZeppelin. In a production environment, using audited libraries is highly recommended.)*