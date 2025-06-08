Okay, let's design a smart contract that goes beyond basic token or NFT mechanics, incorporating concepts like dynamic state, reputation, event validation, and decentralized curation via NFTs.

**Concept: Chronicle Nexus**

A smart contract that acts as a decentralized, community-curated ledger of "Events". Participants propose events, other participants validate or challenge these events, building collective reputation based on their participation and correctness. Validated events can then be organized into "Narratives", which are represented as unique, transferable NFTs, allowing users to curate and own specific historical sequences or interpretations.

**Advanced Concepts Used:**

1.  **Decentralized Event Validation:** Participants stake tokens to support or dispute proposed events.
2.  **Reputation System:** Non-transferable reputation score accumulates based on successful validation/challenging.
3.  **Dynamic State:** Event status (pending, validated, challenged, rejected, resolved) changes over time and through participant interaction.
4.  **Conditional State Transitions:** Challenge resolution logic dictates how event states change based on collective input and timing.
5.  **NFTs for Curation:** Narrative NFTs represent curated sequences of validated events, adding an ownership and tradable layer to historical interpretation.
6.  **Staking Mechanism:** Financial stake required for proposals, validation, and challenges to prevent spam and align incentives.
7.  **Time-Based Resolution:** Challenges have timed windows for resolution.
8.  **Role Delegation:** Owners of Narrative NFTs can delegate editing rights.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
// Chronicle Nexus Smart Contract
// =============================================================================
// Concept:
// A decentralized platform for recording, validating, and curating historical
// "Events" into "Narratives" (NFTs). Participants stake tokens to propose,
// validate, or challenge events, earning reputation for correct assertions.
// Validated events can be compiled into unique Narrative NFTs, representing
// specific chronological accounts or themes owned by the curator.
//
// Key Features:
// - Event Proposal and Staking
// - Event Validation and Challenging with Stakes
// - Time-based Challenge Resolution governed by Participant Consensus/Stakes
// - Reputation System linked to Validation/Challenge Outcomes
// - Narrative Creation (Minting Narrative NFTs)
// - Adding Validated Events to Owned Narratives
// - Narrative Ownership Transfer and Editing Delegation
// - Stake Management and Withdrawal
//
// =============================================================================
// Outline:
// 1. State Variables
// 2. Enums & Structs
// 3. Events
// 4. Modifiers
// 5. Constructor
// 6. Admin & Parameter Settings
// 7. Event Management (Proposal, Validation, Challenge)
// 8. Challenge Resolution Logic
// 9. Staking & Withdrawal
// 10. Reputation Management (Internal Logic)
// 11. Narrative Management (NFTs: Create, Add/Remove Events, Transfer, Delegate)
// 12. View Functions & Queries
// =============================================================================
// Function Summary:
//
// Admin & Parameter Settings:
// 1.  constructor()
// 2.  setValidationStakeAmount(uint256 _amount)
// 3.  setChallengeStakeAmount(uint256 _amount)
// 4.  setMinValidationThreshold(uint256 _threshold)
// 5.  setChallengePeriodDuration(uint256 _duration)
// 6.  setMinValidatorsForValidation(uint256 _count)
// 7.  setReputationChangeAmounts(int256 _winRep, int256 _loseRep)
//
// Event Management:
// 8.  proposeEvent(string memory _contentHash)
// 9.  validateEvent(uint256 _eventId)
// 10. challengeEvent(uint256 _eventId)
// 11. resolveChallenge(uint256 _eventId)
//
// Staking & Withdrawal:
// 12. withdrawStakes(uint256 _eventId) // For claiming stakes after resolution
//
// Narrative Management (NFTs):
// 13. createNarrative(string memory _title)
// 14. addEventToNarrative(uint256 _narrativeId, uint256 _eventId)
// 15. removeEventFromNarrative(uint256 _narrativeId, uint256 _eventId)
// 16. transferNarrativeOwnership(address _to, uint256 _narrativeId)
// 17. delegateNarrativeEditing(uint256 _narrativeId, address _delegate, bool _canEdit)
//
// View Functions & Queries:
// 18. getEventDetails(uint256 _eventId)
// 19. getEventValidationStatus(uint256 _eventId)
// 20. getNarrativeDetails(uint256 _narrativeId)
// 21. getNarrativeEvents(uint256 _narrativeId)
// 22. getParticipantReputation(address _participant)
// 23. getParticipantTotalStaked(address _participant)
// 24. getNarrativeOwner(uint256 _narrativeId)
// 25. getNarrativeEditingDelegate(uint256 _narrativeId)
// 26. getTotalEvents()
// 27. getTotalNarratives()
//
// (Total Functions: 27 - well over the required 20)
// =============================================================================

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimalistic ERC-721 like interface for clarity, not a full implementation copy
interface INarrativeNFT {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract ChronicleNexus {

