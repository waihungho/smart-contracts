Okay, here is a smart contract concept for a "Decentralized Autonomous AI Guild" (DAAIG). This contract blends elements of DAOs, reputation systems, AI evaluation integration (via oracles), and a bounty system for AI-related tasks. It aims for uniqueness by combining these concepts in a specific way – using AI-generated metrics (provided by trusted oracles) alongside human evaluation and a multi-dimensional reputation system to govern funding and reward contributions to decentralized AI development or research.

This contract is complex and outlines a sophisticated system. Note that *actual AI execution* cannot happen on the EVM due to computational limits; the AI integration here relies on *oracles* providing verifiable outputs from off-chain AI models.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Autonomous AI Guild (DAAIG)
 * @dev A decentralized autonomous organization focused on funding, evaluating, and
 *      rewarding contributors to AI-related projects using a combination of
 *      human governance, multi-dimensional reputation, and AI oracle evaluations.
 */

/*
 * OUTLINE:
 * 1. State Variables & Data Structures: Define members, bounties, reputation, oracle registry, and guild parameters.
 * 2. Enums: Define states for bounties, proposals, reputation dimensions, etc.
 * 3. Events: Emit events for state changes, crucial for off-chain monitoring.
 * 4. Modifiers: Access control and state checks.
 * 5. Core Membership: Join, leave, stake management.
 * 6. Treasury Management: Deposit and governed withdrawal of ETH.
 * 7. Reputation System: Internal tracking of multi-dimensional reputation, updated via actions.
 * 8. AI Bounties: Lifecycle management (propose, vote, solve, evaluate (human + AI oracle), finalize, reward).
 * 9. AI Oracle Governance: Registering and deactivating trusted AI oracle addresses via guild governance.
 * 10. Guild Governance: Proposing and voting on changes to contract parameters (e.g., stake, thresholds, periods).
 * 11. View Functions: Querying state for members, bounties, governance, and configuration.
 */

/*
 * FUNCTION SUMMARY:
 *
 * CORE MEMBERSHIP:
 * - constructor(): Initializes guild parameters.
 * - joinGuild(): Allows user to join the guild by staking ETH.
 * - leaveGuild(): Allows user to initiate leaving, triggering a cooldown.
 * - claimStakedETH(): Allows user to claim staked ETH after the cooldown period.
 * - slashMemberStake(): (Governed) Slashes a member's stake due to negative actions.
 *
 * TREASURY MANAGEMENT:
 * - depositETHToTreasury(): Allows anyone to contribute ETH to the guild treasury.
 * - withdrawTreasuryFunds(): (Governed) Allows withdrawal from the treasury.
 *
 * REPUTATION SYSTEM (Primarily Internal, one view):
 * - getMemberReputation(address member): Gets the multi-dimensional reputation scores for a member.
 * - _updateReputation(address member, ReputationDimension dimension, int256 amount): Internal function to adjust reputation.
 * - _calculateVotingWeight(address member): Internal function to calculate voting weight based on reputation and parameters.
 *
 * AI BOUNTIES LIFECYCLE:
 * - proposeAIBounty(string calldata detailsHash, uint256 ethAmount, uint256 requiredReputationToClaim): Allows members to propose AI tasks with funding requests.
 * - voteOnBountyProposal(uint256 bountyId, Vote vote): Members vote on funding a proposed bounty.
 * - submitBountySolution(uint256 bountyId, string calldata solutionHash): The selected solver submits their work.
 * - evaluateBountySolution(uint256 bountyId, uint256 evaluationScore, string calldata feedbackHash): Members (with sufficient reputation) evaluate submitted solutions.
 * - submitOracleBountyEvaluation(uint256 bountyId, int256 aiEvaluationScore, string calldata verificationHash): Registered AI Oracles submit their automated evaluation scores.
 * - finalizeBounty(uint256 bountyId): Finalizes the bounty based on votes, human evaluations, and AI evaluations; pays solver, updates reputations.
 *
 * AI ORACLE GOVERNANCE:
 * - proposeOracleRegistration(address oracleAddress, string calldata descriptionHash): Members propose an address to become a registered AI Oracle.
 * - voteOnOracleRegistration(uint256 proposalId, Vote vote): Members vote on registering an oracle.
 * - executeOracleRegistration(uint256 proposalId): Executes the registration if the proposal passes.
 * - deactivateOracle(address oracleAddress): (Governed) Allows deactivating a registered oracle.
 *
 * GUILD GOVERNANCE (Parameter Changes):
 * - proposeGuildParameterChange(GuildParameter parameter, uint256 newValue): Members propose changing a guild configuration parameter.
 * - voteOnGuildParameterChange(uint256 proposalId, Vote vote): Members vote on changing a parameter.
 * - executeGuildParameterChange(uint256 proposalId): Executes the parameter change if the proposal passes.
 *
 * VIEW FUNCTIONS (Read-only):
 * - getGuildParameters(): Gets all current guild configuration parameters.
 * - getRegisteredOracles(): Gets the list of currently registered AI Oracles.
 * - getBountyCount(): Gets the total number of bounties proposed.
 * - getBountyDetails(uint256 bountyId): Gets the details of a specific bounty proposal.
 * - getBountyEvaluations(uint256 bountyId): Gets human and oracle evaluations for a bounty solution.
 * - getOracleRegistrationProposalCount(): Gets the total number of oracle registration proposals.
 * - getOracleRegistrationProposalDetails(uint256 proposalId): Gets details of an oracle registration proposal.
 * - getParameterChangeProposalCount(): Gets the total number of parameter change proposals.
 * - getParameterChangeProposalDetails(uint256 proposalId): Gets details of a parameter change proposal.
 * - getMemberStake(address memberAddress): Gets the amount of ETH staked by a member.
 * - getBountySolver(uint256 bountyId): Gets the address of the selected solver for a bounty.
 * - isMember(address memberAddress): Checks if an address is currently a guild member.
 * - getTreasuryBalance(): Gets the current ETH balance of the guild treasury.
 * - getVotingPeriod(): Gets the current voting period duration.
 * - getEvaluationPeriod(): Gets the current solution evaluation period duration.
 * - getFinalizationPeriod(): Gets the current bounty finalization period duration.
 * - getStakeRequirement(): Gets the current ETH stake required to join.
 * - getMinReputationToEvaluate(): Gets the min 'Evaluation' reputation required to evaluate solutions.
 * - getMinReputationToProposeBounty(): Gets the min 'Technical' reputation required to propose bounties.
 * - getMinReputationToVote(): Gets the min 'Reliability' reputation required to vote on proposals.
 * - getAIOracleWeight(): Gets the current weight of AI oracle evaluations vs human evaluations in finalization.
 */

