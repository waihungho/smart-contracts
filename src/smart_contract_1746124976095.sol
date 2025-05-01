Okay, let's design a smart contract around an evolving digital entity or artifact (an NFT) that changes state based on time, interaction, staking, merging, and external 'resonance' events. We'll call it `AuraEssence`.

It's an ERC721 token at its core, but with significant added complexity related to its internal state, dynamic attributes, and lifecycle events.

**Concept:** AuraEssences are unique, dynamic NFTs. Each Essence has an internal resource called "Essence Points" (EP), which naturally decays over time. EP influences the Essence's "Aura," a primary attribute. Essences can gain temporary or permanent "Traits" through various actions. They can be "Attuned" (staked) to potentially earn EP or other rewards based on their Aura and Traits, but Attunement might pause decay or apply different decay rules. Essences can be "Synthesized" (merged) or "Fragmented" (split), burning the originals and creating new ones with combined or divided properties. External "Resonance" events can influence Essence states globally or individually. Manifesting requires spending EP for a temporary boost or state change.

This structure provides dynamic state, interaction mechanics, token sinks/faucets (EP), and lifecycle events (mint, synthesis, fragmentation, decay, attunement, manifestation).

---

**AuraEssence Smart Contract**

**Outline:**

1.  **Contract Definition:** Inherits ERC721 and Ownable.
2.  **Structs:**
    *   `Trait`: Defines an attribute with name, modifiers, expiry, and permanence.
    *   `EssenceState`: Holds the core state of an individual Essence token (EP, last decay time, traits, attunement status, ephemeral state).
    *   `SynthesisConfig`: Defines rules for merging.
    *   `FragmentationConfig`: Defines rules for splitting.
3.  **State Variables:**
    *   Mappings to store `EssenceState` for each token ID.
    *   Counters for total tokens minted.
    *   Configuration variables (decay rate, synthesis/fragmentation rules, attunement rates).
    *   Mapping for available `Trait` types.
4.  **Events:** Signaling key actions like minting, synthesis, fragmentation, attunement, trait changes, EP changes, decay, resonance, manifestation.
5.  **Modifiers:** Owner-only, etc.
6.  **Constructor:** Initializes name, symbol, and owner.
7.  **ERC721 Overrides:** Handle state updates potentially affected by transfers (`_beforeTokenTransfer`). `tokenURI` to reflect dynamic state.
8.  **Internal/Helper Functions:**
    *   `_calculateCurrentEP`: Applies decay based on time.
    *   `_calculateAura`: Determines Aura based on EP and Traits.
    *   `_addTraitToEssence`: Adds a trait to an Essence's state.
    *   `_removeTraitFromEssence`: Removes a trait.
    *   `_applyDecayLogic`: Core logic for applying decay to a single token.
    *   `_handleAttunementRewards`: Calculates and applies rewards for attuned tokens.
    *   `_performSynthesis`: Executes the synthesis process.
    *   `_performFragmentation`: Executes the fragmentation process.
    *   `_generateNewEssenceState`: Creates initial state for new tokens (minted, synthesized, fragmented).
9.  **Public/External Functions (20+):**
    *   **Core ERC721 (8):** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.
    *   **Minting:** `mintInitialEssence`.
    *   **State Queries:** `getEssenceState`, `getEssenceAura`, `getEssenceEP`, `getEssenceTraits`, `getTraitDetails`, `getAttunementState`, `getEphemeralStateDetails`.
    *   **EP Management:** `earnEP` (callable by authorized minters or external contracts), `spendEP`.
    *   **Decay/Maintenance:** `applyDecay` (callable by anyone, potentially batched or per-token to manage gas).
    *   **Lifecycle Transformations:** `synthesizeEssences`, `fragmentEssence`.
    *   **Trait Management:** `acquireTrait` (based on some condition), `removeTrait` (costs EP), `purgeAllTraits` (higher EP cost/cooldown).
    *   **Attunement (Staking):** `attuneEssence`, `detuneEssence`, `claimAttunementRewards`.
    *   **Resonance:** `applyResonanceInfluence` (triggered externally or by owner/governance).
    *   **Manifestation:** `manifestEphemeralState`.
    *   **Configuration Queries:** `getDecayRate`, `getSynthesisConfig`, `getFragmentationConfig`, `getAttunementConfig`.
    *   **Configuration Setters (Owner Only):** `setDecayRate`, `setSynthesisConfig`, `setFragmentationConfig`, `setAttunementConfig`, `defineTraitType`.
    *   **Global Events:** `triggerGlobalResonanceEvent` (Owner only).
    *   **Total Supply:** `getTotalEssences`.

**Function Summary:**

