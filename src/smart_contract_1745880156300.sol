Okay, let's design a creative and advanced smart contract concept focusing on dynamic NFTs, crafting, staking with state changes, and incorporating randomness and potentially a decay mechanism. We'll call it "QuantumForge".

The core idea is NFTs ("Essences") that have mutable properties ("Purity", "Instability", "Traits"). Users can interact with these NFTs and other tokens ("Aether Dust" ERC-20, "Components" ERC-1155) through various actions like Forging, Staking, Linking, and Extraction, which modify the NFT's state.

This contract combines elements of:
1.  **Dynamic NFTs:** NFT properties change based on interactions.
2.  **Crafting System:** Users combine resources to attempt transformations.
3.  **Staking with Side Effects:** Staking the NFT itself changes its state (purification) instead of just yielding tokens.
4.  **Randomness:** Using Chainlink VRF for unpredictable forging outcomes.
5.  **Multiple Token Standards:** Interacting with ERC-721, ERC-20, and ERC-1155.
6.  **Decay Mechanism:** Encouraging interaction to prevent negative state changes.
7.  **Linking:** A novel concept to link NFTs together for potential combined effects.

---

**Outline:**

1.  **Imports:** Standard libraries (ERC721, ERC20, ERC1155, Ownable, VRFConsumerBaseV2).
2.  **Error Handling:** Custom errors for clarity.
3.  **Enums & Constants:** Define states or types.
4.  **Structs:**
    *   `EssenceDetails`: Stores mutable properties for each ERC721 ID (Purity, Instability, Traits, LastInteracted, Staking details, Linked ID).
    *   `ForgingRecipe`: Defines inputs, outputs, probabilities, and effects for crafting.
    *   `StakingDetails`: Stores staking-specific info (startTime, accumulatedDust).
5.  **State Variables:**
    *   Mappings for Essence details, Staking details.
    *   Counter for Essence IDs.
    *   Mappings for Forging Recipes.
    *   Addresses for linked ERC-20 (Aether Dust) and ERC-1155 (Components) contracts (or handle internally). Let's handle them internally for simplicity in this example.
    *   Chainlink VRF variables (keyHash, fee, subscriptionId, request counter, mapping requestId to essenceId).
    *   Configuration parameters (decay rate, purify rate, staking dust rate, initial properties, link cooldown).
6.  **Events:** Log key actions (Mint, Forged, Purified, Staked, Unstaked, Decayed, Linked, Extracted, RecipeAdded, VRFRequested, VRFFulfilled).
7.  **Modifiers:** `onlyOwner`, `isEssenceOwner`, `notStaked`, `isStaked`, `notLinked`, `isLinked`, `essenceExists`.
8.  **Constructor:** Initialize VRF, set owner, maybe mint initial components/dust.
9.  **ERC Standard Implementations:** Basic ERC721, ERC20, ERC1155 overrides if needed, but mostly inherited.
10. **Core Mechanics Functions:**
    *   `mintEssence`: Create a new Essence NFT with initial properties.
    *   `forgeEssence`: Consume Dust/Components, trigger VRF for transformation.
    *   `fulfillRandomWords`: VRF callback, apply forging results.
    *   `stakeEssence`: Lock an Essence NFT for purification.
    *   `unstakeEssence`: Unlock NFT, calculate/apply purification/decay, claim staking rewards.
    *   `triggerDecay`: Public function to allow triggering decay calculation for an inactive Essence.
    *   `extractAetherDust`: Sacrifice Essence Purity/Instability for Dust.
    *   `linkEssences`: Link two specified Essence NFTs.
    *   `unlinkEssence`: Break a link for a specific Essence.
11. **Configuration & Utility Functions:**
    *   `addForgingRecipe`: Owner adds a new recipe.
    *   `removeForgingRecipe`: Owner removes a recipe.
    *   `setConfiguration`: Owner sets dynamic parameters.
    *   `requestRandomWords`: Internal VRF request (called by forge).
    *   `withdrawFunds`: Owner withdraws ERC20/ETH accidentally sent.
    *   `grantRole`: Access control for certain admin tasks if needed.
12. **View/Pure Functions:**
    *   `getEssenceDetails`: Get all details of an Essence.
    *   `getEssenceStakingDetails`: Get staking info for an Essence.
    *   `getRecipeDetails`: Get details of a forging recipe.
    *   `calculateCurrentPurity`: Calculate purity considering decay/purification time.
    *   `calculateCurrentInstability`: Calculate instability considering decay/purification time.
    *   `calculateStakingDustAccrued`: Calculate dust earned while staked.
    *   `getTrait`: Check if an Essence has a specific trait (simple implementation).
    *   `isEssenceLinked`: Check if an Essence is linked.
    *   `getLinkedEssence`: Get the ID of the linked Essence.
    *   `getTotalEssencesMinted`: Get the total number of Essences.
    *   `getVRFRequestStatus`: Check status of a VRF request.
    *   `getAetherDustBalance`: Get balance of Aether Dust.
    *   `getComponentBalance`: Get balance of Components.

---

**Function Summary:**

