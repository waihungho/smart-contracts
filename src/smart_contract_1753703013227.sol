This smart contract, **CognitoChain**, introduces a novel decentralized protocol for dynamic skill attestation, AI-assisted task matching, and reputation-based reward distribution. It integrates several advanced and creative concepts that go beyond typical open-source implementations.

The core idea revolves around:
1.  **AI-Assisted Assessment:** Interacting with off-chain AI oracles (simulated here) to assess agent skills and task quality.
2.  **Dynamic Reputation:** A constantly evolving reputation score for agents based on their skill attestations, task performance, and dispute outcomes.
3.  **Commit-Reveal Scheme:** Enhancing privacy and preventing front-running for skill attestations and task submissions.
4.  **Soulbound SkillGraph NFTs:** Non-transferable NFTs that dynamically update to reflect an agent's evolving skills and reputation, serving as a decentralized identity.
5.  **Decentralized Jury System:** For resolving disputes related to skill assessments or task quality.
6.  **Adaptive Rewards:** Task bounties are adjusted based on AI-assessed task quality.
7.  **On-chain Skill Schema:** A flexible way to define and manage various skills within the network.
8.  **Basic Governance:** Allowing for future parameter adjustments and protocol evolution.

---

## Contract Outline and Function Summary

**Contract Name:** `CognitoChain`

**I. Core Infrastructure & Access Control**
*   `constructor(address _skillGraphNFTAddress)`: Initializes the contract, sets the owner, and the address of the SkillGraph NFT contract.
*   `pauseContract()`: Emergency mechanism to pause all core contract functionalities.
*   `unpauseContract()`: Unpauses the contract.
*   `withdrawFunds(address _token, uint256 _amount)`: Allows the owner to withdraw accumulated funds (e.g., dispute fees).

**II. AI Oracle Integration**
*   `updateSkillAssessmentAIOracle(address _newAddress)`: Sets or updates the address of the AI oracle responsible for skill proficiency assessment.
*   `updateTaskQualityAIOracle(address _newAddress)`: Sets or updates the address of the AI oracle responsible for task submission quality assessment.

**III. Skill Schema & Attestation**
*   `defineSkillSchema(string calldata _name, string calldata _schemaURI)`: Defines a new skill type with a detailed schema URI (e.g., "Solidity Dev: ERC20, DeFi, Security").
*   `updateSkillSchema(bytes32 _skillId, string calldata _newSchemaURI)`: Modifies the schema URI for an existing skill.
*   `commitSkillAttestation(bytes32 _commitmentHash, bytes32 _skillId)`: Initiates a skill attestation by committing a hashed proof (first step of commit-reveal).
*   `revealSkillAttestation(string calldata _proofDataURI, bytes32 _salt)`: Reveals the skill proof data, triggering AI oracle assessment, and verifies against the prior commitment.
*   `processSkillAssessmentResult(address _agent, bytes32 _skillId, uint256 _skillLevel)`: Callback function (intended for AI oracle) to update an agent's skill level and reputation based on assessment.
*   `requestSkillReassessment(bytes32 _skillId)`: Allows an agent to request a re-assessment of their skill (requires new commit-reveal).

**IV. Agent Reputation & SkillGraph NFT**
*   `mintSkillGraphNFT()`: Mints a unique, soulbound (non-transferable) ERC-721 NFT for the agent, dynamically representing their skill profile and reputation.
*   `_generateSkillGraphURI(address _agent)`: Internal helper to construct the dynamic metadata URI for the SkillGraph NFT.

**V. Task & Project Management**
*   `createTask(bytes32 _requiredSkillId, uint256 _minSkillLevel, uint256 _bountyAmount, address _bountyToken, uint256 _applicationDeadline, uint256 _submissionDeadline)`: Creates a new task with specified skill requirements, bounty, and deadlines.
*   `applyForTask(bytes32 _taskId)`: Allows an agent to apply for an open task, checked against their skill level and reputation.
*   `assignTask(bytes32 _taskId, address _agent)`: Task creator assigns an agent to a task.
*   `submitTaskCompletionCommitment(bytes32 _taskId, bytes32 _commitmentHash)`: Agent commits a hash of their task completion proof.
*   `revealTaskCompletion(bytes32 _taskId, string calldata _submissionURI, bytes32 _salt)`: Agent reveals task completion proof, triggering AI oracle quality assessment.
*   `processTaskQualityAssessment(bytes32 _taskId, address _agent, uint256 _qualityScore)`: Callback function (intended for AI oracle) to update task status and agent reputation based on quality score.
*   `releaseTaskReward(bytes32 _taskId)`: Releases the task bounty to the assigned agent, adjusted by the AI-assessed quality score.

**VI. Dispute Resolution System**
*   `setJuryPoolManager(address _newManager)`: Sets the address responsible for managing eligible jury members.
*   `addJuryMember(address _member)`: Adds an address to the pool of eligible dispute jury members.
*   `removeJuryMember(address _member)`: Removes an address from the jury pool.
*   `initiateDispute(bytes32 _contextId, DisputeType _disputeType, address _feeToken)`: Initiates a dispute over a skill assessment or task quality, selects a random jury panel.
*   `submitJuryVerdict(bytes32 _disputeId, Verdict _verdict)`: A selected jury member submits their vote on a dispute.
*   `resolveDispute(bytes32 _disputeId)`: Resolves a dispute based on jury votes, adjusting reputation and outcomes as necessary.

**VII. Governance & Parameter Management**
*   `proposeParameterChange(string calldata _description, address _targetContract, bytes calldata _callData)`: Allows proposing changes to contract parameters or logic, encoded as a function call.
*   `voteOnProposal(bytes32 _proposalId, bool _support)`: Agents (or specified voters) cast their vote on a proposal.
*   `executeProposal(bytes32 _proposalId)`: Executes a proposal that has passed its voting period and received sufficient 'for' votes.

**VIII. Helper View Functions**
*   `getAgentReputation(address _agent)`: Retrieves an agent's current reputation score.
*   `getAgentSkillLevel(address _agent, bytes32 _skillId)`: Retrieves an agent's assessed level for a specific skill.
*   `getTaskStatus(bytes32 _taskId)`: Returns the current status of a task.
*   `getTotalSkills()`: Returns the total number of defined skill schemas.
*   `getTotalOpenTasks()`: Returns the total number of open tasks.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For SkillGraph NFT interaction
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For NFT metadata updates

/**
 * @title ISkillGraphNFT
 * @dev Interface for the companion Soulbound NFT contract,
 *      which represents an agent's dynamic skill profile and reputation.
 *      It is expected to be a non-transferable (soulbound) ERC-721 token.
 */
interface ISkillGraphNFT is IERC721, IERC721Metadata {
    /**
     * @dev Mints a new SkillGraph NFT for an agent.
     * @param _to The address of the agent to mint for.
     * @param _tokenId The unique token ID for the NFT.
     * @param _tokenURI The initial metadata URI for the NFT.
     * @return True if minting was successful.
     */
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external returns (bool);

