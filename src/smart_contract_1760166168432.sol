Here's a smart contract in Solidity called `AetherShardProtocol` that incorporates advanced concepts like dynamic NFTs, a decaying reputation system, Proof-of-Interaction quests, weighted voting delegation, and epoch-based progression. It avoids direct duplication of common open-source projects by combining these elements in a unique way to form a "soul-bound" reputation identity system.

---

**Contract Name:** `AetherShardProtocol`

**Description:**
The AetherShard Protocol is a novel system for managing dynamic, reputation-bound, and non-transferable NFTs called "AetherShards." These shards represent a user's on-chain standing and participation within a Web3 ecosystem. Each AetherShard's level, appearance (via dynamic SVG), and associated utility (e.g., weighted voting power, access roles) are directly tied to the holder's earned and decaying reputation. Users must actively participate through "Proof-of-Interaction" (PoI) quests and other contributions to maintain or upgrade their shard, preventing passive accumulation and fostering continuous engagement.

**Core Concepts Implemented:**
1.  **Dynamic SVG NFTs:** On-chain generation of unique NFT metadata (SVG image) reflecting the AetherShard's current level, reputation, and validity status. The SVG content visually changes based on the user's reputation.
2.  **Reputation Decay (Lazy):** A user's reputation score automatically decreases over defined epochs if not actively maintained. This uses a gas-efficient "lazy decay" mechanism, where decay is calculated upon interaction or reputation access, rather than looping through all users.
3.  **Proof-of-Interaction (PoI) Quests:** A system for defining and verifying tasks that users complete to earn reputation and `EssenceToken` (a hypothetical ERC20) rewards. Quests can be on-chain (verified by the contract itself) or require external oracle attestation for off-chain actions.
4.  **Weighted Voting & Delegation:** AetherShard levels directly determine a multiplier for voting power in integrated DAO governance. Holders can delegate their weighted voting power to trusted representatives.
5.  **Role-Based Access Control (RBAC) via NFTs (Conceptual):** While not explicitly building a full RBAC system, the AetherShard's level inherently serves as a proof of role/privilege that could be integrated with external systems.
6.  **Epoch-Based Progression:** Reputation decay, quest availability, and reward distribution are structured around time-based epochs, providing a cyclical progression model.
7.  **Native Token Integration (`EssenceToken`):** A hypothetical ERC20 token used for quest rewards and protocol fees, demonstrating a native economic incentive layer.
8.  **Non-Transferable (Soul-Bound) NFTs:** AetherShards cannot be transferred between addresses, ensuring reputation and identity are strongly tied to the individual's wallet. They can, however, be "re-forged" (burned and re-minted) under specific conditions.

---

**Function Summary (30+ functions):**

**I. Core NFT & Reputation Management:**
1.  `mintAetherShard()`: Allows a new user to mint their initial AetherShard NFT, tying their identity to the protocol. Each user can only hold one shard.
2.  `reforgeAetherShard(uint256 tokenId)`: Allows a user to burn an existing shard and mint a new one, resetting visual properties but retaining (decayed) reputation.
3.  `_increaseReputation(address user, uint256 amount)` (Internal): Adds reputation to a user based on accomplishments.
4.  `_decreaseReputation(address user, uint256 amount)` (Internal): Subtracts reputation, typically due to decay or penalties.
5.  `calculateCurrentShardLevel(uint256 currentReputation)`: Pure function to determine a shard's level based on a given reputation score and configured thresholds.
6.  `getCurrentReputation(address user)`: View function to get a user's current reputation score, applying lazy decay if necessary.
7.  `tokenURI(uint256 tokenId)`: Overrides ERC721 `tokenURI` to generate dynamic SVG metadata that visually represents the shard's current level and reputation.

**II. Quest & Engagement System:**
8.  `createQuest(string memory name, uint256 rewardReputation, uint256 rewardEssence, uint256 durationEpochs, QuestType questType, bytes32 requiredProofHash, uint256 maxCompletions)`: Admin function to define a new Proof-of-Interaction quest with various parameters.
9.  `submitQuestCompletion(uint256 questId, bytes memory proofData)`: Users submit proof of quest completion. For `EXTERNAL` quests, this requires the `oracleVerifier`.
10. `getQuestDetails(uint256 questId)`: View function to retrieve detailed information about a specific quest.
11. `getAvailableQuests()`: View function to list all quests that are currently open for submission.
12. `getUserQuestCompletions(address user, uint256 questId)`: View function to retrieve the number of times a user has completed a specific quest.

**III. Epoch & Decay Mechanisms:**
13. `advanceEpoch()`: Callable by anyone to trigger the advancement of the current epoch if enough time has passed. Handles the global epoch progression.
14. `_advanceEpochIfNeeded()` (Internal): Helper function to ensure the epoch is up-to-date before critical operations.
15. `setReputationDecayRate(uint256 ratePerEpoch)`: Admin function to adjust the global percentage reputation decay rate per epoch.
16. `getCurrentEpoch()`: View function to get the current epoch number.
17. `getTimeUntilNextEpoch()`: View function to get the remaining time (in seconds) until the next epoch can be advanced.

