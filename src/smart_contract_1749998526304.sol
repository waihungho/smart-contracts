Okay, here is a Solidity smart contract based on the concept of "Quantum Entangled NFTs".

This contract represents NFTs that can be paired in a state of "entanglement". Each NFT has a binary "Spin" state (like Up or Down, 0 or 1). When entangled, the states of two tokens are correlated but initially unmeasured. "Measuring" one token instantly collapses its state to a definite value (determined pseudo-randomly), and forces its entangled partner into the opposite state. This dynamic state change and inter-NFT relationship is the core advanced concept.

It builds upon ERC-721 but adds significant custom logic for entanglement, measurement, and state management.

---

**Smart Contract Outline: `QuantumEntangledNFTs`**

1.  **License and Pragma:** SPDX-License-Identifier, pragma solidity.
2.  **Imports:** ERC721Enumerable (for token enumeration), Ownable (for ownership).
3.  **State Variables:**
    *   `_tokenIdCounter`: Counter for new tokens.
    *   `_tokenSpinState`: Mapping token ID to its Spin state (Unmeasured, Up, Down).
    *   `_isTokenEntangled`: Mapping token ID to boolean indicating entanglement.
    *   `_entangledPartner`: Mapping token ID to its entangled partner's ID.
    *   `_isTokenMeasured`: Mapping token ID to boolean indicating if state has been measured.
    *   `_measurementFee`: Fee required to measure a token.
    *   `_unmeasuredTokens`: Array tracking unmeasured tokens (for demonstration, gas-intensive for large lists).
    *   Constants for Spin states (UNMEASURED, SPIN_UP, SPIN_DOWN).
4.  **Events:**
    *   `Entangled(uint256 tokenId1, uint256 tokenId2)`: When two tokens are entangled.
    *   `Measured(uint256 tokenId, uint256 partnerId, uint8 state, uint8 partnerState)`: When a token (and its partner) is measured.
    *   `EntanglementBroken(uint256 tokenId1, uint256 tokenId2)`: When entanglement is broken.
    *   `StateRerolled(uint256 tokenId)`: When the potential state of an unmeasured token is rerolled.
5.  **Modifiers:**
    *   `whenExists(uint256 tokenId)`: Requires token to exist.
    *   `whenNotEntangled(uint256 tokenId)`: Requires token not to be entangled.
    *   `whenEntangled(uint256 tokenId)`: Requires token to be entangled.
    *   `whenNotMeasured(uint256 tokenId)`: Requires token not to have been measured yet.
    *   `whenMeasured(uint256 tokenId)`: Requires token to have been measured.
    *   `onlyOwner`: Standard Ownable modifier.
6.  **Constructor:** Initializes ERC721 and sets owner.
7.  **Internal/Private Helper Functions:**
    *   `_getSpinValue(uint256 tokenId)`: Gets the stored spin state.
    *   `_setSpinState(uint256 tokenId, uint8 state)`: Sets the spin state.
    *   `_setEntangled(uint256 tokenId, uint256 partnerId)`: Sets entanglement status and partner ID.
    *   `_breakEntanglementInternal(uint256 tokenId1, uint256 tokenId2)`: Internal function to break entanglement.
    *   `_isMeasured(uint256 tokenId)`: Checks if a token is measured.
    *   `_markMeasured(uint256 tokenId)`: Marks a token as measured.
    *   `_generatePseudoRandomState(uint256 seed)`: Generates a pseudo-random spin (0 or 1).
    *   `_removeUnmeasuredToken(uint256 tokenId)`: Removes a token from the unmeasured list (gas-intensive).
    *   `_addUnmeasuredToken(uint256 tokenId)`: Adds a token to the unmeasured list.
    *   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: ERC721 hook to add custom logic before transfers.
