This smart contract, `IntentNexus`, is designed to be a decentralized, collaborative platform for task fulfillment, incorporating advanced concepts like dynamic reputation-based collateral, on-chain dispute resolution with a juror system, and a robust intent-based workflow. It aims to foster trust and accountability in decentralized services, especially for tasks that may have off-chain components.

---

## Contract: `IntentNexus`

**Purpose:** A decentralized platform for submitting and fulfilling "Intents" (requests for tasks/services). It features a robust reputation system, collateral-based escrow, and on-chain dispute resolution. The goal is to foster trust and accountability in decentralized collaboration for complex, potentially off-chain, tasks.

**Key Concepts:**
*   **Intents:** User-defined requests with specified rewards, deadlines, and a description hash (pointing to off-chain details like IPFS).
*   **Fulfillment:** Execution of intents by network participants ("Fulfillers").
*   **Reputation:** A dynamic scoring system for participants based on successful fulfillments, valid challenges, and dispute outcomes. New users start with a default reputation.
*   **Collateral & Escrow:** Financial guarantees (ETH) locked by both Intentors and Fulfillers, managed by the contract. This collateral is dynamically adjusted based on a user's reputation.
*   **Dynamic Collateral Adjustment:** Collateral requirements for intents and claims adapt based on a user's reputation. Users with higher reputation might pay less collateral, while those with lower reputation pay more.
*   **Dispute Resolution:** An on-chain mechanism for challenging and resolving contested fulfillments, involving a whitelisted juror voting system and penalties/rewards.
*   **Protocol Fees:** A small fee collected by the protocol for challenge initiation and lost collateral/rewards from failed fulfillments, which can be withdrawn by the owner.

---

### Function Summary:

**I. Intent Lifecycle Management (6 functions)**

1.  `submitIntent(string calldata _descriptionHash, uint256 _reward, uint256 _fulfillByTimestamp)`:
    *   **Description:** Allows an 'Intentor' to create a new intent, locking the specified reward and their dynamically adjusted collateral. The `_descriptionHash` points to off-chain details (e.g., on IPFS).
    *   **Requires:** Future fulfill timestamp, non-zero reward, sufficient ETH for reward + dynamic collateral.
2.  `claimIntent(uint256 _intentId)`:
    *   **Description:** Allows a 'Fulfiller' to claim an open intent, locking their dynamically adjusted collateral.
    *   **Requires:** Intent must be open, not expired, and cannot be claimed by the intentor. Sufficient ETH for dynamic collateral.
3.  `submitFulfillmentProof(uint256 _intentId, string calldata _proofDataHash)`:
    *   **Description:** The Fulfiller submits cryptographic proof (hash) or a reference to the completed task.
    *   **Requires:** Intent must be in 'Claimed' status. Only the assigned fulfiller can submit.
4.  `verifyFulfillment(uint256 _intentId)`:
    *   **Description:** The Intentor confirms successful fulfillment, releasing the reward and fulfiller's collateral to the fulfiller, and returning the intentor's collateral. Reputation is updated for both parties.
    *   **Requires:** Intent must be in 'Fulfilled' status. Only the intentor can verify.
5.  `cancelIntent(uint256 _intentId)`:
    *   **Description:** The Intentor can cancel their intent if it hasn't been claimed and the fulfillment deadline has not passed. All locked funds (reward + intentor collateral) are returned.
    *   **Requires:** Intentor is the caller, intent is 'Open', not expired.
6.  `reclaimExpiredIntent(uint256 _intentId)`:
    *   **Description:** The Intentor can reclaim their reward and collateral if an intent expires without being claimed by any fulfiller.
    *   **Requires:** Intentor is the caller, intent is 'Open', and the fulfill-by timestamp has passed.

**II. Reputation & Collateral Management (3 functions)**

7.  `depositCollateral()`:
    *   **Description:** Users can pre-deposit ETH into their internal collateral balance, which can then be used for future intents or claims without needing to send ETH directly with each transaction.
    *   **Requires:** `msg.value` must be greater than zero.
8.  `withdrawCollateral(uint256 _amount)`:
    *   **Description:** Users can withdraw their available collateral balance from the contract.
    *   **Requires:** Sufficient collateral balance in the user's account.
9.  `getUserReputation(address _user)`:
    *   **Description:** View function to retrieve the current reputation score of any address. New users implicitly start with a default score (e.g., 100).
    *   **Returns:** The reputation score (uint256).

**III. Dispute Resolution System (4 functions)**

10. `challengeFulfillment(uint256 _intentId, string calldata _reasonHash)`:
    *   **Description:** Allows any *third-party* user to dispute a submitted fulfillment by staking a challenge fee. This initiates a voting period for jurors.
    *   **Requires:** Intent must be in 'Fulfilled' status. Challenger cannot be the intentor or fulfiller. Sufficient ETH for the challenge fee. No active challenge for the intent.
11. `voteOnChallenge(uint256 _intentId, bool _supportsFulfiller)`:
    *   **Description:** Allows a whitelisted juror to cast a vote on a challenge, indicating whether they support the fulfiller's claim of proper fulfillment or the challenger's claim of failure.
    *   **Requires:** Active challenge, within the voting period, and the caller must be a registered juror who hasn't voted yet.
12. `resolveChallenge(uint256 _intentId)`:
    *   **Description:** Finalizes a challenge based on the majority vote or after the voting duration expires, distributing collateral, updating reputations, and applying penalties/rewards.
    *   **Requires:** Intent is in 'Challenged' status, and either the voting duration has passed, or the minimum number of votes for resolution has been met.
13. `reclaimExpiredChallengeCollateral(uint256 _intentId)`:
    *   **Description:** Allows the challenger to reclaim their challenge fee if the dispute voting period ends without meeting the minimum votes required for resolution, preventing funds from being locked indefinitely.
    *   **Requires:** The challenge exists, is not resolved, is initiated by the caller, the voting period has passed, and minimum votes were not met.

