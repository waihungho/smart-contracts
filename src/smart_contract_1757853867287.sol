This smart contract, **DeSciNexusDAO**, is a sophisticated decentralized autonomous organization designed to foster and fund scientific research and development. It integrates advanced concepts such as AI-powered reputation systems, Soulbound Tokens (SBTs) for researcher achievements, and Dynamic NFTs (DNFTs) for project funding and status representation. The platform allows researchers to propose projects, receive community funding, and track progress via milestones. AI oracles assist in objective evaluation and reputation scoring, while a robust governance mechanism ensures community oversight and decentralized decision-making.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Strings.sol"; // For int to string conversion in URI updates

// --- INTERFACES ---

// Placeholder for an AI Oracle interface
// In a real scenario, this would likely be a Chainlink VRF/Keepers/Functions consumer,
// or a custom oracle network. This interface assumes the oracle will call back
// a specific function on the DeSciNexusDAO contract with the result.
interface IAIOracle {
    function requestEvaluation(address target, uint256 projectId, string memory context) external returns (bytes32 requestId);
    // The oracle would call back to a function like `_receiveAIEvaluation` on the main contract.
}

// Simple Governance Interface (could be a full DAO contract in a real system like Compound's Governor)
interface IGovernance {
    function createProposal(bytes memory callData, string memory description) external returns (uint256 proposalId);
    function vote(uint256 proposalId, bool support) external;
    function executeProposal(uint256 proposalId) external;
    function getProposalState(uint256 proposalId) external view returns (uint8); // Example: 0=Pending, 1=Active, 2=Succeeded, 3=Executed, 4=Failed
}


