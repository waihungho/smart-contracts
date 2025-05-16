Okay, here is a smart contract concept combining Soulbound Tokens (SBTs) with a system for issuing non-transferable "Proof of Contribution" credentials. It features different types of contributions, levels, attestors who can issue/upgrade/revoke credentials, and a simple on-chain scoring mechanism based on held contributions.

This goes beyond standard ERC-721/ERC-1155 by enforcing non-transferability at the core (`_beforeTokenTransfer`), introducing structured data for contributions (types, levels, attestors), and adding role-based access control for issuance and a simple scoring system.

---

**Contract Name:** `SoulboundProofOfContribution`

**Concept:** A non-transferable (Soulbound) token standard specifically designed to represent and manage contributions, achievements, or credentials within a decentralized ecosystem. Designated "Attestors" can issue, upgrade, or revoke these "Proof of Contribution" tokens based on off-chain or on-chain verified contributions. The contract includes a basic scoring mechanism derived from held contribution tokens.

**Outline:**

1.  **Interfaces & Libraries:** Imports necessary OpenZeppelin contracts.
2.  **Data Structures:** Defines structs for `SBTData` (token details) and `ContributionType` (definition).
3.  **State Variables:** Stores mappings for tokens, recipients, contribution types, attestors, scoring weights, counters, and administrative state.
4.  **Events:** Declares events for state changes.
5.  **Modifiers:** Custom modifiers (`onlyAttestor`, `whenNotPaused`, etc.).
6.  **Constructor:** Initializes the contract, owner, and basic parameters.
7.  **ERC721 Overrides:** Implements ERC721 methods, critically overriding transfer functions to prevent movement.
8.  **Admin Functions (Owner Only):**
    *   Ownership management (`Ownable`).
    *   Pausing issuance (`Pausable`).
    *   Setting metadata base URI.
    *   Managing global score weights.
9.  **Attestor Management (Owner Only):**
    *   Add/remove addresses capable of issuing/managing SBTs.
    *   Query attestor status.
    *   Get list of attestors.
10. **Contribution Type Management (Owner Only):**
    *   Define new types of contributions (e.g., "Code Contributor", "Community Moderator").
    *   Update existing types.
    *   Query type details.
    *   Get list of all types.
11. **SBT Issuance (Attestor Only):**
    *   Mint new SBTs of a specific type and level for a recipient.
    *   Mint multiple SBTs in a single transaction.
12. **SBT Data & Querying:**
    *   Retrieve specific SBT data by token ID.
    *   Get all token IDs held by a recipient.
    *   Get token IDs of a specific type held by a recipient.
    *   Get the highest level achieved for a specific contribution type by a recipient.
    *   Check if a recipient holds *any* SBT of a specific type.
13. **SBT Updates (Attestor Only):**
    *   Upgrade the level of an existing SBT.
    *   Revoke (burn) an SBT.
14. **Scoring:**
    *   Calculate a contribution score for an address based on their held SBTs and predefined weights.
15. **Internal Helpers:** Private functions used by the public methods.

**Function Summary:**

