Okay, let's create a smart contract called "QuantumVault". This contract will manage assets (ETH or ERC20 tokens) locked under complex, multi-faceted conditions that can include time, block number, external contract state, and oracle price feeds. It will also include a basic on-chain reputation system for users who successfully claim deposits based on conditions, and dynamic protocol fees.

This concept combines:
1.  **Conditional Logic:** Release based on multiple, diverse criteria.
2.  **Time & State Dependency:** Using block variables and external calls.
3.  **Oracle Integration:** Dependency on external data feeds (simulated or actual via interfaces).
4.  **Reputation System:** Simple on-chain tracking of user success.
5.  **Dynamic Fees & Protocol Revenue:** Fees based on deposit characteristics.
6.  **Emergency & Failure States:** Handling scenarios where conditions become impossible or require intervention.

This is more complex than a simple time-lock or vesting contract.

---

## QuantumVault Smart Contract

### Outline:

1.  **Contract Description:** A conditional time-locked escrow vault based on multiple criteria.
2.  **Core Concepts:** Deposits locked by conditions, diverse condition types (time, block, external state, oracle price), reputation tracking, dynamic fees.
3.  **State Variables:** Owner, pause status, fee rates, allowed tokens, oracle addresses, deposit counter, mappings for deposits, user deposits, user profiles, collected fees.
4.  **Structs:** Define `Condition`, `Deposit`, `UserProfile`.
5.  **Enums:** Define `DepositState`, `ConditionType`, `ComparisonOperator`.
6.  **Events:** Signal key actions (Deposit, WithdrawalInitiated, WithdrawalExecuted, ConditionsProven, FeeCollected, etc.).
7.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`, `whenPaused`), state checks (`depositExists`, `depositIsInState`).
8.  **Interfaces:** For ERC20 tokens and Oracle price feeds (e.g., Chainlink).
9.  **Functions (20+):**
    *   Core Deposit/Withdrawal Flow.
    *   Condition Management.
    *   Condition Checking & Proving.
    *   Reputation Management (internal calculation, public query).
    *   Fee Calculation & Collection.
    *   Admin/Owner Functions (settings, emergency, pause).
    *   Query Functions (get details, lists, totals).
    *   Failure/Cleanup Function.

### Function Summary:

1.  `constructor()`: Initializes contract owner, sets initial parameters.
2.  `depositETH()`: Allows depositing ETH with specified conditions.
3.  `depositERC20()`: Allows depositing ERC20 tokens with specified conditions.
4.  `addConditionToDeposit()`: Adds a new condition to an existing deposit (if allowed by state).
5.  `updateConditionInDeposit()`: Modifies an existing condition (if allowed by state/permissions).
6.  `removeConditionFromDeposit()`: Removes a condition (if allowed).
7.  `checkConditionStatus()`: Checks the status of a single condition for a deposit (view).
8.  `areAllConditionsMet()`: Checks if all conditions for a deposit are currently true (view).
9.  `proveConditionMet()`: Allows anyone to trigger a check for a single condition and potentially update cached status or emit event (more complex, let's just emit for simplicity).
10. `initiateWithdrawal()`: Checks if conditions are met and moves deposit to 'ReadyForWithdrawal' state. Calculates reputation gain.
11. `executeWithdrawal()`: Transfers funds for deposits in 'ReadyForWithdrawal' state.
12. `markDepositFailed()`: Allows marking a deposit as failed if conditions become impossible (e.g., deadline passed).
13. `getDepositDetails()`: Retrieves all details for a specific deposit (view).
14. `getUserDeposits()`: Lists deposit IDs for a given user (view).
15. `getTotalLockedValue()`: Gets total value locked in the contract (optionally per token/state) (view).
16. `getUserReputation()`: Gets the reputation score for a user (view).
17. `calculateDepositFee()`: Calculates the fee for a given deposit amount/token (view).
18. `getProtocolFeesCollected()`: Gets total fees collected for a specific token (view).
19. `withdrawProtocolFees()`: Allows owner to withdraw collected fees.
20. `setDepositFeeBasisPoints()`: Owner sets the fee percentage.
21. `addAllowedToken()`: Owner adds an ERC20 token address that can be deposited.
22. `removeAllowedToken()`: Owner removes an allowed ERC20 token address.
23. `setOracleAddress()`: Owner sets the address for a specific oracle key (e.g., "ETH/USD").
24. `emergencyRelease()`: Owner can release funds from a deposit bypassing conditions (use with extreme caution).
25. `pause()`: Owner pauses contract operations.
26. `unpause()`: Owner unpauses contract operations.
27. `transferOwnership()`: Transfers ownership of the contract.
28. `sweepStuckFunds()`: Owner can retrieve accidentally sent tokens/ETH not part of a deposit.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Note: In a real scenario, use Chainlink or another robust oracle solution
// This interface is a simplified example.
interface IPriceOracle {
    function getLatestPrice(string calldata key) external view returns (int256 price, uint256 timestamp);
    // Assume price is given with fixed decimals, or this interface specifies it.
    // For simplicity, let's assume it's an integer price value that needs
    // knowledge of its decimals outside this interface.
}

// Interface for an external contract with a boolean state variable/function
interface IExternalState {
    function getStateBool() external view returns (bool);
}

contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    // --- Structs ---

    // Represents a single condition that must be met
    struct Condition {
        ConditionType conditionType; // Type of condition (time, block, external state, oracle)
        ComparisonOperator comparisonOperator; // How to compare (GTE, LTE, EQ)
        uint256 targetValueUint; // Target value for uint comparisons (timestamp, block number, price threshold)
        bool targetValueBool; // Target value for boolean state comparisons
        address targetAddress; // Address of external contract or oracle
        string oracleKeyString; // Key for the oracle (e.g., "ETH/USD")
        bool isMet; // Cached status - can be updated by proveConditionMet or checked directly
    }

    // Represents a single deposit
    struct Deposit {
        address depositor; // The user who made the deposit
        address tokenAddress; // Address of the deposited token (address(0) for ETH)
        uint256 amount; // The amount deposited
        Condition[] conditions; // Array of conditions that must all be met
        DepositState state; // Current state of the deposit
        uint256 depositTimestamp; // Timestamp when the deposit was made
        uint256 conditionsMetTimestamp; // Timestamp when conditions were first met and withdrawal initiated
        uint256 reputationEarned; // Reputation points earned upon successful withdrawal initiation
        uint256 deadlineForConditions; // Optional deadline by which conditions must be met
    }

    // Represents a user's profile
    struct UserProfile {
        uint256 reputation; // Reputation score
    }

    // --- Enums ---

    // States a deposit can be in
    enum DepositState {
        Locked, // Conditions not yet met
        ReadyForWithdrawal, // All conditions met, withdrawal initiated
        Withdrawn, // Funds have been withdrawn
        FailedConditions, // Conditions could not be met (e.g., deadline passed)
        EmergencyReleased // Funds released by owner emergency function
    }

    // Types of conditions
    enum ConditionType {
        TimestampGTE, // Block timestamp >= targetValueUint
        BlockNumberGTE, // Block number >= targetValueUint
        ExternalBoolStateEQ, // targetAddress.getStateBool() == targetValueBool
        OraclePriceGTE, // Price from oracle >= targetValueUint
        OraclePriceLTE // Price from oracle <= targetValueUint
    }

    // Comparison operators (simplified for clarity)
    enum ComparisonOperator {
        GTE, // Greater Than or Equal
        LTE, // Less Than or Equal
        EQ // Equal
    }


    // --- State Variables ---

    uint256 public depositCounter; // Counter for unique deposit IDs
    mapping(uint256 => Deposit) public deposits; // Mapping from deposit ID to Deposit struct
    mapping(address => uint256[]) public userDeposits; // Mapping from user address to array of deposit IDs
    mapping(address => UserProfile) public userProfiles; // Mapping from user address to UserProfile struct

    uint256 public depositFeeBasisPoints; // Fee percentage (e.g., 10 = 0.1%)
    address public protocolFeeRecipient; // Address to send fees to

    mapping(address => bool) public isAllowedToken; // Mapping of allowed ERC20 token addresses
    mapping(string => address) public oracleAddresses; // Mapping from oracle key string to oracle address
    string[] private oracleKeys; // Array to keep track of oracle keys

    mapping(address => uint256) public protocolFeesCollected; // Total fees collected per token (address(0) for ETH)

    // --- Events ---

    event DepositMade(uint256 indexed depositId, address indexed depositor, address indexed tokenAddress, uint256 amount, uint256 depositTimestamp);
    event ConditionAdded(uint256 indexed depositId, uint256 conditionIndex, ConditionType conditionType);
    event ConditionUpdated(uint256 indexed depositId, uint256 conditionIndex);
    event ConditionRemoved(uint256 indexed depositId, uint256 conditionIndex);
    event ConditionProven(uint256 indexed depositId, uint256 indexed conditionIndex, bool status);
    event WithdrawalInitiated(uint256 indexed depositId, address indexed depositor, uint256 conditionsMetTimestamp, uint256 reputationEarned);
    event WithdrawalExecuted(uint256 indexed depositId, address indexed depositor, address indexed tokenAddress, uint256 amount);
    event DepositStateChanged(uint256 indexed depositId, DepositState newState, DepositState oldState);
    event DepositMarkedFailed(uint256 indexed depositId);
    event EmergencyReleaseExecuted(uint256 indexed depositId, address indexed recipient);
    event FeeCollected(address indexed tokenAddress, uint256 amount);
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event DepositFeeUpdated(uint256 newFeeBasisPoints);
    event AllowedTokenAdded(address indexed tokenAddress);
    event AllowedTokenRemoved(address indexed tokenAddress);
    event OracleAddressSet(string indexed key, address indexed oracleAddress);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, uint256 amount, address indexed recipient);

    // --- Modifiers ---

    modifier depositExists(uint256 _depositId) {
        require(_depositId > 0 && _depositId <= depositCounter, "QuantumVault: Invalid deposit ID");
        _;
    }

    modifier depositIsInState(uint256 _depositId, DepositState _state) {
        require(deposits[_depositId].state == _state, "QuantumVault: Deposit is not in required state");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialFeeBasisPoints, address _initialFeeRecipient) Ownable(msg.sender) Pausable(false) {
        depositFeeBasisPoints = _initialFeeBasisPoints;
        protocolFeeRecipient = _initialFeeRecipient;
        // Add ETH as an allowed token by default (represented by address(0))
        isAllowedToken[address(0)] = true;
    }

    // --- Core Deposit Functions (2 Functions) ---

    /// @notice Deposits ETH into the vault under specified conditions.
    /// @param _conditions Array of conditions for withdrawal.
    /// @param _deadlineForConditions Optional deadline (timestamp) for conditions to be met (0 for no deadline).
    function depositETH(Condition[] memory _conditions, uint256 _deadlineForConditions) external payable whenNotPaused returns (uint256 depositId) {
        require(msg.value > 0, "QuantumVault: ETH amount must be greater than 0");
        require(_conditions.length > 0, "QuantumVault: At least one condition required");

        uint256 fee = calculateDepositFee(address(0), msg.value);
        uint256 amountToLock = msg.value.sub(fee);

        // Collect fee
        if (fee > 0) {
            (bool success,) = protocolFeeRecipient.call{value: fee}("");
            require(success, "QuantumVault: Fee transfer failed");
            protocolFeesCollected[address(0)] = protocolFeesCollected[address(0)].add(fee);
            emit FeeCollected(address(0), fee);
        }

        depositCounter++;
        depositId = depositCounter;

        deposits[depositId] = Deposit({
            depositor: msg.sender,
            tokenAddress: address(0), // address(0) signifies ETH
            amount: amountToLock,
            conditions: _conditions,
            state: DepositState.Locked,
            depositTimestamp: block.timestamp,
            conditionsMetTimestamp: 0, // Not set initially
            reputationEarned: 0, // Not set initially
            deadlineForConditions: _deadlineForConditions
        });

        userDeposits[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, address(0), amountToLock, block.timestamp);
        emit DepositStateChanged(depositId, DepositState.Locked, DepositState.Locked); // State starts as Locked

        return depositId;
    }

    /// @notice Deposits ERC20 tokens into the vault under specified conditions.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _amount The amount of tokens to deposit.
    /// @param _conditions Array of conditions for withdrawal.
    /// @param _deadlineForConditions Optional deadline (timestamp) for conditions to be met (0 for no deadline).
    function depositERC20(address _tokenAddress, uint256 _amount, Condition[] memory _conditions, uint256 _deadlineForConditions) external whenNotPaused returns (uint256 depositId) {
        require(_amount > 0, "QuantumVault: Token amount must be greater than 0");
        require(isAllowedToken[_tokenAddress], "QuantumVault: Token is not allowed");
        require(_conditions.length > 0, "QuantumVault: At least one condition required");

        uint256 fee = calculateDepositFee(_tokenAddress, _amount);
        uint256 amountToLock = _amount.sub(fee);

        // Transfer tokens first
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Collect fee
        if (fee > 0) {
            token.safeTransfer(protocolFeeRecipient, fee);
            protocolFeesCollected[_tokenAddress] = protocolFeesCollected[_tokenAddress].add(fee);
            emit FeeCollected(_tokenAddress, fee);
        }

        depositCounter++;
        depositId = depositCounter;

        deposits[depositId] = Deposit({
            depositor: msg.sender,
            tokenAddress: _tokenAddress,
            amount: amountToLock,
            conditions: _conditions,
            state: DepositState.Locked,
            depositTimestamp: block.timestamp,
            conditionsMetTimestamp: 0,
            reputationEarned: 0,
            deadlineForConditions: _deadlineForConditions
        });

        userDeposits[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, _tokenAddress, amountToLock, block.timestamp);
        emit DepositStateChanged(depositId, DepositState.Locked, DepositState.Locked);

        return depositId;
    }

    // --- Condition Management Functions (3 Functions) ---

    /// @notice Adds a condition to an existing locked deposit.
    /// @param _depositId The ID of the deposit.
    /// @param _condition The condition to add.
    function addConditionToDeposit(uint256 _depositId, Condition memory _condition) external depositExists(_depositId) depositIsInState(_depositId, DepositState.Locked) {
        require(deposits[_depositId].depositor == msg.sender, "QuantumVault: Only depositor can add conditions");
        deposits[_depositId].conditions.push(_condition);
        emit ConditionAdded(_depositId, deposits[_depositId].conditions.length - 1, _condition.conditionType);
    }

     /// @notice Updates an existing condition in a locked deposit.
     /// @param _depositId The ID of the deposit.
     /// @param _conditionIndex The index of the condition in the conditions array.
     /// @param _condition The new condition details.
    function updateConditionInDeposit(uint256 _depositId, uint256 _conditionIndex, Condition memory _condition) external depositExists(_depositId) depositIsInState(_depositId, DepositState.Locked) {
        require(deposits[_depositId].depositor == msg.sender, "QuantumVault: Only depositor can update conditions");
        require(_conditionIndex < deposits[_depositId].conditions.length, "QuantumVault: Invalid condition index");
        deposits[_depositId].conditions[_conditionIndex] = _condition;
        emit ConditionUpdated(_depositId, _conditionIndex);
    }

    /// @notice Removes a condition from a locked deposit.
    /// @param _depositId The ID of the deposit.
    /// @param _conditionIndex The index of the condition to remove.
    function removeConditionFromDeposit(uint256 _depositId, uint256 _conditionIndex) external depositExists(_depositId) depositIsInState(_depositId, DepositState.Locked) {
        require(deposits[_depositId].depositor == msg.sender, "QuantumVault: Only depositor can remove conditions");
        require(_conditionIndex < deposits[_depositId].conditions.length, "QuantumVault: Invalid condition index");

        // Swap and pop to remove element from array
        uint256 lastIndex = deposits[_depositId].conditions.length - 1;
        if (_conditionIndex != lastIndex) {
            deposits[_depositId].conditions[_conditionIndex] = deposits[_depositId].conditions[lastIndex];
        }
        deposits[_depositId].conditions.pop();

        emit ConditionRemoved(_depositId, _conditionIndex);
    }


    // --- Condition Checking & Proving Functions (3 Functions) ---

    /// @notice Checks the status of a single condition.
    /// @param _condition The condition struct to check.
    /// @return True if the condition is currently met, false otherwise.
    function checkConditionStatus(Condition memory _condition) public view returns (bool) {
        // Handle potential failures gracefully (e.g., external contract not found, oracle call fails)
        // In a real dapp, robust error handling is needed here.
        try {
            if (_condition.conditionType == ConditionType.TimestampGTE) {
                return block.timestamp >= _condition.targetValueUint;
            } else if (_condition.conditionType == ConditionType.BlockNumberGTE) {
                return block.number >= _condition.targetValueUint;
            } else if (_condition.conditionType == ConditionType.ExternalBoolStateEQ) {
                require(_condition.targetAddress.isContract(), "QuantumVault: Target address is not a contract");
                bool externalState = IExternalState(_condition.targetAddress).getStateBool();
                return externalState == _condition.targetValueBool;
            } else if (_condition.conditionType == ConditionType.OraclePriceGTE) {
                 require(oracleAddresses[_condition.oracleKeyString] != address(0), "QuantumVault: Oracle address not set for key");
                 (int256 price, uint256 timestamp) = IPriceOracle(oracleAddresses[_condition.oracleKeyString]).getLatestPrice(_condition.oracleKeyString);
                 // Note: Integer comparison assumes targetValueUint matches oracle decimal places
                 return price >= int256(_condition.targetValueUint);
            } else if (_condition.conditionType == ConditionType.OraclePriceLTE) {
                 require(oracleAddresses[_condition.oracleKeyString] != address(0), "QuantumVault: Oracle address not set for key");
                 (int256 price, uint256 timestamp) = IPriceOracle(oracleAddresses[_condition.oracleKeyString]).getLatestPrice(_condition.oracleKeyString);
                 // Note: Integer comparison assumes targetValueUint matches oracle decimal places
                 return price <= int256(_condition.targetValueUint);
            }
        } catch {
            // If external call or oracle fails, the condition is considered NOT met.
            // More sophisticated error handling could be added.
            return false;
        }
        // Unknown condition type should fail the check
        return false;
    }

    /// @notice Checks if all conditions for a specific deposit are currently met.
    /// @param _depositId The ID of the deposit.
    /// @return True if all conditions are met, false otherwise.
    function areAllConditionsMet(uint256 _depositId) public view depositExists(_depositId) returns (bool) {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.conditions.length == 0) {
             // No conditions means it's always met for this check,
             // though technically deposit requires at least one condition.
            return true;
        }
        for (uint i = 0; i < deposit.conditions.length; i++) {
            if (!checkConditionStatus(deposit.conditions[i])) {
                return false; // At least one condition is not met
            }
        }
        return true; // All conditions are met
    }

    /// @notice Allows anyone to prove the status of a specific condition.
    /// This doesn't change state by default in this simple version, just emits an event.
    /// Can be extended to cache status or trigger subsequent actions.
    /// @param _depositId The ID of the deposit.
    /// @param _conditionIndex The index of the condition.
    function proveConditionMet(uint256 _depositId, uint256 _conditionIndex) external depositExists(_depositId) {
        require(_conditionIndex < deposits[_depositId].conditions.length, "QuantumVault: Invalid condition index");
        bool status = checkConditionStatus(deposits[_depositId].conditions[_conditionIndex]);
        emit ConditionProven(_depositId, _conditionIndex, status);

        // Advanced: Could add logic here to update deposits[_depositId].conditions[_conditionIndex].isMet
        // This requires careful handling of state transitions and gas costs.
        // For simplicity, we rely on areAllConditionsMet checking live status.
    }

    // --- Withdrawal Functions (2 Functions) ---

    /// @notice Initiates the withdrawal process if all conditions are met and deposit is locked.
    /// Updates the deposit state and calculates reputation gain.
    /// @param _depositId The ID of the deposit.
    function initiateWithdrawal(uint256 _depositId) external depositExists(_depositId) depositIsInState(_depositId, DepositState.Locked) {
        require(deposits[_depositId].depositor == msg.sender, "QuantumVault: Only depositor can initiate withdrawal");
        require(areAllConditionsMet(_depositId), "QuantumVault: Not all conditions are met");

        Deposit storage deposit = deposits[_depositId];
        DepositState oldState = deposit.state;
        deposit.state = DepositState.ReadyForWithdrawal;
        deposit.conditionsMetTimestamp = block.timestamp;

        // Calculate and add reputation
        uint256 potentialReputation = _calculateReputationGain(deposit.amount, deposit.depositTimestamp, block.timestamp);
        deposit.reputationEarned = potentialReputation; // Store reputation earned by this specific deposit
        userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.add(potentialReputation);

        emit WithdrawalInitiated(_depositId, msg.sender, block.timestamp, potentialReputation);
        emit DepositStateChanged(_depositId, DepositState.ReadyForWithdrawal, oldState);
    }

    /// @notice Executes the withdrawal, transferring funds if the deposit is ready.
    /// @param _depositId The ID of the deposit.
    function executeWithdrawal(uint256 _depositId) external depositExists(_depositId) depositIsInState(_depositId, DepositState.ReadyForWithdrawal) {
        require(deposits[_depositId].depositor == msg.sender, "QuantumVault: Only depositor can execute withdrawal");

        Deposit storage deposit = deposits[_depositId];
        DepositState oldState = deposit.state;
        deposit.state = DepositState.Withdrawn;

        if (deposit.tokenAddress == address(0)) {
            // Transfer ETH
            (bool success,) = payable(deposit.depositor).call{value: deposit.amount}("");
            require(success, "QuantumVault: ETH transfer failed");
        } else {
            // Transfer ERC20
            IERC20 token = IERC20(deposit.tokenAddress);
            token.safeTransfer(deposit.depositor, deposit.amount);
        }

        emit WithdrawalExecuted(_depositId, deposit.depositor, deposit.tokenAddress, deposit.amount);
        emit DepositStateChanged(_depositId, DepositState.Withdrawn, oldState);
    }

    // --- Failure & Cleanup Functions (1 Function) ---

    /// @notice Allows marking a deposit as failed if its conditions cannot be met,
    /// e.g., after a deadline has passed. Anyone can call this.
    /// Funds remain locked forever unless emergencyRelease is used.
    /// @param _depositId The ID of the deposit.
    function markDepositFailed(uint256 _depositId) external depositExists(_depositId) depositIsInState(_depositId, DepositState.Locked) {
        Deposit storage deposit = deposits[_depositId];

        bool canPossiblyMeet = false;
        // This check is complex and potentially gas-intensive or incomplete.
        // A robust implementation would need to assess if *any* remaining
        // condition is still theoretically possible to be met.
        // For simplicity, we'll check the deadline if set.
        if (deposit.deadlineForConditions > 0 && block.timestamp > deposit.deadlineForConditions) {
             canPossiblyMeet = false; // Deadline passed, can't meet time/block conditions after this
             // Note: This doesn't perfectly capture impossibility for *all* condition types
             // e.g., external state might still change, oracle price might still move.
             // A truly robust check requires specific logic per condition type.
        } else {
             // If no deadline, or deadline not passed, assume it's potentially still possible.
             // More complex logic needed for other condition types.
             // For this example, we only auto-fail based on deadline.
             revert("QuantumVault: Conditions potentially still met or no deadline passed");
        }


        require(!canPossiblyMeet, "QuantumVault: Conditions can potentially still be met");

        DepositState oldState = deposit.state;
        deposit.state = DepositState.FailedConditions;
        emit DepositMarkedFailed(_depositId);
        emit DepositStateChanged(_depositId, DepositState.FailedConditions, oldState);

        // Note: Funds are now permanently locked unless owner uses emergencyRelease.
        // An alternative could be to return funds to depositor after a long grace period.
    }


    // --- Query Functions (6 Functions) ---

    /// @notice Gets all details for a specific deposit.
    /// @param _depositId The ID of the deposit.
    /// @return The Deposit struct.
    function getDepositDetails(uint256 _depositId) external view depositExists(_depositId) returns (Deposit memory) {
        return deposits[_depositId];
    }

    /// @notice Gets the current state of a specific deposit.
    /// @param _depositId The ID of the deposit.
    /// @return The DepositState enum value.
    function getDepositState(uint256 _depositId) external view depositExists(_depositId) returns (DepositState) {
        return deposits[_depositId].state;
    }


    /// @notice Lists the deposit IDs associated with a user.
    /// Note: This can be gas-intensive for users with many deposits.
    /// @param _user The user's address.
    /// @return An array of deposit IDs.
    function getUserDeposits(address _user) external view returns (uint256[] memory) {
        return userDeposits[_user];
    }

    /// @notice Gets the total value locked in the vault across all deposits.
    /// Note: This loops through all deposits and can be very gas-intensive.
    /// A more efficient approach for production is to track totals in a mapping on state changes.
    /// @return Total amount of ETH and a mapping of total ERC20 amounts.
    function getTotalLockedValue() external view returns (uint256 totalEth, mapping(address => uint256) memory totalErc20) {
        totalErc20 = new mapping(address => uint256)(); // Create a temporary memory mapping
        for (uint256 i = 1; i <= depositCounter; i++) {
            Deposit storage deposit = deposits[i];
            // Only count funds in Locked or ReadyForWithdrawal states
            if (deposit.state == DepositState.Locked || deposit.state == DepositState.ReadyForWithdrawal) {
                if (deposit.tokenAddress == address(0)) {
                    totalEth = totalEth.add(deposit.amount);
                } else {
                    totalErc20[deposit.tokenAddress] = totalErc20[deposit.tokenAddress].add(deposit.amount);
                }
            }
        }
        return (totalEth, totalErc20);
    }

    /// @notice Gets the reputation score for a user.
    /// @param _user The user's address.
    /// @return The reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return userProfiles[_user].reputation;
    }

    /// @notice Calculates the potential fee for a deposit.
    /// @param _tokenAddress The token address (address(0) for ETH).
    /// @param _amount The deposit amount.
    /// @return The calculated fee amount.
    function calculateDepositFee(address _tokenAddress, uint256 _amount) public view returns (uint256) {
        if (depositFeeBasisPoints == 0) {
            return 0;
        }
        // Calculate fee: amount * fee_rate / 10000
        // Use _amount directly, as fee is taken *before* amount is locked.
        return _amount.mul(depositFeeBasisPoints).div(10000);
    }

    // --- Reputation Management (Internal + Query) (1 Function) ---
    // Query function covered by getUserReputation (already counted).
    // Internal calculation function:

    /// @notice Internal function to calculate reputation gain based on deposit parameters.
    /// Simple model: reputation = sqrt(amount) * (lock duration in seconds / 1 day) / factor
    /// Adjust factor based on desired reputation scale.
    /// @param _amount The amount of the deposit.
    /// @param _depositTimestamp The timestamp of the deposit.
    /// @param _conditionsMetTimestamp The timestamp when conditions were met.
    /// @return The calculated reputation points.
    function _calculateReputationGain(uint256 _amount, uint256 _depositTimestamp, uint256 _conditionsMetTimestamp) internal pure returns (uint256) {
        if (_amount == 0 || _conditionsMetTimestamp <= _depositTimestamp) {
            return 0;
        }
        uint256 lockDuration = _conditionsMetTimestamp.sub(_depositTimestamp);
        // Simple estimation: 1 day = 86400 seconds
        uint256 lockDays = lockDuration.div(86400); // Integer division, rounds down

        // Prevent division by zero if lockDays is 0 (very short lockup)
        if (lockDays == 0) {
             lockDays = 1; // Assume minimum 1 day equivalent for any gain
        }

        // Reputation = (sqrt(amount) / 1e9) * lockDays / 100 (example scaling)
        // Need to approximate sqrt on chain, or simplify formula.
        // Let's use a simpler linear model with amount and duration.
        // Reputation = (amount / 1e18) * (lockDuration / 1 day) / SCALING_FACTOR
        // Use a scaling factor to keep numbers manageable.
        uint256 SCALING_FACTOR = 100; // Adjust this to scale reputation points

        // To avoid large number issues and approximate value:
        // Consider _amount in token decimals. For ETH (18 decimals), amount / 1e18 gives ETH amount.
        // For simplicity, let's use amount directly and a larger scaling factor.
        // Reputation = (amount / 1e10) * lockDays / 100 -> rough equivalent of (ETH amount / 10) * lockDays / 100

        uint256 amountFactor = _amount.div(1e10); // Reduces magnitude for calculation
        uint256 reputation = amountFactor.mul(lockDays).div(SCALING_FACTOR);

        return reputation;
    }

    // --- Fee Management & Collection (2 Functions) ---

    /// @notice Gets the total collected fees for a specific token.
    /// @param _tokenAddress The token address (address(0) for ETH).
    /// @return The total collected fee amount.
    function getProtocolFeesCollected(address _tokenAddress) external view returns (uint256) {
        return protocolFeesCollected[_tokenAddress];
    }

    /// @notice Allows the owner to withdraw collected fees for a specific token.
    /// @param _tokenAddress The token address (address(0) for ETH).
    function withdrawProtocolFees(address _tokenAddress) external onlyOwner {
        uint256 amount = protocolFeesCollected[_tokenAddress];
        require(amount > 0, "QuantumVault: No fees collected for this token");

        protocolFeesCollected[_tokenAddress] = 0; // Reset collected fees

        if (_tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success,) = protocolFeeRecipient.call{value: amount}("");
            require(success, "QuantumVault: Fee withdrawal failed (ETH)");
        } else {
            // Withdraw ERC20
            IERC20 token = IERC20(_tokenAddress);
            token.safeTransfer(protocolFeeRecipient, amount);
        }

        emit ProtocolFeesWithdrawn(_tokenAddress, amount, protocolFeeRecipient);
    }


    // --- Admin/Owner Functions (7 Functions) ---

    /// @notice Sets the deposit fee percentage in basis points (100 = 1%).
    /// @param _newFeeBasisPoints The new fee rate (0-10000).
    function setDepositFeeBasisPoints(uint256 _newFeeBasisPoints) external onlyOwner {
        require(_newFeeBasisPoints <= 10000, "QuantumVault: Fee basis points cannot exceed 10000 (100%)");
        depositFeeBasisPoints = _newFeeBasisPoints;
        emit DepositFeeUpdated(_newFeeBasisPoints);
    }

     /// @notice Sets the recipient address for collected protocol fees.
     /// @param _newRecipient The new fee recipient address.
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "QuantumVault: Fee recipient cannot be zero address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }


    /// @notice Adds an ERC20 token to the list of allowed tokens for deposits.
    /// @param _tokenAddress The address of the token.
    function addAllowedToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "QuantumVault: Cannot add zero address");
        require(!isAllowedToken[_tokenAddress], "QuantumVault: Token already allowed");
        isAllowedToken[_tokenAddress] = true;
        emit AllowedTokenAdded(_tokenAddress);
    }

    /// @notice Removes an ERC20 token from the list of allowed tokens.
    /// @param _tokenAddress The address of the token.
    function removeAllowedToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "QuantumVault: Cannot remove zero address");
        require(isAllowedToken[_tokenAddress], "QuantumVault: Token is not allowed");
        isAllowedToken[_tokenAddress] = false;
        emit AllowedTokenRemoved(_tokenAddress);
    }

    /// @notice Sets the address for a specific oracle key string.
    /// @param _key The string key for the oracle (e.g., "ETH/USD").
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(string calldata _key, address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "QuantumVault: Oracle address cannot be zero address");
        // Add key to array if new, for listing purposes
        if (oracleAddresses[_key] == address(0)) {
            oracleKeys.push(_key);
        }
        oracleAddresses[_key] = _oracleAddress;
        emit OracleAddressSet(_key, _oracleAddress);
    }

    /// @notice Allows the owner to emergency release funds from a deposit.
    /// Use with extreme caution! Bypasses all conditions.
    /// @param _depositId The ID of the deposit.
    /// @param _recipient The address to send the funds to.
    function emergencyRelease(uint256 _depositId, address _recipient) external onlyOwner depositExists(_depositId) {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.state != DepositState.Withdrawn && deposit.state != DepositState.EmergencyReleased, "QuantumVault: Deposit already withdrawn or released");
        require(_recipient != address(0), "QuantumVault: Recipient cannot be zero address");

        DepositState oldState = deposit.state;
        deposit.state = DepositState.EmergencyReleased;

        if (deposit.tokenAddress == address(0)) {
            // Transfer ETH
            (bool success,) = payable(_recipient).call{value: deposit.amount}("");
            require(success, "QuantumVault: Emergency release failed (ETH)");
        } else {
            // Transfer ERC20
            IERC20 token = IERC20(deposit.tokenAddress);
            token.safeTransfer(_recipient, deposit.amount);
        }

        emit EmergencyReleaseExecuted(_depositId, _recipient);
        emit DepositStateChanged(_depositId, DepositState.EmergencyReleased, oldState);
    }

    /// @notice Allows the owner to sweep accidentally sent ETH or tokens not associated with a deposit.
    /// Be cautious with this function.
    /// @param _tokenAddress The token address (address(0) for ETH).
    function sweepStuckFunds(address _tokenAddress) external onlyOwner {
         uint256 balance;
         if (_tokenAddress == address(0)) {
             balance = address(this).balance.sub(protocolFeesCollected[address(0)]); // Don't sweep protocol fees
             (bool success,) = payable(owner()).call{value: balance}("");
             require(success, "QuantumVault: ETH sweep failed");
         } else {
             IERC20 token = IERC20(_tokenAddress);
             balance = token.balanceOf(address(this)).sub(protocolFeesCollected[_tokenAddress]); // Don't sweep protocol fees
             token.safeTransfer(owner(), balance);
         }
         // No specific event for this, standard token transfer event would suffice if available
    }


    // --- Pausable Functions (2 Functions) ---

    /// @notice Pauses the contract. Only owner can call.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Only owner can call.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Additional Query Functions (3 Functions) ---

    /// @notice Gets the total number of deposits created.
    /// @return The deposit counter value.
    function getDepositCount() external view returns (uint256) {
        return depositCounter;
    }

    /// @notice Lists all oracle keys that have addresses set.
    /// @return An array of oracle key strings.
    function listOracleKeys() external view returns (string[] memory) {
        return oracleKeys;
    }

     /// @notice Lists all allowed ERC20 token addresses.
     /// Note: This requires iterating a mapping which is not directly possible.
     /// For simplicity, this function is not implemented dynamically based on `isAllowedToken`.
     /// A real-world solution would use a dynamic array or linked list for allowed tokens.
     /// This is a placeholder or indicates the need for off-chain tracking or a different state structure.
     // function listAllowedTokens() external view returns (address[] memory) { ... }

    // For the sake of reaching 20+ functions and demonstrating querying,
    // let's add some simple view functions about counts/settings.

    /// @notice Gets the current deposit fee in basis points.
    function getDepositFeeBasisPoints() external view returns (uint256) {
        return depositFeeBasisPoints;
    }

    /// @notice Gets the address of the protocol fee recipient.
    function getProtocolFeeRecipient() external view returns (address) {
        return protocolFeeRecipient;
    }

    /// @notice Checks if a token is allowed for deposits.
    /// @param _tokenAddress The token address.
    /// @return True if the token is allowed, false otherwise.
    function checkIsAllowedToken(address _tokenAddress) external view returns (bool) {
        return isAllowedToken[_tokenAddress];
    }

    // Total functions: 28+ functions (depositETH, depositERC20, addCondition, updateCondition, removeCondition, checkConditionStatus, areAllConditionsMet, proveConditionMet, initiateWithdrawal, executeWithdrawal, markDepositFailed, getDepositDetails, getDepositState, getUserDeposits, getTotalLockedValue, getUserReputation, calculateDepositFee, getProtocolFeesCollected, withdrawProtocolFees, setDepositFeeBasisPoints, setProtocolFeeRecipient, addAllowedToken, removeAllowedToken, setOracleAddress, emergencyRelease, sweepStuckFunds, pause, unpause, getDepositCount, listOracleKeys, getDepositFeeBasisPoints, getProtocolFeeRecipient, checkIsAllowedToken) -> Yes, definitely over 20.
}
```

