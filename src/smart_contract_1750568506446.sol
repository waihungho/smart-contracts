Okay, let's design a smart contract that implements a sophisticated SoulBound Token (SBT) system. Instead of just a simple non-transferable NFT, this contract will manage different *types* of SBTs representing achievements, skills, or reputation facets, allowing for decentralized attestation, delegation of attestation rights, and dynamic scoring. We'll call it `SoulBoundTokenNexus`.

It will combine concepts of:
1.  **Soulbound Tokens:** Non-transferable representation of identity/achievements.
2.  **Multi-faceted Identity:** Different types of SBTs represent different aspects (Skill, Reputation, Contribution, etc.).
3.  **Decentralized Attestation:** Users (or designated attestors) can verify each other's SBTs, building a reputation graph.
4.  **Delegation:** Owners of certain SBTs or designated roles can delegate their attestation rights.
5.  **Dynamic State:** SBTs can have levels or scores that change over time based on updates or attestations.
6.  **Reputation Scoring:** A dynamic score can be calculated based on owned SBTs and received attestations.

This is complex enough that it's unlikely to be a direct clone of a single popular open-source contract.

---

**Outline and Function Summary**

**Contract Name:** `SoulBoundTokenNexus`

**Concept:** A sophisticated SoulBound Token (SBT) system managing multi-faceted on-chain identity, achievements, and reputation through non-transferable tokens, decentralized attestation, and dynamic scoring.

**Key Features:**
*   ERC-721 Non-Transferable Tokens (SBTs).
*   Support for multiple distinct SBT Types (e.g., Skill, Reputation, Achievement).
*   Owner/Role-based issuance and management of SBT Types.
*   Decentralized Attestation: Designated entities or holders of specific SBTs can attest to the validity/level of another user's SBTs.
*   Delegation of Attestation Rights.
*   Dynamic SBT Properties: Tokens can have a changeable 'level' or 'score'.
*   Basic Reputation Score Calculation based on owned SBTs and attestations received.
*   Access Control for core operations (issuance, type management, attestor roles).

**Outline:**
1.  **Imports & Interfaces:** ERC721, Ownable.
2.  **Errors:** Custom errors for specific failure conditions.
3.  **Events:** To log significant actions.
4.  **Structs & Enums:**
    *   `SBTType`: Defines properties of a type (name, description, base weight).
    *   `Attestation`: Represents an endorsement of an SBT.
5.  **State Variables:**
    *   Mappings for SBT details (owner, type, level, URI, issuer).
    *   Mappings for SBT Type details.
    *   Mappings for Attestations received by specific SBTs.
    *   Mappings for delegated attestation rights.
    *   Counters for token IDs and SBT type IDs.
    *   Mapping to track addresses authorized to attest for specific types.
6.  **Constructor:** Initializes owner.
7.  **ERC721 Overrides:**
    *   `_beforeTokenTransfer`: Enforces non-transferability.
    *   `supportsInterface`: ERC165 compliance.
    *   `tokenURI`: Standard URI lookup.
8.  **Admin & Setup Functions (Owner/Admin Only):**
    *   `initializeSBTType`: Define a new type of SBT.
    *   `updateSBTTypeWeight`: Adjust the influence of an SBT type on reputation.
    *   `addAttestorRole`: Grant an address permission to issue/attest specific SBT types.
    *   `removeAttestorRole`: Revoke an attestor role.
    *   `setBaseURI`: Set base URI for token metadata.
    *   `withdrawERC20` / `withdrawEther`: Utility to extract accidental transfers.
9.  **SBT Management Functions (Authorized Attestors/Issuer):**
    *   `issueSBT`: Mint a new SBT of a specific type to a user.
    *   `updateSBTLevel`: Change the level/score of an existing SBT.
    *   `updateSBTMetadata`: Update the URI for a specific token.
    *   `revokeSBT`: Burn an SBT (e.g., for invalidation).
10. **Attestation Management Functions:**
    *   `attestSBT`: An authorized party attests to the validity/strength of another user's specific SBT.
    *   `revokeAttestation`: Remove a previous attestation.
    *   `delegateAttestationRights`: Delegate the right to attest for a specific type.
    *   `revokeAttestationRightsDelegation`: Revoke delegation.
11. **Query/View Functions (Public):**
    *   `getSBTDetails`: Retrieve detailed information for a token ID.
    *   `getOwnerSBTs`: List all token IDs owned by an address.
    *   `getSBTsByTypeAndOwner`: List token IDs of a specific type owned by an address.
    *   `hasSBTOfType`: Check if an address holds *any* token of a specific type.
    *   `hasSBTWithMinLevel`: Check if an address holds an SBT of a type with at least a minimum level.
    *   `getSBTTypeDetails`: Retrieve details for an SBT Type ID.
    *   `isAttestorForType`: Check if an address is authorized to attest for a type.
    *   `getAttestationsForSBT`: List attestations received by a specific SBT token.
    *   `getAttestationDetails`: Get details of a specific attestation.
    *   `getReputationScore`: Calculate/retrieve the dynamic reputation score for an address.
    *   `getTotalSBTIssued`: Get the total number of SBTs minted.
    *   `getSBTTypeIdCount`: Get the total number of SBT types defined.
    *   `isDelegatingAttestationRights`: Check if an address has delegated attestation rights for a type.
    *   `getDelegateeForAttestationRights`: Get the address an address has delegated attestation rights to for a type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol"; // Use Storage for mixin

/**
 * @title SoulBoundTokenNexus
 * @dev A sophisticated SoulBound Token (SBT) system managing multi-faceted
 *      on-chain identity, achievements, and reputation.
 *      Tokens are non-transferable and represent different types (Skill, Reputation, etc.).
 *      The system allows decentralized attestation, delegation of attestation rights,
 *      and dynamic scoring based on owned SBTs and received attestations.
 *
 * Outline:
 * 1. Imports & Interfaces
 * 2. Errors
 * 3. Events
 * 4. Structs & Enums
 * 5. State Variables
 * 6. Constructor
 * 7. ERC721 Overrides (_beforeTokenTransfer, supportsInterface, tokenURI)
 * 8. Admin & Setup Functions (Owner/Admin Only)
 * 9. SBT Management Functions (Authorized Attestors/Issuer)
 * 10. Attestation Management Functions
 * 11. Query/View Functions (Public)
 * 12. Utility Functions
 */
