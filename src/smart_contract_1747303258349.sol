Okay, let's design an interesting, advanced, and trendy smart contract. A concept that fits these criteria is a **Metaverse Identity and Reputation System**. This goes beyond a simple NFT by embedding dynamic attributes, relationships, credentials, and reputation directly onto a non-transferable (Soulbound Token - SBT-like) identity.

Here's the plan:

1.  **Outline:** Structure the contract logically (Imports, State Variables, Enums, Events, Modifiers, Constructor, ERC721 Overrides, Core Identity Functions, Attribute Management, Relationships, Delegation, Admin).
2.  **Function Summary:** Briefly describe the purpose of each function.
3.  **Solidity Code:** Implement the contract following the outline, ensuring it meets the requirements (20+ functions, advanced concepts, not a direct copy of standard templates).

---

**Smart Contract Concept:** **MetaverseIdentityToken**

This contract implements a Soulbound Token (SBT)-like system for unique, non-transferable digital identities within a potential metaverse or decentralized community. Each token represents a unique identity profile that can accumulate dynamic attributes like reputation scores, verified credentials, relationships with other identities, delegated permissions, and time-bound roles. It's designed to be a building block for on-chain identity, reputation, and social graphs.

**Outline:**

1.  SPDX-License-Identifier and Pragma
2.  Import OpenZeppelin Contracts (ERC721, Ownable, ReentrancyGuard - maybe not needed, Pausable, Counters).
3.  State Variables (Mappings for identity data, counters).
4.  Enums (Identity Status).
5.  Events (Minting, Attribute Changes, Relationships, Delegation, Status).
6.  Modifiers (Custom access control like `onlyIdentityOwner`).
7.  Constructor (Initialize contract).
8.  ERC721 Overrides for Soulbound Behavior (Prevent transfers, approvals).
9.  Core Identity Management (Minting, getting owner/address/token ID).
10. Dynamic Attribute Management (Name, Avatar, Reputation, Credentials, Time-Bound Roles, Status).
11. Relationship Management (Adding/removing/checking connections to other identities).
12. Delegation (Setting/checking who can act on behalf of an identity).
13. Querying Functions (Get various identity details).
14. Admin Functions (Pause, Withdrawals, Base URI).

**Function Summary:**

