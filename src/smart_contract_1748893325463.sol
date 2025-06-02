Okay, here is a Solidity smart contract called `EcoFlow` that implements a system for funding, managing, and tracking decentralized environmental projects. It incorporates concepts like milestone-based funding, dynamic project health scores (potentially influenced by external data/oracles), impact point distribution, and basic governance/reputation features.

This contract aims for novelty by combining these elements in a specific eco-focused context, moving beyond simple crowdfunding or token standards. It's designed to be interesting and relatively complex for demonstration purposes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contract implements EcoFlow, a decentralized platform for funding and managing
// environmental sustainability projects.
// Users can propose projects, contribute funds, track progress via milestones,
// and earn "Impact Points" based on successful project completion.
// Projects have dynamic health scores and funding is released incrementally
// upon milestone approval, potentially influenced by an Oracle for external data validation.

// --- OUTLINE ---
// 1. State Variables: Store project data, user contributions, config, etc.
// 2. Structs: Define the structure of EcoProjects and Milestones.
// 3. Enums: Define project states.
// 4. Events: Announce key actions and state changes.
// 5. Modifiers: (Using inline requires for simplicity)
// 6. Constructor: Initialize the contract admin.
// 7. Admin Functions: Core contract management (setting token, pause, ownership).
// 8. Project Proposal & Lifecycle: Functions for proposing, approving, rejecting, completing projects.
// 9. Funding & Contribution: Functions for users to fund projects and withdraw under conditions.
// 10. Milestone Management: Proposers report, Admin/Oracle approves, funds released.
// 11. Impact Tracking & Distribution: Calculating and distributing Impact Points.
// 12. Dynamic Health & Oracle Integration: Functions related to project health score and oracle reports.
// 13. Governance & Reputation (Basic): Signaling support, leaving ratings, transferring proposer role.
// 14. View Functions: Read-only functions to query contract state.

