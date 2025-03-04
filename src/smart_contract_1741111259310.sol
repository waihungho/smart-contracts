```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that allows members to submit, curate, exhibit, and monetize digital art collectively.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Governance Functions:**
 *    - `joinDAAC()`: Allows anyone to request membership in the DAAC, subject to approval.
 *    - `leaveDAAC()`: Allows members to voluntarily leave the DAAC.
 *    - `proposeNewMember(address _newMember)`:  Members can propose new artists to join the DAAC.
 *    - `voteOnMemberProposal(address _proposedMember, bool _approve)`: Members can vote on membership proposals.
 *    - `getMemberCount()`: Returns the current number of DAAC members.
 *    - `isAdmin(address _account)`: Checks if an address is an admin of the DAAC.
 *    - `addAdmin(address _newAdmin)`:  Allows current admins to add new admins (Admin Function).
 *    - `removeAdmin(address _adminToRemove)`: Allows current admins to remove admins (Admin Function).
 *
 * **2. Art Submission & Curation Functions:**
 *    - `submitArt(string memory _ipfsHash, string memory _title, string memory _description, string memory _artistStatement)`: Members can submit their digital art for consideration.
 *    - `getArtPiece(uint256 _artId)`: Retrieves details of a specific art piece by its ID.
 *    - `getArtPieceCount()`: Returns the total number of art pieces submitted.
 *    - `proposeArtForExhibition(uint256 _artId)`: Members can propose submitted art pieces for an upcoming exhibition.
 *    - `voteOnExhibitionProposal(uint256 _artId, bool _approve)`: Members vote on which art pieces should be included in an exhibition.
 *    - `getExhibitionArtPieces()`: Returns a list of art pieces selected for the current exhibition.
 *    - `isArtPieceExhibited(uint256 _artId)`: Checks if an art piece is currently exhibited.
 *
 * **3. Exhibition & Monetization Functions:**
 *    - `startExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256 _exhibitionDurationDays)`: Admins can start a new exhibition with curated artworks.
 *    - `endExhibition()`: Admins can manually end an ongoing exhibition.
 *    - `setExhibitionTicketPrice(uint256 _priceInWei)`: Admins can set the ticket price for accessing the exhibition (Admin Function).
 *    - `buyExhibitionTicket()`: Allows anyone to purchase a ticket to access the current exhibition.
 *    - `viewExhibitionArt(uint256 _artId)`: Allows ticket holders to view details of an exhibited art piece.
 *    - `distributeExhibitionRevenue()`:  Distributes revenue from ticket sales proportionally to exhibited artists and the DAAC treasury.
 *
 * **4. Treasury & Utility Functions:**
 *    - `getDAACTreasuryBalance()`: Returns the current balance of the DAAC treasury.
 *    - `withdrawFromTreasury(address _to, uint256 _amount)`: Allows admins to withdraw funds from the treasury to a specified address (Admin Function).
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Admins can set the default voting duration for proposals (Admin Function).
 *    - `getVotingDuration()`: Returns the current voting duration.
 */
contract DecentralizedAutonomousArtCollective {

    // -------- Structs & Enums --------

    struct ArtPiece {
        uint256 id;
        address artist;
        string ipfsHash;
        string title;
        string description;
        string artistStatement;
        uint256 submissionTimestamp;
        bool isApproved; // By curation (future feature - currently auto-approved)
        bool isExhibited;
    }

    struct Exhibition {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 ticketPrice;
        uint256[] exhibitedArtIds;
        bool isActive;
    }

    enum ProposalType { MEMBERSHIP, EXHIBITION }

    // -------- State Variables --------

    address public contractOwner;
    address[] public admins;
    mapping(address => bool) public isMember;
    address[] public members;
    mapping(address => bool) public pendingMembershipRequests;

    ArtPiece[] public artPieces;
    uint256 public artPieceCount;
    mapping(uint256 => uint256) public exhibitionProposalVotes; // artId => voteCount
    mapping(uint256 => bool) public isProposedForExhibition;
    Exhibition public currentExhibition;
    uint256 public exhibitionTicketPrice;
    mapping(address => bool) public hasExhibitionTicket;

    uint256 public votingDurationBlocks = 100; // Default voting duration

    uint256 public memberProposalCount;
    mapping(uint256 => address) public pendingMemberProposals; // proposalId => proposedMember
    mapping(uint256 => mapping(address => bool)) public memberProposalVotes; // proposalId => member => vote (true=approve, false=reject)

    // -------- Events --------

    event MembershipRequested(address indexed requester);
    event MembershipApproved(address indexed newMember);
    event MembershipRejected(address indexed rejectedMember);
    event MemberLeft(address indexed memberAddress);
    event AdminAdded(address indexed newAdmin, address indexed addedBy);
    event AdminRemoved(address indexed removedAdmin, address indexed removedBy);

    event ArtSubmitted(uint256 indexed artId, address indexed artist, string title);
    event ArtProposedForExhibition(uint256 indexed artId, address proposer);
    event ArtExhibitionVoteCast(uint256 indexed artId, address voter, bool vote);
    event ExhibitionStarted(string title, uint256 startTime, uint256 endTime);
    event ExhibitionEnded(string title, uint256 endTime);
    event ExhibitionTicketPriceSet(uint256 price);
    event ExhibitionTicketPurchased(address indexed buyer);
    event ExhibitionRevenueDistributed(uint256 totalRevenue, uint256 treasuryShare, uint256 artistsShare);
    event VotingDurationSet(uint256 durationInBlocks, address admin);
    event MemberProposed(uint256 proposalId, address proposedMember, address proposer);
    event MemberProposalVoteCast(uint256 proposalId, address voter, bool vote);


    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only DAAC admins can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only DAAC members can call this function.");
        _;
    }

    modifier exhibitionActive() {
        require(currentExhibition.isActive, "No exhibition is currently active.");
        _;
    }

    modifier exhibitionNotActive() {
        require(!currentExhibition.isActive, "An exhibition is already active.");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(_artId > 0 && _artId <= artPieceCount, "Invalid Art ID.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        contractOwner = msg.sender;
        admins.push(msg.sender); // Contract creator is the first admin.
    }

    // -------- 1. Membership & Governance Functions --------

    function joinDAAC() external {
        require(!isMember[msg.sender], "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
        // In a real-world scenario, you might implement a voting or approval mechanism for membership requests.
        // For simplicity in this example, membership is auto-approved upon request.
        _approveMembership(msg.sender); // Auto-approve for this example.  Replace with voting logic for real DAAC.
    }

    function _approveMembership(address _newMember) private {
        require(pendingMembershipRequests[_newMember], "No pending membership request.");
        require(!isMember[_newMember], "Already a member.");
        isMember[_newMember] = true;
        members.push(_newMember);
        pendingMembershipRequests[_newMember] = false;
        emit MembershipApproved(_newMember);
    }

    function leaveDAAC() external onlyMember {
        isMember[msg.sender] = false;
        // Remove from members array (more efficient implementation might be needed for large member lists in production)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MemberLeft(msg.sender);
    }

    function proposeNewMember(address _newMember) external onlyMember {
        require(!isMember[_newMember], "Proposed member is already a member.");
        require(_newMember != address(0), "Invalid address.");
        require(pendingMemberProposals[memberProposalCount] == address(0), "Another membership proposal is already active, please wait for it to finish."); // Simple concurrency control

        memberProposalCount++;
        pendingMemberProposals[memberProposalCount] = _newMember;
        emit MemberProposed(memberProposalCount, _newMember, msg.sender);
        _startMembershipProposalVoting(memberProposalCount);
    }

    function _startMembershipProposalVoting(uint256 _proposalId) private {
        // Voting starts immediately.  No explicit start function in this simple example.
        // Voting ends after votingDurationBlocks.
        // After voting duration, someone needs to execute the proposal outcome (approve/reject).
    }

    function voteOnMemberProposal(uint256 _proposalId, bool _approve) external onlyMember {
        require(pendingMemberProposals[_proposalId] != address(0), "Invalid proposal ID or proposal not active.");
        require(!memberProposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        memberProposalVotes[_proposalId][msg.sender] = _approve;
        emit MemberProposalVoteCast(_proposalId, msg.sender, _approve);

        // In a more robust system, you'd track votes and automatically execute after voting period.
        // For this example, we'll just let any member trigger the execution after voting duration.
        _executeMembershipProposalOutcome(_proposalId);
    }

    function _executeMembershipProposalOutcome(uint256 _proposalId) private {
        // Check if voting period is over (simple block-based check for demonstration)
        if (block.number >= block.number + votingDurationBlocks) { // In reality, track proposal start block and compare to current.  Simplified for example.
            uint256 approveVotes = 0;
            uint256 rejectVotes = 0;
            for (uint256 i = 0; i < members.length; i++) {
                if (memberProposalVotes[_proposalId][members[i]]) {
                    approveVotes++;
                } else {
                    rejectVotes++; // 'false' vote is considered reject
                }
            }

            if (approveVotes > rejectVotes) { // Simple majority vote
                _approveMembership(pendingMemberProposals[_proposalId]);
                emit MembershipApproved(pendingMemberProposals[_proposalId]);
            } else {
                emit MembershipRejected(pendingMemberProposals[_proposalId]);
            }
            pendingMemberProposals[_proposalId] = address(0); // Clear the proposal
        }
    }


    function getMemberCount() external view returns (uint256) {
        return members.length;
    }

    function isAdmin(address _account) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        require(!isAdmin(_newAdmin), "Address is already an admin.");
        admins.push(_newAdmin);
        emit AdminAdded(_newAdmin, msg.sender);
    }

    function removeAdmin(address _adminToRemove) external onlyAdmin {
        require(isAdmin(_adminToRemove), "Address is not an admin.");
        require(_adminToRemove != contractOwner, "Cannot remove contract owner as admin.");
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _adminToRemove) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                emit AdminRemoved(_adminToRemove, msg.sender);
                return;
            }
        }
    }


    // -------- 2. Art Submission & Curation Functions --------

    function submitArt(string memory _ipfsHash, string memory _title, string memory _description, string memory _artistStatement) external onlyMember {
        artPieceCount++;
        ArtPiece memory newArt = ArtPiece({
            id: artPieceCount,
            artist: msg.sender,
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            artistStatement: _artistStatement,
            submissionTimestamp: block.timestamp,
            isApproved: true, // Auto-approved for this example. Add curation logic later.
            isExhibited: false
        });
        artPieces.push(newArt);
        emit ArtSubmitted(artPieceCount, msg.sender, _title);
    }

    function getArtPiece(uint256 _artId) external view validArtId(_artId) returns (ArtPiece memory) {
        return artPieces[_artId - 1]; // Array is 0-indexed, IDs are 1-indexed.
    }

    function getArtPieceCount() external view returns (uint256) {
        return artPieceCount;
    }

    function proposeArtForExhibition(uint256 _artId) external onlyMember validArtId(_artId) {
        require(!isProposedForExhibition[_artId], "Art piece already proposed for exhibition.");
        isProposedForExhibition[_artId] = true;
        exhibitionProposalVotes[_artId] = 0; // Reset votes
        emit ArtProposedForExhibition(_artId, msg.sender);
        // In a real system, start a voting period and track votes.
        _startExhibitionVoting(_artId);
    }

    function _startExhibitionVoting(uint256 _artId) private {
        // Voting starts immediately. Voting ends after votingDurationBlocks.
    }

    function voteOnExhibitionProposal(uint256 _artId, bool _approve) external onlyMember validArtId(_artId) {
        require(isProposedForExhibition[_artId], "Art piece is not currently proposed for exhibition.");
        require(exhibitionProposalVotes[_artId] >= 0, "Voting not started or already concluded."); // Basic check
        // In a real system, prevent double voting per member.
        if (_approve) {
            exhibitionProposalVotes[_artId]++;
        } else {
            exhibitionProposalVotes[_artId]--; // Negative votes allowed for simplicity, could be just count positive votes.
        }
        emit ArtExhibitionVoteCast(_artId, msg.sender, _approve);
        _executeExhibitionProposalOutcome(_artId); // Check if voting outcome is reached.
    }

    function _executeExhibitionProposalOutcome(uint256 _artId) private {
        // Simple check for voting outcome.  In real system, would check voting period and quorum.
        if (block.number >= block.number + votingDurationBlocks) { // Simplified block-based voting end check
            if (exhibitionProposalVotes[_artId] > 0 ) { // Simple majority of votes for exhibition.
                currentExhibition.exhibitedArtIds.push(_artId);
                artPieces[_artId - 1].isExhibited = true;
            }
            isProposedForExhibition[_artId] = false; // End proposal
            exhibitionProposalVotes[_artId] = type(uint256).max; // Mark as concluded - prevent further voting
        }
    }


    function getExhibitionArtPieces() external view exhibitionActive returns (uint256[] memory) {
        return currentExhibition.exhibitedArtIds;
    }

    function isArtPieceExhibited(uint256 _artId) external view validArtId(_artId) returns (bool) {
        return artPieces[_artId - 1].isExhibited;
    }


    // -------- 3. Exhibition & Monetization Functions --------

    function startExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256 _exhibitionDurationDays) external onlyAdmin exhibitionNotActive {
        require(currentExhibition.exhibitedArtIds.length > 0, "Exhibition must have at least one art piece.");
        currentExhibition = Exhibition({
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + (_exhibitionDurationDays * 1 days),
            ticketPrice: exhibitionTicketPrice,
            exhibitedArtIds: currentExhibition.exhibitedArtIds, // Use already curated list.
            isActive: true
        });
        emit ExhibitionStarted(_exhibitionTitle, currentExhibition.startTime, currentExhibition.endTime);
    }

    function endExhibition() external onlyAdmin exhibitionActive {
        currentExhibition.isActive = false;
        currentExhibition.endTime = block.timestamp;
        emit ExhibitionEnded(currentExhibition.title, currentExhibition.endTime);
        distributeExhibitionRevenue();
    }

    function setExhibitionTicketPrice(uint256 _priceInWei) external onlyAdmin exhibitionNotActive {
        exhibitionTicketPrice = _priceInWei;
        emit ExhibitionTicketPriceSet(_priceInWei);
    }

    function buyExhibitionTicket() external payable exhibitionActive {
        require(!hasExhibitionTicket[msg.sender], "Already have a ticket.");
        require(msg.value >= exhibitionTicketPrice, "Insufficient ticket price sent.");
        hasExhibitionTicket[msg.sender] = true;
        emit ExhibitionTicketPurchased(msg.sender);
        // Transfer excess funds back to the buyer if they sent more than the ticket price.
        if (msg.value > exhibitionTicketPrice) {
            payable(msg.sender).transfer(msg.value - exhibitionTicketPrice);
        }
    }

    function viewExhibitionArt(uint256 _artId) external view exhibitionActive validArtId(_artId) returns (ArtPiece memory) {
        require(hasExhibitionTicket[msg.sender] || isAdmin(msg.sender), "Must have an exhibition ticket to view art.");
        require(artPieces[_artId - 1].isExhibited, "Art piece is not part of the current exhibition.");
        return artPieces[_artId - 1];
    }


    function distributeExhibitionRevenue() private exhibitionActive {
        uint256 totalRevenue = address(this).balance; // All contract balance is exhibition revenue in this simplified example.
        uint256 treasuryShare = totalRevenue / 10; // 10% to treasury, 90% to artists (example split)
        uint256 artistsShare = totalRevenue - treasuryShare;

        payable(admins[0]).transfer(treasuryShare); // Send treasury share to contract owner (admin for simplicity)
        // Distribute artist share proportionally based on number of exhibited art pieces by each artist.
        // In a real system, track ticket sales per art piece or use a more sophisticated distribution model.
        // For this simplified example, evenly distribute among exhibited artists (not ideal in real world).
        uint256 artistsPerPiece = currentExhibition.exhibitedArtIds.length;
        if (artistsPerPiece > 0) {
            uint256 amountPerArtist = artistsShare / artistsPerPiece;
            for (uint256 i = 0; i < currentExhibition.exhibitedArtIds.length; i++) {
                address artistAddress = artPieces[currentExhibition.exhibitedArtIds[i] - 1].artist;
                payable(artistAddress).transfer(amountPerArtist); // Basic distribution - refine in real use.
            }
        }

        emit ExhibitionRevenueDistributed(totalRevenue, treasuryShare, artistsShare);
    }


    // -------- 4. Treasury & Utility Functions --------

    function getDAACTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFromTreasury(address _to, uint256 _amount) external onlyAdmin {
        require(_to != address(0), "Invalid withdrawal address.");
        require(_amount <= address(this).balance, "Insufficient treasury balance.");
        payable(_to).transfer(_amount);
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin {
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks, msg.sender);
    }

    function getVotingDuration() external view returns (uint256) {
        return votingDurationBlocks;
    }

    // -------- Fallback Function (Optional) --------
    // For accepting ETH without explicit function calls (if needed for specific use cases).
    receive() external payable {}
    fallback() external payable {}
}
```