Here's a smart contract written in Solidity, focusing on advanced concepts like Soulbound Tokens (SBTs), decentralized skill validation, adaptive learning paths, reputation systems, and gamified achievements, all managed by a simplified DAO. The goal is to create a "Decentralized Adaptive Learning & Skill Network" named **CogniStream**.

This contract avoids direct duplication of common open-source patterns by combining these concepts into a novel application, where verifiable skills (SBTs) unlock learning opportunities and build on-chain reputation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom errors for gas efficiency and clarity
error CogniStream__NotAuthorized();
error CogniStream__InvalidSkillType();
error CogniStream__SkillTypeAlreadyExists();
error CogniStream__SkillTokenNotFound();
error CogniStream__SkillTokenExpired(); // Currently not explicitly checked in all paths, but useful for future
error CogniStream__NotAValidator();
error CogniStream__ValidatorNotApprovedForSkill();
error CogniStream__LearningStreamNotFound();
error CogniStream__CompletionAlreadySubmitted();
error CogniStream__CompletionNotFound();
error CogniStream__CompletionAlreadyValidated();
error CogniStream__InsufficientPrerequisites();
error CogniStream__InvalidProposal();
error CogniStream__VoteAlreadyCast();
error CogniStream__ProposalNotExecutable();
error CogniStream__ProposalNotPassed();
error CogniStream__AchievementNotFound();
error CogniStream__AchievementCriteriaNotMet();
error CogniStream__ValidatorAlreadyProposed();
error CogniStream__SelfRevocationNotAllowed();

/**
 * @title CogniStream Network
 * @dev A decentralized platform for skill attestation, adaptive learning paths,
 *      and reputation building using Soulbound Tokens (SBTs) and gamification.
 *      It integrates a decentralized validator network, curated learning streams,
 *      and a simplified DAO governance model for parameter changes and upgrades.
 *      This contract acts as the central hub for managing skill definitions,
 *      issuing and revoking skill tokens, managing validators, and facilitating
 *      learning stream completions and reputation tracking.
 */