    /**
     * @dev Updates the metadata URI for an existing SkillGraph NFT.
     * @param _tokenId The ID of the token to update.
     * @param _newTokenURI The new metadata URI.
     * @return True if the update was successful.
     */
    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI) external returns (bool);

    /**
     * @dev Checks if a specific token is configured as soulbound (non-transferable).
     *      (This method might be implemented within the actual NFT contract)
     * @param tokenId The ID of the token to check.
     * @return True if the token is soulbound, false otherwise.
     */
    function isSoulbound(uint256 tokenId) external view returns (bool);
}


/**
 * @title CognitoChain: A Decentralized Skill & Reputation Network
 * @dev This contract facilitates a dynamic skill assessment, AI-assisted task matching,
 *      reputation-based reward distribution, and decentralized dispute resolution.
 *      It leverages oracle-based AI feedback loops and commit-reveal schemes for privacy.
 *      Users possess dynamic, soulbound NFTs representing their evolving skill profiles.
 *
 * Outline:
 * 1.  Core Infrastructure & Access Control: Manages contract state, pausing, and ownership.
 * 2.  AI Oracle Integration: Defines interfaces for interaction with off-chain AI assessment services.
 * 3.  Skill Schema & Attestation: Allows defining skills and users proving their proficiency via commit-reveal.
 * 4.  Agent Reputation & SkillGraph NFT: Dynamically calculates reputation and manages soulbound NFT identities.
 * 5.  Task & Project Management: Enables creating, applying for, assigning, and completing tasks with AI-driven quality assessment.
 * 6.  Dispute Resolution System: Provides a mechanism for jury-based resolution of disagreements.
 * 7.  Governance & Parameter Management: Allows for protocol evolution via proposals and voting.
 */
