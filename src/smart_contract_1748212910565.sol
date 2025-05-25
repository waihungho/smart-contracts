Okay, here is a Solidity smart contract for a "Multi-Chain Metaverse Passport". This concept combines ERC721 NFTs with features for decentralized identity, dynamic attributes, linked assets across chains (conceptually), verifiable attestations, delegation, role-based access, and even a placeholder for ZK proof verification integration.

It aims for originality by blending these features into a single identity token, offering dynamic data and inter-metaverse representation concepts.

---

**Outline & Function Summary:**

```solidity
/**
 * @title MultiChainMetaversePassport
 * @dev An ERC721 contract representing a decentralized identity passport for the metaverse.
 *      Each token ID is a unique passport. It stores dynamic attributes, links to
 *      assets/addresses on potentially other chains, handles verifiable attestations,
 *      manages reputation, allows delegation, and includes advanced features like
 *      ZK proof verification integration for private attributes.
 *
 * Outline:
 * 1. State Variables & Constants: Define roles, mappings for passports, attributes, attestations, roles, delegation, etc.
 * 2. Structs & Events: Define data structures for attributes, attestations, and events for state changes.
 * 3. Roles & Access Control: Implement a simple role-based access control system (Admin, Issuer, Delegate, etc.).
 * 4. Core ERC721 Functionality: Implement or override necessary functions (mint, transfer, tokenURI, etc.).
 * 5. Passport Data Management: Functions to set/get/remove dynamic attributes, link/unlink local assets (on this chain), and link/unlink external addresses (representing identities/assets on other chains/systems).
 * 6. Attestation System: Functions for authorized issuers to add verifiable attestations (claims) to a passport.
 * 7. Reputation System: Basic functions to manage a reputation score for a passport based on external logic (e.g., tied to attestations).
 * 8. Delegation: Allow passport owners to delegate specific permissions to other addresses.
 * 9. Advanced Features:
 *    - Dynamic tokenURI based on passport attributes.
 *    - Integration concept for verifying ZK proofs to add private attributes.
 * 10. Utility Functions: Helper views to retrieve passport data.
 *
 * Function Summary (20+ distinct concepts/entry points):
 *
 * Core (Inherited/Standard):
 * - constructor(string name, string symbol, address verifierContractAddress): Deploys the contract, sets name/symbol, assigns initial owner role.
 * - supportsInterface(bytes4 interfaceId): Standard ERC165 interface detection.
 * - tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a passport token.
 * - mint(address to): Mints a new passport token to an address (Admin only).
 * - transferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer.
 * - approve(address to, uint256 tokenId): Standard ERC721 approval.
 * - setApprovalForAll(address operator, bool approved): Standard ERC721 global approval.
 * - getApproved(uint256 tokenId): Standard ERC721 approved address getter.
 * - isApprovedForAll(address owner, address operator): Standard ERC721 global approval getter.
 * - balanceOf(address owner): Standard ERC721 balance getter.
 * - ownerOf(uint256 tokenId): Standard ERC721 owner getter.
 *
 * Roles & Access Control:
 * - setRole(address account, bytes32 role, bool enabled): Assign or revoke a role for an address (Owner only).
 * - hasRole(address account, bytes32 role): Check if an address has a specific role (View).
 * - getRoleAdmin(bytes32 role): Get the admin role for a given role (View).
 *
 * Passport Data Management:
 * - setAttribute(uint256 tokenId, string key, string value): Set or update a dynamic string attribute for a passport (Owner, Delegate, or specific roles based on attribute key).
 * - setAttributeBytes(uint256 tokenId, string key, bytes value): Set or update a dynamic bytes attribute (for more complex data types).
 * - getAttribute(uint256 tokenId, string key): Get a string attribute value (View).
 * - getAttributeBytes(uint256 tokenId, string key): Get a bytes attribute value (View).
 * - removeAttribute(uint256 tokenId, string key): Remove a specific attribute (Owner, Delegate, or specific roles).
 * - linkLocalAsset(uint256 tokenId, address assetContract, uint256 assetTokenId): Link an ERC721/ERC1155 asset (on this chain) to the passport (Owner, Delegate).
 * - unlinkLocalAsset(uint256 tokenId, address assetContract, uint256 assetTokenId): Unlink a local asset (Owner, Delegate).
 * - getLinkedLocalAssets(uint256 tokenId): Get the list of linked local assets (View).
 * - linkExternalAddress(uint256 tokenId, bytes32 chainIdHash, bytes32 addressHash): Link an identifier representing an address/asset on another chain/system (stores hashes) (Owner, Delegate).
 * - unlinkExternalAddress(uint256 tokenId, bytes32 chainIdHash, bytes32 addressHash): Unlink an external address identifier (Owner, Delegate).
 * - getLinkedExternalAddresses(uint256 tokenId): Get the list of linked external address identifiers (View).
 *
 * Attestation System:
 * - addAttestation(uint256 subjectTokenId, bytes32 dataHash, bytes signature): Add a verifiable attestation to a passport (Issuer role). DataHash represents the hash of the off-chain claim data.
 * - getAttestation(bytes32 attestationHash): Retrieve an attestation by its hash (View).
 * - getAttestationsForSubject(uint256 subjectTokenId): Get a list of attestation hashes for a passport (View).
 * - verifyAttestationSignature(address issuer, uint256 subjectTokenId, bytes32 dataHash, bytes signature): Verify the signature of an attestation (Helper View).
 *
 * Reputation System:
 * - updateReputationScore(uint256 tokenId, uint256 newScore): Update the reputation score for a passport (Admin or designated Reputation Manager role).
 * - getReputationScore(uint256 tokenId): Get the current reputation score (View).
 *
 * Delegation:
 * - addDelegate(uint256 tokenId, address delegate): Add an address as a delegate for the passport (Passport Owner only).
 * - removeDelegate(uint256 tokenId, address delegate): Remove an address as a delegate (Passport Owner only).
 * - isDelegate(uint256 tokenId, address delegate): Check if an address is a delegate for a passport (View).
 *
 * Advanced Features:
 * - verifyZKProofAndAddAttribute(uint256 tokenId, string key, bytes value, uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[2] memory input): Verifies a ZK proof against a pre-configured verifier contract and, if valid, adds/updates an attribute (can be restricted). Note: Requires an external ZK verifier contract.
 *
 * Utility:
 * - getTokenIdsByOwner(address owner): Get all token IDs owned by an address (Requires iteration, can be gas-intensive for many tokens).
 * - getTotalSupply(): Get the total number of minted passports (View).
 */
```