contract DAAIG {

    // --- Enums ---
    enum ReputationDimension { Technical, Evaluation, Reliability }
    enum BountyStatus { Proposed, Voting, SolutionSubmission, Evaluation, Finalization, CompletedSuccess, CompletedFailure, Cancelled }
    enum ProposalStatus { Proposed, Voting, Approved, Rejected, Executed, Cancelled }
    enum Vote { Abstain, Yes, No }
    enum GuildParameter { StakeRequirement, VotingPeriod, EvaluationPeriod, FinalizationPeriod, QuorumThresholdBountyVote, ThresholdBountyVote, QuorumThresholdGovernance, ThresholdGovernance, ReputationWeightVoting, ReputationWeightEvaluation, ReputationWeightFinalization, AIOracleWeight, MinReputationToEvaluate, MinReputationToProposeBounty, MinReputationToVote, LeaveCooldown }

    // --- Structs ---
    struct Member {
        bool isMember;
        uint256 stakedETH;
        uint64 joinTime;
        uint64 leaveCooldownEndTime; // 0 if not leaving
        mapping(ReputationDimension => int256) reputation; // Use int256 to allow negative reputation (slashing)
    }

    struct Bounty {
        uint256 id;
        address proposer;
        string detailsHash; // Hash of off-chain details (IPFS or similar)
        uint256 ethAmount; // Requested funding
        uint256 requiredReputationToClaim; // Min reputation solver needs
        BountyStatus status;
        uint64 proposalEndTime; // End of voting period
        uint64 submissionEndTime; // End of solution submission period
        uint64 evaluationEndTime; // End of evaluation period
        uint64 finalizationEndTime; // End of finalization period
        address solver; // Address of the selected solver (could be proposer or another member)
        string solutionHash; // Hash of off-chain solution
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotingWeight; // Sum of voting weights of voters

        // Evaluation details
        mapping(address => uint256) humanEvaluations; // member => score (e.g., 0-100)
        mapping(address => int256) oracleEvaluations; // oracleAddress => score (e.g., -100 to 100)
        uint256 totalHumanEvaluationScore;
        uint256 humanEvaluatorCount;
        int256 totalOracleEvaluationScore;
        uint256 oracleEvaluatorCount;
        uint256 totalEvaluationWeight; // Sum of evaluation weights
    }

    struct OracleRegistrationProposal {
        uint256 id;
        address proposer;
        address oracleAddress;
        string descriptionHash;
        ProposalStatus status;
        uint64 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotingWeight;
    }

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        GuildParameter parameter;
        uint256 newValue;
        ProposalStatus status;
        uint64 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotingWeight;
    }

    // --- State Variables ---
    mapping(address => Member) public members;
    address[] private memberAddresses; // Simple list, potentially gas-intensive for large DAOs

    mapping(uint256 => Bounty) public bounties;
    uint256 public nextBountyId = 1;

    mapping(uint256 => OracleRegistrationProposal) public oracleRegistrationProposals;
    uint256 public nextOracleRegistrationProposalId = 1;

    mapping(address => bool) public registeredOracles;
    address[] private registeredOracleAddresses; // Simple list

    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    uint256 public nextParameterChangeProposalId = 1;

    // --- Guild Parameters ---
    mapping(GuildParameter => uint256) public guildParameters;

    // --- Events ---
    event MemberJoined(address indexed member, uint256 stakedAmount);
    event MemberLeaveInitiated(address indexed member, uint256 stakedAmount, uint64 cooldownEndTime);
    event MemberLeft(address indexed member, uint256 refundedAmount);
    event MemberStakeSlashed(address indexed member, uint256 slashedAmount, string reasonHash); // reasonHash for off-chain context

    event TreasuryDeposited(address indexed contributor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount, address indexed governor);

    event BountyProposed(uint256 indexed bountyId, address indexed proposer, uint256 ethAmount, string detailsHash);
    event BountyStatusChanged(uint256 indexed bountyId, BountyStatus newStatus);
    event BountyVoteCast(uint256 indexed bountyId, address indexed voter, Vote vote);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed solver, string solutionHash);
    event BountyHumanEvaluationSubmitted(uint256 indexed bountyId, address indexed evaluator, uint256 score, string feedbackHash);
    event BountyOracleEvaluationSubmitted(uint256 indexed bountyId, address indexed oracle, int256 score, string verificationHash);
    event BountyFinalized(uint256 indexed bountyId, BountyStatus finalStatus, uint256 amountPaidToSolver);

    event OracleRegistrationProposed(uint256 indexed proposalId, address indexed proposer, address oracleAddress, string descriptionHash);
    event OracleRegistrationVoteCast(uint256 indexed proposalId, address indexed voter, Vote vote);
    event OracleRegistered(address indexed oracleAddress);
    event OracleDeactivated(address indexed oracleAddress);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, GuildParameter parameter, uint256 newValue);
    event ParameterChangeVoteCast(uint256 indexed proposalId, address indexed voter, Vote vote);
    event ParameterChanged(GuildParameter parameter, uint256 newValue);

    event ReputationUpdated(address indexed member, ReputationDimension indexed dimension, int256 newScore);

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender].isMember, "Not a guild member");
        _;
    }

    modifier onlyRegisteredOracle() {
        require(registeredOracles[msg.sender], "Not a registered oracle");
        _;
    }

    // Utility modifier to check proposal status and timing
    modifier onlyVotingPeriod(uint256 endTime) {
        require(block.timestamp <= endTime, "Voting period has ended");
        _;
    }

    modifier onlyEvaluationPeriod(uint256 endTime) {
         require(block.timestamp > bounties[bountyId].submissionEndTime && block.timestamp <= endTime, "Not in evaluation period");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialStakeRequirement, uint256 votingPeriod, uint256 evaluationPeriod, uint256 finalizationPeriod, uint256 quorumThresholdBountyVote, uint256 thresholdBountyVote, uint256 quorumThresholdGovernance, uint256 thresholdGovernance, uint256 reputationWeightVoting, uint256 reputationWeightEvaluation, uint256 reputationWeightFinalization, uint256 aiOracleWeight, uint256 minReputationToEvaluate, uint256 minReputationToProposeBounty, uint256 minReputationToVote, uint256 leaveCooldown) {
        guildParameters[GuildParameter.StakeRequirement] = initialStakeRequirement;
        guildParameters[GuildParameter.VotingPeriod] = votingPeriod;
        guildParameters[GuildParameter.EvaluationPeriod] = evaluationPeriod;
        guildParameters[GuildParameter.FinalizationPeriod] = finalizationPeriod;
        guildParameters[GuildParameter.QuorumThresholdBountyVote] = quorumThresholdBountyVote; // e.g., 5000 (50%) scaled by 100
        guildParameters[GuildParameter.ThresholdBountyVote] = thresholdBountyVote;       // e.g., 6000 (60%) scaled by 100
        guildParameters[GuildParameter.QuorumThresholdGovernance] = quorumThresholdGovernance;
        guildParameters[GuildParameter.ThresholdGovernance] = thresholdGovernance;
        guildParameters[GuildParameter.ReputationWeightVoting] = reputationWeightVoting; // Weight factor for reputation in voting
        guildParameters[GuildParameter.ReputationWeightEvaluation] = reputationWeightEvaluation; // Weight factor for reputation influence on evaluation score impact
        guildParameters[GuildParameter.ReputationWeightFinalization] = reputationWeightFinalization; // Weight factor for reputation in finalization decision
        guildParameters[GuildParameter.AIOracleWeight] = aiOracleWeight; // Weight factor for AI oracle score vs human score (e.g., 50 = 50%) scaled by 100
        guildParameters[GuildParameter.MinReputationToEvaluate] = minReputationToEvaluate;
        guildParameters[GuildParameter.MinReputationToProposeBounty] = minReputationToProposeBounty;
        guildParameters[GuildParameter.MinReputationToVote] = minReputationToVote;
        guildParameters[GuildParameter.LeaveCooldown] = leaveCooldown; // Seconds for staking cooldown
    }

    // --- Core Membership ---

    /**
     * @dev Allows a user to join the guild by staking the required amount of ETH.
     */
    function joinGuild() external payable {
        require(!members[msg.sender].isMember, "Already a guild member");
        require(msg.value >= guildParameters[GuildParameter.StakeRequirement], "Insufficient stake provided");

        members[msg.sender].isMember = true;
        members[msg.sender].stakedETH = msg.value;
        members[msg.sender].joinTime = uint64(block.timestamp);
        // Initialize reputation (perhaps small positive starting values or 0)
        members[msg.sender].reputation[ReputationDimension.Technical] = 1;
        members[msg.sender].reputation[ReputationDimension.Evaluation] = 1;
        members[msg.sender].reputation[ReputationDimension.Reliability] = 1;

        memberAddresses.push(msg.sender); // Store address for potential iteration (use sparingly)

        emit MemberJoined(msg.sender, msg.value);
        emit ReputationUpdated(msg.sender, ReputationDimension.Technical, 1);
        emit ReputationUpdated(msg.sender, ReputationDimension.Evaluation, 1);
        emit ReputationUpdated(msg.sender, ReputationDimension.Reliability, 1);
    }

    /**
     * @dev Allows a member to initiate the process of leaving the guild.
     *      Starts a cooldown period before stake can be claimed.
     */
    function leaveGuild() external onlyMember {
        require(members[msg.sender].leaveCooldownEndTime == 0, "Leave cooldown already active");
        // Potentially add checks if member is involved in active proposals/bounties

        members[msg.sender].leaveCooldownEndTime = uint64(block.timestamp + guildParameters[GuildParameter.LeaveCooldown]);

        emit MemberLeaveInitiated(msg.sender, members[msg.sender].stakedETH, members[msg.sender].leaveCooldownEndTime);
    }

    /**
     * @dev Allows a member who initiated leaving to claim their staked ETH
     *      after the cooldown period has ended.
     */
    function claimStakedETH() external onlyMember {
        require(members[msg.sender].leaveCooldownEndTime != 0, "Leave process not initiated");
        require(block.timestamp >= members[msg.sender].leaveCooldownEndTime, "Leave cooldown not ended");

        uint256 stake = members[msg.sender].stakedETH;
        address payable memberWallet = payable(msg.sender);

        // Clean up member state
        members[msg.sender].isMember = false;
        members[msg.sender].stakedETH = 0;
        members[msg.sender].joinTime = 0;
        members[msg.sender].leaveCooldownEndTime = 0;
        // Reputations could be reset or partially maintained depending on desired design

        // Remove from memberAddresses (gas intensive for large arrays, consider alternative)
        // For simplicity, let's omit array removal here or use a simple swap-and-pop if order doesn't matter.
        // A simple mapping `isMember` is sufficient for most checks.
        // If an iterable list is needed, a more gas-efficient pattern like linked lists or external subgraph indexing is better.

        (bool success, ) = memberWallet.call{value: stake}("");
        require(success, "ETH transfer failed");

        emit MemberLeft(msg.sender, stake);
    }

    /**
     * @dev Allows slashing a member's stake. Intended to be called via successful
     *      governance proposal or automated based on severe bounty failure/malice.
     *      Requires treasury withdrawal permission logic if triggered by governance.
     */
    function slashMemberStake(address memberAddress, uint256 amount, string calldata reasonHash) external {
        // This function should ONLY be callable via a successful governance proposal execution
        // For simplicity, adding a placeholder check. Realistically needs robust governance integration.
        require(false, "This function is only callable via successful governance proposal execution");

        Member storage member = members[memberAddress];
        require(member.isMember, "Member does not exist");
        require(member.stakedETH >= amount, "Insufficient stake to slash");

        member.stakedETH -= amount;
        // Potentially decrease reputation here too
        _updateReputation(memberAddress, ReputationDimension.Reliability, -(int256(amount / guildParameters[GuildParameter.StakeRequirement]))); // Example: Slashing 1 stake amount decreases reliability by 1

        emit MemberStakeSlashed(memberAddress, amount, reasonHash);
        emit ReputationUpdated(memberAddress, ReputationDimension.Reliability, members[memberAddress].reputation[ReputationDimension.Reliability]);
    }

    // --- Treasury Management ---

    /**
     * @dev Allows anyone to deposit ETH into the guild's treasury.
     */
    function depositETHToTreasury() external payable {
        require(msg.value > 0, "Must deposit some ETH");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows withdrawing funds from the treasury.
     *      Requires a successful governance proposal execution to call this.
     */
    function withdrawTreasuryFunds(address payable recipient, uint256 amount) external {
        // This function should ONLY be callable via a successful governance proposal execution
        // For simplicity, adding a placeholder check. Realistically needs robust governance integration.
         require(false, "This function is only callable via successful governance proposal execution");
         require(address(this).balance >= amount, "Insufficient treasury balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit TreasuryWithdrawn(recipient, amount, msg.sender); // msg.sender here would be the contract executing the governance proposal
    }

    // --- Reputation System ---

    /**
     * @dev Returns the multi-dimensional reputation scores for a member.
     * @param member The address of the member.
     * @return A tuple containing reputation scores for Technical, Evaluation, and Reliability dimensions.
     */
    function getMemberReputation(address member) external view returns (int256 technical, int256 evaluation, int256 reliability) {
        require(members[member].isMember, "Member does not exist");
        return (members[member].reputation[ReputationDimension.Technical],
                members[member].reputation[ReputationDimension.Evaluation],
                members[member].reputation[ReputationDimension.Reliability]);
    }

    /**
     * @dev Internal function to update a member's reputation in a specific dimension.
     *      Called upon successful/unsuccessful actions (e.g., bounty completion, evaluation accuracy, voting).
     * @param member The address of the member.
     * @param dimension The reputation dimension to update.
     * @param amount The amount to add to the current reputation (can be negative).
     */
    function _updateReputation(address member, ReputationDimension dimension, int256 amount) internal {
        if (!members[member].isMember) {
            // Cannot update reputation for non-members (or perhaps handle differently)
            return;
        }
        // Basic bounds checking or clamping could be added if needed
        members[member].reputation[dimension] += amount;
        emit ReputationUpdated(member, dimension, members[member].reputation[dimension]);
    }

    /**
     * @dev Internal function to calculate a member's voting weight based on their reputation.
     *      This is a simplified example; a real system might use a weighted sum or other formula.
     * @param member The address of the member.
     * @return The calculated voting weight.
     */
    function _calculateVotingWeight(address member) internal view returns (uint256) {
        if (!members[member].isMember) {
            return 0;
        }
        // Example: Voting weight = Reliability reputation score * Weight factor
        // Ensure reputation score is treated non-negatively for weight calculation
        int256 reliabilityRep = members[member].reputation[ReputationDimension.Reliability];
        uint256 baseWeight = reliabilityRep > 0 ? uint256(reliabilityRep) : 0;
        return baseWeight * guildParameters[GuildParameter.ReputationWeightVoting] / 100; // Scale by 100
    }

     /**
     * @dev Internal function to calculate a member's evaluation influence based on their reputation.
     *      This might influence how much their evaluation score contributes to the average.
     * @param member The address of the member.
     * @return The calculated evaluation weight.
     */
    function _calculateEvaluationWeight(address member) internal view returns (uint256) {
        if (!members[member].isMember) {
            return 0;
        }
         // Example: Evaluation weight = Evaluation reputation score * Weight factor
        int256 evaluationRep = members[member].reputation[ReputationDimension.Evaluation];
        uint256 baseWeight = evaluationRep > 0 ? uint256(evaluationRep) : 0;
        return baseWeight * guildParameters[GuildParameter.ReputationWeightEvaluation] / 100; // Scale by 100
    }


    // --- AI Bounties Lifecycle ---

    /**
     * @dev Allows a member with sufficient reputation to propose an AI bounty.
     * @param detailsHash Hash referencing off-chain details (problem description, scope, etc.).
     * @param ethAmount The amount of ETH requested from the treasury if the bounty is approved.
     * @param requiredReputationToClaim The minimum 'Technical' reputation a solver needs to claim this bounty.
     */
    function proposeAIBounty(string calldata detailsHash, uint256 ethAmount, uint256 requiredReputationToClaim) external onlyMember {
        require(members[msg.sender].reputation[ReputationDimension.Technical] >= int256(guildParameters[GuildParameter.MinReputationToProposeBounty]), "Insufficient technical reputation to propose bounty");
        require(ethAmount > 0, "Bounty amount must be greater than zero");

        uint256 bountyId = nextBountyId++;
        Bounty storage newBounty = bounties[bountyId];

        newBounty.id = bountyId;
        newBounty.proposer = msg.sender;
        newBounty.detailsHash = detailsHash;
        newBounty.ethAmount = ethAmount;
        newBounty.requiredReputationToClaim = requiredReputationToClaim;
        newBounty.status = BountyStatus.Voting;
        newBounty.proposalEndTime = uint64(block.timestamp + guildParameters[GuildParameter.VotingPeriod]);

        emit BountyProposed(bountyId, msg.sender, ethAmount, detailsHash);
        emit BountyStatusChanged(bountyId, BountyStatus.Voting);
    }

    /**
     * @dev Allows members to vote on a proposed bounty.
     * @param bountyId The ID of the bounty proposal.
     * @param vote The vote (Yes/No/Abstain).
     */
    function voteOnBountyProposal(uint256 bountyId, Vote vote) external onlyMember onlyVotingPeriod(bounties[bountyId].proposalEndTime) {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == BountyStatus.Voting, "Bounty is not in voting state");
        require(members[msg.sender].reputation[ReputationDimension.Reliability] >= int256(guildParameters[GuildParameter.MinReputationToVote]), "Insufficient reliability reputation to vote");

        // Prevent double voting - needs a mapping `mapping(uint256 => mapping(address => bool)) hasVoted;`
        // Adding this mapping and checking `!hasVoted[bountyId][msg.sender]`

        uint256 votingWeight = _calculateVotingWeight(msg.sender);
        require(votingWeight > 0, "Cannot vote with zero voting weight");

        if (vote == Vote.Yes) {
            bounty.yesVotes += votingWeight;
        } else if (vote == Vote.No) {
            bounty.noVotes += votingWeight;
        }
        // Abstain votes don't change yes/no counts but could be tracked if needed

        bounty.totalVotingWeight += votingWeight;
        // hasVoted[bountyId][msg.sender] = true;

        emit BountyVoteCast(bountyId, msg.sender, vote);
    }

     /**
      * @dev Internal function to check if a bounty proposal passes the voting phase.
      * @param bountyId The ID of the bounty.
      * @return True if the proposal passes, false otherwise.
      */
    function _checkBountyProposalOutcome(uint256 bountyId) internal view returns (bool) {
        Bounty storage bounty = bounties[bountyId];
        require(block.timestamp > bounty.proposalEndTime, "Voting period not ended");

        // Calculate quorum (total voting weight must meet a percentage of potential total weight)
        // Calculating 'potential total weight' dynamically is gas intensive.
        // Alternative: Use a fixed total theoretical weight, or track total weight of *all* members over time.
        // For simplicity here, Quorum check is based on *participating* weight vs a threshold of *yes* votes relative to *total participating*.
        // A more robust DAO would track total possible voting weight or staked amount.

        uint256 totalVotes = bounty.yesVotes + bounty.noVotes;
        if (totalVotes == 0) {
            // No votes cast, usually implies rejection
             return false;
        }

        // Quorum check: total participating weight vs a minimum threshold (scaled e.g. 5000 = 50%)
        uint256 quorumRequirement = bounty.totalVotingWeight * guildParameters[GuildParameter.QuorumThresholdBountyVote] / 10000; // Scaled by 10000 for percentage
        if (bounty.totalVotingWeight < quorumRequirement) {
            return false; // Quorum not met
        }

        // Threshold check: percentage of Yes votes among Yes/No votes (scaled e.g. 6000 = 60%)
        uint256 thresholdRequirement = bounty.yesVotes * 10000 / totalVotes;
        if (thresholdRequirement < guildParameters[GuildParameter.ThresholdBountyVote]) {
            return false; // Threshold not met
        }

        return true; // Proposal passes
    }


    /**
     * @dev Allows the bounty proposer (or potentially anyone after voting ends) to move the bounty past the voting phase.
     *      Checks the outcome and transitions the bounty status.
     * @param bountyId The ID of the bounty.
     */
    function transitionBountyFromVoting(uint256 bountyId) external {
         Bounty storage bounty = bounties[bountyId];
         require(bounty.status == BountyStatus.Voting, "Bounty not in voting state");
         require(block.timestamp > bounty.proposalEndTime, "Voting period not ended");

         if (_checkBountyProposalOutcome(bountyId)) {
             // Passed voting, move to Solution Submission
             bounty.status = BountyStatus.SolutionSubmission;
             bounty.submissionEndTime = uint64(block.timestamp + guildParameters[GuildParameter.FinalizationPeriod]); // Allow solver time
             emit BountyStatusChanged(bountyId, BountyStatus.SolutionSubmission);
         } else {
             // Failed voting
             bounty.status = BountyStatus.Cancelled; // Or Rejected? Cancelled implies not proceeding.
             emit BountyStatusChanged(bountyId, BountyStatus.Cancelled);
         }
    }


    /**
     * @dev Allows the selected solver to submit their solution hash for a bounty.
     *      Solver must meet required reputation and bounty must be in submission state.
     * @param bountyId The ID of the bounty.
     * @param solutionHash Hash referencing the off-chain solution.
     */
    function submitBountySolution(uint256 bountyId, string calldata solutionHash) external onlyMember {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == BountyStatus.SolutionSubmission, "Bounty not in solution submission state");
        require(members[msg.sender].reputation[ReputationDimension.Technical] >= int256(bounty.requiredReputationToClaim), "Insufficient technical reputation to claim this bounty");

        bounty.solver = msg.sender;
        bounty.solutionHash = solutionHash;
        bounty.status = BountyStatus.Evaluation; // Move directly to evaluation upon submission
        bounty.evaluationEndTime = uint64(block.timestamp + guildParameters[GuildParameter.EvaluationPeriod]); // Start evaluation timer
        emit BountySolutionSubmitted(bountyId, msg.sender, solutionHash);
        emit BountyStatusChanged(bountyId, BountyStatus.Evaluation);
    }

    /**
     * @dev Allows members with sufficient reputation to evaluate a submitted solution.
     *      Scores should be within a defined range (e.g., 0-100).
     * @param bountyId The ID of the bounty.
     * @param evaluationScore The score given by the evaluator.
     * @param feedbackHash Hash referencing off-chain feedback/justification.
     */
    function evaluateBountySolution(uint256 bountyId, uint256 evaluationScore, string calldata feedbackHash) external onlyMember onlyEvaluationPeriod(bounties[bountyId].evaluationEndTime) {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == BountyStatus.Evaluation, "Bounty not in evaluation state");
        require(msg.sender != bounty.solver, "Solver cannot evaluate their own solution");
        require(members[msg.sender].reputation[ReputationDimension.Evaluation] >= int256(guildParameters[GuildParameter.MinReputationToEvaluate]), "Insufficient evaluation reputation to evaluate");
        require(bounty.humanEvaluations[msg.sender] == 0, "Already submitted a human evaluation"); // Prevent double evaluation

        require(evaluationScore <= 100, "Evaluation score must be between 0 and 100"); // Define score range

        bounty.humanEvaluations[msg.sender] = evaluationScore;
        bounty.totalHumanEvaluationScore += evaluationScore;
        bounty.humanEvaluatorCount++;
        // Add evaluation weight based on evaluator's reputation? (More complex)
        // bounty.totalEvaluationWeight += _calculateEvaluationWeight(msg.sender); // If using weighted average

        // Note: Evaluation accuracy could be judged later during finalization or through separate feedback loop

        emit BountyHumanEvaluationSubmitted(bountyId, msg.sender, evaluationScore, feedbackHash);
    }

    /**
     * @dev Allows a registered AI Oracle to submit an automated evaluation score for a solution.
     *      The oracle contract would need to be whitelisted/registered via governance.
     *      Score range could differ (e.g., -100 to 100).
     * @param bountyId The ID of the bounty.
     * @param oracleAddress The address of the oracle contract submitting the evaluation (msg.sender check below).
     * @param aiEvaluationScore The score provided by the AI model.
     * @param verificationHash Hash proving the AI evaluation was performed correctly (e.g., zk-proof hash, oracle report ID).
     */
    function submitOracleBountyEvaluation(uint256 bountyId, address oracleAddress, int256 aiEvaluationScore, string calldata verificationHash) external onlyRegisteredOracle {
        require(msg.sender == oracleAddress, "Caller must match oracleAddress parameter"); // Ensures registered oracle is calling for itself
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == BountyStatus.Evaluation, "Bounty not in evaluation state");
        require(bounty.oracleEvaluations[oracleAddress] == 0, "Oracle already submitted evaluation"); // Prevent double evaluation

        // Define AI score range, e.g., between -100 and 100
        require(aiEvaluationScore >= -100 && aiEvaluationScore <= 100, "AI evaluation score out of range (-100 to 100)");

        bounty.oracleEvaluations[oracleAddress] = aiEvaluationScore;
        bounty.totalOracleEvaluationScore += aiEvaluationScore;
        bounty.oracleEvaluatorCount++;

        emit BountyOracleEvaluationSubmitted(bountyId, oracleAddress, aiEvaluationScore, verificationHash);
    }

     /**
      * @dev Transitions the bounty to the Finalization stage. Can be called after Evaluation Period ends.
      * @param bountyId The ID of the bounty.
      */
    function transitionBountyToFinalization(uint256 bountyId) external {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == BountyStatus.Evaluation, "Bounty not in evaluation state");
        require(block.timestamp > bounty.evaluationEndTime, "Evaluation period not ended");

        bounty.status = BountyStatus.Finalization;
        bounty.finalizationEndTime = uint64(block.timestamp + guildParameters[GuildParameter.FinalizationPeriod]); // Short period to trigger finalization
        emit BountyStatusChanged(bountyId, BountyStatus.Finalization);
    }


    /**
     * @dev Finalizes the bounty outcome based on collected human and AI oracle evaluations.
     *      Calculates a final success score, pays the solver if successful, and updates reputations.
     *      Can be called after the finalization period starts.
     * @param bountyId The ID of the bounty.
     */
    function finalizeBounty(uint256 bountyId) external {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == BountyStatus.Finalization, "Bounty not in finalization state");
        // Allow finalization any time *after* the evaluation period and *within* or *after* the finalization period
        require(block.timestamp >= bounty.evaluationEndTime, "Evaluation period must be ended");
        // To prevent execution griefing, allow execution *after* finalizationEndTime as well
        // require(block.timestamp >= bounty.finalizationEndTime, "Finalization period not started"); // Or allow immediately after evaluation ends

        // Calculate aggregated score
        int256 finalScore = 0; // Example aggregation logic
        uint256 totalEvaluations = bounty.humanEvaluatorCount + bounty.oracleEvaluatorCount;

        if (totalEvaluations > 0) {
            // Simple average calculation example - could use weighted average based on reputation
            int256 humanAvg = bounty.humanEvaluatorCount > 0 ? int256(bounty.totalHumanEvaluationScore / bounty.humanEvaluatorCount) : 0;
            int256 oracleAvg = bounty.oracleEvaluatorCount > 0 ? bounty.totalOracleEvaluationScore / int256(bounty.oracleEvaluatorCount) : 0;

            // Weighted combination of human and AI scores
            uint256 aiWeight = guildParameters[GuildParameter.AIOracleWeight]; // e.g., 50 means 50%
            uint256 humanWeight = 100 - aiWeight;

            // Scale scores to a common range if needed (e.g., 0-100)
            // Human avg is already 0-100. Oracle avg is -100 to 100, shift to 0-200 then scale to 0-100?
            int256 oracleAvgScaled = bounty.oracleEvaluatorCount > 0 ? (bounty.totalOracleEvaluationScore / int25ty.oracleEvaluatorCount) + 100 : 100; // Shift -100..100 to 0..200
            oracleAvgScaled = oracleAvgScaled * 100 / 200; // Scale 0..200 to 0..100

            finalScore = (humanAvg * int256(humanWeight) + oracleAvgScaled * int256(aiWeight)) / 100; // Weighted average 0-100
        }

        // Determine success threshold (could be fixed or a parameter)
        uint256 successThreshold = 70; // Example: need average score >= 70/100 for success

        if (finalScore >= int256(successThreshold)) {
            // Bounty successful
            bounty.status = BountyStatus.CompletedSuccess;

            // Pay the solver
            uint256 paymentAmount = bounty.ethAmount;
            require(address(this).balance >= paymentAmount, "Insufficient treasury balance for payout");
            address payable solverWallet = payable(bounty.solver);
             (bool success, ) = solverWallet.call{value: paymentAmount}("");
             require(success, "Payment to solver failed");

            // Update reputations: Solver gets positive Technical/Reliability, Evaluators get positive Evaluation/Reliability (especially if their scores aligned with final outcome)
            _updateReputation(bounty.solver, ReputationDimension.Technical, 5); // Example positive boost
            _updateReputation(bounty.solver, ReputationDimension.Reliability, 3);

             // Example: Reward evaluators based on how close their score was to the final score
             // This requires iterating through evaluations - GAS INTENSIVE
             // For loop over mapping keys is not supported. Need to store evaluators in an array
             // Omitting complex evaluator reputation update for gas efficiency in this example.

            emit BountyFinalized(bountyId, BountyStatus.CompletedSuccess, paymentAmount);

        } else {
            // Bounty failed
            bounty.status = BountyStatus.CompletedFailure;

            // Update reputations: Solver gets negative Technical/Reliability, Proposer potentially negative Reliability
            _updateReputation(bounty.solver, ReputationDimension.Technical, -3); // Example negative impact
            _updateReputation(bounty.solver, ReputationDimension.Reliability, -2);
            _updateReputation(bounty.proposer, ReputationDimension.Reliability, -1); // Proposer gets small negative if bounty fails

            // Potentially slash solver's stake (requires governance or automated slashing logic)
            // slashMemberStake(bounty.solver, slashingAmount, "Bounty failure"); // Needs separate governed call or specific logic

            emit BountyFinalized(bountyId, BountyStatus.CompletedFailure, 0);
        }
         emit BountyStatusChanged(bountyId, bounty.status);
    }


    // --- AI Oracle Governance ---

    /**
     * @dev Allows members to propose an address to be registered as a trusted AI Oracle.
     * @param oracleAddress The address of the potential oracle contract/wallet.
     * @param descriptionHash Hash referencing off-chain details about the oracle (e.g., what AI model it uses, how verification works).
     */
    function proposeOracleRegistration(address oracleAddress, string calldata descriptionHash) external onlyMember {
        require(!registeredOracles[oracleAddress], "Address is already a registered oracle");
        // Should also check if an active proposal for this oracle already exists

        uint256 proposalId = nextOracleRegistrationProposalId++;
        OracleRegistrationProposal storage newProposal = oracleRegistrationProposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.oracleAddress = oracleAddress;
        newProposal.descriptionHash = descriptionHash;
        newProposal.status = ProposalStatus.Voting;
        newProposal.votingEndTime = uint64(block.timestamp + guildParameters[GuildParameter.VotingPeriod]);

        emit OracleRegistrationProposed(proposalId, msg.sender, oracleAddress, descriptionHash);
    }

    /**
     * @dev Allows members to vote on registering an AI Oracle.
     * @param proposalId The ID of the oracle registration proposal.
     * @param vote The vote (Yes/No/Abstain).
     */
    function voteOnOracleRegistration(uint256 proposalId, Vote vote) external onlyMember onlyVotingPeriod(oracleRegistrationProposals[proposalId].votingEndTime) {
        OracleRegistrationProposal storage proposal = oracleRegistrationProposals[proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal is not in voting state");
         require(members[msg.sender].reputation[ReputationDimension.Reliability] >= int256(guildParameters[GuildParameter.MinReputationToVote]), "Insufficient reliability reputation to vote");

        // Prevent double voting - needs a mapping for each proposal type

        uint256 votingWeight = _calculateVotingWeight(msg.sender);
         require(votingWeight > 0, "Cannot vote with zero voting weight");

        if (vote == Vote.Yes) {
            proposal.yesVotes += votingWeight;
        } else if (vote == Vote.No) {
            proposal.noVotes += votingWeight;
        }

        proposal.totalVotingWeight += votingWeight;
        // hasVotedOracle[proposalId][msg.sender] = true;

        emit OracleRegistrationVoteCast(proposalId, msg.sender, vote);
    }

     /**
      * @dev Internal function to check if an oracle registration proposal passes.
      * @param proposalId The ID of the proposal.
      * @return True if the proposal passes, false otherwise.
      */
    function _checkGovernanceProposalOutcome(uint256 proposalId, uint256 yesVotes, uint256 noVotes, uint256 totalVotingWeight) internal view returns (bool) {
        uint256 totalVotes = yesVotes + noVotes;
        if (totalVotes == 0) {
            return false;
        }

        // Quorum check
         uint256 quorumRequirement = totalVotingWeight * guildParameters[GuildParameter.QuorumThresholdGovernance] / 10000;
        if (totalVotingWeight < quorumRequirement) {
            return false;
        }

        // Threshold check
        uint256 thresholdRequirement = yesVotes * 10000 / totalVotes;
        if (thresholdRequirement < guildParameters[GuildParameter.ThresholdGovernance]) {
            return false;
        }

        return true;
    }

    /**
     * @dev Executes an oracle registration proposal if it has passed voting.
     * @param proposalId The ID of the oracle registration proposal.
     */
    function executeOracleRegistration(uint256 proposalId) external {
         OracleRegistrationProposal storage proposal = oracleRegistrationProposals[proposalId];
         require(proposal.status == ProposalStatus.Voting, "Proposal not in voting state");
         require(block.timestamp > proposal.votingEndTime, "Voting period not ended");

         if (_checkGovernanceProposalOutcome(proposalId, proposal.yesVotes, proposal.noVotes, proposal.totalVotingWeight)) {
             proposal.status = ProposalStatus.Approved;
             // Perform the action: Register the oracle
             registeredOracles[proposal.oracleAddress] = true;
             registeredOracleAddresses.push(proposal.oracleAddress); // Store address
             emit OracleRegistered(proposal.oracleAddress);

         } else {
             proposal.status = ProposalStatus.Rejected;
         }
        proposal.status = ProposalStatus.Executed; // Mark as executed regardless of outcome
        emit BountyStatusChanged(proposalId, proposal.status); // Using BountyStatusChanged event type for simplicity, ideally dedicated event
    }

    /**
     * @dev Allows deactivating a registered oracle. This function is intended to be
     *      called via a successful governance parameter change proposal execution
     *      or a dedicated 'DeactivateOracleProposal'.
     *      For simplicity, marking as callable only via governance placeholder.
     * @param oracleAddress The address of the oracle to deactivate.
     */
    function deactivateOracle(address oracleAddress) external {
         // This function should ONLY be callable via successful governance proposal execution
         require(false, "This function is only callable via successful governance proposal execution");
         require(registeredOracles[oracleAddress], "Address is not a registered oracle");

         registeredOracles[oracleAddress] = false;
         // Removing from registeredOracleAddresses array is gas intensive. Omitting for simplicity.

         emit OracleDeactivated(oracleAddress);
    }


    // --- Guild Governance (Parameter Changes) ---

    /**
     * @dev Allows members to propose changing a guild configuration parameter.
     * @param parameter The parameter to change (enum).
     * @param newValue The new value for the parameter.
     */
    function proposeGuildParameterChange(GuildParameter parameter, uint256 newValue) external onlyMember {
         // Add checks for valid parameter/value combinations if needed

        uint256 proposalId = nextParameterChangeProposalId++;
        ParameterChangeProposal storage newProposal = parameterChangeProposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.parameter = parameter;
        newProposal.newValue = newValue;
        newProposal.status = ProposalStatus.Voting;
        newProposal.votingEndTime = uint64(block.timestamp + guildParameters[GuildParameter.VotingPeriod]);

        emit ParameterChangeProposed(proposalId, msg.sender, parameter, newValue);
    }

    /**
     * @dev Allows members to vote on a guild parameter change proposal.
     * @param proposalId The ID of the parameter change proposal.
     * @param vote The vote (Yes/No/Abstain).
     */
    function voteOnGuildParameterChange(uint256 proposalId, Vote vote) external onlyMember onlyVotingPeriod(parameterChangeProposals[proposalId].votingEndTime) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal is not in voting state");
         require(members[msg.sender].reputation[ReputationDimension.Reliability] >= int256(guildParameters[GuildParameter.MinReputationToVote]), "Insufficient reliability reputation to vote");

        // Prevent double voting - needs a mapping for each proposal type

        uint256 votingWeight = _calculateVotingWeight(msg.sender);
         require(votingWeight > 0, "Cannot vote with zero voting weight");

        if (vote == Vote.Yes) {
            proposal.yesVotes += votingWeight;
        } else if (vote == Vote.No) {
            proposal.noVotes += votingWeight;
        }

        proposal.totalVotingWeight += votingWeight;
        // hasVotedParameter[proposalId][msg.sender] = true;

        emit ParameterChangeVoteCast(proposalId, msg.sender, vote);
    }

    /**
     * @dev Executes a guild parameter change proposal if it has passed voting.
     * @param proposalId The ID of the parameter change proposal.
     */
    function executeGuildParameterChange(uint256 proposalId) external {
         ParameterChangeProposal storage proposal = parameterChangeProposals[proposalId];
         require(proposal.status == ProposalStatus.Voting, "Proposal not in voting state");
         require(block.timestamp > proposal.votingEndTime, "Voting period not ended");

         if (_checkGovernanceProposalOutcome(proposalId, proposal.yesVotes, proposal.noVotes, proposal.totalVotingWeight)) {
             proposal.status = ProposalStatus.Approved;
             // Perform the action: Change the parameter
             guildParameters[proposal.parameter] = proposal.newValue;
             emit ParameterChanged(proposal.parameter, proposal.newValue);

         } else {
             proposal.status = ProposalStatus.Rejected;
         }
        proposal.status = ProposalStatus.Executed; // Mark as executed regardless of outcome
         emit BountyStatusChanged(proposalId, proposal.status); // Using BountyStatusChanged event type for simplicity, ideally dedicated event
    }


    // --- View Functions ---

    /**
     * @dev Gets all current guild configuration parameters.
     * @return A tuple containing all parameters.
     */
    function getGuildParameters() external view returns (
        uint256 stakeRequirement,
        uint256 votingPeriod,
        uint256 evaluationPeriod,
        uint256 finalizationPeriod,
        uint256 quorumThresholdBountyVote,
        uint256 thresholdBountyVote,
        uint256 quorumThresholdGovernance,
        uint256 thresholdGovernance,
        uint256 reputationWeightVoting,
        uint256 reputationWeightEvaluation,
        uint256 reputationWeightFinalization,
        uint256 aiOracleWeight,
        uint256 minReputationToEvaluate,
        uint256 minReputationToProposeBounty,
        uint256 minReputationToVote,
        uint256 leaveCooldown
    ) {
        return (
            guildParameters[GuildParameter.StakeRequirement],
            guildParameters[GuildParameter.VotingPeriod],
            guildParameters[GuildParameter.EvaluationPeriod],
            guildParameters[GuildParameter.FinalizationPeriod],
            guildParameters[GuildParameter.QuorumThresholdBountyVote],
            guildParameters[GuildParameter.ThresholdBountyVote],
            guildParameters[GuildParameter.QuorumThresholdGovernance],
            guildParameters[GuildParameter.ThresholdGovernance],
            guildParameters[GuildParameter.ReputationWeightVoting],
            guildParameters[GuildParameter.ReputationWeightEvaluation],
            guildParameters[GuildParameter.ReputationWeightFinalization],
            guildParameters[GuildParameter.AIOracleWeight],
            guildParameters[GuildParameter.MinReputationToEvaluate],
            guildParameters[GuildParameter.MinReputationToProposeBounty],
            guildParameters[GuildParameter.MinReputationToVote],
            guildParameters[GuildParameter.LeaveCooldown]
        );
    }

    /**
     * @dev Gets the list of currently registered AI Oracle addresses.
     *      Note: Iterating over dynamic array can be gas-intensive.
     * @return An array of registered oracle addresses.
     */
    function getRegisteredOracles() external view returns (address[] memory) {
        // This function might become very expensive if many oracles are registered.
        // Consider alternatives like external indexing (subgraph) for large lists.
        return registeredOracleAddresses;
    }

     /**
     * @dev Gets the current ETH balance of the guild treasury.
     * @return The treasury balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the total number of bounties proposed.
     * @return The bounty count (ID of the next bounty to be created).
     */
    function getBountyCount() external view returns (uint256) {
        return nextBountyId - 1;
    }

    /**
     * @dev Gets the details of a specific bounty proposal.
     * @param bountyId The ID of the bounty.
     * @return Bounty details (proposer, amount, status, times, etc.).
     */
    function getBountyDetails(uint256 bountyId) external view returns (
        uint256 id,
        address proposer,
        string memory detailsHash,
        uint256 ethAmount,
        uint256 requiredReputationToClaim,
        BountyStatus status,
        uint64 proposalEndTime,
        uint64 submissionEndTime,
        uint64 evaluationEndTime,
        uint64 finalizationEndTime,
        address solver,
        string memory solutionHash,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 totalVotingWeight
    ) {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.id != 0, "Bounty does not exist"); // Check if bounty exists

        return (
            bounty.id,
            bounty.proposer,
            bounty.detailsHash,
            bounty.ethAmount,
            bounty.requiredReputationToClaim,
            bounty.status,
            bounty.proposalEndTime,
            bounty.submissionEndTime,
            bounty.evaluationEndTime,
            bounty.finalizationEndTime,
            bounty.solver,
            bounty.solutionHash,
            bounty.yesVotes,
            bounty.noVotes,
            bounty.totalVotingWeight
        );
    }

    /**
     * @dev Gets the number of human and oracle evaluations and their aggregated scores for a bounty.
     *      Note: Does not return individual evaluations due to gas cost of iterating mappings.
     * @param bountyId The ID of the bounty.
     * @return Aggregated evaluation data.
     */
    function getBountyEvaluations(uint256 bountyId) external view returns (
        uint256 totalHumanEvaluationScore,
        uint256 humanEvaluatorCount,
        int256 totalOracleEvaluationScore,
        uint256 oracleEvaluatorCount
        // uint256 totalEvaluationWeight // If using weighted evaluation
    ) {
        Bounty storage bounty = bounties[bountyId];
         require(bounty.id != 0, "Bounty does not exist");
        return (
            bounty.totalHumanEvaluationScore,
            bounty.humanEvaluatorCount,
            bounty.totalOracleEvaluationScore,
            bounty.oracleEvaluatorCount
            // bounty.totalEvaluationWeight
        );
    }


    /**
     * @dev Gets the total number of oracle registration proposals.
     * @return The proposal count.
     */
    function getOracleRegistrationProposalCount() external view returns (uint256) {
        return nextOracleRegistrationProposalId - 1;
    }

    /**
     * @dev Gets details of a specific oracle registration proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal details.
     */
    function getOracleRegistrationProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        address oracleAddress,
        string memory descriptionHash,
        ProposalStatus status,
        uint64 votingEndTime,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 totalVotingWeight
    ) {
        OracleRegistrationProposal storage proposal = oracleRegistrationProposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.oracleAddress,
            proposal.descriptionHash,
            proposal.status,
            proposal.votingEndTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalVotingWeight
        );
    }

    /**
     * @dev Gets the total number of parameter change proposals.
     * @return The proposal count.
     */
     function getParameterChangeProposalCount() external view returns (uint256) {
        return nextParameterChangeProposalId - 1;
    }

    /**
     * @dev Gets details of a specific parameter change proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal details.
     */
    function getParameterChangeProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        GuildParameter parameter,
        uint256 newValue,
        ProposalStatus status,
        uint64 votingEndTime,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 totalVotingWeight
    ) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[proposalId];
         require(proposal.id != 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.parameter,
            proposal.newValue,
            proposal.status,
            proposal.votingEndTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalVotingWeight
        );
    }

    /**
     * @dev Gets the amount of ETH currently staked by a member.
     * @param memberAddress The address of the member.
     * @return The staked amount.
     */
    function getMemberStake(address memberAddress) external view returns (uint256) {
        return members[memberAddress].stakedETH;
    }

    /**
     * @dev Gets the address of the selected solver for a specific bounty.
     * @param bountyId The ID of the bounty.
     * @return The solver's address (address(0) if not assigned).
     */
    function getBountySolver(uint256 bountyId) external view returns (address) {
         require(bounties[bountyId].id != 0, "Bounty does not exist");
        return bounties[bountyId].solver;
    }

    /**
     * @dev Checks if an address is currently an active guild member.
     * @param memberAddress The address to check.
     * @return True if the address is an active member, false otherwise.
     */
    function isMember(address memberAddress) external view returns (bool) {
        return members[memberAddress].isMember;
    }

    // Direct access to individual guild parameters for convenience
    function getStakeRequirement() external view returns (uint256) { return guildParameters[GuildParameter.StakeRequirement]; }
    function getVotingPeriod() external view returns (uint256) { return guildParameters[GuildParameter.VotingPeriod]; }
    function getEvaluationPeriod() external view returns (uint256) { return guildParameters[GuildParameter.EvaluationPeriod]; }
    function getFinalizationPeriod() external view returns (uint256) { return guildParameters[GuildParameter.FinalizationPeriod]; }
    function getQuorumThresholdBountyVote() external view returns (uint256) { return guildParameters[GuildParameter.QuorumThresholdBountyVote]; }
    function getThresholdBountyVote() external view returns (uint256) { return guildParameters[GuildParameter.ThresholdBountyVote]; }
    function getQuorumThresholdGovernance() external view returns (uint256) { return guildParameters[GuildParameter.QuorumThresholdGovernance]; }
    function getThresholdGovernance() external view returns (uint256) { return guildParameters[GuildParameter.ThresholdGovernance]; }
    function getReputationWeightVoting() external view returns (uint256) { return guildParameters[GuildParameter.ReputationWeightVoting]; }
    function getReputationWeightEvaluation() external view returns (uint256) { return guildParameters[GuildParameter.ReputationWeightEvaluation]; }
    function getReputationWeightFinalization() external view returns (uint256) { return guildParameters[GuildParameter.ReputationWeightFinalization]; }
    function getAIOracleWeight() external view returns (uint256) { return guildParameters[GuildParameter.AIOracleWeight]; }
    function getMinReputationToEvaluate() external view returns (uint256) { return guildParameters[GuildParameter.MinReputationToEvaluate]; }
    function getMinReputationToProposeBounty() external view returns (uint256) { return guildParameters[GuildParameter.MinReputationToProposeBounty]; }
    function getMinReputationToVote() external view returns (uint256) { return guildParameters[GuildParameter.MinReputationToVote]; }
    function getLeaveCooldown() external view returns (uint256) { return guildParameters[GuildParameter.LeaveCooldown]; }


    // Fallback function to receive ETH directly (e.g., for treasury deposits)
    receive() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Multi-dimensional Reputation System (`ReputationDimension` enum, `members[].reputation` mapping):** Instead of a single score, members have reputation across different axes (Technical, Evaluation, Reliability). This allows for a more nuanced understanding of a contributor's value to the DAO and enables differentiation in permissions and voting power.