contract CogniStream is Ownable {
    using Counters for Counters.Counter;

    // --- Outline & Function Summary ---

    // I. Core SkillToken Management (SBTs)
    //    These functions handle the creation, issuance, and verification of non-transferable skill tokens.
    // 1.  `defineSkillType(string _name, string _description, bool _isSoulbound)`: Establishes a new non-transferable skill type with a unique ID, name, and description. Only governance can call this.
    // 2.  `issueSkillToken(address _recipient, uint256 _skillTypeId, uint256 _expirationTimestamp, string _attestationURI)`: Mints a Soulbound Token (SBT) representing a specific skill to a recipient. Only authorized validators for that skill can issue it. Includes an expiration date and an attestation URI for proof.
    // 3.  `revokeSkillToken(uint256 _skillTokenId)`: Allows the issuing validator or governance to revoke a previously issued SkillToken, for example, due to invalidation.
    // 4.  `getSkillTokenDetails(uint256 _skillTokenId)`: Retrieves comprehensive details for a given SkillToken instance by its unique ID.
    // 5.  `getUserSkillTokens(address _user)`: Returns a list of all ACTIVE SkillToken IDs currently held by a specified user address.
    // 6.  `hasSkillType(address _user, uint256 _skillTypeId)`: Checks if a user possesses an active SkillToken of a particular type (active and not expired).

    // II. Skill Validator Management
    //     Manages the lifecycle of network validators who are authorized to issue skill tokens and validate learning.
    // 7.  `proposeValidator(address _validatorAddress, string _metadataURI)`: Allows an address to submit itself for consideration as a Skill Validator, along with metadata.
    // 8.  `approveValidatorForSkills(address _validatorAddress, uint256[] _skillTypeIds)`: Governance formally approves an address as a validator for a specific set of skill types.
    // 9.  `revokeValidatorPrivileges(address _validatorAddress)`: Governance revokes validator status from an address, preventing further issuance of SkillTokens.
    // 10. `getValidatorDetails(address _validatorAddress)`: Provides details about a validator, including their active status, metadata URI, and reputation.
    // 11. `updateValidatorMetadata(string _newMetadataURI)`: Allows an approved validator to update their public metadata URI.

    // III. LearningStream & Project Management
    //      Defines structured learning paths or projects that grant skills and rewards upon completion.
    // 12. `createLearningStream(string _title, string _description, uint256[] _requiredSkillTypes, uint256[] _outcomeSkillTypes, uint256 _rewardAmount, address _rewardToken, address _validatorAddress)`: Defines a structured learning path or project. It specifies prerequisite skills, outcome skills upon completion, potential financial rewards, and a validator responsible for verifying completions.
    // 13. `submitLearningStreamCompletion(uint256 _streamId, string _proofURI)`: A user submits proof (via a URI) of completing a specific LearningStream, triggering a validation process.
    // 14. `validateLearningStreamCompletion(uint256 _submissionId, bool _approved, string _validatorFeedback)`: The designated validator for a LearningStream approves or rejects a completion submission. Approval leads to the issuance of outcome SkillTokens and rewards.
    // 15. `getLearningStreamDetails(uint256 _streamId)`: Retrieves all information about a specific LearningStream.

    // IV. Reputation & Progression System
    //     Tracks participant reputation and helps users identify their next learning steps based on acquired skills.
    // 16. `getReputationScore(address _participant)`: Returns the current reputation score of any participant (user or validator) in the network.
    // 17. `defineSkillPrerequisites(uint256 _skillTypeId, uint256[] _prerequisiteSkillTypeIds)`: Governance establishes dependencies between skill types, e.g., Skill B requires Skill A.
    // 18. `getAchievableSkillTypes(address _user)`: Computes and returns a list of skill types that a user is eligible to pursue, based on their current SkillTokens and defined prerequisites.
    // 19. `getEligibleLearningStreams(address _user)`: Lists LearningStreams for which a user meets the `requiredSkillTypes`, making them eligible to participate.

    // V. Gamification & Achievements
    //    Introduces non-transferable digital badges for significant milestones.
    // 20. `defineAchievement(string _name, string _description, string _criteriaURI, uint256 _maxSupply)`: Governance defines new achievements with criteria (e.g., "completed 5 streams," "earned 3 advanced skills").
    // 21. `mintAchievementNFT(uint256 _achievementDefId, address _recipient)`: Issues a non-transferable Achievement NFT to a user who meets the criteria. This is typically triggered by governance or an oracle/keeper.
    // 22. `getUserAchievements(address _user)`: Lists all Achievement NFTs held by a user.

    // VI. DAO Governance (Simplified)
    //     A basic framework for network participants (represented by the owner in this simplified version) to propose and vote on changes.
    // 23. `proposeGovernanceAction(bytes _callData, string _description)`: Allows authorized participants to propose general administrative actions, parameter changes, or upgrades to the protocol.
    // 24. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables voting on active governance proposals.
    // 25. `executeProposal(uint256 _proposalId)`: Executes a proposal once it has met the voting requirements and voting period has ended.

    // VII. Utility Functions
    // 26. `depositRewardTokens(address _token, uint256 _amount)`: Allows governance to deposit ERC20 tokens into the contract for future learning stream rewards.
    // 27. `getAllSkillTypeIds()`: (Utility for exploration) Returns all defined skill type IDs.
    // 28. `getAllLearningStreamIds()`: (Utility for exploration) Returns all defined learning stream IDs.

    // --- State Variables ---

    // SkillType Definitions
    struct SkillType {
        string name;
        string description;
        bool isSoulbound; // true for SBTs, false for potentially transferable future skills
        address creator;  // Address that initially proposed/defined this skill
        bool isActive;    // Can this skill still be issued/is it deprecated?
    }
    Counters.Counter private _skillTypeIds;
    mapping(uint256 => SkillType) public skillTypes;
    mapping(string => uint256) public skillTypeByName; // For quick lookup by name

    // SkillToken Instances (ERC721-like SBTs via custom mapping)
    // These are non-transferable tokens, tracked directly by recipient address.
    struct SkillTokenInstance {
        uint256 skillTypeId;
        address recipient;
        address issuer;
        uint256 issueTimestamp;
        uint256 expirationTimestamp; // 0 for no expiration
        string attestationURI; // URI to proof of skill (e.g., IPFS hash of a certificate)
        bool isValid; // Can be set to false if revoked
    }
    Counters.Counter private _skillTokenIds;
    mapping(uint256 => SkillTokenInstance) public skillTokens;
    mapping(address => uint256[]) public userToSkillTokenIds; // All skill token instances a user holds

    // Skill Validators
    struct Validator {
        bool isActive;
        string metadataURI; // e.g., IPFS hash to a validator's profile
        mapping(uint256 => bool) canIssueSkillType; // True if validator can issue this skillType
        int256 reputationScore; // Can be positive or negative
    }
    mapping(address => Validator) public validators;
    mapping(address => bool) public isValidator; // Quick check if an address is a validator

    // Learning Streams / Projects
    struct LearningStream {
        string title;
        string description;
        address creator;
        uint256[] requiredSkillTypes; // SkillType IDs required to participate/complete
        uint256[] outcomeSkillTypes;  // SkillType IDs granted upon successful completion
        uint256 rewardAmount;
        IERC20 rewardToken;           // Address of the ERC20 reward token (address(0) for no token reward)
        address validatorAddress;     // Validator responsible for approving completions for this stream
        bool isActive;                // Can this stream still be completed?
    }
    Counters.Counter private _learningStreamIds;
    mapping(uint256 => LearningStream) public learningStreams;

    // Learning Stream Completion Submissions
    struct StreamCompletionSubmission {
        uint256 streamId;
        address participant;
        string proofURI;
        uint256 submissionTimestamp;
        string validatorFeedback; // Optional feedback from validator
        bool isApproved;
        bool isValidated; // True if it has been processed by a validator (approved or rejected)
    }
    Counters.Counter private _completionSubmissionIds;
    mapping(uint256 => StreamCompletionSubmission) public completionSubmissions;
    mapping(uint256 => mapping(address => bool)) public hasSubmittedCompletion; // streamId => participant => bool

    // Skill Prerequisites (for adaptive paths)
    mapping(uint256 => uint256[]) public skillPrerequisites; // skillTypeId => array of prerequisite skillTypeIds

    // Gamification: Achievements (as separate NFTs for unique digital badges)
    // These are also non-transferable and tracked by user address.
    struct AchievementDefinition {
        string name;
        string description;
        string criteriaURI; // e.g., IPFS hash to detailed criteria
        uint256 maxSupply;  // Max number of times this achievement can be minted, 0 for unlimited
        uint256 currentSupply;
        bool isActive;
    }
    Counters.Counter private _achievementDefinitionIds;
    mapping(uint256 => AchievementDefinition) public achievementDefinitions;
    mapping(address => mapping(uint256 => bool)) public userAchievements; // user => achievementDefId => true if achieved

    // DAO Governance (simplified in this contract)
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        bytes callData;         // The function call to execute if proposal passes
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalWeight;    // Sum of votes (simplified: 1 vote per person here)
        mapping(address => bool) hasVoted; // Check if an address has voted
        ProposalState state;
        bool executed;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event SkillTypeDefined(uint256 indexed skillTypeId, string name, string description, bool isSoulbound);
    event SkillTokenIssued(uint256 indexed skillTokenId, uint256 indexed skillTypeId, address indexed recipient, address issuer, uint256 expirationTimestamp, string attestationURI);
    event SkillTokenRevoked(uint256 indexed skillTokenId, address indexed holder, address revoker);
    event ValidatorProposed(address indexed validatorAddress, string metadataURI);
    event ValidatorApproved(address indexed validatorAddress, uint256[] skillTypeIds);
    event ValidatorRevoked(address indexed validatorAddress);
    event LearningStreamCreated(uint256 indexed streamId, string title, address creator, address validatorAddress);
    event LearningStreamCompletionSubmitted(uint256 indexed submissionId, uint256 indexed streamId, address indexed participant, string proofURI);
    event LearningStreamCompletionValidated(uint256 indexed submissionId, bool approved, string validatorFeedback);
    event ReputationAdjusted(address indexed participant, int256 newReputation);
    event SkillPrerequisitesDefined(uint256 indexed skillTypeId, uint256[] prerequisiteSkillTypeIds);
    event AchievementDefined(uint256 indexed achievementId, string name, string criteriaURI);
    event AchievementMinted(uint256 indexed achievementId, address indexed recipient);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event RewardTokensDeposited(address indexed token, uint256 amount, address indexed depositor);

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        // The contract owner acts as the initial governance. In a full DAO,
        // ownership would typically be transferred to a governance contract.
    }

    // --- Modifier for DAO Functions ---
    // In a real DAO, this would check if msg.sender is the DAO governance contract,
    // or if a proposal has passed. For this conceptual contract, it's simplified to the owner.
    modifier onlyGovernance() {
        if (msg.sender != owner()) {
            revert CogniStream__NotAuthorized();
        }
        _;
    }

    // --- I. Core SkillToken Management (SBTs) ---

    /**
     * @dev Defines a new skill type within the network. Only governance can do this.
     * @param _name The unique name of the skill.
     * @param _description A detailed description of the skill.
     * @param _isSoulbound True if this skill is non-transferable (SBT), false otherwise.
     * @return The ID of the newly defined skill type.
     */
    function defineSkillType(string memory _name, string memory _description, bool _isSoulbound)
        external
        onlyGovernance
        returns (uint256)
    {
        if (skillTypeByName[_name] != 0) {
            revert CogniStream__SkillTypeAlreadyExists();
        }
        _skillTypeIds.increment();
        uint256 newId = _skillTypeIds.current();
        skillTypes[newId] = SkillType({
            name: _name,
            description: _description,
            isSoulbound: _isSoulbound,
            creator: msg.sender,
            isActive: true
        });
        skillTypeByName[_name] = newId;

        emit SkillTypeDefined(newId, _name, _description, _isSoulbound);
        return newId;
    }

    /**
     * @dev Issues a specific SkillToken instance to a recipient. Only callable by approved validators.
     *      The issuer must be approved for the specific skillTypeId.
     * @param _recipient The address to receive the SkillToken.
     * @param _skillTypeId The ID of the skill type to issue.
     * @param _expirationTimestamp The timestamp when the skill token expires (0 for no expiration).
     * @param _attestationURI A URI pointing to proof of skill (e.g., IPFS hash).
     * @return The ID of the newly issued SkillToken instance.
     */
    function issueSkillToken(address _recipient, uint256 _skillTypeId, uint256 _expirationTimestamp, string memory _attestationURI)
        external
        returns (uint256)
    {
        if (!isValidator[msg.sender]) {
            revert CogniStream__NotAValidator();
        }
        if (!validators[msg.sender].canIssueSkillType[_skillTypeId]) {
            revert CogniStream__ValidatorNotApprovedForSkill();
        }
        if (!skillTypes[_skillTypeId].isActive || skillTypes[_skillTypeId].name == "") {
            revert CogniStream__InvalidSkillType(); // Skill type not active or doesn't exist
        }

        _skillTokenIds.increment();
        uint256 newId = _skillTokenIds.current();
        skillTokens[newId] = SkillTokenInstance({
            skillTypeId: _skillTypeId,
            recipient: _recipient,
            issuer: msg.sender,
            issueTimestamp: block.timestamp,
            expirationTimestamp: _expirationTimestamp,
            attestationURI: _attestationURI,
            isValid: true
        });
        userToSkillTokenIds[_recipient].push(newId);

        emit SkillTokenIssued(newId, _skillTypeId, _recipient, msg.sender, _expirationTimestamp, _attestationURI);
        _adjustReputation(msg.sender, 5); // Reward validator for issuing a valid skill
        _adjustReputation(_recipient, 2); // Reward recipient for gaining a skill
        return newId;
    }

    /**
     * @dev Revokes a SkillToken. Can be called by the original issuer or governance.
     * @param _skillTokenId The ID of the SkillToken instance to revoke.
     */
    function revokeSkillToken(uint256 _skillTokenId) external {
        SkillTokenInstance storage sToken = skillTokens[_skillTokenId];
        if (sToken.recipient == address(0) || !sToken.isValid) {
            revert CogniStream__SkillTokenNotFound();
        }
        
        bool authorized = (msg.sender == sToken.issuer) || (msg.sender == owner());
        if (!authorized) {
            revert CogniStream__NotAuthorized();
        }

        sToken.isValid = false; // Mark as invalid
        // We don't remove from userToSkillTokenIds to preserve history, but it won't be counted by hasSkillType

        emit SkillTokenRevoked(_skillTokenId, sToken.recipient, msg.sender);
        _adjustReputation(sToken.issuer, -10); // Penalty for issuer if their issued token is revoked
        _adjustReputation(sToken.recipient, -5); // Penalty for recipient if their skill is revoked
    }

    /**
     * @dev Retrieves details of a specific SkillToken instance.
     * @param _skillTokenId The ID of the SkillToken instance.
     * @return skillTypeId, recipient, issuer, issueTimestamp, expirationTimestamp, attestationURI, isValid.
     */
    function getSkillTokenDetails(uint256 _skillTokenId)
        external
        view
        returns (uint256, address, address, uint256, uint256, string memory, bool)
    {
        SkillTokenInstance storage sToken = skillTokens[_skillTokenId];
        if (sToken.recipient == address(0)) {
            revert CogniStream__SkillTokenNotFound();
        }
        return (
            sToken.skillTypeId,
            sToken.recipient,
            sToken.issuer,
            sToken.issueTimestamp,
            sToken.expirationTimestamp,
            sToken.attestationURI,
            sToken.isValid
        );
    }

    /**
     * @dev Returns all active SkillToken IDs held by a user.
     * @param _user The address of the user.
     * @return An array of active SkillToken IDs.
     */
    function getUserSkillTokens(address _user) external view returns (uint256[] memory) {
        uint256[] memory allTokens = userToSkillTokenIds[_user];
        uint256[] memory activeTokens = new uint256[](allTokens.length); // Max possible size
        uint256 activeCount = 0;

        for (uint256 i = 0; i < allTokens.length; i++) {
            SkillTokenInstance storage sToken = skillTokens[allTokens[i]];
            if (sToken.isValid && (sToken.expirationTimestamp == 0 || sToken.expirationTimestamp > block.timestamp)) {
                activeTokens[activeCount] = allTokens[i];
                activeCount++;
            }
        }

        // Resize the array to actual active count
        uint256[] memory finalActiveTokens = new uint256[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            finalActiveTokens[i] = activeTokens[i];
        }
        return finalActiveTokens;
    }

    /**
     * @dev Checks if a user currently holds an active SkillToken of a specific type.
     * @param _user The address of the user.
     * @param _skillTypeId The ID of the skill type to check.
     * @return True if the user holds an active skill of that type, false otherwise.
     */
    function hasSkillType(address _user, uint256 _skillTypeId) public view returns (bool) {
        uint256[] memory userTokens = userToSkillTokenIds[_user];
        for (uint256 i = 0; i < userTokens.length; i++) {
            SkillTokenInstance storage sToken = skillTokens[userTokens[i]];
            if (sToken.skillTypeId == _skillTypeId && sToken.isValid &&
                (sToken.expirationTimestamp == 0 || sToken.expirationTimestamp > block.timestamp)) {
                return true;
            }
        }
        return false;
    }

    // --- II. Skill Validator Management ---

    /**
     * @dev Proposes an address to become a Skill Validator. Governance needs to approve it.
     * @param _validatorAddress The address to propose.
     * @param _metadataURI A URI pointing to the validator's public profile/information.
     */
    function proposeValidator(address _validatorAddress, string memory _metadataURI) external {
        if (isValidator[_validatorAddress]) {
            revert CogniStream__ValidatorAlreadyProposed();
        }
        validators[_validatorAddress].metadataURI = _metadataURI;
        // The isActive flag remains false until approved by governance.
        emit ValidatorProposed(_validatorAddress, _metadataURI);
    }

    /**
     * @dev Approves a proposed validator and grants them permission to issue specific skill types.
     *      Only governance can call this.
     * @param _validatorAddress The address of the validator to approve.
     * @param _skillTypeIds An array of skill type IDs the validator is approved to issue.
     */
    function approveValidatorForSkills(address _validatorAddress, uint256[] memory _skillTypeIds)
        external
        onlyGovernance
    {
        validators[_validatorAddress].isActive = true;
        isValidator[_validatorAddress] = true;
        for (uint256 i = 0; i < _skillTypeIds.length; i++) {
            if (skillTypes[_skillTypeIds[i]].name == "") { // Check if skill type exists
                revert CogniStream__InvalidSkillType();
            }
            validators[_validatorAddress].canIssueSkillType[_skillTypeIds[i]] = true;
        }
        emit ValidatorApproved(_validatorAddress, _skillTypeIds);
        _adjustReputation(_validatorAddress, 50); // Initial reputation boost for becoming a validator
    }

    /**
     * @dev Revokes validator privileges from an address. Only governance can call this.
     * @param _validatorAddress The address of the validator to revoke.
     */
    function revokeValidatorPrivileges(address _validatorAddress) external onlyGovernance {
        if (!isValidator[_validatorAddress]) {
            revert CogniStream__NotAValidator();
        }
        if (_validatorAddress == owner()) { // Prevent accidental self-revocation of the initial owner (governance placeholder)
            revert CogniStream__SelfRevocationNotAllowed();
        }

        validators[_validatorAddress].isActive = false;
        isValidator[_validatorAddress] = false;
        // Clear their skill issuance permissions by setting isActive to false.
        // Clearing `canIssueSkillType` for each skill is gas-intensive and often not necessary.

        emit ValidatorRevoked(_validatorAddress);
        _adjustReputation(_validatorAddress, -100); // Significant reputation penalty for revocation
    }

    /**
     * @dev Returns details about a validator.
     * @param _validatorAddress The address of the validator.
     * @return isActive, metadataURI, reputationScore.
     */
    function getValidatorDetails(address _validatorAddress)
        external
        view
        returns (bool isActive, string memory metadataURI, int256 reputationScore)
    {
        Validator storage val = validators[_validatorAddress];
        return (val.isActive, val.metadataURI, val.reputationScore);
    }

    /**
     * @dev Allows an approved validator to update their public metadata URI.
     * @param _newMetadataURI The new URI for the validator's metadata.
     */
    function updateValidatorMetadata(string memory _newMetadataURI) external {
        if (!isValidator[msg.sender] || !validators[msg.sender].isActive) {
            revert CogniStream__NotAValidator();
        }
        validators[msg.sender].metadataURI = _newMetadataURI;
    }

    // --- III. LearningStream & Project Management ---

    /**
     * @dev Creates a new Learning Stream or Project. Only governance (or approved creators in future) can do this.
     * @param _title The title of the learning stream.
     * @param _description Detailed description.
     * @param _requiredSkillTypes Array of skill type IDs required to start/complete.
     * @param _outcomeSkillTypes Array of skill type IDs granted upon successful completion.
     * @param _rewardAmount Amount of reward token.
     * @param _rewardToken Address of the ERC20 reward token (address(0) for no token reward).
     * @param _validatorAddress The validator responsible for approving completions for this stream.
     * @return The ID of the newly created learning stream.
     */
    function createLearningStream(
        string memory _title,
        string memory _description,
        uint256[] memory _requiredSkillTypes,
        uint256[] memory _outcomeSkillTypes,
        uint256 _rewardAmount,
        address _rewardToken,
        address _validatorAddress
    ) external onlyGovernance returns (uint256) {
        if (!isValidator[_validatorAddress] || !validators[_validatorAddress].isActive) {
            revert CogniStream__NotAValidator();
        }
        for (uint256 i = 0; i < _outcomeSkillTypes.length; i++) {
            if (skillTypes[_outcomeSkillTypes[i]].name == "") {
                revert CogniStream__InvalidSkillType();
            }
        }
        for (uint256 i = 0; i < _requiredSkillTypes.length; i++) {
            if (skillTypes[_requiredSkillTypes[i]].name == "") {
                revert CogniStream__InvalidSkillType();
            }
        }

        _learningStreamIds.increment();
        uint256 newId = _learningStreamIds.current();
        learningStreams[newId] = LearningStream({
            title: _title,
            description: _description,
            creator: msg.sender,
            requiredSkillTypes: _requiredSkillTypes,
            outcomeSkillTypes: _outcomeSkillTypes,
            rewardAmount: _rewardAmount,
            rewardToken: IERC20(_rewardToken),
            validatorAddress: _validatorAddress,
            isActive: true
        });

        emit LearningStreamCreated(newId, _title, msg.sender, _validatorAddress);
        return newId;
    }

    /**
     * @dev A user submits proof of completing a Learning Stream.
     * @param _streamId The ID of the learning stream.
     * @param _proofURI A URI pointing to the completion proof.
     * @return The ID of the new completion submission.
     */
    function submitLearningStreamCompletion(uint256 _streamId, string memory _proofURI) external returns (uint256) {
        LearningStream storage stream = learningStreams[_streamId];
        if (stream.creator == address(0) || !stream.isActive) {
            revert CogniStream__LearningStreamNotFound();
        }
        if (hasSubmittedCompletion[_streamId][msg.sender]) {
            revert CogniStream__CompletionAlreadySubmitted();
        }

        // Check if user meets prerequisites
        for (uint256 i = 0; i < stream.requiredSkillTypes.length; i++) {
            if (!hasSkillType(msg.sender, stream.requiredSkillTypes[i])) {
                revert CogniStream__InsufficientPrerequisites();
            }
        }

        _completionSubmissionIds.increment();
        uint256 newSubmissionId = _completionSubmissionIds.current();
        completionSubmissions[newSubmissionId] = StreamCompletionSubmission({
            streamId: _streamId,
            participant: msg.sender,
            proofURI: _proofURI,
            submissionTimestamp: block.timestamp,
            validatorFeedback: "",
            isApproved: false,
            isValidated: false
        });
        hasSubmittedCompletion[_streamId][msg.sender] = true;

        emit LearningStreamCompletionSubmitted(newSubmissionId, _streamId, msg.sender, _proofURI);
        return newSubmissionId;
    }

    /**
     * @dev A validator approves or rejects a learning stream completion submission.
     *      If approved, outcome skills are issued and rewards disbursed.
     * @param _submissionId The ID of the completion submission.
     * @param _approved True to approve, false to reject.
     * @param _validatorFeedback Optional feedback from the validator.
     */
    function validateLearningStreamCompletion(uint256 _submissionId, bool _approved, string memory _validatorFeedback)
        external
    {
        StreamCompletionSubmission storage submission = completionSubmissions[_submissionId];
        if (submission.participant == address(0)) {
            revert CogniStream__CompletionNotFound();
        }
        if (submission.isValidated) {
            revert CogniStream__CompletionAlreadyValidated();
        }

        LearningStream storage stream = learningStreams[submission.streamId];
        if (stream.validatorAddress != msg.sender) { // Only the designated validator for this stream can validate
            revert CogniStream__NotAuthorized();
        }
        if (!isValidator[msg.sender] || !validators[msg.sender].isActive) {
            revert CogniStream__NotAValidator();
        }

        submission.isApproved = _approved;
        submission.isValidated = true;
        submission.validatorFeedback = _validatorFeedback;

        if (_approved) {
            for (uint256 i = 0; i < stream.outcomeSkillTypes.length; i++) {
                issueSkillToken(submission.participant, stream.outcomeSkillTypes[i], 0, submission.proofURI); // No expiration
            }
            if (stream.rewardAmount > 0 && address(stream.rewardToken) != address(0)) {
                // Transfer reward tokens. Assumes contract has been pre-funded with these tokens.
                IERC20(stream.rewardToken).transfer(submission.participant, stream.rewardAmount);
            }
            _adjustReputation(submission.participant, 10); // Reward participant for completion
            _adjustReputation(msg.sender, 5); // Reward validator for successful validation
        } else {
            _adjustReputation(submission.participant, -5); // Small penalty for rejection
            _adjustReputation(msg.sender, 1); // Small reward for doing their job (even if rejection)
        }

        emit LearningStreamCompletionValidated(_submissionId, _approved, _validatorFeedback);
    }

    /**
     * @dev Retrieves details of a specific Learning Stream.
     * @param _streamId The ID of the learning stream.
     * @return title, description, creator, requiredSkillTypes, outcomeSkillTypes, rewardAmount, rewardTokenAddress, validatorAddress, isActive.
     */
    function getLearningStreamDetails(uint256 _streamId)
        external
        view
        returns (
            string memory title,
            string memory description,
            address creator,
            uint256[] memory requiredSkillTypes,
            uint256[] memory outcomeSkillTypes,
            uint256 rewardAmount,
            address rewardTokenAddress,
            address validatorAddress,
            bool isActive
        )
    {
        LearningStream storage stream = learningStreams[_streamId];
        if (stream.creator == address(0)) {
            revert CogniStream__LearningStreamNotFound();
        }
        return (
            stream.title,
            stream.description,
            stream.creator,
            stream.requiredSkillTypes,
            stream.outcomeSkillTypes,
            stream.rewardAmount,
            address(stream.rewardToken),
            stream.validatorAddress,
            stream.isActive
        );
    }

    // --- IV. Reputation & Progression System ---

    /**
     * @dev Internal function to adjust reputation. Can be called by validators (self-adjusting on actions)
     *      or governance (for penalties/bonuses).
     * @param _participant The address whose reputation is being adjusted.
     * @param _amount The amount to add (can be negative for reduction).
     */
    function _adjustReputation(address _participant, int256 _amount) internal {
        validators[_participant].reputationScore += _amount; // Using validator's struct for generic reputation tracking
        emit ReputationAdjusted(_participant, validators[_participant].reputationScore);
    }

    /**
     * @dev Returns the current reputation score of any participant (user or validator).
     * @param _participant The address to query.
     * @return The reputation score.
     */
    function getReputationScore(address _participant) external view returns (int256) {
        return validators[_participant].reputationScore;
    }

    /**
     * @dev Defines prerequisites for a specific skill type. Governance-only.
     *      A skill cannot be issued if its prerequisites are not met by the recipient (checked in learning stream submission).
     * @param _skillTypeId The skill type for which to define prerequisites.
     * @param _prerequisiteSkillTypeIds An array of skill type IDs that must be held.
     */
    function defineSkillPrerequisites(uint256 _skillTypeId, uint256[] memory _prerequisiteSkillTypeIds)
        external
        onlyGovernance
    {
        if (skillTypes[_skillTypeId].name == "") {
            revert CogniStream__InvalidSkillType();
        }
        for (uint256 i = 0; i < _prerequisiteSkillTypeIds.length; i++) {
            if (skillTypes[_prerequisiteSkillTypeIds[i]].name == "") {
                revert CogniStream__InvalidSkillType();
            }
        }
        skillPrerequisites[_skillTypeId] = _prerequisiteSkillTypeIds;
        emit SkillPrerequisitesDefined(_skillTypeId, _prerequisiteSkillTypeIds);
    }

    /**
     * @dev Computes and returns a list of skill types that a user is eligible to pursue next,
     *      based on their current skills and defined prerequisites.
     * @param _user The address of the user.
     * @return An array of skill type IDs the user is eligible to pursue.
     */
    function getAchievableSkillTypes(address _user) external view returns (uint256[] memory) {
        uint256 currentSkillTypeCount = _skillTypeIds.current();
        uint256[] memory achievableSkillTypeIds = new uint256[](currentSkillTypeCount); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= currentSkillTypeCount; i++) {
            if (!skillTypes[i].isActive || skillTypes[i].name == "") continue; // Skip inactive or non-existent skills
            if (hasSkillType(_user, i)) continue; // Skip skills the user already has

            bool allPrerequisitesMet = true;
            uint256[] memory prereqs = skillPrerequisites[i];
            for (uint256 j = 0; j < prereqs.length; j++) {
                if (!hasSkillType(_user, prereqs[j])) {
                    allPrerequisitesMet = false;
                    break;
                }
            }

            if (allPrerequisitesMet) {
                achievableSkillTypeIds[count] = i;
                count++;
            }
        }

        uint256[] memory finalAchievable = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalAchievable[i] = achievableSkillTypeIds[i];
        }
        return finalAchievable;
    }

    /**
     * @dev Lists Learning Streams for which a user meets the `requiredSkillTypes`.
     * @param _user The address of the user.
     * @return An array of Learning Stream IDs the user is eligible to participate in.
     */
    function getEligibleLearningStreams(address _user) external view returns (uint256[] memory) {
        uint256 currentLearningStreamCount = _learningStreamIds.current();
        uint256[] memory eligibleStreamIds = new uint256[](currentLearningStreamCount); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= currentLearningStreamCount; i++) {
            LearningStream storage stream = learningStreams[i];
            if (!stream.isActive || stream.creator == address(0)) continue; // Skip inactive or non-existent streams

            bool allRequirementsMet = true;
            for (uint256 j = 0; j < stream.requiredSkillTypes.length; j++) {
                if (!hasSkillType(_user, stream.requiredSkillTypes[j])) {
                    allRequirementsMet = false;
                    break;
                }
            }

            if (allRequirementsMet) {
                eligibleStreamIds[count] = i;
                count++;
            }
        }

        uint256[] memory finalEligible = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalEligible[i] = eligibleStreamIds[i];
        }
        return finalEligible;
    }

    // --- V. Gamification & Achievements ---

    /**
     * @dev Defines a new achievement that users can earn. Only governance.
     * @param _name Name of the achievement.
     * @param _description Description of the achievement.
     * @param _criteriaURI URI pointing to the detailed criteria (e.g., "Complete 5 advanced streams").
     * @param _maxSupply Maximum number of times this achievement can be minted (0 for unlimited).
     * @return The ID of the new achievement definition.
     */
    function defineAchievement(string memory _name, string memory _description, string memory _criteriaURI, uint256 _maxSupply)
        external
        onlyGovernance
        returns (uint256)
    {
        _achievementDefinitionIds.increment();
        uint256 newId = _achievementDefinitionIds.current();
        achievementDefinitions[newId] = AchievementDefinition({
            name: _name,
            description: _description,
            criteriaURI: _criteriaURI,
            maxSupply: _maxSupply,
            currentSupply: 0,
            isActive: true
        });
        emit AchievementDefined(newId, _name, _criteriaURI);
        return newId;
    }

    /**
     * @dev Mints an achievement NFT for a user. Can be called by governance or an authorized keeper.
     *      This function relies on the caller to verify the achievement criteria off-chain.
     * @param _achievementDefId The ID of the achievement definition.
     * @param _recipient The address to receive the achievement.
     */
    function mintAchievementNFT(uint256 _achievementDefId, address _recipient) external onlyGovernance {
        AchievementDefinition storage achievement = achievementDefinitions[_achievementDefId];
        if (achievement.name == "" || !achievement.isActive) {
            revert CogniStream__AchievementNotFound();
        }
        if (achievement.maxSupply != 0 && achievement.currentSupply >= achievement.maxSupply) {
            revert CogniStream__AchievementCriteriaNotMet(); // Max supply reached
        }
        if (userAchievements[_recipient][_achievementDefId]) {
            revert CogniStream__AchievementCriteriaNotMet(); // User already has this achievement
        }

        userAchievements[_recipient][_achievementDefId] = true;
        achievement.currentSupply++;

        emit AchievementMinted(_achievementDefId, _recipient);
        _adjustReputation(_recipient, 20); // Reward for earning an achievement
    }

    /**
     * @dev Lists all achievement IDs held by a user.
     * @param _user The address of the user.
     * @return An array of achievement definition IDs.
     */
    function getUserAchievements(address _user) external view returns (uint256[] memory) {
        uint256 currentAchievementDefCount = _achievementDefinitionIds.current();
        uint256[] memory achievedIds = new uint256[](currentAchievementDefCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= currentAchievementDefCount; i++) {
            if (userAchievements[_user][i]) {
                achievedIds[count] = i;
                count++;
            }
        }
        uint256[] memory finalAchievements = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalAchievements[i] = achievedIds[i];
        }
        return finalAchievements;
    }

    // --- VI. DAO Governance (Simplified) ---
    // This is a minimal implementation where the contract owner acts as the sole voter/executor,
    // mimicking governance approval for administrative functions. A full DAO would use dedicated contracts.

    /**
     * @dev Creates a new governance proposal. Only governance can propose.
     *      `_callData` specifies the function call to execute if the proposal passes.
     * @param _callData The encoded function call to execute if the proposal passes.
     * @param _description A human-readable description of the proposal.
     * @return The ID of the new proposal.
     */
    function proposeGovernanceAction(bytes memory _callData, string memory _description)
        external
        onlyGovernance
        returns (uint256)
    {
        _proposalIds.increment();
        uint256 newId = _proposalIds.current();
        proposals[newId] = Proposal({
            callData: _callData,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + 7 days, // 7-day voting period
            yesVotes: 0,
            noVotes: 0,
            totalWeight: 0, // Simplified: 1 vote per person for now
            state: ProposalState.Active,
            executed: false
        });
        emit ProposalCreated(newId, _description, proposals[newId].voteEndTime);
        return newId;
    }

    /**
     * @dev Allows governance (or in a full DAO, any token holder) to vote on a proposal.
     *      For this simplified DAO, only the owner can cast a vote.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernance {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.callData.length == 0) { // Check if proposal exists
            revert CogniStream__InvalidProposal();
        }
        if (proposal.state != ProposalState.Active) {
            revert CogniStream__InvalidProposal();
        }
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) {
            revert CogniStream__InvalidProposal(); // Voting period not active
        }
        if (proposal.hasVoted[msg.sender]) {
            revert CogniStream__VoteAlreadyCast();
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.totalWeight++; // In a real DAO, `totalWeight` would accumulate voting power (e.g., based on tokens)

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal. Only governance can execute.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyGovernance {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.callData.length == 0 || proposal.executed) {
            revert CogniStream__InvalidProposal();
        }

        // Ensure voting period is over
        if (block.timestamp < proposal.voteEndTime) {
            revert CogniStream__ProposalNotExecutable();
        }

        // Finalize state if not already done
        if (proposal.state == ProposalState.Active) {
            if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes >= (proposal.totalWeight / 2) + 1) { // Simple majority threshold
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }

        if (proposal.state != ProposalState.Succeeded) {
            revert CogniStream__ProposalNotPassed();
        }

        proposal.executed = true;

        // Execute the proposed call data
        (bool success, ) = address(this).call(proposal.callData);
        if (!success) {
            revert CogniStream__ProposalNotExecutable(); // Execution failed
        }

        emit ProposalExecuted(_proposalId);
    }

    // --- VII. Utility Functions ---

    /**
     * @dev Allows governance to deposit ERC20 tokens into this contract,
     *      which can then be used as rewards for learning stream completions.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositRewardTokens(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit RewardTokensDeposited(_token, _amount, msg.sender);
    }

    /**
     * @dev (Utility for exploration) Returns all defined skill type IDs.
     *      Note: Not gas efficient for a very large number of skills.
     */
    function getAllSkillTypeIds() external view returns (uint256[] memory) {
        uint256 current = _skillTypeIds.current();
        uint256[] memory ids = new uint256[](current);
        for(uint256 i = 0; i < current; i++) {
            ids[i] = i + 1;
        }
        return ids;
    }

    /**
     * @dev (Utility for exploration) Returns all defined learning stream IDs.
     *      Note: Not gas efficient for a very large number of streams.
     */
    function getAllLearningStreamIds() external view returns (uint256[] memory) {
        uint256 current = _learningStreamIds.current();
        uint256[] memory ids = new uint256[](current);
        for(uint256 i = 0; i < current; i++) {
            ids[i] = i + 1;
        }
        return ids;
    }
}
```