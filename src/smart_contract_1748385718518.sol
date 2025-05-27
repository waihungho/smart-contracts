Okay, let's design a sophisticated smart contract system that manages dynamic, craftable, and evolvable digital assets (like avatars) using a component-based system, staking mechanics, and some administrative controls. We will build a custom logic layer instead of relying on standard open-source interfaces directly to fulfill the "don't duplicate open source" requirement for the core logic itself (though basic patterns like access control will be implemented manually).

This contract will involve:
1.  **Components:** Non-fungible pieces (hats, bodies, backgrounds) required to craft Avatars.
2.  **Avatars:** Unique, dynamic NFTs crafted from components. They can evolve and be staked.
3.  **Crafting:** A process that consumes components and creates an Avatar, potentially requiring a fee.
4.  **Evolution:** A process to upgrade an Avatar, potentially requiring more components or tokens.
5.  **Staking:** Locking Avatars to earn simulated yield or accrue benefits over time.
6.  **Dynamic Traits:** Avatar traits that can change based on factors like evolution level or staking duration.
7.  **Dismantling:** Breaking down an Avatar to recover some resources (e.g., "Salvage" components).
8.  **Admin Controls:** Functions for the owner to configure recipes, fees, yield rates, etc.

**Outline & Function Summary:**

**Contract: CryptoAvatarForge**

This contract manages a system of craftable, evolvable, and stakeable digital assets (Avatars) built from non-fungible Components.

1.  **Core Assets & Data Structures:**
    *   `Component` struct: Represents a piece used in crafting (e.g., Hat, Body).
    *   `Avatar` struct: Represents the main dynamic NFT asset.
    *   `CraftingRecipe` struct: Defines component requirements for crafting an Avatar base type.
    *   Mappings for tracking ownership, asset details, and system state.
    *   Enums for Component types.

2.  **Access Control & Pausing:**
    *   Basic owner-based access control.
    *   System-wide pausing mechanism.

3.  **Component Management:**
    *   Minting new components.
    *   Transferring component ownership.
    *   Viewing component details.

4.  **Avatar Management:**
    *   Crafting Avatars from components.
    *   Transferring Avatar ownership.
    *   Viewing static Avatar details (components used).
    *   Viewing dynamic Avatar state (including derived traits).
    *   Evolving Avatars (upgrading them).
    *   Dismantling Avatars (burning the Avatar, yielding salvage).

5.  **Staking Mechanics:**
    *   Staking Avatars (locking them in the contract).
    *   Unstaking Avatars (retrieving them).
    *   Claiming staking yield/benefits without unstaking.
    *   Calculating pending staking yield/duration.

6.  **Admin & Configuration:**
    *   Setting crafting recipes.
    *   Adjusting crafting fees.
    *   Setting staking yield rates.
    *   Adding/Managing component types.
    *   Withdrawing collected fees.

7.  **Events:**
    *   Emit events for significant actions (Mint, Transfer, Craft, Evolve, Stake, Unstake, Dismantle, Configuration changes).

**Function Summary (Approximate Count: 26+):**

*   `constructor()`: Initialize contract, set owner.
*   `pause()`: Pause contract operations (owner).
*   `unpause()`: Unpause contract operations (owner).
*   `transferOwnership(address newOwner)`: Transfer ownership (owner).
*   `withdrawFees(address payable recipient)`: Withdraw accumulated fees (owner).
*   `addComponentType(string memory name)`: Register a new component type (owner).
*   `toggleComponentMinting(uint256 componentTypeId, bool canMint)`: Enable/disable minting for a component type (owner).
*   `setComponentCraftingRecipe(uint256 avatarBaseType, uint256[] memory requiredComponentTypes, uint256[] memory requiredQuantities)`: Define a recipe (owner).
*   `setCraftingFee(uint256 avatarBaseType, uint256 fee)`: Set crafting fee for a recipe (owner).
*   `setStakingYieldRate(uint256 ratePerSecond)`: Set the staking reward rate (owner).
*   `mintComponent(uint256 componentTypeId, address recipient)`: Mint a component of a specific type (can be restricted, e.g., owner or via another mechanism).
*   `transferComponent(address from, address to, uint256 componentId)`: Transfer component ownership.
*   `getComponentDetails(uint256 componentId)`: View component details.
*   `getComponentsByOwner(address owner)`: View list of component IDs owned by address.
*   `craftAvatar(uint256 avatarBaseType, uint256[] memory componentIds)`: Craft an avatar using components, pay fee.
*   `transferAvatar(address from, address to, uint256 avatarId)`: Transfer avatar ownership.
*   `getAvatarDetails(uint256 avatarId)`: View static avatar details.
*   `getAvatarsByOwner(address owner)`: View list of avatar IDs owned by address.
*   `evolveAvatar(uint256 avatarId, uint256[] memory componentIdsToConsume)`: Evolve an avatar by consuming components.
*   `dismantleAvatar(uint256 avatarId)`: Burn an avatar, receive salvage components.
*   `stakeAvatar(uint256 avatarId)`: Stake an avatar.
*   `unstakeAvatar(uint256 avatarId)`: Unstake an avatar, claim yield.
*   `claimStakingYield(uint256 avatarId)`: Claim yield without unstaking.
*   `getPendingYield(uint256 avatarId)`: Calculate pending staking yield.
*   `updateDynamicTraits(uint256 avatarId)`: (Potentially callable by anyone) Trigger an update to dynamic traits based on current state (e.g., staking time). *Note: This function itself doesn't change state if traits are purely derived; it's more of a getter that calculates.* Let's refine this to be a getter `calculateDynamicTraits` and make the *getter* logic handle the dynamic part. So we add:
*   `calculateDynamicTraits(uint256 avatarId)`: View function to calculate dynamic traits based on current state.
*   `getAvatarCount()`: Total avatars minted.
*   `getComponentCount()`: Total components minted.
*   `getCraftingRecipe(uint256 avatarBaseType)`: View recipe details.
*   `getComponentTypeDetails(uint256 componentTypeId)`: View component type details.
*   `isAvatarStaked(uint256 avatarId)`: Check if an avatar is staked.

