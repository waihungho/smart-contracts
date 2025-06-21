Okay, let's design a smart contract concept around "Dynamic NFTs with Programmable State and User Reputation," which we'll call `ChronoEssenceNexus`. This incorporates NFTs, reputation systems, dynamic state based on interaction and time, and controlled access, going beyond typical static collectibles or basic utility tokens.

We will avoid direct duplication of OpenZeppelin's *implementation* details for common patterns like `Ownable` or `ERC721`'s internal `_grantRole`, `_transfer`, etc., by providing our own basic versions or focusing on the complex logic built *on top* of the standard interfaces. We will implement a custom Role-Based Access Control and Pausability system.

---

**Outline & Function Summary**

**Concept:** A decentralized system for owning and interacting with "Essences" (dynamic NFTs) that evolve based on user actions, time, and user reputation within the ecosystem. Users build reputation through constructive interactions, unlocking higher-level actions and influencing Essence development.

**Key Features:**

1.  **Dynamic Essences (NFTs):** ERC-721 tokens with mutable state variables (Level, State, Energy, Traits) that change over time or based on interactions.
2.  **Essence Types:** Pre-defined templates for Essences with base properties, definable by an admin role.
3.  **User Reputation:** A score tracked for each user, earned/lost based on their interactions.
4.  **Role-Based Access Control:** Custom implementation to manage permissions (Admin, Minter, Pauser, ParameterManager, TreasuryManager).
5.  **Pausability:** System pause mechanism controlled by a specific role.
6.  **Programmable Interactions:** Functions allowing users to interact with their own or *other* users' Essences (with permission), triggering state changes and reputation effects.
7.  **Time-Based Mechanics:** Essences can 'decay' or change state based on time elapsed since the last interaction.
8.  **Configurable Parameters:** Admin functions to adjust interaction costs, reputation effects, decay rates, etc.

**Structs:**

*   `Essence`: Represents a single dynamic NFT instance.
*   `UserData`: Stores user-specific data like reputation score and interaction permissions.
*   `EssenceType`: Defines templates for new Essences.

**Functions (20+):**

