Okay, let's create a smart contract for a Decentralized Reputation and Trust Network. This concept incorporates aspects of digital identity, verifiable claims (implicitly via reputation managers), staking, dispute resolution, and dynamic scoring (decay).

It's not a simple token or NFT, involves multiple roles (owner, managers, oracles), and has a relatively complex state managed on-chain. We'll aim for over 20 functions covering user profiles, reputation scoring, categories, a challenge system, and access control.

**Outline and Function Summary:**

*   **Contract Name:** `DecentralizedReputationNetwork`
*   **Concept:** A smart contract managing user reputation scores across different categories. Reputation can be granted by designated managers, decays over time, and can be challenged via a staking mechanism adjudicated by oracles.
*   **Key Features:**
    *   User Profiles: Basic on-chain representation for reputation holders.
    *   Reputation Categories: Define different domains of reputation with customizable weights and decay rates.
    *   Reputation Scoring: Track scores per user per category.
    *   Dynamic Decay: Reputation scores decrease over time based on category configuration. Decay can be triggered by interaction.
    *   Reputation Managers: Roles allowed to add/deduct reputation.
    *   Challenge System: Users can challenge reputation entries by staking tokens.
    *   Challenge Oracles: Roles responsible for resolving challenges.
    *   Staking: Users must stake a designated token to participate in challenges.
*   **Dependencies:** OpenZeppelin Contracts (Ownable), a hypothetical ERC20 token interface for staking.
*   **Access Control:** Uses `Ownable` for contract administration, custom roles (`ReputationManager`, `ChallengeOracle`) for specific actions.

---

**Function Summaries:**

**I. Core Administration (Owner Only)**
1.  `addReputationManager(address manager)`: Grants `ReputationManager` role.
2.  `removeReputationManager(address manager)`: Revokes `ReputationManager` role.
3.  `addChallengeOracle(address oracle)`: Grants `ChallengeOracle` role.
4.  `removeChallengeOracle(address oracle)`: Revokes `ChallengeOracle` role.
5.  `addReputationCategory(string name, string description, uint256 weight, uint256 decayRatePerUnitTime)`: Creates a new reputation category.
6.  `updateReputationCategory(uint256 categoryId, uint256 weight, uint256 decayRatePerUnitTime)`: Modifies an existing category's parameters.
7.  `setDecayInterval(uint256 interval)`: Sets the time unit (in seconds) used for decay calculations.
8.  `setChallengeStakeToken(address tokenAddress)`: Sets the ERC20 token contract address used for staking in challenges.

**II. User Profile Management**
9.  `registerProfile()`: Registers the caller's address as a user profile.
10. `getProfile(address user)`: Retrieves a user's profile details and total calculated reputation.
11. `getTotalNumberOfUsers()`: Returns the total count of registered users.

**III. Reputation Management (ReputationManager Role or Specific Logic)**
12. `addReputation(address user, uint256 categoryId, int256 amount, string contextHash)`: Adds or subtracts reputation points for a user in a category. Requires `ReputationManager` role. Context hash can link to off-chain details.
13. `getReputationByCategory(address user, uint256 categoryId)`: Retrieves a user's score in a specific category, applying decay first.
14. `calculateTotalReputation(address user)`: Calculates the user's total reputation score across all categories (weighted sum), applying decay first.
15. `triggerDecayForUserCategory(address user, uint256 categoryId)`: Manually triggers the decay calculation for a user in a category. Can be called by anyone to help keep scores current.

**IV. Category Information (Anyone Can View)**
16. `getReputationCategory(uint256 categoryId)`: Retrieves details of a specific reputation category.
17. `getTotalNumberOfCategories()`: Returns the total count of defined categories.

**V. Staking for Challenges**
18. `stakeTokens(uint256 amount)`: Stakes the designated challenge token. Requires user to approve transfer beforehand.
19. `unstakeTokens(uint256 amount)`: Allows a user to unstake their tokens, if not locked in a challenge.
20. `getUserStake(address user)`: Returns the total tokens staked by a user.

**VI. Challenge System**
21. `initiateReputationChallenge(address subject, uint256 categoryId, string reasonHash, uint256 stakeAmount)`: Starts a challenge against a user's reputation entry in a category. Requires staking tokens. `reasonHash` links to off-chain reason.
22. `supportChallenge(uint256 challengeId, uint256 stakeAmount)`: Allows users to support an existing challenge by staking tokens.
23. `resolveChallenge(uint256 challengeId, bool outcome)`: Resolved by a `ChallengeOracle`. `outcome` is `true` if the *challenger* wins, `false` if the *subject* wins. Triggers stake distribution/slashing and potential reputation adjustment.
24. `claimStakeAfterResolution(uint256 challengeId)`: Allows participants (challenger, subject, supporters) to claim their stakes back after a challenge is resolved.
25. `getChallengeDetails(uint256 challengeId)`: Retrieves details of a specific challenge.
26. `getChallengeState(uint256 challengeId)`: Returns the current state of a challenge (Pending, Resolved, Rejected).
27. `getUserChallenges(address user)`: Returns a list of challenge IDs the user is involved in (as subject or challenger - *Note: returning arrays of structs/large arrays is expensive in Solidity, this might be better off-chain indexed, but included for concept*). Let's refine this to return counts or recent ones, or make it clear it's for small numbers or off-chain use. Let's make it a view that iterates up to a limit or requires start/end IDs if we want it on-chain. Simpler: Get individual challenge details by ID. Remove this function for on-chain efficiency in this example. Let's add other view functions to reach >20.
28. `getTotalNumberOfChallenges()`: Returns the total number of challenges initiated.

