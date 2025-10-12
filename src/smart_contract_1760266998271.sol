Here's a smart contract named `AetherForge` designed around the concepts of decentralized intellectual property management, collaborative creation, AI-assisted scoring, and dynamic royalties. It aims for uniqueness by integrating these various aspects into a single, cohesive system, focusing on the *internal logic* for managing these concepts rather than merely implementing existing ERC standards directly.

---

**Outline and Function Summary**

This contract, `AetherForge`, is a Decentralized Autonomous Intellectual Property & Collaborative Creation Engine. It facilitates collaborative artistic and intellectual projects, integrates AI contribution tracking, manages fractional ownership, dynamic licensing, and on-chain dispute resolution.

**Outline:**

1.  **I. Data Structures & Enums:** Defines the core entities like Project, Contribution, LicensingTerm, GrantedLicense, Dispute, and their states/roles.
2.  **II. Events:** Signals important state changes for off-chain monitoring and indexing.
3.  **III. Modifiers:** Restricts function access based on various roles (contract owner, project owner, contributor, AI oracle).
4.  **IV. Core State Variables:** Mappings and counters for projects, contributions, licensing terms, disputes, and reputation.
5.  **V. Owner / Admin Functions:** Functions for the contract deployer to manage global settings like AI Oracles and contract ownership.
6.  **VI. Project Management Functions:**
    *   Create, update, and manage the lifecycle of collaborative projects.
    *   Add/remove contributors, set project policies, delegate administrative roles.
    *   Link external governance tokens for project-specific decentralized decision-making.
7.  **VII. Contribution & Scoring Functions:**
    *   Allow contributors to submit their work (represented by content hashes).
    *   Enable project owners/delegated approvers to evaluate and score contributions, dynamically impacting ownership shares.
    *   Integrate AI Oracles to provide supplementary scores for contributions and overall project AI involvement.
8.  **VIII. Intellectual Property & Ownership Functions:**
    *   Finalize project IP by storing its immutable content hash.
    *   Manage fractional ownership shares among contributors, which are dynamically adjusted based on approved contributions.
    *   Provide functionality for transferring these fractional shares between participants.
9.  **IX. Licensing & Royalty Functions:**
    *   Define various customizable licensing terms (e.g., commercial, non-commercial, attribution-required) at a global level.
    *   Allow project owners to apply these general terms to their specific projects and grant formal licenses to users for set durations.
    *   Implement mechanisms to record revenue events for projects and enable project owners to distribute accumulated royalties proportionally to all shareholders.
10. **X. Dispute Resolution & Reputation Functions:**
    *   Provide an on-chain mechanism for project contributors to propose and vote on disputes related to contributions, their values, or other project disagreements.
    *   Maintain and update a reputation score for each contributor, which can indirectly influence future project involvement or rewards.
11. **XI. Utility & View Functions:**
    *   Comprehensive getter functions to query the detailed state of projects, contributions, licenses, disputes, and contributor data, enabling transparent access to all on-chain information.

---

**Function Summary (35 Functions):**

**V. Owner / Admin Functions:**
1.  `registerAIOracle(address _oracleAddress)`: Whitelists an address as an AI Oracle.
2.  `deregisterAIOracle(address _oracleAddress)`: Removes an address from the AI Oracle whitelist.
3.  `transferOwnership(address _newOwner)`: Transfers contract ownership.
4.  `createLicensingTerm(string memory _name, uint256 _royaltyRateBps, string memory _conditionsHash)`: Defines a new global licensing term.
5.  `updateContributorReputation(address _contributor, int256 _scoreChange)`: Adjusts a contributor's reputation score.

**VI. Project Management Functions:**
6.  `createProject(string memory _name, string memory _description, string memory _contributionPolicyHash)`: Initiates a new collaborative project.
7.  `updateProjectDetails(uint256 _projectId, string memory _newName, string memory _newDescription, string memory _newContributionPolicyHash)`: Modifies project descriptive details.
8.  `addContributorToProject(uint256 _projectId, address _contributor)`: Adds a new participant to a project.
9.  `removeContributorFromProject(uint256 _projectId, address _contributor)`: Removes a participant from a project.
10. `setProjectStatus(uint256 _projectId, ProjectStatus _newStatus)`: Changes the lifecycle status of a project.
11. `delegateProjectRole(uint256 _projectId, address _delegatee, ProjectRole _role)`: Delegates a specific role (e.g., Approver) within a project.
12. `setProjectGovernanceToken(uint256 _projectId, address _tokenAddress)`: Links an ERC-20 token for project-specific governance.

**VII. Contribution & Scoring Functions:**
13. `submitContribution(uint256 _projectId, string memory _contentHash, bool _isAIgenerated, uint256 _estimatedValue)`: Allows a contributor to submit work.
14. `approveContribution(uint256 _contributionId, uint256 _actualValueScore)`: Project owner/approver approves a contribution and assigns a value score.
15. `submitAIContributionScore(uint256 _contributionId, uint256 _aiScore)`: An AI Oracle submits a score for a specific contribution.
16. `submitProjectAIInvolvementScore(uint256 _projectId, uint256 _overallAIScore)`: An AI Oracle submits an overall AI involvement score for a project.

**VIII. Intellectual Property & Ownership Functions:**
17. `finalizeProjectIP(uint256 _projectId, string memory _finalIPHash)`: Marks a project as complete and records its final IP hash.
18. `initializeProjectFractionalOwnership(uint256 _projectId, uint256 _initialTotalShares)`: Sets up initial fractional ownership shares, typically for the creator.
19. `transferFractionalOwnership(uint256 _projectId, address _from, address _to, uint256 _shareAmount)`: Transfers a portion of project ownership shares.

