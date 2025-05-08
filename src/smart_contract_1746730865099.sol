Okay, let's design a smart contract that incorporates several advanced, creative, and trendy concepts without directly duplicating a standard open-source protocol.

We will create a **Decentralized Reputation and Achievement Network (DRAN)**. This contract will manage user reputation scores, track achievements based on reputation thresholds or challenge completion, and issue dynamic "Soulbound" (non-transferable) achievement tokens whose metadata changes based on the user's current reputation. It will also integrate with an Oracle to verify off-chain challenge completions.

**Key Advanced/Trendy Concepts Used:**

1.  **Decentralized Reputation:** On-chain score tracking.
2.  **Soulbound Tokens (SBTs) / Non-Transferable NFTs:** Achievements represented as non-transferable tokens tied to an address.
3.  **Dynamic NFT Metadata:** The metadata/visuals of the achievement tokens change based on the user's real-time reputation score.
4.  **Reputation Decay:** Reputation score decreases over time if not maintained by activity.
5.  **Oracle Integration:** Using an oracle pattern to verify off-chain or complex challenge completions.
6.  **Tiered Access/Benefits:** Functions that grant access or calculate benefits based on reputation and unlocked achievements.
7.  **Gamification:** Defining challenges users can complete.
8.  **State-Based Logic:** Logic heavily depends on the current state of a user's profile (reputation, achievements).

---

### Outline and Function Summary

**Contract Name:** DRANReputationNetwork

**Core Purpose:** To manage user reputation, track and issue dynamic, non-transferable achievements (NTAs), integrate with an oracle for challenge verification, and provide query functions for user status and benefits.

**Modules:**

