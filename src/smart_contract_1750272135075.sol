Okay, here is a smart contract concept that combines several advanced and creative ideas: a "Generative Art Passport". This contract issues Soulbound Tokens (non-transferable NFTs) that represent a user's on-chain identity. The unique twist is that the *traits* and thus the associated generative art for each passport dynamically evolve based on the owner's on-chain activities, linked asset holdings, and successful participation in challenges or attestations.

**Concept:** Generative Art Passport (Soulbound)

**Core Ideas:**
1.  **Soulbound Identity:** Tokens are non-transferable, anchoring them to a specific address as a form of identity.
2.  **Dynamic Generative Art:** The NFT's metadata and associated artwork are generated based on specific on-chain traits.
3.  **On-Chain Trait Logic:** The contract includes logic to derive traits from different sources.
4.  **Activity & Holding Based Traits:** Traits evolve based on the owner's interaction with this contract or their holdings of other specified ERC20/ERC721 tokens.
5.  **Attestation System:** Trusted third parties (Attestors) can add verifiable data/credentials to the passport, influencing traits.
6.  **Challenge System:** Owners can complete on-chain challenges to unlock new traits or evolve their passport.
7.  **Trait Visibility Control:** Passport owners can choose to hide certain traits from public metadata view (though the trait data itself remains on-chain and potentially influences the art).
8.  **On-Chain Randomness:** A simple mechanism to introduce unpredictable elements into trait generation.

---

**Contract Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary OpenZeppelin contracts (ERC721, Ownable, Pausable).
2.  **Error Definitions:** Custom errors for clarity.
3.  **Events:** Announce key actions (Mint, Trait Update, Challenge, Attestation, etc.).
4.  **State Variables:**
    *   Token Counter (`_tokenIdCounter`).
    *   Mappings for traits (`_tokenTraits`).
    *   Mappings for trait visibility (`_traitVisibility`).
    *   Mappings for challenges (`_challenges`, `_completedChallenges`).
    *   Mappings for Attestor roles (`_attestors`).
    *   Mappings for linked assets (ERC20/ERC721) that influence traits.
    *   Base URI for metadata (`_baseURI`).
5.  **Modifiers:** Access control (`onlyOwner`, `onlyAttestor`), state control (`whenNotPaused`, `whenPaused`), ownership check (`onlyPassportOwner`).
6.  **Constructor:** Initialize base URI, owner.
7.  **ERC721 Overrides:**
    *   `_beforeTokenTransfer`: Implement soulbound logic (prevent all transfers except minting/burning by owner).
    *   `tokenURI`: Point to a dynamic metadata service based on `_baseURI` and `tokenId`.
    *   Disable `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`.
8.  **Minting:**
    *   `mintPassport`: Create a new token for a user. Generate initial traits.
9.  **Trait Management & Generation:**
    *   `_storeTrait`: Internal function to save a trait and trigger metadata update.
    *   `_getTrait`: Internal getter for trait data.
    *   `getTraits`: Public view function to get all traits for a token (respecting visibility).
    *   `getTrait`: Public view function for a specific trait (respecting visibility).
    *   `setTraitVisibility`: Allows owner to toggle visibility of a trait.
    *   `getTraitVisibility`: Check visibility status.
    *   `requestMetadataUpdate`: Owner can request metadata refresh after off-chain changes.
    *   `checkAndApplyActivityTraits`: Update traits based on simple contract interaction count or similar.
    *   `checkAndApplyTokenHoldingTraits`: Update traits based on linked ERC20 balances.
    *   `checkAndApplyNFTCollectionTraits`: Update traits based on linked ERC721/ERC1155 holdings.
    *   `reRollRandomTrait`: Generate and store a trait based on simple on-chain randomness.
10. **Attestation System:**
    *   `grantAttestorRole`: Owner grants role.
    *   `revokeAttestorRole`: Owner revokes role.
    *   `attestData`: Attestor adds structured data (interpreted as traits) to a passport.
11. **Challenge System:**
    *   `createChallenge`: Owner defines a challenge.
    *   `completeChallenge`: User proves completion (abstract proof), updates challenge trait.
    *   `getChallenge`: View challenge details.
    *   `getCompletedChallenges`: View challenges completed by a passport.
