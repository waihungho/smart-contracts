Okay, let's design a smart contract for a **Decentralized Autonomous Research Guild (DARG)**. This contract will manage staking for membership, proposal submission and voting for research projects, funding distribution, and reputation tracking.

It combines elements of DAOs, staking, and project funding mechanics, going beyond a simple token or marketplace. It uses state machines for proposals and projects, time-based logic, and internal accounting.

**Outline:**

1.  **SPDX License and Pragma**
2.  **Imports** (ERC20, SafeERC20 from OpenZeppelin for safe token interactions)
3.  **Error Definitions** (Custom errors for clarity and gas efficiency)
4.  **Enums** (For proposal and project states)
5.  **Structs** (For Members, Proposals, Projects)
6.  **State Variables** (Core configuration, mappings for data)
7.  **Events** (To signal state changes)
8.  **Modifiers** (For access control and state checks)
9.  **Constructor** (Initializes the contract)
10. **Admin Functions** (Setting core parameters)
11. **Membership/Staking Functions** (Staking, unstaking, status checks)
12. **Treasury Functions** (Depositing funds)
13. **Proposal Functions** (Submitting, updating, transitioning state)
14. **Voting Functions** (Casting votes)
15. **Proposal Resolution Functions** (Tallying votes, executing approved proposals)
16. **Project Management Functions** (Updating project status, collecting fees)
17. **Reputation & Penalty Functions** (Admin/Governance actions on members)
18. **Reward Distribution Functions** (Admin distributing rewards)
19. **View Functions** (Reading contract state)

**Function Summary:**

Here's a summary of the functions, totaling well over 20:

1.  `constructor()`: Initializes the contract with the ERC20 token address and admin.
2.  `setGuildToken(address _guildToken)`: Admin sets the address of the ERC20 token used by the guild.
3.  `setMinimumStakeAmount(uint256 _amount)`: Admin sets the minimum token amount required to stake for membership.
4.  `setProposalVotingPeriod(uint40 _duration)`: Admin sets how long the voting phase for proposals lasts.
5.  `setStakingLockDuration(uint40 _duration)`: Admin sets how long staked tokens are locked.
6.  `setQuorumRequired(uint256 _percentage)`: Admin sets the percentage of total staked tokens required for a proposal vote to be valid.
7.  `setApprovalThreshold(uint256 _percentage)`: Admin sets the percentage of 'For' votes (among participating votes) required for a proposal to pass.
8.  `setProjectCompletionFeePercentage(uint256 _percentage)`: Admin sets the percentage of funded amount returned to treasury upon project completion.
9.  `setAdmin(address _newAdmin)`: Transfers admin ownership.
10. `stakeTokens(uint256 _amount)`: Allows a user to stake tokens, becoming a member or increasing their stake. Checks minimum stake and transfers tokens.
11. `unstakeTokens(uint256 _amount)`: Allows a member to unstake tokens after the lock duration has passed. Transfers tokens back.
12. `depositToTreasury(uint256 _amount)`: Allows anyone to deposit tokens into the guild's treasury.
13. `submitResearchProposal(bytes32 _descriptionHash, uint256 _fundingRequested)`: Allows a member to submit a new research proposal, linking to off-chain details and requesting funding. Creates a Proposal and associated Project struct.
14. `updateResearchProposal(uint256 _proposalId, bytes32 _newDescriptionHash, uint256 _newFundingRequested)`: Allows the proposer to update their proposal while it's in the `Draft` state.
15. `transitionProposalToVoting(uint256 _proposalId)`: Allows the proposer or admin to move a proposal from `Draft` to `Voting`. Sets the voting end time.
16. `castVote(uint256 _proposalId, bool _support)`: Allows a member to cast a 'For' or 'Against' vote on a proposal during the voting period.
17. `tallyVotes(uint256 _proposalId)`: Can be called by anyone after the voting period ends. Determines if the proposal meets quorum and approval thresholds and transitions its state (`Approved` or `Rejected`).
18. `executeApprovedProposal(uint256 _proposalId)`: Can be called by anyone if a proposal is in the `Approved` state. Transfers the requested funding from the treasury to the project proposer. Transitions project state to `Funded`.
19. `submitProjectUpdate(uint256 _projectId, bytes32 _updateHash)`: Allows the project proposer (researcher) to submit updates on their project progress (e.g., links to reports).
20. `markProjectCompleted(uint256 _projectId)`: Allows the project proposer or admin to mark a funded project as `Completed`.
21. `collectProjectCompletionFee(uint256 _projectId)`: Can be called by anyone after a project is marked `Completed`. Calculates and transfers the completion fee back to the treasury. Transitions project state to `CompletedAndFeeCollected`.
22. `penalizeMember(address _member, uint256 _slashAmount, int256 _reputationChange)`: Admin/Governance function to penalize a member by slashing stake and/or changing reputation.
23. `distributeRewards(address[] calldata _members, uint256[] calldata _amounts)`: Admin/Governance function to distribute rewards from the treasury to multiple members.
24. `updateMemberReputation(address _member, int256 _reputationChange)`: Admin/Governance function to manually adjust a member's reputation.
25. `getMemberDetails(address _member)`: View function to get a member's staking and reputation details.
26. `getProposalDetails(uint256 _proposalId)`: View function to get details of a proposal (state, votes, times, etc.).
27. `getProjectDetails(uint256 _projectId)`: View function to get details of a project (funding, state, proposer, etc.).
28. `getTotalStaked()`: View function to get the total tokens staked in the guild.
29. `getTreasuryBalance()`: View function to get the current balance of the guild's treasury.
30. `getProposalState(uint256 _proposalId)`: View function to get just the state of a specific proposal.
31. `getProjectState(uint256 _projectId)`: View function to get just the state of a specific project.
32. `canUnstake(address _member)`: View function to check if a member's stake lock duration has passed.
33. `isVotingPeriodActive(uint256 _proposalId)`: View function to check if voting is currently active for a proposal.
34. `hasMemberVoted(uint256 _proposalId, address _member)`: View function to check if a member has already voted on a proposal.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial admin control, could be replaced by more complex DAO governance

