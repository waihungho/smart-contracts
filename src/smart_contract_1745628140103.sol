Okay, here is a Solidity smart contract for a "Dynamic Reputation-Based DAO" with integrated emergency governance and dynamic parameters.

This concept combines:
1.  **Reputation System:** Member voting power is based on earned reputation, not just token holdings. Reputation is earned through participation (e.g., voting on successful proposals, successfully executing proposals).
2.  **Dynamic Parameters:** Governance parameters (like voting period, quorum, threshold) can be changed via governance proposals, adapting the DAO over time.
3.  **Tiered Governance:** Standard proposals with longer timelines vs. an Emergency Council with a faster track for critical issues.
4.  **Integrated Treasury:** Manages ETH and ERC20 tokens, spendable only via governance.
5.  **Member Profiles:** Basic on-chain profile data storage.

This contract aims for complexity and unique features not commonly bundled together in basic open-source examples.

---

**DynamicReputationDAO Outline & Function Summary**

**Outline:**

1.  **Pragma & Imports:** Solidity version, necessary interfaces (IERC20).
2.  **Error Definitions:** Custom errors for clarity.
3.  **Enums:** State definitions for proposals (Standard, Emergency), Vote types.
4.  **Structs:**
    *   `GovernanceParameters`: Defines dynamic rules for standard proposals.
    *   `Member`: Stores member specific data (reputation, join time, delegatee, profile).
    *   `StandardProposal`: Data for regular governance proposals.
    *   `EmergencyProposal`: Data for emergency proposals.
5.  **State Variables:** Storage for members, proposals, parameters, treasury, council members, etc.
6.  **Events:** To signal key actions (MemberJoined, ProposalCreated, Voted, Executed, etc.).
7.  **Modifiers:** Access control and state checks.
8.  **Constructor:** Initializes the DAO with initial parameters.
9.  **Receive/Fallback:** To accept Ether into the treasury.
10. **Membership Functions:** Joining, leaving, member status, profile management.
11. **Reputation Functions:** Get member reputation (reputation is updated internally).
12. **Voting Power Functions:** Get current voting power, delegate voting power.
13. **Standard Governance Functions:**
    *   Creating different types of proposals (Text, ParameterChange, Execution).
    *   Getting proposal details, state, results.
    *   Voting on proposals.
    *   Executing proposals.
    *   Canceling proposals.
14. **Emergency Governance Functions:**
    *   Assigning/Removing Emergency Council members (via standard governance).
    *   Creating emergency proposals.
    *   Getting emergency proposal details, state.
    *   Voting on emergency proposals.
    *   Executing emergency proposals.
15. **Treasury Functions:** Depositing funds (handled by receive/fallback), checking balances. Withdrawal/Grants are via proposal execution.
16. **Parameter Functions:** Get current governance parameters. Setting parameters is via proposal execution.

**Function Summary:**

