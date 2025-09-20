This smart contract, named `SkillGraphAttestations`, introduces a novel system for decentralized reputation and skill verification. It allows users to attest to other users' skills, backing these claims with staked tokens. The reputation scores are dynamically calculated, considering the attestation score, the amount staked by the attester, and a time-decay factor. The contract also features a dispute resolution mechanism, user-managed profiles, and the ability to delegate attestation permissions.

---

## Contract: `SkillGraphAttestations`

**A decentralized reputation and skill graphing protocol built on attestations.**
Users can attest to other users' skills with a score and stake tokens to back their claims. Reputation scores are dynamically calculated based on attestations, stake, and time decay. This contract aims to provide a verifiable and dynamic on-chain representation of individual skills and reputation within a community, without relying on centralized authorities.

---

### Function Summary / Outline:

**I. Core Attestation Management**
1.  **`registerSkill(bytes32 _skillId, string memory _skillName, bytes32 _categoryId)`**: Registers a new skill/topic with an optional category.
2.  **`attestSkill(address _recipient, bytes32 _skillId, uint8 _score, uint256 _stakeAmount, uint32 _validityDuration)`**: Creates an attestation for a user's skill, backed by a token stake, with an optional expiration.
3.  **`revokeAttestation(bytes32 _attestationId)`**: Allows an attester to revoke their previously made attestation, returning the staked tokens.
4.  **`updateAttestationScore(bytes32 _attestationId, uint8 _newScore)`**: Enables an attester to update the score of an existing attestation they made.
5.  **`getAttestation(bytes32 _attestationId)`**: Retrieves detailed information about a specific attestation.
6.  **`getAttestationsByAttester(address _attester)`**: Returns a list of all attestation IDs made by a specific address.
7.  **`getAttestationsByRecipient(address _recipient)`**: Returns a list of all attestation IDs received by a specific address.
8.  **`getAttestationsBySkill(bytes32 _skillId)`**: Returns a list of all attestation IDs associated with a specific skill.

**II. Reputation Score Calculation**
9.  **`calculateSkillReputation(address _user, bytes32 _skillId)`**: Calculates the current aggregated reputation score for a user in a specific skill, considering all valid attestations, their stakes, and time decay.
10. **`getOverallReputation(address _user)`**: Calculates an aggregated reputation score across all skills for a given user.
11. **`getTopSkills(address _user, uint256 _limit)`**: Identifies and returns a list of a user's top N skills ranked by their calculated reputation score.

**III. Staking & Rewards**
12. **`depositStake(uint256 _amount)`**: Allows users to deposit ERC20 tokens into their internal contract balance, which can then be used for attestations.
13. **`withdrawStake(uint256 _amount)`**: Enables users to withdraw available (unlocked) ERC20 tokens from their internal contract balance.
14. **`increaseAttestationStake(bytes32 _attestationId, uint256 _additionalAmount)`**: Adds more staked tokens to an existing attestation, increasing its weight in reputation calculation.
15. **`slashStake(address _recipient, bytes32 _attestationId, uint256 _amount)`**: An internal/admin-callable function to slash a portion of the staked tokens from an attestation, typically as part of dispute resolution.

**IV. Dispute Resolution**
16. **`initiateDispute(bytes32 _attestationId, string memory _reasonUri)`**: Allows a user to formally dispute an attestation, requiring a bond and linking to a reason (e.g., IPFS URI).
17. **`resolveDispute(bytes32 _attestationId, bool _isAttestationValid, address _stakeRecipient)`**: A function called by an authorized entity (e.g., DAO or oracle) to resolve a dispute, determining the validity of the attestation and distributing the bond/slashed stake.
18. **`claimDisputeBond(bytes32 _attestationId)`**: Allows the winner of a dispute (the initiator or the attester) to claim the dispute bond once the dispute is resolved.

**V. Profile & Metadata**
19. **`setUserProfileUri(string memory _profileUri)`**: Allows a user to set an IPFS URI or similar link to their public profile metadata.
20. **`getUserProfileUri(address _user)`**: Retrieves the public profile URI for a given user.

**VI. Advanced Concepts / Extensions**
21. **`delegateAttestationPermission(address _delegatee, bytes32[] memory _skillIds, uint32 _duration)`**: Delegates permission to another address to make attestations on the delegator's behalf for specified skills.
22. **`revokeDelegation(address _delegatee, bytes32[] memory _skillIds)`**: Revokes previously granted attestation delegation permissions for specific skills.
23. **`attestSkillAsDelegator(address _delegator, address _recipient, bytes32 _skillId, uint8 _score, uint256 _stakeAmount, uint32 _validityDuration)`**: Allows a delegated address to make an attestation using the delegated "power" of the delegator.
24. **`setSkillCategory(bytes32 _skillId, bytes32 _categoryId)`**: Assigns a skill to a broader category, aiding in skill organization and discovery.
25. **`getSkillsByCategory(bytes32 _categoryId)`**: Retrieves a list of all skills that have been assigned to a specific category.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Function Summary / Outline ---
// I. Core Attestation Management (Functions 1-8)
//    - registerSkill: Registers a new skill/topic.
//    - attestSkill: Creates an attestation for a user's skill, backed by stake.
//    - revokeAttestation: Revokes a previously made attestation, returning stake.
//    - updateAttestationScore: Updates the score of an existing attestation.
//    - getAttestation: Retrieves detailed information about an attestation.
//    - getAttestationsByAttester: Returns attestation IDs made by an attester.
//    - getAttestationsByRecipient: Returns attestation IDs received by a recipient.
//    - getAttestationsBySkill: Returns attestation IDs for a specific skill.

