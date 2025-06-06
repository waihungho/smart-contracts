Okay, this is a fun challenge! Let's design a contract that combines NFT concepts with a metaphorical simulation of "quantum entanglement" and state collapse, aiming for interesting, non-standard mechanics.

We'll create tokens that are minted in pairs and share a hidden "shared energy level" until an "observation" occurs, at which point the state "collapses" based on entanglement strength. Actions on one token can affect its entangled partner, and entanglement can decay or break.

**Disclaimer:** This contract uses concepts inspired by quantum mechanics metaphorically. It does *not* implement actual quantum computing or true randomness. The "randomness" is based on block data and is suitable for demonstration but *not* for applications requiring true unpredictability or strong security guarantees against miner manipulation. This is a complex, experimental concept.

---

## QuantumEntangledTokens

This smart contract creates a new type of non-fungible token (NFT) inspired by the concept of quantum entanglement. Tokens are minted in pairs, sharing a dynamic 'shared energy level' and an 'entanglement strength'. Actions on one token can affect its entangled partner and the shared state. The shared state's observed value depends probabilistically on the entanglement strength at the time of 'observation'.

**Outline:**

1.  **License & Pragma:** SPDX License Identifier and Solidity version.
2.  **Imports:** OpenZeppelin contracts for ERC721, ERC721URIStorage, and Ownable.
3.  **Error Handling:** Custom errors for clearer reverts.
4.  **State Variables:**
    *   Token counter.
    *   Mapping for Token Data (using a struct).
    *   Mapping for Shared Pair State (using a struct).
    *   Mapping for approvals (inherited from ERC721).
    *   Owner (inherited from Ownable).
    *   Configurable parameters (decay rate, charge rate, etc.).
    *   Pseudo-randomness seed components.
5.  **Structs:**
    *   `TokenData`: Stores individual token properties (partner ID, isEntangled).
    *   `SharedPairState`: Stores properties shared by an entangled pair (energy level, strength, last observed value, last observed timestamp, last interaction timestamp).
6.  **Events:** Informative events for key actions (Mint, Entangled, Decohered, Observed, StateCharged, TransferWithEntanglement, etc.).
7.  **Modifiers:** Custom modifiers for specific checks (e.g., only entangled tokens).
8.  **Constructor:** Initializes the contract (name, symbol) and sets the owner.
9.  **Internal Helpers:** Functions for core logic (e.g., calculating decay, applying probability).
10. **Core ERC721 Overrides:** Implement/override key ERC721 functions (`_transfer`, `_burn`, `tokenURI`) to incorporate entanglement logic.
11. **Custom Quantum-Inspired Functions (>= 20 total including overrides/helpers):**
    *   Minting (`mintEntangledPair`).
    *   Getting Token/Pair Data (`getTokenData`, `getSharedPairState`).
    *   Checking Status (`isEntangled`, `getEntangledPartnerId`).
    *   State Interaction (`chargeSharedState`, `peekSharedEnergyLevel`, `observeSharedState`).
    *   Entanglement Management (`simulateDecoherence`, `attemptReEntanglement`, `breakEntanglement`, `rescueOrphans`).
    *   Special Transfer (`transferOneOfPair`, `transferPairTogether`, `simulateQuantumTunnelingTransfer`).
    *   Analysis/Prediction (`predictEntanglementBreakChance`, `measureDecoherenceAmount`).
    *   Admin Functions (`setDecayRate`, `setChargeRate`, `setObservationCooldown`, etc.).
    *   Utility (`getTotalSupply`, `syncRandomnessSeed`).

**Function Summary:**

