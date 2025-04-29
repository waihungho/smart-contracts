Okay, here is a smart contract in Solidity implementing a concept called "Ethereal Canvas". This contract represents dynamic, generative art NFTs where the appearance and properties of the art evolve based on on-chain interactions and states. It includes mechanics like evolving stages, applying traits via "palettes", adding "signature marks" (achievements), community critique scores, and more.

It implements a subset of ERC721 functions manually to avoid simply inheriting a standard library wholesale, focusing on the custom logic. The metadata is designed to be dynamic, relying on an off-chain service (`tokenURI`) that reads the on-chain state of each Canvas NFT.

**Concept:** Ethereal Canvas - Dynamic, Generative Art NFTs.
Each token is a "Canvas" whose visual representation (via dynamic metadata) changes based on its on-chain state.
**Key Features:**
*   **Dynamic State:** Canvases have evolving properties (stage, painting cycle, critique score, traits, signature marks).
*   **Generative Elements:** Initial traits are semi-randomly generated on minting.
*   **Interactive Evolution:** Owners can trigger state changes (evolve, apply palette, add marks) often requiring payment.
*   **Community Layer:** A critique mechanism allows designated addresses to score canvases.
*   **Trait Management:** Traits are stored on-chain and can be influenced by interactions.
*   **Dynamic Metadata:** `tokenURI` pulls state data to generate unique, evolving art representations off-chain.
*   **Access Control:** Uses Ownable for admin functions and Pausable for contract state control.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Use interface for standard adherence
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
//
// Contract: EtherealCanvas
// Standard: Partial ERC721 implementation with significant custom logic
// Base URI: tokenURI relies on an off-chain service interpreting on-chain state
// Randomness: Uses block.timestamp and block.difficulty (NOTE: Basic, insecure randomness - for demonstration)
//
// State Variables:
// - _tokenCounter: Counter for unique token IDs.
// - _canvases: Mapping of tokenId to Canvas struct.
// - _ownerOf: Mapping of tokenId to owner address (ERC721).
// - _balances: Mapping of owner address to number of tokens owned (ERC721).
// - _tokenApprovals: Mapping of tokenId to approved address (ERC721).
// - _operatorApprovals: Mapping of owner to operator to approval status (ERC721).
// - _baseMetadataURI: Base URI for the dynamic metadata service.
// - evolutionPrice: Price to evolve a canvas stage.
// - palettePrices: Mapping of paletteId to price.
// - markPrices: Mapping of markType to price.
// - allowedCritiquers: Mapping of address to boolean for critique permission.
// - traitDefinitions: Mapping of traitType to string definition (for metadata).
//
// Structs:
// - Canvas: Holds all dynamic data for a token (traits, stage, cycle, critique, lock, etc.).
//
// Events:
// - Transfer (ERC721): Emitted when token ownership changes.
// - Approval (ERC721): Emitted when approval is granted for a token.
// - ApprovalForAll (ERC721): Emitted when approval is granted for an operator.
// - CanvasMinted: Emitted when a new canvas is created.
// - CanvasEvolved: Emitted when a canvas stage changes.
// - PaletteApplied: Emitted when a palette modifies traits.
// - SignatureMarkAdded: Emitted when a signature mark is added.
// - CritiqueReceived: Emitted when a critique score is applied.
// - CanvasLocked: Emitted when a canvas is locked.
// - CanvasUnlocked: Emitted when a canvas is unlocked.
// - PriceUpdated: Emitted when a price variable is changed.
// - CritiquerPermissionUpdated: Emitted when critiquer status changes.
// - BaseURIUpdated: Emitted when base URI changes.
//
// Functions:
// --- ERC721 Standard (Partial Implementation) ---
// 1. supportsInterface(bytes4 interfaceId): Check if the contract supports an interface.
// 2. balanceOf(address owner): Get the number of tokens owned by an address.
// 3. ownerOf(uint256 tokenId): Get the owner of a specific token.
// 4. approve(address to, uint256 tokenId): Approve an address to spend a specific token.
// 5. getApproved(uint256 tokenId): Get the approved address for a token.
// 6. setApprovalForAll(address operator, bool approved): Approve or revoke operator status for all tokens.
// 7. isApprovedForAll(address owner, address operator): Check if an address is an approved operator.
// 8. transferFrom(address from, address to, uint256 tokenId): Transfer token ownership (internal helper call).
// 9. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfer token ownership.
// 10. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfer with data.
// 11. tokenURI(uint256 tokenId): Get the metadata URI for a token.
//
// --- Minting Functions ---
// 12. mintInitialCanvas(address recipient): Mints a new canvas with semi-random initial traits.
// 13. mintCanvasWithSeed(address recipient, uint256 seed): Mints a new canvas using a specified seed for traits.
//
// --- Interaction Functions (Affect Canvas State) ---
// 14. evolveCanvas(uint256 tokenId): Allows owner to advance the canvas evolution stage (payable).
// 15. applyPalette(uint256 tokenId, uint8 paletteId): Allows owner to apply a palette, potentially changing traits (payable).
// 16. addSignatureMark(uint256 tokenId, uint8 markType): Allows owner to add a unique mark/achievement (payable).
// 17. startPaintingCycle(uint256 tokenId): Resets/advances the painting cycle for a canvas (payable, different cost/conditions).
// 18. critiqueCanvas(uint256 tokenId, uint8 critiqueScore): Allows authorized critiquers to add a score.
// 19. lockCanvas(uint256 tokenId): Allows owner to lock the canvas, preventing state changes.
// 20. unlockCanvas(uint256 tokenId): Allows owner to unlock a locked canvas.
//
// --- Getter Functions ---
// 21. getCanvasTraits(uint256 tokenId): Get the array of trait values for a canvas.
// 22. getCanvasStage(uint256 tokenId): Get the evolution stage of a canvas.
// 23. getCanvasPaintingCycle(uint256 tokenId): Get the current painting cycle.
// 24. getCanvasCritiqueScore(uint256 tokenId): Get the accumulated critique score.
// 25. getCanvasLockedStatus(uint256 tokenId): Check if a canvas is locked.
// 26. getBaseMetadataURI(): Get the base metadata URI.
// 27. getCanvasEvolutionPrice(): Get the current evolution price.
// 28. getPaletteApplicationPrice(uint8 paletteId): Get the price for a specific palette.
// 29. getSignatureMarkPrice(uint8 markType): Get the price for a specific mark.
// 30. isAllowedCritiquer(address addr): Check if an address is an allowed critiquer.
// 31. getTotalCanvases(): Get the total number of canvases minted.
// 32. getCanvasData(uint256 tokenId): Get all data from the Canvas struct for a token.
// 33. getTraitDefinition(uint8 traitType): Get the definition string for a trait type.
//
// --- Admin Functions (Ownable) ---
// 34. setBaseMetadataURI(string memory newURI): Set the base URI for metadata.
// 35. setCanvasEvolutionPrice(uint256 price): Set the price for evolving.
// 36. setPaletteApplicationPrice(uint8 paletteId, uint256 price): Set the price for a specific palette.
// 37. setSignatureMarkPrice(uint8 markType, uint256 price): Set the price for a specific mark.
// 38. setAllowedCritiquer(address addr, bool allowed): Grant or revoke critiquer permission.
// 39. setTraitDefinition(uint8 traitType, string memory definition): Set the definition string for a trait type.
// 40. pause(): Pause certain interactions (inherits Pausable).
// 41. unpause(): Unpause interactions (inherits Pausable).
// 42. withdrawFunds(): Withdraw collected Ether.
//
// --- Internal Helpers ---
// - _exists(uint256 tokenId): Check if a token exists.
// - _transfer(address from, address to, uint256 tokenId): Internal token transfer logic.
// - _safeTransfer(address from, address to, uint256 tokenId, bytes data): Internal safe transfer check.
// - _approve(address to, uint256 tokenId): Internal approval logic.
// - _isApprovedOrOwner(address spender, uint256 tokenId): Check if address is owner or approved.
// - _generateRandomSeed(): Generates a seed using block data (insecure for critical use).
// - _generateInitialTraits(uint256 seed): Generates initial traits based on a seed.
// - _isContract(address addr): Check if an address is a contract.

