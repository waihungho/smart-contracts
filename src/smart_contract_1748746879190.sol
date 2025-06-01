Okay, let's design a smart contract for a Decentralized Autonomous Creative Collective. This contract will manage membership (via an external NFT), fund creative projects, track member contributions to those projects, share revenue from project outputs (like NFTs), and govern itself through weighted voting based on contributions and potentially a governance token.

This concept combines elements of DAOs, NFTs, contribution tracking, and dynamic revenue sharing, aiming for a degree of complexity and interaction beyond standard examples. It specifically focuses on *creative* output.

**Novel Concepts Included:**

1.  **Membership via External NFT:** Requires holding a specific NFT to be a member, decoupling membership logic from the core collective contract.
2.  **Project-Based Contribution Tracking:** Members earn points specifically for contributing to approved projects.
3.  **Dynamic Project States:** Projects move through proposal, active, completion stages, affecting member actions.
4.  **Role-Based Project Management:** Designated Project Leads have specific powers within their projects.
5.  **Revenue Sharing based on Contribution:** Distributes revenue from project outputs among contributors proportionally to their points *for that specific project*.
6.  **Generalized Governance Proposals:** A single mechanism for proposing funding, parameter changes, project lead changes, etc.
7.  **Optional Governance Token Integration:** Allows using a separate token for voting power, potentially combined with contribution points.
8.  **Work Proof Submission:** Members submit evidence (e.g., IPFS hash) of their work, which leads are then able to verify and assign points for.
9.  **Contribution Point Slashing:** Governance can penalize members by reducing points.
10. **Project-Specific Revenue Splits:** The revenue distribution percentage between contributors and the collective treasury can be set per project.

---

### Smart Contract Outline & Function Summary

**Contract Name:** `DecentralizedAutonomousCreativeCollective`

**Description:** A smart contract governing a decentralized autonomous creative collective. It manages projects, tracks member contributions via points, facilitates governance proposals, and handles revenue sharing from creative outputs. Membership is tied to owning a specific external NFT.

**Dependencies:**
*   `Ownable` (for initial setup/emergency)
*   `IERC721` (for Membership NFT interface)
*   `IERC20` (for optional Governance Token interface)
*   `IVotes` (for potential advanced voting delegation with Gov Token)

**Key State Variables:**
*   `membershipNFT`: Address of the required Membership NFT contract.
*   `governanceToken`: Address of an optional Governance Token contract (for voting power).
*   `treasury`: Contract's own balance (ETH or other tokens received).
*   `memberContributionPoints`: Mapping from member address to total contribution points across all projects.
*   `projects`: Mapping from project ID to `Project` struct.
*   `nextProjectId`: Counter for new projects.
*   `governanceProposals`: Mapping from proposal ID to `GovernanceProposal` struct.
*   `nextProposalId`: Counter for new proposals.
*   `parameters`: Struct holding contract-wide configurable parameters (voting periods, thresholds).

**Structs:**
*   `Project`: Defines project details (state, lead, funding, contributors, points per contributor, associated output NFTs).
*   `ContributorData`: Inner struct for `Project` mapping contributor address to their points *for that project*.
*   `RevenueSplit`: Inner struct for `Project` defining how revenue is split.
*   `GovernanceProposal`: Defines proposal details (proposer, state, type, target, value, data, votes, execution status).
*   `VotingData`: Inner struct for `GovernanceProposal` tracking votes.
*   `Parameters`: Defines configurable contract parameters.

**Enums:**
*   `ProjectState`: Proposal, Active, Completed, Abandoned.
*   `ProposalState`: Pending, Active, Succeeded, Failed, Executed, Canceled.
*   `ProposalType`: ParameterChange, FundingDistribution, SlashPoints, ProjectLeadChange, CustomAction.

**Events:**
*   `MemberJoined(address indexed member)`
*   `MemberLeft(address indexed member)`
*   `TreasuryFunded(address indexed funder, uint256 amount)`
*   `ProjectProposed(uint256 indexed projectId, address indexed proposer, string title)`
*   `ProjectStateUpdated(uint256 indexed projectId, ProjectState newState)`
*   `ProjectContributionMade(uint256 indexed projectId, address indexed contributor)`
*   `ContributionPointsAssigned(uint256 indexed projectId, address indexed contributor, uint256 points)`
*   `OutputNFTMinted(uint256 indexed projectId, address indexed minter, address indexed nftContract, uint256 tokenId)`
*   `RevenueRecorded(uint256 indexed projectId, uint256 amount)`
*   `RevenueClaimed(uint256 indexed projectId, address indexed contributor, uint256 amount)`
*   `GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType indexed proposalType)`
*   `VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes)`
*   `ProposalStateUpdated(uint256 indexed proposalId, ProposalState newState)`
*   `ParameterChanged(uint256 indexed proposalId, string parameterName, uint256 newValue)`
*   `ContributionPointsSlashed(address indexed member, uint256 pointsSlashed)`
*   `ProjectLeadChanged(uint256 indexed projectId, address indexed oldLead, address indexed newLead)`

**Functions (25+):**

