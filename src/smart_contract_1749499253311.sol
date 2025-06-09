Okay, here is a smart contract concept I've developed called `QuantumVault`. It's inspired by concepts like quantum superposition, entanglement, and measurement, applying them metaphorically to asset access conditions on the blockchain. It focuses on complex, multi-conditional release of deposited assets, linking states between deposits, and requiring a specific "measurement" step.

This contract aims to be creative by moving beyond simple time locks or single conditions, introducing intertwined conditions and a deliberate state transition trigger. It avoids duplicating common patterns like standard vesting, simple multisigs, or basic NFT staking by building a system where the *interaction* and *combination* of conditions define availability.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title QuantumVault
 * @dev A vault contract enabling multi-conditional asset release, linked deposit states ("entanglement"),
 *      and a required "measurement" step to transition deposit state.
 *      Inspired by quantum mechanics metaphors applied to on-chain asset control.
 */

/**
 * @dev Outline:
 * 1. State Variables & Mappings: Store deposit data, condition types, user deposits, oracles.
 * 2. Enums: Define states for deposits and types for conditions.
 * 3. Structs: Define structures for Deposit and Condition details.
 * 4. Events: Log key actions like deposits, withdrawals, condition changes, state measurements, etc.
 * 5. Modifiers: Access control (onlyOwner, onlyDepositor).
 * 6. Constructor: Initialize owner.
 * 7. Deposit Functions: Allow users to deposit ERC20 and ERC721 tokens.
 * 8. Condition Management Functions: Add, remove, and query conditions linked to deposits.
 * 9. Condition Evaluation Logic: Internal functions to check if specific condition types are met.
 * 10. State Measurement Function: A core function to evaluate conditions and transition deposit state.
 * 11. Withdrawal Functions: Allow withdrawal only after conditions are met and state is measured.
 * 12. Linked Deposit ("Entanglement") Functions: Create dependencies between deposit states.
 * 13. Delegate Access: Allow depositor to grant withdrawal rights to another address.
 * 14. Oracle Integration: Allow trusted parties to report on external conditions.
 * 15. Emergency Break: A time-locked escape hatch.
 * 16. Batch Operations: Withdraw multiple items meeting criteria.
 * 17. Query Functions: Get deposit details, conditions, status, etc.
 * 18. Admin Functions: Owner-only functions for configuration (e.g., adding oracles).
 */

/**
 * @dev Function Summary:
 *
 * State Changing:
 * - depositERC20(address token, uint256 amount, address depositor): Deposit ERC20 tokens.
 * - depositERC721(address token, uint256 tokenId, address depositor): Deposit ERC721 token.
 * - addCondition(uint256 depositId, Condition calldata condition): Add a condition to a deposit.
 * - removeCondition(uint256 depositId, uint256 conditionIndex): Remove a condition from a deposit.
 * - measureState(uint256 depositId): Evaluate conditions and transition deposit state to 'ConditionsMet'.
 * - withdrawERC20(uint256 depositId): Withdraw ERC20 if conditions met and state is 'ConditionsMet'.
 * - withdrawERC721(uint256 depositId): Withdraw ERC721 if conditions met and state is 'ConditionsMet'.
 * - createInternalLink(uint256 sourceDepositId, uint256 targetDepositId): Link source to target within the same vault.
 * - createExternalLink(uint256 sourceDepositId, address targetVault, uint256 targetDepositId): Link source to target in another vault.
 * - delegateWithdrawal(uint256 depositId, address delegatee): Authorize another address to withdraw deposit.
 * - revokeDelegate(uint256 depositId): Revoke delegate authorization.
 * - updateOracleCondition(uint256 depositId, uint256 conditionIndex, bool status): Oracle reports status for a specific condition.
 * - emergencyBreak(): Withdraw all owned deposits after a long time lock (owner only).
 * - batchWithdrawERC20(uint256[] calldata depositIds): Withdraw multiple ERC20 deposits.
 * - batchWithdrawERC721(uint256[] calldata depositIds): Withdraw multiple ERC721 deposits.
 *
 * View/Pure:
 * - getDepositDetails(uint256 depositId): Get details of a deposit.
 * - getDepositConditions(uint256 depositId): Get conditions attached to a deposit.
 * - getDepositState(uint256 depositId): Get the current state of a deposit.
 * - checkConditionsMet(uint256 depositId): Pure check if conditions *would be* met (doesn't change state).
 * - canWithdraw(uint256 depositId): Check if deposit state is 'ConditionsMet' and not withdrawn.
 * - getUserDeposits(address user): Get list of deposit IDs for a user.
 * - isConditionOracle(address account): Check if an address is a condition oracle.
 * - getDelegatee(uint256 depositId): Get the delegatee address for a deposit.
 * - emergencyBreakAvailableAt(): Get the timestamp when emergency break is available.
 *
 * Admin (Owner-only):
 * - addConditionOracle(address oracle): Add an address allowed to report oracle conditions.
 * - removeConditionOracle(address oracle): Remove an address from condition oracles.
 */