---

**Smart Contract Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For isContract check if needed for linked assets

// Interface for a generic ZK Proof Verifier contract (example)
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) external view returns (bool);
}

contract MultiChainMetaversePassport is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;
    using Address for address;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Passport Data: tokenId -> {attributeKey -> attributeValue}
    // Using string for key/value provides flexibility, but bytes can store richer data.
    // We'll support both string and bytes attributes.
    mapping(uint256 => mapping(string => string)) private _passportStringAttributes;
    mapping(uint256 => mapping(string => bytes)) private _passportBytesAttributes;
    mapping(uint256 => string[]) private _passportStringAttributeKeys; // To iterate keys
    mapping(uint256 => string[]) private _passportBytesAttributeKeys; // To iterate keys

    // Linked Assets (on this chain): tokenId -> list of {assetContract, assetTokenId}
    struct LinkedLocalAsset {
        address contractAddress;
        uint256 tokenId;
    }
    mapping(uint256 => LinkedLocalAsset[]) private _linkedLocalAssets;

    // Linked External Addresses/Identifiers: tokenId -> list of {chainIdHash, addressHash}
    // Use bytes32 to represent hashes of chain identifiers and external addresses/keys.
    mapping(uint256 => mapping(bytes32 => bytes32[])) private _linkedExternalAddresses; // chainIdHash -> list of addressHashes
    mapping(uint256 => bytes32[]) private _linkedExternalChainIdHashes; // To iterate chain hashes

    // Attestations: attestationHash -> Attestation details
    // attestationHash is keccak256(issuer, subjectTokenId, dataHash)
    struct Attestation {
        address issuer;
        uint256 subjectTokenId;
        bytes32 dataHash; // Hash of the off-chain claim data
        bytes signature; // Signature over keccak256(dataHash) by the issuer
        uint256 issuedAt;
    }
    mapping(bytes32 => Attestation) private _attestations;
    mapping(uint256 => bytes32[]) private _passportAttestations; // tokenId -> list of attestation hashes

    // Reputation Score: tokenId -> score
    mapping(uint256 => uint256) private _reputationScore;

    // Delegation: tokenId -> delegateAddress -> isDelegate
    mapping(uint256 => mapping(address => bool)) private _delegates;
    mapping(uint256 => address[]) private _delegateList; // To iterate delegates

    // Role-Based Access Control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    // Add other roles as needed, e.g., ATTRIBUTE_MANAGER_ROLE, ZK_PROOF_VERIFIER_ROLE

    mapping(address => mapping(bytes32 => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmin;

    address public zkVerifierContract; // Address of a ZK proof verifier contract

    string private _baseTokenURI;

    // --- Structs ---
    // Attestation struct defined above within state variables

    // --- Events ---
    event PassportMinted(uint256 indexed tokenId, address indexed owner);
    event AttributeSet(uint256 indexed tokenId, string key, string value, bytes bytesValue); // Emits both, one will be default
    event AttributeRemoved(uint256 indexed tokenId, string key);
    event LocalAssetLinked(uint256 indexed tokenId, address indexed contractAddress, uint256 assetTokenId);
    event LocalAssetUnlinked(uint256 indexed tokenId, address indexed contractAddress, uint256 assetTokenId);
    event ExternalAddressLinked(uint256 indexed tokenId, bytes32 chainIdHash, bytes32 addressHash);
    event ExternalAddressUnlinked(uint256 indexed tokenId, bytes32 chainIdHash, bytes32 addressHash);
    event AttestationAdded(bytes32 indexed attestationHash, uint256 indexed subjectTokenId, address indexed issuer);
    event ReputationScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event DelegateAdded(uint256 indexed tokenId, address indexed delegate);
    event DelegateRemoved(uint256 indexed tokenId, address indexed delegate);
    event RoleSet(address indexed account, bytes32 indexed role, bool enabled);

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        require(_roles[msg.sender][role], "Caller is not authorized");
        _;
    }

    modifier onlyPassportOwnerOrDelegate(uint256 tokenId) {
        address passportOwner = ownerOf(tokenId);
        require(msg.sender == passportOwner || _delegates[tokenId][msg.sender], "Caller is not passport owner or delegate");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address verifierContractAddress)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets the deployer as the initial owner
    {
        _roleAdmin[ADMIN_ROLE] = ADMIN_ROLE; // Admin role is self-administered
        _roleAdmin[ISSUER_ROLE] = ADMIN_ROLE;
        _roleAdmin[REPUTATION_MANAGER_ROLE] = ADMIN_ROLE;
        // Set deployer as ADMIN_ROLE
        _roles[msg.sender][ADMIN_ROLE] = true;
        emit RoleSet(msg.sender, ADMIN_ROLE, true);

        zkVerifierContract = verifierContractAddress;
    }

    // --- Role-Based Access Control ---

    /**
     * @dev Assign or revoke a role for an account. Only the admin of a role can modify it.
     * The contract owner is the initial admin for the ADMIN_ROLE and other base roles.
     */
    function setRole(address account, bytes32 role, bool enabled) public onlyRole(_roleAdmin[role]) {
        _roles[account][role] = enabled;
        emit RoleSet(account, role, enabled);
    }

    /**
     * @dev Check if an account has a specific role.
     */
    function hasRole(address account, bytes32 role) public view returns (bool) {
        return _roles[account][role];
    }

     /**
     * @dev Get the admin role for a given role.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmin[role];
    }

    // --- Core ERC721 Functionality ---

    /**
     * @dev Mints a new passport token. Only callable by ADMIN_ROLE.
     */
    function mint(address to) public onlyRole(ADMIN_ROLE) returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        emit PassportMinted(newTokenId, to);
        return newTokenId;
    }

    /**
     * @dev See {ERC721-tokenURI}. Returns a URI based on the token ID, pointing to
     *      an off-chain service that serves dynamic JSON metadata.
     *      The URI format could be `baseURI/tokenId`.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    /**
     * @dev Sets the base URI for token metadata. Only callable by the contract owner.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Override ERC721 internal functions if needed for custom logic during transfer/approval,
    // but for this example, the default OpenZeppelin implementations are sufficient.
    // _beforeTokenTransfer, _afterTokenTransfer, _approve

    // --- Passport Data Management ---

    /**
     * @dev Set or update a dynamic string attribute for a passport.
     * Callable by the passport owner or a registered delegate.
     * Specific attribute keys could be restricted to certain roles if needed.
     */
    function setAttribute(uint256 tokenId, string memory key, string memory value)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
        // Add key to list if it's new
        if (bytes(_passportStringAttributes[tokenId][key]).length == 0) {
             _passportStringAttributeKeys[tokenId].push(key);
        }
        _passportStringAttributes[tokenId][key] = value;
        emit AttributeSet(tokenId, key, value, bytes("")); // Empty bytes value
    }

    /**
     * @dev Set or update a dynamic bytes attribute for a passport. Useful for complex data.
     * Callable by the passport owner or a registered delegate.
     * Specific attribute keys could be restricted to certain roles if needed.
     */
     function setAttributeBytes(uint256 tokenId, string memory key, bytes memory value)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
        // Add key to list if it's new
         if (_passportBytesAttributes[tokenId][key].length == 0) {
             _passportBytesAttributeKeys[tokenId].push(key);
         }
        _passportBytesAttributes[tokenId][key] = value;
        emit AttributeSet(tokenId, key, "", value); // Empty string value
     }

    /**
     * @dev Get a string attribute value by key.
     */
    function getAttribute(uint256 tokenId, string memory key) public view returns (string memory) {
        return _passportStringAttributes[tokenId][key];
    }

     /**
     * @dev Get a bytes attribute value by key.
     */
    function getAttributeBytes(uint256 tokenId, string memory key) public view returns (bytes memory) {
        return _passportBytesAttributes[tokenId][key];
     }

    /**
     * @dev Get all string attribute keys for a passport.
     */
    function getStringAttributeKeys(uint256 tokenId) public view returns (string[] memory) {
        return _passportStringAttributeKeys[tokenId];
    }

     /**
     * @dev Get all bytes attribute keys for a passport.
     */
    function getBytesAttributeKeys(uint256 tokenId) public view returns (string[] memory) {
        return _passportBytesAttributeKeys[tokenId];
     }


    /**
     * @dev Remove a dynamic attribute from a passport.
     * Callable by the passport owner or a registered delegate.
     * Specific attribute keys could be restricted.
     * Note: Removing from dynamic array (`_passportStringAttributeKeys`/`_passportBytesAttributeKeys`) is gas-intensive.
     * A better approach for production might use linked lists or mark as deleted.
     * For simplicity here, we'll just delete the value and leave the key in the array (less gas, but getter needs to handle potential empty values if iterating keys).
     * A more robust delete would require iterating and shifting the key array. Let's implement a simple version that just deletes the value.
     */
    function removeAttribute(uint256 tokenId, string memory key)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
         // Check and remove from string attributes
        if (bytes(_passportStringAttributes[tokenId][key]).length > 0) {
            delete _passportStringAttributes[tokenId][key];
            emit AttributeRemoved(tokenId, key);
            // Note: Key is NOT removed from _passportStringAttributeKeys for gas reasons.
            // Getters iterating keys must handle potential empty values.
            return; // Exit after removing one type
        }

        // Check and remove from bytes attributes
         if (_passportBytesAttributes[tokenId][key].length > 0) {
            delete _passportBytesAttributes[tokenId][key];
            emit AttributeRemoved(tokenId, key);
            // Note: Key is NOT removed from _passportBytesAttributeKeys for gas reasons.
            return; // Exit after removing one type
         }

         // If neither was found/removed, the key might not exist. No-op.
    }


    /**
     * @dev Link a local asset (on this chain, e.g., another NFT) to the passport.
     * Stores the contract address and token ID of the linked asset.
     * Callable by the passport owner or a registered delegate.
     */
    function linkLocalAsset(uint256 tokenId, address assetContract, uint256 assetTokenId)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
        // Optional: Add checks here if assetContract is a known/supported contract type
        // require(assetContract.isContract(), "Asset address is not a contract");

        _linkedLocalAssets[tokenId].push(LinkedLocalAsset(assetContract, assetTokenId));
        emit LocalAssetLinked(tokenId, assetContract, assetTokenId);
    }

    /**
     * @dev Unlink a local asset from the passport.
     * Callable by the passport owner or a registered delegate.
     * Note: Removing from dynamic array is gas-intensive. This implementation is basic.
     */
    function unlinkLocalAsset(uint256 tokenId, address assetContract, uint256 assetTokenId)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
        LinkedLocalAsset[] storage assets = _linkedLocalAssets[tokenId];
        for (uint i = 0; i < assets.length; i++) {
            if (assets[i].contractAddress == assetContract && assets[i].tokenId == assetTokenId) {
                // Swap the last element with the one to be removed and pop
                assets[i] = assets[assets.length - 1];
                assets.pop();
                emit LocalAssetUnlinked(tokenId, assetContract, assetTokenId);
                return; // Assuming no duplicates for simplicity
            }
        }
        // Optional: revert if asset was not found
        // require(false, "Linked asset not found");
    }

    /**
     * @dev Get the list of local assets linked to a passport.
     */
    function getLinkedLocalAssets(uint256 tokenId) public view returns (LinkedLocalAsset[] memory) {
        return _linkedLocalAssets[tokenId];
    }

    /**
     * @dev Link an identifier representing an address or asset on another chain/system.
     * Stores hashes to avoid storing actual addresses directly on this chain, promoting privacy
     * and flexibility. ChainIdHash could be keccak256("ETH"), keccak256("POLYGON"), etc.
     * addressHash could be keccak256(externalAddress) or a specific asset identifier.
     * Callable by the passport owner or a registered delegate.
     */
    function linkExternalAddress(uint256 tokenId, bytes32 chainIdHash, bytes32 addressHash)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
         // Add chainIdHash to list if it's new
         bool chainHashExists = false;
         for(uint i=0; i < _linkedExternalChainIdHashes[tokenId].length; i++) {
             if (_linkedExternalChainIdHashes[tokenId][i] == chainIdHash) {
                 chainHashExists = true;
                 break;
             }
         }
         if (!chainHashExists) {
             _linkedExternalChainIdHashes[tokenId].push(chainIdHash);
         }

        _linkedExternalAddresses[tokenId][chainIdHash].push(addressHash);
        emit ExternalAddressLinked(tokenId, chainIdHash, addressHash);
    }

    /**
     * @dev Unlink an external address identifier.
     * Callable by the passport owner or a registered delegate.
     * Note: Removing from dynamic array is gas-intensive. This implementation is basic.
     */
    function unlinkExternalAddress(uint256 tokenId, bytes32 chainIdHash, bytes32 addressHash)
        public onlyPassportOwnerOrDelegate(tokenId)
    {
        bytes32[] storage addressHashes = _linkedExternalAddresses[tokenId][chainIdHash];
        for (uint i = 0; i < addressHashes.length; i++) {
            if (addressHashes[i] == addressHash) {
                // Swap the last element with the one to be removed and pop
                addressHashes[i] = addressHashes[addressHashes.length - 1];
                addressHashes.pop();

                // Optional: Remove chainIdHash from _linkedExternalChainIdHashes if this was the last address hash for that chain
                // This is gas-intensive and omitted for simplicity, getters would need to handle empty lists.

                emit ExternalAddressUnlinked(tokenId, chainIdHash, addressHash);
                return; // Assuming no duplicates for simplicity
            }
        }
        // Optional: revert if external address was not found
        // require(false, "Linked external address not found");
    }

    /**
     * @dev Get the list of linked external address identifiers for a specific chain hash.
     */
    function getLinkedExternalAddresses(uint256 tokenId, bytes32 chainIdHash) public view returns (bytes32[] memory) {
        return _linkedExternalAddresses[tokenId][chainIdHash];
    }

     /**
     * @dev Get the list of chain hashes that have linked external addresses for a passport.
     */
    function getLinkedExternalChainIdHashes(uint256 tokenId) public view returns (bytes32[] memory) {
        return _linkedExternalChainIdHashes[tokenId];
    }

    // --- Attestation System ---

    /**
     * @dev Add a verifiable attestation to a passport. Only callable by ISSUER_ROLE.
     * dataHash is keccak256 of the actual claim data (stored off-chain).
     * signature is the issuer's signature over dataHash.
     */
    function addAttestation(uint256 subjectTokenId, bytes32 dataHash, bytes memory signature)
        public onlyRole(ISSUER_ROLE)
    {
        // Construct the message hash that was signed (standard EIP-191/EIP-712 hashing)
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(dataHash);

        // Recover the signer address
        address signer = messageHash.recover(signature);

        // Ensure the signer is indeed an authorized ISSUER_ROLE
        require(hasRole(signer, ISSUER_ROLE), "Signer is not an authorized issuer");

        // Calculate the unique hash for this attestation
        bytes32 attestationHash = keccak256(abi.encodePacked(signer, subjectTokenId, dataHash));

        // Prevent adding the exact same attestation again
        require(_attestations[attestationHash].issuer == address(0), "Attestation already exists");

        _attestations[attestationHash] = Attestation({
            issuer: signer,
            subjectTokenId: subjectTokenId,
            dataHash: dataHash,
            signature: signature,
            issuedAt: block.timestamp
        });

        _passportAttestations[subjectTokenId].push(attestationHash);

        emit AttestationAdded(attestationHash, subjectTokenId, signer);
    }

    /**
     * @dev Retrieve an attestation by its unique hash.
     */
    function getAttestation(bytes32 attestationHash) public view returns (Attestation memory) {
        return _attestations[attestationHash];
    }

    /**
     * @dev Get the list of attestation hashes for a specific passport.
     */
    function getAttestationsForSubject(uint256 subjectTokenId) public view returns (bytes32[] memory) {
        return _passportAttestations[subjectTokenId];
    }

    /**
     * @dev Helper function to verify the signature of an attestation against expected parameters.
     */
    function verifyAttestationSignature(
        address issuer,
        uint256 subjectTokenId,
        bytes32 dataHash,
        bytes memory signature
    ) public view returns (bool) {
         // Note: This only verifies the signature on the dataHash. It doesn't verify
         // that the 'issuer' parameter provided matches the actual signer, or that
         // the attestation exists in the contract's storage. Use `getAttestation` first.

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(dataHash);
        address recoveredSigner = messageHash.recover(signature);

        // For a full check, you'd compare recoveredSigner with the expected issuer
        return recoveredSigner != address(0) && recoveredSigner == issuer;
    }

    // --- Reputation System ---

    /**
     * @dev Update the reputation score for a passport.
     * This function is intended to be called by a trusted entity (Admin or REPUTATION_MANAGER_ROLE)
     * based on off-chain logic or interactions tracked via attestations.
     */
    function updateReputationScore(uint256 tokenId, uint256 newScore)
        public onlyRole(REPUTATION_MANAGER_ROLE) // Or perhaps onlyRole(ADMIN_ROLE)
    {
        _reputationScore[tokenId] = newScore;
        emit ReputationScoreUpdated(tokenId, newScore);
    }

    /**
     * @dev Get the current reputation score for a passport.
     */
    function getReputationScore(uint256 tokenId) public view returns (uint256) {
        return _reputationScore[tokenId];
    }

    // --- Delegation ---

    /**
     * @dev Allows the passport owner to add an address as a delegate.
     * Delegates can perform certain actions on behalf of the owner (e.g., setting attributes).
     */
    function addDelegate(uint256 tokenId, address delegate) public onlyPassportOwnerOrDelegate(tokenId) {
        // Ensure caller is the actual owner, not a delegate adding another delegate
        require(msg.sender == ownerOf(tokenId), "Only the passport owner can add delegates");
        require(delegate != address(0), "Delegate cannot be the zero address");
        require(!_delegates[tokenId][delegate], "Address is already a delegate");

        _delegates[tokenId][delegate] = true;
        _delegateList[tokenId].push(delegate);
        emit DelegateAdded(tokenId, delegate);
    }

    /**
     * @dev Allows the passport owner to remove a delegate.
     */
    function removeDelegate(uint256 tokenId, address delegate) public onlyPassportOwnerOrDelegate(tokenId) {
         // Ensure caller is the actual owner, not a delegate removing a delegate
        require(msg.sender == ownerOf(tokenId), "Only the passport owner can remove delegates");
        require(_delegates[tokenId][delegate], "Address is not a delegate");

        _delegates[tokenId][delegate] = false;
        // Remove from the list (gas-intensive)
        address[] storage delegates = _delegateList[tokenId];
        for (uint i = 0; i < delegates.length; i++) {
            if (delegates[i] == delegate) {
                delegates[i] = delegates[delegates.length - 1];
                delegates.pop();
                break;
            }
        }
        emit DelegateRemoved(tokenId, delegate);
    }

    /**
     * @dev Check if an address is a delegate for a passport.
     */
    function isDelegate(uint256 tokenId, address delegate) public view returns (bool) {
        return _delegates[tokenId][delegate];
    }

     /**
     * @dev Get the list of delegates for a passport.
     */
    function getDelegates(uint256 tokenId) public view returns (address[] memory) {
        return _delegateList[tokenId];
    }


    // --- Advanced Features ---

    /**
     * @dev Verifies a ZK proof using an external verifier contract and, if valid,
     * allows setting a specific bytes attribute.
     * This enables adding attributes based on private data proven off-chain.
     * Requires a pre-deployed IVerifier contract at `zkVerifierContract`.
     * The `input` array typically contains public inputs used in the ZK circuit,
     * which could include a hash of the passport ID, the attribute key, and the value hash,
     * linking the proof to the specific passport and attribute being set.
     * Callable by any address, provided they have the valid proof. Access to *which*
     * attributes can be set via this method might need further restrictions.
     */
    function verifyZKProofAndAddAttribute(
        uint256 tokenId,
        string memory key,
        bytes memory value, // The attribute value revealed on-chain after proof verification
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input // Public inputs for the ZK circuit
    ) public {
        require(zkVerifierContract != address(0), "ZK Verifier contract not set");

        // Ensure the proof inputs link to this passport and potentially the attribute/value
        // Example: input[0] could be hash(tokenId), input[1] could be hash(key), etc.
        // The exact structure depends on the ZK circuit design.
        // require(input[0] == uint256(keccak256(abi.encodePacked(tokenId))), "Proof input mismatch: tokenId");
        // require(input[1] == uint256(keccak256(abi.encodePacked(key))), "Proof input mismatch: key");
        // require(input[2] == uint256(keccak256(value)), "Proof input mismatch: value");
        // (These checks are examples and depend entirely on the specific ZK circuit)

        bool isValid = IVerifier(zkVerifierContract).verifyProof(a, b, c, input);
        require(isValid, "ZK Proof verification failed");

        // If proof is valid, set the attribute
        // This could potentially use a different access control or have specific logic
        // For simplicity, we'll use the bytes attribute setter, potentially restricted by key.
        // A dedicated internal function `_setZKVerifiedAttribute` might be better.
        // For this example, let's allow setting bytes attributes this way.
        setAttributeBytes(tokenId, key, value); // Uses the existing setter logic & checks

        // Optional: Add a specific event for ZK verified attribute set
        // emit ZKVerifiedAttributeSet(tokenId, key, value);
    }

    /**
     * @dev Sets the address for the ZK proof verifier contract. Only callable by the contract owner.
     */
    function setZKVerifierContract(address verifierContractAddress) public onlyOwner {
        zkVerifierContract = verifierContractAddress;
    }


    // --- Utility Functions ---

     /**
     * @dev Get all token IDs owned by an address.
     * Note: This function iterates through potentially all token IDs ever minted.
     * It can be very gas-intensive and might exceed block gas limits for large numbers of tokens.
     * Not suitable for large-scale production unless used off-chain or with pagination.
     * ERC721 standard does not require this function. Included for completeness but caution advised.
     */
    function getTokenIdsByOwner(address owner) public view returns (uint256[] memory) {
        uint256 total = _tokenIdCounter.current();
        uint256[] memory tokenIds = new uint256[](total);
        uint256 count = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (ownerOf(i) == owner) {
                tokenIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of tokens found
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = tokenIds[i];
        }
        return result;
    }

    /**
     * @dev Get the total number of passports minted.
     */
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Get a summary view of a passport's details (owner, reputation).
     * Can be extended to include more key info.
     */
    function getPassportDetails(uint256 tokenId)
        public view
        returns (
            address passportOwner,
            uint256 reputationScore
        )
    {
        // This will revert if the token does not exist, which is desired behavior.
        passportOwner = ownerOf(tokenId);
        reputationScore = _reputationScore[tokenId];
        // Return other core details here if needed
    }
}
```