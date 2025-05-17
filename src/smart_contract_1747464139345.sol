Okay, let's design a smart contract that incorporates several advanced and creative concepts beyond standard token contracts or simple vaults. We'll create a system for "Ethereal Forge" – a place where users can craft dynamic NFTs (Relics) using a fungible token (Essence) and accrue non-transferable reputation (Aura), influenced potentially by external factors via an oracle simulation.

This contract will combine:
1.  **Fungible Token (Essence):** An ERC-20 like token for crafting costs.
2.  **Dynamic NFTs (Relics):** ERC-721 tokens with properties stored on-chain that can change.
3.  **Soulbound Reputation (Aura):** A non-transferable score linked to an address, earned through interaction.
4.  **On-Chain Crafting System:** Define recipes for consuming inputs (Essence, Relics) and producing outputs (Essence, Relics), with logic influenced by Aura or Relic properties.
5.  **Dynamic NFT Properties:** Mechanisms to update Relic properties over time or via actions.
6.  **Oracle Simulation:** A pattern for requesting and fulfilling external data (like randomness) to influence outcomes.
7.  **Tiered Access/Blessed Status:** A simple system to grant special privileges (like access to certain recipes).
8.  **Meta-features:** Functions to manage recipes, oracle address, etc.

We will build upon standard interfaces like ERC-20 and ERC-721 but implement unique logic on top.

---

**Contract Outline: EtherealForge**

*   **ERC-20 Implementation (Essence):** Basic fungible token functionalities (minting, burning, transfer, allowance).
*   **ERC-721 Implementation (Relics):** Basic NFT functionalities (minting, burning, ownership tracking, approval, token URI).
*   **Relic Properties:** Struct and mapping to store dynamic data for each Relic token ID.
*   **Aura:** Mapping to store non-transferable reputation per address.
*   **Crafting System:**
    *   Structs for defining crafting inputs, outputs, and recipes.
    *   Mapping to store defined recipes.
    *   Function to add/remove recipes (owner).
    *   Function for users to execute crafting recipes (consuming inputs, producing outputs, gaining Aura).
*   **Relic Dynamics:**
    *   Functions to update specific Relic properties (e.g., charging, simulating decay, blessing).
    *   Custom `tokenURI` to reflect dynamic properties.
*   **Oracle Integration (Simulated):**
    *   Address for the simulated oracle.
    *   Functions to request randomness (linked to a target, e.g., a Relic) and fulfill randomness (only by oracle).
    *   Mapping to track randomness requests and their targets.
*   **Blessed Crafters:**
    *   Mapping to track addresses with blessed status.
    *   Functions to add/remove blessed crafters (owner).
*   **Utility & Management:**
    *   Functions to retrieve various data (balances, properties, recipes, Aura).
    *   Withdrawal function for owner.
    *   Counters for token IDs and recipe IDs.

---

**Function Summary:**

**ERC-20 (Essence):**
1.  `mintEssence(address to, uint256 amount)`: Mints new Essence tokens to an address (Owner only).
2.  `burnEssence(uint256 amount)`: Burns a specified amount of Essence tokens from the caller's balance.
3.  `transfer(address to, uint256 amount)`: Transfers Essence tokens (inherited ERC-20).
4.  `approve(address spender, uint256 amount)`: Approves a spender for Essence (inherited ERC-20).
5.  `transferFrom(address from, address to, uint256 amount)`: Transfers Essence using allowance (inherited ERC-20).
6.  `balanceOf(address account)`: Gets Essence balance (inherited ERC-20).
7.  `allowance(address owner, address spender)`: Gets Essence allowance (inherited ERC-20).
8.  `totalSupply()`: Gets total Essence supply (inherited ERC-20).