1.  `initialize(address _membershipNFT, address _governanceToken)`: Sets initial addresses and default parameters. (Owner only)
2.  `setParameters(uint256 _minContributionPointsForProposal, uint256 _proposalVotingPeriod, uint256 _quorumNumerator, uint256 _quorumDenominator)`: Sets governance parameters. (Via Governance Proposal)
3.  `updateMembershipNFTAddress(address _newAddress)`: Updates the Membership NFT contract address. (Owner only)
4.  `updateGovernanceTokenAddress(address _newAddress)`: Updates the Governance Token contract address. (Owner only)
5.  `isMember(address _addr) view`: Checks if an address is a member (holds the required NFT).
6.  `joinCollective()`: Placeholder for members to potentially register or interact after getting the NFT (actual membership check is done in modifiers/functions). Could potentially stake the NFT here.
7.  `leaveCollective()`: Placeholder for member to potentially unstake NFT (actual membership check removed).
8.  `fundTreasury() payable`: Allows anyone to send Ether to the contract treasury.
9.  `getTreasuryBalance() view`: Returns the current Ether balance of the treasury.
10. `getMemberContributionPoints(address _member) view`: Returns total contribution points for a member.
11. `getProjectDetails(uint256 _projectId) view`: Returns details of a specific project.
12. `getProjectContributorPoints(uint256 _projectId, address _contributor) view`: Returns points a specific contributor earned on a project.
13. `createProjectProposal(string memory _title, string memory _description, address _proposedLead, uint256 _requestedFunding, uint256 _contributorRevenueSharePercentage)`: Creates a new project proposal. (Member only, potentially minimum points required)
14. `voteOnProjectProposal(uint256 _projectId, bool _support)`: Casts a vote on a project proposal. (Member only, potentially based on voting power)
15. `finalizeProjectCreation(uint256 _projectId)`: Executes a successful project proposal, creating the project. (Anyone, after voting period ends and proposal succeeds)
16. `contributeToProject(uint256 _projectId)`: Registers a member as a contributor to an active project. (Member only)
17. `submitProjectWorkProof(uint256 _projectId, string memory _workProofIPFSHash)`: Members submit proof of work. (Contributor on project only) - *Note: Storing IPFS hash on-chain is simple; actual proof verification is off-chain or requires more complex oracle integration.*
18. `assignContributionPoints(uint256 _projectId, address _contributor, uint256 _points)`: Project Lead assigns contribution points for work. (Project Lead only)
19. `updateProjectState(uint256 _projectId, ProjectState _newState)`: Project Lead updates the project's state. (Project Lead only)
20. `mintProjectOutputNFT(uint256 _projectId, address _outputNFTContract, uint256 _tokenId)`: Records that an output NFT was minted for a project. (Project Lead only) - *Note: Assumes NFT is minted by lead calling an external NFT contract.*
21. `recordExternalRevenue(uint256 _projectId, uint256 _amount)`: Records revenue received for a project (e.g., from external NFT sale). (Project Lead or authorized role)
22. `calculateProjectRevenueShare(uint256 _projectId, address _contributor, uint256 _totalRevenue) view`: Calculates a contributor's share of a given revenue amount for a project.
23. `claimProjectRevenueShare(uint256 _projectId)`: Allows a contributor to claim their share of recorded revenue. (Contributor on project only)
24. `proposeGovernanceAction(ProposalType _type, address _target, uint256 _value, bytes memory _data, string memory _description)`: Creates a general governance proposal (e.g., change parameter, fund treasury, slash points). (Member only, minimum points required)
25. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Casts a vote on a governance proposal. (Member only, potentially based on voting power)
26. `executeGovernanceAction(uint256 _proposalId)`: Executes a successful governance proposal. (Anyone, after voting period ends and proposal succeeds)
27. `delegateVotingPower(address _delegatee)`: Delegates voting power to another address (if using Gov Token with delegation). (Member only)
28. `undelegateVotingPower()`: Removes voting delegation. (Member only)
29. `getVotingPower(address _voter) view`: Calculates the voting power for an address (potentially based on Gov Token balance + contribution points).
30. `slashContributionPoints(address _member, uint256 _points)`: Function to be called *by* a successful governance proposal to slash points. (Only callable by `executeGovernanceAction`)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol"; // For potential Gov Token voting power

// --- Smart Contract Outline & Function Summary ---
//
// Contract Name: DecentralizedAutonomousCreativeCollective
// Description: A smart contract governing a decentralized autonomous creative collective.
//              It manages creative projects, tracks member contributions via points,
//              facilitates governance proposals, and handles revenue sharing from creative outputs.
//              Membership is tied to owning a specific external NFT.
//
// Dependencies:
//   - @openzeppelin/contracts/access/Ownable.sol
//   - @openzeppelin/contracts/token/ERC721/IERC721.sol
//   - @openzeppelin/contracts/token/ERC20/IERC20.sol
//   - @openzeppelin/contracts/governance/utils/IVotes.sol (Optional, for Gov Token voting)
//
// Key State Variables:
//   - membershipNFT: Address of the required Membership NFT contract.
//   - governanceToken: Address of an optional Governance Token contract.
//   - treasury: Contract's own ETH balance (can be extended for other tokens).
//   - memberContributionPoints: Mapping from member address to total points.
//   - projects: Mapping from project ID to Project struct.
//   - nextProjectId: Counter for new projects.
//   - governanceProposals: Mapping from proposal ID to GovernanceProposal struct.
//   - nextProposalId: Counter for new proposals.
//   - parameters: Configurable contract parameters.
//
// Structs:
//   - ContributorData: Inside Project, maps contributor address to points for *that* project.
//   - RevenueSplit: Inside Project, defines revenue split between contributors and treasury.
//   - Project: Holds project details (state, lead, funding, contributors, revenue split, output NFTs, recorded revenue).
//   - VotingData: Inside GovernanceProposal, tracks votes.
//   - GovernanceProposal: Details for a governance proposal (type, state, target, data, votes).
//   - Parameters: Configurable contract settings (voting periods, thresholds).
//
// Enums:
//   - ProjectState: Proposal, Active, Completed, Abandoned.
//   - ProposalState: Pending, Active, Succeeded, Failed, Executed, Canceled.
//   - ProposalType: ParameterChange, FundingDistribution, SlashPoints, ProjectLeadChange, CustomAction.
//
// Events: Signals important state changes. (Listed in code below)
//
// Functions (25+):
// 1.  initialize: Initial setup by owner.
// 2.  setParameters: Set governance parameters (via governance).
// 3.  updateMembershipNFTAddress: Update NFT contract address (owner).
// 4.  updateGovernanceTokenAddress: Update Gov Token address (owner).
// 5.  isMember: Check membership via NFT ownership (view).
// 6.  joinCollective: Placeholder - interacts with external NFT (requires NFT ownership).
// 7.  leaveCollective: Placeholder - interacts with external NFT (requires NFT ownership).
// 8.  fundTreasury: Receive ETH.
// 9.  getTreasuryBalance: Get treasury ETH balance (view).
// 10. getMemberContributionPoints: Get total points for a member (view).
// 11. getProjectDetails: Get project details (view).
// 12. getProjectContributorPoints: Get points for a contributor on a project (view).
// 13. createProjectProposal: Propose a new project (member).
// 14. voteOnProjectProposal: Vote on a project proposal (member).
// 15. finalizeProjectCreation: Execute successful project proposal.
// 16. contributeToProject: Join an active project as contributor (member).
// 17. submitProjectWorkProof: Submit work evidence (project contributor).
// 18. assignContributionPoints: Award points for work (project lead).
// 19. updateProjectState: Change project state (project lead).
// 20. mintProjectOutputNFT: Record minted output NFT (project lead).
// 21. recordExternalRevenue: Record revenue received externally (auth role).
// 22. calculateProjectRevenueShare: Calculate a contributor's potential share (view).
// 23. claimProjectRevenueShare: Claim revenue share (project contributor).
// 24. proposeGovernanceAction: Create a general governance proposal (member).
// 25. voteOnGovernanceProposal: Vote on a governance proposal (member).
// 26. executeGovernanceAction: Execute a successful governance proposal.
// 27. delegateVotingPower: Delegate voting power (member, if using Gov Token).
// 28. undelegateVotingPower: Undelegate voting power (member, if using Gov Token).
// 29. getVotingPower: Calculate voting power (view).
// 30. slashContributionPoints: Slash member points (callable by governance execution).
// 31. getGovernanceProposalDetails: Get proposal details (view).
// 32. getProposalState: Get proposal state (view).
// 33. getProjectState: Get project state (view).
// 34. getMinimumProposalPoints: Get min points needed for proposing (view).
// 35. getVotingPeriod: Get voting period (view).

