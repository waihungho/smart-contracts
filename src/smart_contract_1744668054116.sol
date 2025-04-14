```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Tournament Platform (DATP)
 * @author Bard (Google AI)
 * @dev A sophisticated smart contract for managing decentralized tournaments with advanced features.
 *
 * **Outline & Function Summary:**
 *
 * **1. Tournament Management:**
 *    - `createTournament(string _name, uint256 _entryFee, uint256 _startTime, uint256 _endTime, uint256 _maxParticipants, address _prizeToken, uint256[] _prizeDistribution)`: Allows admin to create a new tournament.
 *    - `cancelTournament(uint256 _tournamentId)`: Allows admin to cancel a tournament before it starts, refunding participants.
 *    - `updateTournamentDetails(uint256 _tournamentId, string _name, uint256 _entryFee, uint256 _startTime, uint256 _endTime, uint256 _maxParticipants, address _prizeToken, uint256[] _prizeDistribution)`: Allows admin to update tournament details before it starts.
 *    - `startTournament(uint256 _tournamentId)`: Manually starts a tournament if conditions are met (e.g., minimum participants).
 *    - `endTournament(uint256 _tournamentId)`: Manually ends a tournament, triggering result submission and prize distribution.
 *    - `pauseTournament(uint256 _tournamentId)`: Allows admin to pause a running tournament for emergency or maintenance.
 *    - `resumeTournament(uint256 _tournamentId)`: Allows admin to resume a paused tournament.
 *
 * **2. Participant Interaction:**
 *    - `registerForTournament(uint256 _tournamentId)`: Allows users to register and pay the entry fee for a tournament.
 *    - `unregisterFromTournament(uint256 _tournamentId)`: Allows users to unregister from a tournament before it starts, getting a refund.
 *    - `submitResult(uint256 _tournamentId, string _resultData)`: Allows participants to submit their tournament result data (e.g., game score, submission link).
 *    - `reportDispute(uint256 _tournamentId, uint256 _participantId, string _disputeReason)`: Allows participants to report a dispute against another participant's result.
 *    - `voteOnDispute(uint256 _tournamentId, uint256 _disputeId, bool _vote)`: Allows registered participants to vote on open disputes.
 *
 * **3. Result & Prize Management:**
 *    - `validateResult(uint256 _tournamentId, uint256 _participantId)`: Allows admin/moderators to manually validate a participant's result.
 *    - `finalizeResults(uint256 _tournamentId)`: Finalizes the results after validation and dispute resolution, preparing for prize distribution.
 *    - `distributePrizes(uint256 _tournamentId)`: Distributes prizes to winners according to the prize distribution structure.
 *    - `claimPrize(uint256 _tournamentId)`: Allows winners to claim their earned prizes.
 *
 * **4. Platform Governance & Features:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows platform admin to set a platform fee percentage on tournament entry fees.
 *    - `withdrawPlatformFees()`: Allows platform admin to withdraw accumulated platform fees.
 *    - `addModerator(address _moderatorAddress)`: Allows platform admin to add a moderator address.
 *    - `removeModerator(address _moderatorAddress)`: Allows platform admin to remove a moderator address.
 *    - `setDisputeVotingDuration(uint256 _durationInSeconds)`: Allows platform admin to set the duration for dispute voting.
 *    - `toggleTournamentRegistrationLock(uint256 _tournamentId)`: Allows admin to manually lock or unlock registration for a tournament.
 *
 * **Advanced Concepts & Creativity:**
 * - **Decentralized Dispute Resolution:** Incorporates a voting mechanism for participants to resolve disputes, moving beyond purely admin-controlled systems.
 * - **Dynamic Prize Distribution:** Prize distribution is flexible and can be defined at tournament creation, supporting various prize structures.
 * - **Platform Fees & Revenue Model:** Integrates a platform fee mechanism, providing a sustainable revenue model for the tournament platform.
 * - **Tournament Lifecycle Management:** Implements a comprehensive tournament lifecycle with states (creation, registration, running, ended, finalized, cancelled, paused) and functions to manage each stage.
 * - **Moderation & Governance:** Introduces moderator roles and platform governance functions, allowing for community involvement and platform management.
 * - **Result Validation & Finalization:** Separates result validation and finalization steps for a more robust and controlled prize distribution process.
 * - **Participant Voting on Disputes:** Empowers participants in dispute resolution, promoting fairness and decentralization.
 * - **Tournament Pausing & Resuming:** Allows for flexibility in tournament management, handling unexpected events or maintenance.
 */
contract DecentralizedAutonomousTournamentPlatform {
    // -------- State Variables --------

    address public platformAdmin;
    uint256 public platformFeePercentage; // Percentage of entry fee taken as platform fee

    mapping(uint256 => Tournament) public tournaments;
    uint256 public tournamentCount;

    mapping(address => bool) public moderators;

    uint256 public disputeVotingDuration; // Duration in seconds for dispute voting

    struct Tournament {
        uint256 id;
        string name;
        address organizer;
        uint256 entryFee;
        uint256 startTime;
        uint256 endTime;
        uint256 maxParticipants;
        address prizeToken;
        uint256[] prizeDistribution; // Array of prize amounts for each rank (e.g., [100, 50, 25] for top 3)
        TournamentState state;
        mapping(address => Participant) participants;
        uint256 participantCount;
        bool registrationLocked;
        mapping(uint256 => Dispute) disputes;
        uint256 disputeCount;
        uint256 platformFeesCollected;
    }

    enum TournamentState {
        CREATED,
        REGISTRATION_OPEN,
        REGISTRATION_CLOSED,
        RUNNING,
        ENDED,
        RESULTS_FINALIZED,
        PRIZES_DISTRIBUTED,
        CANCELLED,
        PAUSED
    }

    struct Participant {
        address participantAddress;
        bool registered;
        bool resultSubmitted;
        string resultData;
        bool resultValidated;
        uint256 rank; // Rank after results are finalized
        bool prizeClaimed;
    }

    struct Dispute {
        uint256 id;
        uint256 tournamentId;
        uint256 reportingParticipantId;
        uint256 disputedParticipantId;
        string reason;
        bool isOpen;
        mapping(address => bool) votes; // Voters (participants) and their votes (true for guilty, false for innocent)
        uint256 positiveVotes;
        uint256 negativeVotes;
        DisputeStatus status;
    }

    enum DisputeStatus {
        OPEN,
        RESOLVED_IN_FAVOR_OF_REPORTER,
        RESOLVED_IN_FAVOR_OF_DISPUTED,
        RESOLVED_BY_MODERATOR // Moderator intervention
    }


    // -------- Events --------

    event TournamentCreated(uint256 tournamentId, string name, address organizer, uint256 entryFee, uint256 startTime, uint256 endTime, uint256 maxParticipants, address prizeToken, uint256[] prizeDistribution);
    event TournamentCancelled(uint256 tournamentId, string name);
    event TournamentUpdated(uint256 tournamentId, string name, uint256 entryFee, uint256 startTime, uint256 endTime, uint256 maxParticipants, address prizeToken, uint256[] prizeDistribution);
    event TournamentStarted(uint256 tournamentId, string name);
    event TournamentEnded(uint256 tournamentId, string name);
    event TournamentPaused(uint256 tournamentId, string name);
    event TournamentResumed(uint256 tournamentId, string name);

    event RegistrationOpened(uint256 tournamentId, string name);
    event RegistrationClosed(uint256 tournamentId, string name);
    event RegistrationLockedToggled(uint256 tournamentId, string name, bool locked);

    event ParticipantRegistered(uint256 tournamentId, address participantAddress);
    event ParticipantUnregistered(uint256 tournamentId, address participantAddress);
    event ResultSubmitted(uint256 tournamentId, address participantAddress, string resultData);
    event ResultValidated(uint256 tournamentId, uint256 participantId, address validatedBy);
    event ResultsFinalized(uint256 tournamentId, string name);
    event PrizesDistributed(uint256 tournamentId, string name);
    event PrizeClaimed(uint256 tournamentId, address winnerAddress, uint256 prizeAmount);

    event DisputeReported(uint256 disputeId, uint256 tournamentId, address reporter, address disputedParticipant, string reason);
    event DisputeVoteCast(uint256 disputeId, uint256 tournamentId, address voter, bool vote);
    event DisputeResolved(uint256 disputeId, uint256 tournamentId, DisputeStatus status);

    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event ModeratorAdded(address moderatorAddress, address addedBy);
    event ModeratorRemoved(address moderatorAddress, address removedBy);
    event DisputeVotingDurationSet(uint256 durationInSeconds);


    // -------- Modifiers --------

    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || msg.sender == platformAdmin, "Only moderators or platform admin can call this function.");
        _;
    }

    modifier tournamentExists(uint256 _tournamentId) {
        require(tournaments[_tournamentId].id == _tournamentId, "Tournament does not exist.");
        _;
    }

    modifier tournamentInState(uint256 _tournamentId, TournamentState _state) {
        require(tournaments[_tournamentId].state == _state, "Tournament is not in the required state.");
        _;
    }

    modifier registrationOpen(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.REGISTRATION_OPEN, "Tournament registration is not open.");
        require(!tournaments[_tournamentId].registrationLocked, "Tournament registration is locked.");
        _;
    }

    modifier registrationClosed(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.REGISTRATION_CLOSED || tournaments[_tournamentId].state == TournamentState.RUNNING || tournaments[_tournamentId].state == TournamentState.ENDED, "Tournament registration must be closed or tournament must be running/ended.");
        _;
    }

    modifier tournamentRunning(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.RUNNING, "Tournament is not running.");
        _;
    }

    modifier tournamentEnded(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.ENDED, "Tournament is not ended.");
        _;
    }

    modifier tournamentNotCancelled(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state != TournamentState.CANCELLED, "Tournament is cancelled.");
        _;
    }

    modifier participantRegistered(uint256 _tournamentId) {
        require(tournaments[_tournamentId].participants[msg.sender].registered, "Participant is not registered for the tournament.");
        _;
    }

    modifier participantNotRegistered(uint256 _tournamentId) {
        require(!tournaments[_tournamentId].participants[msg.sender].registered, "Participant is already registered for the tournament.");
        _;
    }

    modifier validPrizeToken(address _prizeToken) {
        require(_prizeToken != address(0), "Prize token address cannot be zero address.");
        _;
    }

    modifier validPrizeDistribution(uint256[] memory _prizeDistribution) {
        require(_prizeDistribution.length > 0, "Prize distribution must have at least one prize rank.");
        _;
    }

    modifier disputeOpen(uint256 _tournamentId, uint256 _disputeId) {
        require(tournaments[_tournamentId].disputes[_disputeId].isOpen, "Dispute is not open.");
        _;
    }

    modifier notVotedOnDispute(uint256 _tournamentId, uint256 _disputeId) {
        require(!tournaments[_tournamentId].disputes[_disputeId].votes[msg.sender], "Participant has already voted on this dispute.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        platformAdmin = msg.sender;
        platformFeePercentage = 5; // Default platform fee percentage (5%)
        disputeVotingDuration = 3 days; // Default dispute voting duration
    }


    // -------- 1. Tournament Management Functions --------

    /**
     * @dev Creates a new tournament. Only callable by platform admin.
     * @param _name Tournament name.
     * @param _entryFee Entry fee for the tournament.
     * @param _startTime Tournament start timestamp.
     * @param _endTime Tournament end timestamp.
     * @param _maxParticipants Maximum number of participants allowed.
     * @param _prizeToken Address of the token used for prizes.
     * @param _prizeDistribution Array of prize amounts for each rank.
     */
    function createTournament(
        string memory _name,
        uint256 _entryFee,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxParticipants,
        address _prizeToken,
        uint256[] memory _prizeDistribution
    ) external onlyPlatformAdmin validPrizeToken(_prizeToken) validPrizeDistribution(_prizeDistribution) {
        require(_startTime > block.timestamp, "Start time must be in the future.");
        require(_endTime > _startTime, "End time must be after start time.");
        require(_maxParticipants > 0, "Max participants must be greater than zero.");

        tournamentCount++;
        tournaments[tournamentCount] = Tournament({
            id: tournamentCount,
            name: _name,
            organizer: msg.sender,
            entryFee: _entryFee,
            startTime: _startTime,
            endTime: _endTime,
            maxParticipants: _maxParticipants,
            prizeToken: _prizeToken,
            prizeDistribution: _prizeDistribution,
            state: TournamentState.CREATED,
            participantCount: 0,
            registrationLocked: false,
            disputeCount: 0,
            platformFeesCollected: 0
        });

        emit TournamentCreated(tournamentCount, _name, msg.sender, _entryFee, _startTime, _endTime, _maxParticipants, _prizeToken, _prizeDistribution);

        // Automatically open registration after creation
        openRegistration(tournamentCount);
    }

    /**
     * @dev Cancels a tournament before it starts. Refunds participants if any have registered. Only callable by platform admin.
     * @param _tournamentId ID of the tournament to cancel.
     */
    function cancelTournament(uint256 _tournamentId) external onlyPlatformAdmin tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.REGISTRATION_OPEN) {
        Tournament storage tournament = tournaments[_tournamentId];

        tournament.state = TournamentState.CANCELLED;

        // Refund participants (Implementation needs token transfer if entry fee is in ERC20/721)
        // For simplicity, assuming entry fee is in native token for this example.
        for (uint256 i = 1; i <= tournament.participantCount; i++) {
            // In a real-world scenario, iterate through participants mapping efficiently.
            // This is a simplified example for demonstration.
            for(address participantAddress in getRegisteredParticipants(_tournamentId)){
                Participant storage participant = tournament.participants[participantAddress];
                if (participant.registered) {
                    payable(participant.participantAddress).transfer(tournament.entryFee);
                    emit ParticipantUnregistered(_tournamentId, participant.participantAddress); // Technically, they are refunded, not unregistered, but event is reused for simplicity.
                    participant.registered = false; // Mark as not registered to avoid double refunds if iteration logic changes.
                }
            }
            break; // Exit the loop after one iteration (simplified refund logic)
        }


        emit TournamentCancelled(_tournamentId, tournament.name);
    }

    /**
     * @dev Updates tournament details before it starts. Only callable by platform admin.
     * @param _tournamentId ID of the tournament to update.
     * @param _name New tournament name.
     * @param _entryFee New entry fee.
     * @param _startTime New start time.
     * @param _endTime New end time.
     * @param _maxParticipants New maximum participants.
     * @param _prizeToken New prize token address.
     * @param _prizeDistribution New prize distribution array.
     */
    function updateTournamentDetails(
        uint256 _tournamentId,
        string memory _name,
        uint256 _entryFee,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxParticipants,
        address _prizeToken,
        uint256[] memory _prizeDistribution
    ) external onlyPlatformAdmin tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.CREATED) validPrizeToken(_prizeToken) validPrizeDistribution(_prizeDistribution) {
        require(_startTime > block.timestamp, "Start time must be in the future.");
        require(_endTime > _startTime, "End time must be after start time.");
        require(_maxParticipants > 0, "Max participants must be greater than zero.");

        Tournament storage tournament = tournaments[_tournamentId];
        tournament.name = _name;
        tournament.entryFee = _entryFee;
        tournament.startTime = _startTime;
        tournament.endTime = _endTime;
        tournament.maxParticipants = _maxParticipants;
        tournament.prizeToken = _prizeToken;
        tournament.prizeDistribution = _prizeDistribution;

        emit TournamentUpdated(_tournamentId, _name, _entryFee, _startTime, _endTime, _maxParticipants, _prizeToken, _prizeDistribution);
    }

    /**
     * @dev Manually starts a tournament if conditions are met (e.g., minimum participants). Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to start.
     */
    function startTournament(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.REGISTRATION_CLOSED) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(block.timestamp >= tournament.startTime, "Tournament start time has not been reached yet.");
        // Add additional conditions here if needed (e.g., minimum participant count)

        tournament.state = TournamentState.RUNNING;
        emit TournamentStarted(_tournamentId, tournament.name);
    }

    /**
     * @dev Manually ends a tournament, triggering result submission and prize distribution process. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to end.
     */
    function endTournament(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentRunning(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(block.timestamp >= tournament.endTime, "Tournament end time has not been reached yet.");

        tournament.state = TournamentState.ENDED;
        emit TournamentEnded(_tournamentId, tournament.name);
    }

    /**
     * @dev Pauses a running tournament for emergency or maintenance. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to pause.
     */
    function pauseTournament(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentRunning(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        tournament.state = TournamentState.PAUSED;
        emit TournamentPaused(_tournamentId, tournament.name);
    }

    /**
     * @dev Resumes a paused tournament. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to resume.
     */
    function resumeTournament(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.PAUSED) {
        Tournament storage tournament = tournaments[_tournamentId];
        tournament.state = TournamentState.RUNNING;
        emit TournamentResumed(_tournamentId, tournament.name);
    }

    /**
     * @dev Opens registration for a tournament. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to open registration for.
     */
    function openRegistration(uint256 _tournamentId) public onlyModerator tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.CREATED) {
        tournaments[_tournamentId].state = TournamentState.REGISTRATION_OPEN;
        emit RegistrationOpened(_tournamentId, tournaments[_tournamentId].name);
    }

    /**
     * @dev Closes registration for a tournament. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to close registration for.
     */
    function closeRegistration(uint256 _tournamentId) public onlyModerator tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.REGISTRATION_OPEN) {
        tournaments[_tournamentId].state = TournamentState.REGISTRATION_CLOSED;
        emit RegistrationClosed(_tournamentId, tournaments[_tournamentId].name);
    }

    /**
     * @dev Toggles (locks/unlocks) registration for a tournament manually. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to toggle registration lock for.
     */
    function toggleTournamentRegistrationLock(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.REGISTRATION_OPEN) {
        Tournament storage tournament = tournaments[_tournamentId];
        tournament.registrationLocked = !tournament.registrationLocked;
        emit RegistrationLockedToggled(_tournamentId, tournament.name, tournament.registrationLocked);
    }


    // -------- 2. Participant Interaction Functions --------

    /**
     * @dev Registers a user for a tournament and charges the entry fee.
     * @param _tournamentId ID of the tournament to register for.
     */
    function registerForTournament(uint256 _tournamentId) external payable registrationOpen(_tournamentId) tournamentNotCancelled(_tournamentId) participantNotRegistered(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.participantCount < tournament.maxParticipants, "Tournament is full.");
        require(msg.value >= tournament.entryFee, "Insufficient entry fee provided.");

        // Transfer platform fee to platform admin
        uint256 platformFee = (tournament.entryFee * platformFeePercentage) / 100;
        payable(platformAdmin).transfer(platformFee);
        tournament.platformFeesCollected += platformFee;

        // Transfer remaining entry fee to tournament contract (for prize pool - in more complex scenarios, prize pool management can be separated)
        uint256 tournamentFee = tournament.entryFee - platformFee;
        if (tournamentFee > 0) {
            payable(address(this)).transfer(tournamentFee); // Contract receives the fee
        }


        tournament.participants[msg.sender] = Participant({
            participantAddress: msg.sender,
            registered: true,
            resultSubmitted: false,
            resultData: "",
            resultValidated: false,
            rank: 0,
            prizeClaimed: false
        });
        tournament.participantCount++;

        emit ParticipantRegistered(_tournamentId, msg.sender);
    }

    /**
     * @dev Unregisters a user from a tournament before it starts and refunds the entry fee.
     * @param _tournamentId ID of the tournament to unregister from.
     */
    function unregisterFromTournament(uint256 _tournamentId) external tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.REGISTRATION_OPEN) participantRegistered(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        Participant storage participant = tournament.participants[msg.sender];

        payable(msg.sender).transfer(tournament.entryFee); // Refund entry fee
        participant.registered = false;
        tournament.participantCount--;

        emit ParticipantUnregistered(_tournamentId, msg.sender);
    }

    /**
     * @dev Submits a participant's result for a tournament.
     * @param _tournamentId ID of the tournament.
     * @param _resultData String data representing the result (e.g., score, link to submission).
     */
    function submitResult(uint256 _tournamentId, string memory _resultData) external tournamentExists(_tournamentId) tournamentEnded(_tournamentId) participantRegistered(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        Participant storage participant = tournament.participants[msg.sender];
        require(!participant.resultSubmitted, "Result already submitted.");

        participant.resultSubmitted = true;
        participant.resultData = _resultData;

        emit ResultSubmitted(_tournamentId, msg.sender, _resultData);
    }

    /**
     * @dev Reports a dispute against another participant's result.
     * @param _tournamentId ID of the tournament.
     * @param _participantId ID of the participant whose result is being disputed (using participant index, not address directly for simplicity in this example, in real case, might use address).
     * @param _disputeReason Reason for the dispute.
     */
    function reportDispute(uint256 _tournamentId, uint256 _participantId, string memory _disputeReason) external tournamentExists(_tournamentId) tournamentEnded(_tournamentId) participantRegistered(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(_participantId > 0 && _participantId <= tournament.participantCount, "Invalid participant ID."); // Basic ID check - in real app, better participant identification needed
        address disputedParticipantAddress = getParticipantAddressByIndex(_tournamentId, _participantId); // Helper function needed to get address from index.
        require(disputedParticipantAddress != msg.sender, "Cannot dispute your own result.");

        tournament.disputeCount++;
        uint256 disputeId = tournament.disputeCount;
        tournaments[_tournamentId].disputes[disputeId] = Dispute({
            id: disputeId,
            tournamentId: _tournamentId,
            reportingParticipantId: getParticipantIndexByAddress(_tournamentId, msg.sender), // Store index for simplicity
            disputedParticipantId: _participantId,
            reason: _disputeReason,
            isOpen: true,
            positiveVotes: 0,
            negativeVotes: 0,
            status: DisputeStatus.OPEN
        });

        emit DisputeReported(disputeId, _tournamentId, msg.sender, disputedParticipantAddress, _disputeReason);
    }

    /**
     * @dev Allows registered participants to vote on an open dispute.
     * @param _tournamentId ID of the tournament.
     * @param _disputeId ID of the dispute.
     * @param _vote True for guilty (disputed result is invalid), false for innocent (disputed result is valid).
     */
    function voteOnDispute(uint256 _tournamentId, uint256 _disputeId, bool _vote) external tournamentExists(_tournamentId) tournamentEnded(_tournamentId) participantRegistered(_tournamentId) disputeOpen(_tournamentId, _disputeId) notVotedOnDispute(_tournamentId, _disputeId) {
        Tournament storage tournament = tournaments[_tournamentId];
        Dispute storage dispute = tournament.disputes[_disputeId];

        dispute.votes[msg.sender] = _vote;
        if (_vote) {
            dispute.positiveVotes++;
        } else {
            dispute.negativeVotes++;
        }

        emit DisputeVoteCast(_disputeId, _tournamentId, msg.sender, _vote);

        // Automatically resolve dispute after voting duration (simplified logic - in real app, use block.timestamp and require time checks)
        if (block.timestamp > block.timestamp + disputeVotingDuration) { // Simplified time check - replace with actual logic.
            resolveDispute(_tournamentId, _disputeId);
        }
    }


    // -------- 3. Result & Prize Management Functions --------

    /**
     * @dev Allows admin/moderators to manually validate a participant's result.
     * @param _tournamentId ID of the tournament.
     * @param _participantId ID of the participant whose result is being validated (using participant index, not address directly for simplicity).
     */
    function validateResult(uint256 _tournamentId, uint256 _participantId) external onlyModerator tournamentExists(_tournamentId) tournamentEnded(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        address participantAddress = getParticipantAddressByIndex(_tournamentId, _participantId);
        Participant storage participant = tournament.participants[participantAddress];
        require(participant.resultSubmitted, "Result not yet submitted.");

        participant.resultValidated = true;
        emit ResultValidated(_tournamentId, _participantId, msg.sender);
    }

    /**
     * @dev Finalizes the results after validation and dispute resolution, preparing for prize distribution. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to finalize results for.
     */
    function finalizeResults(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentEnded(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.state == TournamentState.ENDED, "Tournament must be in Ended state to finalize results.");

        // In a real application, you would implement logic to rank participants based on validated results.
        // This example assumes results are already ranked or ranking is done off-chain and ranks are input.
        // For simplicity, we just iterate through participants and assign ranks sequentially for demonstration.

        uint256 currentRank = 1;
        for (uint256 i = 1; i <= tournament.participantCount; i++) { // Simplified ranking - real app needs proper ranking algorithm
            address participantAddress = getParticipantAddressByIndex(_tournamentId, i);
            Participant storage participant = tournament.participants[participantAddress];
            if (participant.resultValidated) { // Only rank validated results for this example.
                participant.rank = currentRank;
                currentRank++;
            } else {
                participant.rank = 0; // Rank 0 for unvalidated results
            }
        }

        tournament.state = TournamentState.RESULTS_FINALIZED;
        emit ResultsFinalized(_tournamentId, tournament.name);
    }

    /**
     * @dev Distributes prizes to winners based on the prize distribution structure. Only callable by platform admin or moderator.
     * @param _tournamentId ID of the tournament to distribute prizes for.
     */
    function distributePrizes(uint256 _tournamentId) external onlyModerator tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.RESULTS_FINALIZED) {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 prizePool = address(this).balance; // Assuming prize pool is held in contract balance. For ERC20, need token transfers.

        // Distribute prizes based on rank and prize distribution array
        for (uint256 i = 0; i < tournament.prizeDistribution.length; i++) {
            uint256 rankToPrize = i + 1;
            uint256 prizeAmount = tournament.prizeDistribution[i];

            for (uint256 j = 1; j <= tournament.participantCount; j++) { // Iterate through participants to find winners for this rank.
                address participantAddress = getParticipantAddressByIndex(_tournamentId, j);
                Participant storage participant = tournament.participants[participantAddress];
                if (participant.rank == rankToPrize && !participant.prizeClaimed) {
                    if (prizeAmount <= prizePool) {
                        payable(participant.participantAddress).transfer(prizeAmount); // Transfer prize (native token example)
                        participant.prizeClaimed = true;
                        prizePool -= prizeAmount;
                        emit PrizeDistributed(_tournamentId, tournament.name);
                    } else {
                        // Handle insufficient prize pool - in real app, might adjust prize, refund, or handle differently.
                        // For simplicity, breaking here if prize pool is insufficient for current prize rank.
                        break;
                    }
                }
            }
            if (prizePool <= 0) break; // No more prize pool left
        }

        tournament.state = TournamentState.PRIZES_DISTRIBUTED;
        emit PrizesDistributed(_tournamentId, tournament.name);
    }

    /**
     * @dev Allows winners to claim their earned prizes.
     * @param _tournamentId ID of the tournament to claim prize from.
     */
    function claimPrize(uint256 _tournamentId) external tournamentExists(_tournamentId) tournamentInState(_tournamentId, TournamentState.PRIZES_DISTRIBUTED) participantRegistered(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        Participant storage participant = tournament.participants[msg.sender];
        require(!participant.prizeClaimed, "Prize already claimed.");
        require(participant.rank > 0 && participant.rank <= tournament.prizeDistribution.length, "No prize to claim for your rank."); // Check if rank is in prize distribution range

        uint256 prizeAmount = tournament.prizeDistribution[participant.rank - 1]; // Get prize amount based on rank (array is 0-indexed)

        require(address(this).balance >= prizeAmount, "Insufficient contract balance for prize payout."); // Ensure contract has balance

        payable(msg.sender).transfer(prizeAmount);
        participant.prizeClaimed = true;
        emit PrizeClaimed(_tournamentId, msg.sender, prizeAmount);
    }


    // -------- 4. Platform Governance & Features Functions --------

    /**
     * @dev Sets the platform fee percentage. Only callable by platform admin.
     * @param _feePercentage New platform fee percentage.
     */
    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Allows platform admin to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyPlatformAdmin {
        uint256 balance = address(this).balance; // Get contract balance - platform fees are accumulated here in this simplified model.
        uint256 platformFees = 0;
        for (uint256 i = 1; i <= tournamentCount; i++) {
            platformFees += tournaments[i].platformFeesCollected;
        }
        require(balance >= platformFees, "Insufficient contract balance to withdraw platform fees.");

        payable(platformAdmin).transfer(platformFees);
        for (uint256 i = 1; i <= tournamentCount; i++) {
            tournaments[i].platformFeesCollected = 0; // Reset collected fees after withdrawal.
        }
        emit PlatformFeesWithdrawn(platformFees, msg.sender);
    }

    /**
     * @dev Adds a new moderator. Only callable by platform admin.
     * @param _moderatorAddress Address of the moderator to add.
     */
    function addModerator(address _moderatorAddress) external onlyPlatformAdmin {
        moderators[_moderatorAddress] = true;
        emit ModeratorAdded(_moderatorAddress, msg.sender);
    }

    /**
     * @dev Removes a moderator. Only callable by platform admin.
     * @param _moderatorAddress Address of the moderator to remove.
     */
    function removeModerator(address _moderatorAddress) external onlyPlatformAdmin {
        moderators[_moderatorAddress] = false;
        emit ModeratorRemoved(_moderatorAddress, msg.sender);
    }

    /**
     * @dev Sets the duration for dispute voting. Only callable by platform admin.
     * @param _durationInSeconds Duration in seconds for dispute voting.
     */
    function setDisputeVotingDuration(uint256 _durationInSeconds) external onlyPlatformAdmin {
        disputeVotingDuration = _durationInSeconds;
        emit DisputeVotingDurationSet(_durationInSeconds);
    }

    /**
     * @dev Resolves a dispute based on votes. Called internally after voting duration.
     * @param _tournamentId ID of the tournament.
     * @param _disputeId ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _tournamentId, uint256 _disputeId) private tournamentExists(_tournamentId) tournamentEnded(_tournamentId) disputeOpen(_tournamentId, _disputeId) {
        Tournament storage tournament = tournaments[_tournamentId];
        Dispute storage dispute = tournament.disputes[_disputeId];

        dispute.isOpen = false; // Mark dispute as closed

        if (dispute.positiveVotes > dispute.negativeVotes) {
            // Majority voted guilty - Invalidate disputed result (example action - can be customized)
            address disputedParticipantAddress = getParticipantAddressByIndex(_tournamentId, dispute.disputedParticipantId);
            tournament.participants[disputedParticipantAddress].resultValidated = false; // Example: Invalidate result
            dispute.status = DisputeStatus.RESOLVED_IN_FAVOR_OF_REPORTER;
            emit DisputeResolved(_disputeId, _tournamentId, DisputeStatus.RESOLVED_IN_FAVOR_OF_REPORTER);
        } else {
            // Majority or tie voted innocent - Keep disputed result valid
            dispute.status = DisputeStatus.RESOLVED_IN_FAVOR_OF_DISPUTED;
            emit DisputeResolved(_disputeId, _tournamentId, DisputeStatus.RESOLVED_IN_FAVOR_OF_DISPUTED);
        }
    }

    /**
     * @dev Allows moderators to manually resolve a dispute.
     * @param _tournamentId ID of the tournament.
     * @param _disputeId ID of the dispute.
     * @param _status Dispute status to set manually (e.g., RESOLVED_BY_MODERATOR).
     */
    function resolveDisputeByModerator(uint256 _tournamentId, uint256 _disputeId, DisputeStatus _status) external onlyModerator tournamentExists(_tournamentId) tournamentEnded(_tournamentId) disputeOpen(_tournamentId, _disputeId) {
        require(_status == DisputeStatus.RESOLVED_BY_MODERATOR || _status == DisputeStatus.RESOLVED_IN_FAVOR_OF_DISPUTED || _status == DisputeStatus.RESOLVED_IN_FAVOR_OF_REPORTER, "Invalid dispute status for moderator resolution.");
        Tournament storage tournament = tournaments[_tournamentId];
        Dispute storage dispute = tournament.disputes[_disputeId];

        dispute.isOpen = false;
        dispute.status = _status;
        emit DisputeResolved(_disputeId, _tournamentId, _status);
    }

    // -------- Helper Functions (Internal/Private) --------

    /**
     * @dev Internal helper function to get participant address by index (1-based). For simplified participant management in this example.
     * @param _tournamentId ID of the tournament.
     * @param _participantIndex Index of the participant (1-based).
     * @return address Participant address.
     */
    function getParticipantAddressByIndex(uint256 _tournamentId, uint256 _participantIndex) internal view returns (address) {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 count = 0;
        for (address participantAddress in getRegisteredParticipants(_tournamentId)) {
            count++;
            if (count == _participantIndex) {
                return participantAddress;
            }
        }
        revert("Invalid participant index.");
    }

    /**
     * @dev Internal helper function to get participant index by address (1-based). For simplified participant management in this example.
     * @param _tournamentId ID of the tournament.
     * @param _participantAddress Address of the participant.
     * @return uint256 Participant index (1-based).
     */
    function getParticipantIndexByAddress(uint256 _tournamentId, address _participantAddress) internal view returns (uint256) {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 index = 0;
        for (address participantAddr in getRegisteredParticipants(_tournamentId)) {
            index++;
            if (participantAddr == _participantAddress) {
                return index;
            }
        }
        revert("Participant address not found in tournament.");
    }

    /**
     * @dev Internal helper function to get all registered participant addresses for a tournament.
     * @param _tournamentId ID of the tournament.
     * @return address[] Array of registered participant addresses.
     */
    function getRegisteredParticipants(uint256 _tournamentId) internal view returns (address[] memory) {
        Tournament storage tournament = tournaments[_tournamentId];
        address[] memory participantsArray = new address[](tournament.participantCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= tournament.participantCount; i++) {
             address participantAddress = getParticipantAddressByIndex(_tournamentId, i);
             if(tournament.participants[participantAddress].registered){
                participantsArray[index] = participantAddress;
                index++;
             }
        }
        return participantsArray;
    }

    /**
     * @dev Fallback function to receive native tokens.
     */
    receive() external payable {}
}
```