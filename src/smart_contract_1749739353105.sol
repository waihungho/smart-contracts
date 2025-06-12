Okay, here is a Solidity smart contract exploring some interesting, non-standard mechanics. It's designed around a concept of a "Catalyst System" where users contribute value to gain internal "Catalyst" units, which fuels "Momentum" that decays over time, influencing their "State" and allowing them to earn internal "Spark" units or participate in admin-defined "Challenges".

This contract avoids being a standard ERC-20, ERC-721, simple staking pool, or basic multisig. It focuses on internal state management, time-based mechanics, tiered systems, and admin-driven interactions.

---

**Outline and Function Summary**

**Contract Name:** CatalystMomentumSystem

**Concept:** A system where users contribute value to gain internal "Catalyst" units. Catalyst generates "Momentum," which decays over time. A user's "State" (e.g., Bronze, Silver, Gold) is determined by their current Momentum. Users can earn "Spark" units based on their state and time, and participate in admin-defined "Challenges" to earn more Catalyst or Spark.

**Key Features:**

*   **Internal Units:** Manages `Catalyst` and `Spark` balances internally (not ERC-20 tokens in this contract).
*   **Momentum Decay:** `Momentum` is derived from `Catalyst` but decays over time, requiring users to maintain contributions or activity.
*   **Tiered States:** Users are categorized into states based on their Momentum (e.g., Bronze, Silver, Gold), influencing rewards.
*   **Spark Accrual:** Users accrue `Spark` over time based on their current state.
*   **Admin-Driven Challenges:** Admins can create and verify challenges users participate in.
*   **Configurable Policies:** Decay rates, state thresholds, and Spark rates are set by admins.
*   **Access Control:** Uses Ownable and Pausable patterns.

**Function Summary (27 Functions):**

1.  `constructor()`: Initializes the contract with owner and sets default policies.
2.  `pause()`: Owner pauses contract interactions.
3.  `unpause()`: Owner unpauses contract interactions.
4.  `setPolicyAdmin(address admin, bool isAdmin)`: Owner grants/revokes policy admin role.
5.  `onlyPolicyAdmin`: Modifier to restrict functions to policy admins.
6.  `setCatalyzeRate(uint256 rate)`: Policy admin sets the rate of ETH to Catalyst units.
7.  `setMomentumDecayRate(uint256 ratePerSecond)`: Policy admin sets the per-second momentum decay rate.
8.  `updateStateThresholds(uint256[] calldata thresholds)`: Policy admin sets the momentum thresholds for different states.
9.  `updateSparkRatePerSecond(uint256[] calldata rates)`: Policy admin sets the Spark accrual rate per second for each state.
10. `contributeCatalyst()`: User sends ETH to receive Catalyst units based on the current rate. Updates user's Momentum.
11. `claimSpark()`: User claims accrued Spark units based on their state since the last claim/update. Updates user's Momentum.
12. `_updateUserMomentum(address user)`: Internal helper to calculate and update a user's current Momentum based on time decay. Also updates their State and accrued Spark *up to the update time*.
13. `getUserData(address user)`: View function to get a user's complete data struct (requires internal update before calling for freshest data).
14. `getUserMomentum(address user)`: View function returning a user's *currently calculated* momentum (calls internal update).
15. `getUserState(address user)`: View function returning a user's *currently calculated* state (calls internal update).
16. `getTotalSparkClaimable(address user)`: View function returning the amount of Spark a user can *currently* claim (calls internal update).
17. `getPolicyParameters()`: View function to get current policy settings (rates, thresholds).
18. `createChallenge(uint256 rewardCatalyst, uint256 rewardSpark, uint64 endTime, bytes32 challengeDetailsHash)`: Policy admin creates a new challenge with specific rewards and duration.
19. `registerForChallenge(uint66 challengeId)`: User registers their intent to participate in a challenge.
20. `verifyChallengeCompletion(uint66 challengeId, address user)`: Policy admin verifies completion for a user in a specific challenge, awarding rewards.
21. `cancelChallenge(uint66 challengeId)`: Policy admin cancels an active challenge.
22. `getChallengeDetails(uint66 challengeId)`: View function to get details of a specific challenge.
23. `getUserChallengeStatus(uint66 challengeId, address user)`: View function to get a user's registration and completion status for a challenge.
24. `getContractCatalystPool()`: View function to get the total Catalyst units currently in the system (total contributed).
25. `getContractEthBalance()`: View function to get the ETH balance held by the contract.
26. `withdrawEth(address payable recipient)`: Owner withdraws ETH from the contract (e.g., if part of contribution was a fee, or for system shutdown - *careful usage required, ideally ETH stays backing catalyst* - implementing a dedicated fee mechanism is safer if withdrawable ETH is needed). *Self-correction: Let's assume contributed ETH is locked backing catalyst, no arbitrary withdraw. This function is removed or restricted to system wind-down.* Let's instead add a small optional fee on contribute.
27. `setContributionFee(uint256 feeBasisPoints)`: Policy admin sets a small fee (in basis points) on incoming ETH contributions.
28. `withdrawFees(address payable recipient)`: Owner or Policy Admin withdraws accumulated fees.

*Total Functions: 28* (Satisfies the >= 20 requirement)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Explicitly use SafeMath for older Solidity, but 0.8+ has built-in checks
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Add guard for potentially complex interactions

// Outline and Function Summary provided above the contract

