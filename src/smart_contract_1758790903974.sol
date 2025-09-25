Here's a smart contract for a "Decentralized Autonomous Research Lab" (DARL Protocol), incorporating advanced concepts like Soul-Bound Credentials (SBCs), Dynamic Project NFTs (PNFTs), and a decentralized research funding and collaboration mechanism. It aims for creativity by combining these elements into a novel ecosystem for on-chain research and development.

---

## DARL Protocol: Decentralized Autonomous Research Lab

This smart contract defines the core logic for the Decentralized Autonomous Research Lab (DARL) Protocol. It facilitates a community-governed platform for funding, managing, and rewarding on-chain research and development projects.

### Outline

1.  **ERC20 Token ($DARL)**: The native governance and utility token, based on OpenZeppelin's `ERC20Votes` for robust on-chain voting.
2.  **Access Control**: Utilizes OpenZeppelin's `AccessControl` for roles like `DEFAULT_ADMIN_ROLE` and `SBC_ISSUER_ROLE`.
3.  **Staking & Governance**: Mechanism for DARL token holders to stake their tokens, gain voting power, and earn rewards.
4.  **Treasury Management**: Functions for submitting, voting on, and executing proposals for spending from the DARL treasury.
5.  **Soul-Bound Credentials (SBCs)**: Non-transferable ERC721 tokens representing researcher identities, skills, and achievements, fostering a verifiable on-chain reputation system.
6.  **Dynamic Project NFTs (PNFTs)**: ERC721 tokens that represent research projects. Their metadata (e.g., `tokenURI`) can be dynamically updated as projects progress through milestones, making them "living" NFTs.
7.  **Research Project Lifecycle**: Functions guiding a research project from proposal submission, through funding and milestone verification, to finalization and reward distribution.
8.  **Synergy Matrix & Collaboration**: A mechanism for researchers to register their skills and collaboration interests, facilitating on-chain matching for project teams.

---

### Function Summary (21 Unique Functions)

**I. Core DAO & Tokenomics ($DARL Token & Treasury)**

1.  `stakeDARL(uint256 amount)`: Allows users to stake their $DARL tokens to gain voting power and accrue rewards.
2.  `unstakeDARL()`: Allows stakers to withdraw their $DARL tokens and forfeit future rewards.
3.  `claimStakingRewards()`: Allows stakers to claim their accumulated rewards from the reward pool.
4.  `proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description)`: Submits a proposal for governance to vote on spending funds from the protocol treasury.
5.  `voteOnProposal(uint256 _proposalId, bool _support)`: Allows staked $DARL holders to cast their vote on an active treasury spend proposal.
6.  `executeTreasurySpend(uint256 _proposalId)`: Executes an approved treasury spend proposal, transferring funds to the recipient.
7.  `depositTreasury(uint256 amount)`: Allows external parties or the protocol itself to deposit funds into the treasury.

**II. Soul-Bound Credentials (SBCs - Researcher Profiles)**

8.  `issueSBC_ResearcherID(address _to, string memory _profileHash)`: Mints a unique, non-transferable Researcher Identity SBC for a new participant. (Admin/Issuer Role)
9.  `issueSBC_SkillBadge(address _to, uint256 _skillId, string memory _metadataURI)`: Issues a specific skill badge SBC to a researcher, verifiable on-chain. (Admin/Issuer Role)
10. `revokeSBC_SkillBadge(address _from, uint256 _skillId)`: Allows an authorized issuer to revoke a previously issued skill badge. (Admin/Issuer Role)
11. `updateSBC_ProfileHash(uint256 _tokenId, string memory _newProfileHash)`: Allows a researcher to update the metadata hash associated with their ResearcherID SBC.
12. `hasSBC(address _holder, uint256 _tokenId)`: Public view function to check if an address currently holds a specific SBC token.

**III. Dynamic Project NFTs (PNFTs - Research Project Lifecycle)**

13. `submitResearchProposal(string memory _title, string memory _descriptionHash, uint256 _requestedFunds, address[] memory _collaborators)`: A researcher submits a new project proposal for review and potential funding.
14. `approveProjectProposal(uint256 _proposalId, address _projectLead, string memory _initialPNFTURI)`: Governance approves a proposal, initiating the project and minting its initial PNFT.
15. `fundProjectMilestone(uint256 _projectId, uint256 _amount)`: Releases a tranche of funds from the treasury to the project lead for a specific milestone.
16. `submitMilestoneProof(uint256 _projectId, string memory _milestoneHash)`: The project lead submits proof of a completed milestone.
17. `verifyMilestoneAndAdvancePNFT(uint256 _projectId, string memory _newStageURI)`: Governance verifies a milestone, updates the project's PNFT metadata to reflect the new stage.
18. `requestProjectExtension(uint256 _projectId, uint256 _additionalFunds, string memory _reasonHash)`: Project lead requests additional funding or time for an ongoing project.
19. `finalizeProjectAndReward(uint256 _projectId, string memory _finalReportHash)`: Marks a project as complete, archives its PNFT, and distributes final rewards.