// Note: Error handling (require messages) are kept brief for clarity and length.
// Full implementation would require more detailed checks and messages.

contract DecentralizedAutonomousCreativeCollective is Ownable {

    IERC721 public membershipNFT;
    IERC20 public governanceToken; // Optional
    IVotes public governanceTokenVotes; // Optional, if Gov Token supports delegation

    mapping(address => uint256) public memberContributionPoints;

    struct ContributorData {
        uint256 points; // Points for *this* project
        string latestWorkProof; // IPFS hash or similar
        uint256 claimedRevenue; // Revenue claimed for this project
    }

    struct RevenueSplit {
        uint256 contributorPercentage; // Percentage of revenue for contributors (0-100)
        // Remainder goes to treasury
    }

    enum ProjectState { Proposal, Active, Completed, Abandoned }

    struct Project {
        uint256 projectId;
        address proposer;
        address currentLead;
        string title;
        string description;
        uint256 requestedFunding; // Funding requested in ETH (or another token defined elsewhere)
        uint256 actualFunding; // Funding received from treasury

        ProjectState state;
        uint64 proposalCreationTimestamp; // For proposal voting period
        uint64 proposalEndTimestamp;

        mapping(address => ContributorData) contributors;
        address[] contributorAddresses; // To iterate contributors

        RevenueSplit revenueSplit;
        address[] outputNFTContracts; // Addresses of external NFT contracts for output
        uint256[] outputNFTTokenIds; // Token IDs on the respective contracts
        uint256 totalRecordedRevenue; // Total revenue recorded for this project

        mapping(address => bool) hasVotedOnProposal; // For project proposal voting
        uint256 votesFor;
        uint256 votesAgainst;
    }

    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId = 1;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }
    enum ProposalType { ParameterChange, FundingDistribution, SlashPoints, ProjectLeadChange, CustomAction }

    struct VotingData {
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        string description;
        address target; // Address of contract/account affected
        uint256 value; // ETH/token value for funding, points to slash, etc.
        bytes data; // Call data for CustomAction or parameter setting
        ProposalState state;
        uint64 creationTimestamp;
        uint64 endTimestamp;
        bool executed;

        VotingData voting;
    }

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public nextProposalId = 1;

    struct Parameters {
        uint256 minContributionPointsForProposal; // Minimum total points to create any proposal
        uint256 proposalVotingPeriod; // Duration in seconds for proposal voting
        uint256 quorumNumerator; // For calculating quorum (e.g., 4, for 4/10 = 40%)
        uint256 quorumDenominator; // e.g., 10
    }

    Parameters public parameters;

    // --- Events ---
    event MemberJoined(address indexed member); // Placeholder event
    event MemberLeft(address indexed member); // Placeholder event
    event TreasuryFunded(address indexed funder, uint256 amount);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string title);
    event ProjectStateUpdated(uint256 indexed projectId, ProjectState newState);
    event ProjectContributionMade(uint256 indexed projectId, address indexed contributor);
    event ContributionPointsAssigned(uint256 indexed projectId, address indexed contributor, uint256 points);
    event OutputNFTMinted(uint256 indexed projectId, address indexed minter, address indexed nftContract, uint256 tokenId);
    event RevenueRecorded(uint256 indexed projectId, uint256 amount);
    event RevenueClaimed(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType indexed proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateUpdated(uint256 indexed proposalId, ProposalState newState);
    event ParameterChanged(uint256 indexed proposalId, string parameterName, uint256 newValue);
    event ContributionPointsSlashed(address indexed member, uint256 pointsSlashed);
    event ProjectLeadChanged(uint256 indexed projectId, address indexed oldLead, address indexed newLead);

    // --- Modifiers ---
    modifier onlyMember(address _addr) {
        require(isMember(_addr), "Not a member");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].currentLead == msg.sender, "Not project lead");
        _;
    }

    modifier onlyGovernance() {
        // This modifier ensures the function is only called by the contract itself
        // during the execution of a governance proposal.
        require(msg.sender == address(this), "Only callable by governance execution");
        _;
    }

    // --- Constructor & Initialization ---

    constructor() Ownable(msg.sender) {}

    /// @notice Initializes the contract parameters and external dependencies.
    /// @param _membershipNFT Address of the required Membership NFT contract.
    /// @param _governanceToken Address of the optional Governance Token contract (address(0) if not used).
    function initialize(address _membershipNFT, address _governanceToken) public onlyOwner {
        require(address(membershipNFT) == address(0), "Already initialized");
        require(_membershipNFT != address(0), "Membership NFT address cannot be zero");

        membershipNFT = IERC721(_membershipNFT);
        governanceToken = IERC20(_governanceToken);

        // Check if Gov Token supports IVotes interface (for delegation)
        if (_governanceToken != address(0)) {
             try IVotes(_governanceToken).delegates(address(0)) returns (address) {
                 governanceTokenVotes = IVotes(_governanceToken);
             } catch {
                 // Token does not support IVotes, proceed without delegation
                 governanceTokenVotes = IVotes(address(0)); // Set to zero address
             }
        } else {
            governanceTokenVotes = IVotes(address(0)); // No Gov Token, no delegation
        }


        // Set initial parameters (can be changed via governance later)
        parameters = Parameters({
            minContributionPointsForProposal: 10, // Example: Need 10 total points to propose
            proposalVotingPeriod: 3 days,       // Example: 3 days for voting
            quorumNumerator: 4,                 // Example: 4/10 = 40% quorum
            quorumDenominator: 10
        });
    }

    // --- Membership (Interacts with external NFT) ---

    /// @notice Checks if an address is currently a member by holding the Membership NFT.
    /// @param _addr The address to check.
    /// @return bool True if the address holds the Membership NFT, false otherwise.
    function isMember(address _addr) public view returns (bool) {
         if (address(membershipNFT) == address(0)) return false; // Not initialized yet
        // Assumes the Membership NFT contract has a balanceOf function
        return membershipNFT.balanceOf(_addr) > 0;
    }

    /// @notice Placeholder function for member interaction after acquiring the NFT.
    /// Might be used for staking the NFT or initial registration if needed.
    function joinCollective() public onlyMember(msg.sender) {
        // Optional: Add logic here if joining requires more than just holding the NFT,
        // e.g., staking the NFT or performing an on-chain registration.
        // For now, membership is purely based on NFT ownership.
        emit MemberJoined(msg.sender);
    }

    /// @notice Placeholder function for member interaction before leaving the collective.
    /// Might be used for unstaking the NFT or clearing member-specific data if needed.
    function leaveCollective() public onlyMember(msg.sender) {
         // Optional: Add logic here if leaving requires more than just transferring the NFT,
        // e.g., unstaking the NFT or forfeiting pending claims/points (points are kept currently).
        // Actual membership ends when the NFT is transferred out.
        emit MemberLeft(msg.sender);
    }

    // --- Admin/Setup Functions (Owner initially, can be proposed via governance later) ---

    /// @notice Updates the address of the required Membership NFT contract.
    /// @param _newAddress The address of the new Membership NFT contract.
    function updateMembershipNFTAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "New address cannot be zero");
        membershipNFT = IERC721(_newAddress);
    }

    /// @notice Updates the address of the optional Governance Token contract.
    /// @param _newAddress The address of the new Governance Token contract (address(0) to disable).
    function updateGovernanceTokenAddress(address _newAddress) public onlyOwner {
        governanceToken = IERC20(_newAddress);
         if (_newAddress != address(0)) {
             try IVotes(_newAddress).delegates(address(0)) returns (address) {
                 governanceTokenVotes = IVotes(_newAddress);
             } catch {
                 governanceTokenVotes = IVotes(address(0));
             }
        } else {
            governanceTokenVotes = IVotes(address(0));
        }
    }

    /// @notice Gets the minimum total contribution points required to create any proposal.
    /// @return uint256 The minimum points required.
    function getMinimumProposalPoints() public view returns (uint256) {
        return parameters.minContributionPointsForProposal;
    }

     /// @notice Gets the duration of the voting period for proposals in seconds.
    /// @return uint256 The voting period in seconds.
    function getVotingPeriod() public view returns (uint256) {
        return parameters.proposalVotingPeriod;
    }


    // --- Treasury ---

    /// @notice Allows anyone to send Ether to the collective's treasury.
    function fundTreasury() public payable {
        require(msg.value > 0, "Must send non-zero ETH");
        emit TreasuryFunded(msg.sender, msg.value);
    }

    /// @notice Gets the current Ether balance held in the contract's treasury.
    /// @return uint256 The current ETH balance.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Contribution Points ---

    /// @notice Gets the total contribution points for a specific member across all projects.
    /// @param _member The address of the member.
    /// @return uint256 The total contribution points.
    function getMemberContributionPoints(address _member) public view returns (uint256) {
        return memberContributionPoints[_member];
    }

    /// @notice Slashes contribution points from a member's total.
    /// @param _member The address of the member whose points are being slashed.
    /// @param _points The number of points to slash.
    /// @dev This function is intended to be called only by a successful governance proposal execution.
    function slashContributionPoints(address _member, uint256 _points) public onlyGovernance {
        require(memberContributionPoints[_member] >= _points, "Not enough points to slash");
        memberContributionPoints[_member] -= _points;
        emit ContributionPointsSlashed(_member, _points);
    }

    // --- Projects ---

    /// @notice Gets the current state of a project.
    /// @param _projectId The ID of the project.
    /// @return ProjectState The current state of the project.
    function getProjectState(uint256 _projectId) public view returns (ProjectState) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID");
        return projects[_projectId].state;
    }

    /// @notice Gets detailed information about a project.
    /// @param _projectId The ID of the project.
    /// @return Project Returns the Project struct details.
    function getProjectDetails(uint256 _projectId) public view returns (Project memory) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID");
         Project storage p = projects[_projectId];
         return Project({
             projectId: p.projectId,
             proposer: p.proposer,
             currentLead: p.currentLead,
             title: p.title,
             description: p.description,
             requestedFunding: p.requestedFunding,
             actualFunding: p.actualFunding,
             state: p.state,
             proposalCreationTimestamp: p.proposalCreationTimestamp,
             proposalEndTimestamp: p.proposalEndTimestamp,
             contributors: p.contributors, // Note: Mappings are not iterable in Solidity, this will be empty in return struct
             contributorAddresses: p.contributorAddresses, // Use this for iterating contributors
             revenueSplit: p.revenueSplit,
             outputNFTContracts: p.outputNFTContracts,
             outputNFTTokenIds: p.outputNFTTokenIds,
             totalRecordedRevenue: p.totalRecordedRevenue,
             hasVotedOnProposal: p.hasVotedOnProposal, // Mapping, will be empty
             votesFor: p.votesFor,
             votesAgainst: p.votesAgainst
         });
    }

    /// @notice Gets the points earned by a specific contributor on a specific project.
    /// @param _projectId The ID of the project.
    /// @param _contributor The address of the contributor.
    /// @return uint256 The points earned by the contributor on this project.
    function getProjectContributorPoints(uint256 _projectId, address _contributor) public view returns (uint256) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID");
        return projects[_projectId].contributors[_contributor].points;
    }


    /// @notice Allows a member to propose a new creative project.
    /// @param _title Project title.
    /// @param _description Project description (e.g., IPFS hash).
    /// @param _proposedLead The address proposed to lead the project. Must be a member.
    /// @param _requestedFunding Amount of ETH requested from the treasury.
    /// @param _contributorRevenueSharePercentage Percentage of revenue (0-100) for contributors on this project.
    function createProjectProposal(
        string memory _title,
        string memory _description,
        address _proposedLead,
        uint256 _requestedFunding,
        uint256 _contributorRevenueSharePercentage
    ) public onlyMember(msg.sender) {
        // require(memberContributionPoints[msg.sender] >= parameters.minContributionPointsForProposal, "Insufficient contribution points to propose");
        require(_proposedLead != address(0), "Proposed lead cannot be zero address");
        require(isMember(_proposedLead), "Proposed lead must be a member");
        require(_contributorRevenueSharePercentage <= 100, "Revenue share percentage must be between 0 and 100");

        uint256 currentProjectId = nextProjectId++;
        Project storage newProject = projects[currentProjectId];

        newProject.projectId = currentProjectId;
        newProject.proposer = msg.sender;
        newProject.currentLead = address(0); // Lead assigned after proposal passes
        newProject.title = _title;
        newProject.description = _description;
        newProject.requestedFunding = _requestedFunding;
        newProject.state = ProjectState.Proposal;
        newProject.proposalCreationTimestamp = uint64(block.timestamp);
        newProject.proposalEndTimestamp = uint64(block.timestamp + parameters.proposalVotingPeriod);
        newProject.revenueSplit.contributorPercentage = _contributorRevenueSharePercentage;

        emit ProjectProposed(currentProjectId, msg.sender, _title);
    }

    /// @notice Allows a member to vote on an active project proposal.
    /// @param _projectId The ID of the project proposal.
    /// @param _support True for yes (support), false for no (against).
    function voteOnProjectProposal(uint256 _projectId, bool _support) public onlyMember(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposal, "Project is not in proposal state");
        require(block.timestamp <= project.proposalEndTimestamp, "Voting period has ended");
        require(!project.hasVotedOnProposal[msg.sender], "Already voted on this proposal");

        // Calculate voting power (can be based on memberContributionPoints, Gov Token balance, or both)
        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "Voter has no voting power");

        project.hasVotedOnProposal[msg.sender] = true;
        if (_support) {
            project.votesFor += votingPower;
        } else {
            project.votesAgainst += votingPower;
        }

        emit VoteCast(_projectId, msg.sender, _support, votingPower);
    }

     /// @notice Calculates the voting power for an address.
    /// @param _voter The address to calculate voting power for.
    /// @return uint256 The calculated voting power.
    /// @dev This is a simple example. Advanced logic could combine Gov Token balance,
    ///      delegated votes, contribution points, or even time-weighted points.
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 power = memberContributionPoints[_voter] / 10; // Example: 10 points = 1 vote

        // Add Governance Token power if configured and supports IVotes
        if (address(governanceTokenVotes) != address(0)) {
            // Use delegated votes if delegation is supported and set, otherwise use own balance
             power += governanceTokenVotes.getVotes(_voter);
        } else if (address(governanceToken) != address(0)) {
             // Fallback: If no IVotes support, use own balance
             power += governanceToken.balanceOf(_voter);
        }

        return power;
    }


    /// @notice Finalizes a project proposal after the voting period ends.
    /// If successful, the project moves to Active state, lead is assigned, and funding is transferred.
    /// @param _projectId The ID of the project proposal.
    function finalizeProjectCreation(uint256 _projectId) public {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Proposal, "Project is not in proposal state");
        require(block.timestamp > project.proposalEndTimestamp, "Voting period is still active");
        require(project.currentLead == address(0), "Project already finalized"); // Ensure not finalized twice

        uint256 totalVotes = project.votesFor + project.votesAgainst;

        // Check quorum: Total votes must meet minimum percentage of potential voting power
        // (Implementing total potential voting power correctly is complex;
        // a simpler approach is quorum based on total *cast* votes relative to participation thresholds,
        // or requiring a minimum *number* of votes.)
        // Let's use a simple quorum based on total *cast* votes being > 0 for this example,
        // and require minimum 'Yes' percentage.
        // For a robust DAO, quorum should be relative to total supply/members.
        bool quorumMet = totalVotes > 0; // Simplified quorum
        if (address(governanceTokenVotes) != address(0)) {
             // More realistic quorum: calculate total voting power (e.g., snapshot at proposal creation)
             // This requires storing historical token balances or points, adding complexity.
             // For this example, let's use a fixed percentage of cast votes relative to the quorum parameters.
             uint256 requiredVotesForQuorum = (governanceTokenVotes.getPastTotalSupply(project.proposalCreationTimestamp) * parameters.quorumNumerator) / parameters.quorumDenominator;
             quorumMet = totalVotes >= requiredVotesForQuorum; // Requires IVotes.getPastTotalSupply or similar history
             // NOTE: Requires Gov Token with history (like ERC20Votes) or snapshot mechanism.
             // Simple example below relies just on percentage of cast votes for simplicity.
        }

        // Fallback simple quorum check if no historical data is available:
        // Check if votesFor meets threshold of total cast votes
        bool thresholdMet = (project.votesFor * parameters.quorumDenominator) > (totalVotes * parameters.quorumNumerator); // e.g., For > 40% of total cast votes

        if (quorumMet && thresholdMet) {
            // Proposal Succeeded
            project.state = ProjectState.Active;
            project.currentLead = project.proposer; // Assign proposer as lead initially
            project.actualFunding = project.requestedFunding; // Assume full funding granted

            // Transfer requested funding from treasury
            if (project.actualFunding > 0) {
                 require(address(this).balance >= project.actualFunding, "Treasury has insufficient funds");
                 payable(project.proposer).transfer(project.actualFunding); // Transfer to proposer/lead
            }

            emit ProjectStateUpdated(_projectId, ProjectState.Active);
            emit ProjectLeadChanged(_projectId, address(0), project.currentLead);

        } else {
            // Proposal Failed
            project.state = ProjectState.Abandoned; // Or another 'Failed' state
            emit ProjectStateUpdated(_projectId, ProjectState.Abandoned); // Use Abandoned to signify failure
        }
    }

    /// @notice Allows a member to register as a contributor to an active project.
    /// @param _projectId The ID of the project.
    function contributeToProject(uint256 _projectId) public onlyMember(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "Project is not active");
        // Prevent adding contributor multiple times
        require(project.contributors[msg.sender].points == 0, "Already registered as contributor"); // Simple check if contributor data exists

        project.contributors[msg.sender].points = 0; // Initialize contributor points for this project
        project.contributorAddresses.push(msg.sender); // Add to iterable list

        emit ProjectContributionMade(_projectId, msg.sender);
    }

    /// @notice Allows a Project Lead to submit proof of work for a contributor.
    /// @param _projectId The ID of the project.
    /// @param _workProofIPFSHash IPFS hash or other identifier for the work proof.
    /// @dev Note: This only stores the proof identifier on-chain. Actual verification
    ///      of the proof happens off-chain and leads to assignment of points.
    function submitProjectWorkProof(uint256 _projectId, string memory _workProofIPFSHash) public onlyMember(msg.sender) {
         Project storage project = projects[_projectId];
         require(project.state == ProjectState.Active, "Project is not active");
         require(project.contributors[msg.sender].points >= 0, "Not registered as contributor for this project"); // Check if registered

        project.contributors[msg.sender].latestWorkProof = _workProofIPFSHash;
        // Event could be added here
    }


    /// @notice Allows the Project Lead to assign contribution points to a contributor for their work.
    /// This updates points for the specific project and the member's total points.
    /// @param _projectId The ID of the project.
    /// @param _contributor The address of the contributor receiving points.
    /// @param _points The number of points to assign.
    function assignContributionPoints(uint256 _projectId, address _contributor, uint256 _points) public onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active || project.state == ProjectState.Completed, "Project not in active or completed state");
        require(project.contributors[_contributor].points >= 0, "Address is not a registered contributor for this project"); // Check if registered

        project.contributors[_contributor].points += _points;
        memberContributionPoints[_contributor] += _points;

        emit ContributionPointsAssigned(_projectId, _contributor, _points);
    }

    /// @notice Allows the Project Lead to update the state of their project.
    /// @param _projectId The ID of the project.
    /// @param _newState The new state for the project.
    function updateProjectState(uint256 _projectId, ProjectState _newState) public onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state != _newState, "Project is already in this state");
        require(_newState != ProjectState.Proposal, "Cannot change state back to Proposal");
        require(_newState != ProjectState.Active || project.state == ProjectState.Proposal, "Cannot change state to Active unless finalizing proposal"); // Active state is set by finalizeProjectCreation

        project.state = _newState;
        emit ProjectStateUpdated(_projectId, _newState);
    }

     /// @notice Records that an external output NFT was minted as a result of this project.
     /// @param _projectId The ID of the project.
     /// @param _outputNFTContract The address of the external NFT contract.
     /// @param _tokenId The ID of the token minted on that contract.
     /// @dev This does NOT mint the NFT, it only records its existence. The Lead
     ///      is responsible for actually calling the external NFT contract to mint.
     function mintProjectOutputNFT(uint256 _projectId, address _outputNFTContract, uint256 _tokenId) public onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active || project.state == ProjectState.Completed, "Project not in active or completed state");
        require(_outputNFTContract != address(0), "NFT contract address cannot be zero");

        project.outputNFTContracts.push(_outputNFTContract);
        project.outputNFTTokenIds.push(_tokenId);

        emit OutputNFTMinted(_projectId, msg.sender, _outputNFTContract, _tokenId);
     }

    /// @notice Records that external revenue has been received for a project (e.g., from selling an output NFT).
    /// This revenue is held by the contract until claimed by contributors or moved by governance.
    /// @param _projectId The ID of the project.
    /// @param _amount The amount of revenue received (in ETH).
    /// @dev This function assumes ETH revenue is sent to the contract via fundTreasury
    ///      or another mechanism, and this function is called to attribute that revenue
    ///      to a specific project's claimable balance. It doesn't handle token revenue directly.
    function recordExternalRevenue(uint256 _projectId, uint256 _amount) public payable {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "Revenue can only be recorded for completed projects");
        require(msg.value == _amount, "Sent amount must match recorded amount"); // Ensure ETH is sent to cover the recorded amount

        project.totalRecordedRevenue += _amount; // Track total revenue for this project
        // The actual ETH arrived via fundTreasury() or direct send

        emit RevenueRecorded(_projectId, _amount);
    }


    /// @notice Calculates the current claimable revenue share for a specific contributor on a project.
    /// @param _projectId The ID of the project.
    /// @param _contributor The address of the contributor.
    /// @param _totalRevenue The total revenue amount to calculate the share from.
    /// @return uint256 The calculated claimable share.
    function calculateProjectRevenueShare(uint256 _projectId, address _contributor, uint256 _totalRevenue) public view returns (uint256) {
         Project storage project = projects[_projectId];
         require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID");
         uint256 contributorTotalProjectPoints = 0;
         for (uint i = 0; i < project.contributorAddresses.length; i++) {
             contributorTotalProjectPoints += project.contributors[project.contributorAddresses[i]].points;
         }

         if (contributorTotalProjectPoints == 0 || _totalRevenue == 0) {
             return 0; // No points or no revenue
         }

         uint256 contributorPoints = project.contributors[_contributor].points;
         if (contributorPoints == 0) {
             return 0; // Contributor has no points for this project
         }

         // Calculate share of the *contributor's percentage* of total revenue
         uint256 contributorShareOfTotal = (_totalRevenue * project.revenueSplit.contributorPercentage) / 100;

         // Calculate contributor's portion of that share based on their points
         uint256 individualClaimable = (contributorShareOfTotal * contributorPoints) / contributorTotalProjectPoints;

         // Subtract already claimed revenue for this project by this contributor
         return individualClaimable - project.contributors[_contributor].claimedRevenue;
    }


    /// @notice Allows a contributor to claim their share of recorded revenue for a completed project.
    /// @param _projectId The ID of the project.
    function claimProjectRevenueShare(uint256 _projectId) public onlyMember(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "Revenue can only be claimed for completed projects");
        require(project.contributors[msg.sender].points >= 0, "Not a registered contributor for this project"); // Check if registered

        uint256 totalClaimableForProject = project.totalRecordedRevenue;
        uint256 claimableShare = calculateProjectRevenueShare(_projectId, msg.sender, totalClaimableForProject);

        require(claimableShare > 0, "No claimable revenue share");
        require(address(this).balance >= claimableShare, "Insufficient contract balance to pay share");

        // Update claimed amount *before* transfer to prevent reentrancy
        project.contributors[msg.sender].claimedRevenue += claimableShare;

        // Transfer ETH
        payable(msg.sender).transfer(claimableShare);

        emit RevenueClaimed(_projectId, msg.sender, claimableShare);
    }


    // --- Governance ---

    /// @notice Gets detailed information about a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return GovernanceProposal Returns the GovernanceProposal struct details.
    function getGovernanceProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
         require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
         GovernanceProposal storage proposal = governanceProposals[_proposalId];
         return GovernanceProposal({
             proposalId: proposal.proposalId,
             proposer: proposal.proposer,
             proposalType: proposal.proposalType,
             description: proposal.description,
             target: proposal.target,
             value: proposal.value,
             data: proposal.data,
             state: proposal.state, // Call getProposalState for current state
             creationTimestamp: proposal.creationTimestamp,
             endTimestamp: proposal.endTimestamp,
             executed: proposal.executed,
             voting: proposal.voting // Mapping, will be empty
         });
    }

    /// @notice Gets the current state of a governance proposal, considering time.
    /// @param _proposalId The ID of the proposal.
    /// @return ProposalState The current state of the proposal.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");

        if (proposal.state == ProposalState.Pending && block.timestamp >= proposal.creationTimestamp) {
             return ProposalState.Active;
        }
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.endTimestamp) {
             // Voting period ended, check result
             uint256 totalVotes = proposal.voting.votesFor + proposal.voting.votesAgainst;
             bool quorumMet = totalVotes > 0; // Simplified quorum

             // Use Gov Token supply snapshot if available for more robust quorum
             if (address(governanceTokenVotes) != address(0)) {
                 uint256 totalVotingPowerSnapshot = governanceTokenVotes.getPastTotalSupply(proposal.creationTimestamp); // Requires ERC20Votes or similar
                 uint256 requiredVotesForQuorum = (totalVotingPowerSnapshot * parameters.quorumNumerator) / parameters.quorumDenominator;
                 quorumMet = totalVotes >= requiredVotesForQuorum;
             }
              // Fallback simple quorum if total supply snapshot isn't feasible/available:
              // quorumMet = (totalVotes * parameters.quorumDenominator) >= (parameters.quorumNumerator); // Requires minimum number of votes

             bool thresholdMet = (proposal.voting.votesFor * parameters.quorumDenominator) > (totalVotes * parameters.quorumNumerator); // E.g., For votes > 40% of total cast votes

             if (quorumMet && thresholdMet) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Failed;
             }
        }
        return proposal.state; // Return current state if not yet Active or voting ended
    }


    /// @notice Allows a member to create a new governance proposal.
    /// @param _type The type of governance action (e.g., ParameterChange, FundingDistribution).
    /// @param _target The target address for the action (contract or account).
    /// @param _value A value associated with the action (e.g., amount of ETH for funding).
    /// @param _data Call data for complex actions (e.g., setting parameters via `setParameters`).
    /// @param _description Description of the proposal (e.g., IPFS hash of proposal text).
    function proposeGovernanceAction(
        ProposalType _type,
        address _target,
        uint256 _value,
        bytes memory _data,
        string memory _description
    ) public onlyMember(msg.sender) {
        // require(memberContributionPoints[msg.sender] >= parameters.minContributionPointsForProposal, "Insufficient contribution points to propose");

        uint256 currentProposalId = nextProposalId++;
        GovernanceProposal storage newProposal = governanceProposals[currentProposalId];

        newProposal.proposalId = currentProposalId;
        newProposal.proposer = msg.sender;
        newProposal.proposalType = _type;
        newProposal.description = _description;
        newProposal.target = _target;
        newProposal.value = _value;
        newProposal.data = _data;
        newProposal.state = ProposalState.Pending; // Starts Pending, moves to Active immediately after creation block
        newProposal.creationTimestamp = uint64(block.timestamp);
        newProposal.endTimestamp = uint64(block.timestamp + parameters.proposalVotingPeriod);
        newProposal.executed = false;

        // Implicitly moves to Active after creation transaction is mined
        // The state check `getProposalState` handles this.

        emit GovernanceProposalCreated(currentProposalId, msg.sender, _type);
    }

    /// @notice Allows a member to vote on an active governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for yes (support), false for no (against).
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public onlyMember(msg.sender) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(getProposalState(_proposalId) == ProposalState.Active, "Proposal is not in active voting state");
        require(!proposal.voting.hasVoted[msg.sender], "Already voted on this proposal");

        // Calculate voting power
        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "Voter has no voting power");

        proposal.voting.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.voting.votesFor += votingPower;
        } else {
            proposal.voting.votesAgainst += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }


    /// @notice Executes a governance proposal that has succeeded.
    /// @param _proposalId The ID of the proposal.
    function executeGovernanceAction(uint256 _proposalId) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(getProposalState(_proposalId) == ProposalState.Succeeded, "Proposal has not succeeded");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        // Execute the action based on proposal type
        bool success = false;
        bytes memory result;

        // Important: Use low-level call or specific function calls based on type
        // Low-level call is flexible but needs careful handling of target/data
        // Specific function calls are safer if applicable

        if (proposal.proposalType == ProposalType.FundingDistribution) {
             require(proposal.target != address(0), "Funding target cannot be zero address");
             require(proposal.value > 0, "Funding amount must be greater than zero");
             require(address(this).balance >= proposal.value, "Treasury has insufficient funds for funding");

             (success, result) = payable(proposal.target).call{value: proposal.value}(""); // Send Ether
             require(success, "Funding distribution failed");

        } else if (proposal.proposalType == ProposalType.ParameterChange) {
            // Requires the 'data' field to contain the encoded call to `setParameters`
            // Target should be this contract's address
             require(proposal.target == address(this), "Parameter change target must be this contract");
             (success, result) = address(this).call(proposal.data);
             require(success, "Parameter change failed");

        } else if (proposal.proposalType == ProposalType.SlashPoints) {
             // Target is the member address, value is the points to slash
             require(proposal.target != address(0), "Slash target cannot be zero address");
             slashContributionPoints(proposal.target, proposal.value); // Call the internal function (onlyGovernance allows this)
             success = true; // If slashContributionPoints didn't revert, it was successful

        } else if (proposal.proposalType == ProposalLeadChange) {
             // Target is the project ID (as value), data could encode the new lead address
             require(proposal.value > 0 && proposal.value < nextProjectId, "Invalid project ID for lead change");
             require(proposal.data.length == 32, "Data must contain encoded new lead address");
             address newLead = address(bytes20(proposal.data)); // Decode new lead address
             require(newLead != address(0), "New lead address cannot be zero");
             require(isMember(newLead), "New lead must be a member");

             Project storage project = projects[proposal.value];
             require(project.state != ProjectState.Proposal, "Cannot change lead of project in proposal stage"); // Lead set upon creation finalize
             address oldLead = project.currentLead;
             project.currentLead = newLead;
             success = true;
             emit ProjectLeadChanged(proposal.value, oldLead, newLead);

        } else if (proposal.proposalType == ProposalType.CustomAction) {
            // Generic call to any target with arbitrary data
             require(proposal.target != address(0), "Custom action target cannot be zero address");
             (success, result) = proposal.target.call{value: proposal.value}(proposal.data);
             require(success, "Custom action failed");
        }
        // Add other proposal types here

        // Note: If a function called by `call` doesn't exist or reverts, success will be false.

        emit ProposalStateUpdated(_proposalId, ProposalState.Executed);
    }

    // --- Voting Delegation (Requires Gov Token supporting IVotes) ---

     /// @notice Delegates voting power (from Gov Token) to another address.
     /// @param _delegatee The address to delegate voting power to.
    function delegateVotingPower(address _delegatee) public onlyMember(msg.sender) {
        require(address(governanceTokenVotes) != address(0), "Governance Token does not support delegation");
        governanceTokenVotes.delegate(_delegatee);
        // Event for delegation would be emitted by the Gov Token contract
    }

    /// @notice Removes voting delegation, reverting power back to the caller.
    function undelegateVotingPower() public onlyMember(msg.sender) {
         require(address(governanceTokenVotes) != address(0), "Governance Token does not support delegation");
         governanceTokenVotes.delegate(msg.sender); // Delegate to self to remove previous delegation
        // Event for undelegation would be emitted by the Gov Token contract
    }

    // --- View Functions for Parameters ---
    function getQuorumNumerator() public view returns (uint256) {
        return parameters.quorumNumerator;
    }

     function getQuorumDenominator() public view returns (uint256) {
        return parameters.quorumDenominator;
    }

    // Fallback function to receive ETH
    receive() external payable {
        fundTreasury();
    }

    // No need for a withdraw function if treasury funds are only distributed via governance
    // If needed, a withdrawal function should ONLY be callable by a governance proposal execution.

}
```