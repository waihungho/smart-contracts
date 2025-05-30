Okay, let's create a smart contract that incorporates several advanced, creative, and somewhat trendy concepts like state-dependent access, multi-factor unlocking inspired by physics metaphors (like "entanglement" and "collapse"), commitment/reveal schemes, oracle interaction, time/block dependencies, and pseudo-probabilistic events.

We'll call it `QuantumLocker`. It will hold funds (ETH or ERC20) that can only be accessed after a complex set of conditions are met, simulating a "quantum entanglement collapse."

**Outline & Function Summary**

*   **Contract Name:** `QuantumLocker`
*   **Purpose:** A smart contract vault designed to hold assets (ETH, ERC20) that can only be unlocked and withdrawn under a complex, multi-faceted set of conditions defined as a "Quantum Entanglement State."
*   **Key Concepts:**
    *   **State Machine:** The locker progresses through defined states (`Idle`, `ParametersSet`, `CommitmentPeriod`, `RevealPeriod`, `Entangled`, `Collapsed`, `FailedMeasurement`).
    *   **Entanglement State:** A set of parameters (`unlockTime`, `targetBlockHash`, `oracleValueRange`, `secretHashValidityRule`, `commitmentRevealDeadline`) that must collectively be satisfied for the locker to "collapse" and unlock.
    *   **Commitment/Reveal:** A standard cryptographic pattern used here to ensure a secret input for the unlock condition isn't known too early.
    *   **Oracle Interaction:** Dependency on external data provided via a trusted oracle or observer.
    *   **Time & Block Dependency:** Conditions based on timestamps and block hashes.
    *   **Pseudo-Probabilistic Unlock ("Quantum Fluctuation"):** A separate, low-probability unlock path based on block data after a long waiting period.
    *   **Fees:** A small fee is taken on failed collapse attempts or potentially successful fluctuation unlocks.
    *   **Access Control:** Owner and Observer roles.

