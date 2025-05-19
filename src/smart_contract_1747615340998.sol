Okay, here is a Solidity smart contract concept: the "Quantum Vault of Conditional Release".

This contract acts as a vault that can hold Ether and various ERC-20 tokens. Its key feature is a sophisticated release mechanism governed by internal *states*, defined *conditions*, and *withdrawal rules*. Withdrawals are only possible if the vault is in a specific state and predefined conditions are met, potentially involving time locks, external data (simulated), internal flags, whitelisted addresses, or even holding specific NFTs. It also includes a delegation system for withdrawal rights and a basic challenge mechanism.

This goes beyond standard time locks, multi-sigs, or simple staking by introducing a dynamic state machine and highly customizable, composite conditions for asset release.

---

**Quantum Vault of Conditional Release**

**Outline:**

1.  **Pragma & Imports:** Specify compiler version and import necessary interfaces (ERC20, ERC721).
2.  **Error Definitions:** Custom errors for clarity and gas efficiency.
3.  **Events:** Define events for significant actions (deposits, withdrawals, state changes, challenges, etc.).
4.  **Enums:** Define possible vault states, condition types, and challenge types.
5.  **Structs:** Define structures for conditions, state transition rules, withdrawal rules, delegated rights, challenges, and NFT requirements.
6.  **State Variables:**
    *   Owner and Manager addresses.
    *   Current vault state.
    *   Mappings for ETH and ERC20 balances.
    *   Mappings to store defined conditions, state transition rules, and withdrawal rules.
    *   Mapping for granted delegated withdrawal rights.
    *   Mapping to track active challenges.
    *   Mapping for internal flags used in conditions.
    *   Mapping for whitelisted addresses used in conditions/rules.
    *   Mapping for required NFT collection conditions.
    *   Counters for unique IDs (conditions, rules, challenges).
7.  **Modifiers:** Custom modifiers for access control (`onlyOwner`, `onlyManager`, `onlyAuthorizedExecutor`).
8.  **Constructor:** Initialize owner and starting state.
9.  **Receive & Fallback:** Allow receiving Ether.
10. **Core Logic:**
    *   Deposit functions (ETH, ERC20).
    *   Condition Management (define, update, remove, check).
    *   State Management (define transitions, attempt transitions, query state).
    *   Withdrawal Rule Management (define, update, remove).
    *   Delegation Management (grant, revoke, query).
    *   Withdrawal Execution (the core complex function checking state, rules, conditions, delegation).
    *   Challenge Mechanism (initiate, resolve, query).
    *   Auxiliary Condition Components (internal flags, whitelists, NFT requirements - add/remove/query).
    *   View functions to query contract state and definitions.

---

**Function Summary (Approx. 30+ Functions):**

1.  `constructor()`: Initializes the contract with owner and initial state.
2.  `receive()`: Allows receiving native Ether.
3.  `depositERC20(address token, uint256 amount)`: Allows depositing a specified ERC-20 token.
4.  `defineCondition(bytes32 conditionId, Condition memory cond)`: Owner/Manager defines a complex condition using a struct (time, block, external data, internal state, etc.).
5.  `updateCondition(bytes32 conditionId, Condition memory cond)`: Owner/Manager updates an existing condition.
6.  `removeCondition(bytes32 conditionId)`: Owner/Manager removes a condition definition.
7.  `checkConditionMet(bytes32 conditionId)`: View function to check if a specific condition is currently met.
8.  `defineStateTransition(VaultState fromState, VaultState toState, bytes32 requiredConditionId)`: Owner/Manager defines a rule for transitioning between states, requiring a specific condition to be met.
9.  `updateStateTransition(VaultState fromState, VaultState toState, bytes32 requiredConditionId)`: Owner/Manager updates a state transition rule.
10. `removeStateTransition(VaultState fromState, VaultState toState)`: Owner/Manager removes a state transition rule.
11. `attemptStateTransition()`: Any user can call this; the contract checks if any defined transition rules from the current state are met based on their required conditions and updates the state if so.
12. `defineWithdrawalRule(bytes32 ruleId, WithdrawalRule memory rule)`: Owner/Manager defines *what* can be withdrawn (asset, amount/percentage, recipient constraints) when specific conditions are met and the vault is in a certain state.
13. `updateWithdrawalRule(bytes32 ruleId, WithdrawalRule memory rule)`: Owner/Manager updates a withdrawal rule.
14. `removeWithdrawalRule(bytes32 ruleId)`: Owner/Manager removes a withdrawal rule.
15. `grantDelegatedWithdrawalRight(address delegatee, bytes32 ruleId, uint256 validUntil)`: Owner/Manager grants a specific address the right to execute a *specific withdrawal rule* on behalf of eligible recipients, valid until a certain timestamp.
16. `revokeDelegatedWithdrawalRight(address delegatee, bytes32 ruleId)`: Owner/Manager revokes a previously granted delegated right.
17. `executeWithdrawal(address recipient, bytes32 ruleId, address token, uint256 amount)`: This is the core withdrawal function. It checks:
    *   If the caller is the owner, manager, or a delegate with rights for `ruleId`.
    *   If the current vault state permits execution of `ruleId`.
    *   If all conditions required by `ruleId` are met.
    *   If the `recipient` is valid according to `ruleId`.
    *   If the requested `amount` is permitted by `ruleId` (e.g., fixed, percentage of balance, up to a max).
    *   If the contract has sufficient balance of `token` (or ETH).
    *   Transfers the assets if all checks pass.
