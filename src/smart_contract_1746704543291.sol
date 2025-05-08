Okay, let's design a smart contract that manages digital assets (tokens) with evolving properties, crafting mechanics using a consumable resource, time-based decay, and integrates randomness for outcomes. We'll call it the "QuantumFluxForge".

It will manage two types of assets:
1.  **Flux Crystals:** A fungible resource (like ERC-20).
2.  **Quantum Essences:** Non-fungible items (like ERC-721) with unique, dynamic properties like `power`, `stability`, and `entropy`.

The core concept is a forge where users spend Flux to interact with Essences, attempting to craft new ones, refine them back into Flux, or stabilize their increasing entropy.

**Outline:**

1.  **License & Pragma**
2.  **Imports (Basic interfaces/libraries for clarity, *not* full implementations)**
3.  **Error Definitions**
4.  **Events**
5.  **Structs & Enums**
    *   `EssenceProperties`: Defines dynamic traits of an Essence.
    *   `Essence`: Represents a single NFT instance with properties, owner, entropy state.
    *   `RecipeIngredient`: Defines inputs needed for crafting.
    *   `RecipeOutcome`: Defines potential outputs and success chance.
    *   `CraftingRecipe`: Combines ingredients and outcomes.
    *   `RandomnessRequest`: Tracks VRF requests for crafting.
6.  **State Variables**
    *   Owner/Admin addresses
    *   Pause state
    *   Flux state (balances, total supply, allowances) - *minimal custom implementation*
    *   Essence state (token data, owners, approvals, total supply) - *minimal custom implementation*
    *   Crafting recipes
    *   Entropy parameters (rate, stabilization cost, last decay trigger time)
    *   Randomness state (VRF parameters, pending requests)
    *   Keeper role for triggering decay
7.  **Modifiers**
    *   `onlyOwner`
    *   `whenNotPaused`
    *   `onlyKeeper`
8.  **Constructor**
    *   Sets owner, initial parameters.
9.  **Admin Functions (Restricted)**
    *   `setEntropyDecayRate`
    *   `setStabilizationCost`
    *   `addAllowedKeeper`
    *   `removeAllowedKeeper`
    *   `setCraftingRecipe`
    *   `removeCraftingRecipe`
    *   `mintFlux` (Initial supply/replenishment)
    *   `mintEssence` (Initial creation)
    *   `pause`
    *   `unpause`
    *   `withdrawFees`
    *   `setVRFParameters`
    *   `transferOwnership`
10. **Keeper Functions (Restricted)**
    *   `triggerEntropyDecay` (Processes a batch of Essences)
11. **User Functions (Core Mechanics)**
    *   `transferFlux`
    *   `approveFluxSpending`
    *   `transferEssence`
    *   `approveEssenceTransfer`
    *   `craftEssence` (Requests randomness)
    *   `refineEssence` (Burns Essence for Flux)
    *   `stabilizeEssence` (Spends Flux to reduce entropy)
12. **Oracle Callback Function**
    *   `fulfillRandomness` (Processes crafting outcome based on VRF result)
13. **View Functions (Read-only)**
    *   `getFluxBalance`
    *   `getFluxTotalSupply`
    *   `getEssenceCount`
    *   `getEssenceOwner`
    *   `getEssenceProperties` (Includes calculated current entropy)
    *   `getCraftingRecipe`
    *   `getEntropyDecayRate`
    *   `getStabilizationCost`
    *   `isKeeper`

**Function Summary:**

*   **Admin (10 functions):** Configure contract parameters (recipes, rates, costs, VRF), manage keepers, handle initial token minting, pause functionality, withdraw fees, transfer ownership.
*   **Keeper (1 function):** Periodically trigger entropy decay for a batch of Essences to simulate time-based degradation.
*   **User (7 functions):** Interact with the system - transfer tokens, manage allowances, initiate crafting (leading to randomness request), refine Essences, and stabilize Essences.
*   **Oracle Callback (1 function):** Private function called by the VRF oracle to provide randomness and finalize pending crafting operations.
*   **View (7 functions):** Get information about token balances, total supplies, Essence ownership and dynamic properties (including calculated current entropy), recipes, rates, costs, and keeper status.

