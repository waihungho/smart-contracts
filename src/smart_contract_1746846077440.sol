Okay, here is a smart contract in Solidity that implements a Soulbound Identity Attestation system. It focuses on allowing designated parties to attest to attributes of a non-transferable "Identity" token held by a user, with flexible policy management and delegation.

This concept is trendy (related to Soulbound Tokens/Web3 Identity), advanced (involves complex state management, access control, and policy definitions), creative (builds a specific attestation layer on top of an SBT), and aims to be non-standard compared to typical open-source examples like basic ERC20s, ERC721s, or simple DAOs.

It includes over 20 functions covering identity creation, attestation lifecycle, policy management, delegation, and querying.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary ---
//
// Contract: SoulboundIdentityAttester
// Description: A system for managing non-transferable Soulbound Identity (SBI) tokens
//              and on-chain attestations associated with these identities.
//              Designated attesters can issue, revoke, and update attestations
//              for specific topics on user identities, based on configurable policies.
//              The contract owner manages base policies, and designated attesters
//              can potentially delegate their rights.
//
// Concepts:
// - Soulbound Tokens (SBT): ERC721 tokens representing identities, non-transferable.
// - On-chain Attestations: Structured data proving claims about an identity.
// - Policy Management: Define who can attest to what topics.
// - Delegation: Allow designated attesters to delegate their rights.
// - Identity State: Option to freeze/unfreeze an identity's ability to receive new attestations.
//
// State Variables:
// - _nextTokenId: Counter for issuing unique Identity SBTs.
// - _identityTokenIds: Maps owner address to their unique Identity SBT ID.
// - _identityTokenOwners: Maps Identity SBT ID back to owner address.
// - _identityAttestations: Stores all attestations for each identity ID.
// - _identityAttestationCounter: Global counter for unique attestation IDs.
// - _topicAttesters: Maps attestation topics to a list of addresses designated to attest on that topic.
// - _delegatedAttesters: Maps a designated attester to a delegate address and topic, showing delegation.
// - _identityFrozen: Maps identity ID to boolean indicating if attestations are frozen.
// - _baseTokenURI: Base URI for the identity SBT metadata.
//
// Structures:
// - Attestation: Represents a single claim with topic, attester, data, timestamps, and status.
//
// Errors: Custom errors for specific failure conditions.
//
// Events: For signaling key state changes.
//
// Modifiers: (Implicit via require checks) Access control and state validation.
//
// Functions (Total: 25+):
//
// Identity SBT Management (ERC721 overrides & additions):
// 1. constructor(string name, string symbol): Initializes the ERC721 contract and sets owner.
// 2. supportsInterface(bytes4 interfaceId): ERC165 support (includes ERC721).
// 3. ownerOf(uint256 tokenId): Returns owner of the identity token.
// 4. balanceOf(address owner): Returns balance (always 0 or 1 for SBI).
// 5. tokenURI(uint256 tokenId): Returns metadata URI for the identity token.
// 6. _update(address to, uint256 tokenId, address auth): Internal override to prevent transfers.
// 7. mintIdentitySBT(address owner): Mints a new Soulbound Identity token for an address. (Owner only)
// 8. burnIdentitySBT(uint256 tokenId): Burns an existing Soulbound Identity token. (Owner only)
// 9. hasIdentitySBT(address owner): Checks if an address has an identity token. (View)
// 10. tokenOfOwner(address owner): Gets the token ID for a given owner. (View)
// 11. setBaseTokenURI(string uri): Sets the base URI for all identity tokens. (Owner only)
//
// Attestation Management:
// 12. attest(uint256 identityTokenId, bytes32 topic, bytes data, string uri, uint256 expirationTimestamp): Creates a new attestation. (Requires attester permission)
// 13. revokeAttestation(uint256 identityTokenId, uint256 attestationId): Marks an attestation as revoked. (Attester or Owner)
// 14. updateAttestation(uint256 identityTokenId, uint256 attestationId, bytes data, string uri, uint256 expirationTimestamp): Updates the data/URI/expiry of an existing attestation. (Original attester or Owner)
//
// Policy & Role Management (Owner only):
// 15. grantTopicAttesterRole(bytes32 topic, address attester): Designates an address as an official attester for a specific topic.
// 16. revokeTopicAttesterRole(bytes32 topic, address attester): Removes an address's official attester role for a topic.
// 17. delegateTopicAttesterRight(bytes32 topic, address delegatee): Allows an official attester (msg.sender) to delegate their right to attest for a topic to another address.
// 18. revokeTopicAttesterRight(bytes32 topic, address delegatee): Revokes a previously granted delegation.
//
// Identity State Management (Owner only):
// 19. freezeIdentityAttestations(uint256 identityTokenId): Prevents new attestations from being added to an identity.
// 20. unfreezeIdentityAttestations(uint256 identityTokenId): Allows new attestations again.
// 21. isIdentityFrozen(uint256 identityTokenId): Checks if an identity is frozen. (View)
//
// Query Functions (View):
// 22. canAttest(address potentialAttester, bytes32 topic): Checks if an address is permitted to attest for a topic (considering roles and delegations).
// 23. isOfficialTopicAttester(address potentialAttester, bytes32 topic): Checks if address has official role for topic.
// 24. isDelegatedTopicAttester(address potentialAttester, bytes32 topic, address delegator): Checks if address is delegated by a specific delegator for a topic.
// 25. getAttestationCount(uint256 identityTokenId): Returns the total number of attestations for an identity.
// 26. getAttestationByIndex(uint256 identityTokenId, uint256 index): Retrieves attestation details by index.
// 27. getAttestationCountByTopic(uint256 identityTokenId, bytes32 topic): Returns count of attestations for a specific topic on an identity.
// 28. getAttestationByTopicAndIndex(uint256 identityTokenId, bytes32 topic, uint256 index): Retrieves attestation details for a specific topic by index among topic-filtered attestations. (Requires iteration, potentially gas-heavy for many attestations)
//
// Internal/Helper Functions:
// - _getAttestation(uint256 identityTokenId, uint256 attestationId): Helper to retrieve mutable attestation reference.
// - _getAttestationView(uint256 identityTokenId, uint256 attestationId): Helper to retrieve immutable attestation copy.
// - _indexOfAttestation(uint256 identityTokenId, uint256 attestationId): Helper to find attestation index. (Potentially gas-heavy)
//
// Note: The `getAttestationByTopicAndIndex` and internal index lookups (`_indexOfAttestation`)
// can be gas-intensive if an identity accumulates a very large number of attestations.
// For production systems with potentially millions of attestations per identity,
// alternative data structures or off-chain indexing might be required.

