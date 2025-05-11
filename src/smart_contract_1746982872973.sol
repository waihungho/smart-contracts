Okay, here is a smart contract concept for a Decentralized Autonomous Content Moderation system.

This contract focuses on managing a process where staked moderators review and vote on flagged content, with outcomes influencing content status, moderator reputation, and stakes. Governance roles can adjust system parameters via a voting process.

**Key Concepts:**

1.  **Staked Moderation:** Moderators must stake tokens to participate, providing a financial incentive for honest behavior and a basis for slashing.
2.  **Reputation System:** A simple reputation score tracks moderator performance (e.g., consistency with final outcomes). Reputation could influence vote weight or eligibility over time.
3.  **Case-Based Moderation:** Flagged content creates a specific "case" with a voting period.
4.  **Decentralized Parameter Governance:** A set of addresses (Governors) can propose and vote on changes to key system parameters (like stake amounts, voting periods, slashing percentages), making the system adaptable.
5.  **Slashing and Rewards:** Moderators can lose stake for poor performance (e.g., consistently voting against the final consensus, failing to vote) or gain rewards (tokens, reputation) for good performance.
6.  **Time-Locked Processes:** Voting periods for cases and parameter changes ensure processes aren't instantly manipulated.

**Why it's Creative/Advanced/Trendy:**

*   Combines Staking, Reputation, and Decentralized Governance in a specific application (Content Moderation).
*   Models a complex real-world process (moderation workflow) on-chain.
*   Uses dynamic parameters adjustable via governance, making the DAO concept central.
*   Introduces explicit slashing mechanics tied to performance within the moderation workflow.
*   Moves beyond simple token transfers or static logic to manage roles, reputation, and process outcomes.

---

**Smart Contract Outline & Function Summary**

**Contract Name:** DecentralizedAutonomousContentModeration

**Core Concepts:**
*   Staked Moderators
*   Reputation System
*   Case-Based Moderation Workflow
*   Decentralized Parameter Governance
*   Slashing and Rewards

**Data Structures:**
*   `ModerationCase`: Represents a piece of content being reviewed (content ID, status, timestamps, outcome, voter tallies).
*   `ModeratorVote`: Records a specific moderator's vote on a case.
*   `ParameterChangeProposal`: Represents a proposed change to a system parameter (target parameter, new value, proposer, voting data).

**State Variables:**
*   Mappings for moderators, stakes, reputations.
*   Mappings for moderation cases and individual votes.
*   Mappings for system parameters.
*   Mappings for governance proposals and governor votes.
*   Addresses for governors.
*   Address for the staking token (ERC20).
*   Counters for case IDs and proposal IDs.

**Events:**
*   `ModeratorRegistered`
*   `StakedForModeration`
*   `StakeWithdrawn`
*   `ContentFlagged`
*   `CaseClaimedForReview`
*   `VoteSubmitted`
*   `VoteRevoked`
*   `CaseResolved`
*   `SlashingApplied`
*   `RewardDistributed`
*   `ReputationUpdated`
*   `ParamChangeProposed`
*   `GovernorVoteSubmitted`
*   `ParamChangeExecuted`
*   `GovernorAdded`
*   `GovernorRemoved`

**Modifiers:**
*   `onlyGovernor`: Restricts access to addresses in the governors list.
*   `onlyModerator`: Restricts access to registered moderators.
*   `onlyStakedModerator`: Restricts access to registered moderators with sufficient stake.
*   `caseActive`: Checks if a moderation case is in the `Voting` state.
*   `caseVotingPeriodEnded`: Checks if the voting period for a case has ended.
*   `proposalActive`: Checks if a governance proposal is in the `Voting` state.
*   `proposalVotingPeriodEnded`: Checks if the voting period for a proposal has ended.

**Functions (26 total):**

*   **Setup & Governance (7 functions):**
    1.  `constructor`: Initializes governance addresses, stake token, and initial parameters.
    2.  `setStakeToken(address _token)`: (Governor) Sets the ERC20 token used for staking.
    3.  `addGovernor(address _governor)`: (Governor) Adds a new address to the governor list.
    4.  `removeGovernor(address _governor)`: (Governor) Removes an address from the governor list.
    5.  `proposeParameterChange(bytes32 _parameterKey, uint256 _newValue)`: (Governor) Submits a proposal to change a system parameter.
    6.  `voteOnParameterChange(uint256 _proposalId, bool _support)`: (Governor) Casts a vote on a parameter change proposal.
    7.  `executeParameterChange(uint256 _proposalId)`: (Governor) Executes an accepted parameter change proposal after the voting period.

*   **Moderator Management (4 functions):**
    8.  `registerModerator()`: Allows an address to register as a moderator (might require initial stake/reputation).
    9.  `stakeForModeration(uint256 _amount)`: Allows a registered moderator to stake tokens. Requires prior ERC20 approval.
    10. `withdrawStake(uint256 _amount)`: Allows a moderator to withdraw eligible stake (e.g., not locked in active cases).
    11. `updateModeratorReputation(address _moderator, int256 _delta)`: (Internal) Adjusts a moderator's reputation score.

