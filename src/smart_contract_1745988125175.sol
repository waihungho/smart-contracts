Okay, here is a Solidity smart contract for a SoulBound Certificate NFT system.

This contract implements a non-transferable NFT designed to represent verifiable certificates or credentials tied to a specific address ("Soul"). It includes features for issuance by designated issuers, revocation, expiration, batch operations, and various querying mechanisms. It aims to be advanced by combining the SoulBound concept with structured certificate data, specific roles, and batching, while avoiding direct copy-pasting of common open-source library patterns like OpenZeppelin's `Ownable` or `AccessControl` (though the *concepts* are similar, the implementation is custom for this example). The core ERC721 functionality is also included directly for this example.

**Disclaimer:**
*   This contract is for educational and demonstration purposes.
*   Manually implementing ERC721 and access control patterns is less secure and less gas-efficient than using battle-tested libraries like OpenZeppelin. For production, always use audited libraries.
*   Storing dynamic arrays in storage (`_soulTokens`, `_typeTokens`, `_issuerTokens`) can be very gas-intensive for large numbers of tokens or frequent updates (like burning/revoking which requires element removal). Consider alternative data structures or off-chain indexing for large-scale applications.
*   This contract is provided "as-is" and has not been formally audited.

---

### Contract Outline & Function Summary

**Contract Name:** `SoulBoundCertificateNFT`

**Concept:** Implements a SoulBound Token (SBT) standard specifically for issuing and managing non-transferable certificates or credentials on the blockchain. Certificates are tied to a recipient ("Soul") and issued by authorized parties. They can have expiration dates and can be revoked.

**Key Features:**
1.  **SoulBound (Non-Transferable):** NFTs cannot be transferred between addresses. They are bound to the recipient's wallet.
2.  **Role-Based Issuance:** Only designated "Issuers" can create new certificates.
3.  **Structured Certificate Data:** Each certificate stores details like recipient, issuer, type, issue date, expiration date, and revocation status.
4.  **Revocation Mechanism:** Issuers can revoke previously issued certificates.
5.  **Expiration:** Certificates can be issued with an optional expiration timestamp.
6.  **Verification:** Functions to check the validity (not revoked, not expired) and retrieve details of a certificate.
7.  **Querying:** Functions to query certificates based on the Soul, Issuer, or Certificate Type.
8.  **Batch Operations:** Efficiency functions for issuing or revoking multiple certificates at once.
9.  **Self-Burning:** The Soul can burn their own certificate.

**Function Summary:**

*   **ERC721 Overrides (Preventing Transfer):**
    *   `transferFrom(address from, address to, uint256 tokenId)`: Prevents token transfer (reverts).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Prevents token transfer (reverts).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Prevents token transfer (reverts).
    *   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal hook to enforce non-transferability logic before minting, transferring (prevented), or burning.

*   **Admin/Issuer Management:**
    *   `constructor(string memory name, string memory symbol)`: Deploys the contract, setting name, symbol, and initial owner.
    *   `addIssuer(address account)`: Grants the `account` the role of an Issuer (Owner only).
    *   `removeIssuer(address account)`: Revokes the Issuer role from the `account` (Owner only).
    *   `isIssuer(address account)`: Checks if an address is a current Issuer.
    *   `getIssuers()`: Returns a list of all addresses currently holding the Issuer role.
    *   `owner()`: Returns the address of the contract owner.

*   **Core Certificate Lifecycle:**
    *   `issueCertificate(address soul, uint256 certificateType, uint64 expirationTimestamp, string memory uri)`: Issues a single new certificate to a `soul` of a specific `certificateType` with an optional `expirationTimestamp` and `uri`. Only Issuers can call.
    *   `batchIssueCertificates(address[] souls, uint256[] certificateTypes, uint64[] expirationTimestamps, string[] uris)`: Issues multiple certificates in a single transaction. Only Issuers can call.
    *   `revokeCertificate(uint256 tokenId)`: Marks a specific certificate as revoked. Only the certificate's original Issuer or the contract Owner can call.
    *   `batchRevokeCertificates(uint256[] tokenIds)`: Revokes multiple certificates in a single transaction. Only Issuers or Owner can call.
    *   `burnMyCertificate(uint256 tokenId)`: Allows the certificate holder (the Soul) to permanently destroy their certificate.