1.  **Admin & Configuration:** Setup and management of the network parameters, achievements, challenges, and oracle.
2.  **Reputation Management:** Logic for calculating, awarding, and decaying user reputation.
3.  **Achievement Management:** Logic for defining, unlocking, and querying user achievements (NTAs).
4.  **Challenge Management:** Logic for defining challenges and processing user submissions/oracle results.
5.  **NFT/SBT Simulation:** Functions to simulate the existence and dynamic metadata of non-transferable achievement tokens.
6.  **Query & Utility:** Functions to retrieve user data, check eligibility for benefits, etc.
7.  **Pause/Unpause:** Standard contract pausing mechanism.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner and initial oracle address.
2.  `setOracleAddress(address _oracle)`: (Admin) Sets the address of the trusted oracle contract.
3.  `setReputationDecayRate(uint256 _decayRate)`: (Admin) Sets the rate of reputation decay per unit of time.
4.  `createAchievementType(string memory _name, string memory _description, uint256 _minReputationRequired)`: (Admin) Defines a new type of achievement that can be unlocked based on reputation score.
5.  `updateAchievementType(uint256 _achievementId, string memory _name, string memory _description, uint256 _minReputationRequired)`: (Admin) Updates details of an existing achievement type.
6.  `defineChallenge(string memory _name, string memory _description, uint256 _reputationReward, uint256 _unlockAchievementId, bytes32 _challengeIdentifier)`: (Admin) Defines a new challenge that users can complete, optionally requiring oracle verification via `_challengeIdentifier`.
7.  `updateChallenge(uint256 _challengeId, string memory _name, string memory _description, uint256 _reputationReward, uint256 _unlockAchievementId, bytes32 _challengeIdentifier)`: (Admin) Updates details of an existing challenge.
8.  `grantAdminReputation(address _user, uint256 _amount)`: (Admin) Manually grants reputation to a user (use cautiously).
9.  `deductAdminReputation(address _user, uint256 _amount)`: (Admin) Manually deducts reputation from a user (use cautiously).
10. `submitChallengeProof(uint256 _challengeId, bytes memory _proofData)`: (User) User submits proof for a challenge that requires oracle verification. This triggers an event for the oracle to pick up.
11. `processOracleChallengeResult(address _user, uint256 _challengeId, bool _success, bytes32 _challengeIdentifier)`: (Oracle) The trusted oracle calls this to confirm the result of a user's challenge submission. Awards reputation/unlocks achievements if successful.
12. `completeSimpleChallenge(uint256 _challengeId)`: (User) User calls this for simple, on-chain verifiable challenges (doesn't require separate oracle step).
13. `calculateCurrentReputation(address _user)`: (View) Calculates and returns the user's current reputation score, accounting for decay up to the current time.
14. `getUserProfile(address _user)`: (View) Returns the user's full profile data (last updated reputation, unlocked achievements).
15. `getAchievementDetails(uint256 _achievementId)`: (View) Returns details of a specific achievement type.
16. `getChallengeDetails(uint256 _challengeId)`: (View) Returns details of a specific challenge type.
17. `getUserAchievementStatus(address _user, uint256 _achievementId)`: (View) Checks if a user has unlocked a specific achievement.
18. `getAllUserAchievements(address _user)`: (View) Returns a list of all achievement IDs unlocked by a user.
19. `getAchievementTokenURI(address _user, uint256 _achievementId)`: (View) Generates a dynamic URI for the achievement "token", simulating dynamic metadata based on the user's `calculateCurrentReputation()`.
20. `isEligibleForBenefitTier(address _user, uint256 _minReputationRequired, uint256[] memory _requiredAchievements)`: (View) Checks if a user meets the criteria (reputation and specific achievements) for a certain benefit tier.
21. `getVotingWeight(address _user)`: (View) Calculates a hypothetical voting weight based on user's current reputation and unlocked achievements.
22. `pause()`: (Admin) Pauses contract functionality (prevents state-changing operations).
23. `unpause()`: (Admin) Unpauses contract functionality.
24. `_calculateDecayedReputation(uint256 _initialReputation, uint256 _lastUpdateTime, uint256 _decayRate)`: (Internal Pure) Helper to calculate reputation after decay.
25. `_updateReputation(address _user, uint256 _amount, bool _isAward)`: (Internal) Handles awarding or deducting reputation, applies decay, and triggers achievement checks.
26. `_checkAndUnlockAchievements(address _user, uint256 _newReputation)`: (Internal) Checks if new achievements are unlocked based on the new reputation score.
27. `_unlockAchievement(address _user, uint256 _achievementId)`: (Internal) Marks an achievement as unlocked for a user.

*(Note: Functions 13-21 are view/pure functions, which are common and necessary for querying. Functions 24-27 are internal helpers, breaking down complex logic.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Outline and Function Summary ---
// Contract Name: DRANReputationNetwork
// Core Purpose: To manage user reputation, track and issue dynamic, non-transferable achievements (NTAs),
//               integrate with an oracle for challenge verification, and provide query functions for user
//               status and benefits within a Decentralized Reputation and Achievement Network (DRAN).

// Modules:
// 1. Admin & Configuration: Setup and management of the network parameters, achievements, challenges, and oracle.
// 2. Reputation Management: Logic for calculating, awarding, and decaying user reputation.
// 3. Achievement Management: Logic for defining, unlocking, and querying user achievements (NTAs).
// 4. Challenge Management: Logic for defining challenges and processing user submissions/oracle results.
// 5. NFT/SBT Simulation: Functions to simulate the existence and dynamic metadata of non-transferable achievement tokens.
// 6. Query & Utility: Functions to retrieve user data, check eligibility for benefits, etc.
// 7. Pause/Unpause: Standard contract pausing mechanism.

// Function Summary:
// 1. constructor(): Initializes the contract, setting the owner and initial oracle address.
// 2. setOracleAddress(address _oracle): (Admin) Sets the address of the trusted oracle contract.
// 3. setReputationDecayRate(uint256 _decayRate): (Admin) Sets the rate of reputation decay per unit of time (e.g., decay points per block.timestamp second).
// 4. createAchievementType(string memory _name, string memory _description, uint256 _minReputationRequired): (Admin) Defines a new type of achievement.
// 5. updateAchievementType(uint256 _achievementId, string memory _name, string memory _description, uint256 _minReputationRequired): (Admin) Updates details of an existing achievement type.
// 6. defineChallenge(string memory _name, string memory _description, uint256 _reputationReward, uint256 _unlockAchievementId, bytes32 _challengeIdentifier): (Admin) Defines a new challenge. _unlockAchievementId = 0 if no achievement is tied directly. _challengeIdentifier = 0 if no oracle is needed.
// 7. updateChallenge(uint256 _challengeId, string memory _name, string memory _description, uint256 _reputationReward, uint256 _unlockAchievementId, bytes32 _challengeIdentifier): (Admin) Updates details of an existing challenge.
// 8. grantAdminReputation(address _user, uint256 _amount): (Admin) Manually grants reputation.
// 9. deductAdminReputation(address _user, uint256 _amount): (Admin) Manually deducts reputation.
// 10. submitChallengeProof(uint256 _challengeId, bytes memory _proofData): (User) User submits proof for an oracle-verified challenge. Emits event for oracle pickup.
// 11. processOracleChallengeResult(address _user, uint256 _challengeId, bool _success, bytes32 _challengeIdentifier): (Oracle) Oracle calls this to confirm challenge result.
// 12. completeSimpleChallenge(uint256 _challengeId): (User) User calls this for simple, on-chain challenges.
// 13. calculateCurrentReputation(address _user): (View) Calculates current reputation including decay.
// 14. getUserProfile(address _user): (View) Returns user profile data.
// 15. getAchievementDetails(uint256 _achievementId): (View) Returns details of an achievement type.
// 16. getChallengeDetails(uint256 _challengeId): (View) Returns details of a challenge type.
// 17. getUserAchievementStatus(address _user, uint256 _achievementId): (View) Checks if a user has unlocked an achievement.
// 18. getAllUserAchievements(address _user): (View) Returns list of unlocked achievement IDs for user.
// 19. getAchievementTokenURI(address _user, uint256 _achievementId): (View) Generates dynamic metadata URI for an achievement NTA.
// 20. isEligibleForBenefitTier(address _user, uint256 _minReputationRequired, uint256[] memory _requiredAchievements): (View) Checks eligibility based on reputation and achievements.
// 21. getVotingWeight(address _user): (View) Calculates a hypothetical voting weight.
// 22. pause(): (Admin) Pauses contract.
// 23. unpause(): (Admin) Unpauses contract.
// 24. _calculateDecayedReputation(uint256 _initialReputation, uint256 _lastUpdateTime, uint256 _decayRate): (Internal Pure) Helper for decay calculation.
// 25. _updateReputation(address _user, int256 _amountChange): (Internal) Handles reputation updates (+/-), decay, and triggers achievement checks.
// 26. _checkAndUnlockAchievements(address _user, uint256 _newReputation): (Internal) Checks and unlocks achievements based on new reputation.
// 27. _unlockAchievement(address _user, uint256 _achievementId): (Internal) Marks an achievement as unlocked.

contract DRANReputationNetwork is Ownable, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Errors ---
    error DRAN__InvalidOracleAddress();
    error DRAN__AchievementNotFound(uint256 achievementId);
    error DRAN__ChallengeNotFound(uint256 challengeId);
    error DRAN__UnauthorizedOracle(address caller);
    error DRAN__ChallengeAlreadyCompleted(address user, uint256 challengeId);
    error DRAN__SimpleChallengeRequiresNoIdentifier(uint256 challengeId);
    error DRAN__OracleChallengeRequiresIdentifier(uint256 challengeId);
    error DRAN__InvalidAchievementIdForUnlock(uint256 achievementId);
    error DRAN__InsufficientReputationForUnlock(uint256 currentReputation, uint256 requiredReputation);
    error DRAN__AchievementAlreadyUnlocked(address user, uint256 achievementId);
    error DRAN__NegativeReputationResult(int256 newReputation);
    error DRAN__ChallengeProofIdentifierMismatch(bytes32 expected, bytes32 received);
    error DRAN__ProofDataEmpty();
    error DRAN__ChallengeRequiresProof(uint256 challengeId);

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracle);
    event ReputationDecayRateUpdated(uint256 newRate);
    event AchievementTypeCreated(uint256 indexed achievementId, string name);
    event AchievementTypeUpdated(uint256 indexed achievementId, string name);
    event ChallengeDefined(uint256 indexed challengeId, string name);
    event ChallengeUpdated(uint256 indexed challengeId, string name);
    event ReputationGranted(address indexed user, uint256 amount, address indexed granter);
    event ReputationDeducted(address indexed user, uint256 amount, address indexed granter);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation, uint256 decayApplied);
    event AchievementUnlocked(address indexed user, uint256 indexed achievementId, uint256 reputationAtUnlock);
    event ChallengeProofSubmitted(address indexed user, uint256 indexed challengeId, bytes32 challengeIdentifier);
    event ChallengeCompletedByOracle(address indexed user, uint256 indexed challengeId, bool success);
    event SimpleChallengeCompleted(address indexed user, uint256 indexed challengeId);
    event Paused(address account);
    event Unpaused(address account);

    // --- State Variables ---

    address public oracleAddress;
    uint256 public reputationDecayRate; // Rate of decay points per second

    struct UserProfile {
        uint256 reputationScore; // Current score before decay calculation on read
        uint256 lastReputationUpdateTime; // Timestamp of the last reputation update
        EnumerableSet.UintSet unlockedAchievements; // Set of achievement IDs unlocked by the user
    }

    mapping(address => UserProfile) private userProfiles;

    struct AchievementType {
        string name;
        string description;
        uint256 minReputationRequired;
        bool exists; // To check if an achievementId is valid
    }

    mapping(uint256 => AchievementType) private achievementTypes;
    uint256 private nextAchievementId = 1;

    struct ChallengeType {
        string name;
        string description;
        uint256 reputationReward;
        uint256 unlockAchievementId; // 0 if no achievement is directly unlocked by this challenge
        bytes32 challengeIdentifier; // Unique ID for challenges requiring oracle verification (0 if not required)
        bool exists; // To check if a challengeId is valid
    }

    mapping(uint256 => ChallengeType) private challenges;
    uint256 private nextChallengeId = 1;

    // Track oracle-required challenge submissions awaiting processing
    mapping(address => mapping(uint256 => bool)) private pendingOracleChallenges;

    // Track completed challenges for simple/oracle types
    mapping(address => mapping(uint256 => bool)) private completedChallenges;


    // --- Modifiers ---
    modifier onlyOracle() {
        if (_msgSender() != oracleAddress) {
            revert DRAN__UnauthorizedOracle(_msgSender());
        }
        _;
    }

    modifier onlyUserOrAdmin(address _user) {
        if (_msgSender() != _user && _msgSender() != owner()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle) Ownable(_msgSender()) Pausable(false) ReentrancyGuard() {
        if (_initialOracle == address(0)) {
            revert DRAN__InvalidOracleAddress();
        }
        oracleAddress = _initialOracle;
        reputationDecayRate = 0; // Default: no decay
        emit OracleAddressUpdated(_initialOracle);
    }

    // --- Admin & Configuration Functions ---

    function setOracleAddress(address _oracle) public onlyOwner whenNotPaused {
        if (_oracle == address(0)) {
            revert DRAN__InvalidOracleAddress();
        }
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    function setReputationDecayRate(uint256 _decayRate) public onlyOwner whenNotPaused {
        reputationDecayRate = _decayRate;
        emit ReputationDecayRateUpdated(_decayRate);
    }

    function createAchievementType(
        string memory _name,
        string memory _description,
        uint256 _minReputationRequired
    ) public onlyOwner whenNotPaused returns (uint256 achievementId) {
        achievementId = nextAchievementId++;
        achievementTypes[achievementId] = AchievementType({
            name: _name,
            description: _description,
            minReputationRequired: _minReputationRequired,
            exists: true
        });
        emit AchievementTypeCreated(achievementId, _name);
    }

    function updateAchievementType(
        uint256 _achievementId,
        string memory _name,
        string memory _description,
        uint256 _minReputationRequired
    ) public onlyOwner whenNotPaused {
        AchievementType storage achievement = achievementTypes[_achievementId];
        if (!achievement.exists) {
            revert DRAN__AchievementNotFound(_achievementId);
        }
        achievement.name = _name;
        achievement.description = _description;
        achievement.minReputationRequired = _minReputationRequired;
        emit AchievementTypeUpdated(_achievementId, _name);
    }

    function defineChallenge(
        string memory _name,
        string memory _description,
        uint256 _reputationReward,
        uint256 _unlockAchievementId, // 0 if none
        bytes32 _challengeIdentifier // 0 if simple (on-chain)
    ) public onlyOwner whenNotPaused returns (uint256 challengeId) {
         if (_unlockAchievementId != 0 && !achievementTypes[_unlockAchievementId].exists) {
             revert DRAN__InvalidAchievementIdForUnlock(_unlockAchievementId);
         }
        challengeId = nextChallengeId++;
        challenges[challengeId] = ChallengeType({
            name: _name,
            description: _description,
            reputationReward: _reputationReward,
            unlockAchievementId: _unlockAchievementId,
            challengeIdentifier: _challengeIdentifier,
            exists: true
        });
        emit ChallengeDefined(challengeId, _name);
    }

     function updateChallenge(
        uint256 _challengeId,
        string memory _name,
        string memory _description,
        uint256 _reputationReward,
        uint256 _unlockAchievementId, // 0 if none
        bytes32 _challengeIdentifier // 0 if simple (on-chain)
    ) public onlyOwner whenNotPaused {
        ChallengeType storage challenge = challenges[_challengeId];
        if (!challenge.exists) {
            revert DRAN__ChallengeNotFound(_challengeId);
        }
         if (_unlockAchievementId != 0 && !achievementTypes[_unlockAchievementId].exists) {
             revert DRAN__InvalidAchievementIdForUnlock(_unlockAchievementId);
         }
        challenge.name = _name;
        challenge.description = _description;
        challenge.reputationReward = _reputationReward;
        challenge.unlockAchievementId = _unlockAchievementId;
        challenge.challengeIdentifier = _challengeIdentifier;
        emit ChallengeUpdated(_challengeId, _name);
    }


    function grantAdminReputation(address _user, uint256 _amount) public onlyOwner whenNotPaused nonReentrant {
        _updateReputation(_user, int256(_amount));
        emit ReputationGranted(_user, _amount, _msgSender());
    }

    function deductAdminReputation(address _user, uint256 _amount) public onlyOwner whenNotPaused nonReentrant {
        // Deductions are negative amounts
        _updateReputation(_user, -1 * int256(_amount));
        emit ReputationDeducted(_user, _amount, _msgSender());
    }


    // --- Challenge & Reputation Functions ---

    // User submits proof for an oracle-verified challenge
    function submitChallengeProof(uint256 _challengeId, bytes memory _proofData) public whenNotPaused nonReentrant {
        ChallengeType storage challenge = challenges[_challengeId];
        if (!challenge.exists) {
            revert DRAN__ChallengeNotFound(_challengeId);
        }
        if (challenge.challengeIdentifier == bytes32(0)) {
             revert DRAN__SimpleChallengeRequiresNoIdentifier(_challengeId);
        }
        if (_proofData.length == 0) {
            revert DRAN__ProofDataEmpty();
        }
        if (completedChallenges[_msgSender()][_challengeId]) {
            revert DRAN__ChallengeAlreadyCompleted(_msgSender(), _challengeId);
        }

        // Mark as pending for the oracle
        pendingOracleChallenges[_msgSender()][_challengeId] = true;

        // Oracle will pick up this event to verify proofData off-chain
        emit ChallengeProofSubmitted(_msgSender(), _challengeId, challenge.challengeIdentifier);
    }

    // Oracle processes the result of a challenge proof verification
    function processOracleChallengeResult(
        address _user,
        uint256 _challengeId,
        bool _success,
        bytes32 _challengeIdentifier
    ) public onlyOracle whenNotPaused nonReentrant {
        ChallengeType storage challenge = challenges[_challengeId];
        if (!challenge.exists) {
            revert DRAN__ChallengeNotFound(_challengeId);
        }
         if (challenge.challengeIdentifier == bytes32(0)) {
             // This should not happen if the process was triggered correctly for an oracle challenge
             revert DRAN__SimpleChallengeRequiresNoIdentifier(_challengeId);
        }
        if (challenge.challengeIdentifier != _challengeIdentifier) {
             revert DRAN__ChallengeProofIdentifierMismatch(challenge.challengeIdentifier, _challengeIdentifier);
        }
        if (!pendingOracleChallenges[_user][_challengeId]) {
             // Should only process if user submitted proof and it's pending
             // Could add more specific error if needed, e.g., AlreadyProcessed, NotSubmitted
             revert DRAN__ChallengeNotFound(_challengeId); // Or a more specific error
        }
         if (completedChallenges[_user][_challengeId]) {
            revert DRAN__ChallengeAlreadyCompleted(_user, _challengeId);
        }

        // Remove pending status regardless of success
        delete pendingOracleChallenges[_user][_challengeId];

        if (_success) {
            // Award reputation and potentially unlock achievement
            _updateReputation(_user, int256(challenge.reputationReward));
            if (challenge.unlockAchievementId != 0) {
                _unlockAchievement(_user, challenge.unlockAchievementId);
            }
             completedChallenges[_user][_challengeId] = true;
        }

        emit ChallengeCompletedByOracle(_user, _challengeId, _success);
    }

    // User completes a simple challenge verifiable on-chain (e.g., sends a small tx)
    function completeSimpleChallenge(uint256 _challengeId) public whenNotPaused nonReentrant {
        ChallengeType storage challenge = challenges[_challengeId];
        if (!challenge.exists) {
            revert DRAN__ChallengeNotFound(_challengeId);
        }
        if (challenge.challengeIdentifier != bytes32(0)) {
             revert DRAN__ChallengeRequiresProof(_challengeId); // This challenge requires oracle proof
        }
        if (completedChallenges[_msgSender()][_challengeId]) {
            revert DRAN__ChallengeAlreadyCompleted(_msgSender(), _challengeId);
        }

        // Award reputation and potentially unlock achievement
        _updateReputation(_msgSender(), int256(challenge.reputationReward));
        if (challenge.unlockAchievementId != 0) {
            _unlockAchievement(_msgSender(), challenge.unlockAchievementId);
        }
        completedChallenges[_msgSender()][_challengeId] = true;

        emit SimpleChallengeCompleted(_msgSender(), _challengeId);
    }


    // Internal helper to calculate reputation after decay
    function _calculateDecayedReputation(
        uint256 _initialReputation,
        uint256 _lastUpdateTime,
        uint256 _decayRate
    ) internal view pure returns (uint256) {
        if (_decayRate == 0 || _initialReputation == 0) {
            return _initialReputation;
        }
        uint256 timeElapsed = block.timestamp - _lastUpdateTime;
        uint256 decayAmount = timeElapsed * _decayRate;
        return _initialReputation > decayAmount ? _initialReputation - decayAmount : 0;
    }

    // Internal function to handle reputation updates (award or deduct)
    function _updateReputation(address _user, int256 _amountChange) internal {
        UserProfile storage profile = userProfiles[_user];

        // Calculate current score with decay before updating
        uint256 currentDecayedReputation = _calculateDecayedReputation(
            profile.reputationScore,
            profile.lastReputationUpdateTime,
            reputationDecayRate
        );

        uint256 oldReputation = currentDecayedReputation;
        int256 newReputationSigned = int256(currentDecayedReputation) + _amountChange;

        if (newReputationSigned < 0) {
             // Option 1: Revert if reputation goes below zero
             // revert DRAN__NegativeReputationResult(newReputationSigned);
             // Option 2: Cap at zero (more user-friendly)
             newReputationSigned = 0;
        }

        uint256 newReputation = uint256(newReputationSigned);

        profile.reputationScore = newReputation; // Store the raw new score
        profile.lastReputationUpdateTime = block.timestamp; // Update timestamp

        uint256 decayApplied = oldReputation > newReputation ? oldReputation - newReputation : 0;
         if (_amountChange > 0) {
             // Adjust decayApplied if it was actually an award
             decayApplied = oldReputation > (newReputation - uint256(_amountChange)) ? oldReputation - (newReputation - uint256(_amountChange)) : 0;
         }


        emit ReputationUpdated(_user, oldReputation, newReputation, decayApplied);

        // Check if new achievements are unlocked
        _checkAndUnlockAchievements(_user, newReputation);
    }

    // Internal function to check and unlock achievements based on new reputation
    function _checkAndUnlockAchievements(address _user, uint256 _newReputation) internal {
        // Iterate through all achievement types (can be optimized if many)
        // For simplicity, we iterate up to the current max ID.
        // In a production system, managing iterable achievement IDs might be better.
        uint256 currentAchievementCount = nextAchievementId; // Iterate up to current max ID used + 1
        for (uint256 i = 1; i < currentAchievementCount; i++) {
            AchievementType storage achievement = achievementTypes[i];
            if (achievement.exists && _newReputation >= achievement.minReputationRequired) {
                // Attempt to unlock - _unlockAchievement handles the check if already unlocked
                 _unlockAchievement(_user, i);
            }
        }
    }

    // Internal function to mark an achievement as unlocked for a user
    function _unlockAchievement(address _user, uint256 _achievementId) internal {
        AchievementType storage achievement = achievementTypes[_achievementId];
        if (!achievement.exists) {
            // This case should ideally not happen if called internally after checks
            // but as a safeguard:
            revert DRAN__AchievementNotFound(_achievementId);
        }

        UserProfile storage profile = userProfiles[_user];
        if (profile.unlockedAchievements.add(_achievementId)) {
            // Successfully added (i.e., it wasn't already there)
            uint256 currentReputation = calculateCurrentReputation(_user); // Get decayed score for event
            emit AchievementUnlocked(_user, _achievementId, currentReputation);
        } else {
             // Achievement was already unlocked, do nothing
            // emit DRAN__AchievementAlreadyUnlocked(_user, _achievementId); // Optional: emit event
        }
    }


    // --- Query Functions (View/Pure) ---

    // Calculates and returns the user's current reputation score with decay applied
    function calculateCurrentReputation(address _user) public view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        return _calculateDecayedReputation(profile.reputationScore, profile.lastReputationUpdateTime, reputationDecayRate);
    }

    // Returns the user's profile struct
    function getUserProfile(address _user) public view returns (UserProfile memory) {
        // Note: This returns the stored reputationScore and lastUpdateTime.
        // calculateCurrentReputation() should be used for the actual current score.
        return userProfiles[_user];
    }

    // Returns details of a specific achievement type
    function getAchievementDetails(uint256 _achievementId) public view returns (AchievementType memory) {
         AchievementType storage achievement = achievementTypes[_achievementId];
         if (!achievement.exists) {
             revert DRAN__AchievementNotFound(_achievementId);
         }
         return achievement;
    }

     // Returns details of a specific challenge type
    function getChallengeDetails(uint256 _challengeId) public view returns (ChallengeType memory) {
         ChallengeType storage challenge = challenges[_challengeId];
         if (!challenge.exists) {
             revert DRAN__ChallengeNotFound(_challengeId);
         }
         return challenge;
    }


    // Checks if a user has unlocked a specific achievement
    function getUserAchievementStatus(address _user, uint256 _achievementId) public view returns (bool) {
        // Check if achievement type exists first
        if (!achievementTypes[_achievementId].exists) {
            // Technically, a user cannot have an achievement that doesn't exist.
            // We could return false or revert. Reverting is more informative.
             revert DRAN__AchievementNotFound(_achievementId);
        }
        return userProfiles[_user].unlockedAchievements.contains(_achievementId);
    }

    // Returns an array of achievement IDs unlocked by a user
    function getAllUserAchievements(address _user) public view returns (uint256[] memory) {
        return userProfiles[_user].unlockedAchievements.values();
    }

    // Simulates dynamic NFT metadata by generating a URI based on user state
    // This URI would typically point to an API that generates JSON metadata
    function getAchievementTokenURI(address _user, uint256 _achievementId) public view returns (string memory) {
        // Check if achievement type exists
         if (!achievementTypes[_achievementId].exists) {
             revert DRAN__AchievementNotFound(_achievementId);
         }
         // Check if user owns the achievement (simulate SBT/non-transferable)
         if (!userProfiles[_user].unlockedAchievements.contains(_achievementId)) {
             // Revert if user doesn't have the achievement token
             revert DRAN__AchievementNotFound(_achievementId); // Reusing error, but implies not unlocked for user
         }

        uint256 currentReputation = calculateCurrentReputation(_user);

        // Construct a dynamic URI. A real implementation would use a base URI
        // pointing to a server that uses these parameters to generate metadata JSON.
        // Example format: https://api.yourdran.com/metadata/{userAddress}/{achievementId}?reputation={currentReputation}
        string memory baseURI = "https://dran.network/metadata/"; // Example base URI

        // Using basic concatenation for demonstration. String manipulation is limited in Solidity.
        // A real solution would use abi.encodePacked or helper libraries/off-chain service.
        // This is a simplified representation of the concept.

        // Concatenating parts: baseURI + userAddress + "/" + achievementId + "?reputation=" + currentReputation
        // Using abi.encodePacked for robustness
         return string(abi.encodePacked(
             baseURI,
             Strings.toHexString(uint160(_user), 20), // Convert address to hex string
             "/",
             Strings.toString(_achievementId),
             "?reputation=",
             Strings.toString(currentReputation)
         ));
    }

     // Checks if a user is eligible for a benefit tier based on criteria
     // This function demonstrates how reputation and achievements can gate access
    function isEligibleForBenefitTier(
        address _user,
        uint256 _minReputationRequired,
        uint256[] memory _requiredAchievements
    ) public view returns (bool) {
        uint256 currentReputation = calculateCurrentReputation(_user);

        if (currentReputation < _minReputationRequired) {
            return false;
        }

        for (uint i = 0; i < _requiredAchievements.length; i++) {
             // Ensure the required achievement type exists
             if (!achievementTypes[_requiredAchievements[i]].exists) {
                 // Or maybe revert? Depends on desired behavior if a tier requires a non-existent achievement.
                 // For eligibility check, assuming non-existent means not met requirement.
                 return false;
             }
             if (!userProfiles[_user].unlockedAchievements.contains(_requiredAchievements[i])) {
                 return false;
             }
        }

        return true; // Meets all criteria
    }

    // Calculates a hypothetical voting weight based on reputation and achievements
    // This is a simplified example; real governance could be more complex.
    function getVotingWeight(address _user) public view returns (uint256) {
        uint256 currentReputation = calculateCurrentReputation(_user);

        // Example logic: Base weight is reputation, bonus for each unlocked achievement
        uint256 baseWeight = currentReputation;
        uint256 achievementBonus = userProfiles[_user].unlockedAchievements.length() * 100; // 100 points per achievement

        return baseWeight + achievementBonus;
    }


    // --- Pause/Unpause Functions ---

    function pause() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(_msgSender());
    }

    // Override _beforeTokenTransfer from ERC721 if using OpenZeppelin base
    // Since we are simulating, we just ensure there's no transfer function at all.
    // The 'achievements' are tracked internally and linked to the address.
    // There's no mint/burn/transfer exposed publicly.

    // Internal helper functions (already declared/part of the logic above)

    // _calculateDecayedReputation - Declared above
    // _updateReputation - Declared above
    // _checkAndUnlockAchievements - Declared above
    // _unlockAchievement - Declared above
}

