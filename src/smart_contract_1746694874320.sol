Okay, here is a Solidity smart contract implementing a system for registering mutable digital assets that can be transformed using recipes, fueled by internal resources, and allowing for scoped permissions for third parties to perform transformations.

This design incorporates concepts like:
*   **Mutable Assets:** Unlike standard NFTs, assets have attributes that can change.
*   **Transformation Recipes:** Define rules and outcomes for modifying assets.
*   **Internal Resources:** A simple on-chain resource system used as a cost/requirement for transformations.
*   **Scoped Permissions:** Granting specific users the ability to perform *certain* transformations on *specific* assets for a *limited time* or *number of uses*.
*   **Asset History:** Tracking transformations applied to each asset.
*   **Operator Pattern:** Standard ERC721-like approval for general asset management.

This is designed to be a core logic contract, not necessarily tied to a specific ERC-721 implementation (though it could manage ownership of associated ERC-721 tokens off-chain or in a linked contract). The "assets" here are represented by unique IDs and associated state within this contract.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TransformableAssetVault
 * @dev A contract for managing mutable digital assets, transformation recipes,
 *      internal resources, and scoped permissions for transformations.
 *      Assets are represented by unique IDs and associated attributes/metadata.
 *      Transformations modify asset attributes and consume resources.
 *      Users can grant granular, time-limited, or use-limited permissions
 *      to others to perform specific transformations on their assets.
 */
