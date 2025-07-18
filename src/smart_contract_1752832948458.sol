This smart contract, "CognitoNexus," is designed to create a decentralized reputation and skill network primarily for AI agents or other autonomous entities. It addresses the need for verifiable credentials, dynamic reputation, and trust in a decentralized environment by introducing novel concepts like stake-backed attestations and reputation loans.

**Outline:**

*   **I. Agent Management:** Registration, profile updates, and deactivation for autonomous agents participating in the network.
*   **II. Skill & Competency Management:** A system for defining skills, allowing agents to declare their proficiencies, and managing these declarations.
*   **III. Attestation System:** A core mechanism for agents to issue verifiable attestations (similar to verifiable credentials) about other agents' skills or task performance. These attestations are backed by staked tokens and can be formally challenged and resolved.
*   **IV. Reputation System:** A dynamic, multi-dimensional reputation scoring model (Trust, Competence, Reliability) that evolves based on attestations, task performance, and active staking, with built-in decay over time.
*   **V. Task & Project Market:** A simplified marketplace where creators can post tasks requiring specific skills, agents can express interest, be assigned, complete tasks, and initiate dispute resolution.
*   **VI. Advanced Concepts:** Introduces the innovative concept of "Reputation Loans" where high-reputation agents can temporarily lend a reputation boost to others for a fee and collateral, along with administrative functions for severe misconduct.

**Function Summary:**

1.  **`registerAgent(string _name, string _profileCID)`**: Registers a new agent profile on the network with a unique name and an IPFS CID for their extended profile.
2.  **`updateAgentProfile(string _newName, string _newProfileCID)`**: Allows an existing registered agent to update their public name and profile CID.
3.  **`deactivateAgent()`**: Temporarily deactivates an agent's profile, making them inactive for new tasks or attestations.
4.  **`declareAgentSkill(bytes32 _skillId)`**: Enables an active agent to formally declare their proficiency in a specific, approved skill.
5.  **`addSkillDefinition(string _name, string _descriptionCID, bytes32 _parentSkillId)`**: (Admin/Owner function) Adds a new official skill definition to the network's taxonomy, optionally linking it to a parent skill for hierarchical structuring.
6.  **`revokeAgentSkillDeclaration(bytes32 _skillId)`**: Allows an agent to retract a previously declared skill from their profile.
7.  **`getAgentDeclaredSkills(address _agentAddress)`**: A view function to retrieve all skills an agent has formally declared.
8.  **`issueSkillAttestation(address _subjectAgent, bytes32 _skillId, uint8 _score, string _contextCID, uint256 _attesterStakeAmount)`**: An active agent issues a verifiable attestation for another agent's skill, providing a score (1-100) and staking a specified amount of tokens to back their claim.
9.  **`issuePerformanceAttestation(address _subjectAgent, bytes32 _taskId, uint8 _score, string _contextCID, uint256 _attesterStakeAmount)`**: The creator of a task issues a verifiable attestation for the assigned agent's performance on a specific completed task, including a score (1-100) and a token stake.
10. **`getAttestationDetails(bytes32 _attestationId)`**: A view function to retrieve the full details of a specific attestation (skill or performance).
11. **`challengeAttestation(bytes32 _attestationId, string _reasonCID, uint256 _challengerStakeAmount)`**: Allows an agent to challenge the validity of an existing attestation within a specific timeframe, locking their own tokens as collateral for the challenge.
12. **`resolveAttestationChallenge(bytes32 _attestationId, bool _isValid)`**: (Admin/Owner function) Resolves a formal challenge against an attestation, determining if the original attestation was valid or not, and distributing/slashing the stakes of the attester and challenger accordingly.
13. **`getAgentReputation(address _agentAddress)`**: Retrieves the dynamically calculated multi-dimensional reputation scores (Trust, Competence, Reliability) for a given agent, considering decay and active boosts.
14. **`stakeForReputationBoost(uint256 _amount)`**: Allows an agent to stake additional tokens to temporarily boost their perceived reputation scores.
15. **`unstakeFromReputationBoost(uint256 _amount)`**: Allows an agent to unstake tokens previously committed for a reputation boost.
16. **`createTask(string _title, string _descriptionCID, bytes32[] _requiredSkills, uint256 _bountyAmount, uint256 _deadline)`**: A registered agent creates a new task, specifying required skills, a bounty amount (which is locked in escrow), and a deadline.
17. **`bidOnTask(bytes32 _taskId)`**: An agent expresses interest in performing an open task, implicitly signalling their availability and general suitability.
18. **`assignTask(bytes32 _taskId, address _agentAddress)`**: The task creator assigns an open task to a specific agent, performing checks on the agent's declared skills and reputation.
19. **`completeTask(bytes32 _taskId, string _proofCID)`**: The assigned agent marks a task as completed and provides an IPFS CID pointing to their proof of work.
20. **`requestTaskDisputeResolution(bytes32 _taskId, string _reasonCID)`**: Either the task creator or the assigned agent can initiate a formal dispute over the task's completion or quality.
21. **`resolveTaskDispute(bytes32 _taskId, bool _agentSucceeded)`**: (Admin/Owner function) Resolves a disputed task, determining if the assigned agent successfully completed the task and distributing the bounty (to agent or back to creator) and adjusting reputations accordingly.
22. **`grantReputationLoan(address _borrower, uint256 _loanReputationAmount, uint256 _collateralAmount, uint256 _durationSeconds)`**: An innovative function allowing a high-reputation agent (lender) to temporarily "lend" a specified amount of reputation points to another agent (borrower) for a defined duration, backed by the lender's collateral.
23. **`repayReputationLoan(bytes32 _loanId)`**: The borrower of a reputation loan repays the collateral amount (plus a small fee for the protocol) to reclaim their reputation and release the lender's collateral.
24. **`claimExpiredLoanCollateral(bytes32 _loanId)`**: Allows a lender to claim their collateral if the borrower fails to repay a reputation loan by its expiration deadline.
25. **`punishAgent(address _agentAddress, int256 _penaltyAmount, string _reasonCID)`**: (Admin/Owner function) Directly reduces an agent's multi-dimensional reputation scores by a specified penalty amount, typically used in cases of severe misconduct after off-chain or dispute resolution processes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For `sub` etc. on `uint256`

// Outline:
// I. Agent Management: Registration, profile updates, deactivation.
// II. Skill & Competency Management: Declaring skills, defining new skills, revocation.
// III. Attestation System: Issuing verifiable skill & performance attestations, challenging, and resolving disputes over attestations.
// IV. Reputation System: Dynamic, multi-dimensional reputation score calculation, reputation boosting via staking.
// V. Task & Project Market: Creating tasks with skill requirements, agent bidding, task assignment, completion, and dispute initiation.
// VI. Advanced Concepts: Reputation loans (borrowing/lending temporary reputation boosts), administrative punishment, collateral reclamation.

