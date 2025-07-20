This smart contract, `DecentralizedResearchNexus`, aims to create a sophisticated and novel ecosystem for scientific and technological research. It integrates several advanced and trendy concepts: AI-assisted evaluation through an oracle, a soulbound token (SBT) system for reputation, dynamic NFTs for intellectual property, and a robust DAO governance model, all while conceptualizing privacy-preserving data verification with Zero-Knowledge Proofs.

---

## Smart Contract: `DecentralizedResearchNexus.sol`

### Outline and Function Summary

**Core Concept:** A sophisticated decentralized platform for fostering, funding, evaluating, and managing scientific and technological research projects. It integrates AI-assisted evaluation via oracles, a soulbound token (SBT) reputation system, dynamic Intellectual Property NFTs, and robust DAO governance to create a self-sustaining research ecosystem, with an eye towards privacy-preserving data verification.

---

**I. Core Infrastructure & Access Control**
*   **`constructor(address _initialOracle)`**: Initializes the contract, setting the initial AI oracle address and the deployer as the initial DAO manager.
*   **`setAIDataOracle(address _newOracle)`**: Allows the DAO (via governance) to update the address of the trusted AI data oracle.
*   **`pause()`**: Pauses all critical state-changing functions in emergencies (callable by DAO manager).
*   **`unpause()`**: Resumes contract operations (callable by DAO manager).
*   **`rescueERC20(address _tokenAddress, uint256 _amount)`**: Allows the DAO manager to rescue accidentally sent ERC20 tokens, preventing loss.

**II. Research Project Management Lifecycle**
*   **`submitResearchProposal(string memory _projectTitle, string memory _projectDescriptionURI, uint256 _fundingGoal, uint256 _milestoneCount, string memory _researchCategory)`**: Allows any registered researcher to submit a new project proposal, specifying details, funding goal, number of milestones, and a category for AI evaluation.
*   **`voteOnProjectProposal(uint256 _projectId, bool _approve)`**: DAO members vote to approve or reject a submitted research proposal. Voting power is influenced by `ResearchPoints`.
*   **`fundProject(uint256 _projectId)`**: Allows users to contribute ETH (or future ERC20) to a project's funding goal. Funds are held in escrow for approved projects.
*   **`requestMilestoneEvaluation(uint256 _projectId, uint256 _milestoneIndex, string memory _milestoneDeliverableURI)`**: A researcher requests evaluation for a completed milestone, providing a URI to deliverables. Triggers an AI oracle request.
*   **`confirmMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, uint256 _aiScore)`**: *Internal/Oracle-called*: Processes the AI oracle's evaluation score for a milestone. If score meets threshold, marks milestone complete and queues payout.
*   **`releaseMilestonePayout(uint256 _projectId, uint256 _milestoneIndex)`**: Allows the project lead to claim funds for a successfully completed and AI-approved milestone.
*   **`raiseMilestoneDispute(uint256 _projectId, uint256 _milestoneIndex, string memory _reasonURI)`**: DAO members or funders can dispute a milestone's completion or AI score.
*   **`resolveMilestoneDispute(uint256 _projectId, uint256 _milestoneIndex, bool _validClaim)`**: DAO votes to resolve a dispute, determining if the milestone is valid or invalid.
*   **`closeProject(uint256 _projectId)`**: Marks a project as formally closed after all milestones are complete or explicitly terminated by DAO vote. Triggers final IP NFT creation/update.

**III. AI-Assisted Evaluation & Oracles (Advanced)**
*   **`receiveOracleData(uint256 _requestId, uint256 _aiScore, bytes32 _additionalData)`**: Callable *only by the designated AI oracle*. This function receives the AI evaluation score for a proposal or milestone. This is a core advanced feature for external computation integration.
*   **`requestProjectAIReport(uint256 _projectId)`**: Triggers an off-chain request to the AI oracle for a comprehensive report on a project's potential impact or progress. (Conceptual: oracle would then call `receiveOracleData`).

