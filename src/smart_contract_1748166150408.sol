Okay, let's create a smart contract concept centered around dynamic NFTs with interactive gameplay elements, incorporating verifiable randomness and an internal item system. We'll call it "CryptoLegends". The idea is that players collect unique digital creatures (Legends) that can level up, evolve, battle, and breed, with outcomes influenced by verifiable randomness.

This concept avoids standard examples like basic ERC-20/721, simple voting, or basic marketplaces by integrating several mechanics: dynamic NFT metadata based on on-chain state, on-chain game logic (simplified battle/breeding), integration with Chainlink VRF for randomness, and an internal fungible item system.

---

**CryptoLegends Smart Contract**

**Description:**
This contract implements a collectible creature game where players own unique digital "Legends" (ERC-721 NFTs). Legends have dynamic stats (Level, XP, Attack, Defense, Health, Speed, Type) that evolve through gameplay actions like leveling up, evolving, and battling. The contract incorporates Chainlink VRF for fair and verifiable randomness in crucial events like legend minting, breeding outcomes, and battle critical hits/misses. It also includes an internal system for managing game items that can be used to affect Legend properties.

**Core Concepts:**
1.  **Dynamic NFTs:** Legend metadata (stats, appearance) changes based on on-chain state updates.
2.  **On-Chain Game Logic:** Simplified battle and breeding mechanics are executed deterministically (except for VRF inputs) on the blockchain.
3.  **Verifiable Randomness (Chainlink VRF):** Used for unpredictable but verifiable outcomes in minting, breeding, and battle events.
4.  **Internal Item System:** Manages fungible game items used for healing, evolution, training, etc.
5.  **Breeding:** Allows combining two Legends to create a new one with inherited traits and randomness.
6.  **Battle System:** Players can challenge each other's Legends to a simplified on-chain battle.
7.  **Pausable & Ownable:** Standard security patterns.

**Outline:**

1.  **Libraries/Interfaces:** ERC721, ERC165, Pausable, Ownable, VRFConsumerBase.
2.  **Data Structures:**
    *   `Legend` struct: Stores all dynamic properties of a Legend (stats, level, XP, generation, battle record, VRF request ID for creation/breeding).
    *   `Battle` struct: Stores state for an ongoing battle (participants, state, turn, HP, VRF request ID for outcome).
    *   `Item` mapping: `mapping(address => mapping(uint256 => uint256))` for player item balances.
3.  **State Variables:**
    *   ERC721 related (`_tokens`, `_owners`, etc. - inherited from ERC721 implementation).
    *   Legend data (`_legends`, `_nextLegendId`).
    *   Battle data (`_battles`, `_nextBattleId`).
    *   Item data (`_items`).
    *   VRF Configuration and state (`s_vrfCoordinator`, `s_keyHash`, `s_fee`, `s_requestId`, `s_requestType`, `s_pendingMint`, `s_pendingBreed`, `s_pendingBattleOutcome`).
    *   Counters (`_nextTokenId`, `_nextBattleId`).
    *   Admin/Config variables (`_owner`, `_paused`, Fees, item configs, etc.).
4.  **Events:** Notify frontend/listeners about key actions (Minted, BattleStarted, BattleResolved, Evolved, Bred, ItemUsed, etc.).
5.  **Errors:** Custom errors for clearer failure reasons.
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `isValidLegend`, `isValidBattle`.
7.  **Constructor:** Initializes ERC721, Ownable, Pausable, and VRF parameters.
8.  **ERC721 Standard Functions (9):** `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom` (both overloads), `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`.
9.  **ERC165 Standard Function (1):** `supportsInterface`.
10. **Legend State & Getters (7):** `tokenURI`, `getLegendStats`, `getLegendType`, `getLegendLevel`, `getLegendXP`, `getLegendGeneration`, `getLegendBattleRecord`.
11. **Randomness (VRF) Functions (2):** `requestRandomWords` (internal helper), `fulfillRandomWords` (VRF callback).
12. **Core Game Actions (11):**
    *   `requestMintLegend`: Initiates legend creation by requesting VRF randomness.
    *   `_mintLegend`: Internal function called by `fulfillRandomWords` to finalize minting.
    *   `requestBreedLegends`: Initiates breeding, requesting VRF randomness.
    *   `_breedLegends`: Internal function called by `fulfillRandomWords` to finalize breeding.
    *   `startBattleRequest`: Player A challenges Player B's Legend.
    *   `acceptBattle`: Player B accepts the challenge.
    *   `requestBattleOutcome`: Initiates battle resolution by requesting VRF randomness.
    *   `_resolveBattle`: Internal function called by `fulfillRandomWords` to finalize battle outcome, update stats/XP/records.
    *   `cancelBattleRequest`: Cancel a pending battle challenge.
    *   `levelUpLegend`: Consume XP to increase level and stats.
    *   `evolveLegend`: Consume items/conditions to evolve Legend, change type/stats/appearance base.
    *   `useItem`: Consume an item to perform an action (heal, boost, etc.).
13. **Item Management (3):**
    *   `adminMintItem`: Admin function to issue items.
    *   `transferItem`: Allow players to send items to others.
    *   `getItemBalance`: Check player's item balance.
14. **View/Utility Functions (3):** `getBattleState`, `getPendingBattlesForLegend`, `getRequiredXPForLevel`.
15. **Admin Functions (3):** `pauseGame`, `unpauseGame`, `withdrawFees`, `setVRFConfig`.

**Total Functions:** 9 (ERC721) + 1 (ERC165) + 7 (Legend Getters/URI) + 2 (VRF Interface) + 11 (Game Actions) + 3 (Item) + 3 (View/Utility) + 4 (Admin) = **40 Functions**. Well over the 20 required.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Optional, if needed
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