*   **Functions:**

    1.  `constructor(address initialOwner, address initialFeeRecipient)`: Initializes the contract, setting owner and fee recipient.
    2.  `receive() external payable`: Allows receiving ETH deposits.
    3.  `depositETH() external payable`: Explicit function for ETH deposit (redundant with receive, but good practice to have).
    4.  `depositERC20(address tokenAddress, uint256 amount) external`: Allows depositing ERC20 tokens.
    5.  `withdrawETH() external`: Withdraws all ETH if the locker is in the `Collapsed` state.
    6.  `withdrawERC20(address tokenAddress) external`: Withdraws all of a specific ERC20 token if the locker is in the `Collapsed` state.
    7.  `setEntanglementStateParameters(uint64 _unlockTime, bytes32 _targetBlockHash, address _oracleContract, int256 _oracleValueRangeMin, int256 _oracleValueRangeMax, uint64 _commitmentRevealDeadline, bytes32 _secretHashValidityRule)`: Sets the parameters for the required "Entanglement State". Moves state to `ParametersSet`. Only callable when `Idle`.
    8.  `modifyEntanglementParametersBeforeCommit(uint64 _unlockTime, bytes32 _targetBlockHash, address _oracleContract, int256 _oracleValueRangeMin, int256 _oracleValueRangeMax, uint64 _commitmentRevealDeadline, bytes32 _secretHashValidityRule)`: Allows modification of parameters if state is `ParametersSet` and before commitment period starts.
    9.  `startCommitmentPeriod() external`: Moves state from `ParametersSet` to `CommitmentPeriod`. Callable by Owner/Observer.
    10. `commitToSecret(bytes32 commitment) external`: Allows anyone to commit a hash of their secret value. Callable only during `CommitmentPeriod`.
    11. `startRevealPeriod() external`: Moves state from `CommitmentPeriod` to `RevealPeriod` after commitment deadline or manually by Owner/Observer.
    12. `revealSecretAndAttemptCollapse(uint256 revealedSecret) external`: Reveals the secret, checks against the commitment, checks if the revealed secret's hash satisfies the `secretHashValidityRule`, and attempts collapse if other conditions are also met. Moves state to `Collapsed`, `FailedMeasurement`, or `Entangled`. Callable only during `RevealPeriod`.
    13. `provideOracleMeasurement(int256 value) external`: Allows the designated oracle contract (or Observer) to provide the current measurement value. Updates internal state.
    14. `attemptQuantumCollapseAndUnlock() external`: Attempts to collapse the entanglement state and unlock the locker by checking *all* current conditions *without* revealing a secret. Moves state to `Collapsed` or `Entangled`. Callable when in `Entangled` state.
    15. `attemptFluctuationUnlock() external`: Attempts a pseudo-probabilistic unlock based on block data after a specified long waiting period has passed the initial `unlockTime`. Takes a fee on success. Moves state to `Collapsed` or stays `Entangled`.
    16. `resetEntanglementState() external`: Resets the locker to the `Idle` state, clearing all parameters and commitments. Callable by Owner/Observer after reveal deadline or a failed measurement.
    17. `setObserver(address _observer) external`: Sets the address of the designated observer.
    18. `getEthBalance() public view returns (uint256)`: Gets the current ETH balance of the contract.
    19. `getERC20Balance(address tokenAddress) public view returns (uint256)`: Gets the current balance of a specific ERC20 token.
    20. `getCurrentState() public view returns (LockerState)`: Gets the current state of the locker.
    21. `getEntanglementStateParameters() public view returns (EntanglementState memory)`: Gets the currently set entanglement parameters.
    22. `getCommitmentHash(address committer) public view returns (bytes32)`: Gets the commitment hash for a specific address.
    23. `getSecretRevealedStatus() public view returns (bool, uint256)`: Gets whether a secret has been revealed and the revealed value (if any).
    24. `checkEntanglementCollapseCondition() public view returns (bool)`: Checks if the *current* state (time, block, oracle, revealed secret validity) meets the required conditions for collapse. Does not change state.
    25. `isTimePastUnlock() public view returns (bool)`: Checks if the current block timestamp is past the `unlockTime`.
    26. `isBlockHashMatch() public view returns (bool)`: Checks if the current block hash matches the `targetBlockHash` (requires looking back up to 256 blocks).
    27. `isOracleValueInRange() public view returns (bool)`: Checks if the last provided oracle value is within the required range.
    28. `checkSecretHashValidityRule(uint256 revealedSecret) public pure returns (bool)`: Checks if the hash of the `revealedSecret` conforms to the `secretHashValidityRule` (e.g., leading zeros).
    29. `getFluctuationUnlockChance(uint256 randomness) public pure returns (uint256 percentage)`: Calculates a pseudo-random chance percentage based on input (e.g., blockhash).
    30. `setFeeRecipient(address _feeRecipient) external`: Sets the address where fees are sent.
    31. `getFeeRecipient() public view returns (address)`: Gets the current fee recipient.
    32. `getCommitmentRevealDeadline() public view returns (uint64)`: Gets the timestamp for the commitment/reveal deadline.
    33. `isCommitmentPeriodOver() public view returns (bool)`: Checks if the commitment deadline has passed.
    34. `isRevealPeriodOver() public view returns (bool)`: Checks if the reveal deadline has passed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: This contract uses block.timestamp and blockhash which are susceptible to miner manipulation,
// especially blockhash which is only available for the last 256 blocks.
// The oracle interaction assumes a trusted oracle or mechanism for providing measurement data.
// The "quantum" terminology is a metaphor to describe complex, state-dependent conditions.

// Outline & Function Summary on top of file per instructions.

