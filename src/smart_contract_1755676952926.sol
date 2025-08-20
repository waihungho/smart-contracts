The following smart contract, **"Echelon Protocol: A Reputation-Driven Ecosystem for Evolving Generative NFTs and Curated Digital Legacy"**, introduces a novel combination of advanced concepts:

*   **Dynamic, Generative NFTs (Echelon Artifacts):** NFTs that are not static images but whose on-chain parameters evolve based on user interaction, resource expenditure, and reputation. These parameters then dictate the visual rendering off-chain.
*   **Reputation System (Echelon Points - EP):** A non-transferable scoring mechanism that users earn through active participation, staking, and contributions. EP directly influences the evolution of artifacts and governance weight.
*   **Epoch-Based Progression:** The protocol operates in distinct time-based epochs, which drive reward distribution, artifact generation parameters, and lore ratification.
*   **Community-Curated Lore Fragments:** A unique feature allowing users to submit and vote on short text snippets. Ratified fragments contribute to a global on-chain "lore seed" that influences the generative attributes of newly minted artifacts in subsequent epochs, creating a truly community-driven aesthetic.
*   **Staking with Influence:** Users can stake the protocol's utility token ($ESSENCE) for specific durations to earn an EP boost, enhancing their influence and artifact evolution capabilities.

This design avoids direct duplication of any single open-source project by combining these sophisticated elements into a cohesive, interlinked system.

---

## **Echelon Protocol: Smart Contract Outline and Function Summary**

**Core Contracts:**
*   `EssenceToken.sol`: ERC-20 token for utility, rewards, and fueling artifact evolution.
*   `EchelonArtifacts.sol`: ERC-721 contract for the generative, evolving NFTs.
*   `EchelonProtocolCore.sol`: The main protocol hub, managing epochs, reputation, lore, and orchestrating interactions with the token contracts.

---

### **Outline of `EchelonProtocolCore.sol` Functions:**

**I. Core Protocol Management (Owner/Admin Functions):**
1.  **`advanceEpoch()`**: Moves the protocol to the next chronological epoch. Triggers epoch-end calculations and lore ratification.
2.  **`updateEpochRewards(uint256 epoch, uint256 essenceAmount)`**: Sets the total `$ESSENCE` rewards for a specified future epoch, minting them into the protocol's pool.
3.  **`setLoreFragmentEpochThreshold(uint256 threshold)`**: Sets the minimum Echelon Points (EP) required for a user to submit a lore fragment.
4.  **`pauseProtocol()`**: Halts core protocol functionalities (e.g., minting, evolving, staking, lore submissions).
5.  **`unpauseProtocol()`**: Resumes core protocol functionalities.
6.  **`withdrawProtocolFees(address token, address recipient, uint256 amount)`**: Allows the contract owner to withdraw accumulated fees or residual tokens.

**II. Echelon Points (Reputation System):**
7.  **`getEchelonPoints(address user)`**: Retrieves the current Echelon Points (EP) for a given user.

**III. Essence Token ($ESSENCE) Interaction:**
8.  **`claimEpochEssenceRewards()`**: Allows users to claim their accrued `$ESSENCE` rewards from past epochs based on their accumulated EP.
9.  **`stakeEssenceForInfluence(uint256 amount, uint256 lockDurationEpochs)`**: Users stake `$ESSENCE` for a defined duration to earn an EP boost and influence artifact evolution.
10. **`unstakeEssence(uint256 stakeId)`**: Allows users to reclaim their staked `$ESSENCE` after the lock period expires.
11. **`getEssenceStakeInfo(uint256 stakeId)`**: Provides details about a specific `$ESSENCE` stake.

**IV. Echelon Artifacts (NFT) Management:**
12. **`mintArtifact()`**: Mints a new generative Echelon Artifact NFT. Costs `$ESSENCE` and grants initial EP. The artifact's initial parameters are influenced by the current epoch and ratified lore.
13. **`evolveArtifact(uint256 tokenId, uint256 essenceFuel)`**: Fuels an existing artifact with `$ESSENCE` to evolve its generative parameters. Evolution is also influenced by the owner's EP.
14. **`batchEvolveArtifacts(uint256[] calldata tokenIds, uint256 totalEssenceFuel)`**: Allows evolving multiple artifacts efficiently in a single transaction, distributing the `totalEssenceFuel` among them.
15. **`lockArtifactForChronos(uint256 tokenId, uint256 lockDurationEpochs)`**: Locks an artifact for a specified number of epochs. This action influences the artifact's "Chronos" attribute and grants long-term EP.
16. **`unlockArtifact(uint256 tokenId, uint256 lockId)`**: Unlocks a previously locked artifact once its lock period has passed.
17. **`getArtifactMetadata(uint256 tokenId)`**: Retrieves the structured generative parameters of an Echelon Artifact for off-chain rendering.

**V. Lore Fragment System (Community Contribution):**
18. **`submitLoreFragment(string memory fragmentContent)`**: Allows users to propose short lore fragments for community consideration, requiring minimum EP and a `$ESSENCE` fee.
19. **`voteOnLoreFragment(uint256 fragmentId, bool approve)`**: Users vote for or against a submitted lore fragment. The vote weight is determined by the user's current EP.
20. **`getLoreFragment(uint256 fragmentId)`**: Retrieves detailed information about a specific lore fragment.
21. **`getCurrentActiveLoreFragments()`**: Returns a list of lore fragment IDs that have been ratified and are currently influencing artifact generation.

**VI. View Functions:**
22. **`getCurrentEpoch()`**: Returns the current epoch number of the protocol.
23. **`getEpochEndTime(uint256 epoch)`**: Returns the timestamp when the specified epoch is expected to transition to the next.

