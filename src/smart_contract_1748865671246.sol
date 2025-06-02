Okay, here is a Solidity smart contract incorporating interesting, advanced, creative, and trendy concepts beyond standard open-source patterns.

The core idea revolves around a "Quantum Flux Vault" that holds assets (ETH and ERC20) where access and interactions are governed by a dynamic state machine, tiered user permissions, and complex, configurable withdrawal conditions that can react to time, internal state, and potentially external data (simulated here). It also includes a novel conditional delegation mechanism and a public function allowing anyone to *attempt* to trigger state changes based on predefined conditions.

This contract is complex and intended as a conceptual example. **It is NOT audited and should NOT be used in production without significant security review and testing.**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although not strictly necessary in 0.8+, good practice with external calls

/**
 * @title QuantumFluxVault
 * @dev A complex vault contract with dynamic access rules, tiered permissions,
 * an internal state machine (phases), conditional withdrawals, and timed delegation.
 * This contract is designed to showcase advanced concepts and is NOT audited.
 */

// --- OUTLINE ---
// 1. Enums for User Tiers and Vault Phases
// 2. Structs for Tier Permissions, Withdrawal Conditions, Phase Change Conditions, and Delegations
// 3. State Variables (Owner, ERC20 Tokens, User Tiers, Tier Permissions, Vault Phase,
//    Withdrawal Conditions, Phase Change Conditions, Oracle Data Simulation, Delegations)
// 4. Events for transparency and monitoring
// 5. Modifiers for access control (internal and external)
// 6. Constructor to initialize contract state
// 7. Receive function for ETH deposits
// 8. Core Deposit Functions (ETH, ERC20)
// 9. Core Withdrawal Functions (ETH, ERC20) - Subject to conditions
// 10. Delegation Functions (Set, Revoke, Withdraw via Delegate)
// 11. Tier Management Functions (Set User Tier, Update Tier Permissions)
// 12. Rule Setting Functions (Withdrawal Conditions, Phase Change Conditions)
// 13. Phase Management Functions (Admin Change, Public Attempt to Change)
// 14. Oracle Simulation Function
// 15. Allowed Token Management Functions
// 16. Emergency Withdrawal Functions (Admin Only)
// 17. Internal Helper Functions (e.g., check withdrawal conditions)
// 18. Public View/Pure Functions (Check eligibility, get state info)


// --- FUNCTION SUMMARY ---
// 1. constructor(address _initialOwner, address[] memory _initialAllowedTokens): Initializes owner and allowed tokens.
// 2. receive(): Allows receiving ETH deposits.
// 3. depositETH(): Receives ETH, subject to tier permissions and vault phase.
// 4. depositERC20(address tokenAddress, uint256 amount): Deposits specified ERC20 token, subject to tier permissions and vault phase.
// 5. withdrawETH(uint256 amount): Withdraws ETH for the caller, subject to their tier permissions and the global/phase withdrawal conditions.
// 6. withdrawERC20(address tokenAddress, uint256 amount): Withdraws ERC20 for the caller, subject to tier permissions and conditions.
// 7. delegateAccess(address delegatee, uint durationSeconds): Delegates withdrawal access to another address for a limited time.
// 8. revokeDelegation(): Revokes the caller's active delegation.
// 9. withdrawETHAsDelegate(address delegator, uint256 amount): Allows a delegatee to withdraw ETH on behalf of the delegator, checking delegation validity and delegator's withdrawal conditions.
// 10. withdrawERC20AsDelegate(address delegator, address tokenAddress, uint256 amount): Allows delegatee to withdraw ERC20 for delegator, checking validity and conditions.
// 11. setUserTier(address user, UserTier tier): Admin function to assign a tier to a user.
// 12. updateTierPermissions(UserTier tier, TierPermissions memory permissions): Admin function to set allowed actions for a specific tier.
// 13. setWithdrawalConditionETH(WithdrawalCondition memory condition): Admin function to set the withdrawal conditions for ETH.
// 14. setWithdrawalConditionERC20(address tokenAddress, WithdrawalCondition memory condition): Admin function to set withdrawal conditions for a specific ERC20 token.
// 15. changeVaultPhase(VaultPhase newPhase): Admin function to force a change in the vault's operational phase.
// 16. setPhaseChangeCondition(VaultPhase fromPhase, VaultPhase toPhase, PhaseChangeCondition memory condition): Admin function to define the conditions required to transition between two phases.
// 17. attemptPhaseChange(VaultPhase targetPhase): Allows *any* user to attempt to trigger a phase change if the conditions defined for the transition from the current phase to the target phase are met.
// 18. updateOracleData(uint256 newValue): Admin function (simulating oracle interaction) to update external data that might influence rules.
// 19. addAllowedToken(address tokenAddress): Admin function to add an ERC20 token that can be deposited/managed.
// 20. removeAllowedToken(address tokenAddress): Admin function to remove an allowed ERC20 token.
// 21. emergencyWithdrawETH(uint256 amount): Admin function for emergency ETH withdrawal, bypassing normal rules.
// 22. emergencyWithdrawERC20(address tokenAddress, uint256 amount): Admin function for emergency ERC20 withdrawal, bypassing normal rules.
// 23. checkWithdrawalEligibility(address user, address tokenAddress): View function to check if a user is currently eligible to withdraw a specific token/ETH based on all rules.
// 24. checkUserTier(address user): View function to get a user's assigned tier.
// 25. checkCurrentPhase(): View function to get the vault's current phase.
// 26. getWithdrawalConditionETH(): View function to get the current ETH withdrawal condition rules.
// 27. getWithdrawalConditionERC20(address tokenAddress): View function to get the current ERC20 withdrawal condition rules for a token.
// 28. getTierPermissions(UserTier tier): View function to get the permissions associated with a specific tier.
// 29. getPhaseChangeCondition(VaultPhase fromPhase, VaultPhase toPhase): View function to get the conditions for a phase transition.
// 30. checkDelegationStatus(address user): View function to check the delegation status for a user.
// 31. getERC20Balance(address tokenAddress): View function to get the vault's balance of a specific ERC20 token.
// 32. getAllowedTokens(): View function to get the list of allowed ERC20 tokens.
// 33. getETHBalance(): View function to get the vault's ETH balance.

