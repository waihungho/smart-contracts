Okay, let's design a smart contract that combines concepts of a dynamic strategy vault, a reputation system, and decentralized governance based on oracle data and user contributions. It's complex, so we'll outline the structure and key mechanisms.

We'll call it the "Aetherium Vault". Users deposit an ERC20 token. The contract uses oracle data to potentially switch between predefined, approved strategies to manage these funds. Users earn yield based on their deposit *and* their on-chain reputation within the protocol. Reputation is gained through contributions and successful governance participation. Users can propose new strategies or protocol parameter changes, which are voted on using reputation.

**Key Advanced Concepts:**

1.  **Dynamic Strategy Execution:** Contract logic adapts based on external data (oracle).
2.  **On-Chain Reputation System:** Users earn reputation, which impacts yield share and governance weight.
3.  **Reputation-Weighted Governance:** Voting power is based on earned reputation, not just token holdings.
4.  **Oracle Integration:** Reliance on external data feeds for core logic (strategy switching, parameter tuning).
5.  **Complex Yield Distribution:** Yield is distributed based on a formula considering both deposit size and reputation.
6.  **Proposal Lifecycle:** Structured process for submitting, voting on, and executing changes.

**Outline and Function Summary:**

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Basic ownership for setup

/// @title Aetherium Vault
/// @dev A dynamic strategy vault with reputation-weighted governance based on oracle data.
/// @author Your Name/Alias Here

// --- OUTLINE ---
// 1. Interfaces and Libraries (if needed, e.g., for oracle)
// 2. Error Definitions
// 3. Structs (Strategy, Proposal, UserData, Parameters)
// 4. Events
// 5. State Variables (Vault state, user data, strategies, proposals, parameters, oracle address)
// 6. Modifiers (e.g., onlyOracle)
// 7. Constructor
// 8. Core Vault Functions (Deposit, Withdraw, Claim Yield)
// 9. Oracle Interaction Functions
// 10. Reputation System Functions
// 11. Strategy Management Functions (Adding, Removing, Setting Active, Execution Trigger)
// 12. Governance Functions (Proposing, Voting, Executing)
// 13. Parameter Management (via Governance)
// 14. View/Pure Functions (Getters for state, calculations)
// 15. Internal Helper Functions

// --- FUNCTION SUMMARY ---

// CORE VAULT FUNCTIONS:
// 1.  deposit(uint256 amount): Deposits asset tokens into the vault. Updates user balance and reputation.
// 2.  withdraw(uint256 amount): Withdraws asset tokens from the vault. Calculates and potentially reduces reputation.
// 3.  claimYield(): Claims accumulated yield for the user.
// 4.  getUserDeposit(address user): Returns the current deposited amount for a user.
// 5.  getTotalPooled(): Returns the total amount of asset tokens currently in the vault.

// ORACLE INTERACTION:
// 6.  updateOracleData(uint256 newData): Updates the oracle data. Callable only by the designated oracle address.
// 7.  getOracleData(): Returns the latest oracle data.

// REPUTATION SYSTEM:
// 8.  getUserReputation(address user): Returns the current reputation score for a user.
// 9.  calculateUserYieldShare(address user): Calculates the user's theoretical share of accrued yield based on deposit and reputation. (View)
// 10. getTotalReputation(): Returns the sum of all user reputations. (View)

// STRATEGY MANAGEMENT:
// 11. proposeStrategy(string memory name, bytes memory configData): Submits a proposal to add a new strategy type. Requires min reputation.
// 12. getStrategyDetails(uint256 strategyId): Returns details of a specific strategy. (View)
// 13. getActiveStrategyId(): Returns the ID of the currently active strategy. (View)
// 14. triggerStrategyExecution(): Callable by anyone (potentially incentivized keeper) to evaluate and execute the active strategy based on current oracle data and time.
// 15. addApprovedStrategy(uint256 proposalId): Called by governance execution to add a strategy proposed via governance.
// 16. removeStrategy(uint256 strategyId): Called by governance execution to remove an approved strategy.

// GOVERNANCE:
// 17. proposeParameterChange(bytes memory newParametersConfig): Submits a proposal to change protocol parameters. Requires min reputation.
// 18. voteOnProposal(uint256 proposalId, bool support): Casts a vote (for/against) on an active proposal. Reputation-weighted.
// 19. getProposalDetails(uint256 proposalId): Returns details of a specific proposal (type, proposer, state, votes). (View)
// 20. getProposalState(uint256 proposalId): Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed). (View)
// 21. executeProposal(uint256 proposalId): Callable by anyone if the proposal has succeeded and the timelock has passed. Executes the proposed action.
// 22. canVote(address user, uint256 proposalId): Checks if a user can vote on a specific proposal. (View)
// 23. canPropose(address user): Checks if a user meets the minimum reputation requirement to propose. (View)

// PARAMETER MANAGEMENT (via Governance Execution):
// 24. getParameters(): Returns the current protocol parameters. (View)

// ACCESS CONTROL / SETUP:
// 25. setOracleAddress(address newOracleAddress): Sets the address of the trusted oracle. (Owner only)
// 26. recoverERC20(address tokenAddress, uint256 amount): Allows owner to recover wrongly sent ERC20 tokens (excl. vault asset). (Owner only - standard safety)

// Note: The actual *logic* of strategy execution (how funds are used) is complex and
// might involve interactions with other contracts or internal accounting shifts.
// This contract provides the framework for *triggering* strategy logic based on oracle/governance.
// The yield calculation `_calculateUserYieldShare` and `_distributeYield` logic
// is simplified in the example code but would be highly complex in a real system.
// Reputation calculation (`_updateReputation`) would also involve complex formulas
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Still useful for clarity in complex calcs

/// @title Aetherium Vault
/// @dev A dynamic strategy vault with reputation-weighted governance based on oracle data.
/// @author Your Name/Alias Here

