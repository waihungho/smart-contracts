Here's a Solidity smart contract named `SynthetixNexus` that embodies advanced concepts, creative functions, and trendy features, aiming to avoid direct duplication of common open-source patterns. It focuses on a decentralized autonomous research and development (R&D) hub.

---

**Outline and Function Summary**

**Contract Name:** `SynthetixNexus`
**Concept:** A Decentralized Autonomous Research & Development (R&D) Hub.
This contract facilitates the lifecycle of collaborative R&D projects, from proposal and funding to milestone tracking, Intellectual Property (IP) tokenization, and royalty distribution. It integrates a dynamic reputation system for researchers and an on-chain dispute resolution mechanism, all managed by a designated governor role.

**I. Core Infrastructure & Setup**
1.  `constructor(address _synthesisTokenAddress, address _ipNFTContractAddress)`: Initializes the contract, setting addresses for the primary governance/funding token (ERC20) and the IP NFT contract (ERC721).
2.  `setGovernor(address _newGovernor)`: Grants an address the `governor` role, enabling privileged actions (e.g., project approval, dispute resolution).
3.  `revokeGovernor()`: Removes the `governor` role from the current governor.
4.  `pauseContract()`: Allows the governor to temporarily halt critical contract operations (e.g., project funding, withdrawals) for maintenance or emergencies.
5.  `unpauseContract()`: Allows the governor to resume paused operations.

**II. Project Lifecycle Management**
6.  `proposeProject(string calldata _title, string calldata _description, Milestone[] calldata _milestones, uint256 _fundingGoal)`: Allows any researcher to submit a new R&D project proposal with detailed milestones and a total funding goal. Projects are initially in `Proposed` state.
7.  `approveProject(uint256 _projectId)`: A governor-only function to officially approve a proposed project, making it eligible for funding.
8.  `fundProject(uint256 _projectId, uint256 _amount)`: Enables anyone to contribute funding to an approved project using the designated Synthesis Token. Funds are held in escrow.
9.  `startProject(uint256 _projectId)`: Initiates an approved and sufficiently funded project, transitioning it to `InProgress` state. Can only be called by the project proposer.
10. `reportMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string calldata _evidenceURI)`: Researcher reports the completion of a specific milestone, providing external evidence (e.g., IPFS hash).
11. `verifyMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _isAchieved)`: Governor or designated evaluators verify the reported milestone completion, affecting the project's progress and researcher's reputation.
12. `requestMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex)`: Allows the researcher to request funds for a completed and verified milestone, releasing them from the contract's escrow.
13. `completeProject(uint256 _projectId, string calldata _finalIPURI, uint256 _royaltyPercentage)`: The researcher finalizes a project after all milestones are completed, triggering the minting of an IP NFT and setting its initial royalty percentage.
14. `failProject(uint256 _projectId, string calldata _reason)`: Allows a project to be officially marked as failed (by proposer or governor), leading to reputation adjustments and potential fund reallocation.

**III. Intellectual Property (IP) & Royalty Management**
15. `_mintIPNFT(uint256 _projectId, address _owner, string calldata _tokenURI, uint256 _royaltyPercentage)`: **(Internal Function)** Called upon project completion to create a new IP NFT representing the project's outcome and link it to the contract's royalty system.
16. `distributeRoyalties(uint256 _ipNFTId, uint256 _amount)`: Allows anyone to deposit royalty payments (Synthesis Tokens) to a specific IP NFT, which are then held for the IP NFT owner.
17. `claimRoyalties(uint256 _ipNFTId)`: Allows the current owner of an IP NFT to withdraw their accumulated royalty payments.
18. `updateIPNFTRoyaltyPercentage(uint256 _ipNFTId, uint256 _newPercentage)`: Allows the IP NFT owner to propose an update to the royalty percentage (in a more advanced system, this could trigger a governance vote).

**IV. Reputation System**
19. `getResearcherReputation(address _researcher)`: Retrieves the current reputation score for a given researcher address.
20. `_adjustReputation(address _researcher, int256 _delta)`: **(Internal Function)** Privileged function to modify a researcher's reputation score based on project performance (success/failure, milestone verification).

**V. Dispute Resolution**
21. `initiateDispute(uint256 _projectId, uint256 _milestoneIndex, string calldata _reason)`: Allows a stakeholder (funder, evaluator, or proposer) to formally challenge a project's state or a milestone's completion, putting the project into a `Disputed` state.
22. `resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _proposerWins, string calldata _resolutionDetails)`: Governor resolves an ongoing dispute, determining its outcome and affecting project state and researcher reputation.
23. `reallocateDisputedFunds(uint256 _projectId, uint256 _milestoneIndex)`: Executes the reallocation of unspent funds (return to funders) if a project fails or a dispute results in a funder's favor.

**VI. Utility & Information Access**
24. `getProjectDetails(uint256 _projectId)`: Provides comprehensive details of a specific project, including its state, funding, and associated IP NFT.
25. `getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)`: Fetches the details of a particular milestone within a project.
26. `getIPNFTDetails(uint256 _ipNFTId)`: Returns information about a specific IP NFT, including its associated project, royalty settings, and current owner.
27. `getProjectsByResearcher(address _researcher)`: Returns arrays of project IDs associated with a given researcher, categorized by their state (active, completed, failed).
28. `getProjectsByFunder(address _funder)`: Returns an array of project IDs that a given address has contributed funds to.