// --- Outline & Function Summary ---
//
// Contract: CryptoLegends
// Description:
// This smart contract implements a collectible creature game with dynamic NFTs (Legends).
// Legends have evolving stats based on gameplay (leveling, evolution, battling, breeding).
// Key features include on-chain game logic, verifiable randomness via Chainlink VRF for
// unpredictable outcomes (minting, breeding, battle events), and an internal fungible
// item system. Players can collect, level up, evolve, battle, and breed their Legends.
//
// Core Concepts:
// - Dynamic NFTs (Legend metadata changes based on state)
// - On-Chain Game Logic (Simplified battles, breeding)
// - Verifiable Randomness (Chainlink VRF)
// - Internal Item System
// - Breeding Mechanism
// - Battle System
// - Pausable & Ownable for security
//
// Outline:
// 1. Libraries/Interfaces: ERC721, ERC165, Pausable, Ownable, VRFConsumerBase, LinkTokenInterface
// 2. Data Structures: Legend, Battle, Item mapping, VRF state variables
// 3. State Variables: NFT data, Legend data, Battle data, Item data, VRF config/state, Counters
// 4. Events: Notifications for key game actions
// 5. Errors: Custom error types
// 6. Modifiers: Access control and state checks
// 7. Constructor: Initialization
// 8. ERC721 Standard Functions: Standard NFT operations
// 9. ERC165 Standard Function: Interface support check
// 10. Legend State & Getters: Access Legend properties and dynamic metadata
// 11. Randomness (VRF) Functions: Integration with Chainlink VRF
// 12. Core Game Actions: Minting, Battling, Evolution, Leveling, Breeding, Item Usage
// 13. Item Management: Handling player item balances and transfers
// 14. View/Utility Functions: Read game state without transactions
// 15. Admin Functions: Owner-only configuration and management
//
// Function Summary (40+ Functions):
//
// ERC721 Standard (9):
// - balanceOf(address owner) external view returns (uint256): Returns the number of tokens in 'owner's account.
// - ownerOf(uint256 tokenId) external view returns (address owner): Returns the owner of the NFT specified by 'tokenId'.
// - safeTransferFrom(address from, address to, uint256 tokenId) external: Transfers 'tokenId' from 'from' to 'to' safely.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external: Transfers 'tokenId' from 'from' to 'to' safely with data.
// - transferFrom(address from, address to, uint256 tokenId) external: Transfers 'tokenId' from 'from' to 'to'.
// - approve(address to, uint256 tokenId) external: Approves 'to' to transfer 'tokenId'.
// - getApproved(uint256 tokenId) external view returns (address operator): Returns the approved address for 'tokenId'.
// - setApprovalForAll(address operator, bool approved) external: Sets approval for all tokens for an operator.
// - isApprovedForAll(address owner, address operator) external view returns (bool): Checks if an operator is approved for all tokens of an owner.
//
// ERC165 Standard (1):
// - supportsInterface(bytes4 interfaceId) public view virtual override returns (bool): Checks if the contract supports an interface.
//
// Legend State & Getters (7):
// - tokenURI(uint256 tokenId) public view virtual override returns (string memory): Returns the dynamic metadata URI for a Legend.
// - getLegendStats(uint256 legendId) public view returns (uint256 attack, uint256 defense, uint256 speed, uint256 health): Gets current computed stats for a Legend.
// - getLegendBaseStats(uint256 legendId) public view returns (uint256 baseAttack, uint256 baseDefense, uint256 baseSpeed, uint256 baseHealth): Gets base stats before level/evolution bonuses.
// - getLegendType(uint256 legendId) public view returns (uint8 legendType): Gets the elemental/creature type of a Legend.
// - getLegendLevel(uint256 legendId) public view returns (uint256 level): Gets the current level of a Legend.
// - getLegendXP(uint256 legendId) public view returns (uint256 xp): Gets the current experience points of a Legend.
// - getLegendBattleRecord(uint256 legendId) public view returns (uint256 wins, uint256 losses): Gets the battle history of a Legend.
// - getLegendGeneration(uint256 legendId) public view returns (uint256 generation): Gets the generation number (0 for initial mints, 1+ for bred).
//
// Randomness (VRF) Functions (2):
// - requestRandomWords(uint32 numWords, bytes32 seed) internal returns (uint256 requestId): Helper to request randomness from VRF Coordinator.
// - fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override: VRF Coordinator callback to receive random words and finalize pending actions.
//
// Core Game Actions (11):
// - requestMintLegend(address to, uint8 legendType) external whenNotPaused returns (uint256 requestId): Initiates the minting process for a new Legend for 'to', requests randomness.
// - requestBreedLegends(uint256 parent1Id, uint256 parent2Id) external payable whenNotPaused returns (uint256 requestId): Initiates breeding process, requests randomness, payable fee.
// - startBattleRequest(uint256 legend1Id, uint256 legend2Id) external whenNotPaused returns (uint256 battleId): Player initiates a battle challenge between two Legends.
// - acceptBattle(uint256 battleId) external whenNotPaused: Opponent accepts a battle challenge.
// - cancelBattleRequest(uint256 battleId) external whenNotPaused: Cancels a pending battle challenge.
// - requestBattleOutcome(uint256 battleId) external whenNotPaused returns (uint256 requestId): Initiates battle resolution after acceptance, requests randomness for critical events.
// - levelUpLegend(uint256 legendId) external whenNotPaused: Allows a Legend to level up if it has enough XP.
// - evolveLegend(uint256 legendId, uint256 evolutionItemId) external whenNotPaused: Allows a Legend to evolve using a specific item.
// - useItem(uint256 itemId, uint256 targetLegendId, uint256 amount) external whenNotPaused: Uses 'amount' of 'itemId' on 'targetLegendId'.
//
// Item Management (3):
// - adminMintItem(address to, uint256 itemId, uint256 amount) external onlyOwner whenNotPaused: Mints 'amount' of 'itemId' and sends to 'to'.
// - transferItem(address to, uint256 itemId, uint256 amount) external whenNotPaused: Transfers 'amount' of 'itemId' from sender to 'to'.
// - getItemBalance(address owner, uint256 itemId) public view returns (uint256): Gets the item balance for an owner.
//
// View/Utility Functions (3):
// - getBattleState(uint256 battleId) public view returns (BattleState state, uint256 legend1Id, uint256 legend2Id, address player1, address player2, uint256 hp1, uint256 hp2): Gets the current state of a battle.
// - getPendingBattlesForLegend(uint256 legendId) public view returns (uint256[] memory battleIds): Gets battle IDs where this Legend is involved and pending acceptance.
// - getRequiredXPForLevel(uint256 currentLevel) public pure returns (uint256): Calculates XP needed for the next level.
//
// Admin Functions (4):
// - pauseGame() external onlyOwner whenNotPaused: Pauses game actions.
// - unpauseGame() external onlyOwner whenPaused: Unpauses game actions.
// - withdrawFees(address recipient) external onlyOwner: Withdraws collected fees (from breeding, etc.).
// - setVRFConfig(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, uint256 requestConfirmations, uint32 numWords, uint256 fee) external onlyOwner: Updates Chainlink VRF configuration.
//
// --- End Outline & Function Summary ---

