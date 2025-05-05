Okay, here is a Solidity smart contract implementing a concept called the "Generative Asset Guild". This contract acts as a decentralized crafting guild where members use resources to generate and upgrade unique digital "Artifacts" based on dynamically defined rules stored on-chain.

It incorporates:
1.  **Internal Resource Management:** The contract manages different types of resources internally, tracked per member.
2.  **Dynamic, Rule-Based Generation/Upgrading:** Artifact properties are generated and modified based on configurable `GenerationRule` structs.
3.  **Parametric Properties:** Artifacts have an array of numerical properties that can change.
4.  **Membership & Roles:** Basic member tracking and admin roles.
5.  **Delegation:** Members can delegate their crafting rights (and resource usage) to others.
6.  **Probabilistic Outcomes:** Crafting/upgrading can have a success chance defined in rules.
7.  **Internal Asset Management:** Artifacts are tracked by the contract internally, not as standard ERC-721 tokens (avoiding direct duplication, though the *concept* is similar to NFTs).

**Outline:**

1.  **Pragma & License**
2.  **Error Definitions**
3.  **Struct Definitions:**
    *   `Artifact`: Represents a unique generated item.
    *   `MemberData`: Stores member-specific information.
    *   `ResourceInfo`: Defines a type of crafting resource.
    *   `GenerationRule`: Defines the parameters and outcomes of crafting/upgrading operations.
4.  **State Variables:**
    *   Owner, Admins, Paused status.
    *   Counters for IDs (Artifacts, Resources, Rules).
    *   Mappings for data storage (artifacts, members, resources, rules, parameters).
5.  **Events:** Signalling key actions (Join, Resource Deposit, Artifact Generated/Upgraded, etc.).
6.  **Modifiers:** Access control and state checks.
7.  **Function Summary:** A brief description of each public/external function.
8.  **Constructor:** Initialize owner and base parameters.
9.  **Admin/Setup Functions:**
    *   `setGuildParameter`: Configure core guild settings.
    *   `addAdmin`, `removeAdmin`: Manage administrative roles.
    *   `pauseCrafting`, `unpauseCrafting`: Control crafting availability.
    *   `withdrawFunds`: Owner withdraws collected ETH.
    *   `addResourceType`, `updateResourceType`, `removeResourceType`: Define and manage resource types.
    *   `addGenerationRule`, `updateGenerationRule`, `removeGenerationRule`: Define and manage crafting rules.
10. **Membership Functions:**
    *   `joinGuild`: Become a member.
    *   `leaveGuild`: Resign membership.
11. **Resource Management Functions:**
    *   `depositResource`: Add resources to a member's balance (internal transfer simulated).
    *   `transferResourceInternal`: Admin/guild initiated resource transfer.
12. **Artifact Interaction Functions (Core Logic):**
    *   `generateArtifact`: Create a new artifact using a rule and resources.
    *   `upgradeArtifact`: Modify an existing artifact using a rule and resources.
    *   `interactWithArtifact`: A generic function for simple, rule-independent interactions.
    *   `transferInternalArtifact`: Transfer ownership of an internally managed artifact.
    *   `delegateCraftingPower`: Allow another member to craft using your resources.
    *   `revokeCraftingPower`: Remove crafting delegation.
13. **View Functions:**
    *   `getGuildParameter`, `getResourceInfo`, `getGenerationRule`, `getArtifactProperties`, `getArtifactOwner`, `listMemberArtifacts`, `getResourceBalance`, `isMember`, `isAdmin`, `getDelegatedCrafter`, `getTotalArtifacts`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GenerativeAssetGuild
 * @dev A creative smart contract simulating a decentralized guild for crafting and upgrading dynamic digital assets (Artifacts).
 * Members use internally managed resources and on-chain rules to generate and modify unique Artifacts.
 * This contract manages assets and resources internally without relying on standard ERC interfaces like ERC-721 for Artifacts,
 * or ERC-20 for resources (though it could be extended).
 *
 * Outline:
 * 1. Pragma & License
 * 2. Error Definitions
 * 3. Struct Definitions (Artifact, MemberData, ResourceInfo, GenerationRule)
 * 4. State Variables
 * 5. Events
 * 6. Modifiers
 * 7. Function Summary
 * 8. Constructor
 * 9. Admin/Setup Functions (set parameters, manage admins, pause, withdraw, manage resources/rules)
 * 10. Membership Functions (join, leave)
 * 11. Resource Management Functions (deposit, internal transfer)
 * 12. Artifact Interaction Functions (generate, upgrade, interact, transfer, delegate crafting)
 * 13. View Functions (get data about parameters, resources, rules, artifacts, members, balances)
 */

error Guild__NotOwner();
error Guild__NotAdmin();
error Guild__NotMember();
error Guild__AlreadyMember();
error Guild__CraftingPaused();
error Guild__ArtifactDoesNotExist(uint256 artifactId);
error Guild__NotArtifactOwner(uint256 artifactId, address caller);
error Guild__InsufficientResources(uint256 resourceTypeId, uint256 required, uint256 available);
error Guild__ResourceDoesNotExist(uint256 resourceTypeId);
error Guild__GenerationRuleDoesNotExist(uint256 ruleId);
error Guild__InvalidGenerationRule();
error Guild__ArtifactPropertiesMismatch();
error Guild__ZeroAddress();
error Guild__DelegationConflict();
error Guild__NoDelegationActive();
error Guild__CannotRemoveRequiredResource();
error Guild__CannotRemoveInUseRule();