// Note: Secure randomness (like Chainlink VRF) is recommended for production systems.
// Note: The dynamic metadata service (`tokenURI`) is hypothetical and must be implemented off-chain.

// --- Contract Code Starts ---

// Minimal ERC165 support for interface detection
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract EtherealCanvas is Context, Ownable, Pausable, IERC721, IERC165 {

    using Strings for uint256;

    // --- Errors ---
    error InvalidRecipient();
    error TokenDoesNotExist();
    error NotApprovedOrOwner();
    error NotOwner();
    error TransferToERC721ReceiverRejected();
    error TransferFromIncorrectOwner();
    error ApprovalToCurrentOwner();
    error IndexOutOfRange(); // For trait indexing or similar arrays
    error CanvasLocked();
    error CanvasMaxStageReached();
    error InsufficientPayment();
    error InvalidCritiqueScore();
    error NotAllowedCritiquer();
    error TraitTypeDoesNotExist();

    // --- State Variables ---
    uint256 private _tokenCounter;

    struct Canvas {
        uint8[5] traits; // Example: 5 traits (e.g., background, shape, color, texture, effect)
        uint8 stage; // Evolution stage (e.g., 0 to 5)
        uint16 paintingCycle; // Number of times painting cycle has been reset/advanced
        uint16 critiqueScore; // Accumulated critique score (sum of scores)
        uint16 critiqueCount; // Number of critiques received
        bool locked; // If the canvas is locked
        uint8[5] signatureMarks; // Example: 5 types of signature marks/achievements
    }

    mapping(uint256 => Canvas) private _canvases;

    // ERC721 State
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Contract Configuration
    string private _baseMetadataURI;
    uint256 public evolutionPrice;
    mapping(uint8 => uint256) public palettePrices; // paletteId => price
    mapping(uint8 => uint256) public markPrices;     // markType => price
    mapping(address => bool) private _allowedCritiquers;
    mapping(uint8 => string) private _traitDefinitions; // traitType => definition string

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event CanvasMinted(address indexed owner, uint256 indexed tokenId, uint256 seed);
    event CanvasEvolved(uint256 indexed tokenId, uint8 newStage);
    event PaletteApplied(uint256 indexed tokenId, uint8 indexed paletteId, uint8[5] newTraits);
    event SignatureMarkAdded(uint256 indexed tokenId, uint8 indexed markType, uint8 newCount);
    event CritiqueReceived(uint256 indexed tokenId, address indexed critiquer, uint8 score, uint16 newScore, uint16 newCount);
    event CanvasLocked(uint256 indexed tokenId);
    event CanvasUnlocked(uint256 indexed tokenId);
    event PriceUpdated(string indexed priceType, uint256 indexed identifier, uint256 newPrice); // identifier is paletteId or markType, 0 for evolution
    event CritiquerPermissionUpdated(address indexed critiquer, bool allowed);
    event BaseURIUpdated(string newURI);
    event PaintingCycleStarted(uint256 indexed tokenId, uint16 newCycle);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory initialBaseURI)
        Ownable(msg.sender) // Sets deployer as owner
        Pausable()
    {
        // ERC721 required, but using a name and symbol state is optional if only implementing interface
        // If inheriting a full library, these would be set there. For partial, just note they are expected by standard clients.
        // string public constant name = name; // This syntax is wrong in Solidity for state variables
        // string public constant symbol = symbol;

        _baseMetadataURI = initialBaseURI;
        _tokenCounter = 0;

        // Example initial prices (can be set by owner later)
        evolutionPrice = 0.01 ether; // Example price
        palettePrices[1] = 0.005 ether; // Example price for palette 1
        markPrices[1] = 0.002 ether; // Example price for mark 1
    }

    // --- ERC165 Interface Support ---
    // Required by ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    // --- ERC721 Standard Functions ---

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) {
            revert InvalidRecipient();
        }
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf[tokenId];
        if (owner == address(0)) {
            revert TokenDoesNotExist();
        }
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotApprovedOrOwner();
        }
        if (to == owner) {
            revert ApprovalToCurrentOwner();
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) {
            // Should not grant approval to self as operator for all
            // Reverting might be too strict, but it's a strange case
            // Let's allow but it has no effect
            // require(false, "ERC721: Approve to caller"); // Standard behavior often allows but it's a no-op
        }

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        _transfer(from, to, tokenId);
        if (_isContract(to)) {
            bytes4 selector = IERC721Receiver.onERC721Received.selector;
            (bool success, bytes memory returnData) = to.call(abi.encodeWithSelector(selector, msg.sender, from, tokenId, data));
             if (!success || (returnData.length != 0 && abi.decode(returnData, (bytes4)) != selector)) {
                 revert TransferToERC721ReceiverRejected();
             }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        // This points to a hypothetical off-chain service that serves metadata JSON
        // based on the contract address and token ID, reading the on-chain state.
        return string(abi.encodePacked(_baseMetadataURI, tokenId.toString()));
    }

    // --- Minting Functions ---

    function mintInitialCanvas(address recipient) public payable whenNotPaused returns (uint256) {
        // Basic minting function - maybe requires payment, or is limited
        // Example: free mint, limited supply (not implemented here, but could add max supply)
        if (recipient == address(0)) {
            revert InvalidRecipient();
        }

        _tokenCounter++;
        uint256 newTokenId = _tokenCounter;
        uint256 seed = _generateRandomSeed();

        _canvases[newTokenId] = Canvas({
            traits: _generateInitialTraits(seed),
            stage: 0,
            paintingCycle: 1, // Start at cycle 1
            critiqueScore: 0,
            critiqueCount: 0,
            locked: false,
            signatureMarks: [0, 0, 0, 0, 0] // Initialize signature marks to zero
        });

        _ownerOf[newTokenId] = recipient;
        _balances[recipient]++;

        emit Transfer(address(0), recipient, newTokenId);
        emit CanvasMinted(recipient, newTokenId, seed);

        return newTokenId;
    }

    function mintCanvasWithSeed(address recipient, uint256 seed) public payable whenNotPaused returns (uint256) {
         if (recipient == address(0)) {
            revert InvalidRecipient();
        }
        // Allows specific seed for potentially predictable or verifiable generation
        _tokenCounter++;
        uint256 newTokenId = _tokenCounter;

        _canvases[newTokenId] = Canvas({
            traits: _generateInitialTraits(seed),
            stage: 0,
            paintingCycle: 1,
            critiqueScore: 0,
            critiqueCount: 0,
            locked: false,
            signatureMarks: [0, 0, 0, 0, 0]
        });

        _ownerOf[newTokenId] = recipient;
        _balances[recipient]++;

        emit Transfer(address(0), recipient, newTokenId);
        emit CanvasMinted(recipient, newTokenId, seed);

        return newTokenId;
    }

    // --- Interaction Functions ---

    function evolveCanvas(uint256 tokenId) public payable whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        if (msg.sender != ownerOf(tokenId)) {
             revert NotOwner();
        }
        if (canvas.locked) {
             revert CanvasLocked();
        }
        // Example max stage
        if (canvas.stage >= 5) { // Assume max stage is 5
             revert CanvasMaxStageReached();
        }
        if (msg.value < evolutionPrice) {
             revert InsufficientPayment();
        }

        // Process payment - send difference back or handle exact payment
        if (msg.value > evolutionPrice) {
            payable(msg.sender).transfer(msg.value - evolutionPrice);
        }
        // The received ether stays in the contract, collectable by owner via withdrawFunds()

        canvas.stage++;
        // Evolution might also subtly change traits, e.g., increase magnitude
        for(uint i = 0; i < canvas.traits.length; i++) {
            // Simple example: slightly increase trait value, capping at 255
            canvas.traits[i] = uint8(uint256(canvas.traits[i]).add(10).min(255));
        }

        emit CanvasEvolved(tokenId, canvas.stage);
    }

    function applyPalette(uint256 tokenId, uint8 paletteId) public payable whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
         if (msg.sender != ownerOf(tokenId)) {
             revert NotOwner();
        }
        if (canvas.locked) {
             revert CanvasLocked();
        }
        uint256 price = palettePrices[paletteId];
        if (price == 0) {
            // Palette might be free, or not configured. Assume 0 means not set/invalid or free.
            // Decide contract behavior: require configured price or allow free?
            // Let's require price > 0 for paid palettes, or allow free ones.
             if (msg.value < price) {
                revert InsufficientPayment();
            }
             if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
        } else {
             if (msg.value < price) {
                revert InsufficientPayment();
            }
             if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
        }


        // Example: Apply palette logic - this would be complex and depend on paletteId
        // For demonstration, let's just randomly shift traits based on paletteId
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, paletteId, block.timestamp, block.difficulty)));
        for(uint i = 0; i < canvas.traits.length; i++) {
             // Shift trait value by a small random amount influenced by paletteId and seed
            uint8 shift = uint8((seed >> (i * 8)) % (paletteId + 1) + 1); // Shift between 1 and paletteId+1
            if (seed % 2 == 0) {
                 // Add shift
                 canvas.traits[i] = uint8(uint256(canvas.traits[i]).add(shift).min(255));
            } else {
                 // Subtract shift (handle underflow)
                 canvas.traits[i] = uint8(uint256(canvas.traits[i]).sub(shift).max(0));
            }
        }


        emit PaletteApplied(tokenId, paletteId, canvas.traits);
    }

    function addSignatureMark(uint256 tokenId, uint8 markType) public payable whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
         if (msg.sender != ownerOf(tokenId)) {
             revert NotOwner();
        }
        if (canvas.locked) {
             revert CanvasLocked();
        }
        // Example: Max number of marks of a type
        if (markType >= canvas.signatureMarks.length) {
             revert IndexOutOfRange(); // Mark type index out of bounds
        }
        // Example: Max 3 marks of each type
        if (canvas.signatureMarks[markType] >= 3) {
            // Decide if this should revert or just do nothing
            // Let's revert for clarity
            revert(); // Or a specific error like MaxMarksReached
        }

        uint256 price = markPrices[markType];
         if (price == 0) {
            // Decide if this mark type should be free or requires config
             if (msg.value < price) {
                revert InsufficientPayment();
            }
             if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
         } else {
             if (msg.value < price) {
                revert InsufficientPayment();
            }
             if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
         }


        canvas.signatureMarks[markType]++;

        // Adding a mark might also influence traits or score subtly
        // For example, increasing critique score potential or unlocking new trait ranges

        emit SignatureMarkAdded(tokenId, markType, canvas.signatureMarks[markType]);
    }

     function startPaintingCycle(uint256 tokenId) public payable whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
         if (msg.sender != ownerOf(tokenId)) {
             revert NotOwner();
        }
        if (canvas.locked) {
             revert CanvasLocked();
        }
        // This might require a higher payment or different conditions than evolution
        // Example: Requires a specific payment, maybe based on current cycle
        uint256 cyclePrice = uint256(canvas.paintingCycle).mul(0.001 ether); // Price increases each cycle
         if (msg.value < cyclePrice) {
             revert InsufficientPayment();
         }
          if (msg.value > cyclePrice) {
            payable(msg.sender).transfer(msg.value - cyclePrice);
         }

        canvas.paintingCycle++;
        // Starting a new cycle might reset certain temporary traits,
        // unlock new interactions, or slightly boost base traits.
        // Example: slightly increase base trait values based on cycle number
        uint8 cycleBonus = uint8(canvas.paintingCycle.min(10)); // Cap bonus
         for(uint i = 0; i < canvas.traits.length; i++) {
            canvas.traits[i] = uint8(uint256(canvas.traits[i]).add(cycleBonus).min(255));
        }


        emit PaintingCycleStarted(tokenId, canvas.paintingCycle);
    }


    function critiqueCanvas(uint256 tokenId, uint8 critiqueScore) public whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        if (!_allowedCritiquers[msg.sender]) {
             revert NotAllowedCritiquer();
        }
        if (critiqueScore > 10) { // Example: Score from 0-10
             revert InvalidCritiqueScore();
        }
         if (canvas.locked) {
             revert CanvasLocked(); // Critiquing might be disallowed on locked canvases
        }


        canvas.critiqueScore += critiqueScore;
        canvas.critiqueCount++;

        // The average score could be calculated off-chain for metadata display.
        // The raw sum and count are stored on-chain.

        emit CritiqueReceived(tokenId, msg.sender, critiqueScore, canvas.critiqueScore, canvas.critiqueCount);
    }

    function lockCanvas(uint256 tokenId) public whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
         if (msg.sender != ownerOf(tokenId)) {
             revert NotOwner();
        }

        canvas.locked = true;
        emit CanvasLocked(tokenId);
    }

    function unlockCanvas(uint256 tokenId) public whenNotPaused {
        Canvas storage canvas = _canvases[tokenId];
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
         if (msg.sender != ownerOf(tokenId)) {
             revert NotOwner();
        }

        canvas.locked = false;
        emit CanvasUnlocked(tokenId);
    }

    // --- Getter Functions ---

    function getCanvasTraits(uint256 tokenId) public view returns (uint8[5] memory) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return _canvases[tokenId].traits;
    }

    function getCanvasStage(uint256 tokenId) public view returns (uint8) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return _canvases[tokenId].stage;
    }

     function getCanvasPaintingCycle(uint256 tokenId) public view returns (uint16) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return _canvases[tokenId].paintingCycle;
    }

    function getCanvasCritiqueScore(uint256 tokenId) public view returns (uint16, uint16) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return (_canvases[tokenId].critiqueScore, _canvases[tokenId].critiqueCount);
    }

    function getCanvasLockedStatus(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        return _canvases[tokenId].locked;
    }

    function getBaseMetadataURI() public view returns (string memory) {
        return _baseMetadataURI;
    }

    function getCanvasEvolutionPrice() public view returns (uint256) {
        return evolutionPrice;
    }

    function getPaletteApplicationPrice(uint8 paletteId) public view returns (uint256) {
        return palettePrices[paletteId];
    }

    function getSignatureMarkPrice(uint8 markType) public view returns (uint256) {
         if (markType >= 5) {
             revert IndexOutOfRange(); // Match array size
        }
        return markPrices[markType];
    }

    function isAllowedCritiquer(address addr) public view returns (bool) {
        return _allowedCritiquers[addr];
    }

    function getTotalCanvases() public view returns (uint256) {
        return _tokenCounter;
    }

     function getCanvasData(uint256 tokenId) public view returns (
        uint8[5] memory traits,
        uint8 stage,
        uint16 paintingCycle,
        uint16 critiqueScore,
        uint16 critiqueCount,
        bool locked,
        uint8[5] memory signatureMarks
    ) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist();
        }
        Canvas storage canvas = _canvases[tokenId];
        return (
            canvas.traits,
            canvas.stage,
            canvas.paintingCycle,
            canvas.critiqueScore,
            canvas.critiqueCount,
            canvas.locked,
            canvas.signatureMarks
        );
    }

    function getTraitDefinition(uint8 traitType) public view returns (string memory) {
         if bytes(_traitDefinitions[traitType]).length == 0) {
            revert TraitTypeDoesNotExist();
        }
        return _traitDefinitions[traitType];
    }


    // --- Admin Functions (Ownable) ---

    function setBaseMetadataURI(string memory newURI) public onlyOwner {
        _baseMetadataURI = newURI;
        emit BaseURIUpdated(newURI);
    }

    function setCanvasEvolutionPrice(uint256 price) public onlyOwner {
        evolutionPrice = price;
        emit PriceUpdated("Evolution", 0, price); // 0 identifier for evolution
    }

    function setPaletteApplicationPrice(uint8 paletteId, uint256 price) public onlyOwner {
         palettePrices[paletteId] = price;
         emit PriceUpdated("Palette", paletteId, price);
    }

    function setSignatureMarkPrice(uint8 markType, uint256 price) public onlyOwner {
         if (markType >= 5) {
             revert IndexOutOfRange();
        }
        markPrices[markType] = price;
        emit PriceUpdated("SignatureMark", markType, price);
    }

    function setAllowedCritiquer(address addr, bool allowed) public onlyOwner {
        _allowedCritiquers[addr] = allowed;
        emit CritiquerPermissionUpdated(addr, allowed);
    }

    function setTraitDefinition(uint8 traitType, string memory definition) public onlyOwner {
         if (traitType >= 5) {
             revert IndexOutOfRange(); // Match trait array size
        }
        _traitDefinitions[traitType] = definition;
    }

    // Override Pausable's pause/unpause to make them public owned functions
    function pause() public onlyOwner override {
        _pause();
    }

    function unpause() public onlyOwner override {
        _unpause();
    }

    // Allows the owner to withdraw any Ether collected by the contract
    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    // --- Internal Helper Functions ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != from) {
             revert TransferFromIncorrectOwner();
        }
         if (to == address(0)) {
             revert InvalidRecipient();
        }
        if (canvasLocked(tokenId)) {
             revert CanvasLocked(); // Prevent transfer of locked canvas? Or only state changes? Decide policy. Let's allow transfer but keep it locked.
        }


        // Clear approvals
        _approve(address(0), tokenId);

        _balances[from]--;
        _ownerOf[tokenId] = to;
        _balances[to]++;

        emit Transfer(from, to, tokenId);
    }

    // Helper function to check if address is a contract
    // Note: This check is not foolproof against certain types of contracts or during construction.
    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts during construction.
        // It also returns false for internally-created contracts.
        // See https://eips.ethereum.org/EIPS/eip-1052
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    // --- Randomness Simulation (INSECURE FOR PRODUCTION) ---
    // This uses block data which can potentially be manipulated by miners.
    // For production, use a secure oracle like Chainlink VRF.
    function _generateRandomSeed() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenCounter)));
    }

    function _generateInitialTraits(uint256 seed) internal pure returns (uint8[5] memory) {
        uint8[5] memory traits;
        // Example: generate 5 trait values between 0 and 255 based on the seed
        traits[0] = uint8((seed >> 0) % 256);
        traits[1] = uint8((seed >> 8) % 256);
        traits[2] = uint8((seed >> 16) % 256);
        traits[3] = uint8((seed >> 24) % 256);
        traits[4] = uint8((seed >> 32) % 256); // Use more bits of the seed

        return traits;
    }

     // --- Internal Approval Logic ---
     function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // Check if 'spender' is approved or is the owner
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Custom helper based on OpenZeppelin's uint256 library for basic arithmetic
    // (Avoiding full library import for brevity, but recommended for safety)
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
         require(b <= a, "Subtraction underflow");
         return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

}
```