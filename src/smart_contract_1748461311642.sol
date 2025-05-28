Okay, here is a Solidity smart contract for a Generative Digital Art Collection.

**Concept:** This contract creates NFTs where the "art" (represented by on-chain data/parameters) is generated at mint time based on blockchain data and evolves over time or through owner interaction. The actual visual rendering happens off-chain by interpreting the on-chain data retrieved via the `tokenURI`. This makes the NFTs dynamic.

**Advanced Concepts Used:**

1.  **On-chain Parameterization & Pseudo-Randomness:** Using block data and transaction details (`block.number`, `block.timestamp`, `msg.sender`, `tx.origin`, `block.difficulty`) along with a counter to generate a unique, deterministic seed for each NFT at mint. While not cryptographically secure randomness, it provides a basis for diverse initial states derived solely from on-chain activity.
2.  **Dynamic NFT Data:** The core art data (`ArtData` struct) is stored on-chain and can change (`nurtureArt`, `addModifier`). The `tokenURI` doesn't point to a static file but to a base URI + token ID, indicating that an external service should fetch the *current* on-chain data to render the art.
3.  **Evolution Mechanism:** The art "evolves" based on time since creation/last nurture and owner interaction count, influencing derived traits (`getEvolutionStage`, `getTraits`).
4.  **Owner Interaction (Nurturing):** A specific function (`nurtureArt`) allows owners to interact with their art, updating its state and potentially influencing its evolution or traits.
5.  **On-chain Derived Traits:** Instead of fixed metadata, traits are calculated *on-demand* based on the core `seed` and the current evolutionary state.
6.  **Modifier System:** A simple system to add unique, non-standard modifiers to art pieces.
7.  **ERC2981 Royalties:** Implementing the standard for NFT royalties.
8.  **Pausable & Ownable:** Standard but crucial patterns for contract management and safety.

---

### **Smart Contract Outline and Function Summary**

**Contract Name:** `GenerativeDigitalArtCollection`

**Description:** An ERC721 compliant contract for a collection of generative digital art NFTs. Each piece of art is defined by a unique on-chain seed and evolves based on time and owner interaction. Metadata is dynamic and points to an external renderer.

**Inherits:**
*   `ERC721` (OpenZeppelin)
*   `ERC2981` (OpenZeppelin)
*   `Ownable` (OpenZeppelin)
*   `Pausable` (OpenZeppelin)
*   `ERC165` (OpenZeppelin - implicit via inheritance)

**State Variables:**
*   `_nextTokenId`: Counter for the next available token ID.
*   `_artData`: Mapping from token ID to `ArtData` struct.
*   `_artModifiers`: Mapping from token ID to an array of modifier IDs (uint).
*   `_baseTokenURI`: The base URI for metadata, expected to be an endpoint that takes `/tokenId`.
*   `_mintPrice`: Price to mint a new token.
*   `_royaltyNumerator`: Numerator for default royalty calculations (e.g., 500 for 5%).

**Structs:**
*   `ArtData`: Stores core on-chain data for each art piece (`seed`, `creationTime`, `lastNurtureTime`, `nurtureCount`).

**Events:**
*   `ArtMinted`: Emitted when a new token is minted.
*   `ArtNurtured`: Emitted when an art piece is nurtured.
*   `ModifierAdded`: Emitted when a modifier is added to an art piece.
*   `BaseURISet`: Emitted when the base URI is updated.

**Functions:**