**Total Functions: 28**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Using a minimal custom IERC721 interface for `ownerOf` for conceptual clarity.
// A real system would either use a standard IERC721 (which doesn't have `mint`)
// and have a separate contract that mints, or a custom ERC721 allowing this contract to mint.
interface IERC721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // Note: Standard IERC721 does not include mint functions.
    // For `_mintIPNFT`, a real-world scenario would require a custom ERC721 contract
    // that either whitelists this contract as a minter or has a public mint function
    // callable by specific roles. This example assumes such an interaction is possible.
}


// --- Outline and Function Summary ---
// Contract Name: SynthetixNexus
// A Decentralized Autonomous Research & Development (R&D) Hub.
// This contract facilitates the lifecycle of collaborative R&D projects,
// from proposal and funding to milestone tracking, IP tokenization, and royalty distribution.
// It integrates a dynamic reputation system for researchers and an on-chain dispute resolution mechanism.

// I. Core Infrastructure & Setup
// 1. constructor(address _synthesisTokenAddress, address _ipNFTContractAddress): Initializes the contract, setting addresses for the primary governance/funding token (ERC20) and the IP NFT contract (ERC721).
// 2. setGovernor(address _newGovernor): Grants an address the `governor` role, enabling privileged actions.
// 3. revokeGovernor(): Removes the `governor` role from the current governor.
// 4. pauseContract(): Allows the governor to temporarily halt critical contract operations (e.g., project funding, withdrawals) for maintenance or emergencies.
// 5. unpauseContract(): Allows the governor to resume paused operations.

// II. Project Lifecycle Management
// 6. proposeProject(string calldata _title, string calldata _description, Milestone[] calldata _milestones, uint256 _fundingGoal): Allows any researcher to submit a new R&D project proposal with detailed milestones and a total funding goal.
// 7. approveProject(uint256 _projectId): A governor-only function to officially approve a proposed project, making it eligible for funding.
// 8. fundProject(uint256 _projectId, uint256 _amount): Enables anyone to contribute funding to an approved project using the designated Synthesis Token. Funds are held in escrow.
// 9. startProject(uint256 _projectId): Initiates an approved and sufficiently funded project, transitioning it to `InProgress` state.
// 10. reportMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string calldata _evidenceURI): Researcher reports the completion of a specific milestone, providing external evidence.
// 11. verifyMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _isAchieved): Governor or designated evaluators verify the reported milestone completion, affecting the project's progress and researcher's reputation.
// 12. requestMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex): Allows the researcher to request funds for a completed and verified milestone.
// 13. completeProject(uint256 _projectId, string calldata _finalIPURI, uint256 _royaltyPercentage): The researcher finalizes a project, triggering the minting of an IP NFT and setting its initial royalty percentage.
// 14. failProject(uint256 _projectId, string calldata _reason): Allows a project to be officially marked as failed (e.g., by the proposer or governor), leading to potential fund reallocation and reputation adjustments.

// III. Intellectual Property (IP) & Royalty Management
// 15. _mintIPNFT(uint256 _projectId, address _owner, string calldata _tokenURI, uint256 _royaltyPercentage): An internal function called upon project completion to create a new IP NFT representing the project's outcome.
// 16. distributeRoyalties(uint256 _ipNFTId, uint256 _amount): Allows anyone to deposit royalty payments to a specific IP NFT, which are then held for the IP NFT owner.
// 17. claimRoyalties(uint256 _ipNFTId): Allows the owner of an IP NFT to withdraw accumulated royalty payments.
// 18. updateIPNFTRoyaltyPercentage(uint256 _ipNFTId, uint256 _newPercentage): Allows the IP NFT owner to propose an update to the royalty percentage (may require a future governance vote in advanced versions).

// IV. Reputation System
// 19. getResearcherReputation(address _researcher): Retrieves the current reputation score for a given researcher address.
// 20. _adjustReputation(address _researcher, int256 _delta): An internal, privileged function to modify a researcher's reputation score based on project performance (success/failure, milestone verification).

// V. Dispute Resolution
// 21. initiateDispute(uint256 _projectId, uint256 _milestoneIndex, string calldata _reason): Allows a stakeholder (funder, evaluator, or even the proposer) to formally challenge a project's state or a milestone's completion.
// 22. resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _proposerWins, string calldata _resolutionDetails): Governor or designated arbitrators resolve an ongoing dispute, determining its outcome and affecting project state and reputation.
// 23. reallocateDisputedFunds(uint256 _projectId, uint256 _milestoneIndex): Executes the reallocation of funds (return to funders or release to proposer) based on the resolution of a dispute.

// VI. Utility & Information Access
// 24. getProjectDetails(uint256 _projectId): Provides comprehensive details of a specific project, including its state, funding, and associated IP NFT.
// 25. getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex): Fetches the details of a particular milestone within a project.
// 26. getIPNFTDetails(uint256 _ipNFTId): Returns information about a specific IP NFT, including its owner and associated project.
// 27. getProjectsByResearcher(address _researcher): Returns an array of project IDs associated with a given researcher, categorized by their state.
// 28. getProjectsByFunder(address _funder): Returns an array of project IDs that a given address has funded.

// Total Functions: 28

// --- End of Outline and Summary ---