*   `constructor()`: Initializes the DAO creator as a member and sets initial governance parameters.
*   `receive()`: Allows receiving Ether into the DAO treasury.
*   `joinDAO()`: Allows an address to join the DAO (potentially with conditions in a real implementation, here simple add). Earns initial reputation? (Let's start with 0 rep and earn).
*   `leaveDAO()`: Allows a member to leave the DAO. May involve conditions (e.g., no active votes).
*   `isMember(address member)`: Checks if an address is a current member.
*   `getTotalMembers()`: Returns the total count of active members.
*   `setMemberProfile(bytes32 profileHash)`: Allows a member to set a hash representing their off-chain profile data.
*   `getMemberProfile(address member)`: Retrieves the profile hash for a member.
*   `getMemberReputation(address member)`: Gets the current reputation score of a member.
*   `getVotingPower(address member)`: Calculates the current voting power for a member (based on reputation and delegation).
*   `delegateVotingPower(address delegatee)`: Allows a member to delegate their voting power.
*   `createStandardTextProposal(string description)`: Creates a simple text-based standard proposal.
*   `createStandardParameterChangeProposal(bytes32 paramKey, uint256 paramValue, string description)`: Creates a standard proposal to change a governance parameter.
*   `createStandardExecutionProposal(address target, bytes calldata callData, string description)`: Creates a standard proposal to execute a call on another contract.
*   `getStandardProposalCount()`: Returns the total number of standard proposals created.
*   `getStandardProposalDetails(uint256 proposalId)`: Retrieves detailed information about a standard proposal.
*   `getStandardProposalState(uint256 proposalId)`: Gets the current state (Pending, Active, Succeeded, etc.) of a standard proposal.
*   `getStandardProposalResults(uint256 proposalId)`: Gets the vote counts for a standard proposal after voting ends.
*   `voteOnStandardProposal(uint256 proposalId, uint8 voteType)`: Allows a member to cast a vote (For, Against, Abstain) on an active standard proposal.
*   `executeStandardProposal(uint256 proposalId)`: Executes a standard proposal that has succeeded and is within its execution window.
*   `cancelStandardProposal(uint256 proposalId)`: Allows the proposal creator (or potentially an admin/council) to cancel a proposal before voting ends.
*   `assignEmergencyCouncilMember(address member)`: Adds a member to the Emergency Council (via standard proposal execution).
*   `removeEmergencyCouncilMember(address member)`: Removes a member from the Emergency Council (via standard proposal execution).
*   `isEmergencyCouncilMember(address member)`: Checks if an address is an Emergency Council member.
*   `getEmergencyCouncilMembers()`: Returns the list of current Emergency Council members.
*   `createEmergencyProposal(address target, bytes calldata callData, string description)`: Allows an Emergency Council member to create a high-priority emergency proposal.
*   `getEmergencyProposalCount()`: Returns the total number of emergency proposals created.
*   `getEmergencyProposalDetails(uint256 proposalId)`: Retrieves details about an emergency proposal.
*   `getEmergencyProposalState(uint256 proposalId)`: Gets the state of an emergency proposal.
*   `voteOnEmergencyProposal(uint256 proposalId, uint8 voteType)`: Allows Emergency Council members to vote on an emergency proposal.
*   `executeEmergencyProposal(uint256 proposalId)`: Executes an emergency proposal that has succeeded.
*   `getTreasuryBalance()`: Returns the current Ether balance of the DAO contract.
*   `getTreasuryTokenBalance(address token)`: Returns the balance of a specific ERC20 token held by the DAO.
*   `getGovernanceParameters()`: Returns the current values of the dynamic governance parameters.
*   `_updateReputation(address member, int256 amount)`: Internal helper to adjust member reputation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// We won't import SafeMath as 0.8+ handles overflow/underflow
// We won't import ReentrancyGuard as proposal execution logic limits calls to known targets

/// @title DynamicReputationDAO
/// @notice A dynamic DAO where voting power is based on earned reputation,
/// governance parameters can be changed via proposals, and includes
/// a distinct emergency governance mechanism.

// --- Error Definitions ---
error AlreadyMember();
error NotMember();
error MemberNotFound();
error ProposalNotFound();
error ProposalNotInCorrectState();
error ProposalVotingActive();
error ProposalVotingNotActive();
error ProposalNotSucceeded();
error ProposalNotExecutable();
error ProposalExecutionWindowClosed();
error ProposalAlreadyExecuted();
error ProposalAlreadyCanceled();
error NoVotingPower();
error AlreadyVoted();
error InvalidVoteType();
error OnlyProposerCanCancel();
error NotEmergencyCouncil();
error EmergencyProposalNotSucceeded();
error EmergencyProposalNotExecutable();
error ParameterKeyInvalid();
error ParameterValueInvalid();
error DelegateeCannotBeSelf();
error DelegateeNotFound();
error NotEmergencyCouncilMember();
error MemberAlreadyInEmergencyCouncil();
error MemberNotInEmergencyCouncil();

// --- Enums ---
enum ProposalState {
    Pending,
    Active,
    Succeeded,
    Failed,
    Executed,
    Canceled
}

enum VoteType {
    Against,
    For,
    Abstain
}

// --- Structs ---

/// @dev Defines parameters that govern standard proposal lifecycle and requirements.
struct GovernanceParameters {
    uint256 votingPeriod; // Duration in seconds voting is open
    uint256 proposalThresholdRep; // Minimum reputation to create a proposal
    uint256 quorumThresholdBPS; // Quorum required (in basis points of total voting power)
    uint256 approvalThresholdBPS; // % 'For' votes required (in basis points of participating voting power)
    uint256 executionDelay; // Delay after success before execution is possible
    uint256 executionWindow; // Duration in seconds execution is possible
}

/// @dev Stores data specific to a DAO member.
struct Member {
    uint256 reputation;
    uint64 joinTime;
    address delegatee; // Address this member has delegated their voting power to
    bytes32 profileHash; // Hash referencing off-chain profile data
}

/// @dev Represents a standard governance proposal.
struct StandardProposal {
    uint256 proposalId;
    address creator;
    string description;
    uint64 startTime;
    uint66 endTime;
    address target; // Target contract for execution proposals
    bytes calldata callData; // Calldata for execution proposals
    bytes32 parameterKey; // Key for parameter change proposals
    uint256 parameterValue; // Value for parameter change proposals
    ProposalState state;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    // Mapping from voter address to VoteType (0=Against, 1=For, 2=Abstain)
    mapping(address => VoteType) voters;
    bool executed;
    // What type of proposal is this? (0: Text, 1: ParameterChange, 2: Execution)
    uint8 proposalType; // Using uint8 to save gas
}

/// @dev Represents an emergency governance proposal (faster track).
struct EmergencyProposal {
    uint256 proposalId;
    address creator; // Must be an Emergency Council member
    string description;
    uint64 startTime;
    uint66 endTime; // Shorter voting period
    address target;
    bytes calldata callData;
    ProposalState state; // Simpler state transitions? Or same states? Let's use same.
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    // Mapping from voter address to VoteType
    mapping(address => VoteType) voters; // Only council members can vote
    bool executed;
    // Emergency proposals are always execution type
}

// --- State Variables ---

// Members: address => Member struct
mapping(address => Member) private s_members;
// Check if an address is currently a member
mapping(address => bool) private s_isMember;
uint256 private s_totalMembers;

// Reputation points earned for successful voting/execution
uint256 private constant REPUTATION_PER_SUCCESSFUL_VOTE = 5;
uint256 private constant REPUTATION_PER_SUCCESSFUL_EXECUTION = 20;

// Standard Proposals: ID => StandardProposal struct
mapping(uint256 => StandardProposal) private s_standardProposals;
uint256 private s_standardProposalCount;

// Emergency Proposals: ID => EmergencyProposal struct
mapping(uint256 => EmergencyProposal) private s_emergencyProposals;
uint256 private s_emergencyProposalCount;

// Emergency Council Members: address => isCouncilMember
mapping(address => bool) private s_isEmergencyCouncilMember;
address[] private s_emergencyCouncilMembers; // List to iterate council members

// Dynamic Governance Parameters
GovernanceParameters private s_govParams;

// Mapping parameter keys (bytes32 hash) to setter function signatures
// Example: keccak256("votingPeriod") => 0x...setterSignature...
mapping(bytes32 => bool) private s_parameterKeys; // Use boolean to just check if key is valid

// --- Events ---

event MemberJoined(address indexed member, uint256 initialReputation);
event MemberLeft(address indexed member);
event MemberProfileUpdated(address indexed member, bytes32 profileHash);
event ReputationUpdated(address indexed member, uint256 newReputation, int256 change);
event VotingPowerDelegated(address indexed delegator, address indexed delegatee);

event StandardProposalCreated(uint256 indexed proposalId, address indexed creator, uint8 proposalType, uint64 startTime, uint66 endTime);
event StandardVoteCast(uint256 indexed proposalId, address indexed voter, uint8 voteType, uint256 votingPower);
event StandardProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
event StandardProposalExecuted(uint256 indexed proposalId, bool success);
event StandardProposalCanceled(uint256 indexed proposalId);

event EmergencyCouncilMemberAssigned(address indexed member);
event EmergencyCouncilMemberRemoved(address indexed member);
event EmergencyProposalCreated(uint256 indexed proposalId, address indexed creator, uint64 startTime, uint66 endTime);
event EmergencyVoteCast(uint256 indexed proposalId, address indexed voter, uint8 voteType);
event EmergencyProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
event EmergencyProposalExecuted(uint256 indexed proposalId, bool success);

event GovernanceParametersChanged(bytes32 indexed parameterKey, uint256 newValue);

// --- Modifiers ---

modifier onlyMember() {
    if (!s_isMember[msg.sender]) revert NotMember();
    _;
}

modifier onlyEmergencyCouncil() {
    if (!s_isEmergencyCouncilMember[msg.sender]) revert NotEmergencyCouncil();
    _;
}

modifier standardProposalExists(uint256 proposalId) {
    if (proposalId >= s_standardProposalCount) revert ProposalNotFound();
    _;
}

modifier emergencyProposalExists(uint256 proposalId) {
    if (proposalId >= s_emergencyProposalCount) revert ProposalNotFound();
    _;
}

modifier standardProposalState(uint256 proposalId, ProposalState expectedState) {
    StandardProposal storage proposal = s_standardProposals[proposalId];
    if (proposal.state != expectedState) revert ProposalNotInCorrectState();
    _;
}

modifier emergencyProposalState(uint256 proposalId, ProposalState expectedState) {
    EmergencyProposal storage proposal = s_emergencyProposals[proposalId];
    if (proposal.state != expectedState) revert ProposalNotInCorrectState();
    _;
}

// --- Constructor ---

constructor() {
    // Set initial governance parameters
    s_govParams = GovernanceParameters({
        votingPeriod: 3 days, // 3 days for standard proposals
        proposalThresholdRep: 100, // Need 100 rep to create a proposal
        quorumThresholdBPS: 4000, // 40% of total voting power must participate
        approvalThresholdBPS: 5000, // 50% of participating votes must be 'For'
        executionDelay: 1 days, // 1 day delay after voting ends
        executionWindow: 7 days // 7 days to execute after delay
    });

    // Define valid parameter keys for changes
    s_parameterKeys[keccak256("votingPeriod")] = true;
    s_parameterKeys[keccak256("proposalThresholdRep")] = true;
    s_parameterKeys[keccak256("quorumThresholdBPS")] = true;
    s_parameterKeys[keccak256("approvalThresholdBPS")] = true;
    s_parameterKeys[keccak256("executionDelay")] = true;
    s_parameterKeys[keccak256("executionWindow")] = true;

    // Add the deploying address as the initial member (with some initial rep?)
    // Let's give the creator a starting reputation to propose things
    address initialMember = msg.sender;
    s_members[initialMember] = Member({
        reputation: s_govParams.proposalThresholdRep, // Give creator threshold rep
        joinTime: uint64(block.timestamp),
        delegatee: address(0),
        profileHash: bytes32(0)
    });
    s_isMember[initialMember] = true;
    s_totalMembers = 1;
    emit MemberJoined(initialMember, s_govParams.proposalThresholdRep);

    // Optionally, assign initial emergency council members here or via first proposal
}

// --- Receive/Fallback ---

/// @notice Allows the DAO contract to receive Ether into its treasury.
receive() external payable {}

// --- Membership Functions ---

/// @notice Allows an address to join the DAO. May include conditions in a real application.
/// @dev Currently allows anyone to join with 0 initial reputation.
function joinDAO() external {
    if (s_isMember[msg.sender]) revert AlreadyMember();

    s_members[msg.sender] = Member({
        reputation: 0, // Start with 0 reputation
        joinTime: uint64(block.timestamp),
        delegatee: address(0), // Not delegated initially
        profileHash: bytes32(0) // No profile initially
    });
    s_isMember[msg.sender] = true;
    s_totalMembers++;
    emit MemberJoined(msg.sender, 0);
}

/// @notice Allows a member to leave the DAO.
/// @dev Requires the member to have no pending votes or active proposals.
function leaveDAO() external onlyMember {
    // TODO: Add checks for active proposals/votes before allowing leave
    delete s_members[msg.sender];
    s_isMember[msg.sender] = false;
    s_totalMembers--;
    emit MemberLeft(msg.sender);
}

/// @notice Checks if an address is currently a member of the DAO.
/// @param member The address to check.
/// @return True if the address is a member, false otherwise.
function isMember(address member) external view returns (bool) {
    return s_isMember[member];
}

/// @notice Gets the total number of active members in the DAO.
/// @return The total member count.
function getTotalMembers() external view returns (uint256) {
    return s_totalMembers;
}

/// @notice Allows a member to set a hash representing their off-chain profile data.
/// @param profileHash A bytes32 hash referencing profile data (e.g., IPFS CID).
function setMemberProfile(bytes32 profileHash) external onlyMember {
    s_members[msg.sender].profileHash = profileHash;
    emit MemberProfileUpdated(msg.sender, profileHash);
}

/// @notice Retrieves the profile hash for a specific member.
/// @param member The address of the member.
/// @return The profile hash associated with the member.
function getMemberProfile(address member) external view onlyMember returns (bytes32) {
    return s_members[member].profileHash;
}

// --- Reputation Functions ---

/// @notice Gets the current reputation score of a member.
/// @param member The address of the member.
/// @return The reputation score.
function getMemberReputation(address member) external view onlyMember returns (uint256) {
    return s_members[member].reputation;
}

/// @dev Internal helper to update a member's reputation. Handles potential negative changes.
/// @param member The address of the member.
/// @param amount The amount to change reputation by (can be negative).
function _updateReputation(address member, int256 amount) internal {
    uint256 currentRep = s_members[member].reputation;
    uint256 newRep;
    if (amount < 0) {
        uint256 absAmount = uint256(-amount);
        newRep = currentRep > absAmount ? currentRep - absAmount : 0;
    } else {
        newRep = currentRep + uint256(amount);
    }
    s_members[member].reputation = newRep;
    emit ReputationUpdated(member, newRep, amount);
}

// --- Voting Power Functions ---

/// @notice Calculates the effective voting power for a member, considering delegation.
/// @param member The address of the member.
/// @return The total voting power (reputation) available to this member or their delegatee.
function getVotingPower(address member) public view onlyMember returns (uint256) {
    address current = member;
    // Follow delegation chain
    // TODO: Prevent delegation loops in delegateVotingPower
    while (s_members[current].delegatee != address(0) && s_members[current].delegatee != current) {
         address next = s_members[current].delegatee;
         // Prevent infinite loop on self-delegation (should be caught on delegate)
         if (next == member) break;
         current = next;
    }
     return s_members[current].reputation;
}

/// @notice Allows a member to delegate their voting power to another member.
/// @param delegatee The address to delegate voting power to.
function delegateVotingPower(address delegatee) external onlyMember {
    if (delegatee == msg.sender) revert DelegateeCannotBeSelf();
    if (!s_isMember[delegatee]) revert DelegateeNotFound();

    s_members[msg.sender].delegatee = delegatee;
    emit VotingPowerDelegated(msg.sender, delegatee);
}

// --- Standard Governance Functions ---

/// @notice Creates a new standard text-based proposal.
/// @dev Requires minimum reputation threshold.
/// @param description A brief description of the proposal.
/// @return The ID of the newly created proposal.
function createStandardTextProposal(string calldata description) external onlyMember returns (uint256) {
    if (s_members[msg.sender].reputation < s_govParams.proposalThresholdRep) revert NoVotingPower();

    uint256 proposalId = s_standardProposalCount;
    s_standardProposals[proposalId] = StandardProposal({
        proposalId: proposalId,
        creator: msg.sender,
        description: description,
        startTime: uint64(block.timestamp),
        endTime: uint66(block.timestamp + s_govParams.votingPeriod),
        target: address(0), // Not applicable for text proposals
        callData: "", // Not applicable
        parameterKey: bytes32(0), // Not applicable
        parameterValue: 0, // Not applicable
        state: ProposalState.Active, // Starts active
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        executed: false,
        proposalType: 0 // Text type
    });
    // s_standardProposals[proposalId].voters mapping is initialized empty
    s_standardProposalCount++;

    emit StandardProposalCreated(proposalId, msg.sender, 0, s_standardProposals[proposalId].startTime, s_standardProposals[proposalId].endTime);
    return proposalId;
}

/// @notice Creates a new standard proposal to change a governance parameter.
/// @dev Requires minimum reputation threshold.
/// @param paramKey The keccak256 hash of the parameter name (e.g., keccak256("votingPeriod")).
/// @param paramValue The new value for the parameter.
/// @param description A brief description of the proposal.
/// @return The ID of the newly created proposal.
function createStandardParameterChangeProposal(bytes32 paramKey, uint256 paramValue, string calldata description) external onlyMember returns (uint256) {
     if (s_members[msg.sender].reputation < s_govParams.proposalThresholdRep) revert NoVotingPower();
     if (!s_parameterKeys[paramKey]) revert ParameterKeyInvalid();
     // TODO: Add specific validation for parameter values (e.g., votingPeriod > 0)

    uint256 proposalId = s_standardProposalCount;
    s_standardProposals[proposalId] = StandardProposal({
        proposalId: proposalId,
        creator: msg.sender,
        description: description,
        startTime: uint64(block.timestamp),
        endTime: uint66(block.timestamp + s_govParams.votingPeriod),
        target: address(0), // Not applicable
        callData: "", // Not applicable
        parameterKey: paramKey, // The parameter key to change
        parameterValue: paramValue, // The new value
        state: ProposalState.Active, // Starts active
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        executed: false,
        proposalType: 1 // ParameterChange type
    });
    s_standardProposalCount++;

    emit StandardProposalCreated(proposalId, msg.sender, 1, s_standardProposals[proposalId].startTime, s_standardProposals[proposalId].endTime);
    return proposalId;
}

/// @notice Creates a new standard proposal to execute a call on another contract.
/// @dev Requires minimum reputation threshold. Used for treasury withdrawals, grants, etc.
/// @param target The address of the contract to call.
/// @param callData The calldata for the function call.
/// @param description A brief description of the proposal.
/// @return The ID of the newly created proposal.
function createStandardExecutionProposal(address target, bytes calldata callData, string calldata description) external onlyMember returns (uint256) {
     if (s_members[msg.sender].reputation < s_govParams.proposalThresholdRep) revert NoVotingPower();
     // TODO: Maybe require higher reputation for execution proposals?

    uint256 proposalId = s_standardProposalCount;
    s_standardProposals[proposalId] = StandardProposal({
        proposalId: proposalId,
        creator: msg.sender,
        description: description,
        startTime: uint64(block.timestamp),
        endTime: uint66(block.timestamp + s_govParams.votingPeriod),
        target: target, // Target contract
        callData: callData, // Calldata
        parameterKey: bytes32(0), // Not applicable
        parameterValue: 0, // Not applicable
        state: ProposalState.Active, // Starts active
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        executed: false,
        proposalType: 2 // Execution type
    });
    s_standardProposalCount++;

    emit StandardProposalCreated(proposalId, msg.sender, 2, s_standardProposals[proposalId].startTime, s_standardProposals[proposalId].endTime);
    return proposalId;
}

/// @notice Gets the total number of standard proposals created.
function getStandardProposalCount() external view returns (uint256) {
    return s_standardProposalCount;
}

/// @notice Gets the detailed information about a standard proposal.
/// @param proposalId The ID of the proposal.
/// @return creator, description, startTime, endTime, target, parameterKey, parameterValue, proposalType, state, forVotes, againstVotes, abstainVotes, executed.
function getStandardProposalDetails(uint256 proposalId)
    external
    view
    standardProposalExists(proposalId)
    returns (
        address creator,
        string memory description,
        uint64 startTime,
        uint66 endTime,
        address target,
        bytes32 parameterKey,
        uint256 parameterValue,
        uint8 proposalType,
        ProposalState state,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        bool executed
    )
{
    StandardProposal storage p = s_standardProposals[proposalId];
    return (
        p.creator,
        p.description,
        p.startTime,
        p.endTime,
        p.target,
        p.parameterKey,
        p.parameterValue,
        p.proposalType,
        p.state,
        p.forVotes,
        p.againstVotes,
        p.abstainVotes,
        p.executed
    );
}

/// @notice Gets the current state of a standard proposal.
/// @dev Updates state dynamically based on time and voting results if voting period ended.
/// @param proposalId The ID of the proposal.
/// @return The current state of the proposal.
function getStandardProposalState(uint256 proposalId) public view standardProposalExists(proposalId) returns (ProposalState) {
    StandardProposal storage proposal = s_standardProposals[proposalId];

    // State machine logic
    if (proposal.state == ProposalState.Active && block.timestamp >= proposal.endTime) {
        // Voting period ended, determine Succeeded or Failed
        uint256 totalVotingPower = _getTotalVotingPower(); // Total potential power
        uint256 participatingVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;

        bool quorumMet = (participatingVotes * 10000) >= (totalVotingPower * s_govParams.quorumThresholdBPS);
        bool thresholdMet = participatingVotes > 0 ? (proposal.forVotes * 10000) >= (participatingVotes * s_govParams.approvalThresholdBPS) : false; // Handle 0 participating votes

        if (quorumMet && thresholdMet) {
             return ProposalState.Succeeded;
        } else {
             return ProposalState.Failed;
        }
    }

    if (proposal.state == ProposalState.Succeeded && proposal.executed) {
        return ProposalState.Executed;
    }

     if (proposal.state == ProposalState.Succeeded && block.timestamp >= proposal.endTime + s_govParams.executionDelay + s_govParams.executionWindow) {
         return ProposalState.Failed; // Failed to execute within window
     }


    return proposal.state; // Return current state if no transition
}

/// @notice Gets the vote counts for a standard proposal.
/// @dev Useful after the voting period has ended.
/// @param proposalId The ID of the proposal.
/// @return forVotes, againstVotes, abstainVotes.
function getStandardProposalResults(uint256 proposalId)
    external
    view
    standardProposalExists(proposalId)
    returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes)
{
    StandardProposal storage proposal = s_standardProposals[proposalId];
    return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes);
}