1.  `constructor(string memory name, string memory symbol, uint256 initialMintPrice, uint96 defaultRoyaltyBasisPoints)`: Initializes the contract, name, symbol, mint price, and default royalty.
2.  `mint()`: Mints a new art token. Requires `_mintPrice`. Generates a unique seed based on blockchain data. Sets initial `ArtData`.
3.  `tokenURI(uint256 tokenId) public view override returns (string memory)`: Returns the dynamic metadata URI for a given token ID. Calls `_baseURI()`.
4.  `_baseURI() internal view virtual returns (string memory)`: Internal helper to get the base URI.
5.  `setBaseURI(string memory newBaseURI) public onlyOwner`: Allows the contract owner to update the base URI for metadata.
6.  `getArtData(uint256 tokenId) public view returns (ArtData memory)`: Retrieves the full `ArtData` struct for a token.
7.  `nurtureArt(uint256 tokenId) public payable whenNotPaused`: Allows the owner of a token to "nurture" it. Updates `lastNurtureTime` and `nurtureCount`. Can optionally require a small fee (`msg.value`).
8.  `getEvolutionStage(uint256 tokenId) public view returns (string memory)`: Calculates and returns a string representing the current evolutionary stage based on time and nurture count.
9.  `getTraits(uint256 tokenId) public view returns (string[] memory)`: Calculates and returns an array of strings representing the *derived* traits based on the seed and current evolutionary state.
10. `addModifier(uint256 tokenId, uint256 modifierId) public whenNotPaused`: Allows the owner of a token to add a specific modifier ID to their art piece.
11. `getModifiers(uint256 tokenId) public view returns (uint256[] memory)`: Retrieves the list of modifier IDs associated with a token.
12. `royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount)`: Implements ERC2981; returns the default royalty receiver (contract owner) and amount.
13. `supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool)`: Implements ERC165, indicating support for ERC721, ERC2981, and Ownable/Pausable interfaces.
14. `pause() public onlyOwner whenNotPaused`: Pauses the contract, preventing sensitive actions like minting or nurturing.
15. `unpause() public onlyOwner whenPaused`: Unpauses the contract.
16. `paused() public view override returns (bool)`: Returns current pause status.
17. `withdrawFunds() public onlyOwner`: Allows the contract owner to withdraw collected funds (from minting/nurturing).
18. `transferOwnership(address newOwner) public override onlyOwner`: Transfers contract ownership.
19. `owner() public view override returns (address)`: Returns the current contract owner.
20. `balanceOf(address owner) public view override returns (uint256)`: Returns the number of tokens owned by an address (ERC721).
21. `ownerOf(uint256 tokenId) public view override returns (address)`: Returns the owner of a specific token (ERC721).
22. `transferFrom(address from, address to, uint256 tokenId) public payable override whenNotPaused`: Transfers token ownership (ERC721).
23. `safeTransferFrom(address from, address to, uint256 tokenId) public payable override whenNotPaused`: Transfers token ownership safely (ERC721).
24. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override whenNotPaused`: Transfers token ownership safely with data (ERC721).
25. `approve(address to, uint256 tokenId) public override whenNotPaused`: Approves an address to transfer a token (ERC721).
26. `getApproved(uint256 tokenId) public view override returns (address)`: Gets the approved address for a token (ERC721).
27. `setApprovalForAll(address operator, bool approved) public override`: Sets approval for an operator for all tokens (ERC721).
28. `isApprovedForAll(address owner, address operator) public view override returns (bool)`: Checks if an operator is approved for all tokens (ERC721).
29. `name() public view override returns (string memory)`: Returns the collection name (ERC721).
30. `symbol() public view override returns (string memory)`: Returns the collection symbol (ERC721).
31. `totalSupply() public view returns (uint256)`: Returns the total number of tokens minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Optional, but adds tokenByIndex, etc. Adding it for more standard functions.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Not using URIStorage, but keeping standard imports pattern.
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // Standard for NFT royalties.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Custom Errors for better clarity and gas efficiency
error GenerativeArt__InvalidTokenId();
error GenerativeArt__OnlyTokenOwner();
error GenerativeArt__MintPriceNotMet(uint256 requiredPrice, uint256 sentAmount);
error GenerativeArt__WithdrawTransferFailed();

/**
 * @title GenerativeDigitalArtCollection
 * @dev An ERC721 contract for a collection of generative digital art NFTs.
 * Art is defined by on-chain parameters and evolves based on time and interaction.
 * Metadata is dynamic, pointing to an external renderer that interprets on-chain data.
 */
contract GenerativeDigitalArtCollection is ERC721, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _nextTokenId;

    struct ArtData {
        uint256 seed;             // Deterministic seed generated at mint
        uint64 creationTime;      // Timestamp of creation
        uint64 lastNurtureTime;   // Timestamp of last nurture interaction
        uint32 nurtureCount;      // Number of times nurtured
        // Add more core parameters here if needed
    }

    // Mapping from token ID to its core generative data
    mapping(uint256 tokenId => ArtData data) private _artData;

    // Mapping from token ID to an array of associated modifier IDs
    mapping(uint256 tokenId => uint256[] modifiers) private _artModifiers;

    // Base URI for metadata endpoint (e.g., "https://api.myartproject.com/metadata/")
    // The endpoint should handle /tokenId requests and fetch on-chain data.
    string private _baseTokenURI;

    // Price to mint a new token
    uint256 public immutable _mintPrice;

    // Default royalty numerator (e.g., 500 for 5%)
    uint96 public immutable _royaltyNumerator;

    // --- Events ---
    event ArtMinted(address indexed owner, uint256 indexed tokenId, uint256 seed);
    event ArtNurtured(uint256 indexed tokenId, uint64 nurtureTime, uint32 nurtureCount);
    event ModifierAdded(uint256 indexed tokenId, uint256 modifierId);
    event BaseURISet(string newBaseURI);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialMintPrice,
        uint96 defaultRoyaltyBasisPoints // e.g., 500 for 5%
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(defaultRoyaltyBasisPoints <= 10000, "Royalty basis points too high");
        _mintPrice = initialMintPrice;
        _royaltyNumerator = defaultRoyaltyBasisPoints;
        // _baseTokenURI should be set via setBaseURI after deployment
    }

    // --- Core Generative / Dynamic Functions ---

    /**
     * @dev Mints a new generative art token.
     * @param _to The address to mint the token to.
     * @return The ID of the newly minted token.
     */
    function mint() public payable whenNotPaused returns (uint256) {
        if (msg.value < _mintPrice) {
            revert GenerativeArt__MintPriceNotMet({requiredPrice: _mintPrice, sentAmount: msg.value});
        }

        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        // Generate a seed based on potentially diverse on-chain factors
        // NOTE: This is pseudo-randomness. Do not rely on it for security-sensitive applications.
        // Attackers might try to influence these parameters by controlling transaction details.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            msg.sender,
            block.number,
            block.timestamp,
            block.difficulty, // Included for added entropy pre-PoS, less relevant post-PoS but harmless
            tx.gasprice,    // Gas price can influence tx ordering
            newTokenId      // Include token ID for uniqueness even if other factors repeat
        )));

        _safeMint(msg.sender, newTokenId); // Mint to the caller by default

        _artData[newTokenId] = ArtData({
            seed: seed,
            creationTime: uint64(block.timestamp),
            lastNurtureTime: uint64(block.timestamp), // Start nurtured
            nurtureCount: 0 // Start with 0, increment on first nurture
        });

        emit ArtMinted(msg.sender, newTokenId, seed);

        return newTokenId;
    }

    /**
     * @dev Allows the token owner to "nurture" their art.
     * This interaction updates the art's state and influences its evolution.
     * Can optionally require a small fee.
     * @param tokenId The ID of the token to nurture.
     */
    function nurtureArt(uint256 tokenId) public payable whenNotPaused {
        if (_ownerOf(tokenId) != msg.sender) {
            revert GenerativeArt__OnlyTokenOwner();
        }

        ArtData storage art = _artData[tokenId];
        art.lastNurtureTime = uint64(block.timestamp);
        art.nurtureCount++;

        // Optional: Require a small fee for nurturing
        // uint256 nurtureFee = 0.001 ether; // Example fee
        // if (msg.value < nurtureFee) {
        //     revert GenerativeArt__NurtureFeeNotMet({requiredFee: nurtureFee, sentAmount: msg.value});
        // }

        emit ArtNurtured(tokenId, art.lastNurtureTime, art.nurtureCount);
    }

    /**
     * @dev Allows the token owner to add a specific modifier to their art.
     * Modifier IDs could represent different types of enhancements or attributes.
     * @param tokenId The ID of the token.
     * @param modifierId The ID of the modifier to add.
     */
    function addModifier(uint256 tokenId, uint256 modifierId) public whenNotPaused {
        if (_ownerOf(tokenId) != msg.sender) {
            revert GenerativeArt__OnlyTokenOwner();
        }
        // Consider adding checks here, e.g., prevent duplicate modifiers, limit number of modifiers, etc.

        _artModifiers[tokenId].push(modifierId);

        emit ModifierAdded(tokenId, modifierId);
    }

    // --- View Functions for Dynamic Data ---

    /**
     * @dev Returns the base URI for the token metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI for the token metadata. Only owner.
     * This URI is expected to be an endpoint that serves dynamic metadata based on tokenId.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /**
     * @dev Gets the core generative data for a token.
     * An external renderer would call this to fetch the parameters to render the art.
     * @param tokenId The ID of the token.
     * @return The ArtData struct for the token.
     */
    function getArtData(uint256 tokenId) public view returns (ArtData memory) {
        _requireOwned(tokenId); // Ensure token exists by checking ownership/existence
        return _artData[tokenId];
    }

    /**
     * @dev Calculates and returns the current evolutionary stage of the art.
     * This is a derived property based on time and nurture count.
     * Implement complex logic here based on your desired evolution mechanics.
     * @param tokenId The ID of the token.
     * @return A string representing the evolution stage.
     */
    function getEvolutionStage(uint256 tokenId) public view returns (string memory) {
        _requireOwned(tokenId);
        ArtData memory art = _artData[tokenId];
        uint256 ageInSeconds = block.timestamp - art.creationTime;
        uint256 timeSinceNurture = block.timestamp - art.lastNurtureTime;

        // Example simple evolution logic:
        if (ageInSeconds < 1 days) {
            return "Seedling";
        } else if (ageInSeconds < 7 days) {
            if (timeSinceNurture < 1 days && art.nurtureCount >= 1) {
                 return "Sprout (Thriving)";
            } else {
                 return "Sprout";
            }
        } else if (ageInSeconds < 30 days) {
             if (timeSinceNurture < 3 days && art.nurtureCount >= 5) {
                 return "Young Plant (Vigorous)";
            } else {
                 return "Young Plant";
            }
        } else { // Older than 30 days
             if (timeSinceNurture < 7 days && art.nurtureCount >= 10) {
                 return "Mature";
            } else {
                 return "Mature (Stagnant)";
            }
        }
        // More complex stages could depend on specific nurtureCount milestones, etc.
    }

    /**
     * @dev Calculates and returns an array of derived traits for the art.
     * Traits are determined algorithmically from the seed and current state.
     * Implement complex trait generation logic here.
     * @param tokenId The ID of the token.
     * @return An array of strings representing the art's traits.
     */
    function getTraits(uint256 tokenId) public view returns (string[] memory) {
        _requireOwned(tokenId);
        ArtData memory art = _artData[tokenId];
        uint256 seed = art.seed;

        // Example simple trait derivation based on seed and evolution
        uint256 trait1 = (seed >> 16) % 100; // Example: color property
        uint256 trait2 = (seed >> 8) % 50;  // Example: shape property
        uint256 trait3 = seed % 256;      // Example: texture property

        string memory evolutionStage = getEvolutionStage(tokenId); // Use evolution state

        string[] memory traits = new string[](4); // Adjust size based on number of traits

        traits[0] = string(abi.encodePacked("Evolution Stage: ", evolutionStage));

        // Example: Map seed values to trait names (simplified)
        if (trait1 < 20) { traits[1] = "Color: Red"; }
        else if (trait1 < 50) { traits[1] = "Color: Blue"; }
        else if (trait1 < 80) { traits[1] = "Color: Green"; }
        else { traits[1] = "Color: Yellow"; }

        if (trait2 < 10) { traits[2] = "Shape: Circle"; }
        else if (trait2 < 30) { traits[2] = "Shape: Square"; }
        else { traits[2] = "Shape: Triangle"; }

         if (trait3 < 100) { traits[3] = "Texture: Smooth"; }
        else if (trait3 < 200) { traits[3] = "Texture: Rough"; }
        else { traits[3] = "Texture: Patterned"; }

        // You could make traits also depend on nurture count or modifiers

        return traits;
    }

    /**
     * @dev Gets the list of modifier IDs applied to a token.
     * @param tokenId The ID of the token.
     * @return An array of modifier IDs.
     */
    function getModifiers(uint256 tokenId) public view returns (uint256[] memory) {
         _requireOwned(tokenId);
        return _artModifiers[tokenId];
    }


    // --- ERC721 Standard Functions (Overridden and Pausable) ---

    // Override transfer functions to add Pausable modifier
    function transferFrom(address from, address to, uint256 tokenId) public payable override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused {
        super.approve(to, tokenId);
    }

    // setApprovalForAll does not modify the state of the token itself,
    // only the operator mapping, so it might not strictly need Pausable depending
    // on desired contract behavior, but including for consistency.
    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }


    // ERC721 View functions
    function name() public view override returns (string memory) {
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        return super.symbol();
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    // Total supply (from Counters)
     function totalSupply() public view returns (uint256) {
        return _nextTokenId.current();
    }


    // --- ERC2981 Royalties ---

    /**
     * @dev See {IERC2981-royaltyInfo}.
     * Sets a default royalty for all tokens in this collection.
     * Can be overridden to implement per-token royalties if needed.
     */
    function royaltyInfo(uint256 /* _tokenId */, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // Default royalty goes to the contract owner
        receiver = owner();
        royaltyAmount = (salePrice * _royaltyNumerator) / 10000;
        return (receiver, royaltyAmount);
    }

    // --- Pausable ---

    // Access control handled by Ownable modifier on pause/unpause functions
    function paused() public view override returns (bool) {
        return super.paused();
    }

    // --- Ownership ---

    // Access control handled by Ownable modifier on transferOwnership
    function owner() public view override returns (address) {
        return super.owner();
    }


    // --- ERC165 Support ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(Ownable).interfaceId || // Ownable also uses ERC165
            interfaceId == type(Pausable).interfaceId || // Pausable might not have a dedicated interface, check OZ docs
            super.supportsInterface(interfaceId);
    }

    // --- Withdrawal ---

    /**
     * @dev Allows the contract owner to withdraw any Ether collected from minting/nurturing.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(owner()).call{value: balance}("");
            if (!success) {
                revert GenerativeArt__WithdrawTransferFailed();
            }
        }
    }

    // --- Internal Helpers ---

    /**
     * @dev Throws if the token ID is not valid (does not have an owner).
     */
    function _requireOwned(uint256 tokenId) internal view {
        if (_ownerOf(tokenId) == address(0)) {
            revert GenerativeArt__InvalidTokenId();
        }
    }

    // The rest of ERC721 internal functions like _safeMint, _transfer, _beforeTokenTransfer, _afterTokenTransfer
    // are handled by inheriting from OpenZeppelin's ERC721 and ERC721Enumerable.
    // If ERC721Enumerable was included, these functions would also be available:
    // tokenOfOwnerByIndex(address owner, uint256 index)
    // tokenByIndex(uint256 index)
}
```