*   **`constructor(string memory name, string memory symbol)`:** Initializes the ERC721 contract with a name and symbol, and sets the deployer as the owner.
*   **`supportsInterface(bytes4 interfaceId)`:** ERC165 standard function to declare supported interfaces (ERC721, ERC165).
*   **`_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`:** Internal override to prevent *any* transfer of tokens, enforcing the Soulbound nature.
*   **`mintIdentity(address recipient)`:** Creates a new unique identity token for the specified address. Only callable by the contract owner.
*   **`burnIdentity(uint256 tokenId)`:** Allows the owner to burn an identity token. (Careful with SBTs, burning implies identity destruction).
*   **`pause()`:** Pauses core identity operations (minting, attribute changes). Only callable by the owner.
*   **`unpause()`:** Unpauses the contract. Only callable by the owner.
*   **`setBaseURI(string memory baseURI_)`:** Sets the base URI for token metadata. Only callable by the owner.
*   **`tokenURI(uint256 tokenId)`:** Returns the metadata URI for a given token ID. Overrides standard ERC721.
*   **`setIdentityName(uint256 tokenId, string memory name)`:** Sets the display name for an identity. Only callable by the identity owner or its delegate.
*   **`getIdentityName(uint256 tokenId)`:** Gets the display name of an identity.
*   **`setIdentityAvatarURI(uint256 tokenId, string memory avatarURI)`:** Sets the avatar URI for an identity. Only callable by the identity owner or its delegate.
*   **`getIdentityAvatarURI(uint256 tokenId)`:** Gets the avatar URI of an identity.
*   **`setReputationScore(uint256 tokenId, int256 score)`:** Sets the reputation score for an identity. Only callable by the owner or an authorized entity (not implemented as complex role, just owner for simplicity here). Can be positive or negative.
*   **`incrementReputationScore(uint256 tokenId, uint256 amount)`:** Increases the reputation score. Owner/authorized only.
*   **`decrementReputationScore(uint256 tokenId, uint256 amount)`:** Decreases the reputation score. Owner/authorized only.
*   **`getReputationScore(uint256 tokenId)`:** Gets the current reputation score.
*   **`grantCredential(uint256 tokenId, bytes32 credentialHash, uint256 expiryTimestamp)`:** Grants a hashed credential/achievement to an identity with an optional expiry. Owner/authorized only.
*   **`revokeCredential(uint256 tokenId, bytes32 credentialHash)`:** Revokes a specific credential. Owner/authorized only.
*   **`hasCredential(uint256 tokenId, bytes32 credentialHash)`:** Checks if an identity currently holds a non-expired credential.
*   **`getCredentials(uint256 tokenId)`:** * (Note: Returning arrays of dynamic types is complex/gas-heavy on-chain. This might be simplified in implementation, e.g., returning a count or requiring off-chain indexing. For summary purposes, stating "get" is acceptable, actual implementation might differ).* Gets a list of credentials held by the identity.
*   **`addConnection(uint256 identityIdA, uint256 identityIdB)`:** Records a bi-directional connection between two identities. Owner/authorized only.
*   **`removeConnection(uint256 identityIdA, uint256 identityIdB)`:** Removes a connection between two identities. Owner/authorized only.
*   **`isConnected(uint256 identityIdA, uint256 identityIdB)`:** Checks if two identities are connected.
*   **`setDelegate(uint256 tokenId, address delegatee)`:** Allows an identity owner to set an address that can act on their behalf for certain identity-specific functions (like setting name/avatar).
*   **`removeDelegate(uint256 tokenId)`:** Removes the delegate for an identity.
*   **`getDelegate(uint256 tokenId)`:** Gets the current delegate address for an identity.
*   **`isDelegate(uint256 tokenId, address potentialDelegate)`:** Checks if an address is the delegate for a specific identity.
*   **`grantTemporaryRole(uint256 tokenId, bytes32 roleHash, uint256 expiryTimestamp)`:** Grants a time-bound role to an identity. Owner/authorized only.
*   **`revokeTemporaryRole(uint256 tokenId, bytes32 roleHash)`:** Revokes a temporary role before expiry. Owner/authorized only.
*   **`hasRole(uint256 tokenId, bytes32 roleHash)`:** Checks if an identity currently holds a non-expired role.
*   **`setIdentityStatus(uint256 tokenId, IdentityStatus status)`:** Sets the status of an identity (e.g., Verified, Suspended). Owner/authorized only.
*   **`getIdentityStatus(uint256 tokenId)`:** Gets the current status of an identity.
*   **`isIdentityVerified(uint256 tokenId)`:** Convenience function to check if status is 'Verified'.
*   **`getTokenIdByAddress(address identityAddress)`:** Gets the token ID associated with a given address.
*   **`getAddressByTokenId(uint256 tokenId)`:** Gets the address associated with a given token ID. (Standard ERC721 `ownerOf` handles this).
*   **`getTotalIdentities()`:** Gets the total number of identities minted.
*   **`withdrawEther()`:** Allows the contract owner to withdraw any accidental Ether sent to the contract.
*   **`withdrawERC20(address tokenAddress)`:** Allows the contract owner to withdraw any accidental ERC20 tokens sent to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Needed for basic enumeration if we want _allTokenIds
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Note: ERC721Enumerable is included primarily for OpenZeppelin's internal token tracking
// capabilities (`_beforeTokenTransfer` often relies on it or similar structures).
// While we prevent standard enumeration interfaces for privacy/complexity, the internal
// tracking helps manage total supply and token existence.

