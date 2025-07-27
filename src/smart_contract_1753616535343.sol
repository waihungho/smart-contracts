```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/OracleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title QuantumForge Protocol
 * @dev An advanced decentralized research and development platform leveraging AI agents, dynamic NFTs,
 *      and a robust reputation system. It facilitates project funding, milestone progression,
 *      and incorporates on-chain AI agent performance tracking through Chainlink oracles.
 *      This contract focuses on novelty by combining:
 *      1. Dynamic Research NFTs (dRNFTs) that evolve with project progress.
 *      2. AI Agent NFTs whose on-chain performance (via oracles) impacts projects and reputation.
 *      3. A reputation system tied to both human contributions and AI agent efficacy.
 *      4. A milestone-driven funding release model.
 *      It aims to avoid direct duplication of existing open-source projects by focusing on this unique synergy.
 *
 * @outline
 * I. Core Infrastructure & Setup
 *    - Constructor: Initializes contract with base roles (admin, pauser).
 *    - Role Management: Functions for assigning specialized roles like Milestone Verifier.
 *    - Chainlink Configuration: Setting LINK token, Oracle addresses, and Job IDs for AI data feeds.
 *    - Contract State Control: Emergency pausing and unpausing of contract operations.
 *
 * II. Research Project Management (Dynamic Research NFTs - dRNFTs)
 *    - Project Creation: Allows users to propose and mint unique Dynamic Research NFTs (dRNFTs) representing projects.
 *    - Funding Mechanism: Supports contributions in ETH and any ERC20 token to specific projects.
 *    - Milestone Workflow: Enables project leads to propose, request verification for, and withdraw funds upon
 *      successful completion and verification of project milestones.
 *    - Dynamic NFT Updates: Allows project leads to update the metadata URI of their dRNFTs to reflect progress.
 *
 * III. AI Agent Integration & Performance Tracking
 *    - AI Agent Registration: Allows owners to register their AI models as unique AI Agent NFTs.
 *    - Task Assignment: Project leads can assign registered AI agents to specific research tasks within their projects.
 *    - Oracle Integration: Utilizes Chainlink oracles to request off-chain AI processing (e.g., data analysis, predictions).
 *    - Performance Evaluation: On-chain logic to process Chainlink callback results and update AI agent performance metrics,
 *      contributing to their reputation and utility.
 *    - AI Training Simulation: A conceptual function to represent AI model improvement with an associated cost.
 *
 * IV. Reputation System & Governance
 *    - Reputation Accumulation: Users and successful AI agents accrue reputation based on valuable contributions and verifiable performance.
 *    - Reputation Delegation: Allows for delegation of reputation, enabling liquid democracy within governance.
 *    - Governance Proposals: Mechanism for reputation holders to submit and vote on system-wide or project-specific proposals.
 *    - Reputation Badges: A conceptual integration for Soulbound Token (SBT)-like badges earned for reaching reputation tiers.
 *
 * V. Treasury & Utility
 *    - Fee Management: Handles the collection and withdrawal of protocol-level fees.
 *    - User Utility: Functions enabling users to manage their own reputation.
 *
 * @function_summary
 * 1.  constructor(): Initializes `AccessControl` roles and sets the initial admin.
 * 2.  updateLinkTokenAddress(address _link): Admin function to update the address of the Chainlink LINK token.
 * 3.  updateOracleAddress(address _oracle): Admin function to update the address of the Chainlink Oracle.
 * 4.  setAIDataFeedJobId(bytes32 _jobId): Admin function to set the Chainlink Job ID for AI data requests.
 * 5.  setMilestoneVerifierRole(address _account): Admin function to grant `MILESTONE_VERIFIER_ROLE` to an address.
 * 6.  createResearchProject(string memory _name, string memory _description, string memory _initialURI): Creates a new research project, mints a dRNFT, and assigns project lead.
 * 7.  fundResearchProject(uint256 _projectId, uint256 _amount, address _erc20Token): Allows users to contribute funds (ETH or specified ERC20) to a research project.
 * 8.  proposeMilestone(uint256 _projectId, string memory _description, uint256 _targetFundingShare): Project lead proposes a new milestone with a share of total project funding.
 * 9.  requestMilestoneVerification(uint256 _projectId, uint256 _milestoneId): Project lead requests verification for a completed milestone.
 * 10. verifyMilestone(uint256 _projectId, uint256 _milestoneId, bool _approved): An authorized verifier approves or rejects a milestone, triggering fund release or status update.
 * 11. withdrawMilestoneFunds(uint256 _projectId, uint256 _milestoneId): Project lead withdraws funds allocated to a verified milestone.
 * 12. updateResearchProjectMetadata(uint256 _projectId, string memory _newURI): Project lead updates the dRNFT's `tokenURI` to reflect project progress.
 * 13. registerAIAgent(string memory _name, string memory _description, string memory _initialURI): Registers a new AI model, mints an AI Agent NFT, and sets its owner.
 * 14. assignAIAgentToTask(uint256 _projectId, uint256 _agentId, string memory _taskDescription): Project lead assigns a registered AI agent to a specific task within their project.
 * 15. submitAIDataRequest(uint256 _projectId, uint256 _agentId, string memory _prompt): Requests AI processing via Chainlink, sending a prompt/input for the assigned agent.
 * 16. fulfillAIDataRequest(bytes32 _requestId, string[] memory _result): Chainlink callback function to receive and process results from off-chain AI computation.
 * 17. evaluateAIAgentPerformance(uint256 _agentId, string[] memory _results): Internal function called by `fulfillAIDataRequest` to update an AI agent's performance score based on results.
 * 18. trainAIAgent(uint256 _agentId, uint256 _reputationCost): Simulates an AI agent undergoing "training," potentially costing reputation or requiring proof.
 * 19. getAIAgentPerformanceMetric(uint256 _agentId): View function to retrieve the current performance score of an AI agent.
 * 20. accrueReputation(address _account, uint256 _amount): Internal function to increase an account's reputation score (e.g., upon successful project/AI contributions).
 * 21. delegateReputation(address _delegatee, uint256 _amount): Allows a user to delegate a portion of their reputation to another address for voting power.
 * 22. undelegateReputation(): Allows a user to revoke all their active reputation delegations.
 * 23. submitGovernanceProposal(string memory _description, address _target, bytes memory _calldata): Allows reputation holders to propose on-chain actions or policy changes.
 * 24. voteOnProposal(uint256 _proposalId, bool _support): Allows reputation holders (or their delegates) to vote on open governance proposals.
 * 25. claimReputationBadge(uint256 _tier): Conceptual function for users to claim a Soulbound Token (SBT)-like badge representing their reputation tier (requires external SBT contract).
 * 26. pause(): Admin function to pause all sensitive operations in case of emergency.
 * 27. unpause(): Admin function to unpause operations once emergency is resolved.
 * 28. withdrawProtocolFees(): Admin function to withdraw accumulated protocol fees.
 * 29. burnReputation(uint256 _amount): Allows a user to voluntarily burn a specified amount of their own reputation score.
 */
contract QuantumForge is ERC721, AccessControl, Pausable, ReentrancyGuard, ChainlinkClient {
    // --- Roles ---
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MILESTONE_VERIFIER_ROLE = keccak256("MILESTONE_VERIFIER_ROLE");

    // --- Events ---
    event ResearchProjectCreated(uint256 indexed projectId, address indexed projectLead, string name);
    event ProjectFunded(uint256 indexed projectId, address indexed contributor, uint256 amount, address token);
    event MilestoneProposed(uint256 indexed projectId, uint256 indexed milestoneId, string description);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneId, bool approved);
    event FundsWithdrawn(uint256 indexed projectId, uint256 indexed milestoneId, uint256 amount);
    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string name);
    event AIAgentAssigned(uint256 indexed projectId, uint256 indexed agentId, string taskDescription);
    event AIDataRequestSent(bytes32 indexed requestId, uint256 indexed projectId, uint256 indexed agentId, string prompt);
    event AIDataFulfilled(bytes32 indexed requestId, string[] result);
    event AIAgentPerformanceUpdated(uint256 indexed agentId, uint256 newPerformanceScore);
    event ReputationAccrued(address indexed account, uint256 amount);
    event ReputationBurned(address indexed account, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator);
    event ProposalSubmitted(uint256 indexed proposalId, string description, address target, bytes calldataBytes);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProtocolFeesWithdrawn(address indexed admin, uint256 ethAmount, mapping(address => uint256) erc20Amounts);

    // --- State Variables ---
    uint256 private _nextProjectId;
    uint256 private _nextAIAgentId;
    uint256 private _nextProposalId;

    // --- Protocol Fees ---
    uint256 public protocolFeeBps = 50; // 0.5% (basis points, 10000 = 100%)
    uint256 public totalEthFeesCollected;
    mapping(address => uint256) public totalErc20FeesCollected; // ERC20 token address => amount

    // --- Research Projects (dRNFTs) ---
    struct ResearchProject {
        uint256 id;
        string name;
        string description;
        address projectLead;
        uint256 totalFundedAmount;
        mapping(address => uint256) tokenBalances; // tokenAddress => amount
        uint256 nextMilestoneId;
        mapping(uint256 => Milestone) milestones; // milestoneId => Milestone
        bool exists; // To check if project ID is valid
    }

    struct Milestone {
        uint256 id;
        string description;
        uint256 targetFundingShare; // Percentage of total project funds (e.g., 2000 for 20%)
        bool verified;
        bool fundsWithdrawn;
        uint256 totalFundsAllocated; // Actual amount in wei/smallest unit allocated
    }

    mapping(uint256 => ResearchProject) public researchProjects;

    // --- AI Agents (AI Agent NFTs) ---
    struct AIAgent {
        uint256 id;
        string name;
        string description;
        address owner;
        uint256 performanceScore; // Higher is better
        bool exists;
    }

    mapping(uint256 => AIAgent) public aiAgents;
    mapping(uint256 => uint256) public aiAgentOwners; // tokenId => ownerId

    // --- Chainlink Integration ---
    bytes32 public aiDataFeedJobId;
    mapping(bytes32 => RequestDetails) public requestIdToRequestDetails; // requestId => details

    struct RequestDetails {
        uint256 projectId;
        uint256 agentId;
        address caller;
    }

    // --- Reputation System ---
    mapping(address => uint256) public reputationScores;
    mapping(address => address) public delegatedReputation; // delegator => delegatee
    mapping(address => uint256) public delegatedAmount; // delegator => amount delegated

    // --- Governance ---
    struct Proposal {
        uint256 id;
        string description;
        address target;
        bytes calldataBytes;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 creationTime;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    // --- Constructor ---
    constructor(
        address _link,
        address _oracle
    ) ERC721("QuantumForge Research NFT", "QFR")
        ChainlinkClient() // Initialize ChainlinkClient
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        setChainlinkToken(_link);
        setOracle(_oracle);
    }

    // --- Chainlink Configuration (Admin Only) ---

    /// @notice Admin function to update the Chainlink LINK token address.
    /// @param _link The new LINK token address.
    function updateLinkTokenAddress(address _link) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setChainlinkToken(_link);
    }

    /// @notice Admin function to update the Chainlink Oracle address.
    /// @param _oracle The new Oracle address.
    function updateOracleAddress(address _oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setOracle(_oracle);
    }

    /// @notice Admin function to set the Chainlink Job ID for AI data requests.
    /// @param _jobId The new Chainlink Job ID.
    function setAIDataFeedJobId(bytes32 _jobId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aiDataFeedJobId = _jobId;
    }

    // --- Role Management (Admin Only) ---

    /// @notice Admin function to grant the MILESTONE_VERIFIER_ROLE to an account.
    /// @param _account The address to grant the role to.
    function setMilestoneVerifierRole(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MILESTONE_VERIFIER_ROLE, _account);
    }

    // --- Pausable Functions ---

    /// @notice Admin function to pause all sensitive operations in case of emergency.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Admin function to unpause operations once emergency is resolved.
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // --- Research Project Management (dRNFTs) ---

    /// @notice Creates a new research project, mints a dRNFT, and assigns project lead.
    /// @param _name The name of the research project.
    /// @param _description A description of the project.
    /// @param _initialURI The initial metadata URI for the dRNFT.
    /// @return The ID of the newly created project.
    function createResearchProject(
        string memory _name,
        string memory _description,
        string memory _initialURI
    ) external whenNotPaused returns (uint256) {
        uint256 projectId = _nextProjectId++;
        _mint(msg.sender, projectId);
        _setTokenURI(projectId, _initialURI);

        researchProjects[projectId] = ResearchProject({
            id: projectId,
            name: _name,
            description: _description,
            projectLead: msg.sender,
            totalFundedAmount: 0,
            nextMilestoneId: 0,
            exists: true
        });

        emit ResearchProjectCreated(projectId, msg.sender, _name);
        return projectId;
    }

    /// @notice Allows users to contribute funds (ETH or specified ERC20) to a research project.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount of funds to contribute.
    /// @param _erc20Token The address of the ERC20 token. Use address(0) for ETH.
    function fundResearchProject(
        uint256 _projectId,
        uint256 _amount,
        address _erc20Token
    ) external payable whenNotPaused nonReentrant {
        require(researchProjects[_projectId].exists, "Project does not exist");
        require(_amount > 0, "Amount must be greater than zero");

        uint256 feeAmount = (_amount * protocolFeeBps) / 10000;
        uint256 amountToProject = _amount - feeAmount;

        if (_erc20Token == address(0)) { // ETH
            require(msg.value == _amount, "ETH amount mismatch");
            researchProjects[_projectId].tokenBalances[address(0)] += amountToProject;
            totalEthFeesCollected += feeAmount;
        } else { // ERC20
            require(msg.value == 0, "Do not send ETH with ERC20 funding");
            IERC20(_erc20Token).transferFrom(msg.sender, address(this), _amount);
            researchProjects[_projectId].tokenBalances[_erc20Token] += amountToProject;
            totalErc20FeesCollected[_erc20Token] += feeAmount;
        }

        researchProjects[_projectId].totalFundedAmount += amountToProject;
        emit ProjectFunded(_projectId, msg.sender, _amount, _erc20Token);
    }

    /// @notice Project lead proposes a new milestone with a share of total project funding.
    /// @param _projectId The ID of the project.
    /// @param _description Description of the milestone.
    /// @param _targetFundingShare The percentage of total project funds allocated to this milestone (e.g., 2000 for 20%).
    function proposeMilestone(
        uint256 _projectId,
        string memory _description,
        uint256 _targetFundingShare
    ) external whenNotPaused {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.exists, "Project does not exist");
        require(msg.sender == project.projectLead, "Only project lead can propose milestones");
        require(_targetFundingShare > 0 && _targetFundingShare <= 10000, "Invalid funding share"); // 1-100%

        uint256 milestoneId = project.nextMilestoneId++;
        uint256 allocatedFunds = (project.totalFundedAmount * _targetFundingShare) / 10000;

        project.milestones[milestoneId] = Milestone({
            id: milestoneId,
            description: _description,
            targetFundingShare: _targetFundingShare,
            verified: false,
            fundsWithdrawn: false,
            totalFundsAllocated: allocatedFunds
        });

        emit MilestoneProposed(_projectId, milestoneId, _description);
    }

    /// @notice Project lead requests verification for a completed milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone to verify.
    function requestMilestoneVerification(
        uint256 _projectId,
        uint256 _milestoneId
    ) external whenNotPaused {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.exists, "Project does not exist");
        require(msg.sender == project.projectLead, "Only project lead can request verification");
        require(project.milestones[_milestoneId].id == _milestoneId, "Milestone does not exist");
        require(!project.milestones[_milestoneId].verified, "Milestone already verified");

        // In a real scenario, this might trigger an event for verifiers or a Chainlink request for external verification.
        // For simplicity, we just allow the call for `verifyMilestone`.
        emit MilestoneRequestedVerification(_projectId, _milestoneId);
    }

    /// @notice An authorized verifier approves or rejects a milestone, triggering fund release or status update.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    /// @param _approved True if approved, false if rejected.
    function verifyMilestone(
        uint256 _projectId,
        uint256 _milestoneId,
        bool _approved
    ) external onlyRole(MILESTONE_VERIFIER_ROLE) whenNotPaused {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.exists, "Project does not exist");
        require(project.milestones[_milestoneId].id == _milestoneId, "Milestone does not exist");
        require(!project.milestones[_milestoneId].verified, "Milestone already verified");

        project.milestones[_milestoneId].verified = _approved;
        if (_approved) {
            _accrueReputation(msg.sender, 50); // Verifiers gain reputation for successful verification
        }
        emit MilestoneVerified(_projectId, _milestoneId, _approved);
    }

    /// @notice Project lead withdraws funds allocated to a verified milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    function withdrawMilestoneFunds(
        uint256 _projectId,
        uint256 _milestoneId
    ) external nonReentrant whenNotPaused {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.exists, "Project does not exist");
        require(msg.sender == project.projectLead, "Only project lead can withdraw funds");

        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.id == _milestoneId, "Milestone does not exist");
        require(milestone.verified, "Milestone not yet verified");
        require(!milestone.fundsWithdrawn, "Funds already withdrawn for this milestone");
        require(milestone.totalFundsAllocated > 0, "No funds allocated to this milestone");

        // Assuming ETH for simplicity of withdrawal, can extend for ERC20.
        // In a real multi-token scenario, would need to track funds per token.
        uint256 amountToWithdraw = milestone.totalFundsAllocated;
        require(project.tokenBalances[address(0)] >= amountToWithdraw, "Insufficient ETH balance for milestone");

        project.tokenBalances[address(0)] -= amountToWithdraw;
        milestone.fundsWithdrawn = true;

        (bool success, ) = project.projectLead.call{value: amountToWithdraw}("");
        require(success, "Failed to send ETH to project lead");

        _accrueReputation(msg.sender, 100); // Project lead gains reputation for successful milestone completion
        emit FundsWithdrawn(_projectId, _milestoneId, amountToWithdraw);
    }

    /// @notice Project lead updates the dRNFT's `tokenURI` to reflect project progress.
    /// @param _projectId The ID of the project.
    /// @param _newURI The new metadata URI for the dRNFT.
    function updateResearchProjectMetadata(
        uint256 _projectId,
        string memory _newURI
    ) external whenNotPaused {
        require(researchProjects[_projectId].exists, "Project does not exist");
        require(msg.sender == researchProjects[_projectId].projectLead, "Only project lead can update metadata");
        _setTokenURI(_projectId, _newURI);
        emit ResearchProjectMetadataUpdated(_projectId, _newURI);
    }

    // --- AI Agent Integration & Performance Tracking ---

    /// @notice Registers a new AI model, mints an AI Agent NFT, and sets its owner.
    /// @param _name The name of the AI agent.
    /// @param _description A description of the AI agent.
    /// @param _initialURI The initial metadata URI for the AI Agent NFT.
    /// @return The ID of the newly registered AI agent.
    function registerAIAgent(
        string memory _name,
        string memory _description,
        string memory _initialURI
    ) external whenNotPaused returns (uint256) {
        uint256 agentId = _nextAIAgentId++;
        // We're reusing the same ERC721 contract for AI agents as well for simplicity.
        // In a real application, distinct ERC721s might be preferable.
        _mint(msg.sender, agentId + 1_000_000_000); // Offset to avoid ID collision with projects
        _setTokenURI(agentId + 1_000_000_000, _initialURI);

        aiAgents[agentId] = AIAgent({
            id: agentId,
            name: _name,
            description: _description,
            owner: msg.sender,
            performanceScore: 0, // Initial score
            exists: true
        });

        emit AIAgentRegistered(agentId, msg.sender, _name);
        return agentId;
    }

    /// @notice Project lead assigns a registered AI agent to a specific task within their project.
    /// @param _projectId The ID of the project.
    /// @param _agentId The ID of the AI agent to assign.
    /// @param _taskDescription A description of the task for the AI agent.
    function assignAIAgentToTask(
        uint256 _projectId,
        uint256 _agentId,
        string memory _taskDescription
    ) external whenNotPaused {
        require(researchProjects[_projectId].exists, "Project does not exist");
        require(msg.sender == researchProjects[_projectId].projectLead, "Only project lead can assign agents");
        require(aiAgents[_agentId].exists, "AI Agent does not exist");

        // Logic to formally assign, e.g., mapping project-task to agent.
        // For simplicity, this function primarily sets up the intent for `submitAIDataRequest`.
        emit AIAgentAssigned(_projectId, _agentId, _taskDescription);
    }

    /// @notice Requests AI processing via Chainlink, sending a prompt/input for the assigned agent.
    /// @param _projectId The ID of the project this request is for.
    /// @param _agentId The ID of the AI agent involved.
    /// @param _prompt The prompt or input data for the AI model.
    function submitAIDataRequest(
        uint256 _projectId,
        uint256 _agentId,
        string memory _prompt
    ) public payable whenNotPaused returns (bytes32 requestId) {
        require(researchProjects[_projectId].exists, "Project does not exist");
        require(aiAgents[_agentId].exists, "AI Agent does not exist");
        require(address(link) != address(0), "Link token address not set");
        require(address(oracle) != address(0), "Oracle address not set");
        require(aiDataFeedJobId != bytes32(0), "AI Data Feed Job ID not set");

        Chainlink.Request memory req = buildChainlinkRequest(aiDataFeedJobId, address(this), this.fulfillAIDataRequest.selector);
        req.add("prompt", _prompt);
        // In a real scenario, you might add more params specific to the AI agent or task
        // req.addUint("agentId", _agentId);

        // Cost of request from Chainlink (LINK token)
        requestId = sendChainlinkRequest(req, (1 * 10**18)); // Example LINK payment

        requestIdToRequestDetails[requestId] = RequestDetails({
            projectId: _projectId,
            agentId: _agentId,
            caller: msg.sender
        });

        emit AIDataRequestSent(requestId, _projectId, _agentId, _prompt);
        return requestId;
    }

    /// @notice Chainlink callback function to receive and process results from off-chain AI computation.
    /// @param _requestId The ID of the Chainlink request.
    /// @param _result The array of strings containing the AI processing results.
    function fulfillAIDataRequest(
        bytes32 _requestId,
        string[] memory _result
    ) public recordChainlinkFulfillment(_requestId) {
        RequestDetails memory details = requestIdToRequestDetails[_requestId];
        require(details.projectId != 0, "Invalid Chainlink request ID"); // Check if request ID exists and is valid

        // Example: Parse _result. Let's say _result[0] is "success" or "failure" and _result[1] is a confidence score.
        // For simplicity, we just assume success and update performance.
        if (_result.length > 0 && keccak256(abi.encodePacked(_result[0])) == keccak256(abi.encodePacked("success"))) {
            evaluateAIAgentPerformance(details.agentId, _result);
        } else {
            // Handle failure scenario, e.g., log, reduce reputation of agent owner
            emit AIDataRequestFailed(_requestId, _result);
        }
        delete requestIdToRequestDetails[_requestId]; // Clear request details
        emit AIDataFulfilled(_requestId, _result);
    }

    /// @notice Internal function called by `fulfillAIDataRequest` to update an AI agent's performance score based on results.
    /// @param _agentId The ID of the AI agent.
    /// @param _results The array of strings containing the AI processing results.
    function evaluateAIAgentPerformance(
        uint256 _agentId,
        string[] memory _results
    ) internal {
        AIAgent storage agent = aiAgents[_agentId];
        require(agent.exists, "AI Agent does not exist for evaluation");

        // Example logic: If results indicate success, increase score.
        // In a real-world scenario, this parsing would be more complex,
        // using numerical results or specific keywords.
        if (_results.length > 0 && keccak256(abi.encodePacked(_results[0])) == keccak256(abi.encodePacked("success"))) {
            agent.performanceScore += 10; // Arbitrary score increase
            _accrueReputation(agent.owner, 5); // Agent owner gains reputation for good performance
        } else {
            // Maybe decrease score or reputation on failure.
            if (agent.performanceScore >= 2) {
                agent.performanceScore -= 2;
            }
        }
        emit AIAgentPerformanceUpdated(_agentId, agent.performanceScore);
    }

    /// @notice Simulates an AI agent undergoing "training," potentially costing reputation or requiring proof.
    /// @param _agentId The ID of the AI agent to train.
    /// @param _reputationCost The amount of reputation to burn for training.
    function trainAIAgent(uint256 _agentId, uint256 _reputationCost) external whenNotPaused {
        AIAgent storage agent = aiAgents[_agentId];
        require(agent.exists, "AI Agent does not exist");
        require(msg.sender == agent.owner, "Only AI agent owner can train it");
        require(reputationScores[msg.sender] >= _reputationCost, "Insufficient reputation for training");

        reputationScores[msg.sender] -= _reputationCost;
        agent.performanceScore += _reputationCost / 10; // Training increases performance, scaled by cost
        emit AIAgentTrained(_agentId, msg.sender, _reputationCost, agent.performanceScore);
        emit ReputationBurned(msg.sender, _reputationCost);
    }

    /// @notice View function to retrieve the current performance score of an AI agent.
    /// @param _agentId The ID of the AI agent.
    /// @return The current performance score.
    function getAIAgentPerformanceMetric(uint256 _agentId) external view returns (uint256) {
        require(aiAgents[_agentId].exists, "AI Agent does not exist");
        return aiAgents[_agentId].performanceScore;
    }

    // --- Reputation System ---

    /// @notice Internal function to increase an account's reputation score.
    /// @param _account The address whose reputation to increase.
    /// @param _amount The amount of reputation to add.
    function _accrueReputation(address _account, uint256 _amount) internal {
        reputationScores[_account] += _amount;
        emit ReputationAccrued(_account, _amount);
    }

    /// @notice Allows a user to delegate a portion of their reputation to another address for voting power.
    /// @param _delegatee The address to delegate reputation to.
    /// @param _amount The amount of reputation to delegate.
    function delegateReputation(address _delegatee, uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Cannot delegate zero reputation");
        require(reputationScores[msg.sender] >= _amount, "Insufficient reputation to delegate");
        require(msg.sender != _delegatee, "Cannot delegate to yourself");

        // Undelegate any existing delegation first if a different delegatee
        if (delegatedReputation[msg.sender] != address(0) && delegatedReputation[msg.sender] != _delegatee) {
            reputationScores[delegatedReputation[msg.sender]] -= delegatedAmount[msg.sender];
        }

        delegatedReputation[msg.sender] = _delegatee;
        delegatedAmount[msg.sender] = _amount;
        reputationScores[_delegatee] += _amount; // Delegatee's effective reputation increases
        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    /// @notice Allows a user to revoke all their active reputation delegations.
    function undelegateReputation() external whenNotPaused {
        address currentDelegatee = delegatedReputation[msg.sender];
        uint256 currentDelegatedAmount = delegatedAmount[msg.sender];

        if (currentDelegatee != address(0)) {
            reputationScores[currentDelegatee] -= currentDelegatedAmount;
            delete delegatedReputation[msg.sender];
            delete delegatedAmount[msg.sender];
            emit ReputationUndelegated(msg.sender);
        }
    }

    // --- Governance ---

    /// @notice Allows reputation holders to propose on-chain actions or policy changes.
    /// @param _description A description of the proposal.
    /// @param _target The target address for the proposal's execution (e.g., this contract).
    /// @param _calldata The calldata to be executed if the proposal passes.
    /// @return The ID of the newly created proposal.
    function submitGovernanceProposal(
        string memory _description,
        address _target,
        bytes memory _calldata
    ) external whenNotPaused returns (uint256) {
        require(reputationScores[msg.sender] > 0, "No reputation to submit proposal"); // Simple check

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            target: _target,
            calldataBytes: _calldata,
            yesVotes: 0,
            noVotes: 0,
            creationTime: block.timestamp,
            executed: false
        });
        emit ProposalSubmitted(proposalId, _description, _target, _calldata);
        return proposalId;
    }

    /// @notice Allows reputation holders (or their delegates) to vote on open governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes' vote, false for 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        require(reputationScores[msg.sender] > 0, "You need reputation to vote");

        hasVoted[_proposalId][msg.sender] = true;
        uint256 voteWeight = reputationScores[msg.sender];

        if (_support) {
            proposal.yesVotes += voteWeight;
        } else {
            proposal.noVotes += voteWeight;
        }
        emit Voted(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @notice Conceptual function for users to claim a Soulbound Token (SBT)-like badge representing their reputation tier.
    ///         This function would typically interact with a separate SBT contract.
    /// @param _tier The reputation tier for which to claim the badge.
    function claimReputationBadge(uint256 _tier) external view {
        // This is a placeholder. In a real scenario, it would:
        // 1. Check if msg.sender's reputationScores[msg.sender] meets the requirement for _tier.
        // 2. Interact with an external SBT contract (e.g., `ISoulboundToken(sbtAddress).mint(_tier, msg.sender);`).
        // For this example, it's just a conceptual placeholder to highlight the SBT integration idea.
        require(reputationScores[msg.sender] >= _tier * 1000, "Reputation not high enough for this tier");
        revert("SBT integration is conceptual and not implemented in this contract.");
    }

    // --- Treasury & Utility ---

    /// @notice Admin function to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        // Withdraw ETH fees
        uint256 ethFees = totalEthFeesCollected;
        if (ethFees > 0) {
            totalEthFeesCollected = 0;
            (bool success, ) = msg.sender.call{value: ethFees}("");
            require(success, "Failed to withdraw ETH fees");
        }

        // Withdraw ERC20 fees (iterating over collected tokens is not direct in Solidity mapping)
        // For a full implementation, you'd need a list of ERC20 tokens that have accumulated fees,
        // or iterate through a known set. For this example, we'll just show the concept.
        // As a work around, you would need to specify which ERC20 token to withdraw.
        // mapping(address => uint256) public totalErc20FeesCollected;

        // Example for a specific ERC20 token (needs to be generalized in a full system)
        // IERC20 token = IERC20(erc20_token_address);
        // uint256 erc20Fees = totalErc20FeesCollected[address(token)];
        // if (erc20Fees > 0) {
        //     totalErc20FeesCollected[address(token)] = 0;
        //     token.transfer(msg.sender, erc20Fees);
        // }

        // Emit event with placeholder for ERC20 amounts
        emit ProtocolFeesWithdrawn(msg.sender, ethFees, totalErc20FeesCollected);
    }

    /// @notice Allows a user to voluntarily burn a specified amount of their own reputation score.
    /// @param _amount The amount of reputation to burn.
    function burnReputation(uint256 _amount) external whenNotPaused {
        require(reputationScores[msg.sender] >= _amount, "Insufficient reputation to burn");
        reputationScores[msg.sender] -= _amount;
        emit ReputationBurned(msg.sender, _amount);
    }

    // --- Fallback & Receive ---

    // Allows the contract to receive ETH for funding projects (when _erc20Token is address(0))
    receive() external payable {}

    // --- Private/Internal Helpers ---
    // (No additional complex helpers needed beyond what OpenZeppelin and Chainlink provide for this scope)

    // --- Events not included in summary (for completeness) ---
    event ResearchProjectMetadataUpdated(uint256 indexed projectId, string newURI);
    event MilestoneRequestedVerification(uint256 indexed projectId, uint256 indexed milestoneId);
    event AIDataRequestFailed(bytes32 indexed requestId, string[] result);
    event AIAgentTrained(uint256 indexed agentId, address indexed trainer, uint256 reputationCost, uint256 newPerformanceScore);
}
```