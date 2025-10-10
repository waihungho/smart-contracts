This smart contract suite, named **"Project Minerva"**, establishes a Decentralized Autonomous Research & Development Fund. Its core purpose is to enable a community to propose, fund, validate, and reward innovative projects using a blend of advanced concepts: **Skill-Bound NFTs (SBNFTs) for reputation and access, dynamic milestone-based funding, an internal prediction market-like system for project validation, and adaptive DAO governance where voting power is influenced by contributions and earned reputation.**

The goal is to move beyond simple token-based DAOs or static crowdfunding, introducing mechanisms that incentivize long-term engagement, verified skill, and objective project assessment.

---

## Smart Contract Suite: Project Minerva

### I. Core Contracts Overview

1.  **`MinervaToken.sol`**:
    *   **Type**: ERC-20 Token.
    *   **Purpose**: The primary utility and governance token for the Project Minerva ecosystem. Used for staking, funding projects, challenging milestones, and earning rewards.
    *   **Key Feature**: Minting and burning capabilities are restricted to the `ProjectMinerva` contract (as its owner) to manage token supply for ecosystem rewards and penalties.

2.  **`MinervaSkillNFT.sol`**:
    *   **Type**: Non-transferable ERC-721 Token (Soulbound NFT-like).
    *   **Purpose**: Represents a contributor's skills, roles, and achievements within the platform (e.g., "Project Lead," "Accurate Auditor," "Milestone Achiever"). These NFTs are fundamental for building reputation.
    *   **Key Feature**: Non-transferable to ensure they are tied to the contributor's identity and cannot be traded. They influence voting power, access to roles (like auditors), and reward multipliers. Minting is restricted to the `ProjectMinerva` contract.

3.  **`ProjectMinerva.sol`**:
    *   **Type**: Main Logic Contract.
    *   **Purpose**: Orchestrates the entire ecosystem, managing project lifecycles, contributor profiles, DAO governance, funding mechanisms, and the milestone validation system.
    *   **Key Features**:
        *   **Dynamic Funding**: Projects are funded in phases, tied to milestone completion.
        *   **Reputation-Weighted Governance**: Voting power is a function of staked tokens, unstaked token balance, and the types/levels of Minerva Skill NFTs held.
        *   **Decentralized Milestone Validation**: A system where project leads submit milestones, which can be challenged by community members (requiring a stake). A pool of community-elected auditors reviews the challenge, and their collective verdict determines the outcome, influencing project progression and challenger/auditor rewards.
        *   **Contributor Rewards**: Complex reward distribution based on project success, impact score, and individual contribution shares, in addition to staking rewards.

### II. Function Summary (28 Functions)

**I. Core Setup & Administration**
1.  `constructor(address _tokenAddress, address _skillNFTAddress)`: Initializes the contract, links `MinervaToken` and `MinervaSkillNFT` addresses, and sets initial DAO parameters.
2.  `setCoreContractAddresses(address _newTokenAddress, address _newSkillNFTAddress)`: (Admin) Allows updating the addresses of `MinervaToken` and `MinervaSkillNFT`.
3.  `pauseContract()`: (Admin) Pauses critical contract functionalities in emergencies.
4.  `unpauseContract()`: (Admin) Unpauses contract functionalities.

**II. Contributor & Reputation Management**
5.  `registerContributor(string memory _name)`: Allows a new user to register a profile and automatically mints a "Generic Contributor" SBNFT.
6.  `updateContributorProfile(string memory _newName)`: Allows registered contributors to update their public display name.
7.  `mintSkillNFT(address _to, string memory _skillName, MinervaSkillNFT.SkillType _skillType, uint256 _level)`: (Internal) Mints a specific `MinervaSkillNFT` to a contributor and updates their reputation score.
8.  `getContributorReputation(address _contributor)`: Returns a contributor's calculated reputation score.

**III. Project Lifecycle Management**
9.  `proposeProject(string memory _title, string memory _description, uint256 _totalFundingGoal, address[] memory _contributorAddresses, uint256[] memory _contributorPercentages)`: Allows a lead to propose a new project, which creates a governance proposal for community approval.
10. `voteOnProjectProposal(uint256 _proposalId, bool _support)`: Allows contributors to vote on a project proposal (delegates to general governance voting).
11. `finalizeProjectProposal(uint256 _projectId, bool _approved)`: (Owner/DAO) Executes the outcome of a project proposal, setting its status to Approved or Rejected.
12. `requestMilestoneFunding(uint256 _projectId, string memory _description, uint256 _fundingAmount, uint256 _deadline)`: (Project Lead) Requests funding for a project milestone, creating a governance proposal for approval.
13. `approveMilestoneFunding(uint256 _milestoneId)`: (Owner/DAO) Approves and transfers funds for a milestone if its governance proposal passed.
14. `submitMilestoneCompletion(uint256 _milestoneId)`: (Project Lead) Declares a milestone completed, moving it to an "In Review" state.
15. `challengeMilestoneCompletion(uint256 _milestoneId)`: (Registered Contributor) Stakes MNV to challenge a claimed milestone completion, initiating an audit.
16. `resolveMilestoneChallenge(uint256 _challengeId, bool _milestoneSuccessful)`: (Owner/DAO) Resolves an active milestone challenge based on auditor reports/DAO verdict, distributing stakes and setting milestone status.

**IV. DAO Governance & Tokenomics**
17. `createGovernanceProposal(string memory _description, address _targetContract, bytes memory _callData)`: (Registered Contributor) Creates a new general DAO governance proposal (e.g., for parameter changes, contract upgrades).
18. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: (Registered Contributor) Allows voting on governance proposals with reputation-weighted power.
19. `getVotingPower(address _voter)`: Calculates the effective voting power of an address based on token balance, staked tokens, and SBNFTs.
20. `executeGovernanceProposal(uint256 _proposalId)`: (Owner/DAO) Executes a successful governance proposal after its voting period ends and quorum is met.
21. `stakeMinervaTokens(uint256 _amount)`: (Registered Contributor) Stakes MNV tokens to gain enhanced voting power and earn staking rewards.
22. `unstakeMinervaTokens(uint256 _amount)`: (Registered Contributor) Unstakes MNV tokens.
23. `claimStakingRewards()`: (Registered Contributor) Allows stakers to claim their accumulated MNV rewards.

