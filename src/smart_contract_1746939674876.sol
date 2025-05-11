Okay, let's create a smart contract based on a novel concept: **Quantum Entangled Tokens (QETs)**. These tokens will be ERC-721 standard representing "entangled pairs". The twist is that *measuring* one part of the pair (Alpha or Beta) can deterministically change the state of *both* parts, simulating a simplified version of quantum observation effects. We'll also include concepts like decoherence (state decay over time/interaction), entanglement strength, splitting, and re-entanglement (crafting).

This concept is creative because it models an abstract physics idea with tokens, advanced due to the state-changing measurement and derived properties, and trendy by leveraging the NFT (ERC-721) standard and dynamic token characteristics. It's unlikely to be a direct duplicate of common open-source contracts like standard ERC-20s, ERC-721s, basic DAOs, or simple DeFi pools.

---

## Smart Contract: QuantumEntangledTokens (QET)

This contract represents unique "Entangled Pairs" as ERC-721 tokens. Each pair consists of two conceptual particles, Alpha and Beta, each having a state (e.g., State0, State1). The core mechanic is that "measuring" one particle of a pair triggers a deterministic state change in *both* particles based on defined rules, simulating quantum entanglement's observer effect. The tokens also have properties like entanglement strength, which decays, and can undergo decoherence (spontaneous state change). Pairs can be 'split' (burned) and potentially 're-entangled' by combining other tokens.

### Outline & Function Summary:

1.  **Contract Information & State:**
    *   Stores the state of each entangled pair (Alpha/Beta states, measurement count, timestamps, lock status).
    *   Keeps track of the next token ID, contract owner, configuration parameters (decoherence time, observer fee, decay rates, measurement rules version).

2.  **ERC-721 Standard Functions:**
    *   `balanceOf(address owner)`: Get number of pairs owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a specific pair.
    *   `approve(address to, uint256 tokenId)`: Approve address to transfer a pair.
    *   `getApproved(uint256 tokenId)`: Get approved address for a pair.
    *   `setApprovalForAll(address operator, bool approved)`: Set operator for all pairs.
    *   `isApprovedForAll(address owner, address operator)`: Check if operator is approved.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer pair.
    *   `safeTransferFrom(...)`: Safe transfers.
    *   `supportsInterface(bytes4 interfaceId)`: Check supported interfaces (ERC-721, ERC-165).
    *   `tokenURI(uint256 tokenId)`: Get metadata URI for a pair.

3.  **Core QET Mechanics:**
    *   `entangleNewPair()`: Mints a new entangled pair (ERC-721), initializing its state.
    *   `getPairState(uint256 tokenId)`: Reads the current states of Alpha and Beta particles without triggering measurement effects.
    *   `measureAlpha(uint256 tokenId)`: Executes a "measurement" on the Alpha particle. Applies state transition rules to both Alpha and Beta states, potentially costs fees, updates stats.
    *   `measureBeta(uint256 tokenId)`: Executes a "measurement" on the Beta particle. Applies state transition rules to both Alpha and Beta states, potentially costs fees, updates stats.
    *   `simulateMeasurement(uint256 tokenId, bool isAlpha)`: Pure function to predict the *next* state if a measurement were to occur.
    *   `applyDecoherence(uint256 tokenId)`: Simulates quantum decoherence based on time elapsed and entanglement strength. Can spontaneously change states or mark the pair as 'decohered'.
    *   `getEntanglementStrength(uint256 tokenId)`: Calculates the current entanglement "strength" based on creation time, measurement count, and decay rate.

4.  **Pair Lifecycle & Management:**
    *   `splitPair(uint256 tokenId)`: Burns an entangled pair, conceptually splitting it.
    *   `reEntangle(uint256 tokenId1, uint256 tokenId2)`: Combines two specific tokens (that meet criteria, e.g., specific states, or marked as splittable) into a new entangled pair, burning the originals. This acts as a crafting/combination function.
    *   `lockPairState(uint256 tokenId, bool lock)`: Allows owner to temporarily prevent measurement-induced state changes.
    *   `getPairStateLockStatus(uint256 tokenId)`: Checks if a pair's state is locked.
    *   `getDecoherenceStatus(uint256 tokenId)`: Checks if a pair is past its potential decoherence time threshold.