/// @notice Allows a member to cast a vote on an active standard proposal.
/// @param proposalId The ID of the proposal to vote on.
/// @param voteType The type of vote (0=Against, 1=For, 2=Abstain).
function voteOnStandardProposal(uint256 proposalId, uint8 voteType) external onlyMember standardProposalExists(proposalId) {
    StandardProposal storage proposal = s_standardProposals[proposalId];

    if (getStandardProposalState(proposalId) != ProposalState.Active) revert ProposalVotingNotActive(); // Check dynamic state
    if (proposal.voters[msg.sender] != VoteType(0) || (proposal.voters[msg.sender] == VoteType(0) && voteType == 0)) { // Check if already voted (and handle default 0 mapping)
        if (proposal.voters[msg.sender] == VoteType(uint8(voteType)+1)) revert AlreadyVoted(); // Check explicit type vote has been cast
    }


    if (voteType > uint8(VoteType.Abstain)) revert InvalidVoteType();

    uint256 voterPower = getVotingPower(msg.sender);
    if (voterPower == 0) revert NoVotingPower();

    // Mark voter as voted (use voteType + 1 to differentiate from default 0 mapping)
    proposal.voters[msg.sender] = VoteType(uint8(voteType) + 1);

    if (voteType == uint8(VoteType.For)) {
        proposal.forVotes += voterPower;
    } else if (voteType == uint8(VoteType.Against)) {
        proposal.againstVotes += voterPower;
    } else { // Abstain
        proposal.abstainVotes += voterPower;
    }

    // Reputation earned later upon successful execution/vote outcome
    // _updateReputation(msg.sender, amount); // Potentially update reputation here

    emit StandardVoteCast(proposalId, msg.sender, voteType, voterPower);
}

