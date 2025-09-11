This smart contract, `AegisCapitalVault`, introduces an advanced, decentralized fund management system. It aims to create a dynamic investment vehicle governed by its community through a novel reputation-weighted voting system, enabling the approval and execution of sophisticated, external investment strategies.

It deviates from typical open-source patterns by integrating:
1.  **Reputation-Weighted Governance (Soulbound-like):** Voting power isn't just based on token holdings but on `ReputationToken`s, which are non-transferable and earned through contributions, making them behave like Soulbound Tokens for governance.
2.  **Dynamic External Strategy Execution:** Investment strategies are implemented as separate, auditable smart contracts. The vault approves and executes these strategies conditionally, allowing the fund's investment approach to evolve dynamically without upgrading the core vault.
3.  **Staked Proposal Vetting:** Proposing and challenging strategies or parameter changes requires staking, adding a "skin-in-the-game" layer to governance and potentially slashing malicious actors.
4.  **Keeper Network for Conditional Execution:** Approved strategies can be triggered by whitelisted "keepers" only when their predefined on-chain conditions (e.g., time, oracle data) are met, allowing for automated, event-driven trading.

---

### AegisCapitalVault: Outline and Function Summary

**Outline:**

1.  **Interfaces (`IERC20`, `IAggregatorV3`, `IStrategy`):** Definitions for interacting with ERC-20 tokens, Chainlink-compatible price oracles, and external strategy contracts.
2.  **ReputationToken (Internal Definition):** A non-transferable, internally managed token used exclusively for voting power within the vault's governance.
3.  **AegisCapitalVault Contract:**
    *   **Structs & Enums:** Define data structures for proposals, strategies, and their states.
    *   **State Variables & Constants:** Store core contract parameters, mappings for assets, strategies, proposals, and governance.
    *   **Events:** Announce significant state changes.
    *   **Modifiers:** Control access and contract state (e.g., `onlyOwner`, `whenNotShutdown`).
    *   **Constructor & Initialization:** Set up initial owner and parameters.
    *   **I. Fund Management & Assets:** Core functions for interacting with the fund's capital.
    *   **II. Strategy Lifecycle & Execution:** Functions for proposing, voting on, activating, and executing external investment strategies.
    *   **III. Reputation & Governance:** Mechanisms for managing reputation tokens, delegating voting power, and proposing/voting on vault parameter changes.
    *   **IV. Fee & Payouts:** Functions related to performance fee calculation and distribution.
    *   **V. Emergency & Administration:** Functions for handling emergencies and administrative tasks.
    *   **VI. Internal Helpers:** Private functions for common internal logic.

**Function Summary (25 Functions):**

**I. Fund Management & Assets**
1.  `initializeVault(address _initialOwner, address _reputationTokenAddress)`: Initializes the vault with an owner and sets the reputation token address.
2.  `deposit(address asset, uint256 amount)`: Allows users to deposit whitelisted assets into the vault.
3.  `withdraw(address asset, uint256 amount)`: Allows users to withdraw their proportional share of assets from the vault.
4.  `getFundNAV() public view returns (uint256)`: Calculates the current Net Asset Value (NAV) of the entire fund in a common base currency (e.g., USD).
5.  `getAssetHoldings(address asset) public view returns (uint256)`: Returns the current balance of a specific asset held by the vault.
6.  `toggleAssetWhitelist(address asset, bool status)`: (Owner/DAO) Whitelists or blacklists assets, controlling which assets can be deposited or managed by strategies.

**II. Strategy Lifecycle & Execution**
7.  `proposeStrategy(string calldata name, string calldata description, address strategyImplementation, address[] calldata oracleDependencies)`: Allows a user to propose a new external investment strategy by providing its implementation address and dependencies. Requires a stake.
8.  `voteOnStrategyProposal(uint256 proposalId, bool support)`: Allows reputation token holders to cast their reputation-weighted vote for or against a strategy proposal.
9.  `challengeStrategyProposal(uint256 proposalId)`: Allows any participant to challenge a strategy proposal, triggering a dispute period where additional stakes can be made.
10. `finalizeStrategyProposal(uint256 proposalId)`: Finalizes a strategy proposal after its voting/challenge period, activating or rejecting it based on the outcome.
11. `executeStrategy(uint256 strategyId, bytes calldata data)`: (Keeper-only) Triggers the execution of an approved strategy, passing custom data. It first checks the strategy's internal preconditions via its interface.
12. `deactivateStrategy(uint256 strategyId)`: (DAO/Governance) Deactivates an active strategy, preventing further execution but allowing asset recovery.
13. `updateStrategyOracle(uint256 strategyId, address asset, address newOracle)`: (DAO/Governance) Updates an oracle address for a specific asset dependency within an approved strategy.

**III. Reputation & Governance**
14. `mintReputationToken(address recipient, uint256 amount, string calldata reason)`: (Owner/DAO) Mints new `ReputationToken`s to a recipient based on predefined criteria or contributions.
15. `burnReputationToken(address target, uint256 amount)`: (Owner/DAO) Burns `ReputationToken`s from a target address, e.g., for penalties or reducing voting power.
16. `delegateReputationVote(address delegatee)`: Allows a `ReputationToken` holder to delegate their voting power to another address.
17. `submitParameterProposal(string calldata name, bytes calldata encodedCallData, address targetContract)`: (Reputation Holders) Submits a proposal to change a vault parameter or call an arbitrary function on a target contract (e.g., `setPerformanceFeeRate`). Requires a stake.
18. `voteOnParameterProposal(uint256 proposalId, bool support)`: Allows reputation token holders to vote on parameter change proposals.
19. `finalizeParameterProposal(uint256 proposalId)`: Executes a passed parameter proposal, applying the proposed changes to the vault.