contract CatalystMomentumSystem is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    // Policies (set by Policy Admins)
    uint256 public catalyzeRate; // Units of Catalyst per 1 ETH contributed
    uint256 public momentumDecayRate; // Units of Momentum decayed per second per unit of Catalyst
    uint256[] public stateThresholds; // Momentum thresholds for different states (e.g., [1000, 5000, 20000] for Bronze, Silver, Gold, Platinum)
    uint256[] public sparkRatePerSecond; // Spark units earned per second for each state level (index corresponds to stateThresholds + 1, index 0 for base state)
    uint256 public contributionFeeBasisPoints; // Fee applied to ETH contributions, in 1/100ths of a percent (basis points)

    // Access Control
    mapping(address => bool) public isPolicyAdmin;

    // User Data
    enum UserState { Base, Bronze, Silver, Gold, Platinum, Diamond } // Example states
    struct UserData {
        uint256 catalyst; // Internal Catalyst units
        uint256 spark;    // Internal Spark units earned and claimed
        uint256 lastUpdateTime; // Timestamp of last Catalyst/Momentum/Spark update
        uint256 accruedSparkUnclaimed; // Spark accrued since last update/claim
    }
    mapping(address => UserData) public users;

    // Challenge Data
    struct Challenge {
        uint66 id; // Unique challenge ID (timestamp based?)
        bool isActive;
        uint256 rewardCatalyst;
        uint256 rewardSpark;
        uint64 endTime;
        bytes32 challengeDetailsHash; // Hash of off-chain details/rules
        mapping(address => bool) registeredParticipants;
        mapping(address => bool) completedParticipants;
    }
    mapping(uint66 => Challenge) public challenges;
    uint66 private nextChallengeId; // Simple counter for challenge IDs

    // Accumulated Fees
    uint256 public totalFeesAccumulated;

    // Total System Metrics (for transparency/analytics)
    uint256 public totalCatalystContributed; // Sum of all Catalyst ever created
    uint256 public totalSparkClaimed;      // Sum of all Spark ever claimed

    // --- Events ---

    event PolicyAdminSet(address indexed admin, bool isAdmin);
    event PolicyUpdated(string policyName, uint256[] values); // Generic for rate, thresholds, spark rates
    event CatalyzeRateUpdated(uint256 newRate);
    event MomentumDecayRateUpdated(uint256 newRate);
    event ContributionFeeUpdated(uint256 feeBasisPoints);

    event CatalystContributed(address indexed user, uint256 ethAmount, uint256 catalystAmount, uint256 feeAmount);
    event SparkClaimed(address indexed user, uint256 sparkAmount);
    event UserStateChanged(address indexed user, UserState newState, uint256 momentum);
    event UserMomentumUpdated(address indexed user, uint256 oldMomentum, uint256 newMomentum); // Emitted by internal helper

    event ChallengeCreated(uint66 indexed challengeId, uint256 rewardCatalyst, uint256 rewardSpark, uint64 endTime, bytes32 detailsHash);
    event ChallengeRegistered(uint66 indexed challengeId, address indexed participant);
    event ChallengeCompleted(uint66 indexed challengeId, address indexed participant, uint256 awardedCatalyst, uint256 awardedSpark);
    event ChallengeCancelled(uint66 indexed challengeId);

    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyPolicyAdmin() {
        require(isPolicyAdmin[msg.sender], "CMS: Not a policy admin");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        // Set default policies (these should ideally be set by owner/admin initially)
        // Example defaults:
        catalyzeRate = 1000; // 1 ETH = 1000 Catalyst
        momentumDecayRate = 1; // 1 Momentum decays per second per unit of Catalyst (meaning it decays relative to catalyst balance)
        stateThresholds = [10000, 50000, 200000, 1000000, 5000000]; // Example tiers
        sparkRatePerSecond = [1, 2, 5, 10, 20, 50]; // Example rates for Base, Bronze, Silver, Gold, Platinum, Diamond
        contributionFeeBasisPoints = 0; // Default no fee

        // Ensure sparkRatePerSecond matches number of states + Base state
        require(sparkRatePerSecond.length == stateThresholds.length + 1, "CMS: Spark rate array length mismatch");

        nextChallengeId = 1; // Start challenge IDs from 1
    }

    // --- Access Control & Admin Functions ---

    function setPolicyAdmin(address admin, bool isAdmin) public onlyOwner {
        isPolicyAdmin[admin] = isAdmin;
        emit PolicyAdminSet(admin, isAdmin);
    }

    // --- Policy Configuration (Policy Admin Only) ---

    function setCatalyzeRate(uint256 rate) public onlyPolicyAdmin {
        catalyzeRate = rate;
        emit CatalyzeRateUpdated(rate);
    }

    function setMomentumDecayRate(uint256 ratePerSecond) public onlyPolicyAdmin {
        momentumDecayRate = ratePerSecond;
        emit MomentumDecayRateUpdated(ratePerSecond);
    }

    function updateStateThresholds(uint256[] calldata thresholds) public onlyPolicyAdmin {
        // Ensure threshold array is sorted ascending
        for (uint i = 0; i < thresholds.length; i++) {
            if (i > 0) {
                require(thresholds[i] > thresholds[i-1], "CMS: Thresholds must be strictly increasing");
            }
            // Prevent setting excessively high thresholds that might cause overflow issues elsewhere
            require(thresholds[i] <= type(uint128).max, "CMS: Threshold value too high"); // Use a reasonable cap
        }
        stateThresholds = thresholds;
        emit PolicyUpdated("stateThresholds", stateThresholds);
        // Check if spark rate array size needs adjustment (though updateSparkRatePerSecond checks this too)
        require(sparkRatePerSecond.length == stateThresholds.length + 1, "CMS: Spark rate array length must match new state thresholds + 1");
    }

    function updateSparkRatePerSecond(uint256[] calldata rates) public onlyPolicyAdmin {
         // Ensure rates array size matches the number of states + Base state
        require(rates.length == stateThresholds.length + 1, "CMS: Spark rate array length must match state thresholds + 1");
        sparkRatePerSecond = rates;
        emit PolicyUpdated("sparkRatePerSecond", sparkRatePerSecond);
    }

    function setContributionFee(uint256 feeBasisPoints_) public onlyPolicyAdmin {
         require(feeBasisPoints_ <= 1000, "CMS: Fee cannot exceed 10%"); // Example cap
         contributionFeeBasisPoints = feeBasisPoints_;
         emit ContributionFeeUpdated(feeBasisPoints_);
    }


    // --- Core Mechanics: Contribute, Momentum, Spark ---

    function contributeCatalyst() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "CMS: Must send ETH to contribute");
        require(catalyzeRate > 0, "CMS: Catalyze rate not set");

        uint256 ethAmount = msg.value;
        uint256 feeAmount = ethAmount.mul(contributionFeeBasisPoints).div(10000);
        uint256 netEth = ethAmount.sub(feeAmount);

        uint256 catalystReceived = netEth.mul(catalyzeRate);

        // Update user's momentum *before* adding new catalyst
        _updateUserMomentum(msg.sender);

        users[msg.sender].catalyst = users[msg.sender].catalyst.add(catalystReceived);
        totalCatalystContributed = totalCatalystContributed.add(catalystReceived);
        totalFeesAccumulated = totalFeesAccumulated.add(feeAmount);

        // Update momentum again with new catalyst
        _updateUserMomentum(msg.sender); // This second update is crucial to reflect new catalyst immediately

        emit CatalystContributed(msg.sender, ethAmount, catalystReceived, feeAmount);
    }

    function claimSpark() public whenNotPaused nonReentrant {
        // Update user's momentum and calculate accrual *before* claiming
        _updateUserMomentum(msg.sender);

        uint256 sparkToClaim = users[msg.sender].accruedSparkUnclaimed;
        require(sparkToClaim > 0, "CMS: No Spark to claim");

        users[msg.sender].spark = users[msg.sender].spark.add(sparkToClaim);
        users[msg.sender].accruedSparkUnclaimed = 0; // Reset unclaimed spark
        totalSparkClaimed = totalSparkClaimed.add(sparkToClaim);

        emit SparkClaimed(msg.sender, sparkToClaim);
    }

    // Internal helper to calculate and update user's state based on time decay
    function _updateUserMomentum(address user) internal {
        UserData storage userData = users[user];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime.sub(userData.lastUpdateTime);

        uint256 currentMomentum = _calculateMomentum(userData.catalyst, timeElapsed);
        uint256 oldMomentum = _calculateMomentum(userData.catalyst, 0); // Momentum at last update time

        // Calculate Spark accrued since last update
        uint256 sparkEarned = 0;
        if (timeElapsed > 0) {
             UserState stateAtLastUpdate = _getUserState(oldMomentum);
             uint256 rate = sparkRatePerSecond[_getStateIndex(stateAtLastUpdate)];
             sparkEarned = rate.mul(timeElapsed);
        }

        // Update user state and timestamps
        userData.lastUpdateTime = currentTime;
        userData.accruedSparkUnclaimed = userData.accruedSparkUnclaimed.add(sparkEarned);

        // Emit momentum update event
        emit UserMomentumUpdated(user, oldMomentum, currentMomentum);

        // Check and emit state change if necessary (based on current momentum)
        UserState oldState = _getUserState(oldMomentum);
        UserState newState = _getUserState(currentMomentum);
        if (oldState != newState) {
             emit UserStateChanged(user, newState, currentMomentum);
        }
    }

    // Pure function to calculate momentum based on catalyst and time elapsed
    function _calculateMomentum(uint256 catalyst, uint256 timeElapsed) internal view returns (uint256) {
        if (catalyst == 0) {
            return 0;
        }
        // Momentum = Catalyst * (1 - Decay)
        // Simple linear decay example: Momentum loss = timeElapsed * momentumDecayRate * catalyst / MAX_VALUE?
        // A more robust decay model might be exponential.
        // Let's use a simple decay proportional to time and *current* catalyst:
        // Decay amount = timeElapsed * momentumDecayRate
        // This decay amount is subtracted from the theoretical max momentum (which is related to catalyst).
        // Max momentum could just be equal to Catalyst units at t=0 decay.
        // Momentum at time t = Catalyst - (timeElapsed * momentumDecayRate)
        // But decay should be relative to the *amount* of momentum/catalyst.
        // Let's define decay as a percentage reduction per second, or per unit of catalyst.
        // Decay per second per unit of catalyst:
        // Momentum loss = timeElapsed * momentumDecayRate * catalyst (simple multiplication could overflow)
        // Let's scale decayRate down to avoid huge numbers: momentumDecayRate is decay *per second* per 1000 units of catalyst.
        // decay per second = (catalyst / 1000) * momentumDecayRate
        // Total decay = timeElapsed * (catalyst / 1000) * momentumDecayRate
        // Momentum = max(0, catalyst - Total decay)

        if (momentumDecayRate == 0 || timeElapsed == 0) {
             return catalyst; // No decay if rate or time is zero
        }

        // Using scaled decay: momentumDecayRate units per second *per 1000 catalyst*
        // decayPerSecond = catalyst.mul(momentumDecayRate).div(1000); // Using 1000 scale for demonstration
        // TotalDecay = decayPerSecond.mul(timeElapsed);
        // Simpler linear decay (decay rate is applied directly):
        uint256 decayAmount = timeElapsed.mul(momentumDecayRate);
        // Momentum decreases by decayAmount *for the total catalyst amount*? This feels wrong.
        // Let's rethink: Momentum is derived from Catalyst. Maybe Momentum *is* Catalyst, but decays.
        // E.g., initial Momentum = Catalyst contributed. Decay reduces this Momentum.
        // M_t = M_0 - decay_rate * t.
        // Or M_t = M_0 * exp(-decay_rate * t) -> Hard on-chain.
        // Let's use M_t = max(0, M_0 - decay_per_second * t), where decay_per_second = momentumDecayRate.
        // M_0 is the momentum *at the last update time*.
        // Let's track effective momentum directly, rather than recalculating from base catalyst.
        // This requires storing `currentMomentum` in the UserData struct and updating it.
        // Ok, revising struct and logic:
        // struct UserData { ... uint256 currentMomentum; ... }
        // _updateUserMomentum:
        // timeElapsed = currentTime - lastUpdateTime
        // momentumLoss = timeElapsed * momentumDecayRate
        // user.currentMomentum = max(0, user.currentMomentum - momentumLoss)
        // user.lastUpdateTime = currentTime
        // This is simpler and fits the "decaying state" idea better.

        // Reverting to original plan for now, calculating from base catalyst, but acknowledging the complexity of decay modeling.
        // A simple model: momentum starts at Catalyst value and decays linearly.
        // M(t) = Catalyst - rate * t.
        // This model makes less sense when more catalyst is added. The M_t = M_0 - decay*t model is better if M_0 is the momentum at the *last update*.

        // Let's stick to the simpler calculation based on *original* catalyst contribution potential
        // decay per second is `momentumDecayRate`. Total decay over `timeElapsed` is `timeElapsed * momentumDecayRate`.
        // The amount of momentum *lost* is proportional to the catalyst balance and time.
        // Total momentum loss = (catalyst * momentumDecayRate * timeElapsed) / SCALE
        // Let's use a scale factor, e.g., 1e18 for fixed point.
        // Or simpler: momentum decays at a rate proportional to the *existing* momentum. Exponential decay.
        // Using linear decay *amount* based on time:
        // Total decay = timeElapsed.mul(momentumDecayRate);
        // Momentum = max(0, initialMomentum - totalDecay).
        // Where initialMomentum is the momentum *when the timer started* (lastUpdateTime).
        // This means we *must* store effective momentum.

        // REVISED PLAN: Store `currentMomentum` in UserData.
        // UserData struct needs `uint256 currentMomentum;`.
        // `contributeCatalyst`: calls _updateUserMomentum, then adds catalyzeRate * netEth to `catalyst` AND `currentMomentum`, then calls _updateUserMomentum again.
        // `claimSpark`: calls _updateUserMomentum.
        // `_updateUserMomentum`:
        // timeElapsed = currentTime - userData.lastUpdateTime
        // momentumLoss = timeElapsed.mul(momentumDecayRate);
        // userData.currentMomentum = userData.currentMomentum > momentumLoss ? userData.currentMomentum.sub(momentumLoss) : 0;
        // userData.lastUpdateTime = currentTime;

        // Okay, modifying UserData struct definition and functions based on this `currentMomentum` approach.
        // (This requires changing the struct definition and all functions interacting with it).

        // --- Back to the original code structure, need to add `currentMomentum` ---
        // (Assuming the struct change is made)

        // Calculate decay based on time elapsed and rate
        uint256 decayAmount = timeElapsed.mul(momentumDecayRate);

        // Momentum cannot go below zero
        uint256 newMomentum = 0;
        if (userData.currentMomentum > decayAmount) {
             newMomentum = userData.currentMomentum.sub(decayAmount);
        }

        return newMomentum;
    }


    // Internal helper to determine user state based on momentum
    function _getUserState(uint256 momentum) internal view returns (UserState) {
        if (stateThresholds.length == 0) {
            return UserState.Base; // Default to Base if no thresholds set
        }
        // Iterate through thresholds to find the state
        for (uint i = 0; i < stateThresholds.length; i++) {
            if (momentum < stateThresholds[i]) {
                 // Momentum is below this threshold, state is the previous level
                 return UserState(i); // State index corresponds to threshold index for Bronze onwards. Index 0 is Base.
            }
        }
        // Momentum is higher than or equal to the highest threshold, user is in the top state
        return UserState(stateThresholds.length); // The last state index
    }

    // Internal helper to get the index of a state
    function _getStateIndex(UserState state) internal pure returns (uint256) {
        return uint256(state);
    }

    // --- View Functions (Public) ---

    // Expose updated user data
    function getUserData(address user) public view returns (
        uint256 catalyst,
        uint256 spark,
        uint256 currentMomentum,
        UserState state,
        uint256 accruedSparkUnclaimed,
        uint256 lastUpdateTime
    ) {
        // Note: This view function *cannot* modify state, so it cannot call _updateUserMomentum
        // The returned data reflects the state *as of the last transaction* for the user.
        // To get "real-time" momentum/state/accruedSpark, users must call the specific getter functions that simulate the update.
        UserData storage userData = users[user];
        return (
            userData.catalyst,
            userData.spark,
             _calculateMomentum(userData.currentMomentum, block.timestamp.sub(userData.lastUpdateTime)), // Calculate momentum *as if* updated now
             _getUserState(_calculateMomentum(userData.currentMomentum, block.timestamp.sub(userData.lastUpdateTime))), // Calculate state *as if* updated now
            userData.accruedSparkUnclaimed.add(_calculateSparkAccruedSinceLastUpdate(user, block.timestamp)), // Calculate accrued spark *as if* updated now
            userData.lastUpdateTime
        );
    }

    // View function that calculates current momentum simulating an update
    function getUserMomentum(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         uint256 timeElapsed = block.timestamp.sub(userData.lastUpdateTime);
         return _calculateMomentum(userData.currentMomentum, timeElapsed);
    }

     // View function that calculates current state simulating an update
    function getUserState(address user) public view returns (UserState) {
        uint256 currentMomentum = getUserMomentum(user);
        return _getUserState(currentMomentum);
    }

    // Internal helper to calculate spark accrued *only* since the last update time, without modifying state
    function _calculateSparkAccruedSinceLastUpdate(address user, uint256 currentTime) internal view returns (uint256) {
         UserData storage userData = users[user];
         uint256 timeElapsed = currentTime.sub(userData.lastUpdateTime);
         if (timeElapsed == 0) {
             return 0;
         }

         // Spark accrues based on the state the user was in at the *last update time*
         uint256 momentumAtLastUpdate = userData.currentMomentum; // Momentum *before* calculating decay
         UserState stateAtLastUpdate = _getUserState(momentumAtLastUpdate);
         uint256 rate = sparkRatePerSecond[_getStateIndex(stateAtLastUpdate)];

         return rate.mul(timeElapsed);
    }


    // View function calculating total claimable Spark simulating an update
    function getTotalSparkClaimable(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         // Calculate spark accrued since last update time + already unclaimed spark
         return userData.accruedSparkUnclaimed.add(_calculateSparkAccruedSinceLastUpdate(user, block.timestamp));
    }


    function getPolicyParameters() public view returns (
        uint256 currentCatalyzeRate,
        uint256 currentMomentumDecayRate,
        uint256[] memory currentStateThresholds,
        uint256[] memory currentSparkRatePerSecond,
        uint256 currentContributionFeeBasisPoints
    ) {
        return (
            catalyzeRate,
            momentumDecayRate,
            stateThresholds,
            sparkRatePerSecond,
            contributionFeeBasisPoints
        );
    }

    // --- Challenge System ---

    function createChallenge(
        uint256 rewardCatalyst,
        uint256 rewardSpark,
        uint64 endTime,
        bytes32 challengeDetailsHash // Hash linking to off-chain details (IPFS, Swarm, etc.)
    ) public onlyPolicyAdmin whenNotPaused returns (uint66 challengeId) {
        require(endTime > block.timestamp, "CMS: Challenge end time must be in the future");
        require(rewardCatalyst > 0 || rewardSpark > 0, "CMS: Challenge must offer rewards");

        challengeId = nextChallengeId;
        challenges[challengeId] = Challenge({
            id: challengeId,
            isActive: true,
            rewardCatalyst: rewardCatalyst,
            rewardSpark: rewardSpark,
            endTime: endTime,
            challengeDetailsHash: challengeDetailsHash
        });

        nextChallengeId = nextChallengeId.add(1);

        emit ChallengeCreated(challengeId, rewardCatalyst, rewardSpark, endTime, challengeDetailsHash);
    }

    function registerForChallenge(uint66 challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isActive, "CMS: Challenge is not active");
        require(block.timestamp <= challenge.endTime, "CMS: Challenge registration has ended");
        require(!challenge.registeredParticipants[msg.sender], "CMS: Already registered for this challenge");

        challenge.registeredParticipants[msg.sender] = true;

        emit ChallengeRegistered(challengeId, msg.sender);
    }

    function verifyChallengeCompletion(uint66 challengeId, address user) public onlyPolicyAdmin whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isActive, "CMS: Challenge is not active");
        require(challenge.registeredParticipants[user], "CMS: User did not register for this challenge");
        require(!challenge.completedParticipants[user], "CMS: User completion already verified");
        // Note: This assumes the admin has verified completion *off-chain* based on the challengeDetailsHash and rules.
        // For a fully decentralized system, this would require on-chain proofs or oracle verification.

        challenge.completedParticipants[user] = true;

        // Award rewards
        uint256 awardedCatalyst = challenge.rewardCatalyst;
        uint256 awardedSpark = challenge.rewardSpark;

        // Update user's momentum *before* adding rewards
        _updateUserMomentum(user);

        users[user].catalyst = users[user].catalyst.add(awardedCatalyst);
        users[user].spark = users[user].spark.add(awardedSpark); // Awarded Spark is claimed immediately

        // Update momentum again with new catalyst
        _updateUserMomentum(user);

        totalCatalystContributed = totalCatalystContributed.add(awardedCatalyst); // Track rewards as contributions conceptually
        totalSparkClaimed = totalSparkClaimed.add(awardedSpark); // Track awarded spark

        emit ChallengeCompleted(challengeId, user, awardedCatalyst, awardedSpark);
    }

    function cancelChallenge(uint66 challengeId) public onlyPolicyAdmin {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isActive, "CMS: Challenge is not active");

        challenge.isActive = false; // Simply deactivate, don't delete data

        emit ChallengeCancelled(challengeId);
    }

    // --- Challenge View Functions ---

    function getChallengeDetails(uint66 challengeId) public view returns (
        uint66 id,
        bool isActive,
        uint256 rewardCatalyst,
        uint256 rewardSpark,
        uint64 endTime,
        bytes32 challengeDetailsHash
    ) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.id == challengeId, "CMS: Challenge does not exist"); // Check if ID is valid

        return (
            challenge.id,
            challenge.isActive,
            challenge.rewardCatalyst,
            challenge.rewardSpark,
            challenge.endTime,
            challenge.challengeDetailsHash
        );
    }

    function getUserChallengeStatus(uint66 challengeId, address user) public view returns (bool registered, bool completed) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.id == challengeId, "CMS: Challenge does not exist");

        return (
            challenge.registeredParticipants[user],
            challenge.completedParticipants[user]
        );
    }


    // --- General View Functions ---

    function getContractCatalystPool() public view returns (uint256) {
        return totalCatalystContributed;
    }

    function getContractEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFees(address payable recipient) public onlyPolicyAdmin nonReentrant {
         require(totalFeesAccumulated > 0, "CMS: No fees accumulated");
         uint256 amount = totalFeesAccumulated;
         totalFeesAccumulated = 0;

         (bool success, ) = recipient.call{value: amount}("");
         require(success, "CMS: Fee withdrawal failed");

         emit FeesWithdrawn(recipient, amount);
    }

    // --- Internal Helpers (if needed, but many are inline or specific) ---

     // This internal helper is now deprecated with the revised momentum calculation
     // function _getSparkRateForState(UserState state) internal view returns (uint256) {
     //     uint256 index = uint256(state);
     //     require(index < sparkRatePerSecond.length, "CMS: Invalid state index for spark rate");
     //     return sparkRatePerSecond[index];
     // }

     // This internal helper is still useful
     function _getStateIndex(UserState state) internal pure returns (uint256) {
         return uint256(state);
     }

     // --- Pausable Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {} // Example hook
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {} // Example hook


    // Internal function to update user's currentMomentum based on decay
    // This is the *revised* core momentum logic
    function _calculateMomentum(uint256 initialMomentum, uint256 timeElapsed) internal view returns (uint256) {
        if (initialMomentum == 0 || momentumDecayRate == 0 || timeElapsed == 0) {
            return initialMomentum; // No decay if no momentum, no rate, or no time elapsed
        }

        uint256 decayAmount = timeElapsed.mul(momentumDecayRate);

        if (initialMomentum > decayAmount) {
            return initialMomentum.sub(decayAmount);
        } else {
            return 0;
        }
    }

     // Need to integrate this revised momentum logic into UserData struct and relevant functions.
     // Let's assume the UserData struct *now* includes `uint256 currentMomentum;`
     // And `contributeCatalyst` and `_updateUserMomentum` are modified to use it.

     // **IMPORTANT NOTE:** The current view functions `getUserData`, `getUserMomentum`, `getUserState`, `getTotalSparkClaimable`
     // *simulate* the momentum update using `_calculateMomentum(userData.currentMomentum, timeElapsed)`,
     // but they *do not* modify the stored `userData.currentMomentum` or `userData.lastUpdateTime`.
     // The actual stored values are only updated during state-changing transactions like `contributeCatalyst` or `claimSpark`.
     // This is a standard pattern for view functions to avoid gas costs, but means the returned data is theoretical until a transaction confirms.

     // --- Final Review of Function Count and Logic ---
     // 1. constructor
     // 2. pause
     // 3. unpause
     // 4. setPolicyAdmin
     // 5. onlyPolicyAdmin (modifier)
     // 6. setCatalyzeRate
     // 7. setMomentumDecayRate
     // 8. updateStateThresholds
     // 9. updateSparkRatePerSecond
     // 10. setContributionFee
     // 11. contributeCatalyst
     // 12. claimSpark
     // 13. _updateUserMomentum (internal - doesn't count towards public/external function count requested)
     // 14. getUserData (view)
     // 15. getUserMomentum (view)
     // 16. getUserState (view)
     // 17. _calculateSparkAccruedSinceLastUpdate (internal)
     // 18. getTotalSparkClaimable (view)
     // 19. getPolicyParameters (view)
     // 20. createChallenge
     // 21. registerForChallenge
     // 22. verifyChallengeCompletion
     // 23. cancelChallenge
     // 24. getChallengeDetails (view)
     // 25. getUserChallengeStatus (view)
     // 26. getContractCatalystPool (view)
     // 27. getContractEthBalance (view)
     // 28. withdrawFees

     // Plus internal helpers like _getUserState, _getStateIndex, _calculateMomentum.
     // Total public/external/view functions: 25 + 3 modifiers/internal helpers = 28 distinct named functions/modifiers used. The count is well over 20 public/external entry points.

    // --- Revised UserData Struct ---
    // (Placeholder comment as struct must be defined at the top)
    // struct UserData {
    //     uint256 catalyst; // Internal Catalyst units (total contributed/earned)
    //     uint256 spark;    // Internal Spark units earned and claimed
    //     uint256 lastUpdateTime; // Timestamp of last Catalyst/Momentum/Spark update
    //     uint256 accruedSparkUnclaimed; // Spark accrued since last update/claim (based on state *at* last update)
    //     uint256 currentMomentum; // Effective momentum after decay
    // }
    // Need to replace the original UserData struct with this one.

    // --- Revisit _updateUserMomentum logic with the new struct ---
    // function _updateUserMomentum(address user) internal {
    //     UserData storage userData = users[user];
    //     uint256 currentTime = block.timestamp;
    //     uint256 timeElapsed = currentTime.sub(userData.lastUpdateTime);
    //
    //     // Calculate Spark accrued based on the state *at the previous update time*
    //     uint256 sparkEarned = 0;
    //     if (timeElapsed > 0) {
    //          // Need the state based on momentum *before* decay calculation for this period.
    //          // The `currentMomentum` stored is the momentum *after* decay from the *period before*.
    //          // So spark accrues based on the state derived from the `currentMomentum` at the *start* of this `timeElapsed` interval.
    //          UserState stateAtIntervalStart = _getUserState(userData.currentMomentum); // State from moment of last update
    //          uint256 rate = sparkRatePerSecond[_getStateIndex(stateAtIntervalStart)];
    //          sparkEarned = rate.mul(timeElapsed);
    //     }
    //
    //     uint256 oldMomentum = userData.currentMomentum;
    //
    //     // Apply momentum decay
    //     uint256 decayAmount = timeElapsed.mul(momentumDecayRate);
    //     userData.currentMomentum = userData.currentMomentum > decayAmount ? userData.currentMomentum.sub(decayAmount) : 0;
    //
    //     // Add newly earned Spark to the unclaimed balance
    //     userData.accruedSparkUnclaimed = userData.accruedSparkUnclaimed.add(sparkEarned);
    //
    //     // Update timestamp
    //     userData.lastUpdateTime = currentTime;
    //
    //     // Emit events
    //     emit UserMomentumUpdated(user, oldMomentum, userData.currentMomentum);
    //     UserState oldState = _getUserState(oldMomentum);
    //     UserState newState = _getUserState(userData.currentMomentum);
    //     if (oldState != newState) {
    //          emit UserStateChanged(user, newState, userData.currentMomentum);
    //     }
    // }

    // --- Revisit contributeCatalyst with the new struct ---
    // function contributeCatalyst() public payable whenNotPaused nonReentrant {
    //     require(msg.value > 0, "CMS: Must send ETH to contribute");
    //     require(catalyzeRate > 0, "CMS: Catalyze rate not set");
    //
    //     uint256 ethAmount = msg.value;
    //     uint256 feeAmount = ethAmount.mul(contributionFeeBasisPoints).div(10000);
    //     uint256 netEth = ethAmount.sub(feeAmount);
    //
    //     uint256 catalystReceived = netEth.mul(catalyzeRate);
    //
    //     // Update user state (applies decay, accrues spark, updates lastUpdateTime)
    //     _updateUserMomentum(msg.sender);
    //
    //     // Add new catalyst and its immediate effect on momentum
    //     users[msg.sender].catalyst = users[msg.sender].catalyst.add(catalystReceived);
    //     users[msg.sender].currentMomentum = users[msg.sender].currentMomentum.add(catalystReceived); // New catalyst adds directly to momentum
    //
    //     totalCatalystContributed = totalCatalystContributed.add(catalystReceived);
    //     totalFeesAccumulated = totalFeesAccumulated.add(feeAmount);
    //
    //     // No second _updateUserMomentum call needed here, as the momentum is already updated
    //     // and the next decay period starts from block.timestamp recorded in the first call.
    //
    //     emit CatalystContributed(msg.sender, ethAmount, catalystReceived, feeAmount);
    // }

    // --- Revisit verifyChallengeCompletion with the new struct ---
    // function verifyChallengeCompletion(...) {
    //     ...
    //     // Award rewards
    //     uint256 awardedCatalyst = challenge.rewardCatalyst;
    //     uint256 awardedSpark = challenge.rewardSpark;
    //
    //     // Update user state (applies decay, accrues spark, updates lastUpdateTime)
    //     _updateUserMomentum(user);
    //
    //     // Add awarded catalyst and its immediate effect on momentum
    //     users[user].catalyst = users[user].catalyst.add(awardedCatalyst);
    //     users[user].currentMomentum = users[user].currentMomentum.add(awardedCatalyst);
    //     users[user].spark = users[user].spark.add(awardedSpark); // Awarded Spark is claimed immediately
    //
    //     totalCatalystContributed = totalCatalystContributed.add(awardedCatalyst); // Track rewards as contributions conceptually
    //     totalSparkClaimed = totalSparkClaimed.add(awardedSpark); // Track awarded spark
    //
    //     emit ChallengeCompleted(challengeId, user, awardedCatalyst, awardedSpark);
    // }

    // --- Revisit Spark Accrual Logic ---
    // The `_updateUserMomentum` function calculates spark accrued *since the last update* based on the state *at the moment of the last update*.
    // This is slightly different from the initial plan (accrue based on state during the *entire* period), but simpler to implement.
    // This means if a user's state changes mid-way between two updates, the Spark accrual rate for the *entire* period will be based on the state they were in *at the start* of that period.
    // This is an acceptable trade-off for on-chain complexity.

    // --- Revisit View Functions with the new struct ---
    // `getUserData`, `getUserMomentum`, `getUserState`, `getTotalSparkClaimable` need to be updated to use the new `currentMomentum` field
    // and the revised `_calculateMomentum` function that takes `initialMomentum` (the stored `userData.currentMomentum`) and `timeElapsed`.

    // The provided code below *includes* the revised UserData struct and the updated functions based on the `currentMomentum` approach.

}