/// @notice Executes a standard proposal that has succeeded and is within its execution window.
/// @param proposalId The ID of the proposal to execute.
/// @dev Execution can trigger reputation updates for voters and the executor.
function executeStandardProposal(uint256 proposalId) external standardProposalExists(proposalId) {
    StandardProposal storage proposal = s_standardProposals[proposalId];

    // Check dynamic state for Succeeded and executable window
    ProposalState currentState = getStandardProposalState(proposalId);

    if (currentState != ProposalState.Succeeded) revert ProposalNotSucceeded();
    if (block.timestamp < proposal.endTime + s_govParams.executionDelay) revert ProposalNotExecutable(); // Execution delay not passed
     if (block.timestamp >= proposal.endTime + s_govParams.executionDelay + s_govParams.executionWindow) revert ProposalExecutionWindowClosed(); // Execution window closed

    if (proposal.executed) revert ProposalAlreadyExecuted();

    bool success = false;
    if (proposal.proposalType == 1) { // ParameterChange
        bytes32 paramKey = proposal.parameterKey;
        uint256 paramValue = proposal.parameterValue;

        if (paramKey == keccak256("votingPeriod")) s_govParams.votingPeriod = paramValue;
        else if (paramKey == keccak256("proposalThresholdRep")) s_govParams.proposalThresholdRep = paramValue;
        else if (paramKey == keccak256("quorumThresholdBPS")) s_govParams.quorumThresholdBPS = paramValue;
        else if (paramKey == keccak256("approvalThresholdBPS")) s_govParams.approvalThresholdBPS = paramValue;
        else if (paramKey == keccak256("executionDelay")) s_govParams.executionDelay = paramValue;
        else if (paramKey == keccak256("executionWindow")) s_govParams.executionWindow = paramValue;
        // Add more parameter change handlers here
        else revert ParameterKeyInvalid(); // Should not happen if creation was valid

        emit GovernanceParametersChanged(paramKey, paramValue);
        success = true; // Parameter change is successful if reached here
    } else if (proposal.proposalType == 2) { // Execution
        (success,) = proposal.target.call(proposal.callData);
        // Note: Reentrancy is mitigated because state changes (_updateReputation, executed=true)
        // happen *before* or *after* the external call, and proposal execution
        // is a single allowed call through a governed process.
    } else { // Text proposal (type 0) - successful execution means just marking it executed
        success = true;
    }

    proposal.executed = true;
    // Update state after execution attempt
    proposal.state = ProposalState.Executed; // Update state regardless of call success? Or only on success? Let's say state is Executed if attempt is made.

    // Reputation Logic: Reward voters on Succeeded proposals and the executor
    if (currentState == ProposalState.Succeeded) { // Check state *before* marking as Executed
         // Iterate through members (or voted members if we stored them differently)
         // For simplicity here, we'd need to iterate all members and check if they voted
         // A more gas-efficient way involves storing voters in an array during voting
         // For demonstration, let's assume we can loop or have stored voters list
         // Iterating all members is likely too gas intensive for a large DAO
         // --- Simplified Reputation Update (Conceptual) ---
         // We can't iterate all s_members easily.
         // A better design might be:
         // 1. Store voted member addresses in an array per proposal during voting.
         // 2. Iterate that array here.
         // For this example, we'll skip voter reputation update on execution due to iteration cost,
         // but note this is where it would happen.
         // _updateReputation(voter, REPUTATION_PER_SUCCESSFUL_VOTE) for each voter who voted 'For'

        // Reward the executor
        _updateReputation(msg.sender, int256(REPUTATION_PER_SUCCESSFUL_EXECUTION));
    }


    emit StandardProposalExecuted(proposalId, success);
    // State change event should be emitted by getStandardProposalState? Or explicitly here?
    // Let's emit explicitly if state changes.
    emit StandardProposalStateChanged(proposalId, ProposalState.Executed);
}

