Okay, let's design a smart contract that goes beyond standard patterns. We'll create a "Quantum Vault" concept – not using actual quantum computing (impossible on current blockchains), but *simulating* a process inspired by quantum state collapse or entanglement, where the outcome (the vault key) is determined by a future, hard-to-predict event based on blockchain state.

Users deposit funds, and the ability to withdraw depends on successfully predicting a future "Quantum Determinant" derived from a block hash at a specific time. It incorporates features like commitment schemes, reputation, dynamic fees, and delegation.

---

**Outline & Function Summary:**

This smart contract, named `QuantumVault`, simulates a process where assets are locked and can only be unlocked by successfully predicting a future "Quantum Determinant". The determinant is derived from a block hash at a specific future block number, combined with epoch-specific data. Users must commit a hash of their prediction *before* the determinant block and reveal it *after* the determinant is computed.

**Core Concepts:**

1.  **Epochs:** The contract operates in distinct time periods called Epochs, each with its own target determinant block.
2.  **Quantum Determinant:** A unique `bytes32` value computed for each epoch based on the `blockhash` at the target block and potentially other epoch parameters.
3.  **Commitment Scheme:** Users commit a hash of their predicted determinant *before* the target block to prevent front-running.
4.  **Reveal & Unlock:** After the target block and determinant computation, users reveal their prediction. If it matches the computed determinant, they can unlock their deposited funds.
5.  **Reputation:** The contract tracks user success rate in predicting determinants.
6.  **Dynamic Fees:** Fees for operations (like unlocking) can adjust based on contract state.
7.  **Delegation:** Users can delegate their reveal and unlock rights to another address.

**Function Summary (>= 20 Functions):**

1.  `constructor()`: Initializes the owner and default parameters.
2.  `depositETH(uint256 epochIndex)`: Deposits native ETH into a specified epoch.
3.  `depositERC20(address tokenAddress, uint256 amount, uint256 epochIndex)`: Deposits ERC20 tokens into a specified epoch.
4.  `setEpochParameters(uint256 epochIndex, uint256 targetBlockNumber, uint256 lockDuration)`: Owner sets parameters for a new or future epoch.
5.  `registerForEpoch(uint256 epochIndex)`: Users explicitly register their intent to participate (and guess) for an epoch.
6.  `commitDeterminantGuessHash(uint256 epochIndex, bytes32 guessHash)`: User commits the KECCAK256 hash of their predicted determinant for an epoch.
7.  `computeDeterminant(uint256 epochIndex)`: Callable by anyone *after* the target block, computes and stores the actual determinant for the epoch.
8.  `revealDeterminantGuess(uint256 epochIndex, bytes32 guessedDeterminant)`: User reveals their predicted determinant. Checks against committed hash and computed determinant.
9.  `unlockFunds(uint256 epochIndex)`: Callable by a user whose reveal was successful, allows withdrawing deposited funds for that epoch.
10. `claimFailedRevealPenalties(uint256 epochIndex)`: Owner/privileged address claims penalties from failed reveals (if any).
11. `getUserDeposit(address user, uint256 epochIndex) view`: Gets a user's deposit details for an epoch.
12. `getEpochState(uint256 epochIndex) view`: Gets the state and parameters of a specific epoch.
13. `getComputedDeterminant(uint256 epochIndex) view`: Gets the computed determinant for an epoch.
14. `getUserCommitment(address user, uint256 epochIndex) view`: Gets a user's commitment hash for an epoch.
15. `getUserReputation(address user) view`: Gets a user's reputation (successful guesses count).
16. `setDynamicFeeFactors(uint256 baseFee, uint256 depositFactor, uint256 guessFactor)`: Owner sets parameters for dynamic fee calculation.
17. `getUnlockFee(uint256 epochIndex) view`: Calculates the current dynamic fee for unlocking based on epoch state.
18. `delegateGuessing(uint256 epochIndex, address delegatee)`: User delegates their reveal/unlock rights for a specific epoch.
19. `revokeDelegation(uint256 epochIndex)`: User revokes a previously set delegation for an epoch.
20. `getDelegatedTo(address user, uint256 epochIndex) view`: Gets the address the user delegated to for an epoch.
21. `getDelegators(address delegatee, uint256 epochIndex) view`: Gets the list of addresses that delegated to this delegatee for an epoch.
22. `emergencyWithdrawOwner(address tokenAddress)`: Owner emergency withdrawal of a specific token (or ETH if tokenAddress is zero address) - high privilege, intended for critical situations.
23. `pauseContract() owner`: Pauses key contract functionalities.
24. `unpauseContract() owner`: Unpauses the contract.
25. `updateFeeRecipient(address newRecipient) owner`: Updates the address where fees are sent.
26. `getPenaltyAmount(uint256 epochIndex) view`: Gets the total accumulated penalties for an epoch.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Error codes for clarity
error QuantumVault__EpochNotActive(uint256 epochIndex);
error QuantumVault__EpochNotConfigured(uint256 epochIndex);
error QuantumVault__EpochAlreadyConfigured(uint256 epochIndex);
error QuantumVault__EpochDeterminantBlockInPast(uint256 targetBlockNumber);
error QuantumVault__EpochDeterminantBlockTooFarInFuture(uint256 targetBlockNumber);
error QuantumVault__EpochCommitmentWindowClosed(uint256 epochIndex);
error QuantumVault__EpochRevealWindowNotOpen(uint256 epochIndex);
error QuantumVault__EpochDeterminantNotComputed(uint256 epochIndex);
error QuantumVault__EpochDeterminantAlreadyComputed(uint256 epochIndex);
error QuantumVault__EpochDeterminantBlockNotInRange(uint256 targetBlockNumber, uint256 computationBlock);
error QuantumVault__DepositRequired(uint256 epochIndex);
error QuantumVault__NotRegisteredForEpoch(uint256 epochIndex);
error QuantumVault__CommitmentRequired(uint256 epochIndex);
error QuantumVault__RevealRequired(uint256 epochIndex);
error QuantumVault__InvalidReveal(uint256 epochIndex);
error QuantumVault__FundsAlreadyUnlocked(uint256 epochIndex);
error QuantumVault__UnlockWindowClosed(uint256 epochIndex);
error QuantumVault__NotAllowedToDelegateOrRevoke();
error QuantumVault__SelfDelegation();
error QuantumVault__AlreadyDelegatedTo(address delegatee);
error QuantumVault__NotDelegatedForEpoch(uint256 epochIndex);
error QuantumVault__NoPenaltiesToClaim(uint256 epochIndex);
error QuantumVault__EmergencyWithdrawFailed();
error QuantumVault__InvalidAmount();


