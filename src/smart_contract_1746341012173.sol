Okay, let's create a sophisticated smart contract themed around a "Quantum Catalyst" — a system where users can deposit resources to generate a magical "Essence," and then use that Essence, along with other inputs, to perform "Transformations." The outcomes of these transformations can be influenced by the contract's internal "Ambient Energy State" and temporary "Quantum States," introducing elements of dynamic behavior and unpredictable outcomes. We will include concepts like timed processes, conditional logic, internal state transitions, role-based access, delegation, and various configuration/query functions to reach over 20 functions.

This contract is complex and designed for demonstration/educational purposes. A real-world implementation would require significant security audits and careful consideration of gas costs and off-chain infrastructure to manage pending transformations efficiently.

---

**Smart Contract:** `QuantumCatalyst`

**Theme:** Alchemy, Transformation, State Dynamics, Timed Processes

**Core Concepts:**
1.  **Resource Deposit & Essence Generation:** Users deposit a designated resource token to generate a utility token called "Essence". The generation rate can be configured.
2.  **Transformations:** Users spend Essence and potentially other input tokens to initiate transformations based on predefined "Recipes".
3.  **Timed Processes:** Transformations are not instant; they have a required duration.
4.  **Ambient Energy State:** The contract has a dynamic internal state variable (`AmbientEnergyState`) that can influence transformation outcomes or parameters.
5.  **Quantum States:** Temporary, rare states (`QuantumState`) can be active, providing temporary modifiers to transformations.
6.  **Parametric Transformations:** Some transformations can accept user-provided parameters that affect the outcome calculation.
7.  **Role-Based Access:** Different user roles (Owner, Alchemist, Observer) have different permissions.
8.  **Transformation Delegation:** Users can allow other addresses to initiate transformations on their behalf.
9.  **Configuration & Querying:** Extensive functions for owner/alchemist to configure recipes, rates, states, and for anyone to query the system state, recipes, and pending transformations.

**Outline:**

1.  **Imports & Interfaces:** Standard libraries and ERC20 interface.
2.  **Error Codes:** Custom errors for clarity.
3.  **Enums:** Define possible states, outcomes, and roles.
4.  **Structs:** Define the structure of transformation recipes and pending transformations.
5.  **State Variables:** Contract state, mappings for balances, recipes, pending transformations, roles, etc.
6.  **Events:** Log significant actions and state changes.
7.  **Modifiers:** Custom access control based on roles.
8.  **Constructor:** Initialize the contract with basic settings.
9.  **Role Management Functions (3+):** Grant/revoke roles, check roles.
10. **Essence Management Functions (3+):** Deposit resource, calculate generation, check balance.
11. **Transformation Recipe Management Functions (4+):** Propose, activate, deactivate, query recipes.
12. **Transformation Initiation & Completion Functions (5+):** Initiate standard/parametric transformations, check status, complete transformations, batch completion, delegate initiation.
13. **State Dynamics Functions (3+):** Update ambient energy, trigger quantum flux (influences quantum states), query states.
14. **Configuration Functions (5+):** Set resource token, update rates/costs, manage allowed input tokens, withdraw fees.
15. **Query Functions (5+):** Get role, recipe details, all recipes, pending transformations, allowed input tokens, eligibility checks.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and resource token.
2.  `grantRole(address user, Role role)`: Grants a specific role to an address (Owner only).
3.  `revokeRole(address user, Role role)`: Revokes a specific role from an address (Owner only).
4.  `getRole(address user)`: Returns the role of a user.
5.  `depositResource(uint256 amount)`: Deposits the resource token, generates Essence, and updates user balance.
6.  `calculateEssenceGeneration(uint256 resourceAmount)`: Calculates the amount of Essence that would be generated for a given resource amount. (Pure view function)
7.  `getEssenceBalance(address user)`: Returns the Essence balance of a user. (View function)
8.  `proposeTransformation(bytes32 recipeId, string name, uint256 essenceCost, uint256 duration, address outputToken, uint256 outputAmount, uint256 criticalSuccessOutputAmount, address[] inputTokens, uint256[] inputAmounts, uint256 successChance, uint256 criticalSuccessChance)`: Proposes a new transformation recipe (Alchemist+).
9.  `activateTransformationRecipe(bytes32 recipeId)`: Activates a proposed transformation recipe, making it usable (Alchemist+).
10. `deactivateTransformationRecipe(bytes32 recipeId)`: Deactivates an active transformation recipe (Alchemist+).
11. `getTransformationRecipe(bytes32 recipeId)`: Returns details of a specific transformation recipe (View function).
12. `getAllRecipes()`: Returns a list of all registered transformation recipe IDs (View function).
13. `initiateTransformation(bytes32 recipeId)`: Initiates a transformation based on a recipe, spending Essence and inputs (Requires sufficient Essence, inputs, active recipe).
14. `initiateParametricTransformation(bytes32 recipeId, uint256 parameter)`: Initiates a transformation with an additional parameter that influences outcome (Requires sufficient Essence, inputs, active recipe).
15. `getTransformationStatus(uint256 transformationId)`: Returns the status details of a pending transformation (View function).
16. `completeTransformation(uint256 transformationId)`: Completes a pending transformation after its duration has passed, determining outcome and transferring outputs.
17. `batchCompleteTransformations(uint256[] transformationIds)`: Completes multiple pending transformations in a single transaction.
18. `delegateTransformationPermission(address delegatee, uint256 limit)`: Allows a delegatee to initiate transformations on the caller's behalf up to a certain Essence cost limit (similar to ERC20 approve).
19. `checkTransformationEligibility(address user, bytes32 recipeId, uint256 parameter)`: Checks if a user is currently eligible to initiate a specific transformation, considering balance, inputs, state, and parameters. (View function)
20. `updateAmbientEnergy(AmbientEnergyState newState)`: Updates the contract's ambient energy state (Owner/Alchemist).
21. `getAmbientEnergyState()`: Returns the current ambient energy state (View function).
22. `triggerQuantumFlux()`: Introduces a potential temporary Quantum State modifier based on contract state (Owner/Alchemist with cooldown).
23. `getActiveQuantumStates()`: Returns a list of currently active Quantum States (View function).
24. `setResourceToken(address newToken)`: Sets the address of the resource token (Owner only).
25. `updateEssenceGenerationRate(uint256 newRate)`: Sets the Essence generation rate (Owner only).
26. `updateTransformationCost(bytes32 recipeId, uint256 newEssenceCost)`: Updates the Essence cost for a specific recipe (Alchemist+).
27. `addAllowedInputToken(address token)`: Adds an ERC20 token to the list of tokens that can be used as transformation inputs (Alchemist+).
28. `removeAllowedInputToken(address token)`: Removes an ERC20 token from the allowed input list (Alchemist+).
29. `withdrawAdminFees(address token, uint256 amount)`: Allows owner to withdraw specified tokens (e.g., collected input tokens or resource tokens if applicable) held by the contract (Owner only).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath is good practice with external values/complex ops
import "@openzeppelin/contracts/utils/Address.sol";

// Note: SafeMath is less critical in Solidity 0.8+ due to default overflow/underflow checks,
// but included here as a good practice for clarity and compatibility with older codebases or complex logic.
// For modern 0.8+ code, relying on native checks is usually sufficient unless dealing with raw bytes arithmetic.

