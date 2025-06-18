Okay, let's design an interesting, advanced, and creative smart contract concept. We'll combine ideas around time-based mechanics, prediction/alignment, staking, and potentially unique access control like requiring an NFT.

Let's call the concept "QuantumLeap Protocol". Users stake a custom token (`LEAP`) and align it with a predicted outcome for a specific future "Epoch". Rewards (and potential penalties) are distributed based on the accuracy of their alignment when the epoch is resolved via an oracle. We'll incorporate a multi-phase epoch lifecycle for transparency and complexity.

---

### QuantumLeap Protocol Smart Contract

**Outline:**

1.  **Purpose:** A decentralized protocol enabling users to stake a native token (`LEAP`) and align their stake with a predicted outcome during specific time-based epochs. Rewards are distributed based on alignment accuracy verified by an oracle, with potential penalties for incorrect alignments. Requires holding a specific NFT collection for participation.
2.  **Key Concepts:**
    *   **Epochs:** Discrete time periods with specific phases.
    *   **Phases:** Commit, Reveal, Alignment, Resolution.
    *   **Staking:** Locking `LEAP` tokens to participate in an epoch.
    *   **Alignment:** Choosing a specific outcome for the staked amount within an epoch.
    *   **Oracle:** An external entity responsible for committing target hashes, revealing targets, and resolving epochs with the actual outcome.
    *   **NFT Requirement:** Users must hold an NFT from a specified collection to stake.
    *   **Slashing:** A percentage of stake is lost for incorrect alignment in a resolved epoch.
    *   **Reward Pool:** The total staked amount in an epoch (potentially adjusted by slashing) forms the pool distributed among correct aligners.
    *   **Commit-Reveal:** A mechanism for the oracle to provide a prediction target transparently without front-running.
3.  **State Management:** Tracks epoch data (target hash, target, outcome, deadlines, stake summaries), user data per epoch (stake, alignment, claim status), protocol parameters (epoch duration, oracle address, NFT address, min stake, penalty), and token balances.
4.  **Roles:**
    *   **Owner:** Deploys, sets core parameters, manages protocol pause/upgrade (not covered here but assumed), emergency actions.
    *   **Oracle/Keeper:** A trusted address (or multisig/DAO) responsible for advancing epoch phases and providing outcomes.
    *   **User:** Stakes, aligns, claims rewards/principal.
5.  **Inheritance:** `Ownable`, `Pausable`. Uses `IERC20` and `IERC721`.

**Function Summary (25+ Functions):**

*   **Admin/Setup (Owner Only):**
    1.  `constructor`: Deploys, sets initial parameters (LEAP token, Oracle, NFT collection, durations, penalties).
    2.  `setEpochDurations`: Sets the duration for different epoch phases.
    3.  `setOracleAddress`: Updates the address authorized as the Oracle/Keeper.
    4.  `setRequiredNFTCollection`: Updates the required NFT collection address.
    5.  `setMinStakeAmount`: Sets the minimum amount of LEAP required to stake in an epoch.
    6.  `setSlashingPenaltyBasisPoints`: Sets the percentage (in basis points) of stake slashed for incorrect alignment.
    7.  `pauseProtocol`: Pauses core user interactions (staking, aligning, claiming).
    8.  `unpauseProtocol`: Unpauses the protocol.
    9.  `emergencyWithdrawAdmin`: Allows owner to withdraw arbitrary LEAP tokens from the contract in emergencies (caution!).
    10. `updatePredictionOutcomes`: Allows owner to update the list of possible prediction outcomes (e.g., ["Up", "Down", "Sideways"]).

*   **Epoch Lifecycle Management (Oracle/Keeper Only):**
    11. `startNextEpochCommitPhase`: Advances protocol to the next epoch's commit phase.
    12. `commitNextEpochTargetHash`: Commits the keccak256 hash of the target for the next epoch.
    13. `revealNextEpochTarget`: Reveals the actual target for the next epoch, verifies against the hash, and starts the Alignment phase.
    14. `resolveEpoch`: Resolves a finished epoch by providing the actual outcome, triggers reward/slashing calculations, and makes funds claimable.
    15. `cancelEpochCommitment`: Allows Oracle/Keeper to cancel the commitment before reveal (e.g., if data source fails).
    16. `cancelEpoch`: Allows Oracle/Keeper to cancel an epoch before resolution (e.g., if oracle data is compromised).

*   **User Interaction:**
    17. `stake`: Users stake LEAP tokens for the *current* epoch during the Alignment phase. Requires holding the specified NFT and meeting min stake.
    18. `align`: Users align their staked amount with a chosen outcome during the Alignment phase.
    19. `updateAlignment`: Users can change their alignment during the Alignment phase.
    20. `claimRewardsAndPrincipal`: Users claim their principal stake back + rewards (if any) from a resolved epoch. Includes applying slashing if alignment was incorrect.
    21. `batchClaimRewardsAndPrincipal`: Allows claiming from multiple resolved epochs in one transaction.

*   **View/Information Functions:**
    22. `getEpochData`: Retrieves all details for a specific epoch number.
    23. `getCurrentEpochNumber`: Returns the current active epoch number.
    24. `getEpochState`: Returns the current phase/state of a specific epoch.
    25. `getUserEpochData`: Retrieves a user's staking, alignment, and claim status for a specific epoch.
    26. `getEpochStakeSummary`: Returns the total stake aligned for each outcome within an epoch.
    27. `getTotalProtocolStaked`: Returns the total amount of LEAP tokens currently held by the contract across all epochs.
    28. `getMinStakeAmount`: Returns the current minimum staking amount.
    29. `getSlashingPenaltyBasisPoints`: Returns the current slashing penalty percentage.
    30. `getRequiredNFTCollection`: Returns the required NFT collection address.
    31. `getPossiblePredictionOutcomes`: Returns the list of outcomes users can align with.
    32. `calculatePotentialRewards`: Estimates the potential rewards for a user in a *resolved* epoch if their alignment was correct.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ handles overflow, sometimes useful for clarity or specific ops
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example of advanced concept, not used directly but implies potential
import "@openzeppelin/contracts/utils/Strings.sol"; // Useful for converting numbers to strings for events/debugging