contract QuantumFluxVault is Ownable {
    using SafeERC20 for IERC20;

    // --- 1. Enums ---
    enum UserTier {
        None,       // Default, minimal access
        Basic,      // Some deposit/view access
        Advanced,   // More access, maybe limited withdrawals
        Premium,    // Higher withdrawal limits/frequencies
        Admin       // Full control (reserved for owner/specific roles)
    }

    enum VaultPhase {
        Initialized,         // Setup phase
        DepositsOpen,        // Users can deposit
        WithdrawalsOpen,     // Users can withdraw (subject to conditions)
        PhaseShiftRequired,  // Conditions met, phase change pending
        EmergencyLocked      // All operations paused (admin controlled)
    }

    // --- 2. Structs ---
    struct TierPermissions {
        bool canDepositETH;
        bool canDepositERC20;
        bool canWithdrawETH;
        bool canWithdrawERC20;
        bool canDelegateAccess;        // Ability to delegate withdrawal rights
        bool canAttemptPhaseChange; // Ability to call attemptPhaseChange
    }

    struct WithdrawalCondition {
        UserTier minTier;           // Minimum tier required to withdraw
        uint256 startTime;          // Withdrawal not allowed before this timestamp
        uint256 endTime;            // Withdrawal not allowed after this timestamp (0 means no end time)
        uint256 minVaultTotalValueETH; // Minimum total value (ETH + ERC20 equivalent) vault must hold
        bool requiresOracleValueCheck; // Whether oracle data is part of the condition
        uint256 oracleRequiredValue;  // Required value from oracle if check is needed
        VaultPhase requiredPhase;    // Must be in this phase
    }

    struct PhaseChangeCondition {
        uint256 requiredTimeElapsedFromLastPhase; // Minimum time elapsed since last phase change
        uint256 minTotalVaultValueETH;          // Minimum total value required in the vault
        bool requiresOracleValueCheck;          // Whether oracle data is part of the condition
        uint256 oracleRequiredValue;             // Required value from oracle
        uint256 minUniqueDepositors;            // Minimum number of unique depositors
        UserTier minTierToTriggerAttempt;       // Minimum tier to call attemptPhaseChange for this transition
    }

    struct Delegation {
        address delegatee;
        uint256 expiryTime; // Timestamp when delegation expires
        bool isActive;      // Simple flag, combined with expiryTime
    }

    // --- 3. State Variables ---
    mapping(address => UserTier) public userTiers;
    mapping(UserTier => TierPermissions) public tierPermissions;

    VaultPhase public currentPhase;
    uint256 public lastPhaseChangeTime;

    // Conditions for withdrawal (0x0 for ETH)
    mapping(address => WithdrawalCondition) public tokenWithdrawalConditions;
    WithdrawalCondition public ethWithdrawalCondition;

    // Conditions to transition from one phase to another: phaseConditions[fromPhase][toPhase]
    mapping(VaultPhase => mapping(VaultPhase => PhaseChangeCondition)) public phaseConditions;

    uint256 public currentOracleValue; // Simulated oracle data

    mapping(address => Delegation) public delegations; // delegator => Delegation

    mapping(address => bool) public isAllowedToken; // ERC20 tokens allowed in the vault
    address[] private _allowedTokens; // List of allowed tokens for iteration

    mapping(address => bool) private _uniqueDepositors; // Track unique depositors
    uint256 public uniqueDepositorCount;

    // --- 4. Events ---
    event DepositETH(address indexed user, uint256 amount, VaultPhase phase);
    event DepositERC20(address indexed user, address indexed token, uint256 amount, VaultPhase phase);
    event WithdrawETH(address indexed user, uint256 amount, VaultPhase phase);
    event WithdrawERC20(address indexed user, address indexed token, uint256 amount, VaultPhase phase);
    event UserTierChanged(address indexed user, UserTier newTier);
    event TierPermissionsUpdated(UserTier indexed tier, TierPermissions permissions);
    event VaultPhaseChanged(VaultPhase indexed oldPhase, VaultPhase indexed newPhase, address indexed triggeredBy);
    event WithdrawalConditionUpdated(address indexed token, WithdrawalCondition condition);
    event PhaseChangeConditionUpdated(VaultPhase indexed fromPhase, VaultPhase indexed toPhase, PhaseChangeCondition condition);
    event OracleValueUpdated(uint256 newValue);
    event TokenAllowed(address indexed token);
    event TokenRemoved(address indexed token);
    event DelegationSet(address indexed delegator, address indexed delegatee, uint256 expiryTime);
    event DelegationRevoked(address indexed delegator);

    // --- 5. Modifiers ---
    modifier onlyAllowedToken(address tokenAddress) {
        require(isAllowedToken[tokenAddress], "QuantumFluxVault: Token not allowed");
        _;
    }

    modifier onlyTier(address user, UserTier requiredTier) {
        require(userTiers[user] >= requiredTier, "QuantumFluxVault: Insufficient tier");
        _;
    }

    modifier onlyPhase(VaultPhase requiredPhase) {
        require(currentPhase == requiredPhase, "QuantumFluxVault: Incorrect phase");
        _;
    }

    // --- 6. Constructor ---
    constructor(address _initialOwner, address[] memory _initialAllowedTokens) Ownable(_initialOwner) {
        currentPhase = VaultPhase.Initialized;
        lastPhaseChangeTime = block.timestamp;

        // Set default tier permissions (can be updated by owner)
        tierPermissions[UserTier.None] = TierPermissions(false, false, false, false, false, false);
        tierPermissions[UserTier.Basic] = TierPermissions(true, true, false, false, false, true); // Basic can deposit, attempt phase change
        tierPermissions[UserTier.Advanced] = TierPermissions(true, true, true, true, true, true); // Advanced can deposit/withdraw/delegate/attempt
        tierPermissions[UserTier.Premium] = TierPermissions(true, true, true, true, true, true); // Premium same for now, can be differentiated by withdrawal conditions
        tierPermissions[UserTier.Admin] = TierPermissions(true, true, true, true, true, true);

        // Owner is Admin tier by default
        userTiers[_initialOwner] = UserTier.Admin;
        uniqueDepositorCount = 0;

        // Add initial allowed tokens
        for (uint i = 0; i < _initialAllowedTokens.length; i++) {
            addAllowedToken(_initialAllowedTokens[i]);
        }

        // Set initial (restrictive) withdrawal conditions (can be updated)
        ethWithdrawalCondition = WithdrawalCondition(UserTier.Admin, 0, 0, 0, false, 0, VaultPhase.EmergencyLocked);

        // Set initial (difficult) phase change conditions (can be updated)
        // e.g., Initialized -> DepositsOpen requires min vault value
        phaseConditions[VaultPhase.Initialized][VaultPhase.DepositsOpen] = PhaseChangeCondition(0, 1e18, false, 0, 0, UserTier.Basic); // Example: need 1 ETH value total, anyone basic+ can trigger
        // e.g., DepositsOpen -> WithdrawalsOpen requires time elapsed and unique depositors
        phaseConditions[VaultPhase.DepositsOpen][VaultPhase.WithdrawalsOpen] = PhaseChangeCondition(7 days, 0, false, 0, 10, UserTier.Advanced); // Example: 7 days pass, 10 unique depositors, Advanced+ can trigger
        // ... other transitions can be defined

        // Transition from Initialized to DepositsOpen automatically if conditions met (or requires manual trigger)
        // Let's make it require an attempt for now, as it's part of the dynamic concept.
    }

    // --- 7. Receive function ---
    receive() external payable {
        depositETH();
    }

    // --- 8. Core Deposit Functions ---

    /**
     * @dev Allows users to deposit ETH into the vault.
     * Subject to caller's tier permissions and current vault phase.
     */
    function depositETH() public payable {
        require(msg.value > 0, "QuantumFluxVault: Must deposit more than 0 ETH");
        require(tierPermissions[userTiers[msg.sender]].canDepositETH, "QuantumFluxVault: Tier not allowed to deposit ETH");
        require(currentPhase == VaultPhase.DepositsOpen || currentPhase == VaultPhase.Initialized, "QuantumFluxVault: Deposits are not open"); // Allow deposits during init? Maybe not.
        // require(currentPhase == VaultPhase.DepositsOpen, "QuantumFluxVault: Deposits are not open"); // More restrictive

        if (!_uniqueDepositors[msg.sender]) {
            _uniqueDepositors[msg.sender] = true;
            uniqueDepositorCount++;
        }

        emit DepositETH(msg.sender, msg.value, currentPhase);
    }

    /**
     * @dev Allows users to deposit allowed ERC20 tokens into the vault.
     * Subject to caller's tier permissions and current vault phase.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address tokenAddress, uint256 amount) public onlyAllowedToken(tokenAddress) {
        require(amount > 0, "QuantumFluxVault: Must deposit more than 0 tokens");
        require(tierPermissions[userTiers[msg.sender]].canDepositERC20, "QuantumFluxVault: Tier not allowed to deposit ERC20");
        require(currentPhase == VaultPhase.DepositsOpen || currentPhase == VaultPhase.Initialized, "QuantumFluxVault: Deposits are not open"); // Allow deposits during init? Maybe not.
        // require(currentPhase == VaultPhase.DepositsOpen, "QuantumFluxVault: Deposits are not open"); // More restrictive

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

         if (!_uniqueDepositors[msg.sender]) {
            _uniqueDepositors[msg.sender] = true;
            uniqueDepositorCount++;
        }

        emit DepositERC20(msg.sender, tokenAddress, amount, currentPhase);
    }

    // --- 9. Core Withdrawal Functions ---

    /**
     * @dev Allows users to withdraw ETH from the vault.
     * Subject to caller's tier permissions and configured withdrawal conditions.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) public {
        require(amount > 0, "QuantumFluxVault: Must withdraw more than 0 ETH");
        require(tierPermissions[userTiers[msg.sender]].canWithdrawETH, "QuantumFluxVault: Tier not allowed to withdraw ETH");
        require(_checkWithdrawalConditions(msg.sender, address(0)), "QuantumFluxVault: Withdrawal conditions not met");
        require(address(this).balance >= amount, "QuantumFluxVault: Insufficient vault ETH balance");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "QuantumFluxVault: ETH withdrawal failed");

        emit WithdrawETH(msg.sender, amount, currentPhase);
    }

    /**
     * @dev Allows users to withdraw ERC20 tokens from the vault.
     * Subject to caller's tier permissions and configured withdrawal conditions for the token.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress, uint256 amount) public onlyAllowedToken(tokenAddress) {
        require(amount > 0, "QuantumFluxVault: Must withdraw more than 0 tokens");
        require(tierPermissions[userTiers[msg.sender]].canWithdrawERC20, "QuantumFluxVault: Tier not allowed to withdraw ERC20");
        require(_checkWithdrawalConditions(msg.sender, tokenAddress), "QuantumFluxVault: Withdrawal conditions not met");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QuantumFluxVault: Insufficient vault token balance");

        token.safeTransfer(msg.sender, amount);

        emit WithdrawERC20(msg.sender, tokenAddress, amount, currentPhase);
    }

    // --- 10. Delegation Functions ---

    /**
     * @dev Allows a user to delegate their withdrawal access to another address for a limited time.
     * Subject to caller's tier permissions.
     * @param delegatee The address to delegate access to.
     * @param durationSeconds The duration in seconds for which the delegation is valid.
     */
    function delegateAccess(address delegatee, uint256 durationSeconds) public {
        require(delegatee != address(0), "QuantumFluxVault: Invalid delegatee address");
        require(delegatee != msg.sender, "QuantumFluxVault: Cannot delegate to self");
        require(durationSeconds > 0, "QuantumFluxVault: Delegation duration must be positive");
        require(tierPermissions[userTiers[msg.sender]].canDelegateAccess, "QuantumFluxVault: Tier not allowed to delegate");

        delegations[msg.sender] = Delegation(delegatee, block.timestamp + durationSeconds, true);
        emit DelegationSet(msg.sender, delegatee, block.timestamp + durationSeconds);
    }

    /**
     * @dev Allows a user to revoke their active delegation immediately.
     */
    function revokeDelegation() public {
        require(delegations[msg.sender].isActive, "QuantumFluxVault: No active delegation to revoke");
        delete delegations[msg.sender]; // Clear the struct
        emit DelegationRevoked(msg.sender);
    }

    /**
     * @dev Allows a delegatee to withdraw ETH on behalf of the delegator.
     * Checks delegation validity and the delegator's withdrawal conditions.
     * @param delegator The address whose funds are being withdrawn.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETHAsDelegate(address delegator, uint256 amount) public {
        Delegation storage delegation = delegations[delegator];
        require(delegation.isActive && delegation.delegatee == msg.sender && block.timestamp <= delegation.expiryTime, "QuantumFluxVault: Invalid or expired delegation");

        // Check withdrawal conditions *for the delegator*
        require(_checkWithdrawalConditions(delegator, address(0)), "QuantumFluxVault: Delegator's withdrawal conditions not met");
        require(address(this).balance >= amount, "QuantumFluxVault: Insufficient vault ETH balance");

        // Perform withdrawal to the *delegator* or *delegatee*? Let's assume delegatee for utility.
        // NOTE: A real-world scenario might require explicit permission for delegatee to receive.
        (bool success, ) = msg.sender.call{value: amount}(""); // Sending to the delegatee
        require(success, "QuantumFluxVault: Delegated ETH withdrawal failed");

        // Optionally mark delegation as used for this specific action type/amount if needed (adds complexity)
        // For this example, delegation is time-based for any allowed action.

        emit WithdrawETH(delegator, amount, currentPhase); // Log as if delegator did it, but note triggered by delegatee
        // Consider adding a separate event for clarity: event DelegatedWithdrawETH(address indexed delegator, address indexed delegatee, uint256 amount);
    }


     /**
     * @dev Allows a delegatee to withdraw ERC20 tokens on behalf of the delegator.
     * Checks delegation validity and the delegator's withdrawal conditions.
     * @param delegator The address whose funds are being withdrawn.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20AsDelegate(address delegator, address tokenAddress, uint256 amount) public onlyAllowedToken(tokenAddress) {
        Delegation storage delegation = delegations[delegator];
        require(delegation.isActive && delegation.delegatee == msg.sender && block.timestamp <= delegation.expiryTime, "QuantumFluxVault: Invalid or expired delegation");

        // Check withdrawal conditions *for the delegator*
        require(_checkWithdrawalConditions(delegator, tokenAddress), "QuantumFluxVault: Delegator's withdrawal conditions not met");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QuantumFluxVault: Insufficient vault token balance");

        token.safeTransfer(msg.sender, amount); // Sending to the delegatee

        emit WithdrawERC20(delegator, tokenAddress, amount, currentPhase); // Log as if delegator did it
        // Consider adding a separate event: event DelegatedWithdrawERC20(address indexed delegator, address indexed delegatee, address indexed token, uint256 amount);
    }

    // --- 11. Tier Management Functions ---

    /**
     * @dev Admin function to set the tier for a specific user.
     * @param user The address of the user.
     * @param tier The tier to assign.
     */
    function setUserTier(address user, UserTier tier) public onlyOwner {
        require(user != address(0), "QuantumFluxVault: Invalid user address");
        UserTier oldTier = userTiers[user];
        userTiers[user] = tier;
        emit UserTierChanged(user, tier);
    }

    /**
     * @dev Admin function to update the permissions associated with a specific tier.
     * @param tier The tier to update permissions for.
     * @param permissions The new TierPermissions struct.
     */
    function updateTierPermissions(UserTier tier, TierPermissions memory permissions) public onlyOwner {
        tierPermissions[tier] = permissions;
        emit TierPermissionsUpdated(tier, permissions);
    }

    // --- 12. Rule Setting Functions ---

    /**
     * @dev Admin function to set the withdrawal conditions for ETH.
     * @param condition The new WithdrawalCondition struct for ETH.
     */
    function setWithdrawalConditionETH(WithdrawalCondition memory condition) public onlyOwner {
        ethWithdrawalCondition = condition;
        emit WithdrawalConditionUpdated(address(0), condition);
    }

    /**
     * @dev Admin function to set the withdrawal conditions for a specific ERC20 token.
     * @param tokenAddress The address of the ERC20 token.
     * @param condition The new WithdrawalCondition struct for the token.
     */
    function setWithdrawalConditionERC20(address tokenAddress, WithdrawalCondition memory condition) public onlyOwner onlyAllowedToken(tokenAddress) {
        tokenWithdrawalConditions[tokenAddress] = condition;
        emit WithdrawalConditionUpdated(tokenAddress, condition);
    }

    /**
     * @dev Admin function to define the conditions required to transition between two vault phases.
     * @param fromPhase The phase to transition from.
     * @param toPhase The phase to transition to.
     * @param condition The PhaseChangeCondition struct for this transition.
     */
    function setPhaseChangeCondition(VaultPhase fromPhase, VaultPhase toPhase, PhaseChangeCondition memory condition) public onlyOwner {
        require(fromPhase != toPhase, "QuantumFluxVault: Cannot set condition for same phase");
        phaseConditions[fromPhase][toPhase] = condition;
        emit PhaseChangeConditionUpdated(fromPhase, toPhase, condition);
    }

    // --- 13. Phase Management Functions ---

    /**
     * @dev Admin function to force a change in the vault's operational phase. Bypasses conditions.
     * @param newPhase The target phase.
     */
    function changeVaultPhase(VaultPhase newPhase) public onlyOwner {
        require(currentPhase != newPhase, "QuantumFluxVault: Already in this phase");
        VaultPhase oldPhase = currentPhase;
        currentPhase = newPhase;
        lastPhaseChangeTime = block.timestamp;
        emit VaultPhaseChanged(oldPhase, newPhase, msg.sender);
    }

    /**
     * @dev Allows any user to attempt to trigger a phase change.
     * The attempt succeeds only if the predefined conditions for the transition
     * from the current phase to the target phase are met.
     * @param targetPhase The phase to attempt to transition to.
     */
    function attemptPhaseChange(VaultPhase targetPhase) public {
        require(currentPhase != targetPhase, "QuantumFluxVault: Already in the target phase");
        PhaseChangeCondition memory condition = phaseConditions[currentPhase][targetPhase];

        // Check caller's tier permission for *this specific attempt*
        require(tierPermissions[userTiers[msg.sender]].canAttemptPhaseChange, "QuantumFluxVault: Tier not allowed to attempt phase change");
        // Also check minimum tier required *by the condition* itself
        require(userTiers[msg.sender] >= condition.minTierToTriggerAttempt, "QuantumFluxVault: Insufficient tier to trigger this specific phase change");


        // Check time condition
        require(block.timestamp >= lastPhaseChangeTime + condition.requiredTimeElapsedFromLastPhase, "QuantumFluxVault: Time elapsed condition not met");

        // Check value condition (requires total vault value calculation)
        require(_getVaultTotalValueETH() >= condition.minTotalVaultValueETH, "QuantumFluxVault: Minimum vault value condition not met");

        // Check oracle condition
        if (condition.requiresOracleValueCheck) {
            require(currentOracleValue == condition.oracleRequiredValue, "QuantumFluxVault: Oracle value condition not met");
        }

        // Check unique depositors condition
        require(uniqueDepositorCount >= condition.minUniqueDepositors, "QuantumFluxVault: Minimum unique depositors condition not met");

        // If all conditions pass, change phase
        VaultPhase oldPhase = currentPhase;
        currentPhase = targetPhase;
        lastPhaseChangeTime = block.timestamp; // Reset time reference for the *new* phase
        emit VaultPhaseChanged(oldPhase, targetPhase, msg.sender);
    }

    // --- 14. Oracle Simulation Function ---

    /**
     * @dev Admin function to update the simulated oracle data.
     * This data can be used in withdrawal or phase change conditions.
     * In a real contract, this would likely interact with a decentralized oracle network.
     * @param newValue The new oracle value.
     */
    function updateOracleData(uint256 newValue) public onlyOwner {
        currentOracleValue = newValue;
        emit OracleValueUpdated(newValue);
    }

    // --- 15. Allowed Token Management Functions ---

    /**
     * @dev Admin function to add an ERC20 token to the list of allowed tokens.
     * Only allowed tokens can be deposited or have specific withdrawal conditions set.
     * @param tokenAddress The address of the ERC20 token to add.
     */
    function addAllowedToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "QuantumFluxVault: Invalid token address");
        require(!isAllowedToken[tokenAddress], "QuantumFluxVault: Token already allowed");
        isAllowedToken[tokenAddress] = true;
        _allowedTokens.push(tokenAddress);
        emit TokenAllowed(tokenAddress);
    }

    /**
     * @dev Admin function to remove an ERC20 token from the list of allowed tokens.
     * This prevents new deposits of the token, but existing tokens remain in the vault.
     * It also clears the specific withdrawal condition for this token.
     * @param tokenAddress The address of the ERC20 token to remove.
     */
    function removeAllowedToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "QuantumFluxVault: Invalid token address");
        require(isAllowedToken[tokenAddress], "QuantumFluxVault: Token not allowed");

        isAllowedToken[tokenAddress] = false;

        // Find and remove from _allowedTokens array (inefficient for large arrays)
        // A more gas-efficient approach for removal in large arrays is possible
        // (e.g., swap with last element and pop), but this is simpler for the example.
        for (uint i = 0; i < _allowedTokens.length; i++) {
            if (_allowedTokens[i] == tokenAddress) {
                // Shift elements left
                for (uint j = i; j < _allowedTokens.length - 1; j++) {
                    _allowedTokens[j] = _allowedTokens[j+1];
                }
                _allowedTokens.pop();
                break; // Found and removed
            }
        }

        // Clear associated withdrawal condition for the removed token
        delete tokenWithdrawalConditions[tokenAddress];

        emit TokenRemoved(tokenAddress);
    }

    // --- 16. Emergency Withdrawal Functions ---

    /**
     * @dev Admin function for emergency withdrawal of ETH. Bypasses all normal rules.
     * Use with extreme caution.
     * @param amount The amount of ETH to withdraw.
     */
    function emergencyWithdrawETH(uint256 amount) public onlyOwner {
         require(address(this).balance >= amount, "QuantumFluxVault: Insufficient vault ETH balance for emergency");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "QuantumFluxVault: Emergency ETH withdrawal failed");
         emit WithdrawETH(msg.sender, amount, VaultPhase.EmergencyLocked); // Log under Emergency phase
    }

    /**
     * @dev Admin function for emergency withdrawal of ERC20 tokens. Bypasses all normal rules.
     * Use with extreme caution.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) public onlyOwner onlyAllowedToken(tokenAddress) {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QuantumFluxVault: Insufficient vault token balance for emergency");
        token.safeTransfer(msg.sender, amount);
        emit WithdrawERC20(msg.sender, tokenAddress, amount, VaultPhase.EmergencyLocked); // Log under Emergency phase
    }

    // --- 17. Internal Helper Functions ---

    /**
     * @dev Internal function to check if withdrawal conditions are met for a user and token/ETH.
     * @param user The address attempting to withdraw.
     * @param tokenAddress The address of the token (0x0 for ETH).
     * @return True if withdrawal conditions are met, false otherwise.
     */
    function _checkWithdrawalConditions(address user, address tokenAddress) internal view returns (bool) {
        WithdrawalCondition memory condition;
        if (tokenAddress == address(0)) {
            condition = ethWithdrawalCondition;
        } else {
            // If token is not allowed or no specific condition set, use a default restrictive one?
            // Or just rely on the `onlyAllowedToken` modifier on public withdrawal functions.
            // Let's assume a condition exists (even if default-initialized to restrictive).
             require(isAllowedToken[tokenAddress], "QuantumFluxVault: Token not allowed for condition check"); // Should be caught by public function modifier, but safety.
            condition = tokenWithdrawalConditions[tokenAddress];
        }

        // Check minimum tier
        if (userTiers[user] < condition.minTier) {
            return false;
        }

        // Check time window
        if (condition.startTime > 0 && block.timestamp < condition.startTime) {
             return false;
        }
        if (condition.endTime > 0 && block.timestamp > condition.endTime) {
             return false;
        }

        // Check minimum vault total value
        if (_getVaultTotalValueETH() < condition.minVaultTotalValueETH) {
             return false;
        }

        // Check oracle condition
        if (condition.requiresOracleValueCheck) {
            if (currentOracleValue != condition.oracleRequiredValue) {
                 return false;
            }
        }

        // Check required phase
        if (currentPhase != condition.requiredPhase) {
             return false;
        }

        // All conditions met
        return true;
    }

     /**
     * @dev Internal helper to calculate the total value of assets in the vault, expressed in ETH.
     * This is a placeholder - a real implementation would require reliable price oracles
     * for each allowed token, which adds significant complexity.
     * Here, it just sums ETH and assumes 1:1 value for ERC20 (unsafe for real use).
     * @return The total value of assets in the vault in a simulated ETH value.
     */
    function _getVaultTotalValueETH() internal view returns (uint256) {
        uint256 totalValue = address(this).balance; // ETH balance

        // Sum ERC20 balances (SIMPLIFICATION: Assumes 1 token = 1 wei of ETH equivalent)
        // In a real dapp, integrate Chainlink Price Feeds or similar here.
        for (uint i = 0; i < _allowedTokens.length; i++) {
            address tokenAddress = _allowedTokens[i];
            if (isAllowedToken[tokenAddress]) { // Double check in case removal failed fully or array isn't clean
                 IERC20 token = IERC20(tokenAddress);
                 // DANGER: This is a placeholder! Replace with oracle price * token.balanceOf(address(this))
                 totalValue = totalValue.add(token.balanceOf(address(this)));
            }
        }
        return totalValue;
    }

    // --- 18. Public View/Pure Functions ---

    /**
     * @dev Checks if a user is currently eligible to withdraw a specific token/ETH.
     * Combines tier permissions and the token/ETH specific withdrawal conditions.
     * @param user The address to check eligibility for.
     * @param tokenAddress The address of the token (0x0 for ETH).
     * @return True if eligible, false otherwise.
     */
    function checkWithdrawalEligibility(address user, address tokenAddress) public view returns (bool) {
        TierPermissions memory perms = tierPermissions[userTiers[user]];
        bool tierAllowed = (tokenAddress == address(0)) ? perms.canWithdrawETH : perms.canWithdrawERC20;

        if (!tierAllowed) {
            return false;
        }

        return _checkWithdrawalConditions(user, tokenAddress);
    }

    /**
     * @dev Gets the tier assigned to a specific user.
     * @param user The address of the user.
     * @return The user's tier.
     */
    function checkUserTier(address user) public view returns (UserTier) {
        return userTiers[user];
    }

    /**
     * @dev Gets the current operational phase of the vault.
     * @return The current VaultPhase.
     */
    function checkCurrentPhase() public view returns (VaultPhase) {
        return currentPhase;
    }

    /**
     * @dev Gets the current withdrawal condition rules for ETH.
     * @return The WithdrawalCondition struct for ETH.
     */
    function getWithdrawalConditionETH() public view returns (WithdrawalCondition memory) {
        return ethWithdrawalCondition;
    }

    /**
     * @dev Gets the current withdrawal condition rules for a specific ERC20 token.
     * @param tokenAddress The address of the ERC20 token.
     * @return The WithdrawalCondition struct for the token.
     */
    function getWithdrawalConditionERC20(address tokenAddress) public view onlyAllowedToken(tokenAddress) returns (WithdrawalCondition memory) {
        return tokenWithdrawalConditions[tokenAddress];
    }

    /**
     * @dev Gets the permissions associated with a specific tier.
     * @param tier The UserTier.
     * @return The TierPermissions struct for the tier.
     */
    function getTierPermissions(UserTier tier) public view returns (TierPermissions memory) {
        return tierPermissions[tier];
    }

     /**
     * @dev Gets the conditions required for a specific phase transition.
     * @param fromPhase The phase to transition from.
     * @param toPhase The phase to transition to.
     * @return The PhaseChangeCondition struct for the transition.
     */
    function getPhaseChangeCondition(VaultPhase fromPhase, VaultPhase toPhase) public view returns (PhaseChangeCondition memory) {
        return phaseConditions[fromPhase][toPhase];
    }

    /**
     * @dev Checks the delegation status for a specific user (the delegator).
     * @param user The address of the potential delegator.
     * @return A tuple containing the delegatee address, expiry timestamp, and active status.
     */
    function checkDelegationStatus(address user) public view returns (address delegatee, uint256 expiryTime, bool isActive) {
        Delegation storage delegation = delegations[user];
        return (delegation.delegatee, delegation.expiryTime, delegation.isActive && block.timestamp <= delegation.expiryTime);
    }

    /**
     * @dev Gets the vault's balance of a specific ERC20 token.
     * @param tokenAddress The address of the ERC20 token.
     * @return The balance amount.
     */
    function getERC20Balance(address tokenAddress) public view onlyAllowedToken(tokenAddress) returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Gets the list of ERC20 tokens currently allowed in the vault.
     * @return An array of allowed token addresses.
     */
    function getAllowedTokens() public view returns (address[] memory) {
        // Filter out any potential null/zero addresses if removal wasn't clean
        uint256 count = 0;
        for(uint i = 0; i < _allowedTokens.length; i++){
            if(isAllowedToken[_allowedTokens[i]]){
                count++;
            }
        }

        address[] memory activeTokens = new address[](count);
        uint256 index = 0;
         for(uint i = 0; i < _allowedTokens.length; i++){
            if(isAllowedToken[_allowedTokens[i]]){
                activeTokens[index] = _allowedTokens[i];
                index++;
            }
        }

        return activeTokens;
    }

     /**
     * @dev Gets the vault's current ETH balance.
     * @return The ETH balance.
     */
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Total functions >= 20 check ---
    // Count: constructor(1) + receive (1) + deposits(2) + withdrawals(2) + delegation(4) + tiers(2) + rules(3) + phases(3) + oracle(1) + token management(2) + emergency(2) + helpers(2 internal) + views(11)
    // Total = 1 + 1 + 2 + 2 + 4 + 2 + 3 + 3 + 1 + 2 + 2 + 0 (internal don't count for user interaction) + 11 = 34 public/external/view functions. Meets requirement.
}
```