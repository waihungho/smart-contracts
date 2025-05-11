Okay, let's design a smart contract that incorporates several advanced, creative, and interconnected concepts around asset locking, conditional release, and dynamic state management.

We'll create a "Chronos Entanglement Vault". Users can deposit ETH or ERC20 tokens. Withdrawal is *not* based on a simple time lock or single condition, but rather a combination of:
1.  **Minimum Time Elapsed:** A base lock period for each deposit.
2.  **"Chronon Gates":** Time windows defined by an admin where certain actions (like withdrawal) might be *forbidden* or *only allowed*.
3.  **"Quantum States":** Abstract states activated by external triggers (simulating complex conditions like oracle data, governance votes, or state of another contract) that *must* be active for withdrawal.
4.  **"Entanglement Bonds":** A mechanism to link two user deposits, where one deposit's withdrawal might be conditional on the *other* linked deposit also meeting its *own* conditions, or perhaps requiring a specific trigger.
5.  **Adaptive Friction:** Withdrawal fees that change dynamically based on a parameter set by the admin, potentially simulating network load or desired behavior.

This combination creates a complex, state-dependent withdrawal mechanism that's non-standard.

---

**Outline and Function Summary:**

**Contract Name:** ChronosEntanglementVault

**Core Concepts:**
*   Asset Locking (ETH, ERC20)
*   Time-Based Restrictions (Minimum Lock, Chronon Gates)
*   State-Based Restrictions (Quantum States)
*   Interdependent Deposit Conditions (Entanglement Bonds)
*   Dynamic Parameters (Adaptive Friction Fee)
*   Owner/Admin Control (Defining states, gates, bonds, parameters)
*   User Interaction (Depositing, Extending Lock, Withdrawing)
*   Querying State (Checking eligibility, gate status, state status, bond status)

**Function Summary:**

