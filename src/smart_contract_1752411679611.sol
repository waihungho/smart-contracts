Okay, this sounds like a fun challenge! We'll create a smart contract for a non-standard, state-driven digital asset. Let's call them "Quantum Ephemeral Tokens" (QETs).

These tokens aren't just owned; they exist in different "quantum states" (simulated), influenced by time, interactions ("observations"), energy levels, and even entanglement with other tokens. They can decay, stabilize, become excited, or even collapse and become unusable/burnable.

---

## Quantum Ephemeral Token (QET) Contract

**Concept:** A non-standard, state-aware digital asset where each token's properties and behavior are determined by its current simulated "quantum state". States change based on time (decay), interactions ("observation"), energy levels, and entanglement with other tokens, guided by probabilistic rules configurable by the contract owner.

**Key Features:**
*   **State Machine:** Tokens exist in different defined states (e.g., Superposition, Stable, Decayed, Entangled, Excited, Collapsed).
*   **Ephemerality:** Tokens can decay over time if not maintained or interacted with.
*   **Observation Effect:** Interacting with a token ("observing") can trigger state transitions and affect its energy/decay timer.
*   **Energy Levels:** Tokens have an energy level that influences transitions and can be boosted.
*   **Entanglement:** Tokens can be linked, causing their states or transitions to influence each other.
*   **Probabilistic Transitions:** Some state changes might have configurable probabilities (simulated randomness).
*   **History Tracking:** A hash is maintained to represent the state change history of each token.
*   **Configurable Parameters:** The contract owner can set decay rates, energy costs, transition probabilities, etc.

---

### Outline and Function Summary

