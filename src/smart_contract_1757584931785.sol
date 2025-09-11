```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CognitoNet - Decentralized Adaptive Skill Validation & Reputation Layer
 * @dev This contract establishes a decentralized platform for defining, validating,
 *      and showcasing skills through Adaptive Skill Modules (ASMs) and Dynamic Cognito Badges (CBs).
 *      It integrates with off-chain Cognito Oracles for adaptive assessments and
 *      incentivizes participation through a reputation-based reward system.
 *      The contract aims to be highly advanced, creative, and distinct from existing open-source solutions.
 */

/*
 * OUTLINE:
 *
 * 1.  Interfaces & Libraries (for assumed external token/oracle, no direct OpenZeppelin imports)
 * 2.  Main Contract: CognitoNet
 *     a. State Variables & Data Structures
 *     b. Events
 *     c. Modifiers
 *     d. Constructor
 *     e. Internal Basic Token (DALESV) Implementation
 *     f. Skill Module Management
 *     g. Skill Validation & Adaptive Assessments
 *     h. Dynamic Cognito Badges (CB - Custom ERC721-like Implementation)
 *     i. Reputation & Reward System
 *     j. Admin & Emergency Functions
 */

/*
 * FUNCTION SUMMARY:
 *
 * I.  DALESV Token (Internal, Basic Implementation)
 *     1.  getDALESVBalance(address account): Query DALESV token balance for an address.
 *     2.  _mintDALESV(address account, uint256 amount): Internal function to mint DALESV tokens.
 *     3.  _burnDALESV(address account, uint256 amount): Internal function to burn DALESV tokens.
 *     4.  transferDALESV(address recipient, uint256 amount): Transfer DALESV tokens from caller to recipient.
 *
 * II. Skill Module Management
 *     5.  proposeSkillModule(string memory name, string memory description, bytes32[] memory prerequisiteModuleIds, uint256 minSkillScore): Propose a new Adaptive Skill Module (ASM). Requires a stake.
 *     6.  voteOnModuleProposal(bytes32 moduleId, bool support): Community votes on a module proposal.
 *     7.  finalizeModuleProposal(bytes32 moduleId, bool approved): Admin function to approve or reject a module proposal based on votes.
 *     8.  updateModuleDescription(bytes32 moduleId, string memory newDescription): Module creator or admin can update the module's description.
 *     9.  getSkillModule(bytes32 moduleId): View function to retrieve details of an ASM.
 *
 * III. Skill Validation & Adaptive Assessments
 *     10. registerCognitoOracle(address oracleAddress, string memory description, uint256 stakeAmount): Register an address as a Cognito Oracle, staking DALESV tokens.
 *     11. requestAdaptiveAssessment(bytes32 moduleId): Learner initiates an adaptive assessment for a specific module, paying a fee.
 *     12. submitAssessmentResult(bytes32 assessmentId, uint256 score, string memory proofURI): A registered Cognito Oracle submits the result of an adaptive assessment.
 *     13. revalidateSkill(bytes32 moduleId): Learner re-validates a skill for an existing Cognito Badge, potentially updating its level.
 *     14. challengeAssessment(bytes32 assessmentId, string memory reasonURI): Allows any user to challenge a submitted assessment result, requiring a stake.
 *     15. resolveAssessmentChallenge(bytes32 assessmentId, bool invalidOracleResult, uint256 oraclePenalty): Admin/governance function to resolve a challenged assessment, potentially penalizing the oracle.
 *     16. getLearnerModuleProgress(address learner, bytes32 moduleId): View function to check a learner's current progress/score for a specific module.
 *
 * IV. Dynamic Cognito Badges (CB - Custom ERC721-like Implementation)
 *     17. _mintCognitoBadge(address to, bytes32 moduleId, uint256 initialScore): Internal function to mint a new Cognito Badge (NFT).
 *     18. _updateCognitoBadgeScore(uint256 tokenId, uint256 newScore): Internal function to update the skill score of an existing Cognito Badge.
 *     19. tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a given Cognito Badge token ID.
 *     20. ownerOf(uint256 tokenId): Returns the owner of the given Cognito Badge token ID.
 *     21. balanceOf(address owner): Returns the number of Cognito Badges owned by an address.
 *     22. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of a Cognito Badge.
 *     23. getApproved(uint256 tokenId): Returns the approved address for a single Cognito Badge.
 *     24. approve(address to, uint256 tokenId): Approves another address to transfer a specific Cognito Badge.
 *     25. setApprovalForAll(address operator, bool approved): Sets approval for an operator to manage all of caller's Cognito Badges.
 *     26. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all of owner's Cognito Badges.
 *
 * V.  Reputation & Reward System
 *     27. claimReputationRewards(): Allows users (validators, module creators, challenge resolvers) to claim accumulated DALESV rewards.
 *     28. withdrawOracleStake(): Allows a Cognito Oracle to withdraw their staked DALESV tokens after an unbonding period.
 *     29. finalizeOracleStakeWithdrawal(): Finalizes the withdrawal of staked tokens after the unbonding period.
 *
 * VI. Admin & Emergency Functions
 *     30. setTrustedOracleAddress(address oracleAddress, bool isTrusted): Admin function to manage the list of trusted Cognito Oracles.
 *     31. pause(): Admin function to pause critical contract functionalities during emergencies.
 *     32. unpause(): Admin function to unpause the contract.
 *     33. setMinStakeAmounts(uint256 moduleProposalStake, uint256 oracleRegistrationStake, uint256 assessmentFee, uint256 challengeStakeAmount): Admin function to configure various stake and fee amounts.
 *     34. withdrawContractFunds(address to, uint256 amount): Admin function to withdraw accumulated contract funds (e.g., for governance-approved protocol upgrades or treasury management).
 */

contract CognitoNet {
    // --- State Variables & Data Structures ---

    address public owner; // The deployer, initially acting as admin. Can be transferred to a DAO.
    bool public paused;

    // --- DALESV Token (Internal, Basic Implementation) ---
    mapping(address => uint256) private _balancesDALESV;
    uint256 public totalSupplyDALESV;
    string public nameDALESV = "DALESV Token";
    string public symbolDALESV = "DALESV";
    uint8 public decimalsDALESV = 18;

    // --- Skill Modules ---
    struct SkillModule {
        string name;
        string description;
        address creator;
        bytes32[] prerequisiteModuleIds; // IDs of modules required before this one
        uint256 minSkillScore;         // Minimum score required to pass and earn badge
        uint256 proposalTimestamp;     // When it was proposed
        bool approved;                 // True if approved by admin/governance
        mapping(address => bool) votes; // For tracking proposal votes
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(address => uint256) learnerProgress; // Stores latest score for each learner
    }
    mapping(bytes32 => SkillModule) public skillModules;
    bytes32[] public moduleProposals; // List of active proposals
    uint256 public nextModuleIdCounter;

    // --- Cognito Oracles ---
    struct CognitoOracle {
        string description;
        uint256 stakeAmount;
        uint256 registrationTime;
        bool isTrusted; // Admin-set trust score, could be dynamic in v2
        uint256 unbondingStartTime; // When unbonding was initiated
        bool exists; // To check if oracle is registered
    }
    mapping(address => CognitoOracle) public cognitoOracles;
    mapping(bytes32 => address) public assessmentIdToOracle; // assessmentId => oracle address

    // --- Assessments ---
    struct Assessment {
        bytes32 moduleId;
        address learner;
        address oracle;
        uint256 score;
        string proofURI;
        uint256 submissionTime;
        bool disputed;
        bool resolved;
        address challenger;
        string challengeReasonURI;
        uint256 challengeStake;
    }
    mapping(bytes32 => Assessment) public assessments;
    uint256 public nextAssessmentIdCounter;

    // --- Dynamic Cognito Badges (Custom ERC721-like) ---
    uint256 public nextCognitoBadgeId;
    mapping(uint256 => address) private _cognitoBadgeOwners;    // tokenId => owner
    mapping(address => uint256) private _cognitoBadgeBalances;  // owner => count
    mapping(uint256 => address) private _cognitoBadgeApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _cognitoBadgeOperatorApprovals; // owner => operator => approved
    mapping(uint256 => bytes32) public cognitoBadgeModuleId; // tokenId => moduleId
    mapping(uint256 => uint256) public cognitoBadgeSkillScore; // tokenId => current skill score
    string public baseTokenURI = "https://cognitonet.io/api/badge/"; // Base for metadata URIs

    // --- Reward System ---
    mapping(address => uint256) public pendingRewards; // For various contributions

    // --- Configuration Parameters ---
    uint256 public minModuleProposalStake;
    uint256 public minOracleRegistrationStake;
    uint256 public assessmentFee;
    uint256 public oracleUnbondingPeriod = 7 days;
    uint256 public challengeStakeAmount;
    uint256 public moduleProposalVoteThreshold = 5; // Min positive votes to consider for finalization

    // --- Events ---
    event Paused(address account);
    event Unpaused(address account);
    event TransferDALESV(address indexed from, address indexed to, uint256 value);
    event MintDALESV(address indexed to, uint256 amount);
    event BurnDALESV(address indexed from, uint256 amount);

    event SkillModuleProposed(bytes32 indexed moduleId, address indexed creator, string name);
    event SkillModuleVote(bytes32 indexed moduleId, address indexed voter, bool support);
    event SkillModuleFinalized(bytes32 indexed moduleId, bool approved, address indexed finalizer);
    event ModuleDescriptionUpdated(bytes32 indexed moduleId, string newDescription);

    event CognitoOracleRegistered(address indexed oracleAddress, uint256 stakeAmount);
    event CognitoOracleUnbonded(address indexed oracleAddress);
    event AssessmentRequested(bytes32 indexed assessmentId, address indexed learner, bytes32 indexed moduleId);
    event AssessmentSubmitted(bytes32 indexed assessmentId, address indexed oracle, uint256 score);
    event AssessmentChallenged(bytes32 indexed assessmentId, address indexed challenger, string reasonURI);
    event AssessmentChallengeResolved(bytes32 indexed assessmentId, bool invalidOracleResult);

    event CognitoBadgeMinted(uint256 indexed tokenId, address indexed owner, bytes32 indexed moduleId, uint256 initialScore);
    event CognitoBadgeScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721-like transfer
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event RewardsClaimed(address indexed account, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyRegisteredTrustedOracle() {
        require(cognitoOracles[msg.sender].exists && cognitoOracles[msg.sender].isTrusted, "CognitoNet: Caller is not a registered and trusted oracle");
        _;
    }

    modifier onlyModuleCreatorOrOwner(bytes32 _moduleId) {
        require(skillModules[_moduleId].creator == msg.sender || msg.sender == owner, "CognitoNet: Caller is not module creator or owner");
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 _initialSupplyDALESV,
        uint256 _minModuleProposalStake,
        uint256 _minOracleRegistrationStake,
        uint256 _assessmentFee,
        uint256 _challengeStakeAmount
    ) {
        owner = msg.sender;
        paused = false;

        minModuleProposalStake = _minModuleProposalStake;
        minOracleRegistrationStake = _minOracleRegistrationStake;
        assessmentFee = _assessmentFee;
        challengeStakeAmount = _challengeStakeAmount;

        // Mint initial supply of DALESV tokens to the owner
        _mintDALESV(owner, _initialSupplyDALESV);
    }

    // --- I. DALESV Token (Internal, Basic Implementation) ---

    /**
     * @notice Returns the DALESV token balance of a specific account.
     * @param account The address to query the balance for.
     * @return The amount of DALESV tokens owned by the `account`.
     */
    function getDALESVBalance(address account) public view returns (uint256) {
        return _balancesDALESV[account];
    }

    /**
     * @dev Internal function to mint `amount` DALESV tokens to `account`.
     *      Can be called by privileged functions (e.g., reward distribution).
     * @param account The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function _mintDALESV(address account, uint256 amount) internal {
        require(account != address(0), "DALESV: mint to the zero address");
        totalSupplyDALESV += amount;
        _balancesDALESV[account] += amount;
        emit MintDALESV(account, amount);
        emit TransferDALESV(address(0), account, amount);
    }

    /**
     * @dev Internal function to burn `amount` DALESV tokens from `account`.
     *      Can be called for staking, fees, or penalties.
     * @param account The address to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function _burnDALESV(address account, uint256 amount) internal {
        require(account != address(0), "DALESV: burn from the zero address");
        require(_balancesDALESV[account] >= amount, "DALESV: burn amount exceeds balance");
        _balancesDALESV[account] -= amount;
        totalSupplyDALESV -= amount;
        emit BurnDALESV(account, amount);
        emit TransferDALESV(account, address(0), amount);
    }

    /**
     * @notice Transfers `amount` DALESV tokens from the caller to `recipient`.
     * @param recipient The address to send tokens to.
     * @param amount The amount of tokens to transfer.
     * @return True if the transfer was successful, false otherwise.
     */
    function transferDALESV(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "DALESV: transfer to the zero address");
        _burnDALESV(msg.sender, amount); // Deduct from sender
        _mintDALESV(recipient, amount);  // Add to recipient
        return true;
    }

    // --- II. Skill Module Management ---

    /**
     * @notice Proposes a new Adaptive Skill Module (ASM) for community review and approval.
     * @dev Requires the proposer to stake `minModuleProposalStake` DALESV tokens.
     *      Module ID is generated using keccak256 hash of name, creator, and timestamp for uniqueness.
     * @param name The name of the skill module.
     * @param description A detailed description of the module.
     * @param prerequisiteModuleIds An array of module IDs that must be completed first.
     * @param minSkillScore The minimum score required to pass this module and earn its badge.
     */
    function proposeSkillModule(
        string memory name,
        string memory description,
        bytes32[] memory prerequisiteModuleIds,
        uint256 minSkillScore
    ) public whenNotPaused {
        require(bytes(name).length > 0, "CognitoNet: Module name cannot be empty");
        require(getDALESVBalance(msg.sender) >= minModuleProposalStake, "CognitoNet: Insufficient stake for proposal");

        bytes32 moduleId = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
        require(skillModules[moduleId].creator == address(0), "CognitoNet: Module with this ID already exists or is in proposal");

        _burnDALESV(msg.sender, minModuleProposalStake); // Stake the tokens

        skillModules[moduleId].name = name;
        skillModules[moduleId].description = description;
        skillModules[moduleId].creator = msg.sender;
        skillModules[moduleId].prerequisiteModuleIds = prerequisiteModuleIds;
        skillModules[moduleId].minSkillScore = minSkillScore;
        skillModules[moduleId].proposalTimestamp = block.timestamp;
        skillModules[moduleId].approved = false;

        moduleProposals.push(moduleId);

        emit SkillModuleProposed(moduleId, msg.sender, name);
    }

    /**
     * @notice Allows community members to vote on an active skill module proposal.
     * @param moduleId The ID of the skill module proposal to vote on.
     * @param support True for a positive vote, false for a negative vote.
     */
    function voteOnModuleProposal(bytes32 moduleId, bool support) public whenNotPaused {
        SkillModule storage module = skillModules[moduleId];
        require(module.creator != address(0), "CognitoNet: Module does not exist");
        require(!module.approved, "CognitoNet: Module already finalized");
        require(!module.votes[msg.sender], "CognitoNet: Already voted on this proposal");

        module.votes[msg.sender] = true;
        if (support) {
            module.positiveVotes++;
        } else {
            module.negativeVotes++;
        }
        emit SkillModuleVote(moduleId, msg.sender, support);
    }

    /**
     * @notice Admin function to finalize a skill module proposal.
     * @dev Only callable by the owner. Can approve a module if it meets the vote threshold.
     *      Returns the staked tokens to the proposer if approved, or implicitly keeps them as a cost if rejected.
     * @param moduleId The ID of the skill module proposal to finalize.
     * @param approved True to approve the module, false to reject.
     */
    function finalizeModuleProposal(bytes32 moduleId, bool approved) public onlyOwner whenNotPaused {
        SkillModule storage module = skillModules[moduleId];
        require(module.creator != address(0), "CognitoNet: Module does not exist");
        require(!module.approved, "CognitoNet: Module already finalized");

        if (approved) {
            require(module.positiveVotes >= moduleProposalVoteThreshold, "CognitoNet: Not enough positive votes to approve");
            module.approved = true;
            // Return stake to module creator if approved
            _mintDALESV(module.creator, minModuleProposalStake);
        } else {
            // If rejected, the proposal stake (already burned) is lost, acting as a cost to propose.
        }

        // Remove from proposals list (simplified, in reality might need more complex array management)
        for (uint i = 0; i < moduleProposals.length; i++) {
            if (moduleProposals[i] == moduleId) {
                moduleProposals[i] = moduleProposals[moduleProposals.length - 1];
                moduleProposals.pop();
                break;
            }
        }

        emit SkillModuleFinalized(moduleId, approved, msg.sender);
    }

    /**
     * @notice Allows the module creator or owner to update the description of an approved module.
     * @param moduleId The ID of the module to update.
     * @param newDescription The new description for the module.
     */
    function updateModuleDescription(bytes32 moduleId, string memory newDescription) public onlyModuleCreatorOrOwner(moduleId) whenNotPaused {
        SkillModule storage module = skillModules[moduleId];
        require(module.approved, "CognitoNet: Module is not yet approved");
        module.description = newDescription;
        emit ModuleDescriptionUpdated(moduleId, newDescription);
    }

    /**
     * @notice Retrieves the details of a specific skill module.
     * @param moduleId The ID of the skill module.
     * @return name, description, creator, prerequisiteModuleIds, minSkillScore, approved status.
     */
    function getSkillModule(bytes32 moduleId) public view returns (string memory name, string memory description, address creator, bytes32[] memory prerequisiteModuleIds, uint256 minSkillScore, bool approved) {
        SkillModule storage module = skillModules[moduleId];
        require(module.creator != address(0), "CognitoNet: Module does not exist");
        return (module.name, module.description, module.creator, module.prerequisiteModuleIds, module.minSkillScore, module.approved);
    }

    // --- III. Skill Validation & Adaptive Assessments ---

    /**
     * @notice Registers an address as a Cognito Oracle. Requires staking DALESV tokens.
     * @param oracleAddress The address to register as an oracle.
     * @param description A description of the oracle's expertise or capabilities.
     * @param stakeAmount The amount of DALESV tokens to stake.
     */
    function registerCognitoOracle(address oracleAddress, string memory description, uint256 stakeAmount) public whenNotPaused {
        require(!cognitoOracles[oracleAddress].exists, "CognitoNet: Oracle already registered");
        require(stakeAmount >= minOracleRegistrationStake, "CognitoNet: Stake amount too low");
        require(getDALESVBalance(msg.sender) >= stakeAmount, "CognitoNet: Insufficient DALESV balance to stake");

        _burnDALESV(msg.sender, stakeAmount); // Stake the tokens

        cognitoOracles[oracleAddress] = CognitoOracle({
            description: description,
            stakeAmount: stakeAmount,
            registrationTime: block.timestamp,
            isTrusted: false, // Initially not trusted, needs admin approval or community voting in v2
            unbondingStartTime: 0,
            exists: true
        });

        emit CognitoOracleRegistered(oracleAddress, stakeAmount);
    }

    /**
     * @notice Allows a learner to request an adaptive assessment for a specific module.
     * @dev Learner pays an `assessmentFee` in DALESV tokens.
     * @param moduleId The ID of the module for which to request an assessment.
     * @return The ID of the created assessment request.
     */
    function requestAdaptiveAssessment(bytes32 moduleId) public whenNotPaused returns (bytes32) {
        SkillModule storage module = skillModules[moduleId];
        require(module.approved, "CognitoNet: Module not approved");
        require(getDALESVBalance(msg.sender) >= assessmentFee, "CognitoNet: Insufficient DALESV balance for assessment fee");

        // Check prerequisites
        for (uint i = 0; i < module.prerequisiteModuleIds.length; i++) {
            bytes32 prereqId = module.prerequisiteModuleIds[i]; 
            
            require(skillModules[prereqId].creator != address(0), "CognitoNet: Prerequisite module does not exist");
            require(skillModules[prereqId].approved, "CognitoNet: Prerequisite module not yet approved");
            // Check if learner has passed the prerequisite module
            require(skillModules[prereqId].learnerProgress[msg.sender] >= skillModules[prereqId].minSkillScore, "CognitoNet: Learner has not passed a prerequisite module");
        }


        _burnDALESV(msg.sender, assessmentFee); // Collect fee

        bytes32 assessmentId = keccak256(abi.encodePacked(moduleId, msg.sender, block.timestamp, nextAssessmentIdCounter++));
        assessments[assessmentId] = Assessment({
            moduleId: moduleId,
            learner: msg.sender,
            oracle: address(0), // Oracle assigned later or chosen off-chain
            score: 0,
            proofURI: "",
            submissionTime: 0,
            disputed: false,
            resolved: false,
            challenger: address(0),
            challengeReasonURI: "",
            challengeStake: 0
        });

        emit AssessmentRequested(assessmentId, msg.sender, moduleId);
        return assessmentId;
    }

    /**
     * @notice Allows a registered Cognito Oracle to submit the result of an adaptive assessment.
     * @dev Only trusted oracles can submit results.
     * @param assessmentId The ID of the assessment request.
     * @param score The score achieved by the learner (e.g., 0-100).
     * @param proofURI URI pointing to off-chain assessment details/proof.
     */
    function submitAssessmentResult(bytes32 assessmentId, uint256 score, string memory proofURI) public onlyRegisteredTrustedOracle whenNotPaused {
        Assessment storage assessment = assessments[assessmentId];
        require(assessment.learner != address(0), "CognitoNet: Assessment not found");
        require(assessment.oracle == address(0), "CognitoNet: Assessment result already submitted"); // Only one oracle can submit
        require(score <= 100, "CognitoNet: Score must be between 0 and 100"); // Assuming score is percentage based

        assessment.oracle = msg.sender;
        assessment.score = score;
        assessment.proofURI = proofURI;
        assessment.submissionTime = block.timestamp;

        // Update learner progress
        SkillModule storage module = skillModules[assessment.moduleId];
        module.learnerProgress[assessment.learner] = score;

        // If score is high enough, mint or update a Cognito Badge
        if (score >= module.minSkillScore) {
            bool badgeFound = false;
            for (uint i = 0; i < nextCognitoBadgeId; i++) { // Iterate all existing badges (can be optimized with a mapping if many badges)
                if (_cognitoBadgeOwners[i] == assessment.learner && cognitoBadgeModuleId[i] == assessment.moduleId) {
                    _updateCognitoBadgeScore(i, score);
                    badgeFound = true;
                    break;
                }
            }
            if (!badgeFound) {
                _mintCognitoBadge(assessment.learner, assessment.moduleId, score);
            }
        }

        // Reward the oracle for successful submission (can be dynamic based on reputation/challenge history)
        pendingRewards[msg.sender] += assessmentFee / 2; // Example: half of fee goes to oracle

        emit AssessmentSubmitted(assessmentId, msg.sender, score);
    }

    /**
     * @notice Allows a learner to re-validate their skills for an existing module.
     * @dev This initiates a new assessment process, potentially updating an existing Cognito Badge.
     * @param moduleId The ID of the module for which to re-validate.
     */
    function revalidateSkill(bytes32 moduleId) public whenNotPaused {
        // This function simply triggers a new assessment request for an existing badge holder.
        // The logic for updating the badge is in `submitAssessmentResult`.
        bool hasBadge = false;
        for (uint i = 0; i < nextCognitoBadgeId; i++) {
            if (_cognitoBadgeOwners[i] == msg.sender && cognitoBadgeModuleId[i] == moduleId) {
                hasBadge = true;
                break;
            }
        }
        require(hasBadge, "CognitoNet: Learner does not possess a badge for this module to re-validate");
        requestAdaptiveAssessment(moduleId); // Triggers new assessment process
    }

    /**
     * @notice Allows any user to challenge a submitted assessment result.
     * @dev Requires staking `challengeStakeAmount` DALESV tokens.
     * @param assessmentId The ID of the assessment to challenge.
     * @param reasonURI URI pointing to details/evidence for the challenge.
     */
    function challengeAssessment(bytes32 assessmentId, string memory reasonURI) public whenNotPaused {
        Assessment storage assessment = assessments[assessmentId];
        require(assessment.learner != address(0), "CognitoNet: Assessment not found");
        require(assessment.oracle != address(0), "CognitoNet: Assessment result not submitted yet");
        require(!assessment.disputed, "CognitoNet: Assessment already under dispute");
        require(getDALESVBalance(msg.sender) >= challengeStakeAmount, "CognitoNet: Insufficient stake for challenge");

        _burnDALESV(msg.sender, challengeStakeAmount); // Stake the tokens

        assessment.disputed = true;
        assessment.challenger = msg.sender;
        assessment.challengeReasonURI = reasonURI;
        assessment.challengeStake = challengeStakeAmount;

        emit AssessmentChallenged(assessmentId, msg.sender, reasonURI);
    }

    /**
     * @notice Admin/governance function to resolve a challenged assessment.
     * @dev If `invalidOracleResult` is true, the oracle is penalized (stake burned/reduced), and challenger potentially rewarded.
     * @param assessmentId The ID of the challenged assessment.
     * @param invalidOracleResult True if the oracle's result was indeed invalid, false otherwise.
     * @param oraclePenalty The amount of DALESV to penalize the oracle if their result was invalid.
     */
    function resolveAssessmentChallenge(bytes32 assessmentId, bool invalidOracleResult, uint256 oraclePenalty) public onlyOwner whenNotPaused {
        Assessment storage assessment = assessments[assessmentId];
        require(assessment.disputed, "CognitoNet: Assessment not disputed");
        require(!assessment.resolved, "CognitoNet: Challenge already resolved");

        assessment.resolved = true;
        if (invalidOracleResult) {
            require(oraclePenalty <= cognitoOracles[assessment.oracle].stakeAmount, "CognitoNet: Penalty exceeds oracle stake");
            _burnDALESV(assessment.oracle, oraclePenalty); // Penalize oracle by burning their stake
            cognitoOracles[assessment.oracle].stakeAmount -= oraclePenalty;

            // Reward challenger
            if (assessment.challengeStake > 0) {
                // Return challenge stake as reward (plus potentially a bonus)
                pendingRewards[assessment.challenger] += assessment.challengeStake; 
            }
        } else {
            // Oracle's result was valid. Challenger loses stake (already burned).
            // Optionally, we could reward the oracle here for correct assessment against a false challenge.
        }

        emit AssessmentChallengeResolved(assessmentId, invalidOracleResult);
    }

    /**
     * @notice Retrieves a learner's latest skill score for a specific module.
     * @param learner The address of the learner.
     * @param moduleId The ID of the skill module.
     * @return The latest recorded score for the learner in that module.
     */
    function getLearnerModuleProgress(address learner, bytes32 moduleId) public view returns (uint256) {
        SkillModule storage module = skillModules[moduleId];
        require(module.creator != address(0), "CognitoNet: Module does not exist");
        return module.learnerProgress[learner];
    }

    // --- IV. Dynamic Cognito Badges (CB - Custom ERC721-like Implementation) ---

    /**
     * @dev Internal function to mint a new Cognito Badge (NFT).
     *      Called upon successful initial completion of an approved module.
     * @param to The recipient of the new badge.
     * @param moduleId The ID of the skill module this badge represents.
     * @param initialScore The initial skill score achieved.
     * @return The ID of the newly minted badge.
     */
    function _mintCognitoBadge(address to, bytes32 moduleId, uint256 initialScore) internal returns (uint256) {
        require(to != address(0), "CB: mint to the zero address");
        require(skillModules[moduleId].approved, "CB: Module not approved for badge minting");

        uint256 newBadgeId = nextCognitoBadgeId++;
        _cognitoBadgeOwners[newBadgeId] = to;
        _cognitoBadgeBalances[to]++;
        cognitoBadgeModuleId[newBadgeId] = moduleId;
        cognitoBadgeSkillScore[newBadgeId] = initialScore;

        emit CognitoBadgeMinted(newBadgeId, to, moduleId, initialScore);
        emit Transfer(address(0), to, newBadgeId);
        return newBadgeId;
    }

    /**
     * @dev Internal function to update the skill score of an existing Cognito Badge.
     *      Called after re-validation or improved assessment results.
     * @param tokenId The ID of the Cognito Badge to update.
     * @param newScore The new skill score.
     */
    function _updateCognitoBadgeScore(uint256 tokenId, uint256 newScore) internal {
        require(_cognitoBadgeOwners[tokenId] != address(0), "CB: Badge does not exist");
        // Logic to prevent score from decreasing unless specified (e.g., decay mechanism not implemented in V1)
        require(newScore >= cognitoBadgeSkillScore[tokenId], "CB: New score must be greater than or equal to current score (no decay in V1)");

        cognitoBadgeSkillScore[tokenId] = newScore;
        emit CognitoBadgeScoreUpdated(tokenId, newScore);
    }

    /**
     * @notice Returns the dynamic metadata URI for a given Cognito Badge token ID.
     * @dev The URI can reflect the badge's current level, score, and module.
     * @param tokenId The ID of the Cognito Badge.
     * @return A URI pointing to the JSON metadata for the badge.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_cognitoBadgeOwners[tokenId] != address(0), "CB: Token URI query for non-existent token");
        // Example: baseURI/tokenId.json?module=X&score=Y
        bytes32 modId = cognitoBadgeModuleId[tokenId];
        uint256 score = cognitoBadgeSkillScore[tokenId];
        string memory moduleName = skillModules[modId].name; // Get the module name

        return string(abi.encodePacked(
            baseTokenURI,
            Strings.toString(tokenId),
            "?module=",
            moduleName,
            "&score=",
            Strings.toString(score)
        ));
    }

    /**
     * @notice Returns the owner of the given Cognito Badge token ID.
     * @param tokenId The ID of the Cognito Badge.
     * @return The address of the owner.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address ownerAddr = _cognitoBadgeOwners[tokenId];
        require(ownerAddr != address(0), "CB: owner query for non-existent token");
        return ownerAddr;
    }

    /**
     * @notice Returns the number of Cognito Badges owned by an address.
     * @param ownerAddr The address to query the balance for.
     * @return The count of Cognito Badges owned by `ownerAddr`.
     */
    function balanceOf(address ownerAddr) public view returns (uint256) {
        require(ownerAddr != address(0), "CB: balance query for the zero address");
        return _cognitoBadgeBalances[ownerAddr];
    }

    /**
     * @dev Internal function to transfer ownership of a Cognito Badge.
     * @param from The current owner of the badge.
     * @param to The new owner of the badge.
     * @param tokenId The ID of the badge to transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "CB: transfer from incorrect owner");
        require(to != address(0), "CB: transfer to the zero address");

        // Clear approval for the transferred token
        _cognitoBadgeApprovals[tokenId] = address(0);

        _cognitoBadgeBalances[from]--;
        _cognitoBadgeOwners[tokenId] = to;
        _cognitoBadgeBalances[to]++;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @notice Transfers ownership of a Cognito Badge from `from` to `to`.
     * @dev The caller must be the owner, or an approved operator, or the approved address for the token.
     * @param from The current owner.
     * @param to The new owner.
     * @param tokenId The ID of the badge to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "CB: caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @notice Returns the approved address for a single Cognito Badge.
     * @param tokenId The ID of the Cognito Badge.
     * @return The approved address.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_cognitoBadgeOwners[tokenId] != address(0), "CB: approved query for non-existent token");
        return _cognitoBadgeApprovals[tokenId];
    }

    /**
     * @notice Approves another address to transfer a specific Cognito Badge.
     * @dev Only the owner of the badge or an approved operator can set approval.
     * @param to The address to approve.
     * @param tokenId The ID of the Cognito Badge.
     */
    function approve(address to, uint256 tokenId) public whenNotPaused {
        address ownerAddr = ownerOf(tokenId);
        require(to != ownerAddr, "CB: approval to current owner");
        require(msg.sender == ownerAddr || isApprovedForAll(ownerAddr, msg.sender), "CB: caller is not owner nor approved for all");

        _cognitoBadgeApprovals[tokenId] = to;
        emit Approval(ownerAddr, to, tokenId);
    }

    /**
     * @notice Sets approval for an operator to manage all of caller's Cognito Badges.
     * @param operator The address to set as an operator.
     * @param approved True to approve, false to revoke.
     */
    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        require(operator != msg.sender, "CB: approve to caller");
        _cognitoBadgeOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Checks if an operator is approved for all of owner's Cognito Badges.
     * @param ownerAddr The owner of the badges.
     * @param operator The potential operator.
     * @return True if `operator` is approved for `ownerAddr`, false otherwise.
     */
    function isApprovedForAll(address ownerAddr, address operator) public view returns (bool) {
        return _cognitoBadgeOperatorApprovals[ownerAddr][operator];
    }

    /**
     * @dev Internal helper function to check if `spender` is approved or is the owner of `tokenId`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    // --- V. Reputation & Reward System ---

    /**
     * @notice Allows users (module creators, challenge resolvers, etc.) to claim their accumulated DALESV rewards.
     */
    function claimReputationRewards() public whenNotPaused {
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "CognitoNet: No pending rewards");

        pendingRewards[msg.sender] = 0;
        _mintDALESV(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @notice Allows a Cognito Oracle to initiate withdrawal of their staked DALESV tokens.
     * @dev Initiates an unbonding period. Tokens can only be withdrawn after this period.
     */
    function withdrawOracleStake() public whenNotPaused {
        CognitoOracle storage oracle = cognitoOracles[msg.sender];
        require(oracle.exists, "CognitoNet: Not a registered oracle");
        require(oracle.stakeAmount > 0, "CognitoNet: No stake to withdraw");
        require(oracle.unbondingStartTime == 0, "CognitoNet: Unbonding already in progress");

        oracle.unbondingStartTime = block.timestamp;
        emit CognitoOracleUnbonded(msg.sender);
    }

    /**
     * @notice Finalizes the withdrawal of staked tokens after the unbonding period.
     * @dev Can only be called after `oracleUnbondingPeriod` has passed since `withdrawOracleStake`.
     */
    function finalizeOracleStakeWithdrawal() public whenNotPaused {
        CognitoOracle storage oracle = cognitoOracles[msg.sender];
        require(oracle.exists, "CognitoNet: Not a registered oracle");
        require(oracle.unbondingStartTime > 0, "CognitoNet: Unbonding not initiated");
        require(block.timestamp >= oracle.unbondingStartTime + oracleUnbondingPeriod, "CognitoNet: Unbonding period not over yet");

        uint256 stake = oracle.stakeAmount;
        oracle.stakeAmount = 0;
        oracle.unbondingStartTime = 0;
        oracle.isTrusted = false; // Revoke trusted status upon full withdrawal
        oracle.exists = false; // Oracle effectively deregistered

        _mintDALESV(msg.sender, stake);
        emit TransferDALESV(address(this), msg.sender, stake);
    }

    // --- VI. Admin & Emergency Functions ---

    /**
     * @notice Admin function to manage the trusted status of Cognito Oracles.
     * @dev Only trusted oracles can submit assessment results.
     * @param oracleAddress The address of the oracle to modify.
     * @param isTrusted The new trusted status (true to trust, false to untrust).
     */
    function setTrustedOracleAddress(address oracleAddress, bool isTrusted) public onlyOwner whenNotPaused {
        require(cognitoOracles[oracleAddress].exists, "CognitoNet: Oracle not registered");
        cognitoOracles[oracleAddress].isTrusted = isTrusted;
    }

    /**
     * @notice Pauses the contract in case of emergencies, preventing most state-changing operations.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing operations to resume.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Admin function to configure various stake and fee amounts.
     * @param _moduleProposalStake Minimum DALESV required to propose a skill module.
     * @param _oracleRegistrationStake Minimum DALESV required to register as a Cognito Oracle.
     * @param _assessmentFee DALESV fee paid by learners for an adaptive assessment.
     * @param _challengeStakeAmount DALESV stake required to challenge an assessment.
     */
    function setMinStakeAmounts(uint256 _moduleProposalStake, uint256 _oracleRegistrationStake, uint256 _assessmentFee, uint256 _challengeStakeAmount) public onlyOwner {
        minModuleProposalStake = _moduleProposalStake;
        minOracleRegistrationStake = _oracleRegistrationStake;
        assessmentFee = _assessmentFee;
        challengeStakeAmount = _challengeStakeAmount;
    }

    /**
     * @notice Admin function to withdraw accumulated contract funds (e.g., leftover fees, penalties).
     * @dev This should be used cautiously, ideally after a governance vote.
     * @param to The address to send the funds to.
     * @param amount The amount of DALESV tokens to withdraw.
     */
    function withdrawContractFunds(address to, uint256 amount) public onlyOwner {
        require(getDALESVBalance(address(this)) >= amount, "CognitoNet: Insufficient contract DALESV balance");
        // For the internal token model, this means effectively transferring from the contract's "balance" to `to`.
        // The contract itself does not hold ETH, but its DALESV balance is tracked.
        _burnDALESV(address(this), amount); // Deduct from contract's balance
        _mintDALESV(to, amount);            // Mint to recipient
        emit TransferDALESV(address(this), to, amount);
    }
}

// Minimal String utility for tokenURI function
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```