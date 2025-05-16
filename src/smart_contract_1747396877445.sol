Okay, let's design an advanced, creative, and trendy smart contract.

A concept combining:
1.  **Dynamic State:** The "value" or "influence" of contributions changes over time.
2.  **Reputation/Influence:** A non-transferable score representing a user's impact (akin to Soulbound Tokens in concept, but managed within the contract).
3.  **Curated Contributions:** Users stake to propose ideas/data ("Insights") and others stake to curate/validate them.
4.  **Time-Based Mechanics:** Decay of influence, time-locked staking periods, passive influence generation.
5.  **Simple Governance:** Community influence affects parameters.

Let's call it the "Chrono-Vault of Evolving Insights". Users submit Insights, stake ETH/tokens, curate others' Insights, and earn "Influence Points" (IP) based on the longevity and community acceptance of their contributions. IP unlocks features and affects governance weight.

---

**Outline:**

1.  **Title:** Chrono-Vault of Evolving Insights
2.  **Purpose:** A decentralized platform for submitting, curating, and evolving knowledge/insights, rewarding participants based on their influence and contribution longevity via non-transferable "Influence Points" (IP).
3.  **Core Concepts:**
    *   Insights: User-submitted data with a lifecycle (Pending, Active, Obsolete).
    *   Users: Tracked by address, accumulating non-transferable Influence Points (IP).
    *   Staking: Required for submitting and curating insights, held as collateral and distributed/slashed based on outcomes.
    *   Curation: A community-driven process to validate pending insights.
    *   Evolution: Active insights passively generate IP and can be enhanced or marked obsolete over time.
    *   Time Mechanics: Decay of insight influence, claim periods, voting durations.
    *   Governance: Basic parameters adjustable by high-influence users or a simple owner model (using Ownable for this example, but extensible).
4.  **Key State Variables:**
    *   Mappings for Insights, Users, Influence Points, Staked amounts.
    *   Counters for IDs.
    *   Parameters (stake amounts, durations, rates).
    *   Enum for Insight State.
5.  **Key Functions:**
    *   Submission & Staking: `submitInsight`, `claimInsightStake`.
    *   Curation & Validation: `curateInsight`, `finalizeCuration`, `claimCurationStake`.
    *   Influence & Rewards: `claimGeneratedInfluence`, `getUserInfluence`.
    *   Insight Lifecycle: `enhanceInsight`, `startObsoleteVote`, `finalizeObsoleteVote`.
    *   Parameters & Governance: `updateSubmissionStake`, etc., `transferOwnership`.
    *   Queries: Various `get` functions for state data.

**Function Summary:**

