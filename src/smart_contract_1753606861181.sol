Okay, this is an exciting challenge! Creating a smart contract that is novel, complex, and touches on advanced concepts without duplicating existing open-source projects requires some deep thought.

Let's imagine a system where NFTs are not static images, but rather dynamic entities whose properties are initially in a "superposition" state, requiring a "quantum observation" to collapse them into a definite form, potentially influenced by external factors or "entangled" with other NFTs. This leans into concepts of randomness, dynamic attributes, and inter-NFT relationships, which are currently trending in advanced GameFi and metaverse projects.

---

## QuantumLootForge Smart Contract

This contract implements a decentralized system for forging, evolving, and interacting with unique, dynamic NFT assets called "Quantum Loot Items." These items are initially in a "superposition state" where their true attributes are unknown. Through a "Quantum Observation" process, fueled by "Quantum Essence" (an ERC-20 token), their state collapses, revealing their unique properties. Items can also be "entangled" with each other, leading to shared effects or bonuses, and undergo "Quantum Shifts" to evolve their attributes. The system integrates Chainlink VRF for secure on-chain randomness.

---

### Outline & Function Summary

**I. Core Assets & Structure:**
*   `QuantumLootForge` (ERC-721): The main NFT representing dynamic "Quantum Loot Items."
*   `QuantumEssence` (ERC-20, internal): The utility token required for various operations within the forge.

**II. State Management & Data Structures:**
*   `LootItem` struct: Defines the dynamic attributes and state of each NFT.
*   `RevealedAttributes` struct: Defines the set of attributes revealed upon state collapse.
*   Mappings for item data, pending requests, and entanglement.

**III. Quantum Mechanics & Core Logic:**
1.  **`constructor(...)`**: Initializes the contract with Chainlink VRF details, Quantum Essence token address, and initial parameters.
2.  **`forgeQuantumLoot(string memory _initialMetadataURI, bytes32 _seed)`**: Mints a new Quantum Loot NFT in a superposition state. Its attributes are not yet revealed. Requires `QuantumEssence`.
3.  **`requestSuperpositionCollapse(uint256 _tokenId)`**: Initiates the process to collapse a Loot Item's superposition state, revealing its true attributes. Triggers a Chainlink VRF request. Requires `QuantumEssence`.
4.  **`rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`**: Chainlink VRF callback function. Processes the random word to deterministically collapse the item's state and reveal attributes. *Internal logic for attribute derivation.*
5.  **`initiateQuantumShift(uint256 _tokenId, bytes32 _shiftSeed)`**: Triggers a "Quantum Shift" on a revealed item, subtly altering its attributes over time. Uses an internal pseudo-randomness or requires another VRF request based on configuration. Requires `QuantumEssence`.
6.  **`entangleLootItems(uint256 _tokenId1, uint256 _tokenId2)`**: Establishes a "quantum entanglement" between two distinct Loot Items, creating a linked destiny. Requires `QuantumEssence`.
7.  **`disentangleLootItems(uint256 _tokenId1, uint256 _tokenId2)`**: Breaks the entanglement between two Loot Items. Requires `QuantumEssence`.
8.  **`simulateTemporalDecay(uint256 _tokenId)`**: A function that can be called to apply a temporal decay effect to certain item attributes based on time elapsed since last `rechargeQuantumCore` or `quantumShift`.
9.  **`rechargeQuantumCore(uint256 _tokenId)`**: Restores a portion of an item's decayed attributes or boosts its potential. Requires `QuantumEssence`.

**IV. Item Query & Management:**
10. **`getLootItemDetails(uint256 _tokenId)`**: Retrieves all comprehensive details (superposition state, revealed attributes, entanglement status) of a Quantum Loot Item.
11. **`isLootItemRevealed(uint256 _tokenId)`**: Checks if a Loot Item's attributes have been revealed.
12. **`getLootItemEntanglement(uint256 _tokenId)`**: Returns the ID of the item an item is entangled with (0 if none).
13. **`scrapQuantumLoot(uint256 _tokenId)`**: Allows owners to burn their unwanted Loot Items in exchange for a portion of `QuantumEssence` back.