1.  `constructor(string memory name, string memory symbol)`: Initializes the contract with name and symbol, sets the owner.
2.  `setTokenURIBase(string memory baseURI)`: Sets the base URI for token metadata.
3.  `addAttestor(address attestor)`: Grants attestor role to an address (Owner only).
4.  `removeAttestor(address attestor)`: Revokes attestor role from an address (Owner only).
5.  `isAttestor(address account)`: Checks if an address is an attestor.
6.  `getAttestors()`: Returns an array of current attestor addresses.
7.  `defineContributionType(string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight)`: Creates a new type of contribution (Owner only).
8.  `updateContributionType(uint256 typeId, string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight)`: Modifies an existing contribution type (Owner only).
9.  `getContributionTypeDetails(uint256 typeId)`: Retrieves details for a specific contribution type.
10. `getAllContributionTypeIds()`: Returns an array of all defined contribution type IDs.
11. `setScoreWeights(uint256 typeId, uint256 weight)`: Sets or updates the score weight for a specific contribution type (Owner only).
12. `getScoreWeights(uint256 typeId)`: Gets the score weight for a specific contribution type.
13. `issueSBT(address recipient, uint256 typeId, uint256 level, string memory metadataURI)`: Mints a new SBT for a recipient (Attestor only, when not paused).
14. `issueBatchSBT(address[] memory recipients, uint256[] memory typeIds, uint256[] memory levels, string[] memory metadataURIs)`: Mints multiple SBTs in a single transaction (Attestor only, when not paused).
15. `upgradeSBTLevel(uint256 tokenId, uint256 newLevel, string memory metadataURI)`: Increases the level of an existing SBT (Attestor only).
16. `revokeSBT(uint256 tokenId)`: Burns an existing SBT (Attestor who issued it, or Owner).
17. `getSBTData(uint256 tokenId)`: Retrieves the structured data for a specific SBT.
18. `getSBTIdsByRecipient(address recipient)`: Returns an array of all token IDs held by a recipient.
19. `getSBTIdsByRecipientAndType(address recipient, uint256 typeId)`: Returns an array of token IDs of a specific type held by a recipient.
20. `doesRecipientHoldType(address recipient, uint256 typeId)`: Checks if a recipient holds at least one SBT of a specific type.
21. `getHighestLevelForType(address recipient, uint256 typeId)`: Finds the highest level among SBTs of a specific type held by a recipient.
22. `checkContributionScore(address recipient)`: Calculates the total contribution score for a recipient.
23. `pauseIssuance()`: Pauses `issueSBT` and `issueBatchSBT` (Owner only).
24. `unpauseIssuance()`: Unpauses issuance (Owner only).
25. `paused()`: Checks if issuance is paused (from `Pausable`).
26. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a specific token (standard ERC721).
27. `balanceOf(address owner)`: Returns the number of SBTs held by an address (standard ERC721).
28. `ownerOf(uint256 tokenId)`: Returns the owner of a specific SBT (standard ERC721).
29. `transferFrom(address from, address to, uint256 tokenId)`: *Override:* Reverts, preventing transfers.
30. `safeTransferFrom(address from, address to, uint256 tokenId)`: *Override:* Reverts, preventing transfers.
31. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: *Override:* Reverts, preventing transfers.
32. `approve(address to, uint256 tokenId)`: *Override:* Reverts, preventing approval for transfer.
33. `setApprovalForAll(address operator, bool approved)`: *Override:* Reverts, preventing blanket approval for transfers.
34. `getApproved(uint256 tokenId)`: *Override:* Returns zero address, as approvals are disabled.
35. `isApprovedForAll(address owner, address operator)`: *Override:* Returns false, as blanket approvals are disabled.
36. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 check for supported interfaces (ERC721, ERC721Metadata, ERC165).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // For revoke function