1.  `constructor(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, uint96 requestConfirmations)`: Initializes the contract, setting VRF parameters and linking the owner role.
2.  `mintEssence()`: Mints a new ERC721 Quantum Essence token to the caller, initializing its dynamic properties (Purity, Instability) and last interaction timestamp.
3.  `forgeEssence(uint256 essenceId, uint256 recipeId, uint256 catalystTypeId)`: Allows an Essence owner to attempt a forging recipe. Requires spending Aether Dust and specific Components (ERC-1155). Triggers a Chainlink VRF request to determine the outcome based on the recipe and potentially the Essence's properties or catalyst used.
4.  `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback function. It receives random values and applies the forging outcome to the corresponding Essence, modifying its Purity, Instability, and/or Traits based on the recipe and randomness.
5.  `stakeEssence(uint256 essenceId)`: Allows an Essence owner to stake their NFT in the contract. Starts accruing Aether Dust rewards and initiates a purification process over time, reducing Instability and potentially increasing Purity.
6.  `unstakeEssence(uint256 essenceId)`: Allows a staked Essence owner to unstake it. Calculates earned Aether Dust, applies the total purification/decay effects based on the staking duration, and transfers the NFT back to the owner.
7.  `claimStakingDust(uint256 essenceId)`: Allows a staked Essence owner to claim accumulated Aether Dust rewards without unstaking the NFT.
8.  `triggerDecay(uint256 essenceId)`: A permissionless (or perhaps rate-limited/incentivized) function that anyone can call for an Essence that hasn't been interacted with (forged, staked, unstaked, linked, extracted) for a certain period. Calculates and applies the decay effect, increasing Instability and potentially reducing Purity.
9.  `extractAetherDust(uint256 essenceId, uint256 amount)`: Allows an Essence owner to sacrifice some of the Essence's Purity or Instability (depending on logic) to extract Aether Dust from it, potentially 'burning' some of its essence.
10. `linkEssences(uint256 essenceId1, uint256 essenceId2)`: Allows owners of two separate, unlinked Essences to link them together. This creates a mutual reference between the two NFTs. Linked Essences might gain bonuses (e.g., shared staking effects) or unlock special forging recipes.
11. `unlinkEssence(uint256 essenceId)`: Allows the owner of a linked Essence to break the link, also breaking the link on the other connected Essence.
12. `addForgingRecipe(uint256 recipeId, uint256 requiredDust, ForgingInput[] memory inputs, ForgingOutcome[] memory outcomes)`: Owner function to define a new crafting recipe. Specifies input resources (Dust, Components) and potential outcomes with associated probabilities and resulting property changes/traits.
13. `removeForgingRecipe(uint256 recipeId)`: Owner function to deactivate or remove an existing forging recipe.
14. `setConfiguration(bytes32 key, uint256 value)`: Owner function to update various configurable parameters (e.g., decay rate per hour, purity gain per staked hour, staking dust reward rate, initial property ranges, link cooldown). Uses a key-value approach for flexibility.
15. `getEssenceDetails(uint256 essenceId)`: View function returning the detailed mutable properties of a specific Essence NFT.
16. `getEssenceStakingDetails(uint256 essenceId)`: View function returning staking-specific details for an Essence.
17. `getRecipeDetails(uint256 recipeId)`: View function returning the details of a specific forging recipe, including inputs and potential outcomes.
18. `calculateCurrentPurity(uint256 essenceId)`: Pure/View function that calculates the current Purity of an Essence by considering its base purity and the time passed since the last interaction, applying decay or purification rates.
19. `calculateCurrentInstability(uint256 essenceId)`: Pure/View function that calculates the current Instability similarly, applying decay or purification rates based on inactivity or staking.
20. `calculateStakingDustAccrued(uint256 essenceId)`: Pure/View function calculating the amount of Aether Dust that has accumulated as a reward for staking an Essence.
21. `getTrait(uint256 essenceId, string memory traitName)`: View function to check if an Essence NFT currently possesses a specific trait (based on the traits stored in the `EssenceDetails` struct).
22. `isEssenceLinked(uint256 essenceId)`: View function to check if a specific Essence NFT is currently linked to another.
23. `getLinkedEssence(uint256 essenceId)`: View function returning the ID of the Essence linked to the specified one, or 0 if not linked.
24. `getTotalEssencesMinted()`: View function returning the total number of Quantum Essence NFTs minted so far.
25. `withdrawFunds(address tokenAddress, uint256 amount)`: Owner function to withdraw any specific ERC20 token or Ether accidentally sent to the contract.
26. `mintAetherDust(address account, uint256 amount)`: Owner function to mint Aether Dust tokens to a specific account. (Could be part of initial distribution or admin tool).
27. `mintComponents(address account, uint256 typeId, uint256 amount)`: Owner function to mint specific types of ERC-1155 Components to an account.
28. `burnAetherDust(address account, uint256 amount)`: Owner function to burn Aether Dust tokens from an account. (Could also be a user function for some effect).
29. `burnComponents(address account, uint256 typeId, uint256 amount)`: Owner function to burn specific types of ERC-1155 Components from an account.
30. `getAetherDustBalance(address account)`: View function for Aether Dust balance.
31. `getComponentBalance(address account, uint256 typeId)`: View function for Component balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For total supply etc.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol"; // Needed if paying VRF with LINK

// Note: This implementation assumes Aether Dust (ERC20) and Components (ERC1155)
// are managed internally by this contract for simplicity. In a real scenario,
// they might be external contracts.

// Custom Errors for clarity
error QuantumForge__EssenceDoesNotExist(uint256 essenceId);
error QuantumForge__NotEssenceOwner(uint256 essenceId);
error QuantumForge__EssenceAlreadyStaked(uint256 essenceId);
error QuantumForge__EssenceNotStaked(uint256 essenceId);
error QuantumForge__EssenceAlreadyLinked(uint256 essenceId);
error QuantumForge__EssenceNotLinked(uint256 essenceId);
error QuantumForge__CannotLinkToSelf();
error QuantumForge__LinkingDifferentOwners(); // Decide if linking requires same owner
error QuantumForge__RecipeDoesNotExist(uint256 recipeId);
error QuantumForge__InsufficientAetherDust(uint256 required, uint256 has);
error QuantumForge__InsufficientComponents(uint256 typeId, uint256 required, uint256 has);
error QuantumForge__NothingToClaim();
error QuantumForge__DecayCooldownActive(uint256 timeRemaining);
error QuantumForge__ExtractionAmountInvalid();
error QuantumForge__VRFRequestFailed();
error QuantumForge__CallbackGasLimitTooHigh(); // For VRF config

/**
 * @title QuantumForge
 * @dev A smart contract managing dynamic NFTs (Essences) with crafting, staking,
 *      linking, decay mechanisms, and Chainlink VRF integration for outcomes.
 */
contract QuantumForge is ERC721Enumerable, ERC20, ERC1155, Ownable, VRFConsumerBaseV2 {

    // --- Structs ---

    /**
     * @dev Represents the dynamic properties of a Quantum Essence NFT.
     * @param purity A measure of the Essence's refinement (0-100). Can increase via staking, decrease via decay/extraction.
     * @param instability A measure of the Essence's chaotic energy (0-100). Can decrease via staking, increase via decay/forging failures.
     * @param traits Bytes representation of unique traits the Essence possesses.
     * @param lastInteracted Timestamp of the last significant interaction (mint, forge, stake, unstake, link, unlink, extract). Used for decay calculation.
     * @param linkedEssenceId The ID of another Essence this one is linked to (0 if not linked).
     */
    struct EssenceDetails {
        uint8 purity; // 0-100
        uint8 instability; // 0-100
        bytes traits;
        uint40 lastInteracted; // Use uint40 for efficiency, timestamp won't exceed this for a long time
        uint256 linkedEssenceId;
    }

    /**
     * @dev Stores details when an Essence NFT is staked.
     * @param stakeStartTime Timestamp when staking began.
     * @param dustAccumulated Amount of Aether Dust accrued as rewards.
     */
    struct StakingDetails {
        uint40 stakeStartTime;
        uint256 dustAccumulated;
    }

    /**
     * @dev Represents a required input component for a forging recipe.
     * @param componentTypeId The ERC-1155 type ID of the component.
     * @param amount The quantity of the component required.
     */
    struct ForgingInput {
        uint256 componentTypeId;
        uint256 amount;
    }

    /**
     * @dev Represents a potential outcome of a forging recipe.
     * @param probability The weight or chance of this outcome occurring (relative to other outcomes).
     * @param purityChange Change in Purity (+/-).
     * @param instabilityChange Change in Instability (+/-).
     * @param resultingTraits Bytes of traits to add or remove (logic handled in apply).
     * @param dustRefund Optional Aether Dust refunded on success.
     */
    struct ForgingOutcome {
        uint16 probability; // Relative probability weight
        int8 purityChange;
        int8 instabilityChange;
        bytes resultingTraits; // Logic to apply (add/remove based on byte structure)
        uint256 dustRefund;
    }

    /**
     * @dev Represents a forging recipe.
     * @param requiredDust Total Aether Dust consumed by the recipe attempt.
     * @param inputs Array of required ForgingInput components.
     * @param outcomes Array of possible ForgingOutcome results, weighted by probability.
     */
    struct ForgingRecipe {
        uint256 requiredDust;
        ForgingInput[] inputs;
        ForgingOutcome[] outcomes;
    }

    // --- State Variables ---

    // Core Essence Data
    mapping(uint256 => EssenceDetails) private s_essenceDetails;
    uint256 private s_nextTokenId; // Counter for ERC721 IDs

    // Staking Data
    mapping(uint256 => StakingDetails) private s_stakedEssences; // 0 if not staked
    mapping(address => uint256[]) private s_ownerStakedEssences; // Keep track of staked essences per owner (can be inefficient for many)

    // Forging Data
    mapping(uint256 => ForgingRecipe) private s_forgingRecipes;
    uint256 private s_recipeCount; // Simple counter for recipe IDs

    // Configuration Parameters (Using a flexible key-value store)
    mapping(bytes32 => uint256) private s_config;

    // VRF Data (Chainlink VRF V2)
    VRFConsumerBaseV2 private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint96 private immutable i_requestConfirmations; // Minimum number of blocks to wait
    uint256 private s_vrfRequestCounter;
    mapping(uint256 => uint256) private s_requestIdToEssenceId; // Link VRF request ID to Essence being forged

    // ERC-1155 Component Type IDs (Example)
    uint256 public constant COMPONENT_A = 1;
    uint256 public constant COMPONENT_B = 2;
    uint256 public constant CATALYST_BASIC = 101;
    uint256 public constant CATALYST_ADVANCED = 102;


    // --- Events ---

    event EssenceMinted(uint256 indexed essenceId, address indexed owner, uint8 initialPurity, uint8 initialInstability);
    event EssenceForged(uint256 indexed essenceId, uint256 indexed recipeId, uint256 indexed catalystTypeId, uint256 requestId);
    event ForgingOutcomeApplied(uint256 indexed essenceId, uint256 indexed recipeId, int8 purityChange, int8 instabilityChange, bytes traitsApplied); // traitsApplied could indicate what changed
    event EssenceStaked(uint256 indexed essenceId, address indexed owner);
    event EssenceUnstaked(uint256 indexed essenceId, address indexed owner, uint256 dustClaimed, uint8 finalPurity, uint8 finalInstability);
    event StakingDustClaimed(uint256 indexed essenceId, address indexed owner, uint256 dustClaimed);
    event EssenceDecayed(uint256 indexed essenceId, uint8 purityLoss, uint8 instabilityGain);
    event AetherDustExtracted(uint256 indexed essenceId, address indexed owner, uint256 dustAmount, uint8 puritySacrificed, uint8 instabilitySacrificed);
    event EssencesLinked(uint256 indexed essenceId1, uint256 indexed essenceId2, address indexed owner);
    event EssenceUnlinked(uint256 indexed essenceId1, uint256 indexed essenceId2, address indexed owner);
    event ForgingRecipeAdded(uint256 indexed recipeId);
    event ForgingRecipeRemoved(uint256 indexed recipeId);
    event ConfigurationUpdated(bytes32 indexed key, uint256 value);
    event ComponentsMinted(address indexed account, uint256 indexed typeId, uint256 amount);
    event ComponentsBurned(address indexed account, uint256 indexed typeId, uint256 amount);

    // --- Modifiers ---

    modifier essenceExists(uint256 essenceId) {
        if (!_exists(essenceId)) revert QuantumForge__EssenceDoesNotExist(essenceId);
        _;
    }

    modifier isEssenceOwner(uint256 essenceId) {
        if (ownerOf(essenceId) != msg.sender) revert QuantumForge__NotEssenceOwner(essenceId);
        _;
    }

    modifier notStaked(uint256 essenceId) {
        if (s_stakedEssences[essenceId].stakeStartTime > 0) revert QuantumForge__EssenceAlreadyStaked(essenceId);
        _;
    }

    modifier isStaked(uint256 essenceId) {
        if (s_stakedEssences[essenceId].stakeStartTime == 0) revert QuantumForge__EssenceNotStaked(essenceId);
        _;
    }

     modifier notLinked(uint256 essenceId) {
        if (s_essenceDetails[essenceId].linkedEssenceId != 0) revert QuantumForge__EssenceAlreadyLinked(essenceId);
        _;
    }

     modifier isLinked(uint256 essenceId) {
        if (s_essenceDetails[essenceId].linkedEssenceId == 0) revert QuantumForge__EssenceNotLinked(essenceId);
        _;
    }

    // --- Constructor ---

    constructor(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, uint96 requestConfirmations)
        ERC721("QuantumEssence", "QE")
        ERC20("AetherDust", "AD")
        ERC1155("") // Base URI can be set later or overridden
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(msg.sender)
    {
        i_vrfCoordinator = VRFConsumerBaseV2(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;

        // Set some initial default configurations
        s_config[keccak256("INITIAL_PURITY_MIN")] = 30;
        s_config[keccak256("INITIAL_PURITY_MAX")] = 70;
        s_config[keccak256("INITIAL_INSTABILITY_MIN")] = 30;
        s_config[keccak256("INITIAL_INSTABILITY_MAX")] = 70;
        s_config[keccak256("DECAY_RATE_PER_SECOND")] = 1; // 1 unit instability gain / 1 unit purity loss per day (example scaling needed) -> let's say per hour * 1e16 for 18 decimals scaling
        s_config[keccak256("PURIFY_RATE_PER_SECOND")] = 2; // 2 units instability loss / 2 units purity gain per day
        s_config[keccak256("STAKING_DUST_RATE_PER_SECOND")] = 1e18; // 1 Dust per day staked (example scaling)
        s_config[keccak256("DECAY_COOLDOWN_SECONDS")] = 7 days; // No decay calculation within 7 days of interaction
        s_config[keccak256("EXTRACTION_PURITY_COST_PER_DUST")] = 1; // 1 purity lost per dust extracted
        s_config[keccak256("LINK_COOLDOWN_SECONDS")] = 30 days; // Cannot unlink immediately after linking (optional)
    }

    // --- ERC Standard Implementations ---

    // ERC721 overrides - mostly for tracking and potential future hooks
    // _beforeTokenTransfer is useful for updating lastInteracted or checking linked status
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) { // Exclude minting/burning
             // Potentially trigger decay calculation on transfer if significant time passed?
             // Or ensure not staked/linked? (Implemented in function modifiers)
             _updateEssenceLastInteracted(tokenId);
        }
    }

    // ERC1155 overrides - required boilerplate
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ERC20 overrides - required boilerplate
    // No special overrides needed for basic transfer/approve

    // --- Core Mechanics ---

    /**
     * @dev Mints a new Quantum Essence NFT to the caller.
     * Assigns initial random-ish Purity and Instability within configured range.
     */
    function mintEssence() public returns (uint256 tokenId) {
        uint256 newItemId = s_nextTokenId++;
        _safeMint(msg.sender, newItemId);

        uint256 initialPurityMin = s_config[keccak256("INITIAL_PURITY_MIN")];
        uint256 initialPurityMax = s_config[keccak256("INITIAL_PURITY_MAX")];
        uint256 initialInstabilityMin = s_config[keccak256("INITIAL_INSTABILITY_MIN")];
        uint256 initialInstabilityMax = s_config[keccak256("INITIAL_INSTABILITY_MAX")];

        // Simple pseudo-random for initial properties (NOT secure, just for variability)
        // A more robust system might use VRF here too, but adds complexity/cost to minting
        uint8 initialPurity = uint8((uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, newItemId))) % (initialPurityMax - initialPurityMin + 1)) + initialPurityMin);
        uint8 initialInstability = uint8((uint256(keccak256(abi.encodePacked(newItemId, block.timestamp, msg.sender))) % (initialInstabilityMax - initialInstabilityMin + 1)) + initialInstabilityMin);

        s_essenceDetails[newItemId] = EssenceDetails({
            purity: initialPurity,
            instability: initialInstability,
            traits: "", // Start with no traits
            lastInteracted: uint40(block.timestamp),
            linkedEssenceId: 0
        });

        emit EssenceMinted(newItemId, msg.sender, initialPurity, initialInstability);
        return newItemId;
    }

    /**
     * @dev Allows an Essence owner to attempt a forging recipe.
     * Requires specified Aether Dust and Components. Requests randomness for the outcome.
     * @param essenceId The ID of the Essence NFT to forge.
     * @param recipeId The ID of the forging recipe to use.
     * @param catalystTypeId The ERC-1155 type ID of a catalyst (optional, use 0 if none).
     */
    function forgeEssence(uint256 essenceId, uint256 recipeId, uint256 catalystTypeId)
        public
        isEssenceOwner(essenceId)
        essenceExists(essenceId)
        notStaked(essenceId) // Cannot forge staked essences
    {
        ForgingRecipe storage recipe = s_forgingRecipes[recipeId];
        if (recipe.requiredDust == 0 && recipe.inputs.length == 0 && recipe.outcomes.length == 0) {
             revert QuantumForge__RecipeDoesNotExist(recipeId);
        }

        // Consume Aether Dust
        if (balanceOf(msg.sender) < recipe.requiredDust) {
            revert QuantumForge__InsufficientAetherDust(recipe.requiredDust, balanceOf(msg.sender));
        }
        _burn(msg.sender, recipe.requiredDust); // ERC20 burn

        // Consume Components (ERC-1155)
        for (uint i = 0; i < recipe.inputs.length; i++) {
            ForgingInput memory input = recipe.inputs[i];
            if (balanceOf(msg.sender, input.componentTypeId) < input.amount) {
                revert QuantumForge__InsufficientComponents(input.componentTypeId, input.amount, balanceOf(msg.sender, input.componentTypeId));
            }
            _burn(msg.sender, input.componentTypeId, input.amount); // ERC1155 burn
        }

        // Consume Catalyst (if provided)
        if (catalystTypeId != 0) {
             if (balanceOf(msg.sender, catalystTypeId) < 1) {
                revert QuantumForge__InsufficientComponents(catalystTypeId, 1, balanceOf(msg.sender, catalystTypeId));
             }
             _burn(msg.sender, catalystTypeId, 1); // Burn 1 catalyst
        }

        // Request Randomness
        uint256 requestId = requestRandomWords();
        s_requestIdToEssenceId[requestId] = essenceId;

        _updateEssenceLastInteracted(essenceId);

        emit EssenceForged(essenceId, recipeId, catalystTypeId, requestId);
    }

    /**
     * @dev Chainlink VRF V2 callback function.
     * Processes the forging outcome based on the random number(s).
     * @param requestId The ID of the VRF request.
     * @param randomWords The array of random words generated by Chainlink.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 essenceId = s_requestIdToEssenceId[requestId];
        require(essenceId != 0, "QF: Request ID not found"); // Should not happen if mapping is managed correctly
        delete s_requestIdToEssenceId[requestId]; // Clean up mapping

        EssenceDetails storage essence = s_essenceDetails[essenceId];
        // Re-fetch the recipe ID (assuming it was stored with the request or can be derived)
        // A more robust design might store recipeId alongside essenceId in the mapping
        // For simplicity here, let's assume the randomWords[0] somehow maps to a recipe outcome choice.
        // A real system would likely pass recipeId or link it via the requestId.
        // Let's use a simple example: The first random word determines which outcome to pick
        // based on cumulative probabilities defined in the recipe.

        // Find the recipe used (this needs to be linked to the requestId -> essenceId mapping)
        // Let's add a mapping: s_requestIdToRecipeId[requestId] = recipeId; in forgeEssence
        mapping(uint256 => uint256) private s_requestIdToRecipeId;
        // Inside forgeEssence before requestRandomWords: s_requestIdToRecipeId[requestId] = recipeId;

        uint256 recipeId = s_requestIdToRecipeId[requestId];
        delete s_requestIdToRecipeId[requestId]; // Clean up mapping

        ForgingRecipe storage recipe = s_forgingRecipes[recipeId];
        require(recipe.outcomes.length > 0, "QF: Recipe has no outcomes");

        uint256 randomValue = randomWords[0]; // Use the first random word
        uint256 totalWeight = 0;
        for (uint i = 0; i < recipe.outcomes.length; i++) {
            totalWeight += recipe.outcomes[i].probability;
        }
        require(totalWeight > 0, "QF: Recipe outcomes have zero total weight");

        uint256 chosenWeight = randomValue % totalWeight;
        uint256 cumulativeWeight = 0;
        ForgingOutcome memory chosenOutcome;
        bool foundOutcome = false;

        for (uint i = 0; i < recipe.outcomes.length; i++) {
            cumulativeWeight += recipe.outcomes[i].probability;
            if (chosenWeight < cumulativeWeight) {
                chosenOutcome = recipe.outcomes[i];
                foundOutcome = true;
                break;
            }
        }

        require(foundOutcome, "QF: Failed to select forging outcome"); // Should not happen if logic is correct

        // Apply the chosen outcome effects
        _applyForgingOutcome(essenceId, chosenOutcome);

        // Issue dust refund if applicable
        if (chosenOutcome.dustRefund > 0) {
             _mint(ownerOf(essenceId), chosenOutcome.dustRefund); // ERC20 mint
        }

        emit ForgingOutcomeApplied(essenceId, recipeId, chosenOutcome.purityChange, chosenOutcome.instabilityChange, chosenOutcome.resultingTraits);
    }

    /**
     * @dev Internal function to apply the effects of a forging outcome.
     * @param essenceId The ID of the Essence.
     * @param outcome The ForgingOutcome to apply.
     */
    function _applyForgingOutcome(uint256 essenceId, ForgingOutcome memory outcome) internal {
        EssenceDetails storage essence = s_essenceDetails[essenceId];

        // Apply Purity Change
        if (outcome.purityChange > 0) {
            essence.purity = uint8(Math.min(essence.purity + uint8(outcome.purityChange), 100));
        } else {
             essence.purity = uint8(Math.max(int16(essence.purity) + outcome.purityChange, 0)); // Use int16 for intermediate calculation
        }

        // Apply Instability Change
        if (outcome.instabilityChange > 0) {
             essence.instability = uint8(Math.min(essence.instability + uint8(outcome.instabilityChange), 100));
        } else {
            essence.instability = uint8(Math.max(int16(essence.instability) + outcome.instabilityChange, 0));
        }

        // Apply Traits (Simple append for now, real system needs trait management logic)
        // For example, prepend 0x01 to add trait, 0x00 to remove trait in bytes
        if (outcome.resultingTraits.length > 0) {
             // Example: If traits start with 0x01, append; if 0x00, remove (complex byte manipulation needed)
             // Simple version: just append
             bytes memory currentTraits = essence.traits;
             bytes memory newTraits = new bytes(currentTraits.length + outcome.resultingTraits.length);
             for(uint i=0; i < currentTraits.length; i++) { newTraits[i] = currentTraits[i]; }
             for(uint i=0; i < outcome.resultingTraits.length; i++) { newTraits[currentTraits.length + i] = outcome.resultingTraits[i]; }
             essence.traits = newTraits; // This is an oversimplification, trait management is complex
        }
    }

    /**
     * @dev Stakes an Essence NFT, starting the purification and dust accrual process.
     * @param essenceId The ID of the Essence NFT to stake.
     */
    function stakeEssence(uint256 essenceId)
        public
        isEssenceOwner(essenceId)
        essenceExists(essenceId)
        notStaked(essenceId)
    {
        // Before staking, calculate and apply any pending decay
        _applyDecayIfDue(essenceId);

        // Transfer NFT to the contract
        _safeTransfer(msg.sender, address(this), essenceId);

        s_stakedEssences[essenceId] = StakingDetails({
            stakeStartTime: uint40(block.timestamp),
            dustAccumulated: 0
        });

        // Track staked essences per owner (optional, can be expensive)
        s_ownerStakedEssences[msg.sender].push(essenceId);

        _updateEssenceLastInteracted(essenceId);

        emit EssenceStaked(essenceId, msg.sender);
    }

     /**
     * @dev Unstakes an Essence NFT. Calculates and applies purification/decay effects
     * based on staking duration and claims accumulated dust.
     * @param essenceId The ID of the Essence NFT to unstake.
     */
    function unstakeEssence(uint256 essenceId)
        public
        essenceExists(essenceId)
        isStaked(essenceId) // Ensures stakingDetails exists
    {
        address owner = ownerOf(essenceId); // Owner is the contract address now
        require(tx.origin == ERC721.ownerOf(essenceId), "QF: Only original staker can unstake"); // Basic check, improve with approval if needed

        StakingDetails storage stakingDetails = s_stakedEssences[essenceId];
        EssenceDetails storage essence = s_essenceDetails[essenceId];

        uint256 timeStaked = block.timestamp - stakingDetails.stakeStartTime;

        // Calculate Purification and Decay during staking (Purification offsets decay)
        uint256 purifyRate = s_config[keccak256("PURIFY_RATE_PER_SECOND")];
        uint256 decayRate = s_config[keccak256("DECAY_RATE_PER_SECOND")]; // Decay still applies slightly even when staked? Or no decay when staked? Let's say NO decay when staked, purify is net gain.
        uint256 netPurification = timeStaked * purifyRate / 1e18; // Scale based on config decimals

        uint8 purityGain = uint8(netPurification);
        uint8 instabilityLoss = uint8(netPurification); // Assuming equal gain/loss rates for simplicity

        essence.purity = uint8(Math.min(essence.purity + purityGain, 100));
        essence.instability = uint8(Math.max(essence.instability - instabilityLoss, 0)); // Instability decreases

        // Calculate Dust Rewards
        uint256 dustRate = s_config[keccak256("STAKING_DUST_RATE_PER_SECOND")];
        uint256 dustAccrued = stakingDetails.dustAccumulated + (timeStaked * dustRate / 1e18); // Add current accrual to previous (from claimStakingDust)

        // Mint Dust rewards to original staker
        if (dustAccrued > 0) {
            _mint(tx.origin, dustAccrued); // ERC20 mint
        }

        // Remove from staking state
        delete s_stakedEssences[essenceId];
        // Remove from owner's staked list (less efficient)
        uint256[] storage stakedList = s_ownerStakedEssences[tx.origin];
        for(uint i = 0; i < stakedList.length; i++) {
             if (stakedList[i] == essenceId) {
                 stakedList[i] = stakedList[stakedList.length - 1];
                 stakedList.pop();
                 break;
             }
        }


        // Transfer NFT back to original staker
        _safeTransfer(address(this), tx.origin, essenceId);

        _updateEssenceLastInteracted(essenceId); // Update last interaction timestamp

        emit EssenceUnstaked(essenceId, tx.origin, dustAccrued, essence.purity, essence.instability);
    }

     /**
     * @dev Allows a staked Essence owner to claim accumulated Aether Dust rewards
     * without unstaking the NFT.
     * @param essenceId The ID of the staked Essence.
     */
    function claimStakingDust(uint256 essenceId)
        public
        essenceExists(essenceId)
        isStaked(essenceId)
    {
        // Only callable by the original staker (or approved address)
        require(tx.origin == ERC721.ownerOf(essenceId), "QF: Only original staker can claim");

        StakingDetails storage stakingDetails = s_stakedEssences[essenceId];
        uint256 timeStaked = block.timestamp - stakingDetails.stakeStartTime;
        uint256 dustRate = s_config[keccak256("STAKING_DUST_RATE_PER_SECOND")];

        uint256 dustAccrued = stakingDetails.dustAccumulated + (timeStaked * dustRate / 1e18);

        if (dustAccrued == 0) {
            revert NothingToClaim();
        }

        // Mint Dust rewards
        _mint(tx.origin, dustAccrued); // ERC20 mint

        // Reset staking timer but keep the stake active
        stakingDetails.stakeStartTime = uint40(block.timestamp);
        stakingDetails.dustAccumulated = 0; // Reset accumulated dust

        emit StakingDustClaimed(essenceId, tx.origin, dustAccrued);
    }

    /**
     * @dev Allows triggering a decay calculation for an inactive Essence.
     * Can be called by anyone after a cooldown period, potentially incentivized off-chain.
     * @param essenceId The ID of the Essence to check for decay.
     */
    function triggerDecay(uint256 essenceId)
        public
        essenceExists(essenceId)
        notStaked(essenceId) // Staked essences don't decay this way
    {
        EssenceDetails storage essence = s_essenceDetails[essenceId];
        uint256 decayCooldown = s_config[keccak256("DECAY_COOLDOWN_SECONDS")];

        // Calculate time since last interaction
        uint256 timeSinceLastInteraction = block.timestamp - essence.lastInteracted;

        if (timeSinceLastInteraction < decayCooldown) {
             revert QuantumForge__DecayCooldownActive(decayCooldown - timeSinceLastInteraction);
        }

        // Apply decay effect
        uint256 timeSubjectToDecay = timeSinceLastInteraction - decayCooldown; // Only decay after cooldown
        uint256 decayRate = s_config[keccak256("DECAY_RATE_PER_SECOND")];
        uint256 decayAmount = timeSubjectToDecay * decayRate / 1e18; // Scale based on config decimals

        uint8 purityLoss = uint8(Math.min(decayAmount, uint256(essence.purity))); // Don't go below 0
        uint8 instabilityGain = uint8(Math.min(decayAmount, uint256(100 - essence.instability))); // Don't go above 100

        essence.purity = uint8(Math.max(int16(essence.purity) - purityLoss, 0));
        essence.instability = uint8(Math.min(essence.instability + instabilityGain, 100));

        // Do NOT update lastInteracted here, decay should not reset the timer.
        // The next *active* interaction (forge, stake, link, extract) resets it.

        emit EssenceDecayed(essenceId, purityLoss, instabilityGain);
    }


    /**
     * @dev Allows sacrificing Purity/Instability from an Essence to gain Aether Dust.
     * @param essenceId The ID of the Essence.
     * @param dustAmount The amount of Aether Dust to extract.
     */
    function extractAetherDust(uint256 essenceId, uint256 dustAmount)
        public
        isEssenceOwner(essenceId)
        essenceExists(essenceId)
        notStaked(essenceId)
    {
        if (dustAmount == 0) revert ExtractionAmountInvalid();

        EssenceDetails storage essence = s_essenceDetails[essenceId];
        uint256 purityCostPerDust = s_config[keccak256("EXTRACTION_PURITY_COST_PER_DUST")];
        uint256 requiredPurity = dustAmount * purityCostPerDust;

        // Decide logic: does it cost Purity, Instability, or both? Let's say it costs Purity primarily.
        // Can add complexity: costs purity if purity > X, costs instability if instability > Y, etc.
        uint8 purityToSacrifice = uint8(Math.min(requiredPurity, uint256(essence.purity)));
        // If requiredPurity is high, you can't extract full amount if you don't have enough purity.
        // Re-calculate extractable dust based on available purity
        uint256 extractableDust = uint256(essence.purity) / purityCostPerDust;
        require(dustAmount <= extractableDust, "QF: Insufficient Purity for extraction");

        essence.purity = uint8(Math.max(int16(essence.purity) - purityToSacrifice, 0));

        // Mint the dust
        _mint(msg.sender, dustAmount); // ERC20 mint

        _updateEssenceLastInteracted(essenceId);

        emit AetherDustExtracted(essenceId, msg.sender, dustAmount, purityToSacrifice, 0); // Assuming 0 instability sacrificed for now
    }

    /**
     * @dev Links two Essence NFTs together. Requires both to be owned by the caller
     * and unlinked.
     * @param essenceId1 The ID of the first Essence.
     * @param essenceId2 The ID of the second Essence.
     */
    function linkEssences(uint256 essenceId1, uint256 essenceId2)
        public
        essenceExists(essenceId1)
        essenceExists(essenceId2)
        isEssenceOwner(essenceId1)
        isEssenceOwner(essenceId2)
        notStaked(essenceId1)
        notStaked(essenceId2)
        notLinked(essenceId1)
        notLinked(essenceId2)
    {
        if (essenceId1 == essenceId2) revert CannotLinkToSelf();
        // Decide if linking requires same owner - currently does via isEssenceOwner modifier

        s_essenceDetails[essenceId1].linkedEssenceId = essenceId2;
        s_essenceDetails[essenceId2].linkedEssenceId = essenceId1;

        _updateEssenceLastInteracted(essenceId1);
        _updateEssenceLastInteracted(essenceId2); // Linking counts as interaction

        emit EssencesLinked(essenceId1, essenceId2, msg.sender);
    }

     /**
     * @dev Breaks the link for a specific Essence and its linked partner.
     * Requires the caller to own the specified Essence.
     * @param essenceId The ID of the Essence to unlink.
     */
    function unlinkEssence(uint256 essenceId)
        public
        essenceExists(essenceId)
        isEssenceOwner(essenceId)
        isLinked(essenceId)
        notStaked(essenceId) // Cannot unlink staked essences
    {
        EssenceDetails storage essence = s_essenceDetails[essenceId];
        uint256 linkedId = essence.linkedEssenceId;
        require(essenceExists(linkedId), "QF: Linked essence does not exist"); // Should not happen

        // Check cooldown (optional)
        // uint256 linkCooldown = s_config[keccak256("LINK_COOLDOWN_SECONDS")];
        // if (block.timestamp < essence.lastInteracted + linkCooldown) { ... require(...) }

        essence.linkedEssenceId = 0;
        s_essenceDetails[linkedId].linkedEssenceId = 0; // Break the link on the partner too

        _updateEssenceLastInteracted(essenceId);
        _updateEssenceLastInteracted(linkedId); // Unlinking counts as interaction for both

        emit EssenceUnlinked(essenceId, linkedId, msg.sender);
    }

    // --- Configuration & Utility ---

    /**
     * @dev Owner function to add a new forging recipe.
     * @param recipeId Unique ID for the recipe.
     * @param requiredDust Aether Dust consumed by the recipe attempt.
     * @param inputs Array of required ERC-1155 components.
     * @param outcomes Array of possible results with weights and effects.
     */
    function addForgingRecipe(uint256 recipeId, uint256 requiredDust, ForgingInput[] memory inputs, ForgingOutcome[] memory outcomes)
        public
        onlyOwner
    {
        // Basic validation
        require(recipeId != 0, "QF: Recipe ID must be non-zero");
        require(s_forgingRecipes[recipeId].requiredDust == 0, "QF: Recipe ID already exists"); // Check if ID is unused
        require(outcomes.length > 0, "QF: Recipe must have outcomes");

        // Calculate total weight to validate outcomes
        uint256 totalWeight = 0;
        for(uint i=0; i<outcomes.length; i++) {
            totalWeight += outcomes[i].probability;
        }
        require(totalWeight > 0, "QF: Total outcome probability must be greater than 0");

        s_forgingRecipes[recipeId] = ForgingRecipe({
            requiredDust: requiredDust,
            inputs: inputs,
            outcomes: outcomes
        });
        s_recipeCount++; // Increment recipe counter (useful for enumeration)

        emit ForgingRecipeAdded(recipeId);
    }

    /**
     * @dev Owner function to remove or deactivate a forging recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeForgingRecipe(uint256 recipeId)
        public
        onlyOwner
    {
        require(s_forgingRecipes[recipeId].requiredDust != 0 || s_forgingRecipes[recipeId].inputs.length > 0 || s_forgingRecipes[recipeId].outcomes.length > 0, "QF: Recipe does not exist");
        delete s_forgingRecipes[recipeId];
        s_recipeCount--; // Decrement counter

        emit ForgingRecipeRemoved(recipeId);
    }

    /**
     * @dev Owner function to set various configuration parameters.
     * Uses keccak256 hash of the key name as the mapping key.
     * Example: setConfiguration("DECAY_RATE_PER_SECOND", 1e16)
     * @param key String name of the configuration parameter.
     * @param value The uint256 value to set.
     */
    function setConfiguration(string memory key, uint256 value) public onlyOwner {
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        s_config[keyHash] = value;
        emit ConfigurationUpdated(keyHash, value);
    }

    /**
     * @dev Requests randomness from Chainlink VRF V2.
     * Called internally by forgeEssence.
     */
    function requestRandomWords() internal returns (uint256 requestId) {
        // Will revert if subscription is not funded or other VRF issues
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Number of random words - we only need 1 for simple outcome selection
        );
        s_vrfRequestCounter++;
        return requestId;
    }

    /**
     * @dev Owner function to withdraw ETH or any ERC20 token from the contract.
     * Useful for retrieving accidentally sent tokens or VRF LINK balance.
     * @param tokenAddress Address of the token (0 for ETH).
     * @param amount Amount to withdraw.
     */
    function withdrawFunds(address tokenAddress, uint256 amount) public onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "QF: ETH withdrawal failed");
        } else {
            // Withdraw ERC20
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(msg.sender, amount), "QF: ERC20 withdrawal failed");
        }
    }

     /**
     * @dev Owner function to mint Aether Dust (ERC-20).
     * @param account The address to mint to.
     * @param amount The amount of Dust to mint.
     */
    function mintAetherDust(address account, uint256 amount) public onlyOwner {
        _mint(account, amount); // ERC20 mint
        emit ComponentsMinted(account, 0, amount); // Use 0 or special ID for Dust if desired
    }

    /**
     * @dev Owner function to burn Aether Dust (ERC-20).
     * @param account The address to burn from.
     * @param amount The amount of Dust to burn.
     */
    function burnAetherDust(address account, uint256 amount) public onlyOwner {
         _burn(account, amount); // ERC20 burn
         emit ComponentsBurned(account, 0, amount); // Use 0 or special ID for Dust
    }


    /**
     * @dev Owner function to mint Components (ERC-1155).
     * @param account The address to mint to.
     * @param typeId The type ID of the component.
     * @param amount The amount of components to mint.
     */
    function mintComponents(address account, uint256 typeId, uint256 amount) public onlyOwner {
        _mint(account, typeId, amount, ""); // ERC1155 mint
        emit ComponentsMinted(account, typeId, amount);
    }

     /**
     * @dev Owner function to burn Components (ERC-1155).
     * @param account The address to burn from.
     * @param typeId The type ID of the component.
     * @param amount The amount of components to burn.
     */
    function burnComponents(address account, uint256 typeId, uint256 amount) public onlyOwner {
        _burn(account, typeId, amount); // ERC1155 burn
        emit ComponentsBurned(account, typeId, amount);
    }


    // --- View Functions ---

    /**
     * @dev Gets the detailed mutable properties of an Essence NFT.
     * Includes calculated current Purity/Instability and staking/linking info.
     * @param essenceId The ID of the Essence.
     * @return EssenceDetails struct. Note: purity and instability are shown as *current* calculated values.
     */
    function getEssenceDetails(uint256 essenceId)
        public
        view
        essenceExists(essenceId)
        returns (EssenceDetails memory)
    {
         // Need to create a temporary struct to return calculated values
        EssenceDetails storage stored = s_essenceDetails[essenceId];
        EssenceDetails memory current = stored;

        // Apply transient effects for view
        uint256 purity = stored.purity;
        uint256 instability = stored.instability;

        if (s_stakedEssences[essenceId].stakeStartTime > 0) {
            // Calculate purification effect if staked
            uint256 timeStaked = block.timestamp - s_stakedEssences[essenceId].stakeStartTime;
            uint256 purifyRate = s_config[keccak256("PURIFY_RATE_PER_SECOND")];
            uint256 netPurification = timeStaked * purifyRate / 1e18;
            purity = Math.min(purity + netPurification, 100);
            instability = Math.max(instability - netPurification, 0);
        } else {
             // Calculate decay effect if not staked
            uint256 decayCooldown = s_config[keccak256("DECAY_COOLDOWN_SECONDS")];
            uint256 timeSinceLastInteraction = block.timestamp - stored.lastInteracted;
            if (timeSinceLastInteraction > decayCooldown) {
                uint256 timeSubjectToDecay = timeSinceLastInteraction - decayCooldown;
                uint256 decayRate = s_config[keccak256("DECAY_RATE_PER_SECOND")];
                uint256 decayAmount = timeSubjectToDecay * decayRate / 1e18;
                purity = Math.max(purity - decayAmount, 0);
                instability = Math.min(instability + decayAmount, 100);
            }
        }

        current.purity = uint8(purity);
        current.instability = uint8(instability);

        return current;
    }

    /**
     * @dev Gets staking-specific details for an Essence.
     * @param essenceId The ID of the Essence.
     * @return StakingDetails struct.
     */
    function getEssenceStakingDetails(uint256 essenceId)
        public
        view
        essenceExists(essenceId)
        returns (StakingDetails memory)
    {
        return s_stakedEssences[essenceId];
    }

    /**
     * @dev Gets the details of a specific forging recipe.
     * @param recipeId The ID of the recipe.
     * @return ForgingRecipe struct.
     */
    function getRecipeDetails(uint256 recipeId) public view returns (ForgingRecipe memory) {
         ForgingRecipe storage recipe = s_forgingRecipes[recipeId];
         require(recipe.requiredDust > 0 || recipe.inputs.length > 0 || recipe.outcomes.length > 0, "QF: Recipe does not exist");
         return recipe;
    }


    /**
     * @dev Calculates the current Purity of an Essence including transient effects (purification/decay).
     * @param essenceId The ID of the Essence.
     * @return The calculated current Purity (0-100).
     */
    function calculateCurrentPurity(uint256 essenceId) public view essenceExists(essenceId) returns (uint8) {
        EssenceDetails storage stored = s_essenceDetails[essenceId];
        uint26 purity = stored.purity;

         if (s_stakedEssences[essenceId].stakeStartTime > 0) {
            uint256 timeStaked = block.timestamp - s_stakedEssences[essenceId].stakeStartTime;
            uint256 purifyRate = s_config[keccak256("PURIFY_RATE_PER_SECOND")];
            uint256 netPurification = timeStaked * purifyRate / 1e18;
            purity = Math.min(purity + netPurification, 100);
         } else {
            uint256 decayCooldown = s_config[keccak256("DECAY_COOLDOWN_SECONDS")];
            uint256 timeSinceLastInteraction = block.timestamp - stored.lastInteracted;
             if (timeSinceLastInteraction > decayCooldown) {
                uint256 timeSubjectToDecay = timeSinceLastInteraction - decayCooldown;
                uint256 decayRate = s_config[keccak256("DECAY_RATE_PER_SECOND")];
                uint256 decayAmount = timeSubjectToDecay * decayRate / 1e18;
                purity = Math.max(purity - decayAmount, 0);
            }
         }
         return uint8(purity);
    }

    /**
     * @dev Calculates the current Instability of an Essence including transient effects (purification/decay).
     * @param essenceId The ID of the Essence.
     * @return The calculated current Instability (0-100).
     */
     function calculateCurrentInstability(uint256 essenceId) public view essenceExists(essenceId) returns (uint8) {
        EssenceDetails storage stored = s_essenceDetails[essenceId];
        uint256 instability = stored.instability;

         if (s_stakedEssences[essenceId].stakeStartTime > 0) {
            uint256 timeStaked = block.timestamp - s_stakedEssences[essenceId].stakeStartTime;
            uint256 purifyRate = s_config[keccak256("PURIFY_RATE_PER_SECOND")];
            uint256 netPurification = timeStaked * purifyRate / 1e18;
            instability = Math.max(instability - netPurification, 0);
         } else {
            uint256 decayCooldown = s_config[keccak256("DECAY_COOLDOWN_SECONDS")];
            uint256 timeSinceLastInteraction = block.timestamp - stored.lastInteracted;
             if (timeSinceLastInteraction > decayCooldown) {
                uint256 timeSubjectToDecay = timeSinceLastInteraction - decayCooldown;
                uint256 decayRate = s_config[keccak256("DECAY_RATE_PER_SECOND")];
                uint256 decayAmount = timeSubjectToDecay * decayRate / 1e18;
                instability = Math.min(instability + decayAmount, 100);
            }
         }
         return uint8(instability);
     }


    /**
     * @dev Calculates the amount of Aether Dust accrued for a staked Essence.
     * @param essenceId The ID of the Essence.
     * @return The amount of Dust accrued.
     */
    function calculateStakingDustAccrued(uint256 essenceId) public view essenceExists(essenceId) returns (uint256) {
        StakingDetails storage stakingDetails = s_stakedEssences[essenceId];
        if (stakingDetails.stakeStartTime == 0) return 0;

        uint256 timeStaked = block.timestamp - stakingDetails.stakeStartTime;
        uint256 dustRate = s_config[keccak256("STAKING_DUST_RATE_PER_SECOND")];
        uint256 dustAccrued = stakingDetails.dustAccumulated + (timeStaked * dustRate / 1e18);
        return dustAccrued;
    }

    /**
     * @dev Checks if an Essence NFT has a specific trait (basic implementation).
     * Note: This assumes traits are stored in a simple way in the bytes array.
     * A real implementation would need a structured way to store/query traits.
     * @param essenceId The ID of the Essence.
     * @param traitName The name of the trait to check for (e.g., "FireAffinity").
     * @return True if the Essence has the trait, false otherwise.
     */
    function getTrait(uint256 essenceId, string memory traitName) public view essenceExists(essenceId) returns (bool) {
        // !!! WARNING: This is a highly simplified example.
        // Real trait management in bytes is complex.
        // This function just checks if the traitName string exists as a substring in the bytes.
        bytes memory traitBytes = s_essenceDetails[essenceId].traits;
        bytes memory nameBytes = bytes(traitName);

        // This substring search is not efficient or standard for traits.
        // It's included to fulfill the function count and idea, but needs replacement.
        if (traitBytes.length < nameBytes.length) return false;
        if (nameBytes.length == 0) return false;

        for (uint i = 0; i <= traitBytes.length - nameBytes.length; i++) {
            bool match = true;
            for (uint j = 0; j < nameBytes.length; j++) {
                if (traitBytes[i + j] != nameBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) return true;
        }
        return false;
    }

    /**
     * @dev Checks if an Essence is currently linked to another.
     * @param essenceId The ID of the Essence.
     * @return True if linked, false otherwise.
     */
    function isEssenceLinked(uint256 essenceId) public view essenceExists(essenceId) returns (bool) {
        return s_essenceDetails[essenceId].linkedEssenceId != 0;
    }

    /**
     * @dev Gets the ID of the Essence linked to the specified one.
     * @param essenceId The ID of the Essence.
     * @return The linked Essence ID, or 0 if not linked.
     */
    function getLinkedEssence(uint256 essenceId) public view essenceExists(essenceId) returns (uint256) {
        return s_essenceDetails[essenceId].linkedEssenceId;
    }

    /**
     * @dev Gets the total number of Quantum Essence NFTs minted.
     * @return Total minted count.
     */
    function getTotalEssencesMinted() public view returns (uint256) {
        return s_nextTokenId; // ERC721Enumerable.totalSupply() also works
    }

    /**
     * @dev Gets the status of a VRF request (not implemented, placeholder).
     * A real implementation would need a mapping to store request status/fulfillment.
     * @param requestId The ID of the VRF request.
     * @return Placeholder boolean (always false in this version).
     */
    function getVRFRequestStatus(uint256 requestId) public view returns (bool fulfilled) {
         // This requires storing fulfillment status which adds complexity.
         // For this example, we'll just check if the mapping was cleared.
         return s_requestIdToEssenceId[requestId] == 0 && s_requestIdToRecipeId[requestId] == 0 && requestId > 0 && s_vrfRequestCounter >= requestId; // Basic heuristic
    }


    /**
     * @dev Get the Aether Dust balance for an account.
     * @param account The account address.
     * @return The balance.
     */
    function getAetherDustBalance(address account) public view returns (uint256) {
        return balanceOf(account); // ERC20 balanceOf
    }

    /**
     * @dev Get the Component balance for an account and component type.
     * @param account The account address.
     * @param typeId The ERC-1155 component type ID.
     * @return The balance.
     */
    function getComponentBalance(address account, uint256 typeId) public view returns (uint256) {
        return balanceOf(account, typeId); // ERC1155 balanceOf
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal helper to update the lastInteracted timestamp for an Essence.
     * Called by any function that constitutes a significant interaction.
     * @param essenceId The ID of the Essence.
     */
    function _updateEssenceLastInteracted(uint256 essenceId) internal essenceExists(essenceId) {
         s_essenceDetails[essenceId].lastInteracted = uint40(block.timestamp);
    }

    /**
     * @dev Internal helper to calculate and apply decay if overdue.
     * Called by functions like stake or manual triggerDecay.
     * @param essenceId The ID of the Essence.
     */
    function _applyDecayIfDue(uint256 essenceId) internal essenceExists(essenceId) notStaked(essenceId) {
        EssenceDetails storage essence = s_essenceDetails[essenceId];
        uint256 decayCooldown = s_config[keccak256("DECAY_COOLDOWN_SECONDS")];
        uint256 timeSinceLastInteraction = block.timestamp - essence.lastInteracted;

        if (timeSinceLastInteraction > decayCooldown) {
            uint256 timeSubjectToDecay = timeSinceLastInteraction - decayCooldown;
            uint256 decayRate = s_config[keccak256("DECAY_RATE_PER_SECOND")];
            uint256 decayAmount = timeSubjectToDecay * decayRate / 1e18; // Scale based on config decimals

            uint8 purityLoss = uint8(Math.min(decayAmount, uint256(essence.purity)));
            uint8 instabilityGain = uint8(Math.min(decayAmount, uint256(100 - essence.instability)));

            essence.purity = uint8(Math.max(int16(essence.purity) - purityLoss, 0));
            essence.instability = uint8(Math.min(essence.instability + instabilityGain, 100));

            emit EssenceDecayed(essenceId, purityLoss, instabilityGain);
            // LastInteracted is updated by the calling function (stake, etc.)
        }
    }

    // Required ERC1155 functions
    function uri(uint256) public pure override returns (string memory) {
        // Placeholder URI for components. A real system needs a proper URI resolver.
        return "https://example.com/components/{id}";
    }


    // Basic Math library needed for min/max and potentially other operations
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(int16 a, int16 b) internal pure returns (int16) {
            return a >= b ? a : b;
        }
        function min(int16 a, int16 b) internal pure returns (int16) {
            return a < b ? a : b;
        }
    }

    // Fallback function to receive ETH (e.g., for VRF LINK top-up)
    receive() external payable {}
    fallback() external payable {}
}
```