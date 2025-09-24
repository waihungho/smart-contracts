The following smart contract, `ChronicleOracleNetwork`, is designed to be a decentralized oracle network specifically for **subjective, time-sensitive, and emergent event data**. Unlike traditional oracles focused on objective price feeds, this protocol integrates **AI-assisted pre-evaluation**, human verification by **ChronicleKeepers**, a **Soulbound Token (SBT)**-based reputation system, and a **decentralized dispute resolution** mechanism.

The core idea is to establish a robust, community-driven process for determining the "truth" of events that require human judgment or AI interpretation, such as: "Was this AI's prediction accurate?", "Did a project meet its milestone?", or "What was the sentiment around a news event?".

This contract aims to be creative and advanced by combining several trendy concepts:
*   **Decentralized Oracle Network:** For subjective data.
*   **AI Integration:** Via a trusted oracle for initial assessment.
*   **Soulbound Tokens (SBTs):** For non-transferable keeper reputation.
*   **Decentralized Dispute Resolution:** A mini-court system with reputation-weighted jurors.
*   **Dynamic Staking & Rewards:** Keepers stake for attestations and earn rewards/reputation for accuracy.

---

## ChronicleOracleNetwork: Outline and Function Summary

**I. Core Setup & Administration**
1.  **`constructor`**: Initializes the contract, sets the admin, links the `ChronicleSBT` contract address, and sets initial parameters for the network.
2.  **`updateChronicleSBTContract(address _newSBTAddress)`**: Allows the admin to update the address of the linked `ChronicleSBT` contract.
3.  **`setOracleAddress(address _newOracleAddress)`**: Sets the address of the trusted off-chain oracle that feeds AI pre-evaluations into the contract.
4.  **`setMinKeeperStake(uint256 _minStake)`**: Sets the minimum collateral amount required for a `ChronicleKeeper` to register and participate.
5.  **`setDefaultEventQueryFee(uint256 _newDefaultFee)`**: Sets the default fee required from proposers to query an event.

**II. Chronicle Event Management**
6.  **`proposeChronicleEvent(string memory _descriptionURI, uint256 _resolutionDeadline, uint256 _minReputationForConsensus)`**: Allows any user to propose a new subjective event for resolution, specifying its details, deadline, and the minimum combined reputation required for consensus.
7.  **`depositEventQueryFee(uint256 _eventId)`**: Users deposit the required fee (in native token) to activate a proposed event for resolution, covering keeper rewards and protocol fees.
8.  **`cancelProposedEvent(uint256 _eventId)`**: Allows the event proposer to cancel their event if it's still pending or past its deadline without resolution, refunding any deposited fees.
9.  **`getEventDetails(uint256 _eventId)`**: View function to retrieve comprehensive details about a specific chronicle event.
10. **`requestAIPreEvaluation(uint256 _eventId)`**: Internal/Protocol function to conceptually trigger the off-chain AI oracle for initial analysis of an event. (In practice, an off-chain system would listen for an event trigger).
11. **`receiveAIPreEvaluation(uint256 _eventId, bytes32 _aiSuggestedOutcomeHash, uint256 _confidenceScore, bytes32 _proof)`**: Callable only by the `trustedOracleAddress`, this function feeds the AI's preliminary analysis and confidence score for an event back into the contract.
12. **`markEventResolved(uint256 _eventId)`**: Internal/Protocol function that finalizes an event's resolution once sufficient consensus is reached by keepers or the deadline passes, distributing rewards and updating reputation.

**III. Chronicle Keeper Management**
13. **`registerAsKeeper()`**: Allows a user to stake a minimum amount of tokens to become a `ChronicleKeeper` and participate in event resolution.
14. **`deregisterAsKeeper()`**: Allows a `ChronicleKeeper` to unstake their collateral and leave the network after a cooling-off period, provided they have no active disputes or pending attestations.
15. **`submitEventAttestation(uint256 _eventId, bytes32 _attestationHash)`**: `ChronicleKeepers` submit their subjective assessment/data for a pending event, along with a small collateral stake.
16. **`updateKeeperProfile(string memory _profileURI)`**: Allows a `ChronicleKeeper` to update a URI pointing to their off-chain profile or credentials.
17. **`getKeeperInfo(address _keeperAddress)`**: View function to retrieve general information about a `ChronicleKeeper`, including their stake, accumulated rewards, and registration status.

**IV. Reputation & SBT Integration**
18. **`getKeeperReputation(address _keeperAddress)`**: View function to query the current reputation score (represented by their SBT balance) of a specific `ChronicleKeeper`.
19. **`awardReputation(address _keeperAddress, uint256 _amount)`**: Internal/Protocol function to mint/increase `ChronicleSBT` for a keeper based on accurate attestations or successful dispute resolution.
20. **`penalizeReputation(address _keeperAddress, uint256 _amount)`**: Internal/Protocol function to burn/decrease `ChronicleSBT` for a keeper due to inaccurate attestations or failed dispute claims.

**V. Dispute Resolution System**
21. **`raiseDispute(uint256 _eventId, bytes32 _allegedOutcomeHash, string memory _explanationURI)`**: Allows any user or keeper to formally dispute a proposed outcome, an AI pre-evaluation, or a keeper's attestation for an event, by staking a bond.
22. **`stakeForDispute(uint256 _disputeId)`**: Parties involved in a dispute (disputer, defender) stake additional tokens to support their position.
23. **`selectJurors(uint256 _disputeId)`**: Internal/Protocol function to algorithmically select a panel of high-reputation `ChronicleKeepers` to act as jurors for a dispute (using pseudo-random, reputation-weighted selection).
24. **`submitJurorVote(uint256 _disputeId, uint256 _choice)`**: Selected jurors cast their vote on the disputed outcome.
25. **`resolveDispute(uint256 _disputeId)`**: Internal/Protocol function to finalize a dispute, distribute staked funds (penalizing the loser, rewarding the winner), and adjust the reputation (SBTs) of involved parties and jurors based on the outcome.