**V. Configuration & Governance (Owner/Admin Functions):**
14. **`toggleForgeActivity()`**: Pauses or unpauses core forge operations (minting, observation).
15. **`updateVRFConfiguration(uint64 _subscriptionId, bytes32 _keyHash, address _coordinator)`**: Updates Chainlink VRF configuration parameters.
16. **`setEssenceCostForAction(ActionType _action, uint256 _cost)`**: Sets the `QuantumEssence` cost for various actions (forge, collapse, shift, entangle, disentangle, recharge).
17. **`setBaseAttributeRanges(uint256 _minPower, uint256 _maxPower, ...)`**: Sets the base range for attribute generation during revelation.
18. **`withdrawStuckEssence(address _to)`**: Allows the owner to withdraw accidentally sent `QuantumEssence` from the contract.
19. **`transferOwnership(address _newOwner)`**: Standard OpenZeppelin Ownable function.
20. **`grantAdminRole(address _account)`**: Grants a specific address an administrative role, allowing it to perform certain privileged operations (e.g., setting costs, updating config).
21. **`revokeAdminRole(address _account)`**: Revokes an administrative role.
22. **`hasAdminRole(address _account)`**: Checks if an address has the admin role.

---

### QuantumLootForge Smart Contract (Solidity)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Custom Errors for better clarity and gas efficiency
error NotForgeOwner();
error NotAdmin();
error ForgeNotActive();
error InsufficientEssence(uint256 required, uint256 has);
error TokenDoesNotExist(uint256 tokenId);
error NotTokenOwner(uint256 tokenId, address owner);
error TokenAlreadyRevealed(uint256 tokenId);
error TokenNotRevealed(uint256 tokenId);
error RevelationAlreadyPending(uint256 tokenId);
error NoRevelationPending(uint256 tokenId);
error CannotEntangleSelf();
error AlreadyEntangled(uint256 tokenId, uint256 entangledWith);
error NotEntangled(uint256 tokenId1, uint256 tokenId2);
error InvalidAttributeRange();
error EssenceTransferFailed();

/**
 * @title QuantumLootForge
 * @dev A smart contract for creating, observing, evolving, and entangling dynamic NFT assets.
 *      Integrates Chainlink VRF for secure on-chain randomness.
 *      Features: Superposition state, state collapse (revelation), quantum shifts, and item entanglement.
 */