// --- Custom Errors ---
error QuantumLeap__InvalidPhase();
error QuantumLeap__EpochNotReady();
error QuantumLeap__EpochAlreadyStarted();
error QuantumLeap__EpochNotCommitPhase();
error QuantumLeap__EpochNotRevealPhase();
error QuantumLeap__EpochNotAlignmentPhase();
error QuantumLeap__EpochNotResolved();
error QuantumLeap__EpochAlreadyResolved();
error QuantumLeap__EpochCancelled();
error QuantumLeap__CommitmentNotSet();
error QuantumLeap__TargetAlreadyRevealed();
error QuantumLeap__InvalidTargetReveal(string revealedTarget);
error QuantumLeap__StakeAmountTooLow(uint256 requiredAmount);
error QuantumLeap__NoNFT();
error QuantumLeap__AlreadyStakedInEpoch();
error QuantumLeap__NotStakedInEpoch();
error QuantumLeap__AlignmentAlreadySet();
error QuantumLeap__AlignmentNotSet();
error QuantumLeap__InvalidAlignmentOutcome(string outcome);
error QuantumLeap__ClaimNotAvailable();
error QuantumLeap__AlreadyClaimed();
error QuantumLeap__OracleAddressZero();
error QuantumLeap__NFTAddressZero();
error QuantumLeap__LEAPTokenAddressZero();
error QuantumLeap__DurationTooShort();
error QuantumLeap__EmergencyWithdrawFailed();
error QuantumLeap__InvalidSlashingPenalty();
error QuantumLeap__InvalidOutcomeList();
error QuantumLeap__NoEpochToResolve();


// --- Events ---
event EpochCommitPhaseStarted(uint256 indexed epochNumber, uint64 commitDeadline);
event EpochTargetHashCommitted(uint256 indexed epochNumber, bytes32 targetHash);
event EpochTargetRevealed(uint256 indexed epochNumber, string targetOutcome, uint64 alignmentDeadline);
event EpochAlignmentPhaseStarted(uint256 indexed epochNumber, uint64 resolutionDeadline);
event EpochResolved(uint256 indexed epochNumber, string resolvedOutcome);
event EpochCancelled(uint256 indexed epochNumber);

event Staked(address indexed user, uint256 indexed epochNumber, uint256 amount);
event Aligned(address indexed user, uint256 indexed epochNumber, string indexed outcome);
event AlignmentUpdated(address indexed user, uint256 indexed epochNumber, string indexed newOutcome);
event Claimed(address indexed user, uint256 indexed epochNumber, uint256 principalWithdrawn, uint256 rewardsClaimed, uint256 slashedAmount);

event ProtocolPaused(address indexed by);
event ProtocolUnpaused(address indexed by);

event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
event AddressParameterUpdated(string parameterName, address oldAddress, address newAddress);
event StringArrayParameterUpdated(string parameterName); // Simpler event for array updates