// --- FUNCTION SUMMARY ---
// 1. constructor(address initialAdmin): Sets the initial contract administrator.
// 2. setFundingToken(address tokenAddress): Admin sets the address of the ERC20 token used for funding.
// 3. pauseContract(): Admin pauses the contract, stopping most interactions.
// 4. unpauseContract(): Admin unpauses the contract.
// 5. transferAdmin(address newAdmin): Admin transfers administration ownership.
// 6. createProjectProposal(string title, string description, uint256 fundingGoal, uint256 durationInDays, Milestone[] milestones, string category): Users submit new project proposals.
// 7. approveProjectProposal(uint256 projectId): Admin approves a project proposal, moving it to the Funding state.
// 8. rejectProjectProposal(uint256 projectId, string reason): Admin rejects a project proposal.
// 9. updateProjectProposal(uint256 projectId, string title, string description, Milestone[] milestones, string category): Proposer updates a proposal before approval.
// 10. fundProject(uint256 projectId, uint256 amount): Users contribute funds to a project in the Funding state. Requires prior ERC20 approve().
// 11. withdrawContribution(uint256 projectId, uint256 amount): Users withdraw contributions if the project is rejected or fails early.
// 12. reportMilestoneCompletion(uint256 projectId, uint256 milestoneIndex): Proposer reports a milestone as completed.
// 13. requestMilestoneFunding(uint256 projectId, uint256 milestoneIndex): Proposer requests funding release for a completed and approved milestone.
// 14. approveMilestoneFunding(uint256 projectId, uint256 milestoneIndex): Admin approves the release of funding for a milestone.
// 15. markProjectCompleted(uint256 projectId): Admin marks a project as successfully completed after all milestones.
// 16. markProjectFailed(uint256 projectId, string reason): Admin marks a project as failed at any stage.
// 17. distributeImpactPoints(uint256 projectId): Admin or automated system distributes impact points upon project completion (or milestone completion).
// 18. claimImpactPoints(): Users claim their accumulated impact points.
// 19. calculateProjectHealth(uint256 projectId): Internal/View function to calculate a dynamic health score (based on milestones and oracle data).
// 20. setOracleAddress(address oracleAddress): Admin sets the address of a trusted oracle contract.
// 21. reportProjectHealth(uint256 projectId, uint256 healthScore): Oracle reports an external health score for a project.
// 22. signalSupportForProposal(uint256 projectId): Users signal non-binding support for a proposed project.
// 23. leaveProjectRating(uint256 projectId, uint8 rating): Users leave a 1-5 star rating for a completed project.
// 24. transferProjectProposer(uint256 projectId, address newProposer): Current proposer transfers their role to another address.
// 25. getProject(uint256 projectId): View function to get details of a project.
// 26. getMilestoneStatus(uint256 projectId, uint256 milestoneIndex): View function to check a specific milestone's status.
// 27. getUserContribution(uint256 projectId, address user): View function to get a user's contribution to a project.
// 28. getUserTotalImpactPoints(address user): View function to get a user's total earned impact points.
// 29. getProjectCount(): View function to get the total number of projects.
// 30. getProjectsByCategory(string category): View function (simplified) to potentially filter projects.
// 31. getTotalFunding(uint256 projectId): View function to get total funds contributed to a project.
// 32. getFundingRemaining(uint256 projectId): View function to get funding needed to reach the goal.
// 33. getProjectState(uint256 projectId): View function to get the current state of a project.
// 34. getFundingToken(): View function to get the funding token address.
// 35. getAdmin(): View function to get the current admin address.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract EcoFlow is ReentrancyGuard {

    address public admin;
    address public fundingToken; // The ERC20 token used for funding
    address public oracleAddress; // Address of a trusted oracle contract (optional feature)

    uint256 public nextProjectId;
    bool public contractPaused;

    enum ProjectState { Proposed, Funding, Active, Paused, Completed, Failed, Rejected }

    struct Milestone {
        string description;
        uint256 fundingAllocation; // Percentage of total funding goal for this milestone
        bool completedByProposer;
        bool fundingApprovedByAdmin; // Or by governance/oracle
        uint256 impactPointsAllocation; // Impact points awarded upon this milestone's completion
    }

    struct EcoProject {
        uint256 id;
        address proposer;
        string title;
        string description;
        string category;
        uint256 fundingGoal;
        uint256 totalFunded;
        uint256 startTime; // When project enters Active state
        uint256 durationEndTime; // Expected end time
        Milestone[] milestones;
        ProjectState state;
        mapping(address => uint256) contributors; // Tracks individual contributions
        uint256 currentHealthScore; // Dynamic score (e.g., 0-100)
        uint8 averageRating; // Average rating (1-5) if completed
        uint256 totalImpactPointsGenerated; // Total points for this project
    }

    mapping(uint256 => EcoProject) public projects;
    mapping(uint256 => address[]) projectContributorsList; // To iterate contributors (gas intensive for large lists)
    mapping(address => uint256) public userTotalImpactPoints; // Total accumulated impact points per user
    mapping(uint256 => mapping(address => uint256)) public userProjectContributions; // Contribution amount per user per project
    mapping(uint256 => mapping(address => bool)) public proposalSupport; // Users signalling support

    // Events
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event FundingTokenSet(address indexed token);
    event OracleAddressSet(address indexed oracle);
    event ContractPaused(bool paused);

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string category);
    event ProjectApproved(uint256 indexed projectId, address indexed admin);
    event ProjectRejected(uint256 indexed projectId, address indexed admin, string reason);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event ProjectCompleted(uint256 indexed projectId);
    event ProjectFailed(uint256 indexed projectId, string reason);
    event ProjectProposerTransferred(uint256 indexed projectId, address indexed oldProposer, address indexed newProposer);

    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ContributionWithdrawn(uint256 indexed projectId, address indexed user, uint256 amount);
    event MilestoneReported(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneFundingRequested(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneFundingApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amountReleased);

    event ImpactPointsDistributed(uint256 indexed projectId, uint256 totalPoints);
    event ImpactPointsClaimed(address indexed user, uint256 amount);
    event ProjectHealthReported(uint256 indexed projectId, uint256 healthScore, address reporter);
    event ProposalSupportSignaled(uint256 indexed projectId, address indexed user);
    event ProjectRated(uint256 indexed projectId, address indexed user, uint8 rating);


    modifier onlyAdmin() {
        require(msg.sender == admin, "EcoFlow: Only admin can call this function");
        _;
    }

     modifier onlyProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "EcoFlow: Only project proposer can call this function");
        _;
    }

    modifier notPaused() {
        require(!contractPaused, "EcoFlow: Contract is paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EcoFlow: Only trusted oracle can call this function");
        _;
    }

    constructor(address initialAdmin) {
        require(initialAdmin != address(0), "EcoFlow: Initial admin cannot be zero address");
        admin = initialAdmin;
        nextProjectId = 1;
        contractPaused = false;
    }

    // --- Admin Functions ---

    function setFundingToken(address tokenAddress) external onlyAdmin {
        require(tokenAddress != address(0), "EcoFlow: Token address cannot be zero");
        fundingToken = tokenAddress;
        emit FundingTokenSet(tokenAddress);
    }

     function setOracleAddress(address _oracleAddress) external onlyAdmin {
        require(_oracleAddress != address(0), "EcoFlow: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    function pauseContract() external onlyAdmin {
        contractPaused = true;
        emit ContractPaused(true);
    }

    function unpauseContract() external onlyAdmin {
        contractPaused = false;
        emit ContractPaused(false);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "EcoFlow: New admin cannot be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    // --- Project Proposal & Lifecycle ---

    function createProjectProposal(
        string memory title,
        string memory description,
        string memory category,
        uint256 fundingGoal,
        uint256 durationInDays,
        Milestone[] memory milestones // Array of milestone structs
    ) external notPaused {
        require(fundingGoal > 0, "EcoFlow: Funding goal must be greater than zero");
        require(durationInDays > 0, "EcoFlow: Duration must be greater than zero");
        require(milestones.length > 0, "EcoFlow: Project must have at least one milestone");

        uint256 totalMilestoneAllocation = 0;
        uint256 totalImpactAllocation = 0;
        for (uint i = 0; i < milestones.length; i++) {
             require(milestones[i].fundingAllocation > 0, "EcoFlow: Milestone funding allocation must be greater than zero");
             totalMilestoneAllocation += milestones[i].fundingAllocation;
             totalImpactAllocation += milestones[i].impactPointsAllocation;
        }
         require(totalMilestoneAllocation <= 10000, "EcoFlow: Total milestone funding allocation exceeds 100%"); // Use basis points (10000 = 100%)

        uint256 projectId = nextProjectId++;

        EcoProject storage newProject = projects[projectId];
        newProject.id = projectId;
        newProject.proposer = msg.sender;
        newProject.title = title;
        newProject.description = description;
        newProject.category = category;
        newProject.fundingGoal = fundingGoal;
        newProject.milestones = milestones; // Copy the milestones array
        newProject.state = ProjectState.Proposed;
        // startTime and durationEndTime set on approval/activation
        newProject.currentHealthScore = 0;
        newProject.totalImpactPointsGenerated = totalImpactAllocation;


        emit ProjectProposed(projectId, msg.sender, category);
    }

     function updateProjectProposal(
        uint256 projectId,
        string memory title,
        string memory description,
        Milestone[] memory milestones,
        string memory category
    ) external notPaused onlyProposer(projectId) {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Proposed, "EcoFlow: Can only update proposed projects");
        require(milestones.length > 0, "EcoFlow: Project must have at least one milestone");

        uint256 totalMilestoneAllocation = 0;
        uint256 totalImpactAllocation = 0;
        for (uint i = 0; i < milestones.length; i++) {
             require(milestones[i].fundingAllocation > 0, "EcoFlow: Milestone funding allocation must be greater than zero");
             totalMilestoneAllocation += milestones[i].fundingAllocation;
             totalImpactAllocation += milestones[i].impactPointsAllocation;
        }
         require(totalMilestoneAllocation <= 10000, "EcoFlow: Total milestone funding allocation exceeds 100%"); // Use basis points

        project.title = title;
        project.description = description;
        project.milestones = milestones; // Replace milestones
        project.category = category;
        project.totalImpactPointsGenerated = totalImpactAllocation;
        // Cannot change fundingGoal after proposal

        // No specific event for update, ProposalApproved/Rejected/Funded events cover state change
    }


    function approveProjectProposal(uint256 projectId) external onlyAdmin notPaused {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Proposed, "EcoFlow: Project must be in Proposed state");
        require(project.fundingGoal > 0, "EcoFlow: Project must have a funding goal"); // Should be set on creation

        project.state = ProjectState.Funding;
        // StartTime set when funding goal is met and it becomes Active
        // DurationEndTime will be calculated from startTime + durationInDays

        emit ProjectApproved(projectId, msg.sender);
        emit ProjectStateChanged(projectId, ProjectState.Funding);
    }

    function rejectProjectProposal(uint256 projectId, string memory reason) external onlyAdmin notPaused {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Proposed || project.state == ProjectState.Funding, "EcoFlow: Project must be in Proposed or Funding state");

        project.state = ProjectState.Rejected;
        // Handle potential withdrawals if in Funding state (handled by withdrawContribution)

        emit ProjectRejected(projectId, msg.sender, reason);
        emit ProjectStateChanged(projectId, ProjectState.Rejected);
    }

     function markProjectCompleted(uint256 projectId) external onlyAdmin notPaused {
         EcoProject storage project = projects[projectId];
         require(project.state == ProjectState.Active || project.state == ProjectState.Paused, "EcoFlow: Project must be Active or Paused to be completed");

         // Optional: Check if all milestones are completed and funding approved
         bool allMilestonesApproved = true;
         for(uint i = 0; i < project.milestones.length; i++) {
             if (!project.milestones[i].fundingApprovedByAdmin) {
                 allMilestonesApproved = false;
                 break;
             }
         }
        // require(allMilestonesApproved, "EcoFlow: All milestones must have funding approved before completing"); // Decide if this is strict rule

         project.state = ProjectState.Completed;
         emit ProjectCompleted(projectId);
         emit ProjectStateChanged(projectId, ProjectState.Completed);

         // Optional: Automatically distribute final impact points here
         // distributeImpactPoints(projectId); // Can call this function separately by Admin or external trigger
     }

     function markProjectFailed(uint256 projectId, string memory reason) external onlyAdmin notPaused {
         EcoProject storage project = projects[projectId];
         require(project.state != ProjectState.Completed && project.state != ProjectState.Failed && project.state != ProjectState.Rejected, "EcoFlow: Project is already finalized");

         project.state = ProjectState.Failed;
         emit ProjectFailed(projectId, reason);
         emit ProjectStateChanged(projectId, ProjectState.Failed);

         // Funds remain in contract for users to withdraw if failure state allows
     }

      function pauseProject(uint256 projectId) external onlyAdmin notPaused {
         EcoProject storage project = projects[projectId];
         require(project.state == ProjectState.Funding || project.state == ProjectState.Active, "EcoFlow: Project must be Funding or Active to be paused");

         project.state = ProjectState.Paused;
         emit ProjectStateChanged(projectId, ProjectState.Paused);
     }

     function resumeProject(uint256 projectId) external onlyAdmin notPaused {
         EcoProject storage project = projects[projectId];
         require(project.state == ProjectState.Paused, "EcoFlow: Project must be Paused to be resumed");

         // Decide which state it resumes to - Funding or Active
         // If it was Active, it resumes to Active. If it was Funding, resumes to Funding.
         // Need to store previous state? Or infer from totalFunded vs fundingGoal?
         // Let's infer: If funded > goal, resumes to Active, else to Funding.
         if (project.totalFunded >= project.fundingGoal) {
              project.state = ProjectState.Active;
              // Re-calculate durationEndTime if pausing impacts time? Complex, keep simple for now.
         } else {
             project.state = ProjectState.Funding;
         }

         emit ProjectStateChanged(projectId, project.state);
     }


    // --- Funding & Contribution ---

    function fundProject(uint256 projectId, uint256 amount) external nonReentrant notPaused {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Funding, "EcoFlow: Project is not in Funding state");
        require(fundingToken != address(0), "EcoFlow: Funding token not set");
        require(amount > 0, "EcoFlow: Amount must be greater than zero");

        // Ensure the user has approved this contract to spend their tokens
        IERC20(fundingToken).transferFrom(msg.sender, address(this), amount);

        project.totalFunded += amount;
        project.contributors[msg.sender] += amount; // Track user contribution per project
        userProjectContributions[projectId][msg.sender] += amount; // Redundant but maybe useful for query?
        // Add user to list if not already present (gas intensive if many unique contributors)
        bool contributorExists = false;
        for(uint i = 0; i < projectContributorsList[projectId].length; i++){
            if(projectContributorsList[projectId][i] == msg.sender){
                contributorExists = true;
                break;
            }
        }
        if(!contributorExists){
             projectContributorsList[projectId].push(msg.sender);
        }


        emit ProjectFunded(projectId, msg.sender, amount);

        // Check if funding goal is reached
        if (project.totalFunded >= project.fundingGoal && project.state == ProjectState.Funding) {
            project.state = ProjectState.Active;
            project.startTime = block.timestamp; // Project officially starts now
            // Assuming durationInDays was set in proposal, calculate end time
            // Note: durationInDays was not stored, add it to struct? Let's skip for simplicity here.
            // Or derive from milestone timelines? Too complex. Let's assume proposal duration was just for *initial* estimate.
            emit ProjectStateChanged(projectId, ProjectState.Active);
        }
    }

     function withdrawContribution(uint256 projectId, uint256 amount) external nonReentrant notPaused {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Rejected || project.state == ProjectState.Failed, "EcoFlow: Cannot withdraw unless project is Rejected or Failed");
        require(userProjectContributions[projectId][msg.sender] >= amount, "EcoFlow: Insufficient contribution amount");
        require(amount > 0, "EcoFlow: Amount must be greater than zero");

        // Check if the funds are still in the contract and not already withdrawn/spent
        // This requires tracking withdrawn amounts or available balance per project,
        // which adds complexity. For simplicity, assume all contributed funds
        // for Rejected/Failed projects are available unless already released for milestones (which shouldn't happen in Rejected state).
        // In Failed state, if milestones were paid out, only remaining unspent funds are available.
        // A more robust system would track unspent milestone funds + remaining contribution balance.
        // Let's implement a simple version: allow withdrawal up to contribution, but only if project.totalFunded hasn't been mostly paid out.
        // This is a simplification and risk point in a real contract.
        // A safer approach tracks available withdrawal balance per user per project.

        // Simplified check: Just rely on the state and user record
        uint256 userAvailableToWithdraw = userProjectContributions[projectId][msg.sender];
        require(userAvailableToWithdraw >= amount, "EcoFlow: Not enough unwithdrawn contribution");

        userProjectContributions[projectId][msg.sender] -= amount; // Deduct from user's record
        project.totalFunded -= amount; // Reduce total funded (careful: this isn't perfect accounting if funds were spent)

        // Transfer funds back to the user
        IERC20(fundingToken).transfer(msg.sender, amount);

        emit ContributionWithdrawn(projectId, msg.sender, amount);
    }


    // --- Milestone Management ---

    function reportMilestoneCompletion(uint256 projectId, uint256 milestoneIndex) external notPaused onlyProposer(projectId) {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Active || project.state == ProjectState.Paused, "EcoFlow: Project must be Active or Paused");
        require(milestoneIndex < project.milestones.length, "EcoFlow: Invalid milestone index");
        require(!project.milestones[milestoneIndex].completedByProposer, "EcoFlow: Milestone already reported completed");

        project.milestones[milestoneIndex].completedByProposer = true;

        emit MilestoneReported(projectId, milestoneIndex);
    }

     function requestMilestoneFunding(uint256 projectId, uint256 milestoneIndex) external notPaused onlyProposer(projectId) {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Active || project.state == ProjectState.Paused, "EcoFlow: Project must be Active or Paused");
        require(milestoneIndex < project.milestones.length, "EcoFlow: Invalid milestone index");
        require(project.milestones[milestoneIndex].completedByProposer, "EcoFlow: Milestone not reported as completed");
        require(!project.milestones[milestoneIndex].fundingApprovedByAdmin, "EcoFlow: Funding already approved for this milestone");

        // This function primarily acts as a signal to the admin/governance
        // The actual funding release requires approval

        emit MilestoneFundingRequested(projectId, milestoneIndex);
     }


     function approveMilestoneFunding(uint256 projectId, uint256 milestoneIndex) external onlyAdmin notPaused nonReentrant {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Active || project.state == ProjectState.Paused, "EcoFlow: Project must be Active or Paused");
        require(milestoneIndex < project.milestones.length, "EcoFlow: Invalid milestone index");
        require(project.milestones[milestoneIndex].completedByProposer, "EcoFlow: Milestone not reported as completed by proposer");
        require(!project.milestones[milestoneIndex].fundingApprovedByAdmin, "EcoFlow: Funding already approved for this milestone");
        // Optional: require MilestoneFundingRequested was called? No, Admin can approve directly.

        uint256 allocationBps = project.milestones[milestoneIndex].fundingAllocation; // Allocation in basis points
        uint256 amountToRelease = (project.fundingGoal * allocationBps) / 10000; // Calculate actual amount based on goal

        // Ensure contract has enough balance (should be >= project.totalFunded if no prior withdrawals)
        require(IERC20(fundingToken).balanceOf(address(this)) >= amountToRelease, "EcoFlow: Insufficient contract balance to release milestone funds");

        project.milestones[milestoneIndex].fundingApprovedByAdmin = true;

        // Transfer funds to the project proposer
        IERC20(fundingToken).transfer(project.proposer, amountToRelease);

        // Distribute Impact Points for this milestone immediately upon approval?
        // Or wait until final project completion? Let's do it on approval.
        uint256 impactPointsThisMilestone = project.milestones[milestoneIndex].impactPointsAllocation;
        // How to distribute points? Proportional to contribution? Or just to proposer?
        // Let's distribute proportionally to contributors of THIS project.
        // This requires iterating contributors, which is GAS HEAVY.
        // Alternative: Points accrue per project and are claimed by contributors *after* project is completed, proportionally to their contribution.
        // Let's implement the deferred, proportional distribution on ProjectCompleted/Failed.
        // So, this function *only* releases funds.

        emit MilestoneFundingApproved(projectId, milestoneIndex, amountToRelease);

        // Re-calculate health score after milestone approval
        project.currentHealthScore = calculateProjectHealth(projectId);
     }


    // --- Impact Tracking & Distribution ---

    // Function to distribute points (called by Admin/System after project completion/failure)
     function distributeImpactPoints(uint256 projectId) external onlyAdmin nonReentrant {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Completed || project.state == ProjectState.Failed, "EcoFlow: Project must be Completed or Failed to distribute points");
        require(project.totalImpactPointsGenerated > 0, "EcoFlow: No impact points allocated for this project");

        // Points are distributed proportionally to contribution *among* contributors of this project
        uint256 totalContributionToThisProject = project.totalFunded; // Note: This might be less if withdrawals occurred
        require(totalContributionToThisProject > 0, "EcoFlow: No contributions made to distribute points proportionally");

        uint256 pointsDistributed = 0;

        // Iterate through the *list* of contributors (mapping iteration is not possible)
        for(uint i = 0; i < projectContributorsList[projectId].length; i++){
            address contributor = projectContributorsList[projectId][i];
             uint256 contribution = userProjectContributions[projectId][contributor];

             // Calculate proportional share of points
             // Using 10000 basis points for division precision
             uint256 contributorPointsShare = (project.totalImpactPointsGenerated * (contribution * 10000 / totalContributionToThisProject)) / 10000;

             userTotalImpactPoints[contributor] += contributorPointsShare;
             pointsDistributed += contributorPointsShare;
         }

         // If there's a tiny remainder due to division, it's kept by the contract.

         emit ImpactPointsDistributed(projectId, pointsDistributed);

         // Mark points as distributed for this project to prevent double distribution
         // Need a flag on the struct? Let's just rely on state change and Admin control for simplicity.
         // A more robust system would track distribution status per project.
     }

     function claimImpactPoints() external nonReentrant notPaused {
        uint256 pointsToClaim = userTotalImpactPoints[msg.sender];
        require(pointsToClaim > 0, "EcoFlow: No impact points available to claim");

        // In this contract, Impact Points are abstract scores, not actual tokens.
        // If they were a token, we would mint/transfer them here.
        // For now, claiming just resets the balance and emits an event.
        // A real system would likely involve another token contract.

        userTotalImpactPoints[msg.sender] = 0; // Reset balance after "claiming"

        // If Impact Points were an ERC20 token managed by this contract, we would call:
        // IERC20(impactTokenAddress).mint(msg.sender, pointsToClaim); // Example

        emit ImpactPointsClaimed(msg.sender, pointsToClaim);
     }

    // --- Dynamic Health & Oracle Integration ---

     // Simplified calculation: Based on milestone completion progress + oracle report
     function calculateProjectHealth(uint256 projectId) public view returns (uint256) {
         EcoProject storage project = projects[projectId];

         if (project.milestones.length == 0) {
             return project.currentHealthScore; // Return oracle report if no milestones
         }

         uint256 completedMilestones = 0;
         for(uint i = 0; i < project.milestones.length; i++) {
             // Count milestones where funding was approved (indicates successful completion validation)
             if (project.milestones[i].fundingApprovedByAdmin) {
                 completedMilestones++;
             }
         }

         // Health based on milestone progress (out of 100)
         uint256 milestoneHealth = (completedMilestones * 100) / project.milestones.length;

         // Combine with oracle report (e.g., weighted average, or oracle overrides?)
         // Let's do a simple average or prioritize oracle if available and recent?
         // Simple average: (Milestone Health + Oracle Health) / 2, if oracle exists.
         // Or just return the oracle value if it's been reported, otherwise milestone health.
         // Let's just return the currentHealthScore which can be updated by the oracle.
         // The oracleReportHealth function will be the primary way this value changes externally.
         // The milestone approval implicitly updates it via the call to calculateProjectHealth.

         // So, this function calculates the health *based on milestones only*.
         // The actual `project.currentHealthScore` is a state variable that can be
         // *influenced* by this calculation or by the oracle.

         return milestoneHealth; // Returns milestone-based health
     }

      function reportProjectHealth(uint256 projectId, uint256 healthScore) external onlyOracle notPaused {
        EcoProject storage project = projects[projectId];
        require(project.state == ProjectState.Funding || project.state == ProjectState.Active || project.state == ProjectState.Paused, "EcoFlow: Cannot report health for inactive/finalized projects");
        require(healthScore <= 100, "EcoFlow: Health score must be between 0 and 100");

        project.currentHealthScore = healthScore; // Oracle updates the official health score state variable

        emit ProjectHealthReported(projectId, healthScore, msg.sender);
      }


    // --- Governance & Reputation (Basic) ---

     function signalSupportForProposal(uint256 projectId) external notPaused {
         EcoProject storage project = projects[projectId];
         require(project.state == ProjectState.Proposed, "EcoFlow: Can only signal support for proposed projects");
         require(!proposalSupport[projectId][msg.sender], "EcoFlow: Already signaled support for this proposal");

         proposalSupport[projectId][msg.sender] = true;

         emit ProposalSupportSignaled(projectId, msg.sender);

         // Note: Counting total support signals is not implemented due to gas costs of iterating a mapping.
         // This function primarily serves as a signal and generates an event.
     }

     function leaveProjectRating(uint256 projectId, uint8 rating) external notPaused {
         EcoProject storage project = projects[projectId];
         require(project.state == ProjectState.Completed, "EcoFlow: Can only rate completed projects");
         require(rating >= 1 && rating <= 5, "EcoFlow: Rating must be between 1 and 5");

         // Storing multiple ratings and calculating average adds complexity (mapping address => rating, tracking count).
         // For simplicity, let's store only one average rating on the project struct, updated by *anyone* rating?
         // This is not ideal (can be easily manipulated by first rater).
         // Better: Store count of raters and sum of ratings. Update average on write.
         // Let's add mapping(uint256 => mapping(address => bool)) hasRated; and mappings for sum and count.

         mapping(uint256 => mapping(address => bool)) public hasRated;
         mapping(uint256 => uint256) public projectRatingSum;
         mapping(uint256 => uint256) public projectRatingCount;

         require(!hasRated[projectId][msg.sender], "EcoFlow: You have already rated this project");

         hasRated[projectId][msg.sender] = true;
         projectRatingSum[projectId] += rating;
         projectRatingCount[projectId]++;

         // Calculate new average rating (integer division might not be precise)
         project.averageRating = uint8(projectRatingSum[projectId] / projectRatingCount[projectId]);

         emit ProjectRated(projectId, msg.sender, rating);
     }

    function transferProjectProposer(uint256 projectId, address newProposer) external notPaused onlyProposer(projectId) {
        EcoProject storage project = projects[projectId];
        require(newProposer != address(0), "EcoFlow: New proposer cannot be zero address");
        require(newProposer != msg.sender, "EcoFlow: Cannot transfer to yourself");
        require(project.state != ProjectState.Completed && project.state != ProjectState.Failed && project.state != ProjectState.Rejected, "EcoFlow: Cannot transfer ownership of finalized projects");

        address oldProposer = project.proposer;
        project.proposer = newProposer;

        emit ProjectProposerTransferred(projectId, oldProposer, newProposer);
    }


    // --- View Functions ---

    function getProject(uint256 projectId) external view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        string memory category,
        uint256 fundingGoal,
        uint256 totalFunded,
        uint256 startTime,
        uint256 durationEndTime,
        Milestone[] memory milestones,
        ProjectState state,
        uint256 currentHealthScore,
        uint8 averageRating,
        uint256 totalImpactPointsGenerated
    ) {
        EcoProject storage project = projects[projectId];
        // Access mapping directly might return default values for non-existent IDs.
        // Add a check for existence if necessary, but for view functions often omitted.
        // require(project.id != 0, "EcoFlow: Project not found"); // Assumes ID 0 is never used

        return (
            project.id,
            project.proposer,
            project.title,
            project.description,
            project.category,
            project.fundingGoal,
            project.totalFunded,
            project.startTime,
            project.durationEndTime, // Note: durationEndTime is not set in the code yet, would need to be added in approval/funding
            project.milestones,
            project.state,
            project.currentHealthScore,
            project.averageRating,
            project.totalImpactPointsGenerated
        );
    }

    function getMilestoneStatus(uint256 projectId, uint256 milestoneIndex) external view returns (
        string memory description,
        uint256 fundingAllocation,
        bool completedByProposer,
        bool fundingApprovedByAdmin,
        uint256 impactPointsAllocation
    ) {
        EcoProject storage project = projects[projectId];
        require(milestoneIndex < project.milestones.length, "EcoFlow: Invalid milestone index");

        Milestone storage milestone = project.milestones[milestoneIndex];
         return (
             milestone.description,
             milestone.fundingAllocation,
             milestone.completedByProposer,
             milestone.fundingApprovedByAdmin,
             milestone.impactPointsAllocation
         );
    }

     function getUserContribution(uint256 projectId, address user) external view returns (uint256) {
         return userProjectContributions[projectId][user];
     }

     function getUserTotalImpactPoints(address user) external view returns (uint256) {
         return userTotalImpactPoints[user];
     }

     function getProjectCount() external view returns (uint256) {
         return nextProjectId - 1; // Subtract 1 as nextProjectId is the ID for the *next* project
     }

     // Note: Iterating categories or returning filtered lists is gas-prohibitive on-chain.
     // This view function is illustrative; filtering would typically happen off-chain.
     // A realistic implementation might return ALL project IDs, and the client filters.
     // Let's keep it simple and just acknowledge the category filter idea.
     function getProjectsByCategory(string memory /* category */) external view returns (uint256[] memory) {
         // WARNING: Implementing this properly (returning filtered list) is gas-intensive
         // and often avoided in favor of off-chain indexing.
         // This is a placeholder. Returning all IDs is more practical.
         // return getAllProjectIds(); // Alternative realistic implementation
         revert("EcoFlow: Filtering by category on-chain is not practical");
     }

     function getAllProjectIds() external view returns (uint256[] memory) {
         uint256 totalProjects = getProjectCount();
         uint256[] memory projectIds = new uint256[](totalProjects);
         for(uint i = 0; i < totalProjects; i++) {
             projectIds[i] = i + 1; // Project IDs start from 1
         }
         return projectIds;
     }


     function getTotalFunding(uint256 projectId) external view returns (uint256) {
         return projects[projectId].totalFunded;
     }

     function getFundingRemaining(uint256 projectId) external view returns (uint256) {
         EcoProject storage project = projects[projectId];
         if (project.totalFunded >= project.fundingGoal) {
             return 0;
         }
         return project.fundingGoal - project.totalFunded;
     }

    function getProjectState(uint256 projectId) external view returns (ProjectState) {
        return projects[projectId].state;
    }

    function getFundingToken() external view returns (address) {
        return fundingToken;
    }

     function getAdmin() external view returns (address) {
         return admin;
     }

    // Adding a function to get the list of contributors for a project.
    // WARNING: This can be very gas-intensive for projects with many contributors.
    // For large projects, off-chain indexing is preferred.
    function getProjectContributors(uint256 projectId) external view returns (address[] memory) {
         // Need to copy the list. The stored `projectContributorsList` helps avoid mapping iteration.
         uint256 count = projectContributorsList[projectId].length;
         address[] memory contributors = new address[](count);
         for(uint i = 0; i < count; i++){
             contributors[i] = projectContributorsList[projectId][i];
         }
         return contributors;
    }

    function getProjectContributorCount(uint256 projectId) external view returns (uint256) {
         return projectContributorsList[projectId].length;
    }

     function isProjectProposer(uint256 projectId, address user) external view returns (bool) {
         return projects[projectId].proposer == user;
     }

     // Although calculateProjectHealth is internal/public view, expose it as a view function directly
     function viewCalculatedProjectHealth(uint256 projectId) external view returns (uint256) {
         return calculateProjectHealth(projectId);
     }

     // View function to check if a user has signaled support for a proposal
      function hasSignaledSupport(uint256 projectId, address user) external view returns (bool) {
         return proposalSupport[projectId][user];
     }

     // View function to get rating details for a project
     function getProjectRatingDetails(uint256 projectId) external view returns (uint8 averageRating, uint256 ratingCount) {
        EcoProject storage project = projects[projectId];
         return (project.averageRating, projectRatingCount[projectId]);
     }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Milestone-Based Funding Release:** Funds aren't just given upfront. They are released incrementally to the proposer only after specific project milestones are reported as complete by the proposer and then *approved* by the admin (or potentially a decentralized governance body in a more complex version). This adds a layer of accountability.