**IV. Administrative & Configuration (7 functions)**

14. `pause()`:
    *   **Description:** Owner can pause most critical user-facing functions of the contract, leveraging the Pausable pattern.
    *   **Requires:** `onlyOwner`.
15. `unpause()`:
    *   **Description:** Owner can unpause the contract's functionality.
    *   **Requires:** `onlyOwner`.
16. `setProtocolParameters(uint256 _minIntentCollateral, uint256 _minFulfillerCollateral, uint256 _challengeFee, uint256 _voteDuration, uint256 _minVotesForResolution, uint256 _disputeResolveRewardRatio)`:
    *   **Description:** Owner sets key protocol-wide parameters for base collateral requirements, challenge fees, dispute voting duration, minimum votes for early resolution, and the percentage of challenge fees distributed as rewards in a dispute.
    *   **Requires:** `onlyOwner`, valid parameter values.
17. `setReputationParameters(uint256 _boostSuccess, uint256 _penaltyFailure, uint256 _boostValidChallenge, uint256 _penaltyInvalidChallenge)`:
    *   **Description:** Owner configures how reputation scores change based on different outcomes (successful fulfillment, failed fulfillment, valid challenge, invalid challenge).
    *   **Requires:** `onlyOwner`.
18. `setDynamicCollateralAdjustment(uint256 _lowReputationThreshold, uint256 _highReputationThreshold, uint256 _lowReputationMultiplierBP, uint256 _highReputationMultiplierBP)`:
    *   **Description:** Owner defines the parameters for how user reputation influences their collateral requirements. It sets thresholds and multipliers (in basis points) for low and high reputation users.
    *   **Requires:** `onlyOwner`, valid thresholds and multipliers.
19. `addJuror(address _juror)`:
    *   **Description:** Owner can add an address to the list of authorized jurors who can vote on challenges.
    *   **Requires:** `onlyOwner`, valid and unique address.
20. `removeJuror(address _juror)`:
    *   **Description:** Owner can remove an address from the list of authorized jurors.
    *   **Requires:** `onlyOwner`, address must be an existing juror.
21. `withdrawProtocolFees(address _recipient)`:
    *   **Description:** Owner can withdraw accumulated protocol fees (from challenge fees and lost collateral/rewards) to a specified recipient.
    *   **Requires:** `onlyOwner`.

**V. View Functions (3 functions)**

22. `getIntentDetails(uint256 _intentId)`:
    *   **Description:** Retrieves all structured data for a specific intent by its ID.
    *   **Returns:** Full `Intent` struct.
23. `getChallengeDetails(uint256 _intentId)`:
    *   **Description:** Retrieves all structured data for a specific challenge associated with an intent ID.
    *   **Returns:** Full `Challenge` struct.
24. `getProtocolParameters()`:
    *   **Description:** Retrieves all current global protocol configuration parameters.
    *   **Returns:** Full `ProtocolParameters` struct.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for explicit safety, though 0.8+ has built-in checks.

// Contract: IntentNexus
// Purpose: A decentralized platform for submitting and fulfilling "Intents" (requests for tasks/services).
// It features a robust reputation system, collateral-based escrow, and on-chain dispute resolution.
// The goal is to foster trust and accountability in decentralized collaboration for complex, potentially off-chain, tasks.

// Key Concepts:
// - Intents: User-defined requests with specified rewards, deadlines, and a description hash (pointing to off-chain details).
// - Fulfillment: Execution of intents by network participants ("Fulfillers").
// - Reputation: A dynamic scoring system for participants based on successful fulfillments, valid challenges, and dispute outcomes.
// - Collateral & Escrow: Financial guarantees (ETH) locked by both Intentors and Fulfillers, managed by the contract.
// - Dynamic Collateral Adjustment: Collateral requirements for intents and claims can adapt based on a user's reputation.
// - Dispute Resolution: An on-chain mechanism for challenging and resolving contested fulfillments, involving voting and penalties/rewards.
// - Protocol Fees: A small fee collected by the protocol for challenge initiation, which can be withdrawn by the owner.

// Function Summary:

// I. Intent Lifecycle Management (6 functions)
// 1.  submitIntent(string calldata _descriptionHash, uint256 _reward, uint256 _fulfillByTimestamp):
//     Allows an 'Intentor' to create a new intent, locking the specified reward and their dynamically adjusted collateral.
// 2.  claimIntent(uint256 _intentId):
//     Allows a 'Fulfiller' to claim an open intent, locking their dynamically adjusted collateral.
// 3.  submitFulfillmentProof(uint256 _intentId, string calldata _proofDataHash):
//     Fulfiller submits cryptographic proof (hash) or reference data of the completed task.
// 4.  verifyFulfillment(uint256 _intentId):
//     Intentor confirms successful fulfillment, releasing funds, updating reputation for both parties.
// 5.  cancelIntent(uint256 _intentId):
//     Intentor can cancel their intent if it hasn't been claimed and the deadline is not passed. Collateral is returned.
// 6.  reclaimExpiredIntent(uint256 _intentId):
//     Intentor can reclaim their reward and collateral if an intent expires without being claimed.

// II. Reputation & Collateral Management (3 functions)
// 7.  depositCollateral():
//     Users can pre-deposit ETH into their internal collateral balance, which can be used for future intents or claims.
// 8.  withdrawCollateral(uint256 _amount):
//     Users can withdraw their available collateral balance.
// 9.  getUserReputation(address _user):
//     View function to retrieve the current reputation score of any address.

