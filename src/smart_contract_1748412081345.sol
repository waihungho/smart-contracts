Okay, let's design a smart contract for a Decentralized Autonomous Research Guild (DARG). This contract will combine elements of DAO governance, project funding, reputation systems, and intellectual property tokenization.

It's crucial to state that while this contract introduces a *unique combination* of features and a specific application logic (Decentralized Research), it *will* rely on standard interfaces and common patterns (like Ownable, ReentrancyGuard, ERC20/ERC721 interaction) because those are fundamental building blocks in Solidity. The "don't duplicate open source" rule is interpreted as not cloning an *entire existing project* (like a specific DAO framework or a specific staking contract), but rather building a novel system using standard tools and custom logic.

**Concept:**

The Decentralized Autonomous Research Guild (DARG) is a protocol for funding, managing, and validating scientific or technical research in a decentralized manner. Researchers (members) can propose projects, secure funding through the DARG token ($DRG), collaborate, report milestones, and register the intellectual property (IP) resulting from their work. Governance ($DRG token holders or staked $DRG holders) votes on project proposals, funding allocation, researcher admission, and protocol parameter changes. A reputation system tracks researcher contributions and success.

**Advanced Concepts Included:**

1.  **Reputation System:** An on-chain score for researchers, influenced by successful project completion, milestone delivery, peer reviews (simulated), and governance participation.
2.  **Project Lifecycle Management:** Structured states for research projects (Proposed, Funded, Active, Milestone Review, Completed, Cancelled).
3.  **Milestone-Based Funding/Validation:** Projects define milestones. Funds/Reputation unlocked upon milestone verification (simulated by governance/peer review vote).
4.  **Intellectual Property (IP) Tokenization:** Ability to register hashes of research outputs/data and mint NFTs representing ownership or licensing rights to that IP, linked back to the project.
5.  **Staking for Governance Power & Rewards:** Staking $DRG tokens grants voting power and accrues potential rewards (e.g., from protocol fees or inflation - simplified here to a basic share pool concept).
6.  **Liquid Governance Delegation:** Token holders can delegate their voting power.
7.  **Dynamic Governance Parameters:** Key protocol settings (quorum, voting period, required reputation) can be adjusted via governance proposals.
8.  **Grant System:** Separate from project funding, allowing proposals for infrastructure, community building, etc.
9.  **Role-Based Access Control (Simple):** Researchers, Project Leads, Governance roles.

---

**Outline and Function Summary**

**Contract Name:** `DecentralizedAutonomousResearchGuild`

**Dependencies:**
*   `Ownable` (from OpenZeppelin - for initial admin, though ownership will likely transition to governance)
*   `ReentrancyGuard` (from OpenZeppelin - for security on token transfers)
*   Interfaces for `IDARGToken` (ERC20) and `IIPNFT` (ERC721/ERC1155)

**State Variables:**
*   Contract addresses (`dargToken`, `ipNFT`)
*   Counters for Projects, Proposals, Grants
*   Mappings for Researchers (`address => Researcher`)
*   Mappings for Projects (`uint256 => Project`)
*   Mappings for Governance Proposals (`uint256 => Proposal`)
*   Mappings for Grant Proposals (`uint256 => Grant`)
*   Mapping for Staked Tokens (`address => uint256`)
*   Mapping for Governance Delegates (`address => address`)
*   Mapping for Voter's used votes per proposal (`uint256 => address => bool`)
*   Mapping for IP Hash registration (`bytes32 => IPDetails`)
*   Governance Parameters (e.g., `minVotingPeriod`, `quorumThreshold`, `projectFundingThreshold`, `minReputationForProposal`)
*   Pause status (`paused`)

**Enums:**
*   `ProjectStatus` (Proposed, Funded, Active, MilestoneReview, Completed, Cancelled)
*   `ProposalType` (GovernanceParameter, NewResearcher, RemoveResearcher, ProjectApproval, GrantApproval)
*   `ProposalStatus` (Pending, Active, Succeeded, Failed, Executed)
*   `GrantStatus` (Proposed, Active, Succeeded, Failed, Executed)

**Structs:**
*   `Researcher`: Stores address, reputation score, isResearcher flag, active project IDs.
*   `Project`: Stores details like title, lead researcher, status, funding goal, current funding, allocated funding, milestones (hashes), funding distribution plan, IP hashes.
*   `Milestone`: Stores hash of work, verification status, votes.
*   `Proposal`: Stores type, target data (param ID, address, project ID, etc.), proposal details, votes (for/against), state, expiry.
*   `Grant`: Stores details, requested amount, votes, state, expiry.
*   `IPDetails`: Stores linked project ID, researcher address, metadata URI, associated NFT token ID.

**Events:**
*   `ResearcherAdded(address researcher)`
*   `ResearcherRemoved(address researcher)`
*   `ReputationUpdated(address researcher, int256 newReputation)`
*   `ProjectSubmitted(uint256 projectId, address lead)`
*   `ProjectFunded(uint256 projectId, uint256 amount)`
*   `ProjectStarted(uint256 projectId)`
*   `MilestoneSubmitted(uint256 projectId, uint256 milestoneIndex, bytes32 milestoneHash)`
*   `MilestoneVerified(uint256 projectId, uint256 milestoneIndex, bool success)`
*   `ProjectCompleted(uint256 projectId)`
*   `ProjectCancelled(uint256 projectId)`
*   `IPRegistered(uint256 projectId, bytes32 ipHash, string metadataURI)`
*   `IPNFTMinted(uint256 projectId, bytes32 ipHash, uint256 tokenId, address owner)`
*   `ProposalCreated(uint256 proposalId, ProposalType proposalType)`
*   `Voted(uint256 proposalId, address voter, bool support, uint256 weight)`
*   `ProposalExecuted(uint256 proposalId)`
*   `GrantSubmitted(uint256 grantId, address applicant, uint256 amount)`
*   `GrantExecuted(uint256 grantId)`
*   `Staked(address user, uint256 amount)`
*   `Unstaked(address user, uint256 amount)`
*   `StakingRewardsClaimed(address user, uint256 amount)`
*   `Paused()`
*   `Unpaused()`

**Modifiers:**
*   `onlyResearcher`: Restricts function to registered researchers.
*   `onlyProjectLead(uint256 _projectId)`: Restricts function to the lead researcher of a specific project.
*   `whenNotPaused`: Prevents execution when contract is paused.
*   `whenPaused`: Prevents execution when contract is *not* paused.
*   `onlyGovernance`: Restricts function to execution via a successful governance proposal. (Not a direct caller) - Or initially, just `onlyOwner` before governance takes over. Let's stick with `onlyOwner` for setup and imply governance calls it later.