contract CognitoChain is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Events ---
    event AIOracleUpdated(address indexed oracleType, address newAddress);
    event SkillSchemaDefined(bytes32 indexed skillId, string name, string schemaURI);
    event SkillSchemaUpdated(bytes32 indexed skillId, string newSchemaURI);
    event SkillAttestationCommitted(address indexed agent, bytes32 indexed commitmentHash);
    event SkillAttestationRevealed(address indexed agent, bytes32 indexed skillId, string proofDataURI);
    event SkillAssessmentReceived(address indexed agent, bytes32 indexed skillId, uint256 skillLevel);
    event TaskCreated(bytes32 indexed taskId, address indexed creator, bytes32 indexed requiredSkillId, uint256 bountyAmount);
    event TaskApplicationReceived(bytes32 indexed taskId, address indexed agent);
    event TaskAssigned(bytes32 indexed taskId, address indexed agent);
    event TaskSubmissionCommitted(bytes32 indexed taskId, address indexed agent, bytes32 commitmentHash);
    event TaskSubmissionRevealed(bytes32 indexed taskId, address indexed agent, string submissionURI);
    event TaskQualityAssessmentReceived(bytes32 indexed taskId, address indexed agent, uint256 qualityScore);
    event TaskRewardReleased(bytes32 indexed taskId, address indexed agent, uint256 actualAmount);
    event DisputeInitiated(bytes32 indexed disputeId, bytes32 indexed contextId, uint8 disputeType, address initiator);
    event JuryMemberAdded(address indexed member);
    event JuryMemberRemoved(address indexed member);
    event JuryVerdictSubmitted(bytes32 indexed disputeId, address indexed juryMember, uint8 verdict); // 0=Agree, 1=Disagree, 2=Abstain
    event DisputeResolved(bytes32 indexed disputeId, uint8 outcome); // 0=CreatorWins, 1=AgentWins, 2=Neutral
    event SkillGraphNFTMinted(address indexed agent, uint256 indexed tokenId);
    event SkillGraphNFTMetadataUpdated(uint256 indexed tokenId, string newURI);
    event ParameterChangeProposed(bytes32 indexed proposalId, string description);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(bytes32 indexed proposalId);

    // --- State Variables & Mappings ---

    // AI Oracle Addresses
    address public skillAssessmentAIOracle;
    address public taskQualityAIOracle;
    address public juryPoolManager; // Address responsible for managing jury members
    address public skillGraphNFTAddress; // Address of the deployed SkillGraph NFT contract

    // Skill Management
    struct Skill {
        bytes32 id;             // Unique ID for the skill (keccak256 of name + schema)
        string name;            // Human-readable name (e.g., "Solidity Development")
        string schemaURI;       // IPFS/Arweave URI for the detailed skill schema (e.g., required frameworks, difficulty tiers)
        uint256 definitionTime; // Timestamp when skill was defined
    }
    mapping(bytes32 => Skill) public skills; // skillId => Skill
    bytes32[] public allSkillIds; // Array of all skill IDs for enumeration

    // Agent (User) Profiles
    struct AgentProfile {
        uint256 reputationScore;          // Dynamic reputation (0-10000, 100% = 10000)
        mapping(bytes32 => uint256) skillLevels; // skillId => assessed skill level (0-10000)
        uint256 lastReputationUpdate;     // Timestamp of last reputation update
        uint256 skillGraphTokenId;        // Token ID of the agent's SkillGraph NFT (0 if not minted)
    }
    mapping(address => AgentProfile) public agents; // agentAddress => AgentProfile

    // Commit-Reveal for Skill Attestations
    struct AttestationCommitment {
        bytes32 commitmentHash;
        uint256 commitTime;
        bytes32 skillId; // To link the commitment to a specific skill
    }
    mapping(address => AttestationCommitment) public agentSkillCommitments; // agentAddress => commitment details

    // Task Management
    struct Task {
        bytes32 id;                      // Unique ID for the task
        address creator;                 // Address of the task creator
        bytes32 requiredSkillId;         // Skill ID required for this task
        uint256 minSkillLevel;           // Minimum required skill level for the task (0-10000)
        uint256 bountyAmount;            // Total bounty in native token (wei) or specified ERC20
        address bountyToken;             // Address of ERC20 token for bounty, address(0) for native token
        uint256 creationTime;            // Timestamp of task creation
        uint256 applicationDeadline;     // Deadline for applications
        uint256 submissionDeadline;      // Deadline for task submission after assignment
        address assignedAgent;           // Address of the agent assigned to the task (address(0) if unassigned)
        uint8 status;                    // 0: Open, 1: Assigned, 2: Submitted, 3: Completed, 4: Disputed, 5: Cancelled/Processed
        bytes32 submissionCommitment;    // Hash of task submission proof
        string submissionURI;            // URI to the task submission data
        uint256 qualityScore;            // AI-assessed quality score (0-10000)
    }
    mapping(bytes32 => Task) public tasks; // taskId => Task
    bytes32[] public openTaskIds; // Array of open task IDs

    // Dispute Resolution
    enum DisputeType { SkillAssessment, TaskQuality }
    enum Verdict { Agree, Disagree, Abstain }
    enum DisputeOutcome { CreatorWins, AgentWins, Neutral }

    struct Dispute {
        bytes32 id;                       // Unique ID for the dispute
        bytes32 contextId;                // ID of the skillId or taskId being disputed
        DisputeType disputeType;          // Type of dispute
        address initiator;                // Address of the dispute initiator
        uint256 initiationTime;           // Timestamp when dispute was initiated
        address subjectAgent;             // Agent whose skill or task is being disputed
        uint256 feePaid;                  // Fee paid to initiate dispute
        address feeToken;                 // Token used for fee
        address[] juryPanel;              // Addresses of selected jury members for this dispute
        mapping(address => Verdict) juryVotes; // juryMember => verdict
        uint256 totalVotes;               // Number of votes cast
        bool resolved;                    // True if dispute has been resolved
        DisputeOutcome outcome;           // Outcome of the dispute
    }
    mapping(bytes32 => Dispute) public disputes; // disputeId => Dispute
    address[] public juryMembers; // List of eligible jury members
    mapping(address => bool) public isJuryMember; // juryAddress => bool

    // Governance
    struct Proposal {
        bytes32 id;                     // Unique ID for the proposal
        string description;             // Description of the proposal
        uint256 creationTime;           // Timestamp of proposal creation
        uint256 votingDeadline;         // Deadline for voting
        mapping(address => bool) hasVoted; // voter => true
        uint256 votesFor;               // Count of 'for' votes
        uint256 votesAgainst;           // Count of 'against' votes
        bytes callData;                 // The encoded function call to execute if proposal passes
        address targetContract;         // The contract to call (e.g., self for parameter changes)
        bool executed;                  // True if the proposal has been executed
        bool cancelled;                 // True if the proposal was cancelled
    }
    mapping(bytes32 => Proposal) public proposals; // proposalId => Proposal

    // --- Configuration Constants (Can be made adjustable via governance) ---
    uint256 public constant INITIAL_REPUTATION = 5000; // Starting reputation for new agents (50%)
    uint256 public constant REPUTATION_EFFECT_SCALE = 100; // Scale for reputation changes (e.g., qualityScore/100)
    uint256 public constant MIN_REPUTATION_FOR_TASK_APPLICATION = 1000; // 10%
    uint256 public constant JURY_POOL_MIN_REPUTATION = 7000; // 70% min reputation to be a jury member (not enforced in `addJuryMember` for simplicity)
    uint256 public constant JURY_PANEL_SIZE = 5;
    uint256 public constant DISPUTE_RESOLUTION_PERIOD = 3 days;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant DISPUTE_INITIATION_FEE_NATIVE = 0.1 ether; // Example fee for native token
    uint256 public constant REVEAL_PERIOD = 1 days; // Time window to reveal after committing

    // --- Constructor ---
    /**
     * @dev Initializes the contract with the address of the SkillGraph NFT contract.
     * @param _skillGraphNFTAddress The address of the deployed SkillGraph NFT contract.
     */
    constructor(address _skillGraphNFTAddress) Ownable(msg.sender) Pausable(false) {
        require(_skillGraphNFTAddress != address(0), "SkillGraph NFT address cannot be zero");
        skillGraphNFTAddress = _skillGraphNFTAddress;
        juryPoolManager = msg.sender; // Initial jury manager
        // Placeholder AI oracle addresses (should be set after deployment via update functions)
        skillAssessmentAIOracle = address(0);
        taskQualityAIOracle = address(0);
    }

    // --- 1. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses the contract. Callable only by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Callable only by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated funds (e.g., dispute fees).
     * @param _token The address of the token to withdraw (address(0) for native token).
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address _token, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "Insufficient native balance in contract");
            payable(owner()).transfer(_amount);
        } else {
            // Check contract balance before transfer
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient ERC20 balance in contract");
            IERC20(_token).transfer(owner(), _amount);
        }
    }

    // --- 2. AI Oracle Integration ---

    /**
     * @dev Sets or updates the address of the AI oracle for skill assessment.
     *      Only callable by owner or via governance proposal.
     * @param _newAddress The new address for the skill assessment AI oracle.
     */
    function updateSkillAssessmentAIOracle(address _newAddress) public onlyOwnerOrGovernance {
        require(_newAddress != address(0), "AI Oracle address cannot be zero");
        skillAssessmentAIOracle = _newAddress;
        emit AIOracleUpdated(address(0), _newAddress); // Use address(0) to signify skill oracle type
    }

    /**
     * @dev Sets or updates the address of the AI oracle for task quality assessment.
     *      Only callable by owner or via governance proposal.
     * @param _newAddress The new address for the task quality AI oracle.
     */
    function updateTaskQualityAIOracle(address _newAddress) public onlyOwnerOrGovernance {
        require(_newAddress != address(0), "AI Oracle address cannot be zero");
        taskQualityAIOracle = _newAddress;
        emit AIOracleUpdated(address(1), _newAddress); // Use address(1) to signify task oracle type
    }

    /**
     * @dev Modifier for functions executable by owner or via a successful governance proposal.
     *      In a full DAO, this would involve a more complex proposal execution flow where
     *      `msg.sender` might be the DAO's timelock or executor contract. Here, it simply
     *      allows the owner to directly set parameters or simulates a passed governance call.
     */
    modifier onlyOwnerOrGovernance() {
        require(msg.sender == owner(), "Caller must be owner or a successful governance execution");
        _;
    }

    // --- 3. Skill Schema & Attestation ---

    /**
     * @dev Defines a new skill schema. Only callable by owner or via governance.
     * @param _name The human-readable name of the skill (e.g., "Solidity Development").
     * @param _schemaURI IPFS/Arweave URI pointing to the detailed JSON schema for this skill.
     *        This schema defines expected proofs, assessment criteria etc.
     */
    function defineSkillSchema(string calldata _name, string calldata _schemaURI) public onlyOwnerOrGovernance whenNotPaused {
        bytes32 skillId = keccak256(abi.encodePacked(_name, _schemaURI)); // Unique ID for skill definition
        require(skills[skillId].id == bytes32(0), "Skill with this name and schema already exists");

        skills[skillId] = Skill({
            id: skillId,
            name: _name,
            schemaURI: _schemaURI,
            definitionTime: block.timestamp
        });
        allSkillIds.push(skillId);
        emit SkillSchemaDefined(skillId, _name, _schemaURI);
    }

    /**
     * @dev Updates an existing skill schema's URI. Only callable by owner or via governance.
     * @param _skillId The ID of the skill to update.
     * @param _newSchemaURI The new IPFS/Arweave URI for the skill schema.
     */
    function updateSkillSchema(bytes32 _skillId, string calldata _newSchemaURI) public onlyOwnerOrGovernance whenNotPaused {
        require(skills[_skillId].id != bytes32(0), "Skill does not exist");
        skills[_skillId].schemaURI = _newSchemaURI;
        emit SkillSchemaUpdated(_skillId, _newSchemaURI);
    }

    /**
     * @dev Agent commits a hash of their skill proof. This is the first step of a commit-reveal scheme.
     *      Prevents front-running or bias during skill assessment.
     * @param _commitmentHash A hash of the skill proof data and a salt.
     * @param _skillId The ID of the skill being attested.
     */
    function commitSkillAttestation(bytes32 _commitmentHash, bytes32 _skillId) public whenNotPaused {
        require(agentSkillCommitments[msg.sender].commitmentHash == bytes32(0), "Existing commitment pending reveal for this agent");
        require(skills[_skillId].id != bytes32(0), "Skill does not exist");

        agentSkillCommitments[msg.sender] = AttestationCommitment({
            commitmentHash: _commitmentHash,
            commitTime: block.timestamp,
            skillId: _skillId
        });
        emit SkillAttestationCommitted(msg.sender, _commitmentHash);
    }

    /**
     * @dev Agent reveals their skill proof. The hash of the provided data must match the committed hash.
     *      This triggers an AI oracle call for assessment.
     * @param _proofDataURI IPFS/Arweave URI to the detailed skill proof data (e.g., credentials, project links).
     * @param _salt The salt used during the commitment.
     */
    function revealSkillAttestation(string calldata _proofDataURI, bytes32 _salt) public whenNotPaused {
        AttestationCommitment storage commitment = agentSkillCommitments[msg.sender];
        require(commitment.commitmentHash != bytes32(0), "No active commitment found for this agent");
        require(block.timestamp <= commitment.commitTime.add(REVEAL_PERIOD), "Reveal period expired");
        require(keccak256(abi.encodePacked(_proofDataURI, _salt)) == commitment.commitmentHash, "Proof data does not match commitment");
        require(skillAssessmentAIOracle != address(0), "Skill assessment AI oracle not set");

        // Clear commitment after successful reveal
        bytes32 revealedSkillId = commitment.skillId;
        delete agentSkillCommitments[msg.sender];

        emit SkillAttestationRevealed(msg.sender, revealedSkillId, _proofDataURI);

        // In a real dApp, this would trigger an asynchronous call to the oracle contract,
        // which would then call back `processSkillAssessmentResult` after off-chain AI processing.
        // For demonstration purposes, we simulate the callback immediately.
        _simulateSkillAssessmentCallback(msg.sender, revealedSkillId, _proofDataURI);
    }

    /**
     * @dev Private function to simulate an AI oracle callback for skill assessment.
     *      In a production environment, this would be an external function called by a trusted oracle.
     * @param _agent The agent whose skill was assessed.
     * @param _skillId The ID of the skill assessed.
     * @param _proofDataURI The URI that was submitted (for context).
     */
    function _simulateSkillAssessmentCallback(address _agent, bytes32 _skillId, string memory _proofDataURI) private {
        // This function simulates the AI oracle's role.
        // In reality, the oracle would fetch and analyze _proofDataURI off-chain.
        uint256 simulatedScore = _calculateSimulatedSkillScore(_proofDataURI); // Placeholder for complex AI logic
        processSkillAssessmentResult(_agent, _skillId, simulatedScore); // Directly call the processing function
    }

    /**
     * @dev Placeholder function to simulate AI's skill score calculation based on proof data URI.
     *      This would be complex off-chain AI logic, analyzing content pointed by _proofDataURI.
     */
    function _calculateSimulatedSkillScore(string memory _proofDataURI) private pure returns (uint256) {
        // A dummy simulation: score loosely based on length of URI string
        uint256 length = bytes(_proofDataURI).length;
        if (length > 100) return 9500; // Very high score (95%)
        if (length > 50) return 7000;  // Medium score (70%)
        return 4000;                   // Low score (40%)
    }

    /**
     * @dev Callback function to receive skill assessment results from the AI oracle.
     *      Only callable by the `skillAssessmentAIOracle` address.
     * @param _agent The agent whose skill was assessed.
     * @param _skillId The ID of the skill assessed.
     * @param _skillLevel The assessed skill level (0-10000, 100% = 10000).
     */
    function processSkillAssessmentResult(address _agent, bytes32 _skillId, uint256 _skillLevel) public whenNotPaused {
        require(msg.sender == skillAssessmentAIOracle, "Only the skill assessment oracle can call this function");
        require(skills[_skillId].id != bytes32(0), "Skill does not exist");
        require(_skillLevel <= 10000, "Skill level must be between 0 and 10000");

        if (agents[_agent].reputationScore == 0 && agents[_agent].skillGraphTokenId == 0) {
            agents[_agent].reputationScore = INITIAL_REPUTATION; // Initialize new agent's reputation
        }
        agents[_agent].skillLevels[_skillId] = _skillLevel;
        _updateAgentReputation(_agent, _skillLevel, true); // Update reputation based on new skill

        // Trigger NFT metadata update if agent has one
        if (agents[_agent].skillGraphTokenId != 0) {
            ISkillGraphNFT(skillGraphNFTAddress).updateTokenURI(agents[_agent].skillGraphTokenId, _generateSkillGraphURI(_agent));
            emit SkillGraphNFTMetadataUpdated(agents[_agent].skillGraphTokenId, _generateSkillGraphURI(_agent));
        }

        emit SkillAssessmentReceived(_agent, _skillId, _skillLevel);
    }

    /**
     * @dev Allows an agent to request a re-assessment of a skill.
     *      Requires a new commit-reveal cycle. No direct state change, signals intent.
     * @param _skillId The ID of the skill to re-assess.
     */
    function requestSkillReassessment(bytes32 _skillId) public view whenNotPaused {
        require(agents[msg.sender].skillLevels[_skillId] > 0, "Agent has no existing assessment for this skill");
        require(agentSkillCommitments[msg.sender].commitmentHash == bytes32(0), "Existing commitment pending reveal");
        // Agent must now call commitSkillAttestation again with new proof.
    }

    // --- 4. Agent Reputation & SkillGraph NFT ---

    /**
     * @dev Internal function to calculate and update an agent's dynamic reputation score.
     *      Influenced by skill assessments, task performance, and dispute outcomes.
     * @param _agent The agent whose reputation is to be updated.
     * @param _score The score from which reputation adjustment is derived (e.g., skill level, task quality).
     * @param _positive If the adjustment is positive (true) or negative (false).
     */
    function _updateAgentReputation(address _agent, uint256 _score, bool _positive) internal {
        uint256 currentRep = agents[_agent].reputationScore;
        uint256 changeAmount = _score.div(REPUTATION_EFFECT_SCALE); // Simple linear scale for impact

        if (_positive) {
            currentRep = currentRep.add(changeAmount);
        } else {
            // Prevent underflow, cap at 0
            currentRep = currentRep > changeAmount ? currentRep.sub(changeAmount) : 0;
        }

        // Cap reputation between 0 and 10000 (100%)
        agents[_agent].reputationScore = currentRep > 10000 ? 10000 : currentRep;
        agents[_agent].lastReputationUpdate = block.timestamp;
    }

    /**
     * @dev Mints a unique, soulbound SkillGraph NFT for the agent.
     *      This NFT dynamically reflects their skills and reputation.
     *      Callable once per agent.
     */
    function mintSkillGraphNFT() public whenNotPaused {
        require(skillGraphNFTAddress != address(0), "SkillGraph NFT contract not set");
        require(agents[msg.sender].skillGraphTokenId == 0, "Agent already has a SkillGraph NFT");
        // Agent must have an initialized reputation (e.g., via first skill assessment)
        require(agents[msg.sender].reputationScore >= INITIAL_REPUTATION, "Reputation not initialized for NFT minting");

        ISkillGraphNFT nft = ISkillGraphNFT(skillGraphNFTAddress);
        // Simple token ID derived from address (collision resistant for practical purposes)
        uint256 tokenId = uint256(uint160(msg.sender));
        string memory tokenURI = _generateSkillGraphURI(msg.sender);

        require(nft.mint(msg.sender, tokenId, tokenURI), "SkillGraph NFT minting failed");
        agents[msg.sender].skillGraphTokenId = tokenId;
        emit SkillGraphNFTMinted(msg.sender, tokenId);
    }

    /**
     * @dev Generates the IPFS/Arweave URI for an agent's SkillGraph NFT metadata.
     *      This URI points to a JSON file describing their skills and reputation.
     *      It can be dynamically generated off-chain by a metadata service or on-chain
     *      (though on-chain JSON generation is gas-intensive).
     * @param _agent The agent's address.
     * @return The URI for the NFT metadata.
     */
    function _generateSkillGraphURI(address _agent) internal view returns (string memory) {
        // This is a placeholder. In a real system, this URI would point to a service
        // that dynamically generates the JSON metadata based on the agent's on-chain data.
        // Example: ipfs://<hash>/<agent_address>.json
        // Or a dedicated API: https://api.cognitochain.io/skillgraph/<agent_address>
        string memory baseURI = "ipfs://QmbzG2QxXyZ7N7F6Y8L9K0M1N2O3P4Q5R6S7T8U9V0W1X2Y3Z4A5B6C7D8E9F0/"; // Example base IPFS hash
        string memory agentAddressStr = _addressToString(_agent);
        uint256 currentReputation = agents[_agent].reputationScore;

        // Basic dynamic content: agent address, reputation
        // In a real scenario, this would include all assessed skills from agents[_agent].skillLevels
        return string(abi.encodePacked(baseURI, "agent_", agentAddressStr, "_rep_", _uint256ToString(currentReputation), ".json"));
    }

    /**
     * @dev Helper function to convert an address to its string representation.
     */
    function _addressToString(address _address) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i+12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i+12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Helper function to convert a uint256 to its string representation.
     */
    function _uint256ToString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (j = _i, j != 0) { // Fix: use _i for calculations
            bstr[k--] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    // --- 5. Task & Project Management ---

    /**
     * @dev Creates a new task / bounty.
     * @param _requiredSkillId The ID of the primary skill required for this task.
     * @param _minSkillLevel The minimum required skill level (0-10000).
     * @param _bountyAmount The amount of bounty.
     * @param _bountyToken The address of the ERC20 token for the bounty, or address(0) for native token.
     * @param _applicationDeadline Unix timestamp for application deadline.
     * @param _submissionDeadline Unix timestamp for task submission deadline after assignment.
     */
    function createTask(
        bytes32 _requiredSkillId,
        uint256 _minSkillLevel,
        uint256 _bountyAmount,
        address _bountyToken,
        uint256 _applicationDeadline,
        uint256 _submissionDeadline
    ) public payable whenNotPaused {
        require(skills[_requiredSkillId].id != bytes32(0), "Required skill does not exist");
        require(_bountyAmount > 0, "Bounty amount must be greater than zero");
        require(_applicationDeadline > block.timestamp, "Application deadline must be in the future");
        require(_submissionDeadline > _applicationDeadline, "Submission deadline must be after application deadline");
        require(_minSkillLevel <= 10000, "Min skill level must be between 0 and 10000");

        if (_bountyToken == address(0)) {
            require(msg.value == _bountyAmount, "Native token bounty requires exact value sent");
        } else {
            // For ERC20, the creator needs to approve this contract to spend the tokens.
            // This transferFrom takes the tokens from msg.sender and puts them into this contract as escrow.
            IERC20(_bountyToken).transferFrom(msg.sender, address(this), _bountyAmount);
        }

        bytes32 taskId = keccak256(abi.encodePacked(msg.sender, _requiredSkillId, block.timestamp, _bountyAmount)); // More unique ID

        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            requiredSkillId: _requiredSkillId,
            minSkillLevel: _minSkillLevel,
            bountyAmount: _bountyAmount,
            bountyToken: _bountyToken,
            creationTime: block.timestamp,
            applicationDeadline: _applicationDeadline,
            submissionDeadline: _submissionDeadline,
            assignedAgent: address(0),
            status: 0, // Open
            submissionCommitment: bytes32(0),
            submissionURI: "",
            qualityScore: 0
        });
        openTaskIds.push(taskId);
        emit TaskCreated(taskId, msg.sender, _requiredSkillId, _bountyAmount);
    }

    /**
     * @dev Allows an agent to apply for an open task.
     * @param _taskId The ID of the task to apply for.
     */
    function applyForTask(bytes32 _taskId) public view whenNotPaused { // Changed to view as it doesn't modify state
        Task storage task = tasks[_taskId];
        require(task.id != bytes32(0), "Task does not exist");
        require(task.status == 0, "Task is not open for applications");
        require(block.timestamp < task.applicationDeadline, "Application deadline has passed");
        require(agents[msg.sender].reputationScore >= MIN_REPUTATION_FOR_TASK_APPLICATION, "Insufficient reputation to apply");
        require(agents[msg.sender].skillLevels[task.requiredSkillId] >= task.minSkillLevel, "Insufficient skill level for this task");

        // This function merely serves as a check. In a more complex system,
        // it would register the applicant and allow the creator to pick from a list.
        emit TaskApplicationReceived(_taskId, msg.sender);
    }

    /**
     * @dev Assigns a task to a specific agent. Only callable by the task creator.
     * @param _taskId The ID of the task to assign.
     * @param _agent The address of the agent to assign the task to.
     */
    function assignTask(bytes32 _taskId, address _agent) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.id != bytes32(0), "Task does not exist");
        require(task.creator == msg.sender, "Only task creator can assign");
        require(task.status == 0, "Task is not open for assignment");
        require(block.timestamp < task.applicationDeadline, "Cannot assign after application deadline");
        // Re-check agent qualifications at assignment time for robustness
        require(agents[_agent].reputationScore >= MIN_REPUTATION_FOR_TASK_APPLICATION, "Assigned agent has insufficient reputation");
        require(agents[_agent].skillLevels[task.requiredSkillId] >= task.minSkillLevel, "Assigned agent has insufficient skill level");

        task.assignedAgent = _agent;
        task.status = 1; // Assigned
        // Remove from openTaskIds array
        for (uint i = 0; i < openTaskIds.length; i++) {
            if (openTaskIds[i] == _taskId) {
                openTaskIds[i] = openTaskIds[openTaskIds.length - 1]; // Swap with last element
                openTaskIds.pop(); // Remove last element
                break;
            }
        }
        emit TaskAssigned(_taskId, _agent);
    }

    /**
     * @dev Agent commits a hash of their task completion proof.
     * @param _taskId The ID of the task.
     * @param _commitmentHash A hash of the task submission data and a salt.
     */
    function submitTaskCompletionCommitment(bytes32 _taskId, bytes32 _commitmentHash) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.id != bytes32(0), "Task does not exist");
        require(task.assignedAgent == msg.sender, "Only assigned agent can submit");
        require(task.status == 1, "Task not in assigned status");
        require(task.submissionCommitment == bytes32(0), "Task already has a pending submission");
        require(block.timestamp < task.submissionDeadline, "Task submission deadline has passed");

        task.submissionCommitment = _commitmentHash;
        emit TaskSubmissionCommitted(_taskId, msg.sender, _commitmentHash);
    }

    /**
     * @dev Agent reveals their task completion proof.
     * @param _taskId The ID of the task.
     * @param _submissionURI IPFS/Arweave URI to the task submission data.
     * @param _salt The salt used during the commitment.
     */
    function revealTaskCompletion(bytes32 _taskId, string calldata _submissionURI, bytes32 _salt) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.id != bytes32(0), "Task does not exist");
        require(task.assignedAgent == msg.sender, "Only assigned agent can reveal");
        require(task.status == 1, "Task not in assigned status");
        require(task.submissionCommitment != bytes32(0), "No active commitment found for this task");
        require(keccak256(abi.encodePacked(_submissionURI, _salt)) == task.submissionCommitment, "Submission data does not match commitment");
        require(taskQualityAIOracle != address(0), "Task quality AI oracle not set");
        require(block.timestamp < task.submissionDeadline.add(REVEAL_PERIOD), "Reveal period expired");


        task.submissionURI = _submissionURI;
        task.status = 2; // Submitted
        task.submissionCommitment = bytes32(0); // Clear commitment after reveal

        emit TaskSubmissionRevealed(_taskId, msg.sender, _submissionURI);

        // Simulate external AI oracle call as described earlier.
        _simulateTaskQualityAssessmentCallback(_taskId, msg.sender, _submissionURI);
    }

    /**
     * @dev Private function to simulate an AI oracle callback for task quality assessment.
     *      In a production environment, this would be an external function called by a trusted oracle.
     * @param _taskId The ID of the task assessed.
     * @param _agent The agent who submitted the task.
     * @param _submissionURI The URI that was submitted (for context).
     */
    function _simulateTaskQualityAssessmentCallback(bytes32 _taskId, address _agent, string memory _submissionURI) private {
        // This function simulates the AI oracle's role.
        // In reality, the oracle would fetch and analyze _submissionURI off-chain.
        uint256 simulatedQualityScore = _calculateSimulatedTaskQualityScore(_submissionURI); // Placeholder for complex AI logic
        processTaskQualityAssessment(_taskId, _agent, simulatedQualityScore); // Directly call the processing function
    }

    /**
     * @dev Placeholder function to simulate AI's task quality score calculation.
     *      This would be complex off-chain AI logic, analyzing content pointed by _submissionURI.
     */
    function _calculateSimulatedTaskQualityScore(string memory _submissionURI) private pure returns (uint256) {
        // A dummy simulation: score loosely based on length of URI string
        uint256 length = bytes(_submissionURI).length;
        if (length > 100) return 9000; // High quality (90%)
        if (length > 50) return 6000;  // Medium quality (60%)
        return 3000;                   // Low quality (30%)
    }


    /**
     * @dev Callback function to receive task quality assessment results from the AI oracle.
     *      Only callable by the `taskQualityAIOracle` address.
     * @param _taskId The ID of the task that was assessed.
     * @param _agent The agent who completed the task.
     * @param _qualityScore The assessed quality score (0-10000).
     */
    function processTaskQualityAssessment(bytes32 _taskId, address _agent, uint256 _qualityScore) public whenNotPaused {
        require(msg.sender == taskQualityAIOracle, "Only the task quality oracle can call this function");
        Task storage task = tasks[_taskId];
        require(task.id != bytes32(0), "Task does not exist");
        require(task.assignedAgent == _agent, "Agent mismatch for task");
        require(task.status == 2, "Task not in submitted status");
        require(_qualityScore <= 10000, "Quality score must be between 0 and 10000");

        task.qualityScore = _qualityScore;
        task.status = 3; // Completed
        _updateAgentReputation(_agent, _qualityScore, true); // Update reputation based on task quality

        // Trigger NFT metadata update
        if (agents[_agent].skillGraphTokenId != 0) {
            ISkillGraphNFT(skillGraphNFTAddress).updateTokenURI(agents[_agent].skillGraphTokenId, _generateSkillGraphURI(_agent));
            emit SkillGraphNFTMetadataUpdated(agents[_agent].skillGraphTokenId, _generateSkillGraphURI(_agent));
        }

        emit TaskQualityAssessmentReceived(_taskId, _agent, _qualityScore);
    }

    /**
     * @dev Releases the task reward to the assigned agent based on the quality score.
     *      Callable by the task creator after assessment, or by anyone after a dispute resolution period
     *      if the creator fails to release.
     * @param _taskId The ID of the task.
     */
    function releaseTaskReward(bytes32 _taskId) public whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.id != bytes32(0), "Task does not exist");
        require(task.status == 3, "Task not in completed status (or disputed)");
        require(msg.sender == task.creator || block.timestamp > task.creationTime.add(DISPUTE_RESOLUTION_PERIOD), "Only creator can release within dispute period, or anyone after dispute period");

        // Calculate actual payout based on AI quality score
        uint256 actualAmount = task.bountyAmount.mul(task.qualityScore).div(10000); // Scale reward by quality (e.g., 9000/10000 = 90% bounty)

        if (task.bountyToken == address(0)) {
            require(address(this).balance >= actualAmount, "Insufficient native balance for payout");
            payable(task.assignedAgent).transfer(actualAmount);
        } else {
            require(IERC20(task.bountyToken).balanceOf(address(this)) >= actualAmount, "Insufficient ERC20 balance for payout");
            IERC20(task.bountyToken).transfer(task.assignedAgent, actualAmount);
        }

        // Transfer remaining bounty back to creator if quality was less than 100%
        uint256 remainingBounty = task.bountyAmount.sub(actualAmount);
        if (remainingBounty > 0) {
            if (task.bountyToken == address(0)) {
                payable(task.creator).transfer(remainingBounty);
            } else {
                IERC20(task.bountyToken).transfer(task.creator, remainingBounty);
            }
        }

        task.status = 5; // Marked as fully processed
        emit TaskRewardReleased(_taskId, task.assignedAgent, actualAmount);
    }

    // --- 6. Dispute Resolution System ---

    /**
     * @dev Sets the address that can manage the jury pool (add/remove members).
     *      Only callable by owner or via governance.
     */
    function setJuryPoolManager(address _newManager) public onlyOwnerOrGovernance {
        require(_newManager != address(0), "Jury pool manager cannot be zero address");
        juryPoolManager = _newManager;
    }

    /**
     * @dev Modifier to restrict access to the jury pool manager.
     */
    modifier onlyJuryPoolManager() {
        require(msg.sender == juryPoolManager, "Only jury pool manager can perform this action");
        _;
    }

    /**
     * @dev Adds an address to the pool of eligible jury members.
     *      Callable only by `juryPoolManager`.
     * @param _member The address to add.
     */
    function addJuryMember(address _member) public onlyJuryPoolManager {
        require(!isJuryMember[_member], "Address is already a jury member");
        // Could add reputation checks here, e.g., require(agents[_member].reputationScore >= JURY_POOL_MIN_REPUTATION);
        juryMembers.push(_member);
        isJuryMember[_member] = true;
        emit JuryMemberAdded(_member);
    }

    /**
     * @dev Removes an address from the pool of eligible jury members.
     *      Callable only by `juryPoolManager`.
     * @param _member The address to remove.
     */
    function removeJuryMember(address _member) public onlyJuryPoolManager {
        require(isJuryMember[_member], "Address is not a jury member");
        for (uint i = 0; i < juryMembers.length; i++) {
            if (juryMembers[i] == _member) {
                juryMembers[i] = juryMembers[juryMembers.length - 1]; // Swap with last
                juryMembers.pop(); // Remove last
                break;
            }
        }
        isJuryMember[_member] = false;
        emit JuryMemberRemoved(_member);
    }

    /**
     * @dev Initiates a dispute for a skill assessment or task quality.
     *      Requires a fee to prevent spam.
     * @param _contextId The ID of the skill or task being disputed.
     * @param _disputeType The type of dispute (SkillAssessment or TaskQuality).
     * @param _feeToken The token used for the dispute initiation fee (address(0) for native).
     */
    function initiateDispute(
        bytes32 _contextId,
        DisputeType _disputeType,
        address _feeToken
    ) public payable whenNotPaused {
        bytes32 disputeId = keccak256(abi.encodePacked(_contextId, msg.sender, block.timestamp));
        require(disputes[disputeId].id == bytes32(0), "Dispute with this ID already exists");

        address subjectAgent;
        if (_disputeType == DisputeType.SkillAssessment) {
            require(skills[_contextId].id != bytes32(0), "Skill for dispute context does not exist");
            subjectAgent = msg.sender; // Agent disputes their own skill assessment
            require(agents[subjectAgent].skillLevels[_contextId] > 0, "No skill assessment to dispute for this agent");
        } else if (_disputeType == DisputeType.TaskQuality) {
            Task storage task = tasks[_contextId];
            require(task.id != bytes32(0), "Task for dispute context does not exist");
            require(task.status == 3, "Task must be in completed status to dispute quality");
            require(msg.sender == task.creator || msg.sender == task.assignedAgent, "Only task creator or assigned agent can dispute a task");
            subjectAgent = task.assignedAgent;
            task.status = 4; // Mark task as disputed to prevent reward release
        } else {
            revert("Invalid dispute type");
        }

        uint256 fee = (_feeToken == address(0)) ? DISPUTE_INITIATION_FEE_NATIVE : 0; // If ERC20, assume fee is approved/transferred externally
        if (_feeToken == address(0)) {
            require(msg.value == fee, "Incorrect native token fee sent");
        } else {
            // For ERC20 fees, the initiator would need to approve this contract first:
            // IERC20(_feeToken).transferFrom(msg.sender, address(this), _erc20FeeAmount);
            // This example assumes native token fee for simplicity, or pre-approved ERC20.
        }

        address[] memory juryPanel = _selectJuryPanel();
        require(juryPanel.length == JURY_PANEL_SIZE, "Not enough jury members available to form a panel");

        disputes[disputeId] = Dispute({
            id: disputeId,
            contextId: _contextId,
            disputeType: _disputeType,
            initiator: msg.sender,
            initiationTime: block.timestamp,
            subjectAgent: subjectAgent,
            feePaid: fee,
            feeToken: _feeToken,
            juryPanel: juryPanel,
            totalVotes: 0,
            resolved: false,
            outcome: DisputeOutcome.Neutral // Default until resolved
        });

        emit DisputeInitiated(disputeId, _contextId, uint8(_disputeType), msg.sender);
    }

    /**
     * @dev Internal function to select a random panel of jury members for a dispute.
     *      Uses a blockhash-based pseudo-randomness. Not cryptographically secure, but generally
     *      acceptable for decentralized dispute arbitration if the stake is not extremely high.
     */
    function _selectJuryPanel() internal view returns (address[] memory) {
        require(juryMembers.length >= JURY_PANEL_SIZE, "Not enough eligible jury members in the pool");

        address[] memory panel = new address[](JURY_PANEL_SIZE);
        uint256 seed = uint256(block.timestamp) ^ uint256(block.difficulty); // Basic seed
        // Using block.prevrandao post-Merge for better (but still not perfect) randomness
        if (block.number > 0) {
            seed = seed ^ uint256(block.prevrandao);
        }
        seed = uint256(keccak256(abi.encodePacked(seed, block.gaslimit, tx.gasprice, msg.sender, block.number))); // Further scramble

        // Select distinct jury members for the panel
        mapping(address => bool) private _selected; // Helper to track selected members for current panel selection
        uint selectedCount = 0;
        while(selectedCount < JURY_PANEL_SIZE) {
            uint256 randomIndex = (seed % juryMembers.length);
            address candidate = juryMembers[randomIndex];

            if (!_selected[candidate]) {
                panel[selectedCount] = candidate;
                _selected[candidate] = true;
                selectedCount++;
            }
            seed = uint256(keccak256(abi.encodePacked(seed, block.timestamp, selectedCount))); // Update seed for next pick
        }
        return panel;
    }

    /**
     * @dev Allows a selected jury member to submit their verdict for a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _verdict The verdict (0: Agree, 1: Disagree, 2: Abstain). 'Agree' supports the initiator's claim.
     */
    function submitJuryVerdict(bytes32 _disputeId, Verdict _verdict) public whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != bytes32(0), "Dispute does not exist");
        require(!dispute.resolved, "Dispute already resolved");
        require(block.timestamp < dispute.initiationTime.add(DISPUTE_RESOLUTION_PERIOD), "Dispute resolution period expired");
        require(isJuryMember[msg.sender], "Caller is not an eligible jury member");

        bool isInPanel = false;
        for (uint i = 0; i < dispute.juryPanel.length; i++) {
            if (dispute.juryPanel[i] == msg.sender) {
                isInPanel = true;
                break;
            }
        }
        require(isInPanel, "Caller is not part of this dispute's jury panel");
        require(dispute.juryVotes[msg.sender] == Verdict.Abstain, "Jury member has already voted"); // Default is Abstain initially

        dispute.juryVotes[msg.sender] = _verdict;
        dispute.totalVotes++;

        emit JuryVerdictSubmitted(_disputeId, msg.sender, uint8(_verdict));
    }

    /**
     * @dev Resolves a dispute based on jury votes and executes the outcome.
     *      Can be called by anyone after the dispute resolution period, or by anyone earlier if all votes are in.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(bytes32 _disputeId) public whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != bytes32(0), "Dispute does not exist");
        require(!dispute.resolved, "Dispute already resolved");
        require(block.timestamp >= dispute.initiationTime.add(DISPUTE_RESOLUTION_PERIOD) || dispute.totalVotes == dispute.juryPanel.length, "Dispute period not over or not all votes cast");

        uint256 agreeVotes = 0;
        uint256 disagreeVotes = 0;

        for (uint i = 0; i < dispute.juryPanel.length; i++) {
            address jury = dispute.juryPanel[i];
            if (dispute.juryVotes[jury] == Verdict.Agree) {
                agreeVotes++;
            } else if (dispute.juryVotes[jury] == Verdict.Disagree) {
                disagreeVotes++;
            }
            // Abstain votes are ignored for majority calculation
        }

        DisputeOutcome outcome;
        if (agreeVotes > disagreeVotes) {
            outcome = DisputeOutcome.AgentWins; // Initiator's claim (usually agent) is supported
            if (dispute.disputeType == DisputeType.SkillAssessment) {
                 // Agent's claim about higher skill/better assessment is supported
                 // Could trigger a re-assessment, or a small rep boost
                 _updateAgentReputation(dispute.subjectAgent, 100, true); // Small rep boost for successful dispute
            } else if (dispute.disputeType == DisputeType.TaskQuality) {
                // Agent's task quality is upheld as sufficient.
                _updateAgentReputation(dispute.subjectAgent, 200, true); // Small rep boost
                // Task status can remain 'Completed' (3) or return from 'Disputed' (4) to 'Completed'
                tasks[dispute.contextId].status = 3;
            }
        } else if (disagreeVotes > agreeVotes) {
            outcome = DisputeOutcome.CreatorWins; // Counter-party's claim (e.g., task creator's view) is supported
            if (dispute.disputeType == DisputeType.SkillAssessment) {
                // Agent's skill assessment is deemed incorrect or lower.
                _updateAgentReputation(dispute.subjectAgent, 500, false); // Rep penalty
            } else if (dispute.disputeType == DisputeType.TaskQuality) {
                // Task quality deemed lower than claimed.
                _updateAgentReputation(dispute.subjectAgent, 1000, false); // Significant rep penalty
                // Task status set to a state where creator can decide to cancel or request rework.
                tasks[dispute.contextId].status = 0; // Back to open, for creator to re-assign or cancel
            }
        } else {
            outcome = DisputeOutcome.Neutral; // Tie or no clear majority. Original state stands.
            // Refund dispute fee to initiator in case of tie.
        }

        dispute.resolved = true;
        dispute.outcome = outcome;

        // Refund dispute fee if initiator wins or if dispute is neutral
        if (outcome == DisputeOutcome.AgentWins || outcome == DisputeOutcome.Neutral) {
            if (dispute.feeToken == address(0)) {
                payable(dispute.initiator).transfer(dispute.feePaid);
            } else {
                // For ERC20 fee refund, transfer back to initiator
                // IERC20(dispute.feeToken).transfer(dispute.initiator, dispute.feePaid);
            }
        }

        emit DisputeResolved(_disputeId, uint8(outcome));
    }

    // --- 7. Governance & Parameter Management ---

    /**
     * @dev Proposes a change to a contract parameter or a contract upgrade.
     *      Anyone can propose, but passing requires governance vote.
     * @param _description A clear description of the proposal.
     * @param _targetContract The contract address to call (can be `address(this)` for self-modification).
     * @param _callData The encoded function call to execute (e.g., `abi.encodeWithSignature("updateSkillAssessmentAIOracle(address)", newAddress)`).
     */
    function proposeParameterChange(
        string calldata _description,
        address _targetContract,
        bytes calldata _callData
    ) public whenNotPaused {
        bytes32 proposalId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _description)); // Unique ID for proposal
        require(proposals[proposalId].id == bytes32(0), "Proposal with this ID already exists");
        require(_targetContract != address(0), "Target contract cannot be zero address");
        require(_callData.length > 0, "Call data cannot be empty");

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp.add(PROPOSAL_VOTING_PERIOD),
            votesFor: 0,
            votesAgainst: 0,
            // `hasVoted` mapping is part of the struct, automatically initialized.
            callData: _callData,
            targetContract: _targetContract,
            executed: false,
            cancelled: false
        });

        emit ParameterChangeProposed(proposalId, _description);
    }

    /**
     * @dev Allows an agent (or any stakeholder deemed eligible for voting) to vote on a proposal.
     *      Voting power could be weighted by reputation or token holdings in a real DAO.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'yes' (support), false for 'no' (against).
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != bytes32(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp < proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and received enough 'for' votes.
     *      Requires a simple majority for now. Can be called by anyone.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != bytes32(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp >= proposal.votingDeadline, "Voting period has not ended");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass (not enough 'for' votes)");

        // Execute the proposed action using a low-level call
        (bool success, bytes memory returndata) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("Proposal execution failed: ", returndata)));

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- VIII. Helper View Functions ---

    /**
     * @dev Retrieves an agent's current reputation score.
     * @param _agent The agent's address.
     * @return The agent's reputation score (0-10000).
     */
    function getAgentReputation(address _agent) public view returns (uint256) {
        return agents[_agent].reputationScore;
    }

    /**
     * @dev Retrieves an agent's assessed skill level for a specific skill.
     * @param _agent The agent's address.
     * @param _skillId The ID of the skill.
     * @return The skill level (0-10000).
     */
    function getAgentSkillLevel(address _agent, bytes32 _skillId) public view returns (uint256) {
        return agents[_agent].skillLevels[_skillId];
    }

    /**
     * @dev Returns the current status of a task.
     * @param _taskId The ID of the task.
     * @return The task status (0: Open, 1: Assigned, 2: Submitted, 3: Completed, 4: Disputed, 5: Cancelled/Processed).
     */
    function getTaskStatus(bytes32 _taskId) public view returns (uint8) {
        return tasks[_taskId].status;
    }

    /**
     * @dev Get total number of defined skills.
     */
    function getTotalSkills() public view returns (uint256) {
        return allSkillIds.length;
    }

    /**
     * @dev Get total number of open tasks.
     */
    function getTotalOpenTasks() public view returns (uint256) {
        return openTaskIds.length;
    }
}
```