1.  `receive()` / `depositETH()`: Allows users to deposit Ether into the vault, recording the deposit amount and lock end time.
2.  `depositERC20(address token, uint256 amount)`: Allows users to deposit a specific ERC20 token, requiring prior approval. Records deposit and lock end time.
3.  `extendMyDepositLock(uint256 additionalDuration)`: Allows a user to voluntarily extend the lock period for their own deposits.
4.  `queryMyETHDeposit()`: Returns the user's current locked ETH balance and lock end time.
5.  `queryMyERC20Deposit(address token)`: Returns the user's current locked ERC20 balance and lock end time for a specific token.
6.  `getTotalETHDeposited()`: Returns the total ETH held by the contract from deposits.
7.  `getTotalERC20Deposited(address token)`: Returns the total amount of a specific ERC20 token held from deposits.
8.  `defineChrononGate(uint256 gateId, uint256 startTime, uint256 endTime, bool forbidsWithdrawal)`: (Admin) Defines a named time window (GateId) and whether being inside this window *forbids* withdrawal or not.
9.  `setChrononGateActiveStatus(uint256 gateId, bool isActive)`: (Admin) Activates or deactivates a defined Chronon Gate. An inactive gate doesn't affect withdrawals.
10. `queryChrononGateStatus(uint256 gateId)`: (Query) Checks if a defined Chronon Gate is currently active *and* if the current time is within its window. Returns the forbidding status if active.
11. `defineQuantumState(uint256 stateId)`: (Admin) Defines a named Quantum State (StateId) that can be toggled.
12. `setQuantumStateStatus(uint256 stateId, bool isActive)`: (Admin) Toggles the active status of a Quantum State. This simulates an external trigger.
13. `queryQuantumStateStatus(uint256 stateId)`: (Query) Checks if a specific Quantum State is currently active.
14. `defineEntanglementBond(uint256 bondId, address userA, address userB, uint256 bondType)`: (Admin) Defines a bond linking two users/deposits with a specified type (e.g., Type 1: both must be eligible, Type 2: A must be eligible before B).
15. `markEntanglementBondFulfilled(uint256 bondId)`: (Admin/Triggerable) Marks a specific bond as fulfilled. This might be called manually by admin or via a separate keeper/oracle if conditions are met.
16. `queryEntanglementBondStatus(uint256 bondId)`: (Query) Checks if a specific Entanglement Bond exists and if it's marked as fulfilled.
17. `setRequiredConditionsForWithdrawal(uint256[] requiredGateIds, uint256[] requiredStateIds, uint256[] requiredBondIds)`: (Admin) Sets the global conditions that *must* be met (gates not forbidding, states active, bonds fulfilled) *in addition* to the individual lock time, for any withdrawal to be possible.
18. `getRequiredConditions()`: (Query) Returns the currently set global required Gate, State, and Bond IDs.
19. `checkWithdrawalEligibilityETH(address user)`: (Query) Performs the comprehensive check for a user's ETH deposit: minimum time met, no forbidding gates active, all required states active, all required bonds fulfilled. Returns boolean + details.
20. `checkWithdrawalEligibilityERC20(address user, address token)`: (Query) Same as above for ERC20 deposits.
21. `setAdaptiveFrictionRate(uint256 newRatePermil)`: (Admin) Sets a percentage (in permil, parts per thousand) for the adaptive friction fee applied during withdrawal.
22. `queryAdaptiveFrictionRate()`: (Query) Returns the current adaptive friction rate.
23. `withdrawETH(uint256 amount)`: Attempts to withdraw ETH. This function internally calls the eligibility check. If eligible, transfers ETH minus the adaptive friction fee.
24. `withdrawERC20(address token, uint256 amount)`: Attempts to withdraw ERC20. Internally calls eligibility check. If eligible, transfers token minus the adaptive friction fee.
25. `pauseContract()`: (Admin) Pauses core deposit and withdrawal functionality.
26. `unpauseContract()`: (Admin) Unpauses the contract.
27. `recoverStuckERC20(address token)`: (Admin) Allows owner to recover ERC20 tokens accidentally sent *directly* to the contract address (not via `depositERC20`). Standard safety function.
28. `transferOwnership(address newOwner)`: (Admin) Transfers ownership of the contract.
29. `renounceOwnership()`: (Admin) Renounces ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors for gas efficiency and clarity
error InvalidAmount();
error DepositTooSmall();
error LockDurationTooShort();
error WithdrawalNotAllowedYet();
error NotEligibleForWithdrawal();
error ChrononGateForbids();
error QuantumStateNotActive(uint256 stateId);
error EntanglementBondNotFulfilled(uint256 bondId);
error GateDoesNotExist(uint256 gateId);
error StateDoesNotExist(uint256 stateId);
error BondDoesNotExist(uint256 bondId);
error InvalidBondType();
error AlreadyPartOfBond(address user);
error CannotBondSelf();
error NoDepositFound();
error InsufficientBalanceForWithdrawal();
error InvalidRate();
error TokenNotSupported();