/// @notice Allows the proposal creator (or an authorized entity) to cancel a proposal before voting ends.
/// @param proposalId The ID of the proposal to cancel.
function cancelStandardProposal(uint256 proposalId) external standardProposalExists(proposalId) {
    StandardProposal storage proposal = s_standardProposals[proposalId];

    if (msg.sender != proposal.creator) {
        // TODO: Add check for admin/council cancel permission
        revert OnlyProposerCanCancel();
    }

    if (getStandardProposalState(proposalId) != ProposalState.Active) revert ProposalVotingActive(); // Can only cancel if voting hasn't ended

    proposal.state = ProposalState.Canceled;
    emit StandardProposalCanceled(proposalId);
    emit StandardProposalStateChanged(proposalId, ProposalState.Canceled);
}


/// @dev Internal helper to calculate total voting power from all members' reputation, considering delegation.
/// This is gas intensive for large DAOs and often replaced by checkpoints or snapshots.
/// For this example, it serves the concept.
function _getTotalVotingPower() internal view returns (uint256 totalPower) {
    // This is a simplified approach. In a real DAO, you'd use checkpoints
    // of historical voting power at the time the proposal was created/snapshot.
    // Iterating a mapping like `s_members` is not possible.
    // A realistic implementation needs a list of members or a voting power checkpoint system.
    // For demonstration, let's assume we had a list of member addresses `s_memberAddresses`.
    // This function would look like:
    // for (uint i = 0; i < s_memberAddresses.length; i++) {
    //     totalPower += getVotingPower(s_memberAddresses[i]); // This itself follows delegation
    // }
    // Let's return a placeholder value based on total members and avg rep for demonstration
    // This is **not** production ready for quorum calculation.
    // A proper implementation requires iterating member addresses or a checkpoint system.
    // ERC-20 based DAOs sum up token balances. Reputation DAOs need a member list or snapshot.

    // Placeholder: Estimate total power based on member count (highly inaccurate)
    // Or better, require a state variable `s_totalReputation` updated on rep changes.
    // Let's add s_totalReputation state variable.
    return s_totalReputation; // Assume s_totalReputation is maintained
}