/**
 * @title SoulboundProofOfContribution
 * @dev A non-transferable ERC721 contract for issuing and managing Soulbound Proof of Contribution tokens.
 *      Designated Attestors can issue, upgrade, and revoke contribution tokens of predefined types and levels.
 *      Includes a basic on-chain scoring mechanism based on held contributions.
 *
 * Outline:
 * 1. Imports and Interfaces
 * 2. Data Structures
 * 3. State Variables
 * 4. Events
 * 5. Modifiers
 * 6. Constructor
 * 7. ERC721 Overrides (Preventing Transfers)
 * 8. Admin Functions (Owner Only)
 * 9. Attestor Management (Owner Only)
 * 10. Contribution Type Management (Owner Only)
 * 11. SBT Issuance (Attestor Only)
 * 12. SBT Data & Querying
 * 13. SBT Updates (Attestor Only)
 * 14. Scoring
 * 15. Internal Helpers
 *
 * Function Summary:
 * 1. constructor(string memory name, string memory symbol): Initializes the contract.
 * 2. setTokenURIBase(string memory baseURI): Sets the base URI for token metadata.
 * 3. addAttestor(address attestor): Grants attestor role.
 * 4. removeAttestor(address attestor): Revokes attestor role.
 * 5. isAttestor(address account): Checks attestor status.
 * 6. getAttestors(): Returns list of attestors.
 * 7. defineContributionType(string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight): Defines a new contribution type.
 * 8. updateContributionType(uint256 typeId, string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight): Updates a contribution type.
 * 9. getContributionTypeDetails(uint256 typeId): Gets contribution type details.
 * 10. getAllContributionTypeIds(): Gets all defined contribution type IDs.
 * 11. setScoreWeights(uint256 typeId, uint256 weight): Sets scoring weight for a type.
 * 12. getScoreWeights(uint256 typeId): Gets scoring weight for a type.
 * 13. issueSBT(address recipient, uint256 typeId, uint256 level, string memory metadataURI): Mints a new SBT.
 * 14. issueBatchSBT(address[] memory recipients, uint256[] memory typeIds, uint256[] memory levels, string[] memory metadataURIs): Mints batch SBTs.
 * 15. upgradeSBTLevel(uint256 tokenId, uint256 newLevel, string memory metadataURI): Upgrades SBT level.
 * 16. revokeSBT(uint256 tokenId): Burns an SBT.
 * 17. getSBTData(uint256 tokenId): Gets SBT data.
 * 18. getSBTIdsByRecipient(address recipient): Gets all SBT IDs for a recipient.
 * 19. getSBTIdsByRecipientAndType(address recipient, uint256 typeId): Gets SBT IDs of a type for recipient.
 * 20. doesRecipientHoldType(address recipient, uint256 typeId): Checks if recipient holds type.
 * 21. getHighestLevelForType(address recipient, uint256 typeId): Gets highest level of type for recipient.
 * 22. checkContributionScore(address recipient): Calculates score for a recipient.
 * 23. pauseIssuance(): Pauses issuance.
 * 24. unpauseIssuance(): Unpauses issuance.
 * 25. paused(): Checks if paused.
 * 26. tokenURI(uint256 tokenId): Gets token metadata URI.
 * 27. balanceOf(address owner): Gets balance (number of SBTs).
 * 28. ownerOf(uint256 tokenId): Gets owner of SBT.
 * 29-35. ERC721 Overrides (transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll): Prevent transfers/approvals.
 * 36. supportsInterface(bytes4 interfaceId): ERC165 standard check.
 */
