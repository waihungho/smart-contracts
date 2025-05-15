Okay, let's design an interesting and relatively advanced smart contract concept. We'll build a "Quantum Vault" that allows users to deposit ERC-20 tokens which can only be unlocked by providing a valid Zero-Knowledge Proof (ZK Proof) after a certain time has passed, potentially combined with other conditions derived from the proof's public inputs. This incorporates concepts of conditional release, privacy (what the proof *verifies* vs. its public inputs), external contract interaction (the ZK verifier), and structured deposits.

We'll need a placeholder interface for the ZK Verifier contract, as implementing a full verifier in Solidity is prohibitively complex for a single example. The focus will be on the vault's logic interacting with this external verification process.

Here's the structure and the code:

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Contract Outline ---
// 1. Interface for an external Zero-Knowledge Proof Verifier contract.
// 2. Custom Errors for clarity and gas efficiency.
// 3. Enum for Deposit Status.
// 4. Struct to hold individual deposit details.
// 5. Main Contract Definition (QuantumVault) inheriting Ownable, ReentrancyGuard, Pausable.
// 6. State Variables: Mapping for deposits, deposit counter, penalty rate, approved ZK verifiers, mapping for depositor's deposit IDs, total active token deposits.
// 7. Events to log key actions.
// 8. Modifiers (inherited and custom if needed - none extra needed here).
// 9. Constructor: Sets contract owner.
// 10. Core Deposit & Unlock Logic:
//     - deposit: User deposits tokens with unlock conditions (time, condition hash).
//     - verifyUnlockCondition: Calls ZK Verifier, checks public inputs against stored hash, updates deposit status.
//     - withdraw: Allows user to withdraw unlocked funds.
// 11. Deposit Management & Queries:
//     - getDepositDetails: View details of a specific deposit.
//     - getDepositsByAddress: Get list of deposit IDs for a user.
//     - checkDepositStatus: Get current status of a deposit.
//     - isDepositUnlocked: Simple check if deposit is unlocked.
//     - getLastDepositId: Get the latest deposit ID.
//     - getDepositCountByAddress: Get the number of deposits for a user.
//     - transferDepositOwnership: Allow depositor to transfer rights to another address.
//     - cancelDepositEarly: Allow early cancellation with a penalty.
//     - calculateEarlyCancellationPenalty: View penalty amount for early cancellation.
// 12. ZK Verifier Management (Owner only):
//     - addZKVerifier: Add an approved verifier contract address.
//     - removeZKVerifier: Remove an approved verifier contract address.
//     - isZKVerifier: Check if an address is an approved verifier.
// 13. Contract Management (Owner only):
//     - pause/unpause: Pause/unpause contract functionality.
//     - setPenaltyRate: Set the penalty percentage for early cancellation.
//     - getPenaltyRate: View the current penalty rate.
//     - getTotalActiveTokenDeposits: View total active (not withdrawn/cancelled) amount for a token.
//     - getContractTokenBalance: View the contract's total balance for a token.
//     - sweepTokens: Allow owner to sweep accidentally sent tokens.
// 14. Ownership Management (Inherited).