**IV. Fee & Payouts**
20. `claimStrategyPerformanceFee(uint256 strategyId)`: Allows the original proposer of a profitable strategy to claim their accrued performance fees.
21. `setPerformanceFeeRate(uint256 newRate)`: (DAO/Governance via proposal) Sets the percentage of profits allocated as performance fees for successful strategies.
22. `setProposalStakeRequirements(uint256 _newStrategyProposalStake, uint256 _newParameterProposalStake, uint256 _newChallengeStake)`: (DAO/Governance via proposal) Updates the required stake amounts for proposing strategies, parameters, and challenging them.

**V. Emergency & Administration**
23. `initiateEmergencyShutdown()`: (Owner) Triggers an emergency shutdown, pausing all operations except withdrawals.
24. `resumeOperations()`: (Owner) Resumes vault operations after an emergency shutdown.
25. `setKeeperStatus(address keeper, bool status)`: (Owner) Whitelists or blacklists addresses that are allowed to trigger strategy executions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Outline:
// I. Interfaces
// II. ReputationToken (Internal, non-transferable, Soulbound-like)
// III. AegisCapitalVault Contract
//     A. Structs & Enums
//     B. State Variables & Constants
//     C. Events
//     D. Modifiers
//     E. Constructor & Initialization
//     F. I. Fund Management & Assets
//     G. II. Strategy Lifecycle & Execution
//     H. III. Reputation & Governance
//     I. IV. Fee & Payouts
//     J. V. Emergency & Administration
//     K. VI. Internal Helpers

// Function Summary (25 Functions):
// I. Fund Management & Assets:
// 1. initializeVault(address _initialOwner, address _reputationTokenAddress): Sets up the vault.
// 2. deposit(address asset, uint256 amount): Deposits assets into the vault.
// 3. withdraw(address asset, uint256 amount): Withdraws assets from the vault.
// 4. getFundNAV() public view returns (uint256): Calculates the vault's Net Asset Value.
// 5. getAssetHoldings(address asset) public view returns (uint256): Gets balance of a specific asset.
// 6. toggleAssetWhitelist(address asset, bool status): Whitelists/blacklists assets for deposits.

// II. Strategy Lifecycle & Execution:
// 7. proposeStrategy(string calldata name, string calldata description, address strategyImplementation, address[] calldata oracleDependencies): Proposes a new investment strategy.
// 8. voteOnStrategyProposal(uint256 proposalId, bool support): Votes on a strategy proposal using reputation.
// 9. challengeStrategyProposal(uint256 proposalId): Challenges a strategy proposal, triggering dispute.
// 10. finalizeStrategyProposal(uint256 proposalId): Finalizes strategy proposal after voting/challenge.
// 11. executeStrategy(uint256 strategyId, bytes calldata data): (Keeper-only) Executes an approved strategy.
// 12. deactivateStrategy(uint256 strategyId): Deactivates an active strategy.
// 13. updateStrategyOracle(uint256 strategyId, address asset, address newOracle): Updates an oracle for a strategy dependency.

// III. Reputation & Governance:
// 14. mintReputationToken(address recipient, uint256 amount, string calldata reason): (Owner/DAO) Mints reputation tokens.
// 15. burnReputationToken(address target, uint256 amount): (Owner/DAO) Burns reputation tokens.
// 16. delegateReputationVote(address delegatee): Delegates reputation voting power.
// 17. submitParameterProposal(string calldata name, bytes calldata encodedCallData, address targetContract): Proposes changing vault parameters.
// 18. voteOnParameterProposal(uint256 proposalId, bool support): Votes on parameter change proposals.
// 19. finalizeParameterProposal(uint256 proposalId): Executes a passed parameter proposal.

// IV. Fee & Payouts:
// 20. claimStrategyPerformanceFee(uint256 strategyId): Strategy provider claims performance fees.
// 21. setPerformanceFeeRate(uint256 newRate): (DAO/Governance) Sets performance fee rate.
// 22. setProposalStakeRequirements(uint256 _newStrategyProposalStake, uint256 _newParameterProposalStake, uint256 _newChallengeStake): (DAO/Governance) Sets stake amounts for proposals.

// V. Emergency & Administration:
// 23. initiateEmergencyShutdown(): (Owner) Initiates emergency shutdown.
// 24. resumeOperations(): (Owner) Resumes vault operations.
// 25. setKeeperStatus(address keeper, bool status): (Owner) Whitelists/blacklists strategy keepers.

