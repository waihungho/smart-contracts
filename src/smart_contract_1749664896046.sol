Okay, let's design a smart contract that goes beyond typical token or simple DeFi contracts. We'll create a "ChronoCreatures" contract – a dynamic NFT where creatures have lifecycle stages, stats that change based on actions and time, can breed, go on missions, and are slightly influenced by external data (simulated by an oracle update). This combines concepts like dynamic NFTs, on-chain state changes, gamification mechanics, breeding, missions, and basic oracle interaction.

To avoid duplicating open source *implementations* directly, we will implement the necessary interfaces (like `IERC721`, `IAccessControl`, `IPausable`) manually rather than inheriting from OpenZeppelin contracts directly, while adhering to their standards.

Here's the contract outline and the code:

---

**Contract Outline & Summary: ChronoCreatures**

This smart contract implements a dynamic Non-Fungible Token (NFT) standard (`ERC-721`) representing digital "Creatures". Each creature has a unique identity and a set of dynamic attributes (stats, lifecycle stage) that change over time and based on user interactions.

**Key Concepts & Features:**

1.  **Dynamic Attributes:** Creatures possess stats like Level, Hunger, Mood, Strength, Intelligence, Constitution, Experience, etc. These are stored on-chain and change.
2.  **Lifecycle Stages:** Creatures progress through stages (Egg, Hatchling, Adult, Elder, Retired) based on time and actions.
3.  **User Interactions:** Owners can "Feed", "Play", "Train", "Level Up", "Evolve", and "Mutate" their creatures, affecting their stats and lifecycle.
4.  **Time-Based Decay/Growth:** Stats like Hunger and Mood decay over time, while Experience might accumulate passively or require user action. A general `updateCreatureLifecycle` function allows users to trigger these time-dependent calculations.
5.  **Breeding:** Adult creatures meeting certain criteria can be bred together by their owner to produce a new Egg token, introducing a reproduction mechanic.
6.  **Missions:** Creatures can be assigned to missions. Mission success depends on creature stats and a probabilistic outcome, yielding rewards or penalties after a set duration.
7.  **Simulated Oracle Influence:** The contract includes a function (`updateGlobalWeather`) that can be called by a designated role (simulating an oracle) to update a global state variable (`currentWeather`) which subtly influences creature mood or mission outcomes.
8.  **Access Control & Pausability:** Utilizes role-based access control for administrative functions and allows pausing contract interactions.
9.  **Fee Mechanism:** Fees can be associated with actions (like breeding) and collected by authorized accounts.
10. **Manual Interface Implementation:** Core standards like ERC-721, AccessControl, and Pausability are implemented manually to avoid direct inheritance from common libraries like OpenZeppelin, fulfilling the "don't duplicate open source" requirement for the *implementation* details while adhering to the *interfaces*.

**Function Summary (Public/External Functions):**

*   **ERC-721 Standard Functions (Implemented):**
    1.  `balanceOf(address owner)`: Get the balance of a specific owner.
    2.  `ownerOf(uint256 tokenId)`: Get the owner of a token.
    3.  `approve(address to, uint256 tokenId)`: Approve transfer for a specific token.
    4.  `getApproved(uint256 tokenId)`: Get the approved address for a token.
    5.  `setApprovalForAll(address operator, bool approved)`: Set operator approval for all tokens.
    6.  `isApprovedForAll(address owner, address operator)`: Check operator approval status.
    7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token.
    8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer.
    9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
    10. `tokenURI(uint256 tokenId)`: Get metadata URI for a token.
    11. `totalSupply()`: Get the total supply of tokens.

*   **Creature Management & Interaction Functions:**
    12. `mintCreature(address to)`: Mint a new creature (Egg stage) to an address. (Requires MINT_ROLE).
    13. `getCreatureStats(uint256 tokenId)`: Get the detailed stats of a creature.
    14. `getCreatureLifecycleState(uint256 tokenId)`: Get the current lifecycle stage of a creature.
    15. `feedCreature(uint256 tokenId)`: Feed the creature (reduces hunger, affects mood).
    16. `playWithCreature(uint256 tokenId)`: Play with the creature (improves mood, gains exp).
    17. `trainCreature(uint256 tokenId)`: Train the creature (improves stats, costs something or has cooldown).
    18. `levelUpCreature(uint256 tokenId)`: Level up creature if enough experience is accumulated.
    19. `evolveCreature(uint256 tokenId)`: Evolve creature if conditions are met (e.g., level, stage).
    20. `mutateCreature(uint256 tokenId)`: Trigger a random mutation on the creature (rare, potentially requires item/fee).
    21. `updateCreatureLifecycle(uint256 tokenId)`: Trigger time-based state updates (decay, potential stage progression).
    22. `breedCreatures(uint256 parent1Id, uint256 parent2Id)`: Breed two parent creatures to create a new one (requires fee, cooldowns).
    23. `getBreedingCooldown(uint256 tokenId)`: Get the breeding cooldown end time for a creature.
    24. `assignMission(uint256 tokenId, uint256 missionId)`: Assign a creature to a mission (requires creature stats, sets state).
    25. `completeMission(uint256 tokenId)`: Finalize a mission, calculate outcome, distribute rewards/penalties.
    26. `getMissionOutcomeProbability(uint256 tokenId, uint256 missionId)`: Calculate the success probability for a mission based on creature stats.
    27. `getCreatureMood(uint256 tokenId)`: Calculate the creature's current mood based on stats and global weather.
    28. `updateGlobalWeather(uint256 weatherData)`: Update the global weather state (Requires ORACLE_ROLE).