/// @title MetaverseIdentityToken
/// @dev A Soulbound Token (SBT)-like contract for unique, non-transferable digital identities
///      with dynamic attributes, relationships, and reputation.
contract MetaverseIdentityToken is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Mapping from token ID to the address that owns/controls it
    // (This is implicitly handled by ERC721's _owners mapping, but we map address->id for lookups)
    mapping(address => uint256) private _addressToTokenId;

    // Dynamic Identity Attributes
    mapping(uint256 => string) private _identityNames;
    mapping(uint256 => string) private _identityAvatarURIs;
    mapping(uint256 => int256) private _reputationScores;

    // Credentials (hashed identifier => expiry timestamp)
    mapping(uint256 => mapping(bytes32 => uint256)) private _identityCredentials;

    // Time-Bound Roles (hashed identifier => expiry timestamp)
    mapping(uint256 => mapping(bytes32 => uint256)) private _identityRoles;

    // Relationships (Symmetric connection: idA => idB => true)
    mapping(uint256 => mapping(uint256 => bool)) private _connections;
    mapping(uint256 => uint256) private _connectionCounts; // Simple count

    // Delegation (tokenId => delegate address)
    mapping(uint256 => address) private _delegates;

    // Identity Status
    enum IdentityStatus { None, Active, Verified, Suspended }
    mapping(uint256 => IdentityStatus) private _identityStatus;

    // --- Enums ---
    // (Already defined above)

    // --- Events ---
    event IdentityMinted(uint256 indexed tokenId, address indexed owner);
    event IdentityBurned(uint256 indexed tokenId);
    event IdentityNameUpdated(uint256 indexed tokenId, string newName);
    event IdentityAvatarURIUpdated(uint256 indexed tokenId, string newAvatarURI);
    event ReputationScoreUpdated(uint256 indexed tokenId, int256 newScore);
    event CredentialGranted(uint256 indexed tokenId, bytes32 indexed credentialHash, uint256 expiryTimestamp);
    event CredentialRevoked(uint256 indexed tokenId, bytes32 indexed credentialHash);
    event ConnectionAdded(uint256 indexed identityIdA, uint256 indexed identityIdB);
    event ConnectionRemoved(uint256 indexed identityIdA, uint256 indexed identityIdB);
    event DelegateSet(uint256 indexed tokenId, address indexed delegatee);
    event DelegateRemoved(uint256 indexed tokenId);
    event TemporaryRoleGranted(uint256 indexed tokenId, bytes32 indexed roleHash, uint256 expiryTimestamp);
    event TemporaryRoleRevoked(uint256 indexed tokenId, bytes32 indexed roleHash);
    event IdentityStatusUpdated(uint256 indexed tokenId, IdentityStatus newStatus);

    // --- Modifiers ---

    /// @dev Throws if `_tokenId` does not exist.
    modifier existingIdentity(uint256 _tokenId) {
        require(_exists(_tokenId), "IdentityToken: non-existent identity");
        _;
    }

    /// @dev Throws if the caller is not the owner or the registered delegate of the identity.
    modifier onlyIdentityOwnerOrDelegate(uint256 _tokenId) {
        address identityOwner = ownerOf(_tokenId); // Use ERC721 ownerOf
        address delegatee = _delegates[_tokenId];
        require(
            msg.sender == identityOwner || (delegatee != address(0) && msg.sender == delegatee),
            "IdentityToken: caller is not identity owner or delegate"
        );
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) Pausable() {}

    // --- ERC721 Overrides for Soulbound Behavior ---

    /// @dev See {IERC165-supportsInterface}. Overridden to support ERC721.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        // Standard ERC721 interfaceId: 0x80ac58cd
        // ERC721Metadata interfaceId: 0x5b5e139f
        return super.supportsInterface(interfaceId);
        // Note: We intentionally do NOT support ERC721Enumerable (0x780e9d63)
        // to prevent easy enumeration of all identities for potential privacy reasons.
    }

    /// @dev The following functions prevent transfers and approvals to make the tokens Soulbound.
    /// Overrides {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        // Allow minting (from address(0)) and burning (to address(0)), but nothing else.
        require(from == address(0) || to == address(0), "IdentityToken: transfers are soulbound");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @dev See {IERC721-safeTransferFrom}. Prevented.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert("IdentityToken: transfers are soulbound");
    }

    /// @dev See {IERC721-safeTransferFrom}. Prevented.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert("IdentityToken: transfers are soulbound");
    }

    /// @dev See {IERC721-transferFrom}. Prevented.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert("IdentityToken: transfers are soulbound");
    }

    /// @dev See {IERC721-approve}. Prevented.
    function approve(address to, uint256 tokenId) public override {
        revert("IdentityToken: approvals are soulbound");
    }

    /// @dev See {IERC721-setApprovalForAll}. Prevented.
    function setApprovalForAll(address operator, bool approved) public override {
        revert("IdentityToken: approvals are soulbound");
    }

    /// @dev See {IERC721-getApproved}. Returns address(0) for all tokens.
    function getApproved(uint256 tokenId) public view override returns (address) {
        return address(0); // No approvals allowed
    }

    /// @dev See {IERC721-isApprovedForAll}. Returns false for all operators.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return false; // No approvals allowed
    }

    // --- Core Identity Management ---

    /// @dev Mints a new identity token and assigns it to the recipient.
    /// @param recipient The address to receive the new identity token.
    function mintIdentity(address recipient) public onlyOwner whenNotPaused {
        require(recipient != address(0), "IdentityToken: mint to the zero address");
        require(_addressToTokenId[recipient] == 0, "IdentityToken: recipient already has an identity");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);
        _addressToTokenId[recipient] = newTokenId;
        _identityStatus[newTokenId] = IdentityStatus.Active; // Default status

        emit IdentityMinted(newTokenId, recipient);
    }

     /// @dev Burns an identity token. Only the owner can burn.
     /// @param tokenId The ID of the identity token to burn.
     // Careful consideration needed for burning SBTs - represents identity destruction.
     function burnIdentity(uint256 tokenId) public onlyOwner existingIdentity(tokenId) {
         address identityOwner = ownerOf(tokenId);
         // Clear owner-specific mappings before burning
         delete _addressToTokenId[identityOwner];
         delete _identityNames[tokenId];
         delete _identityAvatarURIs[tokenId];
         delete _reputationScores[tokenId];
         // Credentials, Roles, Connections, Delegates would ideally be cleared too,
         // but clearing nested mappings/large arrays is complex and gas-intensive on-chain.
         // A real implementation might require a separate clean-up process or different data structure.
         // For this example, we'll burn the token and leave potential stale data in mappings
         // (which won't be reachable via a valid tokenId anyway).
         delete _identityStatus[tokenId];
         delete _delegates[tokenId];
         delete _connectionCounts[tokenId]; // Only clear count, not connections mapping itself due to complexity.

         _burn(tokenId); // This removes the owner from the internal ERC721 _owners mapping
         emit IdentityBurned(tokenId);
     }


    // --- Dynamic Attribute Management ---

    /// @dev Sets the display name for an identity.
    /// @param tokenId The ID of the identity.
    /// @param name The new name.
    function setIdentityName(uint256 tokenId, string memory name) public existingIdentity(tokenId) onlyIdentityOwnerOrDelegate(tokenId) whenNotPaused {
        _identityNames[tokenId] = name;
        emit IdentityNameUpdated(tokenId, name);
    }

    /// @dev Gets the display name of an identity.
    /// @param tokenId The ID of the identity.
    /// @return The identity's name.
    function getIdentityName(uint256 tokenId) public view existingIdentity(tokenId) returns (string memory) {
        return _identityNames[tokenId];
    }

    /// @dev Sets the avatar URI for an identity.
    /// @param tokenId The ID of the identity.
    /// @param avatarURI The new avatar URI.
    function setIdentityAvatarURI(uint256 tokenId, string memory avatarURI) public existingIdentity(tokenId) onlyIdentityOwnerOrDelegate(tokenId) whenNotPaused {
        _identityAvatarURIs[tokenId] = avatarURI;
        emit IdentityAvatarURIUpdated(tokenId, avatarURI);
    }

    /// @dev Gets the avatar URI of an identity.
    /// @param tokenId The ID of the identity.
    /// @return The identity's avatar URI.
    function getIdentityAvatarURI(uint256 tokenId) public view existingIdentity(tokenId) returns (string memory) {
        return _identityAvatarURIs[tokenId];
    }

    /// @dev Sets the reputation score for an identity. Callable only by the contract owner.
    ///      In a real system, this might be managed by specific oracles or reputation modules.
    /// @param tokenId The ID of the identity.
    /// @param score The new score. Can be positive or negative.
    function setReputationScore(uint256 tokenId, int256 score) public onlyOwner existingIdentity(tokenId) whenNotPaused {
        _reputationScores[tokenId] = score;
        emit ReputationScoreUpdated(tokenId, score);
    }

     /// @dev Increments the reputation score for an identity by a specific amount. Callable only by the contract owner.
     /// @param tokenId The ID of the identity.
     /// @param amount The amount to increment by.
     function incrementReputationScore(uint256 tokenId, uint256 amount) public onlyOwner existingIdentity(tokenId) whenNotPaused {
         unchecked { // Use unchecked for arithmetic where overflow/underflow is not expected to be a security issue or is handled by design (scores can be negative)
             _reputationScores[tokenId] = _reputationScores[tokenId] + int256(amount);
         }
         emit ReputationScoreUpdated(tokenId, _reputationScores[tokenId]);
     }

      /// @dev Decrements the reputation score for an identity by a specific amount. Callable only by the contract owner.
      /// @param tokenId The ID of the identity.
      /// @param amount The amount to decrement by.
      function decrementReputationScore(uint256 tokenId, uint256 amount) public onlyOwner existingIdentity(tokenId) whenNotPaused {
          unchecked {
              _reputationScores[tokenId] = _reputationScores[tokenId] - int256(amount);
          }
          emit ReputationScoreUpdated(tokenId, _reputationScores[tokenId]);
      }

    /// @dev Gets the current reputation score of an identity.
    /// @param tokenId The ID of the identity.
    /// @return The identity's reputation score.
    function getReputationScore(uint256 tokenId) public view existingIdentity(tokenId) returns (int256) {
        return _reputationScores[tokenId];
    }

    /// @dev Grants a credential to an identity. `credentialHash` is a unique identifier for the credential.
    ///      `expiryTimestamp` is Unix timestamp; 0 means no expiry.
    ///      Callable only by the contract owner. In a real system, might be specific minters.
    /// @param tokenId The ID of the identity.
    /// @param credentialHash Hashed identifier of the credential.
    /// @param expiryTimestamp Unix timestamp when the credential expires (0 for no expiry).
    function grantCredential(uint256 tokenId, bytes32 credentialHash, uint256 expiryTimestamp) public onlyOwner existingIdentity(tokenId) whenNotPaused {
        _identityCredentials[tokenId][credentialHash] = expiryTimestamp;
        emit CredentialGranted(tokenId, credentialHash, expiryTimestamp);
    }

    /// @dev Revokes a credential from an identity.
    ///      Callable only by the contract owner.
    /// @param tokenId The ID of the identity.
    /// @param credentialHash Hashed identifier of the credential.
    function revokeCredential(uint256 tokenId, bytes32 credentialHash) public onlyOwner existingIdentity(tokenId) whenNotPaused {
        delete _identityCredentials[tokenId][credentialHash];
        emit CredentialRevoked(tokenId, credentialHash);
    }

    /// @dev Checks if an identity holds a valid, non-expired credential.
    /// @param tokenId The ID of the identity.
    /// @param credentialHash Hashed identifier of the credential.
    /// @return True if the identity has the credential and it hasn't expired, false otherwise.
    function hasCredential(uint256 tokenId, bytes32 credentialHash) public view existingIdentity(tokenId) returns (bool) {
        uint256 expiry = _identityCredentials[tokenId][credentialHash];
        return expiry > 0 && (expiry == type(uint256).max || expiry > block.timestamp);
    }

    /// @dev Grants a temporary role to an identity. `roleHash` is a unique identifier for the role.
    ///      `expiryTimestamp` is Unix timestamp; must be in the future.
    ///      Callable only by the contract owner.
    /// @param tokenId The ID of the identity.
    /// @param roleHash Hashed identifier of the role.
    /// @param expiryTimestamp Unix timestamp when the role expires. Must be > block.timestamp.
    function grantTemporaryRole(uint256 tokenId, bytes32 roleHash, uint256 expiryTimestamp) public onlyOwner existingIdentity(tokenId) whenNotPaused {
        require(expiryTimestamp > block.timestamp, "IdentityToken: expiry must be in the future");
        _identityRoles[tokenId][roleHash] = expiryTimestamp;
        emit TemporaryRoleGranted(tokenId, roleHash, expiryTimestamp);
    }

    /// @dev Revokes a temporary role from an identity before its expiry.
    ///      Callable only by the contract owner.
    /// @param tokenId The ID of the identity.
    /// @param roleHash Hashed identifier of the role.
    function revokeTemporaryRole(uint256 tokenId, bytes32 roleHash) public onlyOwner existingIdentity(tokenId) whenNotPaused {
        delete _identityRoles[tokenId][roleHash];
        emit TemporaryRoleRevoked(tokenId, roleHash);
    }

    /// @dev Checks if an identity currently holds a non-expired role.
    /// @param tokenId The ID of the identity.
    /// @param roleHash Hashed identifier of the role.
    /// @return True if the identity has the role and it hasn't expired, false otherwise.
    function hasRole(uint256 tokenId, bytes32 roleHash) public view existingIdentity(tokenId) returns (bool) {
        uint256 expiry = _identityRoles[tokenId][roleHash];
        return expiry > block.timestamp; // Role must have a future expiry
    }

    /// @dev Sets the status of an identity.
    ///      Callable only by the contract owner.
    /// @param tokenId The ID of the identity.
    /// @param status The new status (from IdentityStatus enum).
    function setIdentityStatus(uint256 tokenId, IdentityStatus status) public onlyOwner existingIdentity(tokenId) whenNotPaused {
        _identityStatus[tokenId] = status;
        emit IdentityStatusUpdated(tokenId, status);
    }

    /// @dev Gets the current status of an identity.
    /// @param tokenId The ID of the identity.
    /// @return The identity's status.
    function getIdentityStatus(uint256 tokenId) public view existingIdentity(tokenId) returns (IdentityStatus) {
        return _identityStatus[tokenId];
    }

    /// @dev Convenience function to check if an identity's status is 'Verified'.
    /// @param tokenId The ID of the identity.
    /// @return True if the status is Verified, false otherwise.
    function isIdentityVerified(uint256 tokenId) public view existingIdentity(tokenId) returns (bool) {
        return _identityStatus[tokenId] == IdentityStatus.Verified;
    }


    // --- Relationship Management ---

    /// @dev Records a bi-directional connection between two identities. Order doesn't matter (A to B implies B to A).
    ///      Callable only by the contract owner. Could be extended to require mutual consent.
    /// @param identityIdA The ID of the first identity.
    /// @param identityIdB The ID of the second identity.
    function addConnection(uint256 identityIdA, uint256 identityIdB) public onlyOwner existingIdentity(identityIdA) existingIdentity(identityIdB) whenNotPaused {
        require(identityIdA != identityIdB, "IdentityToken: cannot connect identity to itself");

        // Ensure consistent ordering for storage
        uint256 id1 = identityIdA < identityIdB ? identityIdA : identityIdB;
        uint256 id2 = identityIdA < identityIdB ? identityIdB : identityIdA;

        if (!_connections[id1][id2]) {
            _connections[id1][id2] = true;
            _connectionCounts[identityIdA]++; // Increment count for both IDs
            _connectionCounts[identityIdB]++;
            emit ConnectionAdded(identityIdA, identityIdB);
        }
    }

    /// @dev Removes a bi-directional connection between two identities.
    ///      Callable only by the contract owner.
    /// @param identityIdA The ID of the first identity.
    /// @param identityIdB The ID of the second identity.
    function removeConnection(uint256 identityIdA, uint256 identityIdB) public onlyOwner existingIdentity(identityIdA) existingIdentity(identityIdB) whenNotPaused {
         require(identityIdA != identityIdB, "IdentityToken: cannot remove connection to self");

         uint256 id1 = identityIdA < identityIdB ? identityIdA : identityIdB;
         uint256 id2 = identityIdA < identityIdB ? identityIdB : identityIdA;

         if (_connections[id1][id2]) {
             delete _connections[id1][id2];
             _connectionCounts[identityIdA]--; // Decrement count for both IDs
             _connectionCounts[identityIdB]--;
             emit ConnectionRemoved(identityIdA, identityIdB);
         }
    }

    /// @dev Checks if two identities are connected. Order of IDs doesn't matter.
    /// @param identityIdA The ID of the first identity.
    /// @param identityIdB The ID of the second identity.
    /// @return True if the identities are connected, false otherwise.
    function isConnected(uint256 identityIdA, uint256 identityIdB) public view existingIdentity(identityIdA) existingIdentity(identityIdB) returns (bool) {
        if (identityIdA == identityIdB) {
            return false; // Cannot be connected to self in this system
        }
        uint256 id1 = identityIdA < identityIdB ? identityIdA : identityIdB;
        uint256 id2 = identityIdA < identityIdB ? identityIdB : identityIdA;
        return _connections[id1][id2];
    }

    /// @dev Gets the number of connections an identity has.
    /// @param tokenId The ID of the identity.
    /// @return The number of connections.
    function getConnectionCount(uint256 tokenId) public view existingIdentity(tokenId) returns (uint256) {
         return _connectionCounts[tokenId];
    }

    // --- Delegation ---

    /// @dev Sets an address that can act on behalf of the identity owner for certain functions.
    ///      Callable only by the actual owner of the identity.
    /// @param tokenId The ID of the identity.
    /// @param delegatee The address to set as the delegate. Use address(0) to remove.
    function setDelegate(uint256 tokenId, address delegatee) public existingIdentity(tokenId) whenNotPaused {
         require(msg.sender == ownerOf(tokenId), "IdentityToken: caller is not identity owner");
         _delegates[tokenId] = delegatee;
         if (delegatee == address(0)) {
             emit DelegateRemoved(tokenId);
         } else {
             emit DelegateSet(tokenId, delegatee);
         }
    }

    /// @dev Removes the delegate for an identity.
    ///      Callable only by the actual owner of the identity.
    /// @param tokenId The ID of the identity.
    function removeDelegate(uint256 tokenId) public existingIdentity(tokenId) whenNotPaused {
        setDelegate(tokenId, address(0));
    }

    /// @dev Gets the current delegate address for an identity.
    /// @param tokenId The ID of the identity.
    /// @return The delegate address.
    function getDelegate(uint256 tokenId) public view existingIdentity(tokenId) returns (address) {
         return _delegates[tokenId];
    }

    /// @dev Checks if an address is the currently set delegate for an identity.
    /// @param tokenId The ID of the identity.
    /// @param potentialDelegate The address to check.
    /// @return True if the address is the delegate, false otherwise.
    function isDelegate(uint256 tokenId, address potentialDelegate) public view existingIdentity(tokenId) returns (bool) {
         return _delegates[tokenId] == potentialDelegate && potentialDelegate != address(0);
    }


    // --- Querying Functions ---

    /// @dev Gets the identity token ID associated with a given address.
    /// @param identityAddress The address to query.
    /// @return The token ID, or 0 if no identity is associated.
    function getTokenIdByAddress(address identityAddress) public view returns (uint256) {
        return _addressToTokenId[identityAddress];
    }

    /// @dev Gets the total number of identities minted.
    /// @return The total supply of tokens (identities).
    function getTotalIdentities() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Note: ownerOf(tokenId) from ERC721 provides `getAddressByTokenId`.
    // balanceOf(address) from ERC721 provides the number of identities an address owns (should be 0 or 1).


    // --- Admin Functions ---

    /// @dev Pauses certain contract operations (minting, attribute changes, etc.).
    ///      Uses OpenZeppelin's Pausable.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract.
    ///      Uses OpenZeppelin's Pausable.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Allows the owner to withdraw any Ether accidentally sent to the contract.
    function withdrawEther() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /// @dev Allows the owner to withdraw any accidental ERC20 tokens sent to the contract.
    /// @param tokenAddress The address of the ERC20 token.
    function withdrawERC20(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(this), "IdentityToken: cannot withdraw contract itself");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    // Internal helper to check identity existence (used by modifiers, but public for external check if needed)
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId); // ERC721 internal check
    }

    // The contract receives Ether
    receive() external payable {}

    // The contract receives Ether via fallback (less specific than receive)
    fallback() external payable {}
}

// Helper interface for withdrawing ERC20 tokens
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```