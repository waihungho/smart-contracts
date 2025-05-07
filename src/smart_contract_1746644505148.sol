Okay, here is a smart contract concept for a Decentralized Autonomous Creator Guild (DACG). This contract combines elements of DAOs, skill representation, project management with milestones, and dynamic royalty distribution, aiming for a unique blend of features not commonly found in a single standard template.

It's designed to be a self-governing entity where members collaborate, fund projects, verify skills, and share revenue from collective works.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- DACG Smart Contract Outline ---
// Contract Name: Decentralized Autonomous Creator Guild (DACG)
// Purpose: A self-governing decentralized organization for creators.
// It manages members, project funding, skill verification, and IP-linked royalty distribution.
// Advanced Concepts:
// - Skill Badges (ERC721): NFTs representing verified member skills.
// - Reputation Score: Dynamic metric based on contributions and successful projects/proposals.
// - Project Milestones: Funding released based on verified progress.
// - Dynamic Royalty Distribution: Splitting project revenue among participants based on defined shares.
// - On-chain Governance: Proposal system for membership, projects, rule changes, and skill verification.

// --- Function Summary ---
// --- Core Governance ---
// 1. submitProposal(ProposalType, description, target, value, callData): Submit a new governance proposal.
// 2. voteOnProposal(proposalId, support): Vote on an active proposal.
// 3. executeProposal(proposalId): Execute a successfully voted-on proposal.
// 4. cancelProposal(proposalId): Cancel a proposal (under specific conditions).
// 5. getProposalInfo(proposalId): View details of a proposal.
// 6. setGovernanceParameters(uint256, uint256, uint256): Proposal target for changing governance parameters (voting period, quorum, threshold).

// --- Membership Management ---
// 7. submitMembershipProposal(applicant, reason): Propose a new member.
// 8. leaveGuild(): Allow a member to leave the guild.
// 9. isMember(address): Check if an address is a current member.
// 10. getMemberInfo(address): View a member's profile info and reputation.
// 11. updateMemberProfile(string memory metadataUri): Allow a member to update their off-chain profile link.

// --- Project Management ---
// 12. submitProjectProposal(details, requestedBudget, milestones): Propose a new creative project.
// 13. submitMilestoneCompletionProposal(projectId, milestoneIndex, evidenceUri): Propose a project milestone is complete.
// 14. releaseMilestonePayment(projectId, milestoneIndex): Release funds for a verified milestone (called internally by executeProposal).
// 15. getProjectInfo(projectId): View details of a project.
// 16. addProjectParticipant(projectId, participant, role, royaltyShareBps): Add a participant to a project and define their royalty share.
// 17. removeProjectParticipant(projectId, participant): Remove a participant from a project.

// --- Skill & Reputation ---
// 18. defineSkill(bytes32 skillHash, string memory name, string memory description): Define a canonical skill (via proposal).
// 19. submitSkillVerificationProposal(member, skillHash, proofUri): Propose verification of a member's skill.
// 20. issueSkillBadge(address member, bytes32 skillHash): Mint a Skill Badge NFT (called internally by executeProposal).
// 21. getMemberSkills(address member): List all verified skills (Skill Badges) of a member.
// 22. calculateReputationScore(address member): Calculate a member's dynamic reputation score.

// --- Treasury Management ---
// 23. deposit(): Receive funds into the guild treasury.
// 24. withdrawTreasury(uint256 amount, address recipient): Proposal target for withdrawing funds from the treasury.

// --- IP & Royalty Distribution ---
// 25. registerProjectIP(uint256 projectId, string memory ipIdentifier, string memory metadataUri): Link external IP identifier/metadata to a project (via proposal or project lead). Let's make this a proposal target.
// 26. distributeProjectRoyalties(uint256 projectId, uint256 amount): Distribute royalties for a project among participants based on shares.
// 27. getProjectParticipantRoyaltyShare(uint256 projectId, address participant): Get a participant's defined royalty share for a project.

// --- Advanced/Utility ---
// 28. delegateVotingPower(address delegatee): Delegate voting rights.
// 29. revokeVotingPowerDelegation(): Revoke voting delegation.
// 30. signalIntent(uint256 proposalId, bool support): Signal non-binding intent on a proposal. (This is an off-chain concept primarily, but can be represented with an event for on-chain signaling). Let's replace with something more on-chain like dynamic quorum or voting power calculation. Let's do dynamic voting power based on reputation.
// 30. getVotingPower(address member): Get a member's current voting power (based on membership and reputation).

// Let's add a few more unique ones to ensure > 20 with interesting concepts.
// 31. defineProjectRole(bytes32 roleHash, string memory name, string memory description): Define canonical project roles (via proposal).
// 32. updateProjectMetadata(uint256 projectId, string memory metadataUri): Update project metadata (via proposal or project lead).
// 33. submitDisputeProposal(uint256 projectId, DisputeType dtype, string memory details): Submit a proposal to resolve a project dispute (e.g., performance issue, IP conflict).
// 34. getDisputeInfo(uint256 disputeId): View details of a dispute proposal.
// 35. getTreasuryBalance(): View the current treasury balance.
// 36. getSkillBadgeTokenId(bytes32 skillHash): Get the token ID for a specific canonical skill badge type. (Might need to rethink how skill badges are implemented - one token per skill *type* vs one token per *verified instance*. Let's go with one token per *verified instance* for a member/skill pair, linked to a canonical skill hash).
// 36. getMemberSkillBadge(address member, bytes32 skillHash): Get the token ID of a specific skill badge held by a member.

// Okay, let's refine the list to be concrete functions implemented. Aiming for >20 distinct function signatures.

// Final Function List (Counting):
// 1. submitProposal
// 2. voteOnProposal
// 3. executeProposal
// 4. cancelProposal
// 5. getProposalInfo
// 6. setGovernanceParameters (Proposal Target)
// 7. submitMembershipProposal
// 8. leaveGuild
// 9. isMember
// 10. getMemberInfo
// 11. updateMemberProfile
// 12. submitProjectProposal
// 13. submitMilestoneCompletionProposal
// 14. releaseMilestonePayment (Internal helper, not external API count) -> Let's make it proposal target to trigger release.
// 14. submitReleaseMilestonePaymentProposal (New)
// 15. getProjectInfo
// 16. addProjectParticipant
// 17. removeProjectParticipant
// 18. defineSkill (Proposal Target)
// 19. submitSkillVerificationProposal
// 20. issueSkillBadge (Internal helper, not external API count) -> Let's make it proposal target to trigger mint.
// 20. submitIssueSkillBadgeProposal (New)
// 21. getMemberSkills
// 22. calculateReputationScore (View function)
// 23. deposit (Payable function)
// 24. withdrawTreasury (Proposal Target)
// 25. registerProjectIP (Proposal Target)
// 26. distributeProjectRoyalties
// 27. getProjectParticipantRoyaltyShare
// 28. delegateVotingPower
// 29. revokeVotingPowerDelegation
// 30. getVotingPower (View function)
// 31. defineProjectRole (Proposal Target)
// 32. updateProjectMetadata (Proposal Target)
// 33. submitDisputeProposal
// 34. getDisputeInfo
// 35. getTreasuryBalance (View function)
// 36. getMemberSkillBadge (View function)
// 37. getCanonicalSkillInfo (New View function to see defined skills)
// 38. getCanonicalRoleInfo (New View function to see defined roles)
// 39. getProjectParticipants (New View function)
// 40. getProjectMilestones (New View function)