*   **Administrative & Utility Functions:**
    29. `setPausability(bool state)`: Pause or unpause contract interactions (Requires PAUSER_ROLE).
    30. `setBreedingFee(uint256 feeAmount)`: Set the fee for breeding (Requires ADMIN_ROLE).
    31. `setMaxBreedingSupply(uint256 maxSupply)`: Set the maximum number of creatures that can be created via breeding (Requires ADMIN_ROLE).
    32. `initializeMission(uint256 missionId, string name, uint256 duration, uint256 requiredStrength, uint256 successProbabilityBase, string rewardItem)`: Define a new mission (Requires ADMIN_ROLE).
    33. `getMissionDetails(uint256 missionId)`: Get the details of a defined mission.
    34. `withdrawContractBalance(address payable recipient)`: Withdraw collected fees/balance (Requires ADMIN_ROLE).
    35. `getContractBalance()`: Get the current balance held by the contract.
    36. `grantRole(bytes32 role, address account)`: Grant a role to an account (Requires DEFAULT_ADMIN_ROLE or role admin).
    37. `revokeRole(bytes32 role, address account)`: Revoke a role from an account (Requires DEFAULT_ADMIN_ROLE or role admin).
    38. `hasRole(bytes32 role, address account)`: Check if an account has a specific role.
    39. `renounceRole(bytes32 role, address account)`: Renounce a role (Requires the account itself).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC721.sol"; // Assume this interface is defined based on ERC-721 standard
import "./IAccessControl.sol"; // Assume this interface is defined based on AccessControl standard
import "./IPausable.sol"; // Assume this interface is defined based on Pausable standard

// --- Outline & Summary ---
// (Outline and Summary provided above the contract code block)
// --- End Outline & Summary ---


// --- Define Interfaces Manually (as per prompt) ---

// Basic ERC721 Interface - Implemented Manually
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
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ERC721Metadata extension
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Basic AccessControl Interface - Implemented Manually
interface IAccessControl {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

// Basic Pausable Interface - Implemented Manually
interface IPausable {
    event Paused(address account);
    event Unpaused(address account);

    function paused() external view returns (bool);
}

// --- ReentrancyGuard Implementation Manually ---
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// --- Pausable Implementation Manually ---
abstract contract Pausable is IPausable {
    bool private _paused;

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view virtual override returns (bool) {
        return _paused;
    }

    function _setPausability(bool state) internal virtual {
        if (state && !_paused) {
            _paused = true;
            emit Paused(msg.sender);
        } else if (!state && _paused) {
            _paused = false;
            emit Unpaused(msg.sender);
        }
    }
}

// --- AccessControl Implementation Manually ---
abstract contract AccessControl is IAccessControl {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    mapping(bytes32 role => mapping(address account => bool)) private _roles;
    mapping(bytes32 role => bytes32 adminRole) private _roleAdmins;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role][account];
    }

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roleAdmins[role];
    }

    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), msg.sender), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), msg.sender), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roleAdmins[role] = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}


// --- ChronoCreatures Contract ---