**V. Auditor & Validation System**
24. `applyAsMilestoneAuditor(uint256 _milestoneId)`: (Registered Contributor) Stakes MNV to apply as an auditor for a specific milestone, earning an "Auditor" SBNFT.
25. `voteForMilestoneAuditors(uint256 _milestoneId, address[] memory _auditorCandidates, bool[] memory _votes)`: (Placeholder) This function would facilitate community voting for auditors but is simplified in this version (applicants are directly assigned).
26. `submitMilestoneAuditReport(uint256 _milestoneId, bool _success)`: (Assigned Auditor) Submits an audit report for a milestone, deeming it successful or failed.
27. `distributeAuditorRewards(uint256 _milestoneId, bool _milestoneWasSuccessful)`: (Internal) Distributes rewards to accurate auditors and refunds their stakes after a milestone resolution.

**VI. Project Impact & Reward Distribution**
28. `submitProjectFeedback(uint256 _projectId, string memory _feedback)`: (Registered Contributor) Allows community members to submit qualitative feedback, potentially influencing a project's impact score.
29. `updateProjectImpactScore(uint256 _projectId, uint256 _newScore)`: (Owner/DAO) Updates a project's impact score based on community feedback, success, and other metrics.
30. `completeProject(uint256 _projectId)`: (Project Lead) Marks a project as fully completed after all milestones are handled, triggering final reward distribution.
31. `distributeProjectCompletionRewards(uint256 _projectId)`: (Internal) Distributes final MNV rewards to project contributors based on their shares and the project's impact score.
32. `claimContributorRewards()`: (Registered Contributor) Allows individual contributors to claim their allocated project rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- MinervaToken.sol ---
// Represents the governance and utility token for the Project Minerva ecosystem.
// Standard ERC-20 with minting/burning capabilities restricted to the ProjectMinerva contract.
contract MinervaToken is ERC20, Ownable {
    constructor() ERC20("Minerva Token", "MNV") {
        // Initial supply for the contract deployer.
        // In a real scenario, this might be sent to the ProjectMinerva contract as initial DAO treasury.
        _mint(msg.sender, 100_000_000 * 10**decimals()); 
    }

    // Only ProjectMinerva contract (set as owner) can mint/burn tokens for internal mechanics (rewards, funding)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

// --- MinervaSkillNFT.sol ---
// Non-transferable ERC-721 tokens representing contributor skills, roles, and achievements.
// Used for weighted voting, access control, and enhanced reward distribution.
contract MinervaSkillNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Skill types for categorization (e.g., Developer, Auditor, Community Manager)
    enum SkillType { GenericContributor, Developer, Auditor, CommunityManager, ProjectLead, Validator }

    // Mapping to store skill-specific data (e.g., reputation points, level)
    mapping(uint256 => uint256) public skillLevels; // tokenId => level
    mapping(uint256 => string) public skillNames;   // tokenId => name
    // Mapping from tokenId to SkillType
    mapping(uint256 => SkillType) public skillTypeMap;

    constructor() ERC721("Minerva Skill NFT", "MSNFT") {}

    // Only the ProjectMinerva contract (set as owner) can mint these SBNFTs
    function mint(address to, string memory name, SkillType sType, uint256 level) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "Skill name cannot be empty");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        skillLevels[newTokenId] = level;
        skillNames[newTokenId] = name;
        skillTypeMap[newTokenId] = sType;
        // ERC721 mint event is emitted by _safeMint
        return newTokenId;
    }

    // Override _transfer to make tokens non-transferable (soulbound)
    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert("Minerva Skill NFTs are non-transferable (soulbound)");
    }

    // Optional: Allow burning by the owner (ProjectMinerva contract) or the token holder
    // if a skill becomes obsolete or if a contributor is banned.
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || owner() == _msgSender(), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    // Public getter for total supply of NFTs
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}


