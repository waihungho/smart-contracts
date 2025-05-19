Okay, let's design a smart contract called `QuantumVault`. This contract will act as a conditional escrow or vault where funds (ETH or ERC-20 tokens) are locked, and can only be withdrawn if *one* of several predefined, potentially complex conditions is met. This includes concepts like timed locks, required external oracle values, required staking/holding of another token, multi-signature approvals, *and* verification of a Zero-Knowledge Proof (ZKP) related to an off-chain condition. Each deposit creates a unique "lock" with its own set of conditions.

This concept is interesting because it combines multiple conditional release mechanisms, integrates external data (oracles), token interactions (staking), decentralized decision making (multisig), and cutting-edge privacy/verification tech (ZKPs) within a single vault structure. It's not a standard ERC-4626 vault, a simple timelock, or a basic multisig wallet.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  ** SPDX License & Pragma**
2.  ** Imports:** ERC20, Ownable, Pausable, potentially interfaces for ZKVerifier and Oracle.
3.  ** Interfaces:** `I_ZKVerifier`, `I_Oracle` (placeholder for external interactions).
4.  ** Error Handling:** Custom errors for clarity.
5.  ** Enums:** `ConditionType` (Timelock, Stake, Oracle, Multisig, ZKProof), `LockStatus` (Active, Withdrawn, Expired, Revoked).
6.  ** Structs:**
    *   `MultisigData`: Tracks approvals for a specific lock withdrawal attempt.
    *   `ConditionParameters`: Stores parameters for different condition types.
    *   `Lock`: Represents a single deposit/lock instance with details and required conditions.
7.  ** State Variables:**
    *   Owner, Paused state.
    *   External contract addresses (ZKVerifier, Stake Token, Oracle, Multisig signers).
    *   Multisig configuration (signers, threshold).
    *   Mapping from lock ID to `Lock` struct.
    *   Mapping from user address to list of lock IDs.
    *   Counter for lock IDs.
    *   Total locked balances (ETH and specific token if applicable).
8.  ** Events:** Tracking deposits, withdrawals, condition definitions, multisig actions, configuration changes, etc.
9.  ** Modifiers:** `onlyDepositor`, `onlyMultisigSigner`.
10. ** Core Logic Functions:**
    *   `constructor`: Initializes owner, sets initial dependencies/configs.
    *   `setDependencies`: Owner sets addresses of external contracts (ZKVerifier, Oracle).
    *   `setStakeToken`: Owner sets the address of the required stake token.
    *   `setMultisigConfig`: Owner sets the multisig signers and threshold.
    *   `pause`, `unpause`: Owner controls contract state.
    *   `depositETH`: Allows users to deposit ETH and define lock conditions.
    *   `depositTokens`: Allows users to deposit ERC20 tokens and define lock conditions.
    *   `attemptWithdraw`: Main function for a user to attempt withdrawing a locked amount by meeting *one* of the lock's defined conditions. Dispatches to internal check functions.
    *   `submitMultisigApproval`: Allows a multisig signer to approve a withdrawal attempt for a specific lock.
    *   `revokeMultisigApproval`: Allows a multisig signer to revoke their approval.
    *   `updateLockConditionParameters`: Allows depositor to potentially update parameters on their own lock (e.g., extend timelock).
    *   `sweepUnsupportedTokens`: Owner can recover mistakenly sent tokens (not the primary vaulted tokens).
    *   `transferOwnership`: Standard Ownable function.
11. ** Internal Helper Functions:**
    *   `_createLock`: Internal function to handle lock creation logic.
    *   `_isConditionMet`: Internal dispatcher to check if any *one* of the conditions for a lock is met.
    *   `_checkTimelock`: Internal logic for timelock condition.
    *   `_checkStake`: Internal logic for stake condition.
    *   `_checkOracle`: Internal logic for oracle condition.
    *   `_checkMultisig`: Internal logic for multisig condition.
    *   `_checkZKProof`: Internal logic for ZK proof condition.
    *   `_transferFunds`: Internal function for safe fund transfer.
12. ** View/Pure Functions:**
    *   `getLockDetails`: Get full details of a specific lock.
    *   `getUserLockIds`: Get all lock IDs associated with a user.
    *   `getTotalLockedBalanceETH`: Get total ETH locked.
    *   `getTotalLockedBalanceTokens`: Get total tokens locked for a specific token address.
    *   `getLockConditionTypes`: Get the types of conditions defined for a lock.
    *   `getMultisigState`: Get current approvals for a lock's multisig attempt.
    *   `getMultisigConfig`: Get configured multisig signers and threshold.
    *   `getZKVerifierAddress`: Get the configured ZK verifier address.
    *   `getOracleAddress`: Get the configured Oracle address.
    *   `getRequiredStakeTokenAddress`: Get the configured stake token address.
    *   `isLockActive`: Check if a lock is still active.
    *   `canAttemptWithdraw`: Helper view function to see if withdrawal is plausible (checks basic status, not conditions).