**IV. Synergy Matrix & Collaboration**

20. `registerSkillInterest(uint256 _skillId, bool _lookingForCollab)`: Researchers register their skills and indicate whether they are open to collaboration for those skills.
21. `proposeProjectCollaboration(uint256 _projectId, address _collaborator, string memory _role)`: A project lead formally invites another researcher (identified by address) to collaborate on their project.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title DARL Protocol: Decentralized Autonomous Research Lab
/// @author Your Name/AI (Placeholder)
/// @notice This contract implements a community-governed platform for funding, managing, and rewarding on-chain research and development projects.
/// @dev It combines ERC20 for governance, Soul-Bound Tokens for identity/reputation, Dynamic NFTs for project tracking, and a treasury system.

contract DARLProtocol is ERC20Votes, ERC20Permit, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Access Control Roles ---
    bytes32 public constant SBC_ISSUER_ROLE = keccak256("SBC_ISSUER_ROLE");
    bytes32 public constant PROJECT_LEAD_ROLE = keccak256("PROJECT_LEAD_ROLE"); // Granted to project lead upon project approval

    // --- State Variables ---
    Counters.Counter private _proposalIds;
    Counters.Counter private _projectIdCounter;

    // --- Staking ---
    mapping(address => uint256) public stakedAmounts;
    uint256 public totalStaked;
    uint256 public rewardsPerTokenStored;
    mapping(address => uint256) public userLastRecordedRewardsPerToken; // For calculating rewards
    mapping(address => uint256) public userAccumulatedRewards; // Actual claimable rewards
    uint256 public constant REWARD_POOL_ALLOCATION_RATE = 100; // Example: 0.01% of treasury deposits (100 means 100 / 10000 = 1%)

    // --- Treasury Proposals ---
    struct TreasuryProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint224 amount; // Using uint224 to save space as uint256 is usually overkill
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool approved;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    mapping(uint256 => TreasuryProposal) public treasuryProposals;
    uint256 public constant VOTING_PERIOD_BLOCKS = 100; // Example: 100 blocks for voting

    // --- Soul-Bound Credentials (SBCs) ---
    SBCCollection public sbcCollection;
    uint256 public constant SBC_RESEARCHER_ID_TYPE = 1; // Standard type for Researcher ID
    uint256 private _nextSkillId = 1000; // Starting skill IDs from 1000 to avoid conflict with Researcher ID

    // --- Dynamic Project NFTs (PNFTs) ---
    PNFTCollection public pnftCollection;
    struct ResearchProject {
        uint256 id;
        address projectLead;
        string title;
        string descriptionHash; // IPFS hash or similar for detailed description
        uint256 requestedFunds;
        uint256 fundsAllocated;
        address[] collaborators;
        ProjectStatus status;
        uint256 proposalVoteStartTime;
        uint256 proposalVoteEndTime;
        uint256 proposalVotesFor;
        uint256 proposalVotesAgainst;
        bool proposalApproved;
        mapping(address => bool) hasVotedOnProjectProposal;
        mapping(uint256 => string) milestoneProofs; // milestoneIndex => IPFS hash
        uint256 currentMilestone;
        string finalReportHash;
    }
    mapping(uint256 => ResearchProject) public projects;
    enum ProjectStatus { Proposed, Approved, InProgress, OnHold, Completed, Rejected }
    uint256 public constant PROJECT_VOTING_PERIOD_BLOCKS = 200; // Longer voting for projects

    // --- Synergy Matrix (Skill Registry) ---
    struct SkillRegistry {
        bool exists;
        bool lookingForCollaboration;
        mapping(address => bool) projectInvitations; // Project ID => Accepted
    }
    mapping(uint256 => mapping(address => SkillRegistry)) public skillMatrix; // skillId => researcherAddress => SkillRegistry

    // --- Events ---
    event DARLStaked(address indexed user, uint256 amount);
    event DARLUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event TreasuryProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount, string description);
    event TreasuryProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 currentVotesFor, uint256 currentVotesAgainst);
    event TreasuryProposalExecuted(uint256 indexed proposalId, bool approved);
    event TreasuryDeposited(address indexed sender, uint256 amount);

    event ResearchProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 requestedFunds);
    event ResearchProposalApproved(uint256 indexed projectId, address indexed projectLead, string initialPNFTURI);
    event ProjectFunded(uint256 indexed projectId, uint256 amount);
    event MilestoneProofSubmitted(uint256 indexed projectId, address indexed submitter, uint256 milestoneIndex, string milestoneHash);
    event ProjectPNFTAdvanced(uint256 indexed projectId, string newStageURI);
    event ProjectExtensionRequested(uint256 indexed projectId, uint256 additionalFunds);
    event ProjectFinalized(uint256 indexed projectId, string finalReportHash);

    event SkillRegistered(address indexed researcher, uint256 skillId, bool lookingForCollab);
    event CollaborationProposed(uint256 indexed projectId, address indexed projectLead, address indexed collaborator, string role);
    event CollaborationAccepted(uint256 indexed projectId, address indexed collaborator);

    constructor(uint256 initialSupply)
        ERC20("DARL Protocol Token", "DARL")
        ERC20Permit("DARL Protocol Token")
        ERC20Votes("DARL Protocol Token")
    {
        _mint(msg.sender, initialSupply);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SBC_ISSUER_ROLE, msg.sender); // Initial SBC issuer is the deployer

        // Deploy SBC and PNFT contracts
        sbcCollection = new SBCCollection();
        pnftCollection = new PNFTCollection(address(this)); // Pass DARLProtocol address for role management
        _grantRole(DEFAULT_ADMIN_ROLE, address(sbcCollection)); // Allow SBC contract to interact if needed
        _grantRole(DEFAULT_ADMIN_ROLE, address(pnftCollection)); // Allow PNFT contract to interact if needed
    }

    // The following two functions are overrides required by Solidity for ERC20Votes.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    // --- MODIFIERS ---
    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].projectLead == msg.sender, "Caller is not the project lead");
        _;
    }

    modifier onlySBCIssuer() {
        require(hasRole(SBC_ISSUER_ROLE, msg.sender), "Caller is not an SBC Issuer");
        _;
    }

    // --- Helper Functions ---
    function _updateStakingRewards(address _user) internal {
        uint256 _rewardsPerToken = rewardsPerTokenStored;
        uint256 _userStake = stakedAmounts[_user];

        if (_userStake > 0) {
            uint256 pendingRewards = _userStake.mul(_rewardsPerToken.sub(userLastRecordedRewardsPerToken[_user])).div(1e18); // Scale for precision
            userAccumulatedRewards[_user] = userAccumulatedRewards[_user].add(pendingRewards);
        }
        userLastRecordedRewardsPerToken[_user] = _rewardsPerToken;
    }

    function _distributeRewardPool(uint256 _amount) internal {
        if (totalStaked == 0 || _amount == 0) {
            return;
        }
        rewardsPerTokenStored = rewardsPerTokenStored.add(_amount.mul(1e18).div(totalStaked)); // Scale for precision
    }

    // --- I. Core DAO & Tokenomics ($DARL Token & Treasury) ---

    /// @notice Allows users to stake their $DARL tokens to gain voting power and accrue rewards.
    /// @param amount The amount of $DARL tokens to stake.
    function stakeDARL(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot stake 0 DARL");
        _updateStakingRewards(msg.sender); // Update current rewards before modifying stake
        transferFrom(msg.sender, address(this), amount); // Transfer tokens to this contract
        stakedAmounts[msg.sender] = stakedAmounts[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        emit DARLStaked(msg.sender, amount);
    }

    /// @notice Allows stakers to withdraw their $DARL tokens and forfeit future rewards.
    function unstakeDARL() public nonReentrant {
        uint256 amount = stakedAmounts[msg.sender];
        require(amount > 0, "No DARL tokens staked");

        _updateStakingRewards(msg.sender); // Calculate final rewards before unstaking
        stakedAmounts[msg.sender] = 0;
        totalStaked = totalStaked.sub(amount);
        _transfer(address(this), msg.sender, amount); // Transfer tokens back to user
        emit DARLUnstaked(msg.sender, amount);
    }

    /// @notice Allows stakers to claim their accumulated rewards from the reward pool.
    function claimStakingRewards() public nonReentrant {
        _updateStakingRewards(msg.sender); // Calculate final rewards
        uint256 rewards = userAccumulatedRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");

        userAccumulatedRewards[msg.sender] = 0;
        _transfer(address(this), msg.sender, rewards); // Transfer rewards from contract balance
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Submits a proposal for governance to vote on spending funds from the protocol treasury.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of funds to send.
    /// @param _description A description of the proposal.
    function proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description) public {
        require(_amount > 0, "Proposal amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient DARL balance to cover proposal amount"); // Proposer must hold the proposed amount, or a bonding curve

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        treasuryProposals[proposalId] = TreasuryProposal({
            id: proposalId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: uint224(_amount),
            description: _description,
            voteStartTime: block.number,
            voteEndTime: block.number + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            approved: false
        });
        emit TreasuryProposalSubmitted(proposalId, msg.sender, _recipient, _amount, _description);
    }

    /// @notice Allows staked $DARL holders to cast their vote on an active treasury spend proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "for" vote, False for "against" vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.number >= proposal.voteStartTime, "Voting has not started");
        require(block.number <= proposal.voteEndTime, "Voting has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterStake = stakedAmounts[msg.sender];
        require(voterStake > 0, "Voter must have staked DARL");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterStake);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterStake);
        }
        emit TreasuryProposalVoted(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    /// @notice Executes an approved treasury spend proposal, transferring funds to the recipient.
    /// @param _proposalId The ID of the proposal to execute.
    function executeTreasurySpend(uint256 _proposalId) public nonReentrant {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.number > proposal.voteEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        proposal.approved = proposal.votesFor > proposal.votesAgainst && proposal.votesFor > (totalStaked / 10); // Simple quorum: 10% of total staked

        if (proposal.approved) {
            require(balanceOf(address(this)) >= proposal.amount, "Insufficient treasury balance");
            _transfer(address(this), proposal.recipient, proposal.amount);
            emit TreasuryProposalExecuted(_proposalId, true);
        } else {
            emit TreasuryProposalExecuted(_proposalId, false);
        }
    }

    /// @notice Allows external parties or the protocol itself to deposit funds into the treasury.
    /// @param amount The amount of DARL to deposit.
    function depositTreasury(uint256 amount) public nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        transferFrom(msg.sender, address(this), amount);

        // Allocate a portion to the staking reward pool
        uint256 rewardShare = amount.mul(REWARD_POOL_ALLOCATION_RATE).div(10000); // 100/10000 = 1%
        if (rewardShare > 0) {
            _distributeRewardPool(rewardShare);
        }
        emit TreasuryDeposited(msg.sender, amount);
    }

    // --- II. Soul-Bound Credentials (SBCs - Researcher Profiles) ---

    /// @notice Mints a unique, non-transferable Researcher Identity SBC for a new participant.
    /// @dev Only callable by an SBC_ISSUER_ROLE. `_profileHash` can be an IPFS hash pointing to a detailed profile.
    /// @param _to The address of the researcher to issue the SBC to.
    /// @param _profileHash IPFS hash or URI for the researcher's profile metadata.
    function issueSBC_ResearcherID(address _to, string memory _profileHash) public onlySBCIssuer {
        require(sbcCollection.balanceOf(_to) == 0, "Researcher already has an ID SBC");
        sbcCollection.safeMint(_to, SBC_RESEARCHER_ID_TYPE, _profileHash); // Use a standard token ID for ID SBCs or a dynamic one. Here using a fixed one.
    }

    /// @notice Issues a specific skill badge SBC to a researcher, verifiable on-chain.
    /// @dev Only callable by an SBC_ISSUER_ROLE. `_metadataURI` can point to badge details.
    /// @param _to The address of the researcher.
    /// @param _skillId A unique identifier for the skill badge (e.g., hash of skill name).
    /// @param _metadataURI IPFS hash or URI for the skill badge metadata.
    function issueSBC_SkillBadge(address _to, uint256 _skillId, string memory _metadataURI) public onlySBCIssuer {
        require(sbcCollection.tokenOwnerExistsAndHasSBC(_to), "Recipient must have a Researcher ID SBC first.");
        sbcCollection.safeMint(_to, _skillId, _metadataURI);
    }

    /// @notice Allows an authorized issuer to revoke a previously issued skill badge.
    /// @dev This could be used if a credential becomes invalid or is abused.
    /// @param _from The address of the researcher whose badge is being revoked.
    /// @param _skillId The ID of the skill badge to revoke.
    function revokeSBC_SkillBadge(address _from, uint256 _skillId) public onlySBCIssuer {
        sbcCollection.burnSpecificSBC(_from, _skillId);
    }

    /// @notice Allows a researcher to update the metadata hash associated with their ResearcherID SBC.
    /// @dev This enables dynamic profiles where researchers can update their skills/info off-chain and update the hash.
    /// @param _tokenId The token ID of the Researcher ID SBC (SBC_RESEARCHER_ID_TYPE).
    /// @param _newProfileHash The new IPFS hash or URI for the profile metadata.
    function updateSBC_ProfileHash(uint256 _tokenId, string memory _newProfileHash) public {
        require(sbcCollection.ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this SBC");
        require(_tokenId == SBC_RESEARCHER_ID_TYPE, "Only Researcher ID SBCs can be updated this way");
        sbcCollection.setTokenURI(_tokenId, _newProfileHash);
    }

    /// @notice Public view function to check if an address currently holds a specific SBC token.
    /// @param _holder The address to check.
    /// @param _tokenId The token ID of the SBC.
    /// @return True if the address holds the SBC, false otherwise.
    function hasSBC(address _holder, uint256 _tokenId) public view returns (bool) {
        return sbcCollection.ownerOf(_tokenId) == _holder;
    }

    // --- III. Dynamic Project NFTs (PNFTs - Research Project Lifecycle) ---

    /// @notice A researcher submits a new project proposal for review and potential funding.
    /// @param _title The title of the research project.
    /// @param _descriptionHash IPFS hash of the detailed project description.
    /// @param _requestedFunds The total amount of DARL funds requested for the project.
    /// @param _collaborators Optional array of addresses for initial collaborators.
    function submitResearchProposal(
        string memory _title,
        string memory _descriptionHash,
        uint256 _requestedFunds,
        address[] memory _collaborators
    ) public {
        _projectIdCounter.increment();
        uint256 projectId = _projectIdCounter.current();

        projects[projectId] = ResearchProject({
            id: projectId,
            projectLead: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            requestedFunds: _requestedFunds,
            fundsAllocated: 0,
            collaborators: _collaborators,
            status: ProjectStatus.Proposed,
            proposalVoteStartTime: block.number,
            proposalVoteEndTime: block.number + PROJECT_VOTING_PERIOD_BLOCKS,
            proposalVotesFor: 0,
            proposalVotesAgainst: 0,
            proposalApproved: false,
            currentMilestone: 0,
            finalReportHash: ""
        });
        emit ResearchProposalSubmitted(projectId, msg.sender, _title, _requestedFunds);
    }

    // A voting function similar to `voteOnProposal` would be needed here for project proposals.
    // For brevity, I'll assume an admin can approve for this example, but in a real DAO, it would be a token vote.
    // Function to vote on a project proposal:
    // function voteOnProjectProposal(uint256 _projectId, bool _support) ...

    /// @notice Governance approves a proposal, initiating the project and minting its initial PNFT.
    /// @dev Requires `DEFAULT_ADMIN_ROLE` or a successful governance vote.
    /// @param _proposalId The ID of the research proposal to approve.
    /// @param _projectLead The address of the researcher who will lead the project.
    /// @param _initialPNFTURI The initial metadata URI for the project's PNFT.
    function approveProjectProposal(uint256 _proposalId, address _projectLead, string memory _initialPNFTURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // In a full DAO, this would be `onlyIfApprovedByGovernance(_proposalId)`
    {
        ResearchProject storage project = projects[_proposalId];
        require(project.id != 0, "Project proposal does not exist");
        require(project.status == ProjectStatus.Proposed, "Project not in proposed status");

        project.status = ProjectStatus.Approved;
        project.projectLead = _projectLead; // Can reassign lead if needed
        project.proposalApproved = true;

        pnftCollection.safeMint(_projectLead, _proposalId, _initialPNFTURI);
        _grantRole(PROJECT_LEAD_ROLE, _projectLead); // Grant project lead role for specific functions

        emit ResearchProposalApproved(_proposalId, _projectLead, _initialPNFTURI);
    }

    /// @notice Releases a tranche of funds from the treasury to the project lead for a specific milestone.
    /// @dev Requires `DEFAULT_ADMIN_ROLE` or governance vote.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount of DARL to release.
    function fundProjectMilestone(uint256 _projectId, uint256 _amount)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE) // Again, typically a governance vote
    {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "Project not approved or in progress");
        require(project.fundsAllocated.add(_amount) <= project.requestedFunds, "Funding exceeds requested amount");
        require(balanceOf(address(this)) >= _amount, "Insufficient treasury balance");

        project.fundsAllocated = project.fundsAllocated.add(_amount);
        _transfer(address(this), project.projectLead, _amount);

        if (project.status == ProjectStatus.Approved) {
            project.status = ProjectStatus.InProgress;
        }

        emit ProjectFunded(_projectId, _amount);
    }

    /// @notice The project lead submits proof of a completed milestone.
    /// @dev This could be an IPFS hash of a report, code commit, or other evidence.
    /// @param _projectId The ID of the project.
    /// @param _milestoneHash The IPFS hash or URI pointing to the milestone proof.
    function submitMilestoneProof(uint256 _projectId, string memory _milestoneHash) public onlyProjectLead(_projectId) {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "Project not in progress");

        project.currentMilestone = project.currentMilestone.add(1);
        project.milestoneProofs[project.currentMilestone] = _milestoneHash;

        emit MilestoneProofSubmitted(_projectId, msg.sender, project.currentMilestone, _milestoneHash);
    }

    /// @notice Governance verifies a milestone, updates the project's PNFT metadata to reflect the new stage.
    /// @dev Requires `DEFAULT_ADMIN_ROLE` or successful governance vote after proof submission.
    /// @param _projectId The ID of the project.
    /// @param _newStageURI The new metadata URI for the PNFT reflecting the advanced stage.
    function verifyMilestoneAndAdvancePNFT(uint256 _projectId, string memory _newStageURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // In real DAO, a vote
    {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "Project not in progress");
        require(bytes(project.milestoneProofs[project.currentMilestone]).length > 0, "No milestone proof submitted for current stage");

        // The PNFT is dynamic, its metadata URI changes with project progress
        pnftCollection.setTokenURI(_projectId, _newStageURI);

        emit ProjectPNFTAdvanced(_projectId, _newStageURI);
    }

    /// @notice Project lead requests additional funding or time for an ongoing project.
    /// @param _projectId The ID of the project.
    /// @param _additionalFunds The amount of additional funds requested.
    /// @param _reasonHash IPFS hash explaining the reason for the extension.
    function requestProjectExtension(uint256 _projectId, uint256 _additionalFunds, string memory _reasonHash)
        public
        onlyProjectLead(_projectId)
    {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "Project not in progress");

        // This would typically trigger a new treasury proposal or a specific extension vote.
        // For simplicity, we just record the request here.
        project.requestedFunds = project.requestedFunds.add(_additionalFunds);
        // A new proposal might be created here: `proposeTreasurySpend(project.projectLead, _additionalFunds, _reasonHash)`
        // And then need to be voted on.

        emit ProjectExtensionRequested(_projectId, _additionalFunds);
    }

    /// @notice Marks a project as complete, archives its PNFT, and distributes final rewards.
    /// @dev Requires `DEFAULT_ADMIN_ROLE` or successful governance vote after final report.
    /// @param _projectId The ID of the project.
    /// @param _finalReportHash IPFS hash of the final research report.
    function finalizeProjectAndReward(uint256 _projectId, string memory _finalReportHash)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE) // In a full DAO, a vote.
    {
        ResearchProject storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.InProgress, "Project not in progress");
        require(bytes(_finalReportHash).length > 0, "Final report hash required");

        project.status = ProjectStatus.Completed;
        project.finalReportHash = _finalReportHash;

        // Optionally, distribute final rewards to project lead and collaborators
        // For example: `_transfer(address(this), project.projectLead, finalRewardAmount);`
        // And distribute to collaborators if a split mechanism is defined.

        pnftCollection.burn(_projectId); // "Archive" the PNFT by burning it, or transfer to a "completed projects" collection.
        _revokeRole(PROJECT_LEAD_ROLE, project.projectLead); // Revoke temporary project lead role

        emit ProjectFinalized(_projectId, _finalReportHash);
    }

    // --- IV. Synergy Matrix & Collaboration ---

    /// @notice Researchers register their skills and indicate whether they are open to collaboration for those skills.
    /// @dev `_skillId` can be a standardized ID or a hash of the skill name.
    /// @param _skillId The unique identifier for the skill.
    /// @param _lookingForCollab Boolean indicating if the researcher is open to collaboration for this skill.
    function registerSkillInterest(uint256 _skillId, bool _lookingForCollab) public {
        require(sbcCollection.tokenOwnerExistsAndHasSBC(msg.sender), "Researcher must have an ID SBC to register skills.");
        skillMatrix[_skillId][msg.sender].exists = true;
        skillMatrix[_skillId][msg.sender].lookingForCollaboration = _lookingForCollab;
        emit SkillRegistered(msg.sender, _skillId, _lookingForCollab);
    }

    /// @notice A project lead formally invites another researcher (identified by address) to collaborate on their project.
    /// @param _projectId The ID of the project.
    /// @param _collaborator The address of the researcher being invited.
    /// @param _role The proposed role for the collaborator (e.g., "Cryptography Expert").
    function proposeProjectCollaboration(uint256 _projectId, address _collaborator, string memory _role)
        public
        onlyProjectLead(_projectId)
    {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Approved, "Project not active");
        require(_collaborator != address(0), "Collaborator address cannot be zero");
        require(_collaborator != msg.sender, "Cannot invite yourself to collaborate");
        require(sbcCollection.tokenOwnerExistsAndHasSBC(_collaborator), "Collaborator must have a Researcher ID SBC.");

        // Check if already a collaborator
        for (uint256 i = 0; i < project.collaborators.length; i++) {
            require(project.collaborators[i] != _collaborator, "Collaborator already invited or part of the project");
        }

        // Store the invitation implicitly or explicitly. For this simple model, we assume acceptance is separate.
        // A more advanced system might involve an explicit invitation state.
        skillMatrix[0][msg.sender].projectInvitations[_projectId] = true; // Use skillId 0 to represent generic project invites for the project lead.

        emit CollaborationProposed(_projectId, msg.sender, _collaborator, _role);
    }

    /// @notice A researcher accepts a collaboration invitation for a specific project.
    /// @param _projectId The ID of the project for which collaboration is accepted.
    function acceptProjectCollaboration(uint256 _projectId) public {
        ResearchProject storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Approved, "Project not active");
        require(sbcCollection.tokenOwnerExistsAndHasSBC(msg.sender), "Caller must have a Researcher ID SBC.");

        // Check if an invitation was effectively "sent" (e.g., by the project lead calling proposeProjectCollaboration)
        // This is a simplified check. A robust system would require the project lead to explicitly
        // `proposeProjectCollaboration` which might update a mapping `projectInvitations[_projectId][msg.sender]`
        // For now, we assume the `proposeProjectCollaboration` was called and this is an accept.

        // Add to project's collaborators list
        bool alreadyCollaborator = false;
        for (uint256 i = 0; i < project.collaborators.length; i++) {
            if (project.collaborators[i] == msg.sender) {
                alreadyCollaborator = true;
                break;
            }
        }
        require(!alreadyCollaborator, "Already a collaborator on this project");

        project.collaborators.push(msg.sender);
        emit CollaborationAccepted(_projectId, msg.sender);
    }

    // --- View Functions ---

    /// @notice Returns the current staking rewards available for a user.
    /// @param _user The address of the user.
    /// @return The amount of claimable rewards.
    function getClaimableStakingRewards(address _user) public view returns (uint256) {
        uint256 _rewardsPerToken = rewardsPerTokenStored;
        uint256 _userStake = stakedAmounts[_user];
        if (_userStake == 0) return userAccumulatedRewards[_user];

        uint256 pendingRewards = _userStake.mul(_rewardsPerToken.sub(userLastRecordedRewardsPerToken[_user])).div(1e18);
        return userAccumulatedRewards[_user].add(pendingRewards);
    }

    /// @notice Returns the current total staked amount in the protocol.
    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    /// @notice Returns the total supply of DARL tokens.
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return super.totalSupply();
    }

    /// @notice Returns the balance of DARL tokens for a specific address.
    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    /// @notice Returns the details of a specific treasury proposal.
    function getTreasuryProposal(uint256 _proposalId) public view returns (TreasuryProposal memory) {
        return treasuryProposals[_proposalId];
    }

    /// @notice Returns the total number of treasury proposals submitted.
    function getTotalTreasuryProposals() public view returns (uint256) {
        return _proposalIds.current();
    }

    /// @notice Returns the details of a specific research project.
    function getResearchProject(uint256 _projectId) public view returns (ResearchProject memory) {
        return projects[_projectId];
    }

    /// @notice Returns the total number of research projects submitted.
    function getTotalResearchProjects() public view returns (uint256) {
        return _projectIdCounter.current();
    }

    /// @notice Returns addresses of researchers with a specific skill who are looking for collaboration.
    /// @param _skillId The ID of the skill to search for.
    /// @return An array of addresses of matching researchers.
    function findCollaboratorsBySkill(uint256 _skillId) public view returns (address[] memory) {
        address[] memory matchingResearchers;
        uint256 count = 0;

        // This would iterate over all possible addresses which is not feasible on-chain.
        // A real implementation would require an off-chain indexer or a more advanced on-chain data structure.
        // For demonstration, let's assume `_skillId` allows us to iterate a limited set or is used with an off-chain call.
        // As a placeholder, we will return an empty array or simulate a few fixed ones.
        // A proper on-chain implementation for iterating all possible addresses is not efficient or practical.
        // This function would primarily be for an off-chain component to query the skillMatrix mapping for specific addresses.

        // Example: If we had a list of all registered researchers, we could iterate.
        // For now, just a conceptual placeholder that implies off-chain processing for discovery.
        // The on-chain `skillMatrix` just stores the data.
        return matchingResearchers;
    }

    /// @notice Returns the skill interest status for a given researcher and skill.
    /// @param _skillId The ID of the skill.
    /// @param _researcher The address of the researcher.
    /// @return A tuple containing: (skillExists, lookingForCollaboration).
    function getSkillInterest(uint256 _skillId, address _researcher) public view returns (bool, bool) {
        SkillRegistry storage registry = skillMatrix[_skillId][_researcher];
        return (registry.exists, registry.lookingForCollaboration);
    }
}