// --- ProjectMinerva.sol ---
// Main contract for the Decentralized Autonomous Research & Development Fund.
// Manages projects, contributors, governance, funding, and a unique reputation-based validation system.
contract ProjectMinerva is Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables & Core Contracts ---
    MinervaToken public minervaToken;
    MinervaSkillNFT public minervaSkillNFT;

    // Counters for unique IDs
    Counters.Counter private _projectIds;
    Counters.Counter private _milestoneIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _auditChallengeIds;

    // --- Structs ---

    // Represents a registered contributor in the Minerva ecosystem.
    struct Contributor {
        bool isRegistered;
        string name;
        address walletAddress;
        uint256 reputationScore; // Aggregate score based on SBNFTs, successful projects, etc.
        uint256[] ownedSkillNFTs; // List of SBNFT token IDs
    }
    mapping(address => Contributor) public contributors;

    // Represents a project proposed and managed by the DAO.
    enum ProjectStatus { Proposed, Approved, FundingMilestone, InProgress, MilestoneChallenged, Completed, Rejected, Archived }
    struct Project {
        uint256 projectId;
        address leadContributor;
        string title;
        string description;
        uint256 totalFundingGoal;
        uint256 currentFundedAmount;
        ProjectStatus status;
        uint256 createdAt;
        uint256 completedAt;
        uint256 impactScore; // Score based on community feedback, milestone success, external impact
        uint256[] milestones; // Array of milestone IDs
        address[] contributorList; // List of addresses of primary contributors (for iteration)
        mapping(address => uint256) contributorShares; // Specific shares for this project (0-10000 for 0-100%)
    }
    mapping(uint256 => Project) public projects;

    // Represents a specific milestone within a project.
    enum MilestoneStatus { Proposed, Approved, InReview, Challenged, Completed, Failed }
    struct Milestone {
        uint256 milestoneId;
        uint256 projectId;
        string description;
        uint256 fundingAmount; // Amount allocated for this milestone
        MilestoneStatus status;
        uint256 deadline;
        address[] assignedAuditors; // Selected auditors for this milestone
        mapping(address => bool) auditorSubmittedReport; // Track if auditor has submitted report
        mapping(address => bool) auditorVoteSuccess; // Auditor's vote: true for success, false for failure
        uint256 approvalTimestamp; // When the milestone was approved
        uint256 completionSubmissionTimestamp; // When completion was submitted
    }
    mapping(uint256 => Milestone) public milestones;

    // Represents a DAO governance proposal.
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        bytes callData; // Encoded function call for execution
        address targetContract; // Target contract for execution
        mapping(address => bool) hasVoted; // Tracks who has voted
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Represents a challenge against a claimed milestone completion.
    enum ChallengeStatus { Active, ResolvedSuccessful, ResolvedFailed, Refunded }
    struct AuditChallenge {
        uint256 challengeId;
        uint256 milestoneId;
        address challenger;
        uint256 stakedAmount; // Tokens staked by challenger
        ChallengeStatus status;
        uint256 creationTime;
        uint256 resolutionTime;
        bool challengerWon; // True if challenge was successful, false otherwise
    }
    mapping(uint256 => AuditChallenge) public auditChallenges;

    // --- DAO Parameters ---
    uint256 public proposalThreshold;           // Minimum MNV required to create a proposal
    uint256 public votingPeriod;                // Duration of voting in seconds
    uint256 public quorumThresholdPercent;      // Percentage of total MNV supply needed for a proposal to pass
    uint256 public minStakingAmount;            // Minimum MNV to stake for enhanced voting
    uint256 public milestoneChallengeStake;     // MNV required to challenge a milestone
    uint256 public auditorApplicationStake;     // MNV required to apply as an auditor
    uint256 public auditorRewardPoolRate;       // Percentage of milestone funding allocated to auditor reward pool

    // --- Staking ---
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastStakeTime; // For reward calculation
    mapping(address => uint256) public rewardsClaimable; // Accumulated rewards

    // --- Events ---
    event ContributorRegistered(address indexed contributorAddress, string name);
    event ProjectProposed(uint256 indexed projectId, address indexed lead, string title, uint256 totalFundingGoal);
    event ProjectProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProjectApproved(uint256 indexed projectId);
    event MilestoneProposed(uint256 indexed milestoneId, uint256 indexed projectId, uint256 fundingAmount, uint256 deadline);
    event MilestoneFundingApproved(uint256 indexed milestoneId, uint256 indexed projectId, uint256 amount);
    event MilestoneCompletionSubmitted(uint256 indexed milestoneId, uint256 indexed projectId);
    event MilestoneChallenged(uint256 indexed challengeId, uint256 indexed milestoneId, address indexed challenger, uint256 stakedAmount);
    event MilestoneChallengeResolved(uint256 indexed challengeId, uint256 indexed milestoneId, bool challengerWon, ChallengeStatus newStatus);
    event ProjectCompleted(uint256 indexed projectId, uint256 impactScore);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event SkillNFTMinted(address indexed to, uint256 indexed tokenId, string skillName);
    event AuditorApplied(uint256 indexed milestoneId, address indexed auditor);
    event AuditorReportSubmitted(uint256 indexed milestoneId, address indexed auditor, bool success);
    event AuditorRewardsDistributed(uint256 indexed milestoneId, address indexed auditor, uint256 amount);
    event ProjectFeedbackSubmitted(uint256 indexed projectId, address indexed submitter);
    event ProjectImpactScoreUpdated(uint256 indexed projectId, uint256 newScore);
    event ProjectRewardsDistributed(uint256 indexed projectId, address indexed contributor, uint256 amount);

    // --- Modifiers ---
    modifier onlyRegisteredContributor() {
        require(contributors[msg.sender].isRegistered, "Caller must be a registered contributor");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].leadContributor == msg.sender, "Caller must be the project lead");
        _;
    }

    modifier onlyAssignedAuditor(uint256 _milestoneId) {
        bool isAssigned = false;
        for (uint256 i = 0; i < milestones[_milestoneId].assignedAuditors.length; i++) {
            if (milestones[_milestoneId].assignedAuditors[i] == msg.sender) {
                isAssigned = true;
                break;
            }
        }
        require(isAssigned, "Caller is not an assigned auditor for this milestone");
        _;
    }

    // --- Constructor ---
    // @notice Deploys/links MinervaToken and MinervaSkillNFT, sets initial DAO parameters.
    // @param _tokenAddress The address of the MinervaToken contract (if pre-deployed).
    // @param _skillNFTAddress The address of the MinervaSkillNFT contract (if pre-deployed).
    constructor(address _tokenAddress, address _skillNFTAddress) {
        minervaToken = MinervaToken(_tokenAddress);
        minervaSkillNFT = MinervaSkillNFT(_skillNFTAddress);

        // Initial DAO Parameters (can be changed via governance proposals)
        proposalThreshold = 1000 * 10**minervaToken.decimals(); // 1000 MNV
        votingPeriod = 7 days; // 7 days for voting
        quorumThresholdPercent = 5; // 5% of total supply needed for quorum
        minStakingAmount = 100 * 10**minervaToken.decimals(); // 100 MNV
        milestoneChallengeStake = 50 * 10**minervaToken.decimals(); // 50 MNV
        auditorApplicationStake = 20 * 10**minervaToken.decimals(); // 20 MNV
        auditorRewardPoolRate = 5; // 5% of milestone funding for auditors
    }

    // --- I. Core Setup & Administration (4 functions) ---

    // @notice Allows the owner to update the addresses of core contracts.
    // @param _newTokenAddress New address for MinervaToken.
    // @param _newSkillNFTAddress New address for MinervaSkillNFT.
    function setCoreContractAddresses(address _newTokenAddress, address _newSkillNFTAddress) external onlyOwner {
        require(_newTokenAddress != address(0), "Invalid token address");
        require(_newSkillNFTAddress != address(0), "Invalid NFT address");
        minervaToken = MinervaToken(_newTokenAddress);
        minervaSkillNFT = MinervaSkillNFT(_newSkillNFTAddress);
    }

    // @notice Pauses contract functionality in emergencies.
    function pauseContract() external onlyOwner {
        _pause();
    }

    // @notice Unpauses contract functionality.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- II. Contributor & Reputation Management (4 functions) ---

    // @notice Allows a new user to register their profile.
    // @param _name The desired display name for the contributor.
    function registerContributor(string memory _name) external whenNotPaused {
        require(!contributors[msg.sender].isRegistered, "Contributor already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");

        contributors[msg.sender].isRegistered = true;
        contributors[msg.sender].name = _name;
        contributors[msg.sender].walletAddress = msg.sender;
        contributors[msg.sender].reputationScore = 0; // Initial reputation
        
        // Mint a generic "Contributor" SBNFT upon registration
        // (Owner of MinervaSkillNFT must be this contract, or owner call needs to be from MinervaSkillNFT)
        // Here, we assume this contract is the owner of MinervaSkillNFT and can call its mint function.
        minervaSkillNFT.mint(msg.sender, "Generic Contributor", MinervaSkillNFT.SkillType.GenericContributor, 1);
        contributors[msg.sender].ownedSkillNFTs.push(minervaSkillNFT.totalSupply()); // Get the last minted ID

        emit ContributorRegistered(msg.sender, _name);
    }

    // @notice Allows registered contributors to update their public profile details.
    // @param _newName The new desired display name.
    function updateContributorProfile(string memory _newName) external onlyRegisteredContributor whenNotPaused {
        require(bytes(_newName).length > 0, "Name cannot be empty");
        contributors[msg.sender].name = _newName;
        // No event for simple name update to save gas, can be added if crucial
    }

    // @notice Mints a specific MinervaSkillNFT to a contributor based on a validated achievement.
    // This function will be called internally when certain achievements are met (e.g., project completion, successful audits).
    // @param _to The address to mint the SBNFT to.
    // @param _skillName The name of the skill/achievement.
    // @param _skillType The type of skill (from MinervaSkillNFT.SkillType enum).
    // @param _level The level of the skill.
    function mintSkillNFT(address _to, string memory _skillName, MinervaSkillNFT.SkillType _skillType, uint256 _level) internal {
        require(contributors[_to].isRegistered, "Recipient must be a registered contributor");
        minervaSkillNFT.mint(_to, _skillName, _skillType, _level);
        contributors[_to].ownedSkillNFTs.push(minervaSkillNFT.totalSupply()); // Get the last minted ID
        // Update reputation score based on new NFT (example: simple addition)
        contributors[_to].reputationScore = contributors[_to].reputationScore.add(_level.mul(10)); // Example: level * 10 points
        emit SkillNFTMinted(_to, minervaSkillNFT.totalSupply(), _skillName);
    }

    // @notice Calculates a contributor's weighted reputation score.
    // This is a simple example; actual implementation could be more complex (e.g., decay, specific weights per skill type).
    // @param _contributor The address of the contributor.
    // @return The calculated reputation score.
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributors[_contributor].reputationScore;
    }

    // --- III. Project Lifecycle Management (8 functions) ---

    // @notice Allows a registered contributor to submit a new project proposal to the DAO.
    // @param _title Project title.
    // @param _description Project description.
    // @param _totalFundingGoal Total MNV required for the project.
    // @param _contributorAddresses Array of addresses of primary contributors.
    // @param _contributorPercentages Array of corresponding percentage shares (0-10000 for 0-100%).
    function proposeProject(
        string memory _title,
        string memory _description,
        uint256 _totalFundingGoal,
        address[] memory _contributorAddresses,
        uint256[] memory _contributorPercentages
    ) external onlyRegisteredContributor whenNotPaused {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_totalFundingGoal > 0, "Funding goal must be greater than zero");
        require(_contributorAddresses.length == _contributorPercentages.length, "Contributor arrays length mismatch");
        
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _contributorPercentages.length; i++) {
            require(contributors[_contributorAddresses[i]].isRegistered, "All contributors must be registered");
            totalPercentage = totalPercentage.add(_contributorPercentages[i]);
        }
        require(totalPercentage == 10000, "Contributor percentages must sum to 100%");

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        projects[newProjectId].projectId = newProjectId;
        projects[newProjectId].leadContributor = msg.sender;
        projects[newProjectId].title = _title;
        projects[newProjectId].description = _description;
        projects[newProjectId].totalFundingGoal = _totalFundingGoal;
        projects[newProjectId].status = ProjectStatus.Proposed;
        projects[newProjectId].createdAt = block.timestamp;
        projects[newProjectId].impactScore = 0; // Initial impact score
        projects[newProjectId].contributorList = _contributorAddresses; // Store for easy iteration

        for (uint256 i = 0; i < _contributorAddresses.length; i++) {
            projects[newProjectId].contributorShares[_contributorAddresses[i]] = _contributorPercentages[i];
        }

        // Create a governance proposal for the project (DAO needs to approve project creation)
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        bytes memory proposalCallData = abi.encodeWithSelector(this.finalizeProjectProposal.selector, newProjectId, true); // Assume success for now
        
        governanceProposals[newProposalId] = GovernanceProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Approve new project: ", _title, " (ID: ", Strings.toString(newProjectId), ")")),
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(votingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            callData: proposalCallData,
            targetContract: address(this),
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ProjectProposed(newProjectId, msg.sender, _title, _totalFundingGoal);
        emit GovernanceProposalCreated(newProposalId, msg.sender, governanceProposals[newProposalId].description);
    }

    // @notice Community members vote on a submitted project proposal (indirectly via a governance proposal).
    // @param _proposalId The ID of the governance proposal for the project.
    // @param _support True if voting "for", false if voting "against".
    function voteOnProjectProposal(uint256 _proposalId, bool _support) external onlyRegisteredContributor whenNotPaused {
        _voteOnGovernanceProposal(_proposalId, _support); // Delegate to general governance voting
    }

    // @notice Executes the outcome of a project proposal vote.
    // This function is intended to be called by a successful governance proposal (executed by owner).
    // @param _projectId The ID of the project to finalize.
    // @param _approved True if the project is approved, false if rejected.
    function finalizeProjectProposal(uint256 _projectId, bool _approved) public onlyOwner whenNotPaused { // Owner for direct call by governance
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "Project not in proposed status");
        if (_approved) {
            project.status = ProjectStatus.Approved;
            emit ProjectApproved(_projectId);
        } else {
            project.status = ProjectStatus.Rejected;
            // Optionally, refund project proposal fee if any
        }
    }

    // @notice Project lead requests funding for the next project milestone.
    // This creates a milestone struct, but funding is only transferred after DAO approval.
    // @param _projectId The ID of the project.
    // @param _description Description of the milestone.
    // @param _fundingAmount The amount of MNV requested for this milestone.
    // @param _deadline Timestamp by which the milestone is expected to be completed.
    function requestMilestoneFunding(
        uint256 _projectId,
        string memory _description,
        uint256 _fundingAmount,
        uint256 _deadline
    ) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "Project not in approved or in-progress status");
        require(bytes(_description).length > 0, "Milestone description cannot be empty");
        require(_fundingAmount > 0, "Funding amount must be greater than zero");
        require(_deadline > block.timestamp, "Milestone deadline must be in the future");
        require(project.currentFundedAmount.add(_fundingAmount) <= project.totalFundingGoal, "Funding exceeds total project goal");

        _milestoneIds.increment();
        uint256 newMilestoneId = _milestoneIds.current();

        milestones[newMilestoneId] = Milestone({
            milestoneId: newMilestoneId,
            projectId: _projectId,
            description: _description,
            fundingAmount: _fundingAmount,
            status: MilestoneStatus.Proposed,
            deadline: _deadline,
            assignedAuditors: new address[](0),
            auditorSubmittedReport: new mapping(address => bool),
            auditorVoteSuccess: new mapping(address => bool),
            approvalTimestamp: 0,
            completionSubmissionTimestamp: 0
        });
        project.milestones.push(newMilestoneId);

        // Create a governance proposal for milestone funding approval
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        bytes memory proposalCallData = abi.encodeWithSelector(this.approveMilestoneFunding.selector, newMilestoneId);
        
        governanceProposals[newProposalId] = GovernanceProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Approve funding for milestone ID ", Strings.toString(newMilestoneId), " of project ID ", Strings.toString(_projectId))),
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(votingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            callData: proposalCallData,
            targetContract: address(this),
            hasVoted: new mapping(address => bool)
        });

        emit MilestoneProposed(newMilestoneId, _projectId, _fundingAmount, _deadline);
        emit GovernanceProposalCreated(newProposalId, msg.sender, governanceProposals[newProposalId].description);
    }

    // @notice DAO/Admin approves and allocates funds for a requested milestone.
    // This function is intended to be called by a successful governance proposal.
    // @param _milestoneId The ID of the milestone to fund.
    function approveMilestoneFunding(uint256 _milestoneId) public onlyOwner whenNotPaused { // Owner for direct call by governance
        Milestone storage milestone = milestones[_milestoneId];
        Project storage project = projects[milestone.projectId];

        require(milestone.status == MilestoneStatus.Proposed, "Milestone not in proposed status");
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "Project not approved or in progress");

        // Transfer funds from DAO treasury (this contract) to project lead
        require(minervaToken.transfer(project.leadContributor, milestone.fundingAmount), "Token transfer failed for milestone funding");

        project.currentFundedAmount = project.currentFundedAmount.add(milestone.fundingAmount);
        milestone.status = MilestoneStatus.Approved;
        milestone.approvalTimestamp = block.timestamp;
        project.status = ProjectStatus.InProgress; // Mark project as in progress

        emit MilestoneFundingApproved(_milestoneId, milestone.projectId, milestone.fundingAmount);
    }

    // @notice Project lead declares a milestone as completed, initiating the validation phase.
    // @param _milestoneId The ID of the milestone claimed completed.
    function submitMilestoneCompletion(uint256 _milestoneId) external onlyProjectLead(milestones[_milestoneId].projectId) whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.Approved, "Milestone not in approved state for completion submission");
        require(block.timestamp <= milestone.deadline.add(1 days), "Milestone deadline passed (grace period of 1 day)"); // Allow slight delay
        
        milestone.status = MilestoneStatus.InReview;
        milestone.completionSubmissionTimestamp = block.timestamp;

        // This would ideally trigger a period for `applyAsMilestoneAuditor` and `voteForMilestoneAuditors`.
        // For this example, let's simplify and assume the `InReview` status is when auditors can apply/submit reports.
        
        emit MilestoneCompletionSubmitted(_milestoneId, milestone.projectId);
    }

    // @notice Community members can stake tokens to challenge a claimed milestone completion.
    // This initiates an audit challenge.
    // @param _milestoneId The ID of the milestone being challenged.
    function challengeMilestoneCompletion(uint256 _milestoneId) external onlyRegisteredContributor whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.InReview, "Milestone not in 'InReview' status for challenging");
        require(minervaToken.balanceOf(msg.sender) >= milestoneChallengeStake, "Insufficient MNV to challenge");
        
        // Transfer stake from challenger to this contract
        require(minervaToken.transferFrom(msg.sender, address(this), milestoneChallengeStake), "MNV transfer failed for challenge stake");

        _auditChallengeIds.increment();
        uint256 newChallengeId = _auditChallengeIds.current();

        auditChallenges[newChallengeId] = AuditChallenge({
            challengeId: newChallengeId,
            milestoneId: _milestoneId,
            challenger: msg.sender,
            stakedAmount: milestoneChallengeStake,
            status: ChallengeStatus.Active,
            creationTime: block.timestamp,
            resolutionTime: 0,
            challengerWon: false
        });

        milestone.status = MilestoneStatus.Challenged;
        projects[milestone.projectId].status = ProjectStatus.MilestoneChallenged;

        emit MilestoneChallenged(newChallengeId, _milestoneId, msg.sender, milestoneChallengeStake);
    }

    // @notice Designated auditors/DAO resolve a challenged milestone, determining success/failure.
    // This function is intended to be called by the DAO (via owner) after all audit reports are in.
    // @param _challengeId The ID of the audit challenge.
    // @param _milestoneSuccessful True if the milestone is deemed successful, false otherwise.
    function resolveMilestoneChallenge(uint256 _challengeId, bool _milestoneSuccessful) public onlyOwner whenNotPaused { // Owner acts as final DAO decision
        AuditChallenge storage challenge = auditChallenges[_challengeId];
        Milestone storage milestone = milestones[challenge.milestoneId];
        Project storage project = projects[milestone.projectId];

        require(challenge.status == ChallengeStatus.Active, "Challenge not active");
        require(milestone.status == MilestoneStatus.Challenged, "Milestone not in challenged status");

        challenge.resolutionTime = block.timestamp;
        
        if (_milestoneSuccessful) {
            // Milestone successful: Challenger loses stake, milestone completed
            challenge.challengerWon = false;
            challenge.status = ChallengeStatus.ResolvedFailed; // Challenger failed to prove failure
            milestone.status = MilestoneStatus.Completed;
            project.status = ProjectStatus.InProgress; // Resume project
            
            // Burn challenger's stake (or add to DAO treasury/auditor pool)
            minervaToken.burn(address(this), challenge.stakedAmount); // Burn for deflationary pressure

        } else {
            // Milestone failed: Challenger wins, milestone status set to failed
            challenge.challengerWon = true;
            challenge.status = ChallengeStatus.ResolvedSuccessful;
            milestone.status = MilestoneStatus.Failed;
            project.status = ProjectStatus.InProgress; // Project can propose a new milestone or be archived

            // Refund challenger's stake
            require(minervaToken.transfer(challenge.challenger, challenge.stakedAmount), "Refund to challenger failed");
        }

        // If milestone succeeded, mint "Milestone Achiever" SBNFT for project lead
        if (_milestoneSuccessful) {
            mintSkillNFT(project.leadContributor, "Milestone Achiever", MinervaSkillNFT.SkillType.ProjectLead, 1);
        }

        emit MilestoneChallengeResolved(_challengeId, challenge.milestoneId, challenge.challengerWon, challenge.status);
        emit ProjectImpactScoreUpdated(project.projectId, project.impactScore); // Impact score might change
        
        // After resolving, also distribute auditor rewards based on whether they were correct
        distributeAuditorRewards(milestone.milestoneId, _milestoneSuccessful);
    }


    // --- IV. DAO Governance & Tokenomics (6 functions) ---

    // @notice Creates a new governance proposal for contract upgrades, parameter changes, etc.
    // @param _description A description of the proposal.
    // @param _targetContract The address of the contract to call if the proposal passes.
    // @param _callData The encoded function call (e.g., abi.encodeWithSelector(ERC20.transfer.selector, ...)).
    function createGovernanceProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external onlyRegisteredContributor whenNotPaused {
        require(minervaToken.balanceOf(msg.sender) >= proposalThreshold, "Insufficient MNV to create proposal");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(votingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            callData: _callData,
            targetContract: _targetContract,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit GovernanceProposalCreated(newProposalId, msg.sender, _description);
    }

    // @notice Allows community members to vote on a governance proposal.
    // Voting power is based on staked tokens and SBNFT reputation.
    // @param _proposalId The ID of the proposal to vote on.
    // @param _support True for "for" vote, false for "against".
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyRegisteredContributor whenNotPaused {
        _voteOnGovernanceProposal(_proposalId, _support);
    }

    // Internal helper for voting logic
    function _voteOnGovernanceProposal(uint256 _proposalId, bool _support) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "Caller has no voting power");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    // @notice Calculates the voting power of an address.
    // @param _voter The address of the voter.
    // @return The calculated voting power.
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 baseVotingPower = minervaToken.balanceOf(_voter); // Unstaked tokens
        uint256 stakedVotingPower = stakedBalances[_voter].mul(150).div(100); // Staked tokens get 1.5x multiplier
        
        uint256 reputationMultiplier = 100; // Base 100%
        // Add multipliers based on SBNFTs
        for (uint256 i = 0; i < contributors[_voter].ownedSkillNFTs.length; i++) {
            uint256 tokenId = contributors[_voter].ownedSkillNFTs[i];
            MinervaSkillNFT.SkillType sType = minervaSkillNFT.skillTypeMap(tokenId);
            uint256 level = minervaSkillNFT.skillLevels(tokenId);

            if (sType == MinervaSkillNFT.SkillType.Developer || sType == MinervaSkillNFT.SkillType.ProjectLead) {
                reputationMultiplier = reputationMultiplier.add(level.mul(5)); // +5% per level for project-related roles
            } else if (sType == MinervaSkillNFT.SkillType.Auditor) {
                reputationMultiplier = reputationMultiplier.add(level.mul(8)); // +8% per level for auditors
            }
            // Generic contributor gets a small bump
            else if (sType == MinervaSkillNFT.SkillType.GenericContributor) {
                reputationMultiplier = reputationMultiplier.add(level.mul(1)); // +1% per level
            }
        }
        
        uint256 totalPower = baseVotingPower.add(stakedVotingPower);
        return totalPower.mul(reputationMultiplier).div(100);
    }

    // @notice Executes a successful governance proposal.
    // Only callable by the owner, who acts as the DAO's executor.
    // @param _proposalId The ID of the proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalTokenSupply = minervaToken.totalSupply();
        uint256 requiredQuorum = totalTokenSupply.mul(quorumThresholdPercent).div(100);

        require(totalVotes >= requiredQuorum, "Quorum not reached");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposal's intended action
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.status = ProposalStatus.Executed;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    // @notice Allows users to stake MinervaTokens for enhanced voting power and potential rewards.
    // @param _amount The amount of MNV to stake.
    function stakeMinervaTokens(uint256 _amount) external onlyRegisteredContributor whenNotPaused {
        require(_amount >= minStakingAmount, "Amount must meet minimum staking requirement");
        require(minervaToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for staking");

        if (stakedBalances[msg.sender] == 0) {
            lastStakeTime[msg.sender] = block.timestamp;
        }
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(_amount);
        // Reward calculation based on time and amount can be integrated here or in claim
        
        emit TokensStaked(msg.sender, _amount);
    }

    // @notice Allows users to unstake their MinervaTokens.
    // @param _amount The amount of MNV to unstake.
    function unstakeMinervaTokens(uint256 _amount) external onlyRegisteredContributor whenNotPaused {
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked balance");
        
        // Calculate and add current rewards to claimable before reducing stake
        _updateStakingRewards(msg.sender);

        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(_amount);
        lastStakeTime[msg.sender] = block.timestamp; // Reset last stake time for remaining balance
        
        require(minervaToken.transfer(msg.sender, _amount), "Token transfer failed for unstaking");
        
        emit TokensUnstaked(msg.sender, _amount);
    }

    // @notice Internal function to update a user's claimable staking rewards.
    function _updateStakingRewards(address _user) internal {
        if (stakedBalances[_user] > 0 && lastStakeTime[_user] < block.timestamp) {
            uint256 timeElapsed = block.timestamp.sub(lastStakeTime[_user]);
            // Example: 1% APY on staked balance (simplified for solidity)
            // (stakedAmount * timeElapsed * rewardRate) / (SECONDS_PER_YEAR * 100)
            uint256 annualRewardRate = 1; // 1%
            uint256 SECONDS_PER_YEAR = 31536000; // Approx seconds in a year

            uint256 newRewards = stakedBalances[_user].mul(annualRewardRate).mul(timeElapsed).div(SECONDS_PER_YEAR.mul(100));
            rewardsClaimable[_user] = rewardsClaimable[_user].add(newRewards);
            lastStakeTime[_user] = block.timestamp;
        }
    }

    // @notice Allows stakers to claim their accumulated rewards.
    function claimStakingRewards() external onlyRegisteredContributor whenNotPaused {
        _updateStakingRewards(msg.sender); // Ensure rewards are up-to-date
        uint256 amount = rewardsClaimable[msg.sender];
        require(amount > 0, "No rewards to claim");

        rewardsClaimable[msg.sender] = 0;
        // This contract holds a pool of MNV to distribute.
        require(minervaToken.transfer(msg.sender, amount), "Claim rewards transfer failed");

        emit RewardsClaimed(msg.sender, amount);
    }

    // --- V. Auditor & Validation System (4 functions) ---

    // @notice Allows registered contributors to apply to audit a specific project milestone.
    // @param _milestoneId The ID of the milestone to audit.
    function applyAsMilestoneAuditor(uint256 _milestoneId) external onlyRegisteredContributor whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.InReview, "Milestone not open for auditor applications");
        require(minervaToken.balanceOf(msg.sender) >= auditorApplicationStake, "Insufficient MNV to apply as auditor");

        // Ensure not already applied
        for(uint i=0; i < milestone.assignedAuditors.length; i++) {
            require(milestone.assignedAuditors[i] != msg.sender, "Already applied as auditor for this milestone");
        }

        // Transfer stake to contract as commitment
        require(minervaToken.transferFrom(msg.sender, address(this), auditorApplicationStake), "MNV transfer failed for auditor stake");
        
        milestone.assignedAuditors.push(msg.sender); // Add to potential auditors for now.
        // Grant Auditor SBNFT upon application (can be changed to only on selection)
        mintSkillNFT(msg.sender, "Milestone Auditor", MinervaSkillNFT.SkillType.Auditor, 1); 
        
        emit AuditorApplied(_milestoneId, msg.sender);
    }

    // @notice Community members vote on candidates for milestone auditor roles.
    // This function is a placeholder for a more complex selection process.
    // For simplicity in this example, `applyAsMilestoneAuditor` directly makes them auditors.
    // In a real system, this would involve a temporary proposal or a smaller-scale voting mechanism.
    function voteForMilestoneAuditors(uint256 _milestoneId, address[] memory _auditorCandidates, bool[] memory _votes) external pure {
        revert("Auditor voting not fully implemented in this version (simplified to direct application)");
    }

    // @notice Selected auditors submit their official assessment for a milestone.
    // @param _milestoneId The ID of the milestone.
    // @param _success True if the auditor deems the milestone successful, false otherwise.
    function submitMilestoneAuditReport(uint256 _milestoneId, bool _success) external onlyAssignedAuditor(_milestoneId) whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.InReview || milestone.status == MilestoneStatus.Challenged, "Milestone not in review or challenged state");
        require(!milestone.auditorSubmittedReport[msg.sender], "Auditor already submitted a report for this milestone");

        milestone.auditorSubmittedReport[msg.sender] = true;
        milestone.auditorVoteSuccess[msg.sender] = _success;

        // After all auditors submit, or a quorum is reached, resolve the milestone.
        _tryResolveMilestone(_milestoneId);

        emit AuditorReportSubmitted(_milestoneId, msg.sender, _success);
    }

    // Internal function to attempt resolving a milestone after auditor reports.
    function _tryResolveMilestone(uint256 _milestoneId) internal {
        Milestone storage milestone = milestones[_milestoneId];
        uint256 successVotes = 0;
        uint256 failureVotes = 0;
        uint256 reportsCount = 0;

        for (uint256 i = 0; i < milestone.assignedAuditors.length; i++) {
            address auditor = milestone.assignedAuditors[i];
            if (milestone.auditorSubmittedReport[auditor]) {
                reportsCount++;
                if (milestone.auditorVoteSuccess[auditor]) {
                    successVotes++;
                } else {
                    failureVotes++;
                }
            }
        }

        // If a majority of auditors have reported (e.g., >50%), resolve
        if (reportsCount > 0 && (successVotes > reportsCount.div(2) || failureVotes > reportsCount.div(2))) {
            bool milestoneSuccessful = successVotes > failureVotes;
            
            // If the milestone was challenged, its resolution happens through `resolveMilestoneChallenge`
            // and auditors' verdict is passed there.
            if (milestone.status == MilestoneStatus.InReview) {
                if (milestoneSuccessful) {
                    milestone.status = MilestoneStatus.Completed;
                    mintSkillNFT(projects[milestone.projectId].leadContributor, "Milestone Achiever", MinervaSkillNFT.SkillType.ProjectLead, 1);
                } else {
                    milestone.status = MilestoneStatus.Failed;
                }
                // Distribute rewards here if not challenged, or if challenged, it's done by resolveMilestoneChallenge
                distributeAuditorRewards(_milestoneId, milestoneSuccessful);
            } else if (milestone.status == MilestoneStatus.Challenged) {
                // If challenged, the auditors' verdict determines the outcome of the challenge.
                // Call resolveMilestoneChallenge to finalize. This should ideally be called by DAO (owner).
                uint256 challengeId = 0; // Find the active challenge
                for (uint256 i = 1; i <= _auditChallengeIds.current(); i++) {
                    if (auditChallenges[i].milestoneId == _milestoneId && auditChallenges[i].status == ChallengeStatus.Active) {
                        challengeId = i;
                        break;
                    }
                }
                require(challengeId != 0, "No active challenge found for this milestone");
                // The `resolveMilestoneChallenge` function will also call `distributeAuditorRewards`.
                // Owner (DAO) needs to call this final step.
                // For direct contract integration, a `onlyOwner` modifier for resolveMilestoneChallenge means
                // a DAO execute function would eventually trigger this.
                // For now, it's a manual step for the owner after auditors submit reports.
            }
        }
    }


    // @notice Distributes rewards to successful auditors and penalizes poor ones.
    // This is called automatically after a milestone is resolved by `_tryResolveMilestone` or `resolveMilestoneChallenge`.
    // @param _milestoneId The ID of the milestone.
    // @param _milestoneWasSuccessful The final verdict of the milestone.
    function distributeAuditorRewards(uint256 _milestoneId, bool _milestoneWasSuccessful) internal {
        Milestone storage milestone = milestones[_milestoneId];
        uint256 rewardPool = milestone.fundingAmount.mul(auditorRewardPoolRate).div(100); // e.g., 5% of milestone funding
        uint256 successfulAuditorsCount = 0;
        address[] memory correctAuditors = new address[](milestone.assignedAuditors.length);
        uint256 correctAuditorsIndex = 0;

        // First, return stakes and identify correct auditors
        for (uint256 i = 0; i < milestone.assignedAuditors.length; i++) {
            address auditor = milestone.assignedAuditors[i];
            
            // Refund initial stake regardless of outcome
            require(minervaToken.transfer(auditor, auditorApplicationStake), "Auditor stake refund failed");

            if (milestone.auditorSubmittedReport[auditor] && milestone.auditorVoteSuccess[auditor] == _milestoneWasSuccessful) {
                correctAuditors[correctAuditorsIndex] = auditor;
                correctAuditorsIndex++;
                successfulAuditorsCount++;
                mintSkillNFT(auditor, "Accurate Auditor", MinervaSkillNFT.SkillType.Auditor, 1); // Reward with SBNFT
            } else {
                // Penalize incorrect or non-reporting auditors by having them not receive a share of the reward pool.
                // A more complex system might burn a portion of their stake.
            }
        }
        
        // Distribute rewards from the pool
        if (successfulAuditorsCount > 0 && rewardPool > 0) {
            uint256 rewardPerAuditor = rewardPool.div(successfulAuditorsCount);
            for (uint256 i = 0; i < correctAuditorsIndex; i++) {
                address auditor = correctAuditors[i];
                if (auditor != address(0)) { // Check for valid address
                    require(minervaToken.transfer(auditor, rewardPerAuditor), "Auditor reward transfer failed");
                    emit AuditorRewardsDistributed(_milestoneId, auditor, rewardPerAuditor);
                }
            }
        }
    }


    // --- VI. Project Impact & Reward Distribution (4 functions) ---

    // @notice Allows community members to submit qualitative feedback on projects.
    // This feedback can influence the project's impact score.
    // @param _projectId The ID of the project.
    // @param _feedback A string containing the feedback.
    function submitProjectFeedback(uint256 _projectId, string memory _feedback) external onlyRegisteredContributor whenNotPaused {
        require(projects[_projectId].projectId != 0, "Project does not exist");
        require(bytes(_feedback).length > 0, "Feedback cannot be empty");
        // Store feedback (e.g., in IPFS hash, or simplified on-chain just for event)
        // This function primarily serves to signal community engagement.
        emit ProjectFeedbackSubmitted(_projectId, msg.sender);
    }

    // @notice Admin/DAO function to update a project's objective impact score.
    // This score is crucial for future funding decisions and contributor rewards.
    // @param _projectId The ID of the project.
    // @param _newScore The new impact score.
    function updateProjectImpactScore(uint256 _projectId, uint256 _newScore) external onlyOwner whenNotPaused { // Callable by DAO via governance
        require(projects[_projectId].projectId != 0, "Project does not exist");
        require(_newScore <= 1000, "Impact score must be between 0 and 1000"); // Example scale (0-1000)

        projects[_projectId].impactScore = _newScore;
        emit ProjectImpactScoreUpdated(_projectId, _newScore);
    }

    // @notice Finalizes a project and distributes remaining rewards to project contributors.
    // This should be triggered after all milestones are completed and the project has generated impact.
    // @param _projectId The ID of the project to finalize.
    function completeProject(uint256 _projectId) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Completed, "Project already completed");
        
        // Check if all milestones are completed/failed appropriately
        bool allMilestonesHandled = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            Milestone storage milestone = milestones[project.milestones[i]];
            if (milestone.status != MilestoneStatus.Completed && milestone.status != MilestoneStatus.Failed) {
                allMilestonesHandled = false;
                break;
            }
        }
        require(allMilestonesHandled, "Not all project milestones have been completed or failed.");

        project.status = ProjectStatus.Completed;
        project.completedAt = block.timestamp;

        // Distribute final rewards based on total funding goal, impact score, and contributor shares
        _distributeProjectCompletionRewards(_projectId);
        
        // Mint a "Project Completer" SBNFT to the lead
        mintSkillNFT(project.leadContributor, "Project Completer", MinervaSkillNFT.SkillType.ProjectLead, project.impactScore.div(100)); // Level based on impact (max 10 for score 1000)

        emit ProjectCompleted(_projectId, project.impactScore);
    }

    // @notice Distributes final rewards to project contributors upon successful project completion.
    // This is called internally by `completeProject`.
    // @param _projectId The ID of the completed project.
    function _distributeProjectCompletionRewards(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed, "Project not in completed status");

        uint256 totalRewardPool = project.totalFundingGoal; // Example: Final rewards are based on initial funding goal
        // Additional rewards can come from a separate DAO treasury based on project impact
        
        // Hypothetical additional reward from DAO treasury for high impact projects
        uint256 impactBonus = project.impactScore.mul(totalRewardPool).div(1000); // Max 100% bonus for score 1000
        totalRewardPool = totalRewardPool.add(impactBonus);

        for (uint256 i = 0; i < project.contributorList.length; i++) {
            address contributorAddr = project.contributorList[i];
            uint256 sharePercentage = project.contributorShares[contributorAddr];
            uint256 individualReward = totalRewardPool.mul(sharePercentage).div(10000); // sharePercentage is 0-10000

            // Fund goes to a claimable pool for the contributor.
            rewardsClaimable[contributorAddr] = rewardsClaimable[contributorAddr].add(individualReward);
            emit ProjectRewardsDistributed(_projectId, contributorAddr, individualReward);
        }
    }

    // @notice Allows individual contributors to claim their allocated project rewards.
    function claimContributorRewards() external onlyRegisteredContributor whenNotPaused {
        uint256 amount = rewardsClaimable[msg.sender];
        require(amount > 0, "No project rewards to claim");

        rewardsClaimable[msg.sender] = 0;
        require(minervaToken.transfer(msg.sender, amount), "Claim contributor rewards failed");

        emit RewardsClaimed(msg.sender, amount); // Re-use general rewards claimed event for simplicity
    }
}
```