*   `constructor(string memory name_, string memory symbol_)`: Initializes the ERC721 token with a name and symbol, and sets the contract owner.
*   `mintInitialEssence()`: Mints a new AuraEssence token to the caller, initializing its state with base EP and aura.
*   `balanceOf(address owner) external view returns (uint256)`: ERC721 standard - Returns the number of tokens owned by an address.
*   `ownerOf(uint256 tokenId) external view returns (address)`: ERC721 standard - Returns the owner of a specific token.
*   `approve(address to, uint256 tokenId) external`: ERC721 standard - Approves an address to spend a specific token.
*   `getApproved(uint256 tokenId) external view returns (address)`: ERC721 standard - Returns the approved address for a token.
*   `setApprovalForAll(address operator, bool approved) external`: ERC721 standard - Sets approval for an operator to manage all of the owner's tokens.
*   `isApprovedForAll(address owner, address operator) external view returns (bool)`: ERC721 standard - Checks if an operator is approved for an owner.
*   `transferFrom(address from, address to, uint256 tokenId) external`: ERC721 standard - Transfers a token from one address to another (requires approval/ownership).
*   `safeTransferFrom(address from, address to, uint256 tokenId) external`: ERC721 standard - Safe transfer, includes receiver checks.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external`: ERC721 standard - Safe transfer with data.
*   `tokenURI(uint256 tokenId) public view override returns (string memory)`: ERC721 standard - Returns the URI pointing to the token's metadata. The metadata should dynamically reflect the Essence's state (Aura, EP, Traits).
*   `getEssenceState(uint256 tokenId) external view returns (uint256 ep, uint256 lastDecayTimestamp, Trait[] memory traits, uint256 attunedTimestamp, uint256 ephemeralStateEndTime, uint256 baseAura)`: Retrieves the full internal state of an Essence.
*   `getEssenceAura(uint256 tokenId) external view returns (uint256)`: Calculates and returns the current Aura value of an Essence, accounting for EP and Traits.
*   `getEssenceEP(uint256 tokenId) external view returns (uint256)`: Calculates and returns the current Essence Points (EP) of an Essence, applying decay up to the current time.
*   `getEssenceTraits(uint256 tokenId) external view returns (Trait[] memory)`: Returns the list of Traits currently active on an Essence.
*   `getTraitDetails(string memory traitName) external view returns (Trait memory)`: Retrieves the details of a specific available trait type.
*   `getAttunementState(uint256 tokenId) external view returns (uint256 attunedTimestamp)`: Checks if an Essence is attuned and when it started.
*   `getEphemeralStateDetails(uint256 tokenId) external view returns (uint256 ephemeralStateEndTime)`: Checks if an Essence is in an ephemeral state and when it ends.
*   `earnEP(uint256 tokenId, uint256 amount)`: Adds Essence Points to a specific token (might be permissioned).
*   `spendEP(uint256 tokenId, uint256 amount)`: Spends Essence Points from a specific token. Requires sufficient EP.
*   `applyDecay(uint256 tokenId)`: Triggers the application of time-based EP decay for a specific token. Can be called by anyone to update the state.
*   `synthesizeEssences(uint256[] memory tokenIds)`: Allows an owner to combine multiple owned Essences into a new one, burning the originals. The new Essence's state is derived from the inputs based on configured rules.
*   `fragmentEssence(uint256 tokenId, uint256 numFragments)`: Allows an owner to split an owned Essence into multiple new ones, burning the original. The new Essences share the original's properties based on configured rules.
*   `acquireTrait(uint256 tokenId, string memory traitName)`: Allows an Essence to gain a specific trait, potentially based on meeting certain conditions (e.g., sufficient EP, specific Aura level).
*   `removeTrait(uint256 tokenId, string memory traitName)`: Allows an owner to remove a non-permanent trait, potentially costing EP.
*   `purgeAllTraits(uint256 tokenId)`: Removes all non-permanent traits from an Essence, potentially costing significant EP or having a cooldown.
*   `attuneEssence(uint256 tokenId)`: Stakes an Essence, potentially pausing decay or enabling EP/reward accrual. Requires ownership.
*   `detuneEssence(uint256 tokenId)`: Unstakes an Essence. Rewards are calculated and potentially claimed/accrued upon detunement. Requires ownership.
*   `claimAttunementRewards(uint256 tokenId)`: Explicitly claims any accrued rewards from attunement (if not automatically handled on detune).
*   `applyResonanceInfluence(uint256 tokenId, string memory resonanceType, uint256 strength)`: Allows an authorized caller (e.g., owner or another protocol) to apply an external influence that modifies the Essence's state (EP, Aura, Traits) based on the resonance type and strength.
*   `manifestEphemeralState(uint256 tokenId)`: Spends EP to activate a temporary, powerful state on the Essence, often granting temporary traits or Aura boosts.
*   `getDecayRate() external view returns (uint256)`: Returns the current global EP decay rate.
*   `getSynthesisConfig() external view returns (SynthesisConfig memory)`: Returns the current configuration for synthesis.
*   `getFragmentationConfig() external view returns (FragmentationConfig memory)`: Returns the current configuration for fragmentation.
*   `getAttunementConfig() external view returns (uint256)`: Returns the current attunement rate (e.g., EP per hour per Aura point).
*   `setDecayRate(uint256 newRate)`: Owner-only - Sets the global EP decay rate.
*   `setSynthesisConfig(SynthesisConfig memory newConfig)`: Owner-only - Sets the rules for synthesis.
*   `setFragmentationConfig(FragmentationConfig memory newConfig)`: Owner-only - Sets the rules for fragmentation.
*   `setAttunementConfig(uint256 newRate)`: Owner-only - Sets the rate for attunement rewards/EP accrual.
*   `defineTraitType(string memory name, int256 epModifier, uint256 auraModifier, bool permanent, uint256 defaultExpiry)`: Owner-only - Defines a new type of trait that can be acquired by Essences.
*   `triggerGlobalResonanceEvent(string memory eventType, uint256 strength)`: Owner-only - Triggers a global event that might affect multiple Essences (implementation would likely iterate or use specific logic based on the event). (Note: Iterating over all tokens is gas-prohibitive; this would need a clever state update pattern or external trigger).
*   `getTotalEssences() external view returns (uint256)`: Returns the total number of Essences minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. Contract Definition: Inherits ERC721 and Ownable.
// 2. Structs: Trait, EssenceState, SynthesisConfig, FragmentationConfig.
// 3. State Variables: Mappings for EssenceState, counters, configs, available traits.
// 4. Events: Signalling state changes and lifecycle events.
// 5. Modifiers: Owner-only.
// 6. Constructor: Initializes ERC721 and Ownable.
// 7. ERC721 Overrides: _beforeTokenTransfer, tokenURI.
// 8. Internal/Helper Functions: _calculateCurrentEP, _calculateAura, _addTraitToEssence, _removeTraitFromEssence, _applyDecayLogic, _handleAttunementRewards, _performSynthesis, _performFragmentation, _generateNewEssenceState.
// 9. Public/External Functions (20+): Core ERC721, Minting, State Queries, EP Management, Decay/Maintenance, Lifecycle Transformations (Synthesize, Fragment), Trait Management, Attunement (Staking), Resonance, Manifestation, Configuration Queries/Setters, Global Events, Total Supply.

// Function Summary:
// constructor(string memory name_, string memory symbol_): Initializes the contract.
// mintInitialEssence(): Mints a new Essence token.
// balanceOf(address owner), ownerOf(uint256 tokenId), approve(...), getApproved(...), setApprovalForAll(...), isApprovedForAll(...), transferFrom(...), safeTransferFrom(...), safeTransferFrom(bytes data...): Standard ERC721 functions.
// tokenURI(uint256 tokenId): Returns URI for dynamic metadata.
// getEssenceState(uint256 tokenId): Retrieves detailed internal state.
// getEssenceAura(uint256 tokenId): Calculates and returns current Aura.
// getEssenceEP(uint256 tokenId): Calculates and returns current EP with decay applied.
// getEssenceTraits(uint256 tokenId): Returns list of traits.
// getTraitDetails(string memory traitName): Returns definition of a trait type.
// getAttunementState(uint256 tokenId): Checks attunement status.
// getEphemeralStateDetails(uint256 tokenId): Checks ephemeral state status.
// earnEP(uint256 tokenId, uint256 amount): Adds EP (permissioned).
// spendEP(uint256 tokenId, uint256 amount): Spends EP.
// applyDecay(uint256 tokenId): Triggers decay calculation for a token.
// synthesizeEssences(uint256[] memory tokenIds): Merges multiple Essences.
// fragmentEssence(uint256 tokenId, uint256 numFragments): Splits an Essence.
// acquireTrait(uint256 tokenId, string memory traitName): Adds a trait.
// removeTrait(uint256 tokenId, string memory traitName): Removes a trait (costs EP).
// purgeAllTraits(uint256 tokenId): Removes all non-permanent traits (costs EP).
// attuneEssence(uint256 tokenId): Stakes an Essence.
// detuneEssence(uint256 tokenId): Unstakes an Essence and handles rewards.
// claimAttunementRewards(uint256 tokenId): Claims accrued rewards.
// applyResonanceInfluence(uint256 tokenId, string memory resonanceType, uint256 strength): Applies external influence to a token.
// manifestEphemeralState(uint256 tokenId): Activates a temporary power-up.
// getDecayRate(): Returns current decay rate.
// getSynthesisConfig(): Returns synthesis rules.
// getFragmentationConfig(): Returns fragmentation rules.
// getAttunementConfig(): Returns attunement rate.
// setDecayRate(uint256 newRate): Owner-only: Sets decay rate.
// setSynthesisConfig(SynthesisConfig memory newConfig): Owner-only: Sets synthesis rules.
// setFragmentationConfig(FragmentationConfig memory newConfig): Owner-only: Sets fragmentation rules.
// setAttunementConfig(uint256 newRate): Owner-only: Sets attunement rate.
// defineTraitType(string memory name, int256 epModifier, uint256 auraModifier, bool permanent, uint256 defaultExpiry): Owner-only: Defines a new trait type.
// triggerGlobalResonanceEvent(string memory eventType, uint256 strength): Owner-only: Triggers a global event (Note: Direct iteration on all tokens is not feasible on-chain).
// getTotalEssences(): Returns total minted count.


contract AuraEssence is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant EP_PRECISION = 1e18; // For fractional EP if needed, here using integer for simplicity
    uint256 public constant MAX_EP = 1000 * EP_PRECISION; // Example cap

    struct Trait {
        string name;
        int256 epModifier; // EP change per time period or per action (can be negative)
        uint256 auraModifier; // Flat addition to Aura
        bool permanent;
        uint256 expiryTimestamp; // 0 if not temporary
    }

    struct EssenceState {
        uint256 ep; // Essence Points
        uint256 lastDecayTimestamp;
        Trait[] traits;
        uint256 attunedTimestamp; // 0 if not attuned
        uint256 ephemeralStateEndTime; // 0 if not in ephemeral state
        uint256 baseAura; // Base aura value, modified by EP and traits
    }

    mapping(uint256 => EssenceState) private _essenceStates;
    mapping(string => Trait) private _availableTraits; // Map trait name to its definition

    // --- Configuration ---
    uint256 public decayRatePerMinute = 1 * EP_PRECISION / 100; // Example: 1% EP decay per minute

    struct SynthesisConfig {
        uint256 minInputs;
        uint256 maxInputs;
        uint256 epCostPerInput;
        uint256 outputBaseAuraMultiplier; // e.g., 1000 = 1x sum of base auras
        uint256 outputEPMultiplier; // e.g., 800 = 80% sum of input EP
        uint256 traitInheritanceChance; // e.g., 5000 = 50% chance per non-permanent trait
    }
    SynthesisConfig public synthesisConfig = SynthesisConfig({
        minInputs: 2,
        maxInputs: 5,
        epCostPerInput: 50 * EP_PRECISION,
        outputBaseAuraMultiplier: 900, // 90% efficiency
        outputEPMultiplier: 750, // 75% efficiency
        traitInheritanceChance: 6000 // 60% chance
    });

    struct FragmentationConfig {
        uint256 minOutput;
        uint256 maxOutput;
        uint256 epCostPerOutput;
        uint256 outputBaseAuraDivisor; // e.g., 1000 = 1x base aura / num fragments
        uint256 outputEPDivisor; // e.g., 1000 = 1x EP / num fragments
        uint256 traitRetentionChance; // e.g., 7000 = 70% chance per trait on each fragment
    }
    FragmentationConfig public fragmentationConfig = FragmentationConfig({
        minOutput: 2,
        maxOutput: 4,
        epCostPerOutput: 30 * EP_PRECISION,
        outputBaseAuraDivisor: 1000, // Direct split
        outputEPDivisor: 1000, // Direct split
        traitRetentionChance: 5000 // 50% chance
    });

    uint256 public attunementEPPerHourPerAura = 10 * EP_PRECISION; // Example: 10 EP per hour for each point of Aura

    // Base URI for metadata (append token ID and potentially query parameters for state)
    string private _baseTokenURI;

    // --- Events ---
    event EssenceMinted(address indexed owner, uint256 indexed tokenId, uint256 initialEP, uint256 initialAura);
    event EssenceEPCalculated(uint256 indexed tokenId, uint256 newEP, uint256 oldEP, uint256 decayApplied);
    event EssenceEPChanged(uint256 indexed tokenId, uint256 oldEP, uint256 newEP, int256 difference, string reason);
    event TraitAcquired(uint256 indexed tokenId, string traitName, bool permanent, uint256 expiry);
    event TraitRemoved(uint256 indexed tokenId, string traitName);
    event EssenceAttuned(uint256 indexed tokenId, uint256 timestamp);
    event EssenceDetuned(uint256 indexed tokenId, uint256 timestamp, uint256 rewardsAccrued); // Rewards might be EP or other token
    event EssenceSynthesized(address indexed owner, uint256[] indexed inputTokenIds, uint256 indexed outputTokenId);
    event EssenceFragmented(address indexed owner, uint256 indexed inputTokenId, uint256[] indexed outputTokenIds);
    event ResonanceApplied(uint256 indexed tokenId, string resonanceType, uint256 strength, string effect);
    event EphemeralStateManifested(uint256 indexed tokenId, uint256 duration);

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
        // Define some initial traits as examples (Owner can define more later)
        _availableTraits["Hardy"] = Trait("Hardy", 0, 5, true, 0);
        _availableTraits["Volatile"] = Trait("Volatile", int256(-2 * EP_PRECISION), 0, false, 0); // Loses 2 EP per internal tick/decay period
        _availableTraits["Radiant"] = Trait("Radiant", int256(1 * EP_PRECISION), 10, false, 0); // Gains 1 EP per internal tick/decay period
        _availableTraits["Frail"] = Trait("Frail", int256(-1 * EP_PRECISION), 0, true, 0); // Loses 1 EP per internal tick/decay period
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates the current EP applying decay since the last update.
     * Also applies trait EP modifiers based on time/interactions.
     * Updates the last decay timestamp.
     * @param tokenId The ID of the Essence.
     * @return The calculated current EP.
     */
    function _calculateCurrentEP(uint256 tokenId) internal returns (uint256) {
        EssenceState storage state = _essenceStates[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - state.lastDecayTimestamp;

        if (timeElapsed == 0) {
            return state.ep;
        }

        // Apply decay
        if (state.attunedTimestamp == 0) { // Decay only applies if NOT attuned
            uint256 decayAmount = (state.ep * decayRatePerMinute * timeElapsed) / (60 * 1000); // decayRatePerMinute is rate / 100, so 1000 to handle precision
            uint256 oldEP = state.ep;
            state.ep = state.ep > decayAmount ? state.ep - decayAmount : 0;
             emit EssenceEPCalculated(tokenId, state.ep, oldEP, decayAmount);
        }

        // Apply time-based trait modifiers (simplified: apply once per interaction if time passed)
        for(uint i = 0; i < state.traits.length; i++) {
             if (state.traits[i].expiryTimestamp > 0 && currentTime >= state.traits[i].expiryTimestamp) {
                 // Handle expired traits - remove them later or mark as inactive
                 continue; // Skip applying modifier for expired traits
             }
            // This is a simplified model. A more complex model might apply modifiers based on timeElapsed
            // For simplicity here, we just apply decay based on time, and treat trait modifiers as static or action-based
            // A true time-based trait modifier would need more complex time tracking per trait or batch processing.
            // Let's assume epModifier in Trait is *not* per time for this version, but affects actions or base EP.
            // If epModifier *were* time based (e.g., per hour), you'd calculate `modifierAmount = state.traits[i].epModifier * timeElapsed / (1 hours)`
        }


        state.lastDecayTimestamp = currentTime;
        return state.ep;
    }

    /**
     * @dev Calculates the current Aura based on EP, baseAura, and Traits.
     * @param tokenId The ID of the Essence.
     * @return The calculated current Aura.
     */
    function _calculateAura(uint256 tokenId) internal view returns (uint256) {
        EssenceState storage state = _essenceStates[tokenId];
        uint256 currentEP = _essenceStates[tokenId].ep; // Use the state's EP, external calls should use getEssenceEP to apply decay first
        uint256 aura = state.baseAura; // Start with base aura

        // Aura is influenced by EP (example: 1 aura per 10 EP)
        aura += (currentEP / (10 * EP_PRECISION)); // Simple linear scaling

        // Apply trait aura modifiers
        for (uint i = 0; i < state.traits.length; i++) {
             if (state.traits[i].expiryTimestamp > 0 && block.timestamp >= state.traits[i].expiryTimestamp) {
                 continue; // Skip expired traits
             }
            aura += state.traits[i].auraModifier;
        }

        // Ensure Aura is not excessively high or low (optional caps)
        // aura = Math.min(aura, MAX_AURA); // Needs SafeMath or similar for min/max

        return aura;
    }

    /**
     * @dev Internal function to add a trait to an Essence. Handles uniqueness and expiry.
     * @param tokenId The ID of the Essence.
     * @param traitToAdd The Trait struct to add.
     */
    function _addTraitToEssence(uint256 tokenId, Trait memory traitToAdd) internal {
        EssenceState storage state = _essenceStates[tokenId];

        // Check if trait already exists (consider name + permanence/expiry for uniqueness)
        for (uint i = 0; i < state.traits.length; i++) {
            if (keccak256(bytes(state.traits[i].name)) == keccak256(bytes(traitToAdd.name)) &&
                state.traits[i].permanent == traitToAdd.permanent &&
                state.traits[i].expiryTimestamp == traitToAdd.expiryTimestamp) {
                // Trait already present, maybe refresh expiry if it's temporary?
                if (traitToAdd.expiryTimestamp > 0) {
                     state.traits[i].expiryTimestamp = traitToAdd.expiryTimestamp; // Refresh expiry
                }
                return; // Don't add duplicate permanent/non-expiring temporary trait
            }
        }

        state.traits.push(traitToAdd);
        emit TraitAcquired(tokenId, traitToAdd.name, traitToAdd.permanent, traitToAdd.expiryTimestamp);
    }

     /**
     * @dev Internal function to remove a trait from an Essence by name.
     * @param tokenId The ID of the Essence.
     * @param traitName The name of the trait to remove.
     * @return bool True if a trait was found and removed, false otherwise.
     */
    function _removeTraitFromEssence(uint256 tokenId, string memory traitName) internal returns (bool) {
        EssenceState storage state = _essenceStates[tokenId];
        bytes32 traitNameHash = keccak256(bytes(traitName));

        for (uint i = 0; i < state.traits.length; i++) {
            if (keccak256(bytes(state.traits[i].name)) == traitNameHash) {
                // Found the trait
                // Remove by swapping with last element and shrinking array
                state.traits[i] = state.traits[state.traits.length - 1];
                state.traits.pop();
                emit TraitRemoved(tokenId, traitName);
                return true;
            }
        }
        return false; // Trait not found
    }

    /**
     * @dev Applies decay and potentially other time-based state changes to a single token.
     * Can be called by anyone to update state, or triggered internally.
     * @param tokenId The ID of the Essence.
     */
    function _applyDecayLogic(uint256 tokenId) internal {
        // This function is mostly a wrapper now that _calculateCurrentEP handles decay on query/update.
        // However, it's useful if we want to trigger decay/state updates without a read/write.
        // Let's ensure _calculateCurrentEP is called to update the timestamp and EP.
        _calculateCurrentEP(tokenId);

        // Future: Could add checks for expired traits and remove them here
        // Need a mechanism to remove traits that have expired based on their expiryTimestamp
        uint currentTime = block.timestamp;
        uint j = 0;
        EssenceState storage state = _essenceStates[tokenId];
        for(uint i = 0; i < state.traits.length; i++) {
            if (state.traits[i].expiryTimestamp == 0 || currentTime < state.traits[i].expiryTimestamp) {
                // Keep this trait
                state.traits[j] = state.traits[i];
                j++;
            } else {
                // Trait expired, mark for removal
                 emit TraitRemoved(tokenId, state.traits[i].name);
            }
        }
        // Resize the array to remove expired traits
        while (state.traits.length > j) {
            state.traits.pop();
        }

        // Future: Could handle other time-based effects here (e.g., attunement yield calculation)
        // _handleAttunementRewards(tokenId); // Maybe this should be called on detune or claim
    }

    /**
     * @dev Calculates and applies attunement rewards (e.g., adds EP)
     * @param tokenId The ID of the Essence.
     */
    function _handleAttunementRewards(uint256 tokenId) internal {
        EssenceState storage state = _essenceStates[tokenId];
        uint256 currentTime = block.timestamp;

        if (state.attunedTimestamp > 0) {
            uint256 timeAttuned = currentTime - state.attunedTimestamp;
            uint256 currentAura = _calculateAura(tokenId); // Calculate Aura for reward basis

            // Calculate EP earned (Aura * rate * time / hours)
            // Avoid division by zero if rate is 0 or attunement time is 0
            uint256 epEarned = 0;
            if (attunementEPPerHourPerAura > 0 && timeAttuned > 0) {
                 epEarned = (currentAura * attunementEPPerHourPerAura * timeAttuned) / (1 hours); // Use 1 hours constant
            }

            if (epEarned > 0) {
                 uint256 oldEP = state.ep;
                 state.ep = state.ep + epEarned > MAX_EP ? MAX_EP : state.ep + epEarned; // Add earned EP, cap at MAX_EP
                 emit EssenceEPChanged(tokenId, oldEP, state.ep, int256(epEarned), "Attunement Reward");
            }

            // Reset attunement timestamp to current time for next calculation interval
            // Or set to 0 if this is part of detunement
            // Let's assume this is called on detune or claim, so we set to 0.
             state.attunedTimestamp = 0; // This should be handled by the detune/claim logic

            emit EssenceDetuned(tokenId, currentTime, epEarned); // Use this event on detune
        }
    }

     /**
     * @dev Internal logic for performing Synthesis. Assumes ownership and config checks done.
     * @param inputTokenIds The IDs of the tokens to synthesize.
     * @param owner The owner of the tokens.
     * @return The ID of the newly minted token.
     */
    function _performSynthesis(uint256[] memory inputTokenIds, address owner) internal returns (uint256) {
        uint256 totalInputEP = 0;
        uint256 totalInputBaseAura = 0;
        bytes32[] memory inheritedTraitHashes = new bytes32[](inputTokenIds.length * 10); // Max possible traits
        uint256 inheritedTraitCount = 0;

        // Collect data and burn input tokens
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            require(ownerOf(tokenId) == owner, "Not owner of all input tokens");

            EssenceState storage state = _essenceStates[tokenId];
            totalInputEP += _calculateCurrentEP(tokenId); // Use calculated EP after decay
            totalInputBaseAura += state.baseAura;

            // Inherit traits with a chance (only non-permanent ones for simplicity in synthesis)
             for (uint j = 0; j < state.traits.length; j++) {
                 if (!state.traits[j].permanent && state.traits[j].expiryTimestamp == 0) { // Consider only non-permanent, non-expiring traits
                      // Use a simple hash check to avoid exact struct comparison
                     bytes32 traitHash = keccak256(abi.encodePacked(state.traits[j].name, state.traits[j].epModifier, state.traits[j].auraModifier));
                     bool alreadyInherited = false;
                     for(uint k=0; k<inheritedTraitCount; k++){
                         if(inheritedTraitHashes[k] == traitHash){
                             alreadyInherited = true;
                             break;
                         }
                     }
                     if(!alreadyInherited && uint256(keccak256(abi.encodePacked(tokenId, i, j, block.timestamp, block.number))) % 10000 < synthesisConfig.traitInheritanceChance){
                          // Simple pseudo-randomness based on volatile data
                          inheritedTraitHashes[inheritedTraitCount] = traitHash;
                          inheritedTraitCount++;
                     }
                 }
             }


            _burn(tokenId); // Burn the input token
            delete _essenceStates[tokenId]; // Clear state
        }

        // Mint new token
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Calculate new state based on config multipliers
        uint256 newBaseAura = (totalInputBaseAura * synthesisConfig.outputBaseAuraMultiplier) / 1000;
        uint256 newEP = (totalInputEP * synthesisConfig.outputEPMultiplier) / 1000;

        // Generate initial state for the new token
        _essenceStates[newTokenId] = EssenceState({
            ep: newEP,
            lastDecayTimestamp: block.timestamp,
            traits: new Trait[](0), // Traits will be added below
            attunedTimestamp: 0,
            ephemeralStateEndTime: 0,
            baseAura: newBaseAura
        });

        // Add inherited traits to the new token
        for(uint i=0; i<inheritedTraitCount; i++){
            // Need to retrieve the full Trait struct from the hash - requires iterating through available traits
            // This approach with hashes is simplified. A better way is to store trait names directly or indices.
            // For simplicity here, let's assume we can reconstruct the trait or store trait names/indices.
            // Let's iterate through available traits to find a match for the hash (inefficient but works for example)
             for (bytes memory traitNameBytes : keys(_availableTraits)) { // Assuming a helper `keys` function exists or manually iterate
                 string memory traitName = string(traitNameBytes);
                 Trait memory availableTrait = _availableTraits[traitName];
                  bytes32 availableTraitHash = keccak256(abi.encodePacked(availableTrait.name, availableTrait.epModifier, availableTrait.auraModifier));
                  if(availableTraitHash == inheritedTraitHashes[i]){
                      // Found the trait definition, add a copy (make sure it's not permanent if synthesis logic says so)
                       Trait memory inheritedTrait = Trait(availableTrait.name, availableTrait.epModifier, availableTrait.auraModifier, false, 0); // Inherited traits from synthesis are non-permanent, non-expiring by this rule
                       _addTraitToEssence(newTokenId, inheritedTrait);
                       break; // Move to next hash
                  }
             }
        }


        _safeMint(owner, newTokenId);

        emit EssenceSynthesized(owner, inputTokenIds, newTokenId);
        emit EssenceMinted(owner, newTokenId, newEP, _calculateAura(newTokenId));

        return newTokenId;
    }

     // Helper to get keys of a mapping (inefficient on-chain, better off-chain or with an array)
     // For demonstration purposes only.
     function keys(mapping(string => Trait) storage _mapping) internal view returns (bytes[] memory) {
         bytes[] memory _keys = new bytes[](0); // Cannot dynamically size array efficiently
         // This requires iterating over *all possible strings* which is impossible.
         // A real implementation would need an array of trait names/indices alongside the mapping.
         revert("Mapping key iteration not supported efficiently");
     }


     /**
     * @dev Internal logic for performing Fragmentation. Assumes ownership and config checks done.
     * @param inputTokenId The ID of the token to fragment.
     * @param numFragments The number of tokens to create.
     * @param owner The owner of the token.
     * @return An array of the IDs of the newly minted tokens.
     */
    function _performFragmentation(uint256 inputTokenId, uint256 numFragments, address owner) internal returns (uint256[] memory) {
         require(ownerOf(inputTokenId) == owner, "Not owner of the token");

        EssenceState storage inputState = _essenceStates[inputTokenId];
        uint256 currentEP = _calculateCurrentEP(inputTokenId); // Use calculated EP after decay

        // Burn the input token
        _burn(inputTokenId);
        delete _essenceStates[inputTokenId]; // Clear state

        uint256[] memory newTokens = new uint256[](numFragments);
        uint256 baseAuraPerFragment = (inputState.baseAura * fragmentationConfig.outputBaseAuraDivisor) / (1000 * numFragments);
        uint256 epPerFragment = (currentEP * fragmentationConfig.outputEPDivisor) / (1000 * numFragments);


        for (uint i = 0; i < numFragments; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            newTokens[i] = newTokenId;

            // Generate initial state for the new token fragment
            _essenceStates[newTokenId] = EssenceState({
                ep: epPerFragment,
                lastDecayTimestamp: block.timestamp,
                traits: new Trait[](0), // Traits added below
                attunedTimestamp: 0,
                ephemeralStateEndTime: 0,
                baseAura: baseAuraPerFragment
            });

            // Retain traits with a chance for each fragment
             for (uint j = 0; j < inputState.traits.length; j++) {
                 // Use simple pseudo-randomness
                 if (uint256(keccak256(abi.encodePacked(inputTokenId, i, j, block.timestamp, block.number, owner))) % 10000 < fragmentationConfig.traitRetentionChance) {
                     // Add a copy of the trait to the fragment
                      _addTraitToEssence(newTokenId, inputState.traits[j]);
                 }
             }


            _safeMint(owner, newTokenId);

            emit EssenceMinted(owner, newTokenId, epPerFragment, _calculateAura(newTokenId));
        }

        emit EssenceFragmented(owner, inputTokenId, newTokens);
        return newTokens;
    }

     /**
     * @dev Generates the initial state for a new Essence token.
     * Used by minting, synthesis, fragmentation.
     * @param baseAura Initial base aura.
     * @param initialEP Initial EP.
     * @return The initialized EssenceState struct.
     */
    function _generateNewEssenceState(uint256 baseAura, uint256 initialEP) internal view returns (EssenceState memory) {
        // This function was planned, but state is currently initialized directly in mint/synth/fragment.
        // Keeping it as a placeholder for future refactoring if needed.
         return EssenceState({
            ep: initialEP,
            lastDecayTimestamp: block.timestamp,
            traits: new Trait[](0), // Start with no traits
            attunedTimestamp: 0,
            ephemeralStateEndTime: 0,
            baseAura: baseAura
        });
    }


    // --- ERC721 Overrides ---

    /**
     * @dev See {ERC721-tokenURI}.
     * Returns a URI that includes the token ID and can encode state parameters.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Append token ID to the base URI.
        // An off-chain service would serve the dynamic JSON metadata at this URL,
        // querying the contract's state (EP, Aura, Traits) via public functions.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Used to potentially handle state changes (like pausing attunement) upon transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != from) {
            // Handle state changes on transfer for individual token
            if (_essenceStates[tokenId].attunedTimestamp > 0) {
                 // Detune Essence automatically on transfer
                 // Need to be careful not to emit event or modify state too much in this hook
                 // A simple approach: just reset attunement timestamp, rewards are lost or accrue to *new* owner?
                 // Let's reset attunement timestamp and forfeit current potential rewards.
                 _essenceStates[tokenId].attunedTimestamp = 0;
                 // If complex reward calculation is needed, `detuneEssence` should be called *before* transfer by the old owner.
                 // For this example, resetting timestamp implies rewards calculation stops until re-attuned.
            }
             // Optionally, apply partial decay or other transfer penalties/bonuses
             _applyDecayLogic(tokenId); // Ensure decay is applied up to transfer time

             // If you transfer while in ephemeral state, does it persist? Let's say yes for simplicity.

        }
    }


    // --- Public/External Functions ---

    /**
     * @dev Mints a new initial AuraEssence token. Callable by owner or specific role.
     * @param to The address to mint the token to.
     * @param initialEP The initial Essence Points for the new token.
     * @param initialBaseAura The initial base Aura for the new token.
     */
    function mintInitialEssence(address to, uint256 initialEP, uint256 initialBaseAura) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _essenceStates[newTokenId] = EssenceState({
            ep: initialEP,
            lastDecayTimestamp: block.timestamp,
            traits: new Trait[](0),
            attunedTimestamp: 0,
            ephemeralStateEndTime: 0,
            baseAura: initialBaseAura
        });

        _safeMint(to, newTokenId);

        emit EssenceMinted(to, newTokenId, initialEP, initialBaseAura);
    }

    /**
     * @dev Gets the full current state of an Essence.
     * @param tokenId The ID of the Essence.
     * @return ep, lastDecayTimestamp, traits, attunedTimestamp, ephemeralStateEndTime, baseAura
     */
    function getEssenceState(uint256 tokenId) external view returns (uint256 ep, uint256 lastDecayTimestamp, Trait[] memory traits, uint256 attunedTimestamp, uint256 ephemeralStateEndTime, uint256 baseAura) {
         require(_exists(tokenId), "Essence does not exist");
         EssenceState storage state = _essenceStates[tokenId];
         // Note: This returns the *stored* EP and timestamp. Call getEssenceEP for calculated value.
         // Returning memory copy of traits is necessary for external calls.
         return (state.ep, state.lastDecayTimestamp, state.traits, state.attunedTimestamp, state.ephemeralStateEndTime, state.baseAura);
    }


    /**
     * @dev Calculates and returns the current Aura of an Essence. Applies decay before calculation.
     * @param tokenId The ID of the Essence.
     * @return The current Aura value.
     */
    function getEssenceAura(uint256 tokenId) external returns (uint256) {
        require(_exists(tokenId), "Essence does not exist");
        _applyDecayLogic(tokenId); // Apply decay before calculating Aura
        return _calculateAura(tokenId);
    }

    /**
     * @dev Calculates and returns the current Essence Points (EP) of an Essence. Applies decay.
     * @param tokenId The ID of the Essence.
     * @return The current EP value.
     */
    function getEssenceEP(uint256 tokenId) external returns (uint256) {
         require(_exists(tokenId), "Essence does not exist");
         _applyDecayLogic(tokenId); // Apply decay before returning EP
         return _essenceStates[tokenId].ep;
    }

     /**
     * @dev Returns the list of Traits currently active on an Essence.
     * @param tokenId The ID of the Essence.
     * @return An array of Trait structs.
     */
    function getEssenceTraits(uint256 tokenId) external view returns (Trait[] memory) {
         require(_exists(tokenId), "Essence does not exist");
         // Filter out expired traits before returning (view function, doesn't modify state)
         uint currentTime = block.timestamp;
         EssenceState storage state = _essenceStates[tokenId];
         uint validTraitCount = 0;
         for(uint i=0; i<state.traits.length; i++){
             if(state.traits[i].expiryTimestamp == 0 || currentTime < state.traits[i].expiryTimestamp){
                 validTraitCount++;
             }
         }

         Trait[] memory validTraits = new Trait[](validTraitCount);
         uint j = 0;
         for(uint i=0; i<state.traits.length; i++){
             if(state.traits[i].expiryTimestamp == 0 || currentTime < state.traits[i].expiryTimestamp){
                 validTraits[j] = state.traits[i];
                 j++;
             }
         }
         return validTraits;
    }

    /**
     * @dev Retrieves the definition of a specific available trait type.
     * @param traitName The name of the trait type.
     * @return The Trait struct definition.
     */
    function getTraitDetails(string memory traitName) external view returns (Trait memory) {
         require(_availableTraits[traitName].auraModifier != 0 || _availableTraits[traitName].epModifier != 0 || keccak256(bytes(_availableTraits[traitName].name)) == keccak256(bytes(traitName)), "Trait type not defined");
         return _availableTraits[traitName];
    }

    /**
     * @dev Checks if an Essence is attuned and returns the start timestamp.
     * @param tokenId The ID of the Essence.
     * @return The timestamp when attuned, or 0 if not attuned.
     */
    function getAttunementState(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Essence does not exist");
        return _essenceStates[tokenId].attunedTimestamp;
    }

    /**
     * @dev Checks if an Essence is in an ephemeral state and returns the end timestamp.
     * @param tokenId The ID of the Essence.
     * @return The timestamp when the ephemeral state ends, or 0 if not active.
     */
    function getEphemeralStateDetails(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Essence does not exist");
         return _essenceStates[tokenId].ephemeralStateEndTime;
    }


    /**
     * @dev Adds Essence Points to a specific token.
     * Can be called by owner, or potentially another authorized contract (needs modifier/role).
     * @param tokenId The ID of the Essence.
     * @param amount The amount of EP to add (with EP_PRECISION).
     */
    function earnEP(uint256 tokenId, uint256 amount) public { // Consider making this permissioned
        require(_exists(tokenId), "Essence does not exist");
        // _applyDecayLogic(tokenId); // Apply decay before adding EP - done in getEssenceEP if called before
        uint256 oldEP = _essenceStates[tokenId].ep;
        _essenceStates[tokenId].ep = _essenceStates[tokenId].ep + amount > MAX_EP ? MAX_EP : _essenceStates[tokenId].ep + amount;
        emit EssenceEPChanged(tokenId, oldEP, _essenceStates[tokenId].ep, int256(amount), "Earn");
    }

    /**
     * @dev Spends Essence Points from a specific token. Requires sufficient EP.
     * @param tokenId The ID of the Essence.
     * @param amount The amount of EP to spend (with EP_PRECISION).
     */
    function spendEP(uint256 tokenId, uint256 amount) public { // Consider making this permissioned or restricted to owner
        require(_exists(tokenId), "Essence does not exist");
        // _applyDecayLogic(tokenId); // Apply decay before spending EP - done in getEssenceEP if called before
        require(_essenceStates[tokenId].ep >= amount, "Insufficient EP");
        uint256 oldEP = _essenceStates[tokenId].ep;
        _essenceStates[tokenId].ep -= amount;
        emit EssenceEPChanged(tokenId, oldEP, _essenceStates[tokenId].ep, - int256(amount), "Spend");
    }

    /**
     * @dev Public function to trigger decay calculation for a specific token.
     * Anyone can call this to update a token's EP based on elapsed time.
     * @param tokenId The ID of the Essence.
     */
    function applyDecay(uint256 tokenId) external {
         require(_exists(tokenId), "Essence does not exist");
         _applyDecayLogic(tokenId); // This handles the decay and timestamp update
    }


    /**
     * @dev Allows an owner to synthesize multiple Essences into one new, potentially stronger Essence.
     * Burns the input tokens. Costs EP based on config.
     * @param tokenIds The IDs of the tokens to synthesize.
     */
    function synthesizeEssences(uint256[] memory tokenIds) public {
        require(tokenIds.length >= synthesisConfig.minInputs && tokenIds.length <= synthesisConfig.maxInputs, "Invalid number of input tokens for synthesis");
        address currentOwner = _msgSender(); // Use _msgSender() for the caller

        // Check ownership and sufficient EP *before* burning
        uint256 requiredEPCost = tokenIds.length * synthesisConfig.epCostPerInput;
        // Calculate combined EP *after* decay for the check
        uint256 combinedCurrentEP = 0;
        for(uint i=0; i<tokenIds.length; i++){
            require(_exists(tokenIds[i]), "Input token does not exist");
            require(ownerOf(tokenIds[i]) == currentOwner, "Not owner of all input tokens");
             // Apply decay before calculating combined EP for cost check
             _applyDecayLogic(tokenIds[i]);
            combinedCurrentEP += _essenceStates[tokenIds[i]].ep;
        }
        require(combinedCurrentEP >= requiredEPCost, "Insufficient combined EP for synthesis cost");

        // Spend the required EP cost from the *combined* pool (conceptually)
        // Simple approach: Just deduct from the first token or require one "primary" token to hold the cost.
        // Or, distribute the cost. Let's simplify and require sufficient combined EP, but don't deduct from inputs before burning.
        // The deduction implicitly happens because the output starts with a reduced EP based on the multiplier.
        // If a direct cost is needed, one would need a mechanism to pay it *before* burning.
        // Alternative: Deduct cost from the EP of the *resulting* token. Let's do that.

        uint256 newEssenceId = _performSynthesis(tokenIds, currentOwner);

        // Deduct cost from the newly created Essence
         if (_essenceStates[newEssenceId].ep >= requiredEPCost) {
             uint256 oldEP = _essenceStates[newEssenceId].ep;
             _essenceStates[newEssenceId].ep -= requiredEPCost;
             emit EssenceEPChanged(newEssenceId, oldEP, _essenceStates[newEssenceId].ep, - int256(requiredEPCost), "Synthesis Cost");
         } else {
             // This case shouldn't happen if combined EP >= cost, but handle defensively
             // Cap EP at 0 if cost exceeds starting EP (shouldn't happen with logic above)
              _essenceStates[newEssenceId].ep = 0;
               emit EssenceEPChanged(newEssenceId, 0, 0, 0, "Synthesis Cost (Capped)"); // Log 0 change if it goes to 0
         }

    }

    /**
     * @dev Allows an owner to fragment an Essence into multiple weaker Essences.
     * Burns the input token. Costs EP based on config.
     * @param tokenId The ID of the token to fragment.
     * @param numFragments The number of tokens to create from the original.
     */
    function fragmentEssence(uint256 tokenId, uint256 numFragments) public {
        require(_exists(tokenId), "Essence does not exist");
        require(numFragments >= fragmentationConfig.minOutput && numFragments <= fragmentationConfig.maxOutput, "Invalid number of output fragments");
        address currentOwner = _msgSender(); // Use _msgSender() for the caller
        require(ownerOf(tokenId) == currentOwner, "Not owner of the token");

         // Apply decay before checking EP
         _applyDecayLogic(tokenId);

        uint256 requiredEPCost = numFragments * fragmentationConfig.epCostPerOutput;
        require(_essenceStates[tokenId].ep >= requiredEPCost, "Insufficient EP for fragmentation cost");

        // Deduct cost *before* fragmentation
        uint256 oldEP = _essenceStates[tokenId].ep;
        _essenceStates[tokenId].ep -= requiredEPCost;
        emit EssenceEPChanged(tokenId, oldEP, _essenceStates[tokenId].ep, - int256(requiredEPCost), "Fragmentation Cost");

        _performFragmentation(tokenId, numFragments, currentOwner);
    }

     /**
     * @dev Allows an Essence to acquire a specific trait.
     * Conditions for acquiring might involve EP level, Aura, other traits, or external calls.
     * Costs EP based on trait definition or global config (not implemented in Trait struct here).
     * @param tokenId The ID of the Essence.
     * @param traitName The name of the trait to acquire.
     */
    function acquireTrait(uint256 tokenId, string memory traitName) public {
        require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");
        require(_availableTraits[traitName].auraModifier != 0 || _availableTraits[traitName].epModifier != 0 || keccak256(bytes(_availableTraits[traitName].name)) == keccak256(bytes(traitName)), "Trait type not defined"); // Check if trait name exists in available traits

        // Example condition: Requires minimum EP and Aura to acquire "Radiant"
        // _applyDecayLogic(tokenId); // Apply decay
        // uint256 currentAura = _calculateAura(tokenId);
        // uint256 currentEP = _essenceStates[tokenId].ep;
        // if (keccak256(bytes(traitName)) == keccak256(bytes("Radiant"))) {
        //     require(currentEP >= 500 * EP_PRECISION && currentAura >= 50, "Requires high EP and Aura to acquire Radiant");
        // }

        // Apply trait cost if any (not modeled in Trait struct, but could be a separate config)
        // Example: require EP cost
        // uint256 acquisitionCost = 100 * EP_PRECISION; // Example flat cost
        // spendEP(tokenId, acquisitionCost); // Call spendEP internally (applies decay implicitly)

        // Add the trait to the Essence's state
         Trait memory traitDefinition = _availableTraits[traitName];
         // Create a copy to add to the instance's state
         Trait memory instanceTrait = Trait({
             name: traitDefinition.name,
             epModifier: traitDefinition.epModifier,
             auraModifier: traitDefinition.auraModifier,
             permanent: traitDefinition.permanent,
             expiryTimestamp: traitDefinition.expiryTimestamp // Use default expiry from definition
         });

        _addTraitToEssence(tokenId, instanceTrait);
         // Event already emitted in _addTraitToEssence
    }

    /**
     * @dev Allows an owner to remove a non-permanent trait from an Essence. Costs EP.
     * @param tokenId The ID of the Essence.
     * @param traitName The name of the trait to remove.
     */
    function removeTrait(uint256 tokenId, string memory traitName) public {
        require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");

         // Check if the trait exists on the essence and is not permanent
         EssenceState storage state = _essenceStates[tokenId];
         bool foundAndRemovable = false;
         for(uint i=0; i<state.traits.length; i++){
             if(keccak256(bytes(state.traits[i].name)) == keccak256(bytes(traitName))){
                 require(!state.traits[i].permanent, "Cannot remove permanent trait");
                 foundAndRemovable = true;
                 break;
             }
         }
         require(foundAndRemovable, "Trait not found or is permanent");

        // Example cost to remove a trait
        uint256 removalCost = 50 * EP_PRECISION; // Example flat cost
        spendEP(tokenId, removalCost); // Call spendEP (applies decay implicitly)

        _removeTraitFromEssence(tokenId, traitName);
        // Event emitted in _removeTraitFromEssence
    }

     /**
     * @dev Removes all non-permanent traits from an Essence. Costs significant EP.
     * @param tokenId The ID of the Essence.
     */
    function purgeAllTraits(uint256 tokenId) public {
         require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");

         // Example cost to purge all traits
        uint256 purgeCost = 200 * EP_PRECISION; // Example high flat cost
        spendEP(tokenId, purgeCost); // Call spendEP (applies decay implicitly)

        EssenceState storage state = _essenceStates[tokenId];
        uint j = 0;
        // Keep only permanent traits
        for(uint i=0; i<state.traits.length; i++){
            if(state.traits[i].permanent){
                state.traits[j] = state.traits[i];
                j++;
            } else {
                 emit TraitRemoved(tokenId, state.traits[i].name);
            }
        }
         // Resize the array
        while (state.traits.length > j) {
            state.traits.pop();
        }
    }


    /**
     * @dev Stakes an Essence token, marking it as Attuned. Pauses decay and enables potential reward accrual.
     * @param tokenId The ID of the Essence.
     */
    function attuneEssence(uint256 tokenId) public {
        require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");
        require(_essenceStates[tokenId].attunedTimestamp == 0, "Essence is already attuned");

        // Apply decay before attuning
        _applyDecayLogic(tokenId);

        _essenceStates[tokenId].attunedTimestamp = block.timestamp;
        emit EssenceAttuned(tokenId, block.timestamp);
    }

    /**
     * @dev Unstakes an Attuned Essence token. Calculates and potentially provides rewards.
     * @param tokenId The ID of the Essence.
     */
    function detuneEssence(uint256 tokenId) public {
        require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");
        require(_essenceStates[tokenId].attunedTimestamp > 0, "Essence is not attuned");

        // Handle attunement rewards calculation and state update
        _handleAttunementRewards(tokenId); // This sets attunedTimestamp to 0 and emits event
    }

     /**
     * @dev Explicitly claims accrued attunement rewards without detuning (if applicable).
     * Reward model could be complex - e.g., claimable EP, or another token.
     * For simplicity, let's make detune the only way to claim EP rewards.
     * Keeping this function as a placeholder if a separate claim logic is desired.
     * @param tokenId The ID of the Essence.
     */
    function claimAttunementRewards(uint256 tokenId) public {
        require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");
         // This function is a placeholder. In this model, rewards are calculated and added on detune.
         // If a separate 'claim' model were used (e.g., ERC20 token rewards), the logic would go here.
         revert("Rewards are claimed upon detunement in this version.");
    }


    /**
     * @dev Applies an external 'Resonance' influence to a specific Essence.
     * This could be called by another contract, a trusted oracle, or governance.
     * The effect depends on the resonanceType and strength.
     * @param tokenId The ID of the Essence.
     * @param resonanceType A string describing the type of resonance (e.g., "SolarFlare", "LunarAlignment").
     * @param strength A parameter influencing the effect magnitude.
     */
    function applyResonanceInfluence(uint256 tokenId, string memory resonanceType, uint256 strength) public { // Consider making this permissioned/role-based
        require(_exists(tokenId), "Essence does not exist");

        // Apply decay before applying resonance
        _applyDecayLogic(tokenId);
        EssenceState storage state = _essenceStates[tokenId];
        string memory effectDescription = "No effect";

        // Example logic based on resonance type
        if (keccak256(bytes(resonanceType)) == keccak256(bytes("SolarFlare"))) {
            // SolarFlare might temporarily increase Aura and consume EP
             uint256 epCost = strength * EP_PRECISION / 10; // Example cost
             if (state.ep >= epCost) {
                 state.ep -= epCost;
                 state.baseAura += strength / 5; // Temporary Aura boost (how to make it temporary?)
                 effectDescription = "EP consumed, temporary Aura boost";
                 // To make Aura boost temporary, you'd add a temporary trait or use the ephemeral state mechanism.
                  Trait memory tempAuraBoost = Trait("SolarAuraBoost", 0, strength / 5, false, block.timestamp + 1 hours); // Example: Lasts 1 hour
                 _addTraitToEssence(tokenId, tempAuraBoost);
             } else {
                 // Insufficient EP effect: maybe reduced Aura?
                 state.baseAura = state.baseAura > strength / 10 ? state.baseAura - strength / 10 : 0;
                 effectDescription = "Insufficient EP, Aura decreased";
             }
             emit EssenceEPChanged(tokenId, state.ep + epCost, state.ep, - int256(epCost), "Resonance: SolarFlare Cost"); // Log cost before state update
             emit EssenceEPChanged(tokenId, state.ep, state.ep, 0, "Resonance: SolarFlare"); // Log resonance application
        } else if (keccak256(bytes(resonanceType)) == keccak256(bytes("LunarAlignment"))) {
             // LunarAlignment might increase EP over time and add a passive trait
             uint256 epGain = strength * EP_PRECISION; // Example EP gain
             state.ep = state.ep + epGain > MAX_EP ? MAX_EP : state.ep + epGain;
             effectDescription = "EP gained, new passive trait";
             // Add a Lunar trait (assuming it's defined)
             if(_availableTraits["LunarGrace"].auraModifier != 0 || _availableTraits["LunarGrace"].epModifier != 0 || keccak256(bytes(_availableTraits["LunarGrace"].name)) == keccak256(bytes("LunarGrace"))){
                 Trait memory lunarTrait = _availableTraits["LunarGrace"];
                 _addTraitToEssence(tokenId, lunarTrait);
             } else {
                  effectDescription = "EP gained"; // Trait not defined
             }
              emit EssenceEPChanged(tokenId, state.ep - epGain, state.ep, int256(epGain), "Resonance: LunarAlignment");
        }
        // ... add more resonance types ...

        emit ResonanceApplied(tokenId, resonanceType, strength, effectDescription);
    }

    /**
     * @dev Spends EP to activate a temporary, powerful state on the Essence.
     * Grants temporary traits or boosts for a limited duration.
     * @param tokenId The ID of the Essence.
     */
    function manifestEphemeralState(uint256 tokenId) public {
        require(_exists(tokenId), "Essence does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not owner of the token");
        require(_essenceStates[tokenId].ephemeralStateEndTime <= block.timestamp, "Ephemeral state is already active"); // Check if already active

        // Apply decay before checking EP
        _applyDecayLogic(tokenId);

        uint256 cost = 300 * EP_PRECISION; // Example cost
        uint256 duration = 2 hours; // Example duration

        require(_essenceStates[tokenId].ep >= cost, "Insufficient EP to manifest");

        spendEP(tokenId, cost); // Spend EP (applies decay implicitly)

        _essenceStates[tokenId].ephemeralStateEndTime = block.timestamp + duration;

        // Add temporary traits or apply temporary boosts
        // Example: Add a temporary trait "EmpoweredAura"
         if(_availableTraits["EmpoweredAura"].auraModifier != 0 || _availableTraits["EmpoweredAura"].epModifier != 0 || keccak256(bytes(_availableTraits["EmpoweredAura"].name)) == keccak256(bytes("EmpoweredAura"))){
             Trait memory empoweredTrait = _availableTraits["EmpoweredAura"];
              // Create a temporary instance of the trait
             Trait memory tempEmpowered = Trait({
                 name: empoweredTrait.name,
                 epModifier: empoweredTrait.epModifier,
                 auraModifier: empoweredTrait.auraModifier,
                 permanent: false, // Explicitly non-permanent for ephemeral state
                 expiryTimestamp: _essenceStates[tokenId].ephemeralStateEndTime // Link expiry to ephemeral state end
             });
            _addTraitToEssence(tokenId, tempEmpowered);
         } else {
              // If trait not defined, just apply an aura boost for the duration (less ideal)
              // This requires _calculateAura to check ephemeralStateEndTime, which is more complex.
              // Sticking to temporary traits linked to expiryTimestamp is cleaner.
              // For now, if trait isn't defined, manifestation just spends EP and sets timer.
         }


        emit EphemeralStateManifested(tokenId, duration);
    }

    // --- Configuration Queries ---

    function getDecayRate() external view returns (uint256) {
        return decayRatePerMinute;
    }

    function getSynthesisConfig() external view returns (SynthesisConfig memory) {
        return synthesisConfig;
    }

    function getFragmentationConfig() external view returns (FragmentationConfig memory) {
        return fragmentationConfig;
    }

    function getAttunementConfig() external view returns (uint256) {
        return attunementEPPerHourPerAura;
    }


    // --- Configuration Setters (Owner Only) ---

    function setDecayRate(uint256 newRate) public onlyOwner {
        decayRatePerMinute = newRate;
    }

    function setSynthesisConfig(SynthesisConfig memory newConfig) public onlyOwner {
        synthesisConfig = newConfig;
    }

    function setFragmentationConfig(FragmentationConfig memory newConfig) public onlyOwner {
        fragmentationConfig = newConfig;
    }

    function setAttunementConfig(uint256 newRate) public onlyOwner {
        attunementEPPerHourPerAura = newRate;
    }

     /**
     * @dev Defines a new type of trait that Essences can acquire.
     * Only callable by the owner.
     * @param name The unique name of the trait.
     * @param epModifier How this trait affects EP (e.g., per time or per action).
     * @param auraModifier How this trait affects Aura.
     * @param permanent Is this trait permanent once acquired?
     * @param defaultExpiry Default duration if not permanent (0 for non-expiring temp traits).
     */
    function defineTraitType(string memory name, int256 epModifier, uint256 auraModifier, bool permanent, uint256 defaultExpiry) public onlyOwner {
        // Basic check to prevent overwriting unless intentional
         bytes32 nameHash = keccak256(bytes(name));
         // Consider adding a check if trait name already exists and requiring explicit overwrite flag

        _availableTraits[name] = Trait(name, epModifier, auraModifier, permanent, defaultExpiry);
        // No event needed, this is just defining a type.
    }

     /**
     * @dev Allows the owner to trigger a global resonance event.
     * NOTE: Directly iterating over all tokens on-chain is gas-prohibitive.
     * A practical implementation would require an off-chain process or a mechanism
     * where tokens are affected when they are *interacted* with after the event timestamp.
     * This function is a simplified representation.
     * @param eventType The type of global event.
     * @param strength The magnitude of the event.
     */
    function triggerGlobalResonanceEvent(string memory eventType, uint256 strength) public onlyOwner {
        // Example: A global event increases base Aura of all *unattuned* Essences by `strength` for 24 hours
        // Implementing this directly is not feasible.
        // Alternative: Store the event details and have `_calculateAura` check for active global events
        // and apply modifiers based on the event timestamp and type.
        // This would require storing global event state.
        // For now, this function is just a placeholder event emitter.
         emit ResonanceApplied(0, eventType, strength, "Global Event Triggered (Effect applied on interaction)"); // Use tokenID 0 for global
    }


    /**
     * @dev Returns the total number of Essences minted.
     * @return The total count.
     */
    function getTotalEssences() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Required overrides for ERC721
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ERC721).interfaceId || super.supportsInterface(interfaceId);
    }

     // The internal `keys` helper function is illustrative but impractical.
     // A real-world scenario would need an array of trait names/hashes or similar pattern
     // to iterate through defined trait types on-chain if needed, or rely on off-chain lookups.
     // Added a dummy revert to prevent accidental use.

}
```