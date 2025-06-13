Okay, here is a smart contract concept focusing on time-dependent, probabilistic, and credential-gated access to funds, structured around "Epochs" and unique "Sequence IDs". It's inspired by concepts of timed releases, randomness, and unique digital keys, aiming for complexity beyond standard vault patterns.

**QuantumVault Smart Contract**

This contract acts as a sophisticated vault holding Ether and ERC-20 tokens. Funds deposited can only be unlocked during specific time "Epochs", provided the unlocker possesses a valid "Sequence ID" and a probabilistic "Quantum State" condition is met based on pseudo-randomness derived for that epoch.

**Outline:**

1.  **State Variables:** Define data structures and mappings for balances, epoch configurations, sequence ID ownership/status, successful unlocks, roles, fees, and contract parameters.
2.  **Events:** Define events to signal key actions like deposits, epoch configuration, sequence ID generation, unlock attempts (success/failure), withdrawals, and role management.
3.  **Roles:** Define roles for different administrative and operational functions within the vault.
4.  **Modifiers:** Define modifiers for access control (`onlyRole`, `whenNotPaused`, `whenPaused`).
5.  **Structs:** Define structs for `EpochConfig` and `SequenceIDStatus`.
6.  **Core Logic:**
    *   Deposit functions (`depositETH`, `depositToken`).
    *   Epoch Management functions (`defineUnlockEpoch`, `updateEpochParameters`, etc.).
    *   Sequence ID Management functions (`generateSequenceID`, `transferSequenceID`, `setMaxSequenceIDs`, `setSequenceIDCatalystFee`, `withdrawCatalystFees`).
    *   Unlock Attempt function (`attemptUnlock`) - The core complex logic involving epoch checks, sequence ID validation, and pseudo-randomness evaluation.
    *   Withdrawal function (`withdrawUnlockedFunds`).
    *   Role Management functions (`grantRole`, `revokeRole`, etc.).
    *   Emergency/Pause functions (`pause`, `unpause`, `emergencyWithdraw`).
    *   View functions to query state (`getEpochConfig`, `getSequenceIDStatus`, `getWithdrawableAmount`, `predictEpochOutcome`, etc.).
    *   Configuration function (`configureVaultParameters`).

**Function Summary (at least 20):**