1.  `constructor()`: Initializes the contract with owner and initial parameters.
2.  `submitInsight(string memory data, uint256 category)`: Allows a user to submit a new insight by staking the required amount.
3.  `curateInsight(uint256 insightId)`: Allows a user to stake and vote for a pending insight to become active.
4.  `finalizeCuration(uint256 insightId)`: Triggered by anyone after the curation period ends to process votes, distribute/slash stakes, and activate the insight (or reject it).
5.  `claimInsightStake(uint256 insightId)`: Allows an insight submitter to claim their initial stake back after curation finalization (full or partial depending on outcome).
6.  `claimCurationStake(uint256 insightId)`: Allows a curator to claim their stake back after curation finalization (full or partial depending on outcome).
7.  `enhanceInsight(uint256 insightId, string memory newData)`: Allows a user with sufficient influence to update an active insight, resetting its decay timer.
8.  `startObsoleteVote_Community(uint256 insightId)`: Allows a user to initiate a community vote to mark an active insight as obsolete. Requires a stake.
9.  `finalizeObsoleteVote(uint256 insightId)`: Triggered by anyone after the obsolete vote period ends to process votes and potentially mark the insight as obsolete.
10. `claimGeneratedInfluence(uint256[] calldata insightIds)`: Allows a user to claim Influence Points generated passively from active insights they contributed to or curated, accounting for time and decay.
11. `getUserInfluence(address user)`: Returns the current Influence Points of a user.
12. `getInsightDetails(uint256 insightId)`: Returns detailed information about a specific insight.
13. `getUserDetails(address user)`: Returns detailed information about a user.
14. `getTotalInsightsCount()`: Returns the total number of insights ever submitted.
15. `getPendingInsightsCount()`: Returns the number of insights currently in the pending state.
16. `getActiveInsightsCount()`: Returns the number of insights currently in the active state.
17. `getObsoleteInsightsCount()`: Returns the number of insights currently in the obsolete state.
18. `getInsightState(uint256 insightId)`: Returns the current state of a specific insight.
19. `getInsightCuratorVotes(uint256 insightId)`: Returns mapping of curators and their staked amounts for a pending insight.
20. `getInsightVoteEndTime(uint256 insightId)`: Returns the timestamp when the current vote (curation or obsolete) for an insight ends.
21. `updateSubmissionStake(uint256 newStake)`: Owner function to update the required stake for submitting insights.
22. `updateCurationStake(uint256 newStake)`: Owner function to update the required stake for curating insights.
23. `updateIpGenerationRate(uint256 newRate)`: Owner function to update the rate at which active insights generate IP.
24. `updateDecayRate(uint256 newRate)`: Owner function to update the rate at which active insight influence decays.
25. `updateObsoleteVoteThreshold(uint256 newThreshold)`: Owner function to update the required vote weight/stake to mark an insight obsolete.
26. `updateObsoleteVoteDuration(uint256 newDuration)`: Owner function to update the duration of obsolete voting periods.
27. `transferOwnership(address newOwner)`: Transfers contract ownership (from Ownable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Chrono-Vault of Evolving Insights ---
// Purpose: A decentralized platform for submitting, curating, and evolving knowledge/insights,
// rewarding participants based on their influence and contribution longevity
// via non-transferable "Influence Points" (IP).
//
// Core Concepts:
// - Insights: User-submitted data with a lifecycle (Pending, Active, Obsolete).
// - Users: Tracked by address, accumulating non-transferable Influence Points (IP).
// - Staking: Required for submitting and curating insights, held as collateral and distributed/slashed based on outcomes.
// - Curation: A community-driven process to validate pending insights.
// - Evolution: Active insights passively generate IP and can be enhanced or marked obsolete over time.
// - Time Mechanics: Decay of insight influence, claim periods, voting durations.
// - Governance: Basic parameters adjustable by high-influence users or a simple owner model (using Ownable here).
//
// Key State Variables:
// - Mappings for Insights, Users, Influence Points, Staked amounts.
// - Counters for IDs.
// - Parameters (stake amounts, durations, rates).
// - Enum for Insight State.
//
// Key Functions:
// 1. constructor(): Initializes the contract.
// 2. submitInsight(string memory data, uint256 category): Submit new insight, stake ETH.
// 3. curateInsight(uint256 insightId): Stake ETH to vote/support a pending insight.
// 4. finalizeCuration(uint256 insightId): Finalizes curation vote, distributes stakes, updates state.
// 5. claimInsightStake(uint256 insightId): Claim back initial submission stake.
// 6. claimCurationStake(uint256 insightId): Claim back curation stake.
// 7. enhanceInsight(uint256 insightId, string memory newData): Update active insight, reset decay.
// 8. startObsoleteVote_Community(uint256 insightId): Initiate vote to mark insight obsolete.
// 9. finalizeObsoleteVote(uint256 insightId): Finalizes obsolete vote.
// 10. claimGeneratedInfluence(uint256[] calldata insightIds): Claim passive IP from active insights.
// 11. getUserInfluence(address user): Get user's total IP.
// 12. getUserDetails(address user): Get user's details.
// 13. getInsightDetails(uint256 insightId): Get insight details.
// 14. getTotalInsightsCount(): Total insights submitted.
// 15. getPendingInsightsCount(): Insights in Pending state.
// 16. getActiveInsightsCount(): Insights in Active state.
// 17. getObsoleteInsightsCount(): Insights in Obsolete state.
// 18. getInsightState(uint256 insightId): Get state of specific insight.
// 19. getInsightCuratorVotes(uint256 insightId): Get curator stakes for pending insight.
// 20. getInsightVoteEndTime(uint256 insightId): Get voting end time for insight.
// 21. updateSubmissionStake(uint256 newStake): Owner adjusts submission stake.
// 22. updateCurationStake(uint256 newStake): Owner adjusts curation stake.
// 23. updateIpGenerationRate(uint256 newRate): Owner adjusts IP generation rate.
// 24. updateDecayRate(uint256 newRate): Owner adjusts IP decay rate.
// 25. updateObsoleteVoteThreshold(uint256 newThreshold): Owner adjusts obsolete vote threshold.
// 26. updateObsoleteVoteDuration(uint256 newDuration): Owner adjusts obsolete vote duration.
// 27. transferOwnership(address newOwner): Transfer contract ownership.


contract ChronoVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums ---
    enum InsightState {
        PendingCuration,
        Active,
        ObsoleteVoting,
        Obsolete,
        Rejected
    }

    // --- Structs ---
    struct Insight {
        uint256 id;
        string data;
        uint256 category;
        address submitter;
        uint256 submissionStake;
        InsightState state;
        uint256 submissionTimestamp;
        uint256 activationTimestamp; // Timestamp when it became Active
        uint256 lastActivityTimestamp; // Last timestamp of activation or enhancement
        uint256 lastInfluenceClaimTimestamp; // Timestamp when influence was last claimed
        uint256 curationVoteEndTime;
        mapping(address => uint256) curatorStakes; // Stakes from users curating this insight
        uint256 totalCurationStake; // Sum of all curator stakes for this insight
        uint256 obsoleteVoteEndTime;
        mapping(address => bool) obsoleteVotes; // Users who voted for obsolete
        uint256 totalObsoleteVotes; // Count of votes (can be weighted by IP if implemented)
        bool submitterStakeClaimed;
        bool curatorStakesClaimed; // Simplified: track if curator stakes were processed/claimed after finalization
        bool influenceClaimed; // Simplified: track if initial influence was claimed after activation
    }

    struct User {
        uint256 id;
        address walletAddress;
        uint256 influencePoints; // Non-transferable IP
        uint256 lastGlobalInfluenceClaimTimestamp; // Timestamp user last claimed IP across multiple insights
    }

    // --- State Variables ---
    uint256 public nextInsightId = 1;
    mapping(uint256 => Insight) public insights;
    mapping(address => uint256) private userIds; // address -> userId
    mapping(uint256 => User) private users; // userId -> User
    uint256 private nextUserId = 1;

    uint256 public submissionStake = 0.1 ether; // Required ETH stake to submit
    uint256 public curationStake = 0.05 ether; // Required ETH stake to curate
    uint256 public curationVoteDuration = 7 days; // Duration for curation voting
    uint256 public ipGenerationRatePerSecond = 1; // IP generated per second for active insights (per contributor/curator)
    uint256 public decayRatePerSecond = 1; // IP decay rate per second for active insights (affects generation)

    uint256 public obsoleteVoteStake = 0.02 ether; // Required ETH stake to start obsolete vote
    uint256 public obsoleteVoteDuration = 3 days; // Duration for obsolete voting
    uint256 public obsoleteVoteThreshold = 5; // Number of votes/stakes required to mark obsolete (can be weighted by IP)

    // Counters for different states (simplified, could be refined with iterable lists if needed)
    uint256 public pendingInsightsCount = 0;
    uint256 public activeInsightsCount = 0;
    uint256 public obsoleteInsightsCount = 0;
    uint256 public rejectedInsightsCount = 0;


    // --- Events ---
    event InsightSubmitted(uint256 indexed insightId, address indexed submitter, uint256 category, string data);
    event InsightCurated(uint256 indexed insightId, address indexed curator, uint256 stakedAmount);
    event CurationFinalized(uint256 indexed insightId, InsightState newState);
    event InsightStakeClaimed(uint256 indexed insightId, address indexed submitter, uint256 amount);
    event CurationStakeClaimed(uint256 indexed insightId, address indexed curator, uint256 amount);
    event InsightEnhanced(uint256 indexed insightId, address indexed enancer, string newData);
    event ObsoleteVoteStarted(uint256 indexed insightId, address indexed initiator);
    event ObsoleteVoteFinalized(uint256 indexed insightId, bool markedObsolete);
    event InfluenceEarned(address indexed user, uint256 amount);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event InsightStateChanged(uint256 indexed insightId, InsightState oldState, InsightState newState);

    // --- Modifiers ---
    modifier onlyInsightState(uint256 _insightId, InsightState _expectedState) {
        require(insights[_insightId].state == _expectedState, "ChronoVault: Incorrect insight state");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Initial parameters are set as state variables
    }

    // --- Core Functions ---

    /// @notice Allows a user to submit a new insight. Requires staking ETH.
    /// @param _data The content of the insight.
    /// @param _category A category identifier for the insight.
    function submitInsight(string memory _data, uint256 _category) external payable nonReentrant {
        require(msg.value >= submissionStake, "ChronoVault: Insufficient submission stake");

        uint256 insightId = nextInsightId++;
        address submitterAddress = msg.sender;

        // Ensure user exists or create one
        _ensureUserExists(submitterAddress);

        Insight storage newInsight = insights[insightId];
        newInsight.id = insightId;
        newInsight.data = _data;
        newInsight.category = _category;
        newInsight.submitter = submitterAddress;
        newInsight.submissionStake = msg.value; // Store actual staked amount
        newInsight.state = InsightState.PendingCuration;
        newInsight.submissionTimestamp = block.timestamp;
        newInsight.curationVoteEndTime = block.timestamp + curationVoteDuration; // Set curation voting end time

        pendingInsightsCount++;

        emit InsightSubmitted(insightId, submitterAddress, _category, _data);
        emit InsightStateChanged(insightId, InsightState(0), InsightState.PendingCuration); // State(0) is default initial
    }

    /// @notice Allows a user to stake ETH to support and vote for a pending insight.
    /// @param _insightId The ID of the insight to curate.
    function curateInsight(uint256 _insightId) external payable nonReentrant onlyInsightState(_insightId, InsightState.PendingCuration) {
        Insight storage insight = insights[_insightId];
        require(block.timestamp < insight.curationVoteEndTime, "ChronoVault: Curation voting period has ended");
        require(msg.value >= curationStake, "ChronoVault: Insufficient curation stake");
        require(insight.submitter != msg.sender, "ChronoVault: Cannot curate your own insight");
        require(insight.curatorStakes[msg.sender] == 0, "ChronoVault: Already curated this insight");

        // Ensure user exists or create one
        _ensureUserExists(msg.sender);

        insight.curatorStakes[msg.sender] = msg.value; // Store actual staked amount
        insight.totalCurationStake = insight.totalCurationStake.add(msg.value);

        emit InsightCurated(_insightId, msg.sender, msg.value);
    }

    /// @notice Triggered after curation period ends to process votes and state transition.
    /// Can be called by anyone.
    /// @param _insightId The ID of the insight to finalize.
    function finalizeCuration(uint256 _insightId) external nonReentrant onlyInsightState(_insightId, InsightState.PendingCuration) {
        Insight storage insight = insights[_insightId];
        require(block.timestamp >= insight.curationVoteEndTime, "ChronoVault: Curation voting period is still active");
        require(!insight.curatorStakesClaimed, "ChronoVault: Curation stakes already processed"); // Use this flag to ensure this only runs once

        // Decision logic: Simple example: Becomes Active if total curation stake meets or exceeds submission stake.
        // More complex: Weighted by curator IP, minimum number of curators, etc.
        InsightState newState;
        if (insight.totalCurationStake >= insight.submissionStake) {
            newState = InsightState.Active;
            insight.activationTimestamp = block.timestamp;
            insight.lastActivityTimestamp = block.timestamp;
            insight.lastInfluenceClaimTimestamp = block.timestamp; // Initialize claim timestamp
            activeInsightsCount++;
            pendingInsightsCount--;
            // Initial IP grant could happen here or on first claimGeneratedInfluence
        } else {
            newState = InsightState.Rejected;
            rejectedInsightsCount++;
            pendingInsightsCount--;
            // Staked ETH remains in contract until claimed or distributed according to rules
        }

        insight.state = newState;
        insight.curatorStakesClaimed = true; // Mark as processed

        emit CurationFinalized(_insightId, newState);
        emit InsightStateChanged(_insightId, InsightState.PendingCuration, newState);
    }

    /// @notice Allows the submitter to claim their stake back after curation is finalized.
    /// Full refund if Active, partial/none if Rejected (depending on slashing rules).
    /// @param _insightId The ID of the insight.
    function claimInsightStake(uint256 _insightId) external nonReentrant {
        Insight storage insight = insights[_insightId];
        require(insight.submitter == msg.sender, "ChronoVault: Not the insight submitter");
        require(insight.state == InsightState.Active || insight.state == InsightState.Rejected, "ChronoVault: Curation not finalized yet");
        require(!insight.submitterStakeClaimed, "ChronoVault: Submitter stake already claimed");

        uint256 amountToReturn = 0;
        if (insight.state == InsightState.Active) {
            amountToReturn = insight.submissionStake; // Full refund on success
        } else if (insight.state == InsightState.Rejected) {
            // Example: Partial refund on rejection (e.g., 50%) or slash fully
            amountToReturn = insight.submissionStake / 2; // Simple slashing example
            // The remaining slashed amount stays in the contract or could go to a treasury
        }

        insight.submitterStakeClaimed = true;

        if (amountToReturn > 0) {
            payable(msg.sender).transfer(amountToReturn);
            emit InsightStakeClaimed(_insightId, msg.sender, amountToReturn);
        }
    }

    /// @notice Allows curators to claim their stake back after curation is finalized.
    /// Full refund if Active, slashed if Rejected.
    /// @param _insightId The ID of the insight.
    function claimCurationStake(uint256 _insightId) external nonReentrant {
        Insight storage insight = insights[_insightId];
        require(insight.state == InsightState.Active || insight.state == InsightState.Rejected, "ChronoVault: Curation not finalized yet");
        require(insight.curatorStakes[msg.sender] > 0, "ChronoVault: No stake from this user for this insight");
        // Can't use a simple bool like `curatorStakesClaimed` here because multiple curators need to claim
        // Use the stake mapping itself to track if claimed (set to 0 after claim)

        uint256 stakedAmount = insight.curatorStakes[msg.sender];
        require(stakedAmount > 0, "ChronoVault: Stake already claimed");

        uint256 amountToReturn = 0;
        if (insight.state == InsightState.Active) {
            amountToReturn = stakedAmount; // Full refund on success
            // Or could distribute a bonus from slashed submitter stakes
        } else if (insight.state == InsightState.Rejected) {
             // Example: Slash curator stake if they voted for a rejected insight
             amountToReturn = stakedAmount / 4; // Simple slashing example
        }

        insight.curatorStakes[msg.sender] = 0; // Mark stake as claimed

        if (amountToReturn > 0) {
            payable(msg.sender).transfer(amountToReturn);
            emit CurationStakeClaimed(_insightId, msg.sender, amountToReturn);
        }
    }

    /// @notice Allows a user with sufficient influence to update an active insight. Resets decay timer.
    /// Requires user to have at least submissionStake equivalent IP (simplified rule).
    /// @param _insightId The ID of the insight to enhance.
    /// @param _newData The new data/content for the insight.
    function enhanceInsight(uint256 _insightId, string memory _newData) external nonReentrant onlyInsightState(_insightId, InsightState.Active) {
        Insight storage insight = insights[_insightId];
        uint256 userId = userIds[msg.sender];
        require(userId > 0, "ChronoVault: User not registered");
        require(users[userId].influencePoints >= submissionStake / 1 ether, "ChronoVault: Insufficient influence to enhance"); // IP threshold example

        insight.data = _newData;
        insight.lastActivityTimestamp = block.timestamp; // Reset decay timer

        // Could potentially reward enancer with a small amount of IP

        emit InsightEnhanced(_insightId, msg.sender, _newData);
    }

    /// @notice Allows a user to start a community vote to mark an active insight as obsolete.
    /// Requires staking ETH.
    /// @param _insightId The ID of the insight to propose for obsolescence.
    function startObsoleteVote_Community(uint256 _insightId) external payable nonReentrant onlyInsightState(_insightId, InsightState.Active) {
        Insight storage insight = insights[_insightId];
        require(msg.value >= obsoleteVoteStake, "ChronoVault: Insufficient obsolete vote stake");
        require(block.timestamp >= insight.lastActivityTimestamp + 30 days, "ChronoVault: Insight too recently active/enhanced"); // Cooldown period
        require(insight.state != InsightState.ObsoleteVoting, "ChronoVault: Obsolete vote already in progress");
        require(!insight.obsoleteVotes[msg.sender], "ChronoVault: Already voted/staked on this obsolete proposal"); // Can only initiate or vote once

        // Transition state immediately to prevent multiple votes starting
        emit InsightStateChanged(_insightId, InsightState.Active, InsightState.ObsoleteVoting);
        insight.state = InsightState.ObsoleteVoting;
        activeInsightsCount--;
        // obsoleteVotingInsightsCount++; // If we tracked this state separately

        insight.obsoleteVoteEndTime = block.timestamp + obsoleteVoteDuration;
        insight.obsoleteVotes[msg.sender] = true; // Record vote/stake
        insight.totalObsoleteVotes++; // Simple vote count

        // Note: Staked ETH for obsolete vote stays with the contract for now,
        // could be distributed or slashed upon finalization.

        emit ObsoleteVoteStarted(_insightId, msg.sender);
    }

    /// @notice Triggered after the obsolete vote period ends to process votes and state transition.
    /// Can be called by anyone.
    /// @param _insightId The ID of the insight to finalize.
    function finalizeObsoleteVote(uint256 _insightId) external nonReentrant onlyInsightState(_insightId, InsightState.ObsoleteVoting) {
        Insight storage insight = insights[_insightId];
        require(block.timestamp >= insight.obsoleteVoteEndTime, "ChronoVault: Obsolete voting period is still active");

        // Decision logic: Simple example: Becomes Obsolete if total votes meet threshold.
        InsightState newState;
        if (insight.totalObsoleteVotes >= obsoleteVoteThreshold) {
            newState = InsightState.Obsolete;
            obsoleteInsightsCount++;
            // obsoleteVotingInsightsCount--;
        } else {
            newState = InsightState.Active; // Revert to Active if vote fails
            activeInsightsCount++;
            // obsoleteVotingInsightsCount--;
            insight.lastActivityTimestamp = block.timestamp; // Maybe reset decay on failed obsolete vote?
        }

        emit InsightStateChanged(_insightId, InsightState.ObsoleteVoting, newState);
        insight.state = newState;

        // Staked ETH from obsolete votes remains in contract. Could be redistributed to
        // voters on the winning side or slashed on losing side based on more complex logic.
    }

    /// @notice Allows a user to claim Influence Points generated passively from active insights they contributed to or curated.
    /// Calculates IP earned since last claim based on time and decay.
    /// @param _insightIds The IDs of the insights to claim influence from.
    function claimGeneratedInfluence(uint256[] calldata _insightIds) external nonReentrant {
        uint256 userId = userIds[msg.sender];
        require(userId > 0, "ChronoVault: User not registered");
        User storage user = users[userId];

        uint256 totalNewInfluence = 0;
        uint256 currentTimestamp = block.timestamp;

        // Track claimed insights in this call to prevent double counting if multiple IDs are same
        mapping(uint256 => bool) claimedInCall;

        for (uint i = 0; i < _insightIds.length; i++) {
            uint256 insightId = _insightIds[i];
            require(insightId > 0 && insightId < nextInsightId, "ChronoVault: Invalid insight ID");
            Insight storage insight = insights[insightId];

            if (claimedInCall[insightId]) {
                 continue; // Skip if already processed in this call
            }
            claimedInCall[insightId] = true;

            // Check if the user contributed or curated this insight
            bool isContributor = (insight.submitter == msg.sender && insight.state == InsightState.Active && insight.submitterStakeClaimed); // Ensure submitter stake was claimed successfully (implies activation)
            bool isCurator = (insight.curatorStakes[msg.sender] == 0 && insight.state == InsightState.Active && insight.curatorStakesClaimed); // Simplified: check if they curated AND stakes were processed (implies activation)

            if ((isContributor || isCurator) && insight.state == InsightState.Active) {
                // Calculate time elapsed since last activity (activation or enhancement)
                uint256 timeActive = currentTimestamp.sub(insight.lastActivityTimestamp);

                // Calculate time elapsed since last influence claim for this *specific* insight
                // More granular tracking needed if per-insight claim timestamps are desired.
                // Let's use a global user timestamp for simplification in this example.
                // IP is calculated based on the *insight's* active time relative to its last *activity* and *decay* rate.
                // The user claims *their share* of this generated potential based on how long it's been since *they* last claimed influence globally.

                uint256 lastClaim = user.lastGlobalInfluenceClaimTimestamp; // Use global user timestamp
                if (lastClaim < insight.activationTimestamp) {
                    lastClaim = insight.activationTimestamp; // Cannot claim before insight was active
                }
                 if (lastClaim < insight.lastActivityTimestamp) {
                    lastClaim = insight.lastActivityTimestamp; // Cannot claim before last enhancement
                }


                uint256 timeSinceLastUserClaimOnInsight = currentTimestamp.sub(lastClaim);
                 if (timeSinceLastUserClaimOnInsight == 0) {
                     continue; // No time passed since last claim for this user on this insight
                 }


                // Calculate IP generated based on current active time and decay
                // Simplification: IP generation rate decays over time.
                // Active time relative to last activity (enhancement/activation)
                uint256 effectiveActiveTimeSinceActivity = currentTimestamp.sub(insight.lastActivityTimestamp);

                // Decay factor increases with effective active time.
                // Example: Decay = effectiveActiveTimeSinceActivity * decayRatePerSecond
                // Effective IP generation = max(0, ipGenerationRatePerSecond - Decay)
                uint256 decayAmount = effectiveActiveTimeSinceActivity.mul(decayRatePerSecond);
                uint256 currentEffectiveIPRate = (ipGenerationRatePerSecond > decayAmount) ? ipGenerationRatePerSecond.sub(decayAmount) : 0;


                // IP earned in this period = effective rate * time since last user claim
                uint256 ipEarnedThisPeriod = currentEffectiveIPRate.mul(timeSinceLastUserClaimOnInsight);

                // Distribute IP based on contribution type (example: 70% submitter, 30% curators)
                if (isContributor) {
                    totalNewInfluence = totalNewInfluence.add(ipEarnedThisPeriod.mul(70).div(100)); // Example split
                }
                 if (isCurator) {
                    totalNewInfluence = totalNewInfluence.add(ipEarnedThisPeriod.mul(30).div(100)); // Example split
                }

                 // Note: This IP calculation needs careful thought for fairness and gas.
                 // Storing per-user-per-insight last claim timestamp is more accurate but gas heavy.
                 // Using a global user timestamp is simpler but less precise if users claim sporadically across many insights.
                 // The current simplified approach applies the same decay factor from insight.lastActivityTimestamp
                 // regardless of when the user last claimed specific to that insight.
                 // This might slightly favor users who claim less often, which could be a feature or bug depending on design.
            }
        }

        if (totalNewInfluence > 0) {
            user.influencePoints = user.influencePoints.add(totalNewInfluence);
            user.lastGlobalInfluenceClaimTimestamp = currentTimestamp; // Update global timestamp
            emit InfluenceEarned(msg.sender, totalNewInfluence);
        }
    }

    // --- View Functions ---

    /// @notice Returns the current Influence Points of a user.
    /// @param _user The address of the user.
    /// @return The total Influence Points.
    function getUserInfluence(address _user) external view returns (uint256) {
        uint256 userId = userIds[_user];
        if (userId == 0) {
            return 0; // User not registered
        }
        return users[userId].influencePoints;
    }

    /// @notice Returns detailed information about a user.
    /// @param _user The address of the user.
    /// @return userId, walletAddress, influencePoints, lastGlobalInfluenceClaimTimestamp.
    function getUserDetails(address _user) external view returns (uint256, address, uint256, uint256) {
         uint256 userId = userIds[_user];
        if (userId == 0) {
            return (0, address(0), 0, 0); // User not registered
        }
        User storage user = users[userId];
        return (user.id, user.walletAddress, user.influencePoints, user.lastGlobalInfluenceClaimTimestamp);
    }


    /// @notice Returns detailed information about a specific insight.
    /// @param _insightId The ID of the insight.
    /// @return id, data, category, submitter, submissionStake, state, submissionTimestamp, activationTimestamp, lastActivityTimestamp, lastInfluenceClaimTimestamp, curationVoteEndTime, totalCurationStake, obsoleteVoteEndTime, totalObsoleteVotes, submitterStakeClaimed, curatorStakesClaimed, influenceClaimed status.
    function getInsightDetails(uint256 _insightId) external view returns (
        uint256 id,
        string memory data,
        uint256 category,
        address submitter,
        uint256 submissionStakeAmount,
        InsightState state,
        uint256 submissionTimestamp,
        uint256 activationTimestamp,
        uint256 lastActivityTimestamp,
        uint256 lastInfluenceClaimTimestamp,
        uint256 curationVoteEndTime,
        uint256 totalCurationStakeAmount,
        uint256 obsoleteVoteEndTime,
        uint256 totalObsoleteVotesCount,
        bool submitterStakeClaimedStatus,
        bool curatorStakesClaimedStatus,
        bool influenceClaimedStatus // Represents if initial IP was claimed (can be extended)
    ) {
        require(_insightId > 0 && _insightId < nextInsightId, "ChronoVault: Invalid insight ID");
        Insight storage insight = insights[_insightId];
        return (
            insight.id,
            insight.data,
            insight.category,
            insight.submitter,
            insight.submissionStake,
            insight.state,
            insight.submissionTimestamp,
            insight.activationTimestamp,
            insight.lastActivityTimestamp,
            insight.lastInfluenceClaimTimestamp,
            insight.curationVoteEndTime,
            insight.totalCurationStake,
            insight.obsoleteVoteEndTime,
            insight.totalObsoleteVotes,
            insight.submitterStakeClaimed,
            insight.curatorStakesClaimed,
            insight.influenceClaimed // placeholder flag
        );
    }

    /// @notice Returns the total number of insights ever submitted.
    function getTotalInsightsCount() external view returns (uint256) {
        return nextInsightId - 1;
    }

    /// @notice Returns the number of insights currently in the pending state.
    function getPendingInsightsCount() external view returns (uint256) {
        return pendingInsightsCount;
    }

    /// @notice Returns the number of insights currently in the active state.
    function getActiveInsightsCount() external view returns (uint256) {
        return activeInsightsCount;
    }

    /// @notice Returns the number of insights currently in the obsolete state.
    function getObsoleteInsightsCount() external view returns (uint256) {
        return obsoleteInsightsCount;
    }

    /// @notice Returns the current state of a specific insight.
    /// @param _insightId The ID of the insight.
    /// @return The state of the insight.
    function getInsightState(uint256 _insightId) external view returns (InsightState) {
        require(_insightId > 0 && _insightId < nextInsightId, "ChronoVault: Invalid insight ID");
        return insights[_insightId].state;
    }

    /// @notice Returns the total aggregated curation stake for a pending insight.
    /// Individual curator stakes can be retrieved if a helper mapping is added.
    /// @param _insightId The ID of the insight.
    /// @return The total staked amount by all curators for this insight.
    function getInsightCuratorVotes(uint256 _insightId) external view onlyInsightState(_insightId, InsightState.PendingCuration) returns (uint256) {
         return insights[_insightId].totalCurationStake;
    }

     /// @notice Returns the timestamp when the current vote (curation or obsolete) for an insight ends.
     /// @param _insightId The ID of the insight.
     /// @return The end timestamp of the vote.
    function getInsightVoteEndTime(uint256 _insightId) external view returns (uint256) {
        require(_insightId > 0 && _insightId < nextInsightId, "ChronoVault: Invalid insight ID");
        InsightState state = insights[_insightId].state;
        if (state == InsightState.PendingCuration) {
            return insights[_insightId].curationVoteEndTime;
        } else if (state == InsightState.ObsoleteVoting) {
            return insights[_insightId].obsoleteVoteEndTime;
        }
        return 0; // No active vote
    }


    // --- Governance/Parameter Functions (Owner only for simplicity) ---

    /// @notice Allows the owner to update the required stake for submitting insights.
    /// @param _newStake The new required stake amount in wei.
    function updateSubmissionStake(uint256 _newStake) external onlyOwner {
        require(_newStake > 0, "ChronoVault: Stake must be greater than 0");
        emit ParametersUpdated("submissionStake", submissionStake, _newStake);
        submissionStake = _newStake;
    }

    /// @notice Allows the owner to update the required stake for curating insights.
    /// @param _newStake The new required stake amount in wei.
    function updateCurationStake(uint256 _newStake) external onlyOwner {
        require(_newStake > 0, "ChronoVault: Stake must be greater than 0");
        emit ParametersUpdated("curationStake", curationStake, _newStake);
        curationStake = _newStake;
    }

    /// @notice Allows the owner to update the rate at which active insights generate IP.
    /// @param _newRate The new IP generation rate per second.
    function updateIpGenerationRate(uint256 _newRate) external onlyOwner {
        emit ParametersUpdated("ipGenerationRatePerSecond", ipGenerationRatePerSecond, _newRate);
        ipGenerationRatePerSecond = _newRate;
    }

    /// @notice Allows the owner to update the rate at which active insight influence decays.
    /// @param _newRate The new decay rate per second.
    function updateDecayRate(uint256 _newRate) external onlyOwner {
         emit ParametersUpdated("decayRatePerSecond", decayRatePerSecond, _newRate);
        decayRatePerSecond = _newRate;
    }

    /// @notice Allows the owner to update the required vote threshold to mark an insight obsolete.
    /// @param _newThreshold The new vote count threshold.
    function updateObsoleteVoteThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "ChronoVault: Threshold must be greater than 0");
        emit ParametersUpdated("obsoleteVoteThreshold", obsoleteVoteThreshold, _newThreshold);
        obsoleteVoteThreshold = _newThreshold;
    }

    /// @notice Allows the owner to update the duration of obsolete voting periods.
    /// @param _newDuration The new duration in seconds.
    function updateObsoleteVoteDuration(uint256 _newDuration) external onlyOwner {
         require(_newDuration > 0, "ChronoVault: Duration must be greater than 0");
        emit ParametersUpdated("obsoleteVoteDuration", obsoleteVoteDuration, _newDuration);
        obsoleteVoteDuration = _newDuration;
    }

    // Function 27 is transferOwnership inherited from Ownable

    // --- Internal/Helper Functions ---

    /// @dev Ensures a user entry exists for the given address, creates one if not.
    /// @param _user Address to check/create.
    function _ensureUserExists(address _user) internal {
        if (userIds[_user] == 0) {
            uint256 userId = nextUserId++;
            userIds[_user] = userId;
            users[userId] = User({
                id: userId,
                walletAddress: _user,
                influencePoints: 0,
                lastGlobalInfluenceClaimTimestamp: block.timestamp
            });
        }
    }

    // --- Receive/Fallback ---
    receive() external payable {}
    fallback() external payable {} // Allow receiving ETH for stakes or manual deposits

    // --- Consider adding: ---
    // - Functions to withdraw slashed/ excess ETH by owner/governance.
    // - More sophisticated IP calculation and decay.
    // - Weighted obsolete votes based on IP.
    // - More states (e.g., pending obsolete vote, challenged).
    // - Iterators for listing insights by state (gas heavy, maybe offchain indexing is better).
    // - ERC20 staking instead of ETH.
    // - More advanced governance using Influence Points directly.
}
```
**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic State & Lifecycle:** Insights aren't static. They move through explicit states (`PendingCuration`, `Active`, `ObsoleteVoting`, `Obsolete`, `Rejected`) triggered by time and user interactions (`finalizeCuration`, `enhanceInsight`, `finalizeObsoleteVote`). This models a dynamic knowledge base.
2.  **Influence Points (IP):** A non-transferable, internal score (`influencePoints` in `User` struct). It's earned passively from *Active* insights the user contributed to or curated. This acts like an on-chain reputation or "Soulbound" score within the context of the Chrono-Vault, tying a user's standing to their successful contributions over time, rather than tradable tokens.
3.  **Time-Based Passive Generation & Decay:** The `claimGeneratedInfluence` function implements a passive IP generation mechanism. Critically, this generation rate `ipGenerationRatePerSecond` is offset by a `decayRatePerSecond` based on how long the insight has been `Active` since its last `enhanceInsight` or activation. This simulates insights becoming less relevant or "decaying" in their influence potential over time if not updated. The user has to *claim* this potential IP, and the calculation considers the time since *their* last claim (`lastGlobalInfluenceClaimTimestamp`).
4.  **Permissionless State Transitions:** `finalizeCuration` and `finalizeObsoleteVote` are designed to be triggered by *anyone* once the conditions (like time expiry) are met. This decentralizes the responsibility for moving the contract state forward, avoiding reliance on a specific admin or user.
5.  **Staking for Intent and Validation:** Staking ETH (or potentially other tokens) is required for `submitInsight`, `curateInsight`, and `startObsoleteVote_Community`. These stakes act as sybil resistance, commitment, and potential collateral for slashing if contributions/validations are unsuccessful or malicious (simple slashing examples included). Staked funds are held in the contract and released/slashed upon finalization.
6.  **Community Curation & Obsolete Voting:** These mechanisms (`curateInsight`, `finalizeCuration`, `startObsoleteVote_Community`, `finalizeObsoleteVote`) introduce decentralized decision-making processes for validating new insights and managing the obsolescence of existing ones. While simple vote counts are used here, this is designed to be extensible to weighted voting based on Influence Points.
7.  **Influence-Based Feature Access:** The `enhanceInsight` function requires a minimum level of `influencePoints`, demonstrating how the non-transferable IP can unlock utility and privileges within the platform.
8.  **ReentrancyGuard:** Used on functions involving external calls (`transfer`) and state changes (`submitInsight`, `curateInsight`, `finalizeCuration`, `claimInsightStake`, `claimCurationStake`, `enhanceInsight`, `startObsoleteVote_Community`, `finalizeObsoleteVote`, `claimGeneratedInfluence`) to prevent a common vulnerability in Solidity.
9.  **SafeMath:** Used for arithmetic operations to prevent overflow/underflow.
10. **Ownable for Parameters:** While the state transitions are permissionless triggers, critical parameters are managed by the contract owner. This provides a basic governance structure, which could be upgraded to a DAO model based on Influence Points.

This contract goes beyond simple token transfers or basic NFT minting by incorporating dynamic state based on time and community interaction, implementing a reputation system tied to contribution, and using staking for decentralized validation and lifecycle management. It's a conceptual framework that could be expanded into a complex dApp for curated knowledge bases, decentralized research, or similar applications where the value of information evolves.