18. `addRequiredNFTCollection(address collectionAddress, uint256 minBalance, bytes32 conditionId)`: Owner/Manager defines a specific NFT collection and minimum balance required for a *condition* to be met.
19. `removeRequiredNFTCollection(address collectionAddress, bytes32 conditionId)`: Owner/Manager removes an NFT collection requirement from a condition.
20. `setInternalFlag(bytes32 flagId, bool value)`: Owner/Manager sets an internal boolean flag that can be used as a condition type.
21. `addAddressToWhitelist(address account, bytes32 context)`: Owner/Manager adds an address to a named whitelist, which can be used in conditions or withdrawal rules.
22. `removeAddressFromWhitelist(address account, bytes32 context)`: Owner/Manager removes an address from a whitelist.
23. `initiateChallenge(bytes32 subjectId, ChallengeType cType)`: Allows a privileged user (e.g., owner/manager, or perhaps one defined in rules) to challenge a state transition or the evaluation of a condition, potentially pausing related actions and requiring a bond.
24. `resolveChallenge(bytes32 challengeId, bool challengerWon)`: Owner/Manager resolves an active challenge, potentially releasing bonds and updating state/conditions based on the resolution.
25. `setManager(address managerAddress)`: Owner sets a manager who can perform certain control functions.
26. `removeManager()`: Owner removes the manager.
27. `getETHBalance()`: View function for the contract's ETH balance.
28. `getERC20Balance(address token)`: View function for a specific ERC-20 token balance.
29. `getCurrentState()`: View function for the vault's current state.
30. `queryCondition(bytes32 conditionId)`: View function to get details of a defined condition.
31. `queryStateTransition(VaultState fromState, VaultState toState)`: View function to get details of a state transition rule.
32. `queryWithdrawalRule(bytes32 ruleId)`: View function to get details of a withdrawal rule.
33. `queryDelegatedRight(address delegatee, bytes32 ruleId)`: View function to check details of a specific delegated right.
34. `queryNFTRequirement(bytes32 conditionId)`: View function to get NFT requirements for a condition.
35. `queryInternalFlag(bytes32 flagId)`: View function to get the value of an internal flag.
36. `queryAddressWhitelist(bytes32 context)`: View function to list addresses in a specific whitelist (might return an array or allow checking membership).