**Functions (Total: 29)**

**Admin & Setup (Initially Owner-only, later potentially Governance):**
1.  `constructor(address _dargToken, address _ipNFT, ...)`: Initializes the contract with token/NFT addresses and initial governance parameters.
2.  `pauseContract()`: Pauses certain contract functions (e.g., funding, project starts, staking).
3.  `unpauseContract()`: Unpauses the contract.
4.  `setGovernanceParameter(uint256 _paramId, uint256 _newValue)`: Allows setting specific governance parameters (only callable via `executeProposal` if `ProposalType` is `GovernanceParameter`). *Internal helper called by executeProposal.*

**Researcher Management (Requires Governance approval via proposal):**
5.  `addResearcher(address _researcher)`: Adds a new address as a registered researcher (internal, called by `executeProposal`).
6.  `removeResearcher(address _researcher)`: Removes a researcher (internal, called by `executeProposal`).
7.  `_updateResearcherReputation(address _researcher, int256 _delta)`: Internal function to adjust researcher reputation based on project milestones, completion, votes, etc.

**Project Management:**
8.  `submitProjectProposal(string memory _title, string memory _descriptionURI, uint256 _fundingGoal, address[] memory _team, uint256[] memory _fundingDistributionBps)`: Allows a researcher to submit a new project proposal. Creates a governance proposal (`ProposalType.ProjectApproval`).
9.  `fundProject(uint256 _projectId, uint256 _amount)`: Allows anyone to contribute $DRG tokens to a project's funding goal.
10. `startProject(uint256 _projectId)`: Initiates a project if its funding goal is met *and* the project proposal was approved via governance. Changes status to `Active`.
11. `submitProjectMilestone(uint256 _projectId, bytes32 _milestoneHash, string memory _descriptionURI)`: Project lead submits a completed milestone's details (as a hash).
12. `verifyMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _passed)`: Allows authorized entities (e.g., designated reviewers or via governance vote) to vote on milestone verification. *Simplified here; actual implementation might involve complex peer review or require a specific governance proposal.*
13. `completeProject(uint256 _projectId)`: Marks a project as completed if all milestones are verified and governance approves (requires governance proposal). Triggers reward distribution and reputation updates.
14. `cancelProject(uint256 _projectId)`: Allows governance to cancel a project. Refunds remaining funds.

**Funding & Grants:**
15. `distributeProjectFunds(uint256 _projectId)`: Distributes allocated funds to the project team based on the distribution plan upon project start or milestone completion (internal, called by `startProject` or `completeProject`/`verifyMilestone`).
16. `submitGrantApplication(string memory _title, string memory _descriptionURI, uint256 _requestedAmount)`: Allows a researcher to submit a grant application. Creates a grant proposal.
17. `distributeGrantFunds(uint256 _grantId)`: Sends approved grant funds to the applicant (internal, called by `executeProposal` for a grant).

**Intellectual Property (IP) Management:**
18. `registerIPHash(uint256 _projectId, bytes32 _ipHash, string memory _metadataURI)`: Allows project lead to register the hash of research output/data associated with a project.
19. `mintIPNFT(uint256 _projectId, bytes32 _ipHash, address _owner, string memory _tokenURI, bytes memory _data)`: Mints an IP NFT (via the external `ipNFT` contract) representing the registered IP. Can be minted to the project lead, team, or DAO treasury based on project terms.

**Governance:**
20. `propose(ProposalType _type, bytes memory _targetData, string memory _descriptionURI)`: Allows researchers (with sufficient reputation) or stakers (with sufficient stake) to create a new governance proposal.
21. `vote(uint256 _proposalId, bool _support)`: Allows stakers and/or researchers (based on governance rules, e.g., stake-weighted, reputation-weighted, or liquid-delegated power) to vote on a proposal.
22. `delegate(address _delegatee)`: Allows a staker to delegate their voting power to another address.
23. `executeProposal(uint256 _proposalId)`: Executes the outcome of a proposal if it has passed and the voting period is over.

**Staking:**
24. `stake(uint256 _amount)`: Allows users to stake DARG tokens in the contract to gain voting power and potential rewards.
25. `unstake(uint256 _amount)`: Allows users to unstake tokens after a potential lock-up period (simplified here without lockup).
26. `claimStakingRewards()`: Allows stakers to claim accumulated rewards (reward calculation logic needed, simplified accumulator here).

**Query/Getter Functions:**
27. `getResearcher(address _researcher)`: Get details of a researcher.
28. `getProject(uint256 _projectId)`: Get details of a project.
29. `getProposal(uint256 _proposalId)`: Get details of a governance proposal.
30. `getGrant(uint256 _grantId)`: Get details of a grant proposal.
31. `getIPDetails(bytes32 _ipHash)`: Get details of a registered IP hash.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using 721 for simplicity, could be 1155

// --- Outline ---
// 1. State Variables: Addresses, counters, mappings for researchers, projects, proposals, staking, IP.
// 2. Enums & Structs: Define types for statuses, data structures.
// 3. Events: Log important actions.
// 4. Modifiers: Access control and state checks.
// 5. Interfaces: For DARG token (ERC20) and IP NFT (ERC721).
// 6. Admin & Setup: Constructor, pause/unpause.
// 7. Researcher Management: Add/remove researchers (via governance), internal reputation update.
// 8. Project Management: Submit, fund, start, milestone reporting/verification (simplified), complete, cancel.
// 9. Funding & Grants: Distribute project funds (internal), submit/distribute grants (via governance).
// 10. Intellectual Property (IP) Management: Register IP hash, mint IP NFT.
// 11. Governance: Propose, vote, delegate, execute proposals (for params, researchers, projects, grants).
// 12. Staking: Stake, unstake, claim rewards.
// 13. Query Functions: Get details of researchers, projects, proposals, grants, IP.

