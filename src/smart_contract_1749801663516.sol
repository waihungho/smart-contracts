Okay, here is a smart contract system implementing a Creative Commons Licensed NFT Factory.

This system allows a factory contract to deploy multiple independent ERC721 collection contracts. Each collection is owned by a "creator", and the NFTs minted within that collection can be assigned specific Creative Commons-like license terms directly on-chain. NFT owners hold not just ownership of the token, but on-chain attestation of the usage rights granted by the creator under the specified license. It also includes features like on-chain usage attestation, optional license expiry, and creator-controlled license revocation.

It avoids duplicating standard OpenZeppelin ERC721 examples directly by building a factory pattern and adding the specific license management, attestation, and expiry features.

---

**Smart Contract System: CreativeCommonsNFTFactory**

**Outline:**

1.  **CreativeCommonsNFTFactory Contract:**
    *   Manages the deployment of `CreativeCommonsNFTCollection` contracts.
    *   Keeps a registry of all deployed collection addresses.
    *   Allows setting a deployment fee.
    *   Owner controls fee withdrawal and factory pausing.
2.  **CreativeCommonsNFTCollection Contract (Deployed by Factory):**
    *   An ERC721 compliant contract representing a collection of NFTs.
    *   Owned by the creator who deployed it via the factory.
    *   Each NFT (`tokenId`) is associated with a specific `LicenseType`.
    *   License terms (commercial use, modification, attribution, share-alike) are encoded and queryable on-chain.
    *   Supports EIP-2981 for creator royalties.
    *   Includes functions for NFT owners to `attestUse` (log usage).
    *   Includes functions for the creator to set license expiry or `revokeLicense`.
    *   Allows NFT owners to set on-chain notes.
    *   Standard ERC721 functions are included for transfer and ownership.

**Function Summary:**

**CreativeCommonsNFTFactory Contract:**

1.  `constructor()`: Initializes the factory owner.
2.  `deployCollection(string memory name, string memory symbol, string memory baseURI, address royaltyRecipient, uint96 royaltyFeeNumerator)`: Deploys a new `CreativeCommonsNFTCollection` contract. Requires deployment fee if set.
3.  `getDeployedCollections()`: Returns an array of addresses of all deployed collections.
4.  `getCollectionCount()`: Returns the total number of deployed collections.
5.  `isDeployedCollection(address collectionAddress)`: Checks if an address is a valid collection deployed by this factory.
6.  `setDeploymentFee(uint256 fee)`: Sets the fee required to deploy a new collection (callable by factory owner).
7.  `getDeploymentFee()`: Returns the current deployment fee.
8.  `withdrawFees()`: Allows the factory owner to withdraw accumulated deployment fees.
9.  `pauseFactory()`: Pauses the factory, preventing new collection deployments (callable by factory owner).
10. `unpauseFactory()`: Unpauses the factory (callable by factory owner).
11. `transferOwnership(address newOwner)`: Transfers factory ownership (callable by factory owner).

**CreativeCommonsNFTCollection Contract (Deployed by Factory):**