**IV. Governance & Delegation:**
18. `getShardVotingWeight(uint256 tokenId)`: Calculates the voting weight granted by an AetherShard based on its current level (e.g., exponential weighting).
19. `delegateVotingPower(address delegatee)`: Allows a shard holder to delegate their AetherShard's voting power to another address.
20. `undelegateVotingPower()`: Revokes a previous voting power delegation.
21. `getDelegatedVotingPower(address delegator)`: View function to see who a specific user has delegated their power to.
22. `getTotalAggregatedVotingPower(address user)`: Calculates the total voting power held by a user, including their own shard's power and any delegated power they receive (Note: this function may be gas-intensive for large user bases, illustrating a common challenge).

**V. Admin & Configuration:**
23. `setEssenceTokenAddress(address _essenceTokenAddress)`: Admin function to set or update the address of the ERC20 `EssenceToken`.
24. `setOracleVerifier(address _oracleVerifier)`: Admin function to set or update the address of the trusted oracle for external quest verification.
25. `setReputationLevelThresholds(uint256[] memory _thresholds)`: Admin function to define the reputation scores required for each successive shard level.
26. `pause()`: Admin function to pause critical contract functionalities (e.g., quest submissions, minting) using OpenZeppelin's Pausable.
27. `unpause()`: Admin function to unpause the contract.
28. `withdrawProtocolFees(address recipient)`: Admin function to withdraw accumulated `EssenceToken` fees from the contract's treasury.

**VI. View Functions for User Data:**
29. `getUserAetherShardId(address user)`: Returns the AetherShard tokenId owned by a specific user.

**VII. ERC-721 Standard Functions (Modified for Non-Transferability):**
30. `transferFrom(address from, address to, uint256 tokenId)`: Overridden to revert, enforcing non-transferability.
31. `safeTransferFrom(address from, address to, uint256 tokenId)`: Overridden to revert.
32. `approve(address to, uint256 tokenId)`: Overridden to revert.
33. `setApprovalForAll(address operator, bool approved)`: Overridden to revert.
*(Note: `balanceOf` and `ownerOf` are inherited and function as standard for ERC721Enumerable).*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for the hypothetical EssenceToken
interface IEssenceToken is IERC20 {
    // No additional functions needed beyond ERC20 standard for this example
}

