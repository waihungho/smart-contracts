Okay, here is a Solidity smart contract (`QuantumVault`) designed with several advanced, creative, and non-standard concepts. It goes beyond simple token transfers or basic vesting by incorporating multi-layered conditional releases, proof-of-knowledge requirements, delegated access with constraints, epoch-based state transitions, and granular control over deposit rules.

This contract is *not* a copy of standard open-source implementations like ERC20, typical vesting contracts, or simple timelocks. It combines several ideas into a unique vault mechanism.

**Disclaimer:** This is a complex contract for educational/demonstration purposes. It contains advanced features that require careful consideration for security, gas costs, and practical off-chain integration (especially for oracle checks and proof generation). Deploying such a contract in production requires thorough auditing.

---

**Outline and Function Summary:**

**Contract Name:** `QuantumVault`

**Core Concept:** A secure vault for Ether and ERC20 tokens where withdrawals are governed by a combination of time locks, required proof-of-knowledge, and external conditional checks, with support for delegated access and administrative overrides.

**State Variables:**
*   `owner`: Contract administrator.
*   `depositCounter`: Counter for unique deposit IDs.
*   `deposits`: Mapping from deposit ID to `Deposit` struct.
*   `isDelegate`: Mapping to track approved delegate addresses.
*   `paused`: Boolean for contract pausing.
*   `currentEpoch`: Counter for state epochs.
*   `epochStartTime`: Timestamp of the current epoch start.

**Structs:**
*   `Deposit`: Holds all information about a single deposit, including depositor, beneficiary, token details, amount, lock time, proof commitment, conditional check hash, and status flags.

**Modifiers:**
*   `onlyOwner`: Restricts function calls to the contract owner.
*   `whenNotPaused`: Prevents execution when the contract is paused.
*   `whenPaused`: Allows execution only when the contract is paused.

**Events:** (For transparency and off-chain monitoring)
*   `Deposited`
*   `Withdrawn`
*   `ProofRevealed`
*   `ConditionalCheckResultUpdated`
*   `OwnerSet`
*   `DelegateStatusUpdated`
*   `DepositLockTimeUpdated`
*   `DepositDelegatedAccessUpdated`
*   `DepositConditionalCheckToggled`
*   `DepositProofRequirementToggled`
*   `EpochStarted`
*   `Paused`
*   `Unpaused`
*   `DepositRightsTransferred`
*   `ConditionalMetForceSet`
*   `ProofRevealedForceSet`
*   `EmergencyWithdrawal`

**Functions (29 Total Callable Functions + Receive):**

**I. Deposit Functions:**
1.  `depositEther(uint256 lockUntil, bytes32 proofHashCommitment, bytes32 conditionalDataHash, address beneficiary)`: Deposit Ether with specific conditions (lock time, proof requirement, conditional check) and set a beneficiary.
2.  `depositERC20(address tokenAddress, uint256 amount, uint256 lockUntil, bytes32 proofHashCommitment, bytes32 conditionalDataHash, address beneficiary)`: Deposit ERC20 tokens (requires prior approval) with specific conditions and set a beneficiary.
3.  `receive() external payable`: Fallback function to receive Ether. *Note: This Ether is not associated with a structured deposit and can only be withdrawn via `ownerWithdrawAll` when paused.*

**II. Withdrawal & Release Mechanism Functions:**
4.  `withdraw(uint256 depositId)`: Allows the `beneficiary` of a deposit to withdraw if all associated conditions (time lock, proof, conditional check) are met and the contract is not paused.
5.  `delegateWithdraw(uint256 depositId)`: Allows an approved `delegate` to withdraw a specific deposit *on behalf of* the beneficiary, provided the deposit explicitly allows delegated withdrawal, all other conditions are met, and the contract is not paused.
6.  `revealProofPreimage(uint256 depositId, bytes32 proofPreimage)`: Allows the depositor or beneficiary to reveal the preimage corresponding to the `proofHashCommitment` for a deposit, marking the proof requirement as met.