/*
Contract Name: DeSciNexusDAO
Version: 1.0.0
Description:
DeSciNexusDAO is a sophisticated, decentralized autonomous organization designed to foster and fund scientific research and development.
It integrates cutting-edge concepts like AI-powered reputation systems, Soulbound Tokens (SBTs) for researcher achievements,
and Dynamic NFTs (DNFTs) for project funding and status representation. The platform allows researchers to propose projects,
receive community funding, and track progress via milestones. AI oracles assist in objective evaluation and reputation
scoring, while a robust governance mechanism ensures community oversight and decentralized decision-making.

Outline:
I. Core Infrastructure & Access Control
    - Manages contract ownership, administrative roles, and pausing functionality.
    - `Ownable` and `Pausable` OpenZeppelin contracts are leveraged.
II. Research Project Management
    - Enables researchers to submit, manage, and receive funding for their projects.
    - Includes milestone tracking, community review, and dynamic fund releases.
III. AI-Powered Reputation & Soulbound Tokens (SBTs)
    - Leverages AI oracles for researcher and project evaluation.
    - Issues non-transferable SBTs as immutable on-chain achievements and reputation markers.
IV. Dynamic Project NFTs (DNFTs)
    - Mints unique, evolving NFTs to project contributors.
    - These NFTs visually change based on project progress, funding, and AI-driven sentiment.
V. Governance & Community Interaction
    - Facilitates decentralized decision-making through proposals and voting.
    - Includes mechanisms for dispute resolution and reporting misconduct.
VI. Custom ERC721 Implementations
    - `DeSciSBT` for Soulbound Tokens (non-transferable).
    - `ProjectDNFT` for Dynamic NFTs (metadata updates based on project state).

Function Summary:

I. Core Infrastructure & Access Control
1.  `constructor()`: Initializes the contract, setting the deployer as owner and initial AI oracle/governance addresses.
2.  `updateAIOracleAddress(address _newOracle)`: Allows the owner to update the address of the AI oracle contract.
3.  `updateGovernanceAddress(address _newGovernance)`: Allows the owner to update the address of the governance contract.
4.  `pause()`: Pauses core contract functionalities, preventing state changes (Owner/Admin).
5.  `unpause()`: Unpauses the contract, re-enabling functionalities (Owner/Admin).
6.  `addAdmin(address _admin)`: Grants administrative privileges to an address (Owner).
7.  `removeAdmin(address _admin)`: Revokes administrative privileges from an address (Owner).

II. Research Project Management
8.  `submitResearchProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _fundingGoal, uint256[] memory _milestoneAmounts, string[] memory _milestoneDescriptions)`: Submits a new research project proposal by a researcher.
9.  `approveProposalSubmission(uint256 _projectId)`: Approves a submitted proposal, making it eligible for funding (Admin/Governance).
10. `fundProject(uint256 _projectId)`: Allows community members to contribute ETH to an approved project.
11. `submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofIPFSHash)`: Researcher submits proof for a completed milestone.
12. `reviewMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, bool _approved)`: Community/designated reviewers approve or reject a milestone proof.
13. `releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex)`: Releases funds for a successfully reviewed milestone (Admin/Governance decision, potentially AI-assisted).
14. `requestProjectUpdate(uint256 _projectId)`: Anyone can request an update from the project researcher (signal only).
15. `submitProjectUpdate(uint256 _projectId, string memory _updateIPFSHash)`: Researcher provides a project update via IPFS hash.

III. AI-Powered Reputation & Soulbound Tokens (SBTs)
16. `requestAIEvaluation(address _target, uint256 _projectId, string memory _context)`: Triggers an AI oracle request for evaluation (e.g., researcher performance, project progress) by an Admin.
17. `_receiveAIEvaluation(bytes32 _requestId, address _target, uint256 _projectId, int256 _score, string memory _reason)`: Internal callback called by the AI oracle to deliver evaluation results, updates researcher scores and project AI state.
18. `issueReputationBadgeSBT(address _recipient, uint256 _badgeType, string memory _metadataURI)`: Mints a non-transferable SBT badge to a researcher for achievements (Admin).
19. `revokeReputationBadgeSBT(uint256 _badgeId)`: Revokes a specific SBT badge (Admin/Governance, e.g., for misconduct).
20. `getResearcherReputationScore(address _researcher)`: Retrieves the current aggregated reputation score of a researcher.
21. `getResearcherSBTs(address _researcher)`: Returns all SBT badge IDs held by a researcher using `ERC721Enumerable`.

IV. Dynamic Project NFTs (DNFTs)
22. `mintProjectDNFT(uint256 _projectId, address _to)`: Mints a unique Dynamic Project NFT to a funder/contributor.
23. `_updateProjectDNFTMetadata(uint256 _projectId, string memory _newURI)`: Internal function to update the metadata URI for all DNFTs associated with a project. Triggered by milestones, funding, or AI.
24. `signalProjectDisapproval(uint256 _nftId)`: Allows a DNFT holder to signal disapproval for a project (emits event, triggers AI evaluation).
25. `getCurrentProjectDNFTURI(uint256 _nftId)`: Retrieves the current metadata URI for a specific Project DNFT.

V. Governance & Community Interaction
26. `submitGovernanceProposal(bytes memory _callData, string memory _description)`: Allows privileged accounts (Admins, high-reputation researchers) to submit governance proposals.
27. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows eligible participants to vote on active governance proposals.
28. `executeGovernanceProposal(uint256 _proposalId)`: Executes a successfully voted governance proposal.
29. `reportMisconduct(uint256 _projectId, address _researcher, string memory _reportIPFSHash)`: Allows anyone to report misconduct against a researcher/project.
30. `resolveDispute(uint256 _reportId, bool _sanction, address _target, int256 _reputationImpact)`: Admin/Governance resolves a report, potentially applying sanctions or reputation penalties.
31. `allocateResearcherClaimableBalance(address _researcher, uint256 _amount)`: Admin function to credit claimable funds to a researcher (e.g., for bonuses or special grants).
32. `withdrawFundsAsResearcher()`: Allows a researcher to withdraw specifically allocated claimable funds.
33. `withdrawExcessFundsAsFunder(uint256 _projectId)`: Allows funders to withdraw their proportional share of any excess or unspent project funds if a project completes or fails.
34. `initializeTokenContracts(address _sbtAddress, address _dnftAddress)`: Owner sets the addresses of the deployed SBT and DNFT contracts.

*/


// --- Custom ERC721 for Soulbound Tokens (SBTs) ---
// This contract is Ownable, and its owner will be the DeSciNexusDAO contract after deployment.
contract DeSciSBT is ERC721Enumerable, Ownable {
    constructor() ERC721("DeSciNexus SBT", "DSBT") Ownable(msg.sender) {} // Deployer is initial owner

    // Only the owner (DeSciNexusDAO) can mint new SBTs
    function mint(address to, uint256 tokenId, string memory uri) external onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Only the owner (DeSciNexusDAO) can burn SBTs
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    // Override _beforeTokenTransfer to prevent transfers, making them soulbound.
    // Allow minting (from address(0)) and burning (to address(0)).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(from == address(0) || to == address(0), "DeSciSBT: SBTs are non-transferable");
    }

    // Function to set tokenURI, callable by owner
    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }
}

