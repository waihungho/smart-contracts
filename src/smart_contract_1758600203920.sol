Here is a Solidity smart contract, `OptimatiXProtocol`, designed with an advanced, creative, and trendy concept. It focuses on decentralized AI-assisted protocol optimization and a verifiable reputation system, avoiding direct duplication of existing open-source contracts by combining multiple modern DeFi/Web3 ideas into a cohesive, epoch-based mechanism.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For the staking token

/**
 * @title OptimatiXProtocol
 * @dev A decentralized protocol for collaborative AI-driven optimization and verifiable reputation.
 *      Participants (Optimizers) submit strategies (e.g., AI model parameters, optimization algorithms),
 *      and other participants (Verifiers) assess their performance and adherence to objectives.
 *      The protocol advances in distinct epochs, determining winning strategies, distributing rewards,
 *      and dynamically updating non-transferable reputation scores (akin to Soulbound Tokens)
 *      based on participant performance and accuracy.
 *
 *      This contract acts as an on-chain orchestrator for an off-chain process of
 *      AI/ML model development, evaluation, and consensus, providing incentive alignment
 *      and trustless verification.
 *
 * Outline:
 * 1.  State Variables & Custom Types: Defines core data structures like `Epoch`, `Strategy`, `Assessment`,
 *     and `Participant` to manage protocol state.
 * 2.  Events: Declares events for transparent logging of significant protocol actions, crucial for off-chain monitoring.
 * 3.  Errors: Custom error types provide clear and specific feedback for failed transactions.
 * 4.  Access Control & Modifiers: Leverages OpenZeppelin's `Ownable`, `Pausable`, and `ReentrancyGuard` for robust
 *     security and controlled access, along with custom role-based checks.
 * 5.  Core Protocol Management & Governance: Contains functions for the protocol's governor to configure global parameters,
 *     update the central optimization objective, manage protocol fees, and handle emergency pauses and governor changes.
 * 6.  Epoch Management & Resolution: Features the pivotal `advanceEpoch` function, which drives the protocol's
 *     lifecycle. This function resolves the previous epoch by identifying winning strategies, calculating
 *     and distributing rewards, and updating participant reputation based on their contributions.
 * 7.  Optimizer Functions: Provides functionalities for participants designated as "Optimizers," allowing them to
 *     register, submit their optimization strategies, manage their staking funds, and claim earned rewards.
 * 8.  Verifier Functions: Offers functionalities for "Verifiers" to register, submit their assessments of Optimizer
 *     strategies, participate in a dispute mechanism, manage their staking funds, and claim rewards for accurate
 *     evaluations.
 * 9.  Reputation (SBT-like) & State Queries: Includes read-only functions to query participant reputation scores
 *     (which are non-transferable and influence protocol utility/rewards) and other essential protocol state data,
 *     ensuring transparency and auditability.
 *
 * Function Summary (25 Functions):
 *
 * I. Core Protocol Management & Governance (Governor-only or permissioned)
 *    1.  `initializeProtocol(uint256 _epochDuration, uint256 _minOptimizerStake, uint256 _minVerifierStake, bytes32 _initialObjectiveRef)`:
 *        Initializes the protocol's fundamental parameters, including epoch timing, minimum staking requirements for participants,
 *        and the initial reference for the optimization objective. Callable only once by the deployer.
 *    2.  `updateProtocolParameters(uint256 _newEpochDuration, uint256 _newMinOptimizerStake, uint256 _newMinVerifierStake)`:
 *        Enables the governor to modify several key protocol settings (epoch duration, minimum Optimizer and Verifier stakes)
 *        in a single batch transaction.
 *    3.  `setObjectiveFunctionReference(bytes32 _newObjectiveRef)`:
 *        Updates the `bytes32` identifier (e.g., an IPFS Content Identifier or a hash) that points to the current
 *        optimization goal or the specification of the AI model to be optimized. This guides new strategy submissions and their assessments.
 *    4.  `proposeGovernor(address _newGovernor)`:
 *        Initiates a secure, multi-step process for changing the protocol's governing address. This involves a time-lock
 *        period to ensure a deliberate transition.
 *    5.  `finalizeGovernorChange()`:
 *        Completes the governor transition, transferring `Ownable` ownership to the `pendingGovernor` once the
 *        predefined `GOVERNOR_CHANGE_TIMELOCK` has elapsed, thereby securing the change.
 *    6.  `pauseSystem()`:
 *        An emergency function allowing the governor to temporarily halt critical user-facing protocol operations (e.g., submissions, assessments, epoch advances)
 *        in response to security threats or bugs.
 *    7.  `unpauseSystem()`:
 *        Resumes all paused protocol operations, restoring normal functionality once the emergency situation is resolved.
 *    8.  `setRewardDistributionWeights(uint256 _optimizerWeight, uint256 _verifierWeight, uint256 _reputationFactor)`:
 *        Configures the proportional distribution of rewards between Optimizers and Verifiers (in basis points)
 *        and defines how significantly a participant's reputation score impacts their reward share and potential penalties.
 *    9.  `collectProtocolFees()`:
 *        Permits the governor to withdraw accumulated operational fees (collected from strategy submission fees and
 *        a percentage of distributed rewards) into the governor's wallet.
 *
 * II. Epoch Management & Resolution
 *    10. `advanceEpoch()`:
 *        The protocol's core lifecycle function. Callable by any address once the current epoch's end time passes.
 *        It resolves the preceding epoch by identifying winning strategies, calculating and distributing `stakingToken` rewards
 *        to successful Optimizers and accurate Verifiers, and updating participant reputation scores based on their performance.
 *    11. `getEpochDetails(uint256 epochNum)`:
 *        Provides a comprehensive, read-only view of all stored data for a specific epoch, including its start/end times,
 *        status, winning strategy, and total rewards distributed.
 *
 * III. Optimizer Role Functions
 *    12. `registerOptimizer(uint256 _amount)`:
 *        Allows an address to formally register as an Optimizer by staking a minimum required amount of `stakingToken`.
 *        Requires prior approval for the contract to spend the `stakingToken` from the caller's account.
 *    13. `submitStrategy(string memory _strategyURI)`:
 *        Enables registered Optimizers to submit a new optimization strategy for evaluation within the current epoch.
 *        A `strategySubmissionFee` (in `stakingToken`) is required, for which the contract must be approved.
 *        The `_strategyURI` typically points to off-chain data (e.g., IPFS) describing the strategy.
 *    14. `withdrawOptimizerStake()`:
 *        Permits an Optimizer to withdraw their staked `stakingToken` funds. This action is typically restricted until
 *        all associated strategies have been fully resolved and any applicable penalties or lock-up periods are complete.
 *    15. `claimOptimizerRewards(uint256 _epochNumber)`:
 *        Allows an Optimizer to claim their accrued `stakingToken` rewards from a specific, previously resolved epoch
 *        where their strategy was successful.
 *
 * IV. Verifier Role Functions
 *    16. `registerVerifier(uint256 _amount)`:
 *        Allows an address to formally register as a Verifier by staking a minimum required amount of `stakingToken`.
 *        Requires prior approval for the contract to spend the `stakingToken` from the caller's account.
 *    17. `submitAssessment(uint256 _strategyId, int256 _score, string memory _assessmentURI)`:
 *        Enables registered Verifiers to submit their evaluation (a `_score` and an optional `_assessmentURI` to detailed report)
 *        for a specific Optimizer's strategy within the current epoch. Accurate assessments are incentivized.
 *    18. `disputeAssessment(uint256 _epochNumber, uint256 _strategyId, uint256 _assessmentId, string memory _disputeURI)`:
 *        Provides a mechanism for an Optimizer or another Verifier to formally challenge a submitted assessment.
 *        Requires a native currency (e.g., ETH) dispute fee and triggers an implied off-chain arbitration process.
 *    19. `withdrawVerifierStake()`:
 *        Permits a Verifier to withdraw their staked `stakingToken` funds. This action is typically restricted until
 *        all associated assessments have been fully resolved and any applicable penalties or lock-up periods are complete.
 *    20. `claimVerifierRewards(uint256 _epochNumber)`:
 *        Allows a Verifier to claim their accrued `stakingToken` rewards from a specific, previously resolved epoch
 *        where their assessments were accurate and contributed to the consensus.
 *
 * V. Reputation (SBT-like) & State Queries
 *    21. `getOptimizerReputation(address _optimizer)`:
 *        Returns the current non-transferable reputation score of a given Optimizer, which plays a role in their standing
 *        within the protocol and their share of rewards.
 *    22. `getVerifierReputation(address _verifier)`:
 *        Returns the current non-transferable reputation score of a given Verifier, reflecting their historical accuracy
 *        in assessing strategies and influencing their reward potential.
 *    23. `getStrategyStatus(uint256 _strategyId)`:
 *        Provides the current lifecycle status of a specific strategy (e.g., `Pending`, `Assessed`, `Disputed`, `Resolved`).
 *    24. `getCurrentStakes(address _participant)`:
 *        Returns the total amount of `stakingToken` currently staked by a given participant address, whether they are
 *        registered as an Optimizer or a Verifier. Returns 0 if the address is not an active participant.
 *    25. `getCurrentEpochNumber()`:
 *        Returns the identifier of the epoch that is currently active for strategy submissions and assessments.
 */