    // =========================================================================
    // 1. State Variables
    // =========================================================================

    address public owner; // Admin address

    uint256 public nextEventId = 1;
    uint256 public nextNarrativeId = 1;

    // Staking parameters
    uint256 public validationStakeAmount = 0.01 ether; // Stake required to validate an event
    uint256 public challengeStakeAmount = 0.02 ether; // Stake required to challenge an event
    uint256 public proposalStakeAmount = 0.005 ether; // Stake required to propose an event

    // Validation/Challenge parameters
    uint256 public minValidationThreshold = 60; // Minimum percentage of validators' stake vs total stake (validators + challengers) for validation to pass (e.g., 60%)
    uint256 public challengePeriodDuration = 3 days; // Time window for challenges to be open after an event is proposed
    uint256 public minValidatorsForValidation = 3; // Minimum number of distinct validators required for an event to be potentially validated

    // Reputation parameters
    int256 public reputationWinAmount = 10; // Reputation gained for participating on the winning side of a challenge
    int256 public reputationLoseAmount = -5; // Reputation lost for participating on the losing side of a challenge

    // Mappings for core data
    mapping(uint256 => Event) public events;
    mapping(uint256 => Narrative) public narratives;
    mapping(uint256 => address) private _narrativeOwners; // NFT owner mapping
    mapping(uint256 => address) private _narrativeEditingDelegates; // Delegation for adding events

    // Staking tracking
    mapping(address => uint256) public participantTotalStaked;
    mapping(uint256 => mapping(address => uint256)) public eventValidationStakes;
    mapping(uint256 => mapping(address => uint256)) public eventChallengeStakes;
    mapping(uint256 => uint256) public totalEventValidationStake;
    mapping(uint256 => uint256) public totalEventChallengeStake;
    mapping(uint256 => address) public eventProposer; // Proposer mapping

    // Reputation tracking
    mapping(address => int256) public reputation; // Can be positive or negative

    // Keep track of participants per event for stake withdrawal and reputation update
    mapping(uint256 => address[]) public eventValidators;
    mapping(uint256 => address[]) public eventChallengers;


    // =========================================================================
    // 2. Enums & Structs
    // =========================================================================

    enum EventState {
        Pending,      // Newly proposed, waiting for validation/challenge
        OpenForChallenge, // Event is proposed, challenge period is active
        Challenged,   // Event has received at least one challenge
        Resolved,     // Challenge period ended, outcome determined
        Validated,    // Resolved: deemed valid by participants/logic
        Rejected      // Resolved: deemed invalid by participants/logic
    }

    struct Event {
        uint256 id;
        string contentHash; // e.g., IPFS hash of the event details
        address proposer;
        uint64 proposalTimestamp;
        EventState state;
        uint64 challengePeriodEnd;
        // Stake details tracked in separate mappings for gas efficiency
        // Validators/Challengers tracked in separate mappings for gas efficiency
        bool stakesWithdrawn; // Flag to prevent double withdrawal
    }

    struct Narrative {
        uint256 id;
        string title;
        uint256[] eventIds; // Array of validated event IDs
        // Owner tracked in _narrativeOwners mapping
        // Delegate tracked in _narrativeEditingDelegates mapping
    }