*(Note: Some functions might be internal helpers not exposed publicly, but the summary aims for external interactions. The specific implementation details (like how 'ExternalSignalRequired' or complex 'NFT' conditions are checked, or the full challenge mechanism) would add further complexity, but the structure supports them.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Needed if we want the contract to receive NFTs directly, though we'll focus on checking balances
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline ---
// 1. Pragma & Imports
// 2. Error Definitions
// 3. Events
// 4. Enums (VaultState, ConditionType, ChallengeType)
// 5. Structs (Condition, StateTransitionRule, WithdrawalRule, DelegatedRight, Challenge, NFTRequirement)
// 6. State Variables (owner, manager, state, balances, conditions, transitions, rules, delegations, challenges, flags, whitelists, nft requirements, counters)
// 7. Modifiers (onlyOwner, onlyManager, onlyAuthorizedExecutor)
// 8. Constructor
// 9. Receive & Fallback (ETH deposit)
// 10. Core Logic Functions (Deposit, Condition Management, State Management, Rule Management, Delegation, Withdrawal Execution, Challenge, Auxiliary Condition Components, View Functions)

// --- Function Summary ---
// 01. constructor(): Initialize owner, initial state.
// 02. receive(): Allow ETH deposit.
// 03. depositERC20(address token, uint256 amount): Deposit specific ERC20.
// 04. defineCondition(bytes32 conditionId, Condition memory cond): Define a reusable condition.
// 05. updateCondition(bytes32 conditionId, Condition memory cond): Update a condition.
// 06. removeCondition(bytes32 conditionId): Remove a condition definition.
// 07. checkConditionMet(bytes32 conditionId): View check if condition is met.
// 08. defineStateTransition(VaultState fromState, VaultState toState, bytes32 requiredConditionId): Define rule for state changes.
// 09. updateStateTransition(VaultState fromState, VaultState toState, bytes32 requiredConditionId): Update state transition rule.
// 10. removeStateTransition(VaultState fromState, VaultState toState): Remove state transition rule.
// 11. attemptStateTransition(): Trigger state change if rules/conditions met.
// 12. defineWithdrawalRule(bytes32 ruleId, WithdrawalRule memory rule): Define what can be withdrawn under states/conditions.
// 13. updateWithdrawalRule(bytes32 ruleId, WithdrawalRule memory rule): Update a withdrawal rule.
// 14. removeWithdrawalRule(bytes32 ruleId): Remove a withdrawal rule.
// 15. grantDelegatedWithdrawalRight(address delegatee, bytes32 ruleId, uint256 validUntil): Grant specific rule execution right to a delegatee.
// 16. revokeDelegatedWithdrawalRight(address delegatee, bytes32 ruleId): Revoke delegated right.
// 17. executeWithdrawal(address recipient, bytes32 ruleId, address token, uint256 amount): Core function to execute withdrawal based on rules, state, conditions, delegation.
// 18. addRequiredNFTCollection(address collectionAddress, uint256 minBalance, bytes32 conditionId): Add NFT holding requirement to a condition.
// 19. removeRequiredNFTCollection(address collectionAddress, bytes32 conditionId): Remove NFT requirement from a condition.
// 20. setInternalFlag(bytes32 flagId, bool value): Set internal boolean flag for conditions.
// 21. addAddressToWhitelist(address account, bytes32 context): Add address to a named whitelist.
// 22. removeAddressFromWhitelist(address account, bytes32 context): Remove address from whitelist.
// 23. initiateChallenge(bytes32 subjectId, ChallengeType cType): Initiate a challenge against state transition or condition.
// 24. resolveChallenge(bytes32 challengeId, bool challengerWon): Resolve an active challenge.
// 25. setManager(address managerAddress): Set contract manager.
// 26. removeManager(): Remove contract manager.
// 27. getETHBalance(): View contract ETH balance.
// 28. getERC20Balance(address token): View contract ERC20 balance.
// 29. getCurrentState(): View current vault state.
// 30. queryCondition(bytes32 conditionId): View condition details.
// 31. queryStateTransition(VaultState fromState, VaultState toState): View state transition rule details.
// 32. queryWithdrawalRule(bytes32 ruleId): View withdrawal rule details.
// 33. queryDelegatedRight(address delegatee, bytes32 ruleId): View delegated right details.
// 34. queryNFTRequirement(bytes32 conditionId): View NFT requirement details for a condition.
// 35. queryInternalFlag(bytes32 flagId): View internal flag value.
// 36. isWhitelisted(address account, bytes32 context): View if address is in a whitelist.

contract QuantumVaultOfConditionalRelease is ReentrancyGuard, IERC721Receiver { // Implement IERC721Receiver just in case, although core logic checks external balances

    // --- Error Definitions ---
    error Unauthorized();
    error InvalidStateTransition(VaultState currentState, VaultState requestedState);
    error ConditionNotMet(bytes32 conditionId);
    error RuleNotFound(bytes32 ruleId);
    error WithdrawalRuleNotApplicable(VaultState currentState);
    error RecipientNotPermitted(address recipient);
    error InsufficientBalance(address token, uint256 requested, uint256 available);
    error WithdrawalAmountExceedsRuleLimit(uint256 requested, uint256 allowed);
    error DelegationNotFound();
    error DelegationExpired(uint256 validUntil);
    error ConditionNotFound(bytes32 conditionId);
    error StateTransitionNotFound(VaultState fromState, VaultState toState);
    error ChallengeNotFound(bytes32 challengeId);
    error ChallengeAlreadyActive(bytes32 subjectId);
    error ChallengeNotActive(bytes32 challengeId);
    error InvalidChallengeResolution();
    error NFTSenderMismatch();
    error NFTRequirementNotFound(bytes32 conditionId);
    error FlagNotFound(bytes32 flagId);
    error WhitelistContextNotFound(bytes32 context);


    // --- Events ---
    event EthDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed sender, address indexed token, uint256 amount);
    event ConditionDefined(bytes32 indexed conditionId, ConditionType conditionType);
    event ConditionUpdated(bytes32 indexed conditionId);
    event ConditionRemoved(bytes32 indexed conditionId);
    event StateTransitionDefined(VaultState indexed fromState, VaultState indexed toState, bytes32 indexed requiredConditionId);
    event StateTransitionRemoved(VaultState indexed fromState, VaultState indexed toState);
    event StateTransitionAttempted(address indexed caller, VaultState indexed fromState);
    event StateChanged(VaultState indexed oldState, VaultState indexed newState);
    event WithdrawalRuleDefined(bytes32 indexed ruleId, VaultState indexed requiredState);
    event WithdrawalRuleUpdated(bytes32 indexed ruleId);
    event WithdrawalRuleRemoved(bytes32 indexed ruleId);
    event DelegatedRightGranted(address indexed delegatee, bytes32 indexed ruleId, uint256 validUntil);
    event DelegatedRightRevoked(address indexed delegatee, bytes32 indexed ruleId);
    event WithdrawalExecuted(address indexed recipient, address indexed token, uint256 amount, bytes32 indexed ruleId);
    event ChallengeInitiated(bytes32 indexed challengeId, bytes32 indexed subjectId, ChallengeType challengeType, address indexed challenger);
    event ChallengeResolved(bytes32 indexed challengeId, bool challengerWon);
    event ManagerUpdated(address indexed oldManager, address indexed newManager);
    event InternalFlagSet(bytes32 indexed flagId, bool value);
    event AddressAddedToWhitelist(address indexed account, bytes32 indexed context);
    event AddressRemovedFromWhitelist(address indexed account, bytes32 indexed context);
    event NFTRequirementAdded(bytes32 indexed conditionId, address indexed collection, uint256 minBalance);
    event NFTRequirementRemoved(bytes32 indexed conditionId, address indexed collection);


    // --- Enums ---
    enum VaultState {
        Locked,             // Default state, minimal withdrawals allowed
        ConditionalRelease, // Withdrawals possible if specific conditions met
        TimelockedPartial,  // Gradual release or timed partial access
        DelegatedAccess,    // Specific withdrawal rights are delegated
        ChallengedState,    // State is under dispute
        Emergency           // Emergency state (maybe limited owner access?)
    }

    enum ConditionType {
        AlwaysTrue,           // For simple rules not needing a condition
        BlockNumberReached,   // Condition met if block.number >= targetBlock
        TimestampReached,     // Condition met if block.timestamp >= targetTimestamp
        InternalFlagTrue,     // Condition met if a specific internal flag is true
        ExternalSignalRequired, // Placeholder: Represents a condition dependent on external data/oracle (needs off-chain input or another contract call)
        AddressWhitelisted,   // Condition met if a specific address is in a whitelist context
        NFTHoldingRequired    // Condition met if a specific address holds required NFTs
    }

    enum ChallengeType {
        StateTransitionChallenge, // Challenge a potential state transition
        ConditionEvaluationChallenge // Challenge whether a specific condition was truly met
        // Could add more types, e.g., RuleValidityChallenge
    }


    // --- Structs ---
    struct Condition {
        ConditionType conditionType;
        uint256 targetValue; // e.g., block number, timestamp, min NFT balance
        bytes32 targetId;    // e.g., flagId, whitelist context, NFT collection address
        address targetAddress; // e.g., address to check whitelist for, address to check NFT balance for
        bool isMet; // Optional: Could cache state, but risky. Prefer re-evaluating.
        // Could add dependency on *other* conditions via bytes32[] requiredConditions
    }

    struct StateTransitionRule {
        bytes32 requiredConditionId;
        bool exists; // To check if rule is defined
    }

    struct WithdrawalRule {
        VaultState requiredState;         // Vault must be in this state
        bytes32 requiredConditionId;      // This condition must be met
        address permittedRecipient;       // Specific recipient allowed, or address(0) for any
        uint256 maxAmountPerWithdrawal;   // Max amount per single execution call (0 for no limit)
        bytes32 permittedTokenContext;    // Context for whitelisted tokens (e.g., "releasable", "restricted") - adds complexity, omitted for simplicity in initial draft, using specific token address instead
        address permittedTokenAddress;    // Specific token allowed (address(0) for ETH)
        // Could add percentage limits, total withdrawal caps per rule, etc.
        bool exists; // To check if rule is defined
    }

    struct DelegatedRight {
        bytes32 ruleId;
        uint256 validUntil;
        bool exists;
    }

    struct Challenge {
        bytes32 subjectId; // What is being challenged (e.g., transition rule ID, condition ID)
        ChallengeType challengeType;
        address challenger;
        uint256 initiationBlock;
        uint256 bondAmount; // Bond required to challenge (adds complexity, omitted in struct for now)
        bool resolved;
        bool challengerWon; // Result of resolution
        bool exists;
    }

    struct NFTRequirement {
        address collectionAddress;
        uint256 minBalance;
        bool exists;
    }


    // --- State Variables ---
    address public owner;
    address public manager;
    VaultState public currentVaultState;

    // Balances
    mapping(address => uint256) private tokenBalances; // 0x0 for ETH

    // Definitions
    mapping(bytes32 => Condition) public conditions;
    mapping(VaultState => mapping(VaultState => StateTransitionRule)) public stateTransitions;
    mapping(bytes32 => WithdrawalRule) public withdrawalRules;

    // Runtime State
    mapping(address => mapping(bytes32 => DelegatedRight)) public delegatedRights; // delegatee => ruleId => right
    mapping(bytes32 => Challenge) public activeChallenges; // subjectId => challenge details (only one active challenge per subject)

    // Condition Data
    mapping(bytes32 => bool) public internalFlags;
    mapping(bytes32 => mapping(address => bool)) public addressWhitelists; // context => address => isWhitelisted
    mapping(bytes32 => NFTRequirement) public conditionNFTRequirements; // conditionId => NFTRequirement (Simplified: one NFT req per condition)

    // Counters (Could use keccak256(abi.encode(params)) for IDs instead of counters)
    // uint256 private nextConditionId = 1;
    // uint256 private nextRuleId = 1;
    // uint256 private nextChallengeId = 1;


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyManager() {
        if (msg.sender != manager && msg.sender != owner) revert Unauthorized();
        _;
    }

    // Checks if caller is owner, manager, or a delegate with valid rights for the ruleId
    modifier onlyAuthorizedExecutor(bytes32 ruleId) {
        if (msg.sender != owner && msg.sender != manager) {
            DelegatedRight memory delegateRight = delegatedRights[msg.sender][ruleId];
            if (!delegateRight.exists || delegateRight.validUntil < block.timestamp) {
                 revert Unauthorized();
            }
        }
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        currentVaultState = VaultState.Locked;
        emit ManagerUpdated(address(0), address(0)); // Indicate no manager initially
    }


    // --- Receive & Fallback ---
    receive() external payable nonReentrant {
        tokenBalances[address(0)] += msg.value;
        emit EthDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        // Optional: Revert or handle explicitly if ETH is the only expected payable
        revert("Fallback not supported. Use receive() for ETH.");
    }


    // --- Core Logic: Deposit ---

    /// @notice Deposits ERC20 tokens into the vault. Requires prior approval.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external nonReentrant {
        if (amount == 0) return;
        IERC20 erc20 = IERC20(token);

        // Pull tokens from the sender
        uint256 initialBalance = erc20.balanceOf(address(this));
        bool success = erc20.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert("ERC20 transferFrom failed"); // More specific error possible
        }
        uint256 receivedAmount = erc20.balanceOf(address(this)) - initialBalance;
        if (receivedAmount != amount) {
             // ERC20 standard doesn't guarantee return value, check balance change
             // This check might be problematic with deflationary/rebasing tokens.
             // For robust handling, integrate with permit2 or similar.
             // Simplified check for now: assume amount == receivedAmount on success
             revert("ERC20 amount mismatch or transfer failed");
        }


        tokenBalances[token] += amount;
        emit ERC20Deposited(msg.sender, token, amount);
    }


    // --- Core Logic: Condition Management ---

    /// @notice Defines a new condition that can be used in state transitions or withdrawal rules.
    /// @param conditionId A unique identifier for the condition.
    /// @param cond The Condition struct containing details.
    function defineCondition(bytes32 conditionId, Condition memory cond) external onlyManager {
        if (conditions[conditionId].conditionType != ConditionType.AlwaysTrue) {
            // Check if ID is already used, AlwaysTrue is the default state
            revert("Condition ID already exists");
        }
        conditions[conditionId] = cond;
        emit ConditionDefined(conditionId, cond.conditionType);
    }

    /// @notice Updates an existing condition definition.
    /// @param conditionId The identifier of the condition to update.
    /// @param cond The updated Condition struct.
    function updateCondition(bytes32 conditionId, Condition memory cond) external onlyManager {
        if (conditions[conditionId].conditionType == ConditionType.AlwaysTrue) {
             // Check if ID exists by checking default state
            revert ConditionNotFound(conditionId);
        }
        conditions[conditionId] = cond;
        emit ConditionUpdated(conditionId);
    }

    /// @notice Removes a condition definition.
    /// @param conditionId The identifier of the condition to remove.
    function removeCondition(bytes32 conditionId) external onlyManager {
         if (conditions[conditionId].conditionType == ConditionType.AlwaysTrue) {
            revert ConditionNotFound(conditionId);
        }
        delete conditions[conditionId]; // Resets to default (AlwaysTrue)
        emit ConditionRemoved(conditionId);
    }

    /// @notice Checks if a specific condition is currently met based on its definition.
    /// @param conditionId The identifier of the condition to check.
    /// @return True if the condition is met, false otherwise.
    function checkConditionMet(bytes32 conditionId) public view returns (bool) {
        Condition memory cond = conditions[conditionId];
        if (cond.conditionType == ConditionType.AlwaysTrue && conditionId != bytes32(0)) {
             // conditionId 0 can be used for 'always true', otherwise check if defined
             revert ConditionNotFound(conditionId);
        }

        // Basic simulation of condition types
        if (cond.conditionType == ConditionType.AlwaysTrue) {
            return true; // Useful for rules always applicable in a state
        } else if (cond.conditionType == ConditionType.BlockNumberReached) {
            return block.number >= cond.targetValue;
        } else if (cond.conditionType == ConditionType.TimestampReached) {
            return block.timestamp >= cond.targetValue;
        } else if (cond.conditionType == ConditionType.InternalFlagTrue) {
             if (!internalFlags[cond.targetId]) revert FlagNotFound(cond.targetId);
            return internalFlags[cond.targetId];
        } else if (cond.conditionType == ConditionType.AddressWhitelisted) {
            if (!addressWhitelists[cond.targetId][cond.targetAddress]) revert WhitelistContextNotFound(cond.targetId);
            return addressWhitelists[cond.targetId][cond.targetAddress];
        } else if (cond.conditionType == ConditionType.NFTHoldingRequired) {
             NFTRequirement memory nftReq = conditionNFTRequirements[conditionId];
             if (!nftReq.exists) revert NFTRequirementNotFound(conditionId); // NFT condition requires separate definition
             // Note: cond.targetAddress should be the address whose balance is checked
             return IERC721(nftReq.collectionAddress).balanceOf(cond.targetAddress) >= nftReq.minBalance;
        } else if (cond.conditionType == ConditionType.ExternalSignalRequired) {
            // TODO: Implement logic for external signal check.
            // This would typically involve checking a value set by an oracle or another contract.
            // For now, this condition type will always evaluate to false in this simulation.
            return false;
        }
        // Add checks for active challenges against this condition evaluation
        if (activeChallenges[conditionId].exists && activeChallenges[conditionId].challengeType == ChallengeType.ConditionEvaluationChallenge) {
             // While challenged, the condition evaluation might be paused or reversed
             // Simple approach: condition is considered NOT met while challenged
             return false;
        }

        return false; // Should not reach here with defined types
    }


    // --- Core Logic: State Management ---

    /// @notice Defines a rule allowing transition from one state to another if a condition is met.
    /// @param fromState The current state.
    /// @param toState The target state.
    /// @param requiredConditionId The condition required for this transition. Use bytes32(0) for always true.
    function defineStateTransition(VaultState fromState, VaultState toState, bytes32 requiredConditionId) external onlyManager {
        if (fromState == toState) revert("Cannot transition to the same state");
        // Check if the transition rule already exists by checking 'exists' flag (assuming default is false)
        if (stateTransitions[fromState][toState].exists) {
            revert("State transition rule already defined");
        }
        stateTransitions[fromState][toState] = StateTransitionRule(requiredConditionId, true);
        emit StateTransitionDefined(fromState, toState, requiredConditionId);
    }

     /// @notice Updates an existing state transition rule.
    /// @param fromState The current state.
    /// @param toState The target state.
    /// @param requiredConditionId The new condition required for this transition.
    function updateStateTransition(VaultState fromState, VaultState toState, bytes32 requiredConditionId) external onlyManager {
        if (fromState == toState) revert("Cannot transition to the same state");
        if (!stateTransitions[fromState][toState].exists) {
             revert StateTransitionNotFound(fromState, toState);
        }
        stateTransitions[fromState][toState].requiredConditionId = requiredConditionId;
        emit StateTransitionUpdated(fromState, toState, requiredConditionId); // Emit with new condition ID
    }

    /// @notice Removes a state transition rule.
    /// @param fromState The current state.
    /// @param toState The target state.
    function removeStateTransition(VaultState fromState, VaultState toState) external onlyManager {
         if (!stateTransitions[fromState][toState].exists) {
             revert StateTransitionNotFound(fromState, toState);
        }
        delete stateTransitions[fromState][toState]; // Resets to default (false)
        emit StateTransitionRemoved(fromState, toState);
    }


    /// @notice Attempts to transition the vault state based on defined rules and met conditions.
    /// Any user can call this, but the transition only happens if a rule from the current state is met.
    function attemptStateTransition() external {
        VaultState _currentState = currentVaultState;

        // Check for active challenge on the *current* state transitions
        if (activeChallenges[bytes32(uint256(_currentState))].exists &&
            activeChallenges[bytes32(uint256(_currentState))].challengeType == ChallengeType.StateTransitionChallenge) {
             revert ChallengeAlreadyActive(bytes32(uint256(_currentState)));
        }

        emit StateTransitionAttempted(msg.sender, _currentState);

        // Iterate through possible target states (manual iteration required in Solidity)
        // For simplicity, we'll check predefined common transitions or require specific transition calls.
        // A more complex system would iterate over *all* possible VaultState values, which is inefficient.
        // Let's check transitions to ConditionalRelease, TimelockedPartial, DelegatedAccess, Emergency as examples.

        VaultState[] memory possibleTargetStates = new VaultState[](4);
        possibleTargetStates[0] = VaultState.ConditionalRelease;
        possibleTargetStates[1] = VaultState.TimelockedPartial;
        possibleTargetStates[2] = VaultState.DelegatedAccess;
        possibleTargetStates[3] = VaultState.Emergency;


        for (uint i = 0; i < possibleTargetStates.length; i++) {
            VaultState targetState = possibleTargetStates[i];
            StateTransitionRule storage transitionRule = stateTransitions[_currentState][targetState];

            if (transitionRule.exists) {
                bool conditionMet = checkConditionMet(transitionRule.requiredConditionId);

                 // Check for active challenge on *this specific* transition rule
                bytes32 transitionSubjectId = keccak256(abi.encode(_currentState, targetState));
                 if (activeChallenges[transitionSubjectId].exists &&
                    activeChallenges[transitionSubjectId].challengeType == ChallengeType.StateTransitionChallenge) {
                     // Transition is blocked while challenged
                     continue; // Check other transitions
                 }

                if (conditionMet) {
                    currentVaultState = targetState;
                    emit StateChanged(_currentState, currentVaultState);
                    return; // Transition successful, exit
                }
            }
        }

        // If no transition rules were met for the current state, the state remains unchanged.
    }

    /// @notice Gets the current state of the vault.
    function getCurrentState() external view returns (VaultState) {
        return currentVaultState;
    }


    // --- Core Logic: Withdrawal Rule Management ---

    /// @notice Defines a rule specifying allowed withdrawals under certain conditions and state.
    /// @param ruleId A unique identifier for the rule.
    /// @param rule The WithdrawalRule struct containing details.
    function defineWithdrawalRule(bytes32 ruleId, WithdrawalRule memory rule) external onlyManager {
        if (withdrawalRules[ruleId].exists) {
            revert("Withdrawal rule ID already exists");
        }
        // Basic validation: check if required condition exists (unless it's bytes32(0) for always true)
        if (rule.requiredConditionId != bytes32(0) && conditions[rule.requiredConditionId].conditionType == ConditionType.AlwaysTrue && rule.requiredConditionId != bytes32(0)) {
            revert ConditionNotFound(rule.requiredConditionId);
        }

        withdrawalRules[ruleId] = rule;
        emit WithdrawalRuleDefined(ruleId, rule.requiredState);
    }

    /// @notice Updates an existing withdrawal rule definition.
    /// @param ruleId The identifier of the rule to update.
    /// @param rule The updated WithdrawalRule struct.
    function updateWithdrawalRule(bytes32 ruleId, WithdrawalRule memory rule) external onlyManager {
        if (!withdrawalRules[ruleId].exists) {
            revert RuleNotFound(ruleId);
        }
         // Basic validation: check if required condition exists (unless it's bytes32(0) for always true)
        if (rule.requiredConditionId != bytes32(0) && conditions[rule.requiredConditionId].conditionType == ConditionType.AlwaysTrue && rule.requiredConditionId != bytes32(0)) {
            revert ConditionNotFound(rule.requiredConditionId);
        }

        withdrawalRules[ruleId] = rule;
        emit WithdrawalRuleUpdated(ruleId);
    }

    /// @notice Removes a withdrawal rule definition.
    /// @param ruleId The identifier of the rule to remove.
    function removeWithdrawalRule(bytes32 ruleId) external onlyManager {
        if (!withdrawalRules[ruleId].exists) {
            revert RuleNotFound(ruleId);
        }
        delete withdrawalRules[ruleId]; // Resets to default (false)
        emit WithdrawalRuleRemoved(ruleId);
    }


    // --- Core Logic: Delegation ---

    /// @notice Grants a delegatee the right to execute a specific withdrawal rule.
    /// @param delegatee The address receiving the delegation.
    /// @param ruleId The identifier of the withdrawal rule the delegatee can execute.
    /// @param validUntil The timestamp until which the delegation is valid (0 for infinite).
    function grantDelegatedWithdrawalRight(address delegatee, bytes32 ruleId, uint256 validUntil) external onlyManager {
        if (!withdrawalRules[ruleId].exists) {
            revert RuleNotFound(ruleId);
        }
        delegatedRights[delegatee][ruleId] = DelegatedRight(ruleId, validUntil, true);
        emit DelegatedRightGranted(delegatee, ruleId, validUntil);
    }

    /// @notice Revokes a previously granted delegated withdrawal right.
    /// @param delegatee The address whose right is being revoked.
    /// @param ruleId The identifier of the withdrawal rule the delegation was for.
    function revokeDelegatedWithdrawalRight(address delegatee, bytes32 ruleId) external onlyManager {
        if (!delegatedRights[delegatee][ruleId].exists) {
            revert DelegationNotFound();
        }
        delete delegatedRights[delegatee][ruleId]; // Resets to default (false)
        emit DelegatedRightRevoked(delegatee, ruleId);
    }


    // --- Core Logic: Withdrawal Execution ---

    /// @notice Executes a withdrawal based on a predefined withdrawal rule.
    /// @param recipient The address to send the assets to.
    /// @param ruleId The identifier of the withdrawal rule to apply.
    /// @param token The address of the token to withdraw (address(0) for ETH).
    /// @param amount The amount to withdraw.
    function executeWithdrawal(address recipient, bytes32 ruleId, address token, uint256 amount) external nonReentrant onlyAuthorizedExecutor(ruleId) {
        WithdrawalRule memory rule = withdrawalRules[ruleId];
        if (!rule.exists) {
            revert RuleNotFound(ruleId);
        }

        // 1. Check Vault State
        if (currentVaultState != rule.requiredState) {
            revert WithdrawalRuleNotApplicable(currentVaultState);
        }

        // 2. Check Required Condition
        if (rule.requiredConditionId != bytes32(0) && !checkConditionMet(rule.requiredConditionId)) {
            revert ConditionNotMet(rule.requiredConditionId);
        }

        // 3. Check Recipient Constraint
        if (rule.permittedRecipient != address(0) && recipient != rule.permittedRecipient) {
            revert RecipientNotPermitted(recipient);
        }

        // 4. Check Withdrawal Amount Limit (per execution)
        if (rule.maxAmountPerWithdrawal > 0 && amount > rule.maxAmountPerWithdrawal) {
            revert WithdrawalAmountExceedsRuleLimit(amount, rule.maxAmountPerWithdrawal);
        }

        // 5. Check Token and Balance
        if (rule.permittedTokenAddress != address(0) && rule.permittedTokenAddress != token) {
            revert("Withdrawal rule does not permit this token"); // Or specific error
        }
        if (tokenBalances[token] < amount) {
            revert InsufficientBalance(token, amount, tokenBalances[token]);
        }

         // Add checks for active challenges against this rule execution
        bytes32 ruleSubjectId = keccak256(abi.encode(ruleId));
        if (activeChallenges[ruleSubjectId].exists &&
            activeChallenges[ruleSubjectId].challengeType == ChallengeType.StateTransitionChallenge) { // Re-using type, could define RuleExecutionChallenge
             revert ChallengeAlreadyActive(ruleSubjectId);
        }


        // --- Execute Transfer ---
        tokenBalances[token] -= amount;

        if (token == address(0)) { // ETH
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) {
                // Refund balance if ETH transfer fails
                tokenBalances[token] += amount; // Refund
                revert("ETH transfer failed");
            }
        } else { // ERC20
            IERC20 erc20 = IERC20(token);
            bool success = erc20.transfer(recipient, amount);
             if (!success) {
                // Refund balance if ERC20 transfer fails
                tokenBalances[token] += amount; // Refund
                revert("ERC20 transfer failed");
            }
        }

        emit WithdrawalExecuted(recipient, token, amount, ruleId);
    }


    // --- Core Logic: Challenge Mechanism (Simplified) ---

    /// @notice Initiates a challenge against a state transition rule or a condition evaluation.
    /// @param subjectId Identifier of what is being challenged (e.g., encoded state transition, conditionId).
    /// @param cType The type of challenge.
    // Simplified: requires owner/manager to initiate challenge, no bond, immediate effect (blocking)
    function initiateChallenge(bytes32 subjectId, ChallengeType cType) external onlyManager {
        if (activeChallenges[subjectId].exists) {
            revert ChallengeAlreadyActive(subjectId);
        }

        activeChallenges[subjectId] = Challenge(
            subjectId,
            cType,
            msg.sender,
            block.number,
            0, // bondAmount (simplified)
            false, // resolved
            false, // challengerWon (initial)
            true // exists
        );

        emit ChallengeInitiated(subjectId, subjectId, cType, msg.sender);
    }

    /// @notice Resolves an active challenge.
    /// @param challengeId The identifier of the challenge (same as subjectId).
    /// @param challengerWon True if the challenger's claim is validated, false otherwise.
    // Simplified: only manager can resolve
    function resolveChallenge(bytes32 challengeId, bool challengerWon) external onlyManager {
        Challenge storage challenge = activeChallenges[challengeId];
        if (!challenge.exists || challenge.resolved) {
            revert ChallengeNotFound(challengeId);
        }

        // Basic validation: challengerWon must be meaningful based on challenge type
        // (e.g., if challenging a condition being met, winning means it WASN'T met)
        // Add more complex validation here if needed.

        challenge.resolved = true;
        challenge.challengerWon = challengerWon;

        // TODO: Implement logic based on resolution:
        // - If StateTransitionChallenge and challenger won: invalidate/reverse the transition if it happened? (Hard if state already changed)
        // - If ConditionEvaluationChallenge and challenger won: could affect future checkConditionMet calls (e.g., mark condition as false for a period).
        // Simplified: Resolution just records the outcome and removes the block.
        delete activeChallenges[challengeId]; // Remove the active block

        emit ChallengeResolved(challengeId, challengerWon);
    }


    // --- Core Logic: Auxiliary Condition Components ---

    /// @notice Defines an NFT holding requirement for a specific condition.
    /// @param collectionAddress The address of the ERC721 collection.
    /// @param minBalance The minimum number of NFTs from the collection required.
    /// @param conditionId The ID of the condition this requirement applies to. This condition MUST be of type NFTHoldingRequired.
    function addRequiredNFTCollection(address collectionAddress, uint256 minBalance, bytes32 conditionId) external onlyManager {
         Condition memory cond = conditions[conditionId];
         if (cond.conditionType != ConditionType.NFTHoldingRequired) {
              revert("Condition type must be NFTHoldingRequired");
         }
         if (conditionNFTRequirements[conditionId].exists) {
              revert("NFT requirement already exists for this condition");
         }

        conditionNFTRequirements[conditionId] = NFTRequirement(collectionAddress, minBalance, true);
        emit NFTRequirementAdded(conditionId, collectionAddress, minBalance);
    }

    /// @notice Removes an NFT holding requirement from a condition.
     /// @param conditionId The ID of the condition to remove the requirement from.
    function removeRequiredNFTCollection(bytes32 conditionId) external onlyManager {
         if (!conditionNFTRequirements[conditionId].exists) {
              revert NFTRequirementNotFound(conditionId);
         }
         delete conditionNFTRequirements[conditionId];
         emit NFTRequirementRemoved(conditionId, conditionNFTRequirements[conditionId].collectionAddress); // Emit with old address before deleting
    }

    /// @notice Sets the value of an internal boolean flag used by conditions.
    /// @param flagId The identifier for the flag.
    /// @param value The boolean value to set.
    function setInternalFlag(bytes32 flagId, bool value) external onlyManager {
        internalFlags[flagId] = value;
        emit InternalFlagSet(flagId, value);
    }

    /// @notice Adds an address to a named whitelist.
    /// @param account The address to add.
    /// @param context The name/context of the whitelist (e.g., "approvedExecutors", "premiumUsers").
    function addAddressToWhitelist(address account, bytes32 context) external onlyManager {
        addressWhitelists[context][account] = true;
        emit AddressAddedToWhitelist(account, context);
    }

    /// @notice Removes an address from a named whitelist.
    /// @param account The address to remove.
    /// @param context The name/context of the whitelist.
    function removeAddressFromWhitelist(address account, bytes32 context) external onlyManager {
        delete addressWhitelists[context][account];
        emit AddressRemovedFromWhitelist(account, context);
    }


    // --- Admin/Manager Functions ---

    /// @notice Sets the manager address. Only callable by the owner.
    /// @param managerAddress The address to set as manager.
    function setManager(address managerAddress) external onlyOwner {
        address oldManager = manager;
        manager = managerAddress;
        emit ManagerUpdated(oldManager, manager);
    }

    /// @notice Removes the current manager. Only callable by the owner.
    function removeManager() external onlyOwner {
         address oldManager = manager;
        manager = address(0);
        emit ManagerUpdated(oldManager, address(0));
    }


    // --- View Functions ---

    /// @notice Gets the contract's native ETH balance.
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
        // return tokenBalances[address(0)]; // Could also use the internal mapping if kept perfectly synced
    }

    /// @notice Gets the contract's balance for a specific ERC-20 token.
    /// @param token The address of the ERC-20 token.
    /// @return The balance of the token held by the contract.
    function getERC20Balance(address token) external view returns (uint256) {
        return tokenBalances[token];
        // return IERC20(token).balanceOf(address(this)); // Alternative, more reliable source of truth
    }

    /// @notice Queries the details of a defined condition.
    /// @param conditionId The identifier of the condition.
    /// @return The Condition struct details.
    function queryCondition(bytes32 conditionId) external view returns (Condition memory) {
        if (conditions[conditionId].conditionType == ConditionType.AlwaysTrue && conditionId != bytes32(0)) {
            revert ConditionNotFound(conditionId);
        }
        return conditions[conditionId];
    }

     /// @notice Queries the details of a state transition rule.
    /// @param fromState The starting state.
    /// @param toState The target state.
    /// @return The StateTransitionRule struct details.
    function queryStateTransition(VaultState fromState, VaultState toState) external view returns (StateTransitionRule memory) {
         if (!stateTransitions[fromState][toState].exists) {
              revert StateTransitionNotFound(fromState, toState);
         }
        return stateTransitions[fromState][toState];
    }

    /// @notice Queries the details of a withdrawal rule.
    /// @param ruleId The identifier of the rule.
    /// @return The WithdrawalRule struct details.
    function queryWithdrawalRule(bytes32 ruleId) external view returns (WithdrawalRule memory) {
        if (!withdrawalRules[ruleId].exists) {
            revert RuleNotFound(ruleId);
        }
        return withdrawalRules[ruleId];
    }

    /// @notice Queries the details of a specific delegated withdrawal right.
    /// @param delegatee The address of the delegatee.
    /// @param ruleId The identifier of the rule.
    /// @return The DelegatedRight struct details.
    function queryDelegatedRight(address delegatee, bytes32 ruleId) external view returns (DelegatedRight memory) {
         if (!delegatedRights[delegatee][ruleId].exists) {
             revert DelegationNotFound();
         }
        return delegatedRights[delegatee][ruleId];
    }

    /// @notice Queries the NFT requirement details for a condition.
    /// @param conditionId The identifier of the condition.
    /// @return The NFTRequirement struct details.
    function queryNFTRequirement(bytes32 conditionId) external view returns (NFTRequirement memory) {
         if (!conditionNFTRequirements[conditionId].exists) {
              revert NFTRequirementNotFound(conditionId);
         }
        return conditionNFTRequirements[conditionId];
    }

    /// @notice Gets the value of an internal flag.
    /// @param flagId The identifier of the flag.
    /// @return The boolean value of the flag.
    function queryInternalFlag(bytes32 flagId) external view returns (bool) {
        // Accessing a non-existent key returns the default value (false for bool), which is fine.
        return internalFlags[flagId];
    }

    /// @notice Checks if an address is in a specific whitelist context.
    /// @param account The address to check.
    /// @param context The name/context of the whitelist.
    /// @return True if the address is whitelisted, false otherwise.
    function isWhitelisted(address account, bytes32 context) external view returns (bool) {
        // Accessing a non-existent key returns the default value (false for bool), which is fine.
        return addressWhitelists[context][account];
    }

    // --- IERC721Receiver Implementation ---
    // This allows the contract to receive NFTs. We might not need to *store* them,
    // but checking external balances for the NFTHoldingRequired condition is necessary.
    // Adding this just for robustness if NFTs were ever sent here directly.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        // Reject received NFTs by default, as the vault logic relies on checking *external* balances.
        // If the logic were to rely on *internal* NFT balance, this would change.
        revert NFTSenderMismatch(); // Generic error, can be more specific.
        // Or return IERC721Receiver.onERC721Received.selector; if you *do* want to accept them
    }
}
```