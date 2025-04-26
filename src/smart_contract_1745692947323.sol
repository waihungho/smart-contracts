Okay, this is a fun challenge! Let's design a smart contract inspired by quantum mechanics concepts like superposition, measurement, and entanglement, applied to non-fungible tokens. It won't be *true* quantum computing, but a creative model on the blockchain.

We'll create "Quantum State Tokens" (QSTs). Initially, they exist in a state of "Superposition," having the potential to collapse into various defined "Collapsed States" upon "Measurement." Collapsed states can have different properties and interact in unique ways (like "Entanglement" or "State Transitions").

**Concept:** Quantum State Tokens (QSTs) - ERC721-inspired tokens that start in a 'Superposed' state and collapse into a specific 'Collapsed' state upon a 'Measurement' event. Collapsed states determine token properties and potential interactions.

**Advanced/Creative Concepts Used:**
1.  **State Superposition & Measurement:** Tokens hold potential states before "collapsing".
2.  **Probabilistic Outcomes:** Measurement results are determined by predefined probabilities (using pseudo-randomness).
3.  **State-Dependent Properties:** Token utility and interactions depend on its collapsed state.
4.  **Entanglement:** Linking two tokens such that their measurements are correlated or triggered together.
5.  **State Transitions:** Collapsed tokens can attempt to move to other states under certain conditions (e.g., 'excitation', 'decoherence').
6.  **Token Merging/Splitting:** Specific collapsed states can be combined or divided.
7.  **Dynamic Metadata:** Token URI potentially reflects the current state.

---

## **Smart Contract Outline: QuantumStateToken**

This contract defines a unique Non-Fungible Token standard (`ERC721`-like) called QuantumStateToken (QST), incorporating concepts inspired by quantum mechanics.

1.  **State Definitions:**
    *   `TokenState`: Enum representing the token's current state (Superposed, Collapsed, Entangled, etc.).
    *   `StateType`: Enum/Mapping defining possible 'Collapsed' states (e.g., Ground, Excited, Entangled_Observer, Decohered, etc.), each with specific properties.
    *   `StateProbabilities`: Mapping defining the probability distribution for collapsing into different `StateType`s from Superposition.

2.  **Token Structure:**
    *   Each token (`uint256 tokenId`) stores its current `TokenState`, its specific `StateType` (if Collapsed), potential state outcomes (if Superposed), and entanglement info.

3.  **Core Mechanics:**
    *   **Minting (`mintSuperposed`):** Creates new tokens in the `Superposed` state.
    *   **Measurement (`measureState`, `triggerEntangledMeasurement`):** Triggers the collapse of a Superposed token (or an entangled pair) into a specific Collapsed state based on probabilities. Uses block data for pseudo-randomness.
    *   **Entanglement (`entangleTokens`, `disentangleTokens`):** Links two tokens, potentially affecting their measurement or requiring simultaneous measurement.
    *   **State Transitions (`attemptStateExcitation`, `attemptStateDecoherence`):** Functions allowing collapsed tokens to attempt changing their `StateType` based on predefined rules and probabilities.
    *   **State Interactions (`mergeCollapsedTokens`, `splitCollapsedToken`):** Functions to combine or divide tokens based on their specific Collapsed states.
    *   **Burning (`burnToken`):** Destroys a token.

4.  **ERC721 Compliance (Partial/Inspired):**
    *   Basic ownership tracking (`_owners`, `_balances`).
    *   Transfer functions (`transferFrom`, `safeTransferFrom`).
    *   Approval functions (`approve`, `setApprovalForAll`).
    *   Metadata (`tokenURI`).

5.  **Admin Functionality:**
    *   Setting state probabilities.
    *   Defining and updating `StateType` properties.
    *   Pausing contract operations.

---

## **Function Summary:**

Here's a list of the main external and public functions:

1.  `constructor()`: Initializes the contract, sets owner.
2.  `supportsInterface(bytes4 interfaceId)`: Checks if the contract supports a given interface (for ERC721 compatibility).
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (ERC721)
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (ERC721)
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership. (ERC721)
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership safely. (ERC721)
7.  `approve(address to, uint256 tokenId)`: Approves an address to spend a token. (ERC721)
8.  `getApproved(uint256 tokenId)`: Gets the approved address for a token. (ERC721)
9.  `setApprovalForAll(address operator, bool approved)`: Sets approval for all tokens of an owner. (ERC721)
10. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens of an owner. (ERC721)
11. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token. (ERC721)
12. `mintSuperposed(address to, uint256 count)`: Mints new tokens in the Superposed state to an address.
13. `measureState(uint256 tokenId)`: Triggers the collapse of a single Superposed token.
14. `entangleTokens(uint256 tokenId1, uint256 tokenId2)`: Attempts to entangle two tokens. Requires both to be Superposed or specific Collapsed states.
15. `disentangleTokens(uint256 tokenId)`: Removes entanglement from a token.
16. `triggerEntangledMeasurement(uint256 tokenId)`: Triggers the collapse of a token and its entangled partner simultaneously.
17. `attemptStateExcitation(uint256 tokenId)`: Attempts to transition a Collapsed token to a higher energy state.
18. `attemptStateDecoherence(uint256 tokenId)`: Attempts to transition a Collapsed token to a specific, potentially lower energy state.
19. `mergeCollapsedTokens(uint256 tokenId1, uint256 tokenId2)`: Attempts to merge two compatible Collapsed tokens into a new token or enhanced state.
20. `splitCollapsedToken(uint256 tokenId)`: Attempts to split a Collapsed token into multiple simpler tokens.
21. `burnToken(uint256 tokenId)`: Destroys a token.
22. `getTokenState(uint256 tokenId)`: Gets the high-level `TokenState` of a token.
23. `getTokenStateType(uint256 tokenId)`: Gets the specific `StateType` if the token is Collapsed.
24. `getTokenEntanglementPair(uint256 tokenId)`: Gets the token ID of the entangled partner, if any.
25. `getStateDetails(StateType stateType)`: Gets the properties associated with a specific `StateType`.
26. `getPossibleCollapseOutcomes(uint256 tokenId)`: (Conceptual/View) Returns the potential `StateType`s a Superposed token could collapse into (based on global probabilities). *Note: Implementing the exact distribution per token adds significant complexity; this might just return the global possibilities.*
27. `addStateProbability(StateType stateType, uint16 probability)`: Admin: Sets the probability for a StateType outcome during measurement.
28. `removeStateProbability(StateType stateType)`: Admin: Removes a StateType outcome possibility.
29. `updateStateDetails(StateType stateType, string memory name, uint256 power, uint256 stability, uint256 rarityScore)`: Admin: Updates the properties of a StateType.
30. `setBaseURI(string memory baseURI)`: Admin: Sets the base URI for token metadata.
31. `pause()`: Admin: Pauses contract functionality.
32. `unpause()`: Admin: Unpauses contract functionality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title QuantumStateToken (QST)
/// @dev A token contract inspired by quantum mechanics, featuring superposition, measurement, and state transitions.
/// @dev This contract is NOT a true ERC721, but implements necessary functions for basic compatibility and tracking.
/// @dev Pseudo-randomness is used for probabilistic outcomes, which is NOT secure for high-value, unpredictable results.

