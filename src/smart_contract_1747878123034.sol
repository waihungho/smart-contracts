Okay, this is a fascinating challenge! Let's create a contract that represents abstract "Quantum Entangled Tokens" (QETs). These tokens will behave differently based on simulated quantum concepts like entanglement, superposition, and measurement.

We'll base it loosely on ERC721 for ownership tracking, but add significant custom logic for state management and interaction. The core idea is that tokens can exist in a 'superposition' of potential states until 'measured', and when entangled, the 'flipping' of one token's state can deterministically affect its entangled partner based on predefined rules.

**Concept:** QuantumEntangledTokens (QETs)
*   **Token State:** Each token can be in superposition (state not fixed) or measured (state fixed).
*   **Potential State:** A token is minted with a potential state type (e.g., 0 or 1).
*   **Current State:** The actual state (0 or 1) is determined upon measurement based on its potential state.
*   **Entanglement:** Two tokens can be entangled.
*   **Quantum Flip:** An action that changes a token's current state (if measured). If the token is entangled, this action triggers a corresponding state change in its partner based on a contract-wide rule.
*   **Measurement:** Collapses superposition, fixes the current state, and potentially affects the ability to entangle/transfer.

This setup allows for many distinct actions and query functions.

---

**Outline and Function Summary:**

**Contract Name:** `QuantumEntangledTokens`

**Core Concepts:**
*   ERC721 based ownership and token tracking.
*   Tokens have `potentialStateId` (set on mint) and `currentState` (set on measurement).
*   Tokens can be in `superposition` or `measured`.
*   Tokens can be `entangled` in pairs.
*   `applyQuantumFlip` triggers state changes and entangled effects.
*   Measurement can be delegated.
*   Admin can set entanglement rules and measurement delays.

**State Variables:**
*   `_entangledPartner`: Maps token ID to its entangled partner ID (0 if not entangled).
*   `_isSuperpositioned`: Maps token ID to boolean (true if in superposition).
*   `_currentState`: Maps token ID to uint8 (0 or 1), set only after measurement.
*   `_potentialStateId`: Maps token ID to uint8 (0 or 1), set on mint.
*   `_isMeasured`: Maps token ID to boolean (true if measured).
*   `_measurementDelegate`: Maps token ID to delegate address for measurement.
*   `_entanglementRuleType`: Defines how entangled partners react to flips (uint8: 0=Anti-correlated Flip, 1=Correlated Flip, 2=No Entangled Effect).
*   `_minMeasurementDelay`: Minimum time a token must be in superposition before being measured.
*   `_timeEnteredSuperposition`: Timestamp when a token entered superposition.

**Events:**
*   `Minted`: Logs token creation and potential state.
*   `SuperpositionEntered`: Logs when a token enters superposition.
*   `StateMeasured`: Logs when a token is measured and its current state is fixed.
*   `PairEntangled`: Logs when two tokens become entangled.
*   `EntanglementBroken`: Logs when entanglement between two tokens is broken.
*   `QuantumFlipApplied`: Logs when `applyQuantumFlip` is called and resulting states.
*   `MeasurementDelegated`: Logs when measurement rights are delegated.
*   `MeasurementDelegationRevoked`: Logs when delegation is revoked.
*   `EntanglementRuleChanged`: Logs when the admin changes the entanglement rule.
*   `MinMeasurementDelayChanged`: Logs when the admin changes the measurement delay.

**Functions (at least 20):**

**Admin Functions:**
1.  `setEntanglementRuleType(uint8 ruleType)`: Sets the global rule for entangled flip effects. (Owner only)
2.  `setMinMeasurementDelay(uint256 delay)`: Sets the minimum time tokens must be in superposition before measurement. (Owner only)
3.  `getEntanglementRuleType()`: Returns the current entanglement rule type. (View)
4.  `getMinMeasurementDelay()`: Returns the minimum measurement delay. (View)

