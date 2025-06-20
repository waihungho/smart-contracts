Okay, here is a smart contract concept that blends dynamic NFTs, a reputation system, on-chain crafting/evolution, time-based mechanics, and controlled system parameters. It's designed to be somewhat complex and illustrate several distinct functionalities interacting with each other.

**Concept: The Aetherium Forge & Sentinels**

This contract manages the *state* and *interactions* of "Sentinel" NFTs (assuming Sentinels are ERC721 tokens managed externally or conceptually). It introduces mutable attributes, a user reputation system ("Forge Mastery"), time-based attribute decay/growth, a "Fusion" mechanism to combine Sentinels, a "Discovery" mechanism influenced by reputation, and controlled by an "Aetherium Essence" ERC20 token.

**Disclaimer:** This contract is a conceptual example demonstrating advanced features. It is *not* audited or production-ready. Implementing a full, secure ERC721 contract from scratch is complex; this example focuses on the *additional* logic layered on top of an assumed token standard. The randomness used (`block.timestamp` and `blockhash`) is *not* secure or truly random for high-value applications and would require a dedicated oracle like Chainlink VRF in production.

---

**Outline & Function Summary**

1.  **Interfaces & Libraries:** Define necessary interfaces (ERC20) and use utilities (AccessControl).
2.  **Errors:** Custom error types for clearer reverts.
3.  **Events:** Signal important state changes.
4.  **Structs:** Define data structures for Sentinels and Nurturing information.
5.  **Constants:** Define role identifiers and potentially other fixed values.
6.  **State Variables:** Store contract configuration, Sentinel data, user data, and global state.
7.  **Access Control:** Use OpenZeppelin's AccessControl for role-based permissions (Admin, Chronicler).
8.  **Constructor:** Initializes roles, links ERC20 token, sets initial parameters.
9.  **Internal Helpers:**
    *   `_processTimeEffects(uint256 tokenId)`: Calculates and applies time-based decay and growth to a Sentinel's stats based on its last update time and nurturing status.
10. **Sentinel Management (Admin/Internal):**
    *   `mintSentinel(address owner, uint256 tokenId, uint256 initialPower, ...)`: Mints (initializes state for) a new Sentinel with base attributes. (Assumes tokenId is managed externally).
    *   `burnSentinelData(uint256 tokenId)`: Clears the state data for a Sentinel (called after external burning or fusion).
11. **User Interaction Functions:**
    *   `refreshSentinelState(uint256 tokenId)`: Allows a user to force an update of a Sentinel's state based on elapsed time.
    *   `startNurturing(uint256 tokenId, uint256 amount)`: Locks Aetherium Essence to start nurturing a Sentinel, enabling growth and pausing decay.
    *   `claimNurtureEffects(uint256 tokenId)`: Processes accrued nurturing growth and potentially claims minor rewards (applies `_processTimeEffects` implicitly).
    *   `stopNurturing(uint256 tokenId)`: Stops nurturing, releases staked Essence, and applies final time effects.
    *   `performFusion(uint256 tokenId1, uint256 tokenId2)`: Attempts to fuse two Sentinels, burning them and potentially creating a new one with combined/mutated stats, influencing user's Forge Mastery.
    *   `attemptDiscovery()`: Consumes a small amount of Essence and uses Forge Mastery for a chance to trigger a discovery event (e.g., finding a reward).
    *   `applyEssenceCatalyst(uint256 tokenId, uint256 amount)`: Burns Essence to apply a temporary or permanent stat buff to a Sentinel.
12. **Query Functions (View/Pure):**
    *   `getSentinelStats(uint256 tokenId)`: Retrieves the last known stats of a Sentinel.
    *   `getUserForgeMastery(address user)`: Retrieves a user's current Forge Mastery score.
    *   `getNexusStateHash()`: Retrieves the current global Nexus state hash.
    *   `getNurtureInfo(uint256 tokenId)`: Retrieves the nurturing status and staked amount for a Sentinel.
    *   `getEstimatedNurtureGrowth(uint256 tokenId)`: Pure function estimating potential growth if nurtured for a given duration.
    *   `getEstimatedDecay(uint256 tokenId)`: Pure function estimating potential decay if not nurtured for a given duration.
    *   `getFusionOutputPreview(uint256 tokenId1, uint256 tokenId2)`: Estimates the outcome stats and success chance of fusing two Sentinels without performing the action.
    *   `getDiscoveryChance(address user)`: Calculates the current chance of successful discovery based on user's Forge Mastery and contract parameters.
13. **Admin Functions (onlyRole(DEFAULT_ADMIN_ROLE)):**
    *   `setEssenceToken(address tokenAddress)`: Sets the address of the Aetherium Essence ERC20 token.
    *   `setNurtureParams(uint256 growthRatePerSecond, uint64 baseDecayRate)`: Sets parameters for nurturing growth and base decay.
    *   `setFusionParams(uint256 baseSuccessChancePermil, uint256 masteryInfluencePermil)`: Sets parameters for fusion success chance calculation.
    *   `setDiscoveryParams(uint256 baseChancePermil, uint256 masteryInfluencePermil, uint256 essenceCost)`: Sets parameters for the discovery mechanism.
    *   `setNexusStateHash(bytes32 newHash)`: Updates the global Nexus state hash.
    *   `grantChroniclerRole(address chronicler)`: Grants the Chronicler role.
    *   `revokeChroniclerRole(address chronicler)`: Revokes the Chronicler role.
    *   `withdrawContractTokens(address tokenAddress, address recipient, uint256 amount)`: Allows admin to withdraw tokens from the contract (e.g., accumulated fees or accidentally sent tokens).
14. **Chronicler Function (onlyRole(CHRONICLER_ROLE)):**
    *   `recordEvent(string memory eventDescription)`: Allows a Chronicler to record a significant event on-chain via an event log.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// We'll use OpenZeppelin's AccessControl for managing roles
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol"; // More robust ownership transfer

