Here's a smart contract for a Decentralized Autonomous Research Lab (DARL) that embodies interesting, advanced, creative, and trendy concepts, with at least 20 unique functions.

---

**Contract: Decentralized Autonomous Research Lab (DARL)**

**Outline:**

1.  **Core Structures & Enums:** Definitions for Project states, Milestone states, Project details, Milestone details, Researcher profiles, and IP licenses.
2.  **State Variables:** Mappings and arrays to store project data, researcher data, IP data, and system parameters.
3.  **Events:** Emitted for key actions like project proposals, funding, milestone updates, and IP minting.
4.  **Modifiers:** Custom modifiers for access control (e.g., `onlyGovernanceCouncil`, `onlyProjectLead`).
5.  **Constructor:** Initializes the contract with the owner, governance token, treasury, and IP NFT contract addresses.
6.  **I. Core Infrastructure & Initialization Functions:** Functions to set up and update critical contract addresses.
7.  **II. Project Management Functions:** Lifecycle management for research projects, from proposal to conclusion.
8.  **III. Intellectual Property (IP) Management & Rewards Functions:** Functions for minting IP NFTs, distributing rewards, and managing IP licenses.
9.  **IV. Reputation & Researcher Management Functions:** Functions to register researchers and manage their reputation within the DARL.
10. **V. Governance & Utility Functions:** Functions for governance decisions, parameter updates, and general contract utility.
11. **VI. View Functions:** Read-only functions to query the state of the contract.

**Function Summary:**

This contract establishes a platform for decentralized, community-driven research and development. It enables users to propose, fund, execute, and review research projects. Successful projects result in tokenized Intellectual Property (IP) in the form of NFTs, which can be licensed or monetized, sharing rewards among contributors. The system incorporates reputation building for researchers and a governance mechanism for decision-making.

**I. Core Infrastructure & Initialization**
1.  `constructor`: Initializes the contract with the deployer as owner, and sets initial addresses for the governance token, DARL treasury, and the external IP NFT contract.
2.  `updateGovernanceTokenAddress`: Allows the owner to update the address of the ERC20 token used for voting and staking within the DARL.
3.  `updateTreasuryAddress`: Allows the owner to update the address of the main DARL treasury, where project funds and system revenues are held.
4.  `updateIpNftContractAddress`: Allows the owner to update the address of the ERC721 contract responsible for minting project IP NFTs.
5.  `addGovernanceCouncilMember`: Grants an address membership to the governance council. (Owner-only)
6.  `removeGovernanceCouncilMember`: Revokes an address's membership from the governance council. (Owner-only)

**II. Project Management**
7.  `proposeProject`: Allows any registered researcher to propose a new research project, detailing its name, description (IPFS hash), required funding, duration, number of milestones, and expected IP type.
8.  `voteOnProjectProposal`: Enables governance token stakers to vote on whether a proposed project should be accepted for funding. Requires a minimum stake.
9.  `fundProject`: Allows users to contribute ERC20 tokens to a project that has been approved and is actively seeking funding.
10. `startProjectExecution`: Initiates the execution phase of a project once it has met its funding goal and received final governance approval.
11. `submitMilestoneReport`: Project lead submits a report (via IPFS hash) for a completed project milestone, including relevant data hashes for reproducibility and auditability.
12. `reviewMilestone`: Governance council members or designated reviewers assess a submitted milestone report and approve or reject it, potentially releasing funds.
13. `requestAdditionalFunding`: Allows a project lead to request more funds for an ongoing project, requiring subsequent governance approval and funding.
14. `cancelProject`: Enables the governance council to halt and cancel a project, potentially refunding remaining funds based on project status and defined policies.
15. `concludeProject`: Marks a project as complete (either successful or failed), requiring a final report hash and triggering reward distribution if successful.

**III. Intellectual Property (IP) Management & Rewards**
16. `mintProjectIP_NFT`: Upon successful project conclusion, this function mints an ERC721 NFT representing the project's intellectual property, linking it to metadata and initial licensing terms.
17. `distributeProjectRewards`: Calculates and distributes rewards (e.g., governance tokens, project shares, or a portion of collected funds) to researchers, funders, and the DARL treasury based on project success and their contributions.
18. `recordIPLicense`: Allows the owner of a project IP NFT to record a licensing agreement on-chain, specifying the licensee, duration, and terms (IPFS hash).
19. `collectIPRoyalty`: Enables the IP NFT owner to collect specified royalties from active licensing agreements. (Requires an external mechanism to track and deposit royalties).

**IV. Reputation & Researcher Management**
20. `registerResearcherProfile`: Allows users to create a public researcher profile by providing an IPFS hash to their credentials, expertise, or CV.
21. `awardReputationPoints`: (Governance-only) Awards reputation points to researchers for significant contributions, successful project outcomes, or exemplary conduct.
22. `slashReputationPoints`: (Governance-only) Deducts reputation points for documented misconduct, project failures attributed to the researcher, or violation of DARL policies.

**V. Governance & Utility**
23. `setProjectParameter`: Allows the governance council to update various project-related parameters, such as voting thresholds, funding fees, or milestone review periods.
24. `withdrawTreasuryFunds`: Permits the governance council to withdraw funds from the general DARL treasury for approved operational costs or other strategic initiatives.
25. `claimUnusedProjectFunds`: Allows funders to claim back their unspent contributions if a project is canceled or fails to start.

