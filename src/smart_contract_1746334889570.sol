Okay, here is a smart contract concept for an "Evolving Digital Companions" protocol. It combines elements of NFTs (ERC721), fungible tokens (ERC20) for interaction, dynamic attributes influenced by actions and time (simulated), a staking mechanism, access control, and a simple simulated oracle interaction.

The concept aims to be creative by making NFTs that aren't static JPEGs, but rather digital entities whose characteristics change based on user interaction and protocol logic.

---

**Smart Contract: EvolvingDigitalCompanions**

**Outline:**

1.  **License & Pragmas:** SPDX License Identifier and Solidity version.
2.  **Imports:** ERC721, ERC20 interface, AccessControl, SafeERC20, Counters, SafeMath (or rely on 0.8+ checks).
3.  **Errors:** Custom error types for clarity.
4.  **Constants:** Role identifiers, time units, potentially evolution thresholds.
5.  **Enums & Structs:**
    *   `EvolutionStage`: Represents the current evolution stage of a companion.
    *   `CompanionAttributes`: Holds dynamic attributes like health, mood, level, last interaction time.
6.  **State Variables:**
    *   ERC721 State (inherited/internal): tokenCounter, mappings for ownership, approvals, etc.
    *   Protocol State:
        *   `companionAttributes`: Maps token ID to `CompanionAttributes`.
        *   `companionEvolutionStage`: Maps token ID to `EvolutionStage`.
        *   `stakedCompanions`: Maps owner address to staked token ID (simplified: 1 staked NFT per owner).
        *   `stakingStartTime`: Maps token ID to staking start timestamp.
        *   `accruedStakingRewards`: Maps token ID to unclaimable rewards.
        *   `nurtureToken`: Address of the ERC20 token used for interactions.
        *   `oracleContract`: Address of a simulated oracle contract (or just a state variable).
        *   `latestOracleValue`: Stores the value from the simulated oracle.
        *   `interactionFee`: Fee required for certain interactions (in NURTURE token).
        *   `totalProtocolFees`: Accumulated NURTURE tokens from fees.
        *   `evolutionThresholds`: Configurable thresholds for evolution (e.g., min level, min time).
        *   `baseTokenURI`: Base URI for NFT metadata.
        *   `evolutionStageURIParts`: Mapping from stage to URI segment.
7.  **Events:**
    *   `CompanionMinted`: When a new companion is created.
    *   `CompanionNurtured`: When a companion is nurtured.
    *   `CompanionTrained`: When a companion is trained.
    *   `CompanionEvolved`: When a companion evolves.
    *   `CompanionStaked`: When a companion is staked.
    *   `CompanionUnstaked`: When a companion is unstaked.
    *   `StakingRewardsClaimed`: When staking rewards are claimed.
    *   `FeeCollected`: When a fee is paid for an interaction.
    *   `FeesWithdrawn`: When protocol fees are withdrawn.
    *   `OracleDataUpdated`: When the simulated oracle value is updated.
    *   `ConfigUpdated`: Generic event for parameter changes.
    *   `AttributeDecayed`: When attributes decay is triggered.
8.  **Modifiers:**
    *   `whenNotStaked`: Requires a companion to not be currently staked.
    *   `whenStaked`: Requires a companion to be currently staked.
    *   `onlyCompanionOwnerOrApproved`: Allows interaction only by the owner or an approved address.
9.  **Constructor:** Initializes roles and potentially sets initial parameters.
10. **ERC721 Core Functions:** (Inherited, mostly standard overrides if needed)
11. **Role Management Functions:** (Inherited from AccessControl)
12. **Core Protocol Interaction Functions:**
    *   `mintCompanion`: Creates a new NFT.
    *   `nurture`: Pays fee, updates attributes, triggers decay calculation.
    *   `train`: Pays fee, updates attributes based on simulated outcome, triggers decay.
    *   `triggerAttributeDecay`: Public function to allow anyone to trigger attribute decay calculation for a specific companion.
    *   `evolve`: Checks conditions, updates evolution stage, potentially updates URI.
    *   `stakeCompanion`: Locks an NFT for staking.
    *   `unstakeCompanion`: Unlocks a staked NFT and pays rewards.
    *   `claimStakingRewards`: Claims pending rewards for a staked NFT.
13. **Configuration Functions:** (Restricted by roles)
    *   `setNurtureToken`
    *   `setOracleAddress`
    *   `updateOracleValue` (Simulated oracle)
    *   `setInteractionFee`
    *   `setEvolutionThresholds`
    *   `setBaseURI`
    *   `setEvolutionStageURIPart`
    *   `withdrawFees`
14. **View/Pure Functions:** (Read-only)
    *   `getCompanionAttributes`: Returns current attributes *including* decay calculation since last update.
    *   `getCompanionEvolutionStage`: Returns the current stage.
    *   `isCompanionStaked`: Checks if a companion is staked.
    *   `getStakingYieldRate`: Returns the base yield rate (e.g., per day) influenced by attributes.
    *   `getPendingStakingRewards`: Calculates rewards accrued since staking or last claim.
    *   `getTotalCompanions`: Returns the total number of NFTs minted.
    *   `getCompanionsByOwner`: Returns a list of token IDs owned by an address.
    *   `getLatestOracleValue`: Returns the current oracle value.
    *   `getInteractionFee`: Returns the current interaction fee.
    *   `canEvolve`: Checks if a companion meets evolution criteria.
    *   `predictEvolutionOutcome`: Simulates the *next* stage based on current state and thresholds.
    *   `getTokenBalanceForCompanion`: Alias for `getPendingStakingRewards`.
    *   `getCompanionLastInteractionTime`: Returns the timestamp of the last interaction.
    *   `getCompanionStakingStartTime`: Returns staking start time if staked.