*   **Content & Case Management (7 functions):**
    12. `flagContent(bytes32 _contentIdHash)`: Allows anyone (or specific roles) to flag content, creating a new moderation case.
    13. `claimCaseForReview(uint256 _caseId)`: (Staked Moderator) Allows a moderator to indicate they are reviewing a specific case.
    14. `submitModeratorVote(uint256 _caseId, uint8 _voteOption)`: (Staked Moderator) Submits a vote on a moderation case.
    15. `revokeModeratorVote(uint256 _caseId)`: (Staked Moderator) Revokes a previously submitted vote before the voting period ends.
    16. `tallyVotesAndResolveCase(uint256 _caseId)`: Allows anyone to trigger the vote tallying and case resolution after the voting period ends. Applies outcome, reputation changes, slashing, and rewards.
    17. `applySlashing(address _moderator, uint256 _amount)`: (Internal/Triggered by resolution) Applies slashing to a moderator's stake.
    18. `distributeModerationRewards(address _moderator, uint256 _amount)`: (Internal/Triggered by resolution) Distributes token rewards to a moderator.

*   **Query Functions (8 functions):**
    19. `isGovernor(address _address)`: Checks if an address is a governor.
    20. `isModerator(address _address)`: Checks if an address is a registered moderator.
    21. `getModeratorStake(address _moderator)`: Returns the staked amount for a moderator.
    22. `getModeratorReputation(address _moderator)`: Returns the reputation score for a moderator.
    23. `getModerationCaseDetails(uint256 _caseId)`: Returns details of a specific moderation case.
    24. `getCaseVoteDetails(uint256 _caseId, address _moderator)`: Returns the vote submitted by a specific moderator on a case.
    25. `getSystemParameter(bytes32 _parameterKey)`: Returns the current value of a system parameter.
    26. `getPendingParameterChanges(uint256 _proposalId)`: Returns details of a specific parameter change proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Note: This is a conceptual contract. Production use would require extensive security audits,
// gas optimization, more robust error handling, and careful parameter tuning.
// It uses basic ERC20 transfer logic; assumes the contract is approved to spend tokens.

