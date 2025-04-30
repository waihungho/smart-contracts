Okay, here is a Solidity smart contract called `QuantumNexus`. This contract implements a decentralized system for managing verifiable claims about entities, incorporating a reputation system, a staking mechanism for disputes, and dynamic parameters.

It attempts to combine concepts like:
*   **Verifiable Claims:** Users assert facts about entities with associated proofs.
*   **Decentralized Reputation:** Scores derived from successfully defended claims and challenges.
*   **Dispute Mechanism:** Staking an internal token to challenge or support claims.
*   **Dynamic Configuration:** Owner can adjust parameters influencing claim validity and staking rewards.
*   **Time-Based Logic:** Claims/challenges have periods.

This is a complex system and represents a significant amount of logic beyond simple token transfers or basic interactions, aiming for creativity without duplicating common patterns like full ERC standards, standard DeFi strategies, or typical DAO governance models.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- QuantumNexus Smart Contract ---
// A decentralized system for managing verifiable claims about entities,
// incorporating a reputation system, a staking/dispute mechanism,
// and dynamic parameters.

// --- Outline ---
// 1. State Variables & Data Structures
// 2. Events
// 3. Modifiers
// 4. Access Control (Simple Owner)
// 5. Configuration & Parameter Management
// 6. Entity Registration & Management
// 7. User Registration & Management (implicitly via interactions, explicit alias optional)
// 8. Nexus Point (Internal Token) Management
// 9. Claim Submission & Management
// 10. Claim Dispute (Challenge & Support)
// 11. Claim Resolution (Owner-driven for simplicity, could be Oracle/DAO)
// 12. Staking Rewards & Slashing
// 13. Reputation Calculation & Retrieval
// 14. View/Helper Functions

// --- Function Summary ---
// Configuration:
// 1.  setClaimChallengePeriod(uint256 _duration): Sets the time window for challenges.
// 2.  setClaimResolutionPeriod(uint256 _duration): Sets the time window for resolving challenges.
// 3.  setMinimumStakeAmount(uint256 _amount): Sets the minimum points required to stake on disputes.
// 4.  setReputationDecayRate(uint256 _rate): Sets a simulated decay rate for reputation (applied on calculation).
// 5.  setClaimWeight(bytes32 _claimTypeHash, uint256 _weight): Assigns a weight multiplier to a claim type for reputation.

// Entity Management:
// 6.  registerClaimableEntity(address _entityAddress, string memory _name): Registers an address as a claimable entity.
// 7.  updateClaimableEntityName(address _entityAddress, string memory _newName): Updates an entity's name.
// 8.  deactivateClaimableEntity(address _entityAddress): Deactivates an entity, preventing new claims.
// 9.  isEntityClaimable(address _entityAddress): Checks if an address is an active claimable entity. (View)

// User Management: (Implicit registration on first interaction, alias optional)
// 10. registerUser(string memory _alias): Registers the calling address with an alias.

// Nexus Point (Internal Token):
// 11. mintNexusPoints(address _user, uint256 _amount): Mints Nexus Points to a user (Owner only).
// 12. balanceOfNexusPoints(address _user): Gets the Nexus Point balance of a user. (View)

// Claim System:
// 13. submitClaim(address _subjectEntity, bytes32 _claimTypeHash, bytes32 _proofHash, string memory _proofURI): Submits a new claim about an entity.
// 14. revokeClaim(bytes32 _claimId): Revokes a claim submitted by the caller.
// 15. getClaimDetails(bytes32 _claimId): Gets details of a specific claim. (View)
// 16. getEntityClaims(address _entityAddress): Gets a list of claim IDs about an entity. (View)
// 17. getUserSubmittedClaims(address _userAddress): Gets a list of claim IDs submitted by a user. (View)

// Dispute System:
// 18. challengeClaim(bytes32 _claimId, bytes32 _reasonHash, string memory _reasonURI, uint256 _stakeAmount): Challenges a claim, staking Nexus Points.
// 19. supportClaim(bytes32 _claimId, uint256 _stakeAmount): Supports a claim, staking Nexus Points.
// 20. submitDisputeEvidence(bytes32 _disputeId, bytes32 _evidenceHash, string memory _evidenceURI): Submits evidence for a challenge or support stake.
// 21. getClaimChallenges(bytes32 _claimId): Gets a list of challenge IDs for a claim. (View)
// 22. getClaimSupports(bytes32 _claimId): Gets a list of support IDs for a claim. (View)
// 23. getDisputeEvidence(bytes32 _disputeId): Gets evidence submitted for a specific dispute stake. (View)