**Core Token Lifecycle & Quantum Interaction:**
5.  `mint(address to, uint8 potentialStateId)`: Creates a new token, assigns it to `to`, sets its `potentialStateId`, and initially puts it in superposition. (Minter/Owner only)
6.  `enterSuperposition(uint256 tokenId)`: Puts a measured token back into a superposition state. Breaks entanglement. Resets measurement state and time. (Owner or authorized delegate)
7.  `measureState(uint256 tokenId)`: Collapses a token's superposition, fixes its `currentState` based on `potentialStateId`. Requires min delay passed. (Owner or delegate)
8.  `entanglePair(uint256 tokenId1, uint256 tokenId2)`: Entangles two tokens. Requires both to be unentangled and in superposition. (Any address)
9.  `breakEntanglement(uint256 tokenId)`: Breaks the entanglement for a specific token (and its partner). (Owner of either token, or anyone if token is measured)
10. `applyQuantumFlip(uint256 tokenId)`: Flips the `currentState` of a *measured* token. If entangled, triggers the entangled effect on the partner based on the current rule. (Owner or anyone)
11. `delegateMeasurement(uint256 tokenId, address delegate)`: Delegates the right to call `measureState` for a specific token. (Owner only)
12. `revokeMeasurementDelegation(uint256 tokenId)`: Revokes any existing measurement delegation for a token. (Owner only)
13. `batchMeasure(uint256[] memory tokenIds)`: Allows an owner to measure multiple of their tokens at once. (Owner only)

**Query Functions:**
14. `getEntangledPartner(uint256 tokenId)`: Returns the ID of the token's entangled partner (0 if none). (View)
15. `getCurrentState(uint256 tokenId)`: Returns the fixed state (0 or 1) if measured, or a default value (e.g., 255) if in superposition. (View)
16. `getPotentialStateId(uint256 tokenId)`: Returns the potential state type (0 or 1) set at mint. (View)
17. `isSuperpositioned(uint256 tokenId)`: Returns true if the token is in superposition. (View)
18. `isMeasured(uint256 tokenId)`: Returns true if the token's state has been measured and fixed. (View)
19. `isEntangled(uint256 tokenId)`: Returns true if the token is currently entangled with another. (View)
20. `getMeasurementDelegate(uint256 tokenId)`: Returns the address delegated to measure this token (address(0) if none). (View)
21. `getTimeEnteredSuperposition(uint256 tokenId)`: Returns the timestamp when the token last entered superposition. (View)
22. `canMeasure(uint256 tokenId)`: Returns true if the token is in superposition and the minimum delay has passed, and the caller is the owner or delegate. (View)
23. `predictEntangledFlipOutcome(uint256 tokenId)`: Predicts the partner's state *if* `applyQuantumFlip` were called on `tokenId` now, based on the current rule. (View)
24. `getEntanglementRuleDescription(uint8 ruleType)`: Returns a string description of an entanglement rule type. (Pure)

**ERC721 Overrides:**
25. `transferFrom(address from, address to, uint256 tokenId)`: Overrides standard transfer. Adds checks: requires token to be *measured* and *not entangled* for transfer.
26. `safeTransferFrom(address from, address to, uint256 tokenId)`: Overrides standard safe transfer with the same checks.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
// Contract Name: QuantumEntangledTokens
// Core Concepts:
// - ERC721 based ownership and token tracking.
// - Tokens have `potentialStateId` (set on mint) and `currentState` (set on measurement).
// - Tokens can be in `superposition` or `measured`.
// - Tokens can be `entangled` in pairs.
// - `applyQuantumFlip` triggers state changes and entangled effects.
// - Measurement can be delegated.
// - Admin can set entanglement rules and measurement delays.

// State Variables:
// - _entangledPartner: Maps token ID to its entangled partner ID (0 if not entangled).
// - _isSuperpositioned: Maps token ID to boolean (true if in superposition).
// - _currentState: Maps token ID to uint8 (0 or 1), set only after measurement.
// - _potentialStateId: Maps token ID to uint8 (0 or 1), set on mint.
// - _isMeasured: Maps token ID to boolean (true if measured).
// - _measurementDelegate: Maps token ID to delegate address for measurement.
// - _entanglementRuleType: Defines how entangled partners react to flips (uint8: 0=Anti-correlated Flip, 1=Correlated Flip, 2=No Entangled Effect).
// - _minMeasurementDelay: Minimum time a token must be in superposition before being measured.
// - _timeEnteredSuperposition: Timestamp when a token entered superposition.