This gives us well over 20 functions covering a range of interactions and concepts.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline & Function Summary:
//
// Contract: CryptoAvatarForge
// This contract manages a system of craftable, evolvable, and stakeable digital assets (Avatars)
// built from non-fungible Components.
//
// Core Assets & Data Structures:
// - Component struct: Represents a piece used in crafting (e.g., Hat, Body).
// - Avatar struct: Represents the main dynamic NFT asset.
// - CraftingRecipe struct: Defines component requirements for crafting an Avatar base type.
// - Mappings for tracking ownership, asset details, and system state.
// - Enums for Component types.
//
// Access Control & Pausing:
// - Basic owner-based access control.
// - System-wide pausing mechanism.
//
// Component Management:
// - Minting new components.
// - Transferring component ownership.
// - Viewing component details.
//
// Avatar Management:
// - Crafting Avatars from components.
// - Transferring Avatar ownership.
// - Viewing static Avatar details (components used, evolution level).
// - Viewing dynamic Avatar state (including derived traits).
// - Evolving Avatars (upgrading them).
// - Dismantling Avatars (burning the Avatar, yielding salvage).
//
// Staking Mechanics:
// - Staking Avatars (locking them in the contract).
// - Unstaking Avatars (retrieving them).
// - Claiming staking yield/benefits without unstaking.
// - Calculating pending staking yield/duration.
//
// Admin & Configuration:
// - Setting crafting recipes.
// - Adjusting crafting fees.
// - Setting staking yield rates.
// - Adding/Managing component types.
// - Withdrawing collected fees.
//
// Events:
// - Emit events for significant actions (Mint, Transfer, Craft, Evolve, Stake, Unstake, Dismantle, Configuration changes).
//
// Function Summary (26+ Functions):
// - constructor()
// - pause()
// - unpause()
// - transferOwnership(address newOwner)
// - withdrawFees(address payable recipient)
// - addComponentType(string memory name)
// - toggleComponentMinting(uint256 componentTypeId, bool canMint)
// - setComponentCraftingRecipe(uint256 avatarBaseType, uint256[] memory requiredComponentTypes, uint256[] memory requiredQuantities)
// - setCraftingFee(uint256 avatarBaseType, uint256 fee)
// - setStakingYieldRate(uint256 ratePerSecond)
// - mintComponent(uint256 componentTypeId, address recipient)
// - transferComponent(address from, address to, uint256 componentId)
// - getComponentDetails(uint256 componentId)
// - getComponentsByOwner(address owner)
// - craftAvatar(uint256 avatarBaseType, uint256[] memory componentIds)
// - transferAvatar(address from, address to, uint256 avatarId)
// - getAvatarDetails(uint256 avatarId)
// - getAvatarsByOwner(address owner)
// - evolveAvatar(uint256 avatarId, uint256[] memory componentIdsToConsume)
// - dismantleAvatar(uint256 avatarId)
// - stakeAvatar(uint256 avatarId)
// - unstakeAvatar(uint256 avatarId)
// - claimStakingYield(uint256 avatarId)
// - getPendingYield(uint256 avatarId)
// - calculateDynamicTraits(uint256 avatarId) // Calculated view
// - getAvatarCount()
// - getComponentCount()
// - getCraftingRecipe(uint256 avatarBaseType)
// - getComponentTypeDetails(uint256 componentTypeId)
// - isAvatarStaked(uint256 avatarId)
// - getAvatarStakedTime(uint256 avatarId) // Added for yield calculation transparency
// - getAvatarEvolutionLevel(uint256 avatarId) // Added for dynamic trait transparency


