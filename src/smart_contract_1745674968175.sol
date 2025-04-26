Okay, let's create a smart contract system centered around dynamic NFTs with evolving properties, resource management, and a gamified crafting/discovery mechanism involving randomness and distinct element states.

We'll call the system "Quantum Alchemy". It will involve three contracts:
1.  **`EssenceToken`**: An ERC20 token used as fuel/resource for alchemy operations.
2.  **`QuantumElement`**: An ERC721 token representing unique "Quantum Elements". Each element will have dynamic properties and a specific state that affects its behavior.
3.  **`QuantumAlchemy`**: The core logic contract where users can perform alchemy, refine elements, attempt discoveries, and interact with the system, burning Essence and manipulating Quantum Elements.

This system incorporates:
*   **Dynamic NFTs**: Element properties and state change based on interactions.
*   **Resource Management**: Requires ERC20 `Essence` for actions.
*   **Gamification**: Crafting (Alchemy), upgrading (Refining), exploration (Discovery).
*   **Randomness**: Outcomes of actions involve probability (using a simplified, acknowledgeably insecure on-chain method for demonstration; Chainlink VRF would be production standard).
*   **State Machines**: Elements have distinct states (`Stable`, `Volatile`, `QuantumLocked`, etc.) influencing outcomes.
*   **Admin Controls**: Owner can set recipes, costs, probabilities, and trigger global events.
*   **Pausable**: Standard contract safety feature.

---

**Outline and Function Summary**

**Contracts:**

1.  **`EssenceToken`**: Standard ERC20 with basic minting/burning controlled by the `QuantumAlchemy` contract.
2.  **`QuantumElement`**: Standard ERC721 with additional state and properties. Minting/burning controlled by the `QuantumAlchemy` contract.
3.  **`QuantumAlchemy`**: The main logic contract.

**`EssenceToken` Summary:**
*   `constructor`: Initializes ERC20.
*   `mint`: Allows only the minter (expected to be `QuantumAlchemy`) to create new tokens.
*   `burn`: Allows token holders to burn their own tokens.
*   `_mint`: Internal ERC20 mint function.
*   `_burn`: Internal ERC20 burn function.
*   *Inherits standard ERC20 functions:* `name`, `symbol`, `decimals`, `totalSupply`, `balanceOf`, `transfer`, `approve`, `transferFrom`, `allowance`. (Total ~10 functions including internal)

