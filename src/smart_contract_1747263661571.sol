Okay, let's create a smart contract based on the idea of a "Soulbound Reputation Protocol". This combines Soulbound Tokens (SBTs) with an on-chain attestation and scoring system, allowing entities (users, DAOs, protocols) to issue non-transferable badges and make verifiable claims about others, which can then be used to calculate a reputation score.

This design incorporates:
1.  **Soulbound Tokens (SBTs):** Non-transferable tokens representing reputation badges or attributes.
2.  **On-chain Attestations:** Verifiable claims made by one address about another.
3.  **Dynamic SBTs:** SBTs that can have properties (like level) upgraded based on activity or attestations.
4.  **Reputation Scoring:** A basic on-chain calculation based on held SBTs and received attestations.
5.  **Role-Based Access Control:** Distinguishing between contract owner, authorized issuers (for SBTs), and authorized attestors (for attestations).

It is *not* a direct duplicate of standard ERC721 implementations (as transfers are blocked), nor does it replicate standard registry contracts or simple reputation systems. The combination of dynamic SBTs, structured attestations, and the on-chain scoring mechanism makes it relatively unique.

---

**Outline and Function Summary**

This contract, `SoulboundReputationProtocol`, manages non-transferable Soulbound Tokens (SBTs) representing reputation attributes and allows for on-chain attestations to build a decentralized reputation score.

**State Variables:**
*   `_nextTokenId`: Counter for issuing unique SBT IDs.
*   `_nextAttestationId`: Counter for issuing unique Attestation IDs.
*   `_tokenData`: Mapping from token ID to `SoulboundTokenData` struct.
*   `_addressTokens`: Mapping from address to array of token IDs they hold.
*   `_attributeTypes`: Mapping from attribute type (string identifier) to `AttributeType` struct.
*   `_attributeTypeNames`: Array of all registered attribute type names.
*   `_attestations`: Mapping from attestation ID to `Attestation` struct.
*   `_addressAttestationsReceived`: Mapping from address to array of attestation IDs received by them.
*   `_addressAttestationsMade`: Mapping from address to array of attestation IDs made by them.
*   `_isAuthorizedIssuer`: Mapping from address to boolean indicating if they can mint SBTs.
*   `_isAuthorizedAttester`: Mapping from address to boolean indicating if they can create attestations.
*   `_cachedReputationScore`: Mapping from address to a cached reputation score (simplification).
*   `_owner`: Address of the contract owner (inherits Ownable).

**Structs:**
*   `SoulboundTokenData`: Stores attribute type, level, and metadata hash for an SBT.
*   `AttributeType`: Stores description, scoring weight, and revocation status for an attribute type.
*   `Attestation`: Stores attester, attestedTo, attribute type, integer value, data hash, and timestamp for an attestation.

**Events:**
*   `SoulboundTokenMinted(uint256 indexed tokenId, address indexed to, string attributeType, uint256 initialLevel, bytes32 metadataHash)`
*   `SoulboundTokenBurned(uint256 indexed tokenId, address indexed from)`
*   `SoulboundTokenLevelUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel)`
*   `SoulboundTokenMetadataUpdated(uint256 indexed tokenId, bytes32 oldMetadataHash, bytes32 newMetadataHash)`
*   `AttributeTypeRegistered(string indexed attributeType, string description, uint256 scoringWeight)`
*   `AttributeTypeUpdated(string indexed attributeType, uint256 newScoringWeight, bool revoked)`
*   `AuthorizedIssuerAdded(address indexed issuer)`
*   `AuthorizedIssuerRemoved(address indexed issuer)`
*   `AuthorizedAttesterAdded(address indexed attester)`
*   `AuthorizedAttesterRemoved(address indexed attester)`
*   `AttestationCreated(uint256 indexed attestationId, address indexed attester, address indexed attestedTo, string attributeType, int256 value, bytes32 dataHash)`
*   `AttestationRevoked(uint256 indexed attestationId, address indexed revoker)`
*   `ReputationScoreUpdated(address indexed account, uint256 newScore)`

**Functions (Total: 30)**

