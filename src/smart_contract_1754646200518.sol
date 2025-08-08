This smart contract, `AdaptiveCommunityHub`, introduces a dynamic and self-evolving decentralized community system. It focuses on unique features like an on-chain reputation system with decay, adaptive membership tiers, and governance mechanisms influenced by a calculated "Community Health Index". The goal is to create a vibrant, self-regulating community that incentivizes engagement and contribution.

---

## Contract Name: `AdaptiveCommunityHub`

### Outline and Function Summary

This smart contract represents an advanced, self-evolving decentralized community hub. It integrates innovative concepts to foster a resilient and self-correcting community: a dynamic reputation system, adaptive membership tiers, sentiment-driven governance, and a community-centric task/bounty system. The core idea is that the contract's internal mechanics (e.g., membership requirements, voting power) can adjust based on on-chain engagement and a computed "Community Health Index", thereby promoting sustained participation and rewarding positive contributions.

#### I. Infrastructure & Access Control
Functions for basic contract management, pausing, and owner/admin control. It also includes a mechanism for the community (via governance) to update core contract parameters.
*   `constructor()`: Initializes the contract with an admin, sets initial parameters for reputation and governance.
*   `pauseContract()`: Pauses critical contract functions in an emergency. Only callable by the contract owner (admin role for this contract).
*   `unpauseContract()`: Resumes operations after a pause. Only callable by the contract owner.
*   `updateAdmin(address newAdmin)`: Transfers the custom `admin` role of the hub.
*   `proposeParameterUpdate(bytes32 paramKey, uint256 newValue)`: Allows any eligible member to submit a governance proposal to change a core contract parameter (e.g., `reputationDecayRatePerDay`, `proposalQuorumPercentage`).
*   `executeParameterUpdate(uint256 proposalId)`: Executes a `ParameterUpdate` proposal that has successfully passed its voting phase.

#### II. Reputation & Skill Management
A dynamic on-chain reputation system that accrues from positive interactions (e.g., skill endorsements, task completion) and decays over time to encourage continuous engagement.
*   `registerSkill(bytes32 skillHash)`: Allows a member to declare a specific skill (represented by a hash).
*   `endorseSkill(address member, bytes32 skillHash)`: Enables one member to endorse another's declared skill, contributing positively to the endorsed member's reputation.
*   `revokeSkillEndorsement(address member, bytes32 skillHash)`: Allows an endorser to revoke a previous skill endorsement, which can reduce the endorsed member's reputation.
*   `updateReputationDecayRate(uint256 newRatePerDay)`: A governance-controlled function (or admin-only for simplicity) to adjust how quickly members' reputation scores decay over time.
*   `triggerReputationDecay(address member)`: Applies the reputation decay logic to a specific member. This function helps keep the system fair and encourages ongoing contribution.
*   `getReputationScore(address member)`: Retrieves the current reputation score of a member, also applying any pending decay for an up-to-date view.

#### III. Adaptive Membership Tiers
Defines various community tiers with dynamic requirements (e.g., minimum reputation, staked tokens) and associated benefits. Tier requirements can adapt based on the Community Health Index.
*   `defineCommunityTier(bytes32 tierId, string calldata name, uint256 minReputation, uint256 requiredStake, address stakeToken, uint256 maxMembers)`: Admin/governance can define a new membership tier with specific entry criteria.
*   `updateCommunityTier(bytes32 tierId, string calldata name, uint256 minReputation, uint256 requiredStake, address stakeToken, uint256 maxMembers)`: Modifies an existing membership tier's parameters.
*   `joinCommunityTier(bytes32 tierId)`: Allows a user to join a specified tier, provided they meet its current requirements (reputation, stake, availability).
*   `leaveCommunityTier()`: Allows a user to leave their current tier, unstaking any required assets.
*   `getMemberTier(address member)`: Retrieves the current tier ID of a given member.
*   `getTierDetails(bytes32 tierId)`: Returns all configuration parameters for a specific tier.

#### IV. Governance & Treasury
A decentralized governance system where voting power is dynamically influenced by reputation and tier membership. Includes mechanisms for submitting, voting on, and executing proposals, as well as managing the community treasury.
*   `submitProposal(string calldata title, string calldata description, ProposalType proposalType, bytes calldata callData)`: Initiates a new governance proposal for various actions (e.g., treasury allocation, parameter changes, custom actions).
*   `voteOnProposal(uint256 proposalId, bool support)`: Allows members to cast their vote on an active proposal. Voting weight is dynamic based on their `getEffectiveVotingWeight`.
*   `executeProposal(uint256 proposalId)`: Executes a proposal that has met its voting thresholds (quorum and majority) and passed.
*   `depositTreasuryFunds()`: Allows anyone to contribute native currency (ETH) to the community treasury.
*   `proposeTreasuryWithdrawal(address recipient, uint256 amount, address tokenAddress)`: Proposes a withdrawal of funds (ETH or ERC20) from the treasury, subject to governance approval.
*   `executeTreasuryWithdrawal(uint256 proposalId)`: Executes a passed treasury withdrawal proposal.