**IX. Licensing & Royalty Functions:**
20. `applyLicensingTermToProject(uint256 _projectId, uint256 _termId)`: Associates an existing licensing term with a project.
21. `grantProjectLicense(uint256 _projectId, address _licensee, uint256 _termId, uint256 _durationSeconds)`: Grants a specific license to a user for a duration.
22. `recordRevenueEvent(uint256 _projectId, uint256 _amount)`: Records a revenue event for a project (sends `_amount` ETH to contract).
23. `distributeRoyalties(uint256 _projectId, address[] memory _recipients)`: Project owner triggers distribution of collected royalties to specified recipients.

**X. Dispute Resolution & Reputation Functions:**
24. `proposeDispute(uint256 _projectId, uint256 _contributionId, string memory _detailsHash)`: Initiates a dispute related to a project or specific contribution.
25. `voteOnDispute(uint256 _disputeId, bool _resolution)`: Allows eligible participants to vote on a proposed dispute.

**XI. View Functions:**
26. `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive details about a project.
27. `getContributorShare(uint256 _projectId, address _contributor)`: Returns the fractional ownership share of a contributor in a project.
28. `getLicensingTermDetails(uint256 _termId)`: Retrieves details about a specific licensing term.
29. `getContributorReputation(address _contributor)`: Returns the reputation score of a contributor.
30. `getProjectStatus(uint256 _projectId)`: Returns the current status of a project.
31. `getContributionDetails(uint256 _contributionId)`: Retrieves detailed information about a specific contribution.
32. `getProjectRevenue(uint256 _projectId)`: Returns the total accumulated royalties for a project.
33. `getDisputeDetails(uint256 _disputeId)`: Retrieves details about a specific dispute.
34. `getProjectTotalShares(uint256 _projectId)`: Returns the total fractional ownership shares minted for a project.
35. `isAIOracle(address _addr)`: Checks if an address is a registered AI Oracle.
36. `getProjectRole(uint256 _projectId, address _addr)`: Returns the role of an address within a specific project.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary
// This contract, AetherForge, is a Decentralized Autonomous Intellectual Property & Collaborative Creation Engine.
// It facilitates collaborative artistic and intellectual projects, integrates AI contribution tracking,
// manages fractional ownership, dynamic licensing, and on-chain dispute resolution.

// Outline:
// I. Data Structures & Enums: Defines the core entities like Project, Contribution, LicensingTerm, GrantedLicense, Dispute, and their states/roles.
// II. Events: Signals important state changes for off-chain monitoring and indexing.
// III. Modifiers: Restricts function access based on various roles (contract owner, project owner, contributor, AI oracle).
// IV. Core State Variables: Mappings and counters for projects, contributions, licensing terms, disputes, and reputation.
// V. Owner / Admin Functions: Functions for the contract deployer to manage global settings like AI Oracles and contract ownership.
// VI. Project Management Functions:
//    - Create, update, and manage the lifecycle of collaborative projects.
//    - Add/remove contributors, set project policies, delegate administrative roles.
//    - Link external governance tokens for project-specific decentralized decision-making.
// VII. Contribution & Scoring Functions:
//    - Allow contributors to submit their work (represented by content hashes).
//    - Enable project owners/delegated approvers to evaluate and score contributions, dynamically impacting ownership shares.
//    - Integrate AI Oracles to provide supplementary scores for contributions and overall project AI involvement.
// VIII. Intellectual Property & Ownership Functions:
//    - Finalize project IP by storing its immutable content hash.
//    - Manage fractional ownership shares among contributors, which are dynamically adjusted based on approved contributions.
//    - Provide functionality for transferring these fractional shares between participants.
// IX. Licensing & Royalty Functions:
//    - Define various customizable licensing terms (e.g., commercial, non-commercial, attribution-required) at a global level.
//    - Allow project owners to apply these general terms to their specific projects and grant formal licenses to users for set durations.
//    - Implement mechanisms to record revenue events for projects and enable project owners to distribute accumulated royalties proportionally to all shareholders.
// X. Dispute Resolution & Reputation Functions:
//    - Provide an on-chain mechanism for project contributors to propose and vote on disputes related to contributions, their values, or other project disagreements.
//    - Maintain and update a reputation score for each contributor, which can indirectly influence future project involvement or rewards.
// XI. Utility & View Functions:
//    - Comprehensive getter functions to query the detailed state of projects, contributions, licenses, disputes, and contributor data, enabling transparent access to all on-chain information.

// Function Summary (36 Functions):

// V. Owner / Admin Functions:
// 1.  registerAIOracle(address _oracleAddress) external onlyOwner
// 2.  deregisterAIOracle(address _oracleAddress) external onlyOwner
// 3.  transferOwnership(address _newOwner) external onlyOwner
// 4.  createLicensingTerm(string memory _name, uint256 _royaltyRateBps, string memory _conditionsHash) external onlyOwner returns (uint256)
// 5.  updateContributorReputation(address _contributor, int256 _scoreChange) external onlyOwner

// VI. Project Management Functions:
// 6.  createProject(string memory _name, string memory _description, string memory _contributionPolicyHash) external returns (uint256)
// 7.  updateProjectDetails(uint256 _projectId, string memory _newName, string memory _newDescription, string memory _newContributionPolicyHash) external onlyProjectOwner(_projectId)
// 8.  addContributorToProject(uint256 _projectId, address _contributor) external onlyProjectOwner(_projectId)
// 9.  removeContributorFromProject(uint256 _projectId, address _contributor) external onlyProjectOwner(_projectId)
// 10. setProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external onlyProjectOwner(_projectId)
// 11. delegateProjectRole(uint256 _projectId, address _delegatee, ProjectRole _role) external onlyProjectOwner(_projectId)
// 12. setProjectGovernanceToken(uint256 _projectId, address _tokenAddress) external onlyProjectOwner(_projectId)

// VII. Contribution & Scoring Functions:
// 13. submitContribution(uint256 _projectId, string memory _contentHash, bool _isAIgenerated, uint256 _estimatedValue) external returns (uint256)
// 14. approveContribution(uint256 _contributionId, uint256 _actualValueScore) external
// 15. submitAIContributionScore(uint256 _contributionId, uint256 _aiScore) external onlyAIOracle
// 16. submitProjectAIInvolvementScore(uint256 _projectId, uint256 _overallAIScore) external onlyAIOracle

// VIII. Intellectual Property & Ownership Functions:
// 17. finalizeProjectIP(uint256 _projectId, string memory _finalIPHash) external onlyProjectOwner(_projectId)
// 18. initializeProjectFractionalOwnership(uint256 _projectId, uint256 _initialTotalShares) external onlyProjectOwner(_projectId)
// 19. transferFractionalOwnership(uint256 _projectId, address _from, address _to, uint256 _shareAmount) external

// IX. Licensing & Royalty Functions:
// 20. applyLicensingTermToProject(uint256 _projectId, uint256 _termId) external onlyProjectOwner(_projectId)
// 21. grantProjectLicense(uint256 _projectId, address _licensee, uint256 _termId, uint256 _durationSeconds) external onlyProjectOwner(_projectId) returns (uint256)
// 22. recordRevenueEvent(uint256 _projectId, uint256 _amount) external payable
// 23. distributeRoyalties(uint256 _projectId, address[] memory _recipients) external onlyProjectOwner(_projectId)

// X. Dispute Resolution & Reputation Functions:
// 24. proposeDispute(uint256 _projectId, uint256 _contributionId, string memory _detailsHash) external onlyContributorOfProject(_projectId) returns (uint256)
// 25. voteOnDispute(uint256 _disputeId, bool _resolution) external

// XI. View Functions:
// 26. getProjectDetails(uint256 _projectId) public view returns (uint256 projectId, address creator, string memory name, string memory description, string memory contributionPolicyHash, ProjectStatus status, string memory finalIPHash, uint256 totalRoyaltiesCollected, uint256 totalShares, address projectFundingVault, address governanceToken, uint256 aiInvolvementScore, uint256 creationTimestamp, uint256 lastUpdateTimestamp)
// 27. getContributorShare(uint256 _projectId, address _contributor) public view returns (uint256)
// 28. getLicensingTermDetails(uint256 _termId) public view returns (uint256 termId, string memory name, uint256 royaltyRateBps, string memory conditionsHash, address creator, uint256 creationTimestamp)
// 29. getContributorReputation(address _contributor) public view returns (int256)
// 30. getProjectStatus(uint256 _projectId) public view returns (ProjectStatus)
// 31. getContributionDetails(uint256 _contributionId) public view returns (uint256 contributionId, uint256 projectId, address contributor, string memory contentHash, bool isAIgenerated, uint256 estimatedValue, uint256 actualValueScore, uint256 aiScore, bool approved, uint256 timestamp)
// 32. getProjectRevenue(uint256 _projectId) public view returns (uint256)
// 33. getDisputeDetails(uint256 _disputeId) public view returns (uint256 disputeId, uint256 projectId, uint256 contributionId, address proposer, string memory detailsHash, DisputeStatus status, uint256 yesVotes, uint256 noVotes, uint256 totalParticipants, uint256 creationTimestamp)
// 34. getProjectTotalShares(uint256 _projectId) public view returns (uint256)
// 35. isAIOracle(address _addr) public view returns (bool)
// 36. getProjectRole(uint256 _projectId, address _addr) public view returns (ProjectRole)

contract AetherForge {
    address public owner; // Contract deployer/admin
    uint256 private _nextProjectId;
    uint256 private _nextContributionId;
    uint256 private _nextLicensingTermId;
    uint256 private _nextLicenseGrantId;
    uint256 private _nextDisputeId;

    // --- Enums ---
    enum ProjectStatus { Draft, Active, Completed, Frozen, Archived, OnDispute }
    enum ProjectRole { None, Owner, Contributor, Approver, DelegatedReviewer } // None is default for unassigned
    enum DisputeStatus { Open, Resolved, Rejected }

    // --- Structs ---

    struct Project {
        uint256 projectId;
        address creator;
        string name;
        string description;
        string contributionPolicyHash; // IPFS hash of a document outlining contribution rules
        ProjectStatus status;
        string finalIPHash; // IPFS hash of the final creative output (e.g., final art, code repo)
        uint256 totalRoyaltiesCollected; // Total ETH collected for this project within AetherForge
        uint256 totalShares; // Total fractional ownership shares in the project
        address projectFundingVault; // Optional: Address of an external contract where revenues *could* be sent
        address governanceToken; // Optional: ERC-20 token for project-specific governance
        uint252 aiInvolvementScore; // Overall AI contribution score for the project
        uint256 creationTimestamp;
        uint256 lastUpdateTimestamp;
        mapping(address => uint256) contributorShares; // Fractional ownership shares per contributor
        mapping(address => ProjectRole) projectRoles; // Roles within the project (beyond creator)
        mapping(uint256 => bool) appliedLicensingTerms; // Map of termId => whether it's applicable to this project
    }

    struct Contribution {
        uint256 contributionId;
        uint256 projectId;
        address contributor;
        string contentHash; // IPFS hash of the contributed content (e.g., an asset, code snippet)
        bool isAIgenerated; // Flag if this contribution involved AI generation significantly
        uint256 estimatedValue; // Value proposed by contributor
        uint256 actualValueScore; // Value approved by project owner/committee, directly impacts shares
        uint256 aiScore; // Score from an AI oracle (e.g., quality, uniqueness)
        bool approved;
        uint256 timestamp;
    }

    struct LicensingTerm {
        uint256 termId;
        string name;
        uint256 royaltyRateBps; // Royalty rate in basis points (e.g., 100 = 1%)
        string conditionsHash; // IPFS hash of legal conditions document for this term
        address creator; // Who defined this global licensing term
        uint256 creationTimestamp;
    }

    struct GrantedLicense {
        uint256 licenseGrantId;
        uint256 projectId;
        address licensee;
        uint256 termId;
        uint256 grantTimestamp;
        uint256 expirationTimestamp;
        bool revoked;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 projectId;
        uint256 contributionId; // Can be 0 if project-level dispute
        address proposer;
        string detailsHash; // IPFS hash of dispute details document
        DisputeStatus status;
        uint256 creationTimestamp;
        mapping(address => bool) voted; // Tracks who voted
        uint252 yesVotes;
        uint252 noVotes;
        uint252 totalParticipants; // Number of eligible voters for this dispute (snapshot at proposal)
    }

    // --- State Variables ---
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => LicensingTerm) public licensingTerms;
    mapping(uint256 => GrantedLicense) public grantedLicenses;
    mapping(uint256 => Dispute) public disputes;

    mapping(address => int256) public contributorReputation; // Reputation score for each contributor
    mapping(address => bool) public aiOracles; // Whitelisted AI oracle addresses

    // --- Events ---
    event ProjectCreated(uint256 projectId, address indexed creator, string name);
    event ProjectUpdated(uint252 projectId, string name, ProjectStatus newStatus);
    event ContributorAdded(uint252 projectId, address indexed contributor);
    event ContributorRemoved(uint252 projectId, address indexed contributor);
    event ContributionSubmitted(uint252 contributionId, uint252 projectId, address indexed contributor, string contentHash);
    event ContributionApproved(uint252 contributionId, uint252 actualValueScore, uint252 newTotalShares, uint252 newContributorShares);
    event AIContributionScored(uint252 contributionId, uint252 aiScore);
    event ProjectAIInvolvementScored(uint252 projectId, uint252 overallAIScore);
    event ProjectFinalized(uint252 projectId, string finalIPHash);
    event FractionalOwnershipInitialized(uint252 projectId, uint252 initialTotalShares, address indexed creator);
    event FractionalOwnershipTransferred(uint252 projectId, address indexed from, address indexed to, uint252 amount);
    event LicensingTermCreated(uint252 termId, string name, uint252 royaltyRateBps);
    event LicensingTermApplied(uint252 projectId, uint252 termId);
    event LicenseGranted(uint252 licenseGrantId, uint252 projectId, address indexed licensee, uint252 termId, uint252 expirationTimestamp);
    event RevenueRecorded(uint252 projectId, uint252 amount, uint252 currentTotal);
    event RoyaltiesDistributed(uint252 projectId, uint252 distributedAmount);
    event DisputeProposed(uint252 disputeId, uint252 projectId, uint252 contributionId, address indexed proposer);
    event DisputeVoted(uint252 disputeId, address indexed voter, bool resolution);
    event ReputationUpdated(address indexed contributor, int252 newScore);
    event ProjectFundingVaultSet(uint252 projectId, address vaultAddress);
    event ProjectRoleDelegated(uint252 projectId, address indexed delegatee, ProjectRole role);
    event ProjectGovernanceTokenSet(uint252 projectId, address tokenAddress);
    event AIOracleRegistered(address indexed oracleAddress);
    event AIOracleDeregistered(address indexed oracleAddress);


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _nextProjectId = 1;
        _nextContributionId = 1;
        _nextLicensingTermId = 1;
        _nextLicenseGrantId = 1;
        _nextDisputeId = 1;
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].creator != address(0), "Project does not exist."); // Ensure project exists
        require(projects[_projectId].creator == msg.sender, "Only project creator can call this function.");
        _;
    }

    modifier onlyProjectApprover(uint256 _projectId) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        // Project creator is implicitly an owner and can approve.
        // Or if the caller has been delegated the Approver role.
        require(msg.sender == projects[_projectId].creator || projects[_projectId].projectRoles[msg.sender] == ProjectRole.Approver,
                "Caller is not an authorized approver for this project.");
        _;
    }

    modifier onlyContributorOfProject(uint256 _projectId) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        require(projects[_projectId].contributorShares[msg.sender] > 0 || projects[_projectId].creator == msg.sender,
                "Caller is not a recognized contributor or owner of this project.");
        _;
    }

    modifier onlyAIOracle() {
        require(aiOracles[msg.sender], "Only whitelisted AI oracles can call this function.");
        _;
    }

    // --- V. Owner / Admin Functions ---

    // 1. registerAIOracle(address _oracleAddress) external onlyOwner
    function registerAIOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address.");
        require(!aiOracles[_oracleAddress], "AI Oracle already registered.");
        aiOracles[_oracleAddress] = true;
        emit AIOracleRegistered(_oracleAddress);
    }

    // 2. deregisterAIOracle(address _oracleAddress) external onlyOwner
    function deregisterAIOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address.");
        require(aiOracles[_oracleAddress], "AI Oracle not registered.");
        aiOracles[_oracleAddress] = false;
        emit AIOracleDeregistered(_oracleAddress);
    }

    // 3. transferOwnership(address _newOwner) external onlyOwner
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address.");
        owner = _newOwner;
    }

    // 4. createLicensingTerm(string memory _name, uint256 _royaltyRateBps, string memory _conditionsHash) external onlyOwner returns (uint256)
    function createLicensingTerm(string memory _name, uint256 _royaltyRateBps, string memory _conditionsHash) external onlyOwner returns (uint256) {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(_royaltyRateBps <= 10000, "Royalty rate cannot exceed 100% (10000 basis points).");

        uint256 termId = _nextLicensingTermId++;
        licensingTerms[termId] = LicensingTerm({
            termId: termId,
            name: _name,
            royaltyRateBps: _royaltyRateBps,
            conditionsHash: _conditionsHash,
            creator: msg.sender,
            creationTimestamp: block.timestamp
        });
        emit LicensingTermCreated(termId, _name, _royaltyRateBps);
        return termId;
    }

    // 5. updateContributorReputation(address _contributor, int256 _scoreChange) external onlyOwner
    function updateContributorReputation(address _contributor, int256 _scoreChange) external onlyOwner {
        contributorReputation[_contributor] += _scoreChange;
        emit ReputationUpdated(_contributor, contributorReputation[_contributor]);
    }

    // --- VI. Project Management Functions ---

    // 6. createProject(string memory _name, string memory _description, string memory _contributionPolicyHash) external returns (uint256)
    function createProject(string memory _name, string memory _description, string memory _contributionPolicyHash) external returns (uint256) {
        require(bytes(_name).length > 0, "Project name cannot be empty.");

        uint256 projectId = _nextProjectId++;
        Project storage newProject = projects[projectId];
        newProject.projectId = projectId;
        newProject.creator = msg.sender;
        newProject.name = _name;
        newProject.description = _description;
        newProject.contributionPolicyHash = _contributionPolicyHash;
        newProject.status = ProjectStatus.Draft;
        newProject.creationTimestamp = block.timestamp;
        newProject.lastUpdateTimestamp = block.timestamp;

        // Creator implicitly has the Owner role
        newProject.projectRoles[msg.sender] = ProjectRole.Owner;

        emit ProjectCreated(projectId, msg.sender, _name);
        return projectId;
    }

    // 7. updateProjectDetails(uint256 _projectId, string memory _newName, string memory _newDescription, string memory _newContributionPolicyHash) external onlyProjectOwner(_projectId)
    function updateProjectDetails(uint256 _projectId, string memory _newName, string memory _newDescription, string memory _newContributionPolicyHash) external onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Archived, "Cannot update a completed or archived project.");

        if (bytes(_newName).length > 0) project.name = _newName;
        if (bytes(_newDescription).length > 0) project.description = _newDescription;
        if (bytes(_newContributionPolicyHash).length > 0) project.contributionPolicyHash = _newContributionPolicyHash;
        project.lastUpdateTimestamp = block.timestamp;

        emit ProjectUpdated(_projectId, project.name, project.status);
    }

    // 8. addContributorToProject(uint256 _projectId, address _contributor) external onlyProjectOwner(_projectId)
    function addContributorToProject(uint256 _projectId, address _contributor) external onlyProjectOwner(_projectId) {
        require(_contributor != address(0), "Invalid contributor address.");
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        require(projects[_projectId].projectRoles[_contributor] == ProjectRole.None, "Contributor already involved in this project.");
        
        projects[_projectId].projectRoles[_contributor] = ProjectRole.Contributor;
        emit ContributorAdded(_projectId, _contributor);
    }

    // 9. removeContributorFromProject(uint256 _projectId, address _contributor) external onlyProjectOwner(_projectId)
    function removeContributorFromProject(uint256 _projectId, address _contributor) external onlyProjectOwner(_projectId) {
        require(_contributor != address(0), "Invalid contributor address.");
        require(_contributor != projects[_projectId].creator, "Cannot remove project creator.");
        require(projects[_projectId].projectRoles[_contributor] != ProjectRole.None, "Contributor not found in project.");
        require(projects[_projectId].contributorShares[_contributor] == 0, "Contributor still holds shares. Shares must be transferred or burned first.");

        delete projects[_projectId].projectRoles[_contributor];
        emit ContributorRemoved(_projectId, _contributor);
    }

    // 10. setProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external onlyProjectOwner(_projectId)
    function setProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external onlyProjectOwner(_projectId) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        require(_newStatus != projects[_projectId].status, "New status cannot be the same as current status.");
        // Add more complex state transition logic here if needed (e.g., can't go from completed to active)
        projects[_projectId].status = _newStatus;
        projects[_projectId].lastUpdateTimestamp = block.timestamp;
        emit ProjectUpdated(_projectId, projects[_projectId].name, _newStatus);
    }

    // 11. delegateProjectRole(uint256 _projectId, address _delegatee, ProjectRole _role) external onlyProjectOwner(_projectId)
    function delegateProjectRole(uint256 _projectId, address _delegatee, ProjectRole _role) external onlyProjectOwner(_projectId) {
        require(_delegatee != address(0), "Invalid delegatee address.");
        require(_role != ProjectRole.Owner && _role != ProjectRole.None, "Cannot delegate owner or none role.");
        require(projects[_projectId].projectRoles[_delegatee] != ProjectRole.Owner, "Cannot override creator's owner role.");

        projects[_projectId].projectRoles[_delegatee] = _role;
        emit ProjectRoleDelegated(_projectId, _delegatee, _role);
    }

    // 12. setProjectGovernanceToken(uint256 _projectId, address _tokenAddress) external onlyProjectOwner(_projectId)
    function setProjectGovernanceToken(uint256 _projectId, address _tokenAddress) external onlyProjectOwner(_projectId) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        require(_tokenAddress != address(0), "Invalid token address.");
        projects[_projectId].governanceToken = _tokenAddress;
        emit ProjectGovernanceTokenSet(_projectId, _tokenAddress);
    }

    // --- VII. Contribution & Scoring Functions ---

    // 13. submitContribution(uint256 _projectId, string memory _contentHash, bool _isAIgenerated, uint256 _estimatedValue) external returns (uint256)
    function submitContribution(uint256 _projectId, string memory _contentHash, bool _isAIgenerated, uint256 _estimatedValue) external returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.status == ProjectStatus.Active, "Project must be active to submit contributions.");
        require(project.projectRoles[msg.sender] != ProjectRole.None || msg.sender == project.creator, "Caller is not a recognized contributor or project creator.");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty.");

        uint256 contributionId = _nextContributionId++;
        contributions[contributionId] = Contribution({
            contributionId: contributionId,
            projectId: _projectId,
            contributor: msg.sender,
            contentHash: _contentHash,
            isAIgenerated: _isAIgenerated,
            estimatedValue: _estimatedValue,
            actualValueScore: 0, // Awaiting approval
            aiScore: 0, // Awaiting AI oracle score
            approved: false,
            timestamp: block.timestamp
        });
        emit ContributionSubmitted(contributionId, _projectId, msg.sender, _contentHash);
        return contributionId;
    }

    // 14. approveContribution(uint256 _contributionId, uint256 _actualValueScore) external
    function approveContribution(uint256 _contributionId, uint256 _actualValueScore) external {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributionId != 0, "Contribution does not exist.");
        require(!contribution.approved, "Contribution already approved.");

        Project storage project = projects[contribution.projectId];
        require(project.projectId != 0, "Project does not exist for this contribution.");
        
        // Use the `onlyProjectApprover` modifier logic
        require(msg.sender == project.creator || project.projectRoles[msg.sender] == ProjectRole.Approver,
                "Caller is not an authorized approver for this project.");
        
        require(_actualValueScore > 0, "Actual value score must be positive.");

        contribution.actualValueScore = _actualValueScore;
        contribution.approved = true;

        // Dynamically adjust contributor shares based on approved value
        project.contributorShares[contribution.contributor] += _actualValueScore;
        project.totalShares += _actualValueScore;

        project.lastUpdateTimestamp = block.timestamp;
        emit ContributionApproved(_contributionId, _actualValueScore, project.totalShares, project.contributorShares[contribution.contributor]);
    }

    // 15. submitAIContributionScore(uint256 _contributionId, uint256 _aiScore) external onlyAIOracle
    function submitAIContributionScore(uint256 _contributionId, uint256 _aiScore) external onlyAIOracle {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributionId != 0, "Contribution does not exist.");
        require(contribution.aiScore == 0, "AI score already submitted for this contribution.");

        contribution.aiScore = _aiScore;
        // This AI score is recorded for information; further logic could use it (e.g., reputation, dynamic share adjustment)
        emit AIContributionScored(_contributionId, _aiScore);
    }

    // 16. submitProjectAIInvolvementScore(uint256 _projectId, uint256 _overallAIScore) external onlyAIOracle
    function submitProjectAIInvolvementScore(uint256 _projectId, uint256 _overallAIScore) external onlyAIOracle {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        // Allow updating, as AI models might re-evaluate over time.
        project.aiInvolvementScore = _overallAIScore;
        emit ProjectAIInvolvementScored(_projectId, _overallAIScore);
    }

    // --- VIII. Intellectual Property & Ownership Functions ---

    // 17. finalizeProjectIP(uint256 _projectId, string memory _finalIPHash) external onlyProjectOwner(_projectId)
    function finalizeProjectIP(uint256 _projectId, string memory _finalIPHash) external onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(bytes(_finalIPHash).length > 0, "Final IP hash cannot be empty.");
        require(project.status == ProjectStatus.Active, "Project must be active to finalize IP.");
        require(bytes(project.finalIPHash).length == 0, "Project IP already finalized."); // Can only be finalized once.

        project.finalIPHash = _finalIPHash;
        project.status = ProjectStatus.Completed; // Move to completed after IP finalization
        project.lastUpdateTimestamp = block.timestamp;
        emit ProjectFinalized(_projectId, _finalIPHash);
    }

    // 18. initializeProjectFractionalOwnership(uint256 _projectId, uint256 _initialTotalShares) external onlyProjectOwner(_projectId)
    function initializeProjectFractionalOwnership(uint256 _projectId, uint256 _initialTotalShares) external onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.totalShares == 0, "Fractional ownership already initialized.");
        require(_initialTotalShares > 0, "Initial shares must be positive.");

        project.totalShares = _initialTotalShares;
        project.contributorShares[project.creator] += _initialTotalShares; // Creator gets initial shares
        emit FractionalOwnershipInitialized(_projectId, _initialTotalShares, project.creator);
    }

    // 19. transferFractionalOwnership(uint256 _projectId, address _from, address _to, uint256 _shareAmount) external
    function transferFractionalOwnership(uint256 _projectId, address _from, address _to, uint256 _shareAmount) external {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.contributorShares[_from] >= _shareAmount, "Insufficient shares to transfer.");
        require(_to != address(0), "Cannot transfer to zero address.");
        require(msg.sender == _from || msg.sender == project.creator, "Only share owner or project owner can initiate transfer.");

        project.contributorShares[_from] -= _shareAmount;
        project.contributorShares[_to] += _shareAmount;

        // Ensure recipient is recognized as a contributor if they weren't before
        if (project.projectRoles[_to] == ProjectRole.None && _to != project.creator) {
             project.projectRoles[_to] = ProjectRole.Contributor; // Assign contributor role if they receive shares.
        }

        emit FractionalOwnershipTransferred(_projectId, _from, _to, _shareAmount);
    }

    // --- IX. Licensing & Royalty Functions ---

    // 20. applyLicensingTermToProject(uint256 _projectId, uint256 _termId) external onlyProjectOwner(_projectId)
    function applyLicensingTermToProject(uint256 _projectId, uint256 _termId) external onlyProjectOwner(_projectId) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        require(licensingTerms[_termId].termId != 0, "Licensing term does not exist.");
        Project storage project = projects[_projectId];
        require(!project.appliedLicensingTerms[_termId], "Licensing term already applied to this project.");

        project.appliedLicensingTerms[_termId] = true;
        emit LicensingTermApplied(_projectId, _termId);
    }

    // 21. grantProjectLicense(uint256 _projectId, address _licensee, uint256 _termId, uint256 _durationSeconds) external onlyProjectOwner(_projectId) returns (uint256)
    function grantProjectLicense(uint256 _projectId, address _licensee, uint256 _termId, uint256 _durationSeconds) external onlyProjectOwner(_projectId) returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.appliedLicensingTerms[_termId], "Licensing term not applied to this project.");
        require(_licensee != address(0), "Invalid licensee address.");
        require(_durationSeconds > 0, "License duration must be positive.");

        uint256 licenseGrantId = _nextLicenseGrantId++;
        grantedLicenses[licenseGrantId] = GrantedLicense({
            licenseGrantId: licenseGrantId,
            projectId: _projectId,
            licensee: _licensee,
            termId: _termId,
            grantTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + _durationSeconds,
            revoked: false
        });
        emit LicenseGranted(licenseGrantId, _projectId, _licensee, _termId, block.timestamp + _durationSeconds);
        return licenseGrantId;
    }

    // 22. recordRevenueEvent(uint256 _projectId, uint256 _amount) external payable
    function recordRevenueEvent(uint256 _projectId, uint256 _amount) external payable {
        // This function receives Ether as revenue for a project.
        // An external system (e.g., a marketplace) would call this.
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        require(msg.value == _amount, "Sent Ether does not match specified amount.");
        require(_amount > 0, "Revenue amount must be positive.");

        projects[_projectId].totalRoyaltiesCollected += _amount;
        emit RevenueRecorded(_projectId, _amount, projects[_projectId].totalRoyaltiesCollected);
    }

    // 23. distributeRoyalties(uint256 _projectId, address[] memory _recipients) external onlyProjectOwner(_projectId)
    // Project owner provides a list of recipients (typically all contributors with shares > 0).
    // This allows distributing to an arbitrary number of recipients efficiently, by batching.
    // In a highly decentralized system, this could also be a `claim` pattern or use a Merkle tree.
    function distributeRoyalties(uint256 _projectId, address[] memory _recipients) external onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.totalRoyaltiesCollected > 0, "No royalties collected for this project.");
        require(project.totalShares > 0, "Project has no fractional shares to distribute.");
        
        uint256 amountToDistribute = project.totalRoyaltiesCollected;
        project.totalRoyaltiesCollected = 0; // Reset for the next cycle

        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 share = project.contributorShares[recipient];
            if (share > 0) {
                uint256 royaltyAmount = (amountToDistribute * share) / project.totalShares;
                if (royaltyAmount > 0) {
                    // Using transfer for simplicity; in production, use call for reentrancy safety
                    payable(recipient).transfer(royaltyAmount); 
                    totalDistributed += royaltyAmount;
                }
            }
        }
        // Any remainder due to rounding or if not all recipients were included stays in the contract
        // and contributes to the next cycle's `totalRoyaltiesCollected`
        project.totalRoyaltiesCollected += (amountToDistribute - totalDistributed);
        emit RoyaltiesDistributed(_projectId, totalDistributed);
    }

    // --- X. Dispute Resolution & Reputation Functions ---

    // 24. proposeDispute(uint256 _projectId, uint256 _contributionId, string memory _detailsHash) external onlyContributorOfProject(_projectId) returns (uint256)
    function proposeDispute(uint256 _projectId, uint256 _contributionId, string memory _detailsHash) external onlyContributorOfProject(_projectId) returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        if (_contributionId != 0) { // If it's a contribution-specific dispute
            require(contributions[_contributionId].projectId == _projectId, "Contribution does not belong to this project.");
        }
        require(bytes(_detailsHash).length > 0, "Dispute details hash cannot be empty.");

        uint256 disputeId = _nextDisputeId++;
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            projectId: _projectId,
            contributionId: _contributionId,
            proposer: msg.sender,
            detailsHash: _detailsHash,
            status: DisputeStatus.Open,
            creationTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            totalParticipants: 0 // Will be calculated dynamically or at vote closure
        });
        
        // Optionally, change project status to `OnDispute` if it's a critical dispute.
        // For simplicity, this is just a flag, not a blocker for other project operations.

        emit DisputeProposed(disputeId, _projectId, _contributionId, msg.sender);
        return disputeId;
    }

    // 25. voteOnDispute(uint256 _disputeId, bool _resolution) external
    function voteOnDispute(uint256 _disputeId, bool _resolution) external {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist.");
        require(dispute.status == DisputeStatus.Open, "Dispute is not open for voting.");
        require(!dispute.voted[msg.sender], "Caller has already voted on this dispute.");

        // Only contributors or the project owner can vote
        require(projects[dispute.projectId].contributorShares[msg.sender] > 0 || projects[dispute.projectId].creator == msg.sender,
                "Only project contributors/owner can vote.");

        dispute.voted[msg.sender] = true;
        dispute.totalParticipants++; // Increment total participants as they vote (simplified quorum)
        if (_resolution) {
            dispute.yesVotes++;
        } else {
            dispute.noVotes++;
        }
        // In a real system, you'd add a method to `resolveDispute` after a voting period
        // and sufficient votes, which would then update `dispute.status`.
        emit DisputeVoted(_disputeId, msg.sender, _resolution);
    }

    // --- XI. View Functions ---

    // 26. getProjectDetails(uint256 _projectId) public view returns (...)
    function getProjectDetails(uint256 _projectId) public view returns (
        uint256 projectId,
        address creator,
        string memory name,
        string memory description,
        string memory contributionPolicyHash,
        ProjectStatus status,
        string memory finalIPHash,
        uint256 totalRoyaltiesCollected,
        uint256 totalShares,
        address projectFundingVault,
        address governanceToken,
        uint256 aiInvolvementScore,
        uint256 creationTimestamp,
        uint256 lastUpdateTimestamp
    ) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");

        return (
            project.projectId,
            project.creator,
            project.name,
            project.description,
            project.contributionPolicyHash,
            project.status,
            project.finalIPHash,
            project.totalRoyaltiesCollected,
            project.totalShares,
            project.projectFundingVault,
            project.governanceToken,
            project.aiInvolvementScore,
            project.creationTimestamp,
            project.lastUpdateTimestamp
        );
    }

    // 27. getContributorShare(uint256 _projectId, address _contributor) public view returns (uint256)
    function getContributorShare(uint256 _projectId, address _contributor) public view returns (uint256) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        return projects[_projectId].contributorShares[_contributor];
    }

    // 28. getLicensingTermDetails(uint256 _termId) public view returns (...)
    function getLicensingTermDetails(uint256 _termId) public view returns (
        uint256 termId,
        string memory name,
        uint256 royaltyRateBps,
        string memory conditionsHash,
        address creator,
        uint256 creationTimestamp
    ) {
        LicensingTerm storage term = licensingTerms[_termId];
        require(term.termId != 0, "Licensing term does not exist.");
        return (
            term.termId,
            term.name,
            term.royaltyRateBps,
            term.conditionsHash,
            term.creator,
            term.creationTimestamp
        );
    }

    // 29. getContributorReputation(address _contributor) public view returns (int256)
    function getContributorReputation(address _contributor) public view returns (int256) {
        return contributorReputation[_contributor];
    }

    // 30. getProjectStatus(uint256 _projectId) public view returns (ProjectStatus)
    function getProjectStatus(uint225 _projectId) public view returns (ProjectStatus) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        return projects[_projectId].status;
    }

    // 31. getContributionDetails(uint256 _contributionId) public view returns (...)
    function getContributionDetails(uint256 _contributionId) public view returns (
        uint256 contributionId,
        uint256 projectId,
        address contributor,
        string memory contentHash,
        bool isAIgenerated,
        uint256 estimatedValue,
        uint256 actualValueScore,
        uint256 aiScore,
        bool approved,
        uint256 timestamp
    ) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributionId != 0, "Contribution does not exist.");
        return (
            contribution.contributionId,
            contribution.projectId,
            contribution.contributor,
            contribution.contentHash,
            contribution.isAIgenerated,
            contribution.estimatedValue,
            contribution.actualValueScore,
            contribution.aiScore,
            contribution.approved,
            contribution.timestamp
        );
    }

    // 32. getProjectRevenue(uint256 _projectId) public view returns (uint256)
    function getProjectRevenue(uint256 _projectId) public view returns (uint256) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        return projects[_projectId].totalRoyaltiesCollected;
    }

    // 33. getDisputeDetails(uint256 _disputeId) public view returns (...)
    function getDisputeDetails(uint256 _disputeId) public view returns (
        uint256 disputeId,
        uint256 projectId,
        uint256 contributionId,
        address proposer,
        string memory detailsHash,
        DisputeStatus status,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 totalParticipants,
        uint256 creationTimestamp
    ) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist.");
        return (
            dispute.disputeId,
            dispute.projectId,
            dispute.contributionId,
            dispute.proposer,
            dispute.detailsHash,
            dispute.status,
            dispute.yesVotes,
            dispute.noVotes,
            dispute.totalParticipants,
            dispute.creationTimestamp
        );
    }

    // 34. getProjectTotalShares(uint256 _projectId) public view returns (uint256)
    function getProjectTotalShares(uint225 _projectId) public view returns (uint256) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        return projects[_projectId].totalShares;
    }

    // 35. isAIOracle(address _addr) public view returns (bool)
    function isAIOracle(address _addr) public view returns (bool) {
        return aiOracles[_addr];
    }

    // 36. getProjectRole(uint256 _projectId, address _addr) public view returns (ProjectRole)
    function getProjectRole(uint256 _projectId, address _addr) public view returns (ProjectRole) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        if (_addr == projects[_projectId].creator) return ProjectRole.Owner;
        return projects[_projectId].projectRoles[_addr];
    }
}
```