Okay, let's design a smart contract that incorporates several advanced, creative, and interconnected concepts:

1.  **Multi-dimensional Vault Positions:** Assets (ETH and ERC20s) are locked into specific "positions," each with its own set of unlock conditions.
2.  **Complex, Rule-Based Unlock:** Unlocking funds requires satisfying multiple, configurable rules attached to a position.
3.  **Simulated "Quantum State" Resolution:** One type of unlock rule can depend on external data provided by an oracle, simulating resolution of an unknown or complex state. This data must match predefined criteria set during position creation.
4.  **Reputation System:** Users (position owners or participants) have a reputation score within the contract, which can influence unlock conditions (e.g., minimum reputation required) or even dynamic fees.
5.  **Dynamic Fees:** Fees for unlocking can vary based on factors like the time elapsed since the initial lock expiry and the user's reputation.
6.  **Modular Rules:** Rules are represented by types, allowing the owner to add or configure different types of conditions without changing the core vault logic (within the limits of the predefined rule types in the enum).

We'll call this contract `QuantumVault`. It doesn't replicate specific open-source protocols like Uniswap, Compound, or standard NFT/ERC20 factories, but builds a novel vault/locking mechanism with layered complexity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Outline and Function Summary ---
//
// Contract Name: QuantumVault
// Description: A complex, multi-position vault where assets (ETH and ERC20)
// are locked and can only be unlocked by satisfying a set of configurable,
// rule-based conditions attached to each position. Features include a
// reputation system, dynamic unlock fees, and simulation of external
// 'quantum state' resolution via oracle interaction.
//
// Key Concepts:
// - Position-based locking: Assets are tied to specific vault positions.
// - Rule-based unlock: Each position has multiple rules that must evaluate to true.
// - Simulated "Quantum State": Unlock can depend on external data provided by a trusted oracle.
// - Reputation System: Internal reputation affects unlock conditions and fees.
// - Dynamic Fees: Unlock fees adjusted based on time and reputation.
//
// State Variables:
// - owner: Contract owner (from Ownable).
// - paused: Pausing state (from Pausable).
// - positions: Mapping from position ID to Position struct.
// - nextPositionId: Counter for unique position IDs.
// - positionCountByOwner: Mapping from owner address to array of their position IDs.
// - reputations: Mapping from user address to their reputation score (int).
// - reputationThreshold: Minimum reputation often required for actions.
// - oracleAddress: Address of the trusted oracle for state resolution rules.
// - ruleTypeConfigs: Configuration data for different rule types.
// - baseUnlockFee: Base fee percentage for unlocking.
// - feeReputationMultiplier: How reputation affects fee calculation.
// - feeTimePenaltyRate: How time elapsed since expiry affects fee.
// - collectedFees: Mapping from token address (0 for ETH) to collected fee amounts.
//
// Structs:
// - Position: Defines a locked position with owner, lock time, required reputation,
//             assets held (mapping token -> amount), and attached rule evaluations.
// - RuleEvaluation: Tracks the state and parameters of a specific unlock rule for a position.
//
// Enums:
// - RuleType: Defines different types of unlock conditions.
// - RuleStatus: Tracks the evaluation status of a rule (Pending, Passed, Failed).
//
// Events:
// - PositionCreated: Logged when a new position is created.
// - DepositedIntoPosition: Logged when assets are deposited into a position.
// - WithdrewFromPosition: Logged when assets are withdrawn from a position.
// - UnlockRuleConfigured: Logged when a rule is added/configured for a position.
// - RuleEvaluationTriggered: Logged when a complex rule evaluation starts.
// - RuleStatusUpdated: Logged when a rule's evaluation status changes.
// - ReputationUpdated: Logged when a user's reputation changes.
// - FeeParametersUpdated: Logged when dynamic fee parameters are set.
// - FeesSwept: Logged when owner collects fees.
// - EmergencyWithdraw: Logged when owner withdraws stuck tokens.
//
// Modifiers:
// - onlyOwner: Only the contract owner can call (from Ownable).
// - whenNotPaused: Only when the contract is not paused (from Pausable).
// - whenPaused: Only when the contract is paused (from Pausable).
// - nonReentrant: Prevents reentrant calls (from ReentrancyGuard).
//
// Functions (Total: 30+):
//
// Core Vault / Position Management:
// 1. constructor(uint initialReputationThreshold, uint initialBaseFee, uint initialFeeReputationMultiplier, uint initialFeeTimePenaltyRate): Initializes the contract.
// 2. createPosition(uint initialLockDuration, uint minReputationRequired) external whenNotPaused nonReentrant returns (uint positionId): Creates a new empty position.
// 3. depositETHIntoPosition(uint positionId) external payable whenNotPaused nonReentrant: Deposits ETH into a specific position.
// 4. depositERC20IntoPosition(uint positionId, address token, uint amount) external whenNotPaused nonReentrant: Deposits ERC20 into a specific position.
// 5. withdrawETHFromPosition(uint positionId, uint amount) external nonReentrant: Withdraws ETH from a position if unlock conditions are met.
// 6. withdrawERC20FromPosition(uint positionId, address token, uint amount) external nonReentrant: Withdraws ERC20 from a position if unlock conditions are met.
//
// Balance Queries:
// 7. getVaultTotalBalanceETH() public view returns (uint): Total ETH held in the contract.
// 8. getVaultTotalBalanceERC20(address token) public view returns (uint): Total ERC20 held in the contract.
// 9. getPositionBalanceETH(uint positionId) public view returns (uint): ETH balance in a specific position.
// 10. getPositionBalanceERC20(uint positionId, address token) public view returns (uint): ERC20 balance in a specific position.
//
// Rule Configuration & Evaluation:
// 11. configurePositionUnlockRule(uint positionId, RuleType ruleType, bytes ruleData) external onlyOwner returns (uint ruleId): Configures a new rule for a position.
// 12. triggerComplexUnlockEvaluation(uint positionId, uint ruleId, bytes externalData) external nonReentrant: Triggers evaluation for a specific rule using external data (e.g., from oracle).
// 13. getRuleEvaluationStatus(uint positionId, uint ruleId) public view returns (RuleStatus): Gets the current status of a rule evaluation.
// 14. canUnlock(uint positionId) public view returns (bool): Checks if all unlock conditions for a position are met.
// 15. getPositionDetails(uint positionId) public view returns (Position memory): Retrieves details of a position.
// 16. getPositionsByOwner(address owner) public view returns (uint[] memory): Retrieves IDs of all positions owned by an address.
//
// Reputation System:
// 17. updateReputation(address user, int reputationDelta) external onlyOwner: Adjusts a user's reputation score.
// 18. getReputation(address user) public view returns (int): Gets a user's current reputation score.
// 19. setReputationThreshold(uint threshold) external onlyOwner: Sets the global minimum reputation threshold.
//
// Oracle & Rule Type Configuration:
// 20. setOracleAddress(address oracle) external onlyOwner: Sets the trusted oracle address.
// 21. setRuleTypeConfig(RuleType ruleType, bytes configData) external onlyOwner: Sets configuration data for a specific rule type. (e.g., expected hash for OracleDataMatch).
// 22. getRuleTypeConfig(RuleType ruleType) public view returns (bytes memory): Retrieves config data for a rule type.
//
// Dynamic Fees:
// 23. setFeeParameters(uint baseFee, uint reputationMultiplier, uint timePenaltyRate) external onlyOwner: Sets parameters for dynamic fee calculation.
// 24. getCalculatedUnlockFee(uint positionId, uint amount) public view returns (uint feeAmount): Calculates the potential unlock fee for a specific amount.
// 25. sweepFees(address token) external onlyOwner: Allows the owner to withdraw collected fees.
//
// Access Control and Utility (from inherited contracts & custom):
// 26. transferOwnership(address newOwner) external onlyOwner: Transfers ownership.
// 27. renounceOwnership() external onlyOwner: Renounces ownership.
// 28. pause() external onlyOwner whenNotPaused: Pauses the contract.
// 29. unpause() external onlyOwner whenPaused: Unpauses the contract.
// 30. emergencyWithdrawStuckERC20(address token, uint amount) external onlyOwner nonReentrant: Allows owner to rescue accidentally sent ERC20s.
// 31. updatePositionMinReputation(uint positionId, uint newMinReputation) external onlyOwner: Allows owner to adjust min reputation for a position.
// 32. updatePositionLockTime(uint positionId, uint newLockUntil) external onlyOwner: Allows owner to adjust lock time for a position.
//
// Note: Some functions might be internal helpers not listed here. The focus is on public/external interface count.
// Total external/public functions listed: 32 (more than 20 required).

