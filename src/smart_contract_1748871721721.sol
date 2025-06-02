Okay, this sounds like a fun challenge! Let's design a smart contract around the concept of **Generative Soulbound Tokens (SBTs)** with dynamic traits based on on-chain claims and activities.

The core idea:
1.  Users can mint a unique, non-transferable "Soul" token representing their on-chain identity.
2.  This Soul token has generative traits determined initially at minting based on on-chain data.
3.  Trusted entities (Issuers) or specific on-chain actions can add "Claims" to a Soul.
4.  These Claims dynamically influence and update the Soul's generative traits, potentially changing its appearance or metadata over time.
5.  The tokens are Soulbound, meaning they cannot be transferred.

This incorporates SBTs (trendy, advanced concept), generative art (creative), dynamic NFTs (advanced/creative), and a reputation/claim system (interesting, potentially advanced depending on verification).

---

## Generative Soulbound Tokens Contract Outline

**Concept:** A non-transferable token (Soulbound Token) representing an on-chain identity, whose generative traits dynamically evolve based on verified claims issued by trusted entities or specific on-chain actions.

**Use Case:** On-chain identity, reputation, achievements, skill representation, dynamic profile pictures/avatars, access control based on claims.

**Key Features:**
*   Soulbound (Non-transferable ERC-721).
*   Unique Soul per address.
*   Generative traits derived from on-chain data and claims.
*   Claims system with trusted Issuers.
*   Dynamic metadata reflecting trait changes.
*   Pausable functionality for administrative control.

**Interfaces Implemented:** ERC721, ERC165.

---

## Function Summary

**I. Core Soul Management**
1.  `mintSoul(address recipient)`: Mints a new Soul token for an address if they don't have one. Initializes generative traits.
2.  `hasSoul(address account)`: Checks if an address owns a Soul token.
3.  `getTokenIdByAddress(address account)`: Returns the token ID of the Soul owned by an address.
4.  `getTotalSouls()`: Returns the total number of Soul tokens minted.

**II. Issuer Management (Admin Only)**
5.  `addIssuer(address issuerAddress)`: Grants permission for an address to issue and revoke claims.
6.  `removeIssuer(address issuerAddress)`: Revokes issuer permission from an address.
7.  `isIssuer(address account)`: Checks if an address is a trusted issuer.
8.  `getAllIssuers()`: Returns a list of all trusted issuer addresses.

**III. Claim Management (Issuers Only)**
9.  `issueClaim(uint256 tokenId, string memory claimType, bytes memory claimData)`: Adds a new verifiable claim to a Soul token. Triggers trait regeneration.
10. `revokeClaim(uint256 tokenId, uint256 claimId)`: Revokes an existing claim by its ID. Triggers trait regeneration.
11. `getClaimById(uint256 tokenId, uint256 claimId)`: Retrieves details of a specific claim for a Soul.
12. `getClaimsByTokenId(uint256 tokenId)`: Retrieves all claims (active and inactive) associated with a Soul token.
13. `getActiveClaimsByTokenId(uint256 tokenId)`: Retrieves only the active claims associated with a Soul token.
14. `countClaims(uint256 tokenId)`: Returns the total count of claims (active and inactive) for a Soul.
15. `countActiveClaims(uint256 tokenId)`: Returns the count of only active claims for a Soul.

**IV. Generative Trait Management**
16. `regenerateTraits(uint256 tokenId)`: Explicitly triggers the trait regeneration logic for a Soul (callable by owner or issuer).
17. `getTraits(uint256 tokenId)`: Retrieves the current generative traits associated with a Soul token.
18. `getTraitValue(uint256 tokenId, string memory traitName)`: Retrieves the value of a specific trait for a Soul.