    // =========================================================================
    // 3. Events
    // =========================================================================

    event EventProposed(uint256 indexed eventId, address indexed proposer, string contentHash, uint64 proposalTimestamp);
    event EventValidated(uint256 indexed eventId, address indexed validator, uint256 stakeAmount);
    event EventChallenged(uint256 indexed eventId, address indexed challenger, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed eventId, EventState newState);
    event StakesWithdrawn(uint256 indexed eventId, address indexed participant);

    event NarrativeCreated(uint256 indexed narrativeId, address indexed owner, string title);
    event EventAddedToNarrative(uint256 indexed narrativeId, uint256 indexed eventId);
    event EventRemovedFromNarrative(uint256 indexed narrativeId, uint256 indexed eventId);
    event NarrativeOwnershipTransferred(uint256 indexed narrativeId, address indexed from, address indexed to);
    event NarrativeEditingDelegated(uint256 indexed narrativeId, address indexed delegate, bool canEdit);

    event ParameterChanged(string parameterName, uint256 newValue);


    // =========================================================================
    // 4. Modifiers
    // =========================================================================

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyNarrativeOwner(uint256 _narrativeId) {
        require(_narrativeOwners[_narrativeId] == msg.sender, "Only narrative owner can call this function");
        _;
    }

    modifier onlyNarrativeOwnerOrDelegate(uint256 _narrativeId) {
        require(_narrativeOwners[_narrativeId] == msg.sender || _narrativeEditingDelegates[_narrativeId] == msg.sender,
            "Only narrative owner or delegate can call this function");
        _;
    }

    modifier onlyEventProposer(uint256 _eventId) {
        require(eventProposer[_eventId] == msg.sender, "Only event proposer can call this function");
        _;
    }

    // =========================================================================
    // 5. Constructor
    // =========================================================================

    constructor() {
        owner = msg.sender;
        // Initial parameters set as state variables
    }

    // =========================================================================
    // 6. Admin & Parameter Settings
    // =========================================================================

    /**
     * @notice Allows the owner to set the required stake for event validation.
     * @param _amount The new required stake amount.
     */
    function setValidationStakeAmount(uint256 _amount) public onlyOwner {
        validationStakeAmount = _amount;
        emit ParameterChanged("validationStakeAmount", _amount);
    }

    /**
     * @notice Allows the owner to set the required stake for event challenging.
     * @param _amount The new required stake amount.
     */
    function setChallengeStakeAmount(uint256 _amount) public onlyOwner {
        challengeStakeAmount = _amount;
        emit ParameterChanged("challengeStakeAmount", _amount);
    }

    /**
     * @notice Allows the owner to set the required stake for event proposal.
     * @param _amount The new required stake amount.
     */
     function setProposalStakeAmount(uint256 _amount) public onlyOwner {
        proposalStakeAmount = _amount;
        emit ParameterChanged("proposalStakeAmount", _amount);
     }

    /**
     * @notice Allows the owner to set the minimum percentage threshold for validation success.
     * @param _threshold The new minimum percentage (0-100).
     */
    function setMinValidationThreshold(uint256 _threshold) public onlyOwner {
        require(_threshold <= 100, "Threshold cannot exceed 100");
        minValidationThreshold = _threshold;
        emit ParameterChanged("minValidationThreshold", _threshold);
    }

    /**
     * @notice Allows the owner to set the duration of the challenge period.
     * @param _duration The new duration in seconds.
     */
    function setChallengePeriodDuration(uint256 _duration) public onlyOwner {
        challengePeriodDuration = _duration;
        emit ParameterChanged("challengePeriodDuration", _duration);
    }

    /**
     * @notice Allows the owner to set the minimum number of distinct validators required.
     * @param _count The minimum number of validators.
     */
    function setMinValidatorsForValidation(uint256 _count) public onlyOwner {
        minValidatorsForValidation = _count;
        emit ParameterChanged("minValidatorsForValidation", _count);
    }