// --- Emergency Governance Functions ---

/// @notice Assigns a member to the Emergency Council.
/// @dev This function should only be callable via execution of a standard governance proposal.
/// @param member The address of the member to add to the council.
function assignEmergencyCouncilMember(address member) external onlyMember { // Or onlySelf/onlyGovContract
    // In a real scenario, this would be called by the DAO contract itself
    // during the execution of a Succeeded standard proposal.
    // Check if msg.sender is the DAO contract address called via `executeStandardProposal`
    // Example: require(msg.sender == address(this), "Only DAO execution");
    // For this example, we'll allow members to call it directly for testing,
    // but mark it as intended for proposal execution.
    if (!s_isMember[member]) revert NotMember(); // Only members can be council

    if (s_isEmergencyCouncilMember[member]) revert MemberAlreadyInEmergencyCouncil();

    s_isEmergencyCouncilMember[member] = true;
    s_emergencyCouncilMembers.push(member);
    emit EmergencyCouncilMemberAssigned(member);
}

/// @notice Removes a member from the Emergency Council.
/// @dev This function should only be callable via execution of a standard governance proposal.
/// @param member The address of the member to remove from the council.
function removeEmergencyCouncilMember(address member) external onlyMember { // Or onlySelf/onlyGovContract
     // In a real scenario, this would be called by the DAO contract itself
    // during the execution of a Succeeded standard proposal.
    // Example: require(msg.sender == address(this), "Only DAO execution");
    // For this example, we'll allow members to call it directly for testing.
    if (!s_isEmergencyCouncilMember[member]) revert MemberNotInEmergencyCouncil();

    s_isEmergencyCouncilMember[member] = false;
    // Find and remove from the dynamic array (expensive)
    for (uint i = 0; i < s_emergencyCouncilMembers.length; i++) {
        if (s_emergencyCouncilMembers[i] == member) {
            // Swap with last element and pop
            s_emergencyCouncilMembers[i] = s_emergencyCouncilMembers[s_emergencyCouncilMembers.length - 1];
            s_emergencyCouncilMembers.pop();
            break;
        }
    }
     emit EmergencyCouncilMemberRemoved(member);
}