**V. ERC-721 Standard Functions & Overrides**
19. `tokenURI(uint256 tokenId)`: Returns the URI pointing to the metadata for a Soul token. This metadata should include traits and potentially claims for an off-chain renderer to generate the final JSON/image.
20. `balanceOf(address owner)`: Returns the number of tokens owned by an address (will be 0 or 1 for a Soul).
21. `ownerOf(uint256 tokenId)`: Returns the owner of the Soul token.
22. `transferFrom(address from, address to, uint256 tokenId)`: *Override:* Reverts, as tokens are soulbound.
23. `safeTransferFrom(address from, address to, uint256 tokenId)`: *Override:* Reverts, as tokens are soulbound.
24. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: *Override:* Reverts, as tokens are soulbound.
25. `approve(address to, uint256 tokenId)`: *Override:* Reverts, as tokens are non-transferable.
26. `setApprovalForAll(address operator, bool approved)`: *Override:* Reverts, as tokens are non-transferable.
27. `getApproved(uint256 tokenId)`: *Override:* Returns address(0).
28. `isApprovedForAll(address owner, address operator)`: *Override:* Returns false.
29. `supportsInterface(bytes4 interfaceId)`: Supports ERC-721 and ERC-165.

**VI. Admin & Utility**
30. `setBaseURI(string memory baseURI)`: Sets the base URI for the `tokenURI` function. Admin only.
31. `pause()`: Pauses minting and claim issuance. Admin only.
32. `unpause()`: Unpauses contract functions. Admin only.
33. `paused()`: Returns the current pause status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // ERC721Enumerable is useful for tracking tokens, although we have an address->id mapping
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // Added explicitly for supportsInterface

/**
 * @title Generative Soulbound Tokens
 * @dev A contract for non-transferable ERC721 tokens (Souls) whose traits are dynamically
 *      generated based on claims issued by trusted entities.
 */