contract SynthetixNexus is Ownable {
    // --- Enums ---
    enum ProjectState {
        Proposed,      // Project is submitted, awaiting approval
        Approved,      // Project is approved, awaiting full funding
        Funded,        // Project has met its funding goal, awaiting start
        InProgress,    // Project is active, milestones are being worked on
        Completed,     // All milestones completed, IP minted
        Failed,        // Project failed to meet objectives or deadlines
        Disputed       // Project/milestone is under formal dispute
    }

    enum DisputeStatus {
        None,           // No active dispute
        UnderReview,    // Dispute initiated, awaiting resolution
        Resolved_ProposerWins, // Dispute resolved in favor of proposer
        Resolved_FunderWins    // Dispute resolved in favor of funders/evaluators
    }

    // --- Structs ---
    struct Milestone {
        string description;
        uint256 targetDate;      // Unix timestamp
        uint256 requiredFunds;   // Funds required for this specific milestone
        bool isAchieved;         // True if researcher reported completion
        bool isVerified;         // True if governor/evaluator verified completion
        bool fundsClaimed;       // True if funds for this milestone have been claimed
    }

    struct Project {
        uint256 id;
        address proposer;
        string title;
        string description;
        Milestone[] milestones;
        uint256 fundingGoal;
        uint256 currentFunds;      // Total funds received for the project
        uint256 releasedFunds;     // Funds released to the proposer for completed milestones
        ProjectState state;
        uint256 ipNFTId;           // 0 if no IP NFT minted yet
        uint256 startTime;         // Unix timestamp when project enters InProgress
        uint256 endTime;           // Unix timestamp when project completes or fails
        DisputeStatus disputeStatus;
        uint256 disputedMilestoneIndex; // Index of milestone under dispute, if any (0 for whole project)
    }

    struct Researcher {
        int256 reputationScore; // Can be positive or negative
        uint256[] activeProjectIds;
        uint256[] completedProjectIds;
        uint256[] failedProjectIds;
    }

    // Note: IPNFT details like URI, owner are managed by the external ERC721 contract.
    // This struct stores additional SynthetixNexus-specific details for the IP.
    struct IPNFTInfo {
        uint256 projectId;
        uint256 royaltyPercentage; // Basis points (e.g., 100 = 1%)
        uint256 accumulatedRoyalties; // In Synthesis Token units
    }

    // --- State Variables ---
    IERC20 public immutable synthesisToken;
    IERC721Minimal public immutable ipNFTContract; // Instance of the IP NFT contract
    address public governor; // A privileged role, distinct from contract owner, for operational control.

    uint256 private _projectCounter;
    uint256 private _ipNFTCounter;

    mapping(uint256 => Project) public projects;
    mapping(address => Researcher) public researchers;
    mapping(uint256 => IPNFTInfo) public ipNFTs; // Map NFT ID to its SynthetixNexus info
    mapping(uint256 => mapping(address => uint256)) public projectFunders; // projectId => funderAddress => amountFunded

    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 fundingGoal);
    event ProjectApproved(uint256 indexed projectId, address indexed approvedBy);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectStarted(uint256 indexed projectId);
    event MilestoneReported(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reporter);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneIndex, bool isAchieved, address indexed verifier);
    event MilestoneFundsClaimed(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectCompleted(uint256 indexed projectId, uint256 indexed ipNFTId, address indexed proposer);
    event ProjectFailed(uint256 indexed projectId, address indexed reporter, string reason);
    event IPNFTMinted(uint256 indexed ipNFTId, uint256 indexed projectId, address indexed owner, string tokenURI);
    event RoyaltiesDistributed(uint256 indexed ipNFTId, uint256 amount);
    event RoyaltiesClaimed(uint256 indexed ipNFTId, address indexed claimant, uint256 amount);
    event ReputationAdjusted(address indexed researcher, int256 delta, int256 newReputation);
    event DisputeInitiated(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed initiator);
    event DisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, DisputeStatus status, address indexed resolver);
    event FundsReallocated(uint256 indexed projectId, uint256 amount, address indexed recipient);
    event Paused(address account);
    event Unpaused(address account);
    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);

    // --- Modifiers ---
    modifier onlyGovernor() {
        require(msg.sender == governor, "SynthetixNexus: Only governor can call this function");
        _;
    }

    // Pausability state
    bool private _paused;
    modifier whenNotPaused() {
        require(!_paused, "SynthetixNexus: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "SynthetixNexus: Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor(address _synthesisTokenAddress, address _ipNFTContractAddress) Ownable(msg.sender) {
        require(_synthesisTokenAddress != address(0), "SynthetixNexus: Synthesis Token address cannot be zero");
        require(_ipNFTContractAddress != address(0), "SynthetixNexus: IP NFT Contract address cannot be zero");
        synthesisToken = IERC20(_synthesisTokenAddress);
        ipNFTContract = IERC721Minimal(_ipNFTContractAddress);
        governor = msg.sender; // Owner is initially the governor
        _projectCounter = 0;
        _ipNFTCounter = 0;
        _paused = false;
    }

    // --- I. Core Infrastructure & Setup ---

    /// @notice Grants an address the `governor` role, enabling privileged actions.
    /// @param _newGovernor The address to be set as the new governor.
    function setGovernor(address _newGovernor) public onlyOwner {
        require(_newGovernor != address(0), "SynthetixNexus: New governor cannot be zero address");
        address oldGovernor = governor;
        governor = _newGovernor;
        emit GovernorSet(oldGovernor, _newGovernor);
    }

    /// @notice Removes the `governor` role from the current governor.
    ///         The owner can always re-set it.
    function revokeGovernor() public onlyOwner {
        address oldGovernor = governor;
        governor = address(0);
        emit GovernorSet(oldGovernor, address(0));
    }

    /// @notice Allows the governor to temporarily halt critical contract operations for maintenance or emergencies.
    function pauseContract() public onlyGovernor whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Allows the governor to resume paused operations.
    function unpauseContract() public onlyGovernor whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- II. Project Lifecycle Management ---

    /// @notice Allows any researcher to submit a new R&D project proposal.
    ///         Projects are initially in `Proposed` state and require governor approval.
    /// @param _title The title of the research project.
    /// @param _description A detailed description of the project.
    /// @param _milestones An array of Milestone structs outlining project phases and required funds.
    /// @param _fundingGoal The total funding required for the project.
    function proposeProject(
        string calldata _title,
        string calldata _description,
        Milestone[] calldata _milestones,
        uint256 _fundingGoal
    ) public whenNotPaused {
        require(bytes(_title).length > 0, "SynthetixNexus: Title cannot be empty");
        require(bytes(_description).length > 0, "SynthetixNexus: Description cannot be empty");
        require(_milestones.length > 0, "SynthetixNexus: At least one milestone is required");
        require(_fundingGoal > 0, "SynthetixNexus: Funding goal must be greater than zero");

        uint256 calculatedMilestoneFunds = 0;
        for (uint256 i = 0; i < _milestones.length; i++) {
            require(_milestones[i].requiredFunds > 0, "SynthetixNexus: Milestone funds must be positive");
            require(_milestones[i].targetDate > block.timestamp, "SynthetixNexus: Milestone target date must be in the future");
            calculatedMilestoneFunds += _milestones[i].requiredFunds;
        }
        require(calculatedMilestoneFunds == _fundingGoal, "SynthetixNexus: Sum of milestone funds must equal funding goal");

        _projectCounter++;
        uint256 newProjectId = _projectCounter;

        projects[newProjectId] = Project({
            id: newProjectId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            milestones: _milestones,
            fundingGoal: _fundingGoal,
            currentFunds: 0,
            releasedFunds: 0,
            state: ProjectState.Proposed,
            ipNFTId: 0,
            startTime: 0,
            endTime: 0,
            disputeStatus: DisputeStatus.None,
            disputedMilestoneIndex: 0
        });

        // Add to researcher's active projects
        researchers[msg.sender].activeProjectIds.push(newProjectId);

        emit ProjectProposed(newProjectId, msg.sender, _fundingGoal);
    }

    /// @notice A governor-only function to officially approve a proposed project, making it eligible for funding.
    /// @param _projectId The ID of the project to approve.
    function approveProject(uint256 _projectId) public onlyGovernor whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.state == ProjectState.Proposed, "SynthetixNexus: Project is not in Proposed state");

        project.state = ProjectState.Approved;
        emit ProjectApproved(_projectId, msg.sender);
    }

    /// @notice Enables anyone to contribute funding to an approved project using the designated Synthesis Token.
    ///         Funds are held in escrow by this contract.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount of Synthesis Tokens to contribute.
    function fundProject(uint256 _projectId, uint256 _amount) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.state == ProjectState.Approved || project.state == ProjectState.Funded, "SynthetixNexus: Project is not approved or fully funded yet");
        require(_amount > 0, "SynthetixNexus: Funding amount must be greater than zero");
        require(project.currentFunds + _amount <= project.fundingGoal, "SynthetixNexus: Funding amount exceeds remaining goal");

        // Transfer funds from funder to this contract
        bool success = synthesisToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "SynthetixNexus: Token transfer failed");

        project.currentFunds += _amount;
        projectFunders[_projectId][msg.sender] += _amount;

        if (project.currentFunds >= project.fundingGoal && project.state == ProjectState.Approved) {
            project.state = ProjectState.Funded;
        }
        emit ProjectFunded(_projectId, msg.sender, _amount);
    }

    /// @notice Initiates an approved and sufficiently funded project, transitioning it to `InProgress` state.
    ///         Can only be called by the project proposer once funding is met.
    /// @param _projectId The ID of the project to start.
    function startProject(uint256 _projectId) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.proposer == msg.sender, "SynthetixNexus: Only project proposer can start it");
        require(project.state == ProjectState.Funded, "SynthetixNexus: Project is not in Funded state");
        require(project.currentFunds >= project.fundingGoal, "SynthetixNexus: Project has not met its funding goal");

        project.state = ProjectState.InProgress;
        project.startTime = block.timestamp;
        emit ProjectStarted(_projectId);
    }

    /// @notice Researcher reports the completion of a specific milestone, providing external evidence.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone (0-based).
    /// @param _evidenceURI An URI pointing to evidence of completion (e.g., IPFS hash).
    function reportMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _evidenceURI
    ) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.proposer == msg.sender, "SynthetixNexus: Only project proposer can report milestones");
        require(project.state == ProjectState.InProgress, "SynthetixNexus: Project is not in InProgress state");
        require(_milestoneIndex < project.milestones.length, "SynthetixNexus: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].isAchieved, "SynthetixNexus: Milestone already reported as achieved");
        require(bytes(_evidenceURI).length > 0, "SynthetixNexus: Evidence URI is required");

        project.milestones[_milestoneIndex].isAchieved = true;
        // The evidence URI is noted in the event, but for on-chain integrity, a robust system
        // might store this URI in the Milestone struct, if gas costs allow.
        emit MilestoneReported(_projectId, _milestoneIndex, msg.sender);
    }

    /// @notice Governor or designated evaluators verify the reported milestone completion.
    ///         Affects the project's progress and researcher's reputation.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _isAchieved True if the milestone is verified as completed, false otherwise.
    function verifyMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _isAchieved
    ) public onlyGovernor whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.state == ProjectState.InProgress, "SynthetixNexus: Project is not in InProgress state");
        require(_milestoneIndex < project.milestones.length, "SynthetixNexus: Invalid milestone index");
        require(project.milestones[_milestoneIndex].isAchieved, "SynthetixNexus: Milestone not reported by researcher yet");
        require(!project.milestones[_milestoneIndex].isVerified, "SynthetixNexus: Milestone already verified");
        require(project.disputeStatus == DisputeStatus.None, "SynthetixNexus: Cannot verify while dispute is active");

        project.milestones[_milestoneIndex].isVerified = true;
        _adjustReputation(project.proposer, _isAchieved ? 10 : -10); // Adjust reputation based on verification

        emit MilestoneVerified(_projectId, _milestoneIndex, _isAchieved, msg.sender);

        if (!_isAchieved) {
            // If verification fails, it could trigger automatic project failure or dispute
            // For now, it just marks it as not verified achieved and gives a penalty.
            // A more complex system might automatically initiate dispute or transition to Failed after N failures.
        }
    }

    /// @notice Allows the researcher to request funds for a completed and verified milestone.
    ///         Funds are released from the contract's escrow to the project proposer.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    function requestMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.proposer == msg.sender, "SynthetixNexus: Only project proposer can request funds");
        require(project.state == ProjectState.InProgress, "SynthetixNexus: Project is not in InProgress state");
        require(_milestoneIndex < project.milestones.length, "SynthetixNexus: Invalid milestone index");
        require(project.milestones[_milestoneIndex].isVerified, "SynthetixNexus: Milestone not yet verified");
        require(!project.milestones[_milestoneIndex].fundsClaimed, "SynthetixNexus: Funds for this milestone already claimed");
        require(project.disputeStatus == DisputeStatus.None, "SynthetixNexus: Cannot claim funds while dispute is active");

        uint256 fundsToRelease = project.milestones[_milestoneIndex].requiredFunds;
        require(project.currentFunds - project.releasedFunds >= fundsToRelease, "SynthetixNexus: Insufficient unreleased funds for this milestone");

        bool success = synthesisToken.transfer(project.proposer, fundsToRelease);
        require(success, "SynthetixNexus: Funds transfer failed");

        project.releasedFunds += fundsToRelease;
        project.milestones[_milestoneIndex].fundsClaimed = true;

        emit MilestoneFundsClaimed(_projectId, _milestoneIndex, fundsToRelease);
    }

    /// @notice The researcher finalizes a project after all milestones are completed.
    ///         This triggers the minting of an IP NFT and sets its initial royalty percentage.
    /// @param _projectId The ID of the project.
    /// @param _finalIPURI An URI pointing to the final Intellectual Property (e.g., IPFS hash of research paper, code).
    /// @param _royaltyPercentage The initial royalty percentage (in basis points, e.g., 100 = 1%) for future IP utilization.
    function completeProject(
        uint256 _projectId,
        string calldata _finalIPURI,
        uint256 _royaltyPercentage
    ) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.proposer == msg.sender, "SynthetixNexus: Only project proposer can complete it");
        require(project.state == ProjectState.InProgress, "SynthetixNexus: Project is not in InProgress state");
        require(bytes(_finalIPURI).length > 0, "SynthetixNexus: Final IP URI is required");
        require(_royaltyPercentage <= 10000, "SynthetixNexus: Royalty percentage cannot exceed 100%"); // 10000 basis points = 100%

        // Check if all milestones are completed and funds claimed (optional, but good practice)
        for (uint256 i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].isVerified, "SynthetixNexus: All milestones must be verified to complete project");
            require(project.milestones[i].fundsClaimed, "SynthetixNexus: All milestone funds must be claimed to complete project");
        }

        // Adjust researcher reputation for successful completion
        _adjustReputation(project.proposer, 50); // Significant boost for full project completion

        project.state = ProjectState.Completed;
        project.endTime = block.timestamp;

        // Mint IP NFT
        uint256 newIpNFTId = _mintIPNFT(_projectId, project.proposer, _finalIPURI, _royaltyPercentage);
        project.ipNFTId = newIpNFTId;

        // Move project from active to completed list for researcher
        _moveProjectToCompleted(project.proposer, _projectId);

        emit ProjectCompleted(_projectId, newIpNFTId, project.proposer);
    }

    /// @notice Allows a project to be officially marked as failed.
    ///         Can be called by the proposer (e.g., if they give up) or the governor (after assessment).
    ///         Leads to reputation adjustments and potential fund reallocation.
    /// @param _projectId The ID of the project.
    /// @param _reason The reason for project failure.
    function failProject(uint256 _projectId, string calldata _reason) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.proposer == msg.sender || msg.sender == governor, "SynthetixNexus: Only proposer or governor can fail project");
        require(project.state == ProjectState.InProgress || project.state == ProjectState.Funded || project.state == ProjectState.Approved, "SynthetixNexus: Project cannot be failed in current state");
        require(project.state != ProjectState.Completed, "SynthetixNexus: Completed projects cannot be failed");
        require(bytes(_reason).length > 0, "SynthetixNexus: Reason for failure is required");
        require(project.disputeStatus == DisputeStatus.None, "SynthetixNexus: Cannot fail project while dispute is active");

        _adjustReputation(project.proposer, -50); // Significant penalty for project failure

        project.state = ProjectState.Failed;
        project.endTime = block.timestamp;

        // Move project from active to failed list for researcher
        _moveProjectToFailed(project.proposer, _projectId);

        // Funds that were not claimed for milestones remain in the contract and can be returned
        // via `reallocateDisputedFunds` by individual funders.
        emit ProjectFailed(_projectId, msg.sender, _reason);
    }

    // --- III. Intellectual Property (IP) & Royalty Management ---

    /// @notice Internal function to mint a new IP NFT upon project completion.
    ///         Called by `completeProject`.
    /// @param _projectId The ID of the project associated with this IP NFT.
    /// @param _owner The address that will own the new IP NFT.
    /// @param _tokenURI The URI for the NFT metadata (e.g., IPFS link to research details).
    /// @param _royaltyPercentage The royalty percentage for this IP NFT.
    /// @return The ID of the newly minted IP NFT.
    function _mintIPNFT(
        uint256 _projectId,
        address _owner,
        string calldata _tokenURI,
        uint256 _royaltyPercentage
    ) internal returns (uint256) {
        _ipNFTCounter++;
        uint256 newIpNFTId = _ipNFTCounter;

        // Placeholder for actual ERC721 minting.
        // In a real dApp, `ipNFTContract` would be a custom ERC721 contract
        // with a minting function accessible by this `SynthetixNexus` contract.
        // For example: `IERC721Custom(address(ipNFTContract)).mint(_owner, newIpNFTId, _tokenURI);`
        // Given IERC721Minimal, we only conceptually "mint" and emit the event.
        ipNFTs[newIpNFTId] = IPNFTInfo({
            projectId: _projectId,
            royaltyPercentage: _royaltyPercentage,
            accumulatedRoyalties: 0
        });

        emit IPNFTMinted(newIpNFTId, _projectId, _owner, _tokenURI);
        return newIpNFTId;
    }


    /// @notice Allows anyone to deposit royalty payments to a specific IP NFT.
    ///         These funds are held in escrow by this contract for the IP NFT owner.
    /// @param _ipNFTId The ID of the IP NFT to distribute royalties to.
    /// @param _amount The amount of Synthesis Tokens to contribute as royalty.
    function distributeRoyalties(uint256 _ipNFTId, uint256 _amount) public whenNotPaused {
        require(ipNFTs[_ipNFTId].projectId != 0, "SynthetixNexus: IP NFT not found");
        require(_amount > 0, "SynthetixNexus: Amount must be greater than zero");

        bool success = synthesisToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "SynthetixNexus: Token transfer failed");

        ipNFTs[_ipNFTId].accumulatedRoyalties += _amount;
        emit RoyaltiesDistributed(_ipNFTId, _amount);
    }

    /// @notice Allows the current owner of an IP NFT to withdraw their accumulated royalty payments.
    /// @param _ipNFTId The ID of the IP NFT.
    function claimRoyalties(uint256 _ipNFTId) public whenNotPaused {
        require(ipNFTs[_ipNFTId].projectId != 0, "SynthetixNexus: IP NFT not found");
        address currentNFTOwner = ipNFTContract.ownerOf(_ipNFTId);
        require(currentNFTOwner == msg.sender, "SynthetixNexus: Only IP NFT owner can claim royalties");

        uint256 availableRoyalties = ipNFTs[_ipNFTId].accumulatedRoyalties;
        require(availableRoyalties > 0, "SynthetixNexus: No royalties to claim");

        ipNFTs[_ipNFTId].accumulatedRoyalties = 0; // Reset accumulated royalties before transfer
        bool success = synthesisToken.transfer(currentNFTOwner, availableRoyalties);
        require(success, "SynthetixNexus: Royalty transfer failed");

        emit RoyaltiesClaimed(_ipNFTId, currentNFTOwner, availableRoyalties);
    }

    /// @notice Allows the IP NFT owner to propose an update to the royalty percentage.
    ///         In a more advanced system, this would trigger a governance vote. Here, it's direct.
    /// @param _ipNFTId The ID of the IP NFT.
    /// @param _newPercentage The new royalty percentage (basis points).
    function updateIPNFTRoyaltyPercentage(uint256 _ipNFTId, uint256 _newPercentage) public whenNotPaused {
        require(ipNFTs[_ipNFTId].projectId != 0, "SynthetixNexus: IP NFT not found");
        address currentNFTOwner = ipNFTContract.ownerOf(_ipNFTId);
        require(currentNFTOwner == msg.sender, "SynthetixNexus: Only IP NFT owner can update royalty percentage");
        require(_newPercentage <= 10000, "SynthetixNexus: Royalty percentage cannot exceed 100%");

        ipNFTs[_ipNFTId].royaltyPercentage = _newPercentage;
        // An event for royalty update could be added if external tracking is desired.
    }

    // --- IV. Reputation System ---

    /// @notice Retrieves the current reputation score for a given researcher address.
    /// @param _researcher The address of the researcher.
    /// @return The reputation score.
    function getResearcherReputation(address _researcher) public view returns (int256) {
        return researchers[_researcher].reputationScore;
    }

    /// @notice Internal, privileged function to modify a researcher's reputation score.
    ///         Called based on project performance (success/failure, milestone verification).
    /// @param _researcher The address of the researcher.
    /// @param _delta The amount to adjust the reputation by (can be positive or negative).
    function _adjustReputation(address _researcher, int256 _delta) internal {
        researchers[_researcher].reputationScore += _delta;
        emit ReputationAdjusted(_researcher, _delta, researchers[_researcher].reputationScore);
    }

    // Helper functions for researcher project arrays
    function _removeProjectFromList(address _researcher, uint256 _projectId, uint256[] storage _list) internal {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _projectId) {
                _list[i] = _list[_list.length - 1]; // Swap with last element
                _list.pop(); // Remove last element
                break;
            }
        }
    }

    function _moveProjectToCompleted(address _researcher, uint256 _projectId) internal {
        _removeProjectFromList(_researcher, _projectId, researchers[_researcher].activeProjectIds);
        researchers[_researcher].completedProjectIds.push(_projectId);
    }

    function _moveProjectToFailed(address _researcher, uint256 _projectId) internal {
        _removeProjectFromList(_researcher, _projectId, researchers[_researcher].activeProjectIds);
        researchers[_researcher].failedProjectIds.push(_projectId);
    }

    // --- V. Dispute Resolution ---

    /// @notice Allows a stakeholder (funder, evaluator, or even the proposer) to formally challenge a project's state or a milestone's completion.
    ///         This puts the project into a `Disputed` state.
    /// @param _projectId The ID of the project under dispute.
    /// @param _milestoneIndex The index of the milestone being disputed (0 if the whole project is disputed).
    /// @param _reason A description of the dispute.
    function initiateDispute(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _reason
    ) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(
            project.state == ProjectState.InProgress || project.state == ProjectState.Funded,
            "SynthetixNexus: Project cannot be disputed in current state (must be InProgress or Funded)"
        );
        require(project.disputeStatus == DisputeStatus.None, "SynthetixNexus: Project already under dispute");
        require(bytes(_reason).length > 0, "SynthetixNexus: Reason for dispute is required");

        if (_milestoneIndex != 0) { // Specific milestone dispute
            require(_milestoneIndex < project.milestones.length, "SynthetixNexus: Invalid milestone index for dispute");
            // Further checks could be added, e.g., only dispute if milestone is reported/verified but seems incorrect.
        }

        project.state = ProjectState.Disputed;
        project.disputeStatus = DisputeStatus.UnderReview;
        project.disputedMilestoneIndex = _milestoneIndex;

        emit DisputeInitiated(_projectId, _milestoneIndex, msg.sender);
    }

    /// @notice Governor or designated arbitrators resolve an ongoing dispute.
    ///         Determines its outcome and affects project state and researcher reputation.
    /// @param _projectId The ID of the disputed project.
    /// @param _milestoneIndex The index of the disputed milestone (0 if project-wide).
    /// @param _proposerWins True if the dispute is resolved in favor of the project proposer, false otherwise.
    /// @param _resolutionDetails A description of the resolution (not stored on-chain to save gas, but good for events).
    function resolveDispute(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _proposerWins,
        string calldata _resolutionDetails // For external record-keeping
    ) public onlyGovernor whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(project.state == ProjectState.Disputed, "SynthetixNexus: Project is not in Disputed state");
        require(project.disputeStatus == DisputeStatus.UnderReview, "SynthetixNexus: No active dispute to resolve");
        require(project.disputedMilestoneIndex == _milestoneIndex, "SynthetixNexus: Mismatch in disputed milestone index");

        if (_proposerWins) {
            project.disputeStatus = DisputeStatus.Resolved_ProposerWins;
            // Revert project state back to InProgress (or previous functional state)
            project.state = ProjectState.InProgress;
            if (_milestoneIndex != 0) {
                // If specific milestone, mark it as verified if dispute was about its verification
                project.milestones[_milestoneIndex].isVerified = true;
                _adjustReputation(project.proposer, 5); // Small boost for winning dispute
            }
        } else {
            project.disputeStatus = DisputeStatus.Resolved_FunderWins;
            // Mark project as failed, or milestone as failed verification
            project.state = ProjectState.Failed;
            _adjustReputation(project.proposer, -20); // Penalty for losing dispute and project failure
            _moveProjectToFailed(project.proposer, _projectId);
        }

        project.disputedMilestoneIndex = 0; // Reset disputed milestone index
        emit DisputeResolved(_projectId, _milestoneIndex, project.disputeStatus, msg.sender);
    }

    /// @notice Executes the reallocation of funds (return to funders)
    ///         if the project failed or a dispute resulted in funder winning.
    ///         Can be called by any funder to claim their portion if project failed or dispute results in funder win.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The milestone index (if dispute was specific to it, otherwise 0). This parameter is primarily for context and event.
    function reallocateDisputedFunds(uint256 _projectId, uint256 _milestoneIndex) public whenNotPaused {
        // _milestoneIndex is currently unused but kept for interface consistency with `resolveDispute`
        // and potential future granular fund reallocation logic.
        _milestoneIndex; // Silence unused variable warning

        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthetixNexus: Project not found");
        require(
            project.state == ProjectState.Failed || (project.state == ProjectState.Disputed && project.disputeStatus == DisputeStatus.Resolved_FunderWins),
            "SynthetixNexus: Project not in a state for fund reallocation (must be Failed or Disputed-FunderWins)"
        );

        uint256 totalUnreleasedFunds = project.currentFunds - project.releasedFunds;
        require(totalUnreleasedFunds > 0, "SynthetixNexus: No unreleased funds available for reallocation");

        uint256 funderContribution = projectFunders[_projectId][msg.sender];
        require(funderContribution > 0, "SynthetixNexus: No funds contributed by this address to project");

        // Proportionate refund: (funder's contribution / total funds) * total unreleased funds
        uint256 refundableAmount = (funderContribution * totalUnreleasedFunds) / project.currentFunds;
        require(refundableAmount > 0, "SynthetixNexus: No refundable amount for this funder");

        // Reset the funder's recorded contribution for this project to prevent double claims
        projectFunders[_projectId][msg.sender] = 0;

        bool success = synthesisToken.transfer(msg.sender, refundableAmount);
        require(success, "SynthetixNexus: Refund transfer failed");

        // Note: `totalUnreleasedFunds` is implicitly reduced as individual funders claim.
        // `currentFunds` and `releasedFunds` track gross amounts; a separate variable would be needed
        // to track remaining refundable pool explicitly if that was critical for other operations.

        emit FundsReallocated(_projectId, refundableAmount, msg.sender);
    }

    // --- VI. Utility & Information Access ---

    /// @notice Provides comprehensive details of a specific project.
    /// @param _projectId The ID of the project.
    /// @return projectStruct All details of the project.
    function getProjectDetails(uint256 _projectId) public view returns (Project memory projectStruct) {
        require(projects[_projectId].id != 0, "SynthetixNexus: Project not found");
        return projects[_projectId];
    }

    /// @notice Fetches the details of a particular milestone within a project.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @return milestoneStruct Details of the specific milestone.
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex) public view returns (Milestone memory milestoneStruct) {
        require(projects[_projectId].id != 0, "SynthetixNexus: Project not found");
        require(_milestoneIndex < projects[_projectId].milestones.length, "SynthetixNexus: Invalid milestone index");
        return projects[_projectId].milestones[_milestoneIndex];
    }

    /// @notice Returns information about a specific IP NFT, including its associated project and royalty settings.
    /// @param _ipNFTId The ID of the IP NFT.
    /// @return projectId The ID of the project this NFT is associated with.
    /// @return royaltyPercentage The royalty percentage in basis points.
    /// @return accumulatedRoyalties The accumulated royalty funds in Synthesis Tokens.
    /// @return currentOwner The current owner address of the IP NFT (retrieved from ERC721 contract).
    function getIPNFTDetails(uint256 _ipNFTId) public view returns (
        uint256 projectId,
        uint256 royaltyPercentage,
        uint256 accumulatedRoyalties,
        address currentOwner
    ) {
        IPNFTInfo storage ipNFT = ipNFTs[_ipNFTId];
        require(ipNFT.projectId != 0, "SynthetixNexus: IP NFT not found");
        return (
            ipNFT.projectId,
            ipNFT.royaltyPercentage,
            ipNFT.accumulatedRoyalties,
            ipNFTContract.ownerOf(_ipNFTId)
        );
    }

    /// @notice Returns an array of project IDs associated with a given researcher, categorized by their state.
    /// @param _researcher The address of the researcher.
    /// @return activeProjects A list of project IDs currently active.
    /// @return completedProjects A list of project IDs successfully completed.
    /// @return failedProjects A list of project IDs that failed.
    function getProjectsByResearcher(address _researcher) public view returns (
        uint256[] memory activeProjects,
        uint256[] memory completedProjects,
        uint256[] memory failedProjects
    ) {
        return (
            researchers[_researcher].activeProjectIds,
            researchers[_researcher].completedProjectIds,
            researchers[_researcher].failedProjectIds
        );
    }

    /// @notice Returns an array of project IDs that a given address has funded.
    ///         Note: This only indicates past funding, not current 'investment' status or refundable amount.
    /// @param _funder The address of the funder.
    /// @return fundedProjectIds An array of project IDs funded by the given address.
    function getProjectsByFunder(address _funder) public view returns (uint256[] memory fundedProjectIds) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _projectCounter; i++) {
            if (projectFunders[i][_funder] > 0) {
                count++;
            }
        }

        fundedProjectIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _projectCounter; i++) {
            if (projectFunders[i][_funder] > 0) {
                fundedProjectIds[index] = i;
                index++;
            }
        }
        return fundedProjectIds;
    }

    // Utility for paused state
    function paused() public view returns (bool) {
        return _paused;
    }
}

```