// Function Summary:
// 1.  registerAgent(string _name, string _profileCID): Registers a new agent profile.
// 2.  updateAgentProfile(string _newName, string _newProfileCID): Updates an existing agent's name and profile CID.
// 3.  deactivateAgent(): Deactivates an agent's profile, making them inactive for tasks/attestations.
// 4.  declareAgentSkill(bytes32 _skillId): Allows an agent to declare proficiency in a specific skill.
// 5.  addSkillDefinition(string _name, string _descriptionCID, bytes32 _parentSkillId): (Admin) Adds a new skill definition to the protocol.
// 6.  revokeAgentSkillDeclaration(bytes32 _skillId): Agent revokes a previously declared skill.
// 7.  getAgentDeclaredSkills(address _agentAddress): View function to retrieve an agent's declared skills.
// 8.  issueSkillAttestation(address _subjectAgent, bytes32 _skillId, uint8 _score, string _contextCID, uint256 _attesterStakeAmount): An agent issues an attestation for another agent's skill, staking tokens.
// 9.  issuePerformanceAttestation(address _subjectAgent, bytes32 _taskId, uint8 _score, string _contextCID, uint256 _attesterStakeAmount): An agent issues an attestation for another agent's performance on a task, staking tokens.
// 10. getAttestationDetails(bytes32 _attestationId): View function to retrieve details of a specific attestation.
// 11. challengeAttestation(bytes32 _attestationId, string _reasonCID, uint256 _challengerStakeAmount): Initiates a challenge against an attestation, locking the challenger's stake.
// 12. resolveAttestationChallenge(bytes32 _attestationId, bool _isValid): (Admin) Resolves an attestation challenge, distributing/slashing stakes.
// 13. getAgentReputation(address _agentAddress): Retrieves the current multi-dimensional reputation score of an agent.
// 14. stakeForReputationBoost(uint256 _amount): Allows an agent to stake tokens to temporarily boost their reputation.
// 15. unstakeFromReputationBoost(uint256 _amount): Allows an agent to unstake their tokens from a reputation boost.
// 16. createTask(string _title, string _descriptionCID, bytes32[] _requiredSkills, uint256 _bountyAmount, uint256 _deadline): Creates a new task, locking the bounty.
// 17. bidOnTask(bytes32 _taskId): An agent indicates interest in performing a task.
// 18. assignTask(bytes32 _taskId, address _agentAddress): The task creator assigns the task to a bidding agent.
// 19. completeTask(bytes32 _taskId, string _proofCID): The assigned agent marks a task as complete and provides proof.
// 20. requestTaskDisputeResolution(bytes32 _taskId, string _reasonCID): Initiates a dispute over a task's completion or quality.
// 21. resolveTaskDispute(bytes32 _taskId, bool _agentSucceeded): (Admin) Resolves a task dispute, determining payment and reputation impact.
// 22. grantReputationLoan(address _borrower, uint256 _loanReputationAmount, uint256 _collateralAmount, uint256 _durationSeconds): Allows a high-reputation agent to temporarily lend reputation to another agent against collateral.
// 23. repayReputationLoan(bytes32 _loanId): The borrower repays a reputation loan, reclaiming their collateral.
// 24. claimExpiredLoanCollateral(bytes32 _loanId): Lender claims collateral if borrower fails to repay a reputation loan by its deadline.
// 25. punishAgent(address _agentAddress, int256 _penaltyAmount, string _reasonCID): (Admin) Decreases an agent's reputation score as a penalty for misconduct.

// Note: Reputation scores are scaled by 100 to allow for decimal precision with integers.
// A score of 10000 represents 100.00.