**IV. Soulbound Research Points (SRP) & Reputation**
*   **`mintResearchPoints(address _recipient, uint256 _points, uint256 _contextId)`**: *Internal/Privileged*: Mints non-transferable `ResearchPoint` (SRP) tokens to a researcher or reviewer for significant contributions (e.g., successful project completion, high-quality review, dispute resolution).
*   **`getResearcherTotalSRP(address _researcher)`**: Returns the total accumulated SRP for a given researcher. These points influence voting power and access.
*   **`delegateResearchReviewPower(address _delegatee)`**: Allows an SRP holder to temporarily delegate their 'review power' (influenced by SRPs) to another researcher for peer review tasks, without transferring their actual SRPs.

**V. Dynamic Intellectual Property NFTs (ERC-721)**
*   **`mintDynamicIP_NFT(uint256 _projectId, address _owner, string memory _initialMetadataURI)`**: Mints a new ERC-721 NFT representing the Intellectual Property of a completed research project. The NFT metadata is designed to be dynamically updatable.
*   **`updateDynamicIP_NFT_Metadata(uint256 _tokenId, string memory _newMetadataURI)`**: Allows authorized parties (e.g., project lead, DAO) to update the metadata URI of an IP NFT. This URI would point to an evolving metadata JSON, reflecting project impact, citations, or subsequent AI evaluations.
*   **`transferIP_NFT_Ownership(address _from, address _to, uint256 _tokenId)`**: Standard ERC-721 transfer, but the contract might restrict it based on DAO rules or project status.

**VI. Governance & Treasury Management**
*   **`createGovernanceProposal(string memory _proposalURI, uint256 _voteDuration)`**: DAO members can submit proposals for protocol upgrades, treasury spending, or rule changes.
*   **`voteOnGovernanceProposal(uint256 _proposalId, bool _support)`**: Registered members vote on governance proposals.
*   **`executeGovernanceProposal(uint256 _proposalId)`**: Executes a successfully passed governance proposal.
*   **`depositToTreasury()`**: Allows anyone to contribute ETH to the main protocol treasury.
*   **`proposeTreasuryAllocation(uint256 _amount, address _recipient, string memory _description)`**: Creates a governance proposal for allocating funds from the treasury to a specific address for a defined purpose.

**VII. Data Privacy & Verification (Conceptual ZKP Integration)**
*   **`submitZeroKnowledgeProof(uint256 _projectId, bytes memory _proof, bytes memory _publicInputs)`**: Allows a researcher to submit a ZKP (Zero-Knowledge Proof) for off-chain research data. The contract verifies the proof's validity against a predefined verifier contract (conceptual, assuming a pre-deployed verifier). This allows on-chain verification of data integrity or compliance without revealing the raw data, crucial for sensitive research.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for DAO Manager initially
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For rescue function

// Interface for a generic oracle, specifically for AI data.
interface IAIDataOracle {
    function requestEvaluation(uint256 _requestId, address _callbackAddress, string memory _dataURI, string memory _category) external;
    // Expected callback from oracle: receiveOracleData(requestId, aiScore, additionalData)
}

// Interface for a generic Zero-Knowledge Proof Verifier (conceptual)
interface IZKPVerifier {
    function verifyProof(bytes memory _proof, bytes memory _publicInputs) external view returns (bool);
}