// --- Smart Contract Outline: QuantumStateToken ---
// 1. State Definitions: TokenState enum, StateType enum, QuantumStateDetails struct, probabilities mapping.
// 2. Token Structure: TokenQuantumInfo struct storing token's state, type, entanglement, etc. Mapping from tokenId to info.
// 3. Core Mechanics: minting, measurement (single/entangled), entanglement/disentanglement, state transitions, merge/split, burn.
// 4. ERC721 Compatibility (Partial): Ownership, transfers, approvals, metadata.
// 5. Admin Functionality: Setting probabilities, updating state details, pausing.
// 6. Internal Helpers: Pseudo-random number generation, state updates, ownership management.

// --- Function Summary ---
// 1.  constructor()
// 2.  supportsInterface(bytes4 interfaceId)
// 3.  balanceOf(address owner)
// 4.  ownerOf(uint256 tokenId)
// 5.  transferFrom(address from, address to, uint256 tokenId)
// 6.  safeTransferFrom(address from, address to, uint256 tokenId)
// 7.  approve(address to, uint256 tokenId)
// 8.  getApproved(uint256 tokenId)
// 9.  setApprovalForAll(address operator, bool approved)
// 10. isApprovedForAll(address owner, address operator)
// 11. tokenURI(uint256 tokenId)
// 12. mintSuperposed(address to, uint256 count)
// 13. measureState(uint256 tokenId)
// 14. entangleTokens(uint256 tokenId1, uint256 tokenId2)
// 15. disentangleTokens(uint256 tokenId)
// 16. triggerEntangledMeasurement(uint256 tokenId)
// 17. attemptStateExcitation(uint256 tokenId)
// 18. attemptStateDecoherence(uint256 tokenId)
// 19. mergeCollapsedTokens(uint256 tokenId1, uint256 tokenId2)
// 20. splitCollapsedToken(uint256 tokenId)
// 21. burnToken(uint256 tokenId)
// 22. getTokenState(uint256 tokenId)
// 23. getTokenStateType(uint256 tokenId)
// 24. getTokenEntanglementPair(uint256 tokenId)
// 25. getStateDetails(StateType stateType)
// 26. getPossibleCollapseOutcomes(uint256 tokenId) - View, shows global config
// 27. addStateProbability(StateType stateType, uint16 probability) - Admin
// 28. removeStateProbability(StateType stateType) - Admin
// 29. updateStateDetails(StateType stateType, string memory name, uint256 power, uint256 stability, uint256 rarityScore) - Admin
// 30. setBaseURI(string memory baseURI) - Admin
// 31. pause() - Admin
// 32. unpause() - Admin

