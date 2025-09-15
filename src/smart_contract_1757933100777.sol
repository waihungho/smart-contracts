This smart contract, named `Dynapool`, is designed to manage Protocol-Owned Liquidity (POL) through a system of modular, external investment strategies, controlled by a Decentralized Autonomous Organization (DAO). It incorporates advanced concepts such as dynamic strategy allocation, NFT-gated strategist roles, an internal risk parameter framework, and orchestrated flash loan capabilities for strategies.

---

## Dynapool: Dynamic Protocol-Owned Liquidity & Strategy Vault

### Outline and Function Summary

**I. Core Vault & Asset Management**
1.  **`deposit(IERC20 _token, uint256 _amount)`**
    *   **Summary:** Allows users to deposit ERC20 tokens into the main Dynapool vault, contributing to the Protocol-Owned Liquidity.
2.  **`withdraw(IERC20 _token, uint256 _amount)`**
    *   **Summary:** Enables users to withdraw their previously deposited ERC20 tokens from the main vault, subject to a protocol-defined cooldown period for security.
3.  **`requestAssetWithdrawal(address _strategy, IERC20 _token, uint256 _amount)`**
    *   **Summary:** Initiates a DAO-approved request to pull a specific amount of tokens from an active strategy back into the main Dynapool vault. This signals the strategist to perform the actual transfer.
4.  **`executeAssetWithdrawal(address _strategy, IERC20 _token, uint256 _amount)`**
    *   **Summary:** Allows a whitelisted strategist to execute a DAO-requested withdrawal, transferring assets from their managed strategy back to the Dynapool main vault.
5.  **`getVaultBalance(IERC20 _token) view`**
    *   **Summary:** Returns the current balance of a specified ERC20 token held directly within the Dynapool's main vault (unallocated to strategies).
6.  **`getStrategyBalance(address _strategy, IERC20 _token) view`**
    *   **Summary:** Queries an active strategy to get the current balance of a specific ERC20 token it currently manages.
7.  **`getProtocolTotalValueLocked(IERC20 _token) view`**
    *   **Summary:** Calculates the aggregate sum of a given token's balance across the main Dynapool vault and all active strategies, providing the total TVL for that token.

**II. Strategy Management & Execution**
8.  **`proposeStrategy(string calldata _name, address _strategyAddress, string calldata _descriptionURI, uint256 _maxAllocationCap)`**
    *   **Summary:** Allows whitelisted "Strategist Candidates" to propose new, modular investment strategies (implemented as external `IStrategy` contracts) for DAO review and approval.
9.  **`voteForStrategy(uint256 _proposalId, bool _support)`**
    *   **Summary:** Enables "DAO Voters" to cast their vote (for or against) on an active strategy proposal, contributing to the governance process.
10. **`finalizeStrategyProposal(uint256 _proposalId)`**
    *   **Summary:** An "Admin" role can finalize a strategy proposal after its voting period ends, activating the strategy if it receives sufficient votes.
11. **`allocateFundsToStrategy(address _strategy, IERC20 _token, uint256 _amount)`**
    *   **Summary:** Allows the DAO (via an "Admin" role) to transfer a specified amount of tokens from the main vault to an active, approved strategy for execution.
12. **`deactivateStrategy(address _strategy)`**
    *   **Summary:** Enables the DAO to deactivate an active strategy, preventing further fund allocations and initiating the process for fund recall.
13. **`updateStrategyMaxAllocation(address _strategy, uint256 _newCap)`**
    *   **Summary:** Allows the DAO to adjust the maximum USD value of capital an active strategy is permitted to manage.
14. **`executeStrategyOperation(address _strategy, bytes calldata _callData)`**
    *   **Summary:** A generic, powerful function that allows a strategist to trigger arbitrary, approved operations within their managed strategy contract, using the funds allocated by Dynapool. This enables diverse strategy actions like swaps, lending, etc.

**III. Risk Management & Oracles**
15. **`setPriceOracle(IERC20 _token, IPriceOracle _oracle)`**
    *   **Summary:** Enables the DAO to set or update the trusted price oracle for a specific ERC20 token, crucial for accurate USD value calculations within the protocol.
16. **`getAssetValueUSD(IERC20 _token, uint256 _amount) view`**
    *   **Summary:** Calculates and returns the current USD value of a given amount of an ERC20 token, utilizing its configured price oracle.
17. **`setRiskParameter(bytes32 _paramName, uint256 _value)`**
    *   **Summary:** Allows the "Risk Manager" role to configure system-wide risk parameters (e.g., maximum TVL allowed for a single strategy, maximum slippage tolerance).
18. **`getStrategyEffectiveRiskScore(address _strategy) view`**
    *   **Summary:** A conceptual function that delegates to the strategy contract to retrieve its self-assessed risk score, allowing for potential future integration with dynamic on-chain risk models.

**IV. Governance & Roles**
19. **`setDaoRole(address _account, bytes32 _role, bool _active)`**
    *   **Summary:** The "Admin" role can assign or revoke specific governance-related roles (e.g., `DAO_VOTER_ROLE`, `STRATEGIST_CANDIDATE_ROLE`, `RISK_MANAGER_ROLE`) to individual addresses.
20. **`grantStrategistNFT(address _account, uint256 _level)`**
    *   **Summary:** Allows the DAO (via an "Admin" role) to mint a unique NFT (from an external ERC721 contract) to a successful strategist, recognizing their contribution and potentially unlocking enhanced privileges.