**III. Conditional Check & Oracle Interaction Functions:**
7.  `setConditionalCheckResult(uint256 depositId, bool checkResult)`: Allows the `owner` (or an authorized oracle keeper role, if implemented) to update the `isConditionalCheckMet` status for a specific deposit based on external information corresponding to `conditionalDataHash`.
8.  `forceSetConditionalMet(uint256 depositId)`: Owner-only function to force set `isConditionalCheckMet` to `true`, bypassing the normal oracle update (emergency/override).
9.  `forceSetProofRevealed(uint256 depositId)`: Owner-only function to force set `isProofRevealed` to `true`, bypassing the normal preimage reveal (emergency/override).

**IV. Administrative & Configuration Functions (Owner Only):**
10. `setOwner(address newOwner)`: Transfers ownership of the contract.
11. `addDelegate(address delegate)`: Grants an address delegate status, allowing them to call `delegateWithdraw` for eligible deposits.
12. `removeDelegate(address delegate)`: Revokes delegate status.
13. `updateDepositLockTime(uint256 depositId, uint256 newLockUntil)`: Updates the `lockUntil` time for a deposit. Can only extend the time or set a time in the future if currently unlocked. Cannot shorten if still locked.
14. `allowDelegatedWithdrawalOnDeposit(uint256 depositId, bool allowed)`: Toggles the `allowDelegatedWithdrawal` flag for a specific deposit.
15. `enableConditionalCheck(uint256 depositId, bool required)`: Toggles the `conditionalCheckRequired` flag for a specific deposit.
16. `enableProofRequirement(uint256 depositId, bool required)`: Toggles the `proofRequirementRequired` flag for a specific deposit.
17. `pause()`: Pauses the contract, blocking most functions.
18. `unpause()`: Unpauses the contract.
19. `ownerWithdrawAll(address tokenAddress)`: Allows the owner to withdraw all of a specific token (or Ether) from the contract *only when the contract is paused*. This is intended as an emergency or upgrade mechanism.

**V. State Transition & Management Functions:**
20. `startNewEpoch()`: Increments the `currentEpoch` counter and updates `epochStartTime`. Can potentially be used to trigger epoch-dependent logic (though not fully implemented beyond state update in this version).