12. `constructor(...)`: Called by the factory to initialize the collection, setting its name, symbol, creator, and factory address.
13. `mintWithLicense(address recipient, uint256 tokenId, string memory tokenURI, LicenseType licenseType)`: Mints a new NFT with a specific ID, URI, and assigned `LicenseType` (callable only by the collection creator).
14. `getCreator()`: Returns the address of the collection creator.
15. `getLicenseType(uint256 tokenId)`: Returns the `LicenseType` assigned to a specific token.
16. `getLicenseTerms(uint256 tokenId)`: Returns the detailed boolean terms (commercial, modify, attribute, share-alike) for a token's license.
17. `canUseCommercially(uint256 tokenId)`: Checks if the license for a token allows commercial use.
18. `canModify(uint256 tokenId)`: Checks if the license for a token allows modification/derivative works.
19. `mustAttribute(uint256 tokenId)`: Checks if the license for a token requires attribution.
20. `shareAlike(uint256 tokenId)`: Checks if the license for a token requires sharing derivatives under the same license.
21. `attestUse(uint256 tokenId, string memory useDescription)`: Allows the NFT owner to record an on-chain attestation of how they are using the licensed content.
22. `getUseAttestations(uint256 tokenId)`: Returns the list of use attestations logged for a token.
23. `setLicenseExpiry(uint256 tokenId, uint64 expiryTimestamp)`: Sets an optional expiry timestamp for a token's license (callable by creator).
24. `getLicenseExpiry(uint256 tokenId)`: Returns the expiry timestamp for a token's license (0 if no expiry).
25. `isLicenseExpired(uint256 tokenId)`: Checks if the license for a token has expired.
26. `revokeLicense(uint256 tokenId, string memory reason)`: Allows the creator to revoke the license for a token under exceptional circumstances, logging a reason (callable by creator). *Use with caution, this is a powerful function.*
27. `isLicenseRevoked(uint256 tokenId)`: Checks if the license for a token has been revoked.
28. `setOwnerNotes(uint256 tokenId, string memory notes)`: Allows the NFT owner to attach arbitrary notes to the token on-chain.
29. `getOwnerNotes(uint256 tokenId)`: Returns the on-chain notes attached by the token owner.
30. `updateBaseURI(string memory newBaseURI)`: Updates the base URI for the collection metadata (callable by creator).
31. `setTokenURI(uint256 tokenId, string memory newTokenURI)`: Sets a specific token URI for an individual token (callable by creator).
32. `setRoyaltyInfo(address recipient, uint96 feeNumerator)`: Updates the default royalty information for the collection (callable by creator).
33. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: EIP-2981 implementation: Returns the royalty recipient and amount for a given token sale price.
34. `supportsInterface(bytes4 interfaceId)`: EIP-165 implementation: Indicates support for ERC721, ERC165, and ERC2981.
35. `name()`: ERC721: Returns the collection name.
36. `symbol()`: ERC721: Returns the collection symbol.
37. `totalSupply()`: ERC721: Returns the total number of tokens minted.
38. `balanceOf(address owner)`: ERC721: Returns the number of tokens owned by an address.
39. `ownerOf(uint256 tokenId)`: ERC721: Returns the owner of a specific token.
40. `tokenURI(uint256 tokenId)`: ERC721: Returns the metadata URI for a specific token.
41. `transferFrom(address from, address to, uint256 tokenId)`: ERC721: Transfers ownership of a token.
42. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721: Safely transfers ownership.
43. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721: Safely transfers ownership with data.
44. `approve(address to, uint256 tokenId)`: ERC721: Approves an address to manage a token.
45. `getApproved(uint256 tokenId)`: ERC721: Gets the approved address for a token.
46. `setApprovalForAll(address operator, bool approved)`: ERC721: Sets approval for an operator for all tokens.
47. `isApprovedForAll(address owner, address operator)`: ERC721: Checks if an operator is approved for all tokens.
48. `pauseCollection()`: Pauses minting and transfers for this collection (callable by creator).
49. `unpauseCollection()`: Unpauses the collection (callable by creator).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Using enumerable for getDeployedCollections simplicity
import {IERC165} from "@openzeppelin/contracts/utils/interfaces/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC2981} from "@openzeppelin/contracts/token/ERC721/extensions/ERC2981.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// --- Outline ---
// 1. CreativeCommonsNFTFactory Contract:
//    - Manages deployment of CreativeCommonsNFTCollection contracts.
//    - Registry of deployed collections.
//    - Deployment fee mechanism.
//    - Factory owner controls (fee withdrawal, pausing).
// 2. CreativeCommonsNFTCollection Contract (Deployed by Factory):
//    - ERC721 compliant.
//    - Owned by the creator (who deployed it via factory).
//    - Each NFT has a specific LicenseType.
//    - On-chain license terms (commercial, modify, attribute, share-alike).
//    - EIP-2981 royalties.
//    - On-chain usage attestation logging.
//    - Creator can set license expiry.
//    - Creator can revoke license (with reason).
//    - NFT owner can set on-chain notes.
//    - Standard ERC721 functions.

