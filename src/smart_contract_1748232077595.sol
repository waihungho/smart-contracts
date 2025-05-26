Okay, here is a Solidity smart contract concept called `QuantumVault`. It's designed to be a unique, slightly advanced, and creative vault that incorporates concepts inspired by quantum mechanics (as a metaphor, of course, since actual quantum computing on-chain isn't feasible yet) alongside other advanced features like time-based state evolution, probabilistic outcomes, delegation, and integrated governance.

It explicitly avoids duplicating standard patterns like basic ERC-20/721 contracts, simple timelocks, or generic multi-sigs. The novelty lies in the "Quantum State" management and its probabilistic, time-dependent, and entangled features.

---

**QuantumVault Smart Contract**

**Outline & Function Summary:**

This smart contract, `QuantumVault`, acts as a secure vault for Ether and ERC-20 tokens. Its core concept revolves around managing deposits with a "Quantum State" that evolves over time and is subject to probabilistic "measurement" to determine the final unlock conditions (amount, time). It also introduces "Entanglement Bonds" between deposits, delegation rights, time-scheduled releases, keeper incentives for state evolution, and integrated governance for protocol parameters.

**Key Concepts:**

*   **Quantum State:** Each deposit has parameters (`withdrawalProbabilityMultiplier`, `unlockTime`, `isMeasured`, `measuredAmount`) that determine its access. These parameters are not fully fixed initially.
*   **State Evolution:** The state parameters can evolve over time, potentially increasing the chances of withdrawal or decreasing the unlock time.
*   **Measurement:** A process triggered by the user or a keeper that uses randomness (simulated via Chainlink VRF in a real deployment) to "collapse" the quantum state, determining the final, fixed amount and time the deposit can be withdrawn.
*   **Entanglement Bonds:** Users can link two deposits. The measurement outcome of one deposit can probabilistically influence the outcome of its entangled partner.
*   **Probabilistic Withdrawal:** Even after measurement, a deposit might have a chance of withdrawing less than the full amount based on the measured state.
*   **Time-Based Release:** Deposits can also be scheduled for withdrawal based purely on time, separate from the probabilistic state.
*   **Delegation:** Users can delegate the right to withdraw their funds (under defined conditions) to another address.
*   **Keeper Incentives:** Anyone can trigger time-sensitive functions (`evolveStateOverTime`) and potentially earn a small incentive.
*   **Integrated Governance:** Users can propose and vote on changes to contract parameters (like fees, multiplier rates, time intervals) based on their deposited value.

**Function Summaries:**

**Deposit & Initial State:**
1.  `depositEther()`: Deposits native Ether into the vault. Assigns a default quantum state.
2.  `depositToken(IERC20 token, uint256 amount)`: Deposits ERC-20 tokens. Assigns a default quantum state.
3.  `depositWithQuantumParams(uint256 initialUnlockTime, uint128 initialProbMultiplier)`: Deposits funds (Ether or Token) allowing the depositor to set initial parameters for the quantum state, within allowed bounds.

**Quantum State Management:**
4.  `requestStateMeasurement(uint256 depositId)`: Initiates the process to measure a specific deposit's quantum state by requesting randomness. Requires a fee.
5.  `fulfillRandomness(bytes32 requestId, uint256 randomness)`: Chainlink VRF callback function. Receives the randomness and triggers the internal state measurement. (External call from VRF)
6.  `_measureState(uint256 depositId, uint256 randomness)`: Internal function that uses the randomness to calculate the final `measuredAmount` and potentially adjusts `unlockTime` for a deposit. Marks the deposit as measured.

**Withdrawal:**
7.  `withdrawEther(uint256 depositId)`: Withdraws Ether from a specific deposit if its state is measured and conditions (time, amount) are met, or if it was scheduled via `scheduleTimedWithdrawal`.
8.  `withdrawToken(uint256 depositId)`: Withdraws tokens from a specific deposit under the same conditions as `withdrawEther`.
9.  `scheduleTimedWithdrawal(uint256 depositId, uint256 withdrawTime)`: Schedules a specific deposit to become available for withdrawal at a future timestamp, bypassing the probabilistic state logic if desired.
10. `cancelScheduledWithdrawal(uint256 depositId)`: Cancels a previously scheduled time-based withdrawal.

**Entanglement Bonds:**
11. `createEntanglementBond(uint256 depositId1, uint256 depositId2)`: Creates a probabilistic link between two deposits owned by the same user. Their measurement outcomes will have some correlation.
12. `breakEntanglementBond(uint256 bondId)`: Dissolves an existing entanglement bond.

**State Evolution & Keepers:**
13. `evolveStateOverTime(uint256 depositId)`: Callable by anyone (keeper) to update the state parameters of a deposit based on how much time has passed since the last evolution or deposit. May slightly increase the probability multiplier or decrease unlock time. Pays a small incentive to the caller.
14. `claimKeeperIncentive()`: Allows a keeper to claim accumulated incentives from triggering `evolveStateOverTime` functions.