12. **Admin/Configuration:**
    *   `setBaseURI`: Update metadata base URI.
    *   `setLinkedToken`: Enable/disable specific ERC20s for trait checks.
    *   `setLinkedNFTCollection`: Enable/disable specific NFT collections for trait checks.
    *   `pause`, `unpause`: Pause/unpause the contract (e.g., for upgrades or maintenance).
    *   `withdraw`: Owner withdraws ETH (if any received, though this contract isn't designed to receive ETH typically).

---

**Function Summary:**

1.  `balanceOf(address owner) public view returns (uint256)`: Inherited ERC721. Returns the number of passports owned by an address.
2.  `ownerOf(uint256 tokenId) public view returns (address)`: Inherited ERC721. Returns the owner of a specific passport.
3.  `tokenURI(uint256 tokenId) public view returns (string memory)`: Inherited ERC721 (overridden). Returns the URI for the metadata JSON of a passport. Points to a dynamic service.
4.  `mintPassport(address recipient) public virtual onlyOwner`: Mints a new soulbound passport NFT to the recipient. Generates initial traits.
5.  `getTraits(uint256 tokenId) public view returns (string[] memory traitKeys, bytes[] memory traitValues)`: Retrieves all traits associated with a passport, *respecting the owner's visibility settings*.
6.  `getTrait(uint256 tokenId, string calldata traitKey) public view returns (bytes memory traitValue)`: Retrieves a specific trait's value for a passport, *respecting the owner's visibility setting*.
7.  `setTraitVisibility(uint256 tokenId, string calldata traitKey, bool visible) public onlyPassportOwner(tokenId)`: Allows the passport owner to toggle the visibility of a specific trait in public getters (`getTraits`, `getTrait`). Does *not* remove the trait data or prevent it from influencing the art rendered by the off-chain service.
8.  `getTraitVisibility(uint256 tokenId, string calldata traitKey) public view returns (bool)`: Checks the visibility status of a specific trait for a passport.
9.  `requestMetadataUpdate(uint256 tokenId) public onlyPassportOwner(tokenId)`: Allows the passport owner to trigger a refresh signal, prompting the off-chain metadata service to re-fetch traits and update metadata/art cache.
10. `checkAndApplyActivityTraits(uint256 tokenId) public onlyPassportOwner(tokenId)`: Owner triggers an update of traits based on their on-chain activity related to this contract (e.g., number of functions called, time since mint).
11. `checkAndApplyTokenHoldingTraits(uint256 tokenId) public onlyPassportOwner(tokenId)`: Owner triggers an update of traits based on their balances of configured linked ERC20 tokens.
12. `checkAndApplyNFTCollectionTraits(uint256 tokenId) public onlyPassportOwner(tokenId)`: Owner triggers an update of traits based on their holdings in configured linked ERC721/ERC1155 collections.
13. `reRollRandomTrait(uint256 tokenId) public onlyPassportOwner(tokenId)`: Generates a new trait value using a simple on-chain pseudo-random source and applies it. *Note: On-chain randomness is insecure; use Chainlink VRF or similar for production randomness.*
14. `grantAttestorRole(address attestor) public onlyOwner`: Grants the `ATTESTOR_ROLE` to an address, allowing them to call `attestData`.
15. `revokeAttestorRole(address attestor) public onlyOwner`: Revokes the `ATTESTOR_ROLE` from an address.
16. `attestData(uint256 tokenId, string calldata key, bytes calldata value) public onlyAttestor`: Allows an account with the `ATTESTOR_ROLE` to add a specific key-value data point (interpreted as a trait) to a passport.
17. `createChallenge(bytes32 challengeId, string calldata description, uint256 expiryTimestamp) public onlyOwner`: Creates a new challenge that passport owners can attempt to complete.
18. `completeChallenge(uint256 tokenId, bytes32 challengeId, bytes calldata proof) public onlyPassportOwner(tokenId)`: Marks a challenge as completed for a specific passport owner. Requires a proof (implementation of proof verification is abstract here and depends on the challenge type). Updates completion trait.
19. `getChallenge(bytes32 challengeId) public view returns (string memory description, uint256 expiryTimestamp, bool exists)`: Retrieves details of a specific challenge.
20. `getCompletedChallenges(uint256 tokenId) public view returns (bytes32[] memory)`: Returns a list of challenge IDs completed by a passport owner.
21. `setBaseURI(string memory newBaseURI) public onlyOwner`: Sets the base URI used in `tokenURI`.
22. `setLinkedToken(address tokenAddress, bool enabled) public onlyOwner`: Configures an ERC20 token address to be checked by `checkAndApplyTokenHoldingTraits`.
23. `setLinkedNFTCollection(address collectionAddress, bool enabled) public onlyOwner`: Configures an NFT collection address to be checked by `checkAndApplyNFTCollectionTraits`.
24. `pause() public onlyOwner whenNotPaused`: Pauses the contract, preventing most state-changing operations.
25. `unpause() public onlyOwner whenPaused`: Unpauses the contract.
26. `withdraw() public onlyOwner`: Allows the owner to withdraw any native currency accidentally sent to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Example for potential proof verification

/**
 * @title GenerativeArtPassport
 * @dev A Soulbound ERC721 contract representing an on-chain identity.
 *      Passport traits evolve based on owner activity, holdings, challenges, and attestations,
 *      influencing dynamically generated art/metadata.
 *
 * OUTLINE:
 * 1. Pragma and Imports
 * 2. Error Definitions
 * 3. Events
 * 4. State Variables
 * 5. Modifiers
 * 6. Constructor
 * 7. ERC721 Overrides (Soulbound Logic, tokenURI)
 * 8. Minting
 * 9. Trait Management & Generation
 * 10. Attestation System (Role based)
 * 11. Challenge System
 * 12. Admin/Configuration
 * 13. Internal Helpers
 *
 * FUNCTION SUMMARY:
 * 1.  balanceOf: Get owner's token count (inherited).
 * 2.  ownerOf: Get token owner (inherited).
 * 3.  tokenURI: Get metadata URI (overridden for dynamic content).
 * 4.  mintPassport: Create a new soulbound passport.
 * 5.  getTraits: Get all traits for a token (respects visibility).
 * 6.  getTrait: Get specific trait (respects visibility).
 * 7.  setTraitVisibility: Owner sets trait public visibility.
 * 8.  getTraitVisibility: Get trait visibility status.
 * 9.  requestMetadataUpdate: Owner signals for metadata refresh.
 * 10. checkAndApplyActivityTraits: Update traits based on interaction count.
 * 11. checkAndApplyTokenHoldingTraits: Update traits based on ERC20 balances.
 * 12. checkAndApplyNFTCollectionTraits: Update traits based on ERC721/1155 holdings.
 * 13. reRollRandomTrait: Apply a pseudo-random trait.
 * 14. grantAttestorRole: Owner grants role to attest data.
 * 15. revokeAttestorRole: Owner revokes attestor role.
 * 16. attestData: Attestor adds data/trait to a passport.
 * 17. createChallenge: Owner defines a challenge.
 * 18. completeChallenge: Owner marks challenge complete for passport.
 * 19. getChallenge: View challenge details.
 * 20. getCompletedChallenges: View passport's completed challenges.
 * 21. setBaseURI: Set metadata base URI.
 * 22. setLinkedToken: Configure ERC20 for trait checks.
 * 23. setLinkedNFTCollection: Configure NFT collection for trait checks.
 * 24. pause: Pause contract state changes.
 * 25. unpause: Unpause contract.
 * 26. withdraw: Withdraw native currency.
 */
contract GenerativeArtPassport is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error InvalidRecipient();
    error TokenNotFound();
    error NotPassportOwner();
    error TraitNotFound();
    error ChallengeNotFound();
    error ChallengeAlreadyCompleted();
    error ChallengeExpired();
    error UnauthorizedAttestor();
    error LinkedAssetNotEnabled();
    error NotSoulbound(); // Used internally for transfer prevention

    // --- Events ---
    event PassportMinted(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event TraitUpdated(uint256 indexed tokenId, string indexed traitKey, bytes traitValue);
    event TraitVisibilitySet(uint256 indexed tokenId, string indexed traitKey, bool visible);
    event MetadataUpdateRequested(uint256 indexed tokenId);
    event AttestorRoleGranted(address indexed attestor);
    event AttestorRoleRevoked(address indexed attestor);
    event DataAttested(uint256 indexed tokenId, string indexed key, bytes value, address indexed attestor);
    event ChallengeCreated(bytes32 indexed challengeId, uint256 expiryTimestamp);
    event ChallengeCompleted(uint256 indexed tokenId, bytes32 indexed challengeId, uint256 completionTimestamp);
    event LinkedTokenSet(address indexed tokenAddress, bool enabled);
    event LinkedNFTCollectionSet(address indexed collectionAddress, bool enabled);

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Passport traits: tokenId -> traitKey -> traitValue
    mapping(uint256 => mapping(string => bytes)) private _tokenTraits;
    // Trait visibility: tokenId -> traitKey -> isVisible (true by default)
    mapping(uint256 => mapping(string => bool)) private _traitVisibility;

    // Challenge System: challengeId -> Challenge details
    struct Challenge {
        string description;
        uint256 expiryTimestamp;
        bool exists; // To distinguish between unset bytes32 and a created challenge
    }
    mapping(bytes32 => Challenge) private _challenges;
    // Completed challenges: tokenId -> challengeId -> isCompleted (true)
    mapping(uint256 => mapping(bytes32 => bool)) private _completedChallenges;
    // List of completed challenge IDs per token (for easier retrieval)
    mapping(uint256 => bytes32[]) private _tokenCompletedChallengesList;

    // Attestation System: Role mapping
    mapping(address => bool) private _attestors;
    bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTOR_ROLE"); // Define a role ID

    // Linked Assets for trait generation
    mapping(address => bool) private _linkedTokens; // ERC20
    mapping(address => bool) private _linkedNFTCollections; // ERC721 or ERC1155

    string private _baseURI;

    // Simple counter for on-chain activity trait example
    mapping(uint256 => uint256) private _passportActivityCount;


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseURI = baseURI;
        // Grant initial owner the Attestor role
        _attestors[msg.sender] = true;
        emit AttestorRoleGranted(msg.sender);
    }

    // --- Modifiers ---
    modifier onlyPassportOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotPassportOwner();
        }
        _;
    }

    modifier onlyAttestor() {
        if (!_attestors[msg.sender]) {
            revert UnauthorizedAttestor();
        }
        _;
    }

    // --- ERC721 Overrides (Soulbound & Metadata) ---

    /**
     * @dev Prevents all transfers except minting and burning by the contract owner.
     * Implements the Soulbound property.
     * Note: ERC721's _update function calls _beforeTokenTransfer
     * with `from` and `to`. Minting is (0, to), Burning is (from, 0).
     * Standard transfers are (from, to) where from and to are non-zero.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Calls Pausable

        // Allow minting (from == address(0)) and burning by owner (to == address(0) and owner == msg.sender)
        if (from != address(0) && to != address(0)) {
            revert NotSoulbound();
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns the concatenanted base URI and token ID.
     * The off-chain service at the base URI is responsible for fetching
     * traits via getTraits() and generating the dynamic metadata JSON and art.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId); // Ensure token exists
        return string.concat(_baseURI, _toString(tokenId));
    }

    // Disable standard transfer functions to reinforce soulbound nature
    function approve(address to, uint256 tokenId) public pure override { revert NotSoulbound(); }
    function getApproved(uint256 tokenId) public view override returns (address) { revert NotSoulbound(); }
    function setApprovalForAll(address operator, bool approved) public pure override { revert NotSoulbound(); }
    function isApprovedForAll(address owner, address operator) public view override returns (bool) { revert NotSoulbound(); }
    function transferFrom(address from, address to, uint256 tokenId) public pure override { revert NotSoulbound(); }
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override { revert NotSoulbound(); }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override { revert NotSoulbound(); }


    // --- Minting ---

    /**
     * @dev Mints a new passport token for the specified recipient.
     * Only callable by the contract owner.
     * @param recipient The address to mint the passport to.
     */
    function mintPassport(address recipient) public virtual onlyOwner whenNotPaused {
        if (recipient == address(0)) {
            revert InvalidRecipient();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId); // Uses _beforeTokenTransfer, which allows (0, recipient) mint

        // Initialize some basic traits upon minting
        _storeTrait(newTokenId, "MintTimestamp", abi.encodeUint256(block.timestamp));
        _storeTrait(newTokenId, "InitialOwner", abi.encodePacked(recipient));
        _storeTrait(newTokenId, "ActivityCount", abi.encodeUint256(0)); // Initialize activity count

        emit PassportMinted(newTokenId, recipient, block.timestamp);
    }


    // --- Trait Management & Generation ---

    /**
     * @dev Internal function to store or update a trait for a token.
     * Emits a TraitUpdated event and signals metadata refresh.
     * @param tokenId The token ID.
     * @param traitKey The key of the trait.
     * @param traitValue The value of the trait.
     */
    function _storeTrait(uint256 tokenId, string memory traitKey, bytes memory traitValue) internal virtual {
        _tokenTraits[tokenId][traitKey] = traitValue;
        // Set default visibility to true if not already set
        if (!_traitVisibility[tokenId][traitKey]) {
             _traitVisibility[tokenId][traitKey] = true;
        }
        emit TraitUpdated(tokenId, traitKey, traitValue);
        _updateTokenMetadata(tokenId); // Signal metadata refresh
    }

     /**
      * @dev Internal getter for raw trait data, ignores visibility.
      * @param tokenId The token ID.
      * @param traitKey The key of the trait.
      * @return The raw trait value.
      */
     function _getTrait(uint256 tokenId, string memory traitKey) internal view returns (bytes memory) {
        // Note: Checking if the key exists explicitly might require iterating map keys,
        // or relying on the consumer to handle empty bytes if key is not set.
        // For simplicity, we return empty bytes if not set.
         return _tokenTraits[tokenId][traitKey];
     }


    /**
     * @dev Retrieves all traits for a given passport, respecting visibility settings.
     * Traits marked as hidden by the owner will not be included in the returned list.
     * @param tokenId The token ID.
     * @return traitKeys An array of trait keys.
     * @return traitValues An array of trait values corresponding to the keys.
     */
    function getTraits(uint256 tokenId) public view whenNotPaused returns (string[] memory traitKeys, bytes[] memory traitValues) {
        _requireMinted(tokenId);

        // This is a simplified example. Iterating map keys on-chain is inefficient/impossible.
        // A real-world scenario would either:
        // 1. Store keys in a dynamic array (adds complexity to add/remove).
        // 2. Have a fixed list of possible traits.
        // 3. Rely on an off-chain indexer to list all keys stored in the mapping via events.
        // This implementation *simulates* fetching keys. For demonstration, let's just return a placeholder or require off-chain indexing.
        // Let's return a hardcoded known trait for demonstration purposes and add a note.

        // --- SIMPLIFIED FOR DEMONSTRATION ---
        // In a real contract, iterating mapping keys like this is not possible.
        // You would need a separate array to store keys or rely on off-chain indexing.
        // This example only returns the "ActivityCount" trait for simplicity.
        // ---

        string[] memory keys = new string[](1); // Placeholder for 1 key
        bytes[] memory values = new bytes[](1); // Placeholder for 1 value

        string memory activityTraitKey = "ActivityCount";
        if (_traitVisibility[tokenId][activityTraitKey]) {
             keys[0] = activityTraitKey;
             values[0] = _tokenTraits[tokenId][activityTraitKey];
             // In a real scenario, you'd loop through all keys associated with this tokenId
             // (e.g., from an off-chain index or a separate key array) and add visible ones.
        } else {
             // If hidden, return empty arrays or specific indicator
             keys = new string[](0);
             values = new bytes[](0);
        }


        return (keys, values); // Return placeholder or actual data if keys array is used
    }


    /**
     * @dev Retrieves the value for a specific trait of a passport, respecting visibility settings.
     * Returns empty bytes if the trait is not set or is marked as hidden.
     * @param tokenId The token ID.
     * @param traitKey The key of the trait.
     * @return The trait value.
     */
    function getTrait(uint256 tokenId, string calldata traitKey) public view whenNotPaused returns (bytes memory) {
        _requireMinted(tokenId);

        if (!_traitVisibility[tokenId][traitKey]) {
            // Trait is hidden, return empty bytes or specific indicator
            return bytes("");
        }

        bytes memory value = _tokenTraits[tokenId][traitKey];
        // Check if the trait actually exists (mapping returns empty bytes for non-existent keys)
        // This is tricky with bytes. A common pattern is storing a flag or using a different mapping.
        // Assuming empty bytes means "not set" for now, but be cautious.
        // A more robust way is using mapping(uint256 => mapping(string => optional<bytes>)) if supported, or separate `hasTrait` mapping.
        // For this example, we'll return empty bytes if not set OR if hidden.

        // If value is non-empty, return it (already checked visibility above)
        return value;
    }


    /**
     * @dev Allows the passport owner to set the visibility status of a specific trait.
     * Hidden traits are not returned by `getTraits` or `getTrait`.
     * This does NOT remove the trait data from the contract state.
     * @param tokenId The token ID.
     * @param traitKey The key of the trait to modify.
     * @param visible The desired visibility status (true for visible, false for hidden).
     */
    function setTraitVisibility(uint256 tokenId, string calldata traitKey, bool visible) public onlyPassportOwner(tokenId) whenNotPaused {
        // Note: This only affects how `getTraits` and `getTrait` behave.
        // The off-chain renderer *could* still access the raw trait data via logs or other means if designed that way,
        // or it could also respect this on-chain visibility flag by calling `getTraitVisibility`.
        _traitVisibility[tokenId][traitKey] = visible;
        emit TraitVisibilitySet(tokenId, traitKey, visible);
        _updateTokenMetadata(tokenId); // Signal metadata refresh as visibility affects it
    }

    /**
     * @dev Gets the visibility status of a specific trait for a passport.
     * @param tokenId The token ID.
     * @param traitKey The key of the trait.
     * @return True if the trait is visible, false if hidden. Defaults to true.
     */
    function getTraitVisibility(uint256 tokenId, string calldata traitKey) public view returns (bool) {
        _requireMinted(tokenId);
        // Mapping defaults to false for bool, but we want true by default.
        // We store `true` explicitly in _storeTrait if not already set.
        // So checking the mapping directly is sufficient here.
        return _traitVisibility[tokenId][traitKey];
    }

    /**
     * @dev Allows the passport owner to request that the off-chain metadata service
     * update the metadata and potentially re-render the art for their token.
     * This is useful if external data changed or after applying new traits that
     * weren't automatically triggered.
     * @param tokenId The token ID.
     */
    function requestMetadataUpdate(uint256 tokenId) public onlyPassportOwner(tokenId) whenNotPaused {
         _requireMinted(tokenId);
         _updateTokenMetadata(tokenId); // Simply emit the event
         emit MetadataUpdateRequested(tokenId);
    }

    /**
     * @dev Updates a trait based on the owner's interaction count with this contract.
     * This is a simplified example; activity could be tracked in more complex ways.
     * Called by the owner.
     * @param tokenId The token ID.
     */
    function checkAndApplyActivityTraits(uint256 tokenId) public onlyPassportOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        // Increment a simple counter
        _passportActivityCount[tokenId]++;
        uint256 currentCount = _passportActivityCount[tokenId];

        // Example trait logic:
        string memory activityLevelTrait;
        if (currentCount < 5) {
            activityLevelTrait = "Passive";
        } else if (currentCount < 20) {
            activityLevelTrait = "Engaged";
        } else {
            activityLevelTrait = "Active";
        }

        _storeTrait(tokenId, "ActivityCount", abi.encodeUint256(currentCount));
        _storeTrait(tokenId, "ActivityLevel", abi.encodePacked(activityLevelTrait));
    }

    /**
     * @dev Updates traits based on the passport owner's balances of configured linked ERC20 tokens.
     * Called by the owner. Logic for *how* balance translates to a trait is simplified here.
     * @param tokenId The token ID.
     */
    function checkAndApplyTokenHoldingTraits(uint256 tokenId) public onlyPassportOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);
        address owner = ownerOf(tokenId);

        // Example: Iterate through configured linked tokens and check balance
        // In a real contract, storing linked tokens in an array would be necessary to iterate.
        // This is a placeholder showing the *concept*. Off-chain iteration or a helper contract might be needed.

        // --- SIMPLIFIED FOR DEMONSTRATION ---
        // Assumes `_linkedTokens` mapping is populated by owner.
        // Actual iteration of mapping keys is not possible on-chain.
        // This function would need to iterate over a stored array of linked token addresses.
        // ---

        // Example check for a hardcoded linked token (replace with loop over stored addresses)
        address exampleTokenAddress = 0x...; // Replace with a real ERC20 address you configure
        if (_linkedTokens[exampleTokenAddress]) {
            IERC20 linkedToken = IERC20(exampleTokenAddress);
            uint256 balance = linkedToken.balanceOf(owner);
            // Example trait logic:
            string memory tokenTraitKey = string.concat("Holds_", _addressToString(exampleTokenAddress));
            string memory tokenTraitValue = string.concat("Balance:", _toString(balance)); // Or categorize balance

            _storeTrait(tokenId, tokenTraitKey, abi.encodePacked(tokenTraitValue));

            // Add more checks for other linked tokens here...
        } else {
             // If the example token isn't linked, maybe remove its trait or set a default
             // Removing requires a specific delete mechanism or setting empty bytes.
        }
    }

    /**
     * @dev Updates traits based on the passport owner's holdings in configured linked NFT collections (ERC721/ERC1155).
     * Called by the owner. Logic for *how* holdings translates to a trait is simplified here.
     * @param tokenId The token ID.
     */
    function checkAndApplyNFTCollectionTraits(uint256 tokenId) public onlyPassportOwner(tokenId) whenNotPaused {
         _requireMinted(tokenId);
         address owner = ownerOf(tokenId);

         // --- SIMPLIFIED FOR DEMONSTRATION ---
         // Similar to ERC20, actual iteration of mapping keys is not possible.
         // This function would need to iterate over a stored array of linked collection addresses.
         // ---

         // Example check for a hardcoded linked NFT collection (replace with loop)
         address exampleNFTCollectionAddress = 0x...; // Replace with a real NFT address you configure
         if (_linkedNFTCollections[exampleNFTCollectionAddress]) {
             // ERC721 check example
             try IERC721(exampleNFTCollectionAddress).balanceOf(owner) returns (uint256 nftBalance) {
                 string memory nftTraitKey = string.concat("OwnsNFT_", _addressToString(exampleNFTCollectionAddress));
                 string memory nftTraitValue = string.concat("Count:", _toString(nftBalance)); // Or boolean "HasAtLeastOne"

                 _storeTrait(tokenId, nftTraitKey, abi.encodePacked(nftTraitValue));
             } catch {} // Handle if not a standard ERC721

             // ERC1155 check example (need a specific token ID within the collection)
             // try IERC1155(exampleNFTCollectionAddress).balanceOf(owner, someTokenId) returns (uint256 erc1155Balance) {
             //     string memory erc1155TraitKey = string.concat("OwnsERC1155_", _addressToString(exampleNFTCollectionAddress), "_", _toString(someTokenId));
             //     string memory erc1155TraitValue = string.concat("Count:", _toString(erc1155Balance));
             //     _storeTrait(tokenId, erc1155TraitKey, abi.encodePacked(erc1155TraitValue));
             // } catch {}
         }
    }

    /**
     * @dev Generates and stores a trait using a simple on-chain pseudo-random source.
     * This introduces an unpredictable element to the art generation.
     * *WARNING*: Using block.timestamp and block.difficulty/hash for randomness is insecure
     * and predictable. For production use, integrate Chainlink VRF or a similar secure oracle.
     * @param tokenId The token ID.
     */
    function reRollRandomTrait(uint256 tokenId) public onlyPassportOwner(tokenId) whenNotPaused {
        _requireMinted(tokenId);

        // Simplified pseudo-randomness using block data
        // DO NOT use this for anything requiring security or unpredictability against miners
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId)));

        // Example trait based on randomness (e.g., a random color hue, a shape parameter)
        string memory randomTraitValue = string.concat("RandomSeed:", _toString(randomNumber % 1000)); // Example: a number between 0-999

        _storeTrait(tokenId, "RandomFactor", abi.encodePacked(randomTraitValue));
    }


    // --- Attestation System ---

    /**
     * @dev Grants the ATTESTOR_ROLE to an address. Attestors can add arbitrary data/traits
     * to any passport using the `attestData` function.
     * Only callable by the contract owner.
     * @param attestor The address to grant the role to.
     */
    function grantAttestorRole(address attestor) public onlyOwner {
        require(attestor != address(0), "Cannot grant role to zero address");
        _attestors[attestor] = true;
        emit AttestorRoleGranted(attestor);
    }

    /**
     * @dev Revokes the ATTESTOR_ROLE from an address.
     * Only callable by the contract owner.
     * @param attestor The address to revoke the role from.
     */
    function revokeAttestorRole(address attestor) public onlyOwner {
        require(attestor != owner(), "Cannot revoke owner's attestor role"); // Owner is default attestor
        _attestors[attestor] = false;
        emit AttestorRoleRevoked(attestor);
    }

    /**
     * @dev Allows an address with the ATTESTOR_ROLE to add a verifiable data point
     * to a passport. This data is stored as a trait and can influence the art.
     * Example keys could be "ProofOfAttendance:EventXYZ", "Credential:KYCStatus", etc.
     * @param tokenId The token ID of the passport.
     * @param key The key for the attested data/trait.
     * @param value The value for the attested data/trait (bytes allows flexibility).
     */
    function attestData(uint256 tokenId, string calldata key, bytes calldata value) public onlyAttestor whenNotPaused {
        _requireMinted(tokenId);
        _storeTrait(tokenId, key, value);
        emit DataAttested(tokenId, key, value, msg.sender);
    }


    // --- Challenge System ---

    /**
     * @dev Creates a new challenge that passport owners can complete.
     * Only callable by the contract owner.
     * @param challengeId A unique identifier for the challenge.
     * @param description A description of the challenge.
     * @param expiryTimestamp The timestamp after which the challenge can no longer be completed (0 for no expiry).
     */
    function createChallenge(bytes32 challengeId, string calldata description, uint256 expiryTimestamp) public onlyOwner whenNotPaused {
        if (_challenges[challengeId].exists) {
            revert ("Challenge ID already exists");
        }
        _challenges[challengeId] = Challenge(description, expiryTimestamp, true);
        emit ChallengeCreated(challengeId, expiryTimestamp);
    }

    /**
     * @dev Marks a challenge as completed for a specific passport owner.
     * This function includes a placeholder for proof verification. A real implementation
     * would verify `proof` against the challenge requirements.
     * Completing a challenge adds a trait indicating completion.
     * @param tokenId The token ID of the passport.
     * @param challengeId The ID of the challenge being completed.
     * @param proof A bytes field containing proof of completion (format depends on challenge type).
     */
    function completeChallenge(uint256 tokenId, bytes32 challengeId, bytes calldata proof) public onlyPassportOwner(tokenId) whenNotPaused {
        Challenge storage challenge = _challenges[challengeId];
        if (!challenge.exists) {
            revert ChallengeNotFound();
        }
        if (_completedChallenges[tokenId][challengeId]) {
            revert ChallengeAlreadyCompleted();
        }
        if (challenge.expiryTimestamp != 0 && block.timestamp > challenge.expiryTimestamp) {
            revert ChallengeExpired();
        }

        // --- PROOF VERIFICATION PLACEHOLDER ---
        // In a real scenario, complex logic would go here to verify 'proof'.
        // This could involve:
        // - Checking signatures against known addresses.
        // - Verifying complex data structures.
        // - Interacting with other contracts or oracles.
        // Example using ECDSA verification (requires `import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";`)
        // bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(proof));
        // address signer = ECDSA.recover(messageHash, proof);
        // require(signer == authorizedVerifier, "Invalid proof signature");
        // Or simpler: require(keccak256(proof) == challenge.expectedProofHash, "Invalid proof");
        // For this example, we'll skip actual verification.
        // --- END PROOF VERIFICATION ---

        _completedChallenges[tokenId][challengeId] = true;
        _tokenCompletedChallengesList[tokenId].push(challengeId); // Add to list for retrieval

        // Store a trait indicating challenge completion
        string memory traitKey = string.concat("ChallengeCompleted:", _bytes32ToString(challengeId));
        _storeTrait(tokenId, traitKey, abi.encodeUint256(block.timestamp)); // Value could be timestamp or boolean true

        emit ChallengeCompleted(tokenId, challengeId, block.timestamp);
    }

    /**
     * @dev Retrieves the details of a specific challenge.
     * @param challengeId The ID of the challenge.
     * @return description The challenge description.
     * @return expiryTimestamp The challenge expiry timestamp.
     * @return exists True if the challenge exists, false otherwise.
     */
    function getChallenge(bytes32 challengeId) public view returns (string memory description, uint256 expiryTimestamp, bool exists) {
        Challenge storage challenge = _challenges[challengeId];
        return (challenge.description, challenge.expiryTimestamp, challenge.exists);
    }

    /**
     * @dev Retrieves the list of challenges completed by a specific passport.
     * @param tokenId The token ID.
     * @return An array of challenge IDs completed by the passport owner.
     */
    function getCompletedChallenges(uint256 tokenId) public view returns (bytes32[] memory) {
         _requireMinted(tokenId);
         return _tokenCompletedChallengesList[tokenId];
    }


    // --- Admin/Configuration ---

    /**
     * @dev Sets the base URI for token metadata. The tokenURI will be baseURI + tokenId.
     * Only callable by the contract owner.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    /**
     * @dev Configures whether a specific ERC20 token address should be checked
     * when `checkAndApplyTokenHoldingTraits` is called.
     * Only callable by the contract owner.
     * @param tokenAddress The address of the ERC20 token.
     * @param enabled True to enable checks, false to disable.
     */
    function setLinkedToken(address tokenAddress, bool enabled) public onlyOwner {
         require(tokenAddress != address(0), "Cannot link zero address");
         _linkedTokens[tokenAddress] = enabled;
         emit LinkedTokenSet(tokenAddress, enabled);
    }

    /**
     * @dev Configures whether a specific NFT collection address (ERC721 or ERC1155)
     * should be checked when `checkAndApplyNFTCollectionTraits` is called.
     * Only callable by the contract owner.
     * @param collectionAddress The address of the NFT collection.
     * @param enabled True to enable checks, false to disable.
     */
    function setLinkedNFTCollection(address collectionAddress, bool enabled) public onlyOwner {
         require(collectionAddress != address(0), "Cannot link zero address");
         _linkedNFTCollections[collectionAddress] = enabled;
         emit LinkedNFTCollectionSet(collectionAddress, enabled);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Inherited from Pausable.
     * Only callable by the contract owner.
     */
    function pause() public override onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Inherited from Pausable.
     * Only callable by the contract owner.
     */
    function unpause() public override onlyOwner whenPaused {
        _unpause();
    }

     /**
     * @dev Allows the owner to withdraw any native currency held by the contract.
     * Useful if any ETH is accidentally sent here.
     * Only callable by the contract owner.
     */
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal function to signal a metadata update for a token.
     * Emits the standard ERC721 Metadata Update event.
     * @param tokenId The token ID.
     */
    function _updateTokenMetadata(uint256 tokenId) internal {
        // Standard ERC721 Metadata Update event
        // This signals indexers/clients that the tokenURI data *might* have changed
        emit ERC721.MetadataUpdate(tokenId);
    }


    /**
     * @dev Converts a bytes32 to its hexadecimal string representation.
     * Useful for trait keys based on bytes32 IDs.
     */
    function _bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes16 b1 = bytes16(x);
        bytes16 b2 = bytes16(x << 128); // Shift for the second half
        return string.concat(
            Base64.encode(b1),
            Base64.encode(b2) // Or a more direct hex conversion if preferred
        );
    }

    /**
     * @dev Converts an address to its hexadecimal string representation.
     */
    function _addressToString(address _address) internal pure returns (string memory) {
        return Strings.toHexString(uint160(_address), 20);
    }

    // Helper to convert uint256 to string (from OpenZeppelin Strings utility)
    function _toString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }

    // Helper to check if token is minted (from OpenZeppelin ERC721)
    function _requireMinted(uint256 tokenId) internal view {
         require(_exists(tokenId), "ERC721: invalid token ID");
     }

    // Fallback function to accept ETH (though not expected for primary function)
    receive() external payable {}
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative Concepts Implemented:**

