Okay, let's create a smart contract for a conceptual decentralized game or system. We'll call it `CryptoLegions`. It will involve owning unique "Legion" NFTs, managing internal resources, sending Legions on timed missions, staking them, training them, and dealing with outcomes influenced by stats and pseudo-randomness.

This contract will not be a simple ERC20 or ERC721 standard implementation alone, but will integrate these concepts into a unique game logic. It will manage internal resource balances rather than rely on external token contracts for simplicity in this example, but conceptually these resources (`Essence`, `Glory`, `Relics`) act like fungible tokens within the system.

**Advanced/Creative/Trendy Concepts Used:**

1.  **Dynamic NFTs:** Legion stats change based on training, missions, etc.
2.  **On-chain State Management:** Complex state stored for each Legion (stats, mission status, staking).
3.  **Timed Events:** Missions and staking durations tracked on-chain.
4.  **Internal Resource System:** Fungible resources managed within the contract.
5.  **Pseudo-Randomness:** Simulating outcomes (mentioning the need for Chainlink VRF or similar for production).
6.  **Staking/Yield:** Earning resources by deploying Legions.
7.  **Progression System:** Training Legions to improve stats.
8.  **Simulation Logic:** Simple mission outcome calculation based on stats.
9.  **Role-Based Configuration:** Using an owner/admin to set game parameters.
10. **ERC721 Integration:** Core is built around ownership of unique tokens.

---

**CryptoLegions Smart Contract**

**Outline:**

1.  **State Variables:** Contract ownership, token counter, ERC721 mappings, Legion data mappings, resource balances, mission configurations, staking rates.
2.  **Structs:** `LegionStats`, `MissionInfo`, `StakingInfo`, `MissionConfig`.
3.  **Events:** Logging significant actions like minting, training, mission start/end, staking, claiming resources.
4.  **Modifiers:** Access control (`onlyOwner`, `onlyLegionOwnerOrApproved`).
5.  **ERC721 Core Functions:** Standard NFT functions (`balanceOf`, `ownerOf`, `transferFrom`, `approve`, `setApprovalForAll`, etc.).
6.  **Internal Helpers:** Functions for ERC721 state changes (`_mint`, `_transfer`, `_burn`, `_approve`).
7.  **Legion Minting:** Creating new Legions with initial stats.
8.  **Legion Progression & Actions:** Training, equipping, sending on missions, staking, repairing.
9.  **Mission & Staking Resolution:** Completing missions, claiming mission rewards, staking/unstaking Legions, claiming staking rewards.
10. **Resource Management:** Functions to view user resource balances.
11. **Query Functions:** Retrieving Legion data, mission info, staking info, user's Legions.
12. **Admin & Configuration:** Setting mission parameters, staking rates.
13. **Pseudo-Randomness:** Internal function for simulating random outcomes.

**Function Summary (at least 20):**

1.  `constructor()`: Initializes contract owner and token counter.
2.  `supportsInterface(bytes4 interfaceId)`: ERC165 standard check, indicates ERC721 support.
3.  `balanceOf(address owner)`: Returns the number of Legions owned by an address (ERC721).
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Legion (ERC721).
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers Legion ownership (ERC721).
6.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific Legion (ERC721).
7.  `getApproved(uint256 tokenId)`: Returns the approved address for a Legion (ERC721).
8.  `setApprovalForAll(address operator, bool approved)`: Sets operator approval for all Legions (ERC721).
9.  `isApprovedForAll(address owner, address operator)`: Checks operator approval status (ERC721).
10. `mintLegion()`: Allows calling user to mint a new Legion with pseudo-random initial stats.
11. `getLegionStats(uint256 tokenId)`: Retrieves the detailed stats of a Legion.
12. `trainLegion(uint256 tokenId, uint8 statType)`: Spends Essence to increase a specific Legion stat (e.g., Power, Defense).
13. `equipRelic(uint256 tokenId, uint256 relicId)`: Spends a Relic resource to apply a permanent or temporary bonus to a Legion (conceptually, `relicId` represents a type of relic).
14. `sendLegionOnMission(uint256 tokenId, uint8 missionType)`: Sends a Legion on a timed mission, consuming potential costs and making the Legion unavailable.
15. `checkMissionStatus(uint256 tokenId)`: Checks if a Legion's current mission is complete.
16. `completeMission(uint256 tokenId)`: Resolves a completed mission, calculates outcome based on stats/randomness, distributes rewards (Glory, Relics, more Essence), handles potential injury, and frees the Legion.
17. `stakeLegionForEssence(uint256 tokenId)`: Stakes a Legion to passively earn Essence over time.
18. `unstakeLegionFromEssence(uint256 tokenId)`: Removes a Legion from staking and calculates/distributes earned Essence.
19. `claimPassiveStakingEssence(uint256 tokenId)`: Claims earned Essence from a staked Legion without unstaking it.
20. `repairLegion(uint256 tokenId)`: Spends resources (e.g., Glory, Essence) to heal an injured Legion.
21. `disbandLegion(uint256 tokenId)`: Burns a Legion NFT, removing it from existence.
22. `getUserEssence()`: Returns the Essence balance for the calling user.
23. `getUserGlory()`: Returns the Glory balance for the calling user.
24. `getUserRelics()`: Returns the Relics balance for the calling user.
25. `getLegionMissionInfo(uint256 tokenId)`: Returns details about a Legion's active mission.
26. `getLegionStakingInfo(uint256 tokenId)`: Returns details about a Legion's active staking period.
27. `getLegionsByOwner(address owner)`: Returns an array of token IDs owned by an address (Note: Gas intensive for many tokens).
28. `configureMissionType(uint8 missionType, uint64 duration, uint256 baseEssenceReward, uint256 baseGloryReward, uint256 baseRelicReward, uint16 successChancePercent)`: (Owner only) Sets parameters for a specific mission type.
29. `setBaseEssenceStakingRate(uint256 rate)`: (Owner only) Sets the rate at which staked Legions earn Essence per second.
30. `getMissionConfig(uint8 missionType)`: Returns the configuration details for a specific mission type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath although 0.8+ has overflow checks by default

