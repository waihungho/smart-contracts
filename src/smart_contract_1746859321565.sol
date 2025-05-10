Okay, here is a Solidity smart contract example incorporating several interconnected, slightly advanced concepts:

*   **Decentralized Verifiable Claims & Dynamic Reputation:** Users submit 'claims' (pieces of verifiable information/assertions about themselves or others). Other users (or a designated group) can verify these claims. Successful verification boosts a user's on-chain 'Affinity Score'.
*   **Time-Decaying Affinity:** The Affinity Score naturally decays over time, encouraging continuous participation and verification.
*   **Reputation-Based Resource Access:** Users with a high-enough Affinity Score can claim a portion of a resource pool (e.g., native currency like ETH) funded by others. Claiming resources *burns* some of their current Affinity.
*   **Dynamic Parameters:** Key parameters of the system (decay rate, points awarded, verification quorum, claim rates) can be adjusted by an administrator or via a decentralized governance mechanism (simplified as admin-only here).
*   **Internal Accounting:** Tracks claims, verifications, affinity scores, and resource pool dynamics.

This design is not a standard ERC-20/721, vault, or basic marketplace. It combines elements of identity, reputation, time-based mechanics, and resource distribution based on earned social/network capital.

---

## Smart Contract: Decentralized Affinity & Contribution Network (DACN)

**Description:**
This contract implements a Decentralized Affinity & Contribution Network (DACN). Users can submit verifiable claims about themselves or others. These claims can be verified by other participants. Successfully verified claims contribute to the 'Affinity Score' of the subject, submitter, and verifiers. Affinity scores decay over time. Users with sufficient Affinity can claim resources from a pool, which reduces their Affinity. The system parameters are adjustable.

**Outline:**

1.  **License and Pragma**
2.  **Imports** (Ownable, Pausable)
3.  **Events**
4.  **Structs** (Claim, Verification)
5.  **State Variables**
    *   Admin/Ownership
    *   Pausability state
    *   Counters (Claims, Verifications)
    *   Mappings for Claims, Verifications, User Data (Affinity, Last Update, Resource Claims)
    *   System Parameters (Decay Rate, Points per action, Quorum, Claim Rate, Fees)
    *   Fee Pool
6.  **Modifiers** (onlyAdmin, whenNotPaused, whenPaused)
7.  **Core Logic Functions**
    *   Claim Submission & Retrieval
    *   Claim Verification & Status
    *   Affinity Calculation (with decay)
    *   Affinity Updates (on actions)
    *   Resource Deposit & Claiming
    *   Admin Functions (Parameter Setting, Withdrawal)
    *   Helper/View Functions

**Function Summary:**

