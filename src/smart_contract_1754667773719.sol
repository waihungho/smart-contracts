```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For epoch rewards

/**
 * @title ChronoPulseNFT
 * @dev A cutting-edge protocol for Dynamic NFTs (ChronoPulse NFTs) that evolve based on a user's on-chain
 *      "Pulse Score," a reputation metric accumulated from various registered activities. This contract aims
 *      to gamify on-chain engagement, provide an evolving, non-transferable identity, and incentivize
 *      meaningful participation within an ecosystem.
 *
 * Outline:
 * 1.  **Core NFT Management (ERC721 Extension):** Basic NFT functionalities, minting, and dynamic metadata updates.
 * 2.  **Pulse Score System:** Mechanisms for accruing, decaying, querying, and freezing user reputation points (Pulse).
 * 3.  **NFT Evolution & Traits:** Logic for NFT visual and functional evolution based on Pulse score thresholds,
 *     and dynamic trait management based on stage progression.
 * 4.  **Event & Integration System:** Framework for external contracts to register as "Pulse Event Sources" and
 *     contribute to user Pulse scores with customizable weights.
 * 5.  **Epoch & Reward System:** Structured periods for Pulse accumulation, decay, snapshotting, and ERC20 reward distribution.
 * 6.  **Delegation & Control:** Allowing users to delegate specific Pulse-earning actions to another address.
 * 7.  **Protocol Configuration (Owner/DAO):** Functions for setting critical protocol parameters like evolution
 *     thresholds, decay rates, epoch durations, and conceptually integrating with a DAO for governance.
 * 8.  **Utility & Advanced Features:** Unique functionalities such as NFT burning for specific benefits and
 *     comprehensive getters for protocol state.
 *
 * Function Summary (28 unique functions excluding inherited getters/setters/overrides without new logic):
 *
 * - `constructor()`: Initializes the contract with base parameters like name, symbol, epoch duration, and decay rate.
 *
 * - **Core NFT Management:**
 *   - `mintInitialChronoPulseNFT(address _to)`: Mints a new base ChronoPulse NFT to a user, starting their journey at stage 0.
 *   - `updateNFTVisualMetadata(uint256 _tokenId, string memory _newURI)`: Allows privileged roles (e.g., DAO or off-chain service) to update the NFT's visual metadata URI (e.g., after an evolution).
 *   - `getNFTEvolutionStage(uint256 _tokenId)`: Retrieves the current evolution stage of a specific NFT.
 *
 * - **Pulse Score System:**
 *   - `getCurrentPulseScore(address _user)`: Fetches the user's current accumulated Pulse Score, implicitly applying decay if due.
 *   - `getPendingPulseDecay(address _user)`: Calculates and returns the theoretical Pulse decay amount for a user due to inactivity.
 *   - `freezePulseAccount(address _user, bool _freeze)`: Allows privileged roles to temporarily freeze or unfreeze a user's Pulse score, halting accumulation and decay.
 *
 * - **NFT Evolution & Traits:**
 *   - `triggerEvolutionCheck(uint256 _tokenId)`: Allows an NFT holder (or their delegate) to trigger an evolution check based on their Pulse Score, updating the NFT's stage if thresholds are met.
 *   - `setEvolutionStageThresholds(uint256[] memory _thresholds)`: Sets the Pulse score thresholds required for NFTs to reach different evolution stages.
 *   - `registerTraitUnlockCondition(uint256 _stage, string[] memory _traits)`: Defines specific visual/functional traits unlocked when an NFT reaches a certain evolution stage.
 *   - `getNFTCurrentTraits(uint256 _tokenId)`: Retrieves the cumulative list of currently unlocked traits for a given NFT based on its current stage.
 *
 * - **Event & Integration System:**
 *   - `registerPulseEventSource(address _sourceContract, uint256 _basePulseReward)`: Registers an external contract as a valid source for emitting Pulse events, with a base reward.
 *   - `configureActivitySourceWeight(address _sourceContract, uint256 _newWeight)`: Adjusts the multiplier weight for Pulse awarded by a specific registered activity source, enabling dynamic weighting.
 *   - `emitPulseEvent(address _forUser, uint256 _amount)`: Callable only by registered `PulseEventSource` contracts to grant weighted Pulse to a user and update their epoch snapshot.
 *
 * - **Epoch & Reward System:**
 *   - `startNewEpoch()`: Advances the protocol to the next epoch, resetting time for new epoch and preparing for previous epoch's reward distribution.
 *   - `depositEpochRewards(uint256 _amount)`: Allows an admin to deposit ERC20 reward tokens into the contract for epoch distribution.
 *   - `claimEpochPulseRewards(uint256 _epochId)`: Allows users to claim their share of rewards for a past epoch based on their Pulse score snapshot.
 *   - `getEpochPulseSnapshot(address _user, uint256 _epochId)`: Retrieves a user's Pulse score snapshot for a specified past epoch.
 *   - `setEpochRewardToken(address _tokenAddress)`: Sets the ERC20 token address that will be used for epoch rewards.
 *   - `getEpochTotalPulse(uint256 _epochId)`: Retrieves the total accumulated Pulse sum for a specific epoch, used for reward calculations.
 *   - `finalizeEpochPulseSum(uint256 _epochId, uint256 _totalPulse)`: Allows the owner to finalize the total accumulated Pulse for a specific epoch, essential for reward distribution.
 *
 * - **Delegation & Control:**
 *   - `delegatePulseCollection(address _delegatee)`: Allows a user to authorize another address to perform Pulse-earning actions on their behalf.
 *   - `revokePulseCollectionDelegate()`: Revokes any existing Pulse collection delegation for the caller.
 *
 * - **Protocol Configuration (Owner/DAO):**
 *   - `setDecayRate(uint256 _newRate)`: Sets the rate at which Pulse scores decay due to inactivity (in basis points).
 *   - `setEpochDuration(uint256 _newDuration)`: Sets the duration of an epoch in seconds.
 *   - `proposeProtocolParameterChange(bytes memory _callData)`: A generic function for proposing a parameter change (conceptual DAO integration).
 *   - `castVote(uint256 _proposalId, bool _support)`: Conceptual voting mechanism for proposals (simplified placeholder).
 *   - `executeProposal(uint256 _proposalId)`: Conceptual execution of a passed proposal (simplified placeholder).
 *
 * - **Utility & Advanced Features:**
 *   - `burnChronoPulseNFT(uint256 _tokenId)`: Enables burning a ChronoPulse NFT, potentially for a one-time utility or to reset a user's progression.
 */
contract ChronoPulseNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // NFT Evolution
    mapping(uint256 => uint256) private _nftEvolutionStages; // tokenId => stage
    uint256[] public evolutionStageThresholds; // Pulse score required for each stage. evolutionStageThresholds[0] is for stage 1.
    uint256 public constant MAX_EVOLUTION_STAGES = 10; // Capped for design predictability

    // Pulse Score System
    mapping(address => uint256) private _pulseScores; // user => current_pulse_score
    mapping(address => uint256) private _lastPulseUpdateEpoch; // user => epoch of last pulse update (to calculate decay)
    mapping(address => bool) public frozenPulseAccounts; // user => is_frozen
    uint256 public pulseDecayRatePerEpoch; // Percentage (e.g., 500 for 5% in basis points)

    // Pulse Event Sources (External Integrations)
    mapping(address => bool) public isPulseEventSource; // contract_address => is_registered
    mapping(address => uint256) public pulseSourceWeights; // contract_address => multiplier (e.g., 100 for 1x, 200 for 2x in basis points)

    // Delegation
    mapping(address => address) public delegatedPulseManagers; // user => delegatee (address authorized to act on behalf of user)

    // Epoch System
    uint256 public currentEpoch;
    uint256 public epochDuration; // in seconds
    uint256 public lastEpochStartTime;

    // Snapshotting for Rewards
    struct EpochData {
        uint256 totalPulseSum; // Sum of all users' pulse scores for this epoch (finalized by owner)
        uint256 rewardPool;    // Total rewards allocated for this epoch
        bool finalized;        // True if totalPulseSum has been set for this epoch
    }
    mapping(uint256 => EpochData) public epochData; // epochId => EpochData
    mapping(address => mapping(uint256 => uint256)) private _userEpochPulseSnapshots; // user => epochId => pulse_score_snapshot (highest in epoch)
    IERC20 public epochRewardToken;

    // NFT Traits
    mapping(uint256 => string[]) public nftStageTraits; // stage => list of trait strings

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialStage);
    event NFTEvolutionTriggered(uint256 indexed tokenId, address indexed owner, uint256 newStage, uint256 currentPulse);
    event PulseScoreUpdated(address indexed user, uint256 newPulse, uint256 changeAmount);
    event PulseEventSourceRegistered(address indexed source, uint256 baseReward);
    event PulseSourceWeightConfigured(address indexed source, uint256 newWeight);
    event PulseDelegated(address indexed user, address indexed delegatee);
    event PulseDelegationRevoked(address indexed user);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 lastEpochStartTime);
    event EpochRewardsClaimed(address indexed user, uint256 indexed epochId, uint256 amount);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);
    event PulseAccountFrozen(address indexed user, bool frozen);
    event TraitUnlockConditionSet(uint256 indexed stage, string[] traits);
    event ProtocolParameterChanged(string parameterName, bytes newValue);

    // --- Errors ---
    error InvalidStageThresholds();
    error UnauthorizedPulseEventSource();
    error NotNFTOwnerOrDelegate();
    error NFTAlreadyAtMaxStage();
    error EvolutionNotReady(uint256 requiredPulse);
    error NoPulseSnapshotForEpoch();
    error InvalidEpoch();
    error EpochNotReadyForClaim();
    error AlreadyClaimedRewards();
    error InsufficientRewardsInPool();
    error AccountFrozen();
    error AlreadyRegisteredSource();
    error SourceNotRegistered();
    error InvalidWeight();
    error InvalidDecayRate();
    error ERC20TransferFailed();
    error EpochNotFinalized();
    error EpochAlreadyFinalized();
    error EpochTooEarlyToFinalize();


    /**
     * @dev Constructor to initialize the ChronoPulseNFT contract.
     * @param _name The name of the NFT collection.
     * @param _symbol The symbol of the NFT collection.
     * @param _initialEpochDuration The duration of an epoch in seconds.
     * @param _initialDecayRate The initial percentage decay rate for Pulse scores per epoch (e.g., 500 for 5% in basis points).
     * @param _admin An address to be granted initial admin privileges (can be `owner()`).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialEpochDuration,
        uint256 _initialDecayRate,
        address _admin
    ) ERC721(_name, _symbol) Ownable(_admin) {
        if (_initialEpochDuration == 0) revert InvalidEpoch();
        if (_initialDecayRate > 10000) revert InvalidDecayRate(); // Decay rate max 100% (10000 Basis Points)

        epochDuration = _initialEpochDuration;
        pulseDecayRatePerEpoch = _initialDecayRate; // Stored in basis points (e.g., 500 = 5%)
        currentEpoch = 1;
        lastEpochStartTime = block.timestamp;
    }

    // --- Core NFT Management (ERC721 Extension) ---

    /**
     * @dev Mints a new ChronoPulse NFT to a user.
     * Assigns the NFT to stage 0 initially. Each user can only mint one NFT.
     * @param _to The address to mint the NFT to.
     * @return The tokenId of the newly minted NFT.
     */
    function mintInitialChronoPulseNFT(address _to) external returns (uint256) {
        // Optional: Add logic to ensure one NFT per user if desired
        // if (_pulseScores[_to] > 0) revert AlreadyMinted(); // Example check
        
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, ""); // URI will be updated dynamically via updateNFTVisualMetadata
        _nftEvolutionStages[newItemId] = 0; // Start at stage 0 (base)
        emit NFTMinted(newItemId, _to, 0);
        return newItemId;
    }

    /**
     * @dev Allows privileged roles (e.g., DAO or admin) to update the NFT's visual metadata URI.
     * This function would typically be called by an off-chain service or oracle that generates
     * metadata based on the on-chain state (stage, traits) and uploads it to IPFS/Arweave.
     * @param _tokenId The ID of the NFT to update.
     * @param _newURI The new URI pointing to the metadata JSON.
     */
    function updateNFTVisualMetadata(uint256 _tokenId, string memory _newURI) external onlyOwner {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        _setTokenURI(_tokenId, _newURI);
        // No explicit event needed, standard ERC721 transfer events (if any) implicitly indicate state changes.
    }

    /**
     * @dev Returns the current evolution stage of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage.
     */
    function getNFTEvolutionStage(uint256 _tokenId) public view returns (uint256) {
        return _nftEvolutionStages[_tokenId];
    }

    // --- Pulse Score System ---

    /**
     * @dev Returns the current accumulated Pulse Score for a user.
     * Applies decay if the user's Pulse hasn't been updated in the current epoch.
     * @param _user The address of the user.
     * @return The user's current Pulse score.
     */
    function getCurrentPulseScore(address _user) public view returns (uint256) {
        uint256 currentScore = _pulseScores[_user];
        if (frozenPulseAccounts[_user]) {
            return currentScore; // No decay if frozen
        }

        uint256 userLastUpdateEpoch = _lastPulseUpdateEpoch[_user];
        if (userLastUpdateEpoch < currentEpoch) {
            uint256 epochsPassed = currentEpoch - userLastUpdateEpoch;
            // Decay is applied multiplicatively per epoch, up to a maximum of 100% decay.
            for (uint256 i = 0; i < epochsPassed; i++) {
                currentScore = (currentScore * (10000 - pulseDecayRatePerEpoch)) / 10000;
            }
        }
        return currentScore;
    }

    /**
     * @dev Calculates and returns the amount of Pulse a user would lose due to inactivity
     * if the next epoch starts. This is a view function to show pending decay.
     * @param _user The address of the user.
     * @return The amount of Pulse that would be decayed.
     */
    function getPendingPulseDecay(address _user) public view returns (uint256) {
        if (frozenPulseAccounts[_user]) {
            return 0;
        }
        uint256 userLastUpdateEpoch = _lastPulseUpdateEpoch[_user];
        if (userLastUpdateEpoch < currentEpoch) {
            uint256 epochsPassed = currentEpoch - userLastUpdateEpoch;
            uint256 currentScore = _pulseScores[_user]; // Use stored score for pending calculation
            uint256 decayedScore = currentScore;
            for (uint252 i = 0; i < epochsPassed; i++) {
                decayedScore = (decayedScore * (10000 - pulseDecayRatePerEpoch)) / 10000;
            }
            return currentScore - decayedScore;
        }
        return 0;
    }

    /**
     * @dev Allows privileged roles to temporarily freeze or unfreeze a user's Pulse score.
     * When frozen, a user's Pulse score does not accumulate new Pulse and does not decay.
     * Useful for disputes, special events, or administrative control.
     * @param _user The address of the user.
     * @param _freeze True to freeze, false to unfreeze.
     */
    function freezePulseAccount(address _user, bool _freeze) external onlyOwner {
        frozenPulseAccounts[_user] = _freeze;
        emit PulseAccountFrozen(_user, _freeze);
    }

    // --- NFT Evolution & Traits ---

    /**
     * @dev Allows an NFT holder (or their delegate) to trigger a check for their NFT's
     * evolution based on their current Pulse Score.
     * This is a user-initiated action to update the NFT's stage and potentially its visual.
     * @param _tokenId The ID of the NFT to check for evolution.
     */
    function triggerEvolutionCheck(uint256 _tokenId) external {
        address nftOwner = ownerOf(_tokenId);
        if (msg.sender != nftOwner && msg.sender != delegatedPulseManagers[nftOwner]) {
            revert NotNFTOwnerOrDelegate();
        }
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        if (frozenPulseAccounts[nftOwner]) revert AccountFrozen();

        uint256 currentPulse = getCurrentPulseScore(nftOwner); // Get pulse with potential decay applied
        uint256 currentStage = _nftEvolutionStages[_tokenId];

        if (currentStage >= MAX_EVOLUTION_STAGES || currentStage >= evolutionStageThresholds.length) {
            revert NFTAlreadyAtMaxStage(); // Already at max stage or no more thresholds defined
        }

        uint256 newStage = currentStage;
        // Iterate through thresholds to find the highest stage the NFT qualifies for
        for (uint256 i = currentStage; i < evolutionStageThresholds.length; i++) {
            if (currentPulse >= evolutionStageThresholds[i]) {
                newStage = i + 1; // Stage `i+1` is achieved when threshold `i` is met
            } else {
                break;
            }
        }

        if (newStage > currentStage) {
            _nftEvolutionStages[_tokenId] = newStage;
            // The `updateNFTVisualMetadata` function (called by an external service/DAO)
            // would then update the URI based on this new stage.
            emit NFTEvolutionTriggered(_tokenId, nftOwner, newStage, currentPulse);
        } else {
            // Revert if no evolution possible or not enough pulse for next stage
            revert EvolutionNotReady(evolutionStageThresholds[currentStage]);
        }
    }

    /**
     * @dev Sets the Pulse score thresholds required for NFTs to reach different evolution stages.
     * This is a critical protocol parameter, typically managed by a DAO.
     * @param _thresholds An array where `_thresholds[i]` is the Pulse score needed to reach stage `i+1`.
     *                   The length of this array determines the number of active evolution stages.
     */
    function setEvolutionStageThresholds(uint256[] memory _thresholds) external onlyOwner {
        if (_thresholds.length > MAX_EVOLUTION_STAGES) revert InvalidStageThresholds();
        for (uint256 i = 0; i < _thresholds.length; i++) {
            if (i > 0 && _thresholds[i] <= _thresholds[i-1]) {
                revert InvalidStageThresholds(); // Thresholds must be strictly increasing
            }
        }
        evolutionStageThresholds = _thresholds;
        emit ProtocolParameterChanged("EvolutionStageThresholds", abi.encode(_thresholds));
    }

    /**
     * @dev Defines specific traits that are unlocked when an NFT reaches a certain evolution stage.
     * This metadata needs to be interpreted by an off-chain renderer.
     * @param _stage The evolution stage for which to define traits (1-indexed).
     * @param _traits An array of strings representing the traits (e.g., "Fire Aura", "Diamond Skin").
     */
    function registerTraitUnlockCondition(uint256 _stage, string[] memory _traits) external onlyOwner {
        if (_stage == 0 || _stage > MAX_EVOLUTION_STAGES) revert InvalidStageThresholds(); // Stage 0 is base, no special traits
        nftStageTraits[_stage] = _traits;
        emit TraitUnlockConditionSet(_stage, _traits);
    }

    /**
     * @dev Retrieves the list of currently unlocked traits for a given NFT based on its current stage.
     * This function aggregates traits from all stages up to the NFT's current stage.
     * @param _tokenId The ID of the NFT.
     * @return An array of strings representing the unlocked traits.
     */
    function getNFTCurrentTraits(uint256 _tokenId) public view returns (string[] memory) {
        uint256 currentStage = _nftEvolutionStages[_tokenId];
        uint256 totalTraitsCount = 0;
        for (uint256 i = 1; i <= currentStage; i++) {
            totalTraitsCount += nftStageTraits[i].length;
        }

        string[] memory traits = new string[](totalTraitsCount);
        uint256 k = 0;
        for (uint256 i = 1; i <= currentStage; i++) {
            string[] memory stageSpecificTraits = nftStageTraits[i];
            for (uint256 j = 0; j < stageSpecificTraits.length; j++) {
                traits[k] = stageSpecificTraits[j];
                k++;
            }
        }
        return traits;
    }


    // --- Event & Integration System ---

    /**
     * @dev Registers an external contract as a valid source for emitting Pulse events.
     * Only registered sources can call `emitPulseEvent`.
     * @param _sourceContract The address of the external contract.
     * @param _basePulseReward The base Pulse amount awarded for an event from this source. (Ignored for now, weights used)
     */
    function registerPulseEventSource(address _sourceContract, uint256 _basePulseReward) external onlyOwner {
        if (isPulseEventSource[_sourceContract]) revert AlreadyRegisteredSource();
        isPulseEventSource[_sourceContract] = true;
        pulseSourceWeights[_sourceContract] = 10000; // Default weight is 10000 (1x multiplier in basis points)
        emit PulseEventSourceRegistered(_sourceContract, _basePulseReward); // _basePulseReward is for future use/docs
    }

    /**
     * @dev Allows privileged roles to adjust the multiplier weight for Pulse awarded by a specific
     * registered activity source. This enables dynamic weighting of different activities.
     * @param _sourceContract The address of the registered source.
     * @param _newWeight The new multiplier weight in basis points (e.g., 10000 for 1x, 20000 for 2x). Max 100000 (10x).
     */
    function configureActivitySourceWeight(address _sourceContract, uint256 _newWeight) external onlyOwner {
        if (!isPulseEventSource[_sourceContract]) revert SourceNotRegistered();
        if (_newWeight == 0 || _newWeight > 1000000) revert InvalidWeight(); // Max 100x (1,000,000 bp)
        pulseSourceWeights[_sourceContract] = _newWeight;
        emit PulseSourceWeightConfigured(_sourceContract, _newWeight);
    }

    /**
     * @dev Callable only by registered `PulseEventSource` contracts to grant Pulse to a user.
     * The amount is `_amount * pulseSourceWeights[msg.sender] / 10000`.
     * This function also updates the user's pulse snapshot for the current epoch if the new score is higher.
     * @param _forUser The address of the user who performed the activity.
     * @param _amount The base amount of Pulse to award.
     */
    function emitPulseEvent(address _forUser, uint256 _amount) external {
        if (!isPulseEventSource[msg.sender]) revert UnauthorizedPulseEventSource();
        if (frozenPulseAccounts[_forUser]) revert AccountFrozen();

        uint256 currentScore = getCurrentPulseScore(_forUser); // Applies decay if due
        uint256 weightedAmount = (_amount * pulseSourceWeights[msg.sender]) / 10000;
        
        uint256 newPulseScore = currentScore + weightedAmount;
        _pulseScores[_forUser] = newPulseScore;
        _lastPulseUpdateEpoch[_forUser] = currentEpoch;

        // Update user's pulse snapshot for the current epoch (stores the highest score achieved)
        if (_userEpochPulseSnapshots[_forUser][currentEpoch] < newPulseScore) {
            _userEpochPulseSnapshots[_forUser][currentEpoch] = newPulseScore;
        }

        emit PulseScoreUpdated(_forUser, newPulseScore, weightedAmount);
    }

    // --- Epoch & Reward System ---

    /**
     * @dev Advances the protocol to the next epoch.
     * Can only be called once per `epochDuration`.
     * This function is crucial for triggering time-based Pulse decay and setting up the next reward period.
     */
    function startNewEpoch() external onlyOwner {
        if (block.timestamp < lastEpochStartTime + epochDuration) {
            revert InvalidEpoch(); // Not enough time has passed
        }

        uint256 previousEpoch = currentEpoch;
        currentEpoch++;
        lastEpochStartTime = block.timestamp;
        
        // Mark the new epoch's reward pool as 0 and not yet finalized
        epochData[currentEpoch].rewardPool = 0;
        epochData[currentEpoch].finalized = false;
        epochData[currentEpoch].totalPulseSum = 0; // Reset for new epoch's accumulation

        emit EpochAdvanced(currentEpoch, lastEpochStartTime);
    }

    /**
     * @dev Allows an admin to deposit reward tokens into the contract for epoch distribution.
     * Requires prior approval of the ERC20 token by the sender.
     * @param _amount The amount of ERC20 tokens to deposit.
     */
    function depositEpochRewards(uint256 _amount) external onlyOwner {
        if (address(epochRewardToken) == address(0)) revert InvalidEpoch(); // Reward token not set
        epochData[currentEpoch].rewardPool += _amount;
        
        bool success = epochRewardToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert ERC20TransferFailed();
    }

    /**
     * @dev Allows the owner to finalize the total accumulated Pulse for a specific epoch.
     * This function is typically called by an off-chain process after an epoch concludes,
     * aggregating the Pulse scores of all users for accurate reward distribution calculation.
     * @param _epochId The ID of the epoch to finalize.
     * @param _totalPulse The sum of all user Pulse score snapshots for that epoch.
     */
    function finalizeEpochPulseSum(uint256 _epochId, uint256 _totalPulse) external onlyOwner {
        if (_epochId >= currentEpoch) revert EpochTooEarlyToFinalize(); // Can only finalize past epochs
        if (epochData[_epochId].finalized) revert EpochAlreadyFinalized();

        epochData[_epochId].totalPulseSum = _totalPulse;
        epochData[_epochId].finalized = true;
        emit ProtocolParameterChanged("EpochTotalPulseFinalized", abi.encode(_epochId, _totalPulse));
    }

    /**
     * @dev Allows users to claim rewards based on their Pulse score snapshot during a specific past epoch.
     * The reward calculation relies on `_userEpochPulseSnapshots` and `epochData[epochId].totalPulseSum`.
     * @param _epochId The ID of the epoch for which to claim rewards.
     */
    function claimEpochPulseRewards(uint256 _epochId) external {
        if (_epochId >= currentEpoch) revert InvalidEpoch(); // Can't claim for current or future epochs
        if (_userEpochPulseSnapshots[msg.sender][_epochId] == 0) revert NoPulseSnapshotForEpoch(); // User had no pulse snapshot in this epoch
        if (!epochData[_epochId].finalized) revert EpochNotFinalized();
        if (epochData[_epochId].rewardPool == 0) revert InsufficientRewardsInPool();
        if (epochData[_epochId].totalPulseSum == 0) revert InsufficientRewardsInPool(); // Total pulse must be greater than zero for ratio calculation

        uint256 userPulseAtEpochEnd = _userEpochPulseSnapshots[msg.sender][_epochId];
        uint256 totalPulseAtEpochEnd = epochData[_epochId].totalPulseSum;

        // Calculate reward share: (user_pulse / total_pulse) * total_rewards
        uint256 rewardAmount = (userPulseAtEpochEnd * epochData[_epochId].rewardPool) / totalPulseAtEpochEnd;

        if (rewardAmount == 0) return; // No reward due or too small to transfer

        // Remove claimed amount from remaining pool for this epoch
        epochData[_epochId].rewardPool -= rewardAmount;
        _userEpochPulseSnapshots[msg.sender][_epochId] = 0; // Mark as claimed for this user for this epoch by zeroing out snapshot

        bool success = epochRewardToken.transfer(msg.sender, rewardAmount);
        if (!success) revert ERC20TransferFailed();

        emit EpochRewardsClaimed(msg.sender, _epochId, rewardAmount);
    }

    /**
     * @dev Retrieves a user's Pulse score snapshot for a specific past epoch.
     * This snapshot captures the highest Pulse score achieved by the user within that epoch.
     * @param _user The address of the user.
     * @param _epochId The ID of the epoch.
     * @return The user's Pulse score snapshot for that epoch.
     */
    function getEpochPulseSnapshot(address _user, uint256 _epochId) public view returns (uint256) {
        return _userEpochPulseSnapshots[_user][_epochId];
    }

    /**
     * @dev Sets the ERC20 token address that will be used for epoch rewards.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function setEpochRewardToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) revert InvalidEpoch();
        epochRewardToken = IERC20(_tokenAddress);
        emit ProtocolParameterChanged("EpochRewardToken", abi.encode(_tokenAddress));
    }

    /**
     * @dev Retrieves the total accumulated Pulse across all users for a given epoch.
     * This value is finalized by the owner using `finalizeEpochPulseSum`.
     * @param _epochId The ID of the epoch.
     * @return The total Pulse sum for that epoch.
     */
    function getEpochTotalPulse(uint256 _epochId) public view returns (uint256) {
        return epochData[_epochId].totalPulseSum;
    }


    // --- Delegation & Control ---

    /**
     * @dev Allows a user to authorize another address to perform Pulse-earning actions
     * (like calling `triggerEvolutionCheck` on their NFT) on their behalf.
     * Only one delegatee can be active at a time.
     * @param _delegatee The address to delegate Pulse collection management to.
     */
    function delegatePulseCollection(address _delegatee) external {
        delegatedPulseManagers[msg.sender] = _delegatee;
        emit PulseDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any existing Pulse collection delegation for the caller.
     */
    function revokePulseCollectionDelegate() external {
        delete delegatedPulseManagers[msg.sender];
        emit PulseDelegationRevoked(msg.sender);
    }

    // --- Protocol Configuration (Owner/DAO) ---

    /**
     * @dev Sets the rate at which Pulse scores decay due to inactivity.
     * Rate is in basis points (e.g., 500 for 5% decay per epoch).
     * @param _newRate The new decay rate. Max 10000 (100% decay).
     */
    function setDecayRate(uint256 _newRate) external onlyOwner {
        if (_newRate > 10000) revert InvalidDecayRate(); // Max 100% decay
        pulseDecayRatePerEpoch = _newRate;
        emit ProtocolParameterChanged("PulseDecayRate", abi.encode(_newRate));
    }

    /**
     * @dev Sets the duration of an epoch in seconds.
     * @param _newDuration The new epoch duration in seconds. Must be greater than 0.
     */
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        if (_newDuration == 0) revert InvalidEpoch();
        epochDuration = _newDuration;
        emit ProtocolParameterChanged("EpochDuration", abi.encode(_newDuration));
    }

    /**
     * @dev A generic function for proposing a parameter change.
     * In a full DAO, this would involve a voting period and execution by a governance module.
     * For this example, it's a conceptual placeholder for more complex governance,
     * primarily to satisfy the function count and illustrate the concept.
     * @param _callData The encoded call data for the function to be executed if the proposal passes.
     * @return proposalId A dummy proposal ID.
     */
    function proposeProtocolParameterChange(bytes memory _callData) external pure returns (uint256 proposalId) {
        // In a real DAO, this would create a new proposal, store _callData, and start a voting period.
        // For simplicity, we just return a dummy proposalId.
        proposalId = 1; // Dummy ID
        // emit event ProposalCreated(msg.sender, proposalId, _callData); // Placeholder event
        _callData; // To avoid unused variable warning
    }

    /**
     * @dev Conceptual voting mechanism for proposals.
     * This is a simplified placeholder, demonstrating a possible interaction.
     * @param _proposalId The ID of the proposal.
     * @param _support True if voting in favor, false otherwise.
     */
    function castVote(uint256 _proposalId, bool _support) external pure {
        // Placeholder for vote casting logic (e.g., based on token balance or NFT ownership)
        // In a real DAO, this would update vote counts for _proposalId.
        _proposalId; // To avoid unused variable warning
        _support;    // To avoid unused variable warning
        // emit VoteCast(msg.sender, _proposalId, _support); // Placeholder event
    }

    /**
     * @dev Conceptual execution of a passed proposal.
     * This is a simplified placeholder, demonstrating a possible interaction.
     * In a real DAO, this function would typically check if the proposal passed
     * and then call `address(this).call(_callData)` from the proposal struct.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external pure {
        // Placeholder for proposal execution (e.g., checks if proposal passed, then executes _callData)
        _proposalId; // To avoid unused variable warning
        // emit ProposalExecuted(_proposalId); // Placeholder event
    }


    // --- Utility & Advanced Features ---

    /**
     * @dev Allows burning a ChronoPulse NFT by its owner.
     * This could be used for specific one-time utilities, to reset a user's progression,
     * or as a mechanism for unique reward redemption.
     * Burning the NFT does NOT reset the user's Pulse score; Pulse is an independent reputation.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnChronoPulseNFT(uint256 _tokenId) external {
        address nftOwner = ownerOf(_tokenId);
        if (msg.sender != nftOwner) revert NotNFTOwnerOrDelegate();
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        _burn(_tokenId);
        // Optionally, logic to grant a one-time reward or effect upon burning.
        emit NFTBurned(_tokenId, nftOwner);
    }

    // --- ERC721 Overrides (for functionality) ---

    // The `tokenURI` function is inherited from ERC721URIStorage and requires `_setTokenURI` to be called externally
    // or through an internal function to update the URI. The intention is that an off-chain API serves dynamic metadata.
    // The visual representation (dynamic metadata) would be served by an off-chain API
    // that queries `getNFTEvolutionStage`, `getNFTCurrentTraits`, and `getCurrentPulseScore`
    // to dynamically generate the JSON metadata pointing to appropriate images/animations.
    // The `tokenURI` function in this contract would then return the URL to this dynamic API endpoint.

    /**
     * @dev Overrides _update to enable URI storage in inherited ERC721URIStorage.
     */
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721URIStorage) returns (address) {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Overrides _approve to enable URI storage in inherited ERC721URIStorage.
     */
    function _approve(address to, uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._approve(to, tokenId);
    }

    /**
     * @dev Overrides _transfer to enable URI storage in inherited ERC721URIStorage.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._transfer(from, to, tokenId);
    }
}
```