// Okay, easily over 20 public/external functions with diverse functionality.

// Internal ERC721 for Skill Badges
contract SkillBadge is ERC721 {
    constructor(address owner) ERC721("DACG Skill Badge", "DACGSB") {}

    // Custom minting logic accessible only by the DACG contract
    function mint(address to, uint256 tokenId) external {
        // Ensure only the DACG contract can call this function
        require(msg.sender == owner(), "SkillBadge: Only DACG can mint"); // Owner is the DACG contract
        _safeMint(to, tokenId);
    }

    // Custom burning logic accessible only by the DACG contract
    function burn(uint256 tokenId) external {
         require(msg.sender == owner(), "SkillBadge: Only DACG can burn"); // Owner is the DACG contract
        _burn(tokenId);
    }

    // Override transfer functions to prevent members from transferring badges
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SkillBadge: Badges are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SkillBadge: Badges are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("SkillBadge: Badges are non-transferable");
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               super.supportsInterface(interfaceId);
    }
}


contract DACG is AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    // --- State Variables ---

    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // For initial setup/emergency if needed, ideally governed later

    // Governance Parameters
    uint256 public votingPeriod; // Duration of proposal voting in seconds
    uint256 public proposalThreshold; // Minimum members required to submit a proposal (e.g., percentage or fixed number)
    uint256 public quorumThreshold; // Minimum percentage of total voting power needed for a proposal to pass

    // Members
    struct Member {
        bool exists; // Check if address is a registered member
        string profileMetadataUri; // Link to off-chain profile
        uint256 reputationScore; // Dynamic score based on contributions
        address delegate; // Address to which voting power is delegated
    }
    mapping(address => Member) private _members;
    EnumerableSet.AddressSet private _membersSet; // To iterate over members

    // Skills (Canonical definitions)
    struct Skill {
        string name;
        string description;
        bool exists;
        uint256 tokenIdCounter; // Counter for badge tokens of this skill type
    }
    mapping(bytes32 => Skill) private _canonicalSkills;
    bytes32[] private _canonicalSkillHashes; // To list all canonical skills

    // Skill Badges (ERC721)
    SkillBadge public skillBadges; // Internal ERC721 instance

    // Project Roles (Canonical definitions)
    struct ProjectRole {
        string name;
        string description;
        bool exists;
    }
    mapping(bytes32 => ProjectRole) private _canonicalProjectRoles;
    bytes32[] private _canonicalProjectRoleHashes; // To list all canonical roles

    // Projects
    enum ProjectStatus { Proposed, Active, Completed, Cancelled, Dispute }
    struct Milestone {
        string description;
        uint256 fundingPercentage; // Percentage of total project budget allocated to this milestone
        bool isCompleted;
        bytes32 completionProposalHash; // Link to the proposal verifying completion
    }
    struct Project {
        uint256 id;
        address proposer;
        string detailsMetadataUri; // Link to off-chain project details
        uint256 totalBudget;
        uint256 fundsReleased; // Ether released for completed milestones
        ProjectStatus status;
        Milestone[] milestones;
        mapping(address => uint256) participantRoyaltyShares; // Royalty share in basis points (e.g., 100 = 1%)
        EnumerableSet.AddressSet participants; // Addresses involved in the project
        bytes32 ipIdentifier; // Unique identifier linked to external IP (e.g., IPFS CID)
        string ipMetadataUri; // Metadata related to the IP
        bytes32 projectProposalHash; // Link to the original project proposal
    }
    mapping(uint256 => Project) private _projects;
    Counters.Counter private _projectIdCounter;

    // Governance Proposals
    enum ProposalType {
        General,
        Membership,
        ProjectFunding,
        SkillVerification,
        MilestoneCompletion,
        ChangeParameters,
        WithdrawTreasury,
        RegisterProjectIP,
        DefineSkill,
        DefineProjectRole,
        UpdateProjectMetadata,
        DisputeResolution,
        Slashing
    }
    enum ProposalStatus { Pending, Active, Succeeded, Defeated, Executed, Cancelled }
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        string description;
        uint256 submissionTime;
        uint256 votingDeadline;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        address targetContract; // Contract to call for execution (can be self)
        uint256 value; // Ether to send with the execution call
        bytes callData; // Data for the execution call
        // Specific data fields based on ProposalType (simplified - using calldata/description for details)
        // For example, a Membership proposal might encode the applicant address in description/calldata
        // A MilestoneCompletion proposal would need projectId and milestoneIndex
    }
    mapping(uint256 => Proposal) private _proposals;
    Counters.Counter private _proposalIdCounter;

    // --- Events ---
    event MemberJoined(address indexed member);
    event MemberLeft(address indexed member);
    event ProfileUpdated(address indexed member, string metadataUri);
    event ProposalSubmitted(uint256 indexed proposalId, ProposalType indexed proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event MilestoneStatusChanged(uint256 indexed projectId, uint256 indexed milestoneIndex, bool isCompleted);
    event MilestonePaymentReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ParticipantAdded(uint256 indexed projectId, address indexed participant, bytes32 role, uint256 royaltyShareBps);
    event ParticipantRemoved(uint256 indexed projectId, address indexed participant);
    event SkillDefined(bytes32 indexed skillHash, string name);
    event SkillVerified(address indexed member, bytes32 indexed skillHash, uint256 indexed badgeTokenId);
    event RoyaltiesDistributed(uint256 indexed projectId, uint256 amount);
    event VotingDelegated(address indexed delegator, address indexed delegatee);
    event VotingDelegationRevoked(address indexed delegator);
    event TreasuryDeposited(address indexed sender, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);
    event ProjectIPRegistered(uint256 indexed projectId, bytes32 ipIdentifier);
    event ProjectRoleDefined(bytes32 indexed roleHash, string name);
    event ProjectMetadataUpdated(uint256 indexed projectId, string metadataUri);
    event DisputeProposed(uint256 indexed projectId, uint256 indexed proposalId, DisputeType dtype);

    enum DisputeType { General, Performance, IPConflict, Other }


    // --- Constructor ---
    // Initializes with an initial admin (can be a multisig) and basic governance params
    constructor(address initialAdmin, uint256 _votingPeriod, uint256 _proposalThreshold, uint256 _quorumThreshold) {
        _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        // Initial governance parameters (can be changed via proposal)
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumThreshold = _quorumThreshold; // e.g., 5000 for 50%

        // Deploy the internal SkillBadge contract
        skillBadges = new SkillBadge(address(this));
    }

    // --- Modifiers ---
    modifier onlyMember() {
        require(_membersSet.contains(msg.sender), "Not a DACG member");
        _;
    }

    modifier onlyProjectParticipant(uint256 projectId) {
        require(_projects[projectId].participants.contains(msg.sender), "Not a project participant");
        _;
    }

    modifier onlyProposer(uint256 proposalId) {
        require(_proposals[proposalId].proposer == msg.sender, "Not the proposal proposer");
        _;
    }


    // --- Core Governance Functions ---

    /// @notice Submit a new governance proposal. Requires member status.
    /// @param proposalType Type of the proposal.
    /// @param description Description of the proposal.
    /// @param target Contract address to call if proposal passes (can be this contract).
    /// @param value Ether to send with the execution call.
    /// @param callData Data for the execution call.
    function submitProposal(
        ProposalType proposalType,
        string memory description,
        address target,
        uint256 value,
        bytes memory callData
    ) external onlyMember returns (uint256) {
        // Basic check: Ensure minimum members threshold is met (can be expanded to check voting power)
        require(_membersSet.length() >= proposalThreshold, "Not enough members to submit proposal");

        uint256 proposalId = _proposalIdCounter.current();
        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: proposalType,
            description: description,
            submissionTime: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            status: ProposalStatus.Active,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool),
            targetContract: target,
            value: value,
            callData: callData
        });
        _proposalIdCounter.increment();

        emit ProposalSubmitted(proposalId, proposalType, msg.sender);
        return proposalId;
    }

    /// @notice Vote on an active proposal. Requires member status.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for yes, false for no.
    function voteOnProposal(uint256 proposalId, bool support) external onlyMember {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        address voter = _getVotingDelegate(msg.sender); // Use delegate's address if delegated

        require(!proposal.hasVoted[voter], "Delegate already voted for this member");

        proposal.hasVoted[voter] = true;

        // Get voting power (simple: 1 member = 1 vote for now, can be weighted by reputation later)
        uint256 votingPower = getVotingPower(voter);
        require(votingPower > 0, "Voter has no voting power");

        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit VoteCast(proposalId, voter, support);

        // Automatically transition state if voting period ends
        if (block.timestamp > proposal.votingDeadline) {
             _checkProposalStatus(proposalId);
        }
    }

    /// @notice Check and update the status of a proposal after voting ends.
    /// Can be called by anyone.
    /// @param proposalId The ID of the proposal.
    function _checkProposalStatus(uint256 proposalId) internal {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.status == ProposalStatus.Active && block.timestamp > proposal.votingDeadline) {
            // Calculate total voting power (simplified: total members)
            uint256 totalVotingPower = _membersSet.length(); // Can be replaced by sum of getVotingPower() for all members

            // Check quorum: total votes cast >= (quorumThreshold / 10000) * totalVotingPower
             uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;
             bool quorumMet = (totalVotesCast * 10000) >= (totalVotingPower * quorumThreshold);

            if (quorumMet && proposal.yesVotes > proposal.noVotes) {
                proposal.status = ProposalStatus.Succeeded;
                emit ProposalStatusChanged(proposalId, ProposalStatus.Succeeded);
            } else {
                proposal.status = ProposalStatus.Defeated;
                emit ProposalStatusChanged(proposalId, ProposalStatus.Defeated);
            }
        }
    }


    /// @notice Execute a successfully voted-on proposal. Can be called by anyone after grace period.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "Proposal not in succeeded state");
        // Add a grace period check here if desired (e.g., block.timestamp > proposal.votingDeadline + gracePeriod)
        // require(block.timestamp > proposal.votingDeadline, "Grace period not over"); // Assuming execution can happen immediately after deadline

        // Mark as executed *before* the call to prevent reentrancy issues if target calls back
        proposal.status = ProposalStatus.Executed;
        emit ProposalStatusChanged(proposalId, ProposalStatus.Executed);

        // Execute the payload
        // Use low-level call for flexibility, handle success/failure
        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

     /// @notice Cancel a pending or active proposal. Only proposer or ADMIN_ROLE can cancel.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "Proposal not cancelable");
        require(proposal.proposer == msg.sender || hasRole(ADMIN_ROLE, msg.sender), "Only proposer or admin can cancel");
        require(block.timestamp < proposal.votingDeadline, "Voting period has ended");

        proposal.status = ProposalStatus.Cancelled;
        emit ProposalStatusChanged(proposalId, ProposalStatus.Cancelled);
    }


    /// @notice Get information about a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Details of the proposal.
    function getProposalInfo(uint256 proposalId) external view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    /// @notice Internal target function for a 'ChangeParameters' proposal type.
    /// Updates governance parameters. Accessible only via proposal execution.
    /// @param _votingPeriod New voting period in seconds.
    /// @param _proposalThreshold New proposal threshold (minimum members).
    /// @param _quorumThreshold New quorum threshold percentage (basis points, e.g., 5000 for 50%).
    function setGovernanceParameters(uint256 _votingPeriod, uint256 _proposalThreshold, uint256 _quorumThreshold) external {
        require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal

        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumThreshold = _quorumThreshold;

        // Add event if needed
    }


    // --- Membership Management Functions ---

    /// @notice Submit a proposal to add a new member. Requires member status.
    /// @param applicant The address to propose as a new member.
    /// @param reason Off-chain reason/context for the proposal.
    function submitMembershipProposal(address applicant, string memory reason) external onlyMember {
        require(!_members[applicant].exists, "Applicant is already a member");
        // Ensure a proposal of this type for this applicant doesn't already exist and is active/pending/succeeded recently
        // (Skipping detailed check for brevity, but crucial in production)

        // Craft the calldata for the execution - setting MEMBER_ROLE
        bytes memory callData = abi.encodeWithSelector(this.grantRole.selector, MEMBER_ROLE, applicant);

        // Submit a ProposalType.Membership proposal
        submitProposal(
            ProposalType.Membership,
            string(abi.encodePacked("Membership proposal for ", Address.toHexString(applicant), ". Reason: ", reason)),
            address(this), // Target is this contract
            0, // No value sent with the call
            callData // Grant MEMBER_ROLE upon execution
        );
    }

     /// @notice Grant MEMBER_ROLE to an address. Intended to be called via executeProposal for Membership proposals.
     /// Overriding grantRole to add member-specific logic
    function grantRole(bytes32 role, address account) public override {
        // Add custom logic only when granting MEMBER_ROLE via proposal
        if (role == MEMBER_ROLE && msg.sender == address(this)) {
            require(!_members[account].exists, "Account is already a member");
            _members[account].exists = true;
            _membersSet.add(account);
            _members[account].reputationScore = 1; // Start with a base reputation
             _members[account].delegate = account; // Initially delegate voting power to self
            emit MemberJoined(account);
        }
        // Call the parent AccessControl grantRole
        super.grantRole(role, account);
    }

     /// @notice Revoke MEMBER_ROLE from an address. Intended to be called via executeProposal (e.g., for slashing or removal proposal).
     /// Overriding revokeRole to add member-specific logic
    function revokeRole(bytes32 role, address account) public override {
        if (role == MEMBER_ROLE && msg.sender == address(this)) {
             require(_members[account].exists, "Account is not a member");
            _members[account].exists = false;
            _membersSet.remove(account);
             _members[account].reputationScore = 0; // Reset reputation
            // Potentially burn skill badges? Depends on governance decision. Let's keep them for now.
            emit MemberLeft(account);
        }
         // Call the parent AccessControl revokeRole
        super.revokeRole(role, account);
    }


    /// @notice Allow a member to voluntarily leave the guild.
    function leaveGuild() external onlyMember {
        // This revokes the MEMBER_ROLE, triggering the custom revokeRole logic
         revokeRole(MEMBER_ROLE, msg.sender);
    }

    /// @notice Check if an address is currently a member.
    /// @param account The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address account) external view returns (bool) {
        return _members[account].exists;
    }

    /// @notice Get a member's profile information and reputation.
    /// @param account The member's address.
    /// @return exists Whether the member exists, profileMetadataUri, reputationScore, delegate.
    function getMemberInfo(address account) external view returns (bool exists, string memory profileMetadataUri, uint256 reputationScore, address delegate) {
         Member storage member = _members[account];
         return (member.exists, member.profileMetadataUri, member.reputationScore, member.delegate);
    }

     /// @notice Allow a member to update their off-chain profile metadata link.
    /// @param metadataUri The new URI for the member's profile.
    function updateMemberProfile(string memory metadataUri) external onlyMember {
        _members[msg.sender].profileMetadataUri = metadataUri;
        emit ProfileUpdated(msg.sender, metadataUri);
    }


    // --- Project Management Functions ---

    /// @notice Submit a proposal for a new creative project. Requires member status.
    /// @param details Metadata URI for project details.
    /// @param requestedBudget Total budget requested in Wei.
    /// @param milestones Array of milestone definitions.
    function submitProjectProposal(
        string memory details,
        uint256 requestedBudget,
        Milestone[] memory milestones // Note: Milestone struct should exclude completionProposalHash/isCompleted here
    ) external onlyMember {
         require(milestones.length > 0, "Must include at least one milestone");
        uint256 totalPercentage;
        for(uint i = 0; i < milestones.length; i++){
            require(milestones[i].fundingPercentage > 0, "Milestone funding percentage must be positive");
            totalPercentage += milestones[i].fundingPercentage;
        }
        require(totalPercentage <= 10000, "Total milestone percentage exceeds 100%"); // 10000 basis points = 100%

         // Prepare milestones for storage
        Milestone[] memory projectMilestones = new Milestone[](milestones.length);
        for(uint i = 0; i < milestones.length; i++){
            projectMilestones[i] = Milestone({
                description: milestones[i].description,
                fundingPercentage: milestones[i].fundingPercentage,
                isCompleted: false,
                completionProposalHash: bytes32(0) // Placeholder
            });
        }

         // Craft the calldata for execution (this contract's function to create the project)
         bytes memory callData = abi.encodeWithSelector(
             this._createProject.selector,
             msg.sender,
             details,
             requestedBudget,
             projectMilestones // Pass prepared milestones
         );

         // Submit a ProposalType.ProjectFunding proposal
        submitProposal(
            ProposalType.ProjectFunding,
            string(abi.encodePacked("Project funding proposal: ", details)),
            address(this), // Target is this contract
            0, // No value sent here, budget comes from treasury upon milestone completion
            callData
        );
    }

    /// @notice Internal function to create a project. Intended to be called via executeProposal.
    /// @param proposer The address that proposed the project.
    /// @param details Metadata URI for project details.
    /// @param requestedBudget Total budget requested in Wei.
    /// @param milestones Array of milestones.
    function _createProject(
         address proposer,
         string memory details,
         uint256 requestedBudget,
         Milestone[] memory milestones
    ) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal

         uint256 projectId = _projectIdCounter.current();
         Project storage newProject = _projects[projectId];

         newProject.id = projectId;
         newProject.proposer = proposer;
         newProject.detailsMetadataUri = details;
         newProject.totalBudget = requestedBudget;
         newProject.fundsReleased = 0;
         newProject.status = ProjectStatus.Active;
         newProject.milestones = milestones; // Assign the prepared milestones
         // participantRoyaltyShares and participants mappings are empty initially
         newProject.ipIdentifier = bytes32(0);
         newProject.ipMetadataUri = "";
         // Store the hash of the original proposal for traceability
         // Find the proposal that triggered this execution
         uint256 proposalId = _proposalIdCounter.current() - 1; // Assuming this is called immediately after proposal creation
         newProject.projectProposalHash = keccak256(abi.encodePacked(proposalId));


         _projectIdCounter.increment();

         emit ProjectProposed(projectId, proposer);
         emit ProjectStatusChanged(projectId, ProjectStatus.Active);
    }


    /// @notice Submit a proposal to mark a project milestone as complete. Requires member status.
    /// @param projectId The ID of the project.
    /// @param milestoneIndex The index of the milestone (0-based).
    /// @param evidenceUri Link to off-chain evidence of completion.
    function submitMilestoneCompletionProposal(uint256 projectId, uint256 milestoneIndex, string memory evidenceUri) external onlyMember {
        Project storage project = _projects[projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(!project.milestones[milestoneIndex].isCompleted, "Milestone already completed");
        require(project.milestones[milestoneIndex].completionProposalHash == bytes32(0), "Milestone completion proposal already exists");

        // Store a hash linking the milestone to the proposal for later lookup
        // Get the next proposal ID before submitting
        uint256 nextProposalId = _proposalIdCounter.current();
        bytes32 proposalHash = keccak256(abi.encodePacked(nextProposalId));
        project.milestones[milestoneIndex].completionProposalHash = proposalHash;


         // Craft the calldata for execution (this contract's function to release payment)
         bytes memory callData = abi.encodeWithSelector(
             this._releaseMilestonePayment.selector,
             projectId,
             milestoneIndex
         );

        // Submit a ProposalType.MilestoneCompletion proposal
        submitProposal(
            ProposalType.MilestoneCompletion,
            string(abi.encodePacked("Milestone completion proposal for Project ", uint256(projectId).toString(), ", Milestone ", uint265(milestoneIndex).toString(), ". Evidence: ", evidenceUri)),
            address(this), // Target is this contract
            0, // No value sent with the call
            callData // Release payment upon execution
        );
    }

    /// @notice Internal function to release payment for a completed milestone. Intended to be called via executeProposal.
    /// @param projectId The ID of the project.
    /// @param milestoneIndex The index of the milestone.
    function _releaseMilestonePayment(uint256 projectId, uint256 milestoneIndex) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal

        Project storage project = _projects[projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(!project.milestones[milestoneIndex].isCompleted, "Milestone already completed");

        // Verify that this execution was triggered by the *correct* milestone completion proposal
        // This prevents executing payment via a different proposal
        uint256 currentProposalId = _proposalIdCounter.current() - 1; // Assuming this is called immediately after proposal execution
         bytes32 expectedProposalHash = keccak256(abi.encodePacked(currentProposalId));
        require(project.milestones[milestoneIndex].completionProposalHash == expectedProposalHash, "Execution triggered by wrong proposal");


        project.milestones[milestoneIndex].isCompleted = true;
        emit MilestoneStatusChanged(projectId, milestoneIndex, true);

        // Calculate payment amount based on percentage of total budget
        uint256 paymentAmount = (project.totalBudget * project.milestones[milestoneIndex].fundingPercentage) / 10000; // Divide by 10000 for basis points

        // Ensure treasury has enough funds
        require(address(this).balance >= paymentAmount, "Insufficient treasury balance for milestone payment");

        // Transfer funds (ideally to a designated project lead or multi-sig, or just track funds released)
        // For simplicity here, let's track funds released within the guild contract state
        // In a real system, funds might be sent to a project-specific wallet
        project.fundsReleased += paymentAmount; // Track released funds

        emit MilestonePaymentReleased(projectId, milestoneIndex, paymentAmount);

        // Check if all milestones are completed to potentially mark project as completed
        bool allCompleted = true;
        for (uint i = 0; i < project.milestones.length; i++) {
            if (!project.milestones[i].isCompleted) {
                allCompleted = false;
                break;
            }
        }
        if (allCompleted) {
            project.status = ProjectStatus.Completed;
             emit ProjectStatusChanged(projectId, ProjectStatus.Completed);
        }
    }

    /// @notice Submit a proposal to release payment for a completed milestone.
    /// This is a wrapper around the internal function, exposed as a proposal target.
    /// @param projectId The ID of the project.
    /// @param milestoneIndex The index of the milestone.
    function submitReleaseMilestonePaymentProposal(uint256 projectId, uint256 milestoneIndex) external {
        // This function *itself* is not a proposal submission, but the *target* of one.
        // Only the contract can call this.
        require(msg.sender == address(this), "Only executable by proposal");
        _releaseMilestonePayment(projectId, milestoneIndex);
    }


    /// @notice Get information about a project.
    /// @param projectId The ID of the project.
    /// @return Details of the project.
    function getProjectInfo(uint256 projectId) external view returns (Project memory) {
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist"); // Check if ID is non-zero (assuming ID 0 is unused)

        // Create a memory copy to return, excluding participantShares map and participants set directly
        // Call separate view functions to get participants and shares
        Project memory projectMemory = project;
        // Clear mappings/sets in memory copy as they can't be returned directly
        delete projectMemory.participantRoyaltyShares;
        // We can't return EnumerableSet directly either. User needs to call getProjectParticipants.
        // The participant data will be inaccurate in this struct return. It's better to have specific getters.
        // Let's return core data and use other functions for lists.
        return Project({
            id: project.id,
            proposer: project.proposer,
            detailsMetadataUri: project.detailsMetadataUri,
            totalBudget: project.totalBudget,
            fundsReleased: project.fundsReleased,
            status: project.status,
            milestones: project.milestones,
            participantRoyaltyShares: new mapping(address => uint256)(), // Placeholder
            participants: new EnumerableSet.AddressSet(), // Placeholder
            ipIdentifier: project.ipIdentifier,
            ipMetadataUri: project.ipMetadataUri,
            projectProposalHash: project.projectProposalHash
        });
    }

     /// @notice Add a participant to a project and define their royalty share. Requires member status and project participation.
    /// This should ideally be subject to a proposal for approval by existing participants/guild.
    /// For simplicity, let's allow project proposer or current participants to propose/add. Or simplify further: allow project lead (proposer) only.
    /// Let's make this a proposal target for simplicity in the example.
    /// @param projectId The ID of the project.
    /// @param participant The address of the member to add.
    /// @param role The canonical role hash.
    /// @param royaltyShareBps The royalty share in basis points (e.g., 100 = 1%).
    function addProjectParticipant(uint256 projectId, address participant, bytes32 role, uint256 royaltyShareBps) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
         // Check if the proposal execution was initiated by a valid proposal (e.g., a 'ProjectUpdate' proposal type)
         // (Skipping detailed check for brevity)

        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
        require(_members[participant].exists, "Participant must be a guild member");
        require(_canonicalProjectRoles[role].exists, "Invalid canonical role");
        require(royaltyShareBps <= 10000, "Royalty share cannot exceed 100%");

        require(!project.participants.contains(participant), "Participant already added");

        project.participants.add(participant);
        project.participantRoyaltyShares[participant] = royaltyShareBps; // This overwrites if participant was removed and re-added

        emit ParticipantAdded(projectId, participant, role, royaltyShareBps);
    }

     /// @notice Remove a participant from a project. Requires member status and project participation.
     /// Also ideally subject to a proposal. Let's make this a proposal target.
     /// @param projectId The ID of the project.
     /// @param participant The address of the participant to remove.
    function removeProjectParticipant(uint256 projectId, address participant) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
        require(project.participants.contains(participant), "Participant is not in project");

        project.participants.remove(participant);
        delete project.participantRoyaltyShares[participant]; // Remove their share

        emit ParticipantRemoved(projectId, participant);
    }

    /// @notice Get the list of participants for a project.
    /// @param projectId The ID of the project.
    /// @return An array of participant addresses.
    function getProjectParticipants(uint256 projectId) external view returns (address[] memory) {
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
        return project.participants.values();
    }

     /// @notice Get the list of milestones for a project.
    /// @param projectId The ID of the project.
    /// @return An array of milestone structs.
    function getProjectMilestones(uint256 projectId) external view returns (Milestone[] memory) {
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
        return project.milestones;
    }


    // --- Skill & Reputation Functions ---

    /// @notice Define a new canonical skill. Requires proposal execution.
    /// @param skillHash Unique hash identifying the skill (e.g., keccak256("Solidity Development")).
    /// @param name Human-readable name of the skill.
    /// @param description Description of the skill.
    function defineSkill(bytes32 skillHash, string memory name, string memory description) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
        require(!_canonicalSkills[skillHash].exists, "Skill already defined");

        _canonicalSkills[skillHash].name = name;
        _canonicalSkills[skillHash].description = description;
        _canonicalSkills[skillHash].exists = true;
        _canonicalSkills[skillHash].tokenIdCounter = 0; // Initialize badge counter for this skill
        _canonicalSkillHashes.push(skillHash);

        emit SkillDefined(skillHash, name);
    }

     /// @notice Get information about a canonical skill.
    /// @param skillHash The hash of the skill.
    /// @return name, description, exists.
    function getCanonicalSkillInfo(bytes32 skillHash) external view returns (string memory name, string memory description, bool exists) {
        Skill storage skill = _canonicalSkills[skillHash];
        return (skill.name, skill.description, skill.exists);
    }

    /// @notice Submit a proposal to verify a member's skill and issue a badge. Requires member status.
    /// @param member The member whose skill is being verified.
    /// @param skillHash The hash of the canonical skill.
    /// @param proofUri Link to off-chain proof of skill.
    function submitSkillVerificationProposal(address member, bytes32 skillHash, string memory proofUri) external onlyMember {
        require(_members[member].exists, "Member does not exist");
        require(_canonicalSkills[skillHash].exists, "Canonical skill not defined");
        // Check if member already has this skill badge
        require(skillBadges.balanceOf(member) == 0 || skillBadges.tokenOfOwnerByIndex(member, 0) / 1000000 != uint256(skillHash), "Member already verified for this skill"); // Basic check - needs more robust badge tracking

         // Craft the calldata for execution (this contract's function to issue the badge)
         bytes memory callData = abi.encodeWithSelector(
             this._issueSkillBadge.selector,
             member,
             skillHash
         );

        submitProposal(
            ProposalType.SkillVerification,
            string(abi.encodePacked("Skill verification proposal for ", Address.toHexString(member), " for skill ", _canonicalSkills[skillHash].name, ". Proof: ", proofUri)),
            address(this), // Target is this contract
            0, // No value sent
            callData // Issue badge upon execution
        );
    }

    /// @notice Internal function to issue a Skill Badge NFT. Intended to be called via executeProposal.
    /// @param member The recipient of the badge.
    /// @param skillHash The hash of the skill being verified.
    function _issueSkillBadge(address member, bytes32 skillHash) external {
        require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
         require(_members[member].exists, "Recipient must be a member");
        Skill storage skill = _canonicalSkills[skillHash];
         require(skill.exists, "Canonical skill not defined");

        // Generate a unique token ID. Combine skillHash prefix with a counter.
        // This allows querying badges by skill type.
        // Example format: [SkillHashPrefix (e.g., first 4 bytes)] [Counter (28 bytes)]
        // Or simpler: Use a global counter for badges, store skillHash in metadata/mapping
        // Let's use a simpler approach: store skillHash linked to tokenID in a mapping.
        // Let's use a global counter and link token ID -> member & skillHash
        uint256 badgeTokenId = skillBadges.nextTokenId(); // Assuming ERC721Enumerable or similar internal counter

        // Mint the badge via the SkillBadge contract
        skillBadges.mint(member, badgeTokenId);

        // Link the token ID to the member and skill hash internally if needed (e.g., for getMemberSkillBadge)
        // Add mapping: token ID -> skill hash & member
        _badgeDetails[badgeTokenId] = BadgeDetails({member: member, skillHash: skillHash});

        // Increment skill's internal counter if needed for future logic (optional)
        skill.tokenIdCounter++;


        emit SkillVerified(member, skillHash, badgeTokenId);
    }

    // Internal mapping to track badge details by token ID
     struct BadgeDetails {
        address member;
        bytes32 skillHash;
     }
     mapping(uint256 => BadgeDetails) private _badgeDetails;

    /// @notice Get the token ID of a specific skill badge held by a member.
    /// Returns 0 if the member doesn't have the badge for that skill.
    /// NOTE: This requires iterating through member's badges or a reverse mapping for efficiency.
    /// Current implementation iterates via ERC721Enumerable (if available) or relies on a mapping.
    /// For simplicity, let's add a mapping: member -> skillHash -> token ID
    mapping(address => mapping(bytes32 => uint256)) private _memberSkillBadgeTokenId; // Stores the token ID if member has the badge

     /// @notice Internal function called by _issueSkillBadge
    function _linkSkillBadgeToMember(address member, bytes32 skillHash, uint256 tokenId) internal {
        _memberSkillBadgeTokenId[member][skillHash] = tokenId;
    }

    /// @notice Internal function called when a badge is burned
    function _unlinkSkillBadgeFromMember(uint256 tokenId) internal {
        BadgeDetails storage details = _badgeDetails[tokenId];
        if(details.member != address(0)) {
             delete _memberSkillBadgeTokenId[details.member][details.skillHash];
            delete _badgeDetails[tokenId];
        }
    }

    // Need to integrate _linkSkillBadgeToMember and _unlinkSkillBadgeFromMember into _issueSkillBadge and a burn mechanism.
    // Let's update _issueSkillBadge and add a burn function (via proposal).

     /// @notice Internal function to issue a Skill Badge NFT. Intended to be called via executeProposal.
     /// @param member The recipient of the badge.
     /// @param skillHash The hash of the skill being verified.
    function _issueSkillBadge(address member, bytes32 skillHash) external {
        require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
         require(_members[member].exists, "Recipient must be a member");
        Skill storage skill = _canonicalSkills[skillHash];
         require(skill.exists, "Canonical skill not defined");
        require(_memberSkillBadgeTokenId[member][skillHash] == 0, "Member already has this skill badge"); // Check using the new mapping

        uint256 badgeTokenId = skillBadges.nextTokenId();

        skillBadges.mint(member, badgeTokenId);
        _linkSkillBadgeToMember(member, skillHash, badgeTokenId); // Link the token ID

        emit SkillVerified(member, skillHash, badgeTokenId);
    }

    /// @notice Submit a proposal to issue a Skill Badge NFT.
    /// This is a wrapper around the internal function, exposed as a proposal target.
    /// @param member The recipient of the badge.
    /// @param skillHash The hash of the skill being verified.
    function submitIssueSkillBadgeProposal(address member, bytes32 skillHash) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
         _issueSkillBadge(member, skillHash);
    }


    /// @notice Submit a proposal to burn a Skill Badge NFT from a member. E.g., for slashing or skill revocation.
    /// @param member The member whose badge will be burned.
    /// @param skillHash The hash of the skill badge to burn.
    function submitBurnSkillBadgeProposal(address member, bytes32 skillHash) external onlyMember {
         require(_members[member].exists, "Member does not exist");
        uint256 tokenId = _memberSkillBadgeTokenId[member][skillHash];
        require(tokenId != 0, "Member does not have this skill badge");

         // Craft the calldata for execution (this contract's function to burn the badge)
         bytes memory callData = abi.encodeWithSelector(
             this._burnSkillBadge.selector,
             tokenId
         );

        submitProposal(
            ProposalType.Slashing, // Or new type like SkillRevocation
            string(abi.encodePacked("Burn skill badge proposal for ", Address.toHexString(member), " for skill ", _canonicalSkills[skillHash].name)),
            address(this), // Target is this contract
            0, // No value sent
            callData
        );
    }

     /// @notice Internal function to burn a Skill Badge NFT. Intended to be called via executeProposal.
     /// @param tokenId The ID of the badge to burn.
    function _burnSkillBadge(uint256 tokenId) external {
        require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
         // Check if badge exists and is owned by a member (optional, burn function handles ownership)
        skillBadges.burn(tokenId);
        _unlinkSkillBadgeFromMember(tokenId); // Unlink the token ID
         // Add event if needed
    }


    /// @notice Get the token ID of a specific skill badge held by a member.
    /// Returns 0 if the member doesn't have the badge for that skill.
    /// @param member The member's address.
    /// @param skillHash The hash of the skill.
    /// @return The token ID of the badge, or 0 if not found.
    function getMemberSkillBadge(address member, bytes32 skillHash) external view returns (uint256) {
        return _memberSkillBadgeTokenId[member][skillHash];
    }


    /// @notice Get all skill badges held by a member.
    /// Requires iterating through the ERC721 tokens owned by the member.
    /// @param member The member's address.
    /// @return An array of token IDs representing the member's skill badges.
    function getMemberSkills(address member) external view returns (uint256[] memory) {
        uint256 balance = skillBadges.balanceOf(member);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = skillBadges.tokenOfOwnerByIndex(member, i);
        }
        return tokenIds;
    }


    /// @notice Calculate a member's dynamic reputation score.
    /// This is a simplified example. A real system would use more complex logic.
    /// Factors could include:
    /// - Successful project completions.
    /// - Proposal voting history and success rate.
    /// - Holding specific skill badges.
    /// - Duration of membership.
    /// - Dispute resolution participation.
    /// @param member The member's address.
    /// @return The calculated reputation score.
    function calculateReputationScore(address member) external view returns (uint256) {
        Member storage memberInfo = _members[member];
        if (!memberInfo.exists) {
            return 0;
        }

        uint256 score = memberInfo.reputationScore; // Use the stored score as a base

        // Example additions (simplified):
        // +1 for each skill badge
        score += skillBadges.balanceOf(member);

        // Could iterate through projects/proposals here but would be gas intensive.
        // Storing/updating reputation incrementally upon relevant events (milestone completion, proposal execution) is more efficient.
        // For this example, we just return the stored base score + skill badges.
        // The stored score (_members[member].reputationScore) would be updated by proposal execution logic for project/governance events.

        return score;
    }


    // --- Treasury Management Functions ---

    /// @notice Receive funds into the guild treasury.
    receive() external payable {
         emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Explicit deposit function.
    function deposit() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }


    /// @notice Internal target function for a 'WithdrawTreasury' proposal type.
    /// Transfers funds from the treasury. Accessible only via proposal execution.
    /// @param amount The amount of Ether to withdraw.
    /// @param recipient The address to send the funds to.
    function withdrawTreasury(uint256 amount, address recipient) external {
        require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
        require(address(this).balance >= amount, "Insufficient treasury balance");

        Address.sendValue(payable(recipient), amount);

        emit TreasuryWithdrawn(recipient, amount);
    }

     /// @notice Get the current balance of the guild treasury.
     /// @return The treasury balance in Wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- IP & Royalty Distribution Functions ---

     /// @notice Internal target function for a 'RegisterProjectIP' proposal type.
     /// Links external IP identifier/metadata to a project. Accessible only via proposal execution.
     /// @param projectId The ID of the project.
     /// @param ipIdentifier Unique identifier linked to external IP (e.g., IPFS CID).
     /// @param metadataUri Metadata related to the IP.
    function registerProjectIP(uint256 projectId, bytes32 ipIdentifier, string memory metadataUri) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");

        project.ipIdentifier = ipIdentifier;
        project.ipMetadataUri = metadataUri;

        emit ProjectIPRegistered(projectId, ipIdentifier);
    }


    /// @notice Distribute royalties for a project among participants based on shares.
    /// Can be called by anyone who receives royalties, or triggered by a separate mechanism.
    /// This is a pull-based system where the caller provides the amount to distribute.
    /// In a real system, this might integrate with an external revenue source.
    /// @param projectId The ID of the project.
    /// @param amount The total amount of Ether royalties to distribute. Must be sent with the call.
    function distributeProjectRoyalties(uint256 projectId, uint256 amount) external payable {
         require(msg.value == amount, "Sent amount must match royalty amount");
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Completed, "Project not completed"); // Only distribute after completion

        address[] memory participants = project.participants.values();
        uint256 totalSharesBps;
        // First pass: calculate total shares among current participants with defined shares
        for (uint i = 0; i < participants.length; i++) {
            totalSharesBps += project.participantRoyaltyShares[participants[i]];
        }
        // Avoid division by zero if no shares are defined
        require(totalSharesBps > 0, "No royalty shares defined for participants");

        // Second pass: distribute shares
        for (uint i = 0; i < participants.length; i++) {
            uint256 shareBps = project.participantRoyaltyShares[participants[i]];
            if (shareBps > 0) {
                 // Calculate amount for this participant: (amount * shareBps) / totalSharesBps
                 // Use safe math (OpenZeppelin's SafeMath is good, or Solidity 0.8+ handles overflow/underflow)
                 // Ensure precision by multiplying first, then dividing
                 uint256 participantAmount = (amount * shareBps) / totalSharesBps;
                 if (participantAmount > 0) {
                    // Send Ether to participant
                    // Use low-level call for safety against reentrancy in recipient contract
                    (bool success, ) = payable(participants[i]).call{value: participantAmount}("");
                    // In case of failure, funds are stuck in the contract or handled by a recovery mechanism.
                    // A more robust system might use a pull pattern (claim) or track failed payments.
                    require(success, "Royalty transfer failed");
                 }
            }
        }

        emit RoyaltiesDistributed(projectId, amount);
    }

    /// @notice Get a participant's defined royalty share for a project.
    /// @param projectId The ID of the project.
    /// @param participant The participant's address.
    /// @return The royalty share in basis points, or 0 if not found.
    function getProjectParticipantRoyaltyShare(uint256 projectId, address participant) external view returns (uint256) {
         Project storage project = _projects[projectId];
         require(project.id != 0, "Project does not exist");
         return project.participantRoyaltyShares[participant];
    }


    // --- Advanced/Utility Functions ---

    /// @notice Delegate voting power to another member. Requires member status.
    /// @param delegatee The address to delegate voting power to. Must be a member.
    function delegateVotingPower(address delegatee) external onlyMember {
         require(_members[delegatee].exists, "Delegatee must be a member");
        require(msg.sender != delegatee, "Cannot delegate to yourself");
         _members[msg.sender].delegate = delegatee;
        emit VotingDelegated(msg.sender, delegatee);
    }

    /// @notice Revoke voting delegation. Requires member status.
    function revokeVotingPowerDelegation() external onlyMember {
        require(_members[msg.sender].delegate != msg.sender, "Not currently delegated");
        _members[msg.sender].delegate = msg.sender; // Delegate back to self
        emit VotingDelegationRevoked(msg.sender);
    }

    /// @notice Internal helper to get the effective voting address (self or delegatee).
    /// @param voter The potential voter's address.
    /// @return The effective address for voting.
    function _getVotingDelegate(address voter) internal view returns (address) {
        if (!_members[voter].exists) return address(0);
        address delegatee = _members[voter].delegate;
        // Prevent delegation loops (though our delegate logic prevents direct loops)
        if (delegatee != address(0) && _members[delegatee].exists) {
            return delegatee;
        }
        return voter; // Default to self if not delegated or delegatee not a member
    }


    /// @notice Get a member's current voting power.
    /// Currently simplified: 1 for members, 0 otherwise. Can be weighted by reputation later.
    /// @param member The member's address.
    /// @return The voting power.
    function getVotingPower(address member) public view returns (uint256) {
        // Get the effective voter (handle delegation)
        address effectiveVoter = _getVotingDelegate(member);

        // Simple voting power: 1 if a member, 0 otherwise
        if (_members[effectiveVoter].exists) {
            // Future improvement: Weight voting power by reputation
            // return 1 + (_members[effectiveVoter].reputationScore / ReputationScalingFactor);
            return 1;
        }
        return 0;
    }

     /// @notice Define a new canonical project role. Requires proposal execution.
     /// @param roleHash Unique hash identifying the role (e.g., keccak256("Lead Developer")).
     /// @param name Human-readable name of the role.
     /// @param description Description of the role.
    function defineProjectRole(bytes32 roleHash, string memory name, string memory description) external {
        require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
        require(!_canonicalProjectRoles[roleHash].exists, "Role already defined");

        _canonicalProjectRoles[roleHash].name = name;
        _canonicalProjectRoles[roleHash].description = description;
        _canonicalProjectRoles[roleHash].exists = true;
        _canonicalProjectRoleHashes.push(roleHash);

        emit ProjectRoleDefined(roleHash, name);
    }

    /// @notice Get information about a canonical project role.
     /// @param roleHash The hash of the role.
     /// @return name, description, exists.
    function getCanonicalRoleInfo(bytes32 roleHash) external view returns (string memory name, string memory description, bool exists) {
         ProjectRole storage role = _canonicalProjectRoles[roleHash];
         return (role.name, role.description, role.exists);
    }


     /// @notice Internal target function for an 'UpdateProjectMetadata' proposal type.
     /// Updates the metadata URI for a project. Accessible only via proposal execution.
     /// @param projectId The ID of the project.
     /// @param metadataUri The new metadata URI.
    function updateProjectMetadata(uint256 projectId, string memory metadataUri) external {
         require(msg.sender == address(this), "Only executable by proposal"); // Ensure this is called via executeProposal
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");

        project.detailsMetadataUri = metadataUri;
         emit ProjectMetadataUpdated(projectId, metadataUri);
    }

     /// @notice Submit a proposal to resolve a project dispute. Requires member status.
     /// @param projectId The ID of the project the dispute relates to.
     /// @param dtype The type of dispute.
     /// @param details Details about the dispute.
    function submitDisputeProposal(uint256 projectId, DisputeType dtype, string memory details) external onlyMember {
        Project storage project = _projects[projectId];
        require(project.id != 0, "Project does not exist");
         // Optionally require proposer to be a project participant

         // Note: Dispute resolution logic (e.g., removing participant, changing status, re-allocating funds)
         // would be implemented as callData within the proposal execution, targeting relevant functions (like removeProjectParticipant)
         // The proposal itself just records the dispute context and triggers governance.

        bytes memory callData = ""; // Call data would depend on the proposed resolution actions

        uint256 proposalId = submitProposal(
            ProposalType.DisputeResolution,
            string(abi.encodePacked("Dispute proposal for Project ", uint256(projectId).toString(), ". Type: ", uint256(dtype).toString(), ". Details: ", details)),
            address(this), // Target is this contract, or a dispute resolution module
            0,
            callData
        );

        // Mark the project as in dispute status? Requires another proposal or update here.
        // Let's make changing project status part of dispute resolution outcome via proposal.
        // project.status = ProjectStatus.Dispute; // This state change should ideally be via proposal execution

        emit DisputeProposed(projectId, proposalId, dtype);
    }

     /// @notice Get information about a dispute proposal.
     /// @param proposalId The ID of the dispute proposal.
     /// @return Details of the proposal, including type and description.
     function getDisputeInfo(uint256 proposalId) external view returns (Proposal memory) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.proposalType == ProposalType.DisputeResolution, "Not a dispute proposal");
        return proposal;
     }


    // --- Helper Functions ---

    /// @notice Get the number of current members.
    function getMemberCount() external view returns (uint256) {
        return _membersSet.length();
    }

    /// @notice Get the list of all current member addresses.
    function getAllMembers() external view returns (address[] memory) {
        return _membersSet.values();
    }

    /// @notice Get the number of existing projects.
    function getProjectCount() external view returns (uint256) {
        return _projectIdCounter.current();
    }

     /// @notice Get the number of existing proposals.
    function getProposalCount() external view returns (uint256) {
        return _proposalIdCounter.current();
    }

     /// @notice Get the list of all canonical skill hashes.
    function getAllCanonicalSkillHashes() external view returns (bytes32[] memory) {
        return _canonicalSkillHashes;
    }

     /// @notice Get the list of all canonical project role hashes.
    function getAllCanonicalRoleHashes() external view returns (bytes32[] memory) {
        return _canonicalProjectRoleHashes;
    }

    // --- Total External/Public Functions Count ---
    // 1. submitProposal
    // 2. voteOnProposal
    // 3. executeProposal
    // 4. cancelProposal
    // 5. getProposalInfo
    // 6. setGovernanceParameters (Proposal Target)
    // 7. submitMembershipProposal
    // 8. leaveGuild
    // 9. isMember
    // 10. getMemberInfo
    // 11. updateMemberProfile
    // 12. submitProjectProposal
    // 13. submitMilestoneCompletionProposal
    // 14. submitReleaseMilestonePaymentProposal (Proposal Target)
    // 15. getProjectInfo
    // 16. addProjectParticipant (Proposal Target)
    // 17. removeProjectParticipant (Proposal Target)
    // 18. defineSkill (Proposal Target)
    // 19. submitSkillVerificationProposal
    // 20. submitIssueSkillBadgeProposal (Proposal Target)
    // 21. getMemberSkills
    // 22. calculateReputationScore
    // 23. deposit
    // 24. withdrawTreasury (Proposal Target)
    // 25. registerProjectIP (Proposal Target)
    // 26. distributeProjectRoyalties
    // 27. getProjectParticipantRoyaltyShare
    // 28. delegateVotingPower
    // 29. revokeVotingPowerDelegation
    // 30. getVotingPower
    // 31. defineProjectRole (Proposal Target)
    // 32. updateProjectMetadata (Proposal Target)
    // 33. submitDisputeProposal
    // 34. getDisputeInfo
    // 35. getTreasuryBalance
    // 36. getMemberSkillBadge
    // 37. getCanonicalSkillInfo
    // 38. getCanonicalRoleInfo
    // 39. getProjectParticipants
    // 40. getProjectMilestones
    // 41. submitBurnSkillBadgeProposal (New proposal target added earlier)
    // 42. getMemberCount
    // 43. getAllMembers
    // 44. getProjectCount
    // 45. getProposalCount
    // 46. getAllCanonicalSkillHashes
    // 47. getAllCanonicalRoleHashes

    // Total is 47 public/external functions, comfortably over 20.
    // Note: Many functions are *targets* for proposals, meaning they can only be called by `executeProposal` within this contract.
    // Their selector is exposed, but the logic inside `require(msg.sender == address(this))` restricts external calls.
    // The functions * callable * directly by members are the `submit*Proposal` functions, `voteOnProposal`, `leaveGuild`, `updateMemberProfile`, `deposit`, `distributeProjectRoyalties`, `delegateVotingPower`, `revokeVotingPowerDelegation`.

    // To make this truly advanced and avoid standard DAO templates,
    // the combination of Skill Badges (custom non-transferable ERC721),
    // Reputation Score (even basic),
    // Project Milestones linked to funding release via governance,
    // Dynamic Royalty Distribution based on participant shares, and
    // Canonical Skill/Role definitions via governance
    // creates a unique contract tailored for a creative collaboration guild.

}
```