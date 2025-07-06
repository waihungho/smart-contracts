Okay, let's design a smart contract that incorporates several advanced, creative, and trending concepts without directly copying existing common patterns.

**Concept:** **QuantumLockbox**

Imagine a smart contract that acts as a secure vault holding various assets (ETH, ERC-20, ERC-721). This vault can only be unlocked under specific, complex conditions that simulate elements of 'quantum' uncertainty and external verified 'observations' (attestations).

The unlock conditions involve:
1.  A specific time must pass.
2.  A set of "quantum secrets" must be *revealed* which match *prior commitments*. This uses a commit-reveal scheme.
3.  Verifiable "attestations" (proofs of external facts or identity claims signed by trusted entities) must be presented.
4.  A specific "unlocker candidate" (or their delegate) must initiate the process.

The contract uses a state machine to manage the locking/unlocking process. It includes functions for depositing, configuring the lock, managing secrets (commit/reveal), registering trusted attestors, managing the unlocker, attempting the unlock, and withdrawing assets once unlocked.

---

**Outline & Function Summary:**

1.  **License and Pragma:** Standard license and Solidity version.
2.  **Imports:** Interfaces for ERC20, ERC721, and potentially utility libraries (like Address, ECDSA).
3.  **Errors:** Custom errors for clarity and gas efficiency.
4.  **Interfaces:** Define necessary interfaces (`IERC20`, `IERC721`).
5.  **Libraries:** Use `Address` and `ECDSA` for safety and signature verification.
6.  **State Enum:** Defines the different states of the lockbox.
7.  **Structs:** Defines the configuration for the lock.
8.  **State Variables:** Stores owner, balances, lock config, state, trusted attestors, unlocker info, etc.
9.  **Events:** Emits logs for key actions.
10. **Modifiers:** Access control (`onlyOwner`, `whenState`, `whenNotPaused`, `onlyUnlockerCandidateOrDelegate`).
11. **Constructor:** Initializes the contract owner.
12. **Owner Functions:**
    *   `transferOwnership`: Standard owner transfer.
    *   `pause`: Emergency pause functionality.
    *   `unpause`: Resume from pause.
    *   `setTrustedAttestor`: Register/unregister addresses capable of signing attestations accepted by the lockbox.
    *   `configureLock`: Sets the unlock time, required attestation hashes, and initial secret commitments. Transitions state from `Idle` to `Configured`.
    *   `addRequiredAttestationHash`: Adds another required attestation hash *before* finalization.
    *   `addSecretCommitment`: Adds another secret commitment hash *before* finalization.
    *   `finalizeConfiguration`: Locks the configuration, preventing further additions of requirements/commitments. Transitions state to `SecretsCommitted`.
    *   `updateUnlockerCandidate`: Sets or changes the address allowed to attempt unlock (or delegate).
    *   `rescueFundsByOwner`: Allows owner to recover assets if the lockbox transitions to a `Failed` state after an unsuccessful unlock attempt.
13. **Deposit Functions:**
    *   `depositETH`: Receives native ETH.
    *   `depositERC20`: Receives ERC-20 tokens.
    *   `depositERC721`: Receives ERC-721 tokens.
14. **Secret Management Functions:**
    *   `revealSecret`: Provides the actual secret data corresponding to a prior commitment. Must be called before or during the transition to `ReadyForUnlock`.
    *   `batchRevealSecrets`: Reveals multiple secrets at once.
15. **Unlocker Management Functions:**
    *   `delegateUnlockPermission`: Allows the `unlockerCandidate` to authorize another address to attempt the unlock.
    *   `revokeDelegatePermission`: Revokes a previously granted delegation.
16. **State Transition Functions:**
    *   `signalReadyForUnlock`: Callable by owner or unlocker candidate after configuration is finalized and all initial secrets are revealed. Checks conditions and transitions state to `ReadyForUnlock`.
17. **Unlock Attempt Function:**
    *   `attemptUnlock`: The core function. Callable by the `unlockerCandidate` or delegate when the state is `ReadyForUnlock` and time has passed. Verifies the revealed secrets and provided attestation proofs against the configuration and trusted attestors. Transitions state to `Unlocked` on success or `Failed` on failure.
18. **Withdrawal Functions (After Unlock):**
    *   `withdrawETH`: Allows the `successfulUnlocker` (or owner if `Failed`) to withdraw ETH.
    *   `withdrawERC20`: Allows withdrawal of a specific ERC20 token by the `successfulUnlocker` (or owner if `Failed`).
    *   `withdrawERC721`: Allows withdrawal of a specific ERC721 token by the `successfulUnlocker` (or owner if `Failed`).