// --- Function Summary (Total: 24 unique functions + 2 inherited = 26+) ---
// 1.  constructor(): Initializes the contract, setting the owner.
// 2.  deposit(address token, uint256 amount, uint40 unlockTime, bytes32 conditionHash): Accepts ERC20 token deposit, sets unlock time, and a hash representing required ZK proof public inputs. Requires token approval beforehand.
// 3.  getDepositDetails(uint256 depositId): [view] Returns the details of a specific deposit by its ID.
// 4.  verifyUnlockCondition(uint256 depositId, bytes calldata proof, uint256[] calldata publicInputs): Attempts to unlock a deposit. Requires the unlock time to be reached and a successful verification by an approved ZK Verifier contract. The hash of `publicInputs` must match the stored `conditionHash`. Only callable if the deposit is Active.
// 5.  withdraw(uint256 depositId): Allows the original depositor (or transferred owner) to withdraw funds once the deposit status is 'Unlocked'.
// 6.  addZKVerifier(address verifierAddress): [owner] Adds a trusted ZK Verifier contract address.
// 7.  removeZKVerifier(address verifierAddress): [owner] Removes a trusted ZK Verifier contract address.
// 8.  isZKVerifier(address verifierAddress): [view] Checks if an address is currently an approved ZK Verifier.
// 9.  pause(): [owner] Pauses core contract functionality (deposit, verify, withdraw, cancel).
// 10. unpause(): [owner] Unpauses core contract functionality.
// 11. setPenaltyRate(uint256 rate): [owner] Sets the percentage penalty applied for early deposit cancellation (0-100).
// 12. getPenaltyRate(): [view] Returns the current early cancellation penalty rate.
// 13. calculateEarlyCancellationPenalty(uint256 depositId): [view] Calculates the penalty amount for cancelling a specific deposit early.
// 14. cancelDepositEarly(uint256 depositId): Allows the depositor (or transferred owner) to cancel an Active deposit before its unlock time, incurring a penalty. The remaining funds are returned.
// 15. transferDepositOwnership(uint256 depositId, address newOwner): Allows the current depositor of an Active deposit to transfer their rights (to verify/withdraw/cancel) to another address.
// 16. getDepositsByAddress(address depositor): [view] Returns an array of deposit IDs associated with a specific address.
// 17. getTotalActiveTokenDeposits(address token): [view] Returns the total amount of a specific token currently held in deposits with 'Active' or 'Unlocked' status.
// 18. getContractTokenBalance(address token): [view] Returns the raw ERC20 balance of the contract for a given token. (May differ from `getTotalActiveTokenDeposits` due to fees or accidental transfers).
// 19. sweepTokens(address token, address recipient): [owner] Allows the owner to retrieve tokens sent to the contract accidentally, except for funds held in active or unlocked deposits.
// 20. checkDepositStatus(uint256 depositId): [view] Returns the current status (Active, Unlocked, Withdrawn, Cancelled) of a deposit.
// 21. getLastDepositId(): [view] Returns the ID of the most recently created deposit.
// 22. isDepositUnlocked(uint256 depositId): [view] Returns true if a deposit's status is 'Unlocked'.
// 23. getDepositCountByAddress(address depositor): [view] Returns the number of deposits created by a specific address.
// 24. renounceOwnership(): [inherited/owner] Renounces ownership of the contract.
// 25. transferOwnership(address newOwner): [inherited/owner] Transfers ownership of the contract to a new address.

// --- Smart Contract Code ---

// Placeholder Interface for an external ZK Verifier contract
interface IZKVerifier {
    function verifyProof(bytes calldata proof, uint256[] calldata publicInputs) external view returns (bool);
}

// Custom Errors
error DepositNotFound(uint256 depositId);
error DepositNotActive(uint256 depositId);
error DepositNotUnlocked(uint256 depositId);
error UnlockTimeNotReached(uint256 depositId);
error ProofVerificationFailed(uint256 depositId);
error InvalidConditionHash(uint256 depositId);
error InvalidPenaltyRate();
error DepositAlreadyWithdrawn(uint256 depositId);
error NotDepositOwner(uint256 depositId, address caller);
error CannotCancelAfterUnlockTime(uint256 depositId);
error ZKVerifierAlreadyApproved(address verifier);
error ZKVerifierNotApproved(address verifier);
error ZeroAmountDeposit();
error CannotSweepActiveDepositTokens(address token);


enum DepositStatus {
    Active,     // Deposit is live, waiting for unlock time and verification
    Unlocked,   // Unlock time reached and ZK proof verified
    Withdrawn,  // Funds have been successfully withdrawn
    Cancelled   // Deposit was cancelled early (penalty may apply)
}

struct Deposit {
    address depositor;          // The address that currently owns the deposit rights (can be transferred)
    address token;              // The ERC-20 token deposited
    uint256 amount;             // The amount of tokens deposited
    uint40 unlockTime;          // The timestamp when verification can begin
    bytes32 conditionHash;      // Hash of the expected ZK public inputs for verification
    DepositStatus status;       // Current status of the deposit
    uint40 depositTimestamp;    // Timestamp when the deposit was made
}

