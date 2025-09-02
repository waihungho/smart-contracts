This smart contract, `VeriSoulNexus`, introduces a sophisticated system for managing decentralized, dynamic, and reputation-based **VeriSouls**. These VeriSouls act as non-transferable (soulbound) tokens that attest to a user's skills, contributions, or achievements within an ecosystem. Unlike typical NFTs, VeriSouls can dynamically evolve, decay over time, be forged into new forms, and even delegate their influence (not ownership) to other users under strict conditions.

---

## VeriSoulNexus Smart Contract

**Advanced Concepts & Features:**

1.  **Dynamic Soulbound Tokens (SBTs):** VeriSouls are non-transferable (soulbound) ERC721-like tokens. Their `level` and `validity` can change over time.
2.  **Reputation-Based Attestors:** A network of permissioned "Attestors" (verified entities) are responsible for issuing and upgrading VeriSouls. Attestors have their own reputation score managed by the contract, influencing their ability to issue specific VeriSoul types.
3.  **VeriSoul Decay & Maintenance:** VeriSouls can decay in level or expire over time if not re-attested or actively maintained. Users can "stake" ERC-20 tokens to pause this decay, providing a dynamic economic incentive for maintaining relevance.
4.  **Conditional Influence Delegation:** While VeriSouls themselves are soulbound, their *influence* or *access rights* can be temporarily delegated to another address for specific purposes, with on-chain revocability. This allows for flexible participation without breaking the soulbound nature.
5.  **VeriSoul Forging:** Users can combine multiple existing VeriSouls they own into a new, higher-tier VeriSoul. This enables complex credential paths and progression systems (e.g., combining "Developer L1" and "Designer L1" to "Fullstack L1").
6.  **Tiered Access Control:** VeriSouls and their levels can be used by external contracts or internal functions to gate access to resources, features, or influence governance weight.

---

### Outline

1.  **Core Data Structures & Storage**: Defines the foundational structs for `VeriSoul`, `VeriSoulType`, `Attestor`, `Delegation`, and `StakedMaintenance`.
2.  **Deployment & Initialization**: Constructor and initial setup functions for the contract owner.
3.  **Attestor Management (5 functions)**: Handles registration, profile updates, deactivation, reputation adjustments, and authorization of Attestors for specific VeriSoul types.
4.  **VeriSoul Type Management (4 functions)**: Enables the contract owner to define, update, and deactivate different categories of VeriSouls with unique properties (decay rates, max levels).
5.  **VeriSoul Issuance & Management (6 functions)**: Provides functionalities for Attestors to mint new VeriSouls, upgrade existing ones, re-attest (extend validity), and allows owners/contract owner to burn VeriSouls. Includes view functions to query VeriSoul ownership and status.
6.  **Advanced VeriSoul Mechanics (5 functions)**: Implements the unique features: conditional influence delegation, delegation revocation, VeriSoul forging, a publicly callable decay mechanism, and staking for decay prevention.
7.  **Access Control & Utility (2 functions)**: A general-purpose function to check if an address (or its delegatee) meets a VeriSoul requirement, and a utility function to set the base URI for metadata.

---

### Function Summary

*   **`constructor()`**: Initializes the ERC721 contract with its name and symbol, and sets the contract owner.
*   **`initializeNexus(address _firstAttestor, string memory _attestorName, string memory _baseURI, address _trustedERC20ForStaking)`**: Performs a one-time setup of the nexus, registering the first attestor, setting the base URI for metadata, and designating a trusted ERC20 token for staking.

*   **`registerAttestor(address _wallet, string memory _name, uint256 _initialReputation)`**: (Owner Only) Registers a new Attestor with an initial reputation score.
*   **`updateAttestorProfile(uint256 _attestorId, string memory _name, bool _isActive)`**: (Owner / Attestor) Allows updating an Attestor's name or active status.
*   **`deactivateAttestor(uint256 _attestorId)`**: (Owner Only) Deactivates an Attestor, preventing them from issuing new VeriSouls.
*   **`updateAttestorReputation(uint256 _attestorId, int256 _reputationChange)`**: (Owner Only) Adjusts an Attestor's reputation score.
*   **`authorizeAttestorForType(uint256 _attestorId, uint256 _typeId)`**: (Owner Only) Grants an Attestor permission to issue a specific `VeriSoulType`.

*   **`createVeriSoulType(string memory _name, string memory _description, uint64 _decayRatePerYear, uint8 _maxLevel, uint256 _minAttestorRep, bool _isStackable)`**: (Owner Only) Defines a new category of VeriSoul with its specific properties.
*   **`updateVeriSoulTypeProperties(uint256 _typeId, string memory _name, string memory _description, uint64 _decayRatePerYear, uint8 _maxLevel, uint256 _minAttestorRep, bool _isStackable)`**: (Owner Only) Modifies the properties of an existing `VeriSoulType`.
*   **`deactivateVeriSoulType(uint256 _typeId)`**: (Owner Only) Deactivates a `VeriSoulType`, preventing new issuance.
*   **`getVeriSoulTypeDetails(uint256 _typeId) view`**: Retrieves detailed information about a specific `VeriSoulType`.

*   **`issueVeriSoul(address _to, uint256 _typeId, uint8 _level, uint64 _expiryDurationSeconds, string memory _metadataURI) returns (uint256)`**: (Attestor Only) Mints a new VeriSoul for a specified address, subject to Attestor permissions and reputation.
*   **`upgradeVeriSoulLevel(uint256 _tokenId, uint8 _newLevel, string memory _newMetadataURI)`**: (Attestor Only) Increases the level of an existing VeriSoul.
*   **`reAttestVeriSoul(uint256 _tokenId, uint64 _additionalDurationSeconds, string memory _newMetadataURI)`**: (Attestor Only) Extends the validity or resets the decay timer for a VeriSoul.
*   **`burnVeriSoul(uint256 _tokenId)`**: (VeriSoul Owner / Contract Owner) Allows burning a VeriSoul.
*   **`getSoulVeriSouls(address _soul) view returns (uint256[] memory)`**: Returns an array of all VeriSoul token IDs owned by a specific address.
*   **`checkSoulVeriSoulStatus(address _soul, uint256 _typeId) view returns (bool isActive, uint8 level, uint64 expiryTime)`**: Checks the current active status, level, and effective expiry of a specific `VeriSoulType` for a given Soul, considering decay and explicit expiry.

