Okay, let's design a smart contract that goes beyond basic token interactions or standard DeFi primitives. We'll create a `QuantumVault` that acts as a multi-asset vault with advanced, dynamic access control based on verifiable off-chain data (simulated), user traits, reputation, and conditional delegation, incorporating concepts like simulated ZK proof verification and oracle-based rules.

**Concept: QuantumVault**

A vault holding multiple ERC-20 tokens where withdrawal access is highly conditional and personalized. Access rules depend on a combination of:
1.  **On-chain state:** Token balances, time, contract state.
2.  **User Traits/Credentials:** Verified attributes about the user (e.g., "accredited investor status", "verified age", "holds a specific external NFT", "completed KYC off-chain"). These traits are set by admins/oracles or verified by simulated ZK proofs.
3.  **Oracle Data (Simulated):** External data feeds (e.g., price feeds, market sentiment scores, AI predictions) influencing rule evaluation.
4.  **Reputation Score:** An internal score that changes based on verified positive or negative actions/traits.
5.  **Conditional Delegation:** Users can delegate *limited, rule-bound* access to others.
6.  **Attested Events:** Access can be triggered or blocked by verified off-chain events attested by an admin/oracle.

This contract aims to be advanced by combining:
*   Multi-token vault.
*   Sophisticated, rule-based access control engine.
*   Integration points for off-chain data verification (simulated ZK proofs, oracles).
*   User trait/identity management (simulated VC-like concept).
*   Internal reputation system.
*   Conditional access delegation.

---

**Outline and Function Summary**

**Contract:** `QuantumVault`

**Core Purpose:** A multi-token vault with dynamic, rule-based access control influenced by user traits, reputation, oracle data, and simulated zero-knowledge proofs/attested events.

**Sections:**
1.  State Variables & Structs
2.  Events
3.  Modifiers
4.  Admin & Setup Functions
5.  Core Vault Functions (Deposit/Withdraw)
6.  Access Control & Rule Management Functions
7.  User Trait & Reputation Management Functions
8.  ZK Proof & Oracle Interaction Functions (Simulated)
9.  Conditional Delegation Functions
10. Query Functions

**Function Summary (Minimum 20 functions):**

1.  `constructor(address[] initialAcceptedTokens)`: Initializes the contract owner and accepted tokens.
2.  `addAdmin(address _admin)`: Adds an address to the admin list. (Admin)
3.  `removeAdmin(address _admin)`: Removes an address from the admin list. (Owner)
4.  `addAcceptedToken(address _token)`: Adds an ERC-20 token address that the vault will accept. (Admin)
5.  `removeAcceptedToken(address _token)`: Removes an ERC-20 token address. (Admin)
6.  `deposit(address token, uint256 amount)`: Deposits a specified amount of an accepted token into the vault for the caller.
7.  `withdraw(address token, uint256 amount)`: Attempts to withdraw a specified amount of a token. This function triggers the dynamic access rule checks.
8.  `addWithdrawalRule(RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue)`: Adds a new global rule definition that can be applied to users/withdrawals. (Admin)
9.  `removeWithdrawalRule(bytes32 ruleId)`: Removes a global rule definition. (Admin)
10. `updateWithdrawalRule(bytes32 ruleId, RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue)`: Updates an existing global rule definition. (Admin)
11. `assignRuleToUser(address user, bytes32 ruleId, bool required)`: Assigns a specific global rule to a user's profile, marking it as required or optional for their withdrawals. (Admin)
12. `removeRuleFromUser(address user, bytes32 ruleId)`: Removes a rule assignment from a user. (Admin)
13. `addTraitDefinition(bytes32 traitId, string traitName)`: Defines a type of user trait (e.g., `keccak256("isAccredited")`). (Admin)
14. `verifyUserTrait(address user, bytes32 traitId, uint256 value, uint256 expirationTimestamp)`: Sets or updates a trait value for a user, attested by an admin/oracle. (Admin/Oracle)
15. `submitZKProofAndVerifyTrait(bytes32 traitId, bytes memory proof, bytes memory publicInputs)`: User submits a simulated ZK proof. If verified, the contract updates the user's trait based on public inputs. (Simulated Verification)
16. `pause()`: Pauses deposits and withdrawals (except emergency). (Admin)
17. `unpause()`: Unpauses the contract. (Admin)
18. `freezeUser(address user)`: Freezes all activity for a specific user. (Admin)
19. `unfreezeUser(address user)`: Unfreezes a specific user. (Admin)
20. `emergencyWithdraw(address token, uint256 amount, address recipient)`: Allows the owner to withdraw tokens in emergency. (Owner)
21. `setOracleData(bytes32 dataKey, uint256 value)`: Sets a simulated data point from an oracle, usable in rules. (Admin/Oracle)
22. `attestEventForUser(address user, bytes32 eventId, uint256 timestamp, bytes32 eventHash)`: An admin/oracle attests to an off-chain event relevant to a user's access rules. (Admin/Oracle)
23. `delegateRevocableAccess(address delegatee, uint256 expirationTimestamp, bytes32[] permittedRuleIds)`: User delegates limited withdrawal access to another address, subject to specified rules and expiration.
24. `claimDelegatedAccess(address delegator, address token, uint256 amount)`: Delegate attempts to withdraw using delegated access.
25. `revokeDelegatedAccess(address delegatee)`: User revokes previously delegated access.
26. `updateReputationScore(address user, int256 scoreDelta)`: Updates a user's internal reputation score. (Admin/Automated via verified actions)
27. `getUserProfile(address user)`: View user's profile details.
28. `getUserTraits(address user)`: View user's verified traits.
29. `checkUserWithdrawalEligibility(address user, address token, uint256 amount)`: Public view function to check if a user *would* be able to withdraw a specific amount based on current rules, traits, oracle data, etc. (Helper for UIs).
30. `getAcceptedTokens()`: View list of accepted tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// --- Outline ---
// 1. State Variables & Structs
// 2. Events
// 3. Modifiers
// 4. Admin & Setup Functions
// 5. Core Vault Functions (Deposit/Withdraw)
// 6. Access Control & Rule Management Functions
// 7. User Trait & Reputation Management Functions
// 8. ZK Proof & Oracle Interaction Functions (Simulated)
// 9. Conditional Delegation Functions
// 10. Query Functions

