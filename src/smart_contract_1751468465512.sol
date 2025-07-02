Okay, here is a Solidity smart contract incorporating several advanced, creative, and trending concepts like decentralized identity/reputation, dynamic asset attributes based on reputation, a gamified quest system, and a custom role-based access control, while aiming to be distinct from standard open-source implementations.

It combines elements of soulbound tokens (identity/reputation linked to address), dynamic NFTs (conceptual dynamic attributes on assets), and gamification.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline ---
// 1. Contract Overview: A system for managing decentralized identity, reputation,
//    dynamic asset vaults, and interactive quests/achievements.
// 2. Core Concepts:
//    - Decentralized Identity: Users register a unique profile.
//    - Dynamic Reputation: Points earned via actions, subject to decay over time.
//    - Dynamic Asset Vault: Users deposit ERC20 assets. These assets gain dynamic
//      attributes (e.g., yield multiplier) based on the user's reputation.
//    - Quest System: Users attempt and complete quests (verified by Oracle role)
//      to earn reputation and rewards.
//    - Social Endorsement: Users can endorse others by spending/transferring reputation.
//    - Role-Based Access Control: Custom roles for Admin, Oracle, etc.
//    - Pausability & Reentrancy Guard.
// 3. Main Modules & Functions:
//    - Identity & Profile Management
//    - Reputation System (Earning, Spending, Decay, View)
//    - Dynamic Asset Vault (Deposit, Withdraw, View Balance, View Dynamic Attributes)
//    - Quest Management & Interaction (Create, Start, Verify, View Status)
//    - Social & Achievement Features (Endorsement, Claim Rewards)
//    - Access Control & Utility (Roles, Pause, Withdraw)

// --- Function Summary ---
// Identity & Profile:
// - registerIdentity(): Creates a user profile, linking address to the system.
// - updateProfileMetadata(string metadataURI): Allows user to update profile metadata.
// - getProfile(address user): Views a user's profile details.
// - getReputation(address user): Views a user's current reputation points, accounting for decay.
//
// Reputation System:
// - decayReputation(address user): Public function to trigger reputation decay for a specific user. Callable by anyone for their own profile, or by ADMIN/ORACLE for others.
// - setReputationDecayRate(uint256 ratePerPeriod): Admin sets the reputation decay rate (points per period).
// - setReputationDecayPeriod(uint256 periodSeconds): Admin sets the duration of the decay period in seconds.
//
// Dynamic Asset Vault:
// - depositERC20(address tokenAddress, uint256 amount): User deposits a specified amount of an ERC20 token into their vault. Requires prior approval.
// - withdrawERC20(address tokenAddress, uint256 amount): User withdraws a specified amount of an ERC20 token from their vault.
// - getVaultERC20Amount(address user, address tokenAddress): Views the amount of a specific ERC20 token a user holds in their vault.
// - getVaultERC20YieldMultiplier(address user, address tokenAddress): Calculates and views the dynamic yield multiplier for a specific asset based on the user's reputation. (Conceptual multiplier).
//
// Quest System:
// - createQuest(uint256 questId, uint256 requiredReputation, uint256 rewardReputation, string questMetadataURI): Admin creates a new quest.
// - startQuest(uint256 questId): User signals intent to start a quest (checks requirements).
// - verifyQuestCompletion(address user, uint256 questId, bool success): ORACLE or ADMIN verifies quest completion for a user, granting rewards or updating status.
// - getUserQuestStatus(address user, uint256 questId): Views a user's progress/status on a specific quest.
// - updateQuestMetadata(uint256 questId, string newMetadataURI): Admin updates metadata for an existing quest.
//
// Social & Achievement:
// - endorseUser(address userToEndorse): User spends reputation to endorse another user, transferring a portion of their reputation. Subject to cooldown.
// - claimAchievementReward(uint256 achievementId): Allows users to claim specific conceptual rewards based on reputation tiers or achievements (e.g., reset endorsement cooldown).
//
// Access Control & Utility:
// - grantRole(bytes32 role, address account): Owner grants a role to an address.
// - revokeRole(bytes32 role, address account): Owner revokes a role from an address.
// - hasRole(bytes32 role, address account): Checks if an address has a specific role.
// - pauseContract(): Admin pauses core contract functions.
// - unpauseContract(): Admin unpauses core contract functions.
// - withdrawContractBalanceERC20(address tokenAddress): Admin withdraws specific ERC20 tokens held by the contract (e.g., deposited assets).