1.  **Soulbound Tokens:** Achieved by overriding `_beforeTokenTransfer` and reverting if `from` and `to` are both non-zero addresses. This prevents trading and gifting, making the passport non-transferable identity.
2.  **Dynamic & Generative Traits (On-Chain Logic):**
    *   Instead of fixed traits in metadata, traits are stored in a mapping (`_tokenTraits`).
    *   Functions like `checkAndApplyActivityTraits`, `checkAndApplyTokenHoldingTraits`, `checkAndApplyNFTCollectionTraits`, `reRollRandomTrait`, and `attestData` contain the *logic* for how these traits are generated or updated based on on-chain state or inputs.
    *   `_storeTrait` is the central function for updating a trait, ensuring consistency and triggering the metadata update signal.
3.  **Attestation System:** The `onlyAttestor` modifier and `attestData` function create a permissioned system where specific addresses can add verifiable data points (credentials, status updates, etc.) to a passport. This is a core building block for on-chain reputation and identity.
4.  **Challenge System:** `createChallenge` and `completeChallenge` provide a mechanism to gamify user interaction and link on-chain achievements (represented by `proof`) directly to passport traits.
5.  **Trait Visibility:** The `_traitVisibility` mapping and `setTraitVisibility` function allow the *owner* to control which traits are exposed via the public `getTraits` and `getTrait` view functions. This offers a *light* privacy feature, allowing data to influence the art (via the off-chain renderer accessing raw state or events) without being trivially readable by anyone calling the view functions.
6.  **Dynamic Metadata:** The `tokenURI` points to a dynamic service. The contract emits a `MetadataUpdate` event (via `_updateTokenMetadata`) whenever traits change or are updated. This signals off-chain systems (like marketplaces or art renderers) to re-fetch the metadata and potentially re-render the art based on the *new* on-chain traits retrieved using `getTraits` or by watching `TraitUpdated` events.
7.  **Abstracted External Data Integration:** While the contract doesn't directly implement complex oracle patterns, `checkAndApplyTokenHoldingTraits`, `checkAndApplyNFTCollectionTraits`, and `attestData` provide the *structure* for incorporating data from other contracts or external sources (via attestors). The complexity of *verifying* that external data happens *before* calling these functions or is abstracted within the `proof` in `completeChallenge`.
8.  **On-Chain Pseudo-Randomness:** `reRollRandomTrait` demonstrates incorporating a random element directly from the blockchain. (With the critical caveat that this is insecure).

This contract goes beyond standard ERC721 by making the NFT a living, evolving representation of a user's on-chain journey, driven by multiple distinct interaction mechanisms and controlled, in part, by the user themselves (visibility, requesting updates, initiating trait checks).