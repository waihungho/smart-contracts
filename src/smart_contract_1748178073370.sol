Okay, let's design a smart contract around a creative, advanced concept. We'll combine elements of dynamic NFTs, on-chain state progression, resource management, and simulated interaction with external data (like an oracle) to influence NFT traits and capabilities.

Let's call this contract `NFTCatalyst`. The idea is that these NFTs aren't static images; they are living entities with evolving traits, capabilities, and an internal "Essence" resource that can be used for various actions.

**Concept:**

*   **Dynamic Traits:** NFT traits (e.g., power, speed, rarity score influence) aren't fixed at mint. They can change based on the NFT's activity, internal state, and potentially external data.
*   **Essence:** Each Catalyst NFT possesses an internal "Essence" resource. Essence can be gained over time (like staking yield), used to perform actions, or even staked internally for benefits.
*   **Potential/Level:** Catalysts have a "Potential" level that increases with activity (using essence, performing synthesis, successful attunement). Higher potential might unlock new abilities or influence trait growth.
*   **Attunement:** A measure of how well the Catalyst is "attuned" to external conditions (simulated via oracle data). Higher attunement increases the influence of external data on trait updates.
*   **Synthesis:** Catalysts can perform "Synthesis" (crafting) by consuming Essence and potentially other resources (if integrated). This could yield new tokens, modify the NFT itself, or produce other digital assets.
*   **Oracle Influence (Simulated):** The contract will *simulate* receiving data from an external oracle (like market prices, weather, or random numbers) which can influence trait updates if the Catalyst's Attunement is high enough.
*   **Internal Staking:** Essence within the NFT can be "staked" to potentially increase passive Essence gain or influence trait growth.

**Outline:**

1.  **Pragmas and Imports:** Solidity version, ERC721, Ownable.
2.  **Interfaces (Mock):** Define mock interfaces for potential external interactions (e.g., a mock Oracle).
3.  **Error Definitions:** Custom errors for clarity.
4.  **Events:** Announce significant actions (mint, burn, state changes, synthesis, oracle updates).
5.  **Structs:** Define the structure to hold the dynamic state of each Catalyst token. Define Synthesis Recipes.
6.  **State Variables:** Mappings for token state, traits, recipes, oracle contract address, configuration parameters.
7.  **Constructor:** Initialize the ERC721 contract.
8.  **Modifiers:** Custom modifiers for access control beyond `onlyOwner`.
9.  **ERC721 Overrides:** Handle token state changes during transfer/burn.
10. **Core NFT Management:** Minting, Burning.
11. **Dynamic State & Trait Management:** Functions to get state/traits, update state (potential, attunement), trigger trait recalculation based on state/oracle.
12. **Essence Management:** Gaining, consuming, internal staking, claiming yield.
13. **Synthesis/Crafting:** Defining recipes, performing synthesis.
14. **Oracle Interaction (Simulated):** Setting oracle address, requesting update (simulated trigger), fulfilling update (simulated callback).
15. **Configuration (Owner):** Setting recipes, influencing factors, yield rates.
16. **Query Functions:** View functions to inspect token state, recipes, configurations.

**Function Summary:**

1.  `constructor(string name, string symbol)`: Initializes ERC721 contract.
2.  `mintCatalyst(address recipient, uint256 initialEssence)`: Mints a new Catalyst NFT, setting initial essence and base traits.
3.  `burnCatalyst(uint256 tokenId)`: Burns a Catalyst NFT, clearing its state.
4.  `getTokenEssence(uint256 tokenId)`: Gets the current available essence for a token.
5.  `getTokenPotential(uint256 tokenId)`: Gets the current potential level for a token.
6.  `getTokenAttunement(uint256 tokenId)`: Gets the current attunement score for a token.
7.  `getTraitValue(uint256 tokenId, uint256 traitId)`: Gets the value of a specific trait for a token.
8.  `getCatalystState(uint256 tokenId)`: Gets the full dynamic state struct for a token.
9.  `updateTraitsFromState(uint256 tokenId)`: Internal/external call to recalculate traits based *only* on token's internal state (Essence, Potential, Attunement).
10. `requestOracleInfluence(uint256 tokenId)`: Simulates requesting external data relevant to this token from an oracle. Marks the token for an oracle-influenced update.
11. `fulfillOracleInfluence(uint256 tokenId, bytes memory oracleData)`: *Simulated Oracle Callback* - Receives oracle data and uses it (if attunement is high enough) to influence trait updates.
12. `stakeEssence(uint256 tokenId, uint256 amount)`: Stakes available essence within the token.
13. `unstakeEssence(uint256 tokenId, uint256 amount)`: Unstakes essence previously staked within the token.
14. `claimEssenceYield(uint256 tokenId)`: Calculates and adds passive essence yield based on staked amount and time.
15. `synthesizeAsset(uint256 tokenId, uint256 recipeId)`: Performs a synthesis action using the token's essence/state based on a recipe. May modify the token or trigger external calls (simplified here).
16. `increaseAttunement(uint256 tokenId, uint256 essenceCost)`: Increases the token's attunement score by consuming essence.
17. `setOracleAddress(address newOracleAddress)`: Owner sets the address of the (simulated) oracle contract.
18. `setTraitInfluenceWeights(uint256 stateFactorWeight, uint256 oracleFactorWeight)`: Owner sets how much internal state vs. oracle data influences trait updates.
19. `setSynthesisRecipe(uint256 recipeId, SynthesisRecipe memory recipe)`: Owner defines or updates a synthesis recipe.
20. `setEssenceYieldRate(uint256 ratePerSecond)`: Owner sets the passive essence yield rate for staked essence.
21. `getTokenEssenceYieldInfo(uint256 tokenId)`: Calculates how much yield is currently available to claim.
22. `getSynthesisRecipe(uint256 recipeId)`: Gets the details of a specific synthesis recipe.
23. `isOracleInfluencePending(uint256 tokenId)`: Checks if the token is waiting for an oracle callback.
24. `burnEssence(uint256 tokenId, uint256 amount)`: Internal function to decrease token essence (used by actions).
25. `addEssence(uint256 tokenId, uint256 amount)`: Internal function to increase token essence (used by yield, minting).
26. `increasePotential(uint256 tokenId, uint256 levels)`: Internal function to increase potential (used by actions).
27. `updateAttunement(uint256 tokenId, uint256 score)`: Internal function to set attunement score.
28. `getTraitInfluenceWeights()`: Gets the current trait influence weights.
29. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 compliance, including ERC721 and ERC2981 (if royalties added).
30. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: Standard ERC2981 royalty function (optional but trendy). *Let's add this for > 20 total.*