contract SoulBoundTokenNexus is ERC721, Ownable, ERC165Storage {
    using Counters for Counters.Counter;
    using Address for address;

    // --- 2. Errors ---
    error TokenTransferNotAllowed();
    error InvalidSBTType(uint256 sbtTypeId);
    error NotAuthorizedToIssueSBT(uint256 sbtTypeId);
    error NotAuthorizedToAttestSBT(uint256 sbtTypeId); // Attesting specific types
    error NotAuthorizedToUpdateSBT(uint256 tokenId);
    error SBTDoesNotExist(uint256 tokenId);
    error AttestationAlreadyExists(uint256 sbtTokenId, address attester);
    error AttestationDoesNotExist(uint256 sbtTokenId, address attester);
    error CannotAttestOwnSBT();
    error CannotDelegateToSelf();
    error NotDelegatingAttestationRights(uint256 sbtTypeId);
    error DelegationExists(uint256 sbtTypeId);
    error DelegationDoesNotExist(uint256 sbtTypeId);
    error AttestorRoleAlreadyExists(uint256 sbtTypeId, address attestor);
    error AttestorRoleDoesNotExist(uint256 sbtTypeId, address attestor);


    // --- 3. Events ---
    event SBTTypeInitialized(uint256 indexed sbtTypeId, string name, uint256 baseWeight);
    event SBTTypeWeightUpdated(uint256 indexed sbtTypeId, uint256 newBaseWeight);
    event AttestorRoleGranted(uint256 indexed sbtTypeId, address indexed attestor);
    event AttestorRoleRevoked(uint256 indexed sbtTypeId, address indexed attestor);

    event SBTIssued(uint256 indexed tokenId, address indexed owner, uint256 indexed sbtTypeId, address issuer, uint256 initialLevel);
    event SBTLevelUpdated(uint256 indexed tokenId, uint256 newLevel, address updater);
    event SBTMetadataUpdated(uint256 indexed tokenId, string newURI, address updater);
    event SBTRevoked(uint256 indexed tokenId, address indexed owner, address revoker);

    event SBTAttested(uint256 indexed sbtTokenId, address indexed attester, uint256 weight);
    event AttestationRevoked(uint256 indexed sbtTokenId, address indexed attester);
    event AttestationRightsDelegated(uint256 indexed sbtTypeId, address indexed delegator, address indexed delegatee);
    event AttestationRightsRevocation(uint256 indexed sbtTypeId, address indexed delegator);

    // --- 4. Structs & Enums ---
    struct SBTType {
        string name;
        string description;
        uint256 baseWeight; // Base value for reputation calculation
    }

    struct Attestation {
        address attester;
        uint64 timestamp; // Use uint64 as block.timestamp is uint256 but 64 bits are plenty
        uint256 weight; // Weight/influence of this attestation
    }

    // --- 5. State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _sbtTypeIdCounter;

    // SBT Type storage
    mapping(uint256 => SBTType) private _sbtTypes;
    mapping(uint256 => bool) private _sbtTypeExists; // To quickly check if a typeId is valid

    // SBT Instance storage (keyed by tokenId)
    mapping(uint256 => uint256) private _tokenSBTTypeId;
    mapping(uint256 => uint256) private _tokenLevel;
    mapping(uint256 => string) private _tokenURI; // Per-token URI allows dynamic metadata
    mapping(uint256 => address) private _tokenIssuer; // Who initially issued the token

    // Attestation storage (SBT Token ID => List of Attestations)
    mapping(uint256 => Attestation[]) private _attestations;
    // For quicker lookup if an attestation exists from a specific address
    mapping(uint256 => mapping(address => bool)) private _attestationExists;

    // Attestor Roles: SBT Type ID => Attestor Address => bool
    mapping(uint256 => mapping(address => bool)) private _typeAttestors;

    // Delegated Attestation Rights: Delegator Address => SBT Type ID => Delegatee Address
    mapping(address => mapping(uint256 => address)) private _attestationRightsDelegations;

    // Base URI for metadata
    string private _baseTokenURI;

    // --- 6. Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Add ERC165 support for ERC721 and this contract's interfaces
        _registerInterface(bytes4(keccak256("IERC721Enumerable"))); // Though not enumerable, registering common interfaces is good practice
        _registerInterface(bytes4(keccak256("IERC721Metadata")));
        // Custom interface ID for this contract's specific functions if needed,
        // but for simplicity, we rely on standard introspection and function selectors.
    }

    // --- 7. ERC721 Overrides ---

    /**
     * @dev See {ERC721-_beforeTokenTransfer}. This hook is used to enforce
     * non-transferability of SoulBound Tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // Allow minting (from == address(0)) and burning (to == address(0))
        // Disallow transfers between users (from != address(0) && to != address(0))
        if (from != address(0) && to != address(0)) {
            revert TokenTransferNotAllowed();
        }
    }

    /**
     * @dev See {ERC165Storage-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165Storage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-tokenURI}. Fetches the specific token URI if set,
     *      otherwise falls back to the base URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned
        string memory specificURI = _tokenURI[tokenId];
        if (bytes(specificURI).length > 0) {
            return specificURI;
        }
        // Fallback to base URI if specific URI not set
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))) : "";
    }

    // --- 8. Admin & Setup Functions ---

    /**
     * @dev Initializes a new type of SoulBound Token.
     *      Only callable by the contract owner.
     * @param name The name of the SBT type (e.g., "Skill: Solidity", "Reputation: Community Guru").
     * @param description A brief description of the SBT type.
     * @param baseWeight The base weight for this type when calculating reputation scores.
     * @return sbtTypeId The unique ID assigned to the new SBT type.
     */
    function initializeSBTType(string calldata name, string calldata description, uint256 baseWeight)
        external
        onlyOwner
        returns (uint256 sbtTypeId)
    {
        _sbtTypeIdCounter.increment();
        sbtTypeId = _sbtTypeIdCounter.current();
        _sbtTypes[sbtTypeId] = SBTType(name, description, baseWeight);
        _sbtTypeExists[sbtTypeId] = true;
        emit SBTTypeInitialized(sbtTypeId, name, baseWeight);
        return sbtTypeId;
    }

    /**
     * @dev Updates the base weight of an existing SBT type.
     *      Only callable by the contract owner.
     * @param sbtTypeId The ID of the SBT type to update.
     * @param newBaseWeight The new base weight for the type.
     */
    function updateSBTTypeWeight(uint256 sbtTypeId, uint256 newBaseWeight) external onlyOwner {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        _sbtTypes[sbtTypeId].baseWeight = newBaseWeight;
        emit SBTTypeWeightUpdated(sbtTypeId, newBaseWeight);
    }

    /**
     * @dev Grants an address the role of an attestor for a specific SBT type.
     *      Attestors can issue and update SBTs of that type, and attest to others' SBTs of that type.
     *      Only callable by the contract owner.
     * @param sbtTypeId The ID of the SBT type.
     * @param attestor The address to grant the role to.
     */
    function addAttestorRole(uint256 sbtTypeId, address attestor) external onlyOwner {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        if (_typeAttestors[sbtTypeId][attestor]) {
            revert AttestorRoleAlreadyExists(sbtTypeId, attestor);
        }
        _typeAttestors[sbtTypeId][attestor] = true;
        emit AttestorRoleGranted(sbtTypeId, attestor);
    }

    /**
     * @dev Revokes the attestor role for an address for a specific SBT type.
     *      Only callable by the contract owner.
     * @param sbtTypeId The ID of the SBT type.
     * @param attestor The address to revoke the role from.
     */
    function removeAttestorRole(uint256 sbtTypeId, address attestor) external onlyOwner {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        if (!_typeAttestors[sbtTypeId][attestor]) {
            revert AttestorRoleDoesNotExist(sbtTypeId, attestor);
        }
        _typeAttestors[sbtTypeId][attestor] = false;
        emit AttestorRoleRevoked(sbtTypeId, attestor);
    }

    /**
     * @dev Sets the base URI for token metadata.
     *      Only callable by the contract owner.
     *      Used as a fallback if a specific token URI is not set.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens accidentally sent to the contract.
     * @param tokenAddress The address of the ERC20 token.
     */
    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /**
     * @dev Allows the owner to withdraw any Ether accidentally sent to the contract.
     */
    function withdrawEther() external payable onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // --- 9. SBT Management Functions ---

    /**
     * @dev Mints a new SoulBound Token of a specific type to an address.
     *      Only callable by the contract owner or an authorized attestor for the SBT type.
     * @param recipient The address to mint the SBT to.
     * @param sbtTypeId The ID of the SBT type to issue.
     * @param initialLevel The initial level or score for this SBT.
     * @param tokenURI The initial metadata URI for this specific token. Optional.
     * @return tokenId The unique ID of the newly minted SBT.
     */
    function issueSBT(address recipient, uint256 sbtTypeId, uint256 initialLevel, string calldata tokenURI)
        external
        returns (uint256 tokenId)
    {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }

        // Check authorization: must be owner OR an attestor for this type
        if (msg.sender != owner() && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToIssueSBT(sbtTypeId);
        }

        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(recipient, tokenId); // SBTs are non-transferable anyway, so safeMint is fine

        _tokenSBTTypeId[tokenId] = sbtTypeId;
        _tokenLevel[tokenId] = initialLevel;
        _tokenURI[tokenId] = tokenURI;
        _tokenIssuer[tokenId] = msg.sender; // Store who issued it

        emit SBTIssued(tokenId, recipient, sbtTypeId, msg.sender, initialLevel);
        return tokenId;
    }

    /**
     * @dev Updates the level/score of an existing SBT.
     *      Only callable by the original issuer, the contract owner, or an authorized attestor
     *      for the SBT type.
     * @param tokenId The ID of the SBT to update.
     * @param newLevel The new level or score for the SBT.
     */
    function updateSBTLevel(uint256 tokenId, uint256 newLevel) external {
        if (!_exists(tokenId)) {
            revert SBTDoesNotExist(tokenId);
        }
        uint256 sbtTypeId = _tokenSBTTypeId[tokenId];

        // Check authorization: owner OR original issuer OR attestor for this type
        if (msg.sender != owner() && msg.sender != _tokenIssuer[tokenId] && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToUpdateSBT(tokenId);
        }

        _tokenLevel[tokenId] = newLevel;
        emit SBTLevelUpdated(tokenId, newLevel, msg.sender);
    }

    /**
     * @dev Updates the specific metadata URI for an existing SBT.
     *      Only callable by the original issuer, the contract owner, or an authorized attestor
     *      for the SBT type.
     * @param tokenId The ID of the SBT to update.
     * @param newURI The new metadata URI for the SBT.
     */
    function updateSBTMetadata(uint256 tokenId, string calldata newURI) external {
         if (!_exists(tokenId)) {
            revert SBTDoesNotExist(tokenId);
        }
        uint256 sbtTypeId = _tokenSBTTypeId[tokenId];

        // Check authorization: owner OR original issuer OR attestor for this type
        if (msg.sender != owner() && msg.sender != _tokenIssuer[tokenId] && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToUpdateSBT(tokenId);
        }

        _tokenURI[tokenId] = newURI;
        emit SBTMetadataUpdated(tokenId, newURI, msg.sender);
    }

    /**
     * @dev Revokes (burns) an existing SoulBound Token.
     *      Only callable by the original issuer, the contract owner, or an authorized attestor
     *      for the SBT type.
     * @param tokenId The ID of the SBT to revoke.
     */
    function revokeSBT(uint256 tokenId) external {
        address currentOwner = ownerOf(tokenId); // _requireOwned handles existence check implicitly
        uint256 sbtTypeId = _tokenSBTTypeId[tokenId];

        // Check authorization: owner OR original issuer OR attestor for this type
         if (msg.sender != owner() && msg.sender != _tokenIssuer[tokenId] && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToUpdateSBT(tokenId); // Reusing error, maybe rename or add a specific one
        }

        // Clear associated attestations before burning
        // Note: This simple implementation clears all attestations.
        // More complex logic might transfer them or record revocation cause.
        delete _attestations[tokenId];
        // Reset existence map for attestations
        delete _attestationExists[tokenId];

        _burn(tokenId);

        // Clear token-specific state after burn
        delete _tokenSBTTypeId[tokenId];
        delete _tokenLevel[tokenId];
        delete _tokenURI[tokenId];
        delete _tokenIssuer[tokenId];


        emit SBTRevoked(tokenId, currentOwner, msg.sender);
    }

    // --- 10. Attestation Management Functions ---

    /**
     * @dev Allows an authorized party to attest to the validity/strength of another user's SBT.
     *      Authorization check:
     *      1. The caller is the contract owner. OR
     *      2. The caller is an authorized attestor for the SBT type. OR
     *      3. The caller holds an SBT of a relevant type (defined by the contract logic, TBD or simple for now).
     *         For simplicity in this example, let's require the caller to be an authorized attestor
     *         for the *type of SBT* they are attesting *about*.
     *      Delegation: The caller might be a delegatee of someone authorized.
     * @param sbtTokenId The ID of the SBT token being attested to.
     * @param weight The weight or influence of this attestation (e.g., skill proficiency rating).
     */
    function attestSBT(uint256 sbtTokenId, uint256 weight) external {
        if (!_exists(sbtTokenId)) {
            revert SBTDoesNotExist(sbtTokenId);
        }

        address ownerOfSBT = ownerOf(sbtTokenId);
        if (msg.sender == ownerOfSBT) {
            revert CannotAttestOwnSBT();
        }

        uint256 sbtTypeId = _tokenSBTTypeId[sbtTokenId];

        // Check authorization (considering delegation):
        // Is caller owner? OR Is caller a direct attestor for the type? OR Is caller a delegatee?
        address effectiveAttestor = msg.sender;
        bool isAuthorized = msg.sender == owner() || _typeAttestors[sbtTypeId][msg.sender];

        if (!isAuthorized) {
             // Check if sender is a delegatee for any address that *is* authorized for this type
            address delegator = getDelegatorForDelegatee(msg.sender, sbtTypeId);
            if (delegator != address(0)) {
                // msg.sender is a delegatee, the delegator is the effective attestor
                effectiveAttestor = delegator;
                isAuthorized = true;
            }
        }

        if (!isAuthorized) {
            revert NotAuthorizedToAttestSBT(sbtTypeId);
        }

        // Check if attestation from this effective attestor already exists for this SBT
        if (_attestationExists[sbtTokenId][effectiveAttestor]) {
             revert AttestationAlreadyExists(sbtTokenId, effectiveAttestor);
        }

        // Add the attestation
        _attestations[sbtTokenId].push(Attestation(effectiveAttestor, uint64(block.timestamp), weight));
        _attestationExists[sbtTokenId][effectiveAttestor] = true;

        emit SBTAttested(sbtTokenId, effectiveAttestor, weight);
    }

     /**
     * @dev Revokes a previous attestation made by the caller (or their delegator) on an SBT.
     *      Only callable by the address that originally made the attestation (or their current delegatee if rights were delegated *before* revoking).
     *      Requires the caller to identify which attestation to revoke (based on attester address).
     * @param sbtTokenId The ID of the SBT token the attestation is on.
     * @param attesterAddress The address that originally made the attestation. This must match the effective attestor address stored in the attestation struct.
     */
    function revokeAttestation(uint256 sbtTokenId, address attesterAddress) external {
        if (!_exists(sbtTokenId)) {
            revert SBTDoesNotExist(sbtTokenId);
        }

        // Check if an attestation from this attesterAddress exists for this SBT
        if (!_attestationExists[sbtTokenId][attesterAddress]) {
             revert AttestationDoesNotExist(sbtTokenId, attesterAddress);
        }

        // Authorization check:
        // 1. Is caller the original attesterAddress? OR
        // 2. Is caller the current delegatee for the original attesterAddress for this SBT's type?
        uint256 sbtTypeId = _tokenSBTTypeId[sbtTokenId];
        bool isAuthorized = (msg.sender == attesterAddress) ||
                            (msg.sender == _attestationRightsDelegations[attesterAddress][sbtTypeId] && msg.sender != address(0));

        if (!isAuthorized && msg.sender != owner()) { // Owner can always revoke
             // Need to check if msg.sender is a delegatee *for the attesterAddress* for this SBT type
             // This is a bit complex. Let's simplify for this example: Only the original attester OR owner can revoke.
             // A more advanced version would require mapping delegatees back to delegators or checking delegation history.
             // Sticking to original attester or owner for simplicity here.
            if (msg.sender != attesterAddress && msg.sender != owner()) {
                 revert NotAuthorizedToAttestSBT(sbtTypeId); // Reusing error
            }
        }

        // Find and remove the attestation
        Attestation[] storage attestations = _attestations[sbtTokenId];
        bool found = false;
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].attester == attesterAddress) {
                // Found it. Swap with last element and pop.
                attestations[i] = attestations[attestations.length - 1];
                attestations.pop();
                found = true;
                break; // Assuming only one attestation per attester per SBT
            }
        }

        if (!found) {
             revert AttestationDoesNotExist(sbtTokenId, attesterAddress); // Should not happen if _attestationExists was true
        }

        _attestationExists[sbtTokenId][attesterAddress] = false;

        emit AttestationRevoked(sbtTokenId, attesterAddress);
    }

    /**
     * @dev Delegates the right to attest for a specific SBT type to another address.
     *      Only callable by the address that holds the attestation right (owner or direct attestor).
     *      An address can only delegate rights for a specific type to ONE delegatee at a time.
     * @param sbtTypeId The ID of the SBT type for which to delegate rights.
     * @param delegatee The address to delegate the rights to. address(0) to clear delegation.
     */
    function delegateAttestationRights(uint256 sbtTypeId, address delegatee) external {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        if (msg.sender == delegatee) {
            revert CannotDelegateToSelf();
        }

        // Check if sender has attestation rights for this type (owner or direct attestor)
        if (msg.sender != owner() && !_typeAttestors[sbtTypeId][msg.sender]) {
             revert NotAuthorizedToAttestSBT(sbtTypeId); // Reusing error
        }

        if (delegatee == address(0)) {
            // Revoking delegation
            if (_attestationRightsDelegations[msg.sender][sbtTypeId] == address(0)) {
                 revert DelegationDoesNotExist(sbtTypeId);
            }
            delete _attestationRightsDelegations[msg.sender][sbtTypeId];
            emit AttestationRightsRevocation(sbtTypeId, msg.sender);
        } else {
            // Setting/Updating delegation
             if (_attestationRightsDelegations[msg.sender][sbtTypeId] != address(0)) {
                // Can only delegate to one address at a time. Revoke existing first.
                revert DelegationExists(sbtTypeId); // Or allow update, but simpler to require explicit revoke first
            }
            _attestationRightsDelegations[msg.sender][sbtTypeId] = delegatee;
            emit AttestationRightsDelegated(sbtTypeId, msg.sender, delegatee);
        }
    }

     /**
     * @dev Revokes an existing delegation of attestation rights for a specific SBT type.
     *      Only callable by the delegator.
     * @param sbtTypeId The ID of the SBT type for which to revoke delegation.
     */
    function revokeAttestationRightsDelegation(uint256 sbtTypeId) external {
         if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
         if (_attestationRightsDelegations[msg.sender][sbtTypeId] == address(0)) {
             revert DelegationDoesNotExist(sbtTypeId);
        }
        delete _attestationRightsDelegations[msg.sender][sbtTypeId];
        emit AttestationRightsRevocation(sbtTypeId, msg.sender);
    }

    // Internal helper to find the delegator for a delegatee/type
    // This is a linear scan, potentially gas-heavy for many potential delegators.
    // A mapping from delegatee back to delegator would be more efficient but adds state complexity.
    // Keeping it simple for this example.
    // Note: This checks *any* address that has delegated to this delegatee for this type.
    // A more precise check might be needed depending on exact authorization rules.
    function getDelegatorForDelegatee(address delegatee, uint256 sbtTypeId) internal view returns (address) {
        if (!_sbtTypeExists[sbtTypeId] || delegatee == address(0)) return address(0);

        // Optimization needed: Cannot iterate over all possible delegators efficiently.
        // A more efficient approach would be to iterate over known attestors for the type
        // or maintain a reverse mapping (delegatee => sbtTypeId => delegator).
        // For this example, let's assume the direct attestors list isn't huge or this check
        // is only done where performance is less critical (like view functions).
        // A production system would need a more scalable way to track delegations.

        // Assuming a list/set of potential delegators exists (e.g., all addresses that *could* be attestors)
        // Or, simplified: check if the owner has delegated, or if any *active* attestor has delegated.
        // This check is not perfectly efficient without a reverse mapping.
        // We'll return address(0) if no direct/owner delegation found.
        // To make this work, we'd need a way to iterate over all potential delegators, which isn't practical in Solidity.
        // Revisit: The delegation check in `attestSBT` needs to be simpler or state needs restructuring.
        // Alternative: Authorization check is just owner || direct_attestor. Delegation is *only* checked by the delegatee themselves
        // calling `attestSBT` and the contract resolving who the *effective* attestor (the delegator) is.
        // Let's modify `attestSBT` to directly check `_attestationRightsDelegations[delegator][sbtTypeId] == msg.sender`.
        // This requires iterating through potential delegators (owner + all typeAttestors). Still inefficient.

        // Let's adjust authorization check logic:
        // To attest, msg.sender must be EITHER
        // 1. The owner
        // 2. A direct attestor for the sbtTypeId (`_typeAttestors[sbtTypeId][msg.sender] == true`)
        // 3. A delegatee: `_attestationRightsDelegations[delegator][sbtTypeId] == msg.sender` for some `delegator` who is authorized (owner or direct attestor).
        // This still requires iterating through potential delegators.

        // Simpler Delegation model for this example: An authorized attestor (owner or type attestor) can delegate their *entire* attestation right for a type to ONE address.
        // When `attestSBT` is called, check if `msg.sender` is the authorized attestor OR their delegatee.
        // If msg.sender is a delegatee, the *effective* attester recorded in the attestation struct is the *delegator*.

        // Re-implementing the authorization check in attestSBT based on this simpler model:
        // Authorization: msg.sender is owner OR msg.sender is a direct attestor OR msg.sender is a delegatee FOR an authorized address for this type.
        // Finding the delegator is needed if msg.sender is a delegatee. This is still hard.

        // LET'S TRY THIS: `_attestationRightsDelegations[delegator][sbtTypeId]` stores `delegatee`.
        // To check if `msg.sender` is a delegatee for `sbtTypeId`: iterate through addresses `a`. If `_attestationRightsDelegations[a][sbtTypeId] == msg.sender` AND `a` is authorized (owner or attestor), then msg.sender is a delegatee and `a` is the delegator.

        // This iteration is prohibitively expensive.
        // Let's use a reverse mapping for delegation lookup: `delegatee => sbtTypeId => delegator`
        mapping(address => mapping(uint256 => address)) private _attestationRightsDelegationsReverse; // New state variable

        // Update `delegateAttestationRights`:
        // When setting delegation from A to B for type T:
        // if exists _attestationRightsDelegations[A][T], delete _attestationRightsDelegationsReverse[_attestationRightsDelegations[A][T]][T]
        // _attestationRightsDelegations[A][T] = B
        // _attestationRightsDelegationsReverse[B][T] = A

        // Update `revokeAttestationRightsDelegation`:
        // Get delegatee B = _attestationRightsDelegations[msg.sender][sbtTypeId]
        // delete _attestationRightsDelegations[msg.sender][sbtTypeId]
        // delete _attestationRightsDelegationsReverse[B][sbtTypeId]

        // Update `attestSBT`:
        // address delegator = _attestationRightsDelegationsReverse[msg.sender][sbtTypeId];
        // isAuthorized = (msg.sender == owner()) || _typeAttestors[sbtTypeId][msg.sender] || (delegator != address(0) && (delegator == owner() || _typeAttestors[sbtTypeId][delegator]));
        // effectiveAttestor = (delegator != address(0)) ? delegator : msg.sender;

        // This seems workable. Need to add the new mapping and update the delegation functions.

        // --- Adding _attestationRightsDelegationsReverse to state variables ---

        // --- Revising delegateAttestationRights ---
         function delegateAttestationRights(uint256 sbtTypeId, address delegatee) external {
            if (!_sbtTypeExists[sbtTypeId]) revert InvalidSBTType(sbtTypeId);
            if (msg.sender == delegatee) revert CannotDelegateToSelf();

            // Check if sender has attestation rights for this type (owner or direct attestor)
            if (msg.sender != owner() && !_typeAttestors[sbtTypeId][msg.sender]) {
                 revert NotAuthorizedToAttestSBT(sbtTypeId); // Reusing error
            }

            address currentDelegatee = _attestationRightsDelegations[msg.sender][sbtTypeId];

            if (delegatee == address(0)) {
                // Revoking delegation
                if (currentDelegatee == address(0)) revert DelegationDoesNotExist(sbtTypeId);
                delete _attestationRightsDelegations[msg.sender][sbtTypeId];
                delete _attestationRightsDelegationsReverse[currentDelegatee][sbtTypeId];
                emit AttestationRightsRevocation(sbtTypeId, msg.sender);
            } else {
                // Setting/Updating delegation
                if (currentDelegatee != address(0)) {
                     revert DelegationExists(sbtTypeId); // Require explicit revoke first
                }
                _attestationRightsDelegations[msg.sender][sbtTypeId] = delegatee;
                _attestationRightsDelegationsReverse[delegatee][sbtTypeId] = msg.sender;
                emit AttestationRightsDelegated(sbtTypeId, msg.sender, delegatee);
            }
        }

        // --- Revising revokeAttestationRightsDelegation ---
        function revokeAttestationRightsDelegation(uint256 sbtTypeId) external {
            if (!_sbtTypeExists[sbtTypeId]) revert InvalidSBTType(sbtTypeId);
            address currentDelegatee = _attestationRightsDelegations[msg.sender][sbtTypeId];
            if (currentDelegatee == address(0)) revert DelegationDoesNotExist(sbtTypeId);

            delete _attestationRightsDelegations[msg.sender][sbtTypeId];
            delete _attestationRightsDelegationsReverse[currentDelegatee][sbtTypeId];
            emit AttestationRightsRevocation(sbtTypeId, msg.sender);
        }

        // --- Revising attestSBT ---
        // Authorization check:
        // msg.sender must be owner OR a direct attestor for sbtTypeId OR a delegatee *for* someone who is authorized for sbtTypeId.

        // Let's refine the `attestSBT` authorization check logic based on the reverse mapping:
        /*
           address potentialDelegator = _attestationRightsDelegationsReverse[msg.sender][sbtTypeId];

           bool isDirectlyAuthorized = (msg.sender == owner()) || _typeAttestors[sbtTypeId][msg.sender];
           bool isDelegatedAuthorized = (potentialDelegator != address(0)) && // msg.sender is a delegatee
                                        ((potentialDelegator == owner()) || _typeAttestors[sbtTypeId][potentialDelegator]); // The delegator is authorized

           if (!isDirectlyAuthorized && !isDelegatedAuthorized) {
               revert NotAuthorizedToAttestSBT(sbtTypeId);
           }

           address effectiveAttestor = isDirectlyAuthorized ? msg.sender : potentialDelegator;
        */

        // This looks good. Now, back to the original plan for function list.
        // We need `getDelegatorForDelegatee` as a view function now.
    } // End of re-planning delegation logic within attestSBT section


    // --- 11. Query/View Functions ---

    /**
     * @dev Gets the details of a specific SBT.
     * @param tokenId The ID of the SBT.
     * @return sbtTypeId The type ID of the SBT.
     * @return owner The owner of the SBT.
     * @return level The current level/score of the SBT.
     * @return uri The metadata URI for the SBT.
     * @return issuer The address that originally issued the SBT.
     */
    function getSBTDetails(uint256 tokenId)
        external
        view
        returns (uint256 sbtTypeId, address owner, uint256 level, string memory uri, address issuer)
    {
        _requireOwned(tokenId); // Implicitly checks if it exists
        sbtTypeId = _tokenSBTTypeId[tokenId];
        owner = ERC721.ownerOf(tokenId); // Use ERC721.ownerOf to get the owner
        level = _tokenLevel[tokenId];
        uri = tokenURI(tokenId); // Use the tokenURI function to get the correct URI
        issuer = _tokenIssuer[tokenId];
    }

    /**
     * @dev Lists all SBT token IDs owned by a specific address.
     *      Note: This requires iterating through all minted tokens. Can be gas-heavy off-chain.
     *      A production system might track this using an array/set per user or off-chain indexing.
     *      For this example, we rely on the ERC721 standard's tokenOfOwnerByIndex which is usually implemented
     *      by iterating internally or using an enumerable extension. OpenZeppelin's ERC721 *does not*
     *      natively store tokens per owner in an easily iterable way without Enumerable extension.
     *      Let's implement a basic version assuming ERC721 internal state allows this lookup or note the limitation.
     *      (OpenZeppelin's basic ERC721 requires overriding `_owners` mapping access or using Enumerable extension)
     *      Let's add `ERC721Enumerable` inheritance for this function to work efficiently.
     *
     * Note: ERC721Enumerable adds complexity and gas costs on mint/burn. For 20+ functions demo, it's acceptable.
     *
     * @param owner The address to query.
     * @return tokenIds An array of token IDs owned by the address.
     */
     // Revisit: Adding ERC721Enumerable adds function count and complexity.
     // Let's keep it simpler and note the limitation. A view function iterating *all* tokens is too gas-heavy.
     // A practical way without Enumerable is to require off-chain indexing or return count only.
     // Let's return count and state that listing requires off-chain help or Enumerable.

    /**
     * @dev Gets the number of SBTs owned by an address.
     * @param owner The address to query.
     * @return count The number of SBTs owned by the address.
     */
    function getOwnerSBTCount(address owner) external view returns (uint256) {
        return balanceOf(owner); // ERC721 standard function
    }

    // Function to list tokens by owner is omitted due to ERC721 base limitation without Enumerable extension.

    /**
     * @dev Checks if an address holds at least one SBT of a specific type.
     *      Note: This requires iterating through owned tokens. Same limitation as listing.
     *      A practical way without Enumerable is to maintain a mapping `owner => sbtTypeId => count > 0`.
     *      Let's assume for demo purposes an internal check or rely on ERC721Enumerable.
     *      Or, return count for this specific type.
     *
     * Let's add a mapping `_ownerSBTTypeCount[owner][sbtTypeId]` to track this efficiently.
     * Need to increment/decrement in `issueSBT` and `revokeSBT`.
     */
     mapping(address => mapping(uint256 => uint256)) private _ownerSBTTypeCount; // New state variable

     // Update `issueSBT`: `_ownerSBTTypeCount[recipient][sbtTypeId]++;`
     // Update `revokeSBT`: `_ownerSBTTypeCount[currentOwner][sbtTypeId]--;`

    /**
     * @dev Checks if an address holds at least one SBT of a specific type.
     * @param owner The address to query.
     * @param sbtTypeId The ID of the SBT type.
     * @return bool True if the address holds at least one token of the type, false otherwise.
     */
    function hasSBTOfType(address owner, uint256 sbtTypeId) external view returns (bool) {
         if (!_sbtTypeExists[sbtTypeId]) return false; // Handle invalid type
        return _ownerSBTTypeCount[owner][sbtTypeId] > 0;
    }

    /**
     * @dev Checks if an address holds at least one SBT of a specific type with a minimum level.
     *      Note: Requires iterating through owned tokens *of that type* or indexing by owner+type+level.
     *      Requires tracking token IDs per owner and type efficiently.
     *      This is getting complex without a full-fledged index.
     *      Let's simplify: return the HIGHEST level the user has for that type. Caller checks if >= minLevel.
     *      Requires tracking max level per owner per type: `_ownerSBTTypeMaxLevel[owner][sbtTypeId]`.
     *      Update in `issueSBT` and `updateSBTLevel`.
     */
     mapping(address => mapping(uint256 => uint256)) private _ownerSBTTypeMaxLevel; // New state variable

     // Update `issueSBT`: `_ownerSBTTypeMaxLevel[recipient][sbtTypeId] = initialLevel;` (assuming first of this type)
     // Update `updateSBTLevel`: if newLevel > _ownerSBTTypeMaxLevel[ownerOf(tokenId)][sbtTypeId], update it.
     // Also need logic for when tokens are revoked - need to re-calculate max level for the owner/type.
     // Re-calculation on revoke is expensive. Let's note this as a potential optimization area.
     // For demo, we'll just return the tracked max level, which might be slightly inaccurate if a token with the max level was revoked.

    /**
     * @dev Gets the maximum level of an SBT of a specific type held by an address.
     * @param owner The address to query.
     * @param sbtTypeId The ID of the SBT type.
     * @return maxLevel The maximum level found, or 0 if no token of that type is held.
     */
    function getMaxSBTLevelOfType(address owner, uint256 sbtTypeId) external view returns (uint256) {
         if (!_sbtTypeExists[sbtTypeId]) return 0; // Handle invalid type
        return _ownerSBTTypeMaxLevel[owner][sbtTypeId];
    }

    /**
     * @dev Gets the details of an SBT type.
     * @param sbtTypeId The ID of the SBT type.
     * @return name The name of the type.
     * @return description The description of the type.
     * @return baseWeight The base weight for reputation calculation.
     */
    function getSBTTypeDetails(uint256 sbtTypeId)
        external
        view
        returns (string memory name, string memory description, uint256 baseWeight)
    {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        SBTType storage sbtType = _sbtTypes[sbtTypeId];
        return (sbtType.name, sbtType.description, sbtType.baseWeight);
    }

    /**
     * @dev Checks if an address is authorized as an attestor for a specific SBT type.
     * @param sbtTypeId The ID of the SBT type.
     * @param attestor The address to check.
     * @return bool True if the address is a direct attestor for the type, false otherwise.
     */
    function isAttestorForType(uint256 sbtTypeId, address attestor) external view returns (bool) {
        if (!_sbtTypeExists[sbtTypeId]) return false; // Handle invalid type
        return _typeAttestors[sbtTypeId][attestor];
    }

     /**
     * @dev Checks if an address is currently a delegatee for attestation rights of a specific SBT type for any delegator.
     *      Requires the reverse mapping for efficiency.
     * @param sbtTypeId The ID of the SBT type.
     * @param delegatee The address to check.
     * @return bool True if the address is a delegatee for the type, false otherwise.
     */
     function isDelegateeForAttestationRights(uint256 sbtTypeId, address delegatee) external view returns (bool) {
         if (!_sbtTypeExists[sbtTypeId]) return false; // Handle invalid type
         return _attestationRightsDelegationsReverse[delegatee][sbtTypeId] != address(0);
     }


     /**
     * @dev Gets the address that an address has delegated attestation rights to for a specific SBT type.
     * @param delegator The address that might have delegated.
     * @param sbtTypeId The ID of the SBT type.
     * @return delegatee The delegatee address, or address(0) if no delegation exists for this type.
     */
    function getDelegateeForAttestationRights(address delegator, uint256 sbtTypeId) external view returns (address) {
         if (!_sbtTypeExists[sbtTypeId]) return address(0); // Handle invalid type
        return _attestationRightsDelegations[delegator][sbtTypeId];
    }

     /**
     * @dev Gets the address that has delegated attestation rights *to* an address for a specific SBT type.
     *      Requires the reverse mapping.
     * @param delegatee The address that might be a delegatee.
     * @param sbtTypeId The ID of the SBT type.
     * @return delegator The delegator address, or address(0) if not a delegatee for this type.
     */
    function getDelegatorOfAttestationRights(address delegatee, uint256 sbtTypeId) external view returns (address) {
        if (!_sbtTypeExists[sbtTypeId]) return address(0); // Handle invalid type
        return _attestationRightsDelegationsReverse[delegatee][sbtTypeId];
    }


    /**
     * @dev Gets all attestations made on a specific SBT token.
     * @param sbtTokenId The ID of the SBT token.
     * @return attestations An array of Attestation structs.
     */
    function getAttestationsForSBT(uint256 sbtTokenId) external view returns (Attestation[] memory) {
        if (!_exists(sbtTokenId)) {
            revert SBTDoesNotExist(sbtTokenId);
        }
        // Return a memory copy of the dynamic array
        Attestation[] storage storedAttestations = _attestations[sbtTokenId];
        Attestation[] memory attestationsCopy = new Attestation[](storedAttestations.length);
        for (uint i = 0; i < storedAttestations.length; i++) {
            attestationsCopy[i] = storedAttestations[i];
        }
        return attestationsCopy;
    }

     /**
     * @dev Checks if an attestation exists from a specific attester on a specific SBT.
     * @param sbtTokenId The ID of the SBT token.
     * @param attester The address of the attester.
     * @return bool True if the attestation exists, false otherwise.
     */
    function attestationExists(uint256 sbtTokenId, address attester) external view returns (bool) {
        if (!_exists(sbtTokenId)) return false; // Token must exist
        return _attestationExists[sbtTokenId][attester];
    }


    /**
     * @dev Calculates a simple dynamic reputation score for an address.
     *      Score = Sum( (SBT Level * SBT Type Base Weight) + Sum(Attestation Weight for this SBT) ) for all owned SBTs.
     *      Note: This function can be computationally expensive depending on the number of SBTs and attestations
     *      an address has. For production, a more efficient calculation (e.g., updating score on changes)
     *      or off-chain calculation might be needed.
     *      Requires iterating through all owned tokens and their attestations.
     *      Since ERC721Enumerable is not used, we cannot iterate owned tokens directly on-chain efficiently.
     *      Let's make this function calculate based on a provided list of token IDs owned by the user.
     *      This shifts the burden of finding owned tokens off-chain.
     *      OR, let's *assume* ERC721Enumerable is being used internally or we'd add it.
     *      Let's add ERC721Enumerable for this example to demonstrate calculation.
     */
     // --- Adding ERC721Enumerable inheritance ---
     import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

     contract SoulBoundTokenNexus is ERC721, Ownable, ERC165Storage, ERC721Enumerable {
         // ... (previous code) ...

         // Override required functions for ERC721Enumerable
         function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
             return super._update(to, tokenId, auth);
         }

         function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
             super._increaseBalance(account, value);
         }

         // ... (rest of the contract code) ...

         // Now `tokenOfOwnerByIndex` and `totalSupply` are available.
         // The `getReputationScore` can use these.

         function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165Storage, ERC721Enumerable) returns (bool) {
             return super.supportsInterface(interfaceId);
         }
     }

     // --- Revising getReputationScore with Enumerable ---

    /**
     * @dev Calculates a simple dynamic reputation score for an address.
     *      Score = Sum( (SBT Level * SBT Type Base Weight) + Sum(Attestation Weight for this SBT) ) for all owned SBTs.
     *      Uses ERC721Enumerable to iterate through owned tokens. Can be gas-heavy for many tokens/attestations.
     * @param account The address to calculate the score for.
     * @return score The calculated reputation score.
     */
    function getReputationScore(address account) external view returns (uint256 score) {
        uint256 ownedTokenCount = balanceOf(account);
        score = 0;

        for (uint256 i = 0; i < ownedTokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i); // Requires ERC721Enumerable

            uint256 sbtTypeId = _tokenSBTTypeId[tokenId];
            // Should check if sbtTypeId is valid, but should be if token exists.
            // if (!_sbtTypeExists[sbtTypeId]) continue; // Should not happen

            uint256 sbtLevel = _tokenLevel[tokenId];
            uint256 sbtBaseWeight = _sbtTypes[sbtTypeId].baseWeight;

            // Contribution from the SBT itself
            score += sbtLevel * sbtBaseWeight;

            // Contribution from attestations on this SBT
            Attestation[] memory attestations = _attestations[tokenId];
            for (uint j = 0; j < attestations.length; j++) {
                score += attestations[j].weight; // Simple sum of attestation weights
            }
        }
        // Note: This is a very basic scoring model. Real systems would be more complex.
    }


    /**
     * @dev Gets the total number of distinct SBT types initialized.
     * @return count The total number of SBT types.
     */
    function getSBTTypeCount() external view returns (uint256) {
        return _sbtTypeIdCounter.current();
    }

    /**
     * @dev Gets the total number of SBT tokens minted (including burned, if any).
     *      Note: This counter doesn't decrement on burn. Use `totalSupply()` from ERC721Enumerable
     *      for currently existing tokens.
     * @return count The total number of SBTs ever issued.
     */
    function getTotalSBTIssued() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Gets the current base URI for token metadata.
     */
    function getBaseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    // --- Total Functions Count Check ---
    // Admin/Setup: 8 (initType, updateWeight, addAttestor, removeAttestor, setBaseURI, withdrawERC20, withdrawEther, owner())
    // SBT Management: 4 (issueSBT, updateLevel, updateMetadata, revokeSBT)
    // Attestation Management: 4 (attestSBT, revokeAttestation, delegateRights, revokeDelegation)
    // Query/View: 14 (getSBTDetails, getOwnerSBTCount, hasSBTOfType, getMaxSBTLevelOfType, getSBTTypeDetails,
    //                  isAttestorForType, isDelegateeForAttestationRights, getDelegateeForAttestationRights,
    //                  getDelegatorOfAttestationRights, getAttestationsForSBT, attestationExists,
    //                  getReputationScore, getSBTTypeCount, getTotalSBTIssued, getBaseURI)
    // ERC721 Overrides: 3 (_beforeTokenTransfer, supportsInterface, tokenURI)
    // ERC721Enumerable Overrides: 2 (_update, _increaseBalance)
    // Constructor: 1

    // Total = 8 + 4 + 4 + 14 + 3 + 2 + 1 = 36 functions. More than the required 20.

    // Re-check imports and inheritance after adding ERC721Enumerable.
    // Add missing imports and fix inheritance list.

    // --- Adding ERC20 Interface for withdrawERC20 ---
    interface IERC20 {
        function transfer(address recipient, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
    }
}