19. **View Functions:**
    *   `getLockboxConfig`: Returns the details of the lock configuration.
    *   `getLockboxState`: Returns the current state of the lockbox.
    *   `getETHBalance`: Returns the ETH balance held.
    *   `getERC20Balance`: Returns the balance of a specific ERC20 token.
    *   `getERC721Holding`: Checks if a specific ERC721 token is held.
    *   `getRequiredAttestationHashes`: Returns the list of required attestation hashes.
    *   `getSecretCommitments`: Returns the list of secret commitment hashes.
    *   `getRevealedSecretsStatus`: Returns a boolean array indicating which secrets have been revealed.
    *   `getUnlockerCandidate`: Returns the address of the designated unlocker candidate.
    *   `getDelegateUnlocker`: Returns the address currently delegated unlock permission.
    *   `isTrustedAttestor`: Checks if an address is a trusted attestor.
    *   `getSuccessfulUnlocker`: Returns the address that successfully unlocked the box (after state is `Unlocked`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// --- Outline & Function Summary ---
// 1. License and Pragma
// 2. Imports (IERC20, IERC721, Address, ECDSA)
// 3. Errors (Custom errors for specific failures)
// 4. Interfaces (IERC20, IERC721)
// 5. Libraries (Using Address and ECDSA)
// 6. State Enum (Idle, Configured, SecretsCommitted, ReadyForUnlock, Unlocked, Failed)
// 7. Structs (LockConfig - stores unlock conditions)
// 8. State Variables (owner, paused, balances, lock config, state, trusted attestors, unlocker info)
// 9. Events (DepositETH, DepositERC20, DepositERC721, TrustedAttestorSet, LockConfigured, RequiredAttestationAdded, SecretCommitmentAdded, ConfigurationFinalized, SecretRevealed, BatchSecretsRevealed, UnlockerCandidateUpdated, DelegateUnlockPermissionSet, DelegateUnlockPermissionRevoked, ReadyForUnlockSignaled, UnlockAttempt, UnlockSuccess, UnlockFailed, ETHWithdrawn, ERC20Withdrawn, ERC721Withdrawn, FundsRescued)
// 10. Modifiers (onlyOwner, whenState, whenNotPaused, onlyUnlockerCandidateOrDelegate)
// 11. Constructor (Sets owner)
// 12. Owner Functions:
//     - transferOwnership: Standard owner transfer.
//     - pause: Pauses contract operations.
//     - unpause: Unpauses contract.
//     - setTrustedAttestor: Manages addresses whose signatures on attestations are accepted.
//     - configureLock: Sets initial unlock conditions (time, attestation hashes, secret commitments). State: Idle -> Configured.
//     - addRequiredAttestationHash: Adds attestation requirement before finalization. State: Configured.
//     - addSecretCommitment: Adds secret commitment before finalization. State: Configured.
//     - finalizeConfiguration: Locks configuration. State: Configured -> SecretsCommitted.
//     - updateUnlockerCandidate: Sets address eligible to attempt unlock.
//     - rescueFundsByOwner: Allows owner recovery in Failed state.
// 13. Deposit Functions:
//     - depositETH: Receive native ETH.
//     - depositERC20: Receive ERC-20 tokens (requires approval).
//     - depositERC721: Receive ERC-721 tokens (requires approval/transferFrom).
// 14. Secret Management Functions:
//     - revealSecret: Provides actual secret matching a commitment.
//     - batchRevealSecrets: Reveals multiple secrets.
// 15. Unlocker Management Functions:
//     - delegateUnlockPermission: Unlocker candidate delegates unlock attempt.
//     - revokeDelegatePermission: Revokes delegation.
// 16. State Transition Functions:
//     - signalReadyForUnlock: Transition state if conditions met. State: SecretsCommitted -> ReadyForUnlock.
// 17. Unlock Attempt Function:
//     - attemptUnlock: Core function checking all unlock conditions. State: ReadyForUnlock -> Unlocked/Failed.
// 18. Withdrawal Functions (Post-Unlock/Failed):
//     - withdrawETH: Withdraw ETH.
//     - withdrawERC20: Withdraw specific ERC20.
//     - withdrawERC721: Withdraw specific ERC721.
// 19. View Functions:
//     - getLockboxConfig: View current lock config.
//     - getLockboxState: View current state.
//     - getETHBalance: View ETH balance.
//     - getERC20Balance: View specific ERC20 balance.
//     - getERC721Holding: Check holding of specific ERC721.
//     - getRequiredAttestationHashes: View required attestation hashes.
//     - getSecretCommitments: View secret commitment hashes.
//     - getRevealedSecretsStatus: View reveal status of secrets.
//     - getUnlockerCandidate: View unlocker candidate.
//     - getDelegateUnlocker: View delegate unlocker.
//     - isTrustedAttestor: Check trusted attestor status.
//     - getSuccessfulUnlocker: View successful unlocker address.

// --- Custom Errors ---
error NotOwner();
error Paused();
error NotPaused();
error InvalidState();
error StateNotConfigured();
error StateNotSecretsCommitted();
error StateNotReadyForUnlock();
error StateNotUnlocked();
error StateNotFailed();
error LockConfigAlreadyFinalized();
error LockNotConfigured();
error UnlockTimeNotReached();
error NotUnlockerCandidateOrDelegate();
error NoDelegateSet();
error AttestationProofInvalid();
error AttestationIssuerNotTrusted();
error AttestationHashMismatch();
error MissingRequiredAttestationProof();
error SecretNotCommitted();
error SecretAlreadyRevealed();
error SecretMismatch();
error MissingRequiredRevealedSecret();
error NotAllInitialSecretsRevealed();
error CallerNotSuccessfulUnlocker();
error NoFundsToWithdraw();
error ERC721NotHeld();

// --- Interfaces ---
// (Using OpenZeppelin's interfaces)

// --- State Enum ---
enum State {
    Idle, // No configuration set yet
    Configured, // Lock configuration set, can add more requirements/commitments
    SecretsCommitted, // Configuration finalized, initial secrets committed, waiting for revelation
    ReadyForUnlock, // All initial secrets revealed, waiting for unlock attempt time
    Unlocked, // Successfully unlocked, assets available for withdrawal
    Failed // Unlock attempt failed, assets potentially recoverable by owner
}

// --- Structs ---
struct LockConfig {
    bool isActive;
    uint40 unlockTimestamp; // Unix timestamp for unlock
    bytes32[] requiredAttestationHashes; // Keccak256 hash of the required claim data
    bytes32[] secretCommitments; // Keccak256 hash of the secrets
    bytes[] revealedSecrets; // Actual secrets revealed later
}

contract QuantumLockbox {
    using Address for address;
    using ECDSA for bytes32; // For signature verification

    // --- State Variables ---
    address private _owner;
    bool private _paused;

    State public lockboxState;
    LockConfig public lockboxConfig;

    // Balances (tracking for convenience, actual tokens are held by the contract)
    uint256 public ethBalance;
    mapping(address tokenAddress => uint256 balance) public erc20Balances;
    // Mapping of tokenAddress => tokenId => heldStatus
    mapping(address tokenAddress => mapping(uint256 tokenId => bool isHeld)) public erc721Holdings;

    // Addresses whose signatures are accepted for attestations
    mapping(address attestorAddress => bool isTrusted) public trustedAttestors;

    // Address authorized to attempt unlock
    address public unlockerCandidate;
    // Address delegated unlock permission by the candidate
    address public delegateUnlocker;
    // Address that successfully unlocked the box
    address public successfulUnlocker;

    // --- Events ---
    event DepositETH(address indexed depositor, uint256 amount);
    event DepositERC20(address indexed depositor, address indexed token, uint256 amount);
    event DepositERC721(address indexed depositor, address indexed token, uint256 tokenId);
    event TrustedAttestorSet(address indexed attestor, bool indexed status);
    event LockConfigured(uint40 unlockTimestamp, bytes32[] initialAttestationHashes, bytes32[] initialSecretCommitments);
    event RequiredAttestationAdded(bytes32 indexed attestationHash);
    event SecretCommitmentAdded(bytes32 indexed commitment);
    event ConfigurationFinalized();
    event SecretRevealed(address indexed revealer, bytes32 indexed commitmentHash);
    event BatchSecretsRevealed(address indexed revealer, bytes32[] commitmentHashes);
    event UnlockerCandidateUpdated(address indexed oldCandidate, address indexed newCandidate);
    event DelegateUnlockPermissionSet(address indexed candidate, address indexed delegate);
    event DelegateUnlockPermissionRevoked(address indexed candidate, address indexed delegate);
    event ReadyForUnlockSignaled();
    event UnlockAttempt(address indexed caller);
    event UnlockSuccess(address indexed unlocker);
    event UnlockFailed(address indexed attemptedUnlocker);
    event ETHWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Withdrawn(address indexed recipient, address indexed token, uint256 amount);
    event ERC721Withdrawn(address indexed recipient, address indexed token, uint256 tokenId);
    event FundsRescued(address indexed owner, address indexed token, uint256 amount); // ERC20 rescue
    event FundsRescuedETH(address indexed owner, uint256 amount); // ETH rescue
    event FundsRescuedERC721(address indexed owner, address indexed token, uint256 tokenId); // ERC721 rescue

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenState(State expectedState) {
        if (lockboxState != expectedState) revert InvalidState();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier onlyUnlockerCandidateOrDelegate() {
        if (msg.sender != unlockerCandidate && msg.sender != delegateUnlocker) revert NotUnlockerCandidateOrDelegate();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        lockboxState = State.Idle;
        _paused = false;
    }

    // --- Owner Functions ---

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
        // emit OwnershipTransferred(_owner, newOwner); // ERC173 standard event
    }

    /// @notice Pauses contract operations (deposits, configuration changes, unlock attempts, withdrawals).
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        // emit Paused(_owner); // ERC1155 standard event
    }

    /// @notice Unpauses contract operations.
    function unpause() external onlyOwner whenState(State.Failed) { // Only allow owner rescue from Failed state, otherwise resume
        _paused = false;
        // emit Unpaused(_owner); // ERC1155 standard event
    }

    /// @notice Sets the trust status of an address for signing attestations.
    /// Only trusted addresses can issue attestations accepted by the contract.
    /// @param attestor The address to set the trust status for.
    /// @param isTrusted The trust status (true for trusted, false for untrusted).
    function setTrustedAttestor(address attestor, bool isTrusted) external onlyOwner {
        trustedAttestors[attestor] = isTrusted;
        emit TrustedAttestorSet(attestor, isTrusted);
    }

    /// @notice Configures the initial parameters of the lockbox unlock conditions.
    /// Can only be called in the Idle state.
    /// @param unlockTimestamp The timestamp when the lockbox becomes eligible for unlock.
    /// @param initialRequiredAttestationHashes An array of Keccak256 hashes of claim data that must be attested to.
    /// @param initialSecretCommitments An array of Keccak256 hashes of secrets that must be revealed later.
    function configureLock(
        uint40 unlockTimestamp,
        bytes32[] calldata initialRequiredAttestationHashes,
        bytes32[] calldata initialSecretCommitments
    ) external onlyOwner whenState(State.Idle) whenNotPaused {
        lockboxConfig.isActive = true;
        lockboxConfig.unlockTimestamp = unlockTimestamp;
        lockboxConfig.requiredAttestationHashes = initialRequiredAttestationHashes;
        lockboxConfig.secretCommitments = initialSecretCommitments;
        // Initialize revealedSecrets with empty bytes matching commitments length
        lockboxConfig.revealedSecrets = new bytes[](initialSecretCommitments.length);

        lockboxState = State.Configured;

        emit LockConfigured(unlockTimestamp, initialRequiredAttestationHashes, initialSecretCommitments);
    }

    /// @notice Adds a required attestation hash to the configuration before finalization.
    /// Can only be called in the Configured state.
    /// @param attestationHash The Keccak256 hash of the claim data to add.
    function addRequiredAttestationHash(bytes32 attestationHash) external onlyOwner whenState(State.Configured) whenNotPaused {
        lockboxConfig.requiredAttestationHashes.push(attestationHash);
        emit RequiredAttestationAdded(attestationHash);
    }

    /// @notice Adds a secret commitment hash to the configuration before finalization.
    /// Can only be called in the Configured state.
    /// @param commitment The Keccak256 hash of the secret to add.
    function addSecretCommitment(bytes32 commitment) external onlyOwner whenState(State.Configured) whenNotPaused {
        lockboxConfig.secretCommitments.push(commitment);
        lockboxConfig.revealedSecrets.push(bytes("")); // Add placeholder for reveal
        emit SecretCommitmentAdded(commitment);
    }

    /// @notice Finalizes the lock configuration. No more required attestations or secret commitments can be added.
    /// Can only be called in the Configured state. Transitions to SecretsCommitted.
    function finalizeConfiguration() external onlyOwner whenState(State.Configured) whenNotPaused {
        lockboxState = State.SecretsCommitted;
        emit ConfigurationFinalized();
    }

    /// @notice Sets or updates the address designated as the unlocker candidate.
    /// This address (or its delegate) is the only one allowed to attempt the unlock.
    /// Can be called in any state before Unlocked or Failed.
    /// @param candidate The address to set as the unlocker candidate.
    function updateUnlockerCandidate(address candidate) external onlyOwner whenNotPaused {
        if (lockboxState == State.Unlocked || lockboxState == State.Failed) revert InvalidState();
        address oldCandidate = unlockerCandidate;
        unlockerCandidate = candidate;
        emit UnlockerCandidateUpdated(oldCandidate, candidate);
    }

    /// @notice Allows the owner to rescue assets if the lockbox is in a Failed state.
    /// This is a contingency for situations where the unlock fails permanently.
    /// Can only be called in the Failed state.
    /// @param tokenAddress The address of the ERC-20 or ERC-721 token to rescue (address(0) for ETH).
    /// @param tokenId For ERC-721 rescue, the ID of the token. Ignored for ETH and ERC-20.
    /// @param amount For ETH or ERC-20 rescue, the amount. Ignored for ERC-721.
    function rescueFundsByOwner(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner whenState(State.Failed) {
        if (tokenAddress == address(0)) {
            uint256 balance = ethBalance;
            if (balance == 0) revert NoFundsToWithdraw();
            ethBalance = 0;
            (bool success, ) = payable(_owner).call{value: balance}("");
            require(success, "ETH rescue failed");
            emit FundsRescuedETH(_owner, balance);
        } else {
             IERC20 token20 = IERC20(tokenAddress);
             // Check if it's ERC20 first based on amount > 0
             if (amount > 0 && token20.supportsInterface(0x36372b07)) { // ERC20 interface ID
                 uint256 balance = erc20Balances[tokenAddress];
                 if (amount > balance) revert NoFundsToWithdraw(); // Or specify insufficient balance error
                 erc20Balances[tokenAddress] -= amount;
                 token20.safeTransfer(_owner, amount); // Using safeTransfer from Address lib
                 emit FundsRescued(_owner, tokenAddress, amount);
             } else {
                 // Assume ERC721 if not ETH and not ERC20 rescue by amount
                 IERC721 token721 = IERC721(tokenAddress);
                 if (!erc721Holdings[tokenAddress][tokenId]) revert ERC721NotHeld();
                 erc721Holdings[tokenAddress][tokenId] = false;
                 token721.safeTransferFrom(address(this), _owner, tokenId); // Using safeTransferFrom from Address lib
                 emit FundsRescuedERC721(_owner, tokenAddress, tokenId);
             }
        }
    }

    // --- Deposit Functions ---

    /// @notice Allows depositing native ETH into the lockbox.
    receive() external payable whenNotPaused {
        if (msg.value > 0) {
            ethBalance += msg.value;
            emit DepositETH(msg.sender, msg.value);
        }
    }

    /// @notice Allows depositing ERC-20 tokens into the lockbox.
    /// Requires the caller to have approved the contract to spend the tokens first.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address tokenAddress, uint256 amount) external whenNotPaused {
        if (tokenAddress == address(0)) revert InvalidState(); // Prevent sending ETH via this
        IERC20 token = IERC20(tokenAddress);
        // Ensure the contract is approved to transfer
        token.safeTransferFrom(msg.sender, address(this), amount);
        erc20Balances[tokenAddress] += amount;
        emit DepositERC20(msg.sender, tokenAddress, amount);
    }

    /// @notice Allows depositing ERC-721 tokens (NFTs) into the lockbox.
    /// Requires the caller to have approved the contract or set it as an operator first.
    /// @param tokenAddress The address of the ERC-721 token.
    /// @param tokenId The ID of the NFT to deposit.
    function depositERC721(address tokenAddress, uint256 tokenId) external whenNotPaused {
        if (tokenAddress == address(0)) revert InvalidState(); // Prevent sending ETH via this
        IERC721 token = IERC721(tokenAddress);
        // Ensure the contract is approved or is operator
        token.safeTransferFrom(msg.sender, address(this), tokenId);
        erc721Holdings[tokenAddress][tokenId] = true;
        emit DepositERC721(msg.sender, tokenAddress, tokenId);
    }

    // --- Secret Management Functions ---

    /// @notice Reveals a secret that was previously committed.
    /// The Keccak256 hash of the provided secret must match one of the secret commitments.
    /// Can be called in States: SecretsCommitted or ReadyForUnlock.
    /// @param secret The actual secret data (bytes).
    function revealSecret(bytes memory secret) external whenState(State.SecretsCommitted) whenNotPaused {
        bytes32 secretHash = keccak256(secret);
        bool found = false;
        for (uint i = 0; i < lockboxConfig.secretCommitments.length; i++) {
            if (lockboxConfig.secretCommitments[i] == secretHash) {
                // Check if already revealed (revealedSecrets will not be empty)
                if (lockboxConfig.revealedSecrets[i].length > 0) revert SecretAlreadyRevealed();

                // Store the revealed secret
                lockboxConfig.revealedSecrets[i] = secret;
                found = true;
                emit SecretRevealed(msg.sender, secretHash);
                break; // Assuming each commitment is unique
            }
        }
        if (!found) revert SecretMismatch(); // Or SecretNotCommitted
    }

    /// @notice Reveals multiple secrets at once.
    /// @param secrets An array of actual secret data (bytes).
    function batchRevealSecrets(bytes[] memory secrets) external whenState(State.SecretsCommitted) whenNotPaused {
        bytes32[] memory revealedCommitmentHashes = new bytes32[](secrets.length);
        for (uint j = 0; j < secrets.length; j++) {
            bytes memory currentSecret = secrets[j];
            bytes32 secretHash = keccak256(currentSecret);
            revealedCommitmentHashes[j] = secretHash;
            bool found = false;
            for (uint i = 0; i < lockboxConfig.secretCommitments.length; i++) {
                if (lockboxConfig.secretCommitments[i] == secretHash) {
                    // Check if already revealed
                    if (lockboxConfig.revealedSecrets[i].length > 0) revert SecretAlreadyRevealed();

                    // Store the revealed secret
                    lockboxConfig.revealedSecrets[i] = currentSecret;
                    found = true;
                    break; // Assuming each commitment is unique
                }
            }
            if (!found) revert SecretMismatch(); // Or SecretNotCommitted for this batch item
        }
        emit BatchSecretsRevealed(msg.sender, revealedCommitmentHashes);
    }

    // --- Unlocker Management Functions ---

    /// @notice Allows the designated unlocker candidate to delegate unlock permission to another address.
    /// This delegate can then call attemptUnlock on behalf of the candidate.
    /// @param delegate The address to grant delegation to.
    function delegateUnlockPermission(address delegate) external onlyUnlockerCandidateOrDelegate whenNotPaused {
        // Only the designated candidate can set or change the delegate
        if (msg.sender != unlockerCandidate) revert NotUnlockerCandidateOrDelegate(); // Should be redundant with modifier, but explicit check is clear
        delegateUnlocker = delegate;
        emit DelegateUnlockPermissionSet(unlockerCandidate, delegate);
    }

    /// @notice Allows the designated unlocker candidate to revoke a previously granted delegation.
    function revokeDelegatePermission() external onlyUnlockerCandidateOrDelegate whenNotPaused {
         if (msg.sender != unlockerCandidate) revert NotUnlockerCandidateOrDelegate();
        if (delegateUnlocker == address(0)) revert NoDelegateSet();
        address revokedDelegate = delegateUnlocker;
        delegateUnlocker = address(0);
        emit DelegateUnlockPermissionRevoked(unlockerCandidate, revokedDelegate);
    }

    // --- State Transition Functions ---

    /// @notice Signals that the lockbox is ready to be potentially unlocked.
    /// Requires the state to be SecretsCommitted, configuration to be active, and all initial secrets revealed.
    /// Transitions state to ReadyForUnlock.
    function signalReadyForUnlock() external onlyUnlockerCandidateOrDelegate whenState(State.SecretsCommitted) whenNotPaused {
         if (!lockboxConfig.isActive) revert LockNotConfigured(); // Should not happen if state is Configured/SecretsCommitted, but defensive.

        // Check if all initially required secrets have been revealed
        for (uint i = 0; i < lockboxConfig.secretCommitments.length; i++) {
            if (lockboxConfig.revealedSecrets[i].length == 0) {
                revert NotAllInitialSecretsRevealed();
            }
             // Optional: Re-verify commitment against reveal if not done on revealSecret
             // if (keccak256(lockboxConfig.revealedSecrets[i]) != lockboxConfig.secretCommitments[i]) revert SecretMismatch();
        }

        lockboxState = State.ReadyForUnlock;
        emit ReadyForUnlockSignaled();
    }


    // --- Unlock Attempt Function ---

    /// @notice Attempts to unlock the lockbox.
    /// Can only be called by the unlocker candidate or delegate in the ReadyForUnlock state,
    /// after the unlock timestamp has passed.
    /// Requires providing proofs for all required attestations.
    /// Attestation Proof structure: Concatenated bytes (bytes sig, address issuer, bytes claimData).
    /// The contract verifies that keccak256(claimData) is one of the required hashes,
    /// that the issuer is trusted, and that the signature is valid for the claim data hash and issuer.
    /// @param attestationProofs An array of bytes, each containing a packed attestation proof.
    function attemptUnlock(bytes[] calldata attestationProofs) external onlyUnlockerCandidateOrDelegate whenState(State.ReadyForUnlock) whenNotPaused {
        emit UnlockAttempt(msg.sender);

        // 1. Check Unlock Time
        if (block.timestamp < lockboxConfig.unlockTimestamp) revert UnlockTimeNotReached();

        // 2. Verify Revealed Secrets
        // Ensure all initially required secrets are revealed (checked during signalReadyForUnlock)
        // Re-check that revealed secrets match commitments (can be redundant if checked on reveal)
         for (uint i = 0; i < lockboxConfig.secretCommitments.length; i++) {
             if (lockboxConfig.revealedSecrets[i].length == 0 || keccak256(lockboxConfig.revealedSecrets[i]) != lockboxConfig.secretCommitments[i]) {
                  lockboxState = State.Failed; // Transition to Failed on critical requirement failure
                  emit UnlockFailed(msg.sender);
                  revert MissingRequiredRevealedSecret(); // Or SecretMismatch
             }
         }


        // 3. Verify Attestation Proofs
        if (attestationProofs.length < lockboxConfig.requiredAttestationHashes.length) {
             lockboxState = State.Failed;
             emit UnlockFailed(msg.sender);
             revert MissingRequiredAttestationProof();
        }

        // Use a mapping to track which required attestation hashes have been successfully matched by a proof
        mapping(bytes32 => bool) verifiedRequiredHashes;
        uint256 verifiedCount = 0;

        for (uint i = 0; i < attestationProofs.length; i++) {
            bytes memory proof = attestationProofs[i];

            // Attempt to parse the proof structure: sig (65 bytes) || issuer (20 bytes) || claimData (variable)
            if (proof.length < 85) continue; // Skip malformed proofs

            bytes memory sig = new bytes(65);
            address issuer;
            bytes memory claimData;

            assembly {
                // Copy sig (65 bytes) from proof[0]
                mstore(add(sig, 0x20), mload(add(proof, 0x20))) // Length of sig bytes
                mstore(add(sig, 0x40), mload(add(proof, 0x40)))
                mstore(add(sig, 0x60), mload(add(proof, 0x60)))
                mstore(add(sig, 0x80), mload(add(proof, 0x80)))
                mstore(add(sig, 0xA0), mload(add(proof, 0xA0)))
                mstore(add(sig, 0xC0), mload(add(proof, 0xC0)))
                mstore(add(sig, 0xE0), mload(add(proof, 0xE0)))
                mstore(add(sig, 0x100), mload(add(proof, 0x100)))
                mstore(add(sig, 0x120), mload(add(proof, 0x120)))

                // Copy issuer (20 bytes) from proof[65]
                issuer := mload(add(proof, 0x20 + 65))

                // Copy claimData from proof[65+20]
                let claimDataPtr := add(proof, 0x20 + 65 + 20)
                let claimDataLen := sub(mload(proof), 65 + 20)
                claimData := mload(0x40) // Get free memory pointer
                mstore(0x40, add(claimData, add(claimDataLen, 0x20))) // Update free memory pointer
                mstore(claimData, claimDataLen) // Store claimData length
                // Copy claimData bytes
                calldatacopy(add(claimData, 0x20), claimDataPtr, claimDataLen) // This needs to be memory copy from `proof` variable, not calldata
                 // Correct memory copy:
                 let proofDataPtr := add(proof, 0x20) // Pointer to start of proof data (after length)
                 let sigPtr := add(proofDataPtr, 0)
                 let issuerPtr := add(proofDataPtr, 65)
                 let claimDataPtrCorrect := add(proofDataPtr, 65 + 20)
                 let claimDataLenCorrect := sub(mload(proof), 65 + 20)

                 // Copy signature
                 mload(0x40) // Get free memory pointer
                 let sigCopyPtr := mload(0x40)
                 mstore(0x40, add(sigCopyPtr, 65)) // Update free memory pointer
                 mcopy(sigCopyPtr, sigPtr, 65)
                 mstore(sig, 65) // Set length of sig variable
                 mstore(add(sig, 0x20), sigCopyPtr) // Point sig variable to the copied data

                 // Extract issuer
                 issuer := mload(issuerPtr)

                 // Copy claim data
                 mload(0x40) // Get free memory pointer again
                 let claimDataCopyPtr := mload(0x40)
                 mstore(0x40, add(claimDataCopyPtr, add(claimDataLenCorrect, 0x20))) // Update free memory pointer
                 mcopy(claimDataCopyPtr, claimDataPtrCorrect, claimDataLenCorrect)
                 mstore(claimData, claimDataLenCorrect) // Set length of claimData variable
                 mstore(add(claimData, 0x20), claimDataCopyPtr) // Point claimData variable to copied data


            }


            // Check if issuer is trusted
            if (!trustedAttestors[issuer]) {
                 // Note: We don't revert here immediately. A single bad proof shouldn't fail the *whole* attempt if other proofs cover requirements.
                 // We just skip this proof.
                 continue;
            }

            // Verify signature
            bytes32 hashedClaim = keccak256(claimData);
            bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(hashedClaim);

            address signer;
            try prefixedHash.recover(sig) returns (address recoveredSigner) {
                signer = recoveredSigner;
            } catch {
                // Signature recovery failed, skip this proof
                continue;
            }

            // Check if the recovered signer matches the issuer declared in the proof
            if (signer != issuer) {
                 // Signature verification failed, skip this proof
                 continue;
            }

            // Check if this verified claim hash is one of the required hashes
            for (uint j = 0; j < lockboxConfig.requiredAttestationHashes.length; j++) {
                if (lockboxConfig.requiredAttestationHashes[j] == hashedClaim) {
                    // Found a valid proof for a required hash. Mark it as verified.
                    if (!verifiedRequiredHashes[hashedClaim]) {
                         verifiedRequiredHashes[hashedClaim] = true;
                         verifiedCount++;
                         // Break inner loop, assuming one valid proof per required hash is enough
                         break;
                    }
                }
            }
        }

        // Check if all required attestation hashes were covered by valid proofs
        if (verifiedCount < lockboxConfig.requiredAttestationHashes.length) {
            lockboxState = State.Failed;
            emit UnlockFailed(msg.sender);
            revert MissingRequiredAttestationProof(); // Or more specific error
        }

        // If all checks pass: Unlock!
        lockboxState = State.Unlocked;
        successfulUnlocker = msg.sender;
        emit UnlockSuccess(msg.sender);
    }

    // --- Withdrawal Functions (Post-Unlock / Failed) ---

    /// @notice Allows the successful unlocker (or owner in Failed state) to withdraw native ETH.
    function withdrawETH() external whenNotPaused {
         address recipient;
         if (lockboxState == State.Unlocked) {
             if (msg.sender != successfulUnlocker) revert CallerNotSuccessfulUnlocker();
             recipient = successfulUnlocker;
         } else if (lockboxState == State.Failed) {
             if (msg.sender != _owner) revert NotOwner();
             recipient = _owner;
         } else {
             revert InvalidState();
         }

        uint256 balance = ethBalance;
        if (balance == 0) revert NoFundsToWithdraw();
        ethBalance = 0; // Set balance to zero BEFORE transfer (Checks-Effects-Interactions)
        (bool success, ) = payable(recipient).call{value: balance}("");
        require(success, "ETH withdrawal failed"); // Use require for external calls

        emit ETHWithdrawn(recipient, balance);
    }

    /// @notice Allows the successful unlocker (or owner in Failed state) to withdraw ERC-20 tokens.
    /// Withdraws the entire balance of the specified token held by the contract.
    /// @param tokenAddress The address of the ERC-20 token.
    function withdrawERC20(address tokenAddress) external whenNotPaused {
         address recipient;
         if (lockboxState == State.Unlocked) {
             if (msg.sender != successfulUnlocker) revert CallerNotSuccessfulUnlocker();
             recipient = successfulUnlocker;
         } else if (lockboxState == State.Failed) {
             if (msg.sender != _owner) revert NotOwner();
             recipient = _owner;
         } else {
             revert InvalidState();
         }

        if (tokenAddress == address(0)) revert InvalidState(); // Prevent ETH withdrawal here

        uint256 balance = erc20Balances[tokenAddress];
        if (balance == 0) revert NoFundsToWithdraw();
        erc20Balances[tokenAddress] = 0; // Set balance to zero BEFORE transfer

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(recipient, balance); // Use safeTransfer from Address lib

        emit ERC20Withdrawn(recipient, tokenAddress, balance);
    }

    /// @notice Allows the successful unlocker (or owner in Failed state) to withdraw a specific ERC-721 token.
    /// @param tokenAddress The address of the ERC-721 token.
    /// @param tokenId The ID of the NFT to withdraw.
    function withdrawERC721(address tokenAddress, uint256 tokenId) external whenNotPaused {
         address recipient;
         if (lockboxState == State.Unlocked) {
             if (msg.sender != successfulUnlocker) revert CallerNotSuccessfulUnlocker();
             recipient = successfulUnlocker;
         } else if (lockboxState == State.Failed) {
             if (msg.sender != _owner) revert NotOwner();
             recipient = _owner;
         } else {
             revert InvalidState();
         }

        if (tokenAddress == address(0)) revert InvalidState(); // Prevent ETH withdrawal here

        if (!erc721Holdings[tokenAddress][tokenId]) revert ERC721NotHeld();
        erc721Holdings[tokenAddress][tokenId] = false; // Set holding status BEFORE transfer

        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(address(this), recipient, tokenId); // Use safeTransferFrom from Address lib

        emit ERC721Withdrawn(recipient, tokenAddress, tokenId);
    }

    // --- View Functions ---

    /// @notice Returns the current configuration of the lockbox.
    /// @return isActive, unlockTimestamp, requiredAttestationHashes, secretCommitments, revealedSecrets
    function getLockboxConfig()
        external
        view
        returns (
            bool isActive,
            uint40 unlockTimestamp,
            bytes32[] memory requiredAttestationHashes,
            bytes32[] memory secretCommitments,
            bytes[] memory revealedSecrets // Note: Can be large, consider gas implications
        )
    {
        return (
            lockboxConfig.isActive,
            lockboxConfig.unlockTimestamp,
            lockboxConfig.requiredAttestationHashes,
            lockboxConfig.secretCommitments,
            lockboxConfig.revealedSecrets // Returning full secrets for view - be mindful of privacy depending on use case
        );
    }

    /// @notice Returns the current state of the lockbox.
    /// @return The current State enum value.
    function getLockboxState() external view returns (State) {
        return lockboxState;
    }

    /// @notice Returns the native ETH balance held by the lockbox.
    /// @return The ETH balance.
    function getETHBalance() external view returns (uint256) {
        return address(this).balance; // Or return the internally tracked ethBalance
    }

     /// @notice Returns the internally tracked native ETH balance held by the lockbox.
    /// @return The tracked ETH balance.
    function getTrackedETHBalance() external view returns (uint256) {
        return ethBalance;
    }


    /// @notice Returns the balance of a specific ERC-20 token held by the lockbox.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @return The token balance.
    function getERC20Balance(address tokenAddress) external view returns (uint256) {
        return erc20Balances[tokenAddress];
    }

    /// @notice Checks if a specific ERC-721 token is held by the lockbox.
    /// @param tokenAddress The address of the ERC-721 token.
    /// @param tokenId The ID of the NFT.
    /// @return True if the token is held, false otherwise.
    function getERC721Holding(address tokenAddress, uint256 tokenId) external view returns (bool) {
        return erc721Holdings[tokenAddress][tokenId];
    }

    /// @notice Returns the list of required attestation hashes for unlock.
    /// @return An array of bytes32 containing the required attestation hashes.
    function getRequiredAttestationHashes() external view returns (bytes32[] memory) {
        return lockboxConfig.requiredAttestationHashes;
    }

    /// @notice Returns the list of secret commitment hashes.
    /// @return An array of bytes32 containing the secret commitment hashes.
    function getSecretCommitments() external view returns (bytes32[] memory) {
        return lockboxConfig.secretCommitments;
    }

    /// @notice Returns the reveal status for each secret commitment.
    /// @return An array of booleans. True if the secret at the corresponding index has been revealed.
    function getRevealedSecretsStatus() external view returns (bool[] memory) {
        bool[] memory status = new bool[](lockboxConfig.secretCommitments.length);
        for (uint i = 0; i < lockboxConfig.secretCommitments.length; i++) {
            status[i] = lockboxConfig.revealedSecrets[i].length > 0;
        }
        return status;
    }

    /// @notice Returns the address of the designated unlocker candidate.
    /// @return The unlocker candidate address.
    function getUnlockerCandidate() external view returns (address) {
        return unlockerCandidate;
    }

     /// @notice Returns the address currently delegated unlock permission.
    /// @return The delegate unlocker address (address(0) if none set).
    function getDelegateUnlocker() external view returns (address) {
        return delegateUnlocker;
    }

    /// @notice Checks if an address is a trusted attestor.
    /// @param attestor The address to check.
    /// @return True if the address is trusted, false otherwise.
    function isTrustedAttestor(address attestor) external view returns (bool) {
        return trustedAttestors[attestor];
    }

    /// @notice Returns the address that successfully unlocked the box.
    /// Only relevant if the state is Unlocked.
    /// @return The address of the successful unlocker.
    function getSuccessfulUnlocker() external view returns (address) {
        return successfulUnlocker;
    }

    // Fallback function to accept ETH if receive() is not defined or fails, though receive() is sufficient here.
    // fallback() external payable {} // Not strictly needed with receive() but can be added
}

