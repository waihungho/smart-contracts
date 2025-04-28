Okay, let's design a smart contract around the concept of a "Conditional Asset Management Vault". This contract will hold multiple ERC-20 tokens, execute predefined "strategies" (sequences of actions) based on external "conditions" verified by an oracle (simulated for demonstration), and allow governance over strategy definitions and oracle addresses. It incorporates concepts like multi-asset handling, conditional logic, state-based strategy execution, basic simulated governance, and oracle interaction.

We will avoid directly copying standard ERC-20, ERC-721, or basic access control patterns (though we'll use standard interfaces like IERC20). The logic for strategies, conditions, and execution will be custom.

**Contract Concept:** Conditional Strategy Vault (CSV)

**Purpose:** To allow users to deposit various ERC-20 tokens into a vault. The vault can then execute complex strategies (like internal swaps, external contract calls, or rebalancing) automatically when predefined on-chain conditions (e.g., price thresholds met, time elapsed, specific event triggered) are verified, potentially via an oracle. Strategy execution and key parameters are controlled by a simple on-chain governance mechanism.

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and necessary interfaces (IERC20, possibly SafeMath).
2.  **State Variables:** Define variables for ownership/governance, oracle address, supported tokens, vault balances, user balances, strategy definitions, condition definitions, governance proposals, and counters.
3.  **Enums and Structs:** Define custom types for condition types, action types, proposal types, and structs for `Condition`, `Action`, `Strategy`, and `Proposal`.
4.  **Events:** Define events for deposits, withdrawals, strategy executions, condition checks, proposal state changes, etc.
5.  **Modifiers:** Define custom modifiers for access control, pausing, etc.
6.  **Constructor:** Initialize the contract with owner/governance.
7.  **Access Control & Pausing:** Implement basic ownership/governance roles and pause functionality.
8.  **Oracle Management:** Functions to set the oracle address and (simulated) update oracle data.
9.  **Asset Management (Internal):** Functions to track internal vault and user balances. Support for multiple ERC-20 tokens.
10. **User Interaction:** Functions for depositing and withdrawing tokens.
11. **Condition Definition & Management:** Struct definition and functions to propose, vote on, execute, and view conditions via governance.
12. **Action Definition & Management:** Struct definition (Actions are part of Strategies). Internal helper to execute actions.
13. **Strategy Definition & Management:** Struct definition and functions to propose, vote on, execute, and view strategies via governance.
14. **Conditional Logic Execution:** Helper function to check if a condition is met using oracle data.
15. **Strategy Execution:** The core function. Allows anyone (or designated executor) to trigger a strategy check and execution if conditions are met and assets available.
16. **Governance System (Simplified):** Functions to create proposals, vote, and execute approved proposals.
17. **View Functions:** Read-only functions to query contract state, strategy/condition details, balances, proposals, etc.
18. **Emergency/Utility:** Functions like recovering accidentally sent tokens (with governance control).

**Function Summary (27 Functions Planned):**

1.  `constructor()`: Initializes the contract owner/governor.
2.  `pause()`: Pauses contract operations (governor only).
3.  `unpause()`: Unpauses contract operations (governor only).
4.  `setGovernor(address _newGovernor)`: Sets a new governor address (current governor only).
5.  `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle (governor only).
6.  `updateOracleValue(bytes32 _key, uint256 _value)`: (Simulated) Updates an oracle data point (only callable by the set oracle address).
7.  `getOracleValue(bytes32 _key)`: Retrieves the last known value from the oracle for a given key.
8.  `deposit(address tokenAddress, uint256 amount)`: Deposits a specified amount of an allowed ERC-20 token into the vault.
9.  `withdraw(address tokenAddress, uint256 amount)`: Withdraws a specified amount of a token the user has deposited (only if not locked by active strategies - *simplification: assume no locking for now*).
10. `getUserDepositBalance(address user, address tokenAddress)`: Gets the amount of a specific token deposited by a user.
11. `getTotalVaultBalance(address tokenAddress)`: Gets the total amount of a specific token held by the vault.
12. `propose(ProposalType proposalType, bytes memory data)`: Creates a new governance proposal (governor only). `data` contains encoded parameters for the proposal type (e.g., strategy/condition details).
13. `vote(uint256 proposalId, bool support)`: Casts a vote (for or against) on an active proposal.
14. `executeProposal(uint256 proposalId)`: Executes an approved proposal (checks vote threshold).
15. `addSupportedToken(address tokenAddress)`: Adds a token to the list of tokens the vault accepts deposits for (executed via governance proposal).
16. `removeSupportedToken(address tokenAddress)`: Removes a token from the supported list (executed via governance proposal).
17. `addStrategy(Strategy memory strategy)`: Adds a new strategy definition (executed via governance proposal).
18. `updateStrategy(uint256 strategyId, Strategy memory newStrategy)`: Updates an existing strategy definition (executed via governance proposal).
19. `addCondition(Condition memory condition)`: Adds a new condition definition (executed via governance proposal).
20. `updateCondition(uint256 conditionId, Condition memory newCondition)`: Updates an existing condition definition (executed via governance proposal).
21. `checkCondition(uint256 conditionId)`: Checks if a specific condition is currently met using oracle data.
22. `executeStrategy(uint256 strategyId)`: Attempts to execute a strategy. Checks if the strategy is active, conditions are met, and required assets are available. Performs the strategy's actions if all checks pass.
23. `getStrategyDetails(uint256 strategyId)`: Views the details of a specific strategy.
24. `getConditionDetails(uint256 conditionId)`: Views the details of a specific condition.
25. `getProposalDetails(uint256 proposalId)`: Views the details and current voting status of a proposal.
26. `isSupportedToken(address tokenAddress)`: Checks if a token is currently supported for deposit.
27. `recoverAccidentallySentTokens(address tokenAddress, uint256 amount)`: Allows the governor to recover tokens sent directly to the contract address that are not intended vault assets (use with extreme caution, preferably via governance).

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable as a base for Governor for simplicity

/**
 * @title ConditionalStrategyVault
 * @dev A multi-asset vault that executes strategies based on conditions checked against an oracle.
 *      Governance controls strategies, conditions, and parameters.
 *      Note: This is a complex, advanced concept contract for demonstration.
 *      Production usage would require extensive audits, robust oracle integration,
 *      more sophisticated governance (e.g., token-based voting), and gas optimizations.
 */

// --- Outline ---
// 1. Pragma and Imports
// 2. State Variables
// 3. Enums and Structs
// 4. Events
// 5. Modifiers
// 6. Constructor
// 7. Access Control & Pausing
// 8. Oracle Management
// 9. Asset Management (Internal)
// 10. User Interaction
// 11. Condition Definition & Management
// 12. Action Definition & Management (part of Strategy)
// 13. Strategy Definition & Management
// 14. Conditional Logic Execution
// 15. Strategy Execution
// 16. Governance System (Simplified)
// 17. View Functions
// 18. Emergency/Utility

// --- Function Summary ---
// 1. constructor(): Initializes the contract owner/governor.
// 2. pause(): Pauses contract operations (governor only).
// 3. unpause(): Unpauses contract operations (governor only).
// 4. setGovernor(address _newGovernor): Sets a new governor address (current governor only).
// 5. setOracleAddress(address _oracle): Sets the address of the trusted oracle (governor only).
// 6. updateOracleValue(bytes32 _key, uint256 _value): (Simulated) Updates an oracle data point (only callable by the set oracle address).
// 7. getOracleValue(bytes32 _key): Retrieves the last known value from the oracle for a given key.
// 8. deposit(address tokenAddress, uint256 amount): Deposits a specified amount of an allowed ERC-20 token into the vault.
// 9. withdraw(address tokenAddress, uint256 amount): Withdraws a specified amount of a token the user has deposited.
// 10. getUserDepositBalance(address user, address tokenAddress): Gets the amount of a specific token deposited by a user.
// 11. getTotalVaultBalance(address tokenAddress): Gets the total amount of a specific token held by the vault.
// 12. propose(ProposalType proposalType, bytes memory data): Creates a new governance proposal (governor only).
// 13. vote(uint256 proposalId, bool support): Casts a vote (for or against) on an active proposal.
// 14. executeProposal(uint256 proposalId): Executes an approved proposal (checks vote threshold).
// 15. addSupportedToken(address tokenAddress): Adds a token to the list of tokens the vault accepts deposits for (executed via governance proposal).
// 16. removeSupportedToken(address tokenAddress): Removes a token from the supported list (executed via governance proposal).
// 17. addStrategy(Strategy memory strategy): Adds a new strategy definition (executed via governance proposal).
// 18. updateStrategy(uint256 strategyId, Strategy memory newStrategy): Updates an existing strategy definition (executed via governance proposal).
// 19. addCondition(Condition memory condition): Adds a new condition definition (executed via governance proposal).
// 20. updateCondition(uint256 conditionId, Condition memory newCondition): Updates an existing condition definition (executed via governance proposal).
// 21. checkCondition(uint256 conditionId): Checks if a specific condition is currently met using oracle data.
// 22. executeStrategy(uint256 strategyId): Attempts to execute a strategy. Checks if conditions are met and assets available.
// 23. getStrategyDetails(uint256 strategyId): Views the details of a specific strategy.
// 24. getConditionDetails(uint256 conditionId): Views the details of a specific condition.
// 25. getProposalDetails(uint256 proposalId): Views the details and current voting status of a proposal.
// 26. isSupportedToken(address tokenAddress): Checks if a token is currently supported for deposit.
// 27. recoverAccidentallySentTokens(address tokenAddress, uint256 amount): Allows the governor to recover tokens sent directly.

contract ConditionalStrategyVault is Pausable {
    // --- 2. State Variables ---

    address public governor; // Simplified governance role
    address public oracleAddress;

    // Supported tokens for deposit
    mapping(address => bool) public isSupportedToken;
    address[] private _supportedTokens; // To iterate supported tokens

    // Vault balances (total held by contract)
    mapping(address => uint256) private vaultBalances;

    // User deposit balances
    mapping(address => mapping(address => uint256)) private userDepositBalances;

    // --- Oracle Simulation State ---
    mapping(bytes32 => uint256) private oracleData; // key => value

    // --- Strategy and Condition State ---
    uint256 public nextConditionId = 1;
    mapping(uint256 => Condition) public conditions;

    uint256 public nextStrategyId = 1;
    mapping(uint256 => Strategy) public strategies;

    // --- Governance State ---
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotePeriodBlocks = 100; // Blocks for voting period
    uint256 public proposalThresholdVotes = 1; // Minimum votes required for simple demo

    // --- 3. Enums and Structs ---

    enum ConditionType {
        PRICE_ABOVE,          // Check if oracle value for key is > threshold (key, thresholdValue)
        PRICE_BELOW,          // Check if oracle value for key is < threshold (key, thresholdValue)
        ASSET_BALANCE_ABOVE,  // Check if vault balance for token > threshold (tokenAddress, thresholdValue)
        ASSET_BALANCE_BELOW,  // Check if vault balance for token < threshold (tokenAddress, thresholdValue)
        TIME_AFTER,           // Check if current block.timestamp > timestamp (timestamp)
        TIME_BEFORE           // Check if current block.timestamp < timestamp (timestamp)
        // Add more complex condition types as needed (e.g., external contract state check)
    }

    enum ActionType {
        TRANSFER_INTERNAL,    // Transfer tokens within the vault (tokenAddress, recipientAddress - must be this contract, amount/percentage)
        TRANSFER_EXTERNAL,    // Transfer tokens from vault to external address (tokenAddress, recipientAddress, amount/percentage)
        CALL_EXTERNAL_CONTRACT // Call a function on another contract (targetAddress, value, data)
        // Add more action types (e.g., SWAP via DEX interface)
    }

    struct Condition {
        uint256 id;
        ConditionType conditionType;
        bytes data; // Encoded parameters based on type
        string description;
        bool isActive;
    }

    struct Action {
        ActionType actionType;
        bytes data; // Encoded parameters based on type
    }

    struct Strategy {
        uint256 id;
        uint256[] requiredConditionIds; // ALL listed conditions must be met
        Action[] actions; // Sequence of actions to perform
        string description;
        bool isActive;
    }

    enum ProposalType {
        ADD_SUPPORTED_TOKEN,      // data: abi.encode(tokenAddress)
        REMOVE_SUPPORTED_TOKEN,   // data: abi.encode(tokenAddress)
        ADD_STRATEGY,             // data: abi.encode(Strategy struct)
        UPDATE_STRATEGY,          // data: abi.encode(strategyId, Strategy struct)
        ADD_CONDITION,            // data: abi.encode(Condition struct)
        UPDATE_CONDITION,         // data: abi.encode(conditionId, Condition struct)
        SET_ORACLE_ADDRESS,       // data: abi.encode(oracleAddress)
        SET_GOVERNOR              // data: abi.encode(governorAddress)
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes data;
        uint255 startBlock;
        uint255 endBlock;
        uint255 votesFor;
        uint255 votesAgainst;
        mapping(address => bool) voted; // User voted in this proposal?
        bool executed;
        bool cancelled;
    }

    // --- 4. Events ---

    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event OracleValueUpdated(bytes32 indexed key, uint256 value);

    event TokenSupported(address indexed tokenAddress);
    event TokenUnsupported(address indexed tokenAddress);

    event Deposited(address indexed user, address indexed token, uint255 amount);
    event Withdrew(address indexed user, address indexed token, uint255 amount);

    event ConditionAdded(uint256 indexed conditionId, string description);
    event ConditionUpdated(uint256 indexed conditionId, string description);
    event StrategyAdded(uint256 indexed strategyId, string description);
    event StrategyUpdated(uint256 indexed strategyId, string description);

    event ProposalCreated(uint255 indexed proposalId, address indexed proposer, ProposalType proposalType, uint255 startBlock, uint255 endBlock);
    event Voted(uint255 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint255 indexed proposalId);
    event ProposalCancelled(uint255 indexed proposalId);

    event ConditionChecked(uint255 indexed conditionId, bool met);
    event StrategyAttempted(uint255 indexed strategyId);
    event StrategyExecuted(uint255 indexed strategyId);
    event StrategyFailed(uint255 indexed strategyId, string reason);
    event ActionExecuted(uint255 indexed strategyId, uint255 indexed actionIndex, ActionType actionType);

    // --- 5. Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == governor, "CSV: Not the governor");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "CSV: Not the oracle");
        _;
    }

    // Combined Pausable modifiers
    modifier whenNotPausedAndReady() {
        // _status != _PAUSED implicitly checked by Pausable.whenNotPaused
        require(oracleAddress != address(0), "CSV: Oracle not set");
        _;
    }

    // --- 6. Constructor ---

    constructor(address _initialGovernor) {
        require(_initialGovernor != address(0), "CSV: Zero address for governor");
        governor = _initialGovernor;
        // Using Ownable's initializer pattern is common, but let's stick to basic state var for this demo
        // Ownable is imported just for the base class to demonstrate using common libraries.
        // In a real scenario, might use a more complex governance setup.
    }

    // --- 7. Access Control & Pausing ---

    // Pausable functions from OpenZeppelin
    // pause() -> available via Pausable
    // unpause() -> available via Pausable

    /**
     * @dev Sets the address of the governor.
     * @param _newGovernor The address of the new governor.
     */
    function setGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "CSV: Zero address for governor");
        emit GovernorSet(governor, _newGovernor);
        governor = _newGovernor;
    }

    // --- 8. Oracle Management ---

    /**
     * @dev Sets the address of the trusted oracle contract.
     *      This contract relies on the oracle for external data conditions.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyGovernor {
        require(_oracle != address(0), "CSV: Zero address for oracle");
        emit OracleAddressSet(oracleAddress, _oracle);
        oracleAddress = _oracle;
    }

    /**
     * @dev (Simulated) Allows the designated oracle address to update a data value.
     *      In a real scenario, this would likely be an oracle interface call or callback.
     * @param _key A identifier for the data point (e.g., keccak256("ETH/USD")).
     * @param _value The new value for the data point.
     */
    function updateOracleValue(bytes32 _key, uint256 _value) external onlyOracle {
        oracleData[_key] = _value;
        emit OracleValueUpdated(_key, _value);
    }

    /**
     * @dev Retrieves the last known value for a data point from the simulated oracle.
     * @param _key The identifier for the data point.
     * @return The value associated with the key, or 0 if not set.
     */
    function getOracleValue(bytes32 _key) public view returns (uint256) {
        return oracleData[_key];
    }

    // --- 9. Asset Management (Internal) ---

    // vaultBalances and userDepositBalances are state variables updated internally

    // --- 10. User Interaction ---

    /**
     * @dev Deposits a specified amount of an allowed ERC-20 token into the vault.
     *      Requires the user to approve the contract beforehand.
     * @param tokenAddress The address of the ERC-20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address tokenAddress, uint256 amount) external whenNotPaused {
        require(isSupportedToken[tokenAddress], "CSV: Token not supported");
        require(amount > 0, "CSV: Deposit amount must be > 0");

        IERC20 token = IERC20(tokenAddress);
        uint256 initialVaultBalance = token.balanceOf(address(this));

        // Transfer tokens from user to contract
        token.transferFrom(msg.sender, address(this), amount);

        // Verify the transfer increased the balance correctly (basic check)
        // A more robust check would account for potential fees or token logic
        require(token.balanceOf(address(this)) == initialVaultBalance + amount, "CSV: Token transfer failed");

        // Update internal balances
        vaultBalances[tokenAddress] += amount;
        userDepositBalances[msg.sender][tokenAddress] += amount;

        emit Deposited(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Withdraws a specified amount of a token deposited by the user.
     *      Currently assumes no locking.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address tokenAddress, uint256 amount) external whenNotPaused {
        require(isSupportedToken[tokenAddress], "CSV: Token not supported");
        require(amount > 0, "CSV: Withdraw amount must be > 0");
        require(userDepositBalances[msg.sender][tokenAddress] >= amount, "CSV: Insufficient deposit balance");
        require(vaultBalances[tokenAddress] >= amount, "CSV: Insufficient vault balance (might be locked in strategy - not implemented)"); // Basic check

        // Update internal balances first (prevent reentrancy issues if token was malicious)
        userDepositBalances[msg.sender][tokenAddress] -= amount;
        vaultBalances[tokenAddress] -= amount;

        // Transfer tokens to user
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);

        emit Withdrew(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Gets the amount of a specific token deposited by a user.
     * @param user The address of the user.
     * @param tokenAddress The address of the token.
     * @return The deposited amount.
     */
    function getUserDepositBalance(address user, address tokenAddress) external view returns (uint256) {
        return userDepositBalances[user][tokenAddress];
    }

    /**
     * @dev Gets the total amount of a specific token held by the vault contract.
     *      This includes all user deposits and any tokens gained from strategies.
     * @param tokenAddress The address of the token.
     * @return The total vault balance.
     */
    function getTotalVaultBalance(address tokenAddress) external view returns (uint256) {
         // This should ideally match IERC20(tokenAddress).balanceOf(address(this))
         // if all tokens were received via deposit or strategy execution.
         // Using the internal state `vaultBalances` is more reliable if strategies
         // might move tokens without calling a 'receive' function.
         return vaultBalances[tokenAddress];
    }

    // --- 11. Condition Definition & Management ---
    // (Managed via Governance Proposals - see section 16)

    /**
     * @dev Gets the details of a specific condition.
     * @param conditionId The ID of the condition.
     * @return The Condition struct.
     */
    function getConditionDetails(uint256 conditionId) external view returns (Condition memory) {
        require(conditions[conditionId].id != 0, "CSV: Condition not found");
        return conditions[conditionId];
    }

    // --- 12. Action Definition & Management ---
    // (Actions are defined within Strategy structs)

    /**
     * @dev Internal helper function to execute a single action within a strategy.
     *      Handles different ActionTypes.
     * @param action The Action struct to execute.
     */
    function _executeAction(Action memory action) internal {
        if (action.actionType == ActionType.TRANSFER_INTERNAL) {
            (address tokenAddress, address recipientAddress, uint256 amount) = abi.decode(action.data, (address, address, uint256));
            require(recipientAddress == address(this), "CSV: Internal transfer recipient must be vault"); // Internal transfers stay in vault
            require(vaultBalances[tokenAddress] >= amount, "CSV: Insufficient balance for internal transfer");
            // No actual token transfer needed, just state update
            vaultBalances[tokenAddress] -= amount;
            vaultBalances[recipientAddress] += amount; // This should be address(this)
             // Note: A real internal transfer would map funds between sub-accounts if needed,
             // here it just decreases total vault balance for that token, assuming recipientAddress is address(this)
             // This action type is slightly underspecified without internal accounting per strategy/purpose.
             // Let's refine: TRANSFER_INTERNAL just moves 'virtual' balance within the vault's tracking, e.g., from a 'reserve' pool to a 'strategy' pool.
             // For this demo, let's make TRANSFER_INTERNAL simply move 'virtual' balance FROM one token entry TO another WITHIN the vault state (e.g. rebalancing)
             // But the Action struct only has one tokenAddress in the common params. Let's redefine ActionType.
             // New Plan: TRANSFER_INTERNAL is simple value adjustment for reporting, TRANSFER_EXTERNAL moves tokens out, CALL_EXTERNAL interacts.
             // Let's simplify further for demo: Only TRANSFER_EXTERNAL and CALL_EXTERNAL
             // Revert current _executeAction and redefine based on simplified ActionType:

             // Simplified Action Types based on data:
             // TRANSFER_EXTERNAL: data = abi.encode(tokenAddress, recipientAddress, amount)
             // CALL_EXTERNAL_CONTRACT: data = abi.encode(targetAddress, value, callData)
        } else if (action.actionType == ActionType.TRANSFER_EXTERNAL) {
            (address tokenAddress, address recipientAddress, uint256 amount) = abi.decode(action.data, (address, address, uint256));
            require(vaultBalances[tokenAddress] >= amount, "CSV: Insufficient balance for external transfer");

            // Update state before external call
            vaultBalances[tokenAddress] -= amount;

            // Perform actual token transfer
            IERC20 token = IERC20(tokenAddress);
            token.transfer(recipientAddress, amount); // Use transfer for ERC20 simple send
        } else if (action.actionType == ActionType.CALL_EXTERNAL_CONTRACT) {
            (address targetAddress, uint256 value, bytes memory callData) = abi.decode(action.data, (address, uint256, bytes));
            // Important: Low-level call is risky! Needs careful validation of target and data in a real system.
            (bool success, ) = targetAddress.call{value: value}(callData);
            require(success, "CSV: External call failed");
            // Note: This doesn't handle potential token transfers *into* the vault from the call.
            // A real system needs mechanisms to track and potentially distribute gains.
        } else {
            revert("CSV: Unknown action type");
        }
    }


    // --- 13. Strategy Definition & Management ---
    // (Managed via Governance Proposals - see section 16)

    /**
     * @dev Gets the details of a specific strategy.
     * @param strategyId The ID of the strategy.
     * @return The Strategy struct.
     */
    function getStrategyDetails(uint256 strategyId) external view returns (Strategy memory) {
        require(strategies[strategyId].id != 0, "CSV: Strategy not found");
        return strategies[strategyId];
    }

    // --- 14. Conditional Logic Execution ---

    /**
     * @dev Checks if a specific condition is currently met based on oracle data or internal state.
     *      Internal helper function.
     * @param conditionId The ID of the condition to check.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(uint256 conditionId) internal view returns (bool) {
        Condition storage condition = conditions[conditionId];
        require(condition.id != 0 && condition.isActive, "CSV: Invalid or inactive condition");

        if (condition.conditionType == ConditionType.PRICE_ABOVE) {
            (bytes32 key, uint256 thresholdValue) = abi.decode(condition.data, (bytes32, uint256));
            return getOracleValue(key) > thresholdValue;
        } else if (condition.conditionType == ConditionType.PRICE_BELOW) {
            (bytes32 key, uint256 thresholdValue) = abi.decode(condition.data, (bytes32, uint256));
            return getOracleValue(key) < thresholdValue;
        } else if (condition.conditionType == ConditionType.ASSET_BALANCE_ABOVE) {
             (address tokenAddress, uint256 thresholdValue) = abi.decode(condition.data, (address, uint256));
             return vaultBalances[tokenAddress] > thresholdValue;
        } else if (condition.conditionType == ConditionType.ASSET_BALANCE_BELOW) {
             (address tokenAddress, uint256 thresholdValue) = abi.decode(condition.data, (address, uint256));
             return vaultBalances[tokenAddress] < thresholdValue;
        } else if (condition.conditionType == ConditionType.TIME_AFTER) {
             (uint256 timestamp) = abi.decode(condition.data, (uint256));
             return block.timestamp > timestamp;
        } else if (condition.conditionType == ConditionType.TIME_BEFORE) {
             (uint256 timestamp) = abi.decode(condition.data, (uint256));
             return block.timestamp < timestamp;
        }
        // Add checks for other condition types here
        return false; // Default to false for unknown types
    }

    // --- 15. Strategy Execution ---

    /**
     * @dev Attempts to execute a specified strategy.
     *      Checks if the strategy is active and all its required conditions are met.
     *      If successful, executes the sequence of actions defined in the strategy.
     *      Anyone can call this function, but execution only proceeds if conditions are met.
     * @param strategyId The ID of the strategy to attempt to execute.
     */
    function executeStrategy(uint256 strategyId) external whenNotPausedAndReady {
        Strategy storage strategy = strategies[strategyId];
        emit StrategyAttempted(strategyId);

        require(strategy.id != 0 && strategy.isActive, "CSV: Strategy not found or inactive");

        // Check all required conditions
        for (uint256 i = 0; i < strategy.requiredConditionIds.length; i++) {
            uint256 conditionId = strategy.requiredConditionIds[i];
            bool conditionMet = _checkCondition(conditionId);
            emit ConditionChecked(conditionId, conditionMet);
            if (!conditionMet) {
                emit StrategyFailed(strategyId, "Condition not met");
                return; // Conditions not met, strategy cannot execute
            }
        }

        // --- Execute Actions ---
        // Use a nonReentrant modifier if any action involves external calls that could re-enter
        // This example uses _executeAction which includes external calls, so nonReentrant is advisable.
        // Adding a basic reentrancy guard here:
        uint256 internalExecutionState = 0; // 0: Idle, 1: Executing
        require(internalExecutionState == 0, "CSV: ReentrancyGuard");
        internalExecutionState = 1;

        // Note: This execution is atomic. If any action fails, the whole transaction reverts.
        // For complex strategies, consider patterns with checkpointing or task queues.
        for (uint256 i = 0; i < strategy.actions.length; i++) {
            Action memory action = strategy.actions[i];
            _executeAction(action);
            emit ActionExecuted(strategyId, i, action.actionType);
        }

        internalExecutionState = 0; // Reset state

        emit StrategyExecuted(strategyId);
        // Consider logging parameters or outcomes here for auditing/debugging
    }


    // --- 16. Governance System (Simplified) ---

    /**
     * @dev Creates a new governance proposal.
     *      Only the governor can propose.
     * @param proposalType The type of proposal.
     * @param data Encoded data specific to the proposal type.
     * @return proposalId The ID of the created proposal.
     */
    function propose(ProposalType proposalType, bytes memory data) external onlyGovernor returns (uint256 proposalId) {
        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: proposalType,
            data: data,
            startBlock: uint255(block.number),
            endBlock: uint255(block.number + proposalVotePeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool), // Initialize new mapping
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, msg.sender, proposalType, proposals[proposalId].startBlock, proposals[proposalId].endBlock);
        return proposalId;
    }

    /**
     * @dev Casts a vote on an active proposal.
     *      Simplified: Any address can vote once per proposal.
     *      A real system would likely require holding governance tokens.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a vote FOR, false for a vote AGAINST.
     */
    function vote(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0 && !proposal.executed && !proposal.cancelled, "CSV: Invalid or closed proposal");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "CSV: Voting period ended");
        require(!proposal.voted[msg.sender], "CSV: Already voted");

        proposal.voted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes an approved proposal.
     *      Can be called by anyone after the voting period ends if the proposal meets the threshold.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0 && !proposal.executed && !proposal.cancelled, "CSV: Invalid or already processed proposal");
        require(block.number > proposal.endBlock, "CSV: Voting period not ended");

        // Check if proposal meets threshold
        // Simplified: requires proposalThresholdVotes 'for' votes and more 'for' than 'against'
        bool passed = proposal.votesFor >= proposalThresholdVotes && proposal.votesFor > proposal.votesAgainst;
        require(passed, "CSV: Proposal failed to meet threshold");

        // --- Execute the action based on proposal type ---
        if (proposal.proposalType == ProposalType.ADD_SUPPORTED_TOKEN) {
            address tokenAddress = abi.decode(proposal.data, (address));
            addSupportedToken(tokenAddress); // Call internal helper
        } else if (proposal.proposalType == ProposalType.REMOVE_SUPPORTED_TOKEN) {
            address tokenAddress = abi.decode(proposal.data, (address));
            removeSupportedToken(tokenAddress); // Call internal helper
        } else if (proposal.proposalType == ProposalType.ADD_STRATEGY) {
             Strategy memory newStrategy = abi.decode(proposal.data, (Strategy));
             addStrategy(newStrategy); // Call internal helper
        } else if (proposal.proposalType == ProposalType.UPDATE_STRATEGY) {
             (uint256 targetStrategyId, Strategy memory updatedStrategy) = abi.decode(proposal.data, (uint256, Strategy));
             updateStrategy(targetStrategyId, updatedStrategy); // Call internal helper
        } else if (proposal.proposalType == ProposalType.ADD_CONDITION) {
             Condition memory newCondition = abi.decode(proposal.data, (Condition));
             addCondition(newCondition); // Call internal helper
        } else if (proposal.proposalType == ProposalType.UPDATE_CONDITION) {
             (uint256 targetConditionId, Condition memory updatedCondition) = abi.decode(proposal.data, (uint256, Condition));
             updateCondition(targetConditionId, updatedCondition); // Call internal helper
        } else if (proposal.proposalType == ProposalType.SET_ORACLE_ADDRESS) {
             address newOracle = abi.decode(proposal.data, (address));
             setOracleAddress(newOracle); // Call public function (governor already checked by propose/execute flow)
        } else if (proposal.proposalType == ProposalType.SET_GOVERNOR) {
             address newGovernor = abi.decode(proposal.data, (address));
             setGovernor(newGovernor); // Call public function
        } else {
            revert("CSV: Unknown proposal type");
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // Internal helpers for governance execution (called by executeProposal)
    function addSupportedToken(address tokenAddress) internal {
        require(tokenAddress != address(0), "CSV: Zero address");
        require(!isSupportedToken[tokenAddress], "CSV: Token already supported");
        isSupportedToken[tokenAddress] = true;
        _supportedTokens.push(tokenAddress);
        emit TokenSupported(tokenAddress);
    }

    function removeSupportedToken(address tokenAddress) internal {
        require(isSupportedToken[tokenAddress], "CSV: Token not supported");
        isSupportedToken[tokenAddress] = false;
        // Note: Removing from _supportedTokens array efficiently is complex.
        // For simplicity here, we just mark it as unsupported. Iterating _supportedTokens
        // would need to check isSupportedToken.
        // A production contract might use a linked list or different data structure.
        emit TokenUnsupported(tokenAddress);
    }

    function addStrategy(Strategy memory newStrategy) internal {
        require(newStrategy.id == 0, "CSV: Strategy ID must be 0 for adding"); // ID assigned by contract
        newStrategy.id = nextStrategyId++;
        newStrategy.isActive = true; // New strategies are active by default
        strategies[newStrategy.id] = newStrategy;
        emit StrategyAdded(newStrategy.id, newStrategy.description);
    }

    function updateStrategy(uint256 targetStrategyId, Strategy memory updatedStrategy) internal {
         require(strategies[targetStrategyId].id != 0, "CSV: Strategy not found for update");
         // Allow updating description, condition list, action list, and active status
         strategies[targetStrategyId].requiredConditionIds = updatedStrategy.requiredConditionIds;
         strategies[targetStrategyId].actions = updatedStrategy.actions;
         strategies[targetStrategyId].description = updatedStrategy.description;
         strategies[targetStrategyId].isActive = updatedStrategy.isActive;
         // Do NOT update the ID
         emit StrategyUpdated(targetStrategyId, updatedStrategy.description);
    }

    function addCondition(Condition memory newCondition) internal {
         require(newCondition.id == 0, "CSV: Condition ID must be 0 for adding"); // ID assigned by contract
         newCondition.id = nextConditionId++;
         newCondition.isActive = true; // New conditions are active by default
         conditions[newCondition.id] = newCondition;
         emit ConditionAdded(newCondition.id, newCondition.description);
    }

    function updateCondition(uint256 targetConditionId, Condition memory updatedCondition) internal {
         require(conditions[targetConditionId].id != 0, "CSV: Condition not found for update");
         // Allow updating all fields except ID
         conditions[targetConditionId].conditionType = updatedCondition.conditionType;
         conditions[targetConditionId].data = updatedCondition.data;
         conditions[targetConditionId].description = updatedCondition.description;
         conditions[targetConditionId].isActive = updatedCondition.isActive;
         emit ConditionUpdated(targetConditionId, updatedCondition.description);
    }


    // --- 17. View Functions ---

    /**
     * @dev Gets the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The Proposal struct details (excluding the 'voted' mapping).
     */
    function getProposalDetails(uint255 proposalId) external view returns (
        uint255 id,
        address proposer,
        ProposalType proposalType,
        bytes memory data,
        uint255 startBlock,
        uint255 endBlock,
        uint255 votesFor,
        uint255 votesAgainst,
        bool executed,
        bool cancelled
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CSV: Proposal not found");
        return (
            proposal.id,
            proposal.proposer,
            proposal.proposalType,
            proposal.data,
            proposal.startBlock,
            proposal.endBlock,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.cancelled
        );
    }

     /**
     * @dev Checks if a specific address has voted on a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address to check.
     * @return True if the voter has voted, false otherwise.
     */
    function getUserVote(uint255 proposalId, address voter) external view returns (bool) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, "CSV: Proposal not found");
         return proposal.voted[voter]; // Returns false if not voted (default for mapping)
    }

    /**
     * @dev Gets the list of currently supported token addresses.
     * @return An array of supported token addresses.
     */
    function getSupportedTokens() external view returns (address[] memory) {
        // Note: If removeSupportedToken is used, this array might contain addresses
        // where isSupportedToken[address] is false. Filtering would be needed.
        return _supportedTokens;
    }


    // --- 18. Emergency/Utility ---

    /**
     * @dev Allows the governor to recover ERC20 tokens that were accidentally sent
     *      directly to the contract address, *if* they are not a supported vault token.
     *      This prevents locking valuable tokens if sent by mistake.
     *      Use with extreme caution, preferably via a governance proposal.
     * @param tokenAddress The address of the token to recover.
     * @param amount The amount of tokens to recover.
     */
    function recoverAccidentallySentTokens(address tokenAddress, uint256 amount) external onlyGovernor {
        require(tokenAddress != address(0), "CSV: Zero address");
        require(!isSupportedToken[tokenAddress], "CSV: Cannot recover supported vault tokens");
        require(amount > 0, "CSV: Amount must be > 0");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "CSV: Insufficient contract balance");

        token.transfer(governor, amount); // Transfer to the current governor

        // Note: Consider emitting an event for transparency
    }

    // Fallback/Receive functions are not strictly needed for ERC20, but could be added
    // if expecting native token transfers (ETH). For this example, we focus on ERC20.
    // receive() external payable {}
    // fallback() external payable {}
}
```