---

**Function Summary (targeting 20+ public/external/view):**

1.  `constructor`: Sets contract owner and initial configurations.
2.  `setDependencies`: Sets addresses of external ZKVerifier and Oracle contracts. (Owner)
3.  `setStakeToken`: Sets the required stake token address. (Owner)
4.  `setMultisigConfig`: Sets the fixed list of multisig signers and required threshold. (Owner)
5.  `pause`: Pauses deposits and withdrawals. (Owner)
6.  `unpause`: Unpauses the contract. (Owner)
7.  `depositETH`: Deposits ETH, defines condition(s), creates a lock.
8.  `depositTokens`: Deposits ERC20 tokens, defines condition(s), creates a lock.
9.  `attemptWithdraw`: Initiates a withdrawal attempt for a specific lock ID, triggering condition checks. Requires specific parameters based on the attempted condition type (e.g., ZK proof inputs, target oracle value).
10. `submitMultisigApproval`: A designated multisig signer approves a withdrawal attempt for a lock.
11. `revokeMultisigApproval`: A designated multisig signer revokes their approval.
12. `updateLockConditionParameters`: Allows the original depositor to update certain parameters of their active lock conditions (e.g., extend timelock, increase required stake). Restricted updates only.
13. `sweepUnsupportedTokens`: Allows the owner to retrieve tokens accidentally sent to the contract, excluding the primary vaulted token(s).
14. `transferOwnership`: Transfers contract ownership. (Owner)
15. `getLockDetails`: (View) Returns all details for a given lock ID.
16. `getUserLockIds`: (View) Returns an array of lock IDs owned by a specific address.
17. `getTotalLockedBalanceETH`: (View) Returns the total amount of ETH currently locked in the contract.
18. `getTotalLockedBalanceTokens`: (View) Returns the total amount of a specific ERC20 token locked in the contract.
19. `getLockConditionTypes`: (View) Returns the types of conditions configured for a specific lock ID.
20. `getMultisigState`: (View) Returns the current state of multisig approvals for a lock ID's withdrawal attempt.
21. `getMultisigConfig`: (View) Returns the current multisig signers and threshold.
22. `getZKVerifierAddress`: (View) Returns the configured ZK verifier contract address.
23. `getOracleAddress`: (View) Returns the configured Oracle contract address.
24. `getRequiredStakeTokenAddress`: (View) Returns the configured stake token address.
25. `isLockActive`: (View) Checks if a lock ID is currently in the 'Active' status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Using OpenZeppelin for ERC20 standard
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for Ownable
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol"; // Using OpenZeppelin for Pausable
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Using OpenZeppelin for ReentrancyGuard

// --- Interfaces ---

// Placeholder interface for a ZK Verifier contract
// A real implementation would require specific verify function signatures
interface I_ZKVerifier {
    function verify(bytes memory proof, bytes memory publicInputs) external view returns (bool);
    // Example: function verifyGroth16(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[] memory input) external view returns (bool);
}

// Placeholder interface for an Oracle contract
// A real implementation would vary based on the oracle provider (e.g., Chainlink)
interface I_Oracle {
    // Example: function getValue(bytes32 key) external view returns (int256 value, uint256 timestamp);
    // For simplicity in this example, we'll assume a simple getter
    function getLatestValue() external view returns (int256);
}

// --- Custom Errors ---
error QuantumVault__InvalidConditionParameters();
error QuantumVault__WithdrawalAlreadyProcessed();
error QuantumVault__LockDoesNotExist();
error QuantumVault__NotDepositor();
error QuantumVault__UnsupportedTokenType();
error QuantumVault__ConditionNotMet(string reason);
error QuantumVault__MustDefineAtLeastOneCondition();
error QuantumVault__WithdrawalAttemptRequiresSpecificParameters(ConditionType requiredType);
error QuantumVault__NotMultisigSigner();
error QuantumVault__MultisigAlreadyApprovedOrRevoked();
error QuantumVault__MultisigThresholdNotReached();
error QuantumVault__UpdateNotAllowed();
error QuantumVault__ConditionTypeMismatch();
error QuantumVault__ETHTransferFailed();
error QuantumVault__ZeroAddressDependency();
error QuantumVault__ZeroMultisigSigners();

// --- Enums ---
enum ConditionType {
    None, // Should not be used for a valid lock
    Timelock,
    Stake, // Requires holding/staking a specific token
    Oracle, // Requires an external oracle value
    Multisig, // Requires M of N approvals
    ZKProof // Requires a verifiable Zero-Knowledge Proof
}

enum LockStatus {
    Active,
    Withdrawn,
    Expired, // For timelocks that passed, but weren't withdrawn
    Revoked // If a condition allows revocation (e.g., multisig failure or depositor cancels)
}

// --- Structs ---