contract QuantumStateToken is Ownable, Pausable, IERC721 {
    using Strings for uint256;

    // --- Error Definitions ---
    error InvalidRecipient();
    error NotOwnerOrApproved();
    error NotSuperposed();
    error AlreadyCollapsed();
    error AlreadyEntangled();
    error NotEntangled();
    error CannotEntangleDifferentStates(); // If entanglement requires specific starting states
    error CannotMeasureEntangledSeparately();
    error MeasurementFailed();
    error InvalidStateType();
    error NotCollapsed();
    error StateTransitionFailed();
    error InvalidMergeStates();
    error InvalidSplitState();
    error ZeroAddress();
    error InvalidTokenId();
    error SelfEntanglement();
    error ProbabilitySumNot10000(); // Use basis points (1/10000) for probabilities
    error ProbabilityNotFound();


    // --- Enums and Structs ---

    /// @dev Represents the high-level state of a token.
    enum TokenState {
        NonExistent,
        Superposed,   // Can collapse into one of many StateTypes
        Collapsed,    // Has collapsed into a specific StateType
        Entangled     // Linked to another token, special measurement rules apply
    }

    /// @dev Represents the specific type a token collapses into. Defines properties.
    enum StateType {
        Unknown,         // Default/Error state for Collapsed type
        Ground,          // Basic, stable state
        Excited,         // Higher energy, less stable, maybe higher power
        Decohered,       // Forced collapse, potentially low stability
        Entangled_Observer // State resulting from entanglement measurement
        // Add more creative states here... e.g., Quark, Lepton, Photon, etc.
        // StateType will need to be mapped to actual properties.
    }

    /// @dev Defines properties for a specific StateType.
    struct QuantumStateDetails {
        string name;       // e.g., "Ground State", "Excited State"
        uint256 power;     // Example property
        uint256 stability; // Example property
        uint256 rarityScore; // Example property
        bool exists;       // To check if a state type has been configured
    }

    /// @dev Stores the quantum information for each token.
    struct TokenQuantumInfo {
        TokenState state;
        StateType collapsedStateType; // Only relevant if state is Collapsed or Entangled
        uint256 entangledPartnerId; // 0 if not entangled
        uint64 measurementTimestamp; // Timestamp of collapse
    }

    // --- State Variables ---

    string private _name = "QuantumStateToken";
    string private _symbol = "QST";
    string private _baseTokenURI;

    uint256 private _currentTokenId;

    // Token Data
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => TokenQuantumInfo) private _tokenQuantumInfo;

    // ERC721 Approvals
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // State Type Configuration
    mapping(StateType => QuantumStateDetails) private _stateDetails;
    // Probabilities for collapse from Superposition (in basis points, sum must be 10000)
    mapping(StateType => uint16) private _collapseProbabilities;
    StateType[] private _availableCollapseTypes; // To iterate probabilities easily

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Minted(address indexed owner, uint256 indexed tokenId, TokenState initialState);
    event Measured(uint256 indexed tokenId, StateType indexed collapsedState, uint64 timestamp);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StateTransitionAttempt(uint256 indexed tokenId, StateType fromState, StateType attemptedState, bool success);
    event TokensMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId, StateType newState);
    event TokenSplit(uint256 indexed parentTokenId, uint256[] indexed childTokenIds, StateType[] childStates);
    event Burned(uint256 indexed tokenId);
    event StateProbabilityUpdated(StateType indexed stateType, uint16 probability);
    event StateDetailsUpdated(StateType indexed stateType, string name, uint256 power, uint256 stability, uint256 rarityScore);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) Pausable() {
        _name = name_;
        _symbol = symbol_;

        // Initialize some default state types (can be updated/added by owner later)
        _availableCollapseTypes.push(StateType.Ground);
        _stateDetails[StateType.Ground] = QuantumStateDetails("Ground State", 10, 100, 50, true);
        _collapseProbabilities[StateType.Ground] = 7000; // 70%

        _availableCollapseTypes.push(StateType.Excited);
        _stateDetails[StateType.Excited] = QuantumStateDetails("Excited State", 50, 30, 80, true);
        _collapseProbabilities[StateType.Excited] = 2500; // 25%

        _availableCollapseTypes.push(StateType.Entangled_Observer); // State specifically for entanglement outcome
         _stateDetails[StateType.Entangled_Observer] = QuantumStateDetails("Entangled Observer", 20, 80, 70, true);
        _collapseProbabilities[StateType.Entangled_Observer] = 500; // 5% - Sum: 10000

         _availableCollapseTypes.push(StateType.Decohered); // Add Decohered as a possible state later
         _stateDetails[StateType.Decohered] = QuantumStateDetails("Decohered State", 5, 10, 20, true);
         // Decohered probability should likely be 0 initially for random collapse,
         // primarily reached via attemptStateDecoherence or decay.
         _collapseProbabilities[StateType.Decohered] = 0;

        // Check initial probability sum
        _checkProbabilitySum();
    }

    // --- ERC721 Standard Functions (Subset) ---

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // ERC165 identifier for ERC721: 0x80ac58cd
        // ERC165 identifier for ERC721Metadata: 0x5b5e139f
        // ERC165 identifier for ERC721Enumerable: 0x780e9d63 (Not implementing Enumerable)
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || super.supportsInterface(interfaceId);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
        if (_owners[tokenId] != from) revert NotOwnerOrApproved(); // Ensure caller is transferring from the correct owner
        if (to == address(0)) revert InvalidRecipient();

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
         if (_owners[tokenId] != from) revert NotOwnerOrApproved(); // Ensure caller is transferring from the correct owner
        if (to == address(0)) revert InvalidRecipient();

        _safeTransfer(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId); // Checks for token existence
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotOwnerOrApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
         // No check for token existence needed, default address(0) is returned
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        if (operator == msg.sender) revert InvalidRecipient(); // Cannot approve self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId(); // Check token exists

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }

        // Example: Append token ID and potentially state info to URI
        string memory stateIndicator = "";
        TokenQuantumInfo storage tokenInfo = _tokenQuantumInfo[tokenId];
        if (tokenInfo.state == TokenState.Collapsed) {
            stateIndicator = string(abi.encodePacked("/", Strings.toString(uint256(tokenInfo.collapsedStateType))));
        } else if (tokenInfo.state == TokenState.Entangled) {
             stateIndicator = string(abi.encodePacked("/", Strings.toString(uint256(tokenInfo.collapsedStateType)), "-entangled"));
        } else if (tokenInfo.state == TokenState.Superposed) {
             stateIndicator = "/superposed";
        }


        if (bytes(base).length > 0 && base[bytes(base).length - 1] == '/') {
             return string(abi.encodePacked(base, tokenId.toString(), stateIndicator, ".json"));
        } else {
             return string(abi.encodePacked(base, "/", tokenId.toString(), stateIndicator, ".json"));
        }
    }

    // --- Core Quantum Logic Functions ---

    /// @dev Mints new tokens in the Superposed state.
    /// @param to The address to mint tokens to.
    /// @param count The number of tokens to mint.
    function mintSuperposed(address to, uint256 count) public onlyOwner whenNotPaused {
        if (to == address(0)) revert InvalidRecipient();

        for (uint i = 0; i < count; i++) {
            _currentTokenId++;
            uint256 newTokenId = _currentTokenId;

            _owners[newTokenId] = to;
            _balances[to]++;
            _tokenQuantumInfo[newTokenId].state = TokenState.Superposed;

            emit Minted(to, newTokenId, TokenState.Superposed);
            emit Transfer(address(0), to, newTokenId);
        }
    }

    /// @dev Triggers the collapse of a single Superposed token into a Collapsed state.
    /// @param tokenId The ID of the token to measure.
    function measureState(uint256 tokenId) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        TokenQuantumInfo storage tokenInfo = _tokenQuantumInfo[tokenId];
        if (tokenInfo.state != TokenState.Superposed) revert NotSuperposed();
        if (tokenInfo.entangledPartnerId != 0) revert CannotMeasureEntangledSeparately(); // Must use triggerEntangledMeasurement

        StateType outcome = _generateRandomOutcome(block.timestamp, block.difficulty, tokenId);
        _updateTokenState(tokenId, TokenState.Collapsed, outcome);

        emit Measured(tokenId, outcome, tokenInfo.measurementTimestamp);
    }

    /// @dev Attempts to entangle two tokens. Both must be in specific states (e.g., Superposed or compatible Collapsed states).
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangleTokens(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        if (tokenId1 == tokenId2) revert SelfEntanglement();
        _checkValidToken(tokenId1);
        _checkValidToken(tokenId2);
        _checkOwnerOrApproved(tokenId1); // Requires ownership/approval of the first token
        _checkOwnerOrApproved(tokenId2); // Requires ownership/approval of the second token

        TokenQuantumInfo storage info1 = _tokenQuantumInfo[tokenId1];
        TokenQuantumInfo storage info2 = _tokenQuantumInfo[tokenId2];

        if (info1.state == TokenState.Entangled || info2.state == TokenState.Entangled) revert AlreadyEntangled();

        // Define entanglement rules: e.g., only Superposed tokens can be entangled initially
        if (info1.state != TokenState.Superposed || info2.state != TokenState.Superposed) {
            // Could add logic here for entangling specific Collapsed states
             revert CannotEntangleDifferentStates();
        }

        info1.entangledPartnerId = tokenId2;
        info2.entangledPartnerId = tokenId1;
        // Tokens remain Superposed, but now linked. Their state changes to Entangled upon measurement.
        // Or we could immediately change state to Entangled? Let's change state to Entangled.
        info1.state = TokenState.Entangled;
        info2.state = TokenState.Entangled;


        emit Entangled(tokenId1, tokenId2);
    }

    /// @dev Removes entanglement from a token.
    /// @param tokenId The ID of the token to disentangle.
    function disentangleTokens(uint256 tokenId) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        TokenQuantumInfo storage info = _tokenQuantumInfo[tokenId];
        if (info.state != TokenState.Entangled) revert NotEntangled();

        uint256 partnerId = info.entangledPartnerId;
        TokenQuantumInfo storage partnerInfo = _tokenQuantumInfo[partnerId];

        info.entangledPartnerId = 0;
        partnerInfo.entangledPartnerId = 0;

        // Tokens return to Superposed state upon disentanglement (if they were Superposed before)
        // Or perhaps disentanglement forces a 'Decohered' state? Let's make it Decohered state collapse if not measured.
        // If they were entangled and never measured, they become Decohered upon disentanglement.
        // If they were entangled and already measured together, they stay in their Collapsed/Entangled_Observer state.
        if (info.measurementTimestamp == 0) { // Check if measured
             _updateTokenState(tokenId, TokenState.Collapsed, StateType.Decohered); // Force Decohered
             _updateTokenState(partnerId, TokenState.Collapsed, StateType.Decohered); // Force Decohered
        } else {
            // If already measured while entangled, they stay in their resulting states but are no longer linked
             info.state = TokenState.Collapsed;
             partnerInfo.state = TokenState.Collapsed;
        }


        emit Disentangled(tokenId, partnerId);
    }

    /// @dev Triggers the simultaneous measurement of an entangled pair of tokens.
    /// @param tokenId The ID of one token in the entangled pair.
    function triggerEntangledMeasurement(uint256 tokenId) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        TokenQuantumInfo storage info1 = _tokenQuantumInfo[tokenId];
        if (info1.state != TokenState.Entangled) revert NotEntangled();

        uint256 tokenId2 = info1.entangledPartnerId;
        if (tokenId2 == 0) revert NotEntangled(); // Should not happen if state is Entangled, but safety check

        _checkValidToken(tokenId2);
        _checkOwnerOrApproved(tokenId2); // Requires ownership/approval of *both* tokens

        TokenQuantumInfo storage info2 = _tokenQuantumInfo[tokenId2];
        if (info2.entangledPartnerId != tokenId || info2.state != TokenState.Entangled) revert NotEntangled(); // Ensure pair is valid

        // Use a single random seed for both measurements
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, tokenId2)));

        // Generate outcomes independently but with the same seed (or implement correlated outcomes)
        // Simple correlation: if one gets Excited, the other is more likely Decohered?
        // For simplicity now, they just collapse based on standard probabilities using the same seed source.
        // More complex: implement custom probability logic for entangled pairs.
        StateType outcome1 = _generateRandomOutcome(randomSeed, 0, 0); // Use the combined seed
        StateType outcome2 = _generateRandomOutcome(randomSeed + 1, 0, 0); // Use a slightly different seed derived from the combined one for variance

        // Example of potential correlation logic (simplified):
        if (outcome1 == StateType.Excited && outcome2 == StateType.Excited) {
             // If both *randomly* get Excited, force one to Decohered due to instability?
             // This requires re-rolling or specific logic after getting random outcomes.
             // Let's keep it simple and just assign the random outcomes for now.
             // Realistically, entangled measurement would yield correlated, *not* independent, outcomes.
             // Modeling true correlation probabilistically on-chain is complex.
             // A simple approach: both *tend* towards the Entangled_Observer state more often?
             // Or maybe if one hits 'Excited', the other *cannot* be 'Excited'?
             // Let's stick to independent probabilistic collapse for v1, but require simultaneous trigger.
             // We can add state-specific outcomes later.
             // For now, they just collapse independently from the standard distribution using related seeds.
             // Let's assign a specific state type for tokens measured while entangled
             outcome1 = StateType.Entangled_Observer;
             outcome2 = StateType.Entangled_Observer; // Simpler: both become Entangled_Observer state

        }


        _updateTokenState(tokenId, TokenState.Collapsed, outcome1);
        _updateTokenState(tokenId2, TokenState.Collapsed, outcome2);

        // Entanglement is broken after measurement
        info1.entangledPartnerId = 0;
        info2.entangledPartnerId = 0;

        emit Measured(tokenId, outcome1, info1.measurementTimestamp);
        emit Measured(tokenId2, outcome2, info2.measurementTimestamp);
        emit Disentangled(tokenId, tokenId2); // Implicit disentanglement
    }

    /// @dev Attempts to transition a Collapsed token to a higher energy state (e.g., Ground -> Excited).
    /// @param tokenId The ID of the token.
    function attemptStateExcitation(uint256 tokenId) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        TokenQuantumInfo storage tokenInfo = _tokenQuantumInfo[tokenId];
        if (tokenInfo.state != TokenState.Collapsed) revert NotCollapsed();

        StateType currentState = tokenInfo.collapsedStateType;
        StateType attemptedState;
        uint16 successProbability = 0; // In basis points

        // Define excitation rules and probabilities
        if (currentState == StateType.Ground) {
            attemptedState = StateType.Excited;
            successProbability = 3000; // 30% chance of success
        } else if (currentState == StateType.Decohered) {
             attemptedState = StateType.Ground; // Decohered can be 're-excited' to Ground
             successProbability = 5000; // 50% chance
        } else {
             // No defined excitation path from this state or already too high
             revert StateTransitionFailed();
        }

        // Use pseudo-randomness to determine success
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId))) % 10000;
        bool success = randomValue < successProbability;

        if (success) {
            _updateTokenState(tokenId, TokenState.Collapsed, attemptedState);
        }

        emit StateTransitionAttempt(tokenId, currentState, attemptedState, success);
        if (!success) revert StateTransitionFailed(); // Revert if failed (optional, could just emit event)
    }

     /// @dev Attempts to transition a Collapsed token to a specific lower energy state (e.g., Excited -> Ground or Decohered).
    /// @param tokenId The ID of the token.
    /// @param targetState The specific StateType to attempt transitioning to. Must be a valid target.
    function attemptStateDecoherence(uint256 tokenId, StateType targetState) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        TokenQuantumInfo storage tokenInfo = _tokenQuantumInfo[tokenId];
        if (tokenInfo.state != TokenState.Collapsed) revert NotCollapsed();
         if (!_stateDetails[targetState].exists) revert InvalidStateType();

        StateType currentState = tokenInfo.collapsedStateType;
        uint16 successProbability = 0; // In basis points

        // Define decoherence/transition rules and probabilities
        if (currentState == StateType.Excited && targetState == StateType.Ground) {
            successProbability = 9000; // 90% chance Excited -> Ground (natural decay)
        } else if (currentState == StateType.Excited && targetState == StateType.Decohered) {
            successProbability = 6000; // 60% chance Excited -> Decohered (forced/unstable decay)
        } else if (currentState == StateType.Entangled_Observer && targetState == StateType.Ground) {
             successProbability = 7000; // 70% chance Entangled_Observer -> Ground (stable decay)
        }
        // Add more rules as needed... e.g., Ground -> Decohered (if forced?)
        else {
             // No defined transition path from current state to target state
             revert StateTransitionFailed();
        }

         uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, targetState))) % 10000;
        bool success = randomValue < successProbability;

        if (success) {
            _updateTokenState(tokenId, TokenState.Collapsed, targetState);
        }

         emit StateTransitionAttempt(tokenId, currentState, targetState, success);
         if (!success) revert StateTransitionFailed(); // Revert if failed (optional)
    }


    /// @dev Attempts to merge two compatible Collapsed tokens into a new token or enhanced state.
    /// @dev Requires specific StateTypes to be merged. For simplicity, this example merges two 'Excited' into a new 'Excited' (placeholder).
    /// @dev A real implementation would define specific merge recipes (e.g., 2x Excited -> 1x Supernova State).
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function mergeCollapsedTokens(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
         if (tokenId1 == tokenId2) revert InvalidTokenId();
        _checkValidToken(tokenId1);
        _checkValidToken(tokenId2);
        _checkOwnerOrApproved(tokenId1);
        _checkOwnerOrApproved(tokenId2);

        TokenQuantumInfo storage info1 = _tokenQuantumInfo[tokenId1];
        TokenQuantumInfo storage info2 = _tokenQuantumInfo[tokenId2];

        if (info1.state != TokenState.Collapsed || info2.state != TokenState.Collapsed) revert NotCollapsed();

        StateType state1 = info1.collapsedStateType;
        StateType state2 = info2.collapsedStateType;

        // Define merge recipe: e.g., merge two Excited states
        if (state1 == StateType.Excited && state2 == StateType.Excited) {
            // Burn the two source tokens
            _burn(tokenId1);
            _burn(tokenId2);

            // Mint a new token (or enhance one of the existing ones, but burning and minting is cleaner)
            _currentTokenId++;
            uint256 newTokenId = _currentTokenId;
            address owner = msg.sender; // New token goes to the caller

             _owners[newTokenId] = owner;
            _balances[owner]++;
             // The resulting state could be a new special state type
            _tokenQuantumInfo[newTokenId].state = TokenState.Collapsed;
            _tokenQuantumInfo[newTokenId].collapsedStateType = StateType.Excited; // Placeholder: results in another Excited token for simplicity
             _tokenQuantumInfo[newTokenId].measurementTimestamp = uint64(block.timestamp);

            emit TokensMerged(tokenId1, tokenId2, newTokenId, StateType.Excited); // Emit new state
            emit Minted(owner, newTokenId, TokenState.Collapsed);
            emit Transfer(address(0), owner, newTokenId);

        } else {
             revert InvalidMergeStates(); // States are not compatible for merging
        }
    }

    /// @dev Attempts to split a Collapsed token into multiple simpler tokens.
    /// @dev Requires specific StateTypes to be split. For simplicity, this example splits a 'Decohered' into two 'Ground'.
    /// @param tokenId The ID of the token to split.
    function splitCollapsedToken(uint256 tokenId) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        TokenQuantumInfo storage tokenInfo = _tokenQuantumInfo[tokenId];
        if (tokenInfo.state != TokenState.Collapsed) revert NotCollapsed();

        StateType currentState = tokenInfo.collapsedStateType;

        // Define split recipe: e.g., split a Decohered state into two Ground states
        if (currentState == StateType.Decohered) {
             address owner = _owners[tokenId]; // Child tokens go to the parent owner

            // Burn the source token
            _burn(tokenId);

            uint256[] memory childTokenIds = new uint256[](2);
            StateType[] memory childStates = new StateType[](2);

            // Mint child tokens
            for (uint i = 0; i < 2; i++) {
                _currentTokenId++;
                uint256 childId = _currentTokenId;
                 childTokenIds[i] = childId;
                 childStates[i] = StateType.Ground; // Resulting state for children

                _owners[childId] = owner;
                _balances[owner]++;
                 _tokenQuantumInfo[childId].state = TokenState.Collapsed;
                 _tokenQuantumInfo[childId].collapsedStateType = StateType.Ground;
                 _tokenQuantumInfo[childId].measurementTimestamp = uint64(block.timestamp);

                 emit Minted(owner, childId, TokenState.Collapsed);
                 emit Transfer(address(0), owner, childId);
            }

             emit TokenSplit(tokenId, childTokenIds, childStates);

        } else {
             revert InvalidSplitState(); // State is not splittable
        }
    }


    /// @dev Burns (destroys) a token.
    /// @param tokenId The ID of the token to burn.
    function burnToken(uint256 tokenId) public whenNotPaused {
        _checkValidToken(tokenId);
        _checkOwnerOrApproved(tokenId);

        _burn(tokenId);
    }

    // --- View Functions ---

    /// @dev Gets the high-level quantum state of a token.
    /// @param tokenId The ID of the token.
    /// @return The TokenState enum value.
    function getTokenState(uint256 tokenId) public view returns (TokenState) {
        if (_owners[tokenId] == address(0)) return TokenState.NonExistent; // Check existence
        return _tokenQuantumInfo[tokenId].state;
    }

    /// @dev Gets the specific StateType if the token is Collapsed or Entangled.
    /// @param tokenId The ID of the token.
    /// @return The StateType enum value. Returns Unknown if not in a collapsed state.
    function getTokenStateType(uint256 tokenId) public view returns (StateType) {
         if (_owners[tokenId] == address(0)) revert InvalidTokenId(); // Check existence
        TokenState state = _tokenQuantumInfo[tokenId].state;
        if (state == TokenState.Collapsed || state == TokenState.Entangled) {
            return _tokenQuantumInfo[tokenId].collapsedStateType;
        }
        return StateType.Unknown;
    }

    /// @dev Gets the token ID of the entangled partner.
    /// @param tokenId The ID of the token.
    /// @return The partner's token ID, or 0 if not entangled.
    function getTokenEntanglementPair(uint256 tokenId) public view returns (uint256) {
         if (_owners[tokenId] == address(0)) revert InvalidTokenId(); // Check existence
        return _tokenQuantumInfo[tokenId].entangledPartnerId;
    }

     /// @dev Gets the details/properties of a specific StateType.
    /// @param stateType The StateType enum value.
    /// @return The QuantumStateDetails struct.
    function getStateDetails(StateType stateType) public view returns (QuantumStateDetails memory) {
        if (!_stateDetails[stateType].exists) revert InvalidStateType();
        return _stateDetails[stateType];
    }

    /// @dev Returns the possible StateTypes a Superposed token could collapse into based on current probabilities.
    /// @dev Note: This shows the *global* configuration, not per-token potential distribution.
    /// @param tokenId The ID of the token (used only for existence check, logic is global).
    /// @return An array of StateType enums that are currently possible outcomes.
    function getPossibleCollapseOutcomes(uint256 tokenId) public view returns (StateType[] memory) {
         // Optional: could check if tokenId is Superposed, but view function can show global config
         if (_owners[tokenId] == address(0)) revert InvalidTokenId(); // Check existence

         // Return only states with non-zero probability
         uint256 count = 0;
         for(uint i=0; i < _availableCollapseTypes.length; i++) {
             if (_collapseProbabilities[_availableCollapseTypes[i]] > 0) {
                 count++;
             }
         }

         StateType[] memory possibleTypes = new StateType[](count);
         uint256 index = 0;
          for(uint i=0; i < _availableCollapseTypes.length; i++) {
             if (_collapseProbabilities[_availableCollapseTypes[i]] > 0) {
                 possibleTypes[index] = _availableCollapseTypes[i];
                 index++;
             }
         }

         return possibleTypes;
    }


    // --- Admin Functions ---

    /// @dev Admin function to add or update the probability for a specific StateType during measurement.
    /// @dev Probability is in basis points (0-10000). Total probability for all types must sum to 10000.
    /// @param stateType The StateType to configure.
    /// @param probability The probability in basis points (e.g., 1000 = 10%).
    function addStateProbability(StateType stateType, uint16 probability) public onlyOwner whenNotPaused {
        if (!_stateDetails[stateType].exists) revert InvalidStateType();

        bool exists = false;
        for(uint i = 0; i < _availableCollapseTypes.length; i++) {
            if (_availableCollapseTypes[i] == stateType) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _availableCollapseTypes.push(stateType);
        }

        _collapseProbabilities[stateType] = probability;
        _checkProbabilitySum(); // Revert if sum is not 10000

        emit StateProbabilityUpdated(stateType, probability);
    }

     /// @dev Admin function to remove a StateType from the possible collapse outcomes.
    /// @dev Its probability is set to 0. The remaining probabilities must still sum to 10000.
    /// @param stateType The StateType to remove.
    function removeStateProbability(StateType stateType) public onlyOwner whenNotPaused {
        if (!_stateDetails[stateType].exists) revert InvalidStateType();
         if (_collapseProbabilities[stateType] == 0) return; // Already zero

        _collapseProbabilities[stateType] = 0;

        // Remove from the array by swapping with last and popping (gas efficient)
        for(uint i = 0; i < _availableCollapseTypes.length; i++) {
            if (_availableCollapseTypes[i] == stateType) {
                if (i < _availableCollapseTypes.length - 1) {
                     _availableCollapseTypes[i] = _availableCollapseTypes[_availableCollapseTypes.length - 1];
                }
                _availableCollapseTypes.pop();
                break;
            }
        }

        _checkProbabilitySum(); // Revert if remaining sum is not 10000

        emit StateProbabilityUpdated(stateType, 0);
    }


    /// @dev Admin function to define or update the properties of a specific StateType.
    /// @param stateType The StateType to configure.
    /// @param name The descriptive name of the state.
    /// @param power Example property.
    /// @param stability Example property.
    /// @param rarityScore Example property.
    function updateStateDetails(
        StateType stateType,
        string memory name,
        uint256 power,
        uint256 stability,
        uint256 rarityScore
    ) public onlyOwner whenNotPaused {
        _stateDetails[stateType] = QuantumStateDetails(name, power, stability, rarityScore, true);

        // Ensure this stateType is included in potential collapse types if probability is added later
         bool exists = false;
        for(uint i = 0; i < _availableCollapseTypes.length; i++) {
            if (_availableCollapseTypes[i] == stateType) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _availableCollapseTypes.push(stateType);
        }


        emit StateDetailsUpdated(stateType, name, power, stability, rarityScore);
    }


    /// @dev Admin function to set the base URI for token metadata.
    /// @param baseURI The base URI string.
    function setBaseURI(string memory baseURI) public onlyOwner whenNotPaused {
        _baseTokenURI = baseURI;
    }

    /// @dev Admin function to pause contract sensitive functionality.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Admin function to unpause contract functionality.
    function unpause() public onlyOwner whenNotPaused {
        _unpause();
    }


    // --- Internal Helper Functions ---

    /// @dev Checks if a token ID is valid (exists).
    function _checkValidToken(uint256 tokenId) internal view {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
    }

    /// @dev Checks if the caller is the owner or approved for a token.
    function _checkOwnerOrApproved(uint256 tokenId) internal view {
        address owner = _owners[tokenId];
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender) && _tokenApprovals[tokenId] != msg.sender) {
            revert NotOwnerOrApproved();
        }
    }

     /// @dev Internal check if an address is the owner or approved for a token.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId]; // This will revert if token does not exist
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }


    /// @dev Generates a pseudo-random outcome based on configured probabilities.
    /// @dev WARNING: This is NOT cryptographically secure randomness. Block data can be manipulated by miners.
    /// @param seed1 Primary seed (e.g., block.timestamp)
    /// @param seed2 Secondary seed (e.g., block.difficulty or block.number)
    /// @param seed3 Tertiary seed (e.g., tokenId or sender)
    /// @return The chosen StateType based on probabilities.
    function _generateRandomOutcome(uint256 seed1, uint256 seed2, uint256 seed3) internal view returns (StateType) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(seed1, seed2, seed3, msg.sender, block.number))) % 10000;
        uint256 cumulativeProbability = 0;

        for (uint i = 0; i < _availableCollapseTypes.length; i++) {
            StateType currentState = _availableCollapseTypes[i];
            uint16 probability = _collapseProbabilities[currentState];

            if (probability > 0) {
                cumulativeProbability += probability;
                if (randomValue < cumulativeProbability) {
                    return currentState;
                }
            }
        }

        // Fallback: should not be reached if probabilities sum to 10000
        // Could revert or return a default state like Ground or Decohered
         revert MeasurementFailed(); // Indicates probability configuration issue
    }

    /// @dev Updates the internal state and type of a token.
    /// @param tokenId The ID of the token.
    /// @param newState The new high-level TokenState.
    /// @param newStateType The new specific StateType (only if newState is Collapsed or Entangled).
    function _updateTokenState(uint256 tokenId, TokenState newState, StateType newStateType) internal {
        TokenQuantumInfo storage tokenInfo = _tokenQuantumInfo[tokenId];
        tokenInfo.state = newState;
        tokenInfo.collapsedStateType = newStateType;
        tokenInfo.measurementTimestamp = uint64(block.timestamp);
        // Note: Entanglement partner is handled separately
    }

    /// @dev Internal function to handle token transfers.
    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approvals for the token
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal function to handle safe token transfers.
     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);

        if (to.code.length > 0) {
             // If transferring to a contract, check if it implements IERC721Receiver
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert InvalidRecipient(); // ERC721Receiver rejected token
                }
            } catch (bytes memory reason) {
                 if (reason.length > 0) {
                    // Revert with the reason from the receiver contract
                     assembly {
                        revert(add(32, reason), mload(reason))
                     }
                } else {
                     revert InvalidRecipient(); // Call failed
                }
            }
        }
    }

     /// @dev Internal function to handle token burning.
    function _burn(uint256 tokenId) internal {
         address owner = ownerOf(tokenId); // Checks existence and gets owner

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);
        delete _operatorApprovals[owner][msg.sender]; // Clear caller's approval-for-all specifically

        // Decrease balance and clear ownership
        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenQuantumInfo[tokenId]; // Clear all quantum state info

        emit Burned(tokenId);
        emit Transfer(owner, address(0), tokenId);
    }


     /// @dev Internal check to ensure total collapse probability is 10000 basis points.
    function _checkProbabilitySum() internal view {
        uint256 totalProbability = 0;
        for (uint i = 0; i < _availableCollapseTypes.length; i++) {
            totalProbability += _collapseProbabilities[_availableCollapseTypes[i]];
        }
        if (totalProbability != 10000) revert ProbabilitySumNot10000();
    }

     // --- Fallback/Receive (Optional, good practice) ---
    receive() external payable {
        // Optionally handle received ether, though QST is not designed for direct ether interaction.
    }

    fallback() external payable {
         // Optionally handle fallback calls.
    }
}
```

**Explanation of Advanced Concepts & Functions:**

1.  **Superposition (`TokenState.Superposed`) & Measurement (`measureState`):** Tokens are minted in a state where their `collapsedStateType` is undecided. `measureState` uses block data (`block.timestamp`, `block.difficulty`, `block.number`, `msg.sender`) combined with the `tokenId` as a seed for pseudo-randomness. This outcome is mapped to a `StateType` based on the `_collapseProbabilities` configuration.
2.  **Probabilistic Outcomes (`_generateRandomOutcome`):** The core randomness for measurement and state transitions relies on hashing block data. **Crucially, this is *pseudo-randomness* and susceptible to miner manipulation, especially in low-difficulty environments.** For real-world high-stakes dApps, a Chainlink VRF or similar oracle-based randomness would be required.
3.  **State-Dependent Properties (`StateType`, `QuantumStateDetails`, `getStateDetails`):** The `StateType` enum and the `QuantumStateDetails` struct allow defining different properties (like `power`, `stability`, `rarityScore`) for each possible collapsed state. `getStateDetails` lets users query these properties.
4.  **Entanglement (`entangleTokens`, `disentangleTokens`, `triggerEntangledMeasurement`):**
    *   `entangleTokens` links two tokens, changing their `TokenState` to `Entangled`. Requires ownership/approval of both. Includes basic validation (no self-entanglement, specific starting states).
    *   `disentangleTokens` breaks the link. It also includes logic that forces a collapse to the `Decohered` state if the tokens were never measured while entangled, adding a consequence to breaking the link pre-measurement.
    *   `triggerEntangledMeasurement` is the *only* way to measure entangled tokens. They collapse together using related random seeds. Currently, they both collapse into the `Entangled_Observer` state in this simplified model, but this function is the hook for more complex correlated outcome logic.
5.  **State Transitions (`attemptStateExcitation`, `attemptStateDecoherence`):**
    *   These allow *collapsed* tokens to potentially change their `StateType`.
    *   `attemptStateExcitation` models moving to a higher energy state (e.g., Ground to Excited), which is probabilistic.
    *   `attemptStateDecoherence` models moving to a potentially lower or specific state (e.g., Excited to Ground or Decohered), also probabilistic.
    *   The success probability is hardcoded in this example but could be dynamic or require burning other tokens as 'energy'.
6.  **Token Merging/Splitting (`mergeCollapsedTokens`, `splitCollapsedToken`):**
    *   `mergeCollapsedTokens` burns two specific-state tokens (e.g., two 'Excited') and mints a new token (potentially with a new, combined state).
    *   `splitCollapsedToken` burns one specific-state token (e.g., 'Decohered') and mints multiple new tokens (e.g., two 'Ground').
    *   These introduce token sinks and faucets based on state combinations. The 'recipes' are hardcoded but could be parameterized.
7.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` function is overridden to potentially include the token's state in the path, allowing an off-chain metadata server to serve different JSON based on whether the token is Superposed, Collapsed (and what type), or Entangled.
8.  **Admin Config (`addStateProbability`, `removeStateProbability`, `updateStateDetails`):** The owner can dynamically adjust the probability distribution for collapse and update the descriptive properties of different `StateType`s, allowing for evolving game mechanics or token utility balancing. The probability sum check (`_checkProbabilitySum`) ensures the distribution is always valid.

This contract provides a framework for a unique token economy or game where token properties and interactions are non-static and influenced by pseudo-probabilistic "quantum" events and defined transition rules. Remember to replace the pseudo-randomness with a secure oracle for production use cases requiring true unpredictability.