contract QuantumVault is ERC721Holder, ReentrancyGuard {
    using Address for address;

    address public owner;

    enum DepositState {
        Pending,          // Initial state, conditions not evaluated/met
        ConditionsMet,    // Conditions evaluated and found to be met (after measurement)
        Withdrawn,        // Assets have been withdrawn
        LinkedStateActive // Used internally for linked dependencies being active
    }

    enum ConditionType {
        BlockNumber,       // Requires current block >= target block
        Timestamp,         // Requires current timestamp >= target timestamp
        ERC20Balance,      // Requires depositor's balance of a token >= amount
        ERC721Possession,  // Requires depositor owns a specific NFT
        OracleReport,      // Requires a trusted oracle to report a status
        LinkedDepositState // Requires a specific deposit in this or another vault to be in ConditionsMet state
    }

    struct Condition {
        ConditionType conditionType; // Type of condition
        bytes data;                  // abi.encodePacked data specific to the condition type
        bool isMet;                  // Status reported by oracle (only for OracleReport)
    }

    struct Deposit {
        uint256 id;                  // Unique ID for the deposit
        address depositor;           // Original depositor
        address tokenAddress;        // Address of the token (ERC20 or ERC721)
        bool isERC721;               // True if ERC721, false if ERC20
        uint256 amountOrTokenId;     // Amount for ERC20, tokenId for ERC721
        DepositState state;          // Current state of the deposit
        Condition[] conditions;      // Array of conditions that must ALL be met
        address delegatee;           // Address authorized to withdraw
    }

    uint256 private nextDepositId = 1;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) private userDeposits;
    mapping(address => bool) public isConditionOracle;

    uint256 public emergencyBreakAvailableAt;
    uint256 private constant EMERGENCY_BREAK_DELAY = 365 days * 2; // 2 years

    // Events
    event Deposited(uint256 depositId, address depositor, address tokenAddress, bool isERC721, uint256 amountOrTokenId);
    event ConditionAdded(uint256 depositId, uint256 conditionIndex, ConditionType conditionType);
    event ConditionRemoved(uint256 depositId, uint256 conditionIndex);
    event StateMeasured(uint256 depositId, DepositState newState);
    event Withdrawn(uint256 depositId, address recipient);
    event LinkCreated(uint256 sourceDepositId, address targetVault, uint256 targetDepositId);
    event DelegateSet(uint256 depositId, address delegatee);
    event DelegateRevoked(uint256 depositId);
    event OracleStatusUpdated(uint256 depositId, uint256 conditionIndex, bool status);
    event EmergencyBreakTriggered(address owner);

    modifier onlyDepositor(uint256 depositId) {
        require(deposits[depositId].depositor == msg.sender, "Not the depositor");
        _;
    }

    modifier onlyDepositorOrDelegatee(uint256 depositId) {
        require(deposits[depositId].depositor == msg.sender || deposits[depositId].delegatee == msg.sender, "Not depositor or delegatee");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyOracle() {
        require(isConditionOracle[msg.sender], "Not an oracle");
        _;
    }

    constructor() {
        owner = msg.sender;
        emergencyBreakAvailableAt = block.timestamp + EMERGENCY_BREAK_DELAY;
    }

    // 7. Deposit Functions
    /**
     * @dev Deposits ERC20 tokens into the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     * @param depositor The address for whom the deposit is made (usually msg.sender, but allows delegation).
     */
    function depositERC20(address token, uint256 amount, address depositor) external payable nonReentrant {
        require(token.isContract(), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        require(depositor != address(0), "Depositor cannot be zero address");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            depositor: depositor,
            tokenAddress: token,
            isERC721: false,
            amountOrTokenId: amount,
            state: DepositState.Pending,
            conditions: new Condition[](0),
            delegatee: address(0)
        });
        userDeposits[depositor].push(depositId);

        emit Deposited(depositId, depositor, token, false, amount);
    }

    /**
     * @dev Deposits ERC721 tokens into the vault.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to deposit.
     * @param depositor The address for whom the deposit is made (usually msg.sender, but allows delegation).
     */
    function depositERC721(address token, uint256 tokenId, address depositor) external payable nonReentrant {
        require(token.isContract(), "Invalid token address");
        require(depositor != address(0), "Depositor cannot be zero address");
        // ERC721Holder automatically handles onERC721Received check

        IERC721(token).transferFrom(msg.sender, address(this), tokenId);

        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            depositor: depositor,
            tokenAddress: token,
            isERC721: true,
            amountOrTokenId: tokenId,
            state: DepositState.Pending,
            conditions: new Condition[](0),
            delegatee: address(0)
        });
        userDeposits[depositor].push(depositId);

        emit Deposited(depositId, depositor, token, true, tokenId);
    }

    // 8. Condition Management Functions
    /**
     * @dev Adds a condition to a specific deposit. All conditions must be met.
     * @param depositId The ID of the deposit.
     * @param condition The condition to add.
     */
    function addCondition(uint256 depositId, Condition calldata condition)
        external
        onlyDepositor(depositId)
    {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == DepositState.Pending, "Deposit state is not Pending");
        require(condition.conditionType != ConditionType.OracleReport || isConditionOracle[msg.sender], "Only oracles can add OracleReport conditions");
        // Basic check for data length based on type (can be expanded for more strictness)
        require(condition.conditionType != ConditionType.LinkedDepositState || condition.data.length >= 64, "Invalid data for LinkedDepositState"); // Expects address + uint256

        deposit.conditions.push(condition);
        emit ConditionAdded(depositId, deposit.conditions.length - 1, condition.conditionType);
    }

    /**
     * @dev Removes a condition from a deposit.
     * @param depositId The ID of the deposit.
     * @param conditionIndex The index of the condition to remove in the conditions array.
     */
    function removeCondition(uint256 depositId, uint256 conditionIndex)
        external
        onlyDepositor(depositId)
    {
        Deposit storage deposit = deposits[depositId];
        require(deposit.state == DepositState.Pending, "Deposit state is not Pending");
        require(conditionIndex < deposit.conditions.length, "Condition index out of bounds");

        // Shift elements to remove the condition
        for (uint i = conditionIndex; i < deposit.conditions.length - 1; i++) {
            deposit.conditions[i] = deposit.conditions[i + 1];
        }
        deposit.conditions.pop();

        emit ConditionRemoved(depositId, conditionIndex);
    }

    // 9. Condition Evaluation Logic (Internal)
    /**
     * @dev Checks if a single condition is met.
     * @param deposit The deposit struct.
     * @param condition The condition struct.
     * @return True if the condition is met, false otherwise.
     */
    function _isConditionMet(Deposit storage deposit, Condition storage condition) internal view returns (bool) {
        if (condition.conditionType == ConditionType.BlockNumber) {
            uint256 targetBlock = abi.decode(condition.data, (uint256));
            return block.number >= targetBlock;
        } else if (condition.conditionType == ConditionType.Timestamp) {
            uint256 targetTimestamp = abi.decode(condition.data, (uint256));
            return block.timestamp >= targetTimestamp;
        } else if (condition.conditionType == ConditionType.ERC20Balance) {
            (address token, uint256 amount) = abi.decode(condition.data, (address, uint256));
            return IERC20(token).balanceOf(deposit.depositor) >= amount;
        } else if (condition.conditionType == ConditionType.ERC721Possession) {
            (address token, uint256 tokenId) = abi.decode(condition.data, (address, uint256));
            return IERC721(token).ownerOf(tokenId) == deposit.depositor;
        } else if (condition.conditionType == ConditionType.OracleReport) {
            // isMet status is updated by registered oracles
            return condition.isMet;
        } else if (condition.conditionType == ConditionType.LinkedDepositState) {
            (address targetVault, uint256 targetDepositId) = abi.decode(condition.data, (address, uint256));
            if (targetVault == address(this)) {
                // Internal link
                Deposit storage targetDeposit = deposits[targetDepositId];
                return targetDeposit.state == DepositState.ConditionsMet || targetDeposit.state == DepositState.LinkedStateActive;
            } else {
                // External link - call view function on target vault
                try QuantumVault(targetVault).getDepositState(targetDepositId) returns (DepositState targetState) {
                    return targetState == DepositState.ConditionsMet || targetState == DepositState.LinkedStateActive;
                } catch {
                    return false; // External vault/deposit invalid or call failed
                }
            }
        }
        return false; // Unknown condition type
    }

    // 17. Query Functions (Check Condition Status)
    /**
     * @dev Checks if all conditions for a deposit are currently met *without* changing state.
     * @param depositId The ID of the deposit.
     * @return True if all conditions are met, false otherwise.
     */
    function checkConditionsMet(uint256 depositId) public view returns (bool) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.id != 0, "Deposit not found"); // Ensure deposit exists

        if (deposit.conditions.length == 0) {
            return true; // No conditions means always met
        }

        for (uint i = 0; i < deposit.conditions.length; i++) {
            if (!_isConditionMet(deposit, deposit.conditions[i])) {
                return false; // All conditions must be met
            }
        }
        return true;
    }

    // 10. State Measurement Function
    /**
     * @dev Evaluates all conditions for a deposit and transitions its state if met.
     *      This acts as the "measurement" step.
     * @param depositId The ID of the deposit.
     */
    function measureState(uint256 depositId) external nonReentrant {
        Deposit storage deposit = deposits[depositId];
        require(deposit.id != 0, "Deposit not found");
        require(deposit.state == DepositState.Pending || deposit.state == DepositState.LinkedStateActive, "Deposit state not eligible for measurement");

        bool conditionsCurrentlyMet = checkConditionsMet(depositId);

        DepositState oldState = deposit.state;
        if (conditionsCurrentlyMet) {
            deposit.state = DepositState.ConditionsMet;

            // If this deposit is a target of a LinkedDepositState condition in another deposit,
            // trigger measurement for those deposits as well to propagate the state change.
            // NOTE: This could potentially chain measurements. Need to be mindful of gas limits.
            // For simplicity, we won't implement full transitive triggering here, but
            // a more advanced version could track dependencies. Basic external checks suffice for now.

        } else {
             // Optionally transition to a different state if conditions are no longer met?
             // Or just stay Pending/LinkedStateActive. Sticking to Pending/LinkedStateActive for now.
        }

        if (deposit.state != oldState) {
             emit StateMeasured(depositId, deposit.state);
        }
    }

    // 11. Withdrawal Functions
    /**
     * @dev Checks if a deposit can be withdrawn.
     * @param depositId The ID of the deposit.
     * @return True if withdrawal is possible, false otherwise.
     */
    function canWithdraw(uint256 depositId) public view returns (bool) {
        Deposit storage deposit = deposits[depositId];
        return deposit.id != 0 && deposit.state == DepositState.ConditionsMet;
    }

    /**
     * @dev Withdraws ERC20 tokens from a deposit if conditions are met and state is measured.
     * @param depositId The ID of the deposit.
     */
    function withdrawERC20(uint256 depositId) external nonReentrant onlyDepositorOrDelegatee(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isERC721 == false, "Deposit is ERC721");
        require(canWithdraw(depositId), "Conditions not met or state not measured");

        uint256 amount = deposit.amountOrTokenId;
        address recipient = deposit.depositor; // Always send to original depositor

        deposit.state = DepositState.Withdrawn; // Mark as withdrawn BEFORE transfer
        deposit.amountOrTokenId = 0; // Zero out amount

        IERC20(deposit.tokenAddress).transfer(recipient, amount);

        emit Withdrawn(depositId, recipient);
    }

    /**
     * @dev Withdraws ERC721 token from a deposit if conditions are met and state is measured.
     * @param depositId The ID of the deposit.
     */
    function withdrawERC721(uint256 depositId) external nonReentrant onlyDepositorOrDelegatee(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isERC721 == true, "Deposit is ERC20");
        require(canWithdraw(depositId), "Conditions not met or state not measured");

        uint256 tokenId = deposit.amountOrTokenId;
        address recipient = deposit.depositor; // Always send to original depositor

        deposit.state = DepositState.Withdrawn; // Mark as withdrawn BEFORE transfer
        deposit.amountOrTokenId = 0; // Zero out tokenId

        IERC721(deposit.tokenAddress).transferFrom(address(this), recipient, tokenId);

        emit Withdrawn(depositId, recipient);
    }

    // 12. Linked Deposit ("Entanglement") Functions
    /**
     * @dev Adds a LinkedDepositState condition where the target is in the same vault.
     * @param sourceDepositId The deposit that depends on another deposit.
     * @param targetDepositId The deposit whose state (ConditionsMet/LinkedStateActive) is required.
     */
    function createInternalLink(uint256 sourceDepositId, uint256 targetDepositId)
        external
        onlyDepositor(sourceDepositId)
    {
        require(sourceDepositId != targetDepositId, "Cannot link a deposit to itself");
        require(deposits[sourceDepositId].id != 0 && deposits[targetDepositId].id != 0, "Source or target deposit not found");
        require(deposits[sourceDepositId].state == DepositState.Pending, "Source deposit state not Pending");

        Condition memory linkCondition;
        linkCondition.conditionType = ConditionType.LinkedDepositState;
        linkCondition.data = abi.encodePacked(address(this), targetDepositId);
        linkCondition.isMet = false; // isMet is not used for this condition type

        deposits[sourceDepositId].conditions.push(linkCondition);

        // Optionally mark the target as being part of a link dependency
        // This could help in state management, but adds complexity.
        // Let's just add the condition for now.

        emit LinkCreated(sourceDepositId, address(this), targetDepositId);
    }

    /**
     * @dev Adds a LinkedDepositState condition where the target is in another QuantumVault instance.
     * @param sourceDepositId The deposit that depends on another deposit.
     * @param targetVault The address of the target QuantumVault contract.
     * @param targetDepositId The deposit ID in the target vault.
     */
    function createExternalLink(uint256 sourceDepositId, address targetVault, uint256 targetDepositId)
        external
        onlyDepositor(sourceDepositId)
    {
        require(targetVault != address(0) && targetVault != address(this), "Invalid target vault address");
        require(deposits[sourceDepositId].id != 0, "Source deposit not found");
        require(deposits[sourceDepositId].state == DepositState.Pending, "Source deposit state not Pending");
        // Cannot easily verify targetDepositId existence or type from here without another view call,
        // relying on the _isConditionMet check's try/catch.

        Condition memory linkCondition;
        linkCondition.conditionType = ConditionType.LinkedDepositState;
        linkCondition.data = abi.encodePacked(targetVault, targetDepositId);
        linkCondition.isMet = false; // isMet is not used for this condition type

        deposits[sourceDepositId].conditions.push(linkCondition);

        emit LinkCreated(sourceDepositId, targetVault, targetDepositId);
    }

    // 13. Delegate Access
    /**
     * @dev Allows the depositor to authorize another address to withdraw on their behalf.
     * @param depositId The ID of the deposit.
     * @param delegatee The address to authorize. Set to address(0) to revoke.
     */
    function delegateWithdrawal(uint256 depositId, address delegatee) external onlyDepositor(depositId) {
        require(deposits[depositId].id != 0, "Deposit not found");
        require(deposits[depositId].state != DepositState.Withdrawn, "Deposit already withdrawn");
        require(deposits[depositId].depositor != delegatee, "Cannot delegate to self");

        deposits[depositId].delegatee = delegatee;

        if (delegatee == address(0)) {
            emit DelegateRevoked(depositId);
        } else {
            emit DelegateSet(depositId, delegatee);
        }
    }

     /**
     * @dev Revokes withdrawal delegate authorization.
     * @param depositId The ID of the deposit.
     */
    function revokeDelegate(uint256 depositId) external onlyDepositor(depositId) {
        delegateWithdrawal(depositId, address(0));
    }

    // 14. Oracle Integration
    /**
     * @dev Allows a registered oracle to update the status of an OracleReport condition.
     * @param depositId The ID of the deposit.
     * @param conditionIndex The index of the condition in the deposit's conditions array.
     * @param status The boolean status reported by the oracle.
     */
    function updateOracleCondition(uint256 depositId, uint256 conditionIndex, bool status) external onlyOracle {
        Deposit storage deposit = deposits[depositId];
        require(deposit.id != 0, "Deposit not found");
        require(deposit.state == DepositState.Pending || deposit.state == DepositState.LinkedStateActive, "Deposit state not eligible for oracle update");
        require(conditionIndex < deposit.conditions.length, "Condition index out of bounds");
        require(deposit.conditions[conditionIndex].conditionType == ConditionType.OracleReport, "Condition is not an OracleReport type");

        deposit.conditions[conditionIndex].isMet = status;

        emit OracleStatusUpdated(depositId, conditionIndex, status);
    }

    // 15. Emergency Break
    /**
     * @dev Allows the owner to withdraw ALL assets if the emergency break time has passed.
     *      This bypasses all conditions.
     *      Only owner can trigger this.
     */
    function emergencyBreak() external onlyOwner nonReentrant {
        require(block.timestamp >= emergencyBreakAvailableAt, "Emergency break not yet available");

        // This is a complex operation that might exceed gas limits if there are many deposits.
        // A more robust implementation would require pagination or splitting this into multiple transactions.
        // For this example, we'll iterate through user deposits (limited by array size/gas).
        // A better approach would be to iterate through all depositIds in a mapping or indexed list if needed.

        uint256 currentDepositId = 1;
        while (currentDepositId < nextDepositId) {
            Deposit storage deposit = deposits[currentDepositId];
            if (deposit.id != 0 && deposit.state != DepositState.Withdrawn) {
                 // Bypass checks, just send the assets
                if (deposit.isERC721) {
                    try IERC721(deposit.tokenAddress).transferFrom(address(this), owner, deposit.amountOrTokenId) {} catch {} // Attempt transfer, ignore failure
                } else {
                     // Check token balance before attempting transfer (in case some ERC20 balance isn't tied to a deposit)
                     uint256 amountToTransfer = deposit.amountOrTokenId;
                     uint256 contractBalance = IERC20(deposit.tokenAddress).balanceOf(address(this));
                     if (amountToTransfer > contractBalance) {
                         amountToTransfer = contractBalance; // Don't try to send more than we have
                     }
                     if (amountToTransfer > 0) {
                        try IERC20(deposit.tokenAddress).transfer(owner, amountToTransfer) {} catch {} // Attempt transfer, ignore failure
                     }
                }
                deposit.state = DepositState.Withdrawn; // Mark as withdrawn regardless of transfer success
                deposit.amountOrTokenId = 0;
            }
            currentDepositId++;
        }

        emit EmergencyBreakTriggered(owner);
    }

    // 16. Batch Operations
    /**
     * @dev Attempts to withdraw multiple ERC20 deposits in a single transaction.
     *      Each withdrawal is checked independently.
     * @param depositIds Array of deposit IDs to attempt to withdraw.
     */
    function batchWithdrawERC20(uint256[] calldata depositIds) external nonReentrant {
        for (uint256 i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
             // Check if the caller is authorized for this specific deposit
            if (deposits[depositId].depositor == msg.sender || deposits[depositId].delegatee == msg.sender) {
                Deposit storage deposit = deposits[depositId];
                if (deposit.id != 0 && !deposit.isERC721 && canWithdraw(depositId)) {
                     uint256 amount = deposit.amountOrTokenId;
                     address recipient = deposit.depositor;

                    deposit.state = DepositState.Withdrawn;
                    deposit.amountOrTokenId = 0;

                    // Use low-level call or try/catch to allow other transfers to succeed if one fails
                    bool success = IERC20(deposit.tokenAddress).transfer(recipient, amount);
                    if (success) {
                         emit Withdrawn(depositId, recipient);
                    } else {
                        // Optional: Revert state change if transfer fails? Depends on desired behavior.
                        // Keeping it marked as Withdrawn to avoid repeated attempts on failed transfers.
                        // Could add an event for failed withdrawal attempts.
                    }
                }
            }
        }
    }

    /**
     * @dev Attempts to withdraw multiple ERC721 deposits in a single transaction.
     *      Each withdrawal is checked independently.
     * @param depositIds Array of deposit IDs to attempt to withdraw.
     */
     function batchWithdrawERC721(uint256[] calldata depositIds) external nonReentrant {
        for (uint256 i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
            // Check if the caller is authorized for this specific deposit
            if (deposits[depositId].depositor == msg.sender || deposits[depositId].delegatee == msg.sender) {
                Deposit storage deposit = deposits[depositId];
                if (deposit.id != 0 && deposit.isERC721 && canWithdraw(depositId)) {
                    uint256 tokenId = deposit.amountOrTokenId;
                    address recipient = deposit.depositor;

                    deposit.state = DepositState.Withdrawn;
                    deposit.amountOrTokenId = 0;

                    // Use low-level call or try/catch to allow other transfers to succeed if one fails
                    try IERC721(deposit.tokenAddress).transferFrom(address(this), recipient, tokenId) {
                         emit Withdrawn(depositId, recipient);
                    } catch {
                        // Optional: Revert state change if transfer fails?
                    }
                }
            }
        }
     }


    // 17. Query Functions
    /**
     * @dev Gets the details of a specific deposit.
     * @param depositId The ID of the deposit.
     * @return A tuple containing the deposit details.
     */
    function getDepositDetails(uint256 depositId)
        external
        view
        returns (
            uint256 id,
            address depositor,
            address tokenAddress,
            bool isERC721,
            uint256 amountOrTokenId,
            DepositState state,
            address delegatee
        )
    {
        Deposit storage deposit = deposits[depositId];
        require(deposit.id != 0, "Deposit not found");
        return (
            deposit.id,
            deposit.depositor,
            deposit.tokenAddress,
            deposit.isERC721,
            deposit.amountOrTokenId,
            deposit.state,
            deposit.delegatee
        );
    }

     /**
      * @dev Gets the conditions associated with a specific deposit.
      * @param depositId The ID of the deposit.
      * @return An array of Condition structs.
      */
    function getDepositConditions(uint256 depositId) external view returns (Condition[] memory) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.id != 0, "Deposit not found");
        return deposit.conditions;
    }

     /**
      * @dev Gets the current state of a specific deposit.
      * @param depositId The ID of the deposit.
      * @return The DepositState enum value.
      */
    function getDepositState(uint256 depositId) external view returns (DepositState) {
         Deposit storage deposit = deposits[depositId];
         require(deposit.id != 0, "Deposit not found");
         return deposit.state;
     }

    /**
     * @dev Gets the list of deposit IDs associated with a user.
     * @param user The address of the user.
     * @return An array of deposit IDs.
     */
    function getUserDeposits(address user) external view returns (uint256[] memory) {
        return userDeposits[user];
    }

     /**
      * @dev Checks if an address is a registered condition oracle.
      * @param account The address to check.
      * @return True if the address is an oracle, false otherwise.
      */
    function isConditionOracle(address account) external view returns (bool) {
        return isConditionOracle[account];
    }

    /**
     * @dev Gets the delegatee address for a deposit.
     * @param depositId The ID of the deposit.
     * @return The delegatee address, or address(0) if none set.
     */
    function getDelegatee(uint256 depositId) external view returns (address) {
        require(deposits[depositId].id != 0, "Deposit not found");
        return deposits[depositId].delegatee;
    }

     /**
      * @dev Gets the timestamp when the emergency break becomes available.
      * @return The timestamp.
      */
    function emergencyBreakAvailableAt() external view returns (uint256) {
        return emergencyBreakAvailableAt;
    }


    // 18. Admin Functions (Owner-only)
    /**
     * @dev Adds an address to the list of authorized condition oracles.
     * @param oracle The address to add.
     */
    function addConditionOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "Oracle address cannot be zero");
        isConditionOracle[oracle] = true;
    }

    /**
     * @dev Removes an address from the list of authorized condition oracles.
     * @param oracle The address to remove.
     */
    function removeConditionOracle(address oracle) external onlyOwner {
        isConditionOracle[oracle] = false;
    }

    // ERC721Holder receive function (required by ERC721Holder)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Additional checks could be added here if needed, but the core logic
        // relies on depositERC721 being called correctly.
        // The contract only accepts tokens via transferFrom called by the depositor.
        return this.onERC721Received.selector;
    }

    // Fallback function to reject ether transfers
    receive() external payable {
        revert("Ether is not accepted");
    }
}
```