contract ChronoCreatures is IERC721, AccessControl, Pausable, ReentrancyGuard {

    // --- Constants and Roles ---
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd; // ERC721 interface ID
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; // ERC721Metadata interface ID
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7; // ERC165 interface ID
    bytes4 private constant _INTERFACE_ID_ACCESS_CONTROL = 0x7965db0b; // AccessControl interface ID
    bytes4 private constant _INTERFACE_ID_PAUSABLE = 0x8456cb59; // Pausable interface ID

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // General admin role for settings
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // Role for updating external data

    // --- State Variables ---
    string private _name = "ChronoCreatures";
    string private _symbol = "CTC";
    string private _creatureBaseURI;

    uint256 private _tokenIdCounter; // Starts at 1 for the first token
    uint256 private _totalSupplyCount;

    // ERC721 state mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Creature Specific Data
    enum LifecycleState { Egg, Hatchling, Adult, Elder, Retired }
    enum ElementalType { Normal, Fire, Water, Earth, Air } // Example elemental types

    struct CreatureStats {
        uint256 level;
        uint256 hunger; // 0-100, 0 is full, 100 is starving
        uint256 mood; // 0-100, 100 is happy, 0 is sad
        uint256 strength;
        uint256 intelligence;
        uint256 constitution;
        ElementalType elementalType;
        uint256 experience; // For leveling up
        uint256 lastFedTime;
        uint256 lastPlayedTime;
        uint256 lastTrainedTime;
        uint256 breedingCooldownEnds; // Timestamp when breeding is possible again
        uint256 currentMissionId; // 0 if not on a mission
        uint256 missionCompletionTime; // Timestamp when mission ends
    }

    mapping(uint256 => CreatureStats) private _creatureStats;
    mapping(uint256 => LifecycleState) private _creatureLifecycleState;

    // Mission Data
    struct Mission {
        string name;
        uint256 duration; // in seconds
        uint256 requiredStrength; // Minimum strength recommended
        uint256 successProbabilityBase; // Base probability (0-1000 for 0-100.0%)
        string rewardItem; // Placeholder for item identifier
    }
    mapping(uint256 => Mission) private _missions;
    uint256 private _missionCounter = 1; // Start mission IDs from 1

    // Contract Settings & Economy
    uint256 private _breedingFee = 0.01 ether; // Example fee in native currency
    uint256 private _maxBreedingSupply = 10000; // Limit for creatures from breeding
    uint256 private _bredCreatureCount;
    uint256 private _globalWeather; // Example state variable influenced by oracle

    // --- Events ---
    event CreatureMinted(uint256 indexed tokenId, address indexed owner, ElementalType elementType);
    event CreatureStateUpdated(uint256 indexed tokenId, string attribute, uint256 newValue);
    event CreatureLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event CreatureEvolved(uint256 indexed tokenId, LifecycleState newState);
    event CreatureMutated(uint256 indexed tokenId);
    event CreatureBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event MissionAssigned(uint256 indexed tokenId, uint256 indexed missionId, uint256 completionTime);
    event MissionCompleted(uint256 indexed tokenId, uint256 indexed missionId, bool success);
    event GlobalWeatherUpdated(uint256 newWeather);
    event BreedingFeeUpdated(uint256 newFee);

    // --- Constructor ---
    constructor() AccessControl() Pausable() ReentrancyGuard() {
        // Set up roles: Default admin has all roles initially
        _setRoleAdmin(MINT_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);

        // Grant creator initial roles
        _grantRole(MINT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);

        // Initialize the token counter
        _tokenIdCounter = 0;
        _totalSupplyCount = 0;
        _bredCreatureCount = 0;
        _globalWeather = 50; // Default weather state
    }

    // --- Standard ERC721 Implementation ---

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721_METADATA ||
               interfaceId == _INTERFACE_ID_ERC165;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // This should ideally return a URL pointing to JSON metadata
        // For this example, we'll return a base URI + token ID, or an empty string if base URI is not set.
        if (bytes(_creatureBaseURI).length == 0) {
            return ""; // Or a default URI
        }
        // In a real implementation, this would include dynamic data based on stats
        return string(abi.encodePacked(_creatureBaseURI, _toString(tokenId)));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupplyCount;
    }

    // Internal ERC721 helper functions
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId); // Clear approvals
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes calldata data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to]++;
        _owners[tokenId] = to;
        _totalSupplyCount++;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

     function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId); // Cheks if it exists

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId); // Clear approvals
        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId];
        _totalSupplyCount--;

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // ERC721Receiver check
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) {
            return true; // EOA recipient
        }
        // Call onERC721Received in the recipient contract
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
             return retval == _ERC721_RECEIVED;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                // Revert with custom message from target
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // Hooks that can be overridden by derived contracts (not needed for this example, but good practice)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // Basic integer to string conversion (for tokenURI)
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Creature Management & Interaction Functions ---

    /**
     * @notice Mints a new creature (in Egg stage) to a recipient.
     * @param to The address to mint the creature to.
     */
    function mintCreature(address to) public virtual nonReentrant whenNotPaused {
        require(hasRole(MINT_ROLE, msg.sender), "ChronoCreatures: Must have MINT_ROLE to mint");
        require(to != address(0), "ChronoCreatures: Cannot mint to zero address");

        _tokenIdCounter++; // Get next token ID
        uint256 newTokenId = _tokenIdCounter;

        // Initialize creature stats and lifecycle
        _creatureStats[newTokenId] = CreatureStats({
            level: 1,
            hunger: 50, // Medium hunger initially
            mood: 70,   // Fairly happy initially
            strength: _generateInitialStat(),
            intelligence: _generateInitialStat(),
            constitution: _generateInitialStat(),
            elementalType: _generateRandomElementalType(),
            experience: 0,
            lastFedTime: block.timestamp,
            lastPlayedTime: block.timestamp,
            lastTrainedTime: block.timestamp,
            breedingCooldownEnds: 0,
            currentMissionId: 0,
            missionCompletionTime: 0
        });
        _creatureLifecycleState[newTokenId] = LifecycleState.Egg;

        _mint(to, newTokenId); // Mint the NFT

        emit CreatureMinted(newTokenId, to, _creatureStats[newTokenId].elementalType);
    }

    /**
     * @notice Gets the detailed stats of a creature.
     * @param tokenId The ID of the creature token.
     * @return CreatureStats struct containing all stats.
     */
    function getCreatureStats(uint256 tokenId) public view virtual returns (CreatureStats memory) {
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        return _creatureStats[tokenId];
    }

    /**
     * @notice Gets the current lifecycle stage of a creature.
     * @param tokenId The ID of the creature token.
     * @return The current LifecycleState.
     */
    function getCreatureLifecycleState(uint256 tokenId) public view virtual returns (LifecycleState) {
         require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
         return _creatureLifecycleState[tokenId];
    }


    /**
     * @notice Feeds a creature, reducing hunger and slightly boosting mood. Has a cooldown.
     * @param tokenId The ID of the creature token.
     */
    function feedCreature(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");
        require(stats.lastFedTime + 1 hours < block.timestamp, "ChronoCreatures: Creature was fed recently");
        require(_creatureLifecycleState[tokenId] != LifecycleState.Egg && _creatureLifecycleState[tokenId] != LifecycleState.Retired, "ChronoCreatures: Creature cannot be fed in this state");

        uint256 oldHunger = stats.hunger;
        uint256 oldMood = stats.mood;

        stats.hunger = (stats.hunger > 30) ? stats.hunger - 30 : 0; // Reduce hunger significantly
        stats.mood = (stats.mood < 90) ? stats.mood + 10 : 100; // Increase mood slightly
        stats.lastFedTime = block.timestamp;

        emit CreatureStateUpdated(tokenId, "hunger", stats.hunger);
        emit CreatureStateUpdated(tokenId, "mood", stats.mood);
    }

    /**
     * @notice Plays with a creature, boosting mood and gaining experience. Has a cooldown.
     * @param tokenId The ID of the creature token.
     */
    function playWithCreature(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");
        require(stats.lastPlayedTime + 1 hours < block.timestamp, "ChronoCreatures: Creature was played with recently");
         require(_creatureLifecycleState[tokenId] != LifecycleState.Egg && _creatureLifecycleState[tokenId] != LifecycleState.Retired, "ChronoCreatures: Creature cannot be played with in this state");


        uint256 oldMood = stats.mood;
        uint256 oldExp = stats.experience;

        stats.mood = (stats.mood < 80) ? stats.mood + 20 : 100; // Increase mood
        stats.experience += 15; // Gain experience
        stats.lastPlayedTime = block.timestamp;

        emit CreatureStateUpdated(tokenId, "mood", stats.mood);
        emit CreatureStateUpdated(tokenId, "experience", stats.experience);
    }

    /**
     * @notice Trains a creature, improving stats and potentially costing something (simulated by cooldown).
     * @param tokenId The ID of the creature token.
     */
    function trainCreature(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");
        require(stats.lastTrainedTime + 6 hours < block.timestamp, "ChronoCreatures: Creature was trained recently");
         require(_creatureLifecycleState[tokenId] != LifecycleState.Egg && _creatureLifecycleState[tokenId] != LifecycleState.Retired, "ChronoCreatures: Creature cannot be trained in this state");

        // Determine which stat to improve - could be random or based on type
        uint256 statToImprove = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp))) % 3; // 0:Str, 1:Int, 2:Const
        uint256 statGain = 1; // Base gain

        if (statToImprove == 0) {
            stats.strength += statGain;
            emit CreatureStateUpdated(tokenId, "strength", stats.strength);
        } else if (statToImprove == 1) {
            stats.intelligence += statGain;
            emit CreatureStateUpdated(tokenId, "intelligence", stats.intelligence);
        } else {
            stats.constitution += statGain;
            emit CreatureStateUpdated(tokenId, "constitution", stats.constitution);
        }

        stats.lastTrainedTime = block.timestamp;
        stats.experience += 10; // Also gain some exp
        emit CreatureStateUpdated(tokenId, "experience", stats.experience);
    }

    /**
     * @notice Attempts to level up a creature if it has enough experience.
     * @param tokenId The ID of the creature token.
     */
    function levelUpCreature(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");
        require(_creatureLifecycleState[tokenId] != LifecycleState.Egg && _creatureLifecycleState[tokenId] != LifecycleState.Retired, "ChronoCreatures: Creature cannot level up in this state");

        uint256 expRequired = stats.level * 100; // Simple exp requirement formula
        if (stats.experience >= expRequired) {
            stats.level++;
            stats.experience -= expRequired; // Consume exp
            // Optionally boost stats on level up
            stats.strength += 1;
            stats.intelligence += 1;
            stats.constitution += 1;

            emit CreatureLeveledUp(tokenId, stats.level);
            emit CreatureStateUpdated(tokenId, "experience", stats.experience);
        } else {
             revert("ChronoCreatures: Not enough experience to level up");
        }
    }

    /**
     * @notice Attempts to evolve a creature if conditions (like level, stage duration) are met.
     * @param tokenId The ID of the creature token.
     */
    function evolveCreature(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");

        LifecycleState currentState = _creatureLifecycleState[tokenId];
        LifecycleState nextState = currentState; // Default is no change

        // Simple evolution conditions based on level and current state
        if (currentState == LifecycleState.Egg && block.timestamp > stats.lastFedTime + 24 hours) { // Egg hatches after 24h (lastFedTime is creation time)
            nextState = LifecycleState.Hatchling;
        } else if (currentState == LifecycleState.Hatchling && stats.level >= 5) {
            nextState = LifecycleState.Adult;
        } else if (currentState == LifecycleState.Adult && stats.level >= 20) {
            nextState = LifecycleState.Elder;
        } else {
            revert("ChronoCreatures: Evolution conditions not met");
        }

        if (nextState != currentState) {
            _creatureLifecycleState[tokenId] = nextState;
            // Potentially grant stat boosts or change appearance logic here
            emit CreatureEvolved(tokenId, nextState);
        }
    }

     /**
     * @notice Triggers a random mutation on the creature. Requires specific conditions (e.g., low mood, specific item, or just rare chance).
     * This is a conceptual function - implementation of randomness is simplified.
     * @param tokenId The ID of the creature token.
     */
    function mutateCreature(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");
        require(_creatureLifecycleState[tokenId] != LifecycleState.Egg && _creatureLifecycleState[tokenId] != LifecycleState.Retired, "ChronoCreatures: Creature cannot mutate in this state");
        // Example condition: requires low mood and some rare event/item (simplified here)
        require(stats.mood < 30, "ChronoCreatures: Mood must be low to mutate");
        // Simulate randomness - NOT cryptographically secure
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, msg.sender)));
        require(rand % 100 < 5, "ChronoCreatures: Mutation failed (rare chance)"); // 5% chance

        // Apply random stat changes
        uint256 statToMutate = rand % 3; // 0:Str, 1:Int, 2:Const
        int256 changeAmount = (rand % 2 == 0) ? int256(rand % 5 + 1) : -int256(rand % 3 + 1); // Random +/- change

         if (statToMutate == 0) {
            stats.strength = uint256(int256(stats.strength) + changeAmount);
            emit CreatureStateUpdated(tokenId, "strength", stats.strength);
        } else if (statToMutate == 1) {
            stats.intelligence = uint256(int256(stats.intelligence) + changeAmount);
            emit CreatureStateUpdated(tokenId, "intelligence", stats.intelligence);
        } else {
            stats.constitution = uint256(int256(stats.constitution) + changeAmount);
             emit CreatureStateUpdated(tokenId, "constitution", stats.constitution);
        }

        emit CreatureMutated(tokenId);
    }


    /**
     * @notice Updates time-dependent aspects of a creature's state (hunger, mood decay, potential lifecycle progression).
     * This can be called by anyone to trigger updates.
     * @param tokenId The ID of the creature token.
     */
    function updateCreatureLifecycle(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is on a mission");
         require(_creatureLifecycleState[tokenId] != LifecycleState.Retired, "ChronoCreatures: Creature is retired");

        uint256 timeElapsed = block.timestamp - stats.lastFedTime; // Simplified - use different time points for different decays
        uint256 decayAmount = timeElapsed / 6 hours; // Decay every 6 hours

        if (decayAmount > 0) {
            stats.hunger = (stats.hunger + decayAmount > 100) ? 100 : stats.hunger + decayAmount;
            stats.mood = (stats.mood > decayAmount) ? stats.mood - decayAmount : 0;
            stats.lastFedTime = block.timestamp; // Reset last fed time for next decay calculation
             emit CreatureStateUpdated(tokenId, "hunger", stats.hunger);
             emit CreatureStateUpdated(tokenId, "mood", stats.mood);
        }

        // Check for lifecycle progression that happens purely over time (e.g., Egg hatching checked in evolveCreature)
        // Other lifecycle stages might decay stats if not cared for (e.g., mood hits 0 -> sickness, potential death in a more complex version)

        // Also, potentially accumulate passive experience if certain conditions met
        // if (_creatureLifecycleState[tokenId] == LifecycleState.Adult && stats.mood > 50) {
        //     stats.experience += (block.timestamp - stats.lastPlayedTime) / 1 days; // Gain 1 exp per day happy
        //     stats.lastPlayedTime = block.timestamp; // Reset for passive exp
        // }
    }

    /**
     * @notice Breeds two creatures, creating a new Egg token. Requires breeding fee and cooldowns.
     * @param parent1Id The ID of the first parent creature token.
     * @param parent2Id The ID of the second parent creature token.
     */
    function breedCreatures(uint256 parent1Id, uint256 parent2Id) public payable virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, parent1Id), "ChronoCreatures: Not owner or approved for parent1");
        require(_isApprovedOrOwner(msg.sender, parent2Id), "ChronoCreatures: Not owner or approved for parent2");
        require(parent1Id != parent2Id, "ChronoCreatures: Cannot breed a creature with itself");

        CreatureStats storage stats1 = _creatureStats[parent1Id];
        CreatureStats storage stats2 = _creatureStats[parent2Id];

        require(_creatureLifecycleState[parent1Id] == LifecycleState.Adult && _creatureLifecycleState[parent2Id] == LifecycleState.Adult, "ChronoCreatures: Both parents must be Adult");
        require(stats1.breedingCooldownEnds <= block.timestamp, "ChronoCreatures: Parent1 is on breeding cooldown");
        require(stats2.breedingCooldownEnds <= block.timestamp, "ChronoCreatures: Parent2 is on breeding cooldown");
        require(stats1.currentMissionId == 0 && stats2.currentMissionId == 0, "ChronoCreatures: Parents cannot be on mission");
        require(_bredCreatureCount < _maxBreedingSupply, "ChronoCreatures: Breeding supply limit reached");
        require(msg.value >= _breedingFee, "ChronoCreatures: Insufficient breeding fee");

        // Transfer fee to contract balance
        // No explicit transfer needed if payable function receives it

        _tokenIdCounter++; // Get next token ID for child
        uint256 childTokenId = _tokenIdCounter;

        // Generate child stats (simple average + small random variation)
        uint256 randSeed = uint256(keccak256(abi.encodePacked(parent1Id, parent2Id, block.timestamp, msg.sender)));
        CreatureStats memory childStats = CreatureStats({
            level: 1,
            hunger: 50,
            mood: 70,
            strength: (_generateChildStat(stats1.strength, stats2.strength, randSeed + 1)),
            intelligence: (_generateChildStat(stats1.intelligence, stats2.intelligence, randSeed + 2)),
            constitution: (_generateChildStat(stats1.constitution, stats2.constitution, randSeed + 3)),
            elementalType: _generateChildElementalType(stats1.elementalType, stats2.elementalType, randSeed + 4),
            experience: 0,
            lastFedTime: block.timestamp, // Treat creation time as last fed
            lastPlayedTime: block.timestamp,
            lastTrainedTime: block.timestamp,
            breedingCooldownEnds: 0, // Egg cannot breed
            currentMissionId: 0,
            missionCompletionTime: 0
        });

        _creatureStats[childTokenId] = childStats;
        _creatureLifecycleState[childTokenId] = LifecycleState.Egg;

        // Set breeding cooldowns on parents (e.g., 7 days)
        stats1.breedingCooldownEnds = block.timestamp + 7 days;
        stats2.breedingCooldownEnds = block.timestamp + 7 days;

        _bredCreatureCount++;
        _mint(msg.sender, childTokenId); // Mint child to the caller

        emit CreatureBred(parent1Id, parent2Id, childTokenId);
    }

    /**
     * @notice Gets the timestamp when a creature's breeding cooldown ends.
     * @param tokenId The ID of the creature token.
     * @return The timestamp when the creature can breed again.
     */
    function getBreedingCooldown(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        return _creatureStats[tokenId].breedingCooldownEnds;
    }


    /**
     * @notice Assigns a creature to a mission.
     * @param tokenId The ID of the creature token.
     * @param missionId The ID of the mission to assign.
     */
    function assignMission(uint256 tokenId, uint256 missionId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        require(_missions[missionId].duration > 0, "ChronoCreatures: Mission does not exist or is not initialized");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId == 0, "ChronoCreatures: Creature is already on a mission");
        require(_creatureLifecycleState[tokenId] == LifecycleState.Adult || _creatureLifecycleState[tokenId] == LifecycleState.Elder, "ChronoCreatures: Creature cannot go on missions in this state");

        stats.currentMissionId = missionId;
        stats.missionCompletionTime = block.timestamp + _missions[missionId].duration;

        emit MissionAssigned(tokenId, missionId, stats.missionCompletionTime);
    }

    /**
     * @notice Completes a mission for a creature that has finished it. Calculates outcome.
     * @param tokenId The ID of the creature token.
     */
    function completeMission(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoCreatures: Not owner or approved");
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        CreatureStats storage stats = _creatureStats[tokenId];
        require(stats.currentMissionId != 0, "ChronoCreatures: Creature is not on a mission");
        require(block.timestamp >= stats.missionCompletionTime, "ChronoCreatures: Mission is not yet complete");

        uint256 missionId = stats.currentMissionId;
        Mission memory mission = _missions[missionId];

        // Calculate success probability based on stats and weather
        uint256 successProb = getMissionOutcomeProbability(tokenId, missionId); // 0-1000

        // Simulate randomness for outcome - NOT cryptographically secure
        uint256 outcomeRoll = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, msg.sender))) % 1001; // 0-1000

        bool success = outcomeRoll <= successProb;

        if (success) {
            // Apply success rewards (e.g., exp, stat boost, maybe a reward token/item)
            stats.experience += mission.duration / 60; // Simple exp reward (1 exp per minute)
            // Example: if (bytes(mission.rewardItem).length > 0) { _distributeRewardItem(msg.sender, mission.rewardItem); }
            emit CreatureStateUpdated(tokenId, "experience", stats.experience);
        } else {
            // Apply failure penalties (e.g., stat decrease, hunger/mood penalty)
             stats.mood = (stats.mood > 20) ? stats.mood - 20 : 0;
             stats.hunger = (stats.hunger < 80) ? stats.hunger + 20 : 100;
             emit CreatureStateUpdated(tokenId, "mood", stats.mood);
             emit CreatureStateUpdated(tokenId, "hunger", stats.hunger);
            // Example: if (bytes(mission.failurePenalty).length > 0) { _applyPenalty(msg.sender, mission.failurePenalty); }
        }

        // Reset mission state
        stats.currentMissionId = 0;
        stats.missionCompletionTime = 0;

        emit MissionCompleted(tokenId, missionId, success);
    }

     /**
     * @notice Calculates the success probability for a mission based on creature stats and global weather.
     * @param tokenId The ID of the creature token.
     * @param missionId The ID of the mission.
     * @return Success probability out of 1000 (0-100.0%).
     */
    function getMissionOutcomeProbability(uint256 tokenId, uint256 missionId) public view virtual returns (uint256) {
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        require(_missions[missionId].duration > 0, "ChronoCreatures: Mission does not exist or is not initialized");

        CreatureStats memory stats = _creatureStats[tokenId];
        Mission memory mission = _missions[missionId];

        // Base probability from mission definition
        uint256 probability = mission.successProbabilityBase; // 0-1000

        // Adjust based on creature's primary relevant stat (e.g., Strength for combat missions)
        // Simple linear scaling: +1% probability per point above requiredStrength, up to a cap
        if (stats.strength > mission.requiredStrength) {
            uint256 bonus = (stats.strength - mission.requiredStrength) * 10; // +10 points per stat point = +1%
             probability = (probability + bonus > 1000) ? 1000 : probability + bonus;
        } else if (stats.strength < mission.requiredStrength) {
             uint256 penalty = (mission.requiredStrength - stats.strength) * 5; // -0.5% per stat point below
             probability = (probability > penalty) ? probability - penalty : 0;
        }

        // Adjust based on mood (e.g., happy creatures perform better)
        // Mood affects probability: -20% if mood < 30, +10% if mood > 80
        uint256 moodModifier = 0;
        if (stats.mood < 30) {
             moodModifier = 200; // -20%
             probability = (probability > moodModifier) ? probability - moodModifier : 0;
        } else if (stats.mood > 80) {
             moodModifier = 100; // +10%
             probability = (probability + moodModifier > 1000) ? 1000 : probability + moodModifier;
        }

        // Adjust based on global weather (Example: Fire types perform better in hot weather)
        // Assuming weather is 0-100. 50 is neutral.
        // If weather > 70 (hot) and elemental type is Fire: +5% prob
        // If weather < 30 (cold) and elemental type is Water: +5% prob
        // ... etc.
        uint256 weatherModifier = 0;
        if (_globalWeather > 70 && stats.elementalType == ElementalType.Fire) weatherModifier = 50;
        else if (_globalWeather < 30 && stats.elementalType == ElementalType.Water) weatherModifier = 50;
        // Add more type/weather interactions
        probability = (probability + weatherModifier > 1000) ? 1000 : probability + weatherModifier;


        return probability;
    }

     /**
     * @notice Calculates the creature's current mood taking into account hunger, mood stat, and weather.
     * @param tokenId The ID of the creature token.
     * @return The calculated mood (0-100).
     */
    function getCreatureMood(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "ChronoCreatures: Creature does not exist");
        CreatureStats memory stats = _creatureStats[tokenId];

        // Start with base mood stat
        uint256 currentMood = stats.mood;

        // Penalize heavily for high hunger
        if (stats.hunger > 70) {
            currentMood = (currentMood > 30) ? currentMood - 30 : 0;
        } else if (stats.hunger > 40) {
             currentMood = (currentMood > 10) ? currentMood - 10 : 0;
        }

        // Adjust based on weather (Example: Fire types dislike Watery weather)
        // Assuming weather 0-100 (0-20 Cold, 20-40 Wet, 40-60 Normal, 60-80 Sunny, 80-100 Hot)
        if (_globalWeather > 20 && _globalWeather <= 40 && stats.elementalType == ElementalType.Fire) { // Wet weather, Fire type
            currentMood = (currentMood > 15) ? currentMood - 15 : 0;
        } else if (_globalWeather > 80 && stats.elementalType == ElementalType.Water) { // Hot weather, Water type
             currentMood = (currentMood > 15) ? currentMood - 15 : 0;
        } // Add more interactions...


        // Ensure mood stays within bounds
        return (currentMood > 100) ? 100 : currentMood;
    }


    // --- Oracle Integration (Simulated) ---

    /**
     * @notice Updates the global weather state. Can only be called by accounts with ORACLE_ROLE.
     * @param weatherData An integer representing the new weather state (e.g., 0-100 scale).
     */
    function updateGlobalWeather(uint256 weatherData) public virtual nonReentrant {
        require(hasRole(ORACLE_ROLE, msg.sender), "ChronoCreatures: Must have ORACLE_ROLE to update weather");
        require(weatherData <= 100, "ChronoCreatures: Weather data must be between 0 and 100");

        _globalWeather = weatherData;
        emit GlobalWeatherUpdated(weatherData);
    }

    // --- Administrative & Utility Functions ---

    /**
     * @notice Sets the pausable state of the contract. Can only be called by accounts with PAUSER_ROLE.
     * @param state True to pause, false to unpause.
     */
    function setPausability(bool state) public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "ChronoCreatures: Must have PAUSER_ROLE to set pausable state");
        _setPausability(state);
    }

    /**
     * @notice Sets the base URI for creature token metadata. Can only be called by accounts with ADMIN_ROLE.
     * @param baseURI The new base URI.
     */
    function setCreatureBaseURI(string memory baseURI) public virtual {
        require(hasRole(ADMIN_ROLE, msg.sender), "ChronoCreatures: Must have ADMIN_ROLE to set base URI");
        _creatureBaseURI = baseURI;
    }

    /**
     * @notice Sets the fee required to breed creatures. Can only be called by accounts with ADMIN_ROLE.
     * @param feeAmount The new breeding fee in native currency (wei).
     */
    function setBreedingFee(uint256 feeAmount) public virtual {
        require(hasRole(ADMIN_ROLE, msg.sender), "ChronoCreatures: Must have ADMIN_ROLE to set breeding fee");
        _breedingFee = feeAmount;
        emit BreedingFeeUpdated(feeAmount);
    }

    /**
     * @notice Sets the maximum number of creatures that can be created via breeding. Can only be called by accounts with ADMIN_ROLE.
     * @param maxSupply The new maximum breeding supply.
     */
    function setMaxBreedingSupply(uint256 maxSupply) public virtual {
        require(hasRole(ADMIN_ROLE, msg.sender), "ChronoCreatures: Must have ADMIN_ROLE to set max breeding supply");
        _maxBreedingSupply = maxSupply;
    }

    /**
     * @notice Defines or updates a mission's details. Can only be called by accounts with ADMIN_ROLE.
     * @param missionId The ID of the mission (0 for new, or existing ID).
     * @param name The name of the mission.
     * @param duration The duration of the mission in seconds.
     * @param requiredStrength Recommended strength for the mission.
     * @param successProbabilityBase Base probability of success (0-1000).
     * @param rewardItem Placeholder string for reward item.
     */
    function initializeMission(uint256 missionId, string memory name, uint256 duration, uint256 requiredStrength, uint256 successProbabilityBase, string memory rewardItem) public virtual {
         require(hasRole(ADMIN_ROLE, msg.sender), "ChronoCreatures: Must have ADMIN_ROLE to initialize missions");
         require(duration > 0, "ChronoCreatures: Mission duration must be positive");
         require(successProbabilityBase <= 1000, "ChronoCreatures: Base probability must be <= 1000");

         uint256 idToUse = missionId;
         if (idToUse == 0) {
             _missionCounter++;
             idToUse = _missionCounter;
         } else {
             require(_missions[idToUse].duration > 0, "ChronoCreatures: Mission ID must be 0 for new or existing");
         }

         _missions[idToUse] = Mission(
             name,
             duration,
             requiredStrength,
             successProbabilityBase,
             rewardItem
         );
    }

     /**
     * @notice Gets the details of a defined mission.
     * @param missionId The ID of the mission.
     * @return Mission struct containing mission details.
     */
    function getMissionDetails(uint256 missionId) public view virtual returns (Mission memory) {
        require(_missions[missionId].duration > 0, "ChronoCreatures: Mission does not exist");
        return _missions[missionId];
    }


    /**
     * @notice Allows an admin to withdraw accumulated contract balance (e.g., breeding fees).
     * @param payable recipient The address to send the balance to.
     */
    function withdrawContractBalance(address payable recipient) public virtual nonReentrant {
        require(hasRole(ADMIN_ROLE, msg.sender), "ChronoCreatures: Must have ADMIN_ROLE to withdraw");
        require(recipient != address(0), "ChronoCreatures: Cannot withdraw to zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "ChronoCreatures: Contract has no balance");

        (bool success, ) = recipient.call{value: balance}("");
        require(success, "ChronoCreatures: Withdrawal failed");
    }

    /**
     * @notice Gets the current native currency balance held by the contract.
     * @return The contract's balance in wei.
     */
    function getContractBalance() public view virtual returns (uint256) {
        return address(this).balance;
    }

    // --- Internal Helper Functions ---

    // Basic pseudo-random initial stat generation (NOT cryptographically secure)
    function _generateInitialStat() internal view returns (uint256) {
        // Generates a stat between 1 and 10 based on block properties and timestamp
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, msg.sender))) % 10 + 1;
    }

     // Basic pseudo-random elemental type generation (NOT cryptographically secure)
    function _generateRandomElementalType() internal view returns (ElementalType) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tx.gasprice))) % 5; // 5 types
        return ElementalType(rand);
    }

    // Basic child stat generation from parents with some random variation
    function _generateChildStat(uint256 stat1, uint256 stat2, uint256 seed) internal view returns (uint256) {
        uint256 avg = (stat1 + stat2) / 2;
         // Add/subtract small random variation (0-2) based on seed
        uint256 variation = uint256(keccak256(abi.encodePacked(block.timestamp, seed))) % 3; // 0, 1, or 2
        bool add = uint256(keccak256(abi.encodePacked(block.timestamp, seed * 2))) % 2 == 0;

        if (add) {
            return avg + variation;
        } else {
             return avg > variation ? avg - variation : avg;
        }
    }

    // Basic child elemental type generation (e.g., 50% chance inheriting one parent, 50% hybrid/random)
    function _generateChildElementalType(ElementalType type1, ElementalType type2, uint256 seed) internal view returns (ElementalType) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, seed))) % 100;
        if (rand < 40) return type1; // 40% type1
        if (rand < 80) return type2; // 40% type2
        return _generateRandomElementalType(); // 20% random new type
    }

    // --- ERC721Receiver Interface (Placeholder - required if contract ever receives NFTs) ---
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual returns (bytes4) {
    //    // Implement logic if this contract needs to receive ERC721 tokens
    //    return _ERC721_RECEIVED;
    // }
}