**VI. Utility & View Functions:**
21. `canWithdraw(uint256 depositId)`: Public view function to check if a specific deposit meets *all* withdrawal conditions *except* checking the caller's address (beneficiary/delegate status).
22. `getDepositDetails(uint256 depositId)`: Public view function to retrieve all details of a specific deposit.
23. `getDepositCount()`: Public view function returning the total number of deposits created.
24. `isAddressDelegate(address account)`: Public view function to check if an address is currently an approved delegate.
25. `getContractTokenBalance(address tokenAddress)`: Public view function to get the contract's balance of a specific ERC20 token, or Ether balance for address 0.
26. `getEpochInfo()`: Public view function returning the current epoch number and its start time.
27. `checkProofCommitment(bytes32 commitment, bytes32 preimage)`: Pure utility function to check if a given `preimage` hashes to the provided `commitment` using `keccak256`.
28. `transferDepositRights(uint256 depositId, address newBeneficiary)`: Allows the current beneficiary/depositor to transfer the rights to a deposit (change beneficiary) *before* the conditions for withdrawal are met. Cannot transfer if already withdrawn.
29. `getOwner()`: Public view function to get the current owner address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title QuantumVault
 * @dev A complex and conditional vault for Ether and ERC20 tokens.
 * Funds can be deposited with layered conditions for withdrawal, including time locks,
 * proof-of-knowledge requirements, and external conditional checks managed via oracle/keeper.
 * Features include delegated access, administrative overrides, epoch-based state,
 * and granular control over deposit conditions.
 *
 * Outline and Function Summary:
 *
 * State Variables:
 * - owner: Contract administrator.
 * - depositCounter: Counter for unique deposit IDs.
 * - deposits: Mapping from deposit ID to Deposit struct.
 * - isDelegate: Mapping to track approved delegate addresses.
 * - paused: Boolean for contract pausing.
 * - currentEpoch: Counter for state epochs.
 * - epochStartTime: Timestamp of the current epoch start.
 *
 * Structs:
 * - Deposit: Holds all information about a single deposit.
 *
 * Modifiers:
 * - onlyOwner: Restricts calls to the owner.
 * - whenNotPaused: Prevents calls when paused.
 * - whenPaused: Allows calls only when paused.
 *
 * Events:
 * - Deposits, withdrawals, state changes, admin actions, etc.
 *
 * Functions (29 total callable + receive):
 * I. Deposit Functions (2):
 * 1. depositEther: Deposit ETH with conditions and beneficiary.
 * 2. depositERC20: Deposit ERC20 with conditions and beneficiary (requires approval).
 * 3. receive: Fallback for unsolicited ETH. Note: Not managed as a structured deposit.
 *
 * II. Withdrawal & Release Mechanisms (3):
 * 4. withdraw: Beneficiary initiates withdrawal if conditions met & not paused.
 * 5. delegateWithdraw: Delegate initiates withdrawal if allowed, conditions met & not paused.
 * 6. revealProofPreimage: Provide preimage to satisfy proof requirement.
 *
 * III. Conditional Check & Oracle Interaction (3):
 * 7. setConditionalCheckResult: Owner/Keeper updates external condition status.
 * 8. forceSetConditionalMet: Owner override for conditional check.
 * 9. forceSetProofRevealed: Owner override for proof requirement.
 *
 * IV. Administrative & Configuration (Owner Only) (10):
 * 10. setOwner: Transfer ownership.
 * 11. addDelegate: Grant delegate status.
 * 12. removeDelegate: Revoke delegate status.
 * 13. updateDepositLockTime: Modify deposit lock time (extend only).
 * 14. allowDelegatedWithdrawalOnDeposit: Toggle delegate permission per deposit.
 * 15. enableConditionalCheck: Toggle conditional check requirement per deposit.
 * 16. enableProofRequirement: Toggle proof requirement per deposit.
 * 17. pause: Pause contract operations.
 * 18. unpause: Unpause contract operations.
 * 19. ownerWithdrawAll: Emergency withdrawal of all funds when paused.
 *
 * V. State Transition & Management (1):
 * 20. startNewEpoch: Advance the contract epoch.
 *
 * VI. Utility & View Functions (9):
 * 21. canWithdraw: Check if a deposit meets withdrawal conditions (excluding caller check).
 * 22. getDepositDetails: Retrieve details of a specific deposit.
 * 23. getDepositCount: Get total number of deposits created.
 * 24. isAddressDelegate: Check if address is a delegate.
 * 25. getContractTokenBalance: Get contract's balance for a token or ETH.
 * 26. getEpochInfo: Get current epoch and start time.
 * 27. checkProofCommitment: Pure function to verify proof preimage.
 * 28. transferDepositRights: Transfer beneficiary rights for a deposit.
 * 29. getOwner: Get current owner address.
 */
