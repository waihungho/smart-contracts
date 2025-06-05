Okay, here is a Solidity smart contract draft based on the theme of a "Quantum Forge" – a system for creating, evolving, and interacting with dynamic, non-fungible digital artifacts ("Quanta") influenced by time and external data, using multiple resources.

This contract incorporates concepts like:
*   **Dynamic State:** Quanta artifacts have states that change based on time, interactions, and external data.
*   **Resource Management:** Requires specific ERC-20 "Element" tokens for forging, tuning, and recharging.
*   **Oracle Integration:** Allows external data (via an oracle) to influence artifact properties or states.
*   **Bonding/Entanglement:** Artifacts can be linked, potentially affecting each other.
*   **Time-based Mechanics:** Decay, time locks, state changes over time.
*   **Delegation:** Owners can delegate specific permissions (e.g., tuning).
*   **Tiered Crafting (Forging):** Uses predefined recipes with different inputs and outcomes.
*   **Internal Charge System:** Artifacts have a charge that depletes, requiring recharge.

This contract is *not* a standard ERC-721, although it manages non-fungible ownership. It uses custom structs and mappings for artifact data and logic.

---

**QuantumForge Smart Contract**

**Outline:**

1.  **Contract Information:** SPDX License, Solidity version, Contract Name.
2.  **Imports:** ERC20 standard interface, Oracle interface (simple placeholder).
3.  **Error Definitions:** Custom errors for clarity and gas efficiency (Solidity 0.8.4+).
4.  **State Variables:**
    *   Owner address.
    *   Fee recipient address.
    *   Element ERC-20 token address.
    *   Oracle address.
    *   Base forging fee (native currency).
    *   Quanta counter for unique IDs.
    *   Pause state.
5.  **Data Structures:**
    *   `enum QuantaState`: Defines possible states of an artifact.
    *   `struct Quanta`: Holds all dynamic properties of an artifact (ID, name, state, stability, resonance, charge, forge time, last state change/interaction time, bonded artifact ID, tuning delegate, transfer lock time).
    *   `struct Recipe`: Defines inputs and base outputs for forging different types of Quanta.
6.  **Mappings:**
    *   `idToQuanta`: Maps Quanta ID to its struct.
    *   `idToOwner`: Maps Quanta ID to owner address (similar to ERC721 `ownerOf`).
    *   `ownerToQuantaIds`: Maps owner address to an array of owned Quanta IDs (for querying).
    *   `recipes`: Maps recipe ID to its struct.
7.  **Events:** Significant actions and state changes.
8.  **Modifiers:** Access control, state checks.
9.  **Constructor:** Initializes owner, basic parameters.
10. **Admin/Setup Functions:**
    *   Set fee recipient, element token, oracle address, base fee.
    *   Add/Remove/Update forging recipes.
    *   Withdraw collected fees.
    *   Pause/Unpause contract.
11. **Core Mechanics (User Interaction):**
    *   `forgeQuanta`: Create a new Quanta using a recipe, elements, and fee.
    *   `tuneQuanta`: Use elements to improve stability/resonance, consume charge.
    *   `rechargeQuanta`: Use elements to replenish charge.
    *   `applyExternalInfluence`: Trigger state/property change based on oracle data.
    *   `bondQuanta`: Link two Quanta.
    *   `unbondQuanta`: Break a link.
    *   `triggerChainReaction`: Special interaction between bonded Quanta based on state/charge.
12. **Lifecycle/State Management:**
    *   `checkAndApplyDecay`: Public function to check and apply time/charge-based decay.
    *   `updateQuantaStateFromConditions`: Internal function to evaluate and change state based on current properties.
13. **Ownership & Utility Functions:**
    *   `transferQuanta`: Transfer ownership (respecting time locks).
    *   `delegateTuningPermission`: Allow another address to tune a specific Quanta.
    *   `removeTuningDelegate`: Remove a delegate.
    *   `setTimeLock`: Prevent transfer until a specific time.
    *   `clearTimeLock`: Remove time lock after expiry.
14. **Query Functions (View/Pure):**
    *   Get details of a specific Quanta or recipe.
    *   Get owner of a Quanta.
    *   Get Quanta IDs owned by an address.
    *   Check bonding status, get bonded ID.
    *   Calculate dynamic forging fee.
    *   Get total number of forged Quanta.

**Function Summary:**