```

---
Let's put it all together into the final code block.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For listing owned tokens
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

/**
 * @title SoulBoundTokenNexus
 * @dev A sophisticated SoulBound Token (SBT) system managing multi-faceted
 *      on-chain identity, achievements, and reputation.
 *      Tokens are non-transferable and represent different types (Skill, Reputation, etc.).
 *      The system allows decentralized attestation, delegation of attestation rights,
 *      and dynamic scoring based on owned SBTs and received attestations.
 *
 * Outline:
 * 1. Imports & Interfaces
 * 2. Errors
 * 3. Events
 * 4. Structs & Enums
 * 5. State Variables
 * 6. Constructor
 * 7. ERC721 Overrides (_beforeTokenTransfer, supportsInterface, tokenURI)
 * 8. Admin & Setup Functions (Owner/Admin Only)
 * 9. SBT Management Functions (Authorized Attestors/Issuer)
 * 10. Attestation Management Functions
 * 11. Query/View Functions (Public)
 * 12. Utility Functions (Withdrawals)
 *
 * Function Summary:
 * - initializeSBTType(name, description, baseWeight): Initializes a new SBT type (Owner only).
 * - updateSBTTypeWeight(sbtTypeId, newBaseWeight): Updates the reputation weight of an SBT type (Owner only).
 * - addAttestorRole(sbtTypeId, attestor): Grants attestor permission for an SBT type (Owner only).
 * - removeAttestorRole(sbtTypeId, attestor): Revokes attestor permission for an SBT type (Owner only).
 * - setBaseURI(baseURI): Sets the base URI for token metadata (Owner only).
 * - withdrawERC20(tokenAddress): Withdraws ERC20 tokens (Owner only).
 * - withdrawEther(): Withdraws Ether (Owner only).
 * - issueSBT(recipient, sbtTypeId, initialLevel, tokenURI): Mints a new SBT (Owner or authorized Attestor).
 * - updateSBTLevel(tokenId, newLevel): Updates an SBT's level (Owner, Issuer, or authorized Attestor).
 * - updateSBTMetadata(tokenId, newURI): Updates an SBT's metadata URI (Owner, Issuer, or authorized Attestor).
 * - revokeSBT(tokenId): Burns an SBT (Owner, Issuer, or authorized Attestor).
 * - attestSBT(sbtTokenId, weight): Attests to an SBT's validity/strength (Owner, authorized Attestor, or Delegatee).
 * - revokeAttestation(sbtTokenId, attesterAddress): Revokes a specific attestation (Original Attester or Owner).
 * - delegateAttestationRights(sbtTypeId, delegatee): Delegates attestation rights for a type (Owner or authorized Attestor).
 * - revokeAttestationRightsDelegation(sbtTypeId): Revokes delegation for a type (Delegator only).
 * - getSBTDetails(tokenId): Gets details of an SBT token.
 * - getOwnerSBTCount(owner): Gets the number of SBTs owned by an address (from ERC721).
 * - hasSBTOfType(owner, sbtTypeId): Checks if an address owns an SBT of a specific type.
 * - getMaxSBTLevelOfType(owner, sbtTypeId): Gets the highest level for an SBT type owned by an address.
 * - getSBTTypeDetails(sbtTypeId): Gets details of an SBT type.
 * - isAttestorForType(sbtTypeId, attestor): Checks if an address is a direct attestor for a type.
 * - isDelegateeForAttestationRights(sbtTypeId, delegatee): Checks if an address is a delegatee for a type.
 * - getDelegateeForAttestationRights(delegator, sbtTypeId): Gets the delegatee for a delegator/type.
 * - getDelegatorOfAttestationRights(delegatee, sbtTypeId): Gets the delegator for a delegatee/type.
 * - getAttestationsForSBT(sbtTokenId): Gets all attestations for an SBT token.
 * - attestationExists(sbtTokenId, attester): Checks if an attestation exists from a specific attester.
 * - getReputationScore(account): Calculates a reputation score based on SBTs and attestations (may be gas-heavy).
 * - getSBTTypeCount(): Gets the total number of SBT types initialized.
 * - getTotalSBTIssued(): Gets the total count of SBTs ever issued (including burned).
 * - getBaseURI(): Gets the current base URI.
 * - _beforeTokenTransfer(from, to, tokenId): Internal override to block transfers.
 * - supportsInterface(interfaceId): ERC165 standard implementation.
 * - tokenURI(tokenId): Gets the metadata URI for a token.
 * - owner(): Inherited from Ownable.
 * - balanceOf(owner): Inherited from ERC721.
 * - ownerOf(tokenId): Inherited from ERC721.
 * - tokenOfOwnerByIndex(owner, index): Inherited from ERC721Enumerable.
 * - totalSupply(): Inherited from ERC721Enumerable.
 * - _update(to, tokenId, auth): Internal override for ERC721Enumerable.
 * - _increaseBalance(account, value): Internal override for ERC721Enumerable.
 */
contract SoulBoundTokenNexus is ERC721, Ownable, ERC165Storage, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Address for address;
    using Strings for uint256;

    // --- 2. Errors ---
    error TokenTransferNotAllowed();
    error InvalidSBTType(uint256 sbtTypeId);
    error NotAuthorizedToIssueSBT(uint256 sbtTypeId);
    error NotAuthorizedToAttestSBT(uint256 sbtTypeId); // Attesting specific types
    error NotAuthorizedToUpdateSBT(uint256 tokenId);
    error SBTDoesNotExist(uint256 tokenId);
    error AttestationAlreadyExists(uint256 sbtTokenId, address attester);
    error AttestationDoesNotExist(uint256 sbtTokenId, address attester);
    error CannotAttestOwnSBT();
    error CannotDelegateToSelf();
    error DelegationExists(uint256 sbtTypeId);
    error DelegationDoesNotExist(uint256 sbtTypeId);
    error AttestorRoleAlreadyExists(uint256 sbtTypeId, address attestor);
    error AttestorRoleDoesNotExist(uint256 sbtTypeId, address attestor);
    error NotAuthorizedToRevokeAttestation(uint256 sbtTokenId, address attester); // Specific error for revoke


    // --- 3. Events ---
    event SBTTypeInitialized(uint256 indexed sbtTypeId, string name, uint256 baseWeight);
    event SBTTypeWeightUpdated(uint256 indexed sbtTypeId, uint256 newBaseWeight);
    event AttestorRoleGranted(uint256 indexed sbtTypeId, address indexed attestor);
    event AttestorRoleRevoked(uint256 indexed sbtTypeId, address indexed attestor);

    event SBTIssued(uint256 indexed tokenId, address indexed owner, uint256 indexed sbtTypeId, address issuer, uint256 initialLevel);
    event SBTLevelUpdated(uint256 indexed tokenId, uint256 newLevel, address updater);
    event SBTMetadataUpdated(uint256 indexed tokenId, string newURI, address updater);
    event SBTRevoked(uint256 indexed tokenId, address indexed owner, address revoker);

    event SBTAttested(uint256 indexed sbtTokenId, address indexed attester, uint256 weight);
    event AttestationRevoked(uint256 indexed sbtTokenId, address indexed attester, address revoker);
    event AttestationRightsDelegated(uint256 indexed sbtTypeId, address indexed delegator, address indexed delegatee);
    event AttestationRightsRevocation(uint256 indexed sbtTypeId, address indexed delegator);

    // --- 4. Structs ---
    struct SBTType {
        string name;
        string description;
        uint256 baseWeight; // Base value for reputation calculation
    }

    struct Attestation {
        address attester;
        uint64 timestamp; // Use uint64 as block.timestamp fits
        uint256 weight; // Weight/influence of this attestation
    }

    // --- 5. State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _sbtTypeIdCounter;

    // SBT Type storage
    mapping(uint256 => SBTType) private _sbtTypes;
    mapping(uint256 => bool) private _sbtTypeExists;

    // SBT Instance storage (keyed by tokenId)
    mapping(uint256 => uint256) private _tokenSBTTypeId;
    mapping(uint256 => uint256) private _tokenLevel;
    mapping(uint256 => string) private _tokenURI; // Per-token URI allows dynamic metadata
    mapping(uint256 => address) private _tokenIssuer; // Who initially issued the token

    // Attestation storage (SBT Token ID => List of Attestations)
    mapping(uint256 => Attestation[]) private _attestations;
    // For quicker lookup if an attestation exists from a specific address on a specific token
    mapping(uint256 => mapping(address => bool)) private _attestationExists;

    // Attestor Roles: SBT Type ID => Attestor Address => bool
    mapping(uint256 => mapping(address => bool)) private _typeAttestors;

    // Delegated Attestation Rights: Delegator Address => SBT Type ID => Delegatee Address
    mapping(address => mapping(uint256 => address)) private _attestationRightsDelegations;
    // Reverse mapping for quick lookup of delegator by delegatee
    mapping(address => mapping(uint256 => address)) private _attestationRightsDelegationsReverse;


    // Helper mappings for efficient queries without ERC721Enumerable iteration (partially redundant with Enumerable but good practice)
    mapping(address => mapping(uint256 => uint256)) private _ownerSBTTypeCount;
    mapping(address => mapping(uint256 => uint256)) private _ownerSBTTypeMaxLevel; // Max level per owner per type

    // Base URI for metadata fallback
    string private _baseTokenURI;

    // --- 6. Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Register standard ERC165 interfaces for ERC721, Metadata, and Enumerable
        _registerInterface(bytes4(keccak256("IERC721")));
        _registerInterface(bytes4(keccak256("IERC721Metadata")));
        _registerInterface(bytes4(keccak256("IERC721Enumerable")));
    }

    // --- 7. ERC721 Overrides ---

    /**
     * @dev See {ERC721-_beforeTokenTransfer}. This hook is used to enforce
     * non-transferability of SoulBound Tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // Allow minting (from == address(0)) and burning (to == address(0))
        // Disallow transfers between users (from != address(0) && to != address(0))
        if (from != address(0) && to != address(0)) {
            revert TokenTransferNotAllowed();
        }
    }

     /**
     * @dev See {ERC721Enumerable-_update}. Required override for ERC721Enumerable.
     */
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

     /**
     * @dev See {ERC721Enumerable-_increaseBalance}. Required override for ERC721Enumerable.
     */
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }


    /**
     * @dev See {ERC165Storage-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165Storage, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-tokenURI}. Fetches the specific token URI if set,
     *      otherwise falls back to the base URI with token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert ERC721Metadata.URIQueryForNonexistentToken(); // Use standard error
        }
        string memory specificURI = _tokenURI[tokenId];
        if (bytes(specificURI).length > 0) {
            return specificURI;
        }
        // Fallback to base URI if specific URI not set
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    // --- 8. Admin & Setup Functions ---

    /**
     * @dev Initializes a new type of SoulBound Token.
     *      Only callable by the contract owner.
     * @param name The name of the SBT type (e.g., "Skill: Solidity", "Reputation: Community Guru").
     * @param description A brief description of the SBT type.
     * @param baseWeight The base weight for this type when calculating reputation scores.
     * @return sbtTypeId The unique ID assigned to the new SBT type.
     */
    function initializeSBTType(string calldata name, string calldata description, uint256 baseWeight)
        external
        onlyOwner
        returns (uint256 sbtTypeId)
    {
        _sbtTypeIdCounter.increment();
        sbtTypeId = _sbtTypeIdCounter.current();
        _sbtTypes[sbtTypeId] = SBTType(name, description, baseWeight);
        _sbtTypeExists[sbtTypeId] = true;
        emit SBTTypeInitialized(sbtTypeId, name, baseWeight);
        return sbtTypeId;
    }

    /**
     * @dev Updates the base weight of an existing SBT type.
     *      Only callable by the contract owner.
     * @param sbtTypeId The ID of the SBT type to update.
     * @param newBaseWeight The new base weight for the type.
     */
    function updateSBTTypeWeight(uint256 sbtTypeId, uint256 newBaseWeight) external onlyOwner {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        _sbtTypes[sbtTypeId].baseWeight = newBaseWeight;
        emit SBTTypeWeightUpdated(sbtTypeId, newBaseWeight);
    }

    /**
     * @dev Grants an address the role of an attestor for a specific SBT type.
     *      Attestors can issue and update SBTs of that type, and attest to others' SBTs of that type.
     *      Only callable by the contract owner.
     * @param sbtTypeId The ID of the SBT type.
     * @param attestor The address to grant the role to.
     */
    function addAttestorRole(uint256 sbtTypeId, address attestor) external onlyOwner {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        if (_typeAttestors[sbtTypeId][attestor]) {
            revert AttestorRoleAlreadyExists(sbtTypeId, attestor);
        }
        _typeAttestors[sbtTypeId][attestor] = true;
        emit AttestorRoleGranted(sbtTypeId, attestor);
    }

    /**
     * @dev Revokes the attestor role for an address for a specific SBT type.
     *      Only callable by the contract owner.
     * @param sbtTypeId The ID of the SBT type.
     * @param attestor The address to revoke the role from.
     */
    function removeAttestorRole(uint256 sbtTypeId, address attestor) external onlyOwner {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        if (!_typeAttestors[sbtTypeId][attestor]) {
            revert AttestorRoleDoesNotExist(sbtTypeId, attestor);
        }
        _typeAttestors[sbtTypeId][attestor] = false;
        // Note: This does NOT revoke existing delegations by this attestor.
        // A more complex system might auto-revoke delegations upon role removal.
        emit AttestorRoleRevoked(sbtTypeId, attestor);
    }

    /**
     * @dev Sets the base URI for token metadata.
     *      Only callable by the contract owner.
     *      Used as a fallback if a specific token URI is not set.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens accidentally sent to the contract.
     * @param tokenAddress The address of the ERC20 token.
     */
    function withdrawERC20(address tokenAddress) external onlyOwner {
        // Using Address.isContract to prevent sending Ether to non-contract addresses
        if (tokenAddress.isContract()) {
             IERC20 token = IERC20(tokenAddress);
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    /**
     * @dev Allows the owner to withdraw any Ether accidentally sent to the contract.
     */
    function withdrawEther() external payable onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    // --- 9. SBT Management Functions ---

    /**
     * @dev Mints a new SoulBound Token of a specific type to an address.
     *      Only callable by the contract owner or an authorized attestor for the SBT type.
     * @param recipient The address to mint the SBT to.
     * @param sbtTypeId The ID of the SBT type to issue.
     * @param initialLevel The initial level or score for this SBT.
     * @param tokenURI_ The initial metadata URI for this specific token. Optional.
     * @return tokenId The unique ID of the newly minted SBT.
     */
    function issueSBT(address recipient, uint256 sbtTypeId, uint256 initialLevel, string calldata tokenURI_)
        external
        returns (uint256 tokenId)
    {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }

        // Check authorization: must be owner OR a direct attestor for this type
        if (msg.sender != owner() && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToIssueSBT(sbtTypeId);
        }

        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(recipient, tokenId);

        _tokenSBTTypeId[tokenId] = sbtTypeId;
        _tokenLevel[tokenId] = initialLevel;
        _tokenURI[tokenId] = tokenURI_;
        _tokenIssuer[tokenId] = msg.sender; // Store who issued it

        // Update helper mappings
        _ownerSBTTypeCount[recipient][sbtTypeId]++;
        if (initialLevel > _ownerSBTTypeMaxLevel[recipient][sbtTypeId]) {
             _ownerSBTTypeMaxLevel[recipient][sbtTypeId] = initialLevel;
        }


        emit SBTIssued(tokenId, recipient, sbtTypeId, msg.sender, initialLevel);
        return tokenId;
    }

    /**
     * @dev Updates the level/score of an existing SBT.
     *      Only callable by the original issuer, the contract owner, or an authorized attestor
     *      for the SBT type.
     * @param tokenId The ID of the SBT to update.
     * @param newLevel The new level or score for the SBT.
     */
    function updateSBTLevel(uint256 tokenId, uint256 newLevel) external {
        address currentOwner = ownerOf(tokenId); // ownerOf checks _exists

        uint256 sbtTypeId = _tokenSBTTypeId[tokenId];
        // Check authorization: owner OR original issuer OR direct attestor for this type
        if (msg.sender != owner() && msg.sender != _tokenIssuer[tokenId] && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToUpdateSBT(tokenId);
        }

        _tokenLevel[tokenId] = newLevel;

        // Update max level helper mapping
        if (newLevel > _ownerSBTTypeMaxLevel[currentOwner][sbtTypeId]) {
             _ownerSBTTypeMaxLevel[currentOwner][sbtTypeId] = newLevel;
        }
        // Note: If newLevel is LESS than the current max, we don't update the max here.
        // Re-calculating the true max would require iterating the user's tokens of this type,
        // which is inefficient on-chain without a specific index structure.

        emit SBTLevelUpdated(tokenId, newLevel, msg.sender);
    }

    /**
     * @dev Updates the specific metadata URI for an existing SBT.
     *      Only callable by the original issuer, the contract owner, or an authorized attestor
     *      for the SBT type.
     * @param tokenId The ID of the SBT to update.
     * @param newURI The new metadata URI for the SBT.
     */
    function updateSBTMetadata(uint256 tokenId, string calldata newURI) external {
         ownerOf(tokenId); // Checks _exists

        uint256 sbtTypeId = _tokenSBTTypeId[tokenId];

        // Check authorization: owner OR original issuer OR direct attestor for this type
        if (msg.sender != owner() && msg.sender != _tokenIssuer[tokenId] && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToUpdateSBT(tokenId);
        }

        _tokenURI[tokenId] = newURI;
        emit SBTMetadataUpdated(tokenId, newURI, msg.sender);
    }

    /**
     * @dev Revokes (burns) an existing SoulBound Token.
     *      Only callable by the original issuer, the contract owner, or an authorized attestor
     *      for the SBT type.
     * @param tokenId The ID of the SBT to revoke.
     */
    function revokeSBT(uint256 tokenId) external {
        address currentOwner = ownerOf(tokenId); // ownerOf checks _exists
        uint256 sbtTypeId = _tokenSBTTypeId[tokenId];

        // Check authorization: owner OR original issuer OR direct attestor for this type
         if (msg.sender != owner() && msg.sender != _tokenIssuer[tokenId] && !_typeAttestors[sbtTypeId][msg.sender]) {
            revert NotAuthorizedToUpdateSBT(tokenId); // Reusing error
        }

        // Clear associated attestations before burning
        delete _attestations[tokenId];
        delete _attestationExists[tokenId];

        _burn(tokenId);

        // Clear token-specific state after burn
        delete _tokenSBTTypeId[tokenId];
        delete _tokenLevel[tokenId];
        delete _tokenURI[tokenId];
        delete _tokenIssuer[tokenId];

        // Update helper mappings
        if (_ownerSBTTypeCount[currentOwner][sbtTypeId] > 0) {
             _ownerSBTTypeCount[currentOwner][sbtTypeId]--;
        }
        // Note: Re-calculating _ownerSBTTypeMaxLevel here is expensive.
        // A simpler approach is to clear it, or leave it potentially outdated,
        // relying on `getReputationScore` or off-chain index for accuracy.
        // Clearing it is the safest on-chain if the logic relies solely on this mapping.
        // For this demo, we'll clear it, acknowledging the potential issue if a user
        // had multiple tokens of the same type and only the max one is burned.
        _ownerSBTTypeMaxLevel[currentOwner][sbtTypeId] = 0; // Simplistic clearing


        emit SBTRevoked(tokenId, currentOwner, msg.sender);
    }

    // --- 10. Attestation Management Functions ---

    /**
     * @dev Allows an authorized party to attest to the validity/strength of another user's SBT.
     *      Authorization check: The caller is the contract owner, a direct authorized attestor for the SBT type,
     *      or a delegatee for someone who is authorized.
     *      The effective attester recorded is the authorized address (delegator if applicable, otherwise msg.sender).
     * @param sbtTokenId The ID of the SBT token being attested to.
     * @param weight The weight or influence of this attestation (e.g., skill proficiency rating).
     */
    function attestSBT(uint256 sbtTokenId, uint256 weight) external {
        address ownerOfSBT = ownerOf(sbtTokenId); // ownerOf checks _exists
        if (msg.sender == ownerOfSBT) {
            revert CannotAttestOwnSBT();
        }

        uint256 sbtTypeId = _tokenSBTTypeId[sbtTokenId]; // Token type ID is guaranteed to exist if token exists

        // Determine effective attestor and check authorization
        address effectiveAttestor;
        address potentialDelegator = _attestationRightsDelegationsReverse[msg.sender][sbtTypeId];

        bool isDirectlyAuthorized = (msg.sender == owner()) || _typeAttestors[sbtTypeId][msg.sender];
        bool isDelegatedAuthorized = (potentialDelegator != address(0)) && // msg.sender is a delegatee
                                     ((potentialDelegator == owner()) || _typeAttestors[sbtTypeId][potentialDelegator]); // The delegator is authorized

        if (!isDirectlyAuthorized && !isDelegatedAuthorized) {
            revert NotAuthorizedToAttestSBT(sbtTypeId);
        }

        effectiveAttestor = isDirectlyAuthorized ? msg.sender : potentialDelegator;

        // Check if attestation from this effective attestor already exists for this SBT
        if (_attestationExists[sbtTokenId][effectiveAttestor]) {
             revert AttestationAlreadyExists(sbtTokenId, effectiveAttestor);
        }

        // Add the attestation
        _attestations[sbtTokenId].push(Attestation(effectiveAttestor, uint64(block.timestamp), weight));
        _attestationExists[sbtTokenId][effectiveAttestor] = true;

        emit SBTAttested(sbtTokenId, effectiveAttestor, weight);
    }

     /**
     * @dev Revokes a previous attestation made by a specific attester on an SBT.
     *      Only callable by the contract owner or the address that was the *effective* attester
     *      when the attestation was made.
     * @param sbtTokenId The ID of the SBT token the attestation is on.
     * @param attesterAddress The address that is recorded as the effective attester in the attestation struct.
     */
    function revokeAttestation(uint256 sbtTokenId, address attesterAddress) external {
        ownerOf(sbtTokenId); // Checks _exists

        // Check if an attestation from this attesterAddress exists for this SBT
        if (!_attestationExists[sbtTokenId][attesterAddress]) {
             revert AttestationDoesNotExist(sbtTokenId, attesterAddress);
        }

        // Authorization check: Only the original effective attester OR the owner can revoke
        if (msg.sender != attesterAddress && msg.sender != owner()) {
             revert NotAuthorizedToRevokeAttestation(sbtTokenId, attesterAddress);
        }

        // Find and remove the attestation
        Attestation[] storage attestations = _attestations[sbtTokenId];
        bool found = false;
        for (uint i = 0; i < attestations.length; i++) {
            if (attestations[i].attester == attesterAddress) {
                // Found it. Swap with last element and pop.
                attestations[i] = attestations[attestations.length - 1];
                attestations.pop();
                found = true;
                break; // Assuming only one attestation per effective attester per SBT
            }
        }

        if (!found) {
             revert AttestationDoesNotExist(sbtTokenId, attesterAddress); // Should not happen if _attestationExists was true
        }

        _attestationExists[sbtTokenId][attesterAddress] = false;

        emit AttestationRevoked(sbtTokenId, attesterAddress, msg.sender);
    }

    /**
     * @dev Delegates the right to attest for a specific SBT type to another address.
     *      Only callable by the address that holds the attestation right (owner or direct attestor).
     *      An address can only delegate rights for a specific type to ONE delegatee at a time.
     *      Set delegatee to address(0) to clear delegation.
     * @param sbtTypeId The ID of the SBT type for which to delegate rights.
     * @param delegatee The address to delegate the rights to. address(0) to clear delegation.
     */
    function delegateAttestationRights(uint256 sbtTypeId, address delegatee) external {
        if (!_sbtTypeExists[sbtTypeId]) revert InvalidSBTType(sbtTypeId);
        if (msg.sender == delegatee) revert CannotDelegateToSelf();

        // Check if sender has attestation rights for this type (owner or direct attestor)
        if (msg.sender != owner() && !_typeAttestors[sbtTypeId][msg.sender]) {
             revert NotAuthorizedToAttestSBT(sbtTypeId); // Reusing error
        }

        address currentDelegatee = _attestationRightsDelegations[msg.sender][sbtTypeId];

        if (delegatee == address(0)) {
            // Revoking delegation
            if (currentDelegatee == address(0)) revert DelegationDoesNotExist(sbtTypeId);
            delete _attestationRightsDelegations[msg.sender][sbtTypeId];
            delete _attestationRightsDelegationsReverse[currentDelegatee][sbtTypeId];
            emit AttestationRightsRevocation(sbtTypeId, msg.sender);
        } else {
            // Setting/Updating delegation
            if (currentDelegatee != address(0)) {
                 // Allow updating delegation to a new delegatee? Or require explicit revoke first?
                 // Requiring explicit revoke is simpler state management.
                 revert DelegationExists(sbtTypeId); // Require explicit revoke first
            }
            _attestationRightsDelegations[msg.sender][sbtTypeId] = delegatee;
            _attestationRightsDelegationsReverse[delegatee][sbtTypeId] = msg.sender;
            emit AttestationRightsDelegated(sbtTypeId, msg.sender, delegatee);
        }
    }

     /**
     * @dev Revokes an existing delegation of attestation rights for a specific SBT type.
     *      Only callable by the delegator.
     * @param sbtTypeId The ID of the SBT type for which to revoke delegation.
     */
    function revokeAttestationRightsDelegation(uint256 sbtTypeId) external {
         if (!_sbtTypeExists[sbtTypeId]) revert InvalidSBTType(sbtTypeId);
         address currentDelegatee = _attestationRightsDelegations[msg.sender][sbtTypeId];
         if (currentDelegatee == address(0)) revert DelegationDoesNotExist(sbtTypeId);

        delete _attestationRightsDelegations[msg.sender][sbtTypeId];
        delete _attestationRightsDelegationsReverse[currentDelegatee][sbtTypeId];
        emit AttestationRightsRevocation(sbtTypeId, msg.sender);
    }

    // --- 11. Query/View Functions ---

    /**
     * @dev Gets the details of a specific SBT.
     * @param tokenId The ID of the SBT.
     * @return sbtTypeId_ The type ID of the SBT.
     * @return owner_ The owner of the SBT.
     * @return level_ The current level/score of the SBT.
     * @return uri_ The metadata URI for the SBT.
     * @return issuer_ The address that originally issued the SBT.
     */
    function getSBTDetails(uint256 tokenId)
        external
        view
        returns (uint256 sbtTypeId_, address owner_, uint256 level_, string memory uri_, address issuer_)
    {
        owner_ = ownerOf(tokenId); // ownerOf checks _exists
        sbtTypeId_ = _tokenSBTTypeId[tokenId];
        level_ = _tokenLevel[tokenId];
        uri_ = tokenURI(tokenId); // Use the tokenURI function to get the correct URI
        issuer_ = _tokenIssuer[tokenId];
    }

    /**
     * @dev Gets the number of SBTs owned by an address.
     * @param owner The address to query.
     * @return count The number of SBTs owned by the address.
     */
    function getOwnerSBTCount(address owner) external view returns (uint256) {
        return balanceOf(owner); // ERC721 standard function
    }

    // Note: Listing all tokens of an owner requires ERC721Enumerable, available via `tokenOfOwnerByIndex`.
    // Example: function getOwnerSBTs(address owner) external view returns (uint256[] memory) { ... }
    // This is implicitly covered by inheriting ERC721Enumerable.

    /**
     * @dev Checks if an address holds at least one SBT of a specific type.
     * @param owner The address to query.
     * @param sbtTypeId The ID of the SBT type.
     * @return bool True if the address holds at least one token of the type, false otherwise.
     */
    function hasSBTOfType(address owner, uint256 sbtTypeId) external view returns (bool) {
         if (!_sbtTypeExists[sbtTypeId]) return false;
        return _ownerSBTTypeCount[owner][sbtTypeId] > 0;
    }

    /**
     * @dev Gets the maximum level of an SBT of a specific type held by an address.
     * @param owner The address to query.
     * @param sbtTypeId The ID of the SBT type.
     * @return maxLevel The maximum level found, or 0 if no token of that type is held.
     *      Note: This relies on the `_ownerSBTTypeMaxLevel` tracking, which might be slightly
     *      outdated if a token with the max level was revoked without re-calculating.
     */
    function getMaxSBTLevelOfType(address owner, uint256 sbtTypeId) external view returns (uint256) {
         if (!_sbtTypeExists[sbtTypeId]) return 0;
        return _ownerSBTTypeMaxLevel[owner][sbtTypeId];
    }

    /**
     * @dev Gets the details of an SBT type.
     * @param sbtTypeId The ID of the SBT type.
     * @return name The name of the type.
     * @return description The description of the type.
     * @return baseWeight The base weight for reputation calculation.
     */
    function getSBTTypeDetails(uint256 sbtTypeId)
        external
        view
        returns (string memory name, string memory description, uint256 baseWeight)
    {
        if (!_sbtTypeExists[sbtTypeId]) {
            revert InvalidSBTType(sbtTypeId);
        }
        SBTType storage sbtType = _sbtTypes[sbtTypeId];
        return (sbtType.name, sbtType.description, sbtType.baseWeight);
    }

    /**
     * @dev Checks if an address is authorized as a direct attestor for a specific SBT type.
     * @param sbtTypeId The ID of the SBT type.
     * @param attestor The address to check.
     * @return bool True if the address is a direct attestor for the type, false otherwise.
     */
    function isAttestorForType(uint256 sbtTypeId, address attestor) external view returns (bool) {
        if (!_sbtTypeExists[sbtTypeId]) return false;
        return _typeAttestors[sbtTypeId][attestor];
    }

     /**
     * @dev Checks if an address is currently a delegatee for attestation rights of a specific SBT type for any delegator.
     * @param sbtTypeId The ID of the SBT type.
     * @param delegatee The address to check.
     * @return bool True if the address is a delegatee for the type, false otherwise.
     */
     function isDelegateeForAttestationRights(uint256 sbtTypeId, address delegatee) external view returns (bool) {
         if (!_sbtTypeExists[sbtTypeId]) return false;
         return _attestationRightsDelegationsReverse[delegatee][sbtTypeId] != address(0);
     }

     /**
     * @dev Gets the address that an address has delegated attestation rights to for a specific SBT type.
     * @param delegator The address that might have delegated.
     * @param sbtTypeId The ID of the SBT type.
     * @return delegatee The delegatee address, or address(0) if no delegation exists for this type.
     */
    function getDelegateeForAttestationRights(address delegator, uint256 sbtTypeId) external view returns (address) {
         if (!_sbtTypeExists[sbtTypeId]) return address(0);
        return _attestationRightsDelegations[delegator][sbtTypeId];
    }

     /**
     * @dev Gets the address that has delegated attestation rights *to* an address for a specific SBT type.
     * @param delegatee The address that might be a delegatee.
     * @param sbtTypeId The ID of the SBT type.
     * @return delegator The delegator address, or address(0) if not a delegatee for this type.
     */
    function getDelegatorOfAttestationRights(address delegatee, uint256 sbtTypeId) external view returns (address) {
        if (!_sbtTypeExists[sbtTypeId]) return address(0);
        return _attestationRightsDelegationsReverse[delegatee][sbtTypeId];
    }

    /**
     * @dev Gets all attestations made on a specific SBT token.
     * @param sbtTokenId The ID of the SBT token.
     * @return attestations An array of Attestation structs.
     */
    function getAttestationsForSBT(uint256 sbtTokenId) external view returns (Attestation[] memory) {
        ownerOf(sbtTokenId); // Checks _exists
        // Return a memory copy of the dynamic array
        Attestation[] storage storedAttestations = _attestations[sbtTokenId];
        Attestation[] memory attestationsCopy = new Attestation[](storedAttestations.length);
        for (uint i = 0; i < storedAttestations.length; i++) {
            attestationsCopy[i] = storedAttestations[i];
        }
        return attestationsCopy;
    }

     /**
     * @dev Checks if an attestation exists from a specific attester on a specific SBT.
     * @param sbtTokenId The ID of the SBT token.
     * @param attester The address of the attester. This should be the effective attester address recorded.
     * @return bool True if the attestation exists, false otherwise.
     */
    function attestationExists(uint256 sbtTokenId, address attester) external view returns (bool) {
        if (!_exists(sbtTokenId)) return false;
        return _attestationExists[sbtTokenId][attester];
    }


    /**
     * @dev Calculates a simple dynamic reputation score for an address.
     *      Score = Sum( (SBT Level * SBT Type Base Weight) + Sum(Attestation Weight for this SBT) ) for all owned SBTs.
     *      Uses ERC721Enumerable to iterate through owned tokens. Can be gas-heavy for many tokens/attestations.
     * @param account The address to calculate the score for.
     * @return score The calculated reputation score.
     */
    function getReputationScore(address account) external view returns (uint256 score) {
        uint256 ownedTokenCount = balanceOf(account);
        score = 0;

        for (uint256 i = 0; i < ownedTokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i); // Requires ERC721Enumerable

            uint256 sbtTypeId = _tokenSBTTypeId[tokenId];
             if (!_sbtTypeExists[sbtTypeId]) continue; // Should not happen if logic is correct, but defensive

            uint256 sbtLevel = _tokenLevel[tokenId];
            uint256 sbtBaseWeight = _sbtTypes[sbtTypeId].baseWeight;

            // Contribution from the SBT itself (Level * Base Weight)
            score += sbtLevel * sbtBaseWeight;

            // Contribution from attestations on this SBT (Sum of Attestation Weights)
            Attestation[] memory attestations = _attestations[tokenId];
            for (uint j = 0; j < attestations.length; j++) {
                score += attestations[j].weight; // Simple sum of attestation weights
            }
        }
        // Note: This is a basic scoring model. Real systems might use decay, different weights, etc.
    }


    /**
     * @dev Gets the total number of distinct SBT types initialized.
     * @return count The total number of SBT types.
     */
    function getSBTTypeCount() external view returns (uint256) {
        return _sbtTypeIdCounter.current();
    }

    /**
     * @dev Gets the total number of SBT tokens ever minted.
     *      Note: This is a cumulative counter and does not decrement on burn.
     *      Use `totalSupply()` from ERC721Enumerable for the number of currently existing tokens.
     * @return count The total number of SBTs ever issued.
     */
    function getTotalSBTIssued() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Gets the current base URI for token metadata.
     */
    function getBaseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    // Inherited functions from ERC721, Ownable, ERC721Enumerable:
    // - owner()
    // - balanceOf(address owner)
    // - ownerOf(uint256 tokenId)
    // - tokenOfOwnerByIndex(address owner, uint256 index)
    // - totalSupply()
}

// Simple ERC20 interface for withdrawal function
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```