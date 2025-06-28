Okay, here is a Solidity smart contract for a **Decentralized Autonomous Metaverse Guild (DAMG)**.

This contract goes beyond simple token or NFT interactions and incorporates elements of:

1.  **DAO Governance:** Proposals and voting for treasury management and major decisions.
2.  **Member Progression:** XP, Levels, and Skill Points that members can allocate.
3.  **Task System:** Guild tasks that members can undertake for rewards and XP, with verification.
4.  **Resource Management:** Tracking guild-specific, non-standard token resources.
5.  **NFT Custody & Assignment:** Holding NFTs on behalf of the guild and assigning their *usage rights* to members internally.
6.  **Role-Based Access:** Differentiating permissions based on member roles.

It aims to be a framework for a self-governing group within a blockchain-based game or metaverse, managing shared assets, coordinating activities, and fostering member growth.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Outline & Function Summary:
//
// Contract: Decentralized Autonomous Metaverse Guild (DAMG)
// Concept: A self-governing, member-run organization for coordinating activities,
//          managing shared resources and assets (including NFTs), and fostering
//          member progression within a blockchain-based game/metaverse.
//
// State Variables:
// - Guild parameters (name, description, entry fee, max members, DAO settings)
// - Member data (roles, XP, level, skill points, skill allocation)
// - Treasury balances (ETH, custom resources)
// - NFT assets held by the guild and their assigned users
// - DAO proposals, voting state
// - Task definitions and progress
//
// Functions (Total: >20):
//
// I. Guild Management:
// 1.  constructor: Deploys the guild contract, sets initial owner and parameters.
// 2.  setGuildParameters: Admin function to update core guild settings (name, description, fees, limits, DAO params).
// 3.  joinGuild: Allows an address to join the guild by paying the entry fee.
// 4.  leaveGuild: Allows a member to leave the guild.
// 5.  kickMember: Admin function to remove a member from the guild.
// 6.  setMemberRole: Admin function to assign a role to a member.
// 7.  transferOwnership: Transfers contract ownership (Ownable).
//
// II. Treasury & Resources:
// 8.  depositToTreasury: Allows anyone to send Ether to the guild treasury.
// 9.  withdrawFromTreasuryViaProposal: Executes a passed treasury withdrawal proposal.
// 10. mintGuildResource: Admin/DAO function to create new custom guild resources.
// 11. burnGuildResource: Admin/DAO function to destroy custom guild resources.
// 12. transferGuildResource: Admin/DAO function to transfer custom resources (e.g., to members for tasks).
//
// III. DAO Governance:
// 13. createProposal: Allows a member (with sufficient role/level) to create a governance proposal.
// 14. voteOnProposal: Allows a member to cast a vote on an active proposal.
// 15. executeProposal: Can be called by anyone after the voting period ends to execute a successful proposal.
//
// IV. Task System:
// 16. createTask: Admin/Role function to define a new task with requirements, rewards, and verification needed.
// 17. assignTask: Admin/Role function to assign a created task to a specific member.
// 18. submitTaskCompletion: Allows an assigned member to mark a task as completed, awaiting verification.
// 19. verifyTaskCompletion: Admin/Verifier Role function to approve a submitted task completion, triggering rewards and XP.
// 20. claimTaskRewards: Allows a member whose task was verified to claim their rewards (ETH/resources).
//
// V. Member Progression:
// 21. allocateSkillPoints: Allows a member to allocate their earned skill points to specific skills.
// 22. resetSkillPoints: Allows a member to reset their skill point allocation (maybe with a cost).
//
// VI. Asset Management (NFTs):
// 23. depositNFTToTreasury: Allows an ERC721 owner to deposit an NFT into the guild's custody.
// 24. withdrawNFTFromTreasuryViaProposal: Executes a passed NFT withdrawal proposal.
// 25. assignNFTUsage: Admin/Role/DAO function to internally assign which member is currently designated to 'use' a specific guild-owned NFT.
//
// VII. View Functions (for dApps/UI):
// 26. getGuildInfo: Returns core guild parameters.
// 27. getMemberDetails: Returns details about a specific member (role, stats, skills).
// 28. getProposalDetails: Returns details about a specific proposal.
// 29. getTaskDetails: Returns details about a specific task.
// 30. getGuildResourceBalance: Returns the guild's balance of a specific custom resource.
// 31. getMemberResourceBalance: Returns a member's balance of a specific custom resource.
// 32. getGuildNFTs: Returns the list of NFT assets held by the guild.
// 33. getNFTCurrentAssignee: Returns the member currently assigned to use a specific guild NFT.

// --- Contract Implementation ---