// Events:
// - Minted: Logs token creation and potential state.
// - SuperpositionEntered: Logs when a token enters superposition.
// - StateMeasured: Logs when a token is measured and its current state is fixed.
// - PairEntangled: Logs when two tokens become entangled.
// - EntanglementBroken: Logs when entanglement between two tokens is broken.
// - QuantumFlipApplied: Logs when `applyQuantumFlip` is called and resulting states.
// - MeasurementDelegated: Logs when measurement rights are delegated.
// - MeasurementDelegationRevoked: Logs when delegation is revoked.
// - EntanglementRuleChanged: Logs when the admin changes the entanglement rule.
// - MinMeasurementDelayChanged: Logs when the admin changes the measurement delay.

// Functions (26 total):
// Admin Functions:
// 1. setEntanglementRuleType(uint8 ruleType)
// 2. setMinMeasurementDelay(uint256 delay)
// 3. getEntanglementRuleType() (View)
// 4. getMinMeasurementDelay() (View)

// Core Token Lifecycle & Quantum Interaction:
// 5. mint(address to, uint8 potentialStateId)
// 6. enterSuperposition(uint256 tokenId)
// 7. measureState(uint256 tokenId)
// 8. entanglePair(uint256 tokenId1, uint256 tokenId2)
// 9. breakEntanglement(uint256 tokenId)
// 10. applyQuantumFlip(uint256 tokenId)
// 11. delegateMeasurement(uint256 tokenId, address delegate)
// 12. revokeMeasurementDelegation(uint256 tokenId)
// 13. batchMeasure(uint256[] memory tokenIds)

// Query Functions:
// 14. getEntangledPartner(uint256 tokenId) (View)
// 15. getCurrentState(uint256 tokenId) (View)
// 16. getPotentialStateId(uint256 tokenId) (View)
// 17. isSuperpositioned(uint256 tokenId) (View)
// 18. isMeasured(uint256 tokenId) (View)
// 19. isEntangled(uint256 tokenId) (View)
// 20. getMeasurementDelegate(uint256 tokenId) (View)
// 21. getTimeEnteredSuperposition(uint256 tokenId) (View)
// 22. canMeasure(uint256 tokenId) (View)
// 23. predictEntangledFlipOutcome(uint256 tokenId) (View)
// 24. getEntanglementRuleDescription(uint8 ruleType) (Pure)

// ERC721 Overrides:
// 25. transferFrom(address from, address to, uint256 tokenId)
// 26. safeTransferFrom(address from, address to, uint256 tokenId)
// --- End of Summary ---


