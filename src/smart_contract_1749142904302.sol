Okay, here is a Solidity smart contract featuring a "Dynamic Protocol Vault (DPV)" concept. This contract combines elements of staking, a unique on-chain "Karma" reputation system, time-based mechanics, and a basic internal governance/proposal mechanism, tied together with role-based access control and pausing.

It aims to be creative and avoid direct copy-pasting of standard implementations (like a full ERC20, standard SafeMath, or OpenZeppelin Governor/Timelock, though it uses interfaces and basic patterns). The "Karma" system and its integration with yield/penalties and voting are the primary unique concepts here.

**Disclaimer:** This contract is for educational and demonstration purposes. It implements complex logic and would require significant security audits, gas optimization, and testing before being deployed in a production environment with real assets. Implementing a truly secure and robust governance system is highly complex.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Dynamic Protocol Vault (DPV)
 * @dev A smart contract implementing a staking vault with a dynamic Karma system,
 *      time-based rewards/penalties, and internal proposal/voting mechanics.
 *
 * Outline:
 * 1. Contract Overview
 * 2. State Variables
 * 3. Events
 * 4. Modifiers
 * 5. Core Staking & Asset Management Functions (7)
 * 6. Karma System Functions (5)
 * 7. Governance & Proposal Functions (6)
 * 8. Configuration & Admin Functions (9)
 * 9. Utility & Information Functions (2)
 *
 * Total Functions: 7 + 5 + 6 + 9 + 2 = 29 functions.
 *
 * Function Summary:
 * - constructor: Initializes the contract with the vault asset token and deployer as admin.
 * - stake: Allows users to deposit and stake the vault asset.
 * - withdraw: Allows users to withdraw their staked assets (potentially with a penalty based on karma).
 * - claimKarmaRewards: Allows users to claim accrued karma based on their staking duration.
 * - getUserStakedAmount: Gets the amount of tokens staked by a user.
 * - getTotalStaked: Gets the total amount of tokens staked in the vault.
 * - sweepExtraTokens: Admin function to recover accidentally sent ERC20 tokens (excluding the vault asset).
 * - getUserKarma: Gets a user's current karma score.
 * - calculatePendingKarma: Calculates the amount of karma a user is eligible to claim.
 * - getKarmaBoostedPenaltyReduction: Calculates the percentage reduction in withdrawal penalty based on karma.
 * - penalizeUserKarmaAndStake: Admin function to reduce a user's karma and optionally stake for rule violations.
 * - rewardUserKarma: Admin function to increase a user's karma score.
 * - proposeAction: Allows high-karma users to propose arbitrary contract calls for governance.
 * - voteOnProposal: Allows users with sufficient karma to vote on active proposals.
 * - executeProposal: Allows anyone to execute a successful, time-locked proposal.
 * - getProposalState: Gets the current state of a specific proposal.
 * - getProposalDetails: Gets the details of a specific proposal.
 * - getQuorumNeeded: Gets the current required quorum for proposal success.
 * - addAdminRole: Grants admin privileges to an address.
 * - removeAdminRole: Revokes admin privileges from an address.
 * - hasAdminRole: Checks if an address has admin privileges.
 * - setCriticalKarmaThreshold: Sets the karma threshold below which penalties are more severe.
 * - setEarlyWithdrawPenaltyBps: Sets the base early withdrawal penalty rate in basis points.
 * - setKarmaRatePerSecond: Sets the rate at which karma accrues based on staked amount and time.
 * - setPenaltyKarmaLoss: Sets the amount of karma lost when a penalty is applied.
 * - setProposalConfig: Sets parameters for the proposal system (threshold, voting period, timelock, quorum).
 * - pauseStaking: Admin function to pause new staking deposits.
 * - unpauseStaking: Admin function to unpause staking.
 * - getTimeUntilExecution: Gets the remaining time until a successful proposal can be executed.
 * - getVersion: Returns the contract version string.
 */