15. **Internal Helper Functions:**
    *   `_processFee`: Handles fee payment and collection.
    *   `_calculateDecay`: Calculates the amount of decay based on time and attributes.
    *   `_applyDecay`: Applies calculated decay to attributes and updates `lastInteractionTime`.
    *   `_calculateStakingRewards`: Calculates rewards based on time and yield rate.
    *   `_getBaseStakingYieldRate`: Determines the base APR/rate for staking.
    *   `_updateCompanionAttributes`: Internal helper to update attributes and `lastInteractionTime`.
    *   `_generateInitialAttributes`: Helper for minting.

**Function Summary (List of > 20 functions):**

1.  `constructor()`: Initializes roles and settings.
2.  `mintCompanion(address to)`: Mints a new ERC721 companion token to an address. Requires MINTER_ROLE.
3.  `nurture(uint256 tokenId)`: Allows the owner (or approved) to nurture a companion by paying the interaction fee. Increases health and mood. Triggers attribute decay application first.
4.  `train(uint256 tokenId)`: Allows the owner (or approved) to train a companion by paying the interaction fee. Affects level and mood based on a simulated outcome (uses simplified pseudo-randomness). Triggers attribute decay application first.
5.  `triggerAttributeDecay(uint256 tokenId)`: Public function to apply attribute decay calculation based on time elapsed since the last interaction/decay trigger for a specific companion. Updates state.
6.  `evolve(uint256 tokenId)`: Allows the owner (or approved) to trigger evolution if the companion meets specific criteria (level, time, attributes). Changes `EvolutionStage`.
7.  `stakeCompanion(uint256 tokenId)`: Allows the owner to stake their companion NFT in the contract to earn rewards. Requires the companion is not already staked.
8.  `unstakeCompanion(uint256 tokenId)`: Allows the owner to unstake their companion NFT, transferring it back and paying out accrued staking rewards.
9.  `claimStakingRewards(uint256 tokenId)`: Allows the owner of a staked companion to claim accrued staking rewards without unstaking.
10. `setNurtureToken(address tokenAddress)`: Sets the address of the ERC20 token used for interactions and rewards. Requires CONFIG_ROLE.
11. `setOracleAddress(address oracleAddress)`: Sets the address of the simulated oracle contract. Requires CONFIG_ROLE.
12. `updateOracleValue(uint256 newValue)`: Updates the `latestOracleValue` state variable with data from the simulated oracle. Requires ORACLE_UPDATER_ROLE.
13. `setInteractionFee(uint256 feeAmount)`: Sets the amount of NURTURE token required for `nurture` and `train` functions. Requires CONFIG_ROLE.
14. `setEvolutionThresholds(...)`: Sets the thresholds required for companions to evolve (e.g., minimum level, time in stage). Requires CONFIG_ROLE.
15. `setBaseURI(string memory baseURI)`: Sets the base URI for the NFT metadata. Requires CONFIG_ROLE.
16. `setEvolutionStageURIPart(EvolutionStage stage, string memory uriPart)`: Sets the URI path segment specific to an evolution stage. Requires CONFIG_ROLE.
17. `withdrawFees(address recipient)`: Allows a privileged role (e.g., Admin) to withdraw accumulated protocol fees. Requires DEFAULT_ADMIN_ROLE or similar.
18. `getCompanionAttributes(uint256 tokenId)`: View function. Returns the current `CompanionAttributes` for a companion, including the real-time calculation of attribute decay based on the time elapsed since the last update. *Does not change state.*
19. `getCompanionEvolutionStage(uint256 tokenId)`: View function. Returns the current evolution stage.
20. `isCompanionStaked(uint256 tokenId)`: View function. Checks if a specific companion is currently staked.
21. `getPendingStakingRewards(uint256 tokenId)`: View function. Calculates the amount of NURTURE token rewards accrued for a staked companion since it was staked or rewards were last claimed.
22. `getTotalCompanions()`: View function. Returns the total number of companion NFTs minted.
23. `getCompanionsByOwner(address owner)`: View function. Returns an array of token IDs owned by a specific address.
24. `getLatestOracleValue()`: View function. Returns the most recently updated value from the simulated oracle.
25. `getInteractionFee()`: View function. Returns the current interaction fee amount.
26. `canEvolve(uint256 tokenId)`: View function. Checks if a companion currently meets the configured requirements to evolve, without triggering evolution.
27. `predictEvolutionOutcome(uint256 tokenId)`: View function. Simulates and returns the `EvolutionStage` the companion would reach if it were to evolve now, based on current state and thresholds.
28. `getCompanionLastInteractionTime(uint256 tokenId)`: View function. Returns the timestamp of the last time attributes were updated or decay was applied.
29. `getCompanionStakingStartTime(uint256 tokenId)`: View function. Returns the timestamp when a companion was staked (0 if not staked).
30. `tokenURI(uint256 tokenId)`: Overrides ERC721 `tokenURI`. Constructs the full metadata URI including the base URI and evolution stage specific part.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has checked arithmetic, SafeMath can be used for clarity in specific calculations if preferred. Let's stick to 0.8+ defaults for simplicity unless needed.
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example of an advanced util, maybe not strictly needed for THIS logic but good to show awareness. Let's omit for simplicity unless a feature requires it.
// Let's use a simple pseudo-randomness for training outcome for example purposes. Blockhash is NOT secure for high-value dApps.

// Custom Errors
error NotCompanionOwnerOrApproved();
error CompanionNotStaked();
error CompanionAlreadyStaked();
error InsufficientInteractionFee();
error EvolutionCriteriaNotMet();
error InvalidEvolutionStage();
error TokenDoesNotExist();
error CannotUnstakeWhileStaked();

// --- Smart Contract: EvolvingDigitalCompanions ---