contract TransformableAssetVault is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _assetIds;
    Counters.Counter private _recipeIds;
    Counters.Counter private _resourceTypes;
    Counters.Counter private _permissionGrantIds;

    // Asset Data: assetId => ...
    mapping(uint256 => address) public assetOwner;
    mapping(uint256 => string) public assetMetadataURI;
    mapping(uint256 => mapping(string => uint256)) public assetAttributes; // attributeKey => value
    mapping(uint256 => address) private _assetApproved; // Single operator approval
    mapping(address => mapping(address => bool)) private _approvedForAll; // Operator approval for all assets

    // Resource Data: user => resourceType => amount
    mapping(address => mapping(uint256 => uint256)) public userResources;
    mapping(uint256 => string) public resourceTypeNames; // resourceType => name

    // Transformation Recipe Data: recipeId => ...
    struct TransformationRequirement {
        uint256 resourceType;       // Required resource type
        uint256 resourceAmount;     // Required resource amount
        string attributeKey;        // Required asset attribute key (optional, leave empty if not needed)
        uint256 attributeMinValue;  // Minimum value for the required attribute
    }

    struct TransformationOutcome {
        string attributeKey;      // Attribute key to change
        int256 attributeChange;   // Amount to change attribute value by (can be negative)
        string newMetadataURI;    // Optional: New metadata URI (empty string to not change)
        bool setNewMetadata;      // Flag to indicate if metadata should be set
    }

    struct TransformationRecipe {
        bool isActive;                      // Is the recipe currently usable?
        TransformationRequirement[] requirements; // List of requirements
        TransformationOutcome[] outcomes;       // List of outcomes
        mapping(uint256 => uint256) cost;       // Resource costs (resourceType => amount)
    }
    mapping(uint256 => TransformationRecipe) public transformationRecipes;

    // Permission Grant Data: grantId => ...
    struct ScopedPermission {
        uint256 grantId;           // Unique ID for this specific grant
        address grantedBy;         // Asset owner who granted permission
        uint256 assetId;           // The asset the permission applies to
        uint256 recipeId;          // The recipe allowed by this permission
        uint256 expiryTimestamp;   // When the permission expires (0 for no expiry)
        uint256 usesRemaining;     // How many times the permission can be used (0 for unlimited)
        bool isValid;              // Is this permission grant currently valid?
    }
    mapping(uint256 => ScopedPermission) public permissionGrants;
    mapping(uint256 => mapping(address => uint256[])) private _assetUserPermissionGrantIds; // assetId => user => list of grantIds

    // History Data: assetId => list of history entries
    struct TransformationHistoryEntry {
        uint256 timestamp;     // When the transformation occurred
        uint256 recipeId;      // The recipe applied
        address performer;     // Address that performed the transformation
        string details;        // Optional details (e.g., summary of changes)
    }
    mapping(uint256 => TransformationHistoryEntry[]) public assetHistory;

    // --- Events ---
    event AssetRegistered(uint256 indexed assetId, address indexed owner, string metadataURI);
    event AssetTransferred(uint256 indexed assetId, address indexed from, address indexed to);
    event AssetBurned(uint256 indexed assetId);
    event AssetMetadataUpdated(uint256 indexed assetId, string newMetadataURI);
    event AssetAttributeUpdated(uint256 indexed assetId, string key, uint256 value);
    event ResourceTypeAdded(uint256 indexed resourceType, string name);
    event UserResourceGranted(address indexed user, uint256 indexed resourceType, uint256 amount);
    event UserResourceConsumed(address indexed user, uint256 indexed resourceType, uint256 amount);
    event TransformationRecipeDefined(uint256 indexed recipeId, bool isActive);
    event TransformationRecipeUpdated(uint256 indexed recipeId);
    event TransformationRecipeStatusToggled(uint256 indexed recipeId, bool isActive);
    event TransformationApplied(uint256 indexed assetId, uint256 indexed recipeId, address performer, uint256 grantId); // grantId 0 if applied by owner
    event ScopedPermissionGranted(uint256 indexed grantId, uint256 indexed assetId, address indexed recipient, uint256 recipeId, uint256 expiryTimestamp, uint256 maxUses);
    event ScopedPermissionConsumed(uint256 indexed grantId, uint256 usesRemaining);
    event ScopedPermissionRevoked(uint256 indexed grantId, address indexed revokedBy);
    event Approval(address indexed owner, address indexed approved, uint256 indexed assetId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) Pausable(false) {}

    // --- Modifiers ---
    modifier onlyAssetOwner(uint256 assetId) {
        require(assetOwner[assetId] == msg.sender, "TV: Caller is not asset owner");
        _;
    }

    modifier onlyAdmin() {
        // In this simple example, Owner is the Admin. Could be extended with a separate role.
        require(owner() == msg.sender, "TV: Caller is not admin");
        _;
    }

    modifier assetExists(uint256 assetId) {
        require(assetOwner[assetId] != address(0), "TV: Asset does not exist");
        _;
    }

    modifier recipeExists(uint256 recipeId) {
        require(transformationRecipes[recipeId].requirements.length > 0 || transformationRecipes[recipeId].outcomes.length > 0, "TV: Recipe does not exist"); // Check if recipe struct was initialized
        _;
    }

    // --- Admin Functions ---

    /**
     * @notice Allows the admin to add a new resource type.
     * @param name The name of the new resource type.
     * @return The ID of the new resource type.
     */
    function addResourceType(string memory name) external onlyAdmin whenNotPaused returns (uint256) {
        _resourceTypes.increment();
        uint256 newResourceType = _resourceTypes.current();
        resourceTypeNames[newResourceType] = name;
        emit ResourceTypeAdded(newResourceType, name);
        return newResourceType;
    }

    /**
     * @notice Allows the admin to grant resources to a user.
     * @param user The address to grant resources to.
     * @param resourceType The type of resource to grant.
     * @param amount The amount of resources to grant.
     */
    function grantAdminResource(address user, uint256 resourceType, uint256 amount) external onlyAdmin whenNotPaused {
        require(_resourceTypes.current() >= resourceType && resourceType > 0, "TV: Invalid resource type");
        userResources[user][resourceType] += amount;
        emit UserResourceGranted(user, resourceType, amount);
    }

    /**
     * @notice Allows the admin to set a user's resource amount directly.
     * @param user The address whose resources to set.
     * @param resourceType The type of resource to set.
     * @param amount The new amount of resources.
     */
    function setUserResource(address user, uint256 resourceType, uint256 amount) external onlyAdmin whenNotPaused {
        require(_resourceTypes.current() >= resourceType && resourceType > 0, "TV: Invalid resource type");
        userResources[user][resourceType] = amount;
        // No specific event for setting, grantAdminResource can be used for adding.
        // Could add a specific SetUserResource event if needed.
    }

    /**
     * @notice Allows the admin to set an asset attribute value. Useful for initial setup or corrections.
     * @param assetId The ID of the asset.
     * @param key The attribute key.
     * @param value The value to set for the attribute.
     */
    function setAssetAttribute(uint256 assetId, string memory key, uint256 value) external onlyAdmin whenNotPaused assetExists(assetId) {
        assetAttributes[assetId][key] = value;
        emit AssetAttributeUpdated(assetId, key, value);
    }

    /**
     * @notice Allows the admin to define a new transformation recipe.
     * @param isActive Whether the recipe should be active immediately.
     * @param requirements List of requirements for the recipe.
     * @param outcomes List of outcomes when the recipe is applied.
     * @param costResourceTypes Array of resource types for the cost.
     * @param costAmounts Array of amounts corresponding to costResourceTypes.
     * @return The ID of the new recipe.
     */
    function defineTransformationRecipe(
        bool isActive,
        TransformationRequirement[] memory requirements,
        TransformationOutcome[] memory outcomes,
        uint256[] memory costResourceTypes,
        uint256[] memory costAmounts
    ) external onlyAdmin whenNotPaused returns (uint256) {
        require(costResourceTypes.length == costAmounts.length, "TV: Cost type and amount arrays must match");

        _recipeIds.increment();
        uint256 newRecipeId = _recipeIds.current();
        TransformationRecipe storage recipe = transformationRecipes[newRecipeId];
        recipe.isActive = isActive;
        recipe.requirements = requirements;
        recipe.outcomes = outcomes;

        for (uint i = 0; i < costResourceTypes.length; i++) {
            require(_resourceTypes.current() >= costResourceTypes[i] && costResourceTypes[i] > 0, "TV: Invalid cost resource type");
            recipe.cost[costResourceTypes[i]] = costAmounts[i];
        }

        emit TransformationRecipeDefined(newRecipeId, isActive);
        return newRecipeId;
    }

    /**
     * @notice Allows the admin to update an existing transformation recipe.
     * @param recipeId The ID of the recipe to update.
     * @param requirements New list of requirements.
     * @param outcomes New list of outcomes.
     * @param costResourceTypes Array of resource types for the new cost.
     * @param costAmounts Array of amounts corresponding to new costResourceTypes.
     */
    function updateTransformationRecipe(
        uint256 recipeId,
        TransformationRequirement[] memory requirements,
        TransformationOutcome[] memory outcomes,
        uint256[] memory costResourceTypes,
        uint256[] memory costAmounts
    ) external onlyAdmin whenNotPaused recipeExists(recipeId) {
        require(costResourceTypes.length == costAmounts.length, "TV: Cost type and amount arrays must match");

        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        recipe.requirements = requirements;
        recipe.outcomes = outcomes;

        // Clear existing costs before setting new ones
        for (uint i = 0; i < _resourceTypes.current(); i++) {
             recipe.cost[i + 1] = 0; // Assuming resourceType starts from 1
        }
         for (uint i = 0; i < costResourceTypes.length; i++) {
            require(_resourceTypes.current() >= costResourceTypes[i] && costResourceTypes[i] > 0, "TV: Invalid cost resource type in update");
            recipe.cost[costResourceTypes[i]] = costAmounts[i];
        }


        emit TransformationRecipeUpdated(recipeId);
    }

    /**
     * @notice Allows the admin to toggle the active status of a transformation recipe.
     * @param recipeId The ID of the recipe.
     * @param isActive The new active status.
     */
    function toggleRecipeActiveStatus(uint256 recipeId, bool isActive) external onlyAdmin whenNotPaused recipeExists(recipeId) {
        transformationRecipes[recipeId].isActive = isActive;
        emit TransformationRecipeStatusToggled(recipeId, isActive);
    }

    // --- User / Asset Owner Functions ---

    /**
     * @notice Registers a new asset owned by the caller.
     * @param metadataURI The initial metadata URI for the asset.
     * @return The ID of the newly registered asset.
     */
    function registerAsset(string memory metadataURI) external whenNotPaused returns (uint256) {
        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();
        assetOwner[newAssetId] = msg.sender;
        assetMetadataURI[newAssetId] = metadataURI;
        emit AssetRegistered(newAssetId, msg.sender, metadataURI);
        return newAssetId;
    }

    /**
     * @notice Transfers ownership of an asset to another address.
     * @param assetId The ID of the asset to transfer.
     * @param newOwner The address to transfer ownership to.
     */
    function transferAssetOwnership(uint256 assetId, address newOwner) external whenNotPaused assetExists(assetId) onlyAssetOwner(assetId) {
        require(newOwner != address(0), "TV: New owner is the zero address");
        address oldOwner = assetOwner[assetId];
        assetOwner[assetId] = newOwner;
        _assetApproved[assetId] = address(0); // Clear single approval on transfer
        emit AssetTransferred(assetId, oldOwner, newOwner);
    }

    /**
     * @notice Allows the asset owner to burn their asset.
     * @param assetId The ID of the asset to burn.
     */
    function burnAsset(uint256 assetId) external whenNotPaused assetExists(assetId) onlyAssetOwner(assetId) {
        delete assetOwner[assetId];
        delete assetMetadataURI[assetId];
        // Attributes and History remain associated with the ID but the asset is no longer owned
        // Could clear attributes/history too if desired, but keeping them indexed by ID might be useful.
        delete _assetApproved[assetId];
        // Note: approvedForAll status remains unaffected, must be revoked separately.
        emit AssetBurned(assetId);
    }


    /**
     * @notice Allows the asset owner to update their asset's metadata URI.
     * @param assetId The ID of the asset.
     * @param newURI The new metadata URI.
     */
    function updateAssetMetadataURI(uint256 assetId, string memory newURI) external whenNotPaused assetExists(assetId) onlyAssetOwner(assetId) {
        assetMetadataURI[assetId] = newURI;
        emit AssetMetadataUpdated(assetId, newURI);
    }

    /**
     * @notice Allows the asset owner to grant a scoped permission to another user.
     * @param assetId The ID of the asset.
     * @param recipient The address to grant permission to.
     * @param recipeId The ID of the recipe the recipient is allowed to apply.
     * @param duration The duration of the permission in seconds (0 for no expiry).
     * @param maxUses The maximum number of times the permission can be used (0 for unlimited).
     * @return The ID of the newly created permission grant.
     */
    function grantScopedPermission(
        uint256 assetId,
        address recipient,
        uint256 recipeId,
        uint256 duration,
        uint256 maxUses
    ) external whenNotPaused assetExists(assetId) onlyAssetOwner(assetId) recipeExists(recipeId) returns (uint256) {
        require(recipient != address(0), "TV: Recipient is the zero address");
        require(recipient != msg.sender, "TV: Cannot grant permission to self");

        _permissionGrantIds.increment();
        uint256 grantId = _permissionGrantIds.current();

        uint256 expiryTimestamp = duration > 0 ? block.timestamp + duration : 0;

        ScopedPermission storage grant = permissionGrants[grantId];
        grant.grantId = grantId;
        grant.grantedBy = msg.sender;
        grant.assetId = assetId;
        grant.recipeId = recipeId;
        grant.expiryTimestamp = expiryTimestamp;
        grant.usesRemaining = maxUses;
        grant.isValid = true;

        _assetUserPermissionGrantIds[assetId][recipient].push(grantId);

        emit ScopedPermissionGranted(grantId, assetId, recipient, recipeId, expiryTimestamp, maxUses);
        return grantId;
    }

    /**
     * @notice Allows the asset owner to revoke a specific permission grant.
     * @param grantId The ID of the permission grant to revoke.
     */
    function revokeSpecificPermissionGrant(uint256 grantId) external whenNotPaused {
        ScopedPermission storage grant = permissionGrants[grantId];
        require(grant.isValid, "TV: Grant is already invalid");
        require(grant.grantedBy == msg.sender, "TV: Caller is not the grantor");

        grant.isValid = false; // Mark as invalid
        // We don't remove from _assetUserPermissionGrantIds array for gas efficiency.
        // Validity check is done when consuming.

        emit ScopedPermissionRevoked(grantId, msg.sender);
    }

     /**
     * @notice Allows the asset owner to approve or disapprove an operator for a single asset.
     * @param operator The address to approve or disapprove.
     * @param assetId The ID of the asset.
     */
    function approve(address operator, uint256 assetId) external whenNotPaused assetExists(assetId) onlyAssetOwner(assetId) {
        _assetApproved[assetId] = operator;
        emit Approval(msg.sender, operator, assetId);
    }

    /**
     * @notice Allows the asset owner to set approval for all assets to an operator.
     * @param operator The address to approve or disapprove.
     * @param approved True to approve, false to disapprove.
     */
    function setApprovalForAll(address operator, bool approved) external whenNotPaused {
        require(operator != msg.sender, "TV: Cannot set approval for self");
        _approvedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Allows a user to consume their resources. Resources might be consumed
     *         for actions not directly tied to transformations (e.g., crafting, boosts).
     *         Resources are also consumed internally by `_applyTransformationLogic`.
     * @param resourceType The type of resource to consume.
     * @param amount The amount of resource to consume.
     */
    function consumeResource(uint256 resourceType, uint256 amount) external whenNotPaused {
        require(_resourceTypes.current() >= resourceType && resourceType > 0, "TV: Invalid resource type");
        require(userResources[msg.sender][resourceType] >= amount, "TV: Insufficient resources");
        userResources[msg.sender][resourceType] -= amount;
        emit UserResourceConsumed(msg.sender, resourceType, amount);
    }


    // --- User Functions (Asset Owner or Permission Recipient) ---

    /**
     * @notice Allows the asset owner to apply a transformation recipe to their asset.
     * @param assetId The ID of the asset.
     * @param recipeId The ID of the recipe to apply.
     */
    function applyTransformation(uint256 assetId, uint256 recipeId) external whenNotPaused assetExists(assetId) onlyAssetOwner(assetId) recipeExists(recipeId) {
        _applyTransformationLogic(assetId, recipeId, msg.sender, 0); // Pass grantId 0 for owner application
    }

     /**
     * @notice Allows a user with a scoped permission to apply a transformation recipe to someone else's asset.
     * @param assetId The ID of the asset.
     * @param recipeId The ID of the recipe to apply.
     * @param grantId The ID of the permission grant being used.
     */
    function applyTransformationAsPermitted(uint256 assetId, uint256 recipeId, uint256 grantId) external whenNotPaused assetExists(assetId) recipeExists(recipeId) {
        ScopedPermission storage grant = permissionGrants[grantId];

        // Validate the permission grant
        require(grant.isValid, "TV: Permission grant is invalid");
        require(grant.assetId == assetId, "TV: Grant is for a different asset");
        require(grant.recipeId == recipeId, "TV: Grant is for a different recipe");
        require(grant.recipient == msg.sender, "TV: Caller is not the permission recipient");
        require(assetOwner[assetId] != address(0), "TV: Asset no longer exists"); // Ensure asset still exists
        require(assetOwner[assetId] == grant.grantedBy, "TV: Asset ownership changed since grant"); // Ensure grantor still owns asset

        if (grant.expiryTimestamp > 0) {
            require(block.timestamp <= grant.expiryTimestamp, "TV: Permission grant expired");
        }
        if (grant.usesRemaining > 0) {
            require(grant.usesRemaining > 0, "TV: Permission grant has no uses remaining");
            grant.usesRemaining--;
             emit ScopedPermissionConsumed(grantId, grant.usesRemaining);
        }

        // If usesRemaining reaches 0 or expiry is reached, mark as invalid after use (or before on check)
        // Let's mark invalid *after* consumption logic if it reaches 0 uses, but check expiry *before*.
         if (grant.usesRemaining == 0 && grant.expiryTimestamp == 0) {
             // This case implies unlimited uses, no action needed
         } else if (grant.usesRemaining == 0) {
             // Used last remaining use
             grant.isValid = false;
         } // Expiry check is done above

        _applyTransformationLogic(assetId, recipeId, msg.sender, grantId);
    }

    // --- Internal Transformation Logic ---

    /**
     * @dev Internal function to handle the core transformation logic, called by public apply functions.
     * @param assetId The ID of the asset.
     * @param recipeId The ID of the recipe.
     * @param performer The address performing the transformation.
     * @param grantId The ID of the permission grant used (0 if by owner).
     */
    function _applyTransformationLogic(
        uint256 assetId,
        uint256 recipeId,
        address performer,
        uint256 grantId
    ) internal whenNotPaused assetExists(assetId) recipeExists(recipeId) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        require(recipe.isActive, "TV: Recipe is not active");

        // Check Requirements
        for (uint i = 0; i < recipe.requirements.length; i++) {
            TransformationRequirement memory req = recipe.requirements[i];

            // Resource requirements
            if (req.resourceType > 0) {
                require(_resourceTypes.current() >= req.resourceType, "TV: Invalid resource type in recipe requirement");
                require(userResources[performer][req.resourceType] >= req.resourceAmount, "TV: Insufficient user resources for requirement");
            }

            // Attribute requirements
            if (bytes(req.attributeKey).length > 0) {
                 require(assetAttributes[assetId][req.attributeKey] >= req.attributeMinValue, "TV: Asset attribute minimum value not met");
            }
        }

        // Consume Resources (Costs)
        uint256 currentResourceType = _resourceTypes.current();
        for (uint i = 1; i <= currentResourceType; i++) {
            uint256 costAmount = recipe.cost[i];
            if (costAmount > 0) {
                require(userResources[performer][i] >= costAmount, "TV: Insufficient user resources for cost");
                userResources[performer][i] -= costAmount;
                emit UserResourceConsumed(performer, i, costAmount); // Emit consumption event for cost
            }
        }


        // Apply Outcomes
        string memory finalMetadataURI = assetMetadataURI[assetId];
        bool metadataChanged = false;
        string[] memory changedAttributes = new string[](recipe.outcomes.length);
        uint256[] memory newAttributeValues = new uint256[](recipe.outcomes.length);
        uint256 attributeChangeCount = 0;


        for (uint i = 0; i < recipe.outcomes.length; i++) {
            TransformationOutcome memory outcome = recipe.outcomes[i];

            // Attribute changes
            if (bytes(outcome.attributeKey).length > 0) {
                uint256 currentValue = assetAttributes[assetId][outcome.attributeKey];
                // Handle signed integer addition/subtraction
                uint256 newValue;
                if (outcome.attributeChange >= 0) {
                    newValue = currentValue + uint256(outcome.attributeChange);
                } else {
                    uint256 changeAmount = uint256(-outcome.attributeChange);
                    require(currentValue >= changeAmount, "TV: Attribute value cannot go below zero");
                    newValue = currentValue - changeAmount;
                }
                assetAttributes[assetId][outcome.attributeKey] = newValue;
                changedAttributes[attributeChangeCount] = outcome.attributeKey;
                newAttributeValues[attributeChangeCount] = newValue;
                attributeChangeCount++;
                // Emit event for attribute update if needed, perhaps aggregated later or in history details
            }

            // Metadata URI change
            if (outcome.setNewMetadata) {
                finalMetadataURI = outcome.newMetadataURI;
                metadataChanged = true;
            }
        }

        // Apply final metadata change if any outcome specified it
        if (metadataChanged) {
            assetMetadataURI[assetId] = finalMetadataURI;
            emit AssetMetadataUpdated(assetId, finalMetadataURI);
        }

        // Log History
        string memory details = "Applied recipe ";
        details = string(abi.encodePacked(details, Strings.toString(recipeId)));
        if (attributeChangeCount > 0) {
             details = string(abi.encodePacked(details, ", Changed attributes: "));
             for(uint i = 0; i < attributeChangeCount; i++){
                 details = string(abi.encodePacked(details, changedAttributes[i], ": ", Strings.toString(newAttributeValues[i])));
                 if(i < attributeChangeCount - 1) details = string(abi.encodePacked(details, ", "));
             }
        }


        assetHistory[assetId].push(TransformationHistoryEntry({
            timestamp: block.timestamp,
            recipeId: recipeId,
            performer: performer,
            details: details
        }));

        emit TransformationApplied(assetId, recipeId, performer, grantId);
    }


    // --- View Functions ---

    /**
     * @notice Gets the owner of an asset.
     * @param assetId The ID of the asset.
     * @return The address of the asset owner.
     */
    function getAssetOwner(uint256 assetId) external view assetExists(assetId) returns (address) {
        return assetOwner[assetId];
    }

    /**
     * @notice Gets the metadata URI of an asset.
     * @param assetId The ID of the asset.
     * @return The metadata URI string.
     */
    function getAssetMetadataURI(uint256 assetId) external view assetExists(assetId) returns (string memory) {
        return assetMetadataURI[assetId];
    }

     /**
     * @notice Gets the value of a specific attribute for an asset.
     * @param assetId The ID of the asset.
     * @param key The attribute key.
     * @return The attribute value. Returns 0 if the attribute is not set.
     */
    function getAssetAttribute(uint256 assetId, string memory key) external view assetExists(assetId) returns (uint256) {
        return assetAttributes[assetId][key];
    }

    /**
     * @notice Gets the details of a transformation recipe.
     * @param recipeId The ID of the recipe.
     * @return isActive, requirements, outcomes, costResourceTypes, costAmounts.
     * Note: Cost is returned as separate arrays.
     */
    function getTransformationRecipe(uint256 recipeId)
        external
        view
        recipeExists(recipeId)
        returns (
            bool isActive,
            TransformationRequirement[] memory requirements,
            TransformationOutcome[] memory outcomes,
            uint256[] memory costResourceTypes,
            uint256[] memory costAmounts
        )
    {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        isActive = recipe.isActive;
        requirements = recipe.requirements;
        outcomes = recipe.outcomes;

        uint256 currentResourceType = _resourceTypes.current();
        uint256 costCount = 0;
        for(uint i = 1; i <= currentResourceType; i++) {
            if (recipe.cost[i] > 0) {
                costCount++;
            }
        }

        costResourceTypes = new uint256[](costCount);
        costAmounts = new uint256[](costCount);
        uint256 k = 0;
         for(uint i = 1; i <= currentResourceType; i++) {
            if (recipe.cost[i] > 0) {
                 costResourceTypes[k] = i;
                 costAmounts[k] = recipe.cost[i];
                 k++;
            }
        }

        return (isActive, requirements, outcomes, costResourceTypes, costAmounts);
    }

     /**
     * @notice Gets the current amount of a specific resource for a user.
     * @param user The address of the user.
     * @param resourceType The type of resource.
     * @return The resource amount.
     */
    function getUserResourceAmount(address user, uint256 resourceType) external view returns (uint256) {
         require(_resourceTypes.current() >= resourceType && resourceType > 0, "TV: Invalid resource type");
         return userResources[user][resourceType];
    }

    /**
     * @notice Gets the history of transformations applied to an asset.
     * @param assetId The ID of the asset.
     * @return An array of history entries.
     */
    function getAssetHistory(uint256 assetId) external view assetExists(assetId) returns (TransformationHistoryEntry[] memory) {
        return assetHistory[assetId];
    }

    /**
     * @notice Gets the details of a specific scoped permission grant.
     * @param grantId The ID of the permission grant.
     * @return The details of the permission grant.
     */
    function getScopedPermissionDetails(uint256 grantId) external view returns (ScopedPermission memory) {
        require(permissionGrants[grantId].grantId != 0, "TV: Grant ID does not exist"); // Check if struct was default initialized
        return permissionGrants[grantId];
    }

     /**
     * @notice Gets a list of all permission grant IDs associated with a specific asset and recipient.
     * @param assetId The ID of the asset.
     * @param recipient The address of the permission recipient.
     * @return An array of permission grant IDs.
     */
    function getPermissionGrantIdsForAssetUser(uint256 assetId, address recipient) external view returns (uint256[] memory) {
        return _assetUserPermissionGrantIds[assetId][recipient];
    }

     /**
     * @notice Gets the total number of assets registered.
     * @return The total asset count.
     */
    function getTotalAssets() external view returns (uint256) {
        return _assetIds.current();
    }

    /**
     * @notice Gets the total number of transformation recipes defined.
     * @return The total recipe count.
     */
    function getTotalRecipes() external view returns (uint256) {
        return _recipeIds.current();
    }

    /**
     * @notice Gets the total number of resource types defined.
     * @return The total resource type count.
     */
     function getTotalResourceTypes() external view returns (uint256) {
        return _resourceTypes.current();
    }


    /**
     * @notice Gets the name of a specific resource type.
     * @param resourceType The ID of the resource type.
     * @return The name of the resource type.
     */
    function getResourceTypeName(uint256 resourceType) external view returns (string memory) {
        require(_resourceTypes.current() >= resourceType && resourceType > 0, "TV: Invalid resource type");
        return resourceTypeNames[resourceType];
    }

    /**
     * @notice Gets the address approved for a single asset.
     * @param assetId The ID of the asset.
     * @return The approved address (address(0) if no approval).
     */
    function getApproved(uint256 assetId) external view assetExists(assetId) returns (address) {
        return _assetApproved[assetId];
    }

    /**
     * @notice Checks if an operator is approved for all assets of an owner.
     * @param owner The address of the owner.
     * @param operator The address of the operator.
     * @return True if the operator is approved for all assets, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _approvedForAll[owner][operator];
    }

     /**
     * @notice Checks if an address is an approved operator for a specific asset (either single or all).
     * @param assetId The ID of the asset.
     * @param operator The address to check.
     * @return True if the address is approved for the asset, false otherwise.
     */
    function isApprovedOrOwner(uint256 assetId, address operator) external view assetExists(assetId) returns (bool) {
        address owner = assetOwner[assetId];
        return (operator == owner || getApproved(assetId) == operator || isApprovedForAll(owner, operator));
    }

    // --- Pausable Functions ---

    /**
     * @notice Pauses the contract. Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract. Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Overridden Ownable Functions ---

    // transferOwnership is inherited from Ownable
}
```