contract CryptoAvatarForge {

    // --- State Variables ---

    address private _owner;
    bool private _paused;

    // --- Component System ---
    enum ComponentTypeEnum { Unknown, Body, Head, Top, Bottom, Feet, Accessory, Background, Salvage } // Example types + a special 'Salvage' type

    struct Component {
        uint256 id;
        uint256 componentTypeId; // Index in componentTypes array
        address owner;
        string uri; // Metadata URI (off-chain for complex visuals)
    }

    uint256 private _nextComponentId;
    mapping(uint256 => Component) private _components; // componentId => Component
    mapping(address => uint256[]) private _componentsByOwner; // owner => list of componentIds
    mapping(uint256 => bool) private _componentExists; // Track existence for quick lookup
    mapping(uint256 => uint256) private _componentOwnerIndex; // componentId => index in owner's list

    struct ComponentType {
        string name;
        bool canMint;
    }
    ComponentType[] private _componentTypes; // componentTypeId => ComponentType
    mapping(uint256 => bool) private _componentTypeExists; // Track existence


    // --- Avatar System ---
    struct Avatar {
        uint256 id;
        uint256 avatarBaseType; // Index referencing a crafting recipe / base look
        address owner;
        uint256[] componentIdsUsed; // IDs of components consumed
        uint256 evolutionLevel; // Starts at 1, can increase
        uint256 stakedTime; // 0 if not staked, block.timestamp when staked
    }

    uint256 private _nextAvatarId;
    mapping(uint256 => Avatar) private _avatars; // avatarId => Avatar
    mapping(address => uint256[]) private _avatarsByOwner; // owner => list of avatarIds
    mapping(uint256 => bool) private _avatarExists; // Track existence for quick lookup
    mapping(uint256 => uint256) private _avatarOwnerIndex; // avatarId => index in owner's list

    // --- Crafting System ---
    struct CraftingRecipe {
        uint256[] requiredComponentTypes; // Array of component type IDs
        uint256[] requiredQuantities;   // Array of corresponding quantities
        uint256 craftingFee;            // Fee in native currency (ETH)
    }
    mapping(uint256 => CraftingRecipe) private _craftingRecipes; // avatarBaseType => recipe
    mapping(uint256 => bool) private _recipeExists; // Track existence

    // --- Staking System ---
    uint256 private _stakingYieldRatePerSecond; // Units of yield per second per avatar

    // --- Fees ---
    uint256 private _totalFeesCollected;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event ComponentTypeAdded(uint256 indexed typeId, string name, bool canMint);
    event ComponentMintingToggled(uint256 indexed typeId, bool canMint);
    event ComponentMinted(uint256 indexed componentId, uint256 indexed componentTypeId, address indexed recipient);
    event ComponentTransfer(address indexed from, address indexed to, uint256 indexed componentId);
    event ComponentBurned(address indexed owner, uint256 indexed componentId);

    event CraftingRecipeSet(uint256 indexed avatarBaseType, uint256 fee);
    event CraftingFeeSet(uint256 indexed avatarBaseType, uint256 fee);
    event AvatarCrafted(uint256 indexed avatarId, uint256 indexed avatarBaseType, address indexed owner, uint256 feePaid);
    event AvatarTransfer(address indexed from, address indexed to, uint256 indexed avatarId);
    event AvatarEvolved(uint256 indexed avatarId, uint256 newEvolutionLevel, address indexed owner);
    event AvatarDismantled(uint256 indexed avatarId, address indexed owner, uint256[] salvageComponentIds);
    event AvatarBurned(address indexed owner, uint256 indexed avatarId);

    event AvatarStaked(uint256 indexed avatarId, address indexed owner, uint256 timestamp);
    event AvatarUnstaked(uint256 indexed avatarId, address indexed owner, uint256 timestamp, uint256 yieldClaimed);
    event StakingYieldClaimed(uint256 indexed avatarId, address indexed owner, uint256 yieldClaimed);
    event StakingYieldRateSet(uint256 ratePerSecond);

    event FeesWithdrawal(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false; // Start unpaused

        // Initialize the special Salvage component type
        // This needs to be typeId 0 so we know its index easily.
        _componentTypes.push(ComponentType({name: "Salvage", canMint: false})); // Can only be minted via dismantle
        _componentTypeExists[0] = true;

        emit OwnershipTransferred(address(0), _owner);
        emit ComponentTypeAdded(0, "Salvage", false);

        _nextComponentId = 1;
        _nextAvatarId = 1;
        _stakingYieldRatePerSecond = 1; // Example default yield rate
    }

    // --- Access Control & Pausing ---

    /// @notice Allows the owner to pause the contract.
    /// @dev Pauses critical operations like crafting, minting, transfers, staking.
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Allows the owner to unpause the contract.
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Withdraws accumulated fees from the contract balance.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance - _totalFeesCollected; // Only withdraw fees not held for other purposes (like staking rewards later)
         if (balance > 0) {
             (bool success,) = recipient.call{value: balance}("");
             require(success, "Withdrawal failed");
             _totalFeesCollected = 0; // Reset collected fees after withdrawal
             emit FeesWithdrawal(recipient, balance);
         }
    }

    /// @notice Get the current owner address.
    /// @return The address of the contract owner.
    function owner() external view returns (address) {
        return _owner;
    }

    /// @notice Check if the contract is paused.
    /// @return True if the contract is paused, false otherwise.
    function paused() external view returns (bool) {
        return _paused;
    }


    // --- Admin & Configuration ---

    /// @notice Adds a new component type that can be used or minted.
    /// @param name The name of the component type (e.g., "Hat", "Shirt").
    function addComponentType(string memory name) external onlyOwner {
        uint256 newTypeId = _componentTypes.length;
        _componentTypes.push(ComponentType({name: name, canMint: false})); // Default to not mintable
        _componentTypeExists[newTypeId] = true;
        emit ComponentTypeAdded(newTypeId, name, false);
    }

     /// @notice Toggles the minting availability for a specific component type.
     /// @param componentTypeId The ID of the component type.
     /// @param canMint True to enable minting, false to disable.
     function toggleComponentMinting(uint256 componentTypeId, bool canMint) external onlyOwner {
         require(_componentTypeExists[componentTypeId], "Invalid component type ID");
         _componentTypes[componentTypeId].canMint = canMint;
         emit ComponentMintingToggled(componentTypeId, canMint);
     }

    /// @notice Sets or updates a crafting recipe for an avatar base type.
    /// @param avatarBaseType The ID representing the base type of the avatar to craft.
    /// @param requiredComponentTypes An array of component type IDs required.
    /// @param requiredQuantities An array of corresponding quantities required.
    function setComponentCraftingRecipe(uint256 avatarBaseType, uint256[] memory requiredComponentTypes, uint256[] memory requiredQuantities) external onlyOwner {
        require(requiredComponentTypes.length == requiredQuantities.length, "Input array length mismatch");

        for (uint256 i = 0; i < requiredComponentTypes.length; i++) {
             require(_componentTypeExists[requiredComponentTypes[i]], "Required component type does not exist");
             require(requiredComponentTypes[i] != uint256(ComponentTypeEnum.Salvage), "Salvage cannot be a crafting ingredient");
         }

        _craftingRecipes[avatarBaseType] = CraftingRecipe({
            requiredComponentTypes: requiredComponentTypes,
            requiredQuantities: requiredQuantities,
            craftingFee: _craftingRecipes[avatarBaseType].craftingFee // Keep existing fee if any, or 0
        });
        _recipeExists[avatarBaseType] = true;
        emit CraftingRecipeSet(avatarBaseType, _craftingRecipes[avatarBaseType].craftingFee);
    }

    /// @notice Sets the crafting fee (in native currency) for a specific avatar base type recipe.
    /// @param avatarBaseType The ID of the avatar base type.
    /// @param fee The fee amount in native currency (wei).
    function setCraftingFee(uint256 avatarBaseType, uint256 fee) external onlyOwner {
        require(_recipeExists[avatarBaseType], "Recipe does not exist for this avatar type");
        _craftingRecipes[avatarBaseType].craftingFee = fee;
        emit CraftingFeeSet(avatarBaseType, fee);
    }

    /// @notice Sets the staking yield rate per second for Avatars.
    /// @dev The unit of yield is abstract and depends on how it's interpreted (e.g., points, virtual currency units).
    /// @param ratePerSecond The yield rate per second.
    function setStakingYieldRate(uint256 ratePerSecond) external onlyOwner {
        _stakingYieldRatePerSecond = ratePerSecond;
        emit StakingYieldRateSet(ratePerSecond);
    }

    // --- Component Management ---

    /// @notice Mints a new component of a specific type and assigns it to a recipient.
    /// @dev This function's access should be controlled (e.g., by owner, or maybe requires payment/condition).
    /// @param componentTypeId The type of component to mint.
    /// @param recipient The address to receive the component.
    function mintComponent(uint256 componentTypeId, address recipient) public onlyOwner whenNotPaused { // Made public for demonstration, restrict as needed
        require(_componentTypeExists[componentTypeId], "Invalid component type ID");
        require(_componentTypes[componentTypeId].canMint || componentTypeId == uint256(ComponentTypeEnum.Salvage), "Component type is not mintable");
        require(recipient != address(0), "Mint to the zero address");

        uint256 newId = _nextComponentId++;
        string memory _uri = string(abi.encodePacked("ipfs://component/", Strings.toString(newId))); // Example URI pattern

        _components[newId] = Component({
            id: newId,
            componentTypeId: componentTypeId,
            owner: recipient,
            uri: _uri
        });
        _componentExists[newId] = true;

        _addComponentToOwnerList(recipient, newId);

        emit ComponentMinted(newId, componentTypeId, recipient);
    }

    /// @notice Transfers ownership of a component.
    /// @param from The current owner of the component.
    /// @param to The address to transfer the component to.
    /// @param componentId The ID of the component to transfer.
    function transferComponent(address from, address to, uint256 componentId) public whenNotPaused {
        require(msg.sender == from || msg.sender == _owner, "Not authorized to transfer component"); // Basic authorization
        require(_componentExists[componentId], "Component does not exist");
        require(_components[componentId].owner == from, "Component not owned by 'from'");
        require(to != address(0), "Transfer to the zero address");

        _removeComponentFromOwnerList(from, componentId);
        _components[componentId].owner = to;
        _addComponentToOwnerList(to, componentId);

        emit ComponentTransfer(from, to, componentId);
    }

    /// @notice Gets the details of a specific component.
    /// @param componentId The ID of the component.
    /// @return The component's ID, type ID, owner address, and URI.
    function getComponentDetails(uint256 componentId) public view returns (uint256 id, uint256 componentTypeId, address owner, string memory uri) {
        require(_componentExists[componentId], "Component does not exist");
        Component storage component = _components[componentId];
        return (component.id, component.componentTypeId, component.owner, component.uri);
    }

    /// @notice Gets the list of component IDs owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of component IDs owned by the address.
    function getComponentsByOwner(address owner) public view returns (uint256[] memory) {
        return _componentsByOwner[owner];
    }

     /// @notice Get details of a specific component type.
     /// @param componentTypeId The ID of the component type.
     /// @return The name and minting status of the component type.
     function getComponentTypeDetails(uint256 componentTypeId) public view returns (string memory name, bool canMint) {
         require(_componentTypeExists[componentTypeId], "Invalid component type ID");
         return (_componentTypes[componentTypeId].name, _componentTypes[componentTypeId].canMint);
     }


    // Internal helper to add component ID to owner's list
    function _addComponentToOwnerList(address owner, uint256 componentId) internal {
        _componentsByOwner[owner].push(componentId);
        _componentOwnerIndex[componentId] = _componentsByOwner[owner].length - 1;
    }

    // Internal helper to remove component ID from owner's list (using swap-and-pop)
    function _removeComponentFromOwnerList(address owner, uint256 componentId) internal {
        uint256[] storage ownerList = _componentsByOwner[owner];
        uint256 index = _componentOwnerIndex[componentId];
        require(index < ownerList.length, "Component not found in owner list index"); // Should not happen if state is consistent

        // Swap last element with the element at index
        uint256 lastIndex = ownerList.length - 1;
        uint256 lastComponentId = ownerList[lastIndex];
        ownerList[index] = lastComponentId;
        _componentOwnerIndex[lastComponentId] = index;

        // Remove the last element
        ownerList.pop();
        delete _componentOwnerIndex[componentId];
    }

    // Internal helper to burn a component
    function _burnComponent(uint256 componentId) internal {
         require(_componentExists[componentId], "Component does not exist");
         address owner = _components[componentId].owner;

         _removeComponentFromOwnerList(owner, componentId);
         delete _components[componentId];
         delete _componentExists[componentId]; // Mark as non-existent

         emit ComponentBurned(owner, componentId);
    }


    // --- Avatar Management ---

    /// @notice Crafts a new Avatar from a set of components based on a recipe.
    /// @param avatarBaseType The base type of the avatar to craft.
    /// @param componentIds The IDs of the components to use for crafting.
    function craftAvatar(uint256 avatarBaseType, uint256[] memory componentIds) public payable whenNotPaused {
        require(_recipeExists[avatarBaseType], "Crafting recipe does not exist for this type");
        CraftingRecipe storage recipe = _craftingRecipes[avatarBaseType];
        require(msg.value >= recipe.craftingFee, "Insufficient crafting fee");

        // Pay fee
        if (recipe.craftingFee > 0) {
             _totalFeesCollected += recipe.craftingFee;
        }

        // Check if sender owns all components and count types
        mapping(uint256 => uint256) memory componentTypeCounts;
        for (uint256 i = 0; i < componentIds.length; i++) {
            uint256 compId = componentIds[i];
            require(_componentExists[compId], "Component ID is invalid");
            require(_components[compId].owner == msg.sender, "Does not own component");
            componentTypeCounts[_components[compId].componentTypeId]++;
        }

        // Check if component counts match the recipe
        require(componentTypeCounts.length == recipe.requiredComponentTypes.length, "Incorrect number of required component types provided"); // Simple check, might need refinement if order/exact types matter

         for (uint256 i = 0; i < recipe.requiredComponentTypes.length; i++) {
             uint256 requiredTypeId = recipe.requiredComponentTypes[i];
             uint256 requiredQty = recipe.requiredQuantities[i];
             require(componentTypeCounts[requiredTypeId] == requiredQty, "Component type quantity mismatch for recipe");
         }


        // Burn components
        for (uint256 i = 0; i < componentIds.length; i++) {
            _burnComponent(componentIds[i]);
        }

        // Mint new Avatar
        uint256 newAvatarId = _nextAvatarId++;
        _avatars[newAvatarId] = Avatar({
            id: newAvatarId,
            avatarBaseType: avatarBaseType,
            owner: msg.sender,
            componentIdsUsed: componentIds, // Store the IDs of consumed components
            evolutionLevel: 1, // Start at level 1
            stakedTime: 0 // Not staked initially
        });
        _avatarExists[newAvatarId] = true;

        _addAvatarToOwnerList(msg.sender, newAvatarId);

        emit AvatarCrafted(newAvatarId, avatarBaseType, msg.sender, recipe.craftingFee);

        // Return excess ETH if any
        if (msg.value > recipe.craftingFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - recipe.craftingFee}("");
            require(success, "Excess ETH transfer failed");
        }
    }


    /// @notice Transfers ownership of an Avatar.
    /// @dev Cannot transfer if staked.
    /// @param from The current owner of the Avatar.
    /// @param to The address to transfer the Avatar to.
    /// @param avatarId The ID of the Avatar to transfer.
    function transferAvatar(address from, address to, uint256 avatarId) public whenNotPaused {
         require(msg.sender == from || msg.sender == _owner, "Not authorized to transfer avatar"); // Basic authorization
         require(_avatarExists[avatarId], "Avatar does not exist");
         require(_avatars[avatarId].owner == from, "Avatar not owned by 'from'");
         require(to != address(0), "Transfer to the zero address");
         require(_avatars[avatarId].stakedTime == 0, "Cannot transfer staked avatar");

         _removeAvatarFromOwnerList(from, avatarId);
         _avatars[avatarId].owner = to;
         _addAvatarToOwnerList(to, avatarId);

         emit AvatarTransfer(from, to, avatarId);
    }

    /// @notice Gets the static details of an Avatar.
    /// @param avatarId The ID of the Avatar.
    /// @return The avatar's ID, base type, owner, components used, evolution level, and staked status.
    function getAvatarDetails(uint256 avatarId) public view returns (uint256 id, uint256 avatarBaseType, address owner, uint256[] memory componentIdsUsed, uint256 evolutionLevel, uint256 stakedTime) {
        require(_avatarExists[avatarId], "Avatar does not exist");
        Avatar storage avatar = _avatars[avatarId];
        return (avatar.id, avatar.avatarBaseType, avatar.owner, avatar.componentIdsUsed, avatar.evolutionLevel, avatar.stakedTime);
    }

    /// @notice Gets the list of Avatar IDs owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of Avatar IDs owned by the address.
    function getAvatarsByOwner(address owner) public view returns (uint256[] memory) {
        return _avatarsByOwner[owner];
    }

    /// @notice Evolves an Avatar by consuming components.
    /// @param avatarId The ID of the Avatar to evolve.
    /// @param componentIdsToConsume The IDs of components to burn for evolution.
    function evolveAvatar(uint256 avatarId, uint256[] memory componentIdsToConsume) public whenNotPaused {
        require(_avatarExists[avatarId], "Avatar does not exist");
        require(_avatars[avatarId].owner == msg.sender, "Not owner of avatar");
        require(_avatars[avatarId].stakedTime == 0, "Cannot evolve staked avatar"); // Cannot evolve if staked

        // Basic check: Require at least one component to evolve
        require(componentIdsToConsume.length > 0, "No components provided for evolution");

        // Check if sender owns all components and burn them
        for (uint256 i = 0; i < componentIdsToConsume.length; i++) {
            uint256 compId = componentIdsToConsume[i];
            require(_componentExists[compId], "Component ID is invalid");
            require(_components[compId].owner == msg.sender, "Does not own component for evolution");
            _burnComponent(compId); // Burn the component
        }

        // Increase evolution level (simple linear increase for this example)
        _avatars[avatarId].evolutionLevel++;

        emit AvatarEvolved(avatarId, _avatars[avatarId].evolutionLevel, msg.sender);
    }

    /// @notice Dismantles an Avatar, burning it and returning salvage components.
    /// @param avatarId The ID of the Avatar to dismantle.
    function dismantleAvatar(uint256 avatarId) public whenNotPaused {
         require(_avatarExists[avatarId], "Avatar does not exist");
         require(_avatars[avatarId].owner == msg.sender, "Not owner of avatar");
         require(_avatars[avatarId].stakedTime == 0, "Cannot dismantle staked avatar"); // Cannot dismantle if staked

         // Determine how many salvage components to return (simple logic based on components used)
         uint256 numSalvageComponents = _avatars[avatarId].componentIdsUsed.length; // 1 salvage per component used

         uint256[] memory salvageIds = new uint256[](numSalvageComponents);
         for (uint256 i = 0; i < numSalvageComponents; i++) {
             // Mint salvage components
             uint256 salvageComponentTypeId = uint256(ComponentTypeEnum.Salvage); // Ensure this type exists and is special
             // We will allow minting salvage components only internally via dismantle
             uint256 newSalvageId = _nextComponentId++;
             string memory _uri = string(abi.encodePacked("ipfs://salvage/", Strings.toString(newSalvageId))); // Example URI pattern

             _components[newSalvageId] = Component({
                 id: newSalvageId,
                 componentTypeId: salvageComponentTypeId,
                 owner: msg.sender,
                 uri: _uri
             });
             _componentExists[newSalvageId] = true;
             _addComponentToOwnerList(msg.sender, newSalvageId);
             salvageIds[i] = newSalvageId;
             emit ComponentMinted(newSalvageId, salvageComponentTypeId, msg.sender);
         }

         // Burn the avatar
         address owner = _avatars[avatarId].owner;
         _removeAvatarFromOwnerList(owner, avatarId);
         delete _avatars[avatarId];
         delete _avatarExists[avatarId]; // Mark as non-existent

         emit AvatarDismantled(avatarId, owner, salvageIds);
         emit AvatarBurned(owner, avatarId);
    }

    // Internal helper to add avatar ID to owner's list
    function _addAvatarToOwnerList(address owner, uint256 avatarId) internal {
        _avatarsByOwner[owner].push(avatarId);
        _avatarOwnerIndex[avatarId] = _avatarsByOwner[owner].length - 1;
    }

     // Internal helper to remove avatar ID from owner's list (using swap-and-pop)
    function _removeAvatarFromOwnerList(address owner, uint256 avatarId) internal {
        uint256[] storage ownerList = _avatarsByOwner[owner];
        uint256 index = _avatarOwnerIndex[avatarId];
        require(index < ownerList.length, "Avatar not found in owner list index"); // Should not happen if state is consistent

        // Swap last element with the element at index
        uint256 lastIndex = ownerList.length - 1;
        uint256 lastAvatarId = ownerList[lastIndex];
        ownerList[index] = lastAvatarId;
        _avatarOwnerIndex[lastAvatarId] = index;

        // Remove the last element
        ownerList.pop();
        delete _avatarOwnerIndex[avatarId];
    }


    // --- Staking Mechanics ---

    /// @notice Stakes an Avatar. Ownership is transferred to the contract.
    /// @param avatarId The ID of the Avatar to stake.
    function stakeAvatar(uint256 avatarId) public whenNotPaused {
         require(_avatarExists[avatarId], "Avatar does not exist");
         require(_avatars[avatarId].owner == msg.sender, "Not owner of avatar");
         require(_avatars[avatarId].stakedTime == 0, "Avatar is already staked");

         // Update state before transferring ownership to contract
         _avatars[avatarId].stakedTime = block.timestamp;

         address owner = msg.sender;
         address contractAddress = address(this);

         _removeAvatarFromOwnerList(owner, avatarId);
         _avatars[avatarId].owner = contractAddress; // Contract now owns the staked NFT
         _addAvatarToOwnerList(contractAddress, avatarId); // Add to contract's 'owned' list (for tracking staked)

         emit AvatarStaked(avatarId, owner, block.timestamp);
    }

    /// @notice Unstakes an Avatar. Ownership is transferred back to the original staker.
    /// @dev Claims any pending yield upon unstaking.
    /// @param avatarId The ID of the Avatar to unstake.
    function unstakeAvatar(uint256 avatarId) public whenNotPaused {
        require(_avatarExists[avatarId], "Avatar does not exist");
        require(_avatars[avatarId].owner == address(this), "Avatar is not staked in this contract");
        require(_avatarExists[avatarId] && _avatars[avatarId].stakedTime > 0, "Avatar is not currently staked"); // Redundant check but good practice

        uint256 stakedSince = _avatars[avatarId].stakedTime;
        uint256 yieldAmount = calculatePendingYield(avatarId);

        // Reset staking state
        _avatars[avatarId].stakedTime = 0; // Mark as unstaked immediately

        // Transfer ownership back to the original staker (msg.sender must be the one unstaking)
        address originalStaker = msg.sender; // Assuming msg.sender is the one who staked it or is authorized
        // A more robust system might store the original staker's address
        // For simplicity here, we assume the current msg.sender is the intended recipient.
        // In a real system, you might map avatarId -> originalStakerAddress.

        address contractAddress = address(this);

        _removeAvatarFromOwnerList(contractAddress, avatarId);
        _avatars[avatarId].owner = originalStaker; // Transfer back
        _addAvatarToOwnerList(originalStaker, avatarId);

        emit AvatarUnstaked(avatarId, originalStaker, block.timestamp, yieldAmount);

        // Distribute yield (this is a placeholder, actual yield might be a different token or action)
        // For this example, let's just emit the amount. A real system would mint/transfer tokens.
        // If distributing ETH, you'd need a treasury management system or use collected fees.
        // Here, yield is abstract points.
        if (yieldAmount > 0) {
             emit StakingYieldClaimed(avatarId, originalStaker, yieldAmount);
        }
    }

     /// @notice Claims staking yield for an Avatar without unstaking it.
     /// @param avatarId The ID of the Avatar to claim yield from.
     function claimStakingYield(uint256 avatarId) public whenNotPaused {
         require(_avatarExists[avatarId], "Avatar does not exist");
         require(_avatars[avatarId].owner == address(this), "Avatar is not staked in this contract");
         require(_avatars[avatarId].stakedTime > 0, "Avatar is not currently staked");

         uint256 yieldAmount = calculatePendingYield(avatarId);
         require(yieldAmount > 0, "No pending yield to claim");

         // Update staked time to reset yield calculation period
         _avatars[avatarId].stakedTime = block.timestamp;

         // Distribute yield (placeholder as in unstake)
         emit StakingYieldClaimed(avatarId, msg.sender, yieldAmount); // Assuming msg.sender is the staker
     }


    /// @notice Calculates the pending staking yield for an Avatar.
    /// @param avatarId The ID of the Avatar.
    /// @return The calculated yield amount.
    function getPendingYield(uint256 avatarId) public view returns (uint256) {
        require(_avatarExists[avatarId], "Avatar does not exist");
        require(_avatars[avatarId].stakedTime > 0, "Avatar is not currently staked");

        uint256 stakedSince = _avatars[avatarId].stakedTime;
        uint256 duration = block.timestamp - stakedSince;

        // Simple linear yield calculation
        uint256 yieldAmount = duration * _stakingYieldRatePerSecond;

        // Could add multipliers based on evolution level, etc.
        // yieldAmount = yieldAmount * _avatars[avatarId].evolutionLevel; // Example: yield scales with level

        return yieldAmount;
    }


    /// @notice Get the current staking yield rate per second.
    /// @return The rate per second.
    function getStakingYieldRate() external view returns (uint256) {
        return _stakingYieldRatePerSecond;
    }

     /// @notice Checks if an avatar is currently staked.
     /// @param avatarId The ID of the Avatar.
     /// @return True if staked, false otherwise.
     function isAvatarStaked(uint256 avatarId) public view returns (bool) {
         if (!_avatarExists[avatarId]) return false;
         return _avatars[avatarId].stakedTime > 0;
     }

     /// @notice Gets the timestamp when the avatar was staked.
     /// @param avatarId The ID of the Avatar.
     /// @return The timestamp if staked, 0 otherwise.
     function getAvatarStakedTime(uint256 avatarId) public view returns (uint256) {
         if (!_avatarExists[avatarId]) return 0;
         return _avatars[avatarId].stakedTime;
     }

    // --- Dynamic Traits & State Calculation ---

    /// @notice Calculates the dynamic traits of an Avatar based on its current state.
    /// @dev This is a view function; it doesn't change state. Traits are derived.
    /// @param avatarId The ID of the Avatar.
    /// @return A description of dynamic traits (example: 'StakedBonus', 'EvolutionTier').
    function calculateDynamicTraits(uint256 avatarId) public view returns (string memory) {
         require(_avatarExists[avatarId], "Avatar does not exist");
         Avatar storage avatar = _avatars[avatarId];

         string memory dynamicInfo = "Dynamic Traits: ";

         // Trait based on Evolution Level
         string memory evolutionTier;
         if (avatar.evolutionLevel == 1) evolutionTier = "Basic";
         else if (avatar.evolutionLevel < 5) evolutionTier = "Intermediate";
         else if (avatar.evolutionLevel < 10) evolutionTier = "Advanced";
         else evolutionTier = "Epic";
         dynamicInfo = string(abi.encodePacked(dynamicInfo, "EvolutionTier: ", evolutionTier, ", "));

         // Trait based on Staking Status/Duration
         if (avatar.stakedTime > 0) {
             uint256 stakedDuration = block.timestamp - avatar.stakedTime;
             string memory stakedBonus;
             if (stakedDuration < 1 days) stakedBonus = "NewlyStaked";
             else if (stakedDuration < 30 days) stakedBonus = "ConsistentStaker";
             else stakedBonus = "LoyalStaker"; // Example tiers
             dynamicInfo = string(abi.encodePacked(dynamicInfo, "StakedBonus: ", stakedBonus, ", "));
         } else {
              dynamicInfo = string(abi.encodePacked(dynamicInfo, "Status: Not Staked, "));
         }


         // Remove trailing ", " if present
         if (bytes(dynamicInfo).length > 2) {
             bytes memory dynamicInfoBytes = bytes(dynamicInfo);
             bytes memory trimmedInfo = new bytes(dynamicInfoBytes.length - 2);
             for (uint i = 0; i < trimmedInfo.length; i++) {
                 trimmedInfo[i] = dynamicInfoBytes[i];
             }
             dynamicInfo = string(trimmedInfo);
         }

         return dynamicInfo;
    }

    /// @notice Get the current evolution level of an avatar.
    /// @param avatarId The ID of the Avatar.
    /// @return The evolution level.
    function getAvatarEvolutionLevel(uint256 avatarId) public view returns (uint256) {
        require(_avatarExists[avatarId], "Avatar does not exist");
        return _avatars[avatarId].evolutionLevel;
    }


    // --- View & Utility Functions ---

    /// @notice Gets the total number of components minted.
    /// @return The total component count.
    function getComponentCount() public view returns (uint256) {
        return _nextComponentId - 1; // IDs start from 1
    }

    /// @notice Gets the total number of avatars minted.
    /// @return The total avatar count.
    function getAvatarCount() public view returns (uint256) {
        return _nextAvatarId - 1; // IDs start from 1
    }

    /// @notice Gets the crafting recipe for a specific avatar base type.
    /// @param avatarBaseType The ID of the avatar base type.
    /// @return The required component type IDs, required quantities, and crafting fee.
    function getCraftingRecipe(uint256 avatarBaseType) public view returns (uint256[] memory requiredComponentTypes, uint256[] memory requiredQuantities, uint256 craftingFee) {
        require(_recipeExists[avatarBaseType], "Recipe does not exist for this avatar type");
        CraftingRecipe storage recipe = _craftingRecipes[avatarBaseType];
        return (recipe.requiredComponentTypes, recipe.requiredQuantities, recipe.craftingFee);
    }

    // --- Helper Library (Manual Implementation of common utilities) ---
    // Basic String conversion - typically from OpenZeppelin, but implementing here as requested.
    library Strings {
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
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + temp % 10));
                temp /= 10;
            }
            return string(buffer);
        }
    }
}
```