/// @title SBCCollection - Soul-Bound Credentials ERC721
/// @notice A non-transferable ERC721 collection for researcher identities and skill badges.
contract SBCCollection is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant SBC_ISSUER_ROLE = keccak256("SBC_ISSUER_ROLE"); // Same role as in main contract

    // tokenId => metadataURI (dynamic for some SBCs)
    mapping(uint256 => string) private _tokenURIs;
    // user => hasResearcherID
    mapping(address => bool) private _hasResearcherID;

    event SBCMinted(address indexed to, uint256 indexed tokenId, string uri);
    event SBCBurned(address indexed from, uint256 indexed tokenId);
    event SBCURIUpdated(uint256 indexed tokenId, string newUri);

    constructor() ERC721("SBC Researcher Credentials", "SBC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(SBC_ISSUER_ROLE, msg.sender); // Deployer is SBC Issuer
    }

    /// @dev Overrides _beforeTokenTransfer to make SBCs non-transferable (soul-bound).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from == address(0)) and burning (to == address(0))
        // Prevent all other transfers
        if (from != address(0) && to != address(0)) {
            revert("SBCs are non-transferable (soul-bound)");
        }
    }

    /// @notice Mints a new SBC for a researcher.
    /// @dev Only callable by SBC_ISSUER_ROLE.
    /// @param _to The recipient of the SBC.
    /// @param _typeId A type identifier for the SBC (e.g., 1 for Researcher ID, specific numbers for skills).
    /// @param _tokenURI_ The initial metadata URI for the SBC.
    function safeMint(address _to, uint256 _typeId, string memory _tokenURI_) public onlyRole(SBC_ISSUER_ROLE) {
        require(_to != address(0), "Cannot mint to the zero address");
        
        // For Researcher ID SBCs, ensure only one per address
        if (_typeId == DARLProtocol(msg.sender).SBC_RESEARCHER_ID_TYPE()) {
            require(!_hasResearcherID[_to], "Recipient already has a Researcher ID SBC");
            _hasResearcherID[_to] = true;
            _safeMint(_to, _typeId); // Use the typeId as the actual tokenId for ResearcherID
            _setTokenURI(_typeId, _tokenURI_);
            emit SBCMinted(_to, _typeId, _tokenURI_);
        } else {
            // For skill badges, mint a new sequential token ID
            _tokenIdCounter.increment();
            uint256 newId = _tokenIdCounter.current().add(_typeId); // Combine type and counter for unique skill badge ID
            require(ownerOf(newId) == address(0), "Token ID already exists"); // Prevent accidental overwrites
            _safeMint(_to, newId);
            _setTokenURI(newId, _tokenURI_);
            emit SBCMinted(_to, newId, _tokenURI_);
        }
    }

    /// @notice Allows an issuer to burn a specific SBC from an address.
    /// @dev Only callable by SBC_ISSUER_ROLE. Useful for revoking skill badges.
    /// @param _from The owner of the SBC to burn.
    /// @param _tokenId The specific token ID of the SBC to burn.
    function burnSpecificSBC(address _from, uint256 _tokenId) public onlyRole(SBC_ISSUER_ROLE) {
        require(ownerOf(_tokenId) == _from, "SBC not owned by specified address");
        if (_tokenId == DARLProtocol(msg.sender).SBC_RESEARCHER_ID_TYPE()) {
             _hasResearcherID[_from] = false; // Reset has Researcher ID flag
        }
        _burn(_tokenId);
        delete _tokenURIs[_tokenId]; // Clear URI mapping
        emit SBCBurned(_from, _tokenId);
    }

    /// @notice Internal function to set token URI, used by `updateSBC_ProfileHash` in main contract.
    /// @param _tokenId The token ID to update.
    /// @param _newUri The new URI for the token.
    function setTokenURI(uint256 _tokenId, string memory _newUri) public onlyRole(SBC_ISSUER_ROLE) {
        // Here, only the issuer can update. If researcher can update their *own* profile hash,
        // The main contract should call this via a method that checks `msg.sender == ownerOf(_tokenId)`.
        _setTokenURI(_tokenId, _newUri);
        emit SBCURIUpdated(_tokenId, _newUri);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }

    /// @notice Checks if an address exists and holds a Researcher ID SBC.
    /// @param _owner The address to check.
    /// @return True if the address has a Researcher ID SBC, false otherwise.
    function tokenOwnerExistsAndHasSBC(address _owner) public view returns (bool) {
        return _hasResearcherID[_owner];
    }
}