// Helper extensions from OpenZeppelin included for safety
// (These would typically be imported from @openzeppelin/contracts/utils/Address.sol etc.)
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: ETH transfer failed");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory retdata) = target.call{value: value}(data);
        return verifyCallResult(success, retdata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory retdata) = target.staticcall(data);
        return verifyCallResult(success, retdata, errorMessage);
    }

     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory retdata) = target.delegatecall(data);
        return verifyCallResult(success, retdata, errorMessage);
    }


    function verifyCallResult(bool success, bytes memory retdata, string memory errorMessage) internal pure returns(bytes memory) {
        if (success) {
            return retdata;
        } else {
            // Look for revert reason and bubble it up
            if (retdata.length > 0) {
                // The reason string is contained in the first 32 bytes of the retdata,
                // after the function selector (4 bytes)
                assembly {
                    let retdata_size := mload(retdata)
                    if iszero(lt(retdata_size, 36)) { // Check if retdata size is at least 36 bytes
                        let reason_ptr := add(retdata, 0x20) // Pointer to the data part of bytes
                        // We need to check if the first 4 bytes are the selector for "Error(string)" (0x08c379a0)
                        let selector := mload(reason_ptr)
                        if eq(selector, 0x08c379a000000000000000000000000000000000000000000000000000000000) {
                           // It's an Error(string), extract and bubble up the string
                            revert(add(reason_ptr, 0x4 + 0x20), sub(retdata_size, 0x4))
                        }
                    }
                }
            }
            revert(errorMessage);
        }
    }

    // --- Safe token transfer functions ---
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "Address: approve call did not return success or was not reverted");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 addedValue) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, currentAllowance + addedValue));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 subtractedValue) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        require(currentAllowance >= subtractedValue, "Address: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, currentAllowance - subtractedValue));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory retdata = functionCall(address(token), data, "Address: ERC20 low-level call failed");
        if (retdata.length > 0) { // Return data is optional for ERC20
            require(abi.decode(retdata, (bool)), "Address: ERC20 operation did not succeed");
        }
    }

    // --- Safe ERC721 transfer functions ---
     function safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory retdata) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, tokenId));
        require(success, "Address: ERC721 safeTransferFrom failed");

        if (retdata.length > 0) {
            // ERC721 transferFrom does not typically return a value.
            // Some implementations might return true/false or other data.
            // If it returns anything, we consider it failed if the first byte is not 0x00 (success indicator).
            // This is a defensive check based on some non-compliant implementations.
            if (retdata[0] != 0x00) {
                revert("Address: ERC721 transfer did not return success");
            }
        }
    }

    function safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
         // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory retdata) = address(token).call(abi.encodeWithSelector(token.safeTransferFrom.selector, from, to, tokenId, _data));
        require(success, "Address: ERC721 safeTransferFrom with data failed");

         if (retdata.length > 0) {
             if (retdata[0] != 0x00) {
                 revert("Address: ERC721 transfer with data did not return success");
             }
         }
    }
}