// Outline:
// 1. License & Pragmas
// 2. Imports (ERC721, AccessControl, IERC20, SafeERC20, Counters, Strings)
// 3. Errors (Custom errors)
// 4. Constants (Roles)
// 5. Enums & Structs (EvolutionStage, CompanionAttributes)
// 6. State Variables (ERC721 state, Protocol state including attributes, staking, tokens, fees, oracle, config)
// 7. Events (Minting, Interactions, Evolution, Staking, Fees, Oracle, Config)
// 8. Modifiers (whenNotStaked, whenStaked, onlyCompanionOwnerOrApproved - combined or separate checks)
// 9. Constructor
// 10. ERC721 Core Functions (Override tokenURI)
// 11. Role Management Functions (Inherited)
// 12. Core Protocol Interaction Functions (mint, nurture, train, decay, evolve, stake, unstake, claim rewards)
// 13. Configuration Functions (setters for tokens, fees, oracle, evolution, URI, fee withdrawal)
// 14. View/Pure Functions (Getters for attributes, stage, staking status, rewards, counts, fees, oracle, evolution checks)
// 15. Internal Helper Functions (process fee, calculate/apply decay, calculate rewards, get yield rate, generate initial attributes, update attributes helper)

// Function Summary (> 20 Functions):
// 1. constructor()
// 2. mintCompanion(address to)
// 3. nurture(uint256 tokenId)
// 4. train(uint256 tokenId)
// 5. triggerAttributeDecay(uint256 tokenId)
// 6. evolve(uint256 tokenId)
// 7. stakeCompanion(uint256 tokenId)
// 8. unstakeCompanion(uint256 tokenId)
// 9. claimStakingRewards(uint256 tokenId)
// 10. setNurtureToken(address tokenAddress)
// 11. setOracleAddress(address oracleAddress)
// 12. updateOracleValue(uint256 newValue) (Simulated Oracle)
// 13. setInteractionFee(uint256 feeAmount)
// 14. setEvolutionThresholds(...)
// 15. setBaseURI(string memory baseURI)
// 16. setEvolutionStageURIPart(EvolutionStage stage, string memory uriPart)
// 17. withdrawFees(address recipient)
// 18. getCompanionAttributes(uint256 tokenId) (Calculates decay)
// 19. getCompanionEvolutionStage(uint256 tokenId)
// 20. isCompanionStaked(uint256 tokenId)
// 21. getPendingStakingRewards(uint256 tokenId)
// 22. getTotalCompanions()
// 23. getCompanionsByOwner(address owner)
// 24. getLatestOracleValue()
// 25. getInteractionFee()
// 26. canEvolve(uint256 tokenId)
// 27. predictEvolutionOutcome(uint256 tokenId)
// 28. getCompanionLastInteractionTime(uint256 tokenId)
// 29. getCompanionStakingStartTime(uint256 tokenId)
// 30. tokenURI(uint256 tokenId) (Override)
// + Inherited AccessControl functions (grantRole, revokeRole, hasRole, etc. - not counted in the 20 but part of the contract)