*   **Certificate Data & Status Queries:**
    *   `getCertificate(uint256 tokenId)`: Retrieves the full details of a certificate by its token ID.
    *   `isCertificateValid(uint256 tokenId)`: Checks if a certificate exists, is not revoked, and has not expired.
    *   `getCertificateExpiration(uint256 tokenId)`: Returns the expiration timestamp of a certificate.
    *   `getCertificateType(uint256 tokenId)`: Returns the type ID of a certificate.
    *   `getCertificateIssuer(uint256 tokenId)`: Returns the address of the issuer of a certificate.
    *   `getCertificateIssueDate(uint256 tokenId)`: Returns the issuance timestamp of a certificate.
    *   `getCertificateRevokedStatus(uint256 tokenId)`: Returns the revoked status of a certificate.

*   **Indexed Queries (Potentially Gas-Intensive):**
    *   `getCertificatesBySoul(address soul)`: Returns an array of token IDs held by a specific Soul.
    *   `getCertificatesByType(uint256 certificateType)`: Returns an array of token IDs for a specific certificate type.
    *   `getCertificatesByIssuer(address issuer)`: Returns an array of token IDs issued by a specific Issuer.

*   **General ERC721 & Utility Queries:**
    *   `totalSupply()`: Returns the total number of NFTs ever minted.
    *   `balanceOf(address _owner)`: Returns the number of NFTs owned by a Soul (standard ERC721, here meaning certificates held).
    *   `ownerOf(uint256 tokenId)`: Returns the address of the Soul holding the certificate (standard ERC721).
    *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a certificate.
    *   `setTokenURI(uint256 tokenId, string memory _tokenURI)`: Allows the issuer to update the token URI (e.g., to link to updated status metadata). Restricted to the issuer or owner.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a token (always address(0) for SBTs).
    *   `isApprovedForAll(address _owner, address operator)`: Returns approval status for all tokens (always false for SBTs).
    *   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support check (includes ERC165, ERC721, ERC721Enumerable - if implemented, ERC721Metadata).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * Contract Outline & Function Summary:
 * (See detailed summary above the contract code)
 */

