This smart contract, **ChronoForge Protocol: Adaptive Strategy Engine for Decentralized Capital (ASEDC)**, is designed as an autonomous, self-evolving investment and strategy engine. It allows participants to create and manage *adaptive vaults* that dynamically execute investment strategies based on both on-chain and off-chain data (via integrated oracles). The protocol incorporates a robust *Karma-based reputation system* for strategy proposers, oracle providers, and validators, and features an *Evolutionary Fund* mechanism to foster continuous improvement and innovation within the ecosystem.

---

### **Outline and Function Summary**

**I. Core Protocol Management & State**
1.  **`constructor`**: Initializes protocol parameters, roles, and sets up the core `EvolutionaryFund`.
2.  **`setProtocolFeeRecipient`**: Sets the address designated to receive protocol fees (requires `ADMIN_ROLE`).
3.  **`setProtocolFeePercentage`**: Adjusts the percentage of fees collected by the protocol (requires `ADMIN_ROLE`).
4.  **`pauseProtocol`**: Implements a global pause functionality for emergency situations, halting most protocol operations (requires `ADMIN_ROLE`).
5.  **`unpauseProtocol`**: Resumes protocol operations after a pause (requires `ADMIN_ROLE`).

**II. Vault & Asset Management**
6.  **`createAdaptiveVault`**: Deploys a new, empty adaptive vault instance configured to support a specific set of ERC20 tokens (requires `VAULT_MANAGER_ROLE`).
7.  **`depositIntoVault`**: Allows users to deposit supported assets into a specified adaptive vault, receiving vault shares in return.
8.  **`withdrawFromVault`**: Enables users to redeem their vault shares and withdraw their proportional assets from a specified vault.
9.  **`emergencyVaultWithdrawal`**: Provides a mechanism for authorized vault managers or owners to withdraw all funds from a vault in critical situations (requires `VAULT_MANAGER_ROLE` or vault owner).

**III. Strategy Lifecycle Management**
10. **`proposeStrategy`**: Facilitates the submission of a new investment or operational strategy, including its logic, conditions, and actions, for community review (requires `STRATEGY_PROPOSER_ROLE`).
11. **`voteOnStrategyProposal`**: Allows Karma holders to vote on proposed strategies, influencing their approval or rejection status.
12. **`activateStrategyForVault`**: Binds an approved, globally active strategy to a specific adaptive vault, making it eligible for execution within that vault (requires `VAULT_MANAGER_ROLE` or vault owner).
13. **`deactivateStrategyForVault`**: Disables an active strategy within a vault, preventing its further execution (requires `VAULT_MANAGER_ROLE` or vault owner).
14. **`executeStrategyStep`**: Triggers the execution of the next eligible action within a vault's strategy if all predefined conditions are met. This function can be called by anyone.
15. **`updateStrategyVaultParameters`**: Allows vault managers to adjust specific parameters (e.g., execution frequency, conditions, actions) of a strategy active within their vault (requires `VAULT_MANAGER_ROLE` or vault owner).

**IV. Karma & Reputation System**
16. **`challengeStrategyExecution`**: Enables users to formally challenge the correctness, profitability, or integrity of a strategy's execution or related oracle data.
17. **`resolveChallenge`**: Facilitates the resolution of a submitted challenge by designated dispute resolvers, impacting the Karma scores of participants based on the outcome (requires `DISPUTE_RESOLVER_ROLE`).
18. **`getUserKarma`**: Retrieves the current Karma score for any given address.

**V. Oracle & External Data Integration**
19. **`registerOracleProvider`**: Allows an address to be registered as an approved data oracle provider for a specific data key (requires `ADMIN_ROLE`).
20. **`submitOracleData`**: Enables registered oracle providers to submit data points (e.g., market prices, AI sentiment scores) for a given oracle key (requires `ORACLE_PROVIDER_ROLE`).
21. **`setOracleDataValidityThreshold`**: Sets the minimum consensus (number of validated submissions) required for oracle data to be considered trustworthy and active (requires `ADMIN_ROLE`).
22. **`revokeOracleProvider`**: Removes an oracle provider due to consistent inaccuracy, malicious activity, or other governance decisions (requires `ADMIN_ROLE`).

**VI. Evolutionary Fund & Governance**
23. **`proposeEvolutionaryFundAllocation`**: Allows any user to propose an allocation of funds from the Evolutionary Fund for initiatives like research, development, or grants.
24. **`voteOnFundAllocation`**: Enables Karma holders to vote on proposed allocations from the Evolutionary Fund, using their Karma as voting weight.
25. **`distributeEvolutionaryFund`**: Releases funds to approved recipients from the Evolutionary Fund after successful governance vote (requires `ADMIN_ROLE`).
26. **`upgradeProtocolImplementation`**: A placeholder function that, in a full system, would trigger the upgrade of the protocol's implementation contract (assuming a proxy pattern like UUPS) (requires `ADMIN_ROLE`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: For a real-world scenario, this contract would likely be part of a larger system,
// potentially using UUPS for upgradability and external libraries/contracts for
// complex DeFi interactions (e.g., swapping, lending).
// This single-file contract aims to demonstrate the core logic and concepts.

/**
 * @title ChronoForge Protocol: Adaptive Strategy Engine for Decentralized Capital (ASEDC)
 * @dev This contract orchestrates an autonomous, self-evolving investment and strategy engine.
 *      It enables users to propose and execute adaptive investment strategies within vaults,
 *      integrates with decentralized oracles, and features a Karma-based reputation system
 *      alongside an Evolutionary Fund for continuous protocol improvement.
 */