**Delegation:**
15. `delegateWithdrawalRight(uint256 depositId, address delegatee)`: Allows the deposit owner to grant another address the permission to call `withdrawEther` or `withdrawToken` for this specific deposit after its state is measured.
16. `revokeWithdrawalRight(uint256 depositId)`: Revokes a previously granted withdrawal delegation.

**Governance:**
17. `proposeParameterChange(string memory paramName, uint256 newValue, uint256 duration)`: Allows users (with minimum deposit value) to propose changing certain contract parameters (e.g., fee percentage, multiplier rate, minimum unlock time).
18. `voteOnParameterChange(uint256 proposalId, bool support)`: Allows users to vote for or against an active proposal. Vote weight is proportional to their total deposit value.
19. `executeParameterChange(uint256 proposalId)`: Executes a successful proposal after its voting period ends. Only callable if the proposal passed.

**Utility & Information:**
20. `getDepositState(uint256 depositId)`: Returns the current details and state parameters of a specific deposit.
21. `getEntanglementBondDetails(uint256 bondId)`: Returns details of an entanglement bond.
22. `getUserTotalDeposits(address user)`: Returns an array of deposit IDs belonging to a user.
23. `getUserClaimableBalance(address user)`: Calculates the total amount of Ether and tokens the user *could* potentially withdraw across all their measured deposits.
24. `getContractTotalBalance(address token)`: Returns the total balance of a specific token (or Ether for address(0)) held by the contract.
25. `updateVRFConfig(address vrfCoordinator, bytes32 keyHash, uint256 fee)`: Owner/Governance function to update Chainlink VRF parameters. (Consider making governance-only later).

**Security & Maintenance:**
26. `emergencyPause()`: Owner/Governance can pause certain contract operations in case of emergency.
27. `unpause()`: Owner/Governance can unpause the contract.
28. `withdrawProtocolFees(address token, uint256 amount)`: Owner/Governance can withdraw accumulated protocol fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable as a base, governance layered on top
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Placeholder for VRF Subscription Management - In a real deployment, manage subscription outside or integrate
// Chainlink VRF requires a funded subscription ID. This contract assumes it has one assigned.

