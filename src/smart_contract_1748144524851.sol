Okay, let's design a smart contract that combines dynamic membership, reputation, multi-weighted governance, and controlled interaction with external contracts. We'll call it `DynamicDAO`.

**Concept:**

A Decentralized Autonomous Organization (DAO) where membership is not solely based on token ownership. Members have reputation scores and tiers that influence their voting power and proposal rights. The DAO can govern its own parameters and interact with external contracts via proposals. Reputation can be gained, lost, and potentially decays over time. Staking ETH provides an additional boost to voting power.

**Advanced Concepts:**

1.  **Dynamic Membership:** Members can be added/removed via governance, potentially based on criteria beyond token holding.
2.  **Reputation System:** An on-chain score influencing governance, managed by governance itself.
3.  **Multi-Weighted Voting:** Voting power is a function of reputation, membership tier, and staked assets.
4.  **Parameter Governance:** Key DAO parameters (like voting periods, quorum, reputation thresholds) can be changed via proposals.
5.  **Generic External Call Execution:** The DAO can propose and execute arbitrary function calls on other contracts, enabling complex interactions (DeFi, other DAOs, etc.) controlled by governance.
6.  **Self-Governance:** Initial owner can transfer control of critical parameters and treasury actions to the DAO itself.
7.  **Staking for Governance Boost:** Staking ETH provides a direct increase in voting power.
8.  **Proposal Encoding/Decoding:** Using `abi.encode` and `abi.decode` to handle diverse proposal types within a single proposal mechanism.

---

**Outline:**

1.  **State Variables:** Store members, reputation, tiers, parameters, proposals, votes, staking info, proposal counter.
2.  **Enums:** ProposalState, ProposalType, MemberTier.
3.  **Structs:** Member, Proposal.
4.  **Events:** For key actions (member changes, proposals, votes, execution, parameter changes, staking).
5.  **Modifiers:** Restrict function access based on member status, proposal state, roles, etc.
6.  **Internal Helpers:** Functions for calculating voting weight, checking quorum, processing proposal data, updating state.
7.  **Public/External Functions:**
    *   Deployment & Initialization
    *   Membership Management (via Proposals)
    *   Reputation Management (via Proposals)
    *   Parameter Governance (via Proposals)
    *   Treasury Management (ETH/Token/External Calls via Proposals)
    *   Staking
    *   Proposal Lifecycle (Creation, Voting, Execution, Cancellation)
    *   View Functions (Read state)

---

**Function Summary (at least 20 public/external functions):**

1.  `constructor()`: Initializes the contract, sets initial parameters, adds initial members (via owner).
2.  `transferOwnershipToDAO()`: Transfers ownership of critical parameters/treasury control to the DAO governance process.
3.  `isMember(address memberAddress) view`: Checks if an address is a member.
4.  `getMemberInfo(address memberAddress) view`: Retrieves reputation, tier, and active status for a member.
5.  `getReputation(address memberAddress) view`: Retrieves the current reputation score of a member.
6.  `getStakedBalance(address memberAddress) view`: Retrieves the amount of ETH staked by a member.
7.  `getParameter(bytes32 parameterName) view`: Retrieves the value of a specific DAO parameter.
8.  `getVotingPeriod() view`: Convenience view for the voting period parameter.
9.  `getQuorumPercentage() view`: Convenience view for the quorum percentage parameter.
10. `getProposalThresholdReputation() view`: Convenience view for the minimum reputation to propose.
11. `getReputationDecayRate() view`: Convenience view for the reputation decay rate parameter.
12. `receive() external payable`: Allows the contract to receive ETH into its treasury.
13. `getTokenBalance(address tokenAddress) view`: Retrieves the balance of a specific ERC20 token held by the DAO treasury.
14. `propose(uint256 proposalType, bytes calldata data) returns (uint256 proposalId)`: Creates a new proposal. `data` is ABI-encoded based on `proposalType`. Requires minimum reputation.
15. `getProposal(uint256 proposalId) view`: Retrieves detailed information about a specific proposal.
16. `getCurrentProposalState(uint256 proposalId) view`: Calculates and returns the current state of a proposal (considering time).
17. `vote(uint256 proposalId, bool support)`: Casts a vote (for or against) on an active proposal. Voting weight is calculated dynamically.
18. `executeProposal(uint256 proposalId)`: Executes a proposal that has succeeded and is past its voting period.
19. `cancelProposal(uint256 proposalId)`: Allows the proposer to cancel their proposal before it becomes active.
20. `stake() external payable`: Allows a member to stake ETH to boost their voting power.
21. `unstake(uint256 amount)`: Allows a member to unstake their ETH (subject to rules, e.g., not staked on an active proposal).

