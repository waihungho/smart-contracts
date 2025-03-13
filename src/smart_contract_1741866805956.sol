```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAArtGallery)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized autonomous art gallery with advanced features.
 *
 * Outline & Function Summary:
 *
 * 1.  **Gallery Management:**
 *     - `createGallery(string _galleryName, string _galleryDescription, address _curationCommittee)`: Allows platform admin to create a new art gallery.
 *     - `setGalleryParameters(uint256 _galleryId, uint256 _commissionRate, uint256 _votingDuration)`: Allows gallery owner (curation committee) to set gallery parameters.
 *     - `pauseGallery(uint256 _galleryId)`: Pauses all interactions within a specific gallery (admin only).
 *     - `unpauseGallery(uint256 _galleryId)`: Resumes interactions within a paused gallery (admin only).
 *     - `withdrawGalleryFunds(uint256 _galleryId)`: Allows gallery owner (curation committee) to withdraw accumulated gallery funds.
 *     - `setPlatformFee(uint256 _newFee)`:  Allows platform admin to set the platform-wide fee percentage.
 *
 * 2.  **Art Piece Management:**
 *     - `submitArtPiece(uint256 _galleryId, string _artMetadataURI, uint256 _initialPrice)`: Allows artists to submit art pieces to a gallery for review.
 *     - `approveArtPiece(uint256 _galleryId, uint256 _artPieceId)`: Allows curation committee to approve a submitted art piece (voting based).
 *     - `rejectArtPiece(uint256 _galleryId, uint256 _artPieceId)`: Allows curation committee to reject a submitted art piece (voting based).
 *     - `purchaseArtPiece(uint256 _galleryId, uint256 _artPieceId)`: Allows users to purchase an approved art piece.
 *     - `setArtPiecePrice(uint256 _galleryId, uint256 _artPieceId, uint256 _newPrice)`: Allows the artist to change the price of their art piece (subject to gallery rules).
 *     - `removeArtPiece(uint256 _galleryId, uint256 _artPieceId)`: Allows the artist to remove their art piece from the gallery (subject to gallery rules).
 *     - `reportArtPiece(uint256 _galleryId, uint256 _artPieceId, string _reportReason)`: Allows users to report an art piece for policy violations.
 *
 * 3.  **Artist & User Features:**
 *     - `registerArtist(string _artistName, string _artistBio)`: Allows users to register as artists on the platform.
 *     - `updateArtistProfile(string _newBio)`: Allows artists to update their profile information.
 *     - `followArtist(address _artistAddress)`: Allows users to follow artists for updates.
 *     - `likeArtPiece(uint256 _galleryId, uint256 _artPieceId)`: Allows users to "like" art pieces (simple engagement metric).
 *     - `commentOnArtPiece(uint256 _galleryId, uint256 _artPieceId, string _commentText)`: Allows users to comment on art pieces.
 *     - `viewGalleryDetails(uint256 _galleryId)`: Allows users to view details of a specific gallery.
 *     - `viewArtPieceDetails(uint256 _galleryId, uint256 _artPieceId)`: Allows users to view details of a specific art piece.
 *     - `listGalleryArtPieces(uint256 _galleryId)`: Allows users to list all art pieces within a gallery.
 *     - `listArtistArtPieces(address _artistAddress)`: Allows users to list all art pieces by a specific artist across galleries.
 *
 * 4.  **Curation & Governance (Decentralized aspects):**
 *     - `proposeCurator(uint256 _galleryId, address _newCurator)`: Allows current curators to propose a new curator for the gallery (voting needed).
 *     - `voteForCuratorProposal(uint256 _galleryId, address _proposedCurator, bool _support)`: Allows current curators to vote on a curator proposal.
 *     - `resolveCuratorProposal(uint256 _galleryId)`: Resolves a curator proposal after the voting period.
 *     - `startArtPieceApprovalVote(uint256 _galleryId, uint256 _artPieceId)`: Starts a vote for approving an art piece (internal use, triggered by `submitArtPiece`).
 *     - `voteOnArtPieceApproval(uint256 _galleryId, uint256 _artPieceId, bool _approve)`: Allows curators to vote on art piece approvals.
 *     - `resolveArtPieceApprovalVote(uint256 _galleryId, uint256 _artPieceId)`: Resolves an art piece approval vote after the voting period.
 *     - `startArtPieceRejectionVote(uint256 _galleryId, uint256 _artPieceId)`: Starts a vote for rejecting an art piece (internal use, triggered by `reportArtPiece` and curator review).
 *     - `voteOnArtPieceRejection(uint256 _galleryId, uint256 _artPieceId, bool _reject)`: Allows curators to vote on art piece rejections.
 *     - `resolveArtPieceRejectionVote(uint256 _galleryId, uint256 _artPieceId)`: Resolves an art piece rejection vote after the voting period.
 *
 * 5.  **Advanced & Trendy Concepts:**
 *     - **Decentralized Curation & Governance:** Implements voting mechanisms for art piece approvals/rejections and curator selection, making the gallery autonomous.
 *     - **On-chain Comments & Likes:**  Brings social interaction directly onto the blockchain.
 *     - **Dynamic Commission Rates:** Galleries can set their own commission rates, creating a marketplace of galleries.
 *     - **Artist Profiles & Following:**  Basic social networking features for artists and users.
 *     - **Report System:**  Community moderation and content control within the decentralized environment.
 *     - **Gallery Pausing:**  Emergency mechanism for platform admins to handle issues or disputes.
 */

contract DAArtGallery {

    // Platform Admin address - deployer of the contract.
    address public platformAdmin;
    uint256 public platformFeePercentage = 5; // Default platform fee percentage (5%).

    // Structs
    struct Gallery {
        string name;
        string description;
        address curationCommittee; // Address of the curation committee (DAO/Multi-sig)
        uint256 commissionRate;    // Percentage commission for the gallery
        uint256 votingDuration;    // Duration of voting periods in blocks
        bool paused;
        uint256 balance;         // Gallery's accumulated funds
    }

    struct ArtPiece {
        uint256 galleryId;
        address artist;
        string metadataURI;
        uint256 price;
        bool approved;
        bool rejected;
        uint256 likes;
        uint256 submissionTimestamp;
    }

    struct ArtistProfile {
        string name;
        string bio;
        bool registered;
    }

    struct CuratorProposal {
        uint256 galleryId;
        address proposedCurator;
        mapping(address => bool) votes; // Curator address => vote (true for support, false for reject)
        uint256 voteCount;
        uint256 endTime;
        bool resolved;
        bool approved;
    }

    struct ArtPieceApprovalVote {
        uint256 galleryId;
        uint256 artPieceId;
        mapping(address => bool) votes; // Curator address => vote (true for approve, false for reject)
        uint256 voteCount;
        uint256 endTime;
        bool resolved;
        bool approved;
    }

    struct ArtPieceRejectionVote {
        uint256 galleryId;
        uint256 artPieceId;
        mapping(address => bool) votes; // Curator address => vote (true for reject, false for abstain/no vote)
        uint256 voteCount;
        uint256 endTime;
        bool resolved;
        bool rejected;
    }

    struct Comment {
        address commenter;
        string text;
        uint256 timestamp;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
        bool resolved; // Indicate if the report has been reviewed
    }


    // Mappings
    mapping(uint256 => Gallery) public galleries;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => CuratorProposal) public curatorProposals;
    mapping(uint256 => ArtPieceApprovalVote) public artPieceApprovalVotes;
    mapping(uint256 => ArtPieceRejectionVote) public artPieceRejectionVotes;
    mapping(uint256 => mapping(uint256 => Comment[])) public artPieceComments; // galleryId => artPieceId => Comment array
    mapping(uint256 => mapping(uint256 => Report[])) public artPieceReports;   // galleryId => artPieceId => Report array
    mapping(address => address[]) public artistFollowers; // Artist address => array of follower addresses
    mapping(uint256 => uint256[]) public galleryArtPieces; // galleryId => array of artPieceIds

    // Counters
    uint256 public galleryCount;
    uint256 public artPieceCount;
    uint256 public curatorProposalCount;
    uint256 public artPieceApprovalVoteCount;
    uint256 public artPieceRejectionVoteCount;


    // Events
    event GalleryCreated(uint256 galleryId, string galleryName, address curationCommittee);
    event GalleryParametersSet(uint256 galleryId, uint256 commissionRate, uint256 votingDuration);
    event GalleryPaused(uint256 galleryId);
    event GalleryUnpaused(uint256 galleryId);
    event FundsWithdrawn(uint256 galleryId, address withdrawnBy, uint256 amount);
    event PlatformFeeSet(uint256 newFee);

    event ArtPieceSubmitted(uint256 galleryId, uint256 artPieceId, address artist, string metadataURI);
    event ArtPieceApproved(uint256 galleryId, uint256 artPieceId);
    event ArtPieceRejected(uint256 galleryId, uint256 artPieceId);
    event ArtPiecePurchased(uint256 galleryId, uint256 artPieceId, address buyer, uint256 price);
    event ArtPiecePriceSet(uint256 galleryId, uint256 artPieceId, uint256 newPrice);
    event ArtPieceRemoved(uint256 galleryId, uint256 artPieceId);
    event ArtPieceReported(uint256 galleryId, uint256 artPieceId, address reporter, string reason);
    event ArtPieceLiked(uint256 galleryId, uint256 artPieceId, address liker);
    event CommentAdded(uint256 galleryId, uint256 artPieceId, address commenter, string text);

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress);
    event ArtistFollowed(address follower, address artist);

    event CuratorProposed(uint256 proposalId, uint256 galleryId, address proposedCurator);
    event CuratorVoteCast(uint256 proposalId, address voter, bool support);
    event CuratorProposalResolved(uint256 proposalId, bool approved, address newCurator);

    event ArtPieceApprovalVoteStarted(uint256 voteId, uint256 galleryId, uint256 artPieceId);
    event ArtPieceApprovalVoteCast(uint256 voteId, address voter, bool approve);
    event ArtPieceApprovalVoteResolved(uint256 voteId, uint256 artPieceId, bool approved);

    event ArtPieceRejectionVoteStarted(uint256 voteId, uint256 galleryId, uint256 artPieceId);
    event ArtPieceRejectionVoteCast(uint256 voteId, address voter, bool reject);
    event ArtPieceRejectionVoteResolved(uint256 voteId, uint256 artPieceId, uint256 artPieceIdRejected, bool rejected);


    // Modifiers
    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can perform this action.");
        _;
    }

    modifier onlyGalleryOwner(uint256 _galleryId) {
        require(galleries[_galleryId].curationCommittee == msg.sender, "Only gallery owner (curation committee) can perform this action.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].registered, "Only registered artists can perform this action.");
        _;
    }

    modifier validGallery(uint256 _galleryId) {
        require(_galleryId > 0 && _galleryId <= galleryCount, "Invalid gallery ID.");
        _;
    }

    modifier validArtPiece(uint256 _galleryId, uint256 _artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount && artPieces[_artPieceId].galleryId == _galleryId, "Invalid art piece ID or not in this gallery.");
        _;
    }

    modifier galleryNotPaused(uint256 _galleryId) {
        require(!galleries[_galleryId].paused, "Gallery is currently paused.");
        _;
    }

    modifier artPieceNotApproved(uint256 _galleryId, uint256 _artPieceId) {
        require(!artPieces[_artPieceId].approved, "Art piece is already approved.");
        _;
    }

    modifier artPieceNotRejected(uint256 _galleryId, uint256 _artPieceId) {
        require(!artPieces[_artPieceId].rejected, "Art piece is already rejected.");
        _;
    }

    modifier onlyCurator(uint256 _galleryId) {
        require(isCurator(_galleryId, msg.sender), "Only curators of this gallery can perform this action.");
        _;
    }

    // Constructor
    constructor() {
        platformAdmin = msg.sender;
    }


    // ------------------------ Gallery Management Functions ------------------------

    function createGallery(string memory _galleryName, string memory _galleryDescription, address _curationCommittee) external onlyPlatformAdmin {
        galleryCount++;
        galleries[galleryCount] = Gallery({
            name: _galleryName,
            description: _galleryDescription,
            curationCommittee: _curationCommittee,
            commissionRate: 10, // Default commission rate 10%
            votingDuration: 7 days / 12 seconds, // Default voting duration 7 days (in blocks assuming 12s block time)
            paused: false,
            balance: 0
        });
        emit GalleryCreated(galleryCount, _galleryName, _curationCommittee);
    }

    function setGalleryParameters(uint256 _galleryId, uint256 _commissionRate, uint256 _votingDuration) external validGallery(_galleryId) onlyGalleryOwner(_galleryId) {
        galleries[_galleryId].commissionRate = _commissionRate;
        galleries[_galleryId].votingDuration = _votingDuration;
        emit GalleryParametersSet(_galleryId, _commissionRate, _votingDuration);
    }

    function pauseGallery(uint256 _galleryId) external validGallery(_galleryId) onlyPlatformAdmin {
        galleries[_galleryId].paused = true;
        emit GalleryPaused(_galleryId);
    }

    function unpauseGallery(uint256 _galleryId) external validGallery(_galleryId) onlyPlatformAdmin {
        galleries[_galleryId].paused = false;
        emit GalleryUnpaused(_galleryId);
    }

    function withdrawGalleryFunds(uint256 _galleryId) external validGallery(_galleryId) onlyGalleryOwner(_galleryId) {
        uint256 amount = galleries[_galleryId].balance;
        galleries[_galleryId].balance = 0;
        payable(galleries[_galleryId].curationCommittee).transfer(amount);
        emit FundsWithdrawn(_galleryId, galleries[_galleryId].curationCommittee, amount);
    }

    function setPlatformFee(uint256 _newFee) external onlyPlatformAdmin {
        platformFeePercentage = _newFee;
        emit PlatformFeeSet(_newFee);
    }

    // ------------------------ Art Piece Management Functions ------------------------

    function submitArtPiece(uint256 _galleryId, string memory _artMetadataURI, uint256 _initialPrice) external validGallery(_galleryId) galleryNotPaused(_galleryId) onlyRegisteredArtist {
        artPieceCount++;
        artPieces[artPieceCount] = ArtPiece({
            galleryId: _galleryId,
            artist: msg.sender,
            metadataURI: _artMetadataURI,
            price: _initialPrice,
            approved: false,
            rejected: false,
            likes: 0,
            submissionTimestamp: block.timestamp
        });
        galleryArtPieces[_galleryId].push(artPieceCount);
        emit ArtPieceSubmitted(_galleryId, artPieceCount, msg.sender, _artMetadataURI);
        startArtPieceApprovalVote(_galleryId, artPieceCount); // Start approval voting automatically upon submission
    }

    function approveArtPiece(uint256 _galleryId, uint256 _artPieceId) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) onlyCurator(_galleryId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        voteOnArtPieceApproval(_galleryId, _artPieceId, true);
    }

    function rejectArtPiece(uint256 _galleryId, uint256 _artPieceId) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) onlyCurator(_galleryId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        voteOnArtPieceApproval(_galleryId, _artPieceId, false); // Vote against approval effectively rejects
    }

    function purchaseArtPiece(uint256 _galleryId, uint256 _artPieceId) external payable validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) artPieceNotRejected(_galleryId, _artPieceId) {
        require(artPieces[_artPieceId].approved, "Art piece is not yet approved for sale.");
        require(msg.value >= artPieces[_artPieceId].price, "Insufficient funds sent.");

        uint256 platformFee = (artPieces[_artPieceId].price * platformFeePercentage) / 100;
        uint256 galleryCommission = (artPieces[_artPieceId].price * galleries[_galleryId].commissionRate) / 100;
        uint256 artistPayment = artPieces[_artPieceId].price - platformFee - galleryCommission;

        // Transfer funds
        payable(platformAdmin).transfer(platformFee);
        galleries[_galleryId].balance += galleryCommission;
        payable(artPieces[_artPieceId].artist).transfer(artistPayment);

        emit ArtPiecePurchased(_galleryId, _artPieceId, msg.sender, artPieces[_artPieceId].price);
    }

    function setArtPiecePrice(uint256 _galleryId, uint256 _artPieceId, uint256 _newPrice) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) onlyRegisteredArtist {
        require(artPieces[_artPieceId].artist == msg.sender, "Only the artist can set the price.");
        artPieces[_artPieceId].price = _newPrice;
        emit ArtPiecePriceSet(_galleryId, _artPieceId, _newPrice);
    }

    function removeArtPiece(uint256 _galleryId, uint256 _artPieceId) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) onlyRegisteredArtist {
        require(artPieces[_artPieceId].artist == msg.sender, "Only the artist can remove their art piece.");
        // In a real scenario, consider handling ownership transfer if NFT based.
        artPieces[_artPieceId].rejected = true; // Mark as rejected to prevent further interaction
        emit ArtPieceRemoved(_galleryId, _artPieceId);
    }

    function reportArtPiece(uint256 _galleryId, uint256 _artPieceId, string memory _reportReason) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) {
        artPieceReports[_galleryId][_artPieceId].push(Report({
            reporter: msg.sender,
            reason: _reportReason,
            timestamp: block.timestamp,
            resolved: false
        }));
        emit ArtPieceReported(_galleryId, _artPieceId, msg.sender, _reportReason);
        startArtPieceRejectionVote(_galleryId, _artPieceId); // Start rejection vote upon report (can be refined)
    }


    // ------------------------ Artist & User Features ------------------------

    function registerArtist(string memory _artistName, string memory _artistBio) external {
        require(!artistProfiles[msg.sender].registered, "Artist already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            name: _artistName,
            bio: _artistBio,
            registered: true
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _newBio) external onlyRegisteredArtist {
        artistProfiles[msg.sender].bio = _newBio;
        emit ArtistProfileUpdated(msg.sender);
    }

    function followArtist(address _artistAddress) external {
        require(artistProfiles[_artistAddress].registered, "Cannot follow unregistered artist.");
        bool alreadyFollowing = false;
        for (uint256 i = 0; i < artistFollowers[_artistAddress].length; i++) {
            if (artistFollowers[_artistAddress][i] == msg.sender) {
                alreadyFollowing = true;
                break;
            }
        }
        if (!alreadyFollowing) {
            artistFollowers[_artistAddress].push(msg.sender);
            emit ArtistFollowed(msg.sender, _artistAddress);
        }
    }

    function likeArtPiece(uint256 _galleryId, uint256 _artPieceId) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) {
        artPieces[_artPieceId].likes++;
        emit ArtPieceLiked(_galleryId, _artPieceId, msg.sender);
    }

    function commentOnArtPiece(uint256 _galleryId, uint256 _artPieceId, string memory _commentText) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) galleryNotPaused(_galleryId) {
        artPieceComments[_galleryId][_artPieceId].push(Comment({
            commenter: msg.sender,
            text: _commentText,
            timestamp: block.timestamp
        }));
        emit CommentAdded(_galleryId, _artPieceId, msg.sender, _commentText);
    }

    function viewGalleryDetails(uint256 _galleryId) external view validGallery(_galleryId) returns (Gallery memory) {
        return galleries[_galleryId];
    }

    function viewArtPieceDetails(uint256 _galleryId, uint256 _artPieceId) external view validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    function listGalleryArtPieces(uint256 _galleryId) external view validGallery(_galleryId) returns (uint256[] memory) {
        return galleryArtPieces[_galleryId];
    }

    function listArtistArtPieces(address _artistAddress) external view returns (uint256[] memory) {
        uint256[] memory artistArtPieceIds = new uint256[](artPieceCount); // Max possible size, will trim later
        uint256 count = 0;
        for (uint256 i = 1; i <= artPieceCount; i++) {
            if (artPieces[i].artist == _artistAddress) {
                artistArtPieceIds[count] = i;
                count++;
            }
        }
        // Trim the array to the actual number of art pieces
        uint256[] memory trimmedArtistArtPieceIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedArtistArtPieceIds[i] = artistArtPieceIds[i];
        }
        return trimmedArtistArtPieceIds;
    }


    // ------------------------ Curation & Governance Functions ------------------------

    function proposeCurator(uint256 _galleryId, address _newCurator) external validGallery(_galleryId) onlyCurator(_galleryId) galleryNotPaused(_galleryId) {
        curatorProposalCount++;
        curatorProposals[curatorProposalCount] = CuratorProposal({
            galleryId: _galleryId,
            proposedCurator: _newCurator,
            voteCount: 0,
            endTime: block.number + galleries[_galleryId].votingDuration,
            resolved: false,
            approved: false
        });
        emit CuratorProposed(curatorProposalCount, _galleryId, _newCurator);
    }

    function voteForCuratorProposal(uint256 _galleryId, address _proposedCurator, bool _support) external validGallery(_galleryId) onlyCurator(_galleryId) galleryNotPaused(_galleryId) {
        uint256 proposalId = findLatestCuratorProposalId(_galleryId, _proposedCurator);
        require(proposalId > 0, "No active curator proposal found for this gallery and curator.");
        require(!curatorProposals[proposalId].resolved, "Curator proposal already resolved.");
        require(curatorProposals[proposalId].endTime > block.number, "Voting period ended.");
        require(!curatorProposals[proposalId].votes[msg.sender], "Curator already voted.");

        curatorProposals[proposalId].votes[msg.sender] = _support;
        curatorProposals[proposalId].voteCount++;
        emit CuratorVoteCast(proposalId, msg.sender, _support);

        if (curatorProposals[proposalId].voteCount >= getCuratorThreshold(_galleryId)) { // Simple majority for now, can be more complex
            resolveCuratorProposal(_galleryId);
        }
    }

    function resolveCuratorProposal(uint256 _galleryId) external validGallery(_galleryId) galleryNotPaused(_galleryId) {
        uint256 proposalId = findLatestUnresolvedCuratorProposalId(_galleryId);
        require(proposalId > 0, "No unresolved curator proposal found for this gallery.");
        require(!curatorProposals[proposalId].resolved, "Curator proposal already resolved.");
        require(curatorProposals[proposalId].endTime <= block.number, "Voting period not yet ended.");

        uint256 supportVotes = 0;
        uint256 rejectVotes = 0;
        address[] memory curators = getGalleryCurators(_galleryId); // Assuming curators are members of curationCommittee multi-sig/DAO
        for (uint256 i = 0; i < curators.length; i++) {
            if (curatorProposals[proposalId].votes[curators[i]]) {
                supportVotes++;
            } else {
                rejectVotes++;
            }
        }

        if (supportVotes > rejectVotes) { // Simple majority wins
            galleries[_galleryId].curationCommittee = curatorProposals[proposalId].proposedCurator;
            curatorProposals[proposalId].approved = true;
            emit CuratorProposalResolved(proposalId, true, curatorProposals[proposalId].proposedCurator);
        } else {
            curatorProposals[proposalId].approved = false;
            emit CuratorProposalResolved(proposalId, false, address(0)); // No new curator if proposal fails
        }
        curatorProposals[proposalId].resolved = true;
    }


    function startArtPieceApprovalVote(uint256 _galleryId, uint256 _artPieceId) internal validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        artPieceApprovalVoteCount++;
        artPieceApprovalVotes[artPieceApprovalVoteCount] = ArtPieceApprovalVote({
            galleryId: _galleryId,
            artPieceId: _artPieceId,
            voteCount: 0,
            endTime: block.number + galleries[_galleryId].votingDuration,
            resolved: false,
            approved: false
        });
        emit ArtPieceApprovalVoteStarted(artPieceApprovalVoteCount, _galleryId, _artPieceId);
    }


    function voteOnArtPieceApproval(uint256 _galleryId, uint256 _artPieceId, bool _approve) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) onlyCurator(_galleryId) galleryNotPaused(_galleryId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        uint256 voteId = findLatestArtPieceApprovalVoteId(_galleryId, _artPieceId);
        require(voteId > 0, "No active approval vote found for this art piece.");
        require(!artPieceApprovalVotes[voteId].resolved, "Art piece approval vote already resolved.");
        require(artPieceApprovalVotes[voteId].endTime > block.number, "Voting period ended.");
        require(!artPieceApprovalVotes[voteId].votes[msg.sender], "Curator already voted.");

        artPieceApprovalVotes[voteId].votes[msg.sender] = _approve;
        artPieceApprovalVotes[voteId].voteCount++;
        emit ArtPieceApprovalVoteCast(voteId, msg.sender, _approve);

        if (artPieceApprovalVotes[voteId].voteCount >= getCuratorThreshold(_galleryId)) { // Simple majority for now
            resolveArtPieceApprovalVote(_galleryId, _artPieceId);
        }
    }

    function resolveArtPieceApprovalVote(uint256 _galleryId, uint256 _artPieceId) internal validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        uint256 voteId = findLatestArtPieceApprovalVoteId(_galleryId, _artPieceId);
        require(voteId > 0, "No active approval vote found for this art piece.");
        require(!artPieceApprovalVotes[voteId].resolved, "Art piece approval vote already resolved.");
        require(artPieceApprovalVotes[voteId].endTime <= block.number, "Voting period not yet ended.");

        uint256 approveVotes = 0;
        uint256 rejectVotes = 0;
        address[] memory curators = getGalleryCurators(_galleryId); // Assuming curators are members of curationCommittee multi-sig/DAO
        for (uint256 i = 0; i < curators.length; i++) {
            if (artPieceApprovalVotes[voteId].votes[curators[i]]) {
                approveVotes++;
            } else {
                rejectVotes++;
            }
        }

        if (approveVotes > rejectVotes) { // Simple majority wins
            artPieces[_artPieceId].approved = true;
            emit ArtPieceApproved(_galleryId, _artPieceId);
            emit ArtPieceApprovalVoteResolved(voteId, _artPieceId, true);
        } else {
            artPieces[_artPieceId].rejected = true; // Consider marking as rejected if approval fails significantly
            emit ArtPieceRejected(_galleryId, _artPieceId);
            emit ArtPieceApprovalVoteResolved(voteId, _artPieceId, false);
        }
        artPieceApprovalVotes[voteId].resolved = true;
    }


    function startArtPieceRejectionVote(uint256 _galleryId, uint256 _artPieceId) internal validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) artPieceNotApproved(_galleryId, _artPieceId) {
        artPieceRejectionVoteCount++;
        artPieceRejectionVotes[artPieceRejectionVoteCount] = ArtPieceRejectionVote({
            galleryId: _galleryId,
            artPieceId: _artPieceId,
            voteCount: 0,
            endTime: block.number + galleries[_galleryId].votingDuration,
            resolved: false,
            rejected: false
        });
        emit ArtPieceRejectionVoteStarted(artPieceRejectionVoteCount, _galleryId, _artPieceId);
    }


    function voteOnArtPieceRejection(uint256 _galleryId, uint256 _artPieceId, bool _reject) external validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) onlyCurator(_galleryId) galleryNotPaused(_galleryId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        uint256 voteId = findLatestArtPieceRejectionVoteId(_galleryId, _artPieceId);
        require(voteId > 0, "No active rejection vote found for this art piece.");
        require(!artPieceRejectionVotes[voteId].resolved, "Art piece rejection vote already resolved.");
        require(artPieceRejectionVotes[voteId].endTime > block.number, "Voting period ended.");
        require(!artPieceRejectionVotes[voteId].votes[msg.sender], "Curator already voted.");

        artPieceRejectionVotes[voteId].votes[msg.sender] = _reject;
        artPieceRejectionVotes[voteId].voteCount++;
        emit ArtPieceRejectionVoteCast(voteId, msg.sender, _reject);

        if (artPieceRejectionVotes[voteId].voteCount >= getCuratorThreshold(_galleryId)) { // Simple majority for now
            resolveArtPieceRejectionVote(_galleryId, _artPieceId);
        }
    }

    function resolveArtPieceRejectionVote(uint256 _galleryId, uint256 _artPieceId) internal validGallery(_galleryId) validArtPiece(_galleryId, _artPieceId) artPieceNotApproved(_galleryId, _artPieceId) artPieceNotRejected(_galleryId, _artPieceId) {
        uint256 voteId = findLatestArtPieceRejectionVoteId(_galleryId, _artPieceId);
        require(voteId > 0, "No active rejection vote found for this art piece.");
        require(!artPieceRejectionVotes[voteId].resolved, "Art piece rejection vote already resolved.");
        require(artPieceRejectionVotes[voteId].endTime <= block.number, "Voting period not yet ended.");

        uint256 rejectVotes = 0;
        uint256 abstainVotes = 0; // Consider abstain/no vote as not rejecting
        address[] memory curators = getGalleryCurators(_galleryId); // Assuming curators are members of curationCommittee multi-sig/DAO
        for (uint256 i = 0; i < curators.length; i++) {
            if (artPieceRejectionVotes[voteId].votes[curators[i]]) {
                rejectVotes++;
            } else {
                abstainVotes++; // If curator didn't vote 'reject', count as abstain
            }
        }

        if (rejectVotes > abstainVotes) { // Simple majority to reject
            artPieces[_artPieceId].rejected = true;
            emit ArtPieceRejected(_galleryId, _artPieceId);
            emit ArtPieceRejectionVoteResolved(voteId, _artPieceId, _artPieceId, true);
        } else {
            emit ArtPieceRejectionVoteResolved(voteId, _artPieceId, _artPieceId, false); // Rejection vote failed
        }
        artPieceRejectionVotes[voteId].resolved = true;
    }


    // ------------------------ Helper Functions ------------------------

    function isCurator(uint256 _galleryId, address _curator) internal view returns (bool) {
        // In a real-world DAO scenario, this would involve checking membership in the curationCommittee contract (e.g., multi-sig or DAO contract).
        // For simplicity here, we assume the curationCommittee address is a multi-sig/DAO contract itself.
        // A more robust implementation would require interacting with an external contract interface.
        return galleries[_galleryId].curationCommittee == _curator; // Simple address comparison for this example.
    }

    function getGalleryCurators(uint256 _galleryId) internal view returns (address[] memory) {
        // In a real DAO scenario, you'd fetch curator addresses from the curationCommittee contract.
        // Here, we assume the curationCommittee address represents a single curator (or multi-sig address).
        // For simplicity, we return an array containing just the curationCommittee address.
        address[] memory curators = new address[](1);
        curators[0] = galleries[_galleryId].curationCommittee;
        return curators;
    }

    function getCuratorThreshold(uint256 _galleryId) internal view returns (uint256) {
        // In a real DAO, the threshold might be dynamically determined by DAO parameters.
        // For simplicity, we use a simple majority (more than half) of curators as the threshold.
        address[] memory curators = getGalleryCurators(_galleryId);
        return (curators.length / 2) + 1; // Simple majority
    }

    function findLatestCuratorProposalId(uint256 _galleryId, address _proposedCurator) internal view returns (uint256) {
        for (uint256 i = curatorProposalCount; i >= 1; i--) {
            if (curatorProposals[i].galleryId == _galleryId && curatorProposals[i].proposedCurator == _proposedCurator && !curatorProposals[i].resolved) {
                return i;
            }
        }
        return 0; // Not found
    }

    function findLatestUnresolvedCuratorProposalId(uint256 _galleryId) internal view returns (uint256) {
        for (uint256 i = curatorProposalCount; i >= 1; i--) {
            if (curatorProposals[i].galleryId == _galleryId && !curatorProposals[i].resolved) {
                return i;
            }
        }
        return 0; // Not found
    }

    function findLatestArtPieceApprovalVoteId(uint256 _galleryId, uint256 _artPieceId) internal view returns (uint256) {
        for (uint256 i = artPieceApprovalVoteCount; i >= 1; i--) {
            if (artPieceApprovalVotes[i].galleryId == _galleryId && artPieceApprovalVotes[i].artPieceId == _artPieceId && !artPieceApprovalVotes[i].resolved) {
                return i;
            }
        }
        return 0; // Not found
    }

    function findLatestArtPieceRejectionVoteId(uint256 _galleryId, uint256 _artPieceId) internal view returns (uint256) {
        for (uint256 i = artPieceRejectionVoteCount; i >= 1; i--) {
            if (artPieceRejectionVotes[i].galleryId == _galleryId && artPieceRejectionVotes[i].artPieceId == _artPieceId && !artPieceRejectionVotes[i].resolved) {
                return i;
            }
        }
        return 0; // Not found
    }
}
```