contract CognitoNexus is Ownable {
    using SafeMath for uint256;

    IERC20 public cognitoToken;

    // --- Enums ---
    enum AgentStatus { Inactive, Active } // Inactive is default (0)
    enum AttestationStatus { Valid, Challenged, Revoked }
    enum TaskStatus { Open, Assigned, Completed, Disputed, Resolved }

    // --- Structs ---
    struct AgentInfo {
        string name;
        string profileCID;
        AgentStatus status;
        uint256 lastActivityTimestamp;
        uint256 stakedTokens; // For reputation boost
        mapping(bytes32 => bool) declaredSkills; // For quick lookup of declared skills
    }

    struct SkillInfo {
        string name;
        string descriptionCID;
        bytes32 parentSkillId; // For hierarchical skills (0x0 for root)
        bool isApproved; // Set by admin/DAO
    }

    struct AttestationInfo {
        address attester;
        address subject;
        bytes32 skillOrTaskId; // Can be skillId or taskId
        uint8 score; // 1-100
        string contextCID; // IPFS CID for detailed context/proof
        uint256 timestamp;
        AttestationStatus status;
        uint256 attesterStake;
        uint256 challengerStake;
        address challenger;
        bool isPerformanceAttestation; // true if for task performance, false for skill
    }

    struct ReputationScore {
        int256 trustScore;
        int256 competenceScore;
        int256 reliabilityScore;
        uint256 lastUpdatedTimestamp;
    }

    struct TaskInfo {
        address creator;
        string title;
        string descriptionCID;
        bytes32[] requiredSkills;
        uint256 bountyAmount;
        uint256 deadline;
        address assignedAgent;
        TaskStatus status;
        string proofCID;
        uint256 escrowBalance;
    }

    struct ReputationLoanInfo {
        address borrower;
        address lender;
        uint256 loanReputationAmount; // The amount of reputation points lent
        uint256 collateralAmount; // Tokens staked by the lender as collateral
        uint256 creationTimestamp; // Timestamp when the loan was granted
        uint256 expirationTimestamp;
        bool repaid;
        bool claimedByLender;
    }

    // --- Mappings ---
    mapping(address => AgentInfo) public agents;
    mapping(bytes32 => SkillInfo) public skills; // skillId => SkillInfo
    mapping(bytes32 => AttestationInfo) public attestations; // attestationId => AttestationInfo
    mapping(address => ReputationScore) private _reputationScores; // private to enforce calculation via getter
    mapping(bytes32 => TaskInfo) public tasks; // taskId => TaskInfo
    mapping(bytes32 => ReputationLoanInfo) public reputationLoans; // loanId => ReputationLoanInfo

    // --- Arrays for easier iteration/querying (consider gas for large arrays) ---
    // Note: For production, consider using more gas-efficient linked lists or explicit indices in mappings.
    // For this demonstration, simpler array logic is used.
    mapping(address => bytes32[]) public agentDeclaredSkillsList; // agentAddress => list of skillIds
    mapping(address => bytes32[]) public agentAttestationsIssued; // attesterAddress => list of attestationIds
    mapping(address => bytes32[]) public agentAttestationsReceived; // subjectAddress => list of attestationIds
    mapping(address => bytes32[]) public agentTasksCreated; // creatorAddress => list of taskIds
    mapping(address => bytes32[]) public agentTasksAssigned; // assignedAgentAddress => list of taskIds
    mapping(address => bytes32[]) public agentReputationLoansBorrowed; // borrowerAddress => list of loanIds
    mapping(address => bytes32[]) public agentReputationLoansLent; // lenderAddress => list of loanIds

    // --- Constants ---
    uint256 public constant INITIAL_REPUTATION_SCORE = 50000; // 500.00, scaled by 100
    uint256 public constant REPUTATION_DECAY_RATE_PER_DAY = 1; // 0.01% per day (1/10000)
    uint256 public constant STAKE_REPUTATION_FACTOR = 1000; // 1 staked token adds 1/1000 to reputation points
    uint256 public constant MIN_ATTESTATION_SCORE = 1;
    uint256 public constant MAX_ATTESTATION_SCORE = 100;
    uint256 public constant ATTESTATION_CHALLENGE_PERIOD = 7 days; // Period to challenge an attestation
    uint256 public constant TASK_BOUNTY_PROTOCOL_FEE_PERCENT = 1; // 1% fee on task bounties (for protocol/treasury)
    uint256 public constant REPAYMENT_PROTOCOL_FEE_BPS = 10; // 0.1% (10 basis points) fee on loan repayment collateral

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, string name, string profileCID);
    event AgentProfileUpdated(address indexed agentAddress, string newName, string newProfileCID);
    event AgentDeactivated(address indexed agentAddress);
    event SkillDeclared(address indexed agentAddress, bytes32 indexed skillId);
    event SkillDefinitionAdded(bytes32 indexed skillId, string name, bytes32 parentSkillId);
    event SkillAttestationIssued(bytes32 indexed attestationId, address indexed attester, address indexed subject, bytes32 skillId, uint8 score);
    event PerformanceAttestationIssued(bytes32 indexed attestationId, address indexed attester, address indexed subject, bytes32 taskId, uint8 score);
    event AttestationChallenged(bytes32 indexed attestationId, address indexed challenger, string reasonCID);
    event AttestationChallengeResolved(bytes32 indexed attestationId, bool isValid, uint256 attesterStakeReleased, uint256 challengerStakeReleased);
    event ReputationUpdated(address indexed agentAddress, int256 trustScore, int256 competenceScore, int256 reliabilityScore);
    event ReputationBoostStaked(address indexed agentAddress, uint256 amount);
    event ReputationBoostUnstaked(address indexed agentAddress, uint256 amount);
    event TaskCreated(bytes32 indexed taskId, address indexed creator, uint256 bountyAmount, uint256 deadline);
    event TaskBid(bytes32 indexed taskId, address indexed agentAddress);
    event TaskAssigned(bytes32 indexed taskId, address indexed assignedAgent);
    event TaskCompleted(bytes32 indexed taskId, address indexed assignedAgent, string proofCID);
    event TaskDisputeRequested(bytes32 indexed taskId, address indexed disputer, string reasonCID);
    event TaskDisputeResolved(bytes32 indexed taskId, address indexed assignedAgent, bool agentSucceeded);
    event ReputationLoanGranted(bytes32 indexed loanId, address indexed borrower, address indexed lender, uint256 loanReputationAmount, uint256 collateralAmount, uint256 expirationTimestamp);
    event ReputationLoanRepaid(bytes32 indexed loanId, address indexed borrower, address indexed lender);
    event ReputationLoanCollateralClaimed(bytes32 indexed loanId, address indexed lender, uint256 claimedAmount);
    event AgentPunished(address indexed agentAddress, int256 penaltyAmount, string reasonCID);

    // Modifier to ensure the caller is an active registered agent
    modifier onlyRegisteredAgent() {
        require(agents[msg.sender].status == AgentStatus.Active, "CognitoNexus: Caller is not an active registered agent.");
        _;
    }

    /**
     * @dev Constructor sets the ERC20 token address used for all token-based operations.
     * @param _cognitoTokenAddress The address of the ERC20 token contract.
     */
    constructor(address _cognitoTokenAddress) Ownable(msg.sender) { // Set deployer as initial owner
        require(_cognitoTokenAddress != address(0), "CognitoNexus: Token address cannot be zero.");
        cognitoToken = IERC20(_cognitoTokenAddress);
    }

    // --- I. Agent Management ---

    /**
     * @dev Registers a new agent profile. An agent can only be registered once.
     * @param _name The human-readable name of the agent.
     * @param _profileCID The IPFS CID pointing to the agent's detailed profile.
     */
    function registerAgent(string calldata _name, string calldata _profileCID) external {
        require(agents[msg.sender].status == AgentStatus.Inactive, "CognitoNexus: Agent already registered.");
        require(bytes(_name).length > 0, "CognitoNexus: Agent name cannot be empty.");

        agents[msg.sender].name = _name;
        agents[msg.sender].profileCID = _profileCID;
        agents[msg.sender].status = AgentStatus.Active;
        agents[msg.sender].lastActivityTimestamp = block.timestamp;

        // Initialize reputation score for new agent
        _reputationScores[msg.sender] = ReputationScore({
            trustScore: int256(INITIAL_REPUTATION_SCORE),
            competenceScore: int256(INITIAL_REPUTATION_SCORE),
            reliabilityScore: int256(INITIAL_REPUTATION_SCORE),
            lastUpdatedTimestamp: block.timestamp
        });

        emit AgentRegistered(msg.sender, _name, _profileCID);
    }

    /**
     * @dev Updates an existing agent's name and profile CID.
     * @param _newName The new human-readable name for the agent.
     * @param _newProfileCID The new IPFS CID for the agent's detailed profile.
     */
    function updateAgentProfile(string calldata _newName, string calldata _newProfileCID) external onlyRegisteredAgent {
        require(bytes(_newName).length > 0, "CognitoNexus: Agent name cannot be empty.");
        agents[msg.sender].name = _newName;
        agents[msg.sender].profileCID = _newProfileCID;
        _updateAgentActivity(msg.sender);
        emit AgentProfileUpdated(msg.sender, _newName, _newProfileCID);
    }

    /**
     * @dev Deactivates an agent's profile, making them inactive for tasks/attestations.
     *      An inactive agent cannot participate in new protocol activities but their reputation history remains.
     */
    function deactivateAgent() external onlyRegisteredAgent {
        agents[msg.sender].status = AgentStatus.Inactive;
        emit AgentDeactivated(msg.sender);
    }

    // --- II. Skill & Competency Management ---

    /**
     * @dev Allows an agent to declare proficiency in a specific skill.
     *      The skill must be an approved definition in the protocol.
     * @param _skillId The unique identifier of the skill.
     */
    function declareAgentSkill(bytes32 _skillId) external onlyRegisteredAgent {
        require(skills[_skillId].isApproved, "CognitoNexus: Skill not approved or does not exist.");
        require(!agents[msg.sender].declaredSkills[_skillId], "CognitoNexus: Agent already declared this skill.");

        agents[msg.sender].declaredSkills[_skillId] = true;
        agentDeclaredSkillsList[msg.sender].push(_skillId);
        _updateAgentActivity(msg.sender);
        emit SkillDeclared(msg.sender, _skillId);
    }

    /**
     * @dev (Admin function) Adds a new skill definition to the protocol.
     *      This function is restricted to the contract owner to maintain quality control.
     * @param _name The name of the skill.
     * @param _descriptionCID The IPFS CID for the skill's detailed description.
     * @param _parentSkillId Optional. The unique ID of a parent skill for hierarchical categorization (0x0 for root skills).
     */
    function addSkillDefinition(string calldata _name, string calldata _descriptionCID, bytes32 _parentSkillId) external onlyOwner {
        bytes32 skillId = keccak256(abi.encodePacked(_name, _descriptionCID)); // Hash name and description for ID
        require(!skills[skillId].isApproved, "CognitoNexus: Skill definition already exists.");
        if (_parentSkillId != bytes32(0)) {
            require(skills[_parentSkillId].isApproved, "CognitoNexus: Parent skill must be approved.");
        }

        skills[skillId] = SkillInfo({
            name: _name,
            descriptionCID: _descriptionCID,
            parentSkillId: _parentSkillId,
            isApproved: true
        });
        emit SkillDefinitionAdded(skillId, _name, _parentSkillId);
    }

    /**
     * @dev Allows an agent to retract a previously declared skill.
     * @param _skillId The unique identifier of the skill to revoke.
     */
    function revokeAgentSkillDeclaration(bytes32 _skillId) external onlyRegisteredAgent {
        require(agents[msg.sender].declaredSkills[_skillId], "CognitoNexus: Agent has not declared this skill.");

        agents[msg.sender].declaredSkills[_skillId] = false;
        // Efficiently remove from array using swap-and-pop
        uint256 currentLength = agentDeclaredSkillsList[msg.sender].length;
        for (uint256 i = 0; i < currentLength; i++) {
            if (agentDeclaredSkillsList[msg.sender][i] == _skillId) {
                agentDeclaredSkillsList[msg.sender][i] = agentDeclaredSkillsList[msg.sender][currentLength - 1];
                agentDeclaredSkillsList[msg.sender].pop();
                break;
            }
        }
        _updateAgentActivity(msg.sender);
    }

    /**
     * @dev A view function to retrieve all skills an agent has formally declared.
     * @param _agentAddress The address of the agent.
     * @return An array of skill IDs declared by the agent.
     */
    function getAgentDeclaredSkills(address _agentAddress) external view returns (bytes32[] memory) {
        return agentDeclaredSkillsList[_agentAddress];
    }

    // --- III. Attestation System ---

    /**
     * @dev An agent issues an attestation for another agent's skill. The attester stakes tokens
     *      to back the validity of their attestation, which influences reputation calculation.
     * @param _subjectAgent The address of the agent being attested.
     * @param _skillId The ID of the skill being attested to.
     * @param _score The score for the skill (1-100).
     * @param _contextCID An IPFS CID pointing to detailed context or proof for the attestation.
     * @param _attesterStakeAmount The amount of tokens the attester stakes.
     */
    function issueSkillAttestation(address _subjectAgent, bytes32 _skillId, uint8 _score, string calldata _contextCID, uint256 _attesterStakeAmount) external onlyRegisteredAgent {
        require(agents[_subjectAgent].status == AgentStatus.Active, "CognitoNexus: Subject agent not active.");
        require(skills[_skillId].isApproved, "CognitoNexus: Skill not approved or does not exist.");
        require(_subjectAgent != msg.sender, "CognitoNexus: Cannot attest to your own skill.");
        require(_score >= MIN_ATTESTATION_SCORE && _score <= MAX_ATTESTATION_SCORE, "CognitoNexus: Score out of range (1-100).");
        require(_attesterStakeAmount > 0, "CognitoNexus: Attester stake must be positive.");

        require(cognitoToken.transferFrom(msg.sender, address(this), _attesterStakeAmount), "CognitoNexus: Token transfer for attester stake failed.");

        bytes32 attestationId = keccak256(abi.encodePacked(msg.sender, _subjectAgent, _skillId, block.timestamp));
        attestations[attestationId] = AttestationInfo({
            attester: msg.sender,
            subject: _subjectAgent,
            skillOrTaskId: _skillId,
            score: _score,
            contextCID: _contextCID,
            timestamp: block.timestamp,
            status: AttestationStatus.Valid,
            attesterStake: _attesterStakeAmount,
            challengerStake: 0,
            challenger: address(0),
            isPerformanceAttestation: false
        });

        agentAttestationsIssued[msg.sender].push(attestationId);
        agentAttestationsReceived[_subjectAgent].push(attestationId);
        _updateReputationBasedOnAttestation(_subjectAgent, _score, true); // Update subject's reputation
        _updateAgentActivity(msg.sender);
        _updateAgentActivity(_subjectAgent);
        emit SkillAttestationIssued(attestationId, msg.sender, _subjectAgent, _skillId, _score);
    }

    /**
     * @dev The creator of a task issues an attestation for the assigned agent's performance on that task.
     *      Similar to skill attestations, it requires a score and stake.
     * @param _subjectAgent The address of the agent whose performance is being attested.
     * @param _taskId The ID of the task for which performance is being attested.
     * @param _score The performance score (1-100).
     * @param _contextCID An IPFS CID for detailed context or proof.
     * @param _attesterStakeAmount The amount of tokens the attester stakes.
     */
    function issuePerformanceAttestation(address _subjectAgent, bytes32 _taskId, uint8 _score, string calldata _contextCID, uint256 _attesterStakeAmount) external onlyRegisteredAgent {
        require(agents[_subjectAgent].status == AgentStatus.Active, "CognitoNexus: Subject agent not active.");
        require(tasks[_taskId].creator == msg.sender, "CognitoNexus: Only task creator can issue performance attestation.");
        require(tasks[_taskId].assignedAgent == _subjectAgent, "CognitoNexus: Subject agent was not assigned this task.");
        require(tasks[_taskId].status == TaskStatus.Completed || tasks[_taskId].status == TaskStatus.Resolved, "CognitoNexus: Task must be completed to issue performance attestation.");
        require(_score >= MIN_ATTESTATION_SCORE && _score <= MAX_ATTESTATION_SCORE, "CognitoNexus: Score out of range (1-100).");
        require(_attesterStakeAmount > 0, "CognitoNexus: Attester stake must be positive.");

        require(cognitoToken.transferFrom(msg.sender, address(this), _attesterStakeAmount), "CognitoNexus: Token transfer for attester stake failed.");

        bytes32 attestationId = keccak256(abi.encodePacked(msg.sender, _subjectAgent, _taskId, block.timestamp));
        attestations[attestationId] = AttestationInfo({
            attester: msg.sender,
            subject: _subjectAgent,
            skillOrTaskId: _taskId,
            score: _score,
            contextCID: _contextCID,
            timestamp: block.timestamp,
            status: AttestationStatus.Valid,
            attesterStake: _attesterStakeAmount,
            challengerStake: 0,
            challenger: address(0),
            isPerformanceAttestation: true
        });

        agentAttestationsIssued[msg.sender].push(attestationId);
        agentAttestationsReceived[_subjectAgent].push(attestationId);
        _updateReputationBasedOnAttestation(_subjectAgent, _score, false); // Update subject's reputation
        _updateAgentActivity(msg.sender);
        _updateAgentActivity(_subjectAgent);
        emit PerformanceAttestationIssued(attestationId, msg.sender, _subjectAgent, _taskId, _score);
    }

    /**
     * @dev A view function to retrieve the full details of a specific attestation.
     * @param _attestationId The unique ID of the attestation.
     * @return An AttestationInfo struct containing all attestation details.
     */
    function getAttestationDetails(bytes32 _attestationId) external view returns (AttestationInfo memory) {
        return attestations[_attestationId];
    }

    /**
     * @dev Initiates a challenge against an attestation. The challenger stakes tokens,
     *      and the attestation enters a 'Challenged' state.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reasonCID An IPFS CID pointing to the reason and proof for the challenge.
     * @param _challengerStakeAmount The amount of tokens the challenger stakes.
     */
    function challengeAttestation(bytes32 _attestationId, string calldata _reasonCID, uint256 _challengerStakeAmount) external onlyRegisteredAgent {
        AttestationInfo storage att = attestations[_attestationId];
        require(att.status == AttestationStatus.Valid, "CognitoNexus: Attestation is not valid or already challenged.");
        require(att.attester != msg.sender, "CognitoNexus: Cannot challenge your own attestation.");
        require(_challengerStakeAmount > 0, "CognitoNexus: Challenger stake must be positive.");
        require(block.timestamp <= att.timestamp.add(ATTESTATION_CHALLENGE_PERIOD), "CognitoNexus: Challenge period has ended.");

        require(cognitoToken.transferFrom(msg.sender, address(this), _challengerStakeAmount), "CognitoNexus: Token transfer for challenger stake failed.");

        att.status = AttestationStatus.Challenged;
        att.challenger = msg.sender;
        att.challengerStake = _challengerStakeAmount;
        _updateAgentActivity(msg.sender);
        emit AttestationChallenged(_attestationId, msg.sender, _reasonCID);
    }

    /**
     * @dev (Admin function) Resolves an attestation challenge.
     *      If `_isValid` is true, the attester wins and their stake is returned, challenger loses stake.
     *      If `_isValid` is false, the challenger wins and their stake is returned, attester loses stake.
     * @param _attestationId The ID of the challenged attestation.
     * @param _isValid True if the attestation is deemed valid, false otherwise.
     */
    function resolveAttestationChallenge(bytes32 _attestationId, bool _isValid) external onlyOwner {
        AttestationInfo storage att = attestations[_attestationId];
        require(att.status == AttestationStatus.Challenged, "CognitoNexus: Attestation is not challenged.");
        require(att.challenger != address(0), "CognitoNexus: Attestation has no challenger.");

        uint256 attesterStakeReleased = 0;
        uint256 challengerStakeReleased = 0;

        if (_isValid) {
            // Attestation is valid: attester wins, challenger loses stake.
            attesterStakeReleased = att.attesterStake;
            require(cognitoToken.transfer(att.attester, attesterStakeReleased), "CognitoNexus: Failed to release attester stake.");
            // Challenger stake remains in contract (effectively slashed/burned for misbehavior).
            _punishReputationDirectly(att.challenger, -int256(att.challengerStake.div(100)), "Lost attestation challenge"); // Small rep penalty
            att.status = AttestationStatus.Valid; // Remains valid
        } else {
            // Attestation is invalid: challenger wins, attester loses stake.
            att.status = AttestationStatus.Revoked;
            challengerStakeReleased = att.challengerStake;
            require(cognitoToken.transfer(att.challenger, challengerStakeReleased), "CognitoNexus: Failed to release challenger stake.");
            // Attester stake remains in contract (slashed).
            _punishReputationDirectly(att.attester, -int256(att.attesterStake.div(100)), "Failed attestation challenge"); // Small rep penalty
            // If attestation was revoked, its prior positive impact on subject's reputation might need to be reversed.
            // This is handled implicitly by recalculation if `isValid` is false, and explicit reversal isn't directly needed.
        }

        att.attesterStake = 0; // Stakes handled
        att.challengerStake = 0; // Stakes handled
        _updateAgentActivity(att.attester);
        _updateAgentActivity(att.challenger);
        emit AttestationChallengeResolved(_attestationId, _isValid, attesterStakeReleased, challengerStakeReleased);
    }

    // --- IV. Reputation System ---

    /**
     * @dev Retrieves the current multi-dimensional reputation score of an agent.
     *      This function calculates the score dynamically, considering decay and active boosts.
     * @param _agentAddress The address of the agent.
     * @return The agent's trust, competence, and reliability scores.
     */
    function getAgentReputation(address _agentAddress) public view returns (int256 trust, int256 competence, int256 reliability) {
        return calculateCurrentReputation(_agentAddress);
    }

    /**
     * @dev Allows an agent to stake tokens to temporarily boost their perceived reputation.
     *      Staked tokens contribute a positive multiplier to their reputation scores.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForReputationBoost(uint256 _amount) external onlyRegisteredAgent {
        require(_amount > 0, "CognitoNexus: Stake amount must be positive.");
        require(cognitoToken.transferFrom(msg.sender, address(this), _amount), "CognitoNexus: Token transfer for stake failed.");
        agents[msg.sender].stakedTokens = agents[msg.sender].stakedTokens.add(_amount);
        _updateAgentActivity(msg.sender);
        emit ReputationBoostStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows an agent to unstake tokens previously committed for a reputation boost.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeFromReputationBoost(uint256 _amount) external onlyRegisteredAgent {
        require(_amount > 0, "CognitoNexus: Unstake amount must be positive.");
        require(agents[msg.sender].stakedTokens >= _amount, "CognitoNexus: Insufficient staked tokens.");
        agents[msg.sender].stakedTokens = agents[msg.sender].stakedTokens.sub(_amount);
        require(cognitoToken.transfer(msg.sender, _amount), "CognitoNexus: Token transfer for unstake failed.");
        _updateAgentActivity(msg.sender);
        emit ReputationBoostUnstaked(msg.sender, _amount);
    }

    // --- V. Task & Project Market ---

    /**
     * @dev Creates a new task. The task creator must deposit the bounty amount
     *      plus a small protocol fee. Bounty is held in escrow.
     * @param _title The title of the task.
     * @param _descriptionCID The IPFS CID for the task's detailed description.
     * @param _requiredSkills An array of skill IDs required for the task.
     * @param _bountyAmount The bounty amount in tokens for task completion.
     * @param _deadline The timestamp by which the task should ideally be completed.
     */
    function createTask(string calldata _title, string calldata _descriptionCID, bytes32[] calldata _requiredSkills, uint256 _bountyAmount, uint256 _deadline) external onlyRegisteredAgent {
        require(_bountyAmount > 0, "CognitoNexus: Bounty must be positive.");
        require(_deadline > block.timestamp, "CognitoNexus: Deadline must be in the future.");
        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            require(skills[_requiredSkills[i]].isApproved, "CognitoNexus: Required skill not approved.");
        }

        uint256 totalPayment = _bountyAmount.add(_bountyAmount.mul(TASK_BOUNTY_PROTOCOL_FEE_PERCENT).div(100)); // Bounty + fee
        require(cognitoToken.transferFrom(msg.sender, address(this), totalPayment), "CognitoNexus: Token transfer for bounty failed.");

        bytes32 taskId = keccak256(abi.encodePacked(msg.sender, _title, block.timestamp));
        tasks[taskId] = TaskInfo({
            creator: msg.sender,
            title: _title,
            descriptionCID: _descriptionCID,
            requiredSkills: _requiredSkills,
            bountyAmount: _bountyAmount,
            deadline: _deadline,
            assignedAgent: address(0),
            status: TaskStatus.Open,
            proofCID: "",
            escrowBalance: _bountyAmount // Protocol fee is kept, bounty stored in escrow
        });
        agentTasksCreated[msg.sender].push(taskId);
        _updateAgentActivity(msg.sender);
        emit TaskCreated(taskId, msg.sender, _bountyAmount, _deadline);
    }

    /**
     * @dev An agent indicates interest in performing a task.
     *      This is a simple signal of interest, actual assignment is done by the creator.
     * @param _taskId The ID of the task the agent is bidding on.
     */
    function bidOnTask(bytes32 _taskId) external onlyRegisteredAgent {
        TaskInfo storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "CognitoNexus: Task is not open for bidding.");
        require(task.deadline > block.timestamp, "CognitoNexus: Task bidding deadline passed.");

        // Basic check: Agent needs a minimum competence score to bid
        (int256 trust, int256 competence, int256 reliability) = calculateCurrentReputation(msg.sender);
        require(competence >= INITIAL_REPUTATION_SCORE.div(2), "CognitoNexus: Agent's competence is too low to bid."); // Example threshold

        // Also check if agent has declared all required skills
        bool hasAllSkills = true;
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            if (!agents[msg.sender].declaredSkills[task.requiredSkills[i]]) {
                hasAllSkills = false;
                break;
            }
        }
        require(hasAllSkills, "CognitoNexus: Agent does not declare all required skills.");
        _updateAgentActivity(msg.sender);
        emit TaskBid(_taskId, msg.sender);
    }

    /**
     * @dev The task creator assigns an open task to a specific agent.
     *      Requires the assigned agent to be active and meet skill/reputation criteria.
     * @param _taskId The ID of the task to assign.
     * @param _agentAddress The address of the agent to assign the task to.
     */
    function assignTask(bytes32 _taskId, address _agentAddress) external onlyRegisteredAgent {
        TaskInfo storage task = tasks[_taskId];
        require(task.creator == msg.sender, "CognitoNexus: Only task creator can assign.");
        require(task.status == TaskStatus.Open, "CognitoNexus: Task is not open for assignment.");
        require(agents[_agentAddress].status == AgentStatus.Active, "CognitoNexus: Agent is not active.");
        require(task.deadline > block.timestamp, "CognitoNexus: Task deadline passed for assignment.");
        require(task.assignedAgent == address(0), "CognitoNexus: Task already assigned.");

        // Additional checks: ensure _agentAddress has declared skills and sufficient reputation
        (int256 trust, int256 competence, int256 reliability) = calculateCurrentReputation(_agentAddress);
        require(competence >= INITIAL_REPUTATION_SCORE.div(2), "CognitoNexus: Agent's competence is too low to be assigned."); // Example threshold

        bool hasAllSkills = true;
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            if (!agents[_agentAddress].declaredSkills[task.requiredSkills[i]]) {
                hasAllSkills = false;
                break;
            }
        }
        require(hasAllSkills, "CognitoNexus: Assigned agent does not declare all required skills.");

        task.assignedAgent = _agentAddress;
        task.status = TaskStatus.Assigned;
        agentTasksAssigned[_agentAddress].push(_taskId);
        _updateAgentActivity(msg.sender); // Creator activity
        _updateAgentActivity(_agentAddress); // Assigned agent activity
        emit TaskAssigned(_taskId, _agentAddress);
    }

    /**
     * @dev The assigned agent marks a task as complete and provides a proof CID.
     *      This moves the task into a 'Completed' state, awaiting creator review or dispute.
     * @param _taskId The ID of the task to complete.
     * @param _proofCID An IPFS CID pointing to the proof of task completion.
     */
    function completeTask(bytes32 _taskId, string calldata _proofCID) external onlyRegisteredAgent {
        TaskInfo storage task = tasks[_taskId];
        require(task.assignedAgent == msg.sender, "CognitoNexus: Only assigned agent can complete task.");
        require(task.status == TaskStatus.Assigned, "CognitoNexus: Task is not assigned or already completed.");

        task.status = TaskStatus.Completed;
        task.proofCID = _proofCID;
        _updateAgentActivity(msg.sender);
        // Note: Bounty payment is handled upon dispute resolution or implicit approval (off-chain).
        emit TaskCompleted(_taskId, msg.sender, _proofCID);
    }

    /**
     * @dev Allows either the task creator or the assigned agent to request a dispute resolution
     *      for a completed task. This moves the task into a 'Disputed' state.
     * @param _taskId The ID of the task to dispute.
     * @param _reasonCID An IPFS CID pointing to the reason for the dispute.
     */
    function requestTaskDisputeResolution(bytes32 _taskId, string calldata _reasonCID) external onlyRegisteredAgent {
        TaskInfo storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "CognitoNexus: Task is not completed to dispute.");
        require(task.creator == msg.sender || task.assignedAgent == msg.sender, "CognitoNexus: Only creator or assigned agent can dispute.");
        // A dispute period could be enforced here, e.g., require(block.timestamp <= task.deadline.add(TASK_DISPUTE_PERIOD));

        task.status = TaskStatus.Disputed;
        _updateAgentActivity(msg.sender);
        emit TaskDisputeRequested(_taskId, msg.sender, _reasonCID);
    }

    /**
     * @dev (Admin function) Resolves a task dispute. Determines if the assigned agent
     *      succeeded or failed, and distributes the bounty accordingly, impacting reputation.
     * @param _taskId The ID of the disputed task.
     * @param _agentSucceeded True if the assigned agent is deemed to have successfully completed the task.
     */
    function resolveTaskDispute(bytes32 _taskId, bool _agentSucceeded) external onlyOwner {
        TaskInfo storage task = tasks[_taskId];
        require(task.status == TaskStatus.Disputed, "CognitoNexus: Task is not in dispute.");
        require(task.assignedAgent != address(0), "CognitoNexus: Task has no assigned agent.");

        task.status = TaskStatus.Resolved;

        if (_agentSucceeded) {
            // Agent succeeded, release bounty to agent
            require(cognitoToken.transfer(task.assignedAgent, task.bountyAmount), "CognitoNexus: Failed to pay bounty.");
            // Positive reputation adjustment for agent
            _punishReputationDirectly(task.assignedAgent, 500, "Successful task resolution"); // Example positive adjustment
        } else {
            // Agent failed, bounty returned to creator
            require(cognitoToken.transfer(task.creator, task.bountyAmount), "CognitoNexus: Failed to return bounty to creator.");
            // Negative reputation adjustment for agent
            _punishReputationDirectly(task.assignedAgent, -500, "Failed task resolution"); // Example negative adjustment
        }
        _updateAgentActivity(task.assignedAgent);
        _updateAgentActivity(task.creator);
        emit TaskDisputeResolved(_taskId, task.assignedAgent, _agentSucceeded);
    }

    // --- VI. Advanced Concepts ---

    /**
     * @dev Allows a high-reputation agent (lender) to temporarily "lend" a reputation boost
     *      to another agent (borrower). The lender stakes collateral, which can be claimed
     *      if the borrower fails to repay.
     * @param _borrower The address of the agent who will receive the reputation boost.
     * @param _loanReputationAmount The amount of reputation points to temporarily add to the borrower.
     * @param _collateralAmount The amount of tokens the lender stakes as collateral for the loan.
     * @param _durationSeconds The duration in seconds for which the reputation loan is active.
     */
    function grantReputationLoan(address _borrower, uint256 _loanReputationAmount, uint256 _collateralAmount, uint256 _durationSeconds) external onlyRegisteredAgent {
        require(_borrower != msg.sender, "CognitoNexus: Cannot grant loan to self.");
        require(agents[_borrower].status == AgentStatus.Active, "CognitoNexus: Borrower agent not active.");
        require(_loanReputationAmount > 0, "CognitoNexus: Loan reputation amount must be positive.");
        require(_collateralAmount > 0, "CognitoNexus: Collateral amount must be positive.");
        require(_durationSeconds > 0, "CognitoNexus: Loan duration must be positive.");

        // Lender stakes collateral
        require(cognitoToken.transferFrom(msg.sender, address(this), _collateralAmount), "CognitoNexus: Token transfer for collateral failed.");

        bytes32 loanId = keccak256(abi.encodePacked(msg.sender, _borrower, block.timestamp));
        reputationLoans[loanId] = ReputationLoanInfo({
            borrower: _borrower,
            lender: msg.sender,
            loanReputationAmount: _loanReputationAmount,
            collateralAmount: _collateralAmount,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp.add(_durationSeconds),
            repaid: false,
            claimedByLender: false
        });

        agentReputationLoansLent[msg.sender].push(loanId);
        agentReputationLoansBorrowed[_borrower].push(loanId);
        _updateAgentActivity(msg.sender); // Lender activity
        _updateAgentActivity(_borrower); // Borrower activity
        emit ReputationLoanGranted(loanId, _borrower, msg.sender, _loanReputationAmount, _collateralAmount, block.timestamp.add(_durationSeconds));
    }

    /**
     * @dev The borrower repays a reputation loan. This releases the lender's collateral.
     *      A small protocol fee is applied during repayment.
     * @param _loanId The ID of the reputation loan to repay.
     */
    function repayReputationLoan(bytes32 _loanId) external onlyRegisteredAgent {
        ReputationLoanInfo storage loan = reputationLoans[_loanId];
        require(loan.borrower == msg.sender, "CognitoNexus: Only borrower can repay loan.");
        require(!loan.repaid, "CognitoNexus: Loan already repaid.");
        require(!loan.claimedByLender, "CognitoNexus: Loan collateral already claimed by lender.");

        // Borrower repays collateral amount + a small fee for the protocol
        uint256 repaymentAmount = loan.collateralAmount.add(loan.collateralAmount.mul(REPAYMENT_PROTOCOL_FEE_BPS).div(10000)); // 0.1% fee (10bps)
        require(cognitoToken.transferFrom(msg.sender, address(this), repaymentAmount), "CognitoNexus: Token transfer for repayment failed.");

        require(cognitoToken.transfer(loan.lender, loan.collateralAmount), "CognitoNexus: Failed to transfer collateral to lender.");
        // Protocol keeps the fee: (repaymentAmount - loan.collateralAmount)

        loan.repaid = true;
        _updateAgentActivity(msg.sender); // Borrower activity
        _updateAgentActivity(loan.lender); // Lender activity
        emit ReputationLoanRepaid(_loanId, loan.borrower, loan.lender);
    }

    /**
     * @dev Allows a lender to claim their collateral if the borrower fails to repay a reputation
     *      loan by its expiration deadline.
     * @param _loanId The ID of the loan for which to claim collateral.
     */
    function claimExpiredLoanCollateral(bytes32 _loanId) external onlyRegisteredAgent {
        ReputationLoanInfo storage loan = reputationLoans[_loanId];
        require(loan.lender == msg.sender, "CognitoNexus: Only lender can claim collateral.");
        require(block.timestamp > loan.expirationTimestamp, "CognitoNexus: Loan has not expired yet.");
        require(!loan.repaid, "CognitoNexus: Loan has been repaid.");
        require(!loan.claimedByLender, "CognitoNexus: Collateral already claimed.");

        require(cognitoToken.transfer(loan.lender, loan.collateralAmount), "CognitoNexus: Failed to transfer collateral to lender.");
        loan.claimedByLender = true;
        _updateAgentActivity(msg.sender);
        emit ReputationLoanCollateralClaimed(_loanId, loan.lender, loan.collateralAmount);
    }

    /**
     * @dev (Admin function) Directly decreases an agent's reputation scores as a penalty for misconduct.
     *      Used after serious violations determined off-chain or via a separate governance process.
     * @param _agentAddress The address of the agent to punish.
     * @param _penaltyAmount The amount by which to reduce reputation scores. Can be negative for positive adjustments.
     * @param _reasonCID An IPFS CID pointing to the reason for the punishment.
     */
    function punishAgent(address _agentAddress, int256 _penaltyAmount, string calldata _reasonCID) external onlyOwner {
        require(agents[_agentAddress].status == AgentStatus.Active, "CognitoNexus: Agent not active.");
        _punishReputationDirectly(_agentAddress, _penaltyAmount, _reasonCID);
        emit AgentPunished(_agentAddress, _penaltyAmount, _reasonCID);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to update an agent's reputation scores based on an attestation.
     *      High scores (above 50) have a positive impact, low scores (below 50) have a negative.
     * @param _agentAddress The address of the agent whose reputation is being updated.
     * @param _attestationScore The score (1-100) from the attestation.
     * @param _isSkillAttestation True if it's a skill attestation, false for performance.
     */
    function _updateReputationBasedOnAttestation(address _agentAddress, uint8 _attestationScore, bool _isSkillAttestation) internal {
        ReputationScore storage rep = _reputationScores[_agentAddress];
        rep.lastUpdatedTimestamp = block.timestamp;

        // Scale attestation score from 1-100 to a reputation impact value (e.g., 50 is neutral).
        // Each point deviation from 50 (e.g., 60 is +10, 40 is -10) multiplied by 100 for scaled points.
        int256 impact = int256(_attestationScore).sub(50).mul(100);

        if (_isSkillAttestation) {
            rep.competenceScore += impact;
        } else { // Performance attestation
            rep.reliabilityScore += impact;
            rep.trustScore += impact.div(2); // Performance also partially impacts trust
        }
        // Scores are floored at 0 in the `calculateCurrentReputation` function after all dynamic calculations.
        emit ReputationUpdated(_agentAddress, rep.trustScore, rep.competenceScore, rep.reliabilityScore);
    }

    /**
     * @dev Internal function to directly adjust an agent's reputation scores.
     *      Used for administrative penalties or positive adjustments from dispute resolution.
     * @param _agentAddress The address of the agent to adjust.
     * @param _adjustmentAmount The amount to add to/subtract from the scores (can be negative).
     * @param _reasonCID An IPFS CID for the reason of the adjustment.
     */
    function _punishReputationDirectly(address _agentAddress, int256 _adjustmentAmount, string calldata _reasonCID) internal {
        ReputationScore storage rep = _reputationScores[_agentAddress];
        rep.trustScore += _adjustmentAmount;
        rep.competenceScore += _adjustmentAmount;
        rep.reliabilityScore += _adjustmentAmount;
        rep.lastUpdatedTimestamp = block.timestamp;
        // Scores are floored at 0 in the `calculateCurrentReputation` function after all dynamic calculations.
        emit ReputationUpdated(_agentAddress, rep.trustScore, rep.competenceScore, rep.reliabilityScore);
    }

    /**
     * @dev Internal (and public view) function that computes the dynamic reputation score for an agent.
     *      It applies decay based on inactivity, boosts from staked tokens, and temporary boosts from active reputation loans.
     * @param _agentAddress The address of the agent.
     * @return The agent's calculated trust, competence, and reliability scores.
     */
    function calculateCurrentReputation(address _agentAddress) public view returns (int256 trust, int256 competence, int256 reliability) {
        ReputationScore storage storedRep = _reputationScores[_agentAddress];
        uint256 lastUpdate = storedRep.lastUpdatedTimestamp;
        uint256 timePassed = block.timestamp.sub(lastUpdate);
        uint256 daysPassed = timePassed.div(1 days);

        int256 currentTrust = storedRep.trustScore;
        int256 currentCompetence = storedRep.competenceScore;
        int256 currentReliability = storedRep.reliabilityScore;

        // Apply decay for inactivity
        if (daysPassed > 0) {
            uint256 decayFactor = daysPassed.mul(REPUTATION_DECAY_RATE_PER_DAY);
            // Decay amount = score * decayFactor / 10000 (where 10000 means 100% for scaled scores)
            currentTrust -= currentTrust.mul(int256(decayFactor)).div(10000);
            currentCompetence -= currentCompetence.mul(int256(decayFactor)).div(10000);
            currentReliability -= currentReliability.mul(int256(decayFactor)).div(10000);
        }

        // Apply staked tokens boost
        uint256 stakedBoost = agents[_agentAddress].stakedTokens.div(STAKE_REPUTATION_FACTOR);
        currentTrust += int256(stakedBoost);
        currentCompetence += int256(stakedBoost);
        currentReliability += int256(stakedBoost);

        // Apply active reputation loans boost
        // Note: Iterating over an array in a view function is acceptable for reasonable array sizes.
        for (uint256 i = 0; i < agentReputationLoansBorrowed[_agentAddress].length; i++) {
            bytes32 loanId = agentReputationLoansBorrowed[_agentAddress][i];
            ReputationLoanInfo storage loan = reputationLoans[loanId];
            if (!loan.repaid && !loan.claimedByLender && block.timestamp <= loan.expirationTimestamp) {
                uint256 totalDuration = loan.expirationTimestamp.sub(loan.creationTimestamp);
                if (totalDuration > 0) {
                    uint256 remainingDuration = loan.expirationTimestamp.sub(block.timestamp);
                    // Linear decay of loan boost over time
                    int256 effectiveLoanBoost = int256(loan.loanReputationAmount.mul(remainingDuration).div(totalDuration));
                    currentTrust += effectiveLoanBoost;
                    currentCompetence += effectiveLoanBoost;
                    currentReliability += effectiveLoanBoost;
                } else {
                    // If duration is 0, apply full boost
                    currentTrust += int256(loan.loanReputationAmount);
                    currentCompetence += int256(loan.loanReputationAmount);
                    currentReliability += int256(loan.loanReputationAmount);
                }
            }
        }

        // Ensure minimum scores after all calculations (cannot go below 0)
        if (currentTrust < 0) currentTrust = 0;
        if (currentCompetence < 0) currentCompetence = 0;
        if (currentReliability < 0) currentReliability = 0;

        return (currentTrust, currentCompetence, currentReliability);
    }

    /**
     * @dev Helper to update an agent's last activity timestamp, indicating an active participant.
     * @param _agentAddress The address of the agent.
     */
    function _updateAgentActivity(address _agentAddress) internal {
        agents[_agentAddress].lastActivityTimestamp = block.timestamp;
    }
}
```