#### V. Task & Contribution System
An on-chain system for creating, assigning, verifying, and claiming bounties for community tasks. Successful task completion contributes to a member's reputation.
*   `createBountyTask(string calldata description, uint256 bountyAmount, address bountyToken, uint256 deadline)`: Creates a new task with a specified bounty in a given ERC20 token and a deadline.
*   `assignTask(uint256 taskId, address assignee)`: Assigns a specific bounty task to a member for completion.
*   `submitTaskCompletion(uint256 taskId, string calldata proofIpfsHash)`: A member submits cryptographic proof (e.g., IPFS hash of work) of task completion.
*   `verifyTaskCompletion(uint256 taskId)`: Designated verifiers (e.g., admin, or a future governance-selected committee) confirm task completion, potentially boosting the assignee's reputation.
*   `claimBountyReward(uint256 taskId)`: Allows the assigned member to claim their bounty after the task has been successfully verified.

#### VI. Adaptive & Dynamic Mechanisms
These functions implement the core "adaptive" nature of the hub, including calculating a "Community Health Index" and using it to dynamically adjust tier requirements and voting weights.
*   `calculateCommunityHealthIndex()`: Computes an on-chain "health score" for the community based on recent activity (e.g., number of new proposals, tasks created, active members). This serves as a proxy for community sentiment or engagement.
*   `adjustTierRequirements(bytes32 tierId)`: Callable by governance or a time-based trigger, this function dynamically adjusts a tier's minimum reputation and required stake based on the current `CommunityHealthIndex`.
*   `getEffectiveVotingWeight(address member)`: Calculates a member's current voting power in governance proposals, influenced by their reputation score, their membership tier, and the overall `CommunityHealthIndex`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: For a production dApp, standard libraries like OpenZeppelin's Ownable, Pausable, and IERC20
// would typically be imported. For the purpose of this unique, non-duplicating example,
// basic implementations are provided within the contract context.

// Minimal IERC20 interface for token interactions
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint255);
}

// Basic Ownable pattern for contract ownership
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Basic Pausable pattern for emergency stopping of operations
contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _pause() internal virtual onlyOwner { // Only owner can pause/unpause
        require(!_paused, "Pausable: paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual onlyOwner { // Only owner can pause/unpause
        require(_paused, "Pausable: not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// Minimal string conversion utility, adapted from OpenZeppelin's `Strings` library.
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint160 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 + 20 * 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            buffer[2 + i * 2] = _toByte(uint8(value >> (19 - i) * 8) >> 4);
            buffer[2 + i * 2 + 1] = _toByte(uint8(value >> (19 - i) * 8) & 0x0F);
        }
        return string(buffer);
    }

    function _toByte(uint8 value) private pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(48 + value));
        } else {
            return bytes1(uint8(87 + value));
        }
    }
}


