Okay, this sounds like a fun challenge! Let's design a smart contract that models "Quantum Entangled NFTs". The core idea is that NFTs are minted in pairs, and actions on one NFT can instantaneously affect the state of its entangled partner, even if owned by different people. We can add concepts like "state collapse," "measurement," "quantum fluctuation," and "potential interaction energy" to make it more interesting and align with the theme.

This contract will be an ERC-721 extension with significant custom logic. It will NOT be a direct copy of existing open-source implementations (like standard ERC721 extensions for simple features).

---

**Smart Contract: QuantumEntanglementNFT**

**Concept:** An ERC-721 contract where tokens are minted in entangled pairs. Actions performed on one token can influence the state of its entangled partner. Tokens have properties like 'charge', 'state' (boolean, like spin), and can be 'measured' to temporarily fix their state.

**Advanced/Creative Concepts:**
*   **Entangled State:** A direct, mapping-based link between two tokens where updates on one trigger updates on the other within the same transaction.
*   **Quantum-Inspired Mechanics:** Simulating concepts like state change, charge interaction, measurement (locking state), and collapse (random state assignment).
*   **Dynamic Properties:** Token properties (`charge`, `state`) are not static but change based on interactions.
*   **Interaction Energy:** A calculated property based on the combined state of an entangled pair.
*   **Simulated Fluctuation:** A public payable function allowing anyone to pay a fee to trigger a random state/charge perturbation on a pair.
*   **Resonance Cascade:** A specific, complex interaction triggered under certain conditions of charge and state difference.

**Outline:**

1.  **Contract Definition:** Inherits ERC721 and Ownable.
2.  **State Variables:**
    *   Token metadata (name, symbol).
    *   Mapping `tokenId => entangledTokenId`.
    *   Mapping `tokenId => charge (int256)`.
    *   Mapping `tokenId => state (bool)`.
    *   Mapping `tokenId => isMeasured (bool)`.
    *   Mapping `tokenId => measurementTimestamp (uint256)`.
    *   Mapping `tokenId => collapseCount (uint256)`.
    *   Next available token ID for minting.
    *   Measurement cooldown duration.
    *   Quantum fluctuation fee.
    *   Base URI for metadata.
3.  **Events:**
    *   `PairMinted`
    *   `StateChanged`
    *   `ChargeChanged`
    *   `EntanglementCollapse`
    *   `Measured`
    *   `Unmeasured`
    *   `FluctuationTriggered`
    *   `ResonanceCascadeTriggered`
    *   `PairBurned`
4.  **Constructor:** Initializes name, symbol, and base URI.
5.  **Modifiers:** `onlyEntangled`, `whenNotMeasured`.
6.  **Internal/Helper Functions:**
    *   `_safeMintPair`: Mints two tokens and sets up entanglement links and initial states.
    *   `_updateCharge`: Updates charge of a token and its entangled partner.
    *   `_updateState`: Updates state of a token and its entangled partner.
    *   `_isEntangled`: Checks if a token ID is part of an active pair.
    *   `_clearEntanglement`: Removes entanglement link for a pair.
    *   `_generatePseudoRandomNumber`: Helper for 'randomness'.