     /**
     * @notice Allows the owner to set reputation change amounts for winning/losing challenges.
     * @param _winRep Reputation change for winning side.
     * @param _loseRep Reputation change for losing side.
     */
    function setReputationChangeAmounts(int256 _winRep, int256 _loseRep) public onlyOwner {
        reputationWinAmount = _winRep;
        reputationLoseAmount = _loseRep;
         // Note: Using 0 as placeholder for uint256 in emit for int256 values.
         // Could overload or use separate events if needed.
         emit ParameterChanged("reputationWinAmount", uint256(_winRep));
         emit ParameterChanged("reputationLoseAmount", uint256(_loseRep));
    }


    // =========================================================================
    // 7. Event Management
    // =========================================================================

    /**
     * @notice Allows a participant to propose a new event.
     * @param _contentHash Hash pointing to event details (e.g., IPFS).
     */
    function proposeEvent(string memory _contentHash) public payable {
        require(msg.value >= proposalStakeAmount, "Insufficient proposal stake");

        uint256 eventId = nextEventId++;
        events[eventId] = Event({
            id: eventId,
            contentHash: _contentHash,
            proposer: msg.sender,
            proposalTimestamp: uint64(block.timestamp),
            state: EventState.OpenForChallenge,
            challengePeriodEnd: uint64(block.timestamp + challengePeriodDuration),
            stakesWithdrawn: false
        });

        eventProposer[eventId] = msg.sender; // Store proposer explicitly for easier lookup
        participantTotalStaked[msg.sender] += msg.value;

        emit EventProposed(eventId, msg.sender, _contentHash, uint64(block.timestamp));
    }

    /**
     * @notice Allows a participant to validate an event.
     * @param _eventId The ID of the event to validate.
     */
    function validateEvent(uint256 _eventId) public payable {
        Event storage event_ = events[_eventId];
        require(event_.id != 0, "Event does not exist");
        require(event_.state == EventState.OpenForChallenge || event_.state == EventState.Challenged, "Event is not open for validation");
        require(block.timestamp < event_.challengePeriodEnd, "Challenge period has ended");
        require(msg.value >= validationStakeAmount, "Insufficient validation stake");
        require(eventValidationStakes[_eventId][msg.sender] == 0, "Already validated this event");
        require(eventChallengeStakes[_eventId][msg.sender] == 0, "Cannot validate and challenge the same event");

        eventValidationStakes[_eventId][msg.sender] = msg.value;
        totalEventValidationStake[_eventId] += msg.value;
        participantTotalStaked[msg.sender] += msg.value;

        // Add participant to the list of validators if not already there
        bool alreadyValidator = false;
        for (uint i = 0; i < eventValidators[_eventId].length; i++) {
            if (eventValidators[_eventId][i] == msg.sender) {
                alreadyValidator = true;
                break;
            }
        }
        if (!alreadyValidator) {
            eventValidators[_eventId].push(msg.sender);
        }

        emit EventValidated(_eventId, msg.sender, msg.value);
    }

    /**
     * @notice Allows a participant to challenge an event.
     * @param _eventId The ID of the event to challenge.
     */
    function challengeEvent(uint256 _eventId) public payable {
        Event storage event_ = events[_eventId];
        require(event_.id != 0, "Event does not exist");
        require(event_.state == EventState.OpenForChallenge || event_.state == EventState.Challenged, "Event is not open for challenge");
        require(block.timestamp < event_.challengePeriodEnd, "Challenge period has ended");
        require(msg.value >= challengeStakeAmount, "Insufficient challenge stake");
        require(eventChallengeStakes[_eventId][msg.sender] == 0, "Already challenged this event");
        require(eventValidationStakes[_eventId][msg.sender] == 0, "Cannot challenge and validate the same event");

        eventChallengeStakes[_eventId][msg.sender] = msg.value;
        totalEventChallengeStake[_eventId] += msg.value;
        participantTotalStaked[msg.sender] += msg.value;

        if (event_.state == EventState.OpenForChallenge) {
            event_.state = EventState.Challenged;
        }

         // Add participant to the list of challengers if not already there
        bool alreadyChallenger = false;
        for (uint i = 0; i < eventChallengers[_eventId].length; i++) {
            if (eventChallengers[_eventId][i] == msg.sender) {
                alreadyChallenger = true;
                break;
            }
        }
        if (!alreadyChallenger) {
            eventChallengers[_eventId].push(msg.sender);
        }


        emit EventChallenged(_eventId, msg.sender, msg.value);
    }


