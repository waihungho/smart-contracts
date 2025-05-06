Okay, this is an exciting challenge! We'll create a smart contract for NFTs that have "Quantum" inspired properties: **Entanglement**, **Superposition**, and **Decay**.

These aren't real quantum physics, of course, but analogies implemented on the blockchain to create interesting mechanics:

1.  **Entanglement:** Two NFTs can be linked. Actions on one *might* affect the other (in a defined way).
2.  **Superposition:** An NFT can enter a state where some properties are *unknown* until an "Observation" (a transaction) collapses it into a single determined state using on-chain "randomness".
3.  **Decay:** Certain properties of an NFT can degrade over time unless "Re-energized".

Let's call it `QuantumEntangledNFTs`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath explicitly for clarity in calculations though 0.8+ has checks

// --- OUTLINE ---
// 1. Contract Definition & Imports
// 2. State Variables & Data Structures
//    - ERC721 state, Ownable state
//    - Token Counter
//    - Enum for Quantum State (Normal, Entangled, Superposition)
//    - Struct for Token Properties (inspired by quantum concepts)
//    - Mappings for token state, properties (collapsed), entanglement, superposition seed, decay timestamp
//    - Configuration variables (costs, rates, URI)
// 3. Events
//    - Custom events for state changes (Entangle, BreakEntanglement, Superposition, Collapse, ReEnergize)
//    - Standard ERC721 events
// 4. Modifiers (Optional but good practice for access/state checks)
// 5. Constructor
// 6. ERC721 Standard Functions (Implemented via inheritance and overriding where needed)
//    - balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom
//    - supportsInterface
//    - tokenURI (Overridden to reflect state/properties)
//    - tokenByIndex, tokenOfOwnerByIndex (from ERC721Enumerable)
// 7. Custom Core Quantum Functions
//    - mintQuantumToken: Mints a new token, assigns initial state/properties.
//    - entangleTokens: Links two tokens, changes state to Entangled.
//    - breakEntanglement: Unlinks two entangled tokens, changes state back to Normal.
//    - enterSuperposition: Puts a token into a state of potential properties.
//    - collapseSuperposition: Determines final properties from superposition using randomness.
//    - reEnergize: Resets the decay timer for a token.
// 8. Query Functions (Read-only)
//    - getTokenState: Get current quantum state.
//    - getTokenProperties: Get fixed properties (after collapse).
//    - getSuperpositionProperties: Get potential/seed properties while in superposition.
//    - isEntangled: Check if a token is entangled.
//    - getEntangledPair: Get the token ID of the entangled pair.
//    - isInSuperposition: Check if a token is in superposition.
//    - checkDecayStatus: Calculate the current decayed value of a property.
//    - getDecayRate: Get the configured decay rate.
//    - getEntanglementTimestamp: When was entanglement initiated.
//    - getSuperpositionTimestamp: When did it enter superposition.
//    - getLastReEnergizedTimestamp: When was decay last reset.
// 9. Admin/Configuration Functions (Ownable)
//    - setBaseURI: Set the base for token metadata URIs.
//    - setEntanglementCost: Set the cost to entangle tokens.
//    - setReEnergizeCost: Set the cost to re-energize.
//    - setDecayRate: Set the rate at which properties decay.
//    - toggleEntanglementEligibility: Allow/disallow specific tokens from being entangled initially.
// 10. Internal Helper Functions
//    - _calculateDecay: Calculates current decay based on time and rate.
//    - _derivePropertiesFromSeed: Deterministically generates properties from a seed and block data.
//    - _validateEntanglementEligibility: Checks if two tokens meet custom criteria for entanglement.