// --- Function Summary ---
// 1.  constructor: Initializes contract with token/NFT addresses and base params.
// 2.  pauseContract: Pauses core functionalities.
// 3.  unpauseContract: Unpauses core functionalities.
// 4.  setGovernanceParameter (internal): Updates a governance parameter based on proposal execution.
// 5.  addResearcher (internal): Registers a new researcher.
// 6.  removeResearcher (internal): De-registers a researcher.
// 7.  _updateResearcherReputation (internal): Adjusts researcher reputation score.
// 8.  submitProjectProposal: Creates a governance proposal for a new research project.
// 9.  fundProject: Allows users to donate $DRG to a project proposal's funding goal.
// 10. startProject: Moves a project proposal to active status if approved and funded.
// 11. submitProjectMilestone: Researcher submits progress for a project milestone.
// 12. verifyMilestone: Marks a project milestone as verified (simplified access).
// 13. completeProject (internal): Marks a project as completed and distributes rewards (called by executeProposal).
// 14. cancelProject (internal): Cancels a project and refunds funds (called by executeProposal).
// 15. distributeProjectFunds (internal): Transfers project funds based on milestones/completion.
// 16. submitGrantApplication: Creates a grant proposal for non-project funding.
// 17. distributeGrantFunds (internal): Transfers grant funds to recipient (called by executeProposal).
// 18. registerIPHash: Records the hash of research output associated with a project.
// 19. mintIPNFT: Mints an NFT representing registered IP via the external IP NFT contract.
// 20. propose: Creates a new governance or grant proposal.
// 21. vote: Casts a vote on an active proposal.
// 22. delegate: Delegates voting power to another address.
// 23. executeProposal: Executes the outcome of a successful and finished proposal.
// 24. stake: Stakes DARG tokens for voting power and rewards.
// 25. unstake: Unstakes DARG tokens.
// 26. claimStakingRewards: Claims accumulated staking rewards.
// 27. getResearcher: Retrieves details for a researcher.
// 28. getProject: Retrieves details for a project.
// 29. getProposal: Retrieves details for a governance proposal.
// 30. getGrant: Retrieves details for a grant proposal.
// 31. getIPDetails: Retrieves details for a registered IP hash.

// Total Functions: 31 (well over 20)

// --- Interfaces ---

interface IDARGToken is IERC20 {
    // Add any custom DARG token functions if necessary, e.g., minting/burning by DARG contract
    // function mint(address to, uint256 amount) external;
    // function burn(uint256 amount) external;
}

interface IIPNFT is IERC721 {
    // Assuming a mint function callable by the DARG contract
    function mint(address to, uint256 tokenId, string memory uri) external returns (uint256);
    // Or if tokenId is auto-generated:
    // function mint(address to, string memory uri) external returns (uint256 tokenId);
    // Let's use a simple mint function signature for demonstration
    function safeMint(address to, uint256 tokenId, string memory uri) external;
}

// --- Contract Implementation ---