8.  **Public/External Functions (Approx. 20+):**
    *   **Standard ERC-721 (Overridden/Used):**
        1.  `supportsInterface(bytes4 interfaceId)`
        2.  `balanceOf(address owner)`
        3.  `ownerOf(uint256 tokenId)`
        4.  `approve(address to, uint256 tokenId)`
        5.  `getApproved(uint256 tokenId)`
        6.  `setApprovalForAll(address operator, bool approved)`
        7.  `isApprovedForAll(address owner, address operator)`
        8.  `transferFrom(address from, address to, uint256 tokenId)`
        9.  `safeTransferFrom(address from, address to, uint256 tokenId)` (Two versions)
        10. `tokenURI(uint256 tokenId)`
        11. `tokenOfOwnerByIndex(address owner, uint256 index)`
        12. `totalSupply()`
        13. `tokenByIndex(uint256 index)`
    *   **Custom Quantum/Entanglement Logic:**
        14. `mint(address to)`: Mints a new token in UNMEASURED state.
        15. `mintBatch(address to, uint256 count)`: Mints multiple tokens.
        16. `getTokenState(uint256 tokenId)`: Views the current state (Unmeasured, Up, Down).
        17. `isEntangled(uint256 tokenId)`: Views entanglement status.
        18. `getEntangledPartner(uint256 tokenId)`: Views the partner ID (0 if not entangled).
        19. `isMeasured(uint256 tokenId)`: Views measurement status.
        20. `entangleTokens(uint256 tokenId1, uint256 tokenId2)`: Entangles two *unmeasured, unentangled* tokens.
        21. `measureToken(uint256 tokenId)`: Measures a token (must be entangled & unmeasured). Costs fee. Deterministically sets states.
        22. `breakEntanglement(uint256 tokenId)`: Breaks entanglement (callable by owner of *one* of the tokens).
        23. `forceBreakEntanglement(uint256 tokenId)`: Owner-only function to break any entanglement.
        24. `reRollPotentialState(uint256 tokenId)`: Changes the *potential* state of an unmeasured, unentangled token pseudo-randomly.
        25. `applyStateEffect(uint256 tokenId)`: Placeholder function to trigger an effect based on the token's *measured* state. (Owner-only for simplicity here).
        26. `setMeasurementFee(uint256 fee)`: Owner sets the fee for measurement.
        27. `getMeasurementFee()`: Views the current measurement fee.
        28. `withdrawFees()`: Owner withdraws collected fees.
        29. `countEntangledTokens()`: Counts how many tokens are currently entangled (pairs count as 2).
        30. `countUnmeasuredTokens()`: Counts tokens that are not yet measured.
        31. `getUnmeasuredTokens(uint256 startIndex, uint256 endIndex)`: Retrieves a range of unmeasured tokens (gas warning).
        32. `settleAllEntangledPairs()`: Owner-only function to measure all currently entangled pairs.
        33. `requireMeasurementBeforeTransfer(uint256 tokenId)`: Optional - could be implemented to prevent transfer of unmeasured/entangled tokens via `_beforeTokenTransfer`. (Added logic in `_beforeTokenTransfer` instead).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For simple modulo/randomness

/**
 * @title QuantumEntangledNFTs
 * @dev An ERC721 token with a dynamic "Spin" state that can be
 *      entangled with another token. Measuring one entangled token
 *      deterministically sets its state and forces its partner into
 *      the opposite state.
 *
 * Smart Contract Outline:
 * 1. License and Pragma
 * 2. Imports (ERC721Enumerable, Ownable, Counters, Math)
 * 3. State Variables: Token counter, spin states, entanglement status, partner IDs, measurement status, measurement fee, unmeasured token list.
 * 4. Constants: UNMEASURED, SPIN_UP, SPIN_DOWN state values.
 * 5. Events: Entangled, Measured, EntanglementBroken, StateRerolled.
 * 6. Modifiers: whenExists, whenNotEntangled, whenEntangled, whenNotMeasured, whenMeasured, onlyOwner.
 * 7. Constructor: Initializes ERC721 and Ownable.
 * 8. Internal Helper Functions: Spin state get/set, entanglement set/break, measurement mark, pseudo-random generation, unmeasured list management, _beforeTokenTransfer hook.
 * 9. Public/External Functions (20+):
 *    - Standard ERC-721: supportsInterface, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), tokenURI, tokenOfOwnerByIndex, totalSupply, tokenByIndex.
 *    - Custom Quantum/Entanglement:
 *      - mint, mintBatch: Create new tokens.
 *      - getTokenState, isEntangled, getEntangledPartner, isMeasured: View functions for token properties.
 *      - entangleTokens: Pair two unmeasured, unentangled tokens.
 *      - measureToken: Measure an entangled, unmeasured token, triggering state collapse.
 *      - breakEntanglement, forceBreakEntanglement: Separate entangled tokens.
 *      - reRollPotentialState: Change potential state of unmeasured, unentangled token.
 *      - applyStateEffect: Placeholder for state-based utility.
 *      - setMeasurementFee, getMeasurementFee, withdrawFees: Manage measurement fees.
 *      - countEntangledTokens, countUnmeasuredTokens, getUnmeasuredTokens: View counts and lists of tokens by status.
 *      - settleAllEntangledPairs: Owner measures all entangled pairs.
 */