// --- Decentralized Autonomous Research Guild (DARG) Smart Contract ---

// Outline:
// 1. SPDX License and Pragma
// 2. Imports (IERC20, SafeERC20, Ownable)
// 3. Error Definitions
// 4. Enums (ProposalState, ProjectState)
// 5. Structs (Member, Proposal, Project)
// 6. State Variables (Core config, mappings)
// 7. Events
// 8. Modifiers
// 9. Constructor
// 10. Admin Functions (Setters, Ownership)
// 11. Membership/Staking Functions (stake, unstake)
// 12. Treasury Functions (deposit)
// 13. Proposal Functions (submit, update, transition)
// 14. Voting Functions (castVote)
// 15. Proposal Resolution Functions (tallyVotes, executeApprovedProposal)
// 16. Project Management Functions (submitUpdate, markCompleted, collectFee)
// 17. Reputation & Penalty Functions (penalize, updateReputation)
// 18. Reward Distribution Functions (distributeRewards)
// 19. View Functions (getters)

// Function Summary:
// 1. constructor()
// 2. setGuildToken(address)
// 3. setMinimumStakeAmount(uint256)
// 4. setProposalVotingPeriod(uint40)
// 5. setStakingLockDuration(uint40)
// 6. setQuorumRequired(uint256)
// 7. setApprovalThreshold(uint256)
// 8. setProjectCompletionFeePercentage(uint256)
// 9. setAdmin(address) - Inherited from Ownable, but explicitly listed.
// 10. stakeTokens(uint256)
// 11. unstakeTokens(uint256)
// 12. depositToTreasury(uint256)
// 13. submitResearchProposal(bytes32, uint256)
// 14. updateResearchProposal(uint256, bytes32, uint256)
// 15. transitionProposalToVoting(uint256)
// 16. castVote(uint256, bool)
// 17. tallyVotes(uint256)
// 18. executeApprovedProposal(uint256)
// 19. submitProjectUpdate(uint256, bytes32)
// 20. markProjectCompleted(uint256)
// 21. collectProjectCompletionFee(uint256)
// 22. penalizeMember(address, uint256, int256)
// 23. distributeRewards(address[], uint256[])
// 24. updateMemberReputation(address, int256)
// 25. getMemberDetails(address)
// 26. getProposalDetails(uint256)
// 27. getProjectDetails(uint256)
// 28. getTotalStaked()
// 29. getTreasuryBalance()
// 30. getProposalState(uint256)
// 31. getProjectState(uint256)
// 32. canUnstake(address)
// 33. isVotingPeriodActive(uint256)
// 34. hasMemberVoted(uint256, address)
// 35. owner() - Inherited from Ownable, explicitly listed.
// 36. renounceOwnership() - Inherited from Ownable, explicitly listed.
// 37. transferOwnership(address) - Inherited from Ownable, explicitly listed.