Okay, that gives us 30 functions (8 standard ERC721 + 2 ERC2981 + 20 custom/overridden).

Let's write the code. We'll simplify the oracle and synthesis outputs for demonstration purposes, focusing on the *mechanics* within the NFT state.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for listing tokens, often included
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For dynamic URIs if needed
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, good practice or for specific use cases. Let's use 0.8+ safe math directly.
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // For NFT Royalties

// --- Outline ---
// 1. Pragmas and Imports
// 2. Error Definitions
// 3. Events
// 4. Structs
// 5. State Variables
// 6. Constructor
// 7. Modifiers (Implicit via Ownable)
// 8. ERC721 Overrides (_beforeTokenTransfer)
// 9. Core NFT Management (Mint, Burn)
// 10. Dynamic State & Trait Management (Get, Update, Oracle Influence)
// 11. Essence Management (Get, Stake, Unstake, Claim Yield, Internal Add/Burn)
// 12. Synthesis/Crafting (Define Recipe, Perform Synthesis)
// 13. Attunement Management (Increase)
// 14. Oracle Interaction (Simulated Request/Fulfill)
// 15. Configuration (Owner functions for recipes, weights, rates, oracle address)
// 16. Query Functions (Get details, recipes, yield info)
// 17. ERC165 Support
// 18. ERC2981 Royalties

// --- Function Summary ---
// 1. constructor(string name, string symbol) - Initializes contract.
// 2. mintCatalyst(address recipient, uint256 initialEssence) - Mints a new Catalyst.
// 3. burnCatalyst(uint256 tokenId) - Burns a Catalyst.
// 4. getTokenEssence(uint256 tokenId) - Get available essence.
// 5. getTokenStakedEssence(uint256 tokenId) - Get staked essence.
// 6. getTokenPotential(uint256 tokenId) - Get potential level.
// 7. getTokenAttunement(uint256 tokenId) - Get attunement score.
// 8. getTraitValue(uint256 tokenId, uint256 traitId) - Get a specific trait value.
// 9. getCatalystState(uint256 tokenId) - Get full dynamic state.
// 10. updateTraitsFromState(uint256 tokenId) - Recalculate traits based on internal state.
// 11. requestOracleInfluence(uint256 tokenId) - Mark token for oracle update (simulated).
// 12. fulfillOracleInfluence(uint256 tokenId, bytes memory oracleData) - Simulate oracle callback & apply influence.
// 13. stakeEssence(uint256 tokenId, uint256 amount) - Stake essence internally.
// 14. unstakeEssence(uint256 tokenId, uint256 amount) - Unstake essence internally.
// 15. claimEssenceYield(uint256 tokenId) - Claim accumulated essence yield.
// 16. synthesizeAsset(uint256 tokenId, uint256 recipeId) - Perform synthesis using recipe.
// 17. increaseAttunement(uint256 tokenId, uint256 essenceCost) - Increase attunement by spending essence.
// 18. setOracleAddress(address newOracleAddress) - Owner sets oracle address (simulated).
// 19. setTraitInfluenceWeights(uint256 stateFactorWeight, uint256 oracleFactorWeight) - Owner sets trait influence weights.
// 20. setSynthesisRecipe(uint256 recipeId, SynthesisRecipe memory recipe) - Owner sets synthesis recipe.
// 21. setEssenceYieldRate(uint256 ratePerSecond) - Owner sets passive essence yield rate.
// 22. getTokenEssenceYieldInfo(uint256 tokenId) - Calculate current claimable yield.
// 23. getSynthesisRecipe(uint256 recipeId) - Get recipe details.
// 24. isOracleInfluencePending(uint256 tokenId) - Check if pending oracle update.
// 25. getTraitInfluenceWeights() - Get current weights.
// 26. _burnEssence(uint256 tokenId, uint256 amount) - Internal function to burn essence.
// 27. _addEssence(uint256 tokenId, uint256 amount) - Internal function to add essence.
// 28. _increasePotential(uint256 tokenId, uint256 levels) - Internal function to increase potential.
// 29. supportsInterface(bytes4 interfaceId) - ERC165 interface support.
// 30. royaltyInfo(uint256 tokenId, uint256 salePrice) - ERC2981 royalties.