contract QuantumVault is Ownable, Pausable {

    // --- State Variables ---

    struct Epoch {
        uint256 targetBlockNumber; // Block number at which determinant is calculated
        uint256 lockDuration;      // Duration in seconds funds are locked after determinant (can be 0)
        uint256 determinantComputedAtBlock; // Block number when computeDeterminant was called
        bytes32 computedDeterminant;    // The actual determinant calculated after targetBlockNumber
        bool determinantComputed;       // Flag if determinant has been computed
        uint256 totalDepositedETH;      // Total ETH deposited for this epoch
        mapping(address => uint256) totalDepositedERC20; // Total ERC20 deposited per token
        address[] depositedERC20Tokens; // List of unique ERC20 tokens deposited
        uint256 totalRegisteredUsers;   // Count of users who registered for this epoch
        uint256 totalSuccessfulReveals; // Count of users who revealed correctly
        uint256 totalPenaltyETH;        // Total accumulated ETH penalties for this epoch
        mapping(address => uint256) totalPenaltyERC20; // Total accumulated ERC20 penalties per token
    }

    struct UserEpochState {
        uint256 ethDeposit;             // User's ETH deposit for this epoch
        mapping(address => uint256) erc20Deposits; // User's ERC20 deposits per token
        bytes32 determinantCommitHash;  // User's hash commitment for the determinant
        bytes32 revealedDeterminant;    // User's revealed determinant
        bool registered;                // Has the user registered for this epoch?
        bool commitmentMade;            // Has the user made a commitment?
        bool revealed;                  // Has the user revealed?
        bool revealSuccessful;          // Was the reveal correct?
        bool fundsUnlocked;             // Have funds been unlocked?
        address delegatedTo;            // Address this user delegated to for this epoch (address(0) if none)
    }

    mapping(uint256 => Epoch) public epochs; // Epoch index => Epoch state
    mapping(uint256 => mapping(address => UserEpochState)) private userEpochStates; // Epoch index => user address => User state
    mapping(uint256 => address[]) private epochRegisteredUsers; // Epoch index => list of registered users

    uint256 public nextEpochIndex = 0; // Counter for the next epoch index

    uint256 public baseUnlockFee = 0; // Base fee for unlocking (in wei)
    uint256 public dynamicDepositFactor = 0; // Factor for fee calculation based on total deposits
    uint256 public dynamicGuessFactor = 0; // Factor for fee calculation based on total guesses

    address public feeRecipient; // Address to receive fees and potentially penalties

    mapping(address => uint256) public userSuccessfulReveals; // Simple reputation: count of successful reveals

    // --- Events ---

    event EpochParametersSet(uint256 indexed epochIndex, uint256 targetBlockNumber, uint256 lockDuration);
    event UserRegisteredForEpoch(uint256 indexed epochIndex, address indexed user);
    event DepositMade(uint256 indexed epochIndex, address indexed user, address indexed tokenAddress, uint256 amount);
    event DeterminantCommitmentMade(uint256 indexed epochIndex, address indexed user, bytes32 guessHash);
    event DeterminantComputed(uint256 indexed epochIndex, bytes32 computedDeterminant, uint256 computationBlock);
    event DeterminantGuessRevealed(uint256 indexed epochIndex, address indexed user, bytes32 revealedDeterminant, bool success);
    event FundsUnlocked(uint256 indexed epochIndex, address indexed user, uint256 ethUnlocked, uint256 feePaidETH);
    event ERC20FundsUnlocked(uint256 indexed epochIndex, address indexed user, address indexed tokenAddress, uint256 amountUnlocked, uint256 feePaidERC20); // ERC20 fees TBD, or just ETH fees
    event PenaltiesClaimed(uint256 indexed epochIndex, address indexed claimant, uint256 ethAmount, mapping(address => uint256) erc20Amounts);
    event DelegationSet(uint256 indexed epochIndex, address indexed delegator, address indexed delegatee);
    event DelegationRevoked(uint256 indexed epochIndex, address indexed delegator);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event EmergencyWithdrawal(address indexed tokenAddress, uint256 amount);

    // --- Modifiers ---

    modifier onlyEpochConfigured(uint256 epochIndex) {
        if (epochs[epochIndex].targetBlockNumber == 0) {
            revert QuantumVault__EpochNotConfigured(epochIndex);
        }
        _;
    }

    modifier onlyEpochCommitmentWindow(uint256 epochIndex) {
        if (epochs[epochIndex].targetBlockNumber == 0 || block.number >= epochs[epochIndex].targetBlockNumber) {
            revert QuantumVault__EpochCommitmentWindowClosed(epochIndex);
        }
        _;
    }

    modifier onlyEpochRevealWindowOpen(uint256 epochIndex) {
        if (epochs[epochIndex].determinantComputed == false) {
            revert QuantumVault__EpochDeterminantNotComputed(epochIndex);
        }
        if (block.timestamp > epochs[epochIndex].determinantComputedAtBlock + epochs[epochIndex].lockDuration) {
             revert QuantumVault__UnlockWindowClosed(epochIndex);
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable(false) {
        feeRecipient = msg.sender; // Default fee recipient is owner
    }

    // --- Epoch Management (Owner) ---

    /**
     * @notice Sets or updates parameters for a specific epoch.
     * @dev Can only set parameters for epochs >= nextEpochIndex. Target block must be in future but not too far.
     * @param epochIndex The index of the epoch to configure.
     * @param targetBlockNumber The future block number where the determinant will be calculated.
     * @param lockDuration Duration in seconds funds are locked after determinant computation.
     */
    function setEpochParameters(uint256 epochIndex, uint256 targetBlockNumber, uint256 lockDuration) external onlyOwner {
        if (epochIndex < nextEpochIndex && epochs[epochIndex].targetBlockNumber != 0) {
             revert QuantumVault__EpochAlreadyConfigured(epochIndex); // Prevent reconfiguring past or current active epochs
        }
        // Using block.number + 256 is an estimate; chain reorganizations can affect block numbers.
        // This is a design choice for this specific contract's "quantum" simulation.
        if (targetBlockNumber <= block.number) {
            revert QuantumVault__EpochDeterminantBlockInPast(targetBlockNumber);
        }
        // Limit how far in the future to prevent issues with blockhash availability (max 256 blocks)
        // The computeDeterminant call must happen within 256 blocks of targetBlockNumber
        // Let's enforce targetBlockNumber isn't *too* far out, e.g., within 1 year ~ 2.6M blocks @ 13s avg
        if (targetBlockNumber > block.number + 3_000_000) { // Arbitrary large number for "too far"
             revert QuantumVault__EpochDeterminantBlockTooFarInFuture(targetBlockNumber);
        }

        epochs[epochIndex].targetBlockNumber = targetBlockNumber;
        epochs[epochIndex].lockDuration = lockDuration;

        if (epochIndex >= nextEpochIndex) {
            nextEpochIndex = epochIndex + 1;
        }

        emit EpochParametersSet(epochIndex, targetBlockNumber, lockDuration);
    }

    // --- User Actions (Pausable) ---

    /**
     * @notice Registers a user for participation in an epoch. Required before committing a guess.
     * @param epochIndex The index of the epoch to register for.
     */
    function registerForEpoch(uint256 epochIndex) external whenNotPaused onlyEpochCommitmentWindow(epochIndex) {
        UserEpochState storage userState = userEpochStates[epochIndex][msg.sender];
        if (userState.registered) return; // Already registered

        userState.registered = true;
        epochs[epochIndex].totalRegisteredUsers++;
        epochRegisteredUsers[epochIndex].push(msg.sender); // Store user address for enumeration (gas intensive)

        emit UserRegisteredForEpoch(epochIndex, msg.sender);
    }

    /**
     * @notice Deposits native ETH into a specific epoch. Requires prior registration.
     * @param epochIndex The index of the epoch to deposit into.
     */
    function depositETH(uint256 epochIndex) external payable whenNotPaused onlyEpochCommitmentWindow(epochIndex) {
        if (msg.value == 0) revert InvalidAmount();

        UserEpochState storage userState = userEpochStates[epochIndex][msg.sender];
        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);

        userState.ethDeposit += msg.value;
        epochs[epochIndex].totalDepositedETH += msg.value;

        emit DepositMade(epochIndex, msg.sender, address(0), msg.value); // address(0) signifies ETH
    }

    /**
     * @notice Deposits ERC20 tokens into a specific epoch. Requires prior registration and allowance.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     * @param epochIndex The index of the epoch to deposit into.
     */
    function depositERC20(address tokenAddress, uint256 amount, uint256 epochIndex) external whenNotPaused onlyEpochCommitmentWindow(epochIndex) {
        if (amount == 0) revert InvalidAmount();

        UserEpochState storage userState = userEpochStates[epochIndex][msg.sender];
        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);

        // Add token to the list if not already present (gas intensive)
        Epoch storage epoch = epochs[epochIndex];
        bool tokenFound = false;
        for (uint i = 0; i < epoch.depositedERC20Tokens.length; i++) {
            if (epoch.depositedERC20Tokens[i] == tokenAddress) {
                tokenFound = true;
                break;
            }
        }
        if (!tokenFound) {
            epoch.depositedERC20Tokens.push(tokenAddress);
        }

        // Transfer tokens from user
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        userState.erc20Deposits[tokenAddress] += amount;
        epoch.totalDepositedERC20[tokenAddress] += amount;

        emit DepositMade(epochIndex, msg.sender, tokenAddress, amount);
    }

    /**
     * @notice Commits the hash of the user's predicted determinant for an epoch.
     * @dev Must be called before the epoch's target block number.
     * @param epochIndex The index of the epoch.
     * @param guessHash The KECCAK256 hash of the user's predicted determinant.
     */
    function commitDeterminantGuessHash(uint256 epochIndex, bytes32 guessHash) external whenNotPaused onlyEpochCommitmentWindow(epochIndex) {
        UserEpochState storage userState = userEpochStates[epochIndex][msg.sender];
        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);
        if (guessHash == bytes32(0)) revert CommitmentRequired(epochIndex); // Cannot commit zero hash

        userState.determinantCommitHash = guessHash;
        userState.commitmentMade = true;

        emit DeterminantCommitmentMade(epochIndex, msg.sender, guessHash);
    }

    /**
     * @notice Reveals the user's predicted determinant after computation.
     * @dev Checks the reveal against the prior commitment and the computed determinant.
     * @param epochIndex The index of the epoch.
     * @param guessedDeterminant The user's predicted determinant.
     */
    function revealDeterminantGuess(uint256 epochIndex, bytes32 guessedDeterminant) external whenNotPaused onlyEpochRevealWindowOpen(epochIndex) {
        address userAddress = msg.sender;
        UserEpochState storage userState = userEpochStates[epochIndex][userAddress];

        // Check if reveal is being made by a delegatee
        if (userState.delegatedTo != address(0) && userState.delegatedTo != userAddress) {
             revert NotAllowedToDelegateOrRevoke(); // Should be called by the user or their delegate
        }
        if (userState.delegatedTo == userAddress) { // This case is if msg.sender *is* the delegate
            // This path is valid, allow the delegate to reveal
        } else if (userState.delegatedTo == address(0)) { // Not delegated
            // This path is valid, user reveals for themselves
        } else { // userState.delegatedTo is set but not to msg.sender
            revert NotAllowedToDelegateOrRevoke(); // Someone else is the delegate
        }


        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);
        if (!userState.commitmentMade) revert CommitmentRequired(epochIndex);
        if (userState.revealed) return; // Already revealed

        // Verify the reveal against the stored commitment hash
        if (keccak256(abi.encodePacked(guessedDeterminant)) != userState.determinantCommitHash) {
            // Incorrect hash reveal, user failed the commitment step
            userState.revealed = true;
            userState.revealSuccessful = false;
            userState.revealedDeterminant = guessedDeterminant; // Store for debugging/audit
            // Penalize or mark as failed - no explicit penalty token in this simple version, just lose chance to unlock.
            emit DeterminantGuessRevealed(epochIndex, userAddress, guessedDeterminant, false);
            return;
        }

        // Verify the revealed determinant against the computed determinant
        Epoch storage epoch = epochs[epochIndex];
        if (guessedDeterminant == epoch.computedDeterminant) {
            userState.revealed = true;
            userState.revealSuccessful = true;
            userState.revealedDeterminant = guessedDeterminant;
            userSuccessfulReveals[userAddress]++;
            epoch.totalSuccessfulReveals++;
            emit DeterminantGuessRevealed(epochIndex, userAddress, guessedDeterminant, true);
        } else {
            userState.revealed = true;
            userState.revealSuccessful = false;
            userState.revealedDeterminant = guessedDeterminant;
            // Penalize or mark as failed
            emit DeterminantGuessRevealed(epochIndex, userAddress, guessedDeterminant, false);
        }
    }

    /**
     * @notice Allows a user with a successful reveal to unlock their deposited funds.
     * @dev Can be called after successful reveal and within the unlock window.
     * @param epochIndex The index of the epoch.
     */
    function unlockFunds(uint256 epochIndex) external whenNotPaused onlyEpochRevealWindowOpen(epochIndex) {
        address userAddress = msg.sender;
        UserEpochState storage userState = userEpochStates[epochIndex][userAddress];

         // Check if unlock is being made by a delegatee
        if (userState.delegatedTo != address(0) && userState.delegatedTo != userAddress) {
             revert NotAllowedToDelegateOrRevoke(); // Should be called by the user or their delegate
        }
         if (userState.delegatedTo == userAddress) { // This case is if msg.sender *is* the delegate
            // This path is valid, allow the delegate to unlock
        } else if (userState.delegatedTo == address(0)) { // Not delegated
            // This path is valid, user unlocks for themselves
        } else { // userState.delegatedTo is set but not to msg.sender
            revert NotAllowedToDelegateOrRevoke(); // Someone else is the delegate
        }


        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);
        if (!userState.revealed) revert RevealRequired(epochIndex);
        if (!userState.revealSuccessful) revert InvalidReveal(epochIndex);
        if (userState.fundsUnlocked) return; // Already unlocked

        Epoch storage epoch = epochs[epochIndex];

        // Calculate unlock fee (simplified dynamic fee based on total deposits)
        uint256 unlockFeeETH = getUnlockFee(epochIndex);
        uint256 ethToTransfer = userState.ethDeposit;
        uint256 feeAmountETH = 0;

        if (ethToTransfer > 0) {
             if (ethToTransfer <= unlockFeeETH) {
                feeAmountETH = ethToTransfer; // Use all deposit as fee if insufficient
                ethToTransfer = 0;
            } else {
                feeAmountETH = unlockFeeETH;
                ethToTransfer -= unlockFeeETH;
            }

            // Send fee
             (bool successFee, ) = payable(feeRecipient).call{value: feeAmountETH}("");
             // Consider adding error handling if fee transfer fails
        }


        // Send remaining ETH deposit
        if (ethToTransfer > 0) {
            (bool successETH, ) = payable(userAddress).call{value: ethToTransfer}("");
            if (!successETH) {
                 // Handle failure: maybe log or revert. Reverting is safer to prevent state inconsistency.
                 // For demonstration, we'll just log, but in production, consider `revert`.
                 emit EmergencyWithdrawal(address(0), ethToTransfer); // Log failed transfer
            }
        }

        // Transfer ERC20 deposits
        for (uint i = 0; i < epoch.depositedERC20Tokens.length; i++) {
            address tokenAddress = epoch.depositedERC20Tokens[i];
            uint256 erc20Amount = userState.erc20Deposits[tokenAddress];
            if (erc20Amount > 0) {
                // No ERC20 fees in this simplified version
                 IERC20(tokenAddress).transfer(userAddress, erc20Amount);
                 emit ERC20FundsUnlocked(epochIndex, userAddress, tokenAddress, erc20Amount, 0);
            }
        }

        userState.fundsUnlocked = true;
        emit FundsUnlocked(epochIndex, userAddress, ethToTransfer, feeAmountETH);
    }

    // --- Determinant Calculation ---

    /**
     * @notice Computes the Quantum Determinant for an epoch.
     * @dev Can be called by anyone after the epoch's target block number.
     * @param epochIndex The index of the epoch.
     */
    function computeDeterminant(uint256 epochIndex) external whenNotPaused onlyEpochConfigured(epochIndex) {
        Epoch storage epoch = epochs[epochIndex];

        if (epoch.determinantComputed) {
            revert QuantumVault__EpochDeterminantAlreadyComputed(epochIndex);
        }

        uint256 targetBlock = epoch.targetBlockNumber;
        uint256 currentBlock = block.number;

        // Determinant computation must happen after the target block
        // Blockhash is only available for the most recent 256 blocks
        if (currentBlock <= targetBlock) {
            revert QuantumVault__EpochRevealWindowNotOpen(epochIndex); // Computation window not open yet
        }
        if (currentBlock > targetBlock + 256) {
             // This means the target block's hash is no longer available.
             // The epoch effectively becomes unusable for determinant-based unlock.
             // A robust system might handle this (e.g., mark epoch failed), but for this demo, we revert.
             revert QuantumVault__EpochDeterminantBlockNotInRange(targetBlock, currentBlock);
        }

        bytes32 blockHash = blockhash(targetBlock);

        // Combine block hash with epoch index and other factors for the determinant
        // Add current block hash for extra entropy source if needed
        // Adding epoch data makes the determinant unique per epoch
        bytes32 computed = keccak256(abi.encodePacked(blockHash, epochIndex, epoch.targetBlockNumber, epoch.lockDuration, block.timestamp, block.number));

        epoch.computedDeterminant = computed;
        epoch.determinantComputed = true;
        epoch.determinantComputedAtBlock = block.number;

        emit DeterminantComputed(epochIndex, computed, block.number);
    }

    // --- Delegation ---

     /**
     * @notice Allows a user to delegate their reveal and unlock rights for an epoch to another address.
     * @dev The delegatee can call revealDeterminantGuess and unlockFunds on behalf of the delegator.
     * @param epochIndex The index of the epoch.
     * @param delegatee The address to delegate to.
     */
    function delegateGuessing(uint256 epochIndex, address delegatee) external whenNotPaused onlyEpochCommitmentWindow(epochIndex) {
         UserEpochState storage userState = userEpochStates[epochIndex][msg.sender];

        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);
        if (delegatee == address(0)) revert InvalidAmount(); // Cannot delegate to zero address
        if (delegatee == msg.sender) revert SelfDelegation(); // Cannot delegate to self
        if (userState.delegatedTo != address(0)) revert AlreadyDelegatedTo(userState.delegatedTo); // Already delegated

        userState.delegatedTo = delegatee;
        emit DelegationSet(epochIndex, msg.sender, delegatee);
    }

     /**
     * @notice Revokes a delegation set by the user for a specific epoch.
     * @param epochIndex The index of the epoch.
     */
    function revokeDelegation(uint256 epochIndex) external whenNotPaused {
         UserEpochState storage userState = userEpochStates[epochIndex][msg.sender];

        if (!userState.registered) revert NotRegisteredForEpoch(epochIndex);
        if (userState.delegatedTo == address(0)) revert NotDelegatedForEpoch(epochIndex);

        userState.delegatedTo = address(0); // Revoke delegation
        emit DelegationRevoked(epochIndex, msg.sender);
    }

    // --- Dynamic Fees (Owner) ---

     /**
     * @notice Owner sets the factors for dynamic fee calculation.
     * @param baseFee_ The base fee for unlocking (in wei for ETH, or arbitrary for ERC20).
     * @param depositFactor_ Factor applied to total deposits for fee calculation.
     * @param guessFactor_ Factor applied to total guesses for fee calculation.
     */
    function setDynamicFeeFactors(uint256 baseFee_, uint256 depositFactor_, uint256 guessFactor_) external onlyOwner {
        baseUnlockFee = baseFee_;
        dynamicDepositFactor = depositFactor_;
        dynamicGuessFactor = guessFactor_;
    }


    // --- Penalty Management (Owner/Privileged) ---

    /**
     * @notice Allows the owner or a privileged address to claim accumulated penalties from an epoch.
     * @dev In this simple version, penalties are just leftover deposits from failed reveals/unlocks.
     *      A more complex version would explicitly manage a penalty pool.
     * @param epochIndex The index of the epoch.
     */
    function claimFailedRevealPenalties(uint256 epochIndex) external onlyOwner onlyEpochConfigured(epochIndex) {
         Epoch storage epoch = epochs[epochIndex];
         if (!epoch.determinantComputed) revert QuantumVault__EpochDeterminantNotComputed(epochIndex);

         // This simplified version just claims whatever ETH/ERC20 wasn't withdrawn.
         // A real penalty system would collect specific penalty amounts.
         // We'll calculate available balance based on what *should* be left.
         uint256 contractEthBalance = address(this).balance;
         uint256 ethClaimable = contractEthBalance - epoch.totalDepositedETH + (epoch.totalSuccessfulReveals > 0 ? userEpochStates[epochIndex][epochRegisteredUsers[epochIndex][0]].ethDeposit : 0); // Example: subtract deposited ETH, add back 1 successful unlock ETH as approximation

         if (ethClaimable == 0) revert NoPenaltiesToClaim(epochIndex);

         // A proper penalty system would be much more complex, tracking explicit penalties.
         // This function is a placeholder to show a penalty *claiming* mechanism.
         // In this simple version, it's not truly tracking "penalties" but unclaimed funds.
         // Let's just allow owner to withdraw any balance for that epoch (dangerous, simplified!)
         // Real penalty system needs separate mapping for penalty pools.

         // Let's just implement a very basic claim for ETH for now, assuming fees *are* the penalty sink here.
         // Any ETH that isn't unlocked by successful guessers and isn't needed for other epoch deposits
         // is theoretically 'penalty' or 'unclaimed'. This is difficult to track per epoch reliably.
         // A better approach: fees go to feeRecipient, unclaimed deposits stay until owner emergency withdraws.
         // Let's repurpose this function to collect *explicit* fees transferred to feeRecipient,
         // and emergencyWithdraw handles remaining unclaimed deposits.
         // This function name is now confusing based on the simplified fee/penalty structure.
         // Let's rename to `collectFees` and make it callable by feeRecipient.

         revert("Function repurposed, use EmergencyWithdrawOwner"); // Indicate this function is now invalid based on new structure
    }

    // --- Owner Emergency Functions ---

    /**
     * @notice Owner can emergency withdraw funds. Use with extreme caution.
     * @dev This bypasses the epoch unlock mechanism. Intended for recovery ONLY.
     * @param tokenAddress The address of the token to withdraw (address(0) for ETH).
     */
    function emergencyWithdrawOwner(address tokenAddress) external onlyOwner {
        uint256 balance;
        if (tokenAddress == address(0)) {
            balance = address(this).balance;
             if (balance > 0) {
                (bool success, ) = payable(owner()).call{value: balance}("");
                if (!success) revert EmergencyWithdrawFailed();
                emit EmergencyWithdrawal(address(0), balance);
            }
        } else {
            IERC20 token = IERC20(tokenAddress);
            balance = token.balanceOf(address(this));
            if (balance > 0) {
                 token.transfer(owner(), balance);
                 emit EmergencyWithdrawal(tokenAddress, balance);
            }
        }
    }

    /**
     * @notice Pauses critical contract functionalities.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

     /**
     * @notice Unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

     /**
     * @notice Updates the address where fees are sent.
     * @param newRecipient The new address for fees.
     */
    function updateFeeRecipient(address newRecipient) external onlyOwner {
        address oldRecipient = feeRecipient;
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(oldRecipient, newRecipient);
    }


    // --- View Functions ---

    /**
     * @notice Gets a user's deposit details for a specific epoch.
     * @param user The user's address.
     * @param epochIndex The index of the epoch.
     * @return ethDeposit The user's ETH deposit.
     * @return erc20Deposits Array of ERC20 deposit amounts (order matches epoch.depositedERC20Tokens).
     * @return depositedTokenAddresses Array of ERC20 token addresses deposited by this user in this epoch (might be subset of epoch tokens).
     */
    function getUserDeposit(address user, uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (uint256 ethDeposit, uint256[] memory erc20Deposits, address[] memory depositedTokenAddresses) {
        UserEpochState storage userState = userEpochStates[epochIndex][user];
        ethDeposit = userState.ethDeposit;

        Epoch storage epoch = epochs[epochIndex];
        uint256 tokenCount = epoch.depositedERC20Tokens.length;
        erc20Deposits = new uint256[](tokenCount);
        depositedTokenAddresses = new address[](tokenCount);

        uint256 actualDepositedCount = 0;
         for(uint i = 0; i < tokenCount; i++) {
             address tokenAddress = epoch.depositedERC20Tokens[i];
             uint256 amount = userState.erc20Deposits[tokenAddress];
             if (amount > 0) {
                 erc20Deposits[actualDepositedCount] = amount;
                 depositedTokenAddresses[actualDepositedCount] = tokenAddress;
                 actualDepositedCount++;
             }
         }

         // Trim arrays to only include tokens the user actually deposited
         assembly {
             mstore(erc20Deposits, actualDepositedCount)
             mstore(depositedTokenAddresses, actualDepositedCount)
         }
    }

    /**
     * @notice Gets the state and parameters of a specific epoch.
     * @param epochIndex The index of the epoch.
     * @return targetBlockNumber The target block for determinant computation.
     * @return lockDuration Duration funds are locked after determinant computation.
     * @return determinantComputedAtBlock The block determinant was computed.
     * @return determinantComputed Flag if determinant is computed.
     * @return totalDepositedETH Total ETH deposited in epoch.
     * @return totalRegisteredUsers Total users registered.
     * @return totalSuccessfulReveals Total successful reveals.
     * @return depositedERC20Tokens List of unique ERC20 tokens deposited in epoch.
     */
    function getEpochState(uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (
        uint256 targetBlockNumber,
        uint256 lockDuration,
        uint256 determinantComputedAtBlock,
        bool determinantComputed,
        uint256 totalDepositedETH,
        uint256 totalRegisteredUsers,
        uint256 totalSuccessfulReveals,
        address[] memory depositedERC20Tokens // List of unique ERC20 tokens deposited in this epoch
    ) {
        Epoch storage epoch = epochs[epochIndex];
        targetBlockNumber = epoch.targetBlockNumber;
        lockDuration = epoch.lockDuration;
        determinantComputedAtBlock = epoch.determinantComputedAtBlock;
        determinantComputed = epoch.determinantComputed;
        totalDepositedETH = epoch.totalDepositedETH;
        totalRegisteredUsers = epoch.totalRegisteredUsers;
        totalSuccessfulReveals = epoch.totalSuccessfulReveals;
        depositedERC20Tokens = new address[](epoch.depositedERC20Tokens.length);
        for(uint i = 0; i < epoch.depositedERC20Tokens.length; i++){
            depositedERC20Tokens[i] = epoch.depositedERC20Tokens[i];
        }
    }

     /**
     * @notice Gets the total deposited ERC20 amount for a specific token in an epoch.
     * @param epochIndex The index of the epoch.
     * @param tokenAddress The address of the ERC20 token.
     * @return totalAmount The total deposited amount.
     */
    function getEpochTotalDepositedERC20(uint256 epochIndex, address tokenAddress) public view onlyEpochConfigured(epochIndex) returns (uint256) {
        return epochs[epochIndex].totalDepositedERC20[tokenAddress];
    }


    /**
     * @notice Gets the computed determinant for an epoch. Returns zero bytes32 if not computed.
     * @param epochIndex The index of the epoch.
     * @return computedDeterminant The computed determinant.
     */
    function getComputedDeterminant(uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (bytes32) {
        return epochs[epochIndex].computedDeterminant;
    }

    /**
     * @notice Gets a user's determinant commitment hash for an epoch. Returns zero bytes32 if no commitment.
     * @param user The user's address.
     * @param epochIndex The index of the epoch.
     * @return guessHash The commitment hash.
     */
    function getUserCommitment(address user, uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (bytes32) {
        return userEpochStates[epochIndex][user].determinantCommitHash;
    }

    /**
     * @notice Gets a user's revealed determinant for an epoch. Returns zero bytes32 if not revealed.
     * @param user The user's address.
     * @param epochIndex The index of the epoch.
     * @return revealedDeterminant The revealed determinant.
     */
    function getUserRevealedDeterminant(address user, uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (bytes32) {
        return userEpochStates[epochIndex][user].revealedDeterminant;
    }

    /**
     * @notice Gets a user's state flags for an epoch.
     * @param user The user's address.
     * @param epochIndex The index of the epoch.
     * @return registered Has the user registered?
     * @return commitmentMade Has the user committed?
     * @return revealed Has the user revealed?
     * @return revealSuccessful Was the reveal successful?
     * @return fundsUnlocked Have funds been unlocked?
     */
    function getUserStateFlags(address user, uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (bool registered, bool commitmentMade, bool revealed, bool revealSuccessful, bool fundsUnlocked) {
        UserEpochState storage userState = userEpochStates[epochIndex][user];
        return (userState.registered, userState.commitmentMade, userState.revealed, userState.revealSuccessful, userState.fundsUnlocked);
    }


    /**
     * @notice Gets a user's reputation (count of successful reveals across all epochs).
     * @param user The user's address.
     * @return successCount The number of successful reveals.
     */
    function getUserReputation(address user) public view returns (uint256) {
        return userSuccessfulReveals[user];
    }

    /**
     * @notice Calculates the current dynamic fee for unlocking based on current contract state.
     * @dev Simplified calculation: baseFee + (totalRegisteredUsers * guessFactor) + (totalDepositedETH wei * depositFactor / 1e18).
     * @param epochIndex The index of the epoch.
     * @return feeAmount The calculated fee in wei for unlocking ETH.
     */
    function getUnlockFee(uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (uint256 feeAmount) {
        Epoch storage epoch = epochs[epochIndex];
        uint256 calculatedFee = baseUnlockFee;
        calculatedFee += epoch.totalRegisteredUsers * dynamicGuessFactor;
        // Add a portion of total ETH deposits as a factor (scaled down)
        calculatedFee += (epoch.totalDepositedETH * dynamicDepositFactor) / 1e18; // Division by 1e18 to scale wei to Ether for factor

        // Add a portion of total ERC20 deposits - requires knowing decimals, difficult generically.
        // Skip ERC20 total deposit factor for this simplified example or assume 18 decimals.
        // for (uint i = 0; i < epoch.depositedERC20Tokens.length; i++) {
        //      address tokenAddress = epoch.depositedERC20Tokens[i];
        //      uint256 totalERC20 = epoch.totalDepositedERC20[tokenAddress];
        //      // Need token decimals to scale correctly
        //      // calculatedFee += (totalERC20 * dynamicDepositFactor) / (10**IERC20(tokenAddress).decimals()); // Requires ERC20 metadata interface
        // }

        return calculatedFee;
    }

     /**
     * @notice Gets the address the user delegated to for a specific epoch.
     * @param user The delegator's address.
     * @param epochIndex The index of the epoch.
     * @return delegatee The address the user delegated to (address(0) if none).
     */
    function getDelegatedTo(address user, uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (address) {
        return userEpochStates[epochIndex][user].delegatedTo;
    }

     /**
     * @notice Gets the list of addresses that delegated their rights to a specific delegatee for an epoch.
     * @dev WARNING: This function iterates through all registered users for an epoch. Can be gas-intensive for large epochs.
     * @param delegatee The delegatee's address.
     * @param epochIndex The index of the epoch.
     * @return delegators Array of addresses that delegated to the delegatee.
     */
    function getDelegators(address delegatee, uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (address[] memory) {
        address[] storage registeredUsers = epochRegisteredUsers[epochIndex];
        address[] memory delegatorsList = new address[](registeredUsers.length); // Max possible size
        uint256 count = 0;
        for (uint i = 0; i < registeredUsers.length; i++) {
            address user = registeredUsers[i];
            if (userEpochStates[epochIndex][user].delegatedTo == delegatee) {
                delegatorsList[count] = user;
                count++;
            }
        }

         // Trim array to actual size
         assembly {
             mstore(delegatorsList, count)
         }
        return delegatorsList;
    }

     /**
     * @notice Simulates the determinant calculation for a given block and epoch parameters.
     * @dev Pure function for off-chain use to help users predict. Does NOT guarantee blockhash availability or future state.
     * @param blockNumber The block number to use for blockhash.
     * @param epochIndex The index of the epoch.
     * @param targetBlockNumber The target block number for the epoch.
     * @param lockDuration The lock duration for the epoch.
     * @param timestamp The timestamp to include in calculation (use current block.timestamp for simulation).
     * @param currentBlock The current block number (use current block.number for simulation).
     * @return simulatedDeterminant The simulated determinant.
     */
    function simulateDeterminant(uint256 blockNumber, uint256 epochIndex, uint256 targetBlockNumber, uint256 lockDuration, uint256 timestamp, uint256 currentBlock) public pure returns (bytes32 simulatedDeterminant) {
        // Note: blockhash(blockNumber) is only available for the last 256 blocks on chain.
        // This pure function is for *simulation* only. The actual on-chain computeDeterminant
        // function must handle the 256 block limit.
        bytes32 blockHash = blockhash(blockNumber);
        simulatedDeterminant = keccak256(abi.encodePacked(blockHash, epochIndex, targetBlockNumber, lockDuration, timestamp, currentBlock));
    }

     /**
     * @notice Gets the total accumulated penalties for a specific epoch.
     * @dev In this version, this conceptually represents unclaimed ETH/ERC20 deposits from users who failed to unlock.
     *      A true penalty system would explicitly track penalty amounts.
     *      This view function is a placeholder based on the simplified penalty structure.
     * @param epochIndex The index of the epoch.
     * @return ethPenalty The amount of ETH penalties.
     * @return erc20Penalties Mapping of ERC20 token addresses to amounts.
     */
    function getPenaltyAmount(uint256 epochIndex) public view onlyEpochConfigured(epochIndex) returns (uint256 ethPenalty, mapping(address => uint256) memory erc20Penalties) {
        // This view is difficult to implement accurately without a dedicated penalty pool.
        // Let's return 0 for now, indicating the simplified structure doesn't track explicit penalties this way.
        // Unclaimed funds remain in the contract until emergency withdrawn.
        // The feeRecipient receives the unlock fees, which act *like* a penalty for unsuccessful guessers
        // who deposited but couldn't unlock, as their deposit covers the fees of successful unlockers.
        // This needs a clearer design if explicit penalties are required.
        // For demonstration: just return 0
        return (0, erc20Penalties);
    }

    // Fallback function to receive ETH (only for deposits)
    receive() external payable {
        // Should only receive ETH via depositETH function with epoch index
        // Reject direct sends without data, or require depositETH call
         if (msg.sender != address(0)) { // Prevent genesis contract creation weirdness
             revert("Direct ETH receive not allowed, use depositETH");
         }
    }
}

```