**VI. View Functions**
26. `getProjectDetails`: A view function to retrieve all stored information about a specific project, including its status, funding, and lead researcher.
27. `getResearcherProfile`: A view function to retrieve the IPFS hash associated with a researcher's public profile and their current reputation points.
28. `getProjectIPs`: A view function to list all IP NFT IDs that have been minted for a given project.
29. `getProjectContributions`: A view function to see individual funding contributions for a specific project.
30. `getProjectMilestoneDetails`: A view function to retrieve the details of a specific milestone within a project.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For checking IP NFT ownership
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safe arithmetic

// Interface for a custom mintable ERC721 contract that DARL will interact with
interface IDARL_IP_NFT {
    function mint(address to, uint256 tokenId, string calldata uri) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    // Potentially more advanced functions like setTokenURI or updateRoyaltyInfo
}

contract DecentralizedAutonomousResearchLab is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums ---
    enum ProjectStatus { Proposed, Approved, Funding, Active, MilestoneReview, AdditionalFundingRequested, Failed, Cancelled, Completed }
    enum MilestoneStatus { Proposed, Approved, Rejected, PendingReview, Completed }

    // --- Structs ---

    struct Project {
        string name;
        string descriptionHash; // IPFS hash for project description
        address projectLead;
        uint256 requiredFunding;
        uint256 fundedAmount;
        uint256 startTime;
        uint256 duration; // In seconds
        uint256 milestoneCount;
        ProjectStatus status;
        string expectedIPType; // e.g., "Software Module", "Research Paper", "Data Set"
        uint256 ipNftId; // 0 if no IP NFT yet
        address[] funders; // To track unique funders for reward distribution
        mapping(address => uint256) funderContributions; // Specific contribution per funder
        mapping(uint256 => Milestone) milestones;
        mapping(address => bool) projectResearchers; // To track unique researchers on a project
    }

    struct Milestone {
        string reportHash; // IPFS hash for milestone report
        string[] dataHashes; // IPFS hashes for associated data/evidence (on-chain lab notebook)
        MilestoneStatus status;
        uint256 reviewDeadline;
        bool fundsReleased; // Funds specific to this milestone
    }

    struct ResearcherProfile {
        string profileHash; // IPFS hash for CV/expertise
        uint256 reputationPoints;
        bool isRegistered;
    }

    struct IPLicense {
        address licensee;
        string termsHash; // IPFS hash for detailed licensing terms
        uint256 royaltyPercentageBps; // Royalty percentage in basis points (e.g., 100 = 1%)
        uint256 startTime;
        uint256 endTime; // 0 for perpetual license
        bool active;
    }

    // --- State Variables ---

    uint256 public nextProjectId;
    uint256 public nextIpNftId = 1; // Starting ID for IP NFTs
    uint256 public constant MAX_ROYALTY_PERCENTAGE_BPS = 2000; // 20% max royalty

    address public governanceToken; // ERC20 token used for voting and funding
    address public darlTreasury;    // Address to hold general DARL funds
    IDARL_IP_NFT public ipNftContract; // ERC721 contract for project IP NFTs

    // Project data
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => bool)) public projectProposalVotes; // projectId => voter => voted
    mapping(uint256 => uint256) public projectProposalVoteCount; // projectId => votes
    uint256 public proposalVoteThreshold; // Minimum votes required for a project to be approved
    uint256 public minStakedTokensForVote; // Minimum governance tokens required to vote

    // Researcher data
    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(address => bool) public isGovernanceCouncilMember;
    uint256 public governanceCouncilCount;

    // IP data
    mapping(uint256 => mapping(uint256 => IPLicense)) public ipNftLicenses; // ipNftId => licenseId => IPLicense
    mapping(uint256 => uint256) public nextIpLicenseId;

    // Fees and reward parameters (set by governance)
    uint256 public projectFundingFeeBps; // Fee collected by DARL from project funding (basis points)
    uint256 public researcherRewardPercentageBps; // % of successful project budget for researchers
    uint256 public funderRewardPercentageBps;      // % of successful project budget for funders
    uint256 public governanceRewardPercentageBps;   // % of successful project budget for governance

    // --- Events ---

    event GovernanceTokenAddressUpdated(address indexed newAddress);
    event TreasuryAddressUpdated(address indexed newAddress);
    event IpNftContractAddressUpdated(address indexed newAddress);
    event GovernanceCouncilMemberAdded(address indexed member);
    event GovernanceCouncilMemberRemoved(address indexed member);

    event ProjectProposed(uint256 indexed projectId, address indexed projectLead, string name, uint256 requiredFunding);
    event ProjectProposalVoted(uint256 indexed projectId, address indexed voter, bool approved);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectExecutionStarted(uint256 indexed projectId);
    event MilestoneReportSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string reportHash);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneIndex, bool approved);
    event AdditionalFundingRequested(uint256 indexed projectId, uint256 amount);
    event ProjectCancelled(uint256 indexed projectId, string reasonHash);
    event ProjectConcluded(uint256 indexed projectId, bool success, string finalReportHash);

    event ProjectIP_NFT_Minted(uint256 indexed projectId, uint256 indexed ipNftId, address indexed owner);
    event ProjectRewardsDistributed(uint256 indexed projectId, uint256 totalRewards);
    event IPLicenseRecorded(uint256 indexed ipNftId, uint256 indexed licenseId, address indexed licensee, uint256 royaltyPercentageBps);
    event IPRoyaltyCollected(uint256 indexed ipNftId, uint256 indexed licenseId, address indexed collector, uint256 amount);

    event ResearcherProfileRegistered(address indexed researcher, string profileHash);
    event ReputationPointsAwarded(address indexed researcher, uint256 points);
    event ReputationPointsSlashed(address indexed researcher, uint256 points);

    event ProjectParameterSet(string indexed paramName, uint256 oldValue, uint256 newValue);
    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);
    event UnusedProjectFundsClaimed(uint256 indexed projectId, address indexed funder, uint256 amount);

    // --- Modifiers ---

    modifier onlyRegisteredResearcher() {
        require(researcherProfiles[_msgSender()].isRegistered, "Caller must be a registered researcher");
        _;
    }

    modifier onlyGovernanceCouncil() {
        require(isGovernanceCouncilMember[_msgSender()], "Caller must be a governance council member");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].projectLead == _msgSender(), "Caller must be the project lead");
        _;
    }

    modifier onlyIpNftOwner(uint256 _ipNftId) {
        require(ipNftContract.ownerOf(_ipNftId) == _msgSender(), "Caller must be the IP NFT owner");
        _;
    }

    // --- Constructor ---

    constructor(address _governanceToken, address _darlTreasury, address _ipNftContract) Ownable(_msgSender()) {
        require(_governanceToken != address(0), "Invalid governance token address");
        require(_darlTreasury != address(0), "Invalid treasury address");
        require(_ipNftContract != address(0), "Invalid IP NFT contract address");

        governanceToken = _governanceToken;
        darlTreasury = _darlTreasury;
        ipNftContract = IDARL_IP_NFT(_ipNftContract);

        // Initial parameters (can be changed by governance later)
        proposalVoteThreshold = 3; // Example: 3 votes needed to approve a project proposal
        minStakedTokensForVote = 100 ether; // Example: 100 tokens needed to vote
        projectFundingFeeBps = 500; // 5% fee
        researcherRewardPercentageBps = 3000; // 30% for researchers
        funderRewardPercentageBps = 5000;     // 50% for funders
        governanceRewardPercentageBps = 1500;   // 15% for governance (sum = 95%, 5% for DARL treasury via fee)
        require(
            researcherRewardPercentageBps.add(funderRewardPercentageBps).add(governanceRewardPercentageBps) <= 10000,
            "Reward percentages exceed 100%"
        );

        // Add deployer as initial governance council member
        isGovernanceCouncilMember[_msgSender()] = true;
        governanceCouncilCount = 1;
        emit GovernanceCouncilMemberAdded(_msgSender());
    }

    // --- I. Core Infrastructure & Initialization Functions ---

    /**
     * @notice Allows the owner to update the address of the ERC20 token used for voting and staking.
     * @param _newAddress The new address of the governance token.
     */
    function updateGovernanceTokenAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid governance token address");
        governanceToken = _newAddress;
        emit GovernanceTokenAddressUpdated(_newAddress);
    }

    /**
     * @notice Allows the owner to update the address of the main DARL treasury.
     * @param _newAddress The new address for the treasury.
     */
    function updateTreasuryAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid treasury address");
        darlTreasury = _newAddress;
        emit TreasuryAddressUpdated(_newAddress);
    }

    /**
     * @notice Allows the owner to update the address of the ERC721 contract for minting IP NFTs.
     * @param _newAddress The new address for the IP NFT contract.
     */
    function updateIpNftContractAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid IP NFT contract address");
        ipNftContract = IDARL_IP_NFT(_newAddress);
        emit IpNftContractAddressUpdated(_newAddress);
    }

    /**
     * @notice Adds an address as a member of the governance council.
     * @param _member The address to add.
     */
    function addGovernanceCouncilMember(address _member) public onlyOwner {
        require(_member != address(0), "Invalid address");
        require(!isGovernanceCouncilMember[_member], "Address is already a council member");
        isGovernanceCouncilMember[_member] = true;
        governanceCouncilCount = governanceCouncilCount.add(1);
        emit GovernanceCouncilMemberAdded(_member);
    }

    /**
     * @notice Removes an address from the governance council.
     * @param _member The address to remove.
     */
    function removeGovernanceCouncilMember(address _member) public onlyOwner {
        require(_member != address(0), "Invalid address");
        require(isGovernanceCouncilMember[_member], "Address is not a council member");
        require(governanceCouncilCount > 1, "Cannot remove the last governance council member");
        isGovernanceCouncilMember[_member] = false;
        governanceCouncilCount = governanceCouncilCount.sub(1);
        emit GovernanceCouncilMemberRemoved(_member);
    }

    // --- II. Project Management Functions ---

    /**
     * @notice Allows a registered researcher to propose a new research project.
     * @param _name Project name.
     * @param _descriptionHash IPFS hash for detailed description.
     * @param _requiredFunding Total funding required for the project.
     * @param _duration Project duration in seconds.
     * @param _milestoneCount Number of milestones for the project.
     * @param _expectedIPType Description of the expected IP (e.g., "Software", "Paper").
     */
    function proposeProject(
        string calldata _name,
        string calldata _descriptionHash,
        uint256 _requiredFunding,
        uint256 _duration,
        uint256 _milestoneCount,
        string calldata _expectedIPType
    ) external onlyRegisteredResearcher {
        require(_requiredFunding > 0, "Required funding must be greater than zero");
        require(_duration > 0, "Project duration must be greater than zero");
        require(_milestoneCount > 0, "Project must have at least one milestone");

        uint256 projectId = nextProjectId++;
        Project storage newProject = projects[projectId];

        newProject.name = _name;
        newProject.descriptionHash = _descriptionHash;
        newProject.projectLead = _msgSender();
        newProject.requiredFunding = _requiredFunding;
        newProject.duration = _duration;
        newProject.milestoneCount = _milestoneCount;
        newProject.status = ProjectStatus.Proposed;
        newProject.expectedIPType = _expectedIPType;
        newProject.projectResearchers[_msgSender()] = true; // Project lead is a researcher

        emit ProjectProposed(projectId, _msgSender(), _name, _requiredFunding);
    }

    /**
     * @notice Enables governance token stakers to vote on a proposed project.
     * @param _projectId The ID of the project to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "Project is not in Proposed status");
        require(!projectProposalVotes[_projectId][_msgSender()], "Already voted on this proposal");

        // Check if voter holds enough governance tokens
        require(IERC20(governanceToken).balanceOf(_msgSender()) >= minStakedTokensForVote, "Not enough staked tokens to vote");

        projectProposalVotes[_projectId][_msgSender()] = true;
        if (_approve) {
            projectProposalVoteCount[_projectId] = projectProposalVoteCount[_projectId].add(1);
        } else {
            // For simplicity, a "no" vote doesn't actively decrement approval count, but is recorded.
            // A more complex system might have 'yay' and 'nay' counts.
        }

        emit ProjectProposalVoted(_projectId, _msgSender(), _approve);

        if (projectProposalVoteCount[_projectId] >= proposalVoteThreshold) {
            project.status = ProjectStatus.Funding;
            emit ProjectApproved(_projectId);
        }
    }

    /**
     * @notice Allows users to contribute ERC20 tokens to an approved project.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of tokens to contribute.
     */
    function fundProject(uint256 _projectId, uint256 _amount) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Funding, "Project is not in Funding status");
        require(_amount > 0, "Funding amount must be greater than zero");
        require(project.fundedAmount.add(_amount) <= project.requiredFunding, "Funding exceeds required amount");

        // Transfer funds from funder to DARL treasury
        require(IERC20(governanceToken).transferFrom(_msgSender(), address(this), _amount), "Token transfer failed");

        // Apply DARL fee before crediting to project
        uint256 fee = _amount.mul(projectFundingFeeBps).div(10000);
        uint256 netAmount = _amount.sub(fee);

        require(IERC20(governanceToken).transfer(darlTreasury, fee), "Fee transfer failed");

        project.fundedAmount = project.fundedAmount.add(netAmount);
        project.funderContributions[_msgSender()] = project.funderContributions[_msgSender()].add(netAmount);

        // Add funder to list if new
        bool newFunder = true;
        for (uint i = 0; i < project.funders.length; i++) {
            if (project.funders[i] == _msgSender()) {
                newFunder = false;
                break;
            }
        }
        if (newFunder) {
            project.funders.push(_msgSender());
        }

        emit ProjectFunded(_projectId, _msgSender(), netAmount);

        if (project.fundedAmount == project.requiredFunding) {
            project.status = ProjectStatus.Active; // Ready for execution
            project.startTime = block.timestamp;
            emit ProjectExecutionStarted(_projectId);
        }
    }

    /**
     * @notice Initiates the execution phase of a project once fully funded and approved.
     * @param _projectId The ID of the project to start.
     */
    function startProjectExecution(uint256 _projectId) external onlyGovernanceCouncil {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Funding, "Project not in Funding status");
        require(project.fundedAmount >= project.requiredFunding, "Project not fully funded");

        project.status = ProjectStatus.Active;
        project.startTime = block.timestamp;

        // Initialize milestones
        for (uint256 i = 0; i < project.milestoneCount; i++) {
            project.milestones[i].status = MilestoneStatus.Proposed;
            // Example: Set first milestone review deadline
            if (i == 0) {
                 project.milestones[i].reviewDeadline = block.timestamp.add(project.duration.div(project.milestoneCount));
            }
        }
        emit ProjectExecutionStarted(_projectId);
    }

    /**
     * @notice Project lead submits a report for a completed project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-indexed).
     * @param _reportHash IPFS hash for the milestone report.
     * @param _dataHashes Array of IPFS hashes for associated data.
     */
    function submitMilestoneReport(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _reportHash,
        string[] calldata _dataHashes
    ) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.MilestoneReview, "Project not in Active or Review status");
        require(_milestoneIndex < project.milestoneCount, "Milestone index out of bounds");
        require(project.milestones[_milestoneIndex].status != MilestoneStatus.Completed, "Milestone already completed");

        project.milestones[_milestoneIndex].reportHash = _reportHash;
        project.milestones[_milestoneIndex].dataHashes = _dataHashes;
        project.milestones[_milestoneIndex].status = MilestoneStatus.PendingReview;
        project.milestones[_milestoneIndex].reviewDeadline = block.timestamp.add(2 days); // Example: 2 days for review

        project.status = ProjectStatus.MilestoneReview;
        emit MilestoneReportSubmitted(_projectId, _milestoneIndex, _reportHash);
    }

    /**
     * @notice Governance members review a submitted milestone report.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _approved True if approved, false if rejected.
     */
    function reviewMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved) external onlyGovernanceCouncil {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(project.status == ProjectStatus.MilestoneReview, "Project not in MilestoneReview status");
        require(milestone.status == MilestoneStatus.PendingReview, "Milestone not pending review");
        require(block.timestamp <= milestone.reviewDeadline, "Milestone review deadline passed");

        milestone.status = _approved ? MilestoneStatus.Completed : MilestoneStatus.Rejected;
        emit MilestoneReviewed(_projectId, _milestoneIndex, _approved);

        if (_approved) {
            // Funds release logic (example: proportional to milestone completion)
            uint256 fundsToRelease = project.fundedAmount.div(project.milestoneCount);
            // In a real scenario, this would likely involve a separate transfer to the project lead
            // for project expenses, or direct payment to researchers. For simplicity here, it's marked.
            milestone.fundsReleased = true;

            // Check if all milestones completed
            bool allMilestonesCompleted = true;
            for (uint256 i = 0; i < project.milestoneCount; i++) {
                if (project.milestones[i].status != MilestoneStatus.Completed) {
                    allMilestonesCompleted = false;
                    break;
                }
            }
            if (allMilestonesCompleted) {
                project.status = ProjectStatus.Completed; // Project moves to final completion state
                emit ProjectConcluded(_projectId, true, "All milestones completed");
            } else {
                project.status = ProjectStatus.Active; // Back to active if more milestones
                 // Set next milestone review deadline (example: proportional)
                if (_milestoneIndex + 1 < project.milestoneCount) {
                    project.milestones[_milestoneIndex + 1].reviewDeadline = block.timestamp.add(project.duration.div(project.milestoneCount));
                }
            }

        } else {
            // Milestone rejected - project lead can resubmit or project might be cancelled
            project.status = ProjectStatus.Active; // Project Lead needs to resubmit or request cancellation
            // Governance can decide to cancel a project after too many rejections
        }
    }

    /**
     * @notice Allows a project lead to request additional funding for an ongoing project.
     * @param _projectId The ID of the project.
     * @param _amount The additional amount of tokens requested.
     * @param _reasonHash IPFS hash for the justification for additional funding.
     */
    function requestAdditionalFunding(uint256 _projectId, uint256 _amount, string calldata _reasonHash) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.MilestoneReview, "Project not active");
        require(_amount > 0, "Additional funding must be greater than zero");

        project.requiredFunding = project.requiredFunding.add(_amount);
        project.status = ProjectStatus.AdditionalFundingRequested;
        // This state would typically trigger a new voting round by governance or funders
        // For simplicity, it just changes status here. Funders would call fundProject again.

        emit AdditionalFundingRequested(_projectId, _amount);
    }

    /**
     * @notice Enables governance to halt and cancel a project.
     * @param _projectId The ID of the project to cancel.
     * @param _reasonHash IPFS hash for the cancellation reason.
     */
    function cancelProject(uint256 _projectId, string calldata _reasonHash) external onlyGovernanceCouncil {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Failed && project.status != ProjectStatus.Cancelled && project.status != ProjectStatus.Completed, "Project cannot be cancelled");

        project.status = ProjectStatus.Cancelled;
        emit ProjectCancelled(_projectId, _reasonHash);
        // Note: Funds held for cancelled projects can be claimed by funders via claimUnusedProjectFunds
    }

    /**
     * @notice Marks a project as complete, specifying success or failure.
     * @param _projectId The ID of the project.
     * @param _success True if the project was successful, false otherwise.
     * @param _finalReportHash IPFS hash for the final project report.
     */
    function concludeProject(uint256 _projectId, bool _success, string calldata _finalReportHash) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Cancelled && project.status != ProjectStatus.Failed && project.status != ProjectStatus.Completed, "Project already concluded or cancelled");

        project.status = _success ? ProjectStatus.Completed : ProjectStatus.Failed;
        emit ProjectConcluded(_projectId, _success, _finalReportHash);

        if (_success) {
            // Trigger reward distribution and potential IP NFT minting
            distributeProjectRewards(_projectId);
            // Project lead can then call mintProjectIP_NFT
        }
    }

    // --- III. Intellectual Property (IP) Management & Rewards Functions ---

    /**
     * @notice Upon successful project conclusion, mints an ERC721 NFT representing the project's intellectual property.
     *         Callable by the project lead after successful conclusion.
     * @param _projectId The ID of the project.
     * @param _ipfsURI The base URI for the IP NFT metadata.
     * @param _metadataHash IPFS hash for rich metadata.
     * @param _licensingTermsHash IPFS hash for initial licensing terms.
     */
    function mintProjectIP_NFT(
        uint256 _projectId,
        string calldata _ipfsURI,
        string calldata _metadataHash,
        string calldata _licensingTermsHash
    ) external onlyProjectLead(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed, "Project not in Completed status");
        require(project.ipNftId == 0, "IP NFT already minted for this project");

        uint256 currentIpNftId = nextIpNftId++;
        project.ipNftId = currentIpNftId;

        // The DARL contract itself can't own the NFT, it mints to the project lead.
        // The project lead then has the option to assign it to a DAO or a multi-sig.
        // The _ipfsURI + _metadataHash would form the full token URI for the ERC721.
        ipNftContract.mint(_msgSender(), currentIpNftId, _ipfsURI);

        // Record initial licensing terms (optional, can be done post-mint by owner)
        if (bytes(_licensingTermsHash).length > 0) {
            IPLicense storage initialLicense = ipNftLicenses[currentIpNftId][nextIpLicenseId[currentIpNftId]++];
            initialLicense.licensee = _msgSender(); // Default to owner as initial "licensee" for terms
            initialLicense.termsHash = _licensingTermsHash;
            initialLicense.royaltyPercentageBps = 0; // No initial royalty on self-mint
            initialLicense.startTime = block.timestamp;
            initialLicense.active = true;
        }

        emit ProjectIP_NFT_Minted(_projectId, currentIpNftId, _msgSender());
    }

    /**
     * @notice Calculates and distributes rewards to researchers, funders, and governance.
     *         Callable by governance after project completion.
     * @param _projectId The ID of the project.
     */
    function distributeProjectRewards(uint256 _projectId) public onlyGovernanceCouncil nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed, "Project not in Completed status");
        require(project.fundedAmount > 0, "No funds to distribute for this project");

        uint256 totalRewardsPool = project.fundedAmount; // This is the net funded amount after initial fee

        // Calculate rewards for researchers
        uint256 researcherReward = totalRewardsPool.mul(researcherRewardPercentageBps).div(10000);
        uint256 researchersCount = 0;
        for (address researcherAddr : getProjectResearchers(_projectId)) {
            if (researcherAddr != address(0)) { // Ensure it's a valid researcher
                researchersCount = researchersCount.add(1);
            }
        }
        if (researchersCount > 0) {
            uint256 rewardPerResearcher = researcherReward.div(researchersCount);
            // This is simplified. More advanced: track individual contributions, reputation for weighted rewards.
            for (address researcherAddr : getProjectResearchers(_projectId)) {
                if (researcherAddr != address(0) && IERC20(governanceToken).transfer(researcherAddr, rewardPerResearcher)) {
                    // Update researcher reputation for success
                    researcherProfiles[researcherAddr].reputationPoints = researcherProfiles[researcherAddr].reputationPoints.add(10);
                    emit ReputationPointsAwarded(researcherAddr, 10);
                }
            }
        }

        // Calculate rewards for funders
        uint256 funderReward = totalRewardsPool.mul(funderRewardPercentageBps).div(10000);
        for (uint256 i = 0; i < project.funders.length; i++) {
            address funder = project.funders[i];
            uint256 individualFunderShare = funderReward.mul(project.funderContributions[funder]).div(totalRewardsPool);
            require(IERC20(governanceToken).transfer(funder, individualFunderShare), "Funder reward transfer failed");
        }

        // Calculate rewards for governance
        uint256 governanceReward = totalRewardsPool.mul(governanceRewardPercentageBps).div(10000);
        require(IERC20(governanceToken).transfer(darlTreasury, governanceReward), "Governance reward transfer failed");

        // Any remaining funds (due to rounding or if percentages < 100%) go to treasury
        uint256 remainingFunds = totalRewardsPool
            .sub(researcherReward)
            .sub(funderReward)
            .sub(governanceReward);
        if (remainingFunds > 0) {
            require(IERC20(governanceToken).transfer(darlTreasury, remainingFunds), "Remaining funds transfer failed");
        }

        emit ProjectRewardsDistributed(_projectId, totalRewardsPool);
    }

    /**
     * @notice Allows the owner of a project IP NFT to record a licensing agreement on-chain.
     *         The actual royalty payment mechanism would be external (e.g., streaming payments, manual transfer).
     * @param _ipNftId The ID of the IP NFT.
     * @param _licensee The address of the licensee.
     * @param _termsHash IPFS hash for the detailed licensing terms.
     * @param _royaltyPercentageBps Royalty percentage in basis points (e.g., 100 = 1%).
     * @param _endTime The timestamp when the license expires (0 for perpetual).
     */
    function recordIPLicense(
        uint256 _ipNftId,
        address _licensee,
        string calldata _termsHash,
        uint256 _royaltyPercentageBps,
        uint256 _endTime
    ) external onlyIpNftOwner(_ipNftId) {
        require(_licensee != address(0), "Invalid licensee address");
        require(_royaltyPercentageBps <= MAX_ROYALTY_PERCENTAGE_BPS, "Royalty percentage exceeds max allowed");
        require(bytes(_termsHash).length > 0, "Licensing terms hash cannot be empty");
        require(_endTime == 0 || _endTime > block.timestamp, "License end time must be in the future or 0 for perpetual");

        uint256 licenseId = nextIpLicenseId[_ipNftId]++;
        IPLicense storage newLicense = ipNftLicenses[_ipNftId][licenseId];

        newLicense.licensee = _licensee;
        newLicense.termsHash = _termsHash;
        newLicense.royaltyPercentageBps = _royaltyPercentageBps;
        newLicense.startTime = block.timestamp;
        newLicense.endTime = _endTime;
        newLicense.active = true;

        emit IPLicenseRecorded(_ipNftId, licenseId, _licensee, _royaltyPercentageBps);
    }

    /**
     * @notice Enables the IP NFT owner to collect specified royalties from licensing agreements.
     *         This function assumes royalties are sent to the DARL contract, which then forwards to the owner.
     *         In a real scenario, this would likely involve a separate payment processor or agreement.
     * @param _ipNftId The ID of the IP NFT.
     * @param _licenseId The ID of the specific license.
     * @param _amount The amount of royalty to collect.
     */
    function collectIPRoyalty(uint256 _ipNftId, uint256 _licenseId, uint256 _amount) external onlyIpNftOwner(_ipNftId) nonReentrant {
        IPLicense storage license = ipNftLicenses[_ipNftId][_licenseId];
        require(license.active, "License not active");
        require(license.endTime == 0 || license.endTime > block.timestamp, "License has expired");
        require(_amount > 0, "Amount must be greater than zero");

        // The actual royalty calculation based on license terms would be off-chain,
        // this function is for the owner to "pull" already deposited royalties into the contract.
        // For simplicity, we assume the funds are already in this contract from the licensee.
        // A robust system would require the licensee to explicitly `transferAndCollectRoyalty`.

        require(IERC20(governanceToken).transfer(_msgSender(), _amount), "Royalty transfer failed");
        emit IPRoyaltyCollected(_ipNftId, _licenseId, _msgSender(), _amount);
    }

    // --- IV. Reputation & Researcher Management Functions ---

    /**
     * @notice Allows users to create a public researcher profile.
     * @param _profileHash IPFS hash to their credentials/expertise.
     */
    function registerResearcherProfile(string calldata _profileHash) external {
        require(!researcherProfiles[_msgSender()].isRegistered, "Researcher already registered");
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty");

        researcherProfiles[_msgSender()].profileHash = _profileHash;
        researcherProfiles[_msgSender()].reputationPoints = 0; // Start with 0 points
        researcherProfiles[_msgSender()].isRegistered = true;

        emit ResearcherProfileRegistered(_msgSender(), _profileHash);
    }

    /**
     * @notice (Governance-only) Awards reputation points to researchers.
     * @param _researcher The address of the researcher.
     * @param _points The number of points to award.
     */
    function awardReputationPoints(address _researcher, uint256 _points) external onlyGovernanceCouncil {
        require(researcherProfiles[_researcher].isRegistered, "Researcher not registered");
        require(_points > 0, "Points must be greater than zero");

        researcherProfiles[_researcher].reputationPoints = researcherProfiles[_researcher].reputationPoints.add(_points);
        emit ReputationPointsAwarded(_researcher, _points);
    }

    /**
     * @notice (Governance-only) Deducts reputation points from researchers.
     * @param _researcher The address of the researcher.
     * @param _points The number of points to slash.
     */
    function slashReputationPoints(address _researcher, uint256 _points) external onlyGovernanceCouncil {
        require(researcherProfiles[_researcher].isRegistered, "Researcher not registered");
        require(_points > 0, "Points must be greater than zero");

        researcherProfiles[_researcher].reputationPoints = researcherProfiles[_researcher].reputationPoints.sub(
            _points > researcherProfiles[_researcher].reputationPoints ? researcherProfiles[_researcher].reputationPoints : _points
        );
        emit ReputationPointsSlashed(_researcher, _points);
    }

    // --- V. Governance & Utility Functions ---

    /**
     * @notice Allows the governance council to update various project-related parameters.
     * @param _paramName The name of the parameter to update (e.g., "proposalVoteThreshold").
     * @param _newValue The new value for the parameter.
     */
    function setProjectParameter(string calldata _paramName, uint256 _newValue) external onlyGovernanceCouncil {
        uint256 oldValue;
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalVoteThreshold"))) {
            oldValue = proposalVoteThreshold;
            proposalVoteThreshold = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minStakedTokensForVote"))) {
            oldValue = minStakedTokensForVote;
            minStakedTokensForVote = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("projectFundingFeeBps"))) {
            require(_newValue <= 10000, "Fee percentage cannot exceed 100%");
            oldValue = projectFundingFeeBps;
            projectFundingFeeBps = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("researcherRewardPercentageBps"))) {
            require(_newValue <= 10000, "Reward percentage cannot exceed 100%");
            oldValue = researcherRewardPercentageBps;
            researcherRewardPercentageBps = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("funderRewardPercentageBps"))) {
            require(_newValue <= 10000, "Reward percentage cannot exceed 100%");
            oldValue = funderRewardPercentageBps;
            funderRewardPercentageBps = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("governanceRewardPercentageBps"))) {
            require(_newValue <= 10000, "Reward percentage cannot exceed 100%");
            oldValue = governanceRewardPercentageBps;
            governanceRewardPercentageBps = _newValue;
        } else {
            revert("Unknown parameter name");
        }
        // Re-check total reward percentage sum after individual updates
        require(
            researcherRewardPercentageBps.add(funderRewardPercentageBps).add(governanceRewardPercentageBps) <= 10000,
            "Total reward percentages exceed 100%"
        );
        emit ProjectParameterSet(_paramName, oldValue, _newValue);
    }

    /**
     * @notice Permits the governance council to withdraw funds from the general DARL treasury.
     *         These are funds collected from fees or unallocated rewards.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of funds to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyGovernanceCouncil nonReentrant {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(IERC20(governanceToken).balanceOf(address(this)) >= _amount, "Insufficient funds in contract");
        require(IERC20(governanceToken).transfer(_recipient, _amount), "Treasury fund withdrawal failed");
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    /**
     * @notice Allows funders to claim back their unspent contributions if a project is cancelled or fails to start.
     * @param _projectId The ID of the project.
     */
    function claimUnusedProjectFunds(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Cancelled || project.status == ProjectStatus.Failed || project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Funding, "Funds can only be claimed for cancelled, failed or unstarted projects");

        uint256 contribution = project.funderContributions[_msgSender()];
        require(contribution > 0, "No contribution found for this address in this project");

        // Set contribution to 0 before transfer to prevent reentrancy (even with nonReentrant)
        project.funderContributions[_msgSender()] = 0;

        require(IERC20(governanceToken).transfer(_msgSender(), contribution), "Fund reclaim failed");
        emit UnusedProjectFundsClaimed(_projectId, _msgSender(), contribution);
    }

    // --- VI. View Functions ---

    /**
     * @notice Retrieves all stored information about a specific project.
     * @param _projectId The ID of the project.
     * @return name_ Project name.
     * @return descriptionHash_ IPFS hash.
     * @return projectLead_ Address of the project lead.
     * @return requiredFunding_ Total funding required.
     * @return fundedAmount_ Current funded amount.
     * @return startTime_ Project start time.
     * @return duration_ Project duration.
     * @return milestoneCount_ Number of milestones.
     * @return status_ Current project status.
     * @return expectedIPType_ Type of expected IP.
     * @return ipNftId_ ID of the minted IP NFT (0 if none).
     */
    function getProjectDetails(uint256 _projectId)
        public view
        returns (
            string memory name_,
            string memory descriptionHash_,
            address projectLead_,
            uint256 requiredFunding_,
            uint256 fundedAmount_,
            uint256 startTime_,
            uint256 duration_,
            uint256 milestoneCount_,
            ProjectStatus status_,
            string memory expectedIPType_,
            uint256 ipNftId_
        )
    {
        Project storage project = projects[_projectId];
        name_ = project.name;
        descriptionHash_ = project.descriptionHash;
        projectLead_ = project.projectLead;
        requiredFunding_ = project.requiredFunding;
        fundedAmount_ = project.fundedAmount;
        startTime_ = project.startTime;
        duration_ = project.duration;
        milestoneCount_ = project.milestoneCount;
        status_ = project.status;
        expectedIPType_ = project.expectedIPType;
        ipNftId_ = project.ipNftId;
    }

    /**
     * @notice Retrieves the IPFS hash associated with a researcher's public profile and their current reputation points.
     * @param _researcher The address of the researcher.
     * @return profileHash_ IPFS hash for the researcher's profile.
     * @return reputationPoints_ Current reputation points.
     * @return isRegistered_ Whether the researcher is registered.
     */
    function getResearcherProfile(address _researcher)
        public view
        returns (string memory profileHash_, uint256 reputationPoints_, bool isRegistered_)
    {
        ResearcherProfile storage profile = researcherProfiles[_researcher];
        profileHash_ = profile.profileHash;
        reputationPoints_ = profile.reputationPoints;
        isRegistered_ = profile.isRegistered;
    }

    /**
     * @notice Retrieves the details of a specific milestone within a project.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @return reportHash_ IPFS hash for the milestone report.
     * @return dataHashes_ Array of IPFS hashes for associated data.
     * @return status_ Current status of the milestone.
     * @return reviewDeadline_ Deadline for milestone review.
     * @return fundsReleased_ Whether funds for this milestone have been released.
     */
    function getProjectMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)
        public view
        returns (
            string memory reportHash_,
            string[] memory dataHashes_,
            MilestoneStatus status_,
            uint256 reviewDeadline_,
            bool fundsReleased_
        )
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestoneCount, "Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        reportHash_ = milestone.reportHash;
        dataHashes_ = milestone.dataHashes;
        status_ = milestone.status;
        reviewDeadline_ = milestone.reviewDeadline;
        fundsReleased_ = milestone.fundsReleased;
    }

    /**
     * @notice Retrieves a list of all IP NFT IDs that have been minted for a given project.
     * @param _projectId The ID of the project.
     * @return ipNftId_ The ID of the IP NFT (0 if not minted).
     */
    function getProjectIPs(uint256 _projectId) public view returns (uint256 ipNftId_) {
        return projects[_projectId].ipNftId;
    }

    /**
     * @notice Retrieves the individual funding contribution of an address to a project.
     * @param _projectId The ID of the project.
     * @param _funder The address of the funder.
     * @return contribution_ The amount contributed by the funder.
     */
    function getProjectContributions(uint256 _projectId, address _funder) public view returns (uint256 contribution_) {
        return projects[_projectId].funderContributions[_funder];
    }

    /**
     * @notice Retrieves all researchers currently registered as participants for a project.
     * @param _projectId The ID of the project.
     * @return researchers_ An array of addresses of researchers on the project.
     */
    function getProjectResearchers(uint256 _projectId) public view returns (address[] memory researchers_) {
        Project storage project = projects[_projectId];
        uint256 count = 0;
        // Count valid researchers
        for (uint256 i = 0; i < nextProjectId; i++) { // Iterating all possible addresses isn't feasible.
            // This would require explicit tracking in an array. For now, we simulate.
            // A more robust solution would be `mapping(uint256 => address[]) public projectResearcherList;`
            // and add/remove from there.
            // For now, assume a small set of project researchers that are known.
            // Simplified: return project lead and rely on internal logic for others.
        }
        // As a simplification, we can only return the project lead for this function.
        // A better design would maintain an array of researcher addresses within the Project struct.
        address[] memory tempResearchers = new address[](1);
        tempResearchers[0] = project.projectLead;
        return tempResearchers;
    }
}
```