21. **`setStrategistNFTContract(address _nftContract)`**
    *   **Summary:** Sets the address of the external ERC721 contract that will be used for minting strategist NFTs.
22. **`setWithdrawalCooldown(uint256 _cooldownDuration)`**
    *   **Summary:** The DAO sets a mandatory cooldown period (in seconds) that users must observe between withdrawals, enhancing fund security.
23. **`emergencyPause()`**
    *   **Summary:** An "Admin" role can instantly pause critical fund movement operations across the protocol in response to an emergency or security threat.
24. **`resume()`**
    *   **Summary:** An "Admin" role can unpause the protocol, resuming all operations after an emergency pause.

**V. Rewards & Incentives**
25. **`distributePerformanceFees(address _strategy)`**
    *   **Summary:** A conceptual function to trigger the calculation and transfer of performance fees from a strategy's realized profits to the Dynapool treasury. Actual profit tracking and distribution logic would reside in a more complex accounting module.
26. **`claimStrategistReward(address _strategy)`**
    *   **Summary:** A conceptual function allowing strategists to claim their earned rewards, after performance fees, based on their strategy's net performance.
27. **`setPerformanceFee(uint256 _feeBasisPoints)`**
    *   **Summary:** The DAO can set the percentage of performance fees (in basis points) that will be collected from profitable strategies.

**VI. Advanced Flash Loan/Rebalancing**
28. **`initiateFlashArbitrage(address _strategy, IERC20 _borrowToken, uint256 _amount, bytes calldata _callData)`**
    *   **Summary:** Allows an approved strategy to initiate complex flash loan operations (e.g., for arbitrage, liquidations, or rebalancing) by orchestrating the call through Dynapool. The strategy itself must implement the flash loan provider interaction and callback logic.

**VII. External Protocol Whitelisting & Audit Tracking**
29. **`whitelistExternalProtocol(address _protocolAddress, bool _isWhitelisted)`**
    *   **Summary:** The DAO maintains a whitelist of approved external DeFi protocols that strategies are permitted to interact with, acting as a crucial security gate.
30. **`recordStrategyAudit(address _strategyAddress, string calldata _auditURI)`**
    *   **Summary:** Allows a "Risk Manager" or DAO to record a URI (e.g., IPFS hash) linking to an external audit report for a specific strategy, enhancing transparency and trust.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Interfaces ---

/// @title IPriceOracle
/// @dev Interface for a price oracle (e.g., Chainlink) to fetch token prices in USD.
interface IPriceOracle {
    /// @dev Returns the latest price of a token.
    /// @param token The address of the token.
    /// @return price The price of the token in USD, typically multiplied by 10^8 (8 decimals).
    function getLatestPrice(address token) external view returns (uint256 price);
}

/// @title IStrategy
/// @dev Interface that all external strategy contracts must implement to integrate with Dynapool.
interface IStrategy {
    /// @dev Allows Dynapool to deposit funds into the strategy.
    ///      The strategy must accept and manage these funds.
    function depositFunds(IERC20 token, uint256 amount) external;

    /// @dev Allows Dynapool to withdraw funds from the strategy.
    ///      The strategy must release the specified funds back to Dynapool.
    function withdrawFunds(IERC20 token, uint256 amount) external;

    /// @dev A generic function for Dynapool to trigger a strategy-specific operation.
    ///      This allows flexibility for strategies to perform various DeFi interactions.
    ///      The strategy itself must handle `_data` decoding and access control.
    function executeOperation(bytes calldata _data) external returns (bytes memory);

    /// @dev Returns the current balance of a token held within this strategy.
    function getStrategyHoldings(IERC20 token) external view returns (uint256);

    /// @dev Returns the strategy's self-assessed risk score (e.g., 0-100).
    ///      This can be a static value or dynamically calculated by the strategy.
    function getRiskScore() external view returns (uint256);
}

/// @title IERC721NFT
/// @dev Simplified interface for an external ERC721 NFT contract for granting strategist NFTs.
interface IERC721NFT {
    /// @dev Mints an NFT to a recipient with a specific token ID.
    function mint(address to, uint256 tokenId) external;
}