contract ChronoForgeProtocol is AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    /* ========== ROLES ========== */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Manages core protocol settings, pause/unpause, oracle registrations.
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE"); // Can create vaults, manage vault-specific settings and strategies.
    bytes32 public constant STRATEGY_PROPOSER_ROLE = keccak256("STRATEGY_PROPOSER_ROLE"); // Can propose new strategies for governance approval.
    bytes32 public constant ORACLE_PROVIDER_ROLE = keccak256("ORACLE_PROVIDER_ROLE"); // Can submit data to registered oracles.
    bytes32 public constant DISPUTE_RESOLVER_ROLE = keccak256("DISPUTE_RESOLVER_ROLE"); // Can resolve challenges and disputes, affecting Karma.

    /* ========== ENUMS & STRUCTS ========== */

    enum StrategyActionType {
        Rebalance, // Rebalance assets within the vault (e.g., change asset weights)
        Swap,      // Swap one token for another (simulated external interaction)
        Lend,      // Deposit into a lending protocol (simulated external interaction)
        Borrow,    // Borrow from a lending protocol (simulated external interaction)
        Custom     // For highly specific, custom interactions via `callData`
    }

    // Defines a condition that must be met for a strategy action to be considered.
    struct StrategyCondition {
        bytes32 oracleKey;     // Key for the oracle data point (e.g., "ETH_PRICE", "AI_SENTIMENT_SCORE")
        uint256 value;         // Threshold value for the condition
        bool greaterThan;      // True if condition is 'oracle_data > value', false if 'oracle_data < value'
        uint256 maxDeviation;  // Max allowed deviation from the oracle data point for it to be considered valid relative to the condition. (Simplified for this demo)
    }

    // Defines an action to be performed if strategy conditions are met.
    struct StrategyAction {
        StrategyActionType actionType;
        address targetToken;   // Primary token involved (e.g., token to buy/sell, token to lend/borrow)
        address secondaryToken; // For swaps, the token to receive. For custom, target contract.
        uint256 amountPercentage; // Percentage of vault's `targetToken` balance to use (e.g., 5000 = 50%)
        bytes callData;         // Encoded call data for external contract interaction (for Custom, Swap, Lend, Borrow actions)
    }

    // Represents a complete investment or operational strategy.
    struct Strategy {
        uint256 strategyId;         // Unique ID for the strategy
        address proposer;           // Address that proposed the strategy
        string name;                // Name of the strategy
        string description;         // Description of the strategy
        StrategyCondition[] conditions; // Conditions that must be met for execution
        StrategyAction[] actions;   // Actions to perform if conditions are met
        uint256 lastExecutedBlock;  // Block number when strategy was last executed
        uint256 executionFrequency; // Minimum blocks between executions (0 for no frequency limit)
        bool isActive;              // Whether the strategy is currently active (globally approved)
    }

    // Represents an adaptive vault where users deposit assets and strategies are executed.
    struct AdaptiveVault {
        uint256 vaultId;            // Unique ID for the vault
        address owner;              // Creator/primary manager of the vault
        address[] supportedTokens;  // List of ERC20 token addresses the vault can hold
        mapping(address => uint256) balances; // Internal balance tracking for supported tokens
        mapping(uint256 => bool) activeStrategies; // Strategy IDs currently active within this vault
        uint256 totalShares;        // Total shares minted for depositors in this vault
        mapping(address => uint256) shares; // Shares owned by each depositor in this vault
        bool paused;                // Vault-specific pause status
    }

    // Represents a single data point submitted by an oracle provider.
    struct OracleDataPoint {
        bytes32 key;                // Unique identifier for the data (e.g., "ETH_PRICE_CHAINLINK")
        uint256 value;              // The submitted data value (e.g., price in USD * 1e18)
        uint256 timestamp;          // When the data was submitted
        address provider;           // The address that submitted the data
        uint256 validityScore;      // Aggregated score/confidence from validation
    }

    // Represents a proposal for allocating funds from the Evolutionary Fund.
    struct FundAllocationProposal {
        uint256 proposalId;
        address proposer;
        uint256 amount;
        address recipient;
        string description;
        uint256 totalVotesFor;    // Sum of Karma from 'for' votes
        uint256 totalVotesAgainst; // Sum of Karma from 'against' votes
        bool executed;
    }

    /* ========== STATE VARIABLES ========== */

    // Protocol-wide
    uint256 public protocolFeePercentage; // e.g., 100 = 1%, 500 = 5% (max 1000 = 10%)
    address public protocolFeeRecipient;  // Address receiving fees (e.g., DAO treasury)
    uint256 public evolutionaryFundBalance; // Funds reserved for protocol development/grants
    uint256 public constant MAX_FEE_PERCENTAGE = 1000; // 10% in basis points (10000 = 100%)

    // Vaults
    uint256 private nextVaultId = 1;
    mapping(uint256 => AdaptiveVault) public vaults;
    uint256[] public allVaultIds; // To allow iteration over all created vaults

    // Strategies
    uint256 private nextStrategyId = 1;
    mapping(uint256 => Strategy) public strategies;
    mapping(uint256 => bool) public isStrategyApproved; // True if strategy is approved by governance/Karma holders
    uint256[] public allStrategyIds; // To allow iteration over all proposed strategies

    // Karma & Reputation
    mapping(address => uint256) public userKarma; // User reputation score
    mapping(uint256 => mapping(address => bool)) public hasVotedOnStrategyProposal; // Tracks votes on strategy proposals
    mapping(uint256 => mapping(address => bool)) public hasVotedOnFundAllocation;   // Tracks votes on fund allocation proposals

    // Oracles
    mapping(bytes32 => address[]) public registeredOracleProviders; // oracleKey => list of authorized providers
    mapping(bytes32 => OracleDataPoint[]) public oracleDataHistory; // oracleKey => chronological history of submitted data
    mapping(bytes32 => uint256) public oracleDataValidityThreshold; // Minimum validity score (e.g., number of reliable sources) for data
    mapping(bytes32 => OracleDataPoint) public latestOracleData; // Stores the latest *validated* oracle data point

    // Evolutionary Fund Proposals
    uint256 private nextFundProposalId = 1;
    mapping(uint256 => FundAllocationProposal) public fundProposals;

    // Challenge System (Simplified)
    uint256 private nextChallengeId = 1;
    mapping(uint256 => bytes32) public challengeEntityType; // Challenge ID -> type of entity challenged (e.g., "STRATEGY_EXECUTION")
    mapping(uint256 => uint256) public challengeEntityId;   // Challenge ID -> specific entity ID
    mapping(uint256 => address) public challengeChallenger; // Challenge ID -> challenger address
    mapping(uint256 => bool) public challengeResolved;       // Challenge ID -> whether it's resolved

    /* ========== EVENTS ========== */

    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event ProtocolFeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeePercentageSet(uint256 oldPercentage, uint256 newPercentage);

    event VaultCreated(uint256 indexed vaultId, address indexed owner, address[] supportedTokens);
    event Deposited(uint256 indexed vaultId, address indexed depositor, address indexed token, uint256 amount, uint256 sharesMinted);
    event Withdrawn(uint256 indexed vaultId, address indexed withdrawer, address indexed token, uint256 amount, uint256 sharesBurned);
    event EmergencyVaultWithdrawalPerformed(uint256 indexed vaultId, address indexed by, address indexed token, uint256 amount);

    event StrategyProposed(uint256 indexed strategyId, address indexed proposer, string name);
    event StrategyProposalVoted(uint256 indexed strategyId, address indexed voter, bool approved);
    event StrategyActivatedForVault(uint256 indexed vaultId, uint256 indexed strategyId);
    event StrategyDeactivatedForVault(uint256 indexed vaultId, uint256 indexed strategyId);
    event StrategyStepExecuted(uint256 indexed vaultId, uint256 indexed strategyId, bytes32 oracleKey, uint256 oracleValue);
    event StrategyVaultParametersUpdated(uint256 indexed vaultId, uint256 indexed strategyId);

    event ChallengeSubmitted(uint256 indexed challengeId, bytes32 indexed entityType, uint256 indexed entityId, address indexed challenger, string description);
    event ChallengeResolved(uint256 indexed challengeId, bool successForChallenger, address indexed resolver);
    event KarmaUpdated(address indexed user, uint256 oldKarma, uint256 newKarma);

    event OracleProviderRegistered(bytes32 indexed oracleKey, address indexed provider);
    event OracleDataSubmitted(bytes32 indexed oracleKey, address indexed provider, uint256 value, uint256 timestamp);
    event OracleDataValidated(bytes32 indexed oracleKey, uint256 value, uint256 timestamp);
    event OracleProviderRevoked(bytes32 indexed oracleKey, address indexed provider);

    event EvolutionaryFundAllocationProposed(uint256 indexed proposalId, address indexed proposer, uint256 amount, address indexed recipient, string description);
    event EvolutionaryFundAllocationVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event EvolutionaryFundDistributed(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event ProtocolUpgraded(address indexed newImplementation);

    /* ========== MODIFIERS ========== */

    // Restricts access to vault owner or VAULT_MANAGER_ROLE.
    modifier onlyVaultManagerOrOwner(uint256 _vaultId) {
        require(hasRole(VAULT_MANAGER_ROLE, _msgSender()) || vaults[_vaultId].owner == _msgSender(), "ChronoForge: Not vault manager or owner");
        _;
    }

    // Ensures the strategy has been globally approved.
    modifier onlyApprovedStrategy(uint256 _strategyId) {
        require(isStrategyApproved[_strategyId], "ChronoForge: Strategy not approved by governance");
        _;
    }

    // Ensures the strategy is currently active within the specified vault.
    modifier onlyActiveStrategyInVault(uint256 _vaultId, uint256 _strategyId) {
        require(vaults[_vaultId].activeStrategies[_strategyId], "ChronoForge: Strategy not active in this vault");
        _;
    }

    // Ensures the specific vault is not paused.
    modifier notPausedVault(uint256 _vaultId) {
        require(!vaults[_vaultId].paused, "ChronoForge: Vault is paused");
        _;
    }

    // Ensures the caller has a minimum Karma score.
    modifier hasSufficientKarma(address _user, uint256 _requiredKarma) {
        require(userKarma[_user] >= _requiredKarma, "ChronoForge: Insufficient Karma");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _initialAdmin, address _protocolFeeRecipient) {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(ADMIN_ROLE, _initialAdmin); // Grant initial admin all core roles
        _grantRole(VAULT_MANAGER_ROLE, _initialAdmin);
        _grantRole(STRATEGY_PROPOSER_ROLE, _initialAdmin);
        _grantRole(ORACLE_PROVIDER_ROLE, _initialAdmin);
        _grantRole(DISPUTE_RESOLVER_ROLE, _initialAdmin);

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeePercentage = 50; // 0.5% initially (in basis points: 50/10000)
        evolutionaryFundBalance = 0; // Starts empty
    }

    /* ========== I. CORE PROTOCOL MANAGEMENT & STATE ========== */

    /**
     * @dev Sets the address that receives protocol fees.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _newRecipient The new address for fee recipient.
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyRole(ADMIN_ROLE) {
        require(_newRecipient != address(0), "ChronoForge: Invalid recipient address");
        emit ProtocolFeeRecipientSet(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @dev Adjusts the percentage of fees taken by the protocol.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _newPercentage The new fee percentage in basis points (e.g., 50 for 0.5%, 100 for 1%). Max 1000 (10%).
     */
    function setProtocolFeePercentage(uint256 _newPercentage) external onlyRole(ADMIN_ROLE) {
        require(_newPercentage <= MAX_FEE_PERCENTAGE, "ChronoForge: Fee percentage too high (max 10%)");
        emit ProtocolFeePercentageSet(protocolFeePercentage, _newPercentage);
        protocolFeePercentage = _newPercentage;
    }

    /**
     * @dev Pauses the entire protocol in case of emergencies.
     *      Halts most state-changing user interactions. Only callable by `ADMIN_ROLE`.
     */
    function pauseProtocol() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
        emit ProtocolPaused(_msgSender());
    }

    /**
     * @dev Unpauses the entire protocol, resuming normal operations.
     *      Only callable by `ADMIN_ROLE`.
     */
    function unpauseProtocol() external onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
        emit ProtocolUnpaused(_msgSender());
    }

    /* ========== II. VAULT & ASSET MANAGEMENT ========== */

    /**
     * @dev Creates a new adaptive vault instance that can hold and manage a specific set of ERC20 tokens.
     *      Only callable by an address with `VAULT_MANAGER_ROLE`.
     * @param _supportedTokens An array of ERC20 token addresses that the vault will accept deposits of.
     * @return vaultId The ID of the newly created vault.
     */
    function createAdaptiveVault(address[] memory _supportedTokens) external onlyRole(VAULT_MANAGER_ROLE) returns (uint256) {
        require(_supportedTokens.length > 0, "ChronoForge: Must support at least one token");
        uint256 currentVaultId = nextVaultId++;
        AdaptiveVault storage newVault = vaults[currentVaultId];
        newVault.vaultId = currentVaultId;
        newVault.owner = _msgSender();
        newVault.supportedTokens = _supportedTokens;
        newVault.totalShares = 0;
        newVault.paused = false;

        allVaultIds.push(currentVaultId);
        emit VaultCreated(currentVaultId, _msgSender(), _supportedTokens);
        return currentVaultId;
    }

    /**
     * @dev Deposits assets into a specified adaptive vault. Users receive shares proportional to their deposit.
     *      Approve the contract to spend the tokens before calling this.
     * @param _vaultId The ID of the target vault.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositIntoVault(uint256 _vaultId, address _token, uint256 _amount) external whenNotPaused notPausedVault(_vaultId) nonReentrant {
        AdaptiveVault storage vault = vaults[_vaultId];
        require(vault.vaultId != 0, "ChronoForge: Vault does not exist");
        bool isSupported = false;
        for (uint256 i = 0; i < vault.supportedTokens.length; i++) {
            if (vault.supportedTokens[i] == _token) {
                isSupported = true;
                break;
            }
        }
        require(isSupported, "ChronoForge: Token not supported by this vault");
        require(_amount > 0, "ChronoForge: Deposit amount must be greater than zero");

        // Transfer tokens to the contract (representing the vault's custody)
        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);

        // Calculate shares to mint. Simplified for demo: shares are based on proportional value
        // of deposited token relative to total vault value. A real system would use a common currency NAV.
        uint256 totalVaultValue = 0;
        for (uint256 i = 0; i < vault.supportedTokens.length; i++) {
            totalVaultValue = totalVaultValue.add(vault.balances[vault.supportedTokens[i]]);
        }

        uint256 sharesToMint;
        if (vault.totalShares == 0 || totalVaultValue == 0) {
            sharesToMint = _amount; // First deposit or empty vault, 1 share = 1 unit of first token
        } else {
            sharesToMint = _amount.mul(vault.totalShares).div(totalVaultValue);
        }
        require(sharesToMint > 0, "ChronoForge: Shares to mint must be greater than zero");

        vault.balances[_token] = vault.balances[_token].add(_amount);
        vault.shares[_msgSender()] = vault.shares[_msgSender()].add(sharesToMint);
        vault.totalShares = vault.totalShares.add(sharesToMint);

        emit Deposited(_vaultId, _msgSender(), _token, _amount, sharesToMint);
    }

    /**
     * @dev Allows users to withdraw their share from a specified adaptive vault.
     *      Withdrawal amounts are proportional to the user's shares in the vault.
     * @param _vaultId The ID of the target vault.
     * @param _sharesToBurn The number of shares to burn for withdrawal.
     * @param _preferredToken The ERC20 token user prefers to withdraw. The protocol attempts to fulfill this.
     */
    function withdrawFromVault(uint256 _vaultId, uint256 _sharesToBurn, address _preferredToken) external whenNotPaused notPausedVault(_vaultId) nonReentrant {
        AdaptiveVault storage vault = vaults[_vaultId];
        require(vault.vaultId != 0, "ChronoForge: Vault does not exist");
        require(vault.shares[_msgSender()] >= _sharesToBurn, "ChronoForge: Insufficient shares");
        require(_sharesToBurn > 0, "ChronoForge: Withdraw amount must be greater than zero");

        // Calculate proportional withdrawal amount. Simplified: total value is sum of balances.
        uint256 totalVaultValue = 0;
        for (uint256 i = 0; i < vault.supportedTokens.length; i++) {
            totalVaultValue = totalVaultValue.add(vault.balances[vault.supportedTokens[i]]);
        }
        require(totalVaultValue > 0, "ChronoForge: Vault value cannot be zero for share calculation");

        uint256 proportionalValueToWithdraw = _sharesToBurn.mul(totalVaultValue).div(vault.totalShares);

        uint256 actualWithdrawAmount = 0;
        address actualWithdrawnToken = _preferredToken; // Assume preferred token first

        // Try to withdraw preferred token
        if (vault.balances[_preferredToken] > 0) {
            uint256 preferredTokenValueShare = proportionalValueToWithdraw.mul(vault.balances[_preferredToken]).div(totalVaultValue);
            actualWithdrawAmount = preferredTokenValueShare; // Simplified, assumes 1:1 value
            if (actualWithdrawAmount > vault.balances[_preferredToken]) {
                actualWithdrawAmount = vault.balances[_preferredToken]; // Don't withdraw more than available
            }
        } else {
            // If preferred token not available or insufficient, withdraw from any available token
            for (uint256 i = 0; i < vault.supportedTokens.length; i++) {
                address currentToken = vault.supportedTokens[i];
                if (vault.balances[currentToken] > 0) {
                    uint256 tokenWithdrawAmount = proportionalValueToWithdraw.mul(vault.balances[currentToken]).div(totalVaultValue);
                     if (tokenWithdrawAmount == 0 && proportionalValueToWithdraw > 0) tokenWithdrawAmount = 1; // withdraw at least 1 unit if value > 0
                    if (tokenWithdrawAmount > vault.balances[currentToken]) {
                        tokenWithdrawAmount = vault.balances[currentToken];
                    }
                    if (tokenWithdrawAmount > 0) {
                        actualWithdrawAmount = tokenWithdrawAmount;
                        actualWithdrawnToken = currentToken;
                        break; // Withdraw from first available for simplicity. Real system needs complex pro-rata distribution.
                    }
                }
            }
        }
        require(actualWithdrawAmount > 0, "ChronoForge: No assets could be withdrawn or insufficient balance");

        vault.balances[actualWithdrawnToken] = vault.balances[actualWithdrawnToken].sub(actualWithdrawAmount);
        IERC20(actualWithdrawnToken).transfer(_msgSender(), actualWithdrawAmount);

        vault.shares[_msgSender()] = vault.shares[_msgSender()].sub(_sharesToBurn);
        vault.totalShares = vault.totalShares.sub(_sharesToBurn);

        emit Withdrawn(_vaultId, _msgSender(), actualWithdrawnToken, actualWithdrawAmount, _sharesToBurn);
    }


    /**
     * @dev Allows authorized roles (VAULT_MANAGER_ROLE or vault owner) to withdraw all or a specific amount of funds
     *      from a vault in an emergency situation. This bypasses normal withdrawal logic.
     * @param _vaultId The ID of the target vault.
     * @param _token The ERC20 token to withdraw.
     * @param _amount The specific amount to withdraw. If 0, it withdraws the entire balance of the specified token.
     */
    function emergencyVaultWithdrawal(uint256 _vaultId, address _token, uint256 _amount) external onlyVaultManagerOrOwner(_vaultId) whenNotPaused {
        AdaptiveVault storage vault = vaults[_vaultId];
        require(vault.vaultId != 0, "ChronoForge: Vault does not exist");

        uint256 amountToWithdraw = (_amount == 0) ? vault.balances[_token] : _amount;
        require(vault.balances[_token] >= amountToWithdraw, "ChronoForge: Insufficient balance in vault for withdrawal");
        require(amountToWithdraw > 0, "ChronoForge: Amount to withdraw must be greater than zero");

        vault.balances[_token] = vault.balances[_token].sub(amountToWithdraw);
        IERC20(_token).transfer(_msgSender(), amountToWithdraw);

        // This function doesn't burn shares as it's an emergency bypass.
        // A governance decision would typically follow to handle remaining shares/deposits.

        emit EmergencyVaultWithdrawalPerformed(_vaultId, _msgSender(), _token, amountToWithdraw);
    }

    /* ========== III. STRATEGY LIFECYCLE MANAGEMENT ========== */

    /**
     * @dev Proposes a new investment or operational strategy for review by Karma holders.
     *      Only callable by an address with `STRATEGY_PROPOSER_ROLE`.
     * @param _name A descriptive name for the strategy.
     * @param _description A detailed explanation of the strategy's logic and goals.
     * @param _conditions An array of conditions that must be met for the strategy to execute.
     * @param _actions An array of actions to perform if conditions are met.
     * @param _executionFrequency Minimum blocks between executions (0 for no frequency limit, e.g., only execute once per day).
     * @return strategyId The ID of the newly proposed strategy.
     */
    function proposeStrategy(
        string memory _name,
        string memory _description,
        StrategyCondition[] memory _conditions,
        StrategyAction[] memory _actions,
        uint256 _executionFrequency
    ) external onlyRole(STRATEGY_PROPOSER_ROLE) returns (uint256) {
        require(bytes(_name).length > 0, "ChronoForge: Strategy name cannot be empty");
        require(_conditions.length > 0, "ChronoForge: Strategy must have at least one condition");
        require(_actions.length > 0, "ChronoForge: Strategy must have at least one action");

        uint256 currentStrategyId = nextStrategyId++;
        strategies[currentStrategyId] = Strategy({
            strategyId: currentStrategyId,
            proposer: _msgSender(),
            name: _name,
            description: _description,
            conditions: _conditions,
            actions: _actions,
            lastExecutedBlock: 0,
            executionFrequency: _executionFrequency,
            isActive: false // Not active globally until approved by governance
        });

        allStrategyIds.push(currentStrategyId);
        emit StrategyProposed(currentStrategyId, _msgSender(), _name);
        return currentStrategyId;
    }

    /**
     * @dev Allows Karma holders to vote on a proposed strategy.
     *      A minimum Karma score (e.g., 100) is required to prevent spam voting.
     *      For this demo, a single vote from a sufficiently karmic user can approve.
     *      A real system would have a voting period, quorum, and majority rules.
     * @param _strategyId The ID of the strategy proposal.
     * @param _approve True to vote for approval, false to vote for rejection.
     */
    function voteOnStrategyProposal(uint256 _strategyId, bool _approve) external hasSufficientKarma(_msgSender(), 100) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.strategyId != 0, "ChronoForge: Strategy does not exist");
        require(!isStrategyApproved[_strategyId], "ChronoForge: Strategy already approved (or permanently rejected)");
        require(!hasVotedOnStrategyProposal[_strategyId][_msgSender()], "ChronoForge: Already voted on this proposal");

        hasVotedOnStrategyProposal[_strategyId][_msgSender()] = true; // Record the vote

        // Simplified logic: enough Karma-weighted votes for approval.
        // For demo, assume enough Karma means direct approval if `_approve` is true.
        // In reality, this would count up total "for" and "against" Karma and trigger based on a threshold/quorum.
        if (_approve) {
            isStrategyApproved[_strategyId] = true;
            strategy.isActive = true; // Mark globally active upon approval
            userKarma[_msgSender()] = userKarma[_msgSender()].add(50); // Reward for positive governance participation
        } else {
            userKarma[_msgSender()] = userKarma[_msgSender()].add(10); // Smaller reward for participation in any case
        }
        emit StrategyProposalVoted(_strategyId, _msgSender(), _approve);
    }

    /**
     * @dev Activates an approved strategy for a specific adaptive vault.
     *      Only callable by `VAULT_MANAGER_ROLE` or the vault's owner.
     * @param _vaultId The ID of the target vault.
     * @param _strategyId The ID of the strategy to activate. Must be globally approved (`isStrategyApproved`).
     */
    function activateStrategyForVault(uint256 _vaultId, uint256 _strategyId) external onlyVaultManagerOrOwner(_vaultId) onlyApprovedStrategy(_strategyId) {
        AdaptiveVault storage vault = vaults[_vaultId];
        require(vault.vaultId != 0, "ChronoForge: Vault does not exist");
        require(!vault.activeStrategies[_strategyId], "ChronoForge: Strategy already active in this vault");

        vault.activeStrategies[_strategyId] = true;
        emit StrategyActivatedForVault(_vaultId, _strategyId);
    }

    /**
     * @dev Deactivates an active strategy within a vault. This prevents further execution of that strategy.
     *      Only callable by `VAULT_MANAGER_ROLE` or the vault's owner.
     * @param _vaultId The ID of the target vault.
     * @param _strategyId The ID of the strategy to deactivate.
     */
    function deactivateStrategyForVault(uint256 _vaultId, uint256 _strategyId) external onlyVaultManagerOrOwner(_vaultId) onlyActiveStrategyInVault(_vaultId, _strategyId) {
        AdaptiveVault storage vault = vaults[_vaultId];
        require(vault.vaultId != 0, "ChronoForge: Vault does not exist");

        vault.activeStrategies[_strategyId] = false;
        emit StrategyDeactivatedForVault(_vaultId, _strategyId);
    }

    /**
     * @dev Executes a single step of an active strategy within a vault if its conditions are met.
     *      Anyone can call this function. Successful callers could be rewarded with Karma or a small fee (not implemented here for simplicity).
     * @param _vaultId The ID of the target vault.
     * @param _strategyId The ID of the strategy to execute.
     */
    function executeStrategyStep(uint256 _vaultId, uint256 _strategyId) external whenNotPaused nonReentrant {
        AdaptiveVault storage vault = vaults[_vaultId];
        Strategy storage strategy = strategies[_strategyId];

        require(vault.vaultId != 0, "ChronoForge: Vault does not exist");
        require(strategy.strategyId != 0 && strategy.isActive, "ChronoForge: Strategy does not exist or is not globally active");
        require(vault.activeStrategies[_strategyId], "ChronoForge: Strategy not active in this vault");
        require(block.number >= strategy.lastExecutedBlock.add(strategy.executionFrequency), "ChronoForge: Execution frequency lock");

        // Check all conditions for the strategy
        for (uint256 i = 0; i < strategy.conditions.length; i++) {
            StrategyCondition storage condition = strategy.conditions[i];
            OracleDataPoint storage latestData = latestOracleData[condition.oracleKey];
            require(latestData.timestamp != 0, "ChronoForge: Oracle data not available for condition");
            require(latestData.validityScore >= oracleDataValidityThreshold[condition.oracleKey], "ChronoForge: Oracle data not sufficiently validated");

            bool conditionMet = false;
            if (condition.greaterThan) {
                conditionMet = latestData.value > condition.value;
            } else {
                conditionMet = latestData.value < condition.value;
            }
            if (!conditionMet) {
                revert("ChronoForge: Strategy conditions not met"); // All conditions must be met
            }
        }

        // Conditions met, proceed to execute actions
        for (uint256 i = 0; i < strategy.actions.length; i++) {
            StrategyAction storage action = strategy.actions[i];
            uint256 amountToAct = vault.balances[action.targetToken].mul(action.amountPercentage).div(10000); // amountPercentage is in basis points
            require(vault.balances[action.targetToken] >= amountToAct, "ChronoForge: Insufficient token balance in vault for action");

            // For simplicity, this demo primarily simulates internal balance changes.
            // In a real system, these would trigger external contract calls (DEX, lending protocols, etc.).
            if (action.actionType == StrategyActionType.Rebalance) {
                // This simulates selling `amountToAct` of `targetToken` and buying `secondaryToken`.
                // Requires external DEX integration and price oracle for accurate conversion.
                require(action.secondaryToken != address(0), "ChronoForge: Rebalance requires a secondary token");
                vault.balances[action.targetToken] = vault.balances[action.targetToken].sub(amountToAct);
                vault.balances[action.secondaryToken] = vault.balances[action.secondaryToken].add(amountToAct); // Simplified, assumes 1:1 value conversion
            } else if (action.actionType == StrategyActionType.Swap) {
                // Simulate a token swap. Would require ERC20 approve and then call to a DEX router.
                require(action.secondaryToken != address(0), "ChronoForge: Swap requires a secondary token");
                vault.balances[action.targetToken] = vault.balances[action.targetToken].sub(amountToAct);
                vault.balances[action.secondaryToken] = vault.balances[action.secondaryToken].add(amountToAct); // Simplified
            } else if (action.actionType == StrategyActionType.Lend) {
                // Simulate depositing into a lending pool. Funds would leave the vault.
                vault.balances[action.targetToken] = vault.balances[action.targetToken].sub(amountToAct);
                // (External call to lending protocol here: e.g., IERC20(action.targetToken).approve(LENDING_POOL, amountToAct); LENDING_POOL.deposit(...); )
            } else if (action.actionType == StrategyActionType.Borrow) {
                // Simulate borrowing from a lending pool. Funds would enter the vault.
                vault.balances[action.targetToken] = vault.balances[action.targetToken].add(amountToAct);
                // (External call to lending protocol here: e.g., LENDING_POOL.borrow(...); )
            } else if (action.actionType == StrategyActionType.Custom) {
                // Allows for highly flexible, but also risky, interactions with any external contract.
                // Example: (bool success, bytes memory returndata) = action.secondaryToken.call(action.callData);
                // require(success, "ChronoForge: Custom action failed");
                // Effects on vault balances would depend on the custom interaction.
            }
        }

        strategy.lastExecutedBlock = block.number;
        userKarma[_msgSender()] = userKarma[_msgSender()].add(20); // Reward for successful execution trigger
        emit StrategyStepExecuted(_vaultId, _strategyId, strategy.conditions[0].oracleKey, latestOracleData[strategy.conditions[0].oracleKey].value);
    }

    /**
     * @dev Allows vault managers or owners to update specific parameters of a strategy within their vault.
     *      Only callable by `VAULT_MANAGER_ROLE` or the vault's owner.
     * @param _vaultId The ID of the target vault.
     * @param _strategyId The ID of the strategy to update.
     * @param _newExecutionFrequency The new minimum blocks between executions.
     * @param _newConditions New set of conditions to replace old ones (optional, empty array to keep current).
     * @param _newActions New set of actions to replace old ones (optional, empty array to keep current).
     */
    function updateStrategyVaultParameters(
        uint256 _vaultId,
        uint256 _strategyId,
        uint256 _newExecutionFrequency,
        StrategyCondition[] memory _newConditions,
        StrategyAction[] memory _newActions
    ) external onlyVaultManagerOrOwner(_vaultId) onlyActiveStrategyInVault(_vaultId, _strategyId) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.strategyId != 0, "ChronoForge: Strategy does not exist");

        strategy.executionFrequency = _newExecutionFrequency;

        if (_newConditions.length > 0) {
            strategy.conditions = _newConditions;
        }
        if (_newActions.length > 0) {
            strategy.actions = _newActions;
        }

        emit StrategyVaultParametersUpdated(_vaultId, _strategyId);
    }

    /* ========== IV. KARMA & REPUTATION SYSTEM ========== */

    /**
     * @dev Allows users to challenge the correctness or profitability of a strategy's execution or submitted oracle data.
     *      This is a simplified challenge system for the demo. A real system might involve staking challenger bonds
     *      and a more complex evidence submission process.
     * @param _entityType A bytes32 string indicating what is being challenged (e.g., `keccak256("STRATEGY_EXECUTION")`, `keccak256("ORACLE_DATA")`).
     * @param _entityId The ID of the specific strategy, oracle data point, or other entity being challenged.
     * @param _description A detailed description of the challenge, explaining why it's being made.
     * @return challengeId The ID of the newly submitted challenge.
     */
    function challengeStrategyExecution(bytes32 _entityType, uint256 _entityId, string memory _description) external returns (uint256) {
        require(bytes(_description).length > 0, "ChronoForge: Challenge description cannot be empty");
        // Further validation based on _entityType and _entityId could be added here
        // E.g., for "STRATEGY_EXECUTION", check if strategy exists and was executed recently.

        uint256 currentChallengeId = nextChallengeId++;
        challengeEntityType[currentChallengeId] = _entityType;
        challengeEntityId[currentChallengeId] = _entityId;
        challengeChallenger[currentChallengeId] = _msgSender();
        challengeResolved[currentChallengeId] = false;

        emit ChallengeSubmitted(currentChallengeId, _entityType, _entityId, _msgSender(), _description);
        return currentChallengeId;
    }

    /**
     * @dev Resolves a challenge, updating Karma for participants based on the outcome.
     *      Only callable by addresses with `DISPUTE_RESOLVER_ROLE`.
     *      This is a simplified resolution; a real system might involve a decentralized court or DAO vote.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _successForChallenger True if the challenger's claim is deemed valid, false otherwise.
     */
    function resolveChallenge(uint256 _challengeId, bool _successForChallenger) external onlyRole(DISPUTE_RESOLVER_ROLE) {
        require(challengeEntityType[_challengeId] != bytes32(0), "ChronoForge: Challenge does not exist");
        require(!challengeResolved[_challengeId], "ChronoForge: Challenge already resolved");

        address challenger = challengeChallenger[_challengeId];
        uint256 oldKarmaChallenger = userKarma[challenger];

        if (_successForChallenger) {
            userKarma[challenger] = userKarma[challenger].add(100); // Reward for an accurate challenge
            // In a more complex system, the "challenged party" (e.g., strategy proposer, oracle provider)
            // would be penalized here, e.g., userKarma[challengedParty] = userKarma[challengedParty].sub(someAmount);
        } else {
            // Penalize challenger for an incorrect or frivolous challenge
            if (userKarma[challenger] >= 50) { // Prevent underflow
                userKarma[challenger] = userKarma[challenger].sub(50);
            } else {
                userKarma[challenger] = 0;
            }
        }
        emit KarmaUpdated(challenger, oldKarmaChallenger, userKarma[challenger]);

        challengeResolved[_challengeId] = true;
        emit ChallengeResolved(_challengeId, _successForChallenger, _msgSender());
    }

    /**
     * @dev Retrieves the Karma score of a given address.
     * @param _user The address to query Karma for.
     * @return The current Karma score of the user.
     */
    function getUserKarma(address _user) external view returns (uint256) {
        return userKarma[_user];
    }

    /* ========== V. ORACLE & EXTERNAL DATA INTEGRATION ========== */

    /**
     * @dev Allows an address to register as a data oracle provider for a specific data key.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _oracleKey The unique identifier for the type of data (e.g., `keccak256("ETH_PRICE_CHAINLINK")`).
     * @param _provider The address to register as a provider for this key.
     */
    function registerOracleProvider(bytes32 _oracleKey, address _provider) external onlyRole(ADMIN_ROLE) {
        require(_provider != address(0), "ChronoForge: Invalid provider address");

        bool alreadyRegistered = false;
        for (uint256 i = 0; i < registeredOracleProviders[_oracleKey].length; i++) {
            if (registeredOracleProviders[_oracleKey][i] == _provider) {
                alreadyRegistered = true;
                break;
            }
        }
        require(!alreadyRegistered, "ChronoForge: Provider already registered for this key");

        registeredOracleProviders[_oracleKey].push(_provider);
        emit OracleProviderRegistered(_oracleKey, _provider);
    }

    /**
     * @dev Oracle providers submit data points. Submitted data is not immediately considered fully valid;
     *      it requires consensus from multiple providers or validation based on `oracleDataValidityThreshold`.
     *      Only callable by an address with `ORACLE_PROVIDER_ROLE` and registered for the `_oracleKey`.
     * @param _oracleKey The unique identifier for the data.
     * @param _value The data value to submit (e.g., price multiplied by 1e18 for precision).
     */
    function submitOracleData(bytes32 _oracleKey, uint256 _value) external onlyRole(ORACLE_PROVIDER_ROLE) {
        bool isRegistered = false;
        for (uint256 i = 0; i < registeredOracleProviders[_oracleKey].length; i++) {
            if (registeredOracleProviders[_oracleKey][i] == _msgSender()) {
                isRegistered = true;
                break;
            }
        }
        require(isRegistered, "ChronoForge: Caller is not a registered oracle provider for this key");

        OracleDataPoint memory newPoint = OracleDataPoint({
            key: _oracleKey,
            value: _value,
            timestamp: block.timestamp,
            provider: _msgSender(),
            validityScore: 1 // Each submission gets a base validity score
        });
        oracleDataHistory[_oracleKey].push(newPoint);

        _processOracleDataForValidity(_oracleKey); // Attempt to validate immediately based on recent submissions

        emit OracleDataSubmitted(_oracleKey, _msgSender(), _value, block.timestamp);
    }

    /**
     * @dev Internal function to process recently submitted oracle data and determine its validity.
     *      A simplified consensus mechanism is used for this demo (e.g., average of recent data points).
     *      In a real system, this would be more robust (e.g., median, outlier detection, time-weighted average).
     * @param _oracleKey The key of the oracle data to process.
     */
    function _processOracleDataForValidity(bytes32 _oracleKey) internal {
        // Minimum number of data points required to start validation process.
        uint256 minDataPoints = 3; 
        if (oracleDataHistory[_oracleKey].length < minDataPoints) {
            return; // Not enough data points for consensus yet
        }

        uint256 sum = 0;
        uint256 count = 0;
        // Consider only the latest few data points (e.g., up to last 10) for consensus
        uint256 startIndex = oracleDataHistory[_oracleKey].length > 10 ? oracleDataHistory[_oracleKey].length - 10 : 0;
        for (uint256 i = startIndex; i < oracleDataHistory[_oracleKey].length; i++) {
            sum = sum.add(oracleDataHistory[_oracleKey][i].value);
            count++;
        }

        if (count > 0) {
            uint256 averageValue = sum.div(count);
            OracleDataPoint storage latestSubmitted = oracleDataHistory[_oracleKey][oracleDataHistory[_oracleKey].length - 1];

            // Simple check: if the latest submitted value is within 2% of the average of recent values,
            // and the submission itself is recent (e.g., within the last 10 blocks), consider it validated.
            // This is a basic heuristic for a demo.
            uint256 deviation = latestSubmitted.value > averageValue ? latestSubmitted.value.sub(averageValue) : averageValue.sub(latestSubmitted.value);
            if (averageValue > 0 && deviation.mul(10000).div(averageValue) <= 200) { // 200 = 2%
                latestOracleData[_oracleKey] = latestSubmitted;
                latestOracleData[_oracleKey].validityScore = count; // Simplified: score is number of data points considered
                emit OracleDataValidated(_oracleKey, latestOracleData[_oracleKey].value, latestOracleData[_oracleKey].timestamp);
            }
        }
    }

    /**
     * @dev Sets the minimum consensus (validity score) needed for oracle data to be considered valid
     *      for strategies that depend on that specific oracle key.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _oracleKey The unique identifier for the data.
     * @param _threshold The minimum validity score required for data to be "trusted".
     */
    function setOracleDataValidityThreshold(bytes32 _oracleKey, uint256 _threshold) external onlyRole(ADMIN_ROLE) {
        oracleDataValidityThreshold[_oracleKey] = _threshold;
    }

    /**
     * @dev Removes an oracle provider for a specific key, typically due to inaccuracy or malicious activity.
     *      This also penalizes the revoked provider's Karma.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _oracleKey The oracle key for which the provider is registered.
     * @param _provider The address of the provider to revoke.
     */
    function revokeOracleProvider(bytes32 _oracleKey, address _provider) external onlyRole(ADMIN_ROLE) {
        address[] storage providers = registeredOracleProviders[_oracleKey];
        bool found = false;
        for (uint256 i = 0; i < providers.length; i++) {
            if (providers[i] == _provider) {
                providers[i] = providers[providers.length - 1]; // Swap with last element
                providers.pop(); // Remove last element
                found = true;
                break;
            }
        }
        require(found, "ChronoForge: Provider not found for this oracle key");
        emit OracleProviderRevoked(_oracleKey, _provider);

        // Penalize the revoked oracle provider's Karma (e.g., halve their score)
        userKarma[_provider] = userKarma[_provider].div(2);
        emit KarmaUpdated(_provider, userKarma[_provider].mul(2), userKarma[_provider]); // Emit old and new Karma
    }

    /* ========== VI. EVOLUTIONARY FUND & GOVERNANCE ========== */

    /**
     * @dev Proposes an allocation of funds from the Evolutionary Fund for research, development, or grants.
     *      Anyone can propose, but Karma holders vote for approval.
     * @param _amount The amount of funds (in native token, e.g., Wei) to allocate.
     * @param _recipient The address designated to receive the funds.
     * @param _description A detailed description of why the funds should be allocated.
     * @return proposalId The ID of the newly created fund allocation proposal.
     */
    function proposeEvolutionaryFundAllocation(uint256 _amount, address _recipient, string memory _description) external returns (uint256) {
        require(_amount > 0, "ChronoForge: Amount must be greater than zero");
        require(_recipient != address(0), "ChronoForge: Invalid recipient address");
        require(bytes(_description).length > 0, "ChronoForge: Description cannot be empty");
        require(evolutionaryFundBalance >= _amount, "ChronoForge: Insufficient funds in Evolutionary Fund");

        uint256 currentProposalId = nextFundProposalId++;
        fundProposals[currentProposalId] = FundAllocationProposal({
            proposalId: currentProposalId,
            proposer: _msgSender(),
            amount: _amount,
            recipient: _recipient,
            description: _description,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false
        });

        emit EvolutionaryFundAllocationProposed(currentProposalId, _msgSender(), _amount, _recipient, _description);
        return currentProposalId;
    }

    /**
     * @dev Allows Karma holders to vote on proposed allocations from the Evolutionary Fund.
     *      A minimum Karma score (e.g., 50) is required to vote. Votes are Karma-weighted.
     * @param _proposalId The ID of the fund allocation proposal.
     * @param _approve True to vote in favor, false to vote against the proposal.
     */
    function voteOnFundAllocation(uint256 _proposalId, bool _approve) external hasSufficientKarma(_msgSender(), 50) {
        FundAllocationProposal storage proposal = fundProposals[_proposalId];
        require(proposal.proposalId != 0, "ChronoForge: Proposal does not exist");
        require(!proposal.executed, "ChronoForge: Proposal already executed or rejected");
        require(!hasVotedOnFundAllocation[_proposalId][_msgSender()], "ChronoForge: Already voted on this proposal");

        uint256 voterKarma = userKarma[_msgSender()];
        if (_approve) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterKarma); // Karma-weighted vote
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterKarma);
        }
        hasVotedOnFundAllocation[_proposalId][_msgSender()] = true;
        emit EvolutionaryFundAllocationVoted(_proposalId, _msgSender(), _approve);
    }

    /**
     * @dev Distributes funds from the Evolutionary Fund to an approved recipient after a successful Karma-weighted vote.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _proposalId The ID of the fund allocation proposal.
     */
    function distributeEvolutionaryFund(uint256 _proposalId) external onlyRole(ADMIN_ROLE) nonReentrant {
        FundAllocationProposal storage proposal = fundProposals[_proposalId];
        require(proposal.proposalId != 0, "ChronoForge: Proposal does not exist");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "ChronoForge: Proposal not approved by majority Karma votes");
        require(evolutionaryFundBalance >= proposal.amount, "ChronoForge: Insufficient funds in Evolutionary Fund for distribution");

        evolutionaryFundBalance = evolutionaryFundBalance.sub(proposal.amount);
        // This assumes the Evolutionary Fund primarily holds native token (ETH).
        // If it holds ERC20s, a separate ERC20 transfer mechanism would be needed.
        (bool sent, ) = proposal.recipient.call{value: proposal.amount}("");
        require(sent, "ChronoForge: Failed to send funds to recipient");

        proposal.executed = true;
        emit EvolutionaryFundDistributed(_proposalId, proposal.recipient, proposal.amount);
    }

    /**
     * @dev Placeholder for protocol upgrade functionality.
     *      In a real system, this would interact with a UUPS proxy to upgrade the implementation contract.
     *      Only callable by an address with `ADMIN_ROLE`.
     * @param _newImplementation The address of the new implementation contract.
     */
    function upgradeProtocolImplementation(address _newImplementation) external onlyRole(ADMIN_ROLE) {
        require(_newImplementation != address(0), "ChronoForge: Invalid implementation address");
        // In a UUPS proxy setup, this function would call `_upgradeTo(_newImplementation)`.
        // For this base contract demo, it just emits an event.
        emit ProtocolUpgraded(_newImplementation);
    }

    /* ========== INTERNAL & HELPER FUNCTIONS ========== */

    /**
     * @dev Collects protocol fees from a given amount and adds them to the Evolutionary Fund.
     * @param _amount The base amount from which to take a fee.
     * @return The amount remaining after fees have been deducted.
     */
    function _collectProtocolFee(uint256 _amount) internal returns (uint256) {
        if (protocolFeePercentage == 0 || _amount == 0) {
            return _amount;
        }
        uint256 fee = _amount.mul(protocolFeePercentage).div(10000); // 10000 for 100%
        evolutionaryFundBalance = evolutionaryFundBalance.add(fee);
        // A portion might also be sent to `protocolFeeRecipient` based on a split logic.
        // For simplicity, all fees currently fuel the Evolutionary Fund.
        return _amount.sub(fee);
    }

    // Fallback and Receive functions for native token handling
    // Any native tokens sent directly to this contract are added to the Evolutionary Fund.
    receive() external payable {
        evolutionaryFundBalance = evolutionaryFundBalance.add(msg.value);
    }

    fallback() external payable {
        evolutionaryFundBalance = evolutionaryFundBalance.add(msg.value);
    }
}

```