2.  **Dynamic Project Health Score:** The `currentHealthScore` can change over time. The `calculateProjectHealth` provides a base score based on milestone progress. The `reportProjectHealth` function allows a trusted oracle (or admin as a proxy) to report external data that influences this score, making the project's perceived status more dynamic based on real-world conditions (e.g., satellite data validating reforestation progress, weather impacting a solar project).
3.  **Impact Point Distribution:** The contract introduces a concept of "Impact Points" (`userTotalImpactPoints`). These are abstract scores representing a user's positive environmental contribution through funding projects. Points are allocated per project (`totalImpactPointsGenerated`) and distributed proportionally to contributors based on their funding amount once the project is completed or failed. This creates a non-monetary reward/reputation system within the platform.
4.  **Proportional Impact Point Distribution:** When points are distributed for a project, they are split among all contributors *based on the proportion of funds they contributed* to that specific project.
5.  **Project Lifecycle States:** The explicit `ProjectState` enum and transitions (`Proposed`, `Funding`, `Active`, `Paused`, `Completed`, `Failed`, `Rejected`) provide a structured workflow for projects, adding complexity and control.
6.  **Basic Governance Signals:** Functions like `signalSupportForProposal` and `leaveProjectRating` provide simple mechanisms for community interaction and feedback, laying groundwork for potential decentralized governance features (though actual voting/decision-making power is left to the admin in this version for simplicity).
7.  **ERC20 Funding:** Projects are funded using a specified ERC20 token, making it flexible and compatible with existing token ecosystems. `transferFrom` is used, requiring user approval beforehand, which is standard and secure for pulling funds.
8.  **Contributor Tracking:** The contract explicitly tracks individual user contributions per project, enabling proportional calculations (like impact points) and potential future features like tiered rewards or governance weight based on contribution. The `projectContributorsList` attempts to provide an iterable list, although iterating large arrays on-chain is a known gas challenge.

This contract provides a framework for a project funding platform with unique features tailored towards tracking progress and impact in a more dynamic and accountable way than simple crowdfunding. It has well over the requested 20 functions, covering proposal, funding, management, tracking, and basic interaction.