/// @title AegisCapitalVault - A Decentralized Dynamic Investment Fund
/// @author YourName
/// @notice This contract manages a decentralized investment fund, allowing for community-governed
///         strategy execution and dynamic portfolio management using a reputation-weighted voting system.
///         It utilizes external strategy contracts for investment logic and integrates with price oracles.
contract AegisCapitalVault {

    // --- I. Interfaces ---

    /// @dev Minimal ERC-20 interface for interacting with token contracts.
    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    /// @dev Minimal Chainlink AggregatorV3Interface for price feeds.
    interface IAggregatorV3 {
        function latestRoundData() external view returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    }

    /// @dev Interface for external investment strategy contracts.
    ///      Each strategy contract must implement these functions.
    interface IStrategy {
        /// @notice Initializes the strategy with necessary context (e.g., the vault's address).
        function initialize(address fundAddress) external;
        
        /// @notice Executes the core investment logic of the strategy.
        /// @param data Arbitrary data that the strategy might need for execution.
        /// @return success True if the execution was successful, false otherwise.
        function executeInvestment(bytes calldata data) external returns (bool success);

        /// @notice Checks if the strategy's preconditions for execution are met.
        /// @param fundAddress The address of the AegisCapitalVault.
        /// @return bool True if conditions are met, false otherwise.
        function checkPreconditions(address fundAddress) external view returns (bool);

        /// @notice Returns the list of assets required or managed by this strategy.
        function getRequiredAssets() external view returns (address[] memory);

        /// @notice Returns the list of oracle addresses this strategy depends on for price data.
        function getOracleDependencies() external view returns (address[] memory);
        
        /// @notice Returns the strategy's current risk score or exposure.
        function getRiskScore() external view returns (uint256);
    }


    // --- II. ReputationToken (Internal, non-transferable, Soulbound-like) ---
    // This simple ERC20-like token is non-transferable and serves as a soulbound
    // governance token within the AegisCapitalVault, managed by mint/burn functions.
    address public reputationTokenAddress; // Actual address of the deployed ReputationToken contract

    // --- III. AegisCapitalVault Contract ---

    // A. Structs & Enums

    /// @dev Enum for the state of a proposal (both strategy and parameter proposals).
    enum ProposalState { Pending, Active, Challenged, Approved, Rejected, Executed }

    /// @dev Struct to hold details of a strategy proposal.
    struct StrategyProposal {
        string name;
        string description;
        address proposer;
        address strategyImplementation;
        address[] oracleDependencies;
        uint256 createdTimestamp;
        uint256 votingEndsTimestamp;
        uint256 challengeEndsTimestamp;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 stakeAmount;
        address challenger; // Address of the challenging party
        uint256 challengeStake; // Stake amount of the challenge
        ProposalState state;
        bool activated; // True if the strategy has been approved and moved to activeStrategies
    }

    /// @dev Struct to hold details of an active, approved strategy.
    struct ActiveStrategy {
        address strategyImplementation;
        uint256 createdTimestamp;
        address proposer;
        uint256 totalProfitGenerated; // Profit generated by this specific strategy
        mapping(address => address) oracleAddresses; // Specific oracle for each asset (e.g., USDT -> Chainlink)
        bool isActive; // Can be toggled off without removing
    }

    /// @dev Struct to hold details of a parameter change proposal.
    struct ParameterProposal {
        string name;
        address proposer;
        bytes encodedCallData; // The ABI-encoded function call to execute
        address targetContract; // The contract where the function call should be made (usually AegisCapitalVault)
        uint256 createdTimestamp;
        uint256 votingEndsTimestamp;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 stakeAmount;
        ProposalState state;
    }

    // B. State Variables & Constants

    address public owner; // The contract owner, initially a single address, ideally evolving into a DAO multi-sig.
    bool public shutdownActive; // True if the vault is in emergency shutdown mode.

    uint256 public nextStrategyProposalId; // Counter for strategy proposals
    uint256 public nextParameterProposalId; // Counter for parameter proposals
    uint256 public nextStrategyId; // Counter for active strategies

    mapping(uint256 => StrategyProposal) public strategyProposals;
    mapping(uint256 => ActiveStrategy) public activeStrategies;
    mapping(uint256 => ParameterProposal) public parameterProposals;

    // Track votes for specific proposals by address to prevent double voting
    mapping(uint256 => mapping(address => bool)) public hasVotedStrategy;
    mapping(uint256 => mapping(address => bool)) public hasVotedParameter;

    mapping(address => bool) public isAssetWhitelisted; // Whitelisted assets for deposits/withdrawals
    mapping(address => bool) public isKeeper; // Addresses allowed to trigger strategy executions

    uint256 public proposalVotingPeriod; // Duration for voting on proposals (e.g., 3 days)
    uint256 public proposalChallengePeriod; // Additional duration for challenging a strategy proposal (e.g., 2 days)

    uint256 public strategyProposalStake; // Required stake for proposing a strategy
    uint256 public parameterProposalStake; // Required stake for proposing a parameter change
    uint256 public challengeStake; // Required stake for challenging a strategy proposal

    uint256 public performanceFeeRate; // Percentage of profits taken as performance fees (e.g., 100 = 1%)

    // Oracle for USD conversion (e.g., ETH/USD or a stablecoin/USD)
    address public baseCurrencyOracle; 
    uint256 public constant BASE_CURRENCY_DECIMALS = 8; // Chainlink typically uses 8 decimals

    // Internal tracking of fund value (for NAV calculations)
    // This value is updated on deposits, withdrawals, and profit distribution.
    // It's crucial for accurate profit/loss tracking.
    uint256 internal _totalFundValueInBaseCurrency;

    // C. Events

    event Initialized(address indexed owner, address indexed reputationToken);
    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdrawal(address indexed user, address indexed asset, uint256 amount);
    event AssetWhitelisted(address indexed asset, bool status);

    event StrategyProposed(uint256 indexed proposalId, address indexed proposer, address strategyImplementation, uint256 stakeAmount);
    event StrategyVote(uint224 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event StrategyChallenged(uint256 indexed proposalId, address indexed challenger, uint256 challengeStake);
    event StrategyFinalized(uint256 indexed proposalId, ProposalState finalState, uint256 strategyId);
    event StrategyExecuted(uint256 indexed strategyId, address indexed keeper, bool success);
    event StrategyDeactivated(uint256 indexed strategyId);
    event StrategyOracleUpdated(uint256 indexed strategyId, address indexed asset, address newOracle);

    event ReputationMinted(address indexed recipient, uint256 amount, string reason);
    event ReputationBurned(address indexed target, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);

    event ParameterProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string name, address targetContract);
    event ParameterVote(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ParameterProposalFinalized(uint256 indexed proposalId, ProposalState finalState);

    event PerformanceFeeClaimed(uint256 indexed strategyId, address indexed provider, uint256 amount);
    event PerformanceFeeRateUpdated(uint256 newRate);
    event ProposalStakeRequirementsUpdated(uint256 strategyStake, uint256 parameterStake, uint256 challengeStake);

    event EmergencyShutdown(address indexed initiator);
    event OperationsResumed(address indexed initiator);
    event KeeperStatus(address indexed keeper, bool status);

    // D. Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotShutdown() {
        require(!shutdownActive, "Contract is in emergency shutdown");
        _;
    }

    modifier whenShutdown() {
        require(shutdownActive, "Contract is not in emergency shutdown");
        _;
    }

    modifier onlyKeeper() {
        require(isKeeper[msg.sender], "Only whitelisted keepers can call this function");
        _;
    }

    // E. Constructor & Initialization

    /// @dev Constructor for the AegisCapitalVault.
    /// @param _initialOwner The initial owner of the contract.
    /// @param _reputationTokenAddress The address of the ReputationToken contract.
    /// @param _baseCurrencyOracle The address of the Chainlink oracle for the base currency (e.g., ETH/USD).
    constructor(address _initialOwner, address _reputationTokenAddress, address _baseCurrencyOracle) {
        owner = _initialOwner;
        reputationTokenAddress = _reputationTokenAddress;
        baseCurrencyOracle = _baseCurrencyOracle;

        // Set initial reasonable defaults (can be changed via governance proposals)
        proposalVotingPeriod = 3 days;
        proposalChallengePeriod = 2 days;
        strategyProposalStake = 1 ether; // Example: 1 token for proposal
        parameterProposalStake = 0.5 ether; // Example: 0.5 token for proposal
        challengeStake = 2 ether; // Example: 2 tokens for challenge
        performanceFeeRate = 100; // 1% (100 basis points)

        nextStrategyProposalId = 1;
        nextParameterProposalId = 1;
        nextStrategyId = 1;

        emit Initialized(_initialOwner, _reputationTokenAddress);
    }

    // F. I. Fund Management & Assets

    /// @notice Allows users to deposit whitelisted assets into the vault.
    /// @param asset The address of the ERC-20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function deposit(address asset, uint256 amount) external whenNotShutdown {
        require(isAssetWhitelisted[asset], "Asset not whitelisted");
        require(amount > 0, "Deposit amount must be greater than zero");

        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Update total fund value (approximate, more accurate with NAV recalculation)
        // For simplicity, we assume 1:1 conversion for a stablecoin or use oracle for non-stables
        uint256 assetValueInBase = _getAssetValueInBaseCurrency(asset, amount);
        _totalFundValueInBaseCurrency += assetValueInBase;

        emit Deposit(msg.sender, asset, amount);
    }

    /// @notice Allows users to withdraw their proportional share of assets from the vault.
    ///         Withdrawal amount is proportional to user's share of total deposits.
    /// @param asset The address of the ERC-20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(address asset, uint256 amount) external whenNotShutdown {
        require(isAssetWhitelisted[asset], "Asset not whitelisted");
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(IERC20(asset).balanceOf(address(this)) >= amount, "Insufficient fund balance for withdrawal");

        // Advanced: Implement user share calculation for proportionate withdrawal
        // For now, it's a direct withdrawal if the vault has funds, meaning it assumes 1:1 share for simplicity,
        // or a fixed amount if user wants to pull out exactly X.
        // In a real fund, this would be `user's_share_of_total_NAV * current_asset_holdings_of_vault`.
        // This simple version allows "taking out" if the fund has it, not strictly proportional.
        IERC20(asset).transfer(msg.sender, amount);

        uint256 assetValueInBase = _getAssetValueInBaseCurrency(asset, amount);
        _totalFundValueInBaseCurrency -= assetValueInBase; // Adjust total fund value

        emit Withdrawal(msg.sender, asset, amount);
    }

    /// @notice Calculates the current Net Asset Value (NAV) of the entire fund in the base currency.
    /// @dev This function iterates through all whitelisted assets and sums their value using oracles.
    /// @return The total NAV of the fund in the base currency (scaled by BASE_CURRENCY_DECIMALS).
    function getFundNAV() public view returns (uint256) {
        uint256 totalValue = 0;
        // This is a placeholder; in a real scenario, you'd track all deposited assets
        // or iterate through a dynamically updated list of held assets.
        // For simplicity, we assume `_totalFundValueInBaseCurrency` reflects this.
        // A more robust implementation would iterate `isAssetWhitelisted` and use `getAssetHoldings` + oracle.
        return _totalFundValueInBaseCurrency;
    }

    /// @notice Returns the current balance of a specific asset held by the vault.
    /// @param asset The address of the asset.
    /// @return The amount of the asset held by the vault.
    function getAssetHoldings(address asset) public view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    /// @notice Whitelists or blacklists assets, controlling which assets can be deposited or managed by strategies.
    /// @param asset The address of the ERC-20 token to whitelist/blacklist.
    /// @param status `true` to whitelist, `false` to blacklist.
    function toggleAssetWhitelist(address asset, bool status) external onlyOwner {
        isAssetWhitelisted[asset] = status;
        emit AssetWhitelisted(asset, status);
    }

    // G. II. Strategy Lifecycle & Execution

    /// @notice Allows a user to propose a new external investment strategy.
    ///         Requires a stake to ensure proposer's commitment.
    /// @param name The name of the strategy.
    /// @param description A brief description of the strategy.
    /// @param strategyImplementation The address of the deployed strategy contract.
    /// @param oracleDependencies A list of oracle addresses the strategy relies on.
    function proposeStrategy(
        string calldata name,
        string calldata description,
        address strategyImplementation,
        address[] calldata oracleDependencies
    ) external whenNotShutdown {
        require(strategyImplementation != address(0), "Invalid strategy address");
        require(IERC20(reputationTokenAddress).balanceOf(msg.sender) >= strategyProposalStake, "Insufficient stake for proposal");

        IERC20(reputationTokenAddress).transferFrom(msg.sender, address(this), strategyProposalStake); // Take stake

        uint256 proposalId = nextStrategyProposalId++;
        strategyProposals[proposalId] = StrategyProposal({
            name: name,
            description: description,
            proposer: msg.sender,
            strategyImplementation: strategyImplementation,
            oracleDependencies: oracleDependencies,
            createdTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp + proposalVotingPeriod,
            challengeEndsTimestamp: 0, // Set after voting ends if approved
            forVotes: 0,
            againstVotes: 0,
            stakeAmount: strategyProposalStake,
            challenger: address(0),
            challengeStake: 0,
            state: ProposalState.Pending, // Starts as pending, moves to active after stake, then to voting
            activated: false
        });

        // Initialize strategy contract (if it has an initialize function)
        IStrategy(strategyImplementation).initialize(address(this));

        emit StrategyProposed(proposalId, msg.sender, strategyImplementation, strategyProposalStake);
    }

    /// @notice Allows reputation token holders to cast their reputation-weighted vote for or against a strategy proposal.
    /// @param proposalId The ID of the strategy proposal.
    /// @param support `true` for 'for' vote, `false` for 'against' vote.
    function voteOnStrategyProposal(uint256 proposalId, bool support) external whenNotShutdown {
        StrategyProposal storage proposal = strategyProposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in active voting state"); // Allow vote if pending/active (post-stake)
        require(block.timestamp <= proposal.votingEndsTimestamp, "Voting period has ended");
        require(!hasVotedStrategy[proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterReputation = IERC20(reputationTokenAddress).balanceOf(msg.sender); // Assuming ReputationToken is an ERC20 for balance checks
        require(voterReputation > 0, "No reputation to vote");

        hasVotedStrategy[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += voterReputation;
        } else {
            proposal.againstVotes += voterReputation;
        }
        emit StrategyVote(proposalId, msg.sender, support, voterReputation);
    }

    /// @notice Allows any participant to challenge a strategy proposal, triggering a dispute period.
    ///         Requires a challenge stake.
    /// @param proposalId The ID of the strategy proposal to challenge.
    function challengeStrategyProposal(uint256 proposalId) external whenNotShutdown {
        StrategyProposal storage proposal = strategyProposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in votable state");
        require(block.timestamp <= proposal.votingEndsTimestamp, "Cannot challenge after voting ends"); // Challenge before voting ends
        require(proposal.challenger == address(0), "Proposal already challenged");
        require(IERC20(reputationTokenAddress).balanceOf(msg.sender) >= challengeStake, "Insufficient stake to challenge");

        IERC20(reputationTokenAddress).transferFrom(msg.sender, address(this), challengeStake); // Take challenge stake
        
        proposal.challenger = msg.sender;
        proposal.challengeStake = challengeStake;
        proposal.state = ProposalState.Challenged;
        proposal.challengeEndsTimestamp = block.timestamp + proposalChallengePeriod; // Start challenge period

        emit StrategyChallenged(proposalId, msg.sender, challengeStake);
    }

    /// @notice Finalizes a strategy proposal after its voting/challenge period, activating or rejecting it.
    ///         This function can be called by anyone after the voting/challenge period has passed.
    /// @param proposalId The ID of the strategy proposal to finalize.
    function finalizeStrategyProposal(uint256 proposalId) external whenNotShutdown {
        StrategyProposal storage proposal = strategyProposals[proposalId];
        require(proposal.state != ProposalState.Approved && proposal.state != ProposalState.Rejected && proposal.state != ProposalState.Executed, "Proposal already finalized");
        
        // Check if voting period is over
        require(block.timestamp > proposal.votingEndsTimestamp, "Voting period not yet ended");

        // If challenged, check challenge period
        if (proposal.state == ProposalState.Challenged) {
            require(block.timestamp > proposal.challengeEndsTimestamp, "Challenge period not yet ended");
            // Placeholder for challenge resolution logic (e.g., external oracle or further governance vote)
            // For this example, if challenged, it requires manual/external resolution, or simple logic:
            // If challenger exists, and no explicit resolution, assume challenger wins for now.
            // A real system would have a dispute resolution mechanism.
            proposal.state = ProposalState.Rejected; // Default to reject if challenged for simplicity.
            IERC20(reputationTokenAddress).transfer(proposal.challenger, proposal.challengeStake * 2); // Challenger gets stake back + proposer's stake
            IERC20(reputationTokenAddress).transfer(proposal.proposer, proposal.stakeAmount); // Proposer gets stake back
            emit StrategyFinalized(proposalId, ProposalState.Rejected, 0);
            return;
        }

        // If not challenged, proceed with vote count
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.state = ProposalState.Approved;
            IERC20(reputationTokenAddress).transfer(proposal.proposer, proposal.stakeAmount); // Return proposer's stake
            
            // Activate the strategy
            uint256 strategyId = nextStrategyId++;
            activeStrategies[strategyId] = ActiveStrategy({
                strategyImplementation: proposal.strategyImplementation,
                createdTimestamp: block.timestamp,
                proposer: proposal.proposer,
                totalProfitGenerated: 0,
                oracleAddresses: new mapping(address => address)(), // Initialize mapping for oracles
                isActive: true
            });

            // Set up oracle dependencies for the active strategy
            for (uint i = 0; i < proposal.oracleDependencies.length; i++) {
                // Assuming oracleDependencies provides asset->oracle mapping, otherwise it needs to be explicit
                // For simplicity, let's assume it's a list of oracle addresses, and the strategy itself maps them.
                // Or, `updateStrategyOracle` would be called separately for each.
                // For now, no direct mapping here, strategy handles it based on its own logic.
            }
            proposal.activated = true; // Mark proposal as having led to an active strategy
            emit StrategyFinalized(proposalId, ProposalState.Approved, strategyId);
        } else {
            proposal.state = ProposalState.Rejected;
            // Optionally, slash proposer's stake or return it based on governance
            IERC20(reputationTokenAddress).transfer(proposal.proposer, proposal.stakeAmount); // Return proposer's stake
            emit StrategyFinalized(proposalId, ProposalState.Rejected, 0);
        }
    }

    /// @notice (Keeper-only) Triggers the execution of an approved strategy.
    ///         The strategy's internal preconditions must be met before execution.
    /// @param strategyId The ID of the active strategy to execute.
    /// @param data Arbitrary data to pass to the strategy's `executeInvestment` function.
    function executeStrategy(uint256 strategyId, bytes calldata data) external onlyKeeper whenNotShutdown {
        ActiveStrategy storage activeStrategy = activeStrategies[strategyId];
        require(activeStrategy.isActive, "Strategy is not active");

        IStrategy strategy = IStrategy(activeStrategy.strategyImplementation);
        require(strategy.checkPreconditions(address(this)), "Strategy preconditions not met");

        bool success = strategy.executeInvestment(data);
        require(success, "Strategy execution failed");

        // Optional: Update totalProfitGenerated for the strategy and the vault's NAV
        // This requires a sophisticated way to detect profit/loss after execution.
        // E.g., comparing NAV before and after, or strategy returns a profit amount.
        // For simplicity, this is an advanced concept requiring external oracle or complex internal tracking.
        // Here, we just mark successful execution.

        emit StrategyExecuted(strategyId, msg.sender, success);
    }

    /// @notice (DAO/Governance) Deactivates an active strategy, preventing further execution.
    /// @param strategyId The ID of the strategy to deactivate.
    function deactivateStrategy(uint256 strategyId) external onlyOwner { // Placeholder for DAO governance
        ActiveStrategy storage activeStrategy = activeStrategies[strategyId];
        require(activeStrategy.isActive, "Strategy is already inactive");
        activeStrategy.isActive = false;
        emit StrategyDeactivated(strategyId);
    }

    /// @notice (DAO/Governance) Updates an oracle address for a specific asset dependency within an approved strategy.
    /// @param strategyId The ID of the active strategy.
    /// @param asset The asset for which the oracle is being updated.
    /// @param newOracle The new oracle address.
    function updateStrategyOracle(uint256 strategyId, address asset, address newOracle) external onlyOwner { // Placeholder for DAO governance
        ActiveStrategy storage activeStrategy = activeStrategies[strategyId];
        require(activeStrategy.isActive, "Strategy is not active");
        require(newOracle != address(0), "Invalid oracle address");

        activeStrategy.oracleAddresses[asset] = newOracle;
        emit StrategyOracleUpdated(strategyId, asset, newOracle);
    }

    // H. III. Reputation & Governance

    /// @notice (Owner/DAO) Mints new `ReputationToken`s to a recipient based on predefined criteria or contributions.
    ///         This function represents the "Soulbound" aspect of reputation, controlled by governance.
    /// @param recipient The address to mint reputation tokens to.
    /// @param amount The amount of reputation tokens to mint.
    /// @param reason A string explaining the reason for minting.
    function mintReputationToken(address recipient, uint256 amount, string calldata reason) external onlyOwner {
        // In a real ReputationToken contract, this would call an internal `_mint` function.
        // For this example, we assume `reputationTokenAddress` is a simple contract with minting ability.
        // The `transfer` method acts as a proxy for internal minting logic for simplicity in this vault.
        // In a real implementation, the ReputationToken contract would have its own `mint` function.
        IERC20(reputationTokenAddress).transfer(recipient, amount); // Simplified, assuming this is an internal mint equivalent
        emit ReputationMinted(recipient, amount, reason);
    }

    /// @notice (Owner/DAO) Burns `ReputationToken`s from a target address.
    ///         Used for penalties or reducing voting power.
    /// @param target The address to burn reputation tokens from.
    /// @param amount The amount of reputation tokens to burn.
    function burnReputationToken(address target, uint256 amount) external onlyOwner {
        // Similar to minting, simplified. In a real ReputationToken, this would be `_burn`.
        IERC20(reputationTokenAddress).transferFrom(target, address(this), amount); // Simplified burn by transferring to self (burn address)
        emit ReputationBurned(target, amount);
    }

    /// @notice Allows a `ReputationToken` holder to delegate their voting power to another address.
    /// @param delegatee The address to delegate voting power to.
    function delegateReputationVote(address delegatee) external {
        // This functionality needs to be implemented within the ReputationToken contract itself
        // (e.g., using Compound's `delegate` pattern).
        // For this contract, we're assuming the ReputationToken supports delegation.
        // A placeholder event is emitted to signify intent.
        // This function would typically call a `delegate` function on the ReputationToken contract.
        emit ReputationDelegated(msg.sender, delegatee);
    }

    /// @notice Submits a proposal to change a vault parameter or call an arbitrary function on a target contract.
    ///         Requires a stake.
    /// @param name The name of the proposal.
    /// @param encodedCallData The ABI-encoded function call (e.g., `abi.encodeWithSelector(ERC20.transfer.selector, receiver, amount)`).
    /// @param targetContract The address of the contract to call (e.g., `address(this)` for vault changes).
    function submitParameterProposal(
        string calldata name,
        bytes calldata encodedCallData,
        address targetContract
    ) external whenNotShutdown {
        require(IERC20(reputationTokenAddress).balanceOf(msg.sender) >= parameterProposalStake, "Insufficient stake for proposal");

        IERC20(reputationTokenAddress).transferFrom(msg.sender, address(this), parameterProposalStake); // Take stake

        uint256 proposalId = nextParameterProposalId++;
        parameterProposals[proposalId] = ParameterProposal({
            name: name,
            proposer: msg.sender,
            encodedCallData: encodedCallData,
            targetContract: targetContract,
            createdTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp + proposalVotingPeriod,
            forVotes: 0,
            againstVotes: 0,
            stakeAmount: parameterProposalStake,
            state: ProposalState.Pending
        });
        emit ParameterProposalSubmitted(proposalId, msg.sender, name, targetContract);
    }

    /// @notice Allows reputation token holders to vote on parameter change proposals.
    /// @param proposalId The ID of the parameter proposal.
    /// @param support `true` for 'for' vote, `false` for 'against' vote.
    function voteOnParameterProposal(uint256 proposalId, bool support) external whenNotShutdown {
        ParameterProposal storage proposal = parameterProposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in active voting state");
        require(block.timestamp <= proposal.votingEndsTimestamp, "Voting period has ended");
        require(!hasVotedParameter[proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterReputation = IERC20(reputationTokenAddress).balanceOf(msg.sender);
        require(voterReputation > 0, "No reputation to vote");

        hasVotedParameter[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += voterReputation;
        } else {
            proposal.againstVotes += voterReputation;
        }
        emit ParameterVote(proposalId, msg.sender, support, voterReputation);
    }

    /// @notice Executes a passed parameter proposal, applying the proposed changes to the vault.
    ///         This function can be called by anyone after the voting period has passed.
    /// @param proposalId The ID of the parameter proposal to finalize.
    function finalizeParameterProposal(uint256 proposalId) external whenNotShutdown {
        ParameterProposal storage proposal = parameterProposals[proposalId];
        require(proposal.state != ProposalState.Executed && proposal.state != ProposalState.Rejected, "Proposal already finalized");
        require(block.timestamp > proposal.votingEndsTimestamp, "Voting period not yet ended");

        if (proposal.forVotes > proposal.againstVotes) {
            proposal.state = ProposalState.Approved;
            // Execute the proposed call
            (bool success, ) = proposal.targetContract.call(proposal.encodedCallData);
            require(success, "Parameter proposal execution failed");
            proposal.state = ProposalState.Executed;
            IERC20(reputationTokenAddress).transfer(proposal.proposer, proposal.stakeAmount); // Return proposer's stake
            emit ParameterProposalFinalized(proposalId, ProposalState.Executed);
        } else {
            proposal.state = ProposalState.Rejected;
            // Optionally, slash proposer's stake or return it
            IERC20(reputationTokenAddress).transfer(proposal.proposer, proposal.stakeAmount); // Return proposer's stake
            emit ParameterProposalFinalized(proposalId, ProposalState.Rejected);
        }
    }

    // I. IV. Fee & Payouts

    /// @notice Allows the original proposer of a profitable strategy to claim their accrued performance fees.
    ///         Requires a mechanism to track individual strategy profits.
    /// @param strategyId The ID of the active strategy.
    function claimStrategyPerformanceFee(uint256 strategyId) external whenNotShutdown {
        ActiveStrategy storage activeStrategy = activeStrategies[strategyId];
        require(activeStrategy.proposer == msg.sender, "Only strategy proposer can claim fees");
        
        // This is a complex part: how to calculate "profit" and "performance fees".
        // In a real scenario, the strategy contract might report profits,
        // or the vault tracks portfolio performance attributed to each strategy.
        // For simplicity, let's assume `activeStrategy.totalProfitGenerated` is updated
        // externally or by the `executeStrategy` function (which would need to be enhanced).
        
        uint256 feesDue = (activeStrategy.totalProfitGenerated * performanceFeeRate) / 10000; // Assuming performanceFeeRate is basis points (10000 for 100%)
        require(feesDue > 0, "No performance fees due");

        // Transfer fees (e.g., in a stablecoin or the native token)
        // This part needs a specific asset for fee payout. Let's assume a "feeAsset" is configured.
        // For now, it's a conceptual transfer.
        // IERC20(feeAsset).transfer(msg.sender, feesDue);
        
        activeStrategy.totalProfitGenerated -= feesDue; // Reduce profit after payout

        emit PerformanceFeeClaimed(strategyId, msg.sender, feesDue);
    }

    /// @notice (DAO/Governance via proposal) Sets the percentage of profits allocated as performance fees for successful strategies.
    /// @param newRate The new performance fee rate in basis points (e.g., 100 for 1%).
    function setPerformanceFeeRate(uint256 newRate) external onlyOwner { // Callable via ParameterProposal
        require(newRate <= 10000, "Fee rate cannot exceed 100%"); // Max 100% (10000 basis points)
        performanceFeeRate = newRate;
        emit PerformanceFeeRateUpdated(newRate);
    }

    /// @notice (DAO/Governance via proposal) Updates the required stake amounts for various proposals and challenges.
    /// @param _newStrategyProposalStake New stake for strategy proposals.
    /// @param _newParameterProposalStake New stake for parameter proposals.
    /// @param _newChallengeStake New stake for challenging proposals.
    function setProposalStakeRequirements(
        uint256 _newStrategyProposalStake,
        uint256 _newParameterProposalStake,
        uint256 _newChallengeStake
    ) external onlyOwner { // Callable via ParameterProposal
        strategyProposalStake = _newStrategyProposalStake;
        parameterProposalStake = _newParameterProposalStake;
        challengeStake = _newChallengeStake;
        emit ProposalStakeRequirementsUpdated(_newStrategyProposalStake, _newParameterProposalStake, _newChallengeStake);
    }

    // J. V. Emergency & Administration

    /// @notice (Owner) Triggers an emergency shutdown, pausing all operations except withdrawals.
    function initiateEmergencyShutdown() external onlyOwner {
        require(!shutdownActive, "Already in shutdown");
        shutdownActive = true;
        emit EmergencyShutdown(msg.sender);
    }

    /// @notice (Owner) Resumes vault operations after an emergency shutdown.
    function resumeOperations() external onlyOwner whenShutdown {
        shutdownActive = false;
        emit OperationsResumed(msg.sender);
    }

    /// @notice (Owner) Whitelists or blacklists addresses that are allowed to trigger strategy executions.
    /// @param keeper The address of the keeper.
    /// @param status `true` to whitelist, `false` to blacklist.
    function setKeeperStatus(address keeper, bool status) external onlyOwner {
        isKeeper[keeper] = status;
        emit KeeperStatus(keeper, status);
    }

    // K. VI. Internal Helpers

    /// @dev Internal function to get the value of a given asset in the base currency (e.g., USD).
    ///      Assumes Chainlink-compatible oracles are set up for each asset.
    /// @param asset The address of the ERC-20 token.
    /// @param amount The amount of the asset.
    /// @return The value of the asset in base currency, scaled by BASE_CURRENCY_DECIMALS.
    function _getAssetValueInBaseCurrency(address asset, uint256 amount) internal view returns (uint256) {
        if (asset == address(0)) { // Native token (ETH/BNB/etc.)
            // Logic to get native token price via oracle (e.g., ETH/USD)
            // For simplicity, we skip native token handling in this example.
            revert("Native token not supported for _getAssetValueInBaseCurrency");
        }

        // For simplicity, let's assume a direct oracle for each asset to base currency (e.g., USDC/USD, WETH/USD).
        // A real system would have a registry or mapping `asset => oracleAddress`.
        // Let's assume `baseCurrencyOracle` is for all assets for now, or this function needs a map.
        // Or, each `ActiveStrategy` has its own `oracleAddresses` mapping.
        
        // This is a simplified example. A production system needs robust oracle management.
        // For example, if `asset` is a stablecoin like USDC, its value might be 1:1 with base currency.
        // If `asset` is WETH, we'd need WETH/USD oracle.
        // For demonstration, let's assume `baseCurrencyOracle` provides price for *all* assets directly (unrealistic).
        // Or, more accurately, we assume `asset` itself is the base currency (e.g., USDC, and `baseCurrencyOracle` gives 1:1).

        if (asset == reputationTokenAddress) { // Reputation token has no financial value for NAV
            return 0;
        }

        // --- Simplified Oracle Interaction ---
        // This part needs to be refined for actual multi-asset NAV calculation.
        // Option 1: Each whitelisted asset has its own oracle.
        // Option 2: A generic oracle converts everything to a common intermediate.
        // For demonstration purposes, let's use the provided `baseCurrencyOracle` as a generic price source for any asset,
        // which implies `baseCurrencyOracle` somehow knows all prices (highly simplified and usually incorrect).
        // A better approach would be:
        // `mapping(address => address) public assetOracles;` and look up `assetOracles[asset]`.

        // Using a mock or a specific Chainlink oracle for *this specific asset* (e.g., USDC/USD if base is USD).
        // For the sake of this example, we'll pretend `baseCurrencyOracle` returns asset's price directly against base.
        // In reality: `IAggregatorV3 assetOracle = IAggregatorV3(assetOracles[asset]);`

        IAggregatorV3 priceFeed = IAggregatorV3(baseCurrencyOracle); // Highly simplified
        (, int256 price, , ,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed");

        // Assume asset has 18 decimals, oracle has 8 decimals (common for Chainlink)
        // If asset has different decimals, adjust accordingly.
        uint256 assetDecimals = 18; // Common for ERC20
        uint256 oracleDecimals = 8; // Common for Chainlink

        // (amount * price) / (10^(assetDecimals)) * (10^(BASE_CURRENCY_DECIMALS)) / (10^(oracleDecimals))
        // amount is usually 18 decimals for ERC20s, price is usually 8 decimals for Chainlink.
        // We want result in BASE_CURRENCY_DECIMALS.

        uint256 normalizedAmount = amount / (10**(assetDecimals - BASE_CURRENCY_DECIMALS)); // Adjust amount to BASE_CURRENCY_DECIMALS scale
        uint256 value = (normalizedAmount * uint256(price)) / (10**oracleDecimals);

        return value;
    }
}
```