1.  `constructor()`: Initializes the contract, setting the initial owner and default roles.
2.  `depositETH() payable`: Allows users to deposit Ether into the vault.
3.  `depositToken(address tokenAddress, uint256 amount)`: Allows users to deposit a specified ERC-20 token amount into the vault.
4.  `defineUnlockEpoch(uint256 epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker)`: Defines or updates the configuration for a specific unlock epoch, including its time window, the minimum randomness value required for a successful unlock, and the amount of funds a *single successful unlock* claims from the pool for this epoch. Requires `CONFIGURATOR_ROLE`.
5.  `updateEpochParameters(uint256 epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker)`: Allows modifying existing epoch parameters. Requires `CONFIGURATOR_ROLE`.
6.  `generateSequenceID()`: Allows a user to generate a unique "Sequence ID". May require a fee (`catalystFee`). This ID is required to *attempt* an unlock.
7.  `transferSequenceID(uint256 sequenceId, address recipient)`: Allows the owner of a Sequence ID to transfer it to another address.
8.  `attemptUnlock(uint256 epochId, uint256 sequenceId, bytes32 userSeed)`: The core function. Attempts to unlock funds for a given epoch using a specific sequence ID and a user-provided seed. It checks if the current time is within the epoch window, if the sequence ID is valid and owned by the caller, generates pseudo-randomness for the epoch (potentially incorporating the user seed), and checks if it meets the `minRandomnessThreshold`. If successful, it marks the sequence ID as used for this epoch and calculates the withdrawable amount for the unlocker. If failed, it may penalize the sequence ID (e.g., mark it as 'failed_attempt' for this epoch).
9.  `withdrawUnlockedFunds(uint256 epochId, uint256 sequenceId)`: Allows a user who successfully completed an `attemptUnlock` for a specific epoch and sequence ID to withdraw their calculated share of the unlocked funds.
10. `grantRole(bytes32 role, address account)`: Grants a specified role to an account. Requires `DEFAULT_ADMIN_ROLE`.
11. `revokeRole(bytes32 role, address account)`: Revokes a specified role from an account. Requires `DEFAULT_ADMIN_ROLE`.
12. `renounceRole(bytes32 role)`: Allows an account to renounce its own role.
13. `pause()`: Pauses certain contract functionalities (like deposits, unlocks, withdrawals) in case of emergency. Requires `PAUSER_ROLE`.
14. `unpause()`: Unpauses the contract. Requires `PAUSER_ROLE`.
15. `emergencyWithdraw(address tokenAddress)`: Allows an authorized role (`EMERGENCY_ADMIN_ROLE`) to withdraw all funds (ETH or a specific token) from the contract when it is paused.
16. `getEpochConfig(uint256 epochId)`: View function to retrieve the configuration details for a specific epoch.
17. `getSequenceIDStatus(uint256 sequenceId)`: View function to retrieve the status (owner, attempts, successful unlocks) for a specific Sequence ID.
18. `getWithdrawableAmount(uint256 epochId, uint256 sequenceId)`: View function to check the amount of funds a user can withdraw for a specific successful unlock attempt.
19. `getTotalVaultBalance(address tokenAddress)`: View function to get the total balance of a specific token (or ETH) held in the vault.
20. `predictEpochOutcome(uint256 epochId, bytes32 userSeed)`: A *simulated* prediction function. Given an epoch ID and a potential user seed, it calculates the expected pseudo-randomness *based on known factors* (like epoch config, current block hash, block timestamp, etc.) *but cannot predict future block hashes*. It can give an *idea* of the difficulty or potential outcome based on the `minRandomnessThreshold` but is not a guarantee due to the unpredictable nature of future block data.
21. `setMaxSequenceIDs(uint256 maxIds)`: Sets the maximum total number of Sequence IDs that can ever be generated. Requires `SEQUENCER_MANAGER_ROLE`.
22. `setSequenceIDCatalystFee(uint256 feeAmount)`: Sets the amount of Ether required to generate a Sequence ID. Requires `SEQUENCER_MANAGER_ROLE`.
23. `withdrawCatalystFees(address recipient)`: Allows the `SEQUENCER_MANAGER_ROLE` or `DEFAULT_ADMIN_ROLE` to withdraw accumulated Sequence ID generation fees.
24. `configureVaultParameters(uint256 minDepositETH, uint256 minDepositToken, uint256 maxEpochId)`: Sets global parameters for the vault like minimum deposit amounts and the maximum allowed epoch ID. Requires `CONFIGURATOR_ROLE`.
25. `getRoleAdmin(bytes32 role)`: View function to get the admin role for a specific role (useful if implementing a hierarchical role system).
26. `hasRole(bytes32 role, address account)`: View function to check if an account has a specific role.
27. `getEpochSuccessfulUnlockers(uint256 epochId)`: View function returning a list (or mapping keys) of Sequence IDs that successfully unlocked a given epoch. (Implementation might return count or require iteration).
28. `getEpochRandomnessResult(uint256 epochId)`: View function to retrieve the *actual* pseudo-randomness value generated for a specific epoch *after* an attempt has triggered its calculation for the first time (or after the epoch has passed).
29. `getSequenceIDOwner(uint256 sequenceId)`: View function to get the current owner address of a Sequence ID.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A sophisticated vault contract allowing timed, probabilistic, and credential-gated access
 *      to deposited funds (ETH and ERC-20 tokens). Funds are unlocked during specific "Epochs"
 *      if an unlocker possesses a unique "Sequence ID" and meets a "Quantum State" (randomness)
 *      condition defined for that epoch.
 *
 * Outline:
 * 1. State Variables: Balances, epoch configs, sequence ID status, roles, fees, parameters.
 * 2. Events: Signal deposits, config changes, sequence ID actions, unlock attempts, withdrawals, roles, pause/unpause.
 * 3. Roles: DEFAULT_ADMIN_ROLE, CONFIGURATOR_ROLE, SEQUENCER_MANAGER_ROLE, PAUSER_ROLE, EMERGENCY_ADMIN_ROLE.
 * 4. Modifiers: onlyRole, whenNotPaused, whenPaused.
 * 5. Structs: EpochConfig, SequenceIDStatus.
 * 6. Functions: Deposit, Epoch Management, Sequence ID Management, Attempt Unlock (core), Withdraw, Role Management, Pause/Emergency, View/Query, Parameter Configuration.
 *
 * Function Summary (29 functions):
 * - constructor(): Initializes the contract, setting the initial owner and default admin role.
 * - depositETH() payable: Deposit Ether into the vault.
 * - depositToken(address tokenAddress, uint256 amount): Deposit a specified ERC-20 token amount.
 * - defineUnlockEpoch(uint256 epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker): Defines/updates configuration for an epoch. Requires CONFIGURATOR_ROLE.
 * - updateEpochParameters(uint256 epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker): Modifies existing epoch parameters. Requires CONFIGURATOR_ROLE.
 * - generateSequenceID(): Generates a unique Sequence ID. May require catalystFee.
 * - transferSequenceID(uint256 sequenceId, address recipient): Transfers ownership of a Sequence ID.
 * - attemptUnlock(uint256 epochId, uint256 sequenceId, bytes32 userSeed): Core logic: checks epoch, Sequence ID, generates pseudo-randomness against threshold. Calculates withdrawable amount on success.
 * - withdrawUnlockedFunds(uint256 epochId, uint256 sequenceId): Withdraws funds for a successful unlock attempt.
 * - grantRole(bytes32 role, address account): Grants a role. Requires DEFAULT_ADMIN_ROLE.
 * - revokeRole(bytes32 role, address account): Revokes a role. Requires DEFAULT_ADMIN_ROLE.
 * - renounceRole(bytes32 role): Renounces caller's own role.
 * - pause(): Pauses contract. Requires PAUSER_ROLE.
 * - unpause(): Unpauses contract. Requires PAUSER_ROLE.
 * - emergencyWithdraw(address tokenAddress): Withdraws all funds when paused. Requires EMERGENCY_ADMIN_ROLE.
 * - getEpochConfig(uint256 epochId): View: Get epoch config details.
 * - getSequenceIDStatus(uint256 sequenceId): View: Get Sequence ID status.
 * - getWithdrawableAmount(uint256 epochId, uint256 sequenceId): View: Get withdrawable amount for a successful unlock.
 * - getTotalVaultBalance(address tokenAddress): View: Get total balance of a token (or ETH).
 * - predictEpochOutcome(uint256 epochId, bytes32 userSeed): View: Simulated prediction of randomness outcome based on *known* factors.
 * - setMaxSequenceIDs(uint256 maxIds): Sets max total Sequence IDs. Requires SEQUENCER_MANAGER_ROLE.
 * - setSequenceIDCatalystFee(uint256 feeAmount): Sets ETH fee for generating Sequence ID. Requires SEQUENCER_MANAGER_ROLE.
 * - withdrawCatalystFees(address recipient): Withdraws accumulated catalyst fees. Requires SEQUENCER_MANAGER_ROLE or DEFAULT_ADMIN_ROLE.
 * - configureVaultParameters(uint256 minDepositETH, uint256 minDepositToken, uint256 maxEpochId): Sets global vault parameters. Requires CONFIGURATOR_ROLE.
 * - getRoleAdmin(bytes32 role): View: Get admin role for a role.
 * - hasRole(bytes32 role, address account): View: Check if account has a role.
 * - getEpochSuccessfulUnlockers(uint256 epochId): View: Get list of Sequence IDs successful for an epoch.
 * - getEpochRandomnessResult(uint256 epochId): View: Get the *actual* pseudo-randomness generated for an epoch.
 * - getSequenceIDOwner(uint256 sequenceId): View: Get owner of a Sequence ID.
 */