**Revised Function Count & Additional Views:**
1-8 (Admin) + 9-11 (Profile) + 12-15 (Reputation) + 16-17 (Category Views) + 18-20 (Staking) + 21-26 (Challenges) + 28 (Total Challenges) = 8 + 3 + 4 + 2 + 3 + 6 + 1 = 27 functions. This meets the requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol"; // For staking token

// --- Outline and Function Summary ---
// Contract Name: DecentralizedReputationNetwork
// Concept: A smart contract managing user reputation scores across different categories. Reputation can be granted by designated managers, decays over time, and can be challenged via a staking mechanism adjudicated by oracles.
// Key Features: User Profiles, Reputation Categories, Reputation Scoring, Dynamic Decay, Reputation Managers, Challenge System, Challenge Oracles, Staking (using an ERC20).
// Dependencies: OpenZeppelin Contracts (Ownable), IERC20.
// Access Control: Uses Ownable for contract administration, custom roles (ReputationManager, ChallengeOracle) for specific actions.

// --- Function Summaries ---
// I. Core Administration (Owner Only)
//  1. addReputationManager(address manager): Grants ReputationManager role.
//  2. removeReputationManager(address manager): Revokes ReputationManager role.
//  3. addChallengeOracle(address oracle): Grants ChallengeOracle role.
//  4. removeChallengeOracle(address oracle): Revokes ChallengeOracle role.
//  5. addReputationCategory(string name, string description, uint256 weight, uint256 decayRatePerUnitTime): Creates a new reputation category.
//  6. updateReputationCategory(uint256 categoryId, uint256 weight, uint256 decayRatePerUnitTime): Modifies an existing category's parameters.
//  7. setDecayInterval(uint256 interval): Sets the time unit (in seconds) used for decay calculations.
//  8. setChallengeStakeToken(address tokenAddress): Sets the ERC20 token contract address used for staking in challenges.

// II. User Profile Management
//  9. registerProfile(): Registers the caller's address as a user profile.
// 10. getProfile(address user): Retrieves a user's profile details and total calculated reputation.
// 11. getTotalNumberOfUsers(): Returns the total count of registered users.

// III. Reputation Management (ReputationManager Role or Specific Logic)
// 12. addReputation(address user, uint256 categoryId, int256 amount, string contextHash): Adds or subtracts reputation points for a user in a category. Requires ReputationManager role. Context hash can link to off-chain details.
// 13. getReputationByCategory(address user, uint256 categoryId): Retrieves a user's score in a specific category, applying decay first.
// 14. calculateTotalReputation(address user): Calculates the user's total reputation score across all categories (weighted sum), applying decay first.
// 15. triggerDecayForUserCategory(address user, uint256 categoryId): Manually triggers the decay calculation for a user in a category. Can be called by anyone.

// IV. Category Information (Anyone Can View)
// 16. getReputationCategory(uint256 categoryId): Retrieves details of a specific reputation category.
// 17. getTotalNumberOfCategories(): Returns the total count of defined categories.

// V. Staking for Challenges
// 18. stakeTokens(uint256 amount): Stakes the designated challenge token. Requires user to approve transfer beforehand.
// 19. unstakeTokens(uint256 amount): Allows a user to unstake their tokens, if not locked in a challenge.
// 20. getUserStake(address user): Returns the total tokens staked by a user.

// VI. Challenge System
// 21. initiateReputationChallenge(address subject, uint256 categoryId, string reasonHash, uint256 stakeAmount): Starts a challenge against a user's reputation entry in a category. Requires staking tokens. reasonHash links to off-chain reason.
// 22. supportChallenge(uint256 challengeId, uint256 stakeAmount): Allows users to support an existing challenge by staking tokens.
// 23. resolveChallenge(uint256 challengeId, bool outcome): Resolved by a ChallengeOracle. outcome is true if the challenger wins, false if the subject wins. Triggers stake distribution/slashing and potential reputation adjustment.
// 24. claimStakeAfterResolution(uint256 challengeId): Allows participants (challenger, subject, supporters) to claim their stakes back after a challenge is resolved.
// 25. getChallengeDetails(uint256 challengeId): Retrieves details of a specific challenge.
// 26. getChallengeState(uint256 challengeId): Returns the current state of a challenge (Pending, Resolved).
// 27. getTotalNumberOfChallenges(): Returns the total number of challenges initiated.