// III. Dispute Resolution System (4 functions)
// 10. challengeFulfillment(uint256 _intentId, string calldata _reasonHash):
//     Allows any user to dispute a submitted fulfillment, staking a challenge fee.
// 11. voteOnChallenge(uint256 _intentId, bool _supportsFulfiller):
//     Allows a whitelisted juror (or anyone, based on admin settings) to cast a vote on a challenge.
// 12. resolveChallenge(uint256 _intentId):
//     Finalizes a challenge based on voting outcome or expiration, distributing collateral, updating reputations, and applying penalties/rewards.
// 13. reclaimExpiredChallengeCollateral(uint256 _intentId):
//     Allows the challenger to reclaim their fee if the challenge itself expires without sufficient votes.

// IV. Administrative & Configuration (7 functions)
// 14. pause():
//     Owner can pause core functionality of the contract (Pausable pattern).
// 15. unpause():
//     Owner can unpause core functionality.
// 16. setProtocolParameters(uint256 _minIntentCollateral, uint256 _minFulfillerCollateral, uint256 _challengeFee, uint256 _voteDuration, uint256 _minVotesForResolution, uint256 _disputeResolveRewardRatio):
//     Owner sets key protocol-wide parameters for collateral, fees, and dispute resolution.
// 17. setReputationParameters(uint256 _boostSuccess, uint256 _penaltyFailure, uint256 _boostValidChallenge, uint256 _penaltyInvalidChallenge):
//     Owner configures how reputation changes based on different outcomes.
// 18. setDynamicCollateralAdjustment(uint256 _lowReputationThreshold, uint256 _highReputationThreshold, uint256 _lowReputationMultiplierBP, uint256 _highReputationMultiplierBP):
//     Owner sets parameters for how reputation influences collateral requirements (in basis points).
// 19. addJuror(address _juror):
//     Owner can add an address to the list of authorized jurors for dispute voting.
// 20. removeJuror(address _juror):
//     Owner can remove an address from the list of authorized jurors.
// 21. withdrawProtocolFees(address _recipient):
//     Owner can withdraw accumulated protocol fees.

// V. View Functions (3 functions)
// 22. getIntentDetails(uint256 _intentId):
//     Retrieves all struct details for a specific intent.
// 23. getChallengeDetails(uint256 _intentId):
//     Retrieves all struct details for a specific challenge.
// 24. getProtocolParameters():
//     Retrieves all current global protocol parameters.

// Total Public/External Functions: 24