// Inherit from ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ERC2981
contract NFTCatalyst is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Error Definitions ---
    error NFTCatalyst__TokenDoesNotExist();
    error NFTCatalyst__InsufficientEssence(uint256 tokenId, uint256 required, uint256 available);
    error NFTCatalyst__InsufficientStakedEssence(uint256 tokenId, uint256 required, uint256 available);
    error NFTCatalyst__NotOwnerOrApproved();
    error NFTCatalyst__OracleNotSet();
    error NFTCatalyst__OracleInfluenceAlreadyPending(uint256 tokenId);
    error NFTCatalyst__NoOracleInfluencePending(uint256 tokenId);
    error NFTCatalyst__RecipeDoesNotExist(uint256 recipeId);
    error NFTCatalyst__InsufficientPotential(uint256 tokenId, uint256 required, uint256 available);
    error NFTCatalyst__InsufficientAttunement(uint256 tokenId, uint256 required, uint256 available);
    error NFTCatalyst__TraitDoesNotExist(uint256 traitId);
    error NFTCatalyst__AmountCannotBeZero();

    // --- Events ---
    event CatalystMinted(address indexed owner, uint256 indexed tokenId, uint256 initialEssence);
    event CatalystBurned(uint256 indexed tokenId);
    event EssenceAdded(uint256 indexed tokenId, uint256 amount);
    event EssenceBurned(uint256 indexed tokenId, uint256 amount);
    event EssenceStaked(uint256 indexed tokenId, uint256 amount, uint256 totalStaked);
    event EssenceUnstaked(uint256 indexed tokenId, uint256 amount, uint256 totalStaked);
    event EssenceYieldClaimed(uint256 indexed tokenId, uint256 amountClaimed);
    event PotentialIncreased(uint256 indexed tokenId, uint256 oldPotential, uint256 newPotential);
    event AttunementIncreased(uint256 indexed tokenId, uint256 oldAttunement, uint256 newAttunement);
    event TraitsUpdated(uint256 indexed tokenId, bytes32 indexed updateHash, bool oracleInfluenced); // updateHash could be hash of oracle data + state
    event OracleInfluenceRequested(uint256 indexed tokenId);
    event OracleInfluenceFulfilled(uint256 indexed tokenId, bytes oracleData, bytes32 indexed dataHash);
    event AssetSynthesized(uint256 indexed tokenId, uint256 indexed recipeId);
    event SynthesisRecipeSet(uint256 indexed recipeId);
    event TraitInfluenceWeightsSet(uint256 stateFactorWeight, uint256 oracleFactorWeight);
    event EssenceYieldRateSet(uint256 ratePerSecond);

    // --- Structs ---
    struct CatalystState {
        uint256 totalEssence;        // Total essence the token possesses
        uint256 stakedEssence;       // Amount of essence staked internally
        uint256 potential;           // Level/potential of the catalyst
        uint256 attunement;          // Score indicating attunement to external data
        uint256 lastYieldClaimTimestamp; // Timestamp of last essence yield claim
        uint256 lastTraitUpdateTimestamp; // Timestamp of last trait update
        bytes32 lastOracleSnapshotHash; // Hash representing the oracle data used for last update
        bool oracleInfluencePending; // Flag indicating if an oracle update is pending
    }

    struct SynthesisRecipe {
        uint256 essenceCost;       // Essence required to synthesize
        uint256 requiredPotential; // Minimum potential needed
        uint256 requiredAttunement; // Minimum attunement needed
        // Could add inputs for other token types here
        // Could add outputs for new tokens/NFTs here (simplified for this example)
        uint256 outputModifierValue; // Example: A value added to a specific trait upon success
        uint256 potentialGain;     // Potential gained from successful synthesis
        uint256 attunementLoss;    // Attunement lost from synthesis (optional)
    }

    // --- State Variables ---
    mapping(uint256 => CatalystState) private _catalystStates;
    // Traits are stored separately - traitId maps to value
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenTraits; // tokenID => traitID => value

    // Configuration
    mapping(uint256 => SynthesisRecipe) private _recipes;
    uint256 private _recipeCount; // Simple counter for recipes
    uint256 private _essenceYieldRatePerSecond; // Rate of passive essence gain for staked amount
    uint256 private _traitStateFactorWeight;    // Weight of internal state on trait updates (0-100)
    uint256 private _traitOracleFactorWeight;   // Weight of oracle data on trait updates (0-100)
    address private _oracleContract; // Address of the simulated oracle contract

    // Royalties
    address private _royaltyReceiver;
    uint96 private _royaltyFeeNumerator; // e.g., 500 for 5%

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address initialRoyaltyReceiver,
        uint96 initialRoyaltyFeeNumerator // e.g., 500 for 5% (500/10000)
    ) ERC721(name, symbol) ERC721Enumerable() ERC721URIStorage() ERC2981() Ownable(msg.sender) {
        _royaltyReceiver = initialRoyaltyReceiver;
        _royaltyFeeNumerator = initialRoyaltyFeeNumerator;
    }

    // --- ERC721 Overrides ---
    // The following functions are overrides required by Solidity.
    // We add logic to handle the associated state struct.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) // Add ERC721URIStorage if overriding _baseURI, etc.
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring out from zero address (minting) or transferring to zero address (burning)
        if (from == address(0) || to == address(0)) {
             // No state cleanup needed on mint, handled by mint function
             if (to == address(0)) {
                // Handle state cleanup on burn
                delete _catalystStates[tokenId];
                // Note: Traits (_tokenTraits) could persist or be cleared.
                // Clearing them makes more sense if the token is gone.
                // For demonstration, let's assume traits are also tied to existence.
                // In a real complex system, traits might be in a separate contract.
                // For simplicity here, we'll clear the mapping entry.
                delete _tokenTraits[tokenId]; // Clears all traits for this token
             }
        } else {
            // When transferring between users, the state moves with the token implicitly
            // No explicit state transfer code needed here, as the mapping key is the token ID.
            // However, unstaking essence might be a design choice during transfer.
            // Let's choose to unstake all essence on transfer for simplicity and security.
            if (_catalystStates[tokenId].stakedEssence > 0) {
                 uint256 stakedAmount = _catalystStates[tokenId].stakedEssence;
                 _catalystStates[tokenId].totalEssence += stakedAmount;
                 _catalystStates[tokenId].stakedEssence = 0;
                 emit EssenceUnstaked(tokenId, stakedAmount, 0);
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981) // Also add ERC721URIStorage if used
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- ERC2981 Royalties ---
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Check if token exists before providing royalty info
        if (!_exists(tokenId)) {
             return (address(0), 0); // Or revert with a custom error
        }
        // Simple fixed royalty percentage for all tokens
        return (_royaltyReceiver, (salePrice * _royaltyFeeNumerator) / 10000);
    }

    // --- Core NFT Management ---

    /// @notice Mints a new Catalyst NFT and initializes its state.
    /// @param recipient The address to receive the new token.
    /// @param initialEssence The starting amount of essence for the new token.
    function mintCatalyst(address recipient, uint256 initialEssence) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);

        // Initialize Catalyst State
        CatalystState storage newState = _catalystStates[newTokenId];
        newState.totalEssence = initialEssence;
        newState.stakedEssence = 0;
        newState.potential = 1; // Start at potential level 1
        newState.attunement = 0;
        newState.lastYieldClaimTimestamp = block.timestamp;
        newState.lastTraitUpdateTimestamp = block.timestamp;
        newState.lastOracleSnapshotHash = bytes32(0); // No oracle data yet
        newState.oracleInfluencePending = false;

        // Initialize base traits (Example traits: 1=Power, 2=Speed, 3=Luck)
        _tokenTraits[newTokenId][1] = 10; // Initial Power
        _tokenTraits[newTokenId][2] = 5;  // Initial Speed
        _tokenTraits[newTokenId][3] = 1;  // Initial Luck

        emit CatalystMinted(recipient, newTokenId, initialEssence);
    }

    /// @notice Burns a Catalyst NFT. Can only be called by the owner or approved address.
    /// @param tokenId The ID of the token to burn.
    function burnCatalyst(uint256 tokenId) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();

        _burn(tokenId);
        // State cleanup handled in _beforeTokenTransfer
        emit CatalystBurned(tokenId);
    }

    // --- Dynamic State & Trait Management ---

    /// @notice Gets the current available essence for a token.
    /// @param tokenId The ID of the token.
    /// @return The amount of available essence.
    function getTokenEssence(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        // Available essence = Total - Staked
        return _catalystStates[tokenId].totalEssence - _catalystStates[tokenId].stakedEssence;
    }

    /// @notice Gets the current staked essence for a token.
    /// @param tokenId The ID of the token.
    /// @return The amount of staked essence.
    function getTokenStakedEssence(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        return _catalystStates[tokenId].stakedEssence;
    }

    /// @notice Gets the current potential level for a token.
    /// @param tokenId The ID of the token.
    /// @return The potential level.
    function getTokenPotential(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        return _catalystStates[tokenId].potential;
    }

    /// @notice Gets the current attunement score for a token.
    /// @param tokenId The ID of the token.
    /// @return The attunement score.
    function getTokenAttunement(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        return _catalystStates[tokenId].attunement;
    }

    /// @notice Gets the value of a specific trait for a token.
    /// @param tokenId The ID of the token.
    /// @param traitId The ID of the trait (e.g., 1 for Power, 2 for Speed).
    /// @return The trait value.
    function getTraitValue(uint256 tokenId, uint256 traitId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        // Return 0 if trait hasn't been explicitly set/updated for this token/traitId
        return _tokenTraits[tokenId][traitId];
    }

    /// @notice Gets the full dynamic state struct for a token.
    /// @param tokenId The ID of the token.
    /// @return The CatalystState struct.
    function getCatalystState(uint256 tokenId) public view returns (CatalystState memory) {
         if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
         return _catalystStates[tokenId];
    }

    /// @notice Recalculates token traits based on its internal state.
    /// Can be called by the owner of the token or approved.
    /// @param tokenId The ID of the token to update.
    function updateTraitsFromState(uint256 tokenId) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
         if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();

        CatalystState storage state = _catalystStates[tokenId];

        // --- Trait Calculation Logic (Example) ---
        // This is a simplified example. Real logic would be more complex.
        // Traits are influenced by Potential, Attunement, and Essence (maybe).
        // We'll apply the state factor weight.

        // Example Traits:
        // Trait 1 (Power): Influenced by Potential and total Essence
        // Trait 2 (Speed): Influenced by Potential and Attunement
        // Trait 3 (Luck): Influenced by Attunement and Potentia (slightly)

        uint256 stateFactor = (state.potential * 100 + state.attunement * 10 + state.totalEssence / 100);
        uint256 stateInfluence = (stateFactor * _traitStateFactorWeight) / 10000; // Max weight 100, scale factor 100

        // Apply influence (additive example)
        _tokenTraits[tokenId][1] = _tokenTraits[tokenId][1] + (stateInfluence / 5); // Power
        _tokenTraits[tokenId][2] = _tokenTraits[tokenId][2] + (stateInfluence / 10); // Speed
        _tokenTraits[tokenId][3] = _tokenTraits[tokenId][3] + (stateInfluence / 20); // Luck

        // Prevent traits from becoming excessively large - Cap example
        uint256 maxTraitValue = 1000;
        if (_tokenTraits[tokenId][1] > maxTraitValue) _tokenTraits[tokenId][1] = maxTraitValue;
        if (_tokenTraits[tokenId][2] > maxTraitValue) _tokenTraits[tokenId][2] = maxTraitValue;
        if (_tokenTraits[tokenId][3] > maxTraitValue) _tokenTraits[tokenId][3] = maxTraitValue;


        bytes32 updateHash = keccak256(abi.encodePacked(state.totalEssence, state.stakedEssence, state.potential, state.attunement, block.timestamp));
        state.lastTraitUpdateTimestamp = block.timestamp;

        emit TraitsUpdated(tokenId, updateHash, false); // Not oracle influenced this time
    }

     /// @notice Marks a token as needing an oracle influence update.
     /// This is a simulated trigger. A real system would interact with Chainlink or similar.
     /// Can be called by the owner of the token or approved.
     /// @param tokenId The ID of the token.
     function requestOracleInfluence(uint256 tokenId) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();
        if (_catalystStates[tokenId].oracleInfluencePending)
             revert NFTCatalyst__OracleInfluenceAlreadyPending(tokenId);
        if (_oracleContract == address(0))
            revert NFTCatalyst__OracleNotSet();

        // In a real scenario, this would call the oracle contract to request data.
        // The oracle would then asynchronously call back fulfillOracleInfluence.
        // For this simulation, we just set a flag.
        _catalystStates[tokenId].oracleInfluencePending = true;

        emit OracleInfluenceRequested(tokenId);
     }

     /// @notice Simulates the oracle callback to apply external influence on traits.
     /// In a real system, this function would be called by the oracle contract.
     /// Here, it's callable by the owner role for demonstration.
     /// @param tokenId The ID of the token to update.
     /// @param oracleData The simulated data received from the oracle.
     function fulfillOracleInfluence(uint256 tokenId, bytes memory oracleData) public onlyOwner {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        if (!_catalystStates[tokenId].oracleInfluencePending)
            revert NFTCatalyst__NoOracleInfluencePending(tokenId);

        CatalystState storage state = _catalystStates[tokenId];
        state.oracleInfluencePending = false; // Clear the pending flag

        // --- Trait Calculation Logic with Oracle Influence (Example) ---
        // This is a simplified example. Parsing oracleData depends on its format.
        // Assume oracleData is a simple bytes representing a uint256 'environmental score'.
        uint256 oracleFactor = 0;
        if (oracleData.length >= 32) {
             assembly {
                 oracleFactor := mload(add(oracleData, 32)) // Read first uint256 from data
             }
        } else {
             // Handle insufficient data, maybe set oracleFactor to a default or 0
             oracleFactor = 1; // Example default
        }

        // Ensure oracleFactor doesn't cause overflow if used in calculations
        oracleFactor = oracleFactor % 1000; // Cap example

        // Calculate influence from state and oracle data
        uint256 stateInfluence = (_getStateInfluenceValue(tokenId) * _traitStateFactorWeight) / 10000; // Max 10000 total weight
        uint256 oracleInfluence = (oracleFactor * _traitOracleFactorWeight) / 10000;

        // Total influence calculation - simple additive, weighted
        uint256 totalInfluence = stateInfluence + oracleInfluence;

        // Attunement acts as a multiplier or limiter on oracle influence
        // Example: Oracle influence is scaled by Attunement / 100 (max 100 attunement)
        uint256 effectiveOracleInfluence = (oracleInfluence * state.attunement) / 100; // Attunement acts as a percentage multiplier (capped at 100)

        // Apply influence (additive example, potentially to base stats or previous stats)
        // For demonstration, let's just add totalInfluence weighted by attunement effect for oracle part
        uint256 finalInfluence = stateInfluence + effectiveOracleInfluence;

        // Apply influence to traits
        // Trait 1 (Power)
        _tokenTraits[tokenId][1] = _tokenTraits[tokenId][1] + (finalInfluence / 5);
        // Trait 2 (Speed)
        _tokenTraits[tokenId][2] = _tokenTraits[tokenId][2] + (finalInfluence / 10);
        // Trait 3 (Luck)
        _tokenTraits[tokenId][3] = _tokenTraits[tokenId][3] + (finalInfluence / 20);

        // Prevent traits from becoming excessively large - Cap example
        uint256 maxTraitValue = 1000; // Can be different per trait
        if (_tokenTraits[tokenId][1] > maxTraitValue) _tokenTraits[tokenId][1] = maxTraitValue;
        if (_tokenTraits[tokenId][2] > maxTraitValue) _tokenTraits[tokenId][2] = maxTraitValue;
        if (_tokenTraits[tokenId][3] > maxTraitValue) _tokenTraits[tokenId][3] = maxTraitValue;

        bytes32 dataHash = keccak256(oracleData);
        state.lastOracleSnapshotHash = dataHash; // Store snapshot hash
        state.lastTraitUpdateTimestamp = block.timestamp;

        emit OracleInfluenceFulfilled(tokenId, oracleData, dataHash);
        emit TraitsUpdated(tokenId, keccak256(abi.encodePacked(state.totalEssence, state.stakedEssence, state.potential, state.attunement, dataHash, block.timestamp)), true);
     }

    // Internal helper to calculate state influence value
    function _getStateInfluenceValue(uint256 tokenId) internal view returns(uint256) {
         CatalystState storage state = _catalystStates[tokenId];
         // Example formula: Potential * 100 + Attunement * 10 + sqrt(totalEssence)
         // Sqrt is complex on-chain. Use a simpler proportional model.
         // State Factor: Potential (big impact) + Attunement (medium) + Essence (small)
         // Example: Potential * 50 + Attunement * 20 + totalEssence / 200
         // Ensure calculation prevents overflow with reasonable maximums for state values.
         uint256 potentialInfluence = state.potential * 50;
         uint256 attunementInfluence = state.attunement * 20;
         uint256 essenceInfluence = state.totalEssence / 200; // Cap essence influence

         return potentialInfluence + attunementInfluence + essenceInfluence; // Raw state factor value
    }


    /// @notice Checks if a token is currently waiting for an oracle callback.
    /// @param tokenId The ID of the token.
    /// @return True if pending, false otherwise.
    function isOracleInfluencePending(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        return _catalystStates[tokenId].oracleInfluencePending;
    }


    // --- Essence Management ---

    /// @notice Stakes available essence within the token.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of essence to stake.
    function stakeEssence(uint256 tokenId, uint256 amount) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();
        if (amount == 0) revert NFTCatalyst__AmountCannotBeZero();

        CatalystState storage state = _catalystStates[tokenId];
        if (getTokenEssence(tokenId) < amount)
            revert NFTCatalyst__InsufficientEssence(tokenId, amount, getTokenEssence(tokenId));

        // Claim pending yield before staking to avoid calculating yield on newly staked amount for past time
        claimEssenceYield(tokenId); // This updates totalEssence and lastYieldClaimTimestamp

        state.stakedEssence += amount;
        // totalEssence remains the same, available essence decreases

        emit EssenceStaked(tokenId, amount, state.stakedEssence);
    }

    /// @notice Unstakes essence from within the token.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of essence to unstake.
    function unstakeEssence(uint256 tokenId, uint256 amount) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();
        if (amount == 0) revert NFTCatalyst__AmountCannotBeZero();


        CatalystState storage state = _catalystStates[tokenId];
        if (state.stakedEssence < amount)
             revert NFTCatalyst__InsufficientStakedEssence(tokenId, amount, state.stakedEssence);

        // Claim pending yield before unstaking
        claimEssenceYield(tokenId); // This updates totalEssence and lastYieldClaimTimestamp

        state.stakedEssence -= amount;
        // totalEssence remains the same, available essence increases

        emit EssenceUnstaked(tokenId, amount, state.stakedEssence);
    }

    /// @notice Calculates and adds passive essence yield based on staked amount and time.
    /// Callable by the owner of the token or approved.
    /// @param tokenId The ID of the token.
    function claimEssenceYield(uint256 tokenId) public {
         if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
         if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();

         CatalystState storage state = _catalystStates[tokenId];

         uint256 stakedAmount = state.stakedEssence;
         uint256 lastClaim = state.lastYieldClaimTimestamp;
         uint256 currentTimestamp = block.timestamp;
         uint256 yieldRate = _essenceYieldRatePerSecond; // Rate per second per staked unit

         uint256 secondsPassed = currentTimestamp - lastClaim;
         uint256 earnedYield = (stakedAmount * secondsPassed * yieldRate) / 1e18; // Assuming rate is fixed point 1e18 or similar scaling

         if (earnedYield > 0) {
            _addEssence(tokenId, earnedYield);
            emit EssenceYieldClaimed(tokenId, earnedYield);
         }

         state.lastYieldClaimTimestamp = currentTimestamp; // Update timestamp even if 0 yield
    }

    /// @notice Internal function to add essence to a token.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of essence to add.
    function _addEssence(uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return;
        _catalystStates[tokenId].totalEssence += amount;
        emit EssenceAdded(tokenId, amount);
    }

    /// @notice Internal function to burn essence from a token.
    /// Requires sufficient available (unstaked) essence.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of essence to burn.
    function _burnEssence(uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return;
         if (getTokenEssence(tokenId) < amount)
            revert NFTCatalyst__InsufficientEssence(tokenId, amount, getTokenEssence(tokenId));

        _catalystStates[tokenId].totalEssence -= amount;
        emit EssenceBurned(tokenId, amount);
    }

    // --- Synthesis/Crafting ---

    /// @notice Performs a synthesis action using the token's state based on a recipe.
    /// Consumes essence and potentially other resources. Increases potential.
    /// Callable by the owner of the token or approved.
    /// @param tokenId The ID of the token.
    /// @param recipeId The ID of the synthesis recipe to use.
    function synthesizeAsset(uint256 tokenId, uint256 recipeId) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
         if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();

        SynthesisRecipe memory recipe = _recipes[recipeId];
        if (recipe.essenceCost == 0 && recipe.requiredPotential == 0 && recipe.requiredAttunement == 0 && recipe.potentialGain == 0 && recipe.outputModifierValue == 0)
            revert NFTCatalyst__RecipeDoesNotExist(recipeId);

        CatalystState storage state = _catalystStates[tokenId];

        // Check requirements
        if (getTokenEssence(tokenId) < recipe.essenceCost)
            revert NFTCatalyst__InsufficientEssence(tokenId, recipe.essenceCost, getTokenEssence(tokenId));
        if (state.potential < recipe.requiredPotential)
            revert NFTCatalyst__InsufficientPotential(tokenId, recipe.requiredPotential, state.potential);
        if (state.attunement < recipe.requiredAttunement)
            revert NFTCatalyst__InsufficientAttunement(tokenId, recipe.requiredAttunement, state.attunement);

        // Consume inputs
        _burnEssence(tokenId, recipe.essenceCost);

        // Apply effects (example: modify a trait, increase potential)
        // This is where outputs (like minting new tokens) would happen in a real contract
        _increasePotential(tokenId, recipe.potentialGain);

        // Example: Recipe output modifies Trait 1 (Power)
        if (recipe.outputModifierValue > 0) {
            _tokenTraits[tokenId][1] += recipe.outputModifierValue;
             // Add cap check if needed
             uint256 maxTraitValue = 1000; // Use the same cap logic or recipe-specific cap
             if (_tokenTraits[tokenId][1] > maxTraitValue) _tokenTraits[tokenId][1] = maxTraitValue;
        }

        if (recipe.attunementLoss > 0) {
            state.attunement = state.attunement > recipe.attunementLoss ? state.attunement - recipe.attunementLoss : 0;
             emit AttunementIncreased(tokenId, state.attunement + recipe.attunementLoss, state.attunement); // Emit change
        }

        // Recalculate traits after state change
        updateTraitsFromState(tokenId);

        emit AssetSynthesized(tokenId, recipeId);
    }

    // --- Attunement Management ---

    /// @notice Increases the token's attunement score by consuming essence.
    /// Attunement is capped (e.g., at 100).
    /// Callable by the owner of the token or approved.
    /// @param tokenId The ID of the token.
    /// @param essenceCost The amount of essence to spend to increase attunement.
    function increaseAttunement(uint256 tokenId, uint256 essenceCost) public {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
         if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender))
            revert NFTCatalyst__NotOwnerOrApproved();
        if (essenceCost == 0) revert NFTCatalyst__AmountCannotBeZero();

        CatalystState storage state = _catalystStates[tokenId];

        // Check essence
        if (getTokenEssence(tokenId) < essenceCost)
            revert NFTCatalyst__InsufficientEssence(tokenId, essenceCost, getTokenEssence(tokenId));

        // Cap attunement
        uint256 maxAttunement = 100;
        if (state.attunement >= maxAttunement) {
            // Already max attunement, maybe return essence cost or revert
            // For now, let's just do nothing with essence cost if already max
            return;
        }

        // Burn essence
        _burnEssence(tokenId, essenceCost);

        // Increase attunement based on essence spent (simple linear relation example)
        // Example: 1 essence = 1 attunement point (up to max)
        uint256 attunementGain = essenceCost;
        uint256 newAttunement = state.attunement + attunementGain;
        if (newAttunement > maxAttunement) {
            newAttunement = maxAttunement;
            // Refund excess essence? Depends on desired mechanic. For simplicity, no refund.
        }

        uint256 oldAttunement = state.attunement;
        state.attunement = newAttunement;

        emit AttunementIncreased(tokenId, oldAttunement, newAttunement);

        // Optionally, update traits after attunement change
        updateTraitsFromState(tokenId);
    }

    // --- Configuration (Owner) ---

    /// @notice Owner function to set the address of the simulated oracle contract.
    /// @param newOracleAddress The address of the oracle contract.
    function setOracleAddress(address newOracleAddress) public onlyOwner {
        _oracleContract = newOracleAddress;
    }

    /// @notice Owner function to set the weights for how much internal state and oracle data influence trait updates.
    /// Weights are out of 100 (e.g., 70, 30). Must sum to <= 100.
    /// @param stateFactorWeight Weight for internal state influence (0-100).
    /// @param oracleFactorWeight Weight for oracle data influence (0-100).
    function setTraitInfluenceWeights(uint256 stateFactorWeight, uint256 oracleFactorWeight) public onlyOwner {
        require(stateFactorWeight <= 100 && oracleFactorWeight <= 100, "Weights must be <= 100");
        require(stateFactorWeight + oracleFactorWeight <= 100, "Weights sum must be <= 100"); // Allow < 100 for reduced overall influence
        _traitStateFactorWeight = stateFactorWeight;
        _traitOracleFactorWeight = oracleFactorWeight;
        emit TraitInfluenceWeightsSet(stateFactorWeight, oracleFactorWeight);
    }

    /// @notice Owner function to define or update a synthesis recipe.
    /// Setting all fields to 0 effectively removes the recipe.
    /// @param recipeId The ID of the recipe to set.
    /// @param recipe The SynthesisRecipe struct containing details.
    function setSynthesisRecipe(uint256 recipeId, SynthesisRecipe memory recipe) public onlyOwner {
        _recipes[recipeId] = recipe;
        // Simple recipe counter increment if it's a new non-zero recipe
        if (_recipes[recipeId].essenceCost == 0 && recipe.essenceCost > 0) {
             _recipeCount++;
        } else if (_recipes[recipeId].essenceCost > 0 && recipe.essenceCost == 0) {
             _recipeCount--;
        }
        emit SynthesisRecipeSet(recipeId);
    }

    /// @notice Owner function to set the passive essence yield rate for staked essence.
    /// @param ratePerSecond The rate of essence earned per second per unit staked.
    /// This rate should be scaled (e.g., 1e18 for 1 unit/sec).
    function setEssenceYieldRate(uint256 ratePerSecond) public onlyOwner {
        _essenceYieldRatePerSecond = ratePerSecond;
        emit EssenceYieldRateSet(ratePerSecond);
    }

    // --- Query Functions ---

    /// @notice Gets the currently configured trait influence weights.
    /// @return stateFactorWeight, oracleFactorWeight The weights.
    function getTraitInfluenceWeights() public view returns (uint256 stateFactorWeight, uint256 oracleFactorWeight) {
        return (_traitStateFactorWeight, _traitOracleFactorWeight);
    }

    /// @notice Calculates the amount of essence yield currently available to claim for a token.
    /// @param tokenId The ID of the token.
    /// @return The amount of claimable yield.
    function getTokenEssenceYieldInfo(uint256 tokenId) public view returns (uint256 claimableYield) {
        if (!_exists(tokenId)) revert NFTCatalyst__TokenDoesNotExist();
         CatalystState storage state = _catalystStates[tokenId];

         uint256 stakedAmount = state.stakedEssence;
         uint256 lastClaim = state.lastYieldClaimTimestamp;
         uint256 currentTimestamp = block.timestamp;
         uint256 yieldRate = _essenceYieldRatePerSecond;

         if (stakedAmount == 0 || yieldRate == 0 || currentTimestamp <= lastClaim) {
             return 0;
         }

         uint256 secondsPassed = currentTimestamp - lastClaim;
         // Use SafeMath if needed for very large numbers, but 0.8+ handles basic ops
         claimableYield = (stakedAmount * secondsPassed * yieldRate) / 1e18; // Assuming rate scaling

         return claimableYield;
    }

    /// @notice Gets the details of a specific synthesis recipe.
    /// @param recipeId The ID of the recipe.
    /// @return The SynthesisRecipe struct.
    function getSynthesisRecipe(uint256 recipeId) public view returns (SynthesisRecipe memory) {
        SynthesisRecipe memory recipe = _recipes[recipeId];
         if (recipe.essenceCost == 0 && recipe.requiredPotential == 0 && recipe.requiredAttunement == 0 && recipe.potentialGain == 0 && recipe.outputModifierValue == 0)
             revert NFTCatalyst__RecipeDoesNotExist(recipeId);
        return recipe;
    }

     /// @notice Gets the total number of distinct synthesis recipes defined.
     function getRecipeCount() public view returns (uint256) {
         return _recipeCount;
     }


    // --- Internal State Update Helpers ---
    // These could be called by various actions (synthesis, external game logic, etc.)

    /// @notice Internal function to increase the potential level of a token.
    /// @param tokenId The ID of the token.
    /// @param levels The number of levels to increase potential by.
    function _increasePotential(uint256 tokenId, uint256 levels) internal {
        if (levels == 0) return;
        uint256 oldPotential = _catalystStates[tokenId].potential;
        _catalystStates[tokenId].potential += levels; // Potential can grow indefinitely
        emit PotentialIncreased(tokenId, oldPotential, _catalystStates[tokenId].potential);
    }

    /// @notice Internal function to set the attunement score. Used by increaseAttunement.
    /// Not intended for direct external calls other than increaseAttunement.
    /// @param tokenId The ID of the token.
    /// @param score The new attunement score.
    function _updateAttunement(uint256 tokenId, uint256 score) internal {
         // Add bounds check/cap if not handled by caller
         uint256 oldAttunement = _catalystStates[tokenId].attunement;
         _catalystStates[tokenId].attunement = score;
         // Event already emitted by increaseAttunement
    }


    // The following functions are required by ERC721Enumerable.
    // We inherit and don't need to override if we use the standard OpenZeppelin implementation.
    // function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256)
    // function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256)
    // function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256)

    // The following functions are required by ERC721URIStorage.
    // Override tokenURI if you store URIs differently.
    // function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
}
```