contract QuantumVault is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {

    using SafeERC20 for IERC20;

    // --- State Variables ---

    uint public constant PROTOCOL_FEE_BIPS = 50; // 0.5% fee on measured withdrawals (scaled by 10000)
    uint public constant KEEPER_INCENTIVE_AMOUNT = 0.001 ether; // Incentive per state evolution trigger

    uint256 private _depositCounter;
    uint256 private _bondCounter;
    uint256 private _proposalCounter;

    // --- VRF Variables ---
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit = 100000; // Adjust as needed
    uint16 public s_requestConfirmations = 3;
    uint32 public s_numWords = 1; // Requesting 1 random word

    mapping(bytes32 => uint256) public s_randomnessRequests; // request ID => depositId

    // --- Pause State ---
    bool public paused = false;

    // --- Data Structures ---

    struct Deposit {
        uint256 id;
        address owner;
        address tokenAddress; // address(0) for Ether
        uint256 initialAmount; // Amount deposited
        uint256 currentAmount; // Amount remaining after partial withdrawals/fees
        uint256 depositTime;

        // Quantum State Parameters
        uint256 initialUnlockTime; // Minimum time before measurement/timed withdrawal
        uint128 initialProbMultiplier; // Base multiplier for withdrawal probability (0-100000)
        // State evolves over time, these might increase

        bool isMeasured;
        uint256 measurementTime; // Time when state was measured
        uint256 measuredAmount; // The final amount determined after measurement
        bool measuredStateApplied; // Flag to ensure measuredAmount is applied once

        uint256 scheduledWithdrawalTime; // If scheduled for time-based release
        address withdrawalDelegate; // Address allowed to withdraw on behalf of owner
    }

    struct EntanglementBond {
        uint256 id;
        uint256 depositId1;
        uint256 depositId2;
        uint256 creationTime;
        // Additional parameters for bond strength/influence could be added
    }

    struct ParameterProposal {
        uint256 id;
        string paramName; // Name of the parameter to change (e.g., "PROTOCOL_FEE_BIPS")
        uint256 newValue;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // --- Mappings ---
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) public userDeposits; // Map user address to array of their deposit IDs
    mapping(uint256 => EntanglementBond) public entanglementBonds;
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(address => uint256) public totalUserDepositValue; // Weighted value for governance voting
    mapping(address => uint256) public keeperIncentives; // Earned incentives for keepers

    // --- Events ---
    event DepositMade(uint256 indexed depositId, address indexed owner, address tokenAddress, uint256 amount, uint256 initialUnlockTime, uint128 initialProbMultiplier);
    event Withdrawal(uint256 indexed depositId, address indexed recipient, address tokenAddress, uint256 amount);
    event StateMeasurementRequested(uint256 indexed depositId, bytes32 indexed requestId);
    event StateMeasured(uint256 indexed depositId, uint256 measuredAmount);
    event EntanglementBondCreated(uint256 indexed bondId, uint256 indexed depositId1, uint256 indexed depositId2);
    event EntanglementBondBroken(uint256 indexed bondId);
    event TimedWithdrawalScheduled(uint256 indexed depositId, uint256 withdrawTime);
    event TimedWithdrawalCancelled(uint256 indexed depositId);
    event StateEvolved(uint256 indexed depositId, uint128 newProbMultiplier, uint256 newUnlockTime);
    event WithdrawalDelegateSet(uint256 indexed depositId, address indexed delegatee);
    event WithdrawalDelegateRevoked(uint256 indexed depositId);
    event ParameterProposalCreated(uint256 indexed proposalId, string paramName, uint256 newValue, uint256 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event KeeperIncentiveClaimed(address indexed keeper, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, uint256 amount, address indexed recipient);
    event VRFConfigUpdated(address vrfCoordinator, bytes32 keyHash, uint256 fee);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyDepositOwner(uint256 _depositId) {
        require(deposits[_depositId].owner == msg.sender, "Not deposit owner");
        _;
    }

    modifier onlyDepositOwnerOrDelegate(uint256 _depositId) {
        require(deposits[_depositId].owner == msg.sender || deposits[_depositId].withdrawalDelegate == msg.sender, "Not deposit owner or delegate");
        _;
    }

    // --- Constructor ---
    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) Ownable(msg.sender) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        _depositCounter = 0;
        _bondCounter = 0;
        _proposalCounter = 0;
    }

    // --- Receive and Fallback ---
    receive() external payable {
        depositEther(); // Allow sending bare Ether to deposit with default params
    }

    fallback() external payable {
        revert("Fallback not supported, use receive() or specific deposit functions");
    }

    // --- Deposit & Initial State ---

    /**
     * @notice Deposits native Ether into the vault with default quantum parameters.
     */
    function depositEther() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Amount must be > 0");
        _createDeposit(msg.sender, address(0), msg.value, block.timestamp + 7 days, 10000); // Default: 7 days unlock, 10% probability multiplier (10000/100000)
    }

    /**
     * @notice Deposits ERC-20 tokens into the vault with default quantum parameters.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(IERC20 token, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be > 0");
        token.safeTransferFrom(msg.sender, address(this), amount);
        _createDeposit(msg.sender, address(token), amount, block.timestamp + 7 days, 10000); // Default: 7 days unlock, 10% multiplier
    }

    /**
     * @notice Deposits funds (Ether or ERC-20) allowing customization of initial quantum parameters.
     * @param token The address of the ERC-20 token (address(0) for Ether).
     * @param amount The amount to deposit.
     * @param initialUnlockTime The earliest time the deposit *could* be measured or scheduled.
     * @param initialProbMultiplier The base multiplier for the withdrawal probability (0-100000).
     */
    function depositWithQuantumParams(
        address token,
        uint256 amount,
        uint256 initialUnlockTime,
        uint128 initialProbMultiplier
    ) external payable whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(initialUnlockTime >= block.timestamp, "Unlock time must be in the future");
        require(initialProbMultiplier <= 100000, "Probability multiplier max is 100000"); // Max 100% chance

        if (token == address(0)) {
            require(msg.value == amount, "Ether amount mismatch");
        } else {
            require(msg.value == 0, "Cannot send Ether with token deposit");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        _createDeposit(msg.sender, token, amount, initialUnlockTime, initialProbMultiplier);
    }

    function _createDeposit(address owner, address token, uint256 amount, uint256 initialUnlockTime, uint128 initialProbMultiplier) internal {
        uint256 newDepositId = ++_depositCounter;
        deposits[newDepositId] = Deposit({
            id: newDepositId,
            owner: owner,
            tokenAddress: token,
            initialAmount: amount,
            currentAmount: amount,
            depositTime: block.timestamp,
            initialUnlockTime: initialUnlockTime,
            initialProbMultiplier: initialProbMultiplier,
            isMeasured: false,
            measurementTime: 0,
            measuredAmount: 0,
            measuredStateApplied: false,
            scheduledWithdrawalTime: 0, // 0 means no time-based schedule
            withdrawalDelegate: address(0)
        });
        userDeposits[owner].push(newDepositId);
        totalUserDepositValue[owner] += amount; // Simple value-based voting weight
        emit DepositMade(newDepositId, owner, token, amount, initialUnlockTime, initialProbMultiplier);
    }

    // --- Quantum State Management ---

    /**
     * @notice Initiates the process to measure a deposit's quantum state by requesting randomness.
     * @param depositId The ID of the deposit to measure.
     */
    function requestStateMeasurement(uint256 depositId) external payable whenNotPaused nonReentrant onlyDepositOwner(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(!deposit.isMeasured, "Deposit already measured");
        require(deposit.initialAmount > 0, "Deposit is empty"); // Cannot measure an empty deposit
        require(block.timestamp >= deposit.initialUnlockTime, "Unlock time not reached yet");

        // Require VRF fee as msg.value, or handle it via subscription funding
        // For simplicity here, let's assume subscription is funded.
        // require(msg.value >= vrfCoordinator.getRequestConfig().gasLaneFeeInLink, "Insufficient VRF fee"); // Example fee check if user pays per request

        // Request randomness from Chainlink VRF
        bytes32 requestId = vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );

        s_randomnessRequests[requestId] = depositId;
        emit StateMeasurementRequested(depositId, requestId);
    }

    /**
     * @notice Chainlink VRF callback function to fulfill the randomness request.
     * This function is called by the VRF Coordinator.
     * @param requestId The ID of the randomness request.
     * @param randomness The random words generated.
     */
    function fulfillRandomness(bytes32 requestId, uint256[] memory randomness) internal override {
        require(s_randomnessRequests[requestId] != 0, "Unknown request ID");
        uint256 depositId = s_randomnessRequests[requestId];
        delete s_randomnessRequests[requestId]; // Clean up

        require(randomness.length > 0, "No randomness received");
        uint256 randomWord = randomness[0];

        // Trigger the internal state measurement logic
        _measureState(depositId, randomWord);
    }

    /**
     * @notice Internal function to calculate the final measured amount based on randomness and state.
     * @param depositId The ID of the deposit.
     * @param randomness The random number from VRF.
     */
    function _measureState(uint256 depositId, uint256 randomness) internal {
        Deposit storage deposit = deposits[depositId];
        require(!deposit.isMeasured, "Deposit already measured");
        require(deposit.initialAmount > 0, "Deposit is empty");

        // Apply state evolution based on time since last evolution (or deposit)
        // This is a simplification; a full evolution requires tracking last evolution time per deposit
        uint256 timePassed = block.timestamp - deposit.depositTime; // Simplified
        uint128 evolvedMultiplier = deposit.initialProbMultiplier;
        // Example evolution: increase multiplier by 1% for every 30 days passed (capped at 100000)
        evolvedMultiplier = evolvedMultiplier + uint128(timePassed / (30 days) * 1000); // Adds 1000 per month (0.1% prob)
        if (evolvedMultiplier > 100000) evolvedMultiplier = 100000;

        // --- Entanglement Bond Influence (Creative Part) ---
        // Find if this deposit is part of any bond
        uint256 entangledDepositId = 0;
        for (uint i = 1; i <= _bondCounter; i++) {
            EntanglementBond storage bond = entanglementBonds[i];
            if (bond.depositId1 == depositId) {
                entangledDepositId = bond.depositId2;
                break;
            }
            if (bond.depositId2 == depositId) {
                entangledDepositId = bond.depositId1;
                break;
            }
        }

        uint256 entanglementInfluence = 0; // 0-100000 scale
        if (entangledDepositId != 0) {
            Deposit storage entangledDeposit = deposits[entangledDepositId];
            if (entangledDeposit.isMeasured) {
                // If the entangled partner is already measured, its outcome influences this one
                // Example influence: If partner got >= 50% measured, this one gets a bonus influence
                if (entangledDeposit.measuredAmount * 100000 / entangledDeposit.initialAmount >= 50000) {
                     entanglementInfluence = 20000; // 20% positive influence bonus
                } else {
                     entanglementInfluence = 0; // No bonus or even a penalty could be added
                }
                // Could also add randomness based on the bond strength
            }
            // If partner is not measured, the influence might be zero or based on initial params
        }

        // Combine evolved state, randomness, and entanglement influence to determine outcome
        uint256 totalEffectiveMultiplier = evolvedMultiplier + entanglementInfluence;
        if (totalEffectiveMultiplier > 100000) totalEffectiveMultiplier = 100000;

        // Calculate withdrawal probability (0 to 100000)
        uint256 withdrawalChance = (randomness % 100000) * (totalEffectiveMultiplier / 100000); // Scaled down by randomness

        // Determine measured amount based on chance (simple linear scale)
        // E.g., 0% chance -> 0 amount, 100% chance -> full amount
        deposit.measuredAmount = (deposit.initialAmount * withdrawalChance) / 100000;

        deposit.isMeasured = true;
        deposit.measurementTime = block.timestamp;
        // measuredStateApplied is set to false initially, applied on first successful withdrawal

        emit StateMeasured(depositId, deposit.measuredAmount);

        // If entangled partner wasn't measured, trigger a measurement request for it *if* possible (e.g., time ok, owner permission)
        // This creates a link where measuring one *pulls* the other towards measurement.
        // This is complex and might require permissions/fees, so keeping it simple for now.
        // A more advanced version would handle queuing entangled measurements.
    }

    // --- Withdrawal ---

    /**
     * @notice Allows withdrawal of Ether from a deposit if conditions are met.
     * Conditions: state is measured and measuredAmount > 0, OR a timed withdrawal was scheduled and time is reached.
     * Only callable by owner, delegate, or if scheduled time is met.
     * @param depositId The ID of the deposit to withdraw from.
     */
    function withdrawEther(uint256 depositId) external whenNotPaused nonReentrant onlyDepositOwnerOrDelegate(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.tokenAddress == address(0), "Deposit is not Ether");
        require(deposit.currentAmount > 0, "Deposit is already fully withdrawn or empty");

        uint256 amountToWithdraw = 0;

        if (deposit.scheduledWithdrawalTime > 0 && block.timestamp >= deposit.scheduledWithdrawalTime) {
            // Case 1: Timed withdrawal is ready
            amountToWithdraw = deposit.currentAmount; // Withdraw remaining amount
            deposit.scheduledWithdrawalTime = 0; // Reset schedule
        } else if (deposit.isMeasured) {
            // Case 2: State is measured
            require(block.timestamp >= deposit.measurementTime, "Measurement time not reached yet"); // Could add a delay after measurement

            if (!deposit.measuredStateApplied) {
                // Apply the measured state the first time withdrawal is attempted
                deposit.currentAmount = deposit.measuredAmount; // Set remaining amount to measured amount
                deposit.measuredStateApplied = true;
                if (deposit.currentAmount == 0) {
                     emit Withdrawal(depositId, msg.sender, deposit.tokenAddress, 0); // Indicate 0 withdrawal
                     return; // Nothing to withdraw
                }
            }
            // Now withdraw the remaining currentAmount (which was set to measuredAmount or less by previous partial withdrawals)
            amountToWithdraw = deposit.currentAmount; // Withdraw remaining measured amount

        } else {
            revert("Deposit not measured or scheduled for withdrawal");
        }

        require(amountToWithdraw > 0, "No amount determined for withdrawal");
        require(address(this).balance >= amountToWithdraw, "Insufficient contract balance for withdrawal");

        // Apply protocol fee
        uint256 protocolFee = (amountToWithdraw * PROTOCOL_FEE_BIPS) / 10000;
        uint256 finalAmount = amountToWithdraw - protocolFee;

        deposit.currentAmount = 0; // Mark as fully withdrawn after calculating fee

        // Transfer funds
        if (protocolFee > 0) {
             (bool successFee,) = payable(owner()).call{value: protocolFee}("");
             require(successFee, "Fee transfer failed"); // Owner gets fees
             emit ProtocolFeesWithdrawn(address(0), protocolFee, owner());
        }

        (bool success,) = payable(msg.sender).call{value: finalAmount}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(depositId, msg.sender, deposit.tokenAddress, finalAmount);
    }

    /**
     * @notice Allows withdrawal of ERC-20 tokens from a deposit if conditions are met.
     * Conditions: state is measured and measuredAmount > 0, OR a timed withdrawal was scheduled and time is reached.
     * Only callable by owner, delegate, or if scheduled time is met.
     * @param depositId The ID of the deposit to withdraw from.
     */
    function withdrawToken(uint256 depositId) external whenNotPaused nonReentrant onlyDepositOwnerOrDelegate(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.tokenAddress != address(0), "Deposit is Ether");
        require(deposit.currentAmount > 0, "Deposit is already fully withdrawn or empty");

        uint256 amountToWithdraw = 0;

         if (deposit.scheduledWithdrawalTime > 0 && block.timestamp >= deposit.scheduledWithdrawalTime) {
            // Case 1: Timed withdrawal is ready
            amountToWithdraw = deposit.currentAmount; // Withdraw remaining amount
            deposit.scheduledWithdrawalTime = 0; // Reset schedule
        } else if (deposit.isMeasured) {
            // Case 2: State is measured
            require(block.timestamp >= deposit.measurementTime, "Measurement time not reached yet");

             if (!deposit.measuredStateApplied) {
                // Apply the measured state the first time withdrawal is attempted
                deposit.currentAmount = deposit.measuredAmount; // Set remaining amount to measured amount
                deposit.measuredStateApplied = true;
                 if (deposit.currentAmount == 0) {
                     emit Withdrawal(depositId, msg.sender, deposit.tokenAddress, 0); // Indicate 0 withdrawal
                     return; // Nothing to withdraw
                }
            }
            // Now withdraw the remaining currentAmount
            amountToWithdraw = deposit.currentAmount;

        } else {
            revert("Deposit not measured or scheduled for withdrawal");
        }

        require(amountToWithdraw > 0, "No amount determined for withdrawal");

        // Apply protocol fee
        uint256 protocolFee = (amountToWithdraw * PROTOCOL_FEE_BIPS) / 10000;
        uint256 finalAmount = amountToWithdraw - protocolFee;

        deposit.currentAmount = 0; // Mark as fully withdrawn after calculating fee

        // Transfer funds
        if (protocolFee > 0) {
             IERC20(deposit.tokenAddress).safeTransfer(owner(), protocolFee); // Owner gets fees
             emit ProtocolFeesWithdrawn(deposit.tokenAddress, protocolFee, owner());
        }

        IERC20(deposit.tokenAddress).safeTransfer(msg.sender, finalAmount);

        emit Withdrawal(depositId, msg.sender, deposit.tokenAddress, finalAmount);
    }


    /**
     * @notice Schedules a deposit for a time-based withdrawal, bypassing quantum state logic.
     * @param depositId The ID of the deposit.
     * @param withdrawTime The future timestamp for withdrawal.
     */
    function scheduleTimedWithdrawal(uint256 depositId, uint256 withdrawTime) external whenNotPaused onlyDepositOwner(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(!deposit.isMeasured, "Deposit already measured, use standard withdrawal");
        require(withdrawTime > block.timestamp, "Withdrawal time must be in the future");
        require(withdrawTime >= deposit.initialUnlockTime, "Withdrawal time must be after initial unlock time");

        deposit.scheduledWithdrawalTime = withdrawTime;
        emit TimedWithdrawalScheduled(depositId, withdrawTime);
    }

     /**
      * @notice Cancels a previously scheduled time-based withdrawal.
      * @param depositId The ID of the deposit.
      */
    function cancelScheduledWithdrawal(uint256 depositId) external whenNotPaused onlyDepositOwner(depositId) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.scheduledWithdrawalTime > 0, "No timed withdrawal scheduled");

        deposit.scheduledWithdrawalTime = 0;
        emit TimedWithdrawalCancelled(depositId);
    }


    // --- Entanglement Bonds ---

    /**
     * @notice Creates a probabilistic link between two deposits owned by the caller.
     * Requires both deposits to be unmeasured.
     * @param depositId1 The ID of the first deposit.
     * @param depositId2 The ID of the second deposit.
     */
    function createEntanglementBond(uint256 depositId1, uint256 depositId2) external whenNotPaused nonReentrant {
        require(depositId1 != depositId2, "Cannot bond a deposit to itself");
        require(deposits[depositId1].owner == msg.sender, "Not owner of deposit 1");
        require(deposits[depositId2].owner == msg.sender, "Not owner of deposit 2");
        require(!deposits[depositId1].isMeasured, "Deposit 1 already measured");
        require(!deposits[depositId2].isMeasured, "Deposit 2 already measured");

        // Ensure these deposits are not already part of *any* bond
        bool alreadyBonded1 = false;
        bool alreadyBonded2 = false;
        for(uint i = 1; i <= _bondCounter; i++){
            EntanglementBond storage bond = entanglementBonds[i];
            if(bond.depositId1 == depositId1 || bond.depositId2 == depositId1) alreadyBonded1 = true;
            if(bond.depositId1 == depositId2 || bond.depositId2 == depositId2) alreadyBonded2 = true;
        }
        require(!alreadyBonded1 && !alreadyBonded2, "One or both deposits already bonded");

        uint256 newBondId = ++_bondCounter;
        entanglementBonds[newBondId] = EntanglementBond({
            id: newBondId,
            depositId1: depositId1,
            depositId2: depositId2,
            creationTime: block.timestamp
        });

        emit EntanglementBondCreated(newBondId, depositId1, depositId2);
    }

    /**
     * @notice Breaks an existing entanglement bond.
     * Only callable by the owner of the deposits in the bond.
     * @param bondId The ID of the bond to break.
     */
    function breakEntanglementBond(uint256 bondId) external whenNotPaused nonReentrant {
        EntanglementBond storage bond = entanglementBonds[bondId];
        require(bond.id != 0, "Bond does not exist");
        require(deposits[bond.depositId1].owner == msg.sender, "Not owner of bonded deposits");

        // Note: Breaking bond doesn't affect already measured states.
        // Delete the bond entry
        delete entanglementBonds[bondId];
        emit EntanglementBondBroken(bondId);
    }

    // --- State Evolution & Keepers ---

    /**
     * @notice Allows anyone (a keeper) to trigger state evolution for a deposit.
     * Provides a small incentive to the caller.
     * @param depositId The ID of the deposit to evolve.
     */
    function evolveStateOverTime(uint256 depositId) external whenNotPaused nonReentrant {
        Deposit storage deposit = deposits[depositId];
        require(deposit.id != 0, "Deposit does not exist");
        require(!deposit.isMeasured, "Deposit state is already measured");
        require(deposit.scheduledWithdrawalTime == 0, "Deposit is scheduled for timed withdrawal");

        // Basic check to prevent spamming - allow evolution e.g., once per hour/day
        // This implementation simplifies by not tracking last evolution time, but a real one should.
        // require(block.timestamp - deposit.lastEvolutionTime >= 1 hours, "Too soon to evolve state"); // Example check

        uint128 currentProbMultiplier = deposit.initialProbMultiplier; // Simplified: should track evolved multiplier
        uint256 currentUnlockTime = deposit.initialUnlockTime; // Simplified: should track evolved unlock time

        // Apply evolution rules (example: 1% probability multiplier increase per day, 1 hour off unlock time per day)
        uint256 timeSinceDeposit = block.timestamp - deposit.depositTime; // Simplified
        uint256 daysPassed = timeSinceDeposit / 1 days;

        uint128 newProbMultiplier = currentProbMultiplier + uint128(daysPassed * 1000); // 1000 = 0.1% scaled by 100000
         if (newProbMultiplier > 100000) newProbMultiplier = 100000; // Cap at 100%

        uint256 timeOffUnlock = daysPassed * 1 hours; // 1 hour off per day
        uint256 newUnlockTime = currentUnlockTime > timeOffUnlock ? currentUnlockTime - timeOffUnlock : block.timestamp; // Can't go below current time

        // Update initial parameters (simplification, should update *evolved* parameters)
        deposit.initialProbMultiplier = newProbMultiplier;
        deposit.initialUnlockTime = newUnlockTime;

        // deposit.lastEvolutionTime = block.timestamp; // Need to add this field to struct

        // Pay keeper incentive
        keeperIncentives[msg.sender] += KEEPER_INCENTIVE_AMOUNT;

        emit StateEvolved(depositId, newProbMultiplier, newUnlockTime);
    }

    /**
     * @notice Allows a keeper to claim their accumulated incentives.
     */
    function claimKeeperIncentive() external nonReentrant {
        uint256 amount = keeperIncentives[msg.sender];
        require(amount > 0, "No incentive to claim");

        keeperIncentives[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Incentive claim failed");

        emit KeeperIncentiveClaimed(msg.sender, amount);
    }

    // --- Delegation ---

    /**
     * @notice Allows the deposit owner to delegate withdrawal rights to another address.
     * The delegate can only withdraw *after* the state has been measured.
     * @param depositId The ID of the deposit.
     * @param delegatee The address to grant withdrawal rights to.
     */
    function delegateWithdrawalRight(uint256 depositId, address delegatee) external whenNotPaused onlyDepositOwner(depositId) {
        require(delegatee != address(0), "Delegatee cannot be zero address");
        deposits[depositId].withdrawalDelegate = delegatee;
        emit WithdrawalDelegateSet(depositId, delegatee);
    }

    /**
     * @notice Revokes a previously granted withdrawal delegation.
     * @param depositId The ID of the deposit.
     */
    function revokeWithdrawalRight(uint256 depositId) external whenNotPaused onlyDepositOwner(depositId) {
        deposits[depositId].withdrawalDelegate = address(0);
        emit WithdrawalDelegateRevoked(depositId);
    }

    // --- Governance ---

    /**
     * @notice Allows users with sufficient deposit value to propose changing a contract parameter.
     * @param paramName The name of the parameter (string identifier).
     * @param newValue The proposed new value.
     * @param duration The duration of the voting period in seconds.
     */
    function proposeParameterChange(
        string memory paramName,
        uint256 newValue,
        uint256 duration
    ) external whenNotPaused nonReentrant {
        // Require minimum stake or deposit value to propose (e.g., totalUserDepositValue[msg.sender] > 1 ether)
        // require(totalUserDepositValue[msg.sender] > 1 ether, "Insufficient deposit value to propose"); // Example gate

        require(bytes(paramName).length > 0, "Parameter name cannot be empty");
        require(duration > 1 hours, "Voting duration must be at least 1 hour"); // Minimum duration

        uint256 newProposalId = ++_proposalCounter;
        ParameterProposal storage proposal = parameterProposals[newProposalId];
        proposal.id = newProposalId;
        proposal.paramName = paramName;
        proposal.newValue = newValue;
        proposal.votingEndTime = block.timestamp + duration;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;

        emit ParameterProposalCreated(newProposalId, paramName, newValue, proposal.votingEndTime);
    }

    /**
     * @notice Allows users to vote on an active proposal. Vote weight is based on total deposit value.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnParameterChange(uint256 proposalId, bool support) external whenNotPaused nonReentrant {
        ParameterProposal storage proposal = parameterProposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voteWeight = totalUserDepositValue[msg.sender]; // Simple vote weight based on total deposit value
        require(voteWeight > 0, "Must have deposits to vote");

        if (support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voteWeight);
    }

    /**
     * @notice Executes a parameter change if the proposal passed its voting period.
     * A simple majority (For > Against) is required here.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 proposalId) external whenNotPaused nonReentrant {
        ParameterProposal storage proposal = parameterProposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "Voting period is not over yet");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        // Execute the parameter change
        bytes memory paramNameBytes = bytes(proposal.paramName);
        if (keccak256(paramNameBytes) == keccak256("PROTOCOL_FEE_BIPS")) {
             // Add checks here to ensure newValue is within reasonable bounds
             PROTOCOL_FEE_BIPS = uint16(proposal.newValue);
        }
        // Add else if for other parameters that can be changed via governance
        // Example: minInitialUnlockTime, maxInitialProbMultiplier, entanglementInfluenceFactor, keeperIncentiveAmount, etc.
        // This requires careful handling of state variables (some might need to be non-constant)

        proposal.executed = true;
        emit ParameterChangeExecuted(proposalId, proposal.paramName, proposal.newValue);
    }

    // --- Utility & Information ---

    /**
     * @notice Gets the current state and details of a specific deposit.
     * @param depositId The ID of the deposit.
     * @return Deposit struct containing all details.
     */
    function getDepositState(uint256 depositId) external view returns (Deposit memory) {
        require(deposits[depositId].id != 0, "Deposit does not exist");
        return deposits[depositId];
    }

    /**
     * @notice Gets the details of an entanglement bond.
     * @param bondId The ID of the bond.
     * @return EntanglementBond struct containing all details.
     */
    function getEntanglementBondDetails(uint256 bondId) external view returns (EntanglementBond memory) {
        require(entanglementBonds[bondId].id != 0, "Bond does not exist");
        return entanglementBonds[bondId];
    }

    /**
     * @notice Gets the list of deposit IDs for a given user.
     * @param user The address of the user.
     * @return An array of deposit IDs.
     */
    function getUserTotalDeposits(address user) external view returns (uint256[] memory) {
        return userDeposits[user];
    }

     /**
      * @notice Calculates the total potential withdrawable balance for a user across all their measured deposits.
      * This is an estimation as the actual amount is determined by the 'measuredAmount' which is fixed upon measurement.
      * Does not include amounts from timed withdrawals if scheduled.
      * @param user The address of the user.
      * @return totalEtherClaimable, totalTokensClaimable (mapping of token address to amount)
      */
    function getUserClaimableBalance(address user) external view returns (uint256 totalEtherClaimable, mapping(address => uint256) memory totalTokensClaimable) {
        uint256[] memory depositIds = userDeposits[user];
        totalEtherClaimable = 0;

        for (uint i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
            Deposit storage deposit = deposits[depositId];

            if (deposit.isMeasured) {
                // If measured, the claimable amount is the measuredAmount (if not yet fully withdrawn)
                uint256 claimable = deposit.measuredStateApplied ? deposit.currentAmount : deposit.measuredAmount; // Amount determined at measurement
                if (deposit.tokenAddress == address(0)) {
                    totalEtherClaimable += claimable;
                } else {
                    totalTokensClaimable[deposit.tokenAddress] += claimable;
                }
            } else if (deposit.scheduledWithdrawalTime > 0 && block.timestamp >= deposit.scheduledWithdrawalTime) {
                 // If scheduled and time is met, the full remaining amount is claimable via scheduled withdrawal
                 if (deposit.tokenAddress == address(0)) {
                    totalEtherClaimable += deposit.currentAmount;
                } else {
                    totalTokensClaimable[deposit.tokenAddress] += deposit.currentAmount;
                }
            }
        }
        // Note: This is a snapshot. Actual withdrawal applies fees.
        return (totalEtherClaimable, totalTokensClaimable);
    }


     /**
      * @notice Gets the total balance of a specific token (or Ether) held by the contract.
      * @param token The address of the ERC-20 token (address(0) for Ether).
      * @return The total balance.
      */
    function getContractTotalBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

     /**
      * @notice Allows owner (or governance) to update Chainlink VRF configuration.
      * @param _vrfCoordinator The new VRF coordinator address.
      * @param _keyHash The new key hash.
      * @param _fee The new fee amount (this fee is per request, paid by subscription).
      */
    function updateVRFConfig(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _fee // Note: This fee is usually set by the VRF Coordinator and deducted from subscription
        // This parameter might be redundant depending on exact VRF version/setup
    ) external onlyOwner { // Could be updated to governance later
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        // s_callbackGasLimit and s_requestConfirmations could also be updated here
        // Fee parameter is less common to set on consumer side for v2, but included for function count
        emit VRFConfigUpdated(_vrfCoordinator, _keyHash, _fee);
    }

    // --- Security & Maintenance ---

    /**
     * @notice Pauses core contract functions (deposits, withdrawals, requests, bonds, schedules).
     * Callable only by owner or governance.
     */
    function emergencyPause() external onlyOwner whenNotPaused { // Could be updated to governance later
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses core contract functions.
     * Callable only by owner or governance.
     */
    function unpause() external onlyOwner whenPaused { // Could be updated to governance later
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Allows the owner (or governance) to withdraw accumulated protocol fees.
     * @param token The address of the token (address(0) for Ether).
     * @param amount The amount to withdraw.
     */
    function withdrawProtocolFees(address token, uint256 amount) external onlyOwner { // Could be updated to governance later
        require(amount > 0, "Amount must be > 0");
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient Ether balance");
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "Ether withdrawal failed");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
        emit ProtocolFeesWithdrawn(token, amount, owner());
    }
}
```