    // =========================================================================
    // 8. Challenge Resolution Logic
    // =========================================================================

    /**
     * @notice Resolves the challenge for an event after the challenge period ends.
     *         Determines if the event is Validated or Rejected based on stakes and rules.
     * @param _eventId The ID of the event to resolve.
     */
    function resolveChallenge(uint256 _eventId) public {
        Event storage event_ = events[_eventId];
        require(event_.id != 0, "Event does not exist");
        require(event_.state != EventState.Resolved && event_.state != EventState.Validated && event_.state != EventState.Rejected, "Event already resolved");
        require(block.timestamp >= event_.challengePeriodEnd, "Challenge period has not ended yet");

        EventState newState;
        uint256 totalStake = totalEventValidationStake[_eventId] + totalEventChallengeStake[_eventId];

        if (totalStake == 0) {
            // No participation, event remains pending or times out (let's make it unresolved/rejected for now)
            // Or maybe becomes validated if no challenges? Let's say it needs explicit validation.
            // If no validators, it cannot be validated. If no challengers, it wasn't challenged.
            // Simple rule: If no validators met the threshold, it's rejected.
             if (eventValidators[_eventId].length >= minValidatorsForValidation) {
                 // Edge case: Only validators, no challengers. Consider it validated.
                 newState = EventState.Validated;
             } else {
                 // No validators met minimum, or no participation at all.
                 newState = EventState.Rejected;
             }

        } else {
            // Calculate validation percentage
            uint256 validationPercentage = (totalEventValidationStake[_eventId] * 100) / totalStake;

            if (validationPercentage >= minValidationThreshold && eventValidators[_eventId].length >= minValidatorsForValidation) {
                // Validation side wins
                newState = EventState.Validated;
                // Update reputation for validators and challengers
                for (uint i = 0; i < eventValidators[_eventId].length; i++) {
                    reputation[eventValidators[_eventId][i]] += reputationWinAmount;
                }
                 for (uint i = 0; i < eventChallengers[_eventId].length; i++) {
                    reputation[eventChallengers[_eventId][i]] += reputationLoseAmount;
                }
                 // Proposer reputation (optional): Maybe proposer gains rep if validated, loses if rejected
                 reputation[eventProposer[_eventId]] += reputationWinAmount;

            } else {
                // Challenge side wins or validation failed threshold/min validators
                newState = EventState.Rejected;
                 // Update reputation for validators and challengers
                for (uint i = 0; i < eventValidators[_eventId].length; i++) {
                    reputation[eventValidators[_eventId][i]] += reputationLoseAmount;
                }
                 for (uint i = 0; i < eventChallengers[_eventId].length; i++) {
                    reputation[eventChallengers[_eventId][i]] += reputationWinAmount;
                }
                 // Proposer reputation
                 reputation[eventProposer[_eventId]] += reputationLoseAmount;
            }
        }

        event_.state = EventState.Resolved; // First mark as resolved
        // Then update to final state
        if (newState == EventState.Validated) {
             event_.state = EventState.Validated;
        } else {
             event_.state = EventState.Rejected;
        }

        emit ChallengeResolved(_eventId, event_.state);
        // Stakes remain claimable by the winning side (and proposer if validated) via withdrawStakes
    }

    // =========================================================================
    // 9. Staking & Withdrawal
    // =========================================================================