**(Note: There are 21 functions listed above to ensure the requirement is met, plus internal helpers will add more total functions).**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup only
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For safe calls

// --- Outline ---
// 1. State Variables
// 2. Enums & Structs
// 3. Events
// 4. Modifiers
// 5. Internal Helper Functions (Voting Weight, Quorum Check, Proposal Decoding, State Update)
// 6. Public/External Functions (Deployment, Ownership Transfer, Membership, Reputation, Parameters, Treasury, Staking, Proposals, Views)

// --- Function Summary ---
// 1.  constructor() - Initializes DAO, sets initial parameters, adds initial members.
// 2.  transferOwnershipToDAO() - Transfers control of critical parameters/treasury to DAO governance.
// 3.  isMember(address memberAddress) view - Checks if an address is a member.
// 4.  getMemberInfo(address memberAddress) view - Retrieves member details (reputation, tier, active).
// 5.  getReputation(address memberAddress) view - Retrieves reputation score.
// 6.  getStakedBalance(address memberAddress) view - Retrieves staked ETH balance.
// 7.  getParameter(bytes32 parameterName) view - Retrieves a DAO parameter value.
// 8.  getVotingPeriod() view - Retrieves voting period parameter.
// 9.  getQuorumPercentage() view - Retrieves quorum percentage parameter.
// 10. getProposalThresholdReputation() view - Retrieves min reputation to propose.
// 11. getReputationDecayRate() view - Retrieves reputation decay rate parameter.
// 12. receive() external payable - Allows contract to receive ETH.
// 13. getTokenBalance(address tokenAddress) view - Retrieves ERC20 token balance.
// 14. propose(uint256 proposalType, bytes calldata data) returns (uint256 proposalId) - Creates a new proposal.
// 15. getProposal(uint256 proposalId) view - Retrieves proposal details.
// 16. getCurrentProposalState(uint256 proposalId) view - Gets current state of a proposal.
// 17. vote(uint256 proposalId, bool support) - Casts a vote on a proposal.
// 18. executeProposal(uint256 proposalId) - Executes a successful proposal.
// 19. cancelProposal(uint256 proposalId) - Cancels a proposal before it starts.
// 20. stake() external payable - Stakes ETH for voting power boost.
// 21. unstake(uint256 amount) - Unstakes ETH.