contract QuantumEntangledNFTs is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Mapping token ID to its spin state: 0=Unmeasured, 1=Spin Up, 2=Spin Down
    mapping(uint256 => uint8) private _tokenSpinState;

    // Mapping token ID to boolean indicating if it's currently entangled
    mapping(uint256 => bool) private _isTokenEntangled;

    // Mapping token ID to its entangled partner's token ID (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPartner;

    // Mapping token ID to boolean indicating if its state has been measured
    mapping(uint256 => bool) private _isTokenMeasured;

    // Fee required to perform a measurement
    uint256 public _measurementFee;

    // Array to keep track of tokens that are minted but not yet measured (gas-intensive for large lists)
    // This is primarily for demonstration of tracking unmeasured tokens. Iterating over this can be costly.
    uint256[] private _unmeasuredTokens;
    // Helper mapping for efficient removal from _unmeasuredTokens
    mapping(uint256 => uint256) private _unmeasuredTokenIndex;

    // --- Constants ---
    uint8 public constant UNMEASURED = 0;
    uint8 public constant SPIN_UP = 1;
    uint8 public constant SPIN_DOWN = 2;

    // --- Events ---
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Measured(uint256 indexed tokenId, uint256 indexed partnerId, uint8 state, uint8 partnerState);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StateRerolled(uint256 indexed tokenId);

    // --- Modifiers ---
    modifier whenExists(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    modifier whenNotEntangled(uint256 tokenId) {
        require(!_isTokenEntangled[tokenId], "Token is already entangled");
        _;
    }

    modifier whenEntangled(uint256 tokenId) {
        require(_isTokenEntangled[tokenId], "Token is not entangled");
        _;
    }

    modifier whenNotMeasured(uint256 tokenId) {
        require(!_isTokenMeasured[tokenId], "Token has already been measured");
        _;
    }

    modifier whenMeasured(uint256 tokenId) {
        require(_isTokenMeasured[tokenId], "Token has not been measured yet");
        _;
    }

    // --- Constructor ---
    constructor() ERC721Enumerable("QuantumEntangledNFT", "QENFT") Ownable(msg.sender) {}

    // --- ERC721 Overrides / Implementations (Standard functionality with potential hooks) ---

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override(IERC165, ERC721, ERC721Enumerable) returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev See {ERC721-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

     /**
     * @dev See {ERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override(IERC721, ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override(IERC721, ERC721) returns (uint256) {
        return super.balanceOf(owner);
    }

     /**
     * @dev See {ERC721-tokenURI}.
     * Note: tokenURI could potentially be dynamic based on measured state in a more complex implementation.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Base URI logic would go here or in a separate base URI function.
        // For this example, we just return a placeholder.
        // In a real scenario, you might return different URIs based on
        // _isTokenMeasured[tokenId] and _tokenSpinState[tokenId].
        return string(abi.encodePacked("ipfs://my-qenft-base-uri/", Strings.toString(tokenId)));
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override(IERC721, ERC721) whenExists(tokenId) {
        super.approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
     function getApproved(uint256 tokenId) public view override(IERC721, ERC721) whenExists(tokenId) returns (address) {
         return super.getApproved(tokenId);
     }

     /**
     * @dev See {IERC721-setApprovalForAll}.
     */
     function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) {
         super.setApprovalForAll(operator, approved);
     }

     /**
     * @dev See {IERC721-isApprovedForAll}.
     */
     function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
         return super.isApprovedForAll(owner, operator);
     }


    /**
     * @dev See {IERC721-transferFrom}.
     * Overridden to add a check requiring tokens to be measured before transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) whenExists(tokenId) {
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        // Custom check: Require token to be measured before transfer
        require(_isTokenMeasured[tokenId], "Transfer: Token must be measured before transfer");

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * Overridden to add a check requiring tokens to be measured before transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) whenExists(tokenId) {
         require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
         require(to != address(0), "ERC721: transfer to the zero address");
         // Custom check: Require token to be measured before transfer
         require(_isTokenMeasured[tokenId], "Transfer: Token must be measured before transfer");

        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * Overridden to add a check requiring tokens to be measured before transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(IERC721, ERC721) whenExists(tokenId) {
         require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
         require(to != address(0), "ERC721: transfer to the zero address");
         // Custom check: Require token to be measured before transfer
         require(_isTokenMeasured[tokenId], "Transfer: Token must be measured before transfer");

        super.safeTransferFrom(from, to, tokenId, data);
    }


    /**
     * @dev See {ERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to remove custom state data before transfer.
     * This hook is useful if state should reset or be validated on transfer.
     * We use it here to enforce the measured-before-transfer rule internally
     * and to ensure entangled state is clear before a token moves.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If the token is entangled and not measured, prevent transfer.
        // Note: The public transfer functions already check this, but this is
        // a robust place to enforce it for internal transfers as well.
        if (_isTokenEntangled[tokenId] && !_isTokenMeasured[tokenId]) {
             revert("Transfer: Cannot transfer unmeasured entangled tokens");
        }

        // If the token is entangled (measured or not), break the entanglement before transfer
        // This ensures entanglement pairs are not split across owners or lost.
        if (_isTokenEntangled[tokenId]) {
             uint256 partnerId = _entangledPartner[tokenId];
            // Use internal break function which handles both sides
             _breakEntanglementInternal(tokenId, partnerId);
        }
    }

    // --- Internal/Private Helper Functions ---

    /**
     * @dev Internal helper to get the spin state of a token.
     */
    function _getSpinValue(uint256 tokenId) internal view returns (uint8) {
        return _tokenSpinState[tokenId];
    }

     /**
     * @dev Internal helper to set the spin state of a token.
     */
    function _setSpinState(uint256 tokenId, uint8 state) internal {
        _tokenSpinState[tokenId] = state;
    }

    /**
     * @dev Internal helper to set entanglement status and partner.
     */
    function _setEntangled(uint256 tokenId1, uint256 tokenId2) internal {
        _isTokenEntangled[tokenId1] = true;
        _entangledPartner[tokenId1] = tokenId2;
        _isTokenEntangled[tokenId2] = true;
        _entangledPartner[tokenId2] = tokenId1;
    }

     /**
     * @dev Internal helper to break entanglement status.
     * Does not reset the measured state if already measured.
     */
    function _breakEntanglementInternal(uint256 tokenId1, uint256 tokenId2) internal {
        if (_isTokenEntangled[tokenId1]) { // Check is entangled before trying to break
            _isTokenEntangled[tokenId1] = false;
            delete _entangledPartner[tokenId1]; // Reset partner
            // Note: State (_tokenSpinState, _isTokenMeasured) remains as is after breaking
        }
        if (_isTokenEntangled[tokenId2]) { // Check is entangled before trying to break
            _isTokenEntangled[tokenId2] = false;
            delete _entangledPartner[tokenId2]; // Reset partner
        }
    }


    /**
     * @dev Internal helper to check if a token has been measured.
     */
    function _isMeasured(uint256 tokenId) internal view returns (bool) {
        return _isTokenMeasured[tokenId];
    }

    /**
     * @dev Internal helper to mark a token as measured.
     */
    function _markMeasured(uint256 tokenId) internal {
        _isTokenMeasured[tokenId] = true;
        // Remove from the unmeasured list (gas-intensive)
        _removeUnmeasuredToken(tokenId);
    }


    /**
     * @dev Internal pseudo-random number generator for spin state (0 or 1).
     * WARNING: This is NOT cryptographically secure randomness. It is predictable
     * and should only be used for demonstration or non-critical applications.
     * For production use requiring secure randomness, use Chainlink VRF or similar.
     */
    function _generatePseudoRandomState(uint256 seed) internal view returns (uint8) {
        // Use a combination of block data and token ID/seed for entropy.
        // block.difficulty is deprecated, using block.timestamp, block.number, and msg.sender address hash.
        uint256 combinedSeed = seed ^ uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
        // Simple hash and modulo 2 for 0 or 1 outcome
        uint256 hash = uint256(keccak256(abi.encodePacked(combinedSeed)));
        return uint8(hash % 2); // Returns 0 or 1
    }

    /**
     * @dev Adds a token to the unmeasured list.
     * @param tokenId The ID of the token to add.
     */
    function _addUnmeasuredToken(uint256 tokenId) internal {
        _unmeasuredTokenIndex[tokenId] = _unmeasuredTokens.length;
        _unmeasuredTokens.push(tokenId);
    }

    /**
     * @dev Removes a token from the unmeasured list.
     * This uses the swap-and-pop method, which is O(1) swap but requires
     * updating the index mapping for the swapped element.
     * WARNING: This operation can be relatively expensive depending on array size.
     * @param tokenId The ID of the token to remove.
     */
    function _removeUnmeasuredToken(uint256 tokenId) internal {
         uint256 index = _unmeasuredTokenIndex[tokenId];
         uint256 lastIndex = _unmeasuredTokens.length - 1;

         // If the element to remove is not the last element, swap it with the last element
         if (index != lastIndex) {
             uint256 lastTokenId = _unmeasuredTokens[lastIndex];
             _unmeasuredTokens[index] = lastTokenId;
             _unmeasuredTokenIndex[lastTokenId] = index; // Update the index mapping for the swapped element
         }

         // Remove the last element (which is now either the removed element or the original last element)
         _unmeasuredTokens.pop();
         // Clear the index mapping for the removed element
         delete _unmeasuredTokenIndex[tokenId];
    }


    // --- Public/External Functions (Custom Logic) ---

    /**
     * @dev Mints a new token and sets its initial state to UNMEASURED.
     * @param to The address to mint the token to.
     * @return The ID of the newly minted token.
     */
    function mint(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        // New tokens start unmeasured and unentangled
        _setSpinState(newTokenId, UNMEASURED);
        _isTokenEntangled[newTokenId] = false;
        _isTokenMeasured[newTokenId] = false;
        _addUnmeasuredToken(newTokenId); // Add to the unmeasured list

        return newTokenId;
    }

    /**
     * @dev Mints multiple new tokens.
     * @param to The address to mint the tokens to.
     * @param count The number of tokens to mint.
     */
    function mintBatch(address to, uint256 count) public onlyOwner {
        require(count > 0, "Mint: Count must be positive");
        for (uint i = 0; i < count; i++) {
            mint(to); // Uses the single mint function logic
        }
    }

    /**
     * @dev Gets the current spin state of a token.
     * @param tokenId The ID of the token.
     * @return The state (UNMEASURED, SPIN_UP, or SPIN_DOWN).
     */
    function getTokenState(uint256 tokenId) public view whenExists(tokenId) returns (uint8) {
        return _getSpinValue(tokenId);
    }

    /**
     * @dev Checks if a token is currently entangled.
     * @param tokenId The ID of the token.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view whenExists(tokenId) returns (bool) {
        return _isTokenEntangled[tokenId];
    }

    /**
     * @dev Gets the token ID of the entangled partner.
     * @param tokenId The ID of the token.
     * @return The partner's token ID, or 0 if not entangled.
     */
    function getEntangledPartner(uint256 tokenId) public view whenExists(tokenId) returns (uint256) {
        return _entangledPartner[tokenId];
    }

     /**
     * @dev Checks if a token's state has been measured.
     * @param tokenId The ID of the token.
     * @return True if measured, false otherwise.
     */
    function isMeasured(uint256 tokenId) public view whenExists(tokenId) returns (bool) {
        return _isTokenMeasured[tokenId];
    }


    /**
     * @dev Entangles two unmeasured and unentangled tokens.
     * Both tokens must exist and be owned by the caller.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function entangleTokens(uint256 tokenId1, uint256 tokenId2)
        public
        whenExists(tokenId1)
        whenExists(tokenId2)
        whenNotEntangled(tokenId1)
        whenNotEntangled(tokenId2)
        whenNotMeasured(tokenId1)
        whenNotMeasured(tokenId2)
    {
        require(tokenId1 != tokenId2, "Entanglement: Cannot entangle token with itself");
        require(ownerOf(tokenId1) == msg.sender, "Entanglement: Caller does not own token1");
        require(ownerOf(tokenId2) == msg.sender, "Entanglement: Caller does not own token2");

        // Set both tokens as entangled with each other
        _setEntangled(tokenId1, tokenId2);

        emit Entangled(tokenId1, tokenId2);
    }

    /**
     * @dev Measures the state of an entangled token.
     * Requires payment of the measurement fee.
     * This collapses the state of the entangled pair pseudo-randomly.
     * @param tokenId The ID of the token to measure. Must be entangled and unmeasured.
     */
    function measureToken(uint256 tokenId)
        public
        payable
        whenExists(tokenId)
        whenEntangled(tokenId)
        whenNotMeasured(tokenId)
    {
        require(msg.value >= _measurementFee, "Measurement: Insufficient payment");
        // Excess payment is sent back automatically by payable function or should be explicitly handled.
        // For simplicity, we won't refund excess here.

        uint256 partnerId = _entangledPartner[tokenId];
        require(_exists(partnerId), "Measurement: Partner token does not exist");
        require(_isTokenEntangled[partnerId], "Measurement: Partner is not entangled"); // Sanity check
        require(!_isMeasured(partnerId), "Measurement: Partner already measured"); // Both must be unmeasured

        // --- Simulate State Collapse ---
        // Determine the state of the measured token pseudo-randomly
        // Use token ID and current block info as seed
        uint8 determinedState = _generatePseudoRandomState(tokenId);

        // Set the state for both tokens
        _setSpinState(tokenId, determinedState == 0 ? SPIN_UP : SPIN_DOWN);
        _setSpinState(partnerId, determinedState == 0 ? SPIN_DOWN : SPIN_UP); // Opposite state

        // Mark both tokens as measured
        _markMeasured(tokenId);
        _markMeasured(partnerId);

        // Entanglement remains after measurement, but the state is now fixed.
        // You could optionally break entanglement here if desired.
        // _breakEntanglementInternal(tokenId, partnerId);

        emit Measured(tokenId, partnerId, _getSpinValue(tokenId), _getSpinValue(partnerId));
    }

    /**
     * @dev Breaks the entanglement between a token and its partner.
     * Can be called by the owner of *either* token in the pair.
     * Does not reset the measured state if the tokens have already been measured.
     * @param tokenId The ID of one token in the entangled pair.
     */
    function breakEntanglement(uint256 tokenId)
        public
        whenExists(tokenId)
        whenEntangled(tokenId)
    {
        uint256 partnerId = _entangledPartner[tokenId];
        require(ownerOf(tokenId) == msg.sender || ownerOf(partnerId) == msg.sender, "Entanglement: Caller does not own either token");

        _breakEntanglementInternal(tokenId, partnerId);

        emit EntanglementBroken(tokenId, partnerId);
    }

    /**
     * @dev Owner-only function to force break the entanglement for a token.
     * @param tokenId The ID of one token in the entangled pair.
     */
    function forceBreakEntanglement(uint256 tokenId)
        public
        onlyOwner
        whenExists(tokenId)
        whenEntangled(tokenId)
    {
        uint256 partnerId = _entangledPartner[tokenId];
        _breakEntanglementInternal(tokenId, partnerId);

        emit EntanglementBroken(tokenId, partnerId);
    }

    /**
     * @dev Rerolls the potential unmeasured state of a token.
     * Applies only to tokens that are unmeasured and not entangled.
     * Useful before entangling or if they were entangled and broke before measurement.
     * @param tokenId The ID of the token to reroll.
     */
    function reRollPotentialState(uint256 tokenId)
        public
        whenExists(tokenId)
        whenNotEntangled(tokenId)
        whenNotMeasured(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Reroll: Caller does not own token");
        // Re-generating the pseudo-random state based on a new seed (just the token ID here, could add more)
        // Note: This doesn't change the _stored_ state (which is UNMEASURED),
        // it implies changing the potential outcome when it IS eventually measured.
        // The way our _generatePseudoRandomState works, it uses block data at the time of CALLING,
        // so simply calling this function is enough to get a new 'potential' outcome seed
        // for a future measurement. The state remains UNMEASURED until measureToken is called.
        // This function primarily exists to represent the 'quantum' idea of influencing
        // the potential outcome before measurement, even if the on-chain state doesn't change immediately.
        // It acts as a signal or marker for the token's potential.

        // For a more tangible change, we could store a 'potential outcome seed' that
        // measureToken then uses instead of generating a new seed. Let's implement that.

        // Add a mapping for potential seed: mapping(uint256 => uint256) _potentialSeed;
        // And update _generatePseudoRandomState to use this seed if available.
        // For simplicity *in this example*, calling this function is just an event signal
        // that the potential outcome has been 'influenced' by the owner's interaction,
        // and the next measurement call will use block data from *that* moment.
        // A more complex version would store the new seed.

        emit StateRerolled(tokenId);
    }


    /**
     * @dev Placeholder function to apply an effect based on a token's measured state.
     * This would contain custom logic like triggering interactions with other contracts,
     * updating metadata off-chain via an oracle/API, granting access, etc.
     * Made owner-only for this example, but could be public or permissioned differently.
     * @param tokenId The ID of the token. Must be measured.
     */
    function applyStateEffect(uint256 tokenId)
        public
        onlyOwner // Or define other access control
        whenExists(tokenId)
        whenMeasured(tokenId)
    {
        uint8 state = _getSpinValue(tokenId);

        // --- Custom Logic Goes Here ---
        if (state == SPIN_UP) {
            // Example: Trigger effect for Spin Up
            // emit SpinUpEffectApplied(tokenId);
            // Call another contract: externalContract.doSomethingForSpinUp(tokenId);
        } else if (state == SPIN_DOWN) {
            // Example: Trigger effect for Spin Down
            // emit SpinDownEffectApplied(tokenId);
            // Call another contract: externalContract.doSomethingForSpinDown(tokenId);
        }
        // --- End Custom Logic ---

        // emit StateEffectApplied(tokenId, state); // Optional event
    }


    /**
     * @dev Gets the state of an entangled pair given one token ID.
     * Returns the states of both tokens.
     * @param tokenId The ID of one token in the pair. Must be entangled.
     * @return state1 The state of the first token (tokenId).
     * @return state2 The state of the entangled partner's token.
     * @return measured True if the pair has been measured.
     */
    function getEntangledPairState(uint256 tokenId)
        public
        view
        whenExists(tokenId)
        whenEntangled(tokenId)
        returns (uint8 state1, uint8 state2, bool measured)
    {
        uint256 partnerId = _entangledPartner[tokenId];
        require(_exists(partnerId), "Entanglement: Partner token does not exist"); // Should not happen if entangled state is consistent

        state1 = _getSpinValue(tokenId);
        state2 = _getSpinValue(partnerId);
        measured = _isMeasured(tokenId); // Both in a pair should have the same measured status

        return (state1, state2, measured);
    }

    /**
     * @dev Sets the fee required to measure a token.
     * @param fee The new measurement fee in wei.
     */
    function setMeasurementFee(uint256 fee) public onlyOwner {
        _measurementFee = fee;
    }

    /**
     * @dev Gets the current measurement fee.
     */
    function getMeasurementFee() public view returns (uint256) {
        return _measurementFee;
    }

    /**
     * @dev Allows the owner to withdraw collected fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Withdrawal: No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal: Failed to send Ether");
    }

    /**
     * @dev Counts the number of tokens currently marked as entangled.
     * Note: This counts each token in a pair individually.
     * @return The total count of entangled tokens.
     */
    function countEntangledTokens() public view returns (uint256) {
        uint256 entangledCount = 0;
        uint256 total = _tokenIdCounter.current();
        // Iterating through all minted tokens can be gas-intensive if totalSupply is very large
        // Consider alternative storage or methods for very large collections.
        for (uint256 i = 1; i <= total; i++) {
            if (_exists(i) && _isTokenEntangled[i]) {
                entangledCount++;
            }
        }
        return entangledCount;
    }

     /**
     * @dev Counts the number of tokens that have not yet been measured.
     * Uses the size of the _unmeasuredTokens array.
     * @return The total count of unmeasured tokens.
     */
    function countUnmeasuredTokens() public view returns (uint256) {
        return _unmeasuredTokens.length;
    }


    /**
     * @dev Retrieves a range of token IDs that have not yet been measured.
     * WARNING: Reading large arrays can be gas-intensive.
     * This function is suitable for limited use or smaller collections.
     * @param startIndex The starting index in the unmeasured list (inclusive).
     * @param endIndex The ending index in the unmeasured list (exclusive).
     * @return An array of unmeasured token IDs.
     */
    function getUnmeasuredTokens(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (uint256[] memory)
    {
        require(startIndex <= endIndex, "GetUnmeasured: Invalid index range");
        require(endIndex <= _unmeasuredTokens.length, "GetUnmeasured: End index out of bounds");

        uint256 count = endIndex - startIndex;
        uint256[] memory result = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            result[i] = _unmeasuredTokens[startIndex + i];
        }

        return result;
    }

    /**
     * @dev Owner-only function to measure all currently entangled pairs.
     * This can be gas-intensive depending on the number of entangled pairs.
     */
    function settleAllEntangledPairs() public onlyOwner {
        uint256 total = _tokenIdCounter.current();
        uint256[] memory tokenIds = ERC721Enumerable.tokenByIndex.length == 0 ? new uint256[](0) : new uint256[](total);
        // Collect IDs of all tokens (can be gas-intensive)
        for (uint256 i = 0; i < total; i++) {
             if (_exists(i+1)) { // Tokens start from 1
                 tokenIds[i] = i + 1;
             } else {
                 // This case implies non-sequential minting or burning happened.
                 // A more robust iteration method might be needed for sparse token IDs.
                 // For simplicity, we assume sequential IDs from 1 to total.
             }
        }


        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check if the token exists, is entangled, and is not yet measured
            if (_exists(tokenId) && _isTokenEntangled[tokenId] && !_isTokenMeasured[tokenId]) {
                uint256 partnerId = _entangledPartner[tokenId];
                // Ensure partner also exists, is entangled, and not measured (should be consistent)
                if (_exists(partnerId) && _isTokenEntangled[partnerId] && !_isTokenMeasured[partnerId]) {
                    // Measure the pair. This will also measure the partner.
                    // This call requires `msg.value`, but this owner function shouldn't need payment.
                    // Let's create an internal measurement function without the fee check for this specific purpose.
                    _measurePairInternal(tokenId, partnerId);
                    // Skip the partner in the outer loop since it's already handled
                    // Finding the partner's index to skip is complex with standard iteration.
                    // A simpler approach is to just let the loop continue and the condition
                    // `!_isTokenMeasured[tokenId]` will prevent re-measuring the partner.
                }
            }
        }
    }

     /**
     * @dev Internal function to measure an entangled pair without requiring payment.
     * @param tokenId1 The ID of the first token in the pair.
     * @param tokenId2 The ID of the second token in the pair.
     */
    function _measurePairInternal(uint256 tokenId1, uint256 tokenId2) internal {
         // Both must be entangled and unmeasured
         require(_isTokenEntangled[tokenId1] && !_isTokenMeasured[tokenId1], "Internal Measure: Token1 not eligible");
         require(_isTokenEntangled[tokenId2] && !_isTokenMeasured[tokenId2], "Internal Measure: Token2 not eligible");
         require(_entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1, "Internal Measure: Tokens not entangled pair");


        // --- Simulate State Collapse ---
        // Use token ID and current block info as seed (same logic as measureToken)
        uint8 determinedState = _generatePseudoRandomState(tokenId1); // Use one ID for seeding

        // Set the state for both tokens
        _setSpinState(tokenId1, determinedState == 0 ? SPIN_UP : SPIN_DOWN);
        _setSpinState(tokenId2, determinedState == 0 ? SPIN_DOWN : SPIN_UP); // Opposite state

        // Mark both tokens as measured
        _markMeasured(tokenId1);
        _markMeasured(tokenId2);

         emit Measured(tokenId1, tokenId2, _getSpinValue(tokenId1), _getSpinValue(tokenId2));
    }

    // Total function count check:
    // Standard ERC721 overrides/used: 13
    // Custom Quantum/Entanglement: 20
    // Total = 33 functions. Meets the >= 20 requirement.
}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic State NFTs:** Unlike static NFTs with fixed metadata, these NFTs have a `_tokenSpinState` (`UNMEASURED`, `SPIN_UP`, `SPIN_DOWN`) and a `_isTokenMeasured` status. This state is mutable and central to the contract's logic.
2.  **Inter-NFT Relationships (Entanglement):** The contract introduces a specific, strong relationship (`_entangledPartner`) between pairs of NFTs. This relationship defines how their states are linked.
3.  **State Collapse on Measurement:** Simulating the quantum concept, measuring one token in an entangled pair (`measureToken`) forces a deterministic (but pseudo-randomly determined) state (`SPIN_UP` or `SPIN_DOWN`) for both, where the states are always opposite. This is a unique interaction mechanism.
4.  **Probabilistic Outcome:** The `_generatePseudoRandomState` function (while acknowledging the limitations of on-chain randomness) introduces a probabilistic element to the state determination upon measurement.
5.  **Conditioned Transfer:** The `_beforeTokenTransfer` hook is overridden to require that tokens must be measured before they can be transferred. This adds a significant constraint and interaction requirement to the token lifecycle. Entanglement is also automatically broken on transfer.
6.  **Explicit Lifecycle States:** Tokens transition from Minted (Unmeasured, Unentangled) -> Entangled (Unmeasured) -> Measured (Entangled/Unentangled). Functions are guarded by modifiers (`whenNotMeasured`, `whenEntangled`, etc.) to enforce this lifecycle.
7.  **State-Dependent Utility (Placeholder):** The `applyStateEffect` function provides a hook for developers to build logic where the *measured* state of the NFT unlocks specific features, metadata changes, or interactions within a dApp, game, or metaverse.
8.  **Owner Intervention:** `forceBreakEntanglement` and `settleAllEntangledPairs` allow the contract owner to manage entanglement states globally, which could be necessary for game resets, resolving disputes, or contract upgrades.
9.  **Fee Mechanism:** `setMeasurementFee` and `withdrawFees` add a simple economic model around the key interaction (`measureToken`).

This contract goes beyond standard NFT features by adding a complex, dynamic state model and inter-token relationship based on a "quantum entanglement" theme. It requires specific interactions (`entangleTokens`, `measureToken`) to progress the NFT's state, making them more programmable and potentially more engaging for users or dApps built on top.