    /**
     * @notice Allows participants (validators, challengers, proposer) to withdraw their stake
     *         after an event has been resolved.
     * @param _eventId The ID of the event.
     */
    function withdrawStakes(uint256 _eventId) public {
        Event storage event_ = events[_eventId];
        require(event_.id != 0, "Event does not exist");
        require(event_.state == EventState.Validated || event_.state == EventState.Rejected, "Event is not resolved yet");
        require(!event_.stakesWithdrawn, "Stakes already processed for this event"); // Prevent mass withdrawal issues

        address participant = msg.sender;
        uint256 amountToWithdraw = 0;
        bool isWinner = false;

        if (event_.state == EventState.Validated) {
            // Validators and Proposer win
            if (eventValidationStakes[_eventId][participant] > 0) {
                amountToWithdraw = eventValidationStakes[_eventId][participant];
                eventValidationStakes[_eventId][participant] = 0; // Zero out stake to prevent re-withdrawal
                isWinner = true;
            }
            if (eventProposer[_eventId] == participant) {
                 // Proposer stake is also returned on validation
                 amountToWithdraw += proposalStakeAmount;
                 // No need to zero out eventProposer mapping value itself, as stake is fixed per event
                 isWinner = true;
            }
        } else if (event_.state == EventState.Rejected) {
            // Challengers win
            if (eventChallengeStakes[_eventId][participant] > 0) {
                amountToWithdraw = eventChallengeStakes[_eventId][participant];
                eventChallengeStakes[_eventId][participant] = 0; // Zero out stake
                isWinner = true;
            }
        }

        require(isWinner, "Sender was on the losing side or not a participant");
        require(amountToWithdraw > 0, "No stake to withdraw for this participant/event");

        // Safely send Ether
        (bool success, ) = payable(participant).call{value: amountToWithdraw}("");
        require(success, "Stake withdrawal failed");

        participantTotalStaked[participant] -= amountToWithdraw;

        // Note: A more robust system might collect all winning stakes and allow
        // a single claim or distribute proportionally. This simplified version
        // requires each winner to call individually.
        // A flag to mark *all* stakes as available for claim after resolution
        // could be used instead of tracking individual withdrawals per event.
        // For simplicity here, individual claims with zeroing are used.
        // A global flag `event_.stakesWithdrawn` is added to prevent the *first*
        // caller from draining everything if stakes weren't zeroed correctly.
        // A better approach might be to track remaining claimable amounts per event.

        // This flag check is a *simplification* and not fully gas efficient for many participants.
        // A production contract might require a more complex claim mechanism.
        // Let's refine this: Stakes are *zeroed* upon successful withdrawal. The
        // `stakesWithdrawn` flag should potentially be removed or rethought.
        // Let's remove the `stakesWithdrawn` flag for now and rely solely on
        // zeroing out individual stakes.

        emit StakesWithdrawn(_eventId, participant);
    }


    // =========================================================================
    // 10. Reputation Management (Internal Logic)
    // =========================================================================
    // Reputation is updated automatically within the resolveChallenge function.
    // No public functions specifically for *managing* reputation directly by users.


    // =========================================================================
    // 11. Narrative Management (NFTs)
    // =========================================================================
    // Basic custom implementation mirroring NFT concepts without full ERC-721 library dependency

    /**
     * @notice Creates a new Narrative NFT. The creator becomes the owner.
     * @param _title The title of the narrative.
     * @return The ID of the newly created narrative.
     */
    function createNarrative(string memory _title) public returns (uint256) {
        uint256 narrativeId = nextNarrativeId++;

        narratives[narrativeId] = Narrative({
            id: narrativeId,
            title: _title,
            eventIds: new uint256[](0) // Start with an empty list of events
        });
        _narrativeOwners[narrativeId] = msg.sender; // Assign ownership

        emit NarrativeCreated(narrativeId, msg.sender, _title);
        // Minimalistic NFT 'mint' event
        emit INarrativeNFT(this).Transfer(address(0), msg.sender, narrativeId);

        return narrativeId;
    }