**ERC-721 (Relics):**
9.  `mintRelic(address to, uint8 initialPower, uint8 initialRarity, string memory initialTrait)`: Mints a new Relic NFT to an address with initial properties (Owner only).
10. `burnRelic(uint256 tokenId)`: Burns a Relic token (Owner or approved).
11. `getRelicProperties(uint256 tokenId)`: Retrieves the dynamic properties of a Relic. (View)
12. `updateRelicTrait(uint256 tokenId, string memory newTrait)`: Allows owner/oracle to update a Relic's dynamic trait.
13. `chargeRelic(uint256 tokenId, uint256 essenceCost)`: Allows the owner of a Relic to spend Essence to make the Relic "charged".
14. `decayRelicPower(uint256 tokenId)`: Simulates the decay of a Relic's power based on time since last charge/creation (Callable by owner/oracle).
15. `blessRelic(uint256 tokenId, uint8 powerBoost)`: Owner can bless a Relic, boosting its power.
16. `tokenURI(uint256 tokenId)`: Generates a dynamic metadata URI for a Relic reflecting its current state. (View)
17. `balanceOf(address owner)`: Gets number of Relics owned (inherited ERC-721).
18. `ownerOf(uint256 tokenId)`: Gets owner of a Relic (inherited ERC-721).
19. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a Relic (inherited ERC-721).
20. `approve(address to, uint256 tokenId)`: Approves an address for a Relic (inherited ERC-721).

**Aura:**
21. `getAura(address user)`: Gets the Aura score for a user. (View)

**Crafting System:**
22. `addRecipe(CraftingRecipe memory recipe)`: Adds a new crafting recipe (Owner only). Returns the new recipe ID.
23. `removeRecipe(uint8 recipeId)`: Removes a crafting recipe (Owner only).
24. `craft(uint8 recipeId, CraftingInput[] memory actualInputs)`: Executes a crafting recipe. Requires specific inputs (Essence/Relics), sufficient Aura, and potentially blessed status. Consumes inputs, produces outputs, grants Aura.
25. `getRecipe(uint8 recipeId)`: Retrieves the details of a crafting recipe. (View)
26. `getRecipeCount()`: Gets the total number of recipes added. (View)

**Oracle Integration (Simulated):**
27. `setOracleAddress(address newOracle)`: Sets the address of the simulated oracle (Owner only).
28. `requestRandomness(uint256 tokenId)`: Records a request for randomness associated with a specific Relic (Any user). Returns request ID.
29. `fulfillRandomness(uint256 requestId, uint256 randomness)`: Called by the oracle address to provide randomness. Can trigger a dynamic update on the associated Relic.

**Blessed Crafters:**
30. `addBlessedCrafter(address crafter)`: Adds an address to the blessed crafters list (Owner only).
31. `removeBlessedCrafter(address crafter)`: Removes an address from the blessed crafters list (Owner only).
32. `isBlessedCrafter(address crafter)`: Checks if an address is a blessed crafter. (View)

**Utility & Management:**
33. `withdrawEther()`: Allows the owner to withdraw any Ether sent to the contract. (Owner only)
34. `tokenName()`: Gets the name of the Essence token. (View)
35. `tokenSymbol()`: Gets the symbol of the Essence token. (View)
36. `relicName()`: Gets the name of the Relic token. (View)
37. `relicSymbol()`: Gets the symbol of the Relic token. (View)
38. `getRelicCount()`: Gets the total number of Relics minted. (View - using the internal counter)

This gives us well over the required 20 distinct functions/public views with logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic tokenURI metadata

// Custom Errors for clarity
error EtherealForge__NotOwnerOrApproved();
error EtherealForge__InsufficientAura(uint256 required, uint256 current);
error EtherealForge__NotBlessedCrafter();
error EtherealForge__InvalidInputCount();
error EtherealForge__InvalidInputItem(uint8 expectedType, uint8 actualType);
error EtherealForge__InsufficientEssenceInput(uint256 required, uint256 current);
error EtherealForge__IncorrectRelicInput(uint256 requiredTokenId, uint256 actualTokenId);
error EtherealForge__RelicNotOwnedByCrafter(uint256 tokenId);
error EtherealForge__RelicInputNotApproved(uint256 tokenId);
error EtherealForge__RecipeNotFound(uint8 recipeId);
error EtherealForge__OracleNotSet();
error EtherealForge__NotOracle();
error EtherealForge__RandomRequestNotFound(uint256 requestId);
error EtherealForge__RelicAlreadyCharged();
error EtherealForge__RelicNotOwned(uint256 tokenId);
error EtherealForge__CannotRemoveNonExistentRecipe();
error EtherealForge__EtherTransferFailed();


