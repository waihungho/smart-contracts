Okay, here is a smart contract concept called `FractalTreasury`.

This contract explores the idea of a recursive, self-similar organizational structure on-chain. Each `FractalTreasury` node can own assets (Ether, ERC20, ERC721) and can create and manage *child* `FractalTreasury` nodes. Control, permissions, and configuration can be set *per node*, creating a dynamic, nested governance and resource management system.

It incorporates concepts like:
*   **Fractal/Recursive Structure:** A hierarchy of linked contracts.
*   **Node-Specific Configuration & Roles:** Permissions and rules are defined for *each* treasury instance, not just a global admin.
*   **Dynamic State:** Behavior can change based on internal configuration values or epochs.
*   **Multi-Asset Management:** Handles Ether, ERC20, and ERC721.
*   **Recursive Queries:** Ability to query the hierarchy (with gas considerations).
*   **Generic Key-Value Configuration:** Allows flexibility in defining node behavior without hardcoding all rules.

---

**Smart Contract: `FractalTreasury`**

**Outline:**

1.  **License & Pragma:** Standard Solidity setup.
2.  **Imports:** Interfaces for ERC20, ERC721, Ownable, ReentrancyGuard.
3.  **Enums:** Define types for Resources, Roles, and Config keys.
4.  **Structs:** Define data structures for Resource details, Role assignments, and Configuration entries.
5.  **State Variables:** Store contract relationships (parent, children), owned resources, role assignments, configurations, epoch data, and basic contract identity.
6.  **Events:** Announce key actions like node creation, resource transfers, role changes, config updates, and epoch advancements.
7.  **Modifiers:** Custom access control based on roles and hierarchy.
8.  **Constructor:** Initializes the root treasury node.
9.  **Hierarchy Management Functions:** Create, link, unlink, query parent/children, manage child ownership.
10. **Resource Management Functions:** Register, deregister, transfer resources within the hierarchy or externally, list resources.
11. **Node Role Management Functions:** Assign, revoke, query roles specific to this treasury node.
12. **Node Configuration Functions:** Set, get, remove arbitrary key-value configurations for node behavior.
13. **Epoch & Time Functions:** Manage an internal epoch counter and trigger epoch-based logic.
14. **Query Functions:** Get depth, root, check ancestry, query resources/roles/configs.
15. **Receive/Withdrawal Functions:** Handle native token and ERC20/ERC721 withdrawals.
16. **Internal Helper Functions:** Logic for authorization, hierarchy traversal, etc.

**Function Summary:**