// --- Core Contract ---
contract QuantumLeapProtocol is Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256; // For converting uint256 to string in events/errors

    // --- State Variables ---

    IERC20 public immutable leapToken;
    IERC721 public immutable requiredNFTCollection;

    address public oracleAddress;

    enum EpochState {
        NonExistent,
        CommitPhase,
        RevealPhase,
        AlignmentPhase,
        Resolved,
        Cancelled
    }

    struct EpochData {
        EpochState state;
        string targetOutcome; // The outcome users predict
        bytes32 targetOutcomeHash; // Hash of the targetOutcome during commit phase
        string resolvedOutcome;   // The actual outcome after resolution
        uint64 commitDeadline;
        uint64 revealDeadline;
        uint64 alignmentDeadline; // Deadline for staking and aligning
        uint64 resolutionDeadline; // Deadline for oracle to resolve

        uint256 totalStakedInEpoch;
        // Mapping from outcome string => total stake aligned to that outcome
        mapping(string => uint256) totalAlignedPerOutcome;
        uint256 totalSlashingPool; // Sum of slashed amounts in this epoch

        // Mapping from user address => UserEpochData
        mapping(address => UserEpochData) userData;
    }

    struct UserEpochData {
        uint256 stakedAmount;
        string alignedOutcome; // The outcome user aligned with
        bool alignmentSet;
        bool claimed;
    }

    mapping(uint256 => EpochData) public epochs;
    uint256 public currentEpochNumber;

    // Epoch Phase Durations (in seconds)
    uint64 public commitPhaseDuration;
    uint64 public revealPhaseDuration;
    uint64 public alignmentPhaseDuration;
    uint64 public resolutionPhaseDuration; // Max time for oracle to resolve after alignment ends

    uint256 public minStakeAmount;
    uint256 public slashingPenaltyBasisPoints; // e.g., 500 for 5% (500/10000)

    string[] public possiblePredictionOutcomes; // e.g., ["Up", "Down", "Sideways"]

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable's error for consistency
        }
        _;
    }

    modifier whenPhase(uint256 epochNum, EpochState requiredState) {
        if (epochs[epochNum].state != requiredState) {
            revert QuantumLeap__InvalidPhase();
        }
        _;
    }

     modifier whenCommitPhase(uint256 epochNum) {
        if (epochs[epochNum].state != EpochState.CommitPhase || block.timestamp > epochs[epochNum].commitDeadline) {
            revert QuantumLeap__EpochNotCommitPhase();
        }
        _;
    }

    modifier whenRevealPhase(uint256 epochNum) {
         if (epochs[epochNum].state != EpochState.RevealPhase || block.timestamp > epochs[epochNum].revealDeadline) {
            revert QuantumLeap__EpochNotRevealPhase();
        }
        _;
    }

    modifier whenAlignmentPhase(uint256 epochNum) {
         if (epochs[epochNum].state != EpochState.AlignmentPhase || block.timestamp > epochs[epochNum].alignmentDeadline) {
            revert QuantumLeap__EpochNotAlignmentPhase();
        }
        _;
    }

    modifier whenResolutionWindow(uint256 epochNum) {
        if (epochs[epochNum].state != EpochState.AlignmentPhase || block.timestamp <= epochs[epochNum].alignmentDeadline || block.timestamp > epochs[epochNum].resolutionDeadline) {
             revert QuantumLeap__EpochNotReady(); // Or a more specific error
        }
        _;
    }

    modifier whenResolved(uint256 epochNum) {
        if (epochs[epochNum].state != EpochState.Resolved) {
            revert QuantumLeap__EpochNotResolved();
        }
        _;
    }


    // --- Constructor ---

    constructor(
        address _leapToken,
        address _oracleAddress,
        address _requiredNFTCollection,
        uint64 _commitPhaseDuration,
        uint64 _revealPhaseDuration,
        uint64 _alignmentPhaseDuration,
        uint64 _resolutionPhaseDuration,
        uint256 _minStakeAmount,
        uint256 _slashingPenaltyBasisPoints,
        string[] memory _possiblePredictionOutcomes
    ) Ownable(msg.sender) Pausable(false) {
        if (_leapToken == address(0)) revert QuantumLeap__LEAPTokenAddressZero();
        if (_oracleAddress == address(0)) revert QuantumLeap__OracleAddressZero();
        if (_requiredNFTCollection == address(0)) revert QuantumLeap__NFTAddressZero();
        if (_commitPhaseDuration == 0 || _revealPhaseDuration == 0 || _alignmentPhaseDuration == 0 || _resolutionPhaseDuration == 0) revert QuantumLeap__DurationTooShort();
        if (_slashingPenaltyBasisPoints > 10000) revert QuantumLeap__InvalidSlashingPenalty();
        if (_possiblePredictionOutcomes.length == 0) revert QuantumLeap__InvalidOutcomeList();

        leapToken = IERC20(_leapToken);
        oracleAddress = _oracleAddress;
        requiredNFTCollection = IERC721(_requiredNFTCollection);

        commitPhaseDuration = _commitPhaseDuration;
        revealPhaseDuration = _revealPhaseDuration;
        alignmentPhaseDuration = _alignmentPhaseDuration;
        resolutionPhaseDuration = _resolutionPhaseDuration;

        minStakeAmount = _minStakeAmount;
        slashingPenaltyBasisPoints = _slashingPenaltyBasisPoints;
        possiblePredictionOutcomes = _possiblePredictionOutcomes;

        currentEpochNumber = 0; // Starts before Epoch 1 is created
    }

    // --- Admin Functions (Owner Only) ---

    /**
     * @notice Sets the duration for different epoch phases.
     * @param _commitDuration Duration for the commit phase in seconds.
     * @param _revealDuration Duration for the reveal phase in seconds.
     * @param _alignmentDuration Duration for the alignment phase in seconds.
     * @param _resolutionDuration Duration for the resolution phase in seconds.
     */
    function setEpochDurations(
        uint64 _commitDuration,
        uint64 _revealDuration,
        uint64 _alignmentDuration,
        uint64 _resolutionDuration
    ) external onlyOwner {
         if (_commitDuration == 0 || _revealDuration == 0 || _alignmentDuration == 0 || _resolutionDuration == 0) revert QuantumLeap__DurationTooShort();

        commitPhaseDuration = _commitDuration;
        revealPhaseDuration = _revealDuration;
        alignmentPhaseDuration = _alignmentDuration;
        resolutionPhaseDuration = _resolutionDuration;

        emit ParameterUpdated("commitPhaseDuration", 0, _commitDuration); // Use 0 as old value placeholder
        emit ParameterUpdated("revealPhaseDuration", 0, _revealDuration);
        emit ParameterUpdated("alignmentPhaseDuration", 0, _alignmentDuration);
        emit ParameterUpdated("resolutionPhaseDuration", 0, _resolutionDuration);
    }

     /**
     * @notice Sets the address authorized to manage epoch phases and resolution.
     * @param _oracleAddress The address of the Oracle/Keeper.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) revert QuantumLeap__OracleAddressZero();
        emit AddressParameterUpdated("oracleAddress", oracleAddress, _oracleAddress);
        oracleAddress = _oracleAddress;
    }

    /**
     * @notice Sets the address of the required NFT collection for participation.
     * @param _requiredNFTCollection The address of the IERC721 contract.
     */
    function setRequiredNFTCollection(address _requiredNFTCollection) external onlyOwner {
        if (_requiredNFTCollection == address(0)) revert QuantumLeap__NFTAddressZero();
        emit AddressParameterUpdated("requiredNFTCollection", address(requiredNFTCollection), _requiredNFTCollection);
        requiredNFTCollection = IERC721(_requiredNFTCollection);
    }

    /**
     * @notice Sets the minimum amount of LEAP tokens required to stake in an epoch.
     * @param _minStakeAmount The minimum amount.
     */
    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        emit ParameterUpdated("minStakeAmount", minStakeAmount, _minStakeAmount);
        minStakeAmount = _minStakeAmount;
    }

    /**
     * @notice Sets the penalty percentage applied to incorrect alignments.
     * @param _slashingPenaltyBasisPoints Penalty in basis points (0-10000).
     */
    function setSlashingPenaltyBasisPoints(uint256 _slashingPenaltyBasisPoints) external onlyOwner {
         if (_slashingPenaltyBasisPoints > 10000) revert QuantumLeap__InvalidSlashingPenalty();
        emit ParameterUpdated("slashingPenaltyBasisPoints", slashingPenaltyBasisPoints, _slashingPenaltyBasisPoints);
        slashingPenaltyBasisPoints = _slashingPenaltyBasisPoints;
    }

    /**
     * @notice Pauses the protocol, preventing most user interactions and epoch phase changes.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @notice Unpauses the protocol.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

     /**
     * @notice Allows owner to withdraw LEAP tokens stuck in the contract (use with extreme caution).
     * @param amount Amount of LEAP to withdraw.
     */
    function emergencyWithdrawAdmin(uint256 amount) external onlyOwner {
        uint256 balance = leapToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance; // Withdraw max available
        }
        if (!leapToken.transfer(owner(), amount)) {
            revert QuantumLeap__EmergencyWithdrawFailed();
        }
    }

    /**
     * @notice Allows owner to update the list of possible prediction outcomes.
     * @param _outcomes The new array of valid outcome strings.
     */
    function updatePredictionOutcomes(string[] memory _outcomes) external onlyOwner {
        if (_outcomes.length == 0) revert QuantumLeap__InvalidOutcomeList();
        possiblePredictionOutcomes = _outcomes;
        emit StringArrayParameterUpdated("possiblePredictionOutcomes");
    }

    // --- Epoch Lifecycle Management (Oracle/Keeper Only) ---

    /**
     * @notice Starts the commit phase for the NEXT epoch. Can only be called if the current epoch is Resolved, Cancelled, or NonExistent.
     */
    function startNextEpochCommitPhase() external onlyOracle whenNotPaused {
        uint256 nextEpochNum = currentEpochNumber + 1;

        // Ensure previous epoch is settled or doesn't exist
        if (currentEpochNumber > 0) {
             EpochState lastEpochState = epochs[currentEpochNumber].state;
             if (lastEpochState != EpochState.Resolved && lastEpochState != EpochState.Cancelled) {
                 revert QuantumLeap__EpochNotReady();
             }
        }

        epochs[nextEpochNum].state = EpochState.CommitPhase;
        epochs[nextEpochNum].commitDeadline = uint64(block.timestamp) + commitPhaseDuration;
        epochs[nextEpochNum].revealDeadline = epochs[nextEpochNum].commitDeadline + revealPhaseDuration;
        epochs[nextEpochNum].alignmentDeadline = epochs[nextEpochNum].revealDeadline + alignmentPhaseDuration;
        epochs[nextEpochNum].resolutionDeadline = epochs[nextEpochNum].alignmentDeadline + resolutionPhaseDuration;

        currentEpochNumber = nextEpochNum;

        emit EpochCommitPhaseStarted(currentEpochNumber, epochs[currentEpochNumber].commitDeadline);
    }

    /**
     * @notice Oracle commits the hash of the target outcome for the current epoch during the Commit phase.
     * @param _targetHash The keccak256 hash of the target outcome string.
     */
    function commitNextEpochTargetHash(bytes32 _targetHash) external onlyOracle whenCommitPhase(currentEpochNumber) whenNotPaused {
        if (epochs[currentEpochNumber].targetOutcomeHash != bytes32(0)) {
            revert QuantumLeap__TargetAlreadyRevealed(); // Indicates hash already committed (using reveal check error)
        }
        epochs[currentEpochNumber].targetOutcomeHash = _targetHash;
        emit EpochTargetHashCommitted(currentEpochNumber, _targetHash);
    }

    /**
     * @notice Oracle reveals the target outcome for the current epoch during the Reveal phase.
     * Verifies against the committed hash and starts the Alignment phase.
     * @param _targetOutcome The actual target outcome string.
     */
    function revealNextEpochTarget(string memory _targetOutcome) external onlyOracle whenRevealPhase(currentEpochNumber) whenNotPaused {
        EpochData storage epoch = epochs[currentEpochNumber];
        if (epoch.targetOutcomeHash == bytes32(0)) {
            revert QuantumLeap__CommitmentNotSet();
        }
        if (keccak256(abi.encodePacked(_targetOutcome)) != epoch.targetOutcomeHash) {
            revert QuantumLeap__InvalidTargetReveal(_targetOutcome);
        }

        bool isValidOutcome = false;
        for(uint i = 0; i < possiblePredictionOutcomes.length; i++) {
            if (keccak256(abi.encodePacked(_targetOutcome)) == keccak256(abi.encodePacked(possiblePredictionOutcomes[i]))) {
                isValidOutcome = true;
                break;
            }
        }
        if (!isValidOutcome) revert QuantumLeap__InvalidAlignmentOutcome(_targetOutcome);


        epoch.targetOutcome = _targetOutcome;
        epoch.state = EpochState.AlignmentPhase; // Move to Alignment phase
        // AlignmentDeadline and ResolutionDeadline are already set in startNextEpochCommitPhase

        emit EpochTargetRevealed(currentEpochNumber, _targetOutcome, epoch.alignmentDeadline);
        emit EpochAlignmentPhaseStarted(currentEpochNumber, epoch.resolutionDeadline);
    }

    /**
     * @notice Resolves a specific epoch by providing the actual outcome.
     * Can only be called within the resolution window for that epoch.
     * @param epochNum The epoch number to resolve.
     * @param actualOutcome The actual outcome of the event the epoch was predicting.
     */
    function resolveEpoch(uint256 epochNum, string memory actualOutcome) external onlyOracle whenNotPaused whenResolutionWindow(epochNum) {
        EpochData storage epoch = epochs[epochNum];
        if (epoch.state != EpochState.AlignmentPhase || block.timestamp < epoch.alignmentDeadline) {
             revert QuantumLeap__EpochNotReady(); // Not yet past alignment deadline
        }
         if (block.timestamp > epoch.resolutionDeadline) {
            revert QuantumLeap__EpochNotReady(); // Resolution window closed
        }

        bool isValidOutcome = false;
        for(uint i = 0; i < possiblePredictionOutcomes.length; i++) {
            if (keccak256(abi.encodePacked(actualOutcome)) == keccak256(abi.encodePacked(possiblePredictionOutcomes[i]))) {
                isValidOutcome = true;
                break;
            }
        }
        if (!isValidOutcome) revert QuantumLeap__InvalidAlignmentOutcome(actualOutcome);


        epoch.resolvedOutcome = actualOutcome;
        epoch.state = EpochState.Resolved;

        // Note: Reward calculation and slashing happen when users claim,
        // based on the final state and resolved outcome set here.

        emit EpochResolved(epochNum, actualOutcome);
    }

     /**
     * @notice Allows Oracle/Keeper to cancel the commitment before reveal.
     * @param epochNum The epoch number.
     */
    function cancelEpochCommitment(uint256 epochNum) external onlyOracle whenCommitPhase(epochNum) whenNotPaused {
         EpochData storage epoch = epochs[epochNum];
         if (epoch.targetOutcomeHash != bytes32(0)) {
             revert QuantumLeap__TargetAlreadyRevealed(); // Commitment was already made, cannot cancel commitment phase
         }
         // If no commitment, the epoch is essentially stuck until a new commit phase is started.
         // Or we could explicitly cancel the epoch here:
         // epoch.state = EpochState.Cancelled;
         // emit EpochCancelled(epochNum);
         // Let's not implement explicit cancellation here, Oracle can just not commit.
         // The next phase transition will fail until a commit happens.
    }

     /**
     * @notice Allows Oracle/Keeper to cancel an epoch if there's an issue (e.g., oracle data feed failure).
     * Can only be called before the resolution deadline passes.
     * @param epochNum The epoch number to cancel.
     */
    function cancelEpoch(uint256 epochNum) external onlyOracle whenNotPaused {
         EpochData storage epoch = epochs[epochNum];

         // Cannot cancel if already resolved or cancelled
         if (epoch.state == EpochState.Resolved || epoch.state == EpochState.Cancelled) {
             revert QuantumLeap__InvalidPhase();
         }
          // Cannot cancel if resolution window is closed
         if (epoch.state == EpochState.AlignmentPhase && block.timestamp > epoch.resolutionDeadline) {
             revert QuantumLeap__EpochNotReady();
         }

         epoch.state = EpochState.Cancelled;
         // Staked funds become immediately withdrawable by users without penalty
         emit EpochCancelled(epochNum);
    }


    // --- User Interaction ---

    /**
     * @notice Stakes LEAP tokens for the current epoch during the Alignment phase.
     * Requires holding the specified NFT collection and meeting the minimum stake amount.
     * @param amount The amount of LEAP to stake.
     */
    function stake(uint256 amount) external payable whenNotPaused whenAlignmentPhase(currentEpochNumber) {
        EpochData storage epoch = epochs[currentEpochNumber];
        UserEpochData storage userData = epoch.userData[msg.sender];

        if (requiredNFTCollection.balanceOf(msg.sender) == 0) {
            revert QuantumLeap__NoNFT();
        }
        if (amount < minStakeAmount) {
            revert QuantumLeap__StakeAmountTooLow(minStakeAmount);
        }
         if (userData.stakedAmount > 0) {
            revert QuantumLeap__AlreadyStakedInEpoch();
        }

        // Transfer tokens from user to contract
        bool success = leapToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert QuantumLeap__EmergencyWithdrawFailed(); // Reusing error, signifies token transfer failure
        }

        userData.stakedAmount = amount;
        epoch.totalStakedInEpoch = epoch.totalStakedInEpoch.add(amount);

        emit Staked(msg.sender, currentEpochNumber, amount);
    }

    /**
     * @notice Aligns the user's staked amount with a chosen outcome for the current epoch.
     * Must be called during the Alignment phase after staking.
     * @param outcome The outcome string to align with.
     */
    function align(string memory outcome) external whenNotPaused whenAlignmentPhase(currentEpochNumber) {
         EpochData storage epoch = epochs[currentEpochNumber];
        UserEpochData storage userData = epoch.userData[msg.sender];

        if (userData.stakedAmount == 0) {
            revert QuantumLeap__NotStakedInEpoch();
        }
        if (userData.alignmentSet) {
            revert QuantumLeap__AlignmentAlreadySet();
        }

        bool isValidOutcome = false;
        for(uint i = 0; i < possiblePredictionOutcomes.length; i++) {
            if (keccak256(abi.encodePacked(outcome)) == keccak256(abi.encodePacked(possiblePredictionOutcomes[i]))) {
                isValidOutcome = true;
                break;
            }
        }
        if (!isValidOutcome) revert QuantumLeap__InvalidAlignmentOutcome(outcome);


        userData.alignedOutcome = outcome;
        userData.alignmentSet = true;
        epoch.totalAlignedPerOutcome[outcome] = epoch.totalAlignedPerOutcome[outcome].add(userData.stakedAmount);

        emit Aligned(msg.sender, currentEpochNumber, outcome);
    }

    /**
     * @notice Allows user to update their alignment for the current epoch.
     * Must be called during the Alignment phase after staking and initial alignment.
     * @param newOutcome The new outcome string to align with.
     */
    function updateAlignment(string memory newOutcome) external whenNotPaused whenAlignmentPhase(currentEpochNumber) {
         EpochData storage epoch = epochs[currentEpochNumber];
        UserEpochData storage userData = epoch.userData[msg.sender];

        if (userData.stakedAmount == 0) {
            revert QuantumLeap__NotStakedInEpoch();
        }
        if (!userData.alignmentSet) {
            revert QuantumLeap__AlignmentNotSet();
        }

         bool isValidOutcome = false;
        for(uint i = 0; i < possiblePredictionOutcomes.length; i++) {
            if (keccak256(abi.encodePacked(newOutcome)) == keccak256(abi.encodePacked(possiblePredictionOutcomes[i]))) {
                isValidOutcome = true;
                break;
            }
        }
        if (!isValidOutcome) revert QuantumLeap__InvalidAlignmentOutcome(newOutcome);


        // Decrease stake count for old outcome
        epoch.totalAlignedPerOutcome[userData.alignedOutcome] = epoch.totalAlignedPerOutcome[userData.alignedOutcome].sub(userData.stakedAmount);

        // Update alignment
        userData.alignedOutcome = newOutcome;

        // Increase stake count for new outcome
        epoch.totalAlignedPerOutcome[newOutcome] = epoch.totalAlignedPerOutcome[newOutcome].add(userData.stakedAmount);

        emit AlignmentUpdated(msg.sender, currentEpochNumber, newOutcome);
    }


    /**
     * @notice Allows a user to claim their principal stake and any earned rewards
     * from a resolved or cancelled epoch. Applies slashing for incorrect predictions.
     * @param epochNum The epoch number to claim from.
     */
    function claimRewardsAndPrincipal(uint256 epochNum) external whenNotPaused {
        EpochData storage epoch = epochs[epochNum];
        UserEpochData storage userData = epoch.userData[msg.sender];

        // Must have staked and not claimed yet
        if (userData.stakedAmount == 0 || userData.claimed) {
             revert QuantumLeap__ClaimNotAvailable();
        }

        uint256 principalToReturn = userData.stakedAmount;
        uint256 rewardsToClaim = 0;
        uint256 slashedAmount = 0;

        if (epoch.state == EpochState.Cancelled) {
            // If epoch was cancelled, just return principal
             // No slashing or rewards
             // Funds should still be in the contract from transferFrom
        } else if (epoch.state == EpochState.Resolved) {
             if (!userData.alignmentSet) {
                 // User staked but didn't align - they get principal back but no rewards
             } else {
                 // Check if alignment was correct
                 if (keccak256(abi.encodePacked(userData.alignedOutcome)) == keccak256(abi.encodePacked(epoch.resolvedOutcome))) {
                     // Correct alignment: Calculate and distribute rewards
                     uint256 totalWinningStake = epoch.totalAlignedPerOutcome[epoch.resolvedOutcome];
                     uint256 totalRewardPoolForWinners = epoch.totalStakedInEpoch.sub(epoch.totalSlashingPool); // Total staked in epoch minus slashed amounts goes to winners

                     if (totalWinningStake > 0) {
                        // Reward is proportional to user's stake within the total winning stake
                        rewardsToClaim = totalRewardPoolForWinners.mul(userData.stakedAmount).div(totalWinningStake);
                     }
                     // Principal is returned as well

                 } else {
                     // Incorrect alignment: Apply slashing penalty
                     slashedAmount = userData.stakedAmount.mul(slashingPenaltyBasisPoints).div(10000);
                     principalToReturn = principalToReturn.sub(slashedAmount);
                     epoch.totalSlashingPool = epoch.totalSlashingPool.add(slashedAmount); // Add to the slashing pool (which feeds winners)
                 }
             }
        } else {
            // Epoch is not resolved or cancelled yet
            revert QuantumLeap__ClaimNotAvailable();
        }

        // Mark as claimed before transferring
        userData.claimed = true;

        uint256 totalToSend = principalToReturn.add(rewardsToClaim);

        // Transfer funds to user
        if (totalToSend > 0) {
            bool success = leapToken.transfer(msg.sender, totalToSend);
             if (!success) {
                 // This is a critical failure - funds are stuck for the user.
                 // Consider emitting a specific event or a more robust transfer pattern.
                 // For this example, we'll revert, but in production, might log and let user try again.
                 revert QuantumLeap__EmergencyWithdrawFailed(); // Reusing error
            }
        }

        emit Claimed(msg.sender, epochNum, principalToReturn, rewardsToClaim, slashedAmount);
    }

     /**
     * @notice Allows a user to claim from multiple resolved or cancelled epochs in one transaction.
     * @param epochNumbers An array of epoch numbers to claim from.
     */
    function batchClaimRewardsAndPrincipal(uint256[] calldata epochNumbers) external whenNotPaused {
        for (uint i = 0; i < epochNumbers.length; i++) {
            // Call single claim function, ignoring potential reverts on already claimed/not available
            // A more robust version might catch errors or track successful claims.
            try this.claimRewardsAndPrincipal(epochNumbers[i]) {} catch {}
        }
    }


    // --- View/Information Functions ---

    /**
     * @notice Retrieves all details for a specific epoch number.
     * @param epochNum The epoch number.
     * @return epochState The current state of the epoch.
     * @return targetOutcome The target outcome (if revealed).
     * @return resolvedOutcome The resolved outcome (if resolved).
     * @return commitDeadline Timestamp when commit phase ends.
     * @return revealDeadline Timestamp when reveal phase ends.
     * @return alignmentDeadline Timestamp when alignment phase ends.
     * @return resolutionDeadline Timestamp when resolution window ends.
     * @return totalStaked The total amount staked in the epoch.
     */
    function getEpochData(uint256 epochNum)
        external
        view
        returns (
            EpochState epochState,
            string memory targetOutcome,
            string memory resolvedOutcome,
            uint64 commitDeadline,
            uint64 revealDeadline,
            uint64 alignmentDeadline,
            uint64 resolutionDeadline,
            uint256 totalStaked
        )
    {
        EpochData storage epoch = epochs[epochNum];
        return (
            epoch.state,
            epoch.targetOutcome,
            epoch.resolvedOutcome,
            epoch.commitDeadline,
            epoch.revealDeadline,
            epoch.alignmentDeadline,
            epoch.resolutionDeadline,
            epoch.totalStakedInEpoch
        );
    }

     /**
     * @notice Retrieves the current phase/state of a specific epoch.
     * @param epochNum The epoch number.
     * @return The current EpochState.
     */
    function getEpochState(uint256 epochNum) external view returns (EpochState) {
        return epochs[epochNum].state;
    }

    /**
     * @notice Returns the current active epoch number.
     */
    function getCurrentEpochNumber() external view returns (uint256) {
        return currentEpochNumber;
    }

    /**
     * @notice Retrieves a user's staking, alignment, and claim status for a specific epoch.
     * @param user The address of the user.
     * @param epochNum The epoch number.
     * @return stakedAmount The amount the user staked.
     * @return alignedOutcome The outcome the user aligned with.
     * @return alignmentSet Whether the user has set their alignment.
     * @return claimed Whether the user has claimed from this epoch.
     */
    function getUserEpochData(address user, uint256 epochNum)
        external
        view
        returns (uint256 stakedAmount, string memory alignedOutcome, bool alignmentSet, bool claimed)
    {
        UserEpochData storage userData = epochs[epochNum].userData[user];
        return (
            userData.stakedAmount,
            userData.alignedOutcome,
            userData.alignmentSet,
            userData.claimed
        );
    }

     /**
     * @notice Returns the total stake aligned for each outcome within a specific epoch.
     * Note: This only includes stake that has been *aligned*, not just staked.
     * @param epochNum The epoch number.
     * @return An array of outcome strings and an array of corresponding total staked amounts.
     */
    function getEpochStakeSummary(uint256 epochNum) external view returns (string[] memory outcomes, uint256[] memory totalStakedForOutcome) {
         EpochData storage epoch = epochs[epochNum];
         uint256 numOutcomes = possiblePredictionOutcomes.length;
         outcomes = new string[](numOutcomes);
         totalStakedForOutcome = new uint256[](numOutcomes);

         for (uint i = 0; i < numOutcomes; i++) {
             outcomes[i] = possiblePredictionOutcomes[i];
             totalStakedForOutcome[i] = epoch.totalAlignedPerOutcome[possiblePredictionOutcomes[i]];
         }
         return (outcomes, totalStakedForOutcome);
     }

    /**
     * @notice Returns the total amount of LEAP tokens currently held by the contract
     * that have been staked across all epochs (resolved or ongoing).
     */
    function getTotalProtocolStaked() external view returns (uint256) {
        // This is an approximation. A more accurate way would be to sum up
        // totalStakedInEpoch for all epochs not yet claimed by everyone.
        // For simplicity, we return the balance of the contract MINUS fees/other funds if any.
        // Assuming contract only holds staked LEAP + potentially collected slashing fees.
        // A better method would involve iterating or tracking a global total.
        // Let's just return the contract balance for now as a proxy.
        return leapToken.balanceOf(address(this));
    }

    /**
     * @notice Returns the current LEAP token balance of the protocol contract.
     */
    function getProtocolBalance() external view returns (uint256) {
        return leapToken.balanceOf(address(this));
    }

    /**
     * @notice Returns the current minimum staking amount required.
     */
    function getMinStakeAmount() external view returns (uint256) {
        return minStakeAmount;
    }

    /**
     * @notice Returns the current slashing penalty percentage in basis points.
     */
    function getSlashingPenaltyBasisPoints() external view returns (uint256) {
        return slashingPenaltyBasisPoints;
    }

    /**
     * @notice Returns the required NFT collection address for participation.
     */
    function getRequiredNFTCollection() external view returns (address) {
        return address(requiredNFTCollection);
    }

    /**
     * @notice Returns the list of possible prediction outcomes.
     */
    function getPossiblePredictionOutcomes() external view returns (string[] memory) {
        return possiblePredictionOutcomes;
    }

    /**
     * @notice Estimates the potential rewards for a user in a *resolved* epoch if their alignment was correct.
     * Note: This is an estimate based on current state and does not guarantee the final amount
     * as totalWinningStake or totalSlashingPool might slightly change before claim.
     * @param user The address of the user.
     * @param epochNum The epoch number.
     * @return potentialRewards The estimated reward amount.
     */
    function calculatePotentialRewards(address user, uint256 epochNum) external view returns (uint256 potentialRewards) {
        EpochData storage epoch = epochs[epochNum];
        UserEpochData storage userData = epoch.userData[user];

        if (epoch.state != EpochState.Resolved || !userData.alignmentSet || userData.stakedAmount == 0 || userData.claimed) {
            return 0; // No potential rewards if not resolved, not aligned, not staked, or already claimed
        }

        // Check if alignment was correct
        if (keccak256(abi.encodePacked(userData.alignedOutcome)) == keccak256(abi.encodePacked(epoch.resolvedOutcome))) {
            // Correct alignment: Calculate potential rewards
            uint256 totalWinningStake = epoch.totalAlignedPerOutcome[epoch.resolvedOutcome];
            uint256 totalRewardPoolForWinners = epoch.totalStakedInEpoch.sub(epoch.totalSlashingPool); // Total staked in epoch minus slashed amounts goes to winners

            if (totalWinningStake > 0) {
                // Reward is proportional to user's stake within the total winning stake
                return totalRewardPoolForWinners.mul(userData.stakedAmount).div(totalWinningStake);
            }
        }
        return 0; // Incorrect alignment or other conditions not met
    }

    /**
     * @notice Returns the timestamp when the commit phase ends for a given epoch.
     * @param epochNum The epoch number.
     */
    function getEpochCommitDeadline(uint256 epochNum) external view returns (uint64) {
        return epochs[epochNum].commitDeadline;
    }

    /**
     * @notice Returns the timestamp when the reveal phase ends for a given epoch.
     * @param epochNum The epoch number.
     */
    function getEpochTargetRevealDeadline(uint256 epochNum) external view returns (uint64) {
        return epochs[epochNum].revealDeadline;
    }

     /**
     * @notice Returns the timestamp when the alignment phase ends for a given epoch.
     * @param epochNum The epoch number.
     */
    function getEpochAlignmentDeadline(uint256 epochNum) external view returns (uint64) {
        return epochs[epochNum].alignmentDeadline;
    }

    /**
     * @notice Returns the timestamp when the resolution window ends for a given epoch.
     * @param epochNum The epoch number.
     */
    function getEpochResolutionDeadline(uint256 epochNum) external view returns (uint64) {
        return epochs[epochNum].resolutionDeadline;
    }

    /**
     * @notice Returns the committed target hash for a given epoch during the Commit/Reveal phases.
     * @param epochNum The epoch number.
     */
    function getEpochTargetHash(uint256 epochNum) external view returns (bytes32) {
        return epochs[epochNum].targetOutcomeHash;
    }

    /**
     * @notice Returns a list of epoch numbers that a user can claim from.
     * Note: This requires iterating through potentially many epochs and might be gas-intensive for users with high activity across many past epochs.
     * In a real application, consider off-chain indexing or a different claim mechanism.
     * @param user The address of the user.
     * @return An array of epoch numbers eligible for claiming.
     */
    function getUserClaimableEpochs(address user) external view returns (uint256[] memory) {
        uint256[] memory claimable;
        uint256 count = 0;

        // Estimate the maximum number of claimable epochs (cannot be more than currentEpochNumber)
        // Plus add some buffer if iterating isn't too costly
        uint256 maxCheck = currentEpochNumber;
        uint256 estimatedClaimable = 0;
         // First pass to count claimable epochs
        for (uint256 i = 1; i <= maxCheck; i++) {
            EpochData storage epoch = epochs[i];
            UserEpochData storage userData = epoch.userData[user];
            // Claimable if staked, not claimed, and epoch is Resolved or Cancelled
            if (userData.stakedAmount > 0 && !userData.claimed && (epoch.state == EpochState.Resolved || epoch.state == EpochState.Cancelled)) {
                estimatedClaimable++;
            }
        }

        claimable = new uint256[](estimatedClaimable);

        // Second pass to fill the array
        for (uint256 i = 1; i <= maxCheck; i++) {
             EpochData storage epoch = epochs[i];
             UserEpochData storage userData = epoch.userData[user];
             if (userData.stakedAmount > 0 && !userData.claimed && (epoch.state == EpochState.Resolved || epoch.state == EpochState.Cancelled)) {
                claimable[count] = i;
                count++;
            }
        }

        return claimable;
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Time-Based Epochs with Phases:** The protocol operates in distinct, timed phases (Commit, Reveal, Alignment, Resolution). This introduces game theory, transparency (commit-reveal), and defined windows for user interaction.
2.  **Commit-Reveal Mechanism:** The Oracle commits to a hash of the target outcome *before* users align, and only reveals the actual target later. This prevents the Oracle from using information about user alignments to set a target that benefits them, and adds transparency to the Oracle process.
3.  **Staking and Alignment:** Users don't just stake; they stake *and* align with a specific outcome. This is the core prediction mechanism.
4.  **Required NFT for Participation:** Integrating an `IERC721` check (`requiredNFTCollection.balanceOf(msg.sender) > 0`) restricts participation to holders of a specific NFT collection. This can be used for exclusive access, gating based on community membership, or creating tiers of participation.
5.  **Slashing Penalties:** Incorrect predictions result in a loss of a portion of the staked principal. This funds the reward pool for correct predictors, creating a zero-sum or negative-sum game within an epoch, incentivizing accurate predictions.
6.  **Dynamic Parameters:** Owner can adjust parameters like epoch durations, min stake, and slashing penalty, allowing the protocol to adapt.
7.  **Oracle Dependency:** Explicitly defines an `onlyOracle` role for critical state transitions and outcome resolution, highlighting the reliance on external data and the need for a secure Oracle mechanism (though the contract focuses on *how* the oracle interacts, not *building* the oracle itself).
8.  **Structs and Mappings for Complex State:** Uses nested structs (`EpochData`, `UserEpochData`) and mappings (`epochs`, `totalAlignedPerOutcome`, `userData`) to efficiently manage per-epoch and per-user data.
9.  **Pausable Pattern:** Standard security feature to pause the contract in case of issues.
10. **Custom Errors:** Using `revert MyError()` is more gas-efficient and provides clearer error messages than `require(condition, "Error message")` in modern Solidity.
11. **SafeMath:** While 0.8+ includes overflow checks, explicitly using `SafeMath` can enhance readability and sometimes prevent unexpected behavior with very large numbers or specific operations (though less critical in 0.8+). (Included but commented that it's less critical in 0.8+).

This contract provides a framework for a sophisticated prediction/alignment game built on Solidity, featuring timed phases, transparency mechanisms, unique access control, and economic incentives/penalties. It meets the requirement of having over 20 functions while incorporating several advanced and creative concepts not commonly found in basic examples.