contract AdaptiveCommunityHub is Pausable {
    using Strings for uint256;
    using Strings for uint160;

    // --- Enums ---
    enum ProposalType {
        ParameterUpdate,
        TreasuryAllocation,
        TierDefinition,
        TierUpdate,
        CustomAction // For general purpose proposals with specific callData
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Canceled
    }

    enum TaskState {
        Open,
        Assigned,
        Submitted,
        Verified,
        Claimed,
        Canceled
    }

    // --- Structs ---
    struct Member {
        uint256 reputationScore;
        bytes32 currentTierId; // 0 if not in a tier
        uint256 lastReputationDecayTimestamp;
        uint256 lastActivityTimestamp; // For community health index calculation
        mapping(bytes32 => bool) skills;
        mapping(address => mapping(bytes32 => bool)) endorsedSkills; // endorser address => skillHash => bool
    }

    struct Tier {
        string name;
        uint256 minReputation;
        uint256 requiredStake;
        address stakeToken; // Address of the ERC20 token required for staking (address(0) for no token)
        uint256 maxMembers; // 0 for unlimited members
        uint256 currentMemberCount;
        mapping(address => bool) members; // To quickly check if an address is in this tier
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        ProposalType proposalType;
        bytes callData; // Encoded function call for execution (e.g., for CustomAction)
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 requiredQuorumPercentage; // % of total effective voting weight required
        uint256 majorityThresholdPercentage; // % of votesFor needed to pass (votesFor / (votesFor + votesAgainst))
        ProposalState state;
        mapping(address => bool) hasVoted; // Voter address => true
    }

    struct BountyTask {
        uint256 id;
        address creator;
        address assignee; // Member assigned to complete the task
        string description;
        uint256 bountyAmount;
        address bountyToken; // ERC20 token address for the bounty
        uint256 deadline;
        string proofIpfsHash; // IPFS hash or URI for proof of completion
        TaskState state;
        address[] verifiers; // Addresses authorized to verify this task (can be empty, relying on general rule)
        mapping(address => bool) hasVerified; // Verifier => true
        uint256 verificationsNeeded; // Number of verifications required to pass
        uint256 verifiedCount;
        uint256 lastActivityTimestamp; // For community health index
    }

    // --- State Variables ---
    address public admin; // A custom admin role, separate from Ownable's owner, for organizational flexibility.
    uint256 public constant INITIAL_REPUTATION = 100; // Starting reputation for new members
    uint256 public reputationDecayRatePerDay = 1; // Amount of reputation to decay per day (can be updated by governance)
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 500; // Minimum reputation to submit a proposal

    uint256 public proposalCounter;
    uint256 public taskCounter;

    // Governance parameters (can be updated via proposals)
    uint256 public proposalQuorumPercentage = 20; // 20% of calculated total effective voting weight
    uint256 public proposalMajorityPercentage = 60; // 60% of votes in favor to pass
    uint256 public proposalVotingPeriod = 3 days;

    // Mappings
    mapping(address => Member) public members;
    mapping(bytes32 => Tier) public communityTiers; // tierId => Tier
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => BountyTask) public bountyTasks;

    // --- Events ---
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event SkillRegistered(address indexed member, bytes32 skillHash);
    event SkillEndorsed(address indexed endorser, address indexed member, bytes32 skillHash);
    event SkillEndorsementRevoked(address indexed revoker, address indexed member, bytes32 skillHash);
    event ReputationDecayed(address indexed member, uint256 oldReputation, uint256 newReputation);
    event ReputationDecayRateUpdated(uint256 newRate);
    event TierDefined(bytes32 indexed tierId, string name, uint256 minReputation, uint256 requiredStake, address stakeToken, uint256 maxMembers);
    event TierUpdated(bytes32 indexed tierId, string name, uint256 minReputation, uint256 requiredStake, address stakeToken, uint256 maxMembers);
    event MemberJoinedTier(address indexed member, bytes32 indexed tierId);
    event MemberLeftTier(address indexed member, bytes32 indexed tierId);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 indexed proposalId, ProposalState newState);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 indexed proposalId, address indexed recipient, uint256 amount, address tokenAddress);
    event TreasuryWithdrawalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount, address tokenAddress);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 bountyAmount, address bountyToken);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed submitter, string proofIpfsHash);
    event TaskVerified(uint256 indexed taskId, address indexed verifier);
    event BountyClaimed(uint256 indexed taskId, address indexed claimant, uint256 amount, address tokenAddress);
    event ParameterUpdateProposed(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ParameterUpdated(bytes32 paramKey, uint256 newValue);
    event CommunityHealthIndexCalculated(uint256 healthIndex);
    event TierRequirementsAdjusted(bytes32 indexed tierId, uint256 newMinReputation, uint256 newRequiredStake);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier ensureMemberExists(address _member) {
        // Initialize member data if it's their first interaction
        if (members[_member].lastActivityTimestamp == 0 && members[_member].reputationScore == 0) {
            members[_member].reputationScore = INITIAL_REPUTATION;
            members[_member].lastReputationDecayTimestamp = block.timestamp;
            members[_member].lastActivityTimestamp = block.timestamp;
            // No event for initial creation to avoid spam. Can be added if needed.
        }
        _;
    }

    // --- I. Infrastructure & Access Control ---

    constructor() {
        admin = msg.sender;
        // Optionally define a default 'Public' or 'No Tier' with ID 0.
        // For simplicity, members[address].currentTierId == 0 implies no tier.
    }

    // Inherited from Pausable:
    // function pauseContract() public onlyOwner { _pause(); }
    // function unpauseContract() public onlyOwner { _unpause(); }

    function updateAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        emit AdminUpdated(admin, newAdmin);
        admin = newAdmin;
    }

    function proposeParameterUpdate(bytes32 paramKey, uint256 newValue)
        public
        whenNotPaused
        ensureMemberExists(msg.sender)
        returns (uint256)
    {
        require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL, "Not enough reputation to submit a proposal");
        
        uint256 proposalId = ++proposalCounter;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: string(abi.encodePacked("Parameter Update: ", paramKey.toString(), " to ", newValue.toString())),
            description: string(abi.encodePacked("Proposing to update ", paramKey.toString(), " to a new value of ", newValue.toString(), ".")),
            proposalType: ProposalType.ParameterUpdate,
            callData: abi.encode(paramKey, newValue), // Encode key and new value
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            requiredQuorumPercentage: proposalQuorumPercentage,
            majorityThresholdPercentage: proposalMajorityPercentage,
            state: ProposalState.Active, // Starts as Active directly for voting
            hasVoted: new mapping(address => bool)
        });
        emit ProposalSubmitted(proposalId, msg.sender, ProposalType.ParameterUpdate, proposals[proposalId].title);
        emit ParameterUpdateProposed(proposalId, paramKey, newValue);
        return proposalId;
    }

    function executeParameterUpdate(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.proposalType == ProposalType.ParameterUpdate, "Proposal type must be ParameterUpdate");
        
        // This implicitly checks if the proposal has passed.
        // An explicit check for state == Succeeded is needed, which is handled in `executeProposal`.
        // This function is intended to be called by `executeProposal` after success.
        revert("This function is intended for internal call by executeProposal.");
    }

    // Internal function called by `executeProposal` for parameter updates
    function _executeParameterUpdateInternal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        (bytes32 paramKey, uint256 newValue) = abi.decode(proposal.callData, (bytes32, uint256));

        // This requires careful handling, usually with a whitelist or enum for allowed keys.
        // For demonstration, we'll allow specific keys directly.
        if (paramKey == keccak256("reputationDecayRatePerDay")) {
            reputationDecayRatePerDay = newValue;
            emit ReputationDecayRateUpdated(newValue);
        } else if (paramKey == keccak256("proposalQuorumPercentage")) {
            require(newValue > 0 && newValue <= 100, "Quorum must be between 1 and 100");
            proposalQuorumPercentage = newValue;
        } else if (paramKey == keccak256("proposalMajorityPercentage")) {
            require(newValue > 0 && newValue <= 100, "Majority must be between 1 and 100");
            proposalMajorityPercentage = newValue;
        } else if (paramKey == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = newValue;
        } else if (paramKey == keccak256("MIN_REPUTATION_FOR_PROPOSAL")) {
            MIN_REPUTATION_FOR_PROPOSAL = newValue;
        } else {
            revert("Unknown or unsupported parameter key for update");
        }

        emit ParameterUpdated(paramKey, newValue);
    }


    // --- II. Reputation & Skill Management ---

    function registerSkill(bytes32 skillHash) public whenNotPaused ensureMemberExists(msg.sender) {
        require(skillHash != 0, "Skill hash cannot be zero");
        require(!members[msg.sender].skills[skillHash], "Skill already registered");
        members[msg.sender].skills[skillHash] = true;
        members[msg.sender].lastActivityTimestamp = block.timestamp; // Update activity
        emit SkillRegistered(msg.sender, skillHash);
    }

    function endorseSkill(address member, bytes32 skillHash) public whenNotPaused ensureMemberExists(msg.sender) ensureMemberExists(member) {
        require(msg.sender != member, "Cannot endorse your own skill");
        require(members[member].skills[skillHash], "Member has not registered this skill");
        require(!members[msg.sender].endorsedSkills[member][skillHash], "Already endorsed this skill for this member");

        members[msg.sender].endorsedSkills[member][skillHash] = true;
        members[member].reputationScore += 10; // Example: +10 reputation for each endorsement
        members[member].lastActivityTimestamp = block.timestamp; // Update activity for endorsed member
        members[msg.sender].lastActivityTimestamp = block.timestamp; // Update activity for endorser

        emit SkillEndorsed(msg.sender, member, skillHash);
    }

    function revokeSkillEndorsement(address member, bytes32 skillHash) public whenNotPaused ensureMemberExists(msg.sender) ensureMemberExists(member) {
        require(members[msg.sender].endorsedSkills[member][skillHash], "No active endorsement to revoke");

        members[msg.sender].endorsedSkills[member][skillHash] = false;
        uint256 oldReputation = members[member].reputationScore;
        if (members[member].reputationScore >= 10) { // Prevent reputation from going negative or below a floor
            members[member].reputationScore -= 10;
        } else {
            members[member].reputationScore = 0; // Set to 0 if subtraction goes below
        }
        members[member].lastActivityTimestamp = block.timestamp;
        members[msg.sender].lastActivityTimestamp = block.timestamp;

        emit SkillEndorsementRevoked(msg.sender, member, skillHash);
        emit ReputationDecayed(member, oldReputation, members[member].reputationScore);
    }

    function updateReputationDecayRate(uint256 newRatePerDay) public onlyAdmin { // This could be made governance-controlled
        reputationDecayRatePerDay = newRatePerDay;
        emit ReputationDecayRateUpdated(newRatePerDay);
    }

    function triggerReputationDecay(address member) public whenNotPaused ensureMemberExists(member) {
        uint256 lastDecay = members[member].lastReputationDecayTimestamp;
        uint256 daysPassed = (block.timestamp - lastDecay) / 1 days;

        if (daysPassed > 0) {
            uint256 oldReputation = members[member].reputationScore;
            uint256 decayAmount = daysPassed * reputationDecayRatePerDay;
            if (members[member].reputationScore > decayAmount) {
                members[member].reputationScore -= decayAmount;
            } else {
                members[member].reputationScore = 0;
            }
            members[member].lastReputationDecayTimestamp = block.timestamp;
            emit ReputationDecayed(member, oldReputation, members[member].reputationScore);
        }
    }

    function getReputationScore(address member) public view returns (uint256) {
        uint256 currentScore = members[member].reputationScore;
        uint256 lastDecay = members[member].lastReputationDecayTimestamp;
        uint256 daysPassed = (block.timestamp - lastDecay) / 1 days;

        if (daysPassed > 0) {
            uint256 decayAmount = daysPassed * reputationDecayRatePerDay;
            if (currentScore > decayAmount) {
                currentScore -= decayAmount;
            } else {
                currentScore = 0;
            }
        }
        return currentScore;
    }

    // --- III. Adaptive Membership Tiers ---

    function defineCommunityTier(
        bytes32 tierId,
        string calldata name,
        uint256 minReputation,
        uint256 requiredStake,
        address stakeToken,
        uint256 maxMembers
    ) public onlyAdmin whenNotPaused { // This should ideally be a governance proposal
        require(tierId != 0, "Tier ID cannot be zero");
        require(communityTiers[tierId].stakeToken == address(0), "Tier ID already exists"); // Check if tier is initialized by default value

        communityTiers[tierId] = Tier({
            name: name,
            minReputation: minReputation,
            requiredStake: requiredStake,
            stakeToken: stakeToken,
            maxMembers: maxMembers,
            currentMemberCount: 0,
            members: new mapping(address => bool) // Initialize the mapping
        });

        emit TierDefined(tierId, name, minReputation, requiredStake, stakeToken, maxMembers);
    }

    function updateCommunityTier(
        bytes32 tierId,
        string calldata name,
        uint256 minReputation,
        uint256 requiredStake,
        address stakeToken,
        uint256 maxMembers
    ) public onlyAdmin whenNotPaused { // This should ideally be a governance proposal
        require(communityTiers[tierId].stakeToken != address(0), "Tier ID does not exist");

        Tier storage tier = communityTiers[tierId];
        tier.name = name;
        tier.minReputation = minReputation;
        tier.requiredStake = requiredStake;
        tier.stakeToken = stakeToken;
        tier.maxMembers = maxMembers;

        emit TierUpdated(tierId, name, minReputation, requiredStake, stakeToken, maxMembers);
    }

    function joinCommunityTier(bytes32 tierId) public whenNotPaused ensureMemberExists(msg.sender) {
        Tier storage tier = communityTiers[tierId];
        require(tier.stakeToken != address(0), "Tier does not exist"); // Check if tier is initialized
        require(members[msg.sender].currentTierId == 0, "Already in a tier. Leave first.");
        require(getReputationScore(msg.sender) >= tier.minReputation, "Not enough reputation to join this tier");
        if (tier.maxMembers > 0) {
            require(tier.currentMemberCount < tier.maxMembers, "Tier is full");
        }

        if (tier.requiredStake > 0) {
            require(tier.stakeToken != address(0), "Stake token not defined for this tier");
            IERC20 stakeERC20 = IERC20(tier.stakeToken);
            require(stakeERC20.transferFrom(msg.sender, address(this), tier.requiredStake), "Stake transfer failed. Check allowance and balance.");
        }

        members[msg.sender].currentTierId = tierId;
        tier.members[msg.sender] = true;
        tier.currentMemberCount++;
        members[msg.sender].lastActivityTimestamp = block.timestamp;

        emit MemberJoinedTier(msg.sender, tierId);
    }

    function leaveCommunityTier() public whenNotPaused ensureMemberExists(msg.sender) {
        bytes32 currentTierId = members[msg.sender].currentTierId;
        require(currentTierId != 0, "Not currently in a tier");

        Tier storage tier = communityTiers[currentTierId];
        require(tier.members[msg.sender], "Member is not registered in this tier (internal error)");

        members[msg.sender].currentTierId = 0;
        delete tier.members[msg.sender]; // Remove from tier's members mapping
        tier.currentMemberCount--;

        if (tier.requiredStake > 0) {
            require(tier.stakeToken != address(0), "Stake token not defined for this tier for refund");
            IERC20 stakeERC20 = IERC20(tier.stakeToken);
            require(stakeERC20.transfer(msg.sender, tier.requiredStake), "Stake refund failed");
        }
        members[msg.sender].lastActivityTimestamp = block.timestamp;

        emit MemberLeftTier(msg.sender, currentTierId);
    }

    function getMemberTier(address member) public view returns (bytes32) {
        return members[member].currentTierId;
    }

    function getTierDetails(bytes32 tierId) public view returns (string memory name, uint256 minReputation, uint256 requiredStake, address stakeToken, uint256 maxMembers, uint256 currentMemberCount) {
        Tier storage tier = communityTiers[tierId];
        require(tier.stakeToken != address(0), "Tier does not exist"); // Check if tier is initialized
        return (tier.name, tier.minReputation, tier.requiredStake, tier.stakeToken, tier.maxMembers, tier.currentMemberCount);
    }

    // --- IV. Governance & Treasury ---

    function submitProposal(
        string calldata title,
        string calldata description,
        ProposalType proposalType,
        bytes calldata callData
    ) public whenNotPaused ensureMemberExists(msg.sender) returns (uint256) {
        require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL, "Not enough reputation to submit a proposal");

        uint256 proposalId = ++proposalCounter;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            proposalType: proposalType,
            callData: callData,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            requiredQuorumPercentage: proposalQuorumPercentage,
            majorityThresholdPercentage: proposalMajorityPercentage,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });
        members[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ProposalSubmitted(proposalId, msg.sender, proposalType, title);
        return proposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused ensureMemberExists(msg.sender) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not in active voting state");
        require(block.timestamp <= proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 votingWeight = getEffectiveVotingWeight(msg.sender);
        require(votingWeight > 0, "No effective voting weight");

        if (support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        members[msg.sender].lastActivityTimestamp = block.timestamp;

        emit VoteCast(proposalId, msg.sender, support, votingWeight);
    }

    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not in active voting state");
        require(block.timestamp > proposal.votingPeriodEnd, "Voting period has not ended yet");

        uint256 totalEffectiveVotingWeight = calculateTotalEffectiveVotingWeight(); // Represents total possible voting power
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;

        bool quorumMet = (totalVotesCast * 100) / totalEffectiveVotingWeight >= proposal.requiredQuorumPercentage;
        bool majorityMet = false;
        if (totalVotesCast > 0) { // Avoid division by zero
            majorityMet = (proposal.votesFor * 100) / totalVotesCast >= proposal.majorityThresholdPercentage;
        }

        if (quorumMet && majorityMet) {
            proposal.state = ProposalState.Succeeded;
            // Execute the specific action based on proposal type
            if (proposal.proposalType == ProposalType.TreasuryAllocation) {
                // Treasury allocation requires a separate `executeTreasuryWithdrawal` call
                // but this marks the proposal as succeeded for that execution.
            } else if (proposal.proposalType == ProposalType.ParameterUpdate) {
                _executeParameterUpdateInternal(proposalId);
            } else if (proposal.proposalType == ProposalType.CustomAction) {
                 // For custom actions, try to call the encoded data.
                 // This requires a separate proxy or careful target contract setup in real dApps.
                 // For simplicity, it attempts to call a function within this contract or a trusted one.
                (bool success, ) = address(this).call(proposal.callData);
                require(success, "Custom action execution failed");
            } else if (proposal.proposalType == ProposalType.TierDefinition || proposal.proposalType == ProposalType.TierUpdate) {
                 // For tier definition/update proposals, actual execution would involve decoding `callData`
                 // and calling `defineCommunityTier` or `updateCommunityTier` internally.
                 // For this example, we'll just mark it as succeeded.
            }
        } else {
            proposal.state = ProposalState.Failed;
        }

        emit ProposalExecuted(proposalId, proposal.state);
    }

    function depositTreasuryFunds() public payable whenNotPaused {
        require(msg.value > 0, "Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function proposeTreasuryWithdrawal(address recipient, uint256 amount, address tokenAddress)
        public
        whenNotPaused
        ensureMemberExists(msg.sender)
        returns (uint256)
    {
        require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL, "Not enough reputation to submit a proposal");
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");

        uint256 proposalId = ++proposalCounter;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: string(abi.encodePacked("Treasury Withdrawal to ", uint160(recipient).toHexString(), " of ", amount.toString())),
            description: "Proposed withdrawal of funds from treasury.",
            proposalType: ProposalType.TreasuryAllocation,
            callData: abi.encode(recipient, amount, tokenAddress), // Encode recipient, amount, tokenAddress
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            requiredQuorumPercentage: proposalQuorumPercentage,
            majorityThresholdPercentage: proposalMajorityPercentage,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalSubmitted(proposalId, msg.sender, ProposalType.TreasuryAllocation, proposals[proposalId].title);
        emit TreasuryWithdrawalProposed(proposalId, recipient, amount, tokenAddress);
        return proposalId;
    }

    function executeTreasuryWithdrawal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Succeeded, "Proposal must be in Succeeded state to execute withdrawal");
        require(proposal.proposalType == ProposalType.TreasuryAllocation, "Proposal type must be TreasuryAllocation");

        // Decode callData specific to TreasuryAllocation
        (address recipient, uint256 amount, address tokenAddress) = abi.decode(proposal.callData, (address, uint256, address));

        if (tokenAddress == address(0)) { // ETH withdrawal
            require(address(this).balance >= amount, "Insufficient ETH balance in treasury");
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else { // ERC20 token withdrawal
            IERC20 token = IERC20(tokenAddress);
            require(token.balanceOf(address(this)) >= amount, "Insufficient ERC20 token balance in treasury");
            require(token.transfer(recipient, amount), "ERC20 transfer failed");
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, proposal.state);
        emit TreasuryWithdrawalExecuted(proposalId, recipient, amount, tokenAddress);
    }

    // --- V. Task & Contribution System ---

    function createBountyTask(
        string calldata description,
        uint256 bountyAmount,
        address bountyToken,
        uint256 deadline
    ) public whenNotPaused ensureMemberExists(msg.sender) returns (uint256) {
        require(bountyAmount > 0, "Bounty must be greater than zero");
        require(bountyToken != address(0), "Bounty token cannot be zero address");
        require(deadline > block.timestamp, "Deadline must be in the future");

        // Transfer bounty funds to the contract (requires prior approval)
        IERC20 token = IERC20(bountyToken);
        require(token.transferFrom(msg.sender, address(this), bountyAmount), "Bounty token transfer failed. Check allowance.");

        uint256 taskId = ++taskCounter;
        bountyTasks[taskId] = BountyTask({
            id: taskId,
            creator: msg.sender,
            assignee: address(0), // No assignee yet
            description: description,
            bountyAmount: bountyAmount,
            bountyToken: bountyToken,
            deadline: deadline,
            proofIpfsHash: "",
            state: TaskState.Open,
            verifiers: new address[](0), // Can be assigned later by governance or specific roles
            hasVerified: new mapping(address => bool),
            verificationsNeeded: 1, // Default, can be increased later
            verifiedCount: 0,
            lastActivityTimestamp: block.timestamp
        });
        members[msg.sender].lastActivityTimestamp = block.timestamp;
        emit TaskCreated(taskId, msg.sender, bountyAmount, bountyToken);
        return taskId;
    }

    function assignTask(uint256 taskId, address assignee) public onlyAdmin whenNotPaused ensureMemberExists(assignee) { // Or specific role/governance
        BountyTask storage task = bountyTasks[taskId];
        require(task.id != 0, "Task does not exist");
        require(task.state == TaskState.Open, "Task is not open for assignment");
        require(assignee != address(0), "Assignee cannot be zero address");
        // Could add reputation checks for assignee here (e.g., must have X reputation or be in a certain tier)

        task.assignee = assignee;
        task.state = TaskState.Assigned;
        task.lastActivityTimestamp = block.timestamp;
        members[msg.sender].lastActivityTimestamp = block.timestamp; // Admin's activity
        members[assignee].lastActivityTimestamp = block.timestamp; // Assignee's activity

        emit TaskAssigned(taskId, assignee);
    }

    function submitTaskCompletion(uint256 taskId, string calldata proofIpfsHash) public whenNotPaused ensureMemberExists(msg.sender) {
        BountyTask storage task = bountyTasks[taskId];
        require(task.id != 0, "Task does not exist");
        require(task.assignee == msg.sender, "Only the assigned member can submit completion");
        require(task.state == TaskState.Assigned, "Task is not in assigned state");
        require(block.timestamp <= task.deadline, "Task deadline has passed");
        require(bytes(proofIpfsHash).length > 0, "Proof IPFS hash cannot be empty");

        task.proofIpfsHash = proofIpfsHash;
        task.state = TaskState.Submitted;
        task.lastActivityTimestamp = block.timestamp;
        members[msg.sender].lastActivityTimestamp = block.timestamp;

        emit TaskCompletionSubmitted(taskId, msg.sender, proofIpfsHash);
    }

    function verifyTaskCompletion(uint256 taskId) public whenNotPaused ensureMemberExists(msg.sender) {
        BountyTask storage task = bountyTasks[taskId];
        require(task.id != 0, "Task does not exist");
        require(task.state == TaskState.Submitted, "Task is not in submitted state for verification");
        // Simplified authorization: only admin or members in a certain tier can verify.
        // In a real dApp, `verifiers` array or a more complex governance selection could be used.
        require(msg.sender == admin || getMemberTier(msg.sender) != 0, "Caller is not authorized to verify this task");

        require(!task.hasVerified[msg.sender], "Already verified this task");

        task.hasVerified[msg.sender] = true;
        task.verifiedCount++;
        task.lastActivityTimestamp = block.timestamp;
        members[msg.sender].lastActivityTimestamp = block.timestamp; // Verifier's activity

        if (task.verifiedCount >= task.verificationsNeeded) {
            task.state = TaskState.Verified;
            // Boost reputation of assignee upon successful verification
            uint256 oldReputation = members[task.assignee].reputationScore;
            members[task.assignee].reputationScore += 50; // Example: +50 reputation for task completion
            members[task.assignee].lastActivityTimestamp = block.timestamp; // Assignee's activity upon verification
            emit ReputationDecayed(task.assignee, oldReputation, members[task.assignee].reputationScore); // Using "Decayed" event for reputation changes
        }

        emit TaskVerified(taskId, msg.sender);
    }

    function claimBountyReward(uint256 taskId) public whenNotPaused ensureMemberExists(msg.sender) {
        BountyTask storage task = bountyTasks[taskId];
        require(task.id != 0, "Task does not exist");
        require(task.assignee == msg.sender, "Only the assigned member can claim the bounty");
        require(task.state == TaskState.Verified, "Task has not been verified yet");

        task.state = TaskState.Claimed; // Mark as claimed to prevent double claims
        task.lastActivityTimestamp = block.timestamp;
        members[msg.sender].lastActivityTimestamp = block.timestamp;

        IERC20 bountyToken = IERC20(task.bountyToken);
        require(bountyToken.transfer(msg.sender, task.bountyAmount), "Bounty transfer failed");

        emit BountyClaimed(taskId, msg.sender, task.bountyAmount, task.bountyToken);
    }

    // --- VI. Adaptive & Dynamic Mechanisms ---

    // Calculates a synthetic "Community Health Index" based on recent on-chain activity.
    // This is a proxy for community sentiment or engagement.
    // Note: For large communities, iterating through all proposals/tasks might be gas-intensive.
    // In a production environment, this might involve off-chain aggregation or a keeper updating a cached value.
    function calculateCommunityHealthIndex() public view returns (uint256) {
        uint256 recentProposalsCount = 0; // Proposals created/active in last 7 days
        uint256 recentTasksActivityCount = 0; // Tasks with activity (created/submitted/verified) in last 7 days

        uint256 sevenDaysAgo = block.timestamp - 7 days;

        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].creationTimestamp >= sevenDaysAgo) {
                recentProposalsCount++;
            }
        }

        for (uint256 i = 1; i <= taskCounter; i++) {
            if (bountyTasks[i].lastActivityTimestamp >= sevenDaysAgo) {
                recentTasksActivityCount++;
            }
        }

        // Simple weighted sum for the health index. Weights are arbitrary.
        // This index can be expanded to include unique voters, new member joins, etc.
        uint256 healthScore = (recentProposalsCount * 50) + (recentTasksActivityCount * 100);

        emit CommunityHealthIndexCalculated(healthScore); // For off-chain tracking
        return healthScore;
    }

    // Adjusts tier requirements based on the current Community Health Index.
    // This function demonstrates an "adaptive" mechanism. It could be called by governance
    // or triggered by a keeper service periodically.
    function adjustTierRequirements(bytes32 tierId) public onlyAdmin whenNotPaused { // Could be a governance proposal
        Tier storage tier = communityTiers[tierId];
        require(tier.stakeToken != address(0), "Tier does not exist");

        uint256 healthIndex = calculateCommunityHealthIndex();
        uint256 oldMinReputation = tier.minReputation;
        uint256 oldRequiredStake = tier.requiredStake;

        // Example dynamic logic:
        // If community health is very high, make tiers slightly harder to join (more exclusive)
        // If community health is low, make tiers easier to join (encourage participation)
        if (healthIndex > 2000) { // Arbitrary high threshold
            tier.minReputation = tier.minReputation * 105 / 100; // Increase by 5%
            tier.requiredStake = tier.requiredStake * 105 / 100; // Increase by 5%
        } else if (healthIndex < 500) { // Arbitrary low threshold
            tier.minReputation = tier.minReputation * 95 / 100; // Decrease by 5%
            tier.requiredStake = tier.requiredStake * 95 / 100; // Decrease by 5%
        }
        // Ensure minimums or maximums are not breached
        if (tier.minReputation < INITIAL_REPUTATION) tier.minReputation = INITIAL_REPUTATION;
        if (tier.requiredStake < 100) tier.requiredStake = 100; // Example minimum stake of 100 units

        emit TierRequirementsAdjusted(tierId, tier.minReputation, tier.requiredStake);
    }

    // Calculates a member's effective voting power based on reputation, tier, and community health.
    function getEffectiveVotingWeight(address member) public view returns (uint256) {
        uint256 reputation = getReputationScore(member);
        bytes32 tierId = members[member].currentTierId;
        uint256 weight = 0;

        // Base weight from reputation: 1 unit of voting weight for every 10 reputation points
        weight += reputation / 10;

        // Additional weight from tier membership
        if (tierId != 0) {
            Tier storage tier = communityTiers[tierId];
            if (bytes(tier.name).length > 0) { // Check if tier is valid
                 // Assign additional weight based on tier name (illustrative)
                 if (keccak256(abi.encodePacked(tier.name)) == keccak256(abi.encodePacked("Explorer"))) {
                     weight += 50;
                 } else if (keccak256(abi.encodePacked(tier.name)) == keccak256(abi.encodePacked("Contributor"))) {
                     weight += 100;
                 } else if (keccak256(abi.encodePacked(tier.name)) == keccak256(abi.encodePacked("Architect"))) {
                     weight += 200;
                 }
            }
        }

        // Add a small multiplier based on community health index (proxy for sentiment)
        // If community is thriving (high health index), votes are more impactful.
        uint256 healthIndex = calculateCommunityHealthIndex();
        // Example: Health Index of 100 adds 10% to weight, Health Index of 500 adds 50%
        uint256 healthMultiplier = 100 + (healthIndex / 10);
        weight = weight * healthMultiplier / 100;

        return weight;
    }

    // Helper function to estimate total effective voting weight for quorum calculations.
    // Note: For a very large number of members, this is gas-intensive and often estimated or updated off-chain.
    // For this example, it returns a placeholder based on assumed maximum potential.
    function calculateTotalEffectiveVotingWeight() public view returns (uint256) {
        // In a real application, this would either:
        // 1. Iterate through all active members and sum their getEffectiveVotingWeight (gas expensive).
        // 2. Be a value updated periodically by a trusted keeper/oracle.
        // 3. Be a sum of all stakes, if voting power is primarily stake-based.
        // For demonstration, let's return a fixed, plausible maximum for a medium-sized active community.
        // This ensures quorum calculations always have a denominator without gas issues.
        return 100000; // A conceptual maximum total voting weight for quorum calculations
    }
}
```