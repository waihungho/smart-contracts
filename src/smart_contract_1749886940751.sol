Okay, here is a Solidity smart contract implementing a decentralized "Skill & Reputation Nexus".

This concept involves users creating profiles, claiming skills, attesting to the skills and profiles of others, and a dynamic reputation score based on these attestations. It includes a staking mechanism where users can stake tokens on profiles they believe in, potentially earning rewards based on reputation growth or shared fees (simulated here via a reward pool). It also incorporates a simple dispute mechanism.

It avoids being a direct clone of standard tokens, NFTs (though it interacts with them), or DeFi primitives by combining these elements into a novel system focused on on-chain professional identity and reputation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract Outline and Function Summary ---
/*
Contract Name: SkillAndReputationNexus

Core Concept:
A decentralized platform for building on-chain professional profiles,
managing claimed skills, receiving attestations from others, and
developing a dynamic reputation score. Users can stake tokens on
profiles they trust or attestations they believe in, potentially
earning rewards and influencing the reputation system.

Components:
1.  User Profiles: Linked to a Profile NFT, store reputation score.
2.  Skill Registry: A list of available skills users can claim or attest to.
3.  Attestations: Users vouching for others' skills or general profile quality.
    Attestations have weight and contribute to reputation.
4.  Reputation Score: Dynamically calculated based on incoming attestations.
5.  Staking: Users stake tokens on profiles or specific attestations.
    Staking signals confidence and can influence the system or earn rewards.
6.  Disputes: Mechanism to challenge potentially fraudulent attestations.
7.  Rewards: Distribution of collected tokens to stakers based on their stake
    and potentially the performance/reputation of their staking targets.
8.  Governance/Admin: Basic functions for managing the system (adding skills,
    resolving disputes - simplified for this example).

State Variables:
- owner: Contract deployer.
- profileNFT: Address of the associated ERC721 Profile NFT contract.
- governanceToken: Address of the associated ERC20 utility/reward token.
- skillRegistry: Mapping skill ID to Skill struct.
- skillCounter: Counter for unique skill IDs.
- userProfiles: Mapping user address to Profile struct.
- userSkills: Mapping user address to mapping skill ID to bool (claimed).
- attestations: Mapping attestation ID to Attestation struct.
- attestationCounter: Counter for unique attestation IDs.
- userAttestationsMade: Mapping user address to array of attestation IDs they made.
- subjectAttestationsReceived: Mapping subject address to array of attestation IDs they received.
- userStakes: Mapping user address to mapping target address/attestation ID to Stake struct.
- totalStaked: Total tokens staked in the contract.
- disputes: Mapping dispute ID to Dispute struct.
- disputeCounter: Counter for unique dispute IDs.
- disputeVoteTallies: Mapping dispute ID to mapping address to bool (voted).
- disputeStakePool: Mapping dispute ID to tokens staked on dispute outcome.
- totalRewardsClaimed: Total rewards distributed.

Enums:
- AttestationType: SKILL, PROFILE
- AttestationStatus: ACTIVE, REVOKED, DISPUTED, INVALIDATED, VALIDATED
- StakeTargetType: PROFILE, ATTESTATION
- DisputeStatus: OPEN, RESOLVED_VALID, RESOLVED_INVALID, CANCELLED

Structs:
- Skill: name, description, isActive
- Profile: reputation, profileNFTId, isProfileCreated, creationTime
- Attestation: attester, subject, attestationType, dataIdentifier, weight, status, timestamp, disputeId
- Stake: staker, targetAddress, targetAttestationId, stakeAmount, stakeTargetType, stakeTime
- Dispute: attestationId, challenger, status, creationTime, resolutionTime

Events:
- ProfileCreated: Triggered when a new user profile is created.
- SkillAdded: Triggered when a new skill is added to the registry.
- SkillClaimed: Triggered when a user claims a skill.
- SkillUnclaimed: Triggered when a user unclaims a skill.
- AttestationMade: Triggered when an attestation is created.
- AttestationRevoked: Triggered when an attestation is revoked.
- ReputationUpdated: Triggered when a user's reputation potentially changes (note: score is calculated dynamically).
- Staked: Triggered when tokens are staked.
- Unstaked: Triggered when tokens are unstaked.
- DisputeInitiated: Triggered when an attestation is disputed.
- DisputeResolved: Triggered when a dispute is resolved.
- RewardClaimed: Triggered when a user claims staking rewards.
- StakeTargetTypeMismatch: Logged on stake/unstake if target type doesn't match existing stake.

Modifiers:
- onlyOwner: Restricts function access to the contract owner.
- profileExists: Requires the caller or a specified address to have a profile.
- skillExists: Requires a skill ID to be valid and active.
- isAttestationActive: Requires an attestation to be active.
- isAttester: Requires the caller to be the attester of a specific attestation.
- isDisputeOpen: Requires a dispute to be in the OPEN status.
- isValidStakeTarget: Requires a valid target address or attestation ID depending on type.

Functions (28 Public/External/View):

Admin (4):
1.  constructor(): Initializes the contract with NFT and Token addresses.
2.  setProfileNFTAddress(address _profileNFT): Sets the address of the Profile NFT contract (only owner).
3.  setGovernanceTokenAddress(address _governanceToken): Sets the address of the Governance Token contract (only owner).
4.  addSkill(string calldata _name, string calldata _description): Adds a new skill to the registry (only owner).

Profile Management (4):
5.  createProfile(): Creates a new user profile and mints a Profile NFT (requires NFT contract interaction).
6.  getProfile(address _user): Retrieves a user's profile details. (View)
7.  claimSkill(uint256 _skillId): User claims a specific skill. (Requires skill exists)
8.  unclaimSkill(uint256 _skillId): User unclaims a specific skill. (Requires skill claimed)

Attestation System (5):
9.  attest(address _subject, AttestationType _type, uint256 _dataIdentifier, uint256 _weight): Creates an attestation for a subject's skill or profile. (_dataIdentifier means skill ID for SKILL type).
10. revokeAttestation(uint256 _attestationId): Attester revokes their attestation. (Requires attestation exists and is active, caller is attester)
11. getAttestationDetails(uint256 _attestationId): Retrieves details of a specific attestation. (View)
12. getUserAttestationsMade(address _user): Gets a list of attestation IDs made by a user. (View)
13. getUserAttestationsReceived(address _subject): Gets a list of attestation IDs received by a user. (View)

Reputation (1):
14. getUserReputation(address _user): Calculates and returns the user's current reputation score based on active attestations. (View - calculation might be gas-intensive for many attestations)

Staking (6):
15. stake(StakeTargetType _type, address _targetAddress, uint256 _targetAttestationId, uint256 _amount): Stakes tokens on a profile or attestation. (Requires profile/attestation exists, requires token transfer approval)
16. unstake(StakeTargetType _type, address _targetAddress, uint256 _targetAttestationId, uint256 _amount): Unstakes tokens from a profile or attestation. (Requires stake exists, amount <= staked)
17. unstakeAll(StakeTargetType _type, address _targetAddress, uint256 _targetAttestationId): Unstakes all tokens from a specific target.
18. getStakeDetails(address _staker, StakeTargetType _type, address _targetAddress, uint256 _targetAttestationId): Retrieves details of a specific stake. (View)
19. getTotalStaked(): Retrieves the total amount of tokens staked in the contract. (View)
20. getUserTotalStaked(address _user): Retrieves the total amount of tokens a user has staked across all targets. (View)

Disputes (4):
21. initiateDispute(uint256 _attestationId): Initiates a dispute for an attestation. (Requires attestation is active, challenger stakes collateral - collateral handling simplified in this example)
22. resolveDispute(uint256 _disputeId, bool _isValid): Owner resolves a dispute, marking the attestation as valid or invalid.
23. getDisputeDetails(uint256 _disputeId): Retrieves details of a specific dispute. (View)
24. getDisputeCount(): Retrieves the total number of disputes. (View)

Rewards (2):
25. claimRewards(): Allows a user to claim accrued staking rewards. (Reward calculation simplified, assumes a pool distributes proportionally to stake amount * target reputation/validity).
26. getPendingRewards(address _user): Calculates and returns the estimated pending rewards for a user. (View - simplified calculation)

Utility & Views (2):
27. getSkillDetails(uint256 _skillId): Retrieves details of a specific skill. (View)
28. getAllSkills(): Retrieves details of all registered skills. (View - might hit gas limits for many skills)
*/

