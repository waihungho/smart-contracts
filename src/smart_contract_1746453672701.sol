Okay, here is a Solidity smart contract incorporating concepts like on-chain progression (Karma/Skill/Ability points), time-based decay, delegation of abilities/points, and conditional function execution based on earned traits. It aims to be distinct from standard token/DeFi/NFT patterns by focusing on user reputation and capability building within the contract's domain.

This contract simulates a system where users earn 'Karma' by performing actions, convert Karma into 'Skill Points', and spend Skill Points to unlock specific 'Abilities' which grant them access to special functions or effects within this contract's ecosystem. Karma decays over time. Users can also delegate the use of their Karma/Skills or specific Abilities to others.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Progression & Capability Contract (DPCC)
 * @author Your Name/Alias (or leave as is)
 * @notice This contract implements a system for tracking user progression via Karma, Skill Points, and unlockable Abilities.
 * It includes features like time-based Karma decay, delegation of point usage and abilities, and conditional function execution.
 * It is designed as a base or component for applications requiring on-chain reputation, progression, or capability gating.
 */

/**
 * Outline:
 * 1. State Variables: Contract parameters, user data (Karma, Skills, Abilities), delegation maps, system state.
 * 2. Events: Signalling key state changes (KarmaEarned, SkillPointsConverted, AbilityUnlocked, etc.).
 * 3. Modifiers: Access control (owner), system state (paused), capability check (has ability).
 * 4. Structs: Data structures for complex types (KarmaState, AbilityDefinition).
 * 5. Internal Helpers: Core logic like karma decay calculation.
 * 6. Owner Functions: System configuration and emergency controls.
 * 7. User Functions: Earning points, spending points, unlocking abilities, interacting conditionally, delegation.
 * 8. Query Functions: Reading user data, system parameters, ability details.
 */

/**
 * Function Summary:
 * - Constructor: Initializes the contract owner.
 * - OWNER FUNCTIONS:
 *   - setKarmaRatePerAction: Sets the multiplier for karma earned per unit of 'actionValue'.
 *   - setSkillPointCost: Sets the amount of karma required to gain 1 skill point.
 *   - setAbilityCost: Sets the skill point cost for a specific ability.
 *   - setKarmaDecayRate: Sets the rate at which karma decays over time (per second).
 *   - defineAbility: Creates or updates an ability definition including prerequisites.
 *   - updateAbilityDefinition: Allows modifying an existing ability definition.
 *   - removeAbilityDefinition: Removes an ability definition.
 *   - pauseSystem: Pauses core user interaction functions.
 *   - unpauseSystem: Unpauses the system.
 *   - slashKarmaOrSkillPoints: Reduces a user's karma or skill points (emergency/penalty).
 *   - renounceOwnership: Transfers ownership to zero address.
 *   - transferOwnership: Transfers ownership to a new address.
 * - USER FUNCTIONS:
 *   - performActionToEarnKarma: User calls this to potentially earn karma based on an 'actionValue'.
 *   - convertKarmaToSkillPoints: User converts available karma into skill points.
 *   - unlockAbility: User spends skill points to unlock a defined ability, checking prerequisites.
 *   - useAbility: Placeholder/example function that requires a specific ability modifier.
 *   - delegateKarmaSpend: Allows another address to spend the user's karma (e.g., for conversion).
 *   - delegateSkillPointSpend: Allows another address to spend the user's skill points (e.g., for unlocking abilities).
 *   - delegateAbilityUse: Allows another address to use a specific ability on the user's behalf.
 *   - revokeDelegation: Revokes a specific delegation type to an address.
 *   - triggerKarmaDecayUpdate: Allows a user to manually trigger their karma decay calculation (optional, often done implicitly).
 * - DELEGATED FUNCTIONS:
 *   - executeDelegatedKarmaConversion: Delegate converts delegator's karma to skill points.
 *   - executeDelegatedAbilityUnlock: Delegate unlocks an ability for the delegator using their skill points.
 *   - executeDelegatedAbilityUse: Delegate uses an ability on behalf of the delegator.
 * - QUERY FUNCTIONS:
 *   - getKarmaPoints: Gets a user's current karma points (after applying decay).
 *   - getSkillPoints: Gets a user's current skill points.
 *   - hasAbility: Checks if a user has unlocked a specific ability.
 *   - getAbilityDefinition: Gets the details of a defined ability.
 *   - getUnlockedAbilities: Gets the list of abilities a user has unlocked.
 *   - getKarmaRatePerAction: Gets the current karma rate per action value.
 *   - getSkillPointCost: Gets the current karma cost per skill point.
 *   - getAbilityCost: Gets the skill point cost for a specific ability.
 *   - getKarmaDecayRate: Gets the current karma decay rate per second.
 *   - isPaused: Checks if the system is paused.
 *   - checkKarmaDelegation: Checks if an address is delegated to spend another's karma.
 *   - checkSkillPointDelegation: Checks if an address is delegated to spend another's skill points.
 *   - checkAbilityDelegation: Checks if an address is delegated to use a specific ability for another.
 *   - checkAbilityPrerequisites: Checks if a user meets the prerequisites to unlock a specific ability.
 */