contract DecentralizedAutonomousResearchGuild is Ownable {
    using SafeERC20 for IERC20;

    // --- Error Definitions ---
    error DARG_TokenNotSet();
    error DARG_InsufficientStake(uint256 required, uint256 current);
    error DARG_InsufficientTreasury(uint256 requested, uint256 available);
    error DARG_StakeLocked(uint40 unlockTime);
    error DARG_NotAMember();
    error DARG_ProposalNotFound();
    error DARG_ProjectNotFound();
    error DARG_UnauthorizedAction();
    error DARG_InvalidProposalState(ProposalState currentState, string expectedStates);
    error DARG_InvalidProjectState(ProjectState currentState, string expectedStates);
    error DARG_VotingPeriodNotActive();
    error DARG_VotingPeriodExpired();
    error DARG_AlreadyVoted();
    error DARG_QuorumNotMet(uint256 required, uint256 actual);
    error DARG_ApprovalThresholdNotMet(uint256 required, uint256 actual);
    error DARG_FeeCalculationError();
    error DARG_InsufficientRewardAmount();
    error DARG_ArraysLengthMismatch();
    error DARG_ZeroAddressNotAllowed();
    error DARG_ValueMustBeGreaterThanZero();

    // --- Enums ---
    enum ProposalState { Draft, Voting, Approved, Rejected, Implemented } // Implemented means funding executed
    enum ProjectState { Proposed, Funded, InProgress, Completed, CompletedAndFeeCollected, Failed } // State of the research project itself

    // --- Structs ---
    struct Member {
        uint256 stakedAmount;
        uint40 stakeStartTime; // Timestamp when current stake period started (for lock-up)
        int256 reputation; // Simple reputation score (can be positive or negative)
        bool isMember; // True if staked >= minimumStakeAmount
    }

    struct Proposal {
        address proposer;
        uint256 projectId; // Links to the project this proposal is about
        bytes32 descriptionHash; // IPFS hash or similar link to proposal details
        uint40 submissionTime;
        uint40 votingEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 quorumRequired; // Quorum calculated at transition to Voting
        uint256 approvalThreshold; // Approval threshold calculated at transition to Voting
        ProposalState state;
    }

    struct Project {
        address proposer; // The researcher/entity conducting the project
        uint256 fundingRequested;
        uint256 fundingReceived; // Amount actually transferred
        bytes32 latestUpdateHash; // IPFS hash or similar for latest update
        ProjectState state;
        uint256 associatedProposalId; // Links back to the proposal that funded it
    }

    // --- State Variables ---
    IERC20 public guildToken;
    uint256 public totalStakedTokens;
    uint256 public treasuryBalance;
    uint256 public minimumStakeAmount;
    uint40 public proposalVotingPeriod; // In seconds
    uint40 public stakingLockDuration; // In seconds
    uint256 public quorumRequiredPercentage = 20; // % of totalStakedTokens required for quorum
    uint256 public approvalThresholdPercentage = 50; // % of FOR votes among total votes (for + against) required
    uint256 public projectCompletionFeePercentage = 5; // % of fundingReturned to treasury on completion

    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => bool)) private proposalVotes; // proposalId => memberAddress => voted

    uint256 public proposalCount; // Auto-incrementing ID for proposals
    uint256 public projectCount; // Auto-incrementing ID for projects

    // --- Events ---
    event GuildTokenSet(address indexed token);
    event MinimumStakeAmountSet(uint256 amount);
    event ProposalVotingPeriodSet(uint40 duration);
    event StakingLockDurationSet(uint40 duration);
    event QuorumRequiredPercentageSet(uint256 percentage);
    event ApprovalThresholdPercentageSet(uint256 percentage);
    event ProjectCompletionFeePercentageSet(uint256 percentage);

    event TokensStaked(address indexed member, uint256 amount, uint256 newTotalStaked);
    event TokensUnstaked(address indexed member, uint256 amount, uint256 newTotalStaked);
    event MembershipStatusChanged(address indexed member, bool isMember, uint256 currentStake);
    event TokensDepositedToTreasury(address indexed sender, uint256 amount, uint256 newTreasuryBalance);

    event ResearchProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 descriptionHash, uint256 fundingRequested);
    event ResearchProposalUpdated(uint256 indexed proposalId, bytes32 newDescriptionHash, uint256 newFundingRequested);
    event ProposalStateTransitioned(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalOutcome(uint256 indexed proposalId, bool passed, uint256 forVotes, uint256 againstVotes, uint256 totalVotes, uint256 quorumRequired, uint256 approvalThreshold);
    event ProjectFunded(uint256 indexed projectId, uint256 indexed proposalId, uint256 amountTransferred);
    event ProjectUpdateSubmitted(uint256 indexed projectId, address indexed submitter, bytes32 updateHash);
    event ProjectStateTransitioned(uint256 indexed projectId, ProjectState oldState, ProjectState newState);
    event ProjectCompletionFeeCollected(uint256 indexed projectId, uint256 feeAmount, uint256 newTreasuryBalance);

    event MemberPenalized(address indexed member, uint256 slashedAmount, int256 reputationChange);
    event RewardsDistributed(address indexed receiver, uint256 amount);
    event MemberReputationUpdated(address indexed member, int256 reputationChange, int256 newReputation);

    // --- Modifiers ---
    modifier onlyMember() {
        if (!members[msg.sender].isMember) revert DARG_NotAMember();
        _;
    }

    modifier isProposalState(uint256 _proposalId, ProposalState _expectedState) {
        if (_proposalId == 0 || _proposalId > proposalCount) revert DARG_ProposalNotFound();
        if (proposals[_proposalId].state != _expectedState) revert DARG_InvalidProposalState(proposals[_proposalId].state, "Incorrect State");
        _;
    }

     modifier notProposalState(uint256 _proposalId, ProposalState _stateToAvoid) {
        if (_proposalId == 0 || _proposalId > proposalCount) revert DARG_ProposalNotFound();
        if (proposals[_proposalId].state == _stateToAvoid) revert DARG_InvalidProposalState(proposals[_proposalId].state, "Avoided State");
        _;
    }

    modifier isProjectState(uint256 _projectId, ProjectState _expectedState) {
        if (_projectId == 0 || _projectId > projectCount) revert DARG_ProjectNotFound();
        if (projects[_projectId].state != _expectedState) revert DARG_InvalidProjectState(projects[_projectId].state, "Incorrect State");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the Decentralized Autonomous Research Guild contract.
    /// @param _guildToken The address of the ERC20 token used for staking and funding.
    /// @param _minimumStake Amount required for membership.
    /// @param _votingPeriod Duration of proposal voting in seconds.
    /// @param _lockDuration Duration staked tokens are locked in seconds.
    constructor(IERC20 _guildToken, uint256 _minimumStake, uint40 _votingPeriod, uint40 _lockDuration) Ownable(msg.sender) {
        if (address(_guildToken) == address(0)) revert DARG_ZeroAddressNotAllowed();
        if (_minimumStake == 0) revert DARG_ValueMustBeGreaterThanZero();
        if (_votingPeriod == 0) revert DARG_ValueMustBeGreaterThanZero();
        if (_lockDuration == 0) revert DARG_ValueMustBeGreaterThanZero();

        guildToken = _guildToken;
        minimumStakeAmount = _minimumStake;
        proposalVotingPeriod = _votingPeriod;
        stakingLockDuration = _lockDuration;

        emit GuildTokenSet(address(_guildToken));
        emit MinimumStakeAmountSet(_minimumStake);
        emit ProposalVotingPeriodSet(_votingPeriod);
        emit StakingLockDurationSet(_lockDuration);
    }

    // --- Admin Functions ---

    /// @notice Sets the address of the ERC20 token used by the guild.
    /// @param _guildToken The address of the new token.
    function setGuildToken(address _guildToken) external onlyOwner {
        if (_guildToken == address(0)) revert DARG_ZeroAddressNotAllowed();
        guildToken = IERC20(_guildToken);
        emit GuildTokenSet(_guildToken);
    }

    /// @notice Sets the minimum stake amount required for membership.
    /// @param _amount The new minimum stake amount.
    function setMinimumStakeAmount(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert DARG_ValueMustBeGreaterThanZero();
        minimumStakeAmount = _amount;
        emit MinimumStakeAmountSet(_amount);
    }

    /// @notice Sets the duration of the proposal voting period.
    /// @param _duration The new duration in seconds.
    function setProposalVotingPeriod(uint40 _duration) external onlyOwner {
        if (_duration == 0) revert DARG_ValueMustBeGreaterThanZero();
        proposalVotingPeriod = _duration;
        emit ProposalVotingPeriodSet(_duration);
    }

    /// @notice Sets the duration for which staked tokens are locked.
    /// @param _duration The new lock duration in seconds.
    function setStakingLockDuration(uint40 _duration) external onlyOwner {
        if (_duration == 0) revert DARG_ValueMustBeGreaterThanZero();
        stakingLockDuration = _duration;
        emit StakingLockDurationSet(_duration);
    }

    /// @notice Sets the percentage of total staked tokens required for a proposal vote to be valid (quorum).
    /// @param _percentage The new percentage (0-100).
    function setQuorumRequired(uint256 _percentage) external onlyOwner {
        if (_percentage > 100) revert DARG_ValueMustBeGreaterThanZero(); // Should probably be <= 100
        quorumRequiredPercentage = _percentage;
        emit QuorumRequiredPercentageSet(_percentage);
    }

    /// @notice Sets the percentage of 'For' votes required for a proposal to pass (among participating votes).
    /// @param _percentage The new percentage (0-100).
    function setApprovalThreshold(uint256 _percentage) external onlyOwner {
        if (_percentage > 100) revert DARG_ValueMustBeGreaterThanZero(); // Should probably be <= 100
        approvalThresholdPercentage = _percentage;
        emit ApprovalThresholdPercentageSet(_percentage);
    }

     /// @notice Sets the percentage of funded amount returned to treasury upon project completion.
     /// @param _percentage The new percentage (0-100).
    function setProjectCompletionFeePercentage(uint256 _percentage) external onlyOwner {
        if (_percentage > 100) revert DARG_ValueMustBeGreaterThanZero(); // Should probably be <= 100
        projectCompletionFeePercentage = _percentage;
        emit ProjectCompletionFeePercentageSet(_percentage);
    }

    /// @notice Transfers ownership of the contract (admin role). Inherited from Ownable.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) external onlyOwner {
        if (_newAdmin == address(0)) revert DARG_ZeroAddressNotAllowed();
        transferOwnership(_newAdmin); // Using Ownable's transferOwnership
    }

    // --- Membership/Staking Functions ---

    /// @notice Allows a user to stake tokens to become or remain a member of the guild.
    /// @param _amount The amount of tokens to stake.
    function stakeTokens(uint256 _amount) external {
        if (_amount == 0) revert DARG_ValueMustBeGreaterThanZero();
        if (address(guildToken) == address(0)) revert DARG_TokenNotSet();

        uint256 currentStake = members[msg.sender].stakedAmount;
        uint256 newStake = currentStake + _amount;

        // Transfer tokens from user to contract
        guildToken.safeTransferFrom(msg.sender, address(this), _amount);

        members[msg.sender].stakedAmount = newStake;
        members[msg.sender].stakeStartTime = uint40(block.timestamp); // Reset lock time on new stake
        totalStakedTokens += _amount;

        bool wasMember = members[msg.sender].isMember;
        if (newStake >= minimumStakeAmount) {
            members[msg.sender].isMember = true;
            if (!wasMember) {
                 emit MembershipStatusChanged(msg.sender, true, newStake);
            }
        } else {
            members[msg.sender].isMember = false;
             if (wasMember) {
                 emit MembershipStatusChanged(msg.sender, false, newStake);
            }
        }

        emit TokensStaked(msg.sender, _amount, totalStakedTokens);
    }

    /// @notice Allows a member to unstake tokens after their lock duration has passed.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) external onlyMember {
        if (_amount == 0) revert DARG_ValueMustBeGreaterThanZero();
        if (address(guildToken) == address(0)) revert DARG_TokenNotSet();

        Member storage member = members[msg.sender];

        if (block.timestamp < member.stakeStartTime + stakingLockDuration) {
            revert DARG_StakeLocked(member.stakeStartTime + stakingLockDuration);
        }
        if (_amount > member.stakedAmount) revert DARG_InsufficientStake(_amount, member.stakedAmount);

        member.stakedAmount -= _amount;
        totalStakedTokens -= _amount;

        // Transfer tokens from contract back to user
        guildToken.safeTransfer(msg.sender, _amount);

        bool wasMember = member.isMember;
        if (member.stakedAmount < minimumStakeAmount) {
            member.isMember = false;
             if (wasMember) {
                 emit MembershipStatusChanged(msg.sender, false, member.stakedAmount);
            }
        }
        // Note: stakeStartTime is NOT reset on unstake, only on *new* stake

        emit TokensUnstaked(msg.sender, _amount, totalStakedTokens);
    }

    /// @notice Allows anyone to deposit tokens into the guild's treasury.
    /// @param _amount The amount of tokens to deposit.
    function depositToTreasury(uint256 _amount) external {
         if (_amount == 0) revert DARG_ValueMustBeGreaterThanZero();
        if (address(guildToken) == address(0)) revert DARG_TokenNotSet();

        guildToken.safeTransferFrom(msg.sender, address(this), _amount);
        treasuryBalance += _amount;
        emit TokensDepositedToTreasury(msg.sender, _amount, treasuryBalance);
    }

    // --- Proposal Functions ---

    /// @notice Allows a member to submit a new research proposal.
    /// @param _descriptionHash IPFS hash or link to the detailed proposal document.
    /// @param _fundingRequested The amount of tokens requested from the treasury.
    /// @return proposalId The ID of the newly created proposal.
    function submitResearchProposal(bytes32 _descriptionHash, uint256 _fundingRequested) external onlyMember returns (uint256 proposalId) {
        if (_fundingRequested == 0) revert DARG_ValueMustBeGreaterThanZero();

        proposalCount++;
        proposalId = proposalCount;

        projectCount++;
        uint256 projectId = projectCount;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            projectId: projectId,
            descriptionHash: _descriptionHash,
            submissionTime: uint40(block.timestamp),
            votingEndTime: 0, // Set when transitioning to Voting
            forVotes: 0,
            againstVotes: 0,
            quorumRequired: 0, // Calculated when transitioning to Voting
            approvalThreshold: 0, // Calculated when transitioning to Voting
            state: ProposalState.Draft
        });

        projects[projectId] = Project({
            proposer: msg.sender,
            fundingRequested: _fundingRequested,
            fundingReceived: 0,
            latestUpdateHash: bytes32(0),
            state: ProjectState.Proposed,
            associatedProposalId: proposalId
        });

        emit ResearchProposalSubmitted(proposalId, msg.sender, _descriptionHash, _fundingRequested);
        emit ProjectStateTransitioned(projectId, ProjectState.Proposed, ProjectState.Proposed); // Initial state transition event
    }

    /// @notice Allows the proposer to update their research proposal while it's in the Draft state.
    /// @param _proposalId The ID of the proposal to update.
    /// @param _newDescriptionHash The new IPFS hash or link.
    /// @param _newFundingRequested The new funding amount requested.
    function updateResearchProposal(uint256 _proposalId, bytes32 _newDescriptionHash, uint256 _newFundingRequested) external isProposalState(_proposalId, ProposalState.Draft) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer != msg.sender && owner() != msg.sender) revert DARG_UnauthorizedAction();
        if (_newFundingRequested == 0) revert DARG_ValueMustBeGreaterThanZero();

        proposal.descriptionHash = _newDescriptionHash;
        proposal.fundingRequested = _newFundingRequested; // This updates the value in the proposal struct only. The linked project's fundingRequested is set *on submission*. This might require a design choice: should project funding requested be mutable? For simplicity here, let's make the *proposal* mutable but the project amount fixed once proposed. *Self-correction:* It makes more sense for the proposal update to also update the linked project's *requested* funding, as that's what's being voted on. Let's update the project struct too.

        Project storage project = projects[proposal.projectId];
        project.fundingRequested = _newFundingRequested;

        emit ResearchProposalUpdated(_proposalId, _newDescriptionHash, _newFundingRequested);
    }


    /// @notice Allows the proposer or admin to transition a proposal from Draft to Voting.
    /// @param _proposalId The ID of the proposal to transition.
    function transitionProposalToVoting(uint256 _proposalId) external isProposalState(_proposalId, ProposalState.Draft) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer != msg.sender && owner() != msg.sender) revert DARG_UnauthorizedAction();
        if (address(guildToken) == address(0)) revert DARG_TokenNotSet();

        proposal.votingEndTime = uint40(block.timestamp + proposalVotingPeriod);
        proposal.quorumRequired = (totalStakedTokens * quorumRequiredPercentage) / 100; // Calculate quorum based on total staked *now*
        proposal.approvalThreshold = approvalThresholdPercentage; // Store the threshold used for this vote

        ProposalState oldState = proposal.state;
        proposal.state = ProposalState.Voting;

        emit ProposalStateTransitioned(_proposalId, oldState, ProposalState.Voting);
    }

    // --- Voting Functions ---

    /// @notice Allows a member to cast a 'For' or 'Against' vote on a proposal during the voting period.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'For' vote, False for an 'Against' vote.
    function castVote(uint256 _proposalId, bool _support) external onlyMember {
         if (_proposalId == 0 || _proposalId > proposalCount) revert DARG_ProposalNotFound();
         Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Voting) revert DARG_InvalidProposalState(proposal.state, "Voting");
        if (block.timestamp > proposal.votingEndTime) revert DARG_VotingPeriodExpired();
        if (proposalVotes[_proposalId][msg.sender]) revert DARG_AlreadyVoted();

        // Voting weight could be based on stakeAmount or reputation in future versions
        uint256 voteWeight = members[msg.sender].stakedAmount; // Using staked amount as voting power

        if (_support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }

        proposalVotes[_proposalId][msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    // --- Proposal Resolution Functions ---

    /// @notice Can be called by anyone after the voting period ends to tally votes and determine the outcome.
    /// @param _proposalId The ID of the proposal to tally.
    function tallyVotes(uint256 _proposalId) external isProposalState(_proposalId, ProposalState.Voting) {
        Proposal storage proposal = proposals[_proposalId];
        if (block.timestamp <= proposal.votingEndTime) revert DARG_VotingPeriodNotActive();

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        bool quorumMet = totalVotes >= proposal.quorumRequired;

        ProposalState oldState = proposal.state;
        bool passed = false;

        if (quorumMet) {
            uint256 forPercentage = totalVotes > 0 ? (proposal.forVotes * 100) / totalVotes : 0;
            if (forPercentage >= proposal.approvalThreshold) {
                proposal.state = ProposalState.Approved;
                passed = true;
            } else {
                proposal.state = ProposalState.Rejected;
            }
        } else {
            proposal.state = ProposalState.Rejected;
        }

        emit ProposalStateTransitioned(_proposalId, oldState, proposal.state);
        emit ProposalOutcome(_proposalId, passed, proposal.forVotes, proposal.againstVotes, totalVotes, proposal.quorumRequired, proposal.approvalThreshold);
    }

    /// @notice Executes an approved proposal by transferring funding from the treasury to the project proposer.
    /// @param _proposalId The ID of the approved proposal.
    function executeApprovedProposal(uint256 _proposalId) external isProposalState(_proposalId, ProposalState.Approved) {
        Proposal storage proposal = proposals[_proposalId];
        Project storage project = projects[proposal.projectId];

        if (treasuryBalance < project.fundingRequested) {
            // This shouldn't happen if checks are done before approving, but good safety
             proposal.state = ProposalState.Rejected; // Revert state if funding fails
             emit ProposalStateTransitioned(_proposalId, ProposalState.Approved, ProposalState.Rejected);
             revert DARG_InsufficientTreasury(project.fundingRequested, treasuryBalance);
        }

        treasuryBalance -= project.fundingRequested;
        project.fundingReceived = project.fundingRequested;

        // Transfer tokens to the project proposer
        guildToken.safeTransfer(project.proposer, project.fundingRequested);

        ProposalState oldProposalState = proposal.state;
        proposal.state = ProposalState.Implemented;

        ProjectState oldProjectState = project.state;
        project.state = ProjectState.Funded;

        emit ProposalStateTransitioned(proposal.projectId, oldProposalState, ProposalState.Implemented);
        emit ProjectStateTransitioned(proposal.projectId, oldProjectState, ProjectState.Funded);
        emit ProjectFunded(proposal.projectId, _proposalId, project.fundingRequested);
    }

    // --- Project Management Functions ---

    /// @notice Allows the project proposer to submit an update on the project's progress.
    /// @param _projectId The ID of the project.
    /// @param _updateHash IPFS hash or link to the update details.
    function submitProjectUpdate(uint256 _projectId, bytes32 _updateHash) external {
        if (_projectId == 0 || _projectId > projectCount) revert DARG_ProjectNotFound();
        Project storage project = projects[_projectId];

        if (project.proposer != msg.sender) revert DARG_UnauthorizedAction();
        if (project.state != ProjectState.Funded && project.state != ProjectState.InProgress) {
             revert DARG_InvalidProjectState(project.state, "Funded or InProgress");
        }

        project.latestUpdateHash = _updateHash;
         if (project.state == ProjectState.Funded) {
             ProjectState oldState = project.state;
             project.state = ProjectState.InProgress;
             emit ProjectStateTransitioned(_projectId, oldState, ProjectState.InProgress);
         }
        emit ProjectUpdateSubmitted(_projectId, msg.sender, _updateHash);
    }

    /// @notice Allows the project proposer or admin to mark a funded project as Completed.
    /// @param _projectId The ID of the project.
    function markProjectCompleted(uint256 _projectId) external {
         if (_projectId == 0 || _projectId > projectCount) revert DARG_ProjectNotFound();
        Project storage project = projects[_projectId];

        if (project.proposer != msg.sender && owner() != msg.sender) revert DARG_UnauthorizedAction();
         if (project.state == ProjectState.Completed || project.state == ProjectState.CompletedAndFeeCollected) {
            revert DARG_InvalidProjectState(project.state, "Not Already Completed");
         }

        ProjectState oldState = project.state;
        project.state = ProjectState.Completed; // Ready for fee collection

        emit ProjectStateTransitioned(_projectId, oldState, ProjectState.Completed);
    }

    /// @notice Can be called by anyone after a project is marked Completed to collect the completion fee.
    /// @param _projectId The ID of the project.
    function collectProjectCompletionFee(uint256 _projectId) external isProjectState(_projectId, ProjectState.Completed) {
        Project storage project = projects[_projectId];

        // Calculate fee: percentage of original funding amount
        uint256 feeAmount = (project.fundingReceived * projectCompletionFeePercentage) / 100;
        if (feeAmount > project.fundingReceived) revert DARG_FeeCalculationError(); // Should not happen with % <= 100

        treasuryBalance += feeAmount; // Add fee back to treasury

        ProjectState oldState = project.state;
        project.state = ProjectState.CompletedAndFeeCollected; // Final state after fee collection

        emit ProjectCompletionFeeCollected(_projectId, feeAmount, treasuryBalance);
        emit ProjectStateTransitioned(_projectId, oldState, ProjectState.CompletedAndFeeCollected);
    }

    // --- Reputation & Penalty Functions ---

    /// @notice Admin/Governance function to penalize a member by slashing stake and/or changing reputation.
    /// @param _member The address of the member to penalize.
    /// @param _slashAmount The amount of staked tokens to slash (burn or send elsewhere - burning here).
    /// @param _reputationChange The amount to add to the reputation score (can be negative).
    function penalizeMember(address _member, uint256 _slashAmount, int256 _reputationChange) external onlyOwner {
        // This function requires off-chain justification, but the mechanism is here.
        // In a true DAO, this would be triggered by a separate governance vote.
        if (_member == address(0)) revert DARG_ZeroAddressNotAllowed();
        Member storage member = members[_member];

        if (_slashAmount > 0) {
            uint256 actualSlashAmount = (_slashAmount > member.stakedAmount) ? member.stakedAmount : _slashAmount;
            member.stakedAmount -= actualSlashAmount;
            totalStakedTokens -= actualSlashAmount;
            // Tokens are effectively burned by not being transferred back.
            // Could also transfer to treasury or burn explicitly with guildToken.safeTransfer(address(0), actualSlashAmount)
            // Let's transfer to treasury for now.
            treasuryBalance += actualSlashAmount; // Slashing adds to treasury
            emit TokensDepositedToTreasury(address(this), actualSlashAmount, treasuryBalance); // Log as deposit from contract itself

            if (member.stakedAmount < minimumStakeAmount && member.isMember) {
                 member.isMember = false;
                 emit MembershipStatusChanged(_member, false, member.stakedAmount);
            }
        }

        // Reputation update
        member.reputation += _reputationChange;

        emit MemberPenalized(_member, _slashAmount, _reputationChange);
        emit MemberReputationUpdated(_member, _reputationChange, member.reputation);
    }

    /// @notice Admin/Governance function to manually adjust a member's reputation.
    /// @param _member The address of the member.
    /// @param _reputationChange The amount to add to the reputation score (can be negative).
    function updateMemberReputation(address _member, int256 _reputationChange) external onlyOwner {
        if (_member == address(0)) revert DARG_ZeroAddressNotAllowed();
         Member storage member = members[_member];
         member.reputation += _reputationChange;
         emit MemberReputationUpdated(_member, _reputationChange, member.reputation);
    }

    // --- Reward Distribution Functions ---

    /// @notice Admin/Governance function to distribute rewards from the treasury to members.
    /// @param _members Array of member addresses.
    /// @param _amounts Array of amounts to distribute to each member.
    function distributeRewards(address[] calldata _members, uint256[] calldata _amounts) external onlyOwner {
        if (_members.length != _amounts.length || _members.length == 0) revert DARG_ArraysLengthMismatch();
        if (address(guildToken) == address(0)) revert DARG_TokenNotSet();

        uint256 totalRewardAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            if (_members[i] == address(0)) revert DARG_ZeroAddressNotAllowed();
             totalRewardAmount += _amounts[i];
        }

        if (treasuryBalance < totalRewardAmount) revert DARG_InsufficientTreasury(totalRewardAmount, treasuryBalance);
        treasuryBalance -= totalRewardAmount;

        for (uint i = 0; i < _members.length; i++) {
            if (_amounts[i] > 0) {
                guildToken.safeTransfer(_members[i], _amounts[i]);
                emit RewardsDistributed(_members[i], _amounts[i]);
            }
        }
    }

    // --- View Functions ---

    /// @notice Gets the staking and reputation details for a member.
    /// @param _member The address of the member.
    /// @return isMember Whether the address is currently a member.
    /// @return stakedAmount The amount of tokens staked by the member.
    /// @return stakeStartTime The timestamp when the current stake period started.
    /// @return reputation The member's reputation score.
    function getMemberDetails(address _member) external view returns (bool isMember, uint256 stakedAmount, uint40 stakeStartTime, int256 reputation) {
        Member storage member = members[_member];
        return (member.isMember, member.stakedAmount, member.stakeStartTime, member.reputation);
    }

    /// @notice Gets the details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return proposer The address of the proposer.
    /// @return projectId The ID of the associated project.
    /// @return descriptionHash The IPFS hash or link.
    /// @return submissionTime The proposal submission timestamp.
    /// @return votingEndTime The timestamp when voting ends.
    /// @return forVotes Total votes for the proposal.
    /// @return againstVotes Total votes against the proposal.
    /// @return quorumRequired The quorum required for this proposal.
    /// @return approvalThreshold The approval percentage required for this proposal.
    /// @return state The current state of the proposal.
    function getProposalDetails(uint256 _proposalId) external view returns (address proposer, uint256 projectId, bytes32 descriptionHash, uint40 submissionTime, uint40 votingEndTime, uint256 forVotes, uint256 againstVotes, uint256 quorumRequired, uint256 approvalThreshold, ProposalState state) {
         if (_proposalId == 0 || _proposalId > proposalCount) revert DARG_ProposalNotFound();
         Proposal storage proposal = proposals[_proposalId];
         return (proposal.proposer, proposal.projectId, proposal.descriptionHash, proposal.submissionTime, proposal.votingEndTime, proposal.forVotes, proposal.againstVotes, proposal.quorumRequired, proposal.approvalThreshold, proposal.state);
    }

     /// @notice Gets the details of a specific project.
     /// @param _projectId The ID of the project.
     /// @return proposer The address of the project researcher.
     /// @return fundingRequested The amount of funding requested.
     /// @return fundingReceived The amount of funding actually transferred.
     /// @return latestUpdateHash The IPFS hash or link for the latest update.
     /// @return state The current state of the project.
     /// @return associatedProposalId The ID of the proposal that funded this project.
    function getProjectDetails(uint256 _projectId) external view returns (address proposer, uint256 fundingRequested, uint256 fundingReceived, bytes32 latestUpdateHash, ProjectState state, uint256 associatedProposalId) {
         if (_projectId == 0 || _projectId > projectCount) revert DARG_ProjectNotFound();
        Project storage project = projects[_projectId];
        return (project.proposer, project.fundingRequested, project.fundingReceived, project.latestUpdateHash, project.state, project.associatedProposalId);
    }

    /// @notice Gets the total number of tokens currently staked in the guild.
    /// @return The total staked amount.
    function getTotalStaked() external view returns (uint256) {
        return totalStakedTokens;
    }

    /// @notice Gets the current balance of the guild's treasury.
    /// @return The treasury balance.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    /// @notice Gets the current state of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The state of the proposal.
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
         if (_proposalId == 0 || _proposalId > proposalCount) revert DARG_ProposalNotFound();
         return proposals[_proposalId].state;
    }

    /// @notice Gets the current state of a specific project.
    /// @param _projectId The ID of the project.
    /// @return The state of the project.
    function getProjectState(uint256 _projectId) external view returns (ProjectState) {
         if (_projectId == 0 || _projectId > projectCount) revert DARG_ProjectNotFound();
         return projects[_projectId].state;
    }

    /// @notice Checks if a member's stake lock duration has passed.
    /// @param _member The address of the member.
    /// @return True if the member can unstake, false otherwise.
    function canUnstake(address _member) external view returns (bool) {
        Member storage member = members[_member];
        return block.timestamp >= member.stakeStartTime + stakingLockDuration;
    }

    /// @notice Checks if the voting period for a proposal is currently active.
    /// @param _proposalId The ID of the proposal.
    /// @return True if the voting period is active, false otherwise.
    function isVotingPeriodActive(uint256 _proposalId) external view returns (bool) {
         if (_proposalId == 0 || _proposalId > proposalCount) return false; // Or revert
         Proposal storage proposal = proposals[_proposalId];
         return proposal.state == ProposalState.Voting && block.timestamp <= proposal.votingEndTime;
    }

     /// @notice Checks if a member has already voted on a specific proposal.
     /// @param _proposalId The ID of the proposal.
     /// @param _member The address of the member.
     /// @return True if the member has voted, false otherwise.
    function hasMemberVoted(uint256 _proposalId, address _member) external view returns (bool) {
        if (_proposalId == 0 || _proposalId > proposalCount) return false; // Or revert
        return proposalVotes[_proposalId][_member];
    }

    // Functions inherited from Ownable (also count towards the total):
    // 35. owner()
    // 36. renounceOwnership()
    // 37. transferOwnership(address newOwner)
}
```