contract QuantumLocker is Ownable, ReentrancyGuard {

    enum LockerState {
        Idle,              // Ready to set parameters
        ParametersSet,     // Parameters defined, waiting for commitment period
        CommitmentPeriod,  // Accepting secret commitments
        RevealPeriod,      // Accepting secret reveals and collapse attempts
        Entangled,         // Parameters met, but collapse requires external trigger (attemptCollapse)
        Collapsed,         // Conditions met, locker is unlocked, assets withdrawable
        FailedMeasurement  // Attempted collapse failed, parameters might need reset
    }

    struct EntanglementState {
        uint64 unlockTime;              // Minimum timestamp for collapse
        bytes32 targetBlockHash;        // Target block hash (0 if not used, must be recent)
        address oracleContract;         // Address of oracle providing measurement (can be self or observer)
        int256 oracleValueRangeMin;     // Minimum value from oracle measurement
        int256 oracleValueRangeMax;     // Maximum value from oracle measurement
        uint64 commitmentRevealDeadline;// Deadline for commitment and reveal
        bytes32 secretHashValidityRule; // Hash property the revealed secret must meet (e.g., first few bytes)
        bool paramsAreSet;              // Flag indicating if parameters have been set
    }

    LockerState public currentState;
    EntanglementState public entanglementState;

    // Mapping of committer address to their secret commitment hash
    mapping(address => bytes32) private commitments;

    // Store the revealed secret and who revealed it
    uint256 private revealedSecretValue;
    address private secretRevealer;
    bool public secretHasBeenRevealed;

    // Store the last provided oracle measurement
    int256 private lastOracleMeasurement;
    bool public oracleMeasurementProvided;

    // Designated observer address (can perform certain admin-like tasks)
    address public observer;

    // Fee settings
    address public feeRecipient;
    uint256 public failedCollapseFee = 0.005 ether; // Example fee
    uint256 public fluctuationUnlockFee = 0.01 ether; // Example fee

    // Minimum time elapsed past unlockTime for fluctuation unlock attempt
    uint64 public minFluctuationDelay = 365 days; // Example: 1 year past unlock time

    event StateChanged(LockerState newState);
    event Deposited(address indexed tokenAddress, address indexed depositor, uint256 amount);
    event Withdrew(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event ParametersSet(EntanglementState params);
    event SecretCommitted(address indexed committer, bytes32 commitment);
    event SecretRevealed(address indexed revealer, uint256 revealedValue);
    event OracleMeasurementReceived(int256 value);
    event CollapseAttempted(address indexed attempter, bool success);
    event Collapsed(address indexed attempter); // Emitted on successful unlock
    event FluctuationAttempted(address indexed attempter, bool success);
    event FeeCollected(address indexed recipient, uint256 amount);
    event EntanglementStateReset();
    event ObserverSet(address indexed newObserver);
    event FeeRecipientSet(address indexed newRecipient);

    // --- Modifiers ---

    modifier whenStateIs(LockerState _state) {
        require(currentState == _state, "QL: Invalid state for this action");
        _;
    }

    modifier whenNotStateIs(LockerState _state) {
         require(currentState != _state, "QL: Action not allowed in this state");
         _;
    }

    modifier onlyObserverOrOwner() {
        require(msg.sender == owner() || msg.sender == observer, "QL: Only owner or observer");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address initialFeeRecipient) Ownable(initialOwner) {
        require(initialFeeRecipient != address(0), "QL: Fee recipient cannot be zero address");
        currentState = LockerState.Idle;
        feeRecipient = initialFeeRecipient;
        emit StateChanged(currentState);
        emit FeeRecipientSet(feeRecipient);
    }

    // --- Deposit Functions ---

    receive() external payable nonReentrant {
        emit Deposited(address(0), msg.sender, msg.value);
    }

    function depositETH() external payable nonReentrant {
        emit Deposited(address(0), msg.sender, msg.value);
    }

    function depositERC20(address tokenAddress, uint256 amount) external nonReentrant {
        require(tokenAddress != address(0), "QL: Invalid token address");
        require(amount > 0, "QL: Amount must be greater than zero");
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore + amount, "QL: Token transfer failed");
        emit Deposited(tokenAddress, msg.sender, amount);
    }

    // --- Withdrawal Functions ---

    function withdrawETH() external nonReentrant whenStateIs(LockerState.Collapsed) {
        uint256 balance = address(this).balance;
        require(balance > 0, "QL: No ETH to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "QL: ETH withdrawal failed");
        emit Withdrew(address(0), msg.sender, balance);
    }

    function withdrawERC20(address tokenAddress) external nonReentrant whenStateIs(LockerState.Collapsed) {
        require(tokenAddress != address(0), "QL: Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "QL: No ERC20 balance to withdraw");
        token.transfer(msg.sender, balance);
        emit Withdrew(tokenAddress, msg.sender, balance);
    }

    // --- Entanglement State Setup ---

    function setEntanglementStateParameters(
        uint64 _unlockTime,
        bytes32 _targetBlockHash,
        address _oracleContract,
        int256 _oracleValueRangeMin,
        int256 _oracleValueRangeMax,
        uint64 _commitmentRevealDeadline,
        bytes32 _secretHashValidityRule
    ) external onlyOwner whenStateIs(LockerState.Idle) {
        require(_commitmentRevealDeadline > block.timestamp, "QL: Deadline must be in the future");
        if (_targetBlockHash != bytes32(0)) {
             require(block.number >= 1 && block.number - 1 < 256, "QL: Target blockhash must be within last 256 blocks (or set to 0)"); // Check validity range if non-zero
        }
        if (_oracleContract != address(0)) {
             require(msg.sender != _oracleContract, "QL: Oracle contract cannot be the owner"); // Avoid self-oracle unless observer is used
        }
        require(_unlockTime >= block.timestamp, "QL: Unlock time must be in the future or now");


        entanglementState = EntanglementState({
            unlockTime: _unlockTime,
            targetBlockHash: _targetBlockHash,
            oracleContract: _oracleContract,
            oracleValueRangeMin: _oracleValueRangeMin,
            oracleValueRangeMax: _oracleValueRangeMax,
            commitmentRevealDeadline: _commitmentRevealDeadline,
            secretHashValidityRule: _secretHashValidityRule,
            paramsAreSet: true
        });

        currentState = LockerState.ParametersSet;
        emit ParametersSet(entanglementState);
        emit StateChanged(currentState);
    }

     function modifyEntanglementParametersBeforeCommit(
        uint64 _unlockTime,
        bytes32 _targetBlockHash,
        address _oracleContract,
        int256 _oracleValueRangeMin,
        int256 _oracleValueRangeMax,
        uint64 _commitmentRevealDeadline,
        bytes32 _secretHashValidityRule
    ) external onlyObserverOrOwner whenStateIs(LockerState.ParametersSet) {
        require(_commitmentRevealDeadline > block.timestamp, "QL: Deadline must be in the future");
        if (_targetBlockHash != bytes32(0)) {
             require(block.number >= 1 && block.number - 1 < 256, "QL: Target blockhash must be within last 256 blocks (or set to 0)");
        }
         if (_oracleContract != address(0)) {
             require(msg.sender != _oracleContract, "QL: Oracle contract cannot be the owner");
        }
        require(_unlockTime >= block.timestamp, "QL: Unlock time must be in the future or now");

        entanglementState.unlockTime = _unlockTime;
        entanglementState.targetBlockHash = _targetBlockHash;
        entanglementState.oracleContract = _oracleContract;
        entanglementState.oracleValueRangeMin = _oracleValueRangeMin;
        entanglementState.oracleValueRangeMax = _oracleValueRangeMax;
        entanglementState.commitmentRevealDeadline = _commitmentRevealDeadline;
        entanglementState.secretHashValidityRule = _secretHashValidityRule;

        emit ParametersSet(entanglementState); // Emit again as parameters were modified
    }


    function startCommitmentPeriod() external onlyObserverOrOwner whenStateIs(LockerState.ParametersSet) {
        require(entanglementState.paramsAreSet, "QL: Parameters not set");
        currentState = LockerState.CommitmentPeriod;
        emit StateChanged(currentState);
    }

    function startRevealPeriod() external onlyObserverOrOwner whenStateIs(LockerState.CommitmentPeriod) {
         require(block.timestamp < entanglementState.commitmentRevealDeadline, "QL: Cannot start reveal after deadline"); // Optional: Allow manual start before deadline
        currentState = LockerState.RevealPeriod;
        emit StateChanged(currentState);
    }

    // --- Entanglement Interaction ---

    // Standard commit function
    function commitToSecret(bytes32 commitment) external whenStateIs(LockerState.CommitmentPeriod) {
        require(block.timestamp < entanglementState.commitmentRevealDeadline, "QL: Commitment period has ended");
        require(commitments[msg.sender] == bytes32(0), "QL: Already committed");
        require(commitment != bytes32(0), "QL: Commitment cannot be zero");
        commitments[msg.sender] = commitment;
        emit SecretCommitted(msg.sender, commitment);
    }

    // Reveal function that also attempts collapse
    function revealSecretAndAttemptCollapse(uint256 revealedSecret) external nonReentrant whenStateIs(LockerState.RevealPeriod) {
        require(block.timestamp < entanglementState.commitmentRevealDeadline, "QL: Reveal period has ended");

        bytes32 expectedCommitment = commitments[msg.sender];
        require(expectedCommitment != bytes32(0), "QL: No commitment found for sender");

        bytes32 calculatedCommitment = keccak256(abi.encodePacked(revealedSecret));
        require(calculatedCommitment == expectedCommitment, "QL: Revealed secret does not match commitment");

        // Store revealed secret and mark as revealed
        revealedSecretValue = revealedSecret;
        secretRevealer = msg.sender;
        secretHasBeenRevealed = true;
        emit SecretRevealed(msg.sender, revealedSecret);

        // Check all collapse conditions including the revealed secret rule
        bool collapseSuccessful = checkEntanglementCollapseCondition();

        emit CollapseAttempted(msg.sender, collapseSuccessful);

        if (collapseSuccessful) {
            currentState = LockerState.Collapsed;
            emit Collapsed(msg.sender);
            emit StateChanged(currentState);
        } else {
             // Optional: Take a fee on failed attempt after revealing
             if (feeRecipient != address(0) && address(this).balance >= failedCollapseFee) {
                 (bool success, ) = payable(feeRecipient).call{value: failedCollapseFee}("");
                 if (success) {
                     emit FeeCollected(feeRecipient, failedCollapseFee);
                 }
             }
            currentState = LockerState.FailedMeasurement; // Transition to a state requiring reset
            emit StateChanged(currentState);
        }
    }

    // Function to provide external oracle data
    function provideOracleMeasurement(int256 value) external nonReentrant {
        require(msg.sender == entanglementState.oracleContract || msg.sender == observer, "QL: Not authorized to provide measurement");
        require(entanglementState.paramsAreSet, "QL: Parameters not set");

        lastOracleMeasurement = value;
        oracleMeasurementProvided = true;
        emit OracleMeasurementReceived(value);

        // Optional: Automatically attempt collapse if in Entangled state and conditions might now be met
        if (currentState == LockerState.Entangled && checkEntanglementCollapseCondition()) {
             attemptQuantumCollapseAndUnlock(); // Try collapsing immediately
        }
    }

    // Attempt collapse without needing to reveal secret again (if conditions are met)
    function attemptQuantumCollapseAndUnlock() external nonReentrant whenStateIs(LockerState.Entangled) {
        require(secretHasBeenRevealed, "QL: Secret must be revealed before attempting collapse");

        bool collapseSuccessful = checkEntanglementCollapseCondition();

        emit CollapseAttempted(msg.sender, collapseSuccessful);

        if (collapseSuccessful) {
            currentState = LockerState.Collapsed;
            emit Collapsed(msg.sender);
            emit StateChanged(currentState);
        } else {
             // Optional: Take a fee on failed attempt
             if (feeRecipient != address(0) && address(this).balance >= failedCollapseFee) {
                 (bool success, ) = payable(feeRecipient).call{value: failedCollapseFee}("");
                 if (success) {
                     emit FeeCollected(feeRecipient, failedCollapseFee);
                 }
             }
             // Stay in Entangled or move to FailedMeasurement? Let's move to FailedMeasurement to require reset.
             currentState = LockerState.FailedMeasurement;
             emit StateChanged(currentState);
        }
    }

    // Pseudo-probabilistic "fluctuation" unlock after a long delay
    function attemptFluctuationUnlock() external nonReentrant whenNotStateIs(LockerState.Collapsed) {
        require(entanglementState.paramsAreSet, "QL: Parameters not set");
        require(block.timestamp >= entanglementState.unlockTime + minFluctuationDelay, "QL: Fluctuation period not reached");

        // Use block data for pseudo-randomness
        // Note: blockhash is only available for the last 256 blocks. If called much later,
        // use block.timestamp or other factors for randomness.
        bytes32 blockMix = blockhash(block.number - 1); // Use previous block hash
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            blockMix,
            block.timestamp,
            tx.origin, // Using tx.origin can be risky, consider msg.sender or other entropy
            block.difficulty // Difficulty changes, adding variability
        )));

        uint256 chancePercentage = getFluctuationUnlockChance(randomness); // Get chance based on block data

        // Example: 1% chance (1 in 100)
        bool fluctuationSuccess = (randomness % 10000) < (chancePercentage * 100); // Scale percentage to 10000 base

        emit FluctuationAttempted(msg.sender, fluctuationSuccess);

        if (fluctuationSuccess) {
             // Optional: Take a fee on successful fluctuation unlock
             if (feeRecipient != address(0) && address(this).balance >= fluctuationUnlockFee) {
                 (bool success, ) = payable(feeRecipient).call{value: fluctuationUnlockFee}("");
                 if (success) {
                     emit FeeCollected(feeRecipient, fluctuationUnlockFee);
                 }
             }
            currentState = LockerState.Collapsed;
            emit Collapsed(msg.sender);
            emit StateChanged(currentState);
        } else {
            // No state change on failed fluctuation attempt, stays in its current non-Collapsed state
        }
    }

    // Reset the entanglement state (e.g., after a failed measurement or expired reveal period)
    function resetEntanglementState() external onlyObserverOrOwner whenNotStateIs(LockerState.Idle) whenNotStateIs(LockerState.Collapsed) {
        // Conditions allowing reset: reveal period ended, or current state is FailedMeasurement
        require(
            currentState == LockerState.FailedMeasurement || block.timestamp >= entanglementState.commitmentRevealDeadline,
            "QL: Reset not allowed yet"
        );

        delete entanglementState; // Reset struct to default values
        delete revealedSecretValue;
        delete secretRevealer;
        secretHasBeenRevealed = false;
        delete lastOracleMeasurement;
        oracleMeasurementProvided = false;

        // Clear all existing commitments (optional, might be gas intensive if many)
        // In a real contract, consider managing commitments more carefully if needed across resets.
        // For simplicity here, we'll assume commitments are only relevant for one reveal phase.
        // A more robust solution would iterate through committers or store them differently.
        // As a placeholder, we won't clear the mapping here, but it implies old commitments
        // won't work with a *new* entanglement state.

        currentState = LockerState.Idle;
        emit EntanglementStateReset();
        emit StateChanged(currentState);
    }

    // --- Admin Functions ---

    function setObserver(address _observer) external onlyOwner {
        observer = _observer;
        emit ObserverSet(_observer);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
         require(_feeRecipient != address(0), "QL: Fee recipient cannot be zero address");
         feeRecipient = _feeRecipient;
         emit FeeRecipientSet(feeRecipient);
    }

    function setFailedCollapseFee(uint256 _fee) external onlyOwner {
        failedCollapseFee = _fee;
    }

    function setFluctuationUnlockFee(uint256 _fee) external onlyOwner {
        fluctuationUnlockFee = _fee;
    }

    function setMinFluctuationDelay(uint64 _delay) external onlyOwner {
        minFluctuationDelay = _delay;
    }

    // --- Query Functions ---

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address tokenAddress) public view returns (uint256) {
        require(tokenAddress != address(0), "QL: Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getCurrentState() public view returns (LockerState) {
        return currentState;
    }

    function getEntanglementStateParameters() public view returns (EntanglementState memory) {
        return entanglementState;
    }

    function getCommitmentHash(address committer) public view returns (bytes32) {
        return commitments[committer];
    }

    function getSecretRevealedStatus() public view returns (bool isRevealed, uint256 revealedValue) {
        return (secretHasBeenRevealed, revealedSecretValue);
    }

    function getLastOracleMeasurement() public view returns (int256 value, bool provided) {
         return (lastOracleMeasurement, oracleMeasurementProvided);
    }

    function getFeeRecipient() public view returns (address) {
        return feeRecipient;
    }

    function getCommitmentRevealDeadline() public view returns (uint64) {
        return entanglementState.commitmentRevealDeadline;
    }

     function isCommitmentPeriodOver() public view returns (bool) {
         // Commitment Period is active until reveal period starts or deadline passes
         // This check is relevant when in CommitmentPeriod state
         return block.timestamp >= entanglementState.commitmentRevealDeadline;
     }

      function isRevealPeriodOver() public view returns (bool) {
         // Reveal Period is active until deadline passes
         // This check is relevant when in RevealPeriod state
         return block.timestamp >= entanglementState.commitmentRevealDeadline;
     }


    // --- Condition Checkers (Internal/View) ---

    // Checks all conditions required for collapse
    function checkEntanglementCollapseCondition() public view returns (bool) {
        if (!entanglementState.paramsAreSet) {
            return false; // Parameters must be set
        }
        if (!secretHasBeenRevealed) {
            return false; // Secret must be revealed
        }
        if (!oracleMeasurementProvided && entanglementState.oracleContract != address(0)) {
            return false; // Oracle measurement needed if oracle is set
        }

        bool timeCondition = isTimePastUnlock();
        bool blockHashCondition = isBlockHashMatch();
        bool oracleCondition = isOracleValueInRange();
        bool secretHashCondition = checkSecretHashValidityRule(revealedSecretValue);

        // All conditions must be met simultaneously
        return timeCondition && blockHashCondition && oracleCondition && secretHashCondition;
    }

    function isTimePastUnlock() public view returns (bool) {
        return block.timestamp >= entanglementState.unlockTime;
    }

    // Check if the current block hash matches the target block hash
    // Note: blockhash(block.number) is not available, must use a past block.
    // Only block hashes for the last 256 blocks are available.
    function isBlockHashMatch() public view returns (bool) {
        bytes32 target = entanglementState.targetBlockHash;
        if (target == bytes32(0)) {
            return true; // Condition is trivially met if no target hash is set
        }
        // We need to check if the target hash exists within the last 256 blocks
        // This loop is potentially gas-intensive if the target is far back,
        // but limited to 256 iterations.
        for (uint256 i = 1; i <= 256; i++) {
            if (block.number <= i) break; // Stop if we go past genesis or requested block
            if (blockhash(block.number - i) == target) {
                return true;
            }
        }
        return false; // Target hash not found in the last 256 blocks
    }

    function isOracleValueInRange() public view returns (bool) {
         // If no oracle contract is set, this condition is trivially met.
         if (entanglementState.oracleContract == address(0)) {
             return true;
         }
         // If oracle is set but no measurement provided, condition is not met.
         if (!oracleMeasurementProvided) {
             return false;
         }
        return lastOracleMeasurement >= entanglementState.oracleValueRangeMin &&
               lastOracleMeasurement <= entanglementState.oracleValueRangeMax;
    }

    // Checks if the hash of the revealed secret meets the defined rule
    // The rule is represented by bytes32. E.g., require keccak256(revealedSecret)
    // to start with the bytes in secretHashValidityRule.
    function checkSecretHashValidityRule(uint256 _secret) public pure returns (bool) {
         bytes32 secretHash = keccak256(abi.encodePacked(_secret));
         bytes32 rule = entanglementState.secretHashValidityRule;

         // Example rule: Check if the hash starts with the bytes in the rule
         // Compare the first N bytes, where N is the number of non-zero bytes in the rule prefix.
         // This is a simplified example. More complex rules could be implemented.

         // Determine how many leading bytes of the rule are non-zero
         uint8 rulePrefixLength = 0;
         bytes memory ruleBytes = abi.encodePacked(rule);
         for(uint i = 0; i < 32; i++) {
             if (ruleBytes[i] != 0) {
                 rulePrefixLength = uint8(i + 1);
             }
         }

         if (rulePrefixLength == 0) {
             return true; // Rule is bytes32(0), means no rule applied
         }

         bytes memory secretHashBytes = abi.encodePacked(secretHash);

         // Compare the determined number of leading bytes
         for (uint i = 0; i < rulePrefixLength; i++) {
             if (secretHashBytes[i] != ruleBytes[i]) {
                 return false; // Mismatch found
             }
         }

         return true; // Leading bytes match the rule
     }

    // Calculates a pseudo-random chance percentage based on input randomness
    function getFluctuationUnlockChance(uint256 randomness) public pure returns (uint256 percentage) {
        // This is a placeholder for a more complex function.
        // It should return a small percentage (e.g., 0-5%).
        // Example: Use part of the hash to determine a percentage out of 1000.
        // The output percentage will be between 0 and 100.
        // A simple deterministic mapping from randomness to percentage.
        return (randomness % 501) / 100; // Returns value between 0 and 5 (inclusive)
    }
}
```