1.  `constructor()`: Initializes the contract with an admin address.
2.  `pauseContract()`: Pauses the contract (admin only).
3.  `unpauseContract()`: Unpauses the contract (admin only).
4.  `setAffinityDecayRate(uint64 _decayRate)`: Sets the global decay rate for affinity (admin only).
5.  `setPointsPerAction(uint256 _submitter, uint256 _subject, uint256 _verifier, uint256 _verifiedClaimBonus)`: Sets affinity points awarded for different actions (admin only).
6.  `setVerificationQuorum(uint16 _quorum)`: Sets the minimum number of 'true' verifications needed for a claim to be considered verified (admin only).
7.  `setClaimExpirationDuration(uint64 _duration)`: Sets the default validity duration for new claims (admin only).
8.  `setResourceClaimRate(uint256 _rateNumerator, uint256 _rateDenominator)`: Sets the rate at which affinity can be converted to resource claims (admin only). E.g., 1/10000 means 0.01% of affinity can be claimed per resource unit.
9.  `setResourceClaimAffinityThreshold(uint256 _threshold)`: Sets the minimum *calculated* affinity required to claim resources (admin only).
10. `setResourceDepositFeeRate(uint256 _rate)`: Sets the percentage fee on resource deposits (admin only).
11. `withdrawAdminFees(uint256 _amount)`: Allows admin to withdraw collected fees (admin only).
12. `submitClaim(address _subject, bytes32 _dataHash, uint256 _claimType, uint64 _expirationTimestamp)`: Allows a user to submit a new claim about a subject.
13. `verifyClaim(uint256 _claimId, bool _isTrue)`: Allows a user to verify an existing claim. Awards points and updates affinity if verification is successful and quorum is met.
14. `getClaim(uint256 _claimId)`: Retrieves details of a specific claim.
15. `getClaimVerificationStatus(uint256 _claimId)`: Gets the counts of true/false verifications for a claim.
16. `hasUserVerifiedClaim(uint256 _claimId, address _user)`: Checks if a user has already verified a specific claim.
17. `calculateCurrentAffinity(address _user)`: Pure/view function to calculate a user's current affinity score including decay.
18. `getUserRawAffinity(address _user)`: Retrieves the raw earned affinity points for a user before decay calculation.
19. `getUserLastAffinityUpdateTime(address _user)`: Retrieves the timestamp when a user's raw affinity was last updated/decay applied.
20. `depositResource() payable`: Allows anyone to deposit native currency into the resource pool. Applies an admin fee.
21. `getResourcePoolBalance()`: Retrieves the total balance in the resource pool available for claims.
22. `getAdminFeePoolBalance()`: Retrieves the current balance in the admin fee pool.
23. `claimResource(uint256 _claimAmount)`: Allows a user with sufficient *calculated* affinity to claim resources from the pool. Reduces their *raw* affinity proportionally.
24. `getTotalResourceClaimedByUser(address _user)`: Gets the total resources claimed by a user over time.
25. `getClaimCount()`: Gets the total number of claims submitted.
26. `getVerificationCount()`: Gets the total number of individual verifications performed.
27. `getClaimSubject(uint256 _claimId)`: Retrieves the subject address of a claim.
28. `getClaimSubmitter(uint256 _claimId)`: Retrieves the submitter address of a claim.
29. `isClaimVerified(uint256 _claimId)`: Checks if a claim has met the verification quorum with sufficient 'true' votes.
30. `getClaimExpirationTimestamp(uint256 _claimId)`: Retrieves the expiration timestamp of a claim.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Note: This is a complex example for demonstration.
// Production systems would require extensive audits, gas optimization,
// careful parameter tuning, and potentially more sophisticated
// randomness and oracle integrations for real-world claims/verification.