// --- Function Summary ---
// CreativeCommonsNFTFactory Contract:
// 1. constructor()
// 2. deployCollection(string name, string symbol, string baseURI, address royaltyRecipient, uint96 royaltyFeeNumerator)
// 3. getDeployedCollections()
// 4. getCollectionCount()
// 5. isDeployedCollection(address collectionAddress)
// 6. setDeploymentFee(uint256 fee)
// 7. getDeploymentFee()
// 8. withdrawFees()
// 9. pauseFactory()
// 10. unpauseFactory()
// 11. transferOwnership(address newOwner)
//
// CreativeCommonsNFTCollection Contract (Deployed by Factory):
// 12. constructor(...)
// 13. mintWithLicense(address recipient, uint256 tokenId, string tokenURI, LicenseType licenseType)
// 14. getCreator()
// 15. getLicenseType(uint256 tokenId)
// 16. getLicenseTerms(uint256 tokenId)
// 17. canUseCommercially(uint256 tokenId)
// 18. canModify(uint256 tokenId)
// 19. mustAttribute(uint256 tokenId)
// 20. shareAlike(uint256 tokenId)
// 21. attestUse(uint256 tokenId, string useDescription)
// 22. getUseAttestations(uint256 tokenId)
// 23. setLicenseExpiry(uint256 tokenId, uint64 expiryTimestamp)
// 24. getLicenseExpiry(uint256 tokenId)
// 25. isLicenseExpired(uint256 tokenId)
// 26. revokeLicense(uint256 tokenId, string reason)
// 27. isLicenseRevoked(uint256 tokenId)
// 28. setOwnerNotes(uint256 tokenId, string notes)
// 29. getOwnerNotes(uint256 tokenId)
// 30. updateBaseURI(string newBaseURI)
// 31. setTokenURI(uint256 tokenId, string newTokenURI)
// 32. setRoyaltyInfo(address recipient, uint96 feeNumerator)
// 33. royaltyInfo(uint256 tokenId, uint256 salePrice) (EIP-2981 override)
// 34. supportsInterface(bytes4 interfaceId) (EIP-165 override)
// 35. name() (ERC721)
// 36. symbol() (ERC721)
// 37. totalSupply() (ERC721)
// 38. balanceOf(address owner) (ERC721)
// 39. ownerOf(uint256 tokenId) (ERC721)
// 40. tokenURI(uint256 tokenId) (ERC721 override)
// 41. transferFrom(address from, address to, uint256 tokenId) (ERC721)
// 42. safeTransferFrom(address from, address to, uint256 tokenId) (ERC721)
// 43. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) (ERC721)
// 44. approve(address to, uint256 tokenId) (ERC721)
// 45. getApproved(uint256 tokenId) (ERC721)
// 46. setApprovalForAll(address owner, address operator) (ERC721)
// 47. isApprovedForAll(address owner, address operator) (ERC721)
// 48. pauseCollection() (Pausable)
// 49. unpauseCollection() (Pausable)

// (Note: ERC721Enumerable adds functions like tokenByIndex, tokenOfOwnerByIndex, which would also be available)


// --- Contract Definitions ---