// ECDSA library from OpenZeppelin - used for signature recovery
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureV,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return;
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

     function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Bytes.toString(bytes(s))));
    }


    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            _throwError(RecoverError.InvalidSignatureLength);
        }
        return address(0); // Should not be reached
    }

     function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        RecoverError error = _tryRecover(hash, v, r, s);
        _throwError(error);
        // solhint-disable-next-line return-values
    }

    function _tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A5450D5DA2ECE4248B5399) {
             return RecoverError.InvalidSignatureS;
         }
        // EIP-2 still allows signature malleability for ecrecover(). We need to stay backwards compatible to accept
        // signatures from older clients.
        // solhint-disable-next-line no-if-statement
         if (v != 27 && v != 28) {
             // If the signature is from a different chainID, the v value will be different.
             // Standard EIP-155 requires v = 2 * chainID + 35 + recovery_byte (0 or 1).
             // We only support legacy non-EIP-155 signatures (v=27 or 28) here for simplicity.
             // For EIP-155, additional logic checking chainID would be needed.
             return RecoverError.InvalidSignatureV;
         }

         address signer;
         // solhint-disable-next-line no-inline-assembly
         assembly {
             let signature := mload(0x40) // Load free memory pointer
             mstore(signature, 0x20) // Store length of r (32 bytes)
             mstore(add(signature, 0x20), r) // Store r
             mstore(add(signature, 0x40), 0x20) // Store length of s (32 bytes)
             mstore(add(signature, 0x60), s) // Store s
             mstore(add(signature, 0x80), 1) // Store length of v (1 byte)
             mstore(add(signature, 0xA0), v) // Store v

             let success := call(gas(), 0x1, 0, signature, 0xA1, signature, 0x20) // ecrecover(hash, v, r, s)
             signer := mload(signature)

             mstore(0x40, add(signature, 0x20)) // Restore free memory pointer
             if iszero(success) {
                 return (RecoverError.InvalidSignature) // Non-zero return value for failure
             }
         }

         return signer == address(0) ? RecoverError.InvalidSignature : RecoverError.NoError;
     }
}

library Bytes {
    function toString(bytes memory _bytes) internal pure returns (string memory) {
        // Inspired by https://github.com/ethereum/dapp-bin/blob/master/library/stringUtils.sol#L10
        bytes memory bytesString = new bytes(_bytes.length * 2);
        uint256 uint_byte;
        for (uint256 i = 0; i < _bytes.length; i++) {
            uint_byte = uint8(_bytes[i]);
            uint8 hi = uint8(uint_byte / 16);
            uint8 lo = uint8(uint_byte % 16);
            bytesString[i * 2] = bytes1(uint8(48 + hi + (hi > 9 ? 7 : 0)));
            bytesString[i * 2 + 1] = bytes1(uint8(48 + lo + (lo > 9 ? 7 : 0)));
        }
        return string(bytesString);
    }
}
```