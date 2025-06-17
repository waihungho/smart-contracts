Okay, here is a smart contract concept called "Quantum Entangled NFTs". It combines several advanced/interesting ideas:

1.  **Entanglement:** NFTs are minted in pairs, linked together.
2.  **Dynamic State:** The entanglement status (`Entangled` or `UnEntangled`) is a dynamic state.
3.  **Conditional Unlock:** Un-entangling requires meeting a specific condition, simulating a "proof" (like a simplified ZK-proof verification).
4.  **Dynamic Traits/Metadata:** The visual representation and perhaps even on-chain traits of the NFT change based on its entanglement state.
5.  **Interdependent Utility:** Entangled pairs might share resources (like 'Charge') or have different abilities than un-entangled NFTs.
6.  **Unique Transfer Logic:** Transferring one entangled NFT automatically un-entangles the pair.
7.  **Resource Management:** Bond Strength and Charge levels influence actions.

This contract is not a direct duplicate of standard OpenZeppelin contracts or common tutorial examples due to the specific entanglement mechanics, dynamic state, conditional unlock, and paired transfer behavior.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For total supply and enumeration
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // If storing dynamic URIs per token, though we'll derive

// --- Outline ---
// 1. State Variables: Track token supply, pair IDs, entanglement status, partner mapping, bond strength, charge, un-entanglement secret, base URI.
// 2. Structs: Define NFT traits.
// 3. Events: Signal key actions like minting, entanglement state changes, resource updates.
// 4. Modifiers: Custom checks for entanglement state.
// 5. Constructor: Initialize the contract.
// 6. Core Entanglement Logic: Minting pairs, un-entangling, re-entangling.
// 7. Dynamic State & Traits: Functions to query state and potentially influence token URI.
// 8. Resource Management: Collect charge, manage bond strength, sacrifice mechanism.
// 9. ERC721 Overrides: Handle transfer logic based on entanglement.
// 10. Utility & Admin: Pause, withdraw, set parameters, query information.
// 11. Basic ERC721 Functions: Standard ERC721 methods inherited or overridden.

// --- Function Summary ---
// - Constructor: Deploys the contract, sets owner and base URI.
// - supportsInterface(bytes4 interfaceId): ERC165 standard, checks supported interfaces.
// - mintPair(address to): Mints two new entangled NFTs to the recipient.
// - unEntangle(uint256 tokenId, bytes32 proofHash): Attempts to un-entangle an NFT using a simulated proof hash. Requires minimum bond strength.
// - reEntangle(uint256 tokenId): Attempts to re-entangle an un-entangled NFT with its original partner. Requires sufficient charge.
// - collectCharge(uint256 tokenId): Allows the owner of an un-entangled NFT to collect accrued charge. Increases bond strength slightly.
// - attemptFusion(uint256 tokenId1, uint256 tokenId2): Attempts to 'fuse' two un-entangled NFTs from *different* original pairs, burning them and potentially emitting a signal for off-chain action (or a future V2 contract).
// - sacrifice(uint256 tokenIdToSacrifice, uint256 tokenIdToBoost): Burns one un-entangled NFT to significantly boost the bond strength and charge of another owned NFT.
// - isEntangled(uint256 tokenId): Checks if an NFT is currently entangled.
// - getPartner(uint256 tokenId): Returns the token ID of the partner NFT in the original pair.
// - getPairId(uint256 tokenId): Returns the ID of the pair the token belongs to.
// - getEntanglementState(uint256 tokenId): Returns a string ("Entangled", "UnEntangled", "Sacrificed").
// - getBondStrength(uint256 tokenId): Returns the current bond strength of an NFT.
// - getChargeLevel(uint256 tokenId): Returns the current charge level of an NFT.
// - getTokenBaseTraits(uint256 tokenId): Returns the immutable base traits of an NFT.
// - getDynamicTraitValue(uint256 tokenId): Returns a string representing a dynamic trait value based on entanglement state (simulated).
// - setBaseTokenURI(string memory baseURI_): Owner sets the base URI for metadata.
// - setUnEntanglementSecretHash(bytes32 secretHash_): Owner sets the required hash for un-entanglement.
// - pause(): Owner pauses the contract.
// - unpause(): Owner unpauses the contract.
// - withdraw(): Owner withdraws collected funds (if minting cost implemented, currently free).
// - tokenURI(uint256 tokenId): Overridden to potentially include entanglement state in URI path.
// - _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Internal hook to handle entanglement breaking on transfer.
// - _baseURI(): Internal helper for tokenURI.
// - balanceOf(address owner): Standard ERC721.
// - ownerOf(uint256 tokenId): Standard ERC721.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Standard ERC721.
// - safeTransferFrom(address from, address to, uint256 tokenId): Standard ERC721.
// - transferFrom(address from, address to, uint256 tokenId): Standard ERC721.
// - approve(address to, uint256 tokenId): Standard ERC721.
// - getApproved(uint256 tokenId): Standard ERC721.
// - setApprovalForAll(address operator, bool approved): Standard ERC721.
// - isApprovedForAll(address owner, address operator): Standard ERC721.
// - totalSupply(): Standard ERC721Enumerable.
// - tokenByIndex(uint256 index): Standard ERC721Enumerable.
// - tokenOfOwnerByIndex(address owner, uint256 index): Standard ERC721Enumerable.