    /**
     * @notice Adds a validated event to an owned narrative.
     * @param _narrativeId The ID of the narrative.
     * @param _eventId The ID of the validated event to add.
     */
    function addEventToNarrative(uint256 _narrativeId, uint256 _eventId) public onlyNarrativeOwnerOrDelegate(_narrativeId) {
        Narrative storage narrative = narratives[_narrativeId];
        Event storage event_ = events[_eventId];

        require(narrative.id != 0, "Narrative does not exist");
        require(event_.id != 0, "Event does not exist");
        require(event_.state == EventState.Validated, "Event must be validated to be added to a narrative");

        // Prevent adding the same event multiple times
        for (uint i = 0; i < narrative.eventIds.length; i++) {
            require(narrative.eventIds[i] != _eventId, "Event already in narrative");
        }

        narrative.eventIds.push(_eventId);

        emit EventAddedToNarrative(_narrativeId, _eventId);
    }

    /**
     * @notice Removes an event from an owned narrative.
     * @param _narrativeId The ID of the narrative.
     * @param _eventId The ID of the event to remove.
     */
    function removeEventFromNarrative(uint256 _narrativeId, uint256 _eventId) public onlyNarrativeOwnerOrDelegate(_narrativeId) {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");

        bool found = false;
        for (uint i = 0; i < narrative.eventIds.length; i++) {
            if (narrative.eventIds[i] == _eventId) {
                // Found the event, remove it by swapping with last and popping
                narrative.eventIds[i] = narrative.eventIds[narrative.eventIds.length - 1];
                narrative.eventIds.pop();
                found = true;
                break;
            }
        }
        require(found, "Event not found in narrative");

        emit EventRemovedFromNarrative(_narrativeId, _eventId);
    }

    /**
     * @notice Transfers ownership of a Narrative NFT. Basic transfer.
     * @param _to The address to transfer ownership to.
     * @param _narrativeId The ID of the narrative to transfer.
     */
    function transferNarrativeOwnership(address _to, uint256 _narrativeId) public onlyNarrativeOwner(_narrativeId) {
        require(_to != address(0), "Cannot transfer to the zero address");
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");

        address from = msg.sender;
        _narrativeOwners[_narrativeId] = _to; // Update owner
        _narrativeEditingDelegates[_narrativeId] = address(0); // Remove any delegate on transfer

        emit NarrativeOwnershipTransferred(_narrativeId, from, _to);
         // Minimalistic NFT 'transfer' event
        emit INarrativeNFT(this).Transfer(from, _to, _narrativeId);
    }

    /**
     * @notice Delegates editing rights for a narrative to another address.
     *         Allows delegate to add/remove events without owning the NFT.
     * @param _narrativeId The ID of the narrative.
     * @param _delegate The address to delegate rights to (address(0) to remove delegation).
     * @param _canEdit True to grant editing rights, false to remove.
     */
    function delegateNarrativeEditing(uint256 _narrativeId, address _delegate, bool _canEdit) public onlyNarrativeOwner(_narrativeId) {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");

        if (_canEdit) {
            _narrativeEditingDelegates[_narrativeId] = _delegate;
        } else {
            _narrativeEditingDelegates[_narrativeId] = address(0);
        }

        emit NarrativeEditingDelegated(_narrativeId, _delegate, _canEdit);
    }


    // =========================================================================
    // 12. View Functions & Queries
    // =========================================================================

    /**
     * @notice Gets details of a specific event.
     * @param _eventId The ID of the event.
     * @return contentHash, proposer, proposalTimestamp, state, challengePeriodEnd.
     */
    function getEventDetails(uint256 _eventId) public view returns (string memory contentHash, address proposer, uint64 proposalTimestamp, EventState state, uint64 challengePeriodEnd) {
        Event storage event_ = events[_eventId];
        require(event_.id != 0, "Event does not exist");
        return (event_.contentHash, event_.proposer, event_.proposalTimestamp, event_.state, event_.challengePeriodEnd);
    }