---

**Explanation of Advanced Concepts & Design Choices:**

1.  **Multi-criteria Conditional Release:** Unlike simple time locks, this contract allows combining multiple conditions (`Condition[]`) that must *all* be met (`areAllConditionsMet`). The conditions can be time-based, block-based, dependent on the boolean state of *another* arbitrary contract (`ExternalBoolStateEQ`), or based on oracle price feeds (`OraclePriceGTE`, `OraclePriceLTE`). This provides flexibility for escrow scenarios tied to external events or markets.
2.  **Diverse Condition Types:** The `ConditionType` enum and `Condition` struct are designed to be extensible. While only a few types are implemented, you could add more (e.g., `ERC20BalanceGTE`, `NFTOwnershipEQ`, `ExternalUintStateGTE`, etc.) by extending the `checkConditionStatus` function logic.
3.  **Oracle Integration:** Includes a basic `IPriceOracle` interface and a mapping `oracleAddresses` to integrate with external data feeds (like Chainlink Price Feeds or custom oracles). This moves beyond purely internal contract state.
4.  **Reputation System:** A simple `UserProfile` with a `reputation` score is introduced. Reputation is earned upon successfully initiating a withdrawal, proportional to the deposit amount and the lock duration (`_calculateReputationGain`). This adds a social/gamified element and could be used in future versions for governance weight, fee discounts, or other perks.
5.  **Dynamic Fees & Protocol Revenue:** A `depositFeeBasisPoints` state variable allows the owner to set a fee percentage. This fee is calculated and sent to a `protocolFeeRecipient` on deposit. This creates a mechanism for protocol revenue, distinguishing it from a purely trustless escrow where no value accrues to the platform.
6.  **State Machine:** Deposits follow a state machine (`DepositState`): `Locked` -> `ReadyForWithdrawal` -> `Withdrawn`. `FailedConditions` and `EmergencyReleased` are terminal states outside the normal flow. This structure ensures operations happen in the correct sequence.
7.  **"Prove" Function:** `proveConditionMet` allows anyone (not just the depositor) to check the status of a specific condition and emit an event. This is useful for off-chain monitoring and could be extended to update a cached `isMet` flag within the `Condition` struct for gas efficiency if many checks are needed, though this adds complexity to state consistency.
8.  **Failure State (`markDepositFailed`):** Introduces a mechanism to handle cases where conditions become impossible to meet (currently only based on an optional `deadlineForConditions`). This is important for clarity on the status of locked funds that are otherwise stuck indefinitely.
9.  **Emergency Release (`emergencyRelease`):** A powerful owner-only function to bypass conditions and release funds. This acts as a "break glass" mechanism for unforeseen circumstances (e.g., critical oracle failure, bug in linked contract, legal requirements), adding a layer of central control for emergencies.
10. **Gas Considerations:** Note that functions looping through arrays or mappings (`areAllConditionsMet`, `getUserDeposits`, `getTotalLockedValue`, `listOracleKeys`) can become very expensive on gas as the number of conditions or deposits grows. A production system might use different data structures (e.g., linked lists for conditions or allowed tokens), off-chain indexing for queries, or aggregate state variables updated incrementally to mitigate this. This example prioritizes illustrating concepts and function count.

This contract offers a more complex and feature-rich approach to asset locking compared to basic escrow or time-lock contracts by incorporating external dependencies, dynamic parameters, reputation, and explicit failure handling.