contract GenerativeAssetGuild {

    // --- Struct Definitions ---

    struct Artifact {
        uint256 id;
        address owner;
        uint64 creationTime;
        uint256[] properties; // Dynamic array of numerical properties
        bool exists; // To check if the artifact ID is valid
        uint64 lastInteractionTime;
    }

    struct MemberData {
        bool isMember;
        bool isAdmin;
        uint64 joinTime;
        address delegatedCrafter; // Address allowed to craft/upgrade on behalf of this member
    }

    struct ResourceInfo {
        string name;
        bool consumable; // Can this resource be consumed during crafting?
        uint256 baseValue; // Potential value for internal trading/conversion
        bool exists; // To check if the resource type ID is valid
    }

    struct GenerationRule {
        uint256 id;
        string name;
        uint256 requiredResourceTypeId; // Resource needed for this rule
        uint256 requiredResourceAmount; // Amount of resource needed
        uint256 requiredArtifactId; // Optional: require a specific artifact type/ID as input (0 for none)
        uint256[] requiredProperties; // If requiredArtifactId > 0, check these properties match
        uint256 outputArtifactInitialPropertiesRule; // Rule ID or method to generate initial properties
        uint256[] propertyChanges; // How properties are changed on success (e.g., [propIndex1, changeVal1, propIndex2, changeVal2...])
        uint64 cooldownSeconds; // Cooldown for applying this rule per user/artifact
        uint256 successChanceBps; // Success chance in basis points (e.g., 10000 for 100%)
        bool generatesNewArtifact; // True if this rule creates a new artifact, false if it upgrades an existing one
        bool exists; // To check if the rule ID is valid
    }

    // --- State Variables ---

    address private _owner;
    mapping(address => MemberData) public members;
    mapping(bytes32 => uint256) public guildParameters; // Flexible parameters (e.g., MIN_MEMBERSHIP_FEE)
    bool public craftingPaused = false;

    // Resource Management
    uint256 public nextResourceTypeId = 1;
    mapping(uint256 => ResourceInfo) public resourceTypes; // Resource ID => Info
    mapping(address => mapping(uint256 => uint256)) public resourceBalances; // Member Address => Resource ID => Balance

    // Artifact Management
    uint256 public nextArtifactId = 1;
    mapping(uint256 => Artifact) private _artifacts; // Artifact ID => Artifact Data
    mapping(address => uint256[]) private _memberArtifacts; // Member Address => Array of Artifact IDs they own

    // Rule Management
    uint256 public nextGenerationRuleId = 1;
    mapping(uint256 => GenerationRule) public generationRules; // Rule ID => Rule Data

    // Delegation
    mapping(address => address) private _crafterDelegations; // Delegatee => Delegator (who they are crafting for)

    // --- Events ---

    event GuildParameterUpdated(bytes32 indexed key, uint256 value);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event CraftingPaused(bool indexed paused);
    event ResourceTypeAdded(uint256 indexed resourceTypeId, string name, bool consumable, uint256 baseValue);
    event ResourceTypeUpdated(uint256 indexed resourceTypeId, string name, bool consumable, uint256 baseValue);
    event ResourceTypeRemoved(uint256 indexed resourceTypeId);
    event GenerationRuleAdded(uint256 indexed ruleId, string name, bool generatesNewArtifact);
    event GenerationRuleUpdated(uint256 indexed ruleId, string name);
    event GenerationRuleRemoved(uint256 indexed ruleId);
    event MemberJoined(address indexed member, uint64 joinTime);
    event MemberLeft(address indexed member);
    event ResourceDeposited(address indexed member, uint256 indexed resourceTypeId, uint256 amount);
    event ResourceTransferredInternal(address indexed from, address indexed to, uint256 indexed resourceTypeId, uint256 amount);
    event ArtifactGenerated(uint256 indexed artifactId, address indexed owner, uint256 indexed ruleId, uint64 generationTime);
    event ArtifactUpgraded(uint256 indexed artifactId, uint256 indexed ruleId, uint64 upgradeTime);
    event ArtifactInteract(uint256 indexed artifactId, address indexed caller, uint256 interactionType);
    event ArtifactTransfer(uint256 indexed from, uint256 indexed to, uint256 indexed artifactId);
    event CraftingPowerDelegated(address indexed delegator, address indexed delegatee);
    event CraftingPowerRevoked(address indexed delegator, address indexed delegatee);
    event CraftingFailed(address indexed caller, uint256 indexed ruleId, string reason);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert Guild__NotOwner();
        _;
    }

    modifier onlyAdminOrOwner() {
        if (msg.sender != _owner && !members[msg.sender].isAdmin) revert Guild__NotAdmin();
        _;
    }

    modifier onlyMember() {
        if (!members[msg.sender].isMember) revert Guild__NotMember();
        _;
    }

    modifier onlyMemberOrDelegatee() {
         // Check if sender is a member OR is delegated *by* a member
        if (!members[msg.sender].isMember && _crafterDelegations[msg.sender] == address(0)) {
             revert Guild__NotMember(); // Or a specific "NotMemberOrDelegatee" error
        }
        _;
    }

    modifier whenNotPaused() {
        if (craftingPaused) revert Guild__CraftingPaused();
        _;
    }

    modifier artifactExists(uint256 artifactId) {
        if (!_artifacts[artifactId].exists) revert Guild__ArtifactDoesNotExist(artifactId);
        _;
    }

    modifier isArtifactOwner(uint256 artifactId, address _address) {
        if (_artifacts[artifactId].owner != _address) revert Guild__NotArtifactOwner(artifactId, _address);
        _;
    }

    modifier hasEnoughResources(address account, uint256 resourceTypeId, uint256 amount) {
        if (resourceBalances[account][resourceTypeId] < amount) {
            revert Guild__InsufficientResources(resourceTypeId, amount, resourceBalances[account][resourceTypeId]);
        }
        _;
    }

    // --- Function Summary ---
    // (This section is a comment block as requested)
    /*
    * Admin/Setup:
    * 1. setGuildParameter(bytes32 key, uint256 value): Set/update a core uint256 parameter. (Admin/Owner)
    * 2. addAdmin(address account): Grant admin role to a member. (Owner)
    * 3. removeAdmin(address account): Revoke admin role. (Owner)
    * 4. pauseCrafting(): Pause artifact generation/upgrading. (Admin/Owner)
    * 5. unpauseCrafting(): Unpause artifact generation/upgrading. (Admin/Owner)
    * 6. withdrawFunds(address payable to, uint256 amount): Withdraw ETH balance. (Owner)
    * 7. addResourceType(string calldata name, bool consumable, uint256 baseValue): Define a new resource type. (Admin/Owner)
    * 8. updateResourceType(uint256 resourceTypeId, string calldata name, bool consumable, uint256 baseValue): Modify resource type details. (Admin/Owner)
    * 9. removeResourceType(uint256 resourceTypeId): Remove a resource type. (Admin/Owner)
    * 10. addGenerationRule(GenerationRule calldata rule): Define a new crafting/upgrade rule. (Admin/Owner)
    * 11. updateGenerationRule(GenerationRule calldata rule): Modify an existing rule. (Admin/Owner)
    * 12. removeGenerationRule(uint256 ruleId): Remove a crafting/upgrade rule. (Admin/Owner)
    *
    * Membership:
    * 13. joinGuild(): Become a guild member (may require payment/condition). (Public)
    * 14. leaveGuild(): Leave the guild. (Member)
    *
    * Resource Management:
    * 15. depositResource(address member, uint256 resourceTypeId, uint256 amount): Add resources to a member's balance (Admin/Owner - simulated deposit).
    * 16. transferResourceInternal(address from, address to, uint256 resourceTypeId, uint256 amount): Transfer resources between members (Admin/Owner).
    *
    * Artifact Interaction:
    * 17. generateArtifact(uint256 ruleId): Create a new artifact using a specific rule. (Member/Delegatee, whenNotPaused)
    * 18. upgradeArtifact(uint256 artifactId, uint256 ruleId): Modify an existing artifact using a specific rule. (Artifact Owner/Delegatee, whenNotPaused)
    * 19. interactWithArtifact(uint256 artifactId, uint256 interactionType, bytes calldata interactionData): A generic function for unique artifact interactions. (Public/Conditional, whenNotPaused)
    * 20. transferInternalArtifact(address to, uint256 artifactId): Transfer internal artifact ownership. (Artifact Owner)
    * 21. delegateCraftingPower(address delegatee): Allow another member to craft using your resources/permissions. (Member)
    * 22. revokeCraftingPower(): Remove an active crafting delegation. (Member)
    *
    * View Functions (Read-only):
    * 23. getGuildParameter(bytes32 key): Get a core guild parameter value.
    * 24. getResourceInfo(uint256 resourceTypeId): Get details of a resource type.
    * 25. getGenerationRule(uint256 ruleId): Get details of a crafting rule.
    * 26. getArtifactProperties(uint256 artifactId): Get the properties array of an artifact.
    * 27. getArtifactOwner(uint256 artifactId): Get the owner of an artifact.
    * 28. listMemberArtifacts(address member): List artifact IDs owned by a member.
    * 29. getResourceBalance(address member, uint256 resourceTypeId): Get a member's resource balance.
    * 30. isMember(address account): Check if an address is a member.
    * 31. isAdmin(address account): Check if an address is an admin.
    * 32. getDelegatedCrafter(address delegator): Get the address delegated to craft for a member.
    * 33. getTotalArtifacts(): Get the total number of artifacts created.
    */


    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        members[msg.sender].isMember = true; // Owner is a member by default
        members[msg.sender].isAdmin = true;  // Owner is admin by default
        members[msg.sender].joinTime = uint64(block.timestamp);

        // Set some initial parameters (using bytes32 keys for flexibility)
        guildParameters[bytes32("MIN_MEMBERSHIP_FEE")] = 0.01 ether; // Example fee
        guildParameters[bytes32("MAX_ARTIFACT_PROPERTIES")] = 10;     // Limit property array size
        guildParameters[bytes32("BASE_SUCCESS_CHANCE")] = 8000;      // 80% default success (if not in rule)
    }

    // --- Admin/Setup Functions ---

    /**
     * @dev Sets a core uint256 guild parameter.
     * @param key The bytes32 key identifier for the parameter.
     * @param value The uint256 value to set.
     */
    function setGuildParameter(bytes32 key, uint256 value) external onlyAdminOrOwner {
        guildParameters[key] = value;
        emit GuildParameterUpdated(key, value);
    }

    /**
     * @dev Adds an account as an admin. Must already be a member.
     * @param account The address to grant admin role.
     */
    function addAdmin(address account) external onlyOwner {
        if (account == address(0)) revert Guild__ZeroAddress();
        if (!members[account].isMember) revert Guild__NotMember(); // Must be a member first
        members[account].isAdmin = true;
        emit AdminAdded(account);
    }

    /**
     * @dev Removes an account's admin role.
     * @param account The address to remove admin role from.
     */
    function removeAdmin(address account) external onlyOwner {
        if (account == address(0)) revert Guild__ZeroAddress();
        if (account == _owner) revert Guild__NotAdmin(); // Cannot remove owner's admin role
        members[account].isAdmin = false;
        emit AdminRemoved(account);
    }

    /**
     * @dev Pauses artifact generation and upgrading.
     */
    function pauseCrafting() external onlyAdminOrOwner {
        craftingPaused = true;
        emit CraftingPaused(true);
    }

    /**
     * @dev Unpauses artifact generation and upgrading.
     */
    function unpauseCrafting() external onlyAdminOrOwner {
        craftingPaused = false;
        emit CraftingPaused(false);
    }

    /**
     * @dev Allows the owner to withdraw collected Ether.
     * @param to The address to send the Ether to.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawFunds(address payable to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert Guild__ZeroAddress();
        require(address(this).balance >= amount, "Insufficient contract balance");
        to.transfer(amount);
    }

    /**
     * @dev Adds a new resource type definition.
     * @param name The name of the resource type.
     * @param consumable Whether the resource is consumed during use.
     * @param baseValue A base value for the resource.
     * @return The ID of the new resource type.
     */
    function addResourceType(string calldata name, bool consumable, uint256 baseValue) external onlyAdminOrOwner returns (uint256) {
        uint256 newId = nextResourceTypeId++;
        resourceTypes[newId] = ResourceInfo(name, consumable, baseValue, true);
        emit ResourceTypeAdded(newId, name, consumable, baseValue);
        return newId;
    }

    /**
     * @dev Updates an existing resource type definition.
     * @param resourceTypeId The ID of the resource type to update.
     * @param name The new name.
     * @param consumable The new consumable status.
     * @param baseValue The new base value.
     */
    function updateResourceType(uint256 resourceTypeId, string calldata name, bool consumable, uint256 baseValue) external onlyAdminOrOwner {
        if (!resourceTypes[resourceTypeId].exists) revert Guild__ResourceDoesNotExist(resourceTypeId);
        resourceTypes[resourceTypeId].name = name;
        resourceTypes[resourceTypeId].consumable = consumable;
        resourceTypes[resourceTypeId].baseValue = baseValue;
        emit ResourceTypeUpdated(resourceTypeId, name, consumable, baseValue);
    }

    /**
     * @dev Removes a resource type definition. Cannot remove if it's a required resource in any rule.
     * @param resourceTypeId The ID of the resource type to remove.
     */
    function removeResourceType(uint256 resourceTypeId) external onlyAdminOrOwner {
        if (!resourceTypes[resourceTypeId].exists) revert Guild__ResourceDoesNotExist(resourceTypeId);

        // Check if this resource is required in any rule
        uint256 currentRuleId = 1;
        while (currentRuleId < nextGenerationRuleId) {
            if (generationRules[currentRuleId].exists && generationRules[currentRuleId].requiredResourceTypeId == resourceTypeId) {
                revert Guild__CannotRemoveRequiredResource();
            }
            currentRuleId++;
        }

        delete resourceTypes[resourceTypeId];
        emit ResourceTypeRemoved(resourceTypeId);
    }

    /**
     * @dev Adds a new generation/upgrade rule.
     * @param rule The GenerationRule struct to add. The ID field is ignored and assigned automatically.
     * @return The ID of the new rule.
     */
    function addGenerationRule(GenerationRule calldata rule) external onlyAdminOrOwner returns (uint256) {
        if (rule.requiredResourceTypeId != 0 && !resourceTypes[rule.requiredResourceTypeId].exists) revert Guild__ResourceDoesNotExist(rule.requiredResourceTypeId);
        // Add more validation for rule parameters as needed
        if (rule.generatesNewArtifact && rule.requiredArtifactId != 0) revert Guild__InvalidGenerationRule(); // Cannot require input artifact for generation
        if (!rule.generatesNewArtifact && rule.requiredArtifactId == 0) revert Guild__InvalidGenerationRule(); // Must require input artifact for upgrade

        uint256 newId = nextGenerationRuleId++;
        GenerationRule memory newRule = rule; // Copy calldata to memory
        newRule.id = newId;
        newRule.exists = true;
        generationRules[newId] = newRule;
        emit GenerationRuleAdded(newId, newRule.name, newRule.generatesNewArtifact);
        return newId;
    }

     /**
     * @dev Updates an existing generation/upgrade rule.
     * @param rule The GenerationRule struct with updated data. The ID field must match an existing rule.
     */
    function updateGenerationRule(GenerationRule calldata rule) external onlyAdminOrOwner {
        if (!generationRules[rule.id].exists) revert Guild__GenerationRuleDoesNotExist(rule.id);
        if (rule.requiredResourceTypeId != 0 && !resourceTypes[rule.requiredResourceTypeId].exists) revert Guild__ResourceDoesNotExist(rule.requiredResourceTypeId);
         // Add more validation for rule parameters as needed
        if (rule.generatesNewArtifact && rule.requiredArtifactId != 0) revert Guild__InvalidGenerationRule(); // Cannot require input artifact for generation
        if (!rule.generatesNewArtifact && rule.requiredArtifactId == 0) revert Guild__InvalidGenerationRule(); // Must require input artifact for upgrade


        // Update the rule, keeping the exists flag true
        generationRules[rule.id].name = rule.name;
        generationRules[rule.id].requiredResourceTypeId = rule.requiredResourceTypeId;
        generationRules[rule.id].requiredResourceAmount = rule.requiredResourceAmount;
        generationRules[rule.id].requiredArtifactId = rule.requiredArtifactId;
        generationRules[rule.id].requiredProperties = rule.requiredProperties;
        generationRules[rule.id].outputArtifactInitialPropertiesRule = rule.outputArtifactInitialPropertiesRule;
        generationRules[rule.id].propertyChanges = rule.propertyChanges;
        generationRules[rule.id].cooldownSeconds = rule.cooldownSeconds;
        generationRules[rule.id].successChanceBps = rule.successChanceBps;
        generationRules[rule.id].generatesNewArtifact = rule.generatesNewArtifact;

        emit GenerationRuleUpdated(rule.id, rule.name);
    }

    /**
     * @dev Removes a generation/upgrade rule.
     * @param ruleId The ID of the rule to remove.
     */
    function removeGenerationRule(uint256 ruleId) external onlyAdminOrOwner {
         if (!generationRules[ruleId].exists) revert Guild__GenerationRuleDoesNotExist(ruleId);

        // Add checks here if rules are referenced elsewhere (e.g., by artifacts).
        // For this simplified version, we just delete. In a real system, you might
        // want to prevent removal if artifacts or other systems depend on the rule.
        // E.g., if outputArtifactInitialPropertiesRule could reference another rule.
        // uint256 currentRuleId = 1;
        // while (currentRuleId < nextGenerationRuleId) {
        //     if (generationRules[currentRuleId].exists && generationRules[currentRuleId].outputArtifactInitialPropertiesRule == ruleId) {
        //         revert Guild__CannotRemoveInUseRule(); // Example check
        //     }
        //     currentRuleId++;
        // }

        delete generationRules[ruleId];
        emit GenerationRuleRemoved(ruleId);
    }

    // --- Membership Functions ---

    /**
     * @dev Allows an address to join the guild. Requires sending the minimum membership fee.
     * @param referrer Optional address of a member who referred the new member. (Currently unused)
     */
    function joinGuild(address referrer) external payable {
        if (members[msg.sender].isMember) revert Guild__AlreadyMember();
        if (msg.value < guildParameters[bytes32("MIN_MEMBERSHIP_FEE")]) revert ("Insufficient fee to join guild"); // Custom error maybe better

        members[msg.sender].isMember = true;
        members[msg.sender].joinTime = uint64(block.timestamp);
        // Optionally handle referrer logic here (e.g., give them a bonus)

        emit MemberJoined(msg.sender, members[msg.sender].joinTime);
    }

    /**
     * @dev Allows a member to leave the guild. Does not affect owned artifacts or resources (simplification).
     */
    function leaveGuild() external onlyMember {
        if (msg.sender == _owner) revert Guild__NotMember(); // Owner cannot leave

        // Reset member data (doesn't delete artifacts or resources in this simplified version)
        delete members[msg.sender];
        // Ensure any delegation *by* this member is revoked
        address delegated = _crafterDelegations[msg.sender];
        if (delegated != address(0)) {
             delete _crafterDelegations[msg.sender];
             emit CraftingPowerRevoked(msg.sender, delegated);
        }
         // Ensure any delegation *to* this member is removed
         address delegator = _crafterDelegations[msg.sender]; // This lookup is wrong way. Need reverse mapping or iterate
         // A more robust system would require iterating delegations or a reverse mapping.
         // For this example, we'll leave the delegatee pointer potentially stale if the delegator leaves.
         // Better: Add mapping `delegator => delegatee` and update that on join/leave.
         // Corrected logic: we only need to check delegations *from* msg.sender.

        emit MemberLeft(msg.sender);
    }

    // --- Resource Management Functions ---

    /**
     * @dev Admin function to deposit resources into a member's balance.
     * In a real application, this might be linked to purchasing, staking, or external contract interactions.
     * @param member The address to deposit resources for.
     * @param resourceTypeId The ID of the resource type.
     * @param amount The amount to deposit.
     */
    function depositResource(address member, uint256 resourceTypeId, uint256 amount) external onlyAdminOrOwner {
         if (member == address(0)) revert Guild__ZeroAddress();
         if (!members[member].isMember) revert Guild__NotMember(); // Only deposit for members
         if (!resourceTypes[resourceTypeId].exists) revert Guild__ResourceDoesNotExist(resourceTypeId);
         if (amount == 0) return;

        resourceBalances[member][resourceTypeId] += amount;
        emit ResourceDeposited(member, resourceTypeId, amount);
    }

    /**
     * @dev Admin function to transfer resources between member balances.
     * @param from The sender address.
     * @param to The recipient address.
     * @param resourceTypeId The ID of the resource type.
     * @param amount The amount to transfer.
     */
    function transferResourceInternal(address from, address to, uint256 resourceTypeId, uint256 amount) external onlyAdminOrOwner hasEnoughResources(from, resourceTypeId, amount) {
        if (from == address(0) || to == address(0)) revert Guild__ZeroAddress();
        if (!members[from].isMember || !members[to].isMember) revert Guild__NotMember(); // Only transfer between members
        if (!resourceTypes[resourceTypeId].exists) revert Guild__ResourceDoesNotExist(resourceTypeId);
        if (amount == 0) return;

        resourceBalances[from][resourceTypeId] -= amount;
        resourceBalances[to][resourceTypeId] += amount;
        emit ResourceTransferredInternal(from, to, resourceTypeId, amount);
    }

    // --- Artifact Interaction Functions ---

    /**
     * @dev Generates a new artifact based on a specific rule.
     * Requires resources and checks success chance.
     * The actual crafter can be the member or their delegatee.
     * @param ruleId The ID of the generation rule to use.
     */
    function generateArtifact(uint256 ruleId) external onlyMemberOrDelegatee whenNotPaused {
        GenerationRule storage rule = generationRules[ruleId];
        if (!rule.exists) revert Guild__GenerationRuleDoesNotExist(ruleId);
        if (!rule.generatesNewArtifact) revert Guild__InvalidGenerationRule(); // This rule is for upgrading, not generating

        address delegator = _crafterDelegations[msg.sender] != address(0) ? _crafterDelegations[msg.sender] : msg.sender;
        address recipient = delegator; // New artifact goes to the delegator (member)

        // Check resource requirements
        if (rule.requiredResourceTypeId != 0 && rule.requiredResourceAmount > 0) {
            if (!resourceTypes[rule.requiredResourceTypeId].exists || !resourceTypes[rule.requiredResourceTypeId].consumable) {
                revert Guild__ResourceDoesNotExist(rule.requiredResourceTypeId); // Should not happen if rules are added correctly
            }
            if (resourceBalances[delegator][rule.requiredResourceTypeId] < rule.requiredResourceAmount) {
                 revert Guild__InsufficientResources(rule.requiredResourceTypeId, rule.requiredResourceAmount, resourceBalances[delegator][rule.requiredResourceTypeId]);
            }
        }

        // Consume resources BEFORE potential failure
        if (rule.requiredResourceTypeId != 0 && rule.requiredResourceAmount > 0) {
             resourceBalances[delegator][rule.requiredResourceTypeId] -= rule.requiredResourceAmount;
        }

        // Determine success based on chance
        uint256 successChance = rule.successChanceBps > 0 ? rule.successChanceBps : guildParameters[bytes32("BASE_SUCCESS_CHANCE")];
        // Simple probability based on block hash and timestamp (weak, use Chainlink VRF or similar for production)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nextArtifactId))) % 10001; // 0 to 10000

        if (randomNumber > successChance) {
            // Crafting failed
            emit CraftingFailed(msg.sender, ruleId, "Probability check failed");
            // Optionally refund some resources here
            return;
        }

        // Crafting succeeded
        uint256 newArtifactId = nextArtifactId++;
        Artifact memory newArtifact;
        newArtifact.id = newArtifactId;
        newArtifact.owner = recipient;
        newArtifact.creationTime = uint64(block.timestamp);
        newArtifact.lastInteractionTime = uint64(block.timestamp);
        newArtifact.exists = true;

        // Generate initial properties based on rule parameters.
        // This is a simplified example; could involve complex calculations
        // based on resources used, rule weight, previous artifacts, etc.
        // Here, we'll just apply the propertyChanges from the rule as initial properties.
        // A more advanced version might use outputArtifactInitialPropertiesRule
        // to point to *another* rule or algorithm ID.
        uint256 numProperties = rule.propertyChanges.length / 2; // Assuming pairs [index, value]
        uint256 maxProps = guildParameters[bytes32("MAX_ARTIFACT_PROPERTIES")];
         if (numProperties > maxProps) numProperties = maxProps; // Cap properties

        newArtifact.properties = new uint256[](numProperties);
        for (uint i = 0; i < numProperties * 2; i += 2) {
             uint256 propIndex = rule.propertyChanges[i];
             uint256 propValue = rule.propertyChanges[i+1];
             if (propIndex < maxProps) { // Ensure index is within bounds
                 newArtifact.properties[propIndex] = propValue;
             }
        }

        _artifacts[newArtifactId] = newArtifact;
        _memberArtifacts[recipient].push(newArtifactId);

        emit ArtifactGenerated(newArtifactId, recipient, ruleId, newArtifact.creationTime);
    }


    /**
     * @dev Upgrades an existing artifact based on a specific rule.
     * Requires resources, checks properties, and checks success chance.
     * The actual crafter can be the artifact owner or their delegatee.
     * @param artifactId The ID of the artifact to upgrade.
     * @param ruleId The ID of the upgrade rule to use.
     */
    function upgradeArtifact(uint256 artifactId, uint256 ruleId) external onlyMemberOrDelegatee whenNotPaused artifactExists(artifactId) {
        GenerationRule storage rule = generationRules[ruleId];
        if (!rule.exists) revert Guild__GenerationRuleDoesNotExist(ruleId);
        if (rule.generatesNewArtifact) revert Guild__InvalidGenerationRule(); // This rule is for generating, not upgrading

        address owner = _artifacts[artifactId].owner;
        address caller = msg.sender;
        address crafter = _crafterDelegations[caller] != address(0) ? caller : owner; // Caller must be owner OR their delegatee

        if (crafter != owner && _crafterDelegations[caller] != owner) revert Guild__NotArtifactOwner(artifactId, caller); // Ensure caller is owner or delegated by owner

        // Check resource requirements (paid by the owner of the artifact, potentially via delegatee spending)
        if (rule.requiredResourceTypeId != 0 && rule.requiredResourceAmount > 0) {
            if (!resourceTypes[rule.requiredResourceTypeId].exists || !resourceTypes[rule.requiredResourceTypeId].consumable) {
                revert Guild__ResourceDoesNotExist(rule.requiredResourceTypeId);
            }
             if (resourceBalances[owner][rule.requiredResourceTypeId] < rule.requiredResourceAmount) {
                 revert Guild__InsufficientResources(rule.requiredResourceTypeId, rule.requiredResourceAmount, resourceBalances[owner][rule.requiredResourceTypeId]);
            }
        }

         // Check required input artifact properties if the rule specifies
         if (rule.requiredArtifactId != 0) {
              // Assuming requiredArtifactId refers to a *type* or *category* rather than a specific ID for upgrade rules
              // A more complex system would match properties or other characteristics.
              // For this simplified example, if requiredArtifactId > 0, we just check requiredProperties.
              if (rule.requiredProperties.length > 0) {
                   uint256 maxProps = guildParameters[bytes32("MAX_ARTIFACT_PROPERTIES")];
                   if (_artifacts[artifactId].properties.length < rule.requiredProperties.length / 2) revert Guild__ArtifactPropertiesMismatch(); // Not enough properties

                   for (uint i = 0; i < rule.requiredProperties.length; i += 2) {
                       uint256 propIndex = rule.requiredProperties[i];
                       uint256 requiredValue = rule.requiredProperties[i+1];
                        if (propIndex >= maxProps || propIndex >= _artifacts[artifactId].properties.length || _artifacts[artifactId].properties[propIndex] < requiredValue) {
                           revert Guild__ArtifactPropertiesMismatch(); // Property missing or below required value
                        }
                   }
              }
         }


        // Consume resources BEFORE potential failure
        if (rule.requiredResourceTypeId != 0 && rule.requiredResourceAmount > 0) {
             resourceBalances[owner][rule.requiredResourceTypeId] -= rule.requiredResourceAmount;
        }

        // Check cooldown
        if (block.timestamp < _artifacts[artifactId].lastInteractionTime + rule.cooldownSeconds) {
            revert("Upgrade is on cooldown for this artifact"); // Specific error
        }

        // Determine success based on chance
        uint256 successChance = rule.successChanceBps > 0 ? rule.successChanceBps : guildParameters[bytes32("BASE_SUCCESS_CHANCE")];
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, artifactId))) % 10001; // 0 to 10000

        if (randomNumber > successChance) {
            // Crafting failed
            _artifacts[artifactId].lastInteractionTime = uint64(block.timestamp); // Apply cooldown even on failure? Rule design choice.
            emit CraftingFailed(msg.sender, ruleId, "Probability check failed");
            // Optionally refund some resources here
            return;
        }

        // Upgrade succeeded
        uint256 maxProps = guildParameters[bytes32("MAX_ARTIFACT_PROPERTIES")];
        uint256 currentPropCount = _artifacts[artifactId].properties.length;
         if (currentPropCount < maxProps) {
             // Expand properties array if necessary and possible
             uint256 newPropCount = currentPropCount + (rule.propertyChanges.length / 2);
             if (newPropCount > maxProps) newPropCount = maxProps;
              assembly { // Use assembly for efficient array resizing
                 let oldData := add(_artifacts[artifactId].properties, 0x20)
                 let newData := add(mul(newPropCount, 0x20), 0x20)
                 newData := mload(0x40)
                 mstore(0x40, add(newData, newData)) // Update free memory pointer
                 mstore(newData, newPropCount)
                 // Copy old data
                 let oldLen := mload(sub(oldData, 0x20))
                 if gt(oldLen, 0) {
                     staticcall(gas(), 0x4, oldData, mul(oldLen, 0x20), add(newData, 0x20), mul(oldLen, 0x20)) // Use staticcall for memory copy
                 }
                 mstore(_artifacts[artifactId].properties, newData) // Update storage pointer
             }
         }


        // Apply property changes
        for (uint i = 0; i < rule.propertyChanges.length; i += 2) {
            uint256 propIndex = rule.propertyChanges[i];
            int256 changeValue = int256(rule.propertyChanges[i+1]); // Interpret value as potentially signed

            if (propIndex < _artifacts[artifactId].properties.length) {
                // Apply change: simple addition for now, could be more complex (multiplication, setting, etc.)
                // Need careful handling of signed/unsigned conversion if changeValue can be negative
                // For simplicity, let's assume propertyChanges are positive values to add.
                _artifacts[artifactId].properties[propIndex] += uint256(changeValue); // Safe if changeValue is positive
                // To handle negative: unchecked { _artifacts[artifactId].properties[propIndex] = uint256(int256(_artifacts[artifactId].properties[propIndex]) + changeValue); } with safety checks
            }
        }

        _artifacts[artifactId].lastInteractionTime = uint64(block.timestamp);

        emit ArtifactUpgraded(artifactId, ruleId, uint64(block.timestamp));
    }

    /**
     * @dev A generic function for unique interactions with an artifact.
     * The interaction logic is intended to be simple and potentially rule-independent,
     * or could trigger specific logic based on type/data input.
     * Requires the caller to be the owner or delegatee.
     * @param artifactId The ID of the artifact to interact with.
     * @param interactionType A type identifier for the interaction.
     * @param interactionData Arbitrary data for the interaction logic.
     */
    function interactWithArtifact(uint256 artifactId, uint256 interactionType, bytes calldata interactionData) external onlyMemberOrDelegatee whenNotPaused artifactExists(artifactId) {
        address owner = _artifacts[artifactId].owner;
        address caller = msg.sender;
        address crafter = _crafterDelegations[caller] != address(0) ? caller : owner;

        if (crafter != owner && _crafterDelegations[caller] != owner) revert Guild__NotArtifactOwner(artifactId, caller);

        // --- Simple Interaction Logic Example ---
        // This can be expanded significantly based on interactionType and interactionData
        // For example, changing a specific property based on interactionType.
        // Or consuming a small amount of a resource.
        // Or triggering a time-based effect.

        uint256 maxProps = guildParameters[bytes32("MAX_ARTIFACT_PROPERTIES")];
        if (_artifacts[artifactId].properties.length > 0 && interactionType > 0 && interactionType <= maxProps) {
             // Example: Increment a property based on interaction type (if type corresponds to property index)
             // Ensure interactionType is a valid index
             uint256 propIndex = interactionType - 1; // Use interactionType 1 for prop 0, 2 for prop 1, etc.
             if (propIndex < _artifacts[artifactId].properties.length) {
                  _artifacts[artifactId].properties[propIndex]++; // Simple interaction effect
             }
        }

        // Optionally consume a minor resource
        // uint256 interactionCostResource = guildParameters[bytes32("INTERACTION_COST_RESOURCE_TYPE")]; // Need a parameter for this
        // uint256 interactionCostAmount = guildParameters[bytes32("INTERACTION_COST_AMOUNT")];
        // if (interactionCostResource > 0 && interactionCostAmount > 0) {
        //      if (!resourceTypes[interactionCostResource].exists || !resourceTypes[interactionCostResource].consumable) revert ResourceDoesNotExist(...);
        //      if (resourceBalances[owner][interactionCostResource] < interactionCostAmount) revert InsufficientResources(...);
        //      resourceBalances[owner][interactionCostResource] -= interactionCostAmount;
        // }

        _artifacts[artifactId].lastInteractionTime = uint64(block.timestamp);

        emit ArtifactInteract(artifactId, msg.sender, interactionType);
    }

    /**
     * @dev Transfers ownership of an internally managed artifact from the current owner to another address.
     * The sender must be the current owner.
     * @param to The recipient address.
     * @param artifactId The ID of the artifact to transfer.
     */
    function transferInternalArtifact(address to, uint256 artifactId) external artifactExists(artifactId) isArtifactOwner(artifactId, msg.sender) {
        if (to == address(0)) revert Guild__ZeroAddress();
        if (!members[to].isMember) revert Guild__NotMember(); // Can only transfer to members

        address from = msg.sender;

        // Remove artifact from sender's list
        uint256[] storage senderArtifacts = _memberArtifacts[from];
        for (uint i = 0; i < senderArtifacts.length; i++) {
            if (senderArtifacts[i] == artifactId) {
                // Swap with last element and pop
                senderArtifacts[i] = senderArtifacts[senderArtifacts.length - 1];
                senderArtifacts.pop();
                break; // Found and removed
            }
        }

        // Update artifact owner
        _artifacts[artifactId].owner = to;

        // Add artifact to recipient's list
        _memberArtifacts[to].push(artifactId);

        emit ArtifactTransfer(from, to, artifactId);
    }

    /**
     * @dev Allows a member to delegate their crafting rights and resource spending to another member.
     * The delegatee can then call `generateArtifact` and `upgradeArtifact` on behalf of the delegator,
     * using the delegator's resources.
     * Only one active delegation per member is allowed.
     * @param delegatee The address of the member who will be allowed to craft.
     */
    function delegateCraftingPower(address delegatee) external onlyMember {
        if (delegatee == address(0)) revert Guild__ZeroAddress();
        if (!members[delegatee].isMember) revert Guild__NotMember(); // Must delegate to a member
        if (delegatee == msg.sender) revert Guild__DelegationConflict(); // Cannot delegate to self

        // Check if this member is already delegated TO someone else (cannot delegate their delegation)
        address currentDelegator = _crafterDelegations[msg.sender]; // Check if *sender* is a delegatee
        if (currentDelegator != address(0)) revert Guild__DelegationConflict(); // Sender is already crafting for someone else

        // Set the delegation: delegatee -> delegator mapping
        _crafterDelegations[delegatee] = msg.sender;

        emit CraftingPowerDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Revokes an active crafting delegation from the sender.
     * The previously delegated address will no longer be able to craft on behalf of the sender.
     */
    function revokeCraftingPower() external onlyMember {
        address delegatee;
        // Find the delegatee who is crafting *for* the sender
        // This requires iterating or a reverse mapping. Let's use iteration for simplicity in this example.
        // In a high-throughput scenario, a mapping from delegator to delegatee would be better.
        bool found = false;
        // Iterate through potential delegatees (not efficient for large member lists)
        // A better pattern is mapping `delegator => delegatee`. Let's refactor delegation to use that.
        // Refactoring Delegation State:
        // Use mapping `delegator => delegatee`.
        // `_crafterDelegations[delegator]` stores the `delegatee`. `address(0)` means no delegation.
        // When checking `onlyMemberOrDelegatee`, check `members[msg.sender].isMember` OR `_crafterDelegations[memberWhoDelegated] == msg.sender`.
        // Need a way to find which member delegated to `msg.sender` efficiently or check if `msg.sender` is *any* delegatee.
        // Simplest check for `onlyMemberOrDelegatee`: Is `msg.sender` a member OR is `msg.sender`'s address present as a *value* in the `_crafterDelegations` mapping? The latter is hard/inefficient to check.
        // Let's stick to the original mapping `delegatee => delegator`.
        // `_crafterDelegations[delegatee]` stores the `delegator`.
        // `onlyMemberOrDelegatee` checks `members[msg.sender].isMember || _crafterDelegations[msg.sender] != address(0)`. This works.
        // `generateArtifact`/`upgradeArtifact` logic: `address delegator = _crafterDelegations[msg.sender] != address(0) ? _crafterDelegations[msg.sender] : msg.sender;` This correctly finds the account whose resources/artifacts are used.
        // `revokeCraftingPower`: This means the sender (delegator) wants to stop someone crafting for them. The mapping we need to clear is `_crafterDelegations[delegatee]` where `_crafterDelegations[delegatee] == msg.sender`. This still requires iteration or a reverse map.

        // Let's add a mapping `delegator => delegatee` for efficient lookup during revoke.
        // `_delegatorToDelegatee[delegator]` stores the `delegatee`.
        mapping(address => address) private _delegatorToDelegatee;
        // Update `delegateCraftingPower`:
        // `_delegatorToDelegatee[msg.sender] = delegatee;`
        // `_crafterDelegations[delegatee] = msg.sender;` (Keep this for `onlyMemberOrDelegatee` check)
        // Check conflict: `_delegatorToDelegatee[msg.sender] != address(0)`
        // Revoke:
        // Check if `_delegatorToDelegatee[msg.sender] != address(0)`.
        // Get delegatee: `delegatee = _delegatorToDelegatee[msg.sender];`
        // Clear mappings: `delete _delegatorToDelegatee[msg.sender]; delete _crafterDelegations[delegatee];`

        delegatee = _delegatorToDelegatee[msg.sender];

        if (delegatee == address(0)) revert Guild__NoDelegationActive(); // No delegation from sender

        delete _delegatorToDelegatee[msg.sender];
        delete _crafterDelegations[delegatee]; // Clear the reverse mapping too

        emit CraftingPowerRevoked(msg.sender, delegatee);
    }

    // --- View Functions ---

    /**
     * @dev Gets the value of a core guild parameter.
     * @param key The bytes32 key identifier.
     * @return The uint256 value of the parameter.
     */
    function getGuildParameter(bytes32 key) external view returns (uint256) {
        return guildParameters[key];
    }

    /**
     * @dev Gets information about a resource type.
     * @param resourceTypeId The ID of the resource type.
     * @return The ResourceInfo struct.
     */
    function getResourceInfo(uint256 resourceTypeId) external view returns (ResourceInfo memory) {
        if (!resourceTypes[resourceTypeId].exists) revert Guild__ResourceDoesNotExist(resourceTypeId);
        return resourceTypes[resourceTypeId];
    }

    /**
     * @dev Gets information about a generation rule.
     * @param ruleId The ID of the rule.
     * @return The GenerationRule struct.
     */
    function getGenerationRule(uint256 ruleId) external view returns (GenerationRule memory) {
        if (!generationRules[ruleId].exists) revert Guild__GenerationRuleDoesNotExist(ruleId);
        return generationRules[ruleId];
    }

    /**
     * @dev Gets the properties array of an artifact.
     * @param artifactId The ID of the artifact.
     * @return An array of uint256 properties.
     */
    function getArtifactProperties(uint256 artifactId) external view artifactExists(artifactId) returns (uint256[] memory) {
        return _artifacts[artifactId].properties;
    }

     /**
     * @dev Gets the owner of an artifact.
     * @param artifactId The ID of the artifact.
     * @return The owner's address.
     */
    function getArtifactOwner(uint256 artifactId) external view artifactExists(artifactId) returns (address) {
        return _artifacts[artifactId].owner;
    }

    /**
     * @dev Lists the IDs of artifacts owned by a specific member.
     * @param member The address of the member.
     * @return An array of artifact IDs.
     */
    function listMemberArtifacts(address member) external view returns (uint256[] memory) {
        return _memberArtifacts[member];
    }

    /**
     * @dev Gets the balance of a specific resource type for a member.
     * @param member The address of the member.
     * @param resourceTypeId The ID of the resource type.
     * @return The balance amount.
     */
    function getResourceBalance(address member, uint256 resourceTypeId) external view returns (uint256) {
        return resourceBalances[member][resourceTypeId];
    }

     /**
     * @dev Checks if an address is currently a guild member.
     * @param account The address to check.
     * @return True if the account is a member, false otherwise.
     */
    function isMember(address account) external view returns (bool) {
        return members[account].isMember;
    }

     /**
     * @dev Checks if an address is currently a guild admin.
     * @param account The address to check.
     * @return True if the account is an admin, false otherwise.
     */
    function isAdmin(address account) external view returns (bool) {
        return members[account].isAdmin;
    }

    /**
     * @dev Gets the address that a member has delegated their crafting power to.
     * @param delegator The address of the member who might have delegated.
     * @return The delegatee's address, or address(0) if no active delegation from this member.
     */
    function getDelegatedCrafter(address delegator) external view returns (address) {
        return _delegatorToDelegatee[delegator];
    }

    /**
     * @dev Gets the total number of artifacts ever generated.
     * @return The total artifact count.
     */
    function getTotalArtifacts() external view returns (uint256) {
        return nextArtifactId - 1; // nextArtifactId is the ID for the *next* one, so total count is currentId - 1
    }

    // Fallback function to receive Ether for membership fees etc.
    receive() external payable {}
    fallback() external payable {}
}
```