1.  `constructor(address _feeRecipient, address _elementToken, address _oracle, uint256 _baseFee)`: Initializes contract owner, fee recipient, element token, oracle address, and base fee.
2.  `setFeeRecipient(address _recipient)`: Sets the address where fees are sent (Owner only).
3.  `setElementToken(address _token)`: Sets the address of the ERC-20 token used as 'Elements' (Owner only).
4.  `setOracleAddress(address _oracle)`: Sets the address of the oracle contract (Owner only).
5.  `setBaseFee(uint256 _baseFee)`: Sets the base fee required for forging (Owner only).
6.  `addRecipe(uint256 recipeId, string memory name, address[] memory requiredElementTokens, uint256[] memory requiredElementAmounts, uint256 baseCharge, uint256 initialStability, uint256 initialResonance, uint256 baseFeeOverride, QuantaState initialState)`: Adds a new forging recipe (Owner only).
7.  `removeRecipe(uint256 recipeId)`: Removes an existing forging recipe (Owner only).
8.  `updateRecipe(uint256 recipeId, string memory name, address[] memory requiredElementTokens, uint256[] memory requiredElementAmounts, uint256 baseCharge, uint256 initialStability, uint256 initialResonance, uint256 baseFeeOverride, QuantaState initialState)`: Updates an existing forging recipe (Owner only).
9.  `withdrawFees()`: Withdraws accumulated native currency fees to the fee recipient (Owner only).
10. `pauseContract()`: Pauses core functionality (forging, tuning, etc.) (Owner only).
11. `unpauseContract()`: Unpauses the contract (Owner only).
12. `forgeQuanta(uint256 recipeId, string memory quantaName)`: Creates a new Quanta based on a recipe, requiring payment of native currency fee and transfer of element tokens.
13. `tuneQuanta(uint256 tokenId, address elementToken, uint256 amount)`: Allows the owner or delegate to use element tokens to increase stability and resonance of a Quanta, consuming charge.
14. `rechargeQuanta(uint256 tokenId, address elementToken, uint256 amount)`: Allows the owner to use element tokens to replenish the charge of a Quanta.
15. `applyExternalInfluence(uint256 tokenId)`: Allows anyone to trigger an update to the Quanta's state and properties based on current data from the configured oracle.
16. `bondQuanta(uint256 tokenId1, uint256 tokenId2)`: Bonds two Quanta artifacts together, linking them bi-directionally (Owner of both only).
17. `unbondQuanta(uint256 tokenId)`: Unbonds a Quanta from its linked partner (Owner only).
18. `triggerChainReaction(uint256 tokenId)`: A special interaction function that has different effects based on the state and bond status of the Quanta.
19. `checkAndApplyDecay(uint256 tokenId)`: Allows anyone to check if a Quanta should decay based on time and charge, and applies the decay effect if necessary.
20. `transferQuanta(address to, uint256 tokenId)`: Transfers ownership of a Quanta, respecting time locks (Owner only).
21. `delegateTuningPermission(uint256 tokenId, address delegate)`: Sets an address allowed to call `tuneQuanta` for a specific artifact (Owner only).
22. `removeTuningDelegate(uint256 tokenId)`: Removes the tuning delegate for a specific artifact (Owner only).
23. `setTimeLock(uint256 tokenId, uint256 unlockTime)`: Sets a timestamp before which the artifact cannot be transferred (Owner only).
24. `clearTimeLock(uint256 tokenId)`: Clears an expired time lock, allowing transfer (Owner only).
25. `getQuantaDetails(uint256 tokenId)`: Returns the detailed properties of a specific Quanta (View).
26. `getRecipeDetails(uint256 recipeId)`: Returns the details of a specific forging recipe (View).
27. `getQuantaOwner(uint256 tokenId)`: Returns the owner of a specific Quanta (View).
28. `getOwnerQuantaIds(address owner)`: Returns an array of Quanta IDs owned by an address (View - note: can be gas-intensive for large collections).
29. `calculateCurrentFee(uint256 recipeId)`: Calculates the actual forging fee for a recipe, potentially incorporating external data (View).
30. `isBonded(uint256 tokenId)`: Checks if a Quanta is bonded to another (View).
31. `getBondedQuanta(uint256 tokenId)`: Returns the ID of the Quanta it is bonded to, or 0 if not bonded (View).
32. `getTotalQuantaCount()`: Returns the total number of Quanta ever forged (View).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Simple Placeholder Interfaces
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IOracle {
    // Example: Get a combined value from oracle data
    function getValue() external view returns (uint256);
    // Example: Get data points
    function getDataPoint(string memory key) external view returns (uint256);
}

/**
 * @title QuantumForge
 * @dev A smart contract for forging, evolving, and managing dynamic digital artifacts called Quanta.
 * Quanta have states, properties that change over time and based on interactions/oracle data,
 * require element tokens for maintenance, and can be bonded together.
 */
