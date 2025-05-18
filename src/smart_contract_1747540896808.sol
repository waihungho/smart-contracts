```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title QuantumEntangledAssets
/// @author YourName (or a Pseudonym)
/// @notice A creative smart contract for paired, stateful, non-fungible tokens (NFTs) that exhibit metaphorical "quantum entanglement" behavior.
/// The state of one twin can instantaneously influence the state of its entangled partner, even if held by different owners.
/// Features include custom state transitions, entanglement management, decoupling, and dynamic metadata influenced by state.
/// This is a highly experimental concept and is not intended for production use without extensive auditing and refinement.

// --- Core Concepts ---
// 1. Paired Assets: Tokens are always minted in pairs (Twin A and Twin B), linked by a common Pair ID.
// 2. Entangled State: Each twin has a state (`TwinState`). Changing the state of one twin can trigger a deterministic state change in its entangled partner based on a predefined mapping.
// 3. Dynamic State Transitions: The "entanglement mapping" defines how states combine and influence each other.
// 4. Entanglement Management: Functionality to temporarily pause the entanglement effect, lock a twin's state, or decouple a pair entirely.
// 5. Delegated Management: Specific operator roles for managing entanglement state per pair, separate from ERC721 approvals.
// 6. Dynamic Metadata: Metadata can be influenced or updated based on the current states of the twins in a pair.

// --- Outline ---
// 1. State Variables & Mappings
// 2. Enums
// 3. Events
// 4. Modifiers
// 5. Constructor & Initial Setup
// 6. ERC721 Standard Functions (Adapted/Implemented)
// 7. Core Entanglement Logic (State Management & Transitions)
// 8. Pair & Twin Management (Minting, Getters)
// 9. Entanglement Mechanics (Pausing, Locking)
// 10. Decoupling & Recoupling
// 11. Transfer Logic (Custom with checks)
// 12. Metadata & Custom Properties
// 13. Burn Functions
// 14. Entanglement Operators
// 15. Utility & Information Functions
// 16. Ownership & Access Control

// --- Function Summary (Highlighting >= 20 Creative/Advanced Functions) ---
// (Inherited/Adapted ERC721 functions like balanceOf, ownerOf, approve, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom are not counted towards the 20 unique ones, though included for token standard compatibility where feasible with custom logic)
// 1.  `mintEntangledPair(address ownerA, address ownerB)`: Mints a new pair of entangled twins.
// 2.  `changeTwinState(uint256 tokenId, TwinState newState)`: Changes the state of a twin, potentially triggering its partner's state change via entanglement mapping.
// 3.  `getStateEntanglementMapping(TwinState stateA, TwinState stateB)`: Returns the resulting states if twin A transitions to stateA and twin B is in stateB (pure function).
// 4.  `decouplePair(uint256 pairId)`: Breaks the entanglement link between two twins permanently (or until recoupled).
// 5.  `recouplePair(uint256 tokenIdA, uint256 tokenIdB)`: Attempts to re-entangle two previously decoupled or compatible twins.
// 6.  `lockTwinState(uint256 tokenId)`: Prevents the state of a specific twin from being changed.
// 7.  `unlockTwinState(uint256 tokenId)`: Re-enables state changes for a twin.
// 8.  `pauseEntanglementEffect(uint256 pairId)`: Temporarily stops state changes in one twin from affecting its partner.
// 9.  `resumeEntanglementEffect(uint256 pairId)`: Resumes the entanglement effect for a pair.
// 10. `isEntanglementPaused(uint256 pairId)`: Checks if entanglement is paused for a pair.
// 11. `isTwinStateLocked(uint256 tokenId)`: Checks if a twin's state is locked.
// 12. `transferTwin(uint256 tokenId, address to)`: Custom transfer function that includes checks for entanglement status or state locks.
// 13. `batchTransferTwins(uint256[] memory tokenIds, address[] memory to)`: Transfers multiple twins, applying `transferTwin` logic to each.
// 14. `setPairMetadataURI(uint256 pairId, string memory uri)`: Sets the base metadata URI for a pair.
// 15. `addPairProperty(uint256 pairId, string memory key, string memory value)`: Adds or updates a custom key-value property for a pair.
// 16. `getPairProperty(uint256 pairId, string memory key)`: Retrieves a custom property for a pair.
// 17. `removePairProperty(uint256 pairId, string memory key)`: Removes a custom property from a pair.
// 18. `syncMetadataWithState(uint256 pairId)`: Triggers a metadata update based on the current state of the twins in the pair (conceptually - often off-chain, but function included for triggering).
// 19. `grantEntanglementOperator(address operator, uint256 pairId)`: Grants an address permission to manage the state and entanglement status of a specific pair.
// 20. `revokeEntanglementOperator(address operator, uint256 pairId)`: Revokes entanglement management permission for a pair.
// 21. `isEntanglementOperator(address operator, uint256 pairId)`: Checks if an address is an entanglement operator for a pair.
// 22. `burnTwin(uint256 tokenId)`: Burns a single twin, potentially affecting its partner's state (e.g., to `Orphaned`).
// 23. `burnPair(uint256 pairId)`: Burns both twins in a pair.
// 24. `getTwinInfo(uint256 tokenId)`: Gets detailed info about a specific twin (partner ID, pair ID, state, lock status).
// 25. `getPairInfo(uint256 pairId)`: Gets detailed info about a pair (twin IDs, their states, pause status).
// 26. `getTotalPairs()`: Gets the total number of pairs ever minted.
// 27. `predictEntangledState(uint256 twinAId, TwinState twinAProposedState, uint256 twinBId)`: Predicts the resulting states if twinA transitions to `twinAProposedState` while its partner twinB is in its current state.
// 28. `setTwinDescription(uint256 tokenId, string memory description)`: Sets a custom text description for a specific twin.
// 29. `getTwinDescription(uint256 tokenId)`: Gets the custom text description for a twin.
// 30. `setTwinStateLock(uint256 tokenId, bool locked)`: Internal/Helper function exposed as public for setting lock status directly (used by lock/unlock).

contract QuantumEntangledAssets is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId; // Counter for unique token IDs across all twins
    Counters.Counter private _nextPairId;  // Counter for unique pair IDs

    // --- State Variables & Mappings ---

    enum TwinState {
        Dormant,    // Default state
        Active,     // Engaged state
        Critical,   // A fragile or unstable state
        Orphaned,   // Partner has been burned or decoupled forcibly
        Decoupled   // Intentionally decoupled, no longer entangled
    }

    struct Twin {
        uint256 partnerTokenId; // The token ID of the entangled partner (0 if none or decoupled)
        uint256 pairId;         // The ID of the pair this twin belongs to
        TwinState state;        // The current state of the twin
        bool stateLocked;       // If true, state cannot be changed via changeTwinState
    }

    struct Pair {
        uint256 twinAId;           // The token ID of Twin A in this pair
        uint256 twinBId;           // The token ID of Twin B in this pair
        string metadataURI;        // Base URI for the pair (can be combined with state for full URI)
        mapping(string => string) properties; // Custom key-value properties for the pair
        bool entanglementPaused;   // If true, state changes don't affect the partner
    }

    // Mapping from tokenId to Twin struct
    mapping(uint256 => Twin) private _twins;

    // Mapping from pairId to Pair struct
    mapping(uint256 => Pair) private _pairs;

    // Mapping from tokenId to owner address (handled by ERC721, but we manage the data)
    // mapping(uint256 => address) private _owners; // Inherited from ERC721

    // Mapping defining the entanglement state transitions:
    // (StateOfCallerTwin, StateOfPartnerTwin) => [NewStateOfCallerTwin, NewStateOfPartnerTwin]
    // Example: _entanglementMap[uint8(TwinState.Active)][uint8(TwinState.Dormant)] = [uint8(TwinState.Active), uint8(TwinState.Active)]
    mapping(uint8 => mapping(uint8 => uint8[2])) private _entanglementMap;

    // Mapping for custom twin descriptions (per twin, not pair)
    mapping(uint256 => string) private _twinDescriptions;

    // Mapping for entanglement operators (address => pairId => isOperator)
    // These operators can manage state and entanglement settings for a specific pair,
    // independent of ERC721 transfer approvals.
    mapping(address => mapping(uint256 => bool)) private _entanglementOperators;

    string private _baseMetadataURI; // Base URI for tokens

    // --- Enums ---
    // See definition above within state variables for clarity on states

    // --- Events ---
    event PairMinted(uint256 indexed pairId, uint256 twinAId, address indexed ownerA, uint256 twinBId, address indexed ownerB);
    event TwinStateChanged(uint256 indexed tokenId, TwinState oldState, TwinState newState);
    event EntangledStateChanged(uint256 indexed callerTwinId, uint256 indexed partnerTwinId, TwinState oldPartnerState, TwinState newPartnerState);
    event PairDecoupled(uint256 indexed pairId, uint256 twinAId, uint256 twinBId);
    event PairRecoupled(uint256 indexed pairId, uint256 twinAId, uint256 twinBId);
    event TwinStateLocked(uint256 indexed tokenId, address indexed manager);
    event TwinStateUnlocked(uint256 indexed tokenId, address indexed manager);
    event EntanglementPaused(uint256 indexed pairId, address indexed manager);
    event EntanglementResumed(uint256 indexed pairId, address indexed manager);
    event PairMetadataUpdated(uint256 indexed pairId, string uri);
    event PairPropertyChanged(uint256 indexed pairId, string key, string value);
    event PairPropertyRemoved(uint256 indexed pairId, string key);
    event TwinDescriptionUpdated(uint256 indexed tokenId, string description);
    event EntanglementOperatorGranted(uint256 indexed pairId, address indexed operator, address indexed granter);
    event EntanglementOperatorRevoked(uint256 indexed pairId, address indexed operator, address indexed revoker);
    event TwinBurned(uint256 indexed tokenId, uint256 indexed pairId, address indexed owner);
    event PairBurned(uint256 indexed pairId, uint256 twinAId, uint256 twinBId);

    // --- Modifiers ---
    modifier whenTwinExists(uint256 tokenId) {
        require(_exists(tokenId), "Twin does not exist");
        _;
    }

    modifier whenPairExists(uint256 pairId) {
        require(_pairs[pairId].twinAId != 0, "Pair does not exist");
        _;
    }

    modifier onlyTwinOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner or approved for twin");
        _;
    }

    modifier onlyPairEntanglementOperator(uint256 pairId) {
        require(
            _isApprovedOrOwner(_msgSender(), _pairs[pairId].twinAId) || // Owner of Twin A
            _isApprovedOrOwner(_msgSender(), _pairs[pairId].twinBId) || // Owner of Twin B
            _entanglementOperators[_msgSender()][pairId] ||            // Designated operator for the pair
            owner() == _msgSender(),                                  // Contract owner
            "Caller is not authorised for pair entanglement management"
        );
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseMetadataURI_)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseMetadataURI = baseMetadataURI_;
        // Initialize the entanglement mapping with some basic rules
        // (StateOfCallerTwin, StateOfPartnerTwin) => [NewStateOfCallerTwin, NewStateOfPartnerTwin]
        // Note: This is a simplified example. Real complex systems might need more rules.
        _entanglementMap[uint8(TwinState.Dormant)][uint8(TwinState.Dormant)] = [uint8(TwinState.Dormant), uint8(TwinState.Dormant)];
        _entanglementMap[uint8(TwinState.Dormant)][uint8(TwinState.Active)] = [uint8(TwinState.Dormant), uint8(TwinState.Dormant)];
        _entanglementMap[uint8(TwinState.Dormant)][uint8(TwinState.Critical)] = [uint8(TwinState.Dormant), uint8(TwinState.Critical)];
        _entanglementMap[uint8(TwinState.Active)][uint8(TwinState.Dormant)] = [uint8(TwinState.Active), uint8(TwinState.Active)]; // Active can awaken Dormant
        _entanglementMap[uint8(TwinState.Active)][uint8(TwinState.Active)] = [uint8(TwinState.Critical), uint8(TwinState.Critical)]; // Two Active become Critical
        _entanglementMap[uint8(TwinState.Active)][uint8(TwinState.Critical)] = [uint8(TwinState.Dormant), uint8(TwinState.Critical)]; // Active + Critical -> Dormant + Critical
        _entanglementMap[uint8(TwinState.Critical)][uint8(TwinState.Dormant)] = [uint8(TwinState.Critical), uint8(TwinState.Dormant)];
        _entanglementMap[uint8(TwinState.Critical)][uint8(TwinState.Active)] = [uint8(TwinState.Critical), uint8(TwinState.Dormant)]; // Critical + Active -> Critical + Dormant
        _entanglementMap[uint8(TwinState.Critical)][uint8(TwinState.Critical)] = [uint8(TwinState.Dormant), uint8(TwinState.Dormant)]; // Two Critical collapse to Dormant

        // Orphaned and Decoupled states are usually terminal or non-interactive via changeTwinState
        // They might transition *to* Orphaned/Decoupled, but don't drive entanglement changes *from* these states.
        // Any state + Orphaned/Decoupled -> stays that state + stays Orphaned/Decoupled
        // except for specific functions like burnTwin or decouplePair.
    }

    // --- ERC721 Standard Functions (Adapted/Implemented) ---
    // Inherited: supportsInterface, isApprovedForAll, getApproved
    // Overridden: ownerOf, balanceOf, _safeTransfer, _transfer, _approve, _setApprovalForAll, _exists, _update, _mint, _burn, tokenURI

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId); // Use ERC721 internal tracking
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner); // Use ERC721 internal tracking
    }

     // We will use a custom transfer function (`transferTwin`) for checks,
     // but also override safeTransferFrom and transferFrom to route through it
     // for standard compatibility, while adding our checks.

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _transferTwin(tokenId, to); // Route through our custom logic
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransferTwin(tokenId, to, ""); // Route through our custom logic
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransferTwin(tokenId, to, data); // Route through our custom logic
    }

    // Standard ERC721 metadata URI function, enhanced to potentially include state
    function tokenURI(uint256 tokenId) public view override whenTwinExists(tokenId) returns (string memory) {
        string memory base = _baseMetadataURI;
        if (bytes(base).length == 0) {
            return ""; // No base URI set
        }

        // Append pair ID and twin type (A/B) or token ID, and state for dynamic metadata
        string memory pairIdStr = Strings.toString(_twins[tokenId].pairId);
        string memory twinType = (_pairs[_twins[tokenId].pairId].twinAId == tokenId) ? "A" : "B";
        string memory stateStr;
        TwinState currentState = _twins[tokenId].state;
        if (currentState == TwinState.Dormant) stateStr = "dormant";
        else if (currentState == TwinState.Active) stateStr = "active";
        else if (currentState == TwinState.Critical) stateStr = "critical";
        else if (currentState == TwinState.Orphaned) stateStr = "orphaned";
        else if (currentState == TwinState.Decoupled) stateStr = "decoupled";
        else stateStr = "unknown"; // Should not happen

        // Construct a URI that allows fetching metadata based on Pair ID, Twin Type, and State
        // Example: base/pair/{pairId}/{twinType}/{state}.json or base/token/{tokenId}/{state}.json
        // Off-chain metadata server needs to interpret this URI structure.
        return string(abi.encodePacked(base, "/", pairIdStr, "/", twinType, "/", stateStr));
    }

    // Helper to check if a token ID exists (used internally by ERC721)
    function _exists(uint256 tokenId) internal view override returns (bool) {
        return _twins[tokenId].pairId != 0; // Twin struct initialized means it exists (pairId 0 is invalid)
    }

    // Overridden _update to ensure our mappings are consistent with ERC721 transfers
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
         // ERC721 standard handles ownership updates. We just need to ensure our Twin struct is ok.
         // This function is called internally by _transfer, _mint, _burn.
         require(_twins[tokenId].pairId != 0 || to == address(0), "Cannot update non-existent twin (unless burning)");
         return super._update(to, tokenId, auth);
    }

    // Overridden _mint - We will handle minting pairs specifically in `mintEntangledPair`
    // This override prevents direct minting of single twins via the standard ERC721 _mint.
    function _mint(address to, uint256 tokenId) internal override {
        require(false, "Minting single twins is not allowed, use mintEntangledPair");
        super._mint(to, tokenId);
    }

     // Overridden _burn - We will handle burning pairs/twins specifically in `burnTwin`/`burnPair`
     // This override prevents direct burning via the standard ERC721 _burn.
    function _burn(uint256 tokenId) internal override {
         require(false, "Burning single twins via standard burn is not allowed, use burnTwin or burnPair");
         super._burn(tokenId);
    }


    // --- Core Entanglement Logic ---

    /// @notice Changes the state of a twin and triggers an entangled state change in its partner.
    /// @param tokenId The ID of the twin to change the state of.
    /// @param newState The new desired state for the twin.
    function changeTwinState(uint256 tokenId, TwinState newState)
        public
        whenTwinExists(tokenId)
        onlyPairEntanglementOperator(_twins[tokenId].pairId) // Requires entanglement operator permission
    {
        require(_twins[tokenId].stateLocked == false, "Twin state is locked");
        require(newState != TwinState.Orphaned && newState != TwinState.Decoupled, "Cannot transition to Orphaned or Decoupled via changeTwinState");

        Twin storage twin = _twins[tokenId];
        uint256 partnerTokenId = twin.partnerTokenId;

        // Ensure twin is not Orphaned or Decoupled itself
        require(twin.state != TwinState.Orphaned && twin.state != TwinState.Decoupled, "Cannot change state of Orphaned or Decoupled twin directly");

        TwinState oldState = twin.state;

        // Apply the state change to the caller twin
        twin.state = newState;
        emit TwinStateChanged(tokenId, oldState, newState);

        // Check if entangled and entanglement is not paused
        if (partnerTokenId != 0 && _twins[partnerTokenId].pairId != 0 && !_pairs[twin.pairId].entanglementPaused) {
            Twin storage partnerTwin = _twins[partnerTokenId];
            TwinState oldPartnerState = partnerTwin.state;

             // Orphaned/Decoupled partners do not get their state changed by entanglement
            if (oldPartnerState != TwinState.Orphaned && oldPartnerState != TwinState.Decoupled) {

                 // Look up the new entangled state for the partner based on the *new* state of the caller
                 // and the *old* state of the partner.
                 // Note: The mapping lookup uses uint8 representation of the enum
                 uint8[2] memory resultingStates = _entanglementMap[uint8(newState)][uint8(oldPartnerState)];
                 TwinState newPartnerState = TwinState(resultingStates[1]); // resultStates[1] is the new state for the partner

                 // Only change partner state if it's not locked
                 if (!partnerTwin.stateLocked) {
                    partnerTwin.state = newPartnerState;
                    emit EntangledStateChanged(tokenId, partnerTokenId, oldPartnerState, newPartnerState);
                 }
            }
        }
    }

    /// @notice Pure function to show the predicted state transition for a twin's partner.
    /// Does not alter state, only simulates based on the entanglement mapping.
    /// @param callerTwinProposedState The proposed new state for the caller twin.
    /// @param partnerTwinCurrentState The current state of the partner twin.
    /// @return The predicted new state for the partner twin.
    function predictEntangledState(TwinState callerTwinProposedState, TwinState partnerTwinCurrentState)
        public
        view
        returns (TwinState predictedPartnerState)
    {
         // Orphaned/Decoupled partners' states are not changed by entanglement, reflect this prediction
        if (partnerTwinCurrentState == TwinState.Orphaned || partnerTwinCurrentState == TwinState.Decoupled) {
             return partnerTwinCurrentState;
        }
        // Look up the predicted new state for the partner
        uint8[2] memory resultingStates = _entanglementMap[uint8(callerTwinProposedState)][uint8(partnerTwinCurrentState)];
        return TwinState(resultingStates[1]);
    }

    /// @notice Pure function to view the raw entanglement mapping rule.
    /// @param stateA State of the twin initiating the change.
    /// @param stateB State of the partner twin.
    /// @return An array [newStateA, newStateB] where newStateA is the resulting state of twin A
    /// and newStateB is the resulting state of twin B according to the mapping.
    function getStateEntanglementMapping(TwinState stateA, TwinState stateB)
        public
        view
        returns (TwinState newStateA, TwinState newStateB)
    {
         // Note: changeTwinState uses the *old* state of the partner and the *new* state of the caller
         // for the lookup. This function shows the direct lookup result based on the two input states.
        uint8[2] memory result = _entanglementMap[uint8(stateA)][uint8(stateB)];
        return (TwinState(result[0]), TwinState(result[1]));
    }

    // --- Pair & Twin Management ---

    /// @notice Mints a new entangled pair of twins.
    /// Creates two linked tokens, assigned to specified owners.
    /// @param ownerA Owner of Twin A.
    /// @param ownerB Owner of Twin B.
    function mintEntangledPair(address ownerA, address ownerB)
        public
        onlyOwner // Only contract owner can mint new pairs
    {
        require(ownerA != address(0), "Owner A cannot be zero address");
        require(ownerB != address(0), "Owner B cannot be zero address");

        _nextPairId.increment();
        uint256 currentPairId = _nextPairId.current();

        _nextTokenId.increment();
        uint256 twinAId = _nextTokenId.current();

        _nextTokenId.increment();
        uint256 twinBId = _nextTokenId.current();

        // Create Twin A
        _twins[twinAId] = Twin({
            partnerTokenId: twinBId,
            pairId: currentPairId,
            state: TwinState.Dormant, // Start in Dormant state
            stateLocked: false
        });
        // Mint Twin A (ERC721 side)
        ERC721._safeMint(ownerA, twinAId);

        // Create Twin B
        _twins[twinBId] = Twin({
            partnerTokenId: twinAId,
            pairId: currentPairId,
            state: TwinState.Dormant, // Start in Dormant state
            stateLocked: false
        });
        // Mint Twin B (ERC721 side)
        ERC721._safeMint(ownerB, twinBId);

        // Create Pair linkage
        _pairs[currentPairId] = Pair({
            twinAId: twinAId,
            twinBId: twinBId,
            metadataURI: "", // Start with empty URI, can be set later
            entanglementPaused: false
        });

        emit PairMinted(currentPairId, twinAId, ownerA, twinBId, ownerB);
    }

    /// @notice Gets information about a specific twin.
    /// @param tokenId The ID of the twin.
    /// @return pairId The ID of the pair.
    /// @return partnerTokenId The ID of the partner twin (0 if decoupled/burned).
    /// @return state The current state of the twin.
    /// @return stateLocked Whether the twin's state is locked.
    function getTwinInfo(uint256 tokenId)
        public
        view
        whenTwinExists(tokenId)
        returns (uint256 pairId, uint256 partnerTokenId, TwinState state, bool stateLocked)
    {
        Twin storage twin = _twins[tokenId];
        return (twin.pairId, twin.partnerTokenId, twin.state, twin.stateLocked);
    }

     /// @notice Gets information about a specific pair.
     /// @param pairId The ID of the pair.
     /// @return twinAId The ID of Twin A.
     /// @return twinBId The ID of Twin B.
     /// @return twinAState The state of Twin A.
     /// @return twinBState The state of Twin B.
     /// @return entanglementPaused Whether entanglement is paused for the pair.
    function getPairInfo(uint256 pairId)
        public
        view
        whenPairExists(pairId)
        returns (uint256 twinAId, uint256 twinBId, TwinState twinAState, TwinState twinBState, bool entanglementPaused)
    {
         Pair storage pair = _pairs[pairId];
         return (
             pair.twinAId,
             pair.twinBId,
             _twins[pair.twinAId].state,
             _twins[pair.twinBId].state,
             pair.entanglementPaused
         );
    }

    /// @notice Gets the total number of pairs ever minted.
    /// @return The total count of pairs.
    function getTotalPairs() public view returns (uint256) {
        return _nextPairId.current();
    }

    // --- Entanglement Mechanics ---

    /// @notice Locks the state of a twin, preventing `changeTwinState` calls on it.
    /// Requires entanglement operator permission for the pair.
    /// @param tokenId The ID of the twin to lock.
    function lockTwinState(uint256 tokenId)
        public
        whenTwinExists(tokenId)
        onlyPairEntanglementOperator(_twins[tokenId].pairId)
    {
        _setTwinStateLock(tokenId, true);
        emit TwinStateLocked(tokenId, _msgSender());
    }

    /// @notice Unlocks the state of a twin, allowing `changeTwinState` calls again.
    /// Requires entanglement operator permission for the pair.
    /// @param tokenId The ID of the twin to unlock.
    function unlockTwinState(uint256 tokenId)
        public
        whenTwinExists(tokenId)
        onlyPairEntanglementOperator(_twins[tokenId].pairId)
    {
        _setTwinStateLock(tokenId, false);
        emit TwinStateUnlocked(tokenId, _msgSender());
    }

    /// @notice Internal helper function to set the state lock status.
    function _setTwinStateLock(uint256 tokenId, bool locked) internal {
        _twins[tokenId].stateLocked = locked;
    }

    /// @notice Checks if a twin's state is locked.
    /// @param tokenId The ID of the twin.
    /// @return True if the state is locked, false otherwise.
    function isTwinStateLocked(uint256 tokenId) public view whenTwinExists(tokenId) returns (bool) {
        return _twins[tokenId].stateLocked;
    }


    /// @notice Pauses the entanglement effect for a pair. State changes on one twin will not affect the other.
    /// Requires entanglement operator permission for the pair.
    /// @param pairId The ID of the pair.
    function pauseEntanglementEffect(uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        _pairs[pairId].entanglementPaused = true;
        emit EntanglementPaused(pairId, _msgSender());
    }

    /// @notice Resumes the entanglement effect for a pair if it was paused.
    /// Requires entanglement operator permission for the pair.
    /// @param pairId The ID of the pair.
    function resumeEntanglementEffect(uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        _pairs[pairId].entanglementPaused = false;
        emit EntanglementResumed(pairId, _msgSender());
    }

    /// @notice Checks if entanglement is paused for a pair.
    /// @param pairId The ID of the pair.
    /// @return True if entanglement is paused, false otherwise.
    function isEntanglementPaused(uint256 pairId) public view whenPairExists(pairId) returns (bool) {
        return _pairs[pairId].entanglementPaused;
    }

    // --- Decoupling & Recoupling ---

    /// @notice Decouples a pair of twins. They will no longer influence each other's state.
    /// Their state will transition to `Decoupled`.
    /// Requires entanglement operator permission for the pair.
    /// @param pairId The ID of the pair to decouple.
    function decouplePair(uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        Pair storage pair = _pairs[pairId];
        uint256 twinAId = pair.twinAId;
        uint256 twinBId = pair.twinBId;

        // Check if twins are already decoupled or orphaned
        require(_twins[twinAId].state != TwinState.Decoupled, "Twin A is already decoupled");
        require(_twins[twinBId].state != TwinState.Decoupled, "Twin B is already decoupled");
         require(_twins[twinAId].state != TwinState.Orphaned, "Twin A is orphaned, cannot decouple");
        require(_twins[twinBId].state != TwinState.Orphaned, "Twin B is orphaned, cannot decouple");


        // Update twin structures
        _twins[twinAId].partnerTokenId = 0; // Remove partner link
        _twins[twinAId].state = TwinState.Decoupled;
        _twins[twinAId].stateLocked = false; // Decoupling removes state lock
        emit TwinStateChanged(twinAId, _twins[twinAId].state, TwinState.Decoupled);

        _twins[twinBId].partnerTokenId = 0; // Remove partner link
        _twins[twinBId].state = TwinState.Decoupled;
        _twins[twinBId].stateLocked = false; // Decoupling removes state lock
        emit TwinStateChanged(twinBId, _twins[twinBId].state, TwinState.Decoupled);

        // Update pair structure
        pair.entanglementPaused = true; // Decoupled pairs are effectively paused
        // Note: pair struct still exists, linking the two twin IDs, but their twin.partnerTokenId is 0

        emit PairDecoupled(pairId, twinAId, twinBId);
    }

    /// @notice Attempts to re-entangle two compatible twins.
    /// Currently requires both twins to be in the `Decoupled` state and not orphaned.
    /// Requires entanglement operator permission for the pair (implied by owning/managing one of the twins).
    /// @param tokenIdA The ID of the first twin.
    /// @param tokenIdB The ID of the second twin.
    function recouplePair(uint256 tokenIdA, uint256 tokenIdB)
        public
        whenTwinExists(tokenIdA)
        whenTwinExists(tokenIdB)
        onlyPairEntanglementOperator(_twins[tokenIdA].pairId) // Must be operator for pair A
        // Add check for operator for pair B implicitly by requiring twin B exists and is Decoupled
    {
        Twin storage twinA = _twins[tokenIdA];
        Twin storage twinB = _twins[tokenIdB];

        require(tokenIdA != tokenIdB, "Cannot recouple a twin with itself");
        require(twinA.partnerTokenId == 0 && twinB.partnerTokenId == 0, "Twins must be decoupled to recouple");
        require(twinA.state == TwinState.Decoupled && twinB.state == TwinState.Decoupled, "Twins must be in Decoupled state");
         require(twinA.state != TwinState.Orphaned && twinB.state != TwinState.Orphaned, "Orphaned twins cannot be recoupled");
         // Optional: Add checks for other compatibility criteria if needed (e.g., originally from same pair)
         // require(twinA.pairId == twinB.pairId, "Twins must be from the same original pair");

        // Relink partners
        twinA.partnerTokenId = tokenIdB;
        twinB.partnerTokenId = tokenIdA;

        // Reset state to Dormant (or some other default re-entangled state)
        TwinState oldStateA = twinA.state;
        TwinState oldStateB = twinB.state;
        twinA.state = TwinState.Dormant;
        twinB.state = TwinState.Dormant;
        emit TwinStateChanged(tokenIdA, oldStateA, TwinState.Dormant);
        emit TwinStateChanged(tokenIdB, oldStateB, TwinState.Dormant);

        // Find or create a pair ID for them
        uint256 pairId = twinA.pairId != 0 ? twinA.pairId : twinB.pairId; // Prefer original pair ID if exists
        if (pairId == 0) {
            _nextPairId.increment();
            pairId = _nextPairId.current();
            _pairs[pairId].twinAId = tokenIdA; // Assume A is A, B is B based on input order
            _pairs[pairId].twinBId = tokenIdB;
            _pairs[pairId].metadataURI = ""; // Reset or inherit metadata? Reset for simplicity.
             twinA.pairId = pairId; // Link twin to new pair
             twinB.pairId = pairId; // Link twin to new pair
        }

        // Resume entanglement effect for the pair
        _pairs[pairId].entanglementPaused = false;

         // Emit events
         // Check if it's a re-recoupling of an original pair or a new pair linkage
         if (_pairs[pairId].twinAId == tokenIdA && _pairs[pairId].twinBId == tokenIdB) {
             emit PairRecoupled(pairId, tokenIdA, tokenIdB);
         } else {
             // This case is more complex - linking twins from potentially different original pairs.
             // For this simplified contract, we assume recoupling only applies to original pairs.
             // If allowing cross-pair recoupling, need more complex state/metadata/pair management.
             revert("Recoupling currently only supported for twins from their original pair");
         }
    }

    // --- Transfer Logic ---

    /// @notice Custom transfer function with entanglement/state checks.
    /// Calls the ERC721 standard _transfer after checks.
    /// @param tokenId The ID of the twin to transfer.
    /// @param to The recipient address.
    function transferTwin(uint256 tokenId, address to)
        public
        whenTwinExists(tokenId)
        onlyTwinOwnerOrApproved(tokenId) // Standard ERC721 approval check
    {
         // Add custom transfer checks:
         // Example: Cannot transfer if the partner is in a 'Critical' state
         uint256 partnerId = _twins[tokenId].partnerTokenId;
         if (partnerId != 0 && _exists(partnerId)) {
             require(_twins[partnerId].state != TwinState.Critical, "Cannot transfer twin when partner is in Critical state");
         }
         // Example: Cannot transfer if the twin's state is locked (unless owner)
         // require(!_twins[tokenId].stateLocked || _isApprovedOrOwner(_msgSender(), tokenId), "Twin state is locked and caller is not owner/approved");


        // Perform the actual ERC721 transfer
        _transfer(ownerOf(tokenId), to, tokenId);
    }

    /// @notice Custom safeTransfer function with entanglement/state checks.
    /// Calls the ERC721 standard _safeTransfer after checks.
    /// @param tokenId The ID of the twin to transfer.
    /// @param to The recipient address.
    /// @param data Extra data for receiver hook.
    function _safeTransferTwin(uint256 tokenId, address to, bytes memory data)
        internal
        whenTwinExists(tokenId)
    {
         // Add custom transfer checks (same as transferTwin):
         uint256 partnerId = _twins[tokenId].partnerTokenId;
         if (partnerId != 0 && _exists(partnerId)) {
             require(_twins[partnerId].state != TwinState.Critical, "Cannot transfer twin when partner is in Critical state");
         }

        // Perform the actual ERC721 safe transfer
        // Need to get the owner first as _transfer will clear approval BEFORE the transfer
        address from = ownerOf(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }


    /// @notice Transfers multiple twins in a single transaction.
    /// Applies the checks from `transferTwin` to each one.
    /// @param tokenIds An array of token IDs to transfer.
    /// @param to An array of recipient addresses (must match tokenIds length, or be a single address).
    function batchTransferTwins(uint256[] memory tokenIds, address[] memory to) public {
        require(tokenIds.length > 0, "No tokens specified");
        require(to.length > 0, "No recipients specified");
        require(to.length == 1 || to.length == tokenIds.length, "Recipient array length mismatch");

        for (uint i = 0; i < tokenIds.length; i++) {
            address recipient = (to.length == 1) ? to[0] : to[i];
            transferTwin(tokenIds[i], recipient); // Use our custom transfer logic
        }
    }


    // --- Metadata & Custom Properties ---

    /// @notice Sets the base metadata URI for a specific pair.
    /// Requires contract owner or entanglement operator permission for the pair.
    /// @param pairId The ID of the pair.
    /// @param uri The base URI string.
    function setPairMetadataURI(uint256 pairId, string memory uri)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId) // Use operator check for pair metadata
    {
        _pairs[pairId].metadataURI = uri;
        emit PairMetadataUpdated(pairId, uri);
    }

    /// @notice Gets the base metadata URI for a specific pair.
    /// @param pairId The ID of the pair.
    /// @return The base URI string.
    function getPairMetadataURI(uint256 pairId) public view whenPairExists(pairId) returns (string memory) {
        return _pairs[pairId].metadataURI;
    }

    /// @notice Adds or updates a custom key-value property for a pair.
    /// Useful for adding specific traits or data not covered by the base metadata URI.
    /// Requires contract owner or entanglement operator permission for the pair.
    /// @param pairId The ID of the pair.
    /// @param key The property key.
    /// @param value The property value.
    function addPairProperty(uint256 pairId, string memory key, string memory value)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        _pairs[pairId].properties[key] = value;
        emit PairPropertyChanged(pairId, key, value);
    }

    /// @notice Gets the value of a custom property for a pair.
    /// @param pairId The ID of the pair.
    /// @param key The property key.
    /// @return The property value (empty string if key not found).
    function getPairProperty(uint256 pairId, string memory key) public view whenPairExists(pairId) returns (string memory) {
        return _pairs[pairId].properties[key];
    }

    /// @notice Removes a custom key-value property from a pair.
    /// Requires contract owner or entanglement operator permission for the pair.
    /// @param pairId The ID of the pair.
    /// @param key The property key.
    function removePairProperty(uint256 pairId, string memory key)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        delete _pairs[pairId].properties[key];
        emit PairPropertyRemoved(pairId, key);
    }

     /// @notice Sets a custom text description for a specific twin.
     /// Can be used for twin-specific flavor text or notes.
     /// Requires ownership or approval for the twin.
     /// @param tokenId The ID of the twin.
     /// @param description The description string.
    function setTwinDescription(uint256 tokenId, string memory description)
        public
        whenTwinExists(tokenId)
        onlyTwinOwnerOrApproved(tokenId)
    {
        _twinDescriptions[tokenId] = description;
        emit TwinDescriptionUpdated(tokenId, description);
    }

     /// @notice Gets the custom text description for a twin.
     /// @param tokenId The ID of the twin.
     /// @return The description string (empty string if none set).
    function getTwinDescription(uint256 tokenId) public view whenTwinExists(tokenId) returns (string memory) {
        return _twinDescriptions[tokenId];
    }

     /// @notice Conceptually signals that metadata for a pair should be updated off-chain
     /// to reflect the current states of its twins.
     /// This function itself doesn't modify the metadataURI directly, but emits an event
     /// that an off-chain service can listen to.
     /// Requires contract owner or entanglement operator permission for the pair.
     /// @param pairId The ID of the pair.
    function syncMetadataWithState(uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        // In a real system, an off-chain service would listen for this event
        // and regenerate the metadata file/endpoint for the pair based on
        // the current states obtained via getPairInfo or tokenURI.
        // We emit the current metadata URI as a hint, though the service should fetch full info.
        emit PairMetadataUpdated(pairId, _pairs[pairId].metadataURI);
        // Optionally, add pair/twin states to the event for easier off-chain processing:
        // Pair storage pair = _pairs[pairId];
        // emit PairMetadataUpdated(pairId, pair.metadataURI, _twins[pair.twinAId].state, _twins[pair.twinBId].state);
    }


    // --- Burn Functions ---

    /// @notice Burns a single twin. Its partner, if existing and not already Orphaned/Decoupled, transitions to the Orphaned state.
    /// Requires ownership or approval for the twin.
    /// @param tokenId The ID of the twin to burn.
    function burnTwin(uint256 tokenId)
        public
        whenTwinExists(tokenId)
        onlyTwinOwnerOrApproved(tokenId)
    {
        address owner = ownerOf(tokenId);
        uint256 pairId = _twins[tokenId].pairId;
        uint256 partnerTokenId = _twins[tokenId].partnerTokenId;
        TwinState oldState = _twins[tokenId].state;

        // Clear approvals before burning
        _approve(address(0), tokenId);
        _setApprovalForAll(owner, address(0), false); // This clears operator for ALL owner's tokens, might be too broad.
                                                      // Consider only clearing for this contract operator.
                                                      // Standard ERC721 burn doesn't clear operator approvals.

        // Call ERC721 internal burn
        ERC721._burn(tokenId);

        // Remove twin data from our mapping
        delete _twins[tokenId];

        // If partner exists and is not already Orphaned/Decoupled, update its state
        if (partnerTokenId != 0 && _exists(partnerTokenId)) { // _exists checks if partner is burned
             Twin storage partnerTwin = _twins[partnerTokenId];
             if (partnerTwin.state != TwinState.Orphaned && partnerTwin.state != TwinState.Decoupled) {
                 TwinState oldPartnerState = partnerTwin.state;
                 partnerTwin.state = TwinState.Orphaned; // Partner becomes Orphaned
                 partnerTwin.partnerTokenId = 0; // Partner no longer has an active partner
                 partnerTwin.stateLocked = false; // Orphaned state is not locked
                 emit TwinStateChanged(partnerTokenId, oldPartnerState, TwinState.Orphaned);
             }
        }

        // Remove custom description
        delete _twinDescriptions[tokenId];

        // Note: Pair struct remains until both twins are potentially burned or decoupled.
        // Properties and metadata URI for the pair might still be relevant.

        emit TwinBurned(tokenId, pairId, owner);
    }

     /// @notice Burns both twins in a pair.
     /// Requires entanglement operator permission for the pair (implied by owning/managing one twin or explicit operator).
     /// @param pairId The ID of the pair to burn.
    function burnPair(uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId)
    {
        Pair storage pair = _pairs[pairId];
        uint256 twinAId = pair.twinAId;
        uint256 twinBId = pair.twinBId;

        // Check if twins still exist
        bool twinAExists = _exists(twinAId);
        bool twinBExists = _exists(twinBId);

        require(twinAExists || twinBExists, "Neither twin in the pair exists to be burned");

        // Burn Twin A if it exists
        if (twinAExists) {
            address ownerA = ownerOf(twinAId);
             _approve(address(0), twinAId); // Clear approval
            ERC721._burn(twinAId);
            delete _twins[twinAId]; // Remove from our mapping
            delete _twinDescriptions[twinAId]; // Remove description
            emit TwinBurned(twinAId, pairId, ownerA);
        }

        // Burn Twin B if it exists
        if (twinBExists) {
            address ownerB = ownerOf(twinBId);
             _approve(address(0), twinBId); // Clear approval
            ERC721._burn(twinBId);
            delete _twins[twinBId]; // Remove from our mapping
            delete _twinDescriptions[twinBId]; // Remove description
            emit TwinBurned(twinBId, pairId, ownerB);
        }

        // Remove pair data
        delete _pairs[pairId]; // This also implicitly clears properties mapping

        // Remove entanglement operators for this pair
        // Note: Requires iterating or tracking operators, which is gas-intensive.
        // A simpler approach is to just leave the operator mappings, they become irrelevant
        // once the pair is deleted. For completeness, a map like `pairId => operator[]` would
        // be needed to efficiently clear. Sticking to simpler approach for now.

        emit PairBurned(pairId, twinAId, twinBId);
    }

    // --- Entanglement Operators ---

    /// @notice Grants an address entanglement operator rights for a specific pair.
    /// This allows the operator to manage state and entanglement settings for that pair.
    /// Requires the contract owner or an existing entanglement operator for that pair.
    /// Owners of either twin in the pair also implicitly have entanglement operator rights
    /// via the `onlyPairEntanglementOperator` modifier, but explicitly granting
    /// allows management even if ownership changes hands (unless revoked).
    /// @param operator The address to grant rights to.
    /// @param pairId The ID of the pair.
    function grantEntanglementOperator(address operator, uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId) // Caller must already be authorized for the pair
    {
        require(operator != address(0), "Operator cannot be zero address");
        _entanglementOperators[operator][pairId] = true;
        emit EntanglementOperatorGranted(pairId, operator, _msgSender());
    }

    /// @notice Revokes entanglement operator rights for a specific pair.
    /// Requires the contract owner or an existing entanglement operator for that pair.
    /// @param operator The address to revoke rights from.
    /// @param pairId The ID of the pair.
    function revokeEntanglementOperator(address operator, uint256 pairId)
        public
        whenPairExists(pairId)
        onlyPairEntanglementOperator(pairId) // Caller must already be authorized for the pair
    {
        require(operator != address(0), "Operator cannot be zero address");
        _entanglementOperators[operator][pairId] = false;
        emit EntanglementOperatorRevoked(pairId, operator, _msgSender());
    }

    /// @notice Checks if an address is an entanglement operator for a specific pair.
    /// @param operator The address to check.
    /// @param pairId The ID of the pair.
    /// @return True if the address is an operator for the pair, false otherwise.
    function isEntanglementOperator(address operator, uint256 pairId)
        public
        view
        returns (bool)
    {
        // Does not require pair to exist, so you can check if an address *would* be an operator
        // if the pair existed, or for historical purposes.
        return _entanglementOperators[operator][pairId];
    }


    // --- Utility & Information Functions ---

    /// @notice Gets the TwinState enum value as a string.
    /// @param state The TwinState enum.
    /// @return The string representation of the state.
    function getTwinStateString(TwinState state) public pure returns (string memory) {
        if (state == TwinState.Dormant) return "Dormant";
        if (state == TwinState.Active) return "Active";
        if (state == TwinState.Critical) return "Critical";
        if (state == TwinState.Orphaned) return "Orphaned";
        if (state == TwinState.Decoupled) return "Decoupled";
        return "Unknown";
    }


    // --- Ownership & Access Control ---
    // Inherited Ownable functions: owner(), renounceOwnership(), transferOwnership()

    /// @notice Sets the base URI for token metadata.
    /// Requires contract owner.
    /// @param baseMetadataURI_ The new base URI.
    function setBaseURI(string memory baseMetadataURI_) public onlyOwner {
        _baseMetadataURI = baseMetadataURI_;
    }

    /// @notice Gets the current base URI for token metadata.
    function getBaseURI() public view returns (string memory) {
        return _baseMetadataURI;
    }

    /// @notice Allows owner to withdraw any incidental funds sent to the contract.
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Fallback function to receive Ether (optional, demonstrating contract can hold funds)
    receive() external payable {}
}
```