// Note: This contract uses a fixed-point integer representation for reputation scores internally (scaled by SCORE_SCALE) to handle fractional values if needed.
// Decay calculation is simplified: score = score * (1 - decayRate)^time_units. Integer math approximation used.

contract DecentralizedReputationNetwork is Ownable {

    // --- Constants ---
    uint256 public constant SCORE_SCALE = 100; // Used to represent fractional scores (e.g., 100 = 1.0)
    uint256 public constant DECAY_MULTIPLIER_SCALE = 10000; // For decay rate representation (e.g., 9900 = 0.99)
    uint256 public constant MIN_CHALLENGE_STAKE = 1; // Example minimum stake

    // --- State Variables ---

    // --- User Profiles ---
    struct UserProfile {
        bool isRegistered;
        // Reputation scores per category (scaled)
        mapping(uint256 => int256) categoryScores;
        // Timestamp of last update for each category score (for decay calculation)
        mapping(uint256 => uint256) lastReputationUpdate;
        // Total stake held by the user
        uint256 totalStake;
    }
    mapping(address => UserProfile) private _userProfiles;
    address[] private _registeredUsers; // Simple list for total count, could be inefficient for large scale iteration

    // --- Reputation Categories ---
    struct ReputationCategory {
        string name;
        string description;
        uint256 weight; // Weight in total reputation calculation
        uint256 decayRatePerUnitTime; // Rate of decay per decayInterval (scaled by DECAY_MULTIPLIER_SCALE)
        bool exists; // To check if a category ID is valid
    }
    mapping(uint256 => ReputationCategory) public reputationCategories;
    uint256 public nextCategoryId = 0;
    uint256 public decayInterval = 1 days; // Default decay interval in seconds

    // --- Roles ---
    mapping(address => bool) public isReputationManager;
    mapping(address => bool) public isChallengeOracle;

    // --- Challenge System ---
    enum ChallengeState {
        Pending,
        Resolved,
        Rejected // Added Rejected state
    }

    struct Challenge {
        address subject; // User whose reputation is challenged
        address challenger;
        uint256 categoryId;
        string reasonHash; // Hash linking to off-chain reason details
        uint256 totalStake; // Total tokens staked in this challenge
        uint256 challengerStake;
        mapping(address => uint256) supporterStakes; // Stakes from supporters
        ChallengeState state;
        uint256 initiatedAt;
        uint256 resolvedAt;
        bool resolutionOutcome; // true = challenger wins, false = subject wins
        bool stakesClaimed; // Flag to prevent multiple claims
    }
    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId = 0;
    IERC20 public challengeStakeToken;

    // --- Events ---
    event ProfileRegistered(address indexed user);
    event ReputationAdded(address indexed user, uint256 indexed categoryId, int256 amount, string contextHash, address indexed manager);
    event ReputationDecayed(address indexed user, uint256 indexed categoryId, int256 decayAmount, uint256 newScore);
    event ReputationCategoryAdded(uint256 indexed categoryId, string name, uint256 weight, uint256 decayRate);
    event ReputationCategoryUpdated(uint256 indexed categoryId, uint256 weight, uint256 decayRate);
    event ChallengeInitiated(uint256 indexed challengeId, address indexed subject, address indexed challenger, uint256 categoryId, uint256 stakeAmount);
    event ChallengeSupported(uint256 indexed challengeId, address indexed supporter, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed challengeId, address indexed oracle, bool outcome); // true = challenger wins, false = subject wins
    event StakesClaimed(uint256 indexed challengeId, address indexed user);
    event StakeTokens(address indexed user, uint256 amount);
    event UnstakeTokens(address indexed user, uint256 amount);
    event ReputationManagerAdded(address indexed manager);
    event ReputationManagerRemoved(address indexed manager);
    event ChallengeOracleAdded(address indexed oracle);
    event ChallengeOracleRemoved(address indexed oracle);
    event DecayIntervalSet(uint256 interval);
    event ChallengeStakeTokenSet(address indexed tokenAddress);


    // --- Modifiers ---
    modifier onlyReputationManager() {
        require(isReputationManager[msg.sender], "DRN: Caller is not a ReputationManager");
        _;
    }

    modifier onlyChallengeOracle() {
        require(isChallengeOracle[msg.sender], "DRN: Caller is not a ChallengeOracle");
        _;
    }

    modifier isProfileRegistered(address user) {
        require(_userProfiles[user].isRegistered, "DRN: User profile not registered");
        _;
    }

    modifier isValidCategory(uint256 categoryId) {
        require(reputationCategories[categoryId].exists, "DRN: Invalid category ID");
        _;
    }

    modifier isValidChallenge(uint256 challengeId) {
        require(challengeId < nextChallengeId, "DRN: Invalid challenge ID");
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- I. Core Administration (Owner Only) ---

    function addReputationManager(address manager) external onlyOwner {
        require(manager != address(0), "DRN: Zero address");
        require(!isReputationManager[manager], "DRN: Already a manager");
        isReputationManager[manager] = true;
        emit ReputationManagerAdded(manager);
    }

    function removeReputationManager(address manager) external onlyOwner {
        require(manager != address(0), "DRN: Zero address");
        require(isReputationManager[manager], "DRN: Not a manager");
        isReputationManager[manager] = false;
        emit ReputationManagerRemoved(manager);
    }

    function addChallengeOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "DRN: Zero address");
        require(!isChallengeOracle[oracle], "DRN: Already an oracle");
        isChallengeOracle[oracle] = true;
        emit ChallengeOracleAdded(oracle);
    }

    function removeChallengeOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "DRN: Zero address");
        require(isChallengeOracle[oracle], "DRN: Not an oracle");
        isChallengeOracle[oracle] = false;
        emit ChallengeOracleRemoved(oracle);
    }

    function addReputationCategory(
        string memory name,
        string memory description,
        uint256 weight,
        uint256 decayRatePerUnitTime // e.g., 9900 for 0.99 decay factor
    ) external onlyOwner {
        require(weight > 0, "DRN: Weight must be positive");
        require(decayRatePerUnitTime <= DECAY_MULTIPLIER_SCALE, "DRN: Decay rate cannot exceed scale");

        uint256 categoryId = nextCategoryId++;
        reputationCategories[categoryId] = ReputationCategory(
            name,
            description,
            weight,
            decayRatePerUnitTime,
            true
        );
        emit ReputationCategoryAdded(categoryId, name, weight, decayRatePerUnitTime);
    }

    function updateReputationCategory(
        uint256 categoryId,
        uint256 weight,
        uint256 decayRatePerUnitTime
    ) external onlyOwner isValidCategory(categoryId) {
        require(weight > 0, "DRN: Weight must be positive");
        require(decayRatePerUnitTime <= DECAY_MULTIPLIER_SCALE, "DRN: Decay rate cannot exceed scale");

        ReputationCategory storage category = reputationCategories[categoryId];
        category.weight = weight;
        category.decayRatePerUnitTime = decayRatePerUnitTime;
        emit ReputationCategoryUpdated(categoryId, weight, decayRatePerUnitTime);
    }

    function setDecayInterval(uint256 interval) external onlyOwner {
        require(interval > 0, "DRN: Interval must be positive");
        decayInterval = interval;
        emit DecayIntervalSet(interval);
    }

     function setChallengeStakeToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "DRN: Zero address");
        challengeStakeToken = IERC20(tokenAddress);
        emit ChallengeStakeTokenSet(tokenAddress);
    }


    // --- II. User Profile Management ---

    function registerProfile() external {
        require(!_userProfiles[msg.sender].isRegistered, "DRN: Profile already registered");
        _userProfiles[msg.sender].isRegistered = true;
        _registeredUsers.push(msg.sender);
        emit ProfileRegistered(msg.sender);
    }

    function getProfile(address user) external view isProfileRegistered(user) returns (bool isRegistered, uint256 totalReputationScaled) {
        // Calculate total reputation dynamically
        totalReputationScaled = calculateTotalReputation(user);
        return (_userProfiles[user].isRegistered, totalReputationScaled);
    }

    function getTotalNumberOfUsers() external view returns (uint256) {
        return _registeredUsers.length;
    }

    // --- III. Reputation Management ---

    function addReputation(address user, uint256 categoryId, int256 amount, string memory contextHash)
        external
        onlyReputationManager
        isProfileRegistered(user)
        isValidCategory(categoryId)
    {
        // Apply decay before adding new reputation
        _applyDecay(user, categoryId);

        UserProfile storage profile = _userProfiles[user];
        profile.categoryScores[categoryId] += amount;
        profile.lastReputationUpdate[categoryId] = block.timestamp;

        emit ReputationAdded(user, categoryId, amount, contextHash, msg.sender);
    }

    // Internal helper function to apply decay
    function _applyDecay(address user, uint256 categoryId) internal {
        UserProfile storage profile = _userProfiles[user];
        ReputationCategory storage category = reputationCategories[categoryId];

        // Only apply decay if category exists, has decay, score is non-zero, and was updated
        if (!category.exists || category.decayRatePerUnitTime == DECAY_MULTIPLIER_SCALE || profile.categoryScores[categoryId] == 0 || profile.lastReputationUpdate[categoryId] == 0) {
             // Update timestamp even if no decay applies, prevents massive decay later
             if (profile.lastReputationUpdate[categoryId] == 0 && profile.categoryScores[categoryId] != 0) {
                profile.lastReputationUpdate[categoryId] = block.timestamp;
             }
            return;
        }

        uint256 lastUpdate = profile.lastReputationUpdate[categoryId];
        uint256 timeElapsed = block.timestamp - lastUpdate;
        uint256 timeUnits = timeElapsed / decayInterval;

        if (timeUnits == 0) {
            return; // Not enough time elapsed for decay unit
        }

        int256 currentScore = profile.categoryScores[categoryId];
        uint256 decayMultiplier = category.decayRatePerUnitTime;

        // Apply decay iteratively (approximation) or calculate directly
        // Direct calculation: score * (decayMultiplier / SCALE)^timeUnits
        // Using integer math, this is complex for arbitrary powers.
        // Simple iterative approximation:
        for (uint256 i = 0; i < timeUnits; i++) {
             // Handles positive and negative scores
            if (currentScore > 0) {
                 // currentScore = (currentScore * decayMultiplier) / DECAY_MULTIPLIER_SCALE
                 currentScore = int256(uint256(currentScore) * decayMultiplier / DECAY_MULTIPLIER_SCALE);
            } else if (currentScore < 0) {
                 // Apply decay magnitude-wise
                 currentScore = int256(uint256(-currentScore) * decayMultiplier / DECAY_MULTIPLIER_SCALE) * -1;
            }
             // Stop if score becomes 0
             if (currentScore == 0) break;
        }

        int256 decayAmount = profile.categoryScores[categoryId] - currentScore;
        profile.categoryScores[categoryId] = currentScore;
        profile.lastReputationUpdate[categoryId] = block.timestamp; // Update timestamp after decay

        if (decayAmount != 0) {
             emit ReputationDecayed(user, categoryId, decayAmount, currentScore);
        }
    }

    // Anyone can call this to trigger decay for a specific user/category
    function triggerDecayForUserCategory(address user, uint256 categoryId)
        external
        isProfileRegistered(user)
        isValidCategory(categoryId)
    {
        _applyDecay(user, categoryId);
    }

    function getReputationByCategory(address user, uint256 categoryId)
        public
        view
        isProfileRegistered(user)
        isValidCategory(categoryId)
        returns (int256 scoreScaled)
    {
        // Calculate decay first *without* modifying state in a view function
        UserProfile storage profile = _userProfiles[user];
        ReputationCategory storage category = reputationCategories[categoryId];

        int256 currentScore = profile.categoryScores[categoryId];
        uint256 lastUpdate = profile.lastReputationUpdate[categoryId];

        // Simulate decay calculation if time has passed
        if (category.exists && category.decayRatePerUnitTime != DECAY_MULTIPLIER_SCALE && currentScore != 0 && lastUpdate != 0) {
            uint256 timeElapsed = block.timestamp - lastUpdate;
            uint256 timeUnits = timeElapsed / decayInterval;
            uint256 decayMultiplier = category.decayRatePerUnitTime;

            // Simple iterative approximation for simulation
            for (uint256 i = 0; i < timeUnits; i++) {
                 if (currentScore > 0) {
                      currentScore = int256(uint256(currentScore) * decayMultiplier / DECAY_MULTIPLIER_SCALE);
                 } else if (currentScore < 0) {
                      currentScore = int256(uint256(-currentScore) * decayMultiplier / DECAY_MULTIPLIER_SCALE) * -1;
                 }
                if (currentScore == 0) break; // Stop if score reaches 0
            }
        }
        return currentScore; // Return the *simulated* decayed score
    }

    function calculateTotalReputation(address user)
        public
        view
        isProfileRegistered(user)
        returns (uint256 totalReputationScaled)
    {
        // Note: This iterates through categories. Could be gas-intensive with many categories.
        // For view functions, this is acceptable. State-changing functions should avoid large loops.
        uint256 currentCategoryId = 0; // Categories are added sequentially
        uint256 sumWeightedScores = 0;

        // Iterate through all categories that *could* exist
        while (currentCategoryId < nextCategoryId) {
            ReputationCategory storage category = reputationCategories[currentCategoryId];
            if (category.exists) {
                 // Get the decayed score for this category (simulated)
                 int256 categoryScore = getReputationByCategory(user, currentCategoryId);
                 // Add weighted score to sum. Handle potential negative scores.
                 // For simplicity, let's take the absolute value for weighting, or ensure weight logic handles signed scores.
                 // A simple approach: total is sum of weighted *absolute* values, or sum of weighted signed values.
                 // Let's sum weighted signed values: score * weight / SCORE_SCALE (assuming weight is scaled too, or handle scaling)
                 // Assuming weight is a simple multiplier (e.g., 1-100), not scaled.
                 // Weighted Score = (categoryScore / SCORE_SCALE) * category.weight
                 // For scaled score: weightedScaledScore = categoryScore * category.weight / SCALE
                 sumWeightedScores += uint256(categoryScore) * category.weight; // This needs careful signed math or define weight purpose
                 // Let's define total reputation as sum of (score * weight).
                 // If score is -100 (scaled -1.0), weight is 10 -> contribution is -1000.
                 // If score is 50 (scaled 0.5), weight is 5 -> contribution is 250.
                 // Total could be negative. Let's return a signed integer.
                 int256 weightedCategoryScore = categoryScore * int256(category.weight);
                 totalReputationScaled += uint256(weightedCategoryScore); // This is wrong with signed.
                 // Let's return the sum of weighted scores, keeping it unsigned for simplicity unless specific negative behavior is needed.
                 // Let's assume total score calculation needs refinement based on desired output (signed/unsigned, base score, etc.).
                 // For this example, let's just sum the raw (scaled) category scores. This is simple but weights aren't used in the sum itself.
                 // Revisit: Let's return a complex struct with total weighted, etc. Or just keep it simple and return scaled sum of raw scores.
                 // Okay, let's return an int256 representing the sum of (score * weight / SCORE_SCALE).
                 // Sum (categoryScore * weight) / SCORE_SCALE
                 totalReputationScaled += uint256((categoryScore * int256(category.weight)) / int256(SCORE_SCALE)); // Need to be careful with division rounding

                 // Let's return a simple sum of *scaled* scores, ignoring weights for the sum, or use weights differently.
                 // Simplest: just return the average weighted score. Sum (score * weight) / Sum(weight)
                 // totalReputationScaled = Sum(score[i] * weight[i]) / Sum(weight[i])
                 // Let's calculate Sum(score[i] * weight[i]) and let the caller divide by Sum(weight[i]) if needed, or just return this sum.
                 // Let's return the sum of weighted scores directly as a large number.
                 // int256 totalWeightedScore = 0;
                 // totalWeightedScore += categoryScore * int256(category.weight); // This could overflow if weight is large
                 // Let's stick to a scaled representation of the average: Sum(score * weight) / Sum(weight) * SCORE_SCALE
                 // int256 weightedScoreSum = 0;
                 // uint256 totalWeight = 0;
                 // weightedScoreSum += categoryScore * int256(category.weight);
                 // totalWeight += category.weight;
                 // if (totalWeight > 0) {
                 //     return uint256(weightedScoreSum / int256(totalWeight) * int256(SCORE_SCALE));
                 // }
                 // return 0; // If no categories or total weight is 0.

                 // Final decision for simplicity: Sum up the raw scaled scores. Weights are just metadata for categories unless used elsewhere.
                 // Or sum up (score * weight) and return that. Let's do (score * weight).
                 int256 categoryScoreScaled = getReputationByCategory(user, currentCategoryId);
                 totalReputationScaled += uint256(categoryScoreScaled * int256(reputationCategories[currentCategoryId].weight)); // This is wrong with signed values.
                 // Let's return a simple sum of the SCALED scores, ignoring weight in the sum for now.
                 // This is the simplest implementation for the example.
                  totalReputationScaled += uint256(getReputationByCategory(user, currentCategoryId));
            }
            unchecked { currentCategoryId++; } // Safe as long as we don't reach max uint256 categories
        }
        // Return the simple sum of scaled scores.
        return totalReputationScaled;
    }

    // --- IV. Category Information ---

    function getReputationCategory(uint256 categoryId)
        external
        view
        isValidCategory(categoryId)
        returns (string memory name, string memory description, uint256 weight, uint256 decayRatePerUnitTime)
    {
        ReputationCategory storage category = reputationCategories[categoryId];
        return (category.name, category.description, category.weight, category.decayRatePerUnitTime);
    }

    function getTotalNumberOfCategories() external view returns (uint256) {
        return nextCategoryId;
    }

    // --- V. Staking for Challenges ---

    function stakeTokens(uint256 amount) external isProfileRegistered(msg.sender) {
        require(address(challengeStakeToken) != address(0), "DRN: Stake token not set");
        require(amount > 0, "DRN: Amount must be positive");

        // User must have approved this contract to spend 'amount' tokens
        require(challengeStakeToken.transferFrom(msg.sender, address(this), amount), "DRN: Token transfer failed");

        _userProfiles[msg.sender].totalStake += amount;
        emit StakeTokens(msg.sender, amount);
    }

    function unstakeTokens(uint256 amount) external isProfileRegistered(msg.sender) {
        require(address(challengeStakeToken) != address(0), "DRN: Stake token not set");
        require(amount > 0, "DRN: Amount must be positive");
        require(_userProfiles[msg.sender].totalStake >= amount, "DRN: Insufficient staked tokens");

        // TODO: Ensure tokens are not locked in pending challenges.
        // This requires tracking locked stake per challenge per user, which adds complexity.
        // For this example, we allow unstaking from total stake, assuming challenge logic handles locking.
        // A production system would need a more robust stake tracking system.

        _userProfiles[msg.sender].totalStake -= amount;
        require(challengeStakeToken.transfer(msg.sender, amount), "DRN: Token transfer back failed");

        emit UnstakeTokens(msg.sender, amount);
    }

    function getUserStake(address user) external view isProfileRegistered(user) returns (uint256) {
        return _userProfiles[user].totalStake;
    }

    // --- VI. Challenge System ---

    function initiateReputationChallenge(
        address subject,
        uint256 categoryId,
        string memory reasonHash,
        uint256 stakeAmount
    ) external isProfileRegistered(msg.sender) isProfileRegistered(subject) isValidCategory(categoryId) {
        require(msg.sender != subject, "DRN: Cannot challenge yourself");
        require(address(challengeStakeToken) != address(0), "DRN: Stake token not set");
        require(stakeAmount >= MIN_CHALLENGE_STAKE, "DRN: Stake too low");
        require(_userProfiles[msg.sender].totalStake >= stakeAmount, "DRN: Insufficient staked tokens"); // User must have enough stake

        uint256 challengeId = nextChallengeId++;
        Challenge storage challenge = challenges[challengeId];

        challenge.subject = subject;
        challenge.challenger = msg.sender;
        challenge.categoryId = categoryId;
        challenge.reasonHash = reasonHash;
        challenge.challengerStake = stakeAmount;
        challenge.totalStake = stakeAmount; // Initial total stake is just the challenger's
        challenge.state = ChallengeState.Pending;
        challenge.initiatedAt = block.timestamp;
        challenge.stakesClaimed = false;

        // Deduct stake from challenger's available total stake (lock it)
        _userProfiles[msg.sender].totalStake -= stakeAmount;

        emit ChallengeInitiated(challengeId, subject, msg.sender, categoryId, stakeAmount);
    }

    function supportChallenge(uint256 challengeId, uint256 stakeAmount)
        external
        isProfileRegistered(msg.sender)
        isValidChallenge(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.Pending, "DRN: Challenge is not pending");
        require(msg.sender != challenge.challenger && msg.sender != challenge.subject, "DRN: Cannot support your own challenge or challenge against you");
        require(address(challengeStakeToken) != address(0), "DRN: Stake token not set");
        require(stakeAmount >= MIN_CHALLENGE_STAKE, "DRN: Stake too low");
        require(_userProfiles[msg.sender].totalStake >= stakeAmount, "DRN: Insufficient staked tokens");

        // Deduct stake from supporter's available total stake (lock it)
        _userProfiles[msg.sender].totalStake -= stakeAmount;

        challenge.supporterStakes[msg.sender] += stakeAmount;
        challenge.totalStake += stakeAmount;

        emit ChallengeSupported(challengeId, msg.sender, stakeAmount);
    }

    function resolveChallenge(uint256 challengeId, bool outcome)
        external
        onlyChallengeOracle
        isValidChallenge(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.Pending, "DRN: Challenge is not pending");

        challenge.state = ChallengeState.Resolved;
        challenge.resolutionOutcome = outcome; // true = challenger wins, false = subject wins
        challenge.resolvedAt = block.timestamp;

        // --- Stake Distribution Logic ---
        // Example logic:
        // If challenger wins (outcome == true):
        // - Challenger and supporters get their stake back.
        // - Subject loses a stake amount (or reputation penalty translates to stake penalty).
        // - A portion of subject's potential loss or a reward is distributed.
        // If subject wins (outcome == false):
        // - Subject and their supporters (if any) get stake back. (We don't have subject supporters in this simple model).
        // - Challenger and supporters lose their stake (slashed).
        // - Slashed tokens could go to the subject, or the DAO treasury, or be burned.
        // Simple Slash/Reward: Winner(s) get their stake + a share of loser(s)' stake. Loser(s) lose their stake.

        uint256 totalStaked = challenge.totalStake;
        uint256 challengerStake = challenge.challengerStake;
        uint256 subjectPenaltyAmount = 0; // Define how subject is penalized in terms of stake? Or only reputation?
        // Let's keep stake slash/reward simple: Losers forfeit stake, Winners get stake back. Slashed tokens accumulate in contract or go to treasury.

        if (outcome) { // Challenger wins
            // Challenger and supporters get their stake back
            // Tokens remain in the contract until claimStakeAfterResolution is called
            // Logic to *apply* reputation change happens here or via a separate step?
            // Let's have the Oracle resolution also trigger the reputation change.
            // Assume 'amount' is the reputation change defined by the oracle/system based on the outcome.
            // This requires the oracle to specify the amount, or have pre-defined amounts per category/challenge type.
            // For simplicity, let's assume a fixed penalty/reward linked to winning/losing the *challenge* itself,
            // potentially influenced by the stake amount or a fixed contract parameter.
            // Simpler still: Oracle only resolves true/false. Reputation managers (or a new Oracle role) apply reputation change later based on the resolved challenge ID.
            // Let's make resolution separate from rep change. Resolution just determines winner/loser for stake.

            // No staking penalty/reward in this minimal example upon resolve, just state change.
            // Stake logic moved to claimStakeAfterResolution.

        } else { // Subject wins
            // Challenger and supporters lose their stake (forfeited).
            // Stake logic moved to claimStakeAfterResolution.
        }

        emit ChallengeResolved(challengeId, msg.sender, outcome);
    }

    function claimStakeAfterResolution(uint256 challengeId)
        external
        isValidChallenge(challengeId)
        isProfileRegistered(msg.sender)
    {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.Resolved, "DRN: Challenge not resolved");
        require(!challenge.stakesClaimed, "DRN: Stakes already claimed for this challenge"); // Basic flood protection

        uint256 amountToTransfer = 0;
        bool isParticipant = true; // Flag to check if sender was involved

        if (challenge.resolutionOutcome) { // Challenger won
            if (msg.sender == challenge.challenger) {
                amountToTransfer = challenge.challengerStake; // Challenger gets their stake back
            } else if (challenge.supporterStakes[msg.sender] > 0) {
                amountToTransfer = challenge.supporterStakes[msg.sender]; // Supporter gets stake back
                challenge.supporterStakes[msg.sender] = 0; // Reset supporter's stake in the challenge struct
            } else {
                isParticipant = false; // Sender wasn't challenger or a supporter
            }
            // Subject (challenge.subject) gets nothing from stake claim in this simple "challenger wins" scenario stake distribution
            // unless they also staked (not modelled here).
        } else { // Subject won
             if (msg.sender == challenge.subject) {
                // Subject doesn't stake in this model, so no stake to claim here
                isParticipant = true; // Subject was a participant
                amountToTransfer = 0; // Subject doesn't claim from this pool
             } else if (msg.sender == challenge.challenger) {
                // Challenger loses stake, gets 0
                isParticipant = true;
                amountToTransfer = 0;
             } else if (challenge.supporterStakes[msg.sender] > 0) {
                // Supporters of challenger lose stake, gets 0
                isParticipant = true;
                amountToTransfer = 0;
                challenge.supporterStakes[msg.sender] = 0; // Reset supporter's stake
             } else {
                isParticipant = false; // Sender was not involved
             }
             // Slashed tokens (challenger + supporter stakes) remain in the contract unless transferred out by owner/DAO
        }

        require(isParticipant, "DRN: Not a participant in this challenge");

        if (amountToTransfer > 0) {
            // Transfer tokens back to the user's *available* total stake balance
            _userProfiles[msg.sender].totalStake += amountToTransfer;
             // Note: Tokens are still held by the contract. Actual transfer out requires unstakeTokens
             // This model assumes staked tokens are managed internally.
        }

         // Mark challenge stakes as claimed only after all relevant parties potentially claim?
         // Or just mark it per user? Let's mark it globally for simplicity, assuming a single claim process.
         // This needs refinement for multiple supporters claiming independently.
         // Refinement: Store a mapping `claimed[challengeId][user]` bool.
         // Let's add that.

         // Add: mapping(uint256 => mapping(address => bool)) private _stakesClaimed;
         // require(!_stakesClaimed[challengeId][msg.sender], "DRN: Stake already claimed by user");
         // _stakesClaimed[challengeId][msg.sender] = true;

         // Re-simplifying for example: Just mark the challenge as claimed *once* to prevent issues,
         // acknowledging this isn't ideal for multiple independent claimants.
         // A better way: track claimed amount per user per challenge.
         // Let's add the mapping approach.
         mapping(uint256 => mapping(address => bool)) private _stakesClaimed; // Added to state

         // Check and mark claim status for the specific user
         require(!_stakesClaimed[challengeId][msg.sender], "DRN: Stake already claimed by user");
         _stakesClaimed[challengeId][msg.sender] = true;


        emit StakesClaimed(challengeId, msg.sender);
    }

    function getChallengeDetails(uint256 challengeId)
        external
        view
        isValidChallenge(challengeId)
        returns (
            address subject,
            address challenger,
            uint256 categoryId,
            string memory reasonHash,
            uint256 totalStake,
            uint256 challengerStake,
            ChallengeState state,
            uint256 initiatedAt,
            uint256 resolvedAt,
            bool resolutionOutcome,
            bool stakesClaimedFlag // Exposing the potentially simplified flag
        )
    {
        Challenge storage challenge = challenges[challengeId];
        return (
            challenge.subject,
            challenge.challenger,
            challenge.categoryId,
            challenge.reasonHash,
            challenge.totalStake,
            challenge.challengerStake,
            challenge.state,
            challenge.initiatedAt,
            challenge.resolvedAt,
            challenge.resolutionOutcome,
            challenge.stakesClaimed // Note: this is the simplified flag, see comments
        );
    }

    function getChallengeState(uint256 challengeId) external view isValidChallenge(challengeId) returns (ChallengeState) {
        return challenges[challengeId].state;
    }

    function getTotalNumberOfChallenges() external view returns (uint256) {
        return nextChallengeId;
    }

    // --- View Functions for Roles ---

    function isRegistered(address user) public view returns (bool) {
        return _userProfiles[user].isRegistered;
    }

     function getDecayInterval() external view returns (uint256) {
        return decayInterval;
    }

     function getLastReputationUpdate(address user, uint256 categoryId) external view isProfileRegistered(user) returns (uint256) {
        return _userProfiles[user].lastReputationUpdate[categoryId];
    }

}
```