// --- Custom ERC721 for Dynamic Project NFTs (DNFTs) ---
// This contract is Ownable, and its owner will be the DeSciNexusDAO contract after deployment.
contract ProjectDNFT is ERC721, Ownable {
    // Mapping from projectId to its current base URI for all associated NFTs
    mapping(uint256 => string) private _projectTokenURIs;
    // Mapping from NFT tokenId to the projectId it belongs to
    mapping(uint256 => uint256) private _nftToProjectId;

    constructor() ERC721("DeSci Project DNFT", "DPNFT") Ownable(msg.sender) {} // Deployer is initial owner

    // Only the owner (DeSciNexusDAO) can mint new DNFTs
    function mint(address to, uint256 tokenId, uint256 projectId) external onlyOwner {
        _safeMint(to, tokenId);
        _nftToProjectId[tokenId] = projectId; // Link NFT to project
    }

    // Only the owner (DeSciNexusDAO) can update project-wide metadata URI
    function setProjectTokenURI(uint256 projectId, string memory newURI) external onlyOwner {
        _projectTokenURIs[projectId] = newURI;
    }

    function getProjectIdForNFT(uint256 nftId) external view returns (uint256) {
        return _nftToProjectId[nftId];
    }

    // Override tokenURI to provide dynamic metadata based on project progress
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 projectId = _nftToProjectId[tokenId];
        string memory currentURI = _projectTokenURIs[projectId];
        require(bytes(currentURI).length > 0, "ProjectDNFT: No URI set for this project yet.");
        return currentURI;
    }
}