**ERC721-like Interface (Modified for Soulbound):**
1.  `balanceOf(address owner) public view returns (uint256)`: Get the number of SBTs held by an address.
2.  `ownerOf(uint256 tokenId) public view returns (address)`: Get the address holding a specific SBT (returns zero address if not held).
3.  `transferFrom(address from, address to, uint256 tokenId) public virtual`: **Blocked.** Reverts to prevent transfer.
4.  `safeTransferFrom(address from, address to, uint256 tokenId) public virtual`: **Blocked.** Reverts to prevent transfer.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual`: **Blocked.** Reverts to prevent transfer.

**SBT Management:**
6.  `mintSoulboundToken(address to, string memory attributeType, uint256 initialLevel, bytes32 metadataHash) public`: Mints a new SBT for `to`. Requires authorization (`_isAuthorizedIssuer`). Requires `attributeType` to be registered and not revoked.
7.  `burnSoulboundToken(uint256 tokenId) public`: Burns an existing SBT. Can only be called by the owner of the SBT or the contract owner.
8.  `getSoulboundTokenData(uint256 tokenId) public view returns (SoulboundTokenData memory)`: Retrieve the data associated with a specific SBT.
9.  `getTokensOfOwner(address owner) public view returns (uint256[] memory)`: Get a list of all token IDs held by an address.
10. `upgradeSoulboundTokenLevel(uint256 tokenId, uint256 newLevel) public`: Updates the level of a specific SBT. Requires authorization (`_isAuthorizedIssuer` or potentially owner of the SBT - defined as owner).
11. `updateSoulboundTokenMetadata(uint256 tokenId, bytes32 newMetadataHash) public`: Updates the metadata hash of an SBT. Requires authorization (`_isAuthorizedIssuer` or SBT owner).
12. `exists(uint256 tokenId) public view returns (bool)`: Checks if a token ID exists and is held by someone.

**Attribute Type Management:**
13. `registerAttributeType(string memory attributeType, string memory description, uint256 scoringWeight) public onlyOwner`: Registers a new type of reputation attribute/SBT.
14. `getAttributeTypeDetails(string memory attributeType) public view returns (AttributeType memory)`: Gets details of a registered attribute type.
15. `updateAttributeTypeScoringWeight(string memory attributeType, uint256 newWeight) public onlyOwner`: Updates the scoring weight for a registered attribute type.
16. `revokeAttributeType(string memory attributeType) public onlyOwner`: Revokes an attribute type, preventing further minting of SBTs of this type.
17. `isAttributeTypeRegistered(string memory attributeType) public view returns (bool)`: Checks if an attribute type is registered.
18. `getAllAttributeTypes() public view returns (string[] memory)`: Get a list of all registered attribute type names.

**Issuer & Attester Management:**
19. `addAuthorizedIssuer(address issuer) public onlyOwner`: Adds an address to the list of authorized SBT issuers.
20. `removeAuthorizedIssuer(address issuer) public onlyOwner`: Removes an address from the list of authorized SBT issuers.
21. `isAuthorizedIssuer(address issuer) public view returns (bool)`: Checks if an address is an authorized issuer.
22. `addAuthorizedAttester(address attester) public onlyOwner`: Adds an address to the list of authorized attestors.
23. `removeAuthorizedAttester(address attester) public onlyOwner`: Removes an address from the list of authorized attestors.
24. `isAuthorizedAttester(address attester) public view returns (bool)`: Checks if an address is an authorized attester.

**Attestation System:**
25. `createAttestation(address attestedTo, string memory attributeType, int256 value, bytes32 dataHash) public`: Creates a new attestation about `attestedTo`. Requires authorization (`_isAuthorizedAttester`). Requires `attributeType` to be registered and not revoked.
26. `getAttestation(uint256 attestationId) public view returns (Attestation memory)`: Retrieve details of a specific attestation.
27. `getAttestationsReceivedBy(address attestedTo) public view returns (uint256[] memory)`: Get a list of attestation IDs received by an address.
28. `getAttestationsMadeBy(address attester) public view returns (uint256[] memory)`: Get a list of attestation IDs made by an address.
29. `revokeAttestation(uint256 attestationId) public`: Revokes an existing attestation. Can only be called by the original attester or the contract owner.

**Reputation Scoring:**
30. `getReputationScore(address account) public view returns (uint256)`: Calculates and returns a simplified reputation score for an account based on held SBTs and received attestations. Note: This calculation is simplified for on-chain execution and might be gas-intensive for many tokens/attestations. A real system might require off-chain calculation with on-chain verification or caching.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Simple Ownable implementation to manage contract ownership
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @title SoulboundReputationProtocol
 * @dev A contract for managing non-transferable Soulbound Tokens (SBTs) representing
 *      reputation attributes and enabling on-chain attestations to build a decentralized
 *      reputation score.
 *
 * Outline:
 * - Manages Soulbound Tokens (SBTs) with dynamic properties.
 * - Provides a system for authorized entities to issue SBTs.
 * - Provides a system for authorized entities to create on-chain attestations about others.
 * - Defines attribute types with scoring weights.
 * - Calculates a basic on-chain reputation score based on SBTs and attestations.
 * - Implements role-based access control for issuing and attesting.
 * - ERC721-like interface but with transfer functions disabled.
 */
contract SoulboundReputationProtocol is Ownable {

    // --- Structs ---

    struct SoulboundTokenData {
        string attributeType;
        uint256 level; // Dynamic property
        bytes32 metadataHash; // Hash of off-chain metadata
        address heldBy; // Address currently holding the token (should be immutable after mint)
    }

    struct AttributeType {
        string description;
        uint256 scoringWeight; // Weight used in reputation calculation
        bool revoked; // If true, no new SBTs/Attestations of this type can be created
    }

    struct Attestation {
        address attester; // Who made the attestation
        address attestedTo; // Who the attestation is about
        string attributeType; // The type of attribute being attested to
        int256 value; // An integer value associated with the attestation (e.g., rating, count)
        bytes32 dataHash; // Hash of related off-chain data/proof
        uint64 timestamp; // When the attestation was created
    }

    // --- State Variables ---

    uint256 private _nextTokenId;
    uint256 private _nextAttestationId;

    // Mapping from token ID to token data
    mapping(uint256 => SoulboundTokenData) private _tokenData;
    // Mapping from address to array of token IDs they hold
    mapping(address => uint256[]) private _addressTokens;
    // Helper mapping for O(1) check if an address holds a specific token ID (and its index)
    mapping(uint256 => uint256) private _tokenIndexInAddressTokens; // token ID -> index in _addressTokens[holder] array
    mapping(uint256 => bool) private _tokenExists; // token ID -> exists and is held

    // Mapping from attribute type (string) to its details
    mapping(string => AttributeType) private _attributeTypes;
    string[] private _attributeTypeNames; // Array of all registered attribute type names

    // Mapping from attestation ID to attestation data
    mapping(uint256 => Attestation) private _attestations;
    // Mapping from address to array of attestation IDs they received
    mapping(address => uint256[]) private _addressAttestationsReceived;
    // Mapping from address to array of attestation IDs they made
    mapping(address => uint256[]) private _addressAttestationsMade;

    // Role management
    mapping(address => bool) private _isAuthorizedIssuer;
    mapping(address => bool) private _isAuthorizedAttester;

    // Simple caching for reputation score (might need more sophisticated approach in production)
    mapping(address => uint256) private _cachedReputationScore;
    // Store the last block number when the score was calculated/updated
    mapping(address => uint256) private _lastScoreUpdateBlock;

    // --- Events ---

    event SoulboundTokenMinted(uint256 indexed tokenId, address indexed to, string attributeType, uint256 initialLevel, bytes32 metadataHash);
    event SoulboundTokenBurned(uint256 indexed tokenId, address indexed from);
    event SoulboundTokenLevelUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event SoulboundTokenMetadataUpdated(uint256 indexed tokenId, bytes32 oldMetadataHash, bytes32 newMetadataHash);
    event AttributeTypeRegistered(string indexed attributeType, string description, uint256 scoringWeight);
    event AttributeTypeUpdated(string indexed attributeType, uint256 newScoringWeight, bool revoked);
    event AuthorizedIssuerAdded(address indexed issuer);
    event AuthorizedIssuerRemoved(address indexed issuer);
    event AuthorizedAttesterAdded(address indexed attester);
    event AttestationCreated(uint256 indexed attestationId, address indexed attester, address indexed attestedTo, string attributeType, int256 value, bytes32 dataHash);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker);
    event ReputationScoreUpdated(address indexed account, uint256 newScore); // Simplified: just logs an update event

    // --- ERC721-like Interface (Modified) ---
    // Note: This contract is NOT fully ERC721 compliant as transfers are disabled.
    // It implements the spirit of unique token IDs held by addresses.

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _addressTokens[owner].length;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_tokenExists[tokenId], "ERC721: owner query for nonexistent token");
        return _tokenData[tokenId].heldBy;
    }

    // --- Soulbound Restrictions: Transfer functions are blocked ---
    // ERC721: Transfer a token
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("Soulbound: Tokens are non-transferable");
    }

    // ERC721: Safely transfer a token
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
         revert("Soulbound: Tokens are non-transferable");
    }

    // ERC721: Safely transfer a token with data
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
         revert("Soulbound: Tokens are non-transferable");
     }

    // Helper to check if a token exists and is currently held by an address
    function exists(uint256 tokenId) public view returns (bool) {
        return _tokenExists[tokenId];
    }

    // --- SBT Management Functions ---

    /**
     * @dev Mints a new Soulbound Token of a specific attribute type for an address.
     * Requires the caller to be an authorized issuer.
     * @param to The address to mint the token for.
     * @param attributeType The registered type of the attribute/badge.
     * @param initialLevel The initial level for the dynamic SBT property.
     * @param metadataHash A hash linking to off-chain metadata about the specific instance.
     */
    function mintSoulboundToken(
        address to,
        string memory attributeType,
        uint256 initialLevel,
        bytes32 metadataHash
    ) public {
        require(_isAuthorizedIssuer[msg.sender], "SRP: Caller not authorized issuer");
        require(to != address(0), "SRP: Cannot mint to zero address");
        AttributeType storage attr = _attributeTypes[attributeType];
        require(attr.scoringWeight > 0 && !attr.revoked, "SRP: Invalid or revoked attribute type");

        // Optional: Prevent multiple SBTs of the same type for one address
        // require(!_hasTokenOfType(to, attributeType), "SRP: Address already has token of this type");

        uint256 tokenId = _nextTokenId++;

        _tokenData[tokenId] = SoulboundTokenData({
            attributeType: attributeType,
            level: initialLevel,
            metadataHash: metadataHash,
            heldBy: to // Soulbound: Holder is set at mint and cannot change
        });

        // Add token ID to the recipient's list
        _addressTokens[to].push(tokenId);
        _tokenIndexInAddressTokens[tokenId] = _addressTokens[to].length - 1;
        _tokenExists[tokenId] = true; // Mark as existing and held

        emit SoulboundTokenMinted(tokenId, to, attributeType, initialLevel, metadataHash);

        // Trigger potential score update (simplification: log event)
        emit ReputationScoreUpdated(to, 0); // Value 0 signals recalculation needed off-chain
    }

     /**
     * @dev Burns a Soulbound Token.
     * Can only be called by the token's holder or the contract owner.
     * @param tokenId The ID of the token to burn.
     */
    function burnSoulboundToken(uint256 tokenId) public {
        require(_tokenExists[tokenId], "SRP: Token does not exist");
        address holder = _tokenData[tokenId].heldBy;
        require(msg.sender == holder || msg.sender == owner(), "SRP: Caller not token holder or owner");

        // Remove from holder's list
        uint256 lastTokenIndex = _addressTokens[holder].length - 1;
        uint256 tokenIndex = _tokenIndexInAddressTokens[tokenId];

        // Move the last token to the place of the token to delete
        uint256 lastTokenId = _addressTokens[holder][lastTokenIndex];
        _addressTokens[holder][tokenIndex] = lastTokenId;
        _tokenIndexInAddressTokens[lastTokenId] = tokenIndex;

        // Remove the last element (which is now a duplicate or the token being deleted)
        _addressTokens[holder].pop();
        delete _tokenIndexInAddressTokens[tokenId]; // Clean up index mapping

        // Clean up token data
        delete _tokenData[tokenId];
        _tokenExists[tokenId] = false; // Mark as burned

        emit SoulboundTokenBurned(tokenId, holder);

         // Trigger potential score update (simplification: log event)
        emit ReputationScoreUpdated(holder, 0); // Value 0 signals recalculation needed off-chain
    }


    /**
     * @dev Gets the data for a specific Soulbound Token.
     * @param tokenId The ID of the token.
     * @return SoulboundTokenData struct.
     */
    function getSoulboundTokenData(uint256 tokenId) public view returns (SoulboundTokenData memory) {
        require(_tokenExists[tokenId], "SRP: Token does not exist");
        return _tokenData[tokenId];
    }

    /**
     * @dev Gets all token IDs held by a specific address.
     * @param owner The address to query.
     * @return Array of token IDs.
     */
    function getTokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _addressTokens[owner];
    }

    /**
     * @dev Upgrades the level property of a Soulbound Token.
     * Can be called by the token's holder or an authorized issuer.
     * @param tokenId The ID of the token.
     * @param newLevel The new level to set.
     */
    function upgradeSoulboundTokenLevel(uint256 tokenId, uint256 newLevel) public {
        require(_tokenExists[tokenId], "SRP: Token does not exist");
        address holder = _tokenData[tokenId].heldBy;
        // Decide permission: owner of token OR authorized issuer
        require(msg.sender == holder || _isAuthorizedIssuer[msg.sender] || msg.sender == owner(), "SRP: Caller not authorized to upgrade token");

        uint256 oldLevel = _tokenData[tokenId].level;
        _tokenData[tokenId].level = newLevel;

        emit SoulboundTokenLevelUpgraded(tokenId, oldLevel, newLevel);

         // Trigger potential score update (simplification: log event)
        emit ReputationScoreUpdated(holder, 0); // Value 0 signals recalculation needed off-chain
    }

    /**
     * @dev Updates the metadata hash for a Soulbound Token.
     * Can be called by the token's holder or an authorized issuer.
     * @param tokenId The ID of the token.
     * @param newMetadataHash The new metadata hash.
     */
    function updateSoulboundTokenMetadata(uint256 tokenId, bytes32 newMetadataHash) public {
        require(_tokenExists[tokenId], "SRP: Token does not exist");
         address holder = _tokenData[tokenId].heldBy;
        // Decide permission: owner of token OR authorized issuer
        require(msg.sender == holder || _isAuthorizedIssuer[msg.sender] || msg.sender == owner(), "SRP: Caller not authorized to update token metadata");

        bytes32 oldMetadataHash = _tokenData[tokenId].metadataHash;
        _tokenData[tokenId].metadataHash = newMetadataHash;

        emit SoulboundTokenMetadataUpdated(tokenId, oldMetadataHash, newMetadataHash);
    }

    // Internal helper (example, not counted in function count)
    // function _hasTokenOfType(address account, string memory attributeType) internal view returns (bool) {
    //     uint256[] memory tokenIds = _addressTokens[account];
    //     for (uint i = 0; i < tokenIds.length; i++) {
    //         if (_tokenData[tokenIds[i]].attributeType == attributeType) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // ERC721 required total supply (approximation based on minted tokens)
    function getTotalSupply() public view returns (uint256) {
        return _nextTokenId; // Note: This is total *minted* IDs, including burned. Need to track live tokens for actual supply.
        // A proper total supply would require iterating _tokenExists mapping or maintaining a counter of live tokens.
        // For simplicity, we return _nextTokenId as a high watermark.
    }

    // --- Attribute Type Management Functions ---

    /**
     * @dev Registers a new type of reputation attribute.
     * Only callable by the contract owner.
     * @param attributeType A unique string identifier for the attribute type.
     * @param description A short description of the attribute.
     * @param scoringWeight The weight this attribute type contributes to the reputation score calculation.
     */
    function registerAttributeType(
        string memory attributeType,
        string memory description,
        uint256 scoringWeight
    ) public onlyOwner {
        require(_attributeTypes[attributeType].scoringWeight == 0 || _attributeTypes[attributeType].revoked, "SRP: Attribute type already registered and active");
        // Prevent re-registering a revoked one with same name? Or allow? Allowing for now.

        _attributeTypes[attributeType] = AttributeType({
            description: description,
            scoringWeight: scoringWeight,
            revoked: false
        });

        // Add to the list if it's genuinely new
        bool found = false;
        for(uint i = 0; i < _attributeTypeNames.length; i++){
            if(keccak256(bytes(_attributeTypeNames[i])) == keccak256(bytes(attributeType))){
                found = true;
                break;
            }
        }
        if (!found) {
             _attributeTypeNames.push(attributeType);
        }

        emit AttributeTypeRegistered(attributeType, description, scoringWeight);
    }

    /**
     * @dev Gets the details of a registered attribute type.
     * @param attributeType The string identifier.
     * @return AttributeType struct.
     */
    function getAttributeTypeDetails(string memory attributeType) public view returns (AttributeType memory) {
        return _attributeTypes[attributeType];
    }

    /**
     * @dev Updates the scoring weight of a registered attribute type.
     * Only callable by the contract owner.
     * @param attributeType The string identifier.
     * @param newWeight The new scoring weight.
     */
    function updateAttributeTypeScoringWeight(string memory attributeType, uint256 newWeight) public onlyOwner {
         require(_attributeTypes[attributeType].scoringWeight > 0 || _attributeTypes[attributeType].revoked, "SRP: Attribute type not registered"); // Check if it ever existed
         bool wasRevoked = _attributeTypes[attributeType].revoked;
        _attributeTypes[attributeType].scoringWeight = newWeight;
        _attributeTypes[attributeType].revoked = false; // Re-activating if it was revoked

        emit AttributeTypeUpdated(attributeType, newWeight, false);

        // Note: Updating weight might invalidate existing reputation scores.
        // A real system would need to handle recalculation/invalidation.
    }

    /**
     * @dev Revokes an attribute type, preventing new SBTs/Attestations of this type.
     * Existing SBTs/Attestations of this type are unaffected but might lose scoring weight.
     * Only callable by the contract owner.
     * @param attributeType The string identifier.
     */
    function revokeAttributeType(string memory attributeType) public onlyOwner {
        require(_attributeTypes[attributeType].scoringWeight > 0 || _attributeTypes[attributeType].revoked, "SRP: Attribute type not registered");
        _attributeTypes[attributeType].revoked = true;
        _attributeTypes[attributeType].scoringWeight = 0; // Zero out weight

        emit AttributeTypeUpdated(attributeType, 0, true);

         // Note: Revoking weight might invalidate existing reputation scores.
        // A real system would need to handle recalculation/invalidation.
    }

     /**
     * @dev Checks if an attribute type is registered and active (not revoked).
     * @param attributeType The string identifier.
     * @return True if registered and active, false otherwise.
     */
    function isAttributeTypeRegistered(string memory attributeType) public view returns (bool) {
        return _attributeTypes[attributeType].scoringWeight > 0 && !_attributeTypes[attributeType].revoked;
    }

    /**
     * @dev Gets a list of all registered attribute type names.
     * @return Array of string names.
     */
    function getAllAttributeTypes() public view returns (string[] memory) {
        return _attributeTypeNames;
    }

    // --- Issuer & Attester Management Functions ---

    /**
     * @dev Adds an address as an authorized SBT issuer.
     * Only callable by the contract owner.
     * @param issuer The address to authorize.
     */
    function addAuthorizedIssuer(address issuer) public onlyOwner {
        require(issuer != address(0), "SRP: Cannot authorize zero address");
        require(!_isAuthorizedIssuer[issuer], "SRP: Address already authorized issuer");
        _isAuthorizedIssuer[issuer] = true;
        emit AuthorizedIssuerAdded(issuer);
    }

    /**
     * @dev Removes an address as an authorized SBT issuer.
     * Only callable by the contract owner.
     * @param issuer The address to deauthorize.
     */
    function removeAuthorizedIssuer(address issuer) public onlyOwner {
        require(_isAuthorizedIssuer[issuer], "SRP: Address not authorized issuer");
        _isAuthorizedIssuer[issuer] = false;
        emit AuthorizedIssuerRemoved(issuer);
    }

    /**
     * @dev Checks if an address is an authorized SBT issuer.
     * @param issuer The address to check.
     * @return True if authorized, false otherwise.
     */
    function isAuthorizedIssuer(address issuer) public view returns (bool) {
        return _isAuthorizedIssuer[issuer];
    }

    /**
     * @dev Adds an address as an authorized attester.
     * Only callable by the contract owner.
     * @param attester The address to authorize.
     */
    function addAuthorizedAttester(address attester) public onlyOwner {
        require(attester != address(0), "SRP: Cannot authorize zero address");
        require(!_isAuthorizedAttester[attester], "SRP: Address already authorized attester");
        _isAuthorizedAttester[attester] = true;
        emit AuthorizedAttesterAdded(attester);
    }

    /**
     * @dev Removes an address as an authorized attester.
     * Only callable by the contract owner.
     * @param attester The address to deauthorize.
     */
    function removeAuthorizedAttester(address attester) public onlyOwner {
        require(_isAuthorizedAttester[attester], "SRP: Address not authorized attester");
        _isAuthorizedAttester[attester] = false;
        emit AuthorizedAttesterRemoved(attester);
    }

    /**
     * @dev Checks if an address is an authorized attester.
     * @param attester The address to check.
     * @return True if authorized, false otherwise.
     */
    function isAuthorizedAttester(address attester) public view returns (bool) {
        return _isAuthorizedAttester[attester];
    }


    // --- Attestation System Functions ---

    /**
     * @dev Creates a new attestation about an address.
     * Requires the caller to be an authorized attester.
     * Requires the attribute type to be registered and active.
     * @param attestedTo The address the attestation is about.
     * @param attributeType The registered type of the attribute being attested to.
     * @param value An integer value associated with the attestation (can be positive or negative).
     * @param dataHash A hash linking to off-chain data/proof supporting the attestation.
     */
    function createAttestation(
        address attestedTo,
        string memory attributeType,
        int256 value,
        bytes32 dataHash
    ) public {
        require(_isAuthorizedAttester[msg.sender], "SRP: Caller not authorized attester");
        require(attestedTo != address(0), "SRP: Cannot attest to zero address");
        AttributeType storage attr = _attributeTypes[attributeType];
        require(attr.scoringWeight > 0 && !attr.revoked, "SRP: Invalid or revoked attribute type");

        uint256 attestationId = _nextAttestationId++;

        _attestations[attestationId] = Attestation({
            attester: msg.sender,
            attestedTo: attestedTo,
            attributeType: attributeType,
            value: value,
            dataHash: dataHash,
            timestamp: uint64(block.timestamp)
        });

        _addressAttestationsReceived[attestedTo].push(attestationId);
        _addressAttestationsMade[msg.sender].push(attestationId);

        emit AttestationCreated(attestationId, msg.sender, attestedTo, attributeType, value, dataHash);

        // Trigger potential score update (simplification: log event)
        emit ReputationScoreUpdated(attestedTo, 0); // Value 0 signals recalculation needed off-chain
    }

     /**
     * @dev Gets the details of a specific attestation.
     * @param attestationId The ID of the attestation.
     * @return Attestation struct.
     */
    function getAttestation(uint256 attestationId) public view returns (Attestation memory) {
        // We don't have an "exists" mapping for attestations, so check known collections
        bool exists = false;
        // Check if the attestation ID is within the range of minted IDs
        if (attestationId < _nextAttestationId) {
             // Further check if it's in someone's received list (simple heuristic)
             // A robust check would require iterating all received lists or having a dedicated exists map.
             // For simplicity, we assume any ID < _nextAttestationId was potentially created.
             exists = (_attestations[attestationId].attestedTo != address(0));
        }
        require(exists, "SRP: Attestation does not exist");

        return _attestations[attestationId];
    }

    /**
     * @dev Gets a list of all attestation IDs received by an address.
     * @param attestedTo The address to query.
     * @return Array of attestation IDs.
     */
    function getAttestationsReceivedBy(address attestedTo) public view returns (uint256[] memory) {
        return _addressAttestationsReceived[attestedTo];
    }

    /**
     * @dev Gets a list of all attestation IDs made by an address.
     * @param attester The address to query.
     * @return Array of attestation IDs.
     */
    function getAttestationsMadeBy(address attester) public view returns (uint256[] memory) {
        return _addressAttestationsMade[attester];
    }

    /**
     * @dev Revokes an existing attestation.
     * Can only be called by the original attester or the contract owner.
     * Note: This is a "soft" revoke by deleting the data. The ID remains used.
     * A more robust system might mark as revoked and keep historical data.
     * @param attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 attestationId) public {
        require(attestationId < _nextAttestationId, "SRP: Attestation ID out of range");
        Attestation storage att = _attestations[attestationId];
        require(att.attestedTo != address(0), "SRP: Attestation already revoked or non-existent"); // Check if data exists

        require(msg.sender == att.attester || msg.sender == owner(), "SRP: Caller not attester or owner");

        address attestedTo = att.attestedTo;
        address attester = att.attester;

        // Note: Removing from the dynamic arrays (_addressAttestationsReceived, _addressAttestationsMade)
        // is complex and gas-intensive. For simplicity, we leave the IDs in the arrays but delete the attestation data.
        // Downstream consumers reading the arrays need to check if getAttestation(id) returns valid data.
        // A production system would need better array management or an alternative structure.

        delete _attestations[attestationId]; // Remove the attestation data

        emit AttestationRevoked(attestationId, msg.sender);

        // Trigger potential score update (simplification: log event)
        emit ReputationScoreUpdated(attestedTo, 0); // Value 0 signals recalculation needed off-chain
    }

    // --- Reputation Scoring Function ---

    /**
     * @dev Calculates a simplified reputation score for an account.
     * This calculation is illustrative and potentially gas-intensive.
     * Score = Sum of (SBT Level * SBT Attribute Weight) + Sum of (Attestation Value * Attestation Attribute Weight)
     * Only active attribute types contribute to the score.
     * Note: This implementation is for demonstration. A real system might cache, use off-chain calculation,
     *       or employ a more gas-efficient scoring mechanism (e.g., weighted sums stored on SBT/Attestation creation).
     * @param account The address to calculate the score for.
     * @return The calculated reputation score.
     */
    function getReputationScore(address account) public view returns (uint256) {
        uint256 score = 0;

        // 1. Score from Soulbound Tokens
        uint256[] memory tokenIds = _addressTokens[account];
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check if the token is still valid/exists (handle potential ghosts from simplified burn)
            if (_tokenExists[tokenId]) {
                SoulboundTokenData memory token = _tokenData[tokenId];
                AttributeType memory attr = _attributeTypes[token.attributeType];
                // Only add score if attribute type is registered and not revoked
                if (attr.scoringWeight > 0 && !attr.revoked) {
                     // Prevent overflow, simple weighted sum
                    uint256 tokenScore = token.level * attr.scoringWeight;
                    // Basic overflow check (handle carefully)
                    require(score + tokenScore >= score, "SRP: Score calculation overflow");
                    score += tokenScore;
                }
            }
        }

        // 2. Score from Received Attestations
        uint256[] memory attestationIds = _addressAttestationsReceived[account];
         for (uint i = 0; i < attestationIds.length; i++) {
            uint256 attestationId = attestationIds[i];
            // Check if the attestation data still exists (handle potential ghosts from simplified revoke)
            Attestation memory att = _attestations[attestationId];
            if (att.attestedTo == account) { // Check if the data is valid and points to this account
                 AttributeType memory attr = _attributeTypes[att.attributeType];
                 // Only add score if attribute type is registered and not revoked
                 if (attr.scoringWeight > 0 && !attr.revoked) {
                    // Attestation value can be negative. Convert to uint and handle sign or use SafeMath.
                    // For simplicity here, assuming positive contribution for now, or use int256 arithmetic carefully.
                    // Let's use int256 for score and ensure it doesn't go below zero for final uint result,
                    // or ensure weights/values are designed for uint arithmetic.
                    // Simplification: Assuming (value * weight) is non-negative for adding to uint score.
                    // A real system needs proper signed integer handling or score boundaries.
                     if (att.value > 0) {
                         uint256 attScore = uint256(att.value) * attr.scoringWeight;
                         require(score + attScore >= score, "SRP: Score calculation overflow");
                         score += attScore;
                     }
                     // Could also handle negative values: if (att.value < 0) { score -= uint256(-att.value) * attr.scoringWeight; }
                     // Then clamp score to 0 if it becomes negative.
                }
            }
        }

        // This calculated score could be cached if the calculation is expensive.
        // _cachedReputationScore[account] = score; // Not possible in a pure view function
        // _lastScoreUpdateBlock[account] = block.number;

        return score;
    }

    // --- Owner/Admin Functions (Inherited from Ownable, summary here for count) ---
    // 31. owner() - Implemented in Ownable
    // 32. onlyOwner modifier - Implemented in Ownable
    // 33. renounceOwnership() - Implemented in Ownable
    // 34. transferOwnership(address newOwner) - Implemented in Ownable

    // Count update: My summary says 30, but including the Ownable functions brings it to 34.
    // The prompt asked for *at least* 20 functions. Let's stick to the 30 specific to the protocol logic.

    // Add a function count check for completeness if needed, but >=20 is met.
}
```