This design includes 26 functions, covers advanced concepts like dynamic NFT properties, on-chain crafting with external randomness (simulated VRF), resource management, time-based mechanics (entropy decay), and role-based access control (Owner, Keeper). By implementing the core token state manually, we avoid directly duplicating a standard library while providing the necessary token functionality for the internal logic.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary interfaces from OpenZeppelin for clarity on standards,
// but we will implement the minimal required logic internally instead of inheriting
// the full contracts to avoid direct "duplication of open source" implementations.
// VRFConsumerBaseV2 is included to structure the VRF interaction.
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// Using the VRF Consumer Base V2 interface to structure callback interaction
// For a real contract, you'd inherit from VRFConsumerBaseV2 and link to Chainlink VRF coordinator
interface IVRFCoordinatorV2Plus {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

// Custom Errors for better revert reasons
error NotOwner();
error Paused();
error NotPaused();
error ZeroAddress();
error InsufficientFlux(uint256 required, uint256 available);
error EssenceNotFound(uint256 essenceId);
error NotEssenceOwner(uint256 essenceId, address caller);
error EssenceAlreadyApproved(uint256 essenceId);
error NotApprovedOrOwner(uint256 essenceId);
error RecipeNotFound(uint256 recipeId);
error InvalidRecipeInput(uint256 recipeId, string details);
error InsufficientEntropy(uint256 required, uint256 available);
error StabilizationCostTooHigh(); // Prevent excessive cost calculations
error InvalidVRFParameters();
error RandomnessRequestFailed(uint256 requestId);
error RandomnessFulfilledAlready(uint256 requestId);
error OnlyVRFCoordinator(address caller);
error InvalidBatchSize();
error NotAllowedKeeper(address caller);

contract QuantumFluxForge is IERC721Receiver {

    // --- State Variables ---

    // Basic Access Control & Pause State
    address private s_owner;
    bool private s_paused;

    // Keeper Role for Entropy Decay
    mapping(address => bool) private s_allowedKeepers;

    // Flux Crystals (Fungible Resource - Minimal Custom Implementation)
    string public constant FLUX_NAME = "Flux Crystal";
    string public constant FLUX_SYMBOL = "FLUX";
    uint8 public constant FLUX_DECIMALS = 18;
    mapping(address => uint256) private s_fluxBalances;
    mapping(address => mapping(address => uint256)) private s_fluxAllowances;
    uint256 private s_fluxTotalSupply;
    uint256 private s_collectedFeesFlux; // Fees accumulated in Flux

    // Quantum Essences (Non-Fungible Items - Minimal Custom Implementation)
    string public constant ESSENCE_NAME = "Quantum Essence";
    string public constant ESSENCE_SYMBOL = "ESSENCE";
    struct EssenceProperties {
        uint256 power;    // Affects crafting outcomes?
        uint256 stability; // Affects entropy accumulation?
        uint256 essenceType; // Defines category/visuals/base properties
    }
    struct Essence {
        address owner;
        EssenceProperties properties;
        uint256 entropy; // Accumulates over time
        uint256 lastEntropyUpdate; // Timestamp of last decay calculation
    }
    mapping(uint256 => Essence) private s_essences;
    mapping(address => uint256) private s_essenceBalances; // Track owner's token count (optional but useful)
    mapping(uint256 => address) private s_essenceApprovals;
    uint256 private s_nextEssenceId = 1; // Start token IDs from 1

    // Crafting Recipes
    struct RecipeIngredient {
        uint256 fluxCost;
        uint256 requiredEssenceType; // 0 if any type allowed
        uint256 minPower;
        uint256 minStability;
    }
     struct RecipeOutcome {
        uint256 newEssenceType; // 0 if refining (burn input)
        uint256 basePower; // Base for output properties
        uint256 baseStability;
        uint256 successChancePercent; // 0-100
        uint256 feeFlux; // Fee paid to contract on success
    }
    struct CraftingRecipe {
        RecipeIngredient input;
        RecipeOutcome[] outcomes; // Array allows multiple possible results
    }
    mapping(uint256 => CraftingRecipe) private s_craftingRecipes;
    uint256 private s_nextRecipeId = 1;

    // Entropy Mechanics
    uint256 private s_entropyDecayRatePerSecond = 1; // Entropy points gained per second
    uint256 private s_stabilizationCostPerEntropy = 100; // Flux cost per entropy point reduced
    uint256 private s_lastGlobalEntropyTriggerTime; // Timestamp of the last batch decay calculation
    uint256 private s_nextEssenceIdToProcessForDecay = 1; // Used to track position in batch processing

    // Randomness (Chainlink VRF Simulation Structure)
    address private s_vrfCoordinator;
    bytes32 private s_vrfKeyHash;
    uint64 private s_vrfSubscriptionId;
    uint32 private s_vrfCallbackGasLimit;
    uint32 private s_vrfNumWords = 1; // We only need one random number per request

    // Track pending VRF requests
    struct RandomnessRequest {
        address user;
        uint256 recipeId; // Which recipe triggered this?
        uint256 inputEssenceId; // Which essence was used as input?
    }
    mapping(uint256 => RandomnessRequest) private s_randomnessRequests; // Maps VRF request ID to custom request data
    mapping(uint256 => bool) private s_requestFulfilled; // Track if a request ID has been processed

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event KeeperAdded(address indexed account);
    event KeeperRemoved(address indexed account);

    // Flux Events (Minimal)
    event FluxTransfer(address indexed from, address indexed to, uint256 value);
    event FluxApproval(address indexed owner, address indexed spender, uint256 value);
    event FluxMinted(address indexed to, uint256 value);

    // Essence Events (Minimal)
    event EssenceTransfer(address indexed from, address indexed to, uint256 tokenId);
    event EssenceApproval(address indexed owner, address indexed approved, uint256 tokenId);
    event EssenceMinted(address indexed to, uint256 tokenId);
    event EssenceBurned(address indexed owner, uint256 tokenId); // For refining/failed crafts?

    // Core Mechanics Events
    event RecipeSet(uint256 indexed recipeId, RecipeIngredient input);
    event RecipeRemoved(uint256 indexed recipeId);
    event EntropyDecayTriggered(uint256 indexed batchStartId, uint256 indexed batchCount, uint256 timestamp);
    event EssenceEntropyUpdated(uint256 indexed tokenId, uint256 oldEntropy, uint256 newEntropy, uint256 timestamp);
    event EssenceStabilized(uint256 indexed tokenId, uint256 fluxSpent, uint256 oldEntropy, uint256 newEntropy);
    event CraftingRequestSent(uint256 indexed requestId, address indexed user, uint256 indexed recipeId, uint256 inputEssenceId);
    event CraftingFulfilled(uint256 indexed requestId, uint256 randomNumber, address indexed user, uint256 recipeId, uint256 inputEssenceId, bool success, uint256 outputEssenceId, uint256 fluxRefunded); // outputEssenceId is 0 if refined/burned
    event EssenceRefined(uint256 indexed tokenId, uint256 fluxReceived);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (s_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!s_paused) revert NotPaused();
        _;
    }