/// @title Dynapool - Dynamic Protocol-Owned Liquidity & Strategy Vault
/// @dev Dynapool is a sophisticated smart contract designed for a Decentralized Autonomous Organization (DAO)
///      to manage Protocol-Owned Liquidity (POL) through a system of external, modular investment strategies.
///      It enables governance-controlled asset allocation, risk management, and strategist incentives.
contract Dynapool is AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Outline and Function Summary ---

    // I. Core Vault & Asset Management
    // 1.  deposit(IERC20 _token, uint256 _amount)
    //     - Allows users to deposit ERC20 tokens into the main Dynapool vault.
    // 2.  withdraw(IERC20 _token, uint256 _amount)
    //     - Allows users to withdraw their deposited ERC20 tokens from the main vault, subject to cooldown.
    // 3.  requestAssetWithdrawal(address _strategy, IERC20 _token, uint256 _amount)
    //     - DAO initiates a request to pull funds from an active strategy back to the main Dynapool vault.
    // 4.  executeAssetWithdrawal(address _strategy, IERC20 _token, uint256 _amount)
    //     - A strategist executes a DAO-approved withdrawal, moving assets from their strategy back to the main vault.
    // 5.  getVaultBalance(IERC20 _token) view
    //     - Returns the total balance of a specific token held directly in the main Dynapool vault.
    // 6.  getStrategyBalance(address _strategy, IERC20 _token) view
    //     - Returns the balance of a specific token currently managed by a given strategy.
    // 7.  getProtocolTotalValueLocked(IERC20 _token) view
    //     - Calculates the sum of all balances of a token across the main vault and all active strategies.

    // II. Strategy Management & Execution
    // 8.  proposeStrategy(string calldata _name, address _strategyAddress, string calldata _descriptionURI, uint256 _maxAllocationCap)
    //     - Allows a whitelisted Strategist Candidate to propose a new investment strategy to the DAO.
    // 9.  voteForStrategy(uint256 _proposalId, bool _support)
    //     - Allows DAO members to vote on active strategy proposals.
    // 10. finalizeStrategyProposal(uint256 _proposalId)
    //     - Admin role finalizes a strategy proposal, activating it if it passes governance.
    // 11. allocateFundsToStrategy(address _strategy, IERC20 _token, uint256 _amount)
    //     - DAO allocates funds from the main vault to an active, approved strategy.
    // 12. deactivateStrategy(address _strategy)
    //     - DAO deactivates an active strategy, preventing further fund allocation and initiating fund recall.
    // 13. updateStrategyMaxAllocation(address _strategy, uint256 _newCap)
    //     - DAO updates the maximum capital an active strategy is permitted to manage.
    // 14. executeStrategyOperation(address _strategy, bytes calldata _callData)
    //     - Allows a strategist to trigger a specific operation within their managed strategy contract, using allocated funds.

    // III. Risk Management & Oracles
    // 15. setPriceOracle(IERC20 _token, IPriceOracle _oracle)
    //     - DAO sets or updates the price oracle for a specific ERC20 token for USD value calculations.
    // 16. getAssetValueUSD(IERC20 _token, uint256 _amount) view
    //     - Returns the USD value of a given amount of an ERC20 token using its configured oracle.
    // 17. setRiskParameter(bytes32 _paramName, uint256 _value)
    //     - DAO sets system-wide risk parameters (e.g., maximum TVL per strategy, max slippage tolerance).
    // 18. getStrategyEffectiveRiskScore(address _strategy) view
    //     - A conceptual function to retrieve/calculate a dynamic risk score for a strategy, potentially integrating with future AI/ML or on-chain analytics.

    // IV. Governance & Roles
    // 19. setDaoRole(address _account, bytes32 _role, bool _active)
    //     - DAO assigns or revokes specific roles (e.g., VOTER, STRATEGIST_CANDIDATE, RISK_MANAGER) to addresses.
    // 20. grantStrategistNFT(address _account, uint256 _level)
    //     - DAO can mint an NFT (from an external ERC721 contract) to a successful strategist, signifying their achievement and potentially granting boosted privileges.
    // 21. setStrategistNFTContract(address _nftContract)
    //     - Sets the address of the external ERC721 contract used for strategist NFTs.
    // 22. setWithdrawalCooldown(uint256 _cooldownDuration)
    //     - DAO sets a cooldown period required between user withdrawals to enhance security against rapid draining.
    // 23. emergencyPause()
    //     - Pauses critical fund movement operations in case of an emergency.
    // 24. resume()
    //     - Resumes operations after an emergency pause.

    // V. Rewards & Incentives
    // 25. distributePerformanceFees(address _strategy)
    //     - Allows a strategist or DAO to trigger the calculation and transfer of performance fees from a strategy's realized profits to the Dynapool treasury.
    // 26. claimStrategistReward(address _strategy)
    //     - Allows a strategist to claim their share of rewards after performance fees have been taken.
    // 27. setPerformanceFee(uint256 _feeBasisPoints)
    //     - Sets the performance fee percentage in basis points (e.g., 100 for 1%).

    // VI. Advanced Flash Loan/Rebalancing
    // 28. initiateFlashArbitrage(address _strategy, IERC20 _borrowToken, uint256 _amount, bytes calldata _callData)
    //     - Allows an approved strategy to initiate a flash loan for arbitrage or rebalancing purposes. The actual flash loan execution and callback handling must be within the strategy contract. Dynapool here acts as an orchestrator.

    // VII. External Protocol Whitelisting & Audit Tracking
    // 29. whitelistExternalProtocol(address _protocolAddress, bool _isWhitelisted)
    //     - DAO whitelists external DeFi protocols that active strategies are permitted to interact with, enhancing security.
    // 30. recordStrategyAudit(address _strategyAddress, string calldata _auditURI)
    //     - DAO or a RISK_MANAGER can record the URI of an audit report for a specific strategy, improving transparency.

    // --- State Variables ---

    // Roles for AccessControl
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Manages core protocol settings, finalizes proposals
    bytes32 public constant STRATEGIST_CANDIDATE_ROLE = keccak256("STRATEGIST_CANDIDATE_ROLE"); // Can propose and execute strategy ops
    bytes32 public constant DAO_VOTER_ROLE = keccak256("DAO_VOTER_ROLE"); // Can vote on proposals
    bytes32 public constant RISK_MANAGER_ROLE = keccak256("RISK_MANAGER_ROLE"); // Can set risk parameters, record audits

    // Vault Balances (main vault, not allocated to strategies)
    mapping(address => uint256) public tokenBalances; // token address => balance

    // Strategy Management
    struct StrategyProposal {
        string name;
        address strategyAddress; // Address of the external IStrategy contract
        string descriptionURI; // IPFS hash or URL to detailed strategy description
        uint256 maxAllocationCap; // Max capital this strategy can manage (in USD)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 expirationTime;
        bool finalized;
        bool approved;
        EnumerableSet.AddressSet voters; // To prevent double voting
    }

    struct StrategyInfo {
        string name;
        address strategyAddress;
        string descriptionURI;
        uint256 maxAllocationCap; // Max capital this strategy can manage (in USD)
        bool isActive;
        mapping(address => uint256) allocatedFunds; // token address => amount allocated by Dynapool
        uint256 totalAllocatedUSD; // Total USD value currently allocated to this strategy, updated on allocation
        string auditURI; // URI to strategy audit report
    }

    mapping(uint256 => StrategyProposal) public strategyProposals;
    uint256 public nextProposalId;
    mapping(address => StrategyInfo) public activeStrategies; // strategyAddress => StrategyInfo
    EnumerableSet.AddressSet private _activeStrategyAddresses; // Set of all active strategy addresses

    // Risk Management & Oracles
    mapping(address => IPriceOracle) public priceOracles; // token address => IPriceOracle
    mapping(bytes32 => uint256) public riskParameters; // E.g., "PROPOSAL_VOTING_PERIOD", "MAX_SLIPPAGE_BPS"

    // Governance & Cooldowns
    uint256 public withdrawalCooldown; // Seconds
    mapping(address => uint256) public lastWithdrawalTime; // user => timestamp of last withdrawal

    // Rewards
    uint256 public performanceFeeBasisPoints; // Basis points (e.g., 100 for 1%)
    address public strategistNFTContract; // Address of the external ERC721 contract for strategist NFTs

    // Whitelisted External Protocols
    mapping(address => bool) public whitelistedExternalProtocols; // Address of external DeFi protocol => isWhitelisted

    // Events
    event Deposited(address indexed user, IERC20 indexed token, uint256 amount);
    event Withdrawn(address indexed user, IERC20 indexed token, uint256 amount);
    event StrategyProposed(uint256 indexed proposalId, address indexed proposer, string name, address strategyAddress);
    event StrategyVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event StrategyFinalized(uint256 indexed proposalId, address indexed strategyAddress, bool approved);
    event FundsAllocatedToStrategy(address indexed strategy, IERC20 indexed token, uint256 amount);
    event FundsRequestedFromStrategy(address indexed strategy, IERC20 indexed token, uint256 amount);
    event FundsWithdrawnFromStrategy(address indexed strategy, IERC20 indexed token, uint256 amount);
    event StrategyDeactivated(address indexed strategyAddress);
    event StrategyMaxAllocationUpdated(address indexed strategyAddress, uint256 newCap);
    event StrategyOperationExecuted(address indexed strategy, bytes callData);
    event PriceOracleSet(IERC20 indexed token, address indexed oracleAddress);
    event RiskParameterSet(bytes32 indexed paramName, uint256 value);
    event StrategistNFTGranted(address indexed strategist, uint256 level);
    event StrategistNFTContractSet(address indexed nftContract);
    event WithdrawalCooldownSet(uint256 duration);
    event PerformanceFeeDistributed(address indexed strategy, uint256 feeAmount);
    event StrategistRewardClaimed(address indexed strategist, address indexed strategy, uint256 rewardAmount);
    event PerformanceFeeSet(uint256 feeBasisPoints);
    event FlashArbitrageInitiated(address indexed strategy, IERC20 indexed borrowToken, uint256 amount);
    event ExternalProtocolWhitelisted(address indexed protocol, bool isWhitelisted);
    event StrategyAuditRecorded(address indexed strategy, string auditURI);

    // --- Constructor ---

    /// @dev Initializes the Dynapool contract with initial admin, voting period, withdrawal cooldown, and performance fee.
    /// @param _admin The initial address granted the ADMIN_ROLE and DEFAULT_ADMIN_ROLE.
    /// @param _proposalVotingPeriodSeconds Default duration for strategy proposal voting.
    /// @param _defaultWithdrawalCooldown Default cooldown period for user withdrawals.
    /// @param _defaultPerformanceFeeBasisPoints Default performance fee in basis points.
    constructor(
        address _admin,
        uint256 _proposalVotingPeriodSeconds,
        uint256 _defaultWithdrawalCooldown,
        uint256 _defaultPerformanceFeeBasisPoints
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin); // OpenZeppelin's default admin role for role management
        _grantRole(ADMIN_ROLE, _admin); // Custom admin role for specific Dynapool operations

        riskParameters["PROPOSAL_VOTING_PERIOD"] = _proposalVotingPeriodSeconds;
        withdrawalCooldown = _defaultWithdrawalCooldown;
        performanceFeeBasisPoints = _defaultPerformanceFeeBasisPoints;
    }

    // --- Modifiers ---

    modifier onlyStrategistCandidate() {
        require(hasRole(STRATEGIST_CANDIDATE_ROLE, _msgSender()), "Dynapool: Not a strategist candidate");
        _;
    }

    modifier onlyDaoVoter() {
        require(hasRole(DAO_VOTER_ROLE, _msgSender()), "Dynapool: Not a DAO voter");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Dynapool: Not an admin");
        _;
    }

    modifier onlyRiskManager() {
        require(hasRole(RISK_MANAGER_ROLE, _msgSender()), "Dynapool: Not a risk manager");
        _;
    }

    // --- I. Core Vault & Asset Management ---

    /**
     * @dev Allows users to deposit ERC20 tokens into the main Dynapool vault.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function deposit(IERC20 _token, uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Dynapool: Deposit amount must be greater than zero");
        _token.safeTransferFrom(_msgSender(), address(this), _amount);
        tokenBalances[address(_token)] += _amount;
        emit Deposited(_msgSender(), _token, _amount);
    }

    /**
     * @dev Allows users to withdraw their deposited ERC20 tokens from the main vault.
     *      Subject to a withdrawal cooldown period.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(IERC20 _token, uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Dynapool: Withdraw amount must be greater than zero");
        require(tokenBalances[address(_token)] >= _amount, "Dynapool: Insufficient vault balance");
        require(block.timestamp >= lastWithdrawalTime[_msgSender()] + withdrawalCooldown, "Dynapool: Withdrawal cooldown active");

        tokenBalances[address(_token)] -= _amount;
        _token.safeTransfer(_msgSender(), _amount);
        lastWithdrawalTime[_msgSender()] = block.timestamp;

        emit Withdrawn(_msgSender(), _token, _amount);
    }

    /**
     * @dev DAO initiates a request to pull funds from an active strategy back to the main Dynapool vault.
     *      This marks the intent; the strategist needs to execute the actual transfer.
     * @param _strategy The address of the strategy to withdraw from.
     * @param _token The address of the ERC20 token to request for withdrawal.
     * @param _amount The amount of tokens to request.
     */
    function requestAssetWithdrawal(address _strategy, IERC20 _token, uint252 _amount) public onlyAdmin whenNotPaused {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        require(_amount > 0, "Dynapool: Withdrawal amount must be greater than zero");
        // In a more complex system, this would create a specific withdrawal request ID
        // and potentially reserve the funds within the strategy.
        emit FundsRequestedFromStrategy(_strategy, _token, _amount);
    }

    /**
     * @dev A strategist executes a DAO-approved withdrawal, moving assets from their strategy back to the main vault.
     *      This is called by the strategist after `requestAssetWithdrawal` has been made or as per DAO instruction.
     * @param _strategy The address of the strategy to withdraw from.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function executeAssetWithdrawal(address _strategy, IERC20 _token, uint256 _amount) public onlyStrategistCandidate whenNotPaused {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        require(_amount > 0, "Dynapool: Withdrawal amount must be greater than zero");
        require(IStrategy(_strategy).getStrategyHoldings(_token) >= _amount, "Dynapool: Strategy has insufficient funds");

        // The strategist calls their strategy contract to send funds back to Dynapool.
        IStrategy(_strategy).withdrawFunds(_token, _amount);

        // Update Dynapool's internal tracking
        // Note: totalAllocatedUSD is not reduced here; it represents initial allocation.
        // Actual strategy profits/losses affect getStrategyHoldings but not directly totalAllocatedUSD.
        activeStrategies[_strategy].allocatedFunds[address(_token)] -= _amount;
        tokenBalances[address(_token)] += _amount;

        emit FundsWithdrawnFromStrategy(_strategy, _token, _amount);
    }

    /**
     * @dev Returns the total balance of a specific token held directly in the main Dynapool vault.
     * @param _token The address of the ERC20 token.
     * @return The balance of the token in the main vault.
     */
    function getVaultBalance(IERC20 _token) public view returns (uint256) {
        return tokenBalances[address(_token)];
    }

    /**
     * @dev Returns the balance of a specific token currently managed by a given strategy.
     * @param _strategy The address of the strategy.
     * @param _token The address of the ERC20 token.
     * @return The balance of the token managed by the strategy.
     */
    function getStrategyBalance(address _strategy, IERC20 _token) public view returns (uint256) {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        return IStrategy(_strategy).getStrategyHoldings(_token);
    }

    /**
     * @dev Calculates the sum of all balances of a token across the main vault and all active strategies.
     * @param _token The address of the ERC20 token.
     * @return The total value locked for the given token across the protocol.
     */
    function getProtocolTotalValueLocked(IERC20 _token) public view returns (uint256) {
        uint256 total = tokenBalances[address(_token)];
        for (uint256 i = 0; i < _activeStrategyAddresses.length(); i++) {
            address strategyAddress = _activeStrategyAddresses.at(i);
            total += IStrategy(strategyAddress).getStrategyHoldings(_token);
        }
        return total;
    }


    // --- II. Strategy Management & Execution ---

    /**
     * @dev Allows a whitelisted Strategist Candidate to propose a new investment strategy to the DAO.
     * @param _name The human-readable name of the strategy.
     * @param _strategyAddress The address of the external IStrategy contract.
     * @param _descriptionURI IPFS hash or URL to detailed strategy description.
     * @param _maxAllocationCap Max capital this strategy can manage in USD.
     * @return The ID of the newly created proposal.
     */
    function proposeStrategy(
        string calldata _name,
        address _strategyAddress,
        string calldata _descriptionURI,
        uint256 _maxAllocationCap
    ) public onlyStrategistCandidate whenNotPaused returns (uint256) {
        require(_strategyAddress != address(0), "Dynapool: Invalid strategy address");
        require(!_activeStrategyAddresses.contains(_strategyAddress), "Dynapool: Strategy already exists or is active");
        // Additional checks: ensure _strategyAddress implements IStrategy interface (can be done off-chain or via try-catch if using 0.8.11+)
        // Ensure _strategyAddress is not already a pending proposal

        uint256 proposalId = nextProposalId++;
        strategyProposals[proposalId] = StrategyProposal({
            name: _name,
            strategyAddress: _strategyAddress,
            descriptionURI: _descriptionURI,
            maxAllocationCap: _maxAllocationCap,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            expirationTime: block.timestamp + riskParameters["PROPOSAL_VOTING_PERIOD"],
            finalized: false,
            approved: false,
            voters: EnumerableSet.AddressSet(0)
        });

        emit StrategyProposed(proposalId, _msgSender(), _name, _strategyAddress);
        return proposalId;
    }

    /**
     * @dev Allows DAO members to vote on active strategy proposals.
     * @param _proposalId The ID of the strategy proposal.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteForStrategy(uint256 _proposalId, bool _support) public onlyDaoVoter {
        StrategyProposal storage proposal = strategyProposals[_proposalId];
        require(proposal.strategyAddress != address(0), "Dynapool: Proposal does not exist");
        require(!proposal.finalized, "Dynapool: Proposal already finalized");
        require(block.timestamp < proposal.expirationTime, "Dynapool: Voting period has ended");
        require(!proposal.voters.contains(_msgSender()), "Dynapool: Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.voters.add(_msgSender());

        emit StrategyVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Admin role finalizes a strategy proposal, activating it if it passes governance.
     *      Assumes a simple majority vote. For full DAO, this would be a more complex module.
     * @param _proposalId The ID of the strategy proposal.
     */
    function finalizeStrategyProposal(uint256 _proposalId) public onlyAdmin {
        StrategyProposal storage proposal = strategyProposals[_proposalId];
        require(proposal.strategyAddress != address(0), "Dynapool: Proposal does not exist");
        require(!proposal.finalized, "Dynapool: Proposal already finalized");
        require(block.timestamp >= proposal.expirationTime, "Dynapool: Voting period not yet ended");

        proposal.finalized = true;
        if (proposal.votesFor > proposal.votesAgainst) { // Simple majority
            proposal.approved = true;
            _activeStrategyAddresses.add(proposal.strategyAddress);
            activeStrategies[proposal.strategyAddress] = StrategyInfo({
                name: proposal.name,
                strategyAddress: proposal.strategyAddress,
                descriptionURI: proposal.descriptionURI,
                maxAllocationCap: proposal.maxAllocationCap,
                isActive: true,
                totalAllocatedUSD: 0,
                auditURI: "" // Can be updated later via recordStrategyAudit
            });
        }

        emit StrategyFinalized(_proposalId, proposal.strategyAddress, proposal.approved);
    }

    /**
     * @dev DAO allocates funds from the main vault to an active, approved strategy.
     * @param _strategy The address of the active strategy.
     * @param _token The address of the ERC20 token to allocate.
     * @param _amount The amount of tokens to allocate.
     */
    function allocateFundsToStrategy(address _strategy, IERC20 _token, uint256 _amount) public onlyAdmin whenNotPaused {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        require(tokenBalances[address(_token)] >= _amount, "Dynapool: Insufficient vault balance for allocation");
        require(_amount > 0, "Dynapool: Allocation amount must be greater than zero");

        StrategyInfo storage strategyInfo = activeStrategies[_strategy];
        
        // Calculate the USD value of the allocation and check against max cap
        uint256 amountUSD = getAssetValueUSD(_token, _amount);
        require(strategyInfo.totalAllocatedUSD + amountUSD <= strategyInfo.maxAllocationCap, "Dynapool: Exceeds strategy max allocation cap");

        tokenBalances[address(_token)] -= _amount;
        _token.safeTransfer(address(_strategy), _amount); // Transfer funds to the strategy contract
        
        // Update Dynapool's internal tracking
        strategyInfo.allocatedFunds[address(_token)] += _amount;
        strategyInfo.totalAllocatedUSD += amountUSD;

        // Notify the strategy contract about the deposit
        IStrategy(_strategy).depositFunds(_token, _amount);

        emit FundsAllocatedToStrategy(_strategy, _token, _amount);
    }

    /**
     * @dev DAO deactivates an active strategy, preventing further fund allocation and initiating fund recall.
     * @param _strategy The address of the strategy to deactivate.
     */
    function deactivateStrategy(address _strategy) public onlyAdmin {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        
        StrategyInfo storage strategyInfo = activeStrategies[_strategy];
        strategyInfo.isActive = false;
        _activeStrategyAddresses.remove(_strategy);

        // Funds still remain in the strategy contract. An explicit DAO action (requestAssetWithdrawal)
        // or strategist action (executeAssetWithdrawal) would be needed to actually pull them back.
        emit StrategyDeactivated(_strategy);
    }

    /**
     * @dev DAO updates the maximum capital an active strategy is permitted to manage.
     * @param _strategy The address of the active strategy.
     * @param _newCap The new maximum allocation cap in USD.
     */
    function updateStrategyMaxAllocation(address _strategy, uint256 _newCap) public onlyAdmin {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        require(_newCap >= activeStrategies[_strategy].totalAllocatedUSD, "Dynapool: New cap must be greater than or equal to current allocated USD");
        
        activeStrategies[_strategy].maxAllocationCap = _newCap;
        emit StrategyMaxAllocationUpdated(_strategy, _newCap);
    }

    /**
     * @dev Allows a strategist to trigger a specific operation within their managed strategy contract,
     *      using allocated funds. This is a powerful, flexible function for strategies.
     *      The `_callData` must be crafted by the strategist to call a function on their `_strategy` contract.
     *      The strategy contract is responsible for its own safety and interaction with whitelisted protocols.
     * @param _strategy The address of the active strategy.
     * @param _callData The encoded function call data for the strategy contract.
     * @return The raw return data from the strategy's operation.
     */
    function executeStrategyOperation(address _strategy, bytes calldata _callData) public onlyStrategistCandidate whenNotPaused returns (bytes memory) {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        require(activeStrategies[_strategy].isActive, "Dynapool: Strategy is inactive");

        // Dynapool calls the strategy contract's `executeOperation`.
        // The strategy contract itself must ensure that only Dynapool can call its `executeOperation` function
        // and that it only interacts with whitelisted external protocols.
        (bool success, bytes memory result) = _strategy.call(abi.encodeWithSelector(IStrategy.executeOperation.selector, _callData));
        require(success, string(abi.decode(result, (string)))); // Revert with strategy's error message if operation failed

        emit StrategyOperationExecuted(_strategy, _callData);
        return result;
    }


    // --- III. Risk Management & Oracles ---

    /**
     * @dev DAO sets or updates the price oracle for a specific ERC20 token for USD value calculations.
     * @param _token The address of the ERC20 token.
     * @param _oracle The address of the IPriceOracle contract.
     */
    function setPriceOracle(IERC20 _token, IPriceOracle _oracle) public onlyAdmin {
        require(address(_oracle) != address(0), "Dynapool: Invalid oracle address");
        priceOracles[address(_token)] = _oracle;
        emit PriceOracleSet(_token, address(_oracle));
    }

    /**
     * @dev Returns the USD value of a given amount of an ERC20 token using its configured oracle.
     *      Assumes oracle returns price multiplied by 10^8 (e.g., Chainlink feeds).
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens.
     * @return The USD value of the token amount.
     */
    function getAssetValueUSD(IERC20 _token, uint256 _amount) public view returns (uint256) {
        IPriceOracle oracle = priceOracles[address(_token)];
        require(address(oracle) != address(0), "Dynapool: Price oracle not set for this token");

        uint256 price = oracle.getLatestPrice(address(_token)); // price in USD, 8 decimals
        uint256 decimals = IERC20(_token).decimals();

        // Calculate (amount * price) / (10^decimals * 10^8)
        // To prevent overflow with large numbers, handle division carefully.
        // Assumes that price is high enough relative to amount for reasonable precision.
        return (_amount * price) / (10 ** (decimals + 8));
    }

    /**
     * @dev DAO sets system-wide risk parameters (e.g., maximum TVL per strategy, max slippage tolerance).
     * @param _paramName The name of the risk parameter (e.g., "MAX_STRATEGY_TVL_BPS").
     * @param _value The value for the risk parameter.
     */
    function setRiskParameter(bytes32 _paramName, uint256 _value) public onlyRiskManager {
        riskParameters[_paramName] = _value;
        emit RiskParameterSet(_paramName, _value);
    }

    /**
     * @dev A conceptual function to retrieve/calculate a dynamic risk score for a strategy.
     *      In a more advanced version, this could integrate with an on-chain risk scoring model
     *      (e.g., based on historical performance, volatility, protocol interaction, security audits).
     *      For this example, it delegates to the strategy itself.
     * @param _strategy The address of the strategy.
     * @return The effective risk score of the strategy (e.g., 0-100).
     */
    function getStrategyEffectiveRiskScore(address _strategy) public view returns (uint256) {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        return IStrategy(_strategy).getRiskScore(); // Delegates to strategy's internal risk assessment
    }


    // --- IV. Governance & Roles ---

    /**
     * @dev DAO assigns or revokes specific roles (e.g., VOTER, STRATEGIST_CANDIDATE, RISK_MANAGER) to addresses.
     *      Uses OpenZeppelin's AccessControl.
     * @param _account The address to modify roles for.
     * @param _role The role (bytes32 hash) to assign/revoke.
     * @param _active True to grant the role, false to revoke.
     */
    function setDaoRole(address _account, bytes32 _role, bool _active) public onlyAdmin {
        if (_active) {
            _grantRole(_role, _account);
        } else {
            _revokeRole(_role, _account);
        }
    }

    /**
     * @dev DAO can mint an NFT (from an external ERC721 contract) to a successful strategist,
     *      signifying their achievement and potentially granting boosted privileges.
     *      Requires `strategistNFTContract` to be set.
     * @param _account The strategist's address.
     * @param _level The level/tier of the NFT to mint (used as tokenId).
     */
    function grantStrategistNFT(address _account, uint256 _level) public onlyAdmin {
        require(strategistNFTContract != address(0), "Dynapool: Strategist NFT contract not set");
        IERC721NFT(strategistNFTContract).mint(_account, _level); // Assuming mint takes address and tokenId/level
        emit StrategistNFTGranted(_account, _level);
    }
    
    /**
     * @dev Sets the address of the external ERC721 contract used for strategist NFTs.
     * @param _nftContract The address of the ERC721 NFT contract.
     */
    function setStrategistNFTContract(address _nftContract) public onlyAdmin {
        require(_nftContract != address(0), "Dynapool: NFT contract cannot be zero address");
        strategistNFTContract = _nftContract;
        emit StrategistNFTContractSet(_nftContract);
    }

    /**
     * @dev DAO sets a cooldown period required between user withdrawals to enhance security against rapid draining.
     * @param _cooldownDuration The new cooldown duration in seconds.
     */
    function setWithdrawalCooldown(uint252 _cooldownDuration) public onlyAdmin {
        withdrawalCooldown = _cooldownDuration;
        emit WithdrawalCooldownSet(_cooldownDuration);
    }

    /**
     * @dev Pauses critical fund movement operations in case of an emergency.
     *      Can only be called by an ADMIN_ROLE.
     */
    function emergencyPause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Resumes operations after an emergency pause.
     *      Can only be called by an ADMIN_ROLE.
     */
    function resume() public onlyAdmin {
        _unpause();
    }


    // --- V. Rewards & Incentives ---

    /**
     * @dev A conceptual function to trigger the calculation and transfer of performance fees
     *      from a strategy's realized profits to the Dynapool treasury.
     *      Actual implementation requires robust profit/loss tracking within strategies or a dedicated module.
     * @param _strategy The address of the strategy.
     */
    function distributePerformanceFees(address _strategy) public onlyAdmin {
        // Placeholder for complex profit/fee calculation logic.
        // In a real system:
        // 1. A strategy would report its net profits (e.g., by sending profit tokens to Dynapool).
        // 2. Dynapool would calculate (profit * performanceFeeBasisPoints / 10000).
        // 3. The fee would be transferred to a DAO treasury address.
        
        uint256 assumedProfit = 1000 ether; // Example placeholder value
        uint256 feeAmount = (assumedProfit * performanceFeeBasisPoints) / 10000;

        // For now, just emit an event.
        emit PerformanceFeeDistributed(_strategy, feeAmount);
    }

    /**
     * @dev A conceptual function allowing a strategist to claim their share of rewards after performance fees have been taken.
     *      Requires a sophisticated reward calculation system.
     * @param _strategy The address of the strategy.
     */
    function claimStrategistReward(address _strategy) public onlyStrategistCandidate {
        // Placeholder for complex reward calculation logic.
        // In a real system, this would calculate:
        // (net profit - performance fee) * strategistShare
        // And transfer actual tokens to _msgSender().
        
        uint256 strategistReward = 500 ether; // Example placeholder value
        // For now, simply emit an event.
        emit StrategistRewardClaimed(_msgSender(), _strategy, strategistReward);
    }

    /**
     * @dev Sets the performance fee percentage in basis points (e.g., 100 for 1%).
     * @param _feeBasisPoints The new performance fee in basis points.
     */
    function setPerformanceFee(uint256 _feeBasisPoints) public onlyAdmin {
        require(_feeBasisPoints <= 10000, "Dynapool: Fee basis points cannot exceed 10000 (100%)");
        performanceFeeBasisPoints = _feeBasisPoints;
        emit PerformanceFeeSet(_feeBasisPoints);
    }


    // --- VI. Advanced Flash Loan/Rebalancing ---

    /**
     * @dev Allows an approved strategy to initiate a flash loan for arbitrage or rebalancing purposes.
     *      Dynapool acts as an orchestrator, confirming the strategy's approval and passing the call.
     *      The actual flash loan execution and callback handling must be implemented within the strategy contract.
     * @param _strategy The address of the active strategy.
     * @param _borrowToken The address of the token to be conceptually borrowed via flash loan (for event logging).
     * @param _amount The amount of tokens to be conceptually borrowed (for event logging).
     * @param _callData The encoded function call data for the strategy to execute internally during the flash loan.
     */
    function initiateFlashArbitrage(
        address _strategy,
        IERC20 _borrowToken,
        uint256 _amount,
        bytes calldata _callData
    ) public onlyStrategistCandidate whenNotPaused {
        require(_activeStrategyAddresses.contains(_strategy), "Dynapool: Strategy is not active");
        require(activeStrategies[_strategy].isActive, "Dynapool: Strategy is inactive");
        
        // This function simply proxies the `_callData` to the strategy's `executeOperation`.
        // The strategy contract itself must be capable of calling a flash loan provider,
        // handling the callback (which usually means the provider calls the strategy back),
        // and performing the desired arbitrage/rebalancing within that callback.
        (bool success, bytes memory result) = _strategy.call(abi.encodeWithSelector(IStrategy.executeOperation.selector, _callData));
        require(success, string(abi.decode(result, (string))));

        emit FlashArbitrageInitiated(_strategy, _borrowToken, _amount);
    }

    // --- VII. External Protocol Whitelisting & Audit Tracking ---

    /**
     * @dev DAO whitelists external DeFi protocols that active strategies are permitted to interact with,
     *      enhancing security. Strategy contracts must check this whitelist before interacting with external protocols.
     * @param _protocolAddress The address of the external protocol.
     * @param _isWhitelisted True to whitelist, false to delist.
     */
    function whitelistExternalProtocol(address _protocolAddress, bool _isWhitelisted) public onlyAdmin {
        require(_protocolAddress != address(0), "Dynapool: Protocol address cannot be zero");
        whitelistedExternalProtocols[_protocolAddress] = _isWhitelisted;
        emit ExternalProtocolWhitelisted(_protocolAddress, _isWhitelisted);
    }

    /**
     * @dev DAO or a RISK_MANAGER can record the URI of an audit report for a specific strategy,
     *      improving transparency and informing DAO members about the strategy's security posture.
     * @param _strategyAddress The address of the strategy.
     * @param _auditURI The URI (e.g., IPFS hash) to the audit report.
     */
    function recordStrategyAudit(address _strategyAddress, string calldata _auditURI) public onlyRiskManager {
        require(_activeStrategyAddresses.contains(_strategyAddress), "Dynapool: Strategy is not active");
        activeStrategies[_strategyAddress].auditURI = _auditURI;
        emit StrategyAuditRecorded(_strategyAddress, _auditURI);
    }

    // --- Fallback and Receive functions ---

    /// @dev Prevents accidental ETH transfers to this contract, as it's designed for ERC20.
    receive() external payable {
        revert("Dynapool: ETH not accepted, please use ERC20 tokens.");
    }

    /// @dev Prevents accidental calls to undefined functions.
    fallback() external payable {
        revert("Dynapool: Call not accepted.");
    }
}
```