/// @title CreativeCommonsNFTCollection
/// @notice A contract representing a collection of NFTs with Creative Commons-like licensing encoded on-chain.
/// Deployed by the CreativeCommonsNFTFactory. Each instance is owned by the creator.
contract CreativeCommonsNFTCollection is ERC721Enumerable, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Define Creative Commons-like license types
    enum LicenseType {
        UNKNOWN, // Default/Unset state
        CC_0,    // Public Domain Dedication (No Rights Reserved)
        CC_BY,   // Attribution
        CC_BY_SA,// Attribution-ShareAlike
        CC_BY_ND,// Attribution-NoDerivatives
        CC_BY_NC,// Attribution-NonCommercial
        CC_BY_NC_SA, // Attribution-NonCommercial-ShareAlike
        CC_BY_NC_ND // Attribution-NonCommercial-NoDerivatives
    }

    // --- State Variables ---
    address public immutable factoryAddress;
    address public immutable creator; // The address that deployed this collection via the factory

    // Mapping from tokenId to its assigned LicenseType
    mapping(uint256 => LicenseType) private _tokenLicenses;

    // Mapping from tokenId to an optional license expiry timestamp (Unix time)
    mapping(uint256 => uint64) private _licenseExpiry;

    // Mapping from tokenId to a flag indicating if the license has been revoked by the creator
    mapping(uint256 => bool) private _licenseRevoked;
    // Mapping from tokenId to revocation reason
    mapping(uint256 => string) private _revocationReason;

    // Mapping from tokenId to array of use attestations (logged by NFT owner)
    mapping(uint256 => string[]) private _useAttestations;

    // Mapping from tokenId to arbitrary notes set by the NFT owner
    mapping(uint256 => string) private _ownerNotes;

    string private _baseTokenURI;

    // --- Events ---
    event LicenseAssigned(uint256 indexed tokenId, LicenseType licenseType);
    event LicenseExpirySet(uint256 indexed tokenId, uint64 expiryTimestamp);
    event LicenseRevoked(uint256 indexed tokenId, string reason);
    event UseAttested(uint256 indexed tokenId, address indexed owner, string useDescription);
    event OwnerNotesUpdated(uint256 indexed tokenId, address indexed owner, string notes);
    event BaseURIUpdated(string newBaseURI);
    event TokenURIUpdated(uint256 indexed tokenId, string newTokenURI);
    event RoyaltyInfoUpdated(address indexed recipient, uint96 feeNumerator);

    // --- Errors ---
    error NotCollectionCreator();
    error TokenDoesNotExist(uint256 tokenId);
    error TokenAlreadyExists(uint256 tokenId);
    error InvalidLicenseType();


    /// @notice Constructor called by the factory to deploy a new collection.
    /// @param name_ The name of the NFT collection.
    /// @param symbol_ The symbol of the NFT collection.
    /// @param baseURI_ The base URI for token metadata.
    /// @param creator_ The address that initiated the deployment via the factory.
    /// @param factory_ The address of the deploying factory contract.
    /// @param royaltyRecipient The default recipient for royalties.
    /// @param royaltyFeeNumerator The default royalty fee numerator (e.g., 500 for 5%).
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address creator_,
        address factory_,
        address royaltyRecipient,
        uint96 royaltyFeeNumerator
    )
        ERC721(name_, symbol_)
        Ownable(creator_) // Collection owner is the creator
        ERC2981()
    {
        creator = creator_;
        factoryAddress = factory_;
        _baseTokenURI = baseURI_;
        _setDefaultRoyalty(royaltyRecipient, royaltyFeeNumerator);
    }

    // --- Modifiers ---
    modifier onlyCollectionCreator() {
        if (msg.sender != creator) revert NotCollectionCreator();
        _;
    }

    // --- Minting ---

    /// @notice Mints a new NFT and assigns it a specific license type.
    /// @param recipient The address to receive the NFT.
    /// @param tokenId The ID for the new token.
    /// @param tokenURI_ The URI for the token's metadata.
    /// @param licenseType The Creative Commons-like license type to assign.
    function mintWithLicense(
        address recipient,
        uint256 tokenId,
        string memory tokenURI_,
        LicenseType licenseType
    ) external onlyCollectionCreator whenNotPaused {
        // Use counter if tokenId == 0 or similar convention, or allow explicit ID.
        // Using explicit ID here as the creator might have specific IDs in mind.
        // Ensure ID is not already minted.
        if (_exists(tokenId)) revert TokenAlreadyExists(tokenId);

        // Ensure UNKNOWN license type is not assigned during minting
        if (licenseType == LicenseType.UNKNOWN) revert InvalidLicenseType();

        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        _tokenLicenses[tokenId] = licenseType;
        emit LicenseAssigned(tokenId, licenseType);
    }

    // --- License Query Functions ---

    /// @notice Gets the assigned LicenseType enum for a token.
    /// @param tokenId The ID of the token.
    /// @return The LicenseType enum value.
    function getLicenseType(uint256 tokenId) public view returns (LicenseType) {
        _requireMinted(tokenId);
        return _tokenLicenses[tokenId];
    }

    /// @notice Gets the specific boolean terms derived from a token's license type.
    /// @param tokenId The ID of the token.
    /// @return commercial Use allowed commercially.
    /// @return modify Modification/Derivatives allowed.
    /// @return attribute Attribution required.
    /// @return shareAlike Share derivatives under same license.
    function getLicenseTerms(uint256 tokenId)
        public
        view
        returns (bool commercial, bool modify, bool attribute, bool shareAlike)
    {
        _requireMinted(tokenId);
        return _getLicenseTerms(_tokenLicenses[tokenId]);
    }

    /// @notice Helper function to interpret LicenseType enum into boolean terms.
    /// @param licenseType The LicenseType enum value.
    /// @return commercial Use allowed commercially.
    /// @return modify Modification/Derivatives allowed.
    /// @return attribute Attribution required.
    /// @return shareAlike Share derivatives under same license.
    function _getLicenseTerms(LicenseType licenseType)
        internal
        pure
        returns (bool commercial, bool modify, bool attribute, bool shareAlike)
    {
        // Based on common CC license interpretations
        // See: https://creativecommons.org/share-your-work/cclicenses/
        // Note: CC0 is handled separately as it's effectively public domain
        attribute = false; // Default to false
        commercial = true; // Default to true
        modify = true;     // Default to true
        shareAlike = false;// Default to false

        if (licenseType == LicenseType.CC_BY) {
            attribute = true;
        } else if (licenseType == LicenseType.CC_BY_SA) {
            attribute = true;
            shareAlike = true;
        } else if (licenseType == LicenseType.CC_BY_ND) {
            attribute = true;
            modify = false; // No Derivatives
        } else if (licenseType == LicenseType.CC_BY_NC) {
            attribute = true;
            commercial = false; // Non-Commercial
        } else if (licenseType == LicenseType.CC_BY_NC_SA) {
            attribute = true;
            commercial = false; // Non-Commercial
            shareAlike = true;
        } else if (licenseType == LicenseType.CC_BY_NC_ND) {
            attribute = true;
            commercial = false; // Non-Commercial
            modify = false;     // No Derivatives
        }
        // CC_0 implies all true (effectively public domain, no restrictions)
        else if (licenseType == LicenseType.CC_0) {
            attribute = true; // While CC0 says no rights reserved, attribution is standard practice
            commercial = true;
            modify = true;
            shareAlike = false; // No requirement to share alike
        }

        // UNKNOWN implies unknown terms or potentially no rights granted initially
        // Defaults (false, true, true, false) are arbitrary for UNKNOWN.
        // Caller should handle UNKNOWN appropriately.

        return (commercial, modify, attribute, shareAlike);
    }

    /// @notice Checks if the license for a token allows commercial use.
    /// @param tokenId The ID of the token.
    /// @return True if commercial use is allowed, false otherwise.
    function canUseCommercially(uint256 tokenId) public view returns (bool) {
         _requireMinted(tokenId);
        (bool commercial, , , ) = _getLicenseTerms(_tokenLicenses[tokenId]);
        return commercial;
    }

    /// @notice Checks if the license for a token allows modification/derivative works.
    /// @param tokenId The ID of the token.
    /// @return True if modification is allowed, false otherwise.
    function canModify(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        (, bool modify, , ) = _getLicenseTerms(_tokenLicenses[tokenId]);
        return modify;
    }

    /// @notice Checks if the license for a token requires attribution.
    /// @param tokenId The ID of the token.
    /// @return True if attribution is required, false otherwise.
    function mustAttribute(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        (, , bool attribute, ) = _getLicenseTerms(_tokenLicenses[tokenId]);
        return attribute;
    }

    /// @notice Checks if the license for a token requires sharing derivatives under the same license.
    /// @param tokenId The ID of the token.
    /// @return True if share-alike is required, false otherwise.
    function shareAlike(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        (, , , bool shareAlikeTerm) = _getLicenseTerms(_tokenLicenses[tokenId]);
        return shareAlikeTerm;
    }

    // --- Usage Attestation ---

    /// @notice Allows the current owner of an NFT to record an on-chain attestation of how they are using the licensed content.
    /// This is for documentation/transparency, not legal enforcement within the contract.
    /// @param tokenId The ID of the token.
    /// @param useDescription A string describing the use case (e.g., "Used as album art for 'My Song'", "Included in blog post 'Creative Uses'").
    function attestUse(uint256 tokenId, string memory useDescription) public whenNotPaused {
        _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable's error for consistency
        _useAttestations[tokenId].push(useDescription);
        emit UseAttested(tokenId, msg.sender, useDescription);
    }

    /// @notice Retrieves all recorded use attestations for a token.
    /// @param tokenId The ID of the token.
    /// @return An array of strings, each being a use description.
    function getUseAttestations(uint256 tokenId) public view returns (string[] memory) {
        _requireMinted(tokenId);
        return _useAttestations[tokenId];
    }

    // --- License Expiry ---

    /// @notice Sets an optional expiry timestamp for a token's license.
    /// After this time, the license terms are considered expired *by this contract*.
    /// The legal interpretation outside the chain is up to the parties and license terms.
    /// @param tokenId The ID of the token.
    /// @param expiryTimestamp The Unix timestamp when the license expires (0 to clear expiry).
    function setLicenseExpiry(uint256 tokenId, uint64 expiryTimestamp) public onlyCollectionCreator {
        _requireMinted(tokenId);
        _licenseExpiry[tokenId] = expiryTimestamp;
        emit LicenseExpirySet(tokenId, expiryTimestamp);
    }

    /// @notice Gets the expiry timestamp for a token's license.
    /// @param tokenId The ID of the token.
    /// @return The Unix timestamp of expiry, or 0 if no expiry is set.
    function getLicenseExpiry(uint256 tokenId) public view returns (uint64) {
         _requireMinted(tokenId);
        return _licenseExpiry[tokenId];
    }

    /// @notice Checks if the license for a token has passed its expiry timestamp.
    /// @param tokenId The ID of the token.
    /// @return True if the license is expired (expiry set and current time >= expiry), false otherwise.
    function isLicenseExpired(uint256 tokenId) public view returns (bool) {
         _requireMinted(tokenId);
        uint64 expiry = _licenseExpiry[tokenId];
        // License is expired if expiry is set (>0) and current block timestamp is >= expiry
        return expiry > 0 && block.timestamp >= expiry;
    }

    // --- License Revocation ---

    /// @notice Allows the collection creator to revoke a token's license.
    /// This function represents an extreme action and should be used judiciously according to external legal agreements.
    /// Revoking sets a flag and stores a reason on-chain.
    /// @param tokenId The ID of the token.
    /// @param reason A string explaining the reason for revocation.
    function revokeLicense(uint256 tokenId, string memory reason) public onlyCollectionCreator {
        _requireMinted(tokenId);
        _licenseRevoked[tokenId] = true;
        _revocationReason[tokenId] = reason;
        emit LicenseRevoked(tokenId, reason);
    }

    /// @notice Checks if a token's license has been revoked by the creator.
    /// @param tokenId The ID of the token.
    /// @return True if the license is revoked, false otherwise.
    function isLicenseRevoked(uint256 tokenId) public view returns (bool) {
         _requireMinted(tokenId);
        return _licenseRevoked[tokenId];
    }

    // --- Owner Notes ---

    /// @notice Allows the current owner of an NFT to attach arbitrary public notes to the token on-chain.
    /// @param tokenId The ID of the token.
    /// @param notes The string of notes to attach.
    function setOwnerNotes(uint256 tokenId, string memory notes) public whenNotPaused {
         _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        _ownerNotes[tokenId] = notes;
        emit OwnerNotesUpdated(tokenId, msg.sender, notes);
    }

    /// @notice Retrieves the on-chain notes attached by the token owner.
    /// @param tokenId The ID of the token.
    /// @return The string of notes.
    function getOwnerNotes(uint256 tokenId) public view returns (string memory) {
         _requireMinted(tokenId);
        return _ownerNotes[tokenId];
    }


    // --- Creator/Collection Owner Management ---

    /// @notice Updates the base URI for tokens in this collection.
    /// @param newBaseURI The new base URI.
    function updateBaseURI(string memory newBaseURI) public onlyCollectionCreator {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /// @notice Sets a specific token URI for an individual token, overriding the base URI.
    /// @param tokenId The ID of the token.
    /// @param newTokenURI The specific URI for this token.
    function setTokenURI(uint256 tokenId, string memory newTokenURI) public onlyCollectionCreator {
         _requireMinted(tokenId);
        _setTokenURI(tokenId, newTokenURI);
        emit TokenURIUpdated(tokenId, newTokenURI);
    }

    /// @notice Updates the default royalty information for the collection (EIP-2981).
    /// @param recipient The new royalty recipient.
    /// @param feeNumerator The new royalty fee numerator (denominator is always 10000).
    function setRoyaltyInfo(address recipient, uint96 feeNumerator) public onlyCollectionCreator {
        _setDefaultRoyalty(recipient, feeNumerator);
        emit RoyaltyInfoUpdated(recipient, feeNumerator);
    }


    /// @notice Pauses minting and transfers for this collection.
    function pauseCollection() public onlyCollectionCreator {
        _pause();
    }

    /// @notice Unpauses the collection.
    function unpauseCollection() public onlyCollectionCreator {
        _unpause();
    }

    // --- ERC721 & ERC2981 Overrides ---

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721Enumerable) // Needs to override both if using Enumerable
        returns (string memory)
    {
        _requireMinted(tokenId); // Ensure token exists before getting URI
        string memory _tokenURI = super.tokenURI(tokenId);
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI; // Use specific URI if set
        }
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId))); // Use base URI otherwise
    }

    /// @inheritdoc ERC2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC2981, IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
         // This collection uses default royalty for all tokens, set via setRoyaltyInfo.
         // If specific token royalties were needed, this function would be more complex.
        return super.royaltyInfo(tokenId, salePrice);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        // This function is typically used by the default ERC721 tokenURI implementation.
        // We override tokenURI directly above to handle specific URIs vs base URI.
        // Returning the base URI here provides a fallback if the override logic changes.
        return _baseTokenURI;
    }

    /// @inheritdoc ERC721
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        // Add pausable check to core transfer logic
        _requireNotPaused();
        return super._update(to, tokenId, auth);
    }

     /// @inheritdoc ERC721
    function _increaseBalance(address account, uint255 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    /// @inheritdoc ERC721Enumerable
    function tokenByIndex(uint256 index)
        public
        view
        override(ERC721Enumerable, IERC721Enumerable)
        returns (uint256)
    {
        return super.tokenByIndex(index);
    }

    /// @inheritdoc ERC721Enumerable
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override(ERC721Enumerable, IERC721Enumerable)
        returns (uint256)
    {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    // Internal helper to check if a token exists and revert if not
    function _requireMinted(uint256 tokenId) internal view {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
    }
}


/// @title CreativeCommonsNFTFactory
/// @notice A factory contract to deploy CreativeCommonsNFTCollection instances.
contract CreativeCommonsNFTFactory is Ownable, Pausable {
    using Address for address payable;

    // --- State Variables ---
    address[] public deployedCollections;
    mapping(address => bool) public isDeployedCollection; // Verification map
    uint256 public deploymentFee = 0; // Fee to deploy a new collection

    // --- Events ---
    event CollectionDeployed(address indexed collectionAddress, string name, string symbol, address indexed creator);
    event DeploymentFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {} // Factory owner is the deployer

    // --- Factory Functions ---

    /// @notice Deploys a new CreativeCommonsNFTCollection contract.
    /// @param name The name for the new collection.
    /// @param symbol The symbol for the new collection.
    /// @param baseURI The base URI for the new collection's metadata.
    /// @param royaltyRecipient The default royalty recipient for the collection (EIP-2981).
    /// @param royaltyFeeNumerator The default royalty fee numerator for the collection (e.g., 500 for 5%).
    function deployCollection(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address royaltyRecipient,
        uint96 royaltyFeeNumerator
    ) external payable whenNotPaused returns (address) {
        if (msg.value < deploymentFee) revert InsufficientPayment(deploymentFee, msg.value); // Using Ownable's error for simplicity

        CreativeCommonsNFTCollection newCollection = new CreativeCommonsNFTCollection(
            name,
            symbol,
            baseURI,
            msg.sender, // Creator is the caller of this function
            address(this), // Factory address
            royaltyRecipient,
            royaltyFeeNumerator
        );

        deployedCollections.push(address(newCollection));
        isDeployedCollection[address(newCollection)] = true;

        emit CollectionDeployed(address(newCollection), name, symbol, msg.sender);

        // Refund any excess payment
        if (msg.value > deploymentFee) {
             payable(msg.sender).sendValue(msg.value - deploymentFee);
        }

        return address(newCollection);
    }

    /// @notice Gets the list of addresses of all collections deployed by this factory.
    /// @return An array of collection addresses.
    function getDeployedCollections() external view returns (address[] memory) {
        return deployedCollections;
    }

    /// @notice Gets the total number of collections deployed by this factory.
    /// @return The count of deployed collections.
    function getCollectionCount() external view returns (uint256) {
        return deployedCollections.length;
    }

    /// @notice Checks if a given address is a valid collection deployed by this factory.
    /// @param collectionAddress The address to check.
    /// @return True if the address is a deployed collection, false otherwise.
    function isDeployedCollection(address collectionAddress) public view returns (bool) {
        return isDeployedCollection[collectionAddress];
    }

    // --- Factory Owner Functions ---

    /// @notice Sets the fee required to deploy a new collection.
    /// @param fee The new deployment fee in wei.
    function setDeploymentFee(uint256 fee) external onlyOwner {
        deploymentFee = fee;
        emit DeploymentFeeUpdated(fee);
    }

    /// @notice Gets the current deployment fee.
    /// @return The current deployment fee in wei.
    function getDeploymentFee() external view returns (uint256) {
        return deploymentFee;
    }

    /// @notice Allows the factory owner to withdraw accumulated deployment fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).sendValue(balance);
            emit FeesWithdrawn(owner(), balance);
        }
    }

    /// @notice Pauses the factory, preventing new collection deployments.
    function pauseFactory() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the factory.
    function unpauseFactory() external onlyOwner {
        _unpause();
    }

    // The factory needs to be able to receive ether for the deployment fee.
    receive() external payable {}
    fallback() external payable {}
}
```