7.  **External/Public Functions (>= 20 total):**
    *   Admin functions (`onlyOwner`):
        *   `mintPair`: Mints a new entangled pair for specified owners.
        *   `batchMintPairs`: Mints multiple entangled pairs.
        *   `setMeasurementCooldown`: Sets duration measurement lasts.
        *   `setQuantumFluctuationFee`: Sets the fee for triggering fluctuation.
        *   `setBaseTokenURI`: Sets the base URI for metadata.
        *   `forceUnmeasurePair`: Owner can break measurement lock.
        *   `forceCollapsePair`: Owner can force a collapse.
    *   Token Interaction functions (require token owner):
        *   `changeState`: Toggles the state of a token and its partner (if not measured).
        *   `applyChargeDelta`: Adds/subtracts charge from a token, inversely affecting partner (if not measured).
        *   `collapseEntanglement`: Triggers a random state/charge collapse for the pair (if not measured).
        *   `measureState`: Locks the state/charge of the pair for a cooldown period.
        *   `unmeasureState`: Allows owner to voluntarily end measurement early.
        *   `burnPair`: Burns both tokens in an entangled pair.
        *   `triggerResonanceCascade`: Triggers a specific interaction under conditions (if not measured).
    *   Public Interaction function:
        *   `simulateQuantumFluctuation`: Anyone can pay a fee to trigger a small random change in the pair's state/charge.
    *   View functions:
        *   `getEntangledPartner`: Get the ID of the entangled partner.
        *   `getCharge`: Get the current charge of a token.
        *   `getState`: Get the current state (bool) of a token.
        *   `isMeasured`: Check if a token is currently measured.
        *   `getMeasurementTimestamp`: Get when measurement started.
        *   `getMeasurementCooldown`: Get the current cooldown duration.
        *   `canMeasure`: Check if a token is eligible to be measured (not currently measured).
        *   `getCollapseCount`: Get how many times a pair has collapsed.
        *   `getPotentialInteractionEnergy`: Calculate dynamic energy based on pair state/charge.
        *   `getTotalPairsMinted`: Get the total number of pairs created.
        *   `checkEntanglementStatus`: Checks if a token is currently linked to a valid partner.
    *   ERC721 Overrides:
        *   `tokenURI`: Generates metadata URI (points to external service aware of on-chain state).
        *   `_beforeTokenTransfer`: Custom logic before transfers (e.g., clears measurement).
        *   `_afterTokenTransfer`: Custom logic after transfers (e.g., minimal state shock).

**Function Summary:**

