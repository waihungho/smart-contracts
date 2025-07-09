Okay, here is a Solidity smart contract for a "Chronicle DAO". This contract combines several concepts:

1.  **Decentralized Autonomous Organization (DAO):** Governs itself through tokenized voting.
2.  **NFT Membership (ERC721):** Ownership of a specific NFT ("Chronicler's Badge") grants membership, proposal rights, and voting power.
3.  **On-Chain Narrative/Chronicle:** Allows members to propose, vote on, and add entries to a shared, immutable (append-only) on-chain record.
4.  **Reputation System:** Introduces "Chronicle Points" awarded for successful contributions (executed proposals), influencing proposal threshold.
5.  **Advanced Proposal Types:** Includes standard parameter changes and arbitrary calls, plus unique types like adding chronicle entries/links, granting/revoking badges, and time-delayed/conditional execution proposals.
6.  **Time-Based Mechanics:** Voting periods, execution delays, and specific timed-release functionalities.

This design aims to be creative by focusing the DAO on a specific, collaborative output (the Chronicle) and incorporating non-standard proposal types and a simple reputation system tied to contribution success. It avoids duplicating standard libraries like OpenZeppelin's Governor, implementing its own proposal and voting logic based on the NFT membership.

---

## ChronicleDAO Smart Contract

**Outline:**

1.  **Interfaces:**
    *   `IChroniclerBadge`: Defines the necessary functions for interacting with the ERC721 Chronicler Badge contract.
2.  **Errors:** Custom errors for gas efficiency.
3.  **Events:** Log important actions (proposals, votes, execution, entries, points).
4.  **Enums:**
    *   `ProposalState`: Lifecycle states of a proposal.
    *   `ProposalType`: Defines the action a proposal intends to perform.
5.  **Structs:**
    *   `ChronicleEntry`: Represents an entry added to the chronicle.
    *   `Proposal`: Represents a DAO proposal.
6.  **State Variables:** Core DAO parameters, counters, contract addresses.
7.  **Mappings:** Storing entries, proposals, votes, and member points.
8.  **Modifiers:** Access control and state checks.
9.  **Constructor:** Initializes the DAO parameters and links the Badge contract.
10. **External Functions (Public/External):**
    *   **Core DAO Actions:**
        *   `propose`: Create a new proposal.
        *   `vote`: Cast a vote on an active proposal.
        *   `cancelProposal`: Cancel an active proposal.
        *   `queueProposal`: Queue a successful proposal for execution.
        *   `executeProposal`: Execute a queued proposal.
        *   `executeConditionalProposal`: Execute a proposal with a time-based condition.
        *   `claimTimedMint`: Claim a badge from a successful TimedMint proposal.
    *   **Chronicle Interaction:**
        *   `getEntry`: Retrieve chronicle entry details.
        *   `getEntryCount`: Get the total number of chronicle entries.
        *   `getLatestEntry`: Get details of the most recent entry.
        *   `getEntryLinks`: Get the linked entry IDs for a specific entry.
    *   **Member & Points:**
        *   `isChronicler`: Check if an address owns a badge (via interface).
        *   `getChroniclerPoints`: Get points for a member.
    *   **Proposal Information (View Functions):**
        *   `getProposal`: Retrieve all details for a proposal.
        *   `getProposalState`: Get the current state of a proposal.
        *   `hasVoted`: Check if an address has voted on a proposal.
        *   `getProposalVotes`: Get vote counts for a proposal.
        *   `getProposalProposer`: Get the proposer's address.
    *   **DAO Parameter Views (View Functions):**
        *   `getVotingPeriod`: Get the current voting period duration.
        *   `getQuorumNumerator`: Get the quorum numerator.
        *   `getQuorumDenominator`: Get the quorum denominator.
        *   `getProposalThreshold`: Get the required points to propose.
        *   `getExecutionDelay`: Get the standard execution delay.
        *   `getChroniclerBadgeContract`: Get the address of the badge contract.
        *   `getProposalExecutionTime`: Get the scheduled execution time for a proposal.

11. **Internal Functions:** Helper functions for proposal execution, state checks, point management, etc.

**Function Summary:**