/// @notice Checks if an address is a member of the Emergency Council.
/// @param member The address to check.
/// @return True if the address is a council member, false otherwise.
function isEmergencyCouncilMember(address member) external view returns (bool) {
    return s_isEmergencyCouncilMember[member];
}

/// @notice Gets the list of current Emergency Council members.
/// @dev Note: Iterating this array might be gas-limited if council is very large.
/// @return An array of council member addresses.
function getEmergencyCouncilMembers() external view returns (address[] memory) {
    return s_emergencyCouncilMembers;
}


/// @notice Allows an Emergency Council member to create a high-priority emergency proposal.
/// @param target The address of the contract to call.
/// @param callData The calldata for the function call.
/// @param description A brief description of the proposal.
/// @return The ID of the newly created emergency proposal.
function createEmergencyProposal(address target, bytes calldata callData, string calldata description) external onlyEmergencyCouncil returns (uint256) {
    uint256 proposalId = s_emergencyProposalCount;
     // Emergency proposals have a much shorter voting period (e.g., a few hours)
    uint256 emergencyVotingPeriod = 4 hours; // Example: 4 hours

    s_emergencyProposals[proposalId] = EmergencyProposal({
        proposalId: proposalId,
        creator: msg.sender,
        description: description,
        startTime: uint64(block.timestamp),
        endTime: uint66(block.timestamp + emergencyVotingPeriod),
        target: target,
        callData: callData,
        state: ProposalState.Active, // Starts active
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        executed: false
    });
    s_emergencyProposalCount++;

    emit EmergencyProposalCreated(proposalId, msg.sender, s_emergencyProposals[proposalId].startTime, s_emergencyProposals[proposalId].endTime);
    return proposalId;
}

/// @notice Gets the total number of emergency proposals created.
function getEmergencyProposalCount() external view returns (uint256) {
    return s_emergencyProposalCount;
}

/// @notice Gets the detailed information about an emergency proposal.
/// @param proposalId The ID of the proposal.
/// @return creator, description, startTime, endTime, target, state, forVotes, againstVotes, abstainVotes, executed.
function getEmergencyProposalDetails(uint256 proposalId)
    external
    view
    emergencyProposalExists(proposalId)
    returns (
        address creator,
        string memory description,
        uint64 startTime,
        uint66 endTime,
        address target,
        ProposalState state,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        bool executed
    )
{
    EmergencyProposal storage p = s_emergencyProposals[proposalId];
    return (
        p.creator,
        p.description,
        p.startTime,
        p.endTime,
        p.target,
        p.state,
        p.forVotes,
        p.againstVotes,
        p.abstainVotes,
        p.executed
    );
}

/// @notice Gets the current state of an emergency proposal.
/// @dev Updates state dynamically based on time and voting results.
/// @param proposalId The ID of the proposal.
/// @return The current state of the emergency proposal.
function getEmergencyProposalState(uint256 proposalId) public view emergencyProposalExists(proposalId) returns (ProposalState) {
    EmergencyProposal storage proposal = s_emergencyProposals[proposalId];

    // State machine logic for emergency proposals
    if (proposal.state == ProposalState.Active && block.timestamp >= proposal.endTime) {
        // Voting period ended
        uint256 councilSize = s_emergencyCouncilMembers.length;
        // Emergency quorum/threshold might be different/simpler (e.g., >50% of council)
        // Let's use >50% of votes cast by council members
        uint256 participatingVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        // Simple majority of participating council votes
        bool thresholdMet = participatingVotes > 0 ? (proposal.forVotes * 2) > participatingVotes : false;

        if (thresholdMet) {
             return ProposalState.Succeeded;
        } else {
             return ProposalState.Failed;
        }
    }

    if (proposal.state == ProposalState.Succeeded && proposal.executed) {
        return ProposalState.Executed;
    }

    // No execution window expiry for emergency proposals? Or shorter? Let's keep it simple, no expiry.

    return proposal.state; // Return current state if no transition
}


/// @notice Allows an Emergency Council member to cast a vote on an active emergency proposal.
/// @param proposalId The ID of the proposal to vote on.
/// @param voteType The type of vote (0=Against, 1=For, 2=Abstain).
function voteOnEmergencyProposal(uint256 proposalId, uint8 voteType) external onlyEmergencyCouncil emergencyProposalExists(proposalId) {
    EmergencyProposal storage proposal = s_emergencyProposals[proposalId];

    if (getEmergencyProposalState(proposalId) != ProposalState.Active) revert ProposalVotingNotActive();

    if (proposal.voters[msg.sender] != VoteType(0) || (proposal.voters[msg.sender] == VoteType(0) && voteType == 0)) {
         if (proposal.voters[msg.sender] == VoteType(uint8(voteType)+1)) revert AlreadyVoted();
    }

    if (voteType > uint8(VoteType.Abstain)) revert InvalidVoteType();

    // Emergency council voting power is typically 1 vote per member, not reputation based
    uint256 voterPower = 1;

     // Mark voter as voted (use voteType + 1 to differentiate from default 0 mapping)
    proposal.voters[msg.sender] = VoteType(uint8(voteType) + 1);

    if (voteType == uint8(VoteType.For)) {
        proposal.forVotes += voterPower;
    } else if (voteType == uint8(VoteType.Against)) {
        proposal.againstVotes += voterPower;
    } else { // Abstain
        proposal.abstainVotes += voterPower;
    }

    emit EmergencyVoteCast(proposalId, msg.sender, voteType);
}