contract IntentNexus is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256; // Explicitly state SafeMath usage

    // Enum to represent the various states an Intent can be in
    enum IntentStatus {
        Open,        // Intent is submitted, awaiting a fulfiller
        Claimed,     // Intent has been claimed by a fulfiller
        Fulfilled,   // Fulfiller has submitted proof, awaiting intentor verification
        Challenged,  // Fulfillment has been challenged, dispute resolution is active
        Resolved,    // Intent is fully completed (verified or dispute resolved)
        Cancelled,   // Intentor cancelled before claim or expiry
        Expired      // Intent expired without being claimed
    }

    // Struct to store details about an Intent
    struct Intent {
        uint256 id;
        address payable intentor;           // Creator of the intent
        address payable fulfiller;          // Address of the fulfiller (address(0) if not claimed)
        uint256 reward;                     // ETH reward for successful fulfillment
        uint256 intentorCollateral;         // Collateral locked by the intentor
        uint256 fulfillerCollateral;        // Collateral locked by the fulfiller
        uint256 fulfillByTimestamp;         // Deadline for fulfillment
        string descriptionHash;             // IPFS hash or similar for intent details (off-chain)
        string fulfillmentProofHash;        // IPFS hash or similar for fulfillment proof (off-chain)
        IntentStatus status;                // Current status of the intent
        uint256 creationTimestamp;          // Timestamp when the intent was created
    }

    // Struct to store details about a Challenge
    struct Challenge {
        uint256 intentId;                   // ID of the intent being challenged
        address challenger;                 // Address of the user who initiated the challenge
        uint256 challengeFee;               // Fee paid by the challenger
        string reasonHash;                  // IPFS hash for challenge reason/evidence (off-chain)
        uint256 voteStartTime;              // Timestamp when voting period started
        uint256 votesForFulfiller;          // Number of votes supporting the fulfiller
        uint256 votesAgainstFulfiller;      // Number of votes supporting the challenger
        mapping(address => bool) hasVoted;  // Tracks if a juror has voted
        bool isResolved;                    // True if the challenge has been resolved
        bool resultSupportsFulfiller;       // True if fulfiller won, false if challenger won
    }

    // Struct for global protocol parameters
    struct ProtocolParameters {
        uint256 minIntentCollateral;        // Base minimum ETH collateral for an intentor
        uint256 minFulfillerCollateral;     // Base minimum ETH collateral for a fulfiller
        uint256 challengeFee;               // ETH fee to initiate a challenge
        uint256 voteDuration;               // Duration in seconds for a challenge vote
        uint256 minVotesForResolution;      // Minimum number of votes required to resolve a challenge early
        uint256 disputeResolveRewardRatio;  // Percentage of challenge fee for successful voters/winner (basis points)
    }

    // Struct for reputation adjustment parameters
    struct ReputationParameters {
        uint256 boostSuccess;               // Reputation points gained for successful fulfillment/verification
        uint256 penaltyFailure;             // Reputation points lost for failed fulfillment/invalid challenge
        uint256 boostValidChallenge;        // Reputation points gained for successful challenge
        uint256 penaltyInvalidChallenge;    // Reputation points lost for unsuccessful challenge
    }

    // Struct for dynamic collateral adjustment based on reputation
    struct DynamicCollateralAdjustment {
        uint256 lowReputationThreshold;     // Reputation below this threshold gets a higher multiplier
        uint256 highReputationThreshold;    // Reputation above this threshold gets a lower multiplier
        uint256 lowReputationMultiplierBP;  // Multiplier for low reputation users (e.g., 12000 for 1.2x)
        uint256 highReputationMultiplierBP; // Multiplier for high reputation users (e.g., 8000 for 0.8x)
        uint256 defaultMultiplierBP;        // Multiplier for users between thresholds (10000 for 1.0x)
    }

    uint256 private _nextIntentId;                                // Counter for unique intent IDs
    mapping(uint256 => Intent) public intents;                     // All intents by ID
    mapping(uint256 => Challenge) public challenges;               // All challenges by intent ID
    mapping(address => uint256) private _userReputation;           // User reputation scores (starts at 100)
    mapping(address => uint256) private _userCollateralBalances;   // User's internal collateral balance
    mapping(address => bool) private _isJuror;                     // Whitelisted jurors for dispute voting

    ProtocolParameters public protocolParams;
    ReputationParameters public reputationParams;
    DynamicCollateralAdjustment public collateralAdjustment;
    uint256 public totalProtocolFees;                              // Accumulated fees for the protocol owner

    // Events for tracking contract activity
    event IntentSubmitted(uint256 indexed intentId, address indexed intentor, uint256 reward, uint256 collateral, uint256 fulfillByTimestamp);
    event IntentClaimed(uint256 indexed intentId, address indexed fulfiller);
    event FulfillmentProofSubmitted(uint256 indexed intentId, address indexed fulfiller, string proofDataHash);
    event IntentVerified(uint256 indexed intentId, address indexed intentor, address indexed fulfiller);
    event IntentCancelled(uint256 indexed intentId, address indexed intentor);
    event IntentExpired(uint256 indexed intentId, address indexed intentor);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ChallengeInitiated(uint256 indexed intentId, address indexed challenger, uint256 challengeFee);
    event ChallengeVoted(uint256 indexed intentId, address indexed voter, bool supportsFulfiller);
    event ChallengeResolved(uint256 indexed intentId, bool resultSupportsFulfiller, uint256 protocolFeeAccrued);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {
        _nextIntentId = 1; // Initialize intent ID counter

        // Initialize default protocol parameters
        protocolParams = ProtocolParameters({
            minIntentCollateral: 0.1 ether,          // 0.1 ETH for intentor's base collateral
            minFulfillerCollateral: 0.05 ether,      // 0.05 ETH for fulfiller's base collateral
            challengeFee: 0.02 ether,                // 0.02 ETH to initiate a challenge
            voteDuration: 3 days,                    // 3 days for jurors to vote on a challenge
            minVotesForResolution: 3,                // Minimum votes needed to resolve a challenge early
            disputeResolveRewardRatio: 7000          // 70% of challenge fee distributed to winning party in dispute
        });

        // Initialize default reputation adjustment parameters
        reputationParams = ReputationParameters({
            boostSuccess: 10,                        // +10 reputation for success
            penaltyFailure: 20,                      // -20 reputation for failure
            boostValidChallenge: 15,                 // +15 reputation for valid challenge
            penaltyInvalidChallenge: 10              // -10 reputation for invalid challenge
        });

        // Initialize default dynamic collateral adjustment parameters
        collateralAdjustment = DynamicCollateralAdjustment({
            lowReputationThreshold: 50,              // Reputation below 50
            highReputationThreshold: 150,            // Reputation above 150
            lowReputationMultiplierBP: 12000,        // 1.2x collateral for low reputation
            highReputationMultiplierBP: 8000,        // 0.8x collateral for high reputation
            defaultMultiplierBP: 10000               // 1.0x collateral for default reputation range
        });
    }

    /**
     * @notice Internal helper to calculate adjusted collateral based on a user's reputation.
     * @param _user The address of the user.
     * @param _baseCollateral The base collateral amount before adjustment.
     * @return The dynamically adjusted collateral amount.
     */
    function _calculateAdjustedCollateral(address _user, uint256 _baseCollateral) internal view returns (uint256) {
        uint256 reputation = _userReputation[_user];
        if (reputation == 0) reputation = 100; // Default reputation for new users

        uint256 multiplierBP;
        if (reputation < collateralAdjustment.lowReputationThreshold) {
            multiplierBP = collateralAdjustment.lowReputationMultiplierBP;
        } else if (reputation > collateralAdjustment.highReputationThreshold) {
            multiplierBP = collateralAdjustment.highReputationMultiplierBP;
        } else {
            multiplierBP = collateralAdjustment.defaultMultiplierBP;
        }
        // Multiply base collateral by multiplier (in basis points), then divide by 10000 to get final amount
        return _baseCollateral.mul(multiplierBP).div(10000);
    }

    // --- I. Intent Lifecycle Management ---

    /// @notice Allows an 'Intentor' to create a new intent, locking the specified reward and their dynamically adjusted collateral.
    /// @param _descriptionHash IPFS hash or similar reference to the detailed intent description.
    /// @param _reward The ETH reward for successful fulfillment.
    /// @param _fulfillByTimestamp The timestamp by which the intent must be fulfilled.
    function submitIntent(string calldata _descriptionHash, uint256 _reward, uint256 _fulfillByTimestamp)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(_fulfillByTimestamp > block.timestamp, "Intent: Fulfill timestamp must be in the future.");
        require(_reward > 0, "Intent: Reward must be greater than zero.");
        require(bytes(_descriptionHash).length > 0, "Intent: Description hash cannot be empty.");

        uint256 requiredCollateral = _calculateAdjustedCollateral(msg.sender, protocolParams.minIntentCollateral);
        require(msg.value >= _reward.add(requiredCollateral), "Intent: Insufficient ETH sent for reward and collateral.");

        uint256 intentId = _nextIntentId++;
        intents[intentId] = Intent({
            id: intentId,
            intentor: payable(msg.sender),
            fulfiller: payable(address(0)), // Not claimed yet
            reward: _reward,
            intentorCollateral: requiredCollateral,
            fulfillerCollateral: 0,
            fulfillByTimestamp: _fulfillByTimestamp,
            descriptionHash: _descriptionHash,
            fulfillmentProofHash: "",
            status: IntentStatus.Open,
            creationTimestamp: block.timestamp
        });

        // Refund any excess ETH sent
        if (msg.value > _reward.add(requiredCollateral)) {
            payable(msg.sender).transfer(msg.value.sub(_reward.add(requiredCollateral)));
        }

        emit IntentSubmitted(intentId, msg.sender, _reward, requiredCollateral, _fulfillByTimestamp);
    }

    /// @notice Allows a 'Fulfiller' to claim an open intent, locking their dynamically adjusted collateral.
    /// @param _intentId The ID of the intent to claim.
    function claimIntent(uint256 _intentId) external payable nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist."); // Check if intent was initialized
        require(intent.status == IntentStatus.Open, "Intent: Not an open intent.");
        require(intent.fulfillByTimestamp > block.timestamp, "Intent: Intent has expired.");
        require(msg.sender != intent.intentor, "Intent: Cannot claim your own intent.");

        uint256 requiredCollateral = _calculateAdjustedCollateral(msg.sender, protocolParams.minFulfillerCollateral);
        require(msg.value >= requiredCollateral, "Intent: Insufficient ETH sent for fulfiller collateral.");

        intent.fulfiller = payable(msg.sender);
        intent.fulfillerCollateral = requiredCollateral;
        intent.status = IntentStatus.Claimed;

        // Refund any excess ETH sent
        if (msg.value > requiredCollateral) {
            payable(msg.sender).transfer(msg.value.sub(requiredCollateral));
        }

        emit IntentClaimed(_intentId, msg.sender);
    }

    /// @notice Fulfiller submits cryptographic proof (hash) or reference data of the completed task.
    /// @param _intentId The ID of the intent.
    /// @param _proofDataHash IPFS hash or similar reference to the fulfillment proof.
    function submitFulfillmentProof(uint256 _intentId, string calldata _proofDataHash) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist.");
        require(intent.status == IntentStatus.Claimed, "Intent: Not in claimed status.");
        require(msg.sender == intent.fulfiller, "Intent: Only the fulfiller can submit proof.");
        require(bytes(_proofDataHash).length > 0, "Intent: Proof hash cannot be empty.");

        intent.fulfillmentProofHash = _proofDataHash;
        intent.status = IntentStatus.Fulfilled; // Intent is now awaiting verification or challenge

        emit FulfillmentProofSubmitted(_intentId, msg.sender, _proofDataHash);
    }

    /// @notice Intentor confirms successful fulfillment, releasing funds, updating reputation for both parties.
    /// @param _intentId The ID of the intent.
    function verifyFulfillment(uint256 _intentId) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist.");
        require(intent.status == IntentStatus.Fulfilled, "Intent: Not in fulfilled status (awaiting proof or challenged).");
        require(msg.sender == intent.intentor, "Intent: Only the intentor can verify fulfillment.");

        // Transfer reward and fulfiller's collateral to fulfiller
        payable(intent.fulfiller).transfer(intent.reward.add(intent.fulfillerCollateral));
        // Return intentor's collateral
        payable(intent.intentor).transfer(intent.intentorCollateral);

        // Update reputation
        _userReputation[intent.fulfiller] = _userReputation[intent.fulfiller].add(reputationParams.boostSuccess);
        _userReputation[intent.intentor] = _userReputation[intent.intentor].add(reputationParams.boostSuccess.div(2)); // Intentor gets partial boost for successful collaboration
        
        intent.status = IntentStatus.Resolved; // Intent is now fully resolved

        emit IntentVerified(_intentId, msg.sender, intent.fulfiller);
        emit ReputationUpdated(intent.fulfiller, _userReputation[intent.fulfiller]);
        emit ReputationUpdated(intent.intentor, _userReputation[intent.intentor]);
    }

    /// @notice Intentor can cancel their intent if it hasn't been claimed and the deadline is not passed. Collateral is returned.
    /// @param _intentId The ID of the intent.
    function cancelIntent(uint256 _intentId) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist.");
        require(intent.intentor == msg.sender, "Intent: Only the intentor can cancel their intent.");
        require(intent.status == IntentStatus.Open, "Intent: Intent is not open for cancellation (already claimed/fulfilled).");
        require(intent.fulfillByTimestamp > block.timestamp, "Intent: Intent has already expired.");

        // Return all funds (reward + intentor's collateral) to the intentor
        payable(intent.intentor).transfer(intent.reward.add(intent.intentorCollateral));
        intent.status = IntentStatus.Cancelled;

        emit IntentCancelled(_intentId, msg.sender);
    }

    /// @notice Intentor can reclaim their reward and collateral if an intent expires without being claimed.
    /// @param _intentId The ID of the intent.
    function reclaimExpiredIntent(uint256 _intentId) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist.");
        require(intent.intentor == msg.sender, "Intent: Only the intentor can reclaim their expired intent.");
        require(intent.status == IntentStatus.Open, "Intent: Intent is not open (already claimed/fulfilled/cancelled).");
        require(intent.fulfillByTimestamp <= block.timestamp, "Intent: Intent has not expired yet.");

        // Return all funds (reward + intentor's collateral) to the intentor
        payable(intent.intentor).transfer(intent.reward.add(intent.intentorCollateral));
        intent.status = IntentStatus.Expired;

        emit IntentExpired(_intentId, msg.sender);
    }

    // --- II. Reputation & Collateral Management ---

    /// @notice Users can pre-deposit ETH into their internal collateral balance, which can be used for future intents or claims.
    function depositCollateral() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Collateral: Deposit amount must be greater than zero.");
        _userCollateralBalances[msg.sender] = _userCollateralBalances[msg.sender].add(msg.value);
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /// @notice Users can withdraw their available collateral balance.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawCollateral(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Collateral: Withdraw amount must be greater than zero.");
        require(_userCollateralBalances[msg.sender] >= _amount, "Collateral: Insufficient collateral balance.");

        _userCollateralBalances[msg.sender] = _userCollateralBalances[msg.sender].sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit CollateralWithdrawn(msg.sender, _amount);
    }

    /// @notice View function to retrieve the current reputation score of any address.
    /// @param _user The address to query.
    /// @return The reputation score. New users get a default score of 100.
    function getUserReputation(address _user) external view returns (uint256) {
        if (_userReputation[_user] == 0 && _user != address(0)) {
            return 100; // Default reputation for new users
        }
        return _userReputation[_user];
    }

    // --- III. Dispute Resolution System ---

    /// @notice Allows any *third-party* user to dispute a submitted fulfillment, staking a challenge fee.
    /// This moves the intent into a 'Challenged' status and starts a voting period.
    /// @param _intentId The ID of the intent to challenge.
    /// @param _reasonHash IPFS hash or similar reference for the reason of the challenge (off-chain).
    function challengeFulfillment(uint256 _intentId, string calldata _reasonHash) external payable nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Challenge: Intent does not exist.");
        require(intent.status == IntentStatus.Fulfilled, "Challenge: Intent is not in fulfilled status (awaiting verification).");
        require(msg.sender != intent.fulfiller, "Challenge: Fulfiller cannot challenge their own fulfillment.");
        require(msg.sender != intent.intentor, "Challenge: Intentor cannot directly challenge; use verifyFulfillment or let others challenge.");
        require(msg.value >= protocolParams.challengeFee, "Challenge: Insufficient challenge fee.");
        require(challenges[_intentId].intentId == 0, "Challenge: An active challenge already exists for this intent."); // Ensure only one challenge per intent
        require(bytes(_reasonHash).length > 0, "Challenge: Reason hash cannot be empty.");

        Challenge storage newChallenge = challenges[_intentId];
        newChallenge.intentId = _intentId;
        newChallenge.challenger = msg.sender;
        newChallenge.challengeFee = protocolParams.challengeFee;
        newChallenge.reasonHash = _reasonHash;
        newChallenge.voteStartTime = block.timestamp;
        newChallenge.isResolved = false;

        intent.status = IntentStatus.Challenged;
        
        // Protocol keeps a portion of the challenge fee, the rest can be distributed in resolveChallenge
        totalProtocolFees = totalProtocolFees.add(
            protocolParams.challengeFee.mul(10000 - protocolParams.disputeResolveRewardRatio).div(10000)
        );

        // Refund any excess ETH sent
        if (msg.value > protocolParams.challengeFee) {
            payable(msg.sender).transfer(msg.value.sub(protocolParams.challengeFee));
        }

        emit ChallengeInitiated(_intentId, msg.sender, protocolParams.challengeFee);
    }

    /// @notice Allows a whitelisted juror to cast a vote on a challenge.
    /// @param _intentId The ID of the intent being challenged.
    /// @param _supportsFulfiller True if the voter believes the fulfiller completed the intent correctly, false otherwise.
    function voteOnChallenge(uint256 _intentId, bool _supportsFulfiller) external whenNotPaused {
        Challenge storage challenge = challenges[_intentId];
        require(challenge.intentId == _intentId, "Vote: Challenge does not exist.");
        require(!challenge.isResolved, "Vote: Challenge has already been resolved.");
        require(block.timestamp <= challenge.voteStartTime.add(protocolParams.voteDuration), "Vote: Voting period has ended.");
        require(_isJuror[msg.sender], "Vote: Only whitelisted jurors can vote."); // Restrict voting to registered jurors
        require(!challenge.hasVoted[msg.sender], "Vote: You have already voted on this challenge.");

        challenge.hasVoted[msg.sender] = true;
        if (_supportsFulfiller) {
            challenge.votesForFulfiller = challenge.votesForFulfiller.add(1);
        } else {
            challenge.votesAgainstFulfiller = challenge.votesAgainstFulfiller.add(1);
        }

        emit ChallengeVoted(_intentId, msg.sender, _supportsFulfiller);
    }

    /// @notice Finalizes a challenge based on voting outcome or expiration, distributing collateral,
    /// updating reputations, and applying penalties/rewards.
    /// @param _intentId The ID of the intent whose challenge is to be resolved.
    function resolveChallenge(uint256 _intentId) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        Challenge storage challenge = challenges[_intentId];
        require(intent.id != 0, "Resolve: Intent does not exist.");
        require(intent.status == IntentStatus.Challenged, "Resolve: Intent is not in challenged status.");
        require(challenge.intentId == _intentId, "Resolve: Challenge does not exist.");
        require(!challenge.isResolved, "Resolve: Challenge has already been resolved.");
        
        bool canResolveByTime = block.timestamp > challenge.voteStartTime.add(protocolParams.voteDuration);
        bool canResolveByVotes = (challenge.votesForFulfiller.add(challenge.votesAgainstFulfiller) >= protocolParams.minVotesForResolution);
        
        require(canResolveByTime || canResolveByVotes, "Resolve: Challenge cannot be resolved yet (not enough votes or time).");

        address payable intentor = intent.intentor;
        address payable fulfiller = intent.fulfiller;
        address payable challenger = challenge.challenger;

        bool fulfillerWins;
        if (challenge.votesForFulfiller > challenge.votesAgainstFulfiller) {
            fulfillerWins = true;
        } else if (challenge.votesAgainstFulfiller > challenge.votesForFulfiller) {
            fulfillerWins = false;
        } else {
            // In case of a tie or no votes (but time passed), default to fulfiller winning to avoid stalemate.
            // This design choice encourages clear challenging.
            fulfillerWins = true;
        }

        uint256 disputeRewardAmount = challenge.challengeFee.mul(protocolParams.disputeResolveRewardRatio).div(10000);
        uint256 currentProtocolFeesAccrued = 0; // Fees accrued in this resolution

        if (fulfillerWins) {
            // Fulfiller wins: gets reward + own collateral + a portion of challenger's fee
            payable(fulfiller).transfer(intent.reward.add(intent.fulfillerCollateral).add(disputeRewardAmount));
            payable(intentor).transfer(intent.intentorCollateral); // Intentor gets back collateral
            
            _userReputation[fulfiller] = _userReputation[fulfiller].add(reputationParams.boostSuccess);
            _userReputation[challenger] = _userReputation[challenger].sub(reputationParams.penaltyInvalidChallenge); // Penalty for invalid challenge
        } else {
            // Challenger wins: Fulfiller loses reward and collateral. Challenger gets back a portion of their fee.
            // Intentor gets back collateral AND reward (as fulfillment was invalid).
            payable(intentor).transfer(intent.reward.add(intent.intentorCollateral));
            payable(challenger).transfer(disputeRewardAmount);

            // Fulfiller's reward and collateral are forfeited to the protocol fees.
            currentProtocolFeesAccrued = currentProtocolFeesAccrued.add(intent.reward.add(intent.fulfillerCollateral));

            _userReputation[fulfiller] = _userReputation[fulfiller].sub(reputationParams.penaltyFailure); // Penalty for failed fulfillment
            _userReputation[challenger] = _userReputation[challenger].add(reputationParams.boostValidChallenge); // Boost for valid challenge
        }

        intent.status = IntentStatus.Resolved;
        challenge.isResolved = true;
        challenge.resultSupportsFulfiller = fulfillerWins;
        totalProtocolFees = totalProtocolFees.add(currentProtocolFeesAccrued); // Add any newly accrued fees to total

        emit ChallengeResolved(_intentId, fulfillerWins, currentProtocolFeesAccrued);
        emit ReputationUpdated(fulfiller, _userReputation[fulfiller]);
        emit ReputationUpdated(challenger, _userReputation[challenger]);
    }
    
    /// @notice Allows the challenger to reclaim their fee if the challenge itself expires without sufficient votes.
    /// This prevents funds from being locked indefinitely in an unresolved challenge state.
    /// @param _intentId The ID of the intent whose challenge fee is to be reclaimed.
    function reclaimExpiredChallengeCollateral(uint256 _intentId) external nonReentrant whenNotPaused {
        Challenge storage challenge = challenges[_intentId];
        Intent storage intent = intents[_intentId];
        require(challenge.intentId == _intentId, "Reclaim: Challenge does not exist.");
        require(!challenge.isResolved, "Reclaim: Challenge has already been resolved.");
        require(challenge.challenger == msg.sender, "Reclaim: Only challenger can reclaim.");
        
        bool notEnoughVotes = challenge.votesForFulfiller.add(challenge.votesAgainstFulfiller) < protocolParams.minVotesForResolution;
        bool votingPeriodPassed = block.timestamp > challenge.voteStartTime.add(protocolParams.voteDuration);

        require(votingPeriodPassed && notEnoughVotes, "Reclaim: Challenge is still active or resolved.");

        // Return challenge fee to challenger
        payable(msg.sender).transfer(challenge.challengeFee);

        challenges[_intentId].isResolved = true; // Mark as resolved to prevent further actions
        intent.status = IntentStatus.Expired; // Consider intent expired if challenge fails to resolve by votes

        emit ChallengeResolved(_intentId, false, 0); // Emit a resolved event, indicating challenge failed to resolve, no protocol fees
    }


    // --- IV. Administrative & Configuration ---

    /// @notice Owner can pause core functionality of the contract (Pausable pattern).
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Owner can unpause core functionality.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Owner sets key protocol-wide parameters for collateral, fees, and dispute resolution.
    /// @param _minIntentCollateral Minimum ETH collateral required from the Intentor.
    /// @param _minFulfillerCollateral Minimum ETH collateral required from the Fulfiller.
    /// @param _challengeFee Fee to initiate a challenge.
    /// @param _voteDuration Duration in seconds for a challenge vote.
    /// @param _minVotesForResolution Minimum number of votes required to resolve a challenge early.
    /// @param _disputeResolveRewardRatio Percentage of challenge fee for successful party in a dispute (basis points).
    function setProtocolParameters(
        uint256 _minIntentCollateral,
        uint256 _minFulfillerCollateral,
        uint256 _challengeFee,
        uint256 _voteDuration,
        uint256 _minVotesForResolution,
        uint256 _disputeResolveRewardRatio
    ) external onlyOwner {
        require(_minIntentCollateral > 0, "Params: Min intent collateral must be > 0.");
        require(_minFulfillerCollateral > 0, "Params: Min fulfiller collateral must be > 0.");
        require(_challengeFee > 0, "Params: Challenge fee must be > 0.");
        require(_voteDuration > 0, "Params: Vote duration must be > 0.");
        require(_minVotesForResolution > 0, "Params: Min votes for resolution must be > 0.");
        require(_disputeResolveRewardRatio <= 10000, "Params: Reward ratio cannot exceed 100%."); // 10000 BP = 100%

        protocolParams = ProtocolParameters({
            minIntentCollateral: _minIntentCollateral,
            minFulfillerCollateral: _minFulfillerCollateral,
            challengeFee: _challengeFee,
            voteDuration: _voteDuration,
            minVotesForResolution: _minVotesForResolution,
            disputeResolveRewardRatio: _disputeResolveRewardRatio
        });
    }

    /// @notice Owner configures how reputation changes based on different outcomes.
    /// @param _boostSuccess Reputation points gained for successful fulfillment/verification.
    /// @param _penaltyFailure Reputation points lost for failed fulfillment/invalid challenge.
    /// @param _boostValidChallenge Reputation points gained for successful challenge.
    /// @param _penaltyInvalidChallenge Reputation points lost for unsuccessful challenge.
    function setReputationParameters(
        uint256 _boostSuccess,
        uint256 _penaltyFailure,
        uint256 _boostValidChallenge,
        uint256 _penaltyInvalidChallenge
    ) external onlyOwner {
        reputationParams = ReputationParameters({
            boostSuccess: _boostSuccess,
            penaltyFailure: _penaltyFailure,
            boostValidChallenge: _boostValidChallenge,
            penaltyInvalidChallenge: _penaltyInvalidChallenge
        });
    }

    /// @notice Owner sets parameters for how reputation influences collateral requirements (in basis points).
    /// @param _lowReputationThreshold Reputation score below which a higher multiplier is applied.
    /// @param _highReputationThreshold Reputation score above which a lower multiplier is applied.
    /// @param _lowReputationMultiplierBP Multiplier for low reputation users (e.g., 12000 for 1.2x).
    /// @param _highReputationMultiplierBP Multiplier for high reputation users (e.g., 8000 for 0.8x).
    function setDynamicCollateralAdjustment(
        uint256 _lowReputationThreshold,
        uint256 _highReputationThreshold,
        uint256 _lowReputationMultiplierBP,
        uint256 _highReputationMultiplierBP
    ) external onlyOwner {
        require(_lowReputationThreshold < _highReputationThreshold, "Collateral Adj: Low threshold must be less than high threshold.");
        require(_lowReputationMultiplierBP > 10000, "Collateral Adj: Low rep multiplier should be > 1x.");
        require(_highReputationMultiplierBP < 10000, "Collateral Adj: High rep multiplier should be < 1x.");

        collateralAdjustment = DynamicCollateralAdjustment({
            lowReputationThreshold: _lowReputationThreshold,
            highReputationThreshold: _highReputationThreshold,
            lowReputationMultiplierBP: _lowReputationMultiplierBP,
            highReputationMultiplierBP: _highReputationMultiplierBP,
            defaultMultiplierBP: 10000 // Fixed to 1x if reputation is between thresholds
        });
    }

    /// @notice Owner can add an address to the list of authorized jurors for dispute voting.
    /// @param _juror The address to add as a juror.
    function addJuror(address _juror) external onlyOwner {
        require(_juror != address(0), "Juror: Invalid address.");
        require(!_isJuror[_juror], "Juror: Address is already a juror.");
        _isJuror[_juror] = true;
    }

    /// @notice Owner can remove an address from the list of authorized jurors.
    /// @param _juror The address to remove from jurors.
    function removeJuror(address _juror) external onlyOwner {
        require(_isJuror[_juror], "Juror: Address is not a juror.");
        _isJuror[_juror] = false;
    }

    /// @notice Owner can withdraw accumulated protocol fees.
    /// @param _recipient The address to send the fees to.
    function withdrawProtocolFees(address _recipient) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Withdraw: Invalid recipient address.");
        uint256 fees = totalProtocolFees;
        totalProtocolFees = 0; // Reset fees
        payable(_recipient).transfer(fees);
        emit ProtocolFeesWithdrawn(_recipient, fees);
    }

    // --- V. View Functions ---

    /// @notice Retrieves all struct details for a specific intent.
    /// @param _intentId The ID of the intent.
    /// @return Intent struct data (tuple of all fields).
    function getIntentDetails(uint256 _intentId) external view returns (
        uint256 id,
        address intentor,
        address fulfiller,
        uint256 reward,
        uint256 intentorCollateral,
        uint256 fulfillerCollateral,
        uint256 fulfillByTimestamp,
        string memory descriptionHash,
        string memory fulfillmentProofHash,
        IntentStatus status,
        uint256 creationTimestamp
    ) {
        Intent storage i = intents[_intentId];
        return (
            i.id,
            i.intentor,
            i.fulfiller,
            i.reward,
            i.intentorCollateral,
            i.fulfillerCollateral,
            i.fulfillByTimestamp,
            i.descriptionHash,
            i.fulfillmentProofHash,
            i.status,
            i.creationTimestamp
        );
    }

    /// @notice Retrieves all struct details for a specific challenge.
    /// @param _intentId The ID of the intent associated with the challenge.
    /// @return Challenge struct data (tuple of relevant fields).
    function getChallengeDetails(uint256 _intentId) external view returns (
        uint256 intentId,
        address challenger,
        uint256 challengeFee,
        string memory reasonHash,
        uint256 voteStartTime,
        uint256 votesForFulfiller,
        uint256 votesAgainstFulfiller,
        bool isResolved,
        bool resultSupportsFulfiller
    ) {
        Challenge storage c = challenges[_intentId];
        return (
            c.intentId,
            c.challenger,
            c.challengeFee,
            c.reasonHash,
            c.voteStartTime,
            c.votesForFulfiller,
            c.votesAgainstFulfiller,
            c.isResolved,
            c.resultSupportsFulfiller
        );
    }

    /// @notice Retrieves all current global protocol parameters.
    /// @return ProtocolParameters struct data (tuple of all fields).
    function getProtocolParameters() external view returns (
        uint256 minIntentCollateral,
        uint256 minFulfillerCollateral,
        uint256 challengeFee,
        uint256 voteDuration,
        uint256 minVotesForResolution,
        uint256 disputeResolveRewardRatio
    ) {
        return (
            protocolParams.minIntentCollateral,
            protocolParams.minFulfillerCollateral,
            protocolParams.challengeFee,
            protocolParams.voteDuration,
            protocolParams.minVotesForResolution,
            protocolParams.disputeResolveRewardRatio
        );
    }

    /// @notice Fallback function to accept ETH if sent directly to contract.
    /// This ETH is treated as a collateral deposit for the sender.
    receive() external payable {
        depositCollateral();
    }
}
```