contract ChronosEntanglementVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Deposit {
        uint256 ethAmount;
        mapping(address => uint256) erc20Amounts;
        uint256 lockEndTime;
        uint256 bondId; // 0 if not part of a bond
    }

    struct ChrononGate {
        uint256 startTime;
        uint256 endTime;
        bool forbidsWithdrawal; // True if withdrawal is NOT allowed when inside this gate
        bool isActive; // Admin switch to enable/disable this gate's effect
    }

    struct QuantumState {
        bool isActive; // Admin switch, simulating external condition
    }

    struct EntanglementBond {
        address userA;
        address userB;
        uint256 bondType; // e.g., 1 = both users must be individually eligible to fulfill bond
        bool isFulfilled; // Set by admin/trigger when bond conditions met
        bool isActive; // Admin switch to enable/disable bond's effect
    }

    mapping(address => Deposit) private userDeposits;
    mapping(address => bool) private supportedTokens;
    mapping(uint256 => ChrononGate) private chrononGates;
    mapping(uint256 => QuantumState) private quantumStates;
    mapping(uint256 => EntanglementBond) private entanglementBonds;

    uint256[] private supportedTokenList; // For easier enumeration
    uint256 private gateCounter = 0;
    uint256 private stateCounter = 0;
    uint256 private bondCounter = 0;

    uint256 private depositMinimumLockDuration = 1 days; // Default min lock
    uint256 private adaptiveFrictionRatePermil = 10; // 10 permil = 1% default fee

    // Global required conditions for *any* withdrawal (checked *after* individual lock)
    uint256[] private requiredGateIds;
    uint256[] private requiredStateIds;
    uint256[] private requiredBondIds;

    // --- Events ---
    event ETHDeposited(address indexed user, uint256 amount, uint256 lockUntil);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount, uint256 lockUntil);
    event DepositLockExtended(address indexed user, uint256 newLockUntil);
    event ETHWithdrawn(address indexed user, uint256 amount, uint256 fee);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event ChrononGateDefined(uint256 indexed gateId, uint256 startTime, uint256 endTime, bool forbidsWithdrawal);
    event ChrononGateStatusUpdated(uint256 indexed gateId, bool isActive);
    event QuantumStateDefined(uint256 indexed stateId);
    event QuantumStateStatusUpdated(uint256 indexed stateId, bool isActive);
    event EntanglementBondDefined(uint256 indexed bondId, address userA, address userB, uint256 bondType);
    event EntanglementBondFulfilled(uint256 indexed bondId);
    event RequiredConditionsUpdated(uint256[] requiredGateIds, uint256[] requiredStateIds, uint256[] requiredBondIds);
    event AdaptiveFrictionRateUpdated(uint256 newRatePermil);
    event TokenSupported(address indexed token);
    event TokenRecovered(address indexed token, uint256 amount);

    // --- Constructor ---
    constructor(address[] memory _supportedTokens) Ownable(msg.sender) {
        for (uint i = 0; i < _supportedTokens.length; i++) {
            addSupportedToken(_supportedTokens[i]);
        }
    }

    // --- Receive ETH ---
    receive() external payable whenNotPaused nonReentrant {
        depositETH();
    }

    // --- Deposit Functions (2) ---

    /// @notice Deposits sent ETH into the vault.
    /// @dev Associates the deposit with the sender and applies minimum lock duration.
    function depositETH() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        if (msg.value < 0.001 ether) revert DepositTooSmall(); // Example minimum

        Deposit storage deposit = userDeposits[msg.sender];

        // If first deposit, initialize lock end time
        if (deposit.lockEndTime == 0) {
            deposit.lockEndTime = block.timestamp + depositMinimumLockDuration;
        } else {
             // If adding to existing deposit, extend lock if current lock is less than min duration from now
             // This encourages longer locks or maintains minimum on top-ups
            uint256 requiredNewLock = block.timestamp + depositMinimumLockDuration;
            if (deposit.lockEndTime < requiredNewLock) {
                deposit.lockEndTime = requiredNewLock;
            }
        }

        deposit.ethAmount += msg.value;

        emit ETHDeposited(msg.sender, msg.value, deposit.lockEndTime);
    }

    /// @notice Deposits a specified amount of an ERC20 token into the vault.
    /// @dev Requires prior ERC20 approval. Associates deposit with sender and applies minimum lock duration.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of the ERC20 token to deposit.
    function depositERC20(address token, uint256 amount) public whenNotPaused nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (!supportedTokens[token]) revert TokenNotSupported();

        Deposit storage deposit = userDeposits[msg.sender];

        // If first deposit, initialize lock end time
        if (deposit.lockEndTime == 0) {
            deposit.lockEndTime = block.timestamp + depositMinimumLockDuration;
        } else {
             uint256 requiredNewLock = block.timestamp + depositMinimumLockDuration;
             if (deposit.lockEndTime < requiredNewLock) {
                 deposit.lockEndTime = requiredNewLock;
             }
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        deposit.erc20Amounts[token] += amount;

        emit ERC20Deposited(msg.sender, token, amount, deposit.lockEndTime);
    }

    // --- User Interaction Functions (1) ---

    /// @notice Allows the user to extend the lock duration for their deposits.
    /// @param additionalDuration The number of seconds to add to the current lock end time.
    function extendMyDepositLock(uint256 additionalDuration) public whenNotPaused {
        Deposit storage deposit = userDeposits[msg.sender];
        if (deposit.lockEndTime == 0) revert NoDepositFound(); // Cannot extend if no deposit exists

        deposit.lockEndTime += additionalDuration;
        emit DepositLockExtended(msg.sender, deposit.lockEndTime);
    }

    // --- Query Functions (6) ---

    /// @notice Gets the calling user's locked ETH balance and lock end time.
    /// @return amount The user's locked ETH amount.
    /// @return lockUntil The timestamp when the user's deposit lock ends.
    function queryMyETHDeposit() public view returns (uint256 amount, uint256 lockUntil) {
        Deposit storage deposit = userDeposits[msg.sender];
        return (deposit.ethAmount, deposit.lockEndTime);
    }

    /// @notice Gets the calling user's locked ERC20 balance and lock end time for a token.
    /// @param token The address of the ERC20 token.
    /// @return amount The user's locked ERC20 amount for the token.
    /// @return lockUntil The timestamp when the user's deposit lock ends.
    function queryMyERC20Deposit(address token) public view returns (uint256 amount, uint256 lockUntil) {
         if (!supportedTokens[token]) revert TokenNotSupported();
        Deposit storage deposit = userDeposits[msg.sender];
        return (deposit.erc20Amounts[token], deposit.lockEndTime);
    }

    /// @notice Gets the total ETH currently deposited in the vault.
    /// @return The total ETH balance.
    function getTotalETHDeposited() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the total amount of a specific ERC20 token deposited in the vault.
    /// @param token The address of the ERC20 token.
    /// @return The total token balance.
    function getTotalERC20Deposited(address token) public view returns (uint256) {
        if (!supportedTokens[token]) revert TokenNotSupported();
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Checks the current status of a Chronon Gate.
    /// @param gateId The ID of the gate to check.
    /// @return isActive Whether the gate definition is active.
    /// @return isCurrentlyOpen Whether the current time is within the gate's window.
    /// @return forbidsWithdrawal If active and open, whether it forbids withdrawal.
    function queryChrononGateStatus(uint256 gateId) public view returns (bool isActive, bool isCurrentlyOpen, bool forbidsWithdrawal) {
        ChrononGate storage gate = chrononGates[gateId];
         if (!gate.isActive && gate.startTime == 0 && gate.endTime == 0) revert GateDoesNotExist(gateId); // Check if it was ever defined
        isActive = gate.isActive;
        isCurrentlyOpen = gate.isActive && block.timestamp >= gate.startTime && block.timestamp <= gate.endTime;
        forbidsWithdrawal = gate.forbidsWithdrawal;
    }

    /// @notice Checks the current active status of a Quantum State.
    /// @param stateId The ID of the state to check.
    /// @return isActive Whether the state is currently marked as active.
    function queryQuantumStateStatus(uint256 stateId) public view returns (bool isActive) {
        if (!quantumStates[stateId].isActive && stateCounter < stateId) revert StateDoesNotExist(stateId); // Check if defined
        return quantumStates[stateId].isActive;
    }

    /// @notice Checks the current status of an Entanglement Bond.
    /// @param bondId The ID of the bond to check.
    /// @return isActive Whether the bond definition is active.
    /// @return isFulfilled Whether the bond is marked as fulfilled.
    /// @return userA The address of user A in the bond.
    /// @return userB The address of user B in the bond.
    /// @return bondType The type of the bond.
    function queryEntanglementBondStatus(uint256 bondId) public view returns (bool isActive, bool isFulfilled, address userA, address userB, uint256 bondType) {
         EntanglementBond storage bond = entanglementBonds[bondId];
         if (!bond.isActive && bond.userA == address(0)) revert BondDoesNotExist(bondId); // Check if defined
         isActive = bond.isActive;
         isFulfilled = bond.isFulfilled;
         userA = bond.userA;
         userB = bond.userB;
         bondType = bond.bondType;
    }

    /// @notice Returns the globally required Gate, State, and Bond IDs for withdrawal eligibility.
    /// @return requiredGateIds_ The array of gate IDs that must *not* be forbidding if active and open.
    /// @return requiredStateIds_ The array of state IDs that must be active.
    /// @return requiredBondIds_ The array of bond IDs that must be fulfilled if active.
    function getRequiredConditions() public view returns (uint256[] memory requiredGateIds_, uint256[] memory requiredStateIds_, uint256[] memory requiredBondIds_) {
        return (requiredGateIds, requiredStateIds, requiredBondIds);
    }

    /// @notice Returns the current adaptive friction rate applied to withdrawals.
    /// @return The rate in permil (parts per thousand).
    function queryAdaptiveFrictionRate() public view returns (uint256) {
        return adaptiveFrictionRatePermil;
    }

     /// @notice Queries the lock end time for a user's deposit.
     /// @param user The address of the user.
     /// @return The timestamp when the user's deposit lock ends.
     function queryUserDepositLockEndTime(address user) public view returns (uint256) {
         return userDeposits[user].lockEndTime;
     }


    // --- Eligibility Check Functions (2) ---

    /// @notice Checks if a user's ETH deposit is eligible for withdrawal based on all conditions.
    /// @param user The address of the user.
    /// @return isEligible True if all conditions are met.
    /// @return reasons Why the user is not eligible (empty array if eligible).
    function checkWithdrawalEligibilityETH(address user) public view returns (bool isEligible, string[] memory reasons) {
        Deposit storage deposit = userDeposits[user];
        if (deposit.ethAmount == 0) {
            return (false, new string[](1){"No ETH deposit found"});
        }

        string[] memory failureReasons = new string[](0);

        // 1. Check Minimum Lock Time
        if (block.timestamp < deposit.lockEndTime) {
            string memory reason = string.concat("Minimum lock time not met (until ", uint256(deposit.lockEndTime).toString(), ")");
            string[] memory temp = new string[](failureReasons.length + 1);
            for(uint i = 0; i < failureReasons.length; i++) { temp[i] = failureReasons[i]; }
            temp[failureReasons.length] = reason;
            failureReasons = temp;
        }

        // 2. Check Chronon Gates
        for (uint i = 0; i < requiredGateIds.length; i++) {
            uint256 gateId = requiredGateIds[i];
            ChrononGate storage gate = chrononGates[gateId];
            if (gate.isActive && gate.forbidsWithdrawal && block.timestamp >= gate.startTime && block.timestamp <= gate.endTime) {
                 string memory reason = string.concat("Chronon Gate ", uint256(gateId).toString(), " forbids withdrawal");
                 string[] memory temp = new string[](failureReasons.length + 1);
                 for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                 temp[failureReasons.length] = reason;
                 failureReasons = temp;
            }
        }

        // 3. Check Quantum States
        for (uint i = 0; i < requiredStateIds.length; i++) {
            uint256 stateId = requiredStateIds[i];
            if (!quantumStates[stateId].isActive) {
                string memory reason = string.concat("Quantum State ", uint256(stateId).toString(), " is not active");
                 string[] memory temp = new string[](failureReasons.length + 1);
                 for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                 temp[failureReasons.length] = reason;
                 failureReasons = temp;
            }
        }

        // 4. Check Entanglement Bonds
        if (deposit.bondId != 0) {
             EntanglementBond storage bond = entanglementBonds[deposit.bondId];
             if (bond.isActive && !bond.isFulfilled) {
                 // Simplified bond check: just checks if the bond affecting this deposit is fulfilled
                 // More complex logic for different bond types would go here (e.g., check other user's eligibility)
                 string memory reason = string.concat("Entanglement Bond ", uint256(deposit.bondId).toString(), " affecting this deposit is not fulfilled");
                  string[] memory temp = new string[](failureReasons.length + 1);
                  for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                  temp[failureReasons.length] = reason;
                  failureReasons = temp;
             }
         }
        // Also check required bonds set globally, regardless of whether *this* deposit is part of one
        for (uint i = 0; i < requiredBondIds.length; i++) {
             uint256 bondId = requiredBondIds[i];
             EntanglementBond storage bond = entanglementBonds[bondId];
             if (bond.isActive && !bond.isFulfilled) {
                 string memory reason = string.concat("Required Entanglement Bond ", uint256(bondId).toString(), " is not fulfilled");
                 string[] memory temp = new string[](failureReasons.length + 1);
                 for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                 temp[failureReasons.length] = reason;
                 failureReasons = temp;
             }
         }


        return (failureReasons.length == 0, failureReasons);
    }

    /// @notice Checks if a user's ERC20 deposit is eligible for withdrawal based on all conditions.
    /// @dev Same logic as `checkWithdrawalEligibilityETH` but checks ERC20 balance.
    /// @param user The address of the user.
    /// @param token The address of the ERC20 token.
    /// @return isEligible True if all conditions are met.
    /// @return reasons Why the user is not eligible (empty array if eligible).
    function checkWithdrawalEligibilityERC20(address user, address token) public view returns (bool isEligible, string[] memory reasons) {
         if (!supportedTokens[token]) revert TokenNotSupported();
        Deposit storage deposit = userDeposits[user];
        if (deposit.erc20Amounts[token] == 0) {
            return (false, new string[](1){"No ERC20 deposit found for this token"});
        }

        // The eligibility logic is the same as ETH after checking balance.
        // This could be refactored into an internal function if desired.
        string[] memory failureReasons = new string[](0);

        // 1. Check Minimum Lock Time
        if (block.timestamp < deposit.lockEndTime) {
            string memory reason = string.concat("Minimum lock time not met (until ", uint256(deposit.lockEndTime).toString(), ")");
             string[] memory temp = new string[](failureReasons.length + 1);
             for(uint i = 0; i < failureReasons.length; i++) { temp[i] = failureReasons[i]; }
             temp[failureReasons.length] = reason;
             failureReasons = temp;
        }

        // 2. Check Chronon Gates
        for (uint i = 0; i < requiredGateIds.length; i++) {
            uint256 gateId = requiredGateIds[i];
            ChrononGate storage gate = chrononGates[gateId];
            if (gate.isActive && gate.forbidsWithdrawal && block.timestamp >= gate.startTime && block.timestamp <= gate.endTime) {
                 string memory reason = string.concat("Chronon Gate ", uint256(gateId).toString(), " forbids withdrawal");
                 string[] memory temp = new string[](failureReasons.length + 1);
                 for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                 temp[failureReasons.length] = reason;
                 failureReasons = temp;
            }
        }

        // 3. Check Quantum States
        for (uint i = 0; i < requiredStateIds.length; i++) {
            uint256 stateId = requiredStateIds[i];
            if (!quantumStates[stateId].isActive) {
                 string memory reason = string.concat("Quantum State ", uint256(stateId).toString(), " is not active");
                 string[] memory temp = new string[](failureReasons.length + 1);
                 for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                 temp[failureReasons.length] = reason;
                 failureReasons = temp;
            }
        }

         // 4. Check Entanglement Bonds
        if (deposit.bondId != 0) {
             EntanglementBond storage bond = entanglementBonds[deposit.bondId];
             if (bond.isActive && !bond.isFulfilled) {
                 string memory reason = string.concat("Entanglement Bond ", uint256(deposit.bondId).toString(), " affecting this deposit is not fulfilled");
                  string[] memory temp = new string[](failureReasons.length + 1);
                  for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                  temp[failureReasons.length] = reason;
                  failureReasons = temp;
             }
         }
        // Also check required bonds set globally
        for (uint i = 0; i < requiredBondIds.length; i++) {
             uint256 bondId = requiredBondIds[i];
             EntanglementBond storage bond = entanglementBonds[bondId];
             if (bond.isActive && !bond.isFulfilled) {
                 string memory reason = string.concat("Required Entanglement Bond ", uint256(bondId).toString(), " is not fulfilled");
                 string[] memory temp = new string[](failureReasons.length + 1);
                 for(uint j = 0; j < failureReasons.length; j++) { temp[j] = failureReasons[j]; }
                 temp[failureReasons.length] = reason;
                 failureReasons = temp;
             }
         }


        return (failureReasons.length == 0, failureReasons);
    }


    // --- Withdrawal Functions (2) ---

    /// @notice Withdraws a specified amount of ETH if the user is eligible based on current conditions.
    /// @param amount The amount of ETH to withdraw.
    function withdrawETH(uint256 amount) public nonReentrant whenNotPaused {
        Deposit storage deposit = userDeposits[msg.sender];
        if (amount == 0) revert InvalidAmount();
        if (amount > deposit.ethAmount) revert InsufficientBalanceForWithdrawal();

        (bool isEligible, string[] memory reasons) = checkWithdrawalEligibilityETH(msg.sender);
        if (!isEligible) {
            // Revert with the first reason for simplicity, or iterate through reasons if needed
            revert NotEligibleForWithdrawal(); // Could add reason string here
        }

        uint256 fee = (amount * adaptiveFrictionRatePermil) / 1000;
        uint256 amountToSend = amount - fee;

        deposit.ethAmount -= amount; // Deduct before transfer

        // Note: ETH fee is kept in the contract and adds to total balance (could be governance controlled later)
        (bool success, ) = payable(msg.sender).call{value: amountToSend}("");
        require(success, "ETH transfer failed");

        emit ETHWithdrawn(msg.sender, amountToSend, fee);
    }

     /// @notice Withdraws a specified amount of ERC20 tokens if the user is eligible based on current conditions.
     /// @param token The address of the ERC20 token.
     /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(address token, uint256 amount) public nonReentrant whenNotPaused {
        if (!supportedTokens[token]) revert TokenNotSupported();
        Deposit storage deposit = userDeposits[msg.sender];
        if (amount == 0) revert InvalidAmount();
        if (amount > deposit.erc20Amounts[token]) revert InsufficientBalanceForWithdrawal();

        (bool isEligible, string[] memory reasons) = checkWithdrawalEligibilityERC20(msg.sender, token);
        if (!isEligible) {
            revert NotEligibleForWithdrawal(); // Could add reason string here
        }

        uint256 fee = (amount * adaptiveFrictionRatePermil) / 1000;
        uint256 amountToSend = amount - fee;

        deposit.erc20Amounts[token] -= amount; // Deduct before transfer

        // Note: ERC20 fee is kept in the contract (could be governance controlled later)
        IERC20(token).safeTransfer(msg.sender, amountToSend);

        emit ERC20Withdrawn(msg.sender, token, amountToSend, fee);
    }


    // --- Admin/Owner Functions (10) ---

    /// @notice Allows the owner to add a supported ERC20 token.
    /// @dev Only supported tokens can be deposited.
    /// @param token The address of the ERC20 token.
    function addSupportedToken(address token) public onlyOwner {
        if (!supportedTokens[token]) {
            supportedTokens[token] = true;
            supportedTokenList.push(token);
            emit TokenSupported(token);
        }
    }

    /// @notice Allows the owner to define a Chronon Gate.
    /// @param startTime The start timestamp of the gate window.
    /// @param endTime The end timestamp of the gate window.
    /// @param forbidsWithdrawal True if being within this gate window should forbid withdrawal.
    /// @return The ID of the newly defined gate.
    function defineChrononGate(uint256 startTime, uint256 endTime, bool forbidsWithdrawal) public onlyOwner returns (uint256) {
        gateCounter++;
        chrononGates[gateCounter] = ChrononGate(startTime, endTime, forbidsWithdrawal, true); // Gates are active by default
        emit ChrononGateDefined(gateCounter, startTime, endTime, forbidsWithdrawal);
        return gateCounter;
    }

    /// @notice Allows the owner to activate or deactivate a defined Chronon Gate.
    /// @dev Only active gates affect withdrawal eligibility.
    /// @param gateId The ID of the gate to update.
    /// @param isActive True to activate, False to deactivate.
    function setChrononGateActiveStatus(uint256 gateId, bool isActive) public onlyOwner {
        if (gateId == 0 || gateId > gateCounter) revert GateDoesNotExist(gateId);
        chrononGates[gateId].isActive = isActive;
        emit ChrononGateStatusUpdated(gateId, isActive);
    }


    /// @notice Allows the owner to define a Quantum State.
    /// @return The ID of the newly defined state.
    function defineQuantumState() public onlyOwner returns (uint256) {
        stateCounter++;
        quantumStates[stateCounter].isActive = false; // States start inactive
        emit QuantumStateDefined(stateCounter);
        return stateCounter;
    }

    /// @notice Allows the owner to activate or deactivate a Quantum State.
    /// @dev This simulates an external condition trigger.
    /// @param stateId The ID of the state to update.
    /// @param isActive True to activate, False to deactivate.
    function setQuantumStateStatus(uint256 stateId, bool isActive) public onlyOwner {
         if (stateId == 0 || stateId > stateCounter) revert StateDoesNotExist(stateId);
        quantumStates[stateId].isActive = isActive;
        emit QuantumStateStatusUpdated(stateId, isActive);
    }

    /// @notice Allows the owner to define an Entanglement Bond between two users/deposits.
    /// @dev Only users with deposits can be bonded. A user can only be in one active bond at a time.
    /// @param userA The address of the first user in the bond.
    /// @param userB The address of the second user in the bond.
    /// @param bondType The type of bond (e.g., 1 for mutual eligibility requirement).
    /// @return The ID of the newly defined bond.
    function defineEntanglementBond(address userA, address userB, uint256 bondType) public onlyOwner returns (uint256) {
        if (userA == address(0) || userB == address(0)) revert InvalidAmount();
        if (userA == userB) revert CannotBondSelf();
        if (userDeposits[userA].lockEndTime == 0 || userDeposits[userB].lockEndTime == 0) revert NoDepositFound(); // Must have deposits
        if (userDeposits[userA].bondId != 0 || userDeposits[userB].bondId != 0) revert AlreadyPartOfBond(userDeposits[userA].bondId != 0 ? userA : userB);
        if (bondType == 0) revert InvalidBondType(); // Basic validation

        bondCounter++;
        entanglementBonds[bondCounter] = EntanglementBond(userA, userB, bondType, false, true); // Bonds start unfulfilled but active
        userDeposits[userA].bondId = bondCounter;
        userDeposits[userB].bondId = bondCounter;
        emit EntanglementBondDefined(bondCounter, userA, userB, bondType);
        return bondCounter;
    }

    /// @notice Allows the owner to mark an Entanglement Bond as fulfilled.
    /// @dev This simulates the condition for the bond being met externally.
    /// @param bondId The ID of the bond to mark as fulfilled.
    function markEntanglementBondFulfilled(uint256 bondId) public onlyOwner {
        if (bondId == 0 || bondId > bondCounter) revert BondDoesNotExist(bondId);
        entanglementBonds[bondId].isFulfilled = true;
        emit EntanglementBondFulfilled(bondId);
    }

     /// @notice Allows the owner to set the required global conditions for withdrawal eligibility.
     /// @dev These conditions are checked *in addition* to the user's individual deposit lock time.
     /// @param _requiredGateIds The array of gate IDs that must *not* be forbidding if active and open.
     /// @param _requiredStateIds The array of state IDs that must be active.
     /// @param _requiredBondIds The array of bond IDs that must be fulfilled if active.
    function setRequiredConditionsForWithdrawal(uint256[] memory _requiredGateIds, uint256[] memory _requiredStateIds, uint256[] memory _requiredBondIds) public onlyOwner {
        // Basic validation: Check if IDs exist (optional, could allow setting for future states/gates/bonds)
        // For simplicity, let's allow setting any ID, validation happens on check
        requiredGateIds = _requiredGateIds;
        requiredStateIds = _requiredStateIds;
        requiredBondIds = _requiredBondIds;
        emit RequiredConditionsUpdated(requiredGateIds, requiredStateIds, requiredBondIds);
    }

    /// @notice Allows the owner to set the adaptive friction rate applied to withdrawals.
    /// @dev Rate is in permil (parts per thousand), e.g., 10 for 1%, 50 for 5%. Max 1000 (100%).
    /// @param newRatePermil The new rate in permil.
    function setAdaptiveFrictionRate(uint256 newRatePermil) public onlyOwner {
        if (newRatePermil > 1000) revert InvalidRate();
        adaptiveFrictionRatePermil = newRatePermil;
        emit AdaptiveFrictionRateUpdated(newRatePermil);
    }

    /// @notice Allows the owner to set the minimum lock duration for *new* deposits.
    /// @param duration The minimum duration in seconds.
    function setDepositMinimumLockDuration(uint256 duration) public onlyOwner {
        depositMinimumLockDuration = duration;
        // Note: This does not affect existing deposits unless they top up before their current lock ends.
        // `extendMyDepositLock` is the way users extend existing locks.
    }


    /// @notice Allows the owner to pause key functionality (deposit, withdrawal).
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to recover accidentally sent ERC20 tokens (not via deposit).
    /// @dev Useful if random tokens are sent to the contract address.
    /// @param token The address of the ERC20 token to recover.
    function recoverStuckERC20(address token) public onlyOwner {
        if (supportedTokens[token]) revert TokenNotSupported(); // Prevent draining deposited tokens
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(owner(), balance);
            emit TokenRecovered(token, balance);
        }
    }

     // --- Internal Utility (1) ---
     // Simple helper for checkWithdrawalEligibility string conversion
     function uint256ToString(uint256 value) internal pure returns (string memory) {
         // Simple implementation for demonstration; libraries like Strings from OpenZeppelin are better
         if (value == 0) {
             return "0";
         }
         uint256 temp = value;
         uint256 digits;
         while (temp != 0) {
             digits++;
             temp /= 10;
         }
         bytes memory buffer = new bytes(digits);
         while (value != 0) {
             digits -= 1;
             buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
             value /= 10;
         }
         return string(buffer);
     }
}
```