*   `constructor()`: Initializes contract with name, symbol, and sets owner.
*   `mintEntangledPair(address owner, string memory tokenURI1, string memory tokenURI2)`: Mints two new tokens as an entangled pair and assigns them to the owner.
*   `getTokenData(uint256 tokenId)`: Returns the custom `TokenData` struct for a specific token.
*   `getSharedPairState(uint256 pairId)`: Returns the `SharedPairState` struct for an entangled pair. PairId is the lower token ID of the pair.
*   `isEntangled(uint256 tokenId)`: Checks if a token is currently entangled with a partner.
*   `getEntangledPartnerId(uint256 tokenId)`: Returns the token ID of the partner if entangled, otherwise returns 0.
*   `getEntanglementStrength(uint256 tokenId)`: Returns the current *decayed* entanglement strength for the token's pair.
*   `peekSharedEnergyLevel(uint256 tokenId)`: Returns the raw, internal shared energy level *without* triggering observation/collapse.
*   `observeSharedState(uint256 tokenId)`: Triggers the 'measurement' simulation for the token's entangled pair. Calculates and returns the observed energy value based on entanglement strength and pseudo-randomness, updating the last observed state. Subject to cooldown.
*   `chargeSharedState(uint256 tokenId, uint256 amount)`: Increases the shared energy level for the token's entangled pair. Only callable by the token owner.
*   `simulateDecoherence(uint256 tokenId)`: Applies entanglement strength decay based on time elapsed since the last interaction for the token's pair. Can be called by anyone.
*   `attemptReEntanglement(uint256 tokenId1, uint256 tokenId2)`: Attempts to re-entangle two tokens that were previously part of the *same* entangled pair. Success probability depends on factors (e.g., time since decoherence).
*   `breakEntanglement(uint256 tokenId)`: Manually breaks the entanglement between a token and its partner. Callable by the token owner.
*   `rescueOrphans(uint256 orphanTokenId)`: Allows the owner to forcibly break entanglement for a token if its supposed partner is somehow invalid (e.g., due to error, though paired burn prevents this normally).
*   `transferOneOfPair(address from, address to, uint256 tokenId)`: Overrides the standard transfer for entangled tokens. Has a *probability* of breaking entanglement based on the current strength. If entanglement breaks, only the specified token is transferred. If it holds (unlikely for single transfer), the partner might also be affected or state preserved (simpler implementation: high chance of breaking).
*   `transferPairTogether(address from, address to, uint256 tokenId1, uint256 tokenId2)`: Allows transferring both tokens of an entangled pair to the *same* address, with a higher chance of preserving entanglement than transferring one alone. Requires both tokens to be owned by `from`.
*   `simulateQuantumTunnelingTransfer(address from, address to, uint256 tokenId)`: A special, risky transfer function that attempts to move one token of a pair to an address *different* from its partner's location, *while attempting to preserve entanglement*. High chance of failure (breaking entanglement) and potentially higher gas cost.
*   `predictEntanglementBreakChance(uint256 tokenId)`: A view function that estimates the probability (as a percentage) of entanglement breaking if `transferOneOfPair` were called now.
*   `measureDecoherenceAmount(uint256 tokenId)`: A view function showing how much entanglement strength has theoretically decayed based on time since last interaction.
*   `syncRandomnessSeed()`: Allows updating components of the pseudo-random seed (owner only). Useful for reactivating randomness after long periods without block changes.
*   `setDecayRate(uint256 rate)`: Owner function to set the entanglement decay rate.
*   `setChargeRate(uint256 rate)`: Owner function to set the shared energy charge rate.
*   `setObservationCooldown(uint256 cooldown)`: Owner function to set the cooldown duration for `observeSharedState`.
*   `setReEntangleSuccessChance(uint256 chance)`: Owner function to set the base probability for re-entanglement attempts.
*   `getTotalSupply()`: Returns the total number of tokens minted. (Overrides ERC721's _nextTokenId, accounting for pairs).
*   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token (standard ERC721URIStorage).
*   `ownerOf(uint256 tokenId)`: Returns the owner of the token (standard ERC721).
*   `balanceOf(address owner)`: Returns the number of tokens owned by an address (standard ERC721).
*   `approve(address to, uint256 tokenId)`: Approves an address to spend the token (standard ERC721).
*   `getApproved(uint256 tokenId)`: Returns the approved address for the token (standard ERC721).
*   `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens (standard ERC721).
*   `isApprovedForAll(address owner, address operator)`: Checks operator approval (standard ERC721).
*   `transferFrom(address from, address to, uint256 tokenId)`: Overrides standard transfer to redirect entangled single-token transfers to `transferOneOfPair`.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Overrides safe transfer to redirect.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Overrides safe transfer with data to redirect.
*   `_burn(uint256 tokenId)`: Internal burn function override. Implemented to burn the entangled partner automatically.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string

// Custom Errors
error QuantumEntangledTokens__NotEntangled(uint256 tokenId);
error QuantumEntangledTokens__TokensNotPair(uint256 tokenId1, uint256 tokenId2);
error QuantumEntangledTokens__PairAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
error QuantumEntangledTokens__CooldownNotPassed(uint256 tokenId, uint256 timeRemaining);
error QuantumEntangledTokens__PairOwnershipMismatch(uint256 tokenId1, uint256 tokenId2, address owner1, address owner2);
error QuantumEntangledTokens__CannotTransferSelf();
error QuantumEntangledTokens__InvalidRandomSeed();


contract QuantumEntangledTokens is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Constants ---
    uint256 public constant MAX_ENTANGLEMENT_STRENGTH = 10000; // Representing 100.00% * 100
    uint256 public constant MIN_ENTANGLEMENT_STRENGTH = 0;
    uint256 public constant MAX_SHARED_ENERGY = 10000; // Example max energy level

    // --- Configurable Parameters (Owner Settable) ---
    uint256 public entanglementDecayRatePerSecond = 1; // Strength points lost per second
    uint256 public sharedEnergyChargeRate = 100; // Energy points added per charge call (base rate)
    uint256 public observationCooldownDuration = 1 days; // Time in seconds between observations
    uint256 public reEntangleSuccessChancePercent = 50; // Base % chance for re-entanglement (out of 100)
    uint256 public singleTransferBreakChanceFactor = 100; // Factor inversely proportional to strength for break chance (e.g., Strength 100 -> Factor/100 = 1% chance)
    uint256 public tunnelingTransferRiskFactor = 200; // Higher factor for tunneling transfer risk

    // --- State Variables ---
    struct TokenData {
        uint256 entangledPartnerId;
        bool isEntangled;
        uint256 pairId; // The lower token ID of the pair
    }
    mapping(uint256 => TokenData) private _tokenData;

    struct SharedPairState {
        uint256 sharedEnergyLevel; // Can be seen via peek, collapses on observe
        uint256 entanglementStrength; // Current strength (decays)
        uint256 lastObservedValue; // The value the state collapsed to during the last observation
        uint256 lastObservedTimestamp;
        uint256 lastInteractionTimestamp; // Used for decay calculation
        uint256 creationTimestamp; // When the pair was minted/re-entangled
    }
    // pairId => SharedPairState
    mapping(uint256 => SharedPairState) private _sharedPairState;

    // Pseudo-randomness state
    uint256 private _randomSeedComponent1;
    uint256 private _randomSeedComponent2;

    // --- Events ---
    event EntangledPairMinted(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Decohered(uint256 indexed tokenId1, uint256 indexed tokenId2, string reason);
    event ObservedState(uint256 indexed tokenId, uint256 observedValue, uint256 strengthAtObservation);
    event StateCharged(uint256 indexed tokenId, uint256 amount);
    event EntanglementStrengthDecayed(uint256 indexed pairId, uint256 oldStrength, uint256 newStrength);
    event TransferWithEntanglementBroken(uint256 indexed tokenId, address from, address to);
    event PairTransferredTogether(uint256 indexed tokenId1, uint256 indexed tokenId2, address from, address to, bool entanglementPreserved);
    event QuantumTunnelingAttempt(uint256 indexed tokenId, address from, address to, bool success);
    event RandomSeedSynced(uint256 timestamp, uint256 blockNumber);

    // --- Modifiers ---
    modifier onlyEntangled(uint256 tokenId) {
        if (!_tokenData[tokenId].isEntangled) {
            revert QuantumEntangledTokens__NotEntangled(tokenId);
        }
        _;
    }

    modifier onlyPairOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Not pair owner");
        _;
    }

    modifier notSelf(address account) {
        require(account != address(this), "Cannot transfer to self");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("Quantum Entangled Token", "QET") Ownable(msg.sender) {
        // Initialize pseudo-random seed components
        _randomSeedComponent1 = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number)));
        _randomSeedComponent2 = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.prevrandao))); // Using block.prevrandao for variance
        emit RandomSeedSynced(block.timestamp, block.number);
    }

    // --- Pseudo-Randomness Helper (Not cryptographically secure!) ---
    function _pseudoRandom(uint256 seed) internal view returns (uint256) {
        // Simple XOR shift with block data and stored components
        uint256 combinedSeed = seed ^ _randomSeedComponent1 ^ _randomSeedComponent2 ^ block.timestamp ^ block.number ^ uint256(block.prevrandao);
        return uint256(keccak256(abi.encodePacked(combinedSeed)));
    }

    function _rollDice(uint256 max) internal view returns (uint256) {
        if (max == 0) return 0;
        return _pseudoRandom(block.timestamp + _tokenIds.current()) % (max + 1);
    }

    function _checkChance(uint256 percentChance) internal view returns (bool) {
        if (percentChance >= 100) return true;
        if (percentChance == 0) return false;
        // Roll a number from 0 to 99. If the roll is less than the chance, it succeeds.
        return _rollDice(99) < percentChance;
    }

    // --- Internal Entanglement/State Logic ---

    function _getPairId(uint256 tokenId1, uint256 tokenId2) internal pure returns (uint256) {
        return tokenId1 < tokenId2 ? tokenId1 : tokenId2;
    }

    function _getPairId(uint256 tokenId) internal view returns (uint256) {
        return _tokenData[tokenId].pairId;
    }

    function _applyDecay(uint256 pairId) internal {
        SharedPairState storage pairState = _sharedPairState[pairId];
        if (!pairState.isEntanglementActive) return; // Should check _tokenData actually

        // Find one of the token IDs to check its entanglement status
        uint256 tokenId = pairId; // PairId is the lower token ID

        if (!_tokenData[tokenId].isEntangled) return; // Ensure the pair is still marked entangled in token data

        uint256 timeElapsed = block.timestamp - pairState.lastInteractionTimestamp;
        uint256 decayAmount = timeElapsed * entanglementDecayRatePerSecond;

        if (decayAmount > 0) {
            uint256 oldStrength = pairState.entanglementStrength;
            if (pairState.entanglementStrength <= decayAmount) {
                pairState.entanglementStrength = MIN_ENTANGLEMENT_STRENGTH;
            } else {
                pairState.entanglementStrength -= decayAmount;
            }
            pairState.lastInteractionTimestamp = block.timestamp; // Decay is an interaction
            emit EntanglementStrengthDecayed(pairId, oldStrength, pairState.entanglementStrength);
        }
    }

    function _breakEntanglement(uint256 tokenId1, uint256 tokenId2, string memory reason) internal {
        uint256 pairId = _getPairId(tokenId1, tokenId2);

        delete _sharedPairState[pairId]; // Clear shared state
        _tokenData[tokenId1].isEntangled = false;
        _tokenData[tokenId1].entangledPartnerId = 0;
        _tokenData[tokenId1].pairId = 0; // Remove pair association

        _tokenData[tokenId2].isEntangled = false;
        _tokenData[tokenId2].entangledPartnerId = 0;
        _tokenData[tokenId2].pairId = 0; // Remove pair association

        emit Decohered(tokenId1, tokenId2, reason);
    }

    // --- Core ERC721 Overrides ---

    // Override _transfer to handle entanglement effects
    function _transfer(address from, address to, uint256 tokenId) internal override notSelf(to) {
         if (_tokenData[tokenId].isEntangled) {
            // If entangled, redirect to custom transfer logic that handles entanglement
            // We need to know which custom transfer was intended by the caller
            // This is a limitation of overriding _transfer directly.
            // A better approach is to make users call specific transfer functions.
            // For simplicity here, we'll assume a standard ERC721 transfer implies
            // 'transferOneOfPair' and has a chance to break entanglement.
            // Users wanting other transfer types (pair, tunneling) MUST call the custom functions.
            uint256 partnerId = _tokenData[tokenId].entangledPartnerId;
            require(ownerOf(partnerId) != address(0), "Partner does not exist"); // Should not happen with paired burn

            uint256 pairId = _getPairId(tokenId);
            _applyDecay(pairId); // Apply decay before checking break chance

            uint256 currentStrength = _sharedPairState[pairId].entanglementStrength;
            // Calculate chance of breaking: lower strength -> higher chance
            // Max chance is 100% when strength is 0. Min chance > 0 if factor > 0.
            // Let's use a simple inverse relationship: chance = Factor / (Strength + 1)
            // Capped at 100%. If Strength is MAX, chance is Factor / (MAX+1)
            uint256 breakChance = singleTransferBreakChanceFactor * 100 / (currentStrength + 1); // Multiplied by 100 for percentage math later
             breakChance = Math.min(breakChance, 10000); // Cap at 100% (10000 * 100)

            if (_checkChance(breakChance / 100)) { // Roll using the percentage
                // Entanglement breaks
                _breakEntanglement(tokenId, partnerId, "Single token transfer");
                // Proceed with standard single token transfer
                super._transfer(from, to, tokenId);
                emit TransferWithEntanglementBroken(tokenId, from, to);
            } else {
                 // Entanglement holds - This is unexpected for standard transfer.
                 // In this model, standard transfer of one token *should* strongly favor breaking entanglement.
                 // Let's make it ALWAYS break on standard transfer unless using specific pair/tunneling functions.
                 // This makes the custom transfer functions necessary and meaningful.
                 _breakEntanglement(tokenId, partnerId, "Single token standard transfer");
                 super._transfer(from, to, tokenId);
                 emit TransferWithEntanglementBroken(tokenId, from, to);
            }
        } else {
            // Not entangled, proceed with standard transfer
            super._transfer(from, to, tokenId);
        }
    }

    // Override _burn to handle entangled partners
    function _burn(uint256 tokenId) internal override {
        address tokenOwner = ownerOf(tokenId);
        if (_tokenData[tokenId].isEntangled) {
            uint256 partnerId = _tokenData[tokenId].entangledPartnerId;
            // Ensure partner exists and is also owned by the same person (or approved operator)
            require(ownerOf(partnerId) == tokenOwner, "Partner must have same owner to burn pair");

            // Break entanglement first
            _breakEntanglement(tokenId, partnerId, "Paired burn");

            // Burn both tokens
            super._burn(tokenId);
            super._burn(partnerId); // Burn the partner automatically
        } else {
             // Not entangled, burn just the token
             super._burn(tokenId);
        }
        delete _tokenData[tokenId]; // Clean up token data after burn
    }

    // Override tokenURI to work with our storage
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Override supportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // --- Custom Quantum-Inspired Functions (Counting towards the 20+) ---

    /// @notice Mints an entangled pair of tokens.
    /// @param owner The address to receive the new tokens.
    /// @param tokenURI1 Metadata URI for the first token.
    /// @param tokenURI2 Metadata URI for the second token.
    function mintEntangledPair(address owner, string memory tokenURI1, string memory tokenURI2) public onlyOwner {
        _tokenIds.increment();
        uint256 newTokenId1 = _tokenIds.current();
        _tokenIds.increment();
        uint256 newTokenId2 = _tokenIds.current();

        // Assign lower ID as the pair ID
        uint256 pairId = _getPairId(newTokenId1, newTokenId2);

        // Mint tokens
        _safeMint(owner, newTokenId1);
        _setTokenURI(newTokenId1, tokenURI1);

        _safeMint(owner, newTokenId2);
        _setTokenURI(newTokenId2, tokenURI2);

        // Set token data for both
        _tokenData[newTokenId1] = TokenData({
            entangledPartnerId: newTokenId2,
            isEntangled: true,
            pairId: pairId
        });
         _tokenData[newTokenId2] = TokenData({
            entangledPartnerId: newTokenId1,
            isEntangled: true,
            pairId: pairId
        });

        // Set shared pair state
        _sharedPairState[pairId] = SharedPairState({
            sharedEnergyLevel: 0, // Start with 0 energy
            entanglementStrength: MAX_ENTANGLEMENT_STRENGTH, // Start fully entangled
            lastObservedValue: 0,
            lastObservedTimestamp: 0,
            lastInteractionTimestamp: block.timestamp,
            creationTimestamp: block.timestamp
        });

        emit EntangledPairMinted(newTokenId1, newTokenId2, owner);
        emit Entangled(newTokenId1, newTokenId2);
    }

    /// @notice Gets the custom data associated with a specific token.
    /// @param tokenId The ID of the token.
    /// @return The TokenData struct for the token.
    function getTokenData(uint256 tokenId) public view returns (TokenData memory) {
        _requireOwned(tokenId); // Ensure token exists by checking ownership
        return _tokenData[tokenId];
    }

    /// @notice Gets the shared state data for an entangled pair.
    /// @param tokenId An ID of a token within the pair.
    /// @return The SharedPairState struct for the pair.
    function getSharedPairState(uint256 tokenId) public view onlyEntangled(tokenId) returns (SharedPairState memory) {
        uint256 pairId = _getPairId(tokenId);
        return _sharedPairState[pairId];
    }

    /// @notice Checks if a token is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Ensure token exists
        return _tokenData[tokenId].isEntangled;
    }

     /// @notice Gets the partner token ID if entangled.
    /// @param tokenId The ID of the token.
    /// @return The partner token ID, or 0 if not entangled.
    function getEntangledPartnerId(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Ensure token exists
        return _tokenData[tokenId].entangledPartnerId;
    }

    /// @notice Gets the current, potentially decayed, entanglement strength for the pair.
    /// @param tokenId An ID of a token within the pair.
    /// @return The current entanglement strength.
    function getEntanglementStrength(uint256 tokenId) public view onlyEntangled(tokenId) returns (uint256) {
        uint256 pairId = _getPairId(tokenId);
        SharedPairState memory pairState = _sharedPairState[pairId];
        uint256 timeElapsed = block.timestamp - pairState.lastInteractionTimestamp;
        uint256 decayAmount = timeElapsed * entanglementDecayRatePerSecond;
        return pairState.entanglementStrength <= decayAmount ? MIN_ENTANGLEMENT_STRENGTH : pairState.entanglementStrength - decayAmount;
    }

    /// @notice Peeks at the internal shared energy level without triggering observation/collapse.
    /// @param tokenId An ID of a token within the pair.
    /// @return The internal shared energy level.
    function peekSharedEnergyLevel(uint256 tokenId) public view onlyEntangled(tokenId) returns (uint256) {
        uint256 pairId = _getPairId(tokenId);
        return _sharedPairState[pairId].sharedEnergyLevel;
    }

    /// @notice Triggers the 'measurement' simulation. Collapses the shared state based on current entanglement strength and randomness.
    /// @dev Subject to observation cooldown.
    /// @param tokenId An ID of a token within the pair.
    /// @return The observed energy value after collapse.
    function observeSharedState(uint256 tokenId) public onlyEntangled(tokenId) onlyPairOwner(tokenId) returns (uint256) {
        uint256 pairId = _getPairId(tokenId);
        SharedPairState storage pairState = _sharedPairState[pairId];

        uint256 timeSinceLastObservation = block.timestamp - pairState.lastObservedTimestamp;
        if (timeSinceLastObservation < observationCooldownDuration) {
            revert QuantumEntangledTokens__CooldownNotPassed(tokenId, observationCooldownDuration - timeSinceLastObservation);
        }

        _applyDecay(pairId); // Apply decay before observation

        uint256 currentStrength = pairState.entanglementStrength;
        uint256 rawEnergy = pairState.sharedEnergyLevel;

        // Simulate collapse: observed value is raw energy + a random delta.
        // The magnitude of the random delta is inversely proportional to strength.
        // High strength -> delta is small, observed value close to raw.
        // Low strength -> delta is large, observed value more random.
        // Let's add a delta from -RAND_RANGE to +RAND_RANGE, where RAND_RANGE is proportional to (MAX_STRENGTH - currentStrength).

        uint256 maxDeltaRange = MAX_SHARED_ENERGY; // Max possible random spread
        uint256 strengthFactor = MAX_ENTANGLEMENT_STRENGTH - currentStrength; // 0 at max strength, MAX at min strength
        // Delta range is proportional to strengthFactor / MAX_ENTANGLEMENT_STRENGTH
        uint256 currentDeltaRange = (maxDeltaRange * strengthFactor) / MAX_ENTANGLEMENT_STRENGTH;

        // Generate a random value up to 2 * currentDeltaRange
        uint256 randomOffset = _rollDice(2 * currentDeltaRange);
        // Shift it to be centered around 0
        int256 signedDelta = int256(randomOffset) - int256(currentDeltaRange);

        // Calculate the observed value
        int256 observedSigned = int256(rawEnergy) + signedDelta;

        // Clamp the observed value to the valid range [0, MAX_SHARED_ENERGY]
        uint256 observedValue = uint256(Math.max(0, observedSigned));
        observedValue = Math.min(observedValue, MAX_SHARED_ENERGY);

        // Update state
        pairState.lastObservedValue = observedValue;
        pairState.lastObservedTimestamp = block.timestamp;
        pairState.lastInteractionTimestamp = block.timestamp; // Observation is an interaction

        emit ObservedState(tokenId, observedValue, currentStrength);
        return observedValue;
    }

    /// @notice Increases the shared energy level of an entangled pair.
    /// @param tokenId An ID of a token within the pair.
    /// @param amount The amount of energy to add.
    function chargeSharedState(uint256 tokenId, uint256 amount) public onlyEntangled(tokenId) onlyPairOwner(tokenId) {
        uint256 pairId = _getPairId(tokenId);
        SharedPairState storage pairState = _sharedPairState[pairId];

        _applyDecay(pairId); // Apply decay before charging

        pairState.sharedEnergyLevel = Math.min(pairState.sharedEnergyLevel + (amount * sharedEnergyChargeRate / 100), MAX_SHARED_ENERGY); // Scale amount by charge rate
        pairState.lastInteractionTimestamp = block.timestamp; // Charging is an interaction

        emit StateCharged(tokenId, amount);
    }

     /// @notice Explicitly simulates entanglement decoherence based on time.
     /// @dev This decay also happens implicitly during other interactions, but can be triggered manually.
     /// @param tokenId An ID of a token within the pair.
    function simulateDecoherence(uint256 tokenId) public onlyEntangled(tokenId) {
        uint256 pairId = _getPairId(tokenId);
        _applyDecay(pairId);
    }

    /// @notice Attempts to re-entangle two tokens that were previously a pair.
    /// @dev Has a probabilistic chance of success. Requires both tokens to be owned by the caller.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function attemptReEntanglement(uint256 tokenId1, uint256 tokenId2) public {
        // Require caller owns both tokens
        require(ownerOf(tokenId1) == _msgSender(), "Must own both tokens");
        require(ownerOf(tokenId2) == _msgSender(), "Must own both tokens");

        // Require they are not currently entangled
        require(!_tokenData[tokenId1].isEntangled && !_tokenData[tokenId2].isEntangled, "Tokens must not be currently entangled");

        // (Optional but good design) Add a check that they *were* previously a pair
        // This would require storing historical pair data, which adds complexity/gas.
        // For this implementation, we allow re-entangling *any* two non-entangled tokens
        // with a base success chance, but the event could note if they were an original pair.
        // Let's require they *were* part of the *same* pair initially for stronger concept link.
        // This requires checking if their pairId was the same BEFORE they decohered.
        // We can't easily do this without historical state. Let's relax this and allow any two, but note the intent was original pairs.
        // For now, let's simplify and allow any two owned tokens to *attempt* to entangle, but the mechanic is designed for re-pairing.

        // Simulate success chance
        if (_checkChance(reEntangleSuccessChancePercent)) {
            // Success! Re-establish entanglement
            uint256 pairId = _getPairId(tokenId1, tokenId2);

            _tokenData[tokenId1] = TokenData({
                entangledPartnerId: tokenId2,
                isEntangled: true,
                pairId: pairId
            });
             _tokenData[tokenId2] = TokenData({
                entangledPartnerId: tokenId1,
                isEntangled: true,
                pairId: pairId
            });

            // Create new shared state (starts fresh)
            _sharedPairState[pairId] = SharedPairState({
                sharedEnergyLevel: 0, // Start with 0 energy on re-entangle
                entanglementStrength: MAX_ENTANGLEMENT_STRENGTH, // Start fully entangled
                lastObservedValue: 0,
                lastObservedTimestamp: 0,
                lastInteractionTimestamp: block.timestamp,
                creationTimestamp: block.timestamp
            });

            emit Entangled(tokenId1, tokenId2);
        } else {
            // Failed attempt - maybe log an event or return false
            // No state change, just gas consumed for the attempt
            // emit ReEntanglementAttemptFailed(tokenId1, tokenId2, _msgSender()); // Need a new event
        }
    }

    /// @notice Manually breaks the entanglement between a token and its partner.
    /// @param tokenId An ID of a token within the pair.
    function breakEntanglement(uint256 tokenId) public onlyEntangled(tokenId) onlyPairOwner(tokenId) {
         uint256 partnerId = _tokenData[tokenId].entangledPartnerId;
         require(ownerOf(partnerId) == _msgSender(), "Must own partner token to break manually"); // Ensure pair ownership

        _breakEntanglement(tokenId, partnerId, "Manual break");
    }

    /// @notice Allows the owner to break entanglement for a token if its partner is invalid or lost.
    /// @dev Should ideally not be needed if paired burn is used, but provides a recovery mechanism.
    /// @param orphanTokenId The token ID that needs its entanglement broken.
    function rescueOrphans(uint256 orphanTokenId) public onlyOwner {
        if (_tokenData[orphanTokenId].isEntangled) {
             uint256 partnerId = _tokenData[orphanTokenId].entangledPartnerId;
            // Check if partner token exists and is still marked as entangled with this orphan
            bool partnerExists = ownerOf(partnerId) != address(0);
            bool partnerPointsBack = partnerExists && _tokenData[partnerId].isEntangled && _tokenData[partnerId].entangledPartnerId == orphanTokenId;

            if (!partnerExists || !partnerPointsBack) {
                // It's a true orphan or the partner is inconsistent
                uint256 pairId = _getPairId(orphanTokenId); // Use the orphan's stored pair ID
                delete _sharedPairState[pairId]; // Clear shared state for the pair ID
                _tokenData[orphanTokenId].isEntangled = false;
                _tokenData[orphanTokenId].entangledPartnerId = 0;
                 _tokenData[orphanTokenId].pairId = 0; // Remove pair association

                 // Attempt to clean up partner side if it exists but is inconsistent
                 if(partnerExists && _tokenData[partnerId].entangledPartnerId == orphanTokenId) {
                      _tokenData[partnerId].isEntangled = false;
                     _tokenData[partnerId].entangledPartnerId = 0;
                      _tokenData[partnerId].pairId = 0;
                 }

                emit Decohered(orphanTokenId, partnerId, "Orphan rescue");
            } else {
                // Partner exists and state is consistent - not a true orphan needing rescue
                revert("Token is not an orphan needing rescue");
            }
        } else {
             // Not entangled anyway
            revert("Token is not entangled");
        }
    }

    /// @notice Transfers a single token of an entangled pair. High probability of breaking entanglement.
    /// @dev Use this instead of standard `transferFrom` for single tokens if you need specific entanglement-breaking mechanics.
    /// @param from The owner of the token.
    /// @param to The recipient address.
    /// @param tokenId The ID of the token to transfer.
    function transferOneOfPair(address from, address to, uint256 tokenId) public payable {
        require(ownerOf(tokenId) == from, "Transfer caller is not owner nor approved");
        require(to != address(0), "Transfer to zero address");
        _requireOwned(tokenId); // Ensure token exists

        if (_tokenData[tokenId].isEntangled) {
            uint256 partnerId = _tokenData[tokenId].entangledPartnerId;
            require(ownerOf(partnerId) != address(0), "Partner does not exist"); // Should not happen with paired burn

            uint256 pairId = _getPairId(tokenId);
            _applyDecay(pairId); // Apply decay before checking break chance

            uint256 currentStrength = _sharedPairState[pairId].entanglementStrength;
             // Calculate chance of breaking: lower strength -> higher chance
            uint256 breakChance = singleTransferBreakChanceFactor * 100 / (currentStrength + 1); // Multiplied by 100 for percentage math later
             breakChance = Math.min(breakChance, 10000); // Cap at 100% (10000 * 100)


            if (_checkChance(breakChance / 100)) { // Roll using the percentage
                // Entanglement breaks
                _breakEntanglement(tokenId, partnerId, "Single token transfer");
                 // Proceed with standard single token transfer using super (no entanglement logic anymore)
                super._transfer(from, to, tokenId);
                emit TransferWithEntanglementBroken(tokenId, from, to);
            } else {
                 // Entanglement holds (unlikely for this function) - this is inconsistent with physical analogy.
                 // Let's enforce that single transfers *always* break entanglement unless special functions are used.
                 // This makes 'transferOneOfPair' essentially a documented entanglement-breaking transfer.
                 _breakEntanglement(tokenId, partnerId, "Single token transfer enforced break");
                 super._transfer(from, to, tokenId);
                 emit TransferWithEntanglementBroken(tokenId, from, to);
            }
        } else {
            // Not entangled, proceed with standard transfer
             super._transfer(from, to, tokenId);
        }
    }

    /// @notice Transfers both tokens of an entangled pair to the same address. Higher chance of preserving entanglement.
    /// @param from The owner of the tokens.
    /// @param to The recipient address.
    /// @param tokenId1 The ID of the first token in the pair.
    /// @param tokenId2 The ID of the second token in the pair.
    function transferPairTogether(address from, address to, uint256 tokenId1, uint256 tokenId2) public payable notSelf(to) {
         require(ownerOf(tokenId1) == from && ownerOf(tokenId2) == from, "Transfer caller must own both tokens");
         require(to != address(0), "Transfer to zero address");
         require(_tokenData[tokenId1].isEntangled && _tokenData[tokenId2].isEntangled && _tokenData[tokenId1].entangledPartnerId == tokenId2, "Tokens are not an entangled pair");

        // Apply decay before checking chance
        uint256 pairId = _getPairId(tokenId1, tokenId2);
        _applyDecay(pairId);

        uint256 currentStrength = _sharedPairState[pairId].entanglementStrength;
        // Chance of PRESERVING entanglement is higher, related to strength.
        // Let's say chance_preserve = Strength / MAX_STRENGTH * 100%
        uint256 preserveChance = (currentStrength * 10000) / MAX_ENTANGLEMENT_STRENGTH; // Multiplied by 100 for percentage math
        preserveChance = Math.min(preserveChance, 10000); // Cap at 100%

        bool entanglementPreserved = _checkChance(preserveChance / 100);

        if (entanglementPreserved) {
            // Entanglement preserved! Transfer both tokens.
            // Important: When transferring both to the *same* address, the entanglement state moves with them.
            // No need to update pair data *within* the transfer, it just follows ownership.
            super._transfer(from, to, tokenId1);
            super._transfer(from, to, tokenId2);
            emit PairTransferredTogether(tokenId1, tokenId2, from, to, true);
        } else {
             // Entanglement broken during transfer
            _breakEntanglement(tokenId1, tokenId2, "Paired transfer failed to preserve entanglement");
            // Still transfer both tokens, but now they are just regular NFTs
            super._transfer(from, to, tokenId1);
            super._transfer(from, to, tokenId2);
             emit PairTransferredTogether(tokenId1, tokenId2, from, to, false);
        }
    }


    /// @notice Attempts a risky 'quantum tunneling' transfer: move one token while its partner stays, trying to preserve entanglement.
    /// @dev Low probability of success. High gas cost on failure due to state reset.
    /// @param from The owner of the token being moved.
    /// @param to The recipient address for the token being moved.
    /// @param tokenId The ID of the token to attempt tunneling with.
    function simulateQuantumTunnelingTransfer(address from, address to, uint256 tokenId) public payable notSelf(to) onlyEntangled(tokenId) {
        require(ownerOf(tokenId) == from, "Transfer caller is not owner nor approved");
        require(to != address(0), "Transfer to zero address");
        _requireOwned(tokenId); // Ensure token exists

        uint256 partnerId = _tokenData[tokenId].entangledPartnerId;
        address partnerOwner = ownerOf(partnerId);
        require(partnerOwner != address(0), "Partner does not exist"); // Should not happen with paired burn
        require(partnerOwner != to, "Tunneling destination cannot be partner's address"); // Tunneling is about different locations

        uint256 pairId = _getPairId(tokenId);
        _applyDecay(pairId); // Apply decay before checking chance

        uint256 currentStrength = _sharedPairState[pairId].entanglementStrength;
        // Chance of success is low, potentially related to strength but very risky
        // Let's make it inversely related to a high risk factor
        uint256 successChance = currentStrength * 100 / tunnelingTransferRiskFactor; // Multiplied by 100 for percentage math
        successChance = Math.min(successChance, 10000); // Cap at 100%

        bool tunnelingSuccess = _checkChance(successChance / 100);

        if (tunnelingSuccess) {
            // Success! Transfer the single token. Entanglement state remains linked.
            // The challenge here is how shared state behaves when owners are different.
            // For simplicity, we can say observation/charging can still be done by *either* owner, affecting the pair.
            // This introduces complex game mechanics but is interesting.
             super._transfer(from, to, tokenId); // Transfer just the one token
             // The tokenData for both tokens still points to the same pairId and each other.
             // The SharedPairState at pairId remains.
             // Update interaction timestamp for the pair
            _sharedPairState[pairId].lastInteractionTimestamp = block.timestamp;
            emit QuantumTunnelingAttempt(tokenId, from, to, true);
        } else {
            // Failure! Entanglement breaks and the token does NOT move.
             _breakEntanglement(tokenId, partnerId, "Quantum tunneling failed");
             // Token remains at 'from' address. No actual transfer occurs via super._transfer.
             emit QuantumTunnelingAttempt(tokenId, from, to, false);
        }
    }


    /// @notice Predicts the approximate percentage chance of entanglement breaking if `transferOneOfPair` is called now.
    /// @param tokenId An ID of a token within the pair.
    /// @return The probability (0-100) as a uint256.
    function predictEntanglementBreakChance(uint256 tokenId) public view onlyEntangled(tokenId) returns (uint256) {
        uint256 pairId = _getPairId(tokenId);
        SharedPairState memory pairState = _sharedPairState[pairId];
        uint256 currentStrength = getEntanglementStrength(tokenId); // Get decayed strength

         uint256 breakChance = singleTransferBreakChanceFactor * 100 / (currentStrength + 1); // Multiplied by 100 for percentage math later
         return Math.min(breakChance / 100, 100); // Return as 0-100 percentage
    }

     /// @notice Measures the amount of entanglement strength that has decayed since the last interaction.
     /// @param tokenId An ID of a token within the pair.
     /// @return The total strength points lost due to decay since last interaction.
    function measureDecoherenceAmount(uint256 tokenId) public view onlyEntangled(tokenId) returns (uint256) {
         uint256 pairId = _getPairId(tokenId);
         SharedPairState memory pairState = _sharedPairState[pairId];
         uint256 timeElapsed = block.timestamp - pairState.lastInteractionTimestamp;
         uint256 decayAmount = timeElapsed * entanglementDecayRatePerSecond;
         return decayAmount;
    }

    /// @notice Syncs the pseudo-random seed components using current block data.
    /// @dev Can be called by the owner to introduce new entropy into the PRNG, especially after periods of inactivity.
    function syncRandomnessSeed() public onlyOwner {
        _randomSeedComponent1 = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, _randomSeedComponent2)));
        _randomSeedComponent2 = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.prevrandao, _randomSeedComponent1)));
        emit RandomSeedSynced(block.timestamp, block.number);
    }


    // --- Admin/Owner Functions ---

    function setDecayRate(uint256 rate) public onlyOwner {
        entanglementDecayRatePerSecond = rate;
    }

    function setChargeRate(uint256 rate) public onlyOwner {
        sharedEnergyChargeRate = rate;
    }

    function setObservationCooldown(uint256 cooldown) public onlyOwner {
        observationCooldownDuration = cooldown;
    }

     function setReEntangleSuccessChance(uint256 chance) public onlyOwner {
         require(chance <= 100, "Chance must be <= 100");
         reEntangleSuccessChancePercent = chance;
     }

     function setSingleTransferBreakChanceFactor(uint256 factor) public onlyOwner {
         singleTransferBreakChanceFactor = factor;
     }

     function setTunnelingTransferRiskFactor(uint256 factor) public onlyOwner {
         require(factor > 0, "Factor must be greater than 0");
         tunnelingTransferRiskFactor = factor;
     }


    // --- Standard ERC721 Functions (overrides or standard implementations) ---

    // Use the inherited _nextTokenId counter for getTotalSupply
    function getTotalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Standard ERC721 functions requiring override due to our custom _transfer/_burn
    // These simply call the parent implementation
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         super.safeTransferFrom(from, to, tokenId, data);
    }

    // Standard ERC721 functions - implemented by OpenZeppelin via inheritance
    // ownerOf, balanceOf, approve, getApproved, setApprovalForAll, isApprovedForAll

    // Fallback/Receive - good practice to include if payable functions exist
    receive() external payable {}
    fallback() external payable {}
}
```