// --- Contract Implementation ---

// Represents different types of unlock conditions
enum RuleType {
    None, // Default or invalid type
    MinReputation, // Requires the user's reputation to be above a threshold
    AfterTime, // Requires current time to be after a specific timestamp
    BeforeTime, // Requires current time to be before a specific timestamp
    OracleDataMatch, // Requires external data from oracle to match configured value (simulated quantum state resolution)
    QuantumStateResolved // Requires a specific 'quantum state' rule type to have passed evaluation
    // Add more complex rule types here as needed
}

// Represents the evaluation status of a rule for a position
enum RuleStatus {
    Pending, // Rule evaluation not yet completed or triggered
    Passed,  // Rule conditions met
    Failed   // Rule conditions not met
}

// Stores parameters and status for a specific rule attached to a position
struct RuleEvaluation {
    RuleType ruleType;
    bytes configData;   // Data specific to the rule type (e.g., reputation threshold, timestamp, hash)
    RuleStatus status; // Current evaluation status
    bytes evaluationData; // Data used for the evaluation (e.g., oracle response)
}

// Represents a single locked position in the vault
struct Position {
    address owner;
    uint creationTime;   // When the position was created
    uint lockedUntil;    // Minimum time until funds can potentially be unlocked
    uint minReputationRequired; // Minimum reputation needed for unlock eligibility
    mapping(address => uint) assets; // Assets held within this specific position (token address => amount)
    uint nextRuleId;      // Counter for unique rule IDs within this position
    mapping(uint => RuleEvaluation) rules; // Rules attached to this position (rule ID => RuleEvaluation)
    uint[] ruleIds; // Array of rule IDs for easy iteration
}