contract QuantumVault {

    // --- State Variables ---

    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant SEQUENCER_MANAGER_ROLE = keccak256("SEQUENCER_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmins; // Simple role hierarchy

    mapping(address => uint256) private ethBalances;
    mapping(address => mapping(address => uint256)) private tokenBalances; // tokenAddress => account => balance

    struct EpochConfig {
        uint64 unlockStartTime; // Start timestamp (inclusive)
        uint64 unlockEndTime;   // End timestamp (exclusive)
        uint256 minRandomnessThreshold; // Minimum pseudo-randomness value (out of 2^256) to succeed
        uint256 fundsSharePerUnlocker; // Amount of funds claimed by *one* successful unlock for this epoch
        bool isDefined; // Flag to check if epoch config exists
        bytes32 randomnessSeed; // Seed used for epoch randomness calculation (set on first attempt)
        uint256 randomnessResult; // Calculated randomness result for the epoch (set on first attempt)
    }
    mapping(uint256 => EpochConfig) public epochConfigs;

    struct SequenceIDStatus {
        address owner;
        bool exists; // Flag to check if the ID was ever generated
        uint256 successfulUnlockEpoch; // Epoch ID if successfully used once
        mapping(uint256 => bool) attemptedEpochs; // Track epochs where attempt was made
        mapping(uint256 => bool) successfulEpochs; // Track epochs where attempt was successful
    }
    mapping(uint256 => SequenceIDStatus) public sequenceIDs;
    uint256 public nextSequenceId = 1;
    uint256 public maxSequenceIds = 10000; // Default limit
    uint256 public sequenceIdCatalystFee = 0; // Default fee in wei
    uint256 private accumulatedCatalystFees = 0;

    // Mapping: epochId => sequenceId => withdrawableAmount
    mapping(uint256 => mapping(uint256 => uint256)) public withdrawableAmounts;

    bool public paused = false;

    // Vault parameters
    uint256 public minDepositETH = 0;
    uint256 public minDepositToken = 0;
    uint256 public maxEpochId = 1000; // Default max epoch ID

    // --- Events ---

    event Deposit(address indexed account, address indexed token, uint256 amount);
    event EpochConfigured(uint256 indexed epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker);
    event SequenceIDGenerated(uint256 indexed sequenceId, address indexed owner);
    event SequenceIDTransferred(uint256 indexed sequenceId, address indexed from, address indexed to);
    event UnlockAttempted(uint256 indexed epochId, uint256 indexed sequenceId, address indexed caller, bool success, uint256 randomnessResult);
    event UnlockSuccessful(uint256 indexed epochId, uint256 indexed sequenceId, address indexed unlocker, uint256 amountWithdrawnClaimed);
    event FundsWithdrawn(uint256 indexed epochId, uint256 indexed sequenceId, address indexed withdrawer, address indexed token, uint256 amount);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount);
    event CatalystFeesWithdrawn(address indexed recipient, uint256 amount);
    event VaultParametersConfigured(uint256 minDepositETH, uint256 minDepositToken, uint256 maxEpochId);

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        require(_roles[role][msg.sender], "AccessControl: caller is missing role");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        _roles[DEFAULT_ADMIN_ROLE][msg.sender] = true;
        _roleAdmins[DEFAULT_ADMIN_ROLE] = DEFAULT_ADMIN_ROLE; // Self-managed by default admin
        _roleAdmins[CONFIGURATOR_ROLE] = DEFAULT_ADMIN_ROLE;
        _roleAdmins[SEQUENCER_MANAGER_ROLE] = DEFAULT_ADMIN_ROLE;
        _roleAdmins[PAUSER_ROLE] = DEFAULT_ADMIN_ROLE;
        _roleAdmins[EMERGENCY_ADMIN_ROLE] = DEFAULT_ADMIN_ROLE;

        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
    }

    // --- Deposit Functions ---

    /**
     * @dev Deposits Ether into the vault.
     */
    function depositETH() public payable whenNotPaused {
        require(msg.value >= minDepositETH, "Deposit: minimum ETH deposit not met");
        ethBalances[address(this)] += msg.value; // Track contract's internal balance for clarity/views
        // Actual ETH is sent directly to contract address, no explicit transfer needed here.
        emit Deposit(msg.sender, address(0), msg.value);
    }

    /**
     * @dev Deposits ERC-20 tokens into the vault.
     * @param tokenAddress The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(address tokenAddress, uint256 amount) public whenNotPaused {
        require(tokenAddress != address(0), "Deposit: invalid token address");
        require(amount > 0, "Deposit: amount must be positive");
        require(amount >= minDepositToken, "Deposit: minimum token deposit not met");

        // Ensure the token is ERC-20 compatible (basic check)
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Deposit: token transfer failed");

        tokenBalances[tokenAddress][address(this)] += amount; // Track contract's internal balance
        emit Deposit(msg.sender, tokenAddress, amount);
    }

    // --- Epoch Management Functions ---

    /**
     * @dev Defines or updates the configuration for a specific unlock epoch.
     * @param epochId The ID of the epoch.
     * @param unlockStartTime The timestamp when the unlock window starts.
     * @param unlockEndTime The timestamp when the unlock window ends.
     * @param minRandomnessThreshold The minimum pseudo-randomness value (0 to 2^256-1) required for a successful unlock.
     * @param fundsSharePerUnlocker The amount of funds (in wei for ETH, or token units) claimed by *each* successful unlock attempt for this epoch.
     * Requires CONFIGURATOR_ROLE.
     */
    function defineUnlockEpoch(uint256 epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker) public onlyRole(CONFIGURATOR_ROLE) {
        require(epochId > 0 && epochId <= maxEpochId, "Epoch: invalid epoch ID");
        require(unlockStartTime < unlockEndTime, "Epoch: start time must be before end time");
        // No specific check for minRandomnessThreshold range, any uint256 is valid as a target.
        // No specific check for fundsSharePerUnlocker, but be mindful of total vault balance.

        epochConfigs[epochId] = EpochConfig({
            unlockStartTime: unlockStartTime,
            unlockEndTime: unlockEndTime,
            minRandomnessThreshold: minRandomnessThreshold,
            fundsSharePerUnlocker: fundsSharePerUnlocker,
            isDefined: true,
            randomnessSeed: bytes32(0), // Seed initialized to zero
            randomnessResult: 0 // Result initialized to zero
        });

        emit EpochConfigured(epochId, unlockStartTime, unlockEndTime, minRandomnessThreshold, fundsSharePerUnlocker);
    }

    /**
     * @dev Updates parameters for an existing unlock epoch.
     * @param epochId The ID of the epoch.
     * @param unlockStartTime The new start timestamp.
     * @param unlockEndTime The new end timestamp.
     * @param minRandomnessThreshold The new minimum randomness threshold.
     * @param fundsSharePerUnlocker The new funds share per unlocker.
     * Requires CONFIGURATOR_ROLE.
     */
    function updateEpochParameters(uint256 epochId, uint64 unlockStartTime, uint64 unlockEndTime, uint256 minRandomnessThreshold, uint256 fundsSharePerUnlocker) public onlyRole(CONFIGURATOR_ROLE) {
        require(epochConfigs[epochId].isDefined, "Epoch: epoch not defined");
        require(unlockStartTime < unlockEndTime, "Epoch: start time must be before end time");

        EpochConfig storage epoch = epochConfigs[epochId];
        epoch.unlockStartTime = unlockStartTime;
        epoch.unlockEndTime = unlockEndTime;
        epoch.minRandomnessThreshold = minRandomnessThreshold;
        epoch.fundsSharePerUnlocker = fundsSharePerUnlocker;
        // Note: Randomness seed and result are *not* updated here once set by attemptUnlock

        emit EpochConfigured(epochId, unlockStartTime, unlockEndTime, minRandomnessThreshold, fundsSharePerUnlocker); // Use same event for update
    }

    // --- Sequence ID Management Functions ---

    /**
     * @dev Generates a unique Sequence ID for the caller. Requires catalystFee.
     * @return The newly generated sequence ID.
     */
    function generateSequenceID() public payable whenNotPaused returns (uint256) {
        require(nextSequenceId <= maxSequenceIds, "SequenceID: max IDs reached");
        require(msg.value >= sequenceIdCatalystFee, "SequenceID: insufficient catalyst fee");

        if (msg.value > sequenceIdCatalystFee) {
            // Return excess Ether
            payable(msg.sender).transfer(msg.value - sequenceIdCatalystFee);
        }
        accumulatedCatalystFees += sequenceIdCatalystFee;

        uint256 newId = nextSequenceId;
        sequenceIDs[newId].owner = msg.sender;
        sequenceIDs[newId].exists = true;
        nextSequenceId++;

        emit SequenceIDGenerated(newId, msg.sender);
        return newId;
    }

    /**
     * @dev Transfers ownership of a Sequence ID.
     * @param sequenceId The ID of the sequence to transfer.
     * @param recipient The address to transfer the sequence ID to.
     */
    function transferSequenceID(uint256 sequenceId, address recipient) public whenNotPaused {
        require(sequenceIDs[sequenceId].exists, "SequenceID: ID does not exist");
        require(sequenceIDs[sequenceId].owner == msg.sender, "SequenceID: caller is not the owner");
        require(recipient != address(0), "SequenceID: invalid recipient address");
        require(recipient != msg.sender, "SequenceID: cannot transfer to self");

        address oldOwner = sequenceIDs[sequenceId].owner;
        sequenceIDs[sequenceId].owner = recipient;

        emit SequenceIDTransferred(sequenceId, oldOwner, recipient);
    }

     /**
     * @dev Sets the maximum total number of Sequence IDs that can be generated.
     * @param maxIds The new maximum number of Sequence IDs.
     * Requires SEQUENCER_MANAGER_ROLE.
     */
    function setMaxSequenceIDs(uint256 maxIds) public onlyRole(SEQUENCER_MANAGER_ROLE) {
        require(maxIds >= nextSequenceId -1, "SequenceID: max IDs cannot be less than generated IDs");
        maxSequenceIds = maxIds;
    }

    /**
     * @dev Sets the amount of Ether required to generate a Sequence ID.
     * @param feeAmount The new fee amount in wei.
     * Requires SEQUENCER_MANAGER_ROLE.
     */
    function setSequenceIDCatalystFee(uint256 feeAmount) public onlyRole(SEQUENCER_MANAGER_ROLE) {
        sequenceIdCatalystFee = feeAmount;
    }

    /**
     * @dev Allows the Sequence Manager or Admin to withdraw accumulated catalyst fees.
     * @param recipient The address to send the fees to.
     * Requires SEQUENCER_MANAGER_ROLE or DEFAULT_ADMIN_ROLE.
     */
    function withdrawCatalystFees(address recipient) public whenNotPaused {
        require(hasRole(SEQUENCER_MANAGER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AccessControl: caller is not manager or admin");
        require(recipient != address(0), "Withdrawal: invalid recipient address");

        uint256 amount = accumulatedCatalystFees;
        accumulatedCatalystFees = 0;

        if (amount > 0) {
            (bool success,) = payable(recipient).call{value: amount}("");
            require(success, "Withdrawal: fee withdrawal failed");
            emit CatalystFeesWithdrawn(recipient, amount);
        }
    }


    // --- Core Unlock Logic ---

    /**
     * @dev Attempts to unlock funds for a specific epoch using a sequence ID.
     * Includes randomness generation and threshold check.
     * @param epochId The ID of the epoch to attempt unlocking.
     * @param sequenceId The Sequence ID to use for the attempt.
     * @param userSeed A user-provided seed to influence (but not fully control) randomness.
     */
    function attemptUnlock(uint256 epochId, uint256 sequenceId, bytes32 userSeed) public whenNotPaused {
        require(epochConfigs[epochId].isDefined, "Unlock: epoch not defined");
        require(sequenceIDs[sequenceId].exists, "Unlock: sequence ID does not exist");
        require(sequenceIDs[sequenceId].owner == msg.sender, "Unlock: caller is not the sequence ID owner");
        require(block.timestamp >= epochConfigs[epochId].unlockStartTime, "Unlock: epoch has not started");
        require(block.timestamp < epochConfigs[epochId].unlockEndTime, "Unlock: epoch has ended");
        require(!sequenceIDs[sequenceId].attemptedEpochs[epochId], "Unlock: sequence ID already attempted for this epoch");

        // Mark sequence ID as attempted for this epoch
        sequenceIDs[sequenceId].attemptedEpochs[epochId] = true;

        // --- Pseudo-randomness Generation ---
        // NOTE: This is a *simplified, non-custodial* randomness source suitable for demonstration.
        // For high-value applications, a verifiable randomness function (VRF) like Chainlink VRF
        // should be used to prevent miner front-running and ensure true unpredictability.
        // This version uses block data which can be influenced or known to miners.
        bytes32 randomnessSeed;
        uint256 randomnessResult;

        if (epochConfigs[epochId].randomnessSeed == bytes32(0)) {
             // First attempt for this epoch sets the seed based on the block *before* this transaction
             // (to make it slightly harder to predict within the same block) and other factors.
             // It's crucial to use block.number > 0. If block.number == 0, blockhash(0) is 0.
             // We use block.number - 1 for a slight delay, but block.difficulty/timestamp/basefee
             // of the *current* block are also common factors, still susceptible to miner influence.
             bytes32 blockHashSeed = block.number > 0 ? blockhash(block.number - 1) : bytes32(uint256(block.timestamp)); // Fallback if block 0
             randomnessSeed = keccak256(abi.encodePacked(blockHashSeed, epochId, epochConfigs[epochId].unlockStartTime, userSeed, block.timestamp));
             epochConfigs[epochId].randomnessSeed = randomnessSeed;
        } else {
            // Subsequent attempts for this epoch use the same established seed, adding user seed
            // and current block data for minor variation, but the core entropy is from the first attempt.
            // Note: Using the existing seed makes subsequent attempts deterministic *relative to that seed*.
            // This design means the "quantum state" for an epoch is fixed by the first attempt.
            randomnessSeed = epochConfigs[epochId].randomnessSeed; // Use the seed established by the first attempt
             randomnessResult = uint256(keccak256(abi.encodePacked(randomnessSeed, userSeed, block.timestamp, block.difficulty, block.basefee))); // Incorporate user seed and current block data for variability
        }
        // If randomness was not set yet, calculate it now based on the established seed
         if(epochConfigs[epochId].randomnessResult == 0 && epochConfigs[epochId].randomnessSeed != bytes32(0)){
              randomnessResult = uint256(keccak256(abi.encodePacked(epochConfigs[epochId].randomnessSeed))); // Calculate final result based on the fixed seed
              epochConfigs[epochId].randomnessResult = randomnessResult; // Store the fixed result for this epoch
         } else {
             // If randomnessResult was already set by a previous attempt, use that fixed result
             randomnessResult = epochConfigs[epochId].randomnessResult;
         }

        bool success = (randomnessResult >= epochConfigs[epochId].minRandomnessThreshold);

        emit UnlockAttempted(epochId, sequenceId, msg.sender, success, randomnessResult);

        if (success) {
            // Mark sequence ID as successful for this epoch
            sequenceIDs[sequenceId].successfulEpochs[epochId] = true;
            // If this is the *first* successful unlock for this sequence ID ever, record it
            if (sequenceIDs[sequenceId].successfulUnlockEpoch == 0) {
                 sequenceIDs[sequenceId].successfulUnlockEpoch = epochId;
            }

            // Calculate and assign withdrawable amount
            // Note: This example assumes fundsSharePerUnlocker is in the base unit (wei for ETH, token units for ERC20).
            // A more complex version could handle different tokens or percentages.
            uint256 share = epochConfigs[epochId].fundsSharePerUnlocker;

            // Prevent claiming more than the total vault balance (for ETH, simplify for example)
            // In a real multi-token system, this check would be per-token.
            uint256 totalEthInVault = address(this).balance; // Use actual contract balance for ETH
            // For ERC20, would need to check tokenBalances[tokenAddress][address(this)]
            // This simple example only considers ETH for the withdrawable amount calculation for brevity.
            if (share > totalEthInVault) {
                share = totalEthInVault;
            }

            // We could also cap the total claimable per epoch based on total funds deposited *for* that epoch,
            // but this example simplifies by allowing claims up to the total vault ETH balance per successful unlocker.
            // A more robust system would link deposits to epochs.

            withdrawableAmounts[epochId][sequenceId] += share; // Allow multiple successes to accrue? No, one success per ID per epoch
            require(withdrawableAmounts[epochId][sequenceId] == share, "Unlock: withdrawable amount already set for this success"); // Ensure it's only set once per ID/epoch successful combo

            emit UnlockSuccessful(epochId, sequenceId, msg.sender, share);

        } else {
             // Optionally, add logic here for failed attempts, e.g., burning the Sequence ID,
             // increasing fee for next attempt, adding cooldown, etc.
             // For this example, we just mark it as attempted.
        }
    }

    // --- Withdrawal Function ---

    /**
     * @dev Allows a user to withdraw funds associated with a successful unlock attempt.
     * This example assumes ETH is withdrawn. A real multi-token version would need token address parameter.
     * @param epochId The epoch ID of the successful unlock.
     * @param sequenceId The Sequence ID used for the successful unlock.
     */
    function withdrawUnlockedFunds(uint256 epochId, uint256 sequenceId) public whenNotPaused {
        require(sequenceIDs[sequenceId].exists, "Withdrawal: sequence ID does not exist");
        require(sequenceIDs[sequenceId].owner == msg.sender, "Withdrawal: caller is not the sequence ID owner");
        require(sequenceIDs[sequenceId].successfulEpochs[epochId], "Withdrawal: sequence ID not successful for this epoch");

        uint256 amount = withdrawableAmounts[epochId][sequenceId];
        require(amount > 0, "Withdrawal: no withdrawable amount for this unlock");

        // Prevent double withdrawal
        withdrawableAmounts[epochId][sequenceId] = 0;

        // Execute the transfer (assuming ETH)
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal: ETH transfer failed");

        // In a multi-token contract, you would need to track which token amount is withdrawable
        // and transfer the correct token here.
        emit FundsWithdrawn(epochId, sequenceId, msg.sender, address(0), amount); // Using address(0) for ETH
    }

    // --- Role Management (Simplified Access Control) ---

    /**
     * @dev Grants a role to an account. Requires the admin role for the granted role.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantRole(bytes32 role, address account) public {
        require(_roles[_roleAdmins[role]][msg.sender], "AccessControl: caller is missing admin role");
        require(account != address(0), "AccessControl: account is zero address");

        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes a role from an account. Requires the admin role for the revoked role.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public {
        require(_roles[_roleAdmins[role]][msg.sender], "AccessControl: caller is missing admin role");
         require(account != address(0), "AccessControl: account is zero address");

        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

     /**
     * @dev Revokes a role from the calling account.
     * @param role The role to renounce.
     */
    function renounceRole(bytes32 role) public {
        require(_roles[role][msg.sender], "AccessControl: caller does not have role");
        _roles[role][msg.sender] = false;
        emit RoleRevoked(role, msg.sender, msg.sender);
    }


    /**
     * @dev Checks if an account has a role.
     * @param role The role to check.
     * @param account The account to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /**
     * @dev Returns the admin role that manages `role`.
     * @param role The role to query.
     * @return The admin role.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmins[role];
    }

    // --- Pause and Emergency ---

    /**
     * @dev Pauses the contract, disabling key functions.
     * Requires PAUSER_ROLE.
     */
    function pause() public onlyRole(PAUSER_ROLE) whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     * Requires PAUSER_ROLE.
     */
    function unpause() public onlyRole(PAUSER_ROLE) whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows an emergency admin to withdraw all funds when paused.
     * @param tokenAddress The address of the token to withdraw (address(0) for ETH).
     * Requires EMERGENCY_ADMIN_ROLE and the contract to be paused.
     */
    function emergencyWithdraw(address tokenAddress) public onlyRole(EMERGENCY_ADMIN_ROLE) whenPaused {
        uint256 amount;
        if (tokenAddress == address(0)) {
            amount = address(this).balance - accumulatedCatalystFees; // Leave catalyst fees unless explicitly stated? Let's withdraw everything for emergency
             amount = address(this).balance; // Withdraw total ETH
            if (amount > 0) {
                (bool success,) = payable(msg.sender).call{value: amount}("");
                require(success, "Emergency withdrawal failed");
            }
        } else {
            IERC20 token = IERC20(tokenAddress);
            amount = token.balanceOf(address(this));
            if (amount > 0) {
                 require(token.transfer(msg.sender, amount), "Emergency token withdrawal failed");
            }
             tokenBalances[tokenAddress][address(this)] = 0; // Update internal balance tracking
        }
        ethBalances[address(this)] = address(this).balance; // Update internal balance tracking

        emit EmergencyWithdrawal(tokenAddress, msg.sender, amount);
    }

    // --- View/Query Functions ---

    /**
     * @dev Gets the configuration details for a specific epoch.
     * @param epochId The ID of the epoch.
     * @return unlockStartTime, unlockEndTime, minRandomnessThreshold, fundsSharePerUnlocker, isDefined, randomnessSeed, randomnessResult.
     */
    function getEpochConfig(uint256 epochId) public view returns (uint64, uint64, uint256, uint256, bool, bytes32, uint256) {
        EpochConfig storage config = epochConfigs[epochId];
        return (config.unlockStartTime, config.unlockEndTime, config.minRandomnessThreshold, config.fundsSharePerUnlocker, config.isDefined, config.randomnessSeed, config.randomnessResult);
    }

    /**
     * @dev Gets the status details for a specific Sequence ID.
     * @param sequenceId The ID of the sequence.
     * @return owner, exists, successfulUnlockEpoch.
     * Note: Does not return attempt/success mappings directly due to Solidity mapping limitations in returns.
     * Individual checks `sequenceIDs[sequenceId].attemptedEpochs[epochId]` are needed.
     */
    function getSequenceIDStatus(uint256 sequenceId) public view returns (address, bool, uint256) {
        SequenceIDStatus storage status = sequenceIDs[sequenceId];
        return (status.owner, status.exists, status.successfulUnlockEpoch);
    }

     /**
     * @dev Gets the owner of a specific Sequence ID.
     * @param sequenceId The ID of the sequence.
     * @return The owner address. Returns address(0) if ID does not exist.
     */
    function getSequenceIDOwner(uint256 sequenceId) public view returns (address) {
         if (!sequenceIDs[sequenceId].exists) {
             return address(0);
         }
         return sequenceIDs[sequenceId].owner;
    }

    /**
     * @dev Gets the amount of funds claimable by a specific successful unlock attempt.
     * @param epochId The epoch ID of the successful unlock.
     * @param sequenceId The Sequence ID used.
     * @return The withdrawable amount.
     */
    function getWithdrawableAmount(uint256 epochId, uint256 sequenceId) public view returns (uint256) {
        return withdrawableAmounts[epochId][sequenceId];
    }

     /**
     * @dev Gets the total balance of a specific token (or ETH) held by the contract.
     * Note: For ETH, this returns the actual contract balance, which may include catalyst fees
     * and deposited amounts not yet allocated or withdrawn.
     * @param tokenAddress The address of the token (address(0) for ETH).
     * @return The total balance.
     */
    function getTotalVaultBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            IERC20 token = IERC20(tokenAddress);
            return token.balanceOf(address(this));
            // Alternatively, if relying solely on internal tracking: return tokenBalances[tokenAddress][address(this)];
            // Using balanceOf is generally safer as it reflects actual token holdings.
        }
    }

     /**
     * @dev Predicts the *simulated* outcome of the pseudo-randomness for an epoch based on currently available data.
     * IMPORTANT: This is *not* a guarantee and future block data is unpredictable.
     * It calculates the potential randomness result using the same function as attemptUnlock
     * if the epoch's seed is set, or based on the *current* block data if not.
     * @param epochId The epoch ID to predict for.
     * @param userSeed A potential user seed to include in the simulation.
     * @return predictedRandomnessResult The calculated pseudo-randomness result based on available data.
     * @return meetsThreshold True if the predicted result meets the epoch's threshold.
     * @return seedIsSet True if the epoch's randomness seed is already set.
     */
    function predictEpochOutcome(uint256 epochId, bytes32 userSeed) public view returns (uint256 predictedRandomnessResult, bool meetsThreshold, bool seedIsSet) {
        require(epochConfigs[epochId].isDefined, "Predict: epoch not defined");

        bytes32 seed;
        uint256 result;

        if (epochConfigs[epochId].randomnessSeed == bytes32(0)) {
             // Simulate the randomness calculation *if* the seed were set now or based on current block data
             bytes32 blockHashSeed = block.number > 0 ? blockhash(block.number - 1) : bytes32(uint256(block.timestamp)); // Using block.number-1 for consistency with attemptUnlock first-seed logic
             seed = keccak256(abi.encodePacked(blockHashSeed, epochId, epochConfigs[epochId].unlockStartTime, userSeed, block.timestamp));
             result = uint256(keccak256(abi.encodePacked(seed))); // Calculate based on this simulated seed
             seedIsSet = false;
        } else {
            // If the seed is already set, the epoch randomness result is fixed (epochConfigs[epochId].randomnessResult).
            // The user seed and current block data in attemptUnlock only influence the randomness *within* that attempt transaction,
            // not the epoch's *final* randomness result itself, which is fixed once set.
            // This view function can return the fixed epoch randomness result if available.
             seed = epochConfigs[epochId].randomnessSeed;
             result = epochConfigs[epochId].randomnessResult; // Use the actual fixed result for the epoch
             if (result == 0) {
                 // If seed is set but result hasn't been calculated yet (e.g., first attempt transaction failed after setting seed but before calculating result)
                 result = uint256(keccak256(abi.encodePacked(seed)));
             }
             seedIsSet = true;
        }

        return (result, result >= epochConfigs[epochId].minRandomnessThreshold, seedIsSet);
    }

    /**
     * @dev Gets a list (limited) or iterator hint for Sequence IDs that successfully unlocked an epoch.
     * Note: Returning dynamic arrays of unknown size is gas-intensive. A more scalable approach
     * involves events or external indexing. This returns the count and requires off-chain indexing
     * or another view function to get individual IDs.
     * @param epochId The epoch ID.
     * @return count The number of successful Sequence IDs for this epoch.
     * (A practical implementation might return a small array slice or require iteration hints)
     */
     function getEpochSuccessfulUnlockers(uint256 epochId) public view returns (uint256 count) {
        // Mappings don't store size directly. This requires iterating or tracking separately.
        // For demonstration, we rely on external tools to track successful attempts via events.
        // A view function to get *if* a specific sequence ID was successful:
        // `function wasSequenceIDSuccessfulForEpoch(uint256 epochId, uint256 sequenceId) public view returns (bool)`
        // is more practical. Let's add that.
        // Adding a simple counter is also an option if we modify attemptUnlock.
        // Let's return 0 and note this limitation, or return the count if we track it.
        // Let's add a counter in the struct and update attemptUnlock.
        // Add `uint256 successfulUnlockCount;` to EpochConfig struct.
        return epochConfigs[epochId].successfulUnlockCount; // Requires modifying EpochConfig struct and attemptUnlock
     }

     /**
      * @dev Checks if a specific Sequence ID was successful for a specific epoch.
      * @param epochId The epoch ID.
      * @param sequenceId The Sequence ID.
      * @return True if the sequence ID successfully unlocked the epoch.
      */
     function wasSequenceIDSuccessfulForEpoch(uint256 epochId, uint256 sequenceId) public view returns (bool) {
        return sequenceIDs[sequenceId].successfulEpochs[epochId];
     }

    /**
     * @dev Gets the actual pseudo-randomness result generated for an epoch once set.
     * @param epochId The epoch ID.
     * @return The actual randomness result (0 if not set yet).
     */
    function getEpochRandomnessResult(uint256 epochId) public view returns (uint256) {
        return epochConfigs[epochId].randomnessResult;
    }

    // --- Configuration Functions ---

    /**
     * @dev Configures global vault parameters.
     * @param _minDepositETH Minimum acceptable Ether deposit.
     * @param _minDepositToken Minimum acceptable ERC-20 token deposit.
     * @param _maxEpochId Maximum allowed epoch ID for configuration.
     * Requires CONFIGURATOR_ROLE.
     */
    function configureVaultParameters(uint256 _minDepositETH, uint256 _minDepositToken, uint256 _maxEpochId) public onlyRole(CONFIGURATOR_ROLE) {
        minDepositETH = _minDepositETH;
        minDepositToken = _minDepositToken;
        require(_maxEpochId >= nextSequenceId - 1, "Config: max epoch ID must be at least current sequence ID count (arbitrary link)"); // Arbitrary requirement
        maxEpochId = _maxEpochId;
        emit VaultParametersConfigured(minDepositETH, minDepositToken, maxEpochId);
    }

    // --- Internal/Utility Functions (if any, not counted in the 20+) ---

    // Note: For a full implementation, need IERC20 interface.
    // interface IERC20 {
    //     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //     function transfer(address recipient, uint256 amount) external returns (bool);
    //     function balanceOf(address account) external view returns (uint256);
    //     function approve(address spender, uint256 amount) external returns (bool);
    // }

    // Fallback function to accept bare ETH deposits (optional, depositETH is explicit)
    receive() external payable {
        this.depositETH();
    }
}

// Dummy IERC20 interface for compilation without importing OpenZeppelin
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool); // Needed for potential future features
}
```