// Resolution & Rewards:
// 24. resolveClaimChallenge(bytes32 _claimId, bool _isClaimValid): Owner resolves a challenged claim, triggering staking rewards/slashing.
// 25. claimStakingRewards(bytes32 _disputeId): Allows a user to claim their share of staked points after resolution.

// Reputation System:
// 26. getReputationScore(address _userAddress): Gets the current reputation score of a user. (View)
// 27. getClaimTrustScore(bytes32 _claimId): Calculates a dynamic trust score for a claim based on support/challenge stakes. (View)

// Utility:
// 28. hashClaimType(string memory _typeName): Helper to get hash of a claim type string. (Pure)
// 29. hashChallengeReason(string memory _reason): Helper to get hash of a challenge reason string. (Pure)
// 30. getClaimStatus(bytes32 _claimId): Gets the current status of a claim. (View)

contract QuantumNexus {

    // --- 1. State Variables & Data Structures ---

    address public owner;

    // Internal token for staking
    mapping(address => uint256) private _nexusPoints;

    // Unique IDs for Claims, Challenges, Supports, Evidence
    uint256 private _nextClaimId = 1;
    uint256 private _nextDisputeId = 1; // Used for both Challenges and Supports
    uint256 private _nextEvidenceId = 1;

    enum ClaimStatus {
        Pending,       // Newly submitted, within challenge period
        Challenged,    // Under dispute
        ResolvedValid, // Challenge period passed or resolved as valid
        ResolvedInvalid, // Resolved as invalid
        Revoked        // Submitter revoked
    }

    enum DisputeStatus {
        Active,     // Challenge/Support is active
        Won,        // Staker was on the winning side of resolution
        Lost,       // Staker was on the losing side of resolution
        Withdrawn   // Staker withdrew rewards after resolution
    }

    struct Entity {
        string name;
        bool isActive;
        bytes32[] claimIds; // Claims about this entity
    }
    mapping(address => Entity) public claimableEntities;
    mapping(address => bool) public isEntityClaimableBool; // Helper for quicker check

    struct UserProfile {
        string alias;
        bytes32[] submittedClaimIds;
        mapping(bytes32 => bytes32[]) disputeIds; // Mapping claimId -> list of disputeIds (challenge or support) by this user
        int256 reputationScore; // Can be positive or negative
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => bool) public isUserRegisteredBool; // Helper

    struct Claim {
        bytes32 claimId;
        address subjectEntity;
        address submitter;
        bytes32 claimTypeHash;
        bytes32 proofHash;
        string proofURI;
        uint256 submittedTimestamp;
        ClaimStatus status;
        bytes32[] challengeDisputeIds; // disputeIds for challenges
        bytes32[] supportDisputeIds;   // disputeIds for supports
    }
    mapping(bytes32 => Claim) public claims;

    struct DisputeStake { // Used for both Challenges and Supports
        bytes32 disputeId;
        bytes32 claimId;
        address staker;
        uint256 amountStaked;
        bool isChallenge; // true for challenge, false for support
        bytes32 reasonOrSupportHash; // hash of reason (challenge) or general support hash (support)
        string reasonOrSupportURI;   // URI for reason (challenge) or support (support)
        uint256 stakedTimestamp;
        DisputeStatus status;
        bytes32[] evidenceIds; // Evidence submitted for this specific stake
    }
    mapping(bytes32 => DisputeStake) public disputeStakes;

    struct Evidence {
        bytes32 evidenceId;
        bytes32 disputeId; // Link back to the challenge or support stake
        address submitter;
        bytes32 evidenceHash;
        string evidenceURI;
        uint256 submittedTimestamp;
    }
    mapping(bytes32 => Evidence) public evidenceSubmissions;

    // Configuration Parameters
    uint256 public claimChallengePeriod = 3 days; // Time for claims to be challenged
    uint256 public claimResolutionPeriod = 7 days; // Time for owner to resolve challenged claims
    uint256 public minimumStakeAmount = 1e18; // 1 Nexus Point (assuming 18 decimals)
    uint256 public reputationDecayRate = 1; // Simulated decay factor (e.g., decrease score by X per time unit or on interaction) - simplified
    mapping(bytes32 => uint256) public claimTypeWeights; // Weight for each claim type in reputation calculation

    // --- 2. Events ---

    event EntityRegistered(address indexed entity, string name);
    event EntityDeactivated(address indexed entity);
    event UserRegistered(address indexed user, string alias);
    event NexusPointsMinted(address indexed user, uint256 amount);
    event ClaimSubmitted(bytes32 indexed claimId, address indexed subjectEntity, address indexed submitter, bytes32 claimTypeHash, uint256 timestamp);
    event ClaimRevoked(bytes32 indexed claimId, address indexed revoker);
    event ClaimChallenged(bytes32 indexed claimId, bytes32 indexed disputeId, address indexed staker, uint256 stakeAmount);
    event ClaimSupported(bytes32 indexed claimId, bytes32 indexed disputeId, address indexed staker, uint256 stakeAmount);
    event DisputeEvidenceSubmitted(bytes32 indexed disputeId, bytes32 indexed evidenceId, address indexed submitter);
    event ClaimResolved(bytes32 indexed claimId, bool isClaimValid);
    event ReputationUpdated(address indexed user, int256 newReputation);
    event StakingRewardsClaimed(bytes32 indexed disputeId, address indexed staker, uint256 amount);
    event ParametersUpdated(string paramName, uint256 value);

    // --- 3. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredEntity(address _entity) {
        require(isEntityClaimableBool[_entity] && claimableEntities[_entity].isActive, "Entity not registered or inactive");
        _;
    }

    modifier onlyRegisteredUser() {
        // Implicitly register user on first interaction if needed, or just check if they exist
        // For this simple version, we'll allow anyone to submit claims/disputes but track profiles
        // A dedicated `registerUser` allows setting an alias.
        _registerUserIfNotExist(msg.sender);
        _;
    }

    modifier onlyClaimPendingOrChallenged(bytes32 _claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.submittedTimestamp != 0, "Claim does not exist"); // Check if claim exists
        require(claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Challenged, "Claim is not pending or challenged");
        _;
    }

    modifier onlyClaimResolved(bytes32 _claimId) {
         Claim storage claim = claims[_claimId];
        require(claim.submittedTimestamp != 0, "Claim does not exist"); // Check if claim exists
        require(claim.status == ClaimStatus.ResolvedValid || claim.status == ClaimStatus.ResolvedInvalid, "Claim is not resolved");
        _;
    }

    // --- 4. Access Control ---

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        owner = _newOwner;
    }

    // --- 5. Configuration & Parameter Management ---

    function setClaimChallengePeriod(uint256 _duration) external onlyOwner {
        claimChallengePeriod = _duration;
        emit ParametersUpdated("claimChallengePeriod", _duration);
    }

    function setClaimResolutionPeriod(uint256 _duration) external onlyOwner {
        claimResolutionPeriod = _duration;
        emit ParametersUpdated("claimResolutionPeriod", _duration);
    }

    function setMinimumStakeAmount(uint256 _amount) external onlyOwner {
        minimumStakeAmount = _amount;
        emit ParametersUpdated("minimumStakeAmount", _amount);
    }

    function setReputationDecayRate(uint256 _rate) external onlyOwner {
        // Note: This rate is used in calculation. A true decay would require
        // time-based updates, possibly off-chain or on interaction.
        // Here it just influences how much impact a resolved claim has based on age.
        reputationDecayRate = _rate; // Example: 1 means no age penalty, higher means faster penalty
        emit ParametersUpdated("reputationDecayRate", _rate);
    }

    function setClaimWeight(bytes32 _claimTypeHash, uint256 _weight) external onlyOwner {
        claimTypeWeights[_claimTypeHash] = _weight;
        // No specific event for weights, can emit generic param update if needed
    }

    // --- 6. Entity Registration & Management ---

    function registerClaimableEntity(address _entityAddress, string memory _name) external onlyOwner {
        require(_entityAddress != address(0), "Entity address cannot be zero");
        require(!isEntityClaimableBool[_entityAddress], "Entity already registered");

        claimableEntities[_entityAddress] = Entity(_name, true, new bytes32[](0));
        isEntityClaimableBool[_entityAddress] = true;
        emit EntityRegistered(_entityAddress, _name);
    }

    function updateClaimableEntityName(address _entityAddress, string memory _newName) external onlyOwner onlyRegisteredEntity(_entityAddress) {
        claimableEntities[_entityAddress].name = _newName;
        // No specific event for name update
    }

    function deactivateClaimableEntity(address _entityAddress) external onlyOwner onlyRegisteredEntity(_entityAddress) {
        require(claimableEntities[_entityAddress].isActive, "Entity already inactive");
        claimableEntities[_entityAddress].isActive = false;
        emit EntityDeactivated(_entityAddress);
    }

    // --- 7. User Management ---

    function _registerUserIfNotExist(address _user) internal {
        if (!isUserRegisteredBool[_user]) {
            userProfiles[_user] = UserProfile("", new bytes32[](0), new bytes32[](0), 0); // Initialize user profile
            isUserRegisteredBool[_user] = true;
            // No alias set initially
        }
    }

    function registerUser(string memory _alias) external onlyRegisteredUser {
         // onlyRegisteredUser modifier calls _registerUserIfNotExist
        userProfiles[msg.sender].alias = _alias;
        emit UserRegistered(msg.sender, _alias);
    }

     // --- 8. Nexus Point (Internal Token) Management ---

    function mintNexusPoints(address _user, uint256 _amount) external onlyOwner {
        _registerUserIfNotExist(_user);
        _nexusPoints[_user] += _amount;
        emit NexusPointsMinted(_user, _amount);
    }

    function _burnNexusPoints(address _user, uint256 _amount) internal {
        require(_nexusPoints[_user] >= _amount, "Insufficient Nexus Points");
        _nexusPoints[_user] -= _amount;
        // No event for burning as it's internal to staking/slashing logic
    }

    function balanceOfNexusPoints(address _user) external view returns (uint256) {
        return _nexusPoints[_user];
    }

    // --- 9. Claim Submission & Management ---

    function submitClaim(
        address _subjectEntity,
        bytes32 _claimTypeHash,
        bytes32 _proofHash,
        string memory _proofURI
    ) external onlyRegisteredUser onlyRegisteredEntity(_subjectEntity) returns (bytes32) {
        bytes32 claimId = keccak256(abi.encodePacked(_nextClaimId, msg.sender, _subjectEntity, block.timestamp));
        _nextClaimId++;

        claims[claimId] = Claim(
            claimId,
            _subjectEntity,
            msg.sender,
            _claimTypeHash,
            _proofHash,
            _proofURI,
            block.timestamp,
            ClaimStatus.Pending,
            new bytes32[](0),
            new bytes32[](0)
        );

        claimableEntities[_subjectEntity].claimIds.push(claimId);
        userProfiles[msg.sender].submittedClaimIds.push(claimId);

        emit ClaimSubmitted(claimId, _subjectEntity, msg.sender, _claimTypeHash, block.timestamp);
        return claimId;
    }

    function revokeClaim(bytes32 _claimId) external onlyRegisteredUser {
        Claim storage claim = claims[_claimId];
        require(claim.submittedTimestamp != 0, "Claim does not exist");
        require(claim.submitter == msg.sender, "Only claim submitter can revoke");
        require(claim.status == ClaimStatus.Pending, "Claim cannot be revoked after challenge or resolution");

        claim.status = ClaimStatus.Revoked;
        // Note: Revoking a pending claim results in no reputation change and no staking penalty/reward.
        // If we allowed revoking challenged claims, it would require handling stakes. Keeping it simple here.

        emit ClaimRevoked(_claimId, msg.sender);
    }

    function getClaimDetails(bytes32 _claimId) external view returns (Claim memory) {
        require(claims[_claimId].submittedTimestamp != 0, "Claim does not exist");
        return claims[_claimId];
    }

    function getEntityClaims(address _entityAddress) external view onlyRegisteredEntity(_entityAddress) returns (bytes32[] memory) {
        return claimableEntities[_entityAddress].claimIds;
    }

    function getUserSubmittedClaims(address _userAddress) external view returns (bytes32[] memory) {
        require(isUserRegisteredBool[_userAddress], "User not registered");
        return userProfiles[_userAddress].submittedClaimIds;
    }

    // --- 10. Claim Dispute (Challenge & Support) ---

    function challengeClaim(
        bytes32 _claimId,
        bytes32 _reasonHash,
        string memory _reasonURI,
        uint256 _stakeAmount
    ) external onlyRegisteredUser onlyClaimPendingOrChallenged(_claimId) returns (bytes32) {
        Claim storage claim = claims[_claimId];
        require(msg.sender != claim.submitter, "Cannot challenge your own claim");
        require(_stakeAmount >= minimumStakeAmount, "Stake amount is below minimum");
        _burnNexusPoints(msg.sender, _stakeAmount); // Burn points from staker

        bytes32 disputeId = keccak256(abi.encodePacked(_nextDisputeId, msg.sender, _claimId, block.timestamp, true));
        _nextDisputeId++;

        disputeStakes[disputeId] = DisputeStake(
            disputeId,
            _claimId,
            msg.sender,
            _stakeAmount,
            true, // isChallenge
            _reasonHash,
            _reasonURI,
            block.timestamp,
            DisputeStatus.Active,
            new bytes32[](0)
        );

        claim.challengeDisputeIds.push(disputeId);
        userProfiles[msg.sender].disputeIds[_claimId].push(disputeId);

        if (claim.status == ClaimStatus.Pending && block.timestamp <= claim.submittedTimestamp + claimChallengePeriod) {
             // Claim is challenged within the challenge period
             claim.status = ClaimStatus.Challenged;
        } else if (claim.status == ClaimStatus.Pending && block.timestamp > claim.submittedTimestamp + claimChallengePeriod) {
             // If challenge period passed but not resolved yet, still allow challenge, status becomes Challenged.
             claim.status = ClaimStatus.Challenged;
        } else if (claim.status == ClaimStatus.Challenged) {
            // Already challenged, just add another challenge stake
        } else {
             revert("Claim is not in a state to be challenged"); // Should be caught by modifier, but belt-and-suspenders
        }


        emit ClaimChallenged(_claimId, disputeId, msg.sender, _stakeAmount);
        return disputeId;
    }

    function supportClaim(bytes32 _claimId, uint256 _stakeAmount)
        external
        onlyRegisteredUser
        onlyClaimPendingOrChallenged(_claimId)
        returns (bytes32)
    {
        Claim storage claim = claims[_claimId];
        require(msg.sender != claim.submitter, "Cannot support your own claim with stakes"); // Prevent self-support for staking game
        require(_stakeAmount >= minimumStakeAmount, "Stake amount is below minimum");
        _burnNexusPoints(msg.sender, _stakeAmount); // Burn points from staker

        bytes32 disputeId = keccak256(abi.encodePacked(_nextDisputeId, msg.sender, _claimId, block.timestamp, false));
        _nextDisputeId++;

        disputeStakes[disputeId] = DisputeStake(
            disputeId,
            _claimId,
            msg.sender,
            _stakeAmount,
            false, // isChallenge
            bytes32(0), // No specific reason hash for support
            "",         // No specific reason URI for support
            block.timestamp,
            DisputeStatus.Active,
            new bytes32[](0)
        );

        claim.supportDisputeIds.push(disputeId);
        userProfiles[msg.sender].disputeIds[_claimId].push(disputeId);

        // Status remains Pending or Challenged, adding support doesn't change state

        emit ClaimSupported(_claimId, disputeId, msg.sender, _stakeAmount);
        return disputeId;
    }

    function submitDisputeEvidence(bytes32 _disputeId, bytes32 _evidenceHash, string memory _evidenceURI)
        external
        onlyRegisteredUser
    {
        DisputeStake storage dispute = disputeStakes[_disputeId];
        require(dispute.stakedTimestamp != 0, "Dispute stake does not exist");
        require(dispute.staker == msg.sender, "Only the staker can submit evidence for their stake");
        require(dispute.status == DisputeStatus.Active, "Evidence can only be submitted for active disputes");

        bytes32 evidenceId = keccak256(abi.encodePacked(_nextEvidenceId, msg.sender, _disputeId, block.timestamp));
        _nextEvidenceId++;

        evidenceSubmissions[evidenceId] = Evidence(
            evidenceId,
            _disputeId,
            msg.sender,
            _evidenceHash,
            _evidenceURI,
            block.timestamp
        );

        dispute.evidenceIds.push(evidenceId);

        emit DisputeEvidenceSubmitted(_disputeId, evidenceId, msg.sender);
    }

     function getClaimChallenges(bytes32 _claimId) external view returns (bytes32[] memory) {
        require(claims[_claimId].submittedTimestamp != 0, "Claim does not exist");
        return claims[_claimId].challengeDisputeIds;
    }

    function getClaimSupports(bytes32 _claimId) external view returns (bytes32[] memory) {
        require(claims[_claimId].submittedTimestamp != 0, "Claim does not exist");
        return claims[_claimId].supportDisputeIds;
    }

     function getDisputeEvidence(bytes32 _disputeId) external view returns (bytes32[] memory) {
        require(disputeStakes[_disputeId].stakedTimestamp != 0, "Dispute stake does not exist");
        return disputeStakes[_disputeId].evidenceIds;
    }


    // --- 11. Claim Resolution ---
    // NOTE: This uses Owner-based resolution for simplicity. In a truly decentralized system,
    // this would involve an oracle, Schelling point game, or DAO vote.

    function resolveClaimChallenge(bytes32 _claimId, bool _isClaimValid) external onlyOwner onlyClaimPendingOrChallenged(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Challenged || (claim.status == ClaimStatus.Pending && block.timestamp > claim.submittedTimestamp + claimChallengePeriod),
            "Claim not challenged or challenge period not over"); // Ensure it's past challenge period if pending or already challenged

        claim.status = _isClaimValid ? ClaimStatus.ResolvedValid : ClaimStatus.ResolvedInvalid;

        // Process stakers (winners get stake + loser stakes, losers lose stake)
        // Calculate total challenge stake and total support stake
        uint256 totalChallengeStake = 0;
        for (uint i = 0; i < claim.challengeDisputeIds.length; i++) {
            totalChallengeStake += disputeStakes[claim.challengeDisputeIds[i]].amountStaked;
        }

        uint256 totalSupportStake = 0;
        for (uint i = 0; i < claim.supportDisputeIds.length; i++) {
            totalSupportStake += disputeStakes[claim.supportDisputeIds[i]].amountStaked;
        }

        if (_isClaimValid) {
            // Supporters win, Challengers lose
            uint256 totalRewardPool = totalChallengeStake; // Loser stakes are distributed among winners
            if (totalSupportStake > 0) {
                 for (uint i = 0; i < claim.supportDisputeIds.length; i++) {
                    bytes32 disputeId = claim.supportDisputeIds[i];
                    DisputeStake storage dispute = disputeStakes[disputeId];
                    dispute.status = DisputeStatus.Won;
                    // Winner gets their original stake back + proportional share of loser stakes
                    // This is a simplified distribution. More complex could involve pro-rata based on stake size.
                    // Here, we just track status. The claim function handles the payout.
                    // To avoid complex division and potential dust, winners claim their *original* stake
                    // and the owner (as a simplified stand-in for a reward pool manager) receives the slashed funds initially.
                    // A more advanced version would distribute slashings pro-rata here.
                    // For simplicity, losers stakes go to owner for now, winners get their stake back.
                    // Let's refine: Winners get their stake back + (loser_stake * their_stake / total_winner_stake)
                    uint256 rewardShare = (totalChallengeStake * dispute.amountStaked) / totalSupportStake;
                    // Mint their stake back + reward share
                     _nexusPoints[dispute.staker] += dispute.amountStaked + rewardShare; // Mint reward to winner
                 }
            }
             // All challenger stakes are lost/burned
             for (uint i = 0; i < claim.challengeDisputeIds.length; i++) {
                 bytes32 disputeId = claim.challengeDisputeIds[i];
                 disputeStakes[disputeId].status = DisputeStatus.Lost;
                 // Points were already burned on staking. No refund.
             }
             // The claim submitter (if not a staker) also gets reputation boost if claim is valid and challenged.
             // Reputation updates happen in calculateReputationScore (view function) based on resolved claims.
             // Or, we can update reputation here... let's update reputation here for direct effect.
             userProfiles[claim.submitter].reputationScore += int256(getClaimWeight(claim.claimTypeHash) * 10); // Arbitrary reputation points
        } else { // Claim is Invalid
             // Challengers win, Supporters lose
             uint256 totalRewardPool = totalSupportStake; // Loser stakes are distributed among winners
              if (totalChallengeStake > 0) {
                 for (uint i = 0; i < claim.challengeDisputeIds.length; i++) {
                    bytes32 disputeId = claim.challengeDisputeIds[i];
                    DisputeStake storage dispute = disputeStakes[disputeId];
                    dispute.status = DisputeStatus.Won;
                     uint256 rewardShare = (totalSupportStake * dispute.amountStaked) / totalChallengeStake;
                     _nexusPoints[dispute.staker] += dispute.amountStaked + rewardShare; // Mint reward to winner
                 }
            }
             // All supporter stakes are lost/burned
             for (uint i = 0; i < claim.supportDisputeIds.length; i++) {
                 bytes32 disputeId = claim.supportDisputeIds[i];
                 disputeStakes[disputeId].status = DisputeStatus.Lost;
                 // Points were already burned on staking. No refund.
             }
             // The claim submitter loses reputation if claim is invalid and challenged
             userProfiles[claim.submitter].reputationScore -= int256(getClaimWeight(claim.claimTypeHash) * 5); // Arbitrary penalty
        }

        // If the claim was pending and just passed the challenge period without challenges, it becomes ResolvedValid
        if (claim.status == ClaimStatus.Pending) {
            claim.status = ClaimStatus.ResolvedValid;
            // Submitter gets a small reputation boost for unchallenged valid claim
            userProfiles[claim.submitter].reputationScore += int256(getClaimWeight(claim.claimTypeHash) * 2); // Smaller boost
        }
         // Reputation updates emitted inside the resolution logic if scores changed
         emit ReputationUpdated(claim.submitter, userProfiles[claim.submitter].reputationScore);


        emit ClaimResolved(_claimId, _isClaimValid);
    }


    // --- 12. Staking Rewards & Slashing ---
    // Note: In the simple resolution above, winning stakes are minted back *with* rewards immediately.
    // This claimStakingRewards function allows winners to claim their *original* staked amount if the
    // resolution logic didn't handle the rewards directly (e.g., if funds were held in contract).
    // Given the current resolution mints rewards, this function could be simplified or removed,
    // or modified to allow claiming *original* stake back if resolution only handled slashings.
    // Let's keep it to explicitly mark the dispute as "withdrawn" state for tracking.

    function claimStakingRewards(bytes32 _disputeId) external onlyRegisteredUser {
        DisputeStake storage dispute = disputeStakes[_disputeId];
        require(dispute.stakedTimestamp != 0, "Dispute stake does not exist");
        require(dispute.staker == msg.sender, "Only the staker can claim rewards");
        require(dispute.status == DisputeStatus.Won, "Dispute stake did not win resolution");
        require(claims[dispute.claimId].status == ClaimStatus.ResolvedValid || claims[dispute.claimId].status == ClaimStatus.ResolvedInvalid, "Claim is not resolved");

        // In the current implementation of resolveClaimChallenge, points (stake + rewards) are minted immediately.
        // This function simply marks the dispute as withdrawn.
        // If resolveClaimChallenge *transferred* instead of minting, this function would handle the transfer.
        // Example if transfer: _nexusPoints[msg.sender] += dispute.amountStaked + calculatedReward; // Assuming rewards are calculated/stored somewhere
        //emit StakingRewardsClaimed(_disputeId, msg.sender, dispute.amountStaked + calculatedReward);

        dispute.status = DisputeStatus.Withdrawn; // Mark as claimed/withdrawn
        emit StakingRewardsClaimed(_disputeId, msg.sender, 0); // Emit event, 0 amount as points were minted directly
    }


    // --- 13. Reputation Calculation & Retrieval ---

    // Simplified Reputation Calculation: Sum of weighted scores from resolved claims.
    // Does *not* include sophisticated time decay, which would require iterating or tracking decay times.
    // A real decay would need to apply a time penalty when this is called, or rely on an external process.
    // This version just sums up points from resolved claims.
    function calculateReputationScore(address _userAddress) public view returns (int256) {
         require(isUserRegisteredBool[_userAddress], "User not registered");
         // In this version, the score is already updated directly in resolveClaimChallenge
         return userProfiles[_userAddress].reputationScore;

         // A more complex calculation could iterate resolved claims/disputes
         /*
         int256 totalScore = 0;
         // Iterate through claims submitted by user
         for(uint i=0; i < userProfiles[_userAddress].submittedClaimIds.length; i++) {
              bytes32 claimId = userProfiles[_userAddress].submittedClaimIds[i];
              Claim storage claim = claims[claimId];
              uint256 weight = getClaimWeight(claim.claimTypeHash);
              uint256 timeFactor = (block.timestamp - claim.submittedTimestamp) < 365 days ? 100 : 50; // Simple time decay example
              if (claim.status == ClaimStatus.ResolvedValid) {
                  totalScore += int256(weight * timeFactor / 10); // Arbitrary gain
              } else if (claim.status == ClaimStatus.ResolvedInvalid) {
                   totalScore -= int256(weight * timeFactor / 5); // Arbitrary loss
              }
         }
         // Iterate through disputes by user
          bytes32[] memory userDisputes = userProfiles[_userAddress].disputeIds[claimId]; // This mapping structure is wrong for iterating *all* disputes
          // A better structure would be a list of all dispute IDs for a user
          // Or, iterate through all claims and then check disputes on that claim by this user.

          // Simplified example: Just consider submitted claims impact
         */
        // Let's stick to the simple version where reputation is updated directly on resolution.
        // The decay rate parameter is currently illustrative, not applied in calculation.
    }


    function getReputationScore(address _userAddress) external view returns (int256) {
        return calculateReputationScore(_userAddress); // Call the internal calculation
    }

    // Calculate a 'trust' score for a claim based on the total staked amount for/against it.
    // Positive score means more support stake, negative means more challenge stake.
    function getClaimTrustScore(bytes32 _claimId) external view returns (int256) {
         require(claims[_claimId].submittedTimestamp != 0, "Claim does not exist");

        int256 trust = 0;
        for (uint i = 0; i < claims[_claimId].supportDisputeIds.length; i++) {
            trust += int256(disputeStakes[claims[_claimId].supportDisputeIds[i]].amountStaked);
        }
        for (uint i = 0; i < claims[_claimId].challengeDisputeIds.length; i++) {
            trust -= int256(disputeStakes[claims[_claimId].challengeDisputeIds[i]].amountStaked);
        }
        return trust;
    }

    // --- 14. View/Helper Functions ---

    function isEntityClaimable(address _entityAddress) public view returns (bool) {
        return isEntityClaimableBool[_entityAddress] && claimableEntities[_entityAddress].isActive;
    }

     function isUserRegistered(address _userAddress) public view returns (bool) {
        return isUserRegisteredBool[_userAddress];
    }

    function hashClaimType(string memory _typeName) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_typeName));
    }

    function hashChallengeReason(string memory _reason) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_reason));
    }

    function getClaimStatus(bytes32 _claimId) external view returns (ClaimStatus) {
        require(claims[_claimId].submittedTimestamp != 0, "Claim does not exist");
        Claim storage claim = claims[_claimId];

        // Automatically transition from Pending to ResolvedValid if challenge period expired without challenge
        if (claim.status == ClaimStatus.Pending && block.timestamp > claim.submittedTimestamp + claimChallengePeriod) {
            return ClaimStatus.ResolvedValid; // Note: This is a view, state isn't changed. Resolution function changes state.
        }

        return claim.status;
    }

    function getClaimWeight(bytes32 _claimTypeHash) internal view returns (uint256) {
        return claimTypeWeights[_claimTypeHash] > 0 ? claimTypeWeights[_claimTypeHash] : 1; // Default weight is 1
    }

     // Function to get specific dispute details
    function getDisputeDetails(bytes32 _disputeId) external view returns (DisputeStake memory) {
        require(disputeStakes[_disputeId].stakedTimestamp != 0, "Dispute stake does not exist");
        return disputeStakes[_disputeId];
    }

    // Function to get specific evidence details
    function getEvidenceDetails(bytes32 _evidenceId) external view returns (Evidence memory) {
        require(evidenceSubmissions[_evidenceId].submittedTimestamp != 0, "Evidence submission does not exist");
        return evidenceSubmissions[_evidenceId];
    }

}
```