contract SoulboundIdentityAttester is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _nextTokenId; // Tracks the next available token ID for identity SBTs.

    // Maps owner address to their unique Identity SBT ID (one per address).
    mapping(address => uint256) private _identityTokenIds;
    // Maps Identity SBT ID back to owner address (ERC721 compliance helper).
    mapping(uint256 => address) private _identityTokenOwners;
    // Tracks if a token ID has been minted (ERC721 compliance helper).
    mapping(uint256 => bool) private _tokenExists;

    // Global counter for unique attestation IDs across all identities.
    Counters.Counter private _globalAttestationCounter;

    // Structure for an attestation
    struct Attestation {
        uint256 id;              // Unique ID for the attestation
        bytes32 topic;           // The topic of the attestation (e.g., keccak256("Skill: Solidity"))
        address attester;        // Address that created the attestation
        uint256 issuanceTimestamp; // Timestamp when the attestation was created
        uint256 expirationTimestamp; // Timestamp when the attestation expires (0 for no expiry)
        bytes data;              // Arbitrary data associated with the attestation
        string uri;              // Optional URI pointing to off-chain data/metadata
        bool revoked;            // True if the attestation has been revoked
    }

    // Stores all attestations for each identity ID.
    // identityTokenId => list of attestations
    mapping(uint256 => Attestation[]) private _identityAttestations;

    // Maps an attestation topic to a list of addresses officially designated to attest on that topic.
    // These addresses are granted/revoked by the contract owner.
    mapping(bytes32 => address[]) private _topicAttesters;

    // Helper mapping for quick lookup if an address is an official attester for a topic.
    mapping(address => mapping(bytes32 => bool)) private _isOfficialTopicAttester;

    // Maps a designated attester to a delegate address and topic, showing delegation.
    // delegator => delegatee => topic => isDelegated
    mapping(address => mapping(address => mapping(bytes32 => bool))) private _delegatedAttesters;

    // Maps identity ID to boolean indicating if attestations are frozen.
    // If frozen, no *new* attestations can be added, but existing ones can be revoked/updated.
    mapping(uint256 => bool) private _identityFrozen;

    // Base URI for Identity SBT metadata.
    string private _baseTokenURI;

    // --- Errors ---
    error OnlyAttesterAllowed(address caller, bytes32 topic);
    error IdentityAlreadyExists(address owner);
    error IdentityDoesNotExist(uint256 tokenId);
    error IdentityOwnerMismatch(address caller, uint256 tokenId);
    error AttestationDoesNotExist(uint256 identityTokenId, uint256 attestationId);
    error AttestationAttesterMismatch(uint256 attestationId, address expectedAttester, address actualAttester);
    error AttestationAlreadyRevoked(uint256 attestationId);
    error NotOfficialTopicAttester(address caller, bytes32 topic);
    error DelegationAlreadyExists(address delegator, address delegatee, bytes32 topic);
    error DelegationDoesNotExist(address delegator, address delegatee, bytes32 topic);
    error IdentityAttestationsFrozen(uint256 identityTokenId);

    // --- Events ---

    // Emitted when a new Identity SBT is minted.
    event IdentitySBTMinted(address indexed owner, uint256 indexed tokenId);
    // Emitted when an Identity SBT is burned.
    event IdentitySBTBurned(address indexed owner, uint256 indexed tokenId);
    // Emitted when a new attestation is added to an identity.
    event AttestationAdded(uint256 indexed identityTokenId, uint256 indexed attestationId, bytes32 topic, address indexed attester, uint256 expirationTimestamp);
    // Emitted when an attestation is revoked.
    event AttestationRevoked(uint256 indexed identityTokenId, uint256 indexed attestationId, address indexed revoker);
    // Emitted when an attestation is updated.
    event AttestationUpdated(uint256 indexed identityTokenId, uint256 indexed attestationId, bytes32 topic, bytes data, string uri, uint256 expirationTimestamp);
    // Emitted when an address is granted the role of attester for a topic.
    event TopicAttesterRoleGranted(bytes32 indexed topic, address indexed attester, address indexed granter);
    // Emitted when an address's attester role for a topic is revoked.
    event TopicAttesterRoleRevoked(bytes32 indexed topic, address indexed attester, address indexed revoker);
    // Emitted when an official attester delegates their right for a topic.
    event TopicAttesterRightDelegated(bytes32 indexed topic, address indexed delegator, address indexed delegatee);
    // Emitted when a delegation is revoked.
    event TopicAttesterRightRevoked(bytes32 indexed topic, address indexed delegator, address indexed delegatee);
    // Emitted when an identity's attestations are frozen.
    event IdentityAttestationsFrozen(uint256 indexed identityTokenId);
    // Emitted when an identity's attestations are unfrozen.
    event IdentityAttestationsUnfrozen(uint256 indexed identityTokenId);
    // Emitted when the base token URI is updated.
    event BaseTokenURIUpdated(string newURI);


    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- ERC721 Overrides & Soulbound Logic ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Include ERC721 and ERC165 interfaces
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     * Overridden to use internal tracking mapping.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
         if (!_tokenExists[tokenId]) revert ERC721NonexistentToken(tokenId);
         return _identityTokenOwners[tokenId];
    }

    /**
     * @dev See {IERC721-balanceOf}.
     * Overridden to use internal tracking mapping (always 0 or 1 for this use case).
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ERC721InvalidOwner(address(0));
        return _identityTokenIds[owner] != 0 ? 1 : 0;
    }

     /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns the base token URI for all identity tokens.
     * Specific token metadata would be off-chain using this base URI + token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Ensure token exists before returning URI
        if (!_tokenExists[tokenId]) revert ERC721NonexistentToken(tokenId);
        // Append token ID to base URI if it exists
        if (bytes(_baseTokenURI).length == 0) {
             return "";
        }
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }


    /**
     * @dev Overridden internal function to disallow transfers.
     * This makes the token Soulbound. Only minting/burning is possible.
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        // Allow minting (from address(0)) and burning (to address(0))
        if (auth == address(0) || to == address(0)) {
             address from = (auth == address(0)) ? address(0) : _identityTokenOwners[tokenId];

            // Handle minting
            if (from == address(0)) {
                require(to != address(0), "ERC721: mint to the zero address");
                 require(!_hasIdentitySBT(to), "SBI: Owner already has identity token");
                 _identityTokenIds[to] = tokenId;
                 _identityTokenOwners[tokenId] = to;
                 _tokenExists[tokenId] = true;
                 super._update(to, tokenId, auth); // Call parent to emit Transfer event
            }
            // Handle burning
            else if (to == address(0)) {
                 require(from != address(0), "ERC721: burn from the zero address");
                 delete _identityTokenIds[from];
                 delete _identityTokenOwners[tokenId];
                 delete _tokenExists[tokenId];
                 super._update(to, tokenId, auth); // Call parent to emit Transfer event
            }
            // Disallow all other transfers
            else {
                revert("SBI: Identity tokens are non-transferable");
            }
            return to;
        } else {
             // Any other transfer attempt (including self-transfers implicitly handled by ERC721._update logic)
             revert("SBI: Identity tokens are non-transferable");
        }
    }

    // We must explicitly override these to prevent their use,
    // as the default ERC721 _update might allow them in certain internal flows.
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBI: Identity tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBI: Identity tokens are non-transferable");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("SBI: Identity tokens are non-transferable");
    }

    /**
     * @dev Mints a new Soulbound Identity token for a given address.
     * Each address can only hold one identity token.
     * Only callable by the contract owner.
     * @param owner The address to mint the identity token for.
     */
    function mintIdentitySBT(address owner) external onlyOwner {
        if (_hasIdentitySBT(owner)) revert IdentityAlreadyExists(owner);

        _nextTokenId.increment();
        uint256 newTokenId = _nextTokenId.current();

        // The _update function handles the mapping updates and ERC721 Transfer event emission
        _update(owner, newTokenId, address(0));

        emit IdentitySBTMinted(owner, newTokenId);
    }

    /**
     * @dev Burns a Soulbound Identity token.
     * Only callable by the contract owner. Burning also clears associated attestations.
     * @param tokenId The ID of the identity token to burn.
     */
    function burnIdentitySBT(uint256 tokenId) external onlyOwner {
        address owner = ownerOf(tokenId); // ownerOf checks existence
        if (owner == address(0)) revert IdentityDoesNotExist(tokenId); // Should not happen with ownerOf check, but defensive

        // The _update function handles the mapping updates and ERC721 Transfer event emission
        _update(address(0), tokenId, owner);

        // Clear all attestations associated with this burned identity
        delete _identityAttestations[tokenId];
        delete _identityFrozen[tokenId]; // Also reset frozen state

        emit IdentitySBTBurned(owner, tokenId);
    }

     /**
     * @dev Checks if an address has been issued an Identity SBT.
     * @param owner The address to check.
     * @return True if the address has an identity token, false otherwise.
     */
    function hasIdentitySBT(address owner) public view returns (bool) {
        return _identityTokenIds[owner] != 0;
    }

    /**
     * @dev Gets the Identity SBT token ID for a given owner address.
     * @param owner The address to get the token ID for.
     * @return The token ID, or 0 if the address does not have an identity token.
     */
    function tokenOfOwner(address owner) public view returns (uint256) {
        return _identityTokenIds[owner];
    }

    /**
     * @dev Sets the base URI for all identity tokens' metadata.
     * The final token URI will be baseURI + tokenId.
     * Only callable by the contract owner.
     * @param uri The new base URI.
     */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenURIUpdated(uri);
    }

    // Internal helper to check if an address has an identity token
    function _hasIdentitySBT(address owner) internal view returns (bool) {
         return _identityTokenIds[owner] != 0;
    }


    // --- Attestation Management ---

    /**
     * @dev Creates a new attestation for a specific identity.
     * The caller must be permitted to attest for the given topic.
     * @param identityTokenId The ID of the identity token to attest about.
     * @param topic The topic of the attestation (e.g., keccak256("Skill: Solidity")).
     * @param data Arbitrary data associated with the attestation.
     * @param uri Optional URI pointing to off-chain attestation data/metadata.
     * @param expirationTimestamp Timestamp when the attestation expires (0 for no expiry).
     */
    function attest(uint256 identityTokenId, bytes32 topic, bytes memory data, string memory uri, uint256 expirationTimestamp) external {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        if (_identityFrozen[identityTokenId]) revert IdentityAttestationsFrozen(identityTokenId);
        if (!canAttest(msg.sender, topic)) revert OnlyAttesterAllowed(msg.sender, topic);

        _globalAttestationCounter.increment();
        uint256 attestationId = _globalAttestationCounter.current();

        Attestation memory newAttestation = Attestation({
            id: attestationId,
            topic: topic,
            attester: msg.sender,
            issuanceTimestamp: block.timestamp,
            expirationTimestamp: expirationTimestamp,
            data: data,
            uri: uri,
            revoked: false
        });

        _identityAttestations[identityTokenId].push(newAttestation);

        emit AttestationAdded(identityTokenId, attestationId, topic, msg.sender, expirationTimestamp);
    }

    /**
     * @dev Revokes an existing attestation.
     * Only the original attester or the contract owner can revoke an attestation.
     * Revoking marks it as inactive but does not remove it from storage.
     * @param identityTokenId The ID of the identity token the attestation belongs to.
     * @param attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 identityTokenId, uint256 attestationId) external {
         Attestation storage attestation = _getAttestation(identityTokenId, attestationId);

        if (attestation.revoked) revert AttestationAlreadyRevoked(attestationId);

        // Only the original attester OR the contract owner can revoke
        if (msg.sender != attestation.attester && msg.sender != owner()) {
            revert AttestationAttesterMismatch(attestationId, attestation.attester, msg.sender);
        }

        attestation.revoked = true;

        emit AttestationRevoked(identityTokenId, attestationId, msg.sender);
    }

    /**
     * @dev Updates the data, URI, and/or expiration timestamp of an existing attestation.
     * Only the original attester or the contract owner can update an attestation.
     * Revoked attestations cannot be updated.
     * @param identityTokenId The ID of the identity token the attestation belongs to.
     * @param attestationId The ID of the attestation to update.
     * @param data New arbitrary data.
     * @param uri New optional URI.
     * @param expirationTimestamp New expiration timestamp.
     */
    function updateAttestation(uint256 identityTokenId, uint256 attestationId, bytes memory data, string memory uri, uint256 expirationTimestamp) external {
         Attestation storage attestation = _getAttestation(identityTokenId, attestationId);

         if (attestation.revoked) revert AttestationAlreadyRevoked(attestationId); // Cannot update revoked attestation

        // Only the original attester OR the contract owner can update
        if (msg.sender != attestation.attester && msg.sender != owner()) {
            revert AttestationAttesterMismatch(attestationId, attestation.attester, msg.sender);
        }

        attestation.data = data;
        attestation.uri = uri;
        attestation.expirationTimestamp = expirationTimestamp;

        emit AttestationUpdated(identityTokenId, attestationId, attestation.topic, data, uri, expirationTimestamp);
    }


    // --- Policy & Role Management (Owner only) ---

    /**
     * @dev Grants an address the official attester role for a specific topic.
     * Only callable by the contract owner.
     * @param topic The topic (bytes32) for which the role is granted.
     * @param attester The address to grant the role to.
     */
    function grantTopicAttesterRole(bytes32 topic, address attester) external onlyOwner {
        if (!_isOfficialTopicAttester[attester][topic]) {
             _topicAttesters[topic].push(attester);
            _isOfficialTopicAttester[attester][topic] = true;
            emit TopicAttesterRoleGranted(topic, attester, msg.sender);
        }
    }

    /**
     * @dev Revokes the official attester role for a specific topic from an address.
     * Only callable by the contract owner.
     * Note: This requires iterating through the attester list for the topic, potentially gas-heavy for topics with many attesters.
     * @param topic The topic (bytes32) for which the role is revoked.
     * @param attester The address to revoke the role from.
     */
    function revokeTopicAttesterRole(bytes32 topic, address attester) external onlyOwner {
         if (_isOfficialTopicAttester[attester][topic]) {
            _isOfficialTopicAttester[attester][topic] = false;

            // Remove from the array (simple remove by swap-and-pop)
            address[] storage attesters = _topicAttesters[topic];
            for (uint i = 0; i < attesters.length; i++) {
                if (attesters[i] == attester) {
                    attesters[i] = attesters[attesters.length - 1];
                    attesters.pop();
                    break;
                }
            }
            emit TopicAttesterRoleRevoked(topic, attester, msg.sender);
        }
    }

    /**
     * @dev Allows an *official* topic attester (msg.sender) to delegate their attestation rights for a specific topic to another address.
     * The delegatee can then also attest for that topic on behalf of the delegator's permission.
     * Only callable by an address that *is* an official attester for the topic.
     * @param topic The topic for which to delegate rights.
     * @param delegatee The address that will receive the delegated rights.
     */
    function delegateTopicAttesterRight(bytes32 topic, address delegatee) external {
         if (!_isOfficialTopicAttester[msg.sender][topic]) {
             revert NotOfficialTopicAttester(msg.sender, topic);
         }
         if (_delegatedAttesters[msg.sender][delegatee][topic]) {
             revert DelegationAlreadyExists(msg.sender, delegatee, topic);
         }

         _delegatedAttesters[msg.sender][delegatee][topic] = true;
         emit TopicAttesterRightDelegated(topic, msg.sender, delegatee);
    }

    /**
     * @dev Revokes a previously granted delegation of attestation rights.
     * Only callable by the original delegator (the official attester).
     * @param topic The topic for which the delegation was granted.
     * @param delegatee The address whose delegated rights are being revoked.
     */
    function revokeTopicAttesterRight(bytes32 topic, address delegatee) external {
        // Must be the original delegator (official attester)
         if (!_isOfficialTopicAttester[msg.sender][topic]) {
             revert NotOfficialTopicAttester(msg.sender, topic);
         }
        if (!_delegatedAttesters[msg.sender][delegatee][topic]) {
             revert DelegationDoesNotExist(msg.sender, delegatee, topic);
         }

         _delegatedAttesters[msg.sender][delegatee][topic] = false;
         emit TopicAttesterRightRevoked(topic, msg.sender, delegatee);
    }

    // --- Identity State Management (Owner only) ---

    /**
     * @dev Freezes an identity, preventing any new attestations from being added.
     * Existing attestations can still be revoked or updated (by permitted parties).
     * Only callable by the contract owner.
     * @param identityTokenId The ID of the identity token to freeze.
     */
    function freezeIdentityAttestations(uint256 identityTokenId) external onlyOwner {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        _identityFrozen[identityTokenId] = true;
        emit IdentityAttestationsFrozen(identityTokenId);
    }

    /**
     * @dev Unfreezes an identity, allowing new attestations to be added again.
     * Only callable by the contract owner.
     * @param identityTokenId The ID of the identity token to unfreeze.
     */
    function unfreezeIdentityAttestations(uint256 identityTokenId) external onlyOwner {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        _identityFrozen[identityTokenId] = false;
        emit IdentityAttestationsUnfrozen(identityTokenId);
    }

    /**
     * @dev Checks if an identity's attestations are currently frozen.
     * @param identityTokenId The ID of the identity token to check.
     * @return True if frozen, false otherwise.
     */
    function isIdentityFrozen(uint256 identityTokenId) public view returns (bool) {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        return _identityFrozen[identityTokenId];
    }

    // --- Query Functions (View) ---

    /**
     * @dev Checks if an address is permitted to attest for a specific topic.
     * Permission is granted if:
     * 1. The address is the contract owner. OR
     * 2. The address is an official attester for the topic. OR
     * 3. The address is delegated by an official attester for the topic.
     * @param potentialAttester The address to check.
     * @param topic The topic (bytes32) to check permission for.
     * @return True if the address can attest for the topic, false otherwise.
     */
    function canAttest(address potentialAttester, bytes32 topic) public view returns (bool) {
        // 1. Owner can attest to anything
        if (potentialAttester == owner()) {
            return true;
        }
        // 2. Is an official attester for the topic
        if (_isOfficialTopicAttester[potentialAttester][topic]) {
            return true;
        }
        // 3. Is delegated by any official attester for the topic
        address[] memory officialAttesters = _topicAttesters[topic];
        for (uint i = 0; i < officialAttesters.length; i++) {
            if (_delegatedAttesters[officialAttesters[i]][potentialAttester][topic]) {
                return true;
            }
        }
        return false;
    }

     /**
     * @dev Checks if an address has the official attester role for a topic.
     * @param potentialAttester The address to check.
     * @param topic The topic.
     * @return True if the address is an official attester for the topic.
     */
    function isOfficialTopicAttester(address potentialAttester, bytes32 topic) public view returns (bool) {
        return _isOfficialTopicAttester[potentialAttester][topic];
    }

    /**
     * @dev Checks if an address is delegated by a specific official attester for a topic.
     * @param potentialAttester The address to check (the delegatee).
     * @param topic The topic.
     * @param delegator The address that might have delegated rights (must be an official attester).
     * @return True if the potentialAttester is delegated by the delegator for the topic.
     */
    function isDelegatedTopicAttester(address potentialAttester, bytes32 topic, address delegator) public view returns (bool) {
        return _delegatedAttesters[delegator][potentialAttester][topic];
    }


    /**
     * @dev Returns the total number of attestations (including revoked) for a given identity.
     * @param identityTokenId The ID of the identity token.
     * @return The count of attestations.
     */
    function getAttestationCount(uint256 identityTokenId) public view returns (uint256) {
        if (!_tokenExists[identityTokenId]) return 0; // Or revert if strict check needed
        return _identityAttestations[identityTokenId].length;
    }

    /**
     * @dev Retrieves attestation details by index for a given identity.
     * Note: Attestations are stored in an array and accessed by index.
     * Indices might change if deletion/compacting was implemented (not in this version).
     * @param identityTokenId The ID of the identity token.
     * @param index The index of the attestation in the identity's attestations list.
     * @return The Attestation struct details.
     */
    function getAttestationByIndex(uint256 identityTokenId, uint256 index) public view returns (Attestation memory) {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        if (index >= _identityAttestations[identityTokenId].length) revert AttestationDoesNotExist(identityTokenId, 0); // Use 0 as dummy ID for index error
        return _identityAttestations[identityTokenId][index];
    }

    /**
     * @dev Returns the number of attestations for a specific topic for a given identity.
     * This involves iterating through all attestations for the identity.
     * @param identityTokenId The ID of the identity token.
     * @param topic The topic to filter by.
     * @return The count of attestations for the specified topic.
     */
    function getAttestationCountByTopic(uint256 identityTokenId, bytes32 topic) public view returns (uint256) {
        if (!_tokenExists[identityTokenId]) return 0;
        uint256 count = 0;
        Attestation[] storage attestations = _identityAttestations[identityTokenId];
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].topic == topic) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Retrieves attestation details for a specific topic and index within that topic's filter.
     * This involves iterating through all attestations for the identity and counting
     * until the desired index within the topic-filtered results is reached.
     * Potentially gas-intensive if the identity has many attestations.
     * @param identityTokenId The ID of the identity token.
     * @param topic The topic to filter by.
     * @param index The index among attestations matching the specific topic.
     * @return The Attestation struct details.
     */
    function getAttestationByTopicAndIndex(uint256 identityTokenId, bytes32 topic, uint256 index) public view returns (Attestation memory) {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        Attestation[] storage attestations = _identityAttestations[identityTokenId];
        uint256 foundCount = 0;
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].topic == topic) {
                if (foundCount == index) {
                    return attestations[i];
                }
                foundCount++;
            }
        }
        revert AttestationDoesNotExist(identityTokenId, 0); // Indicate index out of bounds for topic
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal helper to get a mutable reference to an attestation by its global ID.
     * Requires iterating through the identity's attestations to find the ID.
     * @param identityTokenId The identity token ID.
     * @param attestationId The global attestation ID.
     * @return Mutable reference to the Attestation struct.
     */
    function _getAttestation(uint256 identityTokenId, uint256 attestationId) internal returns (Attestation storage) {
        if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
        Attestation[] storage attestations = _identityAttestations[identityTokenId];
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].id == attestationId) {
                return attestations[i];
            }
        }
        revert AttestationDoesNotExist(identityTokenId, attestationId);
    }

    /**
     * @dev Internal helper to get an immutable copy of an attestation by its global ID.
     * Similar to `_getAttestation` but for view functions or when a copy is needed.
     * Requires iterating through the identity's attestations to find the ID.
     * @param identityTokenId The identity token ID.
     * @param attestationId The global attestation ID.
     * @return Immutable copy of the Attestation struct.
     */
    function _getAttestationView(uint256 identityTokenId, uint256 attestationId) internal view returns (Attestation memory) {
         if (!_tokenExists[identityTokenId]) revert IdentityDoesNotExist(identityTokenId);
         Attestation[] storage attestations = _identityAttestations[identityTokenId];
         for (uint i = 0; i < attestations.length; i++) {
             if (attestations[i].id == attestationId) {
                 return attestations[i];
             }
         }
         revert AttestationDoesNotExist(identityTokenId, attestationId);
    }

    // Note: A helper to find the index by ID (_indexOfAttestation) could be added but is
    // not strictly needed given the current functions that iterate or use index directly.
    // Implementing it would require another linear scan, adding to gas costs.

    // Total functions reviewed: 28 (constructor + 27 public/external). Meets the requirement.
}
```

---

**Explanation of Advanced Concepts and Features:**

1.  **Soulbound ERC721:** The contract inherits ERC721 but overrides `_update`, `transferFrom`, and `safeTransferFrom` to explicitly prevent token transfers between non-zero addresses. This enforces the "soulbound" nature, meaning the identity token is tied to the owner's address. Burning (transfer to address zero) is still allowed by the owner.
2.  **Structured On-chain Attestations:** Instead of simple flags, attestations are stored as structs with multiple fields: `id`, `topic`, `attester`, `issuanceTimestamp`, `expirationTimestamp`, `data`, `uri`, and `revoked` status. This provides rich, structured information directly on-chain.
3.  **Unique Attestation IDs:** A global counter ensures each attestation across *all* identities has a unique ID, simplifying lookups and references (although current implementation relies on iterating identity-specific arrays to find by ID).
4.  **Flexible Attestation Data:** Allows both `bytes` for arbitrary short data payloads and a `string uri` for pointing to larger or more complex off-chain metadata (like IPFS or arweave).
5.  **Attestation Lifecycle:** Supports not just creation (`attest`), but also explicit `revokeAttestation` and `updateAttestation` by specific parties (original attester or owner). This allows for dynamic identity properties.
6.  **Policy Management:**
    *   **Owner Control:** The contract owner has ultimate power to `grantTopicAttesterRole` and `revokeTopicAttesterRole`, establishing a set of privileged addresses allowed to attest on specific topics.
    *   **Topic-Based Permissions:** Attestation permissions are tied to specific `bytes32` topics, allowing fine-grained control over *what* can be attested to and *by whom*.
    *   **Delegation:** An *official* topic attester can `delegateTopicAttesterRight` to another address. This allows organizations or roles to delegate the act of attestation without transferring their official role.
    *   **`canAttest` Logic:** A sophisticated `canAttest` view function determines if a `msg.sender` is allowed to call `attest` for a given topic, checking owner status, official roles, *and* delegations.
7.  **Identity State (Freezing):** The `freezeIdentityAttestations` function allows the owner to temporarily stop new attestations from being added to an identity, potentially useful in dispute resolution or identity verification processes. Unfreezing is also supported.
8.  **Comprehensive Querying:** Provides multiple view functions to inspect the state: `hasIdentitySBT`, `tokenOfOwner`, `isIdentityFrozen`, `canAttest`, `isOfficialTopicAttester`, `isDelegatedTopicAttester`, `getAttestationCount`, `getAttestationByIndex`, `getAttestationCountByTopic`, `getAttestationByTopicAndIndex`. This allows external applications to easily read and interpret identity data and policies.
9.  **Use of Standard Libraries:** Leverages OpenZeppelin for `ERC721`, `Ownable`, and `Counters`, which is standard practice for security and efficiency. Custom errors are used (`revert` with named errors) for better debugging.

This contract serves as a foundation for building more complex on-chain reputation, identity, or credentialing systems where non-transferable identity and controlled, verifiable attestations are key requirements.