/// @title PNFTCollection - Dynamic Project NFTs ERC721
/// @notice An ERC721 collection where NFTs represent research projects and can have their metadata updated.
contract PNFTCollection is ERC721Enumerable, AccessControl {
    bytes32 public constant PROJECT_LEAD_ROLE = keccak256("PROJECT_LEAD_ROLE"); // Same role as in main contract

    // tokenId => metadataURI (dynamic for project stages)
    mapping(uint256 => string) private _tokenURIs;

    event PNFTMinted(address indexed to, uint256 indexed projectId, string uri);
    event PNFTBurned(address indexed from, uint256 indexed projectId);
    event PNFTURIUpdated(uint256 indexed projectId, string newUri);

    constructor(address _darlProtocol) ERC721("Project NFT", "PNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        // Grant the DARLProtocol contract the ability to manage PNFTs
        _grantRole(DEFAULT_ADMIN_ROLE, _darlProtocol);
        _grantRole(PROJECT_LEAD_ROLE, _darlProtocol); // So DARLProtocol can grant/revoke PROJECT_LEAD_ROLE
    }

    /// @notice Mints a new PNFT for a research project.
    /// @dev Only callable by the DARLProtocol contract or an authorized admin.
    /// @param _to The project lead's address.
    /// @param _projectId The unique ID of the research project (used as tokenId).
    /// @param _tokenURI_ The initial metadata URI for the PNFT.
    function safeMint(address _to, uint256 _projectId, string memory _tokenURI_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Only main protocol contract or admin should mint
    {
        require(_to != address(0), "Cannot mint to the zero address");
        _safeMint(_to, _projectId);
        _setTokenURI(_projectId, _tokenURI_);
        emit PNFTMinted(_to, _projectId, _tokenURI_);
    }

    /// @notice Burns a PNFT, effectively archiving a completed project.
    /// @dev Only callable by the DARLProtocol contract or an authorized admin.
    /// @param _projectId The ID of the project/PNFT to burn.
    function burn(uint256 _projectId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address owner = ownerOf(_projectId);
        _burn(_projectId);
        delete _tokenURIs[_projectId]; // Clear URI mapping
        emit PNFTBurned(owner, _projectId);
    }

    /// @notice Updates the metadata URI for a PNFT.
    /// @dev Only callable by the DARLProtocol contract or an authorized admin, allowing projects to be "dynamic".
    /// @param _projectId The ID of the project/PNFT to update.
    /// @param _newUri The new metadata URI.
    function setTokenURI(uint256 _projectId, string memory _newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireOwned(_projectId); // Ensure the token exists
        _setTokenURI(_projectId, _newUri);
        emit PNFTURIUpdated(_projectId, _newUri);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }
}
```