2.  **AI Oracle Integration for Evaluation (`submitOracleBountyEvaluation`, `oracleEvaluations` mapping, `AIOracleWeight` parameter):** The contract doesn't run AI, but it *consumes* verifiable outputs from trusted off-chain AI models via dedicated oracle addresses. This integrates AI evaluation results directly into the on-chain decision-making process for bounty success. The `AIOracleWeight` allows the DAO to govern how much influence the AI evaluation has relative to human evaluation.
3.  **Dynamic Governance Parameters (`GuildParameter` enum, `guildParameters` mapping, `proposeGuildParameterChange`, `voteOnGuildParameterChange`, `executeGuildParameterChange`):** Many core parameters of the DAO (like staking requirements, voting periods, reputation weights, thresholds) are not fixed constants but can be changed via a formal governance process. This makes the DAO adaptable over time without needing a full contract upgrade.
4.  **Reputation-Weighted Voting and Evaluation (`_calculateVotingWeight`, `_calculateEvaluationWeight` - conceptualized):** A member's influence in voting and potentially in the impact of their evaluation score is directly tied to their reputation, making the DAO more of a meritocracy based on on-chain actions and verified contributions/evaluations. (Note: The evaluation weight calculation and application to the final score calculation is noted as a more complex, potentially gas-intensive part that would need careful implementation or external computation).
5.  **Structured AI Bounty Lifecycle (Multiple `BountyStatus` states and functions):** A well-defined state machine for AI tasks, from proposal to voting, solution submission, parallel human/AI evaluation, and finalization based on aggregated results.
6.  **Governed Oracle Registry (`registeredOracles`, `proposeOracleRegistration`, etc.):** The set of trusted AI oracles is not hardcoded but managed by the DAO's governance, allowing the guild to onboard or remove oracle services as needed based on community consensus.
7.  **Feedback Loops for Reputation:** Successful bounty completion boosts solver reputation. Accurate evaluations (judged by final outcome alignment - complex logic omitted for simplicity) could boost evaluator reputation. Failed bounties or malicious actions could decrease reputation or even lead to stake slashing (via governance).
8.  **Clear Separation of Roles/Permissions:** Using reputation levels (`MinReputationTo...`) and the `onlyMember`/`onlyRegisteredOracle` modifiers to gate access to specific functions based on a member's standing or role.

This contract provides a blueprint for a sophisticated, self-governing ecosystem focused on leveraging decentralized AI capabilities, where influence and rewards are tied to verifiable contribution and evaluation quality, guided by both human consensus and trusted AI insights.

**Disclaimer:** This contract is a conceptual example for educational purposes. It has not been formally audited, and deploying complex contracts like this requires rigorous testing, security audits, and careful consideration of gas costs and potential attack vectors (e.g., griefing via proposals, manipulation of reputation/evaluation). Features like iteration over dynamic arrays or complex reputation calculation on-chain might be gas-prohibitive in practice and might require off-chain computation or L2 solutions. Implementing full double-voting protection would require additional mappings per proposal/bounty ID.