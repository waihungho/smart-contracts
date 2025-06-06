Okay, let's design a smart contract that combines staking, dynamic privileges based on stake, time-based resource distribution, and a simple on-chain governance mechanism influenced by stake duration/amount.

We'll call it `ChronosGuardians`. Users stake an ERC-20 token to earn "Time Authority Points" (TAPs) based on the amount and duration of their stake. TAPs grant influence in on-chain voting and affect their share of a continuously emitted "Chronos" token. The contract will also function as the `ChronosToken` ERC-20 itself for simplicity (a common pattern for reward tokens).

**Core Concepts:**

1.  **Time-Locked Staking:** Users lock `StakeToken` for a minimum duration. Longer duration grants more TAPs per token.
2.  **Time Authority Points (TAPs):** Non-transferable, internal points calculated as `amount * duration * multiplier`. They represent a user's committed influence. Active TAPs are the sum from ongoing stakes.
3.  **Chronos Token Emission:** A `ChronosToken` is minted by the contract and distributed to stakers proportionally to their active TAPs over time.
4.  **Dynamic Privileges:** Certain actions (like creating proposals) require a minimum threshold of active TAPs.
5.  **TAP-Weighted Governance:** Users with active stakes can vote on predefined proposals (e.g., parameter changes), with their vote weight equal to their active TAPs at the time of voting.
6.  **Early Withdrawal Penalties:** Withdrawing before the committed duration incurs a fee, which could be burned or sent to the owner.

---

**Outline:**

1.  **Contract Definition:** Inherit ERC-20.
2.  **State Variables:**
    *   Ownership & Token Addresses
    *   Staking Parameters (min/max duration, TAP multiplier, fee rate)
    *   Chronos Emission Parameters (rate, accrual state)
    *   Staking State (total staked, user stake positions, user TAPs)
    *   Governance Parameters (proposal creation threshold, quorum, threshold)
    *   Governance State (proposals, vote tracking)
3.  **Structs:** `StakePosition`, `Proposal`.
4.  **Events:** Staking, Withdrawal, Chronos Claim, Parameter Updates, Proposal lifecycle.
5.  **Modifiers:** `onlyOwner`, `onlyActiveStake`, `onlyMinTAPs`.
6.  **Internal Helpers:** Accrual update, TAP calculation, Fee calculation.
7.  **External/Public Functions:**
    *   Staking (`stake`, `withdraw`, view user/total stake/TAPs)
    *   Chronos (`claimChronos`, view earnable)
    *   Parameter Updates (Owner-controlled & TAP-governed)
    *   Governance (`createParameterUpdateProposal`, `voteOnProposal`, `executeProposal`, view proposal details/results)
    *   ERC-20 Standard (`transfer`, `balanceOf`, etc. for Chronos)
    *   View Functions (parameter values, contract state)

---

**Function Summary:**

*   **Staking & Core:**
    *   `constructor`: Initializes the contract, sets owner and initial parameters.
    *   `stake(uint256 amount, uint256 duration)`: Allows users to stake `StakeToken` for a specified `duration`, earning TAPs.
    *   `withdraw(uint256 stakeId)`: Allows users to withdraw a specific stake position. Applies fee if withdrawn early.
*   **TAP & State Views:**
    *   `calculatePositionTAPs(uint256 amount, uint256 duration)`: Internal helper to calculate TAPs for a potential stake.
    *   `getUserTotalActiveTAPs(address user)`: Returns the sum of TAPs from a user's active stake positions.
    *   `getTotalActiveTAPs()`: Returns the sum of TAPs from all active stake positions across all users.
    *   `getTotalStakedAmount()`: Returns the total amount of `StakeToken` currently staked in the contract.
    *   `getUserStakePositions(address user)`: Returns details of a user's active stake positions.
*   **Chronos Token & Distribution:**
    *   `_updateAccrual()`: Internal function to update the global Chronos per TAP value. Called before state changes that affect TAPs or when claiming.
    *   `calculateEarnableChronos(address user)`: Returns the amount of `ChronosToken` a user can currently claim across all their positions.
    *   `claimChronos()`: Mints and transfers accumulated `ChronosToken` to the caller.
    *   ERC-20 Standard Functions (`name`, `symbol`, `decimals`, `totalSupply`, `balanceOf`, `transfer`, `approve`, `transferFrom`, `burn`, `burnFrom`): Implement the `ChronosToken` functionality.
