Okay, this is an exciting challenge! Let's conceptualize a sophisticated and dynamic smart contract.

I'll propose a contract called "ChronicleForge Protocol." It's designed to manage **evolving digital identities (Digital Twins)** that accumulate **AI-attested skills and reputation**, participate in a **decentralized task marketplace**, and operate under an **adaptive, AI-informed governance and fee structure**. The core idea is to move beyond static NFTs or simple token transfers, creating dynamic, skill-driven agents that can interact and evolve within a decentralized ecosystem.

---

## ChronicleForge Protocol: Adaptive Skill-Driven Digital Twin Network

**Contract Name:** `ChronicleForgeProtocol`

**Core Concept:** A decentralized protocol for minting, managing, and evolving "Digital Twins" (represented as dynamic NFTs) that acquire and demonstrate skills validated by AI oracles, participate in a skill-based task marketplace, and are governed by an adaptive, community-driven framework. This aims to create a reputation-rich, skill-attested identity layer for future decentralized applications and work allocation.

**Key Features:**

1.  **Dynamic Digital Twins (DD-NFTs):** ERC-721 based NFTs where metadata (skills, reputation, status) changes dynamically on-chain.
2.  **AI-Attested Skill System:** A framework for registering skills and associated "AI Oracles" (or verified human evaluators) that can attest to a Digital Twin's proficiency in a specific skill.
3.  **Reputation System:** A multi-faceted reputation score for each Digital Twin, influenced by skill attestations, successful task completions, and community feedback.
4.  **Decentralized Task Marketplace:** A mechanism for users to propose tasks requiring specific skills, and for Digital Twins to bid on and complete these tasks, earning rewards.
5.  **Adaptive Fee Model:** A unique fee structure that adjusts based on network activity, economic conditions (via external oracle feeds), and governance decisions, promoting sustainability and dynamic pricing.
6.  **Progressive Governance:** A DAO-like system where token holders (or Digital Twin owners with high reputation) can propose and vote on new skills, AI oracle registrations, contract parameter changes, and fund allocations.
7.  **Skill-Based On-Chain AI Evaluation Interface:** An interface for AI services to submit evaluation results securely on-chain.
8.  **Time-Locked Skill Advancement:** Certain skill tiers or reputation boosts might require a time-lock or "cooling-off" period to prevent rapid, unearned progression.
9.  **Dispute Resolution Module:** A basic framework for challenging skill attestations or task outcomes, managed by governance.

---

### Function Summary

1.  **`forgeDigitalTwin(string memory _initialMetadataURI)`**: Mints a new Digital Twin NFT, assigning an initial unique ID and metadata.
2.  **`updateTwinMetadata(uint256 _twinId, string memory _newMetadataURI)`**: Allows the owner of a Digital Twin to update its off-chain metadata (e.g., profile picture, description).
3.  **`proposeNewSkill(string memory _skillName, string memory _description, bytes32 _challengeHash)`**: Proposes a new skill for inclusion in the network, requiring a challenge hash (e.g., IPFS hash of a skill challenge).
4.  **`voteOnSkillProposal(uint256 _proposalId, bool _approve)`**: Allows eligible governance members (or high-reputation Twin owners) to vote on proposed skills.
5.  **`registerSkillVerifier(bytes32 _skillHash, address _verifierAddress, string memory _verifierInfoURI)`**: Registers an approved AI Oracle or human expert as a verifier for a specific skill.
6.  **`attestSkillProficiency(uint256 _twinId, bytes32 _skillHash, uint8 _proficiencyLevel, string memory _attestationProofURI)`**: Callable *only* by registered `skillVerifier` addresses to record a Digital Twin's proficiency in a skill.
7.  **`requestAISkillEvaluation(uint256 _twinId, bytes32 _skillHash, string memory _evaluationRequestURI)`**: Allows a Digital Twin owner to request an off-chain AI evaluation for a specific skill, triggering an external AI service.
8.  **`_receiveAIResultAndAttest(uint256 _twinId, bytes32 _skillHash, uint8 _proficiencyLevel, bytes32 _evaluationHash, address _aiOracleAddress)`**: An internal (or restricted external) function called by a registered AI Oracle to submit an evaluation result, which then calls `attestSkillProficiency`.
9.  **`proposeTask(string memory _taskTitle, string memory _descriptionURI, bytes32[] memory _requiredSkills, uint256 _bountyAmount, uint256 _deadline)`**: Creates a new task on the marketplace, specifying required skills and a bounty.
10. **`bidOnTask(uint256 _taskId, uint256 _twinId, string memory _bidDetailsURI)`**: Allows a Digital Twin owner to bid on an open task, showcasing their Twin's skills.
11. **`assignTask(uint256 _taskId, uint256 _bidTwinId)`**: The task creator selects and assigns a task to a bidding Digital Twin.
12. **`markTaskCompleted(uint256 _taskId, string memory _completionProofURI)`**: The assigned Digital Twin owner marks a task as completed and provides proof.
13. **`verifyTaskCompletion(uint256 _taskId, bool _successful)`**: The task creator verifies task completion. If successful, payment is released and reputation updated. If failed, dispute process can be initiated.
14. **`adjustReputation(uint256 _twinId, int256 _reputationChange)`**: Allows governance or specific trusted roles to adjust a Twin's reputation (e.g., for positive contributions or malicious behavior).
15. **`proposeParameterChange(bytes32 _paramName, bytes memory _newValue)`**: Initiates a governance proposal to change a core contract parameter (e.g., minimum skill level for tasks, fee percentages).
16. **`voteOnProposal(uint256 _proposalId, bool _approve)`**: Casts a vote on an active governance proposal.
17. **`executeProposal(uint256 _proposalId)`**: Executes a passed governance proposal.
18. **`setAdaptiveFeeModelParameters(uint256 _baseFee, uint256 _volatilityFactor, address _priceOracle)`**: Sets parameters for the adaptive fee model, including a reference price oracle for economic context.
19. **`getDynamicServiceFee(uint256 _baseAmount)`**: Calculates the dynamic service fee based on current network activity and configured parameters.
20. **`triggerFeeRecalculation()`**: Allows anyone to trigger a recalculation of the current network-wide adaptive fees, based on current on-chain metrics and oracle data (if applicable).
21. **`initiateDispute(uint256 _taskId, uint256 _twinId, string memory _disputeDetailsURI)`**: Allows a party to initiate a dispute over a task outcome or skill attestation.
22. **`resolveDispute(uint256 _disputeId, bool _requesterWins, uint256 _reputationPenaltyTwinId)`**: Called by governing body to resolve a dispute, potentially adjusting reputations or releasing funds.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; // For more granular roles