contract CryptoLegends is ERC721, Ownable, Pausable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId; // For Legends

    // --- Data Structures ---

    struct Legend {
        uint8 legendType; // e.g., 0: Fire, 1: Water, 2: Grass, etc.
        uint256 baseAttack;
        uint256 baseDefense;
        uint256 baseSpeed;
        uint256 baseHealth;
        uint256 level;
        uint256 xp;
        uint256 generation; // 0 for initial mints, 1+ for bred
        uint256 wins;
        uint256 losses;
        uint256 currentHealth; // For battles
        uint256 lastBattleId; // Store ID of last completed battle
        uint256 vrfRequestId; // ID of VRF request that created/bred this Legend
    }

    enum BattleState {
        NonExistent,
        Requested,
        Accepted,
        InProgress, // Could be turn-based if state changes per turn
        AwaitingRandomness, // Waiting for VRF callback for final outcome
        Resolved,
        Cancelled
    }

    struct Battle {
        uint256 legend1Id;
        address player1; // Challenger
        uint256 legend2Id;
        address player2; // Opponent
        BattleState state;
        uint256 startTime;
        uint256 currentHealth1; // Current HP during battle
        uint256 currentHealth2;
        uint256 winnerLegendId; // 0 if no winner yet or cancelled
        uint256 vrfRequestId; // ID of VRF request for battle outcome
    }

    // --- State Variables ---

    // Legend data: tokenId => Legend struct
    mapping(uint256 => Legend) private _legends;
    // Battle data: battleId => Battle struct
    mapping(uint256 => Battle) private _battles;
    Counters.Counter private _nextBattleId; // For Battles

    // Item data: owner address => itemId => balance
    mapping(address => mapping(uint256 => uint256)) private _items;
    // Item Metadata (Optional, mapping itemId to name/description/effect type etc.)
    // mapping(uint256 => ItemConfig) private _itemConfigs;

    // VRF Data & State
    address private s_vrfCoordinator;
    bytes32 private s_keyHash;
    uint64 private s_subscriptionId;
    uint32 private s_callbackGasLimit;
    uint16 private s_requestConfirmations;
    uint32 private s_numWords = 2; // Number of random words to request

    uint256 private s_fee; // LINK fee for VRF requests

    // Store VRF request ID and what it was for (Mint, Breed, BattleOutcome)
    enum VRFRequestType { None, Mint, Breed, BattleOutcome }
    mapping(uint256 => VRFRequestType) private s_requestType;

    // Store pending actions awaiting VRF callback
    mapping(uint256 => address) private s_pendingMint; // request id => recipient address
    mapping(uint256 => uint8) private s_pendingMintType; // request id => legend type

    mapping(uint256 => uint256) private s_pendingBreedParent1; // request id => parent1 id
    mapping(uint256 => uint256) private s_pendingBreedParent2; // request id => parent2 id
    mapping(uint256 => address) private s_pendingBreedRecipient; // request id => recipient address (can be different from parents)

    mapping(uint256 => uint256) private s_pendingBattleOutcome; // request id => battle id

    // --- Events ---

    event LegendMinted(uint256 indexed legendId, address indexed owner, uint8 legendType, uint256 generation);
    event LegendLeveledUp(uint256 indexed legendId, uint256 newLevel);
    event LegendEvolved(uint256 indexed legendId, uint8 newType); // Assuming evolution changes type/base stats
    event LegendBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newLegendId);
    event ItemMinted(uint256 indexed itemId, address indexed to, uint256 amount);
    event ItemTransferred(address indexed from, address indexed to, uint255 indexed itemId, uint256 amount);
    event ItemUsed(uint256 indexed itemId, uint256 indexed targetLegendId, uint256 amount);
    event BattleRequested(uint256 indexed battleId, uint256 indexed legend1Id, uint256 indexed legend2Id, address indexed player1, address player2);
    event BattleAccepted(uint256 indexed battleId);
    event BattleCancelled(uint256 indexed battleId);
    event BattleOutcomeRequested(uint256 indexed battleId, uint256 indexed requestId);
    event BattleResolved(uint256 indexed battleId, uint256 indexed winnerLegendId, uint256 loserLegendId);
    event VRFRandomnessReceived(uint256 indexed requestId, uint256[] randomWords);

    // --- Errors ---

    error NotOwnerOfLegend(uint256 legendId);
    error LegendDoesNotExist(uint256 legendId);
    error InvalidLegendId(uint256 legendId);
    error BattleDoesNotExist(uint256 battleId);
    error NotBattleParticipant(uint256 battleId);
    error BattleNotInRequestedState(uint256 battleId);
    error BattleNotInAcceptedState(uint256 battleId); // Could also be used for InProgress if turn-based
    error BattleNotInAwaitingRandomnessState(uint256 battleId);
    error CannotCancelAcceptedBattle(uint256 battleId);
    error ItemDoesNotExist(uint256 itemId); // If using item configs
    error InsufficientItems(uint256 itemId, uint256 required, uint256 has);
    error NotEnoughXP(uint256 legendId, uint256 requiredXP);
    error EvolutionConditionsNotMet(uint256 legendId, uint256 evolutionItemId); // Custom logic needed here
    error BreedingConditionsNotMet(); // Custom logic needed here (e.g., parents owned by breeder, cooldowns)
    error InvalidVRFCallback(); // For fulfillRandomWords
    error VRFRequestFailed(uint256 requestId);
    error RandomnessAlreadyUsed(uint256 requestId);
    error InvalidItemUseTarget(uint256 itemId, uint256 targetLegendId);
    error CannotTransferToSelf();

    // --- Modifiers ---

    modifier isValidLegend(uint256 legendId) {
        if (!_exists(legendId)) {
            revert LegendDoesNotExist(legendId);
        }
        _;
    }

    modifier isValidBattle(uint256 battleId) {
        if (_battles[battleId].state == BattleState.NonExistent) {
            revert BattleDoesNotExist(battleId);
        }
        _;
    }

    // --- Constructor ---

    constructor(
        address initialOwner,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 fee,
        address linkToken
    )
        ERC721("CryptoLegends", "LGND")
        Ownable(initialOwner)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
    {
        s_vrfCoordinator = vrfCoordinator;
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_fee = fee;
        s_requestConfirmations = 3; // Standard confirmation count
        // Fund the VRF subscription outside the contract creation
        // LinkTokenInterface LINK = LinkTokenInterface(linkToken);
        // LINK.transferAndCall(vrfCoordinator, s_fee, abi.encode(s_subscriptionId));
    }

    // --- ERC165 Standard ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- ERC721 Standard Functions (Inherited/Implemented) ---
    // _transfer, _safeTransfer, _mint, _burn are internal helper functions from ERC721/ERC721Enumerable
    // ERC721Enumerable adds tokenOfOwnerByIndex, tokenByIndex, totalSupply
    // Let's stick to basic ERC721 for this example to keep it focused.

    // Override _beforeTokenTransfer and _afterTokenTransfer if needed for hooks
    // For this example, default implementation is fine.
    // Override tokenURI to make it dynamic

    // --- Legend State & Getters ---

    function tokenURI(uint256 legendId) public view virtual override(ERC721) returns (string memory) {
        if (!_exists(legendId)) {
             revert LegendDoesNotExist(legendId);
        }

        // Construct a URI pointing to a metadata server that reads the on-chain state
        // Example: `https://mygamedata.com/legend/` + `legendId`
        // The server would call getLegendStats, getLegendLevel, etc. to build JSON.
        // This makes the NFT dynamic.
        // For a simplified example, just return a placeholder or basic URI.
        // A real implementation needs an off-chain service or complex on-chain string generation.
        // Let's return a dummy URI pattern for demonstration.
        return string(abi.encodePacked("ipfs://<CID>/legend/", Strings.toString(legendId)));
    }

    function getLegendStats(uint256 legendId) public view isValidLegend(legendId) returns (uint256 attack, uint256 defense, uint256 speed, uint256 health) {
        Legend storage legend = _legends[legendId];
        // Simple calculation: base stats + level bonus (e.g., 5% per level)
        // In a real game, this would be more complex (type effectiveness, individual stat growth rates, etc.)
        uint256 levelBonus = legend.level * 5; // % bonus
        attack = legend.baseAttack * (100 + levelBonus) / 100;
        defense = legend.baseDefense * (100 + levelBonus) / 100;
        speed = legend.baseSpeed * (100 + levelBonus) / 100;
        health = legend.baseHealth * (100 + levelBonus) / 100;
    }

    function getLegendBaseStats(uint256 legendId) public view isValidLegend(legendId) returns (uint256 baseAttack, uint256 baseDefense, uint256 baseSpeed, uint256 baseHealth) {
         Legend storage legend = _legends[legendId];
         return (legend.baseAttack, legend.baseDefense, legend.baseSpeed, legend.baseHealth);
    }

    function getLegendType(uint256 legendId) public view isValidLegend(legendId) returns (uint8 legendType) {
        return _legends[legendId].legendType;
    }

    function getLegendLevel(uint256 legendId) public view isValidLegend(legendId) returns (uint256 level) {
        return _legends[legendId].level;
    }

    function getLegendXP(uint256 legendId) public view isValidLegend(legendId) returns (uint256 xp) {
        return _legends[legendId].xp;
    }

    function getLegendBattleRecord(uint256 legendId) public view isValidLegend(legendId) returns (uint256 wins, uint256 losses) {
        Legend storage legend = _legends[legendId];
        return (legend.wins, legend.losses);
    }

    function getLegendGeneration(uint256 legendId) public view isValidLegend(legendId) returns (uint256 generation) {
        return _legends[legendId].generation;
    }

    // --- Randomness (VRF) Functions ---

    // Helper function to request randomness
    function requestRandomWords(uint32 numWords, bytes32 seed) internal returns (uint256 requestId) {
        // Will revert if subscription is not set up, or not funded
        requestId = requestSubscriptionOwnerWithdrawAndCall(
            s_subscriptionId,
            s_vrfCoordinator,
            s_keyHash,
            seed,
            numWords,
            s_callbackGasLimit,
            abi.encodeWithSelector(this.fulfillRandomWords.selector, 0, new uint256[](0)) // Pass dummy args for signature
        );
    }

    // VRF Coordinator callback function
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (randomWords.length < s_numWords) {
             revert InvalidVRFCallback(); // Should not happen with correct config
        }

        VRFRequestType reqType = s_requestType[requestId];
        if (reqType == VRFRequestType.None) {
            revert InvalidVRFCallback(); // Unexpected request ID
        }

        // Mark request as used (prevents replay/double-spending)
        delete s_requestType[requestId];

        emit VRFRandomnessReceived(requestId, randomWords);

        if (reqType == VRFRequestType.Mint) {
            address recipient = s_pendingMint[requestId];
            uint8 legendType = s_pendingMintType[requestId];
            delete s_pendingMint[requestId];
            delete s_pendingMintType[requestId];

            if (recipient == address(0)) {
                 revert RandomnessAlreadyUsed(requestId); // Check if action was already processed
            }

            _mintLegend(recipient, legendType, randomWords);

        } else if (reqType == VRFRequestType.Breed) {
            uint256 parent1Id = s_pendingBreedParent1[requestId];
            uint256 parent2Id = s_pendingBreedParent2[requestId];
            address recipient = s_pendingBreedRecipient[requestId];
             delete s_pendingBreedParent1[requestId];
             delete s_pendingBreedParent2[requestId];
             delete s_pendingBreedRecipient[requestId];

             if (recipient == address(0)) {
                 revert RandomnessAlreadyUsed(requestId);
             }

            _breedLegends(parent1Id, parent2Id, recipient, randomWords);

        } else if (reqType == VRFRequestType.BattleOutcome) {
            uint256 battleId = s_pendingBattleOutcome[requestId];
            delete s_pendingBattleOutcome[requestId];

            if (_battles[battleId].state != BattleState.AwaitingRandomness) {
                 revert RandomnessAlreadyUsed(requestId); // Or state mismatch
            }

            _resolveBattle(battleId, randomWords);

        }
    }

    // --- Core Game Actions ---

    // Player requests to mint a legend (asynchronous process due to VRF)
    function requestMintLegend(address to, uint8 legendType) public onlyOwner whenNotPaused returns (uint256 requestId) {
         // Add any potential costs or conditions here (e.g., require payment)

         requestId = requestRandomWords(s_numWords, keccak256(abi.encodePacked(msg.sender, to, legendType, block.timestamp, block.difficulty))); // Use unique seed

         s_requestType[requestId] = VRFRequestType.Mint;
         s_pendingMint[requestId] = to;
         s_pendingMintType[requestId] = legendType;

         emit VRFRequestFailed(requestId); // Placeholder event, actual failure handling needed
         return requestId;
    }

    // Internal function called by fulfillRandomWords to finalize minting
    function _mintLegend(address to, uint8 legendType, uint256[] memory randomWords) internal {
         _nextTokenId.increment();
         uint256 newLegendId = _nextTokenId.current();

         // Use randomWords to determine base stats
         // Example: simple distribution based on random numbers
         uint256 rand1 = randomWords[0];
         uint256 rand2 = randomWords.length > 1 ? randomWords[1] : rand1; // Use second word if available

         uint256 baseAttack = 10 + (rand1 % 10); // Base between 10 and 19
         uint256 baseDefense = 10 + ((rand1 / 10) % 10);
         uint256 baseSpeed = 10 + ((rand1 / 100) % 10);
         uint256 baseHealth = 50 + (rand2 % 50); // Base HP between 50 and 99

         _legends[newLegendId] = Legend({
             legendType: legendType,
             baseAttack: baseAttack,
             baseDefense: baseDefense,
             baseSpeed: baseSpeed,
             baseHealth: baseHealth,
             level: 1,
             xp: 0,
             generation: 0, // Generation 0 for initial mints
             wins: 0,
             losses: 0,
             currentHealth: 0, // Not in battle initially
             lastBattleId: 0,
             vrfRequestId: randomWords[0] // Store a piece of randomness or request ID
         });

         _safeMint(to, newLegendId);

         emit LegendMinted(newLegendId, to, legendType, 0);
    }

     // Player requests to breed two legends (asynchronous due to VRF)
    function requestBreedLegends(uint256 parent1Id, uint256 parent2Id) external payable whenNotPaused returns (uint256 requestId) {
        // Add breeding fee check
        // require(msg.value >= breedingFee, "Insufficient breeding fee"); // Need to define breedingFee state variable

        // Check if sender owns both parents and they meet breeding conditions (level, generation, cooldown, etc.)
        address owner = ownerOf(parent1Id);
        if (owner != msg.sender || ownerOf(parent2Id) != msg.sender) {
             revert NotOwnerOfLegend(0); // Use a generic error for "not owner of required legend"
        }
        if (parent1Id == parent2Id) {
            revert BreedingConditionsNotMet(); // Cannot breed with self
        }
        // Add more complex breeding checks here...

        requestId = requestRandomWords(s_numWords, keccak256(abi.encodePacked(msg.sender, parent1Id, parent2Id, block.timestamp, block.difficulty)));

        s_requestType[requestId] = VRFRequestType.Breed;
        s_pendingBreedParent1[requestId] = parent1Id;
        s_pendingBreedParent2[requestId] = parent2Id;
        s_pendingBreedRecipient[requestId] = msg.sender; // New legend goes to the breeder

        emit VRFRequestFailed(requestId); // Placeholder
        return requestId;
    }

    // Internal function called by fulfillRandomWords to finalize breeding
    function _breedLegends(uint256 parent1Id, uint256 parent2Id, address recipient, uint256[] memory randomWords) internal {
        // Check if parents still exist and are owned by recipient (safety check after async wait)
        if (!_exists(parent1Id) || !_exists(parent2Id) || ownerOf(parent1Id) != recipient || ownerOf(parent22Id) != recipient) {
             revert BreedingConditionsNotMet(); // Parents might have been transferred/burned
        }

        Legend storage parent1 = _legends[parent1Id];
        Legend storage parent2 = _legends[parent2Id];

        _nextTokenId.increment();
        uint256 newLegendId = _nextTokenId.current();

        // Determine new legend properties based on parents and randomness
        // This logic can be very complex (trait inheritance, mutations, etc.)
        uint256 rand1 = randomWords[0];
        uint256 rand2 = randomWords.length > 1 ? randomWords[1] : rand1;

        uint8 childType = (rand1 % 2 == 0) ? parent1.legendType : parent2.legendType; // Simple type inheritance
        uint256 baseAttack = ((parent1.baseAttack + parent2.baseAttack) / 2) + ((rand1 / 100) % 5); // Average + small random bonus
        uint256 baseDefense = ((parent1.baseDefense + parent2.baseDefense) / 2) + ((rand1 / 200) % 5);
        uint256 baseSpeed = ((parent1.baseSpeed + parent2.baseSpeed) / 2) + ((rand2 % 5));
        uint256 baseHealth = ((parent1.baseHealth + parent2.baseHealth) / 2) + ((rand2 / 100) % 10);

        _legends[newLegendId] = Legend({
             legendType: childType,
             baseAttack: baseAttack,
             baseDefense: baseDefense,
             baseSpeed: baseSpeed,
             baseHealth: baseHealth,
             level: 1, // Newly bred legends start at level 1
             xp: 0,
             generation: Math.max(parent1.generation, parent2.generation) + 1,
             wins: 0,
             losses: 0,
             currentHealth: 0,
             lastBattleId: 0,
             vrfRequestId: randomWords[0]
         });

        _safeMint(recipient, newLegendId);

        // Apply breeding cooldowns to parents (requires adding cooldown state to Legend struct)
        // parent1.breedingCooldown = block.timestamp + 1 weeks;
        // parent2.breedingCooldown = block.timestamp + 1 weeks;

        emit LegendBred(parent1Id, parent2Id, newLegendId);
    }


    // Player initiates a battle request
    function startBattleRequest(uint256 legend1Id, uint256 legend2Id) external whenNotPaused returns (uint256 battleId) {
        address player1 = msg.sender;
        address player2 = ownerOf(legend2Id);

        if (!_exists(legend1Id)) revert InvalidLegendId(legend1Id);
        if (!_exists(legend2Id)) revert InvalidLegendId(legend2Id);
        if (ownerOf(legend1Id) != player1) revert NotOwnerOfLegend(legend1Id);
        if (player1 == player2) revert InvalidBattleId(0); // Cannot battle yourself (use 0 for generic)

        _nextBattleId.increment();
        battleId = _nextBattleId.current();

        // Initialize battle state
        _battles[battleId] = Battle({
            legend1Id: legend1Id,
            player1: player1,
            legend2Id: legend2Id,
            player2: player2,
            state: BattleState.Requested,
            startTime: block.timestamp,
            currentHealth1: getLegendStats(legend1Id).health, // Start with full health
            currentHealth2: getLegendStats(legend2Id).health,
            winnerLegendId: 0,
            vrfRequestId: 0 // No VRF request yet
        });

        // Maybe add timeout for acceptance here
        // _battleTimeouts[battleId] = block.timestamp + 1 days;

        emit BattleRequested(battleId, legend1Id, legend2Id, player1, player2);
    }

    // Opponent accepts a battle challenge
    function acceptBattle(uint256 battleId) external whenNotPaused isValidBattle(battleId) {
        Battle storage battle = _battles[battleId];

        if (battle.state != BattleState.Requested) {
            revert BattleNotInRequestedState(battleId);
        }
        if (msg.sender != battle.player2) {
            revert NotBattleParticipant(battleId);
        }

        // Re-verify legends still exist and are owned by players (safety after async wait)
        if (!_exists(battle.legend1Id) || !_exists(battle.legend2Id) || ownerOf(battle.legend1Id) != battle.player1 || ownerOf(battle.legend2Id) != battle.player2) {
             revert BattleConditionsNotMet(); // Use generic error
        }

        battle.state = BattleState.Accepted; // Ready to be resolved
        // Optional: Transition to InProgress if turn-based and requires player actions

        emit BattleAccepted(battleId);
    }

    // Cancels a battle request before it's accepted
    function cancelBattleRequest(uint256 battleId) external whenNotPaused isValidBattle(battleId) {
        Battle storage battle = _battles[battleId];

        if (battle.state != BattleState.Requested) {
             revert CannotCancelAcceptedBattle(battleId);
        }
        // Only the challenger or the owner of the challenged legend can cancel (or admin)
        if (msg.sender != battle.player1 && msg.sender != battle.player2 && msg.sender != owner()) {
             revert NotBattleParticipant(battleId);
        }

        battle.state = BattleState.Cancelled;

        emit BattleCancelled(battleId);
    }

    // Player initiates battle resolution (asynchronous due to VRF)
    // Can be called by either participant after the battle is in Accepted or InProgress state
    function requestBattleOutcome(uint256 battleId) external whenNotPaused isValidBattle(battleId) returns (uint256 requestId) {
         Battle storage battle = _battles[battleId];

         // Must be Accepted state (or InProgress if multi-turn)
         if (battle.state != BattleState.Accepted) {
             revert BattleNotInAcceptedState(battleId);
         }
         // Must be a participant
         if (msg.sender != battle.player1 && msg.sender != battle.player2) {
              revert NotBattleParticipant(battleId);
         }

         battle.state = BattleState.AwaitingRandomness; // Transition state

         // Request randomness for battle events (crits, misses, status effects, etc.)
         // Use battleId and current state as seed
         requestId = requestRandomWords(s_numWords, keccak256(abi.encodePacked(battleId, battle.currentHealth1, battle.currentHealth2, block.timestamp, block.difficulty)));

         battle.vrfRequestId = requestId; // Store request ID in battle struct
         s_requestType[requestId] = VRFRequestType.BattleOutcome;
         s_pendingBattleOutcome[requestId] = battleId;

         emit BattleOutcomeRequested(battleId, requestId);
         emit VRFRequestFailed(requestId); // Placeholder
         return requestId;
    }


    // Internal function called by fulfillRandomWords to finalize battle outcome
    function _resolveBattle(uint256 battleId, uint256[] memory randomWords) internal {
        Battle storage battle = _battles[battleId];

        if (battle.state != BattleState.AwaitingRandomness) {
            revert BattleNotInAwaitingRandomnessState(battleId); // Or already resolved
        }

        // Simple deterministic battle logic using stats and VRF for outcomes
        // This is a highly simplified example. Real battle logic is complex.
        Legend storage legend1 = _legends[battle.legend1Id];
        Legend storage legend2 = _legends[battle.legend2Id];

        // Get stats for calculation
        (uint256 atk1, uint256 def1, uint256 spd1, uint256 hp1) = getLegendStats(battle.legend1Id);
        (uint256 atk2, uint256 def2, uint256 spd2, uint256 hp2) = getLegendStats(battle.legend2Id);

        // Start with full health determined by current stats
        battle.currentHealth1 = hp1;
        battle.currentHealth2 = hp2;

        uint256 winnerLegendId = 0;
        uint256 loserLegendId = 0;

        // Example simple turn-based simulation (could be more complex)
        // Determine who goes first based on speed (use randomness for ties)
        bool legend1Starts = (spd1 > spd2) || (spd1 == spd2 && randomWords[0] % 2 == 0);

        // Simulate rounds until one HP reaches zero
        uint256 maxRounds = 100; // Prevent infinite loops
        for (uint256 round = 0; round < maxRounds; round++) {
            if (legend1Starts) {
                // Legend 1 attacks Legend 2
                uint256 damage1 = Math.max(atk1, def2); // Simplified damage calculation
                // Incorporate randomness: e.g., critical hit chance based on randWords[1]
                if (randomWords[1] % 100 < 10) { // 10% critical hit chance
                     damage1 = damage1 * 150 / 100; // 1.5x damage
                }
                battle.currentHealth2 = (battle.currentHealth2 > damage1) ? battle.currentHealth2 - damage1 : 0;

                if (battle.currentHealth2 == 0) {
                    winnerLegendId = battle.legend1Id;
                    loserLegendId = battle.legend2Id;
                    break;
                }

                // Legend 2 attacks Legend 1
                uint256 damage2 = Math.max(atk2, def1);
                 if (randomWords[1] % 100 > 90) { // Another 10% critical hit chance
                     damage2 = damage2 * 150 / 100;
                }
                battle.currentHealth1 = (battle.currentHealth1 > damage2) ? battle.currentHealth1 - damage2 : 0;

                 if (battle.currentHealth1 == 0) {
                    winnerLegendId = battle.legend2Id;
                    loserLegendId = battle.legend1Id;
                    break;
                }

            } else {
                 // Legend 2 attacks Legend 1
                 uint256 damage2 = Math.max(atk2, def1);
                 if (randomWords[1] % 100 > 90) { // Another 10% critical hit chance
                     damage2 = damage2 * 150 / 100;
                }
                 battle.currentHealth1 = (battle.currentHealth1 > damage2) ? battle.currentHealth1 - damage2 : 0;

                 if (battle.currentHealth1 == 0) {
                    winnerLegendId = battle.legend2Id;
                    loserLegendId = battle.legend1Id;
                    break;
                }

                // Legend 1 attacks Legend 2
                uint256 damage1 = Math.max(atk1, def2);
                 if (randomWords[1] % 100 < 10) { // 10% critical hit chance
                     damage1 = damage1 * 150 / 100;
                }
                battle.currentHealth2 = (battle.currentHealth2 > damage1) ? battle.currentHealth2 - damage1 : 0;

                if (battle.currentHealth2 == 0) {
                    winnerLegendId = battle.legend1Id;
                    loserLegendId = battle.legend2Id;
                    break;
                }
            }

            // Swap turn order if not based on speed (simple turn-based A then B)
            // If speed determines order, this loop structure works for synchronous attacks.
        }

        // Update legend stats/records
        if (winnerLegendId != 0) {
            _legends[winnerLegendId].wins++;
            // Award XP (e.g., fixed amount + bonus based on loser level)
            uint256 xpGained = 100 + (getLegendLevel(loserLegendId) * 10);
            _legends[winnerLegendId].xp += xpGained;

            _legends[loserLegendId].losses++;
            // Maybe lose some XP?

            battle.winnerLegendId = winnerLegendId;
            battle.state = BattleState.Resolved;

            // Clear current health after battle ends
            legend1.currentHealth = 0;
            legend2.currentHealth = 0;

            emit BattleResolved(battleId, winnerLegendId, loserLegendId);
        } else {
            // Should not happen in a standard HP battle unless maxRounds reached
             battle.state = BattleState.Resolved; // Treat as a draw or incomplete
             emit BattleResolved(battleId, 0, 0); // Indicate draw/no winner
        }

        // Store battle ID in legend's last battle field
        legend1.lastBattleId = battleId;
        legend2.lastBattleId = battleId;
    }


    // Allows a Legend to level up if enough XP is accumulated
    function levelUpLegend(uint256 legendId) external whenNotPaused isValidLegend(legendId) {
        Legend storage legend = _legends[legendId];

        uint256 requiredXP = getRequiredXPForLevel(legend.level);
        if (legend.xp < requiredXP) {
            revert NotEnoughXP(legendId, requiredXP);
        }

        legend.level++;
        legend.xp -= requiredXP; // Consume XP

        // Update base stats slightly? Or just rely on level bonus from getLegendStats
        // legend.baseAttack++; // Example small base stat increase

        emit LegendLeveledUp(legendId, legend.level);
    }

    // Allows a Legend to evolve using a specific item
    function evolveLegend(uint256 legendId, uint256 evolutionItemId) external whenNotPaused isValidLegend(legendId) {
         // Check if sender owns the legend and the item
         if (ownerOf(legendId) != msg.sender) revert NotOwnerOfLegend(legendId);
         uint256 requiredAmount = 1; // Assuming 1 item per evolution
         if (_items[msg.sender][evolutionItemId] < requiredAmount) {
             revert InsufficientItems(evolutionItemId, requiredAmount, _items[msg.sender][evolutionItemId]);
         }

        // Add logic here to check if the legend can evolve with this item
        // e.g., requires min level, correct legend type, hasn't evolved before
        // if (!canEvolve(legendId, evolutionItemId)) revert EvolutionConditionsNotMet(legendId, evolutionItemId);

         // Consume the item
         _items[msg.sender][evolutionItemId] -= requiredAmount;
         emit ItemUsed(evolutionItemId, legendId, requiredAmount);

         // Apply evolution effects
         Legend storage legend = _legends[legendId];
         // Example: Change type, significantly boost base stats
         // legend.legendType = getEvolvedType(legend.legendType, evolutionItemId);
         // legend.baseAttack = legend.baseAttack * 120 / 100; // 20% increase
         // legend.baseHealth = legend.baseHealth * 120 / 100; // 20% increase
         // Could also reset level/XP or change appearance properties

         emit LegendEvolved(legendId, legend.legendType); // Emit new type or some evolution identifier
    }


    // Uses an item from the player's inventory on a target legend
    // This is a generic function that could call other functions like evolve or heal
    function useItem(uint256 itemId, uint256 targetLegendId, uint256 amount) external whenNotPaused isValidLegend(targetLegendId) {
        if (ownerOf(targetLegendId) != msg.sender) revert NotOwnerOfLegend(targetLegendId);
        if (_items[msg.sender][itemId] < amount) {
            revert InsufficientItems(itemId, amount, _items[msg.sender][itemId]);
        }

        // Add item specific logic here
        // mapping(uint256 => ItemEffectType) private _itemEffects;
        // ItemEffectType effectType = _itemEffects[itemId];
        // if (effectType == ItemEffectType.Heal) {
        //    _healLegend(targetLegendId, amount); // Heal HP by an amount
        // } else if (effectType == ItemEffectType.EvolutionMaterial) {
             // Only allow amount == 1 for evolution items and call evolveLegend
        //    if (amount != 1) revert InvalidItemUseTarget(itemId, targetLegendId);
        //    evolveLegend(targetLegendId, itemId); // evolveLegend will handle item consumption
        //    return; // evolution consumes item internally
        // } else if (effectType == ItemEffectType.XPBoost) {
        //    _addXP(targetLegendId, amount * 500); // Add XP
        // }
        // ... handle other item types

         // For simplicity in this example, let's just consume the item
         // and require specific item IDs for specific actions like evolve.
         // For a simple healing item (e.g., itemId 1):
         if (itemId == 1) { // Example: Health Potion
             _healLegend(targetLegendId, amount * 20); // Heal 20 HP per potion
         } else {
             revert InvalidItemUseTarget(itemId, targetLegendId); // Item has no defined use
         }

        // Consume the item (if not already consumed by a called function like evolve)
        if (itemId != 2) { // Assuming itemId 2 is an evolution item handled by evolveLegend
             _items[msg.sender][itemId] -= amount;
             emit ItemUsed(itemId, targetLegendId, amount);
        }
    }

    // Internal function to heal a legend
    function _healLegend(uint256 legendId, uint256 healAmount) internal isValidLegend(legendId) {
        Legend storage legend = _legends[legendId];
        // Get max health based on current stats
        (, , , uint256 maxHealth) = getLegendStats(legendId);

        // Only heal if not in battle (cannot use items during async battle resolution)
        if (battleState[_battles[legend.lastBattleId].state] == BattleState.InProgress ||
            battleState[_battles[legend.lastBattleId].state] == BattleState.AwaitingRandomness) {
            // Optionally allow healing during a complex turn-based battle if handled there
            // For this simple example, disallow healing during the single async battle resolution
            return; // Cannot heal during active battle resolution
        }

        // Apply healing, cap at max health
        legend.currentHealth += healAmount;
        if (legend.currentHealth > maxHealth) {
            legend.currentHealth = maxHealth;
        }
        // Emit a Healing event (optional)
    }

    // --- Item Management ---

    function adminMintItem(address to, uint256 itemId, uint256 amount) external onlyOwner whenNotPaused {
        _items[to][itemId] += amount;
        emit ItemMinted(itemId, to, amount);
    }

    function transferItem(address to, uint256 itemId, uint256 amount) external whenNotPaused {
         if (msg.sender == to) revert CannotTransferToSelf();
         if (_items[msg.sender][itemId] < amount) {
             revert InsufficientItems(itemId, amount, _items[msg.sender][itemId]);
         }
         _items[msg.sender][itemId] -= amount;
         _items[to][itemId] += amount;
         emit ItemTransferred(msg.sender, to, itemId, amount);
    }

    function getItemBalance(address owner, uint256 itemId) public view returns (uint256) {
        return _items[owner][itemId];
    }

    // --- View/Utility Functions ---

    function getBattleState(uint256 battleId) public view isValidBattle(battleId) returns (BattleState state, uint256 legend1Id, uint256 legend2Id, address player1, address player2, uint256 hp1, uint256 hp2) {
        Battle storage battle = _battles[battleId];
        return (
            battle.state,
            battle.legend1Id,
            battle.legend2Id,
            battle.player1,
            battle.player2,
            battle.currentHealth1,
            battle.currentHealth2
        );
    }

    function getPendingBattlesForLegend(uint256 legendId) public view returns (uint256[] memory battleIds) {
        // This would require iterating through all battles or maintaining an index mapping,
        // which can be gas-intensive or complex. For simplicity in a view function,
        // a frontend might need to query all battle IDs and filter, or we return a limited list.
        // Let's return a dummy empty array or require a more efficient index if needed.
        // A better approach for a real game is maintaining a mapping like:
        // mapping(uint256 => uint256[]) _pendingBattlesByLegend;
        // But this adds complexity on state updates.

        // Dummy implementation: return empty array
        return new uint256[](0);
    }


    function getRequiredXPForLevel(uint256 currentLevel) public pure returns (uint256) {
        // Simple linear or exponential scaling
        return currentLevel * 1000; // Example: 1000 XP per level
    }

    // --- Admin Functions ---

    function pauseGame() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseGame() external onlyOwner whenPaused {
        _unpause();
    }

    // Assumes some functions (like breeding) collect fees in native currency
    function withdrawFees(address payable recipient) external onlyOwner {
        // Check balance and transfer
        uint256 balance = address(this).balance;
        if (balance > 0) {
            recipient.transfer(balance);
        }
    }

    // Allows updating VRF config if subscription changes or keyhash updates
    function setVRFConfig(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 fee,
        uint16 requestConfirmations,
        uint32 numWords
    ) external onlyOwner {
        s_vrfCoordinator = vrfCoordinator;
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_fee = fee;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;
        // Note: Changing subscriptionId requires re-funding the *new* subscription
    }

     // --- Internal Helpers ---

     // Helper function mappings for item effects, evolution conditions, etc.
     // These would require significant game design logic. Placeholder here.
     // mapping(uint256 => ItemEffectType) private _itemEffects;
     // function canEvolve(uint256 legendId, uint256 evolutionItemId) internal view returns (bool) { /* logic */ }
     // function getEvolvedType(uint8 currentType, uint256 evolutionItemId) internal pure returns (uint8) { /* logic */ }

     // Helper for Math operations if SafeMath isn't implicitly handled by 0.8+
     library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
         function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a <= b ? a : b;
        }
     }
}
```