contract DynamicDAO is Ownable {
    using Address for address;

    // --- State Variables ---

    struct Member {
        bool isActive;
        uint256 tier; // 0: Non-member, 1: Tier1, 2: Tier2, 3: Tier3 (example)
        int256 reputation; // Can be positive or negative
        uint256 lastReputationDecay; // Timestamp of last decay application
    }

    mapping(address => Member) public members;
    address[] private memberAddresses; // To iterate or count members easily (caution with gas for large DAOs)

    mapping(address => uint256) public stakedEth; // Amount of ETH staked by a member

    // DAO Parameters (can be changed by governance)
    mapping(bytes32 => uint256) public parameters;

    bytes32 constant PARAM_VOTING_PERIOD = keccak256("votingPeriod"); // in seconds
    bytes32 constant PARAM_QUORUM_PERCENTAGE = keccak256("quorumPercentage"); // e.g., 40 for 40%
    bytes32 constant PARAM_PROPOSAL_THRESHOLD_REPUTATION = keccak256("proposalThresholdReputation"); // minimum reputation to create a proposal
    bytes32 constant PARAM_REPUTATION_DECAY_RATE = keccak256("reputationDecayRate"); // amount of reputation to decay per decay period
    bytes32 constant PARAM_REPUTATION_DECAY_PERIOD = keccak256("reputationDecayPeriod"); // in seconds
    bytes32 constant PARAM_TIER1_REPUTATION_THRESHOLD = keccak256("tier1ReputationThreshold");
    bytes32 constant PARAM_TIER2_REPUTATION_THRESHOLD = keccak256("tier2ReputationThreshold");
    bytes32 constant PARAM_TIER3_REPUTATION_THRESHOLD = keccak256("tier3ReputationThreshold");
    bytes32 constant PARAM_STAKE_VOTING_BOOST_FACTOR = keccak256("stakeVotingBoostFactor"); // e.g., 1 ETH staked adds X voting weight

    struct Proposal {
        uint256 id;
        uint256 proposalType; // Enum ProposalType
        bytes data; // Encoded proposal data
        address proposer;
        uint256 createdTimestamp;
        uint256 votingPeriodEnd;
        uint256 voteCountFor; // Total voting weight FOR
        uint256 voteCountAgainst; // Total voting weight AGAINST
        mapping(address => bool) hasVoted; // Prevent double voting
        ProposalState state;
        uint256 totalVotingWeightAtStart; // Snapshot of total possible voting weight when proposal starts
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    uint256 public totalMembers = 0; // Simple member count

    // --- Enums & Structs ---

    enum ProposalState {
        Pending, // Created, but voting hasn't started
        Active, // Voting is open
        Succeeded, // Voting ended, met quorum and majority FOR
        Failed, // Voting ended, did not meet quorum or majority AGAINST
        Executed, // Succeeded proposal has been executed
        Cancelled // Proposal cancelled before voting started
    }

    enum ProposalType {
        ChangeParameter, // Data: abi.encode(bytes32 parameterName, uint256 newValue)
        AddMember, // Data: abi.encode(address memberAddress, uint256 tier)
        RemoveMember, // Data: abi.encode(address memberAddress)
        UpdateReputation, // Data: abi.encode(address memberAddress, int256 reputationChange)
        DecayReputation, // Data: abi.encode() - triggers global decay
        SendETH, // Data: abi.encode(address recipient, uint256 amount)
        SendToken, // Data: abi.encode(address tokenAddress, address recipient, uint256 amount)
        CallExternal // Data: abi.encode(address targetContract, bytes callData)
    }

    // --- Events ---

    event MemberAdded(address indexed member, uint256 tier, int256 reputation);
    event MemberRemoved(address indexed member);
    event MemberReputationUpdated(address indexed member, int256 newReputation, int256 reputationChange);
    event ParameterChanged(bytes32 indexed parameterName, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votingWeight, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ETHReceived(address indexed sender, uint256 amount);
    event ETHSent(address indexed recipient, uint256 amount);
    event TokenSent(address indexed token, address indexed recipient, uint256 amount);
    event ExternalCallExecuted(address indexed target, bytes data);
    event ETHStaked(address indexed staker, uint256 amount);
    event ETHUnstaked(address indexed staker, uint256 amount);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not a member");
        _;
    }

    modifier onlyProposer(uint256 proposalId) {
        require(proposals[proposalId].proposer == msg.sender, "Not the proposer");
        _;
    }

    modifier onlyProposalState(uint256 proposalId, ProposalState expectedState) {
        require(_updateProposalState(proposalId) == expectedState, "Proposal is not in the expected state");
        _;
    }

    modifier onlyNotExecuted(uint256 proposalId) {
         require(proposals[proposalId].state != ProposalState.Executed, "Proposal already executed");
        _;
    }

    modifier onlyGovernanceControlled() {
        // Placeholder: This contract currently uses Ownable for initial setup.
        // After transferOwnershipToDAO(), critical functions should check if
        // the call is coming from within the executeProposal function, initiated by a successful DAO proposal.
        // For simplicity in this example, let's assume functions like _addMember, _changeParameter etc.
        // are only called internally by executeProposal.
        _;
    }

    // --- Constructor & Initialization ---

    // Initial parameters: votingPeriod (seconds), quorumPercentage (0-100),
    // proposalThresholdReputation (int), reputationDecayRate (int), reputationDecayPeriod (seconds),
    // tier thresholds (int), stakeVotingBoostFactor (wei per weight unit)
    constructor(
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        int256 _proposalThresholdReputation,
        int256 _reputationDecayRate,
        uint256 _reputationDecayPeriod,
        int256 _tier1Threshold,
        int256 _tier2Threshold,
        int256 _tier3Threshold,
        uint256 _stakeVotingBoostFactor,
        address[] memory initialMembers,
        int256[] memory initialReputations,
        uint256[] memory initialTiers
    ) Ownable(msg.sender) {
        parameters[PARAM_VOTING_PERIOD] = _votingPeriod;
        parameters[PARAM_QUORUM_PERCENTAGE] = _quorumPercentage;
        parameters[PARAM_PROPOSAL_THRESHOLD_REPUTATION] = _proposalThresholdReputation;
        parameters[PARAM_REPUTATION_DECAY_RATE] = _reputationDecayRate;
        parameters[PARAM_REPUTATION_DECAY_PERIOD] = _reputationDecayPeriod;
        parameters[PARAM_TIER1_REPUTATION_THRESHOLD] = _tier1Threshold;
        parameters[PARAM_TIER2_REPUTATION_THRESHOLD] = _tier2Threshold;
        parameters[PARAM_TIER3_REPUTATION_THRESHOLD] = _tier3Threshold;
        parameters[PARAM_STAKE_VOTING_BOOST_FACTOR] = _stakeVotingBoostFactor;


        require(initialMembers.length == initialReputations.length && initialMembers.length == initialTiers.length, "Initial member data mismatch");
        for (uint i = 0; i < initialMembers.length; i++) {
            require(!members[initialMembers[i]].isActive, "Initial member already exists");
            _addMember(initialMembers[i], initialTiers[i]);
            members[initialMembers[i]].reputation = initialReputations[i]; // Set initial reputation
             members[initialMembers[i]].lastReputationDecay = block.timestamp; // Initialize decay timestamp
        }
    }

    // IMPORTANT: After initial setup, the owner should call this function
    // to relinquish control of critical parameter changes and treasury operations
    // to the DAO's governance mechanism (i.e., execution via executeProposal).
    // For *this example contract*, we are not fully implementing the checks
    // within _changeParameter, _sendETH etc. to verify the caller is executeProposal.
    // A real-world scenario would need a state variable like `bool governanceActivated`
    // and modify access control on internal functions based on this flag.
    function transferOwnershipToDAO() public onlyOwner {
        // In a real scenario, ownership of the contract itself might remain with a multisig,
        // but control over DAO logic (parameters, treasury actions) is transferred
        // to being only executable via successful proposals.
        // For this example, we simply remove the 'onlyOwner' modifier implication
        // from functions intended for DAO governance execution.
        // The `Ownable` ownership isn't transferred away in this example,
        // but the *spirit* is that governance takes over key decisions.
        // A more robust implementation might use a custom role-based access control
        // where the 'DAO_EXECUTOR' role is the contract itself calling from executeProposal.
        // For now, this function serves as a marker that governance takes over.
        emit OwnershipTransferred(owner(), address(this)); // Emit OwnershipTransferred to signal intent
    }

    // --- Internal Helper Functions ---

    // Calculates the voting weight for a member based on reputation, tier, and stake
    function _getVotingWeight(address memberAddress) internal view returns (uint256) {
        if (!members[memberAddress].isActive) {
            return 0;
        }
        Member storage member = members[memberAddress];
        uint256 weight = 0;

        // Reputation contributes to weight (handle negative reputation)
        if (member.reputation > 0) {
             // Scale reputation - could use a more complex function
            weight += uint256(member.reputation) / 10; // Example scaling
        }


        // Tier contributes to weight
        if (member.tier == 1) {
            weight += 50; // Example base weight for tier 1
        } else if (member.tier == 2) {
            weight += 100; // Example base weight for tier 2
        } else if (member.tier == 3) {
            weight += 200; // Example base weight for tier 3
        }

        // Staked ETH contributes to weight
        uint256 stakeFactor = parameters[PARAM_STAKE_VOTING_BOOST_FACTOR];
        if (stakeFactor > 0 && stakedEth[memberAddress] > 0) {
             weight += stakedEth[memberAddress] / stakeFactor; // Example: 1 ETH adds N weight units
        }

        return weight;
    }

    // Calculates the total potential voting weight of all active members
    // NOTE: This can be gas-intensive for large DAOs if calculated by iterating memberAddresses.
    // A better approach for large DAOs is to maintain a `totalActiveVotingWeight` state variable
    // updated whenever membership/reputation/stake changes significantly.
    // For this example, we iterate for simplicity.
    function _calculateTotalVotingWeight() internal view returns (uint256) {
        uint256 totalWeight = 0;
        for (uint i = 0; i < memberAddresses.length; i++) {
            if (members[memberAddresses[i]].isActive) {
                 // Decay reputation simulation here for calculation purposes,
                 // actual state update happens via governance proposal.
                totalWeight += _getVotingWeight(memberAddresses[i]);
            }
        }
        return totalWeight;
    }

    // Updates the proposal state based on current time and voting outcome
    function _updateProposalState(uint256 proposalId) internal returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Pending && block.timestamp >= proposal.createdTimestamp) {
            // Voting period begins immediately upon creation in this example
             proposal.state = ProposalState.Active;
             proposal.votingPeriodEnd = proposal.createdTimestamp + parameters[PARAM_VOTING_PERIOD];
             // Snapshot total voting weight when it becomes active
             proposal.totalVotingWeightAtStart = _calculateTotalVotingWeight();
             emit ProposalStateChanged(proposalId, ProposalState.Active);
        }

        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.votingPeriodEnd) {
            uint256 quorumRequired = (proposal.totalVotingWeightAtStart * parameters[PARAM_QUORUM_PERCENTAGE]) / 100;

            if (proposal.voteCountFor + proposal.voteCountAgainst >= quorumRequired && proposal.voteCountFor > proposal.voteCountAgainst) {
                proposal.state = ProposalState.Succeeded;
                emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
            } else {
                proposal.state = ProposalState.Failed;
                emit ProposalStateChanged(proposalId, ProposalState.Failed);
            }
        }

        return proposal.state;
    }

    // Internal function to add a member
    function _addMember(address memberAddress, uint256 tier) internal { // onlyGovernanceControlled?
         require(!members[memberAddress].isActive, "Member already active");
         require(tier > 0 && tier <= 3, "Invalid tier"); // Assuming tiers 1, 2, 3
         members[memberAddress].isActive = true;
         members[memberAddress].tier = tier;
         members[memberAddress].reputation = 0; // Start with 0 reputation
         members[memberAddress].lastReputationDecay = block.timestamp; // Initialize decay timestamp
         memberAddresses.push(memberAddress); // Add to dynamic array (caution for large DAOs)
         totalMembers++;
         emit MemberAdded(memberAddress, tier, members[memberAddress].reputation);
    }

    // Internal function to remove a member
    function _removeMember(address memberAddress) internal { // onlyGovernanceControlled?
         require(members[memberAddress].isActive, "Member not active");
         members[memberAddress].isActive = false;
         members[memberAddress].tier = 0; // Reset tier
         members[memberAddress].reputation = 0; // Reset reputation on removal
         // Find and remove from memberAddresses (gas intensive)
         for (uint i = 0; i < memberAddresses.length; i++) {
             if (memberAddresses[i] == memberAddress) {
                 // Swap last element with the one to remove, then pop
                 memberAddresses[i] = memberAddresses[memberAddresses.length - 1];
                 memberAddresses.pop();
                 break; // Assuming unique addresses
             }
         }
         totalMembers--;
         emit MemberRemoved(memberAddress);
    }

    // Internal function to update reputation
    function _updateMemberReputation(address memberAddress, int256 reputationChange) internal { // onlyGovernanceControlled?
        require(members[memberAddress].isActive, "Cannot update reputation for non-member");
        members[memberAddress].reputation += reputationChange;
        emit MemberReputationUpdated(memberAddress, members[memberAddress].reputation, reputationChange);
    }

    // Internal function to apply reputation decay for a single member
    function _applyReputationDecay(address memberAddress) internal {
         require(members[memberAddress].isActive, "Cannot apply decay to non-member");
         uint256 decayPeriod = parameters[PARAM_REPUTATION_DECAY_PERIOD];
         int256 decayRate = parameters[PARAM_REPUTATION_DECAY_RATE];

         if (decayPeriod > 0 && decayRate > 0) {
             uint256 periodsPassed = (block.timestamp - members[memberAddress].lastReputationDecay) / decayPeriod;
             if (periodsPassed > 0) {
                 int256 totalDecay = int256(periodsPassed) * decayRate;
                 members[memberAddress].reputation -= totalDecay;
                 members[memberAddress].lastReputationDecay += periodsPassed * decayPeriod; // Update last decay timestamp
                 emit MemberReputationUpdated(memberAddress, members[memberAddress].reputation, -totalDecay);
             }
         }
    }

    // Internal function to send ETH from treasury
    function _sendETH(address payable recipient, uint256 amount) internal { // onlyGovernanceControlled?
         require(address(this).balance >= amount, "Insufficient ETH balance");
         (bool success, ) = recipient.call{value: amount}("");
         require(success, "ETH transfer failed");
         emit ETHSent(recipient, amount);
    }

    // Internal function to send ERC20 token from treasury
    function _sendToken(address tokenAddress, address recipient, uint256 amount) internal { // onlyGovernanceControlled?
         IERC20 token = IERC20(tokenAddress);
         require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
         require(token.transfer(recipient, amount), "Token transfer failed");
         emit TokenSent(tokenAddress, recipient, amount);
    }

     // Internal function to call an arbitrary function on another contract
    function _callExternal(address target, bytes memory data) internal { // onlyGovernanceControlled?
        require(target != address(0), "Target address cannot be zero");
        (bool success, bytes memory result) = target.call(data);
        require(success, string(result)); // Revert with error message from the target contract if call fails
        emit ExternalCallExecuted(target, data);
    }

    // Internal function to change a DAO parameter
    function _changeParameter(bytes32 parameterName, uint256 newValue) internal { // onlyGovernanceControlled?
         parameters[parameterName] = newValue;
         emit ParameterChanged(parameterName, newValue);
    }


    // --- Public/External Functions ---

    // Allows receiving ETH directly to the contract treasury
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    // --- View Functions ---

    function isMember(address memberAddress) public view returns (bool) {
        return members[memberAddress].isActive;
    }

     function getMemberInfo(address memberAddress) public view returns (bool isActive, uint256 tier, int256 reputation) {
        Member storage member = members[memberAddress];
        return (member.isActive, member.tier, member.reputation);
    }

    function getReputation(address memberAddress) public view returns (int256) {
        return members[memberAddress].reputation;
    }

    function getStakedBalance(address memberAddress) public view returns (uint256) {
        return stakedEth[memberAddress];
    }

    function getParameter(bytes32 parameterName) public view returns (uint256) {
        return parameters[parameterName];
    }

    function getVotingPeriod() public view returns (uint256) {
        return parameters[PARAM_VOTING_PERIOD];
    }

    function getQuorumPercentage() public view returns (uint256) {
        return parameters[PARAM_QUORUM_PERCENTAGE];
    }

    function getProposalThresholdReputation() public view returns (int256) {
        return int256(parameters[PARAM_PROPOSAL_THRESHOLD_REPUTATION]);
    }

     function getReputationDecayRate() public view returns (int256) {
        return int256(parameters[PARAM_REPUTATION_DECAY_RATE]);
    }

    // Retrieves full proposal details
    function getProposal(uint256 proposalId) public view returns (
        uint256 id,
        uint256 proposalType,
        bytes memory data,
        address proposer,
        uint256 createdTimestamp,
        uint256 votingPeriodEnd,
        uint256 voteCountFor,
        uint256 voteCountAgainst,
        ProposalState state,
        uint256 totalVotingWeightAtStart
    ) {
        Proposal storage proposal = proposals[proposalId];
        // Note: state needs to be calculated dynamically for public view
        // For simplicity here, we return the stored state. _updateProposalState
        // is used internally before checks like execution.
        return (
            proposal.id,
            proposal.proposalType,
            proposal.data,
            proposal.proposer,
            proposal.createdTimestamp,
            proposal.votingPeriodEnd,
            proposal.voteCountFor,
            proposal.voteCountAgainst,
            proposal.state, // Stored state, might be outdated for 'Active'/'Pending' -> 'Succeeded'/'Failed'
            proposal.totalVotingWeightAtStart
        );
    }

    // Gets the current state of a proposal, calculated dynamically
    function getCurrentProposalState(uint256 proposalId) public returns (ProposalState) {
        // This calls the internal function to ensure state is updated based on time
        return _updateProposalState(proposalId);
    }


    // --- Governance Functions ---

    // Create a new proposal
    function propose(uint256 proposalType, bytes calldata data) external onlyMember returns (uint256 proposalId) {
        require(members[msg.sender].reputation >= int256(parameters[PARAM_PROPOSAL_THRESHOLD_REPUTATION]), "Insufficient reputation to propose");

        uint256 pId = nextProposalId++;
        Proposal storage newProposal = proposals[pId];

        newProposal.id = pId;
        newProposal.proposalType = proposalType;
        newProposal.data = data; // Store encoded data
        newProposal.proposer = msg.sender;
        newProposal.createdTimestamp = block.timestamp; // Voting starts immediately after creation
        newProposal.votingPeriodEnd = block.timestamp + parameters[PARAM_VOTING_PERIOD]; // Set initial end time
        newProposal.state = ProposalState.Active; // Starts in Active state
        newProposal.totalVotingWeightAtStart = _calculateTotalVotingWeight(); // Snapshot weight

        emit ProposalCreated(pId, msg.sender, proposalType);
        emit ProposalStateChanged(pId, ProposalState.Active);

        return pId;
    }

    // Vote on an active proposal
    function vote(uint256 proposalId, bool support) external onlyMember onlyProposalState(proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        _applyReputationDecay(msg.sender); // Apply decay before getting weight for vote calculation
        uint256 votingWeight = _getVotingWeight(msg.sender);
        require(votingWeight > 0, "Voter has no voting weight");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.voteCountFor += votingWeight;
        } else {
            proposal.voteCountAgainst += votingWeight;
        }

        emit VoteCast(proposalId, msg.sender, votingWeight, support);
    }

    // Execute a successful proposal
    function executeProposal(uint256 proposalId) external onlyNotExecuted onlyProposalState(proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[proposalId];

        // Decode and execute based on proposal type
        uint256 pType = proposal.proposalType;
        bytes memory pData = proposal.data;

        if (pType == uint256(ProposalType.ChangeParameter)) {
            (bytes32 parameterName, uint256 newValue) = abi.decode(pData, (bytes32, uint256));
            _changeParameter(parameterName, newValue);

        } else if (pType == uint256(ProposalType.AddMember)) {
            (address memberAddress, uint256 tier) = abi.decode(pData, (address, uint256));
            _addMember(memberAddress, tier); // Note: initial rep is 0, can be adjusted by separate proposal

        } else if (pType == uint256(ProposalType.RemoveMember)) {
            (address memberAddress) = abi.decode(pData, (address));
            _removeMember(memberAddress);

        } else if (pType == uint256(ProposalType.UpdateReputation)) {
            (address memberAddress, int256 reputationChange) = abi.decode(pData, (address, int256));
            _updateMemberReputation(memberAddress, reputationChange);

        } else if (pType == uint256(ProposalType.DecayReputation)) {
             // Apply decay for all active members
             for(uint i = 0; i < memberAddresses.length; i++) {
                 if(members[memberAddresses[i]].isActive) {
                     _applyReputationDecay(memberAddresses[i]);
                 }
             }

        } else if (pType == uint256(ProposalType.SendETH)) {
            (address payable recipient, uint256 amount) = abi.decode(pData, (address, uint256));
            _sendETH(recipient, amount);

        } else if (pType == uint256(ProposalType.SendToken)) {
            (address tokenAddress, address recipient, uint256 amount) = abi.decode(pData, (address, uint256, uint256));
            _sendToken(tokenAddress, recipient, amount);

        } else if (pType == uint256(ProposalType.CallExternal)) {
            (address targetContract, bytes memory callData) = abi.decode(pData, (address, bytes));
            _callExternal(targetContract, callData);

        } else {
            revert("Unknown proposal type");
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    // Allows the proposer to cancel their proposal if it hasn't started voting
    function cancelProposal(uint256 proposalId) external onlyProposer(proposalId) onlyProposalState(proposalId, ProposalState.Pending) {
        Proposal storage proposal = proposals[proposalId];
        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Cancelled);
    }


    // --- Staking Functions ---

    // Stake ETH to gain voting power
    function stake() external payable onlyMember {
        require(msg.value > 0, "Must stake more than 0 ETH");
        stakedEth[msg.sender] += msg.value;
        emit ETHStaked(msg.sender, msg.value);
    }

    // Unstake ETH
    function unstake(uint256 amount) external onlyMember {
        require(amount > 0 && stakedEth[msg.sender] >= amount, "Invalid amount to unstake");

        // Optional: Add checks here to prevent unstaking if ETH is currently
        // locked or required for an ongoing process/proposal type.
        // For simplicity, allowing unstake anytime in this example.

        stakedEth[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH unstake transfer failed"); // This is risky if user address is a contract that reverts

        emit ETHUnstaked(msg.sender, amount);
    }

    // --- Member Utilities ---
    // Note: Iterating over memberAddresses[] can be very gas-intensive for large DAOs.
    // Consider alternative patterns for large member sets if frequent iteration is needed.
    function getMemberAddressAtIndex(uint256 index) external view returns (address) {
        require(index < memberAddresses.length, "Index out of bounds");
        return memberAddresses[index];
    }
     function getMemberCount() external view returns (uint256) {
        return totalMembers; // Or memberAddresses.length; totalMembers might be more accurate if addresses are removed from the array on removal
    }

    // Function to get member tier based on reputation thresholds
    function _getTierByReputation(int256 reputation) internal view returns (uint256) {
        if (reputation >= int256(parameters[PARAM_TIER3_REPUTATION_THRESHOLD])) return 3;
        if (reputation >= int256(parameters[PARAM_TIER2_REPUTATION_THRESHOLD])) return 2;
        if (reputation >= int256(parameters[PARAM_TIER1_REPUTATION_THRESHOLD])) return 1;
        return 0;
    }

     // This function is just for demonstrating how tier calculation *could* be used.
     // The actual member tier stored in the struct is set by governance proposal.
     // A more advanced DAO might automatically update tier based on reputation.
    function calculateTierFromReputation(address memberAddress) external view returns (uint256) {
        require(members[memberAddress].isActive, "Member not active");
        return _getTierByReputation(members[memberAddress].reputation);
    }
}
```

**Explanation of Advanced Concepts in the Code:**

1.  **Dynamic Membership:** The `members` mapping and `memberAddresses` array track members. `_addMember` and `_removeMember` internal functions handle state changes, *intended* to be called only by a successful governance proposal (`executeProposal` calls them based on `ProposalType`).
2.  **Reputation System:** The `reputation` field in the `Member` struct and `_updateMemberReputation` allow tracking and changing a member's score. The `DecayReputation` proposal type and `_applyReputationDecay` function demonstrate how a decay mechanism could be implemented and triggered by governance. Reputation thresholds (`PARAM_TIERx_REPUTATION_THRESHOLD`) define tiers, though the stored tier is updated via governance proposal, not automatically.
3.  **Multi-Weighted Voting:** The `_getVotingWeight` function calculates voting power using a formula combining `member.reputation`, `member.tier`, and `stakedEth[memberAddress]`. The `vote` function uses this dynamic weight.
4.  **Parameter Governance:** Key parameters are stored in a `mapping(bytes32 => uint256)`. The `ChangeParameter` proposal type allows governance to call `_changeParameter` to modify these settings, making the DAO adaptable.
5.  **Generic External Call Execution:** The `CallExternal` proposal type allows the DAO to execute arbitrary `bytes callData` on a `targetContract` using `address.call`. This is a powerful and flexible mechanism for interacting with other protocols, fully controlled by the DAO's voting process.
6.  **Self-Governance:** The `transferOwnershipToDAO` function signifies the transition where the DAO's own governance (`executeProposal`) is the only authorized caller for state-changing internal functions like `_changeParameter`, `_addMember`, `_sendETH`, etc. (Note: A production contract would need more robust access control than just relying on `executeProposal` being the *intended* caller).
7.  **Staking for Governance Boost:** The `stake` and `unstake` functions manage staked ETH, which is then incorporated into the `_getVotingWeight` calculation via the `PARAM_STAKE_VOTING_BOOST_FACTOR`.
8.  **Proposal Encoding/Decoding:** The `propose` function takes a `proposalType` and generic `bytes calldata data`. The `executeProposal` function uses `abi.decode` based on the `proposal.proposalType` to correctly interpret the data and call the appropriate internal function (`_changeParameter`, `_addMember`, `_sendETH`, etc.). This makes the proposal system extensible without needing a separate `proposeX` function for every action.

This contract provides a framework for a more complex and dynamic DAO than typical token-weighted governance models. Remember that this is an example for demonstration and would require further hardening, gas optimization for large member bases, and robust testing for production use.