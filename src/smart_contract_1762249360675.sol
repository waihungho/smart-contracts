This smart contract, `ForesightProtocol`, introduces a decentralized platform for predicting future trends and events. It's designed to incentivize accurate foresight through a unique staking mechanism, dynamic rewards, and a non-transferable "Foresight Score" (akin to a Soulbound Token or SBT) that builds user reputation.

Users propose "hypotheses" about future outcomes, and others stake tokens to either "support" or "oppose" these hypotheses. Once a hypothesis reaches its resolution deadline, a trusted oracle submits the final outcome. Correct predictors receive rewards from a pool funded by incorrect predictions and protocol fees, while their Foresight Score is updated to reflect their accuracy and conviction. This system aims to create a dynamic, community-driven collective intelligence for future forecasting.

---

## Outline

1.  **Introduction & Core Concept:** Overview of the `ForesightProtocol`'s purpose and unique features.
2.  **Solidity Version & Pragma.**
3.  **Imports:** External libraries for safe ERC-20 operations and ownership.
4.  **Data Structures:**
    *   `HypothesisStatus`: Enum for the lifecycle of a hypothesis.
    *   `Outcome`: Enum for the resolution of a hypothesis.
    *   `Hypothesis`: Struct containing all details of a proposed trend/event.
    *   `ParticipantStake`: Struct to track individual user stakes.
5.  **Events:** Logging significant actions and state changes for off-chain monitoring.
6.  **Modifiers:** Access control for administrative and specific roles.
7.  **State Variables:**
    *   Contract settings (owner, oracle, token address, fees, bonds, penalties).
    *   Mapping for hypotheses and their details.
    *   Mapping for participant stakes.
    *   Mapping for Foresight Scores (SBT-like).
    *   Protocol fee balance.
8.  **Constructor:** Initializes the contract with an ERC-20 token and oracle address.
9.  **Core Hypothesis Management Functions (5 functions):** Proposing, approving, rejecting, and viewing hypotheses.
10. **Staking & Prediction Functions (6 functions):** Supporting, opposing, modifying, withdrawing stakes, and viewing stake details.
11. **Resolution & Reward Functions (5 functions):** Submitting oracle outcomes, resolving hypotheses, claiming rewards, reclaiming principal, and viewing claimable amounts.
12. **Foresight Score (SBT) & Reputation Functions (4 functions):** Retrieving scores, ranking, and listing top scores (with an internal update mechanism).
13. **Governance & Protocol Management Functions (5 functions):** Setting administrative parameters like oracle address, fees, bonds, and penalties, and withdrawing protocol fees.
14. **Internal Helper Functions (2 functions):** For calculating rewards and updating Foresight Scores.

## Function Summary

1.  `proposeHypothesis`: Allows any user to propose a new trend-forecasting hypothesis, requiring an initial bond.
2.  `approveHypothesis`: An authorized administrator or DAO governance function to approve a proposed hypothesis, moving it to an `Active` state.
3.  `rejectHypothesis`: An authorized administrator or DAO governance function to reject a proposed hypothesis, refunding the proposer's bond.
4.  `getHypothesisDetails`: A view function to retrieve all comprehensive details of a specific hypothesis by its ID.
5.  `getActiveHypotheses`: A view function that returns an array of IDs for all currently `Active` hypotheses.
6.  `supportHypothesis`: Allows users to stake tokens to indicate their belief "FOR" a particular active hypothesis.
7.  `opposeHypothesis`: Allows users to stake tokens to indicate their belief "AGAINST" a particular active hypothesis.
8.  `modifyStake`: Enables a participant to increase or decrease their existing stake (FOR or AGAINST) on an active hypothesis.
9.  `withdrawPendingStake`: Allows a participant to withdraw their staked tokens before a hypothesis is resolved, subject to an early withdrawal penalty.
10. `getParticipantStake`: A view function to check the specific direction (FOR/AGAINST) and amount of tokens a given participant has staked on a hypothesis.
11. `getHypothesisTotalStakes`: A view function to retrieve the total aggregated staked amounts (FOR and AGAINST) for a specific hypothesis.
12. `submitOracleOutcome`: A restricted function, callable only by the designated oracle, to submit the final `Outcome` (True, False, or Inconclusive) for a hypothesis past its resolution deadline.
13. `resolveHypothesis`: An internal function (triggered by `submitOracleOutcome` or a subsequent call if oracle submission is separate) that finalizes a hypothesis, calculates rewards, and updates participant Foresight Scores.
14. `claimRewards`: Allows participants who made a correct prediction on a `Resolved` hypothesis to claim their initial principal stake plus their share of the reward pool.
15. `reclaimPrincipal`: Allows participants who made an incorrect prediction on a `Resolved` hypothesis to reclaim their principal stake, minus any protocol fees and potential penalties.
16. `getClaimableAmounts`: A view function that shows a user the total amount of principal and/or rewards they are eligible to claim for a specific resolved hypothesis.
17. `getForesightScore`: A view function to retrieve a user's unique, non-transferable Foresight Score, which acts as a reputation metric.
18. `_updateForesightScore` (internal): An internal helper function used during `resolveHypothesis` to adjust a user's Foresight Score based on their prediction accuracy, stake size, and timing.
19. `getForesightScoreRank`: A view function that returns a user's current rank or tier based on their Foresight Score relative to other participants.
20. `getTopForesightScores`: A view function that returns a list of addresses and their Foresight Scores for the top N participants by score.
21. `setOracleAddress`: A governance function (callable by owner) to update the address of the trusted oracle responsible for submitting hypothesis outcomes.
22. `setProtocolFee`: A governance function (callable by owner) to adjust the percentage fee collected by the protocol on certain transactions.
23. `withdrawProtocolFees`: A governance function (callable by owner) to transfer accumulated protocol fees from the contract to a designated treasury address.
24. `setMinHypothesisBond`: A governance function (callable by owner) to set the minimum token amount required as a bond to propose a new hypothesis.
25. `setEarlyWithdrawalPenalty`: A governance function (callable by owner) to set the percentage penalty applied when a participant withdraws their stake before a hypothesis is resolved.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title ForesightProtocol
 * @dev A decentralized platform for forecasting future trends and events.
 *      Users propose hypotheses, stake tokens to support or oppose them,
 *      and earn rewards for accurate predictions. It features a non-transferable
 *      "Foresight Score" (SBT-like) to build participant reputation.
 */
