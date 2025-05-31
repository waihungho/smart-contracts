Okay, let's create a smart contract based on a complex, somewhat experimental concept: a "Fractal Funding Sphere."

The idea is a decentralized ecosystem where projects can be proposed, funded, and upon reaching certain milestones and criteria, can themselves evolve into "Spheres" capable of funding *their own* sub-projects. This creates a potential tree-like or fractal structure of funding and development within a single contract system.

It incorporates:
1.  **Hierarchical Funding:** Projects funded by the main sphere can become spheres funding sub-projects.
2.  **Staking & Reputation:** Users stake tokens to gain influence/reputation, which affects governance or yield distribution.
3.  **Dynamic Parameters:** Certain thresholds or rates could dynamically adjust based on the system's state (e.g., total funding, success rate). (For simplicity in this implementation, we'll make them owner-updatable, but the *concept* allows for dynamic logic).
4.  **Yield Distribution:** Fees or excess funds are distributed to stakers/reputation holders.
5.  **State Management:** Complex transitions between project states (Proposed, Funded, Active, Sphere-Pending, Sphere, Completed, Failed).

**Disclaimer:** This is a complex, experimental concept. It is provided for educational purposes only and is *not* audited or ready for production use. Building such a system would require significant security review, gas optimization, and robust governance mechanisms.

---

## Fractal Funding Sphere - Outline & Function Summary

**Concept:** A system for funding projects hierarchically, where successful projects can become funding "Spheres" themselves, creating a fractal structure. Incorporates staking, reputation, and dynamic parameters.

**Entities:**
*   **Project:** A proposal seeking funding. Has a state, owner, funding goal, milestones.
*   **Sphere:** A funded project that has evolved into an entity capable of funding sub-projects. Has its own balance and can have children projects/spheres.
*   **User:** Interacts with the contract by funding projects, staking, proposing projects, or potentially governing.

**Core Mechanisms:**
*   **Funding:** Users fund projects with a specific ERC20 token.
*   **State Transitions:** Projects move through defined states based on funding, reporting, and approval processes.
*   **Sphere Conversion:** A project owner can propose conversion to a Sphere; this requires approval (simplified here via owner/governance).
*   **Hierarchical Funding:** Spheres can allocate funds to new projects, becoming their parent.
*   **Staking:** Users stake tokens to participate and potentially earn yield/reputation.
*   **Reputation:** A score reflecting a user's positive contributions/activity (simplified here).
*   **Yield Distribution:** A portion of contract funds (e.g., collected fees or excess) is distributed to stakers/reputation holders.

**Key State Variables:**
*   `projects`: Mapping from ID to Project struct.
*   `spheres`: Mapping from ID to Sphere struct.
*   `projectCount`: Counter for unique project IDs.
*   `sphereCount`: Counter for unique sphere IDs.
*   `fundingToken`: Address of the ERC20 token used for funding.
*   `stakedBalances`: Mapping user to staked amount.
*   `userReputation`: Mapping user to reputation score.
*   `totalStaked`: Total tokens staked.
*   `totalReputation`: Sum of all reputation scores.
*   `feesCollected`: Tokens collected as fees (for yield distribution).
*   `params`: Struct holding dynamic parameters (funding thresholds, fee rates, etc.).
*   `sphereHierarchy`: Mapping child Project/Sphere ID to parent Sphere ID.

**Function Summary (Total: 26 functions)**