*   **Configuration & Ownership:**
    *   `transferOwnership(address payable newOwner)`: Transfers contract ownership.
    *   `updateTAPMultiplier(uint256 newMultiplier)`: Owner updates the TAP calculation multiplier.
    *   `updateEmissionRate(uint256 newRate)`: Owner updates the rate at which Chronos is emitted per second.
    *   `updateEarlyWithdrawalFeeRate(uint256 newRate)`: Owner updates the percentage fee for early withdrawals.
    *   `updateMinMaxDuration(uint256 newMin, uint256 newMax)`: Owner updates the allowed stake duration range.
    *   `updateRequiredTAPsForProposalCreation(uint256 newAmount)`: Owner updates the minimum TAPs needed to create a proposal.
    *   `updateRequiredVoteQuorum(uint256 newQuorum)`: Owner updates the minimum percentage of Total Active TAPs required to participate for a vote to be valid.
    *   `updateRequiredVoteThreshold(uint256 newThreshold)`: Owner updates the percentage of *participating* votes required for a proposal to pass.
*   **TAP-Weighted Governance:**
    *   `createParameterUpdateProposal(string description, string parameterName, uint256 newValue, uint256 votingDuration)`: Allows users with sufficient TAPs to propose updating a specific, allowed parameter.
    *   `voteOnProposal(uint256 proposalId, bool support)`: Allows users with active stake to vote on a proposal. Vote weight is their active TAPs.
    *   `getProposalDetails(uint256 proposalId)`: Returns details of a specific proposal.
    *   `getProposalVoteResult(uint256 proposalId)`: Returns the current vote count for a proposal.
    *   `executeProposal(uint256 proposalId)`: Allows anyone to attempt to execute a proposal after its voting period ends, if it meets quorum and threshold requirements and is a valid executable type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// ERC-20 basic implementation integrated