// Note: This contract assumes Sentinel NFTs (referenced by tokenId) exist in an external ERC721 contract.
// This contract manages the MUTABLE STATE and INTERACTIONS related to those tokenIds.
// It does *not* handle ERC721 ownership, transfers, approvals itself.

/**
 * @title AetheriumForge
 * @dev Manages the state and interactions of Sentinel NFTs, including mutable attributes,
 *      nurturing, fusion, discovery, user reputation, and time-based effects.
 *      Assumes Sentinel NFTs are tracked via tokenIds owned externally.
 */
contract AetheriumForge is AccessControl, Ownable2Step {
    using SafeERC20 for IERC20;

    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╦ ╦╔╦╗╔═╗╔═╗╦╔═╔═╗
      ║╣ ║ ║ ║ ╠═╣║ ║╠╩╗╚═╗
      ╚═╝╚═╝ ╩ ╩ ╩╚═╝╩ ╩╚═╝
    ═════════════════════════════════════════════════════════════════════════*/

    // --- Custom Errors ---
    error SentinelNotFound(uint256 tokenId);
    error SentinelAlreadyExists(uint256 tokenId);
    error NotEnoughEssence(uint256 required, uint256 available);
    error NurtureAmountZero();
    error SentinelNotNurturing(uint256 tokenId);
    error CannotFuseSelf();
    error FusionRequiresTwoSentinels();
    error NotEnoughForgeMastery(uint256 required, uint256 available);
    error NoEssenceTokenSet();
    error InvalidAmount();
    error NothingToClaim(uint256 tokenId);
    error CatalystNotImplemented(string reason); // Placeholder for future catalyst types

    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, uint256 power, uint256 wisdom, uint256 spirit);
    event SentinelBurned(uint256 indexed tokenId); // Signaled when state is cleared
    event SentinelStateUpdated(uint256 indexed tokenId, uint256 power, uint256 wisdom, uint256 spirit, uint64 decayRate);
    event NurturingStarted(uint256 indexed tokenId, uint256 amount, uint64 startTime);
    event NurturingStopped(uint256 indexed tokenId, uint256 remainingEssence);
    event NurturingEffectsClaimed(uint256 indexed tokenId, uint256 powerGrowth, uint256 wisdomGrowth, uint256 spiritGrowth);
    event FusionPerformed(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newOrUpdatedTokenId, bool success, uint256 newPower, uint256 newWisdom, uint256 newSpirit, uint256 forgeMasteryGained);
    event DiscoveryAttempted(address indexed user, uint256 forgeMastery, bool success);
    event EssenceCatalystApplied(uint256 indexed tokenId, uint256 essenceConsumed, uint256 powerBuff, uint256 wisdomBuff, uint256 spiritBuff);
    event NexusStateUpdated(bytes32 newHash);
    event ChroniclerEventRecorded(address indexed chronicler, uint64 timestamp, string description);
    event ParametersUpdated(string paramName, uint256 value1, uint256 value2); // Generic event for param changes
    event TokenWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);

    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╦ ╦╔═╗╦═╗╦  ╦╔═╗╦═╗
      ║  ╚╦╝║╣ ╠╦╝║  ║║╣ ╠╦╝
      ╚═╝ ╩ ╚═╝╩╚═╩═╝╩╚═╝╩╚══
    ═════════════════════════════════════════════════════════════════════════*/

    // --- Structs ---
    struct Sentinel {
        uint256 power;
        uint256 wisdom;
        uint256 spirit;
        uint64 lastStateUpdate; // Timestamp of the last time time-based effects were processed
        uint64 decayRate;       // How much stats decay per second (scaled)
        bool exists;            // Simple flag to check if data for this token exists
    }

    struct NurtureInfo {
        uint256 stakedEssence;
        uint66 startTime; // Use 66 bits for timestamp safety margin
        bool isNurturing;
    }

    // --- State Variables ---

    // Data mappings
    mapping(uint256 => Sentinel) public sentinelData;
    mapping(uint256 => NurtureInfo) public nurtureInfo;
    mapping(address => uint256) public userForgeMastery;

    // Global State
    bytes32 public nexusStateHash;

    // Configuration Parameters
    IERC20 public essenceToken;

    uint256 public nurtureGrowthRatePerSecond; // How much stats grow per second nurturing (scaled)
    uint64 public baseDecayRate;               // Base decay rate applied when not nurturing (scaled)
    uint256 public decayFactor;                 // Factor applied to baseDecayRate for actual decayRate calculation (e.g., per stat unit)

    uint256 public fusionBaseSuccessChancePermil; // Base chance of successful fusion (per mille, 0-1000)
    uint256 public masteryFusionInfluencePermil;  // How much mastery influences fusion chance (per mille)
    uint256 public fusionMasteryGainSuccess;      // Mastery gained on successful fusion
    uint256 public fusionMasteryGainFailure;      // Mastery gained/lost on failed fusion

    uint256 public discoveryBaseChancePermil;     // Base chance of successful discovery (per mille)
    uint256 public masteryDiscoveryInfluencePermil; // How much mastery influences discovery chance (per mille)
    uint256 public discoveryEssenceCost;          // Essence cost to attempt discovery
    uint256 public discoveryMasteryGain;          // Mastery gained on discovery attempt

    // Access Control Roles
    bytes32 public constant CHRONICLER_ROLE = keccak256("CHRONICLER_ROLE");

    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔═╗╔╦╗╦ ╦╦═╗╔═╗
      ║ ║╣  ║ ╠═╣╠╦╝║╣
      ╚═╝╚═╝ ╩ ╩ ╩╩╚═╚═╝
    ═════════════════════════════════════════════════════════════════════════*/

    constructor(address _essenceToken) Ownable2Step(msg.sender) {
        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Set initial parameters
        essenceToken = IERC20(_essenceToken);

        // Example values (these would need careful tuning)
        nurtureGrowthRatePerSecond = 1e15; // 1 unit growth per second, scaled
        baseDecayRate = 5e14; // 0.5 unit decay per second, scaled
        decayFactor = 1e13; // Decay rate affected by stat value (e.g., decayRate = baseDecayRate + stat * decayFactor)

        fusionBaseSuccessChancePermil = 500; // 50% base chance
        masteryFusionInfluencePermil = 1; // 1 permil influence per mastery point
        fusionMasteryGainSuccess = 10;
        fusionMasteryGainFailure = 2;

        discoveryBaseChancePermil = 100; // 10% base chance
        masteryDiscoveryInfluencePermil = 2; // 2 permil influence per mastery point
        discoveryEssenceCost = 10 ether; // Example cost
        discoveryMasteryGain = 1;

        // Initial Nexus state (e.g., a hash representing the current "era")
        nexusStateHash = keccak256("INITIAL_NEXUS_STATE");

        emit ParametersUpdated("Initial", nurtureGrowthRatePerSecond, baseDecayRate);
    }

    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔╦╗╦ ╦╔═╗╔╦╗╔═╗╔╦╗╔═╗
      ║ ║ ║ ║ ║║╣  ║ ║ ║ ║ ╚═╗
      ╚═╝ ╩ ╚═╝╚═╝ ╩ ╚═╝ ╩ ╚═╝
    ═════════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Internal helper to calculate and apply time-based effects (decay/growth).
     *      Updates the Sentinel's stats and lastStateUpdate timestamp.
     * @param tokenId The ID of the Sentinel to process.
     */
    function _processTimeEffects(uint256 tokenId) internal {
        Sentinel storage sentinel = sentinelData[tokenId];
        if (!sentinel.exists) {
            revert SentinelNotFound(tokenId); // Should not happen if called correctly
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - sentinel.lastStateUpdate;

        if (timeElapsed == 0) {
            return; // No time has passed since last update
        }

        NurtureInfo storage nurture = nurtureInfo[tokenId];

        if (nurture.isNurturing) {
            // Apply growth
            uint256 growthAmount = nurtureGrowthRatePerSecond * timeElapsed;
            sentinel.power += growthAmount;
            sentinel.wisdom += growthAmount;
            sentinel.spirit += growthAmount;
            // Growth might also slightly decrease decay rate, or provide temporary buffs
            // For simplicity here, just attribute growth.
        } else {
            // Apply decay
            // Decay rate can be influenced by stats themselves (more powerful things decay faster?)
            uint64 effectiveDecayRate = sentinel.decayRate; // Example: baseDecayRate + (sentinel.power + sentinel.wisdom + sentinel.spirit) * decayFactor / 3;

            uint256 decayAmount = uint256(effectiveDecayRate) * timeElapsed; // Ensure multiplication doesn't overflow if rates/time are large

            // Prevent stats from going below zero
            sentinel.power = sentinel.power > decayAmount ? sentinel.power - decayAmount : 0;
            sentinel.wisdom = sentinel.wisdom > decayAmount ? sentinel.wisdom - decayAmount : 0;
            sentinel.spirit = sentinel.spirit > decayAmount ? sentinel.spirit - decayAmount : 0;
        }

        sentinel.lastStateUpdate = currentTime;
        emit SentinelStateUpdated(tokenId, sentinel.power, sentinel.wisdom, sentinel.spirit, sentinel.decayRate);
    }

    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔═╗╦  ╔╦╗╔═╗╦═╗╔═╗╦╔═╔═╗
      ║ ║╣ ║  ║║║║╣ ╠╦╝║ ║╠╩╗╚═╗
      ╚═╝╚═╝╩═╝╩ ╩╚═╝╩╚═╚═╝╩ ╩╚═╝
    ═════════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Initializes the state data for a new Sentinel.
     *      Requires the Admin role. Assumes the actual ERC721 token
     *      is minted by an external process or contract.
     * @param owner The address that owns the Sentinel NFT.
     * @param tokenId The ID of the Sentinel.
     * @param initialPower The initial power stat.
     * @param initialWisdom The initial wisdom stat.
     * @param initialSpirit The initial spirit stat.
     * @param initialDecayRate The initial decay rate.
     */
    function mintSentinel(
        address owner, // Owner in the external ERC721 contract
        uint256 tokenId,
        uint256 initialPower,
        uint256 initialWisdom,
        uint256 initialSpirit,
        uint64 initialDecayRate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (sentinelData[tokenId].exists) {
            revert SentinelAlreadyExists(tokenId);
        }

        sentinelData[tokenId] = Sentinel({
            power: initialPower,
            wisdom: initialWisdom,
            spirit: initialSpirit,
            lastStateUpdate: uint64(block.timestamp),
            decayRate: initialDecayRate,
            exists: true
        });

        // Initialize nurturing info as not nurturing
        nurtureInfo[tokenId] = NurtureInfo({
            stakedEssence: 0,
            startTime: 0,
            isNurturing: false
        });

        emit SentinelMinted(tokenId, owner, initialPower, initialWisdom, initialSpirit);
    }

    /**
     * @dev Clears the state data for a Sentinel. Intended to be called
     *      after the corresponding ERC721 token is burned or consumed
     *      (e.g., during fusion). Requires the Admin role.
     * @param tokenId The ID of the Sentinel whose data to burn.
     */
    function burnSentinelData(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }

        // Ensure no Essence is staked before burning data
        if (nurtureInfo[tokenId].isNurturing) {
             // Optionally, force stop nurturing or revert
             // Let's revert to prevent accidental loss of staked tokens
            revert("Cannot burn data while nurturing is active. Stop nurturing first.");
        }

        delete sentinelData[tokenId];
        delete nurtureInfo[tokenId]; // Clean up nurturing info as well

        emit SentinelBurned(tokenId);
    }


    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔═╗╔═╗╦ ╦╔═╗╔╦╗╔╗ ╔═╗╔═╗
      ║ ║╣ ║╣ ║ ║║╣  ║ ╠╩╗║╣ ╚═╗
      ╚═╝╚═╝╚═╝╚═╝╚═╝ ╩ ╚═╝╚═╝╚═╝
    ═════════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Forces an update of the Sentinel's stats based on elapsed time.
     *      Anyone can call this for any Sentinel.
     * @param tokenId The ID of the Sentinel to refresh.
     */
    function refreshSentinelState(uint256 tokenId) public {
        if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }
        _processTimeEffects(tokenId);
    }

    /**
     * @dev Starts the nurturing process for a Sentinel by staking Aetherium Essence.
     *      Requires the caller to own the Sentinel NFT (not checked in this contract,
     *      assumed to be handled by the external caller or NFT contract checks).
     *      Requires prior approval of Essence tokens to the Forge contract.
     * @param tokenId The ID of the Sentinel to nurture.
     * @param amount The amount of Aetherium Essence to stake.
     */
    function startNurturing(uint256 tokenId, uint256 amount) public {
        if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }
        if (amount == 0) {
            revert NurtureAmountZero();
        }
        if (address(essenceToken) == address(0)) {
            revert NoEssenceTokenSet();
        }

        // Process any time effects *before* starting new nurture period
        _processTimeEffects(tokenId);

        NurtureInfo storage nurture = nurtureInfo[tokenId];

        // If already nurturing, add to staked amount and reset timer? Or stop and restart?
        // Let's add to staked amount and extend the effective nurturing power, but keep original start time
        // A more complex system might track "nurturing power" based on staked amount over time.
        // For simplicity, let's just add the amount. Growth calculation would need refinement.
        // Let's choose a simpler approach: stop current, start new.

        if (nurture.isNurturing) {
             stopNurturing(tokenId); // Processes effects, unstakes
        }

        essenceToken.safeTransferFrom(msg.sender, address(this), amount);

        nurture.stakedEssence = amount; // In a real system, amount affects growth rate
        nurture.startTime = uint66(block.timestamp);
        nurture.isNurturing = true;

        emit NurturingStarted(tokenId, amount, nurture.startTime);
    }

    /**
     * @dev Stops the nurturing process for a Sentinel and unstakes the Essence.
     *      Applies pending time effects before stopping.
     * @param tokenId The ID of the Sentinel to stop nurturing.
     */
    function stopNurturing(uint256 tokenId) public {
        if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }

        NurtureInfo storage nurture = nurtureInfo[tokenId];

        if (!nurture.isNurturing) {
            revert SentinelNotNurturing(tokenId);
        }

        // Process time effects before stopping
        _processTimeEffects(tokenId);

        uint256 stakedAmount = nurture.stakedEssence;

        nurture.stakedEssence = 0;
        nurture.startTime = 0;
        nurture.isNurturing = false;

        // Transfer staked essence back to the user
        if (stakedAmount > 0) {
            if (address(essenceToken) == address(0)) {
                 revert NoEssenceTokenSet(); // Should not happen if nurturing started
            }
            essenceToken.safeTransfer(msg.sender, stakedAmount);
        }

        emit NurturingStopped(tokenId, stakedAmount);
    }

     /**
     * @dev Claims the effects of nurturing up to the current time without stopping the process.
     *      Processes pending time effects and updates stats.
     *      Does NOT unstake Essence. Can be called periodically to apply growth.
     * @param tokenId The ID of the Sentinel to claim effects for.
     */
    function claimNurtureEffects(uint256 tokenId) public {
         if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }
         NurtureInfo storage nurture = nurtureInfo[tokenId];

        if (!nurture.isNurturing) {
            revert SentinelNotNurturing(tokenId);
        }

        uint256 oldPower = sentinelData[tokenId].power;
        uint256 oldWisdom = sentinelData[tokenId].wisdom;
        uint256 oldSpirit = sentinelData[tokenId].spirit;

        // Processing time effects applies the growth
        _processTimeEffects(tokenId);

        uint256 newPower = sentinelData[tokenId].power;
        uint256 newWisdom = sentinelData[tokenId].wisdom;
        uint256 newSpirit = sentinelData[tokenId].spirit;

        uint256 powerGrowth = newPower > oldPower ? newPower - oldPower : 0;
        uint256 wisdomGrowth = newWisdom > oldWisdom ? newWisdom - oldWisdom : 0;
        uint256 spiritGrowth = newSpirit > oldSpirit ? newSpirit - oldSpirit : 0;

        if (powerGrowth == 0 && wisdomGrowth == 0 && spiritGrowth == 0) {
            // This case might happen if time elapsed is negligible since last update,
            // or if nurture growth rate is zero.
             revert NothingToClaim(tokenId);
        }

        emit NurturingEffectsClaimed(tokenId, powerGrowth, wisdomGrowth, spiritGrowth);
    }


    /**
     * @dev Attempts to fuse two Sentinels.
     *      Requires the caller to own both Sentinel NFTs (assumed external check).
     *      Requires burning the two input Sentinels (assumed external call).
     *      May mint a new Sentinel or update an existing one based on success chance.
     *      Influences the user's Forge Mastery.
     * @param tokenId1 The ID of the first Sentinel.
     * @param tokenId2 The ID of the second Sentinel.
     */
    function performFusion(uint256 tokenId1, uint256 tokenId2) public {
        if (!sentinelData[tokenId1].exists) {
            revert SentinelNotFound(tokenId1);
        }
        if (!sentinelData[tokenId2].exists) {
            revert SentinelNotFound(tokenId2);
        }
        if (tokenId1 == tokenId2) {
            revert CannotFuseSelf();
        }

        // Process time effects on both parents before fusion
        _processTimeEffects(tokenId1);
        _processTimeEffects(tokenId2);

        Sentinel storage s1 = sentinelData[tokenId1];
        Sentinel storage s2 = sentinelData[tokenId2];

        // --- Fusion Logic ---
        // 1. Calculate Success Chance
        uint256 userMastery = userForgeMastery[msg.sender];
        uint256 masteryBonus = (userMastery * masteryFusionInfluencePermil) / 1000;
        uint256 totalChance = fusionBaseSuccessChancePermil + masteryBonus;
        if (totalChance > 1000) totalChance = 1000; // Cap chance at 100%

        // Use a simple blockhash based randomness (INSECURE FOR REAL APPS)
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, tokenId1, tokenId2, msg.sender))) % 1000;
        bool success = randomValue < totalChance;

        uint256 newPower = 0;
        uint256 newWisdom = 0;
        uint256 newSpirit = 0;
        uint256 newDecayRate = 0; // Decay rate might also be a fusion outcome
        uint256 outcomeTokenId; // Will be a new ID or one of the parents (if upgrading)

        if (success) {
            // Example Success Logic: Average stats + bonus influenced by Nexus State
            newPower = (s1.power + s2.power) / 2 + (uint256(uint160(nexusStateHash)) % 100); // Simplified Nexus influence
            newWisdom = (s1.wisdom + s2.wisdom) / 2 + (uint256(uint160(nexusStateHash >> 160)) % 100);
            newSpirit = (s1.spirit + s2.spirit) / 2 + (uint256(uint160(nexusStateHash >> 32)) % 100);
            newDecayRate = uint64((s1.decayRate + s2.decayRate) / 2); // Simple average decay

            // Determine outcome token: either mint a new one or upgrade one of the parents
            // Let's simplify and say it always mints a new one. An external process would handle getting a new tokenId.
            // For this contract's state, we'll just create data for a conceptual 'new' token.
            // A real implementation needs a mechanism to get/assign new tokenIds.
            // Let's use a placeholder ID for the new token's data. Admin would need to link this data to a real NFT.
            // A better approach: the fusion result IS the *data* for the new token, and the caller or admin must mint the NFT referencing this data.
            // Let's assume the fusion result overwrites tokenId1 data for simplicity in this sample. This is less cool than minting new, but avoids external tokenId management complexity in this code.
            // Let's go with a slightly more complex approach: The function returns the stats for the *new* Sentinel, and the caller (or an admin triggered process) is responsible for minting an NFT with this data and burning the old ones. We won't modify internal state for a *new* token directly here. This makes the function pure-ish in terms of *this contract's* ID space, only affecting mastery.

            // --- Revised Fusion Logic (Simpler State Management): ---
            // This contract updates the *caller's mastery* based on fusion outcome.
            // It DOES NOT create/burn Sentinel state data here.
            // It DOES NOT modify the input Sentinel stats.
            // It assumes an external system:
            // 1. Calls this `performFusion` to check success & get outcome stats.
            // 2. Burns the input NFTs.
            // 3. Mints a new NFT (if success) using the returned stats or applies effects (if fail/upgrade).
            // This decouples the state management from the NFT token ID lifecycle slightly, making this contract more about the *mechanics*.

            // Okay, let's revert to the state-managing approach as it's more illustrative of on-chain *effects*.
            // We *will* modify internal state. Let's assume a `nextTokenId` counter exists or the contract is granted permission to mint via an interface call to the ERC721 contract (which is complex).
            // Simplest: Admin must provide a new tokenId or caller expects a new data entry here and links it later. Let's assume the contract manages its *own* sequence of internal data IDs, separate from the external NFT ID, but they are linked.
            // Let's just update tokenId1 and "burn" tokenId2's data. This is simpler than managing new IDs. It means fusion is an "upgrade" of tokenId1.

            // Simpler Revision: Fusion CONSUMES tokenId2's data, boosts tokenId1's stats if successful.
            // tokenId2's *data* is burned. External system must burn the tokenId2 NFT.
            // tokenId1's *data* is updated. External system keeps tokenId1 NFT.

            delete sentinelData[tokenId2]; // Burn data for the second Sentinel
            delete nurtureInfo[tokenId2]; // Clean up nurture info for the second Sentinel

            if (success) {
                // Calculate outcome stats for tokenId1
                s1.power = (s1.power + s2.power) / 2 + (uint256(uint160(nexusStateHash)) % 100);
                s1.wisdom = (s1.wisdom + s2.wisdom) / 2 + (uint256(uint160(nexusStateHash >> 160)) % 100);
                s1.spirit = (s1.spirit + s2.spirit) / 2 + (uint256(uint160(nexusStateHash >> 32)) % 100);
                s1.decayRate = uint64((s1.decayRate + s2.decayRate) / 2);

                // Update last state update time for tokenId1
                s1.lastStateUpdate = uint64(block.timestamp);

                userForgeMastery[msg.sender] += fusionMasteryGainSuccess;
                outcomeTokenId = tokenId1; // tokenId1 was upgraded

            } else {
                 // Example Failure Logic: Minor stat boost or penalty to tokenId1
                 s1.power = s1.power + s2.power/10; // Minor boost
                 s1.wisdom = s1.wisdom + s2.wisdom/10;
                 s1.spirit = s1.spirit + s2.spirit/10;

                 // Could also introduce a penalty or change decay rate on failure
                 // s1.decayRate = uint64(uint256(s1.decayRate) * 1100 / 1000); // Increase decay by 10% on failure

                 s1.lastStateUpdate = uint64(block.timestamp);

                 if (userForgeMastery[msg.sender] >= fusionMasteryGainFailure) {
                     userForgeMastery[msg.sender] -= fusionMasteryGainFailure; // Lose mastery on failure
                 } else {
                     userForgeMastery[msg.sender] = 0;
                 }
                 outcomeTokenId = tokenId1; // tokenId1 received minor change
            }

             emit SentinelBurned(tokenId2); // Signal data for tokenId2 was removed
             emit SentinelStateUpdated(tokenId1, s1.power, s1.wisdom, s1.spirit, s1.decayRate);
             emit FusionPerformed(tokenId1, tokenId2, outcomeTokenId, success, s1.power, s1.wisdom, s1.spirit, success ? fusionMasteryGainSuccess : (userForgeMastery[msg.sender] > 0 ? fusionMasteryGainFailure : 0)); // Report mastery change
    }

    /**
     * @dev Attempts a discovery using the user's Forge Mastery.
     *      Consumes Aetherium Essence. Has a chance of success influenced by mastery.
     *      Successful discovery would trigger an external event or internal reward logic.
     */
    function attemptDiscovery() public {
        if (address(essenceToken) == address(0)) {
            revert NoEssenceTokenSet();
        }
        if (discoveryEssenceCost == 0) {
             revert("Discovery currently disabled or free.");
        }

        // Ensure user has enough Essence approved/transferred to the contract
        // This requires user to call essenceToken.approve(address(this), discoveryEssenceCost) beforehand.
        essenceToken.safeTransferFrom(msg.sender, address(this), discoveryEssenceCost);

        uint256 userMastery = userForgeMastery[msg.sender];

        // 1. Calculate Success Chance
        uint256 masteryBonus = (userMastery * masteryDiscoveryInfluencePermil) / 1000;
        uint256 totalChance = discoveryBaseChancePermil + masteryBonus;
        if (totalChance > 1000) totalChance = 1000; // Cap chance at 100%

         // Use a simple blockhash based randomness (INSECURE FOR REAL APPS)
        uint265 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 1000;
        bool success = randomValue < totalChance;

        userForgeMastery[msg.sender] += discoveryMasteryGain; // Gain mastery for attempting

        emit DiscoveryAttempted(msg.sender, userMastery, success);

        if (success) {
            // Trigger logic for a successful discovery
            // This could be:
            // - Minting a new NFT (Relic) via an external contract call
            // - Transferring some tokens from a contract pool
            // - Emitting a specific event that an off-chain system monitors
            // - Updating an internal state for a reward claim

            // Example: Emit an event for off-chain system
            emit ChroniclerEventRecorded(address(0), uint64(block.timestamp), string(abi.encodePacked("Discovery Successful for ", Strings.toHexString(uint160(msg.sender), 20))));
        }
    }

    /**
     * @dev Applies a temporary or permanent stat buff to a Sentinel by burning Essence.
     *      Requires the caller to own the Sentinel (assumed external check).
     * @param tokenId The ID of the Sentinel.
     * @param amount The amount of Essence to burn as a catalyst.
     */
    function applyEssenceCatalyst(uint256 tokenId, uint256 amount) public {
        if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (address(essenceToken) == address(0)) {
            revert NoEssenceTokenSet();
        }

        // Requires prior approval of Essence tokens
        essenceToken.safeTransferFrom(msg.sender, address(this), amount);
        essenceToken.safeTransfer(address(0), amount); // Burn the essence

        // Process time effects before applying catalyst
        _processTimeEffects(tokenId);

        Sentinel storage sentinel = sentinelData[tokenId];

        // --- Catalyst Effect Logic ---
        // Example: Boost stats based on amount
        uint256 powerBuff = amount * 5 / 100; // 5% of essence amount adds to power
        uint256 wisdomBuff = amount * 3 / 100;
        uint256 spiritBuff = amount * 2 / 100;
        // More complex effects could involve temporary buffs, changing decay rate, etc.

        sentinel.power += powerBuff;
        sentinel.wisdom += wisdomBuff;
        sentinel.spirit += spiritBuff;

        // Update last state update time
        sentinel.lastStateUpdate = uint64(block.timestamp);

        emit EssenceCatalystApplied(tokenId, amount, powerBuff, wisdomBuff, spiritBuff);
        emit SentinelStateUpdated(tokenId, sentinel.power, sentinel.wisdom, sentinel.spirit, sentinel.decayRate);
    }

     // Placeholder for other catalyst types (e.g., using another NFT)
    function applyRelicCatalyst(uint256 sentinelTokenId, uint256 relicTokenId) public {
        // This function would interact with an external Relic NFT contract
        // and consume a relic token to affect a sentinel.
        // Requires ownership checks for both tokens (external).
        // Requires burning the Relic NFT (external call).
        // Example: IERC721 relicContract = IERC721(relicContractAddress);
        // relicContract.transferFrom(msg.sender, address(0), relicTokenId); // Burn relic

        // Then apply effects to sentinelData[sentinelTokenId] after processing time effects.
        revert CatalystNotImplemented("Relic Catalyst logic not implemented in this sample.");
    }


    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔═╗╦ ╦╔╦╗╔═╗╦═╗
      ║   ║ ║ ║ ║ ║╣ ╠╦╝
      ╚═╝ ╩ ╚═╝ ╩ ╚═╝╩╚═
    ═════════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Gets the last known stats of a Sentinel. Does *not* process time effects.
     *      Call `refreshSentinelState` before querying for the most up-to-date stats.
     * @param tokenId The ID of the Sentinel.
     * @return The Sentinel's stats and existence flag.
     */
    function getSentinelStats(uint256 tokenId) public view returns (Sentinel memory) {
        if (!sentinelData[tokenId].exists) {
            // Return a struct with exists=false
            return Sentinel({
                power: 0,
                wisdom: 0,
                spirit: 0,
                lastStateUpdate: 0,
                decayRate: 0,
                exists: false
            });
        }
        return sentinelData[tokenId];
    }

    /**
     * @dev Gets the Forge Mastery score for a user.
     * @param user The address of the user.
     * @return The user's Forge Mastery score.
     */
    function getUserForgeMastery(address user) public view returns (uint256) {
        return userForgeMastery[user];
    }

    /**
     * @dev Gets the current global Nexus state hash.
     * @return The Nexus state hash.
     */
    function getNexusStateHash() public view returns (bytes32) {
        return nexusStateHash;
    }

    /**
     * @dev Gets the current nurturing information for a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return The nurturing info.
     */
    function getNurtureInfo(uint256 tokenId) public view returns (NurtureInfo memory) {
        if (!sentinelData[tokenId].exists) {
             // Return default struct if sentinel doesn't exist
             return NurtureInfo({
                 stakedEssence: 0,
                 startTime: 0,
                 isNurturing: false
             });
        }
        return nurtureInfo[tokenId];
    }

    /**
     * @dev Estimates potential growth for a Sentinel if nurtured for a given duration.
     *      Pure function, does not read contract state (except parameters).
     * @param timeInSeconds The duration in seconds.
     * @return The estimated growth in stats.
     */
    function getEstimatedNurtureGrowth(uint256 timeInSeconds) public view returns (uint256 estimatedGrowth) {
        // Simplistic: growth rate is per second per stat for any staked amount > 0
        // A real system might scale growth based on stakedAmount
        return nurtureGrowthRatePerSecond * timeInSeconds;
    }

    /**
     * @dev Estimates potential decay for a Sentinel if not nurtured for a given duration.
     *      Uses the Sentinel's current decay rate. Pure function, does not read contract state.
     * @param tokenId The ID of the Sentinel.
     * @param timeInSeconds The duration in seconds.
     * @return The estimated decay in stats.
     */
     function getEstimatedDecay(uint256 tokenId, uint256 timeInSeconds) public view returns (uint256 estimatedDecay) {
        if (!sentinelData[tokenId].exists) {
            revert SentinelNotFound(tokenId);
        }
        // Decay rate can be influenced by stats themselves (more powerful things decay faster?)
        // This view function assumes the decayRate stored is the 'effective' rate or calculates it.
        // Let's assume the stored decayRate is the effective rate *at the last update*.
        // A truly accurate estimate needs current stats, but view functions shouldn't process state.
        // So, this estimate uses the *last known* decay rate.
        uint64 effectiveDecayRateAtLastUpdate = sentinelData[tokenId].decayRate;

        return uint256(effectiveDecayRateAtLastUpdate) * timeInSeconds;
    }


    /**
     * @dev Provides a preview of the potential outcome stats and success chance for a fusion.
     *      Does *not* perform the fusion or modify state. Useful for UI.
     * @param tokenId1 The ID of the first Sentinel.
     * @param tokenId2 The ID of the second Sentinel.
     * @return successChancePermil Estimated success chance (0-1000), estimatedPower, estimatedWisdom, estimatedSpirit.
     */
    function getFusionOutputPreview(uint256 tokenId1, uint256 tokenId2) public view returns (uint256 successChancePermil, uint256 estimatedPower, uint256 estimatedWisdom, uint256 estimatedSpirit) {
         if (!sentinelData[tokenId1].exists) {
            revert SentinelNotFound(tokenId1);
        }
        if (!sentinelData[tokenId2].exists) {
            revert SentinelNotFound(tokenId2);
        }
         if (tokenId1 == tokenId2) {
            revert CannotFuseSelf();
        }

        // Note: This preview uses the *last known* stats. A real system might process time effects here too, but view functions shouldn't change state.
        // For a truly accurate preview reflecting time effects, the user would need to call refreshSentinelState first.
        Sentinel storage s1 = sentinelData[tokenId1];
        Sentinel storage s2 = sentinelData[tokenId2];

        // Estimate Success Chance
        uint256 userMastery = userForgeMastery[msg.sender];
        uint256 masteryBonus = (userMastery * masteryFusionInfluencePermil) / 1000;
        successChancePermil = fusionBaseSuccessChancePermil + masteryBonus;
        if (successChancePermil > 1000) successChancePermil = 1000;

        // Estimate Success Outcome Stats (Example: Average + potential Nexus influence)
        estimatedPower = (s1.power + s2.power) / 2 + (uint256(uint160(nexusStateHash)) % 100); // Estimate potential bonus
        estimatedWisdom = (s1.wisdom + s2.wisdom) / 2 + (uint256(uint160(nexusStateHash >> 160)) % 100);
        estimatedSpirit = (s1.spirit + s2.spirit) / 2 + (uint256(uint160(nexusStateHash >> 32)) % 100);

        // Could also provide estimated failure outcome stats

        return (successChancePermil, estimatedPower, estimatedWisdom, estimatedSpirit);
    }

    /**
     * @dev Calculates the current chance of a successful discovery attempt for a user.
     *      Pure function, does not read contract state (except parameters and mastery).
     * @param user The address of the user.
     * @return The discovery success chance in permil (0-1000).
     */
    function getDiscoveryChance(address user) public view returns (uint256 chancePermil) {
        uint256 userMastery = userForgeMastery[user];
        uint256 masteryBonus = (userMastery * masteryDiscoveryInfluencePermil) / 1000;
        chancePermil = discoveryBaseChancePermil + masteryBonus;
        if (chancePermil > 1000) chancePermil = 1000;
        return chancePermil;
    }


    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔═╗╔╦╗╦╔═╗╔╦╗
      ║ ║╣  ║ ║║╣  ║
      ╚═╝╚═╝ ╩ ╩╚═╝ ╩
    ═════════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Sets the address of the Aetherium Essence ERC20 token.
     *      Requires the Admin role.
     * @param tokenAddress The address of the ERC20 token contract.
     */
    function setEssenceToken(address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        essenceToken = IERC20(tokenAddress);
        // Consider adding checks that it's a valid ERC20
        emit ParametersUpdated("EssenceToken", uint256(uint160(tokenAddress)), 0);
    }

    /**
     * @dev Sets parameters for the nurturing and decay mechanics.
     *      Requires the Admin role.
     * @param growthRatePerSecond The new nurture growth rate per second (scaled).
     * @param baseDecayRate The new base decay rate (scaled).
     */
    function setNurtureParams(uint256 growthRatePerSecond, uint64 baseDecayRate_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nurtureGrowthRatePerSecond = growthRatePerSecond;
        baseDecayRate = baseDecayRate_;
        // decayFactor also a nurture param? Add if needed
        emit ParametersUpdated("NurtureDecay", growthRatePerSecond, baseDecayRate_);
    }

    /**
     * @dev Sets parameters for the fusion mechanics.
     *      Requires the Admin role.
     * @param baseSuccessChancePermil_ New base chance (0-1000).
     * @param masteryInfluencePermil_ New mastery influence (0-1000).
     * @param masteryGainSuccess New mastery gain on success.
     * @param masteryGainFailure New mastery gain/loss on failure.
     */
    function setFusionParams(uint256 baseSuccessChancePermil_, uint256 masteryInfluencePermil_, uint256 masteryGainSuccess, uint256 masteryGainFailure) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(baseSuccessChancePermil_ <= 1000, "Base chance exceeds 1000");
        require(masteryInfluencePermil_ <= 1000, "Mastery influence exceeds 1000");
        fusionBaseSuccessChancePermil = baseSuccessChancePermil_;
        masteryFusionInfluencePermil = masteryInfluencePermil_;
        fusionMasteryGainSuccess = masteryGainSuccess;
        fusionMasteryGainFailure = masteryGainFailure;
        emit ParametersUpdated("Fusion", baseSuccessChancePermil_, masteryInfluencePermil_); // Simplify event params
    }

    /**
     * @dev Sets parameters for the discovery mechanism.
     *      Requires the Admin role.
     * @param baseChancePermil_ New base chance (0-1000).
     * @param masteryInfluencePermil_ New mastery influence (0-1000).
     * @param essenceCost_ New Essence cost for attempt.
     * @param masteryGain_ New mastery gain per attempt.
     */
    function setDiscoveryParams(uint256 baseChancePermil_, uint256 masteryInfluencePermil_, uint256 essenceCost_, uint256 masteryGain_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(baseChancePermil_ <= 1000, "Base chance exceeds 1000");
        require(masteryInfluencePermil_ <= 1000, "Mastery influence exceeds 1000");
        discoveryBaseChancePermil = baseChancePermil_;
        masteryDiscoveryInfluencePermil = masteryInfluencePermil_;
        discoveryEssenceCost = essenceCost_;
        discoveryMasteryGain = masteryGain_;
        emit ParametersUpdated("Discovery", baseChancePermil_, masteryInfluencePermil_); // Simplify event params
    }

    /**
     * @dev Updates the global Nexus state hash.
     *      Requires the Admin role. This hash can influence game mechanics.
     * @param newHash The new Nexus state hash.
     */
    function setNexusStateHash(bytes32 newHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nexusStateHash = newHash;
        emit NexusStateUpdated(newHash);
    }

    /**
     * @dev Grants the Chronicler role to an address.
     *      Requires the Admin role.
     * @param chronicler The address to grant the role to.
     */
    function grantChroniclerRole(address chronicler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CHRONICLER_ROLE, chronicler);
    }

    /**
     * @dev Revokes the Chronicler role from an address.
     *      Requires the Admin role.
     * @param chronicler The address to revoke the role from.
     */
    function revokeChroniclerRole(address chronicler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CHRONICLER_ROLE, chronicler);
    }

    /**
     * @dev Withdraws tokens held by the contract (e.g., staked Essence or fees).
     *      Requires the Admin role.
     * @param tokenAddress The address of the token to withdraw.
     * @param recipient The address to send the tokens to.
     * @param amount The amount to withdraw.
     */
    function withdrawContractTokens(address tokenAddress, address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(tokenAddress, recipient, amount);
    }


    /*═════════════════════════════════════════════════════════════════════════
      ╔═╗╔╦╗╦═╗╔═╗╔╦╗╦  ╔═╗╔═╗╦═╗
      ║ ║ ║ ╠╦╝║╣  ║ ║  ║╣ ║╣ ╠╦╝
      ╚═╝ ╩ ╩╚═╚═╝ ╩ ╩═╝╚═╝╚═╝╩╚═
    ═════════════════════════════════════════════════════════════════════════*/

    /**
     * @dev Allows a Chronicler to record a significant event on-chain.
     *      Emits an event that can be monitored. Requires the Chronicler role.
     * @param eventDescription A string describing the event.
     */
    function recordEvent(string memory eventDescription) external onlyRole(CHRONICLER_ROLE) {
        emit ChroniclerEventRecorded(msg.sender, uint64(block.timestamp), eventDescription);
    }

    /*═════════════════════════════════════════════════════════════════════════
      ╦╔═╗╔═╗╔═╗╦╔═
      ║║  ║╣ ╚═╗╠╩╗
      ╩╚═╝╚═╝╚═╝╩ ╩
    ═════════════════════════════════════════════════════════════════════════*/
    // The standard AccessControl functions are also exposed, contributing to the function count:
    // - `hasRole(bytes32 role, address account)`
    // - `getRoleAdmin(bytes32 role)`
    // - `grantRole(bytes32 role, address account)`
    // - `revokeRole(bytes32 role, address account)`
    // - `renounceRole(bytes32 role, address account)`

    // The standard Ownable2Step functions are also exposed:
    // - `transferOwnership(address newOwner)`
    // - `acceptOwnership()`
    // - `owner()`
    // - `pendingOwner()`

    // Total functions (including inherited and specific Chronicler/Admin):
    // Internal: _processTimeEffects
    // Admin/Internal: mintSentinel, burnSentinelData
    // User Interaction: refreshSentinelState, startNurturing, claimNurtureEffects, stopNurturing, performFusion, attemptDiscovery, applyEssenceCatalyst, applyRelicCatalyst (placeholder) -> 8 functions
    // Query: getSentinelStats, getUserForgeMastery, getNexusStateHash, getNurtureInfo, getEstimatedNurtureGrowth, getEstimatedDecay, getFusionOutputPreview, getDiscoveryChance -> 8 functions
    // Admin: setEssenceToken, setNurtureParams, setFusionParams, setDiscoveryParams, setNexusStateHash, grantChroniclerRole, revokeChroniclerRole, withdrawContractTokens -> 8 functions
    // Chronicler: recordEvent -> 1 function
    // AccessControl (inherited): hasRole, getRoleAdmin, grantRole, revokeRole, renounceRole -> 5 functions
    // Ownable2Step (inherited): transferOwnership, acceptOwnership, owner, pendingOwner -> 4 functions

    // Total unique callable functions: 8 + 8 + 8 + 1 + 5 + 4 = 34 functions.
    // This comfortably exceeds the 20 function requirement with interesting and intertwined logic.
}
```