contract QuantumEntangledTokens is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Mapping from token ID to its entangled partner ID (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPartner;

    // Mapping from token ID to boolean indicating if it's in superposition
    mapping(uint256 => bool) private _isSuperpositioned;

    // Mapping from token ID to its current state (0 or 1), only set when measured
    mapping(uint256 => uint8) private _currentState;

    // Mapping from token ID to its potential state ID (0 or 1), set on mint
    mapping(uint256 => uint8) private _potentialStateId;

    // Mapping from token ID to boolean indicating if its state has been measured
    mapping(uint256 => bool) private _isMeasured;

    // Mapping from token ID to the address delegated to measure it
    mapping(uint256 => address) private _measurementDelegate;

    // Global rule type for entangled partners' state changes upon a flip
    // 0: Anti-correlated Flip (partner flips to opposite state if states were same, stays same if different)
    // 1: Correlated Flip (partner stays same if states were same, flips if different)
    // 2: No Entangled Effect (partner state is unaffected by the flip)
    uint8 private _entanglementRuleType;

    // Minimum time (in seconds) a token must be in superposition before it can be measured
    uint256 private _minMeasurementDelay;

    // Timestamp when a token last entered superposition
    mapping(uint256 => uint48) private _timeEnteredSuperposition; // Using uint48 for efficiency, covers timestamps up to ~136 years from epoch

    // --- Events ---

    event Minted(address indexed to, uint256 indexed tokenId, uint8 potentialStateId);
    event SuperpositionEntered(uint256 indexed tokenId, uint48 timestamp);
    event StateMeasured(uint256 indexed tokenId, uint8 currentState);
    event PairEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2); // Log both partners for clarity
    event QuantumFlipApplied(uint256 indexed tokenId, uint8 newState, uint256 indexed partnerId, uint8 partnerNewState);
    event MeasurementDelegated(uint256 indexed tokenId, address indexed delegate);
    event MeasurementDelegationRevoked(uint256 indexed tokenId, address indexed revokedDelegate);
    event EntanglementRuleChanged(uint8 newRuleType);
    event MinMeasurementDelayChanged(uint256 newDelay);

    // --- Constructor ---

    constructor() ERC721("QuantumEntangledToken", "QET") Ownable(msg.sender) {
        // Default entanglement rule: Anti-correlated Flip
        _entanglementRuleType = 0;
        // Default minimum measurement delay: 1 hour
        _minMeasurementDelay = 3600;
    }

    // --- Admin Functions ---

    /// @notice Sets the global rule for how entangled partners' states react to a flip.
    /// @param ruleType The type of rule (0=Anti-correlated Flip, 1=Correlated Flip, 2=No Effect).
    function setEntanglementRuleType(uint8 ruleType) external onlyOwner {
        require(ruleType <= 2, "Invalid rule type");
        _entanglementRuleType = ruleType;
        emit EntanglementRuleChanged(ruleType);
    }

    /// @notice Sets the minimum time a token must be in superposition before it can be measured.
    /// @param delay The minimum delay in seconds.
    function setMinMeasurementDelay(uint256 delay) external onlyOwner {
        _minMeasurementDelay = delay;
        emit MinMeasurementDelayChanged(delay);
    }

    /// @notice Returns the current entanglement rule type.
    /// @return The current entanglement rule type (0, 1, or 2).
    function getEntanglementRuleType() external view returns (uint8) {
        return _entanglementRuleType;
    }

    /// @notice Returns the minimum measurement delay in seconds.
    /// @return The minimum delay in seconds.
    function getMinMeasurementDelay() external view returns (uint256) {
        return _minMeasurementDelay;
    }

    // --- Core Token Lifecycle & Quantum Interaction ---

    /// @notice Creates a new Quantum Entangled Token.
    /// @param to The address to assign the new token to.
    /// @param potentialStateId The potential state type (0 or 1) this token can collapse into upon measurement.
    function mint(address to, uint8 potentialStateId) external onlyOwner nonReentrant {
        require(potentialStateId <= 1, "Potential state must be 0 or 1");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        _potentialStateId[newTokenId] = potentialStateId;
        _isSuperpositioned[newTokenId] = true; // Starts in superposition
        _isMeasured[newTokenId] = false;
        _timeEnteredSuperposition[newTokenId] = uint48(block.timestamp); // Record entry time

        emit Minted(to, newTokenId, potentialStateId);
        emit SuperpositionEntered(newTokenId, uint48(block.timestamp));
    }

    /// @notice Puts a measured token back into a superposition state.
    /// Breaks any existing entanglement and resets the measured state.
    /// @param tokenId The ID of the token to put back into superposition.
    function enterSuperposition(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Caller is not the token owner");
        require(!_isSuperpositioned[tokenId], "Token is already in superposition");

        // Break entanglement if any
        if (_entangledPartner[tokenId] != 0) {
            breakEntanglement(tokenId);
        }

        _isSuperpositioned[tokenId] = true;
        _isMeasured[tokenId] = false;
        // Reset current state - it's no longer fixed
        delete _currentState[tokenId];
        _timeEnteredSuperposition[tokenId] = uint48(block.timestamp); // Record new entry time

        emit SuperpositionEntered(tokenId, uint48(block.timestamp));
    }

    /// @notice Collapses a token's superposition, fixing its state based on potential state.
    /// Requires the token to be in superposition and the minimum delay to have passed.
    /// @param tokenId The ID of the token to measure.
    function measureState(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        address currentOwner = ownerOf(tokenId);
        address delegate = _measurementDelegate[tokenId];
        require(
            _msgSender() == currentOwner || _msgSender() == delegate,
            "Caller is not owner or delegated measurer"
        );
        require(_isSuperpositioned[tokenId], "Token is not in superposition");
        require(
            block.timestamp >= _timeEnteredSuperposition[tokenId] + _minMeasurementDelay,
            "Minimum superposition delay not met"
        );

        _isSuperpositioned[tokenId] = false;
        _isMeasured[tokenId] = true;
        // State collapses to its potential state value
        _currentState[tokenId] = _potentialStateId[tokenId];

        // Optional: Break entanglement upon measurement?
        // Let's allow measured tokens to remain entangled for this design,
        // but prevent *new* entanglement of measured tokens.
        // breakEntanglement(tokenId); // Uncomment this line if measurement should break entanglement

        emit StateMeasured(tokenId, _currentState[tokenId]);
    }

    /// @notice Entangles two tokens together.
    /// Requires both tokens to exist, be different, unentangled, and in superposition.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entanglePair(uint256 tokenId1, uint256 tokenId2) public nonReentrant {
        require(tokenId1 != tokenId2, "Cannot entangle a token with itself");
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");
        require(_entangledPartner[tokenId1] == 0, "Token 1 is already entangled");
        require(_entangledPartner[tokenId2] == 0, "Token 2 is already entangled");
        require(_isSuperpositioned[tokenId1], "Token 1 must be in superposition");
        require(_isSuperpositioned[tokenId2], "Token 2 must be in superposition");

        _entangledPartner[tokenId1] = tokenId2;
        _entangledPartner[tokenId2] = tokenId1;

        emit PairEntangled(tokenId1, tokenId2);
    }

    /// @notice Breaks the entanglement for a token and its partner.
    /// Can be called by the owner of either token, or by anyone if the token is measured.
    /// @param tokenId The ID of one of the entangled tokens.
    function breakEntanglement(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        uint256 partnerId = _entangledPartner[tokenId];
        require(partnerId != 0, "Token is not entangled");

        // Allow breaking if owner of this token, owner of partner, or if the token is measured (stable state)
        address caller = _msgSender();
        bool isOwner = (ownerOf(tokenId) == caller) || (ownerOf(partnerId) == caller);
        bool isMeasuredAndUnrestricted = _isMeasured[tokenId]; // Consider measured tokens "stable" enough for anyone to break entanglement

        require(isOwner || isMeasuredAndUnrestricted, "Caller is not authorized to break entanglement");

        _entangledPartner[tokenId] = 0;
        _entangledPartner[partnerId] = 0;

        emit EntanglementBroken(tokenId, partnerId);
    }

    /// @notice Applies a "quantum flip" to a measured token's current state.
    /// If the token is entangled, this triggers a reaction in the partner based on the current rule.
    /// Can only be called on measured tokens.
    /// @param tokenId The ID of the measured token to flip.
    function applyQuantumFlip(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(_isMeasured[tokenId], "Token must be measured to apply flip");

        uint8 currentState = _currentState[tokenId];
        // Flip the state (0 becomes 1, 1 becomes 0)
        uint8 newCurrentState = (currentState == 0) ? 1 : 0;
        _currentState[tokenId] = newCurrentState;

        uint256 partnerId = _entangledPartner[tokenId];
        uint8 partnerNewState = 255; // Default to indicate no change or not applicable

        if (partnerId != 0) {
            // Only entangled and *measured* partners react to the flip based on the rule
            if (_isMeasured[partnerId]) {
                 uint8 partnerCurrentState = _currentState[partnerId];
                 // Apply entanglement rule
                 if (_entanglementRuleType == 0) { // Anti-correlated Flip
                     // If current states were the same, partner flips to opposite. If different, partner stays same.
                     partnerNewState = (currentState == partnerCurrentState) ? ((partnerCurrentState == 0) ? 1 : 0) : partnerCurrentState;
                 } else if (_entanglementRuleType == 1) { // Correlated Flip
                     // If current states were the same, partner stays same. If different, partner flips.
                      partnerNewState = (currentState == partnerCurrentState) ? partnerCurrentState : ((partnerCurrentState == 0) ? 1 : 0);
                 } else { // ruleType == 2: No Entangled Effect
                     partnerNewState = partnerCurrentState; // Partner state is unchanged by the flip
                 }
                 _currentState[partnerId] = partnerNewState;
            } else {
                 // Partner is entangled but NOT measured -> its superpositioned state is unaffected by the flip
                 partnerNewState = 255; // Use 255 to indicate state wasn't set/changed by the flip
            }
        }

        emit QuantumFlipApplied(tokenId, newCurrentState, partnerId, partnerNewState);
    }

    /// @notice Delegates the right to call `measureState` for a specific token.
    /// @param tokenId The ID of the token.
    /// @param delegate The address to delegate measurement rights to. Address(0) removes delegation.
    function delegateMeasurement(uint256 tokenId, address delegate) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Caller is not the token owner");

        _measurementDelegate[tokenId] = delegate;
        emit MeasurementDelegated(tokenId, delegate);
    }

    /// @notice Revokes any existing measurement delegation for a token.
    /// @param tokenId The ID of the token.
    function revokeMeasurementDelegation(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Caller is not the token owner");
        require(_measurementDelegate[tokenId] != address(0), "No delegation to revoke");

        address revokedDelegate = _measurementDelegate[tokenId];
        delete _measurementDelegate[tokenId];
        emit MeasurementDelegationRevoked(tokenId, revokedDelegate);
    }

    /// @notice Allows an owner to measure multiple of their tokens at once.
    /// Applies the same measurement logic to each token ID in the array.
    /// @param tokenIds An array of token IDs to measure.
    function batchMeasure(uint256[] memory tokenIds) public nonReentrant {
        address caller = _msgSender();
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Token in batch does not exist");
            // Must own the token to batch measure, or be the delegate for ALL of them (less likely/useful)
            // Let's enforce owner only for batch measure simplicity
            require(ownerOf(tokenId) == caller, "Caller is not the owner of token in batch");

            // Only measure if it's currently in superposition and delay is met
            if (_isSuperpositioned[tokenId] && block.timestamp >= _timeEnteredSuperposition[tokenId] + _minMeasurementDelay) {
                 _isSuperpositioned[tokenId] = false;
                 _isMeasured[tokenId] = true;
                 _currentState[tokenId] = _potentialStateId[tokenId];
                 emit StateMeasured(tokenId, _currentState[tokenId]);
            }
        }
    }


    // --- Query Functions ---

    /// @notice Returns the ID of the token's entangled partner.
    /// @param tokenId The ID of the token.
    /// @return The partner's token ID, or 0 if not entangled.
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _entangledPartner[tokenId];
    }

    /// @notice Returns the fixed state (0 or 1) if the token is measured.
    /// @param tokenId The ID of the token.
    /// @return The current state (0 or 1), or a special value (255) if in superposition.
    function getCurrentState(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "Token does not exist");
         return _isMeasured[tokenId] ? _currentState[tokenId] : 255; // Use 255 to indicate 'unmeasured'
    }

    /// @notice Returns the potential state type (0 or 1) set at mint.
    /// This is the state the token will collapse into upon measurement.
    /// @param tokenId The ID of the token.
    /// @return The potential state ID (0 or 1).
    function getPotentialStateId(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "Token does not exist");
         return _potentialStateId[tokenId];
    }


    /// @notice Returns true if the token is currently in superposition.
    /// @param tokenId The ID of the token.
    /// @return True if in superposition, false otherwise.
    function isSuperpositioned(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Token does not exist");
         return _isSuperpositioned[tokenId];
    }

    /// @notice Returns true if the token's state has been measured and fixed.
    /// @param tokenId The ID of the token.
    /// @return True if measured, false otherwise.
    function isMeasured(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Token does not exist");
         return _isMeasured[tokenId];
    }

    /// @notice Returns true if the token is currently entangled with another.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Token does not exist");
         return _entangledPartner[tokenId] != 0;
    }

    /// @notice Returns the address currently delegated to measure this token.
    /// @param tokenId The ID of the token.
    /// @return The delegate address, or address(0) if no delegation exists.
    function getMeasurementDelegate(uint256 tokenId) public view returns (address) {
         require(_exists(tokenId), "Token does not exist");
         return _measurementDelegate[tokenId];
    }

    /// @notice Returns the timestamp when the token last entered superposition.
    /// @param tokenId The ID of the token.
    /// @return The timestamp (uint48).
    function getTimeEnteredSuperposition(uint256 tokenId) public view returns (uint48) {
         require(_exists(tokenId), "Token does not exist");
         return _timeEnteredSuperposition[tokenId];
    }

    /// @notice Returns true if the token can be measured by the caller right now.
    /// Checks if in superposition, delay met, and caller is owner or delegate.
    /// @param tokenId The ID of the token.
    /// @return True if measurement is allowed for the caller, false otherwise.
    function canMeasure(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Token does not exist");
         address caller = _msgSender();
         address currentOwner = ownerOf(tokenId);
         address delegate = _measurementDelegate[tokenId];

         bool isAuthorized = (caller == currentOwner || caller == delegate);
         bool isReady = _isSuperpositioned[tokenId] && block.timestamp >= _timeEnteredSuperposition[tokenId] + _minMeasurementDelay;

         return isAuthorized && isReady;
    }

     /// @notice Predicts the partner's state if `applyQuantumFlip` were called on `tokenId` now.
     /// This is a view function that simulates the flip logic without changing state.
     /// Returns 255 if the token is not measured or not entangled with a measured partner.
     /// @param tokenId The ID of the token to simulate flipping.
     /// @return The predicted new state of the partner (0 or 1), or 255 if prediction not applicable.
    function predictEntangledFlipOutcome(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "Token does not exist");
        if (!_isMeasured[tokenId]) {
            return 255; // Cannot flip or predict if token is not measured
        }

        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId == 0 || !_isMeasured[partnerId]) {
             return 255; // Not entangled or partner not measured -> no predictable entangled effect
        }

        uint8 currentState = _currentState[tokenId];
        uint8 partnerCurrentState = _currentState[partnerId];
        uint8 ruleType = _entanglementRuleType;

        uint8 predictedPartnerState;
        if (ruleType == 0) { // Anti-correlated Flip
            predictedPartnerState = (currentState == partnerCurrentState) ? ((partnerCurrentState == 0) ? 1 : 0) : partnerCurrentState;
        } else if (ruleType == 1) { // Correlated Flip
            predictedPartnerState = (currentState == partnerCurrentState) ? partnerCurrentState : ((partnerCurrentState == 0) ? 1 : 0);
        } else { // ruleType == 2: No Entangled Effect
            predictedPartnerState = partnerCurrentState; // Partner state would be unchanged
        }

        return predictedPartnerState;
    }

    /// @notice Provides a human-readable description of an entanglement rule type.
    /// @param ruleType The rule type (0, 1, or 2).
    /// @return A string description of the rule.
    function getEntanglementRuleDescription(uint8 ruleType) public pure returns (string memory) {
        if (ruleType == 0) return "Anti-correlated Flip";
        if (ruleType == 1) return "Correlated Flip";
        if (ruleType == 2) return "No Entangled Effect";
        return "Unknown Rule Type";
    }


    // --- ERC721 Overrides ---

    /// @notice Overrides transferFrom to add checks: requires token to be measured and not entangled.
    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
        require(_isMeasured[tokenId], "Token must be measured to transfer");
        require(_entangledPartner[tokenId] == 0, "Token must not be entangled to transfer");
        super.transferFrom(from, to, tokenId);
        // After transfer, break delegation as owner might change
        if (_measurementDelegate[tokenId] != address(0)) {
             address revokedDelegate = _measurementDelegate[tokenId];
            delete _measurementDelegate[tokenId];
             emit MeasurementDelegationRevoked(tokenId, revokedDelegate);
        }
    }

    /// @notice Overrides safeTransferFrom to add checks: requires token to be measured and not entangled.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override nonReentrant {
         require(_isMeasured[tokenId], "Token must be measured to transfer");
         require(_entangledPartner[tokenId] == 0, "Token must not be entangled to transfer");
         super.safeTransferFrom(from, to, tokenId);
          // After transfer, break delegation as owner might change
        if (_measurementDelegate[tokenId] != address(0)) {
             address revokedDelegate = _measurementDelegate[tokenId];
            delete _measurementDelegate[tokenId];
             emit MeasurementDelegationRevoked(tokenId, revokedDelegate);
        }
    }

    /// @notice Overrides safeTransferFrom with data to add checks: requires token to be measured and not entangled.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override nonReentrant {
         require(_isMeasured[tokenId], "Token must be measured to transfer");
         require(_entangledPartner[tokenId] == 0, "Token must not be entangled to transfer");
         super.safeTransferFrom(from, to, tokenId, data);
          // After transfer, break delegation as owner might change
        if (_measurementDelegate[tokenId] != address(0)) {
             address revokedDelegate = _measurementDelegate[tokenId];
            delete _measurementDelegate[tokenId];
             emit MeasurementDelegationRevoked(tokenId, revokedDelegate);
        }
    }

    // The standard ERC721 `approve` and `setApprovalForAll` functions are inherited.
    // Approvals will also be subject to the `transferFrom` restrictions.

}
```