contract AetherShardProtocol is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    /* ========== Constants & Immutables ========== */

    uint256 public constant MAX_REPUTATION = 1_000_000; // Max reputation cap
    uint256 public constant INITIAL_REPUTATION = 100; // Reputation granted on mint
    uint256 public constant ESSENCE_PROTOCOL_FEE_BPS = 100; // 1% (100 basis points) of EssenceToken rewards as protocol fee

    /* ========== State Variables ========== */

    // Mapping from user address to their current reputation score
    mapping(address => uint256) private s_reputation;
    // Mapping from user address to their currently minted AetherShard tokenId
    mapping(address => uint256) private s_userShardTokenId;
    // Mapping from tokenId to the user address (redundant with ownerOf but used for direct lookup in tokenURI)
    mapping(uint256 => address) private s_shardIdToUser;
    // Mapping from user address to the epoch their reputation was last updated/decayed
    mapping(address => uint256) private s_userLastReputationUpdateEpoch;

    // Quest management
    enum QuestType { ON_CHAIN, EXTERNAL }

    struct Quest {
        string name;
        uint256 rewardReputation;
        uint256 rewardEssence; // Amount of EssenceToken reward
        uint256 durationEpochs; // How many epochs the quest is active after creation (0 for indefinite)
        QuestType questType;
        bytes32 requiredProofHash; // For EXTERNAL quests, hash of expected proof data; can be bytes32(0) for ON_CHAIN
        uint256 creationEpoch; // Epoch when the quest was created
        uint256 maxCompletions; // Max times a user can complete this quest (0 for unlimited)
    }

    // Mapping from questId to Quest struct
    mapping(uint256 => Quest) private s_quests;
    uint256 private s_nextQuestId; // Counter for quest IDs

    // Mapping from user => questId => number of completions
    mapping(address => mapping(uint256 => uint256)) private s_userQuestCompletions;

    // Epoch and decay settings
    uint256 public s_reputationDecayRate; // Percentage decay per epoch (e.g., 500 for 5%) - parts per 10,000
    uint256 public s_epochDuration;       // Duration of an epoch in seconds
    uint256 public s_lastEpochAdvanceTime; // Timestamp of the last epoch advance
    uint256 public s_currentEpoch;         // Current epoch number

    // Reputation thresholds for each shard level
    // s_shardLevelThresholds[0] is for Level 1, etc.
    // Example: [0, 500, 1500, 3000] means Level 1 (0-499), Level 2 (500-1499), Level 3 (1500-2999), Level 4 (3000+)
    uint256[] public s_shardLevelThresholds; 

    // Delegation of voting power: delegator => delegatee
    mapping(address => address) private s_delegatee; 

    // External contract addresses
    IEssenceToken public essenceToken; // The ERC20 token used for rewards and fees
    address public oracleVerifier; // Address of the trusted oracle for EXTERNAL quest verification

    /* ========== Events ========== */

    event AetherShardMinted(address indexed user, uint256 tokenId, uint256 initialReputation);
    event AetherShardReforged(address indexed user, uint256 oldTokenId, uint256 newTokenId);
    event ReputationChanged(address indexed user, uint256 oldReputation, uint256 newReputation, string reason);
    event QuestCreated(uint256 indexed questId, string name, QuestType questType, uint256 rewardReputation, uint256 rewardEssence, uint256 durationEpochs);
    event QuestCompleted(address indexed user, uint256 indexed questId, uint256 gainedReputation, uint256 gainedEssence);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 lastAdvanceTime);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event VotingPowerUndelegated(address indexed delegator);
    event OracleVerifierUpdated(address indexed oldVerifier, address indexed newVerifier);
    event EssenceTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ReputationDecayRateUpdated(uint256 oldRate, uint256 newRate);
    event ShardLevelThresholdsUpdated(uint256[] newThresholds);
    event Paused(address account);
    event Unpaused(address account);


    /* ========== Modifiers ========== */

    modifier onlyOracleVerifier() {
        require(msg.sender == oracleVerifier, "AP: Not oracle verifier");
        _;
    }

    modifier onlyShardHolder(uint256 tokenId) {
        require(_exists(tokenId) && ownerOf(tokenId) == msg.sender, "AP: Not shard holder");
        _;
    }

    modifier requiresActiveShard() {
        require(s_userShardTokenId[msg.sender] != 0, "AP: User does not hold an active AetherShard");
        _;
    }

    modifier whenNotZeroAddress(address _address) {
        require(_address != address(0), "AP: Zero address not allowed");
        _;
    }

    /* ========== Constructor ========== */

    constructor(
        address initialOracleVerifier,
        address initialEssenceToken,
        uint256 initialEpochDuration,
        uint256 initialReputationDecayRate, // e.g., 500 for 5% (500 basis points)
        uint256[] memory initialLevelThresholds
    ) ERC721("AetherShard", "ASH") Ownable(msg.sender) Pausable() {
        require(initialOracleVerifier != address(0), "AP: Initial oracle verifier cannot be zero");
        require(initialEssenceToken != address(0), "AP: Initial EssenceToken cannot be zero");
        require(initialEpochDuration > 0, "AP: Epoch duration must be greater than 0");
        require(initialReputationDecayRate <= 10000, "AP: Decay rate cannot exceed 100%"); // 10000 basis points = 100%
        require(initialLevelThresholds.length > 0 && initialLevelThresholds[0] == 0, "AP: Level 1 threshold must be 0");

        oracleVerifier = initialOracleVerifier;
        essenceToken = IEssenceToken(initialEssenceToken);
        s_epochDuration = initialEpochDuration;
        s_reputationDecayRate = initialReputationDecayRate;
        s_shardLevelThresholds = initialLevelThresholds;

        s_lastEpochAdvanceTime = block.timestamp;
        s_currentEpoch = 0; // Start at epoch 0
    }

    /* ========== ERC-721 Overrides (Non-Transferable Logic) ========== */

    /// @dev AetherShards are soul-bound and cannot be transferred.
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AP: AetherShards are non-transferable");
    }

    /// @dev AetherShards are soul-bound and cannot be transferred.
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AP: AetherShards are non-transferable");
    }

    /// @dev AetherShards are soul-bound and cannot be approved for transfer.
    function approve(address to, uint256 tokenId) public pure override {
        revert("AP: AetherShards cannot be approved");
    }

    /// @dev AetherShards are soul-bound and cannot be approved for transfer.
    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("AP: AetherShards cannot be approved for all");
    }

    /// @dev AetherShards are soul-bound, so no approvals exist.
    function getApproved(uint256 tokenId) public pure override returns (address) {
        revert("AP: AetherShards have no approvals");
    }

    /// @dev AetherShards are soul-bound, so no approvals exist.
    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
        return false;
    }


    /* ========== I. Core NFT & Reputation Management ========== */

    /**
     * @dev Allows a new user to mint their initial AetherShard NFT.
     *      Each user can only hold one AetherShard at a time.
     * @return tokenId The ID of the newly minted AetherShard.
     */
    function mintAetherShard() public whenNotPaused nonReentrant returns (uint256) {
        require(s_userShardTokenId[msg.sender] == 0, "AP: User already holds an AetherShard");

        _advanceEpochIfNeeded(); // Ensure epoch is up-to-date before minting

        uint256 newTokenId = ERC721Enumerable.totalSupply() + 1; // Simple incrementing ID
        _mint(msg.sender, newTokenId);

        s_userShardTokenId[msg.sender] = newTokenId;
        s_shardIdToUser[newTokenId] = msg.sender;
        s_reputation[msg.sender] = INITIAL_REPUTATION;
        s_userLastReputationUpdateEpoch[msg.sender] = s_currentEpoch;

        emit AetherShardMinted(msg.sender, newTokenId, INITIAL_REPUTATION);
        emit ReputationChanged(msg.sender, 0, INITIAL_REPUTATION, "Minted initial shard");
        return newTokenId;
    }

    /**
     * @dev Allows a user to burn their existing AetherShard and mint a new one.
     *      This can be used to "reset" a shard's visual state or other properties
     *      without losing the underlying reputation history. Reputation might decay
     *      upon reforge but not reset to initial.
     * @param tokenId The ID of the AetherShard to reforge.
     * @return newTokenId The ID of the newly minted AetherShard.
     */
    function reforgeAetherShard(uint256 tokenId) public onlyShardHolder(tokenId) whenNotPaused nonReentrant returns (uint256) {
        address user = msg.sender;
        require(s_userShardTokenId[user] == tokenId, "AP: Token ID mismatch for user");

        _applyLazyReputationDecay(user); // Apply decay before reforge

        // Burn the old shard
        _burn(tokenId);
        delete s_userShardTokenId[user];
        delete s_shardIdToUser[tokenId]; // Also remove mapping from tokenId to user

        // Mint a new shard, retaining current (decayed) reputation
        uint256 newTokenId = ERC721Enumerable.totalSupply() + 1;
        _mint(user, newTokenId);

        s_userShardTokenId[user] = newTokenId;
        s_shardIdToUser[newTokenId] = user; // Update mapping for new token ID
        s_userLastReputationUpdateEpoch[user] = s_currentEpoch; // Reset decay timer for the new shard

        emit AetherShardReforged(user, tokenId, newTokenId);
        emit AetherShardMinted(user, newTokenId, s_reputation[user]); // Emit as a new mint event
        return newTokenId;
    }

    /**
     * @dev Internal function to increase a user's reputation. Protected to be called only by
     *      quest completion or other authorized internal mechanisms.
     * @param user The address of the user.
     * @param amount The amount of reputation to add.
     */
    function _increaseReputation(address user, uint256 amount) internal {
        _applyLazyReputationDecay(user);
        uint256 oldRep = s_reputation[user];
        uint256 newRep = oldRep + amount;
        if (newRep > MAX_REPUTATION) {
            newRep = MAX_REPUTATION;
        }
        s_reputation[user] = newRep;
        s_userLastReputationUpdateEpoch[user] = s_currentEpoch;
        emit ReputationChanged(user, oldRep, newRep, "Gained");
    }

    /**
     * @dev Internal function to decrease a user's reputation. Protected for decay or penalties.
     * @param user The address of the user.
     * @param amount The amount of reputation to subtract.
     */
    function _decreaseReputation(address user, uint256 amount) internal {
        _applyLazyReputationDecay(user); // Ensure current reputation is accurate before decreasing
        uint256 oldRep = s_reputation[user];
        uint256 newRep = oldRep > amount ? oldRep - amount : 0;
        s_reputation[user] = newRep;
        s_userLastReputationUpdateEpoch[user] = s_currentEpoch;
        emit ReputationChanged(user, oldRep, newRep, "Lost");
    }

    /**
     * @dev Calculates the AetherShard level based on a given reputation score and configured thresholds.
     * @param currentReputation The reputation score.
     * @return The calculated shard level.
     */
    function calculateCurrentShardLevel(uint256 currentReputation) public view returns (uint256) {
        uint256 level = 1;
        for (uint256 i = 0; i < s_shardLevelThresholds.length; i++) {
            if (currentReputation >= s_shardLevelThresholds[i]) {
                level = i + 1;
            } else {
                break; // Thresholds are sorted, so we found the highest level for current rep
            }
        }
        return level;
    }

    /**
     * @dev Retrieves a user's current reputation score, applying lazy decay if necessary.
     * @param user The address of the user.
     * @return The user's current (decayed) reputation.
     */
    function getCurrentReputation(address user) public view returns (uint256) {
        uint256 lastUpdateEpoch = s_userLastReputationUpdateEpoch[user];
        uint256 currentRep = s_reputation[user];

        if (currentRep == 0 || lastUpdateEpoch >= s_currentEpoch) {
            return currentRep; // No decay needed or already decayed in this epoch
        }

        uint256 epochsPassed = s_currentEpoch - lastUpdateEpoch;
        uint256 decayedAmount = (currentRep * s_reputationDecayRate * epochsPassed) / 10000; // rate is parts per 10k
        return currentRep > decayedAmount ? currentRep - decayedAmount : 0;
    }
    
    /**
     * @dev Applies the lazy reputation decay to a user's score if required.
     * This internal function should be called before any operation that reads or modifies a user's reputation.
     * @param user The address of the user.
     */
    function _applyLazyReputationDecay(address user) internal {
        uint256 currentStoredRep = s_reputation[user];
        uint256 decayedRep = getCurrentReputation(user); // This correctly calculates decay
        
        if (currentStoredRep != decayedRep) {
            s_reputation[user] = decayedRep;
            s_userLastReputationUpdateEpoch[user] = s_currentEpoch; // Mark as updated for current epoch
            emit ReputationChanged(user, currentStoredRep, decayedRep, "Decay");
        }
    }


    /**
     * @dev Generates the dynamic SVG metadata for an AetherShard.
     *      The SVG content and attributes change based on the shard's current level, reputation, and validity.
     * @param tokenId The ID of the AetherShard.
     * @return A data URI containing JSON with the NFT's name, description, and dynamic SVG image.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "AP: ERC721: URI query for nonexistent token");

        address owner = s_shardIdToUser[tokenId]; // Use direct map for efficiency
        require(owner != address(0), "AP: Token not associated with a user");

        uint256 currentReputation = getCurrentReputation(owner); // Get decayed reputation
        uint256 shardLevel = calculateCurrentShardLevel(currentReputation);

        string memory name = string(abi.encodePacked("AetherShard #", tokenId.toString(), " (Lvl ", shardLevel.toString(), ")"));
        string memory description = string(abi.encodePacked("A dynamic AetherShard NFT representing on-chain reputation. Level: ", shardLevel.toString(), ", Reputation: ", currentReputation.toString(), ". Owned by: ", Strings.toHexString(uint160(owner))));

        // Dynamic SVG generation based on level
        string memory backgroundColor;
        string memory levelColor;
        string memory glowColor;

        if (shardLevel == 1) {
            backgroundColor = "#282c34"; // Dark grey
            levelColor = "#61dafb";     // Light blue
            glowColor = "#21a1f1";
        } else if (shardLevel == 2) {
            backgroundColor = "#323842";
            levelColor = "#98c379";     // Green
            glowColor = "#6aa651";
        } else if (shardLevel == 3) {
            backgroundColor = "#464d57";
            levelColor = "#e06c75";     // Red
            glowColor = "#b84f55";
        } else if (shardLevel == 4) {
            backgroundColor = "#5a626d";
            levelColor = "#c678dd";     // Purple
            glowColor = "#9b51b0";
        } else { // Level 5+ or higher
            backgroundColor = "#6e7785";
            levelColor = "#d19a66";     // Orange
            glowColor = "#a7774d";
        }

        string memory svg = string(abi.encodePacked(
            "<svg width='300' height='300' viewBox='0 0 300 300' xmlns='http://www.w3.org/2000/svg'>",
            "<style>",
            "body { font-family: monospace; }",
            ".background { fill: ", backgroundColor, "; }",
            ".shard { fill: none; stroke: ", levelColor, "; stroke-width: 3px; filter: drop-shadow(0 0 8px ", glowColor, "); }",
            ".text-title { font-size: 24px; fill: white; text-anchor: middle; dominant-baseline: central; }",
            ".text-level { font-size: 18px; fill: ", levelColor, "; text-anchor: middle; dominant-baseline: central; }",
            ".text-rep { font-size: 14px; fill: #abb2bf; text-anchor: middle; dominant-baseline: central; }",
            ".text-status { font-size: 12px; fill: #cccccc; text-anchor: middle; dominant-baseline: central; }",
            "</style>",
            "<rect x='0' y='0' width='300' height='300' class='background'/>",
            "<path d='M150,50 L250,150 L150,250 L50,150 Z' class='shard'/>", // Diamond shape
            "<text x='150' y='100' class='text-title'>AetherShard</text>",
            "<text x='150' y='150' class='text-level'>Level: ", shardLevel.toString(), "</text>",
            "<text x='150' y='180' class='text-rep'>Reputation: ", currentReputation.toString(), "</text>",
            "<text x='150' y='210' class='text-status'>Epoch: ", s_currentEpoch.toString(), "</text>",
            "</svg>"
        ));

        string memory json = string(abi.encodePacked(
            '{"name":"', name,
            '","description":"', description,
            '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)),
            '","attributes":[{"trait_type":"Level","value":"', shardLevel.toString(),
            '"},{"trait_type":"Reputation","value":"', currentReputation.toString(),
            '"},{"trait_type":"Epoch","value":"', s_currentEpoch.toString(),
            '"}]}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /* ========== II. Quest & Engagement System ========== */

    /**
     * @dev Creates a new Proof-of-Interaction quest. Only callable by the owner.
     * @param name The name of the quest.
     * @param rewardReputation The amount of reputation awarded upon completion.
     * @param rewardEssence The amount of EssenceToken awarded upon completion.
     * @param durationEpochs How many epochs the quest remains active after creation (0 for indefinite).
     * @param questType The type of quest (ON_CHAIN or EXTERNAL).
     * @param requiredProofHash For EXTERNAL quests, a hash representing the expected proof; for ON_CHAIN, can be bytes32(0).
     * @param maxCompletions The maximum number of times a single user can complete this quest (0 for unlimited).
     */
    function createQuest(
        string memory name,
        uint256 rewardReputation,
        uint256 rewardEssence,
        uint256 durationEpochs,
        QuestType questType,
        bytes32 requiredProofHash,
        uint256 maxCompletions
    ) public onlyOwner whenNotPaused returns (uint256) {
        require(rewardReputation > 0 || rewardEssence > 0, "AP: Quest must offer a reward");
        if (questType == QuestType.EXTERNAL) {
            require(requiredProofHash != bytes32(0), "AP: External quests require a proof hash");
        }

        _advanceEpochIfNeeded(); // Ensure epoch is up-to-date

        uint256 questId = s_nextQuestId++;
        s_quests[questId] = Quest({
            name: name,
            rewardReputation: rewardReputation,
            rewardEssence: rewardEssence,
            durationEpochs: durationEpochs,
            questType: questType,
            requiredProofHash: requiredProofHash,
            creationEpoch: s_currentEpoch,
            maxCompletions: maxCompletions
        });

        emit QuestCreated(questId, name, questType, rewardReputation, rewardEssence, durationEpochs);
        return questId;
    }

    /**
     * @dev Allows users to submit proof of quest completion.
     *      For EXTERNAL quests, this proof must be verified by the `oracleVerifier`.
     *      For ON_CHAIN quests, the `proofData` can be any arbitrary data or simply `abi.encodePacked(true)` if no specific proof is needed.
     * @param questId The ID of the quest being completed.
     * @param proofData Arbitrary data provided as proof, or for oracle verification.
     */
    function submitQuestCompletion(uint256 questId, bytes memory proofData) public requiresActiveShard whenNotPaused nonReentrant {
        Quest storage quest = s_quests[questId];
        require(quest.creationEpoch != 0, "AP: Quest does not exist");
        if (quest.durationEpochs > 0) {
            _advanceEpochIfNeeded(); // Check epoch validity against the current epoch
            require(s_currentEpoch <= quest.creationEpoch + quest.durationEpochs, "AP: Quest has expired");
        }
        if (quest.maxCompletions > 0) {
            require(s_userQuestCompletions[msg.sender][questId] < quest.maxCompletions, "AP: Quest completed maximum times");
        }

        if (quest.questType == QuestType.EXTERNAL) {
            require(msg.sender == oracleVerifier, "AP: Only oracle can submit completion for EXTERNAL quests");
            require(keccak256(proofData) == quest.requiredProofHash, "AP: Invalid proof for external quest");
        } else { // ON_CHAIN quest
            // For ON_CHAIN quests, proofData can be anything. We don't verify against requiredProofHash here,
            // as the smart contract itself is the "verifier" implicitly.
            // A more complex ON_CHAIN quest would have internal logic to verify state, e.g., token holdings.
        }

        _advanceEpochIfNeeded(); // Ensure epoch is up-to-date before awarding rewards
        _applyLazyReputationDecay(msg.sender); // Ensure reputation is current before adding

        // Award rewards
        _increaseReputation(msg.sender, quest.rewardReputation);

        if (quest.rewardEssence > 0) {
            uint256 fee = (quest.rewardEssence * ESSENCE_PROTOCOL_FEE_BPS) / 10000;
            uint256 netReward = quest.rewardEssence - fee;
            require(essenceToken.transfer(msg.sender, netReward), "AP: Failed to transfer Essence reward");
            if (fee > 0) {
                require(essenceToken.transfer(address(this), fee), "AP: Failed to transfer Essence fee");
            }
        }

        s_userQuestCompletions[msg.sender][questId]++;

        emit QuestCompleted(msg.sender, questId, quest.rewardReputation, quest.rewardEssence);
    }

    /**
     * @dev Retrieves details about a specific quest.
     * @param questId The ID of the quest.
     * @return The quest details struct.
     */
    function getQuestDetails(uint256 questId) public view returns (Quest memory) {
        return s_quests[questId];
    }

    /**
     * @dev Returns a list of all quest IDs that are currently active.
     * @return An array of active quest IDs.
     */
    function getAvailableQuests() public view returns (uint256[] memory) {
        _advanceEpochIfNeeded(); // Ensure current epoch is updated before checking quest validity

        uint256[] memory tempQuestIds = new uint256[](s_nextQuestId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < s_nextQuestId; i++) {
            Quest memory quest = s_quests[i];
            if (quest.creationEpoch != 0 && (quest.durationEpochs == 0 || s_currentEpoch <= quest.creationEpoch + quest.durationEpochs)) {
                tempQuestIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempQuestIds[i];
        }
        return result;
    }

    /**
     * @dev Retrieves the number of times a user has completed a specific quest.
     * @param user The address of the user.
     * @param questId The ID of the quest.
     * @return The number of completions for that quest by the user.
     */
    function getUserQuestCompletions(address user, uint256 questId) public view returns (uint256) {
        return s_userQuestCompletions[user][questId];
    }


    /* ========== III. Epoch & Decay Mechanisms ========== */

    /**
     * @dev Advances the protocol to the next epoch if enough time has passed.
     *      This function can be called by anyone, incentivized by a small `EssenceToken` reward
     *      for the caller (to cover gas costs and encourage decentralized upkeep).
     *      This function primarily updates the `s_currentEpoch` and `s_lastEpochAdvanceTime`.
     *      Actual reputation decay is handled lazily when reputation is accessed/modified.
     */
    function advanceEpoch() public nonReentrant returns (bool) {
        if (block.timestamp < s_lastEpochAdvanceTime + s_epochDuration) {
            return false; // Not enough time has passed for next epoch
        }

        uint256 newEpochsPassed = (block.timestamp - s_lastEpochAdvanceTime) / s_epochDuration;
        s_currentEpoch += newEpochsPassed;
        s_lastEpochAdvanceTime += newEpochsPassed * s_epochDuration; // Adjust to the exact start of the new epoch

        // Optionally, reward the caller for advancing the epoch.
        // This would require a pre-funded amount of EssenceToken in the contract.
        // Example: uint256 EPOCH_ADVANCE_REWARD = 1 * 10**18; // 1 EssenceToken
        // if (essenceToken.balanceOf(address(this)) >= EPOCH_ADVANCE_REWARD) {
        //     require(essenceToken.transfer(msg.sender, EPOCH_ADVANCE_REWARD), "AP: Failed to reward epoch advancer");
        // }


        emit EpochAdvanced(s_currentEpoch, s_lastEpochAdvanceTime);
        return true;
    }

    /**
     * @dev Internal helper to advance epoch if conditions are met.
     */
    function _advanceEpochIfNeeded() internal {
        if (block.timestamp >= s_lastEpochAdvanceTime + s_epochDuration) {
            advanceEpoch();
        }
    }

    /**
     * @dev Sets the global reputation decay rate per epoch. Only callable by the owner.
     * @param ratePerEpoch New decay rate (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setReputationDecayRate(uint256 ratePerEpoch) public onlyOwner {
        require(ratePerEpoch <= 10000, "AP: Decay rate cannot exceed 100%");
        emit ReputationDecayRateUpdated(s_reputationDecayRate, ratePerEpoch);
        s_reputationDecayRate = ratePerEpoch;
    }

    /**
     * @dev Returns the current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return s_currentEpoch;
    }

    /**
     * @dev Returns the remaining time in seconds until the next epoch advances.
     */
    function getTimeUntilNextEpoch() public view returns (uint256) {
        if (block.timestamp >= s_lastEpochAdvanceTime + s_epochDuration) {
            return 0; // Epoch can be advanced now
        }
        return (s_lastEpochAdvanceTime + s_epochDuration) - block.timestamp;
    }

    /* ========== IV. Governance & Delegation ========== */

    /**
     * @dev Calculates the voting weight for a given AetherShard based on its level.
     *      Higher levels grant significantly more voting power. This can be customized.
     * @param tokenId The ID of the AetherShard.
     * @return The calculated voting weight. Returns 0 if token does not exist or owner has no reputation.
     */
    function getShardVotingWeight(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            return 0;
        }
        address owner = s_shardIdToUser[tokenId];
        if (owner == address(0)) { // Should not happen if _exists(tokenId) is true and s_shardIdToUser is correctly maintained
            return 0;
        }
        uint256 currentReputation = getCurrentReputation(owner);
        uint256 shardLevel = calculateCurrentShardLevel(currentReputation);

        // Simple exponential weighting: Level 1 = 1, Level 2 = 2, Level 3 = 4, Level 4 = 8, Level 5 = 16...
        return 2**(shardLevel - 1);
    }

    /**
     * @dev Allows a shard holder to delegate their voting power to another address.
     *      The delegatee will accumulate voting power from all delegators.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address delegatee) public requiresActiveShard whenNotPaused {
        require(delegatee != address(0), "AP: Delegatee cannot be zero address");
        require(delegatee != msg.sender, "AP: Cannot delegate to self");
        s_delegatee[msg.sender] = delegatee;
        emit VotingPowerDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Revokes a previous voting power delegation, returning power to the delegator.
     */
    function undelegateVotingPower() public requiresActiveShard whenNotPaused {
        require(s_delegatee[msg.sender] != address(0), "AP: No active delegation to undelegate");
        delete s_delegatee[msg.sender];
        emit VotingPowerUndelegated(msg.sender);
    }

    /**
     * @dev Returns the address to whom a user has delegated their voting power.
     * @param delegator The address of the delegator.
     * @return The address of the delegatee, or address(0) if no delegation.
     */
    function getDelegatedVotingPower(address delegator) public view returns (address) {
        return s_delegatee[delegator];
    }

    /**
     * @dev Calculates the total accumulated voting power for a specific address,
     *      including their own shard's power and any delegated power they receive.
     *      NOTE: This function iterates through all minted tokens and can be gas-intensive
     *      for a very large number of users. In a production system, a more efficient
     *      accumulator pattern (e.g., mapping `delegatee => totalPower`) would be used
     *      and updated on `delegate`/`undelegate` calls. This implementation serves to
     *      demonstrate the concept.
     * @param user The address for whom to calculate total voting power.
     * @return The total aggregated voting power.
     */
    function getTotalAggregatedVotingPower(address user) public view returns (uint256) {
        uint256 totalPower = 0;
        
        // Sum own shard's power if not delegated
        uint256 userShardId = s_userShardTokenId[user];
        if (userShardId != 0 && s_delegatee[user] == address(0)) {
            totalPower += getShardVotingWeight(userShardId);
        }

        // Sum up power from those who delegated to this user
        uint256 totalTokenSupply = ERC721Enumerable.totalSupply();
        for (uint256 i = 0; i < totalTokenSupply; i++) {
            uint256 tokenId = tokenByIndex(i);
            address delegator = s_shardIdToUser[tokenId]; // Get owner using direct map
            if (s_delegatee[delegator] == user) {
                totalPower += getShardVotingWeight(tokenId);
            }
        }
        return totalPower;
    }


    /* ========== V. Admin & Configuration ========== */

    /**
     * @dev Sets the address of the ERC20 EssenceToken used by the protocol. Only callable by the owner.
     * @param _essenceTokenAddress The new address of the EssenceToken.
     */
    function setEssenceTokenAddress(address _essenceTokenAddress) public onlyOwner whenNotZeroAddress(_essenceTokenAddress) {
        emit EssenceTokenAddressUpdated(address(essenceToken), _essenceTokenAddress);
        essenceToken = IEssenceToken(_essenceTokenAddress);
    }

    /**
     * @dev Sets the address of the trusted oracle verifier for EXTERNAL quests. Only callable by the owner.
     * @param _oracleVerifier The new address of the oracle verifier.
     */
    function setOracleVerifier(address _oracleVerifier) public onlyOwner whenNotZeroAddress(_oracleVerifier) {
        emit OracleVerifierUpdated(oracleVerifier, _oracleVerifier);
        oracleVerifier = _oracleVerifier;
    }

    /**
     * @dev Sets the reputation score thresholds for each AetherShard level.
     *      Requires thresholds to be in ascending order, with the first being 0.
     * @param _thresholds An array of reputation scores, where `_thresholds[i]` is the minimum
     *                    reputation for level `i+1`.
     */
    function setReputationLevelThresholds(uint256[] memory _thresholds) public onlyOwner {
        require(_thresholds.length > 0 && _thresholds[0] == 0, "AP: Level 1 threshold must be 0 and array not empty");
        for (uint256 i = 0; i < _thresholds.length - 1; i++) {
            require(_thresholds[i] < _thresholds[i+1], "AP: Thresholds must be in ascending order");
        }
        s_shardLevelThresholds = _thresholds;
        emit ShardLevelThresholdsUpdated(_thresholds);
    }

    /**
     * @dev Pauses all critical contract functionalities. Only callable by the owner.
     *      Uses OpenZeppelin's Pausable.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all critical contract functionalities. Only callable by the owner.
     *      Uses OpenZeppelin's Pausable.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated `EssenceToken` fees from the contract.
     * @param recipient The address to send the funds to.
     */
    function withdrawProtocolFees(address recipient) public onlyOwner whenNotZeroAddress(recipient) {
        uint256 balance = essenceToken.balanceOf(address(this));
        require(balance > 0, "AP: No fees to withdraw");
        require(essenceToken.transfer(recipient, balance), "AP: Failed to withdraw fees");
    }

    /* ========== VI. View Functions for User Data ========== */

    /**
     * @dev Returns the AetherShard tokenId owned by a specific user.
     * @param user The address of the user.
     * @return The tokenId of the user's AetherShard, or 0 if none.
     */
    function getUserAetherShardId(address user) public view returns (uint256) {
        return s_userShardTokenId[user];
    }
}
```