// --- Function Summary ---
// constructor(address[] initialAcceptedTokens): Initializes owner and accepted tokens.
// addAdmin(address _admin): Adds an admin.
// removeAdmin(address _admin): Removes an admin (Owner only).
// addAcceptedToken(address _token): Adds an accepted ERC-20 token.
// removeAcceptedToken(address _token): Removes an accepted ERC-20 token.
// deposit(address token, uint256 amount): Deposits accepted tokens into the vault.
// withdraw(address token, uint256 amount): Withdraws tokens after checking dynamic rules.
// addWithdrawalRule(RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue): Defines a new rule type.
// removeWithdrawalRule(bytes32 ruleId): Removes a rule definition (Admin).
// updateWithdrawalRule(bytes32 ruleId, RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue): Updates a rule definition (Admin).
// assignRuleToUser(address user, bytes32 ruleId, bool required): Assigns/configures a rule for a specific user (Admin).
// removeRuleFromUser(address user, bytes32 ruleId): Removes a rule assignment for a user (Admin).
// addTraitDefinition(bytes32 traitId, string traitName): Defines a user trait type (Admin).
// verifyUserTrait(address user, bytes35 traitId, uint256 value, uint256 expirationTimestamp): Admin/Oracle attests a user trait value.
// submitZKProofAndVerifyTrait(bytes32 traitId, bytes memory proof, bytes memory publicInputs): Simulates ZK proof verification to set a trait.
// pause(): Pauses contract functionality (Admin).
// unpause(): Unpauses contract (Admin).
// freezeUser(address user): Freezes a specific user's activity (Admin).
// unfreezeUser(address user): Unfreezes a specific user (Admin).
// emergencyWithdraw(address token, uint256 amount, address recipient): Owner emergency withdrawal.
// setOracleData(bytes32 dataKey, uint256 value): Sets simulated oracle data (Admin/Oracle).
// attestEventForUser(address user, bytes32 eventId, uint256 timestamp, bytes32 eventHash): Admin/Oracle attests an off-chain event for a user.
// delegateRevocableAccess(address delegatee, uint256 expirationTimestamp, bytes32[] permittedRuleIds): User delegates limited withdrawal access.
// claimDelegatedAccess(address delegator, address token, uint256 amount): Delegate attempts withdrawal using delegated access.
// revokeDelegatedAccess(address delegatee): User revokes delegated access.
// updateReputationScore(address user, int256 scoreDelta): Updates user reputation (Admin/Automated).
// getUserProfile(address user): View user profile.
// getUserTraits(address user): View user traits.
// checkUserWithdrawalEligibility(address user, address token, uint256 amount): View function to check withdrawal possibility.
// getAcceptedTokens(): View accepted tokens.