// II. Reputation Score Calculation (Functions 9-11)
//    - calculateSkillReputation: Calculates aggregated reputation score for a skill.
//    - getOverallReputation: Calculates an aggregated reputation score across all skills.
//    - getTopSkills: Identifies and returns a user's top N skills by reputation.

// III. Staking & Rewards (Functions 12-15)
//    - depositStake: Deposits ERC20 tokens into internal balance for staking.
//    - withdrawStake: Withdraws available (unlocked) ERC20 tokens.
//    - increaseAttestationStake: Adds more staked tokens to an existing attestation.
//    - slashStake: Slashes staked tokens from an attestation (admin/dispute callable).

// IV. Dispute Resolution (Functions 16-18)
//    - initiateDispute: Initiates a formal dispute against an attestation.
//    - resolveDispute: Resolves a dispute, called by an authorized entity.
//    - claimDisputeBond: Allows the winner to claim the dispute bond.

// V. Profile & Metadata (Functions 19-20)
//    - setUserProfileUri: Sets an IPFS URI for a user's public profile.
//    - getUserProfileUri: Retrieves a user's public profile URI.

// VI. Advanced Concepts / Extensions (Functions 21-25)
//    - delegateAttestationPermission: Delegates permission to attest on delegator's behalf.
//    - revokeDelegation: Revokes previously granted attestation delegation.
//    - attestSkillAsDelegator: Allows a delegatee to attest using delegator's power.
//    - setSkillCategory: Assigns a skill to a broader category.
//    - getSkillsByCategory: Retrieves all skills within a specific category.
// --- End Function Summary ---