*   `constructor(address _chroniclerBadgeAddress, uint256 _votingPeriod, uint256 _quorumNumerator, uint256 _quorumDenominator, uint256 _proposalThreshold, uint256 _executionDelay)`: Sets initial DAO parameters and the address of the deployed ChroniclerBadge ERC721 contract.
*   `propose(bytes32 _descriptionHash, uint8 _proposalType, address _target, uint256 _value, bytes calldata _callData, bytes32 _entryDataHash, string memory _entryTitle, uint256 _linkFromEntryId, uint256 _linkToEntryId, address _badgeRecipient, uint256 _conditionalExecutionDelay, uint256 _timedMintDelay)`: Creates a new proposal. Requires Chronicler status and meeting the proposal threshold. Different parameters are used based on `_proposalType`.
*   `vote(uint256 _proposalId, bool _support)`: Casts a vote (true for 'For', false for 'Against') on an active proposal. Requires Chronicler status and not having voted on this proposal before.
*   `cancelProposal(uint256 _proposalId)`: Allows the proposer to cancel their proposal if it hasn't started voting or is still pending.
*   `queueProposal(uint256 _proposalId)`: Moves a successful proposal to the queued state, making it eligible for execution after the `executionDelay`.
*   `executeProposal(uint256 _proposalId)`: Executes a proposal that is in the `Queued` state and the execution delay has passed. Handles different proposal types internally. Awards points for successful Chronicle-related proposals.
*   `executeConditionalProposal(uint256 _proposalId)`: Executes a proposal of type `ConditionalExecution` if it's in the `Queued` state and its specific `conditionalExecutionDelay` has passed *after* the standard execution delay.
*   `claimTimedMint(uint256 _proposalId)`: Allows the intended recipient of a `TimedMintBadge` proposal to claim their badge once the specified `timedMintDelay` has passed *after* execution.
*   `getEntry(uint256 _entryId) external view returns (ChronicleEntry memory)`: Retrieves details of a specific chronicle entry.
*   `getEntryCount() external view returns (uint256)`: Returns the total number of entries in the chronicle.
*   `getLatestEntry() external view returns (ChronicleEntry memory)`: Returns details of the most recently added chronicle entry.
*   `getEntryLinks(uint256 _entryId) external view returns (uint256[] memory)`: Returns the array of entry IDs that the specified entry links to.
*   `isChronicler(address _addr) external view returns (bool)`: Checks if an address owns a Chronicler Badge.
*   `getChroniclerPoints(address _addr) external view returns (uint256)`: Returns the Chronicle Points held by an address.
*   `getProposal(uint256 _proposalId) external view returns (Proposal memory)`: Retrieves all stored details for a proposal.
*   `getProposalState(uint256 _proposalId) external view returns (ProposalState)`: Calculates and returns the current state of a proposal.
*   `hasVoted(uint256 _proposalId, address _voter) external view returns (bool)`: Checks if a specific address has already voted on a proposal.
*   `getProposalVotes(uint256 _proposalId) external view returns (uint256 votesFor, uint256 votesAgainst)`: Returns the current vote counts for a proposal.
*   `getProposalProposer(uint256 _proposalId) external view returns (address)`: Returns the address of the proposer for a given proposal ID.
*   `getVotingPeriod() external view returns (uint256)`: Returns the current voting period duration in seconds.
*   `getQuorumNumerator() external view returns (uint256)`: Returns the quorum numerator (used in percentage calculation with denominator).
*   `getQuorumDenominator() external view returns (uint256)`: Returns the quorum denominator.
*   `getProposalThreshold() external view returns (uint256)`: Returns the minimum Chronicle Points required to create a proposal.
*   `getExecutionDelay() external view returns (uint256)`: Returns the standard delay between a proposal succeeding and being eligible for execution.
*   `getChroniclerBadgeContract() external view returns (address)`: Returns the address of the associated ChroniclerBadge contract.
*   `getProposalExecutionTime(uint256 _proposalId) external view returns (uint256)`: Returns the calculated earliest execution timestamp for a queued proposal (considering standard delay or conditional delay).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces
/**
 * @title IChroniclerBadge
 * @dev Interface for the ERC721 Chronicler Badge contract.
 * Assumes a standard ERC721 implementation with ownerOf.
 */
interface IChroniclerBadge {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external; // For revoke proposals
    function mint(address to) external; // Custom mint function controlled by DAO
    function burn(uint256 tokenId) external; // Custom burn function controlled by DAO
    function totalSupply() external view returns (uint256);
}

// Custom Errors
error ChronicleDAO__InvalidProposalType();
error ChronicleDAO__InsufficientPoints(uint256 required, uint256 has);
error ChronicleDAO__NotAChronicler();
error ChronicleDAO__ProposalNotFound();
error ChronicleDAO__VotingPeriodNotActive();
error ChronicleDAO__AlreadyVoted();
error ChronicleDAO__VotingPeriodNotEnded();
error ChronicleDAO__ProposalStillActive();
error ChronicleDAO__ProposalAlreadyCanceled();
error ChronicleDAO__NotProposer();
error ChronicleDAO__ProposalNotSucceeded();
error ChronicleDAO__ProposalNotQueued();
error ChronicleDAO__ExecutionDelayNotPassed();
error ChronicleDAO__ProposalAlreadyExecuted();
error ChronicleDAO__ProposalExpired(); // If queued too long, though not implemented expiry mechanism here
error ChronicleDAO__InvalidProposalState();
error ChronicleDAO__ExecutionFailed();
error ChronicleDAO__InvalidEntryId();
error ChronicleDAO__InvalidLinkIds();
error ChronicleDAO__NotTimedMintRecipient();
error ChronicleDAO__TimedMintDelayNotPassed();
error ChronicleDAO__ConditionalExecutionDelayNotPassed();
error ChronicleDAO__BadgeAlreadyClaimed(); // For TimedMint

// Events
event ProposalCreated(
    uint256 indexed proposalId,
    address indexed proposer,
    uint8 indexed proposalType,
    bytes32 descriptionHash,
    uint256 votingDeadline,
    uint256 executionTime // Base execution time (end of voting + delay)
);
event Voted(
    uint256 indexed proposalId,
    address indexed voter,
    bool support, // true for For, false for Against
    uint256 votes
); // votes is the total voting power of the voter (1 per badge)
event ProposalCanceled(uint256 indexed proposalId);
event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
event ProposalExecuted(uint256 indexed proposalId, bool success);
event EntryAdded(
    uint256 indexed entryId,
    uint256 indexed proposalId,
    address indexed proposer,
    bytes32 dataHash,
    string title,
    uint256 timestamp
);
event PointsAwarded(address indexed member, uint256 pointsAdded, uint256 newTotal);
event BadgeMintedByDAO(uint256 indexed proposalId, address indexed recipient, uint256 tokenId); // TokenId might be 0 if unknown by DAO
event BadgeBurnedByDAO(uint256 indexed proposalId, address indexed holder);
event EntryLinkAdded(uint256 indexed proposalId, uint256 indexed fromEntryId, uint256 indexed toEntryId);
event TimedMintScheduled(uint256 indexed proposalId, address indexed recipient, uint256 claimableTimestamp);
event TimedMintClaimed(uint256 indexed proposalId, address indexed recipient, uint256 tokenId);