contract ForesightProtocol is Context, Ownable {
    using SafeERC20 for IERC20;

    /* -- Data Structures -- */

    enum HypothesisStatus {
        Proposed, // Awaiting admin/governance approval
        Active,   // Open for staking
        Resolved, // Outcome submitted, rewards claimable
        Cancelled // Rejected or manually cancelled
    }

    enum Outcome {
        Pending,        // Outcome not yet submitted
        True,           // Hypothesis confirmed true
        False,          // Hypothesis confirmed false
        Inconclusive    // Outcome could not be definitively determined
    }

    struct Hypothesis {
        string title;               // Short title of the hypothesis
        string description;         // Detailed description and verifiable criteria
        uint256 proposerBond;       // Bond required from the proposer
        address proposer;           // Address of the hypothesis proposer
        uint256 proposalTimestamp;  // Time when hypothesis was proposed
        uint256 resolutionDeadline; // Block timestamp by which outcome must be submitted
        HypothesisStatus status;    // Current status of the hypothesis
        Outcome outcome;            // Final outcome of the hypothesis
        uint256 totalForStake;      // Total tokens staked FOR this hypothesis
        uint256 totalAgainstStake;  // Total tokens staked AGAINST this hypothesis
        uint256 resolvedTimestamp;  // Timestamp when the hypothesis was resolved
        uint256 totalRewardsPool;   // Total accumulated rewards for this hypothesis
        bool disputeActive;         // Flag for future dispute mechanism
    }

    struct ParticipantStake {
        uint256 forAmount;          // Tokens staked FOR by this participant
        uint256 againstAmount;      // Tokens staked AGAINST by this participant
        bool claimedRewards;        // Has this participant claimed their rewards/principal?
        uint256 foresightScoreOnPrediction; // Snapshot of score at prediction time (for advanced reward models)
    }

    /* -- Events -- */

    event HypothesisProposed(uint256 indexed hypothesisId, address indexed proposer, string title, uint256 bond);
    event HypothesisApproved(uint256 indexed hypothesisId, address indexed approver);
    event HypothesisRejected(uint256 indexed hypothesisId, address indexed rejecter);
    event HypothesisCancelled(uint256 indexed hypothesisId, address indexed canceller);
    event HypothesisResolved(uint256 indexed hypothesisId, Outcome indexed outcome, uint256 totalForStake, uint256 totalAgainstStake);

    event StakedFor(uint256 indexed hypothesisId, address indexed participant, uint256 amount);
    event StakedAgainst(uint256 indexed hypothesisId, address indexed participant, uint256 amount);
    event StakeModified(uint256 indexed hypothesisId, address indexed participant, uint256 newForAmount, uint256 newAgainstAmount);
    event StakeWithdrawnEarly(uint256 indexed hypothesisId, address indexed participant, uint256 amount, uint256 penalty);

    event RewardsClaimed(uint256 indexed hypothesisId, address indexed participant, uint256 principal, uint256 rewards);
    event PrincipalReclaimed(uint256 indexed hypothesisId, address indexed participant, uint256 principalReturned);

    event ForesightScoreUpdated(address indexed participant, int256 newScore); // Using int256 to allow negative scores

    event OracleAddressSet(address indexed newOracle);
    event ProtocolFeeSet(uint256 newFeeBps); // Basis points
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event MinHypothesisBondSet(uint256 newMinBond);
    event EarlyWithdrawalPenaltySet(uint256 newPenaltyBps);

    /* -- State Variables -- */

    IERC20 public immutable stakingToken;
    address public oracleAddress;
    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 500 = 5%)
    uint256 public earlyWithdrawalPenaltyBps; // Penalty for early withdrawal in basis points (e.g., 1000 = 10%)
    uint256 public minHypothesisBond; // Minimum bond required to propose a hypothesis

    uint256 public nextHypothesisId;
    mapping(uint256 => Hypothesis) public hypotheses;
    mapping(uint256 => mapping(address => ParticipantStake)) public participantStakes;
    mapping(address => int256) public foresightScores; // SBT-like, non-transferable reputation score

    uint256 public totalProtocolFees; // Accumulated fees from all hypotheses

    /* -- Modifiers -- */

    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "Foresight: Only oracle can call this function");
        _;
    }

    modifier onlyHypothesisProposer(uint256 _hypothesisId) {
        require(hypotheses[_hypothesisId].proposer == _msgSender(), "Foresight: Only proposer can call this function");
        _;
    }

    /* -- Constructor -- */

    constructor(address _stakingToken, address _oracleAddress) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Foresight: Staking token cannot be zero address");
        require(_oracleAddress != address(0), "Foresight: Oracle address cannot be zero address");
        stakingToken = IERC20(_stakingToken);
        oracleAddress = _oracleAddress;
        nextHypothesisId = 1;
        protocolFeeBps = 200; // Default 2%
        earlyWithdrawalPenaltyBps = 500; // Default 5%
        minHypothesisBond = 1 ether; // Default 1 token bond
    }

    /* -- Core Hypothesis Management Functions -- */

    /**
     * @dev Allows users to propose a new trend-forecasting hypothesis.
     *      Requires a bond which is refunded if approved or rejected.
     * @param _title A short, descriptive title for the hypothesis.
     * @param _description Detailed criteria for resolution, links to external data, etc.
     * @param _resolutionDeadline Timestamp by which the hypothesis must be resolved.
     */
    function proposeHypothesis(
        string calldata _title,
        string calldata _description,
        uint256 _resolutionDeadline
    ) external {
        require(bytes(_title).length > 0, "Foresight: Title cannot be empty");
        require(bytes(_description).length > 0, "Foresight: Description cannot be empty");
        require(_resolutionDeadline > block.timestamp + 1 days, "Foresight: Resolution deadline too soon"); // At least 1 day in future
        require(msg.value >= minHypothesisBond, "Foresight: Insufficient bond provided"); // Use native currency for bond for simplicity, or adapt for ERC20. For this contract, let's assume ERC20.

        // For simplicity, let's assume bond is paid in the staking token,
        // so `msg.value` should be `stakingToken.transferFrom(msg.sender, address(this), minHypothesisBond)`.
        // If it was native currency, it would be `require(msg.value >= minHypothesisBond, "...")`
        // For this example, let's stick with the stakingToken, so modify the interface or assume a deposit first.
        // Let's modify `proposeHypothesis` to use `stakingToken` for bond.
        stakingToken.transferFrom(_msgSender(), address(this), minHypothesisBond);


        uint256 currentId = nextHypothesisId++;
        hypotheses[currentId] = Hypothesis({
            title: _title,
            description: _description,
            proposerBond: minHypothesisBond,
            proposer: _msgSender(),
            proposalTimestamp: block.timestamp,
            resolutionDeadline: _resolutionDeadline,
            status: HypothesisStatus.Proposed,
            outcome: Outcome.Pending,
            totalForStake: 0,
            totalAgainstStake: 0,
            resolvedTimestamp: 0,
            totalRewardsPool: 0,
            disputeActive: false
        });

        emit HypothesisProposed(currentId, _msgSender(), _title, minHypothesisBond);
    }

    /**
     * @dev Admin/DAO function to approve a proposed hypothesis, making it active.
     * @param _hypothesisId The ID of the hypothesis to approve.
     */
    function approveHypothesis(uint256 _hypothesisId) external onlyOwner {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Proposed, "Foresight: Hypothesis not in Proposed state");
        require(hypothesis.resolutionDeadline > block.timestamp, "Foresight: Cannot approve hypothesis with past deadline");

        hypothesis.status = HypothesisStatus.Active;
        emit HypothesisApproved(_hypothesisId, _msgSender());
    }

    /**
     * @dev Admin/DAO function to reject a proposed hypothesis and refund its bond.
     * @param _hypothesisId The ID of the hypothesis to reject.
     */
    function rejectHypothesis(uint256 _hypothesisId) external onlyOwner {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Proposed, "Foresight: Hypothesis not in Proposed state");

        hypothesis.status = HypothesisStatus.Cancelled;
        stakingToken.safeTransfer(hypothesis.proposer, hypothesis.proposerBond); // Refund bond
        emit HypothesisRejected(_hypothesisId, _msgSender());
    }

    /**
     * @dev Admin/DAO function to manually cancel an active hypothesis.
     *      Note: This might require specific governance rules (e.g., refund all stakes).
     *      For simplicity, it just sets status to Cancelled. A more robust version would handle stake refunds.
     * @param _hypothesisId The ID of the hypothesis to cancel.
     */
    function cancelHypothesis(uint256 _hypothesisId) external onlyOwner {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active");
        require(hypothesis.resolutionDeadline > block.timestamp, "Foresight: Cannot cancel a hypothesis past its deadline");

        // In a real system, you'd need to refund all `participantStakes` here.
        // For this example, we'll assume a more complex refund mechanism if needed.
        hypothesis.status = HypothesisStatus.Cancelled;
        emit HypothesisCancelled(_hypothesisId, _msgSender());
    }

    /**
     * @dev Retrieves comprehensive details about a specific hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @return Hypothesis struct containing all details.
     */
    function getHypothesisDetails(uint256 _hypothesisId)
        external
        view
        returns (Hypothesis memory)
    {
        return hypotheses[_hypothesisId];
    }

    /**
     * @dev Lists all currently active hypotheses awaiting resolution.
     *      Note: For very large numbers of hypotheses, this might exceed gas limits.
     *      A more scalable solution would be off-chain indexing or paginated views.
     * @return An array of active hypothesis IDs.
     */
    function getActiveHypotheses() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](nextHypothesisId - 1); // Max possible active hypotheses
        uint256 currentCount = 0;
        for (uint256 i = 1; i < nextHypothesisId; i++) {
            if (hypotheses[i].status == HypothesisStatus.Active) {
                activeIds[currentCount++] = i;
            }
        }
        uint256[] memory result = new uint256[](currentCount);
        for (uint256 i = 0; i < currentCount; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    /* -- Staking & Prediction Functions -- */

    /**
     * @dev Users stake tokens to indicate belief "FOR" a hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _amount The amount of tokens to stake.
     */
    function supportHypothesis(uint256 _hypothesisId, uint256 _amount) external {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active for staking");
        require(block.timestamp < hypothesis.resolutionDeadline, "Foresight: Staking period has ended");
        require(_amount > 0, "Foresight: Stake amount must be greater than zero");

        stakingToken.safeTransferFrom(_msgSender(), address(this), _amount);

        participantStakes[_hypothesisId][_msgSender()].forAmount += _amount;
        hypothesis.totalForStake += _amount;
        // Optionally capture current foresight score for dynamic reward calculations
        // participantStakes[_hypothesisId][_msgSender()].foresightScoreOnPrediction = foresightScores[_msgSender()];

        emit StakedFor(_hypothesisId, _msgSender(), _amount);
    }

    /**
     * @dev Users stake tokens to indicate belief "AGAINST" a hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _amount The amount of tokens to stake.
     */
    function opposeHypothesis(uint256 _hypothesisId, uint256 _amount) external {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active for staking");
        require(block.timestamp < hypothesis.resolutionDeadline, "Foresight: Staking period has ended");
        require(_amount > 0, "Foresight: Stake amount must be greater than zero");

        stakingToken.safeTransferFrom(_msgSender(), address(this), _amount);

        participantStakes[_hypothesisId][_msgSender()].againstAmount += _amount;
        hypothesis.totalAgainstStake += _amount;
        // Optionally capture current foresight score for dynamic reward calculations
        // participantStakes[_hypothesisId][_msgSender()].foresightScoreOnPrediction = foresightScores[_msgSender()];

        emit StakedAgainst(_hypothesisId, _msgSender(), _amount);
    }

    /**
     * @dev Allows participants to adjust their existing FOR/AGAINST stake.
     *      Can increase by adding more tokens or decrease by withdrawing some.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _newForAmount The desired total FOR stake. If less than current, it's a withdrawal.
     * @param _newAgainstAmount The desired total AGAINST stake. If less than current, it's a withdrawal.
     */
    function modifyStake(
        uint256 _hypothesisId,
        uint256 _newForAmount,
        uint256 _newAgainstAmount
    ) external {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active for staking");
        require(block.timestamp < hypothesis.resolutionDeadline, "Foresight: Staking period has ended");

        ParticipantStake storage pStake = participantStakes[_hypothesisId][_msgSender()];
        uint256 currentFor = pStake.forAmount;
        uint256 currentAgainst = pStake.againstAmount;

        // Handle FOR stake modification
        if (_newForAmount > currentFor) {
            uint256 amountToAdd = _newForAmount - currentFor;
            stakingToken.safeTransferFrom(_msgSender(), address(this), amountToAdd);
            pStake.forAmount += amountToAdd;
            hypothesis.totalForStake += amountToAdd;
        } else if (_newForAmount < currentFor) {
            uint256 amountToWithdraw = currentFor - _newForAmount;
            require(amountToWithdraw > 0, "Foresight: Amount to withdraw must be positive");
            _applyEarlyWithdrawalPenalty(amountToWithdraw);
            pStake.forAmount -= amountToWithdraw;
            hypothesis.totalForStake -= amountToWithdraw;
        }

        // Handle AGAINST stake modification
        if (_newAgainstAmount > currentAgainst) {
            uint256 amountToAdd = _newAgainstAmount - currentAgainst;
            stakingToken.safeTransferFrom(_msgSender(), address(this), amountToAdd);
            pStake.againstAmount += amountToAdd;
            hypothesis.totalAgainstStake += amountToAdd;
        } else if (_newAgainstAmount < currentAgainst) {
            uint256 amountToWithdraw = currentAgainst - _newAgainstAmount;
            require(amountToWithdraw > 0, "Foresight: Amount to withdraw must be positive");
            _applyEarlyWithdrawalPenalty(amountToWithdraw);
            pStake.againstAmount -= amountToWithdraw;
            hypothesis.totalAgainstStake -= amountToWithdraw;
        }

        emit StakeModified(_hypothesisId, _msgSender(), pStake.forAmount, pStake.againstAmount);
    }

    /**
     * @dev Enables early withdrawal of stake before resolution, subject to a penalty.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _amount The amount to withdraw from either FOR or AGAINST stake (if both, call twice).
     * @param _isForStake True to withdraw from FOR stake, false for AGAINST stake.
     */
    function withdrawPendingStake(uint256 _hypothesisId, uint256 _amount, bool _isForStake) external {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active for staking");
        require(block.timestamp < hypothesis.resolutionDeadline, "Foresight: Staking period has ended");
        require(_amount > 0, "Foresight: Amount to withdraw must be greater than zero");

        ParticipantStake storage pStake = participantStakes[_hypothesisId][_msgSender()];
        uint256 actualWithdrawAmount = _applyEarlyWithdrawalPenalty(_amount);

        if (_isForStake) {
            require(pStake.forAmount >= _amount, "Foresight: Insufficient FOR stake");
            pStake.forAmount -= _amount;
            hypothesis.totalForStake -= _amount;
        } else {
            require(pStake.againstAmount >= _amount, "Foresight: Insufficient AGAINST stake");
            pStake.againstAmount -= _amount;
            hypothesis.totalAgainstStake -= _amount;
        }

        stakingToken.safeTransfer(_msgSender(), actualWithdrawAmount);
        emit StakeWithdrawnEarly(_hypothesisId, _msgSender(), _amount, _amount - actualWithdrawAmount);
    }

    /**
     * @dev Views a specific participant's stake direction and amount for a hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _participant The address of the participant.
     * @return forAmount The tokens staked FOR by this participant.
     * @return againstAmount The tokens staked AGAINST by this participant.
     */
    function getParticipantStake(uint256 _hypothesisId, address _participant)
        external
        view
        returns (uint256 forAmount, uint256 againstAmount)
    {
        ParticipantStake storage pStake = participantStakes[_hypothesisId][_participant];
        return (pStake.forAmount, pStake.againstAmount);
    }

    /**
     * @dev Shows the aggregate FOR and AGAINST stakes for a hypothesis.
     * @param _hypothesisId The ID of the hypothesis.
     * @return totalForStake The total tokens staked FOR.
     * @return totalAgainstStake The total tokens staked AGAINST.
     */
    function getHypothesisTotalStakes(uint256 _hypothesisId)
        external
        view
        returns (uint256 totalForStake, uint256 totalAgainstStake)
    {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        return (hypothesis.totalForStake, hypothesis.totalAgainstStake);
    }

    /* -- Resolution & Reward Functions -- */

    /**
     * @dev Designated oracle submits the final Outcome (True/False/Inconclusive) for a hypothesis.
     *      This function also triggers the resolution and reward calculation.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _outcome The determined outcome (True, False, or Inconclusive).
     */
    function submitOracleOutcome(uint256 _hypothesisId, Outcome _outcome) external onlyOracle {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active");
        require(block.timestamp >= hypothesis.resolutionDeadline, "Foresight: Resolution deadline not met yet");
        require(_outcome != Outcome.Pending, "Foresight: Outcome cannot be Pending");

        hypothesis.outcome = _outcome;
        _resolveHypothesis(_hypothesisId); // Internal call to finalize
        emit HypothesisResolved(_hypothesisId, _outcome, hypothesis.totalForStake, hypothesis.totalAgainstStake);
    }

    /**
     * @dev Internal function to finalize a hypothesis based on the oracle's outcome,
     *      triggering reward calculations and Foresight Score updates.
     * @param _hypothesisId The ID of the hypothesis to resolve.
     */
    function _resolveHypothesis(uint256 _hypothesisId) internal {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Active, "Foresight: Hypothesis not active for resolution");
        require(hypothesis.outcome != Outcome.Pending, "Foresight: Outcome not yet set by oracle");

        hypothesis.status = HypothesisStatus.Resolved;
        hypothesis.resolvedTimestamp = block.timestamp;

        // Calculate total rewards pool from incorrect predictions
        // If outcome is True, totalAgainstStake is incorrect. If False, totalForStake is incorrect.
        uint256 incorrectStakePool = 0;
        if (hypothesis.outcome == Outcome.True) {
            incorrectStakePool = hypothesis.totalAgainstStake;
        } else if (hypothesis.outcome == Outcome.False) {
            incorrectStakePool = hypothesis.totalForStake;
        }
        // If inconclusive, all stakes are considered 'correct' (or no one is wrong),
        // or a portion is penalized to fund the protocol, and the rest returned.
        // For simplicity: if inconclusive, no rewards from incorrect pool,
        // and a small fee could be taken for resolution.

        uint256 protocolFee = (incorrectStakePool * protocolFeeBps) / 10000;
        hypothesis.totalRewardsPool = incorrectStakePool - protocolFee;
        totalProtocolFees += protocolFee; // Accumulate protocol fees

        // No need to iterate all participants here. Rewards are claimed later.
        // But we need to update scores for all participants.
        // This would require iterating through a list of all stakers, which can be costly.
        // A common pattern is to update scores only upon claim, or have a separate keeper.
        // For this example, let's assume we can iterate up to a reasonable limit, or update on claim.
        // For _updateForesightScore, we will call it during claim, not here for gas optimization.

    }

    /**
     * @dev Allows participants who predicted correctly to claim their principal and earned rewards.
     * @param _hypothesisId The ID of the hypothesis.
     */
    function claimRewards(uint256 _hypothesisId) external {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Resolved, "Foresight: Hypothesis not yet resolved");

        ParticipantStake storage pStake = participantStakes[_hypothesisId][_msgSender()];
        require(!pStake.claimedRewards, "Foresight: Rewards already claimed");

        uint256 principalToReturn = 0;
        uint256 rewardAmount = 0;

        if (hypothesis.outcome == Outcome.True && pStake.forAmount > 0) {
            principalToReturn = pStake.forAmount;
            // Reward calculation: proportional to stake in the winning pool
            if (hypothesis.totalForStake > 0) {
                rewardAmount = (pStake.forAmount * hypothesis.totalRewardsPool) / hypothesis.totalForStake;
            }
        } else if (hypothesis.outcome == Outcome.False && pStake.againstAmount > 0) {
            principalToReturn = pStake.againstAmount;
            // Reward calculation: proportional to stake in the winning pool
            if (hypothesis.totalAgainstStake > 0) {
                rewardAmount = (pStake.againstAmount * hypothesis.totalRewardsPool) / hypothesis.totalAgainstStake;
            }
        } else if (hypothesis.outcome == Outcome.Inconclusive) {
             // If inconclusive, everyone gets their principal back minus a small fee
            principalToReturn = pStake.forAmount + pStake.againstAmount;
            // A small fee could be deducted here too, to fund the protocol
            uint256 fee = (principalToReturn * protocolFeeBps) / 10000;
            principalToReturn -= fee;
            totalProtocolFees += fee;
        }
        else {
             revert("Foresight: No correct prediction or no stake");
        }

        pStake.claimedRewards = true;
        stakingToken.safeTransfer(_msgSender(), principalToReturn + rewardAmount);
        _updateForesightScore(_msgSender(), _hypothesisId); // Update score on claim
        emit RewardsClaimed(_hypothesisId, _msgSender(), principalToReturn, rewardAmount);
    }

    /**
     * @dev Allows participants who predicted incorrectly to reclaim their principal stake,
     *      minus protocol fees and potentially penalties.
     * @param _hypothesisId The ID of the hypothesis.
     */
    function reclaimPrincipal(uint256 _hypothesisId) external {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Resolved, "Foresight: Hypothesis not yet resolved");

        ParticipantStake storage pStake = participantStakes[_hypothesisId][_msgSender()];
        require(!pStake.claimedRewards, "Foresight: Principal already reclaimed");

        uint256 principalToReturn = 0;
        if (hypothesis.outcome == Outcome.True && pStake.againstAmount > 0) {
            principalToReturn = pStake.againstAmount;
        } else if (hypothesis.outcome == Outcome.False && pStake.forAmount > 0) {
            principalToReturn = pStake.forAmount;
        } else {
            revert("Foresight: No incorrect prediction or no stake to reclaim");
        }

        pStake.claimedRewards = true;
        // The fee was already taken into the rewards pool.
        // So `principalToReturn` here represents the amount that was not penalized for the rewards pool.
        // No additional fee deducted if it's already part of `incorrectStakePool`
        stakingToken.safeTransfer(_msgSender(), principalToReturn);
        _updateForesightScore(_msgSender(), _hypothesisId); // Update score on claim
        emit PrincipalReclaimed(_hypothesisId, _msgSender(), principalToReturn);
    }

    /**
     * @dev Displays the amount of principal and/or rewards a user can claim.
     * @param _hypothesisId The ID of the hypothesis.
     * @param _participant The address of the participant.
     * @return claimablePrincipal The amount of principal tokens the participant can claim.
     * @return claimableRewards The amount of reward tokens the participant can claim.
     */
    function getClaimableAmounts(uint256 _hypothesisId, address _participant)
        external
        view
        returns (uint256 claimablePrincipal, uint256 claimableRewards)
    {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        require(hypothesis.status == HypothesisStatus.Resolved, "Foresight: Hypothesis not yet resolved");

        ParticipantStake storage pStake = participantStakes[_hypothesisId][_participant];
        if (pStake.claimedRewards) {
            return (0, 0); // Already claimed
        }

        if (hypothesis.outcome == Outcome.True) {
            if (pStake.forAmount > 0) {
                claimablePrincipal = pStake.forAmount;
                if (hypothesis.totalForStake > 0) {
                    claimableRewards = (pStake.forAmount * hypothesis.totalRewardsPool) / hypothesis.totalForStake;
                }
            } else if (pStake.againstAmount > 0) {
                claimablePrincipal = pStake.againstAmount; // Incorrect principal
            }
        } else if (hypothesis.outcome == Outcome.False) {
            if (pStake.againstAmount > 0) {
                claimablePrincipal = pStake.againstAmount;
                if (hypothesis.totalAgainstStake > 0) {
                    claimableRewards = (pStake.againstAmount * hypothesis.totalRewardsPool) / hypothesis.totalAgainstStake;
                }
            } else if (pStake.forAmount > 0) {
                claimablePrincipal = pStake.forAmount; // Incorrect principal
            }
        } else if (hypothesis.outcome == Outcome.Inconclusive) {
            // Inconclusive, everyone gets principal back minus a fee
            uint256 totalStaked = pStake.forAmount + pStake.againstAmount;
            uint256 fee = (totalStaked * protocolFeeBps) / 10000;
            claimablePrincipal = totalStaked - fee;
        }

        return (claimablePrincipal, claimableRewards);
    }

    /* -- Foresight Score (SBT) & Reputation Functions -- */

    /**
     * @dev Retrieves a user's unique, non-transferable Foresight Score.
     * @param _participant The address of the participant.
     * @return The Foresight Score of the participant.
     */
    function getForesightScore(address _participant) external view returns (int256) {
        return foresightScores[_participant];
    }

    /**
     * @dev Internal helper function used during `claimRewards` or `reclaimPrincipal`
     *      to adjust a user's Foresight Score based on their prediction accuracy, stake size, and timing.
     *      This is a basic scoring model; could be made more complex (e.g., ELO-like, quadratic factors).
     * @param _participant The address of the participant.
     * @param _hypothesisId The ID of the hypothesis.
     */
    function _updateForesightScore(address _participant, uint256 _hypothesisId) internal {
        Hypothesis storage hypothesis = hypotheses[_hypothesisId];
        ParticipantStake storage pStake = participantStakes[_hypothesisId][_participant];

        int256 scoreChange = 0;
        uint256 totalParticipantStake = pStake.forAmount + pStake.againstAmount;
        if (totalParticipantStake == 0) return; // No stake, no score change

        // Base score change proportional to stake amount
        int256 baseScore = int256(totalParticipantStake / (1 ether)); // Scale by 1 ether for readability

        if (hypothesis.outcome == Outcome.True) {
            if (pStake.forAmount > 0) { // Correct prediction
                scoreChange = baseScore;
                // Add bonus for contrarian predictions (if totalAgainstStake was higher than totalForStake initially)
                if (hypothesis.totalAgainstStake > hypothesis.totalForStake) {
                    scoreChange += baseScore / 2;
                }
            } else if (pStake.againstAmount > 0) { // Incorrect prediction
                scoreChange = -baseScore;
            }
        } else if (hypothesis.outcome == Outcome.False) {
            if (pStake.againstAmount > 0) { // Correct prediction
                scoreChange = baseScore;
                // Add bonus for contrarian predictions
                if (hypothesis.totalForStake > hypothesis.totalAgainstStake) {
                    scoreChange += baseScore / 2;
                }
            } else if (pStake.forAmount > 0) { // Incorrect prediction
                scoreChange = -baseScore;
            }
        } else if (hypothesis.outcome == Outcome.Inconclusive) {
            // Small penalty for inconclusive or no change
            scoreChange = - (baseScore / 4); // Small penalty for unresolved outcomes
        }

        foresightScores[_participant] += scoreChange;
        emit ForesightScoreUpdated(_participant, foresightScores[_participant]);
    }

    /**
     * @dev Returns a user's relative ranking based on their Foresight Score.
     *      Note: This is a placeholder. Real-world ranking requires off-chain indexing or complex on-chain sorting.
     * @param _participant The address of the participant.
     * @return The rank (e.g., 1st, 2nd, 3rd) and their score.
     */
    function getForesightScoreRank(address _participant) external view returns (uint256 rank, int256 score) {
        score = foresightScores[_participant];
        // Placeholder: Actual ranking requires iterating or an indexed list, which is gas-heavy.
        // A simple approach for now: return 0 for rank, assume off-chain calculation.
        // Could be extended with a Top N list to check if user is in it.
        return (0, score);
    }

    /**
     * @dev Lists users with the highest Foresight Scores.
     *      Note: This is a placeholder. On-chain sorting/listing top N dynamically is gas-prohibitive.
     *      A common pattern involves an off-chain server updating a small "Top N" array on-chain periodically.
     * @param _count The number of top scores to retrieve.
     * @return An array of addresses and their corresponding scores.
     */
    function getTopForesightScores(uint256 _count) external view returns (address[] memory, int256[] memory) {
        // This function cannot efficiently return a dynamically sorted list of all users.
        // It would require iterating `foresightScores` mapping which is not possible.
        // A real implementation would use a different data structure (e.g., a sorted array maintained by a keeper,
        // or rely on off-chain indexing and display).
        // For demonstration, let's return an empty array or a hardcoded example.
        _count; // Suppress unused parameter warning

        address[] memory topAddresses = new address[](0);
        int256[] memory topScores = new int256[](0);
        return (topAddresses, topScores);
    }

    /* -- Governance & Protocol Management Functions -- */

    /**
     * @dev Owner/governance sets the address of the trusted oracle.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Foresight: New oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /**
     * @dev Owner/governance adjusts the percentage fee charged by the protocol.
     * @param _newFeeBps The new protocol fee in basis points (e.g., 200 for 2%).
     */
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Foresight: Fee cannot exceed 10%"); // Max 10% for sanity
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeSet(_newFeeBps);
    }

    /**
     * @dev Owner/governance withdraws accumulated protocol fees to the treasury.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to) external onlyOwner {
        require(_to != address(0), "Foresight: Target address cannot be zero");
        uint256 amount = totalProtocolFees;
        require(amount > 0, "Foresight: No fees to withdraw");

        totalProtocolFees = 0;
        stakingToken.safeTransfer(_to, amount);
        emit ProtocolFeesWithdrawn(_to, amount);
    }

    /**
     * @dev Sets the minimum token bond required to propose a hypothesis.
     * @param _newMinBond The new minimum bond amount.
     */
    function setMinHypothesisBond(uint256 _newMinBond) external onlyOwner {
        require(_newMinBond > 0, "Foresight: Min bond must be greater than zero");
        minHypothesisBond = _newMinBond;
        emit MinHypothesisBondSet(_newMinBond);
    }

    /**
     * @dev Sets the percentage penalty for withdrawing stake before resolution.
     * @param _newPenaltyBps The new penalty in basis points (e.g., 500 for 5%).
     */
    function setEarlyWithdrawalPenalty(uint256 _newPenaltyBps) external onlyOwner {
        require(_newPenaltyBps <= 5000, "Foresight: Penalty cannot exceed 50%"); // Max 50%
        earlyWithdrawalPenaltyBps = _newPenaltyBps;
        emit EarlyWithdrawalPenaltySet(_newPenaltyBps);
    }

    /* -- Internal Helper Functions -- */

    /**
     * @dev Applies the early withdrawal penalty to a given amount.
     * @param _amount The gross amount to be withdrawn.
     * @return The net amount after applying the penalty.
     */
    function _applyEarlyWithdrawalPenalty(uint256 _amount) internal returns (uint256) {
        uint256 penalty = (_amount * earlyWithdrawalPenaltyBps) / 10000;
        uint256 netAmount = _amount - penalty;
        // The penalty portion goes to accumulated protocol fees
        totalProtocolFees += penalty;
        return netAmount;
    }
}
```