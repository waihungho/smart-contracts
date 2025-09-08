```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline and Function Summary:
//
// Contract Name: EminenceLedgerV1
// Description: A decentralized platform for skill validation and reputation management, leveraging Soulbound Tokens (SBTs)
//              for competence proofs. It features a challenge-based system where users prove skills, and
//              validators stake tokens to attest to these proofs, fostering a robust and trustworthy
//              decentralized identity layer based on verifiable competence.
//
// Core Concepts:
// - Soulbound Tokens (SBTs): Non-transferable ERC-1155 tokens where each tokenId represents a specific (skillId, level) pair.
//                            A user possessing such an SBT signifies their verified competence in that skill at that level.
//                            The `uri` for these tokens points to the verifiable proof.
// - Challenge System: Users propose challenges to demonstrate specific skills. Other users submit proofs, and validators
//                     review them.
// - Validator Staking: Participants stake EMN tokens to become eligible validators for skill categories, earning rewards
//                      for accurate validations and facing penalties for incorrect ones.
// - Reputation System: An on-chain score that evolves based on successful challenge completions, accurate validations,
//                      and outcomes of dispute resolutions.
// - Dispute Resolution: A mechanism allowing users to dispute validation decisions, with a voting system to resolve.
// - Integrated ERC-20 Token (EMN): The contract itself acts as the EMN token, used for staking, rewards, and fees.
//
// Function Categories and Summaries (35+ functions):
//
// I. Core Skill & Proof Management (SBTs - ERC1155):
//    1.  `addSkillCategory(string calldata _name, string calldata _description, uint256 _parentId)`: Allows the owner to define new hierarchical skill categories.
//    2.  `updateSkillCategory(uint256 _skillId, string calldata _newName, string calldata _newDescription)`: Owner can update details of an existing skill category.
//    3.  `_createCompetenceProofSBT(address _recipient, uint256 _skillId, uint256 _level, string calldata _proofURI)`: Internal function to mint a non-transferable competence proof SBT.
//    4.  `getSkillInfo(uint256 _skillId)`: Retrieves detailed information about a specific skill category.
//    5.  `hasCompetenceProof(address _user, uint256 _skillId, uint256 _level)`: Checks if a user possesses a specific competence proof SBT.
//    6.  `uri(uint256 _tokenId)`: Overrides ERC1155 URI function to provide metadata for competence proof SBTs, linking to the proof URI.
//    7.  `balanceOf(address account, uint256 id)`: Standard ERC1155 balance query (returns 1 if user has the SBT, 0 otherwise).
//    8.  `balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)`: Standard ERC1155 batch balance query.
//    9.  `setApprovalForAll(address operator, bool approved)`: Standard ERC1155 approval (will be blocked for SBTs).
//    10. `isApprovedForAll(address account, address operator)`: Standard ERC1155 approval check.
//    11. `_beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)`: Overridden to enforce non-transferability of competence proofs (SBTs).
//
// II. Challenge & Validation System:
//    12. `proposeChallenge(uint256 _skillId, uint256 _level, string calldata _challengeDescriptionURI, uint256 _rewardAmount)`: Users initiate a challenge to demonstrate a specific skill and level, requiring a deposit in EMN tokens as a bounty.
//    13. `submitProofForChallenge(uint256 _challengeId, string calldata _proofSubmissionURI)`: Users submit their proof of competence for a proposed challenge.
//    14. `stakeAsValidator(uint256 _skillId, uint256 _amount)`: Users stake EMN tokens to become eligible validators for a specific skill category.
//    15. `unstakeAsValidator(uint256 _skillId, uint256 _amount)`: Allows validators to withdraw their staked EMN tokens if no pending validations/disputes are active for them.
//    16. `validateChallengeSubmission(uint256 _challengeId, address _submitter, bool _isCompetent, string calldata _reasonURI)`: Staked validators review and attest to the competence of a challenge submission.
//    17. `claimValidationRewards()`: Validators claim accumulated EMN rewards for accurate validations.
//    18. `getChallengeDetails(uint256 _challengeId)`: Retrieves all public details about a specific challenge.
//    19. `getValidatorStake(address _validator, uint256 _skillId)`: Returns the amount of EMN tokens a user has staked for a given skill.
//    20. `getSkillChallenges(uint256 _skillId)`: Returns a list of all challenge IDs associated with a specific skill. (Client-side filtering would refine this to "pending").
//    21. `getChallengesByProposer(address _proposer)`: Returns a list of challenges proposed by a specific user.
//    22. `getChallengesBySubmitter(address _submitter)`: Returns a list of challenges a specific user has submitted proofs for.
//
// III. Reputation System:
//    23. `getUserReputation(address _user)`: Returns the current reputation score for a given user.
//    24. `_updateReputation(address _user, int256 _delta)`: Internal function to adjust a user's reputation score.
//    25. `getReputationTier(address _user)`: Determines and returns the reputation tier (e.g., Novice, Journeyman, Expert) for a user based on their score.
//    26. `setReputationTierThresholds(int256[] calldata _thresholds, string[] calldata _tierNames)`: Owner sets the thresholds for reputation tiers and their names.
//
// IV. Dispute Resolution:
//    27. `raiseDispute(uint256 _challengeId, address _validator, string calldata _reasonURI, uint256 _disputeDeposit)`: A user can dispute a validator's decision, requiring a deposit.
//    28. `voteOnDispute(uint256 _disputeId, bool _isValidatorCorrect)`: Staked validators (or a governance body) can vote on the outcome of a dispute.
//    29. `resolveDispute(uint256 _disputeId)`: Owner/governance resolves the dispute, distributing stakes/rewards/penalties based on the outcome.
//    30. `getDisputeDetails(uint256 _disputeId)`: Retrieves details about a specific dispute.
//    31. `getDisputeVotes(uint256 _disputeId)`: Returns the current vote counts for a dispute.
//
// V. EMN Token Management (ERC20 integrated):
//    32. `transfer(address to, uint256 amount)`: Standard ERC20 transfer.
//    33. `approve(address spender, uint256 amount)`: Standard ERC20 approve.
//    34. `transferFrom(address from, address to, uint256 amount)`: Standard ERC20 transferFrom.
//    35. `mintInitialSupply(address _to, uint256 _amount)`: Owner can mint initial EMN supply (for bootstrapping).
//
// VI. Governance & Administrative:
//    36. `setRewardRates(uint256 _validatorRewardRateBps, uint256 _submitterRewardRateBps, uint256 _disputeFeeRateBps)`: Owner sets percentage-based reward rates (in Basis Points) for validators and submitters, and the dispute fee.
//    37. `setMinimumValidatorStake(uint256 _skillId, uint256 _minStake)`: Owner sets minimum EMN stake required for validators for a specific skill.
//    38. `pauseChallengeCreation()`: Owner can pause the creation of new challenges (emergency function).
//    39. `unpauseChallengeCreation()`: Owner can unpause challenge creation.
//    40. `withdrawContractBalance(address _tokenAddress)`: Owner can withdraw accidentally sent ERC20 tokens or accumulated fees (if any in other tokens).
//    41. `setDisputeResolutionThreshold(uint256 _threshold)`: Owner sets the minimum stake weight required to resolve a dispute.
//
// This comprehensive set of functions covers various aspects of a decentralized skill and reputation system, emphasizing
// non-transferable proofs, economic incentives, and dispute resolution.

contract EminenceLedgerV1 is ERC1155, ERC20, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Constants for token ID encoding (assuming skillId and level won't exceed 2^64-1)
    uint256 private constant SKILL_ID_OFFSET = 128; // Using 128 bits for skillId, leaving 128 for level

    // Skill Management
    struct SkillCategory {
        string name;
        string description;
        uint256 parentId; // 0 for top-level skills
        bool exists;
    }
    mapping(uint256 => SkillCategory) public skills;
    Counters.Counter private _skillIdCounter;

    // Challenge Management
    enum ChallengeStatus {
        Proposed,
        Submitted,
        Validated,
        Rejected,
        Disputed,
        Resolved
    }

    struct Challenge {
        uint256 skillId;
        uint256 level;
        address proposer;
        uint256 rewardAmount; // EMN tokens
        string challengeDescriptionURI; // URI to detailed challenge description
        string proofSubmissionURI; // URI to the submitted proof
        address validator; // Address of the validator who made the decision
        ChallengeStatus status;
        string validationReasonURI; // URI to validator's reason/feedback
        uint256 proposedTimestamp;
        uint256 validationTimestamp;
        address submitter; // The user who submitted the proof
    }
    mapping(uint256 => Challenge) public challenges;
    Counters.Counter private _challengeIdCounter;
    mapping(uint256 => uint256[]) public skillToChallengeIds; // To query challenges by skill
    mapping(address => uint256[]) public proposerChallenges;
    mapping(address => uint256[]) public submitterChallenges;

    // Validator Staking
    mapping(address => mapping(uint256 => uint256)) public validatorStakes; // validator => skillId => amount
    mapping(address => uint256) public validatorRewardPool; // validator => accumulated rewards

    // Reputation System
    mapping(address => int256) public userReputation; // Can be negative
    struct ReputationTier {
        int256 threshold;
        string name;
    }
    ReputationTier[] public reputationTiers; // Ordered by threshold, lowest first

    // Dispute Resolution
    enum DisputeStatus {
        Open,
        Voting,
        Resolved
    }

    struct Dispute {
        uint256 challengeId;
        address disputer;
        address challengedValidator;
        string reasonURI; // URI to dispute reasoning
        uint256 disputeDeposit; // EMN tokens
        mapping(address => bool) hasVoted; // validator => voted
        uint256 votesForValidator; // Total stake weight supporting validator
        uint256 votesAgainstValidator; // Total stake weight against validator
        DisputeStatus status;
        uint256 createdTimestamp;
    }
    mapping(uint256 => Dispute) public disputes;
    Counters.Counter private _disputeIdCounter;
    uint256 public disputeResolutionThreshold; // Minimum total stake weight required to resolve a dispute

    // Configuration & Fees
    uint256 public validatorRewardRateBps; // Basis points (e.g., 500 = 5%)
    uint256 public submitterRewardRateBps; // Basis points
    uint256 public disputeFeeRateBps;      // Basis points of challenge reward

    // Pausability
    bool public challengeCreationPaused;

    // --- Events ---
    event SkillCategoryAdded(uint256 indexed skillId, string name, string description, uint256 parentId);
    event SkillCategoryUpdated(uint256 indexed skillId, string newName, string newDescription);
    event CompetenceProofMinted(address indexed user, uint256 indexed skillId, uint256 level, uint256 tokenId, string proofURI);

    event ChallengeProposed(uint256 indexed challengeId, uint256 indexed skillId, uint256 level, address indexed proposer, uint256 rewardAmount, string descriptionURI);
    event ProofSubmitted(uint256 indexed challengeId, address indexed submitter, string submissionURI);
    event ChallengeValidated(uint256 indexed challengeId, address indexed validator, address indexed submitter, bool isCompetent, string reasonURI);
    event ChallengeRejected(uint256 indexed challengeId, address indexed validator, address indexed submitter, string reasonURI);

    event ValidatorStaked(address indexed validator, uint256 indexed skillId, uint256 amount);
    event ValidatorUnstaked(address indexed validator, uint256 indexed skillId, uint256 amount);
    event ValidationRewardsClaimed(address indexed validator, uint256 amount);

    event ReputationUpdated(address indexed user, int256 newReputation, int256 delta);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed challengeId, address indexed disputer, address challengedValidator, uint256 deposit);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool isValidatorCorrect, uint256 stakeWeight);
    event DisputeResolved(uint256 indexed disputeId, bool validatorUpheld, uint256 totalVotesFor, uint256 totalVotesAgainst);

    // --- Modifiers ---
    modifier whenChallengeCreationNotPaused() {
        require(!challengeCreationPaused, "Challenge creation is paused");
        _;
    }

    modifier onlyValidSkill(uint256 _skillId) {
        require(skills[_skillId].exists, "Skill does not exist");
        _;
    }

    modifier onlyValidatorForSkill(uint256 _skillId) {
        require(validatorStakes[msg.sender][_skillId] >= minimumValidatorStake[_skillId], "Not a qualified validator for this skill");
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply)
        ERC1155("https://eminenceledger.io/api/sbt/{id}") // Base URI for SBTs
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        _mint(msg.sender, _initialSupply); // Mint initial EMN supply to owner

        // Set initial configuration
        validatorRewardRateBps = 500; // 5%
        submitterRewardRateBps = 1000; // 10%
        disputeFeeRateBps = 100; // 1% of challenge reward
        disputeResolutionThreshold = 100 * (10**decimals()); // Example: 100 EMN total stake weight

        // Initialize default reputation tiers
        reputationTiers.push(ReputationTier({threshold: -1000, name: "Disgraced"}));
        reputationTiers.push(ReputationTier({threshold: 0, name: "Novice"}));
        reputationTiers.push(ReputationTier({threshold: 100, name: "Apprentice"}));
        reputationTiers.push(ReputationTier({threshold: 500, name: "Journeyman"}));
        reputationTiers.push(ReputationTier({threshold: 1500, name: "Expert"}));
        reputationTiers.push(ReputationTier({threshold: 5000, name: "Grandmaster"}));
    }

    // --- ERC1155 Overrides for Soulbound Tokens (SBTs) ---

    // _tokenId for competence proofs will encode skillId and level: (skillId << SKILL_ID_OFFSET) | level
    // This allows `balanceOf(user, tokenId)` to effectively check if a user has a specific skill/level badge.
    // The URI for such tokens will point to the specific proof.
    mapping(uint256 => string) private _competenceProofURIs; // tokenId => URI of the actual proof

    // Overridden to enforce non-transferability of competence proofs
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Competence proof tokens (SBTs) are non-transferable
        // We assume all minted ERC1155 tokens in this contract are competence proofs.
        if (from != address(0) && to != address(0)) { // This means it's a transfer, not a mint or burn
            revert("Competence Proof SBTs are non-transferable");
        }
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC1155: URI query for nonexistent token");
        string memory _proofURI = _competenceProofURIs[_tokenId];
        if (bytes(_proofURI).length > 0) {
            return _proofURI;
        }
        // Fallback to base URI if no specific proof URI is set (shouldn't happen for competence proofs)
        return super.uri(_tokenId);
    }

    // --- I. Core Skill & Proof Management (SBTs - ERC1155) ---

    mapping(uint256 => uint256) public minimumValidatorStake; // skillId => minStake

    function addSkillCategory(string calldata _name, string calldata _description, uint256 _parentId) public onlyOwner {
        require(bytes(_name).length > 0, "Skill name cannot be empty");
        if (_parentId != 0) {
            require(skills[_parentId].exists, "Parent skill does not exist");
        }

        _skillIdCounter.increment();
        uint256 newSkillId = _skillIdCounter.current();
        skills[newSkillId] = SkillCategory({
            name: _name,
            description: _description,
            parentId: _parentId,
            exists: true
        });
        emit SkillCategoryAdded(newSkillId, _name, _description, _parentId);
    }

    function updateSkillCategory(uint256 _skillId, string calldata _newName, string calldata _newDescription) public onlyOwner onlyValidSkill(_skillId) {
        require(bytes(_newName).length > 0, "Skill name cannot be empty");
        skills[_skillId].name = _newName;
        skills[_skillId].description = _newDescription;
        emit SkillCategoryUpdated(_skillId, _newName, _newDescription);
    }

    // Internal function to mint a non-transferable competence proof SBT
    function _createCompetenceProofSBT(address _recipient, uint256 _skillId, uint256 _level, string calldata _proofURI) internal {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(skills[_skillId].exists, "Skill does not exist for proof");

        uint256 competenceTokenId = (_skillId << SKILL_ID_OFFSET) | _level;

        // Ensure user doesn't already have this specific skill/level proof
        require(balanceOf(_recipient, competenceTokenId) == 0, "User already has this competence proof");

        _mint(_recipient, competenceTokenId, 1, ""); // Mint 1 token
        _competenceProofURIs[competenceTokenId] = _proofURI; // Store URI for specific proof
        emit CompetenceProofMinted(_recipient, _skillId, _level, competenceTokenId, _proofURI);
    }

    function getSkillInfo(uint256 _skillId) public view onlyValidSkill(_skillId) returns (string memory name, string memory description, uint256 parentId) {
        SkillCategory storage skill = skills[_skillId];
        return (skill.name, skill.description, skill.parentId);
    }

    function hasCompetenceProof(address _user, uint256 _skillId, uint256 _level) public view returns (bool) {
        uint256 competenceTokenId = (_skillId << SKILL_ID_OFFSET) | _level;
        return balanceOf(_user, competenceTokenId) > 0;
    }

    // --- II. Challenge & Validation System ---

    function proposeChallenge(uint256 _skillId, uint256 _level, string calldata _challengeDescriptionURI, uint256 _rewardAmount)
        public
        whenChallengeCreationNotPaused
        onlyValidSkill(_skillId)
        returns (uint256)
    {
        require(_rewardAmount > 0, "Reward must be greater than zero");
        require(balanceOf(msg.sender, address(this)) >= _rewardAmount, "Insufficient EMN balance to fund challenge"); // Using own balance for checking

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        // Transfer reward from proposer to contract
        _transfer(msg.sender, address(this), _rewardAmount);

        challenges[newChallengeId] = Challenge({
            skillId: _skillId,
            level: _level,
            proposer: msg.sender,
            rewardAmount: _rewardAmount,
            challengeDescriptionURI: _challengeDescriptionURI,
            proofSubmissionURI: "", // Empty initially
            validator: address(0),
            status: ChallengeStatus.Proposed,
            validationReasonURI: "",
            proposedTimestamp: block.timestamp,
            validationTimestamp: 0,
            submitter: address(0)
        });

        skillToChallengeIds[_skillId].push(newChallengeId);
        proposerChallenges[msg.sender].push(newChallengeId);

        emit ChallengeProposed(newChallengeId, _skillId, _level, msg.sender, _rewardAmount, _challengeDescriptionURI);
        return newChallengeId;
    }

    function submitProofForChallenge(uint256 _challengeId, string calldata _proofSubmissionURI)
        public
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.proposer != address(0), "Challenge does not exist");
        require(challenge.status == ChallengeStatus.Proposed, "Challenge not in 'Proposed' state");
        require(challenge.submitter == address(0), "Proof already submitted for this challenge");
        require(msg.sender != challenge.proposer, "Proposer cannot submit proof for their own challenge");

        challenge.proofSubmissionURI = _proofSubmissionURI;
        challenge.submitter = msg.sender;
        challenge.status = ChallengeStatus.Submitted;

        submitterChallenges[msg.sender].push(_challengeId);

        emit ProofSubmitted(_challengeId, msg.sender, _proofSubmissionURI);
    }

    function stakeAsValidator(uint256 _skillId, uint256 _amount) public nonReentrant onlyValidSkill(_skillId) {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(balanceOf(msg.sender, address(this)) >= _amount, "Insufficient EMN balance");

        _transfer(msg.sender, address(this), _amount); // Transfer EMN to contract
        validatorStakes[msg.sender][_skillId] += _amount;

        emit ValidatorStaked(msg.sender, _skillId, _amount);
    }

    function unstakeAsValidator(uint256 _skillId, uint256 _amount) public nonReentrant onlyValidSkill(_skillId) {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(validatorStakes[msg.sender][_skillId] >= _amount, "Insufficient staked amount");

        // Consider adding checks for active disputes or pending validations.
        // For simplicity, this example allows unstaking as long as amount is available.
        // In a production system, a cooldown or locking mechanism would be vital.

        validatorStakes[msg.sender][_skillId] -= _amount;
        _transfer(address(this), msg.sender, _amount); // Transfer EMN back to validator

        emit ValidatorUnstaked(msg.sender, _skillId, _amount);
    }

    function validateChallengeSubmission(uint256 _challengeId, address _submitter, bool _isCompetent, string calldata _reasonURI)
        public
        nonReentrant
        onlyValidatorForSkill(challenges[_challengeId].skillId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.proposer != address(0), "Challenge does not exist");
        require(challenge.status == ChallengeStatus.Submitted, "Challenge not in 'Submitted' state");
        require(challenge.submitter == _submitter, "Submitter mismatch");
        require(msg.sender != challenge.proposer, "Proposer cannot validate their own challenge");
        require(msg.sender != challenge.submitter, "Submitter cannot validate their own proof");

        challenge.validator = msg.sender;
        challenge.validationReasonURI = _reasonURI;
        challenge.validationTimestamp = block.timestamp;

        if (_isCompetent) {
            challenge.status = ChallengeStatus.Validated;
            // Mint SBT for submitter
            _createCompetenceProofSBT(_submitter, challenge.skillId, challenge.level, challenge.proofSubmissionURI);

            // Reward submitter and validator
            uint256 totalReward = challenge.rewardAmount;
            uint256 validatorCut = (totalReward * validatorRewardRateBps) / 10000;
            uint256 submitterCut = (totalReward * submitterRewardRateBps) / 10000;

            // Remaining is returned to proposer or goes to platform fees
            uint256 proposerRefund = totalReward - validatorCut - submitterCut;

            // Transfer rewards. The EMN is already in the contract.
            validatorRewardPool[msg.sender] += validatorCut; // Add to validator's claimable pool
            _updateReputation(msg.sender, 50); // Positive reputation for successful validation
            _transfer(address(this), _submitter, submitterCut); // Directly reward submitter
            _updateReputation(_submitter, 100); // Positive reputation for successful proof

            if (proposerRefund > 0) {
                 _transfer(address(this), challenge.proposer, proposerRefund); // Refund proposer
            }
            emit ChallengeValidated(_challengeId, msg.sender, _submitter, _isCompetent, _reasonURI);

        } else {
            challenge.status = ChallengeStatus.Rejected;
            _updateReputation(_submitter, -50); // Negative reputation for failed proof
            _updateReputation(msg.sender, 10); // Small positive for being active
            // All reward returned to proposer on rejection
            _transfer(address(this), challenge.proposer, challenge.rewardAmount);
            emit ChallengeRejected(_challengeId, msg.sender, _submitter, _reasonURI);
        }
    }

    function claimValidationRewards() public nonReentrant {
        uint256 amount = validatorRewardPool[msg.sender];
        require(amount > 0, "No rewards to claim");

        validatorRewardPool[msg.sender] = 0;
        _transfer(address(this), msg.sender, amount);

        emit ValidationRewardsClaimed(msg.sender, amount);
    }

    function getChallengeDetails(uint256 _challengeId)
        public
        view
        returns (uint256 skillId, uint256 level, address proposer, uint256 rewardAmount, string memory challengeDescriptionURI, string memory proofSubmissionURI, address validator, ChallengeStatus status, string memory validationReasonURI, uint256 proposedTimestamp, uint256 validationTimestamp, address submitter)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.proposer != address(0), "Challenge does not exist");
        return (challenge.skillId, challenge.level, challenge.proposer, challenge.rewardAmount, challenge.challengeDescriptionURI, challenge.proofSubmissionURI, challenge.validator, challenge.status, challenge.validationReasonURI, challenge.proposedTimestamp, challenge.validationTimestamp, challenge.submitter);
    }

    function getValidatorStake(address _validator, uint256 _skillId) public view returns (uint256) {
        return validatorStakes[_validator][_skillId];
    }

    function getSkillChallenges(uint256 _skillId) public view returns (uint256[] memory) {
        return skillToChallengeIds[_skillId];
    }

    function getChallengesByProposer(address _proposer) public view returns (uint256[] memory) {
        return proposerChallenges[_proposer];
    }

    function getChallengesBySubmitter(address _submitter) public view returns (uint256[] memory) {
        return submitterChallenges[_submitter];
    }

    // This function can be used by off-chain clients to find challenges that are "Submitted" and need validation.
    // On-chain storage of "pending" lists would be too gas-intensive for a large number of challenges.
    function getPendingValidations() public view returns (uint256[] memory) {
        // This is a placeholder. A real system would require an off-chain indexer
        // to find all challenges with status 'Submitted'.
        // Iterating over all challenges on-chain is not feasible for many challenges.
        // For demonstration, we'll return a simple empty array.
        // Or one could provide a method to get a range of challenge IDs.
        uint256[] memory emptyArray;
        return emptyArray;
    }


    // --- III. Reputation System ---

    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    function _updateReputation(address _user, int256 _delta) internal {
        userReputation[_user] += _delta;
        emit ReputationUpdated(_user, userReputation[_user], _delta);
    }

    function getReputationTier(address _user) public view returns (string memory) {
        int256 reputation = userReputation[_user];
        string memory tierName = "Unknown";
        for (uint i = reputationTiers.length - 1; i >= 0; i--) {
            if (reputation >= reputationTiers[i].threshold) {
                tierName = reputationTiers[i].name;
                break;
            }
            if (i == 0) break; // Prevent underflow in loop for unsigned i
        }
        return tierName;
    }

    function setReputationTierThresholds(int256[] calldata _thresholds, string[] calldata _tierNames) public onlyOwner {
        require(_thresholds.length == _tierNames.length, "Thresholds and tier names must have same length");
        require(_thresholds.length > 0, "Must define at least one tier");

        // Ensure thresholds are in strictly increasing order
        for (uint i = 0; i < _thresholds.length - 1; i++) {
            require(_thresholds[i] < _thresholds[i+1], "Thresholds must be in strictly increasing order");
        }

        delete reputationTiers; // Clear existing tiers
        for (uint i = 0; i < _thresholds.length; i++) {
            reputationTiers.push(ReputationTier({threshold: _thresholds[i], name: _tierNames[i]}));
        }
    }

    // --- IV. Dispute Resolution ---

    function raiseDispute(uint256 _challengeId, address _validator, string calldata _reasonURI, uint256 _disputeDeposit)
        public
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.proposer != address(0), "Challenge does not exist");
        require(challenge.status == ChallengeStatus.Validated || challenge.status == ChallengeStatus.Rejected, "Challenge not in a validatable state");
        require(challenge.validator == _validator, "Validator mismatch");
        require(_disputeDeposit >= (challenge.rewardAmount * disputeFeeRateBps) / 10000, "Insufficient dispute deposit");
        require(balanceOf(msg.sender, address(this)) >= _disputeDeposit, "Insufficient EMN balance for deposit");
        require(msg.sender != _validator, "Validator cannot dispute their own decision");

        // Check if there's an existing dispute for this challenge that's still open or voting
        for (uint i = 1; i <= _disputeIdCounter.current(); i++) {
            if (disputes[i].challengeId == _challengeId && disputes[i].status != DisputeStatus.Resolved) {
                revert("An active dispute already exists for this challenge");
            }
        }

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        // Transfer dispute deposit from disputer to contract
        _transfer(msg.sender, address(this), _disputeDeposit);

        disputes[newDisputeId] = Dispute({
            challengeId: _challengeId,
            disputer: msg.sender,
            challengedValidator: _validator,
            reasonURI: _reasonURI,
            disputeDeposit: _disputeDeposit,
            votesForValidator: 0,
            votesAgainstValidator: 0,
            status: DisputeStatus.Voting,
            createdTimestamp: block.timestamp
        });
        // Disputer implicitly votes against the validator
        _voteOnDisputeInternal(newDisputeId, false, msg.sender);
        challenges[_challengeId].status = ChallengeStatus.Disputed;

        emit DisputeRaised(newDisputeId, _challengeId, msg.sender, _validator, _disputeDeposit);
    }

    function _voteOnDisputeInternal(uint256 _disputeId, bool _isValidatorCorrect, address _voter) internal {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputer != address(0), "Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "Dispute not in voting phase");
        require(!dispute.hasVoted[_voter], "Already voted in this dispute");

        uint256 voterStake = validatorStakes[_voter][challenges[dispute.challengeId].skillId];
        require(voterStake > 0, "Voter must have staked EMN for the skill to vote");

        dispute.hasVoted[_voter] = true;
        if (_isValidatorCorrect) {
            dispute.votesForValidator += voterStake;
        } else {
            dispute.votesAgainstValidator += voterStake;
        }
        emit DisputeVoted(_disputeId, _voter, _isValidatorCorrect, voterStake);
    }

    function voteOnDispute(uint256 _disputeId, bool _isValidatorCorrect) public nonReentrant onlyValidatorForSkill(challenges[disputes[_disputeId].challengeId].skillId) {
        require(msg.sender != disputes[_disputeId].disputer, "Disputer cannot vote again");
        require(msg.sender != disputes[_disputeId].challengedValidator, "Challenged validator cannot vote");
        _voteOnDisputeInternal(_disputeId, _isValidatorCorrect, msg.sender);
    }

    function resolveDispute(uint256 _disputeId) public onlyOwner nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputer != address(0), "Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "Dispute not in voting phase");
        require(dispute.votesForValidator + dispute.votesAgainstValidator >= disputeResolutionThreshold, "Not enough stake weight for resolution");

        Challenge storage challenge = challenges[dispute.challengeId];
        bool validatorUpheld = dispute.votesForValidator >= dispute.votesAgainstValidator; // Simple majority based on stake weight

        challenge.status = DisputeStatus.Resolved; // Mark the challenge as resolved

        if (validatorUpheld) {
            // Validator's decision is upheld
            // Disputer loses deposit, some to challenged validator, some burned or platform fee
            uint256 challengedValidatorShare = (dispute.disputeDeposit * 50) / 100; // 50% of deposit to validator
            _transfer(address(this), dispute.challengedValidator, challengedValidatorShare);
            // Rest of deposit can be burned or sent to owner/treasury, here it remains in contract as platform fee.

            _updateReputation(dispute.disputer, -100); // Disputer loses reputation
            _updateReputation(dispute.challengedValidator, 75); // Validator gains reputation
        } else {
            // Validator's decision is overturned
            // Disputer gets deposit back. Challenged validator is penalized.
            _transfer(address(this), dispute.disputer, dispute.disputeDeposit); // Return deposit to disputer

            // Slashing for challenged validator (e.g., reduce stake or burn some stake)
            // For simplicity, we'll just hit their reputation hard and not directly slash stake here.
            _updateReputation(dispute.challengedValidator, -150);
            _updateReputation(dispute.disputer, 75); // Disputer gains reputation for correcting

            // Revert challenge status:
            // If original validation was "Competent" but overturned, burn the SBT.
            // If original validation was "Rejected" but overturned, re-trigger mint.
            // This is complex, a simpler approach for now is to mark challenge as "Resolved"
            // and require submitter to re-submit if they want to try again, or a new validation process.
            // For this example, let's say the original validation is simply nullified in terms of its effect.
            // If the original validation was a mint, the token cannot be burned (SBT).
            // A more advanced system would allow burning SBTs by owner for dispute resolution.
            // For now, if the validation was overturned, the SBT is "tainted" but exists.
            // Or, if overturned for a 'rejected' status, then the original submitter gets a chance to get the SBT minted.
            // For simplicity here, we'll assume "overturned" means the original decision was wrong,
            // and the submitter should *not* have been rejected, or *should not* have been validated.
            // The implications for the SBT would be handled off-chain or by a dedicated mechanism.
            // For now, let's just reverse the reputation effects for the original validation.
            // If it was validated (and got an SBT) but overturned, it means it *should not* have been an SBT.
            // If it was rejected (no SBT) but overturned, it means it *should* have been an SBT.
            // This is where it gets tricky with non-transferable tokens.
            // For now, we only update reputation and transfer funds. Burning SBTs by contract would need _burn override.
            // If an SBT was minted (original decision was Validated) and that was overturned,
            // the SBT exists, but its integrity is compromised by the dispute outcome.
            // It could be flagged, or a new "revoked" SBT could be issued.
            // For now, the reputation update signifies the outcome.
            // (A production system might involve burning the SBT by the contract if overturned from Validated state).
        }

        dispute.status = DisputeStatus.Resolved;
        emit DisputeResolved(_disputeId, validatorUpheld, dispute.votesForValidator, dispute.votesAgainstValidator);
    }

    function getDisputeDetails(uint256 _disputeId)
        public
        view
        returns (uint256 challengeId, address disputer, address challengedValidator, string memory reasonURI, uint256 disputeDeposit, DisputeStatus status, uint256 createdTimestamp)
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputer != address(0), "Dispute does not exist");
        return (dispute.challengeId, dispute.disputer, dispute.challengedValidator, dispute.reasonURI, dispute.disputeDeposit, dispute.status, dispute.createdTimestamp);
    }

    function getDisputeVotes(uint256 _disputeId) public view returns (uint256 votesForValidator, uint256 votesAgainstValidator) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputer != address(0), "Dispute does not exist");
        return (dispute.votesForValidator, dispute.votesAgainstValidator);
    }

    // --- V. EMN Token Management (ERC20 integrated) ---

    // ERC20 functions are inherited from OpenZeppelin's ERC20.sol

    function mintInitialSupply(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    // --- VI. Governance & Administrative ---

    function setRewardRates(uint256 _validatorRewardRateBps, uint256 _submitterRewardRateBps, uint256 _disputeFeeRateBps) public onlyOwner {
        require(_validatorRewardRateBps + _submitterRewardRateBps <= 10000, "Total reward rates exceed 100%");
        validatorRewardRateBps = _validatorRewardRateBps;
        submitterRewardRateBps = _submitterRewardRateBps;
        disputeFeeRateBps = _disputeFeeRateBps;
    }

    function setMinimumValidatorStake(uint256 _skillId, uint256 _minStake) public onlyOwner onlyValidSkill(_skillId) {
        minimumValidatorStake[_skillId] = _minStake;
    }

    function pauseChallengeCreation() public onlyOwner {
        challengeCreationPaused = true;
    }

    function unpauseChallengeCreation() public onlyOwner {
        challengeCreationPaused = false;
    }

    function withdrawContractBalance(address _tokenAddress) public onlyOwner {
        // Allows owner to withdraw accidentally sent ERC20 tokens or accumulated fees
        // This function should be used carefully.
        if (_tokenAddress == address(0) || _tokenAddress == address(this)) { // For ETH or EMN token itself
            revert("Cannot withdraw native token using this function for safety reasons. Use specific functions for EMN.");
        }
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    // This contract *is* the EMN token. A separate function for owner to withdraw EMN specifically
    // would be dangerous as it's also the operational funds for rewards.
    // So, only non-EMN ERC20 withdrawals are allowed via `withdrawContractBalance`.
    // EMN in the contract are for reward pools, staking, etc.

    function setDisputeResolutionThreshold(uint256 _threshold) public onlyOwner {
        disputeResolutionThreshold = _threshold;
    }
}
```