contract SkillGraphAttestations is Ownable {
    using Counters for Counters.Counter;

    IERC20 public immutable reputationToken;

    // --- Configuration Constants ---
    uint32 public constant MAX_DECAY_PERIOD = 365 days; // Attestations fully decay after 1 year
    uint256 public constant MIN_STAKE_AMOUNT = 1000; // Minimum tokens to stake (e.g., 10 tokens with 2 decimal places)
    uint256 public constant DISPUTE_BOND_PERCENTAGE = 5; // 5% of attestation stake as dispute bond

    // --- Data Structures ---

    struct Attestation {
        bytes32 attestationId;      // Unique identifier for the attestation
        address attester;           // Address of the user making the attestation
        address recipient;          // Address of the user receiving the attestation
        bytes32 skillId;            // Identifier for the skill
        uint8 score;                // Score given to the skill (0-100)
        uint256 stakedAmount;       // Tokens staked by attester to back this claim
        uint32 issuanceTimestamp;    // When the attestation was made
        uint32 expirationTimestamp;  // When the attestation automatically expires (0 if no expiration)
        bool revoked;               // True if attestation has been revoked by the attester
        bool disputed;              // True if attestation is currently under dispute
    }

    struct Skill {
        bytes32 skillId;            // Unique identifier for the skill
        string name;                // Human-readable name of the skill
        bytes32 categoryId;         // Optional category ID
        uint32 registrationTimestamp; // When the skill was registered
    }

    struct Dispute {
        bytes32 attestationId;      // The attestation being disputed
        address initiator;          // Who initiated the dispute
        string reasonUri;           // URI pointing to dispute details (e.g., IPFS hash)
        uint256 bondAmount;         // Amount of tokens staked by the initiator for the dispute
        bool resolved;              // True if the dispute has been resolved
        bool attestationFoundValid; // Result of the dispute (true if attestation was valid)
        address winnerAddress;      // Address to receive bond/slashed funds
        uint32 initiationTimestamp; // When the dispute was initiated
    }

    struct Delegation {
        address delegator;          // The user granting the permission
        address delegatee;          // The user receiving the permission
        bytes32[] skillIds;         // Specific skills delegated (empty array for all skills)
        uint32 expirationTimestamp;  // When the delegation expires
    }

    // --- State Variables ---

    // Mappings for core data
    mapping(bytes32 => Attestation) public attestations;
    mapping(bytes32 => Skill) public skills;
    mapping(bytes32 => Dispute) public disputes;

    // Indexes for efficient retrieval
    mapping(address => bytes32[]) public attesterToAttestationIds;
    mapping(address => bytes32[]) public recipientToAttestationIds;
    mapping(bytes32 => bytes32[]) public skillIdToAttestationIds;
    mapping(bytes32 => bytes32[]) public categoryIdToSkillIds;
    mapping(address => string) public userProfileUris;

    // Staking balances: address => amount available for staking
    mapping(address => uint256) public userStakingBalances;

    // Delegation management: delegator => delegatee => skillId => Delegation details
    mapping(address => mapping(address => mapping(bytes32 => Delegation))) public delegations;

    // Store all registered skill IDs for iteration (e.g., for getOverallReputation)
    bytes32[] public allSkillIds;
    Counters.Counter private _totalSkillsRegistered;

    // --- Events ---
    event SkillRegistered(bytes32 indexed skillId, string name, bytes32 indexed categoryId, address indexed by);
    event AttestationMade(bytes32 indexed attestationId, address indexed attester, address indexed recipient, bytes32 indexed skillId, uint8 score, uint256 stakedAmount, uint32 expirationTimestamp);
    event AttestationRevoked(bytes32 indexed attestationId, address indexed attester);
    event AttestationScoreUpdated(bytes32 indexed attestationId, uint8 oldScore, uint8 newScore, address indexed updater);
    event StakeDeposited(address indexed user, uint256 amount);
    event StakeWithdrawn(address indexed user, uint256 amount);
    event AttestationStakeIncreased(bytes32 indexed attestationId, address indexed attester, uint256 additionalAmount);
    event StakeSlashed(bytes32 indexed attestationId, address indexed recipient, uint256 amount);
    event DisputeInitiated(bytes32 indexed attestationId, address indexed initiator, uint256 bondAmount, string reasonUri);
    event DisputeResolved(bytes32 indexed attestationId, bool attestationFoundValid, address indexed winnerAddress);
    event DisputeBondClaimed(bytes32 indexed attestationId, address indexed claimant, uint256 amount);
    event UserProfileUriSet(address indexed user, string profileUri);
    event DelegationGranted(address indexed delegator, address indexed delegatee, bytes32[] skillIds, uint32 expirationTimestamp);
    event DelegationRevoked(address indexed delegator, address indexed delegatee, bytes32[] skillIds);

    // --- Modifiers ---
    modifier onlyDisputeResolver() {
        // In a real system, this would be a DAO, a trusted oracle, or a specific role
        // For this example, let's make it owner-only for simplicity.
        require(msg.sender == owner(), "Only owner can resolve disputes");
        _;
    }

    // --- Constructor ---
    constructor(address _reputationTokenAddress) Ownable(msg.sender) {
        require(_reputationTokenAddress != address(0), "Invalid token address");
        reputationToken = IERC20(_reputationTokenAddress);
    }

    // --- I. Core Attestation Management ---

    /**
     * @notice Registers a new skill in the system.
     * @param _skillId A unique identifier for the skill (e.g., keccak256("Solidity Programming")).
     * @param _skillName A human-readable name for the skill.
     * @param _categoryId An optional category ID for the skill (0x0 if no category).
     */
    function registerSkill(bytes32 _skillId, string memory _skillName, bytes32 _categoryId) public onlyOwner {
        require(skills[_skillId].registrationTimestamp == 0, "Skill already registered");
        require(bytes(_skillName).length > 0, "Skill name cannot be empty");

        skills[_skillId] = Skill({
            skillId: _skillId,
            name: _skillName,
            categoryId: _categoryId,
            registrationTimestamp: uint32(block.timestamp)
        });
        allSkillIds.push(_skillId); // Add to the list of all skills for iteration
        _totalSkillsRegistered.increment();

        if (_categoryId != bytes32(0)) {
            categoryIdToSkillIds[_categoryId].push(_skillId);
        }

        emit SkillRegistered(_skillId, _skillName, _categoryId, msg.sender);
    }

    /**
     * @notice Allows a user to make an attestation about another user's skill.
     * @param _recipient The address of the user whose skill is being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _score The score given to the skill (0-100).
     * @param _stakeAmount The amount of tokens to stake for this attestation.
     * @param _validityDuration The duration in seconds for which the attestation is valid (0 for no expiration).
     */
    function attestSkill(
        address _recipient,
        bytes32 _skillId,
        uint8 _score,
        uint256 _stakeAmount,
        uint32 _validityDuration
    ) public {
        require(msg.sender != _recipient, "Cannot attest your own skill");
        require(skills[_skillId].registrationTimestamp != 0, "Skill not registered");
        require(_score > 0 && _score <= 100, "Score must be between 1 and 100");
        require(_stakeAmount >= MIN_STAKE_AMOUNT, "Stake amount below minimum");
        require(userStakingBalances[msg.sender] >= _stakeAmount, "Insufficient available stake");

        bytes32 attestationId = keccak256(abi.encodePacked(msg.sender, _recipient, _skillId, block.timestamp));
        require(attestations[attestationId].issuanceTimestamp == 0, "Attestation ID collision or already exists");

        uint32 expiration = (_validityDuration == 0) ? 0 : uint32(block.timestamp) + _validityDuration;

        attestations[attestationId] = Attestation({
            attestationId: attestationId,
            attester: msg.sender,
            recipient: _recipient,
            skillId: _skillId,
            score: _score,
            stakedAmount: _stakeAmount,
            issuanceTimestamp: uint32(block.timestamp),
            expirationTimestamp: expiration,
            revoked: false,
            disputed: false
        });

        userStakingBalances[msg.sender] -= _stakeAmount; // Lock the stake

        attesterToAttestationIds[msg.sender].push(attestationId);
        recipientToAttestationIds[_recipient].push(attestationId);
        skillIdToAttestationIds[_skillId].push(attestationId);

        emit AttestationMade(attestationId, msg.sender, _recipient, _skillId, _score, _stakeAmount, expiration);
    }

    /**
     * @notice Allows an attester to revoke their own attestation.
     *         The staked tokens are returned to the attester's available balance.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationId) public {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender, "Only attester can revoke");
        require(!att.revoked, "Attestation already revoked");
        require(!att.disputed, "Cannot revoke a disputed attestation");
        require(att.issuanceTimestamp != 0, "Attestation does not exist");

        att.revoked = true;
        userStakingBalances[msg.sender] += att.stakedAmount; // Return stake
        att.stakedAmount = 0; // Clear staked amount

        emit AttestationRevoked(_attestationId, msg.sender);
    }

    /**
     * @notice Allows an attester to update the score of an existing attestation they made.
     * @param _attestationId The ID of the attestation to update.
     * @param _newScore The new score (0-100).
     */
    function updateAttestationScore(bytes32 _attestationId, uint8 _newScore) public {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender, "Only attester can update score");
        require(!att.revoked, "Cannot update a revoked attestation");
        require(!att.disputed, "Cannot update a disputed attestation");
        require(att.issuanceTimestamp != 0, "Attestation does not exist");
        require(_newScore > 0 && _newScore <= 100, "Score must be between 1 and 100");

        uint8 oldScore = att.score;
        att.score = _newScore;

        emit AttestationScoreUpdated(_attestationId, oldScore, _newScore, msg.sender);
    }

    /**
     * @notice Retrieves the details of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return Attestation struct fields.
     */
    function getAttestation(
        bytes32 _attestationId
    ) public view returns (
        address attester,
        address recipient,
        bytes32 skillId,
        uint8 score,
        uint256 stakedAmount,
        uint32 issuanceTimestamp,
        uint32 expirationTimestamp,
        bool revoked,
        bool disputed
    ) {
        Attestation storage att = attestations[_attestationId];
        require(att.issuanceTimestamp != 0, "Attestation does not exist");
        return (
            att.attester,
            att.recipient,
            att.skillId,
            att.score,
            att.stakedAmount,
            att.issuanceTimestamp,
            att.expirationTimestamp,
            att.revoked,
            att.disputed
        );
    }

    /**
     * @notice Returns an array of attestation IDs made by a specific attester.
     * @param _attester The address of the attester.
     * @return An array of attestation IDs.
     */
    function getAttestationsByAttester(address _attester) public view returns (bytes32[] memory) {
        return attesterToAttestationIds[_attester];
    }

    /**
     * @notice Returns an array of attestation IDs received by a specific recipient.
     * @param _recipient The address of the recipient.
     * @return An array of attestation IDs.
     */
    function getAttestationsByRecipient(address _recipient) public view returns (bytes32[] memory) {
        return recipientToAttestationIds[_recipient];
    }

    /**
     * @notice Returns an array of attestation IDs for a specific skill.
     * @param _skillId The ID of the skill.
     * @return An array of attestation IDs.
     */
    function getAttestationsBySkill(bytes32 _skillId) public view returns (bytes32[] memory) {
        return skillIdToAttestationIds[_skillId];
    }

    // --- II. Reputation Score Calculation ---

    /**
     * @notice Calculates the current reputation score for a user in a specific skill.
     *         The score is a weighted average of valid attestations, considering stake and time decay.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return The calculated reputation score (0-100), or 0 if no valid attestations.
     */
    function calculateSkillReputation(address _user, bytes32 _skillId) public view returns (uint8) {
        bytes32[] memory userSkillAttestations = skillIdToAttestationIds[_skillId];
        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;
        uint32 currentTime = uint32(block.timestamp);

        for (uint256 i = 0; i < userSkillAttestations.length; i++) {
            bytes32 attId = userSkillAttestations[i];
            Attestation storage att = attestations[attId];

            // Only consider attestations for the target user and skill
            if (att.recipient != _user) {
                continue;
            }

            // Filter out invalid attestations
            if (att.revoked || att.disputed || att.stakedAmount == 0 || att.expirationTimestamp != 0 && att.expirationTimestamp < currentTime) {
                continue;
            }

            // Calculate time decay factor (linear decay)
            uint32 timeElapsed = currentTime - att.issuanceTimestamp;
            uint256 decayFactor = (timeElapsed >= MAX_DECAY_PERIOD) ? 0 : (MAX_DECAY_PERIOD - timeElapsed);

            if (decayFactor == 0) {
                continue; // Attestation has fully decayed
            }

            uint256 weight = att.stakedAmount * decayFactor;
            totalWeightedScore += uint256(att.score) * weight;
            totalWeight += weight;
        }

        if (totalWeight == 0) {
            return 0;
        }

        // Reputation = (TotalWeightedScore / TotalWeight) / MAX_DECAY_PERIOD * (MAX_DECAY_PERIOD / MAX_DECAY_PERIOD)
        // Simplified: (totalWeightedScore / totalWeight)
        return uint8(totalWeightedScore / totalWeight);
    }

    /**
     * @notice Calculates an aggregated overall reputation score for a user across all skills.
     *         This is a simplified average of their top skills or all skills.
     * @param _user The address of the user.
     * @return The calculated overall reputation score (0-100), or 0 if no valid attestations.
     */
    function getOverallReputation(address _user) public view returns (uint8) {
        bytes32[] memory userReceivedAttestations = recipientToAttestationIds[_user];
        if (userReceivedAttestations.length == 0) {
            return 0;
        }

        // Aggregate unique skill IDs for the user
        mapping(bytes32 => bool) seenSkills;
        bytes32[] memory userSkills;
        for (uint256 i = 0; i < userReceivedAttestations.length; i++) {
            bytes32 skillId = attestations[userReceivedAttestations[i]].skillId;
            if (skillId != bytes32(0) && !seenSkills[skillId]) {
                seenSkills[skillId] = true;
                userSkills.push(skillId);
            }
        }

        if (userSkills.length == 0) {
            return 0;
        }

        uint256 totalReputationSum = 0;
        for (uint256 i = 0; i < userSkills.length; i++) {
            totalReputationSum += calculateSkillReputation(_user, userSkills[i]);
        }

        return uint8(totalReputationSum / userSkills.length);
    }

    /**
     * @notice Returns a list of a user's top N skills by calculated reputation score.
     *         This function can be gas-intensive for many skills/attestations.
     * @param _user The address of the user.
     * @param _limit The maximum number of top skills to return.
     * @return An array of Skill structs representing the top skills.
     */
    function getTopSkills(address _user, uint256 _limit) public view returns (bytes32[] memory topSkillIds) {
        bytes32[] memory userReceivedAttestations = recipientToAttestationIds[_user];
        if (userReceivedAttestations.length == 0) {
            return new bytes32[](0);
        }

        // Collect unique skills and their scores for the user
        mapping(bytes32 => uint8) skillScores;
        bytes32[] memory uniqueUserSkills;
        mapping(bytes32 => bool) seenSkills;

        for (uint256 i = 0; i < userReceivedAttestations.length; i++) {
            bytes32 skillId = attestations[userReceivedAttestations[i]].skillId;
            if (skillId != bytes32(0) && !seenSkills[skillId]) {
                uint8 score = calculateSkillReputation(_user, skillId);
                if (score > 0) {
                    seenSkills[skillId] = true;
                    uniqueUserSkills.push(skillId);
                    skillScores[skillId] = score;
                }
            }
        }

        // Simple bubble sort for demonstration (inefficient for large N, but simple)
        // In practice, for a large number of skills, this sorting would be done off-chain.
        for (uint256 i = 0; i < uniqueUserSkills.length; i++) {
            for (uint256 j = i + 1; j < uniqueUserSkills.length; j++) {
                if (skillScores[uniqueUserSkills[i]] < skillScores[uniqueUserSkills[j]]) {
                    bytes32 temp = uniqueUserSkills[i];
                    uniqueUserSkills[i] = uniqueUserSkills[j];
                    uniqueUserSkills[j] = temp;
                }
            }
        }

        uint256 numTopSkills = uniqueUserSkills.length < _limit ? uniqueUserSkills.length : _limit;
        topSkillIds = new bytes32[](numTopSkills);
        for (uint256 i = 0; i < numTopSkills; i++) {
            topSkillIds[i] = uniqueUserSkills[i];
        }

        return topSkillIds;
    }

    // --- III. Staking & Rewards ---

    /**
     * @notice Allows a user to deposit ERC20 tokens into the contract to be used as stake.
     *         Requires prior approval of the tokens for the contract.
     * @param _amount The amount of tokens to deposit.
     */
    function depositStake(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be greater than zero");
        reputationToken.transferFrom(msg.sender, address(this), _amount);
        userStakingBalances[msg.sender] += _amount;

        emit StakeDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to withdraw available (unlocked) ERC20 tokens from their internal balance.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawStake(uint256 _amount) public {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(userStakingBalances[msg.sender] >= _amount, "Insufficient available stake to withdraw");

        userStakingBalances[msg.sender] -= _amount;
        reputationToken.transfer(msg.sender, _amount);

        emit StakeWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Increases the staked amount on an existing attestation.
     *         The additional amount is deducted from the attester's available balance.
     * @param _attestationId The ID of the attestation.
     * @param _additionalAmount The amount of tokens to add to the stake.
     */
    function increaseAttestationStake(bytes32 _attestationId, uint256 _additionalAmount) public {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender, "Only attester can increase stake");
        require(!att.revoked, "Cannot increase stake on a revoked attestation");
        require(!att.disputed, "Cannot increase stake on a disputed attestation");
        require(att.issuanceTimestamp != 0, "Attestation does not exist");
        require(_additionalAmount > 0, "Additional stake must be greater than zero");
        require(userStakingBalances[msg.sender] >= _additionalAmount, "Insufficient available stake");

        userStakingBalances[msg.sender] -= _additionalAmount;
        att.stakedAmount += _additionalAmount;

        emit AttestationStakeIncreased(_attestationId, msg.sender, _additionalAmount);
    }

    /**
     * @notice Slashes a portion of the staked tokens from an attestation.
     *         This function is intended to be called by a dispute resolution mechanism.
     *         The slashed funds are typically sent to the dispute winner or a treasury.
     * @param _attestationId The ID of the attestation.
     * @param _amount The amount of tokens to slash.
     */
    function slashStake(bytes32 _attestationId, uint256 _amount) internal onlyDisputeResolver {
        Attestation storage att = attestations[_attestationId];
        require(att.issuanceTimestamp != 0, "Attestation does not exist");
        require(att.stakedAmount >= _amount, "Slash amount exceeds staked amount");

        att.stakedAmount -= _amount;
        // Slashed funds are held by the contract, and can be sent to winner during dispute resolution
        // or to a treasury. For simplicity here, they remain in the contract until explicitly transferred.
        // A more complex system would specify where the slashed tokens go.

        emit StakeSlashed(_attestationId, att.recipient, _amount);
    }

    // --- IV. Dispute Resolution ---

    /**
     * @notice Initiates a dispute against an attestation. Requires a bond.
     * @param _attestationId The ID of the attestation to dispute.
     * @param _reasonUri URI pointing to the details of the dispute (e.g., IPFS hash).
     */
    function initiateDispute(bytes32 _attestationId, string memory _reasonUri) public {
        Attestation storage att = attestations[_attestationId];
        require(att.issuanceTimestamp != 0, "Attestation does not exist");
        require(!att.revoked, "Cannot dispute a revoked attestation");
        require(!att.disputed, "Attestation is already under dispute");
        require(att.stakedAmount > 0, "Attestation has no stake to dispute");

        uint256 bondAmount = (att.stakedAmount * DISPUTE_BOND_PERCENTAGE) / 100;
        require(userStakingBalances[msg.sender] >= bondAmount, "Insufficient bond for dispute");

        userStakingBalances[msg.sender] -= bondAmount; // Lock dispute bond
        att.disputed = true;

        disputes[_attestationId] = Dispute({
            attestationId: _attestationId,
            initiator: msg.sender,
            reasonUri: _reasonUri,
            bondAmount: bondAmount,
            resolved: false,
            attestationFoundValid: false, // Default value, updated upon resolution
            winnerAddress: address(0),    // Default value, updated upon resolution
            initiationTimestamp: uint32(block.timestamp)
        });

        emit DisputeInitiated(_attestationId, msg.sender, bondAmount, _reasonUri);
    }

    /**
     * @notice Resolves a dispute for an attestation. Only callable by an authorized dispute resolver.
     *         If attestation is valid, attester's stake is safe, dispute initiator loses bond.
     *         If attestation is invalid, attester's stake is slashed, dispute initiator gets attester's slashed stake + their bond back.
     * @param _attestationId The ID of the attestation under dispute.
     * @param _isAttestationValid True if the attestation is deemed valid, false otherwise.
     * @param _stakeRecipient The address that receives the slashed stake if the attestation is found invalid.
     */
    function resolveDispute(bytes32 _attestationId, bool _isAttestationValid, address _stakeRecipient) public onlyDisputeResolver {
        Dispute storage dispute = disputes[_attestationId];
        require(dispute.initiationTimestamp != 0, "No dispute found for this attestation");
        require(!dispute.resolved, "Dispute already resolved");

        Attestation storage att = attestations[_attestationId];
        require(att.disputed, "Attestation is not marked as disputed");

        dispute.resolved = true;
        dispute.attestationFoundValid = _isAttestationValid;

        if (_isAttestationValid) {
            // Attestation is valid: attester wins, initiator loses bond
            dispute.winnerAddress = att.attester;
            // The dispute initiator's bond is effectively 'burned' or sent to treasury.
            // For this example, let's just make it unclaimable by the initiator.
            // A more complete system would send it to a DAO treasury.
        } else {
            // Attestation is invalid: attester loses stake, initiator wins bond and potentially attester's stake
            dispute.winnerAddress = dispute.initiator;
            uint256 slashedAmount = att.stakedAmount; // Slash the full stake
            slashStake(_attestationId, slashedAmount); // Internal call to slash

            // Transfer slashed amount to the specified recipient
            if (_stakeRecipient != address(0) && slashedAmount > 0) {
                reputationToken.transfer(_stakeRecipient, slashedAmount);
            }
        }

        att.disputed = false; // Mark attestation as no longer disputed
        emit DisputeResolved(_attestationId, _isAttestationValid, dispute.winnerAddress);
    }

    /**
     * @notice Allows the winner of a resolved dispute to claim their bond.
     * @param _attestationId The ID of the attestation that was disputed.
     */
    function claimDisputeBond(bytes32 _attestationId) public {
        Dispute storage dispute = disputes[_attestationId];
        require(dispute.resolved, "Dispute not yet resolved");
        require(dispute.winnerAddress == msg.sender, "Only the winner can claim the bond");
        require(dispute.bondAmount > 0, "No bond to claim or already claimed");

        uint256 amountToClaim = dispute.bondAmount;
        dispute.bondAmount = 0; // Prevent double claims

        // Return bond to winner
        userStakingBalances[msg.sender] += amountToClaim;

        emit DisputeBondClaimed(_attestationId, msg.sender, amountToClaim);
    }

    // --- V. Profile & Metadata ---

    /**
     * @notice Allows a user to set their public profile URI (e.g., an IPFS link to their metadata).
     * @param _profileUri The URI pointing to the user's public profile data.
     */
    function setUserProfileUri(string memory _profileUri) public {
        userProfileUris[msg.sender] = _profileUri;
        emit UserProfileUriSet(msg.sender, _profileUri);
    }

    /**
     * @notice Retrieves the public profile URI for a given user.
     * @param _user The address of the user.
     * @return The profile URI string.
     */
    function getUserProfileUri(address _user) public view returns (string memory) {
        return userProfileUris[_user];
    }

    // --- VI. Advanced Concepts / Extensions ---

    /**
     * @notice Delegates permission to another address to make attestations on the delegator's behalf.
     *         Can be for specific skills or (if _skillIds is empty) all skills.
     * @param _delegatee The address to delegate permission to.
     * @param _skillIds An array of skill IDs for which permission is delegated. Empty array means all skills.
     * @param _duration The duration in seconds for which the delegation is valid (0 for no expiration).
     */
    function delegateAttestationPermission(address _delegatee, bytes32[] memory _skillIds, uint32 _duration) public {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");

        uint32 expiration = (_duration == 0) ? 0 : uint32(block.timestamp) + _duration;

        // If _skillIds is empty, means 'all skills' delegation.
        // We'll use a special skillId (bytes32(0)) to represent "all skills" delegation.
        // Otherwise, iterate and set for each specific skill.
        if (_skillIds.length == 0) {
            delegations[msg.sender][_delegatee][bytes32(0)] = Delegation({
                delegator: msg.sender,
                delegatee: _delegatee,
                skillIds: new bytes32[](0), // Empty array signals all skills
                expirationTimestamp: expiration
            });
        } else {
            for (uint256 i = 0; i < _skillIds.length; i++) {
                require(skills[_skillIds[i]].registrationTimestamp != 0, "Skill not registered");
                delegations[msg.sender][_delegatee][_skillIds[i]] = Delegation({
                    delegator: msg.sender,
                    delegatee: _delegatee,
                    skillIds: new bytes32[](1), // Store the specific skill
                    expirationTimestamp: expiration
                });
                delegations[msg.sender][_delegatee][_skillIds[i]].skillIds[0] = _skillIds[i];
            }
        }

        emit DelegationGranted(msg.sender, _delegatee, _skillIds, expiration);
    }

    /**
     * @notice Revokes previously granted attestation delegation permissions.
     * @param _delegatee The address whose delegation permissions are being revoked.
     * @param _skillIds An array of skill IDs for which permission is revoked. Empty array means all skills.
     */
    function revokeDelegation(address _delegatee, bytes32[] memory _skillIds) public {
        // If _skillIds is empty, revoke 'all skills' delegation or iterate over known delegations.
        if (_skillIds.length == 0) {
            // Revoke "all skills" delegation explicitly if it exists
            Delegation storage allSkillsDelegation = delegations[msg.sender][_delegatee][bytes32(0)];
            if (allSkillsDelegation.delegator != address(0)) {
                delete delegations[msg.sender][_delegatee][bytes32(0)];
            }
            // A more complex system might iterate all skill-specific delegations and delete them too.
            // For simplicity, this revokes the broad "all skills" permission.
        } else {
            for (uint256 i = 0; i < _skillIds.length; i++) {
                require(skills[_skillIds[i]].registrationTimestamp != 0, "Skill not registered");
                delete delegations[msg.sender][_delegatee][_skillIds[i]];
            }
        }
        emit DelegationRevoked(msg.sender, _delegatee, _skillIds);
    }

    /**
     * @notice Allows a delegated address to make an attestation on behalf of the delegator.
     *         The stake comes from the delegator's available balance.
     * @param _delegator The address that granted the delegation.
     * @param _recipient The address of the user whose skill is being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _score The score given to the skill (0-100).
     * @param _stakeAmount The amount of tokens to stake for this attestation.
     * @param _validityDuration The duration in seconds for which the attestation is valid (0 for no expiration).
     */
    function attestSkillAsDelegator(
        address _delegator,
        address _recipient,
        bytes32 _skillId,
        uint8 _score,
        uint256 _stakeAmount,
        uint32 _validityDuration
    ) public {
        require(_delegator != _recipient, "Cannot attest your own skill");
        require(skills[_skillId].registrationTimestamp != 0, "Skill not registered");
        require(_score > 0 && _score <= 100, "Score must be between 1 and 100");
        require(_stakeAmount >= MIN_STAKE_AMOUNT, "Stake amount below minimum");
        require(userStakingBalances[_delegator] >= _stakeAmount, "Insufficient available stake for delegator");

        // Check for specific skill delegation
        Delegation storage specificDelegation = delegations[_delegator][msg.sender][_skillId];
        bool hasSpecificDelegation = specificDelegation.delegator != address(0) &&
                                     (specificDelegation.expirationTimestamp == 0 || specificDelegation.expirationTimestamp > block.timestamp);

        // Check for all-skills delegation
        Delegation storage allSkillsDelegation = delegations[_delegator][msg.sender][bytes32(0)];
        bool hasAllSkillsDelegation = allSkillsDelegation.delegator != address(0) &&
                                      (allSkillsDelegation.expirationTimestamp == 0 || allSkillsDelegation.expirationTimestamp > block.timestamp);

        require(hasSpecificDelegation || hasAllSkillsDelegation, "Delegation not found or expired for this skill");

        bytes32 attestationId = keccak256(abi.encodePacked(_delegator, _recipient, _skillId, block.timestamp, msg.sender)); // Include delegatee in ID
        require(attestations[attestationId].issuanceTimestamp == 0, "Attestation ID collision or already exists");

        uint32 expiration = (_validityDuration == 0) ? 0 : uint32(block.timestamp) + _validityDuration;

        attestations[attestationId] = Attestation({
            attestationId: attestationId,
            attester: _delegator, // The delegator is the official attester
            recipient: _recipient,
            skillId: _skillId,
            score: _score,
            stakedAmount: _stakeAmount,
            issuanceTimestamp: uint32(block.timestamp),
            expirationTimestamp: expiration,
            revoked: false,
            disputed: false
        });

        userStakingBalances[_delegator] -= _stakeAmount; // Lock stake from delegator's balance

        attesterToAttestationIds[_delegator].push(attestationId);
        recipientToAttestationIds[_recipient].push(attestationId);
        skillIdToAttestationIds[_skillId].push(attestationId);

        emit AttestationMade(attestationId, _delegator, _recipient, _skillId, _score, _stakeAmount, expiration);
    }

    /**
     * @notice Assigns an existing skill to a specific category.
     * @param _skillId The ID of the skill to categorize.
     * @param _categoryId The ID of the category to assign.
     */
    function setSkillCategory(bytes32 _skillId, bytes32 _categoryId) public onlyOwner {
        require(skills[_skillId].registrationTimestamp != 0, "Skill not registered");
        require(skills[_skillId].categoryId != _categoryId, "Skill is already in this category");

        // If skill was in a previous category, it might need to be removed from that category's list.
        // For simplicity, we just update the skill's categoryId and push to the new category list.
        // A more robust system would involve removing from old array, which is gas-intensive.
        skills[_skillId].categoryId = _categoryId;
        if (_categoryId != bytes32(0)) {
            categoryIdToSkillIds[_categoryId].push(_skillId);
        }
        // No specific event for category change, as SkillRegistered already logs category.
        // Can add a SkillCategoryUpdated event if needed.
    }

    /**
     * @notice Retrieves a list of all skills that belong to a specific category.
     * @param _categoryId The ID of the category.
     * @return An array of skill IDs within that category.
     */
    function getSkillsByCategory(bytes32 _categoryId) public view returns (bytes32[] memory) {
        return categoryIdToSkillIds[_categoryId];
    }
}
```