1.  `constructor(address _fundingToken)`: Initializes contract, sets funding token.
2.  `registerProject(string memory _projectTitle, string memory _projectDescription, uint256 _fundingGoal, uint256 _milestoneCount)`: Proposes a new project. (State: Proposed)
3.  `fundProject(uint256 _projectId, uint256 _amount)`: Transfers tokens to fund a project. Updates funding status. (State: Proposed -> Funded)
4.  `getProjectFunding(uint256 _projectId)`: Views current funding for a project.
5.  `claimProjectFunding(uint256 _projectId)`: Project owner claims funded tokens after meeting goal (State: Funded -> Active). Includes fee collection.
6.  `reportProjectProgress(uint256 _projectId, uint256 _milestoneIndex)`: Owner reports milestone completion. Could potentially affect reputation.
7.  `proposeSphereConversion(uint256 _projectId)`: Owner proposes a successful project becomes a Sphere. (State: Active -> Sphere-Pending)
8.  `approveSphereConversion(uint256 _projectId)`: Governance/Owner approves Sphere conversion. (State: Sphere-Pending -> Sphere). Transfers project balance to Sphere balance.
9.  `fundSubProject(uint256 _sphereId, uint256 _projectId, uint256 _amount)`: A Sphere funds a registered project, establishing parent-child link.
10. `getSphereFunding(uint256 _sphereId)`: Views balance of a Sphere.
11. `getSphereChildren(uint256 _sphereId)`: Views projects/spheres funded by a Sphere.
12. `getSphereParent(uint256 _childId)`: Views the parent Sphere of a project or Sphere.
13. `stakeTokens(uint256 _amount)`: Users stake funding tokens.
14. `unstakeTokens(uint256 _amount)`: Users unstake funding tokens.
15. `getUserStake(address _user)`: Views user's staked amount.
16. `getUserReputation(address _user)`: Views user's reputation score.
17. `awardReputation(address _user, uint256 _amount)`: Owner/Governance awards reputation (simplified).
18. `penalizeReputation(address _user, uint256 _amount)`: Owner/Governance reduces reputation (simplified).
19. `distributeYield()`: Distributes accumulated fees to stakers/reputation holders.
20. `getDistributableYield()`: Views total fees available for distribution.
21. `getPendingYield(address _user)`: Views estimated pending yield for a user.
22. `updateFundingGoalThreshold(uint256 _newThreshold)`: Owner updates minimum funding goal parameter.
23. `updateFeeRate(uint256 _newRate)`: Owner updates fee rate parameter.
24. `updateSphereConversionCriteria(uint256 _minFunding, uint256 _minMilestones)`: Owner updates criteria for Sphere conversion proposal.
25. `pauseContract()`: Owner pauses sensitive operations.
26. `unpauseContract()`: Owner unpauses contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Outline & Function Summary ---
// Concept: A system for funding projects hierarchically, where successful projects can become funding "Spheres" themselves, creating a fractal structure. Incorporates staking, reputation, and dynamic parameters.
//
// Entities:
// - Project: A proposal seeking funding. Has a state, owner, funding goal, milestones.
// - Sphere: A funded project that has evolved into an entity capable of funding sub-projects. Has its own balance and can have children projects/spheres.
// - User: Interacts with the contract by funding projects, staking, proposing projects, or potentially governing.
//
// Core Mechanisms:
// - Funding: Users fund projects with a specific ERC20 token.
// - State Transitions: Projects move through defined states based on funding, reporting, and approval processes.
// - Sphere Conversion: A project owner can propose conversion to a Sphere; this requires approval (simplified here via owner/governance).
// - Hierarchical Funding: Spheres can allocate funds to new projects, becoming their parent.
// - Staking: Users stake tokens to participate and potentially earn yield/reputation.
// - Reputation: A score reflecting a user's positive contributions/activity (simplified here).
// - Yield Distribution: A portion of contract funds (e.g., collected fees or excess) is distributed to stakers/reputation holders.
//
// Key State Variables:
// - projects: Mapping from ID to Project struct.
// - spheres: Mapping from ID to Sphere struct.
// - projectCount: Counter for unique project IDs.
// - sphereCount: Counter for unique sphere IDs.
// - fundingToken: Address of the ERC20 token used for funding.
// - stakedBalances: Mapping user to staked amount.
// - userReputation: Mapping user to reputation score.
// - totalStaked: Total tokens staked.
// - totalReputation: Sum of all reputation scores.
// - feesCollected: Tokens collected as fees (for yield distribution).
// - params: Struct holding dynamic parameters (funding thresholds, fee rates, etc.).
// - sphereHierarchy: Mapping child Project/Sphere ID to parent Sphere ID.
//
// Function Summary (Total: 26 functions):
// 1. constructor(address _fundingToken)
// 2. registerProject(string memory _projectTitle, string memory _projectDescription, uint256 _fundingGoal, uint256 _milestoneCount)
// 3. fundProject(uint256 _projectId, uint256 _amount)
// 4. getProjectFunding(uint256 _projectId)
// 5. claimProjectFunding(uint256 _projectId)
// 6. reportProjectProgress(uint256 _projectId, uint256 _milestoneIndex)
// 7. proposeSphereConversion(uint256 _projectId)
// 8. approveSphereConversion(uint256 _projectId)
// 9. fundSubProject(uint256 _sphereId, uint256 _projectId, uint256 _amount)
// 10. getSphereFunding(uint256 _sphereId)
// 11. getSphereChildren(uint256 _sphereId)
// 12. getSphereParent(uint256 _childId)
// 13. stakeTokens(uint256 _amount)
// 14. unstakeTokens(uint256 _amount)
// 15. getUserStake(address _user)
// 16. getUserReputation(address _user)
// 17. awardReputation(address _user, uint256 _amount)
// 18. penalizeReputation(address _user, uint256 _amount)
// 19. distributeYield()
// 20. getDistributableYield()
// 21. getPendingYield(address _user)
// 22. updateFundingGoalThreshold(uint256 _newThreshold)
// 23. updateFeeRate(uint256 _newRate)
// 24. updateSphereConversionCriteria(uint256 _minFunding, uint256 _minMilestones)
// 25. pauseContract()
// 26. unpauseContract()
//
// --- End Outline & Function Summary ---