contract GenerativeSoulboundTokens is ERC721, ERC721Enumerable, Ownable, Pausable, ERC165 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct Claim {
        uint256 id;
        address issuer;
        string claimType;
        bytes claimData; // Arbitrary data associated with the claim
        uint64 timestamp;
        bool active; // Use a flag for soft revocation
    }

    // --- State Variables ---

    Counters.Counter private _soulCounter; // Tracks the total number of souls minted (also next token ID)
    Counters.Counter private _claimCounter; // Tracks the total number of claims ever issued across all souls

    // Mapping from owner address to token ID (since each address can only have one Soul)
    mapping(address => uint256) private _addressSoul;
    // Mapping from token ID back to owner address (standard ERC721 storage) - handled by ERC721

    // Mapping from token ID to a mapping of claim ID to Claim struct
    mapping(uint256 => mapping(uint256 => Claim)) private _tokenClaims;
    // Mapping from token ID to an array of claim IDs for efficient retrieval
    mapping(uint256 => uint256[]) private _tokenClaimIds; // Stores both active and inactive claim IDs

    // Mapping from address to boolean indicating if the address is a trusted issuer
    mapping(address => bool) private _isIssuer;
    // Array of trusted issuer addresses for enumeration
    address[] private _issuers;

    // Mapping from token ID to a mapping of trait name to trait value (string representation)
    mapping(uint256 => mapping(string => string)) private _tokenTraits;
    // Mapping from token ID to an array of trait names for enumeration
    mapping(uint256 => string[]) private _tokenTraitNames;

    // Base URI for token metadata
    string private _baseTokenURI;

    // --- Events ---

    event SoulMinted(address indexed recipient, uint256 tokenId, uint64 timestamp);
    event IssuerAdded(address indexed issuer);
    event IssuerRemoved(address indexed issuer);
    event ClaimIssued(uint256 indexed tokenId, uint256 claimId, address indexed issuer, string claimType, bytes claimData, uint64 timestamp);
    event ClaimRevoked(uint256 indexed tokenId, uint256 indexed claimId, address indexed revoker);
    event TraitsRegenerated(uint256 indexed tokenId, uint64 timestamp);
    event TraitUpdated(uint256 indexed tokenId, string traitName, string traitValue); // Detail trait changes

    // --- Modifiers ---

    modifier onlyIssuer() {
        require(_isIssuer[_msgSender()], "Caller is not an issuer");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseURI;
        // Add contract owner as the initial issuer
        _addIssuer(owner());
    }

    // --- Internal Helpers ---

    /**
     * @dev Generates initial traits for a new Soul token.
     *      Simple example: traits based on block data and recipient address.
     *      More complex logic could involve Chainlink VRF or other on-chain entropy sources.
     */
    function _generateInitialTraits(uint256 tokenId, address recipient) internal {
        // Example generative logic (simple on-chain traits)
        // This should be deterministic based on input parameters (tokenId, recipient, block data)
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, recipient, block.timestamp, block.number, block.difficulty)));

        _setTrait(tokenId, "BirthBlock", block.number.toString());
        _setTrait(tokenId, "BirthTimestamp", block.timestamp.toString());
        _setTrait(tokenId, "SeedHash", Strings.toHexString(seed));
        _setTrait(tokenId, "RecipientPrefix", Strings.toHexString(uint160(recipient), 20)); // Use part of address

        // Add a dynamic trait based on the seed
        string memory colorTrait;
        if (seed % 100 < 30) {
            colorTrait = "Crimson";
        } else if (seed % 100 < 60) {
            colorTrait = "Azure";
        } else if (seed % 100 < 90) {
            colorTrait = "Emerald";
        } else {
            colorTrait = "Golden";
        }
        _setTrait(tokenId, "PrimaryColor", colorTrait);
    }

    /**
     * @dev Regenerates traits based on the current state of claims for a Soul token.
     *      This logic is central to the dynamic nature of the SBT.
     *      Can be arbitrarily complex. Example: Count claims, derive traits from claim data.
     */
    function _regenerateTraitsFromClaims(uint256 tokenId) internal {
        uint256 activeClaimCount = 0;
        bytes memory claimsHash = ""; // Simple way to include claim data in trait derivation

        for (uint i = 0; i < _tokenClaimIds[tokenId].length; i++) {
            uint256 claimId = _tokenClaimIds[tokenId][i];
            Claim storage claim = _tokenClaims[tokenId][claimId];
            if (claim.active) {
                activeClaimCount++;
                // Append claim data to hash input (simple example)
                claimsHash = abi.encodePacked(claimsHash, claim.claimType, claim.claimData);
            }
        }

        _setTrait(tokenId, "ActiveClaimCount", activeClaimCount.toString());

        if (activeClaimCount > 0) {
            _setTrait(tokenId, "ClaimDerivedHash", Strings.toHexString(uint256(keccak256(claimsHash))));
        } else {
             _setTrait(tokenId, "ClaimDerivedHash", "0x0"); // Indicate no claims influence
        }

        // Example: Tier trait based on claim count
        string memory tierTrait;
        if (activeClaimCount >= 10) {
            tierTrait = "Veteran";
        } else if (activeClaimCount >= 5) {
            tierTrait = "Experienced";
        } else if (activeClaimCount > 0) {
            tierTrait = "Claimant";
        } else {
            tierTrait = "Novice";
        }
        _setTrait(tokenId, "ReputationTier", tierTrait);

        emit TraitsRegenerated(tokenId, uint64(block.timestamp));
    }

    /**
     * @dev Internal function to set or update a trait for a token.
     *      Manages the list of trait names.
     */
    function _setTrait(uint256 tokenId, string memory traitName, string memory traitValue) internal {
        // Check if traitName already exists for this token
        bool exists = false;
        for (uint i = 0; i < _tokenTraitNames[tokenId].length; i++) {
            if (keccak256(abi.encodePacked(_tokenTraitNames[tokenId][i])) == keccak256(abi.encodePacked(traitName))) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _tokenTraitNames[tokenId].push(traitName);
        }

        _tokenTraits[tokenId][traitName] = traitValue;
        emit TraitUpdated(tokenId, traitName, traitValue);
    }


    /**
     * @dev Internal function to add an issuer and update the array.
     */
    function _addIssuer(address issuerAddress) internal {
        if (!_isIssuer[issuerAddress]) {
            _isIssuer[issuerAddress] = true;
            _issuers.push(issuerAddress);
            emit IssuerAdded(issuerAddress);
        }
    }

    /**
     * @dev Internal function to remove an issuer and update the array.
     *      This is O(n) due to array modification. Consider a mapping+set if many removals are expected.
     */
    function _removeIssuer(address issuerAddress) internal {
        if (_isIssuer[issuerAddress]) {
            _isIssuer[issuerAddress] = false;
            // Find and remove from array (simple but potentially costly for large arrays)
            for (uint i = 0; i < _issuers.length; i++) {
                if (_issuers[i] == issuerAddress) {
                    // Replace with last element and pop (order doesn't matter here)
                    _issuers[i] = _issuers[_issuers.length - 1];
                    _issuers.pop();
                    break;
                }
            }
            emit IssuerRemoved(issuerAddress);
        }
    }


    // --- I. Core Soul Management ---

    /**
     * @dev Mints a new Soul token for the recipient address.
     *      Each address can only hold one Soul.
     */
    function mintSoul(address recipient) public onlyOwner whenNotPaused {
        require(recipient != address(0), "Mint to zero address");
        require(_addressSoul[recipient] == 0, "Address already has a Soul"); // Check if recipient already has a soul

        _soulCounter.increment();
        uint256 newItemId = _soulCounter.current();

        _safeMint(recipient, newItemId);
        _addressSoul[recipient] = newItemId; // Map address to token ID

        _generateInitialTraits(newItemId, recipient); // Generate initial traits
        // No claims yet, so _regenerateTraitsFromClaims is not needed initially

        emit SoulMinted(recipient, newItemId, uint64(block.timestamp));
    }

    /**
     * @dev Checks if an address has a Soul token.
     */
    function hasSoul(address account) public view returns (bool) {
        return _addressSoul[account] != 0;
    }

    /**
     * @dev Returns the token ID of the Soul owned by an address.
     *      Returns 0 if the address does not own a Soul.
     */
    function getTokenIdByAddress(address account) public view returns (uint256) {
        return _addressSoul[account];
    }

    /**
     * @dev Returns the total number of Soul tokens minted.
     */
    function getTotalSouls() public view returns (uint256) {
        return _soulCounter.current();
    }


    // --- II. Issuer Management ---

    /**
     * @dev Grants permission for an address to issue and revoke claims.
     *      Only callable by the contract owner.
     */
    function addIssuer(address issuerAddress) public onlyOwner {
        _addIssuer(issuerAddress);
    }

    /**
     * @dev Revokes issuer permission from an address.
     *      Only callable by the contract owner.
     */
    function removeIssuer(address issuerAddress) public onlyOwner {
        _removeIssuer(issuerAddress);
    }

    /**
     * @dev Checks if an address is a trusted issuer.
     */
    function isIssuer(address account) public view returns (bool) {
        return _isIssuer[account];
    }

     /**
     * @dev Returns a list of all trusted issuer addresses.
     *      Note: This can be costly for very large numbers of issuers.
     */
    function getAllIssuers() public view returns (address[] memory) {
        return _issuers;
    }


    // --- III. Claim Management ---

    /**
     * @dev Adds a new verifiable claim to a Soul token.
     *      Only callable by a trusted issuer.
     *      Triggers trait regeneration after adding the claim.
     */
    function issueClaim(uint256 tokenId, string memory claimType, bytes memory claimData) public onlyIssuer whenNotPaused {
        require(_exists(tokenId), "Token ID does not exist");

        _claimCounter.increment();
        uint256 newClaimId = _claimCounter.current();

        Claim storage newClaim = _tokenClaims[tokenId][newClaimId];
        newClaim.id = newClaimId;
        newClaim.issuer = _msgSender();
        newClaim.claimType = claimType;
        newClaim.claimData = claimData;
        newClaim.timestamp = uint64(block.timestamp);
        newClaim.active = true; // Claim is active by default

        _tokenClaimIds[tokenId].push(newClaimId); // Add claim ID to the token's list

        _regenerateTraitsFromClaims(tokenId); // Update traits based on new claim

        emit ClaimIssued(tokenId, newClaimId, _msgSender(), claimType, claimData, uint64(block.timestamp));
    }

    /**
     * @dev Revokes an existing claim by its ID.
     *      Uses soft deletion (setting active flag to false).
     *      Only callable by the original issuer of the claim or the contract owner.
     *      Triggers trait regeneration after revoking the claim.
     */
    function revokeClaim(uint256 tokenId, uint256 claimId) public whenNotPaused {
        require(_exists(tokenId), "Token ID does not exist");
        require(_tokenClaims[tokenId][claimId].id != 0, "Claim ID does not exist for this token"); // Check if claim exists
        Claim storage claimToRevoke = _tokenClaims[tokenId][claimId];

        require(claimToRevoke.active, "Claim is already inactive");
        require(claimToRevoke.issuer == _msgSender() || owner() == _msgSender(), "Not authorized to revoke this claim");

        claimToRevoke.active = false; // Soft delete the claim

        _regenerateTraitsFromClaims(tokenId); // Update traits based on revoked claim

        emit ClaimRevoked(tokenId, claimId, _msgSender());
    }

     /**
     * @dev Retrieves details of a specific claim for a Soul.
     */
    function getClaimById(uint256 tokenId, uint256 claimId) public view returns (Claim memory) {
        require(_exists(tokenId), "Token ID does not exist");
        require(_tokenClaims[tokenId][claimId].id != 0, "Claim ID does not exist for this token");
        return _tokenClaims[tokenId][claimId];
    }

    /**
     * @dev Retrieves all claims (active and inactive) associated with a Soul token.
     *      Note: This can be costly for a large number of claims.
     */
    function getClaimsByTokenId(uint256 tokenId) public view returns (Claim[] memory) {
        require(_exists(tokenId), "Token ID does not exist");
        uint256[] storage claimIds = _tokenClaimIds[tokenId];
        Claim[] memory claims = new Claim[](claimIds.length);
        for (uint i = 0; i < claimIds.length; i++) {
            claims[i] = _tokenClaims[tokenId][claimIds[i]];
        }
        return claims;
    }

    /**
     * @dev Retrieves only the active claims associated with a Soul token.
     *      Note: This iterates through all claim IDs, potentially costly.
     */
    function getActiveClaimsByTokenId(uint256 tokenId) public view returns (Claim[] memory) {
        require(_exists(tokenId), "Token ID does not exist");
        uint256[] storage allClaimIds = _tokenClaimIds[tokenId];
        uint256 activeCount = countActiveClaims(tokenId); // First count active ones
        Claim[] memory activeClaims = new Claim[](activeCount);
        uint currentActiveIndex = 0;
        for (uint i = 0; i < allClaimIds.length; i++) {
            Claim storage claim = _tokenClaims[tokenId][allClaimIds[i]];
            if (claim.active) {
                activeClaims[currentActiveIndex] = claim;
                currentActiveIndex++;
            }
        }
        return activeClaims;
    }

    /**
     * @dev Returns the total count of claims (active and inactive) for a Soul.
     */
    function countClaims(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID does not exist");
        return _tokenClaimIds[tokenId].length;
    }

     /**
     * @dev Returns the count of only active claims for a Soul.
     *      Note: This iterates through all claim IDs, potentially costly.
     */
    function countActiveClaims(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID does not exist");
        uint256 activeCount = 0;
        uint256[] storage claimIds = _tokenClaimIds[tokenId];
        for (uint i = 0; i < claimIds.length; i++) {
            if (_tokenClaims[tokenId][claimIds[i]].active) {
                activeCount++;
            }
        }
        return activeCount;
    }


    // --- IV. Generative Trait Management ---

    /**
     * @dev Explicitly triggers the trait regeneration logic for a Soul.
     *      Callable by the Soul's owner or any trusted issuer.
     *      Claims are automatically regenerated when claims are issued/revoked,
     *      but this allows manual trigger if needed (e.g., after complex off-chain logic).
     */
    function regenerateTraits(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token ID does not exist");
        address tokenOwner = ownerOf(tokenId); // Use ERC721 ownerOf

        require(tokenOwner == _msgSender() || _isIssuer[_msgSender()] || owner() == _msgSender(),
                "Not authorized to regenerate traits");

        _regenerateTraitsFromClaims(tokenId);
        // Note: Initial traits from _generateInitialTraits are not re-run here.
        // Only claims-based traits are updated by _regenerateTraitsFromClaims.
    }

    /**
     * @dev Retrieves the current generative traits associated with a Soul token.
     *      Returns arrays of trait names and values.
     *      Note: This can be costly for very large numbers of traits.
     */
    function getTraits(uint256 tokenId) public view returns (string[] memory names, string[] memory values) {
        require(_exists(tokenId), "Token ID does not exist");
        string[] storage traitNames = _tokenTraitNames[tokenId];
        names = new string[](traitNames.length);
        values = new string[](traitNames.length);
        for (uint i = 0; i < traitNames.length; i++) {
            string memory name = traitNames[i];
            names[i] = name;
            values[i] = _tokenTraits[tokenId][name];
        }
        return (names, values);
    }

     /**
     * @dev Retrieves the value of a specific trait for a Soul.
     *      Returns an empty string if the trait does not exist.
     */
    function getTraitValue(uint256 tokenId, string memory traitName) public view returns (string memory) {
         require(_exists(tokenId), "Token ID does not exist");
         // Check if the trait name exists in the list for this token first (optional but cleaner)
        bool traitExists = false;
         string[] storage traitNames = _tokenTraitNames[tokenId];
         for (uint i = 0; i < traitNames.length; i++) {
             if (keccak256(abi.encodePacked(traitNames[i])) == keccak256(abi.encodePacked(traitName))) {
                 traitExists = true;
                 break;
             }
         }
        if (!traitExists) {
             return ""; // Trait doesn't exist for this token
        }
         return _tokenTraits[tokenId][traitName];
    }


    // --- V. ERC-721 Standard Functions & Overrides ---

    /**
     * @dev Returns the base URI + token ID for the metadata endpoint.
     *      An off-chain renderer will use this URI to fetch on-chain data
     *      (traits, claims) and generate the full metadata JSON and potentially an image.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // ERC721Enumerable overrides - required if inheriting ERC721Enumerable
    // These are standard and don't count as 'creative' but are needed.
    // They are automatically included by inheriting ERC721Enumerable

    // --- Soulbound Overrides ---
    // These functions prevent transferability.

    /**
     * @dev See {IERC721-transferFrom}.
     *      Always reverts as tokens are soulbound.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert("Soulbound: Non-transferable");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      Always reverts as tokens are soulbound.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert("Soulbound: Non-transferable");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      Always reverts as tokens are soulbound.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert("Soulbound: Non-transferable");
    }

    /**
     * @dev See {IERC721-approve}.
     *      Always reverts as tokens are non-transferable and cannot be approved.
     */
    function approve(address to, uint256 tokenId) public override {
        revert("Soulbound: Non-transferable");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      Always reverts as tokens are non-transferable and cannot be approved.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) {
         // We still need to call the parent to keep track of approvals for ERC721 standard compliance,
         // even though transfer functions are blocked. However, for true Soulbound,
         // approvals shouldn't even be possible or tracked. Let's hard revert.
        revert("Soulbound: Non-transferable");
    }

     /**
     * @dev See {IERC721-getApproved}.
     *      Always returns address(0) as tokens cannot be approved.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
         require(_exists(tokenId), "Approval query for non-existent token");
        return address(0);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     *      Always returns false as tokens cannot be approved for all.
     */
    function isApprovedForAll(address owner, address operator) public view override(ERC721, IERC721) returns (bool) {
        // ERC721 implementation uses _operatorApprovals mapping.
        // For true soulbound, we can return false directly.
        // Calling super will check the mapping, which will never be true if setApprovalForAll reverts.
        // Let's return false directly for clarity.
        return false;
    }


    // --- VI. Admin & Utility ---

    /**
     * @dev Sets the base URI for the token metadata.
     *      Only callable by the contract owner.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Pauses the contract. Prevents `mintSoul` and `issueClaim`.
     *      Only callable by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Allows `mintSoul` and `issueClaim`.
     *      Only callable by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC165 Support ---

    /**
     * @dev See {IERC165-supportsInterface}.
     *      Adds support for ERC721, ERC721Enumerable, and ERC165.
     *      Could add a custom interface ID if desired.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC165) returns (bool) {
        // Add support for ERC721, ERC721Enumerable, ERC165
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(ERC721Enumerable).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               super.supportsInterface(interfaceId);
    }


    // --- Internal Overrides for ERC721 and ERC721Enumerable ---

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *      Hooks into token transfers. Used here to check if the token exists.
     *      ERC721Enumerable uses this hook internally.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // If from is not address(0), it's a transfer or burn. SBTs cannot be transferred.
        // The public transfer functions already revert, but this ensures internal calls also respect it.
        require(from == address(0) || to == address(0), "Soulbound: Non-transferable"); // Allow mint (from 0) and burn (to 0)
    }

    /**
     * @dev See {ERC721Enumerable-supportsInterface}.
     *      Required override when inheriting ERC721 and ERC721Enumerable.
     *      Our main supportsInterface handles the logic.
     */
    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }
    // NOTE: Consolidated supportsInterface above to handle ERC165 explicitly and call super once.

    /**
     * @dev See {ERC721-_increaseBalance}.
     *      Required override when inheriting ERC721 and ERC721Enumerable.
     *      ERC721Enumerable uses this to track balances.
     *      Added a check here to enforce only one soul per address during mint.
     */
     function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        if (account != address(0)) {
            // This hook is called *before* _safeMint in the case of minting.
            // Check if the account already has a soul *before* increasing the balance.
            // _addressSoul check in mintSoul() is the primary gate, but this is a fail-safe.
            require(_addressSoul[account] == 0 || amount == 0, "Account already owns a Soul");
        }
         super._increaseBalance(account, amount);
     }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts & Functions:**