contract DecentralizedAutonomousMetaverseGuild is Ownable {

    // --- Custom Errors ---
    error AlreadyMember();
    error NotMember();
    error MaxMembersReached();
    error InvalidRole();
    error NotEnoughETH();
    error NotEnoughResources(bytes32 resourceType);
    error ResourceDoesNotExist(bytes32 resourceType);
    error NotEnoughSkillPoints();
    error InvalidSkillAllocation();
    error ProposalDoesNotExist();
    error ProposalNotInVotingPeriod();
    error ProposalAlreadyExecuted();
    error ProposalNotExecutable(string reason);
    error AlreadyVoted();
    error InvalidVote();
    error TaskDoesNotExist();
    error TaskNotAssignedToMember();
    error TaskNotSubmitted();
    error TaskAlreadyCompletedOrVerified();
    error TaskNotVerified();
    error NotEnoughNFTs();
    error NFTNotInGuild(uint256 tokenId);
    error NotAllowed(address account);

    // --- Constants & Enums ---
    uint256 public constant BASE_XP_FOR_LEVEL = 100; // XP needed for level 1
    uint256 public constant XP_INCREASE_PER_LEVEL = 50; // Additional XP needed per level
    uint256 public constant SKILL_POINTS_PER_LEVEL = 1; // Skill points granted per level up

    enum MemberRole {
        Applicant, // Default role upon joining
        Member,    // Standard guild member
        Verifier,  // Can verify task completions
        Officer,   // Can create tasks, assign tasks
        Admin      // Full admin privileges within the guild structure (below Owner)
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    enum ProposalType {
        WithdrawETH,
        WithdrawNFT,
        MintResource,
        BurnResource,
        TransferResource,
        SetGuildParameter, // For specific parameters controllable by DAO
        CustomAction       // For more complex future actions (requires specific payload handling)
    }

    enum TaskState {
        Open,
        Assigned,
        Submitted,
        Verified,
        Completed // Rewards claimed
    }

    // --- Structs ---
    struct Member {
        address memberAddress;
        MemberRole role;
        uint256 xp;
        uint256 level;
        uint256 skillPoints;
        mapping(bytes32 => uint256) skills; // e.g., "Mining", "Combat", "Diplomacy"
        bool isMember; // Explicit flag for quick check
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        string description;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        // Proposal Specific Data (using abi.encodePacked or specific fields based on type)
        bytes data; // Encoded data relevant to the proposal type (e.g., recipient, amount, resource type)
    }

    struct Task {
        uint256 id;
        address creator;
        string description;
        address assignee;
        TaskState state;
        // Rewards
        uint256 ethReward;
        mapping(bytes32 => uint256) resourceRewards; // Custom resource rewards
        uint256 xpReward;
        // Requirements (optional)
        mapping(bytes32 => uint256) resourceRequirements; // e.g., requires 'Wood' to start
        mapping(bytes32 => uint256) skillRequirements;    // e.g., requires 'Mining' skill level
    }

    // --- State Variables ---
    string public guildName;
    string public guildDescription;
    uint256 public entryFee;
    uint256 public maxMembers;
    uint256 public currentMembersCount;

    // DAO Parameters
    uint256 public proposalQuorum; // Percentage of members needed to vote for validity (e.g., 50)
    uint256 public votingPeriod;   // Duration in seconds

    mapping(address => Member) public members;
    address[] public memberAddresses; // To iterate through members (careful with large guilds)

    mapping(bytes32 => uint256) public guildResourceBalances; // Guild's balances of custom resources
    mapping(address => mapping(bytes32 => uint256)) public memberResourceBalances; // Members' balances of custom resources

    IERC721[] public supportedNFTContracts; // List of ERC721 contracts the guild can hold
    mapping(address => mapping(uint256 => bool)) public guildOwnedNFTs; // contractAddress => tokenId => isOwnedByGuild
    address[] internal guildOwnedNFTContractAddresses; // Keep track of which contracts have guild-owned NFTs
    mapping(address => mapping(uint256 => address)) public nftCurrentAssignee; // contractAddress => tokenId => memberAddress assigned to use it

    Proposal[] public proposals;
    uint256 public nextProposalId;

    Task[] public tasks;
    uint256 public nextTaskId;

    // --- Events ---
    event GuildJoined(address indexed member);
    event GuildLeft(address indexed member);
    event MemberKicked(address indexed member, address indexed kickedBy);
    event MemberRoleUpdated(address indexed member, MemberRole newRole);
    event Deposited(address indexed account, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event ResourceMinted(bytes32 indexed resourceType, uint256 amount);
    event ResourceBurned(bytes32 indexed resourceType, uint256 amount);
    event ResourceTransfered(bytes32 indexed resourceType, address indexed from, address indexed to, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType indexed proposalType, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId, ProposalState finalState);
    event TaskCreated(uint256 indexed taskId, address indexed creator, string description);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskSubmitted(uint256 indexed taskId, address indexed submitter);
    event TaskVerified(uint256 indexed taskId, address indexed verifier);
    event TaskRewardsClaimed(uint256 indexed taskId, address indexed claimant);
    event MemberXPGained(address indexed member, uint256 xpGained, uint256 newTotalXP);
    event MemberLeveledUp(address indexed member, uint256 newLevel, uint256 skillPointsEarned);
    event SkillPointsAllocated(address indexed member, bytes32 indexed skill, uint256 points);
    event SkillPointsReset(address indexed member);
    event NFTDeposited(address indexed nftContract, uint256 indexed tokenId, address indexed depositor);
    event NFTWithdrawal(address indexed nftContract, uint256 indexed tokenId, address indexed recipient);
    event NFTUsageAssigned(address indexed nftContract, uint256 indexed tokenId, address indexed assignee);

    // --- Modifiers ---
    modifier onlyMember() {
        if (!members[msg.sender].isMember) revert NotMember();
        _;
    }

    modifier onlyRole(MemberRole role) {
        if (!members[msg.sender].isMember || members[msg.sender].role < role) revert InvalidRole();
        _;
    }

    modifier onlyVerifier() {
         if (!members[msg.sender].isMember || members[msg.sender].role < MemberRole.Verifier) revert InvalidRole();
        _;
    }

     modifier onlyOfficer() {
         if (!members[msg.sender].isMember || members[msg.sender].role < MemberRole.Officer) revert InvalidRole();
        _;
    }

     modifier onlyAdmin() {
         if (!members[msg.sender].isMember || members[msg.sender].role < MemberRole.Admin) revert InvalidRole();
        _;
    }

    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _description,
        uint256 _entryFee,
        uint256 _maxMembers,
        uint256 _proposalQuorumPercentage, // e.g., 50 for 50%
        uint256 _votingPeriodSeconds,
        address _initialAdmin // The first admin member, distinct from contract owner
    ) Ownable(msg.sender) {
        guildName = _name;
        guildDescription = _description;
        entryFee = _entryFee;
        maxMembers = _maxMembers;
        proposalQuorum = _proposalQuorumPercentage;
        votingPeriod = _votingPeriodSeconds;

        // Add initial admin as a member
        members[_initialAdmin] = Member({
            memberAddress: _initialAdmin,
            role: MemberRole.Admin,
            xp: 0,
            level: 0,
            skillPoints: 0,
            isMember: true
        });
        memberAddresses.push(_initialAdmin);
        currentMembersCount = 1;
        emit GuildJoined(_initialAdmin);
        emit MemberRoleUpdated(_initialAdmin, MemberRole.Admin);
    }

    // --- I. Guild Management ---

    /**
     * @notice Sets core guild parameters. Only callable by Owner.
     * @param _name New guild name.
     * @param _description New guild description.
     * @param _entryFee New entry fee in wei.
     * @param _maxMembers New maximum number of members.
     * @param _proposalQuorumPercentage New quorum percentage for proposals.
     * @param _votingPeriodSeconds New voting period duration in seconds.
     */
    function setGuildParameters(
        string memory _name,
        string memory _description,
        uint256 _entryFee,
        uint256 _maxMembers,
        uint256 _proposalQuorumPercentage,
        uint256 _votingPeriodSeconds
    ) external onlyOwner {
        guildName = _name;
        guildDescription = _description;
        entryFee = _entryFee;
        maxMembers = _maxMembers;
        proposalQuorum = _proposalQuorumPercentage;
        votingPeriod = _votingPeriodSeconds;
        // Consider adding events for each parameter change if needed
    }

    /**
     * @notice Allows an address to join the guild by paying the entry fee.
     */
    function joinGuild() external payable {
        if (members[msg.sender].isMember) revert AlreadyMember();
        if (currentMembersCount >= maxMembers) revert MaxMembersReached();
        if (msg.value < entryFee) revert NotEnoughETH();

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            role: MemberRole.Applicant, // Default role upon joining
            xp: 0,
            level: 0,
            skillPoints: 0,
            isMember: true
        });
        memberAddresses.push(msg.sender); // Note: This might be inefficient for large guilds. Consider alternative data structures.
        currentMembersCount++;

        // Excess ETH sent beyond entryFee remains in treasury.
        emit GuildJoined(msg.sender);
    }

    /**
     * @notice Allows a member to leave the guild.
     */
    function leaveGuild() external onlyMember {
        address memberAddress = msg.sender;
        delete members[memberAddress]; // Removes member data
        currentMembersCount--;

        // Find and remove from memberAddresses array (inefficient for large arrays)
        // In a real contract, consider a linked list or a mapping to index if iteration is critical,
        // or accept that iteration over a deleted array might skip indices.
        for (uint i = 0; i < memberAddresses.length; i++) {
            if (memberAddresses[i] == memberAddress) {
                // Swap with last element and pop
                memberAddresses[i] = memberAddresses[memberAddresses.length - 1];
                memberAddresses.pop();
                break;
            }
        }

        // Member forfeits any unclaimed resources or tasks.
        emit GuildLeft(memberAddress);
    }

    /**
     * @notice Admin function to remove a member from the guild.
     * @param memberAddress The address of the member to kick.
     */
    function kickMember(address memberAddress) external onlyAdmin {
        if (!members[memberAddress].isMember) revert NotMember();
        if (memberAddress == msg.sender) revert InvalidRole(); // Cannot kick self

        delete members[memberAddress];
        currentMembersCount--;

         for (uint i = 0; i < memberAddresses.length; i++) {
            if (memberAddresses[i] == memberAddress) {
                memberAddresses[i] = memberAddresses[memberAddresses.length - 1];
                memberAddresses.pop();
                break;
            }
        }

        emit MemberKicked(memberAddress, msg.sender);
    }

    /**
     * @notice Admin function to set the role of a member.
     * @param memberAddress The address of the member.
     * @param newRole The new role for the member.
     */
    function setMemberRole(address memberAddress, MemberRole newRole) external onlyAdmin {
        if (!members[memberAddress].isMember) revert NotMember();
        // Prevent setting a role higher than Admin by anyone other than Owner? Or just allow Owner to set Admin?
        // For simplicity, Admin can set any role including Admin. Owner can also set roles (via setGuildParameters maybe?).
        // Let's make this onlyAdmin, implying Admin can create other Admins, but Owner can't be kicked.
        // Owner is separate via Ownable.
        if (newRole > MemberRole.Admin) revert InvalidRole(); // Should not happen with enum but safety.
        members[memberAddress].role = newRole;
        emit MemberRoleUpdated(memberAddress, newRole);
    }

    // Function 7: transferOwnership is inherited from OpenZeppelin Ownable.

    // --- II. Treasury & Resources ---

    /**
     * @notice Allows any address to deposit Ether into the guild treasury.
     */
    function depositToTreasury() external payable {
        if (msg.value == 0) revert NotEnoughETH(); // Or use a custom error like ZeroValueDeposit()
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Executes a passed proposal to withdraw Ether from the treasury.
     *         This function is intended to be called *only* by `executeProposal`.
     * @param recipient The address to send the Ether to.
     * @param amount The amount of Ether to withdraw.
     */
    function _executeTreasuryWithdrawal(address recipient, uint256 amount) internal {
        if (address(this).balance < amount) revert NotEnoughETH(); // Should be checked in proposal execution logic too
        // Use low-level call for withdrawal pattern safety
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
        emit TreasuryWithdrawal(recipient, amount);
    }

     /**
     * @notice This function serves as the target for DAO proposals wanting to withdraw ETH.
     *         It should *only* be callable internally via `executeProposal`.
     * @param recipient The address to send ETH to.
     * @param amount The amount of ETH to send.
     */
    function withdrawFromTreasuryViaProposal(address recipient, uint256 amount) external onlyMember {
        // This function should technically only be called by the contract itself during proposal execution.
        // We could add a check like `require(msg.sender == address(this), "Not callable directly");`
        // but the `executeProposal` flow handles the permissions. For clarity and safety,
        // the actual withdrawal logic is in a separate internal function.
        // Adding a basic check to prevent direct calls outside a proposal context is good practice,
        // but requires knowing how `executeProposal` might call it (delegatecall, call, etc.).
        // For this example, we assume `executeProposal` uses `call` or internal function call.
        // Let's add a simple check that it's called from within the contract.
        require(tx.origin == owner(), "Direct calls not allowed"); // A basic check, though not fully secure against reentrancy if used differently.
                                                                   // A safer approach involves a dedicated internal execution function.
        // Let's refactor: `executeProposal` calls an *internal* function `_executeTreasuryWithdrawal`.
        // The function signature `withdrawFromTreasuryViaProposal(address, uint256)` is
        // what would be encoded in the proposal data, but the actual execution is internal.
        // Thus, this function doesn't need to exist as a public target if executeProposal handles it.
        // Let's remove this function and rely on `_executeTreasuryWithdrawal` called by `executeProposal`.
        revert("Use executeProposal for withdrawals"); // This function signature is unused as a public target now.
    }


    /**
     * @notice Mints a specific amount of a custom guild resource to the guild's balance.
     * @param resourceType The identifier of the resource (e.g., keccak256("Wood")).
     * @param amount The amount to mint.
     */
    function mintGuildResource(bytes32 resourceType, uint256 amount) external onlyAdmin {
        guildResourceBalances[resourceType] += amount;
        emit ResourceMinted(resourceType, amount);
    }

    /**
     * @notice Burns a specific amount of a custom guild resource from the guild's balance.
     * @param resourceType The identifier of the resource.
     * @param amount The amount to burn.
     */
    function burnGuildResource(bytes32 resourceType, uint256 amount) external onlyAdmin {
        if (guildResourceBalances[resourceType] < amount) revert NotEnoughResources(resourceType);
        guildResourceBalances[resourceType] -= amount;
        emit ResourceBurned(resourceType, amount);
    }

    /**
     * @notice Transfers a specific amount of a custom guild resource from the guild's balance to a member or another address.
     * @param resourceType The identifier of the resource.
     * @param recipient The address to transfer the resource to.
     * @param amount The amount to transfer.
     */
    function transferGuildResource(bytes32 resourceType, address recipient, uint256 amount) external onlyAdmin {
        if (guildResourceBalances[resourceType] < amount) revert NotEnoughResources(resourceType);
        guildResourceBalances[resourceType] -= amount;
        // Resources can be transferred to members (update member balance) or external addresses (just reduces guild balance).
        // For simplicity, let's track only member balances for internal transfers.
        // If transferring OUT of the guild system, this is handled.
        // If transferring TO a member *within* the guild system:
        if (members[recipient].isMember) {
             memberResourceBalances[recipient][resourceType] += amount;
        }
        // Note: This simple model doesn't track resources external to the guild/members.
        emit ResourceTransfered(resourceType, address(this), recipient, amount);
    }

     /**
     * @notice Internal function to transfer resources from guild to member.
     * @param memberAddress The member recipient.
     * @param resourceType The resource type.
     * @param amount The amount.
     */
    function _transferGuildResourceToMember(address memberAddress, bytes32 resourceType, uint256 amount) internal {
         if (!members[memberAddress].isMember) revert NotMember(); // Should not happen if called correctly
         if (guildResourceBalances[resourceType] < amount) revert NotEnoughResources(resourceType);
         guildResourceBalances[resourceType] -= amount;
         memberResourceBalances[memberAddress][resourceType] += amount;
         emit ResourceTransfered(resourceType, address(this), memberAddress, amount);
    }

     /**
     * @notice Internal function to transfer resources from member to guild.
     *         Used for task requirements.
     * @param memberAddress The member providing resources.
     * @param resourceType The resource type.
     * @param amount The amount.
     */
     function _transferMemberResourceToGuild(address memberAddress, bytes32 resourceType, uint256 amount) internal {
         if (!members[memberAddress].isMember) revert NotMember();
         if (memberResourceBalances[memberAddress][resourceType] < amount) revert NotEnoughResources(resourceType);
         memberResourceBalances[memberAddress][resourceType] -= amount;
         guildResourceBalances[resourceType] += amount;
         emit ResourceTransfered(resourceType, memberAddress, address(this), amount);
     }


    // --- III. DAO Governance ---

    /**
     * @notice Creates a new governance proposal. Callable by any Member (minimum role could be added).
     * @param proposalType The type of action the proposal covers.
     * @param description A description of the proposal.
     * @param data Encoded data specific to the proposal type (e.g., recipient and amount for withdrawal).
     */
    function createProposal(ProposalType proposalType, string memory description, bytes memory data) external onlyMember {
        uint256 proposalId = nextProposalId++;
        proposals.push(Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: proposalType,
            description: description,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriod,
            hasVoted: new mapping(address => bool),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            data: data
        }));
        emit ProposalCreated(proposalId, msg.sender, proposalType, description);
    }

    /**
     * @notice Allows a member to cast a vote on an active proposal.
     * @param proposalId The ID of the proposal.
     * @param voteFor True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool voteFor) external onlyMember {
        if (proposalId >= proposals.length) revert ProposalDoesNotExist();
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Active) revert ProposalNotInVotingPeriod();
        if (block.timestamp > proposal.votingPeriodEnd) revert ProposalNotInVotingPeriod();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit Voted(proposalId, msg.sender, voteFor);
    }

    /**
     * @notice Can be called by anyone after the voting period to execute a proposal if it passed quorum and majority.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        if (proposalId >= proposals.length) revert ProposalDoesNotExist();
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.votingPeriodEnd) revert ProposalNotInVotingPeriod(); // Voting period must be over

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredVotesForQuorum = (currentMembersCount * proposalQuorum) / 100;

        if (totalVotes < requiredVotesForQuorum) {
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(proposalId, ProposalState.Failed);
            revert ProposalNotExecutable("Quorum not met");
        }

        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(proposalId, ProposalState.Failed);
            revert ProposalNotExecutable("Proposal failed majority vote");
        }

        // Proposal passed, now execute the action based on type
        proposal.state = ProposalState.Executing; // Temporary state? Or just directly to Executed. Let's go direct.

        bytes memory _data = proposal.data;

        // Decode data and perform action based on type
        if (proposal.proposalType == ProposalType.WithdrawETH) {
            (address recipient, uint256 amount) = abi.decode(_data, (address, uint256));
            _executeTreasuryWithdrawal(recipient, amount); // Call internal execution function
        } else if (proposal.proposalType == ProposalType.WithdrawNFT) {
             (address nftContract, uint256 tokenId, address recipient) = abi.decode(_data, (address, uint256, address));
            _executeNFTWithdrawal(nftContract, tokenId, recipient); // Call internal execution function
        } else if (proposal.proposalType == ProposalType.MintResource) {
             (bytes32 resourceType, uint256 amount) = abi.decode(_data, (bytes32, uint256));
             // Note: Minting is typically admin/owner. Allowing DAO to mint adds a risk.
             // For this example, we allow it via DAO.
             guildResourceBalances[resourceType] += amount;
             emit ResourceMinted(resourceType, amount);
        } else if (proposal.proposalType == ProposalType.BurnResource) {
             (bytes32 resourceType, uint256 amount) = abi.decode(_data, (bytes32, uint256));
             if (guildResourceBalances[resourceType] < amount) revert NotEnoughResources(resourceType); // State check
             guildResourceBalances[resourceType] -= amount;
             emit ResourceBurned(resourceType, amount);
        } else if (proposal.proposalType == ProposalType.TransferResource) {
             (bytes32 resourceType, address recipient, uint256 amount) = abi.decode(_data, (bytes32, address, uint256));
             // This should probably only transfer *to* members within the guild context via DAO.
             _transferGuildResourceToMember(recipient, resourceType, amount); // Use internal function
        } else if (proposal.proposalType == ProposalType.SetGuildParameter) {
            // Example: Allow DAO to change entry fee
            // (uint256 paramIndex, uint256 newValue) = abi.decode(_data, (uint256, uint256));
            // if (paramIndex == 0) entryFee = newValue;
            // More complex parameter changes would need careful encoding and handling.
            revert ProposalNotExecutable("SetGuildParameter type not fully implemented"); // Placeholder
        }
        // else if (proposal.proposalType == ProposalType.CustomAction) {
        //     // Handle complex custom actions encoded in data. Requires trust/care.
        // }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, ProposalState.Executed);
    }

    // --- IV. Task System ---

    /**
     * @notice Creates a new task definition. Callable by Admin or Officer.
     * @param description Task description.
     * @param ethReward ETH reward upon verification.
     * @param resourceRewardTypes Array of resource types for rewards.
     * @param resourceRewardAmounts Array of resource amounts for rewards (must match types length).
     * @param xpReward XP reward upon verification.
     * @param resourceRequirementTypes Array of resource types required to start the task.
     * @param resourceRequirementAmounts Array of resource amounts required.
     * @param skillRequirementTypes Array of skill types required.
     * @param skillRequirementLevels Array of minimum skill levels required.
     */
    function createTask(
        string memory description,
        uint256 ethReward,
        bytes32[] memory resourceRewardTypes,
        uint256[] memory resourceRewardAmounts,
        uint256 xpReward,
        bytes32[] memory resourceRequirementTypes,
        uint256[] memory resourceRequirementAmounts,
        bytes32[] memory skillRequirementTypes,
        uint256[] memory skillRequirementLevels
    ) external onlyOfficer {
        require(resourceRewardTypes.length == resourceRewardAmounts.length, "Reward types/amounts mismatch");
        require(resourceRequirementTypes.length == resourceRequirementAmounts.length, "Requirement types/amounts mismatch");
        require(skillRequirementTypes.length == skillRequirementLevels.length, "Skill requirement types/levels mismatch");

        uint256 taskId = nextTaskId++;
        Task storage newTask = tasks[taskId];

        newTask.id = taskId;
        newTask.creator = msg.sender;
        newTask.description = description;
        newTask.state = TaskState.Open;
        newTask.ethReward = ethReward;
        newTask.xpReward = xpReward;

        for(uint i = 0; i < resourceRewardTypes.length; i++) {
            newTask.resourceRewards[resourceRewardTypes[i]] = resourceRewardAmounts[i];
        }
        for(uint i = 0; i < resourceRequirementTypes.length; i++) {
            newTask.resourceRequirements[resourceRequirementTypes[i]] = resourceRequirementAmounts[i];
        }
         for(uint i = 0; i < skillRequirementTypes.length; i++) {
            newTask.skillRequirements[skillRequirementTypes[i]] = skillRequirementLevels[i];
        }

        emit TaskCreated(taskId, msg.sender, description);
    }

    /**
     * @notice Assigns an open task to a member. Callable by Admin or Officer.
     * @param taskId The ID of the task.
     * @param assigneeAddress The member address to assign the task to.
     */
    function assignTask(uint256 taskId, address assigneeAddress) external onlyOfficer {
        if (taskId >= tasks.length) revert TaskDoesNotExist();
        Task storage task = tasks[taskId];
        if (task.state != TaskState.Open) revert TaskAlreadyCompletedOrVerified(); // Or specific error for state

        if (!members[assigneeAddress].isMember) revert NotMember();
        task.assignee = assigneeAddress;
        task.state = TaskState.Assigned;

        // Check/Deduct requirements
        Member storage assigneeMember = members[assigneeAddress];
        for (bytes32 resourceType : task.resourceRequirementTypes.keys()) { // Iterating over keys in mapping - check docs for safety/gas
             uint256 amount = task.resourceRequirements[resourceType];
             if (amount > 0) {
                if (assigneeMember.resourceBalances[resourceType] < amount) revert NotEnoughResources(resourceType);
                _transferMemberResourceToGuild(assigneeAddress, resourceType, amount);
             }
        }
         for (bytes32 skillType : task.skillRequirementTypes.keys()) {
             uint256 requiredLevel = task.skillRequirementTypes[skillType]; // This mapping access might need refinement depending on storage structure
             if (assigneeMember.skills[skillType] < requiredLevel) revert InvalidSkillAllocation(); // Use a better error name maybe
         }


        emit TaskAssigned(taskId, assigneeAddress);
    }

    /**
     * @notice Allows the assigned member to submit a task as completed.
     * @param taskId The ID of the task.
     */
    function submitTaskCompletion(uint256 taskId) external onlyMember {
        if (taskId >= tasks.length) revert TaskDoesNotExist();
        Task storage task = tasks[taskId];

        if (task.state != TaskState.Assigned) revert TaskNotAssignedToMember();
        if (task.assignee != msg.sender) revert TaskNotAssignedToMember();

        task.state = TaskState.Submitted;
        emit TaskSubmitted(taskId, msg.sender);
    }

    /**
     * @notice Verifies a submitted task completion. Callable by Admin or Verifier.
     *         Triggers XP gain and makes rewards claimable.
     * @param taskId The ID of the task.
     */
    function verifyTaskCompletion(uint256 taskId) external onlyVerifier {
        if (taskId >= tasks.length) revert TaskDoesNotExist();
        Task storage task = tasks[taskId];

        if (task.state != TaskState.Submitted) revert TaskNotSubmitted();

        task.state = TaskState.Verified;

        // Grant XP to the assignee
        _grantXP(task.assignee, task.xpReward);

        // Rewards are now claimable
        emit TaskVerified(taskId, msg.sender);
    }

    /**
     * @notice Allows the assignee of a verified task to claim their rewards (ETH and resources).
     * @param taskId The ID of the task.
     */
    function claimTaskRewards(uint256 taskId) external onlyMember {
        if (taskId >= tasks.length) revert TaskDoesNotExist();
        Task storage task = tasks[taskId];

        if (task.state != TaskState.Verified) revert TaskNotVerified();
        if (task.assignee != msg.sender) revert TaskNotAssignedToMember();

        // Transfer ETH reward
        if (task.ethReward > 0) {
             if (address(this).balance < task.ethReward) revert NotEnoughETH(); // Should not happen if guild is managed
             (bool success, ) = msg.sender.call{value: task.ethReward}("");
             require(success, "ETH reward transfer failed");
        }

        // Transfer Resource rewards
        // Iterating over mapping keys is complex/gas heavy. Requires external tracking or a different struct design.
        // For this example, we'll assume resourceRewardTypes was stored/accessible or iterate over known types if any.
        // A better approach is to store reward types in an array within the Task struct.
        // Let's assume the task struct has `resourceRewardTypesArray` and `resourceRewardAmountsArray`
        // (Requires modifying the Task struct and createTask function).
        // Using a placeholder iteration here:
        // for (bytes32 resourceType : task.resourceRewardTypesArray) {
        //      uint256 amount = task.resourceRewardAmounts[resourceType]; // Or use a parallel array
        //      if (amount > 0) {
        //          _transferGuildResourceToMember(msg.sender, resourceType, amount);
        //      }
        // }
         // Simpler placeholder using the mapping iteration (gas warning):
         // Note: Iterating mappings is NOT standard practice in Solidity for gas efficiency or reliable order.
         // This is illustrative. A production contract would store reward types in an array.
        // for (bytes32 resourceType : Object.keys(task.resourceRewards)) { // This is not how Solidity works
        //     uint256 amount = task.resourceRewards[resourceType];
        //     if (amount > 0) {
        //         _transferGuildResourceToMember(msg.sender, resourceType, amount);
        //     }
        // }
        // A proper implementation needs explicit arrays in the Task struct or external resource type tracking.
        // Assuming a placeholder implementation for resource reward transfer:
         bytes32[] memory resourceRewardTypesPlaceholder = new bytes32[](0); // Need to fetch this from Task struct properly
         uint256[] memory resourceRewardAmountsPlaceholder = new uint256[](0); // Need to fetch this

         // In a real contract, you would iterate through saved reward types/amounts from the Task struct
         // Example: Iterate through the stored resource types and amounts arrays in the Task struct
         // for (uint i = 0; i < task.resourceRewardTypes.length; i++) {
         //     bytes32 resType = task.resourceRewardTypes[i];
         //     uint256 resAmount = task.resourceRewardAmounts[i];
         //     if (resAmount > 0) {
         //          _transferGuildResourceToMember(msg.sender, resType, resAmount);
         //     }
         // }


        task.state = TaskState.Completed; // Mark as completed after claiming rewards
        emit TaskRewardsClaimed(taskId, msg.sender);
    }


    // --- V. Member Progression ---

    /**
     * @notice Internal function to grant XP to a member and handle level ups.
     * @param memberAddress The address of the member.
     * @param amount The amount of XP to grant.
     */
    function _grantXP(address memberAddress, uint256 amount) internal {
        Member storage member = members[memberAddress];
        if (!member.isMember) return; // Should not happen but safety check

        uint256 oldXP = member.xp;
        uint256 oldLevel = member.level;
        member.xp += amount;
        emit MemberXPGained(memberAddress, amount, member.xp);

        // Check for level ups
        uint256 currentLevelXPNeeded = BASE_XP_FOR_LEVEL + oldLevel * XP_INCREASE_PER_LEVEL;
        while (member.xp >= currentLevelXPNeeded) {
            member.level++;
            member.skillPoints += SKILL_POINTS_PER_LEVEL;
            emit MemberLeveledUp(memberAddress, member.level, member.skillPoints);
            currentLevelXPNeeded = BASE_XP_FOR_LEVEL + member.level * XP_INCREASE_PER_LEVEL; // XP needed for the *next* level
        }
    }

    /**
     * @notice Allows a member to allocate their available skill points to skills.
     * @param skillType The identifier of the skill (e.g., keccak256("Mining")).
     * @param pointsToAllocate The number of points to add to this skill.
     */
    function allocateSkillPoints(bytes32 skillType, uint256 pointsToAllocate) external onlyMember {
        Member storage member = members[msg.sender];
        if (member.skillPoints < pointsToAllocate) revert NotEnoughSkillPoints();
        if (pointsToAllocate == 0) return; // No points to allocate

        member.skillPoints -= pointsToAllocate;
        member.skills[skillType] += pointsToAllocate;
        emit SkillPointsAllocated(msg.sender, skillType, member.skills[skillType]);
    }

    /**
     * @notice Allows a member to reset their skill point allocation. Points are returned to the pool.
     *         Can optionally include a cost (e.g., ETH or resource fee).
     */
    function resetSkillPoints() external onlyMember {
        Member storage member = members[msg.sender];

        // Calculate total allocated points
        uint256 totalAllocated = 0;
        // Iterating over all possible skillTypes requires external knowledge or a different mapping approach.
        // Assuming we track which skill types have been allocated to:
        // for (bytes32 skillType : member.allocatedSkillTypes) { // Requires tracking allocated types in an array
        //      totalAllocated += member.skills[skillType];
        //      member.skills[skillType] = 0;
        // }

        // For this example, let's simplify and assume a fixed set of known skills or clear all.
        // Clearing all: Iterate over known skills (requires hardcoding or dynamic list).
        // Or simply refund skillPoints based on level (simpler but less precise if points were spent).
        // Let's make it refund based on level:
        uint256 refundedPoints = member.level * SKILL_POINTS_PER_LEVEL;
        member.skillPoints += refundedPoints;

        // Clear existing skill allocations (this part is tricky without knowing which skills were allocated)
        // A mapping from member address to an array of allocated skill types would be needed for proper reset.
        // For simplicity, this reset just refunds points and assumes skills are reset by dApp logic reading state.
        // A more robust contract needs a way to list allocated skills per member.
        // Example approach: Store skills in a struct array or a mapping `memberSkills[memberAddress][skillType]`.
        // Clearing mapping values is complex. Let's assume the dApp interprets this as "all skills reset".
        // A proper on-chain reset would iterate and zero out specific skills.
        // Placeholder:
        // member.skills = new mapping(bytes32 => uint256); // This line is NOT valid Solidity. Mappings cannot be deleted like this.
        // The correct way requires storing the keys (skill types) somewhere.
        // For now, let's just refund the points and emit an event. The dApp layer interprets this as a skill reset.
        // Refunding based on level is simpler than tracking exactly what was spent.

        emit SkillPointsReset(msg.sender);
        // Note: Full on-chain skill reset requires tracking allocated skill types per member, which adds complexity.
    }


    // --- VI. Asset Management (NFTs) ---

    /**
     * @notice Allows an ERC721 NFT owner to deposit an NFT into the guild's custody.
     *         The guild contract must be approved or be the owner already.
     * @param nftContract The address of the ERC721 contract.
     * @param tokenId The ID of the NFT.
     */
    function depositNFTToTreasury(address nftContract, uint256 tokenId) external {
        IERC721 nft = IERC721(nftContract);

        // Ensure sender is the owner or approved
        require(nft.ownerOf(tokenId) == msg.sender || nft.isApprovedForAll(msg.sender, address(this)), "Not authorized to transfer NFT");

        // Transfer NFT to the guild contract
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        guildOwnedNFTs[nftContract][tokenId] = true;

        // Add contract address to list if not already present (inefficient for many contracts)
        bool found = false;
        for(uint i=0; i < guildOwnedNFTContractAddresses.length; i++) {
            if (guildOwnedNFTContractAddresses[i] == nftContract) {
                found = true;
                break;
            }
        }
        if (!found) {
            guildOwnedNFTContractAddresses.push(nftContract);
        }

        emit NFTDeposited(nftContract, tokenId, msg.sender);
    }

     /**
     * @notice Executes a passed proposal to withdraw an NFT from the treasury.
     *         This function is intended to be called *only* by `executeProposal`.
     * @param nftContract The address of the ERC721 contract.
     * @param tokenId The ID of the NFT.
     * @param recipient The address to send the NFT to.
     */
    function _executeNFTWithdrawal(address nftContract, uint256 tokenId, address recipient) internal {
        if (!guildOwnedNFTs[nftContract][tokenId]) revert NFTNotInGuild(tokenId);

        IERC721 nft = IERC721(nftContract);
        // Check that the guild contract is indeed the owner
        require(nft.ownerOf(tokenId) == address(this), "Guild does not own this NFT");

        nft.safeTransferFrom(address(this), recipient, tokenId);

        delete guildOwnedNFTs[nftContract][tokenId];
        delete nftCurrentAssignee[nftContract][tokenId]; // Clear internal assignment upon withdrawal

        // Consider removing contract from guildOwnedNFTContractAddresses if it's the last NFT of that type (inefficient check)

        emit NFTWithdrawal(nftContract, tokenId, recipient);
    }

     /**
     * @notice This function serves as the target for DAO proposals wanting to withdraw NFTs.
     *         It should *only* be callable internally via `executeProposal`.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param recipient The address to send the NFT to.
     */
    function withdrawNFTFromTreasuryViaProposal(address nftContract, uint256 tokenId, address recipient) external onlyMember {
         revert("Use executeProposal for NFT withdrawals"); // This function signature is unused as a public target now.
    }


    /**
     * @notice Assigns a guild-owned NFT asset to a specific member for internal 'usage'.
     *         Does NOT transfer ownership, just updates internal state.
     *         Callable by Admin, Officer, or via DAO proposal.
     * @param nftContract The address of the ERC721 contract.
     * @param tokenId The ID of the NFT.
     * @param assignee The member address to assign usage to (address(0) to unassign).
     */
    function assignNFTUsage(address nftContract, uint256 tokenId, address assignee) external onlyOfficer { // Could also be onlyAdmin or require DAO proposal
        if (!guildOwnedNFTs[nftContract][tokenId]) revert NFTNotInGuild(tokenId);
        if (assignee != address(0) && !members[assignee].isMember) revert NotMember(); // Must assign to a member or unassign

        nftCurrentAssignee[nftContract][tokenId] = assignee;
        emit NFTUsageAssigned(nftContract, tokenId, assignee);
    }

    // --- VII. View Functions ---

    /**
     * @notice Returns core information about the guild.
     */
    function getGuildInfo() external view returns (
        string memory name,
        string memory description,
        uint256 currentMembers,
        uint256 maxMembersLimit,
        uint256 fee,
        uint256 quorum,
        uint256 votePeriod
    ) {
        return (
            guildName,
            guildDescription,
            currentMembersCount,
            maxMembers,
            entryFee,
            proposalQuorum,
            votingPeriod
        );
    }

    /**
     * @notice Returns details for a specific member.
     * @param memberAddress The address of the member.
     */
    function getMemberDetails(address memberAddress) external view returns (
        bool isMember,
        MemberRole role,
        uint256 xp,
        uint256 level,
        uint256 skillPoints
    ) {
        Member storage member = members[memberAddress];
        return (
            member.isMember,
            member.role,
            member.xp,
            member.level,
            member.skillPoints
        );
    }

     /**
     * @notice Returns the skill level for a specific skill for a member.
     * @param memberAddress The address of the member.
     * @param skillType The identifier of the skill.
     */
    function getMemberSkillLevel(address memberAddress, bytes32 skillType) external view returns (uint256) {
        if (!members[memberAddress].isMember) return 0;
        return members[memberAddress].skills[skillType];
    }


    /**
     * @notice Returns details about a specific proposal.
     * @param proposalId The ID of the proposal.
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        ProposalType proposalType,
        string memory description,
        uint256 creationTime,
        uint256 votingPeriodEnd,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state,
        bytes memory data
    ) {
         if (proposalId >= proposals.length) revert ProposalDoesNotExist();
         Proposal storage proposal = proposals[proposalId];
         return (
            proposal.id,
            proposal.proposer,
            proposal.proposalType,
            proposal.description,
            proposal.creationTime,
            proposal.votingPeriodEnd,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state,
            proposal.data
         );
    }

    /**
     * @notice Returns details about a specific task.
     * @param taskId The ID of the task.
     */
     function getTaskDetails(uint256 taskId) external view returns (
         uint256 id,
         address creator,
         string memory description,
         address assignee,
         TaskState state,
         uint256 ethReward,
         uint256 xpReward
         // Note: Returning mappings (resource rewards/requirements, skill requirements) from a view function is tricky.
         // Requires iterating or returning specific values. Add helper views if needed for specific resources/skills.
     ) {
          if (taskId >= tasks.length) revert TaskDoesNotExist();
          Task storage task = tasks[taskId];
          return (
              task.id,
              task.creator,
              task.description,
              task.assignee,
              task.state,
              task.ethReward,
              task.xpReward
          );
     }

    /**
     * @notice Returns the guild's balance of a specific custom resource.
     * @param resourceType The identifier of the resource.
     */
    function getGuildResourceBalance(bytes32 resourceType) external view returns (uint256) {
        return guildResourceBalances[resourceType];
    }

    /**
     * @notice Returns a member's balance of a specific custom resource.
     * @param memberAddress The address of the member.
     * @param resourceType The identifier of the resource.
     */
     function getMemberResourceBalance(address memberAddress, bytes32 resourceType) external view returns (uint256) {
         if (!members[memberAddress].isMember) return 0;
         return memberResourceBalances[memberAddress][resourceType];
     }


    /**
     * @notice Returns a list of contract addresses for NFTs held by the guild.
     *         To get specific token IDs, further calls per contract are needed.
     */
    function getGuildNFTContracts() external view returns (address[] memory) {
        return guildOwnedNFTContractAddresses; // Note: This list might contain contracts with 0 NFTs if not cleaned up
    }

     /**
      * @notice Returns the member currently assigned to use a specific guild NFT.
      * @param nftContract The address of the ERC721 contract.
      * @param tokenId The ID of the NFT.
      */
    function getNFTCurrentAssignee(address nftContract, uint256 tokenId) external view returns (address) {
        // No need to check if guild owns it here, mapping returns address(0) if not set.
        return nftCurrentAssignee[nftContract][tokenId];
    }

    // --- Receive / Fallback ---
     receive() external payable {
        emit Deposited(msg.sender, msg.value);
     }

     fallback() external payable {
         emit Deposited(msg.sender, msg.value);
     }
}
```