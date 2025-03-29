```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Gemini AI
 * @dev A smart contract for a decentralized research organization, enabling proposal submission, voting, funding,
 *      reputation management, decentralized data storage, and more advanced features.
 *
 * Function Summary:
 * -----------------
 * **Proposal Management:**
 * 1. submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _ipfsHash): Allows researchers to submit research proposals.
 * 2. getProposalDetails(uint256 _proposalId): Retrieves detailed information about a specific research proposal.
 * 3. updateResearchProposal(uint256 _proposalId, string _description, uint256 _fundingGoal, string _ipfsHash): Allows researchers to update their proposal before voting starts.
 * 4. cancelResearchProposal(uint256 _proposalId): Allows the proposer to cancel their research proposal before voting starts.
 * 5. getActiveProposals(): Returns a list of IDs of currently active research proposals.
 * 6. getProposalStatus(uint256 _proposalId): Returns the current status of a research proposal (e.g., pending, voting, funded, rejected).
 *
 * **Voting and Governance:**
 * 7. startProposalVoting(uint256 _proposalId, uint256 _votingDurationDays): Starts the voting process for a research proposal.
 * 8. castVote(uint256 _proposalId, bool _support): Allows members to cast their vote for or against a proposal.
 * 9. getVotingResults(uint256 _proposalId): Retrieves the voting results for a proposal after voting has ended.
 * 10. executeProposal(uint256 _proposalId): Executes a successful proposal, transferring funds to the researcher.
 * 11. setQuorumPercentage(uint8 _quorumPercentage): Allows the DAO to set the quorum percentage required for proposal approval (governance function).
 * 12. setVotingDurationDays(uint256 _defaultVotingDurationDays): Allows the DAO to set the default voting duration (governance function).
 *
 * **Researcher and Reputation Management:**
 * 13. registerResearcher(string _researcherName, string _ipfsProfileHash): Allows researchers to register their profiles.
 * 14. getResearcherProfile(address _researcherAddress): Retrieves the profile information of a registered researcher.
 * 15. reportResearchProgress(uint256 _proposalId, string _progressReport, string _ipfsReportHash): Allows researchers to report progress on funded projects.
 * 16. rateResearcher(address _researcherAddress, uint8 _rating, string _feedback): Allows community members to rate researchers based on their work.
 * 17. getResearcherRating(address _researcherAddress): Retrieves the average rating of a researcher.
 *
 * **Decentralized Data Storage and Access:**
 * 18. storeResearchData(uint256 _proposalId, string _dataDescription, string _ipfsDataHash): Allows researchers to store research data associated with a proposal.
 * 19. getResearchDataHashes(uint256 _proposalId): Retrieves a list of IPFS hashes of research data associated with a proposal.
 * 20. accessResearchData(uint256 _proposalId, uint256 _dataIndex): Allows authorized users to access research data (future access control can be added).
 *
 * **Treasury and Funding:**
 * 21. contributeToTreasury(): Allows anyone to contribute funds to the DARO treasury.
 * 22. getTreasuryBalance(): Returns the current balance of the DARO treasury.
 * 23. refundProposalFunds(uint256 _proposalId): Refunds contributed funds to voters if a proposal fails (optional, can be implemented for specific use cases).
 */
contract DecentralizedAutonomousResearchOrganization {

    // --- Data Structures ---
    struct ResearchProposal {
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        string ipfsHash; // IPFS hash for detailed proposal document
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voters; // Track who has voted
        string[] researchDataHashes; // IPFS hashes of research data
    }

    struct ResearcherProfile {
        string researcherName;
        string ipfsProfileHash; // IPFS hash for researcher profile
        uint8 totalRatings;
        uint8 ratingCount;
    }

    enum ProposalStatus {
        Pending,
        Voting,
        Funded,
        Rejected,
        Cancelled,
        Executed
    }

    // --- State Variables ---
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(address => ResearcherProfile) public researcherProfiles;
    uint256 public proposalCounter;
    uint256 public treasuryBalance;
    address public daoGovernor; // Address that can manage governance settings
    uint8 public quorumPercentage = 50; // Default quorum percentage for voting (50%)
    uint256 public defaultVotingDurationDays = 7; // Default voting duration in days

    // --- Events ---
    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalUpdated(uint256 proposalId, string description, uint256 fundingGoal, string ipfsHash);
    event ProposalCancelled(uint256 proposalId);
    event VotingStarted(uint256 proposalId, uint256 votingEndTime);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalFunded(uint256 proposalId, address researcher, uint256 fundingAmount);
    event ProposalRejected(uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);
    event ResearcherRegistered(address researcherAddress, string researcherName);
    event ResearchProgressReported(uint256 proposalId, address researcher, string progressReport);
    event ResearcherRated(address researcherAddress, address rater, uint8 rating, string feedback);
    event ResearchDataStored(uint256 proposalId, address researcher, string dataDescription, string ipfsDataHash);
    event QuorumPercentageUpdated(uint8 newQuorumPercentage);
    event VotingDurationUpdated(uint256 newVotingDurationDays);
    event TreasuryContribution(address contributor, uint256 amount);

    // --- Modifiers ---
    modifier onlyDAO() {
        require(msg.sender == daoGovernor, "Only DAO governor can call this function.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposer != address(0), "Proposal does not exist.");
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposer can call this function.");
        _;
    }

    modifier validProposalStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Invalid proposal status for this action.");
        _;
    }

    modifier votingNotStarted(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Pending, "Voting already started or proposal not pending.");
        _;
    }

    modifier votingInProgress(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Voting, "Voting is not in progress.");
        require(block.timestamp <= researchProposals[_proposalId].votingEndTime, "Voting has ended.");
        _;
    }

    modifier votingEnded(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Voting, "Voting is not in progress.");
        require(block.timestamp > researchProposals[_proposalId].votingEndTime, "Voting has not ended.");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!researchProposals[_proposalId].voters[msg.sender], "You have already voted on this proposal.");
        _;
    }

    modifier researcherRegistered(address _researcherAddress) {
        require(keccak256(bytes(researcherProfiles[_researcherAddress].researcherName)) != keccak256(bytes("")), "Researcher is not registered.");
        _;
    }

    // --- Constructor ---
    constructor() {
        daoGovernor = msg.sender; // Initially, the contract deployer is the DAO governor
    }

    // --- Proposal Management Functions ---

    /// @notice Allows researchers to submit research proposals.
    /// @param _title The title of the research proposal.
    /// @param _description A brief description of the research proposal.
    /// @param _fundingGoal The funding goal in Wei for the research proposal.
    /// @param _ipfsHash IPFS hash of the detailed research proposal document.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHash
    ) public researcherRegistered(msg.sender) {
        proposalCounter++;
        researchProposals[proposalCounter] = ResearchProposal({
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            ipfsHash: _ipfsHash,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0,
            researchDataHashes: new string[](0)
        });
        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /// @notice Retrieves detailed information about a specific research proposal.
    /// @param _proposalId The ID of the research proposal.
    /// @return Returns proposal details.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (
        address proposer,
        string memory title,
        string memory description,
        uint256 fundingGoal,
        string memory ipfsHash,
        ProposalStatus status,
        uint256 votingStartTime,
        uint256 votingEndTime,
        uint256 votesFor,
        uint256 votesAgainst
    ) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.fundingGoal,
            proposal.ipfsHash,
            proposal.status,
            proposal.votingStartTime,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }

    /// @notice Allows researchers to update their proposal before voting starts.
    /// @param _proposalId The ID of the research proposal to update.
    /// @param _description Updated description of the research proposal.
    /// @param _fundingGoal Updated funding goal for the research proposal.
    /// @param _ipfsHash Updated IPFS hash of the detailed proposal document.
    function updateResearchProposal(
        uint256 _proposalId,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHash
    ) public proposalExists(_proposalId) onlyProposer(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        researchProposals[_proposalId].description = _description;
        researchProposals[_proposalId].fundingGoal = _fundingGoal;
        researchProposals[_proposalId].ipfsHash = _ipfsHash;
        emit ProposalUpdated(_proposalId, _description, _fundingGoal, _ipfsHash);
    }

    /// @notice Allows the proposer to cancel their research proposal before voting starts.
    /// @param _proposalId The ID of the research proposal to cancel.
    function cancelResearchProposal(uint256 _proposalId) public proposalExists(_proposalId) onlyProposer(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        researchProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Returns a list of IDs of currently active research proposals (Pending or Voting).
    /// @return An array of proposal IDs.
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (researchProposals[i].status == ProposalStatus.Pending || researchProposals[i].status == ProposalStatus.Voting) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of active proposals
        uint256[] memory resizedActiveProposalIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedActiveProposalIds[i] = activeProposalIds[i];
        }
        return resizedActiveProposalIds;
    }

    /// @notice Returns the current status of a research proposal.
    /// @param _proposalId The ID of the research proposal.
    /// @return The ProposalStatus enum value.
    function getProposalStatus(uint256 _proposalId) public view proposalExists(_proposalId) returns (ProposalStatus) {
        return researchProposals[_proposalId].status;
    }


    // --- Voting and Governance Functions ---

    /// @notice Starts the voting process for a research proposal. Only DAO governor can start voting.
    /// @param _proposalId The ID of the research proposal to start voting for.
    /// @param _votingDurationDays The duration of the voting period in days.
    function startProposalVoting(uint256 _proposalId, uint256 _votingDurationDays) public onlyDAO proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        researchProposals[_proposalId].status = ProposalStatus.Voting;
        researchProposals[_proposalId].votingStartTime = block.timestamp;
        researchProposals[_proposalId].votingEndTime = block.timestamp + (_votingDurationDays * 1 days); // Convert days to seconds
        emit VotingStarted(_proposalId, researchProposals[_proposalId].votingEndTime);
    }

    /// @notice Starts the voting process for a research proposal with default duration. Only DAO governor can start voting.
    /// @param _proposalId The ID of the research proposal to start voting for.
    function startProposalVoting(uint256 _proposalId) public onlyDAO proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        startProposalVoting(_proposalId, defaultVotingDurationDays);
    }

    /// @notice Allows members to cast their vote for or against a proposal.
    /// @param _proposalId The ID of the research proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function castVote(uint256 _proposalId, bool _support) public votingInProgress(_proposalId) notVoted(_proposalId) {
        researchProposals[_proposalId].voters[msg.sender] = true;
        if (_support) {
            researchProposals[_proposalId].votesFor++;
        } else {
            researchProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Retrieves the voting results for a proposal after voting has ended.
    /// @param _proposalId The ID of the research proposal.
    /// @return votesFor The number of votes in favor.
    /// @return votesAgainst The number of votes against.
    /// @return passed Boolean indicating if the proposal passed.
    function getVotingResults(uint256 _proposalId) public view proposalExists(_proposalId) votingEnded(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, bool passed) {
        votesFor = researchProposals[_proposalId].votesFor;
        votesAgainst = researchProposals[_proposalId].votesAgainst;
        uint256 totalVotes = votesFor + votesAgainst;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;
        if (totalVotes >= quorum && votesFor > votesAgainst) { // Simple majority with quorum
            passed = true;
        } else {
            passed = false;
        }
    }

    /// @notice Executes a successful proposal, transferring funds to the researcher.
    /// @param _proposalId The ID of the research proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyDAO proposalExists(_proposalId) votingEnded(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Voting) {
        (uint256 votesFor, uint256 votesAgainst, bool passed) = getVotingResults(_proposalId);
        if (passed) {
            ResearchProposal storage proposal = researchProposals[_proposalId];
            require(treasuryBalance >= proposal.fundingGoal, "Insufficient funds in treasury.");
            payable(proposal.proposer).transfer(proposal.fundingGoal);
            treasuryBalance -= proposal.fundingGoal;
            proposal.status = ProposalStatus.Funded; // Status changed to Funded after execution. Can refine to 'Executed' if needed after funds transferred.
            emit ProposalFunded(_proposalId, proposal.proposer, proposal.fundingGoal);
            emit ProposalExecuted(_proposalId); // Adding an event to specifically mark execution.
        } else {
            researchProposals[_proposalId].status = ProposalStatus.Rejected;
            emit ProposalRejected(_proposalId);
        }
    }

    /// @notice Allows the DAO governor to set the quorum percentage required for proposal approval.
    /// @param _quorumPercentage The new quorum percentage (0-100).
    function setQuorumPercentage(uint8 _quorumPercentage) public onlyDAO {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _quorumPercentage;
        emit QuorumPercentageUpdated(_quorumPercentage);
    }

    /// @notice Allows the DAO governor to set the default voting duration in days.
    /// @param _defaultVotingDurationDays The new default voting duration in days.
    function setVotingDurationDays(uint256 _defaultVotingDurationDays) public onlyDAO {
        defaultVotingDurationDays = _defaultVotingDurationDays;
        emit VotingDurationUpdated(_defaultVotingDurationDays);
    }


    // --- Researcher and Reputation Management Functions ---

    /// @notice Allows researchers to register their profiles.
    /// @param _researcherName The name of the researcher.
    /// @param _ipfsProfileHash IPFS hash of the detailed researcher profile document.
    function registerResearcher(string memory _researcherName, string memory _ipfsProfileHash) public {
        require(keccak256(bytes(researcherProfiles[msg.sender].researcherName)) == keccak256(bytes("")), "Researcher already registered.");
        researcherProfiles[msg.sender] = ResearcherProfile({
            researcherName: _researcherName,
            ipfsProfileHash: _ipfsProfileHash,
            totalRatings: 0,
            ratingCount: 0
        });
        emit ResearcherRegistered(msg.sender, _researcherName);
    }

    /// @notice Retrieves the profile information of a registered researcher.
    /// @param _researcherAddress The address of the researcher.
    /// @return researcherName The name of the researcher.
    /// @return ipfsProfileHash IPFS hash of the researcher's profile.
    function getResearcherProfile(address _researcherAddress) public view researcherRegistered(_researcherAddress) returns (string memory researcherName, string memory ipfsProfileHash) {
        ResearcherProfile storage profile = researcherProfiles[_researcherAddress];
        return (profile.researcherName, profile.ipfsProfileHash);
    }

    /// @notice Allows researchers to report progress on funded projects.
    /// @param _proposalId The ID of the funded research proposal.
    /// @param _progressReport A brief text progress report.
    /// @param _ipfsReportHash IPFS hash of a detailed progress report document.
    function reportResearchProgress(uint256 _proposalId, string memory _progressReport, string memory _ipfsReportHash) public proposalExists(_proposalId) onlyProposer(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) {
        // Potentially add more checks to ensure it's a truly funded proposal and researcher is the proposer
        // For now, basic checks are sufficient.
        emit ResearchProgressReported(_proposalId, msg.sender, _progressReport);
        // Consider storing progress reports in a more structured way if needed.
    }

    /// @notice Allows community members to rate researchers based on their work.
    /// @param _researcherAddress The address of the researcher to rate.
    /// @param _rating The rating (e.g., 1-5 scale).
    /// @param _feedback Optional feedback text.
    function rateResearcher(address _researcherAddress, uint8 _rating, string memory _feedback) public researcherRegistered(_researcherAddress) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Example 1-5 scale
        ResearcherProfile storage profile = researcherProfiles[_researcherAddress];
        profile.totalRatings += _rating;
        profile.ratingCount++;
        emit ResearcherRated(_researcherAddress, msg.sender, _rating, _feedback);
        // Consider adding restrictions on who can rate (e.g., voters on proposals, token holders, etc.) for enhanced reputation system.
    }

    /// @notice Retrieves the average rating of a researcher.
    /// @param _researcherAddress The address of the researcher.
    /// @return averageRating The average rating, scaled by 100 (to handle decimals without floating point).
    function getResearcherRating(address _researcherAddress) public view researcherRegistered(_researcherAddress) returns (uint256 averageRating) {
        ResearcherProfile storage profile = researcherProfiles[_researcherAddress];
        if (profile.ratingCount == 0) {
            return 0; // No ratings yet
        }
        return (profile.totalRatings * 100) / profile.ratingCount; // Scaled average
    }


    // --- Decentralized Data Storage and Access Functions ---

    /// @notice Allows researchers to store research data associated with a proposal.
    /// @param _proposalId The ID of the research proposal.
    /// @param _dataDescription A description of the data being stored.
    /// @param _ipfsDataHash IPFS hash of the research data.
    function storeResearchData(uint256 _proposalId, string memory _dataDescription, string memory _ipfsDataHash) public proposalExists(_proposalId) onlyProposer(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        proposal.researchDataHashes.push(_ipfsDataHash);
        emit ResearchDataStored(_proposalId, msg.sender, _dataDescription, _ipfsDataHash);
    }

    /// @notice Retrieves a list of IPFS hashes of research data associated with a proposal.
    /// @param _proposalId The ID of the research proposal.
    /// @return An array of IPFS data hashes.
    function getResearchDataHashes(uint256 _proposalId) public view proposalExists(_proposalId) returns (string[] memory) {
        return researchProposals[_proposalId].researchDataHashes;
    }

    /// @notice Allows authorized users to access research data (currently public access, can be enhanced with access control).
    /// @param _proposalId The ID of the research proposal.
    /// @param _dataIndex The index of the data hash in the researchDataHashes array.
    /// @return The IPFS hash of the research data.
    function accessResearchData(uint256 _proposalId, uint256 _dataIndex) public view proposalExists(_proposalId) returns (string memory ipfsDataHash) {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(_dataIndex < proposal.researchDataHashes.length, "Invalid data index.");
        return proposal.researchDataHashes[_dataIndex];
    }


    // --- Treasury and Funding Functions ---

    /// @notice Allows anyone to contribute funds to the DARO treasury.
    function contributeToTreasury() public payable {
        treasuryBalance += msg.value;
        emit TreasuryContribution(msg.sender, msg.value);
    }

    /// @notice Returns the current balance of the DARO treasury.
    /// @return The treasury balance in Wei.
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    /// @notice Optional function to refund contributed funds if a proposal fails (example, can be customized based on funding model).
    /// @param _proposalId The ID of the rejected research proposal.
    function refundProposalFunds(uint256 _proposalId) public onlyDAO proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Rejected) {
        // This is a placeholder. Refund logic needs to be designed based on how funding was collected.
        // For example, if users directly funded proposals, you'd need to track contributors and amounts per proposal.
        // For a simpler treasury model, refunds might not be directly linked to specific proposals.
        // In this basic example, no direct refund mechanism is implemented, but you could add logic to return funds
        // to voters or contributors based on your specific funding model.
        // For now, just emitting an event to indicate a potential refund action (implementation needed).
        // emit ProposalFundsRefundInitiated(_proposalId);
        // Placeholder comment to remind that actual refund logic needs to be implemented based on requirements.
    }


    // --- Governance Functions (beyond setQuorumPercentage and setVotingDurationDays) ---
    // More advanced governance functions could be added, such as:
    // - Change DAO Governor
    // - Implement a more sophisticated voting system (e.g., quadratic voting, ranked-choice voting)
    // - Token-based governance (require holding a governance token to vote)
    // - Delegation of voting power
    // - Proposal categories and different voting rules for each category
    // - Time-lock mechanisms for critical governance changes
    // - ... and many more depending on the desired level of decentralization and complexity.
}
```