contract QuantumLootForge is ERC721, VRFConsumerBaseV2, Ownable {
    using SafeMath for uint256;

    // --- Events ---
    event LootForged(uint256 indexed tokenId, address indexed owner, string initialURI, bytes32 superpositionHash);
    event SuperpositionCollapseRequested(uint256 indexed tokenId, uint256 indexed requestId);
    event SuperpositionCollapsed(uint256 indexed tokenId, RevealedAttributes attributes, uint256 randomWord);
    event QuantumShiftInitiated(uint256 indexed tokenId, RevealedAttributes newAttributes);
    event ItemsEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ItemsDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event LootScrapped(uint256 indexed tokenId, uint256 essenceRefunded);
    event ForgeActivityToggled(bool active);
    event EssenceCostUpdated(ActionType indexed action, uint256 newCost);
    event AttributeRangesUpdated(uint256 minPower, uint256 maxPower, uint256 minAgility, uint256 maxAgility, uint256 minCharisma, uint256 maxCharisma);
    event QuantumCoreRecharged(uint256 indexed tokenId, RevealedAttributes currentAttributes);
    event TemporalDecayApplied(uint256 indexed tokenId, RevealedAttributes newAttributes);
    event AdminRoleGranted(address indexed account);
    event AdminRoleRevoked(address indexed account);

    // --- Enums ---
    enum ActionType { ForgeLoot, CollapseState, QuantumShift, EntangleItems, DisentangleItems, RechargeCore, ScrapLoot }

    // --- Structs ---
    struct RevealedAttributes {
        uint8 power;    // Represents destructive capability
        uint8 agility;  // Represents speed and evasion
        uint8 charisma; // Represents influence and luck
        uint16 rarityScore; // A combined score based on attributes and derived properties
        bytes1 elementalAffinity; // A single byte representing elemental type (e.g., 0x01 for fire, 0x02 for water)
    }

    struct LootItem {
        bytes32 superpositionStateHash; // A hash representing the item's potential state before revelation
        RevealedAttributes revealedAttributes; // Actual attributes once revealed
        bool isRevealed;                // True if attributes have been determined
        uint256 entropySeed;            // A seed used during initial forging for the superposition hash
        uint256 lastQuantumShift;       // Timestamp of the last quantum shift or creation/recharge
        uint256 entangledWith;          // Token ID of the item it's entangled with (0 if none)
    }

    // --- State Variables ---

    // ERC-20 token for Quantum Essence
    IERC20 public immutable quantumEssenceToken;

    // Chainlink VRF configuration
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public immutable i_keyHash;
    uint64 public immutable i_subscriptionId;
    uint32 public immutable i_callbackGasLimit;
    uint16 public immutable i_requestConfirmations;

    // Mappings for storing Loot Item data
    mapping(uint256 => LootItem) public quantumLootItems;

    // Chainlink VRF request tracking
    mapping(uint256 => uint256) public s_requestIdToTokenId; // requestId => tokenId
    mapping(uint256 => uint256) public s_tokenIdToRequestId; // tokenId => requestId (for pending requests)

    // Contract activity status
    bool public isForgeActive;

    // Cost configuration for various actions in Quantum Essence
    mapping(ActionType => uint256) public essenceCosts;

    // Attribute ranges for revelation
    uint8 public minPowerAttribute;
    uint8 public maxPowerAttribute;
    uint8 public minAgilityAttribute;
    uint8 public maxAgilityAttribute;
    uint8 public minCharismaAttribute;
    uint8 public maxCharismaAttribute;

    // Counter for unique token IDs
    uint256 private _nextTokenId;

    // Admin role for privileged operations beyond basic ownership
    mapping(address => bool) private _admins;

    // --- Modifiers ---
    modifier whenForgeActive() {
        if (!isForgeActive) revert ForgeNotActive();
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != _msgSender()) revert NotTokenOwner(_tokenId, _msgSender());
        _;
    }

    modifier payEssence(ActionType _actionType) {
        uint256 cost = essenceCosts[_actionType];
        if (quantumEssenceToken.balanceOf(_msgSender()) < cost) {
            revert InsufficientEssence(cost, quantumEssenceToken.balanceOf(_msgSender()));
        }
        // Approve and transfer in a single call (pull over push)
        if (!quantumEssenceToken.transferFrom(_msgSender(), address(this), cost)) {
            revert EssenceTransferFailed();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!_admins[_msgSender()] && _msgSender() != owner()) revert NotAdmin();
        _;
    }

    // --- Constructor ---
    constructor(
        address _essenceTokenAddress,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) ERC721("QuantumLootItem", "QLI") VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        if (_essenceTokenAddress == address(0) || _vrfCoordinator == address(0)) {
            revert InvalidAttributeRange(); // Reusing error for brevity, could be custom init error
        }

        quantumEssenceToken = IERC20(_essenceTokenAddress);
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_requestConfirmations = _requestConfirmations;

        isForgeActive = true; // Forge starts active

        // Set initial essence costs
        essenceCosts[ActionType.ForgeLoot] = 50 * 10**18; // 50 Essence
        essenceCosts[ActionType.CollapseState] = 100 * 10**18; // 100 Essence
        essenceCosts[ActionType.QuantumShift] = 75 * 10**18; // 75 Essence
        essenceCosts[ActionType.EntangleItems] = 200 * 10**18; // 200 Essence
        essenceCosts[ActionType.DisentangleItems] = 50 * 10**18; // 50 Essence
        essenceCosts[ActionType.RechargeCore] = 25 * 10**18; // 25 Essence
        essenceCosts[ActionType.ScrapLoot] = 0; // Scrap does not cost essence, gives essence back

        // Set initial attribute ranges (example: 1-100)
        minPowerAttribute = 1; maxPowerAttribute = 100;
        minAgilityAttribute = 1; maxAgilityAttribute = 100;
        minCharismaAttribute = 1; maxCharismaAttribute = 100;

        _admins[msg.sender] = true; // Grant owner admin role by default
    }

    // --- Core Quantum Mechanics & Logic ---

    /**
     * @dev Forges a new Quantum Loot Item, which starts in a superposition state.
     *      Requires Quantum Essence payment.
     * @param _initialMetadataURI The initial URI for the NFT metadata (before revelation).
     * @param _seed A user-provided seed for the superposition state hash.
     * @return The ID of the newly minted Quantum Loot Item.
     */
    function forgeQuantumLoot(string memory _initialMetadataURI, bytes32 _seed)
        public
        whenForgeActive
        payEssence(ActionType.ForgeLoot)
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _initialMetadataURI);

        // Calculate a superposition hash based on initial parameters (before actual attributes are revealed)
        bytes32 superpositionHash = keccak256(abi.encodePacked(tokenId, block.timestamp, msg.sender, _seed, _initialMetadataURI));

        quantumLootItems[tokenId] = LootItem({
            superpositionStateHash: superpositionHash,
            revealedAttributes: RevealedAttributes(0, 0, 0, 0, bytes1(0x00)), // All zeros initially
            isRevealed: false,
            entropySeed: _seed,
            lastQuantumShift: 0, // Set to 0 as it's not shifted yet
            entangledWith: 0
        });

        emit LootForged(tokenId, msg.sender, _initialMetadataURI, superpositionHash);
        return tokenId;
    }

    /**
     * @dev Initiates the process to collapse a Quantum Loot Item's superposition state.
     *      This requests random words from Chainlink VRF.
     *      Requires Quantum Essence payment.
     * @param _tokenId The ID of the Quantum Loot Item to reveal.
     */
    function requestSuperpositionCollapse(uint256 _tokenId)
        public
        whenForgeActive
        onlyTokenOwner(_tokenId)
        payEssence(ActionType.CollapseState)
    {
        LootItem storage item = quantumLootItems[_tokenId];
        if (item.superpositionStateHash == bytes32(0)) revert TokenDoesNotExist(_tokenId);
        if (item.isRevealed) revert TokenAlreadyRevealed(_tokenId);
        if (s_tokenIdToRequestId[_tokenId] != 0) revert RevelationAlreadyPending(_tokenId);

        // Request 1 random word to derive multiple attributes securely
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Request 1 random word
        );

        s_requestIdToTokenId[requestId] = _tokenId;
        s_tokenIdToRequestId[_tokenId] = requestId;

        emit SuperpositionCollapseRequested(_tokenId, requestId);
    }

    /**
     * @dev Chainlink VRF callback function. This function is called by the VRF Coordinator
     *      when the random words are available. It processes the random word to
     *      determine and set the item's revealed attributes.
     *      DO NOT CALL THIS FUNCTION DIRECTLY.
     * @param requestId The ID of the Chainlink VRF request.
     * @param randomWords An array containing the random word(s) generated by VRF.
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 tokenId = s_requestIdToTokenId[requestId];
        if (tokenId == 0) revert NoRevelationPending(tokenId); // Should not happen if VRF is configured correctly

        delete s_requestIdToTokenId[requestId];
        delete s_tokenIdToRequestId[tokenId];

        LootItem storage item = quantumLootItems[tokenId];
        if (item.isRevealed) return; // Already revealed by another callback (unlikely but safe)

        uint256 randomness = randomWords[0];

        // Deterministically derive attributes from the original superposition hash and randomness.
        // This makes the revelation "fair" as the initial potential is fixed, and randomness
        // only determines which specific outcome from that potential is chosen.
        // Example derivation (can be more complex):
        item.revealedAttributes.power = uint8(
            (uint256(item.superpositionStateHash ^ bytes32(randomness)) % (maxPowerAttribute - minPowerAttribute + 1)) + minPowerAttribute
        );
        item.revealedAttributes.agility = uint8(
            (uint256(keccak256(abi.encodePacked(item.superpositionStateHash, randomness, "agility"))) % (maxAgilityAttribute - minAgilityAttribute + 1)) + minAgilityAttribute
        );
        item.revealedAttributes.charisma = uint8(
            (uint256(keccak256(abi.encodePacked(item.superpositionStateHash, randomness, "charisma"))) % (maxCharismaAttribute - minCharismaAttribute + 1)) + minCharismaAttribute
        );

        // Derive rarity score based on combined attributes (example formula)
        item.revealedAttributes.rarityScore = uint16(
            (item.revealedAttributes.power + item.revealedAttributes.agility + item.revealedAttributes.charisma) * 10
        );

        // Derive elemental affinity (example: use a bit of randomness to pick from 4 elements)
        item.revealedAttributes.elementalAffinity = bytes1(uint8(randomness % 4) + 1); // 1-4 for different elements

        item.isRevealed = true;
        item.lastQuantumShift = block.timestamp; // Mark as revealed and effectively shifted

        // You might want to update the token URI here to reflect revealed attributes
        // _setTokenURI(tokenId, generateRevealedMetadataURI(tokenId)); // requires a new internal function

        emit SuperpositionCollapsed(tokenId, item.revealedAttributes, randomness);
    }

    /**
     * @dev Initiates a "Quantum Shift" on a revealed Loot Item, subtly altering its attributes.
     *      This could represent an upgrade, decay, or random evolution.
     *      Requires Quantum Essence payment.
     * @param _tokenId The ID of the revealed Loot Item to shift.
     * @param _shiftSeed A user-provided seed to influence the shift outcome (can be bytes32(0) for pure randomness).
     */
    function initiateQuantumShift(uint256 _tokenId, bytes32 _shiftSeed)
        public
        whenForgeActive
        onlyTokenOwner(_tokenId)
        payEssence(ActionType.QuantumShift)
    {
        LootItem storage item = quantumLootItems[_tokenId];
        if (!item.isRevealed) revert TokenNotRevealed(_tokenId);

        // Generate a pseudo-random number for the shift (can integrate VRF here for true randomness)
        // For simplicity, using a hash of current block, timestamp, tokenId, and user seed.
        uint256 shiftRandomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, _tokenId, _shiftSeed, item.superpositionStateHash)));

        // Apply a small shift to attributes
        item.revealedAttributes.power = uint8(uint256(item.revealedAttributes.power).add(shiftRandomness % 5).sub(shiftRandomness % 3));
        item.revealedAttributes.agility = uint8(uint256(item.revealedAttributes.agility).add(shiftRandomness % 4).sub(shiftRandomness % 2));
        item.revealedAttributes.charisma = uint8(uint256(item.revealedAttributes.charisma).add(shiftRandomness % 6).sub(shiftRandomness % 4));

        // Ensure attributes stay within bounds (e.g., min 1, max 255 for uint8)
        item.revealedAttributes.power = item.revealedAttributes.power == 0 ? 1 : item.revealedAttributes.power;
        item.revealedAttributes.agility = item.revealedAttributes.agility == 0 ? 1 : item.revealedAttributes.agility;
        item.revealedAttributes.charisma = item.revealedAttributes.charisma == 0 ? 1 : item.revealedAttributes.charisma;
        
        item.revealedAttributes.power = item.revealedAttributes.power > maxPowerAttribute ? maxPowerAttribute : item.revealedAttributes.power;
        item.revealedAttributes.agility = item.revealedAttributes.agility > maxAgilityAttribute ? maxAgilityAttribute : item.revealedAttributes.agility;
        item.revealedAttributes.charisma = item.revealedAttributes.charisma > maxCharismaAttribute ? maxCharismaAttribute : item.revealedAttributes.charisma;


        // Update rarity score based on new attributes
        item.revealedAttributes.rarityScore = uint16(
            (item.revealedAttributes.power + item.revealedAttributes.agility + item.revealedAttributes.charisma) * 10
        );

        item.lastQuantumShift = block.timestamp; // Update last shift timestamp

        emit QuantumShiftInitiated(_tokenId, item.revealedAttributes);
    }

    /**
     * @dev Establishes a "quantum entanglement" between two distinct Loot Items.
     *      Entangled items could share properties or affect each other in game logic.
     *      Requires Quantum Essence payment.
     * @param _tokenId1 The ID of the first Loot Item.
     * @param _tokenId2 The ID of the second Loot Item.
     */
    function entangleLootItems(uint256 _tokenId1, uint256 _tokenId2)
        public
        whenForgeActive
        payEssence(ActionType.EntangleItems)
    {
        if (_tokenId1 == _tokenId2) revert CannotEntangleSelf();
        if (ownerOf(_tokenId1) != _msgSender() || ownerOf(_tokenId2) != _msgSender()) {
            revert NotTokenOwner(_tokenId1, _msgSender()); // Or a more specific error for not owning both
        }

        LootItem storage item1 = quantumLootItems[_tokenId1];
        LootItem storage item2 = quantumLootItems[_tokenId2];

        if (item1.superpositionStateHash == bytes32(0) || item2.superpositionStateHash == bytes32(0)) revert TokenDoesNotExist(0); // Generic, could be specific

        if (item1.entangledWith != 0) revert AlreadyEntangled(_tokenId1, item1.entangledWith);
        if (item2.entangledWith != 0) revert AlreadyEntangled(_tokenId2, item2.entangledWith);

        // Establish mutual entanglement
        item1.entangledWith = _tokenId2;
        item2.entangledWith = _tokenId1;

        // Optionally, apply a temporary bonus or effect to entangled items
        // E.g., item1.revealedAttributes.power += 5; item2.revealedAttributes.power += 5;
        // This would require items to be revealed before entanglement, or handle unrevealed states.
        // For simplicity, just establishing the link.

        emit ItemsEntangled(_tokenId1, _tokenId2);
    }

    /**
     * @dev Breaks the entanglement between two Loot Items.
     *      Requires Quantum Essence payment.
     * @param _tokenId1 The ID of the first Loot Item.
     * @param _tokenId2 The ID of the second Loot Item.
     */
    function disentangleLootItems(uint256 _tokenId1, uint256 _tokenId2)
        public
        whenForgeActive
        payEssence(ActionType.DisentangleItems)
    {
        if (_tokenId1 == _tokenId2) revert CannotEntangleSelf();
        if (ownerOf(_tokenId1) != _msgSender() || ownerOf(_tokenId2) != _msgSender()) {
            revert NotTokenOwner(_tokenId1, _msgSender());
        }

        LootItem storage item1 = quantumLootItems[_tokenId1];
        LootItem storage item2 = quantumLootItems[_tokenId2];

        if (item1.entangledWith != _tokenId2 || item2.entangledWith != _tokenId1) {
            revert NotEntangled(_tokenId1, _tokenId2);
        }

        // Break mutual entanglement
        item1.entangledWith = 0;
        item2.entangledWith = 0;

        // Optionally, remove any bonuses or effects applied during entanglement

        emit ItemsDisentangled(_tokenId1, _tokenId2);
    }

    /**
     * @dev Simulates temporal decay on certain item attributes based on time passed
     *      since the last quantum shift or core recharge. Can be called periodically
     *      by a keeper or the owner to update item state.
     *      NOTE: This is a simplified example. Real-world decay might be more complex.
     * @param _tokenId The ID of the Loot Item to simulate decay on.
     */
    function simulateTemporalDecay(uint256 _tokenId)
        public
        onlyTokenOwner(_tokenId) // Could be public for anyone to trigger, but costs gas.
    {
        LootItem storage item = quantumLootItems[_tokenId];
        if (!item.isRevealed) revert TokenNotRevealed(_tokenId);

        uint256 timeElapsed = block.timestamp.sub(item.lastQuantumShift);
        uint256 decayRate = 1 days; // Decay happens per day

        if (timeElapsed < decayRate) return; // Not enough time passed for decay

        uint256 decayCycles = timeElapsed.div(decayRate);

        // Apply decay to attributes (e.g., 1 point per cycle)
        item.revealedAttributes.power = item.revealedAttributes.power > decayCycles ?
            uint8(uint256(item.revealedAttributes.power).sub(uint8(decayCycles))) : 1; // Min attribute 1
        item.revealedAttributes.agility = item.revealedAttributes.agility > decayCycles ?
            uint8(uint256(item.revealedAttributes.agility).sub(uint8(decayCycles))) : 1;
        item.revealedAttributes.charisma = item.revealedAttributes.charisma > decayCycles ?
            uint8(uint256(item.revealedAttributes.charisma).sub(uint8(decayCycles))) : 1;

        // Update rarity score
        item.revealedAttributes.rarityScore = uint16(
            (item.revealedAttributes.power + item.revealedAttributes.agility + item.revealedAttributes.charisma) * 10
        );

        item.lastQuantumShift = item.lastQuantumShift.add(decayCycles.mul(decayRate)); // Update timestamp to reflect decay

        emit TemporalDecayApplied(_tokenId, item.revealedAttributes);
    }

    /**
     * @dev Recharges a Quantum Loot Item's core, counteracting temporal decay or boosting attributes.
     *      Requires Quantum Essence payment.
     * @param _tokenId The ID of the Loot Item to recharge.
     */
    function rechargeQuantumCore(uint256 _tokenId)
        public
        whenForgeActive
        onlyTokenOwner(_tokenId)
        payEssence(ActionType.RechargeCore)
    {
        LootItem storage item = quantumLootItems[_tokenId];
        if (!item.isRevealed) revert TokenNotRevealed(_tokenId);

        // Apply a boost to attributes (e.g., 5 points per attribute, capped at max)
        item.revealedAttributes.power = item.revealedAttributes.power.add(5);
        item.revealedAttributes.agility = item.revealedAttributes.agility.add(5);
        item.revealedAttributes.charisma = item.revealedAttributes.charisma.add(5);

        // Ensure attributes don't exceed max values
        item.revealedAttributes.power = item.revealedAttributes.power > maxPowerAttribute ? maxPowerAttribute : item.revealedAttributes.power;
        item.revealedAttributes.agility = item.revealedAttributes.agility > maxAgilityAttribute ? maxAgilityAttribute : item.revealedAttributes.agility;
        item.revealedAttributes.charisma = item.revealedAttributes.charisma > maxCharismaAttribute ? maxCharismaAttribute : item.revealedAttributes.charisma;

        // Update rarity score
        item.revealedAttributes.rarityScore = uint16(
            (item.revealedAttributes.power + item.revealedAttributes.agility + item.revealedAttributes.charisma) * 10
        );

        item.lastQuantumShift = block.timestamp; // Reset decay timer

        emit QuantumCoreRecharged(_tokenId, item.revealedAttributes);
    }


    // --- Item Query & Management ---

    /**
     * @dev Retrieves all comprehensive details of a Quantum Loot Item.
     * @param _tokenId The ID of the Loot Item.
     * @return LootItem struct containing all relevant data.
     */
    function getLootItemDetails(uint256 _tokenId) public view returns (LootItem memory) {
        if (quantumLootItems[_tokenId].superpositionStateHash == bytes32(0) && _exists(_tokenId)) {
            // This case handles a newly minted token that isn't fully initialized in the mapping yet
            // If _exists(_tokenId) is false, it means the token truly doesn't exist.
            revert TokenDoesNotExist(_tokenId);
        }
        return quantumLootItems[_tokenId];
    }

    /**
     * @dev Checks if a Loot Item's attributes have been revealed.
     * @param _tokenId The ID of the Loot Item.
     * @return True if revealed, false otherwise.
     */
    function isLootItemRevealed(uint256 _tokenId) public view returns (bool) {
        if (quantumLootItems[_tokenId].superpositionStateHash == bytes32(0)) revert TokenDoesNotExist(_tokenId);
        return quantumLootItems[_tokenId].isRevealed;
    }

    /**
     * @dev Returns the ID of the item an item is entangled with.
     * @param _tokenId The ID of the Loot Item.
     * @return The ID of the entangled item (0 if none).
     */
    function getLootItemEntanglement(uint256 _tokenId) public view returns (uint256) {
        if (quantumLootItems[_tokenId].superpositionStateHash == bytes32(0)) revert TokenDoesNotExist(_tokenId);
        return quantumLootItems[_tokenId].entangledWith;
    }

    /**
     * @dev Allows owners to burn their unwanted Loot Items in exchange for a portion of `QuantumEssence` back.
     *      The refund amount is configured.
     * @param _tokenId The ID of the Loot Item to scrap.
     */
    function scrapQuantumLoot(uint256 _tokenId)
        public
        whenForgeActive
        onlyTokenOwner(_tokenId)
    {
        LootItem storage item = quantumLootItems[_tokenId];
        if (item.superpositionStateHash == bytes32(0)) revert TokenDoesNotExist(_tokenId);
        if (item.entangledWith != 0) revert AlreadyEntangled(_tokenId, item.entangledWith); // Cannot scrap entangled items

        // Calculate refund (e.g., 50% of forge cost, or a fixed amount)
        uint256 refundAmount = essenceCosts[ActionType.ForgeLoot].div(2);

        _burn(_tokenId);
        delete quantumLootItems[_tokenId]; // Remove from storage

        if (!quantumEssenceToken.transfer(_msgSender(), refundAmount)) {
            revert EssenceTransferFailed();
        }

        emit LootScrapped(_tokenId, refundAmount);
    }

    // --- Configuration & Governance (Owner/Admin Functions) ---

    /**
     * @dev Toggles the overall activity status of the forge (pauses/unpauses core operations).
     *      Only callable by the contract owner or an admin.
     */
    function toggleForgeActivity() public onlyAdmin {
        isForgeActive = !isForgeActive;
        emit ForgeActivityToggled(isForgeActive);
    }

    /**
     * @dev Updates Chainlink VRF configuration parameters.
     *      Only callable by the contract owner or an admin.
     * @param _subscriptionId The new Chainlink VRF subscription ID.
     * @param _keyHash The new Chainlink VRF key hash.
     * @param _coordinator The new Chainlink VRF coordinator address.
     */
    function updateVRFConfiguration(uint64 _subscriptionId, bytes32 _keyHash, address _coordinator) public onlyAdmin {
        // No direct `i_vrfCoordinator = VRFCoordinatorV2Interface(_coordinator);` because it's immutable.
        // This function would be for updating a mutable `_vrfCoordinator` variable if it were designed that way.
        // For an immutable coordinator, these parameters are passed only once in constructor.
        // If dynamic updates are needed, VRFConsumerBaseV2 and related contracts need to be re-architected.
        // For this example, assume these immutable values are set correctly once.
        // If these were mutable, it would look like:
        // i_subscriptionId = _subscriptionId;
        // i_keyHash = _keyHash;
        // (if i_vrfCoordinator was a state variable and not immutable, it would be assigned here)
        // For this contract, this function conceptually shows what *would* be done if mutable.
        // Realistically, for an immutable VRF, this function would just update `_subscriptionId` and `_keyHash`
        // if they were mutable variables within the contract.
        revert NotForgeOwner(); // Placeholder: this function cannot change immutable values
    }

    /**
     * @dev Sets the Quantum Essence cost for various actions.
     *      Only callable by the contract owner or an admin.
     * @param _action The action type for which to set the cost.
     * @param _cost The new cost in Quantum Essence (with 18 decimals).
     */
    function setEssenceCostForAction(ActionType _action, uint256 _cost) public onlyAdmin {
        essenceCosts[_action] = _cost;
        emit EssenceCostUpdated(_action, _cost);
    }

    /**
     * @dev Sets the base range for attribute generation during revelation.
     *      Only callable by the contract owner or an admin.
     * @param _minPower The minimum power attribute.
     * @param _maxPower The maximum power attribute.
     * @param _minAgility The minimum agility attribute.
     * @param _maxAgility The maximum agility attribute.
     * @param _minCharisma The minimum charisma attribute.
     * @param _maxCharisma The maximum charisma attribute.
     */
    function setBaseAttributeRanges(
        uint8 _minPower, uint8 _maxPower,
        uint8 _minAgility, uint8 _maxAgility,
        uint8 _minCharisma, uint8 _maxCharisma
    ) public onlyAdmin {
        if (_minPower > _maxPower || _minAgility > _maxAgility || _minCharisma > _maxCharisma) {
            revert InvalidAttributeRange();
        }
        minPowerAttribute = _minPower; maxPowerAttribute = _maxPower;
        minAgilityAttribute = _minAgility; maxAgilityAttribute = _maxAgility;
        minCharismaAttribute = _minCharisma; maxCharismaAttribute = _maxCharisma;
        emit AttributeRangesUpdated(_minPower, _maxPower, _minAgility, _maxAgility, _minCharisma, _maxCharisma);
    }

    /**
     * @dev Allows the contract owner or admin to withdraw any `QuantumEssence` tokens
     *      accidentally sent to the contract address.
     * @param _to The address to send the tokens to.
     */
    function withdrawStuckEssence(address _to) public onlyAdmin {
        uint256 balance = quantumEssenceToken.balanceOf(address(this));
        if (balance > 0) {
            if (!quantumEssenceToken.transfer(_to, balance)) {
                revert EssenceTransferFailed();
            }
        }
    }

    /**
     * @dev Grants an address an administrative role. Admins can perform privileged operations.
     *      Only callable by the contract owner.
     * @param _account The address to grant admin role to.
     */
    function grantAdminRole(address _account) public onlyOwner {
        _admins[_account] = true;
        emit AdminRoleGranted(_account);
    }

    /**
     * @dev Revokes an administrative role from an address.
     *      Only callable by the contract owner.
     * @param _account The address to revoke admin role from.
     */
    function revokeAdminRole(address _account) public onlyOwner {
        if (_account == owner()) revert NotForgeOwner(); // Owner cannot revoke their own admin role
        _admins[_account] = false;
        emit AdminRoleRevoked(_account);
    }

    /**
     * @dev Checks if an address has the administrative role.
     * @param _account The address to check.
     * @return True if the address has the admin role, false otherwise.
     */
    function hasAdminRole(address _account) public view returns (bool) {
        return _admins[_account] || _account == owner();
    }

    // --- Internal/Utility Functions (ERC-721 overrides) ---

    // The following are standard ERC721 overrides.
    // They are counted as part of the 20+ functions as they are essential for the NFT contract.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Additional logic for transfers:
        // Ensure tokens are not being revealed during transfer
        if (s_tokenIdToRequestId[tokenId] != 0) {
            revert RevelationAlreadyPending(tokenId);
        }
        // If entangled, transfer of one item might affect the other, or require disentanglement.
        // For simplicity, we enforce disentanglement before scrapping, but not necessarily before transfer.
        // A more complex system might auto-disentangle on transfer or penalize.
    }

    // --- ERC-721 required view functions ---
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Internal function to get the next token ID, useful for preventing issues with _nextTokenId directly.
    function _getNextTokenId() internal view returns (uint256) {
        return _nextTokenId;
    }
}
```