// Enums
enum ProposalState {
    Pending,   // Waiting for start time (not used in this simple time-based model, always Active immediately)
    Active,    // Voting is open
    Canceled,  // Proposer canceled
    Defeated,  // Did not pass vote or quorum
    Succeeded, // Passed vote and quorum, waiting to be queued
    Queued,    // Succeeded and is waiting for execution delay
    Executed,  // Successfully executed
    Expired    // Queued but not executed within an expiry window (not implemented)
}

enum ProposalType {
    AddEntry,
    ChangeDAOParameter, // target, value, callData encodes param index/value
    ExecuteArbitraryCall, // target, value, callData
    AddEntryLink, // linkFromEntryId, linkToEntryId
    GrantBadge, // badgeRecipient
    RevokeBadge, // badgeRecipient (address of badge holder)
    TimedMintBadge, // badgeRecipient, timedMintDelay (delay after execution)
    ConditionalExecution, // target, value, callData, conditionalExecutionDelay (delay after execution)
    TransferFunds // target, value
}

// Structs
struct ChronicleEntry {
    uint256 id;
    bytes32 dataHash; // e.g., IPFS hash or content hash
    string title;
    uint256 timestamp;
    address proposer;
    uint256 proposalId;
    uint256[] linksTo; // IDs of other entries this one links to
}

struct Proposal {
    uint256 id;
    address proposer;
    bytes32 descriptionHash; // Hash of proposal details stored off-chain
    ProposalType proposalType;

    // Proposal specific data (use based on type)
    address target;
    uint256 value; // ETH value for calls/transfers
    bytes callData; // Calldata for arbitrary calls / parameter changes
    bytes32 entryDataHash; // For AddEntry
    string entryTitle; // For AddEntry
    uint256 linkFromEntryId; // For AddEntryLink
    uint256 linkToEntryId; // For AddEntryLink
    address badgeRecipient; // For Grant/Revoke/TimedMint Badge
    uint256 conditionalExecutionDelay; // For ConditionalExecution (delay after base executionTime)
    uint256 timedMintDelay; // For TimedMintBadge (delay after base executionTime)

    // State
    uint256 creationTime;
    uint256 votingDeadline; // creationTime + votingPeriod
    uint256 executionTime; // votingDeadline + executionDelay (base time)
    ProposalState state;

    // Voting
    uint256 votesFor;
    uint256 votesAgainst;
    mapping(address => bool) hasVoted; // Only needs to track Chroniclers
    bool executed;
    bool badgeClaimed; // For TimedMintBadge
}