contract EvolvingDigitalCompanions is ERC721, AccessControl {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Constants ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");

    // Time units in seconds (for clarity)
    uint256 public constant SECONDS_PER_DAY = 1 days;
    uint256 public constant SECONDS_PER_HOUR = 1 hours;

    // --- Enums & Structs ---
    enum EvolutionStage {
        STAGE_BABY,
        STAGE_JUVENILE,
        STAGE_ADULT,
        STAGE_ANCIENT,
        STAGE_LEGENDARY // Example stages
    }

    struct CompanionAttributes {
        uint256 health; // 0-100
        uint256 mood;   // 0-100
        uint256 level;  // Starts at 1
        uint256 lastInteractionTime; // Timestamp of last nurture/train/decay trigger
        // Add more attributes like 'strength', 'intelligence', 'agility' etc. if desired
    }

    struct EvolutionThresholds {
        uint256 minLevel;
        uint256 minTimeInStage; // In seconds
        uint256 minHealth;      // As a percentage (0-100)
        uint256 minMood;        // As a percentage (0-100)
        uint256 oracleInfluenceThreshold; // Value from oracle needed to help evolution
    }

    // --- State Variables ---
    Counters.Counter private _tokenCounter;

    mapping(uint256 => CompanionAttributes) private _companionAttributes;
    mapping(uint256 => EvolutionStage) private _companionEvolutionStage;
    mapping(address => uint256) private _stakedCompanion; // Simplified: 1 staked NFT per address
    mapping(uint256 => uint256) private _stakingStartTime; // Mapping tokenId => timestamp
    mapping(uint256 => uint256) private _accruedStakingRewards; // Mapping tokenId => accrued tokens (in NURTURE token units)

    IERC20 public nurtureToken;
    address public oracleContract; // Placeholder for a real oracle contract address
    uint256 public latestOracleValue; // Value fetched from the simulated oracle

    uint256 public interactionFee; // Fee for nurture/train, in NURTURE tokens
    uint256 public totalProtocolFees; // Accumulated fees

    mapping(EvolutionStage => EvolutionThresholds) public evolutionThresholds;
    mapping(EvolutionStage => string) private _evolutionStageURIParts;

    string private _baseTokenURI;

    // --- Events ---
    event CompanionMinted(address indexed owner, uint256 indexed tokenId, EvolutionStage initialStage);
    event CompanionNurtured(uint256 indexed tokenId, uint256 newHealth, uint256 newMood, uint256 feePaid);
    event CompanionTrained(uint256 indexed tokenId, bool success, uint256 newLevel, uint256 newMood, uint256 feePaid);
    event AttributeDecayed(uint256 indexed tokenId, uint256 decayedHealth, uint256 decayedMood, uint256 newHealth, uint256 newMood);
    event CompanionEvolved(uint256 indexed tokenId, EvolutionStage fromStage, EvolutionStage toStage);
    event CompanionStaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event CompanionUnstaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp, uint256 rewardsClaimed);
    event StakingRewardsClaimed(uint256 indexed tokenId, uint256 rewardsClaimed);
    event FeeCollected(uint256 feeAmount, uint256 totalFees);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event OracleDataUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event ConfigUpdated(string paramName, uint256 indexed newValue); // Generic config update event
    event ConfigAddressUpdated(string paramName, address indexed newAddress);
    event EvolutionThresholdsUpdated(EvolutionStage stage, EvolutionThresholds thresholds);

    // --- Modifiers ---
    modifier whenNotStaked(uint256 tokenId) {
        if (_stakedCompanion[ownerOf(tokenId)] == tokenId) revert CompanionAlreadyStaked();
        _;
    }

    modifier whenStaked(uint256 tokenId) {
        if (_stakedCompanion[ownerOf(tokenId)] != tokenId) revert CompanionNotStaked();
        _;
    }

    modifier onlyCompanionOwnerOrApproved(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotCompanionOwnerOrApproved();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address admin,
        address minter,
        address configSetter,
        address oracleUpdater
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(CONFIG_ROLE, configSetter);
        _grantRole(ORACLE_UPDATER_ROLE, oracleUpdater);

        // Set some initial default evolution thresholds (can be updated later)
        evolutionThresholds[EvolutionStage.STAGE_BABY] = EvolutionThresholds({
            minLevel: 5,
            minTimeInStage: 3 * SECONDS_PER_DAY,
            minHealth: 70,
            minMood: 60,
            oracleInfluenceThreshold: 50 // Example value
        });
         evolutionThresholds[EvolutionStage.STAGE_JUVENILE] = EvolutionThresholds({
            minLevel: 10,
            minTimeInStage: 7 * SECONDS_PER_DAY,
            minHealth: 60,
            minMood: 50,
            oracleInfluenceThreshold: 60
        });
        evolutionThresholds[EvolutionStage.STAGE_ADULT] = EvolutionThresholds({
            minLevel: 20,
            minTimeInStage: 30 * SECONDS_PER_DAY,
            minHealth: 50,
            minMood: 40,
            oracleInfluenceThreshold: 70
        });
        // Add thresholds for STAGE_ANCIENT, STAGE_LEGENDARY...
    }

    // --- Core Protocol Interaction Functions ---

    /**
     * @notice Mints a new companion NFT and assigns initial attributes.
     * @param to The address to mint the companion to.
     */
    function mintCompanion(address to) public onlyRole(MINTER_ROLE) {
        _tokenCounter.increment();
        uint256 newItemId = _tokenCounter.current();
        _safeMint(to, newItemId);

        _companionAttributes[newItemId] = _generateInitialAttributes();
        _companionEvolutionStage[newItemId] = EvolutionStage.STAGE_BABY;

        emit CompanionMinted(to, newItemId, EvolutionStage.STAGE_BABY);
    }

    /**
     * @notice Allows the owner or approved user to nurture a companion. Requires interaction fee.
     * @param tokenId The ID of the companion to nurture.
     */
    function nurture(uint256 tokenId) public onlyCompanionOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        _requireTokenExists(tokenId);
        _processFee();

        // Apply decay before nurturing
        _applyDecay(tokenId);

        CompanionAttributes storage attrs = _companionAttributes[tokenId];
        // Nurturing increases Health and Mood (up to 100)
        attrs.health = (attrs.health + 15 > 100) ? 100 : attrs.health + 15; // Example increase
        attrs.mood = (attrs.mood + 10 > 100) ? 100 : attrs.mood + 10;     // Example increase

        _updateCompanionAttributes(tokenId, attrs); // Updates lastInteractionTime

        emit CompanionNurtured(tokenId, attrs.health, attrs.mood, interactionFee);
    }

     /**
     * @notice Allows the owner or approved user to train a companion. Requires interaction fee.
     * @param tokenId The ID of the companion to train.
     */
    function train(uint256 tokenId) public onlyCompanionOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        _requireTokenExists(tokenId);
         _processFee();

        // Apply decay before training
        _applyDecay(tokenId);

        CompanionAttributes storage attrs = _companionAttributes[tokenId];

        // Simulate a training outcome using block hash and timestamp (NOT SECURE)
        // For production, use Chainlink VRF or a similar secure randomness solution.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId)));
        bool success = randomness % 100 < (attrs.mood + attrs.health) / 2; // Higher mood/health increases success chance

        if (success) {
            attrs.level++;
            attrs.mood = (attrs.mood + 5 > 100) ? 100 : attrs.mood + 5; // Small mood boost on success
        } else {
            attrs.mood = (attrs.mood > 10) ? attrs.mood - 10 : 0; // Mood hit on failure
        }

        _updateCompanionAttributes(tokenId, attrs); // Updates lastInteractionTime

        emit CompanionTrained(tokenId, success, attrs.level, attrs.mood, interactionFee);
    }

    /**
     * @notice Allows anyone to trigger the calculation and application of attribute decay
     * for a specific companion based on elapsed time.
     * @param tokenId The ID of the companion.
     */
    function triggerAttributeDecay(uint256 tokenId) public {
        _requireTokenExists(tokenId);
        // This function does not require ownership or approval to allow anyone to
        // 'ping' the contract to update a companion's state based on time.
        // This could be incentivized externally or called by a bot.

        _applyDecay(tokenId); // Decay is applied based on time since last update within this function.

        // Event is emitted within _applyDecay
    }


    /**
     * @notice Attempts to evolve a companion to the next stage. Checks evolution criteria.
     * @param tokenId The ID of the companion to evolve.
     */
    function evolve(uint256 tokenId) public onlyCompanionOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        _requireTokenExists(tokenId);
         // No fee for evolution itself, represents a milestone

        EvolutionStage currentStage = _companionEvolutionStage[tokenId];
        if (currentStage == EvolutionStage.STAGE_LEGENDARY) {
             revert InvalidEvolutionStage(); // Already at max stage
        }

        // Apply decay before checking evolution criteria
        _applyDecay(tokenId);

        if (!canEvolve(tokenId)) {
            revert EvolutionCriteriaNotMet();
        }

        EvolutionStage nextStage = EvolutionStage(uint8(currentStage) + 1);
        _companionEvolutionStage[tokenId] = nextStage;

        // Reset some attributes upon evolution? E.g., reset level but keep some progression?
        // For simplicity, let's just advance the stage and perhaps give a small attribute boost.
         CompanionAttributes storage attrs = _companionAttributes[tokenId];
         attrs.health = (attrs.health + 20 > 100) ? 100 : attrs.health + 20; // Boost health
         attrs.mood = (attrs.mood + 15 > 100) ? 100 : attrs.mood + 15;     // Boost mood
         attrs.lastInteractionTime = block.timestamp; // Reset timer for next stage

        emit CompanionEvolved(tokenId, currentStage, nextStage);
    }


    /**
     * @notice Allows the owner to stake a companion NFT to earn tokens.
     * @param tokenId The ID of the companion to stake.
     */
    function stakeCompanion(uint256 tokenId) public {
        _requireTokenExists(tokenId);
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotCompanionOwnerOrApproved(); // Must be owner to stake

        if (_stakedCompanion[owner] != 0) revert CompanionAlreadyStaked(); // Only one staked companion per address in this simplified version

        // Transfer NFT to contract
        safeTransferFrom(owner, address(this), tokenId);

        _stakedCompanion[owner] = tokenId;
        _stakingStartTime[tokenId] = block.timestamp;
        // Accrued rewards start calculating from now. Any prior accrued rewards are reset here.
        // A more complex version might pay out pending rewards on stake, but that adds complexity.
        // For simplicity, let's say staking clears pending pre-stake rewards.

        emit CompanionStaked(owner, tokenId, block.timestamp);
    }

    /**
     * @notice Allows the owner to unstake a companion NFT and claim pending rewards.
     * @param tokenId The ID of the companion to unstake.
     */
    function unstakeCompanion(uint256 tokenId) public whenStaked(tokenId) {
         _requireTokenExists(tokenId);
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotCompanionOwnerOrApproved();

        uint256 rewardsToClaim = _calculateStakingRewards(tokenId);

        // Transfer NFT back to owner
        safeTransferFrom(address(this), owner, tokenId);

        // Pay out rewards
        if (rewardsToClaim > 0) {
            nurtureToken.safeTransfer(owner, rewardsToClaim);
            emit StakingRewardsClaimed(tokenId, rewardsToClaim);
        }

        // Clear staking state
        delete _stakedCompanion[owner];
        delete _stakingStartTime[tokenId];
        delete _accruedStakingRewards[tokenId]; // Reset accrued rewards after payout

        emit CompanionUnstaked(owner, tokenId, block.timestamp, rewardsToClaim);
    }

    /**
     * @notice Allows the owner of a staked companion to claim pending rewards without unstaking.
     * @param tokenId The ID of the companion to claim rewards for.
     */
    function claimStakingRewards(uint256 tokenId) public whenStaked(tokenId) {
         _requireTokenExists(tokenId);
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotCompanionOwnerOrApproved();

        uint256 rewardsToClaim = _calculateStakingRewards(tokenId);

        if (rewardsToClaim > 0) {
            nurtureToken.safeTransfer(owner, rewardsToClaim);

            // Update staking start time to now, effectively resetting the claim period
            _stakingStartTime[tokenId] = block.timestamp;
            // Accrued rewards are paid out, so the mapping value is effectively reset for the next period.

            emit StakingRewardsClaimed(tokenId, rewardsToClaim);
        }
        // If rewardsToClaim is 0, no event is emitted and state doesn't change.
    }

    // --- Configuration Functions ---

    /**
     * @notice Sets the address of the ERC20 token used for interactions and staking rewards.
     * @param tokenAddress The address of the NURTURE token contract.
     */
    function setNurtureToken(address tokenAddress) public onlyRole(CONFIG_ROLE) {
        require(tokenAddress != address(0), "Invalid address");
        nurtureToken = IERC20(tokenAddress);
        emit ConfigAddressUpdated("nurtureToken", tokenAddress);
    }

    /**
     * @notice Sets the address of the simulated oracle contract.
     * @param oracleAddress The address of the oracle contract.
     */
    function setOracleAddress(address oracleAddress) public onlyRole(CONFIG_ROLE) {
        require(oracleAddress != address(0), "Invalid address");
        oracleContract = oracleAddress;
        emit ConfigAddressUpdated("oracleContract", oracleAddress);
    }

    /**
     * @notice Updates the internal state variable with a new value from the simulated oracle.
     * In a real contract, this would likely pull data from the oracle contract address.
     * @param newValue The new oracle value.
     */
    function updateOracleValue(uint256 newValue) public onlyRole(ORACLE_UPDATER_ROLE) {
        uint256 oldValue = latestOracleValue;
        latestOracleValue = newValue;
        emit OracleDataUpdated(newValue, oldValue);
    }

    /**
     * @notice Sets the fee amount required for interactions (nurture, train).
     * @param feeAmount The amount of NURTURE token required.
     */
    function setInteractionFee(uint256 feeAmount) public onlyRole(CONFIG_ROLE) {
        interactionFee = feeAmount;
        emit ConfigUpdated("interactionFee", feeAmount);
    }

    /**
     * @notice Sets the evolution thresholds for a specific stage.
     * @param stage The evolution stage to configure.
     * @param thresholds The new thresholds for this stage.
     */
    function setEvolutionThresholds(EvolutionStage stage, EvolutionThresholds memory thresholds) public onlyRole(CONFIG_ROLE) {
         // Basic validation (e.g., levels should increase or stay same across stages, time > 0)
         if (stage > EvolutionStage.STAGE_BABY) {
             EvolutionThresholds memory prevThresholds = evolutionThresholds[EvolutionStage(uint8(stage) - 1)];
             require(thresholds.minLevel >= prevThresholds.minLevel, "Min level must increase or stay same");
             // Add more validation as needed
         }
        evolutionThresholds[stage] = thresholds;
        emit EvolutionThresholdsUpdated(stage, thresholds);
    }

    /**
     * @notice Sets the base URI for NFT metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) public onlyRole(CONFIG_ROLE) {
        _baseTokenURI = baseURI;
        emit ConfigUpdated("baseTokenURI", 0); // Use 0 as placeholder for string value
    }

     /**
     * @notice Sets the URI path segment specific to an evolution stage.
     * @param stage The evolution stage.
     * @param uriPart The URI path segment (e.g., "baby/", "adult/").
     */
    function setEvolutionStageURIPart(EvolutionStage stage, string memory uriPart) public onlyRole(CONFIG_ROLE) {
        _evolutionStageURIParts[stage] = uriPart;
        // No specific event for this part, covered by ConfigUpdated or could add a dedicated one.
    }


    /**
     * @notice Allows a privileged role to withdraw accumulated protocol fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = totalProtocolFees;
        require(amount > 0, "No fees to withdraw");
        totalProtocolFees = 0;
        nurtureToken.safeTransfer(recipient, amount);
        emit FeesWithdrawn(recipient, amount);
    }

    // --- View/Pure Functions ---

    /**
     * @notice Gets the current attributes of a companion, including decay calculation.
     * Does NOT modify state.
     * @param tokenId The ID of the companion.
     * @return CompanionAttributes struct with potentially decayed values.
     */
    function getCompanionAttributes(uint256 tokenId) public view returns (CompanionAttributes memory) {
        _requireTokenExists(tokenId); // Added check for view functions too for safety
        CompanionAttributes memory attrs = _companionAttributes[tokenId];
        uint256 timeElapsed = block.timestamp - attrs.lastInteractionTime;

        // Calculate decay without modifying the stored attributes
        uint256 healthDecay = _calculateDecay(attrs.health, timeElapsed, SECONDS_PER_DAY, 10); // Example: Lose up to 10 health per day
        uint256 moodDecay = _calculateDecay(attrs.mood, timeElapsed, SECONDS_PER_DAY, 15);   // Example: Lose up to 15 mood per day

        attrs.health = (attrs.health > healthDecay) ? attrs.health - healthDecay : 0;
        attrs.mood = (attrs.mood > moodDecay) ? attrs.mood - moodDecay : 0;

        return attrs;
    }

    /**
     * @notice Gets the current evolution stage of a companion.
     * @param tokenId The ID of the companion.
     * @return The EvolutionStage enum value.
     */
    function getCompanionEvolutionStage(uint256 tokenId) public view returns (EvolutionStage) {
        _requireTokenExists(tokenId);
        return _companionEvolutionStage[tokenId];
    }

     /**
     * @notice Checks if a companion is currently staked.
     * @param tokenId The ID of the companion.
     * @return True if staked, false otherwise.
     */
    function isCompanionStaked(uint256 tokenId) public view returns (bool) {
         _requireTokenExists(tokenId);
        // Simplified: check if the owner's stakedCompanion slot points to this tokenId
        address owner = ownerOf(tokenId);
        return _stakedCompanion[owner] == tokenId && _stakingStartTime[tokenId] > 0;
    }


    /**
     * @notice Calculates the pending staking rewards for a staked companion.
     * @param tokenId The ID of the staked companion.
     * @return The amount of pending NURTURE tokens.
     */
    function getPendingStakingRewards(uint256 tokenId) public view returns (uint256) {
        _requireTokenExists(tokenId);
        if (!isCompanionStaked(tokenId)) {
            return 0;
        }
        return _calculateStakingRewards(tokenId);
    }

    /**
     * @notice Gets the total number of companion NFTs minted.
     * @return The total supply of NFTs.
     */
    function getTotalCompanions() public view returns (uint256) {
        return _tokenCounter.current();
    }

    /**
     * @notice Gets a list of token IDs owned by a specific address.
     * Note: This is inefficient for owners with many NFTs.
     * @param owner The address to query.
     * @return An array of token IDs.
     */
    function getCompanionsByOwner(address owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenCount = _tokenCounter.current(); // Iterate up to total minted

        uint256 index = 0;
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (ownerOf(i) == owner) {
                tokenIds[index] = i;
                index++;
                if (index == balance) break; // Stop if we found all tokens for this owner
            }
        }
        return tokenIds;
    }

    /**
     * @notice Gets the latest value stored from the simulated oracle.
     * @return The oracle value.
     */
    function getLatestOracleValue() public view returns (uint256) {
        return latestOracleValue;
    }

     /**
     * @notice Gets the current fee amount for interactions.
     * @return The interaction fee in NURTURE tokens.
     */
    function getInteractionFee() public view returns (uint256) {
        return interactionFee;
    }

    /**
     * @notice Checks if a companion meets the criteria to evolve to the next stage.
     * @param tokenId The ID of the companion.
     * @return True if evolution is possible, false otherwise.
     */
    function canEvolve(uint256 tokenId) public view returns (bool) {
        _requireTokenExists(tokenId);
        CompanionAttributes memory attrs = getCompanionAttributes(tokenId); // Use the view function to get decayed attrs
        EvolutionStage currentStage = _companionEvolutionStage[tokenId];

        if (currentStage == EvolutionStage.STAGE_LEGENDARY) {
            return false; // Already at max stage
        }

        EvolutionStage nextStage = EvolutionStage(uint8(currentStage) + 1);
        EvolutionThresholds memory thresholds = evolutionThresholds[currentStage]; // Thresholds *from* the current stage determine evolution *to* the next

        bool meetsLevel = attrs.level >= thresholds.minLevel;
        bool meetsTime = (block.timestamp - attrs.lastInteractionTime) >= thresholds.minTimeInStage;
        bool meetsHealth = attrs.health >= thresholds.minHealth;
        bool meetsMood = attrs.mood >= thresholds.minMood;
        // Example: Oracle influence helps *reduce* the required level/time or acts as an additional gate
        bool meetsOracle = latestOracleValue >= thresholds.oracleInfluenceThreshold; // Simple check

        // All criteria must be met for evolution
        return meetsLevel && meetsTime && meetsHealth && meetsMood && meetsOracle;
    }

    /**
     * @notice Predicts the outcome of the next evolution based on current state and thresholds.
     * Note: This just indicates the *potential* next stage, actual evolution still requires meeting criteria.
     * @param tokenId The ID of the companion.
     * @return The potential next EvolutionStage.
     */
    function predictEvolutionOutcome(uint256 tokenId) public view returns (EvolutionStage) {
        _requireTokenExists(tokenId);
        EvolutionStage currentStage = _companionEvolutionStage[tokenId];
        if (currentStage == EvolutionStage.STAGE_LEGENDARY) {
            return EvolutionStage.STAGE_LEGENDARY; // Cannot evolve further
        }
        // This is a simplified prediction. A real complex one might use attribute scaling.
        // Here, we just check if it *can* evolve based on the next stage thresholds.
        if (canEvolve(tokenId)) {
             return EvolutionStage(uint8(currentStage) + 1);
        } else {
            return currentStage; // Stays at current stage if not meeting criteria
        }
    }

     /**
     * @notice Gets the timestamp of the last interaction/decay trigger for a companion.
     * @param tokenId The ID of the companion.
     * @return Timestamp.
     */
    function getCompanionLastInteractionTime(uint256 tokenId) public view returns (uint256) {
         _requireTokenExists(tokenId);
        return _companionAttributes[tokenId].lastInteractionTime;
    }

     /**
     * @notice Gets the staking start timestamp for a companion.
     * @param tokenId The ID of the companion.
     * @return Timestamp (0 if not staked).
     */
     function getCompanionStakingStartTime(uint256 tokenId) public view returns (uint256) {
         _requireTokenExists(tokenId);
         return _stakingStartTime[tokenId];
     }


    // --- ERC721 Overrides ---

    /**
     * @notice Returns the full metadata URI for a companion, combining base and stage-specific parts.
     * @param tokenId The ID of the companion.
     * @return The full metadata URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireTokenExists(tokenId);
        EvolutionStage stage = _companionEvolutionStage[tokenId];
        string memory stagePart = _evolutionStageURIParts[stage];

        // Concatenate base URI, stage part, and token ID. Assumes baseURI ends with '/', and stagePart ends with '/'.
        return string(abi.encodePacked(_baseTokenURI, stagePart, tokenId.toString(), ".json")); // Example format
    }


    // --- Internal Helper Functions ---

    /**
     * @notice Helper to check if a token ID exists.
     */
    function _requireTokenExists(uint256 tokenId) internal view {
        // ERC721's _exists check is internal. We can call ownerOf which reverts for non-existent tokens,
        // or implement a custom check if we track minted IDs differently.
        // Using ownerOf implicitly checks existence.
        address owner = ownerOf(tokenId); // This will revert if tokenId doesn't exist
        // If it reaches here, the token exists.
        if (owner == address(0)) revert TokenDoesNotExist(); // Should not happen if using ownerOf correctly, but belt-and-suspenders.
    }

    /**
     * @notice Handles the fee payment for interactions.
     */
    function _processFee() internal {
        if (interactionFee > 0) {
            // User must approve the contract to spend nurtureToken beforehand
            // This uses SafeERC20's safeTransferFrom which checks success
            nurtureToken.safeTransferFrom(msg.sender, address(this), interactionFee);
            totalProtocolFees += interactionFee;
            emit FeeCollected(interactionFee, totalProtocolFees);
        }
    }

    /**
     * @notice Calculates the amount of decay for an attribute based on time elapsed.
     * @param currentValue The current attribute value.
     * @param timeElapsed The time elapsed since last update (in seconds).
     * @param decayPeriod The time period over which a certain decay amount applies (in seconds).
     * @param decayAmountPerPeriod The maximum decay amount per decayPeriod.
     * @return The calculated decay amount.
     */
    function _calculateDecay(uint256 currentValue, uint256 timeElapsed, uint256 decayPeriod, uint256 decayAmountPerPeriod) internal pure returns (uint256) {
        if (timeElapsed == 0 || decayPeriod == 0 || decayAmountPerPeriod == 0) {
            return 0;
        }
        uint256 periods = timeElapsed / decayPeriod;
        uint256 totalDecay = periods * decayAmountPerPeriod;
        return (currentValue > totalDecay) ? totalDecay : currentValue; // Decay cannot make attribute negative
    }

     /**
     * @notice Applies the calculated decay to a companion's attributes and updates the last interaction time.
     * Modifies state.
     * @param tokenId The ID of the companion.
     */
    function _applyDecay(uint256 tokenId) internal {
        CompanionAttributes storage attrs = _companionAttributes[tokenId];
        uint256 timeElapsed = block.timestamp - attrs.lastInteractionTime;

        uint256 healthDecay = _calculateDecay(attrs.health, timeElapsed, SECONDS_PER_DAY, 10); // Example: Lose up to 10 health per day
        uint256 moodDecay = _calculateDecay(attrs.mood, timeElapsed, SECONDS_PER_DAY, 15);   // Example: Lose up to 15 mood per day

        if (healthDecay > 0 || moodDecay > 0) {
             uint256 oldHealth = attrs.health;
             uint256 oldMood = attrs.mood;
             attrs.health = (attrs.health > healthDecay) ? attrs.health - healthDecay : 0;
             attrs.mood = (attrs.mood > moodDecay) ? attrs.mood - moodDecay : 0;
             attrs.lastInteractionTime = block.timestamp; // Update timestamp when decay is applied

             emit AttributeDecayed(tokenId, healthDecay, moodDecay, attrs.health, attrs.mood);
        }
        // If no time has passed or decay amounts are zero, nothing happens.
    }


    /**
     * @notice Calculates the staking rewards accrued for a staked companion.
     * @param tokenId The ID of the companion.
     * @return The amount of NURTURE token rewards.
     */
    function _calculateStakingRewards(uint256 tokenId) internal view returns (uint256) {
        uint256 startTime = _stakingStartTime[tokenId];
        if (startTime == 0) {
            return 0; // Not staked
        }

        uint256 timeStaked = block.timestamp - startTime;
        if (timeStaked == 0) {
            return 0; // No time elapsed since staking or last claim
        }

        // Example Yield Calculation: Base rate per day + bonus based on attributes
        CompanionAttributes memory attrs = getCompanionAttributes(tokenId); // Use getter to include decay
        uint256 baseYieldPerSecond = (1000000 * (10**nurtureToken.decimals())) / SECONDS_PER_DAY; // Example: 1 token per day base rate
        uint256 attributeBonusRate = (attrs.level * 1000) + (attrs.health * 500) + (attrs.mood * 200); // Example bonus based on attributes
        uint256 totalYieldPerSecond = baseYieldPerSecond + (attributeBonusRate / SECONDS_PER_DAY); // Simplified bonus application

        uint256 rewards = (totalYieldPerSecond * timeStaked) / (10**nurtureToken.decimals()); // Scale based on token decimals

        // Add any previously accrued but not claimed rewards (optional, depending on claim logic)
        // In this design, claim resets startTime, so _accruedStakingRewards isn't strictly needed for this calculation,
        // but it could be used if claims didn't reset the timer but just deducted from an accruing balance.
        // For now, let's use startTime reset logic.

        return rewards;
    }

     /**
     * @notice Generates initial random-ish attributes for a new companion.
     * Using block variables for pseudo-randomness (NOT SECURE).
     * @return CompanionAttributes struct with initial values.
     */
    function _generateInitialAttributes() internal view returns (CompanionAttributes memory) {
        // Using block hash is deprecated and unreliable/predictable for production randomness.
        // This is for demonstration ONLY.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenCounter.current())));

        uint256 initialHealth = 70 + (seed % 30); // 70-99
        uint256 initialMood = 60 + ((seed / 100) % 40); // 60-99
        uint256 initialLevel = 1; // Always start at level 1
        uint256 initialLastInteractionTime = block.timestamp;

        return CompanionAttributes({
            health: initialHealth,
            mood: initialMood,
            level: initialLevel,
            lastInteractionTime: initialLastInteractionTime
        });
    }

    /**
     * @notice Internal helper to update companion attributes and set the last interaction time.
     * Use this instead of directly writing to the mapping in interaction functions.
     * @param tokenId The ID of the companion.
     * @param attrs The updated CompanionAttributes struct.
     */
    function _updateCompanionAttributes(uint256 tokenId, CompanionAttributes memory attrs) internal {
        // Ensure lastInteractionTime is updated to block.timestamp
        attrs.lastInteractionTime = block.timestamp;
        _companionAttributes[tokenId] = attrs;
    }

    // The following functions are required by ERC721 or AccessControl
    // but are often inherited and don't need explicit implementation
    // unless overriding specific behavior. They are part of the >20 functions
    // count as they define external interaction points, even if inherited.
    // function supportsInterface(bytes4 interfaceId) public view override returns (bool)
    // function balanceOf(address owner) public view override returns (uint256)
    // function ownerOf(uint256 tokenId) public view override returns (address)
    // function approve(address to, uint256 tokenId) public override
    // function getApproved(uint256 tokenId) public view override returns (address)
    // function setApprovalForAll(address operator, bool approved) public override
    // function isApprovedForAll(address owner, address operator) public view override returns (bool)
    // function transferFrom(address from, address to, uint256 tokenId) public override
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override
    // function hasRole(bytes32 role, address account) public view override returns (bool)
    // function getRoleAdmin(bytes32 role) public view override returns (bytes32)
    // function grantRole(bytes32 role, address account) public virtual override
    // function revokeRole(bytes32 role, address account) public virtual override
    // function renounceRole(bytes32 role, address account) public virtual override

    // Adding explicit view functions for inherited AccessControl roles count towards >20
    function hasMinterRole(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function hasConfigRole(address account) public view returns (bool) {
        return hasRole(CONFIG_ROLE, account);
    }

    function hasOracleUpdaterRole(address account) public view returns (bool) {
        return hasRole(ORACLE_UPDATER_ROLE, account);
    }

    // Adding a combined view function for convenience (optional for the count, but useful)
    function getTokenBalanceForCompanion(uint256 tokenId) public view returns (uint256) {
        return getPendingStakingRewards(tokenId); // Alias
    }

     // Adding a view function for staking yield rate (could make _getBaseStakingYieldRate external)
     function getStakingYieldRate(uint256 tokenId) public view returns (uint256) {
        _requireTokenExists(tokenId);
        CompanionAttributes memory attrs = getCompanionAttributes(tokenId); // Use getter for potentially decayed attrs
         // Example logic: Combine base rate and attribute bonus
        uint256 baseYieldPerSecond = (1000000 * (10**nurtureToken.decimals())) / SECONDS_PER_DAY; // Example base rate
        uint256 attributeBonusRate = (attrs.level * 1000) + (attrs.health * 500) + (attrs.mood * 200); // Example bonus
        uint256 totalYieldPerSecond = baseYieldPerSecond + (attributeBonusRate / SECONDS_PER_DAY);
        return totalYieldPerSecond; // Return the yield rate per second scaled by token decimals
     }
}
```