    modifier onlyKeeper() {
        if (!s_allowedKeepers[msg.sender]) revert NotAllowedKeeper(msg.sender);
        _;
    }

    // --- Constructor ---

    constructor(
        address initialOwner,
        address initialVRFCoordinator,
        bytes32 initialVRFKeyHash,
        uint64 initialVRFSubscriptionId,
        uint32 initialVRFCallbackGasLimit
    ) {
        if (initialOwner == address(0)) revert ZeroAddress();
        s_owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);

        s_vrfCoordinator = initialVRFCoordinator;
        s_vrfKeyHash = initialVRFKeyHash;
        s_vrfSubscriptionId = initialVRFSubscriptionId;
        s_vrfCallbackGasLimit = initialVRFCallbackGasLimit;

        s_lastGlobalEntropyTriggerTime = block.timestamp; // Initialize entropy trigger time
    }

    // --- Access Control & Pause ---

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address oldOwner = s_owner;
        s_owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function owner() public view returns (address) {
        return s_owner;
    }

    function pause() external onlyOwner whenNotPaused {
        s_paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        s_paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() public view returns (bool) {
        return s_paused;
    }

    function addAllowedKeeper(address keeper) external onlyOwner {
        if (keeper == address(0)) revert ZeroAddress();
        s_allowedKeepers[keeper] = true;
        emit KeeperAdded(keeper);
    }

    function removeAllowedKeeper(address keeper) external onlyOwner {
        s_allowedKeepers[keeper] = false;
        emit KeeperRemoved(keeper);
    }

    function isKeeper(address account) public view returns (bool) {
        return s_allowedKeepers[account];
    }

    // --- Admin Functions ---

    function setEntropyDecayRate(uint256 rate) external onlyOwner {
        s_entropyDecayRatePerSecond = rate;
    }

    function getEntropyDecayRate() external view returns (uint256) {
        return s_entropyDecayRatePerSecond;
    }

    function setStabilizationCost(uint256 costPerEntropy) external onlyOwner {
        s_stabilizationCostPerEntropy = costPerEntropy;
    }

    function getStabilizationCost() external view returns (uint256) {
        return s_stabilizationCostPerEntropy;
    }

    // Set a crafting recipe or update an existing one
    function setCraftingRecipe(
        uint256 recipeId, // 0 to create a new recipe
        RecipeIngredient calldata input,
        RecipeOutcome[] calldata outcomes
    ) external onlyOwner {
        uint256 currentId = recipeId == 0 ? s_nextRecipeId++ : recipeId;
        // Basic validation (more comprehensive checks needed for production)
        if (outcomes.length == 0) revert InvalidRecipeInput(recipeId, "No outcomes defined");
        // Ensure recipeId isn't 0 if not creating new
        if (recipeId != 0 && currentId != recipeId) revert InvalidRecipeInput(recipeId, "Invalid ID provided for update");

        s_craftingRecipes[currentId] = CraftingRecipe({
            input: input,
            outcomes: outcomes
        });

        emit RecipeSet(currentId, input);
    }

    function removeCraftingRecipe(uint256 recipeId) external onlyOwner {
        if (s_craftingRecipes[recipeId].outcomes.length == 0) revert RecipeNotFound(recipeId);
        delete s_craftingRecipes[recipeId];
        emit RecipeRemoved(recipeId);
    }

    function getCraftingRecipe(uint256 recipeId) external view returns (CraftingRecipe memory) {
        if (s_craftingRecipes[recipeId].outcomes.length == 0) revert RecipeNotFound(recipeId);
        return s_craftingRecipes[recipeId];
    }

    // Admin function to mint initial or replenish Flux
    function mintFlux(address account, uint256 amount) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        s_fluxBalances[account] += amount;
        s_fluxTotalSupply += amount;
        emit FluxMinted(account, amount);
        emit FluxTransfer(address(0), account, amount); // Conventionally represent minting from zero address
    }

    // Admin function to mint initial Essences
    function mintEssence(address account, EssenceProperties memory properties) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        uint256 tokenId = s_nextEssenceId++;
        s_essences[tokenId] = Essence({
            owner: account,
            properties: properties,
            entropy: 0, // Newly minted essences start with 0 entropy
            lastEntropyUpdate: block.timestamp
        });
        s_essenceBalances[account]++;
        emit EssenceMinted(account, tokenId);
        emit EssenceTransfer(address(0), account, tokenId); // Conventionally represent minting from zero address
    }

    // Admin function to withdraw collected fees (Flux)
    function withdrawFees(address recipient) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        uint256 amount = s_collectedFeesFlux;
        s_collectedFeesFlux = 0;
        s_fluxBalances[address(this)] -= amount; // Adjust contract balance
        s_fluxBalances[recipient] += amount; // Send to recipient
        emit FluxTransfer(address(this), recipient, amount);
    }

     // Admin function to set VRF parameters
    function setVRFParameters(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) external onlyOwner {
        if (vrfCoordinator == address(0)) revert ZeroAddress();
        s_vrfCoordinator = vrfCoordinator;
        s_vrfKeyHash = keyHash;
        s_vrfSubscriptionId = subscriptionId;
        s_vrfCallbackGasLimit = callbackGasLimit;
    }

    // --- Keeper Function ---

    // Trigger entropy decay for a batch of essences
    function triggerEntropyDecay(uint256 batchSize) external onlyKeeper whenNotPaused {
        if (batchSize == 0) revert InvalidBatchSize();

        uint256 processedCount = 0;
        uint256 currentId = s_nextEssenceIdToProcessForDecay;
        uint256 totalEssences = s_nextEssenceId - 1; // Total minted essences

        // Wrap around if we reach the end
        if (currentId > totalEssences) {
            currentId = 1;
        }

        uint256 endIndex = currentId + batchSize;
        if (endIndex > totalEssences + 1) { // Check against total + 1 because loop goes up to but not including endIndex
            endIndex = totalEssences + 1;
        }


        for (uint256 i = currentId; i < endIndex; i++) {
            // Only process if essence exists (it might have been refined/burned)
            if (s_essences[i].owner != address(0)) {
                uint256 currentEntropy = _calculateCurrentEntropy(i);
                uint256 oldEntropy = s_essences[i].entropy; // Store pre-calculated current entropy
                s_essences[i].entropy = currentEntropy; // Apply the decay
                s_essences[i].lastEntropyUpdate = block.timestamp; // Update timestamp

                if (currentEntropy != oldEntropy) {
                    emit EssenceEntropyUpdated(i, oldEntropy, currentEntropy, block.timestamp);
                }
                processedCount++;
            }
        }

        // Update the starting point for the next batch
        s_nextEssenceIdToProcessForDecay = endIndex > totalEssences ? 1 : endIndex;
        s_lastGlobalEntropyTriggerTime = block.timestamp; // Record trigger time

        emit EntropyDecayTriggered(currentId, processedCount, block.timestamp);
    }


    // --- User Functions (Core Mechanics) ---

    // --- Flux Token Functions (Minimal Custom Implementation) ---
    // Does NOT implement the full IERC20 interface publicly,
    // only the functions needed for interaction within this contract logic.

    function transferFlux(address recipient, uint256 amount) external whenNotPaused returns (bool) {
        address sender = msg.sender;
        if (sender == address(0) || recipient == address(0)) revert ZeroAddress();
        if (s_fluxBalances[sender] < amount) revert InsufficientFlux(amount, s_fluxBalances[sender]);

        s_fluxBalances[sender] -= amount;
        s_fluxBalances[recipient] += amount;
        emit FluxTransfer(sender, recipient, amount);
        return true;
    }

    // Approve a spender to spend Flux on behalf of msg.sender
    function approveFluxSpending(address spender, uint256 amount) external whenNotPaused returns (bool) {
        s_fluxAllowances[msg.sender][spender] = amount;
        emit FluxApproval(msg.sender, spender, amount);
        return true;
    }

    // --- Essence Token Functions (Minimal Custom Implementation) ---
    // Does NOT implement the full IERC721 interface publicly,
    // only the functions needed for interaction within this contract logic.

    function transferEssence(address to, uint256 tokenId) external whenNotPaused {
        address from = msg.sender;
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (s_essences[tokenId].owner == address(0)) revert EssenceNotFound(tokenId); // Check if token exists
        if (s_essences[tokenId].owner != from) revert NotEssenceOwner(tokenId, from);

        _transferEssence(from, to, tokenId);
    }

     function approveEssenceTransfer(address approved, uint256 tokenId) external whenNotPaused {
        address owner = s_essences[tokenId].owner;
        if (owner == address(0)) revert EssenceNotFound(tokenId);
        if (msg.sender != owner) revert NotEssenceOwner(tokenId, msg.sender); // Only owner can approve

        s_essenceApprovals[tokenId] = approved;
        emit EssenceApproval(owner, approved, tokenId);
    }

    // ERC721Receiver interface implementation (allows this contract to receive NFTs)
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Accept any ERC721 transfer. Logic for *what* to do with received NFTs
        // must be handled by other contract functions (e.g., crafting inputs).
        // This function just allows receiving.
        return this.onERC721Received.selector;
    }


    // --- Core Mechanics ---

    // Initiate a crafting attempt - requests randomness
    function craftEssence(uint256 recipeId, uint256 inputEssenceId) external whenNotPaused {
        CraftingRecipe storage recipe = s_craftingRecipes[recipeId];
        if (recipe.outcomes.length == 0) revert RecipeNotFound(recipeId);

        address user = msg.sender;
        Essence storage inputEssence = s_essences[inputEssenceId];

        // 1. Validate input Essence ownership and approval
        if (inputEssence.owner == address(0)) revert EssenceNotFound(inputEssenceId); // Check if token exists
        if (inputEssence.owner != user && s_essenceApprovals[inputEssenceId] != user) revert NotApprovedOrOwner(inputEssenceId);

        // 2. Calculate current entropy and apply it to properties (if crafting uses properties affected by entropy)
        // For simplicity, let's assume entropy affects the *chance* of success or the *output properties*.
        // We'll calculate current entropy here and pass it or use it in the outcome calculation later.
        uint256 currentEntropy = _calculateCurrentEntropy(inputEssenceId);
        // Potentially modify recipe requirements or outcomes based on currentEntropy here?
        // Example: higher entropy reduces success chance or worsens output properties.
        // For now, we'll just update the state.
        inputEssence.entropy = currentEntropy;
        inputEssence.lastEntropyUpdate = block.timestamp;
        // Emit an update event if needed here.

        // 3. Check Recipe Ingredients (Flux Cost and Input Essence Properties)
        if (s_fluxBalances[user] < recipe.input.fluxCost) revert InsufficientFlux(recipe.input.fluxCost, s_fluxBalances[user]);
        if (recipe.input.requiredEssenceType != 0 && inputEssence.properties.essenceType != recipe.input.requiredEssenceType) revert InvalidRecipeInput(recipeId, "Incorrect essence type");
        if (inputEssence.properties.power < recipe.input.minPower) revert InvalidRecipeInput(recipeId, "Insufficient essence power");
        if (inputEssence.properties.stability < recipe.input.minStability) revert InvalidRecipeInput(recipeId, "Insufficient essence stability");


        // 4. Consume Flux cost
        s_fluxBalances[user] -= recipe.input.fluxCost;
        s_collectedFeesFlux += recipe.input.fluxCost; // Collect crafting cost as fee
        emit FluxTransfer(user, address(this), recipe.input.fluxCost);

        // 5. Transfer input Essence to contract (if not already approved for transfer)
        // The user must have already approved this contract (or msg.sender) to transfer the essence.
        // We don't check allowance here, the _transferEssence requires approval.
        _transferEssence(inputEssence.owner, address(this), inputEssenceId);

        // 6. Request Randomness from VRF Coordinator
        // In a real contract, this would call the VRFCoordinator
        uint256 requestId;
        try IVRFCoordinatorV2Plus(s_vrfCoordinator).requestRandomWords(
            s_vrfKeyHash,
            s_vrfSubscriptionId,
            s_vrfCallbackGasLimit,
            s_vrfCallbackGasLimit, // Use the same limit for callback gas
            s_vrfNumWords
        ) returns (uint256 reqId) {
            requestId = reqId;
        } catch {
            // Revert if VRF request fails
            revert RandomnessRequestFailed(0); // Use 0 as request ID since we didn't get one
        }

        // 7. Store crafting context pending randomness fulfillment
        s_randomnessRequests[requestId] = RandomnessRequest({
            user: user,
            recipeId: recipeId,
            inputEssenceId: inputEssenceId
        });
        s_requestFulfilled[requestId] = false; // Mark as pending

        emit CraftingRequestSent(requestId, user, recipeId, inputEssenceId);
    }

    // Refine an Essence back into Flux (burns the Essence)
    function refineEssence(uint256 tokenId) external whenNotPaused {
        address user = msg.sender;
        Essence storage essence = s_essences[tokenId];

        // 1. Validate ownership
        if (essence.owner == address(0)) revert EssenceNotFound(tokenId);
        if (essence.owner != user) revert NotEssenceOwner(tokenId, user);

        // 2. Calculate Flux output based on Essence properties (e.g., power, stability)
        // Example: Output = (power + stability / 2) * multiplier
        // Add entropy as a negative modifier?
        uint256 currentEntropy = _calculateCurrentEntropy(tokenId);
        uint256 effectiveStability = essence.properties.stability > currentEntropy ? essence.properties.stability - currentEntropy : 0;
        uint256 fluxOutput = (essence.properties.power + effectiveStability / 2) * 10; // Example formula

        // 3. Transfer Flux to user
        s_fluxBalances[user] += fluxOutput;
        s_fluxTotalSupply += fluxOutput; // Refining increases total supply if formula creates new Flux
        emit FluxMinted(user, fluxOutput); // Can emit Minted event if it represents net new flux
        emit FluxTransfer(address(0), user, fluxOutput);

        // 4. Burn Essence (remove from state)
        _burnEssence(tokenId);

        emit EssenceRefined(tokenId, fluxOutput);
    }

    // Stabilize an Essence - spend Flux to reduce entropy
    function stabilizeEssence(uint256 tokenId, uint256 entropyToReduce) external whenNotPaused {
        address user = msg.sender;
        Essence storage essence = s_essences[tokenId];

        // 1. Validate ownership and amount
        if (essence.owner == address(0)) revert EssenceNotFound(tokenId);
        if (essence.owner != user) revert NotEssenceOwner(tokenId, user);
        if (entropyToReduce == 0) return; // Nothing to do

        // 2. Calculate current entropy and required reduction
        uint256 currentEntropy = _calculateCurrentEntropy(tokenId);
        uint256 actualEntropyToReduce = entropyToReduce > currentEntropy ? currentEntropy : entropyToReduce; // Can't reduce more entropy than exists

        // 3. Calculate stabilization cost
        uint256 cost = actualEntropyToReduce * s_stabilizationCostPerEntropy;
        // Add safeguard against excessive cost due to high entropy/rate
        if (cost / s_stabilizationCostPerEntropy != actualEntropyToReduce) revert StabilizationCostTooHigh(); // Check for overflow

        // 4. Check Flux balance
        if (s_fluxBalances[user] < cost) revert InsufficientFlux(cost, s_fluxBalances[user]);

        // 5. Consume Flux
        s_fluxBalances[user] -= cost;
        s_collectedFeesFlux += cost; // Collect stabilization cost as fee
        emit FluxTransfer(user, address(this), cost);

        // 6. Reduce entropy and update timestamp
        uint256 oldEntropy = essence.entropy;
        essence.entropy = currentEntropy - actualEntropyToReduce; // Apply reduction
        essence.lastEntropyUpdate = block.timestamp; // Update timestamp after calculation and stabilization

        emit EssenceStabilized(tokenId, cost, oldEntropy, essence.entropy);
        // Emit update event if entropy changed
        if (oldEntropy != essence.entropy) {
             emit EssenceEntropyUpdated(tokenId, oldEntropy, essence.entropy, block.timestamp);
        }
    }

    // --- Oracle Callback Function ---

    // This function is called by the VRF Coordinator contract after randomness is generated.
    // It MUST be restricted to only the configured VRF Coordinator address.
    function fulfillRandomness(uint256 requestId, uint256[] calldata randomWords) external {
        // Basic validation: Ensure caller is the VRF Coordinator
        if (msg.sender != s_vrfCoordinator) revert OnlyVRFCoordinator(msg.sender);
        // Ensure the request hasn't been fulfilled already (protects against replay attacks)
        if (s_requestFulfilled[requestId]) revert RandomnessFulfilledAlready(requestId);
        // Ensure randomness was actually provided
        if (randomWords.length == 0) revert RandomnessRequestFailed(requestId);

        // Mark request as fulfilled
        s_requestFulfilled[requestId] = true;

        // Retrieve stored crafting context
        RandomnessRequest memory req = s_randomnessRequests[requestId];
        CraftingRecipe storage recipe = s_craftingRecipes[req.recipeId];

        address user = req.user;
        uint256 inputEssenceId = req.inputEssenceId;
        uint256 randomNumber = randomWords[0]; // Use the first random number

        bool success = false;
        uint256 outputEssenceId = 0; // 0 indicates no new essence minted (e.g., failed craft, or refining outcome)
        uint256 fluxRefunded = 0; // Optional: refund some flux on failure

        // Determine crafting outcome based on randomness and recipe outcomes
        uint256 randomChance = randomNumber % 100; // Get a number between 0-99
        uint256 cumulativeChance = 0;
        RecipeOutcome memory selectedOutcome;
        bool outcomeSelected = false;

        // Iterate through potential outcomes to find the one that matches the random chance
        for (uint i = 0; i < recipe.outcomes.length; i++) {
            cumulativeChance += recipe.outcomes[i].successChancePercent;
            if (randomChance < cumulativeChance) {
                selectedOutcome = recipe.outcomes[i];
                outcomeSelected = true;
                break; // Outcome found
            }
        }

        // Handle the selected outcome
        if (outcomeSelected) {
            // Pay outcome fee (if any)
            if (selectedOutcome.feeFlux > 0) {
                 s_fluxBalances[address(this)] -= selectedOutcome.feeFlux; // Already collected in craftEssence
                 s_collectedFeesFlux += selectedOutcome.feeFlux; // Add to fees (already collected)
            }

            // Handle different outcome types
            if (selectedOutcome.newEssenceType != 0) {
                // --- Successful Craft: Mint a NEW Essence ---
                success = true;
                // Calculate new essence properties based on recipe base + random variance? + input essence properties?
                // Example: New power = basePower + (randomness part) + (influence from input power)
                // For simplicity, let's just use base properties for now.
                EssenceProperties memory newProperties = EssenceProperties({
                    power: selectedOutcome.basePower,
                    stability: selectedOutcome.baseStability,
                    essenceType: selectedOutcome.newEssenceType
                });

                outputEssenceId = s_nextEssenceId++;
                s_essences[outputEssenceId] = Essence({
                    owner: user, // Mint to the user who initiated the craft
                    properties: newProperties,
                    entropy: 0, // Newly minted essences start with 0 entropy
                    lastEntropyUpdate: block.timestamp
                });
                s_essenceBalances[user]++;
                emit EssenceMinted(user, outputEssenceId);
                emit EssenceTransfer(address(0), user, outputEssenceId); // Represent minting from zero address

                 // Burn the input Essence used for crafting
                _burnEssence(inputEssenceId);

            } else {
                 // --- Outcome is Refining/Failure/Input Burn ---
                 // If newEssenceType is 0, it implies the input Essence is consumed
                 // and the outcome might be failure, partial refund, or a specific effect without a new NFT.
                 // The input Essence was already transferred to the contract in `craftEssence`.
                 // We just need to burn it now.
                 _burnEssence(inputEssenceId);

                 // No new essence is minted, outputEssenceId remains 0.
                 // Maybe refund some Flux on 'failure' outcome?
                 // Example: if selectedOutcome represents a failure.
                 // This is just an example, specific logic depends on recipes.
                 // if (selectedOutcome.isFailureOutcome) {
                 //    fluxRefunded = recipe.input.fluxCost / 2; // Example refund
                 //    s_fluxBalances[user] += fluxRefunded;
                 //    s_collectedFeesFlux -= fluxRefunded; // Adjust fees
                 //    emit FluxTransfer(address(this), user, fluxRefunded);
                 // }
            }

        } else {
             // --- No Outcome Selected (Shouldn't happen if total chance is 100%, but good fallback) ---
             // Treat as failure. Burn input Essence. Maybe refund some flux.
             _burnEssence(inputEssenceId);
             // Optional refund logic here
             // fluxRefunded = recipe.input.fluxCost / 4; // Smaller example refund on unexpected failure
             // s_fluxBalances[user] += fluxRefunded;
             // s_collectedFeesFlux -= fluxRefunded;
             // emit FluxTransfer(address(this), user, fluxRefunded);
        }

        emit CraftingFulfilled(requestId, randomNumber, user, req.recipeId, inputEssenceId, success, outputEssenceId, fluxRefunded);

        // Clean up request state (optional, but good for gas if many requests)
        delete s_randomnessRequests[requestId];
        // s_requestFulfilled is already set to true.
    }


    // --- View Functions ---

    // Flux Balance of an account
    function getFluxBalance(address account) external view returns (uint256) {
        return s_fluxBalances[account];
    }

    // Total Flux Supply
    function getFluxTotalSupply() external view returns (uint256) {
        return s_fluxTotalSupply;
    }

    // Total number of Essences minted
    function getEssenceCount() external view returns (uint256) {
        // The last minted ID is s_nextEssenceId - 1. Total count is the number of _existing_ tokens.
        // Tracking s_nextEssenceId gives total *minted* ever.
        // To get total *existing*, you'd need a separate counter updated on mint/burn.
        // For simplicity, let's return the total minted count.
        return s_nextEssenceId - 1;
    }

    // Owner of a specific Essence
    function getEssenceOwner(uint256 tokenId) external view returns (address) {
        return s_essences[tokenId].owner;
    }

    // Get properties of an Essence, including calculated current entropy
    function getEssenceProperties(uint256 tokenId) external view returns (EssenceProperties memory properties, uint256 currentEntropy) {
        Essence storage essence = s_essences[tokenId];
        if (essence.owner == address(0)) revert EssenceNotFound(tokenId); // Check if token exists

        properties = essence.properties;
        currentEntropy = _calculateCurrentEntropy(tokenId);

        return (properties, currentEntropy);
    }

     // --- Internal Helper Functions ---

    // Calculate current entropy for a specific Essence based on time elapsed
    function _calculateCurrentEntropy(uint256 tokenId) internal view returns (uint256) {
        Essence storage essence = s_essences[tokenId];
        if (essence.owner == address(0)) return 0; // Should not happen if called internally after existence check

        uint256 timeElapsed = block.timestamp - essence.lastEntropyUpdate;
        uint256 entropyGained = timeElapsed * s_entropyDecayRatePerSecond;

        // Check for potential overflow before adding
        uint256 current = essence.entropy;
        unchecked {
            if (current + entropyGained < current) { // Check if adding makes it smaller (overflow)
                 return type(uint256).max; // Cap at max uint256 on overflow
            }
        }

        return current + entropyGained;
    }


    // Internal transfer function for Essences
    function _transferEssence(address from, address to, uint256 tokenId) internal {
        if (s_essences[tokenId].owner == address(0)) revert EssenceNotFound(tokenId); // Should already be checked
        if (s_essences[tokenId].owner != from) revert NotEssenceOwner(tokenId, from); // Should already be checked

        // Check approval if transferring from someone other than owner
        if (msg.sender != from) { // If caller is not the owner
            address approved = s_essenceApprovals[tokenId];
            if (approved != msg.sender && approved != address(0)) {
                 revert NotApprovedOrOwner(tokenId); // Neither owner nor approved
            }
             // Clear approval after transfer
             s_essenceApprovals[tokenId] = address(0);
        }


        s_essenceBalances[from]--;
        s_essenceBalances[to]++;
        s_essences[tokenId].owner = to; // Update owner in the struct

        emit EssenceTransfer(from, to, tokenId);
    }

     // Internal burn function for Essences
    function _burnEssence(uint256 tokenId) internal {
        address owner = s_essences[tokenId].owner;
        if (owner == address(0)) revert EssenceNotFound(tokenId); // Should already be checked

        s_essenceBalances[owner]--;

        // Clear data associated with the token
        delete s_essences[tokenId];
        delete s_essenceApprovals[tokenId]; // Clear any pending approval

        emit EssenceBurned(owner, tokenId);
    }

     // Required for ERC721 compliance if implementing fully (though not fully implementing here)
     // But useful if the contract itself needs to know its balance or approve others.
     function balanceOf(address owner) public view returns (uint256) {
         if (owner == address(0)) revert ZeroAddress();
         return s_essenceBalances[owner];
     }

    // Required for ERC721 compliance (partial implementation)
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = s_essences[tokenId].owner;
        if (owner == address(0)) revert EssenceNotFound(tokenId);
        return owner;
    }

     // Required for ERC721 compliance (partial implementation)
     function getApproved(uint256 tokenId) public view returns (address) {
         if (s_essences[tokenId].owner == address(0)) revert EssenceNotFound(tokenId);
         return s_essenceApprovals[tokenId];
     }

    // Required for ERC721 compliance (partial implementation) - assuming no `setApprovalForAll` in this minimal version
    // function isApprovedForAll(address owner, address operator) public view returns (bool) {
    //     // Not implemented in this minimal version
    //     return false;
    // }

    // Required for ERC721 compliance (partial implementation) - safeTransferFrom overloads
    // function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
    //      // Implement safety checks and call _transferEssence
    //      _transferEssence(from, to, tokenId); // Simplified
    // }
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public whenNotPaused {
    //      // Implement safety checks, call _transferEssence, and call onERC721Received
    //      _transferEssence(from, to, tokenId); // Simplified
    //      require(IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) == IERC721Receiver.onERC721Received.selector, "ERC721: transfer to non ERC721Receiver implementer"); // Simplified
    // }

    // function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
    //      // Implement checks and call _transferEssence
    //      _transferEssence(from, to, tokenId); // Simplified
    // }


    // --- Additional View Functions ---

    function getNextEssenceId() external view returns (uint256) {
        return s_nextEssenceId;
    }

    function getNextRecipeId() external view returns (uint256) {
        return s_nextRecipeId;
    }

    function getNextEssenceIdToProcessForDecay() external view returns (uint256) {
        return s_nextEssenceIdToProcessForDecay;
    }

    function getLastGlobalEntropyTriggerTime() external view returns (uint256) {
        return s_lastGlobalEntropyTriggerTime;
    }

     function getCollectedFeesFlux() external view returns (uint256) {
         return s_collectedFeesFlux;
     }

    // Expose VRF parameters
    function getVRFParameters() external view returns (address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, uint32 numWords) {
        return (s_vrfCoordinator, s_vrfKeyHash, s_vrfSubscriptionId, s_vrfCallbackGasLimit, s_vrfNumWords);
    }

}
```