// Custom Errors for better gas efficiency and clarity
error Unauthorized();
error InvalidProposalState();
error AlreadyVoted();
error NotEnoughVotes();
error ProposalNotFound();
error SkillNotFound();
error TwinNotFound();
error TaskNotFound();
error BidNotFound();
error TaskNotAssigned();
error TaskNotCompleted();
error PaymentFailed();
error InvalidProficiencyLevel();
error InvalidDeadline();
error InsufficientFunds();
error SkillVerifierNotRegistered();
error DuplicateSkillProposal();
error BidAlreadyExists();
error TaskAlreadyAssigned();
error TaskAlreadyCompleted();
error NoActiveDispute();
error DisputeAlreadyResolved();

/**
 * @title ChronicleForgeProtocol
 * @dev A sophisticated smart contract for managing evolving Digital Twins, AI-attested skills,
 *      a decentralized task marketplace, adaptive fees, and progressive governance.
 */
contract ChronicleForgeProtocol is ERC721, Ownable, ReentrancyGuard, Pausable, AccessControl {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant GOVERNING_COUNCIL_ROLE = keccak256("GOVERNING_COUNCIL_ROLE");
    bytes32 public constant SKILL_VERIFIER_ROLE = keccak256("SKILL_VERIFIER_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE"); // For AI-driven attestations

    // --- State Variables ---

    Counters.Counter private _twinIds; // Counter for Digital Twin NFTs
    Counters.Counter private _skillProposalIds; // Counter for skill proposals
    Counters.Counter private _taskIds; // Counter for tasks
    Counters.Counter private _generalProposalIds; // Counter for general governance proposals
    Counters.Counter private _disputeIds; // Counter for disputes

    // --- Digital Twin Structures ---
    struct DigitalTwin {
        address owner;
        string metadataURI;
        uint256 reputation; // Accumulated reputation score
        uint256 lastActivityTime; // Timestamp of last significant activity
        bool exists; // To check if a twin ID is valid
    }
    mapping(uint256 => DigitalTwin) public digitalTwins; // twinId => DigitalTwin data
    mapping(uint256 => mapping(bytes32 => uint8)) public twinSkills; // twinId => skillHash => proficiencyLevel (0-100)

    // --- Skill Management ---
    struct Skill {
        string name;
        string description; // URI to detailed skill description
        bytes32 challengeHash; // Hash of off-chain challenge/test for this skill
        bool registered; // True if skill is officially added
    }
    mapping(bytes32 => Skill) public skills; // skillHash => Skill data
    mapping(bytes32 => address[]) public skillVerifiers; // skillHash => list of approved verifier addresses for this skill
    mapping(address => bool) public isAIOracle; // address => true if address is a registered AI Oracle

    struct SkillProposal {
        bytes32 skillHash;
        string skillName;
        string description;
        bytes32 challengeHash;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted;
        uint256 proposalEndTime;
        bool executed;
    }
    mapping(uint256 => SkillProposal) public skillProposals; // proposalId => SkillProposal data

    // --- Task Marketplace ---
    enum TaskStatus { Open, Assigned, Completed, Verified, Failed, Disputed }

    struct Task {
        address creator;
        string title;
        string descriptionURI;
        bytes32[] requiredSkills; // Hashes of skills required
        uint256 bountyAmount;
        uint256 deadline;
        TaskStatus status;
        uint256 assignedTwinId; // 0 if not assigned
        address assignedTwinOwner;
        string completionProofURI;
        mapping(uint256 => string) bids; // twinId => bidDetailsURI
        uint256 disputeId; // 0 if no active dispute
    }
    mapping(uint256 => Task) public tasks; // taskId => Task data

    // --- Governance ---
    enum ProposalType { ParameterChange, Other }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        ProposalType proposalType;
        bytes32 paramName; // For ParameterChange type
        bytes newValue;    // For ParameterChange type
        string descriptionURI; // For Other type
        uint256 proposerTwinId; // Twin that proposed it
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted; // address of the Twin owner who voted
        uint256 proposalEndTime;
        ProposalState state;
    }
    mapping(uint256 => GovernanceProposal) public generalProposals;

    // --- Adaptive Fee Model ---
    uint256 public baseServiceFeeBPS; // Base fee in Basis Points (e.g., 500 = 5%)
    uint256 public volatilityFactorBPS; // Factor influencing fee adaptation (e.g., 100 = 1%)
    address public priceOracleAddress; // Address of an external price oracle (e.g., Chainlink) for market context
    uint256 public lastFeeRecalculationTime;
    uint256 public currentAdaptiveFeeBPS; // The actual fee currently in effect
    uint256 public constant MIN_FEE_BPS = 100; // 1%
    uint256 public constant MAX_FEE_BPS = 2000; // 20%
    uint256 public constant RECALC_INTERVAL = 1 days; // Recalculate fees at most once a day

    // --- Dispute Resolution ---
    enum DisputeStatus { Open, Resolved }
    struct Dispute {
        uint256 targetId; // TaskId or TwinId
        bytes32 targetHash; // For skill attestations
        string disputeDetailsURI;
        address initiator;
        DisputeStatus status;
        bool requesterWins; // Outcome
    }
    mapping(uint256 => Dispute) public disputes;

    // --- Configuration Parameters (set by governance) ---
    uint256 public minReputationForVoting;
    uint256 public proposalVotingPeriod; // In seconds
    uint256 public skillProposalThreshold; // Min votes for skill proposal
    uint256 public generalProposalThreshold; // Min votes for general proposal
    uint256 public reputationGainPerSkillAttestation;
    uint256 public reputationGainPerTaskCompletion;
    uint256 public reputationPenaltyForMalice;

    // --- Events ---
    event DigitalTwinForged(uint256 indexed twinId, address indexed owner, string metadataURI);
    event TwinMetadataUpdated(uint256 indexed twinId, string newMetadataURI);
    event SkillProposed(uint256 indexed proposalId, bytes32 indexed skillHash, string skillName);
    event SkillRegistered(bytes32 indexed skillHash, string skillName);
    event SkillVerifierRegistered(bytes32 indexed skillHash, address indexed verifierAddress);
    event SkillProficiencyAttested(uint256 indexed twinId, bytes32 indexed skillHash, uint8 proficiencyLevel, address indexed attester);
    event TaskProposed(uint256 indexed taskId, address indexed creator, uint256 bountyAmount, bytes32[] requiredSkills);
    event TaskBid(uint256 indexed taskId, uint256 indexed twinId);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed twinId);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed twinId);
    event TaskVerified(uint256 indexed taskId, uint256 indexed twinId, bool successful);
    event ReputationAdjusted(uint256 indexed twinId, int256 changeAmount, uint256 newReputation);
    event GeneralProposalCreated(uint256 indexed proposalId, ProposalType proposalType, uint256 indexed proposerTwinId);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed proposalId);
    event AdaptiveFeeRecalculated(uint256 newFeeBPS);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed targetId, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, bool requesterWins);

    /**
     * @dev Constructor initializes the ERC721 token, Pausable, and AccessControl.
     *      Sets initial owner roles and default parameters.
     * @param _name Name of the NFT collection.
     * @param _symbol Symbol of the NFT collection.
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNING_COUNCIL_ROLE, msg.sender); // Initial Governing Council is deployer
        _setupRole(GOVERNING_COUNCIL_ROLE, msg.sender); // Deprecated in favor of _grantRole

        // Set initial configurable parameters
        minReputationForVoting = 100;
        proposalVotingPeriod = 7 days; // 7 days for proposals
        skillProposalThreshold = 5; // 5 positive votes to register a skill
        generalProposalThreshold = 10; // 10 positive votes to pass a general proposal
        reputationGainPerSkillAttestation = 10;
        reputationGainPerTaskCompletion = 20;
        reputationPenaltyForMalice = 50;

        // Set initial adaptive fee parameters (can be changed by governance later)
        baseServiceFeeBPS = 500; // 5%
        volatilityFactorBPS = 100; // 1%
        currentAdaptiveFeeBPS = baseServiceFeeBPS; // Start with base fee
        lastFeeRecalculationTime = block.timestamp;
    }

    // --- Access Control Modifiers ---
    modifier onlyGoverningCouncil() {
        if (!hasRole(GOVERNING_COUNCIL_ROLE, _msgSender())) revert Unauthorized();
        _;
    }

    modifier onlySkillVerifier(bytes32 _skillHash) {
        bool isVerifier = false;
        for (uint i = 0; i < skillVerifiers[_skillHash].length; i++) {
            if (skillVerifiers[_skillHash][i] == _msgSender()) {
                isVerifier = true;
                break;
            }
        }
        if (!isVerifier) revert Unauthorized();
        _;
    }

    modifier onlyAIOracle() {
        if (!isAIOracle[_msgSender()]) revert Unauthorized();
        _;
    }

    // --- Digital Twin Management (DD-NFT) ---

    /**
     * @dev Mints a new Digital Twin NFT.
     * @param _initialMetadataURI URI pointing to the initial metadata of the Digital Twin.
     * @return The ID of the newly forged Digital Twin.
     */
    function forgeDigitalTwin(string memory _initialMetadataURI) public whenNotPaused returns (uint256) {
        _twinIds.increment();
        uint256 newTwinId = _twinIds.current();

        digitalTwins[newTwinId] = DigitalTwin({
            owner: msg.sender,
            metadataURI: _initialMetadataURI,
            reputation: 0,
            lastActivityTime: block.timestamp,
            exists: true
        });

        _mint(msg.sender, newTwinId);
        _setTokenURI(newTwinId, _initialMetadataURI); // ERC721 tokenURI for off-chain metadata
        emit DigitalTwinForged(newTwinId, msg.sender, _initialMetadataURI);
        return newTwinId;
    }

    /**
     * @dev Allows the owner of a Digital Twin to update its off-chain metadata URI.
     * @param _twinId The ID of the Digital Twin to update.
     * @param _newMetadataURI The new URI for the metadata.
     */
    function updateTwinMetadata(uint256 _twinId, string memory _newMetadataURI) public whenNotPaused {
        if (ownerOf(_twinId) != msg.sender) revert Unauthorized();
        if (!digitalTwins[_twinId].exists) revert TwinNotFound();

        digitalTwins[_twinId].metadataURI = _newMetadataURI;
        _setTokenURI(_twinId, _newMetadataURI); // Update ERC721 tokenURI as well
        emit TwinMetadataUpdated(_twinId, _newMetadataURI);
    }

    // Overriding transfer functions to update owner in our custom struct
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        digitalTwins[tokenId].owner = to; // Update owner in our custom struct
    }

    // --- Skill Management ---

    /**
     * @dev Proposes a new skill for inclusion in the network.
     *      Anyone can propose, but it requires governance approval.
     * @param _skillName The human-readable name of the skill.
     * @param _description URI pointing to a detailed description of the skill.
     * @param _challengeHash A hash referencing an off-chain challenge or test for this skill.
     */
    function proposeNewSkill(string memory _skillName, string memory _description, bytes32 _challengeHash) public whenNotPaused {
        bytes32 skillHash = keccak256(abi.encodePacked(_skillName));
        if (skills[skillHash].registered || skillProposals[skillHash].proposalEndTime != 0) {
            revert DuplicateSkillProposal(); // Prevent proposing same skill twice
        }

        _skillProposalIds.increment();
        uint256 proposalId = _skillProposalIds.current();

        skillProposals[proposalId] = SkillProposal({
            skillHash: skillHash,
            skillName: _skillName,
            description: _description,
            challengeHash: _challengeHash,
            upvotes: 0,
            downvotes: 0,
            proposalEndTime: block.timestamp + proposalVotingPeriod,
            executed: false
        });

        emit SkillProposed(proposalId, skillHash, _skillName);
    }

    /**
     * @dev Allows eligible members (Digital Twin owners with minReputationForVoting) to vote on skill proposals.
     * @param _proposalId The ID of the skill proposal.
     * @param _approve True to upvote, false to downvote.
     */
    function voteOnSkillProposal(uint256 _proposalId, bool _approve) public whenNotPaused {
        SkillProposal storage proposal = skillProposals[_proposalId];
        if (proposal.proposalEndTime == 0 || proposal.executed) revert ProposalNotFound(); // Check if proposal exists and is not executed
        if (block.timestamp >= proposal.proposalEndTime) revert InvalidProposalState(); // Voting period ended

        uint256 voterTwinId = _getTwinIdByOwner(msg.sender);
        if (voterTwinId == 0 || digitalTwins[voterTwinId].reputation < minReputationForVoting) revert Unauthorized();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        if (_approve) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Registers a new skill if the proposal has enough upvotes and hasn't expired.
     *      Callable by anyone after the voting period ends.
     * @param _proposalId The ID of the skill proposal to execute.
     */
    function executeSkillProposal(uint256 _proposalId) public whenNotPaused {
        SkillProposal storage proposal = skillProposals[_proposalId];
        if (proposal.proposalEndTime == 0 || proposal.executed) revert ProposalNotFound();
        if (block.timestamp < proposal.proposalEndTime) revert InvalidProposalState(); // Voting period not ended
        if (proposal.upvotes < skillProposalThreshold) revert NotEnoughVotes();

        bytes32 skillHash = proposal.skillHash;
        if (skills[skillHash].registered) revert DuplicateSkillProposal(); // Already registered

        skills[skillHash] = Skill({
            name: proposal.skillName,
            description: proposal.description,
            challengeHash: proposal.challengeHash,
            registered: true
        });

        proposal.executed = true; // Mark proposal as executed
        emit SkillRegistered(skillHash, proposal.skillName);
    }

    /**
     * @dev Registers an address as a verifier for a specific skill. Only Governing Council can do this.
     * @param _skillHash The hash of the skill to register a verifier for.
     * @param _verifierAddress The address to register as a verifier.
     * @param _verifierInfoURI URI pointing to information about the verifier (e.g., credentials, AI model info).
     */
    function registerSkillVerifier(bytes32 _skillHash, address _verifierAddress, string memory _verifierInfoURI) public onlyGoverningCouncil whenNotPaused {
        if (!skills[_skillHash].registered) revert SkillNotFound();
        skillVerifiers[_skillHash].push(_verifierAddress);
        // If it's an AI Oracle, grant the role as well
        if (bytes(_verifierInfoURI).length > 0 && keccak256(abi.encodePacked(_verifierInfoURI)) == keccak256(abi.encodePacked("AI_ORACLE"))) {
            isAIOracle[_verifierAddress] = true;
            _grantRole(AI_ORACLE_ROLE, _verifierAddress);
        }
        emit SkillVerifierRegistered(_skillHash, _verifierAddress);
    }

    /**
     * @dev Attests to a Digital Twin's proficiency in a given skill. Only callable by registered Skill Verifiers.
     * @param _twinId The ID of the Digital Twin.
     * @param _skillHash The hash of the skill.
     * @param _proficiencyLevel The proficiency level (0-100).
     * @param _attestationProofURI URI pointing to proof of attestation (e.g., test results, AI analysis).
     */
    function attestSkillProficiency(uint256 _twinId, bytes32 _skillHash, uint8 _proficiencyLevel, string memory _attestationProofURI) public onlySkillVerifier(_skillHash) whenNotPaused {
        if (!digitalTwins[_twinId].exists) revert TwinNotFound();
        if (!skills[_skillHash].registered) revert SkillNotFound();
        if (_proficiencyLevel > 100) revert InvalidProficiencyLevel();

        uint8 currentProficiency = twinSkills[_twinId][_skillHash];
        if (_proficiencyLevel > currentProficiency) { // Only allow improvement, or specific governance overrides
            twinSkills[_twinId][_skillHash] = _proficiencyLevel;
            // Increase reputation based on new skill attestation
            _adjustReputation(_twinId, int256(reputationGainPerSkillAttestation));
        }

        digitalTwins[_twinId].lastActivityTime = block.timestamp;
        emit SkillProficiencyAttested(_twinId, _skillHash, _proficiencyLevel, msg.sender);
        // Potentially emit an event with attestationProofURI if needed for off-chain tools
    }

    /**
     * @dev Allows a Digital Twin owner to request an off-chain AI evaluation for a skill.
     *      This function primarily serves as an event trigger for off-chain AI services.
     *      The AI service, after evaluation, must call `_receiveAIResultAndAttest`.
     * @param _twinId The ID of the Digital Twin.
     * @param _skillHash The hash of the skill to be evaluated.
     * @param _evaluationRequestURI URI pointing to details of the evaluation request.
     */
    function requestAISkillEvaluation(uint256 _twinId, bytes32 _skillHash, string memory _evaluationRequestURI) public whenNotPaused {
        if (ownerOf(_twinId) != msg.sender) revert Unauthorized();
        if (!digitalTwins[_twinId].exists) revert TwinNotFound();
        if (!skills[_skillHash].registered) revert SkillNotFound();

        // Emit an event to be picked up by off-chain AI oracles
        emit Log("AISkillEvaluationRequested", _twinId, _skillHash, _evaluationRequestURI);
    }

    /**
     * @dev Internal (or restricted external) function to be called by a registered AI Oracle
     *      to submit evaluation results and attest to a skill.
     *      This is a critical security point; access MUST be strictly controlled by the AI_ORACLE_ROLE.
     * @param _twinId The ID of the Digital Twin.
     * @param _skillHash The hash of the skill.
     * @param _proficiencyLevel The proficiency level (0-100) determined by the AI.
     * @param _evaluationHash A hash of the detailed AI evaluation report (e.g., IPFS hash).
     * @param _aiOracleAddress The address of the AI oracle submitting the result.
     */
    function _receiveAIResultAndAttest(uint256 _twinId, bytes32 _skillHash, uint8 _proficiencyLevel, bytes32 _evaluationHash, address _aiOracleAddress) public onlyAIOracle {
        // This function acts as the secure callback for AI Oracles
        // It's called by the registered AI oracle address itself.
        // The _aiOracleAddress parameter is just for logging/verification, msg.sender must be the oracle.
        require(_aiOracleAddress == msg.sender, "AI Oracle address mismatch");

        // The actual attestation logic is handled by attestSkillProficiency
        attestSkillProficiency(_twinId, _skillHash, _proficiencyLevel, string(abi.encodePacked("ipfs://", Strings.toHexString(uint256(_evaluationHash)))));
    }


    // --- Task Marketplace ---

    /**
     * @dev Proposes a new task on the marketplace.
     *      Requires sending the bounty amount as value with the transaction.
     * @param _taskTitle A brief title for the task.
     * @param _descriptionURI URI to a detailed description of the task.
     * @param _requiredSkills An array of skill hashes required for the task.
     * @param _bountyAmount The reward for completing the task (in native token, e.g., Wei).
     * @param _deadline The timestamp by which the task must be completed.
     */
    function proposeTask(
        string memory _taskTitle,
        string memory _descriptionURI,
        bytes32[] memory _requiredSkills,
        uint256 _bountyAmount,
        uint256 _deadline
    ) public payable whenNotPaused {
        if (msg.value < _bountyAmount) revert InsufficientFunds();
        if (_deadline <= block.timestamp) revert InvalidDeadline();
        if (_bountyAmount == 0) revert InsufficientFunds(); // Bounty must be > 0

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            title: _taskTitle,
            descriptionURI: _descriptionURI,
            requiredSkills: _requiredSkills,
            bountyAmount: _bountyAmount,
            deadline: _deadline,
            status: TaskStatus.Open,
            assignedTwinId: 0,
            assignedTwinOwner: address(0),
            completionProofURI: "",
            disputeId: 0
        });

        // Transfer funds to the contract's treasury
        // funds remain in contract until task verified
        emit TaskProposed(newTaskId, msg.sender, _bountyAmount, _requiredSkills);
    }

    /**
     * @dev Allows a Digital Twin owner to bid on an open task.
     * @param _taskId The ID of the task to bid on.
     * @param _twinId The ID of the Digital Twin making the bid.
     * @param _bidDetailsURI URI pointing to details of the bid (e.g., proposal, portfolio).
     */
    function bidOnTask(uint256 _taskId, uint256 _twinId, string memory _bidDetailsURI) public whenNotPaused {
        if (ownerOf(_twinId) != msg.sender) revert Unauthorized();
        if (!digitalTwins[_twinId].exists) revert TwinNotFound();
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Open) revert InvalidProposalState(); // Task not open for bids
        if (task.bids[_twinId] != "") revert BidAlreadyExists(); // Twin already bid

        // Check if the bidding twin has the required skills (basic check, could be more complex)
        for (uint i = 0; i < task.requiredSkills.length; i++) {
            if (twinSkills[_twinId][task.requiredSkills[i]] == 0) {
                revert SkillNotFound(); // Twin does not have a required skill
            }
        }

        task.bids[_twinId] = _bidDetailsURI;
        digitalTwins[_twinId].lastActivityTime = block.timestamp;
        emit TaskBid(_taskId, _twinId);
    }

    /**
     * @dev The task creator assigns the task to a specific Digital Twin.
     * @param _taskId The ID of the task.
     * @param _bidTwinId The ID of the Digital Twin to assign the task to.
     */
    function assignTask(uint256 _taskId, uint256 _bidTwinId) public whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.creator != msg.sender) revert Unauthorized();
        if (task.status != TaskStatus.Open) revert TaskAlreadyAssigned();
        if (task.bids[_bidTwinId] == "") revert BidNotFound(); // Twin did not bid

        task.assignedTwinId = _bidTwinId;
        task.assignedTwinOwner = digitalTwins[_bidTwinId].owner;
        task.status = TaskStatus.Assigned;
        digitalTwins[_bidTwinId].lastActivityTime = block.timestamp;
        emit TaskAssigned(_taskId, _bidTwinId);
    }

    /**
     * @dev The assigned Digital Twin owner marks the task as completed.
     * @param _taskId The ID of the task.
     * @param _completionProofURI URI pointing to proof of completion.
     */
    function markTaskCompleted(uint256 _taskId, string memory _completionProofURI) public whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.Assigned) revert TaskNotAssigned();
        if (task.assignedTwinOwner != msg.sender) revert Unauthorized();
        if (block.timestamp > task.deadline) revert InvalidDeadline(); // Task completed after deadline

        task.completionProofURI = _completionProofURI;
        task.status = TaskStatus.Completed;
        digitalTwins[task.assignedTwinId].lastActivityTime = block.timestamp;
        emit TaskCompleted(_taskId, task.assignedTwinId);
    }

    /**
     * @dev The task creator verifies the task completion and releases payment.
     * @param _taskId The ID of the task.
     * @param _successful True if the task was completed successfully, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _successful) public nonReentrant whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.creator != msg.sender) revert Unauthorized();
        if (task.status != TaskStatus.Completed) revert TaskNotCompleted();

        task.status = _successful ? TaskStatus.Verified : TaskStatus.Failed;
        emit TaskVerified(_taskId, task.assignedTwinId, _successful);

        if (_successful) {
            // Calculate fee and send bounty
            uint256 fee = (task.bountyAmount * currentAdaptiveFeeBPS) / 10000; // currentAdaptiveFeeBPS is in BPS
            uint256 amountToTwin = task.bountyAmount - fee;

            // Transfer bounty to the assigned Twin owner
            (bool success, ) = payable(task.assignedTwinOwner).call{value: amountToTwin}("");
            if (!success) revert PaymentFailed();

            // Transfer fee to contract treasury (this contract itself acts as treasury)
            // No explicit transfer needed, as the bounty was already sent to this contract.
            // The fee amount remains in this contract.

            // Adjust reputation for successful completion
            _adjustReputation(task.assignedTwinId, int256(reputationGainPerTaskCompletion));
        } else {
            // Task failed, funds remain with creator (or dispute can change this)
            // No reputation change here, but dispute could lead to penalty
        }
    }

    // --- Reputation System ---

    /**
     * @dev Internal function to adjust a Digital Twin's reputation.
     *      Can be positive or negative.
     * @param _twinId The ID of the Digital Twin.
     * @param _reputationChange The amount to change reputation by (can be negative).
     */
    function _adjustReputation(uint256 _twinId, int256 _reputationChange) internal {
        DigitalTwin storage twin = digitalTwins[_twinId];
        if (!twin.exists) return; // Should not happen if called internally with valid twinId

        uint256 currentReputation = twin.reputation;
        if (_reputationChange > 0) {
            twin.reputation += uint256(_reputationChange);
        } else {
            uint256 absoluteChange = uint256(-_reputationChange);
            if (currentReputation < absoluteChange) {
                twin.reputation = 0;
            } else {
                twin.reputation -= absoluteChange;
            }
        }
        emit ReputationAdjusted(_twinId, _reputationChange, twin.reputation);
    }

    /**
     * @dev Allows Governing Council to directly adjust a Twin's reputation for specific reasons (e.g., fraud).
     * @param _twinId The ID of the Digital Twin.
     * @param _reputationChange The amount to change reputation by (can be negative).
     */
    function adjustReputation(uint256 _twinId, int256 _reputationChange) public onlyGoverningCouncil whenNotPaused {
        if (!digitalTwins[_twinId].exists) revert TwinNotFound();
        _adjustReputation(_twinId, _reputationChange);
    }

    // --- Progressive Governance ---

    /**
     * @dev Proposes a general change to contract parameters or other governance decisions.
     *      Requires a Digital Twin with sufficient reputation.
     * @param _paramName The name of the parameter to change (for ParameterChange type).
     * @param _newValue The new value for the parameter (for ParameterChange type).
     * @param _descriptionURI URI to a detailed description of the proposal.
     * @param _proposalType The type of the proposal.
     */
    function proposeParameterChange(
        bytes32 _paramName,
        bytes memory _newValue,
        string memory _descriptionURI,
        ProposalType _proposalType
    ) public whenNotPaused {
        uint256 proposerTwinId = _getTwinIdByOwner(msg.sender);
        if (proposerTwinId == 0 || digitalTwins[proposerTwinId].reputation < minReputationForVoting) revert Unauthorized();

        _generalProposalIds.increment();
        uint256 proposalId = _generalProposalIds.current();

        generalProposals[proposalId] = GovernanceProposal({
            proposalType: _proposalType,
            paramName: _paramName,
            newValue: _newValue,
            descriptionURI: _descriptionURI,
            proposerTwinId: proposerTwinId,
            upvotes: 0,
            downvotes: 0,
            proposalEndTime: block.timestamp + proposalVotingPeriod,
            state: ProposalState.Pending
        });

        emit GeneralProposalCreated(proposalId, _proposalType, proposerTwinId);
    }

    /**
     * @dev Allows eligible governance members (or high-reputation Twin owners) to vote on general proposals.
     * @param _proposalId The ID of the general proposal.
     * @param _approve True to upvote, false to downvote.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public whenNotPaused {
        GovernanceProposal storage proposal = generalProposals[_proposalId];
        if (proposal.proposalEndTime == 0 || proposal.state != ProposalState.Pending) revert ProposalNotFound();
        if (block.timestamp >= proposal.proposalEndTime) revert InvalidProposalState();

        uint256 voterTwinId = _getTwinIdByOwner(msg.sender);
        if (voterTwinId == 0 || digitalTwins[voterTwinId].reputation < minReputationForVoting) revert Unauthorized();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        if (_approve) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        // Check if proposal can transition to Succeeded or Failed early
        if (proposal.upvotes >= generalProposalThreshold) {
            proposal.state = ProposalState.Succeeded;
        } else if (proposal.downvotes > (proposal.upvotes + generalProposalThreshold)) { // Heuristic for early failure
            proposal.state = ProposalState.Failed;
        }

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a passed general governance proposal. Callable by anyone after voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant whenNotPaused {
        GovernanceProposal storage proposal = generalProposals[_proposalId];
        if (proposal.proposalEndTime == 0 || proposal.state == ProposalState.Executed) revert ProposalNotFound();
        if (block.timestamp < proposal.proposalEndTime) revert InvalidProposalState(); // Voting period not ended

        if (proposal.upvotes < generalProposalThreshold) {
            proposal.state = ProposalState.Failed;
            revert NotEnoughVotes();
        }

        if (proposal.state != ProposalState.Succeeded) {
             proposal.state = ProposalState.Failed; // Mark as failed if not explicitly succeeded earlier
             revert InvalidProposalState();
        }

        // Execute the parameter change
        if (proposal.proposalType == ProposalType.ParameterChange) {
            if (proposal.paramName == keccak256(abi.encodePacked("minReputationForVoting"))) {
                minReputationForVoting = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
                proposalVotingPeriod = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("skillProposalThreshold"))) {
                skillProposalThreshold = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("generalProposalThreshold"))) {
                generalProposalThreshold = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("reputationGainPerSkillAttestation"))) {
                reputationGainPerSkillAttestation = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("reputationGainPerTaskCompletion"))) {
                reputationGainPerTaskCompletion = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("reputationPenaltyForMalice"))) {
                reputationPenaltyForMalice = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("baseServiceFeeBPS"))) {
                baseServiceFeeBPS = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("volatilityFactorBPS"))) {
                volatilityFactorBPS = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.paramName == keccak256(abi.encodePacked("priceOracleAddress"))) {
                priceOracleAddress = abi.decode(proposal.newValue, (address));
            } else if (proposal.paramName == keccak256(abi.encodePacked("addGoverningCouncil"))) {
                address newCouncilMember = abi.decode(proposal.newValue, (address));
                _grantRole(GOVERNING_COUNCIL_ROLE, newCouncilMember);
            } else if (proposal.paramName == keccak256(abi.encodePacked("removeGoverningCouncil"))) {
                address oldCouncilMember = abi.decode(proposal.newValue, (address));
                _revokeRole(GOVERNING_COUNCIL_ROLE, oldCouncilMember);
            } else {
                revert InvalidProposalState(); // Unknown parameter
            }
        }
        // For 'Other' proposal types, this would trigger an internal function call or a separate logic based on descriptionURI
        // Example: if (proposal.proposalType == ProposalType.Other) { _handleOtherProposal(proposal.descriptionURI); }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    // --- Adaptive Fee Model ---

    /**
     * @dev Sets the parameters for the adaptive fee model.
     * @param _baseFee The base service fee in Basis Points (e.g., 500 for 5%).
     * @param _volatilityFactor The factor influencing fee adaptation (e.g., 100 for 1%).
     * @param _priceOracle The address of an external price oracle (e.g., Chainlink) for market context.
     */
    function setAdaptiveFeeModelParameters(uint256 _baseFee, uint256 _volatilityFactor, address _priceOracle) public onlyGoverningCouncil whenNotPaused {
        baseServiceFeeBPS = _baseFee;
        volatilityFactorBPS = _volatilityFactor;
        priceOracleAddress = _priceOracle;
        // Trigger immediate recalculation with new parameters
        _recalculateAdaptiveFees();
    }

    /**
     * @dev Calculates the dynamic service fee for a given base amount.
     *      This function does NOT change the global `currentAdaptiveFeeBPS`.
     * @param _baseAmount The base amount on which the fee is calculated.
     * @return The calculated fee amount.
     */
    function getDynamicServiceFee(uint256 _baseAmount) public view returns (uint256) {
        return (_baseAmount * currentAdaptiveFeeBPS) / 10000;
    }

    /**
     * @dev Triggers a recalculation of the current network-wide adaptive fees.
     *      This function can be called by anyone, but it's rate-limited.
     *      It simulates an adaptive fee model based on simplified metrics.
     */
    function triggerFeeRecalculation() public whenNotPaused {
        if (block.timestamp < lastFeeRecalculationTime + RECALC_INTERVAL) {
            revert("Fee recalculation too soon");
        }
        _recalculateAdaptiveFees();
        lastFeeRecalculationTime = block.timestamp;
        emit AdaptiveFeeRecalculated(currentAdaptiveFeeBPS);
    }

    /**
     * @dev Internal function to recalculate the adaptive fees based on network activity.
     *      This is a placeholder for a more complex economic model involving:
     *      - Number of active tasks
     *      - Number of recent skill attestations
     *      - External oracle data (e.g., gas prices, market volatility) via `priceOracleAddress`
     *      For simplicity, it uses a basic proportional model here.
     */
    function _recalculateAdaptiveFees() internal {
        uint256 totalActiveTasks = _taskIds.current() - _countTasksByStatus(TaskStatus.Verified) - _countTasksByStatus(TaskStatus.Failed);
        uint256 recentSkillAttestations = 0; // In a real system, this would be derived from event logs or a time-based counter

        // Simulate reading from an external price oracle (e.g., Chainlink)
        // For demonstration, we use a mock value. In production, integrate Chainlink AggregatorV3Interface.
        // uint256 currentEthPrice = IPriceOracle(priceOracleAddress).getLatestPrice(); // Example
        uint256 currentEthPrice = 2000e8; // Mock ETH price: 2000 USD, 8 decimals

        // Simple adaptive logic:
        // More active tasks -> slightly higher fee (demand)
        // Higher ETH price -> potentially lower BPS fee as value increases (affordability)
        uint256 calculatedFee = baseServiceFeeBPS;

        // Influence by active tasks (simple linear increase)
        calculatedFee += (totalActiveTasks / 10) * volatilityFactorBPS / 100; // +1% fee for every 10 active tasks

        // Influence by mock ETH price (inverse relation: higher price -> lower fee BPS)
        // This is a simplified example. A real model needs careful economic design.
        // If price goes up, fee BPS goes down to keep absolute fee somewhat stable.
        if (currentEthPrice > 1000e8) { // If price is high (e.g., > 1000 USD)
            calculatedFee -= ((currentEthPrice - 1000e8) / 100e8) * (volatilityFactorBPS / 500); // Reduce fee for every $100 increase
        } else if (currentEthPrice < 500e8) { // If price is low
            calculatedFee += ((500e8 - currentEthPrice) / 100e8) * (volatilityFactorBPS / 500); // Increase fee
        }


        // Ensure fee stays within bounds
        if (calculatedFee < MIN_FEE_BPS) calculatedFee = MIN_FEE_BPS;
        if (calculatedFee > MAX_FEE_BPS) calculatedFee = MAX_FEE_BPS;

        currentAdaptiveFeeBPS = calculatedFee;
    }

    /**
     * @dev Helper function to count tasks by a specific status.
     * @param _status The TaskStatus to count.
     * @return The number of tasks with the given status.
     */
    function _countTasksByStatus(TaskStatus _status) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _taskIds.current(); i++) {
            if (tasks[i].status == _status) {
                count++;
            }
        }
        return count;
    }

    // --- Dispute Resolution Module ---

    /**
     * @dev Allows a party to initiate a dispute over a task outcome or skill attestation.
     *      Only callable by the task creator, assigned Twin owner, or a Skill Verifier for attestations.
     * @param _taskId The ID of the task if the dispute is task-related (0 if not).
     * @param _twinId The ID of the Digital Twin if the dispute is skill-attestation related (0 if not).
     * @param _skillHash The skill hash if dispute is skill-attestation related.
     * @param _disputeDetailsURI URI to detailed dispute evidence/arguments.
     */
    function initiateDispute(
        uint256 _taskId,
        uint256 _twinId,
        bytes32 _skillHash,
        string memory _disputeDetailsURI
    ) public whenNotPaused {
        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        if (_taskId != 0) { // Task dispute
            Task storage task = tasks[_taskId];
            if (task.disputeId != 0) revert AlreadyVoted(); // Already disputed
            if (msg.sender != task.creator && msg.sender != task.assignedTwinOwner) revert Unauthorized();
            if (task.status != TaskStatus.Failed && task.status != TaskStatus.Verified) revert NoActiveDispute(); // Can only dispute failed or verified tasks

            disputes[newDisputeId] = Dispute({
                targetId: _taskId,
                targetHash: 0, // Not used for task disputes
                disputeDetailsURI: _disputeDetailsURI,
                initiator: msg.sender,
                status: DisputeStatus.Open,
                requesterWins: false
            });
            task.disputeId = newDisputeId; // Link dispute to task
        } else if (_twinId != 0 && _skillHash != 0) { // Skill attestation dispute
            // Need a way to link to an attestation, e.g., by checking recent attestations
            // For simplicity, allow any twin owner or skill verifier to dispute
            if (msg.sender != ownerOf(_twinId) && !hasRole(SKILL_VERIFIER_ROLE, msg.sender)) revert Unauthorized();
            if (twinSkills[_twinId][_skillHash] == 0) revert SkillNotFound(); // No such attestation

             disputes[newDisputeId] = Dispute({
                targetId: _twinId,
                targetHash: _skillHash,
                disputeDetailsURI: _disputeDetailsURI,
                initiator: msg.sender,
                status: DisputeStatus.Open,
                requesterWins: false
            });
        } else {
            revert InvalidProposalState(); // Must specify a task or twin/skill for dispute
        }

        emit DisputeInitiated(newDisputeId, _taskId != 0 ? _taskId : _twinId, msg.sender);
    }

    /**
     * @dev Resolves an open dispute. Only callable by the Governing Council.
     *      Can adjust reputation, reverse task outcomes, etc.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _requesterWins True if the dispute initiator wins, false otherwise.
     * @param _reputationPenaltyTwinId Optional: Twin ID to penalize reputation (0 if none).
     */
    function resolveDispute(uint256 _disputeId, bool _requesterWins, uint256 _reputationPenaltyTwinId) public onlyGoverningCouncil whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.status != DisputeStatus.Open) revert DisputeAlreadyResolved();

        dispute.status = DisputeStatus.Resolved;
        dispute.requesterWins = _requesterWins;

        if (dispute.targetId != 0 && dispute.targetHash == 0) { // Task Dispute
            Task storage task = tasks[dispute.targetId];
            if (_requesterWins) { // Initiator wins (e.g., creator says "failed", twin says "succeeded" and wins)
                // Reverse previous verification logic or apply new logic
                if (task.status == TaskStatus.Failed) { // If original was 'Failed', and twin won dispute
                    // Re-process as successful
                    uint256 fee = (task.bountyAmount * currentAdaptiveFeeBPS) / 10000;
                    uint256 amountToTwin = task.bountyAmount - fee;
                    (bool success, ) = payable(task.assignedTwinOwner).call{value: amountToTwin}("");
                    if (!success) revert PaymentFailed();
                    _adjustReputation(task.assignedTwinId, int256(reputationGainPerTaskCompletion));
                    task.status = TaskStatus.Verified;
                } else if (task.status == TaskStatus.Verified) { // If original was 'Verified', and creator won dispute
                    // Revert payment (complex, usually not done on-chain)
                    // For simplicity, just penalize twin
                    _adjustReputation(task.assignedTwinId, -int256(reputationPenaltyForMalice));
                    task.status = TaskStatus.Failed;
                }
            } else { // Initiator loses
                // If initiator was twin and lost, penalize
                if (task.creator == dispute.initiator && task.status == TaskStatus.Verified) {
                    _adjustReputation(task.assignedTwinId, -int256(reputationPenaltyForMalice));
                }
            }
        } else if (dispute.targetId != 0 && dispute.targetHash != 0) { // Skill Attestation Dispute
            if (_requesterWins) { // If Twin owner disputed and won, or Verifier disputed another verifier's attestation and won
                // Could reduce proficiency, or reset attestation to 0
                twinSkills[dispute.targetId][dispute.targetHash] = 0; // Reset proficiency
                _adjustReputation(dispute.targetId, -int256(reputationPenaltyForMalice)); // Penalty for bad attestation (if disputer was attester)
            } else { // Requester lost
                _adjustReputation(dispute.targetId, -int256(reputationPenaltyForMalice)); // Penalty for frivolous dispute if targetId is the Twin who initiated
            }
        }

        if (_reputationPenaltyTwinId != 0) {
             _adjustReputation(_reputationPenaltyTwinId, -int256(reputationPenaltyForMalice));
        }

        emit DisputeResolved(_disputeId, _requesterWins);
    }

    // --- View Functions ---

    /**
     * @dev Retrieves a Digital Twin's current skills and proficiency levels.
     * @param _twinId The ID of the Digital Twin.
     * @return An array of skill hashes and an array of their corresponding proficiency levels.
     */
    function getTwinSkills(uint256 _twinId) public view returns (bytes32[] memory, uint8[] memory) {
        require(digitalTwins[_twinId].exists, "Twin not found");
        // This is inefficient for many skills. A mapping of skillHash to struct is better,
        // but iterating over all possible skills to return existing ones is bad.
        // In a real dApp, you'd track skills more efficiently or rely on off-chain indexing.
        // For this example, we'll return all skills and their current proficiency.
        // Better: have a mapping like mapping(uint256 => bytes32[]) private _twinToSkillsList;
        // For simplicity, we'll return current proficiency for all *registered* skills.
        uint256 registeredSkillCount = 0;
        for(uint i=1; i<=_skillProposalIds.current(); i++){ // Assuming skill IDs are sequential or trackable
            if(skillProposals[i].executed && skills[skillProposals[i].skillHash].registered){
                registeredSkillCount++;
            }
        }

        bytes32[] memory currentSkills = new bytes32[](registeredSkillCount);
        uint8[] memory currentProficiencies = new uint8[](registeredSkillCount);
        uint256 currentIndex = 0;
        for(uint i=1; i<=_skillProposalIds.current(); i++){
            bytes32 skillHash = skillProposals[i].skillHash;
            if(skillProposals[i].executed && skills[skillHash].registered){
                 currentSkills[currentIndex] = skillHash;
                 currentProficiencies[currentIndex] = twinSkills[_twinId][skillHash];
                 currentIndex++;
            }
        }
        return (currentSkills, currentProficiencies);
    }

    /**
     * @dev Get total number of Digital Twins minted.
     */
    function getTotalTwins() public view returns (uint256) {
        return _twinIds.current();
    }

    /**
     * @dev Get current balance of the contract (treasury).
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal Helpers ---
    /**
     * @dev Helper to find a Twin ID owned by a specific address.
     *      Note: An address can own multiple Twins. This returns the first one found.
     *      For a real dApp, you'd likely map address => list of Twin IDs.
     */
    function _getTwinIdByOwner(address _owner) internal view returns (uint256) {
        for (uint256 i = 1; i <= _twinIds.current(); i++) {
            if (digitalTwins[i].exists && digitalTwins[i].owner == _owner) {
                return i;
            }
        }
        return 0;
    }

    // --- Pausable Functions ---
    /**
     * @dev Pauses the contract. Only callable by the owner (or ADMIN_ROLE).
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner (or ADMIN_ROLE).
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // Fallback function to accept payments
    receive() external payable {}
    fallback() external payable {}

    // Debugging event (can be removed in production)
    event Log(string message, uint256 arg1, bytes32 arg2, string arg3);
}

// Interface for a mock price oracle (e.g., Chainlink AggregatorV3Interface)
// interface IPriceOracle {
//     function getLatestPrice() external view returns (uint256 price);
// }

```