*   **ERC-721 Standard Functions (~8):** `balanceOf`, `ownerOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `safeTransferFrom`. (Implemented or stubbed to comply with interface).
*   **Essence Data & Views (~4):** `getEssenceDetails`, `getEssenceState`, `getEssenceTraits`, `getEssenceTypeDetails`.
*   **User Data & Views (~2):** `getUserReputation`, `getUserData`.
*   **Core Role Management (~4):** `grantRole`, `revokeRole`, `hasRole`, `getRoleAdmin`. (Custom implementation).
*   **Pausability (~3):** `pause`, `unpause`, `paused`. (Custom implementation).
*   **Admin & Configuration (~4):** `defineEssenceType`, `setParameter`, `setRoleAdmin`, `withdrawFees`.
*   **Minting (~1):** `mintEssence`.
*   **Interaction Permissions (~2):** `requestInteractionPermission`, `revokeInteractionPermission`.
*   **Dynamic Interactions (~7+):**
    *   `checkAndApplyDecay`: Internal helper applied before interactions/views to handle time-based decay.
    *   `chargeEssence`: User interacts with owned Essence to increase Energy.
    *   `cultivateEssence`: User interacts with owned Essence to influence Level/Traits.
    *   `evolveEssence`: Attempts to evolve an Essence based on conditions (Level, State, Reputation).
    *   `interactWithOtherEssence`: General function for permitted interactions with another user's Essence. Requires permission.
    *   `corruptEssence`: A potentially negative interaction (needs higher reputation?). Reduces Energy/State.
    *   `harmonizeEssences`: User interacts with *two* owned Essences to blend traits or energy.
    *   `extractEssence`: User sacrifices an Essence to gain resources or permanent reputation boost.

**Total Functions:** ~8 (ERC721) + 4 (Essence Views) + 2 (User Views) + 4 (Roles) + 3 (Pause) + 4 (Admin) + 1 (Mint) + 2 (Permissions) + 7 (Interactions) = **35+ Functions**. This comfortably exceeds the 20 function requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for ERC721 standard
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Custom Role-Based Access Control and Pausability
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract ChronoAccessControl is Context {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PARAMETER_MANAGER_ROLE = keccak256("PARAMETER_MANAGER_ROLE");
    bytes32 public constant TREASURY_MANAGER_ROLE = keccak256("TREASURY_MANAGER_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmins;

    bool private _paused;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event Paused(address account);
    event Unpaused(address account);

    constructor(address adminInitial) {
        _setupRole(ADMIN_ROLE, adminInitial);
        _roleAdmins[ADMIN_ROLE] = ADMIN_ROLE; // Admin role is managed by itself
        _roleAdmins[MINTER_ROLE] = ADMIN_ROLE;
        _roleAdmins[PAUSER_ROLE] = ADMIN_ROLE;
        _roleAdmins[PARAMETER_MANAGER_ROLE] = ADMIN_ROLE;
        _roleAdmins[TREASURY_MANAGER_ROLE] = ADMIN_ROLE;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function _setupRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roleAdmins[role], _msgSender()), "AccessControl: sender must be admin for role");
        _setupRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roleAdmins[role], _msgSender()), "AccessControl: sender must be admin for role");
        require(_roles[role][account], "AccessControl: account does not have role");
        _roles[role][account] = false;
        emit RoleRevoked(role, account, _msgSender());
    }

     function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        require(_roles[role][account], "AccessControl: account does not have role");
        _roles[role][account] = false;
        emit RoleRevoked(role, account, _msgSender());
    }


    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmins[role];
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "AccessControl: sender must be admin");
        bytes32 previousAdminRole = _roleAdmins[role];
        _roleAdmins[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public virtual whenNotPaused {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Pausable: must have pauser role");
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public virtual whenPaused {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Pausable: must have pauser role");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract ChronoEssenceNexus is IERC721, ChronoAccessControl {

    // --- Constants ---
    string private constant _name = "ChronoEssence";
    string private constant _symbol = "CE";
    uint256 private _currentTokenId = 0;

    // --- Enums ---
    enum EssenceState { Dormant, Active, Evolving, Depleted, Corrupted }

    // --- Structs ---
    struct Essence {
        uint256 id;
        uint256 typeId; // Index into essenceTypes array
        uint256 level;
        EssenceState state;
        uint256 energy;
        uint256[] traits; // Indices or values representing dynamic traits
        uint256 lastInteractionTimestamp;
    }

    struct UserData {
        int256 reputation; // Can be negative
        mapping(uint256 => bool) essenceInteractionPermissions; // tokenId => granted
    }

    struct EssenceType {
        string name;
        uint256 baseEnergy;
        uint256 initialLevel;
        uint256[] initialTraits;
        // Add other type-specific base properties
    }

    // --- State Variables ---
    mapping(uint256 => Essence) private _essences;
    mapping(address => UserData) private _users;
    mapping(uint256 => address) private _tokenOwners; // ERC721 owner mapping
    mapping(uint256 => address) private _tokenApprovals; // ERC721 approval mapping
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC721 operator approval mapping

    EssenceType[] private _essenceTypes; // Array of available essence types

    // Configurable parameters (Admin role)
    mapping(bytes32 => uint256) private _parameters;

    // --- Events ---
    event EssenceMinted(uint256 indexed tokenId, address indexed owner, uint256 typeId);
    event EssenceStateChanged(uint256 indexed tokenId, EssenceState newState, EssenceState oldState);
    event EssenceLevelChanged(uint256 indexed tokenId, uint256 newLevel);
    event EssenceEnergyChanged(uint256 indexed tokenId, uint256 newEnergy);
    event EssenceTraitsChanged(uint256 indexed tokenId, uint256[] newTraits);
    event UserReputationChanged(address indexed user, int256 newReputation, int256 reputationDelta);
    event InteractionPermissionGranted(uint256 indexed tokenId, address indexed granter, address indexed receiver);
    event InteractionPermissionRevoked(uint256 indexed tokenId, address indexed granter, address indexed receiver);
    event ParameterSet(bytes32 indexed paramKey, uint256 value);
    event FeesWithdrawn(address indexed treasury, uint256 amount);

    // --- Constructor ---
    constructor(address adminInitial) ChronoAccessControl(adminInitial) {}

    // --- ERC721 Implementation (Basic) ---

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        uint256 count = 0;
        // NOTE: A real implementation would track balances efficiently,
        // this is simplified for demonstration.
        uint256 currentMaxId = _currentTokenId; // Avoid state change issues during loop
        for (uint256 i = 1; i <= currentMaxId; i++) {
            if (_tokenOwners[i] == owner) {
                count++;
            }
        }
        return count;
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @dev Internal helper to check if a token exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

     /// @dev Internal helper to check if `spender` is approved or owner.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @dev Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner"); // ownerOf checks existence
        require(to != address(0), "ERC721: transfer to the zero address");

        _tokenApprovals[tokenId] = address(0); // Clear approval

        _tokenOwners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal mint logic
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwners[tokenId] = to; // Set owner

        emit Transfer(address(0), to, tokenId); // ERC721 Mint event is Transfer from address(0)

        require(_checkOnERC721Received(address(0), address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @dev Internal function to check if a contract is ERC721Receiver (basic check)
    function _checkOnERC721Received(address, address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // Transfer to non-contract address is always safe
        }
    }

    // --- IERC165 Interface (Stubbed) ---
    // Standard for checking supported interfaces. Not strictly required by prompt but good practice.
    // function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    //     return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    // }

    // Minimal IERC721Receiver interface for internal check
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }


    // --- Custom ChronoEssence Logic ---

    /// @dev Defines a new Essence Type. Only callable by PARAMETER_MANAGER_ROLE.
    /// @param _name Name of the type (e.g., "Basic Spark", "Mystic Orb").
    /// @param _baseEnergy Initial energy for Essences of this type.
    /// @param _initialLevel Initial level for Essences of this type.
    /// @param _initialTraits Initial traits for Essences of this type.
    function defineEssenceType(string memory _name, uint256 _baseEnergy, uint256 _initialLevel, uint256[] memory _initialTraits)
        public
        whenNotPaused
        onlyRole(PARAMETER_MANAGER_ROLE)
    {
        _essenceTypes.push(EssenceType(_name, _baseEnergy, _initialLevel, _initialTraits));
        // No event for simplicity, but could add one.
    }

    /// @dev Gets details for a specific Essence Type.
    /// @param typeId The index of the Essence Type.
    /// @return name, baseEnergy, initialLevel, initialTraits
    function getEssenceTypeDetails(uint256 typeId) public view returns (string memory, uint256, uint256, uint256[] memory) {
        require(typeId < _essenceTypes.length, "Chrono: invalid essence type ID");
        EssenceType storage et = _essenceTypes[typeId];
        return (et.name, et.baseEnergy, et.initialLevel, et.initialTraits);
    }

    /// @dev Mints a new Essence of a specific type. Only callable by MINTER_ROLE.
    /// @param to The recipient of the new Essence.
    /// @param typeId The type of Essence to mint.
    function mintEssence(address to, uint256 typeId)
        public
        whenNotPaused
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        require(to != address(0), "Chrono: mint to the zero address");
        require(typeId < _essenceTypes.length, "Chrono: invalid essence type ID");

        _currentTokenId++;
        tokenId = _currentTokenId;
        EssenceType storage et = _essenceTypes[typeId];

        _essences[tokenId] = Essence({
            id: tokenId,
            typeId: typeId,
            level: et.initialLevel,
            state: EssenceState.Dormant, // Start as dormant
            energy: et.baseEnergy,
            traits: et.initialTraits,
            lastInteractionTimestamp: block.timestamp // Initialize timestamp
        });

        _safeMint(to, tokenId, ""); // Use basic ERC721 internal mint logic

        emit EssenceMinted(tokenId, to, typeId);
    }

    /// @dev Gets details of a specific Essence NFT.
    /// @param tokenId The ID of the Essence.
    /// @return id, typeId, level, state, energy, traits, lastInteractionTimestamp
    function getEssenceDetails(uint256 tokenId)
        public
        view
        returns (uint256, uint256, uint256, EssenceState, uint256, uint256[] memory, uint256)
    {
        require(_exists(tokenId), "Chrono: Essence does not exist");
        Essence storage e = _essences[tokenId];
        return (e.id, e.typeId, e.level, e.state, e.energy, e.traits, e.lastInteractionTimestamp);
    }

    /// @dev Gets the current state of an Essence.
    /// @param tokenId The ID of the Essence.
    /// @return The current state.
    function getEssenceState(uint256 tokenId) public view returns (EssenceState) {
         require(_exists(tokenId), "Chrono: Essence does not exist");
         return _essences[tokenId].state;
    }

    /// @dev Gets the current traits of an Essence.
    /// @param tokenId The ID of the Essence.
    /// @return An array of trait values.
    function getEssenceTraits(uint256 tokenId) public view returns (uint256[] memory) {
         require(_exists(tokenId), "Chrono: Essence does not exist");
         return _essences[tokenId].traits;
    }

    /// @dev Gets the reputation score of a user.
    /// @param user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address user) public view returns (int256) {
        // Users start with 0 reputation implicitly if not in map
        return _users[user].reputation;
    }

     /// @dev Gets all user data (currently just reputation).
    /// @param user The address of the user.
    /// @return reputation score.
    function getUserData(address user) public view returns (int256) {
         return _users[user].reputation;
    }


    /// @dev Internal helper to update essence state and emit event.
    function _updateEssenceState(uint256 tokenId, EssenceState newState) internal {
        Essence storage e = _essences[tokenId];
        if (e.state != newState) {
            EssenceState oldState = e.state;
            e.state = newState;
            emit EssenceStateChanged(tokenId, newState, oldState);
        }
    }

    /// @dev Internal helper to update user reputation and emit event.
    function _updateUserReputation(address user, int256 delta) internal {
        if (delta != 0) {
            _users[user].reputation += delta;
            emit UserReputationChanged(user, _users[user].reputation, delta);
        }
    }

    /// @dev Internal helper to get a configurable parameter value. Returns 0 if not set.
    function _getParameter(bytes32 paramKey) internal view returns (uint256) {
        return _parameters[paramKey];
    }

    /// @dev Allows PARAMETER_MANAGER_ROLE to set configurable parameters.
    /// @param paramKey The key of the parameter (e.g., keccak256("CHARGE_REPUTATION_GAIN")).
    /// @param value The value to set.
    function setParameter(bytes32 paramKey, uint256 value) public whenNotPaused onlyRole(PARAMETER_MANAGER_ROLE) {
        _parameters[paramKey] = value;
        emit ParameterSet(paramKey, value);
    }

     /// @dev Internal helper to apply time decay to an essence based on elapsed time.
     /// Decay logic is simplified here (e.g., reduce energy).
     /// Could affect state, traits, etc.
     function _applyTimeDecay(uint256 tokenId) internal {
        Essence storage e = _essences[tokenId];
        uint256 timeElapsed = block.timestamp - e.lastInteractionTimestamp;
        uint256 decayRate = _getParameter(keccak256("TIME_DECAY_RATE")); // E.g., energy lost per second/hour

        if (decayRate > 0 && timeElapsed > 0) {
            uint256 energyDecay = (timeElapsed * decayRate) / (1 days); // Example: rate is daily
            if (energyDecay > e.energy) {
                energyDecay = e.energy;
            }
            e.energy -= energyDecay;
            emit EssenceEnergyChanged(tokenId, e.energy);

            // Example state change based on decay
            if (e.energy == 0 && e.state != EssenceState.Depleted) {
                 _updateEssenceState(tokenId, EssenceState.Depleted);
            }
             // Update timestamp *after* applying decay
             e.lastInteractionTimestamp = block.timestamp;
        }
     }

     /// @dev Helper function to check and apply decay before interactions or critical views.
     function checkAndApplyDecay(uint256 tokenId) internal {
         require(_exists(tokenId), "Chrono: Essence does not exist");
         _applyTimeDecay(tokenId);
     }


    /// @dev Allows owner to charge their Essence, increasing its energy.
    /// May cost something or require user reputation. Gives minor reputation gain.
    /// @param tokenId The ID of the Essence to charge.
    function chargeEssence(uint256 tokenId) public payable whenNotPaused {
        address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
        require(_msgSender() == essenceOwner, "Chrono: Caller must own the Essence");

        checkAndApplyDecay(tokenId); // Apply decay before action

        Essence storage e = _essences[tokenId];
        uint256 chargeCost = _getParameter(keccak256("CHARGE_COST"));
        require(msg.value >= chargeCost, "Chrono: Insufficient payment");

        uint256 energyGain = _getParameter(keccak256("CHARGE_ENERGY_GAIN"));
        int256 reputationGain = int256(_getParameter(keccak256("CHARGE_REPUTATION_GAIN")));

        e.energy += energyGain;
        e.lastInteractionTimestamp = block.timestamp;
        _updateEssenceState(tokenId, EssenceState.Active); // Charging makes it active

        _updateUserReputation(_msgSender(), reputationGain);

        emit EssenceEnergyChanged(tokenId, e.energy);

        // Refund excess payment
        if (msg.value > chargeCost) {
             payable(_msgSender()).transfer(msg.value - chargeCost);
        }
    }

    /// @dev Allows owner to cultivate their Essence, potentially influencing level or traits.
    /// Requires sufficient energy. Gives moderate reputation gain.
    /// @param tokenId The ID of the Essence to cultivate.
    function cultivateEssence(uint256 tokenId) public whenNotPaused {
        address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
        require(_msgSender() == essenceOwner, "Chrono: Caller must own the Essence");

        checkAndApplyDecay(tokenId); // Apply decay before action

        Essence storage e = _essences[tokenId];
        uint256 cultivationEnergyCost = _getParameter(keccak256("CULTIVATE_ENERGY_COST"));
        require(e.energy >= cultivationEnergyCost, "Chrono: Insufficient Essence energy");

        e.energy -= cultivationEnergyCost;
        e.lastInteractionTimestamp = block.timestamp;
         _updateEssenceState(tokenId, EssenceState.Active); // Cultivating keeps it active

        int256 reputationGain = int256(_getParameter(keccak256("CULTIVATE_REPUTATION_GAIN")));
        _updateUserReputation(_msgSender(), reputationGain);

        // Simple cultivation logic: Minor level gain chance or trait modification
        if (e.level < _getParameter(keccak256("MAX_ESSENCE_LEVEL"))) {
             e.level++; // Simplified: always gain level if below max
             emit EssenceLevelChanged(tokenId, e.level);
        }
        // Trait modification logic would go here...

        emit EssenceEnergyChanged(tokenId, e.energy);
    }

     /// @dev Attempts to evolve an Essence to the next stage.
     /// Requires minimum level, state, user reputation, and potentially consumes energy/items.
     /// Complex evolution logic would go here (e.g., depends on traits, other essences, etc.)
     /// @param tokenId The ID of the Essence to evolve.
     function evolveEssence(uint256 tokenId) public whenNotPaused {
        address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
        require(_msgSender() == essenceOwner, "Chrono: Caller must own the Essence");

        checkAndApplyDecay(tokenId); // Apply decay before action

        Essence storage e = _essences[tokenId];
        int256 userRep = _users[_msgSender()].reputation;
        uint256 requiredLevel = _getParameter(keccak256("EVOLVE_MIN_LEVEL"));
        int256 requiredReputation = int256(_getParameter(keccak256("EVOLVE_MIN_REPUTATION")));
        uint256 requiredEnergy = _getParameter(keccak256("EVOLVE_ENERGY_COST"));

        require(e.level >= requiredLevel, "Chrono: Essence level too low for evolution");
        require(userRep >= requiredReputation, "Chrono: User reputation too low for evolution");
        require(e.energy >= requiredEnergy, "Chrono: Insufficient Essence energy for evolution");
        require(e.state != EssenceState.Evolving, "Chrono: Essence is already evolving");
        require(e.state != EssenceState.Corrupted, "Chrono: Corrupted Essences cannot evolve");


        e.energy -= requiredEnergy;
        e.lastInteractionTimestamp = block.timestamp;
        _updateEssenceState(tokenId, EssenceState.Evolving); // Set state to Evolving

        int256 reputationGain = int256(_getParameter(keccak256("EVOLVE_INITIATE_REPUTATION_GAIN")));
        _updateUserReputation(_msgSender(), reputationGain);

        emit EssenceEnergyChanged(tokenId, e.energy);

        // A more complex evolution might trigger a time delay,
        // require external input (e.g., another tx), or depend on random factors.
        // For simplicity, we just set the state to Evolving here.
        // A separate function or internal logic on subsequent interactions could finalize evolution.
     }

     /// @dev Requests permission for another user to interact with a specific Essence owned by the caller.
     /// @param tokenId The ID of the Essence.
     /// @param receiver The address to grant permission to.
     function requestInteractionPermission(uint256 tokenId, address receiver) public whenNotPaused {
         address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
         require(_msgSender() == essenceOwner, "Chrono: Caller must own the Essence");
         require(receiver != address(0), "Chrono: Cannot grant permission to zero address");
         require(receiver != _msgSender(), "Chrono: Cannot grant permission to self");

         _users[_msgSender()].essenceInteractionPermissions[tokenId] = true;
         emit InteractionPermissionGranted(tokenId, _msgSender(), receiver);
     }

     /// @dev Revokes interaction permission previously granted to another user for a specific Essence.
     /// @param tokenId The ID of the Essence.
     /// @param receiver The address to revoke permission from.
     function revokeInteractionPermission(uint256 tokenId, address receiver) public whenNotPaused {
         address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
         require(_msgSender() == essenceOwner, "Chrono: Caller must own the Essence");
         require(receiver != address(0), "Chrono: Cannot revoke permission from zero address");

         _users[_msgSender()].essenceInteractionPermissions[tokenId] = false;
         emit InteractionPermissionRevoked(tokenId, _msgSender(), receiver);
     }

     /// @dev Allows a user (with permission) to interact with another user's Essence.
     /// Requires the owner to have granted permission via requestInteractionPermission.
     /// Specific interaction effects (e.g., Harmonize, Boost, Observe) would be handled inside based on parameters or subtypes.
     /// This is a generic function that can have varying effects.
     /// @param tokenId The ID of the target Essence.
     /// @param interactionType A value or key specifying the type of interaction.
     function interactWithOtherEssence(uint256 tokenId, uint256 interactionType) public payable whenNotPaused {
         address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
         address caller = _msgSender();

         // Check permission: Caller is owner OR Caller was granted permission
         require(caller == essenceOwner || _users[essenceOwner].essenceInteractionPermissions[tokenId],
             "Chrono: Caller does not have permission to interact with this Essence");

         checkAndApplyDecay(tokenId); // Apply decay before action

         Essence storage e = _essences[tokenId];

         bytes32 costParamKey = keccak256(abi.encodePacked("INTERACT_OTHER_COST_", interactionType));
         uint256 interactionCost = _getParameter(costParamKey);
         require(msg.value >= interactionCost, "Chrono: Insufficient payment for interaction");

         bytes32 repGainParamKey = keccak256(abi.encodePacked("INTERACT_OTHER_REP_GAIN_", interactionType));
         int256 callerReputationGain = int256(_getParameter(repGainParamKey));

         bytes32 ownerRepGainParamKey = keccak256(abi.encodePacked("INTERACT_OTHER_OWNER_REP_GAIN_", interactionType));
         int256 ownerReputationGain = int256(_getParameter(ownerRepGainParamKey));


         // Apply interaction effects (simplified based on type)
         if (interactionType == 1) { // Example: Harmonize
             uint256 energyBoost = _getParameter(keccak256("HARMONIZE_ENERGY_BOOST"));
             e.energy += energyBoost;
             _updateEssenceState(tokenId, EssenceState.Active); // Harmonizing makes it active
             _updateUserReputation(caller, callerReputationGain); // Interactor gains rep
             _updateUserReputation(essenceOwner, ownerReputationGain); // Owner gains rep
             emit EssenceEnergyChanged(tokenId, e.energy);

         } else if (interactionType == 2) { // Example: Observe (low cost, small rep gain)
             // Maybe reveal a hidden trait or slightly boost energy
             uint256 observeEnergyBoost = _getParameter(keccak256("OBSERVE_ENERGY_BOOST"));
             e.energy += observeEnergyBoost;
              _updateEssenceState(tokenId, EssenceState.Active);
             _updateUserReputation(caller, callerReputationGain);
              emit EssenceEnergyChanged(tokenId, e.energy);

         } else {
             revert("Chrono: Invalid interaction type");
         }

         e.lastInteractionTimestamp = block.timestamp; // Update timestamp after action

         // Refund excess payment
        if (msg.value > interactionCost) {
             payable(_msgSender()).transfer(msg.value - interactionCost);
        }
     }

    /// @dev Allows a user (with sufficient reputation) to attempt to corrupt an Essence.
    /// This is a negative interaction. Requires interaction permission or high negative reputation threshold?
    /// Decreases Essence energy/state and might penalize reputation of *both* users.
    /// Requires interaction permission from the owner.
    /// @param tokenId The ID of the target Essence.
    function corruptEssence(uint256 tokenId) public whenNotPaused {
        address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
        address caller = _msgSender();

        // Check permission: Caller must have permission (owner allows this 'harmful' interaction explicitly)
        require(_users[essenceOwner].essenceInteractionPermissions[tokenId],
            "Chrono: Caller does not have permission to interact with this Essence");

        checkAndApplyDecay(tokenId); // Apply decay before action

        Essence storage e = _essences[tokenId];
        int256 requiredReputation = int256(_getParameter(keccak256("CORRUPT_MIN_REPUTATION")));
         // Require caller to have minimum (possibly negative) reputation to do this
         require(_users[caller].reputation >= requiredReputation, "Chrono: Caller reputation too high or too low to Corrupt"); // Example: requires highly negative reputation or specific trait

        uint256 corruptionEnergyCost = _getParameter(keccak256("CORRUPT_ENERGY_COST")); // Energy removed from Essence
        int256 callerReputationPenalty = int256(_getParameter(keccak256("CORRUPT_CALLER_REP_PENALTY")));
        int256 ownerReputationPenalty = int256(_getParameter(keccak256("CORRUPT_OWNER_REP_PENALTY"))); // Owner also penalized?

        require(e.energy > 0, "Chrono: Essence has no energy to corrupt"); // Cannot corrupt a depleted essence

        if (e.energy > corruptionEnergyCost) {
            e.energy -= corruptionEnergyCost;
        } else {
            e.energy = 0;
             _updateEssenceState(tokenId, EssenceState.Corrupted); // Corrupt if energy hits 0
        }

        e.lastInteractionTimestamp = block.timestamp; // Update timestamp
        _updateUserReputation(caller, callerReputationPenalty);
        _updateUserReputation(essenceOwner, ownerReputationPenalty);

        emit EssenceEnergyChanged(tokenId, e.energy);
    }

    /// @dev Allows a user to combine the energies/traits of two owned Essences.
    /// Consumes one Essence, boosts the other. Gives moderate reputation.
    /// @param tokenIdToBoost The ID of the Essence that receives the boost.
    /// @param tokenIdToConsume The ID of the Essence that is consumed.
    function harmonizeEssences(uint256 tokenIdToBoost, uint256 tokenIdToConsume) public whenNotPaused {
        address caller = _msgSender();
        require(ownerOf(tokenIdToBoost) == caller, "Chrono: Caller must own boost target Essence");
        require(ownerOf(tokenIdToConsume) == caller, "Chrono: Caller must own consume target Essence");
        require(tokenIdToBoost != tokenIdToConsume, "Chrono: Cannot harmonize an Essence with itself");

        checkAndApplyDecay(tokenIdToBoost);
        checkAndApplyDecay(tokenIdToConsume);

        Essence storage boostEssence = _essences[tokenIdToBoost];
        Essence storage consumeEssence = _essences[tokenIdToConsume];

        // Logic: Transfer energy and potentially some traits from consume to boost
        uint256 energyTransferAmount = consumeEssence.energy; // Transfer all energy
        boostEssence.energy += energyTransferAmount;

        // Example Trait Transfer (simplified): Add traits from consumed, avoid duplicates
        for (uint256 i = 0; i < consumeEssence.traits.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < boostEssence.traits.length; j++) {
                if (boostEssence.traits[j] == consumeEssence.traits[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                boostEssence.traits.push(consumeEssence.traits[i]);
            }
        }

        boostEssence.lastInteractionTimestamp = block.timestamp;
         _updateEssenceState(tokenIdToBoost, EssenceState.Active); // Harmonizing makes it active

        // Burn the consumed Essence NFT
        _burn(tokenIdToConsume);

        int256 reputationGain = int256(_getParameter(keccak256("HARMONIZE_REPUTATION_GAIN")));
        _updateUserReputation(caller, reputationGain);

        emit EssenceEnergyChanged(tokenIdToBoost, boostEssence.energy);
        emit EssenceTraitsChanged(tokenIdToBoost, boostEssence.traits);
        // Burn event is handled by _burn -> _transfer(owner, address(0), tokenId)
    }

     /// @dev Allows a user to permanently destroy an Essence to gain a resource or a permanent reputation boost.
     /// The Essence is burned.
     /// @param tokenId The ID of the Essence to extract.
     function extractEssence(uint256 tokenId) public whenNotPaused {
         address essenceOwner = ownerOf(tokenId); // Reverts if token doesn't exist
         require(_msgSender() == essenceOwner, "Chrono: Caller must own the Essence");
         require(e.state != EssenceState.Evolving, "Chrono: Cannot extract an evolving Essence");


         checkAndApplyDecay(tokenId); // Apply decay before extraction logic

         Essence storage e = _essences[tokenId];

         // Extraction logic: Gain resources based on level, state, energy, traits
         uint256 extractedResourceAmount = e.energy + (e.level * 10) + (e.traits.length * 5); // Example calculation
         int256 reputationGain = int256(_getParameter(keccak256("EXTRACT_REPUTATION_GAIN")));

         // Grant user resources (not implemented here, but would interact with another token/system)
         // For this contract, only reputation is affected directly.
         _updateUserReputation(_msgSender(), reputationGain);

         // Burn the Essence
         _burn(tokenId);

         // Emit event indicating resource extraction (optional)
         // emit ResourceExtracted(_msgSender(), extractedResourceAmount, e.typeId);
     }

     /// @dev Internal helper to burn a token.
     function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Checks existence
        _tokenApprovals[tokenId] = address(0); // Clear approval

        delete _tokenOwners[tokenId]; // Remove owner
        // Note: Essence data in _essences mapping is NOT deleted, for historical lookups.
        // A more gas-efficient approach might clean up some data.

        emit Transfer(owner, address(0), tokenId); // ERC721 Burn event is Transfer to address(0)
     }


    /// @dev Allows TREASURY_MANAGER_ROLE to withdraw collected ETH fees.
    /// @param amount The amount to withdraw.
    /// @param treasuryReceiver The address to send the funds to.
    function withdrawFees(uint256 amount, address payable treasuryReceiver)
        public
        whenNotPaused
        onlyRole(TREASURY_MANAGER_ROLE)
    {
        require(address(this).balance >= amount, "Chrono: Insufficient contract balance");
        require(treasuryReceiver != address(0), "Chrono: Cannot withdraw to zero address");

        treasuryReceiver.transfer(amount);
        emit FeesWithdrawn(treasuryReceiver, amount);
    }

    /// @dev Gets the current ETH balance of the contract.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Modifiers for Custom Access Control ---
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), string(abi.encodePacked("AccessControl: account ", _msgSender(), " is missing role ", role)));
        _;
    }

    // Fallback function to receive ETH
    receive() external payable {
        // Optional: Log event or add received ETH to a counter
    }

    fallback() external payable {
        // Optional: Handle unexpected calls, maybe revert
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFT State (`Essence` struct):** Unlike most NFTs where metadata is static or points to a static file, `ChronoEssence` NFTs have mutable on-chain properties (`level`, `state`, `energy`, `traits`). These change based on contract logic.
2.  **Essence State Machine (`EssenceState` enum):** Essences transition between states (`Dormant`, `Active`, `Evolving`, `Depleted`, `Corrupted`) based on interactions and time. This creates a more game-like or simulation-like element.
3.  **User Reputation System (`UserData`, `reputation`):** The contract tracks a reputation score for each user, which can be positive or negative. Reputation gates access to certain advanced interactions (like `evolveEssence` or potentially `corruptEssence`). Interactions grant or penalize reputation, creating a feedback loop based on user behavior within the ecosystem.
4.  **Interaction Permissioning (`essenceInteractionPermissions`):** Users can explicitly grant or revoke permission for *specific* NFTs to *other users* to perform interactions like `interactWithOtherEssence` or `corruptEssence`. This adds a layer of social/permissioned interaction between owners, not just owner-to-NFT.
5.  **Time-Based Decay (`lastInteractionTimestamp`, `_applyTimeDecay`):** Essences degrade over time if not interacted with. This encourages active participation and prevents stagnation, a common issue with static collectibles. The decay logic is applied *when* an interaction or critical view occurs, rather than constantly running (which is impossible on-chain).
6.  **Programmable Interaction Types (`chargeEssence`, `cultivateEssence`, `evolveEssence`, `interactWithOtherEssence`, `corruptEssence`, `harmonizeEssences`, `extractEssence`):** A variety of distinct functions allow users to influence Essences in different ways, each with unique rules, costs, and effects on Essence state and user reputation. `interactWithOtherEssence` demonstrates a generic pattern where the *type* of interaction can be passed as a parameter to a single function, allowing for future expansion.
7.  **Configurable Parameters (`_parameters`, `setParameter`):** Key game/system parameters (costs, gains, thresholds, rates) are not hardcoded constants but stored in a mapping and adjustable by a specific role. This allows for tuning the system without needing to deploy a new contract.
8.  **Custom Role-Based Access Control and Pausability:** While the *concept* exists in OpenZeppelin, this contract implements a basic version of these features from scratch (or simulates it, focusing on the `require(hasRole(...))` pattern), fulfilling the "don't duplicate open source" constraint on implementation details.

This contract provides a framework for a complex, interactive, and evolving digital ecosystem built on NFTs and user engagement. It's a starting point, and a production system would require more sophisticated state management, potentially off-chain computation for complex trait generation, and robust security audits.