*   **`delegateVeriSoulInfluence(uint256 _tokenId, address _delegatee, uint64 _durationSeconds, bytes32 _purposeHash)`**: (VeriSoul Owner Only) Temporarily delegates the *influence* of a VeriSoul to another address for a specified duration and purpose.
*   **`revokeVeriSoulDelegation(uint256 _tokenId, address _delegatee)`**: (VeriSoul Owner Only) Revokes an active influence delegation.
*   **`forgeVeriSouls(uint256[] memory _tokenIdsToBurn, uint256 _newVeriSoulTypeId, uint8 _newVeriSoulLevel, string memory _metadataURI) returns (uint256)`**: (VeriSoul Owner Only) Allows combining and burning multiple VeriSouls to mint a new, higher-tier VeriSoul.
*   **`decayVeriSoul(uint256 _tokenId) returns (bool)`**: (Anyone) Triggers the decay process for an eligible VeriSoul, reducing its level based on its `VeriSoulType`'s decay rate. Can be publicly called (potentially for a small incentive).
*   **`stakeForVeriSoulMaintenance(uint256 _tokenId, uint256 _amount, address _erc20Token)`**: (VeriSoul Owner Only) Stakes a designated ERC-20 token to pause or extend the decay protection period for a VeriSoul.

*   **`hasVeriSoulAccess(address _soul, uint256 _requiredTypeId, uint8 _minLevel) view returns (bool)`**: Checks if a given address (either directly or via an active delegation) holds an active VeriSoul of the required type and minimum level.
*   **`setBaseURI(string memory _newBaseURI)`**: (Owner Only) Sets the base URI for VeriSoul metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VeriSoulNexus
 * @dev A Decentralized Skill & Contribution Attestation Network.
 *      VeriSoulNexus issues non-transferable VeriSouls (reputation-based tokens)
 *      that dynamically evolve based on user activity, attestations, and time.
 *      It features conditional influence delegation, VeriSoul forging, and decay mechanisms.
 *      This contract integrates advanced concepts like dynamic SBTs, permissioned attestation,
 *      and influence-based access control.
 *
 * @outline
 * 1.  **Core Data Structures & Storage**: Defines the foundational structs for VeriSouls, VeriSoulTypes, and Attestors.
 * 2.  **Deployment & Initialization**: Constructor and initial setup functions.
 * 3.  **Attestor Management (5 functions)**: Functions for registering, updating, deactivating, and managing the reputation of Attestors.
 * 4.  **VeriSoul Type Management (4 functions)**: Functions to define and modify the properties of different categories of VeriSouls.
 * 5.  **VeriSoul Issuance & Management (6 functions)**: Functions for minting, upgrading, re-attesting, and burning VeriSouls.
 * 6.  **Advanced VeriSoul Mechanics (5 functions)**: Implements unique features like conditional influence delegation, VeriSoul forging,
 *     decay, and staking for maintenance.
 * 7.  **Access Control & Utility (2 functions)**: Functions to check access based on VeriSouls and general contract utilities.
 *
 * @function_summary
 * - **constructor()**: Initializes the contract with an owner.
 * - **initializeNexus(address _firstAttestor, string memory _attestorName, string memory _baseURI, address _trustedERC20ForStaking)**: Sets up initial system.
 *
 * - **registerAttestor(address _wallet, string memory _name, uint256 _initialReputation)**: Registers a new Attestor. (Owner Only)
 * - **updateAttestorProfile(uint256 _attestorId, string memory _name, bool _isActive)**: Updates an Attestor's details. (Owner/Attestor)
 * - **deactivateAttestor(uint256 _attestorId)**: Deactivates an Attestor, preventing new attestations. (Owner Only)
 * - **updateAttestorReputation(uint256 _attestorId, int256 _reputationChange)**: Adjusts an Attestor's reputation. (Owner/Governance)
 * - **authorizeAttestorForType(uint256 _attestorId, uint256 _typeId)**: Grants an Attestor permission to issue a specific VeriSoulType. (Owner/Attestor)
 *
 * - **createVeriSoulType(string memory _name, string memory _description, uint64 _decayRatePerYear, uint8 _maxLevel, uint256 _minAttestorRep, bool _isStackable)**: Defines a new VeriSoul category. (Owner Only)
 * - **updateVeriSoulTypeProperties(uint256 _typeId, string memory _name, string memory _description, uint64 _decayRatePerYear, uint8 _maxLevel, uint256 _minAttestorRep, bool _isStackable)**: Modifies properties of a VeriSoulType. (Owner Only)
 * - **deactivateVeriSoulType(uint256 _typeId)**: Deactivates a VeriSoulType, preventing new issuance. (Owner Only)
 * - **getVeriSoulTypeDetails(uint256 _typeId) view**: Retrieves details of a specific VeriSoulType.
 *
 * - **issueVeriSoul(address _to, uint256 _typeId, uint8 _level, uint64 _expiryDurationSeconds, string memory _metadataURI) returns (uint256)**: Mints a new VeriSoul for a user. (Attestor Only)
 * - **upgradeVeriSoulLevel(uint256 _tokenId, uint8 _newLevel, string memory _newMetadataURI)**: Increases the level of an existing VeriSoul. (Attestor Only)
 * - **reAttestVeriSoul(uint256 _tokenId, uint64 _additionalDurationSeconds, string memory _newMetadataURI)**: Extends the validity/resets decay of a VeriSoul. (Attestor Only)
 * - **burnVeriSoul(uint256 _tokenId)**: Allows the owner of the VeriSoul or contract owner to burn it.
 * - **getSoulVeriSouls(address _soul) view returns (uint256[] memory)**: Lists all VeriSouls for an address.
 * - **checkSoulVeriSoulStatus(address _soul, uint256 _typeId) view returns (bool isActive, uint8 level, uint64 expiryTime)**: Checks the status of a specific VeriSoulType for a Soul.
 *
 * - **delegateVeriSoulInfluence(uint256 _tokenId, address _delegatee, uint64 _durationSeconds, bytes32 _purposeHash)**: Temporarily delegates the influence of a VeriSoul. (Soul Only)
 * - **revokeVeriSoulDelegation(uint256 _tokenId, address _delegatee)**: Revokes an active influence delegation. (Soul Only)
 * - **forgeVeriSouls(uint256[] memory _tokenIdsToBurn, uint256 _newVeriSoulTypeId, uint8 _newVeriSoulLevel, string memory _metadataURI) returns (uint256)**: Combines multiple VeriSouls into a new, higher-tier one. (Soul Only)
 * - **decayVeriSoul(uint256 _tokenId) returns (bool)**: Triggers the decay process for an eligible VeriSoul, reducing its level or marking as inactive. (Anyone, potentially incentivized)
 * - **stakeForVeriSoulMaintenance(uint256 _tokenId, uint256 _amount, address _erc20Token)**: Stakes ERC-20 tokens to pause or extend the validity of a VeriSoul's decay. (Soul Only)
 *
 * - **hasVeriSoulAccess(address _soul, uint256 _requiredTypeId, uint8 _minLevel) view returns (bool)**: Checks if a Soul (or its delegatee) meets a specific VeriSoul requirement.
 * - **setBaseURI(string memory _newBaseURI)**: Sets the base URI for VeriSoul metadata. (Owner Only)
 */