/**
 * @title EtherealForge
 * @dev An advanced smart contract combining ERC-20, Dynamic ERC-721, Soulbound Reputation,
 *      On-chain Crafting, Oracle Simulation, and Tiered Access.
 *
 * Contract Outline:
 * - ERC-20 Implementation (Essence): Fungible token for crafting costs.
 * - ERC-721 Implementation (Relics): Dynamic NFTs with on-chain properties.
 * - Aura: Non-transferable reputation score linked to addresses.
 * - Crafting System: Define and execute recipes to transform tokens, influenced by Aura/status.
 * - Relic Dynamics: Functions to change NFT properties over time or via actions.
 * - Oracle Simulation: Pattern for external data interaction influencing outcomes.
 * - Blessed Crafters: Tiered access for special recipes.
 * - Utility & Management: Getters, setters, and withdrawal.
 */
contract EtherealForge is ERC20, ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ERC721 (Relics) Counter
    Counters.Counter private _relicTokenIdCounter;

    // Relic Dynamic Properties
    struct RelicProperties {
        uint256 creationTime;
        uint8 power;
        uint8 rarity; // 0-100 scale
        bool isCharged;
        uint256 lastChargedTime; // Timestamp of last charge
        string dynamicTrait;
    }
    mapping(uint256 => RelicProperties) public relicData;

    // Aura (Soulbound Reputation)
    mapping(address => uint256) public userAura;

    // Crafting System
    struct CraftingInput {
        uint8 inputType; // 0: Essence, 1: Relic
        uint256 amountOrTokenId; // Amount for Essence, specific Token ID for Relic
    }
    struct CraftingOutput {
        uint8 outputType; // 0: Essence, 1: Relic
        uint256 amountOrTokenIdHint; // Amount for Essence, hint for Relic properties (e.g., base power/rarity)
        uint8 outputPowerHint;
        uint8 outputRarityHint;
        string outputTraitHint;
    }
    struct CraftingRecipe {
        CraftingInput[] inputs;
        CraftingOutput[] outputs;
        uint256 requiredAura;
        address requiredCrafter; // 0x0 for anyone, owner(), specific address
        bool requiresBlessed; // Whether a blessed crafter is required
    }
    mapping(uint8 => CraftingRecipe) public recipes;
    uint8 public nextRecipeId;

    // Oracle Simulation
    address public oracleAddress;
    Counters.Counter private _randomRequestIdCounter;
    mapping(uint256 => address) public randomRequestSender; // Maps request ID to the address that made the request
    mapping(uint256 => uint256) public randomRequestTargetToken; // Maps request ID to a target token ID (if applicable)

    // Blessed Crafters
    mapping(address => bool) public isBlessedCrafter;

    // Constants
    uint256 private constant POWER_DECAY_INTERVAL = 30 days; // Decay power every 30 days

    // --- Events ---
    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event RelicMinted(address indexed to, uint256 indexed tokenId, uint8 power, uint8 rarity, string initialTrait);
    event RelicBurned(uint256 indexed tokenId);
    event AuraGained(address indexed user, uint256 amount);
    event RelicTraitUpdated(uint256 indexed tokenId, string newTrait);
    event RelicCharged(uint256 indexed tokenId, uint256 essenceCost);
    event RelicPowerDecayed(uint256 indexed tokenId, uint8 oldPower, uint8 newPower);
    event RelicBlessed(uint256 indexed tokenId, uint8 powerBoost);
    event RecipeAdded(uint8 indexed recipeId, address indexed owner);
    event RecipeRemoved(uint8 indexed recipeId);
    event Crafted(uint8 indexed recipeId, address indexed crafter);
    event RandomnessRequested(uint256 indexed requestId, address indexed sender, uint256 indexed targetTokenId);
    event RandomnessFulfilled(uint256 indexed requestId, uint256 randomness);
    event BlessedCrafterAdded(address indexed crafter);
    event BlessedCrafterRemoved(address indexed crafter);

    // --- Constructor ---
    constructor(string memory essenceName, string memory essenceSymbol, string memory relicName, string memory relicSymbol)
        ERC20(essenceName, essenceSymbol)
        ERC721(relicName, relicSymbol)
        Ownable(msg.sender)
    {
        _relicTokenIdCounter.increment(); // Start token IDs from 1
        nextRecipeId = 1; // Start recipe IDs from 1
    }

    // --- Modifier ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert EtherealForge__NotOracle();
        }
        _;
    }

    // --- ERC20 (Essence) Functions ---

    /**
     * @dev Mints new Essence tokens. Only callable by the contract owner.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mintEssence(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit EssenceMinted(to, amount);
    }

    /**
     * @dev Burns Essence tokens from the caller's balance.
     * @param amount The amount of tokens to burn.
     */
    function burnEssence(uint256 amount) external {
        _burn(msg.sender, amount);
        emit EssenceBurned(msg.sender, amount);
    }

    // Inherited ERC-20 functions: transfer, approve, transferFrom, balanceOf, allowance, totalSupply

    // --- ERC721 (Relics) Functions ---

    /**
     * @dev Mints a new Relic NFT. Only callable by the contract owner.
     * Sets initial dynamic properties.
     * @param to The address to mint the Relic to.
     * @param initialPower The initial power level of the Relic.
     * @param initialRarity The initial rarity score of the Relic (0-100).
     * @param initialTrait The initial dynamic trait string.
     */
    function mintRelic(address to, uint8 initialPower, uint8 initialRarity, string memory initialTrait) external onlyOwner {
        uint256 tokenId = _relicTokenIdCounter.current();
        _relicTokenIdCounter.increment();

        _safeMint(to, tokenId);

        relicData[tokenId] = RelicProperties({
            creationTime: block.timestamp,
            power: initialPower,
            rarity: initialRarity,
            isCharged: false,
            lastChargedTime: block.timestamp, // Set initial charge time
            dynamicTrait: initialTrait
        });

        emit RelicMinted(to, tokenId, initialPower, initialRarity, initialTrait);
    }

    /**
     * @dev Burns a Relic NFT. Callable by the owner of the Relic or an approved address.
     * Clears the associated dynamic properties.
     * @param tokenId The token ID of the Relic to burn.
     */
    function burnRelic(uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert EtherealForge__NotOwnerOrApproved();
        }

        _burn(tokenId);
        delete relicData[tokenId]; // Clean up dynamic data

        emit RelicBurned(tokenId);
    }

    /**
     * @dev Retrieves the dynamic properties of a specific Relic.
     * @param tokenId The token ID of the Relic.
     * @return RelicProperties The struct containing the Relic's dynamic data.
     */
    function getRelicProperties(uint256 tokenId) public view returns (RelicProperties memory) {
        // ERC721 standard functions (like ownerOf) will revert if token doesn't exist.
        // No need for explicit existence check based on relicData mapping alone.
        return relicData[tokenId];
    }

    /**
     * @dev Allows the owner or oracle to update a Relic's dynamic trait.
     * Can be triggered by oracle fulfillment or owner action.
     * @param tokenId The token ID of the Relic.
     * @param newTrait The new string for the dynamic trait.
     */
    function updateRelicTrait(uint256 tokenId, string memory newTrait) external {
        if (msg.sender != owner() && msg.sender != oracleAddress) {
             revert EtherealForge__NotOwnerOrApproved(); // Using this error broadly for non-owner/non-oracle access
        }
        // Check if token exists implicitly via ownerOf if needed, or rely on future calls
        // that might use this data. For simplicity here, assume it exists.

        relicData[tokenId].dynamicTrait = newTrait;
        emit RelicTraitUpdated(tokenId, newTrait);
    }

    /**
     * @dev Allows the owner of a Relic to spend Essence to make it 'Charged'.
     * Charging resets the decay timer.
     * @param tokenId The token ID of the Relic.
     * @param essenceCost The amount of Essence required to charge the Relic.
     */
    function chargeRelic(uint256 tokenId, uint256 essenceCost) external {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner) {
            revert EtherealForge__RelicNotOwned(tokenId);
        }
        if (relicData[tokenId].isCharged) {
            revert EtherealForge__RelicAlreadyCharged();
        }

        // Use transferFrom for safety, requires caller to approve contract first
        require(allowance(msg.sender, address(this)) >= essenceCost, "Insufficient allowance");
        _transfer(msg.sender, address(this), essenceCost); // Transfer to contract, could also burn directly

        relicData[tokenId].isCharged = true;
        relicData[tokenId].lastChargedTime = block.timestamp;
        emit RelicCharged(tokenId, essenceCost);
    }

    /**
     * @dev Simulates the decay of a Relic's power based on time since last charge/creation.
     * Can be called by the owner or oracle. Relic power never decays below 1.
     * @param tokenId The token ID of the Relic.
     */
    function decayRelicPower(uint256 tokenId) external {
        if (msg.sender != owner() && msg.sender != oracleAddress) {
             revert EtherealForge__NotOwnerOrApproved(); // Using this error broadly
        }
        // Check if token exists implicitly via ownerOf if needed

        RelicProperties storage props = relicData[tokenId];
        uint256 timeSinceLastCharge = block.timestamp - props.lastChargedTime;
        uint256 decayPeriods = timeSinceLastCharge / POWER_DECAY_INTERVAL;

        if (decayPeriods > 0 && props.power > 1) {
            uint8 oldPower = props.power;
            // Decay power by the number of periods, ensuring it doesn't go below 1
            props.power = props.power > decayPeriods ? props.power - uint8(decayPeriods) : 1;
            props.lastChargedTime = props.lastChargedTime + decayPeriods * POWER_DECAY_INTERVAL; // Advance last charged time marker
            emit RelicPowerDecayed(tokenId, oldPower, props.power);
        }
        // Note: isCharged status does not automatically reset here,
        // it might require another mechanism or be part of the crafting input check.
    }

    /**
     * @dev Allows the owner to manually bless a Relic, boosting its power.
     * @param tokenId The token ID of the Relic.
     * @param powerBoost The amount to increase the power by.
     */
    function blessRelic(uint256 tokenId, uint8 powerBoost) external onlyOwner {
        // Check if token exists implicitly via ownerOf if needed
        relicData[tokenId].power = relicData[tokenId].power + powerBoost; // Allow overflow, or add checks if needed
        emit RelicBlessed(tokenId, powerBoost);
    }


    /**
     * @dev Generates a dynamic metadata URI for a Relic.
     * This URI reflects the current state of the Relic's on-chain properties.
     * @param tokenId The token ID of the Relic.
     * @return string The base64 encoded JSON metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check if token exists using ERC721's internal logic via ownerOf
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        RelicProperties memory props = relicData[tokenId];

        // Example dynamic metadata JSON
        string memory json = string(abi.encodePacked(
            '{"name": "Ethereal Relic #', Strings.toString(tokenId), '",',
            '"description": "A dynamic relic from the Ethereal Forge.",',
            '"attributes": [',
                '{"trait_type": "Power", "value": ', Strings.toString(props.power), '},',
                '{"trait_type": "Rarity", "value": ', Strings.toString(props.rarity), '},',
                '{"trait_type": "Charged", "value": ', props.isCharged ? '"True"' : '"False"', '},',
                '{"trait_type": "Dynamic Trait", "value": "', props.dynamicTrait, '"}'
            ']}'
            // Could add image based on properties, creation time etc.
        ));

        // Encode JSON as base64
        string memory base64Json = Base64.encode(bytes(json));

        // Return data URI
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    // Inherited ERC-721 functions: balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll

    // --- Aura Functions ---

    /**
     * @dev Gets the Aura score for a user.
     * @param user The address to query Aura for.
     * @return uint256 The Aura score.
     */
    function getAura(address user) public view returns (uint256) {
        return userAura[user];
    }

    /**
     * @dev Internal function to add Aura to a user.
     * @param user The address to grant Aura to.
     * @param amount The amount of Aura to add.
     */
    function _gainAura(address user, uint256 amount) internal {
        userAura[user] += amount;
        emit AuraGained(user, amount);
    }

    // --- Crafting System Functions ---

    /**
     * @dev Adds a new crafting recipe. Only callable by the contract owner.
     * @param recipe The CraftingRecipe struct defining the recipe.
     * @return uint8 The ID of the newly added recipe.
     */
    function addRecipe(CraftingRecipe memory recipe) external onlyOwner returns (uint8) {
        uint8 recipeId = nextRecipeId;
        recipes[recipeId] = recipe;
        nextRecipeId++;
        emit RecipeAdded(recipeId, msg.sender);
        return recipeId;
    }

    /**
     * @dev Removes a crafting recipe. Only callable by the contract owner.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeRecipe(uint8 recipeId) external onlyOwner {
        if (recipeId >= nextRecipeId || recipes[recipeId].inputs.length == 0) {
             revert EtherealForge__CannotRemoveNonExistentRecipe(); // Check if recipe exists
        }
        delete recipes[recipeId];
        emit RecipeRemoved(recipeId);
    }

    /**
     * @dev Executes a crafting recipe.
     * Validates inputs, consumes tokens/NFTs, produces outputs, grants Aura.
     * Requires user approval for ERC-20 and ERC-721 inputs.
     * @param recipeId The ID of the recipe to execute.
     * @param actualInputs An array of actual inputs provided by the crafter.
     */
    function craft(uint8 recipeId, CraftingInput[] memory actualInputs) external {
        CraftingRecipe storage recipe = recipes[recipeId];
        if (recipe.inputs.length == 0) {
            revert EtherealForge__RecipeNotFound(recipeId);
        }

        address crafter = msg.sender;

        // 1. Check Aura requirement
        if (userAura[crafter] < recipe.requiredAura) {
            revert EtherealForge__InsufficientAura(recipe.requiredAura, userAura[crafter]);
        }

        // 2. Check Crafter requirement
        if (recipe.requiredCrafter != address(0) && crafter != recipe.requiredCrafter && (recipe.requiredCrafter != owner() || crafter != owner())) {
            revert EtherealForge__NotBlessedCrafter(); // Using this error loosely for any crafter requirement not met
        }
        if (recipe.requiresBlessed && !isBlessedCrafter[crafter]) {
             revert EtherealForge__NotBlessedCrafter();
        }


        // 3. Validate and Consume Inputs
        if (actualInputs.length != recipe.inputs.length) {
            revert EtherealForge__InvalidInputCount();
        }

        for (uint i = 0; i < recipe.inputs.length; i++) {
            CraftingInput memory required = recipe.inputs[i];
            CraftingInput memory actual = actualInputs[i];

            if (actual.inputType != required.inputType) {
                revert EtherealForge__InvalidInputItem(required.inputType, actual.inputType);
            }

            if (required.inputType == 0) { // Essence Input
                // Check specific amount (optional, could allow more)
                if (actual.amountOrTokenId < required.amountOrTokenId) {
                    revert EtherealForge__InsufficientEssenceInput(required.amountOrTokenId, actual.amountOrTokenId);
                }
                // Consume Essence - Use transferFrom, requires crafter to approve contract
                require(allowance(crafter, address(this)) >= actual.amountOrTokenId, "Insufficient Essence allowance");
                _transfer(crafter, address(this), actual.amountOrTokenId); // Transfer to contract, could also burn
                emit EssenceBurned(crafter, actual.amountOrTokenId); // Or Transferred
            } else if (required.inputType == 1) { // Relic Input
                // Check specific token ID required (optional, recipe could list types instead)
                // Here we require the EXACT token ID specified in the recipe input
                // A more advanced system might check for Relics with minimum properties or traits.
                if (actual.amountOrTokenId != required.amountOrTokenId) {
                     revert EtherealForge__IncorrectRelicInput(required.amountOrTokenId, actual.amountOrTokenId);
                }
                uint256 tokenId = actual.amountOrTokenId;
                // Check ownership and approval - requires crafter to approve contract for the relic
                if (ownerOf(tokenId) != crafter) {
                    revert EtherealForge__RelicNotOwnedByCrafter(tokenId);
                }
                 if (getApproved(tokenId) != address(this) && !isApprovedForAll(crafter, address(this))) {
                    revert EtherealForge__RelicInputNotApproved(tokenId);
                }

                // Consume Relic - Burn it
                _burn(tokenId); // ERC721 burn handles ownership and approval checks implicitly if inheriting standard
                delete relicData[tokenId]; // Clean up dynamic data
                emit RelicBurned(tokenId);
            }
        }

        // 4. Produce Outputs
        for (uint i = 0; i < recipe.outputs.length; i++) {
            CraftingOutput memory output = recipe.outputs[i];
            if (output.outputType == 0) { // Essence Output
                _mint(crafter, output.amountOrTokenIdHint); // Mint Essence to the crafter
                emit EssenceMinted(crafter, output.amountOrTokenIdHint);
            } else if (output.outputType == 1) { // Relic Output
                uint256 newTokenId = _relicTokenIdCounter.current();
                _relicTokenIdCounter.increment();

                // Mint new Relic to the crafter
                _safeMint(crafter, newTokenId);

                // Set properties based on hints and potential dynamic factors
                // Example: Power is hint + (crafter's aura / 100)
                uint8 calculatedPower = output.outputPowerHint + uint8(userAura[crafter] / 100);
                // Example: Rarity is hint + (randomness influencing factor - needs oracle integration)
                uint8 calculatedRarity = output.outputRarityHint; // Placeholder, could use randomness here
                string memory calculatedTrait = output.outputTraitHint; // Placeholder, could be dynamic

                relicData[newTokenId] = RelicProperties({
                    creationTime: block.timestamp,
                    power: calculatedPower,
                    rarity: calculatedRarity,
                    isCharged: false,
                    lastChargedTime: block.timestamp,
                    dynamicTrait: calculatedTrait
                });

                emit RelicMinted(crafter, newTokenId, calculatedPower, calculatedRarity, calculatedTrait);
            }
        }

        // 5. Grant Aura
        _gainAura(crafter, recipe.inputs.length * 10 + recipe.outputs.length * 20); // Example Aura gain logic

        emit Crafted(recipeId, crafter);
    }

    /**
     * @dev Retrieves the details of a specific crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return CraftingRecipe The struct defining the recipe.
     */
    function getRecipe(uint8 recipeId) public view returns (CraftingRecipe memory) {
         if (recipeId >= nextRecipeId || recipes[recipeId].inputs.length == 0) {
            revert EtherealForge__RecipeNotFound(recipeId);
        }
        return recipes[recipeId];
    }

    /**
     * @dev Gets the total number of recipes that have been added (including removed ones by ID, until nextRecipeId wraps).
     * Use getRecipe to check if a specific ID is active.
     * @return uint8 The count of recipe IDs used.
     */
    function getRecipeCount() public view returns (uint8) {
        return nextRecipeId;
    }

    // --- Oracle Integration (Simulated) Functions ---

    /**
     * @dev Sets the address of the simulated oracle. Only callable by the contract owner.
     * @param newOracle The address of the oracle contract/account.
     */
    function setOracleAddress(address newOracle) external onlyOwner {
        oracleAddress = newOracle;
    }

    /**
     * @dev Allows a user to request randomness, potentially targeting a Relic.
     * This simulates the user-facing call to a VRF system.
     * @param tokenId The target Relic ID (0 if not targeting a specific Relic).
     * @return uint256 The unique request ID for this randomness request.
     */
    function requestRandomness(uint256 tokenId) external returns (uint256) {
        // In a real system, this would interface with a VRF oracle (like Chainlink VRF)
        // The VRF oracle would call a 'fulfill' function on this contract later.
        uint256 requestId = _randomRequestIdCounter.current();
        _randomRequestIdCounter.increment();

        randomRequestSender[requestId] = msg.sender;
        randomRequestTargetToken[requestId] = tokenId; // Store target token

        // A real VRF would emit a request event for the oracle to pick up
        emit RandomnessRequested(requestId, msg.sender, tokenId);

        return requestId;
    }

    /**
     * @dev Called by the designated oracle address to fulfill a randomness request.
     * This function should be called by the `oracleAddress` and provides the random result.
     * Uses the randomness to influence the target Relic's dynamic trait if a target was set.
     * @param requestId The ID of the randomness request being fulfilled.
     * @param randomness The random number provided by the oracle.
     */
    function fulfillRandomness(uint256 requestId, uint256 randomness) external onlyOracle {
        // Check if the request ID is valid and hasn't been fulfilled (simple check based on existence)
        if (randomRequestSender[requestId] == address(0)) {
             revert EtherealForge__RandomRequestNotFound(requestId);
        }

        address requester = randomRequestSender[requestId];
        uint256 targetTokenId = randomRequestTargetToken[requestId];

        // --- Apply Randomness Effect ---
        if (targetTokenId != 0) {
            // Example effect: Update the Relic's dynamic trait based on randomness
            // In a real scenario, randomness could influence power, rarity, new traits, etc.
            string memory randomTrait;
            if (randomness % 100 < 10) { // 10% chance of a rare trait
                randomTrait = "Mystic Glow";
            } else if (randomness % 100 < 50) { // 40% chance of an uncommon trait
                 randomTrait = "Shimmering Dust";
            } else { // 50% chance of a common trait
                 randomTrait = "Faint Spark";
            }
            // This update needs to be allowed from the oracle address
            updateRelicTrait(targetTokenId, randomTrait);

            // Could also influence power, rarity, or other properties directly here
            // relicData[targetTokenId].power += uint8(randomness % 5); // Example: Add up to 4 power
        } else {
            // Handle randomness not tied to a specific token, e.g., a global event
            // Could mint essence to the requester, grant aura, etc.
             _gainAura(requester, randomness % 50 + 1); // Example: Requester gains 1-50 Aura
        }
        // --- End Apply Randomness Effect ---

        // Clean up the request data
        delete randomRequestSender[requestId];
        delete randomRequestTargetToken[requestId];

        emit RandomnessFulfilled(requestId, randomness);
    }

    // --- Blessed Crafters Functions ---

    /**
     * @dev Adds an address to the list of blessed crafters. Only callable by the contract owner.
     * Blessed crafters can access recipes with the `requiresBlessed` flag.
     * @param crafter The address to add.
     */
    function addBlessedCrafter(address crafter) external onlyOwner {
        isBlessedCrafter[crafter] = true;
        emit BlessedCrafterAdded(crafter);
    }

    /**
     * @dev Removes an address from the list of blessed crafters. Only callable by the contract owner.
     * @param crafter The address to remove.
     */
    function removeBlessedCrafter(address crafter) external onlyOwner {
        isBlessedCrafter[crafter] = false;
        emit BlessedCrafterRemoved(crafter);
    }

    /**
     * @dev Checks if an address is currently a blessed crafter.
     * @param crafter The address to check.
     * @return bool True if the address is blessed, false otherwise.
     */
    function isBlessedCrafter(address crafter) public view returns (bool) {
        return isBlessedCrafter[crafter];
    }


    // --- Utility & Management Functions ---

    /**
     * @dev Allows the contract owner to withdraw any Ether held by the contract.
     */
    function withdrawEther() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert EtherealForge__EtherTransferFailed();
        }
    }

     /**
     * @dev Gets the name of the Essence token.
     * @return string The name of the Essence token.
     */
    function tokenName() external view returns (string memory) {
        return name(); // ERC20 standard name function
    }

    /**
     * @dev Gets the symbol of the Essence token.
     * @return string The symbol of the Essence token.
     */
    function tokenSymbol() external view returns (string memory) {
        return symbol(); // ERC20 standard symbol function
    }

    /**
     * @dev Gets the name of the Relic token.
     * @return string The name of the Relic token.
     */
    function relicName() external view returns (string memory) {
        return ERC721.name(); // ERC721 standard name function (explicitly call via ERC721)
    }

    /**
     * @dev Gets the symbol of the Relic token.
     * @return string The symbol of the Relic token.
     */
    function relicSymbol() external view returns (string memory) {
        return ERC721.symbol(); // ERC721 standard symbol function (explicitly call via ERC721)
    }

     /**
     * @dev Gets the total number of Relics minted so far.
     * @return uint256 The count of minted Relics.
     */
    function getRelicCount() external view returns (uint256) {
        // Counter starts at 1, so total minted is counter - 1
        return _relicTokenIdCounter.current() - 1;
    }

    // Fallback function to receive Ether (for potential future features or accidental sends)
    receive() external payable {}
    fallback() external payable {}
}
```