contract QuantumVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    mapping(uint256 => Deposit) private deposits;
    uint256 public lastDepositId = 0;

    // Percentage penalty for early cancellation (e.g., 10 for 10%)
    uint256 public earlyCancellationPenaltyRate = 10; // Default to 10%

    // Mapping of approved ZK Verifier contract addresses
    mapping(address => bool) public approvedZKVerifiers;

    // To track deposits per address (might become gas-intensive for large number of deposits per user)
    mapping(address => uint256[] private depositorDepositIds);

    // To track the total amount locked per token (sum of Active and Unlocked deposits)
    mapping(address => uint256 public totalActiveTokenDeposits);

    // Events
    event DepositMade(
        uint256 indexed depositId,
        address indexed depositor,
        address indexed token,
        uint256 amount,
        uint40 unlockTime,
        bytes32 conditionHash,
        uint40 timestamp
    );
    event DepositUnlocked(uint256 indexed depositId, uint40 timestamp);
    event FundsWithdrawn(
        uint256 indexed depositId,
        address indexed recipient,
        uint256 amount,
        uint40 timestamp
    );
    event DepositCancelled(
        uint256 indexed depositId,
        address indexed depositor,
        uint256 refundedAmount,
        uint256 penaltyAmount,
        uint40 timestamp
    );
    event ZKVerifierAdded(address indexed verifier);
    event ZKVerifierRemoved(address indexed verifier);
    event DepositOwnershipTransferred(
        uint256 indexed depositId,
        address indexed oldOwner,
        address indexed newOwner
    );
    event PenaltyRateUpdated(uint256 oldRate, uint256 newRate);

    constructor() Ownable(msg.sender) {}

    /// @notice Deposits ERC20 tokens into the vault with conditions for future unlock.
    /// @param token The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    /// @param unlockTime The timestamp after which the ZK proof can be verified.
    /// @param conditionHash A hash commitment to the required public inputs for the ZK proof.
    /// @dev The user must approve the contract to spend `amount` of `token` beforehand.
    function deposit(
        address token,
        uint256 amount,
        uint40 unlockTime,
        bytes32 conditionHash
    ) external whenNotPaused nonReentrant {
        if (amount == 0) revert ZeroAmountDeposit();
        if (unlockTime <= block.timestamp) revert UnlockTimeNotReached(0); // Use 0 as depositId not assigned yet

        lastDepositId++;
        uint256 currentDepositId = lastDepositId;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        deposits[currentDepositId] = Deposit({
            depositor: msg.sender,
            token: token,
            amount: amount,
            unlockTime: unlockTime,
            conditionHash: conditionHash,
            status: DepositStatus.Active,
            depositTimestamp: uint40(block.timestamp)
        });

        depositorDepositIds[msg.sender].push(currentDepositId);
        totalActiveTokenDeposits[token] += amount;

        emit DepositMade(
            currentDepositId,
            msg.sender,
            token,
            amount,
            unlockTime,
            conditionHash,
            uint40(block.timestamp)
        );
    }

    /// @notice Retrieves details for a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return Deposit struct containing all deposit information.
    function getDepositDetails(
        uint256 depositId
    ) external view returns (Deposit memory) {
        if (depositId == 0 || depositId > lastDepositId) revert DepositNotFound(depositId);
        return deposits[depositId];
    }

    /// @notice Attempts to verify the ZK proof and unlock the deposit.
    /// @param depositId The ID of the deposit to unlock.
    /// @param proof The ZK proof data (specific format depends on the verifier).
    /// @param publicInputs The public inputs associated with the proof.
    /// @dev Requires `unlockTime` to have passed and the proof to be valid by an approved verifier.
    function verifyUnlockCondition(
        uint256 depositId,
        bytes calldata proof,
        uint256[] calldata publicInputs
    ) external whenNotPaused nonReentrant {
        Deposit storage deposit = deposits[depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound(depositId); // Check if deposit exists (mapping default)
        if (deposit.status != DepositStatus.Active) revert DepositNotActive(depositId);
        if (block.timestamp < deposit.unlockTime) revert UnlockTimeNotReached(depositId);
        if (!approvedZKVerifiers[msg.sender]) revert ZKVerifierNotApproved(msg.sender);

        // Hash the public inputs to compare against the stored commitment
        // NOTE: This hashing logic must match the way the conditionHash was generated off-chain.
        // A common pattern is `keccak256(abi.encodePacked(publicInputs))`.
        bytes32 calculatedHash = keccak256(abi.encodePacked(publicInputs));

        if (calculatedHash != deposit.conditionHash) revert InvalidConditionHash(depositId);

        // Call the external ZK verifier contract
        bool success = IZKVerifier(msg.sender).verifyProof(proof, publicInputs);

        if (!success) revert ProofVerificationFailed(depositId);

        // Proof is valid and conditions met, unlock the deposit
        deposit.status = DepositStatus.Unlocked;

        emit DepositUnlocked(depositId, uint40(block.timestamp));
    }

    /// @notice Allows the deposit owner to withdraw unlocked funds.
    /// @param depositId The ID of the deposit to withdraw from.
    /// @dev Requires the deposit status to be 'Unlocked'.
    function withdraw(uint256 depositId) external whenNotPaused nonReentrant {
        Deposit storage deposit = deposits[depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound(depositId);
        if (deposit.status == DepositStatus.Withdrawn) revert DepositAlreadyWithdrawn(depositId);
        if (deposit.status != DepositStatus.Unlocked) revert DepositNotUnlocked(depositId);
        if (deposit.depositor != msg.sender) revert NotDepositOwner(depositId, msg.sender);

        uint256 amountToWithdraw = deposit.amount;
        deposit.status = DepositStatus.Withdrawn;

        totalActiveTokenDeposits[deposit.token] -= amountToWithdraw;

        // Find and remove the depositId from the depositor's list (optional, gas considerations)
        // This is inefficient for large arrays. Keeping for feature count, but real-world
        // might manage depositIds off-chain or with iterable mapping pattern.
        uint256[] storage userDeposits = depositorDepositIds[msg.sender];
        for (uint i = 0; i < userDeposits.length; i++) {
            if (userDeposits[i] == depositId) {
                userDeposits[i] = userDeposits[userDeposits.length - 1];
                userDeposits.pop();
                break;
            }
        }

        IERC20(deposit.token).safeTransfer(msg.sender, amountToWithdraw);

        emit FundsWithdrawn(depositId, msg.sender, amountToWithdraw, uint40(block.timestamp));
    }

    /// @notice Allows the current deposit owner to cancel an active deposit early, incurring a penalty.
    /// @param depositId The ID of the deposit to cancel.
    function cancelDepositEarly(uint256 depositId) external whenNotPaused nonReentrant {
        Deposit storage deposit = deposits[depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound(depositId);
        if (deposit.status != DepositStatus.Active) revert DepositNotActive(depositId);
        if (deposit.depositor != msg.sender) revert NotDepositOwner(depositId, msg.sender);
        if (block.timestamp >= deposit.unlockTime) revert CannotCancelAfterUnlockTime(depositId);

        uint256 penaltyAmount = calculateEarlyCancellationPenalty(depositId);
        uint256 refundAmount = deposit.amount - penaltyAmount;

        deposit.status = DepositStatus.Cancelled;

        totalActiveTokenDeposits[deposit.token] -= deposit.amount; // Full amount removed from active total

        // Find and remove depositId from depositor's list (same note as withdraw)
        uint256[] storage userDeposits = depositorDepositIds[msg.sender];
        for (uint i = 0; i < userDeposits.length; i++) {
            if (userDeposits[i] == depositId) {
                userDeposits[i] = userDeposits[userDeposits.length - 1];
                userDeposits.pop();
                break;
            }
        }

        IERC20(deposit.token).safeTransfer(msg.sender, refundAmount);

        emit DepositCancelled(
            depositId,
            msg.sender,
            refundAmount,
            penaltyAmount,
            uint40(block.timestamp)
        );
    }

    /// @notice Calculates the penalty amount for cancelling a deposit early.
    /// @param depositId The ID of the deposit.
    /// @return The calculated penalty amount.
    function calculateEarlyCancellationPenalty(
        uint256 depositId
    ) public view returns (uint256) {
         if (depositId == 0 || depositId > lastDepositId) revert DepositNotFound(depositId);
        Deposit storage deposit = deposits[depositId];
        // Penalty is a percentage of the original deposit amount
        return (deposit.amount * earlyCancellationPenaltyRate) / 100;
    }

    /// @notice Allows the current deposit owner to transfer ownership of the deposit rights to another address.
    /// @param depositId The ID of the deposit.
    /// @param newOwner The address of the new owner.
    /// @dev Can only transfer ownership of an Active deposit.
    function transferDepositOwnership(
        uint256 depositId,
        address newOwner
    ) external whenNotPaused nonReentrant {
        Deposit storage deposit = deposits[depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound(depositId);
        if (deposit.status != DepositStatus.Active) revert DepositNotActive(depositId);
        if (deposit.depositor != msg.sender) revert NotDepositOwner(depositId, msg.sender);
        if (newOwner == address(0)) revert OwnableInvalidOwner(address(0)); // Use Ownable error for zero address

        address oldOwner = deposit.depositor;
        deposit.depositor = newOwner;

        // Update depositorDepositIds mappings (gas-intensive) - simplified: add to new, don't remove from old.
        // A more robust solution would be needed for efficient lookup/removal.
        depositorDepositIds[newOwner].push(depositId);

        emit DepositOwnershipTransferred(depositId, oldOwner, newOwner);
    }


    // --- Owner Functions (ZK Verifier Management) ---

    /// @notice Allows the owner to add an approved ZK Verifier contract address.
    /// @param verifierAddress The address of the ZK Verifier contract.
    function addZKVerifier(address verifierAddress) external onlyOwner {
        if (approvedZKVerifiers[verifierAddress]) revert ZKVerifierAlreadyApproved(verifierAddress);
        approvedZKVerifiers[verifierAddress] = true;
        emit ZKVerifierAdded(verifierAddress);
    }

    /// @notice Allows the owner to remove an approved ZK Verifier contract address.
    /// @param verifierAddress The address of the ZK Verifier contract.
    function removeZKVerifier(address verifierAddress) external onlyOwner {
        if (!approvedZKVerifiers[verifierAddress]) revert ZKVerifierNotApproved(verifierAddress);
        approvedZKVerifiers[verifierAddress] = false;
        emit ZKVerifierRemoved(verifierAddress);
    }

    // --- Owner Functions (Contract Management) ---

    /// @notice Allows the owner to set the early cancellation penalty rate.
    /// @param rate The new penalty rate (0-100 percentage).
    function setPenaltyRate(uint256 rate) external onlyOwner {
        if (rate > 100) revert InvalidPenaltyRate();
        uint256 oldRate = earlyCancellationPenaltyRate;
        earlyCancellationPenaltyRate = rate;
        emit PenaltyRateUpdated(oldRate, rate);
    }

    /// @notice Allows the owner to sweep accidentally sent tokens (not part of active deposits).
    /// @param token The address of the token to sweep.
    /// @param recipient The address to send the swept tokens to.
    /// @dev Sweeps the total balance of the token minus the amount currently held in Active or Unlocked deposits.
    function sweepTokens(address token, address recipient) external onlyOwner {
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        uint256 activeDepositsAmount = totalActiveTokenDeposits[token];

        // Cannot sweep tokens that are part of active/unlocked deposits
        if (contractBalance < activeDepositsAmount) {
             // This case should ideally not happen if totalActiveTokenDeposits is correctly maintained
             // but adding a safeguard or a more specific error is good practice.
            revert CannotSweepActiveDepositTokens(token);
        }

        uint256 amountToSweep = contractBalance - activeDepositsAmount;

        if (amountToSweep > 0) {
             IERC20(token).safeTransfer(recipient, amountToSweep);
        }
        // Emit an event if sweeping happens (optional but good for tracking)
        // event TokensSwept(address indexed token, address indexed recipient, uint256 amount);
        // emit TokensSwept(token, recipient, amountToSweep);
    }

    // --- View Functions ---

    /// @notice Checks if an address is currently an approved ZK Verifier.
    /// @param verifierAddress The address to check.
    /// @return True if approved, false otherwise.
    function isZKVerifier(address verifierAddress) external view returns (bool) {
        return approvedZKVerifiers[verifierAddress];
    }

    /// @notice Returns the current early cancellation penalty rate.
    /// @return The penalty rate (0-100 percentage).
    function getPenaltyRate() external view returns (uint256) {
        return earlyCancellationPenaltyRate;
    }

    /// @notice Returns an array of deposit IDs associated with a specific address.
    /// @param depositor The address to query deposits for.
    /// @return An array of deposit IDs.
    function getDepositsByAddress(address depositor) external view returns (uint256[] memory) {
        return depositorDepositIds[depositor];
    }

    /// @notice Returns the total amount of a specific token currently held in Active or Unlocked deposits.
    /// @param token The address of the ERC20 token.
    /// @return The total amount of the token in active deposits.
    function getTotalActiveTokenDeposits(address token) external view returns (uint256) {
        return totalActiveTokenDeposits[token];
    }

     /// @notice Returns the raw ERC20 balance of the contract for a given token.
     /// @param token The address of the ERC20 token.
     /// @return The contract's total balance for the token.
    function getContractTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Returns the current status of a deposit.
    /// @param depositId The ID of the deposit.
    /// @return The DepositStatus enum value.
    function checkDepositStatus(uint256 depositId) external view returns (DepositStatus) {
         if (depositId == 0 || depositId > lastDepositId) revert DepositNotFound(depositId);
         return deposits[depositId].status;
    }

    /// @notice Returns true if a deposit's status is 'Unlocked'.
    /// @param depositId The ID of the deposit.
    /// @return True if unlocked, false otherwise.
    function isDepositUnlocked(uint256 depositId) external view returns (bool) {
        if (depositId == 0 || depositId > lastDepositId) return false; // Or revert DepositNotFound
        return deposits[depositId].status == DepositStatus.Unlocked;
    }

     /// @notice Returns the number of deposits created by a specific address.
     /// @param depositor The address to query.
     /// @return The number of deposits.
    function getDepositCountByAddress(address depositor) external view returns (uint256) {
        return depositorDepositIds[depositor].length;
    }

    // Pausable modifiers
    function pause() public override onlyOwner {
        _pause();
    }

    function unpause() public override onlyOwner {
        _unpause();
    }

    // Inherited from Ownable:
    // renounceOwnership()
    // transferOwnership(address newOwner)
}
```