import {IERC721, IERC721Metadata, IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // Using OpenZeppelin's ERC165 for correctness


contract SoulBoundCertificateNFT is ERC165, IERC721, IERC721Metadata {

    // --- Structs ---
    struct Certificate {
        address soul;           // The address the certificate is bound to
        address issuer;         // The address that issued the certificate
        uint256 certificateType;// An identifier for the type of certificate (e.g., 1 for Completion, 2 for Skill)
        uint64 issueDate;       // Timestamp of issuance
        uint64 expirationDate;  // Timestamp of expiration (0 if no expiration)
        bool revoked;           // Whether the certificate has been revoked
        string uri;             // Metadata URI for the token
    }

    // --- State Variables ---

    // ERC721 standard state
    string private _name;
    string private _symbol;
    uint256 private _tokenIdCounter;
    mapping(uint256 => address) private _owners;         // tokenId => owner (Soul)
    mapping(address => uint256) private _balances;       // owner (Soul) => balance
    mapping(uint256 => string) private _tokenURIs;      // tokenId => token URI

    // Certificate-specific state
    mapping(uint256 => Certificate) private _certificates; // tokenId => Certificate data

    // Role-based access control (custom implementation)
    address private _owner; // Contract deployer/owner
    mapping(address => bool) private _issuers; // issuer address => isIssuer
    address[] private _issuerList; // List of issuers for retrieval

    // Indexed mappings for querying (potentially gas-intensive for modifications)
    mapping(address => uint256[]) private _soulTokens;    // soul => list of tokenIds
    mapping(uint256 => uint256[]) private _typeTokens;    // certificateType => list of tokenIds
    mapping(address => uint256[]) private _issuerTokens;  // issuer => list of tokenIds


    // --- Events ---
    event CertificateIssued(uint256 indexed tokenId, address indexed soul, address indexed issuer, uint256 certificateType, uint64 expirationDate);
    event CertificateRevoked(uint256 indexed tokenId, address indexed issuer);
    event CertificateBurned(uint256 indexed tokenId, address indexed soul);
    event IssuerAdded(address indexed account, address indexed addedBy);
    event IssuerRemoved(address indexed account, address indexed removedBy);
    event TokenURIUpdated(uint256 indexed tokenId, string newURI); // Not standard ERC721, but useful

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyIssuer() {
        require(_issuers[msg.sender] || msg.sender == _owner, "Only issuer or owner can call this function");
        _;
    }

    modifier onlySoul(uint256 tokenId) {
         require(_exists(tokenId), "Token does not exist");
         require(msg.sender == _owners[tokenId], "Only the token soul can call this function");
         _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        // Optionally add the owner as an initial issuer
        _addIssuer(msg.sender);
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId;
               // || interfaceId == type(IERC721Enumerable).interfaceId; // If adding full enumeration
    }

    // --- ERC721 Standard Implementations (Overridden for SoulBound) ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        // Could dynamically update URI based on validity here if needed
        return _tokenURIs[tokenId];
    }

    // --- SoulBound Enforcement (Preventing Transfers) ---

    function approve(address to, uint256 tokenId) public pure override {
        // SoulBound tokens are non-transferable, so approval is not allowed.
        // Revert explicitly or implicitly by doing nothing (revert is clearer).
        revert("SoulBound: Token is non-transferable");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        // SoulBound tokens are non-transferable, so approval is not allowed.
        revert("SoulBound: Token is non-transferable");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "Token does not exist");
        // For SoulBound, there is no approved address other than the owner, but ownerOf is used for that.
        // Returning address(0) is standard for no approval set.
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // For SoulBound, no operator can be approved for all tokens.
        return false;
    }

    // Core transfer functions are overridden to prevent transfers
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SoulBound: Token is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SoulBound: Token is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("SoulBound: Token is non-transferable");
    }

    // Internal hook that is called before any token transfer (mint, transfer, burn)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Prevent transfers (from != address(0) and to != address(0))
        require(from == address(0) || to == address(0), "SoulBound: Token is non-transferable");

        // Note: Burning (to == address(0)) and Minting (from == address(0)) are allowed.
        // Transferring from 0 to 0 is not possible.
    }

    // --- Internal ERC721 Helpers (Simplified) ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId, string memory uri_) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to]++;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = uri_;

        // Indexing for queries (potentially gas-intensive)
        _soulTokens[to].push(tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: burn of non-existent token");

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals (though not used for SBTs)
        // delete _tokenApprovals[tokenId];

        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        delete _certificates[tokenId]; // Also delete certificate data

        // Remove from indexing arrays (very gas-intensive!)
        _removeTokenFromSoulIndex(owner, tokenId);
        // Need type and issuer to remove from their indexes - retrieve before deleting certificate data
        // This makes _burn more complex. A simpler approach might be to just not remove from indexes on burn.
        // Let's keep it simple for this example and accept the limitation or complexity.
        // To correctly remove from _typeTokens and _issuerTokens, we'd need to read _certificates[tokenId] FIRST.
        // Let's modify _burn slightly or add a helper. Helper approach is cleaner.
        _burnHelper(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    // Helper burn function to handle index removal
    function _burnHelper(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: burn of non-existent token");

        // Get certificate data BEFORE deleting it
        Certificate storage cert = _certificates[tokenId];
        uint256 certType = cert.certificateType;
        address issuer = cert.issuer;

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        delete _certificates[tokenId];

        // Remove from indexing arrays (very gas-intensive operations)
        _removeTokenFromSoulIndex(owner, tokenId);
        _removeTokenFromTypeIndex(certType, tokenId);
        _removeTokenFromIssuerIndex(issuer, tokenId);

        emit Transfer(owner, address(0), tokenId);
    }


    // --- Index Management Helpers (Gas-Intensive Array Operations) ---

    // Finds and removes a tokenId from a dynamic array in storage
    function _removeTokenFromArray(uint256[] storage arr, uint256 tokenId) internal {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == tokenId) {
                arr[i] = arr[arr.length - 1]; // Replace with last element
                arr.pop(); // Remove last element
                return; // Found and removed
            }
        }
        // Token not found in array (shouldn't happen if logic is correct)
    }

    function _removeTokenFromSoulIndex(address soul, uint256 tokenId) internal {
        _removeTokenFromArray(_soulTokens[soul], tokenId);
    }

    function _removeTokenFromTypeIndex(uint256 certType, uint256 tokenId) internal {
        _removeTokenFromArray(_typeTokens[certType], tokenId);
    }

    function _removeTokenFromIssuerIndex(address issuer, uint256 tokenId) internal {
        _removeTokenFromArray(_issuerTokens[issuer], tokenId);
    }

    // --- Admin/Issuer Management ---

    function owner() public view returns (address) {
        return _owner;
    }

    function addIssuer(address account) public onlyOwner {
        require(account != address(0), "Issuer address cannot be zero");
        require(!_issuers[account], "Account is already an issuer");
        _issuers[account] = true;
        _issuerList.push(account); // Add to list
        emit IssuerAdded(account, msg.sender);
    }

    function removeIssuer(address account) public onlyOwner {
        require(account != address(0), "Issuer address cannot be zero");
        require(_issuers[account], "Account is not an issuer");
        require(account != _owner, "Cannot remove owner as issuer via this function"); // Owner is always an implicit issuer/admin

        _issuers[account] = false;
        // Remove from list (gas-intensive)
        for (uint i = 0; i < _issuerList.length; i++) {
            if (_issuerList[i] == account) {
                _issuerList[i] = _issuerList[_issuerList.length - 1];
                _issuerList.pop();
                break;
            }
        }
        emit IssuerRemoved(account, msg.sender);
    }

    function isIssuer(address account) public view returns (bool) {
        return _issuers[account] || account == _owner; // Owner is also considered an issuer
    }

    function getIssuers() public view returns (address[] memory) {
         // Create a temporary array excluding the owner if they are explicitly in _issuerList
         // Or just return the list and let the caller know owner is always an issuer
         // Let's return the list, it's simpler. The isIssuer function handles the owner case.
         return _issuerList;
    }


    // --- Core Certificate Lifecycle ---

    function issueCertificate(
        address soul,
        uint256 certificateType,
        uint64 expirationTimestamp,
        string memory uri_
    ) public onlyIssuer returns (uint256 tokenId) {
        require(soul != address(0), "Cannot issue to the zero address");
        require(certificateType > 0, "Certificate type cannot be zero");

        tokenId = _tokenIdCounter++;

        _certificates[tokenId] = Certificate({
            soul: soul,
            issuer: msg.sender,
            certificateType: certificateType,
            issueDate: uint64(block.timestamp),
            expirationDate: expirationTimestamp,
            revoked: false,
            uri: uri_
        });

        _mint(soul, tokenId, uri_); // Mints the NFT and handles _soulTokens indexing

        // Add to other indexing arrays (potentially gas-intensive)
        _typeTokens[certificateType].push(tokenId);
        _issuerTokens[msg.sender].push(tokenId);

        emit CertificateIssued(tokenId, soul, msg.sender, certificateType, expirationTimestamp);
    }

    function batchIssueCertificates(
        address[] memory souls,
        uint256[] memory certificateTypes,
        uint64[] memory expirationTimestamps,
        string[] memory uris
    ) public onlyIssuer {
        require(souls.length == certificateTypes.length &&
                souls.length == expirationTimestamps.length &&
                souls.length == uris.length, "Array lengths must match");

        for (uint i = 0; i < souls.length; i++) {
             // Internal call to issue single certificate
            issueCertificate(souls[i], certificateTypes[i], expirationTimestamps[i], uris[i]);
            // Note: This will emit an event for each certificate issued.
            // For maximum efficiency, a dedicated internal batch mint/index function could be written
            // that avoids redundant checks/events inside the loop, but calling the single issue function
            // is clearer for demonstration.
        }
    }


    function revokeCertificate(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");

        Certificate storage cert = _certificates[tokenId];
        require(!cert.revoked, "Certificate is already revoked");

        // Only the original issuer or the owner can revoke
        require(msg.sender == cert.issuer || msg.sender == _owner, "Only the issuer or owner can revoke");

        cert.revoked = true;

        // Consider updating the URI here to reflect revoked status if using dynamic metadata
        // string memory revokedUri = "ipfs://.../revoked_metadata.json"; // Example
        // _setTokenURI(tokenId, revokedUri); // Need to implement _setTokenURI

        emit CertificateRevoked(tokenId, msg.sender);
    }

     function batchRevokeCertificates(uint256[] memory tokenIds) public {
         for (uint i = 0; i < tokenIds.length; i++) {
             // Internal call to revoke single certificate
             revokeCertificate(tokenIds[i]); // Will perform permission checks per token
         }
     }

    function burnMyCertificate(uint256 tokenId) public onlySoul(tokenId) {
         require(_exists(tokenId), "Token does not exist");
         // _burnHelper handles the actual burning and index removal
         _burnHelper(tokenId);
         emit CertificateBurned(tokenId, msg.sender);
    }


    // --- Certificate Data & Status Queries ---

    function getCertificate(uint256 tokenId) public view returns (
        address soul,
        address issuer,
        uint256 certificateType,
        uint64 issueDate,
        uint64 expirationDate,
        bool revoked,
        string memory uri_
    ) {
        require(_exists(tokenId), "Token does not exist");
        Certificate storage cert = _certificates[tokenId];
        return (
            cert.soul,
            cert.issuer,
            cert.certificateType,
            cert.issueDate,
            cert.expirationDate,
            cert.revoked,
            cert.uri // Note: This returns the stored URI, not necessarily the tokenURI() result if _setTokenURI is used.
        );
    }

    function isCertificateValid(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) {
            return false; // Doesn't exist
        }
        Certificate storage cert = _certificates[tokenId];
        if (cert.revoked) {
            return false; // Is revoked
        }
        if (cert.expirationDate > 0 && cert.expirationDate < block.timestamp) {
            return false; // Has expired
        }
        return true; // Exists, not revoked, not expired
    }

    function getCertificateExpiration(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "Token does not exist");
        return _certificates[tokenId].expirationDate;
    }

    function getCertificateType(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _certificates[tokenId].certificateType;
    }

    function getCertificateIssuer(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return _certificates[tokenId].issuer;
    }

    function getCertificateIssueDate(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "Token does not exist");
        return _certificates[tokenId].issueDate;
    }

     function getCertificateRevokedStatus(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Token does not exist");
         return _certificates[tokenId].revoked;
     }

    // --- Indexed Queries (Potentially Gas-Intensive) ---

    function getCertificatesBySoul(address soul) public view returns (uint256[] memory) {
        return _soulTokens[soul]; // Returns the array of token IDs
    }

    function getCertificatesByType(uint256 certificateType) public view returns (uint256[] memory) {
        return _typeTokens[certificateType]; // Returns the array of token IDs
    }

    function getCertificatesByIssuer(address issuer) public view returns (uint256[] memory) {
        return _issuerTokens[issuer]; // Returns the array of token IDs
    }

    // --- General ERC721 & Utility Queries ---

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter; // Returns the number of tokens ever attempted to be minted
        // Note: This is not the *actual* number of existing tokens if some were burned.
        // To get actual existing tokens, you'd need an explicit counter incremented on mint/decremented on burn,
        // or track all token IDs in a separate enumerable structure (like ERC721Enumerable).
        // For this example, _tokenIdCounter serves as a simple total *issued* count.
    }

     // Internal function to set token URI (used by issue and potentially setTokenURI public)
     function _setTokenURI(uint256 tokenId, string memory uri_) internal {
         require(_exists(tokenId), "Token does not exist");
         _tokenURIs[tokenId] = uri_;
         // Optionally update the URI stored in the Certificate struct as well for consistency
         _certificates[tokenId].uri = uri_; // Keep URI consistent in both mappings
         emit TokenURIUpdated(tokenId, uri_);
     }

     function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
         // Only the issuer of the certificate or the contract owner can change the URI
         require(_exists(tokenId), "Token does not exist");
         Certificate storage cert = _certificates[tokenId];
         require(msg.sender == cert.issuer || msg.sender == _owner, "Only the issuer or owner can set URI");
         _setTokenURI(tokenId, _tokenURI);
     }

    /*
     * Standard ERC721 functions that might be expected but are omitted
     * or trivially implemented due to SoulBound nature:
     * - `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll` (Overridden/Revert)
     * - `transferFrom`, `safeTransferFrom` (Overridden/Revert)
     * - `tokenByIndex`, `tokenOfOwnerByIndex` (Requires ERC721Enumerable extension, omitted for simplicity and gas concerns)
     * - `tokenFallback` (Related to safeTransfer, not applicable here)
     */

}
```