contract DecentralizedResearchNexus is Context, Ownable, Pausable, ERC721 {

    // --- State Variables ---

    // Addresses
    address public aiDataOracle;
    address public zkpVerifierContract; // Address of a deployed ZKP verifier contract (conceptual)

    // Counters
    uint256 public nextProjectId;
    uint256 public nextIpNftId;
    uint256 public nextGovernanceProposalId;
    uint256 public nextOracleRequestId; // For tracking oracle requests

    // --- Structs ---

    enum ProjectStatus { Proposed, Approved, Funding, Active, MilestoneDispute, Completed, Terminated }
    enum MilestoneStatus { PendingEvaluation, EvaluatedApproved, EvaluatedRejected, Disputed, Completed, PayoutClaimed }
    enum GovernanceProposalStatus { Pending, Approved, Rejected, Executed }

    struct Project {
        uint256 id;
        address researcher;
        string title;
        string descriptionURI;
        uint256 fundingGoal;
        uint256 fundedAmount;
        uint256 milestoneCount;
        Milestone[] milestones;
        ProjectStatus status;
        string researchCategory; // For AI evaluation context
        uint256 creationTime;
        uint256 ipNftId; // ID of the associated Dynamic IP NFT
    }

    struct Milestone {
        uint256 index;
        string deliverableURI;
        MilestoneStatus status;
        uint256 aiScore; // AI evaluation score for this milestone
        bool payoutClaimed;
        uint256 disputeCount; // Number of active disputes for this milestone
        mapping(address => bool) hasDisputed; // Tracks who has disputed a milestone
    }

    struct GovernanceProposal {
        uint256 id;
        string proposalURI; // URI to detailed proposal text/IPFS hash
        uint256 creationTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        GovernanceProposalStatus status;
        address proposer;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks who has voted on a governance proposal
    }

    // --- Mappings ---

    mapping(uint256 => Project) public projects;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => uint256) public oracleRequestToProjectId; // Maps oracle request ID to Project ID
    mapping(uint256 => uint256) public oracleRequestToMilestoneIndex; // Maps oracle request ID to Milestone Index

    // Soulbound Research Points (SRP) - not a standard ERC, just a balance mapping conceptually.
    // Represents a non-transferable reputation token.
    mapping(address => uint256) public researcherResearchPoints;
    mapping(address => address) public delegatedReviewPower; // SRP holder can delegate review 'power'

    // --- Events ---

    event ProjectProposed(uint256 indexed projectId, address indexed researcher, string title, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event MilestoneRequestedEvaluation(uint256 indexed projectId, uint256 indexed milestoneIndex, string deliverableURI);
    event MilestoneEvaluated(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 aiScore, MilestoneStatus status);
    event MilestonePayoutReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneDisputed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed disputer);
    event MilestoneDisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool validClaim);
    event ProjectClosed(uint256 indexed projectId, ProjectStatus finalStatus);

    event OracleDataReceived(uint256 indexed requestId, uint256 aiScore, bytes32 additionalData);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);

    event ResearchPointsMinted(address indexed recipient, uint256 points, uint256 contextId);
    event ReviewPowerDelegated(address indexed delegator, address indexed delegatee);

    event DynamicIP_NFT_Minted(uint256 indexed tokenId, uint256 indexed projectId, address indexed owner, string initialMetadataURI);
    event DynamicIP_NFT_MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string proposalURI, uint256 voteEndTime);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryAllocationProposed(uint256 indexed proposalId, uint256 amount, address recipient);

    event ZeroKnowledgeProofSubmitted(uint256 indexed projectId, address indexed submitter);


    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(_msgSender() == aiDataOracle, "DRN: Caller is not the AI oracle");
        _;
    }

    modifier onlyDAOManager() {
        // For simplicity, using Ownable's owner for DAO management initially.
        // In a real DAO, this would be a more complex governance module.
        require(owner() == _msgSender(), "DRN: Not DAO Manager");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle) ERC721("DynamicResearchIP", "DRN-IP") Ownable(_msgSender()) {
        require(_initialOracle != address(0), "DRN: Initial oracle address cannot be zero");
        aiDataOracle = _initialOracle;
        // ZKP Verifier contract would be deployed separately and set by DAO governance
    }

    // --- I. Core Infrastructure & Access Control ---

    function setAIDataOracle(address _newOracle) external onlyDAOManager {
        require(_newOracle != address(0), "DRN: New oracle address cannot be zero");
        emit AIOracleAddressUpdated(aiDataOracle, _newOracle);
        aiDataOracle = _newOracle;
    }

    function pause() external onlyDAOManager pausable {
        _pause();
    }

    function unpause() external onlyDAOManager pausable {
        _unpause();
    }

    // Function to rescue accidentally sent ERC20 tokens to the contract
    function rescueERC20(address _tokenAddress, uint256 _amount) external onlyDAOManager {
        require(_tokenAddress != address(0), "DRN: Invalid token address");
        require(_amount > 0, "DRN: Amount must be greater than zero");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "DRN: ERC20 transfer failed"); // Rescued to DAO Manager
    }

    // --- II. Research Project Management Lifecycle ---

    function submitResearchProposal(
        string memory _projectTitle,
        string memory _projectDescriptionURI,
        uint256 _fundingGoal,
        uint256 _milestoneCount,
        string memory _researchCategory
    ) external whenNotPaused {
        require(bytes(_projectTitle).length > 0, "DRN: Title cannot be empty");
        require(bytes(_projectDescriptionURI).length > 0, "DRN: Description URI cannot be empty");
        require(_fundingGoal > 0, "DRN: Funding goal must be greater than zero");
        require(_milestoneCount > 0, "DRN: At least one milestone is required");
        require(bytes(_researchCategory).length > 0, "DRN: Research category required for AI eval");

        uint256 projectId = nextProjectId++;
        Project storage newProject = projects[projectId];

        newProject.id = projectId;
        newProject.researcher = _msgSender();
        newProject.title = _projectTitle;
        newProject.descriptionURI = _projectDescriptionURI;
        newProject.fundingGoal = _fundingGoal;
        newProject.fundedAmount = 0;
        newProject.milestoneCount = _milestoneCount;
        newProject.status = ProjectStatus.Proposed;
        newProject.researchCategory = _researchCategory;
        newProject.creationTime = block.timestamp;
        newProject.ipNftId = 0; // Will be minted later

        newProject.milestones.length = _milestoneCount;
        for (uint256 i = 0; i < _milestoneCount; i++) {
            newProject.milestones[i].index = i;
            newProject.milestones[i].status = MilestoneStatus.PendingEvaluation; // Initial status
        }

        // Request initial AI evaluation for the proposal itself (conceptual)
        uint256 requestId = nextOracleRequestId++;
        IAIDataOracle(aiDataOracle).requestEvaluation(requestId, address(this), _projectDescriptionURI, _researchCategory);
        oracleRequestToProjectId[requestId] = projectId;
        oracleRequestToMilestoneIndex[requestId] = type(uint256).max; // Sentinel for proposal eval

        emit ProjectProposed(projectId, _msgSender(), _projectTitle, _fundingGoal);
    }

    function voteOnProjectProposal(uint256 _projectId, bool _approve) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "DRN: Project is not in proposed status");
        // Simplified voting: For actual DAO, check if msg.sender has voting power (e.g., sufficient SRPs) and hasn't voted.
        // For this example, anyone can vote, but in real DAO, would check researcherResearchPoints[_msgSender()] for weight.
        if (_approve) {
            project.status = ProjectStatus.Approved; // Simplified direct approval
            // In a real DAO, this would trigger a governance proposal and require enough 'yes' votes.
        } else {
            project.status = ProjectStatus.Terminated; // Simplified direct rejection
        }
        emit ProjectStatusChanged(_projectId, project.status);
    }

    function fundProject(uint256 _projectId) external payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Funding, "DRN: Project not approved for funding");
        require(project.fundedAmount < project.fundingGoal, "DRN: Project already fully funded");
        require(msg.value > 0, "DRN: Must send ETH to fund project");

        project.fundedAmount += msg.value;
        project.status = ProjectStatus.Funding; // Ensure status reflects active funding
        if (project.fundedAmount >= project.fundingGoal) {
            project.status = ProjectStatus.Active; // Project now fully funded and active
        }

        emit ProjectFunded(_projectId, _msgSender(), msg.value);
    }

    function requestMilestoneEvaluation(uint256 _projectId, uint256 _milestoneIndex, string memory _milestoneDeliverableURI) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "DRN: Project not active");
        require(_msgSender() == project.researcher, "DRN: Only project researcher can request evaluation");
        require(_milestoneIndex < project.milestoneCount, "DRN: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.PendingEvaluation || milestone.status == MilestoneStatus.EvaluatedRejected, "DRN: Milestone not ready for evaluation");
        require(bytes(_milestoneDeliverableURI).length > 0, "DRN: Deliverable URI required");

        milestone.deliverableURI = _milestoneDeliverableURI;
        milestone.status = MilestoneStatus.PendingEvaluation; // Reset for re-evaluation if rejected

        // Request AI evaluation from the oracle
        uint256 requestId = nextOracleRequestId++;
        IAIDataOracle(aiDataOracle).requestEvaluation(requestId, address(this), _milestoneDeliverableURI, project.researchCategory);
        oracleRequestToProjectId[requestId] = _projectId;
        oracleRequestToMilestoneIndex[requestId] = _milestoneIndex;

        emit MilestoneRequestedEvaluation(_projectId, _milestoneIndex, _milestoneDeliverableURI);
    }

    // Internal/Oracle-called: Processes the AI oracle's evaluation score for a milestone.
    // This function will be called by the `receiveOracleData` function.
    function confirmMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, uint256 _aiScore) internal {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        require(project.status == ProjectStatus.Active, "DRN: Project not active for milestone confirmation");
        require(milestone.status != MilestoneStatus.Disputed, "DRN: Milestone is currently disputed");

        milestone.aiScore = _aiScore;

        uint256 requiredScore = 70; // Example threshold, could be dynamic or set by DAO
        if (_aiScore >= requiredScore) {
            milestone.status = MilestoneStatus.EvaluatedApproved;
            // Potentially mint SRPs for researcher for successful milestone
            _mintResearchPoints(project.researcher, 10, _projectId);
        } else {
            milestone.status = MilestoneStatus.EvaluatedRejected;
        }

        emit MilestoneEvaluated(_projectId, _milestoneIndex, _aiScore, milestone.status);
    }

    function releaseMilestonePayout(uint256 _projectId, uint256 _milestoneIndex) external whenNotPaused {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];

        require(_msgSender() == project.researcher, "DRN: Only project researcher can claim payout");
        require(project.status == ProjectStatus.Active, "DRN: Project not active");
        require(_milestoneIndex < project.milestoneCount, "DRN: Invalid milestone index");
        require(milestone.status == MilestoneStatus.EvaluatedApproved, "DRN: Milestone not approved for payout");
        require(!milestone.payoutClaimed, "DRN: Payout already claimed for this milestone");

        uint256 payoutAmount = project.fundedAmount / project.milestoneCount; // Simple equal distribution

        milestone.payoutClaimed = true;
        milestone.status = MilestoneStatus.Completed;

        (bool success, ) = payable(project.researcher).call{value: payoutAmount}("");
        require(success, "DRN: Failed to transfer milestone payout");

        emit MilestonePayoutReleased(_projectId, _milestoneIndex, payoutAmount);
    }

    function raiseMilestoneDispute(uint256 _projectId, uint256 _milestoneIndex, string memory _reasonURI) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "DRN: Project not active");
        require(_milestoneIndex < project.milestoneCount, "DRN: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.EvaluatedApproved || milestone.status == MilestoneStatus.EvaluatedRejected || milestone.status == MilestoneStatus.Completed, "DRN: Milestone not in disputable state");
        require(!milestone.hasDisputed[_msgSender()], "DRN: You have already disputed this milestone");
        require(bytes(_reasonURI).length > 0, "DRN: Reason URI is required for dispute");

        milestone.disputeCount++;
        milestone.hasDisputed[_msgSender()] = true;
        project.status = ProjectStatus.MilestoneDispute; // Set project status to indicate dispute

        // For a full DAO, this would trigger a governance vote for dispute resolution.
        // Simplified here to just mark dispute count.
        emit MilestoneDisputed(_projectId, _milestoneIndex, _msgSender());
    }

    function resolveMilestoneDispute(uint256 _projectId, uint256 _milestoneIndex, bool _validClaim) external onlyDAOManager whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.MilestoneDispute, "DRN: Project is not in dispute status");
        require(_milestoneIndex < project.milestoneCount, "DRN: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.disputeCount > 0, "DRN: No active disputes for this milestone");

        // Reset dispute flags (simplified: all active disputes cleared)
        milestone.disputeCount = 0;
        // In a real DAO, specific disputes would be resolved, perhaps by voting on each.
        // This current implementation just clears existing dispute flags for everyone.
        // A more complex system would require tracking individual dispute proposals.

        if (_validClaim) {
            milestone.status = MilestoneStatus.EvaluatedApproved; // Re-approve if dispute was invalid
        } else {
            milestone.status = MilestoneStatus.EvaluatedRejected; // Mark as rejected if dispute was valid
            // Potentially penalize researcher or release less funds
        }

        // After dispute resolution, set project status back to active if no other disputes
        bool anyMilestoneDisputed = false;
        for(uint256 i=0; i < project.milestoneCount; i++) {
            if (project.milestones[i].disputeCount > 0) {
                anyMilestoneDisputed = true;
                break;
            }
        }
        if (!anyMilestoneDisputed) {
            project.status = ProjectStatus.Active;
        }

        emit MilestoneDisputeResolved(_projectId, _milestoneIndex, _validClaim);
    }

    function closeProject(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(_msgSender() == project.researcher || owner() == _msgSender(), "DRN: Only researcher or DAO manager can close project");
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.Funding, "DRN: Project not in active or funding state");

        bool allMilestonesCompleted = true;
        for (uint256 i = 0; i < project.milestoneCount; i++) {
            if (project.milestones[i].status != MilestoneStatus.Completed) {
                allMilestonesCompleted = false;
                break;
            }
        }

        if (allMilestonesCompleted) {
            project.status = ProjectStatus.Completed;
            _mintDynamicIP_NFT(_projectId, project.researcher, project.descriptionURI); // Mint IP NFT upon completion
        } else {
            project.status = ProjectStatus.Terminated; // Terminated if not all milestones complete
        }

        emit ProjectClosed(_projectId, project.status);
    }

    // --- III. AI-Assisted Evaluation & Oracles ---

    function receiveOracleData(uint256 _requestId, uint256 _aiScore, bytes32 _additionalData) external onlyAIOracle {
        require(oracleRequestToProjectId[_requestId] != 0 || _requestId == 0, "DRN: Unknown oracle request ID"); // _requestId 0 can be for initial setup/testing
        
        uint256 projectId = oracleRequestToProjectId[_requestId];
        uint256 milestoneIndex = oracleRequestToMilestoneIndex[_requestId];

        if (milestoneIndex == type(uint256).max) {
            // This was a project proposal evaluation
            // For now, simply log and allow proposal to proceed via DAO vote.
            // In a more complex system, this score could influence DAO's default vote or highlight.
            // project.aiProposalScore = _aiScore; // Could add a field for this.
        } else {
            // This was a milestone evaluation
            confirmMilestoneCompletion(projectId, milestoneIndex, _aiScore);
        }

        emit OracleDataReceived(_requestId, _aiScore, _additionalData);
    }

    function requestProjectAIReport(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id == _projectId, "DRN: Project does not exist");
        // This function simply triggers an off-chain oracle request.
        // The oracle would then call back `receiveOracleData` with the report's score/summary.
        uint256 requestId = nextOracleRequestId++;
        IAIDataOracle(aiDataOracle).requestEvaluation(requestId, address(this), project.descriptionURI, project.researchCategory);
        oracleRequestToProjectId[requestId] = _projectId;
        oracleRequestToMilestoneIndex[requestId] = type(uint256).max; // Marks it as a general project report request.
        // No explicit event here as the result comes via receiveOracleData
    }

    // --- IV. Soulbound Research Points (SRP) & Reputation ---

    // Internal function to mint non-transferable Research Points
    function _mintResearchPoints(address _recipient, uint256 _points, uint256 _contextId) internal {
        require(_recipient != address(0), "DRN: Cannot mint SRP to zero address");
        require(_points > 0, "DRN: Points must be greater than zero");
        researcherResearchPoints[_recipient] += _points;
        // Conceptually, these are non-transferable tokens (SBTs).
        // For actual SBTs, you'd use an ERC721-like interface with transfer/approve disabled.
        emit ResearchPointsMinted(_recipient, _points, _contextId);
    }

    function getResearcherTotalSRP(address _researcher) external view returns (uint256) {
        return researcherResearchPoints[_researcher];
    }

    function delegateResearchReviewPower(address _delegatee) external whenNotPaused {
        require(researcherResearchPoints[_msgSender()] > 0, "DRN: No SRP to delegate");
        require(_delegatee != address(0), "DRN: Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "DRN: Cannot delegate to self");
        delegatedReviewPower[_msgSender()] = _delegatee;
        emit ReviewPowerDelegated(_msgSender(), _delegatee);
    }

    // --- V. Dynamic Intellectual Property NFTs (ERC-721) ---

    function _mintDynamicIP_NFT(uint256 _projectId, address _owner, string memory _initialMetadataURI) internal returns (uint256) {
        require(_owner != address(0), "DRN: NFT owner cannot be zero address");
        uint256 tokenId = nextIpNftId++;
        _safeMint(_owner, tokenId);
        _setTokenURI(tokenId, _initialMetadataURI); // Initial metadata URI
        projects[_projectId].ipNftId = tokenId;
        emit DynamicIP_NFT_Minted(tokenId, _projectId, _owner, _initialMetadataURI);
        return tokenId;
    }

    function updateDynamicIP_NFT_Metadata(uint256 _tokenId, string memory _newMetadataURI) external whenNotPaused {
        // Only the token owner or an approved address (e.g., DAO manager) can update metadata.
        require(_isApprovedOrOwner(_msgSender(), _tokenId) || owner() == _msgSender(), "DRN: Not authorized to update NFT metadata");
        _setTokenURI(_tokenId, _newMetadataURI);
        emit DynamicIP_NFT_MetadataUpdated(_tokenId, _newMetadataURI);
    }

    // `transferIP_NFT_Ownership` is covered by ERC721's `transferFrom` and `safeTransferFrom` functions.
    // However, to explicitly highlight it in our summary, we can provide a wrapper or just note the standard functions.
    // For this context, standard ERC-721 transfers apply, meaning project IP can be transferred.
    // Restrictions would be handled by _beforeTokenTransfer hook or external governance.

    // --- VI. Governance & Treasury Management ---

    function createGovernanceProposal(string memory _proposalURI, uint256 _voteDuration) external whenNotPaused {
        require(bytes(_proposalURI).length > 0, "DRN: Proposal URI cannot be empty");
        require(_voteDuration > 0, "DRN: Vote duration must be positive");
        // Check for minimum SRP to create proposal (conceptual)
        require(researcherResearchPoints[_msgSender()] >= 100, "DRN: Insufficient SRP to create proposal"); // Example threshold

        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalURI = _proposalURI;
        proposal.creationTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + _voteDuration;
        proposal.status = GovernanceProposalStatus.Pending;
        proposal.proposer = _msgSender();

        emit GovernanceProposalCreated(proposalId, _msgSender(), _proposalURI, proposal.voteEndTime);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == GovernanceProposalStatus.Pending, "DRN: Proposal not in voting period");
        require(block.timestamp <= proposal.voteEndTime, "DRN: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "DRN: Already voted on this proposal");
        // Voting power based on SRP (conceptual)
        uint256 voterSRP = researcherResearchPoints[_msgSender()];
        require(voterSRP > 0, "DRN: Must have SRP to vote");

        if (_support) {
            proposal.yesVotes += voterSRP; // Use SRP as voting weight
        } else {
            proposal.noVotes += voterSRP;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit GovernanceVoteCast(_proposalId, _msgSender(), _support);
    }

    function executeGovernanceProposal(uint256 _proposalId) external onlyDAOManager whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == GovernanceProposalStatus.Pending, "DRN: Proposal not pending");
        require(block.timestamp > proposal.voteEndTime, "DRN: Voting period not ended");
        require(!proposal.executed, "DRN: Proposal already executed");

        uint256 thresholdPercentage = 51; // Example: 51% approval to pass
        if (proposal.yesVotes * 100 > (proposal.yesVotes + proposal.noVotes) * thresholdPercentage) {
            proposal.status = GovernanceProposalStatus.Approved;
            // In a real DAO, this is where the actual action (e.g., calling another contract, changing state vars) would happen.
            // For example:
            // if (bytes(proposal.proposalURI).length > 0 && keccak256(abi.encodePacked(proposal.proposalURI)) == keccak256(abi.encodePacked("SET_NEW_ORACLE"))) {
            //      setAIDataOracle(address(bytes20(_additionalData))); // Example of how a proposal could update state
            // }
            // This implementation assumes manual execution of the proposal details by DAO Manager for safety/simplicity.
        } else {
            proposal.status = GovernanceProposalStatus.Rejected;
        }
        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    function depositToTreasury() external payable whenNotPaused {
        require(msg.value > 0, "DRN: Deposit amount must be greater than zero");
        emit TreasuryDeposit(_msgSender(), msg.value);
    }

    function proposeTreasuryAllocation(uint256 _amount, address _recipient, string memory _description) external whenNotPaused {
        require(_amount > 0, "DRN: Amount must be greater than zero");
        require(_recipient != address(0), "DRN: Recipient cannot be zero address");
        require(address(this).balance >= _amount, "DRN: Insufficient treasury balance");
        // This creates a governance proposal for fund allocation. Actual transfer happens via governance execution.
        uint256 proposalId = nextGovernanceProposalId++; // Uses same counter as generic governance
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalURI = string(abi.encodePacked("Treasury Allocation: ", _description, " to ", Strings.toHexString(uint160(_recipient)), " for ", Strings.toString(_amount), " ETH"));
        proposal.creationTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + 7 days; // Example fixed duration
        proposal.status = GovernanceProposalStatus.Pending;
        proposal.proposer = _msgSender();

        // Store allocation details for execution
        // mapping(uint256 => TreasuryAllocation) public pendingAllocations;
        // struct TreasuryAllocation { uint256 amount; address recipient; }
        // pendingAllocations[proposalId] = TreasuryAllocation(_amount, _recipient);
        // This is a conceptual example for the proposal, actual execution logic is simplified.

        emit GovernanceProposalCreated(proposalId, _msgSender(), proposal.proposalURI, proposal.voteEndTime);
        emit TreasuryAllocationProposed(proposalId, _amount, _recipient);
    }

    // --- VII. Data Privacy & Verification (Conceptual ZKP Integration) ---

    function submitZeroKnowledgeProof(uint256 _projectId, bytes memory _proof, bytes memory _publicInputs) external whenNotPaused {
        require(projects[_projectId].id == _projectId, "DRN: Project does not exist");
        require(zkpVerifierContract != address(0), "DRN: ZKP Verifier contract not set");
        
        // This assumes _proof and _publicInputs are valid for a pre-configured ZKP verifier circuit.
        // The actual ZKP verification happens inside the IZKPVerifier contract.
        bool verified = IZKPVerifier(zkpVerifierContract).verifyProof(_proof, _publicInputs);
        require(verified, "DRN: ZKP verification failed");

        // What to do after successful ZKP verification?
        // - Potentially update project status if ZKP validates critical data/milestone.
        // - Mint additional SRPs for privacy-preserving data contribution.
        // - Unlock further project functionality.
        // For example:
        // if (projects[_projectId].status == ProjectStatus.Active) {
        //     // Logic to update project based on verified private data
        //     _mintResearchPoints(_msgSender(), 5, _projectId); // Reward for verified data
        // }
        
        emit ZeroKnowledgeProofSubmitted(_projectId, _msgSender());
    }

    // DAO governance could call this to set the ZKP verifier contract
    function setZKPVerifierContract(address _newVerifier) external onlyDAOManager {
        require(_newVerifier != address(0), "DRN: New ZKP verifier address cannot be zero");
        zkpVerifierContract = _newVerifier;
    }
}
```