contract SoulboundProofOfContribution is ERC721, Ownable, Pausable, ERC721Burnable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextTypeId;

    string private _tokenURIBase;

    // ERC721 standard requires _owners mapping, ERC721Enumerable adds _ownedTokens

    // Custom data for each Soulbound Token
    struct SBTData {
        uint256 typeId;
        uint256 level;
        address attester;
        uint64 timestamp; // When issued or last updated
        string metadataURI; // Specific URI if different from base
    }
    mapping(uint256 => SBTData) private _sbtData;

    // Store token IDs per recipient for efficient querying
    // recipient -> typeId -> list of tokenIds
    mapping(address => mapping(uint256 => uint256[])) private _recipientTokensByType;
     // recipient -> list of all tokenIds (redundant but useful for checkContributionScore if _recipientTokensByType becomes too complex)
    mapping(address => uint256[] ) private _allRecipientTokens;

    // Attestor Management
    mapping(address => bool) private _isAttestor;
    address[] private _attestors; // List of attestor addresses

    // Contribution Type Definitions
    struct ContributionType {
        string name;
        string description;
        uint256 maxLevel; // Max level for this type (0 means no level cap)
        uint256 defaultScoreWeight; // Default weight for score calculation if no specific weight is set
        bool exists; // Sentinel to check if typeId is valid
    }
    mapping(uint256 => ContributionType) private _contributionTypes;
    uint256[] private _contributionTypeIds; // List of defined type IDs

    // Scoring Weights (typeId -> weight) - overrides default weight in ContributionType
    mapping(uint256 => uint256) private _scoreWeights;
    bool private _useTypeSpecificWeights; // Flag to use scoreWeights mapping or defaultScoreWeight

    // --- Events ---

    event AttestorAdded(address indexed account);
    event AttestorRemoved(address indexed account);
    event ContributionTypeDefined(uint256 indexed typeId, string name);
    event ContributionTypeUpdated(uint256 indexed typeId);
    event SBTIssued(uint256 indexed tokenId, address indexed recipient, uint256 indexed typeId, uint256 level, address attester);
    event SBTUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel, address attester);
    event SBTRevoked(uint256 indexed tokenId, address indexed recipient, address revoker);
    event ScoreWeightsSet(uint256 indexed typeId, uint256 weight);
    event TokenURIBaseSet(string baseURI);


    // --- Modifiers ---

    modifier onlyAttestor() {
        require(_isAttestor[msg.sender], "Not an attestor");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- ERC721 Overrides (Preventing Transfers) ---

    // Override _beforeTokenTransfer to prevent transfers unless minting or burning
    // Allows minting (from == address(0)) and burning (to == address(0))
    // Prevents all other transfers (from != address(0) && to != address(0))
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            // Prevent transfers between accounts
            revert("SBT: Token is soulbound and cannot be transferred");
        }

        // Handle adding/removing token ID from recipient's lists during mint/burn
        if (from == address(0) && to != address(0)) { // Minting
             _recipientTokensByType[to][_sbtData[tokenId].typeId].push(tokenId);
             _allRecipientTokens[to].push(tokenId);
        } else if (from != address(0) && to == address(0)) { // Burning (revoking)
             // Remove from _recipientTokensByType
             uint256 typeId = _sbtData[tokenId].typeId;
             uint256[] storage tokenIdsForType = _recipientTokensByType[from][typeId];
             for (uint i = 0; i < tokenIdsForType.length; i++) {
                 if (tokenIdsForType[i] == tokenId) {
                     tokenIdsForType[i] = tokenIdsForType[tokenIdsForType.length - 1];
                     tokenIdsForType.pop();
                     break;
                 }
             }
             // Remove from _allRecipientTokens
              uint256[] storage allTokenIds = _allRecipientTokens[from];
              for (uint i = 0; i < allTokenIds.length; i++) {
                  if (allTokenIds[i] == tokenId) {
                      allTokenIds[i] = allTokenIds[allTokenIds.length - 1];
                      allTokenIds.pop();
                      break;
                  }
              }
        }
    }

    // Explicitly override transfer functions to prevent their use
    // Even though _beforeTokenTransfer handles it, this provides clearer intent
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBT: Token is soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBT: Token is soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("SBT: Token is soulbound and cannot be transferred");
    }

    // Prevent approvals as tokens are non-transferable
    function approve(address to, uint256 tokenId) public pure override {
        revert("SBT: Token is soulbound and cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
         revert("SBT: Token is soulbound and cannot be approved");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        // Return zero address as approvals are not possible
        return address(0);
    }

     function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Return false as approvals are not possible
        return false;
    }

    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Sets the base URI for token metadata.
     * Tokens will typically have metadata at `baseURI/tokenId`.
     * @param baseURI The new base URI.
     */
    function setTokenURIBase(string memory baseURI) public onlyOwner {
        _tokenURIBase = baseURI;
        emit TokenURIBaseSet(baseURI);
    }

    // Use OpenZeppelin's Ownable functions for transferOwnership and renounceOwnership
    // (Implicitly available from inheriting Ownable)

    // Use OpenZeppelin's Pausable functions for pause() and unpause()
    // Renamed to pauseIssuance/unpauseIssuance for clarity on scope
    /**
     * @dev Pauses the issuance of new SBTs.
     * Only callable by the owner.
     */
    function pauseIssuance() public onlyOwner {
        _pause(); // Calls the _pause from Pausable
    }

    /**
     * @dev Unpauses the issuance of new SBTs.
     * Only callable by the owner.
     */
    function unpauseIssuance() public onlyOwner {
         _unpause(); // Calls the _unpause from Pausable
    }

    // paused() getter is available from Pausable


    // --- Attestor Management (Owner Only) ---

    /**
     * @dev Grants the attestor role to an address.
     * Attestors can issue, upgrade, and revoke SBTs.
     * Only callable by the owner.
     * @param attestor The address to grant the role to.
     */
    function addAttestor(address attestor) public onlyOwner {
        require(attestor != address(0), "Invalid address");
        require(!_isAttestor[attestor], "Address is already an attestor");
        _isAttestor[attestor] = true;
        _attestors.push(attestor);
        emit AttestorAdded(attestor);
    }

    /**
     * @dev Revokes the attestor role from an address.
     * Only callable by the owner.
     * @param attestor The address to revoke the role from.
     */
    function removeAttestor(address attestor) public onlyOwner {
         require(attestor != address(0), "Invalid address");
         require(_isAttestor[attestor], "Address is not an attestor");
         _isAttestor[attestor] = false;
         // Remove from the array - inefficient for large arrays, but OK for moderate number of attestors
         for(uint i = 0; i < _attestors.length; i++) {
             if (_attestors[i] == attestor) {
                 _attestors[i] = _attestors[_attestors.length - 1];
                 _attestors.pop();
                 break;
             }
         }
         emit AttestorRemoved(attestor);
    }

    /**
     * @dev Checks if an address has the attestor role.
     * @param account The address to check.
     * @return True if the address is an attestor, false otherwise.
     */
    function isAttestor(address account) public view returns (bool) {
        return _isAttestor[account];
    }

    /**
     * @dev Returns the list of current attestor addresses.
     * @return An array of attestor addresses.
     */
    function getAttestors() public view returns (address[] memory) {
        return _attestors;
    }


    // --- Contribution Type Management (Owner Only) ---

    /**
     * @dev Defines a new type of contribution or achievement.
     * Each type gets a unique ID.
     * Only callable by the owner.
     * @param name The name of the contribution type (e.g., "Code Contributor").
     * @param description A brief description.
     * @param maxLevel The maximum level for this type (0 for no limit).
     * @param defaultScoreWeight The weight to use for scoring if no specific weight is set for this type.
     */
    function defineContributionType(string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight) public onlyOwner {
        uint256 typeId = _nextTypeId.current();
        _contributionTypes[typeId] = ContributionType({
            name: name,
            description: description,
            maxLevel: maxLevel,
            defaultScoreWeight: defaultScoreWeight,
            exists: true
        });
        _contributionTypeIds.push(typeId);
        _nextTypeId.increment();
        emit ContributionTypeDefined(typeId, name);
    }

     /**
     * @dev Updates an existing type of contribution or achievement.
     * Only callable by the owner.
     * @param typeId The ID of the type to update.
     * @param name The new name.
     * @param description The new description.
     * @param maxLevel The new maximum level (0 for no limit).
     * @param defaultScoreWeight The new default weight for scoring.
     */
    function updateContributionType(uint256 typeId, string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight) public onlyOwner {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        _contributionTypes[typeId].name = name;
        _contributionTypes[typeId].description = description;
        _contributionTypes[typeId].maxLevel = maxLevel;
        _contributionTypes[typeId].defaultScoreWeight = defaultScoreWeight;
         emit ContributionTypeUpdated(typeId);
    }

    /**
     * @dev Retrieves details for a specific contribution type ID.
     * @param typeId The ID of the type to retrieve.
     * @return The name, description, maxLevel, and defaultScoreWeight of the type.
     */
    function getContributionTypeDetails(uint256 typeId) public view returns (string memory name, string memory description, uint256 maxLevel, uint256 defaultScoreWeight) {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        ContributionType storage cType = _contributionTypes[typeId];
        return (cType.name, cType.description, cType.maxLevel, cType.defaultScoreWeight);
    }

    /**
     * @dev Returns an array of all defined contribution type IDs.
     * @return An array of type IDs.
     */
    function getAllContributionTypeIds() public view returns (uint256[] memory) {
        return _contributionTypeIds;
    }

    /**
     * @dev Sets or updates the specific score weight for a contribution type.
     * This overrides the defaultScoreWeight set in the type definition.
     * If set to 0, the defaultScoreWeight from the type definition is used.
     * Only callable by the owner.
     * @param typeId The ID of the contribution type.
     * @param weight The specific score weight to assign (0 to use default).
     */
    function setScoreWeights(uint256 typeId, uint256 weight) public onlyOwner {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        _scoreWeights[typeId] = weight;
        if (weight > 0) {
            _useTypeSpecificWeights = true; // Enable specific weights if any is set > 0
        } else {
             // If setting weight to 0, re-check if any specific weight is still > 0
             _useTypeSpecificWeights = false;
             for(uint i = 0; i < _contributionTypeIds.length; i++) {
                 if (_scoreWeights[_contributionTypeIds[i]] > 0) {
                     _useTypeSpecificWeights = true;
                     break;
                 }
             }
        }
        emit ScoreWeightsSet(typeId, weight);
    }

    /**
     * @dev Gets the effective score weight for a contribution type.
     * Returns the specific weight if set (> 0), otherwise returns the default weight from the type definition.
     * @param typeId The ID of the contribution type.
     * @return The effective score weight.
     */
    function getScoreWeights(uint256 typeId) public view returns (uint256) {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        uint256 specificWeight = _scoreWeights[typeId];
        if (_useTypeSpecificWeights && specificWeight > 0) {
            return specificWeight;
        }
        return _contributionTypes[typeId].defaultScoreWeight;
    }


    // --- SBT Issuance (Attestor Only) ---

    /**
     * @dev Issues a new Soulbound Proof of Contribution token to a recipient.
     * Only callable by an attestor when the contract is not paused.
     * @param recipient The address to issue the token to.
     * @param typeId The ID of the contribution type.
     * @param level The level of the contribution (must be > 0).
     * @param metadataURI The specific metadata URI for this token (can be empty to use base URI).
     */
    function issueSBT(address recipient, uint256 typeId, uint256 level, string memory metadataURI) public onlyAttestor whenNotPaused {
        require(recipient != address(0), "Cannot mint to zero address");
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        require(level > 0, "Level must be greater than 0");
        if (_contributionTypes[typeId].maxLevel > 0) {
            require(level <= _contributionTypes[typeId].maxLevel, "Level exceeds max level for type");
        }

        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _mint(recipient, tokenId); // Mints the token using ERC721 standard internal function

        _sbtData[tokenId] = SBTData({
            typeId: typeId,
            level: level,
            attester: msg.sender,
            timestamp: uint64(block.timestamp),
            metadataURI: metadataURI // Stores specific URI, potentially overriding base
        });

        emit SBTIssued(tokenId, recipient, typeId, level, msg.sender);
    }

     /**
     * @dev Issues multiple Soulbound Proof of Contribution tokens in a single transaction.
     * Arrays must be of the same length.
     * Only callable by an attestor when the contract is not paused.
     * @param recipients Array of recipient addresses.
     * @param typeIds Array of contribution type IDs.
     * @param levels Array of levels.
     * @param metadataURIs Array of specific metadata URIs (can contain empty strings).
     */
    function issueBatchSBT(address[] memory recipients, uint256[] memory typeIds, uint256[] memory levels, string[] memory metadataURIs) public onlyAttestor whenNotPaused {
        require(recipients.length == typeIds.length && typeIds.length == levels.length && levels.length == metadataURIs.length, "Array lengths must match");
        require(recipients.length > 0, "Arrays cannot be empty");

        for (uint i = 0; i < recipients.length; i++) {
             require(recipients[i] != address(0), "Cannot mint to zero address");
             require(_contributionTypes[typeIds[i]].exists, "Invalid type ID");
             require(levels[i] > 0, "Level must be greater than 0");
             if (_contributionTypes[typeIds[i]].maxLevel > 0) {
                 require(levels[i] <= _contributionTypes[typeIds[i]].maxLevel, "Level exceeds max level for type");
             }

             uint256 tokenId = _nextTokenId.current();
             _nextTokenId.increment();

            _mint(recipients[i], tokenId);

             _sbtData[tokenId] = SBTData({
                 typeId: typeIds[i],
                 level: levels[i],
                 attester: msg.sender,
                 timestamp: uint64(block.timestamp),
                 metadataURI: metadataURIs[i]
             });

            emit SBTIssued(tokenId, recipients[i], typeIds[i], levels[i], msg.sender);
        }
    }


    // --- SBT Data & Querying ---

    /**
     * @dev Retrieves the specific data stored for a Soulbound Token.
     * @param tokenId The ID of the token.
     * @return The type ID, level, attester address, timestamp, and metadata URI.
     */
    function getSBTData(uint256 tokenId) public view returns (uint256 typeId, uint256 level, address attester, uint64 timestamp, string memory metadataURI) {
        require(_exists(tokenId), "Token does not exist");
        SBTData storage data = _sbtData[tokenId];
        return (data.typeId, data.level, data.attester, data.timestamp, data.metadataURI);
    }

    /**
     * @dev Gets all token IDs held by a specific recipient address.
     * @param recipient The address to query.
     * @return An array of token IDs.
     */
    function getSBTIdsByRecipient(address recipient) public view returns (uint256[] memory) {
        // Access the consolidated list maintained in _beforeTokenTransfer
         return _allRecipientTokens[recipient];
    }

    /**
     * @dev Gets token IDs of a specific contribution type held by a recipient.
     * @param recipient The address to query.
     * @param typeId The ID of the contribution type.
     * @return An array of token IDs of that type held by the recipient.
     */
    function getSBTIdsByRecipientAndType(address recipient, uint256 typeId) public view returns (uint256[] memory) {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        // Access the type-specific list maintained in _beforeTokenTransfer
        return _recipientTokensByType[recipient][typeId];
    }

     /**
     * @dev Checks if a recipient holds at least one SBT of a specific contribution type.
     * @param recipient The address to query.
     * @param typeId The ID of the contribution type.
     * @return True if the recipient holds at least one token of this type, false otherwise.
     */
    function doesRecipientHoldType(address recipient, uint256 typeId) public view returns (bool) {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        // Efficient check using the type-specific list
        return _recipientTokensByType[recipient][typeId].length > 0;
    }

    /**
     * @dev Finds the highest level among all SBTs of a specific type held by a recipient.
     * Returns 0 if the recipient holds no tokens of that type.
     * @param recipient The address to query.
     * @param typeId The ID of the contribution type.
     * @return The highest level found, or 0.
     */
    function getHighestLevelForType(address recipient, uint256 typeId) public view returns (uint256) {
        require(_contributionTypes[typeId].exists, "Invalid type ID");
        uint256 highestLevel = 0;
        uint256[] memory tokenIds = _recipientTokensByType[recipient][typeId];
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Ensure token still exists (might have been revoked outside the list logic if not careful, though _beforeTokenTransfer should handle)
             if (_exists(tokenId)) {
                 highestLevel = highestLevel > _sbtData[tokenId].level ? highestLevel : _sbtData[tokenId].level;
             }
        }
        return highestLevel;
    }


    // --- SBT Updates (Attestor Only) ---

    /**
     * @dev Upgrades the level of an existing Soulbound Token.
     * Only callable by an attestor.
     * @param tokenId The ID of the token to upgrade.
     * @param newLevel The new level for the token (must be > current level and > 0).
     * @param metadataURI Optional new metadata URI for the updated token.
     */
    function upgradeSBTLevel(uint256 tokenId, uint256 newLevel, string memory metadataURI) public onlyAttestor {
        require(_exists(tokenId), "Token does not exist");
        SBTData storage data = _sbtData[tokenId];
        require(newLevel > data.level, "New level must be higher than current level");
        require(newLevel > 0, "Level must be greater than 0");
        uint256 typeId = data.typeId;
         if (_contributionTypes[typeId].maxLevel > 0) {
            require(newLevel <= _contributionTypes[typeId].maxLevel, "New level exceeds max level for type");
        }

        address recipient = ownerOf(tokenId); // Get current owner (recipient)

        uint256 oldLevel = data.level;
        data.level = newLevel;
        data.timestamp = uint64(block.timestamp); // Update timestamp on upgrade
        data.metadataURI = metadataURI; // Update metadata URI

        emit SBTUpgraded(tokenId, oldLevel, newLevel, msg.sender);

        // Note: The token remains with the same recipient and tokenId.
        // No need to modify _recipientTokensByType or _allRecipientTokens as only level changed.
    }

    /**
     * @dev Revokes (burns) a Soulbound Token.
     * Can be called by the attestor who issued the token or by the contract owner.
     * @param tokenId The ID of the token to revoke.
     */
    function revokeSBT(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        // Only the original attester or the owner can revoke
        require(msg.sender == _sbtData[tokenId].attester || msg.sender == owner(), "Only issuer or owner can revoke");

        address recipient = ownerOf(tokenId); // Get current owner (recipient)

        _burn(tokenId); // Burns the token using ERC721Burnable

        // No need to explicitly delete _sbtData[tokenId], mapping default is zero/empty
        // The _beforeTokenTransfer hook should handle removal from recipient lists

        emit SBTRevoked(tokenId, recipient, msg.sender);
    }


    // --- Scoring ---

    /**
     * @dev Calculates a simple contribution score for an address.
     * The score is calculated based on the types and levels of SBTs held by the recipient.
     * Score = SUM( weight_for_type * level_of_token ) for all tokens held.
     * Uses type-specific weights if set, otherwise uses the default weight from the type definition.
     * @param recipient The address to calculate the score for.
     * @return The calculated contribution score.
     */
    function checkContributionScore(address recipient) public view returns (uint256) {
        uint256 totalScore = 0;
        // Iterate through all tokens held by the recipient
        uint256[] memory tokenIds = _allRecipientTokens[recipient];

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Double check existence, although _allRecipientTokens should be accurate after _beforeTokenTransfer
            if (_exists(tokenId)) {
                SBTData storage data = _sbtData[tokenId];
                uint256 typeId = data.typeId;
                uint256 level = data.level;

                uint256 effectiveWeight = getScoreWeights(typeId); // Use the function that checks specific vs default

                totalScore += effectiveWeight * level;
            }
        }
        return totalScore;
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns the specific metadataURI stored for the token if set,
     * otherwise constructs the URI from the base URI and token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory specificURI = _sbtData[tokenId].metadataURI;

        if (bytes(specificURI).length > 0) {
            return specificURI; // Return specific URI if provided
        } else if (bytes(_tokenURIBase).length > 0) {
            // Construct URI from base + tokenId
            return string(abi.encodePacked(_tokenURIBase, tokenId.toString()));
        } else {
            // Return empty string if neither base nor specific URI is set
            return "";
        }
    }

    /**
     * @dev See {ERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
        // Supports ERC721, ERC721Metadata, ERC721Enumerable, and ERC165
        // Does NOT support ERC721Transferable or ERC721Tradable interfaces if they existed,
        // as transfers are explicitly disabled.
        // Include ERC721Enumerable interface ID (0x780e9d63) if _ownedTokens is tracked efficiently.
        // OpenZeppelin's ERC721 includes ERC165 and ERC721. ERC721Burnable adds no new interface ID.
        // We manually added logic for enumeration (_allRecipientTokens), but it's not the standard ERC721Enumerable implementation.
        // Let's only claim support for ERC721 and ERC165 unless we fully implement ERC721Enumerable's public functions.
        // Given we provide `getSBTIdsByRecipient`, let's NOT claim ERC721Enumerable to avoid misleading users expecting `tokenOfOwnerByIndex`.
        // Revisit: OpenZeppelin's ERC721 *does* implement ERC721Enumerable internally via `_owners` and `_ownedTokens` unless configured not to.
        // Let's *assume* the OZ base supports it unless explicitly told otherwise, but our _beforeTokenTransfer hook might interfere or make the enumeration list inaccurate if not perfectly handled.
        // Safe bet: Claim ERC721 and ERC165 only. Add ERC721Metadata if tokenURI is meaningful.
        // Our tokenURI *is* meaningful.
        // ERC721: 0x80ac58cd
        // ERC721Metadata: 0x5b5e139f
        // ERC165: 0x01ffc9a7
        bytes4 erc721Interface = 0x80ac58cd;
        bytes4 erc721MetadataInterface = 0x5b5e139f;

        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId); // Includes ERC165 check
    }

}
```