contract FractalFundingSphere is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IERC20 public immutable fundingToken;

    enum ProjectStatus {
        Proposed,
        Funded, // Reached funding goal, funds available to claim
        Active, // Funding claimed, project owner working
        SpherePending, // Proposed for sphere conversion
        Sphere, // Converted to a Sphere, can fund sub-projects
        Completed,
        Failed,
        Cancelled // By owner or governance
    }

    struct Project {
        uint256 id;
        address owner;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 amountRaised;
        uint256 milestoneCount;
        uint256 milestonesCompleted;
        ProjectStatus status;
        bool isSphere; // Redundant with status but useful flag
        address parentSphere; // Address of the Sphere contract if applicable, 0x0 for top-level
    }

    struct Sphere {
        uint256 id; // Corresponds to Project ID
        address owner;
        uint256 balance;
        uint256 totalAllocated; // Total amount allocated to children
        uint256[] children; // Project/Sphere IDs funded by this Sphere
    }

    struct DynamicParameters {
        uint256 minFundingGoalThreshold; // Minimum funding goal required for a project
        uint256 projectClaimFeeRate; // Percentage fee taken when project claims funding (e.g., 500 = 5%)
        uint256 sphereConversionMinFunding; // Minimum funding project must have to propose sphere conversion
        uint256 sphereConversionMinMilestones; // Minimum milestones completed to propose conversion
        uint256 reputationAwardForMilestone; // Reputation points awarded for each completed milestone report
        uint256 yieldDistributionBasisPoints; // Basis points of collected fees distributed as yield (e.g., 10000 = 100%)
    }

    Counters.Counter private _projectIds;
    Counters.Counter private _sphereIds; // Uses project ID as Sphere ID

    mapping(uint256 => Project) public projects;
    mapping(uint256 => Sphere) public spheres;
    mapping(uint256 => uint256) private _projectBalances; // Balances held for projects before claiming

    // Hierarchy mapping: Child ID => Parent Sphere ID
    mapping(uint256 => uint256) public sphereHierarchy;
    // Children mapping: Sphere ID => List of Child IDs
    mapping(uint256 => uint256[]) private _sphereChildren;

    // Staking and Reputation
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public userReputation;
    uint256 public totalStaked;
    uint256 public totalReputation; // Sum of all user reputation scores

    uint256 public feesCollected; // Tokens collected from project claims

    DynamicParameters public params;

    event ProjectRegistered(uint256 indexed projectId, address indexed owner, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount, uint256 totalRaised);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event FundingClaimed(uint256 indexed projectId, uint256 amountClaimed, uint256 feeAmount);
    event MilestoneReported(uint256 indexed projectId, uint256 milestoneIndex, uint256 milestonesCompleted);
    event SphereConversionProposed(uint256 indexed projectId);
    event SphereConverted(uint256 indexed projectId, address indexed sphereOwner);
    event SubProjectFunded(uint256 indexed sphereId, uint256 indexed subProjectId, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 totalStaked);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event ReputationAwarded(address indexed user, uint256 amount, uint256 totalReputation);
    event ReputationPenalized(address indexed user, uint256 amount, uint256 totalReputation);
    event YieldDistributed(uint256 amountDistributed, uint256 feesRemaining);
    event ParametersUpdated(string paramName);

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "Not project owner");
        _;
    }

    modifier projectMustBeInStatus(uint256 _projectId, ProjectStatus _status) {
        require(projects[_projectId].status == _status, "Project not in required status");
        _;
    }

     modifier projectMustBeAnyStatus(uint256 _projectId, ProjectStatus[] memory _statuses) {
        bool found = false;
        for(uint i = 0; i < _statuses.length; i++){
            if(projects[_projectId].status == _statuses[i]){
                found = true;
                break;
            }
        }
        require(found, "Project not in any of the required statuses");
        _;
    }

    modifier onlySphereOwner(uint256 _sphereId) {
         require(spheres[_sphereId].owner == msg.sender, "Not sphere owner");
        _;
    }

    constructor(address _fundingToken) Ownable(msg.sender) Pausable() {
        require(_fundingToken != address(0), "Funding token address cannot be zero");
        fundingToken = IERC20(_fundingToken);

        // Set initial parameters (can be updated by owner)
        params.minFundingGoalThreshold = 1 ether; // Example: 1 token unit (assuming 18 decimals)
        params.projectClaimFeeRate = 500; // Example: 5% fee (500 / 10000)
        params.sphereConversionMinFunding = 10 ether; // Example: Must raise at least 10 token units
        params.sphereConversionMinMilestones = 1; // Example: Must complete at least 1 milestone
        params.reputationAwardForMilestone = 10; // Example: 10 reputation per milestone
        params.yieldDistributionBasisPoints = 10000; // Example: Distribute 100% of collected fees
    }

    /// @notice Registers a new project proposal.
    /// @param _projectTitle Title of the project.
    /// @param _projectDescription Description of the project.
    /// @param _fundingGoal Required funding amount.
    /// @param _milestoneCount Number of milestones planned.
    /// @return projectId The ID of the newly registered project.
    function registerProject(
        string memory _projectTitle,
        string memory _projectDescription,
        uint256 _fundingGoal,
        uint256 _milestoneCount
    ) external whenNotPaused returns (uint256) {
        require(bytes(_projectTitle).length > 0, "Title cannot be empty");
        require(_fundingGoal >= params.minFundingGoalThreshold, "Funding goal below minimum threshold");
        require(_milestoneCount > 0, "Project must have at least one milestone");

        _projectIds.increment();
        uint256 newId = _projectIds.current();

        projects[newId] = Project({
            id: newId,
            owner: msg.sender,
            title: _projectTitle,
            description: _projectDescription,
            fundingGoal: _fundingGoal,
            amountRaised: 0,
            milestoneCount: _milestoneCount,
            milestonesCompleted: 0,
            status: ProjectStatus.Proposed,
            isSphere: false,
            parentSphere: address(0) // Top-level project
        });

        emit ProjectRegistered(newId, msg.sender, _fundingGoal);
        return newId;
    }

    /// @notice Allows a user to fund a project.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount of tokens to fund.
    function fundProject(uint256 _projectId, uint256 _amount) external nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Proposed, "Project is not in Proposed status");
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer tokens from funder to the contract
        bool success = fundingToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        project.amountRaised += _amount;
        _projectBalances[_projectId] += _amount;

        if (project.amountRaised >= project.fundingGoal) {
            project.status = ProjectStatus.Funded;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Proposed, ProjectStatus.Funded);
        }

        emit ProjectFunded(_projectId, msg.sender, _amount, project.amountRaised);
    }

    /// @notice Views the current funding amount for a project.
    /// @param _projectId The ID of the project.
    /// @return The amount raised for the project.
    function getProjectFunding(uint256 _projectId) external view returns (uint256) {
         require(projects[_projectId].id != 0, "Project does not exist");
         return projects[_projectId].amountRaised;
    }

    /// @notice Allows a funded project owner to claim the raised tokens.
    /// @param _projectId The ID of the project.
    function claimProjectFunding(uint256 _projectId)
        external
        onlyProjectOwner(_projectId)
        projectMustBeInStatus(_projectId, ProjectStatus.Funded)
        nonReentrant
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        uint256 balance = _projectBalances[_projectId];
        require(balance > 0, "Project has no balance to claim");

        // Calculate fee
        uint256 feeAmount = (balance * params.projectClaimFeeRate) / 10000;
        uint256 amountToOwner = balance - feeAmount;

        _projectBalances[_projectId] = 0; // Clear balance

        feesCollected += feeAmount;

        // Transfer funds to project owner
        bool success = fundingToken.transfer(project.owner, amountToOwner);
        require(success, "Transfer to project owner failed");

        project.status = ProjectStatus.Active;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Funded, ProjectStatus.Active);
        emit FundingClaimed(_projectId, amountToOwner, feeAmount);
    }

    /// @notice Allows an active project owner to report completing a milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the completed milestone (1-based).
    function reportProjectProgress(uint256 _projectId, uint256 _milestoneIndex)
        external
        onlyProjectOwner(_projectId)
        projectMustBeInStatus(_projectId, ProjectStatus.Active)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex > project.milestonesCompleted, "Milestone already reported or invalid index");
        require(_milestoneIndex <= project.milestoneCount, "Invalid milestone index");

        project.milestonesCompleted = _milestoneIndex;

        // Optionally award reputation for reporting progress
        uint256 reputationAward = params.reputationAwardForMilestone;
        userReputation[msg.sender] += reputationAward;
        totalReputation += reputationAward;
        emit ReputationAwarded(msg.sender, reputationAward, totalReputation);

        emit MilestoneReported(_projectId, _milestoneIndex, project.milestonesCompleted);

        // Optional: Add logic to change status if all milestones completed
        // if (project.milestonesCompleted == project.milestoneCount) {
        //     project.status = ProjectStatus.Completed;
        //     emit ProjectStatusChanged(_projectId, ProjectStatus.Active, ProjectStatus.Completed);
        // }
    }

    /// @notice Allows an active project owner meeting criteria to propose converting to a Sphere.
    /// @param _projectId The ID of the project.
    function proposeSphereConversion(uint256 _projectId)
        external
        onlyProjectOwner(_projectId)
        projectMustBeInStatus(_projectId, ProjectStatus.Active)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.amountRaised >= params.sphereConversionMinFunding, "Not enough funding raised for Sphere conversion");
        require(project.milestonesCompleted >= params.sphereConversionMinMilestones, "Not enough milestones completed for Sphere conversion");

        project.status = ProjectStatus.SpherePending;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Active, ProjectStatus.SpherePending);
        emit SphereConversionProposed(_projectId);
    }

    /// @notice Allows the owner/governance to approve a project becoming a Sphere.
    /// @param _projectId The ID of the project.
    function approveSphereConversion(uint256 _projectId)
        external
        onlyOwner // Simplified: uses contract owner. Could be a DAO vote in a real system.
        projectMustBeInStatus(_projectId, ProjectStatus.SpherePending)
        nonReentrant
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        project.status = ProjectStatus.Sphere;
        project.isSphere = true;

        // Create the Sphere struct and transfer balance
        // Note: Sphere ID == Project ID it originated from
        _sphereIds.increment(); // This counter isn't strictly needed for ID mapping, but good practice
        spheres[_projectId] = Sphere({
            id: _projectId,
            owner: project.owner,
            balance: _projectBalances[_projectId], // Any remaining balance goes to Sphere
            totalAllocated: 0,
            children: new uint256[](0)
        });

        _projectBalances[_projectId] = 0; // Clear project balance now managed by sphere

        emit ProjectStatusChanged(_projectId, ProjectStatus.SpherePending, ProjectStatus.Sphere);
        emit SphereConverted(_projectId, project.owner);
    }

    /// @notice Allows a Sphere owner to fund a registered project.
    /// @param _sphereId The ID of the Sphere funding the project.
    /// @param _projectId The ID of the project being funded.
    /// @param _amount The amount the Sphere allocates.
    function fundSubProject(uint256 _sphereId, uint256 _projectId, uint256 _amount)
        external
        onlySphereOwner(_sphereId)
        projectMustBeAnyStatus(_projectId, new ProjectStatus[](2).push(ProjectStatus.Proposed).push(ProjectStatus.Cancelled)) // Can only fund Proposed or Cancelled projects
        nonReentrant
        whenNotPaused
    {
        Sphere storage sphere = spheres[_sphereId];
        Project storage project = projects[_projectId];

        require(sphere.id != 0, "Sphere does not exist");
        require(project.id != 0, "Project does not exist");
        require(project.owner != address(0), "Project must have an owner"); // Ensure it's a registered project, not zero struct
        require(_amount > 0, "Amount must be greater than zero");
        require(sphere.balance >= _amount, "Sphere does not have enough balance");
        require(sphereHierarchy[_projectId] == 0, "Project already funded by another Sphere/top-level");

        sphere.balance -= _amount;
        sphere.totalAllocated += _amount;
        _projectBalances[_projectId] += _amount; // Add funds to the project's claimable balance

        // Update project status (if funding goal is met)
        project.amountRaised += _amount; // Note: AmountRaised tracks total for its goal, not just sphere funds
        if (project.status == ProjectStatus.Proposed && project.amountRaised >= project.fundingGoal) {
             project.status = ProjectStatus.Funded; // Funded by Sphere, follows same state flow
             emit ProjectStatusChanged(_projectId, ProjectStatus.Proposed, ProjectStatus.Funded);
        } else if (project.status == ProjectStatus.Cancelled) {
             // Reviving a cancelled project
             project.status = ProjectStatus.Proposed; // Or straight to Funded if criteria met? Let's stick to Proposed first.
             emit ProjectStatusChanged(_projectId, ProjectStatus.Cancelled, ProjectStatus.Proposed);
             // Check funding goal again after status change
             if (project.amountRaised >= project.fundingGoal) {
                project.status = ProjectStatus.Funded;
                emit ProjectStatusChanged(_projectId, ProjectStatus.Proposed, ProjectStatus.Funded);
            }
        }


        // Link child project to parent sphere
        sphereHierarchy[_projectId] = _sphereId;
        _sphereChildren[_sphereId].push(_projectId);
        project.parentSphere = address(this); // Indicates parent is this contract (the sphere system)

        emit SubProjectFunded(_sphereId, _projectId, _amount);
    }

    /// @notice Views the current balance of a Sphere.
    /// @param _sphereId The ID of the Sphere.
    /// @return The current balance of the Sphere.
    function getSphereFunding(uint256 _sphereId) external view returns (uint256) {
        require(spheres[_sphereId].id != 0, "Sphere does not exist");
        return spheres[_sphereId].balance;
    }

     /// @notice Views the list of project/sphere IDs funded by a Sphere.
     /// @param _sphereId The ID of the Sphere.
     /// @return An array of child project/sphere IDs.
    function getSphereChildren(uint256 _sphereId) external view returns (uint256[] memory) {
         require(spheres[_sphereId].id != 0, "Sphere does not exist");
         return _sphereChildren[_sphereId];
    }

    /// @notice Views the parent Sphere ID of a project or Sphere.
    /// @param _childId The ID of the child project or Sphere.
    /// @return The ID of the parent Sphere, or 0 if it's a top-level project.
    function getSphereParent(uint256 _childId) external view returns (uint256) {
         require(projects[_childId].id != 0, "Project/Sphere does not exist");
         return sphereHierarchy[_childId];
    }

    /// @notice Allows a user to stake funding tokens.
    /// @param _amount The amount of tokens to stake.
    function stakeTokens(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer tokens from user to the contract
        bool success = fundingToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        stakedBalances[msg.sender] += _amount;
        totalStaked += _amount;

        emit TokensStaked(msg.sender, _amount, totalStaked);
    }

    /// @notice Allows a user to unstake their funding tokens.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakedBalances[msg.sender] >= _amount, "Not enough staked tokens");

        stakedBalances[msg.sender] -= _amount;
        totalStaked -= _amount;

        // Transfer tokens from contract back to user
        bool success = fundingToken.transfer(msg.sender, _amount);
        require(success, "Token transfer failed");

        emit TokensUnstaked(msg.sender, _amount, totalStaked);
    }

    /// @notice Views a user's staked amount.
    /// @param _user The address of the user.
    /// @return The user's staked token balance.
    function getUserStake(address _user) external view returns (uint256) {
        return stakedBalances[_user];
    }

    /// @notice Views a user's reputation score.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Allows the owner/governance to award reputation points to a user.
    /// @param _user The user to award reputation to.
    /// @param _amount The amount of reputation points.
    function awardReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
         require(_user != address(0), "Cannot award reputation to zero address");
         require(_amount > 0, "Amount must be greater than zero");

         userReputation[_user] += _amount;
         totalReputation += _amount;

         emit ReputationAwarded(_user, _amount, totalReputation);
    }

    /// @notice Allows the owner/governance to penalize (reduce) a user's reputation points.
    /// @param _user The user to penalize.
    /// @param _amount The amount of reputation points to penalize.
    function penalizeReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
         require(_user != address(0), "Cannot penalize zero address");
         require(_amount > 0, "Amount must be greater than zero");
         uint256 currentReputation = userReputation[_user];
         uint256 penalty = _amount;

         if (penalty > currentReputation) {
            penalty = currentReputation; // Cannot go below zero
         }

         userReputation[_user] -= penalty;
         totalReputation -= penalty;

         emit ReputationPenalized(_user, penalty, totalReputation);
    }


    /// @notice Distributes collected fees as yield to stakers and reputation holders.
    /// Distribution is proportional to a combined weight (stake + reputation).
    function distributeYield() external nonReentrant whenNotPaused {
        uint256 yieldAmount = (feesCollected * params.yieldDistributionBasisPoints) / 10000; // Apply distribution rate
        if (yieldAmount == 0) {
            return; // No yield to distribute or rate is 0
        }

        uint256 totalWeight = totalStaked + totalReputation; // Simple combined weight
        if (totalWeight == 0) {
            feesCollected = 0; // If no one is eligible, burn/reset fees
            emit YieldDistributed(0, 0);
            return;
        }

        // Iterate through all stakers/reputation holders (NOTE: this is inefficient for large user bases)
        // A real system would use a pull-based system or a more gas-efficient distribution method.
        // For demonstration, we simulate distribution to a few key addresses.
        // In a real scenario, you'd need a way to track all eligible users.
        // This implementation is a placeholder demonstrating the concept.
        // DO NOT use this iteration pattern in production with unknown user count.

        // --- Placeholder Distribution Logic (Inefficient) ---
        // A real system would maintain a list of users or use a Merkle Tree/Accumulator
        // Or a pull-based mechanism where users claim based on checkpointed weight.
        // For the sake of having the function and showing the *intent*, we'll just reset fees.
        // A proper implementation is beyond the scope of a single example function due to gas limits.

        // Simulating distribution:
        uint256 distributed = 0;
        // In a real system, you'd loop through addresses.
        // For example: for (address user in _eligibleUsers) { ... calculate and send ... }
        // This requires tracking _eligibleUsers, which is complex state.

        // Resetting feesCollected as if it were distributed (conceptually)
        // The actual token transfer would need a proper user enumeration or pull mechanism.
        distributed = yieldAmount; // Assume distributed conceptually
        feesCollected -= distributed; // Reduce fees by the amount notionally distributed

        emit YieldDistributed(distributed, feesCollected);
        // --- End Placeholder Distribution Logic ---

        // TODO: Implement a gas-efficient yield distribution mechanism (e.g., pull-based or snapshot + Merkle proof)
    }

    /// @notice Views the total amount of fees collected and available for yield distribution.
    /// @return The total distributable yield.
    function getDistributableYield() external view returns (uint256) {
        return (feesCollected * params.yieldDistributionBasisPoints) / 10000;
    }

    /// @notice Estimates the pending yield for a specific user based on current fees, stake, and reputation.
    /// This is an *estimate* and does not account for changes in total stake/reputation or fees between calls.
    /// @param _user The address of the user.
    /// @return The estimated pending yield for the user.
    function getPendingYield(address _user) external view returns (uint256) {
         uint256 userWeight = stakedBalances[_user] + userReputation[_user];
         uint256 totalWeight = totalStaked + totalReputation;
         uint256 totalYield = getDistributableYield();

         if (totalWeight == 0 || userWeight == 0) {
             return 0;
         }

         return (userWeight * totalYield) / totalWeight;
    }

    /// @notice Allows the owner to update the minimum funding goal parameter.
    /// @param _newThreshold The new minimum funding goal value.
    function updateFundingGoalThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        params.minFundingGoalThreshold = _newThreshold;
        emit ParametersUpdated("minFundingGoalThreshold");
    }

    /// @notice Allows the owner to update the project claim fee rate parameter.
    /// @param _newRate The new fee rate (in basis points, 10000 = 100%).
    function updateFeeRate(uint256 _newRate) external onlyOwner whenNotPaused {
        require(_newRate <= 10000, "Fee rate cannot exceed 100%");
        params.projectClaimFeeRate = _newRate;
         emit ParametersUpdated("projectClaimFeeRate");
    }

    /// @notice Allows the owner to update the criteria for a project to propose Sphere conversion.
    /// @param _minFunding The new minimum funding requirement.
    /// @param _minMilestones The new minimum milestones completed requirement.
    function updateSphereConversionCriteria(uint256 _minFunding, uint256 _minMilestones) external onlyOwner whenNotPaused {
        params.sphereConversionMinFunding = _minFunding;
        params.sphereConversionMinMilestones = _minMilestones;
        emit ParametersUpdated("sphereConversionCriteria");
    }

    /// @notice Pauses the contract, disabling certain functions.
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, enabling all functions.
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

     /// @notice Views the current status of a project.
     /// @param _projectId The ID of the project.
     /// @return The project's current status.
    function getProjectStatus(uint256 _projectId) external view returns (ProjectStatus) {
         require(projects[_projectId].id != 0, "Project does not exist");
         return projects[_projectId].status;
    }

    // --- Additional Functions (Pushing towards 20+) ---

    /// @notice Allows owner or governance to cancel a project. Funds are frozen or returned (not implemented).
    /// @param _projectId The ID of the project to cancel.
    function cancelProject(uint256 _projectId)
        external
        onlyOwner // Simplified governance
        projectMustBeAnyStatus(_projectId, new ProjectStatus[](3).push(ProjectStatus.Proposed).push(ProjectStatus.Funded).push(ProjectStatus.Active))
        whenNotPaused
    {
        projects[_projectId].status = ProjectStatus.Cancelled;
         emit ProjectStatusChanged(_projectId, projects[_projectId].status, ProjectStatus.Cancelled);
        // TODO: Handle project balance (_projectBalances[_projectId]) - return to funders? Hold?
    }

     /// @notice Views the number of children a Sphere has.
     /// @param _sphereId The ID of the Sphere.
     /// @return The count of children funded by the Sphere.
    function getSphereChildCount(uint256 _sphereId) external view returns (uint256) {
         require(spheres[_sphereId].id != 0, "Sphere does not exist");
         return _sphereChildren[_sphereId].length;
    }

    /// @notice Views a project's full details.
    /// @param _projectId The ID of the project.
    /// @return Project struct details.
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
         require(projects[_projectId].id != 0, "Project does not exist");
         return projects[_projectId];
    }

    /// @notice Views a Sphere's full details.
    /// @param _sphereId The ID of the Sphere.
    /// @return Sphere struct details.
    function getSphereDetails(uint256 _sphereId) external view returns (Sphere memory) {
         require(spheres[_sphereId].id != 0, "Sphere does not exist");
         return spheres[_sphereId];
    }

    /// @notice Gets the total number of projects ever registered.
    /// @return Total project count.
    function getTotalProjectCount() external view returns (uint256) {
        return _projectIds.current();
    }

     /// @notice Gets the total number of Spheres ever created.
     /// @return Total Sphere count.
    function getTotalSphereCount() external view returns (uint256) {
        return _sphereIds.current(); // This counts Sphere conversions
    }

    /// @notice Views the current dynamic parameters.
    /// @return DynamicParameters struct.
    function getCurrentParameters() external view returns (DynamicParameters memory) {
        return params;
    }

    // --- Reached 26 functions. Can add more if needed, e.g., governance proposals, voting,
    // more complex yield distribution, project completion logic, failure handling, etc. ---
}
```