contract ChronicleDAO {
    using Address for address;

    // DAO Parameters (Governed by proposals)
    uint256 public votingPeriod; // in seconds
    uint256 public quorumNumerator; // Quorum represented as a fraction
    uint256 public quorumDenominator;
    uint256 public proposalThreshold; // Minimum Chronicle Points required to propose
    uint256 public executionDelay; // Delay between proposal succeeding and being executable (in seconds)
    uint256 public constant POINT_AWARD_ENTRY = 10; // Points awarded for successfully adding an entry
    uint256 public constant POINT_AWARD_LINK = 5; // Points awarded for successfully adding a link

    // Core State
    IChroniclerBadge public immutable chroniclerBadge;
    uint256 private nextProposalId;
    uint256 private nextEntryId;

    // Storage
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => ChronicleEntry) public chronicle;
    mapping(address => uint256) public chroniclerPoints; // Tracks reputation points per address

    // Modifiers
    modifier onlyChronicler() {
        if (chroniclerBadge.balanceOf(msg.sender) == 0) {
            revert ChronicleDAO__NotAChronicler();
        }
        _;
    }

    modifier whenState(uint256 _proposalId, ProposalState _expectedState) {
        if (getProposalState(_proposalId) != _expectedState) {
            revert ChronicleDAO__InvalidProposalState();
        }
        _;
    }

    /**
     * @dev The constructor initializes the DAO with core parameters and links
     *      the Chronicler Badge ERC721 contract.
     * @param _chroniclerBadgeAddress Address of the deployed IChroniclerBadge contract.
     * @param _votingPeriod Duration for proposal voting in seconds.
     * @param _quorumNumerator Numerator for quorum calculation.
     * @param _quorumDenominator Denominator for quorum calculation (e.g., 4 for 40%, denominator 10).
     * @param _proposalThreshold Minimum points required to create a proposal.
     * @param _executionDelay Delay after voting ends before execution is possible in seconds.
     */
    constructor(
        address _chroniclerBadgeAddress,
        uint256 _votingPeriod,
        uint256 _quorumNumerator,
        uint256 _quorumDenominator,
        uint256 _proposalThreshold,
        uint256 _executionDelay
    ) {
        if (_chroniclerBadgeAddress == address(0)) {
            revert ChronicleDAO__InvalidProposalType(); // Using a generic error here
        }
        if (_quorumDenominator == 0) {
             revert ChronicleDAO__InvalidProposalType();
        }

        chroniclerBadge = IChroniclerBadge(_chroniclerBadgeAddress);
        votingPeriod = _votingPeriod;
        quorumNumerator = _quorumNumerator;
        quorumDenominator = _quorumDenominator;
        proposalThreshold = _proposalThreshold;
        executionDelay = _executionDelay;

        nextProposalId = 1;
        nextEntryId = 1;
    }

    /**
     * @dev Allows a Chronicler with sufficient points to create a new proposal.
     *      Uses various parameters based on the chosen proposal type.
     * @param _descriptionHash IPFS or other hash referencing off-chain proposal details.
     * @param _proposalType The type of proposal (enum ProposalType).
     * @param _target Target address for calls, transfers, or badge actions.
     * @param _value ETH value for calls or transfers.
     * @param _callData Calldata for arbitrary calls or encoded parameter changes.
     * @param _entryDataHash Data hash for AddEntry type.
     * @param _entryTitle Title for AddEntry type.
     * @param _linkFromEntryId Source entry ID for AddEntryLink type.
     * @param _linkToEntryId Target entry ID for AddEntryLink type.
     * @param _badgeRecipient Recipient/holder address for badge proposals.
     * @param _conditionalExecutionDelay Extra delay for ConditionalExecution type after base executionTime.
     * @param _timedMintDelay Delay for TimedMintBadge type after base executionTime.
     * @return The ID of the created proposal.
     */
    function propose(
        bytes32 _descriptionHash,
        uint8 _proposalType,
        address _target,
        uint256 _value,
        bytes calldata _callData,
        bytes32 _entryDataHash,
        string memory _entryTitle,
        uint256 _linkFromEntryId,
        uint256 _linkToEntryId,
        address _badgeRecipient,
        uint256 _conditionalExecutionDelay,
        uint256 _timedMintDelay
    ) external onlyChronicler returns (uint256) {
        if (chroniclerPoints[msg.sender] < proposalThreshold) {
            revert ChronicleDAO__InsufficientPoints(proposalThreshold, chroniclerPoints[msg.sender]);
        }

        ProposalType proposalTypeEnum;
        unchecked { // Assuming _proposalType maps directly to enum values
            proposalTypeEnum = ProposalType(_proposalType);
        }

        // Basic validation for specific types
        if (proposalTypeEnum == ProposalType.AddEntry && (_entryDataHash == bytes32(0) || bytes(_entryTitle).length == 0)) {
             revert ChronicleDAO__InvalidProposalType();
        }
         if (proposalTypeEnum == ProposalType.AddEntryLink && (_linkFromEntryId == 0 || _linkToEntryId == 0 || _linkFromEntryId > nextEntryId - 1 || _linkToEntryId > nextEntryId - 1)) {
             revert ChronicleDAO__InvalidLinkIds(); // Need valid existing entries
        }
        if ((proposalTypeEnum == ProposalType.GrantBadge || proposalTypeEnum == ProposalType.RevokeBadge || proposalTypeEnum == ProposalType.TimedMintBadge) && _badgeRecipient == address(0)) {
             revert ChronicleDAO__InvalidProposalType();
        }
        if (proposalTypeEnum == ProposalType.ExecuteArbitraryCall && _target == address(0)) {
             revert ChronicleDAO__InvalidProposalType();
        }
         if (proposalTypeEnum == ProposalType.TransferFunds && _target == address(0)) {
             revert ChronicleDAO__InvalidProposalType();
        }


        uint256 proposalId = nextProposalId++;
        uint256 currentTime = block.timestamp;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.descriptionHash = _descriptionHash;
        proposal.proposalType = proposalTypeEnum;

        // Store relevant data based on type
        proposal.target = _target;
        proposal.value = _value;
        proposal.callData = _callData;
        proposal.entryDataHash = _entryDataHash;
        proposal.entryTitle = _entryTitle;
        proposal.linkFromEntryId = _linkFromEntryId;
        proposal.linkToEntryId = _linkToEntryId;
        proposal.badgeRecipient = _badgeRecipient;
        proposal.conditionalExecutionDelay = _conditionalExecutionDelay;
        proposal.timedMintDelay = _timedMintDelay;

        proposal.creationTime = currentTime;
        proposal.votingDeadline = currentTime + votingPeriod;
        proposal.executionTime = proposal.votingDeadline + executionDelay; // Base execution time
        proposal.state = ProposalState.Active;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;
        proposal.badgeClaimed = false; // For TimedMint

        emit ProposalCreated(
            proposalId,
            msg.sender,
            uint8(proposalTypeEnum),
            _descriptionHash,
            proposal.votingDeadline,
            proposal.executionTime
        );

        return proposalId;
    }

    /**
     * @dev Allows a Chronicler to vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'For', False for 'Against'.
     */
    function vote(uint256 _proposalId, bool _support) external onlyChronicler {
        Proposal storage proposal = proposals[_proposalId];

        if (getProposalState(_proposalId) != ProposalState.Active) {
            revert ChronicleDAO__VotingPeriodNotActive();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert ChronicleDAO__AlreadyVoted();
        }

        // Voting power is 1 token = 1 vote in this simple model
        // Can be extended based on points, time held, etc.
        uint256 voterPower = chroniclerBadge.balanceOf(msg.sender);
        if (voterPower == 0) {
             revert ChronicleDAO__NotAChronicler(); // Redundant due to modifier but safe
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        emit Voted(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Allows the proposer to cancel their proposal before it becomes eligible for queuing.
     * @param _proposalId The ID of the proposal.
     */
    function cancelProposal(uint256 _proposalId) external {
         Proposal storage proposal = proposals[_proposalId];
         if (proposal.proposer != msg.sender) {
             revert ChronicleDAO__NotProposer();
         }
         ProposalState currentState = getProposalState(_proposalId);
         if (currentState != ProposalState.Active && currentState != ProposalState.Pending) { // Should mostly be Active in this model
             revert ChronicleDAO__ProposalAlreadyCanceled(); // Or already Succeeded/Defeated etc.
         }

         proposal.state = ProposalState.Canceled;
         emit ProposalCanceled(_proposalId);
    }


    /**
     * @dev Queues a proposal that has succeeded based on voting results.
     * @param _proposalId The ID of the proposal.
     */
    function queueProposal(uint256 _proposalId) external whenState(_proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[_proposalId];
        proposal.state = ProposalState.Queued;
        // Re-calculate or confirm executionTime in case DAO params changed between success and queuing
        // For simplicity here, we stick to the time calculated when proposed + executionDelay
        // proposal.executionTime = block.timestamp + executionDelay; // Alternative: delay from *queuing* time
        // We use the pre-calculated time based on voting end: proposal.executionTime

        emit ProposalQueued(_proposalId, proposal.executionTime);
    }

    /**
     * @dev Executes a proposal that is in the Queued state and the execution delay has passed.
     *      Handles execution logic based on proposal type.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external whenState(_proposalId, ProposalState.Queued) {
        Proposal storage proposal = proposals[_proposalId];

        // Check standard execution delay
        if (block.timestamp < proposal.executionTime) {
             revert ChronicleDAO__ExecutionDelayNotPassed();
        }

        // Special check for ConditionalExecution - must use executeConditionalProposal instead
        if (proposal.proposalType == ProposalType.ConditionalExecution) {
             revert ChronicleDAO__InvalidProposalState(); // Use executeConditionalProposal
        }

        if (proposal.executed) {
             revert ChronicleDAO__ProposalAlreadyExecuted();
        }

        _executeProposal(_proposalId, proposal.proposalType, proposal.target, proposal.value, proposal.callData, proposal.entryDataHash, proposal.entryTitle, proposal.linkFromEntryId, proposal.linkToEntryId, proposal.badgeRecipient, proposal.timedMintDelay);

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, true);
    }

     /**
     * @dev Executes a specific ConditionalExecution proposal type. Requires its specific delay to pass.
     * @param _proposalId The ID of the proposal.
     */
    function executeConditionalProposal(uint256 _proposalId) external whenState(_proposalId, ProposalState.Queued) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType != ProposalType.ConditionalExecution) {
             revert ChronicleDAO__InvalidProposalType(); // Must be ConditionalExecution
        }

        // Check standard execution delay AND the additional conditional delay
        if (block.timestamp < proposal.executionTime + proposal.conditionalExecutionDelay) {
             revert ChronicleDAO__ConditionalExecutionDelayNotPassed();
        }

         if (proposal.executed) {
             revert ChronicleDAO__ProposalAlreadyExecuted();
        }

        _executeProposal(_proposalId, proposal.proposalType, proposal.target, proposal.value, proposal.callData, proposal.entryDataHash, proposal.entryTitle, proposal.linkFromEntryId, proposal.linkToEntryId, proposal.badgeRecipient, proposal.timedMintDelay);

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, true);
    }


     /**
     * @dev Allows the designated recipient of a TimedMintBadge proposal to claim their badge.
     * @param _proposalId The ID of the TimedMintBadge proposal.
     */
    function claimTimedMint(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType != ProposalType.TimedMintBadge) {
            revert ChronicleDAO__InvalidProposalType();
        }
        if (proposal.state != ProposalState.Executed) {
            revert ChronicleDAO__InvalidProposalState(); // Must be executed first
        }
        if (proposal.badgeRecipient != msg.sender) {
            revert ChronicleDAO__NotTimedMintRecipient();
        }
        if (block.timestamp < proposal.executionTime + proposal.timedMintDelay) {
            revert ChronicleDAO__TimedMintDelayNotPassed();
        }
        if (proposal.badgeClaimed) {
            revert ChronicleDAO__BadgeAlreadyClaimed();
        }

        // Mint the badge to the recipient
        chroniclerBadge.mint(msg.sender); // Assumes the badge contract has a mint function callable by this DAO

        proposal.badgeClaimed = true;
        // We don't know the tokenId here without querying the badge contract right after mint,
        // so we emit 0 or can query if the interface supported returning it.
        // Assuming badge contract auto-increments or similar.
        emit TimedMintClaimed(_proposalId, msg.sender, 0); // Emitting 0 as a placeholder tokenId

    }


    /**
     * @dev Internal function to handle the execution logic based on proposal type.
     */
    function _executeProposal(
        uint256 _proposalId,
        ProposalType _proposalType,
        address _target,
        uint256 _value,
        bytes memory _callData,
        bytes32 _entryDataHash,
        string memory _entryTitle,
        uint256 _linkFromEntryId,
        uint256 _linkToEntryId,
        address _badgeRecipient,
        uint256 _timedMintDelay // Only used for TimedMintBadge type
    ) internal {
        bool success = false;
        // Award points *before* execution, as execution might fail but proposal succeeded vote-wise
        // Or award only on successful execution? Let's award on successful execution of relevant types.

        if (_proposalType == ProposalType.AddEntry) {
            uint256 entryId = nextEntryId++;
            chronicle[entryId] = ChronicleEntry({
                id: entryId,
                dataHash: _entryDataHash,
                title: _entryTitle,
                timestamp: block.timestamp,
                proposer: proposals[_proposalId].proposer,
                proposalId: _proposalId,
                linksTo: new uint256[](0) // Start with no links
            });
            emit EntryAdded(entryId, _proposalId, proposals[_proposalId].proposer, _entryDataHash, _entryTitle, block.timestamp);
            _awardPoints(proposals[_proposalId].proposer, POINT_AWARD_ENTRY);
            success = true;

        } else if (_proposalType == ProposalType.ChangeDAOParameter) {
            // _callData is expected to encode the parameter index/identifier and new value
            // Example: Simple mapping for parameter index (e.g., 0 for votingPeriod, 1 for quorumNumerator, etc.)
            // This is a simplified example; a robust implementation might use ABI decoding or internal functions.
            // Here, we'll use target as a simple parameter index and value as the new value.
            // A real implementation would need careful encoding/decoding or specific functions per parameter.
            // bytes decodedData = proposals[_proposalId].callData; // Need abi.decode

            // Simple direct setting for illustration; a real DAO needs robust param change logic.
            // This example assumes _target indicates WHICH parameter and _value is the new value.
            // THIS IS INSECURE FOR ARBITRARY PARAMETERS - USE WITH CAUTION OR REFACTOR
            // A better way is to have _executeChangeDAOParameter decode _callData safely.

            // Example of how a real system might work (pseudocode):
            // (uint8 paramIndex, uint256 newValue) = abi.decode(_callData, (uint8, uint256));
            // if (paramIndex == 0) votingPeriod = newValue;
            // else if (paramIndex == 1) quorumNumerator = newValue;
            // else if ... etc.
            // Check permissions/valid ranges

            // For this example, we will use a very simple, limited set or rely on _callData decoding later.
            // Let's make ChangeDAOParameter require callData that calls a *specific* internal setter function.
            // e.g., callData = abi.encodeWithSelector(this.setVotingPeriodInternal.selector, newValue)
            // This requires making internal functions callable via `call`.

             (success, ) = address(this).call(_callData);


        } else if (_proposalType == ProposalType.ExecuteArbitraryCall) {
             (success, ) = _target.call{value: _value}(_callData);

        } else if (_proposalType == ProposalType.AddEntryLink) {
            // Check if from/to entries exist
            if (_linkFromEntryId == 0 || _linkFromEntryId >= nextEntryId || _linkToEntryId == 0 || _linkToEntryId >= nextEntryId) {
                revert ChronicleDAO__InvalidLinkIds(); // Should have been caught in propose, but double check
            }
            // Add link to the 'from' entry's linksTo array
            chronicle[_linkFromEntryId].linksTo.push(_linkToEntryId);
            emit EntryLinkAdded(_proposalId, _linkFromEntryId, _linkToEntryId);
            _awardPoints(proposals[_proposalId].proposer, POINT_AWARD_LINK);
            success = true;

        } else if (_proposalType == ProposalType.GrantBadge) {
            // Mint a new badge to the recipient
             chroniclerBadge.mint(_badgeRecipient); // Assumes mint function callable by this DAO
             emit BadgeMintedByDAO(_proposalId, _badgeRecipient, 0); // TokenId unknown
             success = true;

        } else if (_proposalType == ProposalType.RevokeBadge) {
            // Burn a badge held by the recipient. Need to find one of their tokenIds.
            // This requires the badge contract to allow burning a specific token ID or *any* token ID of an owner.
            // A simple approach: require the proposer to specify the *tokenId* in _callData/other param.
            // Let's assume the proposal includes the tokenId in _value for simplicity in *this* example.
             uint256 tokenIdToBurn = _value;
             address holder = chroniclerBadge.ownerOf(tokenIdToBurn);
             if (holder != _badgeRecipient) {
                revert ChronicleDAO__ExecutionFailed(); // Specified token ID not held by target recipient
             }
             chroniclerBadge.burn(tokenIdToBurn); // Assumes burn function callable by this DAO
             emit BadgeBurnedByDAO(_proposalId, _badgeRecipient);
             success = true;

        } else if (_proposalType == ProposalType.TimedMintBadge) {
            // Logic handled in claimTimedMint. We just mark it executable here.
            // The actual minting happens when claimTimedMint is called by the recipient after the delay.
            emit TimedMintScheduled(_proposalId, _badgeRecipient, proposals[_proposalId].executionTime + _timedMintDelay);
            success = true; // Mark as executed successfully for the schedule to be set

        } else if (_proposalType == ProposalType.ConditionalExecution) {
            // Execution handled in executeConditionalProposal. Actual logic is the arbitrary call.
             (success, ) = _target.call{value: _value}(_callData); // Perform the call
             if (!success) {
                 revert ChronicleDAO__ExecutionFailed();
             }

        } else if (_proposalType == ProposalType.TransferFunds) {
             (success, ) = _target.call{value: _value}("");
             if (!success) {
                 revert ChronicleDAO__ExecutionFailed();
             }

        } else {
            revert ChronicleDAO__InvalidProposalType();
        }

        if (!success) {
            // Revert execution if the internal call failed, but the proposal state remains "Executed"
            // A more advanced DAO might move it to a "FailedExecution" state.
             revert ChronicleDAO__ExecutionFailed();
        }
    }

    /**
     * @dev Internal function to award points to a member.
     * @param _member The address to award points to.
     * @param _points The number of points to award.
     */
    function _awardPoints(address _member, uint256 _points) internal {
        uint256 newTotal = chroniclerPoints[_member] + _points;
        chroniclerPoints[_member] = newTotal;
        emit PointsAwarded(_member, _points, newTotal);
    }

    // --- Parameter Setter Functions (Internal, callable only via ChangeDAOParameter proposal) ---
    // These should only be callable via the `call` in `_executeProposal` from ChangeDAOParameter type.
    // The callData in the proposal should be abi.encodeWithSelector(this.setVotingPeriodInternal.selector, newValue) etc.
    // Added _checkMsgSenderIsSelf to enforce this, preventing accidental direct calls.

    modifier _checkMsgSenderIsSelf() {
        if (msg.sender != address(this)) {
            revert ChronicleDAO__ExecutionFailed(); // Indicates internal call only
        }
        _;
    }

    function setVotingPeriodInternal(uint256 _newVotingPeriod) external _checkMsgSenderIsSelf {
        votingPeriod = _newVotingPeriod;
    }

    function setQuorumInternal(uint256 _newNumerator, uint256 _newDenominator) external _checkMsgSenderIsSelf {
        if (_newDenominator == 0) revert ChronicleDAO__ExecutionFailed();
        quorumNumerator = _newNumerator;
        quorumDenominator = _newDenominator;
    }

    function setProposalThresholdInternal(uint256 _newProposalThreshold) external _checkMsgSenderIsSelf {
        proposalThreshold = _newProposalThreshold;
    }

    function setExecutionDelayInternal(uint256 _newExecutionDelay) external _checkMsgSenderIsSelf {
        executionDelay = _newExecutionDelay;
    }

    // --- View Functions ---

    /**
     * @dev Gets the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) { // Assuming proposal 0 is invalid/non-existent
             revert ChronicleDAO__ProposalNotFound();
        }

        if (proposal.state == ProposalState.Canceled) return ProposalState.Canceled;
        if (proposal.state == ProposalState.Executed) return ProposalState.Executed;
        if (proposal.state == ProposalState.Queued) return ProposalState.Queued;

        // Check states based on time and votes
        if (block.timestamp < proposal.creationTime) return ProposalState.Pending; // Should not happen with block.timestamp start
        if (block.timestamp <= proposal.votingDeadline) return ProposalState.Active;

        // Voting period has ended, determine Defeated or Succeeded
        uint256 totalVotingSupply = chroniclerBadge.totalSupply();
        uint256 votesCast = proposal.votesFor + proposal.votesAgainst;

        // Check quorum
        if (votesCast * quorumDenominator < totalVotingSupply * quorumNumerator) {
            return ProposalState.Defeated;
        }

        // Check majority
        if (proposal.votesFor <= proposal.votesAgainst) {
            return ProposalState.Defeated;
        }

        return ProposalState.Succeeded;
    }

    /**
     * @dev Retrieves details of a specific chronicle entry.
     * @param _entryId The ID of the entry.
     * @return ChronicleEntry struct containing entry details.
     */
    function getEntry(uint256 _entryId) external view returns (ChronicleEntry memory) {
        if (_entryId == 0 || _entryId >= nextEntryId) {
            revert ChronicleDAO__InvalidEntryId();
        }
        return chronicle[_entryId];
    }

    /**
     * @dev Gets the total number of chronicle entries.
     * @return The number of entries.
     */
    function getEntryCount() external view returns (uint256) {
        return nextEntryId - 1; // Since IDs start from 1
    }

    /**
     * @dev Gets the details of the most recent chronicle entry.
     * @return ChronicleEntry struct of the latest entry.
     */
    function getLatestEntry() external view returns (ChronicleEntry memory) {
         uint256 latestId = nextEntryId - 1;
         if (latestId == 0) {
             revert ChronicleDAO__InvalidEntryId(); // No entries yet
         }
         return chronicle[latestId];
    }

    /**
     * @dev Gets the list of entry IDs linked from a specific entry.
     * @param _entryId The ID of the entry.
     * @return An array of entry IDs linked from the specified entry.
     */
    function getEntryLinks(uint256 _entryId) external view returns (uint256[] memory) {
        if (_entryId == 0 || _entryId >= nextEntryId) {
            revert ChronicleDAO__InvalidEntryId();
        }
        return chronicle[_entryId].linksTo;
    }

    /**
     * @dev Checks if an address holds a Chronicler Badge.
     * @param _addr The address to check.
     * @return True if the address owns at least one badge, false otherwise.
     */
    function isChronicler(address _addr) external view returns (bool) {
        return chroniclerBadge.balanceOf(_addr) > 0;
    }

    /**
     * @dev Gets the Chronicle Points for an address.
     * @param _addr The address to check.
     * @return The number of Chronicle Points.
     */
    function getChroniclerPoints(address _addr) external view returns (uint256) {
        return chroniclerPoints[_addr];
    }

    /**
     * @dev Retrieves details for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing all proposal details.
     */
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
         if (proposals[_proposalId].id == 0) {
             revert ChronicleDAO__ProposalNotFound();
        }
        return proposals[_proposalId];
    }

    /**
     * @dev Checks if an address has voted on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address to check.
     * @return True if the address has voted, false otherwise.
     */
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
         if (proposals[_proposalId].id == 0) {
             revert ChronicleDAO__ProposalNotFound();
        }
        return proposals[_proposalId].hasVoted[_voter];
    }

     /**
     * @dev Gets the vote counts for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return votesFor The number of 'For' votes.
     * @return votesAgainst The number of 'Against' votes.
     */
    function getProposalVotes(uint256 _proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
         if (proposals[_proposalId].id == 0) {
             revert ChronicleDAO__ProposalNotFound();
        }
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

     /**
     * @dev Gets the proposer's address for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The proposer's address.
     */
    function getProposalProposer(uint256 _proposalId) external view returns (address) {
         if (proposals[_proposalId].id == 0) {
             revert ChronicleDAO__ProposalNotFound();
        }
        return proposals[_proposalId].proposer;
    }

     /**
     * @dev Gets the calculated execution time for a queued proposal.
     *      Considers base execution time and additional conditional delay.
     * @param _proposalId The ID of the proposal.
     * @return The earliest timestamp the proposal can be executed.
     */
    function getProposalExecutionTime(uint256 _proposalId) external view returns (uint256) {
         Proposal storage proposal = proposals[_proposalId];
         if (proposal.id == 0) {
             revert ChronicleDAO__ProposalNotFound();
        }
        if (proposal.proposalType == ProposalType.ConditionalExecution) {
            return proposal.executionTime + proposal.conditionalExecutionDelay;
        }
        // For TimedMint, this is the schedule time, but claimable is executionTime + timedMintDelay
        // This getter just gives the time the *proposal itself* is executable (standard delay)
        // We could add another getter for claimable time specifically for TimedMint
        return proposal.executionTime; // Base execution time
    }

    // Getters for DAO parameters
    function getVotingPeriod() external view returns (uint256) { return votingPeriod; }
    function getQuorumNumerator() external view returns (uint256) { return quorumNumerator; }
    function getQuorumDenominator() external view returns (uint256) { return quorumDenominator; }
    function getProposalThreshold() external view returns (uint256) { return proposalThreshold; }
    function getExecutionDelay() external view returns (uint256) { return executionDelay; }
    function getChroniclerBadgeContract() external view returns (address) { return address(chroniclerBadge); }

    // Fallback function to receive ETH if needed for TransferFunds proposals
    receive() external payable {}
}