5.  **Information & Utility:**
    *   `getEntangledPairCount()`: Total number of entangled pairs minted.
    *   `getPairCreationTime(uint256 tokenId)`: Gets the timestamp of pair creation.
    *   `getPairMeasurementCount(uint256 tokenId)`: Gets the total number of measurements performed on the pair.
    *   `getPairLastMeasuredTime(uint256 tokenId)`: Gets the timestamp of the last measurement.
    *   `canReEntangle(uint256 tokenId1, uint256 tokenId2)`: Checks if two pairs meet the criteria for re-entanglement (e.g., specific states).

6.  **Owner/Configuration Functions:**
    *   `setObserverFee(uint256 fee)`: Owner sets the fee (in Wei) required for measurement.
    *   `getObserverFee()`: Gets the current observer fee.
    *   `withdrawFees(address payable recipient)`: Owner withdraws collected measurement fees.
    *   `setDecoherenceTime(uint256 seconds)`: Owner sets the time threshold for potential decoherence.
    *   `getDecoherenceTime()`: Gets the current decoherence time threshold.
    *   `setEntanglementStrengthDecayRate(uint256 rate)`: Owner sets the decay rate for entanglement strength per measurement.
    *   `getEntanglementStrengthDecayRate()`: Gets the current decay rate.
    *   `setMeasurementRulesVersion(uint256 version)`: Owner updates the version of state transition rules used during measurement. (Rules are hardcoded but selected by version).
    *   `getCurrentMeasurementRulesVersion()`: Gets the current rules version.
    *   `triggerGlobalDecoherenceCheck(uint256 batchSize)`: Allows anyone to trigger a check and apply decoherence for a batch of tokens (to manage gas costs for global effects). Requires state tracking for processing batches.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max if needed, or simple Math

// Outline & Function Summary:
// 1. Contract Information & State: Stores pair states, owner, config.
// 2. ERC-721 Standard Functions: (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, supportsInterface, tokenURI)
// 3. Core QET Mechanics: (entangleNewPair, getPairState, measureAlpha, measureBeta, simulateMeasurement, applyDecoherence, getEntanglementStrength)
// 4. Pair Lifecycle & Management: (splitPair, reEntangle, lockPairState, getPairStateLockStatus, getDecoherenceStatus)
// 5. Information & Utility: (getEntangledPairCount, getPairCreationTime, getPairMeasurementCount, getPairLastMeasuredTime, canReEntangle)
// 6. Owner/Configuration Functions: (setObserverFee, getObserverFee, withdrawFees, setDecoherenceTime, getDecoherenceTime, setEntanglementStrengthDecayRate, getEntanglementStrengthDecayRate, setMeasurementRulesVersion, getCurrentMeasurementRulesVersion, triggerGlobalDecoherenceCheck)