contract QuantumEntangledNFT is ERC721, Ownable, Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _pairIdCounter;

    // State Variables
    mapping(uint256 => uint256) private _partnerId; // tokenId => partner tokenId
    mapping(uint256 => bool) private _isEntangled; // tokenId => entanglement status
    mapping(uint256 => uint256) private _pairId; // tokenId => pair ID (0, 1, 2...)
    mapping(uint256 => uint256) private _bondStrength; // tokenId => bond strength level
    mapping(uint256 => uint256) private _chargeLevel; // tokenId => charge level
    mapping(uint256 => uint256) private _lastChargeCollectionBlock; // tokenId => block number of last charge collection
    bytes32 private _unEntanglementSecretHash; // Required hash for un-entangling

    // Represents immutable base traits
    struct NFTBaseTraits {
        string color;
        string pattern;
        uint8 rarity; // e.g., 1-100
    }
    mapping(uint256 => NFTBaseTraits) private _tokenBaseTraits;

    // Keep track of sacrificed tokens (optional, but useful for state query)
    mapping(uint256 => bool) private _isSacrificed;

    // Constants for game mechanics (can be owner configurable)
    uint256 public constant MIN_BOND_FOR_UNENTANGLE = 10;
    uint256 public constant CHARGE_COST_FOR_REENTANGLE = 5;
    uint256 public constant CHARGE_PER_BLOCK = 1; // Simplified charge accrual
    uint256 public constant MAX_CHARGE_LEVEL = 100;
    uint256 public constant SACRIFICE_BOND_BOOST = 20;
    uint256 public constant SACRIFICE_CHARGE_BOOST = 20;
    uint256 public constant INITIAL_BOND_STRENGTH = 5;
    uint256 public constant INITIAL_CHARGE_LEVEL = 0;

    // Events
    event PairMinted(address indexed to, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 pairId);
    event Entangled(uint256 indexed tokenId, uint256 indexed partnerId);
    event UnEntangled(uint256 indexed tokenId, uint256 indexed partnerId, bytes32 proofHash);
    event BondStrengthIncreased(uint256 indexed tokenId, uint256 newBondStrength);
    event ChargeCollected(uint256 indexed tokenId, uint256 amount, uint256 newChargeLevel);
    event Sacrifice(uint256 indexed tokenIdSacrificed, uint256 indexed tokenIdBoosted);
    event FusionAttempted(uint256 indexed tokenId1, uint256 indexed tokenId2, bool success); // Signalling event

    // Errors
    error NotEntangled();
    error AlreadyEntangled();
    error NotUnEntangled();
    error IncorrectPartner();
    error InsufficientBondStrength();
    error InvalidProof();
    error InsufficientCharge();
    error SelfSacrificeForbidden();
    error CannotBoostEntangled();
    error InvalidFusionPair();
    error FusionConditionsNotMet();
    error CannotSacrificeEntangled();
    error NotPartnerOfToken();

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Core Entanglement Logic ---

    /**
     * @notice Mints a new entangled pair of NFTs to the recipient.
     * @param to The address to mint the NFTs to.
     */
    function mintPair(address to) external onlyOwner {
        _pause(); // Pause minting during development or specific events
        _pairIdCounter.increment();
        uint256 currentPairId = _pairIdCounter.current();

        uint256 tokenId1 = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        uint256 tokenId2 = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId1);
        _safeMint(to, tokenId2);

        _partnerId[tokenId1] = tokenId2;
        _partnerId[tokenId2] = tokenId1;
        _pairId[tokenId1] = currentPairId;
        _pairId[tokenId2] = currentPairId;

        _setEntanglement(tokenId1, true);
        _setEntanglement(tokenId2, true);

        _bondStrength[tokenId1] = INITIAL_BOND_STRENGTH;
        _bondStrength[tokenId2] = INITIAL_BOND_STRENGTH;
        _chargeLevel[tokenId1] = INITIAL_CHARGE_LEVEL;
        _chargeLevel[tokenId2] = INITIAL_CHARGE_LEVEL;
        _lastChargeCollectionBlock[tokenId1] = block.number;
        _lastChargeCollectionBlock[tokenId2] = block.number;

        // Assign some random-ish base traits (simplified)
        // In a real contract, this might use Chainlink VRF or a more complex generation logic
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId1, tokenId2, currentPairId)));
        _tokenBaseTraits[tokenId1] = _generateBaseTraits(seed);
        _tokenBaseTraits[tokenId2] = _generateBaseTraits(seed + 1); // Slightly different traits for partner

        emit PairMinted(to, tokenId1, tokenId2, currentPairId);
    }

    /**
     * @notice Attempts to un-entangle an NFT. Requires a proof hash verification and minimum bond strength.
     * @param tokenId The ID of the NFT to un-entangle.
     * @param proofHash A hash provided by the user, simulating a ZK-proof output or secret knowledge.
     */
    function unEntangle(uint256 tokenId, bytes32 proofHash) external whenNotPaused {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        if (ownerOf(tokenId) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenId);
        if (!_isEntangled[tokenId]) revert NotEntangled();
        if (_bondStrength[tokenId] < MIN_BOND_FOR_UNENTANGLE) revert InsufficientBondStrength();
        if (proofHash != _unEntanglementSecretHash) revert InvalidProof();

        uint256 partnerId = _partnerId[tokenId];
        // Ensure partner is also owned by the sender and exists
        if (!_exists(partnerId) || ownerOf(partnerId) != _msgSender()) revert IncorrectPartner();

        _setEntanglement(tokenId, false);
        _setEntanglement(partnerId, false);

        // Reset charge upon un-entanglement
        _chargeLevel[tokenId] = 0;
        _chargeLevel[partnerId] = 0;
        _lastChargeCollectionBlock[tokenId] = block.number; // Reset collection block
        _lastChargeCollectionBlock[partnerId] = block.number;

        emit UnEntangled(tokenId, partnerId, proofHash);
    }

    /**
     * @notice Attempts to re-entangle an un-entangled NFT with its original partner.
     * @param tokenId The ID of the NFT to re-entangle.
     */
    function reEntangle(uint256 tokenId) external whenNotPaused {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        if (ownerOf(tokenId) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenId);
        if (_isEntangled[tokenId]) revert AlreadyEntangled();
        if (_isSacrificed[tokenId]) revert CannotBoostEntangled(); // Cannot re-entangle if sacrificed

        uint256 partnerId = _partnerId[tokenId];
        if (!_exists(partnerId) || ownerOf(partnerId) != _msgSender() || _isSacrificed[partnerId]) revert IncorrectPartner();
        if (_isEntangled[partnerId]) revert AlreadyEntangled(); // Both must be un-entangled

        if (_chargeLevel[tokenId] < CHARGE_COST_FOR_REENTANGLE) revert InsufficientCharge();
        if (_chargeLevel[partnerId] < CHARGE_COST_FOR_REENTANGLE) revert InsufficientCharge(); // Both pay charge

        // Pay charge cost
        _chargeLevel[tokenId] -= CHARGE_COST_FOR_REENTANGLE;
        _chargeLevel[partnerId] -= CHARGE_COST_FOR_REENTANGLE;

        _setEntanglement(tokenId, true);
        _setEntanglement(partnerId, true);

        // Increase bond strength slightly upon successful re-entanglement
        _bondStrength[tokenId]++;
        _bondStrength[partnerId]++;
        emit BondStrengthIncreased(tokenId, _bondStrength[tokenId]);
        emit BondStrengthIncreased(partnerId, _bondStrength[partnerId]);


        emit Entangled(tokenId, partnerId);
    }

    // --- Dynamic State & Traits ---

    /**
     * @notice Checks if an NFT is currently entangled.
     * @param tokenId The ID of the NFT.
     * @return bool True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _isEntangled[tokenId];
    }

    /**
     * @notice Gets the ID of the partner NFT in the original pair.
     * @param tokenId The ID of the NFT.
     * @return uint256 The partner token ID.
     */
    function getPartner(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _partnerId[tokenId];
    }

     /**
     * @notice Gets the Pair ID the token belongs to.
     * @param tokenId The ID of the NFT.
     * @return uint256 The pair ID.
     */
    function getPairId(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _pairId[tokenId];
    }


    /**
     * @notice Gets the current entanglement state as a string.
     * @param tokenId The ID of the NFT.
     * @return string State: "Entangled", "UnEntangled", "Sacrificed", or "Nonexistent".
     */
    function getEntanglementState(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) return "Nonexistent";
        if (_isSacrificed[tokenId]) return "Sacrificed";
        if (_isEntangled[tokenId]) return "Entangled";
        return "UnEntangled";
    }

    /**
     * @notice Returns the immutable base traits of an NFT.
     * @param tokenId The ID of the NFT.
     * @return NFTBaseTraits The base traits struct.
     */
    function getTokenBaseTraits(uint256 tokenId) public view returns (NFTBaseTraits memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _tokenBaseTraits[tokenId];
    }

    /**
     * @notice Returns a string representing a *simulated* dynamic trait based on entanglement state.
     * This value would typically influence the tokenURI metadata.
     * @param tokenId The ID of the NFT.
     * @return string A dynamic trait value.
     */
    function getDynamicTraitValue(uint256 tokenId) public view returns (string memory) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
         if (_isSacrificed[tokenId]) return "Echo"; // State after sacrifice
         return _isEntangled[tokenId] ? "Synchronized" : "QuantumFlux"; // Different states
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Overridden to include the entanglement state in the path, allowing for dynamic metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        string memory base = _baseURI();
        string memory state = getEntanglementState(tokenId); // "Entangled", "UnEntangled", "Sacrificed"

        // Append state and token ID to base URI (e.g., ipfs://.../entangled/123.json)
        return string(abi.encodePacked(base, state, "/", tokenId.toString(), ".json"));
    }

    // --- Resource Management ---

    /**
     * @notice Allows the owner of an *un-entangled* NFT to collect accrued charge.
     * Charge accrues based on block difference since last collection/mint.
     * Collecting charge slightly increases bond strength.
     * @param tokenId The ID of the NFT.
     */
    function collectCharge(uint256 tokenId) external whenNotPaused {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        if (ownerOf(tokenId) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenId);
        if (_isEntangled[tokenId]) revert CannotBoostEntangled(); // Can only collect charge when un-entangled
        if (_isSacrificed[tokenId]) revert CannotBoostEntangled(); // Cannot collect if sacrificed

        uint256 lastCollectionBlock = _lastChargeCollectionBlock[tokenId];
        uint256 blocksPassed = block.number - lastCollectionBlock;
        uint256 accruedCharge = blocksPassed * CHARGE_PER_BLOCK;
        if (accruedCharge == 0) return; // No charge accrued yet

        uint256 newCharge = _chargeLevel[tokenId] + accruedCharge;
        _chargeLevel[tokenId] = newCharge > MAX_CHARGE_LEVEL ? MAX_CHARGE_LEVEL : newCharge;
        _lastChargeCollectionBlock[tokenId] = block.number; // Reset collection block

        // Slightly increase bond strength upon collection (capped)
        if (_bondStrength[tokenId] < type(uint256).max) {
             _bondStrength[tokenId]++;
             emit BondStrengthIncreased(tokenId, _bondStrength[tokenId]);
        }


        emit ChargeCollected(tokenId, accruedCharge, _chargeLevel[tokenId]);
    }

     /**
     * @notice Gets the current bond strength of an NFT.
     * @param tokenId The ID of the NFT.
     * @return uint256 The bond strength level.
     */
    function getBondStrength(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _bondStrength[tokenId];
    }

    /**
     * @notice Gets the current charge level of an NFT.
     * @param tokenId The ID of the NFT.
     * @return uint256 The charge level.
     */
    function getChargeLevel(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _chargeLevel[tokenId];
    }

    /**
     * @notice Allows the owner to sacrifice one un-entangled NFT to boost the bond strength and charge of another owned NFT.
     * The sacrificed NFT is burned.
     * @param tokenIdToSacrifice The ID of the NFT to burn.
     * @param tokenIdToBoost The ID of the NFT to boost. Must be owned by the sender.
     */
    function sacrifice(uint256 tokenIdToSacrifice, uint256 tokenIdToBoost) external whenNotPaused {
        if (!_exists(tokenIdToSacrifice)) revert ERC721NonexistentToken(tokenIdToSacrifice);
        if (!_exists(tokenIdToBoost)) revert ERC721NonexistentToken(tokenIdToBoost);
        if (ownerOf(tokenIdToSacrifice) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenIdToSacrifice);
        if (ownerOf(tokenIdToBoost) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenIdToBoost);
        if (tokenIdToSacrifice == tokenIdToBoost) revert SelfSacrificeForbidden();
        if (_isEntangled[tokenIdToBoost]) revert CannotBoostEntangled(); // Cannot boost an entangled NFT
        if (!_isEntangled[tokenIdToSacrifice]) revert CannotSacrificeEntangled(); // Can only sacrifice *un-entangled* NFTs

        // Mark as sacrificed (instead of full burn, allows tracking state)
        _isSacrificed[tokenIdToSacrifice] = true;
         _transfer(_msgSender(), address(0), tokenIdToSacrifice); // Transfer to zero address to simulate burn

        // Apply boost to the target NFT
        _bondStrength[tokenIdToBoost] += SACRIFICE_BOND_BOOST;
        _chargeLevel[tokenIdToBoost] += SACRIFICE_CHARGE_BOOST;
        if (_chargeLevel[tokenIdToBoost] > MAX_CHARGE_LEVEL) _chargeLevel[tokenIdToBoost] = MAX_CHARGE_LEVEL;

        emit Sacrifice(tokenIdToSacrifice, tokenIdToBoost);
        emit BondStrengthIncreased(tokenIdToBoost, _bondStrength[tokenIdToBoost]);
        emit ChargeCollected(tokenIdToBoost, SACRIFICE_CHARGE_BOOST, _chargeLevel[tokenIdToBoost]); // Treat boost as collection
    }

     /**
     * @notice Attempts to fuse two un-entangled NFTs from *different* original pairs.
     * If successful, they are burned. This is a signaling mechanism for potential off-chain effects or V2 minting.
     * @param tokenId1 The ID of the first NFT.
     * @param tokenId2 The ID of the second NFT.
     */
    function attemptFusion(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        if (!_exists(tokenId1)) revert ERC721NonexistentToken(tokenId1);
        if (!_exists(tokenId2)) revert ERC721NonexistentToken(tokenId2);
        if (ownerOf(tokenId1) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenId1);
        if (ownerOf(tokenId2) != _msgSender()) revert ERC721NotOwned(_msgSender(), tokenId2);
        if (tokenId1 == tokenId2) revert InvalidFusionPair();
        if (_pairId[tokenId1] == _pairId[tokenId2]) revert InvalidFusionPair(); // Must be from different pairs
        if (_isEntangled[tokenId1] || _isEntangled[tokenId2]) revert FusionConditionsNotMet(); // Must be un-entangled
        if (_isSacrificed[tokenId1] || _isSacrificed[tokenId2]) revert FusionConditionsNotMet(); // Cannot fuse sacrificed tokens

        // --- Simulate complex fusion logic ---
        // This is where you could add checks for:
        // - Minimum bond strength/charge levels
        // - Specific trait combinations (_tokenBaseTraits)
        // - External conditions (via Oracle if implemented)
        // For this example, let's require a minimum combined bond strength and sum of specific trait values
        uint256 combinedBond = _bondStrength[tokenId1] + _bondStrength[tokenId2];
        uint256 traitSum = _tokenBaseTraits[tokenId1].rarity + _tokenBaseTraits[tokenId2].rarity; // Example condition

        bool fusionPossible = combinedBond >= 50 && traitSum >= 150; // Example arbitrary condition

        if (fusionPossible) {
             // Mark as sacrificed (instead of full burn, allows tracking state)
            _isSacrificed[tokenId1] = true;
            _isSacrificed[tokenId2] = true;
            _transfer(_msgSender(), address(0), tokenId1); // Simulate burn
            _transfer(_msgSender(), address(0), tokenId2); // Simulate burn

            // In a real scenario, this might mint a new token type (ERC20/ERC721 V2),
            // trigger an off-chain event, etc.
            // emit NewFusedTokenMinted(owner(), newTokenId); // Example for V2
        }

        emit FusionAttempted(tokenId1, tokenId2, fusionPossible);
        if (!fusionPossible) revert FusionConditionsNotMet();
    }


    // --- ERC721 Overrides ---

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Overridden to handle entanglement state changes upon transfer.
     * Transferring an entangled NFT automatically un-entangles both NFTs in the pair.
     * Sacrificed tokens cannot be transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Always call super

        if (_isSacrificed[tokenId] && from != address(0)) { // Cannot transfer if sacrificed (unless it's the burn itself)
             revert ERC721InvalidTransfer(from, to, tokenId, batchSize); // Or a custom error
        }

        if (_isEntangled[tokenId] && to != address(0) && from != address(0)) { // If transferring an entangled token (not mint or burn)
            uint256 partnerId = _partnerId[tokenId];

            // Check if partner exists and is not already sacrificed
            if (_exists(partnerId) && !_isSacrificed[partnerId]) {
                 // Automatically un-entangle both tokens upon transfer of one
                _setEntanglement(tokenId, false);
                _setEntanglement(partnerId, false);

                // Reset charge upon un-entanglement
                _chargeLevel[tokenId] = 0;
                _chargeLevel[partnerId] = 0;
                 _lastChargeCollectionBlock[tokenId] = block.number; // Reset collection block
                _lastChargeCollectionBlock[partnerId] = block.number;


                // Important: Do NOT attempt to transfer the partner token here automatically.
                // This would violate ERC721 assumptions about batch size and token ownership.
                // The partner remains with the original owner, just un-entangled.
                // This is a key characteristic of THIS specific contract's logic.

                emit UnEntangled(tokenId, partnerId, bytes32(0)); // Use 0 hash for transfer-induced un-entanglement
            }
             // Note: If partner is sacrificed or doesn't exist, the token still transfers,
             // but its link is implicitly broken anyway. We still set `_isEntangled[tokenId]` to false.
             _isEntangled[tokenId] = false; // Ensure the transferred token is marked un-entangled
        }
         // If target `to` is address(0), it's a burn. Handled implicitly by OpenZeppelin's burn function logic.
         // If `from` is address(0), it's a mint. Entanglement is set in `mintPair`.
    }


    // --- Utility & Admin ---

    /**
     * @notice Sets the base URI for token metadata.
     * Owner only.
     * @param baseURI_ The new base URI.
     */
    function setBaseTokenURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @notice Sets the secret hash required for un-entanglement.
     * Owner only. This hash simulates the outcome of a ZK-proof verification.
     * @param secretHash_ The new secret hash.
     */
    function setUnEntanglementSecretHash(bytes32 secretHash_) external onlyOwner {
        _unEntanglementSecretHash = secretHash_;
    }

    /**
     * @notice Pauses the contract, preventing most interactions.
     * Owner only.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing interactions.
     * Owner only.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw any accumulated ether.
     * (This contract doesn't collect ether currently, but good practice)
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev Helper function to set the entanglement state of a token.
     */
    function _setEntanglement(uint256 tokenId, bool entangled) internal {
        _isEntangled[tokenId] = entangled;
        uint256 partnerId = _partnerId[tokenId];
        if (_exists(partnerId)) { // Ensure partner exists before setting state
             _isEntangled[partnerId] = entangled;
        }
    }

     /**
     * @dev Helper function to generate simple base traits.
     * @param seed A seed for generating traits.
     * @return NFTBaseTraits The generated traits.
     */
    function _generateBaseTraits(uint256 seed) internal pure returns (NFTBaseTraits memory) {
        string memory color;
        string memory pattern;
        uint8 rarity;

        // Use seed to pick traits (very simplified example)
        if (seed % 3 == 0) color = "Red";
        else if (seed % 3 == 1) color = "Blue";
        else color = "Green";

        if (seed % 2 == 0) pattern = "Stripes";
        else pattern = "Dots";

        rarity = uint8((seed % 100) + 1); // Rarity 1-100

        return NFTBaseTraits(color, pattern, rarity);
    }

    // --- Standard ERC721 & Enumerable Functions ---
    // These are mostly inherited or simple overrides required by the standards

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address owner, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(owner, amount);
    }

    function _decreaseBalance(address owner, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._decreaseBalance(owner, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return super._baseURI();
    }

    // The remaining standard ERC721 functions are inherited and used:
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // transferFrom(address from, address to, uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // getApproved(uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // isApprovedForAll(address owner, address operator)
    // totalSupply()
    // tokenByIndex(uint256 index)
    // tokenOfOwnerByIndex(address owner, uint256 index)
}
```