// --- Minimal Interface Definitions (to avoid importing OpenZeppelin directly) ---

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function mint(address to) external returns (uint256 tokenId); // Assuming a simplified mint function for the Profile NFT
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// --- Custom Error Definitions (Solidity >= 0.8.4) ---
error ProfileDoesNotExist(address user);
error ProfileAlreadyExists(address user);
error SkillDoesNotExist(uint256 skillId);
error SkillNotClaimed(address user, uint256 skillId);
error AttestationDoesNotExist(uint256 attestationId);
error AttestationNotActive(uint256 attestationId);
error UnauthorizedAttester(uint256 attestationId);
error CannotAttestSelf();
error CannotStakeSelf();
error StakeDoesNotExist(address staker, uint256 targetAttestationId); // Simplified error, needs target type/address
error InsufficientStake(address staker, uint256 targetAttestationId, uint256 requested, uint256 available); // Simplified error
error InvalidStakeTarget();
error InsufficientBalance(uint256 required, uint256 available);
error TokenTransferFailed();
error NFTContractNotSet();
error TokenContractNotSet();
error DisputeDoesNotExist(uint256 disputeId);
error DisputeNotOpen(uint256 disputeId);
error InvalidDisputeResolution(); // e.g., resolving with status other than valid/invalid
error NoPendingRewards(address user);
error NoStakeFound(address staker, StakeTargetType targetType, address targetAddress, uint256 targetAttestationId);