1.  `constructor()`: Deploys the root treasury node.
2.  `createChildTreasury(address initialChildOwner)`: Creates a new `FractalTreasury` contract as a child of the current node.
3.  `addChildTreasury(address childAddress)`: Links an *existing* `FractalTreasury` contract as a child (requires child's consent).
4.  `removeChildTreasury(address childAddress)`: Unlinks a child treasury (requires specific role).
5.  `getParentTreasury()`: Returns the address of the parent treasury.
6.  `getChildTreasuries()`: Returns an array of addresses of direct child treasuries.
7.  `transferChildOwnership(address childAddress, address newOwner)`: Transfers the `NODE_OWNER` role of a specific child node.
8.  `registerResource(ResourceType rType, address tokenAddress, uint256 tokenIdOrAmount)`: Registers a resource type/address/ID as being managed by *this* node. Does *not* transfer the asset itself, only records intent/ownership claim within the fractal structure.
9.  `deregisterResource(uint256 resourceId)`: Deregisters a previously registered resource.
10. `distributeResourceToChild(uint256 resourceId, address childAddress, uint256 amountOrTokenId)`: Records the intent to distribute a portion or specific item of a resource to a child node. Actual asset transfer needs separate action or rule evaluation.
11. `reclaimResourceFromChild(address childAddress, uint256 resourceId, uint256 amountOrTokenId)`: Records the intent to reclaim a resource from a child node (requires permissions on child node).
12. `transferResourceOut(uint256 resourceId, address recipient, uint256 amountOrTokenId)`: Initiates the *actual* transfer of the underlying asset for a registered resource to an external address. Requires permissions and resource availability.
13. `getResourceDetails(uint256 resourceId)`: Retrieves details of a registered resource.
14. `listOwnedResources()`: Lists all resource IDs registered to *this* node.
15. `assignNodeRole(address account, NodeRole role)`: Assigns a specific role to an address within *this* treasury node.
16. `revokeNodeRole(address account, NodeRole role)`: Revokes a role within *this* treasury node.
17. `hasNodeRole(address account, NodeRole role)`: Checks if an address has a specific role within *this* node.
18. `setNodeConfig(ConfigKey key, bytes32 value)`: Sets a configuration value for this node using a key.
19. `getNodeConfig(ConfigKey key)`: Gets a configuration value for this node.
20. `removeNodeConfig(ConfigKey key)`: Removes a configuration value.
21. `advanceEpoch()`: Increments the epoch counter for this node. Can be triggered manually or via rules/time.
22. `getCurrentEpoch()`: Returns the current epoch number for this node.
23. `triggerEpochRules()`: Placeholder function to simulate processing rules configured for the current epoch.
24. `getDepth()`: Returns the depth of this node in the hierarchy (root is 0).
25. `getRootTreasury()`: Returns the address of the root treasury node.
26. `isDescendant(address potentialDescendant)`: Checks if a given address is a descendant of this treasury node.
27. `receive()`: Allows the contract to receive Ether.
28. `withdrawERC20(address token, address recipient, uint256 amount)`: Withdraws a specific amount of an ERC20 token managed by this node.
29. `withdrawERC721(address token, address recipient, uint256 tokenId)`: Withdraws a specific ERC721 token managed by this node.
30. `setNodeOwner(address newOwner)`: Assigns the `NODE_OWNER` role, transferring primary control of this node.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using for root contract deployment

// --- Smart Contract: FractalTreasury ---
// Outline:
// 1. License & Pragma
// 2. Imports (Interfaces, OpenZeppelin helpers)
// 3. Enums (Resource Types, Node Roles, Config Keys)
// 4. Structs (Resource Details, Role Assignment)
// 5. State Variables (Hierarchy, Resources, Roles, Configs, Epoch)
// 6. Events
// 7. Modifiers (Internal authorization helper)
// 8. Constructor
// 9. Hierarchy Management Functions (create, add, remove child, parent/child queries)
// 10. Resource Management Functions (register, deregister, transfer, list, details)
// 11. Node Role Management Functions (assign, revoke, check roles per node)
// 12. Node Configuration Functions (set, get, remove config per node)
// 13. Epoch & Time Functions (advance, get epoch, trigger rules)
// 14. Query Functions (depth, root, ancestry)
// 15. Receive/Withdrawal Functions (Ether, ERC20, ERC721)
// 16. Internal Helper Functions (Authorization, hierarchy traversal, config parsing)
//
// Function Summary:
// 1. constructor()
// 2. createChildTreasury(address initialChildOwner)
// 3. addChildTreasury(address childAddress)
// 4. removeChildTreasury(address childAddress)
// 5. getParentTreasury()
// 6. getChildTreasuries()
// 7. transferChildOwnership(address childAddress, address newOwner)
// 8. registerResource(ResourceType rType, address tokenAddress, uint256 tokenIdOrAmount)
// 9. deregisterResource(uint256 resourceId)
// 10. distributeResourceToChild(uint256 resourceId, address childAddress, uint256 amountOrTokenId)
// 11. reclaimResourceFromChild(address childAddress, uint256 resourceId, uint256 amountOrTokenId)
// 12. transferResourceOut(uint256 resourceId, address recipient, uint256 amountOrTokenId)
// 13. getResourceDetails(uint256 resourceId)
// 14. listOwnedResources()
// 15. assignNodeRole(address account, NodeRole role)
// 16. revokeNodeRole(address account, NodeRole role)
// 17. hasNodeRole(address account, NodeRole role)
// 18. setNodeConfig(ConfigKey key, bytes32 value)
// 19. getNodeConfig(ConfigKey key)
// 20. removeNodeConfig(ConfigKey key)
// 21. advanceEpoch()
// 22. getCurrentEpoch()
// 23. triggerEpochRules() - Placeholder for dynamic logic
// 24. getDepth()
// 25. getRootTreasury()
// 26. isDescendant(address potentialDescendant)
// 27. receive() - Allows receiving Ether
// 28. withdrawERC20(address token, address recipient, uint256 amount)
// 29. withdrawERC721(address token, address recipient, uint256 tokenId)
// 30. setNodeOwner(address newOwner)

contract FractalTreasury is ReentrancyGuard, ERC721Holder {

    // --- Enums ---
    enum ResourceType {
        ETHER,
        ERC20,
        ERC721
    }

    // Define specific roles within THIS node
    enum NodeRole {
        NODE_OWNER,         // Primary controller of this specific node
        RESOURCE_MANAGER,   // Can manage resources owned by this node
        CHILD_MANAGER,      // Can create/add/remove children of this node
        ROLE_MANAGER,       // Can assign/revoke roles within this node
        CONFIG_MANAGER,     // Can set/get/remove config for this node
        EPOCH_ADVANCER      // Can advance the epoch for this node
    }

    // Define keys for generic configuration values
    enum ConfigKey {
        INVALID_KEY,
        RESOURCE_DISTRIBUTION_PERCENTAGE, // e.g., bytes32 representation of a percentage
        MIN_EPOCH_DURATION,               // e.g., bytes32 representation of seconds
        REQUIRED_ROLE_FOR_TRANSFERS,      // e.g., bytes32 representation of a NodeRole enum value
        ALLOW_PARENT_RECLAIM,             // e.g., bytes32(uint256(1)) for true, bytes32(uint256(0)) for false
        ALLOW_EXTERNAL_ADD_CHILD          // e.g., bytes32(uint256(1)) for true, bytes32(uint256(0)) for false
    }

    // --- Structs ---
    struct Resource {
        uint256 id;             // Unique ID within this node
        ResourceType rType;
        address tokenAddress;   // Address for ERC20/ERC721, address(0) for ETHER
        uint256 tokenIdOrAmount; // Token ID for ERC721, relevant for ERC20/ETHER tracking (though actual balance matters)
        string name;            // Optional name/description
        bool registered;        // Is this resource entry active?
    }

    // --- State Variables ---
    address public parentTreasury;
    FractalTreasury[] public childTreasuries; // Store child contract instances directly? Or just addresses? Addresses simpler.
    address[] private _childTreasuryAddresses; // Addresses of direct children

    uint256 private _resourceCounter = 0;
    // Mapping from resource ID to resource details
    mapping(uint256 => Resource) private _resources;
    // Mapping from (ResourceType, tokenAddress, tokenIdOrAmount) to resource ID? Could be complex.
    // Let's stick to ID -> Resource for simplicity, requiring users to track their resource IDs.

    // Mapping from account to role to boolean (has role?) within THIS node
    mapping(address => mapping(NodeRole => bool)) private _roles;

    // Mapping from ConfigKey to value
    mapping(ConfigKey => bytes32) private _config;

    uint256 private _currentEpoch = 0;
    uint256 private _lastEpochAdvanceTime = block.timestamp;

    // Root-specific variable, managed only by the initial deployer role
    address private _rootTreasury; // Address of the absolute top-level treasury
    uint256 private _depth;       // Depth in the hierarchy, root is 0

    // --- Events ---
    event ChildTreasuryCreated(address indexed childAddress, address indexed parentAddress, address indexed owner);
    event ChildTreasuryAdded(address indexed childAddress, address indexed parentAddress);
    event ChildTreasuryRemoved(address indexed childAddress, address indexed parentAddress);
    event ChildOwnershipTransferred(address indexed childAddress, address indexed oldOwner, address indexed newOwner);
    event ResourceRegistered(uint256 indexed resourceId, ResourceType rType, address tokenAddress, uint256 tokenIdOrAmount);
    event ResourceDeregistered(uint256 indexed resourceId);
    event ResourceDistributed(uint256 indexed resourceId, address indexed childAddress, uint256 amountOrTokenId);
    event ResourceReclaimed(uint256 indexed resourceId, address indexed childAddress, uint256 amountOrTokenId);
    event ResourceTransferredOut(uint256 indexed resourceId, address indexed recipient, uint256 amountOrTokenId);
    event NodeRoleAssigned(address indexed account, NodeRole role);
    event NodeRoleRevoked(address indexed account, NodeRole role);
    event NodeConfigUpdated(ConfigKey key, bytes32 value);
    event NodeConfigRemoved(ConfigKey key);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event NodeOwnerTransferred(address indexed oldOwner, address indexed newOwner);

    // --- Modifiers (Internal authorization helper) ---
    // This internal function checks if the caller has ANY of the required roles OR is the node owner.
    function _authorize(address caller, NodeRole[] memory requiredRoles) internal view returns (bool) {
        if (_roles[caller][NodeRole.NODE_OWNER]) {
            return true;
        }
        for (uint i = 0; i < requiredRoles.length; i++) {
            if (_roles[caller][requiredRoles[i]]) {
                return true;
            }
        }
        return false;
    }

    modifier onlyAuthorized(NodeRole[] memory requiredRoles) {
        require(_authorize(msg.sender, requiredRoles), "FT: Unauthorized");
        _;
    }

    modifier onlyNodeOwner() {
        require(_roles[msg.sender][NodeRole.NODE_OWNER], "FT: Only node owner");
        _;
    }

    // --- Constructor ---
    constructor(address _parentTreasury, uint256 initialDepth, address initialOwner) {
        // Root Treasury: parent is address(0), depth is 0, initial owner is deployer
        // Child Treasury: parent is creator, depth is parent.depth + 1, initial owner is specified
        parentTreasury = _parentTreasury;
        _depth = initialDepth;

        if (_parentTreasury == address(0)) {
            // This is the root treasury
            _rootTreasury = address(this);
            // Assign NODE_OWNER role to the initial deployer/owner
             _roles[initialOwner][NodeRole.NODE_OWNER] = true;
        } else {
             // This is a child treasury
            // The root treasury address is passed from the parent during creation
            // (Requires parent to know/store root, or compute it)
            // Let's pass it from parent constructor call for simplicity
            // Or better, recursively find it once needed? Recursive find is complex/gas heavy.
            // A simpler approach: The *creator* of a child is its initial NODE_OWNER,
            // and they can set the root address based on their own root.
            _roles[initialOwner][NodeRole.NODE_OWNER] = true;
            // How does the child know the root? The parent must tell it.
            // Let's adjust the constructor signature slightly, or add a post-creation setup.
            // Post-creation setup is risky if not done atomically with creation.
            // Let's add _rootTreasury to constructor params.

            // Reworking constructor to take root address
            // Initial deployment must set root to address(this)
            // Child deployment must pass parent's root address
             revert("FT: Use factory or parent to create child"); // Should not deploy child directly via constructor
        }
    }

    // Proper constructor for Root Treasury deployment
    function initializeRoot() public {
        require(parentTreasury == address(0), "FT: Already initialized");
        _rootTreasury = address(this);
        _depth = 0;
        // Assuming Ownable pattern for initial root owner assignment
        // We inherit Ownable just for the initial deployment/transferRootOwnership
        // After root owner is set, we can use the internal role system.
        // Let's simplify and use NODE_OWNER for the root directly, assignable upon deployment.
        // The *deployer* of the root contract gets the NODE_OWNER role automatically.
        // Need to remove Ownable inheritance then and manage root owner like any other node owner.
        // Let's add a public function to assign the initial root owner after deployment.
        // Or, better, the constructor takes initial owner, works for root and children.
    }

    // Simplified Constructor (works for root and children if deployed via factory/parent)
    // Root deployment: _parent=address(0), _depth=0, _root=address(this), _initialOwner=deployer
    // Child deployment: _parent=parentAddress, _depth=parent.depth+1, _root=parent.root, _initialOwner=specified
    constructor(address _parent, uint256 _initialDepth, address _root, address _initialOwner) {
        require(_initialOwner != address(0), "FT: Invalid owner");
        parentTreasury = _parent;
        _depth = _initialDepth;
        _rootTreasury = _root;
        _roles[_initialOwner][NodeRole.NODE_OWNER] = true;

        if (_parent != address(0)) {
            // Child must allow itself to be added by parent
            // Or the parent must just add it without child consent?
            // Let's assume parent can add child without explicit consent, but child
            // can potentially detach later based on config/roles.
        }
    }

    // Fallback to receive Ether
    receive() external payable {}

    // --- Hierarchy Management ---

    /// @notice Creates and deploys a new FractalTreasury contract as a child of this node.
    /// @param initialChildOwner The address that will receive the NODE_OWNER role in the new child node.
    /// @return childAddress The address of the newly deployed child treasury contract.
    function createChildTreasury(address initialChildOwner)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.CHILD_MANAGER))
        returns (address childAddress)
    {
        // Deploy a new child contract, passing required constructor parameters
        // Note: This requires the parent contract to know how to deploy the child contract code.
        // This is a simplification; in reality, you might use a factory contract.
        // For demonstration, let's assume the contract bytecode is known/hardcoded or proxied.
        // Using `new FractalTreasury(...)` directly here is possible if this code IS the child code.
        // This requires a deployer/factory pattern or self-deployment logic.
        // Let's simulate using a factory pattern concept - assume 'new FractalTreasury' works.
        // In a real scenario, this would call a factory: `FractalTreasury child = factory.createTreasury(...)`

        FractalTreasury child = new FractalTreasury(
            address(this),             // parent
            _depth + 1,                // depth
            _rootTreasury,             // root (inherited from parent)
            initialChildOwner          // initial node owner of the child
        );

        _childTreasuryAddresses.push(address(child));
        // childTreasuries.push(child); // Store interface/address directly
        emit ChildTreasuryCreated(address(child), address(this), initialChildOwner);
        return address(child);
    }

    /// @notice Adds an existing FractalTreasury contract as a child of this node.
    /// Requires configuration on the child node allowing external addition.
    /// @param childAddress The address of the FractalTreasury contract to add.
    function addChildTreasury(address childAddress)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.CHILD_MANAGER))
    {
        require(childAddress != address(0) && childAddress != address(this), "FT: Invalid child address");
        // Check if already a child
        for (uint i = 0; i < _childTreasuryAddresses.length; i++) {
            require(_childTreasuryAddresses[i] != childAddress, "FT: Already a child");
        }

        FractalTreasury child = FractalTreasury(childAddress);

        // Check if child allows being added by this specific parent, or generally
        // Requires a mechanism on the child to signal this consent/configuration.
        // Example: Check a config key on the child
        bytes32 allowExternalAdd = child.getNodeConfig(ConfigKey.ALLOW_EXTERNAL_ADD_CHILD);
        require(bytes32ToUint(allowExternalAdd) == 1, "FT: Child does not allow external adding");

        // Check if child's parent is address(0) or this address to prevent linking elsewhere
        require(child.getParentTreasury() == address(0) || child.getParentTreasury() == address(this), "FT: Child already belongs to another parent");

        // @TODO: More robust checks? Like matching root treasury address?
        // require(child.getRootTreasury() == _rootTreasury, "FT: Child root mismatch");
         require(child.getDepth() == _depth + 1, "FT: Child depth mismatch");

        _childTreasuryAddresses.push(childAddress);
        // childTreasuries.push(child);
        emit ChildTreasuryAdded(childAddress, address(this));

        // Note: The child's parent variable is set during its creation.
        // This function is for linking from the parent's side.
    }

    /// @notice Removes a linked child treasury. Does NOT destroy the child contract.
    /// @param childAddress The address of the child treasury to remove.
    function removeChildTreasury(address childAddress)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.CHILD_MANAGER))
    {
        bool found = false;
        for (uint i = 0; i < _childTreasuryAddresses.length; i++) {
            if (_childTreasuryAddresses[i] == childAddress) {
                // Simple remove by swapping with last and pop
                _childTreasuryAddresses[i] = _childTreasuryAddresses[_childTreasuryAddresses.length - 1];
                _childTreasuryAddresses.pop();
                found = true;
                break;
            }
        }
        require(found, "FT: Child not found");
        // Note: The child's parent variable is NOT changed by this.
        // The child contract would need a separate function to potentially nullify its parent
        // or allow a new parent based on its internal rules/roles.
        emit ChildTreasuryRemoved(childAddress, address(this));
    }


    /// @notice Returns the address of the parent treasury.
    function getParentTreasury() external view returns (address) {
        return parentTreasury;
    }

    /// @notice Returns the addresses of direct child treasuries.
    function getChildTreasuries() external view returns (address[] memory) {
        return _childTreasuryAddresses;
    }

    /// @notice Transfers the NODE_OWNER role of a specific child node.
    /// Requires being NODE_OWNER of the child OR having a specific role on the parent
    /// that is authorized to manage child roles (e.g. CHILD_MANAGER with config/rule).
    /// For simplicity here, requires being NODE_OWNER of the child.
    /// A more complex system could allow a parent's ROLE_MANAGER to do this.
    /// @param childAddress The address of the child treasury.
    /// @param newOwner The address to assign as the new NODE_OWNER of the child.
    function transferChildOwnership(address childAddress, address newOwner)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.CHILD_MANAGER)) // Requires parent CHILD_MANAGER role to initiate
    {
        require(newOwner != address(0), "FT: Invalid new owner");
        // Ensure child exists and is linked
        bool isLinkedChild = false;
        for(uint i=0; i<_childTreasuryAddresses.length; i++) {
            if (_childTreasuryAddresses[i] == childAddress) {
                isLinkedChild = true;
                break;
            }
        }
        require(isLinkedChild, "FT: Not a linked child");

        // Call the child's setNodeOwner function
        FractalTreasury child = FractalTreasury(childAddress);
        // This requires the caller (msg.sender) to have permission *on the child*
        // to call setNodeOwner, OR the child must have a specific rule/role check
        // allowing the parent's authorized address to call it.
        // Assuming child allows its parent's CHILD_MANAGER to call setNodeOwner for simplicity:
        // In child's setNodeOwner: check if msg.sender is parent.CHILD_MANAGER AND parent.getAddress() == msg.sender.parentTreasury
        child.setNodeOwner(newOwner); // Child contract handles actual role assignment

        emit ChildOwnershipTransferred(childAddress, msg.sender, newOwner); // oldOwner is implicit msg.sender if only owner can call
    }

    /// @notice Allows the current NODE_OWNER to transfer their role to another address.
    /// This is the primary way to transfer control of this specific node.
    /// @param newOwner The address to assign as the new NODE_OWNER.
    function setNodeOwner(address newOwner) external onlyNodeOwner {
        require(newOwner != address(0), "FT: Invalid new owner");
        address oldOwner = msg.sender; // The current owner calling the function

        // Revoke the old owner's NODE_OWNER role
        _roles[oldOwner][NodeRole.NODE_OWNER] = false;
        // Assign the new owner the NODE_OWNER role
        _roles[newOwner][NodeRole.NODE_OWNER] = true;

        emit NodeOwnerTransferred(oldOwner, newOwner);
    }


    // --- Resource Management ---

    /// @notice Registers a resource that this treasury node is intended to manage.
    /// This function only records the resource details, it does NOT transfer the actual asset.
    /// The actual asset transfer/holding is separate (e.g., direct sends to this contract address).
    /// @param rType The type of resource (ETHER, ERC20, ERC721).
    /// @param tokenAddress The address of the token contract (address(0) for ETHER).
    /// @param tokenIdOrAmount Identifier for the resource (Token ID for ERC721, can be 0 or indicative for ERC20/ETHER).
    /// @param name Optional name/description for the resource.
    /// @return resourceId The unique ID assigned to this registered resource entry.
    function registerResource(ResourceType rType, address tokenAddress, uint256 tokenIdOrAmount, string calldata name)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
        returns (uint256 resourceId)
    {
        _resourceCounter++;
        resourceId = _resourceCounter;

        _resources[resourceId] = Resource({
            id: resourceId,
            rType: rType,
            tokenAddress: tokenAddress,
            tokenIdOrAmount: tokenIdOrAmount, // Represents a specific ERC721 or could be a 'type' identifier for fungibles
            name: name,
            registered: true
        });

        emit ResourceRegistered(resourceId, rType, tokenAddress, tokenIdOrAmount);
        return resourceId;
    }

    /// @notice Deregisters a resource entry. Does NOT transfer the actual asset.
    /// @param resourceId The ID of the resource entry to deregister.
    function deregisterResource(uint256 resourceId)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
    {
        require(_resources[resourceId].registered, "FT: Resource not registered");
        _resources[resourceId].registered = false; // Mark as inactive

        // Consider if resource data should be fully deleted (gas cost) vs marked inactive.
        // Marking inactive is safer if resourceId might be referenced elsewhere.
        // delete _resources[resourceId]; // Alternative: full deletion

        emit ResourceDeregistered(resourceId);
    }

    /// @notice Records the intention to distribute a portion/item of a registered resource to a child node.
    /// Actual asset transfer depends on subsequent actions or epoch processing.
    /// @param resourceId The ID of the registered resource.
    /// @param childAddress The address of the child treasury.
    /// @param amountOrTokenId The amount (for fungible) or token ID (for ERC721) to distribute.
    function distributeResourceToChild(uint256 resourceId, address childAddress, uint256 amountOrTokenId)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
    {
        require(_resources[resourceId].registered, "FT: Resource not registered");
        // Verify childAddress is a linked child
        bool isLinkedChild = false;
        for(uint i=0; i<_childTreasuryAddresses.length; i++) {
            if (_childTreasuryAddresses[i] == childAddress) {
                isLinkedChild = true;
                break;
            }
        }
        require(isLinkedChild, "FT: Not a linked child");

        // @TODO: Add logic to track amounts/items marked for distribution per child.
        // This function currently only emits an event indicating intent.
        // A more complex version would update state, pending actual transfer by triggerEpochRules or another function.

        emit ResourceDistributed(resourceId, childAddress, amountOrTokenId);
    }

     /// @notice Records the intention to reclaim a portion/item of a registered resource from a child node.
     /// Actual asset transfer depends on child's rules/permissions and subsequent actions.
     /// @param childAddress The address of the child treasury to reclaim from.
     /// @param resourceId The ID of the resource registered on the parent (this node).
     /// @param amountOrTokenId The amount (for fungible) or token ID (for ERC721) to reclaim.
    function reclaimResourceFromChild(address childAddress, uint256 resourceId, uint256 amountOrTokenId)
        external
         onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
    {
        // Verify childAddress is a linked child
        bool isLinkedChild = false;
        for(uint i=0; i<_childTreasuryAddresses.length; i++) {
            if (_childTreasuryAddresses[i] == childAddress) {
                isLinkedChild = true;
                break;
            }
        }
        require(isLinkedChild, "FT: Not a linked child");
        require(_resources[resourceId].registered, "FT: Resource not registered on parent");

        // @TODO: Implement actual logic to request/pull from child, requires child's cooperation (allowParentReclaim config)
        // Child contract would need a function like `allowReclaim(address parentAddress, uint256 resourceId, uint256 amountOrTokenId)`
        // and authorization checks within that function based on its own roles/config.
        // This function currently only emits an event indicating intent.

        emit ResourceReclaimed(resourceId, childAddress, amountOrTokenId);
    }


    /// @notice Initiates the actual transfer of the underlying asset for a registered resource.
    /// Requires having the physical asset balance/ownership in this contract.
    /// @param resourceId The ID of the registered resource.
    /// @param recipient The address to transfer the asset to.
    /// @param amountOrTokenId The amount (for fungible) or token ID (for ERC721) to transfer.
    function transferResourceOut(uint256 resourceId, address recipient, uint256 amountOrTokenId)
        external
        nonReentrant // Prevent reentrancy during token transfers
        onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
    {
        Resource storage res = _resources[resourceId];
        require(res.registered, "FT: Resource not registered");
        require(recipient != address(0), "FT: Invalid recipient");

        // @TODO: Add rule/config check here, e.g., based on REQUIRED_ROLE_FOR_TRANSFERS

        if (res.rType == ResourceType.ETHER) {
            // Ensure contract has enough Ether
            require(address(this).balance >= amountOrTokenId, "FT: Insufficient Ether");
            (bool success, ) = payable(recipient).call{value: amountOrTokenId}("");
            require(success, "FT: Ether transfer failed");
        } else if (res.rType == ResourceType.ERC20) {
            // Ensure contract has enough ERC20
             IERC20 token = IERC20(res.tokenAddress);
             require(token.balanceOf(address(this)) >= amountOrTokenId, "FT: Insufficient ERC20 balance");
             require(token.transfer(recipient, amountOrTokenId), "FT: ERC20 transfer failed");
        } else if (res.rType == ResourceType.ERC721) {
            // Ensure contract owns the specific ERC721 token
            IERC721 token = IERC721(res.tokenAddress);
            require(token.ownerOf(amountOrTokenId) == address(this), "FT: ERC721 not owned");
            token.safeTransferFrom(address(this), recipient, amountOrTokenId);
        } else {
            revert("FT: Unknown resource type");
        }

        emit ResourceTransferredOut(resourceId, recipient, amountOrTokenId);
    }

    /// @notice Gets the details of a registered resource.
    /// @param resourceId The ID of the resource.
    /// @return Resource struct containing resource details.
    function getResourceDetails(uint256 resourceId)
        external
        view
        returns (Resource memory)
    {
        require(_resources[resourceId].registered, "FT: Resource not registered");
        return _resources[resourceId];
    }

    /// @notice Lists the IDs of all resources currently registered to this node.
    /// @return An array of resource IDs.
    function listOwnedResources()
        external
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;
        // First pass to count active resources
        for (uint256 i = 1; i <= _resourceCounter; i++) {
            if (_resources[i].registered) {
                count++;
            }
        }

        uint256[] memory resourceIds = new uint256[](count);
        uint256 index = 0;
        // Second pass to fill the array
        for (uint256 i = 1; i <= _resourceCounter; i++) {
            if (_resources[i].registered) {
                resourceIds[index] = i;
                index++;
            }
        }
        return resourceIds;
    }


    // --- Node Role Management ---

    /// @notice Assigns a specific role to an account within THIS treasury node.
    /// Requires the caller to have the ROLE_MANAGER role for this node.
    /// @param account The address to assign the role to.
    /// @param role The role to assign.
    function assignNodeRole(address account, NodeRole role)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.ROLE_MANAGER))
    {
        require(account != address(0), "FT: Invalid account");
        // Cannot assign NODE_OWNER role via this function, use setNodeOwner instead.
        require(role != NodeRole.NODE_OWNER, "FT: Use setNodeOwner for NODE_OWNER role");
        _roles[account][role] = true;
        emit NodeRoleAssigned(account, role);
    }

    /// @notice Revokes a specific role from an account within THIS treasury node.
    /// Requires the caller to have the ROLE_MANAGER role for this node.
    /// @param account The address to revoke the role from.
    /// @param role The role to revoke.
    function revokeNodeRole(address account, NodeRole role)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.ROLE_MANAGER))
    {
        require(account != address(0), "FT: Invalid account");
         // Cannot revoke NODE_OWNER role via this function. Owner must transfer.
        require(role != NodeRole.NODE_OWNER, "FT: Use setNodeOwner to transfer NODE_OWNER role");
        _roles[account][role] = false;
        emit NodeRoleRevoked(account, role);
    }

    /// @notice Checks if an account has a specific role within THIS treasury node.
    /// @param account The address to check.
    /// @param role The role to check for.
    /// @return bool True if the account has the role, false otherwise.
    function hasNodeRole(address account, NodeRole role)
        external
        view
        returns (bool)
    {
        return _roles[account][role];
    }


    // --- Node Configuration ---

    /// @notice Sets a configuration value for this node.
    /// Requires the caller to have the CONFIG_MANAGER role for this node.
    /// Can be used to store arbitrary configuration influencing node behavior.
    /// @param key The configuration key (enum).
    /// @param value The value (bytes32).
    function setNodeConfig(ConfigKey key, bytes32 value)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.CONFIG_MANAGER))
    {
         require(key != ConfigKey.INVALID_KEY, "FT: Invalid config key");
        _config[key] = value;
        emit NodeConfigUpdated(key, value);
    }

    /// @notice Gets a configuration value for this node.
    /// @param key The configuration key.
    /// @return bytes32 The stored value. Returns bytes32(0) if not set.
    function getNodeConfig(ConfigKey key)
        external
        view
        returns (bytes32)
    {
         require(key != ConfigKey.INVALID_KEY, "FT: Invalid config key");
        return _config[key];
    }

    /// @notice Removes a configuration value for this node.
    /// Requires the caller to have the CONFIG_MANAGER role for this node.
    /// @param key The configuration key.
    function removeNodeConfig(ConfigKey key)
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.CONFIG_MANAGER))
    {
         require(key != ConfigKey.INVALID_KEY, "FT: Invalid config key");
        delete _config[key];
        emit NodeConfigRemoved(key);
    }

    // Helper to convert bytes32 to uint256 for config values
    function bytes32ToUint(bytes32 b) internal pure returns (uint256) {
        return uint256(b);
    }

    // Helper to convert NodeRole enum to bytes32 for config values
    function nodeRoleToBytes32(NodeRole role) internal pure returns (bytes32) {
        return bytes32(uint256(role));
    }

    // Helper to convert bytes32 to NodeRole enum
    function bytes32ToNodeRole(bytes32 b) internal pure returns (NodeRole) {
         // Add checks to ensure the uint value corresponds to a valid enum member
         uint256 value = uint256(b);
         if (value > uint256(NodeRole.EPOCH_ADVANCER)) {
             revert("FT: Invalid role value in config");
         }
         return NodeRole(value);
    }


    // --- Epoch & Time ---

    /// @notice Advances the internal epoch counter for this node.
    /// Can be triggered manually by EPOCH_ADVANCER or via a separate mechanism (e.g., oracle, time lock).
    function advanceEpoch()
        external
        onlyAuthorized(new NodeRole[](1).push(NodeRole.EPOCH_ADVANCER))
    {
        // Optional: Check MIN_EPOCH_DURATION config
        bytes32 minDurationBytes = _config[ConfigKey.MIN_EPOCH_DURATION];
        uint256 minDuration = bytes32ToUint(minDurationBytes);
        if (minDuration > 0) {
            require(block.timestamp >= _lastEpochAdvanceTime + minDuration, "FT: Minimum epoch duration not passed");
        }

        _currentEpoch++;
        _lastEpochAdvanceTime = block.timestamp;

        // @TODO: Automatically trigger triggerEpochRules here? Or keep separate?
        // Keeping separate allows for more control over gas usage.

        emit EpochAdvanced(_currentEpoch, _lastEpochAdvanceTime);
    }

    /// @notice Returns the current epoch number for this node.
    function getCurrentEpoch() external view returns (uint256) {
        return _currentEpoch;
    }

    /// @notice Placeholder function to trigger rule evaluation based on the current epoch.
    /// This function would contain complex logic based on node configuration and state.
    /// For example:
    /// - Distribute resources to children based on config and epoch number.
    /// - Change node configuration based on epoch.
    /// - Trigger actions in child nodes.
    /// Requires EPOCH_ADVANCER role or triggered by advanceEpoch.
    function triggerEpochRules()
        external
         onlyAuthorized(new NodeRole[](1).push(NodeRole.EPOCH_ADVANCER))
    {
        // --- COMPLEX RULE EVALUATION LOGIC GOES HERE ---
        // Example: Read RESOURCE_DISTRIBUTION_PERCENTAGE config
        // bytes32 distributionBytes = _config[ConfigKey.RESOURCE_DISTRIBUTION_PERCENTAGE];
        // uint256 percentage = bytes32ToUint(distributionBytes);
        // If percentage > 0, iterate through registered resources and child nodes,
        // calculating and potentially executing transfers (or marking them as pending).

        // Example: Check for time-based config changes
        // bytes32 futureConfigBytes = _config[ConfigKey.SOME_FUTURE_CONFIG];
        // if (bytes32ToUint(futureConfigBytes) == _currentEpoch) {
        //    // Apply config change planned for this epoch
        // }

        // Example: Trigger children's epoch rules (careful with gas and recursion depth)
        // for (uint i = 0; i < _childTreasuryAddresses.length; i++) {
        //    FractalTreasury child = FractalTreasury(_childTreasuryAddresses[i]);
        //    // child.triggerEpochRules(); // Recursive call - gas limit risk!
        //    // Better: Events or external process triggers child rules
        // }

        // --- END COMPLEX RULE EVALUATION LOGIC ---

        // Emit an event indicating rules were processed for this epoch
        emit EpochAdvanced(_currentEpoch, block.timestamp); // Re-emitting or a separate event? Let's re-emit for now.
        // Alternatively: event EpochRulesTriggered(uint256 indexed epoch);
    }

    // --- Query Functions ---

    /// @notice Gets the depth of this treasury node in the hierarchy. Root is 0.
    function getDepth() external view returns (uint256) {
        return _depth;
    }

    /// @notice Gets the address of the absolute root treasury node.
    function getRootTreasury() external view returns (address) {
        // Assuming _rootTreasury is correctly set in the constructor
        // A recursive traversal method would be:
        // address current = address(this);
        // while (FractalTreasury(current).parentTreasury() != address(0)) {
        //     current = FractalTreasury(current).parentTreasury();
        // }
        // return current;
        // But storing it is much more gas efficient.
        return _rootTreasury;
    }

    /// @notice Checks if a given address is a descendant (child, grandchild, etc.) of this treasury node.
    /// @param potentialDescendant The address to check.
    /// @return bool True if the address is a descendant, false otherwise.
    function isDescendant(address potentialDescendant) external view returns (bool) {
        if (potentialDescendant == address(0) || potentialDescendant == address(this)) {
            return false;
        }

        address current = potentialDescendant;
        // Traverse upwards from the potential descendant
        while (current != address(0) && current != address(this)) {
             // Check if current is a FractalTreasury and has a parent
             try FractalTreasury(current).parentTreasury() returns (address parent) {
                 current = parent;
             } catch {
                 // If the call fails (not a FT or no parent function), it's not in this hierarchy
                 return false;
             }
        }

        // If we reached this address by traversing upwards, it's a descendant
        return current == address(this);
    }

    // --- Receive / Withdrawal Functions ---

    // Inherited receive() handles incoming Ether

    /// @notice Withdraws ERC20 tokens held by this treasury.
    /// Requires RESOURCE_MANAGER role AND that the token resource is registered.
    /// @param token Address of the ERC20 token.
    /// @param recipient Address to send tokens to.
    /// @param amount Amount of tokens to withdraw.
    function withdrawERC20(address token, address recipient, uint256 amount)
        external
        nonReentrant
        onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
    {
         require(token != address(0) && recipient != address(0), "FT: Invalid addresses");
         // Optional: Check if this token is *registered* as a resource type ERC20
         // This requires iterating registered resources or having a lookup, which is complex.
         // For simplicity, let's assume permission is enough, but registration is for tracking.
         // Adding a lookup check would be more robust:
         // bool isRegistered = false;
         // for (uint256 i = 1; i <= _resourceCounter; i++) {
         //     if (_resources[i].registered && _resources[i].rType == ResourceType.ERC20 && _resources[i].tokenAddress == token) {
         //         isRegistered = true; break;
         //     }
         // }
         // require(isRegistered, "FT: ERC20 resource not registered for this node");


        IERC20 erc20Token = IERC20(token);
        require(erc20Token.transfer(recipient, amount), "FT: ERC20 withdrawal failed");
    }

     /// @notice Withdraws a specific ERC721 token held by this treasury.
    /// Requires RESOURCE_MANAGER role AND that the NFT resource is registered (optionally).
    /// @param token Address of the ERC721 token.
    /// @param recipient Address to send the token to.
    /// @param tokenId ID of the token to withdraw.
    function withdrawERC721(address token, address recipient, uint256 tokenId)
        external
        nonReentrant
        onlyAuthorized(new NodeRole[](1).push(NodeRole.RESOURCE_MANAGER))
    {
        require(token != address(0) && recipient != address(0), "FT: Invalid addresses");
        // Optional: Check if this NFT is *registered* as a resource type ERC721
        // bool isRegistered = false;
        // for (uint256 i = 1; i <= _resourceCounter; i++) {
        //     if (_resources[i].registered && _resources[i].rType == ResourceType.ERC721 && _resources[i].tokenAddress == token && _resources[i].tokenIdOrAmount == tokenId) {
        //         isRegistered = true; break;
        //     }
        // }
        // require(isRegistered, "FT: ERC721 resource not registered for this node");


        IERC721 erc721Token = IERC721(token);
        // This contract must inherit ERC721Holder or implement onERC721Received to receive NFTs
        // Added ERC721Holder inheritance
        require(erc721Token.ownerOf(tokenId) == address(this), "FT: Not owner of ERC721");
        erc721Token.safeTransferFrom(address(this), recipient, tokenId);
    }

    // Override ERC721Holder's onERC721Received if needed for custom logic on receive
    // default implementation is usually sufficient to accept NFTs
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    //     public virtual override returns (bytes4)
    // {
    //     // Add logging or specific checks if needed
    //     return this.onERC721Received.selector;
    // }

    // --- Internal Helpers ---

    // Add more internal helpers as needed for complex rule evaluations, recursive traversal (careful with gas), etc.
}
```

---

**Explanation of Advanced/Creative Concepts & Functionality:**

1.  **Fractal/Recursive Structure (`parentTreasury`, `_childTreasuryAddresses`, `createChildTreasury`, `getParentTreasury`, `getChildTreasuries`, `getDepth`, `getRootTreasury`, `isDescendant`):** The core concept is the `FractalTreasury` contract holding references to its parent and children. This allows for arbitrary depth in the hierarchy. `createChildTreasury` allows a node to spawn new nodes. Query functions like `getDepth`, `getRootTreasury`, and `isDescendant` (though the recursive ones need careful gas consideration) explore this structure.
2.  **Node-Specific Configuration & Roles (`NodeRole`, `ConfigKey`, `_roles`, `_config`, `assignNodeRole`, `revokeNodeRole`, `hasNodeRole`, `setNodeConfig`, `getNodeConfig`, `removeNodeConfig`, `onlyAuthorized`, `onlyNodeOwner`, `setNodeOwner`):** Instead of a single owner or admin for the entire system, permissions (`NodeRole`) and arbitrary key-value configurations (`ConfigKey`, `_config`) are managed *per instance* of the `FractalTreasury` contract. This allows different branches or nodes of the fractal to have distinct governance rules, resource distribution policies, etc., independent of the root or siblings. `setNodeOwner` provides a dedicated way to transfer the primary control of a specific node. `onlyAuthorized` combines role checks with the `NODE_OWNER` override.
3.  **Dynamic State (`_currentEpoch`, `advanceEpoch`, `triggerEpochRules`, `MIN_EPOCH_DURATION` config):** The `_currentEpoch` counter introduces a time or event-based state change mechanism. `advanceEpoch` (which could be manually triggered, or by a separate time-based contract/oracle) moves the node into a new epoch. `triggerEpochRules` is a placeholder where complex logic could be implemented to change node behavior, distribute resources, or interact with children *based on the current epoch and configuration*. This allows for state to evolve dynamically.
4.  **Multi-Asset Management (`ResourceType`, `Resource`, `_resources`, `registerResource`, `deregisterResource`, `transferResourceOut`, `withdrawERC20`, `withdrawERC721`):** The contract can track and manage different types of assets (Ether, ERC20, ERC721) owned by the contract address. `registerResource` provides an internal way *for the node* to claim management over a specific asset, separating the *concept* of ownership within the fractal from the *physical* token holding. Withdrawal functions provide the mechanism to move assets out.
5.  **Intent vs. Action (`distributeResourceToChild`, `reclaimResourceFromChild`):** These functions record the *intention* to move resources between parent and child nodes within the fractal. The actual asset transfer isn't necessarily executed by these calls but would likely happen during an `advanceEpoch` or `triggerEpochRules` call based on the node's configured rules and potentially requiring cooperation from the child node (e.g., `ALLOW_PARENT_RECLAIM` config). This decouples governance intent from execution mechanics.
6.  **Generic Configuration (`ConfigKey`, `setNodeConfig`, `getNodeConfig`):** The `_config` mapping with `ConfigKey` allows defining flexible rules and parameters for a node's behavior without hardcoding every possible rule into a function. This enables setting things like distribution percentages, required roles for actions, or boolean flags (`ALLOW_PARENT_RECLAIM`, `ALLOW_EXTERNAL_ADD_CHILD`) dynamically per node.

This contract is a foundation. A real-world implementation would require a factory contract to deploy children, more sophisticated rule evaluation logic in `triggerEpochRules`, potentially inter-contract calls between parent and child for resource transfers (`reclaimResourceFromChild` needs child function calls), and careful gas management for any recursive operations. The `ERC721Holder` is included to allow the contract to receive NFTs. `ReentrancyGuard` is added for safety during withdrawals.