contract DynamicProtocolVault {
    using Address for address; // Using Address utility for safety checks

    // --- State Variables ---

    // Vault Asset Token
    IERC20 public immutable vaultAsset;

    // Staking Data
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint48) public lastInteractionTime; // Use uint48 for gas efficiency if block.timestamp fits
    uint256 public totalStakedSupply;

    // Karma System
    mapping(address => int96) public userKarma; // Use int96, allows negative, fits in uint256 slot
    int96 public constant MIN_KARMA = -5000; // Define bounds for karma
    int96 public constant MAX_KARMA = 10000;
    uint256 public karmaRatePerSecond; // Karma accrual rate (per 1e18 tokens staked per second)
    int96 public criticalKarmaThreshold; // Below this karma, penalties apply
    uint256 public earlyWithdrawPenaltyBps; // Base penalty for early withdrawal (basis points)
    int96 public penaltyKarmaLoss; // Karma lost upon penalty application

    // Access Control (Role-Based)
    mapping(address => bool) public admins;

    // Pausing
    bool public paused = false;

    // Governance (Basic Internal Proposal System)
    struct Proposal {
        uint256 id;
        address proposer;
        address targetContract; // The contract address to call
        bytes callData; // The data to send with the call
        string description; // Description of the proposal
        uint48 creationTime;
        uint48 votingDeadline;
        uint48 executionTime;
        uint256 forVotes; // Total weighted votes (sum of voter karma)
        uint256 againstVotes; // Total weighted votes (sum of voter karma)
        bool executed;
        bool canceled; // Maybe implemented later, or just defeated
        mapping(address => bool) hasVoted; // Which addresses have voted (saves gas vs mapping in state)
        ProposalState state;
    }

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed } // No Cancelled for simplicity

    Proposal[] public proposals; // Array of all proposals
    uint256 public proposalCount; // Counter for proposal IDs

    uint256 public proposalThresholdKarma; // Minimum karma required to propose
    uint256 public votingPeriodDuration; // Duration of the voting period in seconds
    uint256 public timelockDelay; // Delay after success before execution in seconds
    uint256 public quorumPercent; // Percentage of total possible vote weight (total positive karma) required for quorum (e.g., 4000 for 40%)

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event Withdrawn(address indexed user, uint256 amount, uint256 penaltyApplied, uint256 newTotalStaked);
    event KarmaClaimed(address indexed user, int96 amount, int96 newKarma);
    event KarmaUpdated(address indexed user, int96 oldKarma, int96 newKarma, string reason);
    event PenaltyApplied(address indexed user, int96 karmaLost, uint256 stakeReduced);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint48 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool decision, int96 voteWeight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event AdminRoleGranted(address indexed account);
    event AdminRoleRevoked(address indexed account);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(admins[msg.sender], "DPV: Caller is not an admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DPV: Contract is paused");
        _;
    }

    // --- Constructor ---

    constructor(address _vaultAsset, uint256 _karmaRatePerSecond, int96 _criticalKarmaThreshold, uint256 _earlyWithdrawPenaltyBps, int96 _penaltyKarmaLoss, uint256 _proposalThresholdKarma, uint256 _votingPeriodDuration, uint256 _timelockDelay, uint256 _quorumPercent) {
        vaultAsset = IERC20(_vaultAsset);
        admins[msg.sender] = true;
        emit AdminRoleGranted(msg.sender);

        karmaRatePerSecond = _karmaRatePerSecond;
        criticalKarmaThreshold = _criticalKarmaThreshold;
        earlyWithdrawPenaltyBps = _earlyWithdrawPenaltyBps;
        penaltyKarmaLoss = _penaltyKarmaLoss;

        proposalThresholdKarma = _proposalThresholdKarma;
        votingPeriodDuration = _votingPeriodDuration;
        timelockDelay = _timelockDelay;
        quorumPercent = _quorumPercent;

        // Sanity checks
        require(_quorumPercent <= 10000, "DPV: Quorum percent invalid");
        require(_earlyWithdrawPenaltyBps <= 10000, "DPV: Penalty BPS invalid");
    }

    // --- Core Staking & Asset Management Functions (7) ---

    /**
     * @dev Stakes tokens in the vault.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "DPV: Amount must be greater than 0");
        uint256 currentStaked = stakedBalances[msg.sender];

        // Claim pending karma before staking again
        claimKarmaRewards(msg.sender);

        // Transfer tokens to the contract
        vaultAsset.transferFrom(msg.sender, address(this), amount);

        // Update state
        stakedBalances[msg.sender] = currentStaked + amount;
        totalStakedSupply += amount;
        lastInteractionTime[msg.sender] = uint48(block.timestamp);

        emit Staked(msg.sender, amount, totalStakedSupply);
    }

    /**
     * @dev Allows users to withdraw their staked assets.
     *      Applies a penalty if user karma is below the critical threshold.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external {
        uint256 userBalance = stakedBalances[msg.sender];
        require(amount > 0, "DPV: Amount must be greater than 0");
        require(amount <= userBalance, "DPV: Insufficient staked balance");

        // Claim pending karma before withdrawal
        claimKarmaRewards(msg.sender);

        uint256 withdrawalAmount = amount;
        uint256 penaltyAmount = 0;

        int96 currentUserKarma = userKarma[msg.sender];

        // Check if penalty applies
        if (currentUserKarma < criticalKarmaThreshold) {
            uint256 basePenalty = (amount * earlyWithdrawPenaltyBps) / 10000;
            int96 penaltyReductionBps = getKarmaBoostedPenaltyReduction(currentUserKarma); // Calculate reduction based on (negative) karma
            uint256 effectivePenalty = (basePenalty * (10000 - uint256(int256(penaltyReductionBps)))) / 10000; // Apply reduction (reduction is positive, so subtract from 10000)

            penaltyAmount = effectivePenalty;
            withdrawalAmount = amount - penaltyAmount;

            // Reduce user karma as part of the penalty logic
             _updateUserKarma(msg.sender, -penaltyKarmaLoss, "Early withdrawal penalty");
        }

        // Ensure withdrawal amount is not negative (shouldn't happen with uint, but good logic check)
        require(withdrawalAmount <= amount, "DPV: Internal penalty calculation error");
        require(withdrawalAmount <= userBalance, "DPV: Withdrawal exceeds balance after penalty consideration");


        // Update state
        stakedBalances[msg.sender] = userBalance - amount; // Reduce by requested amount, penalty is deducted from withdrawal amount
        totalStakedSupply -= amount;
         lastInteractionTime[msg.sender] = uint48(block.timestamp); // Update interaction time

        // Transfer tokens back to the user
        vaultAsset.transfer(msg.sender, withdrawalAmount);

        // Note: Penalty amount remains in the contract or can be directed elsewhere later
        // For now, it effectively stays in the contract, reducing total tokens vs total staked balance difference.

        emit Withdrawn(msg.sender, amount, penaltyAmount, totalStakedSupply);
    }


    /**
     * @dev Allows a user to claim their accrued karma rewards based on staking time.
     * @param user The address to claim karma for (allows admin/self-claim).
     */
    function claimKarmaRewards(address user) public {
        uint48 lastInteraction = lastInteractionTime[user];
        uint256 stakedAmount = stakedBalances[user];
        int96 currentKarma = userKarma[user];

        // No karma accrual if nothing staked or no time has passed
        if (stakedAmount == 0 || lastInteraction == 0 || block.timestamp <= lastInteraction) {
            return;
        }

        uint256 timeElapsed = block.timestamp - lastInteraction;
        // Calculate karma proportional to staked amount and time, using karmaRatePerSecond (scaled)
        // Assumes karmaRatePerSecond is per 1e18 (standard token decimals)
        uint256 karmaEarnedScaled = (stakedAmount * timeElapsed * karmaRatePerSecond);
        // Convert scaled karma to base units (assuming karma is not 1e18, but 1 unit = 1 karma)
        // This part depends on how karmaRatePerSecond is defined (e.g., if it's 1e18 per unit karma per sec per token)
        // Let's simplify: karmaRatePerSecond is fixed. Staked amount is scaled.
        // Simplified karma accrual: time * (stakedAmount / 1e18) * karmaRatePerSecond
        // To avoid division before multiplication and handle large numbers:
        // karma = (stakedAmount * karmaRatePerSecond / (10**vaultAsset.decimals())) * timeElapsed;
        // Or, even simpler if karmaRatePerSecond is defined carefully (e.g., basis points per sec per token unit):
        // karmaEarned = (stakedAmount * karmaRatePerSecond * timeElapsed) / SOME_SCALING_FACTOR;
        // Let's assume karmaRatePerSecond is set such that multiplying by stakedAmount (full decimals) and timeElapsed gives a result that, when divided by 1e18, gives the integer/fixed-point karma earned.
        // uint256 karmaEarnedScaled = (stakedAmount * timeElapsed * karmaRatePerSecond) / 1e18;
        // Let's refine: karmaRatePerSecond is the amount of karma earned per staked token per second.
         uint256 karmaEarned = (stakedAmount / (10**vaultAsset.decimals())) * timeElapsed * (karmaRatePerSecond / (10**vaultAsset.decimals()));
         // This still feels clunky. Let's define karmaRatePerSecond as e.g. 10 (meaning 10 karma per token per second)
         // Let's make it simpler: karma is earned based *only* on time elapsed per user, maybe weighted by their average stake during that time? No, that's complex.
         // Let's go back to: karmaRatePerSecond is a rate. Let's say it's 10 (meaning 10 units of karma).
         // Karma earned = (stakedAmount * timeElapsed * karmaRatePerSecond) / 1e18; // this makes more sense if rate is small
         // Example: 100 tokens staked (100 * 1e18). 1 sec. rate = 1e16 (0.01 karma per token per sec)
         // Karma = (100 * 1e18 * 1 * 1e16) / 1e18 = 100 * 1e16 = 1e18. Too large.

         // Let's define karmaRatePerSecond as the amount of karma units earned per staked token *unit* per second.
         // Example: 1 token (1e18). 1 second. rate = 1e-5 (very small).
         // Karma = (stakedAmount * timeElapsed * karmaRatePerSecond) / (10**vaultAsset.decimals());
         // Example: stakedAmount = 1e18. timeElapsed = 1. rate = 1e-5. decimals=18.
         // Karma = (1e18 * 1 * 1e-5) / 1e18 = 1e-5. Still not integer karma.

         // Simplest approach: Karma earned is proportional *only* to time, maybe slightly weighted by current stake?
         // Let's make it simpler: Karma earned is a flat rate per second * weighted by current stake amount vs total. No.
         // Let's make karma earned proportional to time elapsed * MIN(userStake, MaxClaimablePerPeriod)
         // Let's redefine: karmaRatePerSecond is simply a rate applied *per staked token* per second.
         // `karmaEarned = (stakedAmount * timeElapsed * karmaRatePerSecond) / (10 ** vaultAsset.decimals())` This seems reasonable if karmaRatePerSecond is small.
         // Example: 1 token (1e18), 1 second, rate = 10000 (0.0001 per sec per token).
         // Karma = (1e18 * 1 * 10000) / 1e18 = 10000. Too big.

         // Let's try again: karmaRatePerSecond = karma units per second *per 1e18 tokens*.
         // karmaEarned = (stakedAmount * timeElapsed * karmaRatePerSecond) / 1e18;
         // Example: 100 tokens (100*1e18). 1 sec. rate = 1e15 (0.001 karma per sec per 1e18).
         // Karma = (100 * 1e18 * 1 * 1e15) / 1e18 = 100 * 1e15 = 1e17. Still large integers.

         // OK, let's define `karmaRatePerSecond` as the *integer* karma units gained per staked token *unit* per second (scaled by 1e18 for fixed point).
         // So, if `karmaRatePerSecond = 1e10`, this means `1e10 / 1e18` karma per token unit per second.
         uint256 karmaUnits = (stakedAmount * timeElapsed * karmaRatePerSecond) / (10**vaultAsset.decimals());
         // Now `karmaUnits` is scaled by 1e18. Let's convert to integer karma units.
         int96 karmaEarnedInt = int96(karmaUnits / (1e18)); // Integer karma units

        // Update karma, respecting bounds
        int96 newKarma = currentKarma + karmaEarnedInt;
        newKarma = newKarma > MAX_KARMA ? MAX_KARMA : newKarma;
        newKarma = newKarma < MIN_KARMA ? MIN_KARMA : newKarma;

        if (newKarma != currentKarma) {
            userKarma[user] = newKarma;
            emit KarmaClaimed(user, karmaEarnedInt, newKarma);
             emit KarmaUpdated(user, currentKarma, newKarma, "Claimed staking rewards");
        }

        // Update last interaction time AFTER calculation
        lastInteractionTime[user] = uint48(block.timestamp);
    }


    /**
     * @dev Gets the amount of tokens staked by a user.
     * @param user The address of the user.
     * @return The staked amount.
     */
    function getUserStakedAmount(address user) external view returns (uint256) {
        return stakedBalances[user];
    }

    /**
     * @dev Gets the total amount of tokens staked in the vault.
     * @return The total staked amount.
     */
    function getTotalStaked() external view returns (uint256) {
        return totalStakedSupply;
    }

     /**
     * @dev Allows admin to recover accidentally sent ERC20 tokens (not vaultAsset).
     * @param tokenAddress The address of the ERC20 token to sweep.
     * @param amount The amount to sweep.
     */
    function sweepExtraTokens(address tokenAddress, uint256 amount) external onlyAdmin {
        require(tokenAddress != address(vaultAsset), "DPV: Cannot sweep the vault asset");
        IERC20 extraToken = IERC20(tokenAddress);
        extraToken.transfer(msg.sender, amount);
    }


    // --- Karma System Functions (5) ---

    /**
     * @dev Gets a user's current karma score.
     * @param user The address of the user.
     * @return The karma score.
     */
    function getUserKarma(address user) external view returns (int96) {
        return userKarma[user];
    }

    /**
     * @dev Calculates the pending karma a user is eligible to claim.
     * @param user The address of the user.
     * @return The pending karma amount.
     */
    function calculatePendingKarma(address user) external view returns (int96) {
        uint48 lastInteraction = lastInteractionTime[user];
        uint256 stakedAmount = stakedBalances[user];

         if (stakedAmount == 0 || lastInteraction == 0 || block.timestamp <= lastInteraction) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInteraction;
         uint256 karmaUnits = (stakedAmount * timeElapsed * karmaRatePerSecond) / (10**vaultAsset.decimals());
         int96 karmaEarnedInt = int96(karmaUnits / (1e18));
        return karmaEarnedInt;
    }

    /**
     * @dev Calculates the percentage reduction in withdrawal penalty based on karma.
     *      More positive karma means higher reduction (capped), negative karma means no reduction (or even increase).
     * @param karma The karma score.
     * @return The penalty reduction in basis points (0-10000).
     */
    function getKarmaBoostedPenaltyReduction(int96 karma) public view returns (int96) {
         // Example logic: Linear boost from criticalThreshold up to MAX_KARMA
         // Below criticalThreshold, reduction is 0 or negative (increase penalty).
         // Between criticalThreshold and 0, reduction is 0 or small.
         // Between 0 and MAX_KARMA, reduction increases.
         // Max reduction happens at MAX_KARMA.
         // Let's make it simple: Reduction is (karma / MAX_KARMA) * 10000, but capped at MAX_KARMA and floored at criticalThreshold (or 0).

         if (karma <= criticalKarmaThreshold) {
             return 0; // No reduction, full penalty applies below or at critical threshold
         }

         // Calculate a linear reduction factor between criticalThreshold and MAX_KARMA
         // Factor is 0 at criticalThreshold, and 1 at MAX_KARMA.
         // reduction = (karma - criticalThreshold) / (MAX_KARMA - criticalThreshold) * 10000
         // Need to handle division carefully.
         // Max possible positive karma above threshold: MAX_KARMA - criticalKarmaThreshold
         // Current karma above threshold: karma - criticalKarmaThreshold

         uint256 karmaAboveThreshold = uint256(int256(karma - criticalKarmaThreshold));
         uint256 maxKarmaAboveThreshold = uint256(int256(MAX_KARMA - criticalKarmaThreshold));

         if (maxKarmaAboveThreshold == 0) return 0; // Avoid division by zero

         // Calculate reduction percentage (0-10000)
         uint256 reductionBps = (karmaAboveThreshold * 10000) / maxKarmaAboveThreshold;

         return int96(reductionBps); // Return as int96 to match karma type, although it's non-negative BPS
    }


    /**
     * @dev Admin function to penalize a user's karma and optionally reduce their stake.
     * @param user The address of the user to penalize.
     * @param stakeReductionAmount The amount of stake to reduce (optional).
     */
    function penalizeUserKarmaAndStake(address user, uint256 stakeReductionAmount) external onlyAdmin {
         require(user != address(0), "DPV: Invalid user address");

         // Reduce karma
        int96 currentKarma = userKarma[user];
        int96 newKarma = currentKarma - penaltyKarmaLoss;
        newKarma = newKarma < MIN_KARMA ? MIN_KARMA : newKarma;
        _updateUserKarma(user, newKarma - currentKarma, "Admin penalty"); // Record delta

        // Reduce stake if requested
        if (stakeReductionAmount > 0) {
            uint256 currentStaked = stakedBalances[user];
            require(stakeReductionAmount <= currentStaked, "DPV: Stake reduction exceeds user balance");

            stakedBalances[user] = currentStaked - stakeReductionAmount;
            totalStakedSupply -= stakeReductionAmount;

             // The reduced stake effectively stays in the contract, similar to a withdrawal penalty.
             // Emit event or handle separately if needed.
             // No transfer out happens here.

            emit PenaltyApplied(user, penaltyKarmaLoss, stakeReductionAmount);
        } else {
            emit PenaltyApplied(user, penaltyKarmaLoss, 0);
        }
    }

    /**
     * @dev Admin function to reward a user by increasing their karma score.
     * @param user The address of the user to reward.
     * @param amount The amount of karma to add.
     */
    function rewardUserKarma(address user, int96 amount) external onlyAdmin {
        require(user != address(0), "DPV: Invalid user address");
        require(amount > 0, "DPV: Amount must be positive");

        _updateUserKarma(user, amount, "Admin reward");
    }

     /**
     * @dev Internal function to update user karma and enforce bounds.
     * @param user The address of the user.
     * @param karmaDelta The amount of karma to add or subtract.
     * @param reason The reason for the karma update.
     */
    function _updateUserKarma(address user, int96 karmaDelta, string memory reason) internal {
        int96 currentKarma = userKarma[user];
        int96 newKarma = currentKarma + karmaDelta;

        newKarma = newKarma > MAX_KARMA ? MAX_KARMA : newKarma;
        newKarma = newKarma < MIN_KARMA ? MIN_KARMA : newKarma;

        if (newKarma != currentKarma) {
            userKarma[user] = newKarma;
            emit KarmaUpdated(user, currentKarma, newKarma, reason);
        }
    }


    // --- Governance & Proposal Functions (6) ---

    /**
     * @dev Allows a user with sufficient karma to propose an action.
     * @param targetContract The address of the contract to call.
     * @param callData The encoded function call data.
     * @param description A brief description of the proposal.
     * @return The ID of the created proposal.
     */
    function proposeAction(address targetContract, bytes memory callData, string memory description) external returns (uint256) {
        // Claim karma before proposing to ensure current karma is used for threshold check
        claimKarmaRewards(msg.sender);
        require(userKarma[msg.sender] >= int96(int256(proposalThresholdKarma)), "DPV: Insufficient karma to propose");
        require(targetContract.isContract(), "DPV: Target must be a contract");
         // Basic sanity checks on callData? Complex to do generally.

        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals.push(); // Add new proposal to the array
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.targetContract = targetContract;
        newProposal.callData = callData;
        newProposal.description = description;
        newProposal.creationTime = uint48(block.timestamp);
        newProposal.votingDeadline = uint48(block.timestamp + votingPeriodDuration);
        // Execution time is set upon success after timelock

        newProposal.state = ProposalState.Active; // Starts in Active state

        emit ProposalCreated(proposalId, msg.sender, description, newProposal.votingDeadline);

        return proposalId;
    }

    /**
     * @dev Allows a user with sufficient karma to vote on an active proposal.
     * @param proposalId The ID of the proposal.
     * @param support True for 'for' vote, False for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        require(proposal.state == ProposalState.Active, "DPV: Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "DPV: Voting period has ended");
         // Claim karma before voting to ensure current karma is used for weight
        claimKarmaRewards(msg.sender);
        int96 voterKarma = userKarma[msg.sender];
        require(voterKarma > 0, "DPV: Voter karma must be positive to cast weighted vote"); // Only positive karma votes count towards weight

        require(!proposal.hasVoted[msg.sender], "DPV: Already voted on this proposal");

        // Karma-weighted vote: add user's positive karma to the respective vote count
        if (support) {
            proposal.forVotes += uint256(int256(voterKarma)); // Use uint256 for sum, requires cast from int96
        } else {
            proposal.againstVotes += uint256(int256(voterKarma));
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voterKarma);

        // Optional: Transition state if voting ends immediately, but usually done by execute
        // For simplicity, state transition (Succeeded/Defeated) happens upon checking before execution
    }

    /**
     * @dev Allows anyone to trigger the execution of a successful and time-locked proposal.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) external {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Check if voting period is over and transition state if needed
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
            uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
            // Calculate total possible voting weight (sum of all users' positive karma)
            // This is complex to calculate on-chain accurately without iterating.
            // Alternative: Quorum is percentage of *cast* votes, not total possible.
            // Let's redefine quorum: it's a percentage of total *positive* karma *currently* in the system when voting ends.
            // This requires tracking sum of positive karma, which is state-heavy.

            // Simpler Quorum: percentage of *FOR* votes relative to *total positive karma cast*.
            // Quorum check: `proposal.forVotes >= (totalPositiveKarmaAtDeadline * quorumPercent) / 10000`
            // This requires snapshotting or calculating total positive karma.

            // Let's make quorum a percentage of *total cast votes* (for + against), and ALSO require FOR > AGAINST.
            // Quorum Check: totalVotes >= (getTotalPositiveKarmaInSystemAtSnapshot * quorumPercent / 10000)
            // This is still hard.

            // Easiest Quorum: Total `forVotes` must meet a percentage of `totalStakedSupply` (as a proxy for system size/engagement).
            // This ties stake to voting power, which is common. Let's use staked balance for voting weight and quorum.
            // Let's revise `voteOnProposal` to use `stakedBalances[msg.sender]` as vote weight.
            // And revise `proposeAction` threshold to be based on staked amount.

            // --- REVISING VOTING MECHANISM ---
            // Let's switch vote weight from Karma to Staked Amount for simplicity and practicality.
            // This is a common pattern (token-weighted voting). Karma will influence other things (yield/penalties).
            // `proposeAction`: requires `stakedBalances[msg.sender] >= proposalThresholdStakeAmount`.
            // `voteOnProposal`: vote weight is `stakedBalances[msg.sender]`. Quorum is percentage of `totalStakedSupply` when voting ends.

            // Okay, revising the plan to use staked amount for voting weight and karma for other benefits.
            // Need to update `Proposal` struct, `proposeAction`, `voteOnProposal`, `setProposalConfig`

            // --- RE-DOING GOVERNANCE FUNCTIONS ---
            // (Self-correction during thinking process)

            // New Proposal struct:
            // struct Proposal { ... uint256 forVotesStake; uint256 againstVotesStake; mapping(address => bool) hasVoted; ... }
            // proposeAction: requires stakedBalances[msg.sender] >= proposalThresholdStakeAmount
            // voteOnProposal: weight is stakedBalances[msg.sender]. Add to forVotesStake or againstVotesStake.
            // executeProposal: check voting deadline. Calculate quorum based on totalStakedSupply at deadline. Check forVotesStake > againstVotesStake. Check timelock. Execute.

            // Updating state variables and functions based on this revised plan:
            // Add: uint256 public proposalThresholdStakeAmount; (replaces proposalThresholdKarma)
            // Update: proposeAction, voteOnProposal, executeProposal, setProposalConfig

            // --- Let's implement the revised governance ---

            // --- Back to executeProposal ---
            // Assuming revised governance is in place:
            uint256 totalVotesCast = proposal.forVotesStake + proposal.againstVotesStake;
            uint256 totalPossibleQuorumStake; // This would ideally be totalStakedSupply at voting end. Hard to snapshot.
            // Let's make quorum a % of totalStakedSupply *when execute is called*, OR a minimum absolute amount.
            // Simpler: quorum is a % of totalStakedSupply *now*. This makes timing of execution matter for quorum.
            totalPossibleQuorumStake = totalStakedSupply; // Using current supply as proxy

            bool quorumMet = (totalVotesCast * 10000) / totalPossibleQuorumStake >= quorumPercent;
            bool majorityMet = proposal.forVotesStake > proposal.againstVotesStake;

            if (quorumMet && majorityMet) {
                proposal.state = ProposalState.Succeeded;
                // Set execution time only upon success
                proposal.executionTime = uint48(block.timestamp + timelockDelay);
                emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.Succeeded);
            } else {
                proposal.state = ProposalState.Defeated;
                emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.Defeated);
                // No further action needed for defeated proposals
                return;
            }
        }

        // Now check for execution eligibility (must be Succeeded and timelock passed)
        require(proposal.state == ProposalState.Succeeded, "DPV: Proposal must be in Succeeded state");
        require(block.timestamp >= proposal.executionTime, "DPV: Timelock not passed yet");
        require(!proposal.executed, "DPV: Proposal already executed");

        // Execute the proposal call
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);

        proposal.executed = true;
        proposal.state = ProposalState.Executed; // Final state

        emit ProposalExecuted(proposalId, success, result);
        // Note: Call failures are recorded but don't revert the execution transaction
    }


    /**
     * @dev Gets the current state of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The proposal state.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
         require(proposalId < proposalCount, "DPV: Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];

         // Determine state dynamically for Active/Succeeded/Defeated before execution
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
             // Check outcome to determine Succeeded or Defeated
             uint256 totalVotes = proposal.forVotesStake + proposal.againstVotesStake; // Use staked votes
             uint256 totalPossibleQuorumStake = totalStakedSupply; // Use current total stake for quorum check

             bool quorumMet = (totalVotes * 10000) / totalPossibleQuorumStake >= quorumPercent;
             bool majorityMet = proposal.forVotesStake > proposal.againstVotesStake;

             if (quorumMet && majorityMet) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Defeated;
             }
         }
         return proposal.state;
    }

    /**
     * @dev Gets the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return All relevant proposal details.
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        address targetContract,
        bytes memory callData,
        string memory description,
        uint48 creationTime,
        uint48 votingDeadline,
        uint48 executionTime,
        uint256 forVotesStake,
        uint256 againstVotesStake,
        bool executed,
        ProposalState state
    ) {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Return details including calculated state
        return (
            proposal.id,
            proposal.proposer,
            proposal.targetContract,
            proposal.callData,
            proposal.description,
            proposal.creationTime,
            proposal.votingDeadline,
            proposal.executionTime,
            proposal.forVotesStake,
            proposal.againstVotesStake,
            proposal.executed,
            getProposalState(proposalId) // Call helper to get dynamic state
        );
    }

    /**
     * @dev Gets the current required quorum for proposal success (as a percentage).
     *      Note: The actual quorum calculation uses total staked supply.
     * @return The quorum percentage (0-10000).
     */
    function getQuorumNeeded() external view returns (uint256) {
        return quorumPercent;
    }

    // --- Configuration & Admin Functions (9) ---

    /**
     * @dev Grants admin privileges to an address.
     * @param account The address to grant admin role to.
     */
    function addAdminRole(address account) external onlyAdmin {
        require(account != address(0), "DPV: Invalid address");
        require(!admins[account], "DPV: Account already has admin role");
        admins[account] = true;
        emit AdminRoleGranted(account);
    }

    /**
     * @dev Revokes admin privileges from an address.
     *      Cannot revoke own role unless there's another admin.
     * @param account The address to revoke admin role from.
     */
    function removeAdminRole(address account) external onlyAdmin {
        require(account != address(0), "DPV: Invalid address");
        require(admins[account], "DPV: Account does not have admin role");

        // Prevent removing the last admin role unless a recovery mechanism exists (not implemented)
        // Simple check: count admins. Or, require multiple admins before allowing removal.
        // For simplicity here, a single admin can remove themselves, which is risky.
        // A robust system would require multi-sig or DAO vote to change admins.
        // Let's add a basic check: must be at least one admin left OR caller is not the account being removed.
        // This is still not fully safe if one admin removes all others including themselves.
        // Proper access control (like OpenZeppelin's AccessControl) is better.
        // Let's keep it simple for function count: remove if exists.

        admins[account] = false;
        emit AdminRoleRevoked(account);
    }

     /**
     * @dev Checks if an address has admin privileges.
     * @param account The address to check.
     * @return True if the account is an admin, false otherwise.
     */
    function hasAdminRole(address account) external view returns (bool) {
        return admins[account];
    }


    /**
     * @dev Admin function to set the critical karma threshold.
     * @param threshold The new critical karma threshold.
     */
    function setCriticalKarmaThreshold(int96 threshold) external onlyAdmin {
        criticalKarmaThreshold = threshold;
    }

    /**
     * @dev Admin function to set the base early withdrawal penalty rate.
     * @param penaltyBps The new penalty rate in basis points (0-10000).
     */
    function setEarlyWithdrawPenaltyBps(uint256 penaltyBps) external onlyAdmin {
        require(penaltyBps <= 10000, "DPV: Penalty BPS invalid");
        earlyWithdrawPenaltyBps = penaltyBps;
    }

    /**
     * @dev Admin function to set the karma accrual rate per second.
     *      Defined as karma units gained per 1e18 tokens staked per second.
     * @param ratePerSecond The new karma rate per second (scaled by 1e18).
     */
    function setKarmaRatePerSecond(uint256 ratePerSecond) external onlyAdmin {
        karmaRatePerSecond = ratePerSecond;
    }

     /**
     * @dev Admin function to set the amount of karma lost when a penalty is applied.
     * @param karmaLoss The new karma loss amount.
     */
    function setPenaltyKarmaLoss(int96 karmaLoss) external onlyAdmin {
        require(karmaLoss >= 0, "DPV: Karma loss must be non-negative");
        penaltyKarmaLoss = karmaLoss;
    }

    /**
     * @dev Admin function to set parameters for the proposal system.
     *      Note: Uses staked amount for thresholds and voting weight.
     * @param thresholdStakeAmount Minimum staked amount to propose.
     * @param votingDuration Voting period duration in seconds.
     * @param timelock Timelock delay after success before execution in seconds.
     * @param quorumPercentBps Quorum percentage of total staked supply in basis points (0-10000).
     */
    function setProposalConfig(uint256 thresholdStakeAmount, uint256 votingDuration, uint256 timelock, uint256 quorumPercentBps) external onlyAdmin {
        require(quorumPercentBps <= 10000, "DPV: Quorum percent invalid");
        proposalThresholdStakeAmount = thresholdStakeAmount;
        votingPeriodDuration = votingDuration;
        timelockDelay = timelock;
        quorumPercent = quorumPercentBps;
    }


    /**
     * @dev Admin function to pause staking deposits.
     */
    function pauseStaking() external onlyAdmin {
        require(!paused, "DPV: Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Admin function to unpause staking deposits.
     */
    function unpauseStaking() external onlyAdmin {
        require(paused, "DPV: Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Utility & Information Functions (2) ---

    /**
     * @dev Gets the remaining time until a successful proposal can be executed.
     * @param proposalId The ID of the proposal.
     * @return The remaining time in seconds, or 0 if not Succeeded or already executable.
     */
    function getTimeUntilExecution(uint256 proposalId) external view returns (uint256) {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Check state dynamically
        if (getProposalState(proposalId) == ProposalState.Succeeded && !proposal.executed) {
            if (block.timestamp < proposal.executionTime) {
                return proposal.executionTime - uint48(block.timestamp);
            }
        }
        return 0; // Not in a state waiting for execution or already past timelock
    }

    /**
     * @dev Returns the contract version string.
     * @return The version string.
     */
    function getVersion() external pure returns (string memory) {
        return "DPV-v1.0";
    }

    // --- REVISED GOVERNANCE FUNCTIONS (Using Staked Balance for Voting) ---

    // Need to replace the old governance function implementations with these revised ones.
    // Adding them here as replacements.

    /**
     * @dev Allows a user with sufficient staked balance to propose an action.
     * @param targetContract The address of the contract to call.
     * @param callData The encoded function call data.
     * @param description A brief description of the proposal.
     * @return The ID of the created proposal.
     */
    function proposeAction_revised(address targetContract, bytes memory callData, string memory description) external returns (uint256) {
        require(stakedBalances[msg.sender] >= proposalThresholdStakeAmount, "DPV: Insufficient staked balance to propose");
        require(targetContract.isContract(), "DPV: Target must be a contract");

        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals.push(); // Add new proposal to the array
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.targetContract = targetContract;
        newProposal.callData = callData;
        newProposal.description = description;
        newProposal.creationTime = uint48(block.timestamp);
        newProposal.votingDeadline = uint48(block.timestamp + votingPeriodDuration);

        newProposal.state = ProposalState.Active; // Starts in Active state

        emit ProposalCreated(proposalId, msg.sender, description, newProposal.votingDeadline);

        return proposalId;
    }

     /**
     * @dev Allows a user with staked balance to vote on an active proposal.
     *      Vote weight is proportional to staked balance.
     * @param proposalId The ID of the proposal.
     * @param support True for 'for' vote, False for 'against' vote.
     */
    function voteOnProposal_revised(uint256 proposalId, bool support) external {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        require(proposal.state == ProposalState.Active, "DPV: Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "DPV: Voting period has ended");
        uint256 voterStake = stakedBalances[msg.sender];
        require(voterStake > 0, "DPV: Voter must have staked balance to vote");

        require(!proposal.hasVoted[msg.sender], "DPV: Already voted on this proposal");

        // Staked balance-weighted vote
        if (support) {
            proposal.forVotesStake += voterStake;
        } else {
            proposal.againstVotesStake += voterStake;
        }

        proposal.hasVoted[msg.sender] = true;

        // Use 0 for voteWeight in Voted event as it's staked balance, not karma
        emit Voted(proposalId, msg.sender, support, 0); // Log the vote, stake weight implicitly used

        // No state transition here, happens on execution attempt
    }

     /**
     * @dev Allows anyone to trigger the execution of a successful and time-locked proposal.
     *      Uses staked balance for vote weight and quorum.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal_revised(uint256 proposalId) external {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Check if voting period is over and transition state if needed (using staked balances)
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
             uint256 totalVotesCast = proposal.forVotesStake + proposal.againstVotesStake;
             uint256 currentTotalStaked = totalStakedSupply; // Use current total stake as proxy for quorum denominator

             // If total staked supply is zero, no quorum is possible unless 0% quorum is set.
             // Avoid division by zero if quorumPercent > 0 and currentTotalStaked is 0.
             bool quorumMet;
             if (quorumPercent == 0) {
                 quorumMet = true; // 0% quorum always met
             } else if (currentTotalStaked == 0) {
                 quorumMet = false; // Cannot meet non-zero quorum if total stake is zero
             } else {
                quorumMet = (totalVotesCast * 10000) / currentTotalStaked >= quorumPercent;
             }


             bool majorityMet = proposal.forVotesStake > proposal.againstVotesStake;

             if (quorumMet && majorityMet) {
                proposal.state = ProposalState.Succeeded;
                proposal.executionTime = uint48(block.timestamp + timelockDelay);
                emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.Succeeded);
             } else {
                proposal.state = ProposalState.Defeated;
                emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.Defeated);
                return; // Proposal defeated, stop here
             }
        }

        // Now check for execution eligibility (must be Succeeded and timelock passed)
        require(proposal.state == ProposalState.Succeeded, "DPV: Proposal must be in Succeeded state");
        require(block.timestamp >= proposal.executionTime, "DPV: Timelock not passed yet");
        require(!proposal.executed, "DPV: Proposal already executed");

        // Execute the proposal call
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);

        proposal.executed = true;
        proposal.state = ProposalState.Executed; // Final state

        emit ProposalExecuted(proposalId, success, result);
    }

    // Let's replace the original governance functions with the _revised versions
    // Renaming _revised functions to their original names.

    // The function count remains the same (6 governance functions), but their internal logic changes.
    // The function summary needs updating to reflect staked balance voting.

    // Replacing:
    // proposeAction -> proposeAction_revised (renamed)
    // voteOnProposal -> voteOnProposal_revised (renamed)
    // executeProposal -> executeProposal_revised (renamed)
    // getProposalState - Update internal logic to use staked votes
    // getProposalDetails - Update return values to include stake votes
    // getQuorumNeeded - Description still applies, uses total staked supply

    // Let's make these changes directly in the main code block.
    // (In a real coding scenario, you'd do this before writing the final code).
    // For this exercise, I will *manually integrate* the revised logic into the original function names.

    // --- Final Function Count Check ---
    // Staking: stake, withdraw, claimKarmaRewards, getUserStakedAmount, getTotalStaked, sweepExtraTokens (6)
    // Karma: getUserKarma, calculatePendingKarma, getKarmaBoostedPenaltyReduction, penalizeUserKarmaAndStake, rewardUserKarma (5)
    // Governance: proposeAction, voteOnProposal, executeProposal, getProposalState, getProposalDetails, getQuorumNeeded (6)
    // Admin/Config: addAdminRole, removeAdminRole, hasAdminRole, setCriticalKarmaThreshold, setEarlyWithdrawPenaltyBps, setKarmaRatePerSecond, setPenaltyKarmaLoss, setProposalConfig, pauseStaking, unpauseStaking (10) - Wait, counted 9 before? Let's recount set functions. Yes, 7 set functions + add/remove/has admin + pause/unpause = 12? No, 7 set + 3 admin role + 2 pause = 12. Let's re-list: setCriticalKarmaThreshold, setEarlyWithdrawPenaltyBps, setKarmaRatePerSecond, setPenaltyKarmaLoss, setProposalConfig (5 set) + addAdminRole, removeAdminRole, hasAdminRole (3 admin role) + pauseStaking, unpauseStaking (2 pause) = 10 Admin/Config functions.
    // Utility: getTimeUntilExecution, getVersion (2)

    // Total: 6 + 5 + 6 + 10 + 2 = 29 functions. This meets the requirement.

    // --- Final Review of Logic ---
    // - Karma accrual: based on staked amount and time since last interaction. Claimable via claimKarmaRewards.
    // - Karma benefit: influences penalty reduction during withdrawal.
    // - Karma penalty: applied by admin, or automatically on early withdrawal below critical threshold.
    // - Governance proposal: requires minimum *staked amount*. Vote weight is *staked amount*. Quorum is % of *total staked supply*. Execution is timelocked.
    // - Admin roles: basic mapping based.
    // - Pausing: affects staking.
    // - Withdrawal penalty: based on karma, applied to withdrawal amount, deducted amount stays in contract.

    // The logic seems internally consistent for this concept. The karma system and its dynamic application to penalties and *separate* staking/voting mechanics are the key unique aspects. The governance is basic but functional for demonstrating the concept.
}
```

Let's regenerate the code block with the finalized logic, incorporating the revised governance using staked balance for voting, and ensuring the function summary is updated.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Dynamic Protocol Vault (DPV)
 * @dev A smart contract implementing a staking vault with a dynamic Karma system,
 *      time-based karma accrual, variable penalties, role-based access, pausing,
 *      and an internal staked-balance-weighted proposal/voting mechanism.
 *      It features a novel "Karma" system influencing user benefits (penalty reduction)
 *      while using staked balance for governance voting power.
 *
 * Outline:
 * 1. Contract Overview
 * 2. State Variables
 * 3. Events
 * 4. Modifiers
 * 5. Core Staking & Asset Management Functions (6)
 * 6. Karma System & Effects Functions (5)
 * 7. Governance & Proposal Functions (6)
 * 8. Configuration & Admin Functions (10)
 * 9. Utility & Information Functions (2)
 *
 * Total Functions: 6 + 5 + 6 + 10 + 2 = 29 functions.
 *
 * Function Summary:
 * - constructor: Initializes the contract with the vault asset token, deployer as admin, and initial parameters for karma, penalties, and governance.
 * - stake: Allows users to deposit and stake the vault asset, updating their last interaction time for karma accrual.
 * - withdraw: Allows users to withdraw their staked assets. Applies a penalty to the withdrawal amount if user karma is below the critical threshold, also reducing karma.
 * - claimKarmaRewards: Allows users to claim accrued karma based on their staked amount and time elapsed since the last interaction.
 * - getUserStakedAmount: Gets the amount of tokens staked by a user.
 * - getTotalStaked: Gets the total amount of tokens staked in the vault.
 * - sweepExtraTokens: Admin function to recover accidentally sent ERC20 tokens (excluding the vault asset) from the contract.
 * - getUserKarma: Gets a user's current karma score.
 * - calculatePendingKarma: Calculates the amount of karma a user is currently eligible to claim based on time and stake.
 * - getKarmaBoostedPenaltyReduction: Calculates the percentage reduction in the withdrawal penalty based on a user's karma score.
 * - penalizeUserKarmaAndStake: Admin function to reduce a user's karma and optionally reduce their staked balance for rule violations.
 * - rewardUserKarma: Admin function to increase a user's karma score.
 * - proposeAction: Allows users meeting the minimum staked balance threshold to propose an action (arbitrary contract call) for governance voting.
 * - voteOnProposal: Allows users with a staked balance to vote on an active proposal. The vote weight is proportional to their staked balance at the time of voting.
 * - executeProposal: Allows anyone to trigger the execution of a proposal that has passed its voting period, met quorum and majority requirements (based on staked vote weight), and cleared the timelock delay.
 * - getProposalState: Gets the current state of a specific proposal, dynamically checking if voting is over.
 * - getProposalDetails: Gets all relevant data for a specific proposal, including its dynamic state.
 * - getQuorumNeeded: Gets the configured required quorum percentage for proposal success. (Actual quorum calculation uses total staked supply).
 * - addAdminRole: Grants admin privileges to a specified address (only callable by current admins).
 * - removeAdminRole: Revokes admin privileges from a specified address (only callable by current admins).
 * - hasAdminRole: Checks if a given address currently holds admin privileges.
 * - setCriticalKarmaThreshold: Admin function to set the karma score threshold below which withdrawal penalties are applied or increased.
 * - setEarlyWithdrawPenaltyBps: Admin function to set the base percentage rate (in basis points) for the early withdrawal penalty.
 * - setKarmaRatePerSecond: Admin function to set the rate at which karma accrues per staked token unit per second.
 * - setPenaltyKarmaLoss: Admin function to set the amount of karma a user loses when a penalty is applied via penalizeUserKarmaAndStake.
 * - setProposalConfig: Admin function to configure the governance parameters: minimum staked balance to propose, voting period duration, execution timelock delay, and the required quorum percentage.
 * - pauseStaking: Admin function to temporarily halt new staking deposits into the vault.
 * - unpauseStaking: Admin function to resume staking deposits.
 * - getTimeUntilExecution: Calculates the remaining time in seconds before a Succeeded proposal becomes eligible for execution.
 * - getVersion: Returns the current version string of the smart contract.
 */
contract DynamicProtocolVault {
    using Address for address;

    // --- State Variables ---

    IERC20 public immutable vaultAsset;

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint48) public lastInteractionTime;
    uint256 public totalStakedSupply;

    // Karma System
    mapping(address => int96) public userKarma;
    int96 public constant MIN_KARMA = -5000;
    int96 public constant MAX_KARMA = 10000;
    uint256 public karmaRatePerSecond; // Karma units per 1e18 tokens per second (scaled by 1e18 internally)
    int96 public criticalKarmaThreshold;
    uint256 public earlyWithdrawPenaltyBps; // Basis points (0-10000)
    int96 public penaltyKarmaLoss;

    // Access Control
    mapping(address => bool) public admins;

    // Pausing
    bool public paused = false;

    // Governance (Staked-Balance-Weighted)
    struct Proposal {
        uint256 id;
        address proposer;
        address targetContract;
        bytes callData;
        string description;
        uint48 creationTime;
        uint48 votingDeadline;
        uint48 executionTime;
        uint256 forVotesStake; // Total staked balance voting FOR
        uint256 againstVotesStake; // Total staked balance voting AGAINST
        bool executed;
        mapping(address => bool) hasVoted; // Simple flag if address has voted
        ProposalState state;
    }

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    Proposal[] public proposals;
    uint256 public proposalCount;

    uint256 public proposalThresholdStakeAmount; // Minimum staked balance required to propose
    uint256 public votingPeriodDuration;
    uint256 public timelockDelay;
    uint256 public quorumPercent; // Percentage of total staked supply (0-10000)

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event Withdrawn(address indexed user, uint256 amount, uint256 penaltyApplied, uint256 newTotalStaked);
    event KarmaClaimed(address indexed user, int96 amount, int96 newKarma);
    event KarmaUpdated(address indexed user, int96 oldKarma, int96 newKarma, string reason);
    event PenaltyApplied(address indexed user, int96 karmaLost, uint256 stakeReduced);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint48 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool decision, uint256 voteWeightStake); // Log staked weight
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event AdminRoleGranted(address indexed account);
    event AdminRoleRevoked(address indexed account);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(admins[msg.sender], "DPV: Caller is not an admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DPV: Contract is paused");
        _;
    }

    // --- Constructor ---

    constructor(address _vaultAsset, uint256 _karmaRatePerSecond, int96 _criticalKarmaThreshold, uint256 _earlyWithdrawPenaltyBps, int96 _penaltyKarmaLoss, uint256 _proposalThresholdStakeAmount, uint256 _votingPeriodDuration, uint256 _timelockDelay, uint256 _quorumPercent) {
        vaultAsset = IERC20(_vaultAsset);
        admins[msg.sender] = true;
        emit AdminRoleGranted(msg.sender);

        karmaRatePerSecond = _karmaRatePerSecond;
        criticalKarmaThreshold = _criticalKarmaThreshold;
        earlyWithdrawPenaltyBps = _earlyWithdrawPenaltyBps;
        penaltyKarmaLoss = _penaltyKarmaLoss;

        proposalThresholdStakeAmount = _proposalThresholdStakeAmount;
        votingPeriodDuration = _votingPeriodDuration;
        timelockDelay = _timelockDelay;
        quorumPercent = _quorumPercent;

        require(_quorumPercent <= 10000, "DPV: Quorum percent invalid");
        require(_earlyWithdrawPenaltyBps <= 10000, "DPV: Penalty BPS invalid");
    }

    // --- Core Staking & Asset Management Functions (6) ---

    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "DPV: Amount must be greater than 0");
        uint256 currentStaked = stakedBalances[msg.sender];

        // Claim pending karma before staking again to update lastInteractionTime correctly
        claimKarmaRewards(msg.sender);

        vaultAsset.transferFrom(msg.sender, address(this), amount);

        stakedBalances[msg.sender] = currentStaked + amount;
        totalStakedSupply += amount;
        lastInteractionTime[msg.sender] = uint48(block.timestamp); // Update after potential karma claim

        emit Staked(msg.sender, amount, totalStakedSupply);
    }

    function withdraw(uint256 amount) external {
        uint256 userBalance = stakedBalances[msg.sender];
        require(amount > 0, "DPV: Amount must be greater than 0");
        require(amount <= userBalance, "DPV: Insufficient staked balance");

        // Claim pending karma before withdrawal
        claimKarmaRewards(msg.sender); // Ensures karma and lastInteractionTime are up-to-date

        uint256 withdrawalAmount = amount;
        uint256 penaltyAmount = 0;
        int96 currentUserKarma = userKarma[msg.sender];

        if (currentUserKarma < criticalKarmaThreshold) {
            uint256 basePenalty = (amount * earlyWithdrawPenaltyBps) / 10000;
            int96 penaltyReductionBps = getKarmaBoostedPenaltyReduction(currentUserKarma); // Reduction is 0 or positive BPS
            // Apply reduction: effective_penalty = base_penalty * (10000 - reduction_bps) / 10000
            uint256 effectivePenalty = (basePenalty * (10000 - uint256(int256(penaltyReductionBps)))) / 10000;

            penaltyAmount = effectivePenalty;
            withdrawalAmount = amount - penaltyAmount;

            // Reduce user karma as part of the penalty
             _updateUserKarma(msg.sender, -penaltyKarmaLoss, "Early withdrawal penalty");
        }

        require(withdrawalAmount <= amount, "DPV: Internal penalty calculation error"); // Should not happen

        stakedBalances[msg.sender] = userBalance - amount;
        totalStakedSupply -= amount;
        lastInteractionTime[msg.sender] = uint48(block.timestamp); // Update interaction time

        vaultAsset.transfer(msg.sender, withdrawalAmount);

        emit Withdrawn(msg.sender, amount, penaltyAmount, totalStakedSupply);
    }

    function claimKarmaRewards(address user) public {
        uint48 lastInteraction = lastInteractionTime[user];
        uint256 stakedAmount = stakedBalances[user];
        int96 currentKarma = userKarma[user];

        if (stakedAmount == 0 || lastInteraction == 0 || block.timestamp <= lastInteraction) {
            return;
        }

        uint256 timeElapsed = block.timestamp - lastInteraction;
        // Calculate karma units based on staked amount (scaled) * time * rate (scaled)
        // Assuming karmaRatePerSecond is already scaled such that (stakedAmount * time * rate) / 1e18 gives integer karma.
        // Let's assume rate is karma units per staked token unit per second (scaled by 1e18)
        // karmaEarned = (stakedAmount / (10**vaultAsset.decimals())) * timeElapsed * (karmaRatePerSecond / (1e18));
        // Simplified: karmaEarned = (stakedAmount * timeElapsed * karmaRatePerSecond) / (10**vaultAsset.decimals() * 1e18); - Still complicated.
        // Let's use the previous approach where karmaRatePerSecond is units/sec per 1e18 tokens
        uint256 karmaEarnedScaled = (stakedAmount * timeElapsed * karmaRatePerSecond) / 1e18;
        int96 karmaEarnedInt = int96(karmaEarnedScaled / 1e18); // Convert scaled result to integer karma units

        _updateUserKarma(user, karmaEarnedInt, "Claimed staking rewards");

        lastInteractionTime[user] = uint48(block.timestamp); // Update after calculation
         emit KarmaClaimed(user, karmaEarnedInt, userKarma[user]);
    }

    function getUserStakedAmount(address user) external view returns (uint256) {
        return stakedBalances[user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStakedSupply;
    }

    function sweepExtraTokens(address tokenAddress, uint256 amount) external onlyAdmin {
        require(tokenAddress != address(vaultAsset), "DPV: Cannot sweep the vault asset");
        IERC20 extraToken = IERC20(tokenAddress);
        extraToken.transfer(msg.sender, amount);
    }

    // --- Karma System & Effects Functions (5) ---

    function getUserKarma(address user) external view returns (int96) {
        return userKarma[user];
    }

    function calculatePendingKarma(address user) external view returns (int96) {
        uint48 lastInteraction = lastInteractionTime[user];
        uint256 stakedAmount = stakedBalances[user];

         if (stakedAmount == 0 || lastInteraction == 0 || block.timestamp <= lastInteraction) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInteraction;
        uint256 karmaEarnedScaled = (stakedAmount * timeElapsed * karmaRatePerSecond) / 1e18;
        return int96(karmaEarnedScaled / 1e18);
    }

    function getKarmaBoostedPenaltyReduction(int96 karma) public view returns (int96) {
         if (karma <= criticalKarmaThreshold) {
             return 0; // No reduction below or at threshold
         }

         // Reduction scales linearly from 0% at criticalThreshold + 1 to 100% at MAX_KARMA
         uint256 karmaAboveThreshold = uint256(int256(karma - criticalKarmaThreshold));
         uint256 maxKarmaAboveThreshold = uint256(int256(MAX_KARMA - criticalKarmaThreshold));

         if (maxKarmaAboveThreshold == 0) return 0; // Avoid division by zero

         // Calculate reduction percentage (0-10000)
         uint256 reductionBps = (karmaAboveThreshold * 10000) / maxKarmaAboveThreshold;

         // Cap reduction at 100% (10000 bps) just in case of edge cases near MAX_KARMA
         if (reductionBps > 10000) reductionBps = 10000;

         return int96(reductionBps);
    }

    function penalizeUserKarmaAndStake(address user, uint256 stakeReductionAmount) external onlyAdmin {
         require(user != address(0), "DPV: Invalid user address");

         // Reduce karma
        _updateUserKarma(user, -penaltyKarmaLoss, "Admin penalty");

        // Reduce stake if requested
        if (stakeReductionAmount > 0) {
            uint256 currentStaked = stakedBalances[user];
            require(stakeReductionAmount <= currentStaked, "DPV: Stake reduction exceeds user balance");

            stakedBalances[user] = currentStaked - stakeReductionAmount;
            totalStakedSupply -= stakeReductionAmount;
             emit PenaltyApplied(user, penaltyKarmaLoss, stakeReductionAmount);
        } else {
            emit PenaltyApplied(user, penaltyKarmaLoss, 0);
        }
    }

    function rewardUserKarma(address user, int96 amount) external onlyAdmin {
        require(user != address(0), "DPV: Invalid user address");
        require(amount > 0, "DPV: Amount must be positive");
        _updateUserKarma(user, amount, "Admin reward");
    }

    function _updateUserKarma(address user, int96 karmaDelta, string memory reason) internal {
        int96 currentKarma = userKarma[user];
        int96 newKarma = currentKarma + karmaDelta;

        newKarma = newKarma > MAX_KARMA ? MAX_KARMA : newKarma;
        newKarma = newKarma < MIN_KARMA ? MIN_KARMA : newKarma;

        if (newKarma != currentKarma) {
            userKarma[user] = newKarma;
            emit KarmaUpdated(user, currentKarma, newKarma, reason);
        }
    }

    // --- Governance & Proposal Functions (6) ---

    function proposeAction(address targetContract, bytes memory callData, string memory description) external returns (uint256) {
        require(stakedBalances[msg.sender] >= proposalThresholdStakeAmount, "DPV: Insufficient staked balance to propose");
        require(targetContract.isContract(), "DPV: Target must be a contract");

        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.targetContract = targetContract;
        newProposal.callData = callData;
        newProposal.description = description;
        newProposal.creationTime = uint48(block.timestamp);
        newProposal.votingDeadline = uint48(block.timestamp + votingPeriodDuration);
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, description, newProposal.votingDeadline);

        return proposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) external {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        require(proposal.state == ProposalState.Active, "DPV: Proposal is not active");
        require(block.timestamp <= proposal.votingDeadline, "DPV: Voting period has ended"); // Vote must be within period
        uint256 voterStake = stakedBalances[msg.sender];
        require(voterStake > 0, "DPV: Voter must have staked balance to vote");

        require(!proposal.hasVoted[msg.sender], "DPV: Already voted on this proposal");

        if (support) {
            proposal.forVotesStake += voterStake;
        } else {
            proposal.againstVotesStake += voterStake;
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voterStake);
    }

    function executeProposal(uint256 proposalId) external {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Check if voting period is over and transition state if needed
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
             uint256 totalVotesCast = proposal.forVotesStake + proposal.againstVotesStake;
             uint256 currentTotalStaked = totalStakedSupply;

             bool quorumMet;
             if (quorumPercent == 0) {
                 quorumMet = true;
             } else if (currentTotalStaked == 0) {
                 quorumMet = false;
             } else {
                // Quorum check: (total_staked_votes_cast * 10000) / total_staked_supply >= quorum_percent
                // Multiply by 10000 first to avoid losing precision, requires care with overflow for large numbers
                // totalVotesCast and currentTotalStaked can be large, but their ratio is what matters.
                // Let's assume totalVotesCast <= currentTotalStaked in most cases.
                // (a * b) / c = (a / c) * b
                // quorumMet = (totalVotesCast / currentTotalStaked) * 10000 >= quorumPercent <-- integer division issue
                // Use fixed point or check order:
                // Check if totalVotesCast * 10000 >= currentTotalStaked * quorumPercent
                quorumMet = totalVotesCast * 10000 >= currentTotalStaked * quorumPercent;
             }

             bool majorityMet = proposal.forVotesStake > proposal.againstVotesStake;

             if (quorumMet && majorityMet) {
                proposal.state = ProposalState.Succeeded;
                proposal.executionTime = uint48(block.timestamp + timelockDelay);
                emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.Succeeded);
             } else {
                proposal.state = ProposalState.Defeated;
                emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.Defeated);
                return;
             }
        }

        require(proposal.state == ProposalState.Succeeded, "DPV: Proposal must be in Succeeded state");
        require(block.timestamp >= proposal.executionTime, "DPV: Timelock not passed yet");
        require(!proposal.executed, "DPV: Proposal already executed");

        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId, success, result);
    }

    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
         require(proposalId < proposalCount, "DPV: Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];

         if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
             uint256 totalVotesCast = proposal.forVotesStake + proposal.againstVotesStake;
             uint256 currentTotalStaked = totalStakedSupply;

             bool quorumMet;
             if (quorumPercent == 0) {
                 quorumMet = true;
             } else if (currentTotalStaked == 0) {
                 quorumMet = false;
             } else {
                quorumMet = totalVotesCast * 10000 >= currentTotalStaked * quorumPercent;
             }

             bool majorityMet = proposal.forVotesStake > proposal.againstVotesStake;

             if (quorumMet && majorityMet) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Defeated;
             }
         }
         return proposal.state;
    }

    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        address targetContract,
        bytes memory callData,
        string memory description,
        uint48 creationTime,
        uint48 votingDeadline,
        uint48 executionTime,
        uint256 forVotesStake,
        uint256 againstVotesStake,
        bool executed,
        ProposalState state
    ) {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        return (
            proposal.id,
            proposal.proposer,
            proposal.targetContract,
            proposal.callData,
            proposal.description,
            proposal.creationTime,
            proposal.votingDeadline,
            proposal.executionTime,
            proposal.forVotesStake,
            proposal.againstVotesStake,
            proposal.executed,
            getProposalState(proposalId) // Call helper to get dynamic state
        );
    }

    function getQuorumNeeded() external view returns (uint256) {
        return quorumPercent;
    }

    // --- Configuration & Admin Functions (10) ---

    function addAdminRole(address account) external onlyAdmin {
        require(account != address(0), "DPV: Invalid address");
        require(!admins[account], "DPV: Account already has admin role");
        admins[account] = true;
        emit AdminRoleGranted(account);
    }

    function removeAdminRole(address account) external onlyAdmin {
         require(account != address(0), "DPV: Invalid address");
        require(admins[account], "DPV: Account does not have admin role");
        // Basic check: don't allow removing the only admin unless it's the caller removing themselves (risky)
        // A more robust system would count admins or require multi-sig.
        // We allow removing the caller here.
        admins[account] = false;
        emit AdminRoleRevoked(account);
    }

    function hasAdminRole(address account) external view returns (bool) {
        return admins[account];
    }

    function setCriticalKarmaThreshold(int96 threshold) external onlyAdmin {
        criticalKarmaThreshold = threshold;
    }

    function setEarlyWithdrawPenaltyBps(uint256 penaltyBps) external onlyAdmin {
        require(penaltyBps <= 10000, "DPV: Penalty BPS invalid");
        earlyWithdrawPenaltyBps = penaltyBps;
    }

    function setKarmaRatePerSecond(uint256 ratePerSecond) external onlyAdmin {
        karmaRatePerSecond = ratePerSecond;
    }

    function setPenaltyKarmaLoss(int96 karmaLoss) external onlyAdmin {
        require(karmaLoss >= 0, "DPV: Karma loss must be non-negative");
        penaltyKarmaLoss = karmaLoss;
    }

    function setProposalConfig(uint256 thresholdStakeAmount, uint256 votingDuration, uint256 timelock, uint256 quorumPercentBps) external onlyAdmin {
        require(quorumPercentBps <= 10000, "DPV: Quorum percent invalid");
        proposalThresholdStakeAmount = thresholdStakeAmount;
        votingPeriodDuration = votingDuration;
        timelockDelay = timelock;
        quorumPercent = quorumPercentBps;
    }

    function pauseStaking() external onlyAdmin {
        require(!paused, "DPV: Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    function unpauseStaking() external onlyAdmin {
        require(paused, "DPV: Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Utility & Information Functions (2) ---

    function getTimeUntilExecution(uint256 proposalId) external view returns (uint256) {
        require(proposalId < proposalCount, "DPV: Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Check state dynamically
        if (getProposalState(proposalId) == ProposalState.Succeeded && !proposal.executed) {
            if (block.timestamp < proposal.executionTime) {
                return proposal.executionTime - uint48(block.timestamp);
            }
        }
        return 0; // Not in a state waiting for execution or already past timelock
    }

    function getVersion() external pure returns (string memory) {
        return "DPV-v1.0";
    }
}
```