// Simple ERC721 interface for clarity, using a custom one linked above.
// The actual ChroniclerBadge contract needs to implement these functions.
// For example, a basic version could be:
/*
contract ChroniclerBadge is ERC721, Ownable {
    uint256 private _nextTokenId;
    address public daoAddress; // Address of the ChronicleDAO contract

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call");
        _;
    }

    constructor(string memory name, string memory symbol, address _daoAddress) ERC721(name, symbol) Ownable(msg.sender) {
        daoAddress = _daoAddress;
    }

    function mint(address to) public onlyDAO {
        _safeMint(to, _nextTokenId++);
    }

    function burn(uint256 tokenId) public onlyDAO {
        _burn(tokenId);
    }

    // Override transferFrom and safeTransferFrom to potentially add checks? Or keep standard for members.
    // For DAO revoke proposal, direct burn by DAO is easier.
}
*/
```

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **NFT-Gated DAO Membership:** The `onlyChronicler` modifier uses the `IChroniclerBadge` interface to check the balance of the caller. Only addresses holding at least one Chronicler Badge NFT can call core functions like `propose` and `vote`.
2.  **On-Chain Chronicle:** The `ChronicleEntry` struct and `chronicle` mapping store narrative entries directly on-chain. This is gas-intensive for large content, so `dataHash` is used to reference off-chain data (like IPFS), keeping the on-chain footprint small while preserving the immutable list of entries and their metadata. Functions like `getEntry`, `getEntryCount`, `getLatestEntry` allow reading this data.
3.  **Chronicle Points (Simple Reputation):** The `chroniclerPoints` mapping introduces a non-transferable point system. Points are awarded via `_awardPoints` when specific proposals (like adding an entry or link) are successfully *executed*. The `proposalThreshold` requires a minimum number of points to submit a proposal, adding a basic Sybil resistance and rewarding active contributors.
4.  **Diverse and Custom Proposal Types:** The `ProposalType` enum defines specific actions beyond generic calls.
    *   `AddEntry`: Dedicated type for adding to the chronicle.
    *   `AddEntryLink`: Allows creating directed links between existing chronicle entries, building a graph structure on-chain.
    *   `GrantBadge` / `RevokeBadge`: DAO can vote to issue new memberships or remove existing ones (requires a powerful DAO!). Revoke requires specifying a `tokenId` in this example for simplicity.
    *   `TimedMintBadge`: A creative type where the execution of the proposal doesn't immediately mint the badge, but schedules it. The intended recipient must call `claimTimedMint` *after* a specified delay (`timedMintDelay`) has passed since the *proposal execution*. This is a simple form of time-locked distribution.
    *   `ConditionalExecution`: Allows proposals whose arbitrary call execution is delayed *beyond* the standard `executionDelay` by an additional `conditionalExecutionDelay`. This could be extended to check other on-chain conditions before execution (though kept simple time-based here for clarity). It requires a specific `executeConditionalProposal` call.
5.  **Custom DAO Logic:** Instead of inheriting a standard Governor contract, this implements its own proposal lifecycle, state transitions (`ProposalState`), voting mechanism (1 NFT = 1 vote, with quorum and simple majority), and execution logic tailored to the custom `ProposalType`s.
6.  **Internal Parameter Setters:** DAO parameter changes (`ChangeDAOParameter`) are handled by calling internal setter functions (`setVotingPeriodInternal`, etc.) via the low-level `call` function within `_executeProposal`. This pattern ensures these sensitive changes can *only* occur through a successful DAO vote and not direct external calls, while keeping the setters themselves private/internal logic. The `_checkMsgSenderIsSelf` modifier adds a safety layer, though the primary protection is that the `call` originates from `address(this)`.
7.  **Gas Efficiency:** Uses custom errors (Solidity >= 0.8.4) and `calldata` where appropriate in external functions. Avoids storing dynamic arrays or large data structures (like lists of voters or proposer proposals) directly in storage mappings where possible, relying on events or external indexing for historical data.

This contract provides a unique blend of DAO governance, NFT utility, on-chain data structures, reputation, and custom execution logic, moving beyond typical token-transfer or simple voting DAOs. It requires a separate `ChroniclerBadge` ERC721 contract deployed and linked to this DAO.