**VI. Reward & Fee Management**
26. **`claimKeeperRewards()`**: Allows `ChronicleKeepers` to claim their accumulated rewards from accurately resolved events and participating in dispute resolution.
27. **`getProtocolFeeBalance()`**: View function to check the approximate total accumulated protocol fees held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Placeholder for ChronicleSBT interface, assuming it's an ERC721-like non-transferable token
interface IChronicleSBT {
    // A more direct way to get reputation score, as balanceOf for ERC721 typically means token count
    function getTotalReputation(address owner) external view returns (uint256);
    function awardReputation(address account, uint256 amount) external;
    function penalizeReputation(address account, uint256 amount) external;
    // In a full SBT implementation, tokenIds might represent badges, and reputation is a sum/score.
    // For simplicity, award/penalize directly adjust an abstract "reputation score" for the user.
}


/**
 * @title ChronicleOracleNetwork
 * @dev A decentralized oracle network for time-sensitive, subjective, and emergent event data.
 *      Integrates AI-assisted pre-evaluation, human verification by 'ChronicleKeepers',
 *      a reputation system powered by Soulbound Tokens (SBTs), and decentralized dispute resolution.
 *      Aims to provide reliable, nuanced data feeds beyond objective price information.
 *      The contract defines 27 functions as requested.
 */