---

### **Solidity Smart Contract Source Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit mul/div protection
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

/**
 * @dev Library for defining the generative parameters of Echelon Artifacts.
 *      These parameters are stored on-chain and are used by off-chain rendering
 *      engines to generate the visual representation of the NFT.
 */
library ArtifactAttributes {
    struct GenerativeParams {
        uint256 creationEpoch;      // Epoch in which the artifact was minted
        uint256 baseColorSeed;      // A seed influencing the artifact's primary color palette
        uint256 shapeComplexity;    // A value representing the complexity of the artifact's form
        uint256 auraIntensity;      // The intensity of a visual "aura" or glow
        uint256 chronosInfluence;   // Represents influence from locking duration, higher for longer locks
        bytes32 loreHashInfluence;  // A hash derived from community-ratified lore fragments
        uint256 evolutionCount;     // How many times the artifact has undergone evolution
        uint256 totalEssenceFueled; // Total Essence spent on this artifact's evolution
    }
}

/**
 * @title EssenceToken
 * @dev ERC-20 token contract for the Echelon Protocol.
 *      It is burnable and has a restricted minter (intended to be EchelonProtocolCore).
 */
contract EssenceToken is ERC20Burnable, Ownable {
    address private _minter;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    modifier onlyMinter() {
        require(msg.sender == _minter, "EssenceToken: only minter can call");
        _;
    }

    /**
     * @notice Sets the address allowed to mint new Essence tokens.
     * @dev Callable only by the contract owner.
     * @param minter_ The address of the EchelonProtocolCore contract.
     */
    function setMinter(address minter_) external onlyOwner {
        _minter = minter_;
    }

    /**
     * @notice Returns the address currently designated as the minter.
     */
    function getMinter() external view returns (address) {
        return _minter;
    }

    /**
     * @notice Mints new Essence tokens and assigns them to an address.
     * @dev Callable only by the designated minter.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }
}

/**
 * @title EchelonArtifacts
 * @dev ERC-721 token contract for generative, evolving NFTs.
 *      Stores generative parameters and manages artifact locking.
 */
contract EchelonArtifacts is ERC721, Ownable {
    using ArtifactAttributes for ArtifactAttributes.GenerativeParams;
    using Math for uint256;
    using SafeMath for uint256;

    // Mapping from tokenId to its generative parameters
    mapping(uint256 => ArtifactAttributes.GenerativeParams) internal _artifactGenerativeParams;
    // Mapping from tokenId to artifact lock info: tokenId => (lockId => unlockEpoch)
    mapping(uint256 => mapping(uint256 => uint256)) internal _artifactLocks;
    // Counter for active locks per artifact: tokenId => count of unique locks
    mapping(uint256 => uint256) internal _artifactLockCount;

    uint256 private _nextTokenId; // Counter for next available NFT token ID
    address private _minter;      // The EchelonProtocolCore contract will be the minter

    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, uint256 epoch, ArtifactAttributes.GenerativeParams params);
    event ArtifactEvolved(uint256 indexed tokenId, ArtifactAttributes.GenerativeParams oldParams, ArtifactAttributes.GenerativeParams newParams);
    event ArtifactLocked(uint256 indexed tokenId, uint256 lockId, uint256 unlockEpoch);
    event ArtifactUnlocked(uint256 indexed tokenId, uint256 lockId);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    modifier onlyMinter() {
        require(msg.sender == _minter, "EchelonArtifacts: only minter can call");
        _;
    }

    /**
     * @notice Sets the address allowed to mint and manage artifact state.
     * @dev Callable only by the contract owner (EchelonProtocolCore address upon deployment).
     * @param minter_ The address of the EchelonProtocolCore contract.
     */
    function setMinter(address minter_) external onlyOwner {
        _minter = minter_;
    }

    /**
     * @notice Returns the address currently designated as the artifact minter/manager.
     */
    function getMinter() external view returns (address) {
        return _minter;
    }

    /**
     * @notice Internal function to mint a new Echelon Artifact NFT.
     * @dev Only callable by the designated minter (EchelonProtocolCore).
     * @param to The address to mint the NFT to.
     * @param epoch The current protocol epoch at mint time.
     * @param loreHashSeed A hash derived from ratified lore fragments, influencing initial parameters.
     * @return tokenId The ID of the newly minted artifact.
     */
    function _mintArtifact(address to, uint256 epoch, bytes32 loreHashSeed) internal onlyMinter returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initial generative parameters based on epoch, a simple hash, and lore seed
        _artifactGenerativeParams[tokenId] = ArtifactAttributes.GenerativeParams({
            creationEpoch: epoch,
            baseColorSeed: uint256(keccak256(abi.encodePacked(tokenId, epoch, block.timestamp))),
            shapeComplexity: 1, // Start at a low complexity
            auraIntensity: 1,   // Start at a low aura intensity
            chronosInfluence: 0,
            loreHashInfluence: loreHashSeed,
            evolutionCount: 0,
            totalEssenceFueled: 0
        });
        emit ArtifactMinted(tokenId, to, epoch, _artifactGenerativeParams[tokenId]);
        return tokenId;
    }

    /**
     * @notice Internal function to evolve an existing Echelon Artifact NFT.
     * @dev Only callable by the designated minter (EchelonProtocolCore).
     * @param tokenId The ID of the artifact to evolve.
     * @param essenceSpent The amount of Essence spent to fuel the evolution.
     * @param userEP The Echelon Points of the artifact owner, influencing evolution.
     */
    function _evolveArtifact(uint256 tokenId, uint256 essenceSpent, uint256 userEP) internal onlyMinter {
        require(_exists(tokenId), "Artifact does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not artifact owner");

        ArtifactAttributes.GenerativeParams storage params = _artifactGenerativeParams[tokenId];
        ArtifactAttributes.GenerativeParams memory oldParams = params; // Copy for event logging

        // Evolution logic: Parameters change based on essence spent and user EP.
        // These formulas are simplified for illustration; real logic could be more complex.
        params.shapeComplexity = params.shapeComplexity.add(essenceSpent / 100).min(1000); // More essence, more complex, capped at 1000
        params.auraIntensity = params.auraIntensity.add(userEP / 1000).min(1000);       // More EP, stronger aura, capped at 1000
        params.evolutionCount = params.evolutionCount.add(1);
        params.totalEssenceFueled = params.totalEssenceFueled.add(essenceSpent);

        emit ArtifactEvolved(tokenId, oldParams, params);
    }

    /**
     * @notice Internal function to lock an Echelon Artifact for a specified duration.
     * @dev Only callable by the designated minter (EchelonProtocolCore).
     * @param tokenId The ID of the artifact to lock.
     * @param unlockEpoch The epoch at which the artifact will become unlocked.
     * @return lockId A unique identifier for this specific lock instance.
     */
    function _lockArtifact(uint256 tokenId, uint256 unlockEpoch) internal onlyMinter returns (uint256 lockId) {
        require(_exists(tokenId), "Artifact does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not artifact owner");

        lockId = _artifactLockCount[tokenId]++; // Assign a new lock ID and increment counter
        _artifactLocks[tokenId][lockId] = unlockEpoch; // Store unlock epoch

        // Apply Chronos influence instantly based on the longest lock duration
        ArtifactAttributes.GenerativeParams storage params = _artifactGenerativeParams[tokenId];
        params.chronosInfluence = params.chronosInfluence.max(unlockEpoch);

        emit ArtifactLocked(tokenId, lockId, unlockEpoch);
        return lockId;
    }

    /**
     * @notice Internal function to unlock a previously locked Echelon Artifact.
     * @dev Only callable by the designated minter (EchelonProtocolCore).
     * @param tokenId The ID of the artifact to unlock.
     * @param lockId The specific lock ID to remove.
     */
    function _unlockArtifact(uint256 tokenId, uint256 lockId) internal onlyMinter {
        require(_exists(tokenId), "Artifact does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not artifact owner");
        require(_artifactLocks[tokenId][lockId] != 0, "Lock does not exist or already unlocked");

        delete _artifactLocks[tokenId][lockId]; // Remove the lock entry

        emit ArtifactUnlocked(tokenId, lockId);
    }

    /**
     * @notice Retrieves the generative parameters for a specific Echelon Artifact.
     * @param tokenId The ID of the artifact.
     * @return A struct containing all generative parameters for off-chain rendering.
     */
    function getArtifactGenerativeParams(uint256 tokenId) public view returns (ArtifactAttributes.GenerativeParams memory) {
        require(_exists(tokenId), "Artifact does not exist");
        return _artifactGenerativeParams[tokenId];
    }

    /**
     * @notice Checks if an artifact is currently locked.
     * @param tokenId The ID of the artifact.
     * @param currentEpoch The current protocol epoch.
     * @return True if the artifact is locked, false otherwise.
     */
    function isArtifactLocked(uint256 tokenId, uint256 currentEpoch) public view returns (bool) {
        // Iterate through all possible lock IDs for this token
        for (uint256 i = 0; i < _artifactLockCount[tokenId]; i++) {
            // If an unlockEpoch is greater than the currentEpoch, it means the lock is still active
            if (_artifactLocks[tokenId][i] > currentEpoch) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Retrieves the unlock epoch for a specific lock on an artifact.
     * @param tokenId The ID of the artifact.
     * @param lockId The specific ID of the lock.
     * @return The epoch at which this lock will expire. Returns 0 if lock doesn't exist.
     */
    function getArtifactLockInfo(uint256 tokenId, uint256 lockId) public view returns (uint256 unlockEpoch) {
        return _artifactLocks[tokenId][lockId];
    }

    /**
     * @notice Returns the total number of Echelon Artifacts minted so far.
     */
    function getTotalArtifactsMinted() public view returns (uint256) {
        return _nextTokenId;
    }
}

/**
 * @title EchelonProtocolCore
 * @dev The main smart contract for the Echelon Protocol.
 *      Manages epochs, reputation (Echelon Points), Essence token interactions,
 *      Echelon Artifact NFT lifecycle, and the community lore fragment system.
 */
contract EchelonProtocolCore is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Math for uint256;

    // --- Core Contracts ---
    EssenceToken public essenceToken;
    EchelonArtifacts public echelonArtifacts;

    // --- Protocol State ---
    uint256 public currentEpoch;        // Current chronological epoch of the protocol
    uint256 public epochDuration;       // Duration of each epoch in seconds
    uint256 public nextEpochStartTime;  // Timestamp when the next epoch begins

    // --- Echelon Points (Reputation) ---
    mapping(address => uint256) public echelonPoints; // User address => EP balance
    uint256 public constant ESSENCE_STAKE_EP_MULTIPLIER = 100; // EP per Essence staked per epoch of lock
    uint256 public constant ARTIFACT_MINT_EP = 50;           // EP granted for minting an artifact
    uint256 public constant ARTIFACT_EVOLVE_EP_PER_ESSENCE = 10; // EP per 100 essence spent on evolution
    uint256 public constant ARTIFACT_LOCK_EP_PER_EPOCH = 10; // EP per epoch duration artifact is locked
    uint256 public constant LORE_VOTE_EP = 5;                // EP granted for voting on lore fragments

    // --- Essence Rewards ---
    mapping(uint256 => uint256) public epochEssenceRewards; // Epoch => Total $ESSENCE available for distribution
    mapping(uint256 => mapping(address => uint256)) public epochClaimedEssence; // Epoch => User => Claimed amount for that epoch
    uint256 public essenceMintFee; // Cost in ESSENCE to mint an artifact (example)

    // --- Staking ---
    struct EssenceStake {
        address staker;
        uint256 amount;
        uint256 startEpoch;
        uint256 unlockEpoch;
        uint256 epBoostGranted; // Total EP boost awarded for this stake
    }
    mapping(address => uint256[]) public userEssenceStakes; // User => Array of stake IDs owned by user
    mapping(uint256 => EssenceStake) public essenceStakes; // Stake ID => Stake Info
    uint256 private _nextStakeId; // Counter for next available stake ID

    // --- Lore Fragments ---
    struct LoreFragment {
        address author;
        string content;
        uint256 submissionEpoch;      // Epoch when the fragment was submitted
        uint256 totalVotesFor;        // Sum of EP from 'for' votes
        uint256 totalVotesAgainst;    // Sum of EP from 'against' votes
        mapping(address => bool) hasVoted; // Tracks if a user has voted on this fragment
        bool ratified;                // True if the fragment passed the vote threshold
    }
    mapping(uint256 => LoreFragment) public loreFragments; // Fragment ID => LoreFragment struct
    uint256 public nextLoreFragmentId; // Counter for next available lore fragment ID
    uint256 public loreFragmentEpochThreshold; // Minimum EP required to submit a lore fragment
    uint256 public loreFragmentSubmitCost; // $ESSENCE cost to submit a lore fragment
    uint256 public loreFragmentVoteThreshold; // Minimum support ratio (e.g., 7000 for 70%) for a fragment to be ratified

    // --- Events ---
    event ProtocolInitialized(uint256 initialEpoch, uint256 epochDuration, address essenceTokenAddr, address echelonArtifactsAddr);
    event EpochAdvanced(uint256 oldEpoch, uint256 newEpoch, uint256 nextStartTime);
    event EpochRewardsUpdated(uint256 epoch, uint256 amount);
    event EchelonPointsGranted(address indexed user, uint256 amount, string reason);
    event EssenceClaimed(address indexed user, uint256 epoch, uint256 amount);
    event EssenceStaked(address indexed staker, uint256 stakeId, uint256 amount, uint256 unlockEpoch);
    event EssenceUnstaked(address indexed staker, uint256 stakeId, uint256 amount);
    event LoreFragmentSubmitted(uint256 indexed fragmentId, address indexed author, string content, uint256 submissionEpoch);
    event LoreFragmentVoted(uint256 indexed fragmentId, address indexed voter, bool voteFor);
    event LoreFragmentRatified(uint256 indexed fragmentId, uint256 ratificationEpoch);

    /**
     * @dev Constructor for the EchelonProtocolCore contract.
     * @param _essenceTokenAddr The address of the deployed EssenceToken contract.
     * @param _echelonArtifactsAddr The address of the deployed EchelonArtifacts contract.
     * @param _epochDuration The duration of each epoch in seconds (e.g., 604800 for 7 days).
     * @param _loreFragmentEpochThreshold The minimum EP required to submit a lore fragment.
     * @param _loreFragmentSubmitCost The cost in Essence for submitting a lore fragment.
     * @param _loreFragmentVoteThreshold The ratio (0-10000) for lore fragment ratification.
     */
    constructor(
        address _essenceTokenAddr,
        address _echelonArtifactsAddr,
        uint256 _epochDuration,
        uint256 _loreFragmentEpochThreshold,
        uint256 _loreFragmentSubmitCost,
        uint256 _loreFragmentVoteThreshold
    ) Ownable(msg.sender) Pausable() {
        require(_essenceTokenAddr != address(0) && _echelonArtifactsAddr != address(0), "Invalid token addresses");

        essenceToken = EssenceToken(_essenceTokenAddr);
        echelonArtifacts = EchelonArtifacts(_echelonArtifactsAddr);

        epochDuration = _epochDuration;
        loreFragmentEpochThreshold = _loreFragmentEpochThreshold;
        loreFragmentSubmitCost = _loreFragmentSubmitCost;
        loreFragmentVoteThreshold = _loreFragmentVoteThreshold;

        // Set this contract as the minter/manager for both associated tokens
        essenceToken.setMinter(address(this));
        echelonArtifacts.setMinter(address(this));

        currentEpoch = 0; // Initialize with epoch 0
        nextEpochStartTime = block.timestamp.add(epochDuration); // Epoch 0 ends / Epoch 1 begins

        // Example artifact mint cost
        essenceMintFee = 100 * (10 ** essenceToken.decimals()); // 100 ESSENCE

        emit ProtocolInitialized(currentEpoch, epochDuration, _essenceTokenAddr, _echelonArtifactsAddr);
    }

    // --- I. Core Protocol Management (Owner/Admin) ---

    /**
     * @notice Advances the protocol to the next epoch.
     * @dev Callable only by the owner or when the current epoch has ended.
     *      This function performs epoch-end calculations, such as lore ratification.
     */
    function advanceEpoch() external onlyOwner nonReentrant {
        require(block.timestamp >= nextEpochStartTime, "EchelonProtocolCore: Not time to advance epoch yet");

        uint256 oldEpoch = currentEpoch;
        currentEpoch = currentEpoch.add(1);
        nextEpochStartTime = nextEpochStartTime.add(epochDuration);

        _processEpochEnd(oldEpoch);

        emit EpochAdvanced(oldEpoch, currentEpoch, nextEpochStartTime);
    }

    /**
     * @notice Sets the total $ESSENCE rewards available for a specific epoch.
     * @dev This amount will be minted into the protocol's balance and later distributed.
     * @param epoch The epoch number for which to set rewards. Must be current or future epoch.
     * @param essenceAmount The total $ESSENCE amount to be distributed in this epoch.
     */
    function updateEpochRewards(uint256 epoch, uint256 essenceAmount) external onlyOwner {
        require(epoch >= currentEpoch, "EchelonProtocolCore: Cannot update past epoch rewards");
        epochEssenceRewards[epoch] = essenceAmount;
        // Mint the rewards into the protocol contract's balance to be distributed later
        essenceToken.mint(address(this), essenceAmount);
        emit EpochRewardsUpdated(epoch, essenceAmount);
    }

    /**
     * @notice Sets the minimum reputation (EP) required for a user to submit a lore fragment.
     * @param threshold The new minimum EP.
     */
    function setLoreFragmentEpochThreshold(uint256 threshold) external onlyOwner {
        loreFragmentEpochThreshold = threshold;
    }

    /**
     * @notice Pauses core protocol functionalities.
     * @dev Prevents minting, evolving, staking, lore submissions/votes. Callable only by owner.
     */
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses core protocol functionalities.
     * @dev Callable only by owner.
     */
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw any residual tokens (ERC20 or native) held by the contract.
     * @dev This is a safeguard against accidental deposits or to withdraw collected fees.
     * @param token The address of the token to withdraw (address(0) for native currency).
     * @param recipient The address to send the tokens to.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawProtocolFees(address token, address recipient, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(recipient).transfer(amount);
        } else {
            ERC20(token).transfer(recipient, amount);
        }
    }

    // --- II. Echelon Points (Reputation System) ---

    /**
     * @notice Internal function to grant Echelon Points to a user.
     * @dev Called by various protocol functions upon specific user actions (e.g., minting, staking).
     * @param user The address to grant EP to.
     * @param amount The amount of EP to grant.
     * @param reason A descriptive string for the reason EP was granted.
     */
    function _grantEchelonPoints(address user, uint256 amount, string memory reason) internal {
        echelonPoints[user] = echelonPoints[user].add(amount);
        emit EchelonPointsGranted(user, amount, reason);
    }

    /**
     * @notice Gets the Echelon Points (reputation) for a given user.
     * @param user The address of the user.
     * @return The Echelon Points balance of the user.
     */
    function getEchelonPoints(address user) public view returns (uint256) {
        return echelonPoints[user];
    }

    // --- III. Essence Token ($ESSENCE) Interaction ---

    /**
     * @notice Allows users to claim their accumulated $ESSENCE rewards from previous epochs.
     * @dev The distribution logic here is simplified for demonstration purposes (pro-rata based on total EP).
     *      A more complex system might track EP earned per epoch or have a specific rewards distribution model.
     */
    function claimEpochEssenceRewards() external nonReentrant whenNotPaused {
        uint256 totalClaimableAmount = 0;
        uint256 userEP = echelonPoints[msg.sender];

        // Iterate through past epochs to find unclaimed rewards
        for (uint256 i = 0; i < currentEpoch; i++) {
            if (epochEssenceRewards[i] > 0 && epochClaimedEssence[i][msg.sender] == 0) {
                // Simplified claim logic: user can claim a small fixed amount based on their EP,
                // or a fraction of the total pool proportional to their EP against a global EP sum.
                // For this example, let's assume a simplified claim based on general participation.
                // This would be replaced by actual complex reward calculation logic in a production system.
                uint256 claimAmountForEpoch = userEP / 1000; // Example: 1 ESSENCE per 1000 EP
                claimAmountForEpoch = claimAmountForEpoch.min(epochEssenceRewards[i]); // Cap by available rewards in pool

                if (claimAmountForEpoch > 0) {
                    totalClaimableAmount = totalClaimableAmount.add(claimAmountForEpoch);
                    epochClaimedEssence[i][msg.sender] = claimAmountForEpoch; // Mark as claimed for this epoch
                }
            }
        }

        require(totalClaimableAmount > 0, "EchelonProtocolCore: No claimable essence rewards found");
        essenceToken.transfer(msg.sender, totalClaimableAmount);
        emit EssenceClaimed(msg.sender, currentEpoch, totalClaimableAmount); // Log total claimed across all applicable epochs
    }

    /**
     * @notice Allows users to stake $ESSENCE for a duration to gain an Echelon Points boost.
     * @param amount The amount of $ESSENCE to stake.
     * @param lockDurationEpochs The number of epochs the $ESSENCE will be locked for (must be > 0).
     * @return stakeId The unique ID of the newly created stake.
     */
    function stakeEssenceForInfluence(uint256 amount, uint256 lockDurationEpochs) external nonReentrant whenNotPaused returns (uint256) {
        require(amount > 0, "EchelonProtocolCore: Stake amount must be greater than zero");
        require(lockDurationEpochs > 0, "EchelonProtocolCore: Lock duration must be at least one epoch");

        essenceToken.transferFrom(msg.sender, address(this), amount); // Transfer essence to protocol contract

        uint256 unlockEpoch = currentEpoch.add(lockDurationEpochs);
        uint256 stakeId = _nextStakeId++;

        // Calculate EP boost based on amount and duration
        uint256 epBoost = amount.mul(ESSENCE_STAKE_EP_MULTIPLIER).mul(lockDurationEpochs);
        _grantEchelonPoints(msg.sender, epBoost, "Essence Stake EP Boost");

        essenceStakes[stakeId] = EssenceStake({
            staker: msg.sender,
            amount: amount,
            startEpoch: currentEpoch,
            unlockEpoch: unlockEpoch,
            epBoostGranted: epBoost
        });

        userEssenceStakes[msg.sender].push(stakeId); // Track stake IDs per user

        emit EssenceStaked(msg.sender, stakeId, amount, unlockEpoch);
        return stakeId;
    }

    /**
     * @notice Allows users to unstake their $ESSENCE after the lock period has passed.
     * @param stakeId The ID of the stake to unstake.
     */
    function unstakeEssence(uint256 stakeId) external nonReentrant whenNotPaused {
        EssenceStake storage stake = essenceStakes[stakeId];
        require(stake.staker == msg.sender, "EchelonProtocolCore: Not your stake");
        require(stake.amount > 0, "EchelonProtocolCore: Stake already claimed or does not exist");
        require(currentEpoch >= stake.unlockEpoch, "EchelonProtocolCore: Stake is still locked");

        uint256 amountToReturn = stake.amount;
        stake.amount = 0; // Mark stake as claimed by setting amount to zero

        essenceToken.transfer(msg.sender, amountToReturn);
        emit EssenceUnstaked(msg.sender, stakeId, amountToReturn);
    }

    /**
     * @notice Retrieves detailed information about a specific essence stake.
     * @param stakeId The ID of the stake.
     * @return A tuple containing staker address, staked amount, start epoch, unlock epoch, and total EP boost granted.
     */
    function getEssenceStakeInfo(uint256 stakeId) public view returns (address staker, uint256 amount, uint256 startEpoch, uint256 unlockEpoch, uint256 epBoostGranted) {
        EssenceStake storage stake = essenceStakes[stakeId];
        return (stake.staker, stake.amount, stake.startEpoch, stake.unlockEpoch, stake.epBoostGranted);
    }

    // --- IV. Echelon Artifacts (NFT) Management ---

    /**
     * @notice Mints a new Echelon Artifact NFT.
     * @dev Requires a certain amount of $ESSENCE as a minting fee and grants initial EP.
     *      The artifact's initial generative parameters are influenced by the current epoch's ratified lore.
     * @return tokenId The ID of the newly minted artifact.
     */
    function mintArtifact() external nonReentrant whenNotPaused returns (uint256 tokenId) {
        essenceToken.transferFrom(msg.sender, address(this), essenceMintFee); // Transfer minting fee

        // Calculate lore influence for new artifact (from previous epoch's ratified lore)
        bytes32 loreHashSeed = _getLoreHashInfluenceForEpoch(currentEpoch);

        tokenId = echelonArtifacts._mintArtifact(msg.sender, currentEpoch, loreHashSeed);
        _grantEchelonPoints(msg.sender, ARTIFACT_MINT_EP, "Artifact Mint");
        return tokenId;
    }

    /**
     * @notice Evolves an existing Echelon Artifact NFT by fueling it with $ESSENCE.
     * @param tokenId The ID of the artifact to evolve.
     * @param essenceFuel The amount of $ESSENCE to spend on evolution (must be > 0).
     * @dev Evolution changes the artifact's generative parameters based on fuel and owner's EP.
     */
    function evolveArtifact(uint256 tokenId, uint256 essenceFuel) external nonReentrant whenNotPaused {
        require(echelonArtifacts.ownerOf(tokenId) == msg.sender, "EchelonProtocolCore: Not artifact owner");
        require(essenceFuel > 0, "EchelonProtocolCore: Essence fuel must be greater than zero");

        essenceToken.transferFrom(msg.sender, address(this), essenceFuel); // Transfer essence for fueling

        uint256 userEP = echelonPoints[msg.sender];
        echelonArtifacts._evolveArtifact(tokenId, essenceFuel, userEP);

        // Grant EP based on essence spent for evolution
        _grantEchelonPoints(msg.sender, essenceFuel.div(100).mul(ARTIFACT_EVOLVE_EP_PER_ESSENCE), "Artifact Evolution");
    }

    /**
     * @notice Evolves multiple Echelon Artifact NFTs in a single transaction.
     * @param tokenIds An array of artifact IDs to evolve. All must be owned by the caller.
     * @param totalEssenceFuel The total amount of $ESSENCE to spend across all artifacts.
     * @dev The `totalEssenceFuel` is divided equally among the artifacts in the batch.
     */
    function batchEvolveArtifacts(uint256[] calldata tokenIds, uint256 totalEssenceFuel) external nonReentrant whenNotPaused {
        require(tokenIds.length > 0, "EchelonProtocolCore: No token IDs provided");
        require(totalEssenceFuel > 0, "EchelonProtocolCore: Total essence fuel must be greater than zero");
        require(totalEssenceFuel >= tokenIds.length, "EchelonProtocolCore: Not enough essence fuel for each artifact");

        essenceToken.transferFrom(msg.sender, address(this), totalEssenceFuel); // Transfer total essence

        uint256 essencePerArtifact = totalEssenceFuel.div(tokenIds.length);
        uint256 userEP = echelonPoints[msg.sender];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(echelonArtifacts.ownerOf(tokenIds[i]) == msg.sender, "EchelonProtocolCore: Not owner of all artifacts in batch");
            echelonArtifacts._evolveArtifact(tokenIds[i], essencePerArtifact, userEP);
        }

        _grantEchelonPoints(msg.sender, totalEssenceFuel.div(100).mul(ARTIFACT_EVOLVE_EP_PER_ESSENCE), "Batch Artifact Evolution");
    }

    /**
     * @notice Locks an Echelon Artifact for a specified number of epochs.
     * @param tokenId The ID of the artifact to lock.
     * @param lockDurationEpochs The number of epochs to lock the artifact for (must be > 0).
     * @return lockId The ID of the new lock instance.
     * @dev Locking influences the artifact's Chronos attribute and grants long-term EP.
     *      An artifact can only have one active lock at a time through this function.
     */
    function lockArtifactForChronos(uint256 tokenId, uint256 lockDurationEpochs) external nonReentrant whenNotPaused returns (uint256 lockId) {
        require(echelonArtifacts.ownerOf(tokenId) == msg.sender, "EchelonProtocolCore: Not artifact owner");
        require(lockDurationEpochs > 0, "EchelonProtocolCore: Lock duration must be at least one epoch");
        // Ensure the artifact is not currently locked through this mechanism
        require(!echelonArtifacts.isArtifactLocked(tokenId, currentEpoch), "Artifact already locked");

        uint256 unlockEpoch = currentEpoch.add(lockDurationEpochs);
        lockId = echelonArtifacts._lockArtifact(tokenId, unlockEpoch);

        // Grant EP for locking artifacts (proportional to lock duration)
        _grantEchelonPoints(msg.sender, lockDurationEpochs.mul(ARTIFACT_LOCK_EP_PER_EPOCH), "Artifact Lock");
        return lockId;
    }

    /**
     * @notice Unlocks a previously locked Echelon Artifact after its lock period has expired.
     * @param tokenId The ID of the artifact to unlock.
     * @param lockId The specific lock ID to remove.
     */
    function unlockArtifact(uint256 tokenId, uint256 lockId) external nonReentrant whenNotPaused {
        require(echelonArtifacts.ownerOf(tokenId) == msg.sender, "EchelonProtocolCore: Not artifact owner");
        // Check if the lock exists and if its unlock epoch has passed
        require(echelonArtifacts.getArtifactLockInfo(tokenId, lockId) <= currentEpoch, "EchelonProtocolCore: Artifact still locked");

        echelonArtifacts._unlockArtifact(tokenId, lockId);
    }

    /**
     * @notice Gets the generative parameters for an Echelon Artifact.
     * @param tokenId The ID of the artifact.
     * @return A struct containing the generative parameters.
     */
    function getArtifactMetadata(uint256 tokenId) public view returns (ArtifactAttributes.GenerativeParams memory) {
        return echelonArtifacts.getArtifactGenerativeParams(tokenId);
    }

    // --- V. Lore Fragment System (Community Contribution) ---

    /**
     * @notice Allows users to submit a new lore fragment for community consideration.
     * @param fragmentContent The text content of the lore fragment.
     * @return fragmentId The ID of the newly submitted lore fragment.
     * @dev Requires minimum EP and costs $ESSENCE. Content length is capped.
     */
    function submitLoreFragment(string memory fragmentContent) external nonReentrant whenNotPaused returns (uint256 fragmentId) {
        require(bytes(fragmentContent).length > 0, "Lore fragment cannot be empty");
        require(bytes(fragmentContent).length <= 256, "Lore fragment too long (max 256 bytes)"); // Cap length
        require(echelonPoints[msg.sender] >= loreFragmentEpochThreshold, "EchelonProtocolCore: Not enough Echelon Points to submit lore");

        essenceToken.transferFrom(msg.sender, address(this), loreFragmentSubmitCost); // Transfer submission fee

        fragmentId = nextLoreFragmentId++;
        loreFragments[fragmentId] = LoreFragment({
            author: msg.sender,
            content: fragmentContent,
            submissionEpoch: currentEpoch,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool)(), // Initialize internal mapping
            ratified: false
        });

        emit LoreFragmentSubmitted(fragmentId, msg.sender, fragmentContent, currentEpoch);
        return fragmentId;
    }

    /**
     * @notice Allows users to vote on a submitted lore fragment.
     * @param fragmentId The ID of the lore fragment to vote on.
     * @param approve True for a vote in favor, false for a vote against.
     * @dev Voting is EP-weighted: the user's current Echelon Points determines their vote's influence.
     *      Users can only vote once per fragment and only on fragments submitted in the current epoch.
     */
    function voteOnLoreFragment(uint256 fragmentId, bool approve) external nonReentrant whenNotPaused {
        LoreFragment storage fragment = loreFragments[fragmentId];
        require(fragment.author != address(0), "Lore fragment does not exist");
        require(!fragment.hasVoted[msg.sender], "EchelonProtocolCore: Already voted on this fragment");
        require(fragment.submissionEpoch == currentEpoch, "EchelonProtocolCore: Can only vote on fragments from current epoch");

        uint256 voteWeight = echelonPoints[msg.sender];
        require(voteWeight > 0, "EchelonProtocolCore: Cannot vote with 0 Echelon Points");

        if (approve) {
            fragment.totalVotesFor = fragment.totalVotesFor.add(voteWeight);
        } else {
            fragment.totalVotesAgainst = fragment.totalVotesAgainst.add(voteWeight);
        }
        fragment.hasVoted[msg.sender] = true;

        _grantEchelonPoints(msg.sender, LORE_VOTE_EP, "Lore Vote"); // Small EP for participation
        emit LoreFragmentVoted(fragmentId, msg.sender, approve);
    }

    /**
     * @notice Retrieves details of a specific lore fragment.
     * @param fragmentId The ID of the lore fragment.
     * @return A tuple containing author, content, submission epoch, total EP votes for, total EP votes against, and ratification status.
     */
    function getLoreFragment(uint256 fragmentId) public view returns (address author, string memory content, uint256 submissionEpoch, uint256 totalVotesFor, uint256 totalVotesAgainst, bool ratified) {
        LoreFragment storage fragment = loreFragments[fragmentId];
        return (fragment.author, fragment.content, fragment.submissionEpoch, fragment.totalVotesFor, fragment.totalVotesAgainst, fragment.ratified);
    }

    /**
     * @notice Returns a list of lore fragment IDs that have been ratified for the current epoch's influence.
     * @dev This function iterates through all submitted fragments and filters for ratified ones.
     *      Note: For performance, this might need optimization if `nextLoreFragmentId` becomes very large.
     * @return An array of ratified lore fragment IDs.
     */
    function getCurrentActiveLoreFragments() public view returns (uint256[] memory) {
        uint256[] memory activeFragments = new uint256[](nextLoreFragmentId); // Allocate max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < nextLoreFragmentId; i++) {
            if (loreFragments[i].ratified) { // Assumes 'ratified' means it's active for current/future influence
                activeFragments[count++] = i;
            }
        }
        // Resize array to actual count for efficiency
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeFragments[i];
        }
        return result;
    }


    // --- VI. View Functions ---

    /**
     * @notice Returns the current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Returns the timestamp when a specific epoch is expected to end (i.e., when the next epoch begins).
     * @dev This returns `nextEpochStartTime` as it represents the transition point.
     *      For epoch N, this value signifies the start of Epoch N+1.
     * @param epoch The epoch number. (Note: The `epoch` parameter is not used in this simplified calculation,
     *        as `nextEpochStartTime` directly reflects the end of the `currentEpoch`).
     */
    function getEpochEndTime(uint256 epoch) public view returns (uint256) {
        // A more precise calculation would be:
        // `(contract_deployment_time + (epoch + 1) * epochDuration)`
        // For simplicity, we expose `nextEpochStartTime` which is the end of the current epoch.
        return nextEpochStartTime;
    }

    // --- Internal Logic ---

    /**
     * @dev Processes end-of-epoch tasks, including lore fragment ratification and reward distribution.
     * @param oldEpoch The epoch that just ended.
     */
    function _processEpochEnd(uint256 oldEpoch) internal {
        _ratifyLoreFragments(oldEpoch);
        _distributeEssenceRewards(oldEpoch);
        // Potentially add more epoch-end logic here, e.g., decaying EP for inactive users,
        // re-evaluating global parameters for artifacts based on accumulated state.
    }

    /**
     * @dev Ratifies lore fragments submitted in the past epoch (`epochToRatify`) for future influence.
     *      Fragments must meet the `loreFragmentVoteThreshold` to be ratified.
     */
    function _ratifyLoreFragments(uint256 epochToRatify) internal {
        for (uint256 i = 0; i < nextLoreFragmentId; i++) {
            LoreFragment storage fragment = loreFragments[i];
            // Only process fragments submitted in the epoch that just ended and not yet ratified
            if (fragment.submissionEpoch == epochToRatify && !fragment.ratified) {
                uint256 totalVotes = fragment.totalVotesFor.add(fragment.totalVotesAgainst);
                if (totalVotes > 0) {
                    // Calculate support ratio (e.g., 7000 for 70%)
                    uint256 supportRatio = fragment.totalVotesFor.mul(10000).div(totalVotes);
                    if (supportRatio >= loreFragmentVoteThreshold) {
                        fragment.ratified = true;
                        emit LoreFragmentRatified(i, currentEpoch); // Ratified for influence starting this new 'currentEpoch'
                    }
                }
            }
        }
    }

    /**
     * @dev Calculates a combined hash of all ratified lore fragments from the *previous* epoch.
     *      This hash serves as a global seed for new artifact generation in the current epoch.
     * @param targetEpoch The epoch for which the lore influence is being calculated (i.e., new artifact minting epoch).
     * @return A bytes32 hash representing the collective lore influence.
     */
    function _getLoreHashInfluenceForEpoch(uint256 targetEpoch) internal view returns (bytes32) {
        bytes memory combinedLoreData;
        // Collect content from fragments ratified in the *previous* epoch to influence the *current* targetEpoch
        uint256 influencingEpoch = targetEpoch.sub(1);
        for (uint256 i = 0; i < nextLoreFragmentId; i++) {
            LoreFragment storage fragment = loreFragments[i];
            if (fragment.ratified && fragment.submissionEpoch == influencingEpoch) {
                combinedLoreData = abi.encodePacked(combinedLoreData, fragment.content);
            }
        }
        if (bytes(combinedLoreData).length == 0) {
            // Provide a default seed if no lore fragments were ratified in the influencing epoch
            return keccak256(abi.encodePacked("NoLoreInfluence", targetEpoch));
        }
        return keccak256(combinedLoreData);
    }

    /**
     * @dev Placeholder for actual essence reward distribution logic.
     *      In a production system, this would involve a complex calculation of each user's share
     *      based on their activities and EP accumulation within the `epoch` parameter.
     *      The `claimEpochEssenceRewards` function allows users to pull rewards when ready.
     * @param epoch The epoch for which rewards are being processed.
     */
    function _distributeEssenceRewards(uint256 epoch) internal {
        // This function would, in a full implementation, calculate the individual reward amounts for users
        // for the given `epoch` based on their participation/EP during that specific epoch.
        // For the scope of this request, the total epoch rewards are minted at `updateEpochRewards`,
        // and users claim them based on their overall EP in `claimEpochEssenceRewards`.
        // This acts as a marker that rewards for `epoch` are now available in the pool.
    }
}
```