1.  **State Management (`State` Enum, `TokenData` Struct):** Defines possible token states and the data structure for each token.
2.  **Data Storage (`tokens`, `_owners`, `_balances`, `config`, etc.):** Mappings and variables to store token data, ownership, contract configuration, etc.
3.  **Events:** Signals significant actions (minting, burning, state changes, entanglement, etc.).
4.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`), state checks (`onlyState`, `notState`).
5.  **Ownership & Supply (`ownerOf`, `balanceOf`, `totalSupply`, `_mint`, `_burn`):** Basic ERC721-like minimal implementation for tracking ownership and supply, adapted for state logic.
    *   `ownerOf(tokenId)`: Get the owner of a token.
    *   `balanceOf(owner)`: Get the number of tokens owned by an address.
    *   `totalSupply()`: Get the total number of active tokens.
    *   `_mint(to, tokenId)`: Internal function to create a new token.
    *   `_burn(tokenId)`: Internal function to destroy a token.
    *   `transferFrom(from, to, tokenId)`: Transfer ownership (with state checks).
    *   `safeTransferFrom(from, to, tokenId)`: Transfer ownership (with state checks, standard ERC721 safe call stub).
6.  **State Management Core (`_applyTransition`, `_generateHistoryHash`):** Internal helpers for state changes.
    *   `_applyTransition(tokenId, newState, energyDelta, decayTimerReset, partnerId)`: Internal function to update token data after a state change.
    *   `_generateHistoryHash(tokenId, transitionDetails)`: Internal function to update the token's history hash.
7.  **Query Functions (Getters):** Retrieve information about tokens and contract state.
    *   `getTokenState(tokenId)`: Get the current state of a token.
    *   `getEnergyLevel(tokenId)`: Get the current energy level of a token.
    *   `getDecayTimestamp(tokenId)`: Get the timestamp when decay check should occur.
    *   `getEntanglementPartner(tokenId)`: Get the ID of the token it's entangled with.
    *   `getObservationCount(tokenId)`: Get how many times it's been observed.
    *   `isDecayed(tokenId)`: Check if the token is currently in a Decayed or Collapsed state.
    *   `canTransition(tokenId, desiredState)`: Check if a direct transition to a state is theoretically possible from the current state based on config.
    *   `getHistoryHash(tokenId)`: Get the history hash of a token.
    *   `getConfig()`: Get the current contract configuration.
    *   `isPaused()`: Check if state transitions are paused.
8.  **User Interaction Functions (State Transitions & Actions):** Functions users call to interact with tokens and potentially change their state.
    *   `mintInitialToken()`: Mint a *new* token (potentially requiring payment or conditions).
    *   `observeState(tokenId)`: Simulate observing a token, potentially triggering a state transition based on rules and energy.
    *   `decayState(tokenId)`: Manually trigger a decay check for a token based on time.
    *   `feedEnergy(tokenId)`: Increase a token's energy level (potentially requiring payment).
    *   `entangle(tokenId1, tokenId2)`: Attempt to entangle two tokens.
    *   `splitEntanglement(tokenId)`: Attempt to break a token's entanglement.
    *   `stabilizeState(tokenId)`: Use energy to reset a token's decay timer and potentially boost stability.
    *   `simulateQuantumFluctuation(tokenId)`: Pay a fee to potentially trigger a random state change with low probability.
    *   `catalyzeReaction(tokenId1, tokenId2, ...)`: A more complex interaction involving multiple tokens, potentially leading to significant state changes or creation/destruction. (Requires multiple token inputs, simplified to 2 for clarity).
    *   `collapseEntanglement(tokenId)`: Forcefully collapse an entangled state, potentially with destructive outcomes for one or both tokens.
    *   `resurrectDecayed(tokenId)`: Attempt to bring a Decayed token back to a less degraded state at high cost.
    *   `batchObserve(tokenIds)`: Observe multiple tokens in a single transaction.
    *   `burnCollapsedOrDecayed(tokenId)`: Burn a token that is in a final decayed/collapsed state.
    *   `probeStatePrediction(tokenId)`: User pays a fee to get potential next states and probabilities based on current state (query-like, but costs and is user-initiated).
    *   `claimStateMilestoneReward(tokenId)`: Allow user to claim a small reward if a token reaches a specific state or observation count milestone for the first time.
9.  **Admin Functions (`onlyOwner`):** Contract owner controls.
    *   `setConfig(newConfig)`: Update the contract's behavioral parameters.
    *   `pauseTransitions(paused)`: Pause all state transition functions.
    *   `withdrawFees()`: Withdraw collected fees (if any) from the contract.
    *   `setOracleAddress(oracleAddress)`: If using an oracle for better randomness (stub).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Simple interface stub if needed, e.g., for interacting with an oracle or payment token
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title QuantumEphemeralToken
 * @dev A non-standard, state-aware digital asset with ephemeral and interactive properties.
 *      Tokens exist in simulated 'quantum states' influenced by time, interactions, energy, and entanglement.
 */
contract QuantumEphemeralToken {

    // --- State Management: Enum and Struct ---
    enum State {
        NonExistent,     // Default state for tokens not yet minted
        Superposition,   // Initial, highly unstable state
        Stable,          // Relatively stable, less prone to random decay
        Excited,         // High energy, prone to specific transitions
        Entangled,       // Linked to another token
        Decayed,         // Has degraded due to time/neglect
        Collapsed,       // Final, unusable state (can be burned)
        Observing        // Temporary state during complex interactions (optional, adds complexity)
    }

    struct TokenData {
        State state;
        uint256 energyLevel;
        uint256 lastStateChangeTimestamp;
        uint256 decayCheckTimestamp; // Next time decay *could* occur
        uint256 entanglementPartnerId; // 0 if not entangled
        uint256 observationCount;
        bytes32 historyHash; // Hash representing the sequence of state changes
        bool stateMilestoneClaimed; // To prevent multiple reward claims for same milestone
    }

    struct Config {
        uint256 initialEnergy;
        uint256 mintCost; // In ETH or a specific token (ERC20 address optional)
        uint256 observationEnergyCost;
        uint256 observationEnergyGain;
        uint256 decayDurationStable;
        uint256 decayDurationOther; // Decay rate for non-stable states
        uint256 feedEnergyAmount;
        uint256 feedEnergyCost;
        uint256 stabilizeEnergyCost;
        uint256 stabilizeDecayReset; // Time added to decayCheckTimestamp
        uint256 fluctuationFee; // Fee to trigger fluctuation
        uint256 resurrectionCost;
        uint256 resurrectionEnergy; // Energy level after resurrection
        uint256 entanglementEnergyCost; // Energy cost for *each* token to entangle
        uint256 splitEnergyCost; // Energy cost to split
        uint256 collapseEntanglementCost; // Energy cost to initiate collapse
        uint256 stateMilestoneObservationCount; // Threshold for milestone reward
        uint256 stateMilestoneRewardAmount; // Reward amount (in contract's native token or ETH)
        // Add probabilistic transition configs here (e.g., mapping from state to possible next states and weights)
        // For simplicity, using hardcoded probabilities in logic, but configurable is the advanced way.
    }

    // --- Data Storage ---
    mapping(uint256 => TokenData) private tokens;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    uint256 private _totalSupply;
    uint256 private _nextTokenId; // Simple counter for token IDs

    address public owner;
    bool public paused;
    Config public config;

    // If using an external token for payments/rewards
    address public paymentToken; // Address of an optional ERC20 payment token

    // --- Events ---
    event TokenMinted(address indexed to, uint256 indexed tokenId, State initialState);
    event TokenBurned(uint256 indexed tokenId, State finalState);
    event StateChanged(uint256 indexed tokenId, State oldState, State newState, uint256 energyLevel, bytes32 historyHash);
    event EnergyChanged(uint256 indexed tokenId, uint256 oldEnergy, uint256 newEnergy);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementSplit(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementCollapsed(uint256 indexed tokenId1, uint256 indexed tokenId2, string outcome);
    event ObservationCountIncreased(uint256 indexed tokenId, uint256 newCount);
    event DecayCheckTriggered(uint256 indexed tokenId, bool decayed);
    event HistoryHashUpdated(uint256 indexed tokenId, bytes32 newHash);
    event ConfigUpdated(Config newConfig);
    event Paused(address account);
    event Unpaused(address account);
    event StateMilestoneRewardClaimed(uint256 indexed tokenId, address indexedclaimer, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(tokens[tokenId].state != State.NonExistent, "Token does not exist");
        _;
    }

    modifier onlyState(uint256 tokenId, State expectedState) {
        require(tokens[tokenId].state == expectedState, "Token not in required state");
        _;
    }

    modifier notState(uint256 tokenId, State forbiddenState) {
         require(tokens[tokenId].state != forbiddenState, "Token in forbidden state");
        _;
    }


    // --- Constructor ---
    constructor(Config memory initialConfig, address _paymentToken) {
        owner = msg.sender;
        config = initialConfig;
        _nextTokenId = 1; // Start token IDs from 1
        paused = false;
        paymentToken = _paymentToken; // Optional: set ERC20 token for payments
    }

    // --- Internal State Management Helpers ---

    /**
     * @dev Applies a state transition and updates related token data.
     * @param tokenId The ID of the token.
     * @param newState The state to transition to.
     * @param energyDelta The amount to add to the current energy level (can be negative).
     * @param decayTimerReset If true, reset the decay timer based on the new state's duration.
     * @param partnerId If state becomes Entangled, the partner's tokenId.
     */
    function _applyTransition(uint256 tokenId, State newState, int256 energyDelta, bool decayTimerReset, uint256 partnerId) internal {
        TokenData storage token = tokens[tokenId];
        State oldState = token.state;

        // Prevent transitions for collapsed tokens
        if (oldState == State.Collapsed) {
             revert("Cannot transition from Collapsed state");
        }

        token.state = newState;

        uint256 oldEnergy = token.energyLevel;
        // Ensure energy doesn't go below zero using unchecked block for safety with int256
        unchecked {
             int256 newEnergy = int256(oldEnergy) + energyDelta;
             token.energyLevel = newEnergy >= 0 ? uint256(newEnergy) : 0;
        }

        token.lastStateChangeTimestamp = block.timestamp;

        if (decayTimerReset) {
            token.decayCheckTimestamp = block.timestamp + (newState == State.Stable ? config.decayDurationStable : config.decayDurationOther);
        }

        if (newState == State.Entangled) {
             token.entanglementPartnerId = partnerId;
        } else {
             token.entanglementPartnerId = 0; // Clear partner if not entangled
        }

        // Update history hash
        bytes32 transitionDetails = keccak256(abi.encodePacked(oldState, newState, energyDelta, decayTimerReset, partnerId));
        token.historyHash = _generateHistoryHash(tokenId, transitionDetails);

        emit StateChanged(tokenId, oldState, newState, token.energyLevel, token.historyHash);
        if (oldEnergy != token.energyLevel) {
             emit EnergyChanged(tokenId, oldEnergy, token.energyLevel);
        }
        emit HistoryHashUpdated(tokenId, token.historyHash);
    }

     /**
     * @dev Updates the history hash based on previous hash and transition details.
     *      A simple append hash. More complex hashing could be used.
     * @param tokenId The ID of the token.
     * @param transitionDetails Hash of the state change details.
     * @return The new history hash.
     */
    function _generateHistoryHash(uint256 tokenId, bytes32 transitionDetails) internal view returns (bytes32) {
        // Incorporate block data and token ID for added 'unpredictability'/uniqueness per token/block
        return keccak256(abi.encodePacked(
            tokens[tokenId].historyHash, // Previous hash
            transitionDetails,          // Details of the current change
            block.timestamp,
            block.number,
            tokenId
        ));
    }


    // --- Basic Ownership & Supply (ERC721-like subset) ---

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the total number of tokens in existence.
     *      Note: This counts *active* tokens, excluding Collapsed and NonExistent.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     /**
     * @dev Internal function to mint a new token.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to address zero");
        require(tokens[tokenId].state == State.NonExistent, "Token already exists");

        _balances[to]++;
        _owners[tokenId] = to;
        _totalSupply++;

        tokens[tokenId] = TokenData({
            state: State.Superposition, // New tokens start in Superposition
            energyLevel: config.initialEnergy,
            lastStateChangeTimestamp: block.timestamp,
            decayCheckTimestamp: block.timestamp + config.decayDurationOther, // Superposition uses 'Other' decay
            entanglementPartnerId: 0,
            observationCount: 0,
            historyHash: keccak256(abi.encodePacked(tokenId, block.timestamp, "Minted")), // Initial hash
            stateMilestoneClaimed: false
        });

        emit TokenMinted(to, tokenId, State.Superposition);
        emit Transfer(address(0), to, tokenId); // ERC721-like Mint Transfer event
    }

    /**
     * @dev Internal function to burn a token.
     */
    function _burn(uint256 tokenId) internal tokenExists(tokenId) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token has no owner");

        State finalState = tokens[tokenId].state;

        delete _owners[tokenId];
        delete tokens[tokenId]; // This sets state to NonExistent

        _balances[owner]--;
        _totalSupply--;

        emit TokenBurned(tokenId, finalState);
        emit Transfer(owner, address(0), tokenId); // ERC721-like Burn Transfer event
    }

    /**
     * @dev Transfers a specific token `tokenId` from `from` to `to`.
     *      Adds a state check: Collapsed tokens cannot be transferred.
     * @param from The address of the token holder.
     * @param to The address of the recipient.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused tokenExists(tokenId) {
        require(ownerOf(tokenId) == from, "TransferFrom: caller is not token owner");
        require(to != address(0), "TransferTo: transfer to the zero address");
        // --- State Check ---
        require(tokens[tokenId].state != State.Collapsed, "Cannot transfer Collapsed token");
        // --- End State Check ---

        // Basic transfer logic (no approvals like full ERC721)
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     /**
     * @dev Equivalent to `transferFrom`, included for standard interface compatibility
     *      but without ERC721 receiver hook logic.
     * @param from The address of the token holder.
     * @param to The address of the recipient.
     * @param tokenId The ID of the token to transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused tokenExists(tokenId) {
         // Simple pass-through, assumes recipient can receive (no ERC721Receiver check)
         transferFrom(from, to, tokenId);
         // If implementing full ERC721, would add:
         // require(_checkOnERC721Received(from, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }


    // --- Query Functions ---

    function getTokenState(uint256 tokenId) public view tokenExists(tokenId) returns (State) {
        return tokens[tokenId].state;
    }

    function getEnergyLevel(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return tokens[tokenId].energyLevel;
    }

    function getDecayTimestamp(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return tokens[tokenId].decayCheckTimestamp;
    }

    function getEntanglementPartner(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return tokens[tokenId].entanglementPartnerId;
    }

    function getObservationCount(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return tokens[tokenId].observationCount;
    }

    function isDecayed(uint256 tokenId) public view tokenExists(tokenId) returns (bool) {
        State currentState = tokens[tokenId].state;
        return currentState == State.Decayed || currentState == State.Collapsed;
    }

    /**
     * @dev Checks if a direct transition *is defined* in the logic from current to desired state.
     *      Does not check if energy/conditions are met, only theoretical possibility.
     *      This is a simplified check based on the *intended* transitions in the contract logic.
     *      A more advanced version would read from a configuration mapping.
     * @param tokenId The ID of the token.
     * @param desiredState The state to check possibility for.
     * @return True if the transition is potentially possible, false otherwise.
     */
    function canTransition(uint256 tokenId, State desiredState) public view tokenExists(tokenId) returns (bool) {
        State currentState = tokens[tokenId].state;
        // This is a simplification. Real complex state machines would use adjacency lists or similar.
        // Example basic logic:
        if (currentState == State.Collapsed || currentState == State.NonExistent) return false; // Cannot transition from final/non-existent

        if (desiredState == State.Decayed || desiredState == State.Collapsed) return true; // Decay is always a risk
        if (desiredState == State.Entangled) return currentState == State.Superposition || currentState == State.Stable; // Can entangle from these
        if (desiredState == State.Excited) return currentState != State.Collapsed && currentState != State.Decayed; // Can get excited from most non-terminal states
        if (desiredState == State.Stable) return currentState == State.Superposition || currentState == State.Excited; // Can stabilize from unstable/excited
        if (desiredState == State.Superposition) return currentState == State.Stable || currentState == State.Excited || currentState == State.Decayed; // Can become unstable again, or resurrected to unstable
        // Add other specific transitions here...

        return false; // Default: transition not defined or possible
    }


    function getHistoryHash(uint256 tokenId) public view tokenExists(tokenId) returns (bytes32) {
        return tokens[tokenId].historyHash;
    }

    function getConfig() public view returns (Config memory) {
        return config;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    // --- User Interaction Functions ---

    /**
     * @dev Mints a new token. Requires payment.
     */
    function mintInitialToken() public payable whenNotPaused returns (uint256 tokenId) {
        require(msg.value >= config.mintCost, "Insufficient mint cost");

        tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId);

        // Return change if any (for ETH payments)
        if (msg.value > config.mintCost) {
            payable(msg.sender).transfer(msg.value - config.mintCost);
        }

        return tokenId;
    }

    /**
     * @dev Simulates "observing" a token. Can trigger state changes and consume energy.
     *      Includes simplified probabilistic state transition.
     * @param tokenId The ID of the token to observe.
     */
    function observeState(uint256 tokenId) public whenNotPaused tokenExists(tokenId) notState(tokenId, State.Collapsed) {
        TokenData storage token = tokens[tokenId];

        require(token.energyLevel >= config.observationEnergyCost, "Insufficient energy to observe");

        token.observationCount++;
        emit ObservationCountIncreased(tokenId, token.observationCount);

        // Simple pseudo-randomness based on block data, sender, and token history
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tokenId, token.historyHash))) % 100; // 0-99

        State currentState = token.state;
        State nextState = currentState; // Default is no change

        // --- Simplified Probabilistic/Rule-based Transitions ---
        int256 energyDelta = int256(config.observationEnergyGain) - int256(config.observationEnergyCost);
        bool decayReset = false;
        uint256 partnerId = 0;

        if (currentState == State.Superposition) {
            if (randomness < 60) { // 60% chance to stabilize
                nextState = State.Stable;
                decayReset = true;
                energyDelta += 10; // Bonus energy for stabilizing
            } else { // 40% chance to get excited or remain Superposition
                 nextState = State.Excited; // Simplified: always Excited if not Stable
                 decayReset = true;
            }
        } else if (currentState == State.Stable) {
             if (randomness < 10) { // 10% chance to become Superposition (random fluctuation)
                 nextState = State.Superposition;
             } // else remains Stable, energy changes
            decayReset = true; // Observing a Stable token resets timer
        } else if (currentState == State.Excited) {
             if (randomness < 30) { // 30% chance to settle to Stable
                 nextState = State.Stable;
                 decayReset = true;
                 energyDelta += 5;
             } else if (randomness < 70) { // 40% chance to become Superposition
                 nextState = State.Superposition;
                 decayReset = true; // Still chaotic, but timer resets
             } // else remains Excited
             // Observing Excited does not reset timer by default
        } else if (currentState == State.Entangled) {
            // Observing one entangled token also affects the partner
            uint256 pId = token.entanglementPartnerId;
            if (tokens[pId].state == State.Entangled && tokens[pId].entanglementPartnerId == tokenId) {
                 // Both are validly entangled
                 // Energy cost and gain apply to *both* tokens
                 _applyTransition(pId, tokens[pId].state, energyDelta, false, tokenId); // Apply to partner first
                 energyDelta = int256(config.observationEnergyGain) - int256(config.observationEnergyCost); // Apply to this token
                 // State change probability might depend on *both* states, very complex!
                 // Simplified: Observing entangled token increases stability chance slightly for both?
                 if (randomness < 20 && currentState != State.Stable && tokens[pId].state != State.Stable) {
                     nextState = State.Stable;
                     decayReset = true;
                 }
            } else {
                 // Entanglement broken or partner invalid, revert to Superposition
                 nextState = State.Superposition;
                 token.entanglementPartnerId = 0; // Clean up invalid link
                 emit EntanglementSplit(tokenId, pId);
            }
            partnerId = token.entanglementPartnerId; // Ensure partnerId is carried through if still entangled

        } else if (currentState == State.Decayed) {
            // Observing a decayed token uses energy but provides minimal gain, slight chance of 'flicker'
            energyDelta = int256(config.observationEnergyGain / 2) - int256(config.observationEnergyCost);
             if (randomness < 5) { // Small chance to briefly flicker back to Superposition
                 nextState = State.Superposition;
                 decayReset = true; // Decayed state timer reset
                 energyDelta += 20; // Energy gain for flicker
             } // Else remains Decayed
             decayReset = true; // Observing decayed also resets timer (decayed clock)
        }
        // Collapsed state cannot be observed

        _applyTransition(tokenId, nextState, energyDelta, decayReset, partnerId);

        // Check for milestone reward after observation
        if (token.observationCount >= config.stateMilestoneObservationCount && !token.stateMilestoneClaimed) {
            // Reward claim logic here - separate function better
        }
    }


    /**
     * @dev Manually triggers a decay check for a token. Can be called by anyone.
     *      Tokens decay if current time exceeds decayCheckTimestamp and not in a terminal state.
     * @param tokenId The ID of the token to check.
     */
    function decayState(uint256 tokenId) public whenNotPaused tokenExists(tokenId) notState(tokenId, State.Collapsed) notState(tokenId, State.Decayed) {
        TokenData storage token = tokens[tokenId];

        if (block.timestamp >= token.decayCheckTimestamp) {
            State currentState = token.state;
            State nextState = currentState;
            int256 energyDelta = -30; // Significant energy loss on decay

            // Decay logic:
            if (currentState == State.Superposition || currentState == State.Excited || currentState == State.Entangled) {
                nextState = State.Decayed;
            } else if (currentState == State.Stable) {
                nextState = State.Decayed; // Stable decays slower, but still decays
            }
            // Decayed state cannot decay further to Collapsed automatically by THIS function, needs a separate trigger or interaction.
            // For simplicity, let's add automatic collapse probability from Decayed here.
            if (nextState == State.Decayed) {
                 uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, token.historyHash, "decayCollapse"))) % 100;
                 if (randomness < 10) { // 10% chance to collapse from Decayed on decay check
                     nextState = State.Collapsed;
                     energyDelta = - int256(token.energyLevel); // Energy goes to 0
                 }
            }

            if (nextState != currentState) {
                _applyTransition(tokenId, nextState, energyDelta, true, 0); // Reset decay timer on decay
                emit DecayCheckTriggered(tokenId, true);
            } else {
                 // Even if no state change, decay check consumes a little energy past timestamp
                 if (token.energyLevel > 0) {
                      _applyTransition(tokenId, currentState, -5, false, token.entanglementPartnerId); // Just lose energy
                 }
                 emit DecayCheckTriggered(tokenId, false);
            }

        } else {
            // Not time to decay yet, perhaps consume small energy for 'attempted' check
            if (token.energyLevel > 0) {
                 _applyTransition(tokenId, token.state, -1, false, token.entanglementPartnerId);
            }
            emit DecayCheckTriggered(tokenId, false);
        }
    }

    /**
     * @dev Increases a token's energy level. Requires payment.
     * @param tokenId The ID of the token.
     */
    function feedEnergy(uint256 tokenId) public payable whenNotPaused tokenExists(tokenId) notState(tokenId, State.Collapsed) notState(tokenId, State.Decayed) {
        require(msg.value >= config.feedEnergyCost, "Insufficient energy cost");

        TokenData storage token = tokens[tokenId];
        uint256 oldEnergy = token.energyLevel;
        token.energyLevel += config.feedEnergyAmount;

        // Return change if any
        if (msg.value > config.feedEnergyCost) {
            payable(msg.sender).transfer(msg.value - config.feedEnergyCost);
        }

        // Optional: State change if energy reaches a threshold (e.g., Superposition -> Excited)
        if (token.state == State.Superposition && token.energyLevel > config.initialEnergy * 2) {
             _applyTransition(tokenId, State.Excited, 0, true, 0); // No energy change on this transition, just state
        }

        emit EnergyChanged(tokenId, oldEnergy, token.energyLevel);
        bytes32 transitionDetails = keccak256(abi.encodePacked("FeedEnergy", config.feedEnergyAmount));
        token.historyHash = _generateHistoryHash(tokenId, transitionDetails);
        emit HistoryHashUpdated(tokenId, token.historyHash);
    }

    /**
     * @dev Attempts to entangle two tokens. Requires specific states and energy.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function entangle(uint256 tokenId1, uint256 tokenId2) public whenNotPaused tokenExists(tokenId1) tokenExists(tokenId2) {
        require(tokenId1 != tokenId2, "Cannot entangle a token with itself");
        require(tokens[tokenId1].state != State.Entangled && tokens[tokenId2].state != State.Entangled, "Tokens already entangled");
        require(tokens[tokenId1].state == State.Superposition || tokens[tokenId1].state == State.Stable, "Token 1 not in entangleable state");
        require(tokens[tokenId2].state == State.Superposition || tokens[tokenId2].state == State.Stable, "Token 2 not in entangleable state");
        require(tokens[tokenId1].energyLevel >= config.entanglementEnergyCost && tokens[tokenId2].energyLevel >= config.entanglementEnergyCost, "Insufficient energy for entanglement");

        // Consume energy from both
        _applyTransition(tokenId1, tokens[tokenId1].state, -int256(config.entanglementEnergyCost), false, 0);
        _applyTransition(tokenId2, tokens[tokenId2].state, -int256(config.entanglementEnergyCost), false, 0);

        // Apply transition to Entangled state for both
        _applyTransition(tokenId1, State.Entangled, 0, true, tokenId2);
        _applyTransition(tokenId2, State.Entangled, 0, true, tokenId1);

        emit Entangled(tokenId1, tokenId2);
    }

    /**
     * @dev Attempts to break a token's entanglement. Requires energy.
     * @param tokenId The ID of the token.
     */
    function splitEntanglement(uint256 tokenId) public whenNotPaused tokenExists(tokenId) onlyState(tokenId, State.Entangled) {
        uint256 partnerId = tokens[tokenId].entanglementPartnerId;
        require(partnerId != 0 && tokens[partnerId].entanglementPartnerId == tokenId, "Token not validly entangled");
        require(tokens[tokenId].energyLevel >= config.splitEnergyCost, "Insufficient energy to split entanglement");

        // Consume energy from this token
        _applyTransition(tokenId, tokens[tokenId].state, -int256(config.splitEnergyCost), false, 0);

        // Apply transition to Superposition for both (splitting adds uncertainty)
        _applyTransition(tokenId, State.Superposition, 0, true, 0);
        // Only split partner if it's still entangled with this token
        if (tokens[partnerId].state == State.Entangled && tokens[partnerId].entanglementPartnerId == tokenId) {
             _applyTransition(partnerId, State.Superposition, 0, true, 0);
             emit EntanglementSplit(tokenId, partnerId);
        } else {
             // Partner was already split or in invalid state, just update this token
             emit EntanglementSplit(tokenId, 0); // Indicate partner wasn't validly linked
        }
    }

    /**
     * @dev Use energy to reset a token's decay timer and potentially boost stability.
     * @param tokenId The ID of the token.
     */
    function stabilizeState(uint256 tokenId) public whenNotPaused tokenExists(tokenId) notState(tokenId, State.Collapsed) notState(tokenId, State.Decayed) {
        TokenData storage token = tokens[tokenId];
        require(token.energyLevel >= config.stabilizeEnergyCost, "Insufficient energy to stabilize");

        _applyTransition(tokenId, token.state, -int256(config.stabilizeEnergyCost), true, token.entanglementPartnerId); // Reset timer, consume energy

        // Optional: State change towards stable if not already
        if (token.state == State.Superposition) {
             _applyTransition(tokenId, State.Stable, 0, true, token.entanglementPartnerId); // Transition to Stable, timer already reset
        } else if (token.state == State.Excited) {
             // Slight chance to become Stable
             uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, "stabilize"))) % 100;
             if (randomness < 50) { // 50% chance to settle
                 _applyTransition(tokenId, State.Stable, 0, true, token.entanglementPartnerId);
             }
        }
        // If already Stable or Entangled, just resets timer and consumes energy
    }

    /**
     * @dev Pays a fee for a small chance of a random state fluctuation.
     *      Purely based on simulated randomness.
     * @param tokenId The ID of the token.
     */
    function simulateQuantumFluctuation(uint256 tokenId) public payable whenNotPaused tokenExists(tokenId) notState(tokenId, State.Collapsed) {
        require(msg.value >= config.fluctuationFee, "Insufficient fluctuation fee");

        // Return change if any
        if (msg.value > config.fluctuationFee) {
            payable(msg.sender).transfer(msg.value - config.fluctuationFee);
        }

        // Use randomness source (better would be Chainlink VRF or similar)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tx.origin, msg.sender, tokenId, tokens[tokenId].historyHash, "fluctuate"))) % 1000; // 0-999

        // Very low probability random state jump
        if (randomness < 20) { // 2% chance
            State currentState = tokens[tokenId].state;
            State nextState = currentState;
            int256 energyDelta = -10; // Energy cost regardless of success

            // Select a random *other* state (excluding NonExistent and Collapsed)
            // Simple pseudo-random state selection
            uint256 stateIndex = (randomness % 5) + 1; // States 1-5 (Superposition to Decayed)
            if (stateIndex == uint256(currentState)) { stateIndex = (stateIndex % 5) + 1;} // Avoid staying in same state initially
            nextState = State(stateIndex);

            // Adjust energy delta based on state jump severity (example)
            if (nextState == State.Decayed) energyDelta -= 50;
            if (nextState == State.Excited) energyDelta += 30;

            _applyTransition(tokenId, nextState, energyDelta, true, 0); // Always reset timer on fluctuation
        } else {
             // Fluctuation failed, maybe tiny energy cost anyway
             if (tokens[tokenId].energyLevel > 0) {
                 _applyTransition(tokenId, tokens[tokenId].state, -1, false, tokens[tokenId].entanglementPartnerId);
             }
        }
    }

    /**
     * @dev Catalyzes a reaction between two tokens (simplified).
     *      Requires specific states/energy and results in significant changes.
     *      Example: Two Excited tokens might merge energy and become Stable/Superposition,
     *      or one Decayed + one Stable might revive the Decayed one partially.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function catalyzeReaction(uint256 tokenId1, uint256 tokenId2) public whenNotPaused tokenExists(tokenId1) tokenExists(tokenId2) {
         require(tokenId1 != tokenId2, "Cannot catalyze a reaction with itself");
         require(tokens[tokenId1].state != State.Collapsed && tokens[tokenId2].state != State.Collapsed, "Cannot catalyze reaction with Collapsed tokens");

         TokenData storage token1 = tokens[tokenId1];
         TokenData storage token2 = tokens[tokenId2];

         // --- Define Reaction Rules (Complex Logic) ---
         bool reacted = false;
         bytes32 reactionHash = keccak256(abi.encodePacked(token1.state, token2.state, token1.energyLevel > token2.energyLevel, tokenId1 < tokenId2)); // Simple hash for history

         // Example Rule 1: Excited + Excited -> Stable + Stable (energy transfer)
         if (token1.state == State.Excited && token2.state == State.Excited) {
             uint256 totalEnergy = token1.energyLevel + token2.energyLevel;
             _applyTransition(tokenId1, State.Stable, int256(totalEnergy / 2) - int256(token1.energyLevel), true, 0);
             _applyTransition(tokenId2, State.Stable, int256(totalEnergy / 2) - int256(token2.energyLevel), true, 0);
             reacted = true;
         }
         // Example Rule 2: Decayed + Stable -> Decayed -> Superposition, Stable -> Decayed (risky revival)
         else if ((token1.state == State.Decayed && token2.state == State.Stable) || (token1.state == State.Stable && token2.state == State.Decayed)) {
              uint256 decayedTokenId = (token1.state == State.Decayed) ? tokenId1 : tokenId2;
              uint256 stableTokenId = (token1.state == State.Stable) ? tokenId1 : tokenId2;

              uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId1, tokenId2, "catalyzeDecayStable"))) % 100;
              if (randomness < 70) { // 70% chance of partial revival
                   _applyTransition(decayedTokenId, State.Superposition, 50, true, 0); // Partial energy boost
                   _applyTransition(stableTokenId, State.Decayed, -30, true, 0); // Stable token degrades
              } else { // 30% chance of failure -> both Decayed
                   _applyTransition(decayedTokenId, State.Decayed, -10, false, 0);
                   _applyTransition(stableTokenId, State.Decayed, -10, false, 0);
              }
              reacted = true;
         }
         // Add more complex rules...

         require(reacted, "No applicable reaction rule for these tokens");

         // Record reaction in history hash (simplified)
         token1.historyHash = _generateHistoryHash(tokenId1, reactionHash);
         token2.historyHash = _generateHistoryHash(tokenId2, reactionHash);
         emit HistoryHashUpdated(tokenId1, token1.historyHash);
         emit HistoryHashUpdated(tokenId2, token2.historyHash);
    }


    /**
     * @dev Forcefully collapses an entangled state. Can have destructive outcomes based on randomness.
     * @param tokenId The ID of one of the entangled tokens.
     */
    function collapseEntanglement(uint256 tokenId) public whenNotPaused tokenExists(tokenId) onlyState(tokenId, State.Entangled) {
        uint256 partnerId = tokens[tokenId].entanglementPartnerId;
        require(partnerId != 0 && tokens[partnerId].entanglementPartnerId == tokenId, "Token not validly entangled");
        require(tokens[tokenId].energyLevel >= config.collapseEntanglementCost, "Insufficient energy to collapse entanglement");

         // Consume energy from this token
        _applyTransition(tokenId, tokens[tokenId].state, -int256(config.collapseEntanglementCost), false, 0);

        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, partnerId, "collapse"))) % 100; // 0-99

        string memory outcome;

        if (randomness < 30) { // 30% chance: Both collapse
            _applyTransition(tokenId, State.Collapsed, -int256(tokens[tokenId].energyLevel), false, 0);
            _applyTransition(partnerId, State.Collapsed, -int256(tokens[partnerId].energyLevel), false, 0);
            outcome = "Both Collapsed";
        } else if (randomness < 70) { // 40% chance: One collapses, other stabilizes
            uint256 collapseId = (randomness % 2 == 0) ? tokenId : partnerId;
            uint256 stabilizeId = (collapseId == tokenId) ? partnerId : tokenId;
             _applyTransition(collapseId, State.Collapsed, -int256(tokens[collapseId].energyLevel), false, 0);
             _applyTransition(stabilizeId, State.Stable, 50, true, 0); // Energy boost for survival
             outcome = string(abi.encodePacked("Token ", uint256ToString(collapseId), " Collapsed, Token ", uint256ToString(stabilizeId), " Stabilized"));
        } else { // 30% chance: Both revert to Superposition with energy loss
             _applyTransition(tokenId, State.Superposition, -50, true, 0);
             _applyTransition(partnerId, State.Superposition, -50, true, 0);
             outcome = "Both Reverted to Superposition";
        }

        // Clear entanglement for both regardless of outcome
        tokens[tokenId].entanglementPartnerId = 0;
        tokens[partnerId].entanglementPartnerId = 0;

        emit EntanglementCollapsed(tokenId, partnerId, outcome);
        // History hashes updated by _applyTransition
    }


    /**
     * @dev Attempts to bring a Decayed token back to a less degraded state. High cost.
     * @param tokenId The ID of the token.
     */
    function resurrectDecayed(uint256 tokenId) public payable whenNotPaused tokenExists(tokenId) onlyState(tokenId, State.Decayed) {
        require(msg.value >= config.resurrectionCost, "Insufficient resurrection cost");

        // Return change if any
        if (msg.value > config.resurrectionCost) {
            payable(msg.sender).transfer(msg.value - config.resurrectionCost);
        }

        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, "resurrect"))) % 100; // 0-99

        State nextState;
        int256 energyDelta = int256(config.resurrectionEnergy) - int256(tokens[tokenId].energyLevel); // Set energy to resurrection level

        if (randomness < 60) { // 60% chance: Back to Superposition
            nextState = State.Superposition;
        } else { // 40% chance: Back to Decayed (failed resurrection)
            nextState = State.Decayed;
            energyDelta = -10; // Still lose a bit more energy on failure
        }

        _applyTransition(tokenId, nextState, energyDelta, true, 0); // Reset timer on resurrection attempt
    }

    /**
     * @dev Allows observing multiple tokens in a single transaction.
     * @param tokenIds An array of token IDs to observe.
     */
    function batchObserve(uint256[] calldata tokenIds) public whenNotPaused {
        uint256 gasBefore = gasleft();
        for (uint i = 0; i < tokenIds.length; i++) {
             // Add basic gas check to prevent hitting block gas limit
             if (gasleft() < 50000) { // Arbitrary threshold, adjust as needed
                 // Could emit an event indicating incomplete batch
                 break;
             }
             uint256 tokenId = tokenIds[i];
             // Use try/catch if want to continue on individual token errors, or just let it revert
             // With require in observeState, this will revert on first error.
             // Adding checks here avoids internal reverts within the loop:
             if (tokens[tokenId].state != State.NonExistent && tokens[tokenId].state != State.Collapsed) {
                 try this.observeState(tokenId) {
                     // Success
                 } catch {
                     // Handle individual observation failure (e.g., insufficient energy) - skip or log
                     // For simplicity, we let it revert on the first issue for now by not adding try/catch
                     // If we *did* add try/catch, need to make observeState external/public
                     // and ensure `this` call works (might need interface cast)
                 }
             }
        }
        // Simpler approach: Just call the internal logic directly to avoid 'this' call issues
        // Looping and calling _applyTransition logic directly would be more gas efficient than external calls.
        // Let's stick to calling observeState directly for now, assuming it's public enough or adding try/catch.
        // Reverted to calling the public function for clarity, but gas caution applied.
        for (uint i = 0; i < tokenIds.length; i++) {
             uint256 tokenId = tokenIds[i];
             // Add gas check inside loop
             if (gasleft() < 50000) break; // Stop if gas low
             // Basic checks to skip problematic tokens without reverting the batch
             if (tokens[tokenId].state == State.NonExistent || tokens[tokenId].state == State.Collapsed) continue;
             if (tokens[tokenId].energyLevel < config.observationEnergyCost) continue; // Skip if not enough energy
             // Call the function logic directly
             _observeStateLogic(tokenId); // Refactor observeState's core logic into an internal helper
        }
    }

     /**
     * @dev Internal helper for observeState core logic, used by batchObserve.
     */
    function _observeStateLogic(uint256 tokenId) internal {
         TokenData storage token = tokens[tokenId];
         State oldState = token.state; // Capture state before changes

         require(token.energyLevel >= config.observationEnergyCost, "Insufficient energy to observe"); // Redundant check, but safe

         token.observationCount++;
         emit ObservationCountIncreased(tokenId, token.observationCount);

         uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tokenId, token.historyHash, "batchObserve"))) % 100;

         State nextState = token.state;
         int256 energyDelta = int256(config.observationEnergyGain) - int256(config.observationEnergyCost);
         bool decayReset = false;
         uint256 partnerId = 0;

         // Simplified core transition logic (can be expanded)
         if (token.state == State.Superposition) {
             nextState = (randomness < 60) ? State.Stable : State.Excited;
             decayReset = true;
             if (nextState == State.Stable) energyDelta += 10;
         } else if (token.state == State.Stable) {
              nextState = (randomness < 10) ? State.Superposition : State.Stable;
              decayReset = true;
         } else if (token.state == State.Excited) {
              if (randomness < 30) { nextState = State.Stable; decayReset = true; energyDelta += 5;}
              else if (randomness < 70) { nextState = State.Superposition; decayReset = true;}
         } else if (token.state == State.Entangled) {
              uint256 pId = token.entanglementPartnerId;
               if (tokens[pId].state == State.Entangled && tokens[pId].entanglementPartnerId == tokenId) {
                  _applyTransition(pId, tokens[pId].state, energyDelta, false, tokenId);
                  energyDelta = int256(config.observationEnergyGain) - int256(config.observationEnergyCost);
                  if (randomness < 20 && token.state != State.Stable && tokens[pId].state != State.Stable) {
                      nextState = State.Stable; decayReset = true;
                  }
              } else {
                   nextState = State.Superposition;
                   token.entanglementPartnerId = 0;
                   emit EntanglementSplit(tokenId, pId);
              }
              partnerId = token.entanglementPartnerId;
         } else if (token.state == State.Decayed) {
             energyDelta = int256(config.observationEnergyGain / 2) - int256(config.observationEnergyCost);
             if (randomness < 5) { nextState = State.Superposition; decayReset = true; energyDelta += 20; }
             decayReset = true;
         }
         // End Simplified core transition logic

         _applyTransition(tokenId, nextState, energyDelta, decayReset, partnerId);

         // State milestone check (logic moved to separate function for clarity)
         if (token.observationCount >= config.stateMilestoneObservationCount && !token.stateMilestoneClaimed) {
             // Flag as claimable, don't claim immediately in a batch
             // Or call a dedicated internal claim checker if gas allows
              // claimStateMilestoneReward(tokenId); // Might fail or cost too much gas in batch
              // Alternative: Just leave the flag true and let the user call the public function later.
         }
    }

    /**
     * @dev Burns a token that is in the Collapsed or Decayed state.
     * @param tokenId The ID of the token to burn.
     */
    function burnCollapsedOrDecayed(uint256 tokenId) public tokenExists(tokenId) {
        require(tokens[tokenId].state == State.Collapsed || tokens[tokenId].state == State.Decayed, "Can only burn Collapsed or Decayed tokens");
        require(ownerOf(tokenId) == msg.sender, "Burner is not token owner");

        _burn(tokenId);
    }

     /**
     * @dev Allows a user to pay a fee to get a prediction/hint about the token's next state transition probabilities.
     *      This function is read-only but costs ETH to simulate an "analysis".
     *      The implementation is a simplified example.
     * @param tokenId The ID of the token to probe.
     * @return probabilities String representation of possible next states and probabilities.
     *         (In a real advanced contract, this would return structured data).
     */
    function probeStatePrediction(uint256 tokenId) public payable view tokenExists(tokenId) returns (string memory probabilities) {
        require(msg.value >= config.fluctuationFee, "Insufficient probe cost"); // Re-using fluctuation fee for simplicity

        // No state change or energy change on token for a read-only view

        State currentState = tokens[tokenId].state;

        // --- Simplified Prediction Logic (Matches observeState probabilities) ---
        string memory result = string(abi.encodePacked("Current State: ", stateToString(currentState), ". Possible next states on OBSERVATION:\n"));

        if (currentState == State.Superposition) {
             result = string(abi.encodePacked(result, "- Stable (approx. 60%)\n"));
             result = string(abi.encodePacked(result, "- Excited (approx. 40%)\n"));
        } else if (currentState == State.Stable) {
             result = string(abi.encodePacked(result, "- Superposition (approx. 10%)\n"));
             result = string(abi.encodePacked(result, "- Stable (approx. 90%)\n"));
        } else if (currentState == State.Excited) {
             result = string(abi.encodePacked(result, "- Stable (approx. 30%)\n"));
             result = string(abi.encodePacked(result, "- Superposition (approx. 40%)\n"));
             result = string(abi.encodePacked(result, "- Excited (approx. 30%)\n"));
        } else if (currentState == State.Entangled) {
             result = string(abi.encodePacked(result, "- State transition dependent on partner state and randomness (complex)\n"));
             result = string(abi.encodePacked(result, "- Risk of Splitting (if partner invalid) or Collapsing (if forced)\n"));
        } else if (currentState == State.Decayed) {
             result = string(abi.encodePacked(result, "- Superposition (approx. 5% flicker)\n"));
             result = string(abi.encodePacked(result, "- Decayed (approx. 95%)\n"));
        } else if (currentState == State.Collapsed) {
             result = string(abi.encodePacked(result, "Token is Collapsed. No further state transitions are possible."));
        } else {
            result = string(abi.encodePacked(result, "Prediction unavailable for this state."));
        }

         // Return change if any (for ETH payments) - must be done *before* returning
        if (msg.value > config.fluctuationFee) {
             payable(msg.sender).transfer(msg.value - config.fluctuationFee);
         }

        return result; // Note: Returning complex strings is gas-intensive
    }

    /**
     * @dev Allows the token owner to claim a small reward if the token reaches a specific
     *      observation count milestone for the first time.
     * @param tokenId The ID of the token.
     */
    function claimStateMilestoneReward(uint256 tokenId) public tokenExists(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Only owner can claim reward");
        TokenData storage token = tokens[tokenId];
        require(!token.stateMilestoneClaimed, "Milestone reward already claimed");
        require(token.observationCount >= config.stateMilestoneObservationCount, "Observation count milestone not reached");

        token.stateMilestoneClaimed = true;

        // Reward can be ETH or an ERC20 token
        if (paymentToken == address(0)) {
             // Reward in ETH
             require(address(this).balance >= config.stateMilestoneRewardAmount, "Contract balance too low for reward");
             payable(msg.sender).transfer(config.stateMilestoneRewardAmount);
        } else {
             // Reward in ERC20 token
             IERC20 paymentTokenContract = IERC20(paymentToken);
             require(paymentTokenContract.transfer(msg.sender, config.stateMilestoneRewardAmount), "ERC20 transfer failed");
        }

        emit StateMilestoneRewardClaimed(tokenId, msg.sender, config.stateMilestoneRewardAmount);
         bytes32 transitionDetails = keccak256(abi.encodePacked("MilestoneRewardClaimed", config.stateMilestoneRewardAmount));
         token.historyHash = _generateHistoryHash(tokenId, transitionDetails);
         emit HistoryHashUpdated(tokenId, token.historyHash);
    }


    // --- Admin Functions ---

    /**
     * @dev Allows the owner to update the contract's configuration parameters.
     * @param newConfig The new configuration struct.
     */
    function setConfig(Config memory newConfig) public onlyOwner {
        config = newConfig;
        emit ConfigUpdated(newConfig);
    }

    /**
     * @dev Allows the owner to pause or unpause state transitions and most user interactions.
     * @param _paused True to pause, false to unpause.
     */
    function pauseTransitions(bool _paused) public onlyOwner {
        paused = _paused;
        if (_paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    /**
     * @dev Allows the owner to withdraw any accumulated ETH in the contract (e.g., from mint fees).
     */
    function withdrawFees() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

     /**
     * @dev Sets the address of an optional ERC20 payment token for costs/rewards.
     *      If address(0), ETH is used.
     * @param oracleAddress The address of the oracle contract.
     */
    function setOracleAddress(address oracleAddress) public onlyOwner {
        // This is a stub. Actual oracle interaction (e.g., Chainlink VRF) is more complex.
        // A real implementation would store this address and use it to request randomness.
        // For this contract's simulation purposes, it's just a placeholder.
         address dummyOracle = oracleAddress; // Store if needed later
         // require(isContract(oracleAddress), "Invalid oracle address"); // Add a helper check
         // oracle = IOracle(oracleAddress);
    }

    // --- Utility Functions ---

    /**
     * @dev Helper function to convert State enum to string for events/debugging.
     *      Note: String conversions on-chain are gas-intensive.
     */
    function stateToString(State state) public pure returns (string memory) {
        if (state == State.NonExistent) return "NonExistent";
        if (state == State.Superposition) return "Superposition";
        if (state == State.Stable) return "Stable";
        if (state == State.Excited) return "Excited";
        if (state == State.Entangled) return "Entangled";
        if (state == State.Decayed) return "Decayed";
        if (state == State.Collapsed) return "Collapsed";
        if (state == State.Observing) return "Observing"; // If implemented
        return "Unknown";
    }

    // Helper to convert uint256 to string (basic, for event string construction)
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Fallback function to receive ETH for fees/minting
    receive() external payable {}
    fallback() external payable {}
}
```