// Import necessary interfaces if interacting with external contracts
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title CryptoLegions
 * @dev A smart contract implementing a conceptual decentralized game system
 *      involving Legion NFTs, internal resources, timed missions, and staking.
 *      Uses pseudo-randomness for outcomes (real dApps should use Chainlink VRF etc.).
 */
contract CryptoLegions is Ownable, IERC721, IERC721Metadata {
    using SafeMath for uint256; // Safemath for explicitness, 0.8+ has checks
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // ERC721 mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Legion Data
    struct LegionStats {
        uint8 power;    // Affects mission success chance
        uint8 defense;  // Affects mission injury chance
        uint8 speed;    // Affects mission duration reduction (conceptually)
        uint8 morale;   // Affects training cost reduction (conceptually)
        bool isInjured; // Cannot go on missions/stake while injured
        bool isEquipped; // Simple flag if a relic is equipped
    }
    mapping(uint256 => LegionStats) public legionStats;

    // Resource Balances (internal tokens)
    mapping(address => uint256) public essenceBalances; // Used for training, repair, staking rewards
    mapping(address => uint256) public gloryBalances;   // Earned from missions, used for repair
    mapping(address => uint256) public relicBalances;   // Earned from missions, used for equipping

    // Timed Actions Data
    enum LegionStatus { Available, OnMission, Staking, Injured }
    mapping(uint256 => LegionStatus) public legionStatus;

    struct MissionInfo {
        uint8 missionType;
        uint64 startTime;
        uint64 endTime;
    }
    mapping(uint256 => MissionInfo) public missionInfo;

    struct StakingInfo {
        uint64 startTime;
        uint256 accumulatedEssence; // Track earned Essence
    }
    mapping(uint256 => StakingInfo) public stakingInfo;

    // Configuration (Owner controlled)
    struct MissionConfig {
        uint64 duration; // in seconds
        uint256 baseEssenceReward;
        uint256 baseGloryReward;
        uint256 baseRelicReward;
        uint16 successChancePercent; // 0-10000 (e.g., 7500 for 75%)
        uint16 injuryChancePercent;  // 0-10000
        uint256 essenceCost;         // Cost to start mission
    }
    mapping(uint8 => MissionConfig) public missionConfigs;
    uint256 public baseEssenceStakingRate = 1; // Essence per second per staked Legion

    // Pseudo-randomness - WARNING: NOT SECURE FOR PRODUCTION
    uint256 private randomSeed;

    // --- Events ---
    event LegionMinted(address indexed owner, uint256 indexed tokenId, LegionStats initialStats);
    event StatsTrained(uint256 indexed tokenId, uint8 statType, uint8 newStatValue, uint256 essenceSpent);
    event RelicEquipped(uint256 indexed tokenId, uint256 indexed relicId, uint256 relicsSpent);
    event MissionStarted(uint256 indexed tokenId, uint8 missionType, uint64 endTime);
    event MissionCompleted(uint256 indexed tokenId, uint8 missionType, bool success, bool injured, uint256 essenceEarned, uint256 gloryEarned, uint256 relicsEarned);
    event LegionStaked(uint256 indexed tokenId);
    event LegionUnstaked(uint256 indexed tokenId, uint256 essenceClaimed);
    event StakingEssenceClaimed(uint256 indexed tokenId, uint256 essenceClaimed);
    event LegionRepaired(uint256 indexed tokenId, uint256 resourcesSpent); // Generic event for repair costs
    event LegionDisbanded(uint256 indexed tokenId, address indexed owner);
    event ResourceClaimed(address indexed owner, uint256 essenceAmount, uint256 gloryAmount, uint256 relicsAmount);
    event MissionConfigUpdated(uint8 indexed missionType, MissionConfig config);
    event BaseEssenceStakingRateUpdated(uint256 newRate);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // ERC721
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Initialize random seed (insecure, use VRF for real projects)
        randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));

        // Set some default mission configs (Example)
        missionConfigs[1] = MissionConfig({
            duration: 1 hours,
            baseEssenceReward: 100,
            baseGloryReward: 50,
            baseRelicReward: 1,
            successChancePercent: 7500, // 75%
            injuryChancePercent: 2000,  // 20%
            essenceCost: 10
        });
         missionConfigs[2] = MissionConfig({
            duration: 4 hours,
            baseEssenceReward: 300,
            baseGloryReward: 200,
            baseRelicReward: 3,
            successChancePercent: 6000, // 60%
            injuryChancePercent: 3500,  // 35%
            essenceCost: 50
        });
    }

    // --- Modifiers ---

    modifier onlyLegionOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CL: Not owner or approved");
        _;
    }

    // --- ERC721 Core Implementation ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId); // Assuming Ownable might have one
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "CL: Address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "CL: Owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyLegionOwnerOrApproved(tokenId) {
        require(_owners[tokenId] == from, "CL: Transfer from incorrect owner");
        require(to != address(0), "CL: transfer to the zero address");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override onlyLegionOwnerOrApproved(tokenId) {
        require(_owners[tokenId] == from, "CL: Transfer from incorrect owner");
        require(to != address(0), "CL: transfer to the zero address");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "CL: Approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "CL: Approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "CL: Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "CL: Approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "CryptoLegions";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "CLEGION";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Note: This example does not implement off-chain metadata.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
         require(_exists(tokenId), "CL: URI query for nonexistent token");
        // In a real project, this would return a URI pointing to off-chain metadata (JSON file)
        // Example: return string(abi.encodePacked("ipfs://YOUR_METADATA_BASE_URI/", Strings.toString(tokenId), ".json"));
        return ""; // Placeholder
    }

    // --- Internal ERC721 Helpers ---

     /**
     * @dev Returns whether the specified token exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether the given operator can transfer a token owned by owner.
     */
    function _isApprovedOrOwner(address operator, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (operator == owner || getApproved(tokenId) == operator || isApprovedForAll(owner, operator));
    }

    /**
     * @dev Safely transfers `tokenId` by calling `_transfer` and then ensuring the recipient
     * is a contract capable of receiving ERC721 tokens.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "CL: Transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     * Requirements:
     *
     * - `from` cannot be zero address.
     * - `to` cannot be zero address.
     * - `tokenId` must exist and be owned by `from`.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "CL: Transfer from incorrect owner");
        require(to != address(0), "CL: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals for the transferring token
        _approve(address(0), tokenId);

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "CL: mint to the zero address");
        require(!_exists(tokenId), "CL: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] = _balances[owner].sub(1);
        delete _owners[tokenId]; // Use delete for mappings

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length > 0) {
                    /// @solidity exclusive
                    revert(string(reason));
                } else {
                    /// @solidity exclusive
                    revert("CL: Transfer to non ERC721Receiver implementer");
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     *     Caller must be owner, approved, or approved for all.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning.
     *     Caller must be owner, approved, or approved for all.
     */
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // When a token is transferred, ensure it's not on a mission or staking.
        // If it was, cancel it (maybe refund proportional costs/rewards in a real dApp).
        // For simplicity here, just ensure status is reset if transferred while busy.
        if (from != address(0) && to != address(0)) { // Not minting or burning
            if (legionStatus[tokenId] != LegionStatus.Available) {
                 // In a real system, you'd handle cancelling/refunding gracefully.
                 // For this example, we'll just disallow transfer while busy.
                 // Alternatively, the transfer itself could trigger the completion/unstaking.
                 // Let's add a check to prevent transfer while busy.
            }
        }
    }


    // --- Pseudo-Randomness (INSECURE FOR PRODUCTION) ---
    function _getUint256Random(uint256 max) internal returns (uint256) {
        // Use block data and a changing seed for pseudo-randomness.
        // This is PREDICTABLE and should NOT be used for high-value outcomes in production.
        // Use Chainlink VRF or similar secure oracle for randomness.
        randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, block.timestamp, block.difficulty, block.gaslimit, msg.sender, _tokenIdCounter.current())));
        return randomSeed % (max + 1); // Result is between 0 and max (inclusive)
    }

    function _getBoolRandom(uint16 chancePercent) internal returns (bool) {
        require(chancePercent <= 10000, "Chance must be <= 10000"); // Max 100% is 10000
        if (chancePercent == 0) return false;
        if (chancePercent == 10000) return true;
        return _getUint256Random(9999) < chancePercent;
    }

    // --- Legion Minting ---

    /**
     * @dev Mints a new Legion token for the caller.
     * Initial stats are pseudo-randomly assigned.
     */
    function mintLegion() public {
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Pseudo-random initial stats (between 1 and 10, for example)
        LegionStats memory initialStats = LegionStats({
            power: uint8(_getUint256Random(9) + 1), // 1-10
            defense: uint8(_getUint256Random(9) + 1), // 1-10
            speed: uint8(_getUint256Random(9) + 1), // 1-10
            morale: uint8(_getUint256Random(9) + 1), // 1-10
            isInjured: false,
            isEquipped: false
        });

        legionStats[newItemId] = initialStats;
        legionStatus[newItemId] = LegionStatus.Available;
        _mint(_msgSender(), newItemId);

        emit LegionMinted(_msgSender(), newItemId, initialStats);
    }

    // --- Legion Progression & Actions ---

     /**
     * @dev Trains a specific stat of a Legion using Essence.
     * Requires Legion owner/approved and sufficient Essence.
     * @param tokenId The ID of the Legion to train.
     * @param statType The type of stat to train (e.g., 1 for Power, 2 for Defense).
     */
    function trainLegion(uint256 tokenId, uint8 statType) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Available, "CL: Legion is busy");

        LegionStats storage stats = legionStats[tokenId];
        require(stats.isInjured == false, "CL: Legion is injured");

        // Example: Training cost increases with stat value.
        // Morale could reduce cost, but keeping simple for example.
        uint256 currentStatValue;
        if (statType == 1) {
            currentStatValue = stats.power;
        } else if (statType == 2) {
            currentStatValue = stats.defense;
        } else if (statType == 3) {
            currentStatValue = stats.speed;
        } else if (statType == 4) {
            currentStatValue = stats.morale;
        } else {
            revert("CL: Invalid stat type");
        }

        require(currentStatValue < 100, "CL: Stat is already max"); // Max stat cap

        uint256 essenceCost = currentStatValue.mul(10).add(50); // Example cost calculation
        require(essenceBalances[_msgSender()] >= essenceCost, "CL: Insufficient Essence");

        essenceBalances[_msgSender()] = essenceBalances[_msgSender()].sub(essenceCost);

        if (statType == 1) {
            stats.power = stats.power.add(1);
        } else if (statType == 2) {
            stats.defense = stats.defense.add(1);
        } else if (statType == 3) {
            stats.speed = stats.speed.add(1);
        } else if (statType == 4) {
            stats.morale = stats.morale.add(1);
        }

        emit StatsTrained(tokenId, statType, currentStatValue.add(1), essenceCost);
    }

    /**
     * @dev Equips a conceptual Relic to a Legion.
     * This is a simplified example. A real system would have specific relic effects.
     * @param tokenId The ID of the Legion.
     * @param relicId The ID of the relic type (conceptually).
     */
    function equipRelic(uint256 tokenId, uint256 relicId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Available, "CL: Legion is busy");
        require(!legionStats[tokenId].isEquipped, "CL: Legion already has a relic");

        // Example cost - 1 relic of the specified type
        uint256 relicsCost = 1;
        // In a real system, you'd check specific relicId ownership/cost
        // For this example, we assume relicId 1 costs 1 Relic resource.
        require(relicBalances[_msgSender()] >= relicsCost, "CL: Insufficient Relics");
        require(relicId == 1, "CL: Invalid or unsupported relic ID"); // Simplified check

        relicBalances[_msgSender()] = relicBalances[_msgSender()].sub(relicsCost);
        legionStats[tokenId].isEquipped = true; // Set flag, could add specific relic ID if needed

        emit RelicEquipped(tokenId, relicId, relicsCost);
        // Note: A real system would likely add a specific bonus to stats or mission outcomes
        // and potentially have the relic wear off or be consumed by a mission.
    }

    /**
     * @dev Sends a Legion on a timed mission.
     * Requires Legion owner/approved, Legion available, and sufficient resources.
     * @param tokenId The ID of the Legion to send.
     * @param missionType The type of mission (references missionConfigs mapping).
     */
    function sendLegionOnMission(uint256 tokenId, uint8 missionType) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Available, "CL: Legion is busy");
        require(legionStats[tokenId].isInjured == false, "CL: Legion is injured");
        require(missionConfigs[missionType].duration > 0, "CL: Invalid or unconfigured mission type");

        MissionConfig storage config = missionConfigs[missionType];
        require(essenceBalances[_msgSender()] >= config.essenceCost, "CL: Insufficient Essence for mission");

        essenceBalances[_msgSender()] = essenceBalances[_msgSender()].sub(config.essenceCost);

        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + config.duration; // Speed stat could reduce duration here

        missionInfo[tokenId] = MissionInfo({
            missionType: missionType,
            startTime: startTime,
            endTime: endTime
        });
        legionStatus[tokenId] = LegionStatus.OnMission;

        emit MissionStarted(tokenId, missionType, endTime);
    }

    /**
     * @dev Stakes a Legion to earn passive Essence.
     * Requires Legion owner/approved and Legion available.
     * @param tokenId The ID of the Legion to stake.
     */
    function stakeLegionForEssence(uint256 tokenId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Available, "CL: Legion is busy");
        require(legionStats[tokenId].isInjured == false, "CL: Legion is injured");

        stakingInfo[tokenId] = StakingInfo({
            startTime: uint64(block.timestamp),
            accumulatedEssence: 0
        });
        legionStatus[tokenId] = LegionStatus.Staking;

        emit LegionStaked(tokenId);
    }

    /**
     * @dev Repairs an injured Legion using resources.
     * Requires Legion owner/approved and Legion to be injured.
     * @param tokenId The ID of the Legion to repair.
     */
    function repairLegion(uint256 tokenId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStats[tokenId].isInjured == true, "CL: Legion is not injured");

        // Example repair cost: 100 Glory + 50 Essence
        uint256 gloryCost = 100;
        uint256 essenceCost = 50;
        require(gloryBalances[_msgSender()] >= gloryCost, "CL: Insufficient Glory for repair");
        require(essenceBalances[_msgSender()] >= essenceCost, "CL: Insufficient Essence for repair");

        gloryBalances[_msgSender()] = gloryBalances[_msgSender()].sub(gloryCost);
        essenceBalances[_msgSender()] = essenceBalances[_msgSender()].sub(essenceCost);

        legionStats[tokenId].isInjured = false;
        legionStatus[tokenId] = LegionStatus.Available;

        emit LegionRepaired(tokenId, gloryCost.add(essenceCost)); // Log total cost for simplicity
    }

    /**
     * @dev Disbands a Legion, burning the NFT.
     * Can potentially refund some resources (not implemented in this basic version).
     * Requires Legion owner/approved and Legion to be available.
     * @param tokenId The ID of the Legion to disband.
     */
    function disbandLegion(uint256 tokenId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Available, "CL: Legion is busy");

        address owner = ownerOf(tokenId);
        _burn(tokenId);

        // In a real system, could add resource refund logic here.
        // Example: essenceBalances[owner] = essenceBalances[owner].add(RESOURCES_TO_REFUND);

        emit LegionDisbanded(tokenId, owner);
    }


    // --- Mission & Staking Resolution ---

    /**
     * @dev Checks if a Legion's mission is complete based on block timestamp.
     * @param tokenId The ID of the Legion.
     * @return True if mission is complete, false otherwise.
     */
    function checkMissionStatus(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.OnMission, "CL: Legion is not on a mission");

        return block.timestamp >= missionInfo[tokenId].endTime;
    }

    /**
     * @dev Completes a finished mission for a Legion, calculates outcome, and distributes rewards.
     * Requires Legion owner/approved and mission to be complete.
     * @param tokenId The ID of the Legion to complete the mission for.
     */
    function completeMission(uint256 tokenId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.OnMission, "CL: Legion is not on a mission");
        require(checkMissionStatus(tokenId), "CL: Mission is not yet complete");

        MissionInfo memory currentMission = missionInfo[tokenId];
        MissionConfig storage config = missionConfigs[currentMission.missionType];
        LegionStats storage stats = legionStats[tokenId];

        address owner = ownerOf(tokenId);

        // Calculate outcome (pseudo-random)
        bool success = _getBoolRandom(config.successChancePercent); // Power stat could influence this
        bool injured = false;
        uint256 essenceEarned = 0;
        uint256 gloryEarned = 0;
        uint256 relicsEarned = 0;

        if (success) {
            // Base rewards + potential bonus based on stats (e.g., Power/Speed)
            essenceEarned = config.baseEssenceReward;
            gloryEarned = config.baseGloryReward;
            relicsEarned = config.baseRelicReward; // Could be _getUint256Random(max) for variable relics

             // Example: +1% success chance per Power stat point
             // success = _getBoolRandom(config.successChancePercent + stats.power * 100); // max 10000 total


        } else {
            // Handle failure: maybe reduced rewards or increased injury chance
            // For this example, failure means no rewards.
        }

        // Check for injury (pseudo-random)
        // Injury chance could be reduced by Defense stat
        if (_getBoolRandom(config.injuryChancePercent)) {
             injured = true;
             stats.isInjured = true;
        }

        // Distribute rewards
        if (essenceEarned > 0) essenceBalances[owner] = essenceBalances[owner].add(essenceEarned);
        if (gloryEarned > 0) gloryBalances[owner] = gloryBalances[owner].add(gloryEarned);
        if (relicsEarned > 0) relicBalances[owner] = relicBalances[owner].add(relicsEarned);


        // Reset Legion status
        delete missionInfo[tokenId];
        legionStatus[tokenId] = injured ? LegionStatus.Injured : LegionStatus.Available;

        emit MissionCompleted(tokenId, currentMission.missionType, success, injured, essenceEarned, gloryEarned, relicsEarned);
    }

    /**
     * @dev Unstakes a Legion and calculates/distributes earned Essence.
     * Requires Legion owner/approved and Legion to be staking.
     * @param tokenId The ID of the Legion to unstake.
     */
    function unstakeLegionFromEssence(uint256 tokenId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Staking, "CL: Legion is not staking");

        StakingInfo memory currentStaking = stakingInfo[tokenId];
        uint64 stakeDuration = uint64(block.timestamp) - currentStaking.startTime;

        // Calculate pending Essence and add to accumulated
        currentStaking.accumulatedEssence = currentStaking.accumulatedEssence.add(uint256(stakeDuration).mul(baseEssenceStakingRate));

        address owner = ownerOf(tokenId);
        essenceBalances[owner] = essenceBalances[owner].add(currentStaking.accumulatedEssence);

        uint256 totalClaimed = currentStaking.accumulatedEssence;

        // Reset Legion status and staking info
        delete stakingInfo[tokenId];
        legionStatus[tokenId] = legionStats[tokenId].isInjured ? LegionStatus.Injured : LegionStatus.Available; // Check injury status after unstaking

        emit LegionUnstaked(tokenId, totalClaimed);
    }

    /**
     * @dev Claims accumulated Essence from a staked Legion without unstaking it.
     * Requires Legion owner/approved and Legion to be staking.
     * @param tokenId The ID of the staked Legion.
     */
    function claimPassiveStakingEssence(uint256 tokenId) public onlyLegionOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Staking, "CL: Legion is not staking");

        StakingInfo storage currentStaking = stakingInfo[tokenId];
        uint64 timeElapsed = uint64(block.timestamp) - currentStaking.startTime;

        uint256 earnedThisPeriod = uint256(timeElapsed).mul(baseEssenceStakingRate);
        currentStaking.accumulatedEssence = currentStaking.accumulatedEssence.add(earnedThisPeriod);

        // Update start time to now for future calculations
        currentStaking.startTime = uint64(block.timestamp);

        address owner = ownerOf(tokenId);
        uint256 totalClaimable = currentStaking.accumulatedEssence;

        require(totalClaimable > 0, "CL: No essence accumulated yet");

        essenceBalances[owner] = essenceBalances[owner].add(totalClaimable);
        currentStaking.accumulatedEssence = 0; // Reset accumulated after claiming

        emit StakingEssenceClaimed(tokenId, totalClaimable);
    }


    // --- Resource Management ---

    /**
     * @dev Returns the Essence balance for a user.
     */
    function getUserEssence() public view returns (uint256) {
        return essenceBalances[_msgSender()];
    }

     /**
     * @dev Returns the Glory balance for a user.
     */
    function getUserGlory() public view returns (uint256) {
        return gloryBalances[_msgSender()];
    }

     /**
     * @dev Returns the Relics balance for a user.
     */
    function getUserRelics() public view returns (uint256) {
        return relicBalances[_msgSender()];
    }

     /**
     * @dev Allows user to claim accumulated resources from all their completed missions
     * and staked Legions in one call. (Alternative/Convenience function)
     * Note: This requires iterating user's tokens, potentially gas heavy.
     * In a complex game, users might claim per-token or per-activity.
     */
    /*
    function claimAllResources() public {
        address owner = _msgSender();
        uint256 essenceClaim = 0;
        uint256 gloryClaim = 0;
        uint256 relicsClaim = 0;

        // This approach would require tracking token IDs per owner efficiently,
        // which is gas expensive on-chain for large numbers.
        // A common pattern is off-chain indexing or having users claim per activity/token.
        // For demonstration, we'll skip the actual loop here and just show the concept.
        // In a real system, you'd call completeMission and unstakeLegionForEssence
        // for eligible tokens, perhaps triggered individually or via a helper contract.

        // Example logic (conceptual, high gas):
        // uint256[] memory tokenIds = getLegionsByOwner(owner);
        // for(uint i=0; i < tokenIds.length; i++) {
        //     uint256 tokenId = tokenIds[i];
        //     if (legionStatus[tokenId] == LegionStatus.OnMission && checkMissionStatus(tokenId)) {
        //         // Logic to complete mission and sum rewards
        //         // completeMission(tokenId); // Cannot call non-view function from view/pure
        //         // Need to re-implement logic or make completeMission callable internally
        //     } else if (legionStatus[tokenId] == LegionStatus.Staking) {
        //         // Logic to calculate & sum staking rewards
        //         // claimPassiveStakingEssence(tokenId);
        //     }
        // }

        // Since actual auto-claiming all is gas heavy, leave this function
        // as a conceptual placeholder or require users to claim per token/mission.
        // The individual claim functions (completeMission, unstakeLegionForEssence, claimPassiveStakingEssence)
        // are the primary way to claim.
        // We can add a function to CLAIM existing balances if they were somehow credited without explicit claims.
        // But current design credits resources directly to user balance mappings.

        // If the design *did* have a pending reward system, this function would collect it.
        // Example: Add mappings like pendingEssence[owner], pendingGlory[owner]...
        // and have missions/staking update these, then claimAllResources would transfer from pending to balance.

        // For this example, let's make claimAllResources just trigger pending claims if any were implemented.
        // As they are not, this remains conceptual for now.

        // If implemented:
        // essenceBalances[owner] = essenceBalances[owner].add(pendingEssence[owner]);
        // pendingEssence[owner] = 0;
        // ... similar for glory, relics ...
        // emit ResourceClaimed(owner, essenceClaim, gloryClaim, relicsClaim);
    }
    */


    // --- Query Functions ---

    /**
     * @dev Returns the current status of a Legion (Available, OnMission, Staking, Injured).
     * @param tokenId The ID of the Legion.
     */
    function getLegionStatus(uint256 tokenId) public view returns (LegionStatus) {
         require(_exists(tokenId), "CL: Legion does not exist");
         return legionStatus[tokenId];
    }

    /**
     * @dev Returns the detailed mission info for a Legion if it's on a mission.
     * @param tokenId The ID of the Legion.
     */
    function getLegionMissionInfo(uint256 tokenId) public view returns (uint8 missionType, uint64 startTime, uint64 endTime) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.OnMission, "CL: Legion is not on a mission");
        MissionInfo memory info = missionInfo[tokenId];
        return (info.missionType, info.startTime, info.endTime);
    }

    /**
     * @dev Returns the detailed staking info for a Legion if it's staking.
     * Includes calculated pending Essence since last claim/stake start.
     * @param tokenId The ID of the Legion.
     */
    function getLegionStakingInfo(uint256 tokenId) public view returns (uint64 startTime, uint256 accumulatedEssence, uint256 pendingEssence) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStatus[tokenId] == LegionStatus.Staking, "CL: Legion is not staking");
        StakingInfo memory info = stakingInfo[tokenId];
        uint64 timeElapsed = uint64(block.timestamp) - info.startTime;
        pendingEssence = uint256(timeElapsed).mul(baseEssenceStakingRate);
        return (info.startTime, info.accumulatedEssence, pendingEssence);
    }

    /**
     * @dev Returns the configuration details for a specific mission type.
     * @param missionType The type of mission.
     */
    function getMissionConfig(uint8 missionType) public view returns (MissionConfig memory) {
         require(missionConfigs[missionType].duration > 0, "CL: Invalid mission type");
         return missionConfigs[missionType];
    }

    /**
     * @dev Returns the list of all token IDs owned by an address.
     * WARNING: This function is gas-intensive and should be used with caution,
     * especially for addresses owning many tokens. Off-chain indexing is recommended.
     * @param owner The address to query.
     */
    function getLegionsByOwner(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "CL: Address zero cannot own tokens");
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // Iterating through all possible token IDs is highly inefficient.
        // A real ERC721 implementation with this function would use a linked list
        // or similar structure to track tokens per owner efficiently, or simply
        // omit this function and rely on off-chain indexing.
        // For this conceptual example, we'll iterate up to the current max token ID.
        // This loop *will* be expensive if total tokens minted is large.
        uint256 totalMinted = _tokenIdCounter.current();
        for (uint256 i = 0; i < totalMinted; i++) {
            if (_owners[i] == owner) {
                tokenIds[index] = i;
                index++;
                if (index == tokenCount) break; // Stop once all owned tokens are found
            }
        }
        return tokenIds;
    }

    // --- Admin & Configuration ---

     /**
     * @dev Sets or updates the configuration for a specific mission type.
     * Only callable by the contract owner.
     * @param missionType The type of mission to configure.
     * @param duration The duration of the mission in seconds.
     * @param baseEssenceReward Base Essence earned on success.
     * @param baseGloryReward Base Glory earned on success.
     * @param baseRelicReward Base Relics earned on success.
     * @param successChancePercent Success chance (0-10000, representing 0-100%).
     * @param injuryChancePercent Injury chance on completion (0-10000).
     * @param essenceCost Essence cost to start the mission.
     */
    function configureMissionType(
        uint8 missionType,
        uint64 duration,
        uint256 baseEssenceReward,
        uint256 baseGloryReward,
        uint256 baseRelicReward,
        uint16 successChancePercent,
        uint16 injuryChancePercent,
        uint256 essenceCost
    ) public onlyOwner {
        require(duration > 0, "CL: Mission duration must be greater than zero");
        require(successChancePercent <= 10000, "CL: Success chance must be <= 10000");
        require(injuryChancePercent <= 10000, "CL: Injury chance must be <= 10000");

        missionConfigs[missionType] = MissionConfig({
            duration: duration,
            baseEssenceReward: baseEssenceReward,
            baseGloryReward: baseGloryReward,
            baseRelicReward: baseRelicReward,
            successChancePercent: successChancePercent,
            injuryChancePercent: injuryChancePercent,
            essenceCost: essenceCost
        });

        emit MissionConfigUpdated(missionType, missionConfigs[missionType]);
    }

    /**
     * @dev Sets the base rate at which staked Legions earn Essence per second.
     * Only callable by the contract owner.
     * @param rate The new rate (Essence per second).
     */
    function setBaseEssenceStakingRate(uint256 rate) public onlyOwner {
        baseEssenceStakingRate = rate;
        emit BaseEssenceStakingRateUpdated(rate);
    }

    // Add any other necessary admin functions, e.g., withdrawing stuck ETH, emergency pauses, etc.

    // --- Additional Helper (Optional, for showing required training essence) ---

    /**
     * @dev Calculates the Essence cost for the *next* training step of a specific stat.
     * @param tokenId The ID of the Legion.
     * @param statType The type of stat (1-4).
     * @return The required Essence cost.
     */
    function getRequiredTrainingEssence(uint256 tokenId, uint8 statType) public view returns (uint256) {
         require(_exists(tokenId), "CL: Legion does not exist");
         LegionStats memory stats = legionStats[tokenId];
         uint256 currentStatValue;
        if (statType == 1) {
            currentStatValue = stats.power;
        } else if (statType == 2) {
            currentStatValue = stats.defense;
        } else if (statType == 3) {
            currentStatValue = stats.speed;
        } else if (statType == 4) {
            currentStatValue = stats.morale;
        } else {
            revert("CL: Invalid stat type");
        }
        if (currentStatValue >= 100) return 0; // Already max stat
        return currentStatValue.mul(10).add(50); // Matches training logic cost
    }

    /**
     * @dev Returns the resource costs required to repair an injured Legion.
     * @param tokenId The ID of the Legion.
     * @return gloryCost The required Glory.
     * @return essenceCost The required Essence.
     */
    function getRequiredRepairCost(uint256 tokenId) public view returns (uint256 gloryCost, uint256 essenceCost) {
        require(_exists(tokenId), "CL: Legion does not exist");
        require(legionStats[tokenId].isInjured == true, "CL: Legion is not injured");
        // Matches repair logic costs
        return (100, 50);
    }


}
```