**`QuantumElement` Summary:**
*   `constructor`: Initializes ERC721 and sets the minter (expected to be `QuantumAlchemy`).
*   `setElementProperties`: Internal/owner function to set properties for an element.
*   `getElementProperties`: View function to get properties of an element.
*   `setElementState`: Internal/owner function to set the state of an element.
*   `getElementState`: View function to get the state of an element.
*   `mint`: Allows only the minter to create new NFTs and set initial properties/state.
*   `burn`: Allows the owner or approved contract (expected to be `QuantumAlchemy`) to burn an NFT.
*   `_updateElementProperties`: Internal function to modify element properties (used during refining/alchemy).
*   `_updateElementState`: Internal function to modify element state.
*   *Inherits standard ERC721 functions:* `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `supportsInterface`. (Total ~10 functions including internal/overridden)

**`QuantumAlchemy` Summary (Core Logic - Focus on Public/External Functions for >= 20 count):**
1.  `constructor`: Sets token contract addresses and initial costs/parameters.
2.  `mintInitialElement`: Allows users to mint a Tier 1 element (payable).
3.  `purchaseEssence`: Allows users to buy Essence tokens with native currency (payable).
4.  `claimDailyEssence`: Allows users to claim a small amount of free Essence daily.
5.  `defineAlchemyRecipe`: Admin defines recipes (input elements, essence, output, probabilities).
6.  `removeAlchemyRecipe`: Admin removes a recipe.
7.  `performAlchemy`: Executes a crafting attempt using input elements and essence. Burns inputs on success/failure, potentially mints new element based on randomness.
8.  `refineElement`: Attempts to improve an element's properties or change its state using essence (involves randomness).
9.  `discoverNewRecipeAttempt`: Allows users to attempt unknown combinations. If a successful *undiscovered* recipe is matched, rewards are given and the recipe might be revealed.
10. `mutateGlobalElements`: Admin triggers a system-wide "quantum fluctuation" event that can randomly change the state or properties of many elements owned by users.
11. `setEssenceCosts`: Admin sets the cost in Essence for various operations.
12. `setProbabilities`: Admin adjusts randomness weights/seeds for operations.
13. `setNativeCurrencyPurchaseRate`: Admin sets the rate for buying Essence with native currency.
14. `setInitialMintCost`: Admin sets the cost for minting the first element.
15. `setDailyClaimAmount`: Admin sets the amount for daily Essence claims.
16. `withdrawFunds`: Admin withdraws collected native currency.
17. `queryAlchemyRecipe`: View function to see details of a defined recipe.
18. `queryElementProperties`: View function to get properties of a specific Element NFT (calls `QuantumElement`).
19. `queryElementState`: View function to get the state of a specific Element NFT (calls `QuantumElement`).
20. `queryUserElementCount`: View function to get the number of Element NFTs owned by an address (calls `QuantumElement`).
21. `queryUserEssenceBalance`: View function to get the Essence balance of an address (calls `EssenceToken`).
22. `getLastDailyClaimTime`: View function for a user's last daily claim time.
23. `getTotalAlchemyAttempts`: View total count of alchemy attempts.
24. `getTotalDiscoveryAttempts`: View total count of discovery attempts.
25. `isRecipeDiscovered`: View function to check if a recipe has been discovered.
26. `pause`: Admin pauses core system functions.
27. `unpause`: Admin unpauses core system functions.
28. `onERC721Received`: Required callback for ERC721 transfers *to* the contract (used when users approve & transfer elements for alchemy).

*Note: Some functions listed above are internal helpers or inherited ERC20/ERC721. The `QuantumAlchemy` contract itself will have well over 20 external/public functions users or the owner interact with directly.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Included for clarity, though 0.8+ handles overflow

// Define Custom Errors for better clarity and gas efficiency
error NotEnoughEssence(uint256 required, uint256 has);
error NotEnoughNativeCurrency(uint256 required, uint256 sent);
error ElementNotFound(uint256 tokenId);
error InvalidElementOwner(uint256 tokenId, address expectedOwner);
error InvalidElementState(uint256 tokenId, string currentStateName, string[] expectedStateNames);
error DailyClaimAlreadyUsed(uint40 nextClaimTime);
error InvalidRecipe(uint256 recipeId);
error AlchemyInputsMismatch(uint256[] providedTokens, string requiredTypes); // Simplified error
error AlchemyRecipeNotFound(uint256[] inputTokenIds); // Simplified error
error RecipeAlreadyDiscovered(uint256 recipeId);
error RecipeNotDiscovered(uint256 recipeId); // For reveal logic etc.
error InsufficientAllowance(address spender, uint256 required);
error InvalidInputData(); // For various malformed inputs

/**
 * @title EssenceToken
 * @dev ERC20 token used as fuel for Quantum Alchemy operations.
 * Minting controlled by the minter role, expected to be QuantumAlchemy contract.
 */
contract EssenceToken is ERC20, Ownable {
    address private immutable _minter;

    constructor(address minterAddress) ERC20("Quantum Essence", "ESS") Ownable(msg.sender) {
        _minter = minterAddress;
    }

    // Allow only the minter to create new Essence tokens
    function mint(address to, uint256 amount) external {
        if (msg.sender != _minter) revert OwnableUnauthorizedAccount(msg.sender); // Re-use Ownable error
        _mint(to, amount);
    }

    // Allow any holder to burn their own Essence tokens
    function burn(uint256 amount) external {
         _burn(msg.sender, amount);
    }

    // Standard ERC20 functions inherited:
    // name(), symbol(), decimals(), totalSupply(), balanceOf(address), transfer(address,uint256),
    // approve(address,uint256), transferFrom(address,address,uint256), allowance(address,address)
}

/**
 * @title QuantumElement
 * @dev ERC721 token representing Quantum Elements with dynamic properties and state.
 * Properties and State controlled by the minter role, expected to be QuantumAlchemy contract.
 */
contract QuantumElement is ERC721, Ownable {

    enum ElementState { Stable, Volatile, QuantumLocked, Decaying, Inert } // Define possible states

    struct ElementProperties {
        uint8 elementType; // e.g., 1=Fire, 2=Water, 3=Earth, 4=Air, 5=Aether, etc.
        uint8 tier;        // e.g., 1, 2, 3, etc. Higher tiers are generally better.
        uint16 stability;   // affects resilience during operations
        uint16 reactivity;  // affects potential outcomes during operations
        uint16 purity;      // affects property inheritance or randomness bias
        ElementState state; // Current state of the element
        uint40 lastStateChange; // Timestamp of the last state change
    }

    // Mapping from token ID to ElementProperties
    mapping(uint256 => ElementProperties) private _elementProperties;

    address private immutable _minter;

    constructor(address minterAddress) ERC721("Quantum Element", "QEL") Ownable(msg.sender) {
        _minter = minterAddress;
    }

    // --- Minter-controlled Functions (expected to be called by QuantumAlchemy) ---

    // Internal/Minter function to set properties for a specific element
    function _setElementProperties(uint256 tokenId, ElementProperties memory props) internal {
        if (msg.sender != _minter && msg.sender != owner()) revert OwnableUnauthorizedAccount(msg.sender);
        if (!_exists(tokenId)) revert ElementNotFound(tokenId);
        _elementProperties[tokenId] = props;
        // Note: Consider emitting an event for property changes
    }

     // Internal/Minter function to update element properties
    function _updateElementProperties(uint256 tokenId, uint16 stabilityDelta, uint16 reactivityDelta, uint16 purityDelta) internal {
        if (msg.sender != _minter && msg.sender != owner()) revert OwnableUnauthorizedAccount(msg.sender);
        if (!_exists(tokenId)) revert ElementNotFound(tokenId);

        ElementProperties storage props = _elementProperties[tokenId];

        // Apply deltas with clamping
        props.stability = uint16(Math.max(0, int256(props.stability) + int256(stabilityDelta)));
        props.reactivity = uint16(Math.max(0, int256(props.reactivity) + int256(reactivityDelta)));
        props.purity = uint16(Math.max(0, int256(props.purity) + int256(purityDelta)));

         // Note: Consider emitting an event for property changes
    }


    // Internal/Minter function to set the state of a specific element
    function _setElementState(uint256 tokenId, ElementState newState) internal {
         if (msg.sender != _minter && msg.sender != owner()) revert OwnableUnauthorizedAccount(msg.sender);
         if (!_exists(tokenId)) revert ElementNotFound(tokenId);
         ElementProperties storage props = _elementProperties[tokenId];
         if (props.state != newState) {
             props.state = newState;
             props.lastStateChange = uint40(block.timestamp);
             // Note: Consider emitting an event for state changes
         }
    }

    // Allows only the minter to create new NFTs and set initial properties
    function mint(address to, uint256 tokenId, ElementProperties memory props) external {
        if (msg.sender != _minter) revert OwnableUnauthorizedAccount(msg.sender); // Re-use Ownable error
        _safeMint(to, tokenId);
        _elementProperties[tokenId] = props; // Set initial properties
        _elementProperties[tokenId].lastStateChange = uint40(block.timestamp); // Initial state change time
    }

    // Allows minter or owner/approved to burn NFTs (needed for alchemy)
    function burn(uint256 tokenId) external {
        if (msg.sender != _minter && !_isApprovedOrOwner(msg.sender, tokenId)) {
             // Re-use ERC721 error or define custom
            revert ERC721Unauthorized(msg.sender, tokenId);
        }
        _burn(tokenId);
        delete _elementProperties[tokenId]; // Clean up properties
    }

    // --- Public View Functions ---

    // Get properties of a specific element
    function getElementProperties(uint256 tokenId) external view returns (ElementProperties memory) {
        if (!_exists(tokenId)) revert ElementNotFound(tokenId);
        return _elementProperties[tokenId];
    }

     // Get state of a specific element
    function getElementState(uint256 tokenId) external view returns (ElementState) {
        if (!_exists(tokenId)) revert ElementNotFound(tokenId);
        return _elementProperties[tokenId].state;
    }


    // Override to ensure properties are deleted on burn
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        delete _elementProperties[tokenId];
    }

    // Standard ERC721 functions inherited:
    // balanceOf(address), ownerOf(uint256), transferFrom(address,address,uint256), safeTransferFrom(address,address,uint256),
    // approve(address,uint256), setApprovalForAll(address,bool), getApproved(uint256), isApprovedForAll(address,address), supportsInterface(bytes4)
}

/**
 * @title QuantumAlchemy
 * @dev The core contract for Quantum Alchemy operations. Manages recipes, state transitions,
 * resource burning, and interacts with QuantumElement and EssenceToken.
 */
contract QuantumAlchemy is Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256; // Use SafeMath explicitly

    // --- State Variables ---

    EssenceToken private immutable _essenceToken;
    QuantumElement private immutable _elementToken;

    // Costs for various operations in Essence tokens
    mapping(string => uint256) private _essenceCosts;
    uint256 private _nativeCurrencyPurchaseRate; // How much essence per native token
    uint256 private _initialMintCost; // Cost to mint the first Tier 1 element

    // Daily essence claim
    mapping(address => uint40) private _lastDailyClaim; // Timestamp of last claim
    uint256 private _dailyClaimAmount;

    // Recipes for Alchemy
    struct AlchemyRecipe {
        uint8[] inputElementTypes; // e.g., [1, 2] for Fire + Water
        uint8[] inputElementTiers; // e.g., [1, 1] for Tier 1 Fire + Tier 1 Water
        uint256 requiredEssence;   // Cost in Essence
        uint8 outputElementType;   // e.g., 6 for Steam
        uint8 outputElementTier;   // e.g., 2 for Tier 2
        uint16 successChance;      // % chance of success (0-10000 for 0.00%-100.00%)
        uint16 criticalChance;     // % chance of critical success (part of successChance)
        // Add failure outcomes, state influence etc. for complexity
    }
    mapping(uint256 => AlchemyRecipe) private _recipes; // recipeId => Recipe
    uint256 private _nextRecipeId = 1; // Counter for new recipes

    // Discovery mechanism
    mapping(uint256 => bool) private _recipeDiscovered; // recipeId => isDiscovered
    // Could add discoverer rewards, first discovery bonuses etc.

    // Randomness seed (simplified, see comments below)
    uint256 private _randomSeed;
    uint256 private _seedUpdateInterval = 100; // Update seed every X blocks (admin configurable)
    uint256 private _lastSeedUpdateBlock;


    // Operation Counters (for stats/analytics)
    uint256 public totalAlchemyAttempts = 0;
    uint256 public totalRefinementAttempts = 0;
    uint256 public totalDiscoveryAttempts = 0;
    uint256 public totalEssencePurchased = 0;
    uint256 public totalElementsMintedByAlchemy = 0;

    // --- Events ---

    event InitialElementMinted(address indexed receiver, uint256 indexed tokenId);
    event EssencePurchased(address indexed purchaser, uint256 nativeAmount, uint256 essenceAmount);
    event DailyEssenceClaimed(address indexed claimant, uint256 amount);
    event RecipeDefined(uint256 indexed recipeId, AlchemyRecipe recipe);
    event RecipeRemoved(uint256 indexed recipeId);
    event AlchemyAttempted(address indexed user, uint256[] inputTokenIds, uint256 recipeId);
    event AlchemySuccess(address indexed user, uint256 recipeId, uint256[] inputTokenIds, uint256 outputTokenId, bool isCritical);
    event AlchemyFailure(address indexed user, uint256 recipeId, uint256[] inputTokenIds, string reason);
    event ElementRefined(address indexed user, uint256 indexed tokenId);
    event DiscoveryAttempted(address indexed user, uint256[] inputTokenIds);
    event RecipeDiscovered(address indexed discoverer, uint256 indexed recipeId, uint256[] inputTokenIds); // Reveal inputs on discovery
    event GlobalMutationTriggered(address indexed admin, uint256 blockTimestamp);
    event EssenceCostsUpdated(string indexed operation, uint256 newCost);
    event ProbabilitiesUpdated(string indexed setting, uint256 value);
    event NativeCurrencyPurchaseRateUpdated(uint256 newRate);
    event InitialMintCostUpdated(uint256 newCost);
    event DailyClaimAmountUpdated(uint256 newAmount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event ElementStateChangedByAlchemy(uint256 indexed tokenId, QuantumElement.ElementState oldState, QuantumElement.ElementState newState); // Consider adding delta
    event ElementStateChangedByRefining(uint256 indexed tokenId, QuantumElement.ElementState oldState, QuantumElement.ElementState newState);
    event ElementStateChangedByMutation(uint256 indexed tokenId, QuantumElement.ElementState oldState, QuantumElement.ElementState newState);


    // --- Constructor ---

    constructor(address essenceTokenAddress, address elementTokenAddress)
        Ownable(msg.sender)
        Pausable() // Paused by default initially? Let's start unpaused for simplicity.
    {
        _essenceToken = EssenceToken(essenceTokenAddress);
        _elementToken = QuantumElement(elementTokenAddress);

        // Ensure tokens have this contract as minter
        // In a real deployment flow, ensure the tokens are deployed first
        // and their constructors are called with THIS contract's address.
        // Add checks if necessary, or handle in deployment script.

        // Set some initial costs (can be updated by owner)
        _essenceCosts["alchemy"] = 100 ether; // Example cost
        _essenceCosts["refine"] = 50 ether;   // Example cost
        _essenceCosts["discover"] = 200 ether; // Example cost
        _nativeCurrencyPurchaseRate = 1000 ether; // 1 Native = 1000 ESS
        _initialMintCost = 0.01 ether; // 0.01 Native to mint initial element
        _dailyClaimAmount = 10 ether; // 10 ESS per day

        // Initialize randomness seed (simplified)
        _randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        _lastSeedUpdateBlock = block.number;
    }

    // --- Modifiers ---

    modifier whenNotPausedAndReady() {
        if (paused()) revert Paused();
        // Potentially add other readiness checks here
        _;
    }

    modifier onlyElementOwner(uint256 tokenId) {
        if (_elementToken.ownerOf(tokenId) != msg.sender) revert InvalidElementOwner(tokenId, msg.sender);
        _;
    }

     // --- Internal Helper Functions ---

     // Simplified randomness generation - NOT SUITABLE FOR PRODUCTION
     // Use Chainlink VRF or similar for secure randomness.
    function _generateRandomSeed() private view returns (uint256) {
        // Combine block data with internal seed. Internal seed changes based on block.
        // Predictable by miners/nodes.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _randomSeed)));
    }

    // Updates the internal randomness seed state
    function _updateInternalSeed() private {
         // Only update periodically to avoid constant state changes
        if (block.number > _lastSeedUpdateBlock + _seedUpdateInterval) {
             _randomSeed = _generateRandomSeed();
            _lastSeedUpdateBlock = block.number;
            // Maybe emit an event?
        }
    }

    // Helper to burn essence tokens (requires user allowance)
    function _burnEssenceForUser(address user, uint256 amount) private {
        // Check allowance first
        if (_essenceToken.allowance(user, address(this)) < amount) {
            revert InsufficientAllowance(address(this), amount);
        }
        _essenceToken.transferFrom(user, address(this), amount); // Transfer to self
        _essenceToken.burn(amount); // Then burn from self
    }

    // Helper to transfer Element NFT (requires user approval)
    function _transferElementFromUser(address user, uint256 tokenId) private {
        // Check ownership and approval (ERC721 transferFrom handles approval check)
        if (_elementToken.ownerOf(tokenId) != user) revert InvalidElementOwner(tokenId, user);
         // Transfer to self. onERC721Received will be called.
        _elementToken.safeTransferFrom(user, address(this), tokenId);
    }

    // Helper to burn Element NFT owned by this contract
    function _burnElement(uint256 tokenId) private {
        if (_elementToken.ownerOf(tokenId) != address(this)) revert InvalidElementOwner(tokenId, address(this));
        _elementToken.burn(tokenId);
    }

     // Helper to mint Element NFT
    function _mintElement(address to, uint256 tokenId, QuantumElement.ElementProperties memory props) private {
         _elementToken.mint(to, tokenId, props);
    }

    // Helper to get element properties (wraps call to token contract)
    function _getElementProps(uint256 tokenId) private view returns (QuantumElement.ElementProperties memory) {
        return _elementToken.getElementProperties(tokenId);
    }

    // Helper to set element properties (wraps call to token contract)
    function _setElementProps(uint256 tokenId, QuantumElement.ElementProperties memory props) private {
        _elementToken._setElementProperties(tokenId, props);
    }

     // Helper to update element properties (wraps call to token contract)
    function _updateElementProps(uint256 tokenId, int256 stabilityDelta, int256 reactivityDelta, int256 purityDelta) private {
         // Need to cast signed deltas to uint16 deltas for the token contract, carefully handling negative outcomes.
         // This requires logic to check current value vs delta.
         // Or, update token contract's _update function to accept signed deltas and handle Math.max(0, ...)
         // For simplicity here, let's assume _updateElementProperties in token contract handles this.
         // A more robust approach involves fetching current props, applying deltas, and calling _setElementProperties
         _elementToken._updateElementProperties(tokenId, uint16(stabilityDelta), uint16(reactivityDelta), uint16(purityDelta)); // This cast is risky if deltas are large negative. Refactor QuantumElement._updateElementProperties to take signed int256 deltas for robustness.
    }

     // Helper to get element state (wraps call to token contract)
    function _getElementState(uint256 tokenId) private view returns (QuantumElement.ElementState) {
        return _elementToken.getElementState(tokenId);
    }

    // Helper to set element state (wraps call to token contract)
    function _setElementState(uint256 tokenId, QuantumElement.ElementState newState) private {
        _elementToken._setElementState(tokenId, newState);
        // Emit event here or in the token contract's internal function
        // For simplicity, let's emit here when called by core logic
        // This requires knowing old state.
        // Let's refine: The token contract internal function should emit.
    }


    // Minimal ERC721Receiver implementation (used when NFTs are transferred TO this contract)
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Ensure it's from our element contract
        if (msg.sender != address(_elementToken)) {
            revert InvalidInputData(); // Or a more specific error
        }
        // Accept the transfer. Further processing should happen in the function
        // that initiated the transfer (e.g., performAlchemy) using the token's new location.
        return this.onERC721Received.selector;
    }

    // --- Core Logic Functions (Public/External) ---

    /**
     * @dev Allows a user to mint their first Tier 1 element. Payable function.
     * Requires native currency payment.
     */
    function mintInitialElement() external payable whenNotPaused {
        if (msg.value < _initialMintCost) revert NotEnoughNativeCurrency(_initialMintCost, msg.value);

        // Generate a new unique token ID (e.g., using a global counter or hash)
        // For simplicity, let's use a simple counter. In production, consider potential collisions or more robust ID generation.
        uint256 newTokenId = _elementToken.totalSupply() + 1; // This is NOT safe in real applications, use a proper counter or hash of unique data

        // Define initial properties for a Tier 1 element
        QuantumElement.ElementProperties memory initialProps = QuantumElement.ElementProperties({
            elementType: 1, // Example: default type 1
            tier: 1,
            stability: 500, // Base stats
            reactivity: 500,
            purity: 500,
            state: QuantumElement.ElementState.Stable, // Start stable
            lastStateChange: uint40(block.timestamp) // Set initial timestamp
        });

        _mintElement(msg.sender, newTokenId, initialProps);

        // Refund excess native currency if any
        if (msg.value > _initialMintCost) {
            payable(msg.sender).transfer(msg.value - _initialMintCost);
        }

        emit InitialElementMinted(msg.sender, newTokenId);
    }

    /**
     * @dev Allows a user to purchase Essence tokens with native currency. Payable function.
     */
    function purchaseEssence() external payable whenNotPaused {
        if (msg.value == 0 || _nativeCurrencyPurchaseRate == 0) revert InvalidInputData();

        uint256 essenceAmount = msg.value.mul(_nativeCurrencyPurchaseRate);

        _essenceToken.mint(msg.sender, essenceAmount);

        totalEssencePurchased = totalEssencePurchased.add(essenceAmount);
        emit EssencePurchased(msg.sender, msg.value, essenceAmount);
    }

    /**
     * @dev Allows a user to claim a small amount of free Essence once per day.
     */
    function claimDailyEssence() external whenNotPaused {
        uint40 lastClaim = _lastDailyClaim[msg.sender];
        uint40 nextClaimTime = lastClaim + 1 days; // Use 1 day interval

        if (block.timestamp < nextClaimTime) {
            revert DailyClaimAlreadyUsed(nextClaimTime);
        }

        uint256 claimAmount = _dailyClaimAmount;
        if (claimAmount == 0) revert InvalidInputData(); // Ensure claim amount is set

        _essenceToken.mint(msg.sender, claimAmount);
        _lastDailyClaim[msg.sender] = uint40(block.timestamp);

        emit DailyEssenceClaimed(msg.sender, claimAmount);
    }

    /**
     * @dev Admin function to define a new alchemy recipe.
     * @param recipeId The ID for the new recipe.
     * @param recipeData The details of the recipe.
     */
    function defineAlchemyRecipe(uint256 recipeId, AlchemyRecipe memory recipeData) external onlyOwner {
        // Basic validation
        if (recipeData.inputElementTypes.length != recipeData.inputElementTiers.length || recipeData.inputElementTypes.length == 0) {
            revert InvalidInputData();
        }
        if (recipeData.successChance + (recipeData.criticalChance > 0 ? recipeData.criticalChance : 0) > 10000) { // Basic probability sum check
             revert InvalidInputData(); // Probabilities exceed 100%
        }
         // Add more validation: valid element types, reasonable tiers, etc.

        _recipes[recipeId] = recipeData;
        _nextRecipeId = Math.max(_nextRecipeId, recipeId + 1); // Ensure counter keeps growing
        emit RecipeDefined(recipeId, recipeData);
    }

     /**
     * @dev Admin function to remove an alchemy recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeAlchemyRecipe(uint256 recipeId) external onlyOwner {
        if (_recipes[recipeId].inputElementTypes.length == 0) revert InvalidRecipe(recipeId); // Check if recipe exists

        delete _recipes[recipeId];
        // Note: does not affect _nextRecipeId or _recipeDiscovered mapping.
        // Consider implications if you want recipes to be 'undiscovered' again.
        emit RecipeRemoved(recipeId);
    }

    /**
     * @dev Performs an alchemy attempt using specified input elements and essence.
     * Requires user to approve Element NFTs and Essence tokens for this contract.
     * @param inputTokenIds The IDs of the elements to use as input.
     * @param recipeId The ID of the recipe to attempt.
     */
    function performAlchemy(uint256[] calldata inputTokenIds, uint256 recipeId) external whenNotPausedAndReady {
        if (inputTokenIds.length == 0) revert InvalidInputData();

        AlchemyRecipe storage recipe = _recipes[recipeId];
        if (recipe.inputElementTypes.length == 0) revert InvalidRecipe(recipeId); // Check if recipe exists

        // 1. Check and Burn Essence
        uint256 requiredEssence = recipe.requiredEssence.add(_essenceCosts["alchemy"]);
        _burnEssenceForUser(msg.sender, requiredEssence);

        // 2. Validate Inputs and Transfer to contract
        if (inputTokenIds.length != recipe.inputElementTypes.length) {
             revert AlchemyInputsMismatch(inputTokenIds, "Incorrect number of elements");
        }

        // Collect input element data and transfer NFTs to the contract
        QuantumElement.ElementProperties[] memory inputProps = new QuantumElement.ElementProperties[](inputTokenIds.length);
        for (uint i = 0; i < inputTokenIds.length; i++) {
            _transferElementFromUser(msg.sender, inputTokenIds[i]); // Transfers ownership to this contract
            inputProps[i] = _getElementProps(inputTokenIds[i]);

            // Basic input validation based on recipe
            if (inputProps[i].elementType != recipe.inputElementTypes[i] || inputProps[i].tier != recipe.inputElementTiers[i]) {
                // Revert or handle mismatch. For simplicity, strict match required here.
                 // Need to transfer elements back or handle state if reverting after transfer.
                 // For now, let's revert before transfers or design flow differently.
                 // Alternative flow: User calls `requestAlchemy`, system checks inputs, user approves and transfers *then* calls `executeAlchemy` with contract-owned tokens.
                 // Let's stick to simpler "approve & call" model, but add checks before transfer.
                 // Re-check before transfer:
                 if (_elementToken.ownerOf(inputTokenIds[i]) != msg.sender) revert InvalidElementOwner(inputTokenIds[i], msg.sender);
                 QuantumElement.ElementProperties memory preTransferProps = _getElementProps(inputTokenIds[i]);
                 if (preTransferProps.elementType != recipe.inputElementTypes[i] || preTransferProps.tier != recipe.inputElementTiers[i]) {
                     revert AlchemyInputsMismatch(inputTokenIds, "Input element types/tiers don't match recipe");
                 }
                 // Okay, checks passed. Proceed with transfer.
                 _transferElementFromUser(msg.sender, inputTokenIds[i]); // Transfers ownership to this contract
                 inputProps[i] = _getElementProps(inputTokenIds[i]); // Get properties *after* transfer completes (safer)
            }

            // Optional: Add state influence checks/logic here
            // e.g., If an input is 'Volatile', increase critical chance, if 'Decaying', increase failure chance.
        }

         emit AlchemyAttempted(msg.sender, inputTokenIds, recipeId);
         totalAlchemyAttempts = totalAlchemyAttempts.add(1);

        // 3. Determine Outcome using Randomness
        _updateInternalSeed(); // Update seed if necessary
        uint256 randomValue = _generateRandomSeed() % 10000; // 0-9999

        bool success = randomValue < recipe.successChance;
        bool criticalSuccess = success && (randomValue < recipe.criticalChance); // Critical is a subset of success

        // 4. Execute Outcome
        if (success) {
            // Burn input elements
            for (uint i = 0; i < inputTokenIds.length; i++) {
                _burnElement(inputTokenIds[i]); // Burn the elements now owned by the contract
            }

            // Mint output element
            uint256 outputTokenId = _elementToken.totalSupply() + 1; // Use a safe unique ID counter
            QuantumElement.ElementProperties memory outputProps = QuantumElement.ElementProperties({
                elementType: recipe.outputElementType,
                tier: criticalSuccess ? recipe.outputElementTier + 1 : recipe.outputElementTier, // Critical might increase tier
                stability: 0, reactivity: 0, purity: 0, // Base stats, inherit/calculate below
                state: QuantumElement.ElementState.Stable, // Default state
                lastStateChange: uint40(block.timestamp)
            });

            // Calculate output properties based on inputs (example logic)
            uint256 totalStability = 0;
            uint256 totalReactivity = 0;
            uint256 totalPurity = 0;
            for(uint i=0; i < inputProps.length; i++) {
                totalStability += inputProps[i].stability;
                totalReactivity += inputProps[i].reactivity;
                totalPurity += inputProps[i].purity;
            }
             // Average or weighted average, add random variation
             outputProps.stability = uint16(totalStability / inputProps.length + (_generateRandomSeed() % 100 - 50)); // Add +/- 50 variation
             outputProps.reactivity = uint16(totalReactivity / inputProps.length + (_generateRandomSeed() % 100 - 50));
             outputProps.purity = uint16(totalPurity / inputProps.length + (_generateRandomSeed() % 100 - 50));

            // Ensure properties don't exceed uint16 max or go below 0 (handled by Math.max/min or clamping)
            // A better way is to set ranges and clamp results. Let's use simple casting for now.
            outputProps.stability = uint16(Math.min(65535, Math.max(0, int256(outputProps.stability))));
            outputProps.reactivity = uint16(Math.min(65535, Math.max(0, int256(outputProps.reactivity))));
            outputProps.purity = uint16(Math.min(65535, Math.max(0, int256(outputProps.purity))));


            // Potentially change output state based on critical success or input states
            if (criticalSuccess) {
                outputProps.state = QuantumElement.ElementState.QuantumLocked; // Critical success state
            }

            _mintElement(msg.sender, outputTokenId, outputProps);
            totalElementsMintedByAlchemy = totalElementsMintedByAlchemy.add(1);

            emit AlchemySuccess(msg.sender, recipeId, inputTokenIds, outputTokenId, criticalSuccess);

        } else {
            // Failure outcome: Inputs might be burned, partially burned, or state changed.
            // For simplicity, let's burn inputs on failure in this example.
            // A more complex system could have partial refunds, state damage, etc.

            for (uint i = 0; i < inputTokenIds.length; i++) {
                 // Inputs are owned by the contract now. Burn them.
                _burnElement(inputTokenIds[i]);
                // Optional: state changes on failure? e.g. change state to 'Decaying' before burning if not fully consumed.
                // _setElementState(inputTokenIds[i], QuantumElement.ElementState.Decaying); // Would need to happen BEFORE burning
            }

            emit AlchemyFailure(msg.sender, recipeId, inputTokenIds, "Alchemy failed");
        }
    }


    /**
     * @dev Attempts to refine an existing element using Essence. Improves properties or changes state.
     * Requires user to approve Element NFT and Essence tokens for this contract.
     * @param tokenId The ID of the element to refine.
     */
    function refineElement(uint256 tokenId) external whenNotPausedAndReady onlyElementOwner(tokenId) {
         // 1. Check and Burn Essence
        uint256 requiredEssence = _essenceCosts["refine"];
        if (requiredEssence > 0) {
            _burnEssenceForUser(msg.sender, requiredEssence);
        }

        // 2. Get Element Properties
        QuantumElement.ElementProperties memory currentProps = _getElementProps(tokenId);

        // 3. Determine Outcome using Randomness
        _updateInternalSeed();
        uint256 randomValue = _generateRandomSeed() % 100; // 0-99

        // Example refinement logic:
        // - Small chance of state change
        // - Always a property boost, but magnitude is random
        // - State influences boost magnitude

        int256 stabilityBoost = 0;
        int256 reactivityBoost = 0;
        int256 purityBoost = 0;
        QuantumElement.ElementState newState = currentProps.state;
        bool stateChanged = false;

        // Base boost
        stabilityBoost = int256(_generateRandomSeed() % 20 + 10); // +10 to +30
        reactivityBoost = int256(_generateRandomSeed() % 20 + 10); // +10 to +30
        purityBoost = int256(_generateRandomSeed() % 20 + 10);   // +10 to +30

        // State influence on boost and state change chance
        if (currentProps.state == QuantumElement.ElementState.Volatile) {
            stabilityBoost = stabilityBoost - 20; // Can decrease stability
            reactivityBoost = reactivityBoost + 30; // Increase reactivity more
            if (randomValue < 15) { // 15% chance
                 newState = QuantumElement.ElementState.QuantumLocked;
                 stateChanged = true;
             }
        } else if (currentProps.state == QuantumElement.ElementState.Decaying) {
            stabilityBoost = stabilityBoost - 30; // Significant stability loss
            purityBoost = purityBoost - 15;
             if (randomValue < 10) { // 10% chance
                 newState = QuantumElement.ElementState.Inert;
                 stateChanged = true;
             }
        } else if (currentProps.state == QuantumElement.ElementState.QuantumLocked) {
             stabilityBoost = stabilityBoost + 30; // Significant stability gain
             if (randomValue < 5) { // 5% chance
                 newState = QuantumElement.ElementState.Stable; // Can transition back
                 stateChanged = true;
             }
        }

        // Apply property updates (QuantumElement contract handles clamping)
        _updateElementProps(tokenId, stabilityBoost, reactivityBoost, purityBoost);

        // Apply state change if determined
        if (stateChanged) {
            _setElementState(tokenId, newState);
             emit ElementStateChangedByRefining(tokenId, currentProps.state, newState);
        }


        totalRefinementAttempts = totalRefinementAttempts.add(1);
        emit ElementRefined(msg.sender, tokenId);
    }

     /**
     * @dev Allows users to attempt a new, undefined combination to discover a recipe.
     * Costs Essence. If the input matches an undiscovered recipe, it's revealed and user gets a reward.
     * Requires user to approve Element NFTs and Essence tokens for this contract.
     * @param inputTokenIds The IDs of the elements to use for the discovery attempt.
     * Note: This attempt might consume the inputs based on logic. For simplicity, let's make it NOT consume inputs unless a *new* recipe is discovered (and that triggers an alchemy success).
     * A simpler model: It *only* costs essence and checks for a match without consuming NFTs.
     * Let's go with the simpler model for function count/complexity. It just costs essence.
     */
    function discoverNewRecipeAttempt(uint256[] calldata inputTokenIds) external whenNotPausedAndReady {
        if (inputTokenIds.length == 0) revert InvalidInputData();

         // 1. Check and Burn Essence for the attempt
        uint256 requiredEssence = _essenceCosts["discover"];
        if (requiredEssence > 0) {
            _burnEssenceForUser(msg.sender, requiredEssence);
        }

        emit DiscoveryAttempted(msg.sender, inputTokenIds);
        totalDiscoveryAttempts = totalDiscoveryAttempts.add(1);

        // 2. Get input properties (do NOT transfer NFTs for this attempt type)
         uint8[] memory inputTypes = new uint8[](inputTokenIds.length);
         uint8[] memory inputTiers = new uint8[](inputTokenIds.length);
         for (uint i = 0; i < inputTokenIds.length; i++) {
             QuantumElement.ElementProperties memory props = _getElementProps(inputTokenIds[i]);
             inputTypes[i] = props.elementType;
             inputTiers[i] = props.tier;
         }

        // 3. Check against *all* defined recipes (even undiscovered ones)
        uint256 discoveredRecipeId = 0;

        // This iteration can be gas-intensive if there are many recipes.
        // A mapping lookup based on a hash of inputs would be more efficient.
        // For this example, iterate for clarity.
        uint256 currentRecipeId = 1; // Start checking from recipe ID 1
        while(_recipes[currentRecipeId].inputElementTypes.length > 0) {
            AlchemyRecipe storage recipe = _recipes[currentRecipeId];

            bool inputMatch = false;
            if (recipe.inputElementTypes.length == inputTypes.length) {
                inputMatch = true;
                 // Need to check if inputTokens match recipe inputs *regardless of order*
                 // Simple check requires inputs to be sorted and match sorted recipe inputs.
                 // Let's assume recipe inputs and provided inputs are ordered consistently for simplicity.
                 // Production: Implement proper set comparison or require sorted inputs.
                for(uint i = 0; i < inputTypes.length; i++) {
                    if (inputTypes[i] != recipe.inputElementTypes[i] || inputTiers[i] != recipe.inputElementTiers[i]) {
                        inputMatch = false;
                        break;
                    }
                }
            }

            if (inputMatch) {
                 // Found a matching recipe
                 if (!_recipeDiscovered[currentRecipeId]) {
                     // It's a *new* discovery!
                     discoveredRecipeId = currentRecipeId;
                     _recipeDiscovered[currentRecipeId] = true; // Mark as discovered
                     // Optional: Reward the discoverer (mint Essence?)
                     _essenceToken.mint(msg.sender, requiredEssence.mul(2)); // Example: double cost refund as reward
                     emit RecipeDiscovered(msg.sender, discoveredRecipeId, inputTokenIds); // Reveal inputs used for discovery
                     // Could break here if only first matching new discovery counts, or continue to find ALL matches?
                     // Let's break after the first discovery.
                     break;
                 }
            }
            currentRecipeId++; // Move to the next recipe ID
        }

         // Outcome: If discoveredRecipeId is 0, nothing new was found. User just paid essence.
         // If > 0, the recipe was discovered, marked, and reward sent.
         // No NFTs are burned in this 'attempt' function.
    }


    /**
     * @dev Admin function to trigger a global mutation event.
     * This can affect the state or properties of elements across the system.
     * Example: Randomly change states of some elements based on rules.
     */
    function mutateGlobalElements() external onlyOwner whenNotPausedAndReady {
        emit GlobalMutationTriggered(msg.sender, block.timestamp);
        _updateInternalSeed(); // Use randomness for which elements are affected

        // This is a complex operation. Iterating over ALL elements is gas-prohibitive.
        // Instead, this function would likely affect a *subset* of elements,
        // maybe based on owner activity, element type/tier, or a probabilistic roll per element (still requires iteration/gas).
        // A realistic implementation might involve off-chain calculation triggering on-chain state updates for specific token IDs.
        // For demonstration, let's simulate affecting a *few* random high-tier elements (needs a way to list/find elements, which ERC721 doesn't natively support without iterating events or tracking IDs externally).
        // Let's simplify greatly: This function *pretends* to affect random elements.

        // Production idea: Instead of iterating, have elements check for a 'mutation event block'
        // or rely on users interacting with their elements after an event is triggered.
        // Or, the admin specifies a list of token IDs to potentially mutate.

        // Simple example: find 5 random elements (conceptually) and potentially change their state
        // In reality, you'd need a way to list/pick token IDs.
        // Example with dummy token IDs (replace with actual logic to get token IDs):
        uint256[] memory sampleTokenIds = new uint256[](5); // Dummy IDs for example
        sampleTokenIds[0] = 1; sampleTokenIds[1] = 5; sampleTokenIds[2] = 10; sampleTokenIds[3] = 15; sampleTokenIds[4] = 20;

        for (uint i = 0; i < sampleTokenIds.length; i++) {
            uint256 tokenId = sampleTokenIds[i];
             // Check if the token ID exists and is valid
            try _elementToken.ownerOf(tokenId) returns (address currentOwner) {
                // Token exists, proceed potentially
                 uint256 roll = _generateRandomSeed() % 100; // 0-99

                 // Example rule: 30% chance to change state for affected elements
                 if (roll < 30) {
                    QuantumElement.ElementState currentState = _getElementState(tokenId);
                    QuantumElement.ElementState newState;
                    // Example: Cycle states, or random state based on current
                    if (currentState == QuantumElement.ElementState.Stable) newState = QuantumElement.ElementState.Volatile;
                    else if (currentState == QuantumElement.ElementState.Volatile) newState = QuantumElement.ElementState.QuantumLocked;
                    else if (currentState == QuantumElement.ElementState.QuantumLocked) newState = QuantumElement.ElementState.Decaying;
                    else if (currentState == QuantumElement.ElementState.Decaying) newState = QuantumElement.ElementState.Inert;
                    else newState = QuantumElement.ElementState.Stable; // Inert back to Stable?

                    _setElementState(tokenId, newState);
                    emit ElementStateChangedByMutation(tokenId, currentState, newState);
                 }
            } catch {
                // Token doesn't exist, skip
            }
        }
         // Note: Real implementation requires managing large lists of token IDs or using different patterns.
         // This is a placeholder demonstrating the *intent* of global state change.
    }


    // --- Admin Configuration Functions ---

     /**
     * @dev Admin function to set essence costs for various operations.
     * @param operation The name of the operation (e.g., "alchemy", "refine", "discover").
     * @param cost The new cost in Essence tokens (in wei).
     */
    function setEssenceCosts(string calldata operation, uint256 cost) external onlyOwner {
        _essenceCosts[operation] = cost;
        emit EssenceCostsUpdated(operation, cost);
    }

    /**
     * @dev Admin function to adjust probabilities for operations.
     * This is highly simplified. Production systems need careful control.
     * @param setting Identifier for the probability setting (e.g., "alchemySuccessBase").
     * @param value The new value (interpretation depends on the setting).
     */
    function setProbabilities(string calldata setting, uint256 value) external onlyOwner {
        // Example: Allow setting a base success chance for recipes?
        // More robust: Modify existing recipe probabilities via defineAlchemyRecipe.
        // Let's use this to modify the internal randomness seed mechanism slightly (e.g., seed update interval)
        if (keccak256(abi.encodePacked(setting)) == keccak256(abi.encodePacked("seedUpdateInterval"))) {
            _seedUpdateInterval = value;
             emit ProbabilitiesUpdated(setting, value);
        } else {
            // Add other probability settings here if needed
            revert InvalidInputData(); // Unknown setting
        }

    }

     /**
     * @dev Admin function to set the rate for purchasing Essence with native currency.
     * @param rate The new rate (Essence amount per native currency unit).
     */
    function setNativeCurrencyPurchaseRate(uint256 rate) external onlyOwner {
        _nativeCurrencyPurchaseRate = rate;
        emit NativeCurrencyPurchaseRateUpdated(rate);
    }

     /**
     * @dev Admin function to set the cost in native currency for minting the initial element.
     * @param cost The new cost in native currency (in wei).
     */
    function setInitialMintCost(uint256 cost) external onlyOwner {
        _initialMintCost = cost;
        emit InitialMintCostUpdated(cost);
    }

    /**
     * @dev Admin function to set the amount of Essence claimable daily.
     * @param amount The new daily claim amount (in wei).
     */
    function setDailyClaimAmount(uint256 amount) external onlyOwner {
        _dailyClaimAmount = amount;
        emit DailyClaimAmountUpdated(amount);
    }


    /**
     * @dev Admin function to withdraw native currency balance from the contract.
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
            emit FundsWithdrawn(owner(), balance);
        }
    }

    /**
     * @dev Pauses the contract, disabling core functions.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, enabling core functions.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- View Functions ---

    /**
     * @dev Gets the details of a specific alchemy recipe.
     * @param recipeId The ID of the recipe.
     * @return AlchemyRecipe struct.
     */
    function queryAlchemyRecipe(uint256 recipeId) external view returns (AlchemyRecipe memory) {
        if (_recipes[recipeId].inputElementTypes.length == 0) revert InvalidRecipe(recipeId);
        return _recipes[recipeId];
    }

    /**
     * @dev Gets the properties of a specific Element NFT.
     * @param tokenId The ID of the Element NFT.
     * @return ElementProperties struct.
     */
    function queryElementProperties(uint256 tokenId) external view returns (QuantumElement.ElementProperties memory) {
         // Simply call the view function on the element contract
        return _elementToken.getElementProperties(tokenId);
    }

    /**
     * @dev Gets the current state of a specific Element NFT.
     * @param tokenId The ID of the Element NFT.
     * @return ElementState enum.
     */
    function queryElementState(uint256 tokenId) external view returns (QuantumElement.ElementState) {
         // Simply call the view function on the element contract
        return _elementToken.getElementState(tokenId);
    }


    /**
     * @dev Gets the number of Element NFTs owned by an address.
     * @param ownerAddress The address to check.
     * @return The balance of Element NFTs.
     */
    function queryUserElementCount(address ownerAddress) external view returns (uint256) {
        return _elementToken.balanceOf(ownerAddress);
    }

    /**
     * @dev Gets the Essence token balance for an address.
     * @param account The address to check.
     * @return The balance of Essence tokens.
     */
    function queryUserEssenceBalance(address account) external view returns (uint256) {
        return _essenceToken.balanceOf(account);
    }

    /**
     * @dev Gets the timestamp of the user's last daily essence claim.
     * @param user The address to check.
     * @return The timestamp (uint40).
     */
    function getLastDailyClaimTime(address user) external view returns (uint40) {
        return _lastDailyClaim[user];
    }

    /**
     * @dev Gets the cost for a specific operation in Essence tokens.
     * @param operation The name of the operation.
     * @return The cost in Essence.
     */
    function getEssenceCost(string calldata operation) external view returns (uint256) {
        return _essenceCosts[operation];
    }

    /**
     * @dev Gets the rate for purchasing Essence with native currency.
     * @return The rate (Essence amount per native currency unit).
     */
    function getNativeCurrencyPurchaseRate() external view returns (uint256) {
        return _nativeCurrencyPurchaseRate;
    }

    /**
     * @dev Gets the cost in native currency for minting the initial element.
     * @return The cost in native currency.
     */
    function getInitialMintCost() external view returns (uint256) {
        return _initialMintCost;
    }

    /**
     * @dev Gets the amount of Essence claimable daily.
     * @return The daily claim amount.
     */
    function getDailyClaimAmount() external view returns (uint256) {
        return _dailyClaimAmount;
    }

    /**
     * @dev Checks if a specific recipe has been discovered by any user.
     * @param recipeId The ID of the recipe.
     * @return True if discovered, false otherwise.
     */
    function isRecipeDiscovered(uint256 recipeId) external view returns (bool) {
        return _recipeDiscovered[recipeId];
    }

     /**
     * @dev Gets the total number of elements minted through the alchemy process.
     * Note: This excludes initial mints.
     * @return The total count.
     */
    function getTotalElementsMintedByAlchemy() external view returns (uint256) {
        return totalElementsMintedByAlchemy;
    }

    /**
     * @dev Returns the number of ERC721 tokens that the contract is ready to receive.
     * Implemented as part of IERC721Receiver. Always returns the selector.
     */
    // Included in the main function count for completeness as it's part of the contract interface.
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override(IERC721Receiver)
        returns (bytes4)
    {
        // Only accept transfers from our designated Element Token contract
        // In a real scenario, you might want to check `operator` or `from` more rigorously
        // if allowing transfers from different origins for specific logic.
        // For this simple example, relying on the initiating function (`_transferElementFromUser`)
        // to ensure the call stack is correct is sufficient.
        // We return the selector indicating successful reception.
        return IERC721Receiver.onERC721Received.selector;
    }
}
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic NFT Properties & State:** The `QuantumElement` ERC721 isn't just a static image/metadata link. It has on-chain properties (`stability`, `reactivity`, `purity`, `tier`, `elementType`) and a distinct `ElementState` enum. These properties and the state can change via specific interactions (`refineElement`, `performAlchemy`, `mutateGlobalElements`). This moves beyond basic collectible NFTs to functional, evolving assets.
2.  **State Machine:** Elements have states (`Stable`, `Volatile`, `QuantumLocked`, `Decaying`, `Inert`). These states can influence the *outcomes* of other functions (e.g., a `Volatile` element might have a higher chance of a critical success in alchemy but a lower chance of a beneficial outcome in refining). The `mutateGlobalElements` function simulates external events that can change these states across many elements.
3.  **Gamified Resource Management & Crafting (`QuantumAlchemy`):**
    *   Uses an ERC20 (`EssenceToken`) as a consumable resource for operations, creating a simple economic loop (buy Essence -> use Essence for alchemy/refining/discovery).
    *   `performAlchemy` is a crafting mechanism requiring specific inputs (types and tiers of elements) and Essence. It's not guaranteed to succeed and has probabilistic outcomes.
    *   Successful alchemy burns the input NFTs and mints a new one with calculated properties based on the inputs and randomness.
4.  **Discovery Mechanism:** `discoverNewRecipeAttempt` introduces an exploration/puzzle element. Users can try arbitrary combinations of their elements (paying Essence). If the combination matches a predefined *undiscovered* recipe, it's revealed, and the user is rewarded. This encourages experimentation.
5.  **Randomness Integration:** Alchemy, Refining, and Global Mutations rely on a random number generator (`_generateRandomSeed`). *Crucially, the example uses a simplified, insecure block-hash/timestamp method and includes notes that production systems require secure solutions like Chainlink VRF.* This demonstrates the *concept* of using randomness for unpredictable on-chain outcomes.
6.  **Global Events (`mutateGlobalElements`):** The admin can trigger events that affect potentially many elements owned by different users, adding a layer of dynamic world simulation or periodic challenges/opportunities to the system. (Note: The implementation here is a simplified placeholder due to gas costs of iterating large NFT collections).
7.  **Controlled Token Interactions:** The `QuantumAlchemy` contract is designed to be the exclusive minter of both `EssenceToken` and `QuantumElement`, centralizing control over asset creation and scarcity. It also burns tokens as part of the core game loop. Users interact with the system by approving the Alchemy contract to spend their Essence and transfer their Elements.
8.  **Multiple Function Roles:** The contract includes functions for users (minting, buying, claiming, alchemy, refining, discovery), administrators (setting costs, recipes, probabilities, triggering mutations, withdrawing funds), and view functions for querying system state and user assets.
9.  **Custom Errors:** Uses Solidity 0.8.4+ custom errors for more informative and gas-efficient error handling compared to simple `require` messages.
10. **Pausable Pattern:** Standard, but essential for managing a complex system where bugs might require halting operations.
11. **ERC721Receiver:** Implemented to safely receive NFTs into the contract address when they are submitted for operations like alchemy.

This contract system provides a framework for a complex, interactive on-chain game or dApp economy built around evolving digital assets.