// --- FUNCTION SUMMARY ---
// 1. balanceOf(address owner): Returns the number of tokens owned by `owner`. (ERC721 Standard)
// 2. ownerOf(uint256 tokenId): Returns the owner of the `tokenId`. (ERC721 Standard)
// 3. approve(address to, uint256 tokenId): Gives permission to `to` to transfer `tokenId`. (ERC721 Standard)
// 4. getApproved(uint256 tokenId): Returns the approved address for `tokenId`. (ERC721 Standard)
// 5. setApprovalForAll(address operator, bool approved): Approves or revokes operator for all tokens. (ERC721 Standard)
// 6. isApprovedForAll(address owner, address operator): Checks if operator is approved for all tokens of owner. (ERC721 Standard)
// 7. transferFrom(address from, address to, uint256 tokenId): Transfers `tokenId` from `from` to `to`. (ERC721 Standard)
// 8. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers `tokenId`. (ERC721 Standard)
// 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfers `tokenId` with data. (ERC721 Standard)
// 10. supportsInterface(bytes4 interfaceId): ERC165 standard interface check. (ERC721 Standard)
// 11. tokenURI(uint256 tokenId): Returns the metadata URI for `tokenId`, reflecting state/properties. (ERC721 Standard, Overridden)
// 12. tokenByIndex(uint256 index): Returns the token ID at `index` in the global token list. (ERC721Enumerable)
// 13. tokenOfOwnerByIndex(address owner, uint256 index): Returns the token ID at `index` for owner. (ERC721Enumerable)
// 14. mintQuantumToken(address to, uint256 initialEnergy, uint256 initialCoherence, bool canEntangle): Mints a new NFT with specified initial properties and entanglement eligibility.
// 15. entangleTokens(uint256 tokenIdA, uint256 tokenIdB): Links two eligible NFTs, requiring payment.
// 16. breakEntanglement(uint256 tokenId): Breaks the entanglement of `tokenId` and its pair.
// 17. enterSuperposition(uint256 tokenId): Moves an NFT into a superposition state, clearing current properties.
// 18. collapseSuperposition(uint256 tokenId): Resolves the superposition state into fixed properties using blockchain data for randomness.
// 19. reEnergize(uint256 tokenId): Resets the decay timer for an NFT's energy level, requiring payment.
// 20. getTokenState(uint256 tokenId): Returns the current quantum state (Normal, Entangled, Superposition).
// 21. getTokenProperties(uint256 tokenId): Returns the *fixed* properties of the token (after collapse).
// 22. getSuperpositionProperties(uint256 tokenId): Returns the properties *seed* for a token in superposition (not the resolved properties).
// 23. isEntangled(uint256 tokenId): Checks if the token is currently entangled.
// 24. getEntangledPair(uint256 tokenId): Returns the token ID of the entangled pair, or 0 if not entangled.
// 25. isInSuperposition(uint256 tokenId): Checks if the token is currently in superposition.
// 26. checkDecayStatus(uint256 tokenId): Calculates the current effective energy level considering decay.
// 27. getDecayRate(): Returns the configured decay rate (energy units per second).
// 28. getEntanglementTimestamp(uint256 tokenId): Returns the timestamp when entanglement started.
// 29. getSuperpositionTimestamp(uint256 tokenId): Returns the timestamp when superposition started.
// 30. getLastReEnergizedTimestamp(uint256 tokenId): Returns the timestamp when the token was last re-energized.
// 31. setBaseURI(string memory baseURI): (Admin) Sets the base URI for token metadata.
// 32. setEntanglementCost(uint256 cost): (Admin) Sets the cost (in Wei) to entangle tokens.
// 33. setReEnergizeCost(uint256 cost): (Admin) Sets the cost (in Wei) to re-energize a token.
// 34. setDecayRate(uint256 rate): (Admin) Sets the decay rate (energy units per second).
// 35. toggleEntanglementEligibility(uint256 tokenId, bool eligible): (Admin) Manually set entanglement eligibility for a token.