contract DecentralizedAffinityNetwork is Ownable, Pausable {

    // --- Events ---
    event ClaimSubmitted(uint256 indexed claimId, address indexed submitter, address indexed subject, bytes32 dataHash, uint256 claimType, uint64 expiresAt);
    event ClaimVerified(uint256 indexed claimId, address indexed verifier, bool isTrue, uint16 trueCount, uint16 falseCount);
    event ClaimFullyVerified(uint256 indexed claimId, address indexed subject, uint256 finalTrueCount, uint256 finalFalseCount);
    event AffinityUpdated(address indexed user, uint256 rawAffinity, uint256 calculatedAffinity);
    event ResourcesDeposited(address indexed depositor, uint256 amount, uint256 feeAmount);
    event ResourcesClaimed(address indexed user, uint256 resourceAmount, uint256 affinityBurned);
    event ParameterSet(string indexed parameterName, uint256 oldValue, uint256 newValue); // Generic event for param changes

    // --- Structs ---
    struct Claim {
        address submitter;
        address subject;
        bytes32 dataHash; // Hash of the claim data (e.g., IPFS hash, specific assertion)
        uint256 claimType; // Categorization of the claim
        uint64 submittedAt;
        uint64 expiresAt; // Timestamp after which claim verification is less relevant or points are reduced
        uint16 verifiedCountTrue;
        uint16 verifiedCountFalse;
        bool pointsAwarded; // Track if points have been awarded for this claim reaching quorum
    }

    // Verification struct is not strictly needed if we only track counts and who verified
    // struct Verification {
    //     address verifier;
    //     uint256 claimId;
    //     uint64 verifiedAt;
    //     bool isTrue;
    // }

    // --- State Variables ---

    // Core Data
    Claim[] public claims;
    mapping(uint256 => mapping(address => bool)) private hasUserVerifiedClaim; // claimId => user => verified? (prevents double verification)

    // Affinity & User State
    mapping(address => uint256) private rawAffinity; // Total earned affinity points
    mapping(address => uint64) private lastAffinityUpdateTimestamp; // Timestamp when decay was last applied
    mapping(address => uint256) private totalResourceClaimedByUser; // Total resources claimed by a user

    // Counters
    uint256 private claimCounter = 0;
    uint256 private verificationCounter = 0; // Count of individual verification actions

    // Resource Pool & Fees
    uint256 public adminFeePool;
    uint256 public resourcePoolBalance; // Redundant with address(this).balance but useful for clarity

    // Parameters (Admin Configurable)
    uint64 public affinityDecayRatePerSecond = 1; // Points decayed per second per point of affinity (e.g., 1e18 for 1 point/sec if using 18 decimals)
    uint256 public pointsPerSubmitterClaim = 10;
    uint256 public pointsPerSubjectClaim = 50; // Subject gets more points for a verified claim about them
    uint256 public pointsPerVerifier = 5;
    uint256 public pointsVerifiedClaimBonus = 100; // Bonus points awarded when a claim reaches quorum verified=true
    uint16 public verificationQuorum = 3; // Minimum 'true' verifications needed to trigger points/status
    uint64 public defaultClaimExpirationDuration = 365 days; // Default expiration for claims
    uint256 public resourceClaimRateNumerator = 1;   // E.g., 1e18 * 1
    uint256 public resourceClaimRateDenominator = 10000; // E.g., 1e18 * 10000 (means 0.01% of calculated affinity can be claimed in wei per affinity point)
    uint256 public resourceClaimAffinityThreshold = 1000; // Minimum calculated affinity to claim
    uint256 public resourceDepositFeeRate = 100; // Fee in basis points (1% = 100)

    // --- Modifiers ---
    // Inherits onlyAdmin from Ownable
    // Inherits whenNotPaused and whenPaused from Pausable

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        resourcePoolBalance = address(this).balance; // Should be 0 initially, but good practice
    }

    // --- Admin Functions ---

    function pauseContract() external onlyWithOwner {
        _pause();
    }

    function unpauseContract() external onlyWithOwner {
        _unpause();
    }

    function setAffinityDecayRate(uint64 _decayRate) external onlyWithOwner {
        emit ParameterSet("affinityDecayRatePerSecond", affinityDecayRatePerSecond, _decayRate);
        affinityDecayRatePerSecond = _decayRate;
    }

    function setPointsPerAction(uint256 _submitter, uint256 _subject, uint256 _verifier, uint256 _verifiedClaimBonus) external onlyWithOwner {
        // Emit specific events or a generic one
        emit ParameterSet("pointsPerSubmitterClaim", pointsPerSubmitterClaim, _submitter);
        emit ParameterSet("pointsPerSubjectClaim", pointsPerSubjectClaim, _subject);
        emit ParameterSet("pointsPerVerifier", pointsPerVerifier, _verifier);
        emit ParameterSet("pointsVerifiedClaimBonus", pointsVerifiedClaimBonus, _verifiedClaimBonus);

        pointsPerSubmitterClaim = _submitter;
        pointsPerSubjectClaim = _subject;
        pointsPerVerifier = _verifier;
        pointsVerifiedClaimBonus = _verifiedClaimBonus;
    }

    function setVerificationQuorum(uint16 _quorum) external onlyWithOwner {
        require(_quorum > 0, "Quorum must be positive");
        emit ParameterSet("verificationQuorum", verificationQuorum, _quorum);
        verificationQuorum = _quorum;
    }

    function setClaimExpirationDuration(uint64 _duration) external onlyWithOwner {
        emit ParameterSet("defaultClaimExpirationDuration", defaultClaimExpirationDuration, _duration);
        defaultClaimExpirationDuration = _duration;
    }

    function setResourceClaimRate(uint256 _rateNumerator, uint256 _rateDenominator) external onlyWithOwner {
         require(_rateDenominator > 0, "Denominator must be positive");
         emit ParameterSet("resourceClaimRateNumerator", resourceClaimRateNumerator, _rateNumerator);
         emit ParameterSet("resourceClaimRateDenominator", resourceClaimRateDenominator, _rateDenominator);
         resourceClaimRateNumerator = _rateNumerator;
         resourceClaimRateDenominator = _rateDenominator;
    }

    function setResourceClaimAffinityThreshold(uint256 _threshold) external onlyWithOwner {
        emit ParameterSet("resourceClaimAffinityThreshold", resourceClaimAffinityThreshold, _threshold);
        resourceClaimAffinityThreshold = _threshold;
    }

    function setResourceDepositFeeRate(uint256 _rate) external onlyWithOwner {
        require(_rate <= 10000, "Fee rate cannot exceed 100%");
        emit ParameterSet("resourceDepositFeeRate", resourceDepositFeeRate, _rate);
        resourceDepositFeeRate = _rate;
    }

    function withdrawAdminFees(uint256 _amount) external onlyWithOwner {
        require(_amount > 0 && _amount <= adminFeePool, "Invalid withdrawal amount");
        adminFeePool -= _amount;
        (bool success,) = payable(owner()).call{value: _amount}("");
        require(success, "Fee withdrawal failed");
    }

    // --- Core Logic Functions ---

    function submitClaim(address _subject, bytes32 _dataHash, uint256 _claimType, uint64 _expirationTimestamp)
        external
        whenNotPaused
        returns (uint256 claimId)
    {
        claimId = claimCounter++;
        claims.push(Claim({
            submitter: msg.sender,
            subject: _subject,
            dataHash: _dataHash,
            claimType: _claimType,
            submittedAt: uint64(block.timestamp),
            expiresAt: _expirationTimestamp == 0 ? uint64(block.timestamp + defaultClaimExpirationDuration) : _expirationTimestamp,
            verifiedCountTrue: 0,
            verifiedCountFalse: 0,
            pointsAwarded: false
        }));

        emit ClaimSubmitted(claimId, msg.sender, _subject, _dataHash, _claimType, claims[claimId].expiresAt);
    }

    function verifyClaim(uint256 _claimId, bool _isTrue)
        external
        whenNotPaused
    {
        require(_claimId < claims.length, "Invalid claim ID");
        Claim storage claim = claims[_claimId];
        require(block.timestamp <= claim.expiresAt, "Claim has expired");
        require(!hasUserVerifiedClaim[_claimId][msg.sender], "User already verified this claim");
        require(msg.sender != claim.submitter, "Submitter cannot verify their own claim");
        require(msg.sender != claim.subject || ! _isTrue, "Subject cannot cast positive verification on their own claim"); // Added rule

        hasUserVerifiedClaim[_claimId][msg.sender] = true;
        verificationCounter++;

        if (_isTrue) {
            claim.verifiedCountTrue++;
        } else {
            claim.verifiedCountFalse++;
        }

        emit ClaimVerified(_claimId, msg.sender, _isTrue, claim.verifiedCountTrue, claim.verifiedCountFalse);

        // Award points if quorum is reached and points haven't been awarded yet
        if (!claim.pointsAwarded && claim.verifiedCountTrue >= verificationQuorum) {
            claim.pointsAwarded = true;

            // Award points to subject (most points)
            _updateAffinity(claim.subject, pointsPerSubjectClaim + pointsVerifiedClaimBonus);
            // Award points to submitter
            _updateAffinity(claim.submitter, pointsPerSubmitterClaim);
            // Award points to the *current* verifier who pushed it over the quorum
             _updateAffinity(msg.sender, pointsPerVerifier); // Consider awarding points to ALL true verifiers? More complex to track. Sticking to the one who reaches quorum for simplicity.

            emit ClaimFullyVerified(_claimId, claim.subject, claim.verifiedCountTrue, claim.verifiedCountFalse);
        } else if (_isTrue) {
             // Award points to verifier even if quorum isn't met yet
            _updateAffinity(msg.sender, pointsPerVerifier);
        }
         // No points for false verifications? Or small negative? Added small negative for false
        else if (!_isTrue) {
             _updateAffinity(msg.sender, pointsPerVerifier / 5, true); // Deduct small points for 'false' votes
        }
    }

     // Internal helper to update affinity applying decay
    function _updateAffinity(address _user, uint256 _points, bool _deduct) internal {
        uint256 currentCalculatedAffinity = calculateCurrentAffinity(_user); // Apply decay up to now
        uint256 decayedRawAffinity = rawAffinity[_user]; // This is the raw score after applying decay implicitly in calculateCurrentAffinity

        if (_deduct) {
             // Only deduct from raw affinity if it doesn't go below 0
             decayedRawAffinity = decayedRawAffinity > _points ? decayedRawAffinity - _points : 0;
        } else {
             decayedRawAffinity += _points;
        }

        rawAffinity[_user] = decayedRawAffinity;
        lastAffinityUpdateTimestamp[_user] = uint64(block.timestamp); // Reset decay timer

        emit AffinityUpdated(_user, rawAffinity[_user], calculateCurrentAffinity(_user));
    }


    function calculateCurrentAffinity(address _user) public view returns (uint256) {
        uint256 currentRaw = rawAffinity[_user];
        uint64 lastUpdate = lastAffinityUpdateTimestamp[_user];
        uint64 timeElapsed = block.timestamp - lastUpdate;

        // Prevent overflow if decay rate is very large or time elapsed is huge
        uint256 decayAmount = 0;
        if (affinityDecayRatePerSecond > 0 && timeElapsed > 0) {
             // Simple linear decay based on time and current raw value
             // A more complex decay (e.g., exponential) would be harder/more expensive on-chain.
             // Linear decay: decay = time * rate
             // Let's make it slightly more sophisticated: Decay is percentage based or fixed points/sec.
             // Let's stick to fixed points/sec for simplicity:
             decayAmount = uint256(timeElapsed) * affinityDecayRatePerSecond;

             // Alternative: Percentage decay per time period (e.g., per day)
             // uint256 decayRatePerDay = 100; // e.g. 1%
             // uint256 daysElapsed = timeElapsed / 1 days;
             // uint256 decayed = currentRaw;
             // for (uint256 i = 0; i < daysElapsed; i++) {
             //     decayed = decayed * (10000 - decayRatePerDay) / 10000; // 10000 basis points
             // }
             // decayAmount = currentRaw - decayed;
        }


        // Apply decay, ensuring it doesn't go below zero
        uint256 currentCalculated = currentRaw > decayAmount ? currentRaw - decayAmount : 0;

        return currentCalculated;
    }


    function depositResource() external payable whenNotPaused {
        require(msg.value > 0, "Must deposit a positive amount");

        uint256 feeAmount = (msg.value * resourceDepositFeeRate) / 10000; // Basis points calculation
        uint256 depositAmount = msg.value - feeAmount;

        adminFeePool += feeAmount;
        resourcePoolBalance += depositAmount; // Update internal tracker
        // The actual Ether is added to address(this).balance automatically

        emit ResourcesDeposited(msg.sender, depositAmount, feeAmount);
    }

    function claimResource(uint256 _claimAmount) external whenNotPaused {
        require(_claimAmount > 0, "Must claim a positive amount");

        uint256 userCurrentAffinity = calculateCurrentAffinity(msg.sender);
        require(userCurrentAffinity >= resourceClaimAffinityThreshold, "Affinity below threshold");
        require(_claimAmount <= resourcePoolBalance, "Claim amount exceeds pool balance");

        // Determine how much affinity must be burned for this claim amount
        // Based on resourceClaimRate: _claimAmount resources = X affinity
        // X / _claimAmount = resourceClaimRateDenominator / resourceClaimRateNumerator
        // X = _claimAmount * resourceClaimRateDenominator / resourceClaimRateNumerator
        uint256 affinityToBurn = (_claimAmount * resourceClaimRateDenominator) / resourceClaimRateNumerator;

        require(userCurrentAffinity >= affinityToBurn, "Insufficient current affinity to cover burn cost");

        // Update user's raw affinity by applying decay *first*, then burning
        _updateAffinity(msg.sender, affinityToBurn, true); // Deduct affinity

        // Transfer resources
        resourcePoolBalance -= _claimAmount;
        totalResourceClaimedByUser[msg.sender] += _claimAmount;

        (bool success,) = payable(msg.sender).call{value: _claimAmount}("");
        require(success, "Resource claim transfer failed");

        emit ResourcesClaimed(msg.sender, _claimAmount, affinityToBurn);
    }


    // --- View Functions ---

    function getClaim(uint256 _claimId)
        public view
        returns (
            address submitter,
            address subject,
            bytes32 dataHash,
            uint256 claimType,
            uint64 submittedAt,
            uint64 expiresAt,
            uint16 verifiedCountTrue,
            uint16 verifiedCountFalse,
            bool pointsAwarded
        )
    {
        require(_claimId < claims.length, "Invalid claim ID");
        Claim storage claim = claims[_claimId];
        return (
            claim.submitter,
            claim.subject,
            claim.dataHash,
            claim.claimType,
            claim.submittedAt,
            claim.expiresAt,
            claim.verifiedCountTrue,
            claim.verifiedCountFalse,
            claim.pointsAwarded
        );
    }

    function getClaimVerificationStatus(uint256 _claimId) public view returns (uint16 trueCount, uint16 falseCount) {
         require(_claimId < claims.length, "Invalid claim ID");
         Claim storage claim = claims[_claimId];
         return (claim.verifiedCountTrue, claim.verifiedCountFalse);
    }

    function hasUserVerifiedClaim(uint256 _claimId, address _user) public view returns (bool) {
        require(_claimId < claims.length, "Invalid claim ID");
        return hasUserVerifiedClaim[_claimId][_user];
    }

    function getUserRawAffinity(address _user) public view returns (uint256) {
        return rawAffinity[_user];
    }

    function getUserLastAffinityUpdateTime(address _user) public view returns (uint64) {
        return lastAffinityUpdateTimestamp[_user];
    }

    function getResourcePoolBalance() public view returns (uint256) {
         // While address(this).balance is the true source,
         // this tracks the *claimable* amount after fees.
         return resourcePoolBalance;
    }

    function getAdminFeePoolBalance() public view returns (uint256) {
        return adminFeePool;
    }

    function getTotalResourceClaimedByUser(address _user) public view returns (uint256) {
        return totalResourceClaimedByUser[_user];
    }

    function getClaimCount() public view returns (uint256) {
        return claimCounter;
    }

    function getVerificationCount() public view returns (uint256) {
        return verificationCounter;
    }

     function getClaimSubject(uint256 _claimId) public view returns (address) {
        require(_claimId < claims.length, "Invalid claim ID");
        return claims[_claimId].subject;
    }

    function getClaimSubmitter(uint256 _claimId) public view returns (address) {
        require(_claimId < claims.length, "Invalid claim ID");
        return claims[_claimId].submitter;
    }

    function isClaimVerified(uint256 _claimId) public view returns (bool) {
        require(_claimId < claims.length, "Invalid claim ID");
        return claims[_claimId].pointsAwarded; // PointsAwarded indicates quorum met
    }

    function getClaimExpirationTimestamp(uint256 _claimId) public view returns (uint64) {
        require(_claimId < claims.length, "Invalid claim ID");
        return claims[_claimId].expiresAt;
    }
}
```