1.  **Soulbound Tokens (SBTs):** The core concept. Implemented by overriding all ERC-721 transfer mechanisms (`transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`) to revert. This makes the tokens non-transferable, tying them permanently to the owner's address.
2.  **Generative Traits:** The tokens don't store a static image or metadata URI. Instead, they store *parameters* or *traits* on-chain (`_tokenTraits`). These traits are initialized based on on-chain data (`_generateInitialTraits`) and then dynamically updated (`_regenerateTraitsFromClaims`) based on subsequent claims.
3.  **Dynamic Metadata:** The `tokenURI` function points to a location (off-chain renderer/API) that reads the on-chain traits and claims to *generate* the final metadata JSON and potentially the image representation. This makes the NFT appearance/description change as claims are added or revoked.
4.  **Claim System:** A structured way to associate verifiable information (`claimType`, `claimData`, `issuer`) with a Soul. This is implemented using mappings (`_tokenClaims`, `_tokenClaimIds`) and a dedicated `Claim` struct. This allows building reputation or identity layers on the SBT.
5.  **Trusted Issuers:** A mechanism (`_isIssuer`, `_issuers`, `onlyIssuer` modifier) to control *who* can issue claims, adding a layer of trust or verification to the claim system. The contract owner manages this list.
6.  **Dynamic Trait Regeneration:** The `_regenerateTraitsFromClaims` function is the core logic that reads the active claims and updates the traits. This function is automatically called when claims are issued or revoked, or can be manually triggered by authorized parties (`regenerateTraits`).
7.  **Soft Revocation:** Claims are not deleted, but marked as `active = false`. This preserves the history of claims while allowing traits to reflect only current, active claims.
8.  **Unique Soul per Address:** The `_addressSoul` mapping and checks in `mintSoul` and `_increaseBalance` ensure that a single Ethereum address can only ever own one Soul token, reinforcing the identity concept.
9.  **Explicit ERC165 Support:** While often handled by inheriting OpenZeppelin contracts, explicitly implementing `supportsInterface` and calling `super` demonstrates understanding of standard interfaces.
10. **Pausable Pattern:** Standard but useful advanced pattern (`Pausable` from OpenZeppelin) allowing the owner to pause sensitive operations like minting and claim issuance in case of issues.

The function count is well over 20, covering the core ERC721 standard (including the overrides making it Soulbound), identity/soul management, issuer management, detailed claim management, trait access, and admin utilities. The on-chain generative logic is kept relatively simple (using block data, claim count, hashing) to minimize gas costs, relying on the off-chain renderer to translate these traits into rich metadata and visuals.