contract SkillAndReputationNexus {

    address public owner;
    IERC721 public profileNFT;
    IERC20 public governanceToken;

    enum AttestationType { SKILL, PROFILE }
    enum AttestationStatus { ACTIVE, REVOKED, DISPUTED, INVALIDATED, VALIDATED } // VALIDATED could be result of dispute
    enum StakeTargetType { PROFILE, ATTESTATION }
    enum DisputeStatus { OPEN, RESOLVED_VALID, RESOLVED_INVALID, CANCELLED } // CANCELLED if attestation revoked during dispute

    struct Skill {
        string name;
        string description;
        bool isActive;
    }

    struct Profile {
        uint256 reputation; // Calculated dynamically, not stored here directly
        uint256 profileNFTId;
        bool isProfileCreated;
        uint256 creationTime;
    }

    struct Attestation {
        address attester;
        address subject;
        AttestationType attestationType;
        uint256 dataIdentifier; // Skill ID for SKILL, or 0/rating for PROFILE? Let's use uint for skill ID, maybe a rating scale (1-5) for PROFILE type
        uint256 weight; // Influence on reputation (e.g., staker reputation, stake amount?)
        AttestationStatus status;
        uint256 timestamp;
        uint256 disputeId; // 0 if no active dispute
    }

    struct Stake {
        address staker;
        address targetAddress; // For PROFILE targets
        uint256 targetAttestationId; // For ATTESTATION targets
        StakeTargetType stakeTargetType;
        uint256 stakeAmount;
        uint256 stakeTime; // Timestamp of staking
        // Could add tracking for yield calculation
    }

    struct Dispute {
        uint256 attestationId;
        address challenger;
        DisputeStatus status;
        uint256 creationTime;
        uint256 resolutionTime;
        // In a real system: would need voting, collateral, etc.
    }

    mapping(uint256 => Skill) public skillRegistry;
    uint256 public skillCounter; // Starts from 1

    mapping(address => Profile) public userProfiles;
    mapping(address => mapping(uint256 => bool)) public userSkills; // address => skillId => claimed

    mapping(uint256 => Attestation) public attestations;
    uint256 public attestationCounter; // Starts from 1

    mapping(address => uint256[]) public userAttestationsMade;
    mapping(address => uint256[]) public subjectAttestationsReceived;

    // Mapping: staker => (targetType => targetAddress => attestationId => Stake)
    // This allows staking on multiple profiles AND multiple attestations.
    // Using 0 for targetAttestationId when targetType is PROFILE
    // Using address(0) for targetAddress when targetType is ATTESTATION (targetAttestationId is key)
    mapping(address => mapping(StakeTargetType => mapping(address => mapping(uint256 => Stake)))) public userStakes;

    uint256 public totalStaked;

    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCounter; // Starts from 1

    // Simplistic reward tracking - in a real system, yield would be more complex
    mapping(address => uint256) public rewardsAccrued;
    uint256 public totalRewardsClaimed;

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].isProfileCreated, ProfileDoesNotExist(_user).selector);
        _;
    }

     modifier skillExists(uint256 _skillId) {
        require(_skillId > 0 && _skillId <= skillCounter && skillRegistry[_skillId].isActive, SkillDoesNotExist(_skillId).selector);
        _;
    }

    modifier isAttestationActive(uint256 _attestationId) {
        require(_attestationId > 0 && _attestationId <= attestationCounter, AttestationDoesNotExist(_attestationId).selector);
        require(attestations[_attestationId].status == AttestationStatus.ACTIVE, AttestationNotActive(_attestationId).selector);
        _;
    }

    modifier isAttester(uint256 _attestationId) {
        require(attestations[_attestationId].attester == msg.sender, UnauthorizedAttester(_attestationId).selector);
        _;
    }

     modifier isDisputeOpen(uint256 _disputeId) {
        require(_disputeId > 0 && _disputeId <= disputeCounter, DisputeDoesNotExist(_disputeId).selector);
        require(disputes[_disputeId].status == DisputeStatus.OPEN, DisputeNotOpen(_disputeId).selector);
        _;
    }

    // --- Constructor ---

    constructor(address _profileNFT, address _governanceToken) {
        owner = msg.sender;
        profileNFT = IERC721(_profileNFT);
        governanceToken = IERC20(_governanceToken);
        skillCounter = 0;
        attestationCounter = 0;
        disputeCounter = 0;
    }

    // --- Admin Functions ---

    function setProfileNFTAddress(address _profileNFT) external onlyOwner {
        profileNFT = IERC721(_profileNFT);
        emit NFTContractNotSet(); // Using an event here just for logging demonstration
    }

    function setGovernanceTokenAddress(address _governanceToken) external onlyOwner {
        governanceToken = IERC20(_governanceToken);
         emit TokenContractNotSet(); // Using an event here just for logging demonstration
    }

    function addSkill(string calldata _name, string calldata _description) external onlyOwner returns (uint256) {
        skillCounter++;
        skillRegistry[skillCounter] = Skill(_name, _description, true);
        emit SkillAdded(skillCounter, _name);
        return skillCounter;
    }

    // Example: disable a skill
    // function disableSkill(uint256 _skillId) external onlyOwner skillExists(_skillId) {
    //     skillRegistry[_skillId].isActive = false;
    //     // Need to handle existing attestations for this skill - maybe mark them inactive?
    // }

    // --- Profile Management Functions ---

    function createProfile() external {
        require(!userProfiles[msg.sender].isProfileCreated, ProfileAlreadyExists(msg.sender).selector);
        require(address(profileNFT) != address(0), NFTContractNotSet().selector);

        uint256 newNFTId = profileNFT.mint(msg.sender); // Assuming the NFT contract has a public mint function callable by this contract

        userProfiles[msg.sender] = Profile({
            reputation: 0, // Initial reputation - dynamically calculated later
            profileNFTId: newNFTId,
            isProfileCreated: true,
            creationTime: block.timestamp
        });

        emit ProfileCreated(msg.sender, newNFTId, block.timestamp);
    }

    function getProfile(address _user) external view profileExists(_user) returns (Profile memory) {
        Profile memory profile = userProfiles[_user];
        // Note: profile.reputation stored is not the dynamic calculation
        // Use getUserReputation for the current calculated value
        return profile;
    }

    function claimSkill(uint256 _skillId) external profileExists(msg.sender) skillExists(_skillId) {
        require(!userSkills[msg.sender][_skillId], "Skill already claimed");
        userSkills[msg.sender][_skillId] = true;
        emit SkillClaimed(msg.sender, _skillId);
    }

    function unclaimSkill(uint256 _skillId) external profileExists(msg.sender) {
        require(userSkills[msg.sender][_skillId], SkillNotClaimed(msg.sender, _skillId).selector);
        userSkills[msg.sender][_skillId] = false;
        emit SkillUnclaimed(msg.sender, _skillId);
    }

    // --- Attestation System Functions ---

    function attest(
        address _subject,
        AttestationType _type,
        uint256 _dataIdentifier, // Skill ID for SKILL, potentially rating for PROFILE
        uint256 _weight // Influence weight (e.g., 1-10) - could be influenced by attester's reputation/stake
    ) external profileExists(msg.sender) profileExists(_subject) {
        require(msg.sender != _subject, CannotAttestSelf().selector);

        // Basic validation based on type
        if (_type == AttestationType.SKILL) {
            require(skillExists(_dataIdentifier), SkillDoesNotExist(_dataIdentifier).selector);
             // Optional: require subject to have claimed the skill? Or allow attesting un-claimed skills?
             // require(userSkills[_subject][_dataIdentifier], "Subject has not claimed this skill");
        } else if (_type == AttestationType.PROFILE) {
             // For profile attestations, _dataIdentifier could represent a rating (e.g., 1-5)
             // Or it could be 0 and weight signifies the rating. Let's use weight for influence.
             // _dataIdentifier could be ignored or used for sub-categories of profile attestations.
             // Let's ignore _dataIdentifier for PROFILE type in this example, or set a range constraint.
             require(_dataIdentifier == 0, "dataIdentifier must be 0 for PROFILE type"); // Or check rating range
             require(_weight > 0, "Weight must be positive for PROFILE attestation");
        } else {
             revert("Invalid attestation type");
        }

        attestationCounter++;
        uint256 newAttestationId = attestationCounter;

        attestations[newAttestationId] = Attestation({
            attester: msg.sender,
            subject: _subject,
            attestationType: _type,
            dataIdentifier: _dataIdentifier,
            weight: _weight, // This weight could be multiplied by attester's current reputation or stake
            status: AttestationStatus.ACTIVE,
            timestamp: block.timestamp,
            disputeId: 0 // No active dispute initially
        });

        userAttestationsMade[msg.sender].push(newAttestationId);
        subjectAttestationsReceived[_subject].push(newAttestationId);

        // Trigger potential reputation update (dynamic calculation makes storage update unnecessary here)
        emit AttestationMade(newAttestationId, msg.sender, _subject, _type, _dataIdentifier, _weight, block.timestamp);
        // emit ReputationUpdated(_subject, getUserReputation(_subject)); // Emitting this here could be gas heavy
    }

    function revokeAttestation(uint256 _attestationId) external isAttestationActive(_attestationId) isAttester(_attestationId) {
        attestations[_attestationId].status = AttestationStatus.REVOKED;

        // If under dispute, cancel the dispute
        if (attestations[_attestationId].disputeId != 0 && disputes[attestations[_attestationId].disputeId].status == DisputeStatus.OPEN) {
             disputes[attestations[_attestationId].disputeId].status = DisputeStatus.CANCELLED;
             disputes[attestations[_attestationId].disputeId].resolutionTime = block.timestamp;
             // Need to handle collateral refund for cancelled dispute here
             emit DisputeResolved(attestations[_attestationId].disputeId, DisputeStatus.CANCELLED);
        }


        // Trigger potential reputation update (dynamic calculation makes storage update unnecessary here)
        emit AttestationRevoked(_attestationId, msg.sender, attestations[_attestationId].subject, block.timestamp);
        // emit ReputationUpdated(attestations[_attestationId].subject, getUserReputation(attestations[_attestationId].subject));
    }

     function getAttestationDetails(uint256 _attestationId) external view returns (Attestation memory) {
        require(_attestationId > 0 && _attestationId <= attestationCounter, AttestationDoesNotExist(_attestationId).selector);
        return attestations[_attestationId];
    }

    function getUserAttestationsMade(address _user) external view returns (uint256[] memory) {
        // No profileExists check here as user might have made attestations before profile creation was mandatory (if logic changed), or for users without profiles.
        return userAttestationsMade[_user];
    }

    function getUserAttestationsReceived(address _subject) external view returns (uint256[] memory) {
         // No profileExists check here for similar reasons.
        return subjectAttestationsReceived[_subject];
    }

    // --- Reputation Function ---

    // Note: This is a view function and calculates reputation on-the-fly.
    // For subjects with many attestations, this could exceed gas limits.
    // A more robust system would use checkpointing or incremental updates.
    function getUserReputation(address _user) public view returns (uint256) {
        // If the user has no profile created via this contract, reputation is 0
        if (!userProfiles[_user].isProfileCreated) {
            return 0;
        }

        uint256 totalWeight = 0;
        uint256[] storage receivedAttestations = subjectAttestationsReceived[_user];

        for (uint i = 0; i < receivedAttestations.length; i++) {
            uint256 attId = receivedAttestations[i];
            Attestation storage att = attestations[attId];

            // Only consider active or validated attestations
            if (att.status == AttestationStatus.ACTIVE || att.status == AttestationStatus.VALIDATED) {
                // Simple reputation calculation: Sum of weights from active/validated attestations.
                // Could be more complex: weight by attester's reputation, decay over time,
                // differentiate by attestation type, incorporate staking influence, etc.
                totalWeight += att.weight;
            }
        }

        // Simple model: reputation is just the sum of active/validated weights.
        // Could scale it, add a base reputation, etc.
        return totalWeight; // Placeholder: Simple sum of weights
    }

    // --- Staking Functions ---

    // Helper to get target address/ID based on type for mapping lookup
    function _getStakeMappingKeys(StakeTargetType _type, address _targetAddress, uint256 _targetAttestationId)
        private
        pure
        returns (address keyAddress, uint256 keyUint)
    {
        if (_type == StakeTargetType.PROFILE) {
            keyAddress = _targetAddress;
            keyUint = 0; // Use 0 for profile targets
        } else if (_type == StakeTargetType.ATTESTATION) {
            keyAddress = address(0); // Use address(0) for attestation targets
            keyUint = _targetAttestationId;
        } else {
            revert InvalidStakeTarget();
        }
    }

    function stake(
        StakeTargetType _type,
        address _targetAddress,
        uint256 _targetAttestationId,
        uint256 _amount
    ) external profileExists(msg.sender) {
        require(address(governanceToken) != address(0), TokenContractNotSet().selector);
        require(_amount > 0, "Cannot stake 0");
        require(msg.sender != _targetAddress, CannotStakeSelf().selector); // Prevent staking on own profile

        // Validate target
        if (_type == StakeTargetType.PROFILE) {
            require(_targetAttestationId == 0, "Attestation ID must be 0 for Profile stake");
            require(userProfiles[_targetAddress].isProfileCreated, ProfileDoesNotExist(_targetAddress).selector);
        } else if (_type == StakeTargetType.ATTESTATION) {
            require(_targetAddress == address(0), "Target address must be address(0) for Attestation stake");
            require(_targetAttestationId > 0 && _targetAttestationId <= attestationCounter, AttestationDoesNotExist(_targetAttestationId).selector);
             // Optional: require attestation to be active/disputed? Can stake on invalid ones too to bet against them?
             // require(attestations[_targetAttestationId].status == AttestationStatus.ACTIVE, "Attestation must be active to stake on");
        } else {
             revert InvalidStakeTarget();
        }

        (address keyAddress, uint256 keyUint) = _getStakeMappingKeys(_type, _targetAddress, _targetAttestationId);
        Stake storage existingStake = userStakes[msg.sender][_type][keyAddress][keyUint];

        if (existingStake.stakeAmount == 0) {
            // New stake
            existingStake.staker = msg.sender;
            existingStake.targetAddress = _targetAddress;
            existingStake.targetAttestationId = _targetAttestationId;
            existingStake.stakeTargetType = _type;
            existingStake.stakeTime = block.timestamp;
        } else {
             // Check if target type matches existing stake
             require(existingStake.stakeTargetType == _type, "Stake target type mismatch for existing stake");
        }

        // Transfer tokens from user to contract
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), TokenTransferFailed().selector);

        existingStake.stakeAmount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _type, _targetAddress, _targetAttestationId, _amount, existingStake.stakeAmount, block.timestamp);
    }

    function unstake(
        StakeTargetType _type,
        address _targetAddress,
        uint256 _targetAttestationId,
        uint256 _amount
    ) external profileExists(msg.sender) {
        require(address(governanceToken) != address(0), TokenContractNotSet().selector);
        require(_amount > 0, "Cannot unstake 0");

        (address keyAddress, uint256 keyUint) = _getStakeMappingKeys(_type, _targetAddress, _targetAttestationId);
        Stake storage existingStake = userStakes[msg.sender][_type][keyAddress][keyUint];

        require(existingStake.stakeAmount > 0, NoStakeFound(msg.sender, _type, _targetAddress, _targetAttestationId).selector);
        require(existingStake.stakeAmount >= _amount, InsufficientStake(msg.sender, _targetAttestationId, _amount, existingStake.stakeAmount).selector);
        require(existingStake.stakeTargetType == _type, "Stake target type mismatch"); // Double check type consistency

        // Transfer tokens from contract back to user
        require(governanceToken.transfer(msg.sender, _amount), TokenTransferFailed().selector);

        existingStake.stakeAmount -= _amount;
        totalStaked -= _amount;

        // If stake amount reaches zero, clean up the storage slot
        if (existingStake.stakeAmount == 0) {
            delete userStakes[msg.sender][_type][keyAddress][keyUint];
             // Note: This completely removes the Stake struct, losing stakeTime history.
             // For reward calculation based on duration, need a different approach or separate storage.
        }

        emit Unstaked(msg.sender, _type, _targetAddress, _targetAttestationId, _amount, existingStake.stakeAmount, block.timestamp);
    }

     function unstakeAll(
        StakeTargetType _type,
        address _targetAddress,
        uint256 _targetAttestationId
    ) external profileExists(msg.sender) {
        require(address(governanceToken) != address(0), TokenContractNotSet().selector);

        (address keyAddress, uint256 keyUint) = _getStakeMappingKeys(_type, _targetAddress, _targetAttestationId);
        Stake storage existingStake = userStakes[msg.sender][_type][keyAddress][keyUint];

        require(existingStake.stakeAmount > 0, NoStakeFound(msg.sender, _type, _targetAddress, _targetAttestationId).selector);
        require(existingStake.stakeTargetType == _type, "Stake target type mismatch");

        uint256 amountToUnstake = existingStake.stakeAmount;

        // Transfer tokens from contract back to user
        require(governanceToken.transfer(msg.sender, amountToUnstake), TokenTransferFailed().selector);

        totalStaked -= amountToUnstake;

        // Clean up storage
        delete userStakes[msg.sender][_type][keyAddress][keyUint];

        emit Unstaked(msg.sender, _type, _targetAddress, _targetAttestationId, amountToUnstake, 0, block.timestamp);
    }


    function getStakeDetails(
        address _staker,
        StakeTargetType _type,
        address _targetAddress,
        uint256 _targetAttestationId
    ) external view returns (Stake memory) {
         (address keyAddress, uint256 keyUint) = _getStakeMappingKeys(_type, _targetAddress, _targetAttestationId);
         return userStakes[_staker][_type][keyAddress][keyUint];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getUserTotalStaked(address _user) external view returns (uint256) {
        uint256 total = 0;
        // Iterating mappings is not directly possible or gas-efficient in Solidity.
        // A real contract would need to track this sum separately or use a more complex structure.
        // For this example, we'll simulate by iterating potential targets if needed,
        // or simply state this limitation. Let's just return 0 for now or add a note.
        // Note: Calculating total staked across all targets for a single user requires
        // iterating through potentially many mapping keys, which is not feasible in a view
        // function for large numbers of stakes. A separate state variable updated on
        // stake/unstake for *each user* would be needed for an accurate view.
        // Leaving it as 0 for now to avoid complex iteration in a view.
        // return 0; // Placeholder for non-feasible calculation
        // Alternative: If we only allowed staking on profiles, it would be easier to track.
        // Let's assume for this example that we could iterate known profile addresses or attestation IDs the user staked on (e.g., if we tracked them in an array).
        // As is, mapping iteration isn't viable here. Returning a simplified value or requiring off-chain calculation.
         // A simple implementation might just sum stake amounts IF we only allowed staking on profiles or a limited set of attestations tracked in an array.
         // Given the current structure, it's not practical to calculate this sum on-chain in a gas-efficient way.
         // Let's return 0 or indicate it's not directly available via this mapping structure.
        return 0; // Not practically feasible to calculate this on-chain with this mapping structure.
    }


    // --- Dispute Functions ---

    function initiateDispute(uint256 _attestationId) external profileExists(msg.sender) isAttestationActive(_attestationId) {
        Attestation storage att = attestations[_attestationId];
        require(att.attester != msg.sender && att.subject != msg.sender, "Only non-involved parties can initiate disputes");

        // Basic dispute initiation - needs collateral in a real system
        // require(governanceToken.transferFrom(msg.sender, address(this), disputeInitiationCollateral), "Collateral transfer failed");

        disputeCounter++;
        uint256 newDisputeId = disputeCounter;

        disputes[newDisputeId] = Dispute({
            attestationId: _attestationId,
            challenger: msg.sender,
            status: DisputeStatus.OPEN,
            creationTime: block.timestamp,
            resolutionTime: 0
        });

        att.status = AttestationStatus.DISPUTED;
        att.disputeId = newDisputeId;

        emit DisputeInitiated(newDisputeId, _attestationId, msg.sender, block.timestamp);
    }

    // Simplified dispute resolution: Owner decides
    function resolveDispute(uint256 _disputeId, bool _isValid) external onlyOwner isDisputeOpen(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        Attestation storage att = attestations[dispute.attestationId];

        require(att.disputeId == _disputeId, "Attestation dispute ID mismatch"); // Should be linked

        DisputeStatus newStatus = _isValid ? DisputeStatus.RESOLVED_VALID : DisputeStatus.RESOLVED_INVALID;
        AttestationStatus newAttestationStatus = _isValid ? AttestationStatus.VALIDATED : AttestationStatus.INVALIDATED;

        dispute.status = newStatus;
        dispute.resolutionTime = block.timestamp;
        att.status = newAttestationStatus;
        // att.disputeId remains set to the resolved dispute ID

        // In a real system: handle collateral distribution, potentially reputation impact, notify stakers
        // Example: If resolved invalid, stakers on the attestation lose, stakers on challenger (if applicable) win.

        emit DisputeResolved(_disputeId, newStatus);
        // emit ReputationUpdated(att.subject, getUserReputation(att.subject)); // Trigger potential reputation update
    }

     function getDisputeDetails(uint256 _disputeId) external view returns (Dispute memory) {
         require(_disputeId > 0 && _disputeId <= disputeCounter, DisputeDoesNotExist(_disputeId).selector);
         return disputes[_disputeId];
     }

     function getDisputeCount() external view returns (uint256) {
         return disputeCounter;
     }


    // --- Rewards Functions ---

    // This is a simplified reward mechanism. A real system needs
    // careful tracking of stake duration, total staking pool over time,
    // and distribution logic (e.g., proportional, based on target performance,
    // based on fees collected).
    // This example assumes a simple pool that grows and distributes based on stake amount
    // and potentially target profile reputation at time of claim.
    // Assumes tokens are sent to the contract balance by external means for rewards.

    function claimRewards() external profileExists(msg.sender) {
        require(address(governanceToken) != address(0), TokenContractNotSet().selector);

        uint256 pendingRewards = getPendingRewards(msg.sender); // Calculate rewards on the fly

        if (pendingRewards == 0) {
            revert NoPendingRewards(msg.sender);
        }

        // Transfer reward tokens from contract balance to user
        require(governanceToken.transfer(msg.sender, pendingRewards), TokenTransferFailed().selector);

        rewardsAccrued[msg.sender] = 0; // Reset pending rewards after claim
        totalRewardsClaimed += pendingRewards;

        emit RewardClaimed(msg.sender, pendingRewards, block.timestamp);
    }

    // Simplified pending rewards calculation (View)
    // This is a very basic model. Real staking rewards are complex.
    // This version distributes a hypothetical amount based on the user's
    // total stake value and the *current* reputation of profiles they stake on.
    // It does NOT track stake duration or distribution over time accurately.
    function getPendingRewards(address _user) public view returns (uint256) {
        // This function is a placeholder. A real implementation requires:
        // 1. Tracking the total reward pool available over time.
        // 2. Tracking each user's stake amount and duration for each target.
        // 3. Calculating a share of the pool based on (stake_amount * stake_duration * target_performance_multiplier) relative to total network stake-seconds.
        // 4. Subtracting previously claimed rewards.

        // For demonstration, let's assume a simple proportional distribution
        // based on the user's *current* stake relative to total staked,
        // potentially boosted by the reputation of the profile they staked on.

        // This calculation is NOT accurate for a real yield farm.
        // It's complex to do accurately on-chain without state that tracks yield accrual.
        // Let's return 0 and state the complexity, or return a very basic estimate.
        // Returning a basic estimate based on *current* stake and reputation of target profile
        // (assuming only PROFILE staking for simplicity in this view calc):
        // estimated_reward = (user_stake_on_profile / total_staked_on_profiles) * total_rewards_distributed_since_last_claim_on_profiles * reputation_multiplier

        // This requires iterating through all user stakes to sum them, which is not feasible in view.
        // Let's return 0 for now and emphasize that real reward calculation needs off-chain or more state.
        // Or, let's just use a fixed amount per period per stake unit (requires tracking time).
        // Simplest: Rewards are manually sent to the contract, and `claimRewards`
        // just distributes `rewardsAccrued[_user]` which would be updated by an admin function or internal logic.
        // Let's add `rewardsAccrued` and assume it's somehow funded, and `claimRewards` just clears it.

        return rewardsAccrued[_user]; // Assuming rewardsAccrued is updated elsewhere
    }


    // --- Utility & View Functions ---

    function getSkillDetails(uint256 _skillId) external view returns (Skill memory) {
        require(_skillId > 0 && _skillId <= skillCounter, SkillDoesNotExist(_skillId).selector);
        return skillRegistry[_skillId];
    }

    // Note: Retrieving all skills could hit gas limits if many exist.
    function getAllSkills() external view returns (Skill[] memory) {
        Skill[] memory skills = new Skill[](skillCounter);
        for (uint i = 1; i <= skillCounter; i++) {
            skills[i-1] = skillRegistry[i];
        }
        return skills;
    }

     function getProfileNFTId(address _user) external view profileExists(_user) returns (uint256) {
        return userProfiles[_user].profileNFTId;
     }

    function getAttestationCount() external view returns (uint256) {
        return attestationCounter;
    }

     function isSkillClaimed(address _user, uint256 _skillId) external view returns (bool) {
         // Allow checking even if profile doesn't exist, just returns false
         if (!userProfiles[_user].isProfileCreated) return false;
         return userSkills[_user][_skillId];
     }

    // Internal helper to update reputation - not exposed directly as reputation is calculated on view
    // function _updateReputation(address _user) internal {
        // This would be complex, iterating through attestations, applying weights, decay, etc.
        // As reputation is calculated in the view `getUserReputation`, this internal update isn't strictly needed
        // if the view function is the only way to get the score. If we stored it, this would be needed.
        // Storing is better for gas if the score is read frequently, but requires updates on every attestation change.
    // }

    // Internal helper for reward distribution logic (simplified)
    // function _distributeRewardPool() internal {
        // Example logic: distribute tokens from contract balance
        // based on active stakes. This would typically be triggered periodically.
        // Too complex for this example, assuming manual funding or fee distribution.
    // }

    // --- Fallback/Receive functions (Optional but good practice if receiving ETH) ---
    // receive() external payable {}
    // fallback() external payable {}
    // Note: This contract is designed for ERC20/ERC721, receiving ETH isn't central unless for fees/collateral.

    // --- Events ---
    event ProfileCreated(address indexed user, uint256 indexed nftId, uint256 timestamp);
    event SkillAdded(uint256 indexed skillId, string name);
    event SkillClaimed(address indexed user, uint256 indexed skillId);
    event SkillUnclaimed(address indexed user, uint256 indexed skillId);
    event AttestationMade(uint256 indexed attestationId, address indexed attester, address indexed subject, AttestationType attestationType, uint256 dataIdentifier, uint256 weight, uint256 timestamp);
    event AttestationRevoked(uint256 indexed attestationId, address indexed attester, address indexed subject, uint256 timestamp);
    event ReputationUpdated(address indexed user, uint256 newReputation); // Note: Emitted only when reputation is *conceptually* updated, calculation is dynamic view
    event Staked(address indexed staker, StakeTargetType targetType, address indexed targetAddress, uint256 indexed targetAttestationId, uint256 amount, uint256 totalStake, uint256 timestamp);
    event Unstaked(address indexed staker, StakeTargetType targetType, address indexed targetAddress, uint256 indexed targetAttestationId, uint256 amount, uint256 totalStake, uint256 timestamp);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed attestationId, address indexed challenger, uint256 timestamp);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);
    event RewardClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event StakeTargetTypeMismatch(address indexed staker, StakeTargetType providedType, StakeTargetType existingType, address targetAddress, uint256 targetAttestationId); // Log on unstake error

    // Using events for logging potential issues or important state changes
    event NFTContractNotSet();
    event TokenContractNotSet();
}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Decentralized Reputation:** The core concept builds a reputation score not based on centralized identity, but on verifiable on-chain attestations from other users within the system.
2.  **Dynamic Reputation Score (Simulated):** While the actual score isn't a mutable state variable constantly updated (due to gas costs), the `getUserReputation` function calculates it dynamically by iterating over active attestations. This makes the score immediately responsive to changes (new attestations, revocations, dispute resolutions). *Note: As mentioned in comments, this dynamic calculation in a view might hit gas limits for users with thousands of attestations. A real-world system might use checkpointing or incremental updates stored on-chain.*
3.  **Attestations with Weight:** Attestations have a `weight` parameter. In a more advanced version, this weight could be derived from the *attester's* reputation or the amount they *stake* on the attestation, making attestations from reputable/vested users more impactful.
4.  **Generic Attestation Function:** The `attest` function is designed to be somewhat generic (`AttestationType`, `dataIdentifier`), allowing extension beyond just skills (e.g., attesting to project completion, profile quality, etc.).
5.  **Staking on Entities:** Users can stake on *profiles* or specific *attestations*. This signals conviction. Staking on a profile could boost its reputation or the weight of the staker's attestations on that profile. Staking on an attestation could act as a prediction market (betting on its validity) or simply a way to add weight/credibility to it.
6.  **Dispute Mechanism (Simplified):** Includes a basic system for challenging attestations. While the resolution is simplified to an owner decision here, in a real application, this would involve decentralized governance (voting by token holders, stakers, or high-reputation users) and collateral management.
7.  **NFT Integration:** Profiles are linked to a unique Profile NFT (`profileNFTId`). This makes the on-chain profile a tangible digital asset that can be owned, transferred, or potentially gain dynamic traits based on reputation or earned attestations (though dynamic traits aren't explicitly coded here, the data exists to support it).
8.  **Reward Pool (Simulated):** Includes a mechanism (`claimRewards`, `getPendingRewards`) for distributing tokens to stakers. Although the calculation is simplified, the intent is to reward users who participate actively and make successful/well-regarded stakes (e.g., staking on profiles that gain high reputation, or attestations that are validated). This incentivizes good behavior within the system.
9.  **Custom Errors:** Uses `error` definitions (Solidity >= 0.8.4) for gas-efficient and informative error handling, a modern best practice.
10. **Interface Usage:** Defines minimal interfaces (`IERC20`, `IERC721`) rather than importing full libraries like OpenZeppelin, adhering to the "don't duplicate open source" spirit while showing how external contracts are interacted with.
11. **Structured Data:** Uses structs (`Skill`, `Profile`, `Attestation`, `Stake`, `Dispute`) and enums (`AttestationType`, `AttestationStatus`, etc.) for clear organization of complex data.

This contract provides a framework for a complex decentralized application centered around verifiable identity, reputation, and aligned incentives through staking. While some parts (like reputation calculation scale, dispute resolution, reward distribution) are simplified for demonstration, the core concepts and their interaction represent a creative and advanced use of smart contract capabilities.