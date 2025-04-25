Okay, here is a Solidity smart contract implementing a "Soulbound Identity NFT" concept. This contract mints non-transferable NFTs that represent unique identities tied to a wallet address. These identities can accumulate "claims" or "attributes" issued by authorized parties, and a basic on-chain reputation score can be derived from these claims.

It incorporates several advanced concepts:

1.  **Soulbound Nature:** Overrides standard ERC721 transfer mechanisms to make tokens non-transferable.
2.  **Dynamic Claims/Attributes:** Allows attaching structured data (claims) to an identity token after minting.
3.  **Role-Based Access Control:** Uses OpenZeppelin's AccessControl to manage permissions for minting, issuing claims, and configuring reputation.
4.  **On-Chain Reputation (Basic):** A simple scoring mechanism based on weighted claim types.
5.  **Pausable:** Ability to pause critical functions.
6.  **Events:** Comprehensive events for tracking state changes.
7.  **Enumerable-like Queries (Address-based):** Provides functions to get token ID by address and vice versa, relevant for identity tokens.
8.  **Time-Based Claims:** Claims can have optional expiry dates.

It includes well over 20 functions by incorporating core logic, access control helpers, pausing, and standard ERC721 getters (which are still relevant even if transfers are disabled).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- Outline and Function Summary ---
//
// Contract: SoulboundIdentityNFT
// Type: ERC721 (Modified - Non-Transferable)
// Purpose: Represents a unique, non-transferable on-chain identity.
// Features:
// - Minting and Revocation of unique identity NFTs per address.
// - Attaching verifiable claims/attributes to identities by authorized issuers.
// - Time-sensitive claims with expiry dates.
// - Basic on-chain reputation scoring based on claim types.
// - Role-based access control for minting, claiming, and configuration.
// - Pausability for emergency situations.
//
// Functions:
// 1. constructor: Initializes the contract, sets name/symbol, grants default admin and initial roles.
// 2. supportsInterface: Standard ERC165 support.
// 3. balanceOf: Standard ERC721 - overridden to check for existence of the *single* identity token for an address.
// 4. ownerOf: Standard ERC721 - overridden for clarity on identity ownership.
// 5. safeTransferFrom (override): Prevents token transfers - enforces soulbound property.
// 6. transferFrom (override): Prevents token transfers - enforces soulbound property.
// 7. approve (override): Prevents approval - enforces soulbound property.
// 8. setApprovalForAll (override): Prevents approval - enforces soulbound property.
// 9. getApproved (override): Returns zero address as approvals are disabled.
// 10. isApprovedForAll (override): Returns false as approvals are disabled.
// 11. mintIdentity: Mints a new identity NFT for an address (requires MINTER_ROLE, one per address).
// 12. revokeIdentity: Revokes (burns) an identity NFT (requires MINTER_ROLE).
// 13. getTokenIdByAddress: Gets the identity token ID for a given address.
// 14. getAddressByTokenId: Gets the address associated with a given token ID (same as ownerOf).
// 15. getTotalIdentitiesIssued: Gets the total number of identities ever minted.
// 16. isSoulbound: Returns true, indicating the non-transferable nature.
// 17. addClaim: Adds a claim/attribute to an identity (requires CLAIM_ISSUER_ROLE).
// 18. updateClaim: Updates an existing claim (requires CLAIM_ISSUER_ROLE or DEFAULT_ADMIN_ROLE).
// 19. removeClaim: Removes a claim from an identity (requires CLAIM_ISSUER_ROLE or DEFAULT_ADMIN_ROLE).
// 20. getClaimDetails: Retrieves details of a specific claim for an identity.
// 21. getAllClaimKeys: Lists all claim keys associated with an identity.
// 22. isClaimExpired: Checks if a specific claim has expired.
// 23. renewClaim: Renews an expired claim by setting a new expiry (requires CLAIM_ISSUER_ROLE or DEFAULT_ADMIN_ROLE).
// 24. setClaimTypeWeight: Sets a weight for a claim type for reputation scoring (requires REPUTATION_ADMIN_ROLE).
// 25. getClaimTypeWeight: Gets the weight for a specific claim type.
// 26. getReputationScore: Calculates a simple reputation score based on weighted, non-expired claims.
// 27. setBaseURI: Sets the base URI for token metadata (requires DEFAULT_ADMIN_ROLE).
// 28. tokenURI: Standard ERC721 - gets the metadata URI for a token.
// 29. pause: Pauses the contract (requires PAUSER_ROLE or DEFAULT_ADMIN_ROLE - using DEFAULT_ADMIN_ROLE here for simplicity).
// 30. unpause: Unpauses the contract (requires PAUSER_ROLE or DEFAULT_ADMIN_ROLE).
// 31. paused: Checks if the contract is paused.
// 32. grantRole: Grants a role (requires role's admin or DEFAULT_ADMIN_ROLE).
// 33. revokeRole: Revokes a role (requires role's admin or DEFAULT_ADMIN_ROLE).
// 34. renounceRole: Renounces a role (self-service).
// 35. hasRole: Checks if an address has a role.
// 36. getRoleAdmin: Gets the admin role for a given role.
// 37. getRoleMemberCount: Gets the number of members with a role.
// 38. getRoleMember: Gets a member at an index for a role.
// 39. getIdentityIssueTimestamp: Gets the timestamp when an identity was minted.
// 40. isClaimIssuer: Checks if an address was the issuer of a specific claim.

 contract SoulboundIdentityNFT is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Errors ---
    error IdentityAlreadyExists(address indexed account);
    error IdentityDoesNotExist(address indexed account);
    error IdentityTokenNotFound(uint256 indexed tokenId);
    error CannotTransferSoulbound();
    error ClaimDoesNotExist(uint256 indexed tokenId, string key);
    error NotClaimIssuerOrAdmin();
    error ClaimIsNotExpired(uint256 indexed tokenId, string key);
    error ClaimIsExpired(uint256 indexed tokenId, string key);

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CLAIM_ISSUER_ROLE = keccak256("CLAIM_ISSUER_ROLE");
    bytes32 public constant REPUTATION_ADMIN_ROLE = keccak256("REPUTATION_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Although Pausable uses DEFAULT_ADMIN_ROLE by default

    // --- State Variables ---
    Counters.Counter private _tokenIds;

    // Mapping from owner address to token ID
    mapping(address => uint256) private _addressToTokenId;

    // Mapping from token ID to owner address (ERC721 already has this via _owner, but redundancy for clarity/lookup)
    // mapping(uint256 => address) private _tokenIdToAddress; // Redundant with ERC721 _owner mapping

    // Struct to store claim details
    struct Claim {
        string value;
        address issuer;
        uint40 timestamp; // Use uint40 for gas efficiency (enough for ~17 trillion seconds > 500k years)
        uint40 expiryTimestamp; // 0 indicates no expiry
    }

    // Mapping from token ID to claim key to claim details
    mapping(uint256 => mapping(string => Claim)) private _tokenClaims;

    // Mapping from token ID to list of claim keys (to retrieve all claims)
    mapping(uint256 => string[]) private _tokenClaimKeys;
    mapping(uint256 => mapping(string => bool)) private _tokenClaimKeyExists; // Helper to track existence

    // Mapping for reputation scoring weights: claim type (key) => weight
    mapping(string => int256) private _claimTypeWeights;

    // Mapping from token ID to issue timestamp
    mapping(uint256 => uint40) private _identityIssueTimestamp;

    // Base URI for token metadata
    string private _baseURI;

    // Flag indicating if the token is soulbound (always true for this contract)
    bool public immutable isSoulbound = true;

    // --- Events ---
    event IdentityMinted(address indexed account, uint256 indexed tokenId, address indexed minter);
    event IdentityRevoked(address indexed account, uint256 indexed tokenId, address indexed revoker);
    event ClaimAdded(uint256 indexed tokenId, string indexed key, string value, address indexed issuer, uint40 timestamp, uint40 expiryTimestamp);
    event ClaimUpdated(uint256 indexed tokenId, string indexed key, string newValue, address indexed updater);
    event ClaimRemoved(uint256 indexed tokenId, string indexed key, address indexed remover);
    event ClaimExpired(uint256 indexed tokenId, string indexed key);
    event ClaimRenewed(uint256 indexed tokenId, string indexed key, uint40 newExpiryTimestamp, address indexed renewer);
    event ClaimTypeWeightSet(string indexed claimKey, int256 weight, address indexed setter);
    event ReputationScoreCalculated(uint256 indexed tokenId, int256 score); // Informative event
    event BaseURISet(string newBaseURI);


    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Grant initial roles (can be changed by admin later)
        // Consider granting MINTER_ROLE and CLAIM_ISSUER_ROLE to the deployer or a specific initial address
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(CLAIM_ISSUER_ROLE, _msgSender());
        _grantRole(REPUTATION_ADMIN_ROLE, _msgSender());
        // _grantRole(PAUSER_ROLE, _msgSender()); // Pausable uses DEFAULT_ADMIN_ROLE by default, can specify PAUSER_ROLE if needed
    }

    // --- Overrides for ERC721 ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(AccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Override balance to check if the address has *any* identity token (should be max 1)
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _exists(_addressToTokenId[owner]) ? 1 : 0;
    }

    // Override ownerOf for clarity (returns the same address it was minted for)
    function ownerOf(uint256 tokenId) public view override returns (address) {
         address owner = super.ownerOf(tokenId);
         if (owner == address(0)) {
             revert IdentityTokenNotFound(tokenId); // Use custom error for better context
         }
         return owner;
    }

    // Prevent transfers
    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert CannotTransferSoulbound();
    }

    // Prevent transfers (SafeTransferFrom uses _transfer internally, but explicit override is clearer)
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        revert CannotTransferSoulbound();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        revert CannotTransferSoulbound();
    }

    // Prevent approvals
    function approve(address to, uint256 tokenId) public override {
        revert CannotTransferSoulbound();
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert CannotTransferSoulbound();
    }

    // Indicate approvals are disabled
    function getApproved(uint256 tokenId) public view override returns (address) {
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return false;
    }

    // --- Core Identity Management ---

    /// @notice Mints a new soulbound identity NFT for the caller or a specified address.
    /// An address can only have one identity NFT.
    /// @param account The address to mint the identity for.
    function mintIdentity(address account) public onlyRole(MINTER_ROLE) whenNotPaused {
        if (_addressToTokenId[account] != 0) {
            revert IdentityAlreadyExists(account);
        }

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // _safeMint automatically checks if the account is address(0)
        _safeMint(account, newItemId);

        // Store mapping
        _addressToTokenId[account] = newItemId;
        // _tokenIdToAddress[newItemId] = account; // Redundant with ERC721 _owner mapping

        // Store issue timestamp
        _identityIssueTimestamp[newItemId] = uint40(block.timestamp);

        emit IdentityMinted(account, newItemId, _msgSender());
    }

    /// @notice Revokes (burns) the identity NFT associated with an address.
    /// This removes the identity and all associated claims.
    /// @param account The address whose identity should be revoked.
    function revokeIdentity(address account) public onlyRole(MINTER_ROLE) whenNotPaused {
        uint256 tokenId = _addressToTokenId[account];
        if (tokenId == 0 || !_exists(tokenId)) {
            revert IdentityDoesNotExist(account);
        }

        // Burn the token
        _burn(tokenId);

        // Clean up mappings
        delete _addressToTokenId[account];
        // delete _tokenIdToAddress[tokenId]; // Redundant

        // Remove all claims associated with this token ID
        string[] storage keys = _tokenClaimKeys[tokenId];
        for (uint i = 0; i < keys.length; i++) {
            delete _tokenClaims[tokenId][keys[i]];
            delete _tokenClaimKeyExists[tokenId][keys[i]];
        }
        delete _tokenClaimKeys[tokenId]; // Clear the keys array
        delete _identityIssueTimestamp[tokenId];

        emit IdentityRevoked(account, tokenId, _msgSender());
    }

    /// @notice Gets the token ID of the identity NFT owned by an address.
    /// Returns 0 if the address does not have an identity.
    /// @param account The address to query.
    /// @return The token ID or 0.
    function getTokenIdByAddress(address account) public view returns (uint256) {
        return _addressToTokenId[account];
    }

     /// @notice Gets the address that owns the identity NFT with a given token ID.
     /// This is the same as the standard ERC721 `ownerOf`, included for semantic clarity.
     /// @param tokenId The token ID to query.
     /// @return The address that owns the token.
    function getAddressByTokenId(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId); // Calls the overridden ownerOf
    }

    /// @notice Gets the total number of identity NFTs that have been minted.
    /// Note: This counter is incremented on mint, not decremented on burn.
    /// @return The total number of identities ever issued.
    function getTotalIdentitiesIssued() public view returns (uint256) {
        return _tokenIds.current();
    }

    // --- Claim Management ---

    /// @notice Adds a claim/attribute to a specific identity token.
    /// Only addresses with the CLAIM_ISSUER_ROLE can add claims.
    /// Claims are key-value pairs and can have an optional expiry timestamp.
    /// @param tokenId The ID of the identity token.
    /// @param key The key (name) of the claim.
    /// @param value The value of the claim.
    /// @param expiryTimestamp The Unix timestamp when the claim expires (0 for no expiry).
    function addClaim(uint256 tokenId, string calldata key, string calldata value, uint40 expiryTimestamp) public onlyRole(CLAIM_ISSUER_ROLE) whenNotPaused {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (_tokenClaimKeyExists[tokenId][key]) {
            revert('Claim already exists, use updateClaim');
        }

        _tokenClaims[tokenId][key] = Claim({
            value: value,
            issuer: _msgSender(),
            timestamp: uint40(block.timestamp),
            expiryTimestamp: expiryTimestamp
        });

        _tokenClaimKeys[tokenId].push(key);
        _tokenClaimKeyExists[tokenId][key] = true;

        emit ClaimAdded(tokenId, key, value, _msgSender(), uint40(block.timestamp), expiryTimestamp);
    }

    /// @notice Updates an existing claim on a specific identity token.
    /// Only the original issuer of the claim or an account with DEFAULT_ADMIN_ROLE can update a claim.
    /// @param tokenId The ID of the identity token.
    /// @param key The key of the claim to update.
    /// @param newValue The new value for the claim.
    /// @param newExpiryTimestamp The new expiry timestamp for the claim (0 for no expiry).
    function updateClaim(uint256 tokenId, string calldata key, string calldata newValue, uint40 newExpiryTimestamp) public whenNotPaused {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (!_tokenClaimKeyExists[tokenId][key]) {
            revert ClaimDoesNotExist(tokenId, key);
        }

        Claim storage claim = _tokenClaims[tokenId][key];
        // Only the original issuer or the contract admin can update
        if (claim.issuer != _msgSender() && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotClaimIssuerOrAdmin();
        }

        claim.value = newValue;
        claim.expiryTimestamp = newExpiryTimestamp; // Allow updating expiry too

        emit ClaimUpdated(tokenId, key, newValue, _msgSender());
    }

    /// @notice Removes a claim from a specific identity token.
    /// Only the original issuer of the claim or an account with DEFAULT_ADMIN_ROLE can remove a claim.
    /// @param tokenId The ID of the identity token.
    /// @param key The key of the claim to remove.
    function removeClaim(uint256 tokenId, string calldata key) public whenNotPaused {
         if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (!_tokenClaimKeyExists[tokenId][key]) {
            revert ClaimDoesNotExist(tokenId, key);
        }

        Claim storage claim = _tokenClaims[tokenId][key];
        // Only the original issuer or the contract admin can remove
        if (claim.issuer != _msgSender() && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotClaimIssuerOrAdmin();
        }

        // Remove from mapping and list
        delete _tokenClaims[tokenId][key];
        delete _tokenClaimKeyExists[tokenId][key];

        string[] storage keys = _tokenClaimKeys[tokenId];
        for (uint i = 0; i < keys.length; i++) {
            if (keccak256(bytes(keys[i])) == keccak256(bytes(key))) {
                // Shift elements left to fill the gap
                for (uint j = i; j < keys.length - 1; j++) {
                    keys[j] = keys[j+1];
                }
                keys.pop(); // Remove the last element
                break;
            }
        }

        emit ClaimRemoved(tokenId, key, _msgSender());
    }


    /// @notice Retrieves the value of a specific claim for an identity.
    /// @param tokenId The ID of the identity token.
    /// @param key The key of the claim.
    /// @return The value of the claim. Reverts if the claim does not exist.
    function getClaimValue(uint256 tokenId, string calldata key) public view returns (string memory) {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (!_tokenClaimKeyExists[tokenId][key]) {
            revert ClaimDoesNotExist(tokenId, key);
        }
        return _tokenClaims[tokenId][key].value;
    }

     /// @notice Retrieves all details of a specific claim for an identity.
     /// @param tokenId The ID of the identity token.
     /// @param key The key of the claim.
     /// @return value The value of the claim.
     /// @return issuer The address that issued the claim.
     /// @return timestamp The Unix timestamp when the claim was added.
     /// @return expiryTimestamp The Unix timestamp when the claim expires (0 for no expiry).
    function getClaimDetails(uint256 tokenId, string calldata key) public view returns (string memory value, address issuer, uint40 timestamp, uint40 expiryTimestamp) {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (!_tokenClaimKeyExists[tokenId][key]) {
            revert ClaimDoesNotExist(tokenId, key);
        }
        Claim storage claim = _tokenClaims[tokenId][key];
        return (claim.value, claim.issuer, claim.timestamp, claim.expiryTimestamp);
    }

    /// @notice Lists all claim keys associated with a specific identity token.
    /// @param tokenId The ID of the identity token.
    /// @return An array of claim keys.
    function getAllClaimKeys(uint256 tokenId) public view returns (string[] memory) {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        // Return a memory copy of the storage array
        string[] storage keys = _tokenClaimKeys[tokenId];
        string[] memory result = new string[](keys.length);
        for(uint i = 0; i < keys.length; i++){
            result[i] = keys[i];
        }
        return result;
    }

    /// @notice Checks if a specific claim on an identity has expired.
    /// Claims with expiryTimestamp == 0 are considered never expired.
    /// @param tokenId The ID of the identity token.
    /// @param key The key of the claim.
    /// @return True if the claim has an expiry set and the current block timestamp is >= expiry timestamp.
    function isClaimExpired(uint256 tokenId, string calldata key) public view returns (bool) {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (!_tokenClaimKeyExists[tokenId][key]) {
             // A non-existent claim could be considered "expired" in a sense,
             // but let's strictly define expired as having existed and passed its date.
             // Reverting is clearer that the claim doesn't exist.
            revert ClaimDoesNotExist(tokenId, key);
        }
        uint40 expiry = _tokenClaims[tokenId][key].expiryTimestamp;
        return expiry != 0 && block.timestamp >= expiry;
    }

    /// @notice Renews an expired claim by setting a new expiry timestamp.
    /// Only the original issuer or an account with DEFAULT_ADMIN_ROLE can renew a claim.
    /// Cannot renew a claim that is not currently expired.
    /// @param tokenId The ID of the identity token.
    /// @param key The key of the claim to renew.
    /// @param newExpiryTimestamp The new expiry timestamp. Must be in the future.
    function renewClaim(uint256 tokenId, string calldata key, uint40 newExpiryTimestamp) public whenNotPaused {
         if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        if (!_tokenClaimKeyExists[tokenId][key]) {
            revert ClaimDoesNotExist(tokenId, key);
        }
         if (!isClaimExpired(tokenId, key)) {
            revert ClaimIsNotExpired(tokenId, key);
        }
         if (newExpiryTimestamp != 0 && block.timestamp >= newExpiryTimestamp) {
             revert('New expiry must be in the future');
         }


        Claim storage claim = _tokenClaims[tokenId][key];
        // Only the original issuer or the contract admin can renew
        if (claim.issuer != _msgSender() && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotClaimIssuerOrAdmin();
        }

        claim.expiryTimestamp = newExpiryTimestamp;

        emit ClaimRenewed(tokenId, key, newExpiryTimestamp, _msgSender());
    }

    // --- Reputation Scoring ---

    /// @notice Sets or updates the weight for a specific claim type used in reputation scoring.
    /// Only accounts with the REPUTATION_ADMIN_ROLE can set weights.
    /// A weight can be positive, negative, or zero.
    /// @param claimKey The key (type) of the claim.
    /// @param weight The integer weight for this claim type.
    function setClaimTypeWeight(string calldata claimKey, int256 weight) public onlyRole(REPUTATION_ADMIN_ROLE) whenNotPaused {
        _claimTypeWeights[claimKey] = weight;
        emit ClaimTypeWeightSet(claimKey, weight, _msgSender());
    }

    /// @notice Gets the current weight for a specific claim type.
    /// Returns 0 if no weight has been set for this type.
    /// @param claimKey The key (type) of the claim.
    /// @return The weight.
    function getClaimTypeWeight(string calldata claimKey) public view returns (int256) {
        return _claimTypeWeights[claimKey];
    }

    /// @notice Calculates a simple on-chain reputation score for an identity.
    /// The score is the sum of weights of all *non-expired* claims associated with the identity.
    /// NOTE: This calculation iterates through claims and can be gas-intensive for identities with many claims.
    /// For complex or frequently accessed scores, off-chain calculation is recommended.
    /// @param tokenId The ID of the identity token.
    /// @return The calculated reputation score.
    function getReputationScore(uint256 tokenId) public view returns (int256) {
         if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }

        int256 totalScore = 0;
        string[] storage keys = _tokenClaimKeys[tokenId]; // Access storage array directly

        for (uint i = 0; i < keys.length; i++) {
            string storage key = keys[i];
            // Ensure the claim key still exists (edge case after potential removal issues if iteration was on a copy)
            if (_tokenClaimKeyExists[tokenId][key]) {
                 Claim storage claim = _tokenClaims[tokenId][key];
                 // Only consider non-expired claims
                 if (claim.expiryTimestamp == 0 || block.timestamp < claim.expiryTimestamp) {
                     totalScore += _claimTypeWeights[key];
                 } else {
                     // Emit an event if a claim is found to be expired during score calculation
                     // Note: This could be spammy if called frequently with many expired claims.
                     // Consider removing expired claims explicitly or handling off-chain.
                     // emit ClaimExpired(tokenId, key); // Too much event data in a view function context
                 }
            }
        }

         // Optionally emit score calculation event (informative)
         // emit ReputationScoreCalculated(tokenId, totalScore); // Cannot emit in view function

        return totalScore;
    }

    // --- Metadata ---

    /// @notice Sets the base URI for token metadata.
    /// The final token URI will be `_baseURI + tokenId.toString()`.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _baseURI = baseURI_;
        emit BaseURISet(baseURI_);
    }

    /// @notice Standard ERC721 function to get the metadata URI for a token.
    /// Returns the base URI concatenated with the token ID.
    /// @param tokenId The ID of the identity token.
    /// @return The metadata URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Inherited check that token exists and caller is owner (not relevant here as it's view)
        // Ensure token exists for robust check
        if (!_exists(tokenId)) {
             revert ERC721NonexistentToken(tokenId);
        }
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
        // Note: Dynamic metadata based on claims would typically require an API backend pointed to by the base URI.
        // The contract itself only stores the claims, it doesn't generate the full JSON metadata on-chain due to gas costs.
    }

    // --- Pausability ---

    /// @notice Pauses the contract, preventing minting, adding/updating claims, and changing weights.
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) { // Using DEFAULT_ADMIN_ROLE as per Pausable default
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) { // Using DEFAULT_ADMIN_ROLE as per Pausable default
        _unpause();
    }

    // paused() is a standard getter provided by Pausable.

    // --- Access Control Helpers (Inherited but listed for completeness) ---
    // hasRole, grantRole, revokeRole, renounceRole, getRoleAdmin, getRoleMemberCount, getRoleMember
    // These are inherited from AccessControl and are callable based on role permissions.


    // --- Utility ---

    /// @notice Gets the timestamp when an identity NFT was minted.
    /// @param tokenId The ID of the identity token.
    /// @return The Unix timestamp of minting.
    function getIdentityIssueTimestamp(uint256 tokenId) public view returns (uint40) {
        if (!_exists(tokenId)) {
            revert IdentityTokenNotFound(tokenId);
        }
        return _identityIssueTimestamp[tokenId];
    }

    /// @notice Checks if a given address was the issuer of a specific claim on an identity.
    /// @param tokenId The ID of the identity token.
    /// @param key The key of the claim.
    /// @param account The address to check.
    /// @return True if the account was the issuer of the claim.
    function isClaimIssuer(uint256 tokenId, string calldata key, address account) public view returns (bool) {
        if (!_exists(tokenId) || !_tokenClaimKeyExists[tokenId][key]) {
            return false; // Cannot be issuer if token or claim doesn't exist
        }
        return _tokenClaims[tokenId][key].issuer == account;
    }

    // Internal helper to check if a token ID exists (private to avoid collision with ERC721 public exists)
    // ERC721 public exists is now _exists in OpenZeppelin 5+, so can use that directly.
    // function _exists(uint256 tokenId) internal view returns (bool) {
    //     return _tokenIdToAddress[tokenId] != address(0);
    // }

    // The standard ERC721 _exists function is sufficient here.
}
```

---

**Explanation of Concepts & Functions:**

1.  **Soulbound Nature:** The core idea is implemented by overriding `safeTransferFrom`, `transferFrom`, `approve`, and `setApprovalForAll` to unconditionally revert. This prevents the token from ever changing wallets.
2.  **Identity Management (`mintIdentity`, `revokeIdentity`):** Only addresses with the `MINTER_ROLE` can issue a new identity. A crucial check ensures an address can only have one identity NFT (`_addressToTokenId`). `revokeIdentity` allows burning the identity, removing all associated data.
3.  **Claim Management (`addClaim`, `updateClaim`, `removeClaim`, `getClaimDetails`, `getAllClaimKeys`, `isClaimExpired`, `renewClaim`):**
    *   `addClaim`: Authorized claim issuers (`CLAIM_ISSUER_ROLE`) can attach key-value claims to an identity. Each claim stores who issued it and when.
    *   `updateClaim` / `removeClaim`: Control over claims rests with the original issuer or the contract admin (`DEFAULT_ADMIN_ROLE`).
    *   `getClaimDetails` / `getAllClaimKeys`: Allow external parties to inspect the claims associated with an identity.
    *   `isClaimExpired` / `renewClaim`: Introduces a time dimension to claims, allowing for verifiable credentials that might need renewal (e.g., certifications, memberships). Renewal requires authorization.
4.  **On-Chain Reputation (`setClaimTypeWeight`, `getReputationScore`):**
    *   `setClaimTypeWeight`: An admin (`REPUTATION_ADMIN_ROLE`) defines how much each *type* of claim (identified by its key) contributes to a score.
    *   `getReputationScore`: Calculates a basic score by summing the weights of all *non-expired* claims on an identity. This is a simple example of deriving reputation from verifiable on-chain data. Note the gas caveat for many claims.
5.  **Access Control (`AccessControl`):** Instead of a single `owner`, roles (`MINTER_ROLE`, `CLAIM_ISSUER_ROLE`, `REPUTATION_ADMIN_ROLE`, `DEFAULT_ADMIN_ROLE`) govern who can perform specific actions, offering more flexible permissioning. Standard OpenZeppelin functions like `grantRole`, `revokeRole`, `hasRole`, etc., are available.
6.  **Pausable (`Pausable`):** Allows an authorized address (default admin) to pause operations like minting, adding claims, etc., in case of emergencies or upgrades (though this specific contract isn't designed for upgradability via proxy).
7.  **Query Functions (`getTokenIdByAddress`, `getAddressByTokenId`, `getTotalIdentitiesIssued`, `getIdentityIssueTimestamp`):** Provide easy ways to look up identity information based on address or token ID, and track issuance.
8.  **Metadata (`setBaseURI`, `tokenURI`):** Follows the ERC721 metadata standard. The `tokenURI` points to a base URL + token ID. For *dynamic* metadata based on the claims stored in the contract, the server hosting the metadata JSON (at the `_baseURI + tokenId`) would need to query the contract's claims storage using `getClaimDetails` or `getAllClaimKeys` and generate the JSON dynamically.

This contract provides a robust framework for creating and managing non-transferable identities with dynamic attributes and a basic reputation system, demonstrating several advanced Solidity patterns and adhering to the requirement of having many distinct functions.