1.  `constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)`: Initializes the contract with name, symbol, and base metadata URI.
2.  `mintPair(address owner1, address owner2)`: (Owner Only) Mints a new entangled pair of tokens, assigning one to `owner1` and the other to `owner2`.
3.  `batchMintPairs(address[] calldata owner1s, address[] calldata owner2s)`: (Owner Only) Mints multiple entangled pairs in a single transaction.
4.  `setMeasurementCooldown(uint256 cooldown)`: (Owner Only) Sets the duration that `measureState` remains active.
5.  `setQuantumFluctuationFee(uint256 fee)`: (Owner Only) Sets the amount of Ether required to call `simulateQuantumFluctuation`.
6.  `setBaseTokenURI(string memory baseTokenURI_)`: (Owner Only) Sets the base URI used to construct token metadata URIs.
7.  `forceUnmeasurePair(uint256 tokenId)`: (Owner Only) Allows the owner to forcibly end the measurement state for a token pair.
8.  `forceCollapsePair(uint256 tokenId)`: (Owner Only) Allows the owner to forcibly trigger a state collapse for a token pair.
9.  `changeState(uint256 tokenId)`: (Token Owner Only, Not Measured) Toggles the boolean state of the specified token and its entangled partner.
10. `applyChargeDelta(uint256 tokenId, int256 delta)`: (Token Owner Only, Not Measured) Adds `delta` to the token's charge and applies a related change (e.g., `-delta/2`) to its entangled partner's charge.
11. `collapseEntanglement(uint256 tokenId)`: (Token Owner Only, Not Measured) Triggers a simulated 'collapse', assigning new pseudo-random states and charges to the token pair.
12. `measureState(uint256 tokenId)`: (Token Owner Only, Not Currently Measured) Locks the state and charge of the token pair for the defined `measurementCooldown` period.
13. `unmeasureState(uint256 tokenId)`: (Token Owner Only) Allows the owner to voluntarily end the measurement state for their token and its partner before the cooldown expires.
14. `burnPair(uint256 tokenId)`: (Token Owner Only) Burns the specified token and its entangled partner, permanently destroying both NFTs and clearing their entanglement link.
15. `triggerResonanceCascade(uint256 tokenId)`: (Token Owner Only, Not Measured) If specific conditions related to the pair's charge and state difference are met, triggers a significant, predefined change in their states and charges.
16. `simulateQuantumFluctuation(uint256 tokenId)`: (Public Payable) Allows anyone to pay the `quantumFluctuationFee` to introduce a small, random perturbation to the state or charge of a token pair, even if they don't own the tokens (unless measured). Fee is sent to the contract owner.
17. `getEntangledPartner(uint256 tokenId)`: (View) Returns the token ID of the entangled partner for the given token ID. Returns 0 if not entangled.
18. `getCharge(uint256 tokenId)`: (View) Returns the current charge of the specified token.
19. `getState(uint256 tokenId)`: (View) Returns the current boolean state of the specified token.
20. `isMeasured(uint256 tokenId)`: (View) Returns true if the specified token (and its partner) are currently under measurement.
21. `getMeasurementTimestamp(uint256 tokenId)`: (View) Returns the timestamp when the token was last measured. Returns 0 if never measured or currently not measured.
22. `getMeasurementCooldown()`: (View) Returns the currently set duration for measurement cooldown.
23. `canMeasure(uint256 tokenId)`: (View) Returns true if the token is not currently measured and its owner can initiate measurement.
24. `getCollapseCount(uint256 tokenId)`: (View) Returns the number of times the token's pair has undergone a state collapse.
25. `getPotentialInteractionEnergy(uint256 tokenId)`: (View) Calculates and returns a dynamic value representing the interaction energy of the entangled pair based on their current charges and states.
26. `getTotalPairsMinted()`: (View) Returns the total number of entangled pairs that have been minted by the contract.
27. `checkEntanglementStatus(uint256 tokenId)`: (View) Returns true if the token ID corresponds to a valid, existing token that is currently linked to another existing token as its entangled partner.
28. `tokenURI(uint256 tokenId)`: (View Override) Returns the metadata URI for the given token, constructed from the base URI and token ID. An external service must serve dynamic metadata based on the token's on-chain state (charge, state, measured, collapse count, partner ID).
29. `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: (Internal Override) Custom logic executed before a token transfer (e.g., clears measurement status).
30. `_afterTokenTransfer(address from, address to, uint256 tokenId)`: (Internal Override) Custom logic executed after a token transfer (e.g., applies minor state perturbation).

*(Note: Several standard ERC721 view functions like `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`, `totalSupply` are inherited and not listed individually above to reach the 20+ count, but they contribute to the overall functionality).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath explicitly for int256 charge logic clarity

/// @title QuantumEntanglementNFT
/// @dev An ERC-721 contract implementing concepts of quantum entanglement for token pairs.
///      Tokens are minted in pairs, and actions on one instantaneously affect its entangled partner.
///      Includes features like dynamic state/charge, measurement (state locking),
///      state collapse (randomization), and interaction energy.
contract QuantumEntanglementNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For standard uint256 ops if needed, ERC721 uses it implicitly.
    using SafeMath for int256; // Using SafeMath for int256 charge ops.

    // --- State Variables ---

    Counters.Counter private _tokenIds; // Counter for total tokens minted (pairs * 2)
    uint256 private _pairsMinted; // Counter for total pairs minted

    mapping(uint256 => uint256) private _entangledPair; // tokenId => entangledTokenId
    mapping(uint256 => int256) private _charge; // tokenId => charge (can be negative)
    mapping(uint256 => bool) private _state; // tokenId => boolean state (e.g., spin Up/Down)
    mapping(uint256 => bool) private _isMeasured; // tokenId => is state/charge temporarily fixed?
    mapping(uint256 => uint256) private _measurementTimestamp; // tokenId => timestamp when measured
    mapping(uint256 => uint256) private _collapseCount; // tokenId => how many times this pair collapsed

    uint256 public measurementCooldown = 1 days; // Duration measurement state lasts
    uint256 public quantumFluctuationFee = 0.01 ether; // Fee for simulating fluctuation

    string private _baseTokenURI; // Base URI for metadata service

    // --- Events ---

    event PairMinted(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner1, address indexed owner2);
    event StateChanged(uint256 indexed tokenId1, uint256 indexed tokenId2, bool newState1, bool newState2);
    event ChargeChanged(uint256 indexed tokenId1, uint256 indexed tokenId2, int256 newCharge1, int256 newCharge2);
    event EntanglementCollapse(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 collapseCount);
    event Measured(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 timestamp);
    event Unmeasured(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event FluctuationTriggered(uint256 indexed tokenId, uint256 indexed partnerId, address indexed by);
    event ResonanceCascadeTriggered(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairBurned(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed burnedBy);
    event MeasurementCooldownUpdated(uint256 newCooldown);
    event QuantumFluctuationFeeUpdated(uint256 newFee);
    event BaseTokenURIUpdated(string newURI);

    // --- Constructor ---

    /// @dev Initializes the contract.
    /// @param name_ The token collection name.
    /// @param symbol_ The token collection symbol.
    /// @param baseTokenURI_ The base URI for metadata.
    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
    }

    // --- Modifiers ---

    /// @dev Requires that the token is part of an active entangled pair.
    modifier onlyEntangled(uint256 tokenId) {
        require(_isEntangled(tokenId), "Token is not entangled");
        _;
    }

    /// @dev Requires that neither the token nor its partner are currently measured.
    modifier whenNotMeasured(uint256 tokenId) {
        require(!_isMeasured[tokenId], "Token is currently measured");
        _;
    }

    // --- Internal/Helper Functions ---

    /// @dev Mints a new entangled pair of tokens and sets initial state.
    function _safeMintPair(address owner1, address owner2) internal returns (uint256 tokenId1, uint256 tokenId2) {
        _tokenIds.increment();
        tokenId1 = _tokenIds.current();
        _safeMint(owner1, tokenId1);

        _tokenIds.increment();
        tokenId2 = _tokenIds.current();
        _safeMint(owner2, tokenId2);

        // Establish entanglement link
        _entangledPair[tokenId1] = tokenId2;
        _entangledPair[tokenId2] = tokenId1;

        // Initialize state and charge (e.g., random-ish initial state)
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId1, tokenId2)));
        _state[tokenId1] = (entropy % 2 == 0);
        _state[tokenId2] = (entropy % 3 == 0); // Slightly different initial probability
        _charge[tokenId1] = int256(int128(uint128(entropy % 100) - 50)); // Random charge between -50 and 50
        _charge[tokenId2] = int256(int128(uint128((entropy / 100) % 100) - 50));

        _pairsMinted++;

        emit PairMinted(tokenId1, tokenId2, owner1, owner2);
    }

    /// @dev Checks if a token ID is part of an active entangled pair.
    function _isEntangled(uint256 tokenId) internal view returns (bool) {
        uint256 partnerId = _entangledPair[tokenId];
        return partnerId != 0 && _exists(partnerId);
    }

    /// @dev Internal function to apply state change and propagate to partner.
    function _updateState(uint256 tokenId) internal {
        require(_isEntangled(tokenId), "Token is not entangled for state update");
        uint256 partnerId = _entangledPair[tokenId];

        // Toggle state
        _state[tokenId] = !_state[tokenId];
        // Entangled effect: Partner state also flips (simple example)
        _state[partnerId] = !_state[partnerId];

        emit StateChanged(tokenId, partnerId, _state[tokenId], _state[partnerId]);
    }

    /// @dev Internal function to apply charge delta and propagate inversely to partner.
    function _updateCharge(uint256 tokenId, int256 delta) internal {
         require(_isEntangled(tokenId), "Token is not entangled for charge update");
        uint256 partnerId = _entangledPair[tokenId];

        // Apply delta to the token
        _charge[tokenId] = _charge[tokenId].add(delta);

        // Entangled effect: Partner charge changes inversely, perhaps scaled
        int256 partnerDelta = -delta.div(2); // Half the inverse change
        _charge[partnerId] = _charge[partnerId].add(partnerDelta);

        emit ChargeChanged(tokenId, partnerId, _charge[tokenId], _charge[partnerId]);
    }

    /// @dev Clears the entanglement link between a pair.
    function _clearEntanglement(uint256 tokenId1, uint256 tokenId2) internal {
        delete _entangledPair[tokenId1];
        delete _entangledPair[tokenId2];
        // Optional: Clear other state relevant only to entanglement if needed
        delete _charge[tokenId1]; // Charge might only make sense when entangled
        delete _charge[tokenId2];
        delete _state[tokenId1]; // State might only make sense when entangled
        delete _state[tokenId2];
        delete _isMeasured[tokenId1]; // Clear measured status
        delete _isMeasured[tokenId2];
        delete _measurementTimestamp[tokenId1];
        delete _measurementTimestamp[tokenId2];
        delete _collapseCount[tokenId1]; // Collapse count is pair-specific
        delete _collapseCount[tokenId2];
    }

    /// @dev Simple pseudo-random number generator using block data and gas.
    ///      NOTE: Not truly random. Suitable for demonstration/game mechanics, NOT security critical.
    function _generatePseudoRandomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, gasleft(), seed, msg.sender)));
    }

    // --- Admin Functions (onlyOwner) ---

    /// @dev Mints a new entangled pair of tokens.
    /// @param owner1 Address of the first token's recipient.
    /// @param owner2 Address of the second token's recipient.
    function mintPair(address owner1, address owner2) external onlyOwner {
        require(owner1 != address(0) && owner2 != address(0), "Invalid recipient address");
        _safeMintPair(owner1, owner2);
    }

    /// @dev Mints multiple entangled pairs of tokens.
    /// @param owner1s Array of addresses for the first token of each pair.
    /// @param owner2s Array of addresses for the second token of each pair.
    function batchMintPairs(address[] calldata owner1s, address[] calldata owner2s) external onlyOwner {
        require(owner1s.length == owner2s.length, "Owner arrays must have same length");
        for (uint i = 0; i < owner1s.length; i++) {
            require(owner1s[i] != address(0) && owner2s[i] != address(0), "Invalid recipient address in batch");
            _safeMintPair(owner1s[i], owner2s[i]);
        }
    }

    /// @dev Sets the duration for the measurement cooldown period.
    /// @param cooldown The new cooldown duration in seconds.
    function setMeasurementCooldown(uint256 cooldown) external onlyOwner {
        measurementCooldown = cooldown;
        emit MeasurementCooldownUpdated(cooldown);
    }

    /// @dev Sets the fee required for triggering quantum fluctuation.
    /// @param fee The new fee amount in wei.
    function setQuantumFluctuationFee(uint256 fee) external onlyOwner {
        quantumFluctuationFee = fee;
        emit QuantumFluctuationFeeUpdated(fee);
    }

    /// @dev Sets the base URI for token metadata.
    /// @param baseTokenURI_ The new base URI string.
    function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        _baseTokenURI = baseTokenURI_;
        emit BaseTokenURIUpdated(baseTokenURI_);
    }

     /// @dev Allows the contract owner to force end the measurement state for a pair.
     /// @param tokenId Any token ID in the pair.
     function forceUnmeasurePair(uint256 tokenId) external onlyOwner onlyEntangled(tokenId) {
         uint256 partnerId = _entangledPair[tokenId];
         if (_isMeasured[tokenId]) {
             _isMeasured[tokenId] = false;
             _isMeasured[partnerId] = false;
             delete _measurementTimestamp[tokenId];
             delete _measurementTimestamp[partnerId];
             emit Unmeasured(tokenId, partnerId);
         }
     }

     /// @dev Allows the contract owner to force a state collapse for a pair.
     /// @param tokenId Any token ID in the pair.
     function forceCollapsePair(uint256 tokenId) external onlyOwner onlyEntangled(tokenId) whenNotMeasured(tokenId) {
         _collapseEntanglementInternal(tokenId); // Use internal logic
     }


    // --- Token Interaction Functions (require token owner, check measurement) ---

    /// @dev Toggles the state of the token and its entangled partner.
    /// @param tokenId The ID of the token to interact with.
    function changeState(uint256 tokenId) external onlyEntangled(tokenId) whenNotMeasured(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to change state");
        _updateState(tokenId);
    }

    /// @dev Applies a delta to the token's charge, affecting its partner.
    /// @param tokenId The ID of the token to interact with.
    /// @param delta The amount to add to the token's charge.
    function applyChargeDelta(uint256 tokenId, int256 delta) external onlyEntangled(tokenId) whenNotMeasured(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to apply charge delta");
        _updateCharge(tokenId, delta);
    }

    /// @dev Triggers a simulated state collapse for the entangled pair.
    /// @param tokenId The ID of any token in the pair.
    function collapseEntanglement(uint256 tokenId) external onlyEntangled(tokenId) whenNotMeasured(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to trigger collapse");
        _collapseEntanglementInternal(tokenId);
    }

    /// @dev Internal logic for collapse, usable by owner-only or token-owner functions.
    function _collapseEntanglementInternal(uint256 tokenId) internal {
        uint256 partnerId = _entangledPair[tokenId];
        uint256 seed = _generatePseudoRandomNumber(tokenId);

        // Assign new pseudo-random states
        _state[tokenId] = (seed % 2 == 0);
        _state[partnerId] = ((seed / 2) % 2 == 0);

        // Assign new pseudo-random charges (e.g., between -100 and 100)
        _charge[tokenId] = int256(int128(uint128(seed % 201) - 100));
        _charge[partnerId] = int256(int128(uint128((seed / 201) % 201) - 100));

        // Increment collapse count for both tokens in the pair
        _collapseCount[tokenId] = _collapseCount[tokenId].add(1);
        _collapseCount[partnerId] = _collapseCount[partnerId].add(1);

        emit EntanglementCollapse(tokenId, partnerId, _collapseCount[tokenId]);
    }

    /// @dev Measures the state of the token pair, locking their state/charge for a cooldown.
    /// @param tokenId The ID of any token in the pair.
    function measureState(uint256 tokenId) external onlyEntangled(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to measure");
        require(!_isMeasured[tokenId], "Token is already measured");
        // Check if cooldown has passed since last measurement ended (if applicable, simpler just check !isMeasured)
        // require(block.timestamp >= _measurementTimestamp[tokenId].add(measurementCooldown), "Measurement cooldown in effect"); // Alternative if tracking *end* time

        uint256 partnerId = _entangledPair[tokenId];

        _isMeasured[tokenId] = true;
        _isMeasured[partnerId] = true;
        _measurementTimestamp[tokenId] = block.timestamp;
        _measurementTimestamp[partnerId] = block.timestamp; // Apply timestamp to both

        emit Measured(tokenId, partnerId, block.timestamp);
    }

    /// @dev Allows the owner to unmeasure a token pair before the cooldown expires.
    /// @param tokenId The ID of any token in the pair.
    function unmeasureState(uint256 tokenId) external onlyEntangled(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to unmeasure");
        require(_isMeasured[tokenId], "Token is not currently measured");

        uint256 partnerId = _entangledPair[tokenId];

        _isMeasured[tokenId] = false;
        _isMeasured[partnerId] = false;
        // Keep timestamp for historical or cooldown checks if needed, or clear it:
        delete _measurementTimestamp[tokenId];
        delete _measurementTimestamp[partnerId];


        emit Unmeasured(tokenId, partnerId);
    }

    /// @dev Burns a token and its entangled partner.
    /// @param tokenId The ID of the token to burn.
    function burnPair(uint256 tokenId) external onlyEntangled(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to burn the pair");
        uint256 partnerId = _entangledPair[tokenId];

        address burner = msg.sender; // Record who initiated the burn

        // Clear entanglement *before* burning in case overrides check entanglement
        _clearEntanglement(tokenId, partnerId);

        _burn(tokenId);
        _burn(partnerId);

        emit PairBurned(tokenId, partnerId, burner);
    }

    /// @dev Triggers a specific Resonance Cascade if charge/state conditions are met.
    ///      Example condition: high charge difference and opposite states.
    /// @param tokenId The ID of any token in the pair.
    function triggerResonanceCascade(uint256 tokenId) external onlyEntangled(tokenId) whenNotMeasured(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Must own the token to trigger cascade");

        uint256 partnerId = _entangledPair[tokenId];

        int256 charge1 = _charge[tokenId];
        int256 charge2 = _charge[partnerId];
        bool state1 = _state[tokenId];
        bool state2 = _state[partnerId];

        // Define conditions for cascade (example conditions)
        bool highChargeDifference = (charge1.sub(charge2)).abs() > 150; // Example threshold
        bool oppositeStates = state1 != state2;

        require(highChargeDifference && oppositeStates, "Resonance Cascade conditions not met");

        // --- Cascade Effect (example) ---
        // Both states flip
        _state[tokenId] = !state1;
        _state[partnerId] = !state2;

        // Charges reset to a balanced state (or undergo a large shift)
        _charge[tokenId] = charge1.div(2); // Example: half the charge
        _charge[partnerId] = charge2.div(2);

        // Could add other effects or side effects here

        emit ResonanceCascadeTriggered(tokenId, partnerId);
        // StateChanged and ChargeChanged events are emitted by the internal _update functions
        // but since we modify directly here, we might re-emit or handle differently.
        // For this example, direct modification is fine, no _update calls needed for cascade.
        emit StateChanged(tokenId, partnerId, _state[tokenId], _state[partnerId]);
        emit ChargeChanged(tokenId, partnerId, _charge[tokenId], _charge[partnerId]);
    }


    // --- Public Interaction Function (Payable) ---

    /// @dev Allows anyone to pay a fee to simulate a random quantum fluctuation
    ///      that slightly alters the state or charge of a token pair.
    ///      The fee is sent to the contract owner.
    /// @param tokenId The ID of any token in the pair.
    function simulateQuantumFluctuation(uint256 tokenId) external payable onlyEntangled(tokenId) whenNotMeasured(tokenId) {
        require(msg.value >= quantumFluctuationFee, "Insufficient fluctuation fee");

        // Send fee to owner
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Fee transfer failed");

        uint256 partnerId = _entangledPair[tokenId];
        uint256 seed = _generatePseudoRandomNumber(tokenId + block.number); // Use block number as part of seed

        // --- Apply small random fluctuation ---
        if (seed % 5 == 0) { // 20% chance to flip state
             // Directly modify state without _updateState to avoid double events/logic in this specific fluctuation case
            _state[tokenId] = !_state[tokenId];
            _state[partnerId] = !_state[partnerId]; // Entangled flip
            emit StateChanged(tokenId, partnerId, _state[tokenId], _state[partnerId]);
        }

        if (seed % 3 != 0) { // ~66% chance to adjust charge
            int256 smallDelta = int256(int128(uint128((seed / 10) % 11) - 5)); // Random delta between -5 and 5
            _charge[tokenId] = _charge[tokenId].add(smallDelta);
             // Apply related delta to partner, perhaps smaller or inversed
            _charge[partnerId] = _charge[partnerId].add(-smallDelta.div(3)); // Small inverse scaled change
            emit ChargeChanged(tokenId, partnerId, _charge[tokenId], _charge[partnerId]);
        }

        emit FluctuationTriggered(tokenId, partnerId, msg.sender);
    }


    // --- View Functions ---

    /// @dev Returns the ID of the entangled partner for a given token ID.
    /// @param tokenId The ID of the token.
    /// @return The partner token ID, or 0 if not entangled or invalid.
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        return _entangledPair[tokenId];
    }

    /// @dev Returns the current charge of a token.
    /// @param tokenId The ID of the token.
    /// @return The token's charge (int256).
    function getCharge(uint256 tokenId) public view returns (int256) {
        return _charge[tokenId];
    }

    /// @dev Returns the current boolean state of a token.
    /// @param tokenId The ID of the token.
    /// @return The token's state (bool).
    function getState(uint256 tokenId) public view returns (bool) {
        return _state[tokenId];
    }

    /// @dev Checks if a token (and its partner) are currently under measurement.
    /// @param tokenId The ID of the token.
    /// @return True if measured, false otherwise.
    function isMeasured(uint256 tokenId) public view returns (bool) {
        // Check cooldown expiry if measured
        if (_isMeasured[tokenId]) {
            if (block.timestamp >= _measurementTimestamp[tokenId].add(measurementCooldown)) {
                 // State has expired, but cleanup isn't automatic.
                 // A user would need to call unmeasureState or an owner use forceUnmeasurePair.
                 // Or we can make this view function return false after expiry.
                 // Let's make the view function reflect the "effective" measured state:
                 return false; // Effectively no longer measured
            }
            return true; // Still within cooldown
        }
        return false;
    }

    /// @dev Returns the timestamp when the token was last measured.
    /// @param tokenId The ID of the token.
    /// @return Timestamp of measurement start, or 0.
    function getMeasurementTimestamp(uint256 tokenId) public view returns (uint256) {
        return _measurementTimestamp[tokenId];
    }

    /// @dev Returns the current measurement cooldown duration.
    function getMeasurementCooldown() public view returns (uint256) {
        return measurementCooldown;
    }

     /// @dev Checks if a token is eligible to be measured (not currently measured).
     /// @param tokenId The ID of the token.
     /// @return True if can measure, false otherwise.
    function canMeasure(uint256 tokenId) public view returns (bool) {
        // Calls the public `isMeasured` to get the effective status considering cooldown.
        return !isMeasured(tokenId);
    }


    /// @dev Returns how many times the token's pair has undergone a state collapse.
    /// @param tokenId The ID of the token.
    /// @return The collapse count for the pair.
    function getCollapseCount(uint256 tokenId) public view returns (uint256) {
        return _collapseCount[tokenId];
    }

    /// @dev Calculates the potential interaction energy of the entangled pair.
    ///      Example calculation: `charge1 * charge2 * (state1 == state2 ? 1 : -1)`
    /// @param tokenId The ID of any token in the pair.
    /// @return The calculated potential interaction energy.
    function getPotentialInteractionEnergy(uint256 tokenId) public view onlyEntangled(tokenId) returns (int256) {
        uint256 partnerId = _entangledPair[tokenId];
        int256 charge1 = _charge[tokenId];
        int256 charge2 = _charge[partnerId];
        bool state1 = _state[tokenId];
        bool state2 = _state[partnerId];

        int256 stateFactor = state1 == state2 ? 1 : -1;

        // Use SafeMath for multiplication
        int256 interactionEnergy = charge1.mul(charge2).mul(stateFactor);

        return interactionEnergy;
    }

    /// @dev Returns the total number of entangled pairs minted.
    function getTotalPairsMinted() public view returns (uint256) {
        return _pairsMinted;
    }

     /// @dev Checks if a token ID is valid and currently entangled with another existing token.
     /// @param tokenId The ID of the token.
     /// @return True if entangled with a valid partner, false otherwise.
    function checkEntanglementStatus(uint256 tokenId) public view returns (bool) {
        return _isEntangled(tokenId);
    }


    // --- ERC721 Overrides ---

    /// @dev See {ERC721-tokenURI}.
    ///      This function constructs the URI pointing to an external metadata service.
    ///      The service must retrieve the on-chain state (charge, state, measured, collapseCount, partnerId)
    ///      using the provided token ID and dynamically generate the JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Append token ID to base URI. The external service will fetch dynamic state.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // Add a trailing slash if it doesn't exist
        if (bytes(base)[bytes(base).length - 1] != '/') {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    ///      Custom logic before any token transfer. E.g., clears measurement status.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If the token is being transferred and is currently measured, clear the measurement state for the pair.
        // This ensures the state is "observed" upon transfer/change of ownership context.
        if (_isEntangled(tokenId) && _isMeasured[tokenId]) {
             uint256 partnerId = _entangledPair[tokenId];
             _isMeasured[tokenId] = false;
             _isMeasured[partnerId] = false;
             delete _measurementTimestamp[tokenId];
             delete _measurementTimestamp[partnerId];
             emit Unmeasured(tokenId, partnerId); // Emit event due to transfer-induced unmeasure
        }

        // Note: _burn is called internally by _beforeTokenTransfer when burning.
        // Our _clearEntanglement handles state cleanup when burning, so no extra logic needed here for burn case.
    }

    /// @dev See {ERC721-_afterTokenTransfer}.
    ///      Custom logic after any token transfer. E.g., apply minor state shock.
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._afterTokenTransfer(from, to, tokenId);

        // Example: Apply a minor state shock after a transfer, unless measured (though _before cleared measurement)
        // Re-checking !isMeasured here is belt-and-suspenders, but ensures this doesn't run if
        // forceUnmeasurePair was called in the same block *after* _before but *before* _after.
        if (_isEntangled(tokenId) && !_isMeasured[tokenId]) {
             uint256 partnerId = _entangledPair[tokenId];

             // Apply a tiny random charge fluctuation on the token that moved, affecting its partner.
             uint256 seed = _generatePseudoRandomNumber(tokenId + block.number + 1);
             int256 shockDelta = int256(int128(uint128((seed % 7)))); // Random delta between 0 and 6

            // Only apply the shock if delta is non-zero
            if (shockDelta != 0) {
                _charge[tokenId] = _charge[tokenId].add(shockDelta);
                _charge[partnerId] = _charge[partnerId].add(-shockDelta.div(2));
                // No StateChanged/ChargeChanged events here to distinguish from explicit function calls
                // but state mappings are updated. An alternative would be a specific 'TransferShock' event.
            }
        }
    }

    // The following standard ERC721 functions are inherited:
    // name(), symbol(), balanceOf(address owner), ownerOf(uint256 tokenId), approve(), getApproved(),
    // setApprovalForAll(), isApprovedForAll(), transferFrom(), safeTransferFrom().
    // totalSupply() (implicitly via _tokenIds.current() if needed, or override)

    // Override totalSupply for clarity (it's simply the counter)
    function totalSupply() public view override returns (uint256) {
        return _tokenIds.current();
    }

}
```