contract QuantumForge {

    // --- Errors ---
    error NotOwner();
    error NotPaused();
    error IsPaused();
    error RecipeDoesNotExist(uint256 recipeId);
    error QuantaDoesNotExist(uint256 tokenId);
    error NotQuantaOwner(uint256 tokenId);
    error NotQuantaDelegate(uint256 tokenId);
    error TransferLocked(uint256 tokenId, uint256 unlockTime);
    error NotBonded(uint256 tokenId);
    error AlreadyBonded(uint256 tokenId);
    error CannotBondSelf();
    error BondedToDifferentPartner(uint256 tokenId1, uint256 tokenId2);
    error InsufficientElements(address token, uint256 required, uint256 has);
    error InsufficientNativeFee(uint256 required, uint256 sent);
    error ElementTokenNotRequired(address token);
    error InvalidElementAmount(address token, uint256 expectedCount, uint256 actualCount);
    error InvalidRecipeInputLengths();
    error InvalidQuantaState(QuantaState currentState, string memory requiredStates);
    error OracleNotSet();


    // --- State Variables ---
    address public owner;
    address payable public feeRecipient;
    address public elementTokenAddress; // Main ERC-20 token for general element use
    address public oracleAddress;
    uint256 public baseFee = 1 ether; // Base native currency fee for forging
    uint256 private _quantaCounter = 0; // Counter for unique Quanta IDs
    bool public paused = false;

    // --- Data Structures ---
    enum QuantaState {
        Stable,     // Durable, slow decay
        Unstable,   // Prone to decay, sensitive to influence
        Resonant,   // Amplifies effects, faster charge consumption
        Decayed,    // Requires significant effort to restore, limited interaction
        Bonded      // Linked to another Quanta, state influenced by partner
    }

    struct Quanta {
        uint256 id;
        string name;
        QuantaState state;
        uint256 stability;      // Resistance to decay/negative influence
        uint256 resonance;      // Magnifies effects of tuning/influence
        uint256 charge;         // Resource depleted by actions/time
        uint256 forgeTime;      // Timestamp of creation
        uint256 lastInteractionTime; // Timestamp of last tune, recharge, influence, or state change
        uint256 bondedToId;     // ID of the Quanta it is bonded to (0 if not bonded)
        address delegateTuner;  // Address allowed to call tuneQuanta (0x0 if none)
        uint256 transferLockUntil; // Timestamp until which transfer is locked (0 if not locked)
    }

    struct Recipe {
        uint256 recipeId;
        string name;
        address[] requiredElementTokens; // Addresses of specific element tokens required
        uint256[] requiredElementAmounts; // Amounts of required specific element tokens
        uint256 baseCharge;
        uint256 initialStability;
        uint256 initialResonance;
        uint256 baseFeeOverride; // If > 0, overrides baseFee for this recipe
        QuantaState initialState;
    }

    // --- Mappings ---
    mapping(uint256 => Quanta) private idToQuanta;
    mapping(uint256 => address) private idToOwner;
    mapping(address => uint256[]) private ownerToQuantaIds; // List of IDs owned by an address
    mapping(uint256 => Recipe) private recipes;
    mapping(uint256 => bool) private recipeExists; // Helper to quickly check if recipeId is valid


    // --- Events ---
    event QuantaForged(uint256 indexed tokenId, address indexed owner, uint256 recipeId, string name);
    event QuantaTuned(uint256 indexed tokenId, address indexed tuner, uint256 elementAmount, uint256 newStability, uint256 newResonance, uint256 newCharge);
    event QuantaRecharged(uint256 indexed tokenId, address indexed owner, uint256 elementAmount, uint256 newCharge);
    event ExternalInfluenceApplied(uint256 indexed tokenId, uint256 oracleValue, QuantaState newState);
    event QuantaBonded(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event QuantaUnbonded(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ChainReactionTriggered(uint256 indexed tokenId, QuantaState state, uint256 charge);
    event QuantaDecayed(uint256 indexed tokenId, QuantaState newState);
    event StateChanged(uint256 indexed tokenId, QuantaState oldState, QuantaState newState);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721-like transfer event
    event DelegateUpdated(uint256 indexed tokenId, address indexed oldDelegate, address indexed newDelegate);
    event TimeLockUpdated(uint256 indexed tokenId, uint256 unlockTime);
    event RecipeAdded(uint256 indexed recipeId, string name);
    event RecipeRemoved(uint256 indexed recipeId);
    event RecipeUpdated(uint256 indexed recipeId);
    event FeeWithdrawn(uint256 amount);
    event OracleAddressUpdated(address oldAddress, address newAddress);
    event FeeRecipientUpdated(address oldAddress, address newAddress);
    event Paused(address account);
    event Unpaused(address account);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert IsPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier isQuantaOwner(uint256 tokenId) {
        if (idToOwner[tokenId] == address(0) || idToOwner[tokenId] != msg.sender) revert NotQuantaOwner(tokenId);
        _;
    }

    modifier isQuantaDelegate(uint256 tokenId) {
         if (idToQuanta[tokenId].delegateTuner != msg.sender) revert NotQuantaDelegate(tokenId);
         _;
    }

    modifier quantaExists(uint256 tokenId) {
        if (idToOwner[tokenId] == address(0)) revert QuantaDoesNotExist(tokenId);
        _;
    }

    modifier recipeMustExist(uint256 recipeId) {
        if (!recipeExists[recipeId]) revert RecipeDoesNotExist(recipeId);
        _;
    }

    // --- Constructor ---
    constructor(address payable _feeRecipient, address _elementToken, address _oracle, uint256 _baseFee) {
        owner = msg.sender;
        feeRecipient = _feeRecipient;
        elementTokenAddress = _elementToken;
        oracleAddress = _oracle;
        baseFee = _baseFee;
    }

    // --- Admin/Setup Functions (1-11) ---

    /**
     * @dev Sets the address to receive collected fees.
     * @param _recipient The new fee recipient address.
     */
    function setFeeRecipient(address payable _recipient) external onlyOwner {
        address oldRecipient = feeRecipient;
        feeRecipient = _recipient;
        emit FeeRecipientUpdated(oldRecipient, _recipient);
    }

    /**
     * @dev Sets the address of the main Element ERC-20 token.
     * @param _token The address of the Element token contract.
     */
    function setElementToken(address _token) external onlyOwner {
        address oldToken = elementTokenAddress;
        elementTokenAddress = _token;
        // Ideally validate token interface here, but skipped for brevity
        // require(IERC20(_token).supportsInterface(...), "Invalid ERC20 interface");
        emit ElementAddressUpdated(oldToken, _token); // Assuming ElementAddressUpdated event exists
    }

    /**
     * @dev Sets the address of the oracle contract.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        address oldOracle = oracleAddress;
        oracleAddress = _oracle;
        // Ideally validate oracle interface here
        emit OracleAddressUpdated(oldOracle, _oracle);
    }

     /**
     * @dev Sets the base fee for forging Quanta.
     * @param _baseFee The new base fee amount in native currency.
     */
    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }


    /**
     * @dev Adds a new recipe for forging Quanta.
     * @param recipeId Unique identifier for the recipe.
     * @param name Name of the recipe.
     * @param requiredElementTokens Addresses of element tokens needed (must match requiredElementAmounts length).
     * @param requiredElementAmounts Amounts of each element token needed (must match requiredElementTokens length).
     * @param baseCharge Initial charge of the forged Quanta.
     * @param initialStability Initial stability of the forged Quanta.
     * @param initialResonance Initial resonance of the forged Quanta.
     * @param baseFeeOverride Fee override for this recipe (0 to use contract base fee).
     * @param initialState Initial state of the forged Quanta.
     */
    function addRecipe(
        uint256 recipeId,
        string memory name,
        address[] memory requiredElementTokens,
        uint256[] memory requiredElementAmounts,
        uint256 baseCharge,
        uint256 initialStability,
        uint256 initialResonance,
        uint256 baseFeeOverride,
        QuantaState initialState
    ) external onlyOwner {
        require(!recipeExists[recipeId], "Recipe already exists");
        if (requiredElementTokens.length != requiredElementAmounts.length) revert InvalidRecipeInputLengths();

        recipes[recipeId] = Recipe(
            recipeId,
            name,
            requiredElementTokens,
            requiredElementAmounts,
            baseCharge,
            initialStability,
            initialResonance,
            baseFeeOverride,
            initialState
        );
        recipeExists[recipeId] = true;

        emit RecipeAdded(recipeId, name);
    }

    /**
     * @dev Removes an existing forging recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeRecipe(uint256 recipeId) external onlyOwner recipeMustExist(recipeId) {
        delete recipes[recipeId];
        recipeExists[recipeId] = false;
        emit RecipeRemoved(recipeId);
    }

     /**
     * @dev Updates an existing forging recipe.
     * @param recipeId Unique identifier for the recipe.
     * @param name Name of the recipe.
     * @param requiredElementTokens Addresses of element tokens needed (must match requiredElementAmounts length).
     * @param requiredElementAmounts Amounts of each element token needed (must match requiredElementTokens length).
     * @param baseCharge Initial charge of the forged Quanta.
     * @param initialStability Initial stability of the forged Quanta.
     * @param initialResonance Initial resonance of the forged Quanta.
     * @param baseFeeOverride Fee override for this recipe (0 to use contract base fee).
     * @param initialState Initial state of the forged Quanta.
     */
    function updateRecipe(
        uint256 recipeId,
        string memory name,
        address[] memory requiredElementTokens,
        uint256[] memory requiredElementAmounts,
        uint256 baseCharge,
        uint256 initialStability,
        uint256 initialResonance,
        uint256 baseFeeOverride,
        QuantaState initialState
    ) external onlyOwner recipeMustExist(recipeId) {
        if (requiredElementTokens.length != requiredElementAmounts.length) revert InvalidRecipeInputLengths();

        recipes[recipeId] = Recipe(
            recipeId,
            name,
            requiredElementTokens,
            requiredElementAmounts,
            baseCharge,
            initialStability,
            initialResonance,
            baseFeeOverride,
            initialState
        );

        emit RecipeUpdated(recipeId);
    }

    /**
     * @dev Withdraws accumulated native currency fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            feeRecipient.transfer(balance);
            emit FeeWithdrawn(balance);
        }
    }

    /**
     * @dev Pauses key contract functionality. Owner only.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Owner only.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Core Mechanics (12-18) ---

    /**
     * @dev Forges a new Quanta artifact based on a recipe.
     * Requires native currency payment and transfer of required element tokens.
     * @param recipeId The ID of the recipe to use.
     * @param quantaName The desired name for the new Quanta.
     */
    function forgeQuanta(uint256 recipeId, string memory quantaName)
        external
        payable
        whenNotPaused
        recipeMustExist(recipeId)
    {
        Recipe storage recipe = recipes[recipeId];
        uint256 requiredFee = calculateCurrentFee(recipeId);

        if (msg.value < requiredFee) revert InsufficientNativeFee(requiredFee, msg.value);

        // Pay excess native currency back
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }

        // Transfer required element tokens
        for (uint i = 0; i < recipe.requiredElementTokens.length; i++) {
            address elementAddress = recipe.requiredElementTokens[i];
            uint256 amount = recipe.requiredElementAmounts[i];

            if (IERC20(elementAddress).balanceOf(msg.sender) < amount)
                revert InsufficientElements(elementAddress, amount, IERC20(elementAddress).balanceOf(msg.sender));

            // Approve the contract or ensure prior approval
            // In a real scenario, users would need to approve this contract beforehand
            // For this example, we assume approval is handled off-chain or in a wrapper contract
             require(IERC20(elementAddress).transferFrom(msg.sender, address(this), amount), "Element transfer failed");
        }

        // Mint the new Quanta
        _quantaCounter++;
        uint256 newTokenId = _quantaCounter;
        uint256 currentTime = block.timestamp;

        idToQuanta[newTokenId] = Quanta({
            id: newTokenId,
            name: quantaName,
            state: recipe.initialState,
            stability: recipe.initialStability,
            resonance: recipe.initialResonance,
            charge: recipe.baseCharge,
            forgeTime: currentTime,
            lastInteractionTime: currentTime,
            bondedToId: 0, // Not bonded initially
            delegateTuner: address(0), // No delegate initially
            transferLockUntil: 0 // Not locked initially
        });

        idToOwner[newTokenId] = msg.sender;
        ownerToQuantaIds[msg.sender].push(newTokenId);

        emit QuantaForged(newTokenId, msg.sender, recipeId, quantaName);
        emit Transfer(address(0), msg.sender, newTokenId); // Simulate mint transfer event
    }

     /**
     * @dev Allows the owner or delegate to use elements to tune a Quanta.
     * Tuning increases stability and resonance, consumes charge.
     * @param tokenId The ID of the Quanta to tune.
     * @param elementToken Address of the element token used.
     * @param amount Amount of element token used.
     */
    function tuneQuanta(uint256 tokenId, address elementToken, uint256 amount)
        external
        whenNotPaused
        quantaExists(tokenId)
    {
        // Check if sender is owner or delegate
        if (idToOwner[tokenId] != msg.sender && idToQuanta[tokenId].delegateTuner != msg.sender) {
            revert NotQuantaOwner(tokenId); // Revert with owner specific error if not delegate, or create new error
            // Note: For clarity here, I reuse NotQuantaOwner, but a specific error like NotAllowedToTune is better.
        }

        // Check if element token is the primary one (or other logic for specific tuning elements)
        if (elementToken != elementTokenAddress) revert ElementTokenNotRequired(elementToken); // Example check

        if (IERC20(elementToken).balanceOf(msg.sender) < amount)
            revert InsufficientElements(elementToken, amount, IERC20(elementToken).balanceOf(msg.sender));

        require(IERC20(elementToken).transferFrom(msg.sender, address(this), amount), "Element transfer failed");

        Quanta storage quanta = idToQuanta[tokenId];
        uint256 oldCharge = quanta.charge;

        // Tuning effect: Increase stability & resonance, consume charge
        // Effects can be more complex: diminishing returns, based on state, etc.
        uint256 stabilityIncrease = amount / 10; // Example formula
        uint256 resonanceIncrease = amount / 20; // Example formula
        uint256 chargeConsumption = amount * 2; // Example formula (tuning consumes charge faster than element amount)

        quanta.stability += stabilityIncrease;
        quanta.resonance += resonanceIncrease;

        if (quanta.charge < chargeConsumption) {
            quanta.charge = 0;
        } else {
             quanta.charge -= chargeConsumption;
        }


        quanta.lastInteractionTime = block.timestamp;

        // Check and potentially update state after tuning
        updateQuantaStateFromConditions(tokenId);

        emit QuantaTuned(tokenId, msg.sender, amount, quanta.stability, quanta.resonance, quanta.charge);
    }

    /**
     * @dev Allows the owner to use elements to recharge a Quanta's internal charge.
     * @param tokenId The ID of the Quanta to recharge.
     * @param elementToken Address of the element token used.
     * @param amount Amount of element token used.
     */
    function rechargeQuanta(uint256 tokenId, address elementToken, uint256 amount)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
    {
         if (elementToken != elementTokenAddress) revert ElementTokenNotRequired(elementToken); // Example check

         if (IERC20(elementToken).balanceOf(msg.sender) < amount)
            revert InsufficientElements(elementToken, amount, IERC20(elementToken).balanceOf(msg.sender));

        require(IERC20(elementToken).transferFrom(msg.sender, address(this), amount), "Element transfer failed");

        Quanta storage quanta = idToQuanta[tokenId];
        uint256 oldCharge = quanta.charge;

        // Recharge effect: Increase charge
        quanta.charge += amount * 5; // Example formula (recharge is efficient)

        quanta.lastInteractionTime = block.timestamp;

         // Check and potentially update state after recharge (e.g., if it was Decayed)
        updateQuantaStateFromConditions(tokenId);

        emit QuantaRecharged(tokenId, msg.sender, amount, quanta.charge);
    }


    /**
     * @dev Allows anyone to trigger an update based on external oracle data.
     * This can change the Quanta's state or properties.
     * @param tokenId The ID of the Quanta to influence.
     */
    function applyExternalInfluence(uint256 tokenId)
        external
        whenNotPaused
        quantaExists(tokenId)
    {
        if (oracleAddress == address(0)) revert OracleNotSet();

        IOracle oracle = IOracle(oracleAddress);
        uint256 oracleValue = oracle.getValue(); // Example call

        Quanta storage quanta = idToQuanta[tokenId];
        QuantaState oldState = quanta.state;

        // Example Influence Logic:
        // If oracle value is high, maybe increase resonance slightly, reduce stability slightly.
        // If oracle value is low, maybe increase stability, reduce resonance.
        // Specific oracle data points could trigger state changes.
        // For instance, if oracle.getDataPoint("marketVolatility") > someThreshold, state changes to Unstable.

        // Simplified example:
        if (oracleValue > 1000) { // Example threshold
            quanta.resonance += oracleValue / 500;
            if (quanta.stability > oracleValue / 1000) quanta.stability -= oracleValue / 1000;
        } else {
             quanta.stability += (1000 - oracleValue) / 500;
             if (quanta.resonance > (1000 - oracleValue) / 1000) quanta.resonance -= (1000 - oracleValue) / 1000;
        }

        quanta.lastInteractionTime = block.timestamp;

        // Re-evaluate state after influence
        updateQuantaStateFromConditions(tokenId);

        emit ExternalInfluenceApplied(tokenId, oracleValue, quanta.state);
    }

    /**
     * @dev Bonds two Quanta artifacts together. Both owners must call this.
     * @param tokenId1 The ID of the first Quanta.
     * @param tokenId2 The ID of the second Quanta.
     */
    function bondQuanta(uint256 tokenId1, uint256 tokenId2)
        external
        whenNotPaused
        quantaExists(tokenId1)
        quantaExists(tokenId2)
    {
        if (tokenId1 == tokenId2) revert CannotBondSelf();
        if (idToOwner[tokenId1] != msg.sender && idToOwner[tokenId2] != msg.sender) revert NotQuantaOwner(tokenId1); // Must own at least one
        if (idToOwner[tokenId1] != idToOwner[tokenId2]) revert NotQuantaOwner(0); // For simplicity, require single owner for bonding in this example

        Quanta storage quanta1 = idToQuanta[tokenId1];
        Quanta storage quanta2 = idToQuanta[tokenId2];

        if (quanta1.bondedToId != 0 || quanta2.bondedToId != 0) revert AlreadyBonded(quanta1.bondedToId != 0 ? tokenId1 : tokenId2);

        quanta1.bondedToId = tokenId2;
        quanta2.bondedToId = tokenId1;

        QuantaState oldState1 = quanta1.state;
        QuantaState oldState2 = quanta2.state;

        // Bonding might change state, e.g., to Bonded
        quanta1.state = QuantaState.Bonded;
        quanta2.state = QuantaState.Bonded;

        quanta1.lastInteractionTime = block.timestamp;
        quanta2.lastInteractionTime = block.timestamp;

        if (oldState1 != QuantaState.Bonded) emit StateChanged(tokenId1, oldState1, QuantaState.Bonded);
        if (oldState2 != QuantaState.Bonded) emit StateChanged(tokenId2, oldState2, QuantaState.Bonded);

        emit QuantaBonded(tokenId1, tokenId2);
    }

    /**
     * @dev Unbonds a Quanta from its partner. Only the owner can call.
     * @param tokenId The ID of the Quanta to unbond.
     */
    function unbondQuanta(uint256 tokenId)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
        quantaExists(tokenId)
    {
        Quanta storage quanta1 = idToQuanta[tokenId];
        if (quanta1.bondedToId == 0) revert NotBonded(tokenId);

        uint256 tokenId2 = quanta1.bondedToId;
        Quanta storage quanta2 = idToQuanta[tokenId2];

        if (quanta2.bondedToId != tokenId) revert BondedToDifferentPartner(tokenId, tokenId2); // Sanity check

        quanta1.bondedToId = 0;
        quanta2.bondedToId = 0;

        // Re-evaluate state after unbonding (e.g., revert to Stable or Unstable based on properties)
        updateQuantaStateFromConditions(tokenId);
        updateQuantaStateFromConditions(tokenId2);

        emit QuantaUnbonded(tokenId, tokenId2);
    }


    /**
     * @dev Triggers a special "Chain Reaction" interaction.
     * Effect depends on the Quanta's state and whether it's bonded.
     * Consumes charge regardless.
     * @param tokenId The ID of the Quanta initiating the reaction.
     */
    function triggerChainReaction(uint256 tokenId)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
        quantaExists(tokenId)
    {
        Quanta storage quanta = idToQuanta[tokenId];
        uint256 oldCharge = quanta.charge;
        QuantaState oldState = quanta.state;

        // Consume charge
        uint256 chargeConsumption = 500; // Example
        if (quanta.charge < chargeConsumption) {
            quanta.charge = 0;
        } else {
            quanta.charge -= chargeConsumption;
        }

        // Effects based on state and bonding
        if (quanta.state == QuantaState.Resonant && quanta.bondedToId != 0) {
             // Resonant + Bonded: Significant positive effect on both
             uint256 bondedId = quanta.bondedToId;
             Quanta storage bondedQuanta = idToQuanta[bondedId];
             uint256 boost = quanta.resonance / 10 + bondedQuanta.resonance / 10; // Boost based on resonance
             quanta.stability += boost;
             bondedQuanta.stability += boost;
             quanta.charge += boost / 2; // Reaction might generate some charge
             bondedQuanta.charge += boost / 2;
             // State might change if boost is high enough
             updateQuantaStateFromConditions(bondedId);

        } else if (quanta.state == QuantaState.Unstable) {
            // Unstable: High chance of decay or negative effect
            // Simple deterministic example: reduce stability significantly
            quanta.stability /= 2;
            if (quanta.stability < 10) quanta.stability = 10; // Floor
        }
        // Add more state/bond combinations

        quanta.lastInteractionTime = block.timestamp;
        updateQuantaStateFromConditions(tokenId);

        emit ChainReactionTriggered(tokenId, quanta.state, quanta.charge);
        if (oldState != quanta.state) emit StateChanged(tokenId, oldState, quanta.state);
    }

    // --- Lifecycle/State Management (19) ---

    /**
     * @dev Checks if a Quanta should decay based on time and charge, and applies decay if needed.
     * Can be called by anyone (incentivizes keeping state updated).
     * Decay reduces stability and charge, and can change state.
     * @param tokenId The ID of the Quanta to check.
     */
    function checkAndApplyDecay(uint256 tokenId)
        external
        whenNotPaused
        quantaExists(tokenId)
    {
        Quanta storage quanta = idToQuanta[tokenId];
        uint256 timeSinceLastInteraction = block.timestamp - quanta.lastInteractionTime;

        // Decay formula example: faster decay if Unstable, slower if Stable/Bonded, requires time and consumes charge
        uint256 decayRate = 100; // Base decay units per time unit
        if (quanta.state == QuantaState.Unstable) decayRate = 200;
        if (quanta.state == QuantaState.Stable || quanta.state == QuantaState.Bonded) decayRate = 50;
        if (quanta.state == QuantaState.Decayed) decayRate = 0; // Already decayed

        uint256 potentialDecay = timeSinceLastInteraction * decayRate;

        if (potentialDecay > 0) {
             uint256 chargeUsedInDecay = potentialDecay / 5; // Decay consumes charge

             if (quanta.charge < chargeUsedInDecay) {
                 quanta.charge = 0;
                 // Additional decay penalty if charge hits zero during potential decay period
                 potentialDecay += (chargeUsedInDecay - quanta.charge) * 2;
             } else {
                 quanta.charge -= chargeUsedInDecay;
             }

             if (quanta.stability > potentialDecay) {
                quanta.stability -= potentialDecay;
             } else {
                quanta.stability = 0; // Can't go below zero
             }

             quanta.lastInteractionTime = block.timestamp; // Update interaction time after checking

             // Re-evaluate state after decay
             updateQuantaStateFromConditions(tokenId);

             emit QuantaDecayed(tokenId, quanta.state);
        }
    }

    /**
     * @dev Internal function to update a Quanta's state based on its current properties.
     * Called after actions that change stability, resonance, charge, or bonding status.
     * @param tokenId The ID of the Quanta to update.
     */
    function updateQuantaStateFromConditions(uint256 tokenId) internal {
        Quanta storage quanta = idToQuanta[tokenId];
        QuantaState oldState = quanta.state;
        QuantaState newState = oldState; // Assume state doesn't change

        // Example State Transition Logic:
        if (quanta.bondedToId != 0) {
            newState = QuantaState.Bonded; // Bonding overrides other states
        } else if (quanta.stability == 0 || quanta.charge == 0 && block.timestamp > quanta.forgeTime + 1 days) { // Decay takes time unless properties are zero
            newState = QuantaState.Decayed;
        } else if (quanta.resonance > 500 && quanta.stability > 200 && quanta.charge > 100) { // Example thresholds
             newState = QuantaState.Resonant;
        } else if (quanta.stability < 100 || quanta.charge < 50) {
             newState = QuantaState.Unstable;
        } else {
             newState = QuantaState.Stable; // Default stable state
        }

        if (oldState != newState) {
            quanta.state = newState;
            quanta.lastInteractionTime = block.timestamp; // State changes count as interaction
            emit StateChanged(tokenId, oldState, newState);
        }
    }

    // --- Ownership & Utility Functions (20-24) ---

    /**
     * @dev Transfers ownership of a Quanta. Respects transfer locks.
     * @param to The address to transfer ownership to.
     * @param tokenId The ID of the Quanta to transfer.
     */
    function transferQuanta(address to, uint256 tokenId)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
        quantaExists(tokenId)
    {
        Quanta storage quanta = idToQuanta[tokenId];
        if (quanta.transferLockUntil > block.timestamp) revert TransferLocked(tokenId, quanta.transferLockUntil);

        address from = msg.sender;

        // If bonded, unbond it first
        if (quanta.bondedToId != 0) {
            unbondQuanta(tokenId); // Unbonding is allowed even if transfer is locked
        }

        // Clear delegate on transfer
        if (quanta.delegateTuner != address(0)) {
            quanta.delegateTuner = address(0);
            emit DelegateUpdated(tokenId, quanta.delegateTuner, address(0));
        }

        // Remove from old owner's list
        uint256[] storage ownerIds = ownerToQuantaIds[from];
        for (uint i = 0; i < ownerIds.length; i++) {
            if (ownerIds[i] == tokenId) {
                // Swap with last element and pop
                ownerIds[i] = ownerIds[ownerIds.length - 1];
                ownerIds.pop();
                break;
            }
        }

        // Add to new owner's list
        ownerToQuantaIds[to].push(tokenId);
        idToOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }


    /**
     * @dev Allows the owner to delegate the permission to call `tuneQuanta` for a specific artifact.
     * @param tokenId The ID of the Quanta.
     * @param delegate The address to delegate tuning permission to (0x0 to clear).
     */
    function delegateTuningPermission(uint256 tokenId, address delegate)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
        quantaExists(tokenId)
    {
        Quanta storage quanta = idToQuanta[tokenId];
        address oldDelegate = quanta.delegateTuner;
        quanta.delegateTuner = delegate;
        emit DelegateUpdated(tokenId, oldDelegate, delegate);
    }

    /**
     * @dev Removes the tuning delegate for a specific artifact.
     * @param tokenId The ID of the Quanta.
     */
    function removeTuningDelegate(uint256 tokenId)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
        quantaExists(tokenId)
    {
        Quanta storage quanta = idToQuanta[tokenId];
        address oldDelegate = quanta.delegateTuner;
        quanta.delegateTuner = address(0);
        emit DelegateUpdated(tokenId, oldDelegate, address(0));
    }

    /**
     * @dev Sets a time lock on a Quanta, preventing transfer until the specified time.
     * Can only be set by the owner. Setting unlockTime 0 removes the lock.
     * @param tokenId The ID of the Quanta.
     * @param unlockTime The timestamp until which transfer is locked.
     */
    function setTimeLock(uint256 tokenId, uint256 unlockTime)
        external
        whenNotPaused
        isQuantaOwner(tokenId)
        quantaExists(tokenId)
    {
        Quanta storage quanta = idToQuanta[tokenId];
        // Allow setting a lock in the future, or clearing an existing lock
        require(unlockTime == 0 || unlockTime > block.timestamp, "Unlock time must be in the future or 0");
        quanta.transferLockUntil = unlockTime;
        emit TimeLockUpdated(tokenId, unlockTime);
    }

     /**
     * @dev Clears an expired time lock, allowing transfer. Callable by anyone once expired.
     * @param tokenId The ID of the Quanta.
     */
    function clearTimeLock(uint256 tokenId)
        external
        whenNotPaused
        quantaExists(tokenId)
    {
         Quanta storage quanta = idToQuanta[tokenId];
         require(quanta.transferLockUntil != 0, "No active time lock");
         require(block.timestamp >= quanta.transferLockUntil, "Time lock has not expired yet");

         quanta.transferLockUntil = 0;
         emit TimeLockUpdated(tokenId, 0);
    }


    // --- Query Functions (View/Pure) (25-32) ---

    /**
     * @dev Gets the details of a specific Quanta artifact.
     * @param tokenId The ID of the Quanta.
     * @return The Quanta struct containing its properties.
     */
    function getQuantaDetails(uint256 tokenId)
        external
        view
        quantaExists(tokenId)
        returns (Quanta memory)
    {
        return idToQuanta[tokenId];
    }

    /**
     * @dev Gets the details of a specific forging recipe.
     * @param recipeId The ID of the recipe.
     * @return The Recipe struct containing its details.
     */
    function getRecipeDetails(uint256 recipeId)
        external
        view
        recipeMustExist(recipeId)
        returns (Recipe memory)
    {
        return recipes[recipeId];
    }

     /**
     * @dev Gets the owner of a specific Quanta.
     * @param tokenId The ID of the Quanta.
     * @return The address of the owner.
     */
    function getQuantaOwner(uint256 tokenId)
        external
        view
        quantaExists(tokenId)
        returns (address)
    {
        return idToOwner[tokenId];
    }

    /**
     * @dev Gets the list of Quanta IDs owned by an address.
     * WARNING: Can be very gas-intensive for addresses with many Quanta.
     * Consider using getOwnerQuantaCount and getOwnerQuantaIdAtIndex for large collections.
     * @param owner The address to query.
     * @return An array of Quanta IDs owned by the address.
     */
    function getOwnerQuantaIds(address owner) external view returns (uint256[] memory) {
        return ownerToQuantaIds[owner];
    }

    /**
     * @dev Calculates the current fee for forging a specific recipe.
     * May incorporate recipe-specific overrides or oracle data.
     * @param recipeId The ID of the recipe.
     * @return The required native currency fee.
     */
    function calculateCurrentFee(uint256 recipeId)
        public
        view
        recipeMustExist(recipeId)
        returns (uint256)
    {
        Recipe storage recipe = recipes[recipeId];
        uint256 fee = recipe.baseFeeOverride > 0 ? recipe.baseFeeOverride : baseFee;

        // Example of dynamic fee based on oracle:
        if (oracleAddress != address(0)) {
            IOracle oracle = IOracle(oracleAddress);
            uint256 oracleValue = oracle.getValue();
            // Adjust fee based on oracle value - example: higher oracle value means higher fee
            fee = fee + (fee * oracleValue / 10000); // Add up to 100% based on oracle value (0-10000)
        }
        return fee;
    }

    /**
     * @dev Checks if a Quanta is currently bonded to another.
     * @param tokenId The ID of the Quanta.
     * @return True if bonded, false otherwise.
     */
    function isBonded(uint256 tokenId) external view quantaExists(tokenId) returns (bool) {
        return idToQuanta[tokenId].bondedToId != 0;
    }

    /**
     * @dev Gets the ID of the Quanta a specific Quanta is bonded to.
     * @param tokenId The ID of the Quanta.
     * @return The ID of the bonded Quanta, or 0 if not bonded.
     */
    function getBondedQuanta(uint256 tokenId) external view quantaExists(tokenId) returns (uint256) {
        return idToQuanta[tokenId].bondedToId;
    }

     /**
     * @dev Gets the total number of Quanta ever forged.
     * @return The total count.
     */
    function getTotalQuantaCount() external view returns (uint256) {
        return _quantaCounter;
    }

    // Fallback function to receive Ether for fees
    receive() external payable {}
    fallback() external payable {}
}
```