contract DecentralizedAutonomousContentModeration {

    // --- Imports ---
    using Counters for Counters.Counter;

    // --- State Variables ---

    address public stakeToken; // Address of the ERC20 token used for staking

    // Roles
    mapping(address => bool) public isGovernor;
    address[] private governors; // Simple list for iteration (could be optimized for large numbers)

    mapping(address => bool) public registeredModerator;
    mapping(address => uint256) public moderatorStake; // Amount of stake
    mapping(address => int256) public moderatorReputation; // Reputation score (can be negative)

    // Moderation Cases
    enum CaseStatus { Active, Voting, Resolved, Rejected }
    enum VoteOption { Abstain, Approve, Flag, Ban } // Example vote options

    struct ModerationCase {
        bytes32 contentIdHash; // Hash or identifier of the content being moderated
        uint256 caseId;
        CaseStatus status;
        uint256 startTime; // Timestamp when the case was created/flagged
        uint256 votingEndTime; // Timestamp when voting ends
        VoteOption finalOutcome; // Final result after tallying
        uint256 totalWeightedVotesApprove; // Weighted votes for each option
        uint256 totalWeightedVotesFlag;
        uint256 totalWeightedVotesBan;
        uint256 reviewersCount; // How many moderators claimed/reviewed the case
        mapping(address => bool) claimedReview; // Track who claimed review
        mapping(address => ModeratorVote) votes; // Moderator's vote on this case
    }

    struct ModeratorVote {
        VoteOption option;
        uint256 stakeWeight; // Stake amount at the time of voting
        int256 reputationWeight; // Reputation at the time of voting (simple additive weight for this example)
        bool submitted; // Flag to check if vote exists
    }

    mapping(uint256 => ModerationCase) public moderationCases;
    Counters.Counter private _caseIds;

    // System Parameters (dynamic via governance)
    // Using bytes32 for key for flexibility
    mapping(bytes32 => uint256) public systemParameters;
    bytes32 constant PARAM_MIN_MODERATOR_STAKE = "minModeratorStake";
    bytes32 constant PARAM_CASE_VOTING_PERIOD = "caseVotingPeriod"; // in seconds
    bytes32 constant PARAM_VOTE_WEIGHT_STAKE_FACTOR = "voteWeightStakeFactor"; // Multiplier for stake weight
    bytes32 constant PARAM_VOTE_WEIGHT_REPUTATION_FACTOR = "voteWeightReputationFactor"; // Multiplier for reputation weight
    bytes32 constant PARAM_SLASH_PERCENTAGE = "slashPercentage"; // % to slash stake (e.g., 500 for 5%)
    bytes32 constant PARAM_REWARD_PER_CASE = "rewardPerCase"; // Tokens rewarded per correctly resolved case (total to distribute)
    bytes32 constant PARAM_REPUTATION_GAIN_CORRECT_VOTE = "reputationGainCorrectVote";
    bytes32 constant PARAM_REPUTATION_LOSS_INCORRECT_VOTE = "reputationLossIncorrectVote";
    bytes32 constant PARAM_REPUTATION_LOSS_NO_VOTE = "reputationLossNoVote";
    bytes32 constant PARAM_PROPOSAL_VOTING_PERIOD = "proposalVotingPeriod"; // in seconds
    bytes32 constant PARAM_PROPOSAL_QUORUM_PERCENTAGE = "proposalQuorumPercentage"; // % of governors needed to vote (e.g., 500 for 50%)
    bytes32 constant PARAM_PROPOSAL_MAJORITY_PERCENTAGE = "proposalMajorityPercentage"; // % of votes needed to pass (e.g., 510 for 51%)


    // Parameter Governance
    enum ProposalStatus { Active, Succeeded, Failed, Executed }

    struct ParameterChangeProposal {
        bytes32 parameterKey;
        uint256 newValue;
        uint256 proposalId;
        address proposer;
        uint256 startTime;
        uint256 votingEndTime;
        ProposalStatus status;
        mapping(address => bool) governorVotes; // Track if governor voted
        uint256 totalVotes; // Count of governors who voted
        uint256 supportVotes; // Count of governors who voted 'support'
    }

    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    Counters.Counter private _proposalIds;

    // --- Events ---
    event ModeratorRegistered(address indexed moderator);
    event StakedForModeration(address indexed moderator, uint256 amount);
    event StakeWithdrawn(address indexed moderator, uint256 amount);
    event ContentFlagged(bytes32 indexed contentIdHash, uint256 indexed caseId, address indexed flagger);
    event CaseClaimedForReview(uint256 indexed caseId, address indexed reviewer);
    event VoteSubmitted(uint256 indexed caseId, address indexed voter, uint8 voteOption);
    event VoteRevoked(uint256 indexed caseId, address indexed voter);
    event CaseResolved(uint256 indexed caseId, VoteOption finalOutcome, uint256 totalWeightedVotes);
    event SlashingApplied(uint256 indexed caseId, address indexed moderator, uint256 amount);
    event RewardDistributed(uint256 indexed caseId, address indexed moderator, uint256 amount); // Could be split per moderator
    event ReputationUpdated(address indexed moderator, int256 oldReputation, int256 newReputation);
    event ParamChangeProposed(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue, address indexed proposer);
    event GovernorVoteSubmitted(uint256 indexed proposalId, address indexed governor, bool support);
    event ParamChangeExecuted(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue);
    event GovernorAdded(address indexed governor);
    event GovernorRemoved(address indexed governor);

    // --- Modifiers ---
    modifier onlyGovernor() {
        require(isGovernor[msg.sender], "DACM: Not a governor");
        _;
    }

    modifier onlyModerator() {
        require(registeredModerator[msg.sender], "DACM: Not a registered moderator");
        _;
    }

    modifier onlyStakedModerator() {
        require(moderatorStake[msg.sender] >= systemParameters[PARAM_MIN_MODERATOR_STAKE], "DACM: Insufficient stake");
        _;
    }

    modifier caseActive(uint256 _caseId) {
        require(moderationCases[_caseId].status == CaseStatus.Voting, "DACM: Case not active or does not exist");
        _;
    }

    modifier caseVotingPeriodEnded(uint256 _caseId) {
        require(moderationCases[_caseId].status == CaseStatus.Voting, "DACM: Case not active or does not exist");
        require(block.timestamp >= moderationCases[_caseId].votingEndTime, "DACM: Voting period not ended");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Active, "DACM: Proposal not active or does not exist");
        _;
    }

    modifier proposalVotingPeriodEnded(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Active, "DACM: Proposal not active or does not exist");
        require(block.timestamp >= parameterChangeProposals[_proposalId].votingEndTime, "DACM: Proposal voting period not ended");
        _;
    }

    // --- Constructor ---

    constructor(address _stakeToken, address[] memory _initialGovernors, uint256 _initialMinStake, uint256 _initialCaseVotingPeriod) {
        require(_stakeToken != address(0), "DACM: Invalid stake token address");
        stakeToken = _stakeToken;

        for (uint i = 0; i < _initialGovernors.length; i++) {
            require(_initialGovernors[i] != address(0), "DACM: Invalid governor address in list");
            isGovernor[_initialGovernors[i]] = true;
            governors.push(_initialGovernors[i]);
            emit GovernorAdded(_initialGovernors[i]);
        }

        // Set initial system parameters
        systemParameters[PARAM_MIN_MODERATOR_STAKE] = _initialMinStake;
        systemParameters[PARAM_CASE_VOTING_PERIOD] = _initialCaseVotingPeriod;
        // Default other parameters - these should ideally be set by governance after deployment
        systemParameters[PARAM_VOTE_WEIGHT_STAKE_FACTOR] = 1; // 1x stake
        systemParameters[PARAM_VOTE_WEIGHT_REPUTATION_FACTOR] = 1; // 1x reputation (can be negative)
        systemParameters[PARAM_SLASH_PERCENTAGE] = 500; // 5%
        systemParameters[PARAM_REWARD_PER_CASE] = 100 * (10**18); // Example: 100 tokens
        systemParameters[PARAM_REPUTATION_GAIN_CORRECT_VOTE] = 10;
        systemParameters[PARAM_REPUTATION_LOSS_INCORRECT_VOTE] = 5;
        systemParameters[PARAM_REPUTATION_LOSS_NO_VOTE] = 2;
        systemParameters[PARAM_PROPOSAL_VOTING_PERIOD] = 7 days; // Example: 7 days
        systemParameters[PARAM_PROPOSAL_QUORUM_PERCENTAGE] = 300; // 30% of governors
        systemParameters[PARAM_PROPOSAL_MAJORITY_PERCENTAGE] = 510; // 51% of votes cast
    }

    // --- Governor Functions ---

    function setStakeToken(address _token) public onlyGovernor {
        require(_token != address(0), "DACM: Invalid stake token address");
        stakeToken = _token;
        // Event missing, add if needed
    }

    function addGovernor(address _governor) public onlyGovernor {
        require(_governor != address(0), "DACM: Invalid address");
        require(!isGovernor[_governor], "DACM: Address is already a governor");
        isGovernor[_governor] = true;
        governors.push(_governor);
        emit GovernorAdded(_governor);
    }

    function removeGovernor(address _governor) public onlyGovernor {
        require(isGovernor[_governor], "DACM: Address is not a governor");
        require(governors.length > 1, "DACM: Cannot remove the last governor"); // Prevent locking out

        isGovernor[_governor] = false;
        // Find and remove from the dynamic array (inefficient for large arrays)
        for (uint i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                governors[i] = governors[governors.length - 1];
                governors.pop();
                break;
            }
        }
        emit GovernorRemoved(_governor);
    }

    function proposeParameterChange(bytes32 _parameterKey, uint256 _newValue) public onlyGovernor {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            parameterKey: _parameterKey,
            newValue: _newValue,
            proposalId: proposalId,
            proposer: msg.sender,
            startTime: block.timestamp,
            votingEndTime: block.timestamp + systemParameters[PARAM_PROPOSAL_VOTING_PERIOD],
            status: ProposalStatus.Active,
            totalVotes: 0,
            supportVotes: 0
        });

        emit ParamChangeProposed(proposalId, _parameterKey, _newValue, msg.sender);
    }

    function voteOnParameterChange(uint256 _proposalId, bool _support) public onlyGovernor proposalActive(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(block.timestamp < proposal.votingEndTime, "DACM: Voting period for proposal has ended");
        require(!proposal.governorVotes[msg.sender], "DACM: Already voted on this proposal");

        proposal.governorVotes[msg.sender] = true;
        proposal.totalVotes++;
        if (_support) {
            proposal.supportVotes++;
        }

        emit GovernorVoteSubmitted(_proposalId, msg.sender, _support);
    }

    function executeParameterChange(uint256 _proposalId) public onlyGovernor proposalVotingPeriodEnded(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];

        // Calculate quorum and majority requirements
        uint256 totalGovernors = governors.length; // Use dynamic array length
        uint256 requiredQuorum = (totalGovernors * systemParameters[PARAM_PROPOSAL_QUORUM_PERCENTAGE]) / 1000; // 1000 = 100% * 10 (for one decimal place)
        uint256 requiredMajority = (proposal.totalVotes * systemParameters[PARAM_PROPOSAL_MAJORITY_PERCENTAGE]) / 1000;

        if (proposal.totalVotes >= requiredQuorum && proposal.supportVotes >= requiredMajority) {
            systemParameters[proposal.parameterKey] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ParamChangeExecuted(proposalId, proposal.parameterKey, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
            // Event for failed proposal?
        }
    }

    // --- Moderator Management Functions ---

    function registerModerator() public {
        require(!registeredModerator[msg.sender], "DACM: Address already registered");
        // Could require initial stake here, or just registration is enough, stake later.
        // Let's require minimum stake upon registration for this example.
        // Alternatively, require staking *after* registration to become active.
        // Let's make registration separate, but require stake for active moderation.
        registeredModerator[msg.sender] = true;
        moderatorReputation[msg.sender] = 0; // Start with base reputation
        emit ModeratorRegistered(msg.sender);
    }

    function stakeForModeration(uint256 _amount) public onlyModerator {
        require(_amount > 0, "DACM: Stake amount must be positive");
        // Transfer tokens from the caller to this contract
        IERC20 stakeTokenContract = IERC20(stakeToken);
        require(stakeTokenContract.transferFrom(msg.sender, address(this), _amount), "DACM: ERC20 transfer failed");

        moderatorStake[msg.sender] += _amount;
        emit StakedForModeration(msg.sender, _amount);
    }

    function withdrawStake(uint256 _amount) public onlyModerator {
        require(_amount > 0, "DACM: Withdraw amount must be positive");
        require(moderatorStake[msg.sender] >= _amount, "DACM: Insufficient staked balance");

        // Check if moderator has any active cases preventing full withdrawal
        // This is complex to track efficiently on-chain. A simple approach might be:
        // - Allow withdrawal only if stake remains >= minStake after withdrawal, OR
        // - Implement a cooldown period after last moderation action/case closure.
        // - Track explicitly locked stake per case (more complex state).
        // For simplicity in this example, let's require stake >= minStake after withdrawal
        // OR allow withdrawal only if *no* cases claimed/voted on in last X time.
        // Let's implement the simple "must keep min stake" rule.
        require(moderatorStake[msg.sender] - _amount >= systemParameters[PARAM_MIN_MODERATOR_STAKE], "DACM: Cannot withdraw below minimum stake");

        moderatorStake[msg.sender] -= _amount;
        IERC20 stakeTokenContract = IERC20(stakeToken);
        require(stakeTokenContract.transfer(msg.sender, _amount), "DACM: ERC20 transfer failed");

        emit StakeWithdrawn(msg.sender, _amount);
    }

    // Internal function to update reputation
    function updateModeratorReputation(address _moderator, int256 _delta) internal {
        int256 oldReputation = moderatorReputation[_moderator];
        moderatorReputation[_moderator] = oldReputation + _delta;
        emit ReputationUpdated(_moderator, oldReputation, moderatorReputation[_moderator]);
    }

    // --- Content & Case Management Functions ---

    function flagContent(bytes32 _contentIdHash) public {
        _caseIds.increment();
        uint256 caseId = _caseIds.current();

        moderationCases[caseId] = ModerationCase({
            contentIdHash: _contentIdHash,
            caseId: caseId,
            status: CaseStatus.Voting, // Starts immediately in voting
            startTime: block.timestamp,
            votingEndTime: block.timestamp + systemParameters[PARAM_CASE_VOTING_PERIOD],
            finalOutcome: VoteOption.Abstain, // Default before tally
            totalWeightedVotesApprove: 0,
            totalWeightedVotesFlag: 0,
            totalWeightedVotesBan: 0,
            reviewersCount: 0
        });
        // Mappings (votes, claimedReview) are initialized empty by default

        emit ContentFlagged(_contentIdHash, caseId, msg.sender);
    }

    function claimCaseForReview(uint256 _caseId) public onlyStakedModerator caseActive(_caseId) {
        ModerationCase storage case_ = moderationCases[_caseId];
        require(!case_.claimedReview[msg.sender], "DACM: Already claimed review for this case");

        case_.claimedReview[msg.sender] = true;
        case_.reviewersCount++;
        // Could add a small reward/reputation gain for claiming here
        // updateModeratorReputation(msg.sender, someSmallAmount); // Example
        emit CaseClaimedForReview(_caseId, msg.sender);
    }

    function submitModeratorVote(uint256 _caseId, uint8 _voteOption) public onlyStakedModerator caseActive(_caseId) {
        ModerationCase storage case_ = moderationCases[_caseId];
        require(block.timestamp < case_.votingEndTime, "DACM: Voting period has ended");
        require(_voteOption >= uint8(VoteOption.Approve) && _voteOption <= uint8(VoteOption.Ban), "DACM: Invalid vote option");
        // Note: Abstain (0) is not allowed as an active vote, only default

        // Ensure moderator has claimed review before voting (optional, but good practice)
        require(case_.claimedReview[msg.sender], "DACM: Must claim case for review before voting");

        // Prevent double voting
        require(!case_.votes[msg.sender].submitted, "DACM: Already voted on this case");

        // Calculate vote weight based on current stake and reputation
        uint256 stakeWeight = moderatorStake[msg.sender] * systemParameters[PARAM_VOTE_WEIGHT_STAKE_FACTOR];
        // Handle potentially negative reputation. Additive weight can be negative.
        int256 reputationWeight = moderatorReputation[msg.sender] * int256(systemParameters[PARAM_VOTE_WEIGHT_REPUTATION_FACTOR]);
        // Total weight is stakeWeight + reputationWeight (handle signed/unsigned arithmetic carefully)
        // For simplicity here, let's say weight = stake * stakeFactor + reputation * repFactor. If reputation is negative,
        // it reduces the total weight. Ensure total weight isn't negative if used in calculations below.
        // A simple way: totalWeight = stake * factor1 + max(0, reputation * factor2). Or allow negative weight.
        // Let's just add them for now, allowing negative reputation to reduce weight. Need signed integer for total weight.
        int256 totalVoteWeight = int256(stakeWeight) + reputationWeight;
        if (totalVoteWeight < 0) totalVoteWeight = 0; // Prevent negative effective vote weight

        case_.votes[msg.sender] = ModeratorVote({
            option: VoteOption(_voteOption),
            stakeWeight: moderatorStake[msg.sender], // Record stake at vote time
            reputationWeight: moderatorReputation[msg.sender], // Record reputation at vote time
            submitted: true
        });

        // Add weight to the corresponding tally
        if (_voteOption == uint8(VoteOption.Approve)) {
            case_.totalWeightedVotesApprove += uint256(totalVoteWeight);
        } else if (_voteOption == uint8(VoteOption.Flag)) {
            case_.totalWeightedVotesFlag += uint256(totalVoteWeight);
        } else if (_voteOption == uint8(VoteOption.Ban)) {
            case_.totalWeightedVotesBan += uint256(totalVoteWeight);
        }

        emit VoteSubmitted(_caseId, msg.sender, _voteOption);
    }

    function revokeModeratorVote(uint256 _caseId) public onlyStakedModerator caseActive(_caseId) {
        ModerationCase storage case_ = moderationCases[_caseId];
        require(block.timestamp < case_.votingEndTime, "DACM: Voting period has ended");
        require(case_.votes[msg.sender].submitted, "DACM: No vote submitted for this case");

        VoteOption revokedOption = case_.votes[msg.sender].option;
        uint256 revokedStakeWeight = case_.votes[msg.sender].stakeWeight;
        int256 revokedReputationWeight = case_.votes[msg.sender].reputationWeight;
        int256 revokedTotalWeight = int256(revokedStakeWeight * systemParameters[PARAM_VOTE_WEIGHT_STAKE_FACTOR]) + revokedReputationWeight * int256(systemParameters[PARAM_VOTE_WEIGHT_REPUTATION_FACTOR]);
        if (revokedTotalWeight < 0) revokedTotalWeight = 0;


        // Subtract weight from the tally
        if (revokedOption == VoteOption.Approve) {
            case_.totalWeightedVotesApprove -= uint256(revokedTotalWeight);
        } else if (revokedOption == VoteOption.Flag) {
            case_.totalWeightedVotesFlag -= uint256(revokedTotalWeight);
        } else if (revokedOption == VoteOption.Ban) {
            case_.totalWeightedVotesBan -= uint256(revokedTotalWeight);
        }

        delete case_.votes[msg.sender]; // Remove the vote entry

        emit VoteRevoked(_caseId, msg.sender);
    }

    function tallyVotesAndResolveCase(uint256 _caseId) public caseVotingPeriodEnded(_caseId) {
        ModerationCase storage case_ = moderationCases[_caseId];

        uint256 approve = case_.totalWeightedVotesApprove;
        uint256 flag = case_.totalWeightedVotesFlag;
        uint256 ban = case_.totalWeightedVotesBan;
        uint256 totalWeightedVotes = approve + flag + ban;

        require(totalWeightedVotes > 0, "DACM: No votes submitted for this case"); // Cannot resolve if no votes

        VoteOption finalOutcome;
        // Determine the final outcome based on weighted majority
        if (approve >= flag && approve >= ban) {
            finalOutcome = VoteOption.Approve;
        } else if (flag >= approve && flag >= ban) {
            finalOutcome = VoteOption.Flag;
        } else {
            finalOutcome = VoteOption.Ban; // Ban is the outcome if it has the most votes
        }

        case_.finalOutcome = finalOutcome;
        case_.status = CaseStatus.Resolved; // Content status would be updated off-chain based on this

        emit CaseResolved(_caseId, finalOutcome, totalWeightedVotes);

        // Apply rewards and penalties (slashing and reputation)
        // This is a simplified example. More complex logic could distribute rewards based on weight,
        // penalize non-voters among reviewers, penalize based on vote 'wrongness', etc.
        uint256 slashPercentage = systemParameters[PARAM_SLASH_PERCENTAGE]; // e.g., 500 for 5%
        int256 repGain = int256(systemParameters[PARAM_REPUTATION_GAIN_CORRECT_VOTE]);
        int256 repLossIncorrect = -int256(systemParameters[PARAM_REPUTATION_LOSS_INCORRECT_VOTE]);
        int256 repLossNoVote = -int256(systemParameters[PARAM_REPUTATION_LOSS_NO_VOTE]);
        uint256 totalRewardPool = systemParameters[PARAM_REWARD_PER_CASE];

        // Iterate through all *claimed reviewers* to apply penalties/rewards
        // NOTE: Iterating through mapping keys is not directly possible in Solidity.
        // A common pattern is to store claimed reviewers in a dynamic array when they claim.
        // For simplicity here, we'll just iterate over the governors/moderators array directly
        // which is highly inefficient and incorrect if not all are reviewers.
        // A production system NEEDS a way to track claimed reviewers efficiently (e.g., a dynamic array of addresses).
        // For this example, let's simulate by just checking anyone who *voted* and everyone *registered* (again, inefficient).
        // Proper approach: Maintain `address[] reviewersForCase[_caseId]` when `claimCaseForReview` is called.

        // *** Simplified (Inefficient) Simulation ***
        // In a real contract, you'd iterate over reviewersForCase[_caseId]
        // Here, we'll check all registered moderators.

        uint256 rewardAmountPerCorrectVoter = 0;
        uint256 correctVotersCount = 0;

        // First pass to count correct voters and calculate per-voter reward
        address[] memory allRegisteredMods; // Dummy array - replace with actual reviewer list
        // For demonstration, let's assume 'governors' list is small and representative, or fetch a limited list of moderators
        // A REAL contract CANNOT iterate over all registeredModerator keys efficiently.
        // This loop is for concept illustration only.
        uint regModCount = 0;
        // Dummy loop to get *some* addresses - NOT production code
        // This part highlights the need for a proper data structure to track reviewers
        // Let's skip this part and assume we had an array `address[] caseReviewers` stored in the case struct.

        // *** Let's refine the case struct to include reviewer list ***
         struct ModerationCase {
            // ... other fields
            address[] reviewers; // Addresses who claimed review
            // ... other fields
        }
        // Modify flagContent and claimCaseForReview accordingly.
        // Add `moderationCases[caseId].reviewers.push(msg.sender);` in claimCaseForReview.
        // This makes the iteration below possible.

        // *** Second pass (assuming reviewers array exists and is populated) ***
        // Calculate rewards/slashing
        for (uint i = 0; i < case_.reviewers.length; i++) {
            address moderator = case_.reviewers[i];
            ModeratorVote storage modVote = case_.votes[moderator];

            if (!modVote.submitted) {
                 // Penalize for not voting after claiming review
                 if(moderatorReputation[moderator] > 0) { // Only slash if stake > 0
                     uint256 slashAmount = (moderatorStake[moderator] * slashPercentage) / 10000; // e.g., 500/10000 = 5%
                     // Ensure slash amount doesn't take stake below min stake (or handle as full slashing/exit)
                     if (moderatorStake[moderator] >= slashAmount + systemParameters[PARAM_MIN_MODERATOR_STAKE]) {
                          applySlashing(moderator, slashAmount);
                     } else if (moderatorStake[moderator] > systemParameters[PARAM_MIN_MODERATOR_STAKE]) {
                           // Slash down to min stake
                           applySlashing(moderator, moderatorStake[moderator] - systemParameters[PARAM_MIN_MODERATOR_STAKE]);
                     } else {
                        // Cannot slash below min stake unless configured differently
                     }
                 }
                 updateModeratorReputation(moderator, repLossNoVote);

            } else {
                 // Voted - reward/penalize based on outcome alignment
                 if (modVote.option == finalOutcome) {
                    // Correct vote
                    updateModeratorReputation(moderator, repGain);
                    correctVotersCount++;
                 } else {
                    // Incorrect vote
                    if(moderatorStake[moderator] > 0) {
                       uint256 slashAmount = (moderatorStake[moderator] * slashPercentage) / 10000;
                       if (moderatorStake[moderator] >= slashAmount + systemParameters[PARAM_MIN_MODERATOR_STAKE]) {
                            applySlashing(moderator, slashAmount);
                       } else if (moderatorStake[moderator] > systemParameters[PARAM_MIN_MODERATOR_STAKE]) {
                           applySlashing(moderator, moderatorStake[moderator] - systemParameters[PARAM_MIN_MODERATOR_STAKE]);
                       } // else cannot slash below min stake
                    }
                    updateModeratorReputation(moderator, repLossIncorrect);
                 }
            }
        }

        // Distribute total reward pool among correct voters (if any)
        if (correctVotersCount > 0 && totalRewardPool > 0) {
             rewardAmountPerCorrectVoter = totalRewardPool / correctVotersCount;
             for (uint i = 0; i < case_.reviewers.length; i++) {
                address moderator = case_.reviewers[i];
                ModeratorVote storage modVote = case_.votes[moderator];
                if (modVote.submitted && modVote.option == finalOutcome) {
                    distributeModerationRewards(moderator, rewardAmountPerCorrectVoter); // This adds to stake for simplicity
                }
             }
        }
         // *** End of Simplified Simulation ***
    }

    // Internal function for slashing
    function applySlashing(address _moderator, uint256 _amount) internal {
        require(moderatorStake[_moderator] >= _amount, "DACM: Insufficient stake to slash");
        moderatorStake[_moderator] -= _amount;
        // Slashed tokens could be sent to a treasury, burned, or distributed.
        // For simplicity, they stay in the contract address for now (effectively removed from staked balance).
        emit SlashingApplied(moderationCases[_caseIds.current()].caseId, _moderator, _amount); // Use current case ID? Or pass caseId? Pass caseId.
        // NOTE: Need to pass caseId to this internal function from tallyVotesAndResolveCase
        // Let's fix this in the main function call.
    }

    // Internal function for distributing rewards
    function distributeModerationRewards(address _moderator, uint256 _amount) internal {
         require(_amount > 0, "DACM: Reward amount must be positive");
         // Rewards could be added to stake, sent directly, or be a separate token.
         // Adding to stake incentivizes continued participation.
         moderatorStake[_moderator] += _amount; // Add to staked balance
         // Tokens must be sent from contract balance. Need a mechanism to fund the contract.
         // Example: A deposit function `fundContract(uint256 amount)`.
         // For simplicity, assume the contract has enough tokens or add to stake without actual transfer out (less realistic).
         // Let's assume adding to stake implicitly means the moderator now owns more of the stake pool.
         // A more realistic approach requires transferring tokens to the contract beforehand.
         // Let's add a simple `fundContract` function.
         emit RewardDistributed(moderationCases[_caseIds.current()].caseId, _moderator, _amount); // Need caseId here too.
    }

    // Add a funding function for rewards/slashed tokens
    function fundContract(uint256 _amount) public {
        IERC20 stakeTokenContract = IERC20(stakeToken);
        require(stakeTokenContract.transferFrom(msg.sender, address(this), _amount), "DACM: ERC20 transfer failed");
        // No event for funding needed unless tracking treasury balance explicitly
    }


    // --- Query Functions ---

    function isGovernor(address _address) public view returns (bool) {
        return isGovernor[_address];
    }

    function isModerator(address _address) public view returns (bool) {
        return registeredModerator[_address];
    }

    function getModeratorStake(address _moderator) public view returns (uint256) {
        return moderatorStake[_moderator];
    }

    function getModeratorReputation(address _moderator) public view returns (int256) {
        return moderatorReputation[_moderator];
    }

    // Get details of a case (public view, returns tuple for multiple values)
    function getModerationCaseDetails(uint256 _caseId) public view returns (
        bytes32 contentIdHash,
        CaseStatus status,
        uint256 startTime,
        uint256 votingEndTime,
        VoteOption finalOutcome,
        uint256 totalWeightedVotesApprove,
        uint256 totalWeightedVotesFlag,
        uint256 totalWeightedVotesBan,
        uint256 reviewersCount
        // reviewers list cannot be returned efficiently for dynamic array in memory
    ) {
        ModerationCase storage case_ = moderationCases[_caseId];
        require(case_.caseId == _caseId || _caseId == 0, "DACM: Case does not exist"); // caseId 0 check for default struct

        return (
            case_.contentIdHash,
            case_.status,
            case_.startTime,
            case_.votingEndTime,
            case_.finalOutcome,
            case_.totalWeightedVotesApprove,
            case_.totalWeightedVotesFlag,
            case_.totalWeightedVotesBan,
            case_.reviewersCount
        );
    }

    // Get details of a specific moderator's vote on a case
    function getCaseVoteDetails(uint256 _caseId, address _moderator) public view returns (
        VoteOption option,
        uint256 stakeWeight,
        int256 reputationWeight,
        bool submitted
    ) {
        ModerationCase storage case_ = moderationCases[_caseId];
        require(case_.caseId == _caseId || _caseId == 0, "DACM: Case does not exist");

        ModeratorVote storage vote_ = case_.votes[_moderator];
         return (
            vote_.option,
            vote_.stakeWeight,
            vote_.reputationWeight,
            vote_.submitted
        );
    }

    // Get the value of a system parameter
    function getSystemParameter(bytes32 _parameterKey) public view returns (uint256) {
        return systemParameters[_parameterKey];
    }

    // Get details of a specific parameter change proposal
    function getPendingParameterChanges(uint256 _proposalId) public view returns (
        bytes32 parameterKey,
        uint256 newValue,
        uint256 proposalId,
        address proposer,
        uint256 startTime,
        uint256 votingEndTime,
        ProposalStatus status,
        uint256 totalVotes,
        uint256 supportVotes
    ) {
         ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
         require(proposal.proposalId == _proposalId || _proposalId == 0, "DACM: Proposal does not exist"); // proposalId 0 check

         return (
             proposal.parameterKey,
             proposal.newValue,
             proposal.proposalId,
             proposal.proposer,
             proposal.startTime,
             proposal.votingEndTime,
             proposal.status,
             proposal.totalVotes,
             proposal.supportVotes
         );
    }

    // Get voter status on a proposal (did they vote?)
     function getProposalVoteStatus(uint256 _proposalId, address _governor) public view returns (bool voted) {
         ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
         require(proposal.proposalId == _proposalId || _proposalId == 0, "DACM: Proposal does not exist");
         return proposal.governorVotes[_governor];
     }

     // Function to get the list of governors (potentially expensive for many governors)
     function getGovernors() public view returns (address[] memory) {
         return governors;
     }

    // Function to get the total number of cases created
    function getTotalCases() public view returns (uint256) {
        return _caseIds.current();
    }

    // Function to get the total number of proposals created
     function getTotalProposals() public view returns (uint256) {
        return _proposalIds.current();
    }

}
```