contract DecentralizedProgressionCapability {

    // --- State Variables ---

    address public owner;
    bool public paused = false;

    struct KarmaState {
        uint256 amount;
        uint40 lastUpdateTimestamp; // Using uint40 is sufficient for timestamps and saves gas
    }

    // User addresses mapped to their Karma state
    mapping(address => KarmaState) private userKarma;
    // User addresses mapped to their Skill Points
    mapping(address => uint256) private userSkillPoints;
    // User addresses mapped to their unlocked abilities (abilityId => bool)
    mapping(address => mapping(uint256 => bool)) private userUnlockedAbilities;

    struct AbilityDefinition {
        uint256 abilityId;
        string name; // e.g., "Master Miner", "Negotiator Pro"
        uint256 skillPointCost;
        uint256[] prerequisiteAbilityIds; // Abilities required *before* unlocking this one
        bool exists; // To check if definition exists
    }

    // Ability IDs mapped to their definitions
    mapping(uint256 => AbilityDefinition) private abilityDefinitions;
    uint256 private nextAbilityId = 1; // Counter for new ability definitions

    // System parameters
    uint256 public karmaRatePerAction = 1 ether; // Default rate: 1 karma per action value unit
    uint256 public skillPointCost = 10 ether; // Default: 10 karma per skill point
    uint256 public karmaDecayRatePerSecond = 1000; // Default: 1000 wei karma per second (adjust units)

    // Delegation mappings: delegator => delegatee => status
    mapping(address => mapping(address => bool)) private karmaSpendDelegation;
    mapping(address => mapping(address => bool)) private skillPointSpendDelegation;
    // Delegation per ability: delegator => delegatee => abilityId => status
    mapping(address => mapping(address => mapping(uint256 => bool))) private abilityUseDelegation;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event KarmaEarned(address indexed user, uint256 amount, uint256 newTotalKarma);
    event KarmaDecayed(address indexed user, uint256 amount, uint256 newTotalKarma);
    event SkillPointsConverted(address indexed user, uint256 karmaSpent, uint256 skillPointsEarned, uint256 newTotalSkillPoints);
    event AbilityDefined(uint256 indexed abilityId, string name, uint256 skillPointCost);
    event AbilityUnlocked(address indexed user, uint256 indexed abilityId, uint256 skillPointsSpent);
    event KarmaOrSkillPointsSlashed(address indexed user, uint256 slashedKarma, uint256 slashedSkillPoints);

    event KarmaSpendDelegated(address indexed delegator, address indexed delegatee, bool status);
    event SkillPointSpendDelegated(address indexed delegator, address indexed delegatee, bool status);
    event AbilityUseDelegated(address indexed delegator, address indexed delegatee, uint256 indexed abilityId, bool status);

    event ConditionalActionExecuted(address indexed user, uint256 indexed abilityId, bytes data);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier hasAbility(uint256 _abilityId) {
        require(userUnlockedAbilities[msg.sender][_abilityId], "Capability: requires specific ability");
        _;
    }

    // Modifier for checking if a delegatee is authorized for karma actions
    modifier onlyKarmaDelegatee(address _delegator) {
        require(karmaSpendDelegation[_delegator][msg.sender], "Delegation: Not authorized for karma actions");
        _;
    }

    // Modifier for checking if a delegatee is authorized for skill point actions
    modifier onlySkillPointDelegatee(address _delegator) {
        require(skillPointSpendDelegation[_delegator][msg.sender], "Delegation: Not authorized for skill point actions");
        _;
    }

     // Modifier for checking if a delegatee is authorized for specific ability use
    modifier onlyAbilityDelegatee(address _delegator, uint256 _abilityId) {
        require(abilityUseDelegation[_delegator][msg.sender][_abilityId], "Delegation: Not authorized for this ability use");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates and applies karma decay for a user.
     * Updates the user's karma balance and last update timestamp.
     * @param _user The address of the user.
     */
    function _calculateAndDecayKarma(address _user) internal {
        KarmaState storage state = userKarma[_user];
        uint40 currentTime = uint40(block.timestamp); // Use uint40 for safety

        if (state.lastUpdateTimestamp == 0) {
            // First interaction, set timestamp without decay
             state.lastUpdateTimestamp = currentTime;
             return;
        }

        uint256 elapsedTime = currentTime - state.lastUpdateTimestamp;
        uint256 decayAmount = elapsedTime * karmaDecayRatePerSecond;

        if (decayAmount > 0) {
            uint256 oldKarma = state.amount;
            state.amount = state.amount > decayAmount ? state.amount - decayAmount : 0;

            if (state.amount != oldKarma) {
                 emit KarmaDecayed(_user, oldKarma - state.amount, state.amount);
            }
        }
        state.lastUpdateTimestamp = currentTime; // Always update timestamp
    }

    /**
     * @dev Internal function to add karma to a user, handles decay first.
     * @param _user The address of the user.
     * @param _amount The amount of karma to add.
     */
    function _addKarma(address _user, uint256 _amount) internal {
        _calculateAndDecayKarma(_user); // Apply decay before adding
        userKarma[_user].amount += _amount;
        emit KarmaEarned(_user, _amount, userKarma[_user].amount);
    }

    /**
     * @dev Internal function to deduct karma from a user, handles decay first.
     * Reverts if insufficient karma after decay.
     * @param _user The address of the user.
     * @param _amount The amount of karma to deduct.
     */
    function _deductKarma(address _user, uint256 _amount) internal {
        _calculateAndDecayKarma(_user); // Apply decay before deducting
        require(userKarma[_user].amount >= _amount, "Karma: Insufficient karma");
        userKarma[_user].amount -= _amount;
    }

     /**
     * @dev Internal function to deduct skill points from a user.
     * Reverts if insufficient skill points.
     * @param _user The address of the user.
     * @param _amount The amount of skill points to deduct.
     */
    function _deductSkillPoints(address _user, uint256 _amount) internal {
        require(userSkillPoints[_user] >= _amount, "Skills: Insufficient skill points");
        userSkillPoints[_user] -= _amount;
    }


    // --- Owner Functions ---

    /**
     * @dev Sets the multiplier for karma earned per unit of 'actionValue'.
     * @param _rate The new karma rate.
     */
    function setKarmaRatePerAction(uint256 _rate) external onlyOwner {
        karmaRatePerAction = _rate;
    }

    /**
     * @dev Sets the amount of karma required to gain 1 skill point.
     * @param _cost The new skill point cost.
     */
    function setSkillPointCost(uint256 _cost) external onlyOwner {
        skillPointCost = _cost;
    }

    /**
     * @dev Sets the rate at which karma decays over time (per second).
     * @param _rate The new decay rate (wei karma per second).
     */
    function setKarmaDecayRate(uint256 _rate) external onlyOwner {
        karmaDecayRatePerSecond = _rate;
    }

    /**
     * @dev Defines or updates an ability. Can only add new abilities or update existing ones.
     * Requires owner permissions.
     * @param _abilityId Optional: ID of the ability to update. If 0, a new ID is generated.
     * @param _name The name of the ability.
     * @param _skillPointCost The skill point cost to unlock this ability.
     * @param _prerequisiteAbilityIds Array of ability IDs required as prerequisites.
     * @return The ID of the defined or updated ability.
     */
    function defineAbility(
        uint256 _abilityId,
        string calldata _name,
        uint256 _skillPointCost,
        uint256[] calldata _prerequisiteAbilityIds
    ) external onlyOwner returns (uint256) {
        uint256 currentAbilityId = _abilityId;
        if (currentAbilityId == 0) {
            currentAbilityId = nextAbilityId++;
        } else {
            require(abilityDefinitions[currentAbilityId].exists, "Ability: ID does not exist");
        }

        // Basic check for self-prerequisite or circular dependencies (can be expanded)
        for(uint i = 0; i < _prerequisiteAbilityIds.length; i++) {
            require(_prerequisiteAbilityIds[i] != currentAbilityId, "Ability: Cannot be prerequisite for itself");
             // Note: Detecting complex cycles requires more sophisticated graph traversal,
             // which is too gas-intensive for on-chain. Assumes reasonable definition setting.
        }


        abilityDefinitions[currentAbilityId] = AbilityDefinition(
            currentAbilityId,
            _name,
            _skillPointCost,
            _prerequisiteAbilityIds,
            true // Mark as existing
        );

        emit AbilityDefined(currentAbilityId, _name, _skillPointCost);
        return currentAbilityId;
    }

     /**
     * @dev Updates an existing ability definition. Cannot create new abilities.
     * Requires owner permissions.
     * @param _abilityId ID of the ability to update. Must exist.
     * @param _name The new name of the ability.
     * @param _skillPointCost The new skill point cost.
     * @param _prerequisiteAbilityIds New array of ability IDs required as prerequisites.
     */
    function updateAbilityDefinition(
        uint256 _abilityId,
        string calldata _name,
        uint256 _skillPointCost,
        uint256[] calldata _prerequisiteAbilityIds
    ) external onlyOwner {
        require(abilityDefinitions[_abilityId].exists, "Ability: ID does not exist");

        for(uint i = 0; i < _prerequisiteAbilityIds.length; i++) {
            require(_prerequisiteAbilityIds[i] != _abilityId, "Ability: Cannot be prerequisite for itself");
        }

        abilityDefinitions[_abilityId].name = _name;
        abilityDefinitions[_abilityId].skillPointCost = _skillPointCost;
        abilityDefinitions[_abilityId].prerequisiteAbilityIds = _prerequisiteAbilityIds; // This replaces the entire array

        emit AbilityDefined(_abilityId, _name, _skillPointCost); // Reuse event for update
    }

    /**
     * @dev Removes an ability definition. Does NOT remove the ability from users who already unlocked it.
     * Requires owner permissions.
     * @param _abilityId ID of the ability to remove. Must exist.
     */
    function removeAbilityDefinition(uint256 _abilityId) external onlyOwner {
        require(abilityDefinitions[_abilityId].exists, "Ability: ID does not exist");
        // Simply mark as not existing, mapping entry remains but 'exists' is false.
        // Could delete, but might lose info if ID is reused carelessly. Mark is safer.
        abilityDefinitions[_abilityId].exists = false;
        // emit AbilityRemoved(_abilityId); // Could add a specific event
    }


    /**
     * @dev Pauses core user interaction functions (earning, converting, unlocking).
     * Requires owner permissions.
     */
    function pauseSystem() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the system.
     * Requires owner permissions.
     */
    function unpauseSystem() external onlyOwner {
        require(paused, "Pausable: not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows owner to slash (reduce) a user's karma or skill points.
     * Can be used for penalties or adjustments.
     * @param _user The address of the user.
     * @param _karmaAmount The amount of karma to remove.
     * @param _skillPointAmount The amount of skill points to remove.
     */
    function slashKarmaOrSkillPoints(address _user, uint256 _karmaAmount, uint256 _skillPointAmount) external onlyOwner {
        _calculateAndDecayKarma(_user); // Apply decay before slashing karma

        uint256 slashedKarma = 0;
        if (userKarma[_user].amount >= _karmaAmount) {
            userKarma[_user].amount -= _karmaAmount;
            slashedKarma = _karmaAmount;
        } else {
            slashedKarma = userKarma[_user].amount;
            userKarma[_user].amount = 0;
        }

        uint256 slashedSkillPoints = 0;
        if (userSkillPoints[_user] >= _skillPointAmount) {
            userSkillPoints[_user] -= _skillPointAmount;
            slashedSkillPoints = _skillPointAmount;
        } else {
            slashedSkillPoints = userSkillPoints[_user];
            userSkillPoints[_user] = 0;
        }

        emit KarmaOrSkillPointsSlashed(_user, slashedKarma, slashedSkillPoints);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    // --- User Functions ---

    /**
     * @dev User performs an action that grants karma. The actual logic determining
     * 'actionValue' would likely be external or calculated differently in a real system.
     * Here, it's a simple parameter.
     * @param _actionValue A value representing the magnitude or type of the action.
     */
    function performActionToEarnKarma(uint256 _actionValue) external whenNotPaused {
        uint256 karmaEarned = _actionValue * karmaRatePerAction;
        _addKarma(msg.sender, karmaEarned);
    }

    /**
     * @dev User converts earned karma into skill points.
     * Consumes karma, grants skill points based on the current cost.
     * @param _karmaAmountToConvert The amount of karma the user wishes to convert.
     */
    function convertKarmaToSkillPoints(uint256 _karmaAmountToConvert) external whenNotPaused {
         require(_karmaAmountToConvert > 0, "Conversion: Amount must be positive");
        _deductKarma(msg.sender, _karmaAmountToConvert); // Deducts karma (applies decay implicitly)

        uint256 skillPointsEarned = _karmaAmountToConvert / skillPointCost;
        require(skillPointsEarned > 0, "Conversion: Not enough karma for any skill points");

        userSkillPoints[msg.sender] += skillPointsEarned;

        emit SkillPointsConverted(msg.sender, _karmaAmountToConvert, skillPointsEarned, userSkillPoints[msg.sender]);
    }

    /**
     * @dev User unlocks a specific ability by spending skill points.
     * Checks if the ability exists, user has enough skill points, and user meets prerequisites.
     * Prevents unlocking already unlocked abilities.
     * @param _abilityId The ID of the ability to unlock.
     */
    function unlockAbility(uint256 _abilityId) external whenNotPaused {
        AbilityDefinition storage abilityDef = abilityDefinitions[_abilityId];
        require(abilityDef.exists, "Ability: Definition does not exist");
        require(!userUnlockedAbilities[msg.sender][_abilityId], "Ability: Already unlocked");
        require(userSkillPoints[msg.sender] >= abilityDef.skillPointCost, "Skills: Insufficient skill points to unlock");

        // Check prerequisites
        for (uint256 i = 0; i < abilityDef.prerequisiteAbilityIds.length; i++) {
            uint256 prereqId = abilityDef.prerequisiteAbilityIds[i];
            require(userUnlockedAbilities[msg.sender][prereqId], string.concat("Ability: Prerequisite not met - ", Strings.toString(prereqId)));
            require(abilityDefinitions[prereqId].exists, string.concat("Ability: Prerequisite does not exist - ", Strings.toString(prereqId))); // Ensure prerequisite is a valid, existing ability
        }

        _deductSkillPoints(msg.sender, abilityDef.skillPointCost);
        userUnlockedAbilities[msg.sender][_abilityId] = true;

        emit AbilityUnlocked(msg.sender, _abilityId, abilityDef.skillPointCost);
    }

    /**
     * @dev Example function showing how an ability can gate functionality.
     * Requires the caller to have the specified ability.
     * The actual effect/payload of the action is represented by the `data` parameter and event.
     * @param _abilityId The ability required to execute this action.
     * @param data Arbitrary data describing the specific action details (ABI encoded function call, JSON string, etc.).
     */
    function useAbility(uint256 _abilityId, bytes calldata data) external hasAbility(_abilityId) {
        // Internal logic for the ability's effect would go here.
        // This could involve interacting with other parts of the contract, or simply serving as a log.
        // For this example, it just emits an event.
        emit ConditionalActionExecuted(msg.sender, _abilityId, data);
    }

    /**
     * @dev Allows the user to delegate the ability to spend their karma to another address.
     * @param _delegatee The address to delegate to.
     * @param _status True to grant delegation, false to revoke.
     */
    function delegateKarmaSpend(address _delegatee, bool _status) external {
        require(_delegatee != msg.sender, "Delegation: Cannot delegate to self");
        karmaSpendDelegation[msg.sender][_delegatee] = _status;
        emit KarmaSpendDelegated(msg.sender, _delegatee, _status);
    }

    /**
     * @dev Allows the user to delegate the ability to spend their skill points to another address.
     * @param _delegatee The address to delegate to.
     * @param _status True to grant delegation, false to revoke.
     */
    function delegateSkillPointSpend(address _delegatee, bool _status) external {
        require(_delegatee != msg.sender, "Delegation: Cannot delegate to self");
        skillPointSpendDelegation[msg.sender][_delegatee] = _status;
        emit SkillPointSpendDelegated(msg.sender, _delegatee, _status);
    }

    /**
     * @dev Allows the user to delegate the ability to *use* a specific unlocked ability on their behalf.
     * @param _delegatee The address to delegate to.
     * @param _abilityId The ID of the ability to delegate usage for.
     * @param _status True to grant delegation, false to revoke.
     */
    function delegateAbilityUse(address _delegatee, uint256 _abilityId, bool _status) external {
        require(_delegatee != msg.sender, "Delegation: Cannot delegate to self");
        require(userUnlockedAbilities[msg.sender][_abilityId], "Delegation: Cannot delegate an unowned ability");
        abilityUseDelegation[msg.sender][_delegatee][_abilityId] = _status;
        emit AbilityUseDelegated(msg.sender, _delegatee, _abilityId, _status);
    }

    /**
     * @dev Revokes all delegation rights granted to a specific address by the caller.
     * A convenience function.
     * @param _delegatee The address whose delegation rights to revoke.
     */
    function revokeDelegation(address _delegatee) external {
        karmaSpendDelegation[msg.sender][_delegatee] = false;
        skillPointSpendDelegation[msg.sender][_delegatee] = false;
        // Cannot easily revoke *all* ability delegations in a gas-efficient way
        // without iterating over abilityIds. A per-ability revocation is needed.
        // For simplicity, this function only revokes the point spending delegations.
        emit KarmaSpendDelegated(msg.sender, _delegatee, false);
        emit SkillPointSpendDelegated(msg.sender, _delegatee, false);
         // AbilityUseDelegated event would need to be emitted per ability revoked.
         // Omitting for gas/complexity, user can call delegateAbilityUse(_, _, false).
    }

     /**
     * @dev Allows a user to explicitly trigger the calculation and application of their karma decay.
     * This isn't strictly necessary as it happens implicitly on state-changing calls,
     * but can be useful for users wanting to see their 'true' current balance reflecting decay.
     */
    function triggerKarmaDecayUpdate() external {
        _calculateAndDecayKarma(msg.sender);
    }


    // --- Delegated Functions ---

    /**
     * @dev Allows a delegated address to convert the delegator's karma to skill points.
     * @param _delegator The address whose karma is being converted.
     * @param _karmaAmountToConvert The amount of delegator's karma to convert.
     */
    function executeDelegatedKarmaConversion(address _delegator, uint256 _karmaAmountToConvert)
        external
        whenNotPaused
        onlyKarmaDelegatee(_delegator)
    {
         require(_karmaAmountToConvert > 0, "Conversion: Amount must be positive");
        _deductKarma(_delegator, _karmaAmountToConvert); // Deducts karma (applies decay implicitly)

        uint256 skillPointsEarned = _karmaAmountToConvert / skillPointCost;
        require(skillPointsEarned > 0, "Conversion: Not enough karma for any skill points");

        userSkillPoints[_delegator] += skillPointsEarned;

        emit SkillPointsConverted(_delegator, _karmaAmountToConvert, skillPointsEarned, userSkillPoints[_delegator]);
    }

    /**
     * @dev Allows a delegated address to unlock an ability for the delegator using their skill points.
     * @param _delegator The address for whom the ability is being unlocked.
     * @param _abilityId The ID of the ability to unlock for the delegator.
     */
    function executeDelegatedAbilityUnlock(address _delegator, uint256 _abilityId)
        external
        whenNotPaused
        onlySkillPointDelegatee(_delegator)
    {
        AbilityDefinition storage abilityDef = abilityDefinitions[_abilityId];
        require(abilityDef.exists, "Ability: Definition does not exist");
        require(!userUnlockedAbilities[_delegator][_abilityId], "Ability: Already unlocked");
        require(userSkillPoints[_delegator] >= abilityDef.skillPointCost, "Skills: Insufficient skill points to unlock");

        // Check prerequisites FOR THE DELEGATOR
        for (uint256 i = 0; i < abilityDef.prerequisiteAbilityIds.length; i++) {
            uint256 prereqId = abilityDef.prerequisiteAbilityIds[i];
            require(userUnlockedAbilities[_delegator][prereqId], string.concat("Ability: Prerequisite not met for delegator - ", Strings.toString(prereqId)));
             require(abilityDefinitions[prereqId].exists, string.concat("Ability: Prerequisite does not exist - ", Strings.toString(prereqId))); // Ensure prerequisite is valid
        }

        _deductSkillPoints(_delegator, abilityDef.skillPointCost);
        userUnlockedAbilities[_delegator][_abilityId] = true;

        emit AbilityUnlocked(_delegator, _abilityId, abilityDef.skillPointCost);
    }

     /**
     * @dev Allows a delegated address to use a specific ability on behalf of the delegator.
     * @param _delegator The address on whose behalf the ability is used.
     * @param _abilityId The ability required to execute this action.
     * @param data Arbitrary data describing the specific action details.
     */
    function executeDelegatedAbilityUse(address _delegator, uint256 _abilityId, bytes calldata data)
        external
        onlyAbilityDelegatee(_delegator, _abilityId) // Checks if delegatee is authorized for this specific ability for delegator
    {
        // Check if the DELEGATOR actually has the ability
        require(userUnlockedAbilities[_delegator][_abilityId], "Capability: Delegator requires specific ability");

        // Internal logic for the ability's effect would go here.
        // For this example, it just emits an event, noting it's a delegated action.
        emit ConditionalActionExecuted(_delegator, _abilityId, data); // Log event for delegator
        // Could also log an event for the delegatee if needed.
    }


    // --- Query Functions ---

    /**
     * @dev Gets a user's current karma points, applying decay first.
     * @param _user The address of the user.
     * @return The user's current karma amount.
     */
    function getKarmaPoints(address _user) public view returns (uint256) {
         KarmaState storage state = userKarma[_user];
         uint40 currentTime = uint40(block.timestamp);

         if (state.lastUpdateTimestamp == 0 || state.amount == 0 || karmaDecayRatePerSecond == 0) {
             return state.amount; // No decay if never updated, amount is zero, or decay rate is zero
         }

         uint256 elapsedTime = currentTime - state.lastUpdateTimestamp;
         uint256 decayAmount = elapsedTime * karmaDecayRatePerSecond;

         return state.amount > decayAmount ? state.amount - decayAmount : 0;
    }

     /**
     * @dev Gets a user's current skill points.
     * @param _user The address of the user.
     * @return The user's current skill point amount.
     */
    function getSkillPoints(address _user) external view returns (uint256) {
        return userSkillPoints[_user];
    }

    /**
     * @dev Checks if a user has unlocked a specific ability.
     * @param _user The address of the user.
     * @param _abilityId The ID of the ability to check.
     * @return True if the user has the ability, false otherwise.
     */
    function hasAbility(address _user, uint256 _abilityId) external view returns (bool) {
        return userUnlockedAbilities[_user][_abilityId];
    }

     /**
     * @dev Gets the definition details for a specific ability ID.
     * @param _abilityId The ID of the ability.
     * @return The ability's ID, name, skill point cost, prerequisite ability IDs, and existence status.
     */
    function getAbilityDefinition(uint256 _abilityId) external view returns (AbilityDefinition memory) {
        return abilityDefinitions[_abilityId];
    }

    /**
     * @dev Gets the skill point cost for a specific ability ID.
     * @param _abilityId The ID of the ability.
     * @return The skill point cost. Returns 0 if ability does not exist.
     */
     function getAbilityCost(uint256 _abilityId) external view returns (uint256) {
         if (!abilityDefinitions[_abilityId].exists) {
             return 0;
         }
         return abilityDefinitions[_abilityId].skillPointCost;
     }

    /**
     * @dev Gets a list of ability IDs unlocked by a user.
     * NOTE: This function can be gas-intensive if a user has unlocked a large number of abilities.
     * Consider off-chain indexing for systems expecting many unlocked abilities per user.
     * @param _user The address of the user.
     * @return An array of ability IDs unlocked by the user.
     */
    function getUnlockedAbilities(address _user) external view returns (uint256[] memory) {
        // Iterating over mappings is not possible directly.
        // A common pattern is to track unlocked abilities in a dynamic array for each user,
        // but this adds significant complexity and gas cost to the unlock process.
        // A simpler alternative for query is to iterate possible ability IDs up to `nextAbilityId`.
        // This is also gas-intensive if `nextAbilityId` is large.
        // A truly scalable solution requires off-chain data indexing.
        // For demonstration, we will iterate up to nextAbilityId.

        uint256[] memory unlocked; // Initialize empty array

        // First pass to count unlocked abilities for size calculation
        uint256 count = 0;
        for (uint256 i = 1; i < nextAbilityId; i++) {
            if (abilityDefinitions[i].exists && userUnlockedAbilities[_user][i]) {
                count++;
            }
        }

        if (count > 0) {
            unlocked = new uint256[](count);
            uint256 currentIndex = 0;
            for (uint256 i = 1; i < nextAbilityId; i++) {
                 // Check if the definition exists is important!
                if (abilityDefinitions[i].exists && userUnlockedAbilities[_user][i]) {
                    unlocked[currentIndex] = i;
                    currentIndex++;
                }
            }
        } else {
             // Return empty array if count is 0
             unlocked = new uint256[](0);
        }

        return unlocked;
    }


    /**
     * @dev Gets the current karma rate per action value.
     * @return The current rate.
     */
    function getKarmaRatePerAction() external view returns (uint256) {
        return karmaRatePerAction;
    }

    /**
     * @dev Gets the current karma cost per skill point.
     * @return The current cost.
     */
    function getSkillPointCost() external view returns (uint256) {
        return skillPointCost;
    }

    /**
     * @dev Gets the current karma decay rate per second.
     * @return The current rate.
     */
    function getKarmaDecayRate() external view returns (uint256) {
        return karmaDecayRatePerSecond;
    }

    /**
     * @dev Checks if the system is paused.
     * @return True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Checks if an address is delegated to spend another's karma.
     * @param _delegator The address who potentially delegated.
     * @param _delegatee The address who is potentially delegated.
     * @return True if delegated, false otherwise.
     */
    function checkKarmaDelegation(address _delegator, address _delegatee) external view returns (bool) {
        return karmaSpendDelegation[_delegator][_delegatee];
    }

    /**
     * @dev Checks if an address is delegated to spend another's skill points.
     * @param _delegator The address who potentially delegated.
     * @param _delegatee The address who is potentially delegated.
     * @return True if delegated, false otherwise.
     */
    function checkSkillPointDelegation(address _delegator, address _delegatee) external view returns (bool) {
        return skillPointSpendDelegation[_delegator][_delegatee];
    }

     /**
     * @dev Checks if an address is delegated to use a specific ability for another.
     * @param _delegator The address who potentially delegated.
     * @param _delegatee The address who is potentially delegated.
     * @param _abilityId The ID of the ability in question.
     * @return True if delegated for this ability, false otherwise.
     */
    function checkAbilityDelegation(address _delegator, address _delegatee, uint256 _abilityId) external view returns (bool) {
        return abilityUseDelegation[_delegator][_delegatee][_abilityId];
    }


    /**
     * @dev Checks if a user meets the prerequisites to unlock a specific ability.
     * Note: This does NOT check if they have enough skill points or already have the ability.
     * @param _user The address of the user.
     * @param _abilityId The ID of the ability to check prerequisites for.
     * @return True if all prerequisites are met, false otherwise. Reverts if ability ID doesn't exist.
     */
    function checkAbilityPrerequisites(address _user, uint256 _abilityId) external view returns (bool) {
        AbilityDefinition storage abilityDef = abilityDefinitions[_abilityId];
        require(abilityDef.exists, "Ability: Definition does not exist");

        for (uint256 i = 0; i < abilityDef.prerequisiteAbilityIds.length; i++) {
            uint256 prereqId = abilityDef.prerequisiteAbilityIds[i];
            // Must check that the prerequisite itself is a valid, existing ability
             if (!abilityDefinitions[prereqId].exists || !userUnlockedAbilities[_user][prereqId]) {
                 return false;
             }
        }
        return true;
    }

    // --- Utility/Helper for toString (needed for require messages with numbers) ---
    // This is a minimal implementation, could use a library like OpenZeppelin's SafeCast/Strings
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
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
    }

}
```