contract QuantumVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    uint public nextPositionId = 1; // Start from 1 to avoid default 0
    mapping(uint => Position) public positions;
    mapping(address => uint[]) private positionCountByOwner; // Map owner address to array of their position IDs

    mapping(address => int) public reputations; // User address => reputation score
    uint public reputationThreshold; // Global minimum reputation setting

    address public oracleAddress; // Address of the trusted oracle

    // Configuration data for different rule types (e.g., expected hash for OracleDataMatch)
    mapping(RuleType => bytes) public ruleTypeConfigs;

    uint public baseUnlockFee; // Base percentage fee (e.g., 100 = 1%)
    uint public feeReputationMultiplier; // Higher = reputation reduces fee more
    uint public feeTimePenaltyRate; // Higher = fee increases faster after lock expiry

    mapping(address => uint) private collectedFees; // Token address (0 for ETH) => collected amount

    // --- Events ---
    event PositionCreated(uint indexed positionId, address indexed owner, uint initialLockDuration, uint minReputationRequired);
    event DepositedIntoPosition(uint indexed positionId, address indexed token, uint amount, address indexed depositor);
    event WithdrewFromPosition(uint indexed positionId, address indexed token, uint amount, uint feeAmount, address indexed recipient);
    event UnlockRuleConfigured(uint indexed positionId, uint indexed ruleId, RuleType ruleType);
    event RuleEvaluationTriggered(uint indexed positionId, uint indexed ruleId, bytes externalData);
    event RuleStatusUpdated(uint indexed positionId, uint indexed ruleId, RuleStatus newStatus);
    event ReputationUpdated(address indexed user, int oldReputation, int newReputation);
    event FeeParametersUpdated(uint baseFee, uint reputationMultiplier, uint timePenaltyRate);
    event FeesSwept(address indexed token, uint amount, address indexed collector);
    event EmergencyWithdraw(address indexed token, uint amount, address indexed recipient);
    event OracleAddressUpdated(address indexed newOracle);
    event RuleTypeConfigUpdated(RuleType indexed ruleType, bytes configData);

    // --- Constructor ---
    constructor(
        uint initialReputationThreshold,
        uint initialBaseFee,
        uint initialFeeReputationMultiplier,
        uint initialFeeTimePenaltyRate
    ) Ownable(msg.sender) {
        reputationThreshold = initialReputationThreshold;
        baseUnlockFee = initialBaseFee;
        feeReputationMultiplier = initialFeeReputationMultiplier;
        feeTimePenaltyRate = initialFeeTimePenaltyRate;
    }

    // --- Core Vault / Position Management ---

    /// @notice Creates a new empty vault position for the caller.
    /// @param initialLockDuration The duration in seconds the position is initially locked from creation time.
    /// @param minReputationRequired The minimum reputation score required for this specific position's owner to unlock.
    /// @return positionId The ID of the newly created position.
    function createPosition(uint initialLockDuration, uint minReputationRequired)
        external
        whenNotPaused
        nonReentrant
        returns (uint positionId)
    {
        positionId = nextPositionId++;
        uint lockUntil = block.timestamp + initialLockDuration;

        positions[positionId] = Position({
            owner: msg.sender,
            creationTime: block.timestamp,
            lockedUntil: lockUntil,
            minReputationRequired: minReputationRequired,
            assets: new mapping(address => uint), // Initialize the nested mapping
            nextRuleId: 1,
            rules: new mapping(uint => RuleEvaluation), // Initialize the nested mapping
            ruleIds: new uint[](0) // Initialize dynamic array
        });

        positionCountByOwner[msg.sender].push(positionId);

        emit PositionCreated(positionId, msg.sender, initialLockDuration, minReputationRequired);
    }

    /// @notice Deposits ETH into a specific vault position.
    /// @param positionId The ID of the position to deposit into.
    function depositETHIntoPosition(uint positionId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(positions[positionId].owner != address(0), "Position does not exist");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // ETH balance is tracked within the position's assets mapping (address(0) for ETH)
        positions[positionId].assets[address(0)] += msg.value;

        emit DepositedIntoPosition(positionId, address(0), msg.value, msg.sender);
    }

    /// @notice Deposits ERC20 tokens into a specific vault position.
    /// @param positionId The ID of the position to deposit into.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20IntoPosition(uint positionId, address token, uint amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(positions[positionId].owner != address(0), "Position does not exist");
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Deposit amount must be greater than zero");

        IERC20 erc20 = IERC20(token);

        // Transfer tokens from the sender to the contract
        erc20.safeTransferFrom(msg.sender, address(this), amount);

        // Update the position's asset balance
        positions[positionId].assets[token] += amount;

        emit DepositedIntoPosition(positionId, token, amount, msg.sender);
    }

    /// @notice Attempts to withdraw ETH from a position. Requires all unlock conditions to be met.
    /// @param positionId The ID of the position to withdraw from.
    /// @param amount The amount of ETH to withdraw.
    function withdrawETHFromPosition(uint positionId, uint amount)
        external
        nonReentrant
    {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        require(msg.sender == pos.owner, "Not position owner");
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(pos.assets[address(0)] >= amount, "Insufficient ETH in position");

        // Check all unlock conditions
        require(canUnlock(positionId), "Unlock conditions not met");

        // Calculate and collect fee
        uint feeAmount = getCalculatedUnlockFee(positionId, amount);
        uint netAmount = amount - feeAmount;

        pos.assets[address(0)] -= amount;
        collectedFees[address(0)] += feeAmount;

        // Send ETH to the owner
        (bool success, ) = payable(pos.owner).call{value: netAmount}("");
        require(success, "ETH transfer failed");

        emit WithdrewFromPosition(positionId, address(0), netAmount, feeAmount, pos.owner);
    }

    /// @notice Attempts to withdraw ERC20 tokens from a position. Requires all unlock conditions to be met.
    /// @param positionId The ID of the position to withdraw from.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20FromPosition(uint positionId, address token, uint amount)
        external
        nonReentrant
    {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        require(msg.sender == pos.owner, "Not position owner");
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(pos.assets[token] >= amount, "Insufficient tokens in position");

        // Check all unlock conditions
        require(canUnlock(positionId), "Unlock conditions not met");

        // Calculate and collect fee
        uint feeAmount = getCalculatedUnlockFee(positionId, amount);
        uint netAmount = amount - feeAmount;

        pos.assets[token] -= amount;
        collectedFees[token] += feeAmount;

        // Transfer tokens to the owner
        IERC20(token).safeTransfer(pos.owner, netAmount);

        emit WithdrewFromPosition(positionId, token, netAmount, feeAmount, pos.owner);
    }

    // --- Balance Queries ---

    /// @notice Gets the total amount of ETH held across all positions in the vault.
    /// @return Total ETH balance.
    function getVaultTotalBalanceETH() public view returns (uint) {
        return address(this).balance;
    }

    /// @notice Gets the total amount of a specific ERC20 token held across all positions in the vault.
    /// @param token The address of the ERC20 token.
    /// @return Total token balance.
    function getVaultTotalBalanceERC20(address token) public view returns (uint) {
         if (token == address(0)) return 0; // ETH handled by getVaultTotalBalanceETH
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Gets the amount of ETH held within a specific position.
    /// @param positionId The ID of the position.
    /// @return The ETH balance in the position.
    function getPositionBalanceETH(uint positionId) public view returns (uint) {
        require(positions[positionId].owner != address(0), "Position does not exist");
        return positions[positionId].assets[address(0)];
    }

    /// @notice Gets the amount of a specific ERC20 token held within a specific position.
    /// @param positionId The ID of the position.
    /// @param token The address of the ERC20 token.
    /// @return The token balance in the position.
    function getPositionBalanceERC20(uint positionId, address token) public view returns (uint) {
        require(positions[positionId].owner != address(0), "Position does not exist");
        require(token != address(0), "Invalid token address");
        return positions[positionId].assets[token];
    }

    // --- Rule Configuration & Evaluation ---

    /// @notice Configures a new unlock rule for a specific position. Only owner can add rules.
    /// @param positionId The ID of the position.
    /// @param ruleType The type of the rule to configure.
    /// @param ruleData Configuration data specific to the rule type.
    /// @return ruleId The ID of the newly configured rule within the position.
    function configurePositionUnlockRule(uint positionId, RuleType ruleType, bytes memory ruleData)
        external
        onlyOwner
        returns (uint ruleId)
    {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        require(ruleType != RuleType.None, "Invalid rule type");

        ruleId = pos.nextRuleId++;

        pos.rules[ruleId] = RuleEvaluation({
            ruleType: ruleType,
            configData: ruleData,
            status: RuleStatus.Pending, // Rules start as pending evaluation
            evaluationData: "" // Empty initially
        });
        pos.ruleIds.push(ruleId);

        emit UnlockRuleConfigured(positionId, ruleId, ruleType);
    }

    /// @notice Triggers the evaluation process for a specific rule, potentially using external data.
    /// Only the oracle address can provide data for OracleDataMatch rules.
    /// @param positionId The ID of the position.
    /// @param ruleId The ID of the rule within the position.
    /// @param externalData Data provided for the evaluation (e.g., oracle response, timestamp).
    function triggerComplexUnlockEvaluation(uint positionId, uint ruleId, bytes memory externalData)
        external
        nonReentrant
    {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        RuleEvaluation storage rule = pos.rules[ruleId];
        require(rule.ruleType != RuleType.None, "Rule does not exist");

        // Check permissions based on rule type
        if (rule.ruleType == RuleType.OracleDataMatch || rule.ruleType == RuleType.QuantumStateResolved) {
            require(msg.sender == oracleAddress, "Only oracle can trigger this rule type evaluation");
        } else if (rule.ruleType == RuleType.AfterTime || rule.ruleType == RuleType.BeforeTime) {
             // Anyone can trigger time-based checks (evaluation uses block.timestamp)
             // No externalData strictly needed, but included for generic interface
        } else if (rule.ruleType == RuleType.MinReputation) {
            // Reputation check is simple, can be evaluated anytime.
            // No externalData strictly needed.
        }
        // Add checks for other rule types

        rule.evaluationData = externalData; // Store the data used for evaluation
        RuleStatus oldStatus = rule.status;
        rule.status = _evaluateRule(pos, ruleId, rule.ruleType, rule.configData, externalData);

        if (rule.status != oldStatus) {
             emit RuleStatusUpdated(positionId, ruleId, rule.status);
        }
        emit RuleEvaluationTriggered(positionId, ruleId, externalData);
    }

    /// @notice Internal helper to evaluate a rule based on its type and data.
    /// @dev This function implements the core logic for different rule types.
    /// @param pos The position struct.
    /// @param ruleId The ID of the rule.
    /// @param ruleType The type of the rule.
    /// @param configData Configuration data for the rule.
    /// @param evaluationData Data provided during triggerComplexUnlockEvaluation.
    /// @return The evaluation status (Passed or Failed).
    function _evaluateRule(
        Position storage pos,
        uint ruleId,
        RuleType ruleType,
        bytes memory configData,
        bytes memory evaluationData
    ) internal view returns (RuleStatus) {
        if (ruleType == RuleType.MinReputation) {
            // Check if position owner's current reputation meets the configured threshold
            uint requiredRep = abi.decode(configData, (uint));
            return reputations[pos.owner] >= int(requiredRep) ? RuleStatus.Passed : RuleStatus.Failed;

        } else if (ruleType == RuleType.AfterTime) {
            // Check if current time is after the configured timestamp
            uint requiredTime = abi.decode(configData, (uint));
            return block.timestamp >= requiredTime ? RuleStatus.Passed : RuleStatus.Failed;

        } else if (ruleType == RuleType.BeforeTime) {
            // Check if current time is before the configured timestamp
            uint requiredTime = abi.decode(configData, (uint));
            return block.timestamp < requiredTime ? RuleStatus.Passed : RuleStatus.Failed;

        } else if (ruleType == RuleType.OracleDataMatch) {
            // Check if the provided evaluationData matches the configured data
            bytes memory requiredData = abi.decode(configData, (bytes));
            // Simple byte-by-byte comparison (gas intensive for large data)
            if (requiredData.length != evaluationData.length) {
                 return RuleStatus.Failed;
            }
            for (uint i = 0; i < requiredData.length; i++) {
                 if (requiredData[i] != evaluationData[i]) {
                     return RuleStatus.Failed;
                 }
            }
            return RuleStatus.Passed;

        } else if (ruleType == RuleType.QuantumStateResolved) {
             // This rule type assumes a specific 'quantum state' evaluation has occurred.
             // It requires another rule (presumably OracleDataMatch or similar) to have Passed.
             // The configData for this rule type could specify the ID of the dependency rule.
             // For simplicity, let's just check if *any* OracleDataMatch rule for this position has passed.
             bool anyOracleMatchPassed = false;
             for (uint i = 0; i < pos.ruleIds.length; i++) {
                 uint currentRuleId = pos.ruleIds[i];
                 if (pos.rules[currentRuleId].ruleType == RuleType.OracleDataMatch && pos.rules[currentRuleId].status == RuleStatus.Passed) {
                     anyOracleMatchPassed = true;
                     break;
                 }
             }
             return anyOracleMatchPassed ? RuleStatus.Passed : RuleStatus.Failed;
        }
        // Add evaluation logic for other rule types here

        return RuleStatus.Failed; // Default fail for unknown or unsupported types
    }

    /// @notice Gets the current evaluation status of a specific rule for a position.
    /// @param positionId The ID of the position.
    /// @param ruleId The ID of the rule within the position.
    /// @return The RuleStatus (Pending, Passed, Failed).
    function getRuleEvaluationStatus(uint positionId, uint ruleId) public view returns (RuleStatus) {
         require(positions[positionId].owner != address(0), "Position does not exist");
         require(positions[positionId].rules[ruleId].ruleType != RuleType.None, "Rule does not exist");
         return positions[positionId].rules[ruleId].status;
    }


    /// @notice Checks if ALL conditions for unlocking a position are currently met.
    /// This is the primary check before allowing withdrawals.
    /// Conditions:
    /// 1. Current time must be >= lockedUntil timestamp.
    /// 2. Position owner's reputation must be >= minReputationRequired for the position.
    /// 3. ALL rules configured for the position must have status == Passed.
    /// @param positionId The ID of the position to check.
    /// @return True if all conditions are met, false otherwise.
    function canUnlock(uint positionId) public view returns (bool) {
        Position storage pos = positions[positionId];
        if (pos.owner == address(0)) {
            return false; // Position does not exist
        }

        // 1. Check lock time
        if (block.timestamp < pos.lockedUntil) {
            return false;
        }

        // 2. Check minimum reputation
        if (reputations[pos.owner] < int(pos.minReputationRequired)) {
            return false;
        }

        // 3. Check all configured rules
        for (uint i = 0; i < pos.ruleIds.length; i++) {
            uint ruleId = pos.ruleIds[i];
            // Note: Rules that haven't been triggered for evaluation might still be Pending.
            // canUnlock requires them to be Passed.
            if (pos.rules[ruleId].status != RuleStatus.Passed) {
                return false; // At least one rule is not passed
            }
        }

        return true; // All checks passed
    }

    /// @notice Gets the full details of a specific position.
    /// @param positionId The ID of the position.
    /// @return The Position struct details.
    function getPositionDetails(uint positionId) public view returns (Position memory) {
        require(positions[positionId].owner != address(0), "Position does not exist");
        // Note: Mapping 'assets' and nested mapping 'rules' cannot be directly returned.
        // Need separate helper functions if individual asset/rule details per position are needed frequently.
        // For this function, we return a memory copy of the struct *excluding* the nested mappings.
        // Or, we can simulate returning key details and require separate calls for assets/rules.
        // Let's return key details in memory.
        Position storage pos = positions[positionId];
        return Position({
            owner: pos.owner,
            creationTime: pos.creationTime,
            lockedUntil: pos.lockedUntil,
            minReputationRequired: pos.minReputationRequired,
            assets: new mapping(address => uint), // Cannot return mapping, initialize empty in memory
            nextRuleId: pos.nextRuleId,
            rules: new mapping(uint => RuleEvaluation), // Cannot return mapping, initialize empty in memory
            ruleIds: pos.ruleIds // Can return the array of rule IDs
        });
         // Caller would then use getPositionBalanceETH/ERC20 and getRuleEvaluationStatus/details(if added)
         // to get full picture.
    }

    /// @notice Gets the IDs of all positions owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of position IDs.
    function getPositionsByOwner(address owner) public view returns (uint[] memory) {
        return positionCountByOwner[owner];
    }

    // --- Reputation System ---

    /// @notice Updates the reputation score of a user. Only owner can do this.
    /// Reputation can be positive or negative.
    /// @param user The address whose reputation to update.
    /// @param reputationDelta The amount to add to the user's reputation (can be negative).
    function updateReputation(address user, int reputationDelta) external onlyOwner {
        int oldRep = reputations[user];
        int newRep = oldRep + reputationDelta;
        reputations[user] = newRep;
        emit ReputationUpdated(user, oldRep, newRep);
    }

    /// @notice Gets the current reputation score of a user.
    /// @param user The address to query.
    /// @return The user's reputation score.
    function getReputation(address user) public view returns (int) {
        return reputations[user];
    }

    /// @notice Sets the global minimum reputation threshold required for certain actions (e.g., some rule types).
    /// @param threshold The new minimum reputation threshold.
    function setReputationThreshold(uint threshold) external onlyOwner {
        reputationThreshold = threshold;
    }

    // --- Oracle & Rule Type Configuration ---

    /// @notice Sets the address of the trusted oracle contract. Only owner can set.
    /// This oracle is called or interacts with the contract for certain rule evaluations.
    /// @param oracle The address of the oracle contract.
    function setOracleAddress(address oracle) external onlyOwner {
        oracleAddress = oracle;
        emit OracleAddressUpdated(oracle);
    }

    /// @notice Sets or updates the configuration data for a specific rule type.
    /// This allows the owner to define parameters or expected values for rule evaluation.
    /// e.g., for OracleDataMatch, the configData could be a hash the oracle's response must match.
    /// @param ruleType The type of rule to configure.
    /// @param configData The configuration data (bytes).
    function setRuleTypeConfig(RuleType ruleType, bytes memory configData) external onlyOwner {
        require(ruleType != RuleType.None, "Invalid rule type");
        ruleTypeConfigs[ruleType] = configData;
        emit RuleTypeConfigUpdated(ruleType, configData);
    }

    /// @notice Gets the configuration data for a specific rule type.
    /// @param ruleType The type of rule to query.
    /// @return The configuration data (bytes).
    function getRuleTypeConfig(RuleType ruleType) public view returns (bytes memory) {
        require(ruleType != RuleType.None, "Invalid rule type");
        return ruleTypeConfigs[ruleType];
    }


    // --- Dynamic Fees ---

    /// @notice Sets the parameters used to calculate dynamic unlock fees.
    /// Fee formula could be: baseFee + (time elapsed since expiry * timePenaltyRate) - (reputation * reputationMultiplier)
    /// Fees are capped at the withdrawal amount.
    /// @param baseFee Base percentage fee (e.g., 100 = 1%).
    /// @param reputationMultiplier Multiplier for reputation effect on fee (higher = more reduction).
    /// @param timePenaltyRate Multiplier for time elapsed since expiry effect on fee (higher = faster increase).
    function setFeeParameters(uint baseFee, uint reputationMultiplier, uint timePenaltyRate)
        external
        onlyOwner
    {
        baseUnlockFee = baseFee;
        feeReputationMultiplier = reputationMultiplier;
        feeTimePenaltyRate = timePenaltyRate;
        emit FeeParametersUpdated(baseFee, reputationMultiplier, timePenaltyRate);
    }

    /// @notice Calculates the potential unlock fee for a given amount based on current time, position, and owner reputation.
    /// Fee formula: max(0, baseFee% + (time_after_expiry * timePenaltyRate) - (reputation * reputationMultiplier))
    /// Resulting fee is capped at the withdrawal amount.
    /// @param positionId The ID of the position.
    /// @param amount The amount intended to withdraw.
    /// @return The calculated fee amount.
    function getCalculatedUnlockFee(uint positionId, uint amount)
        public
        view
        returns (uint feeAmount)
    {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        require(block.timestamp >= pos.lockedUntil, "Position is still locked by time");
        // Note: This calculation is public, but the actual withdraw still requires canUnlock()

        uint baseFee = (amount * baseUnlockFee) / 10000; // baseFee is in hundredths of a percent (e.g. 100 = 1%)

        // Calculate time penalty component
        uint timePenalty = 0;
        if (block.timestamp > pos.lockedUntil) {
            uint timeElapsedAfterExpiry = block.timestamp - pos.lockedUntil;
            timePenalty = timeElapsedAfterExpiry * feeTimePenaltyRate; // Simple linear penalty
        }

        // Calculate reputation reduction component
        uint reputationReduction = 0;
        int currentReputation = reputations[pos.owner];
        if (currentReputation > 0) { // Only positive reputation reduces fee
             // Be careful with integer overflow for large reputations/multipliers
             // Simple model: reduction = reputation * multiplier
             // More robust: reduction capped or non-linear
             // Let's use a simple model for now, assume multiplier prevents easy overflow
             reputationReduction = uint(currentReputation) * feeReputationMultiplier;
        }

        // Calculate raw fee total
        uint rawFee = 0;
        if (baseFee + timePenalty > reputationReduction) {
             rawFee = baseFee + timePenalty - reputationReduction;
        }
        // else rawFee is 0 if reduction is greater than base+penalty

        // Fee is capped at the withdrawal amount
        feeAmount = rawFee > amount ? amount : rawFee;
    }

    /// @notice Allows the contract owner to withdraw collected fees for a specific token.
    /// @param token The address of the token (address(0) for ETH).
    /// @param amount The amount of fees to sweep.
    function sweepFees(address token, uint amount) external onlyOwner {
        require(collectedFees[token] >= amount, "Insufficient collected fees");
        require(amount > 0, "Amount must be greater than zero");

        collectedFees[token] -= amount;

        if (token == address(0)) {
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }

        emit FeesSwept(token, amount, owner());
    }


    // --- Access Control and Utility ---

    // transferOwnership, renounceOwnership, pause, unpause inherited from Ownable/Pausable

    /// @notice Allows the owner to withdraw ERC20 tokens that were sent directly to the contract address
    /// and are not associated with a specific position or fees. Use with caution.
    /// @param token The address of the ERC20 token to rescue.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdrawStuckERC20(address token, uint amount) external onlyOwner nonReentrant {
        require(token != address(0), "Cannot withdraw ETH with this function");
        require(amount > 0, "Amount must be greater than zero");

        // Check contract balance vs total held in positions and fees
        uint contractBalance = IERC20(token).balanceOf(address(this));
        uint heldInPositions = 0;
        // This requires iterating through all positions - potentially gas-intensive for large number of positions
        // A better design might track total held in a separate sum.
        // For now, loop is acceptable for emergency function.
        for (uint i = 1; i < nextPositionId; i++) {
             if (positions[i].owner != address(0)) { // Check if position exists
                  heldInPositions += positions[i].assets[token];
             }
        }
        uint heldAsFees = collectedFees[token];
        uint unaccountedTokens = contractBalance - heldInPositions - heldAsFees;

        require(unaccountedTokens >= amount, "Amount exceeds unaccounted balance");

        IERC20(token).safeTransfer(owner(), amount);
        emit EmergencyWithdraw(token, amount, owner());
    }

    /// @notice Allows the owner to update the minimum reputation required for a specific position.
    /// @param positionId The ID of the position.
    /// @param newMinReputation The new minimum reputation value.
    function updatePositionMinReputation(uint positionId, uint newMinReputation) external onlyOwner {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        pos.minReputationRequired = newMinReputation;
        // No specific event for this, or add one if needed.
    }

    /// @notice Allows the owner to extend (but not shorten) the lockedUntil time for a specific position.
    /// Useful for resolving issues or granting extensions.
    /// @param positionId The ID of the position.
    /// @param newLockUntil The new lock until timestamp. Must be greater than or equal to the current one.
    function updatePositionLockTime(uint positionId, uint newLockUntil) external onlyOwner {
        Position storage pos = positions[positionId];
        require(pos.owner != address(0), "Position does not exist");
        require(newLockUntil >= pos.lockedUntil, "New lock time must be greater than or equal to current");
        pos.lockedUntil = newLockUntil;
        // No specific event for this, or add one if needed.
    }

    // Optional: Add helper functions to get details about a specific rule within a position
    // function getRuleDetails(uint positionId, uint ruleId) public view returns (RuleEvaluation memory) { ... }
    // function getPositionRuleIds(uint positionId) public view returns (uint[] memory) { ... }

    // Fallback function to receive ETH
    receive() external payable {
        // Optionally handle ETH sent without calling depositETHIntoPosition.
        // Currently, it will just increase the contract's ETH balance but won't be tracked
        // within a specific position unless depositETHIntoPosition is called.
        // Adding a require(msg.sender == address(0)) could reject direct ETH sends not from a position deposit.
    }

    // Fallback function to receive ERC20 (will likely revert without specific handler logic)
    fallback() external payable {
        revert("Fallback not implemented: Consider using depositERC20IntoPosition.");
    }
}
```