struct MultisigData {
    // Using a dynamic array is gas-inefficient for storage, but simpler for example.
    // For production, consider bitmasks or fixed-size arrays if N is small, or mapping(address => bool).
    address[] signers;
    uint256 threshold;
    mapping(address => bool) approvals;
    uint256 currentApprovalsCount;
}

struct ConditionParameters {
    uint256 timelockExpiration; // For Timelock: unix timestamp
    uint256 requiredStakeAmount; // For Stake: minimum token amount
    int256 requiredOracleValue; // For Oracle: target value from oracle
    bytes32 zkProofIdentifier; // For ZKProof: identifier for the type/parameters of ZK proof needed
    bytes zkProofVerificationInput; // For ZKProof: auxiliary public inputs for verification (e.g., commitment hash)
    // Multisig parameters are stored separately in the MultisigData struct for each lock
}

struct Lock {
    uint256 id;
    address depositor;
    address tokenAddress; // ERC20 token address, or address(0) for ETH
    uint256 amount;
    uint256 depositTime;
    LockStatus status;
    ConditionType[] conditionTypes; // A lock can require *any* of these conditions to be met
    ConditionParameters params;
    MultisigData multisig; // Specific multisig state for this lock
    // Note: Could add fee structures per lock, etc. for more complexity
}