contract VeriSoulNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- Events ---
    event AttestorRegistered(uint256 indexed attestorId, address indexed wallet, string name);
    event AttestorReputationUpdated(uint256 indexed attestorId, int256 newReputation);
    event VeriSoulTypeCreated(uint256 indexed typeId, string name, uint8 maxLevel);
    event VeriSoulIssued(uint256 indexed tokenId, address indexed to, uint256 indexed typeId, uint8 level);
    event VeriSoulLevelUpgraded(uint256 indexed tokenId, uint8 newLevel);
    event VeriSoulReAttested(uint256 indexed tokenId, uint64 newExpiryTime);
    event VeriSoulBurned(uint256 indexed tokenId);
    event VeriSoulDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee, uint64 duration, bytes32 purposeHash);
    event VeriSoulDelegationRevoked(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event VeriSoulForged(uint256 indexed newVeriSoulTokenId, address indexed forger, uint256[] burnedTokenIds);
    event VeriSoulDecayed(uint256 indexed tokenId, uint8 newLevel, bool inactive);
    event VeriSoulMaintenanceStaked(uint256 indexed tokenId, address indexed staker, uint256 amount, address erc20Token);

    // --- Storage ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _veriSoulTypeCounter;
    Counters.Counter private _attestorIdCounter;

    struct VeriSoul {
        uint256 typeId;
        address owner; // Cannot be transferred, but stored for convenience
        uint8 level;
        uint64 issueTimestamp;
        uint64 expiryTimestamp; // 0 if no explicit expiry, relies on decay rate
        uint256 attestorId;
        string metadataURI;
    }

    struct VeriSoulType {
        string name;
        string description;
        uint64 decayRatePerYear; // In seconds, e.g., 31536000 seconds for 1 level per year
        uint8 maxLevel;
        uint256 minAttestorRep; // Minimum reputation an attestor needs to issue this type
        bool isStackable; // Can multiple of this type be held by one person (e.g., L1, L2 of same skill)?
        bool isActive;
    }

    struct Attestor {
        address wallet;
        string name;
        int256 reputationScore;
        bool isActive;
        // Mapped separately: `authorizedAttestorTypes[attestorId][typeId]`
    }

    // tokenId => VeriSoul details
    mapping(uint256 => VeriSoul) public veriSouls;
    // typeId => VeriSoulType details
    mapping(uint256 => VeriSoulType) public veriSoulTypes;
    // attestorId => Attestor details
    mapping(uint256 => Attestor) public attestors;

    // attestorId => typeId => bool (is authorized to issue this type)
    mapping(uint256 => mapping(uint256 => bool)) public authorizedAttestorTypes;

    // tokenId => delegatee => {duration, purposeHash, delegatedAt}
    mapping(uint256 => mapping(address => Delegation)) public veriSoulDelegations;

    struct Delegation {
        uint64 delegatedAt;
        uint64 duration; // 0 for indefinite
        bytes32 purposeHash;
    }

    // tokenId => {stakedToken, amount, timestamp, protectionUntil} for decay prevention
    mapping(uint256 => StakedMaintenance) public stakedMaintenance;

    struct StakedMaintenance {
        IERC20 token;
        uint256 amount;
        uint64 stakedAt;
        uint64 protectionUntil; // Timestamp until which decay is paused
    }

    // ERC20 token for staking (can be configured to accept multiple, but for simplicity, one trusted token)
    address public trustedERC20ForStaking;

    // Internal variable to store the base URI for metadata
    string private _baseURIExtended;

    constructor() ERC721("VeriSoulNexus", "VSN") Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier onlyAttestor(uint256 _attestorId) {
        require(attestors[_attestorId].isActive, "VeriSoulNexus: Attestor is not active");
        require(attestors[_attestorId].wallet == msg.sender, "VeriSoulNexus: Not authorized attestor");
        _;
    }

    modifier onlyVeriSoulOwner(uint256 _tokenId) {
        require(veriSouls[_tokenId].owner == msg.sender, "VeriSoulNexus: Not VeriSoul owner");
        _;
    }

    // --- 2. Deployment & Initialization ---

    /**
     * @dev Initializes the Nexus with essential configurations like the first attestor, base URI, and trusted staking token.
     *      Can only be called once.
     * @param _firstAttestor The wallet address of the initial attestor.
     * @param _attestorName The name of the initial attestor.
     * @param _baseURI The base URI for VeriSoul metadata.
     * @param _trustedERC20ForStaking The address of the ERC-20 token contract to be used for staking.
     */
    function initializeNexus(
        address _firstAttestor,
        string memory _attestorName,
        string memory _baseURI,
        address _trustedERC20ForStaking
    ) public onlyOwner {
        require(_attestorIdCounter.current() == 0, "VeriSoulNexus: Nexus already initialized");
        
        _baseURIExtended = _baseURI;
        trustedERC20ForStaking = _trustedERC20ForStaking;

        _attestorIdCounter.increment();
        uint256 firstAttestorId = _attestorIdCounter.current();
        attestors[firstAttestorId] = Attestor({
            wallet: _firstAttestor,
            name: _attestorName,
            reputationScore: 1000, // Initial high reputation
            isActive: true
        });
        emit AttestorRegistered(firstAttestorId, _firstAttestor, _attestorName);
    }

    // --- 3. Attestor Management (5 functions) ---

    /**
     * @dev Registers a new Attestor. Only callable by the contract owner.
     * @param _wallet The address of the new attestor.
     * @param _name The name of the attestor.
     * @param _initialReputation The initial reputation score for the attestor.
     */
    function registerAttestor(address _wallet, string memory _name, uint256 _initialReputation) public onlyOwner {
        _attestorIdCounter.increment();
        uint256 newAttestorId = _attestorIdCounter.current();
        attestors[newAttestorId] = Attestor({
            wallet: _wallet,
            name: _name,
            reputationScore: int256(_initialReputation),
            isActive: true
        });
        emit AttestorRegistered(newAttestorId, _wallet, _name);
    }

    /**
     * @dev Updates an Attestor's profile. Can be called by the owner or the attestor themselves.
     * @param _attestorId The ID of the attestor to update.
     * @param _name The new name for the attestor (empty string to keep current).
     * @param _isActive The new active status (true to activate, false to deactivate).
     */
    function updateAttestorProfile(uint256 _attestorId, string memory _name, bool _isActive) public {
        require(attestors[_attestorId].wallet != address(0), "VeriSoulNexus: Attestor does not exist");
        require(msg.sender == owner() || msg.sender == attestors[_attestorId].wallet, "VeriSoulNexus: Not authorized to update attestor profile");

        Attestor storage attestor = attestors[_attestorId];
        if (bytes(_name).length > 0) {
            attestor.name = _name;
        }
        attestor.isActive = _isActive;
    }

    /**
     * @dev Deactivates an Attestor, preventing them from issuing new VeriSouls.
     *      Existing VeriSouls issued by them remain valid. Only callable by the contract owner.
     * @param _attestorId The ID of the attestor to deactivate.
     */
    function deactivateAttestor(uint256 _attestorId) public onlyOwner {
        require(attestors[_attestorId].wallet != address(0), "VeriSoulNexus: Attestor does not exist");
        attestors[_attestorId].isActive = false;
    }

    /**
     * @dev Updates an Attestor's reputation score. This can be used by governance or owner
     *      to reward or penalize attestors based on their performance or community feedback.
     * @param _attestorId The ID of the attestor.
     * @param _reputationChange The amount to change the reputation by (can be negative).
     */
    function updateAttestorReputation(uint256 _attestorId, int256 _reputationChange) public onlyOwner {
        require(attestors[_attestorId].wallet != address(0), "VeriSoulNexus: Attestor does not exist");
        Attestor storage attestor = attestors[_attestorId];
        attestor.reputationScore += _reputationChange;
        emit AttestorReputationUpdated(_attestorId, attestor.reputationScore);
    }

    /**
     * @dev Authorizes an Attestor to issue a specific VeriSoulType.
     *      Callable by the contract owner.
     * @param _attestorId The ID of the attestor.
     * @param _typeId The ID of the VeriSoulType.
     */
    function authorizeAttestorForType(uint256 _attestorId, uint256 _typeId) public onlyOwner {
        require(attestors[_attestorId].wallet != address(0), "VeriSoulNexus: Attestor does not exist");
        require(veriSoulTypes[_typeId].isActive, "VeriSoulNexus: VeriSoulType is not active");
        authorizedAttestorTypes[_attestorId][_typeId] = true;
    }
    
    // --- 4. VeriSoul Type Management (4 functions) ---

    /**
     * @dev Creates a new VeriSoulType. Only callable by the contract owner.
     * @param _name The name of the VeriSoulType (e.g., "Developer L1").
     * @param _description A description of the type.
     * @param _decayRatePerYear The rate at which this VeriSoul type decays, e.g., 31536000 seconds for 1 level per year.
     * @param _maxLevel The maximum level achievable for this type.
     * @param _minAttestorRep Minimum reputation an attestor needs to issue/upgrade this type.
     * @param _isStackable If true, a user can hold multiple VeriSouls of this type (e.g., L1 and L2). If false, only one at a time.
     */
    function createVeriSoulType(
        string memory _name,
        string memory _description,
        uint64 _decayRatePerYear,
        uint8 _maxLevel,
        uint256 _minAttestorRep,
        bool _isStackable
    ) public onlyOwner {
        _veriSoulTypeCounter.increment();
        uint256 newTypeId = _veriSoulTypeCounter.current();
        veriSoulTypes[newTypeId] = VeriSoulType({
            name: _name,
            description: _description,
            decayRatePerYear: _decayRatePerYear,
            maxLevel: _maxLevel,
            minAttestorRep: _minAttestorRep,
            isStackable: _isStackable,
            isActive: true
        });
        emit VeriSoulTypeCreated(newTypeId, _name, _maxLevel);
    }

    /**
     * @dev Updates properties of an existing VeriSoulType. Only callable by the contract owner.
     *      Careful: changes affect future behavior and interpretation of existing VeriSouls.
     * @param _typeId The ID of the VeriSoulType to update.
     * @param _name The new name (empty string to keep current).
     * @param _description The new description (empty string to keep current).
     * @param _decayRatePerYear The new decay rate (0 to keep current).
     * @param _maxLevel The new maximum level (0 to keep current).
     * @param _minAttestorRep The new minimum attestor reputation (0 to keep current).
     * @param _isStackable The new stackable status (explicitly set).
     */
    function updateVeriSoulTypeProperties(
        uint256 _typeId,
        string memory _name,
        string memory _description,
        uint64 _decayRatePerYear,
        uint8 _maxLevel,
        uint256 _minAttestorRep,
        bool _isStackable
    ) public onlyOwner {
        VeriSoulType storage vt = veriSoulTypes[_typeId];
        require(vt.isActive, "VeriSoulNexus: VeriSoulType does not exist or is inactive");

        if (bytes(_name).length > 0) vt.name = _name;
        if (bytes(_description).length > 0) vt.description = _description;
        if (_decayRatePerYear > 0) vt.decayRatePerYear = _decayRatePerYear;
        if (_maxLevel > 0) vt.maxLevel = _maxLevel;
        if (_minAttestorRep > 0) vt.minAttestorRep = _minAttestorRep;
        vt.isStackable = _isStackable;
    }

    /**
     * @dev Deactivates a VeriSoulType, preventing new VeriSouls of this type from being issued.
     *      Existing VeriSouls of this type remain active unless they decay.
     * @param _typeId The ID of the VeriSoulType to deactivate.
     */
    function deactivateVeriSoulType(uint256 _typeId) public onlyOwner {
        require(veriSoulTypes[_typeId].isActive, "VeriSoulNexus: VeriSoulType does not exist or is already inactive");
        veriSoulTypes[_typeId].isActive = false;
    }
    
    /**
     * @dev Retrieves the detailed properties of a specific VeriSoulType.
     * @param _typeId The ID of the VeriSoulType.
     * @return name The name of the type.
     * @return description The description of the type.
     * @return decayRatePerYear The annual decay rate.
     * @return maxLevel The maximum level.
     * @return minAttestorRep The minimum attestor reputation required.
     * @return isStackable Whether multiple VeriSouls of this type can be held.
     * @return isActive Whether the type is active.
     */
    function getVeriSoulTypeDetails(uint256 _typeId)
        public
        view
        returns (
            string memory name,
            string memory description,
            uint64 decayRatePerYear,
            uint8 maxLevel,
            uint256 minAttestorRep,
            bool isStackable,
            bool isActive
        )
    {
        VeriSoulType storage vt = veriSoulTypes[_typeId];
        return (vt.name, vt.description, vt.decayRatePerYear, vt.maxLevel, vt.minAttestorRep, vt.isStackable, vt.isActive);
    }

    // --- 5. VeriSoul Issuance & Management (6 functions) ---

    /**
     * @dev Issues a new VeriSoul to an address. Only callable by an authorized Attestor.
     *      This is akin to minting an SBT.
     * @param _to The address to issue the VeriSoul to.
     * @param _typeId The VeriSoulType ID.
     * @param _level The initial level of the VeriSoul.
     * @param _expiryDurationSeconds Optional: duration after which the VeriSoul expires (0 for no explicit expiry).
     * @param _metadataURI The URI pointing to the VeriSoul's metadata.
     * @return The tokenId of the newly issued VeriSoul.
     */
    function issueVeriSoul(
        address _to,
        uint256 _typeId,
        uint8 _level,
        uint64 _expiryDurationSeconds,
        string memory _metadataURI
    ) public returns (uint256) {
        uint256 attestorId = 0; // Find attestorId for msg.sender
        for (uint256 i = 1; i <= _attestorIdCounter.current(); i++) {
            if (attestors[i].wallet == msg.sender) {
                attestorId = i;
                break;
            }
        }
        require(attestorId != 0, "VeriSoulNexus: Caller is not a registered attestor");
        require(attestors[attestorId].isActive, "VeriSoulNexus: Attestor is not active");
        require(authorizedAttestorTypes[attestorId][_typeId], "VeriSoulNexus: Attestor not authorized for this type");
        require(attestors[attestorId].reputationScore >= int256(veriSoulTypes[_typeId].minAttestorRep), "VeriSoulNexus: Attestor reputation too low for this type");
        
        VeriSoulType storage vt = veriSoulTypes[_typeId];
        require(vt.isActive, "VeriSoulNexus: VeriSoulType is not active");
        require(_level > 0 && _level <= vt.maxLevel, "VeriSoulNexus: Invalid VeriSoul level");
        
        // If not stackable, check if the soul already has a VeriSoul of this type
        if (!vt.isStackable) {
            uint256[] memory soulsOfType = getSoulVeriSoulsByType(_to, _typeId);
            require(soulsOfType.length == 0, "VeriSoulNexus: Soul already possesses a non-stackable VeriSoul of this type");
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        uint64 currentTime = uint64(block.timestamp);
        uint64 expiry = _expiryDurationSeconds > 0 ? currentTime + _expiryDurationSeconds : 0;

        veriSouls[newTokenId] = VeriSoul({
            typeId: _typeId,
            owner: _to,
            level: _level,
            issueTimestamp: currentTime,
            expiryTimestamp: expiry,
            attestorId: attestorId,
            metadataURI: _metadataURI
        });
        
        _safeMint(_to, newTokenId);
        emit VeriSoulIssued(newTokenId, _to, _typeId, _level);
        return newTokenId;
    }

    /**
     * @dev Upgrades the level of an existing VeriSoul. Only callable by an authorized Attestor.
     *      The attestor must be authorized for the VeriSoul's type and meet reputation requirements.
     * @param _tokenId The ID of the VeriSoul to upgrade.
     * @param _newLevel The new level for the VeriSoul.
     * @param _newMetadataURI Optional: New URI for updated metadata (empty string to keep current).
     */
    function upgradeVeriSoulLevel(uint256 _tokenId, uint8 _newLevel, string memory _newMetadataURI) public {
        VeriSoul storage vs = veriSouls[_tokenId];
        require(vs.owner != address(0), "VeriSoulNexus: VeriSoul does not exist");
        
        uint256 attestorId = 0; // Find attestorId for msg.sender
        for (uint256 i = 1; i <= _attestorIdCounter.current(); i++) {
            if (attestors[i].wallet == msg.sender) {
                attestorId = i;
                break;
            }
        }
        require(attestorId != 0, "VeriSoulNexus: Caller is not a registered attestor");
        require(attestors[attestorId].isActive, "VeriSoulNexus: Attestor is not active");
        require(authorizedAttestorTypes[attestorId][vs.typeId], "VeriSoulNexus: Attestor not authorized for this type");
        require(attestors[attestorId].reputationScore >= int256(veriSoulTypes[vs.typeId].minAttestorRep), "VeriSoulNexus: Attestor reputation too low for this type");

        VeriSoulType storage vt = veriSoulTypes[vs.typeId];
        require(_newLevel > vs.level && _newLevel <= vt.maxLevel, "VeriSoulNexus: Invalid new VeriSoul level");

        vs.level = _newLevel;
        if (bytes(_newMetadataURI).length > 0) {
            vs.metadataURI = _newMetadataURI;
        }
        emit VeriSoulLevelUpgraded(_tokenId, _newLevel);
    }

    /**
     * @dev Re-attests a VeriSoul, extending its validity or resetting its decay timer.
     *      Callable by an authorized Attestor.
     * @param _tokenId The ID of the VeriSoul to re-attest.
     * @param _additionalDurationSeconds The duration to add to its current expiry or decay period.
     * @param _newMetadataURI Optional: New URI for updated metadata (empty string to keep current).
     */
    function reAttestVeriSoul(uint256 _tokenId, uint64 _additionalDurationSeconds, string memory _newMetadataURI) public {
        VeriSoul storage vs = veriSouls[_tokenId];
        require(vs.owner != address(0), "VeriSoulNexus: VeriSoul does not exist");

        uint256 attestorId = 0; // Find attestorId for msg.sender
        for (uint256 i = 1; i <= _attestorIdCounter.current(); i++) {
            if (attestors[i].wallet == msg.sender) {
                attestorId = i;
                break;
            }
        }
        require(attestorId != 0, "VeriSoulNexus: Caller is not a registered attestor");
        require(attestors[attestorId].isActive, "VeriSoulNexus: Attestor is not active");
        require(authorizedAttestorTypes[attestorId][vs.typeId], "VeriSoulNexus: Attestor not authorized for this type");
        require(attestors[attestorId].reputationScore >= int256(veriSoulTypes[vs.typeId].minAttestorRep), "VeriSoulNexus: Attestor reputation too low for this type");
        
        // If there was a staked maintenance, assume re-attestation overrules it or extends from it
        if (stakedMaintenance[_tokenId].protectionUntil > block.timestamp || vs.expiryTimestamp == 0) {
            stakedMaintenance[_tokenId].protectionUntil = uint64(block.timestamp) + _additionalDurationSeconds;
        } else { // Extend explicit expiry
            vs.expiryTimestamp = uint64(block.timestamp) + _additionalDurationSeconds;
        }
        
        if (bytes(_newMetadataURI).length > 0) {
            vs.metadataURI = _newMetadataURI;
        }
        emit VeriSoulReAttested(_tokenId, vs.expiryTimestamp);
    }

    /**
     * @dev Allows the owner of the VeriSoul or the contract owner to burn it.
     *      This effectively removes the attestation from the Soul.
     * @param _tokenId The ID of the VeriSoul to burn.
     */
    function burnVeriSoul(uint256 _tokenId) public {
        VeriSoul storage vs = veriSouls[_tokenId];
        require(vs.owner != address(0), "VeriSoulNexus: VeriSoul does not exist");
        require(msg.sender == owner() || msg.sender == vs.owner, "VeriSoulNexus: Not authorized to burn this VeriSoul");

        _burn(_tokenId);
        delete veriSouls[_tokenId];
        // Clean up any associated delegation or staking info
        delete veriSoulDelegations[_tokenId];
        delete stakedMaintenance[_tokenId];
        emit VeriSoulBurned(_tokenId);
    }

    /**
     * @dev Returns an array of all VeriSoul token IDs owned by a specific address.
     * @param _soul The address whose VeriSouls are to be retrieved.
     * @return An array of VeriSoul token IDs.
     */
    function getSoulVeriSouls(address _soul) public view returns (uint256[] memory) {
        uint256[] memory ownedTokens = new uint256[](balanceOf(_soul));
        uint256 counter = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (veriSouls[i].owner == _soul) { // Check ownership
                ownedTokens[counter] = i;
                counter++;
            }
        }
        return ownedTokens;
    }

    /**
     * @dev Internal helper to get VeriSouls of a specific type for a given soul.
     */
    function getSoulVeriSoulsByType(address _soul, uint256 _typeId) internal view returns (uint256[] memory) {
        uint256[] memory allSoulVeriSouls = getSoulVeriSouls(_soul);
        uint256 count = 0;
        for (uint256 i = 0; i < allSoulVeriSouls.length; i++) {
            if (veriSouls[allSoulVeriSouls[i]].typeId == _typeId) {
                count++;
            }
        }
        uint256[] memory filteredVeriSouls = new uint256[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < allSoulVeriSouls.length; i++) {
            if (veriSouls[allSoulVeriSouls[i]].typeId == _typeId) {
                filteredVeriSouls[currentIdx] = allSoulVeriSouls[i];
                currentIdx++;
            }
        }
        return filteredVeriSouls;
    }


    /**
     * @dev Checks the current status (active/level/expiry) of a specific VeriSoulType for a given Soul.
     *      Considers decay and explicit expiry.
     * @param _soul The address of the Soul.
     * @param _typeId The VeriSoulType ID to check.
     * @return isActive True if the soul has an active VeriSoul of this type and level > 0.
     * @return level The current level of the VeriSoul (0 if inactive).
     * @return expiryTime The effective expiry time (0 if no explicit expiry and fully decayed).
     */
    function checkSoulVeriSoulStatus(address _soul, uint256 _typeId)
        public
        view
        returns (bool isActive, uint8 level, uint64 expiryTime)
    {
        uint256[] memory soulVeriSouls = getSoulVeriSoulsByType(_soul, _typeId);
        if (soulVeriSouls.length == 0) {
            return (false, 0, 0);
        }

        uint256 highestLevelTokenId = 0;
        uint8 highestLevel = 0;
        uint64 effectiveExpiry = 0;

        for (uint256 i = 0; i < soulVeriSouls.length; i++) {
            uint256 tokenId = soulVeriSouls[i];
            VeriSoul storage vs = veriSouls[tokenId];
            
            uint8 currentLevel = vs.level;
            uint64 currentExpiry = vs.expiryTimestamp;

            // Check for active maintenance stake
            if (stakedMaintenance[tokenId].protectionUntil > block.timestamp) {
                // Decay is paused, effective expiry is protectionUntil
                currentExpiry = stakedMaintenance[tokenId].protectionUntil;
            } else if (veriSoulTypes[vs.typeId].decayRatePerYear > 0) {
                // Apply decay logic if not explicitly expired and no active stake
                uint64 timePassedSinceIssue = uint64(block.timestamp) - vs.issueTimestamp;
                uint256 levelsToDecay = timePassedSinceIssue / veriSoulTypes[vs.typeId].decayRatePerYear;
                currentLevel = vs.level > levelsToDecay ? vs.level - uint8(levelsToDecay) : 0;
                
                // If decayed to 0, it's inactive effectively now.
                // Otherwise, it doesn't have a new explicit expiry from decay, only its level is reduced.
            }

            // If there's an explicit expiry, it takes precedence if sooner
            if (vs.expiryTimestamp > 0 && vs.expiryTimestamp <= block.timestamp) {
                currentLevel = 0; // Explicitly expired
            } else if (vs.expiryTimestamp > 0) {
                // If it has explicit expiry, and it's in the future, that's its expiry.
                // If also protected by stake, the later of the two takes precedence for validity duration.
                currentExpiry = (currentExpiry > vs.expiryTimestamp) ? currentExpiry : vs.expiryTimestamp;
            }

            if (currentLevel > 0 && (currentExpiry == 0 || currentExpiry > block.timestamp)) {
                if (currentLevel > highestLevel) {
                    highestLevel = currentLevel;
                    effectiveExpiry = currentExpiry;
                    highestLevelTokenId = tokenId;
                }
            }
        }
        
        if (highestLevelTokenId != 0) {
            return (true, highestLevel, effectiveExpiry);
        }
        return (false, 0, 0);
    }

    // --- 6. Advanced VeriSoul Mechanics (5 functions) ---

    /**
     * @dev Allows a VeriSoul owner to temporarily delegate its *influence* or *access rights*
     *      to another address for a specified duration and purpose. This does NOT transfer the VeriSoul itself.
     * @param _tokenId The ID of the VeriSoul to delegate influence for.
     * @param _delegatee The address to delegate influence to.
     * @param _durationSeconds The duration for which the delegation is valid (0 for indefinite, until revoked).
     * @param _purposeHash A hash representing the specific purpose or context of the delegation.
     */
    function delegateVeriSoulInfluence(uint256 _tokenId, address _delegatee, uint64 _durationSeconds, bytes32 _purposeHash) public onlyVeriSoulOwner(_tokenId) {
        require(_delegatee != address(0), "VeriSoulNexus: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "VeriSoulNexus: Cannot delegate to self");

        veriSoulDelegations[_tokenId][_delegatee] = Delegation({
            delegatedAt: uint64(block.timestamp),
            duration: _durationSeconds,
            purposeHash: _purposeHash
        });

        emit VeriSoulDelegated(_tokenId, msg.sender, _delegatee, _durationSeconds, _purposeHash);
    }

    /**
     * @dev Revokes an active VeriSoul influence delegation. Callable by the original delegator.
     * @param _tokenId The ID of the VeriSoul for which delegation is revoked.
     * @param _delegatee The address whose delegation is to be revoked.
     */
    function revokeVeriSoulDelegation(uint256 _tokenId, address _delegatee) public onlyVeriSoulOwner(_tokenId) {
        require(veriSoulDelegations[_tokenId][_delegatee].delegatedAt != 0, "VeriSoulNexus: No active delegation found for this delegatee");
        
        delete veriSoulDelegations[_tokenId][_delegatee];
        emit VeriSoulDelegationRevoked(_tokenId, msg.sender, _delegatee);
    }

    /**
     * @dev Allows a user to combine (forge) multiple existing VeriSouls they own into a new, higher-tier VeriSoul.
     *      The specific requirements for forging (e.g., types and levels of input VeriSouls)
     *      would be defined off-chain or by a helper contract/oracle based on `newVeriSoulTypeId`.
     *      For this example, we require burning at least 2 tokens and a valid new type/level.
     * @param _tokenIdsToBurn An array of VeriSoul IDs to be burned.
     * @param _newVeriSoulTypeId The VeriSoulType ID of the new VeriSoul to be minted.
     * @param _newVeriSoulLevel The level of the new VeriSoul.
     * @param _metadataURI The URI for the metadata of the new forged VeriSoul.
     * @return The tokenId of the newly forged VeriSoul.
     */
    function forgeVeriSouls(
        uint256[] memory _tokenIdsToBurn,
        uint256 _newVeriSoulTypeId,
        uint8 _newVeriSoulLevel,
        string memory _metadataURI
    ) public returns (uint256) {
        require(_tokenIdsToBurn.length >= 2, "VeriSoulNexus: At least two VeriSouls are required for forging");
        
        // Basic example forging logic: requires all burned tokens to be owned by msg.sender
        // and allows forging into a new type, given valid level and type.
        // More complex logic (e.g., requiring specific types/levels to be burned for a specific result)
        // would be implemented here or managed by external logic interacting with this function.
        for (uint256 i = 0; i < _tokenIdsToBurn.length; i++) {
            require(veriSouls[_tokenIdsToBurn[i]].owner == msg.sender, "VeriSoulNexus: Can only burn your own VeriSouls for forging");
            require(veriSouls[_tokenIdsToBurn[i]].owner != address(0), "VeriSoulNexus: One of the VeriSouls to burn does not exist");
        }

        VeriSoulType storage newVt = veriSoulTypes[_newVeriSoulTypeId];
        require(newVt.isActive, "VeriSoulNexus: New VeriSoulType is not active");
        require(_newVeriSoulLevel > 0 && _newVeriSoulLevel <= newVt.maxLevel, "VeriSoulNexus: Invalid level for new VeriSoul");

        // Burn the old VeriSouls
        for (uint256 i = 0; i < _tokenIdsToBurn.length; i++) {
            _burn(_tokenIdsToBurn[i]);
            delete veriSouls[_tokenIdsToBurn[i]];
            // Also clean up any associated delegation or staking for burned tokens
            delete veriSoulDelegations[_tokenIdsToBurn[i]];
            delete stakedMaintenance[_tokenIdsToBurn[i]];
        }

        // Mint the new, forged VeriSoul
        _tokenIdCounter.increment();
        uint256 newForgedTokenId = _tokenIdCounter.current();
        uint64 currentTime = uint64(block.timestamp);

        veriSouls[newForgedTokenId] = VeriSoul({
            typeId: _newVeriSoulTypeId,
            owner: msg.sender,
            level: _newVeriSoulLevel,
            issueTimestamp: currentTime,
            expiryTimestamp: 0, // Forged VeriSouls can have different expiry logic, default to decay-based
            attestorId: 0, // Forged by the system, or a special "Forging Attestor"
            metadataURI: _metadataURI
        });

        _safeMint(msg.sender, newForgedTokenId);
        emit VeriSoulForged(newForgedTokenId, msg.sender, _tokenIdsToBurn);
        return newForgedTokenId;
    }

    /**
     * @dev Triggers the decay process for a specified VeriSoul. Anyone can call this,
     *      potentially to "clean up" inactive VeriSouls or to process decay for a reward.
     *      This function updates the level of the VeriSoul based on its type's decay rate.
     * @param _tokenId The ID of the VeriSoul to decay.
     * @return True if decay was applied, false otherwise (e.g., already decayed or protected).
     */
    function decayVeriSoul(uint256 _tokenId) public returns (bool) {
        VeriSoul storage vs = veriSouls[_tokenId];
        require(vs.owner != address(0), "VeriSoulNexus: VeriSoul does not exist");
        
        VeriSoulType storage vt = veriSoulTypes[vs.typeId];
        if (vt.decayRatePerYear == 0) return false; // This type does not decay

        // Check for active maintenance stake or explicit future expiry
        if (stakedMaintenance[_tokenId].protectionUntil > block.timestamp || (vs.expiryTimestamp > 0 && vs.expiryTimestamp > block.timestamp)) {
            return false; // Currently protected from decay or explicitly valid
        }

        uint64 timePassedSinceLastUpdate = uint64(block.timestamp) - vs.issueTimestamp; // Simplified: could be `lastDecayCheck`
        uint256 potentialLevelsToDecay = timePassedSinceLastUpdate / vt.decayRatePerYear;

        if (potentialLevelsToDecay == 0) return false; // Not enough time passed for a level decay

        uint8 oldLevel = vs.level;
        uint8 newLevel = oldLevel > potentialLevelsToDecay ? oldLevel - uint8(potentialLevelsToDecay) : 0;
        
        if (newLevel == oldLevel) return false; // No effective decay

        vs.level = newLevel;
        // Reset issueTimestamp for next decay calculation from current time, reflecting new base level
        vs.issueTimestamp = uint64(block.timestamp); 

        emit VeriSoulDecayed(_tokenId, newLevel, newLevel == 0);
        return true;
    }

    /**
     * @dev Allows a VeriSoul owner to stake ERC-20 tokens to pause or extend the validity
     *      of their VeriSoul's decay for a certain period.
     * @param _tokenId The ID of the VeriSoul to protect.
     * @param _amount The amount of ERC-20 tokens to stake.
     * @param _erc20Token The address of the ERC-20 token contract.
     */
    function stakeForVeriSoulMaintenance(uint256 _tokenId, uint256 _amount, address _erc20Token) public onlyVeriSoulOwner(_tokenId) {
        VeriSoul storage vs = veriSouls[_tokenId];
        require(vs.owner != address(0), "VeriSoulNexus: VeriSoul does not exist");
        require(_amount > 0, "VeriSoulNexus: Stake amount must be greater than zero");
        require(_erc20Token == trustedERC20ForStaking, "VeriSoulNexus: Only trusted ERC20 token can be staked");

        IERC20 token = IERC20(_erc20Token);
        require(token.transferFrom(msg.sender, address(this), _amount), "VeriSoulNexus: ERC20 transfer failed");

        // Example: 100 units of trusted ERC20 for 30 days of protection.
        // This rate can be made configurable or more complex.
        uint64 protectionExtension = (_amount * 30 days) / 100;

        StakedMaintenance storage maintenance = stakedMaintenance[_tokenId];
        maintenance.token = token;
        maintenance.amount += _amount;
        maintenance.stakedAt = uint64(block.timestamp); // Update last staked time

        if (maintenance.protectionUntil < block.timestamp) {
            maintenance.protectionUntil = uint64(block.timestamp) + protectionExtension;
        } else {
            maintenance.protectionUntil += protectionExtension;
        }
        
        emit VeriSoulMaintenanceStaked(_tokenId, msg.sender, _amount, _erc20Token);
    }
    
    // TODO: Add function to withdraw staked maintenance. This would require rules for partial withdrawal,
    // and potentially shortening the protection period. Not included to keep the example manageable.

    // --- 7. Access Control & Utility (2 functions) ---

    /**
     * @dev Checks if a Soul (or an active delegatee) meets the requirements for a specific VeriSoulType and level.
     * @param _potentialAccessor The address of the Soul (or a potential delegatee).
     * @param _requiredTypeId The VeriSoulType ID required.
     * @param _minLevel The minimum level required.
     * @return True if the Soul or an active delegatee satisfies the requirement, false otherwise.
     */
    function hasVeriSoulAccess(address _potentialAccessor, uint256 _requiredTypeId, uint8 _minLevel) public view returns (bool) {
        // First, check if the accessor directly owns a valid VeriSoul
        (bool directActive, uint8 directLevel,) = checkSoulVeriSoulStatus(_potentialAccessor, _requiredTypeId);
        if (directActive && directLevel >= _minLevel) {
            return true;
        }

        // Second, check if the accessor is an active delegatee for any relevant VeriSoul
        // This requires iterating through all VeriSouls to find delegations to `_potentialAccessor`
        for (uint256 tokenId = 1; tokenId <= _tokenIdCounter.current(); tokenId++) {
            if (veriSouls[tokenId].typeId == _requiredTypeId) {
                Delegation storage delegation = veriSoulDelegations[tokenId][_potentialAccessor];
                if (delegation.delegatedAt != 0 && (delegation.duration == 0 || delegation.delegatedAt + delegation.duration > block.timestamp)) {
                    // Check the original VeriSoul's status (owned by the delegator)
                    (bool delegatedActive, uint8 delegatedLevel,) = checkSoulVeriSoulStatus(veriSouls[tokenId].owner, _requiredTypeId);
                    if (delegatedActive && delegatedLevel >= _minLevel) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    // --- ERC721 Overrides (for Soulbound/non-transferable behavior) ---

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * @dev Sets the base URI for all token IDs. This is typically a URL prefix
     *      where token metadata JSON files are hosted.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURIExtended = _newBaseURI;
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to prevent any transfers, making VeriSouls soulbound.
     *      Only allows minting (from == address(0)) or burning (to == address(0)).
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Only allow minting (from == address(0)) or burning (to == address(0))
        require(from == address(0) || to == address(0), "VeriSoulNexus: VeriSouls are non-transferable (soulbound)");
    }
}
```