contract QuantumVault is Ownable, Pausable {
    using ECDSA for bytes32;

    // --- 1. State Variables & Structs ---

    // Accepted tokens for deposit/withdrawal
    mapping(address => bool) private acceptedTokens;
    address[] public acceptedTokenList;

    // User balances for each token
    mapping(address => mapping(address => uint256)) private userBalances;

    // Admin addresses with elevated permissions
    mapping(address => bool) public admins;

    // User Profile
    struct UserProfile {
        bool isFrozen; // Is the user's activity frozen?
        int256 reputationScore; // Internal reputation score
        mapping(bytes32 => uint256) tokenBalancesInternal; // Internal balances for rules
        mapping(bytes32 => UserTrait) traits; // Verified traits (traitId => trait)
        mapping(bytes32 => UserRuleAssignment) assignedRules; // Rule assignments (ruleId => assignment)
        mapping(address => DelegatedAccess) delegatedAccess; // Delegated access configurations
        mapping(bytes32 => uint256) attestedEvents; // Timestamp of last attested event (eventId => timestamp)
    }
    mapping(address => UserProfile) public userProfiles;

    // User Trait
    struct UserTrait {
        uint256 value; // The value of the trait (e.g., age, score, boolean represented as 0/1)
        uint256 expirationTimestamp; // When the trait expires (0 for no expiration)
        bool verified; // Was this trait verified?
    }
    mapping(bytes32 => string) public traitDefinitions; // traitId => traitName

    // Withdrawal Rule
    enum RuleType {
        MinimumReputation, // Requires user's reputation >= paramValue
        HasTraitValue, // Requires user to have a specific traitId with value >= paramValue (ruleParamHash is traitId)
        TokenBalanceThreshold, // Requires user's balance of a specific token >= paramValue (ruleParamHash is token address)
        OracleDataThreshold, // Requires simulated oracle data point >= paramValue (ruleParamHash is dataKey)
        TimeBasedUnlock, // Requires current time >= paramValue (ruleParamHash can be any identifier)
        AttestedEventOccurred // Requires a specific eventId to have been attested for the user at or after a certain time (paramValue is min timestamp, ruleParamHash is eventId)
    }
    struct WithdrawalRule {
        RuleType ruleType;
        bytes32 ruleParamHash; // Depends on ruleType (traitId, token address, oracle data key, eventId)
        uint256 paramValue; // Value to compare against
        bool isActive; // Is the rule currently active globally?
    }
    mapping(bytes32 => WithdrawalRule) public withdrawalRules; // ruleId => rule

    // User Rule Assignment
    struct UserRuleAssignment {
        bool required; // Is this rule mandatory for this user's withdrawals?
        bool assigned; // Is this rule assigned to the user?
    }

    // Simulated Oracle Data
    mapping(bytes32 => uint256) private oracleData; // dataKey => value

    // Delegated Access
    struct DelegatedAccess {
        uint256 expirationTimestamp; // When the delegation expires
        mapping(bytes32 => bool) permittedRules; // Allowed ruleIds for this delegatee
        bool active; // Is this delegation active?
    }

    // --- 2. Events ---

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event AcceptedTokenAdded(address indexed token);
    event AcceptedTokenRemoved(address indexed token);
    event DepositMade(address indexed user, address indexed token, uint256 amount);
    event WithdrawalAttempt(address indexed user, address indexed token, uint256 requestedAmount);
    event WithdrawalSuccess(address indexed user, address indexed token, uint256 amount);
    event WithdrawalDenied(address indexed user, address indexed token, uint256 requestedAmount, string reason);
    event RuleAdded(bytes32 indexed ruleId, RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue);
    event RuleRemoved(bytes32 indexed ruleId);
    event RuleUpdated(bytes32 indexed ruleId, RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue);
    event RuleAssignedToUser(address indexed user, bytes32 indexed ruleId, bool required);
    event RuleRemovedFromUser(address indexed user, bytes32 indexed ruleId);
    event TraitDefinitionAdded(bytes35 indexed traitId, string traitName);
    event UserTraitVerified(address indexed user, bytes35 indexed traitId, uint256 value, uint256 expirationTimestamp);
    event ZKProofValidated(address indexed user, bytes35 indexed traitId, uint256 validatedValue); // Simulated
    event UserFrozen(address indexed user);
    event UserUnfrozen(address indexed user);
    event OracleDataUpdated(bytes32 indexed dataKey, uint256 value);
    event EventAttestedForUser(address indexed user, bytes32 indexed eventId, uint256 timestamp);
    event AccessDelegated(address indexed delegator, address indexed delegatee, uint256 expirationTimestamp);
    event AccessClaimedByDelegatee(address indexed delegator, address indexed delegatee);
    event AccessRevoked(address indexed delegator, address indexed delegatee);
    event ReputationScoreUpdated(address indexed user, int256 newScore);

    // --- 3. Modifiers ---

    modifier onlyAdmin() {
        require(admins[msg.sender] || owner() == msg.sender, "Only owner or admin");
        _;
    }

    // Check if user is not frozen
    modifier notFrozen(address user) {
        require(!userProfiles[user].isFrozen, "User account frozen");
        _;
    }

    // Internal modifier to check if a user meets a specific rule
    modifier requiresRule(address user, bytes32 ruleId) {
        require(_checkSingleRule(user, ruleId), "Rule not met");
        _;
    }

    // --- 4. Admin & Setup Functions ---

    constructor(address[] memory initialAcceptedTokens) Ownable(msg.sender) Pausable(false) {
        for (uint i = 0; i < initialAcceptedTokens.length; i++) {
            acceptedTokens[initialAcceptedTokens[i]] = true;
            acceptedTokenList.push(initialAcceptedTokens[i]);
        }
    }

    /// @notice Adds an address to the list of contract administrators.
    /// @param _admin The address to add as an admin.
    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Zero address");
        require(!admins[_admin], "Already an admin");
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /// @notice Removes an address from the list of contract administrators.
    /// @param _admin The address to remove from admins.
    function removeAdmin(address _admin) external onlyOwner {
        require(_admin != owner(), "Cannot remove owner as admin");
        require(admins[_admin], "Not an admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    /// @notice Adds a new ERC-20 token address that the vault will accept for deposits and withdrawals.
    /// @param _token The address of the ERC-20 token.
    function addAcceptedToken(address _token) external onlyAdmin {
        require(_token != address(0), "Zero address");
        require(!acceptedTokens[_token], "Token already accepted");
        acceptedTokens[_token] = true;
        acceptedTokenList.push(_token);
        emit AcceptedTokenAdded(_token);
    }

    /// @notice Removes an ERC-20 token address from the list of accepted tokens.
    /// @param _token The address of the ERC-20 token to remove.
    function removeAcceptedToken(address _token) external onlyAdmin {
        require(acceptedTokens[_token], "Token not accepted");
        acceptedTokens[_token] = false;
        // Note: Removing from acceptedTokenList array is gas intensive.
        // For simplicity in this example, we'll leave it, but in production,
        // one might use a mapping + count or a more sophisticated list
        // implementation, or simply iterate and check the mapping.
        emit AcceptedTokenRemoved(_token);
    }

    /// @notice Pauses deposits and non-emergency withdrawals.
    function pause() external onlyAdmin whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyAdmin whenPaused {
        _unpause();
    }

    /// @notice Freezes a specific user account, preventing their activity.
    /// @param user The address of the user to freeze.
    function freezeUser(address user) external onlyAdmin {
        require(user != address(0), "Zero address");
        require(!userProfiles[user].isFrozen, "User already frozen");
        userProfiles[user].isFrozen = true;
        emit UserFrozen(user);
    }

    /// @notice Unfreezes a specific user account.
    /// @param user The address of the user to unfreeze.
    function unfreezeUser(address user) external onlyAdmin {
        require(user != address(0), "Zero address");
        require(userProfiles[user].isFrozen, "User not frozen");
        userProfiles[user].isFrozen = false;
        emit UserUnfrozen(user);
    }

    /// @notice Allows the owner to withdraw tokens from the contract in an emergency.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    /// @param recipient The address to send the tokens to.
    function emergencyWithdraw(address token, uint256 amount, address recipient) external onlyOwner {
        require(token != address(0), "Zero address");
        require(amount > 0, "Amount must be > 0");
        require(recipient != address(0), "Zero address recipient");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient contract balance");

        IERC20(token).transfer(recipient, amount);
    }

    // --- 5. Core Vault Functions (Deposit/Withdraw) ---

    /// @notice Deposits a specified amount of an accepted ERC-20 token into the vault.
    /// @param token The address of the ERC-20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function deposit(address token, uint256 amount) external whenNotPaused notFrozen(msg.sender) {
        require(acceptedTokens[token], "Token not accepted");
        require(amount > 0, "Amount must be > 0");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userBalances[msg.sender][token] += amount;
        emit DepositMade(msg.sender, token, amount);
    }

    /// @notice Attempts to withdraw a specified amount of a token. Withdrawal is subject to dynamic access rules.
    /// @param token The address of the ERC-20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(address token, uint256 amount) external whenNotPaused notFrozen(msg.sender) {
        emit WithdrawalAttempt(msg.sender, token, amount);

        require(acceptedTokens[token], "Token not accepted");
        require(amount > 0, "Amount must be > 0");
        require(userBalances[msg.sender][token] >= amount, "Insufficient user balance in vault");

        // --- Dynamic Access Control Check ---
        string memory denialReason;
        if (!_checkUserWithdrawalEligibility(msg.sender, token, amount, denialReason)) {
             emit WithdrawalDenied(msg.sender, token, amount, denialReason);
             revert(denialReason);
        }
        // --- End Access Control Check ---

        userBalances[msg.sender][token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit WithdrawalSuccess(msg.sender, token, amount);
    }

    // --- 6. Access Control & Rule Management Functions ---

    /// @notice Adds a new type of withdrawal rule that can be assigned to users.
    /// @param ruleType The type of the rule.
    /// @param ruleParamHash Identifier for the parameter (traitId, token address, oracle key, eventId).
    /// @param paramValue The threshold value for the rule.
    /// @return ruleId The unique ID of the newly added rule.
    function addWithdrawalRule(RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue) external onlyAdmin returns (bytes32) {
        bytes32 ruleId = keccak256(abi.encodePacked(uint8(ruleType), ruleParamHash, paramValue));
        require(!withdrawalRules[ruleId].isActive, "Rule already exists");

        withdrawalRules[ruleId] = WithdrawalRule({
            ruleType: ruleType,
            ruleParamHash: ruleParamHash,
            paramValue: paramValue,
            isActive: true
        });
        emit RuleAdded(ruleId, ruleType, ruleParamHash, paramValue);
        return ruleId;
    }

    /// @notice Removes a withdrawal rule definition.
    /// @param ruleId The ID of the rule to remove.
    function removeWithdrawalRule(bytes32 ruleId) external onlyAdmin {
        require(withdrawalRules[ruleId].isActive, "Rule does not exist or is inactive");
        withdrawalRules[ruleId].isActive = false; // Soft delete
        emit RuleRemoved(ruleId);
    }

    /// @notice Updates an existing withdrawal rule definition.
    /// @param ruleId The ID of the rule to update.
    /// @param ruleType The new type of the rule.
    /// @param ruleParamHash The new identifier for the parameter.
    /// @param paramValue The new threshold value.
    function updateWithdrawalRule(bytes32 ruleId, RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue) external onlyAdmin {
        require(withdrawalRules[ruleId].isActive, "Rule does not exist or is inactive");

        withdrawalRules[ruleId].ruleType = ruleType;
        withdrawalRules[ruleId].ruleParamHash = ruleParamHash;
        withdrawalRules[ruleId].paramValue = paramValue;

        emit RuleUpdated(ruleId, ruleType, ruleParamHash, paramValue);
    }

    /// @notice Assigns a specific rule definition to a user's profile and sets if it's required.
    /// @param user The user address.
    /// @param ruleId The ID of the rule to assign.
    /// @param required True if the rule is mandatory for this user's withdrawals, false if optional.
    function assignRuleToUser(address user, bytes32 ruleId, bool required) external onlyAdmin {
        require(user != address(0), "Zero address");
        require(withdrawalRules[ruleId].isActive, "Rule definition not active");

        userProfiles[user].assignedRules[ruleId] = UserRuleAssignment({
            required: required,
            assigned: true
        });
        emit RuleAssignedToUser(user, ruleId, required);
    }

    /// @notice Removes a rule assignment from a user's profile.
    /// @param user The user address.
    /// @param ruleId The ID of the rule to remove from the user.
    function removeRuleFromUser(address user, bytes32 ruleId) external onlyAdmin {
        require(user != address(0), "Zero address");
        require(userProfiles[user].assignedRules[ruleId].assigned, "Rule not assigned to user");

        delete userProfiles[user].assignedRules[ruleId]; // Remove assignment
        emit RuleRemovedFromUser(user, ruleId);
    }

    /// @notice Internal helper function to check if a single rule is met for a user.
    /// @param user The user address.
    /// @param ruleId The ID of the rule to check.
    /// @return True if the rule is met, false otherwise.
    function _checkSingleRule(address user, bytes32 ruleId) internal view returns (bool) {
        WithdrawalRule memory rule = withdrawalRules[ruleId];
        if (!rule.isActive) {
            // If the rule definition is inactive, it cannot be met in its current form.
            // Depending on logic, assigned but inactive rules might fail or be ignored.
            // Here, we consider an inactive *definition* as a failure to meet the *assigned* rule.
             return false;
        }

        UserProfile storage userProfile = userProfiles[user];

        if (!userProfile.assignedRules[ruleId].assigned) {
             // If the rule isn't even assigned to the user, it's not a requirement for them.
             // This function is called *after* checking if the rule is required.
             // So if assignedRules[ruleId].required is true but assigned is false,
             // the check in _checkUserWithdrawalEligibility would fail before calling this.
             // If assignedRules[ruleId].required is false, this function might still be called
             // to see if the optional rule is met (e.g., for logging/bonuses), but for
             // withdrawal eligibility, only required rules matter in the main check.
             // For this helper, we'll assume we only call it for assigned rules.
        }


        // Evaluate the rule based on its type
        if (rule.ruleType == RuleType.MinimumReputation) {
            return userProfile.reputationScore >= int256(rule.paramValue);
        } else if (rule.ruleType == RuleType.HasTraitValue) {
            bytes32 traitId = rule.ruleParamHash;
            UserTrait memory trait = userProfile.traits[traitId];
            // Trait must be verified and meet the value threshold, and not expired
            bool notExpired = (trait.expirationTimestamp == 0 || block.timestamp <= trait.expirationTimestamp);
            return trait.verified && notExpired && trait.value >= rule.paramValue;
        } else if (rule.ruleType == RuleType.TokenBalanceThreshold) {
            address token = address(uint160(bytes20(rule.ruleParamHash))); // Cast bytes32 to address
            // Check user's balance *in the vault*
            return userBalances[user][token] >= rule.paramValue;
        } else if (rule.ruleType == RuleType.OracleDataThreshold) {
             // Check against simulated oracle data
            return oracleData[rule.ruleParamHash] >= rule.paramValue;
        } else if (rule.ruleType == RuleType.TimeBasedUnlock) {
             // Check if current time is after the specified timestamp
             return block.timestamp >= rule.paramValue;
        } else if (rule.ruleType == RuleType.AttestedEventOccurred) {
             // Check if the event was attested *after* the minimum timestamp specified in the rule's paramValue
             bytes32 eventId = rule.ruleParamHash;
             return userProfile.attestedEvents[eventId] >= rule.paramValue && userProfile.attestedEvents[eventId] > 0; // ensure it's > 0 to distinguish from default 0
        }

        // Unknown rule type or inactive rule definition defaults to false
        return false;
    }

    /// @notice Internal function to check ALL applicable rules for a user's withdrawal.
    /// @param user The user address attempting to withdraw.
    /// @param token The token being withdrawn (can be used in rules).
    /// @param amount The amount being withdrawn (can be used in rules).
    /// @param denialReason Out parameter to return a reason if denied.
    /// @return True if all required rules are met, false otherwise.
    function _checkUserWithdrawalEligibility(address user, address token, uint256 amount, out string denialReason) internal view returns (bool) {
        UserProfile storage userProfile = userProfiles[user];

        if (userProfile.isFrozen) {
            denialReason = "User account is frozen";
            return false;
        }

        if (paused()) {
             denialReason = "Contract is paused";
             return false;
        }

        // Iterate through all rule assignments for the user
        // NOTE: Iterating over mappings directly is not possible.
        // In a real scenario, we would need a list of assigned ruleIds per user,
        // or iterate over the global rule definitions and check assignment.
        // For this example, we'll simulate checking against a *subset* or
        // assume some rules are applied via direct checks.
        // A more robust approach would involve mapping user => list of assigned ruleIds.
        // Let's simulate by checking a few key rules directly for demonstration.

        // Example checks based on profile state directly, or by looking up specific rule IDs
        // This assumes specific rules have known IDs or types we can check for.

        // Example 1: Check a generic MinimumReputation rule (if assigned and required)
        // This requires knowing the ruleId for the MinReputation rule type used for this user/context
        // Let's assume there's a standard rule ID for minimum reputation, e.g., keccak256("GLOBAL_MIN_REP_RULE")
        bytes32 minRepRuleId = keccak256("GLOBAL_MIN_REP_RULE"); // Example ID - need to add/get this ID properly
        if (userProfile.assignedRules[minRepRuleId].assigned && userProfile.assignedRules[minRepRuleId].required) {
             if (!_checkSingleRule(user, minRepRuleId)) {
                 denialReason = "Minimum reputation rule not met";
                 return false;
             }
        }

        // Example 2: Check a specific Trait requirement rule (if assigned and required)
        // Assume a rule exists like "Requires 'isAccredited' trait with value 1"
        bytes32 accreditedTraitId = keccak256("isAccredited");
        // Find the ruleId that corresponds to RuleType.HasTraitValue, ruleParamHash=accreditedTraitId, paramValue=1
        // This lookup is complex. A better approach is to store assigned rule IDs.
        // Let's simulate: Assume ruleId `accreditedRuleID` exists and is assigned/required.
        bytes32 accreditedRuleID = keccak256("ACCREDITED_STATUS_RULE"); // Example ID
         if (userProfile.assignedRules[accreditedRuleID].assigned && userProfile.assignedRules[accreditedRuleID].required) {
             if (!_checkSingleRule(user, accreditedRuleID)) {
                 denialReason = "Accredited investor status rule not met";
                 return false;
             }
        }

        // Example 3: Check a Time-Based Unlock rule (if assigned and required)
        // Assume a rule like "Unlock after a specific date" exists and is assigned/required.
        bytes32 unlockDateRuleID = keccak256("PORTFOLIO_UNLOCK_DATE_RULE"); // Example ID
         if (userProfile.assignedRules[unlockDateRuleID].assigned && userProfile.assignedRules[unlockDateRuleID].required) {
             if (!_checkSingleRule(user, unlockDateRuleID)) {
                 denialReason = "Time-based unlock rule not met";
                 return false;
             }
        }

        // Example 4: Check based on Attested Event (if assigned and required)
        // Assume a rule like "Claim allowed after Graduation event attested" exists and is assigned/required.
        bytes32 graduationEventID = keccak256("GRADUATION_EVENT");
        bytes32 graduationClaimRuleID = keccak256("GRADUATION_CLAIM_RULE"); // Example rule checks for this event after a certain timestamp
         if (userProfile.assignedRules[graduationClaimRuleID].assigned && userProfile.assignedRules[graduationClaimRuleID].required) {
             if (!_checkSingleRule(user, graduationClaimRuleID)) {
                 denialReason = "Attested event rule not met (e.g., Graduation)";
                 return false;
             }
        }


        // In a production system, you would need to iterate through `userProfiles[user].assignedRules`
        // (which implies storing these IDs in a list/array in the struct)
        // and call _checkSingleRule for each `required: true` assignment.

        // If all required rules assigned to the user pass (or no rules are assigned/required), return true
        denialReason = ""; // Clear reason on success
        return true;
    }

    // --- 7. User Trait & Reputation Management Functions ---

    /// @notice Defines a type of user trait that can be verified.
    /// @param traitId A unique identifier for the trait (e.g., keccak256("isAccredited")).
    /// @param traitName A human-readable name for the trait.
    function addTraitDefinition(bytes32 traitId, string memory traitName) external onlyAdmin {
        require(traitId != bytes32(0), "Zero trait ID");
        require(bytes(traitDefinitions[traitId]).length == 0, "Trait ID already defined");
        traitDefinitions[traitId] = traitName;
        emit TraitDefinitionAdded(traitId, traitName);
    }

    /// @notice Admin or authorized Oracle verifies/sets a trait value for a user.
    /// @param user The user address.
    /// @param traitId The ID of the trait (must be defined).
    /// @param value The numerical value of the trait.
    /// @param expirationTimestamp Timestamp when the verification expires (0 for no expiration).
    function verifyUserTrait(address user, bytes32 traitId, uint256 value, uint256 expirationTimestamp) external onlyAdmin {
        require(user != address(0), "Zero address");
        require(bytes(traitDefinitions[traitId]).length > 0, "Trait ID not defined");

        userProfiles[user].traits[traitId] = UserTrait({
            value: value,
            expirationTimestamp: expirationTimestamp,
            verified: true
        });
        emit UserTraitVerified(user, traitId, value, expirationTimestamp);
    }

    /// @notice Allows a user to submit a ZK proof to verify a trait off-chain.
    /// (Simulated Verification) This function does not contain actual ZK logic.
    /// It assumes an external ZK verifier would be called here or the proof
    /// is verified by an trusted entity/oracle signing the verification.
    /// @param traitId The ID of the trait being verified.
    /// @param proof The ZK proof data.
    /// @param publicInputs Public inputs for the proof, including the user's address and claimed trait value.
    function submitZKProofAndVerifyTrait(bytes32 traitId, bytes memory proof, bytes memory publicInputs) external notFrozen(msg.sender) {
        require(bytes(traitDefinitions[traitId]).length > 0, "Trait ID not defined");
        // require(zkVerifiers[traitId] != address(0), "ZK verifier not configured for this trait");

        // --- SIMULATION ---
        // In a real scenario, this would call an external precompiled contract or
        // another contract implementing the ZK verification algorithm (e.g., Groth16Verifier).
        // `publicInputs` would typically include components like `msg.sender`, `traitId`, and the `claimedValue`.
        // The verifier returns true/false based on proof and public inputs.
        // For this simulation, we'll just parse a claimed value from publicInputs
        // and assume verification passed.
        uint256 claimedValue = 0;
        if (publicInputs.length >= 32) {
             assembly {
                 claimedValue := mload(add(publicInputs, 0x20)) // Read the first 32 bytes after length as the claimed value
             }
        }
        // bool verificationSuccessful = ZKVerifier(zkVerifiers[traitId]).verify(proof, publicInputs);
        bool verificationSuccessful = (claimedValue > 0); // Simple simulation: proof is valid if claimedValue > 0

        require(verificationSuccessful, "ZK proof verification failed");
        // --- END SIMULATION ---

        // Assuming publicInputs contained the user's address and the value being claimed/verified for the trait
        // In a real ZK system, the public inputs must be structured and verified against the proof.
        // For this simulation, we'll directly use msg.sender and the claimedValue.

        userProfiles[msg.sender].traits[traitId] = UserTrait({
            value: claimedValue, // Value comes from public inputs verified by ZK proof
            expirationTimestamp: 0, // ZK proofs are often timeless or have logic within the circuit
            verified: true
        });

        emit ZKProofValidated(msg.sender, traitId, claimedValue);
        emit UserTraitVerified(msg.sender, traitId, claimedValue, 0); // Also emit standard trait event
    }

    /// @notice Admin or authorized entity updates a user's internal reputation score.
    /// This could be based on verified positive actions or negative events.
    /// @param user The user address.
    /// @param scoreDelta The amount to add to the current reputation score (can be negative).
    function updateReputationScore(address user, int256 scoreDelta) external onlyAdmin {
        require(user != address(0), "Zero address");
        userProfiles[user].reputationScore += scoreDelta;
        emit ReputationScoreUpdated(user, userProfiles[user].reputationScore);
    }


    // --- 8. Oracle Interaction Functions (Simulated) ---

    /// @notice Sets a simulated data point from an external oracle.
    /// This data can be used in withdrawal rules.
    /// @param dataKey A unique key identifying the oracle data (e.g., keccak256("ETH/USD_Price")).
    /// @param value The value provided by the oracle.
    function setOracleData(bytes32 dataKey, uint256 value) external onlyAdmin {
        require(dataKey != bytes32(0), "Zero data key");
        oracleData[dataKey] = value;
        emit OracleDataUpdated(dataKey, value);
    }

    /// @notice Admin/Oracle attests that a specific off-chain event occurred for a user.
    /// This timestamp can be used in rules (e.g., TimeBasedUnlock or AttestedEventOccurred).
    /// @param user The user address.
    /// @param eventId A unique identifier for the event (e.g., keccak256("Graduation")).
    /// @param timestamp The timestamp of the event (usually `block.timestamp` when attested).
    /// @param eventHash Optional hash of event details for verification off-chain.
    function attestEventForUser(address user, bytes32 eventId, uint256 timestamp, bytes32 eventHash) external onlyAdmin {
         require(user != address(0), "Zero address");
         require(eventId != bytes32(0), "Zero event ID");
         require(timestamp > 0, "Timestamp must be greater than zero"); // Avoid default 0

         userProfiles[user].attestedEvents[eventId] = timestamp;
         // eventHash could be stored or used in a signature verification if attested by a specific oracle address
         emit EventAttestedForUser(user, eventId, timestamp);
    }

    // --- 9. Conditional Delegation Functions ---

    /// @notice Allows a user to delegate limited withdrawal access to another address.
    /// The delegatee can only withdraw if they meet the specified rules and before expiration.
    /// @param delegatee The address to delegate access to.
    /// @param expirationTimestamp When the delegated access expires.
    /// @param permittedRuleIds The list of rule IDs that the delegatee must satisfy for withdrawal.
    function delegateRevocableAccess(address delegatee, uint256 expirationTimestamp, bytes32[] memory permittedRuleIds) external notFrozen(msg.sender) {
        require(delegatee != address(0), "Zero address");
        require(delegatee != msg.sender, "Cannot delegate to self");
        require(expirationTimestamp > block.timestamp, "Expiration must be in the future");

        // Optional: Validate if permittedRuleIds are valid and active rules
        // require(...)

        DelegatedAccess storage delegation = userProfiles[msg.sender].delegatedAccess[delegatee];
        delegation.expirationTimestamp = expirationTimestamp;
        delegation.active = true;

        // Clear previous permitted rules and set new ones
        for (bytes32 ruleId : permittedRuleIds) {
            delegation.permittedRules[ruleId] = true;
        }
        // Note: This doesn't clear previously set rules if permittedRuleIds is shorter.
        // A better approach is to store allowed rules in an array or clear all first.
        // For simplicity here, we just set.

        emit AccessDelegated(msg.sender, delegatee, expirationTimestamp);
    }

    /// @notice Allows a delegatee to attempt withdrawal using delegated access.
    /// Checks delegation validity and required rules specified in the delegation.
    /// @param delegator The address who delegated the access.
    /// @param token The token to withdraw.
    /// @param amount The amount to withdraw.
    function claimDelegatedAccess(address delegator, address token, uint256 amount) external whenNotPaused {
        emit AccessClaimedByDelegatee(delegator, msg.sender);

        require(acceptedTokens[token], "Token not accepted");
        require(amount > 0, "Amount must be > 0");
        require(userBalances[delegator][token] >= amount, "Insufficient delegator balance in vault");

        UserProfile storage delegatorProfile = userProfiles[delegator];
        DelegatedAccess storage delegation = delegatorProfile.delegatedAccess[msg.sender];

        require(delegation.active, "Delegation is not active");
        require(delegation.expirationTimestamp > block.timestamp, "Delegation has expired");

        // --- Delegation Specific Access Control Check ---
        // Delegatee must be not frozen, delegator must be not frozen, and all rules required *by the delegation* must be met.
        // Note: Rules assigned directly to the delegator's profile might NOT apply here,
        // unless the delegation structure explicitly dictates that.
        // Here, we only check rules specified in `delegation.permittedRules`.

        bool allPermittedRulesMet = true;
        // Iterating mapping is not possible. Assuming `permittedRuleIds` were stored in an array
        // in the DelegatedAccess struct during delegation for iteration here.
        // As a workaround for this example, we'll assume the delegation requires
        // meeting *some* specific known rule IDs that the delegatee must pass.
        // In a real implementation, loop through `delegation.permittedRuleIds`.

        // Example Simulation: Check if the delegatee meets a specific minimum reputation rule AND a specific trait rule, IF these rule IDs were included in the delegation.
        bytes32 exampleRuleId1 = keccak256("GLOBAL_MIN_REP_RULE"); // Assumed ID included in permittedRuleIds
        bytes32 exampleRuleId2 = keccak256("ACCREDITED_STATUS_RULE"); // Assumed ID included in permittedRuleIds

        // Check if these rules were actually permitted in the delegation AND if the delegatee meets them.
        if (delegation.permittedRules[exampleRuleId1]) {
            if (!_checkSingleRule(msg.sender, exampleRuleId1)) { // Check rule on the *delegatee* profile
                 allPermittedRulesMet = false;
            }
        }
         if (allPermittedRulesMet && delegation.permittedRules[exampleRuleId2]) {
            if (!_checkSingleRule(msg.sender, exampleRuleId2)) { // Check rule on the *delegatee* profile
                 allPermittedRulesMet = false;
            }
        }
        // Add checks for other permitted rules in a real implementation...

        require(allPermittedRulesMet, "Delegatee failed required rules");
        require(!userProfiles[msg.sender].isFrozen, "Delegatee account frozen"); // Delegatee must also not be frozen
        require(!delegatorProfile.isFrozen, "Delegator account frozen"); // Delegator must also not be frozen

        // --- End Delegation Access Control Check ---


        userBalances[delegator][token] -= amount; // Deduct from delegator's balance
        IERC20(token).transfer(msg.sender, amount); // Send to delegatee
        // Note: This specific implementation transfers to the delegatee. Could also allow sending back to delegator or a third party based on delegation parameters.

        // Optional: Reduce delegation allowance or mark delegation as used up to a certain amount
        // delegation.amountClaimed += amount; requires adding amountClaimed to struct

        // Optional: Revoke delegation after a single use or specific conditions
        // delete delegatorProfile.delegatedAccess[msg.sender];

        emit WithdrawalSuccess(msgator, token, amount); // Event uses delegator as the source
    }

    /// @notice Allows the delegator to revoke previously granted access to a delegatee.
    /// @param delegatee The address whose access is being revoked.
    function revokeRevocableAccess(address delegatee) external notFrozen(msg.sender) {
        DelegatedAccess storage delegation = userProfiles[msg.sender].delegatedAccess[delegatee];
        require(delegation.active, "No active delegation to this address");

        delete userProfiles[msg.sender].delegatedAccess[delegatee]; // Revoke delegation
        emit AccessRevoked(msg.sender, delegatee);
    }


    // --- 10. Query Functions ---

    /// @notice Gets the profile details for a user.
    /// @param user The user address.
    /// @return isFrozen Whether the user is frozen.
    /// @return reputationScore The user's reputation score.
    function getUserProfile(address user) external view returns (bool isFrozen, int256 reputationScore) {
        UserProfile storage profile = userProfiles[user];
        return (profile.isFrozen, profile.reputationScore);
    }

    /// @notice Gets the verified traits for a user.
    /// Note: Cannot return a mapping directly. Returns an array of trait IDs assigned.
    /// Need another view function or off-chain logic to get trait *values* by iterating these IDs.
    /// @param user The user address.
    /// @return traitIds An array of trait IDs the user has assigned.
    /// @return traitValues An array of trait values corresponding to the IDs.
    /// @return expirationTimestamps An array of expiration timestamps.
    function getUserTraits(address user) external view returns (bytes32[] memory traitIds, uint256[] memory traitValues, uint256[] memory expirationTimestamps) {
        // Iterating mapping is not possible. Need to store traitIds in an array in UserProfile struct.
        // For this example, we'll simulate by checking a few known trait IDs.
        bytes32[] memory knownTraitIds = new bytes32[](2); // Example: check for 'isAccredited' and 'ageVerified'
        knownTraitIds[0] = keccak256("isAccredited");
        knownTraitIds[1] = keccak256("ageVerified");

        uint count = 0;
        for(uint i = 0; i < knownTraitIds.length; i++) {
            if (userProfiles[user].traits[knownTraitIds[i]].verified) {
                count++;
            }
        }

        traitIds = new bytes32[](count);
        traitValues = new uint256[](count);
        expirationTimestamps = new uint256[](count);
        uint index = 0;
        for(uint i = 0; i < knownTraitIds.length; i++) {
            UserTrait memory trait = userProfiles[user].traits[knownTraitIds[i]];
            if (trait.verified) {
                traitIds[index] = knownTraitIds[i];
                traitValues[index] = trait.value;
                expirationTimestamps[index] = trait.expirationTimestamp;
                index++;
            }
        }

        return (traitIds, traitValues, expirationTimestamps);
    }

    /// @notice Gets the details of a specific withdrawal rule definition.
    /// @param ruleId The ID of the rule.
    /// @return ruleType The type of the rule.
    /// @return ruleParamHash The parameter hash of the rule.
    /// @return paramValue The parameter value of the rule.
    /// @return isActive Whether the rule definition is active.
    function getWithdrawalRule(bytes32 ruleId) external view returns (RuleType ruleType, bytes32 ruleParamHash, uint256 paramValue, bool isActive) {
        WithdrawalRule memory rule = withdrawalRules[ruleId];
        return (rule.ruleType, rule.ruleParamHash, rule.paramValue, rule.isActive);
    }


    /// @notice Public view function to check if a user *would* be able to withdraw a specific amount based on current rules, traits, oracle data, etc.
    /// This is a helper for UIs to show withdrawal eligibility *before* attempting a transaction.
    /// @param user The user address to check.
    /// @param token The token address.
    /// @param amount The amount to check eligibility for.
    /// @return isEligible True if eligible, false otherwise.
    /// @return denialReason A string explaining why withdrawal would be denied if not eligible.
    function checkUserWithdrawalEligibility(address user, address token, uint256 amount) external view returns (bool isEligible, string memory denialReason) {
        // Check basic conditions first
        if (!acceptedTokens[token]) {
             return (false, "Token not accepted");
        }
         if (amount == 0) {
             return (false, "Amount must be > 0");
         }
         if (userBalances[user][token] < amount) {
            return (false, "Insufficient user balance in vault");
         }
         if (userProfiles[user].isFrozen) {
             return (false, "User account is frozen");
         }
         if (paused()) {
             return (false, "Contract is paused");
         }

        // Perform the complex rule check
        string memory internalDenialReason; // Use a temporary variable
        bool eligible = _checkUserWithdrawalEligibility(user, token, amount, internalDenialReason);
        return (eligible, internalDenialReason);
    }


    /// @notice Gets the list of accepted token addresses.
    /// @return addresses An array of accepted token addresses.
    function getAcceptedTokens() external view returns (address[] memory) {
        // This relies on `acceptedTokenList` being maintained. `removeAcceptedToken`
        // currently doesn't prune the list for gas reasons, so this list might contain
        // addresses that are no longer accepted according to the `acceptedTokens` mapping.
        // A more robust approach would filter the list based on the mapping.
        address[] memory currentAccepted = new address[](acceptedTokenList.length);
        uint count = 0;
        for (uint i = 0; i < acceptedTokenList.length; i++) {
            if (acceptedTokens[acceptedTokenList[i]]) {
                currentAccepted[count] = acceptedTokenList[i];
                count++;
            }
        }
        // Trim the array to actual accepted tokens
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = currentAccepted[i];
        }
        return result;
    }
}
```