**Explanation:**

1.  **Imports:** Imports necessary standard libraries from OpenZeppelin for common patterns (ERC721, ERC2981, Ownable, Pausable, Counters, Strings, ERC165).
2.  **Errors:** Uses custom errors (Solidity ^0.8.4) for more informative and gas-efficient error handling.
3.  **State Variables & Structs:** Defines the core state: the token counter, the `ArtData` struct holding the unique generative parameters for each token, a mapping for arbitrary `_artModifiers`, the `_baseTokenURI` for dynamic metadata, the `_mintPrice`, and the default `_royaltyNumerator`.
4.  **Events:** Standard events to signal important actions like minting, nurturing, etc.
5.  **Constructor:** Sets the name, symbol, mint price, and royalty basis points. It also initializes `Ownable` with the deployer as the owner.
6.  **`mint()`:** This is the core creation function. It requires `_mintPrice` to be paid. It increments the token counter, generates a `seed` using a combination of blockchain variables and the new token ID (for pseudo-randomness), mints the ERC721 token, and stores the initial `ArtData` for the token, including the creation time.
7.  **`tokenURI()` & `_baseURI()` & `setBaseURI()`:** `tokenURI` is overridden to return `_baseTokenURI + tokenId.toString()`. This tells platforms/wallets to look for metadata at a dynamic endpoint. `setBaseURI` allows the owner to update this endpoint if needed (e.g., migrating the metadata service). The external service receiving the request for `baseURI/123` would then call view functions on the contract like `getArtData(123)`, `getTraits(123)`, `getModifiers(123)` to fetch the *current* state and construct the metadata and potentially render the image/visual representation off-chain.
8.  **`getArtData()`:** A simple view function to expose the raw on-chain data for a specific token.
9.  **`nurtureArt()`:** An owner-only function (`_ownerOf(tokenId) == msg.sender`) that updates the `lastNurtureTime` and increments the `nurtureCount`. This interaction is recorded and can influence the derived traits and evolution stage. It's marked `payable` in case you want to add an optional nurture fee later.
10. **`getEvolutionStage()`:** A view function that implements the logic for calculating the current "stage" of the art based on its age and how often/recently it's been nurtured. The example is simple time-based staging, but you can implement more complex rules.
11. **`getTraits()`:** A view function that demonstrates how to derive traits *deterministically* from the token's `seed` and potentially its current state (`evolutionStage`, `nurtureCount`, etc.). This means the traits are not fixed at mint but can conceptually change as the art evolves, although the example derivation uses the seed primarily.
12. **`addModifier()` & `getModifiers()`:** A simple system where the owner can add arbitrary `modifierId`s to their art piece, stored in an array. This could represent adding visual effects, frames, etc., which the off-chain renderer would interpret. `getModifiers` allows fetching these.
13. **ERC721 Overrides:** Standard ERC721 transfer and approval functions are overridden primarily to add the `whenNotPaused` modifier, ensuring transfers/approvals are disabled if the contract is paused.
14. **`royaltyInfo()`:** Implements the ERC2981 standard, defining a default royalty percentage (`_royaltyNumerator`) that goes to the contract owner for all tokens.
15. **Pausable:** Inherits `Pausable` and uses the `whenNotPaused` and `whenPaused` modifiers to allow the owner to halt certain core contract interactions in an emergency.
16. **Ownable:** Inherits `Ownable` to provide basic access control for sensitive functions like `setBaseURI`, `pause`, `unpause`, and `withdrawFunds`.
17. **`supportsInterface()`:** Implements ERC165 to signal which standard interfaces the contract supports (ERC721, ERC2981, Ownable, Pausable).
18. **`withdrawFunds()`:** Allows the contract owner to extract any Ether sent to the contract (from minting or nurture fees).
19. **`_requireOwned()`:** Internal helper to check if a token ID is valid by verifying it has an owner.

This contract provides a solid foundation for a dynamic, generative NFT collection where the art's state is managed on-chain and can evolve, offering a more interactive experience than traditional static NFTs. Remember that the actual visual art generation is the responsibility of an external service that interacts with this contract's view functions.