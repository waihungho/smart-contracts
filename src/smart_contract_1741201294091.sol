```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Tournament Organizer (DATO)
 * @author Bard (AI Assistant)
 * @dev A smart contract for creating and managing decentralized tournaments with advanced features like dynamic prize pools,
 *      NFT-based rewards, skill-based matchmaking (abstracted), community governance through proposals and voting,
 *      and integration with decentralized identity (DID) for reputation and access control (abstracted).
 *
 * **Outline and Function Summary:**
 *
 * **Tournament Management:**
 * 1. `createTournament(string _name, uint256 _startTime, uint256 _endTime, uint256 _entryFee, address _prizeToken, uint256 _basePrizePool, uint8 _maxParticipants, string _rulesURI)`:  Allows admins to create a new tournament with various parameters.
 * 2. `updateTournamentDetails(uint256 _tournamentId, string _name, uint256 _startTime, uint256 _endTime, uint256 _entryFee, address _prizeToken, uint256 _basePrizePool, uint8 _maxParticipants, string _rulesURI)`: Allows admins to update tournament details before it starts.
 * 3. `cancelTournament(uint256 _tournamentId)`: Allows admins to cancel a tournament and refund participants.
 * 4. `addAdmin(address _newAdmin)`: Allows existing admins to add new admins.
 * 5. `removeAdmin(address _adminToRemove)`: Allows existing admins to remove admins.
 * 6. `pauseContract()`: Pauses the contract, preventing most functions from being executed (emergency stop).
 * 7. `unpauseContract()`: Unpauses the contract, resuming normal operations.
 * 8. `setPlatformFee(uint256 _feePercentage)`: Sets a platform fee percentage charged on entry fees.
 * 9. `withdrawPlatformFees()`: Allows admins to withdraw accumulated platform fees.
 *
 * **Participant Management:**
 * 10. `registerForTournament(uint256 _tournamentId)`: Allows users to register for a tournament by paying the entry fee.
 * 11. `deregisterFromTournament(uint256 _tournamentId)`: Allows users to deregister from a tournament before it starts and get a refund.
 * 12. `submitScore(uint256 _tournamentId, uint256 _score, bytes32 _proofOfPerformance)`: Allows participants to submit their scores and proof of performance (abstracted - could be oracle integration or decentralized verification).
 * 13. `claimPrize(uint256 _tournamentId)`: Allows winners to claim their prizes after the tournament ends and results are finalized.
 *
 * **Tournament Logic and Dynamics:**
 * 14. `startTournament(uint256 _tournamentId)`:  Allows admins to manually start a tournament (or could be automated based on start time).
 * 15. `finalizeTournament(uint256 _tournamentId)`: Allows admins to finalize a tournament, calculate rankings, and prepare for prize distribution.
 * 16. `distributePrizes(uint256 _tournamentId)`: Distributes prizes to winners based on their rankings and dynamic prize pool logic.
 * 17. `contributeToPrizePool(uint256 _tournamentId)`: Allows anyone to contribute to the prize pool of a tournament, increasing rewards and community engagement.
 * 18. `setPrizeNFT(uint256 _tournamentId, string _nftMetadataURI)`: Sets an NFT metadata URI to be minted as a special reward for tournament winners.
 * 19. `mintAchievementNFT(uint256 _tournamentId, address _participant, string _achievementName, string _achievementMetadataURI)`: Mints achievement NFTs for participants based on milestones or performance in a tournament.
 *
 * **Governance and Community:**
 * 20. `proposeRuleChange(uint256 _tournamentId, string _ruleProposal, string _proposalDetailsURI)`: Allows participants to propose changes to tournament rules or parameters (DAO-lite governance).
 * 21. `voteOnProposal(uint256 _tournamentId, uint256 _proposalId, bool _vote)`: Allows registered participants of a tournament to vote on rule change proposals.
 * 22. `executeProposal(uint256 _tournamentId, uint256 _proposalId)`: Allows admins to execute a passed proposal, applying the rule changes.
 *
 * **Data Retrieval and Information:**
 * 23. `getTournamentDetails(uint256 _tournamentId)`: Retrieves detailed information about a specific tournament.
 * 24. `getParticipantDetails(uint256 _tournamentId, address _participant)`: Retrieves details about a participant in a tournament.
 * 25. `getTournamentProposals(uint256 _tournamentId)`: Retrieves all active proposals for a specific tournament.
 * 26. `getContractBalance()`: Retrieves the contract's balance in the prize token (useful for monitoring prize pools).
 */
contract DecentralizedAutonomousTournamentOrganizer {
    // -------- State Variables --------

    address public owner;
    bool public paused;
    uint256 public platformFeePercentage; // Percentage fee charged on entry fees
    address[] public admins;

    uint256 public tournamentCount;

    struct Tournament {
        uint256 id;
        string name;
        address organizer; // Admin who created the tournament
        uint256 startTime;
        uint256 endTime;
        uint256 entryFee;
        address prizeToken;
        uint256 basePrizePool;
        uint256 currentPrizePool; // Dynamic prize pool, can be increased by contributions
        uint8 maxParticipants;
        string rulesURI;
        TournamentState state;
        mapping(address => Participant) participants;
        address[] participantList; // Keep track of participants for iteration
        mapping(uint256 => RuleProposal) proposals;
        uint256 proposalCount;
        string prizeNFTMetadataURI; // Optional NFT prize metadata
        bool prizeNFTSet;
    }

    enum TournamentState {
        Pending, // Tournament created, not yet started
        RegistrationOpen, // Registration is open for participants
        Ongoing,     // Tournament in progress
        Completed,   // Tournament finished, results finalized
        Cancelled    // Tournament cancelled
    }

    struct Participant {
        address participantAddress;
        bool registered;
        uint256 score;
        bytes32 proofOfPerformance; // Abstracted proof of performance, could be IPFS hash, oracle signature, etc.
        bool prizeClaimed;
        bool achievementNFTMinted;
    }

    struct RuleProposal {
        uint256 id;
        string proposal;
        string detailsURI;
        address proposer;
        uint256 startTime;
        uint256 endTime; // Proposal voting period end time
        mapping(address => bool) votes; // Participants who voted (true for yes, false for no - not explicitly recording no votes for gas optimization, absence implies no/abstain)
        uint256 yesVotes;
        uint256 noVotes; // Explicitly track no votes for clarity
        bool executed;
    }


    mapping(uint256 => Tournament) public tournaments;

    // -------- Events --------
    event TournamentCreated(uint256 tournamentId, string name, address organizer, uint256 startTime, uint256 endTime);
    event TournamentUpdated(uint256 tournamentId, string name, uint256 startTime, uint256 endTime);
    event TournamentCancelled(uint256 tournamentId);
    event AdminAdded(address newAdmin, address addedBy);
    event AdminRemoved(address removedAdmin, address removedBy);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address withdrawnBy, uint256 amount);

    event RegisteredForTournament(uint256 tournamentId, address participant);
    event DeregisteredFromTournament(uint256 tournamentId, address participant);
    event ScoreSubmitted(uint256 tournamentId, address participant, uint256 score);
    event PrizeClaimed(uint256 tournamentId, address winner, uint256 prizeAmount);

    event TournamentStarted(uint256 tournamentId);
    event TournamentFinalized(uint256 tournamentId);
    event PrizesDistributed(uint256 tournamentId);
    event PrizePoolContribution(uint256 tournamentId, address contributor, uint256 amount);
    event PrizeNFTSet(uint256 tournamentId, string nftMetadataURI);
    event AchievementNFTMinted(uint256 tournamentId, address participant, string achievementName);

    event RuleProposalCreated(uint256 tournamentId, uint256 proposalId, string proposal, address proposer);
    event VotedOnProposal(uint256 tournamentId, uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 tournamentId, uint256 proposalId);


    // -------- Modifiers --------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin || msg.sender == owner, "Only admins or owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier tournamentExists(uint256 _tournamentId) {
        require(_tournamentId > 0 && _tournamentId <= tournamentCount && tournaments[_tournamentId].id == _tournamentId, "Tournament does not exist.");
        _;
    }

    modifier registrationOpen(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.RegistrationOpen, "Tournament registration is not open.");
        _;
    }

    modifier tournamentPending(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.Pending, "Tournament is not in pending state.");
        _;
    }

    modifier tournamentOngoing(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.Ongoing, "Tournament is not ongoing.");
        _;
    }

    modifier tournamentCompleted(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state == TournamentState.Completed, "Tournament is not completed.");
        _;
    }

    modifier tournamentNotCancelled(uint256 _tournamentId) {
        require(tournaments[_tournamentId].state != TournamentState.Cancelled, "Tournament is cancelled.");
        _;
    }

    modifier participantRegistered(uint256 _tournamentId, address _participant) {
        require(tournaments[_tournamentId].participants[_participant].registered, "Participant is not registered for this tournament.");
        _;
    }

    modifier participantNotRegistered(uint256 _tournamentId, address _participant) {
        require(!tournaments[_tournamentId].participants[_participant].registered, "Participant is already registered for this tournament.");
        _;
    }

    modifier proposalExists(uint256 _tournamentId, uint256 _proposalId) {
        require(tournaments[_tournamentId].proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalVotingOpen(uint256 _tournamentId, uint256 _proposalId) {
        require(block.timestamp >= tournaments[_tournamentId].proposals[_proposalId].startTime && block.timestamp <= tournaments[_tournamentId].proposals[_proposalId].endTime, "Proposal voting period is not open.");
        _;
    }

    modifier proposalNotExecuted(uint256 _tournamentId, uint256 _proposalId) {
        require(!tournaments[_tournamentId].proposals[_proposalId].executed, "Proposal has already been executed.");
        _;
    }


    // -------- Constructor --------
    constructor() {
        owner = msg.sender;
        admins.push(msg.sender); // Initially, the contract creator is the admin
        paused = false;
        platformFeePercentage = 5; // Default platform fee is 5%
        tournamentCount = 0;
    }

    // -------- Admin Functions --------

    /// @dev Allows admins to create a new tournament.
    /// @param _name Name of the tournament.
    /// @param _startTime Unix timestamp for tournament start time.
    /// @param _endTime Unix timestamp for tournament end time.
    /// @param _entryFee Entry fee for the tournament in the prize token.
    /// @param _prizeToken Address of the ERC20 token used as prize.
    /// @param _basePrizePool Base prize pool amount in the prize token.
    /// @param _maxParticipants Maximum number of participants allowed.
    /// @param _rulesURI URI pointing to the tournament rules document.
    function createTournament(
        string memory _name,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _entryFee,
        address _prizeToken,
        uint256 _basePrizePool,
        uint8 _maxParticipants,
        string memory _rulesURI
    ) external onlyAdmin whenNotPaused {
        require(_startTime > block.timestamp, "Start time must be in the future.");
        require(_endTime > _startTime, "End time must be after start time.");
        require(_maxParticipants > 0, "Max participants must be greater than 0.");
        require(_entryFee >= 0, "Entry fee cannot be negative.");
        require(_basePrizePool >= 0, "Base prize pool cannot be negative.");

        tournamentCount++;
        tournaments[tournamentCount] = Tournament({
            id: tournamentCount,
            name: _name,
            organizer: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            entryFee: _entryFee,
            prizeToken: _prizeToken,
            basePrizePool: _basePrizePool,
            currentPrizePool: _basePrizePool,
            maxParticipants: _maxParticipants,
            rulesURI: _rulesURI,
            state: TournamentState.Pending,
            participantList: new address[](0),
            proposalCount: 0,
            prizeNFTMetadataURI: "",
            prizeNFTSet: false
        });

        emit TournamentCreated(tournamentCount, _name, msg.sender, _startTime, _endTime);
    }

    /// @dev Allows admins to update tournament details before it starts.
    /// @param _tournamentId ID of the tournament to update.
    function updateTournamentDetails(
        uint256 _tournamentId,
        string memory _name,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _entryFee,
        address _prizeToken,
        uint256 _basePrizePool,
        uint8 _maxParticipants,
        string memory _rulesURI
    ) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentPending(_tournamentId) {
        require(_startTime > block.timestamp, "Start time must be in the future.");
        require(_endTime > _startTime, "End time must be after start time.");
        require(_maxParticipants > 0, "Max participants must be greater than 0.");
        require(_entryFee >= 0, "Entry fee cannot be negative.");
        require(_basePrizePool >= 0, "Base prize pool cannot be negative.");

        Tournament storage tournament = tournaments[_tournamentId];
        tournament.name = _name;
        tournament.startTime = _startTime;
        tournament.endTime = _endTime;
        tournament.entryFee = _entryFee;
        tournament.prizeToken = _prizeToken;
        tournament.basePrizePool = _basePrizePool;
        tournament.currentPrizePool = _basePrizePool; // Reset current prize pool if base prize pool is changed on update
        tournament.maxParticipants = _maxParticipants;
        tournament.rulesURI = _rulesURI;

        emit TournamentUpdated(_tournamentId, _name, _startTime, _endTime);
    }


    /// @dev Allows admins to cancel a tournament and refund participants.
    /// @param _tournamentId ID of the tournament to cancel.
    function cancelTournament(uint256 _tournamentId) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentPending(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        tournament.state = TournamentState.Cancelled;
        uint256 entryFee = tournament.entryFee;
        address prizeToken = tournament.prizeToken;

        for (uint256 i = 0; i < tournament.participantList.length; i++) {
            address participantAddress = tournament.participantList[i];
            // Refund entry fee to participants
            if (entryFee > 0) {
                // Transfer prize token back to participant
                IERC20(prizeToken).transfer(participantAddress, entryFee);
            }
        }

        emit TournamentCancelled(_tournamentId);
    }

    /// @dev Allows admins to add new admins.
    /// @param _newAdmin Address of the new admin to add.
    function addAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        // Check if admin already exists to prevent duplicates
        bool adminExists = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _newAdmin) {
                adminExists = true;
                break;
            }
        }
        require(!adminExists, "Admin already exists.");

        admins.push(_newAdmin);
        emit AdminAdded(_newAdmin, msg.sender);
    }

    /// @dev Allows admins to remove admins. Cannot remove the contract owner from admin list.
    /// @param _adminToRemove Address of the admin to remove.
    function removeAdmin(address _adminToRemove) external onlyAdmin onlyOwner whenNotPaused { // Owner can remove any admin, other admins might have restrictions in a more complex system
        require(_adminToRemove != address(0), "Invalid admin address.");
        require(_adminToRemove != owner, "Cannot remove contract owner from admins.");

        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _adminToRemove) {
                delete admins[i]; // Remove admin from array - can cause gaps, consider array compaction if order matters
                // To maintain array order and avoid gaps, you could shift elements:
                // if (i < admins.length - 1) {
                //     for (uint256 j = i; j < admins.length - 1; j++) {
                //         admins[j] = admins[j + 1];
                //     }
                // }
                admins.pop(); // Remove last element to shorten the array
                emit AdminRemoved(_adminToRemove, msg.sender);
                return;
            }
        }
        revert("Admin not found.");
    }

    /// @dev Pauses the contract, preventing most functions from being executed (emergency stop).
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @dev Unpauses the contract, resuming normal operations.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @dev Sets the platform fee percentage.
    /// @param _feePercentage Percentage of entry fee to be taken as platform fee (e.g., 5 for 5%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @dev Allows admins to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyAdmin whenNotPaused {
        uint256 contractBalance = getContractBalance();
        uint256 withdrawableFees = (contractBalance * platformFeePercentage) / 100; // Simple calculation, adjust if needed based on fee collection logic
        require(withdrawableFees > 0, "No platform fees to withdraw.");

        address prizeTokenAddress = tournaments[1].prizeToken; // Assuming all tournaments use the same prize token for simplicity in fee withdrawal.  In a real system, you'd track fees per token.
        require(prizeTokenAddress != address(0), "Prize token address not set or invalid.");

        IERC20(prizeTokenAddress).transfer(msg.sender, withdrawableFees);
        emit PlatformFeesWithdrawn(msg.sender, withdrawableFees);
    }


    // -------- Participant Functions --------

    /// @dev Allows users to register for a tournament by paying the entry fee.
    /// @param _tournamentId ID of the tournament to register for.
    function registerForTournament(uint256 _tournamentId) external payable whenNotPaused tournamentExists(_tournamentId) registrationOpen(_tournamentId) tournamentNotCancelled(_tournamentId) participantNotRegistered(_tournamentId, msg.sender) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.participantList.length < tournament.maxParticipants, "Tournament is full.");

        uint256 entryFee = tournament.entryFee;
        address prizeToken = tournament.prizeToken;

        if (entryFee > 0) {
            require(prizeToken != address(0), "Prize token address is not set.");
            IERC20(prizeToken).transferFrom(msg.sender, address(this), entryFee); // Assuming user approves contract to spend tokens
        }

        tournament.participants[msg.sender] = Participant({
            participantAddress: msg.sender,
            registered: true,
            score: 0,
            proofOfPerformance: bytes32(0),
            prizeClaimed: false,
            achievementNFTMinted: false
        });
        tournament.participantList.push(msg.sender);
        emit RegisteredForTournament(_tournamentId, msg.sender);
    }

    /// @dev Allows users to deregister from a tournament before it starts and get a refund.
    /// @param _tournamentId ID of the tournament to deregister from.
    function deregisterFromTournament(uint256 _tournamentId) external whenNotPaused tournamentExists(_tournamentId) registrationOpen(_tournamentId) tournamentNotCancelled(_tournamentId) participantRegistered(_tournamentId, msg.sender) {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 entryFee = tournament.entryFee;
        address prizeToken = tournament.prizeToken;

        tournament.participants[msg.sender].registered = false;

        // Remove participant from participantList (more efficient approach needed for large lists if order matters)
        for (uint256 i = 0; i < tournament.participantList.length; i++) {
            if (tournament.participantList[i] == msg.sender) {
                delete tournament.participantList[i];
                // To maintain array order and avoid gaps, you could shift elements:
                // if (i < tournament.participantList.length - 1) {
                //     for (uint256 j = i; j < tournament.participantList.length - 1; j++) {
                //         tournament.participantList[j] = tournament.participantList[j + 1];
                //     }
                // }
                tournament.participantList.pop(); // Remove last element to shorten the array
                break;
            }
        }


        if (entryFee > 0) {
            // Refund entry fee to participant
            IERC20(prizeToken).transfer(msg.sender, entryFee);
        }
        emit DeregisteredFromTournament(_tournamentId, msg.sender);
    }

    /// @dev Allows participants to submit their scores and proof of performance.
    /// @param _tournamentId ID of the tournament.
    /// @param _score Score achieved by the participant.
    /// @param _proofOfPerformance Proof of performance (e.g., hash of game replay, oracle signature, etc. - abstracted, needs external verification in a real system).
    function submitScore(uint256 _tournamentId, uint256 _score, bytes32 _proofOfPerformance) external whenNotPaused tournamentExists(_tournamentId) tournamentOngoing(_tournamentId) tournamentNotCancelled(_tournamentId) participantRegistered(_tournamentId, msg.sender) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(block.timestamp <= tournament.endTime, "Tournament end time exceeded."); // Ensure score submission within tournament time

        tournament.participants[msg.sender].score = _score;
        tournament.participants[msg.sender].proofOfPerformance = _proofOfPerformance; // Store proof (abstracted verification)
        emit ScoreSubmitted(_tournamentId, msg.sender, _score);
    }

    /// @dev Allows winners to claim their prizes after the tournament ends and results are finalized.
    /// @param _tournamentId ID of the tournament.
    function claimPrize(uint256 _tournamentId) external whenNotPaused tournamentExists(_tournamentId) tournamentCompleted(_tournamentId) tournamentNotCancelled(_tournamentId) participantRegistered(_tournamentId, msg.sender) {
        Tournament storage tournament = tournaments[_tournamentId];
        Participant storage participant = tournament.participants[msg.sender];
        require(!participant.prizeClaimed, "Prize already claimed.");

        // In a real system, prize distribution logic would be more complex based on ranking and prize tiers.
        // For simplicity here, assuming top participants get prizes based on ranking (needs to be implemented in finalizeTournament).
        // Example: Simple prize distribution - everyone gets equal share for now (replace with ranking logic later)

        uint256 prizeAmount = tournament.currentPrizePool / tournament.participantList.length; // Very basic example - replace with actual prize distribution logic
        if (prizeAmount > 0) {
            IERC20(tournament.prizeToken).transfer(msg.sender, prizeAmount);
            participant.prizeClaimed = true;
            emit PrizeClaimed(_tournamentId, msg.sender, prizeAmount);
        } else {
            revert("No prize available for claim.");
        }
    }


    // -------- Tournament Logic Functions --------

    /// @dev Allows admins to manually start a tournament (or could be automated based on start time).
    /// @param _tournamentId ID of the tournament to start.
    function startTournament(uint256 _tournamentId) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentPending(_tournamentId) tournamentNotCancelled(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(block.timestamp >= tournament.startTime, "Tournament start time not reached yet.");
        tournament.state = TournamentState.Ongoing;
        tournament.state = TournamentState.RegistrationOpen; // Open registration first.  Start tournament after registration period.
        tournament.state = TournamentState.Ongoing; // Move directly to ongoing for this example. In real system, registration period needed.
        emit TournamentStarted(_tournamentId);
    }


    /// @dev Allows admins to finalize a tournament, calculate rankings, and prepare for prize distribution.
    /// @param _tournamentId ID of the tournament to finalize.
    function finalizeTournament(uint256 _tournamentId) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentOngoing(_tournamentId) tournamentNotCancelled(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(block.timestamp >= tournament.endTime, "Tournament end time not reached yet."); // Ensure finalize is called after end time.

        tournament.state = TournamentState.Completed;

        // --- Ranking Logic (Abstracted - needs implementation based on tournament rules) ---
        // Example: Sort participants by score in descending order (simple example, real ranking can be more complex)
        //  - Implement a sorting algorithm to rank participants based on their scores.
        //  - Consider tie-breaking rules if needed.
        //  - Store ranked participant list (or update participant struct with rank).
        // --- End Ranking Logic ---


        emit TournamentFinalized(_tournamentId);
    }

    /// @dev Distributes prizes to winners based on their rankings and dynamic prize pool logic.
    /// @param _tournamentId ID of the tournament to distribute prizes for.
    function distributePrizes(uint256 _tournamentId) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentCompleted(_tournamentId) tournamentNotCancelled(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.currentPrizePool > 0, "No prize pool available to distribute.");

        // --- Prize Distribution Logic (Abstracted - needs implementation based on tournament rules) ---
        // Example: Distribute prizes to top 3 ranked participants (simple example, real distribution can be tiered)
        //  - Access the ranked participant list (calculated in finalizeTournament).
        //  - Determine prize amounts for each rank (e.g., 50% for 1st, 30% for 2nd, 20% for 3rd).
        //  - Transfer prize tokens to winners.
        // --- End Prize Distribution Logic ---

        // Simple example: Equal distribution to all participants (replace with ranking-based distribution)
        uint256 prizePerParticipant = tournament.currentPrizePool / tournament.participantList.length;
        if (prizePerParticipant > 0) {
            for (uint256 i = 0; i < tournament.participantList.length; i++) {
                address participantAddress = tournament.participantList[i];
                IERC20(tournament.prizeToken).transfer(participantAddress, prizePerParticipant);
            }
        }

        emit PrizesDistributed(_tournamentId);
    }

    /// @dev Allows anyone to contribute to the prize pool of a tournament, increasing rewards.
    /// @param _tournamentId ID of the tournament to contribute to.
    function contributeToPrizePool(uint256 _tournamentId) external payable whenNotPaused tournamentExists(_tournamentId) registrationOpen(_tournamentId) tournamentNotCancelled(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 contributionAmount = msg.value; // Assuming contribution in native token (ETH in testnet, can be prize token too)
        address prizeToken = tournament.prizeToken;

        require(prizeToken != address(0), "Prize token address is not set.");
        require(contributionAmount > 0, "Contribution amount must be greater than zero.");

        IERC20(prizeToken).transferFrom(msg.sender, address(this), contributionAmount); // User needs to approve contract to spend prize tokens for contribution
        tournament.currentPrizePool += contributionAmount;
        emit PrizePoolContribution(_tournamentId, msg.sender, contributionAmount);
    }

    /// @dev Sets an NFT metadata URI to be minted as a special reward for tournament winners.
    /// @param _tournamentId ID of the tournament.
    /// @param _nftMetadataURI URI pointing to the NFT metadata (e.g., IPFS URI).
    function setPrizeNFT(uint256 _tournamentId, string memory _nftMetadataURI) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentPending(_tournamentId) tournamentNotCancelled(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        tournament.prizeNFTMetadataURI = _nftMetadataURI;
        tournament.prizeNFTSet = true;
        emit PrizeNFTSet(_tournamentId, _nftMetadataURI);
    }

    /// @dev Mints achievement NFTs for participants based on milestones or performance in a tournament.
    /// @param _tournamentId ID of the tournament.
    /// @param _participant Address of the participant to mint NFT for.
    /// @param _achievementName Name of the achievement (e.g., "Top Scorer", "Participant").
    /// @param _achievementMetadataURI URI pointing to the achievement NFT metadata.
    function mintAchievementNFT(uint256 _tournamentId, address _participant, string memory _achievementName, string memory _achievementMetadataURI) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentCompleted(_tournamentId) tournamentNotCancelled(_tournamentId) participantRegistered(_tournamentId, _participant) {
        Tournament storage tournament = tournaments[_tournamentId];
        Participant storage participant = tournament.participants[_participant];
        require(!participant.achievementNFTMinted, "Achievement NFT already minted for this participant.");

        // --- NFT Minting Logic (Abstracted - needs integration with NFT contract or library) ---
        // Example: Call an external NFT contract to mint an NFT to the participant.
        //  - You would need an NFT contract deployed separately (e.g., ERC721 or ERC1155).
        //  - This function would interact with that NFT contract to mint the NFT.
        //  - For simplicity, we'll just mark it as minted in this contract for now.
        // --- End NFT Minting Logic ---

        participant.achievementNFTMinted = true;
        emit AchievementNFTMinted(_tournamentId, _participant, _achievementName);
    }


    // -------- Governance and Community Functions --------

    /// @dev Allows participants to propose changes to tournament rules or parameters.
    /// @param _tournamentId ID of the tournament to propose a rule change for.
    /// @param _ruleProposal Short description of the rule proposal.
    /// @param _proposalDetailsURI URI pointing to a document with detailed proposal information.
    function proposeRuleChange(uint256 _tournamentId, string memory _ruleProposal, string memory _proposalDetailsURI) external whenNotPaused tournamentExists(_tournamentId) registrationOpen(_tournamentId) tournamentNotCancelled(_tournamentId) participantRegistered(_tournamentId, msg.sender) {
        Tournament storage tournament = tournaments[_tournamentId];
        tournament.proposalCount++;
        uint256 proposalId = tournament.proposalCount;
        tournament.proposals[proposalId] = RuleProposal({
            id: proposalId,
            proposal: _ruleProposal,
            detailsURI: _proposalDetailsURI,
            proposer: msg.sender,
            startTime: block.timestamp, // Start voting immediately upon proposal
            endTime: block.timestamp + 7 days, // Example: 7 days voting period
            votes: mapping(address => bool)(),
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit RuleProposalCreated(_tournamentId, proposalId, _ruleProposal, msg.sender);
    }

    /// @dev Allows registered participants of a tournament to vote on rule change proposals.
    /// @param _tournamentId ID of the tournament.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _tournamentId, uint256 _proposalId, bool _vote) external whenNotPaused tournamentExists(_tournamentId) registrationOpen(_tournamentId) tournamentNotCancelled(_tournamentId) participantRegistered(_tournamentId, msg.sender) proposalExists(_tournamentId, _proposalId) proposalVotingOpen(_tournamentId, _proposalId) proposalNotExecuted(_tournamentId, _proposalId) {
        Tournament storage tournament = tournaments[_tournamentId];
        RuleProposal storage proposal = tournament.proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Participant has already voted on this proposal.");

        proposal.votes[msg.sender] = _vote; // Record vote (true for yes, absence implies no/abstain for gas optimization)
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit VotedOnProposal(_tournamentId, _proposalId, msg.sender, _vote);
    }

    /// @dev Allows admins to execute a passed proposal, applying the rule changes.
    /// @param _tournamentId ID of the tournament.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _tournamentId, uint256 _proposalId) external onlyAdmin whenNotPaused tournamentExists(_tournamentId) tournamentPending(_tournamentId) tournamentNotCancelled(_tournamentId) proposalExists(_tournamentId, _proposalId) proposalNotExecuted(_tournamentId, _proposalId) {
        Tournament storage tournament = tournaments[_tournamentId];
        RuleProposal storage proposal = tournament.proposals[_proposalId];

        require(block.timestamp > proposal.endTime, "Voting period is still ongoing."); // Ensure voting period is over

        // --- Proposal Execution Logic (Abstracted - based on proposal content) ---
        // Example: If proposal was to change entry fee, update tournament.entryFee = newFee;
        //  - This logic needs to parse the proposal content and apply the changes to the tournament.
        //  - For simplicity, we'll just mark the proposal as executed for now.
        // --- End Proposal Execution Logic ---

        // Basic passing condition: more yes votes than no votes (can be adjusted based on governance rules)
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.executed = true;
            emit ProposalExecuted(_tournamentId, _proposalId);
        } else {
            revert("Proposal failed to pass based on voting results.");
        }
    }


    // -------- Data Retrieval Functions --------

    /// @dev Retrieves detailed information about a specific tournament.
    /// @param _tournamentId ID of the tournament.
    /// @return Tournament struct containing tournament details.
    function getTournamentDetails(uint256 _tournamentId) external view tournamentExists(_tournamentId) returns (Tournament memory) {
        return tournaments[_tournamentId];
    }

    /// @dev Retrieves details about a participant in a tournament.
    /// @param _tournamentId ID of the tournament.
    /// @param _participant Address of the participant.
    /// @return Participant struct containing participant details.
    function getParticipantDetails(uint256 _tournamentId, address _participant) external view tournamentExists(_tournamentId) participantRegistered(_tournamentId, _participant) returns (Participant memory) {
        return tournaments[_tournamentId].participants[_participant];
    }

    /// @dev Retrieves all active proposals for a specific tournament.
    /// @param _tournamentId ID of the tournament.
    /// @return Array of RuleProposal structs.
    function getTournamentProposals(uint256 _tournamentId) external view tournamentExists(_tournamentId) returns (RuleProposal[] memory) {
        Tournament storage tournament = tournaments[_tournamentId];
        RuleProposal[] memory proposalsArray = new RuleProposal[](tournament.proposalCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= tournament.proposalCount; i++) {
            if (tournament.proposals[i].id == i) { // Check if proposal exists (to handle potential gaps if proposals are deleted - not in this version)
                proposalsArray[index] = tournament.proposals[i];
                index++;
            }
        }
        return proposalsArray;
    }

    /// @dev Retrieves the contract's balance in the prize token (useful for monitoring prize pools).
    /// @return Contract balance in prize token.
    function getContractBalance() public view returns (uint256) {
        if (tournamentCount > 0) { // Assuming prize token is the same for all tournaments for simplicity in fee withdrawal.
            return IERC20(tournaments[1].prizeToken).balanceOf(address(this));
        }
        return 0; // Return 0 if no tournaments created yet.
    }
}

// --- Interface for ERC20 Token ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```