contract DynamicReputationSystem is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Constants ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // Role for verifying external events/quests

    uint256 public constant MAX_REPUTATION = 10000; // Example Cap

    uint256 public reputationDecayRate = 1; // Points decayed per period
    uint256 public reputationDecayPeriod = 1 days; // Seconds in a decay period

    uint256 public endorsementCost = 50; // RP cost to endorse
    uint256 public endorsementGain = 25; // RP gain from being endorsed
    uint256 public constant ENDORSEMENT_COOLDOWN = 7 days; // Cooldown for endorsing the same user

    // --- Events ---
    event IdentityRegistered(address indexed user, uint256 timestamp);
    event ProfileMetadataUpdated(address indexed user, string metadataURI);
    event ReputationUpdated(address indexed user, uint256 newReputation, string reason);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation, uint256 decayedAmount);

    event AssetDeposited(address indexed user, address indexed tokenAddress, uint256 amount);
    event AssetWithdrawal(address indexed user, address indexed tokenAddress, uint256 amount);

    event QuestCreated(uint256 indexed questId, uint256 requiredReputation, uint256 rewardReputation);
    event QuestStarted(address indexed user, uint256 indexed questId);
    event QuestCompletionVerified(address indexed user, uint256 indexed questId, bool success, uint256 awardedReputation);
    event QuestMetadataUpdated(uint256 indexed questId, string newMetadataURI);

    event UserEndorsed(address indexed endorser, address indexed endorsed, uint256 endorserNewReputation, uint256 endorsedNewReputation);
    event AchievementRewardClaimed(address indexed user, uint256 indexed achievementId);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Paused(address account);
    event Unpaused(address account);

    // --- Errors ---
    error IdentityNotRegistered(address user);
    error AlreadyRegistered(address user);
    error InsufficientReputation(uint256 currentReputation, uint256 required);
    error Unauthorized(address caller, bytes32 requiredRole);
    error Paused();
    error NotPaused();
    error QuestNotFound(uint256 questId);
    error QuestAlreadyStarted(address user, uint256 questId);
    error QuestNotInProgress(address user, uint256 questId);
    error InsufficientVaultBalance(address tokenAddress, uint256 currentBalance, uint256 requested);
    error CannotEndorseSelf();
    error EndorsementOnCooldown(address userToEndorse, uint256 timeLeft);
    error VaultEmpty(address tokenAddress);
    error NoActiveQuests();
    error InvalidReputationAmount();
    error CannotWithdrawAdminRoles();

    // --- Data Structures ---
    struct UserProfile {
        bool registered;
        uint256 reputationPoints;
        uint256 lastReputationUpdateTime; // To track decay based on time
        string metadataURI; // Link to off-chain profile metadata (IPFS, etc.)
        mapping(address => uint256) lastEndorsementTime; // Cooldown per endorsed user
    }

    struct Quest {
        bool exists; // To check if questId is valid
        bool active; // Can this quest still be attempted?
        uint256 requiredReputation; // Minimum RP to start quest
        uint256 rewardReputation; // RP earned upon successful completion
        string metadataURI; // Info about the quest (description, steps, etc.)
    }

    enum QuestStatus {
        NotStarted,
        InProgress,
        Completed,
        Failed
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(address => uint256)) public vaultBalances; // user => tokenAddress => amount
    mapping(bytes32 => mapping(address => bool)) private roles; // role => account => hasRole
    mapping(uint256 => Quest) public quests;
    mapping(address => mapping(uint256 => QuestStatus)) public userQuestStatuses;

    address private _owner; // The initial deployer, typically holding ADMIN_ROLE
    bool private _paused;

    uint256 public questCounter = 0; // Simple counter for quest IDs

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert Unauthorized(msg.sender, "OWNER");
        _;
    }

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert Unauthorized(msg.sender, role);
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _grantRole(ADMIN_ROLE, msg.sender); // Deployer is admin by default
    }

    // --- Role Management (Basic) ---
    function _grantRole(bytes32 role, address account) internal {
        if (!roles[role][account]) {
            roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (roles[role][account]) {
             // Prevent removing ADMIN_ROLE from the owner or removing OWNER role if it existed
            if (role == ADMIN_ROLE && account == _owner) revert CannotWithdrawAdminRoles();
            roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function grantRole(bytes32 role, address account) external onlyOwner {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyOwner {
        _revokeRole(role, account);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[role][account];
    }

    // --- Pausability ---
    function pauseContract() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyRole(ADMIN_ROLE) whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    // --- Identity & Profile Management ---
    function registerIdentity() external whenNotPaused {
        if (userProfiles[msg.sender].registered) revert AlreadyRegistered(msg.sender);
        userProfiles[msg.sender].registered = true;
        userProfiles[msg.sender].reputationPoints = 0;
        userProfiles[msg.sender].lastReputationUpdateTime = block.timestamp; // Initialize update time
        emit IdentityRegistered(msg.sender, block.timestamp);
        emit ReputationUpdated(msg.sender, 0, "Identity Registered");
    }

    function updateProfileMetadata(string calldata metadataURI) external whenNotPaused {
        if (!userProfiles[msg.sender].registered) revert IdentityNotRegistered(msg.sender);
        userProfiles[msg.sender].metadataURI = metadataURI;
        emit ProfileMetadataUpdated(msg.sender, metadataURI);
    }

    function getProfile(address user) external view returns (UserProfile memory) {
         // Return a copy of the struct, excluding the internal mapping (lastEndorsementTime)
        UserProfile storage profile = userProfiles[user];
        return UserProfile({
            registered: profile.registered,
            reputationPoints: _calculateCurrentReputation(user), // Return current reputation
            lastReputationUpdateTime: profile.lastReputationUpdateTime,
            metadataURI: profile.metadataURI,
            lastEndorsementTime: profile.lastEndorsementTime // This mapping won't be visible externally directly this way, but included for struct completeness
        });
    }

    // Calculates current reputation considering decay
    function getReputation(address user) public view returns (uint256) {
        return _calculateCurrentReputation(user);
    }

    // --- Reputation System (Internal & External) ---
    function _calculateCurrentReputation(address user) internal view returns (uint256) {
        UserProfile storage profile = userProfiles[user];
        if (!profile.registered) return 0; // Or handle as error/special case

        uint256 currentTime = block.timestamp;
        uint256 lastUpdateTime = profile.lastReputationUpdateTime;
        uint256 currentReputation = profile.reputationPoints;

        if (currentTime > lastUpdateTime && reputationDecayPeriod > 0) {
            uint256 timeElapsed = currentTime - lastUpdateTime;
            uint256 decayPeriods = timeElapsed / reputationDecayPeriod;
            uint256 decayAmount = decayPeriods * reputationDecayRate;
            
            // Prevent underflow, reputation doesn't go below zero
            currentReputation = currentReputation > decayAmount ? currentReputation - decayAmount : 0;
        }
        return currentReputation;
    }

     // Internal function to apply decay and update timestamp
    function _applyReputationDecay(address user) internal {
        UserProfile storage profile = userProfiles[user];
         if (!profile.registered) return;

        uint256 oldReputation = profile.reputationPoints;
        uint256 currentReputation = _calculateCurrentReputation(user); // Calculate based on current time
        uint256 decayedAmount = oldReputation > currentReputation ? oldReputation - currentReputation : 0;

        profile.reputationPoints = currentReputation; // Update stored reputation
        profile.lastReputationUpdateTime = block.timestamp; // Reset update time
        if (decayedAmount > 0) {
             emit ReputationDecayed(user, oldReputation, currentReputation, decayedAmount);
        }
    }

    // Public function to trigger decay for a user (pull mechanism)
    function decayReputation(address user) external whenNotPaused {
        if (msg.sender != user && !hasRole(ADMIN_ROLE, msg.sender) && !hasRole(ORACLE_ROLE, msg.sender)) {
             revert Unauthorized(msg.sender, "Self or Admin/Oracle");
        }
        if (!userProfiles[user].registered) revert IdentityNotRegistered(user);
        _applyReputationDecay(user);
    }


    // Internal function to earn RP
    function _earnReputation(address user, uint256 amount, string memory reason) internal {
        if (!userProfiles[user].registered) revert IdentityNotRegistered(user);
        if (amount == 0) revert InvalidReputationAmount(); // Prevent earning 0

        // Apply decay before adding to ensure base is current
        _applyReputationDecay(user);

        uint256 currentReputation = userProfiles[user].reputationPoints;
        uint256 newReputation = currentReputation + amount;
        if (newReputation > MAX_REPUTATION) {
            newReputation = MAX_REPUTATION; // Cap reputation
        }
        userProfiles[user].reputationPoints = newReputation;
        userProfiles[user].lastReputationUpdateTime = block.timestamp; // Reset update time on earning
        emit ReputationUpdated(user, newReputation, reason);
    }

    // Internal function to spend RP
    function _spendReputation(address user, uint256 amount, string memory reason) internal {
        if (!userProfiles[user].registered) revert IdentityNotRegistered(user);
         if (amount == 0) revert InvalidReputationAmount(); // Prevent spending 0

        // Apply decay before spending to ensure sufficient balance
        _applyReputationDecay(user);

        uint256 currentReputation = userProfiles[user].reputationPoints;
        if (currentReputation < amount) revert InsufficientReputation(currentReputation, amount);

        uint256 newReputation = currentReputation - amount;
        userProfiles[user].reputationPoints = newReputation;
        userProfiles[user].lastReputationUpdateTime = block.timestamp; // Reset update time on spending
        emit ReputationUpdated(user, newReputation, reason);
    }

    function setReputationDecayRate(uint256 ratePerPeriod) external onlyRole(ADMIN_ROLE) {
        reputationDecayRate = ratePerPeriod;
    }

    function setReputationDecayPeriod(uint256 periodSeconds) external onlyRole(ADMIN_ROLE) {
        reputationDecayPeriod = periodSeconds;
    }


    // --- Dynamic Asset Vault (ERC20 Specific) ---
    function depositERC20(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
        if (!userProfiles[msg.sender].registered) revert IdentityNotRegistered(msg.sender);
        if (amount == 0) revert InsufficientVaultBalance(tokenAddress, 0, 1); // Simple check for > 0

        // Transfer tokens from user to contract
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        // Update internal balance
        vaultBalances[msg.sender][tokenAddress] += amount;

        emit AssetDeposited(msg.sender, tokenAddress, amount);
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
        if (!userProfiles[msg.sender].registered) revert IdentityNotRegistered(msg.sender);
        uint256 currentBalance = vaultBalances[msg.sender][tokenAddress];
        if (currentBalance < amount) revert InsufficientVaultBalance(tokenAddress, currentBalance, amount);

        // Update internal balance
        vaultBalances[msg.sender][tokenAddress] -= amount;

        // Transfer tokens from contract back to user
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amount);

        emit AssetWithdrawal(msg.sender, tokenAddress, amount);
    }

    function getVaultERC20Amount(address user, address tokenAddress) external view returns (uint256) {
         if (!userProfiles[user].registered) revert IdentityNotRegistered(user);
         return vaultBalances[user][tokenAddress];
    }

    // Example of a dynamic attribute calculation based on reputation
    // This is purely conceptual and depends on how "yield multiplier" is applied off-chain or in another contract interaction.
    function getVaultERC20YieldMultiplier(address user, address tokenAddress) external view returns (uint256) {
         if (!userProfiles[user].registered) revert IdentityNotRegistered(user);
         if (vaultBalances[user][tokenAddress] == 0) revert VaultEmpty(tokenAddress); // Only apply multiplier if asset exists

         uint256 currentReputation = _calculateCurrentReputation(user);

         // Simple example formula: 10000 + (RP * 10) -> meaning a multiplier of 1x (base) + (RP/1000) * 0.1x
         // For example: RP 0 = 10000 (1x), RP 1000 = 11000 (1.1x), RP 5000 = 15000 (1.5x), RP 10000 = 20000 (2x)
         // This needs careful scaling depending on desired range. Using 10000 as base for 1.0000x
         uint256 baseMultiplier = 10000; // Represents 1.0000x
         uint256 reputationBonus = (currentReputation * 10000) / MAX_REPUTATION; // Max bonus = 10000 (another 1.0000x)

        return baseMultiplier + reputationBonus; // Total multiplier (scaled by 10000)
    }


    // --- Quest System ---
    function createQuest(uint256 questId, uint256 requiredReputation, uint256 rewardReputation, string calldata questMetadataURI) external onlyRole(ADMIN_ROLE) whenNotPaused {
        if (quests[questId].exists) revert QuestNotFound(questId); // Use QuestNotFound as "already exists" error
        if (requiredReputation > MAX_REPUTATION || rewardReputation > MAX_REPUTATION) revert InvalidReputationAmount(); // Simple bounds check

        quests[questId] = Quest({
            exists: true,
            active: true,
            requiredReputation: requiredReputation,
            rewardReputation: rewardReputation,
            metadataURI: questMetadataURI
        });
        questCounter++; // Increment counter, although questId is manual in this version
        emit QuestCreated(questId, requiredReputation, rewardReputation);
    }

     function updateQuestMetadata(uint256 questId, string calldata newMetadataURI) external onlyRole(ADMIN_ROLE) whenNotPaused {
        if (!quests[questId].exists) revert QuestNotFound(questId);
        quests[questId].metadataURI = newMetadataURI;
        emit QuestMetadataUpdated(questId, newMetadataURI);
    }


    function startQuest(uint256 questId) external whenNotPaused {
        if (!userProfiles[msg.sender].registered) revert IdentityNotRegistered(msg.sender);
        Quest storage quest = quests[questId];
        if (!quest.exists || !quest.active) revert QuestNotFound(questId);
        if (userQuestStatuses[msg.sender][questId] != QuestStatus.NotStarted) revert QuestAlreadyStarted(msg.sender, questId);

        uint256 currentReputation = _calculateCurrentReputation(msg.sender); // Check live RP
        if (currentReputation < quest.requiredReputation) {
            revert InsufficientReputation(currentReputation, quest.requiredReputation);
        }

        userQuestStatuses[msg.sender][questId] = QuestStatus.InProgress;
        emit QuestStarted(msg.sender, questId);
    }

    // Verification function called by ORACLE or ADMIN
    function verifyQuestCompletion(address user, uint256 questId, bool success) external onlyRole(ORACLE_ROLE) whenNotPaused {
        if (!userProfiles[user].registered) revert IdentityNotRegistered(user);
        Quest storage quest = quests[questId];
        if (!quest.exists) revert QuestNotFound(questId); // Verification applies even if quest becomes inactive later? Decide logic. Let's allow verification of completed attempts.
        if (userQuestStatuses[user][questId] != QuestStatus.InProgress) revert QuestNotInProgress(user, questId);

        userQuestStatuses[user][questId] = success ? QuestStatus.Completed : QuestStatus.Failed;

        uint256 awardedReputation = 0;
        if (success) {
            awardedReputation = quest.rewardReputation;
            _earnReputation(user, awardedReputation, string(abi.encodePacked("Quest Completion: ", uint256(questId))));
        }
        // Optionally, add penalty for failure: _spendReputation(user, penaltyAmount, "Quest Failed");

        emit QuestCompletionVerified(user, questId, success, awardedReputation);
    }

    function getUserQuestStatus(address user, uint256 questId) external view returns (QuestStatus) {
        // Doesn't require registration check here, returns NotStarted (0) if user or quest doesn't exist
        return userQuestStatuses[user][questId];
    }

    // --- Social & Achievement ---
    function endorseUser(address userToEndorse) external whenNotPaused {
        if (msg.sender == userToEndorse) revert CannotEndorseSelf();
        if (!userProfiles[msg.sender].registered) revert IdentityNotRegistered(msg.sender);
        if (!userProfiles[userToEndorse].registered) revert IdentityNotRegistered(userToEndorse);

        // Check endorser cooldown for this specific user
        uint256 lastEndorsementTime = userProfiles[msg.sender].lastEndorsementTime[userToEndorse];
        if (block.timestamp < lastEndorsementTime + ENDORSEMENT_COOLDOWN) {
             revert EndorsementOnCooldown(userToEndorse, (lastEndorsementTime + ENDORSEMENT_COOLDOWN) - block.timestamp);
        }

        // Apply decay before checking and spending/earning
        _applyReputationDecay(msg.sender);
        _applyReputationDecay(userToEndorse);

        // Spend reputation from endorser
        _spendReputation(msg.sender, endorsementCost, string(abi.encodePacked("Endorsing user ", userToEndorse)));

        // Earn reputation for endorsed user
        _earnReputation(userToEndorse, endorsementGain, string(abi.encodePacked("Endorsed by user ", msg.sender)));

        // Update cooldown
        userProfiles[msg.sender].lastEndorsementTime[userToEndorse] = block.timestamp;

        emit UserEndorsed(msg.sender, userToEndorse, userProfiles[msg.sender].reputationPoints, userProfiles[userToEndorse].reputationPoints);
    }

    // Example achievement: allows resetting endorsement cooldown once RP is high enough
    function claimAchievementReward(uint256 achievementId) external whenNotPaused {
        if (!userProfiles[msg.sender].registered) revert IdentityNotRegistered(msg.sender);
         uint256 currentReputation = _calculateCurrentReputation(msg.sender);

        if (achievementId == 1) { // Example: Achievement 1 = Reach 500 RP
            if (currentReputation < 500) revert InsufficientReputation(currentReputation, 500);
            // Reward: Reset all endorsement cooldowns for the user
            // This is tricky to implement efficiently on-chain. A simple way is to
            // set a flag or timestamp that overrides individual cooldowns temporarily.
            // For simplicity, let's just emit the event and assume off-chain logic handles the reward.
            // A more complex on-chain reward could be earning a special boost token or unlocking a feature.
             // Let's implement a simple RP boost instead for on-chain effect.
             uint256 bonusRP = 100; // Example small bonus
             _earnReputation(msg.sender, bonusRP, string(abi.encodePacked("Achievement Claimed #", uint256(achievementId))));

        } else {
             // Add more achievements here
             revert("Unknown achievement ID"); // Or a specific error
        }

        emit AchievementRewardClaimed(msg.sender, achievementId);
    }

    // --- Utility ---
    // Allows ADMIN_ROLE to withdraw any stuck ERC20 tokens from the contract
    function withdrawContractBalanceERC20(address tokenAddress) external onlyRole(ADMIN_ROLE) nonReentrant {
         if (tokenAddress == address(0)) revert("Cannot withdraw native token");
         IERC20 token = IERC20(tokenAddress);
         uint256 balance = token.balanceOf(address(this));
         if (balance == 0) revert("No balance to withdraw");

         token.safeTransfer(_owner, balance); // Withdraw to the contract owner
    }
}
```

---

**Explanation of Concepts & Code Choices:**

1.  **Decentralized Identity (`UserProfile`, `registerIdentity`):** Instead of just using `msg.sender`, users explicitly `registerIdentity`. This allows associating additional data (`metadataURI`) and state (`reputationPoints`, `lastReputationUpdateTime`) with an address within the system. It's a simplified take on on-chain identity.
2.  **Dynamic Reputation (`reputationPoints`, `lastReputationUpdateTime`, `decayReputation`, `_calculateCurrentReputation`, `_earnReputation`, `_spendReputation`):**
    *   Reputation (`reputationPoints`) is a core state variable for each user.
    *   It's *dynamic* because it changes based on actions (`_earnReputation`, `_spendReputation`) and also *decays* over time.
    *   The decay mechanism is implemented using `lastReputationUpdateTime` and a `decayReputation` function. To be gas-efficient, decay is calculated and applied *when the user's reputation is needed* (`_calculateCurrentReputation`) or when specifically triggered by the user (or admin/oracle) via `decayReputation`. This avoids expensive loops over all users.
    *   `MAX_REPUTATION` introduces a conceptual cap.
3.  **Dynamic Asset Vault (`vaultBalances`, `depositERC20`, `withdrawERC20`, `getVaultERC20Amount`, `getVaultERC20YieldMultiplier`):**
    *   The contract acts as a vault holding specific ERC20 tokens on behalf of users (`vaultBalances`).
    *   The `getVaultERC20YieldMultiplier` function is the "dynamic attribute" part. It's a `view` function that calculates a conceptual "multiplier" based on the user's *current reputation*. This multiplier itself isn't applied *within* this contract (that would require integrating a yield-farming or staking mechanism), but it provides data that *off-chain applications* or *other contracts* interacting with this one could use to provide dynamic benefits to users based on their reputation. This keeps the core contract focused while showcasing the dynamic attribute concept.
    *   Uses `SafeERC20` and `nonReentrant` for secure token handling.
4.  **Quest System (`Quest`, `quests`, `QuestStatus`, `userQuestStatuses`, `createQuest`, `startQuest`, `verifyQuestCompletion`, `getUserQuestStatus`):**
    *   Defines quests with requirements and rewards.
    *   Users transition through `QuestStatus` (`NotStarted` -> `InProgress` -> `Completed`/`Failed`).
    *   Crucially, quest completion is *verified* by an address with the `ORACLE_ROLE`. This simulates interaction with off-chain events or manual verification, a common pattern for bridging on-chain state with real-world actions or complex game logic.
    *   Successful completion rewards reputation points.
5.  **Social Endorsement (`endorseUser`, `lastEndorsementTime`):** A custom social mechanic where users can transfer/spend their reputation to endorse another, with a cooldown to prevent spamming. This directly links user interaction to the core reputation metric.
6.  **Achievement Reward (`claimAchievementReward`):** A conceptual function allowing users to claim rewards tied to reaching certain reputation thresholds or other criteria. The example implementation gives a small RP boost, but this could be extended to unlock features, special roles, or other benefits handled by off-chain logic or integrated partner contracts.
7.  **Role-Based Access Control (`roles`, `ADMIN_ROLE`, `ORACLE_ROLE`, `onlyRole`, `grantRole`, `revokeRole`, `hasRole`):** A basic custom implementation of access control roles instead of inheriting a standard library. The `ADMIN_ROLE` can manage settings and roles, while the `ORACLE_ROLE` is specifically for verifying quests. The deployer gets `ADMIN_ROLE`. Includes a safety check to prevent removing the owner's admin role.
8.  **Pausability (`_paused`, `paused`, `pauseContract`, `unpauseContract`, `whenNotPaused`, `whenPaused`):** Allows an admin to pause critical functions in case of emergencies.
9.  **Utility (`withdrawContractBalanceERC20`):** A necessary admin function to recover any ERC20 tokens accidentally sent directly to the contract address or left over from vault operations.

This contract provides a framework for a reputation-gated system with dynamic asset properties and interactive elements, going beyond standard token or simple contract patterns. The dynamic reputation decay and RP-based asset boosting are key advanced/creative aspects. The required 20+ functions are met by breaking down the core system into granular actions and including necessary utility and access control functions.