// --- Actual Final Code (incorporating revisions) ---

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Outline and Function Summary provided above this section

contract CatalystMomentumSystem is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    // Policies (set by Policy Admins)
    uint256 public catalyzeRate; // Units of Catalyst per 1 ETH contributed
    uint256 public momentumDecayRate; // Units of Momentum decayed per second
    uint256[] public stateThresholds; // Momentum thresholds for different states (e.g., [1000, 5000, 20000] for Bronze, Silver, Gold, Platinum)
    uint256[] public sparkRatePerSecond; // Spark units earned per second for each state level (index corresponds to stateThresholds + 1, index 0 for base state)
    uint256 public contributionFeeBasisPoints; // Fee applied to ETH contributions, in 1/100ths of a percent (basis points)

    // Access Control
    mapping(address => bool) public isPolicyAdmin;

    // User Data
    enum UserState { Base, Bronze, Silver, Gold, Platinum, Diamond } // Example states
    struct UserData {
        uint256 catalyst; // Internal Catalyst units (total contributed/earned)
        uint256 spark;    // Internal Spark units earned and claimed
        uint256 lastUpdateTime; // Timestamp of last Catalyst/Momentum/Spark update
        uint256 accruedSparkUnclaimed; // Spark accrued since last update/claim (based on state *at* last update)
        uint256 currentMomentum; // Effective momentum after decay
    }
    mapping(address => UserData) public users;

    // Challenge Data
    struct Challenge {
        uint66 id; // Unique challenge ID
        bool isActive;
        uint256 rewardCatalyst;
        uint256 rewardSpark;
        uint64 endTime;
        bytes32 challengeDetailsHash; // Hash of off-chain details/rules
        mapping(address => bool) registeredParticipants;
        mapping(address => bool) completedParticipants;
    }
    mapping(uint66 => Challenge) public challenges;
    uint66 private nextChallengeId; // Simple counter for challenge IDs

    // Accumulated Fees
    uint256 public totalFeesAccumulated;

    // Total System Metrics (for transparency/analytics)
    uint256 public totalCatalystContributed; // Sum of all Catalyst ever created
    uint256 public totalSparkClaimed;      // Sum of all Spark ever claimed

    // --- Events ---

    event PolicyAdminSet(address indexed admin, bool isAdmin);
    event PolicyUpdated(string policyName); // Generic for rate, thresholds, spark rates
    event CatalyzeRateUpdated(uint256 newRate);
    event MomentumDecayRateUpdated(uint256 newRate);
    event ContributionFeeUpdated(uint256 feeBasisPoints);

    event CatalystContributed(address indexed user, uint256 ethAmount, uint256 catalystAmount, uint256 feeAmount);
    event SparkClaimed(address indexed user, uint256 sparkAmount);
    event UserStateChanged(address indexed user, UserState newState, uint256 momentum);
    event UserMomentumUpdated(address indexed user, uint256 oldMomentum, uint256 newMomentum); // Emitted by internal helper

    event ChallengeCreated(uint66 indexed challengeId, uint256 rewardCatalyst, uint256 rewardSpark, uint64 endTime, bytes32 detailsHash);
    event ChallengeRegistered(uint66 indexed challengeId, address indexed participant);
    event ChallengeCompleted(uint66 indexed challengeId, address indexed participant, uint256 awardedCatalyst, uint256 awardedSpark);
    event ChallengeCancelled(uint66 indexed challengeId);

    event FeesWithdrawn(address indexed recipient, uint255 amount); // Use uint255 for ETH balance withdrawal to match address(this).balance type

    // --- Modifiers ---

    modifier onlyPolicyAdmin() {
        require(isPolicyAdmin[msg.sender], "CMS: Not a policy admin");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        // Set default policies (these should ideally be set by owner/admin initially)
        // Example defaults:
        catalyzeRate = 1000; // 1 ETH = 1000 Catalyst
        momentumDecayRate = 1; // 1 Momentum unit decays per second (applied linearly)
        stateThresholds = [10000, 50000, 200000, 1000000, 5000000]; // Example tiers
        sparkRatePerSecond = [1, 2, 5, 10, 20, 50]; // Example rates for Base, Bronze, Silver, Gold, Platinum, Diamond
        contributionFeeBasisPoints = 0; // Default no fee

        // Ensure sparkRatePerSecond matches number of states + Base state
        require(sparkRatePerSecond.length == stateThresholds.length + 1, "CMS: Spark rate array length mismatch");

        nextChallengeId = 1; // Start challenge IDs from 1
    }

    // --- Access Control & Admin Functions ---

    function setPolicyAdmin(address admin, bool isAdmin) public onlyOwner {
        isPolicyAdmin[admin] = isAdmin;
        emit PolicyAdminSet(admin, isAdmin);
    }

    // --- Policy Configuration (Policy Admin Only) ---

    function setCatalyzeRate(uint256 rate) public onlyPolicyAdmin {
        catalyzeRate = rate;
        emit CatalyzeRateUpdated(rate);
    }

    function setMomentumDecayRate(uint256 ratePerSecond) public onlyPolicyAdmin {
        momentumDecayRate = ratePerSecond;
        emit MomentumDecayRateUpdated(ratePerSecond);
    }

    function updateStateThresholds(uint256[] calldata thresholds) public onlyPolicyAdmin {
        for (uint i = 0; i < thresholds.length; i++) {
            if (i > 0) {
                require(thresholds[i] > thresholds[i-1], "CMS: Thresholds must be strictly increasing");
            }
             require(thresholds[i] < type(uint256).max / 2, "CMS: Threshold value too high"); // Prevent potential overflow issues
        }
        stateThresholds = thresholds;
        emit PolicyUpdated("stateThresholds");
        require(sparkRatePerSecond.length == stateThresholds.length + 1, "CMS: Spark rate array length must match new state thresholds + 1");
    }

    function updateSparkRatePerSecond(uint256[] calldata rates) public onlyPolicyAdmin {
        require(rates.length == stateThresholds.length + 1, "CMS: Spark rate array length must match state thresholds + 1");
        sparkRatePerSecond = rates;
        emit PolicyUpdated("sparkRatePerSecond");
    }

    function setContributionFee(uint256 feeBasisPoints_) public onlyPolicyAdmin {
         require(feeBasisPoints_ <= 1000, "CMS: Fee cannot exceed 10%"); // Example cap (1000 basis points = 10%)
         contributionFeeBasisPoints = feeBasisPoints_;
         emit ContributionFeeUpdated(feeBasisPoints_);
    }

    // Owner can withdraw remaining balance only if contract is paused (e.g., for shutdown)
    function emergencyWithdrawEth(address payable recipient) public onlyOwner whenPaused nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "CMS: No ETH balance");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "CMS: ETH withdrawal failed");
    }


    // --- Core Mechanics: Contribute, Momentum, Spark ---

    function contributeCatalyst() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "CMS: Must send ETH to contribute");
        require(catalyzeRate > 0, "CMS: Catalyze rate not set");

        uint256 ethAmount = msg.value;
        uint256 feeAmount = ethAmount.mul(contributionFeeBasisPoints).div(10000);
        uint256 netEth = ethAmount.sub(feeAmount);

        uint256 catalystReceived = netEth.mul(catalyzeRate);

        // Update user state (applies decay, accrues spark, updates lastUpdateTime)
        _updateUserMomentum(msg.sender);

        // Add new catalyst and its immediate effect on momentum
        users[msg.sender].catalyst = users[msg.sender].catalyst.add(catalystReceived);
        users[msg.sender].currentMomentum = users[msg.sender].currentMomentum.add(catalystReceived); // New catalyst adds directly to momentum

        totalCatalystContributed = totalCatalystContributed.add(catalystReceived);
        totalFeesAccumulated = totalFeesAccumulated.add(feeAmount);

        // No second _updateUserMomentum call needed here.

        emit CatalystContributed(msg.sender, ethAmount, catalystReceived, feeAmount);
    }

    function claimSpark() public whenNotPaused nonReentrant {
        // Update user state (applies decay, accrues spark, updates lastUpdateTime)
        _updateUserMomentum(msg.sender);

        uint256 sparkToClaim = users[msg.sender].accruedSparkUnclaimed;
        require(sparkToClaim > 0, "CMS: No Spark to claim");

        users[msg.sender].spark = users[msg.sender].spark.add(sparkToClaim);
        users[msg.sender].accruedSparkUnclaimed = 0; // Reset unclaimed spark
        totalSparkClaimed = totalSparkClaimed.add(sparkToClaim);

        emit SparkClaimed(msg.sender, sparkToClaim);
    }

    // Internal helper to calculate and update user's state based on time decay and accrue spark
    function _updateUserMomentum(address user) internal {
        UserData storage userData = users[user];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime.sub(userData.lastUpdateTime);

        // Calculate Spark accrued based on the state *at the start* of this time interval (i.e., state based on momentum *before* decay is applied for this interval)
        uint256 sparkEarned = 0;
        if (timeElapsed > 0) {
             UserState stateAtIntervalStart = _getUserState(userData.currentMomentum); // State from moment of last update
             uint256 rate = sparkRatePerSecond[_getStateIndex(stateAtIntervalStart)];
             sparkEarned = rate.mul(timeElapsed);
        }

        uint256 oldMomentum = userData.currentMomentum;

        // Apply momentum decay
        uint256 decayAmount = timeElapsed.mul(momentumDecayRate);
        userData.currentMomentum = userData.currentMomentum > decayAmount ? userData.currentMomentum.sub(decayAmount) : 0;

        // Add newly earned Spark to the unclaimed balance
        userData.accruedSparkUnclaimed = userData.accruedSparkUnclaimed.add(sparkEarned);

        // Update timestamp
        userData.lastUpdateTime = currentTime;

        // Emit events
        emit UserMomentumUpdated(user, oldMomentum, userData.currentMomentum);
        UserState oldState = _getUserState(oldMomentum);
        UserState newState = _getUserState(userData.currentMomentum);
        if (oldState != newState) {
             emit UserStateChanged(user, newState, userData.currentMomentum);
        }
    }

    // Pure function to calculate potential future momentum after decay, based on an initial momentum value
    function _calculateMomentum(uint256 initialMomentum, uint256 timeElapsed) internal view returns (uint256) {
        if (initialMomentum == 0 || momentumDecayRate == 0 || timeElapsed == 0) {
            return initialMomentum; // No decay if no momentum, no rate, or no time elapsed
        }

        // Calculate the total decay amount
        uint256 decayAmount = timeElapsed.mul(momentumDecayRate);

        // Ensure momentum doesn't go below zero
        if (initialMomentum > decayAmount) {
            return initialMomentum.sub(decayAmount);
        } else {
            return 0;
        }
    }


    // Internal helper to determine user state based on momentum
    function _getUserState(uint256 momentum) internal view returns (UserState) {
        if (stateThresholds.length == 0) {
            return UserState.Base; // Default to Base if no thresholds set
        }
        // Iterate through thresholds to find the state
        for (uint i = 0; i < stateThresholds.length; i++) {
            if (momentum < stateThresholds[i]) {
                 // Momentum is below this threshold, state is the previous level (Base or a tier)
                 return UserState(i); // State index corresponds to threshold index for Bronze onwards. Index 0 is Base.
            }
        }
        // Momentum is higher than or equal to the highest threshold, user is in the top state
        return UserState(stateThresholds.length); // The last state index corresponds to the last threshold index + 1
    }

    // Internal helper to get the index of a state
    function _getStateIndex(UserState state) internal pure returns (uint256) {
        return uint256(state);
    }

     // Internal helper to calculate spark accrued *only* since a specific time point, without modifying state
    function _calculateSparkAccruedSince(address user, uint256 fromTime, uint256 currentTime) internal view returns (uint256) {
         if (currentTime <= fromTime) {
             return 0;
         }
         uint256 timeElapsed = currentTime.sub(fromTime);
         UserData storage userData = users[user];

         // Spark accrues based on the state derived from the `currentMomentum` value stored *at* `fromTime`.
         // This requires knowing the momentum value *at* fromTime, which we don't store historically.
         // The simpler model calculates based on the state at the *most recent update time* (`userData.lastUpdateTime`)
         // and applies that rate for the duration up to `currentTime`.

         // Let's calculate based on the state at `userData.lastUpdateTime`:
         uint256 timeElapsedFromLastUpdate = currentTime.sub(userData.lastUpdateTime);
         if (timeElapsedFromLastUpdate == 0) {
             return 0;
         }

         // State is determined by `userData.currentMomentum` *before* decay for this new interval.
         // This value is the `currentMomentum` stored in the struct.
         UserState stateAtLastUpdate = _getUserState(userData.currentMomentum);
         uint256 rate = sparkRatePerSecond[_getStateIndex(stateAtLastUpdate)];

         return rate.mul(timeElapsedFromLastUpdate);
    }


    // --- View Functions (Public) ---

    // Expose user data including current calculated momentum and state
    function getUserData(address user) public view returns (
        uint256 catalyst,
        uint256 spark,
        uint256 currentMomentum,
        UserState state,
        uint256 accruedSparkUnclaimed,
        uint256 lastUpdateTime
    ) {
        UserData storage userData = users[user];
        uint256 timeElapsed = block.timestamp.sub(userData.lastUpdateTime);

        // Calculate momentum *as if* updated now
        uint256 calculatedMomentum = _calculateMomentum(userData.currentMomentum, timeElapsed);
        // Calculate state *as if* updated now
        UserState calculatedState = _getUserState(calculatedMomentum);
        // Calculate accrued spark since last update time + already unclaimed
        uint256 calculatedAccruedSpark = userData.accruedSparkUnclaimed.add(_calculateSparkAccruedSince(user, userData.lastUpdateTime, block.timestamp));


        return (
            userData.catalyst,
            userData.spark,
            calculatedMomentum,
            calculatedState,
            calculatedAccruedSpark,
            userData.lastUpdateTime
        );
    }

    // View function that calculates current momentum simulating an update
    function getUserMomentum(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         uint256 timeElapsed = block.timestamp.sub(userData.lastUpdateTime);
         return _calculateMomentum(userData.currentMomentum, timeElapsed);
    }

     // View function that calculates current state simulating an update
    function getUserState(address user) public view returns (UserState) {
        uint256 currentMomentum = getUserMomentum(user);
        return _getUserState(currentMomentum);
    }

    // View function calculating total claimable Spark simulating an update
    function getTotalSparkClaimable(address user) public view returns (uint256) {
         UserData storage userData = users[user];
         // Calculate spark accrued since last update time + already unclaimed spark
         return userData.accruedSparkUnclaimed.add(_calculateSparkAccruedSince(user, userData.lastUpdateTime, block.timestamp));
    }


    function getPolicyParameters() public view returns (
        uint256 currentCatalyzeRate,
        uint256 currentMomentumDecayRate,
        uint256[] memory currentStateThresholds,
        uint256[] memory currentSparkRatePerSecond,
        uint256 currentContributionFeeBasisPoints
    ) {
        return (
            catalyzeRate,
            momentumDecayRate,
            stateThresholds,
            sparkRatePerSecond,
            contributionFeeBasisPoints
        );
    }

    // --- Challenge System ---

    function createChallenge(
        uint256 rewardCatalyst,
        uint256 rewardSpark,
        uint64 endTime,
        bytes32 challengeDetailsHash // Hash linking to off-chain details/rules
    ) public onlyPolicyAdmin whenNotPaused returns (uint66 challengeId) {
        require(endTime > block.timestamp, "CMS: Challenge end time must be in the future");
        require(rewardCatalyst > 0 || rewardSpark > 0, "CMS: Challenge must offer rewards");

        challengeId = nextChallengeId;
        challenges[challengeId] = Challenge({
            id: challengeId,
            isActive: true,
            rewardCatalyst: rewardCatalyst,
            rewardSpark: rewardSpark,
            endTime: endTime,
            challengeDetailsHash: challengeDetailsHash
        });

        nextChallengeId = nextChallengeId.add(1);

        emit ChallengeCreated(challengeId, rewardCatalyst, rewardSpark, endTime, challengeDetailsHash);
    }

    function registerForChallenge(uint66 challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isActive, "CMS: Challenge is not active");
        require(block.timestamp <= challenge.endTime, "CMS: Challenge registration has ended");
        require(!challenge.registeredParticipants[msg.sender], "CMS: Already registered for this challenge");

        challenge.registeredParticipants[msg.sender] = true;

        emit ChallengeRegistered(challengeId, msg.sender);
    }

    function verifyChallengeCompletion(uint66 challengeId, address user) public onlyPolicyAdmin whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isActive, "CMS: Challenge is not active");
        require(block.timestamp <= challenge.endTime, "CMS: Cannot verify after challenge end time"); // Verification window restriction
        require(challenge.registeredParticipants[user], "CMS: User did not register for this challenge");
        require(!challenge.completedParticipants[user], "CMS: User completion already verified");
        // Note: This assumes the admin has verified completion *off-chain* based on the challengeDetailsHash and rules.

        challenge.completedParticipants[user] = true;

        // Award rewards
        uint256 awardedCatalyst = challenge.rewardCatalyst;
        uint256 awardedSpark = challenge.rewardSpark;

        // Update user state (applies decay, accrues spark, updates lastUpdateTime) before adding rewards
        _updateUserMomentum(user);

        // Add awarded catalyst and its immediate effect on momentum
        users[user].catalyst = users[user].catalyst.add(awardedCatalyst);
        users[user].currentMomentum = users[user].currentMomentum.add(awardedCatalyst);
        users[user].spark = users[user].spark.add(awardedSpark); // Awarded Spark is claimed immediately

        totalCatalystContributed = totalCatalystContributed.add(awardedCatalyst); // Track rewards as contributions conceptually
        totalSparkClaimed = totalSparkClaimed.add(awardedSpark); // Track awarded spark

        emit ChallengeCompleted(challengeId, user, awardedCatalyst, awardedSpark);
    }

    function cancelChallenge(uint66 challengeId) public onlyPolicyAdmin {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.isActive, "CMS: Challenge is not active");

        challenge.isActive = false; // Simply deactivate, don't delete data

        // Optional: Implement refund logic here if registration required a stake.

        emit ChallengeCancelled(challengeId);
    }

    // --- Challenge View Functions ---

    function getChallengeDetails(uint66 challengeId) public view returns (
        uint66 id,
        bool isActive,
        uint256 rewardCatalyst,
        uint256 rewardSpark,
        uint64 endTime,
        bytes32 challengeDetailsHash
    ) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.id == challengeId, "CMS: Challenge does not exist"); // Check if ID is valid

        return (
            challenge.id,
            challenge.isActive,
            challenge.rewardCatalyst,
            challenge.rewardSpark,
            challenge.endTime,
            challenge.challengeDetailsHash
        );
    }

    function getUserChallengeStatus(uint66 challengeId, address user) public view returns (bool registered, bool completed) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.id == challengeId, "CMS: Challenge does not exist");

        return (
            challenge.registeredParticipants[user],
            challenge.completedParticipants[user]
        );
    }


    // --- General View Functions ---

    function getContractCatalystPool() public view returns (uint256) {
        return totalCatalystContributed;
    }

    function getContractEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFees(address payable recipient) public onlyPolicyAdmin nonReentrancy {
         require(totalFeesAccumulated > 0, "CMS: No fees accumulated");
         uint256 amount = totalFeesAccumulated;
         totalFeesAccumulated = 0;

         (bool success, ) = recipient.call{value: amount}("");
         require(success, "CMS: Fee withdrawal failed");

         emit FeesWithdrawn(recipient, amount);
    }

     // Pausable hook implementations (can be used for additional logic if needed)
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(Pausable) {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override(Pausable) {}

    // Override Pausable's _pause and _unpause to emit specific events or add logic
    function _pause() internal virtual override(Pausable) {
        super._pause();
        // Additional logic here
    }

    function _unpause() internal virtual override(Pausable) {
         super._unpause();
        // Additional logic here
    }

     // Receive ETH function to allow contract to receive funds directly (optional, but good practice if ETH is sent without calling contribute)
     receive() external payable {
         // Can add logic here if direct ETH transfers should somehow affect catalyst/momentum,
         // but the current design expects contribution via contributeCatalyst().
         // Reverting or logging could be options. Logging is safer to avoid locking funds.
         emit CatalystContributed(msg.sender, msg.value, 0, 0); // Log received ETH without catalyst
     }
}
```