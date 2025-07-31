Here's a Solidity smart contract named `CognitoNexus`, designed to be an advanced, creative, and trendy platform for decentralized AI-powered research and innovation. It incorporates concepts like dynamic NFTs, AI oracle integration, reputation systems, and on-chain licensing of research output.

---

**Contract Name:** `CognitoNexus`

**Outline and Function Summary:**

**I. Core Infrastructure & Access Control**
1.  `constructor(address initialOwner)`: Initializes the contract with an owner.
2.  `renounceOwnership()`: (Inherited from `Ownable`) Relinquishes ownership of the contract.
3.  `transferOwnership(address newOwner)`: (Inherited from `Ownable`) Transfers ownership to a new address.
4.  `setOracleAddress(address _aiOracleAddress)`: Sets the address of the external AI Oracle contract responsible for evaluations.

**II. Project Management (Dynamic Project NFTs - ERC721)**
5.  `proposeResearchProject(string memory _title, string memory _proposalURI, uint256 _fundingRequested)`: Allows a researcher to submit a new project proposal, minting a unique ERC721 "Project NFT" that dynamically represents the project's journey.
6.  `updateProjectProgress(uint256 _projectId, uint256 _milestoneNumber)`: Enables the researcher to mark project milestones as complete, updating the Project NFT's metadata and potentially triggering AI progress evaluations.
7.  `submitFinalResearchOutput(uint256 _projectId, string memory _finalOutputURI)`: Allows the researcher to submit the final research output, changing the Project NFT's state and triggering a final AI validation.
8.  `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive details about a specific project and its current state.
9.  `pauseProject(uint256 _projectId)`: An administrative function to pause a project, for instance, due to misconduct or security concerns.

**III. AI Oracle Interaction & Evaluation**
10. `requestAIEvaluation(uint256 _projectId, uint256 _evaluationType)`: Initiates a request to the configured AI Oracle for evaluating a project (proposal, progress, or final output).
11. `receiveAIEvaluationCallback(uint256 _projectId, uint256 _score, uint256 _evaluationType)`: A callback function, callable only by the AI Oracle, to deliver evaluation results, which update project status and researcher reputation.

**IV. Funding & Grants Mechanism**
12. `depositFunds()`: Allows anyone to contribute Ether to the contract's public grant pool.
13. `requestGrantAllocation(uint256 _projectId, uint256 _amount)`: Researchers can request an allocation from their project's approved grant. Initial allocations can be auto-approved based on AI scores.
14. `_approveGrantAllocation(uint256 _projectId, uint256 _amount)`: (Internal) Handles the approval and allocation of funds to a project's dedicated balance.
15. `claimGrantFunds(uint256 _projectId)`: Allows a researcher to withdraw approved and allocated funds for their project.

**V. Researcher Reputation System (SBT-like)**
16. `getResearcherReputation(address _researcher)`: Queries the non-transferable reputation score of a given researcher.
17. `updateReputationScore(address _researcher, int256 _change)`: (Internal) Adjusts a researcher's reputation score based on project outcomes (e.g., successful completion, failed validation) or governance decisions.
18. `punishReputation(address _researcher, uint256 _amount)`: Allows the owner (or eventually governance) to reduce a researcher's reputation score for severe misconduct.

**VI. Licensable Research Output (Project NFTs become "Knowledge NFTs")**
19. `finalizeProjectAsKnowledge(uint256 _projectId, uint256 _royaltyPercentage)`: Transforms a successfully completed and AI-validated "Project NFT" into a "Knowledge NFT" by defining its on-chain licensing terms, making the original Project NFT directly licensable.
20. `acquireKnowledgeLicense(uint256 _projectId)`: Allows users to "acquire a license" for a finalized Knowledge NFT by paying a fee, which is then distributed as royalties to the researcher and to the community/admin pool.

**VII. Community Governance & Voting**
21. `submitGovernanceProposal(string memory _description, address _targetContract, bytes memory _callData, uint256 _votingPeriod)`: Allows users with sufficient reputation to propose significant changes or actions for the contract, including funding allocations or protocol upgrades.
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables reputation-holding community members to vote on active proposals, with their vote weight determined by their reputation score.
23. `executeProposal(uint256 _proposalId)`: Executes a governance proposal if the voting period has ended and it has passed with a majority of reputation-weighted votes.

**VIII. Utility & Emergency Functions**
24. `withdrawAdminFees(uint256 _amount)`: Allows the contract owner to withdraw a portion of the accumulated admin fees from licensing revenue.
25. `emergencyWithdrawFunds(address _to)`: A critical owner-only function to transfer all Ether from the contract to a designated safe address in case of an emergency.
26. `receive()`: A payable fallback function that allows direct Ether contributions to be added to the total grant pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString for dynamic URI updates

// Interface for a mock AI Oracle. In a real scenario, this would be a sophisticated oracle network
// (e.g., Chainlink external adapters for off-chain AI computation and on-chain verification).
interface IAIOracle {
    // Function to request an evaluation from the AI oracle.
    // projectId: The ID of the project to evaluate.
    // callbackContract: The address of the contract the oracle should call back.
    // evaluationType: 0 for proposal, 1 for progress, 2 for final output.
    function requestEvaluation(uint256 projectId, address callbackContract, uint256 evaluationType) external;
}

/**
 * @title CognitoNexus
 * @dev A Decentralized AI-Powered Research & Innovation Hub.
 *
 * This contract orchestrates a unique ecosystem for scientific research and innovation on-chain.
 * It integrates several advanced concepts:
 *
 * 1.  **Dynamic NFTs (Project NFTs):** Each research project is an ERC721 token whose metadata
 *     (represented by its `tokenURI`) dynamically updates based on its progress, AI evaluations,
 *     and eventual finalization into a "Knowledge NFT."
 * 2.  **AI Oracle Integration:** The contract interacts with an external AI oracle to
 *     evaluate research proposals, assess progress, and validate final outputs. This brings
 *     intelligent, external computation into the on-chain workflow.
 * 3.  **On-chain Reputation System (SBT-like):** Researchers accrue or lose reputation points
 *     based on the success or failure of their projects and AI evaluations. This reputation is
 *     non-transferable and influences voting power in governance.
 * 4.  **Decentralized Funding & Grants:** A community-funded grant pool supports research projects,
 *     with allocations potentially influenced by AI evaluations and community governance.
 * 5.  **Licensable Research Output ("Knowledge NFTs"):** Successful and validated research projects
 *     (Project NFTs) can be "finalized" as Knowledge NFTs, allowing their intellectual property
 *     to be licensed on-chain with defined royalty distributions.
 * 6.  **Community Governance:** A simple voting mechanism weighted by reputation allows the community
 *     to make collective decisions on protocol parameters, funding, or other key operations.
 *
 * This contract serves as a blueprint for a self-evolving, intelligent, and community-driven
 * research and development platform.
 */
contract CognitoNexus is Ownable, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _projectIdCounter;
    uint256 public constant MIN_REPUTATION_FOR_VOTING = 100; // Minimum reputation required to propose or vote
    uint256 public constant ADMIN_FEE_PERCENTAGE = 500; // 5% (500 basis points) of licensing revenue for admin/protocol

    address public aiOracleAddress; // Address of the external AI Oracle contract
    uint256 public totalGrantPool;  // Total Ether available in the grant pool

    // Project States: Defines the lifecycle of a research project
    enum ProjectState { Proposed, UnderReview, InProgress, AwaitingFinalEvaluation, Completed, Rejected, Paused }

    // Project Structure: Each instance represents a dynamic Project NFT (ERC721 token)
    struct Project {
        uint256 id; // Unique ID for the project (also its ERC721 token ID)
        address researcher; // Address of the project's creator
        string title; // Title of the research project
        string proposalURI; // IPFS URI for the initial detailed proposal document
        uint256 fundingRequested; // Total funding requested by the researcher in wei
        uint256 fundingAllocated; // Total funding actually allocated to the project in wei
        ProjectState state; // Current state of the project
        uint252 currentMilestone; // Tracks the highest completed milestone number
        uint256 aiEvaluationScore; // AI score for the initial proposal or latest progress (dynamic)
        mapping(uint256 => bool) milestoneCompleted; // Tracks individual milestone completion status
        uint256 finalOutputScore; // Final AI score for the completed research output
        string finalOutputURI; // URI for the final research output's metadata (becomes Knowledge NFT URI)
        bool isKnowledgeNFTLicensed; // True if this project's output has licensing terms defined
    }
    mapping(uint256 => Project) public projects; // Maps project ID to Project struct
    mapping(uint256 => uint256) public projectFundingBalances; // Funds specifically held for a project (ready for claiming)

    // Researcher Reputation: A non-transferable score tied to researcher's address (SBT-like)
    mapping(address => int256) public researcherReputation; // int256 allows for positive and negative scores

    // Project Licensing Terms: Stores licensing details for completed projects (Knowledge NFTs)
    struct ProjectLicensingTerms {
        uint256 royaltyPercentage; // Percentage of revenue paid to the researcher (e.g., 500 for 5%)
        mapping(address => bool) hasLicense; // Simplified: tracks if an address has acquired a license for this project
    }
    mapping(uint256 => ProjectLicensingTerms) public projectLicensingTerms; // projectId => licensing terms

    // Governance Proposal Structure
    struct Proposal {
        uint256 id; // Unique ID for the proposal
        address proposer; // Address of the proposal creator
        string description; // Description of the proposal
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Target contract for the execution (can be `address(this)`)
        bool executed; // True if the proposal has been executed
        uint256 deadline; // Timestamp when voting ends
        uint256 votesFor; // Sum of reputation scores of 'for' voters
        uint256 votesAgainst; // Sum of reputation scores of 'against' voters
        mapping(address => bool) hasVoted; // Tracks if an address has already voted on this proposal
    }
    Counters.Counter private _proposalIdCounter; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // Maps proposal ID to Proposal struct


    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed researcher, string title, uint256 fundingRequested);
    event ProjectStateUpdated(uint256 indexed projectId, ProjectState newState, string reason);
    event AIEvaluationRequested(uint256 indexed projectId, uint256 evaluationType);
    event AIEvaluationReceived(uint256 indexed projectId, uint256 score, uint256 evaluationType);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event GrantAllocated(uint256 indexed projectId, address indexed recipient, uint256 amount);
    event GrantClaimed(uint256 indexed projectId, address indexed recipient, uint256 amount);
    event ReputationUpdated(address indexed researcher, int256 newReputation);
    event ProjectFinalizedAsKnowledge(uint256 indexed projectId, address indexed creator, uint256 royaltyPercentage);
    event KnowledgeLicensed(uint256 indexed projectId, address indexed licensee, uint256 amount);
    event RevenueDistributed(uint256 indexed projectId, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleAddressSet(address indexed newOracleAddress);
    event AdminFeesWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @dev Constructor.
     * Initializes the contract, setting the initial owner.
     * @param initialOwner The address that will initially own the contract.
     */
    constructor(address initialOwner) ERC721("CognitoNexus Project NFT", "CNPNFT") Ownable(initialOwner) {
        // AI oracle address must be set separately by the owner after deployment.
    }

    // --- 1. Core Infrastructure & Access Control ---

    /**
     * @dev Sets the address of the AI Oracle contract.
     * This function is restricted to the contract owner.
     * @param _aiOracleAddress The address of the AI Oracle contract.
     */
    function setOracleAddress(address _aiOracleAddress) public onlyOwner {
        require(_aiOracleAddress != address(0), "Invalid address");
        aiOracleAddress = _aiOracleAddress;
        emit OracleAddressSet(_aiOracleAddress);
    }

    // --- 2. Project Management (Dynamic Project NFTs) ---

    /**
     * @dev Allows a researcher to propose a new research project.
     * A new Project NFT (ERC721) is minted for the researcher upon successful proposal.
     * The `_proposalURI` will serve as the initial `tokenURI` for the Project NFT.
     * @param _title The title of the research project.
     * @param _proposalURI An IPFS URI or similar, pointing to the detailed research proposal document.
     * @param _fundingRequested The total amount of funds (in wei) the researcher is requesting for the project.
     * @return The unique ID of the newly created project.
     */
    function proposeResearchProject(
        string memory _title,
        string memory _proposalURI,
        uint256 _fundingRequested
    ) public nonReentrant returns (uint256) {
        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        Project storage newProject = projects[newProjectId];
        newProject.id = newProjectId;
        newProject.researcher = msg.sender;
        newProject.title = _title;
        newProject.proposalURI = _proposalURI;
        newProject.fundingRequested = _fundingRequested;
        newProject.state = ProjectState.Proposed;
        newProject.currentMilestone = 0; // Projects start at milestone 0 (proposal phase)

        _safeMint(msg.sender, newProjectId); // Mint the ERC721 Project NFT
        _setTokenURI(newProjectId, _proposalURI); // Set initial NFT metadata URI

        emit ProjectProposed(newProjectId, msg.sender, _title, _fundingRequested);
        emit ProjectStateUpdated(newProjectId, ProjectState.Proposed, "New project proposed.");
        return newProjectId;
    }

    /**
     * @dev Allows the researcher to update the progress of their project by marking a milestone complete.
     * This action updates the Project NFT's state and dynamically changes its `tokenURI`
     * to reflect the new progress. It can also trigger an AI evaluation for this milestone.
     * @param _projectId The ID of the project to update.
     * @param _milestoneNumber The number of the milestone being completed. Must be greater than the current.
     */
    function updateProjectProgress(uint256 _projectId, uint256 _milestoneNumber) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "Only project researcher can update progress");
        require(project.state == ProjectState.InProgress, "Project not in InProgress state");
        require(_milestoneNumber > project.currentMilestone, "Milestone must be greater than current");
        require(!project.milestoneCompleted[_milestoneNumber], "Milestone already marked complete");

        project.currentMilestone = _milestoneNumber;
        project.milestoneCompleted[_milestoneNumber] = true;

        // Dynamically update Project NFT metadata URI to reflect new progress.
        // In a real application, `_setTokenURI` would point to an off-chain API
        // that generates dynamic JSON metadata based on the on-chain project state.
        string memory updatedURI = string(abi.encodePacked(project.proposalURI, "/progress/", Strings.toString(_milestoneNumber)));
        _setTokenURI(_projectId, updatedURI);

        // Optionally, request AI evaluation for this milestone if an oracle is configured.
        if (aiOracleAddress != address(0)) {
            IAIOracle(aiOracleAddress).requestEvaluation(_projectId, address(this), 1); // 1 for progress evaluation
            emit AIEvaluationRequested(_projectId, 1);
        }

        emit ProjectStateUpdated(_projectId, ProjectState.InProgress, string(abi.encodePacked("Milestone ", Strings.toString(_milestoneNumber), " completed.")));
    }

    /**
     * @dev Allows the researcher to submit the final output of their project for evaluation.
     * This transitions the project to an "AwaitingFinalEvaluation" state and updates
     * the Project NFT's `tokenURI` to point to the final output's metadata.
     * @param _projectId The ID of the project.
     * @param _finalOutputURI The URI pointing to the metadata for the final research output.
     */
    function submitFinalResearchOutput(uint256 _projectId, string memory _finalOutputURI) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "Only project researcher can submit final output");
        require(project.state == ProjectState.InProgress, "Project not in InProgress state");

        project.state = ProjectState.AwaitingFinalEvaluation;
        project.finalOutputURI = _finalOutputURI; // This URI will become permanent if the project is validated.

        if (aiOracleAddress != address(0)) {
            IAIOracle(aiOracleAddress).requestEvaluation(_projectId, address(this), 2); // 2 for final output evaluation
            emit AIEvaluationRequested(_projectId, 2);
        }

        // Update NFT URI to reflect the final output, pending AI validation.
        _setTokenURI(_projectId, _finalOutputURI);
        emit ProjectStateUpdated(_projectId, ProjectState.AwaitingFinalEvaluation, "Final output submitted for evaluation.");
    }

    /**
     * @dev Retrieves detailed information about a specific project.
     * @param _projectId The ID of the project.
     * @return All relevant project details including its state, funding, and scores.
     */
    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            uint256 projectId,
            address researcher,
            string memory title,
            string memory proposalURI,
            uint256 fundingRequested,
            uint256 fundingAllocated,
            ProjectState state,
            uint256 currentMilestone,
            uint256 aiEvaluationScore,
            string memory finalOutputURI,
            uint256 finalOutputScore,
            bool isKnowledgeLicensed
        )
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        return (
            project.id,
            project.researcher,
            project.title,
            project.proposalURI,
            project.fundingRequested,
            project.fundingAllocated,
            project.state,
            project.currentMilestone,
            project.aiEvaluationScore,
            project.finalOutputURI,
            project.finalOutputScore,
            project.isKnowledgeNFTLicensed
        );
    }

    /**
     * @dev Allows the contract owner to pause a project.
     * This function can be used for security reasons, investigation, or severe policy violations.
     * @param _projectId The ID of the project to pause.
     */
    function pauseProject(uint256 _projectId) public onlyOwner {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.state != ProjectState.Paused, "Project is already paused");
        project.state = ProjectState.Paused;
        emit ProjectStateUpdated(_projectId, ProjectState.Paused, "Project paused by admin.");
    }

    // --- 3. AI Oracle Interaction & Evaluation ---

    /**
     * @dev Requests an AI evaluation for a project.
     * This function is typically called internally after proposal submission, milestone updates,
     * or final output submission. It can also be called by anyone, allowing community-driven re-evaluations.
     * @param _projectId The ID of the project to be evaluated.
     * @param _evaluationType Type of evaluation (0: proposal, 1: progress, 2: final output).
     */
    function requestAIEvaluation(uint256 _projectId, uint256 _evaluationType) public {
        require(aiOracleAddress != address(0), "AI Oracle address not set");
        require(projects[_projectId].id != 0, "Project does not exist");

        // The oracle itself would handle any fees or request queuing.
        IAIOracle(aiOracleAddress).requestEvaluation(_projectId, address(this), _evaluationType);
        emit AIEvaluationRequested(_projectId, _evaluationType);
    }

    /**
     * @dev Callback function to receive AI evaluation results from the AI Oracle.
     * This function is designed to be called exclusively by the registered AI Oracle.
     * It updates the project's state and the researcher's reputation based on the AI score.
     * @param _projectId The ID of the project that was evaluated.
     * @param _score The evaluation score provided by the AI.
     * @param _evaluationType The type of evaluation (0: proposal, 1: progress, 2: final output).
     */
    function receiveAIEvaluationCallback(uint256 _projectId, uint256 _score, uint256 _evaluationType) external {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");

        if (_evaluationType == 0) { // Proposal evaluation
            project.aiEvaluationScore = _score;
            if (_score >= 70) { // Example threshold for proposal approval
                project.state = ProjectState.UnderReview; // Ready for potential funding/community review
                updateReputationScore(project.researcher, 10); // Small positive reputation for a good proposal
                emit ProjectStateUpdated(_projectId, ProjectState.UnderReview, "Proposal AI score received.");
            } else {
                project.state = ProjectState.Rejected;
                updateReputationScore(project.researcher, -5); // Small negative reputation for a rejected proposal
                emit ProjectStateUpdated(_projectId, ProjectState.Rejected, "Proposal rejected by AI.");
            }
        } else if (_evaluationType == 1) { // Progress evaluation
            // A progress score can influence future decisions or trigger warnings.
            if (_score < 50 && project.state == ProjectState.InProgress) { // Example: low score on progress
                 updateReputationScore(project.researcher, -10); // Penalty for poor progress
                 emit ProjectStateUpdated(_projectId, ProjectState.InProgress, "Progress AI score is low, reputation reduced.");
            }
        } else if (_evaluationType == 2) { // Final output evaluation
            project.finalOutputScore = _score;
            if (_score >= 80) { // Example: High enough score for project completion
                project.state = ProjectState.Completed;
                updateReputationScore(project.researcher, 50); // Significant positive reputation for successful completion
                // The Project NFT's URI is already updated in `submitFinalResearchOutput` to the final output URI.
                emit ProjectStateUpdated(_projectId, ProjectState.Completed, "Final output validated by AI.");
            } else {
                project.state = ProjectState.Rejected; // Final output not sufficient
                updateReputationScore(project.researcher, -20); // Penalty for failed project validation
                emit ProjectStateUpdated(_projectId, ProjectState.Rejected, "Final output rejected by AI.");
            }
        }
        emit AIEvaluationReceived(_projectId, _score, _evaluationType);
    }

    // --- 4. Funding & Grants Mechanism ---

    /**
     * @dev Allows any user to deposit Ether into the contract's overall grant pool.
     * These funds are used to support research projects.
     */
    function depositFunds() public payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        totalGrantPool += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows a researcher to request a portion of their project's funding.
     * Initial grant allocations for "UnderReview" projects with high AI scores can be auto-approved.
     * Subsequent allocations for "InProgress" projects often require explicit governance approval.
     * @param _projectId The ID of the project.
     * @param _amount The amount of funds (in wei) requested for allocation.
     */
    function requestGrantAllocation(uint256 _projectId, uint256 _amount) public {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "Only project researcher can request allocation");
        require(project.state == ProjectState.UnderReview || project.state == ProjectState.InProgress, "Project not in review or in progress");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount + project.fundingAllocated <= project.fundingRequested, "Total allocated amount cannot exceed requested amount.");

        // Auto-approve initial grant if project is under review and has a sufficiently high AI score.
        if (project.state == ProjectState.UnderReview && project.aiEvaluationScore >= 70) {
            _approveGrantAllocation(_projectId, _amount);
        } else {
            // For in-progress projects or those not meeting auto-approval, a governance proposal
            // or explicit administrative approval (via `executeProposal`) would be necessary.
            revert("Grant requests for in-progress projects require governance approval.");
        }
    }

    /**
     * @dev Internal function to approve and transfer funds from the general grant pool to a project's balance.
     * This function is called internally (e.g., by `requestGrantAllocation` or `executeProposal`).
     * @param _projectId The ID of the project to allocate funds to.
     * @param _amount The amount of funds (in wei) to allocate.
     */
    function _approveGrantAllocation(uint256 _projectId, uint256 _amount) internal nonReentrant {
        Project storage project = projects[_projectId];
        require(totalGrantPool >= _amount, "Not enough funds in grant pool");
        require(_amount + project.fundingAllocated <= project.fundingRequested, "Allocation exceeds requested funds");

        totalGrantPool -= _amount; // Deduct from general pool
        projectFundingBalances[_projectId] += _amount; // Add to project's specific balance
        project.fundingAllocated += _amount; // Update total allocated for the project

        if (project.state == ProjectState.UnderReview) {
            project.state = ProjectState.InProgress; // Move project to InProgress once initial funding is secured
            emit ProjectStateUpdated(_projectId, ProjectState.InProgress, "Initial grant approved, project moved to InProgress.");
        }
        emit GrantAllocated(_projectId, project.researcher, _amount);
    }

    /**
     * @dev Allows a researcher to claim their approved and allocated grant funds for their project.
     * Funds are transferred from the contract to the researcher's address.
     * @param _projectId The ID of the project for which funds are being claimed.
     */
    function claimGrantFunds(uint256 _projectId) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "Only project researcher can claim funds");
        require(projectFundingBalances[_projectId] > 0, "No funds allocated for this project to claim");

        uint256 amountToClaim = projectFundingBalances[_projectId];
        projectFundingBalances[_projectId] = 0; // Reset the project's balance

        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Failed to send funds to researcher");

        emit GrantClaimed(_projectId, msg.sender, amountToClaim);
    }

    // --- 5. Researcher Reputation System (SBT-like) ---

    /**
     * @dev Retrieves the current reputation score of a given researcher.
     * @param _researcher The address of the researcher.
     * @return The current reputation score as an int256.
     */
    function getResearcherReputation(address _researcher) public view returns (int256) {
        return researcherReputation[_researcher];
    }

    /**
     * @dev Internal function to update a researcher's reputation score.
     * This function is called by other parts of the contract, e.g., AI evaluation callbacks
     * or successful governance proposal executions.
     * @param _researcher The address of the researcher whose reputation is being updated.
     * @param _change The amount to add (positive) or subtract (negative) from the reputation.
     */
    function updateReputationScore(address _researcher, int256 _change) internal {
        researcherReputation[_researcher] += _change;
        emit ReputationUpdated(_researcher, researcherReputation[_researcher]);
    }

    /**
     * @dev Allows the owner to punish a researcher's reputation (reduce their score).
     * This might be extended to be callable only via a successful governance proposal.
     * @param _researcher The address of the researcher to punish.
     * @param _amount The amount by which to reduce the reputation.
     */
    function punishReputation(address _researcher, uint256 _amount) public onlyOwner {
        require(_researcher != address(0), "Invalid researcher address");
        require(_amount > 0, "Punishment amount must be positive");
        researcherReputation[_researcher] -= int256(_amount);
        emit ReputationUpdated(_researcher, researcherReputation[_researcher]);
    }

    // --- 6. Licensable Research Output (Project NFTs become "Knowledge NFTs") ---

    /**
     * @dev Finalizes a successfully completed and AI-validated project as a "Knowledge NFT".
     * This function sets the licensing terms (e.g., royalty percentage) for the research output.
     * The existing Project NFT (ERC721) for this project now represents the licensable knowledge.
     * @param _projectId The ID of the project to finalize.
     * @param _royaltyPercentage The percentage of future licensing revenue to be paid to the researcher (e.g., 500 for 5%). Max 10000 (100%).
     */
    function finalizeProjectAsKnowledge(uint256 _projectId, uint256 _royaltyPercentage) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "Only project researcher can finalize as Knowledge NFT");
        require(project.state == ProjectState.Completed, "Project must be in Completed state to finalize as Knowledge NFT");
        require(!project.isKnowledgeNFTLicensed, "Project already finalized as Knowledge NFT with license terms.");
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%"); // 10000 basis points = 100%

        ProjectLicensingTerms storage knftTerms = projectLicensingTerms[_projectId];
        knftTerms.royaltyPercentage = _royaltyPercentage;
        project.isKnowledgeNFTLicensed = true;

        // The Project NFT's tokenURI is already set to `finalOutputURI` in `submitFinalResearchOutput`.
        // This makes the Project NFT itself represent the licensed knowledge asset.
        emit ProjectFinalizedAsKnowledge(_projectId, msg.sender, _royaltyPercentage);
    }

    /**
     * @dev Allows a user to acquire a license for a "Knowledge NFT" (which is a completed Project NFT).
     * The function handles the payment of the license fee and distributes it as royalties
     * to the researcher, and portions to the admin and community grant pool.
     * @param _projectId The ID of the Project NFT (representing the Knowledge NFT) to license.
     */
    function acquireKnowledgeLicense(uint256 _projectId) public payable nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.isKnowledgeNFTLicensed, "This project's output is not set for licensing.");
        require(msg.value > 0, "License fee must be greater than zero");

        ProjectLicensingTerms storage knftTerms = projectLicensingTerms[_projectId];
        // Simplified: prevents multiple licenses by the same address.
        // A real system might have more complex licensing models (e.g., timed, tiered).
        require(!knftTerms.hasLicense[msg.sender], "You already hold a license for this knowledge.");

        knftTerms.hasLicense[msg.sender] = true;

        // Calculate distribution: creator royalty, admin fee, remaining to community pool
        uint256 creatorRoyalty = (msg.value * knftTerms.royaltyPercentage) / 10000;
        uint256 adminFee = (msg.value * ADMIN_FEE_PERCENTAGE) / 10000;
        uint256 communityPoolCut = msg.value - creatorRoyalty - adminFee;

        // Send royalty to the researcher (creator of the knowledge)
        (bool successCreator, ) = payable(project.researcher).call{value: creatorRoyalty}("");
        require(successCreator, "Failed to send creator royalty");

        // Add remaining funds to the community grant pool
        totalGrantPool += communityPoolCut;

        // Admin fees are implicitly part of the contract's balance and can be withdrawn by the owner.
        // In a more complex system, `adminFeesAccrued` could be a separate tracked variable.

        emit KnowledgeLicensed(_projectId, msg.sender, msg.value);
        emit RevenueDistributed(_projectId, msg.value);
    }

    // --- 7. Community Governance & Voting ---

    /**
     * @dev Allows users with a sufficient reputation score to submit a governance proposal.
     * Proposals can initiate actions like new grant allocations, protocol upgrades, or policy changes.
     * @param _description A textual description of the proposal.
     * @param _targetContract The address of the contract that the proposal aims to call (can be `address(this)` for self-calls).
     * @param _callData The ABI-encoded function call to execute if the proposal passes.
     * @param _votingPeriod The duration of the voting period in seconds.
     * @return The unique ID of the newly created proposal.
     */
    function submitGovernanceProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint256 _votingPeriod
    ) public nonReentrant returns (uint256) {
        require(researcherReputation[msg.sender] >= MIN_REPUTATION_FOR_VOTING, "Insufficient reputation to propose");
        require(_targetContract != address(0), "Target contract cannot be zero address");
        require(_votingPeriod > 0, "Voting period must be greater than zero");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.targetContract = _targetContract;
        newProposal.callData = _callData;
        newProposal.executed = false;
        newProposal.deadline = block.timestamp + _votingPeriod;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;

        emit ProposalCreated(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /**
     * @dev Allows users with sufficient reputation to vote on an active proposal.
     * Each voter's influence is weighted by their current reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for voting 'for' the proposal, false for voting 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(researcherReputation[msg.sender] >= MIN_REPUTATION_FOR_VOTING, "Insufficient reputation to vote");
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        int256 voterReputation = researcherReputation[msg.sender];
        require(voterReputation > 0, "Cannot vote with non-positive reputation."); // Only positive reputation counts

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += uint256(voterReputation); // Add reputation score to 'for' votes
        } else {
            proposal.votesAgainst += uint256(voterReputation); // Add reputation score to 'against' votes
        }
        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a governance proposal if its voting period has ended and it has passed.
     * A simple majority of reputation-weighted votes (votesFor > votesAgainst) is required.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.deadline, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass the majority vote");

        proposal.executed = true;

        // Execute the proposed action using low-level call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // --- 8. Utility & Emergency Functions ---

    /**
     * @dev Allows the owner to withdraw a specified amount of administrative fees.
     * These fees are implicitly collected from `acquireKnowledgeLicense` into the contract's balance.
     * @param _amount The amount of Ether (in wei) to withdraw as fees.
     */
    function withdrawAdminFees(uint256 _amount) public onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        // This implicitly assumes the contract's balance holds enough fees.
        // For production, a separate `adminFeeBalance` counter would be more explicit.
        require(address(this).balance >= _amount, "Insufficient contract balance for admin fees");

        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Failed to withdraw admin fees");

        emit AdminFeesWithdrawn(owner(), _amount);
    }

    /**
     * @dev Allows the owner to emergency withdraw all Ether held by the contract to a safe address.
     * This is a critical function for disaster recovery or in unforeseen circumstances.
     * @param _to The address to send all funds to.
     */
    function emergencyWithdrawFunds(address _to) public onlyOwner nonReentrant {
        require(_to != address(0), "Invalid recipient address");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");

        (bool success, ) = payable(_to).call{value: contractBalance}("");
        require(success, "Emergency withdrawal failed");
    }

    /**
     * @dev A general receive fallback function to accept Ether.
     * Any direct Ether sent to the contract will be added to the `totalGrantPool`.
     */
    receive() external payable {
        depositFunds(); // Direct ETH deposits contribute to the grant pool
    }
}
```