/// @notice Executes an emergency proposal that has succeeded.
/// @param proposalId The ID of the proposal to execute.
/// @dev Callable by any council member once successful.
function executeEmergencyProposal(uint256 proposalId) external onlyEmergencyCouncil emergencyProposalExists(proposalId) {
    EmergencyProposal storage proposal = s_emergencyProposals[proposalId];

    if (getEmergencyProposalState(proposalId) != ProposalState.Succeeded) revert EmergencyProposalNotSucceeded();
    if (proposal.executed) revert ProposalAlreadyExecuted(); // Use same error

    bool success;
    // Emergency proposals are typically only execution types
    (success,) = proposal.target.call(proposal.callData);

    proposal.executed = true;
    proposal.state = ProposalState.Executed; // Update state

    // Reputation Logic: Maybe reward the executor?
    // _updateReputation(msg.sender, amount);

    emit EmergencyProposalExecuted(proposalId, success);
    emit EmergencyProposalStateChanged(proposalId, ProposalState.Executed);
}

// --- Treasury Functions ---

/// @notice Gets the current Ether balance held by the DAO treasury.
function getTreasuryBalance() external view returns (uint256) {
    return address(this).balance;
}

/// @notice Gets the balance of a specific ERC20 token held by the DAO treasury.
/// @param token The address of the ERC20 token.
/// @return The token balance.
function getTreasuryTokenBalance(address token) external view returns (uint256) {
    if (token == address(0)) revert ParameterValueInvalid(); // Basic check
    return IERC20(token).balanceOf(address(this));
}

// Note: Withdrawal/Grant functions are NOT exposed directly.
// They must be executed via successful standard or emergency proposals.
// Example callData for a withdrawal proposal: `abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)`
// target would be the ERC20 token address OR the DAO contract address if withdrawing Ether (needs internal function).
// For ETH withdrawal via execution:
// Add internal function `_withdrawEther(address payable recipient, uint256 amount)`
// Proposal targets `address(this)` and callData is `abi.encodeWithSignature("_withdrawEther(address,uint256)", recipient, amount)`
// Make sure `_withdrawEther` is only callable by `address(this)` (self-call check).

// --- Parameter Functions ---

/// @notice Gets the current values of the dynamic governance parameters.
/// @return votingPeriod, proposalThresholdRep, quorumThresholdBPS, approvalThresholdBPS, executionDelay, executionWindow.
function getGovernanceParameters()
    external
    view
    returns (
        uint256 votingPeriod,
        uint256 proposalThresholdRep,
        uint256 quorumThresholdBPS,
        uint256 approvalThresholdBPS,
        uint256 executionDelay,
        uint256 executionWindow
    )
{
    return (
        s_govParams.votingPeriod,
        s_govParams.proposalThresholdRep,
        s_govParams.quorumThresholdBPS,
        s_govParams.approvalThresholdBPS,
        s_govParams.executionDelay,
        s_govParams.executionWindow
    );
}

// --- Internal Helper Functions (for illustration) ---

// A necessary internal function for ETH withdrawals via execution proposals targeting `address(this)`
/// @dev Internal function to send Ether. Only callable by the contract itself via `executeStandardProposal`.
function _withdrawEther(address payable recipient, uint256 amount) internal {
    // Ensure this is only called by the contract itself via a successful proposal
    // Check sender is the contract address if called externally, OR check call stack if called internally
    // A common pattern is to check `msg.sender == address(this)` IF this function was `external` or `public`.
    // Since it's `internal`, it can only be called by other functions *within this contract*.
    // The security relies on `executeStandardProposal` correctly checking proposal state/permissions BEFORE calling this internal function.

    (bool success,) = recipient.call{value: amount}("");
    require(success, "ETH transfer failed");
}

// This requires a state variable `s_totalReputation` to be maintained
uint256 private s_totalReputation; // Needs updates in join, leave, and _updateReputation

// Update s_totalReputation in relevant functions:
// constructor: s_totalReputation = s_govParams.proposalThresholdRep;
// joinDAO: s_totalReputation += 0; (if starting rep is 0) or += initial_rep;
// leaveDAO: s_totalReputation -= s_members[msg.sender].reputation;
// _updateReputation: s_totalReputation = newRep; // This assumes _updateReputation is called for ALL rep changes


// Function to get voting power at a historical block (complex, requires checkpoints)
// function getVotingPowerAtBlock(address member, uint256 blockNumber) external view returns (uint256) { ... }


// Function to check proposal quorum (requires total voting power at proposal creation/snapshot)
// function _checkQuorum(uint256 proposalId) internal view returns (bool) { ... }

// Function to check proposal threshold (requires participating voting power)
// function _checkThreshold(uint256 proposalId) internal view returns (bool) { ... }


// Missing implementations for robust reputation tracking, member list iteration,
// and historical voting power (checkpoints) are significant considerations
// for a production-ready DAO of this type. This contract focuses on the core
// advanced *concepts* requested.

// Example of adding voters list to Proposal struct for gas-efficient reputation update:
/*
struct StandardProposal {
    // ... other fields ...
    mapping(address => VoteType) voters;
    address[] votedMembers; // Add this
}
function voteOnStandardProposal(...) {
    // ... existing vote logic ...
    if (proposal.voters[msg.sender] == VoteType(0)) { // First vote from this member
        proposal.votedMembers.push(msg.sender); // Add to list
    }
    // ... rest of vote logic ...
}
function executeStandardProposal(...) {
    // ... existing execution logic ...
    if (currentState == ProposalState.Succeeded) {
        for (uint i = 0; i < proposal.votedMembers.length; i++) {
            address voter = proposal.votedMembers[i];
            if (proposal.voters[voter] == VoteType(uint8(VoteType.For)+1)) { // Check explicit vote type
                _updateReputation(voter, int256(REPUTATION_PER_SUCCESSFUL_VOTE));
            }
             // Optionally decrease reputation for voting against failed proposals
        }
        _updateReputation(msg.sender, int256(REPUTATION_PER_SUCCESSFUL_EXECUTION));
    }
    // ... rest of execute logic ...
}
*/
}
```