contract QuantumCatalyst is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address; // For isContract check

    // --- Custom Errors ---
    error InvalidRole();
    error RecipeNotFound();
    error RecipeNotActive();
    error InsufficientEssence();
    error InsufficientInputTokens(address token);
    error TransformationInProgress(uint256 transformationId);
    error TransformationNotCompleteable(uint256 transformationId);
    error TransformationAlreadyCompleted(uint256 transformationId);
    error TransformationFailed();
    error TransformationCancelled();
    error DuplicateRecipeId();
    error TokenNotAllowedAsInput();
    error DelegationLimitExceeded();
    error NotEnoughDelegatedAllowance();
    error CannotSelfDelegate();
    error QuantumFluxOnCooldown();
    error NoActiveQuantumStates();
    error InvalidParameter();
    error NoPendingTransformations();
    error InvalidBatchCompletion();

    // --- Enums ---
    enum Role {
        None,
        Owner,      // Full control (inherited from Ownable)
        Alchemist,  // Can propose/activate recipes, manage rates, trigger flux
        Observer    // Can only query state and recipes
    }

    enum AmbientEnergyState {
        Stable,
        Volatile,
        Attuned,
        Chaotic
    }

    enum TransformationOutcome {
        Pending,
        Success,
        Failure,
        CriticalSuccess,
        QuantumShift, // Special outcome influenced by Quantum States
        Cancelled // If inputs are withdrawn early or recipe deactivated
    }

    enum QuantumState {
        None,
        Amplification, // Increases success chances
        Attenuation,   // Decreases success chances
        Mutation,      // Increases chance of QuantumShift
        Stability      // Reduces chance of Failure
    }

    // --- Structs ---
    struct TransformationRecipe {
        string name;
        uint256 essenceCost;
        uint64 duration; // In seconds
        address outputToken;
        uint256 outputAmount; // Base output on success
        uint256 criticalSuccessOutputAmount; // Higher output on critical success
        address[] inputTokens;
        uint256[] inputAmounts;
        uint256 successChance; // Out of 10000 (e.g., 7500 for 75%)
        uint256 criticalSuccessChance; // Out of 10000 (e.g., 500 for 5%)
        bool isActive;
        bool allowsParameter; // Does this recipe accept a parameter?
    }

    struct PendingTransformation {
        uint256 transformationId;
        address initiator;
        bytes32 recipeId;
        uint64 startTime;
        uint256 parameter; // Used if recipe.allowsParameter is true
        TransformationOutcome outcome;
        // Input tokens are transferred to the contract upon initiation
        // Output tokens are transferred upon completion
    }

    // --- State Variables ---
    address public resourceToken;
    uint256 public essenceGenerationRate; // Amount of Essence per unit of resource token
    mapping(address => uint256) private essenceBalances;
    mapping(address => Role) private userRoles;

    mapping(bytes32 => TransformationRecipe) private transformationRecipes;
    bytes32[] public registeredRecipeIds; // List of all recipe IDs

    uint256 private nextTransformationId = 1;
    mapping(uint256 => PendingTransformation) private pendingTransformations;
    mapping(address => uint256[]) private userPendingTransformationIds; // Track user's pending transformations

    mapping(address => mapping(address => uint256)) private transformationDelegatedAllowance; // Who can initiate transformations for whom, up to what essence cost limit

    AmbientEnergyState public currentAmbientEnergyState = AmbientEnergyState.Stable;
    mapping(QuantumState => uint64) private activeQuantumStates; // QuantumState => Expiry Timestamp (0 if inactive)

    uint64 public lastQuantumFluxTriggerTime;
    uint64 public quantumFluxCooldown = 1 days; // Cooldown period for triggering flux

    mapping(address => bool) public allowedInputTokens; // Whitelist of tokens that can be used as transformation inputs

    // --- Events ---
    event ResourceDeposited(address indexed user, uint256 amount, uint256 essenceGenerated);
    event EssenceGenerated(address indexed user, uint256 amount); // Separate event for clarity
    event RoleGranted(address indexed user, Role role);
    event RoleRevoked(address indexed user, Role role);
    event RecipeProposed(bytes32 indexed recipeId, address indexed proposer);
    event RecipeActivated(bytes32 indexed recipeId, address indexed activator);
    event RecipeDeactivated(bytes32 indexed recipeId, address indexed deactivator);
    event TransformationInitiated(uint256 indexed transformationId, address indexed initiator, bytes32 indexed recipeId, uint256 parameter);
    event TransformationCompleted(uint256 indexed transformationId, address indexed initiator, bytes32 indexed recipeId, TransformationOutcome outcome);
    event AmbientEnergyUpdated(AmbientEnergyState newState);
    event QuantumFluxTriggered(address indexed triggerer);
    event QuantumStateShift(QuantumState indexed state, uint64 expiryTime); // State became active or expired
    event TransformationDelegationUpdated(address indexed delegator, address indexed delegatee, uint256 newLimit);
    event AllowedInputTokenAdded(address indexed token);
    event AllowedInputTokenRemoved(address indexed token);

    // --- Modifiers ---
    modifier onlyRole(Role requiredRole) {
        if (userRoles[msg.sender] < requiredRole) {
            revert InvalidRole();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _resourceToken) Ownable(msg.sender) {
        resourceToken = _resourceToken;
        userRoles[owner()] = Role.Owner; // Owner has Role.Owner implicitly
        essenceGenerationRate = 100; // Default rate: 100 Essence per resource unit
        allowedInputTokens[resourceToken] = true; // Resource token is allowed as input by default
    }

    // --- Role Management Functions ---

    /// @notice Grants a specific role to a user. Only callable by the contract owner.
    /// @param user The address to grant the role to.
    /// @param role The role to grant (Alchemist or Observer). Role.None and Role.Owner cannot be granted this way.
    function grantRole(address user, Role role) public onlyOwner {
        if (role == Role.None || role == Role.Owner) revert InvalidRole();
        if (userRoles[user] == role) return; // No change
        userRoles[user] = role;
        emit RoleGranted(user, role);
    }

    /// @notice Revokes a specific role from a user. Only callable by the contract owner.
    /// @param user The address to revoke the role from.
    /// @param role The role to revoke. Cannot revoke Owner role this way.
    function revokeRole(address user, Role role) public onlyOwner {
        if (role == Role.None || role == Role.Owner) revert InvalidRole();
        if (userRoles[user] != role) return; // User doesn't have this role
        userRoles[user] = Role.None; // Revert to None
        emit RoleRevoked(user, role);
    }

    /// @notice Returns the current role of a user.
    /// @param user The address to query.
    /// @return The user's role.
    function getRole(address user) public view returns (Role) {
        if (user == owner()) return Role.Owner; // Explicitly return Owner role
        return userRoles[user];
    }

    // --- Essence Management Functions ---

    /// @notice Deposits the resource token to generate Essence.
    /// @param amount The amount of resource token to deposit.
    function depositResource(uint256 amount) public {
        if (amount == 0) revert InvalidParameter();
        IERC20 token = IERC20(resourceToken);
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 generatedEssence = amount.mul(essenceGenerationRate);
        essenceBalances[msg.sender] = essenceBalances[msg.sender].add(generatedEssence);

        emit ResourceDeposited(msg.sender, amount, generatedEssence);
        emit EssenceGenerated(msg.sender, generatedEssence);
    }

    /// @notice Calculates the amount of Essence that would be generated for a given resource amount based on the current rate.
    /// @param resourceAmount The amount of resource token.
    /// @return The calculated amount of Essence.
    function calculateEssenceGeneration(uint256 resourceAmount) public view returns (uint256) {
        return resourceAmount.mul(essenceGenerationRate);
    }

    /// @notice Returns the Essence balance of a user.
    /// @param user The address to query.
    /// @return The user's Essence balance.
    function getEssenceBalance(address user) public view returns (uint256) {
        return essenceBalances[user];
    }

    // --- Transformation Recipe Management Functions ---

    /// @notice Proposes a new transformation recipe. Recipes must be activated before use.
    /// @param recipeId A unique identifier for the recipe.
    /// @param name The name of the recipe.
    /// @param essenceCost The cost in Essence to initiate this transformation.
    /// @param duration The time in seconds required for the transformation to complete.
    /// @param outputToken The address of the token produced on success (use address(0) for no token output).
    /// @param outputAmount The base amount of outputToken produced on success.
    /// @param criticalSuccessOutputAmount The amount of outputToken produced on critical success.
    /// @param inputTokens Array of addresses for input tokens required (use address(0) for no inputs other than Essence).
    /// @param inputAmounts Array of amounts corresponding to inputTokens. Must match length of inputTokens.
    /// @param successChance The base probability of success (out of 10000).
    /// @param criticalSuccessChance The base probability of critical success (out of 10000).
    /// @param allowsParameter True if this recipe can accept a user-defined parameter influencing outcome.
    function proposeTransformation(
        bytes32 recipeId,
        string memory name,
        uint256 essenceCost,
        uint64 duration,
        address outputToken,
        uint256 outputAmount,
        uint256 criticalSuccessOutputAmount,
        address[] memory inputTokens,
        uint256[] memory inputAmounts,
        uint256 successChance,
        uint256 criticalSuccessChance,
        bool allowsParameter
    ) public onlyRole(Role.Alchemist) {
        if (transformationRecipes[recipeId].essenceCost != 0) { // Check if recipeId is already used (essenceCost is a simple check for existence)
            revert DuplicateRecipeId();
        }
        if (inputTokens.length != inputAmounts.length) revert InvalidParameter();
        if (successChance + criticalSuccessChance > 10000) revert InvalidParameter();
        if (duration == 0) revert InvalidParameter(); // Must take some time

        transformationRecipes[recipeId] = TransformationRecipe({
            name: name,
            essenceCost: essenceCost,
            duration: duration,
            outputToken: outputToken,
            outputAmount: outputAmount,
            criticalSuccessOutputAmount: criticalSuccessOutputAmount,
            inputTokens: inputTokens,
            inputAmounts: inputAmounts,
            successChance: successChance,
            criticalSuccessChance: criticalSuccessChance,
            isActive: false, // Proposed recipes are inactive by default
            allowsParameter: allowsParameter
        });

        registeredRecipeIds.push(recipeId);
        emit RecipeProposed(recipeId, msg.sender);
    }

    /// @notice Activates a proposed transformation recipe, making it available for use.
    /// @param recipeId The ID of the recipe to activate.
    function activateTransformationRecipe(bytes32 recipeId) public onlyRole(Role.Alchemist) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (recipe.essenceCost == 0) revert RecipeNotFound(); // Check if recipe exists
        if (recipe.isActive) return; // Already active

        recipe.isActive = true;
        emit RecipeActivated(recipeId, msg.sender);
    }

    /// @notice Deactivates an active transformation recipe, preventing new initiations.
    /// @param recipeId The ID of the recipe to deactivate.
    function deactivateTransformationRecipe(bytes32 recipeId) public onlyRole(Role.Alchemist) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (recipe.essenceCost == 0) revert RecipeNotFound();
        if (!recipe.isActive) return; // Already inactive

        recipe.isActive = false;
        // Note: Initiated transformations based on this recipe can still be completed.
        emit RecipeDeactivated(recipeId, msg.sender);
    }

    /// @notice Returns the details of a specific transformation recipe.
    /// @param recipeId The ID of the recipe to query.
    /// @return The TransformationRecipe struct details.
    function getTransformationRecipe(bytes32 recipeId) public view returns (TransformationRecipe memory) {
        TransformationRecipe memory recipe = transformationRecipes[recipeId];
         if (recipe.essenceCost == 0) revert RecipeNotFound(); // Check if recipe exists
         return recipe;
    }

    /// @notice Returns a list of all registered transformation recipe IDs.
    /// @return An array of bytes32 containing all recipe IDs.
    function getAllRecipes() public view returns (bytes32[] memory) {
        return registeredRecipeIds;
    }

    // --- Transformation Initiation & Completion Functions ---

    /// @notice Initiates a transformation based on a recipe. This consumes Essence and required inputs.
    /// @param recipeId The ID of the recipe to use.
    function initiateTransformation(bytes32 recipeId) public {
        _initiateTransformation(recipeId, msg.sender, 0); // Parameter is 0 for non-parametric initiation
    }

     /// @notice Initiates a transformation based on a recipe, providing a parameter.
     /// @param recipeId The ID of the recipe to use. Must be a recipe that allows parameters.
     /// @param parameter A uint256 value to pass to the transformation logic.
    function initiateParametricTransformation(bytes32 recipeId, uint256 parameter) public {
        _initiateTransformation(recipeId, msg.sender, parameter);
    }

    /// @dev Internal function to handle transformation initiation logic, supporting delegation.
    /// @param recipeId The ID of the recipe.
    /// @param initiator The address that *initiated* the call (msg.sender).
    /// @param parameter The parameter for the transformation.
    function _initiateTransformation(bytes32 recipeId, address initiator, uint256 parameter) internal {
         TransformationRecipe storage recipe = transformationRecipes[recipeId];
         if (!recipe.isActive) revert RecipeNotActive();
         if (recipe.allowsParameter && parameter == 0) {
            // If parameter is required but not provided (0 is default for uints), might indicate an error unless 0 is a valid meaningful parameter
            // Add a check here if 0 is an invalid parameter value for parametric recipes.
            // For now, we assume 0 is a valid parameter value if allowsParameter is true.
         }
         if (!recipe.allowsParameter && parameter != 0) {
             revert InvalidParameter(); // Parameter provided for non-parametric recipe
         }

         address caller = msg.sender; // The account paying gas/making the call

         // Check delegation allowance if caller is not the initiator
         if (caller != initiator) {
             uint256 allowance = transformationDelegatedAllowance[initiator][caller];
             if (allowance < recipe.essenceCost) revert NotEnoughDelegatedAllowance();
             transformationDelegatedAllowance[initiator][caller] = allowance.sub(recipe.essenceCost);
         }

         // Check if initiator has enough Essence (either directly or via delegation handled above)
         if (essenceBalances[initiator] < recipe.essenceCost) revert InsufficientEssence();

         // Check and transfer input tokens (excluding Essence)
         for (uint i = 0; i < recipe.inputTokens.length; i++) {
             address inputTokenAddress = recipe.inputTokens[i];
             uint256 inputAmount = recipe.inputAmounts[i];

             if (inputAmount > 0) {
                 // Check if the token is allowed as an input (security measure)
                 if (inputTokenAddress != resourceToken && !allowedInputTokens[inputTokenAddress]) {
                    revert TokenNotAllowedAsInput();
                 }
                 // Ensure it's a contract address if not address(0) (ETH)
                 if (inputTokenAddress != address(0) && !inputTokenAddress.isContract()) {
                     // Revert or handle non-contract input token addresses if necessary
                     // For now, assume ERC20s which are contracts, or address(0) for ETH
                     // This check might need refinement depending on intended behavior
                 }


                 if (inputTokenAddress == address(0)) { // Handling ETH input
                      // Note: Initiator sending ETH directly in `msg.value` isn't supported by this pattern
                      // for inputs *within* the recipe struct. ETH input would typically be
                      // handled via a separate function or by requiring wrapped ETH (WETH).
                      // For this contract, let's assume inputTokens are always ERC20s or require WETH.
                      // If native ETH input was desired, the struct/logic would need to change significantly.
                      revert InvalidParameter(); // Native ETH not supported as recipe input
                 } else { // Handling ERC20 input
                     IERC20 inputToken = IERC20(inputTokenAddress);
                     // User must have approved this contract to spend the input tokens
                     inputToken.safeTransferFrom(initiator, address(this), inputAmount);
                 }
             }
         }

         // Deduct Essence cost from initiator's balance
         essenceBalances[initiator] = essenceBalances[initiator].sub(recipe.essenceCost);

         // Create pending transformation entry
         uint256 currentId = nextTransformationId;
         pendingTransformations[currentId] = PendingTransformation({
             transformationId: currentId,
             initiator: initiator,
             recipeId: recipeId,
             startTime: uint64(block.timestamp),
             parameter: parameter,
             outcome: TransformationOutcome.Pending
         });

         userPendingTransformationIds[initiator].push(currentId);
         nextTransformationId = nextTransformationId.add(1);

         emit TransformationInitiated(currentId, initiator, recipeId, parameter);
    }


    /// @notice Allows an address to delegate permission to initiate transformations on their behalf up to a certain Essence cost limit.
    /// @param delegatee The address that will be allowed to initiate transformations.
    /// @param limit The maximum total Essence cost of transformations the delegatee can initiate for the delegator. Set to 0 to revoke.
    function delegateTransformationPermission(address delegatee, uint256 limit) public {
        if (delegatee == msg.sender) revert CannotSelfDelegate();
        transformationDelegatedAllowance[msg.sender][delegatee] = limit;
        emit TransformationDelegationUpdated(msg.sender, delegatee, limit);
    }


    /// @notice Returns the status details of a specific pending transformation.
    /// @param transformationId The ID of the transformation to query.
    /// @return The PendingTransformation struct details.
    function getTransformationStatus(uint256 transformationId) public view returns (PendingTransformation memory) {
        // Ensure transformationId is valid (greater than 0 and less than next ID)
        if (transformationId == 0 || transformationId >= nextTransformationId) revert TransformationNotFound();
        // Note: A completed transformation will still exist in this mapping but with a non-Pending outcome.
        // This allows querying historical outcomes.
        return pendingTransformations[transformationId];
    }

    /// @notice Completes a pending transformation if its duration has passed. Determines the outcome and transfers outputs.
    /// @param transformationId The ID of the transformation to complete.
    function completeTransformation(uint256 transformationId) public {
        PendingTransformation storage pt = pendingTransformations[transformationId];

        // Basic existence and state checks
        if (pt.transformationId == 0 || pt.transformationId >= nextTransformationId) revert TransformationNotFound();
        if (pt.outcome != TransformationOutcome.Pending) revert TransformationAlreadyCompleted(transformationId);
        if (block.timestamp < pt.startTime.add(pt.recipeId == bytes32(0) ? 0 : transformationRecipes[pt.recipeId].duration)) {
             revert TransformationNotCompleteable(transformationId);
        }

        // Retrieve recipe details (even if recipe was deactivated after initiation)
        TransformationRecipe storage recipe = transformationRecipes[pt.recipeId]; // Using storage here assumes recipes aren't deleted, only deactivated

        // Determine outcome based on chances, AmbientEnergyState, QuantumStates, and Parameter
        TransformationOutcome finalOutcome = _determineOutcome(recipe, pt.parameter);
        pt.outcome = finalOutcome; // Update state variable immediately

        // Handle outputs and cleanup based on outcome
        _handleTransformationOutcome(pt, recipe, finalOutcome);

        emit TransformationCompleted(transformationId, pt.initiator, pt.recipeId, finalOutcome);
    }

    /// @notice Attempts to complete multiple pending transformations in a single transaction.
    /// @param transformationIds An array of transformation IDs to attempt to complete.
    function batchCompleteTransformations(uint256[] memory transformationIds) public {
        if (transformationIds.length == 0) revert InvalidBatchCompletion();

        for (uint i = 0; i < transformationIds.length; i++) {
            uint256 currentId = transformationIds[i];
            PendingTransformation storage pt = pendingTransformations[currentId];

            // Check if it's a valid, pending transformation that is ready
            if (pt.transformationId != currentId || // Check if struct is initialized for this ID
                pt.outcome != TransformationOutcome.Pending ||
                (pt.recipeId != bytes32(0) && block.timestamp < pt.startTime.add(transformationRecipes[pt.recipeId].duration))
                )
            {
                // Skip invalid, already completed, or not-yet-ready transformations in the batch
                // Consider adding an event or logging mechanism for skipped IDs in a real app
                continue;
            }

            // Retrieve recipe details
            TransformationRecipe storage recipe = transformationRecipes[pt.recipeId];

            // Determine outcome
            TransformationOutcome finalOutcome = _determineOutcome(recipe, pt.parameter);
            pt.outcome = finalOutcome; // Update state

            // Handle outputs
            _handleTransformationOutcome(pt, recipe, finalOutcome);

            emit TransformationCompleted(currentId, pt.initiator, pt.recipeId, finalOutcome);
        }
    }


    /// @dev Internal function to determine the outcome of a transformation.
    ///     Outcome calculation logic incorporates recipe chances, ambient energy, quantum states, and parameter.
    /// @param recipe The transformation recipe used.
    /// @param parameter The parameter provided during initiation (if applicable).
    /// @return The determined TransformationOutcome.
    function _determineOutcome(TransformationRecipe storage recipe, uint256 parameter) internal view returns (TransformationOutcome) {
        // Simple pseudo-random number generation (caution: exploitable on its own)
        // A more secure approach would use Chainlink VRF or similar.
        // For this example, we combine block details and the unique transformation ID.
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            msg.sender, // Including sender for more variation in batch calls, though standard VRF doesn't use this
            block.difficulty, // Less relevant post-merge
            gasleft(),
            recipe.essenceCost,
            parameter, // Incorporate the parameter
            pendingTransformations[nextTransformationId].transformationId // Use the *next* ID for future-proofing, but safer is the *current* pending ID if stored
        )));

        // Use a secure source if possible in production
        // For demonstration, let's use the block hash and transformation ID
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), nextTransformationId))); // Using nextId as a unique factor

        uint256 chanceRoll = uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % 10000;

        // Adjust chances based on state and parameter (example logic)
        uint256 currentSuccessChance = recipe.successChance;
        uint256 currentCriticalSuccessChance = recipe.criticalSuccessChance;
        uint256 failureChance = 10000 - currentSuccessChance - currentCriticalSuccessChance;
        uint256 quantumShiftChance = 0; // Base chance for quantum shift

        // Apply Ambient Energy State effects
        if (currentAmbientEnergyState == AmbientEnergyState.Volatile) {
            currentSuccessChance = currentSuccessChance.div(2); // Halve success chance
            failureChance = 10000 - currentSuccessChance - currentCriticalSuccessChance; // Remaining chance is failure
        } else if (currentAmbientEnergyState == AmbientEnergyState.Attuned) {
            currentSuccessChance = currentSuccessChance.mul(120).div(100); // Increase success chance by 20%
            currentCriticalSuccessChance = currentCriticalSuccessChance.mul(150).div(100); // Increase critical success chance by 50%
            if (currentSuccessChance + currentCriticalSuccessChance > 10000) { // Cap total success chance
                 uint256 totalSuccess = currentSuccessChance + currentCriticalSuccessChance;
                 currentCriticalSuccessChance = currentCriticalSuccessChance.mul(10000).div(totalSuccess);
                 currentSuccessChance = 10000 - currentCriticalSuccessChance;
            }
             failureChance = 10000 - currentSuccessChance - currentCriticalSuccessChance;
        } else if (currentAmbientEnergyState == AmbientEnergyState.Chaotic) {
             quantumShiftChance = 500; // 5% chance of Quantum Shift in Chaotic state
             failureChance = failureChance.add(1000); // Increase failure chance by 10%
             if (failureChance > 10000) failureChance = 10000;
             uint256 remaining = 10000 - failureChance - quantumShiftChance; // Distribute remaining chance between success/critical
             uint256 totalRecipeSuccess = recipe.successChance + recipe.criticalSuccessChance;
             if (totalRecipeSuccess > 0) {
                currentCriticalSuccessChance = recipe.criticalSuccessChance.mul(remaining).div(totalRecipeSuccess);
                currentSuccessChance = recipe.successChance.mul(remaining).div(totalRecipeSuccess);
             } else { // No base success chance
                currentSuccessChance = 0;
                currentCriticalSuccessChance = 0;
             }
        }

        // Apply Active Quantum State effects
        uint64 currentTime = uint64(block.timestamp);
        if (activeQuantumStates[QuantumState.Amplification] > currentTime) {
             currentSuccessChance = currentSuccessChance.mul(130).div(100); // +30% success chance from QS
        }
        if (activeQuantumStates[QuantumState.Attenuation] > currentTime) {
             currentSuccessChance = currentSuccessChance.div(2); // -50% success chance from QS
        }
         if (activeQuantumStates[QuantumState.Mutation] > currentTime) {
             quantumShiftChance = quantumShiftChance.add(1000); // +10% chance of Quantum Shift from QS
        }
         if (activeQuantumStates[QuantumState.Stability] > currentTime) {
             failureChance = failureChance.div(2); // -50% failure chance from QS
        }

        // Cap chances at 10000
        if (currentSuccessChance + currentCriticalSuccessChance + failureChance + quantumShiftChance > 10000) {
             // Need to re-normalize or prioritize. Let's prioritize Failure > Quantum > Critical > Success
             uint256 total = currentSuccessChance + currentCriticalSuccessChance + failureChance + quantumShiftChance;
             failureChance = failureChance.mul(10000).div(total);
             quantumShiftChance = quantumShiftChance.mul(10000).div(total);
             currentCriticalSuccessChance = currentCriticalSuccessChance.mul(10000).div(total);
             currentSuccessChance = 10000 - failureChance - quantumShiftChance - currentCriticalSuccessChance;
        }


        // Apply Parameter effect (example: parameter increases chance for higher values)
        if (recipe.allowsParameter && parameter > 0) {
            uint256 parameterBonus = parameter.div(100); // Example: parameter 100 adds 1% (100 / 100 = 1, total 10000 basis points = 100)
            currentSuccessChance = currentSuccessChance.add(parameterBonus * 50); // Add parameterBonus * 0.5% chance
             if (currentSuccessChance + currentCriticalSuccessChance + failureChance + quantumShiftChance > 10000) {
                currentSuccessChance = 10000 - (currentCriticalSuccessChance + failureChance + quantumShiftChance);
             }
        }


        // Determine final outcome based on rolled chance
        uint256 cumulativeChance = 0;

        cumulativeChance = cumulativeChance.add(failureChance);
        if (chanceRoll < cumulativeChance) return TransformationOutcome.Failure;

        cumulativeChance = cumulativeChance.add(quantumShiftChance);
         if (chanceRoll < cumulativeChance) return TransformationOutcome.QuantumShift;

        cumulativeChance = cumulativeChance.add(currentCriticalSuccessChance);
        if (chanceRoll < cumulativeChance) return TransformationOutcome.CriticalSuccess;

        cumulativeChance = cumulativeChance.add(currentSuccessChance);
        if (chanceRoll < cumulativeChance) return TransformationOutcome.Success;

        // Should not reach here if chances sum to 10000, but as a fallback:
        return TransformationOutcome.Failure; // Or handle unexpected state
    }


    /// @dev Internal function to handle output transfer and state cleanup based on transformation outcome.
    /// @param pt The pending transformation struct.
    /// @param recipe The transformation recipe.
    /// @param outcome The determined outcome.
    function _handleTransformationOutcome(
        PendingTransformation storage pt,
        TransformationRecipe storage recipe,
        TransformationOutcome outcome
    ) internal {
        if (outcome == TransformationOutcome.Success) {
            if (recipe.outputToken != address(0) && recipe.outputAmount > 0) {
                 IERC20(recipe.outputToken).safeTransfer(pt.initiator, recipe.outputAmount);
            }
        } else if (outcome == TransformationOutcome.CriticalSuccess) {
             if (recipe.outputToken != address(0) && recipe.criticalSuccessOutputAmount > 0) {
                 IERC20(recipe.outputToken).safeTransfer(pt.initiator, recipe.criticalSuccessOutputAmount);
            }
        } else if (outcome == TransformationOutcome.QuantumShift) {
             // Example: Transfer inputs back + a small bonus essence? Or mint a special token?
             // For this example, let's return inputs + a small essence bonus.
             for (uint i = 0; i < recipe.inputTokens.length; i++) {
                 address inputTokenAddress = recipe.inputTokens[i];
                 uint256 inputAmount = recipe.inputAmounts[i];
                 if (inputTokenAddress != address(0) && inputAmount > 0) {
                     IERC20(inputTokenAddress).safeTransfer(pt.initiator, inputAmount); // Return inputs
                 }
             }
             uint256 essenceBonus = recipe.essenceCost.div(10); // 10% of essence cost back as bonus
             if (essenceBonus > 0) {
                  essenceBalances[pt.initiator] = essenceBalances[pt.initiator].add(essenceBonus);
                 emit EssenceGenerated(pt.initiator, essenceBonus);
             }
        } else if (outcome == TransformationOutcome.Failure) {
             // Inputs (Essence and tokens) are lost/burned. No output.
             // The tokens were already transferred to the contract, they just remain there unless withdrawn by owner/role.
             // This could be considered a form of 'fee' or 'burn'.
             // The Essence is already deducted.
        }
         // Note: inputs are not returned for Success, CriticalSuccess, or Failure.
         // They are returned for QuantumShift as a special outcome.

         // Clean up the pending transformation entry (or mark it as completed)
         // Marking as completed keeps history:
         // pendingTransformations[pt.transformationId].outcome = outcome; // Already done above
         // Remove from user's pending list (optional, could leave for history)
         // Removing from user's list requires finding and shifting array elements, which is gas-intensive.
         // Better to leave it and filter off-chain or provide a view function that filters.
    }


    /// @notice Returns a list of transformation IDs that are pending for a specific user.
    /// @param user The address of the user.
    /// @return An array of pending transformation IDs.
    function getPendingTransformations(address user) public view returns (uint256[] memory) {
        // Note: This returns *all* IDs the user initiated. Off-chain logic or getTransformationStatus
        // is needed to check if they are still `Pending`.
        // For efficiency, we store the IDs in an array per user.
        // Removing completed IDs from this array is gas-prohibitive for large numbers.
        // Consider a linked list or simply filtering off-chain if list gets very long.
        return userPendingTransformationIds[user];
    }


    /// @notice Checks if a user is currently eligible to initiate a specific transformation.
    /// @param user The address of the user.
    /// @param recipeId The ID of the recipe.
    /// @param parameter The parameter to check (use 0 if recipe is non-parametric).
    /// @return True if the user is eligible, false otherwise. Includes reasons if not eligible.
    function checkTransformationEligibility(address user, bytes32 recipeId, uint256 parameter) public view returns (bool, string memory) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];

        if (!recipe.isActive) return (false, "Recipe not active");
        if (recipe.allowsParameter && parameter == 0 && getRole(user) != Role.Owner) {
            // Strict check: if parameter allowed, 0 might be invalid unless owner
            // Or define strict rules for 0 parameter depending on context
             // For this check, let's assume 0 parameter is okay if recipe.allowsParameter
        }
        if (!recipe.allowsParameter && parameter != 0) return (false, "Recipe does not allow parameter");

        if (essenceBalances[user] < recipe.essenceCost) return (false, "Insufficient essence");

        // Check input tokens
        for (uint i = 0; i < recipe.inputTokens.length; i++) {
            address inputTokenAddress = recipe.inputTokens[i];
            uint256 inputAmount = recipe.inputAmounts[i];

            if (inputAmount > 0) {
                 // Check if the token is allowed as an input (security measure)
                 if (inputTokenAddress != resourceToken && !allowedInputTokens[inputTokenAddress]) {
                    return (false, "Input token not allowed");
                 }
                 if (inputTokenAddress == address(0)) {
                     // Native ETH input check - not supported by this struct design
                     return (false, "Native ETH input not supported by recipe struct");
                 } else {
                     IERC20 inputToken = IERC20(inputTokenAddress);
                     // Check user's balance for the input token
                     if (inputToken.balanceOf(user) < inputAmount) return (false, string(abi.encodePacked("Insufficient ", Address.toString(inputTokenAddress), " balance")));
                     // Check if user has approved this contract to spend the input tokens
                      if (inputToken.allowance(user, address(this)) < inputAmount) return (false, string(abi.encodePacked("Allowance too low for ", Address.toString(inputTokenAddress))));
                 }
            }
        }

        // Add checks related to state/parameter if they block initiation entirely (not just outcome)
        // Example: if (currentAmbientEnergyState == AmbientEnergyState.Chaotic && parameter == 0) return (false, "Chaotic state requires non-zero parameter");


        return (true, "Eligible");
    }


    // --- State Dynamics Functions ---

    /// @notice Updates the contract's ambient energy state. Influences transformation outcomes.
    /// @param newState The new ambient energy state.
    function updateAmbientEnergy(AmbientEnergyState newState) public onlyRole(Role.Alchemist) {
        if (currentAmbientEnergyState == newState) return; // No change
        currentAmbientEnergyState = newState;
        emit AmbientEnergyUpdated(newState);
    }

    /// @notice Returns the current ambient energy state.
    /// @return The current AmbientEnergyState enum value.
    function getAmbientEnergyState() public view returns (AmbientEnergyState) {
        return currentAmbientEnergyState;
    }

    /// @notice Triggers a potential Quantum Flux event, which might activate or deactivate Quantum States. Has a cooldown.
    function triggerQuantumFlux() public onlyRole(Role.Alchemist) {
        if (block.timestamp < lastQuantumFluxTriggerTime.add(quantumFluxCooldown)) {
            revert QuantumFluxOnCooldown();
        }

        lastQuantumFluxTriggerTime = uint64(block.timestamp);

        // Pseudo-randomly decide which states to activate/deactivate and for how long
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, lastQuantumFluxTriggerTime)));
        uint256 roll = uint256(keccak256(abi.encodePacked(seed, block.difficulty))) % 10000;

        uint64 duration = uint64(roll % (1 days) + 1 hours); // Random duration between 1 hour and 1 day

        // Example logic:
        if (roll < 2000) { // 20% chance for Amplification
             activeQuantumStates[QuantumState.Amplification] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Amplification, activeQuantumStates[QuantumState.Amplification]);
        } else if (roll < 3000) { // 10% chance for Attenuation
             activeQuantumStates[QuantumState.Attenuation] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Attenuation, activeQuantumStates[QuantumState.Attenuation]);
        } else if (roll < 3500) { // 5% chance for Mutation
             activeQuantumStates[QuantumState.Mutation] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Mutation, activeQuantumStates[QuantumState.Mutation]);
        } else if (roll < 4500) { // 10% chance for Stability
             activeQuantumStates[QuantumState.Stability] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Stability, activeQuantumStates[QuantumState.Stability]);
        } else if (roll > 8000) { // 20% chance to clear *all* states
             for (uint i = 1; i <= uint(type(QuantumState).max); ++i) { // Iterate through all states except None (0)
                  QuantumState state = QuantumState(i);
                  if (activeQuantumStates[state] > block.timestamp) { // If state was active
                       activeQuantumStates[state] = 0; // Set expiry to 0 (inactive)
                       emit QuantumStateShift(state, 0);
                  }
             }
        } else {
            // 35% chance nothing happens (states just expire naturally if time passes)
             // Check and emit expiry for any states that *just* expired
             for (uint i = 1; i <= uint(type(QuantumState).max); ++i) { // Iterate through all states except None (0)
                  QuantumState state = QuantumState(i);
                  if (activeQuantumStates[state] > 0 && activeQuantumStates[state] <= block.timestamp) {
                       activeQuantumStates[state] = 0; // Ensure it's set to 0
                       emit QuantumStateShift(state, 0);
                  }
             }
        }

         // Ensure any expired states are marked inactive and emit event if just expired
        _clearExpiredQuantumStates(); // Call explicit cleanup for clarity
        emit QuantumFluxTriggered(msg.sender);
    }

    /// @notice Returns a list of currently active Quantum States (those that haven't expired).
    /// @return An array of active QuantumState enum values.
    function getActiveQuantumStates() public view returns (QuantumState[] memory) {
        uint64 currentTime = uint64(block.timestamp);
        QuantumState[] memory activeStates = new QuantumState[](uint(type(QuantumState).max)); // Max possible states
        uint256 count = 0;

         // Iterate through all states except None (0)
        for (uint i = 1; i <= uint(type(QuantumState).max); ++i) {
            QuantumState state = QuantumState(i);
            if (activeQuantumStates[state] > currentTime) {
                activeStates[count] = state;
                count++;
            }
        }

        // Resize array to actual count
        QuantumState[] memory result = new QuantumState[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeStates[i];
        }
        return result;
    }

    /// @dev Internal helper to explicitly clear expired quantum states and emit events.
    /// Called during getActiveQuantumStates and potentially other state-changing functions.
    function _clearExpiredQuantumStates() internal {
         uint64 currentTime = uint64(block.timestamp);
         for (uint i = 1; i <= uint(type(QuantumState).max); ++i) {
            QuantumState state = QuantumState(i);
            if (activeQuantumStates[state] > 0 && activeQuantumStates[state] <= currentTime) {
                activeQuantumStates[state] = 0; // Ensure it's set to 0
                emit QuantumStateShift(state, 0);
            }
        }
    }


    // --- Configuration Functions ---

    /// @notice Sets the address of the resource token used for Essence generation.
    /// @param newToken The address of the new resource token contract.
    function setResourceToken(address newToken) public onlyOwner {
        if (newToken == address(0)) revert InvalidParameter();
        resourceToken = newToken;
        // Automatically allow the new resource token as an input token
        allowedInputTokens[newToken] = true;
    }

    /// @notice Sets the rate at which Essence is generated per unit of resource token.
    /// @param newRate The new Essence generation rate.
    function updateEssenceGenerationRate(uint256 newRate) public onlyOwner {
        essenceGenerationRate = newRate;
    }

    /// @notice Updates the Essence cost for a specific transformation recipe.
    /// @param recipeId The ID of the recipe to update.
    /// @param newEssenceCost The new Essence cost.
    function updateTransformationCost(bytes32 recipeId, uint256 newEssenceCost) public onlyRole(Role.Alchemist) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (recipe.essenceCost == 0) revert RecipeNotFound();
        recipe.essenceCost = newEssenceCost;
    }

    /// @notice Adds an ERC20 token address to the whitelist of tokens allowed as transformation inputs.
    /// @param token The address of the ERC20 token contract.
    function addAllowedInputToken(address token) public onlyRole(Role.Alchemist) {
        if (token == address(0) || token == resourceToken) revert InvalidParameter(); // resource token is already allowed
        if (!token.isContract()) revert InvalidParameter(); // Must be a contract address (assuming ERC20)
        allowedInputTokens[token] = true;
        emit AllowedInputTokenAdded(token);
    }

    /// @notice Removes an ERC20 token address from the whitelist of tokens allowed as transformation inputs.
    /// @param token The address of the ERC20 token contract.
    function removeAllowedInputToken(address token) public onlyRole(Role.Alchemist) {
         if (token == resourceToken) revert InvalidParameter(); // Resource token cannot be disallowed
         allowedInputTokens[token] = false;
         emit AllowedInputTokenRemoved(token);
    }

    /// @notice Allows the owner to withdraw specified tokens (e.g., collected inputs from failed transformations) from the contract.
    /// @param token The address of the token to withdraw (use address(0) for native ETH, though ERC20 is expected).
    /// @param amount The amount of the token to withdraw.
    function withdrawAdminFees(address token, uint256 amount) public onlyOwner {
        if (amount == 0) revert InvalidParameter();

        if (token == address(0)) {
            // Handle ETH withdrawal if the contract were designed to receive ETH directly
            // This contract's logic assumes ERC20 for inputs, so this path is unlikely to be used
            // unless ETH is sent manually.
             payable(owner()).transfer(amount);
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
    }

    // --- Query Functions (already included above: getRole, getEssenceBalance, calculateEssenceGeneration,
    // getTransformationRecipe, getAllRecipes, getTransformationStatus, getPendingTransformations,
    // getAmbientEnergyState, getActiveQuantumStates, checkTransformationEligibility)
    // We need a few more simple queries to reach 20+ *distinct* public/external functions.

    /// @notice Returns the current Essence generation rate.
    function getEssenceGenerationRate() public view returns (uint256) {
        return essenceGenerationRate;
    }

    /// @notice Returns the address of the resource token.
    function getResourceToken() public view returns (address) {
        return resourceToken;
    }

     /// @notice Returns the list of allowed input tokens.
     /// @dev This function might be gas-intensive if many tokens are allowed. Consider pagination or off-chain lookup for large lists.
    function getAllowedInputTokens() public view returns (address[] memory) {
         // This requires iterating through keys, which isn't directly supported efficiently by Solidity mappings.
         // To implement efficiently, you'd need to store allowed tokens in an array alongside the mapping.
         // For demonstration, we'll return an empty array or require off-chain lookup based on `allowedInputTokens` mapping.
         // Let's return a fixed small array for demonstration or require specific checks.
         // A better approach is to have a limited number or store them in an array/linked list.
         // Given the constraint for 20+ *functions*, a function that returns the list, even if inefficient for huge lists, counts.
         // Let's return *up to* a fixed number or rely on off-chain tools checking the `allowedInputTokens` mapping.
         // A simple way for demonstration: return a list of IDs added, if we tracked that.
         // Let's track them in an array for this function.
         // Adding a state variable: `address[] private allowedInputTokenList;`
         // Update `addAllowedInputToken` and `removeAllowedInputToken` to manage this array.

        // Re-structuring add/remove to maintain an array:
        // Remove the old mapping: `mapping(address => bool) public allowedInputTokens;`
        // Add new state: `address[] private allowedInputTokenList;`
        // Add new mapping: `mapping(address => bool) private isAllowedInputToken;` // To check existence quickly

        // --- New State Variables ---
        // (replace `mapping(address => bool) public allowedInputTokens;`)
        address[] private allowedInputTokenList;
        mapping(address => bool) private isAllowedInputToken;

        // --- Update Constructor ---
        // allowedInputTokens[resourceToken] = true; // ->
        isAllowedInputToken[resourceToken] = true;
        allowedInputTokenList.push(resourceToken);


        // --- Update addAllowedInputToken ---
        /*
        function addAllowedInputToken(address token) public onlyRole(Role.Alchemist) {
            if (token == address(0) || token == resourceToken) revert InvalidParameter();
            if (!token.isContract()) revert InvalidParameter();
            // allowedInputTokens[token] = true; // Old line
            if (!isAllowedInputToken[token]) { // Check if not already added
                isAllowedInputToken[token] = true;
                allowedInputTokenList.push(token);
                emit AllowedInputTokenAdded(token);
            }
        }
        */

        // --- Update removeAllowedInputToken ---
        /*
        function removeAllowedInputToken(address token) public onlyRole(Role.Alchemist) {
            if (token == resourceToken) revert InvalidParameter();
            // allowedInputTokens[token] = false; // Old line
            if (isAllowedInputToken[token]) { // Check if currently allowed
                 isAllowedInputToken[token] = false;
                 // Removing from array is inefficient, but necessary for this function.
                 // Find index and swap+pop.
                 uint256 indexToRemove = type(uint256).max;
                 for(uint i = 0; i < allowedInputTokenList.length; i++) {
                     if (allowedInputTokenList[i] == token) {
                         indexToRemove = i;
                         break;
                     }
                 }
                 if (indexToRemove != type(uint256).max) {
                      // Swap the element to remove with the last element
                     if (indexToRemove != allowedInputTokenList.length - 1) {
                         allowedInputTokenList[indexToRemove] = allowedInputTokenList[allowedInputTokenList.length - 1];
                     }
                     // Remove the last element
                     allowedInputTokenList.pop();
                     emit AllowedInputTokenRemoved(token);
                 }
            }
        }
        */
        // Okay, let's implement the array + mapping approach for getAllowedInputTokens to be viable.

        return allowedInputTokenList; // Now this works efficiently
    }

    /// @notice Checks if a specific token is allowed as a transformation input.
    /// @param token The address of the token to check.
    /// @return True if the token is allowed, false otherwise.
    function isInputTokenAllowed(address token) public view returns (bool) {
         // Re-structuring add/remove requires using the new mapping `isAllowedInputToken`
         // return allowedInputTokens[token]; // Old line
         return isAllowedInputToken[token];
    }


    /// @notice Returns the total number of registered transformation recipes (active or inactive).
    function getRecipeCount() public view returns (uint256) {
        return registeredRecipeIds.length;
    }

    /// @notice Returns the total number of transformations initiated ever.
    function getTotalTransformationsInitiated() public view returns (uint256) {
        return nextTransformationId - 1; // Since IDs start at 1
    }


    // --- Internal helpers (already included: _initiateTransformation, _determineOutcome, _handleTransformationOutcome, _clearExpiredQuantumStates) ---


    // Re-implementing add/remove functions with the array+mapping approach for getAllowedInputTokens efficiency
    // These replace the original `addAllowedInputToken` and `removeAllowedInputToken`
     /// @notice Adds an ERC20 token address to the whitelist of tokens allowed as transformation inputs.
    /// @param token The address of the ERC20 token contract.
    function addAllowedInputToken(address token) public override onlyRole(Role.Alchemist) { // Override keyword added assuming this is a refined version
        if (token == address(0) || token == resourceToken) revert InvalidParameter(); // resource token is already allowed
        if (!token.isContract()) revert InvalidParameter(); // Must be a contract address (assuming ERC20)
        if (!isAllowedInputToken[token]) { // Check if not already added
            isAllowedInputToken[token] = true;
            allowedInputTokenList.push(token);
            emit AllowedInputTokenAdded(token);
        }
    }

    /// @notice Removes an ERC20 token address from the whitelist of tokens allowed as transformation inputs.
    /// @param token The address of the ERC20 token contract.
    function removeAllowedInputToken(address token) public override onlyRole(Role.Alchemist) { // Override keyword added
        if (token == resourceToken) revert InvalidParameter(); // Resource token cannot be disallowed
        if (isAllowedInputToken[token]) { // Check if currently allowed
             isAllowedInputToken[token] = false;
             // Remove from array by finding index and swapping with last element
             uint256 indexToRemove = type(uint256).max;
             for(uint i = 0; i < allowedInputTokenList.length; i++) {
                 if (allowedInputTokenList[i] == token) {
                     indexToRemove = i;
                     break;
                 }
             }
             if (indexToRemove != type(uint256).max) {
                  // Swap the element to remove with the last element
                 if (indexToRemove != allowedInputTokenList.length - 1) {
                     allowedInputTokenList[indexToRemove] = allowedInputTokenList[allowedInputTokenList.length - 1];
                 }
                 // Remove the last element
                 allowedInputTokenList.pop();
                 emit AllowedInputTokenRemoved(token);
             }
        }
    }

    // Add the new state variables and update constructor again based on the re-implementation need
    // This requires placing the struct definitions, state variables, and constructor *after* the pragma/imports but *before* the function implementations.
    // The original code structure was mostly correct, just need to integrate the array+mapping changes properly.

    // Let's count the public/external functions one last time:
    // 1. constructor (internal helper, not external/public count) - skip
    // 2. grantRole (public)
    // 3. revokeRole (public)
    // 4. getRole (public view)
    // 5. depositResource (public)
    // 6. calculateEssenceGeneration (public view)
    // 7. getEssenceBalance (public view)
    // 8. proposeTransformation (public)
    // 9. activateTransformationRecipe (public)
    // 10. deactivateTransformationRecipe (public)
    // 11. getTransformationRecipe (public view)
    // 12. getAllRecipes (public view)
    // 13. initiateTransformation (public)
    // 14. initiateParametricTransformation (public)
    // 15. getTransformationStatus (public view)
    // 16. completeTransformation (public)
    // 17. batchCompleteTransformations (public)
    // 18. delegateTransformationPermission (public)
    // 19. checkTransformationEligibility (public view)
    // 20. updateAmbientEnergy (public)
    // 21. getAmbientEnergyState (public view)
    // 22. triggerQuantumFlux (public)
    // 23. getActiveQuantumStates (public view)
    // 24. setResourceToken (public)
    // 25. updateEssenceGenerationRate (public)
    // 26. updateTransformationCost (public)
    // 27. addAllowedInputToken (public) - Re-implemented
    // 28. removeAllowedInputToken (public) - Re-implemented
    // 29. withdrawAdminFees (public)
    // 30. getEssenceGenerationRate (public view)
    // 31. getResourceToken (public view)
    // 32. getAllowedInputTokens (public view) - Requires array+mapping
    // 33. isInputTokenAllowed (public view) - Requires mapping
    // 34. getRecipeCount (public view)
    // 35. getTotalTransformationsInitiated (public view)

    Okay, 35 public/external functions. Well over 20. The structure is sound. The logic is complex but fits the theme.

    Final check on state variables and constructor based on the allowedInputToken changes.
    Need to add `allowedInputTokenList` and change `allowedInputTokens` to `isAllowedInputToken`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract QuantumCatalyst is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    // --- Custom Errors ---
    error InvalidRole();
    error RecipeNotFound();
    error RecipeNotActive();
    error InsufficientEssence();
    error InsufficientInputTokens(address token); // Specific token helps diagnosis
    error TransformationNotFound(); // Added specific error for querying non-existent ID
    error TransformationInProgress(uint256 transformationId); // Maybe not needed if checking outcome != Pending
    error TransformationNotCompleteable(uint256 transformationId);
    error TransformationAlreadyCompleted(uint256 transformationId);
    // error TransformationFailed(); // Outcome is logged, no specific error on failure
    // error TransformationCancelled(); // Outcome is logged, no specific error on cancellation
    error DuplicateRecipeId();
    error TokenNotAllowedAsInput();
    error DelegationLimitExceeded(); // Not used directly, covered by NotEnoughDelegatedAllowance
    error NotEnoughDelegatedAllowance();
    error CannotSelfDelegate();
    error QuantumFluxOnCooldown();
    error NoActiveQuantumStates(); // Not used directly, states just aren't applied
    error InvalidParameter();
    error NoPendingTransformations(); // Not used directly for individual tx, maybe for batch
    error InvalidBatchCompletion();
    error ResourceTokenCannotBeRemoved(); // Added for clarity


    // --- Enums ---
    enum Role {
        None,
        Owner,      // Full control (inherited from Ownable)
        Alchemist,  // Can propose/activate recipes, manage rates, trigger flux, manage allowed inputs, update costs
        Observer    // Can only query state and recipes, essence balance, pending transformations
    }

    enum AmbientEnergyState {
        Stable,
        Volatile,
        Attuned,
        Chaotic
    }

    enum TransformationOutcome {
        Pending,
        Success,
        Failure,
        CriticalSuccess,
        QuantumShift, // Special outcome influenced by Quantum States
        Cancelled // If inputs are withdrawn early or recipe deactivated (less likely with current design)
    }

    enum QuantumState {
        None,
        Amplification, // Increases success chances
        Attenuation,   // Decreases success chances
        Mutation,      // Increases chance of QuantumShift
        Stability      // Reduces chance of Failure
    }

    // --- Structs ---
    struct TransformationRecipe {
        string name;
        uint256 essenceCost;
        uint64 duration; // In seconds
        address outputToken;
        uint256 outputAmount; // Base output on success
        uint256 criticalSuccessOutputAmount; // Higher output on critical success
        address[] inputTokens;
        uint256[] inputAmounts;
        uint256 successChance; // Out of 10000 (e.g., 7500 for 75%)
        uint256 criticalSuccessChance; // Out of 10000 (e.g., 500 for 5%)
        bool isActive;
        bool allowsParameter; // Does this recipe accept a parameter?
        uint256 parameterMax; // Max value for parameter (0 if no max)
    }

    struct PendingTransformation {
        uint256 transformationId;
        address initiator;
        bytes32 recipeId;
        uint64 startTime;
        uint256 parameter; // Used if recipe.allowsParameter is true
        TransformationOutcome outcome;
        // Input tokens were transferred to the contract upon initiation
        // Output tokens are transferred upon completion
    }

    // --- State Variables ---
    address public resourceToken;
    uint256 public essenceGenerationRate; // Amount of Essence per unit of resource token

    mapping(address => uint256) private essenceBalances;
    mapping(address => Role) private userRoles; // Owner role handled by Ownable internally, but tracked here for Role enum

    mapping(bytes32 => TransformationRecipe) private transformationRecipes;
    bytes32[] public registeredRecipeIds; // List of all recipe IDs

    uint256 private nextTransformationId = 1;
    mapping(uint256 => PendingTransformation) private pendingTransformations;
    mapping(address => uint256[]) private userPendingTransformationIds; // Track user's pending transformation IDs

    mapping(address => mapping(address => uint256)) private transformationDelegatedAllowance; // delegator => delegatee => essenceCostLimit

    AmbientEnergyState public currentAmbientEnergyState = AmbientEnergyState.Stable;

    // Tracking allowed input tokens
    address[] private allowedInputTokenList;
    mapping(address => bool) private isAllowedInputToken; // Efficient lookup

    // Quantum Flux state
    mapping(QuantumState => uint64) private activeQuantumStates; // QuantumState => Expiry Timestamp (0 if inactive)
    uint64 public lastQuantumFluxTriggerTime;
    uint64 public quantumFluxCooldown = 1 days; // Cooldown period for triggering flux

    // --- Events ---
    event ResourceDeposited(address indexed user, uint256 amount, uint256 essenceGenerated);
    event EssenceGenerated(address indexed user, uint256 amount);
    event RoleGranted(address indexed user, Role role);
    event RoleRevoked(address indexed user, Role role);
    event RecipeProposed(bytes32 indexed recipeId, address indexed proposer);
    event RecipeActivated(bytes32 indexed recipeId, address indexed activator);
    event RecipeDeactivated(bytes32 indexed recipeId, address indexed deactivator);
    event TransformationInitiated(uint256 indexed transformationId, address indexed initiator, bytes32 indexed recipeId, uint256 parameter);
    event TransformationCompleted(uint256 indexed transformationId, address indexed initiator, bytes32 indexed recipeId, TransformationOutcome outcome);
    event AmbientEnergyUpdated(AmbientEnergyState newState);
    event QuantumFluxTriggered(address indexed triggerer);
    event QuantumStateShift(QuantumState indexed state, uint64 expiryTime); // State became active or expired
    event TransformationDelegationUpdated(address indexed delegator, address indexed delegatee, uint256 newLimit);
    event AllowedInputTokenAdded(address indexed token);
    event AllowedInputTokenRemoved(address indexed token);
    event AdminFundsWithdrawn(address indexed token, address indexed to, uint256 amount);


    // --- Modifiers ---
    modifier onlyRole(Role requiredRole) {
        // Owner has implicit Role.Owner, which is > any other role value
        if (msg.sender != owner() && userRoles[msg.sender] < requiredRole) {
            revert InvalidRole();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _resourceToken) Ownable(msg.sender) {
        resourceToken = _resourceToken;
        userRoles[owner()] = Role.Owner; // Set owner's role explicitly in the mapping for clarity
        essenceGenerationRate = 100; // Default rate: 100 Essence per resource unit

        // Add resource token to allowed inputs by default
        isAllowedInputToken[resourceToken] = true;
        allowedInputTokenList.push(resourceToken);
    }

    // --- Role Management Functions ---

    /// @notice Grants a specific role to a user. Only callable by the contract owner.
    /// @param user The address to grant the role to.
    /// @param role The role to grant (Alchemist or Observer). Cannot grant None or Owner role using this function.
    function grantRole(address user, Role role) public onlyOwner {
        if (role == Role.None || role == Role.Owner) revert InvalidRole();
        if (userRoles[user] == role) return; // No change
        userRoles[user] = role;
        emit RoleGranted(user, role);
    }

    /// @notice Revokes a specific role from a user. Only callable by the contract owner.
    /// @param user The address to revoke the role from.
    /// @param role The role to revoke. Cannot revoke Owner role using this function.
    function revokeRole(address user, Role role) public onlyOwner {
        if (role == Role.None || role == Role.Owner) revert InvalidRole();
        if (userRoles[user] != role) return; // User doesn't have this role
        userRoles[user] = Role.None; // Revert to None
        emit RoleRevoked(user, role);
    }

    /// @notice Returns the current role of a user.
    /// @param user The address to query.
    /// @return The user's role.
    function getRole(address user) public view returns (Role) {
        if (user == owner()) return Role.Owner;
        return userRoles[user];
    }

    // --- Essence Management Functions ---

    /// @notice Deposits the resource token to generate Essence.
    /// @param amount The amount of resource token to deposit.
    function depositResource(uint256 amount) public {
        if (amount == 0) revert InvalidParameter();
        IERC20 token = IERC20(resourceToken);
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 generatedEssence = amount.mul(essenceGenerationRate);
        essenceBalances[msg.sender] = essenceBalances[msg.sender].add(generatedEssence);

        emit ResourceDeposited(msg.sender, amount, generatedEssence);
        emit EssenceGenerated(msg.sender, generatedEssence);
    }

    /// @notice Calculates the amount of Essence that would be generated for a given resource amount based on the current rate.
    /// @param resourceAmount The amount of resource token.
    /// @return The calculated amount of Essence.
    function calculateEssenceGeneration(uint256 resourceAmount) public view returns (uint256) {
        return resourceAmount.mul(essenceGenerationRate);
    }

    /// @notice Returns the Essence balance of a user.
    /// @param user The address to query.
    /// @return The user's Essence balance.
    function getEssenceBalance(address user) public view returns (uint256) {
        return essenceBalances[user];
    }

    // --- Transformation Recipe Management Functions ---

    /// @notice Proposes a new transformation recipe. Recipes must be activated before use.
    /// @param recipeId A unique identifier for the recipe.
    /// @param name The name of the recipe.
    /// @param essenceCost The cost in Essence to initiate this transformation.
    /// @param duration The time in seconds required for the transformation to complete.
    /// @param outputToken The address of the token produced on success (use address(0) for no token output).
    /// @param outputAmount The base amount of outputToken produced on success.
    /// @param criticalSuccessOutputAmount The amount of outputToken produced on critical success.
    /// @param inputTokens Array of addresses for input tokens required (use address(0) for no inputs other than Essence).
    /// @param inputAmounts Array of amounts corresponding to inputTokens. Must match length of inputTokens.
    /// @param successChance The base probability of success (out of 10000).
    /// @param criticalSuccessChance The base probability of critical success (out of 10000).
    /// @param allowsParameter True if this recipe can accept a user-defined parameter influencing outcome.
    /// @param parameterMax Max value for the parameter (0 if no max, or not allowed).
    function proposeTransformation(
        bytes32 recipeId,
        string memory name,
        uint256 essenceCost,
        uint64 duration,
        address outputToken,
        uint256 outputAmount,
        uint256 criticalSuccessOutputAmount,
        address[] memory inputTokens,
        uint256[] memory inputAmounts,
        uint256 successChance,
        uint256 criticalSuccessChance,
        bool allowsParameter,
        uint256 parameterMax
    ) public onlyRole(Role.Alchemist) {
        if (transformationRecipes[recipeId].essenceCost != 0) { // Check if recipeId is already used (essenceCost is a simple check for existence)
            revert DuplicateRecipeId();
        }
        if (inputTokens.length != inputAmounts.length) revert InvalidParameter();
        if (successChance + criticalSuccessChance > 10000) revert InvalidParameter();
        if (duration == 0) revert InvalidParameter(); // Must take some time
        if (!allowsParameter && parameterMax > 0) revert InvalidParameter(); // Cannot set max if parameter not allowed

        // Validate input tokens are in the allowed list (except address(0) handled later)
        for(uint i = 0; i < inputTokens.length; i++) {
             if(inputTokens[i] != address(0) && !isAllowedInputToken[inputTokens[i]]) {
                  revert TokenNotAllowedAsInput();
             }
        }


        transformationRecipes[recipeId] = TransformationRecipe({
            name: name,
            essenceCost: essenceCost,
            duration: duration,
            outputToken: outputToken,
            outputAmount: outputAmount,
            criticalSuccessOutputAmount: criticalSuccessOutputAmount,
            inputTokens: inputTokens,
            inputAmounts: inputAmounts,
            successChance: successChance,
            criticalSuccessChance: criticalSuccessChance,
            isActive: false, // Proposed recipes are inactive by default
            allowsParameter: allowsParameter,
            parameterMax: parameterMax
        });

        registeredRecipeIds.push(recipeId);
        emit RecipeProposed(recipeId, msg.sender);
    }

    /// @notice Activates a proposed transformation recipe, making it available for use.
    /// @param recipeId The ID of the recipe to activate.
    function activateTransformationRecipe(bytes32 recipeId) public onlyRole(Role.Alchemist) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (recipe.essenceCost == 0) revert RecipeNotFound(); // Check if recipe exists
        if (recipe.isActive) return; // Already active

        recipe.isActive = true;
        emit RecipeActivated(recipeId, msg.sender);
    }

    /// @notice Deactivates an active transformation recipe, preventing new initiations.
    /// @param recipeId The ID of the recipe to deactivate.
    function deactivateTransformationRecipe(bytes32 recipeId) public onlyRole(Role.Alchemist) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (recipe.essenceCost == 0) revert RecipeNotFound();
        if (!recipe.isActive) return; // Already inactive

        recipe.isActive = false;
        // Note: Initiated transformations based on this recipe can still be completed.
        emit RecipeDeactivated(recipeId, msg.sender);
    }

    /// @notice Returns the details of a specific transformation recipe.
    /// @param recipeId The ID of the recipe to query.
    /// @return The TransformationRecipe struct details.
    function getTransformationRecipe(bytes32 recipeId) public view returns (TransformationRecipe memory) {
        TransformationRecipe memory recipe = transformationRecipes[recipeId];
        // Check if recipeId exists by checking a default value (e.g., name is empty or essenceCost is 0)
         if (recipe.essenceCost == 0 && bytes(recipe.name).length == 0) revert RecipeNotFound();
         return recipe;
    }

    /// @notice Returns a list of all registered transformation recipe IDs.
    /// @return An array of bytes32 containing all recipe IDs.
    function getAllRecipes() public view returns (bytes32[] memory) {
        return registeredRecipeIds;
    }

    /// @notice Updates the Essence cost for a specific transformation recipe.
    /// @param recipeId The ID of the recipe to update.
    /// @param newEssenceCost The new Essence cost.
    function updateTransformationCost(bytes32 recipeId, uint256 newEssenceCost) public onlyRole(Role.Alchemist) {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (recipe.essenceCost == 0 && bytes(recipe.name).length == 0) revert RecipeNotFound();
        recipe.essenceCost = newEssenceCost;
    }


    // --- Transformation Initiation & Completion Functions ---

    /// @notice Initiates a transformation based on a recipe. This consumes Essence and required inputs.
    /// @param recipeId The ID of the recipe to use.
    function initiateTransformation(bytes32 recipeId) public {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
         if (recipe.allowsParameter) revert InvalidParameter(); // Must use parametric initiation
        _initiateTransformation(recipeId, msg.sender, 0); // Parameter is 0 for non-parametric initiation
    }

     /// @notice Initiates a transformation based on a recipe, providing a parameter.
     /// @param recipeId The ID of the recipe to use. Must be a recipe that allows parameters.
     /// @param parameter A uint256 value to pass to the transformation logic.
    function initiateParametricTransformation(bytes32 recipeId, uint256 parameter) public {
        TransformationRecipe storage recipe = transformationRecipes[recipeId];
        if (!recipe.allowsParameter) revert InvalidParameter(); // Parameter provided for non-parametric recipe
        if (recipe.parameterMax > 0 && parameter > recipe.parameterMax) revert InvalidParameter();

        _initiateTransformation(recipeId, msg.sender, parameter);
    }

    /// @dev Internal function to handle transformation initiation logic, supporting delegation.
    /// @param recipeId The ID of the recipe.
    /// @param initiator The address who is paying for the transformation (owner of Essence/inputs).
    /// @param parameter The parameter for the transformation.
    function _initiateTransformation(bytes32 recipeId, address initiator, uint256 parameter) internal {
         TransformationRecipe storage recipe = transformationRecipes[recipeId];
         if (!recipe.isActive) revert RecipeNotActive();
         // Parameter validation already happened in public wrappers


         address caller = msg.sender; // The account paying gas/making the call

         // Check delegation allowance if caller is not the initiator
         if (caller != initiator) {
             uint256 allowance = transformationDelegatedAllowance[initiator][caller];
             if (allowance < recipe.essenceCost) revert NotEnoughDelegatedAllowance();
             // Reduce allowance *before* checking/transferring inputs or Essence, as this is the delegated 'right'
             transformationDelegatedAllowance[initiator][caller] = allowance.sub(recipe.essenceCost);
         }

         // Check if initiator has enough Essence
         if (essenceBalances[initiator] < recipe.essenceCost) revert InsufficientEssence();

         // Check and transfer input tokens (excluding Essence)
         for (uint i = 0; i < recipe.inputTokens.length; i++) {
             address inputTokenAddress = recipe.inputTokens[i];
             uint256 inputAmount = recipe.inputAmounts[i];

             if (inputAmount > 0) {
                 // Check if the token is allowed as an input (security measure)
                 // address(0) for ETH is not supported by this recipe input method
                 if (inputTokenAddress == address(0) || !isAllowedInputToken[inputTokenAddress]) {
                    revert TokenNotAllowedAsInput();
                 }
                 // Ensure it's a contract address (assuming ERC20)
                 if (!inputTokenAddress.isContract()) {
                     revert TokenNotAllowedAsInput(); // Or a more specific error
                 }

                 IERC20 inputToken = IERC20(inputTokenAddress);
                 // Initiator must have approved this contract to spend the input tokens
                 inputToken.safeTransferFrom(initiator, address(this), inputAmount);

             }
         }

         // Deduct Essence cost from initiator's balance
         essenceBalances[initiator] = essenceBalances[initiator].sub(recipe.essenceCost);

         // Create pending transformation entry
         uint256 currentId = nextTransformationId;
         pendingTransformations[currentId] = PendingTransformation({
             transformationId: currentId,
             initiator: initiator,
             recipeId: recipeId,
             startTime: uint64(block.timestamp),
             parameter: parameter,
             outcome: TransformationOutcome.Pending
         });

         userPendingTransformationIds[initiator].push(currentId);
         nextTransformationId = nextTransformationId.add(1);

         emit TransformationInitiated(currentId, initiator, recipeId, parameter);
    }


    /// @notice Allows an address to delegate permission to initiate transformations on their behalf up to a certain Essence cost limit.
    /// @param delegatee The address that will be allowed to initiate transformations.
    /// @param limit The maximum total Essence cost of transformations the delegatee can initiate for the delegator. Set to 0 to revoke.
    function delegateTransformationPermission(address delegatee, uint256 limit) public {
        if (delegatee == msg.sender) revert CannotSelfDelegate();
        transformationDelegatedAllowance[msg.sender][delegatee] = limit;
        emit TransformationDelegationUpdated(msg.sender, delegatee, limit);
    }


    /// @notice Returns the status details of a specific pending transformation.
    /// @param transformationId The ID of the transformation to query.
    /// @return The PendingTransformation struct details.
    function getTransformationStatus(uint256 transformationId) public view returns (PendingTransformation memory) {
        // Ensure transformationId is valid (greater than 0 and exists in the mapping)
        // Check against nextTransformationId is safer than just != 0
        if (transformationId == 0 || transformationId >= nextTransformationId || pendingTransformations[transformationId].transformationId == 0) {
             revert TransformationNotFound();
        }
        // Note: A completed transformation will still exist in this mapping but with a non-Pending outcome.
        // This allows querying historical outcomes.
        return pendingTransformations[transformationId];
    }

    /// @notice Completes a pending transformation if its duration has passed. Determines the outcome and transfers outputs.
    /// Anyone can call this function to help process transformations once ready.
    /// @param transformationId The ID of the transformation to complete.
    function completeTransformation(uint256 transformationId) public {
        PendingTransformation storage pt = pendingTransformations[transformationId];

        // Basic existence and state checks
        if (pt.transformationId == 0 || pt.transformationId >= nextTransformationId) revert TransformationNotFound();
        if (pt.outcome != TransformationOutcome.Pending) revert TransformationAlreadyCompleted(transformationId);

        TransformationRecipe storage recipe = transformationRecipes[pt.recipeId]; // Get recipe details

        // Check time lock
        if (block.timestamp < pt.startTime.add(recipe.duration)) {
             revert TransformationNotCompleteable(transformationId);
        }

        // Determine outcome
        TransformationOutcome finalOutcome = _determineOutcome(recipe, pt.parameter);
        pt.outcome = finalOutcome; // Update state variable immediately

        // Handle outputs and cleanup based on outcome
        _handleTransformationOutcome(pt, recipe, finalOutcome);

        emit TransformationCompleted(transformationId, pt.initiator, pt.recipeId, finalOutcome);
    }

    /// @notice Attempts to complete multiple pending transformations in a single transaction.
    /// Anyone can call this function to help process transformations once ready.
    /// @param transformationIds An array of transformation IDs to attempt to complete.
    function batchCompleteTransformations(uint256[] memory transformationIds) public {
        if (transformationIds.length == 0) revert InvalidBatchCompletion();

        uint64 currentTime = uint64(block.timestamp);

        for (uint i = 0; i < transformationIds.length; i++) {
            uint256 currentId = transformationIds[i];
            PendingTransformation storage pt = pendingTransformations[currentId];

            // Check if it's a valid, pending transformation that is ready
             // pt.transformationId == 0 check covers non-existent or 0 IDs
            if (pt.transformationId != currentId ||
                pt.outcome != TransformationOutcome.Pending)
            {
                // Skip invalid or already completed
                continue;
            }

            TransformationRecipe storage recipe = transformationRecipes[pt.recipeId]; // Get recipe details
            if (currentTime < pt.startTime.add(recipe.duration))
            {
                // Skip not-yet-ready
                continue;
            }


            // Determine outcome
            TransformationOutcome finalOutcome = _determineOutcome(recipe, pt.parameter);
            pt.outcome = finalOutcome; // Update state

            // Handle outputs
            _handleTransformationOutcome(pt, recipe, finalOutcome);

            emit TransformationCompleted(currentId, pt.initiator, pt.recipeId, finalOutcome);
        }
    }


    /// @dev Internal function to determine the outcome of a transformation.
    ///     Outcome calculation logic incorporates recipe chances, ambient energy, quantum states, and Parameter.
    /// @param recipe The transformation recipe used.
    /// @param parameter The parameter provided during initiation (if applicable).
    /// @return The determined TransformationOutcome.
    function _determineOutcome(TransformationRecipe storage recipe, uint256 parameter) internal view returns (TransformationOutcome) {
        // --- Secure Pseudo-randomness ---
        // Use blockhash of a recent block and a unique contract state variable (like nextTransformationId or the current transformation ID)
        // to generate a seed. Avoid using block.timestamp or tx.origin alone as they are easily manipulated.
        // blockhash(block.number - 1) is relatively safe for non-critical applications, but for high-value, Chainlink VRF is recommended.
        // For this complex demo, blockhash is sufficient to demonstrate state influence.

        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), nextTransformationId))); // Using nextId as a unique factor for the current batch

        // Introduce parameter influence into the seed if the recipe allows it
        if (recipe.allowsParameter) {
             seed = uint256(keccak256(abi.encodePacked(seed, parameter)));
        }

        uint256 chanceRoll = uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % 10000; // Roll between 0-9999

        // --- Chance Calculation with Modifiers ---
        uint256 currentSuccessChance = recipe.successChance;
        uint256 currentCriticalSuccessChance = recipe.criticalSuccessChance;
        uint256 baseFailureChance = 10000 - recipe.successChance - recipe.criticalSuccessChance;
        uint256 currentFailureChance = baseFailureChance;
        uint256 currentQuantumShiftChance = 0; // Base chance for quantum shift

        // Apply Ambient Energy State effects (Modifiers are percentages / 100 or fixed values)
        if (currentAmbientEnergyState == AmbientEnergyState.Volatile) {
            currentSuccessChance = currentSuccessChance.div(2); // 50% reduction
            currentFailureChance = currentFailureChance.add(baseFailureChance); // Double base failure
        } else if (currentAmbientEnergyState == AmbientEnergyState.Attuned) {
            currentSuccessChance = currentSuccessChance.mul(120).div(100); // +20%
            currentCriticalSuccessChance = currentCriticalSuccessChance.mul(150).div(100); // +50%
        } else if (currentAmbientEnergyState == AmbientEnergyState.Chaotic) {
             currentQuantumShiftChance = currentQuantumShiftChance.add(500); // +5% base QS chance
             currentFailureChance = currentFailureChance.add(1000); // +10% failure chance
        }
         // Ensure chances don't exceed 10000 during intermediate calculation
         uint256 totalCheck = currentSuccessChance.add(currentCriticalSuccessChance).add(currentFailureChance).add(currentQuantumShiftChance);
         if (totalCheck > 10000) currentFailureChance = 10000 - currentSuccessChance - currentCriticalSuccessChance - currentQuantumShiftChance;


        // Apply Active Quantum State effects (Modifiers stack or override based on design)
        uint64 currentTime = uint64(block.timestamp);
        if (activeQuantumStates[QuantumState.Amplification] > currentTime) {
             currentSuccessChance = currentSuccessChance.mul(130).div(100); // +30% from QS
        }
        if (activeQuantumStates[QuantumState.Attenuation] > currentTime) {
             currentSuccessChance = currentSuccessChance.div(2); // -50% from QS
        }
         if (activeQuantumStates[QuantumState.Mutation] > currentTime) {
             currentQuantumShiftChance = currentQuantumShiftChance.add(1000); // +10% from QS
        }
         if (activeQuantumStates[QuantumState.Stability] > currentTime) {
             currentFailureChance = currentFailureChance.div(2); // -50% from QS
        }

        // Apply Parameter effect (example: parameter value influences chance)
        // Higher parameter -> higher chance for a specific outcome, lower for others
        if (recipe.allowsParameter && parameter > 0) {
            // Example: Parameter increases Critical Success Chance
            uint256 parameterBonusChance = parameter.div(10); // e.g., param 100 adds 10% (1000 basis points)
            currentCriticalSuccessChance = currentCriticalSuccessChance.add(parameterBonusChance);
            // Redistribute from Failure? Or Success? Let's reduce Failure.
            if (currentFailureChance > parameterBonusChance) {
                currentFailureChance = currentFailureChance.sub(parameterBonusChance);
            } else {
                 currentFailureChance = 0;
            }
        }


        // --- Final Normalization and Outcome Determination ---
        // Sum all chances and normalize if they exceed 10000 (due to compounding bonuses)
        // Or, prioritize outcomes: Failure > QuantumShift > CriticalSuccess > Success
        uint256 finalFailureChance = currentFailureChance;
        uint256 finalQuantumShiftChance = currentQuantumShiftChance;
        uint256 finalCriticalSuccessChance = currentCriticalSuccessChance;
        uint256 finalSuccessChance = currentSuccessChance;


        // Simple clamping: Ensure total is <= 10000 by reducing lowest priority outcomes first
        uint256 totalChance = finalFailureChance.add(finalQuantumShiftChance).add(finalCriticalSuccessChance).add(finalSuccessChance);
        if (totalChance > 10000) {
             uint256 overflow = totalChance.sub(10000);
             // Reduce Success first
             if (finalSuccessChance >= overflow) { finalSuccessChance = finalSuccessChance.sub(overflow); overflow = 0; } else { overflow = overflow.sub(finalSuccessChance); finalSuccessChance = 0; }
             // Reduce Critical Success next
             if (overflow > 0 && finalCriticalSuccessChance >= overflow) { finalCriticalSuccessChance = finalCriticalSuccessChance.sub(overflow); overflow = 0; } else if (overflow > 0) { overflow = overflow.sub(finalCriticalSuccessChance); finalCriticalSuccessChance = 0; }
             // Reduce Quantum Shift next
             if (overflow > 0 && finalQuantumShiftChance >= overflow) { finalQuantumShiftChance = finalQuantumShiftChance.sub(overflow); overflow = 0; } else if (overflow > 0) { overflow = overflow.sub(finalQuantumShiftChance); finalQuantumShiftChance = 0; }
             // Reduce Failure last (shouldn't reach here unless base chances sum > 10k)
             if (overflow > 0 && finalFailureChance >= overflow) { finalFailureChance = finalFailureChance.sub(overflow); overflow = 0; } else if (overflow > 0) { finalFailureChance = 0; }
        }

         // Recalculate total after clamping (should be <= 10000)
         totalChance = finalFailureChance.add(finalQuantumShiftChance).add(finalCriticalSuccessChance).add(finalSuccessChance);
         // The remaining chance up to 10000 will be Failure if we prioritized others, or Success if we normalized differently.
         // Let's make the remainder fall into Failure for simplicity after clamping.
         finalFailureChance = 10000 - finalQuantumShiftChance - finalCriticalSuccessChance - finalSuccessChance;
         if (finalFailureChance > 10000) finalFailureChance = 10000; // Should not happen with clamping logic above


        // Determine outcome based on rolled chance against cumulative probabilities
        uint256 cumulativeChance = 0;

        cumulativeChance = cumulativeChance.add(finalFailureChance);
        if (chanceRoll < cumulativeChance) return TransformationOutcome.Failure;

        cumulativeChance = cumulativeChance.add(finalQuantumShiftChance);
         if (chanceRoll < cumulativeChance) return TransformationOutcome.QuantumShift;

        cumulativeChance = cumulativeChance.add(finalCriticalSuccessChance);
        if (chanceRoll < cumulativeChance) return TransformationOutcome.CriticalSuccess;

        cumulativeChance = cumulativeChance.add(finalSuccessChance);
        if (chanceRoll < cumulativeChance) return TransformationOutcome.Success;

        // Fallback (should ideally not be reached if chances sum correctly)
        return TransformationOutcome.Failure;
    }


    /// @dev Internal function to handle output transfer and state cleanup based on transformation outcome.
    /// @param pt The pending transformation struct.
    /// @param recipe The transformation recipe.
    /// @param outcome The determined outcome.
    function _handleTransformationOutcome(
        PendingTransformation storage pt,
        TransformationRecipe storage recipe,
        TransformationOutcome outcome
    ) internal {
        if (outcome == TransformationOutcome.Success) {
            if (recipe.outputToken != address(0) && recipe.outputAmount > 0) {
                 // Assuming outputToken is ERC20
                 IERC20(recipe.outputToken).safeTransfer(pt.initiator, recipe.outputAmount);
            }
        } else if (outcome == TransformationOutcome.CriticalSuccess) {
             if (recipe.outputToken != address(0) && recipe.criticalSuccessOutputAmount > 0) {
                 // Assuming outputToken is ERC20
                 IERC20(recipe.outputToken).safeTransfer(pt.initiator, recipe.criticalSuccessOutputAmount);
            }
        } else if (outcome == TransformationOutcome.QuantumShift) {
             // Example: Return inputs + a small bonus essence.
             for (uint i = 0; i < recipe.inputTokens.length; i++) {
                 address inputTokenAddress = recipe.inputTokens[i];
                 uint256 inputAmount = recipe.inputAmounts[i];
                 if (inputTokenAddress != address(0) && inputAmount > 0) {
                     // Assuming inputToken is ERC20
                     IERC20(inputTokenAddress).safeTransfer(pt.initiator, inputAmount); // Return inputs
                 }
             }
             uint256 essenceBonus = recipe.essenceCost.div(10); // 10% of essence cost back as bonus
             if (essenceBonus > 0) {
                  essenceBalances[pt.initiator] = essenceBalances[pt.initiator].add(essenceBonus);
                 emit EssenceGenerated(pt.initiator, essenceBonus);
             }
        } else if (outcome == TransformationOutcome.Failure) {
             // Inputs (Essence and tokens) are kept by the contract. They act as 'fees' or are 'burned'.
             // The Essence was already deducted. Input tokens remain in the contract balance.
        }
         // Note: inputs are not returned for Success, CriticalSuccess, or Failure.
         // They are returned for QuantumShift as a special outcome.

         // The pending transformation struct's outcome is already updated.
         // Removing from userPendingTransformationIds is left as an exercise or handled off-chain for gas efficiency.
    }


    /// @notice Returns a list of transformation IDs initiated by a specific user.
    /// @param user The address of the user.
    /// @return An array of transformation IDs.
    function getPendingTransformations(address user) public view returns (uint256[] memory) {
        // Note: This returns *all* IDs the user initiated. Call getTransformationStatus for each ID
        // or filter off-chain to find those still `Pending`.
        return userPendingTransformationIds[user];
    }


    /// @notice Checks if a user is currently eligible to initiate a specific transformation.
    /// This function does not consider delegation allowance.
    /// @param user The address of the user.
    /// @param recipeId The ID of the recipe.
    /// @param parameter The parameter to check (use 0 if recipe is non-parametric).
    /// @return True if the user is eligible, false otherwise. Includes a reason string.
    function checkTransformationEligibility(address user, bytes32 recipeId, uint256 parameter) public view returns (bool, string memory) {
        TransformationRecipe memory recipe = transformationRecipes[recipeId]; // Use memory for view function

        if (recipe.essenceCost == 0 && bytes(recipe.name).length == 0) return (false, "Recipe not found"); // Check if recipe exists
        if (!recipe.isActive) return (false, "Recipe not active");

        if (recipe.allowsParameter) {
            if (recipe.parameterMax > 0 && parameter > recipe.parameterMax) return (false, "Parameter exceeds max allowed");
             // Add other specific parameter validation here if needed, e.g., parameter != 0
        } else { // Not allowsParameter
             if (parameter != 0) return (false, "Recipe does not allow parameter");
        }


        if (essenceBalances[user] < recipe.essenceCost) return (false, "Insufficient essence");

        // Check input tokens
        for (uint i = 0; i < recipe.inputTokens.length; i++) {
            address inputTokenAddress = recipe.inputTokens[i];
            uint256 inputAmount = recipe.inputAmounts[i];

            if (inputAmount > 0) {
                 // address(0) for ETH is not supported by this recipe input method
                 if (inputTokenAddress == address(0) || !isAllowedInputToken[inputTokenAddress]) {
                    return (false, "Input token not allowed");
                 }
                  if (!inputTokenAddress.isContract()) {
                     return (false, "Input token address is not a contract");
                 }

                 IERC20 inputToken = IERC20(inputTokenAddress);
                 // Check user's balance for the input token
                 if (inputToken.balanceOf(user) < inputAmount) return (false, string(abi.encodePacked("Insufficient balance for ", Address.toString(inputTokenAddress))));
                 // Check if user has approved this contract to spend the input tokens
                  if (inputToken.allowance(user, address(this)) < inputAmount) return (false, string(abi.encodePacked("Allowance too low for ", Address.toString(inputTokenAddress))));
            }
        }

        // Add any other global constraints based on state or user properties here

        return (true, "Eligible");
    }


    // --- State Dynamics Functions ---

    /// @notice Updates the contract's ambient energy state. Influences transformation outcomes.
    /// @param newState The new ambient energy state.
    function updateAmbientEnergy(AmbientEnergyState newState) public onlyRole(Role.Alchemist) {
        if (currentAmbientEnergyState == newState) return; // No change
        currentAmbientEnergyState = newState;
        emit AmbientEnergyUpdated(newState);
    }

    /// @notice Returns the current ambient energy state.
    /// @return The current AmbientEnergyState enum value.
    function getAmbientEnergyState() public view returns (AmbientEnergyState) {
        return currentAmbientEnergyState;
    }

    /// @notice Triggers a potential Quantum Flux event, which might activate or deactivate Quantum States. Has a cooldown.
    function triggerQuantumFlux() public onlyRole(Role.Alchemist) {
        if (block.timestamp < lastQuantumFluxTriggerTime.add(quantumFluxCooldown)) {
            revert QuantumFluxOnCooldown();
        }

        lastQuantumFluxTriggerTime = uint64(block.timestamp);

        // Pseudo-randomly decide which states to activate/deactivate and for how long
        // Using blockhash of a recent block + timestamp for pseudo-randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, lastQuantumFluxTriggerTime)));
        uint256 roll = uint256(keccak256(abi.encodePacked(seed, block.difficulty))) % 10000;

        uint64 duration = uint64(roll % (1 days) + 1 hours); // Random duration between 1 hour and 1 day

        // Example logic for state activation/deactivation:
        uint256 stateRoll = roll % 100; // Use part of the roll for state selection

        if (stateRoll < 10) { // 10% chance
             activeQuantumStates[QuantumState.Amplification] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Amplification, activeQuantumStates[QuantumState.Amplification]);
        } else if (stateRoll < 20) { // 10% chance
             activeQuantumStates[QuantumState.Attenuation] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Attenuation, activeQuantumStates[QuantumState.Attenuation]);
        } else if (stateRoll < 25) { // 5% chance
             activeQuantumStates[QuantumState.Mutation] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Mutation, activeQuantumStates[QuantumState.Mutation]);
        } else if (stateRoll < 35) { // 10% chance
             activeQuantumStates[QuantumState.Stability] = uint64(block.timestamp).add(duration);
             emit QuantumStateShift(QuantumState.Stability, activeQuantumStates[QuantumState.Stability]);
        } else if (stateRoll > 90) { // 10% chance to clear *all* states
             for (uint i = 1; i <= uint(type(QuantumState).max); ++i) { // Iterate through all states except None (0)
                  QuantumState state = QuantumState(i);
                   if (activeQuantumStates[state] > block.timestamp) { // Only emit if it was active
                        activeQuantumStates[state] = 0; // Set expiry to 0 (inactive)
                        emit QuantumStateShift(state, 0);
                   } else if (activeQuantumStates[state] > 0 && activeQuantumStates[state] <= block.timestamp) {
                        // If state was active but just expired, ensure it's zero and emit expiry
                         activeQuantumStates[state] = 0;
                         emit QuantumStateShift(state, 0);
                   }
             }
        } else {
            // ~55% chance nothing new is activated. Just let existing states expire naturally.
            // Ensure any expired states are marked inactive and emit event if just expired
            _clearExpiredQuantumStates(); // Clean up expired states explicitly
        }

        emit QuantumFluxTriggered(msg.sender);
    }

    /// @notice Returns a list of currently active Quantum States (those that haven't expired).
    /// @return An array of active QuantumState enum values.
    function getActiveQuantumStates() public view returns (QuantumState[] memory) {
        uint64 currentTime = uint64(block.timestamp);
        QuantumState[] memory activeStates = new QuantumState[](uint(type(QuantumState).max)); // Max possible states
        uint256 count = 0;

         // Iterate through all states except None (0)
        for (uint i = 1; i <= uint(type(QuantumState).max); ++i) {
            QuantumState state = QuantumState(i);
            if (activeQuantumStates[state] > currentTime) {
                activeStates[count] = state;
                count++;
            }
        }

        // Resize array to actual count
        QuantumState[] memory result = new QuantumState[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeStates[i];
        }
        return result;
    }

    /// @dev Internal helper to explicitly clear expired quantum states and emit events.
    /// Called during getActiveQuantumStates and potentially other state-changing functions.
    function _clearExpiredQuantumStates() internal {
         uint64 currentTime = uint64(block.timestamp);
         for (uint i = 1; i <= uint(type(QuantumState).max); ++i) {
            QuantumState state = QuantumState(i);
            if (activeQuantumStates[state] > 0 && activeQuantumStates[state] <= currentTime) {
                activeQuantumStates[state] = 0; // Ensure it's set to 0
                emit QuantumStateShift(state, 0);
            }
        }
    }


    // --- Configuration Functions ---

    /// @notice Sets the address of the resource token used for Essence generation.
    /// @param newToken The address of the new resource token contract.
    function setResourceToken(address newToken) public onlyOwner {
        if (newToken == address(0)) revert InvalidParameter();
        // Remove the old resource token from the allowed list first if it exists (and isn't the new one)
        if (resourceToken != address(0) && isAllowedInputToken[resourceToken] && resourceToken != newToken) {
            isAllowedInputToken[resourceToken] = false;
            // Need to remove from allowedInputTokenList as well (inefficient, but necessary for getAllowedInputTokens)
             uint256 indexToRemove = type(uint256).max;
             for(uint i = 0; i < allowedInputTokenList.length; i++) {
                 if (allowedInputTokenList[i] == resourceToken) {
                     indexToRemove = i;
                     break;
                 }
             }
             if (indexToRemove != type(uint256).max) {
                 if (indexToRemove != allowedInputTokenList.length - 1) {
                     allowedInputTokenList[indexToRemove] = allowedInputTokenList[allowedInputTokenList.length - 1];
                 }
                 allowedInputTokenList.pop();
             }
             // No event for removing the OLD resource token
        }

        resourceToken = newToken;
        // Add the new resource token to allowed inputs (or ensure it's there)
        if (!isAllowedInputToken[newToken]) {
             isAllowedInputToken[newToken] = true;
             allowedInputTokenList.push(newToken);
             emit AllowedInputTokenAdded(newToken); // Emit event for the NEW resource token being added
        }
         // No specific event for changing the resourceToken address itself? Add one if useful.

    }

    /// @notice Sets the rate at which Essence is generated per unit of resource token.
    /// @param newRate The new Essence generation rate.
    function updateEssenceGenerationRate(uint256 newRate) public onlyOwner {
        essenceGenerationRate = newRate;
    }


    /// @notice Adds an ERC20 token address to the whitelist of tokens allowed as transformation inputs.
    /// @param token The address of the ERC20 token contract.
    function addAllowedInputToken(address token) public onlyRole(Role.Alchemist) {
        if (token == address(0) || token == resourceToken) revert InvalidParameter(); // resource token is already allowed and cannot be re-added via this
        if (!token.isContract()) revert InvalidParameter(); // Must be a contract address (assuming ERC20)
        if (!isAllowedInputToken[token]) { // Check if not already added
            isAllowedInputToken[token] = true;
            allowedInputTokenList.push(token);
            emit AllowedInputTokenAdded(token);
        }
    }

    /// @notice Removes an ERC20 token address from the whitelist of tokens allowed as transformation inputs.
    /// @param token The address of the ERC20 token contract.
    function removeAllowedInputToken(address token) public onlyRole(Role.Alchemist) {
        if (token == resourceToken) revert ResourceTokenCannotBeRemoved(); // Resource token cannot be disallowed
        if (isAllowedInputToken[token]) { // Check if currently allowed
             isAllowedInputToken[token] = false;
             // Remove from array by finding index and swapping with last element
             uint256 indexToRemove = type(uint256).max;
             for(uint i = 0; i < allowedInputTokenList.length; i++) {
                 if (allowedInputTokenList[i] == token) {
                     indexToRemove = i;
                     break;
                 }
             }
             if (indexToRemove != type(uint256).max) {
                  // Swap the element to remove with the last element
                 if (indexToRemove != allowedInputTokenList.length - 1) {
                     allowedInputTokenList[indexToRemove] = allowedInputTokenList[allowedInputTokenList.length - 1];
                 }
                 // Remove the last element
                 allowedInputTokenList.pop();
                 emit AllowedInputTokenRemoved(token);
             }
        }
    }

    /// @notice Allows the owner to withdraw specified tokens (e.g., collected inputs from failed transformations) from the contract.
    /// This function assumes the contract holds ERC20 tokens. ETH withdrawal is not standard here.
    /// @param token The address of the token to withdraw. Cannot be address(0).
    /// @param amount The amount of the token to withdraw.
    function withdrawAdminFees(address token, uint256 amount) public onlyOwner {
        if (amount == 0 || token == address(0)) revert InvalidParameter();
        IERC20(token).safeTransfer(owner(), amount);
        emit AdminFundsWithdrawn(token, owner(), amount);
    }

    // --- Query Functions ---

    // getRole, getEssenceBalance, calculateEssenceGeneration,
    // getTransformationRecipe, getAllRecipes, updateTransformationCost (config, but queried here),
    // getTransformationStatus, getPendingTransformations,
    // getAmbientEnergyState, getActiveQuantumStates, checkTransformationEligibility (all above 20)


    /// @notice Returns the current Essence generation rate.
    function getEssenceGenerationRate() public view returns (uint256) {
        return essenceGenerationRate;
    }

    /// @notice Returns the address of the resource token.
    function getResourceToken() public view returns (address) {
        return resourceToken;
    }

    /// @notice Returns the list of all ERC20 tokens currently allowed as transformation inputs.
    /// @return An array of allowed input token addresses.
    function getAllowedInputTokens() public view returns (address[] memory) {
        return allowedInputTokenList;
    }

    /// @notice Checks if a specific token is allowed as a transformation input.
    /// @param token The address of the token to check.
    /// @return True if the token is allowed, false otherwise.
    function isInputTokenAllowed(address token) public view returns (bool) {
         // Checks against the mapping for efficiency
         return isAllowedInputToken[token];
    }

    /// @notice Returns the total number of registered transformation recipes (active or inactive).
    function getRecipeCount() public view returns (uint256) {
        return registeredRecipeIds.length;
    }

    /// @notice Returns the total number of transformations initiated ever.
    function getTotalTransformationsInitiated() public view returns (uint256) {
        return nextTransformationId - 1; // Since IDs start at 1
    }

    /// @notice Returns the current delegation allowance for a specific delegatee by a delegator.
    /// @param delegator The address who granted the allowance.
    /// @param delegatee The address who received the allowance.
    /// @return The remaining Essence cost limit the delegatee can initiate for the delegator.
    function getTransformationDelegatedAllowance(address delegator, address delegatee) public view returns (uint256) {
        return transformationDelegatedAllowance[delegator][delegatee];
    }

    /// @notice Returns the cooldown period for triggering a Quantum Flux event.
    function getQuantumFluxCooldown() public view returns (uint64) {
        return quantumFluxCooldown;
    }

     /// @notice Returns the timestamp of the last time Quantum Flux was triggered.
    function getLastQuantumFluxTriggerTime() public view returns (uint64) {
        return lastQuantumFluxTriggerTime;
    }

    // Total function count check again:
    // Public/External: 35+. Looks good.
    // Concepts: Timed process (duration), State influence (AmbientEnergy, QuantumStates), Parametric inputs,
    // Delegation, Role-based access, Dynamic configuration, Complex outcome calculation, Batch processing.
    // Avoids simple ERC20/NFT minting as the core logic, uses libraries for safety.
    // Outline and summary provided.


    // Note: The pseudo-randomness based on block data is predictable to miners. For real-world critical applications
    // requiring unpredictability, a decentralized oracle like Chainlink VRF is necessary.
    // This contract is for demonstration of complex logic and state interaction.
}
```