contract QuantumVault is ReentrancyGuard {

    address public owner;
    uint256 public depositCounter;

    struct Deposit {
        address depositor;            // Address that made the deposit
        address beneficiary;          // Address authorized to withdraw (normally)
        address tokenAddress;         // Address of the ERC20 token (0x0 for Ether)
        uint256 amount;               // Amount deposited
        uint256 lockUntil;            // Timestamp when the time lock expires (0 means no time lock)
        bytes32 proofHashCommitment;  // Hash commitment for a required proof (bytes32(0) means no proof required)
        bytes32 conditionalDataHash;  // Hash representing external condition data (bytes32(0) means no external condition)
        bool conditionalCheckRequired; // Is the external condition check required?
        bool isConditionalCheckMet;    // Has the external condition been met? (Set by oracle/keeper)
        bool proofRequirementRequired; // Is the proof reveal required?
        bool isProofRevealed;          // Has the proof been successfully revealed?
        bool allowDelegatedWithdrawal; // Can a delegate withdraw this specific deposit?
        bool isWithdrawn;              // Has the deposit been withdrawn?
    }

    mapping(uint256 => Deposit) public deposits;
    mapping(address => bool) public isDelegate;

    bool public paused;
    uint256 public currentEpoch;
    uint256 public epochStartTime;

    // --- Events ---
    event Deposited(uint256 indexed depositId, address indexed depositor, address indexed beneficiary, address tokenAddress, uint256 amount, uint256 lockUntil, bytes32 proofHashCommitment, bytes32 conditionalDataHash);
    event Withdrawn(uint256 indexed depositId, address indexed beneficiary, address indexed receiver, address tokenAddress, uint256 amount);
    event ProofRevealed(uint256 indexed depositId, address indexed revealer);
    event ConditionalCheckResultUpdated(uint256 indexed depositId, bool result, address indexed updater);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event DelegateStatusUpdated(address indexed delegate, bool isNowDelegate);
    event DepositLockTimeUpdated(uint256 indexed depositId, uint256 indexed newLockUntil, address indexed updater);
    event DepositDelegatedAccessUpdated(uint256 indexed depositId, bool indexed allowed, address indexed updater);
    event DepositConditionalCheckToggled(uint256 indexed depositId, bool indexed required, address indexed toggler);
    event DepositProofRequirementToggled(uint256 indexed depositId, bool indexed required, address indexed toggler);
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event Paused(address account);
    event Unpaused(address account);
    event DepositRightsTransferred(uint256 indexed depositId, address indexed oldBeneficiary, address indexed newBeneficiary, address indexed transferrer);
    event ConditionalMetForceSet(uint256 indexed depositId, address indexed operator);
    event ProofRevealedForceSet(uint256 indexed depositId, address indexed operator);
    event EmergencyWithdrawal(address indexed tokenAddress, uint256 amount, address indexed recipient);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
        depositCounter = 0;
        currentEpoch = 1;
        epochStartTime = block.timestamp;
        emit OwnerSet(address(0), owner);
        emit EpochStarted(currentEpoch, epochStartTime);
    }

    // --- Receive Ether Function ---
    /**
     * @dev Fallback function to receive Ether. Note: Ether sent directly
     * via this function is NOT tracked as a structured deposit and can only
     * be withdrawn by the owner using `ownerWithdrawAll` when paused.
     * This is generally discouraged for managed funds.
     */
    receive() external payable {
        // You could add a requirement here if you strictly only want deposits via depositEther
        // require(false, "Use depositEther function for structured deposits");
        // Or allow it but with the understanding it's 'unaccounted'
    }

    // --- I. Deposit Functions ---

    /**
     * @dev Deposits Ether into the vault with specified conditions and beneficiary.
     * @param lockUntil Timestamp until which withdrawal is locked (0 for no time lock).
     * @param proofHashCommitment Keccak256 hash of a preimage that must be revealed to withdraw (bytes32(0) for no proof).
     * @param conditionalDataHash Hash representing external data/conditions to be checked (bytes32(0) for no external condition).
     * @param beneficiary The address authorized to withdraw the deposit if conditions are met.
     */
    function depositEther(
        uint256 lockUntil,
        bytes32 proofHashCommitment,
        bytes32 conditionalDataHash,
        address beneficiary
    ) external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(beneficiary != address(0), "Beneficiary cannot be the zero address");

        depositCounter++;
        uint256 currentDepositId = depositCounter;

        bool requireConditional = (conditionalDataHash != bytes32(0));
        bool requireProof = (proofHashCommitment != bytes32(0));

        deposits[currentDepositId] = Deposit({
            depositor: msg.sender,
            beneficiary: beneficiary,
            tokenAddress: address(0), // Represents Ether
            amount: msg.value,
            lockUntil: lockUntil,
            proofHashCommitment: proofHashCommitment,
            conditionalDataHash: conditionalDataHash,
            conditionalCheckRequired: requireConditional,
            isConditionalCheckMet: !requireConditional, // Auto-met if not required
            proofRequirementRequired: requireProof,
            isProofRevealed: !requireProof, // Auto-revealed if not required
            allowDelegatedWithdrawal: false, // Default to false
            isWithdrawn: false
        });

        emit Deposited(
            currentDepositId,
            msg.sender,
            beneficiary,
            address(0),
            msg.value,
            lockUntil,
            proofHashCommitment,
            conditionalDataHash
        );
    }

    /**
     * @dev Deposits ERC20 tokens into the vault with specified conditions and beneficiary.
     * Requires the sender to have approved this contract to spend `amount` tokens beforehand.
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of tokens to deposit.
     * @param lockUntil Timestamp until which withdrawal is locked (0 for no time lock).
     * @param proofHashCommitment Keccak256 hash of a preimage that must be revealed to withdraw (bytes32(0) for no proof).
     * @param conditionalDataHash Hash representing external data/conditions to be checked (bytes32(0) for no external condition).
     * @param beneficiary The address authorized to withdraw the deposit if conditions are met.
     */
    function depositERC20(
        address tokenAddress,
        uint256 amount,
        uint256 lockUntil,
        bytes32 proofHashCommitment,
        bytes32 conditionalDataHash,
        address beneficiary
    ) external whenNotPaused nonReentrant {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(amount > 0, "Deposit amount must be greater than 0");
        require(beneficiary != address(0), "Beneficiary cannot be the zero address");

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);

        depositCounter++;
        uint256 currentDepositId = depositCounter;

        bool requireConditional = (conditionalDataHash != bytes32(0));
        bool requireProof = (proofHashCommitment != bytes32(0));

        deposits[currentDepositId] = Deposit({
            depositor: msg.sender,
            beneficiary: beneficiary,
            tokenAddress: tokenAddress,
            amount: amount,
            lockUntil: lockUntil,
            proofHashCommitment: proofHashCommitment,
            conditionalDataHash: conditionalDataHash,
            conditionalCheckRequired: requireConditional,
            isConditionalCheckMet: !requireConditional, // Auto-met if not required
            proofRequirementRequired: requireProof,
            isProofRevealed: !requireProof, // Auto-revealed if not required
            allowDelegatedWithdrawal: false, // Default to false
            isWithdrawn: false
        });

        emit Deposited(
            currentDepositId,
            msg.sender,
            beneficiary,
            tokenAddress,
            amount,
            lockUntil,
            proofHashCommitment,
            conditionalDataHash
        );
    }

    // --- II. Withdrawal & Release Mechanism Functions ---

    /**
     * @dev Allows the beneficiary to withdraw a deposit if all conditions are met.
     * Conditions checked: not withdrawn, time lock expired, proof revealed (if required),
     * conditional check met (if required), and contract not paused.
     * @param depositId The ID of the deposit to withdraw.
     */
    function withdraw(uint256 depositId) external nonReentrant whenNotPaused {
        Deposit storage deposit = deposits[depositId];

        require(deposit.beneficiary == msg.sender, "Only the beneficiary can withdraw");
        require(deposit.amount > 0, "Deposit does not exist or amount is zero"); // Checks existence implicitly
        require(!deposit.isWithdrawn, "Deposit already withdrawn");
        require(canWithdraw(depositId), "Withdrawal conditions not met");

        deposit.isWithdrawn = true;

        if (deposit.tokenAddress == address(0)) {
            // Ether withdrawal
            (bool success, ) = payable(deposit.beneficiary).call{value: deposit.amount}("");
            require(success, "Ether withdrawal failed");
        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(deposit.tokenAddress);
            token.transfer(deposit.beneficiary, deposit.amount);
        }

        emit Withdrawn(depositId, deposit.beneficiary, deposit.beneficiary, deposit.tokenAddress, deposit.amount);
    }

    /**
     * @dev Allows an approved delegate to withdraw a deposit on behalf of the beneficiary,
     * provided the specific deposit allows delegation and all other conditions are met.
     * Conditions checked: sender is a delegate, deposit allows delegation, not withdrawn,
     * time lock expired, proof revealed (if required), conditional check met (if required),
     * and contract not paused.
     * @param depositId The ID of the deposit to withdraw.
     */
    function delegateWithdraw(uint256 depositId) external nonReentrant whenNotPaused {
        Deposit storage deposit = deposits[depositId];

        require(isDelegate[msg.sender], "Caller is not an authorized delegate");
        require(deposit.allowDelegatedWithdrawal, "Delegated withdrawal not allowed for this deposit");
        require(deposit.amount > 0, "Deposit does not exist or amount is zero"); // Checks existence implicitly
        require(!deposit.isWithdrawn, "Deposit already withdrawn");
        require(canWithdraw(depositId), "Withdrawal conditions not met");

        deposit.isWithdrawn = true;

        if (deposit.tokenAddress == address(0)) {
            // Ether withdrawal
            (bool success, ) = payable(deposit.beneficiary).call{value: deposit.amount}("");
            require(success, "Ether withdrawal failed");
        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(deposit.tokenAddress);
            token.transfer(deposit.beneficiary, deposit.amount);
        }

        emit Withdrawn(depositId, deposit.beneficiary, msg.sender, deposit.tokenAddress, deposit.amount);
    }

    /**
     * @dev Allows the depositor or beneficiary to reveal the preimage for a required proof.
     * This satisfies the `proofRequirementRequired` condition if the hash matches.
     * @param depositId The ID of the deposit.
     * @param proofPreimage The preimage string/bytes that should hash to the commitment.
     */
    function revealProofPreimage(uint256 depositId, bytes32 proofPreimage) external whenNotPaused {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(deposit.proofRequirementRequired, "Proof reveal is not required for this deposit");
        require(!deposit.isProofRevealed, "Proof already revealed");
        require(msg.sender == deposit.beneficiary || msg.sender == deposit.depositor, "Only beneficiary or depositor can reveal proof");

        // Check if the revealed preimage matches the commitment
        require(keccak256(abi.encodePacked(proofPreimage)) == deposit.proofHashCommitment, "Proof preimage does not match commitment");

        deposit.isProofRevealed = true;
        emit ProofRevealed(depositId, msg.sender);
    }

    // --- III. Conditional Check & Oracle Interaction Functions ---

    /**
     * @dev Allows the owner (or an authorized oracle keeper) to set the result of an external condition check.
     * This satisfies the `conditionalCheckRequired` condition if `checkResult` is true.
     * Assumes the `conditionalDataHash` provided during deposit represents the data/condition being checked.
     * @param depositId The ID of the deposit.
     * @param checkResult The boolean result of the external condition check.
     */
    function setConditionalCheckResult(uint256 depositId, bool checkResult) external onlyOwner whenNotPaused {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(deposit.conditionalCheckRequired, "Conditional check not required for this deposit");
        require(!deposit.isConditionalCheckMet, "Conditional check result already set");
        // Note: This function doesn't *verify* the condition using `conditionalDataHash`.
        // It relies on the owner/keeper to have done that off-chain.

        deposit.isConditionalCheckMet = checkResult;
        emit ConditionalCheckResultUpdated(depositId, checkResult, msg.sender);
    }

    /**
     * @dev Owner override to force set the conditional check status to true.
     * Use with caution, primarily for emergencies like oracle failures.
     * @param depositId The ID of the deposit.
     */
    function forceSetConditionalMet(uint256 depositId) external onlyOwner whenNotPaused {
         Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isConditionalCheckMet, "Conditional check already met");

        deposit.isConditionalCheckMet = true;
        emit ConditionalMetForceSet(depositId, msg.sender);
    }

    /**
     * @dev Owner override to force set the proof revealed status to true.
     * Use with caution, primarily for emergencies like lost preimages.
     * @param depositId The ID of the deposit.
     */
    function forceSetProofRevealed(uint256 depositId) external onlyOwner whenNotPaused {
         Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isProofRevealed, "Proof already revealed");

        deposit.isProofRevealed = true;
        emit ProofRevealedForceSet(depositId, msg.sender);
    }


    // --- IV. Administrative & Configuration Functions (Owner Only) ---

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerSet(oldOwner, newOwner);
    }

    /**
     * @dev Grants delegate status to an address. Delegates can call `delegateWithdraw`
     * for deposits where `allowDelegatedWithdrawal` is true.
     * @param delegate The address to add as a delegate.
     */
    function addDelegate(address delegate) external onlyOwner {
        require(delegate != address(0), "Delegate address cannot be zero");
        require(!isDelegate[delegate], "Address is already a delegate");
        isDelegate[delegate] = true;
        emit DelegateStatusUpdated(delegate, true);
    }

    /**
     * @dev Revokes delegate status from an address.
     * @param delegate The address to remove as a delegate.
     */
    function removeDelegate(address delegate) external onlyOwner {
        require(isDelegate[delegate], "Address is not a delegate");
        isDelegate[delegate] = false;
        emit DelegateStatusUpdated(delegate, false);
    }

    /**
     * @dev Updates the lockUntil time for a deposit. Can only extend the lock time,
     * or set a future lock time if currently unlocked. Cannot shorten if still locked.
     * @param depositId The ID of the deposit.
     * @param newLockUntil The new timestamp for the lock expiry.
     */
    function updateDepositLockTime(uint256 depositId, uint256 newLockUntil) external onlyOwner {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isWithdrawn, "Cannot update lock time for a withdrawn deposit");

        // Cannot shorten the lock time if it's still locked
        require(newLockUntil >= deposit.lockUntil || block.timestamp >= deposit.lockUntil,
                "Cannot shorten lock time or set it in the past if currently locked");

        deposit.lockUntil = newLockUntil;
        emit DepositLockTimeUpdated(depositId, newLockUntil, msg.sender);
    }

    /**
     * @dev Toggles whether delegated withdrawal is allowed for a specific deposit.
     * @param depositId The ID of the deposit.
     * @param allowed Boolean indicating if delegated withdrawal should be allowed.
     */
    function allowDelegatedWithdrawalOnDeposit(uint256 depositId, bool allowed) external onlyOwner {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isWithdrawn, "Cannot update delegation status for a withdrawn deposit");

        deposit.allowDelegatedWithdrawal = allowed;
        emit DepositDelegatedAccessUpdated(depositId, allowed, msg.sender);
    }

    /**
     * @dev Toggles whether the external conditional check is required for a specific deposit.
     * If set to false while required, `isConditionalCheckMet` is automatically set to true.
     * @param depositId The ID of the deposit.
     * @param required Boolean indicating if the conditional check should be required.
     */
    function enableConditionalCheck(uint256 depositId, bool required) external onlyOwner {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isWithdrawn, "Cannot update check requirement for a withdrawn deposit");

        deposit.conditionalCheckRequired = required;
        if (!required) {
             deposit.isConditionalCheckMet = true; // Auto-met if no longer required
        }
        emit DepositConditionalCheckToggled(depositId, required, msg.sender);
    }

    /**
     * @dev Toggles whether the proof reveal is required for a specific deposit.
     * If set to false while required, `isProofRevealed` is automatically set to true.
     * @param depositId The ID of the deposit.
     * @param required Boolean indicating if the proof reveal should be required.
     */
    function enableProofRequirement(uint256 depositId, bool required) external onlyOwner {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isWithdrawn, "Cannot update proof requirement for a withdrawn deposit");

        deposit.proofRequirementRequired = required;
        if (!required) {
             deposit.isProofRevealed = true; // Auto-revealed if no longer required
        }
        emit DepositProofRequirementToggled(depositId, required, msg.sender);
    }

    /**
     * @dev Pauses contract operations. Blocks most functions.
     * Can only be called by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses contract operations.
     * Can only be called by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw all of a specific token (or Ether) from the contract.
     * This is intended as an emergency or upgrade mechanism and is only callable when the contract is paused.
     * This will withdraw *all* tokens/Ether of that type, including any that might be part of structured deposits.
     * Use with extreme caution.
     * @param tokenAddress Address of the token to withdraw (0x0 for Ether).
     */
    function ownerWithdrawAll(address tokenAddress) external onlyOwner whenPaused nonReentrant {
        uint256 balance;
        if (tokenAddress == address(0)) {
            balance = address(this).balance;
            (bool success, ) = payable(owner).call{value: balance}("");
            require(success, "Emergency Ether withdrawal failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            balance = token.balanceOf(address(this));
            token.transfer(owner, balance);
        }
        emit EmergencyWithdrawal(tokenAddress, balance, owner);
    }


    // --- V. State Transition & Management Functions ---

    /**
     * @dev Increments the epoch counter and updates the start time.
     * Can be used to signal logical periods within the contract's lifecycle.
     * Could be extended with epoch-specific rules or data snapshots.
     */
    function startNewEpoch() external onlyOwner {
        currentEpoch++;
        epochStartTime = block.timestamp;
        emit EpochStarted(currentEpoch, epochStartTime);
    }


    // --- VI. Utility & View Functions ---

    /**
     * @dev Checks if a specific deposit meets all the conditions required for withdrawal.
     * This function does NOT check if the caller is the beneficiary or a delegate.
     * It's useful for off-chain clients or other contracts to query withdrawal eligibility.
     * Conditions checked: not withdrawn, time lock expired, proof revealed (if required),
     * conditional check met (if required).
     * @param depositId The ID of the deposit to check.
     * @return bool True if all conditions are met, false otherwise.
     */
    function canWithdraw(uint256 depositId) public view returns (bool) {
        Deposit storage deposit = deposits[depositId];

        // Basic check for deposit existence and status
        if (deposit.amount == 0 || deposit.isWithdrawn) {
            return false;
        }

        // Check Time Lock
        if (deposit.lockUntil > 0 && block.timestamp < deposit.lockUntil) {
            return false;
        }

        // Check Proof Requirement
        if (deposit.proofRequirementRequired && !deposit.isProofRevealed) {
            return false;
        }

        // Check Conditional Requirement
        if (deposit.conditionalCheckRequired && !deposit.isConditionalCheckMet) {
            return false;
        }

        // If all checks pass, withdrawal is possible (pending caller authorization)
        return true;
    }

    /**
     * @dev Retrieves all details for a specific deposit.
     * @param depositId The ID of the deposit.
     * @return Deposit Struct containing all deposit information.
     */
    function getDepositDetails(uint256 depositId) external view returns (Deposit memory) {
        // No require here, will return default struct if depositId doesn't exist
        // Caller needs to check returned struct's amount > 0 for validity
        return deposits[depositId];
    }

    /**
     * @dev Returns the total number of deposits that have been created.
     * Note: This is a counter, not the number of *active* deposits.
     * @return uint256 The total deposit count.
     */
    function getDepositCount() external view returns (uint256) {
        return depositCounter;
    }

    /**
     * @dev Checks if an address is currently marked as an authorized delegate.
     * @param account The address to check.
     * @return bool True if the address is a delegate, false otherwise.
     */
    function isAddressDelegate(address account) external view returns (bool) {
        return isDelegate[account];
    }

    /**
     * @dev Returns the contract's current balance of a specific token or Ether.
     * @param tokenAddress Address of the token (0x0 for Ether).
     * @return uint256 The balance.
     */
    function getContractTokenBalance(address tokenAddress) external view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            IERC20 token = IERC20(tokenAddress);
            return token.balanceOf(address(this));
        }
    }

     /**
      * @dev Returns the current epoch information.
      * @return uint256 epoch ID.
      * @return uint256 timestamp when the epoch started.
      */
    function getEpochInfo() external view returns (uint256, uint256) {
        return (currentEpoch, epochStartTime);
    }

    /**
     * @dev Pure function to verify if a preimage hashes to a given commitment.
     * Useful for off-chain tools to check against the stored `proofHashCommitment`.
     * @param commitment The hash commitment.
     * @param preimage The potential preimage.
     * @return bool True if keccak256(abi.encodePacked(preimage)) matches commitment.
     */
    function checkProofCommitment(bytes32 commitment, bytes32 preimage) external pure returns (bool) {
        return keccak256(abi.encodePacked(preimage)) == commitment;
    }

    /**
     * @dev Allows the current beneficiary (or depositor if no beneficiary set) to transfer
     * the rights to a deposit to a new beneficiary.
     * Can only be done if the deposit has not been withdrawn.
     * @param depositId The ID of the deposit.
     * @param newBeneficiary The address of the new beneficiary.
     */
    function transferDepositRights(uint256 depositId, address newBeneficiary) external whenNotPaused {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "Deposit does not exist");
        require(!deposit.isWithdrawn, "Deposit has already been withdrawn");
        require(newBeneficiary != address(0), "New beneficiary cannot be the zero address");
        require(msg.sender == deposit.beneficiary || (deposit.beneficiary == address(0) && msg.sender == deposit.depositor),
                "Only the current beneficiary or depositor can transfer rights");
        require(newBeneficiary != deposit.beneficiary, "New beneficiary is already the current beneficiary");

        address oldBeneficiary = deposit.beneficiary;
        deposit.beneficiary = newBeneficiary;
        emit DepositRightsTransferred(depositId, oldBeneficiary, newBeneficiary, msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}
```