// Helper library for string conversions (needed for getAchievementTokenURI)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

     // from OpenZeppelin's Address.sol/toHexString
     function toHexString(uint160 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 2 * length; i > 0; --i) {
            buffer[i - 1] = bytes1(uint8(48 + value % 16 + (value % 16 > 9 ? 39 : 0)));
            value /= 16;
        }
        return string(buffer);
    }
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic Reputation with Decay:** The `reputationScore` is not static. `calculateCurrentReputation` applies a decay rate based on the time elapsed since the last update (`lastReputationUpdateTime`). This encourages continued engagement. The `_updateReputation` function is central, handling both positive and negative changes and resetting the timestamp.
2.  **State-Based Non-Transferable Achievements (SBT-like NTAs):** Achievements are tracked directly in the user's profile via an `EnumerableSet`. There are no standard ERC-721 `transferFrom` or `safeTransferFrom` functions. This makes the achievements permanently tied to the user's address, fitting the Soulbound concept.
3.  **Dynamic Achievement Metadata:** The `getAchievementTokenURI` function doesn't return a static link. It constructs a URL that includes the user's *current* calculated reputation. This simulates an off-chain metadata service that could dynamically generate the NFT's image, description, or traits based on the user's real-time status in the DRAN.
4.  **Oracle Integration for Challenges:** The contract distinguishes between `completeSimpleChallenge` (purely on-chain logic) and `submitChallengeProof`/`processOracleChallengeResult` (requires external verification). Users signal intent and provide proof, and a trusted `oracleAddress` confirms the outcome, making the contract interact with off-chain events in a secure way.
5.  **Tiered Benefits/Access Control:** Functions like `isEligibleForBenefitTier` and `getVotingWeight` show how the reputation score and unlocked achievements can be used programmatically on-chain to grant access, calculate governance weight, or influence other protocol mechanics.
6.  **Internal Helpers:** Using internal functions like `_updateReputation`, `_calculateDecayedReputation`, `_checkAndUnlockAchievements`, and `_unlockAchievement` breaks down complex logic, makes the code more readable, and helps ensure consistency (e.g., all reputation changes go through `_updateReputation`).
7.  **EnumerableSet:** Used for `unlockedAchievements` to efficiently store and retrieve the list of achievement IDs for a user, which is more gas-efficient than dynamic arrays for membership testing and iteration.

This contract provides a framework for a decentralized identity and reward system where user status (reputation and achievements) is dynamic, verifiable on-chain, tied to the user's address, and can influence their participation and benefits within the ecosystem or connected dApps. It goes beyond standard token contracts by building a stateful, dynamic profile system with external interaction patterns (Oracle) and simulated dynamic NFTs.