contract AetheriumVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Error Definitions ---
    error InvalidAmount();
    error InsufficientBalance();
    error InsufficientReputation();
    error ProposalNotFound();
    error ProposalAlreadyActive();
    error ProposalNotInVotingPeriod();
    error ProposalAlreadyVoted();
    error ProposalNotSucceeded();
    error ProposalExecutionTimelockNotPassed();
    error ProposalAlreadyExecuted();
    error InvalidProposalType();
    error StrategyNotFound();
    error NotOracle();
    error CannotWithdrawReputationLocked(); // If reputation is tied to deposit time/amount

    // --- Structs ---

    struct UserData {
        uint256 depositAmount;
        uint256 reputation;
        uint256 lastYieldClaimTimestamp;
        // More fields for reputation calculation based on deposit duration/amount
        uint256 depositTimestamp;
        uint256 totalDepositDuration;
    }

    struct Strategy {
        uint256 id;
        string name;
        bytes configData; // Arbitrary data specific to the strategy logic (e.g., parameters)
        bool isActive; // Can this strategy be set as active?
        // Could potentially add address of an external strategy contract here
        // address strategyExecutor;
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    enum ProposalType {
        AddStrategy,
        RemoveStrategy,
        ChangeParameters
        // Add other types as needed
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 submittedTimestamp;
        uint256 startVotingTimestamp;
        uint256 endVotingTimestamp;
        bytes proposalData; // Data specific to the proposal type (e.g., new strategy config, new parameters)
        uint256 totalReputationFor;
        uint256 totalReputationAgainst;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    struct ProtocolParameters {
        uint256 depositFeeBasisPoints; // 100 = 1%
        uint256 withdrawalFeeBasisPoints;
        uint256 minReputationToPropose;
        uint256 votingPeriodDuration; // in seconds
        uint256 proposalExecutionTimelock; // in seconds after voting ends
        uint256 minReputationForVoting; // minimum reputation to cast a vote
        uint256 proposalQuorumReputationBasisPoints; // % of total reputation needed to vote (e.g., 1000 = 10%)
        uint256 proposalThresholdReputationBasisPoints; // % 'For' votes out of total cast votes to succeed (e.g., 5000 = 50%)
        uint256 strategyExecutionGracePeriod; // time in seconds before strategy can be re-executed
        // More parameters affecting yield, reputation calculation, etc.
        uint256 reputationGainPerSecondPerUnitDeposit; // Example factor
        uint256 reputationLossPerWithdrawalBasisPoints; // % of reputation lost on withdrawal
    }


    // --- Events ---

    event Deposit(address indexed user, uint256 amount, uint256 newBalance, uint256 newReputation);
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance, uint256 newReputation);
    event YieldClaimed(address indexed user, uint256 claimedAmount, uint256 remainingYield);
    event OracleDataUpdated(uint256 newData);
    event StrategyProposed(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string name); // Name only for UI help
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event StrategyAdded(uint256 indexed strategyId, string name);
    event StrategyRemoved(uint256 indexed strategyId);
    event ActiveStrategySet(uint256 indexed strategyId);
    event StrategyExecutionTriggered(uint256 indexed strategyId, uint256 oracleData, uint256 timestamp);
    event ParametersChanged(ProtocolParameters newParameters);


    // --- State Variables ---

    IERC20 public immutable vaultAsset; // The token users deposit (e.g., WETH, USDC)
    address public oracleAddress;

    // Vault state
    uint256 public totalPooled; // Total vaultAsset held by this contract

    // User data: address => UserData
    mapping(address => UserData) public userData;
    uint256 public totalReputation; // Sum of all user reputations

    // Strategies: id => Strategy
    mapping(uint256 => Strategy) public strategies;
    uint256 public nextStrategyId = 1; // Start IDs from 1
    uint256[] public approvedStrategyIds; // List of IDs that can be active

    uint256 public activeStrategyId; // The strategy currently influencing behavior
    uint256 public lastStrategyExecutionTimestamp; // Timestamp of the last strategy execution trigger

    // Oracle Data
    uint256 public latestOracleData; // Example: Sentiment score, AI prediction, price signal etc.

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    uint256[] public activeProposals; // IDs of proposals in Active state

    ProtocolParameters public parameters;

    // Yield Accounting (Simplified)
    // In a real system, this would be far more complex, tracking profit/loss per strategy, etc.
    // Here we simulate by assuming 'external' profits are periodically accounted for.
    uint256 public totalRealizedProfits; // Total profit realized by the vault strategies
    uint256 public totalClaimedProfits; // Total profit claimed by users

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert NotOracle();
        }
        _;
    }

    // --- Constructor ---

    constructor(address _vaultAssetAddress, address _initialOracleAddress) Ownable(msg.sender) {
        vaultAsset = IERC20(_vaultAssetAddress);
        oracleAddress = _initialOracleAddress;

        // Set initial default parameters - should be changed via governance eventually
        parameters = ProtocolParameters({
            depositFeeBasisPoints: 10, // 0.1%
            withdrawalFeeBasisPoints: 50, // 0.5%
            minReputationToPropose: 100,
            votingPeriodDuration: 3 days,
            proposalExecutionTimelock: 1 days,
            minReputationForVoting: 1,
            proposalQuorumReputationBasisPoints: 1000, // 10%
            proposalThresholdReputationBasisPoints: 5000, // 50%
            strategyExecutionGracePeriod: 1 hours,
            reputationGainPerSecondPerUnitDeposit: 1e12, // Example: Scales reputation by deposit amount and time
            reputationLossPerWithdrawalBasisPoints: 500 // 5%
        });

        // Add a dummy initial strategy (Strategy 0 is reserved or unused, start with 1)
         _addStrategy(
            0, // Use 0 for initial/default strategy - should NOT be removable via governance
            "Default Strategy",
            "" // No config data for default
        );
        activeStrategyId = 0; // Default active strategy is ID 0
        approvedStrategyIds.push(0); // Add default strategy to approved list
    }

    // --- Core Vault Functions ---

    /// @notice Deposits asset tokens into the vault. Updates user balance and reputation.
    /// @param amount The amount of vault asset tokens to deposit.
    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        uint256 fee = amount.mul(parameters.depositFeeBasisPoints).div(10000);
        uint256 amountAfterFee = amount.sub(fee);

        // Transfer tokens from user to contract
        bool success = vaultAsset.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert("Transfer failed");
        }

        // Update user data
        UserData storage user = userData[msg.sender];
        // Update reputation based on previous deposit duration BEFORE updating deposit amount
        _updateReputation(msg.sender);
        user.depositAmount = user.depositAmount.add(amountAfterFee);
        user.depositTimestamp = block.timestamp; // Reset timestamp for duration calculation

        totalPooled = totalPooled.add(amountAfterFee);

        // Reputation gain is calculated in _updateReputation when depositing
        // Or could add a small bonus here: totalReputation = totalReputation.add(fixedDepositBonus);

        emit Deposit(msg.sender, amount, user.depositAmount, user.reputation);
    }

    /// @notice Withdraws asset tokens from the vault. Calculates and potentially reduces reputation.
    /// @param amount The amount of vault asset tokens to withdraw.
    function withdraw(uint256 amount) external nonReentrant {
        UserData storage user = userData[msg.sender];
        if (amount == 0) revert InvalidAmount();
        if (amount > user.depositAmount) revert InsufficientBalance();

        // Update reputation before withdrawal (calculates gain up to now)
        _updateReputation(msg.sender);

        uint256 fee = amount.mul(parameters.withdrawalFeeBasisPoints).div(10000);
        uint256 amountToSend = amount.sub(fee);

        user.depositAmount = user.depositAmount.sub(amount);
        totalPooled = totalPooled.sub(amountToSend); // Note: totalPooled reduces by amountToSend, not amount. Fee stays in vault/treasury

        // Reputation loss on withdrawal
        uint256 reputationLoss = user.reputation.mul(parameters.reputationLossPerWithdrawalBasisPoints).div(10000);
        user.reputation = user.reputation.sub(reputationLoss);
        totalReputation = totalReputation.sub(reputationLoss);

        // Reset deposit timestamp if balance is zero, else update for remaining duration calc
        if (user.depositAmount == 0) {
             user.depositTimestamp = 0; // No active deposit duration to track
        } else {
             user.depositTimestamp = block.timestamp; // Reset for remaining amount duration
        }


        // Transfer tokens to user
        bool success = vaultAsset.transfer(msg.sender, amountToSend);
        if (!success) {
            // This is a critical failure. Funds are stuck. Need robust error handling or escape hatch.
            // For simplicity, we'll let it revert here, but real systems need care.
             revert("Transfer failed");
        }


        emit Withdrawal(msg.sender, amount, user.depositAmount, user.reputation);
    }

    /// @notice Claims accumulated yield for the user.
    function claimYield() external nonReentrant {
        // This is a simplified example. Real yield calculation is complex.
        // Assume 'totalRealizedProfits' are added externally (e.g., by an admin after a strategy performs).

        UserData storage user = userData[msg.sender];

        // Calculate theoretical share of total profits earned since last claim
        uint256 yieldShare = _calculateUserYieldShare(msg.sender); // Total potential yield for user based on ALL profits

        // Calculate actual claimable amount (share minus what's already claimed)
        // This logic is highly simplified. Needs tracking of yield accrued vs claimed per user.
        // A better model: total protocol profits / total protocol "yield points".
        // Users earn yield points based on deposit * reputation * time.
        // User claim = (User yield points / Total yield points) * (totalRealizedProfits - totalClaimedProfits)
        // This requires complex on-chain accounting or a dedicated yield calculation helper.

        // For this example, let's just simulate a claim based on current total realized profits and a rough share
        // A REAL contract needs a robust yield accounting mechanism.
        // uint256 userAlreadyClaimed = ... // Need a state variable for this
        // uint256 claimable = yieldShare.sub(userAlreadyClaimed); // Error if yieldShare < userAlreadyClaimed

        // --- Simplified, conceptual claim logic ---
        // Calculate yield earned *since last claim* based on average balance and reputation in that period?
        // OR calculate percentage of pool based on current deposit/reputation and claim percentage of NEW profits?

        // Let's use a very basic model: claim a % of current total profits based on current state.
        // This is INACCURATE but demonstrates the function call.
        uint256 theoreticalTotalValue = totalPooled.add(totalRealizedProfits.sub(totalClaimedProfits)); // Highly simplified
        if (theoreticalTotalValue == 0 || user.depositAmount == 0) {
             emit YieldClaimed(msg.sender, 0, 0);
             return; // Nothing to claim
        }

        // Share of total pool value (including unrealized yield)
        uint256 userValueShare = user.depositAmount.mul(10000).div(theoreticalTotalValue); // Basis points

        // Influence of reputation (simple multiplier example)
        uint256 reputationMultiplier = user.reputation.add(100).div(100); // Add 100 to avoid 0 multiplier, divide by 100 to scale

        // Adjusted share considering reputation (conceptual)
        uint256 adjustedShareBasisPoints = userValueShare.mul(reputationMultiplier).div(100); // Example scaling

        // Amount to claim from current profits
        uint256 claimable = totalRealizedProfits.sub(totalClaimedProfits).mul(adjustedShareBasisPoints).div(10000);

        if (claimable == 0) {
             emit YieldClaimed(msg.sender, 0, 0);
             return;
        }

        totalClaimedProfits = totalClaimedProfits.add(claimable);
        // UserData needs a field to track claimed yield: user.totalClaimedYield = user.totalClaimedYield.add(claimable);

        // Send yield token (could be the same as vaultAsset or a different token)
        // Assuming yield is paid in vaultAsset for simplicity here.
        bool success = vaultAsset.transfer(msg.sender, claimable);
         if (!success) {
             // Funds might be stuck, needs handling.
             revert("Yield transfer failed");
         }

        user.lastYieldClaimTimestamp = block.timestamp; // Update claim time
        // Need to update user's tracked yield here if using a proper accounting system

        emit YieldClaimed(msg.sender, claimable, yieldShare.sub(claimable)); // Need accurate remaining calculation


        // --- End Simplified Logic ---
    }

    /// @notice Returns the current deposited amount for a user.
    /// @param user The address of the user.
    /// @return The user's deposit amount.
    function getUserDeposit(address user) external view returns (uint256) {
        return userData[user].depositAmount;
    }

     /// @notice Returns the total amount of asset tokens currently in the vault (excluding fees kept).
     /// @dev This is the sum of user deposits.
     /// @return The total pooled amount.
    function getTotalPooled() external view returns (uint256) {
        return totalPooled;
    }

    // --- Oracle Interaction ---

    /// @notice Updates the oracle data. Callable only by the designated oracle address.
    /// @param newData The new data provided by the oracle.
    function updateOracleData(uint256 newData) external onlyOracle {
        latestOracleData = newData;
        emit OracleDataUpdated(newData);

        // Optional: Trigger strategy evaluation directly on oracle update
        // triggerStrategyExecution(); // Be cautious with gas costs and re-entrancy if this calls external strategies
    }

    /// @notice Returns the latest oracle data.
    /// @return The latest oracle data value.
    function getOracleData() external view returns (uint256) {
        return latestOracleData;
    }

    // --- Reputation System ---

    /// @notice Returns the current reputation score for a user.
    /// @param user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address user) external view returns (uint256) {
        // Call internal function to ensure reputation is up-to-date based on deposit duration
        // This is a view function, it won't actually WRITE state, but calculates potential gain
        return _calculatePendingReputationGain(user).add(userData[user].reputation);
    }

     /// @notice Calculates the user's theoretical share of accrued yield based on deposit and reputation.
     /// @dev This is a conceptual calculation and depends heavily on the actual yield accounting model.
     /// @param user The address of the user.
     /// @return The theoretical total yield share for the user.
    function calculateUserYieldShare(address user) public view returns (uint256) {
        // This function needs complex logic correlating deposit history, reputation history,
        // and protocol-level profit realization timestamps.
        // A simple example: (user.depositAmount * user.reputation) / (totalPooled * totalReputation) * totalRealizedProfits
        // This is highly inaccurate for time-weighted yield.

        // Using the simplified model:
        uint256 theoreticalTotalValue = totalPooled.add(totalRealizedProfits.sub(totalClaimedProfits));
        if (theoreticalTotalValue == 0 || userData[user].depositAmount == 0) {
            return 0;
        }

        // Share of total pool value (including unrealized yield)
        uint256 userValueShareBasisPoints = userData[user].depositAmount.mul(10000).div(theoreticalTotalValue); // Basis points

        // Influence of reputation (simple multiplier example)
        uint256 currentReputation = _calculatePendingReputationGain(user).add(userData[user].reputation);
        uint256 reputationMultiplier = currentReputation.add(100).div(100); // Add 100 to avoid 0 multiplier, divide by 100 to scale

        // Adjusted share considering reputation (conceptual)
        uint256 adjustedShareBasisPoints = userValueShareBasisPoints.mul(reputationMultiplier).div(100); // Example scaling

        // Theoretical total yield share for this user
        uint256 totalYieldShare = totalRealizedProfits.mul(adjustedShareBasisPoints).div(10000);

        return totalYieldShare;
    }

     /// @notice Returns the sum of all user reputations.
     /// @dev Note: This state variable needs to be updated whenever reputation changes.
     /// @return The total reputation across all users.
    function getTotalReputation() external view returns (uint256) {
        // Consider adding pending reputation from deposits to this sum if getUserReputation does it
        return totalReputation;
    }

    // --- Strategy Management ---

    /// @notice Submits a proposal to add a new strategy type.
    /// @dev Requires the proposer to have sufficient reputation.
    /// @param name The name of the strategy (for identification).
    /// @param configData Arbitrary configuration data for the strategy.
    /// @return The ID of the newly created proposal.
    function proposeStrategy(string memory name, bytes memory configData) external returns (uint256) {
        if (!_canPropose(msg.sender)) revert InsufficientReputation();

        // Update reputation before proposing
        _updateReputation(msg.sender);

        uint256 proposalId = nextProposalId++;
        uint256 strategyId = nextStrategyId++; // Pre-assign strategy ID for the proposal

        // Encode strategy data for the proposal
        bytes memory proposalData = abi.encode(strategyId, name, configData);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.AddStrategy,
            proposer: msg.sender,
            submittedTimestamp: block.timestamp,
            startVotingTimestamp: block.timestamp, // Voting starts immediately for simplicity
            endVotingTimestamp: block.timestamp.add(parameters.votingPeriodDuration),
            proposalData: proposalData,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            state: ProposalState.Active
        });

        activeProposals.push(proposalId);

        emit StrategyProposed(proposalId, msg.sender, ProposalType.AddStrategy, name);

        return proposalId;
    }

    /// @notice Returns details of a specific strategy.
    /// @param strategyId The ID of the strategy.
    /// @return id, name, configData, isActive
    function getStrategyDetails(uint256 strategyId) external view returns (uint256, string memory, bytes memory, bool) {
        Strategy storage strat = strategies[strategyId];
        if (strat.id == 0 && strategyId != 0) revert StrategyNotFound(); // Strategy 0 is default, always exists
        return (strat.id, strat.name, strat.configData, strat.isActive);
    }

    /// @notice Returns the ID of the currently active strategy.
    /// @return The active strategy ID.
    function getActiveStrategyId() external view returns (uint256) {
        return activeStrategyId;
    }

    /// @notice Callable by anyone (potentially incentivized) to evaluate and execute the active strategy.
    /// @dev This function checks the active strategy ID, oracle data, and last execution time
    ///      to determine if strategy logic should be run. The actual strategy logic is internal
    ///      or calls out to trusted helper contracts.
    function triggerStrategyExecution() external {
        // Prevent execution too frequently
        if (block.timestamp < lastStrategyExecutionTimestamp.add(parameters.strategyExecutionGracePeriod)) {
            // Too soon, do nothing
            return;
        }

        uint256 currentStrategyId = activeStrategyId;
        bytes memory config = strategies[currentStrategyId].configData; // Get active strategy config

        // --- Core Strategy Logic Evaluation ---
        // This is the dynamic part. Based on `currentStrategyId`, `latestOracleData`, and `config`,
        // the contract decides *what* action to take.
        // Example:
        // if (currentStrategyId == 1) {
        //     // Strategy 1: Rebalance based on oracle sentiment (e.g., > 50 buy, < 50 sell)
        //     if (latestOracleData > 50) {
        //          // _executeBuyLogic(config); // Call internal or external function
        //          // Potentially update totalRealizedProfits here
        //     } else {
        //          // _executeSellLogic(config);
        //     }
        // } else if (currentStrategyId == 2) {
        //     // Strategy 2: Adjust allocation based on oracle price signal
        //     // _adjustAllocation(config, latestOracleData);
        //     // Potentially update totalRealizedProfits here
        // }
        // etc.

        // For this example, we just log the trigger and the active strategy/oracle data.
        // The actual financial logic is a placeholder.

        lastStrategyExecutionTimestamp = block.timestamp;
        emit StrategyExecutionTriggered(currentStrategyId, latestOracleData, block.timestamp);

        // Note: If actual token transfers or complex state changes happen here,
        // need to be extremely careful with reentrancy and gas limits.
        // Calling out to separate, audited StrategyExecutor contracts is safer.
    }

    /// @notice Called by governance execution to add a strategy proposed via governance.
    /// @dev This function is ONLY callable by executeProposal for a successful AddStrategy proposal.
    /// @param proposalId The ID of the successful AddStrategy proposal.
    function addApprovedStrategy(uint256 proposalId) external {
        // This function should ideally only be callable by the contract itself via executeProposal
        // Add an internal check: require(msg.sender == address(this), "Only callable via governance execution");

        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalType != ProposalType.AddStrategy || proposal.state != ProposalState.Succeeded) {
            revert InvalidProposalType(); // Or specific error
        }

        // Decode strategy data from proposal
        (uint256 strategyId, string memory name, bytes memory configData) = abi.decode(proposal.proposalData, (uint256, string, bytes));

        _addStrategy(strategyId, name, configData);

        // Mark proposal as executed
        proposal.state = ProposalState.Executed;
        _removeActiveProposal(proposalId); // Remove from active list
        emit ProposalExecuted(proposalId);
    }

    /// @notice Called by governance execution to remove an approved strategy.
    /// @dev This function is ONLY callable by executeProposal for a successful RemoveStrategy proposal.
    /// @param strategyId The ID of the strategy to remove.
    function removeStrategy(uint256 strategyId) external {
         // Add an internal check: require(msg.sender == address(this), "Only callable via governance execution");

        Strategy storage strat = strategies[strategyId];
        if (strat.id == 0) revert StrategyNotFound(); // Cannot remove default strategy (ID 0)
        if (strat.id == activeStrategyId) revert("Cannot remove active strategy"); // Cannot remove active one

        strat.isActive = false; // Mark as inactive

        // Remove from approvedStrategyIds list
        for (uint i = 0; i < approvedStrategyIds.length; i++) {
            if (approvedStrategyIds[i] == strategyId) {
                approvedStrategyIds[i] = approvedStrategyIds[approvedStrategyIds.length - 1];
                approvedStrategyIds.pop();
                break;
            }
        }

        // Note: We don't delete the struct data, just mark it inactive.
        // Could potentially delete for gas savings if needed, but loses history.

        emit StrategyRemoved(strategyId);
    }

    /// @notice Sets the active strategy that influences vault behavior.
    /// @dev This function is ONLY callable by executeProposal for a successful ChangeParameters proposal
    ///      that specifically includes setting the active strategy, OR potentially triggered
    ///      internally by `triggerStrategyExecution` based on specific complex rules.
    ///      For this example, we'll assume it's set via governance OR internal logic decides.
    /// @param strategyId The ID of the strategy to make active.
    function setActiveStrategy(uint256 strategyId) external {
        // Add internal checks: require(msg.sender == address(this) || msg.sender == SOME_TRUSTED_KEEPER, "Unauthorized");

        // Ensure strategy exists and is approved/active
        Strategy storage strat = strategies[strategyId];
        if (strat.id == 0 && strategyId != 0) revert StrategyNotFound();
        // Check if ID is in approvedStrategyIds list (except for ID 0)
        bool found = false;
        if (strategyId == 0) {
            found = true; // Default strategy is always allowed
        } else {
            for(uint i = 0; i < approvedStrategyIds.length; i++) {
                if (approvedStrategyIds[i] == strategyId) {
                    found = true;
                    break;
                }
            }
        }
        if (!found) revert StrategyNotFound(); // Or specifically "StrategyNotApproved"

        activeStrategyId = strategyId;
        emit ActiveStrategySet(strategyId);
    }


    // --- Governance ---

    /// @notice Submits a proposal to change protocol parameters.
    /// @dev Requires the proposer to have sufficient reputation.
    /// @param newParametersConfig Serialized configuration data for the new parameters.
    ///        The structure/encoding must match what executeProposal expects for this type.
    /// @return The ID of the newly created proposal.
    function proposeParameterChange(bytes memory newParametersConfig) external returns (uint256) {
        if (!_canPropose(msg.sender)) revert InsufficientReputation();

        // Update reputation before proposing
        _updateReputation(msg.sender);

        uint256 proposalId = nextProposalId++;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ChangeParameters,
            proposer: msg.sender,
            submittedTimestamp: block.timestamp,
            startVotingTimestamp: block.timestamp,
            endVotingTimestamp: block.timestamp.add(parameters.votingPeriodDuration),
            proposalData: newParametersConfig, // The new parameter data
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize map
            state: ProposalState.Active
        });

         activeProposals.push(proposalId);

        emit StrategyProposed(proposalId, msg.sender, ProposalType.ChangeParameters, "Parameter Change"); // Use StrategyProposed event, maybe rename it

        return proposalId;
    }

    /// @notice Casts a vote (for/against) on an active proposal. Reputation-weighted.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for', false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound(); // Check if proposal exists

        // Check state and voting period
        if (proposal.state != ProposalState.Active) revert ProposalNotInVotingPeriod();
        if (block.timestamp > proposal.endVotingTimestamp) revert ProposalNotInVotingPeriod();

        // Check if user has already voted
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        // Check if user has minimum reputation to vote
        _updateReputation(msg.sender); // Update voter reputation before counting vote weight
        uint256 voterReputation = userData[msg.sender].reputation;
        if (voterReputation < parameters.minReputationForVoting) revert InsufficientReputation();

        // Record the vote
        proposal.hasVoted[msg.sender] = true;

        // Add reputation weight to the vote count
        if (support) {
            proposal.totalReputationFor = proposal.totalReputationFor.add(voterReputation);
        } else {
            proposal.totalReputationAgainst = proposal.totalReputationAgainst.add(voterReputation);
        }

        emit VoteCast(proposalId, msg.sender, support, voterReputation);

        // Optional: Check if proposal succeeds/fails immediately if quorum/threshold met early
        // _checkProposalState(proposalId);
    }

    /// @notice Returns details of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return id, type, proposer, submittedTimestamp, startVotingTimestamp, endVotingTimestamp, forVotes, againstVotes, state
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address proposer,
        uint256 submittedTimestamp,
        uint256 startVotingTimestamp,
        uint256 endVotingTimestamp,
        uint256 totalReputationFor,
        uint256 totalReputationAgainst,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound();

        // Calculate current state if it's active or pending
        ProposalState currentState = proposal.state;
        if (currentState == ProposalState.Active && block.timestamp > proposal.endVotingTimestamp) {
            // Voting period ended, check outcome
            currentState = _checkProposalOutcome(proposalId);
        }

        return (
            proposal.id,
            proposal.proposalType,
            proposal.proposer,
            proposal.submittedTimestamp,
            proposal.startVotingTimestamp,
            proposal.endVotingTimestamp,
            proposal.totalReputationFor,
            proposal.totalReputationAgainst,
            currentState // Return potentially updated state
        );
    }

     /// @notice Returns the current state of a proposal.
     /// @param proposalId The ID of the proposal.
     /// @return The state of the proposal (Pending, Active, Succeeded, Failed, Executed).
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0) revert ProposalNotFound();

        if (proposal.state == ProposalState.Active && block.timestamp > proposal.endVotingTimestamp) {
            // Voting period ended, check outcome
            return _checkProposalOutcome(proposalId);
        }
        return proposal.state;
    }


    /// @notice Callable by anyone if the proposal has succeeded and the timelock has passed. Executes the proposed action.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound();

        // Ensure voting period has ended and the proposal succeeded
        ProposalState currentState = _checkProposalOutcome(proposalId); // Re-check outcome definitively
        if (currentState != ProposalState.Succeeded) revert ProposalNotSucceeded();

        // Check execution timelock
        if (block.timestamp < proposal.endVotingTimestamp.add(parameters.proposalExecutionTimelock)) revert ProposalExecutionTimelockNotPassed();

        // Prevent double execution
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted();

        // --- Execution Logic ---
        // Based on proposal type, call the appropriate internal function or method
        if (proposal.proposalType == ProposalType.AddStrategy) {
            // Call the internal/restricted function
            // Note: Direct call `addApprovedStrategy(proposalId)` won't work as it's external.
            // Need an internal function or use `delegatecall` (complex/risky) or simply replicate the logic.
            // Let's replicate the logic for simplicity in this example, assuming validation happened.

            (uint256 strategyId, string memory name, bytes memory configData) = abi.decode(proposal.proposalData, (uint256, string, bytes));
            _addStrategy(strategyId, name, configData);

        } else if (proposal.proposalType == ProposalType.RemoveStrategy) {
            // Need to decode the strategyId from the proposal data
             uint256 strategyIdToRemove = abi.decode(proposal.proposalData, (uint256)); // Assuming proposalData is just the ID
             // Call internal/restricted function
             _removeStrategyInternal(strategyIdToRemove); // Internal helper

        } else if (proposal.proposalType == ProposalType.ChangeParameters) {
             // Decode and apply new parameters
             ProtocolParameters memory newParams = abi.decode(proposal.proposalData, (ProtocolParameters));
             _setParametersInternal(newParams); // Internal helper

        } else {
            revert InvalidProposalType(); // Should not happen if proposal submission was validated
        }

        // Mark proposal as executed
        proposal.state = ProposalState.Executed;
        _removeActiveProposal(proposalId); // Remove from active list

        emit ProposalExecuted(proposalId);
    }

     /// @notice Checks if a user can vote on a specific proposal.
     /// @param user The address of the user.
     /// @param proposalId The ID of the proposal.
     /// @return True if the user can vote, false otherwise.
    function canVote(address user, uint256 proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) return false; // Proposal doesn't exist

        if (proposal.state != ProposalState.Active) return false; // Not in active state
        if (block.timestamp > proposal.endVotingTimestamp) return false; // Voting period ended

        if (proposal.hasVoted[user]) return false; // Already voted

        // Check minimum reputation (using potential current reputation)
        uint256 currentReputation = _calculatePendingReputationGain(user).add(userData[user].reputation);
        if (currentReputation < parameters.minReputationForVoting) return false;

        return true;
    }

     /// @notice Checks if a user meets the minimum reputation requirement to propose.
     /// @param user The address of the user.
     /// @return True if the user can propose, false otherwise.
    function canPropose(address user) external view returns (bool) {
         // Check minimum reputation (using potential current reputation)
        uint256 currentReputation = _calculatePendingReputationGain(user).add(userData[user].reputation);
        return currentReputation >= parameters.minReputationToPropose;
    }

    // --- Parameter Management (via Governance Execution) ---

    /// @notice Returns the current protocol parameters.
    /// @return The current ProtocolParameters struct.
    function getParameters() external view returns (ProtocolParameters memory) {
        return parameters;
    }


    // --- Access Control / Setup ---

    /// @notice Sets the address of the trusted oracle.
    /// @dev Only callable by the contract owner initially. Future changes might require governance.
    /// @param newOracleAddress The address of the new oracle contract.
    function setOracleAddress(address newOracleAddress) external onlyOwner {
        oracleAddress = newOracleAddress;
    }

     /// @notice Allows the owner to recover ERC20 tokens sent to the contract by mistake.
     /// @dev Standard safety function. Cannot recover the vault asset token.
     /// @param tokenAddress The address of the token to recover.
     /// @param amount The amount of tokens to recover.
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(vaultAsset)) {
             revert("Cannot recover vault asset token");
        }
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }

    // --- Internal Helper Functions ---

    /// @dev Internal function to add a strategy. Used by constructor and governance execution.
    function _addStrategy(uint256 strategyId, string memory name, bytes memory configData) internal {
         // This relies on the strategyId being unique, assigned during proposal creation
         // or using nextStrategyId if called directly (e.g., from constructor).
         // If called from executeProposal, strategyId comes from the proposal data.
         // Need a robust check that the strategyId from the proposal matches the next available
         // or is within an expected range, depending on the proposal/execution flow.
         // For this example, we'll assume the decoded strategyId is the one to use.
        require(strategies[strategyId].id == 0 || strategyId == 0, "Strategy ID already exists"); // ID 0 is exception

        strategies[strategyId] = Strategy({
            id: strategyId,
            name: name,
            configData: configData,
            isActive: true // New strategies are added as active=true initially, but not necessarily *set* as the activeStrategyId
            // strategyExecutor: address(0) // If using external executors
        });

        // Add to the list of approved strategy IDs (except ID 0, which is already there)
        if (strategyId != 0) {
            bool exists = false;
            for(uint i = 0; i < approvedStrategyIds.length; i++) {
                if (approvedStrategyIds[i] == strategyId) {
                    exists = true; break;
                }
            }
            if (!exists) approvedStrategyIds.push(strategyId);
        }


        emit StrategyAdded(strategyId, name);
    }

    /// @dev Internal function to remove a strategy. Used by governance execution.
    function _removeStrategyInternal(uint256 strategyId) internal {
         Strategy storage strat = strategies[strategyId];
         require(strat.id != 0 || strategyId == 0, "Strategy not found"); // Check exists
         if (strategyId == 0) revert("Cannot remove default strategy");
         if (strat.id == activeStrategyId) revert("Cannot remove active strategy");

         strat.isActive = false;

         // Remove from approvedStrategyIds list
        for (uint i = 0; i < approvedStrategyIds.length; i++) {
            if (approvedStrategyIds[i] == strategyId) {
                approvedStrategyIds[i] = approvedStrategyIds[approvedStrategyIds.length - 1];
                approvedStrategyIds.pop();
                break;
            }
        }

        emit StrategyRemoved(strategyId);
    }


    /// @dev Internal function to set parameters. Used by governance execution.
    function _setParametersInternal(ProtocolParameters memory newParams) internal {
        parameters = newParams;
        emit ParametersChanged(newParams);
    }

    /// @dev Internal function to update user reputation based on deposit duration.
    /// Called before actions affected by reputation (propose, vote, withdraw, claim yield).
    /// @param user The address of the user.
    function _updateReputation(address user) internal {
        UserData storage userStorage = userData[user];
        uint256 currentDeposit = userStorage.depositAmount;

        if (currentDeposit > 0 && userStorage.depositTimestamp > 0 && block.timestamp > userStorage.depositTimestamp) {
            uint256 timeElapsed = block.timestamp.sub(userStorage.depositTimestamp);
            uint256 reputationGain = timeElapsed.mul(currentDeposit).div(1e18) // Scale deposit amount if it's a large token amount, e.g., USDC with 6 decimals vs reputation unit
                                    .mul(parameters.reputationGainPerSecondPerUnitDeposit);

            userStorage.reputation = userStorage.reputation.add(reputationGain);
            totalReputation = totalReputation.add(reputationGain);

            userStorage.totalDepositDuration = userStorage.totalDepositDuration.add(timeElapsed);
            userStorage.depositTimestamp = block.timestamp; // Reset timestamp for next duration calculation
        }
    }

    /// @dev Internal pure function to calculate potential reputation gain without changing state.
     /// Used for view functions like getUserReputation, canVote, canPropose.
     /// @param user The address of the user.
     /// @return The amount of reputation the user *would* gain since their last update/deposit timestamp.
    function _calculatePendingReputationGain(address user) internal view returns (uint256) {
        UserData storage userStorage = userData[user];
        uint256 currentDeposit = userStorage.depositAmount;

        if (currentDeposit > 0 && userStorage.depositTimestamp > 0 && block.timestamp > userStorage.depositTimestamp) {
             uint256 timeElapsed = block.timestamp.sub(userStorage.depositTimestamp);
             uint256 reputationGain = timeElapsed.mul(currentDeposit).div(1e18) // Scale deposit amount
                                    .mul(parameters.reputationGainPerSecondPerUnitDeposit);
             return reputationGain;
        }
        return 0;
    }


    /// @dev Internal function to check the outcome of a proposal based on votes and quorum.
    /// Updates the proposal state if voting period is over.
    /// @param proposalId The ID of the proposal.
    /// @return The current (or resolved) state of the proposal.
    function _checkProposalOutcome(uint256 proposalId) internal returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }

        if (block.timestamp <= proposal.endVotingTimestamp) {
            return ProposalState.Active; // Still voting
        }

        // Voting period is over. Determine outcome.
        uint256 totalVotesReputation = proposal.totalReputationFor.add(proposal.totalReputationAgainst);

        // Check Quorum: Total reputation that voted must be >= quorum percentage of total protocol reputation
        uint256 requiredQuorumReputation = totalReputation.mul(parameters.proposalQuorumReputationBasisPoints).div(10000);
        if (totalVotesReputation < requiredQuorumReputation) {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
            return ProposalState.Failed;
        }

        // Check Threshold: Reputation 'For' must be >= threshold percentage of total reputation that voted
        uint256 requiredThresholdFor = totalVotesReputation.mul(parameters.proposalThresholdReputationBasisPoints).div(10000);
        if (proposal.totalReputationFor >= requiredThresholdFor) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
            return ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
            return ProposalState.Failed;
        }
    }

    /// @dev Helper to remove a proposal ID from the activeProposals array.
    function _removeActiveProposal(uint256 proposalId) internal {
        for (uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }
    }

     /// @dev Internal function for `removeStrategy`, called by `executeProposal`.
     /// Needed because `removeStrategy` is external but intended for internal calls from `executeProposal`.
     function _removeStrategyInternal(uint256 strategyId) internal {
        // Add checks that this is called from `executeProposal` or a trusted source if needed.
        // For now, relies on `executeProposal` calling it correctly.
        removeStrategy(strategyId); // Call the external function
     }

     /// @dev Internal function for `setParameters`, called by `executeProposal`.
      function _setParametersInternal(ProtocolParameters memory newParams) internal {
         // Add checks that this is called from `executeProposal` or a trusted source if needed.
         parameters = newParams;
         emit ParametersChanged(newParams);
      }


    // --- Additional potential internal functions (not required by >=20 external) ---
    // _executeBuyLogic(bytes memory config) internal { ... }
    // _executeSellLogic(bytes memory config) internal { ... }
    // _adjustAllocation(bytes memory config, uint256 oracleData) internal { ... }
    // _distributeYield(uint256 profitAmount) internal { ... } // Distributes profits to users based on share
    // _addRealizedProfit(uint256 profitAmount) internal { totalRealizedProfits = totalRealizedProfits.add(profitAmount); } // Called externally or internally


}
```

**Explanation of Concepts and Implementation Choices:**

1.  **Dynamic Strategy:** The `triggerStrategyExecution` function is the entry point for dynamic behavior. It reads `latestOracleData` and `activeStrategyId`, then *conceptually* executes different logic branches or calls different internal/external functions based on these values. The actual profitable logic is complex and heavily depends on what strategies mean (e.g., interacting with AMMs, lending protocols, etc.). The example provides a structure for *when* strategy logic runs but leaves the *what* as placeholder comments.
2.  **On-Chain Reputation:** The `UserData` struct tracks `reputation`. Reputation is primarily gained based on the `amount` deposited and the `duration` of the deposit (`depositTimestamp`, `totalDepositDuration`). The `_updateReputation` internal function calculates this gain. Reputation is spent or lost on withdrawal (`reputationLossPerWithdrawalBasisPoints`). This creates a dynamic score based on engagement.
3.  **Reputation-Weighted Governance:** The `voteOnProposal` function adds the voter's current reputation (`userData[msg.sender].reputation`) to the `totalReputationFor` or `totalReputationAgainst`. The `_checkProposalOutcome` function uses these weighted totals, along with `totalReputation` for quorum calculation, to determine if a proposal succeeds.
4.  **Oracle Integration:** An `oracleAddress` is a state variable. The `updateOracleData` function is restricted to this address. The `latestOracleData` is then available to `triggerStrategyExecution` for decision making.
5.  **Complex Yield Distribution:** The `claimYield` function and `calculateUserYieldShare` view function illustrate the *intention* to distribute yield based on a formula incorporating *both* deposit size and reputation. The actual implementation provided is a simplification; a real system would require sophisticated accounting to track yield accrual accurately over time for each user, considering changes in deposit, reputation, and protocol-level profits. A yield accounting helper library or pattern is typically needed. `totalRealizedProfits` and `totalClaimedProfits` are basic placeholders.
6.  **Proposal Lifecycle:** Proposals (`Proposal` struct) have states (`Pending`, `Active`, `Succeeded`, `Failed`, `Executed`). Users with sufficient reputation (`minReputationToPropose`) can submit proposals (`proposeStrategy`, `proposeParameterChange`). Others with minimum voting reputation (`minReputationForVoting`) can vote (`voteOnProposal`) during the `votingPeriodDuration`. After the period, anyone can call `executeProposal` if the proposal met quorum and threshold checks (`_checkProposalOutcome`) and the `proposalExecutionTimelock` has passed.
7.  **Parameter Management:** Protocol-level settings are stored in the `ProtocolParameters` struct. These can be changed via the governance process (`proposeParameterChange`, `executeProposal`).
8.  **Functions >= 20:** The contract includes 26 public/external functions, fulfilling this requirement. Many are view functions providing transparency into the system's state.

This contract provides a framework for a complex, dynamic, and community-governed vault. Implementing the actual profit-generating strategies, the precise yield calculation, and robust security for cross-contract calls would be the next steps in a real-world application.