// --- Contract ---
contract QuantumVault is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    uint256 private _lockIdCounter;
    mapping(uint256 => Lock) public locks;
    mapping(address => uint256[]) private _userLockIds;

    // Dependencies
    I_ZKVerifier private _zkVerifier;
    IERC20 private _stakeToken; // Token required for the Stake condition
    I_Oracle private _oracle;

    // Global Multisig configuration for who *can* be a signer on any lock's multisig condition
    // The actual threshold and list of signers for a *specific* lock are stored in Lock.multisig
    address[] private _globalMultisigSigners;
    // Note: This global list could be simplified to a mapping(address => bool) for signer check

    // Track total locked balances
    uint256 private _totalLockedETH;
    mapping(address => uint256) private _totalLockedTokens; // per token address

    // --- Events ---

    event LockCreated(
        uint256 indexed lockId,
        address indexed depositor,
        address indexed tokenAddress,
        uint256 amount,
        ConditionType[] conditionTypes,
        uint256 depositTime
    );

    event WithdrawalAttempted(uint256 indexed lockId, address indexed attempter, ConditionType attemptedCondition);
    event WithdrawalSuccessful(uint256 indexed lockId, address indexed withdrawer, uint256 amount, address tokenAddress);
    event LockStatusUpdated(uint256 indexed lockId, LockStatus newStatus);

    event ConditionParametersUpdated(uint256 indexed lockId, ConditionType indexed conditionType);

    event MultisigApprovalSubmitted(uint256 indexed lockId, address indexed signer);
    event MultisigApprovalRevoked(uint256 indexed lockId, address indexed signer);

    event DependenciesSet(address zkVerifier, address oracle);
    event StakeTokenSet(address stakeToken);
    event MultisigConfigSet(address[] signers, uint256 threshold);

    event UnsupportedTokensSwept(address indexed token, uint256 amount, address indexed recipient);

    // --- Modifiers ---

    modifier onlyDepositor(uint256 _lockId) {
        if (locks[_lockId].depositor != msg.sender) {
            revert QuantumVault__NotDepositor();
        }
        _;
    }

    modifier onlyMultisigSigner() {
        bool isSigner = false;
        for (uint256 i = 0; i < _globalMultisigSigners.length; i++) {
            if (_globalMultisigSigners[i] == msg.sender) {
                isSigner = true;
                break;
            }
        }
        if (!isSigner) {
            revert QuantumVault__NotMultisigSigner();
        }
        _;
    }

    // --- Constructor ---

    constructor(address initialZKVerifier, address initialOracle, address initialStakeToken, address[] memory initialMultisigSigners, uint256 initialMultisigThreshold) Ownable(msg.sender) Pausable(false) {
        if (initialZKVerifier == address(0) || initialOracle == address(0) || initialStakeToken == address(0)) {
             revert QuantumVault__ZeroAddressDependency();
        }
        if (initialMultisigSigners.length == 0 || initialMultisigThreshold == 0 || initialMultisigThreshold > initialMultisigSigners.length) {
             revert QuantumVault__ZeroMultisigSigners();
        }

        _zkVerifier = I_ZKVerifier(initialZKVerifier);
        _oracle = I_Oracle(initialOracle);
        _stakeToken = IERC20(initialStakeToken);

        _globalMultisigSigners = initialMultisigSigners; // Store the global list of potential signers
        // Note: The threshold and specific signers for a *lock's* multisig condition are set during deposit/lock creation.
        // For simplicity, let's make the lock's multisig threshold match the global threshold initially.
        // A more complex version could allow specifying lock-specific signers/thresholds from the global list.
    }

    // --- Configuration Functions (Owner Only) ---

    function setDependencies(address zkVerifier, address oracle) external onlyOwner {
        if (zkVerifier == address(0) || oracle == address(0)) revert QuantumVault__ZeroAddressDependency();
        _zkVerifier = I_ZKVerifier(zkVerifier);
        _oracle = I_Oracle(oracle);
        emit DependenciesSet(zkVerifier, oracle);
    }

    function setStakeToken(address stakeToken) external onlyOwner {
         if (stakeToken == address(0)) revert QuantumVault__ZeroAddressDependency();
        _stakeToken = IERC20(stakeToken);
        emit StakeTokenSet(stakeToken);
    }

    // Sets the *global* list of potential multisig signers and default threshold for *new* locks
    function setMultisigConfig(address[] memory signers, uint256 threshold) external onlyOwner {
        if (signers.length == 0 || threshold == 0 || threshold > signers.length) {
             revert QuantumVault__ZeroMultisigSigners();
        }
        _globalMultisigSigners = signers;
         // Note: This *does not* affect existing locks' multisig configurations.
         // Existing locks retain the config they were created with.
        emit MultisigConfigSet(signers, threshold);
    }

    // --- Pausable Functions ---

    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- Deposit Functions ---

    function depositETH(ConditionType[] memory _conditionTypes, ConditionParameters memory _params)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        if (msg.value == 0) revert QuantumVault__InvalidConditionParameters(); // Minimum deposit amount check
        if (_conditionTypes.length == 0) revert QuantumVault__MustDefineAtLeastOneCondition();

        _totalLockedETH += msg.value;
        _createLock(address(0), msg.value, _conditionTypes, _params);
    }

    function depositTokens(address _tokenAddress, uint256 _amount, ConditionType[] memory _conditionTypes, ConditionParameters memory _params)
        external
        whenNotPaused
        nonReentrant
    {
        if (_amount == 0) revert QuantumVault__InvalidConditionParameters(); // Minimum deposit amount check
        if (_tokenAddress == address(0)) revert QuantumVault__UnsupportedTokenType(); // Cannot use address(0) for ERC20
         if (_conditionTypes.length == 0) revert QuantumVault__MustDefineAtLeastOneCondition();

        IERC20 token = IERC20(_tokenAddress);
        // Ensure contract is approved to spend the tokens
        if (token.allowance(msg.sender, address(this)) < _amount) {
            revert ERC20InsufficientAllowance(token.allowance(msg.sender, address(this)), _amount);
        }
        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert ERC20TransferFromFailed(msg.sender, address(this), _amount);
        }

        _totalLockedTokens[_tokenAddress] += _amount;
        _createLock(_tokenAddress, _amount, _conditionTypes, _params);
    }

    // --- Withdrawal Attempt Function ---

    // attemptWithdraw is the main function to try and get funds out.
    // It checks the status, ensures the caller is the depositor,
    // and then checks if *any* of the conditions defined for the lock are met.
    // Parameters are passed generically and interpreted based on the lock's condition types.
    // For ZKProof: proof and publicInputs should be provided in the bytes parameter.
    // For Oracle: The function implicitly checks the current oracle value based on the lock's required value.
    // For Multisig: This function doesn't check multisig itself; submitMultisigApproval does. This function checks if threshold is met *after* approvals are submitted.
    function attemptWithdraw(uint256 _lockId, bytes memory _withdrawalParameters)
        external
        nonReentrant // Prevent reentrancy during withdrawal
        whenNotPaused
    {
        Lock storage lock = locks[_lockId];

        if (lock.status != LockStatus.Active) {
             if (lock.id == 0) revert QuantumVault__LockDoesNotExist(); // Check if lock ID is valid
            revert QuantumVault__WithdrawalAlreadyProcessed(); // Status is not Active
        }
        if (lock.depositor != msg.sender) {
            revert QuantumVault__NotDepositor();
        }
        if (lock.conditionTypes.length == 0) {
             revert QuantumVault__InvalidConditionParameters(); // Should not happen if locks are created correctly
        }

        // Check if ANY condition is met
        bool conditionMet = false;
        for (uint256 i = 0; i < lock.conditionTypes.length; i++) {
            ConditionType currentCondition = lock.conditionTypes[i];

             // Delegate the check based on the condition type
            if (_isConditionMet(_lockId, currentCondition, _withdrawalParameters)) {
                conditionMet = true;
                emit WithdrawalAttempted(_lockId, msg.sender, currentCondition);
                break; // Only one condition needs to be met
            }
        }

        if (!conditionMet) {
            revert QuantumVault__ConditionNotMet("None of the defined conditions are currently met.");
        }

        // If condition is met, transfer funds
        _transferFunds(lock.tokenAddress, lock.depositor, lock.amount);

        // Update lock status
        lock.status = LockStatus.Withdrawn;

        // Update total locked balances
        if (lock.tokenAddress == address(0)) {
            _totalLockedETH -= lock.amount;
        } else {
            _totalLockedTokens[lock.tokenAddress] -= lock.amount;
        }

        emit WithdrawalSuccessful(_lockId, msg.sender, lock.amount, lock.tokenAddress);
        emit LockStatusUpdated(_lockId, LockStatus.Withdrawn);
    }

    // --- Multisig Specific Functions ---

    // Allows a multisig signer to approve a withdrawal attempt for a lock
    function submitMultisigApproval(uint256 _lockId) external onlyMultisigSigner whenNotPaused {
        Lock storage lock = locks[_lockId];

        if (lock.status != LockStatus.Active) {
             if (lock.id == 0) revert QuantumVault__LockDoesNotExist();
            revert QuantumVault__WithdrawalAlreadyProcessed();
        }

        // Check if Multisig is one of the required conditions for this lock
        bool isMultisigCondition = false;
        for(uint i=0; i < lock.conditionTypes.length; i++) {
            if (lock.conditionTypes[i] == ConditionType.Multisig) {
                isMultisigCondition = true;
                break;
            }
        }
        if (!isMultisigCondition) {
            revert QuantumVault__ConditionTypeMismatch(); // Multisig approval not required for this lock
        }

        // Check if signer has already approved
        if (lock.multisig.approvals[msg.sender]) {
            revert QuantumVault__MultisigAlreadyApprovedOrRevoked();
        }

        lock.multisig.approvals[msg.sender] = true;
        lock.multisig.currentApprovalsCount++;

        emit MultisigApprovalSubmitted(_lockId, msg.sender);

        // Note: Withdrawal happens when attemptWithdraw is called *after* threshold is met.
        // We could auto-withdraw here if threshold is reached, but requiring attemptWithdraw
        // makes the flow consistent and allows attaching parameters (like ZK proof) if needed alongside multisig.
    }

     // Allows a multisig signer to revoke their approval for a lock
    function revokeMultisigApproval(uint256 _lockId) external onlyMultisigSigner whenNotPaused {
        Lock storage lock = locks[_lockId];

        if (lock.status != LockStatus.Active) {
             if (lock.id == 0) revert QuantumVault__LockDoesNotExist();
            revert QuantumVault__WithdrawalAlreadyProcessed();
        }

        bool isMultisigCondition = false;
         for(uint i=0; i < lock.conditionTypes.length; i++) {
            if (lock.conditionTypes[i] == ConditionType.Multisig) {
                isMultisigCondition = true;
                break;
            }
        }
        if (!isMultisigCondition) {
            revert QuantumVault__ConditionTypeMismatch(); // Multisig approval not required for this lock
        }


        // Check if signer has approved
        if (!lock.multisig.approvals[msg.sender]) {
            revert QuantumVault__MultisigAlreadyApprovedOrRevoked(); // Or a different error like NotApprovedYet
        }

        lock.multisig.approvals[msg.sender] = false;
        lock.multisig.currentApprovalsCount--;

        emit MultisigApprovalRevoked(_lockId, msg.sender);
    }


    // --- Lock Parameter Update Function ---

    // Allows depositor to update *some* parameters on their active lock
    function updateLockConditionParameters(uint256 _lockId, ConditionType _conditionType, bytes memory _newParameters)
        external
        onlyDepositor(_lockId)
        whenNotPaused
    {
        Lock storage lock = locks[_lockId];

        if (lock.status != LockStatus.Active) {
             if (lock.id == 0) revert QuantumVault__LockDoesNotExist();
            revert QuantumVault__WithdrawalAlreadyProcessed();
        }

         // Check if the requested condition type is actually defined for this lock
        bool conditionExists = false;
         for(uint i=0; i < lock.conditionTypes.length; i++) {
            if (lock.conditionTypes[i] == _conditionType) {
                conditionExists = true;
                break;
            }
        }
        if (!conditionExists) {
            revert QuantumVault__ConditionTypeMismatch();
        }


        // Only allow specific, generally beneficial updates by the depositor
        // Owner could have a separate function for more powerful updates (use with caution!)
        if (_conditionType == ConditionType.Timelock) {
             // Allows extending the timelock, but not shortening it past the original
            uint256 newExpiration = abi.decode(_newParameters, (uint256));
             if (newExpiration <= lock.params.timelockExpiration) {
                revert QuantumVault__UpdateNotAllowed(); // Cannot shorten timelock
            }
             lock.params.timelockExpiration = newExpiration;

        } else if (_conditionType == ConditionType.Stake) {
             // Allows increasing the required stake amount
             uint256 newRequiredStake = abi.decode(_newParameters, (uint256));
             if (newRequiredStake <= lock.params.requiredStakeAmount) {
                 revert QuantumVault__UpdateNotAllowed(); // Cannot decrease required stake
             }
             lock.params.requiredStakeAmount = newRequiredStake;

         } else {
             // Disallow updates for other condition types by the depositor
             revert QuantumVault__UpdateNotAllowed();
         }

        emit ConditionParametersUpdated(_lockId, _conditionType);
    }


    // --- Emergency/Admin Functions ---

    function sweepUnsupportedTokens(address _token, address _recipient) external onlyOwner nonReentrant {
        if (_token == address(0)) revert QuantumVault__UnsupportedTokenType(); // Don't sweep ETH via this function
        if (_recipient == address(0)) revert QuantumVault__ZeroAddressDependency();
        if (_token == address(this)) revert QuantumVault__UnsupportedTokenType(); // Cannot sweep contract's own address

        uint256 balance = IERC20(_token).balanceOf(address(this));

        // Optional: Prevent sweeping the main vaulted token(s) if they are configured
        if (_token == address(_stakeToken)) { // Check against configured stake token
             revert QuantumVault__UnsupportedTokenType(); // Cannot sweep primary vault token
        }
        // If vaulting multiple ERC20s, would need a list to check against

        if (balance > 0) {
            if (!IERC20(_token).transfer(_recipient, balance)) {
                 revert ERC20TransferFailed(address(this), _recipient, balance);
            }
            emit UnsupportedTokensSwept(_token, balance, _recipient);
        }
    }

    // Using OpenZeppelin's Ownable transferOwnership
    // function transferOwnership(address newOwner) public virtual override onlyOwner

    // --- Internal Helper Functions ---

    function _createLock(address _tokenAddress, uint256 _amount, ConditionType[] memory _conditionTypes, ConditionParameters memory _params) internal {
        uint256 lockId = _lockIdCounter++;

        // Initialize MultisigData only if Multisig is a condition type
        MultisigData memory multisigData;
        bool requiresMultisig = false;
         for(uint i=0; i < _conditionTypes.length; i++) {
            if (_conditionTypes[i] == ConditionType.Multisig) {
                requiresMultisig = true;
                break;
            }
        }

        if (requiresMultisig) {
             // Deep copy the global signers list
            multisigData.signers = new address[](_globalMultisigSigners.length);
             for(uint i=0; i < _globalMultisigSigners.length; i++) {
                 multisigData.signers[i] = _globalMultisigSigners[i];
             }
             multisigData.threshold = getMultisigConfig().threshold; // Use the current global threshold as the lock's threshold
             multisigData.currentApprovalsCount = 0;
             // approvals mapping is initialized empty by default
        }


        locks[lockId] = Lock({
            id: lockId,
            depositor: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            depositTime: block.timestamp,
            status: LockStatus.Active,
            conditionTypes: _conditionTypes, // Store the array of required condition types
            params: _params,
            multisig: multisigData // Assign the created multisig data (empty if no multisig needed)
        });

        _userLockIds[msg.sender].push(lockId);

        emit LockCreated(lockId, msg.sender, _tokenAddress, _amount, _conditionTypes, block.timestamp);
    }

    // Internal dispatcher to check if *any* condition is met
    function _isConditionMet(uint256 _lockId, ConditionType _conditionType, bytes memory _withdrawalParameters) internal view returns (bool) {
        Lock storage lock = locks[_lockId];

        if (_conditionType == ConditionType.Timelock) {
            return _checkTimelock(lock.params.timelockExpiration);
        } else if (_conditionType == ConditionType.Stake) {
            return _checkStake(lock.depositor, lock.params.requiredStakeAmount);
        } else if (_conditionType == ConditionType.Oracle) {
            // Requires no extra parameters in _withdrawalParameters beyond lock.params
            return _checkOracle(lock.params.requiredOracleValue);
        } else if (_conditionType == ConditionType.Multisig) {
             // Requires no extra parameters in _withdrawalParameters beyond lock.multisig state
            return _checkMultisig(lock.multisig);
        } else if (_conditionType == ConditionType.ZKProof) {
            // Requires passing the proof and public inputs via _withdrawalParameters
             // _withdrawalParameters is expected to be abi.encode(proof, publicInputs)
            (bytes memory proof, bytes memory publicInputs) = abi.decode(_withdrawalParameters, (bytes, bytes));
            return _checkZKProof(lock.params.zkProofIdentifier, proof, publicInputs);
        } else {
            // Should not happen with valid ConditionTypes
            return false;
        }
    }


    function _checkTimelock(uint256 _expirationTimestamp) internal view returns (bool) {
        return block.timestamp >= _expirationTimestamp;
    }

    function _checkStake(address _user, uint256 _requiredAmount) internal view returns (bool) {
        if (address(_stakeToken) == address(0)) return false; // Stake token not configured
        return _stakeToken.balanceOf(_user) >= _requiredAmount;
    }

    function _checkOracle(int256 _requiredValue) internal view returns (bool) {
         if (address(_oracle) == address(0)) return false; // Oracle not configured
        // This is a simple check, a real oracle use case might check ranges, time since last update, etc.
        // Example: Check if the oracle value is exactly the required value.
        // More realistically: check if it's >=, <=, or within a range. Let's assume >= for this example.
        try _oracle.getLatestValue() returns (int256 currentValue) {
            return currentValue >= _requiredValue;
        } catch {
            return false; // Oracle call failed
        }
    }

    function _checkMultisig(MultisigData storage _multisigData) internal view returns (bool) {
        // Check if Multisig condition is validly configured for this lock
         if (_multisigData.threshold == 0 || _multisigData.signers.length < _multisigData.threshold) {
             return false; // Invalid multisig setup for this lock
         }
        return _multisigData.currentApprovalsCount >= _multisigData.threshold;
    }

    function _checkZKProof(bytes32 _proofIdentifier, bytes memory _proof, bytes memory _publicInputs) internal view returns (bool) {
         if (address(_zkVerifier) == address(0)) return false; // ZK Verifier not configured
        // In a real scenario, the verifier contract might have different verification functions
        // based on the proof system or the specific statement being proven.
        // The _proofIdentifier could be used to select the correct verification function.
        // For this example, we call a generic 'verify' function on the configured I_ZKVerifier.
        // A real implementation would likely require a specific ZK verifier contract designed
        // for the proof related to the off-chain condition (e.g., prove knowledge of a secret,
        // prove membership in a set, prove computation output).
        // The structure of _proof and _publicInputs depends entirely on the ZK system used (e.g., Groth16, Plonk).
        try _zkVerifier.verify(_proof, _publicInputs) returns (bool isValid) {
            return isValid;
        } catch {
            return false; // ZK verification call failed or reverted
        }
    }

    function _transferFunds(address _tokenAddress, address _recipient, uint256 _amount) internal {
        if (_tokenAddress == address(0)) { // ETH
            (bool success,) = payable(_recipient).call{value: _amount}("");
            if (!success) {
                revert QuantumVault__ETHTransferFailed();
            }
        } else { // ERC20
            IERC20 token = IERC20(_tokenAddress);
            if (!token.transfer(_recipient, _amount)) {
                 revert ERC20TransferFailed(address(this), _recipient, _amount);
            }
        }
    }

    // --- View Functions ---

    function getLockDetails(uint256 _lockId) external view returns (
        uint256 id,
        address depositor,
        address tokenAddress,
        uint256 amount,
        uint256 depositTime,
        LockStatus status,
        ConditionType[] memory conditionTypes,
        ConditionParameters memory params,
        MultisigData memory multisig
    ) {
        Lock storage lock = locks[_lockId];
        if (lock.id == 0 && _lockId != 0) revert QuantumVault__LockDoesNotExist(); // Check if lock exists (handle ID 0)

         // Deep copy complex structs/arrays for return
         ConditionType[] memory _conditionTypes = new ConditionType[](lock.conditionTypes.length);
         for(uint i=0; i < lock.conditionTypes.length; i++) {
             _conditionTypes[i] = lock.conditionTypes[i];
         }

         MultisigData memory _multisigData;
         _multisigData.signers = new address[](lock.multisig.signers.length);
          for(uint i=0; i < lock.multisig.signers.length; i++) {
              _multisigData.signers[i] = lock.multisig.signers[i];
          }
          _multisigData.threshold = lock.multisig.threshold;
          _multisigData.currentApprovalsCount = lock.multisig.currentApprovalsCount;
          // Note: Mapping approvals cannot be directly returned. Use getMultisigState for that.


        return (
            lock.id,
            lock.depositor,
            lock.tokenAddress,
            lock.amount,
            lock.depositTime,
            lock.status,
            _conditionTypes,
            lock.params, // Simple struct copy is okay
            _multisigData
        );
    }

    function getUserLockIds(address _user) external view returns (uint256[] memory) {
        return _userLockIds[_user];
    }

    function getTotalLockedBalanceETH() external view returns (uint256) {
        return _totalLockedETH;
    }

    function getTotalLockedBalanceTokens(address _tokenAddress) external view returns (uint256) {
         if (_tokenAddress == address(0)) revert QuantumVault__UnsupportedTokenType();
        return _totalLockedTokens[_tokenAddress];
    }

     function getLockConditionTypes(uint256 _lockId) external view returns (ConditionType[] memory) {
         Lock storage lock = locks[_lockId];
         if (lock.id == 0 && _lockId != 0) revert QuantumVault__LockDoesNotExist();

         ConditionType[] memory _conditionTypes = new ConditionType[](lock.conditionTypes.length);
         for(uint i=0; i < lock.conditionTypes.length; i++) {
             _conditionTypes[i] = lock.conditionTypes[i];
         }
         return _conditionTypes;
     }


    function getMultisigState(uint256 _lockId) external view returns (address[] memory signers, uint256 threshold, uint256 currentApprovals, mapping(address => bool) storage approvals) {
        Lock storage lock = locks[_lockId];
        if (lock.id == 0 && _lockId != 0) revert QuantumVault__LockDoesNotExist();

        // Check if Multisig is actually a condition for this lock
        bool isMultisigCondition = false;
         for(uint i=0; i < lock.conditionTypes.length; i++) {
            if (lock.conditionTypes[i] == ConditionType.Multisig) {
                isMultisigCondition = true;
                break;
            }
        }
        if (!isMultisigCondition) {
            revert QuantumVault__ConditionTypeMismatch();
        }

        // Note: Cannot return the mapping directly. The caller would need to query approvals[signerAddress]
        // separately for each signer, or we could return a list/array of (address, bool) pairs.
        // Let's return the state *data* and let the caller query the mapping directly if needed.
         address[] memory _signers = new address[](lock.multisig.signers.length);
         for(uint i=0; i < lock.multisig.signers.length; i++) {
             _signers[i] = lock.multisig.signers[i];
         }

        return (_signers, lock.multisig.threshold, lock.multisig.currentApprovalsCount, lock.multisig.approvals);
    }


    function getMultisigConfig() external view returns (address[] memory signers, uint256 threshold) {
         address[] memory _signers = new address[](_globalMultisigSigners.length);
         for(uint i=0; i < _globalMultisigSigners.length; i++) {
             _signigiers[i] = _globalMultisigSigners[i];
         }
        // The threshold is not stored globally, but the constructor initializes locks with it.
        // Let's return the *configured* threshold that new locks will get. This needs a state variable.
        // Adding a state variable `_defaultMultisigThreshold`.
        return (_signers, 0); // Need to fix this return after adding _defaultMultisigThreshold
    }
    // *Correction*: The global threshold isn't stored. The `setMultisigConfig` sets the signers, and the threshold *for new locks* is derived from that call. Let's add a state var for the default threshold.

    // *Correction 2*: Let's simplify and store the threshold in `_globalMultisigSigners` struct or similar, or just store the signers and threshold globally. Simpler: store both globally.

    // Redefine global multisig state
    address[] private _globalMultisigSigners;
    uint256 private _globalMultisigThreshold;

     // Update constructor & setMultisigConfig to use these:
     /*
     constructor(...) {
         ...
         _globalMultisigSigners = initialMultisigSigners;
         _globalMultisigThreshold = initialMultisigThreshold;
         ...
     }
     function setMultisigConfig(address[] memory signers, uint256 threshold) external onlyOwner {
         ...
         _globalMultisigSigners = signers;
         _globalMultisigThreshold = threshold;
         ...
     }
      function _createLock(...) internal {
          ...
          if (requiresMultisig) {
              ...
              multisigData.threshold = _globalMultisigThreshold; // Use the global threshold
              ...
          }
          ...
      }
     */
     // Now fix the view function:
     function getMultisigConfig() external view returns (address[] memory signers, uint256 threshold) {
         address[] memory _signers = new address[](_globalMultisigSigners.length);
         for(uint i=0; i < _globalMultisigSigners.length; i++) {
             _signers[i] = _globalMultisigSigners[i];
         }
        return (_signers, _globalMultisigThreshold); // Now returns the actual global config
     }


    function getZKVerifierAddress() external view returns (address) {
        return address(_zkVerifier);
    }

    function getOracleAddress() external view returns (address) {
        return address(_oracle);
    }

    function getRequiredStakeTokenAddress() external view returns (address) {
        return address(_stakeToken);
    }

    function isLockActive(uint256 _lockId) external view returns (bool) {
         if (locks[_lockId].id == 0 && _lockId != 0) return false; // Doesn't exist
        return locks[_lockId].status == LockStatus.Active;
    }

     // Helper view to check if a withdraw *could* be attempted (basic status check)
     function canAttemptWithdraw(uint256 _lockId) external view returns (bool) {
         return isLockActive(_lockId) && locks[_lockId].depositor == msg.sender;
     }

    // Internal view to check if an address is a configured global multisig signer
    function _isGlobalMultisigSigner(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < _globalMultisigSigners.length; i++) {
            if (_globalMultisigSigners[i] == _address) {
                return true;
            }
        }
        return false;
    }

     // Additional view function to check a specific signer's approval status for a lock's multisig condition
     function getMultisigSignerApprovalStatus(uint256 _lockId, address _signer) external view returns (bool) {
          Lock storage lock = locks[_lockId];
          if (lock.id == 0 && _lockId != 0) revert QuantumVault__LockDoesNotExist();

          bool isMultisigCondition = false;
           for(uint i=0; i < lock.conditionTypes.length; i++) {
              if (lock.conditionTypes[i] == ConditionType.Multisig) {
                  isMultisigCondition = true;
                  break;
              }
          }
          if (!isMultisigCondition) {
              revert QuantumVault__ConditionTypeMismatch(); // Multisig approval not required for this lock
          }
         if (!_isGlobalMultisigSigner(_signer)) {
             revert QuantumVault__NotMultisigSigner(); // Only configured signers have a status
         }

         return lock.multisig.approvals[_signer];
     }


}
```