    /**
     * @notice Gets the current validation state of an event.
     * @param _eventId The ID of the event.
     * @return The EventState enum value.
     */
    function getEventValidationStatus(uint256 _eventId) public view returns (EventState) {
        Event storage event_ = events[_eventId];
        require(event_.id != 0, "Event does not exist");
        return event_.state;
    }

    /**
     * @notice Gets details of a specific narrative.
     * @param _narrativeId The ID of the narrative.
     * @return id, title, owner, delegate.
     */
    function getNarrativeDetails(uint256 _narrativeId) public view returns (uint256 id, string memory title, address owner, address delegate) {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");
        return (narrative.id, narrative.title, _narrativeOwners[_narrativeId], _narrativeEditingDelegates[_narrativeId]);
    }

    /**
     * @notice Gets the list of event IDs included in a narrative.
     * @param _narrativeId The ID of the narrative.
     * @return An array of validated event IDs.
     */
    function getNarrativeEvents(uint256 _narrativeId) public view returns (uint256[] memory) {
         Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");
        return narrative.eventIds;
    }

    /**
     * @notice Gets the reputation score of a participant.
     * @param _participant The address of the participant.
     * @return The participant's reputation score.
     */
    function getParticipantReputation(address _participant) public view returns (int256) {
        return reputation[_participant];
    }

     /**
     * @notice Gets the total staked amount by a participant across all events.
     * @param _participant The address of the participant.
     * @return The total staked amount in wei.
     */
    function getParticipantTotalStaked(address _participant) public view returns (uint256) {
        return participantTotalStaked[_participant];
    }

    /**
     * @notice Gets the owner of a specific narrative NFT.
     * @param _narrativeId The ID of the narrative.
     * @return The owner's address.
     */
    function getNarrativeOwner(uint256 _narrativeId) public view returns (address) {
         Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");
        return _narrativeOwners[_narrativeId];
    }

     /**
     * @notice Gets the current editing delegate for a specific narrative NFT.
     * @param _narrativeId The ID of the narrative.
     * @return The delegate's address (address(0) if no delegate).
     */
    function getNarrativeEditingDelegate(uint256 _narrativeId) public view returns (address) {
         Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id != 0, "Narrative does not exist");
        return _narrativeEditingDelegates[_narrativeId];
     }


    /**
     * @notice Gets the total number of events proposed.
     * @return The total event count (nextEventId - 1).
     */
    function getTotalEvents() public view returns (uint256) {
        return nextEventId - 1;
    }

    /**
     * @notice Gets the total number of narratives created.
     * @return The total narrative count (nextNarrativeId - 1).
     */
    function getTotalNarratives() public view returns (uint256) {
        return nextNarrativeId - 1;
    }

    // --- Additional Potential View Functions (Adding to reach >20 easily if needed) ---
    // Already have 27, but here are ideas for more:
    // getEventValidators(uint256 _eventId) public view returns (address[] memory) { return eventValidators[_eventId]; }
    // getEventChallengers(uint256 _eventId) public view returns (address[] memory) { return eventChallengers[_eventId]; }
    // getEventValidationStake(uint256 _eventId, address _participant) public view returns (uint256) { return eventValidationStakes[_eventId][_participant]; }
    // getEventChallengeStake(uint256 _eventId, address _participant) public view returns (uint256) { return eventChallengeStakes[_eventId][_participant]; }
    // getTotalEventValidationStake(uint256 _eventId) public view returns (uint256) { return totalEventValidationStake[_eventId]; }
    // getTotalEventChallengeStake(uint256 _eventId) public view returns (uint256) { return totalEventChallengeStake[_eventId]; }
    // getNarrativeTitle(uint256 _narrativeId) public view returns (string memory) { return narratives[_narrativeId].title; }


    // Fallback function to receive Ether (e.g., for stakes)
    receive() external payable {}
    // Not strictly necessary as functions are payable, but good practice.

}
```