// Define the IERC721Receiver interface required for safe transfers
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```

**Explanation of Concepts and Advanced Aspects:**

1.  **Dynamic NFTs (State Changes):** The core `CreatureStats` struct and `_creatureLifecycleState` mapping represent on-chain state that changes over time (`lastFedTime`, `lastPlayedTime`, `breedingCooldownEnds`, `missionCompletionTime`) and through user interactions (`feedCreature`, `playWithCreature`, `trainCreature`, `levelUpCreature`, `evolveCreature`, `mutateCreature`). This is more complex than static NFT metadata.
2.  **Lifecycle Management:** The `LifecycleState` enum and the `updateCreatureLifecycle` function introduce a temporal element where creatures mature or decay based on time and interaction frequency. `evolveCreature` provides explicit stage transitions.
3.  **Gamification Mechanics:** Hunger/Mood decay, Experience accumulation, Leveling, Training, Missions, and Breeding introduce game-like loops and incentives for interaction.
4.  **On-chain Calculations:** Functions like `getCreatureMood` and `getMissionOutcomeProbability` perform calculations based on multiple on-chain state variables (`stats`, `_globalWeather`).
5.  **Breeding Mechanism:** `breedCreatures` is a complex function requiring multiple checks (ownership, approval, lifecycle state, cooldowns, supply limits, payment) and results in the creation of a new token whose initial stats are derived from the parents with some variability.
6.  **Mission System:** `assignMission` and `completeMission` manage a creature's "busy" state and involve a probabilistic outcome calculation (`getMissionOutcomeProbability`) based on stats and external factors, culminating in on-chain rewards/penalties.
7.  **Simulated Oracle Interaction:** `updateGlobalWeather` demonstrates how external data (provided by a trusted oracle role) can influence on-chain logic (e.g., affecting mood or mission success probability). This is a common pattern in more advanced dApps needing real-world data.
8.  **Role-Based Access Control:** Using `AccessControl` (implemented manually) for functions like minting, pausing, updating settings, and the oracle feed provides fine-grained permissions, a standard advanced security practice.
9.  **Pausability:** Implementing `Pausable` (manually) allows contract administrators to halt sensitive operations in emergencies.
10. **Manual Implementation:** Implementing `IERC721`, `IAccessControl`, `IPausable`, `ReentrancyGuard`, and basic utilities (`_toString`, `_checkOnERC721Received`) without inheriting from standard libraries requires deeper understanding of the underlying logic and interfaces, fulfilling the "don't duplicate open source" requirement for the *implementation code itself*, while still conforming to established *standards* and *patterns*. This is more complex and gas-intensive than using optimized library implementations but demonstrates the ability to build from primitives.
11. **ReentrancyGuard:** Included manually to prevent reentrancy attacks on functions that might interact with external contracts or handle payments (`withdrawContractBalance`, `breedCreatures`).
12. **Pseudo-Randomness:** While true randomness is difficult on-chain, the contract uses common (though vulnerable to sophisticated miners) techniques based on block data and timestamps for initial stats, mutations, and mission outcomes. A real-world dApp would use Chainlink VRF or similar.
13. **Structs and Enums:** Extensive use of structs (`CreatureStats`, `Mission`) and enums (`LifecycleState`, `ElementalType`) helps organize complex data structures.

This contract provides a foundation for a complex, interactive NFT ecosystem with various features beyond simple ownership and transfer. It includes significantly more than 20 *distinct* public/external functions, covering core standard operations, unique creature mechanics, and necessary administrative controls.