contract QuantumEntangledNFTs is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Use SafeMath for decay calculations

    Counters.Counter private _tokenIdCounter;

    // --- State Variables & Data Structures ---

    enum QuantumState { Normal, Entangled, Superposition }

    struct TokenProperties {
        uint256 energyLevel;     // Can decay
        uint256 coherenceFactor; // Fixed after collapse
        bytes32 spinState;       // Fixed after collapse, abstract binary-like property
        uint256 colorValue;      // Fixed after collapse, abstract property
    }

    // Mapping from token ID to its current quantum state
    mapping(uint256 => QuantumState) private _tokenState;

    // Mapping from token ID to its fixed properties (after superposition collapse)
    mapping(uint256 => TokenProperties) private _tokenProperties;

    // Mapping for entanglement: tokenId => entangled tokenId (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPair;
    // Mapping to track when entanglement occurred
    mapping(uint256 => uint256) private _entanglementTimestamp;

    // Mapping for superposition: tokenId => seed used for collapse
    mapping(uint256 => bytes32) private _superpositionSeed;
    // Mapping to track when superposition started
    mapping(uint256 => uint256) private _superpositionTimestamp;

    // Mapping for decay: tokenId => timestamp of last re-energize
    mapping(uint256 => uint255) private _lastReEnergizedTimestamp; // Using uint255 to save slot if possible, though timestamp fits uint256

    // Mapping to track initial entanglement eligibility
    mapping(uint256 => bool) private _canEntangleInitially;

    // Configuration variables
    string private _baseTokenURI;
    uint256 private _entanglementCost = 0.01 ether; // Cost in Wei
    uint256 private _reEnergizeCost = 0.005 ether;  // Cost in Wei
    uint256 private _decayRatePerSecond = 1;      // Energy units lost per second

    // --- Events ---

    event Entangled(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 timestamp);
    event BreakEntanglement(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 timestamp);
    event EnteredSuperposition(uint256 indexed tokenId, bytes32 seed, uint256 timestamp);
    event CollapsedSuperposition(uint256 indexed tokenId, TokenProperties finalProperties, uint256 timestamp);
    event ReEnergized(uint256 indexed tokenId, uint256 timestamp);
    // Standard ERC721 events are inherited/emitted by the base contracts

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
    {
        // Initial configurations can be set here or via admin functions
    }

    // --- ERC721 Standard Overrides ---

    // Required by ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(ERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // Required by ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        // Custom logic before transfer if needed (e.g., cannot transfer if entangled)
        // Let's add a check: Entangled tokens cannot be transferred unless explicitly allowed (e.g., via a specific 'transferEntangledPair' function, which we won't implement to keep focus, but the check remains)
        // For simplicity, we'll just revert if entangled. A real use case might allow only the owner of *both* to transfer the pair.
        require(_tokenState[tokenId] != QuantumState.Entangled, "QENFT: Cannot transfer entangled token");

        return super._update(to, tokenId, auth);
    }

    // Required by ERC721Enumerable
    function _increaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    // Required by ERC721Enumerable
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // Before burning, ensure it's not entangled or in superposition
        require(_tokenState[tokenId] == QuantumState.Normal, "QENFT: Cannot burn token in special state");
        super._burn(tokenId);
        // Clean up state data associated with the burnt token
        delete _tokenState[tokenId];
        delete _tokenProperties[tokenId];
        delete _superpositionSeed[tokenId];
        delete _superpositionTimestamp[tokenId];
        delete _lastReEnergizedTimestamp[tokenId];
        delete _canEntangleInitially[tokenId];
        // Note: If entanglement could persist through burn (unlikely), need to handle paired token.
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(tokenId); // Ensure token exists

        // Basic URI structure, a real contract would fetch complex metadata
        string memory base = _baseTokenURI;
        string memory currentId = Strings.toString(tokenId);
        string memory state;

        // Append state to URI for dynamic metadata retrieval
        QuantumState currentState = _tokenState[tokenId];
        if (currentState == QuantumState.Normal) {
            state = "/normal";
        } else if (currentState == QuantumState.Entangled) {
             state = "/entangled";
        } else if (currentState == QuantumState.Superposition) {
             state = "/superposition";
        } else {
             state = "/unknown"; // Should not happen
        }

        // A real implementation would probably use a dedicated metadata service (off-chain)
        // and pass token ID and potentially state/properties as query parameters.
        // This on-chain implementation just gives a simple path structure example.
        if (bytes(base).length > 0) {
             return string(abi.encodePacked(base, currentId, state));
        } else {
            // Fallback or revert if base URI not set
            return ""; // Or revert("Base URI not set");
        }
    }


    // --- Custom Core Quantum Functions ---

    /**
     * @notice Mints a new Quantum NFT.
     * @param to The address that will own the new token.
     * @param initialEnergy The starting energy level for the token (subject to decay).
     * @param initialCoherence The starting coherence factor (fixed property).
     * @param canEntangle Whether this token is initially eligible for entanglement.
     */
    function mintQuantumToken(address to, uint256 initialEnergy, uint256 initialCoherence, bool canEntangle)
        public onlyOwner
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(to, newTokenId);

        // Set initial state and properties
        _tokenState[newTokenId] = QuantumState.Normal;
        _tokenProperties[newTokenId] = TokenProperties({
            energyLevel: initialEnergy,
            coherenceFactor: initialCoherence,
            spinState: bytes32(0), // Initially unset, will be determined on collapse
            colorValue: 0         // Initially unset, will be determined on collapse
        });
        _lastReEnergizedTimestamp[newTokenId] = uint255(block.timestamp); // Set initial re-energize time
        _canEntangleInitially[newTokenId] = canEntangle;

        // SpinState and ColorValue are meant to be fixed upon collapse, not mint.
        // Let's ensure they are zeroed here. The initialEnergy/Coherence are starting points.
        _tokenProperties[newTokenId].spinState = bytes32(0);
        _tokenProperties[newTokenId].colorValue = 0;


        return newTokenId;
    }

    /**
     * @notice Attempts to entangle two eligible tokens owned by the caller or approved.
     * @dev Requires payment of entanglementCost. Both tokens must be in Normal state.
     * @param tokenIdA The ID of the first token.
     * @param tokenIdB The ID of the second token.
     */
    function entangleTokens(uint256 tokenIdA, uint256 tokenIdB) public payable {
        require(tokenIdA != tokenIdB, "QENFT: Cannot entangle a token with itself");
        require(msg.value >= _entanglementCost, "QENFT: Insufficient funds for entanglement");

        address ownerA = ownerOf(tokenIdA);
        address ownerB = ownerOf(tokenIdB);

        // Ensure caller has permission for both tokens
        require(ownerA == _msgSender() || getApproved(tokenIdA) == _msgSender() || isApprovedForAll(ownerA, _msgSender()),
            "QENFT: Caller not authorized for token A");
         require(ownerB == _msgSender() || getApproved(tokenIdB) == _msgSender() || isApprovedForAll(ownerB, _msgSender()),
            "QENFT: Caller not authorized for token B");

        // Ensure both tokens are in Normal state and eligible
        require(_tokenState[tokenIdA] == QuantumState.Normal, "QENFT: Token A is not in Normal state");
        require(_tokenState[tokenIdB] == QuantumState.Normal, "QENFT: Token B is not in Normal state");
        require(_validateEntanglementEligibility(tokenIdA, tokenIdB), "QENFT: Tokens are not eligible for entanglement");


        // Perform entanglement
        _entangledPair[tokenIdA] = tokenIdB;
        _entangledPair[tokenIdB] = tokenIdA;
        _tokenState[tokenIdA] = QuantumState.Entangled;
        _tokenState[tokenIdB] = QuantumState.Entangled;
        _entanglementTimestamp[tokenIdA] = block.timestamp;
        _entanglementTimestamp[tokenIdB] = block.timestamp; // Record timestamp for both

        // Transfer entanglement cost to contract owner
        // Using transfer for simple payment, consider call/send with checks in production
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "QENFT: Payment transfer failed");


        emit Entangled(tokenIdA, tokenIdB, block.timestamp);
    }

    /**
     * @notice Breaks the entanglement of a token and its pair.
     * @param tokenId The ID of one of the entangled tokens.
     */
    function breakEntanglement(uint256 tokenId) public {
         address ownerA = ownerOf(tokenId);

         // Ensure caller has permission for this token
        require(ownerA == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerA, _msgSender()),
            "QENFT: Caller not authorized for this token");

        require(_tokenState[tokenId] == QuantumState.Entangled, "QENFT: Token is not entangled");

        uint256 pairId = _entangledPair[tokenId];
        require(pairId != 0, "QENFT: Token is not entangled (pair ID missing)"); // Sanity check

        // Break entanglement for both
        _entangledPair[tokenId] = 0;
        _entangledPair[pairId] = 0;
        _tokenState[tokenId] = QuantumState.Normal;
        _tokenState[pairId] = QuantumState.Normal;
        delete _entanglementTimestamp[tokenId];
        delete _entanglementTimestamp[pairId];

        emit BreakEntanglement(tokenId, pairId, block.timestamp);
    }

    /**
     * @notice Puts an NFT into a superposition state.
     * @dev Token must be in Normal state.
     * @param tokenId The ID of the token to put into superposition.
     */
    function enterSuperposition(uint256 tokenId) public {
         address ownerOfToken = ownerOf(tokenId);
         // Ensure caller has permission
        require(ownerOfToken == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOfToken, _msgSender()),
            "QENFT: Caller not authorized for this token");

        require(_tokenState[tokenId] == QuantumState.Normal, "QENFT: Token must be in Normal state to enter superposition");

        // Generate a seed based on recent block data and sender entropy
        // NOTE: blockhash is only available for the last 256 blocks.
        // For production, use Chainlink VRF or similar for secure randomness.
        // This is a simplified example.
        bytes32 seed = keccak256(abi.encodePacked(
             blockhash(block.number > 0 ? block.number - 1 : block.number), // Use previous block hash
             block.timestamp,
             msg.sender,
             tokenId,
             block.difficulty // Add another source of potential entropy
        ));

        _superpositionSeed[tokenId] = seed;
        _tokenState[tokenId] = QuantumState.Superposition;
        _superpositionTimestamp[tokenId] = block.timestamp;

        emit EnteredSuperposition(tokenId, seed, block.timestamp);
    }

    /**
     * @notice Collapses an NFT's superposition into fixed properties.
     * @dev Token must be in Superposition state. Uses the stored seed and current block data.
     * @param tokenId The ID of the token to collapse.
     */
    function collapseSuperposition(uint256 tokenId) public {
        address ownerOfToken = ownerOf(tokenId);
        // Ensure caller has permission
        require(ownerOfToken == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOfToken, _msgSender()),
            "QENFT: Caller not authorized for this token");

        require(_tokenState[tokenId] == QuantumState.Superposition, "QENFT: Token must be in Superposition state to collapse");

        bytes32 seed = _superpositionSeed[tokenId];
        require(seed != bytes32(0), "QENFT: Superposition seed missing"); // Sanity check

        // Generate final properties using the stored seed and current block data
        // Again, blockhash has limitations. Secure randomness oracle recommended for production.
         bytes32 finalRandomness = keccak256(abi.encodePacked(
             seed,
             blockhash(block.number > 0 ? block.number - 1 : block.number), // Use previous block hash
             block.timestamp,
             msg.sender // Add sender to influence randomness slightly (prevents simple front-running)
        ));

        TokenProperties memory collapsedProps = _derivePropertiesFromSeed(finalRandomness, _tokenProperties[tokenId].energyLevel, _tokenProperties[tokenId].coherenceFactor);

        // Apply the collapsed properties
        _tokenProperties[tokenId] = collapsedProps;

        // Reset state
        _tokenState[tokenId] = QuantumState.Normal;
        delete _superpositionSeed[tokenId];
        delete _superpositionTimestamp[tokenId];

        emit CollapsedSuperposition(tokenId, collapsedProps, block.timestamp);
    }

     /**
     * @notice Resets the decay timer for a token's energy level.
     * @dev Requires payment of reEnergizeCost.
     * @param tokenId The ID of the token to re-energize.
     */
    function reEnergize(uint256 tokenId) public payable {
         address ownerOfToken = ownerOf(tokenId);
        // Ensure caller has permission
        require(ownerOfToken == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOfToken, _msgSender()),
            "QENFT: Caller not authorized for this token");

        require(msg.value >= _reEnergizeCost, "QENFT: Insufficient funds for re-energize");
        _requireOwned(tokenId); // Ensure token exists

        // Update the timestamp
        _lastReEnergizedTimestamp[tokenId] = uint255(block.timestamp);

        // Transfer re-energize cost to contract owner
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "QENFT: Payment transfer failed");

        emit ReEnergized(tokenId, block.timestamp);
    }


    // --- Query Functions (Read-only) ---

    /**
     * @notice Returns the current quantum state of a token.
     * @param tokenId The ID of the token.
     * @return The QuantumState enum value.
     */
    function getTokenState(uint256 tokenId) public view returns (QuantumState) {
        _requireOwned(tokenId);
        return _tokenState[tokenId];
    }

    /**
     * @notice Returns the fixed properties of a token (valid after collapse).
     * @param tokenId The ID of the token.
     * @return The TokenProperties struct.
     */
    function getTokenProperties(uint256 tokenId) public view returns (TokenProperties memory) {
        _requireOwned(tokenId);
        return _tokenProperties[tokenId];
    }

    /**
     * @notice Returns the superposition seed for a token in Superposition state.
     * @dev This does *not* return the resolved properties, only the seed used in the collapse process.
     * @param tokenId The ID of the token.
     * @return The bytes32 seed, or bytes32(0) if not in Superposition.
     */
    function getSuperpositionProperties(uint256 tokenId) public view returns (bytes32) {
        _requireOwned(tokenId);
        require(_tokenState[tokenId] == QuantumState.Superposition, "QENFT: Token is not in Superposition");
        return _superpositionSeed[tokenId];
    }

    /**
     * @notice Checks if a token is currently entangled.
     * @param tokenId The ID of the token.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        _requireOwned(tokenId);
        return _tokenState[tokenId] == QuantumState.Entangled;
    }

    /**
     * @notice Returns the token ID of the entangled pair.
     * @param tokenId The ID of the token.
     * @return The token ID of the pair, or 0 if not entangled.
     */
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId);
        return _entangledPair[tokenId];
    }

     /**
     * @notice Checks if a token is currently in Superposition.
     * @param tokenId The ID of the token.
     * @return True if in Superposition, false otherwise.
     */
    function isInSuperposition(uint256 tokenId) public view returns (bool) {
        _requireOwned(tokenId);
        return _tokenState[tokenId] == QuantumState.Superposition;
    }

    /**
     * @notice Calculates the current effective energy level considering decay.
     * @param tokenId The ID of the token.
     * @return The current effective energy level.
     */
    function checkDecayStatus(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        uint256 baseEnergy = _tokenProperties[tokenId].energyLevel;
        uint256 lastReEnergized = uint255(_lastReEnergizedTimestamp[tokenId]);

        return _calculateDecay(baseEnergy, lastReEnergized, _decayRatePerSecond);
    }

    /**
     * @notice Returns the configured decay rate per second.
     * @return The decay rate.
     */
    function getDecayRate() public view returns (uint256) {
        return _decayRatePerSecond;
    }

    /**
     * @notice Returns the timestamp when entanglement was initiated for this token.
     * @param tokenId The ID of the token.
     * @return The timestamp, or 0 if not entangled or not initiated via `entangleTokens`.
     */
    function getEntanglementTimestamp(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _entanglementTimestamp[tokenId];
    }

     /**
     * @notice Returns the timestamp when superposition was entered for this token.
     * @param tokenId The ID of the token.
     * @return The timestamp, or 0 if not in superposition.
     */
    function getSuperpositionTimestamp(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _superpositionTimestamp[tokenId];
    }

    /**
     * @notice Returns the timestamp when the token was last re-energized.
     * @param tokenId The ID of the token.
     * @return The timestamp.
     */
    function getLastReEnergizedTimestamp(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return uint256(_lastReEnergizedTimestamp[tokenId]);
    }


    // --- Admin/Configuration Functions (Ownable) ---

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setEntanglementCost(uint256 cost) public onlyOwner {
        _entanglementCost = cost;
    }

    function setReEnergizeCost(uint256 cost) public onlyOwner {
        _reEnergizeCost = cost;
    }

    function setDecayRate(uint256 rate) public onlyOwner {
        _decayRatePerSecond = rate;
    }

    /**
     * @notice Toggles the initial entanglement eligibility for a specific token.
     * @dev This provides an admin override to the `canEntangle` flag set during minting.
     * @param tokenId The ID of the token.
     * @param eligible The eligibility status to set.
     */
    function toggleEntanglementEligibility(uint256 tokenId, bool eligible) public onlyOwner {
        _requireOwned(tokenId); // Ensure token exists before setting eligibility
        _canEntangleInitially[tokenId] = eligible;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Helper to check if caller is owner or approved for a token.
     * @param tokenId The ID of the token.
     */
    function _requireOwnedOrApproved(uint256 tokenId) internal view {
        address ownerOfToken = ownerOf(tokenId);
        require(ownerOfToken == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOfToken, _msgSender()),
            "QENFT: Caller not authorized for this token");
    }


    /**
     * @dev Calculates the current energy level considering decay since last timestamp.
     * @param baseEnergy The initial or base energy level.
     * @param lastTimestamp The timestamp of the last re-energize or mint.
     * @param ratePerSecond The decay rate per second.
     * @return The calculated current energy level. Returns 0 if decay exceeds base.
     */
    function _calculateDecay(uint256 baseEnergy, uint256 lastTimestamp, uint256 ratePerSecond)
        internal view returns (uint256)
    {
        uint256 timePassed = block.timestamp.sub(lastTimestamp);
        uint256 decayAmount = timePassed.mul(ratePerSecond);

        if (decayAmount >= baseEnergy) {
            return 0;
        } else {
            return baseEnergy.sub(decayAmount);
        }
    }

    /**
     * @dev Deterministically derives fixed properties from a randomness seed.
     * @param seed The randomness seed (e.g., derived from blockhash, timestamp, msg.sender).
     * @param initialEnergy The initial energy level from mint (carried over if needed).
     * @param initialCoherence The initial coherence factor from mint (carried over if needed).
     * @return The TokenProperties struct with calculated spinState, colorValue, and carried over energy/coherence.
     */
    function _derivePropertiesFromSeed(bytes32 seed, uint256 initialEnergy, uint256 initialCoherence)
        internal pure returns (TokenProperties memory)
    {
        // Use the seed to derive properties. This is a simple example.
        // You could use more complex logic to map hash bytes to specific traits.
        uint256 seedUint = uint256(seed);

        // Example derivations:
        // SpinState: Simple boolean interpretation based on the first bit of the hash
        bytes32 spinState = (seedUint % 2 == 0) ? hex'01' : hex'ff'; // Example: 0x01 for 'up', 0xff for 'down'

        // ColorValue: Map a portion of the hash to a color range (e.g., 0-255 for grayscale, or combine bytes for RGB)
        // Let's use 3 bytes for an RGB-like value (0xRRGGBB)
        uint256 colorValue = (seedUint >> 8) % (2**24); // Take bytes 8-10, result in 0-~16M range

        return TokenProperties({
            energyLevel: initialEnergy,     // Energy is affected by decay, not collapse state
            coherenceFactor: initialCoherence, // Coherence set at mint, not affected by collapse here
            spinState: spinState,
            colorValue: colorValue
        });
    }

     /**
     * @dev Checks if two tokens meet custom criteria for entanglement.
     * @dev Current criteria: Both must be marked as initially eligible (`_canEntangleInitially`).
     * @param tokenIdA The ID of the first token.
     * @param tokenIdB The ID of the second token.
     * @return True if eligible, false otherwise.
     */
    function _validateEntanglementEligibility(uint256 tokenIdA, uint256 tokenIdB)
        internal view returns (bool)
    {
        // Example eligibility rule: Both tokens must have been minted with the canEntangle flag true
        return _canEntangleInitially[tokenIdA] && _canEntangleInitially[tokenIdB];

        // --- Potential future complex rules could include: ---
        // - require(_tokenProperties[tokenIdA].coherenceFactor > threshold && _tokenProperties[tokenIdB].coherenceFactor > threshold);
        // - require(_tokenProperties[tokenIdA].colorValue == _tokenProperties[tokenIdB].colorValue); // Only same color tokens can entangle
        // - require(bytes(_tokenProperties[tokenIdA].spinState)[0] != bytes(_tokenProperties[tokenIdB].spinState)[0]); // Only opposite spins can entangle
        // - Interaction with other contracts or data sources via oracles.
    }

    // --- Add more functions to reach 20+ if needed, e.g.: ---
    // 36. getEntanglementCost() public view returns (uint256) { return _entanglementCost; }
    // 37. getReEnergizeCost() public view returns (uint256) { return _reEnergizeCost; }
    // 38. getTokenCanEntangleInitially(uint256 tokenId) public view returns (bool) { return _canEntangleInitially[tokenId]; }
    // 39. transferEntangledPair(uint256 tokenIdA, address to) // Allows transferring both if entangled (complex logic needed to update ERC721 ownership) - Omitted for complexity
    // 40. splitEntangledPair(uint256 tokenIdA, address toA, address toB) // Allows transferring to two addresses - Omitted for complexity
    // ... many more query/admin functions can be added easily.

    // Including a few more simple getters to easily exceed 20
    function getEntanglementCost() public view returns (uint256) {
        return _entanglementCost;
    }

    function getReEnergizeCost() public view returns (uint256) {
        return _reEnergizeCost;
    }

     function getTokenCanEntangleInitially(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Ensure token exists
        return _canEntangleInitially[tokenId];
    }

    // Note: ERC721Enumerable adds tokenByIndex, tokenOfOwnerByIndex (2 functions).
    // ERC721 adds balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2) (9 functions).
    // supportsInterface (1 function).
    // tokenURI (1 function, override).
    // Total standard/overridden: 13 functions.
    // Custom functions added:
    // mintQuantumToken (1)
    // entangleTokens (1)
    // breakEntanglement (1)
    // enterSuperposition (1)
    // collapseSuperposition (1)
    // reEnergize (1)
    // getTokenState (1)
    // getTokenProperties (1)
    // getSuperpositionProperties (1)
    // isEntangled (1)
    // getEntangledPair (1)
    // isInSuperposition (1)
    // checkDecayStatus (1)
    // getDecayRate (1)
    // getEntanglementTimestamp (1)
    // getSuperpositionTimestamp (1)
    // getLastReEnergizedTimestamp (1)
    // setBaseURI (1)
    // setEntanglementCost (1)
    // setReEnergizeCost (1)
    // setDecayRate (1)
    // toggleEntanglementEligibility (1)
    // getTokenCanEntangleInitially (1)
    // getEntanglementCost (1) - Duplicate, already counted. Let's ensure unique public/external
    // getReEnergizeCost (1) - Duplicate, already counted.

    // Let's recount unique public/external functions:
    // 1-9: Standard ERC721 + safeTransferFrom variations (9)
    // 10: supportsInterface (1)
    // 11: tokenURI (1)
    // 12-13: ERC721Enumerable (2)
    // 14: mintQuantumToken (1)
    // 15: entangleTokens (1)
    // 16: breakEntanglement (1)
    // 17: enterSuperposition (1)
    // 18: collapseSuperposition (1)
    // 19: reEnergize (1)
    // 20: getTokenState (1)
    // 21: getTokenProperties (1)
    // 22: getSuperpositionProperties (1)
    // 23: isEntangled (1)
    // 24: getEntangledPair (1)
    // 25: isInSuperposition (1)
    // 26: checkDecayStatus (1)
    // 27: getDecayRate (1)
    // 28: getEntanglementTimestamp (1)
    // 29: getSuperpositionTimestamp (1)
    // 30: getLastReEnergizedTimestamp (1)
    // 31: setBaseURI (1)
    // 32: setEntanglementCost (1)
    // 33: setReEnergizeCost (1)
    // 34: setDecayRate (1)
    // 35: toggleEntanglementEligibility (1)
    // 36: getTokenCanEntangleInitially (1)

    // Total Public/External functions: 9 + 1 + 1 + 2 + 23 = 36 functions. Plenty over 20.

}
```