contract ChronicleOracleNetwork is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Custom Errors ---
    error NotRegisteredKeeper();
    error AlreadyRegisteredKeeper();
    error InvalidStakeAmount();
    error EventNotFound();
    error EventNotActive();
    error EventAlreadyResolved();
    error DeadlinePassed();
    error Unauthorized();
    error InsufficientFee();
    error DisputeNotFound();
    error AlreadyAttested();
    error NoActiveDisputes(); // Also used for "Cool-off period not over" to generalize
    error NotEnoughReputation(uint256 required, uint256 has);
    error InvalidJurorVote();
    error EventNotReadyForResolution();
    error InvalidAttestation();
    error NoRewardsToClaim();
    error NotEnoughEligibleJurors();
    error DuplicateJurorSelection();

    // --- State Variables ---

    IChronicleSBT public chronicleSBT; // Address of the ChronicleSBT contract
    address public trustedOracleAddress; // Address of the trusted oracle that provides AI pre-evaluations

    uint256 public minKeeperStake; // Minimum ETH/native token stake required to be a ChronicleKeeper
    uint256 public keeperDeregisterCooloffPeriod; // Time period before a keeper can fully deregister
    uint256 public disputeResolutionPeriod; // Time allotted for jurors to vote
    uint256 public disputeJurorCount; // Number of jurors to select for a dispute
    uint256 public defaultEventQueryFee; // Default fee for proposing an event
    uint256 public protocolFeeShareNumerator; // Numerator for protocol fee share (e.g., 10 for 10%)
    uint256 public constant PROTOCOL_FEE_SHARE_DENOMINATOR = 100; // Denominator for protocol fee share (100 for 10%)

    uint256 public nextEventId;
    uint256 public nextDisputeId;

    // --- Structs ---

    enum EventStatus { Proposed, WaitingForFee, AwaitingAI, AwaitingAttestations, Disputed, Resolved, Cancelled }
    enum DisputeStatus { Active, Resolved, Tied }

    struct ChronicleEvent {
        address proposer;
        string descriptionURI; // URI to off-chain event description
        uint256 resolutionDeadline;
        uint256 minReputationForConsensus; // Min combined reputation required from attestors for consensus
        uint256 queryFeeAmount; // Total fee deposited by the proposer
        EventStatus status;
        bytes32 aiSuggestedOutcomeHash; // Hash of AI's suggested outcome
        uint256 aiConfidenceScore; // AI's confidence in its suggestion (e.g., 0-100)
        bytes32 finalOutcomeHash; // Hash of the final resolved outcome
        uint256 totalAttestationStake; // Total stake from keepers for this event
        mapping(address => bytes32) attestations; // Keeper address => attestation hash
        EnumerableSet.AddressSet activeAttestors; // Keep track of who attested to this event
    }

    struct ChronicleKeeper {
        uint256 stake; // Current staked amount
        uint256 rewardsAccumulated;
        uint256 lastDeregisterRequest; // Timestamp of deregister request, 0 if not requested
        bool isRegistered;
        string profileURI; // URI to off-chain keeper profile
    }

    struct Dispute {
        uint256 eventId;
        address disputer;
        bytes32 allegedOutcomeHash; // The outcome the disputer claims is correct
        string explanationURI; // URI to detailed explanation of the dispute
        uint256 disputerStake;
        uint256 defenderStake; // Can be from initial attestors or other parties supporting original outcome
        DisputeStatus status;
        uint256 resolutionDeadline; // Deadline for jurors to vote
        EnumerableSet.AddressSet jurors; // Set of addresses for selected jurors
        mapping(address => uint256) jurorVotes; // Juror address => vote choice (0 for disputer, 1 for defender)
        uint256 winningOutcomeIndex; // 0 for disputer, 1 for defender, 2 for tie
    }

    // --- Mappings ---
    mapping(uint256 => ChronicleEvent) public chronicleEvents;
    mapping(address => ChronicleKeeper) public chronicleKeepers;
    mapping(uint256 => Dispute) public disputes;
    EnumerableSet.AddressSet private _activeKeepers; // Set of all currently registered and active keepers

    // --- Events ---
    event ChronicleSBTContractUpdated(address indexed newAddress);
    event OracleAddressUpdated(address indexed newAddress);
    event MinKeeperStakeUpdated(uint256 newStake);
    event DefaultEventQueryFeeUpdated(uint256 newFee);
    event KeeperRegistered(address indexed keeper, uint256 stake);
    event KeeperDeregisterRequested(address indexed keeper, uint256 timestamp);
    event KeeperDeregistered(address indexed keeper);
    event EventProposed(uint256 indexed eventId, address indexed proposer, string descriptionURI, uint256 resolutionDeadline);
    event EventFeeDeposited(uint256 indexed eventId, address indexed depositor, uint256 amount);
    event EventCancelled(uint256 indexed eventId, address indexed canceller);
    event AIPreEvaluationReceived(uint256 indexed eventId, bytes32 aiSuggestedOutcomeHash, uint256 confidenceScore);
    event AttestationSubmitted(uint256 indexed eventId, address indexed keeper, bytes32 attestationHash, uint256 attestationStake);
    event EventResolved(uint256 indexed eventId, bytes32 finalOutcomeHash, uint256 protocolFee);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed eventId, address indexed disputer, bytes32 allegedOutcomeHash, uint256 disputerStake);
    event StakeForDispute(uint256 indexed disputeId, address indexed staker, uint256 amount);
    event JurorsSelected(uint256 indexed disputeId, address[] jurors);
    event JurorVoteSubmitted(uint256 indexed disputeId, address indexed juror, uint256 voteChoice);
    event DisputeResolved(uint256 indexed disputeId, uint256 winningOutcomeIndex);
    event RewardsClaimed(address indexed keeper, uint256 amount);
    event ProposerRefunded(uint256 indexed eventId, address indexed proposer, uint256 amount);
    event KeeperProfileUpdated(address indexed keeper, string profileURI);


    // --- Constructor ---
    /**
     * @dev Initializes the contract with the ChronicleSBT contract address and initial parameters.
     * @param _chronicleSBTAddress The address of the deployed ChronicleSBT contract.
     * @param _trustedOracleAddress The initial address of the trusted AI oracle.
     * @param _minKeeperStake The minimum stake required for a keeper.
     * @param _keeperDeregisterCooloffPeriod The cool-off period for keeper deregistration.
     * @param _disputeResolutionPeriod The time jurors have to vote.
     * @param _disputeJurorCount The number of jurors to select for disputes.
     * @param _defaultEventQueryFee The default fee for proposing events.
     * @param _protocolFeeShareNumerator The numerator for protocol fee percentage (e.g., 10 for 10%).
     */
    constructor(
        address _chronicleSBTAddress,
        address _trustedOracleAddress,
        uint256 _minKeeperStake,
        uint256 _keeperDeregisterCooloffPeriod,
        uint256 _disputeResolutionPeriod,
        uint256 _disputeJurorCount,
        uint256 _defaultEventQueryFee,
        uint256 _protocolFeeShareNumerator
    ) Ownable(msg.sender) {
        require(_chronicleSBTAddress != address(0), "Invalid SBT address");
        require(_trustedOracleAddress != address(0), "Invalid Oracle address");
        require(_minKeeperStake > 0, "Min stake must be > 0");
        require(_disputeJurorCount > 0, "Juror count must be > 0");
        require(_protocolFeeShareNumerator < PROTOCOL_FEE_SHARE_DENOMINATOR, "Invalid fee share");

        chronicleSBT = IChronicleSBT(_chronicleSBTAddress);
        trustedOracleAddress = _trustedOracleAddress;
        minKeeperStake = _minKeeperStake;
        keeperDeregisterCooloffPeriod = _keeperDeregisterCooloffPeriod;
        disputeResolutionPeriod = _disputeResolutionPeriod;
        disputeJurorCount = _disputeJurorCount;
        defaultEventQueryFee = _defaultEventQueryFee;
        protocolFeeShareNumerator = _protocolFeeShareNumerator;
        nextEventId = 1;
        nextDisputeId = 1;
    }

    // --- Modifier for Keeper status ---
    modifier onlyRegisteredKeeper() {
        if (!chronicleKeepers[msg.sender].isRegistered) {
            revert NotRegisteredKeeper();
        }
        _;
    }

    // --- I. Core Setup & Administration (5 functions) ---

    /**
     * @dev Allows the admin to update the address of the linked ChronicleSBT contract.
     * @param _newSBTAddress The new address of the ChronicleSBT contract.
     */
    function updateChronicleSBTContract(address _newSBTAddress) public onlyOwner {
        require(_newSBTAddress != address(0), "Invalid SBT address");
        chronicleSBT = IChronicleSBT(_newSBTAddress);
        emit ChronicleSBTContractUpdated(_newSBTAddress);
    }

    /**
     * @dev Sets the address of the trusted off-chain oracle that feeds AI pre-evaluations.
     * @param _newOracleAddress The new address of the trusted oracle.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "Invalid Oracle address");
        trustedOracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @dev Sets the minimum collateral amount required for a ChronicleKeeper to register.
     * @param _minStake The new minimum stake amount.
     */
    function setMinKeeperStake(uint256 _minStake) public onlyOwner {
        require(_minStake > 0, "Min stake must be > 0");
        minKeeperStake = _minStake;
        emit MinKeeperStakeUpdated(_minStake);
    }

    /**
     * @dev Sets the default fee for proposing an event.
     * @param _newDefaultFee The new default event query fee.
     */
    function setDefaultEventQueryFee(uint256 _newDefaultFee) public onlyOwner {
        defaultEventQueryFee = _newDefaultFee;
        emit DefaultEventQueryFeeUpdated(_newDefaultFee);
    }

    // --- II. Chronicle Event Management (7 functions) ---

    /**
     * @dev Allows any user to propose a new subjective event for resolution by the network.
     * @param _descriptionURI URI to off-chain event description.
     * @param _resolutionDeadline Timestamp by which the event should be resolved.
     * @param _minReputationForConsensus Minimum combined reputation required from attestors for consensus.
     * @return The ID of the newly proposed event.
     */
    function proposeChronicleEvent(
        string memory _descriptionURI,
        uint256 _resolutionDeadline,
        uint256 _minReputationForConsensus
    ) public returns (uint256) {
        require(bytes(_descriptionURI).length > 0, "Description URI cannot be empty");
        require(_resolutionDeadline > block.timestamp, "Resolution deadline must be in the future");
        require(_minReputationForConsensus > 0, "Min reputation for consensus must be > 0");

        uint256 eventId = nextEventId++;
        chronicleEvents[eventId].proposer = msg.sender;
        chronicleEvents[eventId].descriptionURI = _descriptionURI;
        chronicleEvents[eventId].resolutionDeadline = _resolutionDeadline;
        chronicleEvents[eventId].minReputationForConsensus = _minReputationForConsensus;
        chronicleEvents[eventId].queryFeeAmount = 0; // Will be set upon fee deposit
        chronicleEvents[eventId].status = EventStatus.WaitingForFee;
        // Mappings within structs are implicitly initialized
        // EnumerableSet.AddressSet is also implicitly initialized via storage

        emit EventProposed(eventId, msg.sender, _descriptionURI, _resolutionDeadline);
        return eventId;
    }

    /**
     * @dev Users deposit the required fee (in native token) to activate an event for resolution.
     *      The fee covers keeper rewards and protocol fees.
     * @param _eventId The ID of the event to deposit fees for.
     */
    function depositEventQueryFee(uint256 _eventId) public payable nonReentrant {
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.status != EventStatus.WaitingForFee) revert EventNotActive();
        if (msg.value < defaultEventQueryFee) revert InsufficientFee();

        event_.queryFeeAmount = msg.value;
        event_.status = EventStatus.AwaitingAI; // Move to next stage

        // An off-chain system would typically listen for EventFeeDeposited and call receiveAIPreEvaluation
        // via the trustedOracleAddress. `requestAIPreEvaluation` is a conceptual hook.

        emit EventFeeDeposited(_eventId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the event proposer to cancel their event if it hasn't been picked up by keepers
     *      or is past its deadline without resolution. Refunds remaining fees.
     * @param _eventId The ID of the event to cancel.
     */
    function cancelProposedEvent(uint256 _eventId) public nonReentrant {
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.proposer != msg.sender) revert Unauthorized();
        if (event_.status == EventStatus.Resolved || event_.status == EventStatus.Disputed || event_.status == EventStatus.Cancelled)
            revert EventAlreadyResolved();

        // Allow cancellation if still awaiting fee, or if past deadline without resolution
        bool canCancel = (event_.status == EventStatus.WaitingForFee) ||
                         (event_.status == EventStatus.AwaitingAI && block.timestamp > event_.resolutionDeadline) ||
                         (event_.status == EventStatus.AwaitingAttestations && block.timestamp > event_.resolutionDeadline && event_.activeAttestors.length() == 0);

        if (!canCancel) revert EventNotReadyForResolution();

        event_.status = EventStatus.Cancelled;

        // Refund any deposited fees
        if (event_.queryFeeAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: event_.queryFeeAmount}("");
            require(success, "Refund failed");
            emit ProposerRefunded(_eventId, msg.sender, event_.queryFeeAmount);
        }

        emit EventCancelled(_eventId, msg.sender);
    }

    /**
     * @dev View function to retrieve comprehensive details about a specific chronicle event.
     * @param _eventId The ID of the event.
     * @return Tuple containing event details.
     */
    function getEventDetails(uint256 _eventId)
        public
        view
        returns (
            address proposer,
            string memory descriptionURI,
            uint256 resolutionDeadline,
            uint256 minReputationForConsensus,
            uint256 queryFeeAmount,
            EventStatus status,
            bytes32 aiSuggestedOutcomeHash,
            uint256 aiConfidenceScore,
            bytes32 finalOutcomeHash,
            uint256 totalAttestationStake
        )
    {
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();

        return (
            event_.proposer,
            event_.descriptionURI,
            event_.resolutionDeadline,
            event_.minReputationForConsensus,
            event_.queryFeeAmount,
            event_.status,
            event_.aiSuggestedOutcomeHash,
            event_.aiConfidenceScore,
            event_.finalOutcomeHash,
            event_.totalAttestationStake
        );
    }

    /**
     * @dev Internal/Protocol function to conceptually trigger the off-chain AI oracle for initial analysis of an event.
     *      (This function serves as a conceptual hook; actual off-chain interaction
     *      would be handled by listening to `EventFeeDeposited` and `receiveAIPreEvaluation` being called by the oracle.)
     * @param _eventId The ID of the event to request AI pre-evaluation for.
     */
    function requestAIPreEvaluation(uint256 _eventId) internal view {
        // In a real system, this would not be callable directly on-chain but trigger an off-chain process.
        // An event like `EventAITriggered(eventId)` would be emitted here to notify off-chain systems.
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.status != EventStatus.AwaitingAI) revert EventNotReadyForResolution();
        // Here, an external system would pick up this event and call `trustedOracleAddress` to submit AI result.
    }

    /**
     * @dev Callable only by the trusted oracle, this function feeds the AI's preliminary analysis and confidence score
     *      for an event back into the contract. Requires an external proof for integrity.
     * @param _eventId The ID of the event for which AI data is provided.
     * @param _aiSuggestedOutcomeHash Hash of the AI's suggested outcome.
     * @param _confidenceScore AI's confidence level (e.g., 0-100).
     * @param _proof Cryptographic proof from the oracle (e.g., signature) for data integrity. (Placeholder)
     */
    function receiveAIPreEvaluation(
        uint256 _eventId,
        bytes32 _aiSuggestedOutcomeHash,
        uint256 _confidenceScore,
        bytes32 _proof // Placeholder for actual proof mechanism (e.g., Chainlink OCR)
    ) public {
        if (msg.sender != trustedOracleAddress) revert Unauthorized();
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.status != EventStatus.AwaitingAI) revert EventNotReadyForResolution();
        // In a production system, _proof would be verified here.

        event_.aiSuggestedOutcomeHash = _aiSuggestedOutcomeHash;
        event_.aiConfidenceScore = _confidenceScore;
        event_.status = EventStatus.AwaitingAttestations;

        emit AIPreEvaluationReceived(_eventId, _aiSuggestedOutcomeHash, _confidenceScore);
    }

    /**
     * @dev Internal/Protocol function that finalizes an event's resolution once sufficient consensus is reached
     *      by keepers, or the deadline is passed, distributes rewards, and updates reputation.
     *      This function can be triggered externally or internally if conditions are met.
     * @param _eventId The ID of the event to resolve.
     */
    function markEventResolved(uint256 _eventId) public nonReentrant {
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.status != EventStatus.AwaitingAttestations && event_.status != EventStatus.Disputed) revert EventNotReadyForResolution();
        if (event_.status == EventStatus.AwaitingAttestations && block.timestamp < event_.resolutionDeadline && event_.activeAttestors.length() == 0) return; // Not past deadline and no attestors yet

        bytes32 winningOutcome = event_.aiSuggestedOutcomeHash; // Default to AI if no human input/consensus
        uint256 maxVotes = 0;
        mapping(bytes32 => uint256) memory outcomeVotes; // Counts simple majority

        EnumerableSet.AddressSet memory currentAttestors = event_.activeAttestors;

        // Aggregate attestations
        for (uint256 i = 0; i < currentAttestors.length(); i++) {
            address keeper = currentAttestors.at(i);
            bytes32 attestation = event_.attestations[keeper];
            outcomeVotes[attestation]++;

            if (outcomeVotes[attestation] > maxVotes) {
                maxVotes = outcomeVotes[attestation];
                winningOutcome = attestation;
            }
        }

        // Apply a reputation weight to votes if desired. For simplicity, currently a simple majority,
        // or AI if no attestations / consensus. A more complex system would consider `minReputationForConsensus`.
        event_.finalOutcomeHash = winningOutcome;
        event_.status = EventStatus.Resolved;

        // Distribute rewards and adjust reputation
        uint256 totalPool = event_.queryFeeAmount;
        uint256 protocolFee = (totalPool * protocolFeeShareNumerator) / PROTOCOL_FEE_SHARE_DENOMINATOR;
        uint256 rewardsForKeepers = totalPool - protocolFee;

        if (event_.totalAttestationStake > 0) {
            for (uint256 i = 0; i < currentAttestors.length(); i++) {
                address keeper = currentAttestors.at(i);
                bytes32 attestation = event_.attestations[keeper];
                if (attestation == winningOutcome) {
                    // Reward for correct attestation proportional to stake in this event
                    chronicleKeepers[keeper].rewardsAccumulated += (rewardsForKeepers * chronicleKeepers[keeper].stake) / event_.totalAttestationStake;
                    chronicleSBT.awardReputation(keeper, 1); // Small reputation boost
                } else {
                    // Penalize for incorrect attestation
                    chronicleSBT.penalizeReputation(keeper, 1); // Small reputation penalty
                    // Losing stake could also be slashed/redistributed here
                }
            }
        }

        emit EventResolved(_eventId, winningOutcome, protocolFee);
    }

    // --- III. Chronicle Keeper Management (5 functions) ---

    /**
     * @dev Allows a user to stake a minimum amount of tokens to become a ChronicleKeeper.
     *      Requires sending `minKeeperStake` with the transaction.
     */
    function registerAsKeeper() public payable nonReentrant {
        if (chronicleKeepers[msg.sender].isRegistered) revert AlreadyRegisteredKeeper();
        if (msg.value < minKeeperStake) revert InvalidStakeAmount();

        chronicleKeepers[msg.sender].stake = msg.value;
        chronicleKeepers[msg.sender].isRegistered = true;
        _activeKeepers.add(msg.sender);

        emit KeeperRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Allows a ChronicleKeeper to unstake their collateral and leave the network after a cooling-off period,
     *      provided they have no active disputes.
     */
    function deregisterAsKeeper() public onlyRegisteredKeeper nonReentrant {
        ChronicleKeeper storage keeper = chronicleKeepers[msg.sender];
        if (keeper.lastDeregisterRequest == 0) {
            keeper.lastDeregisterRequest = block.timestamp;
            emit KeeperDeregisterRequested(msg.sender, block.timestamp);
            return; // Initiate cooldown
        }

        if (block.timestamp < keeper.lastDeregisterRequest + keeperDeregisterCooloffPeriod) {
            revert NoActiveDisputes(); // "Cool-off period not over"
        }
        // In a real system, would also check for active attestations or disputes.
        // For simplicity, we assume no active disputes after cool-off period.

        _activeKeepers.remove(msg.sender);
        keeper.isRegistered = false;
        keeper.lastDeregisterRequest = 0;

        (bool success, ) = payable(msg.sender).call{value: keeper.stake}("");
        require(success, "Deregister refund failed");
        keeper.stake = 0; // Clear stake after refund

        emit KeeperDeregistered(msg.sender);
    }

    /**
     * @dev ChronicleKeepers submit their subjective assessment/data for a pending event, along with a stake.
     *      Their stake acts as collateral against inaccurate attestations.
     * @param _eventId The ID of the event to attest to.
     * @param _attestationHash Hash of the keeper's assessment/outcome.
     */
    function submitEventAttestation(uint256 _eventId, bytes32 _attestationHash) public payable onlyRegisteredKeeper nonReentrant {
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.status != EventStatus.AwaitingAttestations) revert EventNotReadyForResolution();
        if (block.timestamp > event_.resolutionDeadline) revert DeadlinePassed();
        if (event_.attestations[msg.sender] != bytes32(0)) revert AlreadyAttested();
        if (msg.value < (minKeeperStake / 10)) revert InvalidStakeAmount(); // Example: small attestation stake (1/10 of min keeper stake)

        uint256 keeperReputation = chronicleSBT.getTotalReputation(msg.sender);
        if (keeperReputation == 0) revert NotEnoughReputation(1, 0); // Keepers need some reputation

        event_.attestations[msg.sender] = _attestationHash;
        event_.activeAttestors.add(msg.sender);
        event_.totalAttestationStake += msg.value;

        // Potentially, adjust keeper's stake temporarily to cover attestation
        // For simplicity, msg.value is just added to event's totalAttestationStake, not to keeper's main stake.

        emit AttestationSubmitted(_eventId, msg.sender, _attestationHash, msg.value);

        // Check for consensus and resolve if enough attestations and reputation.
        // This could be based on reputation-weighted sum, or just number of attestations.
        // For simplicity, we'll check if enough attestors are present OR if deadline passed.
        // This can be triggered by anyone after enough attestations or deadline.
        if (event_.activeAttestors.length() >= 3 || block.timestamp > event_.resolutionDeadline) { // Example threshold of 3 attestors
             markEventResolved(_eventId);
        }
    }

    /**
     * @dev Allows a ChronicleKeeper to update a URI pointing to their off-chain profile or credentials.
     * @param _profileURI The new URI for the keeper's profile.
     */
    function updateKeeperProfile(string memory _profileURI) public onlyRegisteredKeeper {
        chronicleKeepers[msg.sender].profileURI = _profileURI;
        emit KeeperProfileUpdated(msg.sender, _profileURI);
    }

    // --- IV. Reputation & SBT Integration (3 functions) ---

    /**
     * @dev View function to query the current reputation score (SBT balance) of a specific ChronicleKeeper.
     * @param _keeperAddress The address of the keeper.
     * @return The reputation score of the keeper.
     */
    function getKeeperReputation(address _keeperAddress) public view returns (uint256) {
        return chronicleSBT.getTotalReputation(_keeperAddress);
    }

    /**
     * @dev Internal/Protocol function to mint/increase ChronicleSBT for a keeper based on accurate attestations
     *      or successful dispute resolution.
     * @param _keeperAddress The address of the keeper to award reputation to.
     * @param _amount The amount of reputation to award.
     */
    function awardReputation(address _keeperAddress, uint256 _amount) internal {
        // This interacts directly with the ChronicleSBT contract.
        chronicleSBT.awardReputation(_keeperAddress, _amount);
        // An event could be emitted here for off-chain tracking
    }

    /**
     * @dev Internal/Protocol function to burn/decrease ChronicleSBT for a keeper due to inaccurate attestations
     *      or failed dispute claims.
     * @param _keeperAddress The address of the keeper to penalize.
     * @param _amount The amount of reputation to penalize.
     */
    function penalizeReputation(address _keeperAddress, uint256 _amount) internal {
        // This interacts directly with the ChronicleSBT contract.
        chronicleSBT.penalizeReputation(_keeperAddress, _amount);
        // An event could be emitted here for off-chain tracking
    }

    // --- V. Dispute Resolution System (5 functions) ---

    /**
     * @dev Allows any user or keeper to formally dispute a proposed outcome, an AI pre-evaluation, or a keeper's attestation for an event.
     *      The disputer must stake some funds.
     * @param _eventId The ID of the event being disputed.
     * @param _allegedOutcomeHash The outcome the disputer claims is correct.
     * @param _explanationURI URI to a detailed explanation of the dispute.
     * @return The ID of the newly created dispute.
     */
    function raiseDispute(
        uint256 _eventId,
        bytes32 _allegedOutcomeHash,
        string memory _explanationURI
    ) public payable nonReentrant returns (uint256) {
        ChronicleEvent storage event_ = chronicleEvents[_eventId];
        if (event_.proposer == address(0)) revert EventNotFound();
        if (event_.status == EventStatus.Resolved || event_.status == EventStatus.Cancelled) revert EventAlreadyResolved();
        if (msg.value == 0) revert InsufficientFee(); // Must stake something to raise a dispute

        event_.status = EventStatus.Disputed; // Event moves to disputed state

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId].eventId = _eventId;
        disputes[disputeId].disputer = msg.sender;
        disputes[disputeId].allegedOutcomeHash = _allegedOutcomeHash;
        disputes[disputeId].explanationURI = _explanationURI;
        disputes[disputeId].disputerStake = msg.value;
        disputes[disputeId].defenderStake = event_.totalAttestationStake; // Initial defender stake comes from attestors
        disputes[disputeId].status = DisputeStatus.Active;
        disputes[disputeId].resolutionDeadline = block.timestamp + disputeResolutionPeriod;
        // Jurors set implicitly.

        emit DisputeRaised(disputeId, _eventId, msg.sender, _allegedOutcomeHash, msg.value);
        return disputeId;
    }

    /**
     * @dev Parties involved in a dispute (disputer, defender) stake tokens to support their position.
     *      This allows original attestors to add more stake, or other interested parties to support the original outcome.
     * @param _disputeId The ID of the dispute to stake for.
     */
    function stakeForDispute(uint256 _disputeId) public payable nonReentrant {
        Dispute storage dispute_ = disputes[_disputeId];
        if (dispute_.disputer == address(0)) revert DisputeNotFound();
        if (dispute_.status != DisputeStatus.Active) revert EventAlreadyResolved(); // Dispute not active
        if (msg.value == 0) revert InvalidStakeAmount();

        if (msg.sender == dispute_.disputer) {
            dispute_.disputerStake += msg.value;
        } else {
            // Any other party can contribute to defender stake
            dispute_.defenderStake += msg.value;
        }

        emit StakeForDispute(_disputeId, msg.sender, msg.value);
    }

    /**
     * @dev Internal/Protocol function to algorithmically select a panel of high-reputation ChronicleKeepers to act as jurors for a dispute.
     *      Selection should be pseudo-random and reputation-weighted. Only callable by owner or trusted process.
     * @param _disputeId The ID of the dispute.
     */
    function selectJurors(uint256 _disputeId) public onlyOwner { // Made public for demonstration, but typically internal/protocol-triggered
        Dispute storage dispute_ = disputes[_disputeId];
        if (dispute_.disputer == address(0)) revert DisputeNotFound();
        if (dispute_.status != DisputeStatus.Active) revert EventAlreadyResolved();

        address[] memory eligibleKeepers = new address[](_activeKeepers.length());
        uint256 eligibleCount = 0;

        // Filter for active keepers with sufficient reputation, not involved in the event or dispute
        for (uint256 i = 0; i < _activeKeepers.length(); i++) {
            address keeper = _activeKeepers.at(i);
            // Exclude disputer and original attestors for impartiality
            if (keeper == dispute_.disputer || chronicleEvents[dispute_.eventId].activeAttestors.contains(keeper)) {
                continue;
            }
            // Require a minimum reputation to be a juror
            if (chronicleSBT.getTotalReputation(keeper) >= 10) { // Example: require min reputation score of 10
                eligibleKeepers[eligibleCount++] = keeper;
            }
        }

        require(eligibleCount >= disputeJurorCount, "Not enough eligible jurors");

        // Simple pseudo-random selection (NOT cryptographically secure; requires VRF for production)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, dispute_.eventId, eligibleCount)));
        for (uint256 i = 0; i < disputeJurorCount; i++) {
            uint256 randomIndex = (seed + i) % eligibleCount;
            address juror = eligibleKeepers[randomIndex];

            // Ensure unique jurors
            if (!dispute_.jurors.add(juror)) { // EnumerableSet.add returns false if element already exists
                revert DuplicateJurorSelection(); // Should not happen with careful selection or more robust logic
            }
            seed = uint256(keccak256(abi.encodePacked(seed, juror))); // Update seed for next selection
        }
        emit JurorsSelected(_disputeId, dispute_.jurors.values());
    }


    /**
     * @dev Selected jurors cast their vote on the disputed outcome.
     * @param _disputeId The ID of the dispute.
     * @param _choice The juror's vote (0 for disputer's claim, 1 for defender's claim/original outcome).
     */
    function submitJurorVote(uint256 _disputeId, uint256 _choice) public onlyRegisteredKeeper {
        Dispute storage dispute_ = disputes[_disputeId];
        if (dispute_.disputer == address(0)) revert DisputeNotFound();
        if (dispute_.status != DisputeStatus.Active) revert EventAlreadyResolved();
        if (block.timestamp > dispute_.resolutionDeadline) revert DeadlinePassed();
        if (!dispute_.jurors.contains(msg.sender)) revert Unauthorized(); // Not a selected juror
        if (dispute_.jurorVotes[msg.sender] != 0) revert AlreadyAttested(); // Already voted
        if (_choice != 0 && _choice != 1) revert InvalidJurorVote(); // Simple binary choice

        dispute_.jurorVotes[msg.sender] = _choice;
        emit JurorVoteSubmitted(_disputeId, msg.sender, _choice);
    }

    /**
     * @dev Internal/Protocol function to finalize a dispute, distribute staked funds, and adjust the reputation (SBTs)
     *      of involved parties and jurors based on the outcome. Callable by anyone after the resolution deadline.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) public nonReentrant {
        Dispute storage dispute_ = disputes[_disputeId];
        if (dispute_.disputer == address(0)) revert DisputeNotFound();
        if (dispute_.status != DisputeStatus.Active) revert EventAlreadyResolved();
        if (block.timestamp < dispute_.resolutionDeadline) revert EventNotReadyForResolution(); // Must be past voting deadline

        uint256 disputerVotes = 0;
        uint256 defenderVotes = 0;
        EnumerableSet.AddressSet memory currentJurors = dispute_.jurors;

        // Count votes
        for (uint256 i = 0; i < currentJurors.length(); i++) {
            address juror = currentJurors.at(i);
            if (dispute_.jurorVotes[juror] == 0) { // 0 for disputer's claim
                disputerVotes++;
            } else if (dispute_.jurorVotes[juror] == 1) { // 1 for defender's claim
                defenderVotes++;
            }
            // Jurors who didn't vote get no reward/penalty here.
        }

        uint256 winningOutcomeIndex; // 0: disputer, 1: defender, 2: tie
        address winnerAddress;
        address loserAddress;
        uint256 totalStaked = dispute_.disputerStake + dispute_.defenderStake;
        uint256 protocolFee = (totalStaked * protocolFeeShareNumerator) / PROTOCOL_FEE_SHARE_DENOMINATOR;
        uint256 rewardPool = totalStaked - protocolFee;

        if (disputerVotes > defenderVotes) {
            winningOutcomeIndex = 0; // Disputer wins
            winnerAddress = dispute_.disputer;
            // The losing stake from the defender side is now part of the reward pool
            chronicleEvents[dispute_.eventId].finalOutcomeHash = dispute_.allegedOutcomeHash; // Update event outcome
        } else if (defenderVotes > disputerVotes) {
            winningOutcomeIndex = 1; // Defender wins
            loserAddress = dispute_.disputer;
            // If defender wins, the event's original final outcome (if already set) stands, or defaults to AI
            if(chronicleEvents[dispute_.eventId].finalOutcomeHash == bytes32(0)) {
                chronicleEvents[dispute_.eventId].finalOutcomeHash = chronicleEvents[dispute_.eventId].aiSuggestedOutcomeHash;
            }
        } else {
            // Tie - stakes could be refunded or split. For simplicity, refund stakes to original contributors.
            (bool successDisputer, ) = payable(dispute_.disputer).call{value: dispute_.disputerStake}("");
            require(successDisputer, "Disputer refund failed on tie");

            // For defender's stake, it would need to be returned proportionally to contributors.
            // Simplified: if defender is the contract (representing multiple attestors), it stays.
            // A more complex system would map defender contributions. For now, it stays in contract.
            dispute_.status = DisputeStatus.Tied;
            emit DisputeResolved(_disputeId, 2); // 2 for tie
            return;
        }

        dispute_.winningOutcomeIndex = winningOutcomeIndex;
        dispute_.status = DisputeStatus.Resolved;
        chronicleEvents[dispute_.eventId].status = EventStatus.Resolved; // Mark event resolved based on dispute outcome

        // Distribute rewards and adjust reputation
        if (winningOutcomeIndex == 0) { // Disputer wins
            // Disputer gets their stake back + a share of the loser's stake as reward
            (bool success, ) = payable(dispute_.disputer).call{value: dispute_.disputerStake + (rewardPool * dispute_.disputerStake) / totalStaked}("");
            require(success, "Disputer reward failed");
            chronicleSBT.awardReputation(dispute_.disputer, 5); // Larger reputation boost for winning dispute
            // Penalize original attestors who were incorrect (this logic could be more complex, e.g. slash their attestation stake)
        } else { // Defender wins (Disputer loses)
            // Original attestors (if any) and jurors who voted correctly get rewards
            // For simplicity, jurors who voted correctly get rewarded from the dispute reward pool.
            uint256 rewardedJurorsCount = 0;
            for (uint256 i = 0; i < currentJurors.length(); i++) {
                if (dispute_.jurorVotes[currentJurors.at(i)] == winningOutcomeIndex) {
                    rewardedJurorsCount++;
                }
            }

            if (rewardedJurorsCount > 0) {
                for (uint256 i = 0; i < currentJurors.length(); i++) {
                    address juror = currentJurors.at(i);
                    if (dispute_.jurorVotes[juror] == winningOutcomeIndex) {
                        chronicleKeepers[juror].rewardsAccumulated += (rewardPool / rewardedJurorsCount); // Equal share for winning jurors
                        chronicleSBT.awardReputation(juror, 2); // Juror reputation boost
                    } else {
                        chronicleSBT.penalizeReputation(juror, 1); // Juror reputation penalty for incorrect vote
                    }
                }
            }
            chronicleSBT.penalizeReputation(dispute_.disputer, 5); // Larger penalty for losing dispute
        }

        emit DisputeResolved(_disputeId, winningOutcomeIndex);
    }

    // --- VI. Reward & Fee Management (2 functions) ---

    /**
     * @dev Allows ChronicleKeepers to claim their accumulated rewards from accurately resolved events
     *      and participating in dispute resolution.
     */
    function claimKeeperRewards() public onlyRegisteredKeeper nonReentrant {
        ChronicleKeeper storage keeper = chronicleKeepers[msg.sender];
        if (keeper.rewardsAccumulated == 0) revert NoRewardsToClaim();

        uint256 amountToClaim = keeper.rewardsAccumulated;
        keeper.rewardsAccumulated = 0;

        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Reward claim failed");

        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    /**
     * @dev View function to check the total accumulated protocol fees.
     *      Note: This is an approximation. A robust system would track `totalProtocolFees` in a dedicated state variable.
     * @return The approximate total amount of native token held by the contract as protocol fees.
     */
    function getProtocolFeeBalance() public view returns (uint256) {
        uint256 totalStakes = 0;
        for (uint256 i = 0; i < _activeKeepers.length(); i++) {
            totalStakes += chronicleKeepers[_activeKeepers.at(i)].stake;
        }

        // This is a highly simplified approximation. It returns the contract's total balance
        // minus all active keeper stakes. This does not precisely track "protocol fees"
        // as other funds might be held. A production system would manage this with a dedicated variable.
        return address(this).this.balance - totalStakes;
    }

    // --- Fallback & Receive ---
    receive() external payable {
        // Allow direct deposits, e.g., for general protocol funding or unexpected transfers.
        // These funds are not immediately tied to any event/stake unless explicitly assigned.
    }

    fallback() external payable {
        // Allow direct deposits for compatibility.
    }
}
```