// --- Main DeSciNexusDAO Contract ---
contract DeSciNexusDAO is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- I. Core Infrastructure & Access Control ---
    address public aiOracleAddress;
    address public governanceAddress; // Address of the external Governance contract
    mapping(address => bool) public admins;

    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event GovernanceAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event TokenContractsInitialized(address indexed sbtAddress, address indexed dnftAddress);

    modifier onlyAdmin() {
        require(admins[msg.sender] || owner() == msg.sender, "DeSciNexusDAO: Only admin or owner can perform this action");
        _;
    }

    constructor(address _initialAIOracle, address _initialGovernance) Ownable(msg.sender) {
        aiOracleAddress = _initialAIOracle;
        governanceAddress = _initialGovernance;
        admins[msg.sender] = true; // Deployer is also an admin by default
        emit AIOracleAddressUpdated(address(0), _initialAIOracle);
        emit GovernanceAddressUpdated(address(0), _initialGovernance);
    }

    function updateAIOracleAddress(address _newOracle) external only_owner {
        require(_newOracle != address(0), "DeSciNexusDAO: AI Oracle cannot be zero address");
        emit AIOracleAddressUpdated(aiOracleAddress, _newOracle);
        aiOracleAddress = _newOracle;
    }

    function updateGovernanceAddress(address _newGovernance) external only_owner {
        require(_newGovernance != address(0), "DeSciNexusDAO: Governance cannot be zero address");
        emit GovernanceAddressUpdated(governanceAddress, _newGovernance);
        governanceAddress = _newGovernance;
    }

    function addAdmin(address _admin) external only_owner {
        require(_admin != address(0), "DeSciNexusDAO: Cannot add zero address as admin");
        require(!admins[_admin], "DeSciNexusDAO: Address is already an admin");
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external only_owner {
        require(_admin != address(0), "DeSciNexusDAO: Cannot remove zero address as admin");
        require(admins[_admin], "DeSciNexusDAO: Address is not an admin");
        require(_admin != owner(), "DeSciNexusDAO: Cannot remove owner from admin role"); // Owner is always an admin
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }


    // --- II. Research Project Management ---
    struct Milestone {
        uint256 amount;
        string description;
        bool completed;
        bool approved;
        string proofIPFSHash;
        address[] reviewers;
    }

    enum ProjectStatus { PendingApproval, Approved, Funding, Active, Completed, Cancelled }

    struct ResearchProject {
        address researcher;
        string title;
        string description;
        string ipfsHash;
        uint256 fundingGoal;
        uint256 fundedAmount; // This is the currently held ETH for the project, decreases upon milestone release
        uint256 initialTotalContributions; // Total ETH received for the project, used for funder refund proportionality
        Milestone[] milestones;
        ProjectStatus status;
        address[] funders; // List of unique funders (for `withdrawExcessFundsAsFunder`)
        mapping(address => uint256) funderContributions; // How much each funder contributed originally
        string currentDNFTMetadataURI;
        bytes32 currentAIEvaluationRequestId;
        int256 aiEvaluationScore;
        string aiEvaluationReason;
    }

    Counters.Counter private _projectIdCounter;
    mapping(uint256 => ResearchProject) public projects;
    mapping(bytes32 => uint256) private _aiRequestIdToProjectId; // Map AI request IDs to projects

    event ProjectSubmitted(uint256 indexed projectId, address indexed researcher, string title, uint256 fundingGoal);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneProofSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed submitter, string proofIPFSHash);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reviewer, bool approved);
    event MilestoneFundingReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectUpdated(uint256 indexed projectId, address indexed updater, string updateIPFSHash);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);

    function submitResearchProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _fundingGoal,
        uint256[] memory _milestoneAmounts,
        string[] memory _milestoneDescriptions
    ) external whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "DeSciNexusDAO: Title cannot be empty");
        require(_fundingGoal > 0, "DeSciNexusDAO: Funding goal must be greater than zero");
        require(_milestoneAmounts.length == _milestoneDescriptions.length, "DeSciNexusDAO: Milestone arrays mismatch");
        uint256 totalMilestoneAmount;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            require(_milestoneAmounts[i] > 0, "DeSciNexusDAO: Milestone amount must be greater than zero");
            totalMilestoneAmount += _milestoneAmounts[i];
        }
        require(totalMilestoneAmount == _fundingGoal, "DeSciNexusDAO: Total milestone amounts must equal funding goal");

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        Milestone[] memory newMilestones = new Milestone[](_milestoneAmounts.length);
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            newMilestones[i] = Milestone({
                amount: _milestoneAmounts[i],
                description: _milestoneDescriptions[i],
                completed: false,
                approved: false,
                proofIPFSHash: "",
                reviewers: new address[](0)
            });
        }

        projects[newProjectId] = ResearchProject({
            researcher: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            fundingGoal: _fundingGoal,
            fundedAmount: 0,
            initialTotalContributions: 0,
            milestones: newMilestones,
            status: ProjectStatus.PendingApproval,
            funders: new address[](0),
            funderContributions: new mapping(address => uint256),
            currentDNFTMetadataURI: "",
            currentAIEvaluationRequestId: bytes32(0),
            aiEvaluationScore: 0,
            aiEvaluationReason: ""
        });

        emit ProjectSubmitted(newProjectId, msg.sender, _title, _fundingGoal);
        return newProjectId;
    }

    function approveProposalSubmission(uint256 _projectId) external onlyAdmin whenNotPaused {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(project.status == ProjectStatus.PendingApproval, "DeSciNexusDAO: Project not in pending approval status");

        project.status = ProjectStatus.Funding;
        emit ProjectApproved(_projectId);
        emit ProjectStatusChanged(_projectId, ProjectStatus.Funding);
    }

    function fundProject(uint256 _projectId) external payable whenNotPaused nonReentrant {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(project.status == ProjectStatus.Funding || project.status == ProjectStatus.Active, "DeSciNexusDAO: Project not open for funding");
        require(msg.value > 0, "DeSciNexusDAO: Must send ETH to fund project");
        require(project.fundedAmount + msg.value <= project.fundingGoal * 2, "DeSciNexusDAO: Funding amount exceeds double the goal"); // Cap overfunding

        // Record funder contribution
        if (project.funderContributions[msg.sender] == 0) {
            project.funders.push(msg.sender);
            issueReputationBadgeSBT(msg.sender, 1, "ipfs://QmFundingContributorBadge"); // Issue a generic contributor badge
        }
        project.funderContributions[msg.sender] += msg.value;
        project.fundedAmount += msg.value;
        project.initialTotalContributions += msg.value; // Track total contributions received

        // Mint DNFT to funder
        mintProjectDNFT(_projectId, msg.sender);

        if (project.status == ProjectStatus.Funding && project.fundedAmount >= project.fundingGoal) {
            project.status = ProjectStatus.Active;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Active);
            _updateProjectDNFTMetadata(_projectId, "ipfs://QmDNFTFunded");
        }

        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    function submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _proofIPFSHash) external whenNotPaused {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher == msg.sender, "DeSciNexusDAO: Only the researcher can submit milestone proofs");
        require(project.status == ProjectStatus.Active, "DeSciNexusDAO: Project not active");
        require(_milestoneIndex < project.milestones.length, "DeSciNexusDAO: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].completed, "DeSciNexusDAO: Milestone already completed");
        require(bytes(_proofIPFSHash).length > 0, "DeSciNexusDAO: Proof IPFS hash cannot be empty");
        require(aiOracleAddress != address(0), "DeSciNexusDAO: AI Oracle address not set");

        project.milestones[_milestoneIndex].proofIPFSHash = _proofIPFSHash;
        emit MilestoneProofSubmitted(_projectId, _milestoneIndex, msg.sender, _proofIPFSHash);

        bytes32 reqId = IAIOracle(aiOracleAddress).requestEvaluation(msg.sender, _projectId, string(abi.encodePacked("MilestoneProof_", Strings.toString(_milestoneIndex), "_", _proofIPFSHash)));
        _aiRequestIdToProjectId[reqId] = _projectId;
        project.currentAIEvaluationRequestId = reqId;
    }

    // Community members or designated reviewers can review milestones
    function reviewMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, bool _approved) external whenNotPaused {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(msg.sender != project.researcher, "DeSciNexusDAO: Researcher cannot review their own milestone");
        require(project.status == ProjectStatus.Active, "DeSciNexusDAO: Project not active");
        require(_milestoneIndex < project.milestones.length, "DeSciNexusDAO: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].completed, "DeSciNexusDAO: Milestone already completed");
        require(aiOracleAddress != address(0), "DeSciNexusDAO: AI Oracle address not set");

        project.milestones[_milestoneIndex].approved = _approved;
        project.milestones[_milestoneIndex].reviewers.push(msg.sender);

        emit MilestoneReviewed(_projectId, _milestoneIndex, msg.sender, _approved);

        bytes32 reqId = IAIOracle(aiOracleAddress).requestEvaluation(project.researcher, _projectId, string(abi.encodePacked("MilestoneReviewed_", Strings.toString(_milestoneIndex), "_Approved:", _approved ? "true" : "false")));
        _aiRequestIdToProjectId[reqId] = _projectId;
        project.currentAIEvaluationRequestId = reqId;
    }

    function releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex) external onlyAdmin whenNotPaused nonReentrant {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(project.status == ProjectStatus.Active, "DeSciNexusDAO: Project not active");
        require(_milestoneIndex < project.milestones.length, "DeSciNexusDAO: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].completed, "DeSciNexusDAO: Milestone already completed");
        require(project.milestones[_milestoneIndex].approved, "DeSciNexusDAO: Milestone not yet approved");
        require(project.fundedAmount >= project.milestones[_milestoneIndex].amount, "DeSciNexusDAO: Insufficient funds for milestone release");

        uint256 amountToRelease = project.milestones[_milestoneIndex].amount;
        project.milestones[_milestoneIndex].completed = true;
        project.fundedAmount -= amountToRelease;

        (bool success, ) = project.researcher.call{value: amountToRelease}("");
        require(success, "DeSciNexusDAO: Failed to send ETH to researcher");

        emit MilestoneFundingReleased(_projectId, _milestoneIndex, amountToRelease);

        _updateProjectDNFTMetadata(_projectId, string(abi.encodePacked("ipfs://QmDNFTMilestone_", Strings.toString(_milestoneIndex), "_Complete")));

        bool allMilestonesCompleted = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (!project.milestones[i].completed) {
                allMilestonesCompleted = false;
                break;
            }
        }

        if (allMilestonesCompleted) {
            project.status = ProjectStatus.Completed;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Completed);
            issueReputationBadgeSBT(project.researcher, 2, "ipfs://QmProjectCompletedBadge");
            _updateProjectDNFTMetadata(_projectId, "ipfs://QmDNFTCompleted");
        }
    }

    function requestProjectUpdate(uint256 _projectId) external view whenNotPaused {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(project.status == ProjectStatus.Active, "DeSciNexusDAO: Project not active");
        // An event could be emitted here to notify the researcher off-chain.
        // emit ProjectUpdateRequest(projectId, msg.sender);
    }

    function submitProjectUpdate(uint256 _projectId, string memory _updateIPFSHash) external whenNotPaused {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher == msg.sender, "DeSciNexusDAO: Only the researcher can submit updates");
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(project.status == ProjectStatus.Active, "DeSciNexusDAO: Project not active");
        require(bytes(_updateIPFSHash).length > 0, "DeSciNexusDAO: Update IPFS hash cannot be empty");
        require(aiOracleAddress != address(0), "DeSciNexusDAO: AI Oracle address not set");

        emit ProjectUpdated(_projectId, msg.sender, _updateIPFSHash);

        bytes32 reqId = IAIOracle(aiOracleAddress).requestEvaluation(msg.sender, _projectId, string(abi.encodePacked("ProjectUpdate_", _updateIPFSHash)));
        _aiRequestIdToProjectId[reqId] = _projectId;
        project.currentAIEvaluationRequestId = reqId;
    }


    // --- III. AI-Powered Reputation & Soulbound Tokens (SBTs) ---
    DeSciSBT public _sbt;
    mapping(address => int256) public researcherReputationScores;

    event ReputationScoreUpdated(address indexed researcher, int256 newScore, string reason);
    event SBTIssued(address indexed recipient, uint256 indexed badgeId, uint256 badgeType, string metadataURI);
    event SBTRevoked(uint256 indexed badgeId);

    function setSBTContract(DeSciSBT sbtAddress) external only_owner {
        require(address(_sbt) == address(0), "DeSciNexusDAO: SBT contract already set");
        _sbt = sbtAddress;
    }

    function requestAIEvaluation(address _target, uint256 _projectId, string memory _context) external onlyAdmin whenNotPaused returns (bytes32) {
        require(aiOracleAddress != address(0), "DeSciNexusDAO: AI Oracle address not set");
        bytes32 reqId = IAIOracle(aiOracleAddress).requestEvaluation(_target, _projectId, _context);
        _aiRequestIdToProjectId[reqId] = _projectId;
        return reqId;
    }

    // This function is intended to be called ONLY by the trusted AI Oracle contract
    function _receiveAIEvaluation(
        bytes32 _requestId,
        address _target,
        uint256 _projectId,
        int256 _score,
        string memory _reason
    ) external {
        require(msg.sender == aiOracleAddress, "DeSciNexusDAO: Only the AI Oracle can call this function");

        researcherReputationScores[_target] += _score;
        emit ReputationScoreUpdated(_target, researcherReputationScores[_target], _reason);

        if (_projectId != 0 && projects[_projectId].researcher != address(0)) {
            ResearchProject storage project = projects[_projectId];
            project.aiEvaluationScore = _score;
            project.aiEvaluationReason = _reason;

            string memory currentDNFTURI = project.currentDNFTMetadataURI;
            if (bytes(currentDNFTURI).length > 0) {
                if (_score > 0) {
                    _updateProjectDNFTMetadata(_projectId, string(abi.encodePacked(currentDNFTURI, "_AI_Positive_Score:", Strings.toString(_score))));
                } else if (_score < 0) {
                    _updateProjectDNFTMetadata(_projectId, string(abi.encodePacked(currentDNFTURI, "_AI_Negative_Score:", Strings.toString(_score))));
                }
            }
        }
        delete _aiRequestIdToProjectId[_requestId];
    }

    Counters.Counter private _sbtIdCounter;

    function issueReputationBadgeSBT(address _recipient, uint256 _badgeType, string memory _metadataURI) public onlyAdmin {
        require(address(_sbt) != address(0), "DeSciNexusDAO: SBT contract not set");
        require(_recipient != address(0), "DeSciNexusDAO: Cannot issue SBT to zero address");
        require(bytes(_metadataURI).length > 0, "DeSciNexusDAO: Metadata URI cannot be empty");

        _sbtIdCounter.increment();
        uint256 newBadgeId = _sbtIdCounter.current();
        _sbt.mint(_recipient, newBadgeId, _metadataURI);

        emit SBTIssued(_recipient, newBadgeId, _badgeType, _metadataURI);
    }

    function revokeReputationBadgeSBT(uint256 _badgeId) external onlyAdmin {
        require(address(_sbt) != address(0), "DeSciNexusDAO: SBT contract not set");
        // address holder = _sbt.ownerOf(_badgeId); // Not used directly, but good to know
        _sbt.burn(_badgeId); // Burn the SBT
        emit SBTRevoked(_badgeId);
    }

    function getResearcherReputationScore(address _researcher) external view returns (int256) {
        return researcherReputationScores[_researcher];
    }

    function getResearcherSBTs(address _researcher) external view returns (uint256[] memory) {
        require(address(_sbt) != address(0), "DeSciNexusDAO: SBT contract not set");
        uint256 balance = _sbt.balanceOf(_researcher);
        uint256[] memory sbtIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            sbtIds[i] = _sbt.tokenOfOwnerByIndex(_researcher, i);
        }
        return sbtIds;
    }


    // --- IV. Dynamic Project NFTs (DNFTs) ---
    ProjectDNFT public _dnft;
    Counters.Counter private _dnftIdCounter;

    event DNFTMinted(uint256 indexed projectId, address indexed recipient, uint256 indexed nftId);
    event DNFTMetadataUpdated(uint256 indexed projectId, string newURI);
    event DNFTDisapprovalSignaled(uint256 indexed nftId, address indexed signaler);

    function setDNFTContract(ProjectDNFT dnftAddress) external only_owner {
        require(address(_dnft) == address(0), "DeSciNexusDAO: DNFT contract already set");
        _dnft = dnftAddress;
    }

    function mintProjectDNFT(uint256 _projectId, address _to) public whenNotPaused returns (uint256) {
        require(address(_dnft) != address(0), "DeSciNexusDAO: DNFT contract not set");
        require(projects[_projectId].researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(_to != address(0), "DeSciNexusDAO: Cannot mint to zero address");

        _dnftIdCounter.increment();
        uint256 newNftId = _dnftIdCounter.current();

        _dnft.mint(_to, newNftId, _projectId);

        // Set initial URI if not already set by project status change
        if (bytes(projects[_projectId].currentDNFTMetadataURI).length > 0) {
            _dnft.setProjectTokenURI(_projectId, projects[_projectId].currentDNFTMetadataURI);
        } else {
             // Default URI if none set yet
             _dnft.setProjectTokenURI(_projectId, "ipfs://QmDefaultProjectDNFT");
             projects[_projectId].currentDNFTMetadataURI = "ipfs://QmDefaultProjectDNFT";
        }

        emit DNFTMinted(_projectId, _to, newNftId);
        return newNftId;
    }

    // Internal function to update metadata for all DNFTs of a given project
    function _updateProjectDNFTMetadata(uint256 _projectId, string memory _newURI) internal {
        require(address(_dnft) != address(0), "DeSciNexusDAO: DNFT contract not set");
        require(projects[_projectId].researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(bytes(_newURI).length > 0, "DeSciNexusDAO: New URI cannot be empty");
        _dnft.setProjectTokenURI(_projectId, _newURI);
        projects[_projectId].currentDNFTMetadataURI = _newURI;
        emit DNFTMetadataUpdated(_projectId, _newURI);
    }

    function signalProjectDisapproval(uint256 _nftId) external whenNotPaused {
        require(address(_dnft) != address(0), "DeSciNexusDAO: DNFT contract not set");
        require(_dnft.ownerOf(_nftId) == msg.sender, "DeSciNexusDAO: Only DNFT owner can signal disapproval");
        require(aiOracleAddress != address(0), "DeSciNexusDAO: AI Oracle address not set");

        emit DNFTDisapprovalSignaled(_nftId, msg.sender);

        uint256 projectId = _dnft.getProjectIdForNFT(_nftId);
        if (projectId != 0) {
            bytes32 reqId = IAIOracle(aiOracleAddress).requestEvaluation(projects[projectId].researcher, projectId, "Project_Disapproval_Signal");
            _aiRequestIdToProjectId[reqId] = projectId;
        }
    }

    function getCurrentProjectDNFTURI(uint256 _nftId) external view returns (string memory) {
        require(address(_dnft) != address(0), "DeSciNexusDAO: DNFT contract not set");
        return _dnft.tokenURI(_nftId);
    }

    // --- V. Governance & Community Interaction ---
    struct MisconductReport {
        uint256 projectId;
        address reportedResearcher;
        address reporter;
        string reportIPFSHash;
        bool resolved;
        bool sanctioned;
        int256 reputationImpact;
    }

    Counters.Counter private _reportIdCounter;
    mapping(uint256 => MisconductReport) public misconductReports;
    mapping(address => uint256) public researcherClaimableBalance; // Funds explicitly allocated to a researcher, withdrawable by them.
    event FundsWithdrawn(address indexed recipient, uint256 amount, string reason);


    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed submitter, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event MisconductReported(uint256 indexed reportId, uint256 indexed projectId, address indexed reportedResearcher);
    event DisputeResolved(uint256 indexed reportId, bool sanctioned, address indexed target, int256 reputationImpact);


    function submitGovernanceProposal(bytes memory _callData, string memory _description) external whenNotPaused returns (uint256) {
        // Eligibility: Admins, owner, or researchers with high reputation.
        require(admins[msg.sender] || owner() == msg.sender || researcherReputationScores[msg.sender] >= 500, "DeSciNexusDAO: Not eligible to submit proposals");
        require(governanceAddress != address(0), "DeSciNexusDAO: Governance contract not set");

        uint256 proposalId = IGovernance(governanceAddress).createProposal(_callData, _description);
        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        // Eligibility: Researchers with some reputation or anyone holding an SBT.
        require(governanceAddress != address(0), "DeSciNexusDAO: Governance contract not set");
        require(researcherReputationScores[msg.sender] >= 100 || (_sbt != address(0) && _sbt.balanceOf(msg.sender) > 0), "DeSciNexusDAO: Not eligible to vote");

        IGovernance(governanceAddress).vote(_proposalId, _support);
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused {
        require(governanceAddress != address(0), "DeSciNexusDAO: Governance contract not set");
        IGovernance(governanceAddress).executeProposal(_proposalId);
        emit GovernanceProposalExecuted(_proposalId);
    }


    function reportMisconduct(uint256 _projectId, address _reportedResearcher, string memory _reportIPFSHash) external whenNotPaused returns (uint256) {
        require(_reportedResearcher != address(0), "DeSciNexusDAO: Cannot report zero address");
        require(projects[_projectId].researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(msg.sender != _reportedResearcher, "DeSciNexusDAO: Cannot report self");
        require(bytes(_reportIPFSHash).length > 0, "DeSciNexusDAO: Report IPFS hash cannot be empty");
        require(aiOracleAddress != address(0), "DeSciNexusDAO: AI Oracle address not set");

        _reportIdCounter.increment();
        uint256 newReportId = _reportIdCounter.current();

        misconductReports[newReportId] = MisconductReport({
            projectId: _projectId,
            reportedResearcher: _reportedResearcher,
            reporter: msg.sender,
            reportIPFSHash: _reportIPFSHash,
            resolved: false,
            sanctioned: false,
            reputationImpact: 0
        });

        bytes32 reqId = IAIOracle(aiOracleAddress).requestEvaluation(_reportedResearcher, _projectId, string(abi.encodePacked("MisconductReport_", Strings.toString(newReportId), "_", _reportIPFSHash)));
        _aiRequestIdToProjectId[reqId] = _projectId;

        emit MisconductReported(newReportId, _projectId, _reportedResearcher);
        return newReportId;
    }

    function resolveDispute(uint256 _reportId, bool _sanction, address _target, int256 _reputationImpact) external onlyAdmin whenNotPaused {
        MisconductReport storage report = misconductReports[_reportId];
        require(report.reporter != address(0), "DeSciNexusDAO: Report does not exist");
        require(!report.resolved, "DeSciNexusDAO: Report already resolved");
        require(_target == report.reportedResearcher, "DeSciNexusDAO: Target must match reported researcher");
        require(address(_dnft) != address(0), "DeSciNexusDAO: DNFT contract not set");

        report.resolved = true;
        report.sanctioned = _sanction;
        report.reputationImpact = _reputationImpact;

        if (_sanction) {
            researcherReputationScores[_target] += _reputationImpact; // Apply negative impact
            _updateProjectDNFTMetadata(report.projectId, "ipfs://QmDNFTMisconduct"); // Update project DNFT to reflect issue
        }

        emit DisputeResolved(_reportId, _sanction, _target, _reputationImpact);
    }

    function allocateResearcherClaimableBalance(address _researcher, uint256 _amount) external onlyAdmin {
        require(_researcher != address(0), "DeSciNexusDAO: Cannot allocate to zero address.");
        researcherClaimableBalance[_researcher] += _amount;
    }

    function withdrawFundsAsResearcher() external nonReentrant {
        // This function allows a researcher to withdraw *approved bonuses or allocated funds*
        // that have been explicitly credited to them within this contract, *not* from project funds.
        require(researcherClaimableBalance[msg.sender] > 0, "DeSciNexusDAO: No claimable funds for this researcher.");

        uint256 amount = researcherClaimableBalance[msg.sender];
        researcherClaimableBalance[msg.sender] = 0; // Reset balance to prevent re-withdrawal

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "DeSciNexusDAO: Failed to withdraw researcher funds.");
        emit FundsWithdrawn(msg.sender, amount, "ResearcherClaim");
    }

    function withdrawExcessFundsAsFunder(uint256 _projectId) external nonReentrant {
        ResearchProject storage project = projects[_projectId];
        require(project.researcher != address(0), "DeSciNexusDAO: Project does not exist");
        require(project.status == ProjectStatus.Cancelled || project.status == ProjectStatus.Completed, "DeSciNexusDAO: Project must be cancelled or completed to withdraw excess funds.");
        
        uint256 funderInitialContribution = project.funderContributions[msg.sender]; 
        require(funderInitialContribution > 0, "DeSciNexusDAO: Caller did not fund this project or already withdrew.");

        require(project.fundedAmount > 0, "DeSciNexusDAO: No excess funds in this project.");
        require(project.initialTotalContributions > 0, "DeSciNexusDAO: No initial contributions recorded.");

        // Calculate funder's proportional share from the remaining 'fundedAmount' (which is the excess/unspent)
        uint256 funderShare = (funderInitialContribution * project.fundedAmount) / project.initialTotalContributions; 
        require(funderShare > 0, "DeSciNexusDAO: No withdrawable share for this funder.");

        project.fundedAmount -= funderShare; // Deduct from the project's remaining pool
        project.funderContributions[msg.sender] = 0; // Mark this funder's claim as fulfilled

        (bool success, ) = msg.sender.call{value: funderShare}("");
        require(success, "DeSciNexusDAO: Failed to send excess funds to funder");

        emit FundsWithdrawn(msg.sender, funderShare, "FunderExcess");
    }


    // --- Contract Setup ---
    // This function is called by the owner to set the addresses of the deployed SBT and DNFT contracts.
    // It is assumed that the owner has separately deployed DeSciSBT and ProjectDNFT,
    // and then transferred their ownership to THIS DeSciNexusDAO contract address
    // BEFORE calling this function.
    function initializeTokenContracts(address _sbtAddress, address _dnftAddress) external only_owner {
        require(_sbtAddress != address(0), "DeSciNexusDAO: SBT contract address cannot be zero");
        require(_dnftAddress != address(0), "DeSciNexusDAO: DNFT contract address cannot be zero");
        require(address(_sbt) == address(0), "DeSciNexusDAO: SBT contract already set");
        require(address(_dnft) == address(0), "DeSciNexusDAO: DNFT contract already set");

        _sbt = DeSciSBT(_sbtAddress);
        _dnft = ProjectDNFT(_dnftAddress);

        emit TokenContractsInitialized(_sbtAddress, _dnftAddress);
    }
}
```