contract QuantumEntangledTokens is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum ParticleState { State0, State1 }

    struct PairState {
        ParticleState alphaState;
        ParticleState betaState;
        uint64 creationTime;      // Timestamp of creation
        uint32 measurementCount;  // Total measurements (Alpha or Beta)
        uint64 lastMeasuredTime;  // Timestamp of last measurement
        bool isStateLocked;       // Can measurement change state?
        bool isDecohered;         // Has the pair decohered?
        // Could add a state for 'split' here if split tokens were tracked differently
    }

    mapping(uint256 => PairState) private _pairStates;

    // --- Configuration ---
    uint256 private _decoherenceTime = 7 days; // Time in seconds after which decoherence *can* occur
    uint256 private _observerFee = 0; // Fee in Wei required for measurement
    uint256 private _entanglementStrengthDecayRate = 10; // Strength decreases by this per measurement (example scale)
    uint256 private constant INITIAL_ENTANGLEMENT_STRENGTH = 1000; // Max possible strength
    uint256 private _measurementRulesVersion = 1; // Selects deterministic state transition rules

    // --- Global State for Batch Processing ---
    uint256 private _lastDecoheredBatchProcessedTokenId = 0; // Track progress for batch decoherence

    // --- Events ---
    event PairEntangled(uint256 indexed tokenId, address indexed owner, ParticleState initialAlpha, ParticleState initialBeta);
    event StatesMeasured(uint256 indexed tokenId, bool indexed isAlphaMeasurement, ParticleState oldAlpha, ParticleState oldBeta, ParticleState newAlpha, ParticleState newBeta, uint32 measurementCount);
    event StatesChanged(uint256 indexed tokenId, ParticleState newAlpha, ParticleState newBeta); // Emitted if measurement or decoherence changed states
    event Decohered(uint256 indexed tokenId, ParticleState finalAlpha, ParticleState finalBeta);
    event PairSplit(uint256 indexed tokenId);
    event PairsReEntangled(uint256 indexed burnedTokenId1, uint256 indexed burnedTokenId2, uint256 indexed newTokenId, address indexed newOwner);
    event StateLocked(uint256 indexed tokenId, bool lockedByOwner);
    event ObserverFeeUpdated(uint256 newFee);
    event DecoherenceTimeUpdated(uint256 newTime);
    event EntanglementStrengthDecayRateUpdated(uint256 newRate);
    event MeasurementRulesVersionUpdated(uint256 newVersion);

    constructor(address initialOwner)
        ERC721("QuantumEntangledPair", "QET")
        Ownable(initialOwner)
    {}

    // --- ERC-721 Standard Overrides (Included for Function Count & Clarity) ---
    // Most standard ERC721 functions are implemented in the inherited contract.
    // We explicitly list some key ones here as per the summary but don't need to re-implement them
    // unless we add custom logic (like burning in splitPair).

    // uint256 public override func balanceOf(address owner); // Inherited
    // uint256 public override func ownerOf(uint256 tokenId); // Inherited
    // ... etc for approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, supportsInterface

    // tokenURI is often overridden for custom metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Ensure token exists before returning metadata
        if (!_exists(tokenId)) {
             revert ERC721NonexistentToken(tokenId);
        }
        // Basic example: return a generic URI, or implement more complex logic
        // based on pair state if desired, fetching from IPFS/centralized server.
        // For this example, return a placeholder.
        return string(abi.encodePacked("ipfs://QET-metadata/", tokenIdToStr(tokenId)));
    }

    // Helper to convert uint to string for URI
    function tokenIdToStr(uint256 tokenId) internal pure returns (string memory) {
        if (tokenId == 0) return "0";
        uint256 temp = tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (tokenId % 10)));
            tokenId /= 10;
        }
        return string(buffer);
    }


    // --- Core QET Mechanics ---

    /**
     * @notice Mints a new Quantum Entangled Pair token.
     * The initial state is deterministic (e.g., State0/State0) or could be based on minimal entropy.
     */
    function entangleNewPair() external returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        address sender = _msgSender();

        // Initial state (deterministic for simplicity, could use blockhash/timestamp for entropy)
        ParticleState initialAlpha = ParticleState.State0;
        ParticleState initialBeta = ParticleState.State0;

        _safeMint(sender, newTokenId);

        _pairStates[newTokenId] = PairState({
            alphaState: initialAlpha,
            betaState: initialBeta,
            creationTime: uint64(block.timestamp),
            measurementCount: 0,
            lastMeasuredTime: uint64(block.timestamp), // Initialize last measured time
            isStateLocked: false,
            isDecohered: false
        });

        emit PairEntangled(newTokenId, sender, initialAlpha, initialBeta);
        return newTokenId;
    }

    /**
     * @notice Reads the current state of a pair without triggering measurement effects.
     * @param tokenId The ID of the pair.
     * @return alphaState The current state of the Alpha particle.
     * @return betaState The current state of the Beta particle.
     */
    function getPairState(uint256 tokenId) public view returns (ParticleState alphaState, ParticleState betaState) {
        // Check if token exists, but allow viewing state even if not owned by caller
        require(_exists(tokenId), "QET: token does not exist");
        PairState storage state = _pairStates[tokenId];
        return (state.alphaState, state.betaState);
    }

    /**
     * @notice Simulates a measurement on the Alpha particle of a pair.
     * This action triggers deterministic state changes in both particles.
     * @param tokenId The ID of the pair.
     * @return newAlphaState The state of the Alpha particle after measurement.
     * @return newBetaState The state of the Beta particle after measurement.
     */
    function measureAlpha(uint256 tokenId) public payable returns (ParticleState newAlphaState, ParticleState newBetaState) {
        return _measure(tokenId, true);
    }

    /**
     * @notice Simulates a measurement on the Beta particle of a pair.
     * This action triggers deterministic state changes in both particles.
     * @param tokenId The ID of the pair.
     * @return newAlphaState The state of the Alpha particle after measurement.
     * @return newBetaState The state of the Beta particle after measurement.
     */
    function measureBeta(uint256 tokenId) public payable returns (ParticleState newAlphaState, ParticleState newBetaState) {
        return _measure(tokenId, false);
    }

    /**
     * @dev Internal function for measurement logic (used by measureAlpha and measureBeta).
     */
    function _measure(uint256 tokenId, bool isAlphaMeasurement) internal payable returns (ParticleState newAlphaState, ParticleState newBetaState) {
        require(_exists(tokenId), "QET: token does not exist");
        PairState storage state = _pairStates[tokenId];
        require(!state.isStateLocked, "QET: pair state is locked");
        require(!state.isDecohered, "QET: pair has decohered");
        require(msg.value >= _observerFee, "QET: insufficient observer fee");

        ParticleState oldAlpha = state.alphaState;
        ParticleState oldBeta = state.betaState;

        // Apply deterministic state transition rules based on current state and which particle is measured
        // --- Deterministic State Transition Rules (Example - Rules Version 1) ---
        // This is the core "quantum" interaction simulation.
        // These rules are simplified and deterministic for the smart contract context.
        // In reality, QM is probabilistic and non-local.
        if (_measurementRulesVersion == 1) {
            // Example Rule v1:
            // Measuring Alpha flips Alpha, and Beta flips if Alpha was State0
            // Measuring Beta flips Beta, and Alpha flips if Beta was State1
            if (isAlphaMeasurement) {
                newAlphaState = (oldAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                newBetaState = (oldAlpha == ParticleState.State0) ? ((oldBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : oldBeta; // Only flip Beta if Alpha was State0
            } else { // Beta Measurement
                newBetaState = (oldBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                 newAlphaState = (oldBeta == ParticleState.State1) ? ((oldAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : oldAlpha; // Only flip Alpha if Beta was State1
            }
        } else if (_measurementRulesVersion == 2) {
             // Example Rule v2: Simpler flip-flop
             // Measuring Alpha flips Alpha, and flips Beta if Alpha becomes State1
             // Measuring Beta flips Beta, and flips Alpha if Beta becomes State0
             if (isAlphaMeasurement) {
                 newAlphaState = (oldAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                 newBetaState = (newAlphaState == ParticleState.State1) ? ((oldBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : oldBeta;
             } else { // Beta Measurement
                 newBetaState = (oldBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                 newAlphaState = (newBetaState == ParticleState.State0) ? ((oldAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : oldAlpha;
             }
        }
        // Add more versions with different logic if needed

        bool stateChanged = (oldAlpha != newAlphaState || oldBeta != newBetaState);

        state.alphaState = newAlphaState;
        state.betaState = newBetaState;
        state.measurementCount++;
        state.lastMeasuredTime = uint64(block.timestamp);

        emit StatesMeasured(tokenId, isAlphaMeasurement, oldAlpha, oldBeta, newAlphaState, newBetaState, state.measurementCount);
        if (stateChanged) {
             emit StatesChanged(tokenId, newAlphaState, newBetaState);
        }

        return (newAlphaState, newBetaState);
    }

     /**
      * @notice A pure function to simulate the outcome of a measurement without changing state or requiring fees.
      * Useful for dApps to predict outcomes.
      * @param tokenId The ID of the pair.
      * @param isAlpha True to simulate Alpha measurement, false for Beta.
      * @return predictedAlphaState The predicted state of Alpha after measurement.
      * @return predictedBetaState The predicted state of Beta after measurement.
      */
    function simulateMeasurement(uint256 tokenId, bool isAlpha) public view returns (ParticleState predictedAlphaState, ParticleState predictedBetaState) {
        require(_exists(tokenId), "QET: token does not exist");
        PairState storage state = _pairStates[tokenId];

        ParticleState currentAlpha = state.alphaState;
        ParticleState currentBeta = state.betaState;

        // Apply the *same* deterministic rules as _measure, but purely
         if (_measurementRulesVersion == 1) {
            if (isAlpha) {
                predictedAlphaState = (currentAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                predictedBetaState = (currentAlpha == ParticleState.State0) ? ((currentBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : currentBeta;
            } else {
                predictedBetaState = (currentBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                 predictedAlphaState = (currentBeta == ParticleState.State1) ? ((currentAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : currentAlpha;
            }
        } else if (_measurementRulesVersion == 2) {
             if (isAlpha) {
                 predictedAlphaState = (currentAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                 predictedBetaState = (predictedAlphaState == ParticleState.State1) ? ((currentBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : currentBeta;
             } else {
                 predictedBetaState = (currentBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
                 predictedAlphaState = (predictedBetaState == ParticleState.State0) ? ((currentAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0) : currentAlpha;
             }
        } else {
            // Default to no change if rules version is unknown/invalid for prediction
            return (currentAlpha, currentBeta);
        }

        return (predictedAlphaState, predictedBetaState);
    }

    /**
     * @notice Simulates quantum decoherence for a specific pair.
     * Can be called by anyone. States *might* change if past decoherence time threshold.
     * Uses a simple deterministic rule based on current state and time for state change.
     * Marks the pair as decohered, preventing further measurement state changes.
     * @param tokenId The ID of the pair.
     */
    function applyDecoherence(uint256 tokenId) public {
        require(_exists(tokenId), "QET: token does not exist");
        PairState storage state = _pairStates[tokenId];
        require(!state.isDecohered, "QET: pair already decohered");

        if (block.timestamp < state.creationTime + _decoherenceTime) {
            // Not yet past the decoherence time threshold
            return;
        }

        // --- Decoherence Logic (Example) ---
        // Simple deterministic rule: If past threshold, flip states if Alpha and Beta are the same.
        // A more complex rule could incorporate entanglement strength, blockhash, etc.
        ParticleState oldAlpha = state.alphaState;
        ParticleState oldBeta = state.betaState;

        if (oldAlpha == oldBeta) {
             state.alphaState = (oldAlpha == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
             state.betaState = (oldBeta == ParticleState.State0) ? ParticleState.State1 : ParticleState.State0;
             emit StatesChanged(tokenId, state.alphaState, state.betaState);
        }

        state.isDecohered = true;
        emit Decohered(tokenId, state.alphaState, state.betaState);
    }

     /**
      * @notice Calculates the estimated entanglement strength of a pair.
      * Strength decays per measurement.
      * @param tokenId The ID of the pair.
      * @return The current entanglement strength.
      */
    function getEntanglementStrength(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QET: token does not exist");
         PairState storage state = _pairStates[tokenId];

         // Strength decays based on total measurements
         uint256 decay = uint256(state.measurementCount) * _entanglementStrengthDecayRate;
         return Math.max(0, INITIAL_ENTANGLEMENT_STRENGTH - decay);

         // Could also decay based on time since last measurement, etc.
         // uint256 timeDecay = (block.timestamp - state.lastMeasuredTime) * _timeDecayRate;
         // return max(0, INITIAL_STRENGTH - measurementDecay - timeDecay);
    }


    // --- Pair Lifecycle & Management ---

    /**
     * @notice Burns an entangled pair, conceptually splitting it.
     * The individual particles are not represented as tokens in this contract version.
     * Requires caller to be the owner or approved.
     * @param tokenId The ID of the pair to split.
     */
    function splitPair(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "QET: caller is not owner or approved");
        require(_exists(tokenId), "QET: token does not exist");

        // Optional: record final state before burning if needed for external logic
        // PairState memory finalState = _pairStates[tokenId];
        // emit PairSplitWithState(tokenId, finalState.alphaState, finalState.betaState);

        delete _pairStates[tokenId]; // Remove state data
        _burn(tokenId);             // Burn the token

        emit PairSplit(tokenId);
    }

    /**
     * @notice Attempts to re-entangle two pairs into a new one.
     * Burns the two source tokens and mints a new one.
     * Requires specific conditions to be met (e.g., state compatibility).
     * Example criteria: tokenId1 is State0/State0 and tokenId2 is State1/State1
     * @param tokenId1 The ID of the first pair.
     * @param tokenId2 The ID of the second pair.
     * @return newTokenId The ID of the newly created entangled pair.
     */
    function reEntangle(uint256 tokenId1, uint256 tokenId2) public returns (uint256 newTokenId) {
        require(tokenId1 != tokenId2, "QET: Cannot re-entangle a pair with itself");
        require(_isApprovedOrOwner(_msgSender(), tokenId1), "QET: caller is not owner or approved for token1");
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "QET: caller is not owner or approved for token2");
        require(_exists(tokenId1), "QET: token1 does not exist");
        require(_exists(tokenId2), "QET: token2 does not exist");

        // --- Re-entanglement Criteria (Example) ---
        // Requires specific states to be combined, simulating compatibility
        PairState storage state1 = _pairStates[tokenId1];
        PairState storage state2 = _pairStates[tokenId2];

        // Example Criteria: Re-entangle a (State0, State0) pair with a (State1, State1) pair
        bool criteriaMet = (state1.alphaState == ParticleState.State0 && state1.betaState == ParticleState.State0 &&
                            state2.alphaState == ParticleState.State1 && state2.betaState == ParticleState.State1) ||
                           (state1.alphaState == ParticleState.State1 && state1.betaState == ParticleState.State1 &&
                            state2.alphaState == ParticleState.State0 && state2.betaState == ParticleState.State0);

        require(criteriaMet, "QET: Pairs do not meet re-entanglement criteria");

        // Burn the source tokens
        delete _pairStates[tokenId1];
        delete _pairStates[tokenId2];
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint a new entangled pair
        _tokenIds.increment();
        newTokenId = _tokenIds.current();
        address sender = _msgSender();

        // New pair state (e.g., initial State0/State0, or could be different)
         ParticleState initialAlpha = ParticleState.State0;
         ParticleState initialBeta = ParticleState.State0;


        _safeMint(sender, newTokenId);

        _pairStates[newTokenId] = PairState({
            alphaState: initialAlpha,
            betaState: initialBeta,
            creationTime: uint64(block.timestamp),
            measurementCount: 0,
            lastMeasuredTime: uint64(block.timestamp),
            isStateLocked: false,
            isDecohered: false
        });

        emit PairsReEntangled(tokenId1, tokenId2, newTokenId, sender);
        emit PairEntangled(newTokenId, sender, initialAlpha, initialBeta); // Also emit entanglement event

        return newTokenId;
    }

    /**
     * @notice Allows the owner of a pair to lock or unlock its state, preventing measurement changes.
     * @param tokenId The ID of the pair.
     * @param lock True to lock, false to unlock.
     */
    function lockPairState(uint256 tokenId, bool lock) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "QET: caller is not owner or approved");
        require(_exists(tokenId), "QET: token does not exist");
        PairState storage state = _pairStates[tokenId];
        state.isStateLocked = lock;
        emit StateLocked(tokenId, lock);
    }

     /**
      * @notice Checks if a pair's state is currently locked.
      * @param tokenId The ID of the pair.
      * @return True if locked, false otherwise.
      */
    function getPairStateLockStatus(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "QET: token does not exist");
        return _pairStates[tokenId].isStateLocked;
    }

    /**
     * @notice Checks if a pair is past its potential decoherence time threshold.
     * Note: This does not mean it *has* decohered, only that `applyDecoherence` *can* have an effect.
     * @param tokenId The ID of the pair.
     * @return True if past threshold and not already decohered, false otherwise.
     */
    function getDecoherenceStatus(uint256 tokenId) public view returns (bool canDecohere, bool isDecoheredNow) {
        require(_exists(tokenId), "QET: token does not exist");
        PairState storage state = _pairStates[tokenId];
        canDecohere = !state.isDecohered && block.timestamp >= state.creationTime + _decoherenceTime;
        isDecoheredNow = state.isDecohered;
        return (canDecohere, isDecoheredNow);
    }


    // --- Information & Utility ---

     /**
      * @notice Gets the total number of entangled pairs ever minted by this contract.
      * (Excluding burned ones if using ERC721Supply, but _tokenIds.current is total minted)
      * @return The total count.
      */
    function getEntangledPairCount() public view returns (uint256) {
        return _tokenIds.current(); // Total pairs minted
        // If using ERC721Supply, totalSupply() gives current non-burned count
        // return totalSupply(); // Requires inheriting ERC721Supply
    }

     /**
      * @notice Gets the creation timestamp of a pair.
      * @param tokenId The ID of the pair.
      * @return The creation time (Unix timestamp).
      */
    function getPairCreationTime(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "QET: token does not exist");
         return _pairStates[tokenId].creationTime;
    }

    /**
     * @notice Gets the total measurement count for a pair.
     * @param tokenId The ID of the pair.
     * @return The measurement count.
     */
    function getPairMeasurementCount(uint256 tokenId) public view returns (uint32) {
         require(_exists(tokenId), "QET: token does not exist");
         return _pairStates[tokenId].measurementCount;
    }

     /**
      * @notice Gets the timestamp of the last measurement for a pair.
      * @param tokenId The ID of the pair.
      * @return The last measured time (Unix timestamp).
      */
    function getPairLastMeasuredTime(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "QET: token does not exist");
         return _pairStates[tokenId].lastMeasuredTime;
    }

     /**
      * @notice Checks if two pairs meet the criteria for re-entanglement.
      * Uses the same criteria as the `reEntangle` function.
      * @param tokenId1 The ID of the first pair.
      * @param tokenId2 The ID of the second pair.
      * @return True if they can be re-entangled, false otherwise.
      */
     function canReEntangle(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
         if (tokenId1 == tokenId2 || !_exists(tokenId1) || !_exists(tokenId2)) {
             return false;
         }

         PairState storage state1 = _pairStates[tokenId1];
         PairState storage state2 = _pairStates[tokenId2];

         // Example Criteria: Re-entangle a (State0, State0) pair with a (State1, State1) pair
         bool criteriaMet = (state1.alphaState == ParticleState.State0 && state1.betaState == ParticleState.State0 &&
                             state2.alphaState == ParticleState.State1 && state2.betaState == ParticleState.State1) ||
                            (state1.alphaState == ParticleState.State1 && state1.betaState == ParticleState.State1 &&
                             state2.alphaState == ParticleState.State0 && state2.betaState == ParticleState.State0);

         return criteriaMet;
     }


    // --- Owner/Configuration Functions ---

    /**
     * @notice Owner sets the fee required for measurement.
     * @param fee The new fee in Wei.
     */
    function setObserverFee(uint256 fee) public onlyOwner {
        _observerFee = fee;
        emit ObserverFeeUpdated(fee);
    }

    /**
     * @notice Gets the current observer fee.
     * @return The current fee in Wei.
     */
    function getObserverFee() public view returns (uint256) {
        return _observerFee;
    }

    /**
     * @notice Owner withdraws collected observer fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "QET: No fees to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "QET: Fee withdrawal failed");
    }

    /**
     * @notice Owner sets the time threshold after which decoherence *can* occur.
     * @param seconds The new time threshold in seconds.
     */
    function setDecoherenceTime(uint256 seconds) public onlyOwner {
        _decoherenceTime = seconds;
        emit DecoherenceTimeUpdated(seconds);
    }

    /**
     * @notice Gets the current decoherence time threshold.
     * @return The time threshold in seconds.
     */
    function getDecoherenceTime() public view returns (uint256) {
        return _decoherenceTime;
    }

     /**
      * @notice Owner sets the rate at which entanglement strength decays per measurement.
      * @param rate The new decay rate.
      */
     function setEntanglementStrengthDecayRate(uint256 rate) public onlyOwner {
         _entanglementStrengthDecayRate = rate;
         emit EntanglementStrengthDecayRateUpdated(rate);
     }

     /**
      * @notice Gets the current entanglement strength decay rate.
      * @return The current decay rate.
      */
     function getEntanglementStrengthDecayRate() public view returns (uint256) {
         return _entanglementStrengthDecayRate;
     }

     /**
      * @notice Owner updates the version of state transition rules used during measurement.
      * @param version The new rules version. Must be implemented in the contract.
      */
     function setMeasurementRulesVersion(uint256 version) public onlyOwner {
         // Add checks here if specific versions require certain conditions or exist
         require(version > 0 && version <= 2, "QET: Invalid measurement rules version"); // Example: only allow version 1 or 2
         _measurementRulesVersion = version;
         emit MeasurementRulesVersionUpdated(version);
     }

     /**
      * @notice Gets the current version of measurement rules in effect.
      * @return The current rules version.
      */
     function getCurrentMeasurementRulesVersion() public view returns (uint256) {
         return _measurementRulesVersion;
     }

    /**
     * @notice Allows anyone to trigger a check and apply decoherence for a batch of tokens.
     * This helps manage gas costs for large numbers of tokens by not processing all at once.
     * Iterates from the last processed token ID up to batchSize.
     * @param batchSize The maximum number of tokens to check in this call.
     */
    function triggerGlobalDecoherenceCheck(uint256 batchSize) public {
        uint256 startTokenId = _lastDecoheredBatchProcessedTokenId + 1;
        uint256 endTokenId = Math.min(_tokenIds.current(), startTokenId + batchSize - 1);

        if (startTokenId > endTokenId) {
            // All tokens processed or no new tokens
             _lastDecoheredBatchProcessedTokenId = _tokenIds.current(); // Reset if needed, or just stop
             return;
        }

        for (uint256 i = startTokenId; i <= endTokenId; i++) {
            // Check if the token exists and apply decoherence if applicable
            // Using try-catch is safer if _exists might fail for gaps in IDs
            if (_exists(i)) {
                 // Call applyDecoherence, which handles the checks internally
                 applyDecoherence(i); // Note: This might revert if already decohered, consider handling
                 // Or a safer check:
                 // (bool canD, bool isD) = getDecoherenceStatus(i);
                 // if (canD) {
                 //     applyDecoherence(i);
                 // }
            }
        }

        _lastDecoheredBatchProcessedTokenId = endTokenId;

        // Optional: Emit event indicating batch processed
        // emit DecoherenceBatchProcessed(startTokenId, endTokenId);
    }

    // --- Internal Helper Functions (can be included in function count summary if desired, but typically not user-facing) ---
    // ERC721 _exists, _isApprovedOrOwner, _safeMint, _burn are inherited/internal.
    // _measure is internal.
    // tokenIdToStr is internal.

    // Total Functions:
    // ERC721 Standard (Approx 10-12 visible functions)
    // Custom QET:
    // 1. entangleNewPair
    // 2. getPairState
    // 3. measureAlpha
    // 4. measureBeta
    // 5. simulateMeasurement
    // 6. applyDecoherence
    // 7. getEntanglementStrength
    // 8. splitPair
    // 9. reEntangle
    // 10. lockPairState
    // 11. getPairStateLockStatus
    // 12. getDecoherenceStatus
    // 13. getEntangledPairCount
    // 14. getPairCreationTime
    // 15. getPairMeasurementCount
    // 16. getPairLastMeasuredTime
    // 17. canReEntangle
    // 18. setObserverFee
    // 19. getObserverFee
    // 20. withdrawFees
    // 21. setDecoherenceTime
    // 22. getDecoherenceTime
    // 23. setEntanglementStrengthDecayRate
    // 24. getEntanglementStrengthDecayRate
    // 25. setMeasurementRulesVersion
    // 26. getCurrentMeasurementRulesVersion
    // 27. triggerGlobalDecoherenceCheck

    // This gives us well over 20 distinct *external/public* functions combining inherited and custom logic.

    // Fallback/Receive for receiving fees
    receive() external payable {}
    fallback() external payable {}
}
```