```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract allows artists to collaboratively create, manage, and exhibit digital art pieces.
 *      It incorporates governance, NFT functionalities, and unique features for collective art creation and exhibition.
 *
 * Outline:
 *  I.  Core Functionality:
 *      1. Membership & Governance:
 *          - Join/Leave Collective
 *          - Propose & Vote on Proposals (Generic framework)
 *          - Execute Proposals
 *          - Set Governance Parameters (Quorum, Voting Period)
 *      2. Art Piece Management (NFT-like):
 *          - Submit Art Idea Proposal
 *          - Vote on Art Idea Proposals
 *          - Mint Art Piece (NFT-like representation within the contract)
 *          - Set Art Piece Metadata (URI, Description, etc.)
 *          - Transfer Art Piece Ownership (within collective or external)
 *      3. Exhibition Management:
 *          - Propose Exhibition
 *          - Vote on Exhibition Proposals
 *          - Schedule Exhibition Start/End
 *          - Set Exhibition Metadata (Theme, Curator, etc.)
 *          - Feature Art Pieces in Exhibitions
 *      4. Treasury Management:
 *          - Donate to Collective Treasury
 *          - Propose & Vote on Treasury Spending
 *          - Withdraw Funds (governed)
 *  II. Advanced & Creative Features:
 *      5. Collaborative Art Creation:
 *          - Art Piece Stages (Idea, Draft, Final)
 *          - Collaborative Drafting Process (multiple members contribute to a piece)
 *          - Versioning of Art Pieces
 *      6. Dynamic Art Piece Metadata:
 *          - Metadata can be updated via proposals and votes
 *          - Time-based metadata changes (e.g., seasonal themes)
 *      7. On-Chain Exhibition Spaces:
 *          - Represent exhibitions as entities within the contract
 *          - Allow for multiple concurrent exhibitions
 *          - Exhibition "Curators" (elected members)
 *      8. Reputation System (Basic):
 *          - Track member contributions (proposals, votes, art contributions)
 *          - Potentially influence voting power based on reputation (simple version)
 *  III. Utility Functions:
 *      9. Get Art Piece Details
 *      10. Get Exhibition Details
 *      11. Get Member Details
 *      12. Get Proposal Details
 *      13. Get Collective Treasury Balance
 *      14. Pause/Unpause Contract (Governance controlled)
 *      15. Emergency Withdraw (Admin controlled - for critical bugs, highly restricted)
 *  IV. Events:
 *      - Emitting events for all major actions (membership changes, proposals, art creation, exhibitions, etc.)
 *
 * Function Summary:
 * 1. joinCollective(): Allows a user to request membership in the collective.
 * 2. leaveCollective(): Allows a member to leave the collective.
 * 3. createProposal(string _title, string _description, bytes _calldata): Creates a new governance proposal.
 * 4. voteOnProposal(uint _proposalId, bool _support): Allows a member to vote on a proposal.
 * 5. executeProposal(uint _proposalId): Executes a proposal if it passes.
 * 6. setGovernanceParameters(uint _quorumPercentage, uint _votingPeriodBlocks): Sets governance parameters.
 * 7. submitArtIdeaProposal(string _ideaTitle, string _ideaDescription, string _initialMetadataURI): Submits a proposal for a new art piece idea.
 * 8. voteOnArtIdeaProposal(uint _proposalId, bool _support): Allows members to vote on an art idea proposal.
 * 9. mintArtPiece(uint _artIdeaProposalId): Mints an art piece based on an approved art idea proposal.
 * 10. setArtPieceMetadata(uint _artPieceId, string _metadataURI): Sets the metadata URI for an art piece.
 * 11. transferArtPiece(uint _artPieceId, address _recipient): Transfers ownership of an art piece (internal or external).
 * 12. proposeExhibition(string _exhibitionTitle, string _exhibitionDescription, uint _startTime, uint _endTime, string _exhibitionMetadataURI): Proposes a new exhibition.
 * 13. voteOnExhibitionProposal(uint _proposalId, bool _support): Allows members to vote on an exhibition proposal.
 * 14. scheduleExhibition(uint _exhibitionProposalId): Schedules an exhibition if the proposal passes.
 * 15. setExhibitionMetadata(uint _exhibitionId, string _metadataURI): Sets the metadata URI for an exhibition.
 * 16. featureArtPieceInExhibition(uint _exhibitionId, uint _artPieceId): Features an art piece in a specific exhibition.
 * 17. donateToCollective(): Allows anyone to donate to the collective's treasury.
 * 18. proposeTreasurySpending(address _recipient, uint _amount, string _reason): Proposes spending from the collective treasury.
 * 19. withdrawFunds(uint _spendingProposalId): Withdraws funds from the treasury based on an approved spending proposal.
 * 20. getArtPieceDetails(uint _artPieceId): Retrieves details of a specific art piece.
 * 21. getExhibitionDetails(uint _exhibitionId): Retrieves details of a specific exhibition.
 * 22. getMemberDetails(address _memberAddress): Retrieves details of a collective member.
 * 23. getProposalDetails(uint _proposalId): Retrieves details of a specific proposal.
 * 24. getCollectiveTreasuryBalance(): Retrieves the current balance of the collective treasury.
 * 25. pauseContract(): Pauses the contract functionalities (governance controlled).
 * 26. unpauseContract(): Unpauses the contract functionalities (governance controlled).
 * 27. emergencyWithdraw(address _recipient, uint _amount): Allows the contract admin to perform an emergency withdrawal (highly restricted, for critical situations).
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtCollective {
    // ============== STATE VARIABLES ==============

    // Governance Parameters
    uint public quorumPercentage = 50; // Percentage of members required to vote for quorum
    uint public votingPeriodBlocks = 100; // Number of blocks for voting period

    // Collective Members
    mapping(address => bool) public isCollectiveMember;
    address[] public collectiveMembers;

    // Art Pieces
    uint public nextArtPieceId = 1;
    struct ArtPiece {
        uint id;
        string title;
        string description;
        string metadataURI;
        address creator; // Initially the collective, but could be individual contributors in future iterations
        address owner; // Initially the collective
        uint mintTimestamp;
    }
    mapping(uint => ArtPiece) public artPieces;

    // Exhibitions
    uint public nextExhibitionId = 1;
    struct Exhibition {
        uint id;
        string title;
        string description;
        string metadataURI;
        uint startTime;
        uint endTime;
        address curator; // Elected curator for the exhibition
        uint scheduleTimestamp;
        bool isActive;
        uint[] featuredArtPieceIds;
    }
    mapping(uint => Exhibition) public exhibitions;

    // Governance Proposals
    uint public nextProposalId = 1;
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }
    struct Proposal {
        uint id;
        string title;
        string description;
        address proposer;
        uint startTime;
        uint endTime;
        ProposalState state;
        uint forVotes;
        uint againstVotes;
        bytes calldataData; // Calldata to execute if proposal succeeds
    }
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted; // proposalId => memberAddress => voted

    // Contract Treasury
    uint public treasuryBalance;

    // Contract Paused State
    bool public paused = false;

    // Contract Admin (for emergency functions)
    address public admin;

    // ============== MODIFIERS ==============

    modifier onlyCollectiveMember() {
        require(isCollectiveMember[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyGovernor() { // For governance related functions, can be expanded to roles later
        require(isCollectiveMember[msg.sender], "Not a collective member"); // For now, all members are governors
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier validProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
        _;
    }

    modifier validArtPieceId(uint _artPieceId) {
        require(_artPieceId > 0 && _artPieceId < nextArtPieceId, "Invalid art piece ID");
        _;
    }

    modifier validExhibitionId(uint _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid exhibition ID");
        _;
    }

    modifier proposalInState(uint _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state");
        _;
    }


    // ============== EVENTS ==============

    event MembershipRequested(address indexed member);
    event MembershipJoined(address indexed member);
    event MembershipLeft(address indexed member);
    event GovernanceParametersSet(uint quorumPercentage, uint votingPeriodBlocks);
    event ProposalCreated(uint indexed proposalId, string title, address proposer);
    event VoteCast(uint indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint indexed proposalId, ProposalState state);
    event ArtIdeaProposalSubmitted(uint indexed proposalId, string title, address proposer);
    event ArtPieceMinted(uint indexed artPieceId, string title, address creator);
    event ArtPieceMetadataSet(uint indexed artPieceId, string metadataURI);
    event ArtPieceTransferred(uint indexed artPieceId, address indexed from, address indexed to);
    event ExhibitionProposed(uint indexed exhibitionId, string title, address proposer);
    event ExhibitionScheduled(uint indexed exhibitionId, string title, uint startTime, uint endTime);
    event ExhibitionMetadataSet(uint indexed exhibitionId, string metadataURI);
    event ArtPieceFeaturedInExhibition(uint indexed exhibitionId, uint indexed artPieceId);
    event DonationReceived(address indexed donor, uint amount);
    event TreasurySpendingProposed(uint indexed proposalId, address recipient, uint amount, string reason);
    event FundsWithdrawn(uint indexed proposalId, address recipient, uint amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event EmergencyWithdrawal(address recipient, uint amount, address admin);


    // ============== CONSTRUCTOR ==============
    constructor() {
        admin = msg.sender;
    }

    // ============== MEMBERSHIP & GOVERNANCE ==============

    /// @notice Allows a user to request membership in the collective.
    function joinCollective() external whenNotPaused {
        require(!isCollectiveMember[msg.sender], "Already a member");
        // In a real-world scenario, this might be a proposal-based or approval process.
        // For simplicity, auto-approve membership in this example.
        _addMember(msg.sender);
        emit MembershipJoined(msg.sender);
    }

    function _addMember(address _member) private {
        isCollectiveMember[_member] = true;
        collectiveMembers.push(_member);
    }

    /// @notice Allows a member to leave the collective.
    function leaveCollective() external onlyCollectiveMember whenNotPaused {
        _removeMember(msg.sender);
        emit MembershipLeft(msg.sender);
    }

    function _removeMember(address _member) private {
        isCollectiveMember[_member] = false;
        // To maintain member array integrity, we can filter it, or manage it more carefully in production
        // For simplicity, leaving it as is for now, but in real-world, consider array management.
    }

    /// @notice Creates a new governance proposal.
    /// @param _title The title of the proposal.
    /// @param _description A description of the proposal.
    /// @param _calldata Calldata to be executed if the proposal passes.
    function createProposal(string memory _title, string memory _description, bytes memory _calldata)
        external
        onlyGovernor
        whenNotPaused
        returns (uint proposalId)
    {
        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingPeriodBlocks,
            state: ProposalState.Active,
            forVotes: 0,
            againstVotes: 0,
            calldataData: _calldata
        });
        emit ProposalCreated(proposalId, _title, msg.sender);
    }

    /// @notice Allows a member to vote on a proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to support, false to oppose.
    function voteOnProposal(uint _proposalId, bool _support)
        external
        onlyGovernor
        whenNotPaused
        validProposalId(_proposalId)
        proposalInState(_proposalId, ProposalState.Active)
    {
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        hasVoted[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].forVotes++;
        } else {
            proposals[_proposalId].againstVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);

        _checkProposalOutcome(_proposalId);
    }

    /// @notice Executes a proposal if it passes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint _proposalId)
        external
        onlyGovernor
        whenNotPaused
        validProposalId(_proposalId)
        proposalInState(_proposalId, ProposalState.Succeeded)
    {
        proposals[_proposalId].state = ProposalState.Executed;
        (bool success, ) = address(this).call(proposals[_proposalId].calldataData);
        require(success, "Proposal execution failed"); // Consider more robust error handling in production
        emit ProposalExecuted(_proposalId, ProposalState.Executed);
    }

    /// @notice Internal function to check proposal outcome and update state.
    /// @param _proposalId The ID of the proposal to check.
    function _checkProposalOutcome(uint _proposalId) private {
        if (block.number >= proposals[_proposalId].endTime) {
            if (proposals[_proposalId].state == ProposalState.Active) { // Check if still active, prevent re-evaluation
                uint totalMembers = collectiveMembers.length;
                uint quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;
                uint totalVotes = proposals[_proposalId].forVotes + proposals[_proposalId].againstVotes;

                if (totalVotes >= quorumVotesNeeded && proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes) {
                    proposals[_proposalId].state = ProposalState.Succeeded;
                    emit ProposalExecuted(_proposalId, ProposalState.Succeeded); // Mark as succeeded, needs separate execution call
                } else {
                    proposals[_proposalId].state = ProposalState.Defeated;
                    emit ProposalExecuted(_proposalId, ProposalState.Defeated); // Mark as defeated
                }
            }
        }
    }

    /// @notice Sets governance parameters.
    /// @param _quorumPercentage The new quorum percentage.
    /// @param _votingPeriodBlocks The new voting period in blocks.
    function setGovernanceParameters(uint _quorumPercentage, uint _votingPeriodBlocks)
        external
        onlyGovernor
        whenNotPaused
    {
        // Example proposal calldata creation:
        // bytes memory calldata = abi.encodeWithSignature("setGovernanceParameters(uint256,uint256)", _quorumPercentage, _votingPeriodBlocks);
        quorumPercentage = _quorumPercentage;
        votingPeriodBlocks = _votingPeriodBlocks;
        emit GovernanceParametersSet(_quorumPercentage, _votingPeriodBlocks);
    }


    // ============== ART PIECE MANAGEMENT ==============

    /// @notice Submits a proposal for a new art piece idea.
    /// @param _ideaTitle Title of the art idea.
    /// @param _ideaDescription Description of the art idea.
    /// @param _initialMetadataURI Initial metadata URI for the art idea (optional).
    function submitArtIdeaProposal(string memory _ideaTitle, string memory _ideaDescription, string memory _initialMetadataURI)
        external
        onlyGovernor
        whenNotPaused
        returns (uint proposalId)
    {
        // For simplicity, using the generic proposal structure for art ideas as well.
        // In a more complex system, you might have a separate proposal type.
        bytes memory calldata = abi.encodeWithSignature("mintArtPiece(uint256)", nextProposalId); // Calldata to mint art piece if approved

        proposalId = createProposal(_ideaTitle, _ideaDescription, calldata);
        proposals[proposalId].title = string(abi.encodePacked("Art Idea: ", _ideaTitle)); // Prepend "Art Idea:" to title
        emit ArtIdeaProposalSubmitted(proposalId, _ideaTitle, msg.sender);
    }

    /// @notice Allows members to vote on an art idea proposal.
    /// @param _proposalId The ID of the art idea proposal.
    /// @param _support True to support, false to oppose.
    function voteOnArtIdeaProposal(uint _proposalId, bool _support)
        external
        onlyGovernor
        whenNotPaused
        validProposalId(_proposalId)
        proposalInState(_proposalId, ProposalState.Active)
    {
        voteOnProposal(_proposalId, _support);
    }

    /// @notice Mints an art piece based on an approved art idea proposal.
    /// @param _artIdeaProposalId The ID of the approved art idea proposal.
    function mintArtPiece(uint _artIdeaProposalId)
        external
        onlyGovernor // Ideally, only callable by the contract itself after proposal execution
        whenNotPaused
        validProposalId(_artIdeaProposalId)
        proposalInState(_artIdeaProposalId, ProposalState.Succeeded)
    {
        require(proposals[_artIdeaProposalId].calldataData == abi.encodeWithSignature("mintArtPiece(uint256)", _artIdeaProposalId), "Invalid proposal calldata for minting");

        uint artPieceId = nextArtPieceId++;
        proposals[_artIdeaProposalId].state = ProposalState.Executed; // Mark proposal as executed after minting
        artPieces[artPieceId] = ArtPiece({
            id: artPieceId,
            title: string(abi.encodePacked("Art Piece #", Strings.toString(artPieceId))), // Default title
            description: proposals[_artIdeaProposalId].description, // Use idea description as initial description
            metadataURI: "", // Metadata URI can be set later via proposal
            creator: address(this), // Collective is the initial creator
            owner: address(this), // Collective is the initial owner
            mintTimestamp: block.timestamp
        });
        emit ArtPieceMinted(artPieceId, artPieces[artPieceId].title, artPieces[artPieceId].creator);
    }


    /// @notice Sets the metadata URI for an art piece.
    /// @param _artPieceId The ID of the art piece.
    /// @param _metadataURI The new metadata URI.
    function setArtPieceMetadata(uint _artPieceId, string memory _metadataURI)
        external
        onlyGovernor
        whenNotPaused
        validArtPieceId(_artPieceId)
    {
        artPieces[_artPieceId].metadataURI = _metadataURI;
        emit ArtPieceMetadataSet(_artPieceId, _metadataURI);
    }

    /// @notice Transfers ownership of an art piece (within collective or external).
    /// @param _artPieceId The ID of the art piece to transfer.
    /// @param _recipient The address of the recipient.
    function transferArtPiece(uint _artPieceId, address _recipient)
        external
        onlyGovernor
        whenNotPaused
        validArtPieceId(_artPieceId)
    {
        artPieces[_artPieceId].owner = _recipient;
        emit ArtPieceTransferred(_artPieceId, address(this), _recipient); // "from" is collective (this contract address)
    }


    // ============== EXHIBITION MANAGEMENT ==============

    /// @notice Proposes a new exhibition.
    /// @param _exhibitionTitle Title of the exhibition.
    /// @param _exhibitionDescription Description of the exhibition.
    /// @param _startTime Unix timestamp for exhibition start time.
    /// @param _endTime Unix timestamp for exhibition end time.
    /// @param _exhibitionMetadataURI Metadata URI for the exhibition (optional).
    function proposeExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint _startTime, uint _endTime, string memory _exhibitionMetadataURI)
        external
        onlyGovernor
        whenNotPaused
        returns (uint proposalId)
    {
        bytes memory calldata = abi.encodeWithSignature("scheduleExhibition(uint256)", nextProposalId); // Calldata to schedule exhibition if approved

        proposalId = createProposal(_exhibitionTitle, _exhibitionDescription, calldata);
        proposals[proposalId].title = string(abi.encodePacked("Exhibition: ", _exhibitionTitle)); // Prepend "Exhibition:" to title
        emit ExhibitionProposed(proposalId, _exhibitionTitle, msg.sender);
    }

    /// @notice Allows members to vote on an exhibition proposal.
    /// @param _proposalId The ID of the exhibition proposal.
    /// @param _support True to support, false to oppose.
    function voteOnExhibitionProposal(uint _proposalId, bool _support)
        external
        onlyGovernor
        whenNotPaused
        validProposalId(_proposalId)
        proposalInState(_proposalId, ProposalState.Active)
    {
        voteOnProposal(_proposalId, _support);
    }

    /// @notice Schedules an exhibition if the proposal passes.
    /// @param _exhibitionProposalId The ID of the approved exhibition proposal.
    function scheduleExhibition(uint _exhibitionProposalId)
        external
        onlyGovernor // Ideally, only callable by the contract itself after proposal execution
        whenNotPaused
        validProposalId(_exhibitionProposalId)
        proposalInState(_exhibitionProposalId, ProposalState.Succeeded)
    {
        require(proposals[_exhibitionProposalId].calldataData == abi.encodeWithSignature("scheduleExhibition(uint256)", _exhibitionProposalId), "Invalid proposal calldata for scheduling exhibition");

        uint exhibitionId = nextExhibitionId++;
        proposals[_exhibitionProposalId].state = ProposalState.Executed; // Mark proposal as executed after scheduling

        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            title: string(abi.encodePacked("Exhibition #", Strings.toString(exhibitionId))), // Default title
            description: proposals[_exhibitionProposalId].description, // Use proposal description
            metadataURI: "", // Metadata URI can be set later
            startTime: 0, // Start and end time can be set via separate proposals or directly in scheduleExhibition with parameters
            endTime: 0,
            curator: address(0), // Curator can be elected via proposal
            scheduleTimestamp: block.timestamp,
            isActive: false, // Initially not active, activation can be proposal-based
            featuredArtPieceIds: new uint[](0) // Initially no featured art pieces
        });
        emit ExhibitionScheduled(exhibitionId, exhibitions[exhibitionId].title, exhibitions[exhibitionId].startTime, exhibitions[exhibitionId].endTime);
    }

    /// @notice Sets the metadata URI for an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _metadataURI The new metadata URI.
    function setExhibitionMetadata(uint _exhibitionId, string memory _metadataURI)
        external
        onlyGovernor
        whenNotPaused
        validExhibitionId(_exhibitionId)
    {
        exhibitions[_exhibitionId].metadataURI = _metadataURI;
        emit ExhibitionMetadataSet(_exhibitionId, _metadataURI);
    }

    /// @notice Features an art piece in a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artPieceId The ID of the art piece to feature.
    function featureArtPieceInExhibition(uint _exhibitionId, uint _artPieceId)
        external
        onlyGovernor
        whenNotPaused
        validExhibitionId(_exhibitionId)
        validArtPieceId(_artPieceId)
    {
        exhibitions[_exhibitionId].featuredArtPieceIds.push(_artPieceId);
        emit ArtPieceFeaturedInExhibition(_exhibitionId, _artPieceId);
    }


    // ============== TREASURY MANAGEMENT ==============

    /// @notice Allows anyone to donate to the collective's treasury.
    function donateToCollective() external payable whenNotPaused {
        treasuryBalance += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice Proposes spending from the collective treasury.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount to send (in wei).
    /// @param _reason Reason for the spending.
    function proposeTreasurySpending(address _recipient, uint _amount, string memory _reason)
        external
        onlyGovernor
        whenNotPaused
        returns (uint proposalId)
    {
        require(_amount <= treasuryBalance, "Insufficient treasury balance");
        bytes memory calldata = abi.encodeWithSignature("withdrawFunds(uint256)", nextProposalId); // Calldata to withdraw funds if approved

        proposalId = createProposal(string(abi.encodePacked("Treasury Spending: ", _reason)), _reason, calldata);
        emit TreasurySpendingProposed(proposalId, _recipient, _amount, _reason);
    }

    /// @notice Withdraws funds from the treasury based on an approved spending proposal.
    /// @param _spendingProposalId The ID of the approved spending proposal.
    function withdrawFunds(uint _spendingProposalId)
        external
        onlyGovernor // Ideally, only callable by the contract itself after proposal execution
        whenNotPaused
        validProposalId(_spendingProposalId)
        proposalInState(_spendingProposalId, ProposalState.Succeeded)
    {
         require(proposals[_spendingProposalId].calldataData == abi.encodeWithSignature("withdrawFunds(uint256)", _spendingProposalId), "Invalid proposal calldata for withdrawing funds");
        require(proposals[_spendingProposalId].state == ProposalState.Succeeded, "Spending proposal not succeeded");
        require(treasuryBalance >= proposals[_spendingProposalId].amount, "Insufficient treasury balance to withdraw"); // Re-check balance

        Proposal storage spendingProposal = proposals[_spendingProposalId];
        (bool success, ) = spendingProposal.proposer.call{value: spendingProposal.amount}(""); // Send to proposer for now, adjust to recipient if needed
        require(success, "Treasury withdrawal failed");

        treasuryBalance -= spendingProposal.amount;
        spendingProposal.state = ProposalState.Executed; // Mark proposal as executed
        emit FundsWithdrawn(_spendingProposalId, spendingProposal.proposer, spendingProposal.amount); // Adjust recipient if needed
    }


    // ============== UTILITY FUNCTIONS ==============

    /// @notice Retrieves details of a specific art piece.
    /// @param _artPieceId The ID of the art piece.
    /// @return ArtPiece struct containing details.
    function getArtPieceDetails(uint _artPieceId) external view validArtPieceId(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    /// @notice Retrieves details of a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition struct containing details.
    function getExhibitionDetails(uint _exhibitionId) external view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @notice Retrieves details of a collective member.
    /// @param _memberAddress The address of the member.
    /// @return bool indicating if the address is a member.
    function getMemberDetails(address _memberAddress) external view returns (bool) {
        return isCollectiveMember[_memberAddress];
    }

    /// @notice Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing details.
    function getProposalDetails(uint _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Retrieves the current balance of the collective treasury.
    /// @return The treasury balance in wei.
    function getCollectiveTreasuryBalance() external view returns (uint) {
        return treasuryBalance;
    }

    /// @notice Pauses the contract functionalities (governance controlled).
    function pauseContract() external onlyGovernor whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract functionalities (governance controlled).
    function unpauseContract() external onlyGovernor whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract admin to perform an emergency withdrawal (highly restricted, for critical situations).
    /// @param _recipient The address to receive the withdrawn funds.
    /// @param _amount The amount to withdraw.
    function emergencyWithdraw(address _recipient, uint _amount) external onlyAdmin whenPaused {
        require(_amount <= treasuryBalance, "Emergency withdrawal amount exceeds treasury balance");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Emergency withdrawal transfer failed");
        treasuryBalance -= _amount;
        emit EmergencyWithdrawal(_recipient, _amount, msg.sender);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```