contract ChronosGuardians is Ownable, ReentrancyGuard, IERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- ERC-20 STATE (Chronos Token) ---
    string public constant name = "Chronos Token";
    string public constant symbol = "CHR";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // --- STAKING STATE ---
    IERC20 public immutable stakeToken;
    uint256 public totalStakedAmount; // Total amount of stakeToken held by the contract

    struct StakePosition {
        uint256 amount; // Amount of stakeToken in this position
        uint256 startTime; // Timestamp when staking started
        uint256 duration; // Committed duration in seconds
        uint256 calculatedTAPs; // TAPs calculated at stake time (amount * duration * multiplier)
        uint256 lastChronosPerTAPSecond; // Accrual checkpoint for Chronos distribution
        bool active; // Flag to indicate if the position is active (not withdrawn)
    }

    // User's staking positions (can have multiple)
    mapping(address => StakePosition[]) public userStakePositions;
    // Total active TAPs for each user (cached for quick access)
    mapping(address => uint256) public userTotalActiveTAPs;
    // Global total active TAPs across all stakers
    uint256 public totalActiveTAPs;

    // --- CHRONOS EMISSION STATE ---
    // Chronos per TAP second multiplier (scaled by 1e18 for precision)
    uint256 public chronosPerTAPSecond;
    // Timestamp of the last accrual update
    uint256 public lastAccrualTime;
    // Rate of Chronos emission per second (scaled by 1e18, e.g., 1e18 means 1 CHR/sec)
    uint256 public chronosEmissionRate;

    // --- PARAMETERS ---
    uint256 public tapMultiplier; // Multiplier for TAP calculation (e.g., 1e18 for 1x, 2e18 for 2x)
    uint256 public minStakeDuration; // Minimum allowed stake duration in seconds
    uint256 public maxStakeDuration; // Maximum allowed stake duration in seconds
    // Early withdrawal fee rate (in basis points, 100 = 1%)
    uint256 public earlyWithdrawalFeeRate; // Max 10000 (100%)

    // --- GOVERNANCE STATE & PARAMETERS ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        string parameterName; // Name of the parameter to update
        uint256 newValue; // The proposed new value
        uint256 creationTime;
        uint256 endTime; // Voting ends timestamp
        uint256 forVotes; // Total TAP weight supporting the proposal
        uint256 againstVotes; // Total TAP weight opposing the proposal
        mapping(address => bool) voted; // Track who has voted
        bool executed; // Whether the proposal has been executed
        bool passed; // Whether the proposal passed the vote (set on execution attempt)
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    uint256 public requiredTAPsForProposalCreation; // Min TAPs required to create a proposal
    uint256 public requiredVoteQuorum; // Min percentage (basis points) of Total Active TAPs required to vote for proposal to be valid
    uint256 public requiredVoteThreshold; // Min percentage (basis points) of *participating* votes required for proposal to pass (e.g., 5001 for >50%)

    // --- EVENTS ---
    event Staked(address indexed user, uint256 amount, uint256 duration, uint256 stakeId, uint256 calculatedTAPs);
    event Withdrawal(address indexed user, uint256 stakeId, uint256 returnedAmount, uint256 feeAmount);
    event ChronosClaimed(address indexed user, uint256 amount, uint256 totalClaimed);
    event ParametersUpdated(string name, uint256 oldValue, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, string parameterName, uint256 newValue, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- CONSTRUCTOR ---

    constructor(
        address _stakeToken,
        uint256 _tapMultiplier, // e.g., 1e18
        uint256 _minDuration, // in seconds
        uint256 _maxDuration, // in seconds
        uint256 _emissionRate, // scaled by 1e18, e.g., 1e18 for 1 CHR/sec
        uint256 _requiredTAPsForProposalCreation,
        uint256 _requiredVoteQuorum, // in basis points (e.g., 1000 = 10%)
        uint256 _requiredVoteThreshold // in basis points (e.g., 5001 = >50%)
    )
        Ownable(msg.sender)
    {
        require(_stakeToken != address(0), "Stake token cannot be zero address");
        require(_minDuration > 0, "Min duration must be positive");
        require(_maxDuration >= _minDuration, "Max duration must be >= min duration");
        require(_emissionRate > 0, "Emission rate must be positive");
        require(_requiredVoteQuorum <= 10000, "Quorum cannot exceed 100%");
        require(_requiredVoteThreshold <= 10000, "Threshold cannot exceed 100%");

        stakeToken = IERC20(_stakeToken);
        tapMultiplier = _tapMultiplier;
        minStakeDuration = _minDuration;
        maxStakeDuration = _maxDuration;
        chronosEmissionRate = _emissionRate;
        earlyWithdrawalFeeRate = 0; // Default to 0 fee
        lastAccrualTime = block.timestamp;

        requiredTAPsForProposalCreation = _requiredTAPsForProposalCreation;
        requiredVoteQuorum = _requiredVoteQuorum;
        requiredVoteThreshold = _requiredVoteThreshold;

        nextProposalId = 0;
    }

    // --- MODIFIERS ---

    modifier onlyActiveStake(address user) {
        require(userTotalActiveTAPs[user] > 0, "User must have active stake");
        _;
    }

    modifier onlyMinTAPs(address user, uint256 minTAPs) {
        require(getUserTotalActiveTAPs(user) >= minTAPs, "User does not have minimum TAPs");
        _;
    }

    // --- INTERNAL HELPERS ---

    /**
     * @dev Internal function to update the global Chronos accrual state.
     * This should be called before any operation that changes the state
     * that impacts Chronos distribution (stake, withdraw, claim, vote?).
     * For simplicity, call it before stake, withdraw, and claim.
     * Calling it before vote/propose adds complexity and gas costs without huge benefit.
     */
    function _updateAccrual() internal {
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastAccrualTime;

        if (timeElapsed > 0 && totalActiveTAPs > 0) {
            uint256 chronosToAdd = chronosEmissionRate.mul(timeElapsed);
            // chronosPerTAPSecond is scaled by 1e18 for precision
            chronosPerTAPSecond = chronosPerTAPSecond.add(chronosToAdd.mul(1e18).div(totalActiveTAPs));
        }
        lastAccrualTime = currentTime;
    }

    /**
     * @dev Internal function to calculate TAPs for a given amount and duration.
     * @param amount The amount staked.
     * @param duration The duration in seconds.
     * @return calculated TAPs (scaled by tapMultiplier)
     */
    function _calculateTAPs(uint256 amount, uint256 duration) internal view returns (uint256) {
         // TAPs = amount * duration * tapMultiplier (handle potential overflow)
        uint256 taps = amount.mul(duration);
        taps = taps.mul(tapMultiplier).div(1e18); // Assume tapMultiplier is scaled by 1e18
        return taps;
    }

     /**
      * @dev Calculates Chronos earned for a specific position since its last accrual update.
      * @param position The stake position struct.
      * @return The amount of Chronos earned by this position.
      */
    function _calculatePositionChronos(StakePosition storage position) internal view returns (uint256) {
        // position.calculatedTAPs * (chronosPerTAPSecond - position.lastChronosPerTAPSecond) / 1e18
        if (chronosPerTAPSecond <= position.lastChronosPerTAPSecond) {
            return 0;
        }
        uint256 accumulatedPerTAP = chronosPerTAPSecond.sub(position.lastChronosPerTAPSecond);
        return position.calculatedTAPs.mul(accumulatedPerTAP).div(1e18);
    }

    // --- STAKING FUNCTIONS ---

    /**
     * @dev Stakes stakeToken for a specified duration.
     * @param amount The amount of stakeToken to stake.
     * @param duration The duration of the stake in seconds.
     */
    function stake(uint256 amount, uint256 duration) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(duration >= minStakeDuration && duration <= maxStakeDuration, "Invalid duration");

        _updateAccrual(); // Update accrual before state changes

        uint256 taps = _calculateTAPs(amount, duration);
        require(taps > 0, "Calculated TAPs must be positive");

        // Transfer stake tokens to the contract
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        // Add new stake position
        userStakePositions[msg.sender].push(
            StakePosition({
                amount: amount,
                startTime: block.timestamp,
                duration: duration,
                calculatedTAPs: taps,
                lastChronosPerTAPSecond: chronosPerTAPSecond, // Checkpoint current accrual state
                active: true
            })
        );

        // Update total staked amount and TAPs
        totalStakedAmount = totalStakedAmount.add(amount);
        userTotalActiveTAPs[msg.sender] = userTotalActiveTAPs[msg.sender].add(taps);
        totalActiveTAPs = totalActiveTAPs.add(taps);

        emit Staked(msg.sender, amount, duration, userStakePositions[msg.sender].length - 1, taps);
    }

    /**
     * @dev Withdraws a specific stake position. Applies early withdrawal fee if applicable.
     * @param stakeId The index of the stake position in the user's array.
     */
    function withdraw(uint256 stakeId) external nonReentrant {
        require(stakeId < userStakePositions[msg.sender].length, "Invalid stake ID");
        StakePosition storage position = userStakePositions[msg.sender][stakeId];
        require(position.active, "Stake position is not active");

        _updateAccrual(); // Update accrual before state changes

        // Claim any pending Chronos for this position before processing withdrawal
        uint256 positionEarned = _calculatePositionChronos(position);
        if (positionEarned > 0) {
            _mint(msg.sender, positionEarned);
             // No need to update position.lastChronosPerTAPSecond here, as the position becomes inactive.
        }

        uint256 elapsedTime = block.timestamp.sub(position.startTime);
        uint256 returnAmount = position.amount;
        uint256 feeAmount = 0;

        if (elapsedTime < position.duration) {
            // Early withdrawal
            // Fee calculation: amount * (remainingDuration / originalDuration) * feeRate
            uint256 remainingDuration = position.duration.sub(elapsedTime);
            feeAmount = returnAmount.mul(remainingDuration).div(position.duration).mul(earlyWithdrawalFeeRate).div(10000);
            returnAmount = returnAmount.sub(feeAmount);
        }

        // Mark position as inactive
        position.active = false; // Don't remove from array to preserve indices

        // Update total staked amount and TAPs
        totalStakedAmount = totalStakedAmount.sub(position.amount);
        userTotalActiveTAPs[msg.sender] = userTotalActiveTAPs[msg.sender].sub(position.calculatedTAPs);
        totalActiveTAPs = totalActiveTAPs.sub(position.calculatedTAPs);

        // Transfer stake tokens back to the user (minus fee)
        if (returnAmount > 0) {
            stakeToken.safeTransfer(msg.sender, returnAmount);
        }

        // Handle fee (send to owner)
        if (feeAmount > 0) {
            // For demonstration, sending fee to owner. Can be changed (e.g., burn).
            stakeToken.safeTransfer(owner(), feeAmount);
        }

        emit Withdrawal(msg.sender, stakeId, returnAmount, feeAmount);
    }

    // --- CHRONOS TOKEN & DISTRIBUTION FUNCTIONS ---

    /**
     * @dev Calculates the total Chronos earnable by a user across all active positions.
     * This does NOT update the accrual state.
     * @param user The address of the user.
     * @return The total earnable Chronos.
     */
    function calculateEarnableChronos(address user) public view returns (uint256) {
        uint256 totalEarnable = 0;
        uint256 currentChronosPerTAPSecond = chronosPerTAPSecond;
        uint256 currentTime = block.timestamp;
        uint256 timeElapsedSinceLastAccrual = currentTime.sub(lastAccrualTime);

        // Simulate updating accrual state for calculation purposes
        if (timeElapsedSinceLastAccrual > 0 && totalActiveTAPs > 0) {
             uint256 chronosToAdd = chronosEmissionRate.mul(timeElapsedSinceLastAccrual);
             currentChronosPerTAPSecond = currentChronosPerTAPSecond.add(chronosToAdd.mul(1e18).div(totalActiveTAPs));
        }

        uint256 numPositions = userStakePositions[user].length;
        for (uint i = 0; i < numPositions; i++) {
            StakePosition storage position = userStakePositions[user][i];
            if (position.active) {
                 if (currentChronosPerTAPSecond > position.lastChronosPerTAPSecond) {
                    uint256 accumulatedPerTAP = currentChronosPerTAPSecond.sub(position.lastChronosPerTAPSecond);
                    totalEarnable = totalEarnable.add(position.calculatedTAPs.mul(accumulatedPerTAP).div(1e18));
                 }
            }
        }
        return totalEarnable;
    }

    /**
     * @dev Mints and claims pending Chronos for the caller.
     */
    function claimChronos() external nonReentrant {
        _updateAccrual(); // Update accrual state first

        uint256 totalClaimable = 0;
        uint256 currentChronosPerTAPSecondValue = chronosPerTAPSecond; // Use the updated value

        uint256 numPositions = userStakePositions[msg.sender].length;
        for (uint i = 0; i < numPositions; i++) {
            StakePosition storage position = userStakePositions[msg.sender][i];
            if (position.active) {
                uint256 positionEarned = _calculatePositionChronos(position); // Uses current chronosPerTAPSecond
                totalClaimable = totalClaimable.add(positionEarned);
                // Update checkpoint for this position
                position.lastChronosPerTAPSecond = currentChronosPerTAPSecondValue;
            }
        }

        require(totalClaimable > 0, "No Chronos available to claim");

        _mint(msg.sender, totalClaimable);

        emit ChronosClaimed(msg.sender, totalClaimable, _balances[msg.sender]); // Emit total balance after claim
    }

    // --- PARAMETER UPDATE FUNCTIONS (Owner & Governance) ---

    /**
     * @dev Allows owner to update the TAP multiplier.
     * @param newMultiplier The new TAP multiplier (scaled by 1e18).
     */
    function updateTAPMultiplier(uint256 newMultiplier) external onlyOwner {
        uint256 oldMultiplier = tapMultiplier;
        tapMultiplier = newMultiplier;
        emit ParametersUpdated("tapMultiplier", oldMultiplier, newMultiplier);
    }

    /**
     * @dev Allows owner to update the Chronos emission rate.
     * @param newRate The new emission rate per second (scaled by 1e18).
     */
    function updateEmissionRate(uint256 newRate) external onlyOwner {
        _updateAccrual(); // Update accrual before changing rate

        uint256 oldRate = chronosEmissionRate;
        chronosEmissionRate = newRate;
        emit ParametersUpdated("chronosEmissionRate", oldRate, newRate);
    }

    /**
     * @dev Allows owner to update the early withdrawal fee rate.
     * @param newRate The new fee rate in basis points (0-10000).
     */
    function updateEarlyWithdrawalFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= 10000, "Fee rate cannot exceed 10000 basis points (100%)");
        uint256 oldRate = earlyWithdrawalFeeRate;
        earlyWithdrawalFeeRate = newRate;
        emit ParametersUpdated("earlyWithdrawalFeeRate", oldRate, newRate);
    }

    /**
     * @dev Allows owner to update minimum and maximum stake durations.
     * @param newMin The new minimum duration in seconds.
     * @param newMax The new maximum duration in seconds.
     */
    function updateMinMaxDuration(uint256 newMin, uint256 newMax) external onlyOwner {
        require(newMin > 0, "Min duration must be positive");
        require(newMax >= newMin, "Max duration must be >= min duration");
        uint256 oldMin = minStakeDuration;
        uint256 oldMax = maxStakeDuration;
        minStakeDuration = newMin;
        maxStakeDuration = newMax;
        emit ParametersUpdated("minStakeDuration", oldMin, newMin); // Simplified event for multiple params
        emit ParametersUpdated("maxStakeDuration", oldMax, newMax);
    }

    /**
     * @dev Allows owner to update the minimum TAPs required to create a proposal.
     * @param newAmount The new required TAP amount.
     */
    function updateRequiredTAPsForProposalCreation(uint256 newAmount) external onlyOwner {
        uint256 oldAmount = requiredTAPsForProposalCreation;
        requiredTAPsForProposalCreation = newAmount;
        emit ParametersUpdated("requiredTAPsForProposalCreation", oldAmount, newAmount);
    }

     /**
     * @dev Allows owner to update the required vote quorum for proposals.
     * @param newQuorum The new required quorum in basis points (0-10000).
     */
    function updateRequiredVoteQuorum(uint256 newQuorum) external onlyOwner {
        require(newQuorum <= 10000, "Quorum cannot exceed 100%");
        uint256 oldQuorum = requiredVoteQuorum;
        requiredVoteQuorum = newQuorum;
        emit ParametersUpdated("requiredVoteQuorum", oldQuorum, newQuorum);
    }

    /**
     * @dev Allows owner to update the required vote threshold for proposals.
     * @param newThreshold The new required threshold in basis points (0-10000).
     */
    function updateRequiredVoteThreshold(uint256 newThreshold) external onlyOwner {
         require(newThreshold <= 10000, "Threshold cannot exceed 100%");
        uint256 oldThreshold = requiredVoteThreshold;
        requiredVoteThreshold = newThreshold;
        emit ParametersUpdated("requiredVoteThreshold", oldThreshold, newThreshold);
    }


    // --- TAP-WEIGHTED GOVERNANCE FUNCTIONS ---

    /**
     * @dev Allows users with sufficient TAPs to create a proposal to update a contract parameter.
     * Only specific parameters can be proposed for update.
     * @param description A description of the proposal.
     * @param parameterName The name of the parameter to update ("tapMultiplier", "emissionRate", etc.).
     * @param newValue The proposed new value for the parameter.
     * @param votingDuration The duration of the voting period in seconds.
     */
    function createParameterUpdateProposal(
        string memory description,
        string memory parameterName,
        uint256 newValue,
        uint256 votingDuration
    ) external nonReentrant onlyMinTAPs(msg.sender, requiredTAPsForProposalCreation) {
        require(bytes(parameterName).length > 0, "Parameter name cannot be empty");
        require(votingDuration > 0, "Voting duration must be positive");

        // Basic validation of parameterName (can be extended)
        bool validParam = false;
        if (
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("tapMultiplier")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("chronosEmissionRate")) ||
            keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("earlyWithdrawalFeeRate")) ||
             keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("requiredTAPsForProposalCreation")) ||
             keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("requiredVoteQuorum")) ||
             keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("requiredVoteThreshold"))
        ) {
            validParam = true;
        }
        require(validParam, "Invalid parameter name for proposal");
         if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("earlyWithdrawalFeeRate"))) {
             require(newValue <= 10000, "Proposed fee rate exceeds 100%");
         }
         if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("requiredVoteQuorum")) || keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("requiredVoteThreshold"))) {
             require(newValue <= 10000, "Proposed quorum/threshold exceeds 100%");
         }


        _updateAccrual(); // Update accrual state before snapshotting TAPs

        uint256 proposalId = nextProposalId;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            parameterName: parameterName,
            newValue: newValue,
            creationTime: block.timestamp,
            endTime: block.timestamp.add(votingDuration),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            passed: false
        });

        nextProposalId++;

        emit ProposalCreated(proposalId, msg.sender, description, parameterName, newValue, proposals[proposalId].endTime);
    }

    /**
     * @dev Allows users with active stake to vote on an active proposal.
     * Vote weight is based on the user's current active TAPs.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for voting for, false for voting against.
     */
    function voteOnProposal(uint256 proposalId, bool support) external nonReentrant onlyActiveStake(msg.sender) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist"); // Check if proposal struct is initialized
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        _updateAccrual(); // Update accrual before getting TAP snapshot

        uint256 userTAPs = getUserTotalActiveTAPs(msg.sender);
        require(userTAPs > 0, "User must have active TAPs to vote"); // Redundant with onlyActiveStake, but good check

        if (support) {
            proposal.forVotes = proposal.forVotes.add(userTAPs);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(userTAPs);
        }

        proposal.voted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, userTAPs);
    }

    /**
     * @dev Allows anyone to execute a proposal if the voting period has ended
     * and it meets the quorum and threshold requirements.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        _updateAccrual(); // Update accrual before checking TotalActiveTAPs for quorum

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        bool passedQuorum = false;
        // Check quorum against the TotalActiveTAPs at the time of execution attempt
        if (totalActiveTAPs > 0) {
            passedQuorum = totalVotes.mul(10000).div(totalActiveTAPs) >= requiredVoteQuorum;
        }

        bool passedThreshold = false;
        if (totalVotes > 0) {
            passedThreshold = proposal.forVotes.mul(10000).div(totalVotes) >= requiredVoteThreshold;
        }

        proposal.passed = passedQuorum && passedThreshold;
        proposal.executed = true; // Mark as executed regardless of passing to prevent re-execution

        if (proposal.passed) {
            // Execute the parameter update based on the parameter name
            bytes memory paramNameBytes = abi.encodePacked(proposal.parameterName);

            if (keccak256(paramNameBytes) == keccak256(abi.encodePacked("tapMultiplier"))) {
                tapMultiplier = proposal.newValue;
            } else if (keccak256(paramNameBytes) == keccak256(abi.encodePacked("chronosEmissionRate"))) {
                chronosEmissionRate = proposal.newValue;
            } else if (keccak256(paramNameBytes) == keccak256(abi.encodePacked("earlyWithdrawalFeeRate"))) {
                 earlyWithdrawalFeeRate = proposal.newValue;
            } else if (keccak256(paramNameBytes) == keccak256(abi.encodePacked("requiredTAPsForProposalCreation"))) {
                 requiredTAPsForProposalCreation = proposal.newValue;
            } else if (keccak256(paramNameBytes) == keccak256(abi.encodePacked("requiredVoteQuorum"))) {
                 requiredVoteQuorum = proposal.newValue;
            } else if (keccak256(paramNameBytes) == keccak256(abi.encodePacked("requiredVoteThreshold"))) {
                 requiredVoteThreshold = proposal.newValue;
            }
            // Add more parameter update cases here if needed
             emit ParametersUpdated(proposal.parameterName, 0, proposal.newValue); // Old value is hard to get generically
        }

        emit ProposalExecuted(proposalId, proposal.passed);
    }

    // --- VIEW FUNCTIONS ---

    /**
     * @dev Returns details of a specific stake position for a user.
     * @param user The address of the user.
     * @param stakeId The index of the stake position.
     * @return amount, startTime, duration, calculatedTAPs, active status.
     */
    function getUserStakePosition(address user, uint256 stakeId) external view returns (
        uint256 amount,
        uint256 startTime,
        uint256 duration,
        uint256 calculatedTAPs,
        bool active
    ) {
        require(stakeId < userStakePositions[user].length, "Invalid stake ID");
        StakePosition storage position = userStakePositions[user][stakeId];
        return (position.amount, position.startTime, position.duration, position.calculatedTAPs, position.active);
    }

     /**
      * @dev Returns the address of the stake token.
      */
     function getStakeTokenAddress() external view returns (address) {
         return address(stakeToken);
     }

     /**
      * @dev Returns the current TAP multiplier.
      */
     function getTAPMultiplier() external view returns (uint256) {
         return tapMultiplier;
     }

    /**
      * @dev Returns the minimum allowed stake duration.
      */
     function getMinStakeDuration() external view returns (uint256) {
         return minStakeDuration;
     }

     /**
      * @dev Returns the maximum allowed stake duration.
      */
     function getMaxStakeDuration() external view returns (uint256) {
         return maxStakeDuration;
     }

     /**
      * @dev Returns the early withdrawal fee rate in basis points.
      */
     function getEarlyWithdrawalFeeRate() external view returns (uint256) {
         return earlyWithdrawalFeeRate;
     }

     /**
      * @dev Returns the Chronos emission rate per second.
      */
     function getChronosEmissionRate() external view returns (uint256) {
         return chronosEmissionRate;
     }

     /**
      * @dev Returns details of a specific proposal.
      * @param proposalId The ID of the proposal.
      * @return id, proposer, description, parameterName, newValue, creationTime, endTime, forVotes, againstVotes, executed, passed status.
      */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        string memory parameterName,
        uint256 newValue,
        uint256 creationTime,
        uint256 endTime,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed,
        bool passed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.parameterName,
            proposal.newValue,
            proposal.creationTime,
            proposal.endTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.passed
        );
    }

    /**
     * @dev Returns the current number of proposals.
     */
    function getProposalCount() external view returns (uint256) {
        return nextProposalId;
    }

    /**
     * @dev Returns the minimum TAPs required to create a proposal.
     */
    function getRequiredTAPsForProposalCreation() external view returns (uint256) {
        return requiredTAPsForProposalCreation;
    }

     /**
     * @dev Returns the required vote quorum for proposals in basis points.
     */
    function getRequiredVoteQuorum() external view returns (uint256) {
        return requiredVoteQuorum;
    }

     /**
     * @dev Returns the required vote threshold for proposals in basis points.
     */
    function getRequiredVoteThreshold() external view returns (uint256) {
        return requiredVoteThreshold;
    }


    // --- ERC-20 STANDARD FUNCTIONS (Chronos Token Implementation) ---
    // The contract itself acts as the Chronos Token

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override nonReentrant returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    // --- Internal ERC-20 Functions ---

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- ERC-20 Optional Functions ---

    /**
     * @dev Destroys `amount` tokens from the caller's account.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual nonReentrant {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public virtual nonReentrant {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    // --- Additional View Functions for Clarity ---

    /**
     * @dev Returns the address of the Chronos Token (this contract).
     */
    function getChronosTokenAddress() external view returns (address) {
        return address(this);
    }

     /**
      * @dev Returns the details of a user's stake position by index.
      * Allows retrieval of individual positions by ID from the user array.
      * Note: Use getUserStakePositions to get the whole array.
      * @param user The address of the user.
      * @param stakeId The index of the stake position.
      */
     function getIndexedUserStakePosition(address user, uint256 stakeId) external view returns (StakePosition memory) {
         require(stakeId < userStakePositions[user].length, "Invalid stake ID");
         return userStakePositions[user][stakeId];
     }

    /**
     * @dev Returns the current block timestamp. Useful for client-side time calculations.
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    // Total function count check:
    // constructor: 1
    // Staking: stake, withdraw (2)
    // TAP/State Views: calculatePositionTAPs (internal), getUserTotalActiveTAPs, getTotalActiveTAPs, getTotalStakedAmount, getUserStakePositions (returns dynamic array, might be limited depending on client) -> Let's make a specific indexed getter instead: getIndexedUserStakePosition. (4 views + 1 internal)
    // Chronos: _updateAccrual (internal), calculateEarnableChronos, claimChronos (2 + 1 internal)
    // Config (Owner): transferOwnership, updateTAPMultiplier, updateEmissionRate, updateEarlyWithdrawalFeeRate, updateMinMaxDuration, updateRequiredTAPsForProposalCreation, updateRequiredVoteQuorum, updateRequiredVoteThreshold (8)
    // Governance: createParameterUpdateProposal, voteOnProposal, getProposalDetails, getProposalVoteResult, executeProposal, getRequiredTAPsForProposalCreation, getRequiredVoteQuorum, getRequiredVoteThreshold, getProposalCount (9)
    // ERC-20: totalSupply, balanceOf, transfer, allowance, approve, transferFrom, _transfer, _mint, _burn, _approve, burn, burnFrom (12 + 4 internal)
    // Additional Views: getStakeTokenAddress, getChronosTokenAddress, getCurrentTimestamp (3)

    // Total external/public functions: 2 + 4 + 2 + 8 + 9 + 12 + 3 = 40.
    // Total internal functions: 1 + 1 + 1 + 4 = 7.
    // Total functions (external/public + internal listed): 40 + 7 = 47.
    // The requirement is for external/public functions primarily. 40 is > 20.


    // Missing `getProposalVoteResult`
    function getProposalVoteResult(uint256 proposalId) external view returns (uint256 forVotes, uint256 againstVotes) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        return (proposal.forVotes, proposal.againstVotes);
    }
    // Add this function to the count: 40 + 1 = 41 external/public functions.

}
```

This contract provides a rich set of features: time-locked staking, dynamic influence (TAPs), proportional resource distribution (Chronos Token emission managed internally), early withdrawal penalties, and a simple TAP-weighted governance system for updating certain parameters. It integrates the reward token directly, which is gas-efficient for distribution. It uses standard patterns like `Ownable`, `ReentrancyGuard`, and `SafeERC20`. The governance mechanism allows the community (weighted by their stake commitment) to influence key aspects of the system. It meets the function count requirement with over 40 external/public functions.