contract OptimatiXProtocol is Ownable, Pausable, ReentrancyGuard {
    // --- State Variables & Custom Types ---

    IERC20 public immutable stakingToken; // ERC20 token used for staking and rewards

    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration of each epoch in seconds
    uint256 public epochStartTime; // Timestamp of current epoch start

    bytes32 public objectiveFunctionReference; // IPFS CID or similar identifier for the current optimization goal/AI model spec

    uint256 public minOptimizerStake;
    uint256 public minVerifierStake;
    uint256 public strategySubmissionFee; // Fee in stakingToken for submitting a strategy

    // Reward distribution weights (in basis points, e.g., 6000 for 60%)
    uint256 public optimizerRewardWeight;
    uint256 public verifierRewardWeight;
    uint256 public reputationImpactFactor; // Multiplier for reputation's effect on rewards/penalties, in basis points (100 = 1x)

    // Protocol Fees
    uint256 public protocolFeePercentage; // Percentage of rewards/penalties collected as fees (e.g., 500 for 5%)
    uint256 public protocolFeeBalance;    // Accumulated fees in stakingToken

    uint256 private nextStrategyId;
    uint256 private nextAssessmentId;

    // Structs
    struct Epoch {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        bool resolved;
        uint256[] strategyIds; // IDs of strategies submitted in this epoch
        uint256 winningStrategyId; // The strategy deemed best for this epoch
        uint256 totalRewardsDistributed; // Total rewards distributed for this epoch from the pool
    }

    enum StrategyStatus {
        Pending,   // Submitted, awaiting assessments
        Assessed,  // Has received sufficient assessments
        Disputed,  // An assessment for this strategy is disputed
        Resolved   // Finalized for the epoch
    }

    struct Strategy {
        uint256 id;
        address optimizer;
        uint256 epochId;
        string strategyURI; // IPFS CID or URL to strategy description/code
        StrategyStatus status;
        uint256[] assessmentIds; // IDs of assessments for this strategy
        int256 aggregatedScore; // Sum of verifier scores (simplified aggregation)
        uint256 claimedRewards; // Total rewards claimed by this strategy's optimizer
    }

    struct Assessment {
        uint256 id;
        address verifier;
        uint256 strategyId;
        uint256 epochId;
        int256 score; // The verifier's score/evaluation for the strategy
        string assessmentURI; // IPFS CID or URL to detailed assessment report
        bool disputed;
        bool rewarded;
    }

    struct Participant {
        address addr;
        uint256 totalStaked;
        uint256 reputation; // Non-transferable score (Soulbound Token-like)
        bool isActive; // Can participate in current epoch (e.g., if stake is sufficient)
        uint256 totalClaimedRewards; // Sum of all rewards claimed across epochs
    }

    // Mappings
    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => Strategy) public strategies;
    mapping(uint256 => Assessment) public assessments;

    mapping(address => Participant) public optimizers;
    mapping(address => Participant) public verifiers;

    // Individual rewards per participant per epoch, waiting to be claimed
    mapping(address => mapping(uint224 => uint224)) public claimableOptimizerEpochRewards; // Using uint224 to save gas
    mapping(address => mapping(uint224 => uint224)) public claimableVerifierEpochRewards; // Using uint224 to save gas

    // For governor change with timelock
    address public pendingGovernor;
    uint256 public governorProposalTime;
    uint256 public constant GOVERNOR_CHANGE_TIMELOCK = 7 days; // Example timelock for governor change

    // --- Events ---
    event ProtocolInitialized(address indexed _governor, address indexed _stakingToken, uint256 _epochDuration);
    event ProtocolParametersUpdated(uint256 _newEpochDuration, uint256 _newMinOptimizerStake, uint256 _newMinVerifierStake);
    event ObjectiveFunctionReferenceUpdated(bytes32 _newRef);
    event GovernorProposed(address indexed _newGovernor);
    event GovernorChanged(address indexed _oldGovernor, address indexed _newGovernor);
    event SystemPaused();
    event SystemUnpaused();
    event RewardWeightsUpdated(uint256 _optimizerWeight, uint256 _verifierWeight, uint256 _reputationFactor);
    event ProtocolFeesCollected(address indexed _collector, uint256 _amount);

    event EpochAdvanced(uint256 indexed _newEpochId, uint224 _startTime, uint224 _endTime, uint256 _winningStrategyId); // uint224 for timestamps to save gas

    event OptimizerRegistered(address indexed _optimizer, uint256 _stakeAmount);
    event StrategySubmitted(uint256 indexed _strategyId, address indexed _optimizer, uint224 indexed _epochId, string _strategyURI, uint256 _fee);
    event OptimizerStakeWithdrawn(address indexed _optimizer, uint256 _amount);
    event OptimizerRewardsClaimed(address indexed _optimizer, uint224 indexed _epochId, uint256 _amount);

    event VerifierRegistered(address indexed _verifier, uint256 _stakeAmount);
    event AssessmentSubmitted(uint256 indexed _assessmentId, address indexed _verifier, uint224 indexed _strategyId, int256 _score);
    event AssessmentDisputed(uint256 indexed _assessmentId, uint224 indexed _strategyId, address indexed _disputer, string _disputeURI, uint256 _disputeFee);
    event VerifierStakeWithdrawn(address indexed _verifier, uint252 _amount); // uint252 for balance
    event VerifierRewardsClaimed(address indexed _verifier, uint224 indexed _epochId, uint256 _amount);

    event OptimizerReputationUpdated(address indexed _optimizer, uint252 _oldReputation, uint252 _newReputation); // uint252 for reputation
    event VerifierReputationUpdated(address indexed _verifier, uint252 _oldReputation, uint252 _newReputation);

    // --- Custom Errors ---
    error ProtocolNotInitialized();
    error AlreadyInitialized();
    error InvalidEpochDuration();
    error InsufficientStake(uint256 required, uint256 provided);
    error AlreadyRegistered();
    error NotRegistered();
    error EpochNotActiveForSubmissions();
    error EpochNotActiveForAssessments();
    error StrategyNotFound();
    error StrategyNotInCurrentEpoch();
    error AssessmentNotFound();
    error AlreadyAssessedStrategy();
    error NotEnoughAssessments();
    error EpochNotYetEnded();
    error EpochAlreadyResolved();
    error EpochNotResolved();
    error NothingToWithdraw();
    error NothingToClaim();
    error InvalidGovernorProposal();
    error GovernorChangePending();
    error GovernorChangeNotReady();
    error Unauthorized();
    error InvalidRewardWeights();
    error InvalidPercentage();
    error StrategyNotYetAssessed();
    error CannotDisputeOwnAssessment();
    error AssessmentAlreadyDisputed();
    error DisputeFeeRequired(uint256 required);
    error EpochNotFound(); // Custom error for getEpochDetails

    // --- Constructor ---
    constructor(address _stakingTokenAddress) Ownable(msg.sender) {
        if (_stakingTokenAddress == address(0)) {
            revert ProtocolNotInitialized();
        }
        stakingToken = IERC20(_stakingTokenAddress);
        nextStrategyId = 1; // Start IDs from 1
        nextAssessmentId = 1;
    }

    // --- I. Core Protocol Management & Governance ---

    /**
     * @dev Initializes the protocol with core parameters. Can only be called once by the deployer.
     * @param _epochDuration The duration of each epoch in seconds. Must be greater than 0.
     * @param _minOptimizerStake The minimum amount of `stakingToken` required for an Optimizer to register.
     * @param _minVerifierStake The minimum amount of `stakingToken` required for a Verifier to register.
     * @param _initialObjectiveRef The initial IPFS CID or identifier for the optimization objective.
     */
    function initializeProtocol(
        uint256 _epochDuration,
        uint256 _minOptimizerStake,
        uint256 _minVerifierStake,
        bytes32 _initialObjectiveRef
    ) external onlyOwner {
        if (currentEpoch != 0) revert AlreadyInitialized();
        if (_epochDuration == 0) revert InvalidEpochDuration();

        epochDuration = _epochDuration;
        minOptimizerStake = _minOptimizerStake;
        minVerifierStake = _minVerifierStake;
        objectiveFunctionReference = _initialObjectiveRef;
        strategySubmissionFee = minOptimizerStake / 20; // Example: 5% of min optimizer stake

        // Set initial reward distribution weights (e.g., 60% optimizers, 40% verifiers)
        optimizerRewardWeight = 6000; // 60%
        verifierRewardWeight = 4000;  // 40%
        reputationImpactFactor = 100; // 1x impact by default (100 = 1.00)
        protocolFeePercentage = 500;  // 5%

        // Start the first epoch
        currentEpoch = 1;
        epochStartTime = block.timestamp;
        epochs[currentEpoch] = Epoch(currentEpoch, epochStartTime, epochStartTime + epochDuration, false, new uint256[](0), 0, 0);

        emit ProtocolInitialized(owner(), address(stakingToken), _epochDuration);
    }

    /**
     * @dev Allows the governor to update core protocol parameters in a batch.
     *      Requires the system not to be paused.
     * @param _newEpochDuration The new duration for epochs in seconds. Must be greater than 0.
     * @param _newMinOptimizerStake The new minimum stake for optimizers.
     * @param _newMinVerifierStake The new minimum stake for verifiers.
     */
    function updateProtocolParameters(
        uint256 _newEpochDuration,
        uint256 _newMinOptimizerStake,
        uint256 _newMinVerifierStake
    ) external onlyOwner whenNotPaused {
        if (_newEpochDuration == 0) revert InvalidEpochDuration();

        epochDuration = _newEpochDuration;
        minOptimizerStake = _newMinOptimizerStake;
        minVerifierStake = _newMinVerifierStake;
        strategySubmissionFee = _newMinOptimizerStake / 20; // Update submission fee accordingly

        emit ProtocolParametersUpdated(_newEpochDuration, _newMinOptimizerStake, _newMinVerifierStake);
    }

    /**
     * @dev Updates the reference (e.g., IPFS CID) pointing to the current optimization objective or AI model specification.
     *      This is a core mechanism for defining what Optimizers should aim for.
     *      Requires the system not to be paused.
     * @param _newObjectiveRef The new bytes32 identifier for the objective function.
     */
    function setObjectiveFunctionReference(bytes32 _newObjectiveRef) external onlyOwner whenNotPaused {
        objectiveFunctionReference = _newObjectiveRef;
        emit ObjectiveFunctionReferenceUpdated(_newObjectiveRef);
    }

    /**
     * @dev Initiates a change of the protocol's governor. This is a two-step process with a timelock
     *      to prevent immediate or accidental changes. Only the current governor can propose.
     * @param _newGovernor The address of the new governor.
     */
    function proposeGovernor(address _newGovernor) external onlyOwner {
        if (_newGovernor == address(0)) revert InvalidGovernorProposal();
        if (pendingGovernor != address(0)) revert GovernorChangePending(); // A proposal is already active

        pendingGovernor = _newGovernor;
        governorProposalTime = block.timestamp;
        emit GovernorProposed(_newGovernor);
    }

    /**
     * @dev Finalizes the governor change after the predefined timelock has passed.
     *      Can only be called by the current governor.
     */
    function finalizeGovernorChange() external onlyOwner {
        if (pendingGovernor == address(0)) revert GovernorChangeNotReady();
        if (block.timestamp < governorProposalTime + GOVERNOR_CHANGE_TIMELOCK) revert GovernorChangeNotReady();

        address oldGovernor = owner();
        transferOwnership(pendingGovernor); // OpenZeppelin's transferOwnership handles setting `owner`
        pendingGovernor = address(0);
        governorProposalTime = 0;
        emit GovernorChanged(oldGovernor, owner());
    }

    /**
     * @dev Emergency function to pause critical operations of the protocol.
     *      Only the governor can call this.
     */
    function pauseSystem() external onlyOwner {
        _pause();
        emit SystemPaused();
    }

    /**
     * @dev Resumes protocol operations after a pause.
     *      Only the governor can call this.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
        emit SystemUnpaused();
    }

    /**
     * @dev Sets the weights for how rewards are distributed between optimizers and verifiers,
     *      and how much reputation influences these distributions. Weights are in basis points (e.g., 6000 for 60%).
     *      The sum of optimizerWeight and verifierWeight must equal 10000 (100%).
     *      Requires the system not to be paused.
     * @param _optimizerWeight The weight for optimizers in basis points.
     * @param _verifierWeight The weight for verifiers in basis points.
     * @param _reputationFactor The multiplier for reputation's impact on rewards/penalties, in basis points (100 = 1x).
     */
    function setRewardDistributionWeights(
        uint256 _optimizerWeight,
        uint256 _verifierWeight,
        uint256 _reputationFactor
    ) external onlyOwner whenNotPaused {
        if (_optimizerWeight + _verifierWeight != 10000) revert InvalidRewardWeights();
        if (_reputationFactor == 0) revert InvalidRewardWeights(); // Reputation factor must be positive

        optimizerRewardWeight = _optimizerWeight;
        verifierRewardWeight = _verifierWeight;
        reputationImpactFactor = _reputationFactor;
        emit RewardWeightsUpdated(_optimizerWeight, _verifierWeight, _reputationFactor);
    }

    /**
     * @dev Allows the governor to collect accumulated protocol fees.
     *      These fees are collected from strategy submission fees and a percentage of rewards/penalties.
     */
    function collectProtocolFees() external onlyOwner {
        uint256 amount = protocolFeeBalance;
        if (amount == 0) revert NothingToWithdraw();

        protocolFeeBalance = 0;
        require(stakingToken.transfer(owner(), amount), "Fee transfer failed");
        emit ProtocolFeesCollected(owner(), amount);
    }

    // --- II. Epoch Management & Resolution ---

    /**
     * @dev Advances the protocol to the next epoch. This function can be called by anyone
     *      once the current epoch's end time has passed. It triggers the resolution logic
     *      for the previous epoch, including reward calculations, reputation updates, and penalties.
     *      This is a complex function handling core game theory and incentive alignment.
     *      It ensures the previous epoch is resolved before starting a new one.
     */
    function advanceEpoch() external nonReentrant whenNotPaused {
        Epoch storage current = epochs[currentEpoch];
        if (block.timestamp < current.endTime) revert EpochNotYetEnded();
        if (current.resolved) revert EpochAlreadyResolved();

        // 1. Resolve the current epoch (currentEpoch)
        // Determine the winning strategy and calculate rewards/penalties

        uint256 winningStrategyId = 0;
        int256 highestScore = type(int256).min; // Initialize with smallest possible int256
        uint256 totalActiveOptimizerReputation = 0; // For proportional reward distribution

        // Find the winning strategy and sum active optimizer reputations
        for (uint252 i = 0; i < current.strategyIds.length; i++) { // Using uint252 for loop variable to save gas
            uint256 sId = current.strategyIds[i];
            Strategy storage strategy = strategies[sId];

            // Only consider strategies that have been sufficiently assessed and not disputed
            if (strategy.status == StrategyStatus.Assessed) {
                if (strategy.aggregatedScore > highestScore) {
                    highestScore = strategy.aggregatedScore;
                    winningStrategyId = sId;
                }
                if (optimizers[strategy.optimizer].isActive) {
                    totalActiveOptimizerReputation += optimizers[strategy.optimizer].reputation;
                }
            }
        }

        current.winningStrategyId = winningStrategyId;
        current.resolved = true; // Mark epoch as resolved regardless of outcome

        uint256 totalAvailableRewards = stakingToken.balanceOf(address(this)); // Entire balance in contract
        // Adjust for existing protocol fees already accumulated
        totalAvailableRewards = totalAvailableRewards > protocolFeeBalance ? totalAvailableRewards - protocolFeeBalance : 0;

        if (winningStrategyId == 0) {
            // No winning strategy (e.g., no valid strategies or no assessments).
            // Rewards remain undistributed in the contract for future epochs, or could be burned/redirected.
            // No specific reputation changes if no clear winner.
            // For now, these funds will implicitly increase the pool for the next epoch.
            // No rewards are logged as distributed for this epoch.
            current.totalRewardsDistributed = 0;
        } else {
            // --- Reward Distribution & Reputation Updates ---
            Strategy storage winningStrategy = strategies[winningStrategyId];
            winningStrategy.status = StrategyStatus.Resolved;

            // Calculate portions for optimizers and verifiers
            uint256 totalOptimizerPool = (totalAvailableRewards * optimizerRewardWeight) / 10000;
            uint256 totalVerifierPool = (totalAvailableRewards * verifierRewardWeight) / 10000;

            // Apply protocol fees before individual distribution
            uint256 optimizerFees = (totalOptimizerPool * protocolFeePercentage) / 10000;
            uint256 verifierFees = (totalVerifierPool * protocolFeePercentage) / 10000;
            protocolFeeBalance += (optimizerFees + verifierFees);

            totalOptimizerPool -= optimizerFees;
            totalVerifierPool -= verifierFees;

            current.totalRewardsDistributed = totalOptimizerPool + totalVerifierPool;

            // 1. Optimize Rewards for Winning Optimizer
            uint256 optimizerReward = 0;
            if (totalActiveOptimizerReputation > 0) {
                uint256 winningOptimizerRep = optimizers[winningStrategy.optimizer].reputation;
                optimizerReward = (totalOptimizerPool * winningOptimizerRep) / totalActiveOptimizerReputation;
            }
            
            // Cast currentEpoch to uint224 for mapping key
            claimableOptimizerEpochRewards[winningStrategy.optimizer][uint224(currentEpoch)] += uint224(optimizerReward);
            optimizers[winningStrategy.optimizer].totalClaimedRewards += optimizerReward;

            // Update Optimizer Reputation: Winning optimizer gains reputation
            uint256 oldOptimizerRep = optimizers[winningStrategy.optimizer].reputation;
            optimizers[winningStrategy.optimizer].reputation += (100 * reputationImpactFactor / 100); // Base gain adjusted by factor
            emit OptimizerReputationUpdated(winningStrategy.optimizer, uint252(oldOptimizerRep), uint252(optimizers[winningStrategy.optimizer].reputation));

            // 2. Reward Verifiers & Update Verifier Reputation
            mapping(address => uint256) verifierAccuracyScores; // Temporary to sum accuracy weighted by reputation
            uint256 totalWeightedAccuracyScore = 0;

            for (uint252 i = 0; i < current.strategyIds.length; i++) { // Using uint252 for loop variable to save gas
                uint256 sId = current.strategyIds[i];
                Strategy storage strategy = strategies[sId];

                // Consider only strategies that were assessed and not disputed
                if (strategy.status == StrategyStatus.Assessed || strategy.id == winningStrategyId) {
                    for (uint252 j = 0; j < strategy.assessmentIds.length; j++) { // Using uint252 for loop variable to save gas
                        uint256 aId = strategy.assessmentIds[j];
                        Assessment storage assessment = assessments[aId];
                        if (assessment.disputed || assessment.rewarded) continue; // Skip disputed or already rewarded

                        address verifierAddr = assessment.verifier;
                        if (!verifiers[verifierAddr].isActive) continue; // Only consider active verifiers

                        uint256 verifierRep = verifiers[verifierAddr].reputation;
                        if (verifierRep == 0) verifierRep = 1; // Avoid division by zero, ensure base reputation always active

                        // Simplified accuracy calculation: how close the verifier's score was to the winning strategy's aggregated score
                        // More sophisticated logic needed for complex scenarios (e.g., normalized scores, statistical methods)
                        int256 scoreDiff = winningStrategy.aggregatedScore - assessment.score;
                        uint256 accuracyPoints = 0;
                        if (scoreDiff == 0) {
                            accuracyPoints = 1000; // Max points for perfect match
                        } else {
                            // Example: accuracy reduces linearly with difference. Assumes scores are within a known range.
                            // A higher `accuracyPoints` means better assessment.
                            uint256 absDiff = uint256(scoreDiff > 0 ? scoreDiff : -scoreDiff);
                            accuracyPoints = absDiff < 1000 ? (1000 - absDiff) : 0; // If score range implies 1000 is max diff
                        }
                        
                        uint256 weightedAccuracy = (accuracyPoints * verifierRep * reputationImpactFactor) / 10000; // Factor in reputation
                        verifierAccuracyScores[verifierAddr] += weightedAccuracy;
                        totalWeightedAccuracyScore += weightedAccuracy;
                    }
                }
            }

            // Distribute verifier rewards based on weighted accuracy
            for (uint252 i = 0; i < current.strategyIds.length; i++) { // Using uint252 for loop variable to save gas
                uint256 sId = current.strategyIds[i];
                Strategy storage strategy = strategies[sId];
                if (strategy.status == StrategyStatus.Assessed || strategy.id == winningStrategyId) { // Re-check relevant strategies
                    for (uint252 j = 0; j < strategy.assessmentIds.length; j++) { // Using uint252 for loop variable to save gas
                        uint256 aId = strategy.assessmentIds[j];
                        Assessment storage assessment = assessments[aId];
                        if (assessment.disputed || assessment.rewarded) continue;

                        address verifierAddr = assessment.verifier;
                        if (!verifiers[verifierAddr].isActive) continue;

                        uint256 individualVerifierReward = 0;
                        if (totalWeightedAccuracyScore > 0) {
                            individualVerifierReward = (totalVerifierPool * verifierAccuracyScores[verifierAddr]) / totalWeightedAccuracyScore;
                        }

                        // Cast currentEpoch to uint224 for mapping key
                        claimableVerifierEpochRewards[verifierAddr][uint224(currentEpoch)] += uint224(individualVerifierReward);
                        verifiers[verifierAddr].totalClaimedRewards += individualVerifierReward;
                        assessment.rewarded = true; // Mark as rewarded

                        // Update verifier reputation (gain for accuracy, loss for inaccuracy)
                        uint256 oldVerifierRep = verifiers[verifierAddr].reputation;
                        // Example: Gaining reputation if score was close to winning strategy's
                        if (winningStrategy.id == sId && assessment.score == winningStrategy.aggregatedScore) {
                             verifiers[verifierAddr].reputation += (50 * reputationImpactFactor / 100);
                        } else if (winningStrategy.id != sId && assessment.score == winningStrategy.aggregatedScore) {
                            // Potentially penalize if they gave a high score to a losing strategy, even if accurate to its aggregate
                            // For simplicity, only positive reputation for good assessments.
                        } else {
                            // Slight reputation decay or penalty for inaccurate assessments
                            if (verifiers[verifierAddr].reputation > 100) verifiers[verifierAddr].reputation -= (10 * reputationImpactFactor / 100);
                        }
                        emit VerifierReputationUpdated(verifierAddr, uint252(oldVerifierRep), uint252(verifiers[verifierAddr].reputation));
                    }
                }
            }
        }

        // 2. Start the new epoch (currentEpoch + 1)
        currentEpoch++;
        epochStartTime = block.timestamp;
        epochs[currentEpoch] = Epoch(currentEpoch, epochStartTime, epochStartTime + epochDuration, false, new uint256[](0), 0, 0);

        // Cast timestamps to uint224 for event
        emit EpochAdvanced(currentEpoch, uint224(epochStartTime), uint224(epochStartTime + epochDuration), winningStrategyId);
    }

    /**
     * @dev Retrieves details about a specific epoch.
     * @param _epochNum The ID of the epoch to query.
     * @return A tuple containing all details of the Epoch struct.
     */
    function getEpochDetails(uint256 _epochNum) external view returns (Epoch memory) {
        if (_epochNum == 0 || _epochNum > currentEpoch) revert EpochNotFound(); // Assume no epoch 0
        return epochs[_epochNum];
    }

    // --- III. Optimizer Role Functions ---

    /**
     * @dev Allows an address to register as an Optimizer by staking `_amount` of `stakingToken`.
     *      The amount must be at least `minOptimizerStake`.
     *      Requires the caller to have approved this contract to spend the `stakingToken`.
     *      Requires the system not to be paused.
     * @param _amount The amount of `stakingToken` to stake.
     */
    function registerOptimizer(uint256 _amount) external nonReentrant whenNotPaused {
        if (optimizers[msg.sender].isActive) revert AlreadyRegistered();
        if (_amount < minOptimizerStake) revert InsufficientStake(minOptimizerStake, _amount);

        optimizers[msg.sender] = Participant(msg.sender, _amount, 1000, true, 0); // Initial reputation 1000
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        emit OptimizerRegistered(msg.sender, _amount);
    }

    /**
     * @dev Allows an Optimizer to submit a new optimization strategy for the current epoch.
     *      Requires payment of `strategySubmissionFee` in `stakingToken`.
     *      Requires the caller to have approved this contract to spend the `stakingToken`.
     *      Requires the system not to be paused.
     * @param _strategyURI The URI (e.g., IPFS CID) pointing to the strategy's description/code.
     */
    function submitStrategy(string memory _strategyURI) external nonReentrant whenNotPaused {
        if (!optimizers[msg.sender].isActive) revert NotRegistered();
        if (block.timestamp >= epochs[currentEpoch].endTime) revert EpochNotActiveForSubmissions();
        if (strategySubmissionFee > 0) {
            require(stakingToken.transferFrom(msg.sender, address(this), strategySubmissionFee), "Strategy fee transfer failed");
            protocolFeeBalance += strategySubmissionFee; // Collect as protocol fee
        }
        
        uint256 sId = nextStrategyId++;
        strategies[sId] = Strategy(sId, msg.sender, currentEpoch, _strategyURI, StrategyStatus.Pending, new uint256[](0), 0, 0);
        epochs[currentEpoch].strategyIds.push(sId);

        // Cast currentEpoch to uint224 for event
        emit StrategySubmitted(sId, msg.sender, uint224(currentEpoch), _strategyURI, strategySubmissionFee);
    }

    /**
     * @dev Allows an Optimizer to withdraw their registration stake.
     *      Can only be done if they are no longer an active participant or after all their
     *      associated strategies have been fully resolved and funds are available.
     *      Requires the system not to be paused.
     */
    function withdrawOptimizerStake() external nonReentrant whenNotPaused {
        // A more robust system would check if any active strategies or pending resolutions
        // For simplicity, we assume they can withdraw if `isActive` is false or no pending participation
        if (!optimizers[msg.sender].isActive) revert NotRegistered();

        uint256 amount = optimizers[msg.sender].totalStaked;
        if (amount == 0) revert NothingToWithdraw();

        optimizers[msg.sender].totalStaked = 0;
        optimizers[msg.sender].isActive = false; // Deactivate after full withdrawal
        
        require(stakingToken.transfer(msg.sender, amount), "Stake withdrawal failed");
        emit OptimizerStakeWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows an Optimizer to claim their rewards from a specific resolved epoch.
     *      Must be a past and resolved epoch. Requires the system not to be paused.
     * @param _epochNumber The epoch from which to claim rewards.
     */
    function claimOptimizerRewards(uint256 _epochNumber) external nonReentrant whenNotPaused {
        if (!optimizers[msg.sender].isActive) revert NotRegistered();
        if (_epochNumber == 0 || _epochNumber >= currentEpoch) revert EpochNotResolved();
        if (!epochs[_epochNumber].resolved) revert EpochNotResolved();

        // Cast _epochNumber to uint224 for mapping key
        uint256 amount = claimableOptimizerEpochRewards[msg.sender][uint224(_epochNumber)];
        if (amount == 0) revert NothingToClaim();

        claimableOptimizerEpochRewards[msg.sender][uint224(_epochNumber)] = 0; // Prevent double claiming
        optimizers[msg.sender].totalClaimedRewards += amount;

        require(stakingToken.transfer(msg.sender, amount), "Reward claim failed");
        emit OptimizerRewardsClaimed(msg.sender, uint224(_epochNumber), amount);
    }

    // --- IV. Verifier Role Functions ---

    /**
     * @dev Allows an address to register as a Verifier by staking `_amount` of `stakingToken`.
     *      The amount must be at least `minVerifierStake`.
     *      Requires the caller to have approved this contract to spend the `stakingToken`.
     *      Requires the system not to be paused.
     * @param _amount The amount of `stakingToken` to stake.
     */
    function registerVerifier(uint256 _amount) external nonReentrant whenNotPaused {
        if (verifiers[msg.sender].isActive) revert AlreadyRegistered();
        if (_amount < minVerifierStake) revert InsufficientStake(minVerifierStake, _amount);

        verifiers[msg.sender] = Participant(msg.sender, _amount, 1000, true, 0); // Initial reputation 1000
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        emit VerifierRegistered(msg.sender, _amount);
    }

    /**
     * @dev Allows a Verifier to submit an assessment for a specific strategy in the current epoch.
     *      Verifiers are incentivized to provide accurate and honest assessments.
     *      Requires the system not to be paused.
     * @param _strategyId The ID of the strategy being assessed.
     * @param _score The verifier's score for the strategy (e.g., -100 to 100, or 0 to 10000).
     * @param _assessmentURI The URI (e.g., IPFS CID) pointing to the detailed assessment report.
     */
    function submitAssessment(
        uint256 _strategyId,
        int256 _score,
        string memory _assessmentURI
    ) external nonReentrant whenNotPaused {
        if (!verifiers[msg.sender].isActive) revert NotRegistered();
        if (block.timestamp >= epochs[currentEpoch].endTime) revert EpochNotActiveForAssessments();

        Strategy storage strategy = strategies[_strategyId];
        if (strategy.id == 0 || strategy.epochId != currentEpoch) revert StrategyNotFound(); // Checks strategy existence and current epoch

        // Check if this verifier has already assessed this strategy in this epoch
        for (uint252 i = 0; i < strategy.assessmentIds.length; i++) { // Using uint252 for loop variable to save gas
            if (assessments[strategy.assessmentIds[i]].verifier == msg.sender) {
                revert AlreadyAssessedStrategy();
            }
        }

        uint256 aId = nextAssessmentId++;
        assessments[aId] = Assessment(aId, msg.sender, _strategyId, currentEpoch, _score, _assessmentURI, false, false);
        strategy.assessmentIds.push(aId);
        strategy.aggregatedScore += _score; // Simple aggregation. More complex logic might use median, weighted average, etc.

        // If enough assessments, mark strategy as assessed (e.g., 3 is a common threshold)
        if (strategy.assessmentIds.length >= 3) { // This threshold could be a configurable protocol parameter
            strategy.status = StrategyStatus.Assessed;
        }

        // Cast _strategyId to uint224 for event
        emit AssessmentSubmitted(aId, msg.sender, uint224(_strategyId), _score);
    }

    /**
     * @dev Allows an Optimizer or another Verifier to dispute an assessment.
     *      This requires a dispute fee in native currency (ETH/MATIC etc.) to prevent spam.
     *      This implies an off-chain arbitration process or a governor's decision
     *      will be needed to resolve the dispute, which would then update the assessment's status.
     *      Requires the system not to be paused.
     * @param _epochNumber The epoch where the disputed assessment took place.
     * @param _strategyId The ID of the strategy involved.
     * @param _assessmentId The ID of the assessment being disputed.
     * @param _disputeURI The URI (e.g., IPFS CID) pointing to the detailed dispute rationale.
     */
    function disputeAssessment(
        uint256 _epochNumber,
        uint256 _strategyId,
        uint256 _assessmentId,
        string memory _disputeURI
    ) external payable nonReentrant whenNotPaused {
        if (_epochNumber >= currentEpoch) revert EpochNotYetEnded(); // Can only dispute past epoch assessments
        if (epochs[_epochNumber].resolved) revert EpochAlreadyResolved(); // Cannot dispute a resolved epoch

        Assessment storage assessment = assessments[_assessmentId];
        if (assessment.id == 0 || assessment.epochId != _epochNumber || assessment.strategyId != _strategyId) revert AssessmentNotFound();
        if (assessment.verifier == msg.sender) revert CannotDisputeOwnAssessment();
        if (assessment.disputed) revert AssessmentAlreadyDisputed();

        // A dispute fee is required to prevent spam
        uint256 disputeFee = minVerifierStake / 10; // Example: 10% of min verifier stake, paid in native currency
        if (msg.value < disputeFee) revert DisputeFeeRequired(disputeFee);

        assessment.disputed = true;
        strategies[_strategyId].status = StrategyStatus.Disputed; // Mark strategy as disputed

        // Dispute fees go to the protocol for arbitration costs or as a burning mechanism.
        // For simplicity, it just adds to the contracts native token balance.
        // In a real system, these would be managed by the treasury or DAO.

        // Cast _strategyId to uint224 for event
        emit AssessmentDisputed(_assessmentId, uint224(_strategyId), msg.sender, _disputeURI, msg.value);
    }

    /**
     * @dev Allows a Verifier to withdraw their registration stake.
     *      Can only be done if they are no longer an active participant or after all their
     *      associated assessments have been fully resolved and funds are available.
     *      Requires the system not to be paused.
     */
    function withdrawVerifierStake() external nonReentrant whenNotPaused {
        if (!verifiers[msg.sender].isActive) revert NotRegistered();

        uint256 amount = verifiers[msg.sender].totalStaked;
        if (amount == 0) revert NothingToWithdraw();

        verifiers[msg.sender].totalStaked = 0;
        verifiers[msg.sender].isActive = false;

        require(stakingToken.transfer(msg.sender, amount), "Stake withdrawal failed");
        emit VerifierStakeWithdrawn(msg.sender, uint252(amount));
    }

    /**
     * @dev Allows a Verifier to claim their rewards from a specific resolved epoch.
     *      Must be a past and resolved epoch. Requires the system not to be paused.
     * @param _epochNumber The epoch from which to claim rewards.
     */
    function claimVerifierRewards(uint256 _epochNumber) external nonReentrant whenNotPaused {
        if (!verifiers[msg.sender].isActive) revert NotRegistered();
        if (_epochNumber == 0 || _epochNumber >= currentEpoch) revert EpochNotResolved();
        if (!epochs[_epochNumber].resolved) revert EpochNotResolved();

        // Cast _epochNumber to uint224 for mapping key
        uint256 amount = claimableVerifierEpochRewards[msg.sender][uint224(_epochNumber)];
        if (amount == 0) revert NothingToClaim();

        claimableVerifierEpochRewards[msg.sender][uint224(_epochNumber)] = 0; // Prevent double claiming
        verifiers[msg.sender].totalClaimedRewards += amount;

        require(stakingToken.transfer(msg.sender, amount), "Reward claim failed");
        emit VerifierRewardsClaimed(msg.sender, uint224(_epochNumber), amount);
    }

    // --- V. Reputation (SBT-like) & State Queries ---

    /**
     * @dev Returns the current non-transferable reputation score of an Optimizer.
     * @param _optimizer The address of the optimizer.
     * @return The reputation score.
     */
    function getOptimizerReputation(address _optimizer) external view returns (uint256) {
        return optimizers[_optimizer].reputation;
    }

    /**
     * @dev Returns the current non-transferable reputation score of a Verifier.
     * @param _verifier The address of the verifier.
     * @return The reputation score.
     */
    function getVerifierReputation(address _verifier) external view returns (uint256) {
        return verifiers[_verifier].reputation;
    }

    /**
     * @dev Returns the current status of a specific strategy.
     * @param _strategyId The ID of the strategy.
     * @return The StrategyStatus enum value.
     */
    function getStrategyStatus(uint256 _strategyId) external view returns (StrategyStatus) {
        if (strategies[_strategyId].id == 0) revert StrategyNotFound();
        return strategies[_strategyId].status;
    }

    /**
     * @dev Returns the total amount of `stakingToken` currently staked by a given participant address.
     *      Checks if the address is registered as an Optimizer or a Verifier.
     * @param _participant The address of the participant.
     * @return The total staked amount. Returns 0 if the address is not an active participant or has no stake.
     */
    function getCurrentStakes(address _participant) external view returns (uint256) {
        // Return stake for Optimizer if active
        if (optimizers[_participant].isActive) {
            return optimizers[_participant].totalStaked;
        }
        // Return stake for Verifier if active
        if (verifiers[_participant].isActive) {
            return verifiers[_participant].totalStaked;
        }
        return 0; // Not an active participant or no stake
    }

    /**
     * @dev Returns the identifier of the epoch currently active for submissions and assessments.
     * @return The current epoch number.
     */
    function getCurrentEpochNumber() external view returns (uint256) {
        return currentEpoch;
    }
}
```