contract DecentralizedAutonomousResearchGuild is Ownable, ReentrancyGuard {
    // --- State Variables ---

    IDARGToken public dargToken;
    IIPNFT public ipNFT;

    uint256 private _nextProjectId;
    uint256 private _nextProposalId;
    uint256 private _nextGrantId;
    uint256 private _nextIPNFTId; // For simplified sequential IP NFT token IDs

    enum ProjectStatus { Proposed, Funded, Active, MilestoneReview, Completed, Cancelled }
    enum ProposalType { GovernanceParameter, NewResearcher, RemoveResearcher, ProjectApproval, GrantApproval }
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    enum GrantStatus { Proposed, Voting, Succeeded, Failed, Executed }

    struct Researcher {
        address wallet;
        int256 reputation;
        bool isResearcher;
        uint256[] activeProjects; // IDs of projects the researcher is currently leading or on the team
    }

    struct Milestone {
        bytes32 milestoneHash;
        string descriptionURI; // Link to off-chain description/data
        bool verified;
        mapping(address => bool) verifierVotes; // Simplified verification: who voted for/against verification?
        uint256 verificationVotes; // Count of successful verification votes (simplified quorum)
        uint256 totalVerifierVotesCast;
    }

    struct Project {
        string title;
        string descriptionURI;
        address leadResearcher;
        address[] team; // Team member addresses
        ProjectStatus status;
        uint256 fundingGoal; // in DARG tokens
        uint256 fundedAmount; // current amount funded
        uint256 allocatedFunding; // amount released from fundedAmount for work
        uint256[] fundingDistributionBps; // Basis points (summing to 10000) for team distribution
        Milestone[] milestones;
        bytes32[] ipHashes; // Hashes of associated IP
        uint256 creationTimestamp;
    }

    struct Proposal {
        ProposalType proposalType;
        bytes targetData; // ABI-encoded data for parameter change, researcher address, project/grant ID
        string descriptionURI; // Link to off-chain proposal details
        uint256 startBlock; // Or startTimestamp
        uint256 endBlock;   // Or endTimestamp
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // To prevent double voting
    }

     struct Grant {
        string title;
        string descriptionURI;
        address applicant;
        uint256 requestedAmount; // in DARG tokens
        uint256 startBlock; // Or startTimestamp
        uint256 endBlock;   // Or endTimestamp
        uint256 votesFor;
        uint256 votesAgainst;
        GrantStatus status;
        mapping(address => bool) hasVoted; // To prevent double voting
    }

    struct IPDetails {
        uint256 projectId;
        address researcher; // The researcher who registered it
        string metadataURI; // Link to off-chain metadata about the IP
        uint256 nftTokenId; // The token ID of the associated IP NFT (0 if no NFT minted)
    }

    mapping(address => Researcher) public researchers;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Proposal) public governanceProposals;
    mapping(uint256 => Grant) public grantProposals;
    mapping(bytes32 => IPDetails) public registeredIPHashes; // IP Hash => Details

    // Staking
    mapping(address => uint256) public stakedBalances;
    uint256 public totalStaked;
    // Reward calculation logic can be complex. Simple: accrue share of total staked,
    // rewards added to a pool and distributed proportionally? Or time-based?
    // Let's use a simple accumulator based on time and stake amount for example.
    // A more advanced system would use a reward rate and handle compounding shares.
    // This example simplifies to just tracking stake. Reward distribution requires external logic or funding.
    // We'll add placeholder for claiming rewards.
    // mapping(address => uint256) public stakingRewards; // Placeholder for accumulated rewards

    // Governance Delegation
    mapping(address => address) public delegates; // Voter => Delegatee

    // Governance Parameters (can be updated via proposals)
    uint256 public minVotingPeriodBlocks = 1000; // Example block duration
    uint256 public quorumThresholdBps = 4000; // 40% of total staked supply (in Basis Points)
    uint256 public projectFundingThresholdBps = 8000; // 80% of funding goal required to start (in Basis Points)
    int256 public minReputationForProposal = 100; // Minimum reputation to submit a proposal
    uint256 public milestoneVerificationQuorumBps = 6000; // 60% of participating reviewers needed to verify milestone


    bool public paused = false;

    // --- Events ---

    event ResearcherAdded(address indexed researcher);
    event ResearcherRemoved(address indexed researcher);
    event ReputationUpdated(address indexed researcher, int256 newReputation);

    event ProjectSubmitted(uint256 indexed projectId, address indexed lead);
    event ProjectFunded(uint256 indexed projectId, uint256 amount);
    event ProjectStarted(uint256 indexed projectId);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, bytes32 milestoneHash);
    event MilestoneVerified(uint256 indexed projectId, uint256 indexed milestoneIndex, bool success);
    event ProjectCompleted(uint256 indexed projectId);
    event ProjectCancelled(uint256 indexed projectId);

    event IPRegistered(uint256 indexed projectId, bytes32 indexed ipHash, string metadataURI);
    event IPNFTMinted(uint256 indexed projectId, bytes32 indexed ipHash, uint256 indexed tokenId, address owner);

    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);

    event GrantSubmitted(uint256 indexed grantId, address indexed applicant, uint256 amount);
    event GrantExecuted(uint256 indexed grantId);

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyResearcher() {
        require(researchers[msg.sender].isResearcher, "DARG: Not a registered researcher");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].leadResearcher == msg.sender, "DARG: Not the project lead");
        _;
    }

     modifier whenNotPaused() {
        require(!paused, "DARG: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "DARG: Not paused");
        _;
    }

    // Note: Functions meant to be called ONLY by governance proposals will
    // be marked as internal and called by `executeProposal`.

    // --- Interfaces ---

    // (Defined above State Variables)

    // --- Contract Implementation ---

    // 6. Admin & Setup
    constructor(address _dargToken, address _ipNFT) Ownable(msg.sender) {
        require(_dargToken != address(0), "DARG: Invalid DARG token address");
        require(_ipNFT != address(0), "DARG: Invalid IP NFT address");
        dargToken = IDARGToken(_dargToken);
        ipNFT = IIPNFT(_ipNFT);

        // Initial admin is the first researcher (can be changed later via governance)
        // Or perhaps first admin is just the deployer who adds researchers via governance proposals
        // Let's add the deployer as the first researcher for bootstrapping.
        researchers[msg.sender] = Researcher(msg.sender, 0, true, new uint256[](0));
        emit ResearcherAdded(msg.sender);

        _nextProjectId = 1;
        _nextProposalId = 1;
        _nextGrantId = 1;
        _nextIPNFTId = 1; // Assuming sequential NFT IDs starting from 1
    }

    /// @notice Pauses core functionalities. Only callable by owner initially, later governance.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses core functionalities. Only callable by owner initially, later governance.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @dev Sets a specific governance parameter. Internal, called by executeProposal.
    /// @param _paramId Identifier for the parameter (e.g., 1 for minVotingPeriodBlocks)
    /// @param _newValue The new value for the parameter.
    function setGovernanceParameter(uint256 _paramId, uint256 _newValue) internal {
        // This mapping logic would be more complex with more parameters
        // and needs careful handling in the proposal struct and executeProposal logic.
        // Example for paramId 1:
        // require(_paramId == 1, "DARG: Unknown parameter ID");
        // minVotingPeriodBlocks = _newValue;
        // More robust implementation would use a mapping or switch case
        // based on paramId to update different state variables.
        revert("DARG: setGovernanceParameter not fully implemented"); // Placeholder
    }

    // 7. Researcher Management (Internal - Called via Governance)

    /// @dev Adds a researcher to the guild. Internal, called by executeProposal.
    /// @param _researcher The address to add.
    function addResearcher(address _researcher) internal {
        require(_researcher != address(0), "DARG: Invalid address");
        require(!researchers[_researcher].isResearcher, "DARG: Already a researcher");
        researchers[_researcher] = Researcher(_researcher, 0, true, new uint256[](0));
        emit ResearcherAdded(_researcher);
    }

    /// @dev Removes a researcher from the guild. Internal, called by executeProposal.
    /// @param _researcher The address to remove.
    function removeResearcher(address _researcher) internal {
        require(researchers[_researcher].isResearcher, "DARG: Not a researcher");
        require(researchers[_researcher].activeProjects.length == 0, "DARG: Researcher has active projects");
        // In a real system, need to handle their staked tokens, reputation, etc.
        delete researchers[_researcher];
        emit ResearcherRemoved(_researcher);
    }

    /// @dev Internal function to update a researcher's reputation.
    /// Triggered by project completion, milestone verification, governance votes, etc.
    /// @param _researcher The researcher's address.
    /// @param _delta The amount to add to the current reputation (can be negative).
    function _updateResearcherReputation(address _researcher, int256 _delta) internal {
        require(researchers[_researcher].isResearcher, "DARG: Not a researcher");
        // Prevent potential underflow if reputation is int256
        if (_delta < 0 && researchers[_researcher].reputation < -_delta) {
             researchers[_researcher].reputation = 0; // Cap at 0 or a minimum
        } else {
            researchers[_researcher].reputation += _delta;
        }

        emit ReputationUpdated(_researcher, researchers[_researcher].reputation);
    }

    // 8. Project Management

    /// @notice Allows a researcher to submit a new research project proposal.
    /// Creates a governance proposal for approval.
    /// @param _title Project title.
    /// @param _descriptionURI Link to off-chain detailed description.
    /// @param _fundingGoal Required DARG funding.
    /// @param _team Addresses of team members (including lead).
    /// @param _fundingDistributionBps Funding split for the team in basis points (sum must be 10000).
    function submitProjectProposal(
        string memory _title,
        string memory _descriptionURI,
        uint256 _fundingGoal,
        address[] memory _team,
        uint256[] memory _fundingDistributionBps
    ) public onlyResearcher whenNotPaused {
        require(researchers[msg.sender].reputation >= minReputationForProposal, "DARG: Not enough reputation to propose");
        require(_team.length > 0, "DARG: Team cannot be empty");
        require(_team[0] == msg.sender, "DARG: First team member must be the lead researcher (msg.sender)");
        require(_team.length == _fundingDistributionBps.length, "DARG: Team and distribution arrays must match length");
        uint256 totalBps;
        for (uint i = 0; i < _fundingDistributionBps.length; i++) {
            totalBps += _fundingDistributionBps[i];
        }
        require(totalBps == 10000, "DARG: Funding distribution basis points must sum to 10000");
        require(_fundingGoal > 0, "DARG: Funding goal must be greater than 0");

        uint256 projectId = _nextProjectId++;
        projects[projectId].title = _title;
        projects[projectId].descriptionURI = _descriptionURI;
        projects[projectId].leadResearcher = msg.sender;
        projects[projectId].team = _team; // Copy the array
        projects[projectId].status = ProjectStatus.Proposed;
        projects[projectId].fundingGoal = _fundingGoal;
        projects[projectId].fundingDistributionBps = _fundingDistributionBps; // Copy the array
        projects[projectId].creationTimestamp = block.timestamp;

        // Create a governance proposal for this project
        bytes memory proposalData = abi.encode(projectId);
        uint256 proposalId = _nextProposalId++;
        governanceProposals[proposalId] = Proposal(
            ProposalType.ProjectApproval,
            proposalData,
            string(abi.encodePacked("Project Approval: ", _title)), // Simple description for proposal
            block.number,
            block.number + minVotingPeriodBlocks,
            0, 0, ProposalStatus.Active, new mapping(address => bool)()
        );

        emit ProjectSubmitted(projectId, msg.sender);
        emit ProposalCreated(proposalId, ProposalType.ProjectApproval, msg.sender);
    }

    /// @notice Allows anyone to contribute DARG tokens to a proposed project.
    /// @param _projectId The ID of the project proposal.
    /// @param _amount The amount of DARG tokens to fund.
    function fundProject(uint256 _projectId, uint256 _amount) public whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Funded, "DARG: Project not in funding stage");
        require(project.fundedAmount < project.fundingGoal, "DARG: Project funding goal already met");
        require(_amount > 0, "DARG: Amount must be greater than 0");

        uint256 amountToTransfer = _amount;
        if (project.fundedAmount + _amount > project.fundingGoal) {
            amountToTransfer = project.fundingGoal - project.fundedAmount;
        }

        require(dargToken.transferFrom(msg.sender, address(this), amountToTransfer), "DARG: Token transfer failed");

        project.fundedAmount += amountToTransfer;
        project.status = ProjectStatus.Funded; // Update status if first funding received

        emit ProjectFunded(_projectId, amountToTransfer);
    }

    /// @notice Starts a project if its proposal is approved and funding threshold is met.
    /// Can be called by anyone once conditions are met (or triggered by executeProposal).
    /// Simplified: callable by owner/governance after conditions met.
    /// @param _projectId The ID of the project.
    function startProject(uint256 _projectId) public onlyOwner whenNotPaused { // Change to governance call later
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Funded, "DARG: Project not funded");

        // Find the associated Project Approval proposal
        uint256 proposalId = 0; // Needs mapping ProjectId => ProposalId or searching proposals
        // For demonstration, let's assume project was approved. In real code, link Project ID to Proposal ID.
        // require(governanceProposals[proposalId].status == ProposalStatus.Succeeded, "DARG: Project proposal not approved");

        uint256 requiredFundingForStart = (project.fundingGoal * projectFundingThresholdBps) / 10000;
        require(project.fundedAmount >= requiredFundingForStart, "DARG: Funding threshold not met");

        project.status = ProjectStatus.Active;
        project.allocatedFunding = 0; // No funds allocated yet, will be done per milestone or on start

        // Add project ID to researchers' active project lists
        researchers[project.leadResearcher].activeProjects.push(_projectId);
        for(uint i = 0; i < project.team.length; i++) {
             // Avoid adding lead twice, check if member is already researcher
             if (researchers[project.team[i]].isResearcher && project.team[i] != project.leadResearcher) {
                 researchers[project.team[i]].activeProjects.push(_projectId);
             } else if (!researchers[project.team[i]].isResearcher) {
                 // Maybe add as an 'associate' or require them to become researchers first?
                 // For simplicity, just add to researcher if they are one.
             }
        }


        // Allocate initial funding? Or wait for first milestone? Let's allocate on start.
        // Simplified: Allocate a small portion or the full amount here.
        // A real system would tie allocation to milestones.
        // Let's distribute a portion (e.g., 10%) on start.
        // distributeProjectFunds(_projectId, project.fundedAmount / 10); // Requires distributeProjectFunds to take amount

        emit ProjectStarted(_projectId);
    }

    /// @notice Project lead submits details for a completed milestone.
    /// @param _projectId The project ID.
    /// @param _milestoneHash Hash of the milestone work/data.
    /// @param _descriptionURI Link to off-chain description of the milestone.
    function submitProjectMilestone(uint256 _projectId, bytes32 _milestoneHash, string memory _descriptionURI) public onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.MilestoneReview, "DARG: Project not active or in review");

        project.milestones.push(Milestone(_milestoneHash, _descriptionURI, false, new mapping(address => bool)(), 0, 0));
        project.status = ProjectStatus.MilestoneReview; // Move to review status

        emit MilestoneSubmitted(_projectId, project.milestones.length - 1, _milestoneHash);
    }

    /// @notice Allows a researcher or designated reviewer to vote on milestone verification.
    /// @param _projectId The project ID.
    /// @param _milestoneIndex The index of the milestone (0-based).
    /// @param _passed Whether the reviewer believes the milestone passed verification.
    function verifyMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _passed) public onlyResearcher whenNotPaused { // Access control needs refinement (e.g., designated reviewers)
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.MilestoneReview, "DARG: Project not in milestone review");
        require(_milestoneIndex < project.milestones.length, "DARG: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(!milestone.verified, "DARG: Milestone already verified");
        require(!milestone.verifierVotes[msg.sender], "DARG: Already voted on this milestone");

        milestone.verifierVotes[msg.sender] = true;
        milestone.totalVerifierVotesCast++;

        if (_passed) {
            milestone.verificationVotes++;
        }

        // Check if quorum/threshold for verification is reached
        // Simplified: Quorum of *participating* reviewers, not total researchers
        uint256 requiredVotes = (milestone.totalVerifierVotesCast * milestoneVerificationQuorumBps) / 10000;

        if (milestone.verificationVotes >= requiredVotes && milestone.totalVerifierVotesCast > 0) {
             milestone.verified = true;
             // Trigger fund distribution for this milestone
             // distributeProjectFunds(_projectId, _milestoneIndex); // Requires distributeProjectFunds to take milestone index

             // Update project status if all milestones are verified
             bool allMilestonesVerified = true;
             for(uint i = 0; i < project.milestones.length; i++) {
                 if (!project.milestones[i].verified) {
                     allMilestonesVerified = false;
                     break;
                 }
             }
             if (allMilestonesVerified) {
                 project.status = ProjectStatus.Funded; // Move back to Funded state, awaiting completion proposal
             } else {
                 project.status = ProjectStatus.Active; // Move back to Active if more milestones expected
             }

             // Update reputation for researchers involved in this milestone? Yes.
             _updateResearcherReputation(project.leadResearcher, 50); // Example reputation gain

             emit MilestoneVerified(_projectId, _milestoneIndex, true);

        } else if (milestone.totalVerifierVotesCast >= minVotingPeriodBlocks) { // Use block count as a simple "review period"
             // Milestone failed to reach quorum/threshold within review period
             // Handle consequences: partial reputation loss, project might need new proposal
             project.status = ProjectStatus.Active; // Or Cancelled? Or needs re-submission?
             _updateResearcherReputation(project.leadResearcher, -20); // Example reputation loss
             emit MilestoneVerified(_projectId, _milestoneIndex, false);
        }
    }

    /// @dev Marks a project as completed and triggers final reward distribution.
    /// Internal, called by executeProposal after a "Project Completion Approval" proposal passes.
    /// @param _projectId The project ID.
    function completeProject(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Cancelled, "DARG: Project already finished");
        // require all milestones verified? Or governance overrides? Let's require all verified.
        for(uint i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].verified, "DARG: Not all milestones verified");
        }

        project.status = ProjectStatus.Completed;

        // Final fund distribution and reward
        // distributeProjectFunds(_projectId, type(uint256).max); // Signal final distribution

        // Update reputation for successful project completion
        _updateResearcherReputation(project.leadResearcher, 200); // Larger reputation gain
        for(uint i = 0; i < project.team.length; i++) {
             if (researchers[project.team[i]].isResearcher && project.team[i] != project.leadResearcher) {
                 _updateResearcherReputation(project.team[i], 100); // Team members get less
             }
        }

        // Remove project ID from active projects list for team members
        for(uint i = 0; i < project.team.length; i++) {
             address member = project.team[i];
             if (researchers[member].isResearcher) {
                 uint256[] storage active = researchers[member].activeProjects;
                 for(uint j = 0; j < active.length; j++) {
                     if (active[j] == _projectId) {
                         active[j] = active[active.length - 1];
                         active.pop();
                         break;
                     }
                 }
             }
        }

        emit ProjectCompleted(_projectId);
    }

    /// @dev Cancels a project. Internal, called by executeProposal.
    /// @param _projectId The project ID.
    function cancelProject(uint256 _projectId) internal nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Cancelled, "DARG: Project already finished");

        project.status = ProjectStatus.Cancelled;

        // Refund remaining funds to contributors (simplified: send remaining balance back to a DAO treasury or burners)
        uint256 remainingBalance = dargToken.balanceOf(address(this)) - totalStaked; // Need a way to track project-specific balance vs staked balance
        // This is complex. A better approach is to escrow funds PER project.
        // Let's assume remaining balance *for this project* needs refunding.
        // Requires mapping ProjectId => EscrowBalance.
        // For simplicity, this function is incomplete regarding refunds.
        // revert("DARG: Project cancellation and refunds not fully implemented");

        // Remove project ID from active projects list
         for(uint i = 0; i < project.team.length; i++) {
             address member = project.team[i];
             if (researchers[member].isResearcher) {
                 uint256[] storage active = researchers[member].activeProjects;
                 for(uint j = 0; j < active.length; j++) {
                     if (active[j] == _projectId) {
                         active[j] = active[active.length - 1];
                         active.pop();
                         break;
                     }
                 }
             }
        }


        emit ProjectCancelled(_projectId);
    }

    // 9. Funding & Grants

    /// @dev Distributes allocated project funds to the project team based on distribution plan.
    /// Internal function, called upon project start or milestone verification/completion.
    /// @param _projectId The project ID.
    /// @param _amountToDistribute The amount of funding to distribute in this round.
    function distributeProjectFunds(uint256 _projectId, uint256 _amountToDistribute) internal nonReentrant {
        Project storage project = projects[_projectId];
        // Ensure allocatedFunding + amountToDistribute doesn't exceed fundedAmount
        uint256 distributionCap = project.fundedAmount - project.allocatedFunding;
        uint256 actualAmount = _amountToDistribute > distributionCap ? distributionCap : _amountToDistribute;

        require(actualAmount > 0, "DARG: No funds to distribute");

        project.allocatedFunding += actualAmount;

        for (uint i = 0; i < project.team.length; i++) {
            address teamMember = project.team[i];
            uint256 share = (actualAmount * project.fundingDistributionBps[i]) / 10000;
            if (share > 0) {
                // Transfer funds to team members
                require(dargToken.transfer(teamMember, share), "DARG: Failed to distribute funds to team");
            }
        }
    }

     /// @notice Allows a researcher to submit a grant application for general guild support.
     /// Creates a grant proposal for governance approval.
     /// @param _title Grant title.
     /// @param _descriptionURI Link to off-chain details.
     /// @param _requestedAmount Amount of DARG tokens requested.
    function submitGrantApplication(
        string memory _title,
        string memory _descriptionURI,
        uint256 _requestedAmount
    ) public onlyResearcher whenNotPaused {
        require(researchers[msg.sender].reputation >= minReputationForProposal, "DARG: Not enough reputation to propose");
        require(_requestedAmount > 0, "DARG: Requested amount must be greater than 0");

        uint256 grantId = _nextGrantId++;
        grantProposals[grantId] = Grant(
            _title,
            _descriptionURI,
            msg.sender,
            _requestedAmount,
            block.number,
            block.number + minVotingPeriodBlocks, // Use same voting period as governance
            0, 0, GrantStatus.Proposed, new mapping(address => bool)()
        );

        // Create a governance proposal for this grant
        bytes memory proposalData = abi.encode(grantId);
        uint256 proposalId = _nextProposalId++;
         governanceProposals[proposalId] = Proposal(
            ProposalType.GrantApproval,
            proposalData,
            string(abi.encodePacked("Grant Approval: ", _title)), // Simple description for proposal
            block.number,
            block.number + minVotingPeriodBlocks,
            0, 0, ProposalStatus.Active, new mapping(address => bool)()
        );

        emit GrantSubmitted(grantId, msg.sender, _requestedAmount);
        emit ProposalCreated(proposalId, ProposalType.GrantApproval, msg.sender);
    }


    /// @dev Distributes grant funds to the applicant. Internal, called by executeProposal.
    /// @param _grantId The grant ID.
    function distributeGrantFunds(uint256 _grantId) internal nonReentrant {
        Grant storage grant = grantProposals[_grantId];
        require(grant.status == GrantStatus.Succeeded, "DARG: Grant not succeeded");
        require(dargToken.balanceOf(address(this)) >= totalStaked + grant.requestedAmount, "DARG: Insufficient funds for grant"); // Ensure funds are available

        grant.status = GrantStatus.Executed;

        require(dargToken.transfer(grant.applicant, grant.requestedAmount), "DARG: Failed to distribute grant funds");

        emit GrantExecuted(_grantId);
    }


    // 10. Intellectual Property (IP) Management

    /// @notice Allows a project lead to register the hash of research output.
    /// @param _projectId The project ID this IP belongs to.
    /// @param _ipHash The hash of the research data/output (e.g., IPFS CID).
    /// @param _metadataURI Link to off-chain metadata describing the IP.
    function registerIPHash(uint256 _projectId, bytes32 _ipHash, string memory _metadataURI) public onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.Completed, "DARG: Project not active or completed");
        require(registeredIPHashes[_ipHash].projectId == 0, "DARG: IP hash already registered"); // Assuming project 0 is invalid

        registeredIPHashes[_ipHash] = IPDetails(
            _projectId,
            msg.sender, // The researcher who registered it
            _metadataURI,
            0 // No NFT yet
        );
        project.ipHashes.push(_ipHash);

        emit IPRegistered(_projectId, _ipHash, _metadataURI);
    }

    /// @notice Mints an NFT representing ownership or rights to registered IP.
    /// Requires the IP hash to be registered first.
    /// @param _ipHash The registered hash of the IP.
    /// @param _owner The address to mint the NFT to.
    /// @param _tokenURI URI for the NFT metadata.
    /// @param _data Optional data for the mint function (e.g., ERC1155 amount/data).
    function mintIPNFT(bytes32 _ipHash, address _owner, string memory _tokenURI, bytes memory _data) public whenNotPaused { // Access control: who can mint NFTs? Project lead? Governance?
        IPDetails storage ipDetails = registeredIPHashes[_ipHash];
        require(ipDetails.projectId != 0, "DARG: IP hash not registered"); // Ensure IP exists
        require(ipDetails.nftTokenId == 0, "DARG: NFT already minted for this IP");
        require(_owner != address(0), "DARG: Invalid owner address");

        // In a real system, who has permission to mint for specific IP?
        // Could be only the project lead, or require a governance proposal.
        // For simplicity, let's say project lead can mint initially.
        require(projects[ipDetails.projectId].leadResearcher == msg.sender, "DARG: Only project lead can mint NFT for this IP");


        uint256 newTokenId = _nextIPNFTId++; // Simplified sequential ID
        // Note: IIPNFT interface assumes ERC721 safeMint with tokenId.
        // If using ERC1155, the mint function signature would be different.
        // Adjust interface and call based on actual NFT contract.
        ipNFT.safeMint(_owner, newTokenId, _tokenURI);

        ipDetails.nftTokenId = newTokenId;

        emit IPNFTMinted(ipDetails.projectId, _ipHash, newTokenId, _owner);
    }


    // 11. Governance

    /// @notice Creates a new governance or grant proposal.
    /// Requires sufficient reputation or stake.
    /// @param _type The type of proposal (GovernanceParameter, NewResearcher, etc.).
    /// @param _targetData ABI-encoded data relevant to the proposal type.
    /// @param _descriptionURI Link to off-chain proposal details.
    function propose(ProposalType _type, bytes memory _targetData, string memory _descriptionURI) public whenNotPaused {
        // Check proposal eligibility:
        bool eligible = false;
        // Option 1: Minimum Stake
        // require(stakedBalances[msg.sender] >= minStakeForProposal, "DARG: Not enough stake to propose");
        // Option 2: Minimum Reputation
         if (researchers[msg.sender].isResearcher && researchers[msg.sender].reputation >= minReputationForProposal) {
             eligible = true;
         }
         // Add other eligibility criteria if needed (e.g., combined stake/reputation)
         require(eligible, "DARG: Not eligible to propose");


        uint256 proposalId = _nextProposalId++;
        governanceProposals[proposalId] = Proposal(
            _type,
            _targetData,
            _descriptionURI,
            block.number,
            block.number + minVotingPeriodBlocks,
            0, 0, ProposalStatus.Active, new mapping(address => bool)()
        );

        emit ProposalCreated(proposalId, _type, msg.sender);
    }

    /// @notice Casts a vote on an active governance proposal.
    /// Voting power is based on staked DARG or delegated power.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a vote in favor, false for against.
    function vote(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "DARG: Proposal not active");
        require(block.number >= proposal.startBlock && block.number < proposal.endBlock, "DARG: Voting period not active");

        address voter = msg.sender;
        // Resolve delegate if exists
        address votingAddress = delegates[voter] != address(0) ? delegates[voter] : voter;

        require(!proposal.hasVoted[votingAddress], "DARG: Already voted");

        // Voting power calculation:
        // Simple: 1 token staked = 1 vote. Or based on reputation? Or a combination?
        // Using staked balance is common for token governance.
        uint256 votingWeight = stakedBalances[votingAddress]; // Get the balance of the actual staker or delegatee

        require(votingWeight > 0, "DARG: No voting power (stake or delegation)");

        proposal.hasVoted[votingAddress] = true;

        if (_support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }

        emit Voted(_proposalId, votingAddress, _support, votingWeight); // Log the address whose power was used
    }

    /// @notice Allows a staker to delegate their voting power.
    /// @param _delegatee The address to delegate voting power to. address(0) to undelegate.
    function delegate(address _delegatee) public whenNotPaused {
        // Optional: require msg.sender has staked balance
        require(stakedBalances[msg.sender] > 0, "DARG: Must have staked tokens to delegate");
        require(msg.sender != _delegatee, "DARG: Cannot delegate to self");

        delegates[msg.sender] = _delegatee;
        // In a real system, need to manage voting power snapshots carefully when delegates change mid-vote.
        // This simple version just updates the delegate mapping.

        // Emit an event for delegation
        // event DelegationUpdated(address indexed delegator, address indexed delegatee);
    }


    /// @notice Executes a proposal if it has passed the voting period and met success conditions.
    /// Callable by anyone.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "DARG: Proposal not active");
        require(block.number >= proposal.endBlock, "DARG: Voting period not ended");

        // Check success conditions:
        // 1. Votes For > Votes Against
        // 2. Quorum Met: Votes For + Votes Against >= (totalStaked * quorumThresholdBps) / 10000
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (totalStaked * quorumThresholdBps) / 10000;

        if (proposal.votesFor > proposal.votesAgainst && totalVotesCast >= requiredQuorum) {
            proposal.status = ProposalStatus.Succeeded;

            // Execute the proposal based on type
            if (proposal.proposalType == ProposalType.GovernanceParameter) {
                (uint256 paramId, uint256 newValue) = abi.decode(proposal.targetData, (uint256, uint256));
                 setGovernanceParameter(paramId, newValue); // Call internal function
            } else if (proposal.proposalType == ProposalType.NewResearcher) {
                 (address newResearcherAddr) = abi.decode(proposal.targetData, (address));
                 addResearcher(newResearcherAddr); // Call internal function
            } else if (proposal.proposalType == ProposalType.RemoveResearcher) {
                 (address oldResearcherAddr) = abi.decode(proposal.targetData, (address));
                 removeResearcher(oldResearcherAddr); // Call internal function
            } else if (proposal.proposalType == ProposalType.ProjectApproval) {
                 (uint256 projectId) = abi.decode(proposal.targetData, (uint256));
                 // Project approval just means it's eligible to be started *if* funded.
                 // We don't start it automatically here.
                 // The `startProject` function requires both approval (implicit) and funding.
                 // A better design might move approved projects to a new status like 'ApprovedForFunding'.
                 // For this example, reaching Succeeded status is enough approval.
            } else if (proposal.proposalType == ProposalType.GrantApproval) {
                 (uint256 grantId) = abi.decode(proposal.targetData, (uint256));
                 // Transfer funds for the grant
                 distributeGrantFunds(grantId); // Call internal function
            } else {
                revert("DARG: Unknown proposal type for execution");
            }

            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);

        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }


    // 12. Staking

    /// @notice Stakes DARG tokens in the contract.
    /// @param _amount The amount of DARG tokens to stake.
    function stake(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "DARG: Amount must be greater than 0");
        require(dargToken.transferFrom(msg.sender, address(this), _amount), "DARG: Token transfer failed");

        stakedBalances[msg.sender] += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    /// @notice Unstakes DARG tokens from the contract.
    /// @param _amount The amount of DARG tokens to unstake.
    function unstake(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "DARG: Amount must be greater than 0");
        require(stakedBalances[msg.sender] >= _amount, "DARG: Not enough staked tokens");

        stakedBalances[msg.sender] -= _amount;
        totalStaked -= _amount;

        // Reset delegation if unstaking everything? Or keep it? Let's keep it.
        // if (stakedBalances[msg.sender] == 0) {
        //     delete delegates[msg.sender];
        // }

        require(dargToken.transfer(msg.sender, _amount), "DARG: Token transfer failed");

        emit Unstaked(msg.sender, _amount);
    }

    /// @notice Claims accumulated staking rewards.
    /// NOTE: Reward calculation logic is complex and omitted here.
    /// This function is a placeholder. A real system needs a mechanism
    /// for earning and distributing rewards (e.g., based on protocol revenue, inflation).
    function claimStakingRewards() public whenNotPaused nonReentrant {
        // Placeholder logic: Calculate and distribute rewards.
        // uint256 rewards = calculateRewards(msg.sender); // Complex external/internal function
        // require(rewards > 0, "DARG: No rewards to claim");
        // stakingRewards[msg.sender] = 0; // Reset claimed rewards
        // require(dargToken.transfer(msg.sender, rewards), "DARG: Reward transfer failed");
        // emit StakingRewardsClaimed(msg.sender, rewards);

        revert("DARG: Staking rewards claim not implemented"); // Placeholder
    }


    // 13. Query/Getter Functions

    /// @notice Retrieves details for a registered researcher.
    /// @param _researcher The researcher's address.
    /// @return Researcher struct details.
    function getResearcher(address _researcher) public view returns (Researcher memory) {
        require(researchers[_researcher].isResearcher, "DARG: Address is not a researcher");
        return researchers[_researcher];
    }

    /// @notice Retrieves details for a project.
    /// @param _projectId The project ID.
    /// @return Project struct details.
    function getProject(uint256 _projectId) public view returns (Project memory) {
        require(_projectId > 0 && _projectId < _nextProjectId, "DARG: Invalid project ID");
        Project storage project = projects[_projectId];
        // Return struct including dynamically sized arrays
        return Project(
            project.title,
            project.descriptionURI,
            project.leadResearcher,
            project.team,
            project.status,
            project.fundingGoal,
            project.fundedAmount,
            project.allocatedFunding,
            project.fundingDistributionBps,
            project.milestones, // Note: Mapping inside Milestone struct is not returned
            project.ipHashes,
            project.creationTimestamp
        );
    }

    /// @notice Retrieves details for a governance proposal.
    /// @param _proposalId The proposal ID.
    /// @return Proposal struct details (excluding the mapping).
    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
         require(_proposalId > 0 && _proposalId < _nextProposalId, "DARG: Invalid proposal ID");
         Proposal storage proposal = governanceProposals[_proposalId];
         return Proposal(
             proposal.proposalType,
             proposal.targetData,
             proposal.descriptionURI,
             proposal.startBlock,
             proposal.endBlock,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.status,
             new mapping(address => bool)() // Mappings cannot be returned directly
         );
    }

    /// @notice Retrieves details for a grant proposal.
    /// @param _grantId The grant ID.
    /// @return Grant struct details (excluding the mapping).
    function getGrant(uint256 _grantId) public view returns (Grant memory) {
        require(_grantId > 0 && _grantId < _nextGrantId, "DARG: Invalid grant ID");
        Grant storage grant = grantProposals[_grantId];
        return Grant(
            grant.title,
            grant.descriptionURI,
            grant.applicant,
            grant.requestedAmount,
            grant.startBlock,
            grant.endBlock,
            grant.votesFor,
            grant.votesAgainst,
            grant.status,
            new mapping(address => bool)() // Mappings cannot be returned directly
        );
    }

    /// @notice Retrieves details for a registered IP hash.
    /// @param _ipHash The IP hash.
    /// @return IPDetails struct.
    function getIPDetails(bytes32 _ipHash) public view returns (IPDetails memory) {
         require(registeredIPHashes[_ipHash].projectId != 0, "DARG: IP hash not registered");
         return registeredIPHashes[_ipHash];
    }

    // --- Fallback/Receive (Optional but good practice) ---
    receive() external payable {
        revert("DARG: Cannot receive ether directly");
    }

    fallback() external payable {
        revert("DARG: Cannot receive ether directly");
    }
}
```