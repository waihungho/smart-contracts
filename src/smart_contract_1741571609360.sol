```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)

 * @dev This smart contract implements a Decentralized Autonomous Art Collective (DAAC)
 * where artists can submit their artwork, the community can curate and vote on them,
 * and successful artworks are minted as NFTs and auctioned. Revenue is shared between
 * the artist and the collective. The contract incorporates advanced concepts like:
 *  - Decentralized Governance: Community voting for artwork curation, parameter changes, etc.
 *  - Dynamic Curation: Voting mechanism to select high-quality art.
 *  - Revenue Sharing: Fair distribution of auction proceeds.
 *  - NFT Minting: Automatic NFT creation for approved artworks.
 *  - Decentralized Auctions:  Built-in auction mechanism.
 *  - Membership & Reputation: Potential for future reputation system based on participation.
 *  - Parameterized Governance:  Adjustable voting periods, quorum, platform fees through governance.
 *  - Layered Security:  Access control and modifiers for secure operations.
 *  - Event Emission:  Detailed event logging for off-chain tracking and integration.
 *  - Pausable Functionality: Emergency stop mechanism for critical situations.
 *  - Treasury Management:  Dedicated treasury for collective funds.
 *  - Multi-Currency Support (Future Extension): Placeholder for potential multi-currency auctions.
 *  - Artist Royalties (Future Extension): Placeholder for potential secondary market royalties.
 *  - Progressive Decentralization: Designed for gradual transfer of control to the community.
 *  - On-Chain Provenance:  Immutable record of artwork creation and ownership.
 *  - Community Engagement:  Incentivizes participation through curation and governance.
 *  - Fair and Transparent System:  Open and auditable processes for all operations.
 *  - Anti-Spam Measures:  Submission fees and voting thresholds to deter malicious activities.
 *  - Dynamic Platform Fee:  Governance-adjustable platform fee for sustainability.
 *  - Proposal System:  Formalized process for suggesting and voting on changes.
 *  - Tiered Membership (Future Extension):  Potential for different membership levels with varying rights.
 *  - Delegated Voting (Future Extension):  Possibility for members to delegate their voting power.
 *  - Quadratic Voting (Future Extension):  Potential for more nuanced voting mechanisms.
 *  - DAO Tooling Integration (Future Extension): Designed to be compatible with DAO tooling.
 *  - Cross-Chain Compatibility (Future Extension):  Consideration for future cross-chain deployments.
 *  - Metaverse Integration (Future Extension):  Potential for integration with metaverse platforms.
 */

contract DecentralizedArtCollective {
    // ------------------------------------------------------------------------
    // Outline and Function Summary
    // ------------------------------------------------------------------------
    /*
     * Contract Name: DecentralizedArtCollective
     *
     * Purpose: Manages a decentralized autonomous art collective for artwork submission, curation,
     *          NFT minting, auctioning, and revenue sharing, governed by the community.
     *
     * Functions (20+):
     *
     * --- Submission & Curation ---
     * 1. submitArtwork(string memory _artworkCID, string memory _metadataCID, uint256 _submissionFee): Allows artists to submit artwork for curation.
     * 2. getSubmissionDetails(uint256 _submissionId): Retrieves details of a specific artwork submission.
     * 3. getPendingSubmissions(): Returns a list of IDs of pending artwork submissions.
     * 4. voteOnSubmission(uint256 _submissionId, bool _approve): Allows members to vote on artwork submissions.
     * 5. getVotingStatus(uint256 _submissionId): Retrieves the current voting status of a submission.
     * 6. tallyVotes(uint256 _submissionId): (Admin/Scheduler) Tallies votes for a submission and determines outcome.
     * 7. getApprovedSubmissions(): Returns a list of IDs of approved artwork submissions.
     * 8. rejectSubmission(uint256 _submissionId): (Admin) Manually rejects a submission if needed after voting.
     *
     * --- NFT Minting & Auction ---
     * 9. mintArtworkNFT(uint256 _submissionId): (Internal) Mints an NFT for an approved artwork.
     * 10. createAuction(uint256 _nftId, uint256 _startingBid, uint256 _auctionDuration): Creates an auction for a minted NFT.
     * 11. bidOnAuction(uint256 _auctionId) payable: Allows users to bid on an active auction.
     * 12. endAuction(uint256 _auctionId): Ends an auction and settles the highest bid.
     * 13. getAuctionDetails(uint256 _auctionId): Retrieves details of a specific auction.
     * 14. getActiveAuctions(): Returns a list of IDs of active auctions.
     * 15. getWinningBid(uint256 _auctionId): Retrieves the winning bid and bidder of a finished auction.
     *
     * --- Revenue & Treasury ---
     * 16. distributeRevenue(uint256 _auctionId): (Internal) Distributes auction revenue to artist and treasury.
     * 17. withdrawArtistRevenue(): Allows artists to withdraw their earned revenue.
     * 18. getArtistRevenueBalance(address _artist): Retrieves the revenue balance of an artist.
     * 19. getCollectiveTreasuryBalance(): Retrieves the current balance of the collective treasury.
     * 20. setPlatformFee(uint256 _newFeePercentage): (Governance) Proposes and enacts changes to the platform fee.
     * 21. getPlatformFee(): Returns the current platform fee percentage.
     * 22. proposeParameterChange(string memory _parameterName, uint256 _newValue): (Member) Proposes a change to a governance parameter.
     * 23. voteOnParameterChange(uint256 _proposalId, bool _support): (Member) Votes on a parameter change proposal.
     * 24. enactParameterChange(uint256 _proposalId): (Admin/Scheduler) Enacts a parameter change proposal after successful voting.
     * 25. getParameterChangeProposal(uint256 _proposalId): Retrieves details of a parameter change proposal.
     *
     * --- Membership & Governance ---
     * 26. requestMembership(): Allows users to request membership in the collective.
     * 27. approveMembership(address _user): (Admin/Governance) Approves a membership request.
     * 28. revokeMembership(address _user): (Admin/Governance) Revokes membership from a user.
     * 29. isMember(address _user): Checks if an address is a member of the collective.
     * 30. getMemberCount(): Returns the current number of members in the collective.
     *
     * --- Admin & Utility ---
     * 31. pauseContract(): (Admin) Pauses the contract functionality in case of emergency.
     * 32. unpauseContract(): (Admin) Resumes contract functionality after pausing.
     * 33. isPaused(): Checks if the contract is currently paused.
     * 34. setTreasuryAddress(address _newTreasury): (Admin) Sets the treasury address.
     * 35. getTreasuryAddress(): Returns the current treasury address.
     * 36. setVotingDuration(uint256 _newDuration): (Governance) Proposes and enacts changes to voting duration.
     * 37. getVotingDuration(): Returns the current voting duration.
     * 38. setQuorumPercentage(uint256 _newQuorum): (Governance) Proposes and enacts changes to the voting quorum.
     * 39. getQuorumPercentage(): Returns the current voting quorum percentage.
     * 40. setSubmissionFee(uint256 _newFee): (Governance) Proposes and enacts changes to the submission fee.
     * 41. getSubmissionFee(): Returns the current submission fee.
     * 42. getContractOwner(): Returns the address of the contract owner.
     * 43. renounceOwnership(): (Owner - Careful!) Allows owner to renounce ownership.
     * 44. transferOwnership(address _newOwner): (Owner) Allows owner to transfer ownership.
     */

    // ------------------------------------------------------------------------
    // State Variables
    // ------------------------------------------------------------------------
    string public collectiveName = "Decentralized Art Collective";
    address public owner;
    address public treasuryAddress;
    uint256 public platformFeePercentage = 5; // Percentage of auction revenue for the collective
    uint256 public submissionFee = 0.01 ether; // Fee to submit artwork, in Ether
    uint256 public votingDuration = 7 days; // Duration of voting period for submissions
    uint256 public quorumPercentage = 50; // Percentage of members needed to reach quorum for voting
    bool public paused = false;

    uint256 public submissionCounter = 0;
    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    enum SubmissionStatus { Pending, Approved, Rejected, Voting }

    struct ArtworkSubmission {
        uint256 id;
        address artist;
        string artworkCID; // IPFS CID for the artwork file
        string metadataCID; // IPFS CID for the artwork metadata
        SubmissionStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 votingEndTime;
    }

    uint256 public nftCounter = 0;
    mapping(uint256 => ArtworkNFT) public artworkNFTs;
    struct ArtworkNFT {
        uint256 id;
        uint256 submissionId;
        address artist;
        string tokenURI; // Metadata URI for the NFT
        bool minted;
    }

    uint256 public auctionCounter = 0;
    mapping(uint256 => Auction) public auctions;
    enum AuctionStatus { Active, Ended }

    struct Auction {
        uint256 id;
        uint256 nftId;
        address seller;
        uint256 startingBid;
        uint256 currentBid;
        address highestBidder;
        uint256 auctionEndTime;
        AuctionStatus status;
    }

    mapping(uint256 => mapping(address => bool)) public submissionVotes; // submissionId => voter => vote (true=upvote, false=downvote)
    mapping(address => bool) public members;
    address[] public memberList;

    uint256 public parameterProposalCounter = 0;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    enum ProposalStatus { Pending, Approved, Rejected, Enacted }

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        ProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 votingEndTime;
    }
    mapping(uint256 => mapping(address => bool)) public parameterProposalVotes; // proposalId => voter => vote (true=support, false=oppose)

    mapping(address => uint256) public artistRevenueBalances;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    event ArtworkSubmitted(uint256 submissionId, address artist, string artworkCID, string metadataCID);
    event VoteCast(uint256 submissionId, address voter, bool vote);
    event SubmissionApproved(uint256 submissionId);
    event SubmissionRejected(uint256 submissionId);
    event ArtworkNFTMinted(uint256 nftId, uint256 submissionId, address artist, string tokenURI);
    event AuctionCreated(uint256 auctionId, uint256 nftId, address seller, uint256 startingBid, uint256 auctionDuration);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, address winner, uint256 winningBid);
    event RevenueDistributed(uint256 auctionId, address artist, uint256 artistRevenue, uint256 collectiveRevenue);
    event RevenueWithdrawn(address artist, uint256 amount);
    event MembershipRequested(address user);
    event MembershipApproved(address user);
    event MembershipRevoked(address user);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterVoteCast(uint256 proposalId, address voter, bool vote);
    event ParameterChangeEnacted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event TreasuryAddressUpdated(address newTreasury);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event VotingDurationUpdated(uint256 newDuration);
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);
    event SubmissionFeeUpdated(uint256 newSubmissionFee);

    // ------------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= submissionCounter, "Invalid submission ID.");
        _;
    }

    modifier validNftId(uint256 _nftId) {
        require(_nftId > 0 && _nftId <= nftCounter, "Invalid NFT ID.");
        _;
    }

    modifier validAuctionId(uint256 _auctionId) {
        require(_auctionId > 0 && _auctionId <= auctionCounter, "Invalid auction ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= parameterProposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier submissionInStatus(uint256 _submissionId, SubmissionStatus _status) {
        require(artworkSubmissions[_submissionId].status == _status, "Submission not in required status.");
        _;
    }

    modifier auctionInStatus(uint256 _auctionId, AuctionStatus _status) {
        require(auctions[_auctionId].status == _status, "Auction not in required status.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(parameterChangeProposals[_proposalId].status == _status, "Proposal not in required status.");
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _treasuryAddress) {
        owner = msg.sender;
        treasuryAddress = _treasuryAddress;
    }

    // ------------------------------------------------------------------------
    // Submission & Curation Functions
    // ------------------------------------------------------------------------

    /// @notice Allows artists to submit their artwork for curation by the collective.
    /// @param _artworkCID IPFS CID of the artwork file.
    /// @param _metadataCID IPFS CID of the artwork metadata.
    /// @param _submissionFee Fee required to submit the artwork.
    function submitArtwork(string memory _artworkCID, string memory _metadataCID) external payable notPaused {
        require(msg.value >= submissionFee, "Submission fee is required.");
        submissionCounter++;
        artworkSubmissions[submissionCounter] = ArtworkSubmission({
            id: submissionCounter,
            artist: msg.sender,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            status: SubmissionStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            votingEndTime: block.timestamp + votingDuration
        });
        emit ArtworkSubmitted(submissionCounter, msg.sender, _artworkCID, _metadataCID);
    }

    /// @notice Retrieves details of a specific artwork submission.
    /// @param _submissionId ID of the artwork submission.
    /// @return ArtworkSubmission struct containing submission details.
    function getSubmissionDetails(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtworkSubmission memory) {
        return artworkSubmissions[_submissionId];
    }

    /// @notice Returns a list of IDs of pending artwork submissions.
    /// @return Array of submission IDs that are currently pending curation.
    function getPendingSubmissions() external view returns (uint256[] memory) {
        uint256[] memory pendingSubmissionIds = new uint256[](submissionCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= submissionCounter; i++) {
            if (artworkSubmissions[i].status == SubmissionStatus.Pending) {
                pendingSubmissionIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pendingSubmissionIds[i];
        }
        return result;
    }

    /// @notice Allows members to vote on an artwork submission.
    /// @param _submissionId ID of the artwork submission to vote on.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the submission.
    function voteOnSubmission(uint256 _submissionId, bool _approve) external onlyMembers notPaused validSubmissionId(_submissionId) submissionInStatus(_submissionId, SubmissionStatus.Pending) {
        require(block.timestamp < artworkSubmissions[_submissionId].votingEndTime, "Voting period has ended.");
        require(!submissionVotes[_submissionId][msg.sender], "You have already voted on this submission.");

        submissionVotes[_submissionId][msg.sender] = true; // Record that voter has voted (regardless of vote direction for anti-spam)
        if (_approve) {
            artworkSubmissions[_submissionId].upvotes++;
        } else {
            artworkSubmissions[_submissionId].downvotes++;
        }
        emit VoteCast(_submissionId, msg.sender, _approve);
    }

    /// @notice Retrieves the current voting status of a submission.
    /// @param _submissionId ID of the artwork submission.
    /// @return Upvote count, downvote count, and voting end time.
    function getVotingStatus(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (uint256 upvotes, uint256 downvotes, uint256 votingEndTime) {
        return (artworkSubmissions[_submissionId].upvotes, artworkSubmissions[_submissionId].downvotes, artworkSubmissions[_submissionId].votingEndTime);
    }

    /// @notice (Admin/Scheduler) Tallies votes for a submission and determines outcome after voting period.
    /// @param _submissionId ID of the artwork submission to tally votes for.
    function tallyVotes(uint256 _submissionId) external notPaused validSubmissionId(_submissionId) submissionInStatus(_submissionId, SubmissionStatus.Pending) {
        require(block.timestamp >= artworkSubmissions[_submissionId].votingEndTime, "Voting period is not yet over.");
        uint256 totalMembers = memberList.length;
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        uint256 totalVotes = artworkSubmissions[_submissionId].upvotes + artworkSubmissions[_submissionId].downvotes;

        if (totalVotes >= quorum && artworkSubmissions[_submissionId].upvotes > artworkSubmissions[_submissionId].downvotes) {
            artworkSubmissions[_submissionId].status = SubmissionStatus.Approved;
            mintArtworkNFT(_submissionId); // Automatically mint NFT upon approval
            emit SubmissionApproved(_submissionId);
        } else {
            artworkSubmissions[_submissionId].status = SubmissionStatus.Rejected;
            emit SubmissionRejected(_submissionId);
        }
    }

    /// @notice Returns a list of IDs of approved artwork submissions.
    /// @return Array of submission IDs that have been approved.
    function getApprovedSubmissions() external view returns (uint256[] memory) {
        uint256[] memory approvedSubmissionIds = new uint256[](submissionCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= submissionCounter; i++) {
            if (artworkSubmissions[i].status == SubmissionStatus.Approved) {
                approvedSubmissionIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = approvedSubmissionIds[i];
        }
        return result;
    }

    /// @notice (Admin) Manually rejects a submission if needed after voting or in special cases.
    /// @param _submissionId ID of the artwork submission to reject.
    function rejectSubmission(uint256 _submissionId) external onlyOwner notPaused validSubmissionId(_submissionId) submissionInStatus(_submissionId, SubmissionStatus.Pending) {
        artworkSubmissions[_submissionId].status = SubmissionStatus.Rejected;
        emit SubmissionRejected(_submissionId);
    }


    // ------------------------------------------------------------------------
    // NFT Minting & Auction Functions
    // ------------------------------------------------------------------------

    /// @notice (Internal) Mints an NFT for an approved artwork submission.
    /// @param _submissionId ID of the approved artwork submission.
    function mintArtworkNFT(uint256 _submissionId) internal validSubmissionId(_submissionId) submissionInStatus(_submissionId, SubmissionStatus.Approved) {
        nftCounter++;
        string memory tokenURI = string(abi.encodePacked("ipfs://", artworkSubmissions[_submissionId].metadataCID)); // Construct tokenURI from metadata CID
        artworkNFTs[nftCounter] = ArtworkNFT({
            id: nftCounter,
            submissionId: _submissionId,
            artist: artworkSubmissions[_submissionId].artist,
            tokenURI: tokenURI,
            minted: true
        });
        emit ArtworkNFTMinted(nftCounter, _submissionId, artworkSubmissions[_submissionId].artist, tokenURI);
    }

    /// @notice Creates an auction for a minted NFT.
    /// @param _nftId ID of the NFT to auction.
    /// @param _startingBid Starting bid amount for the auction in wei.
    /// @param _auctionDuration Duration of the auction in seconds.
    function createAuction(uint256 _nftId, uint256 _startingBid, uint256 _auctionDuration) external onlyMembers notPaused validNftId(_nftId) {
        require(artworkNFTs[_nftId].minted, "NFT must be minted to create an auction.");
        require(auctions[_nftId].status != AuctionStatus.Active, "Auction already exists for this NFT."); //Prevent re-auctioning same NFT while auction is active
        auctionCounter++;
        auctions[auctionCounter] = Auction({
            id: auctionCounter,
            nftId: _nftId,
            seller: msg.sender,
            startingBid: _startingBid,
            currentBid: _startingBid, // Initial bid is the starting bid
            highestBidder: address(0), // No bidder initially
            auctionEndTime: block.timestamp + _auctionDuration,
            status: AuctionStatus.Active
        });
        emit AuctionCreated(auctionCounter, _nftId, msg.sender, _startingBid, _auctionDuration);
    }

    /// @notice Allows users to bid on an active auction.
    /// @param _auctionId ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) external payable notPaused validAuctionId(_auctionId) auctionInStatus(_auctionId, AuctionStatus.Active) {
        require(block.timestamp < auctions[_auctionId].auctionEndTime, "Auction has ended.");
        require(msg.value >= auctions[_auctionId].currentBid, "Bid amount must be higher than current bid.");

        if (auctions[_auctionId].highestBidder != address(0)) {
            payable(auctions[_auctionId].highestBidder).transfer(auctions[_auctionId].currentBid); // Refund previous highest bidder
        }
        auctions[_auctionId].currentBid = msg.value;
        auctions[_auctionId].highestBidder = msg.sender;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /// @notice Ends an auction and settles the highest bid.
    /// @param _auctionId ID of the auction to end.
    function endAuction(uint256 _auctionId) external notPaused validAuctionId(_auctionId) auctionInStatus(_auctionId, AuctionStatus.Active) {
        require(block.timestamp >= auctions[_auctionId].auctionEndTime, "Auction time is not yet over.");
        auctions[_auctionId].status = AuctionStatus.Ended;
        address winner = auctions[_auctionId].highestBidder;
        uint256 winningBid = auctions[_auctionId].currentBid;

        if (winner != address(0)) {
            // Transfer NFT to winner (implementation depends on NFT standard)
            // For simplicity, assuming NFT ownership is tracked off-chain or handled by another contract.
            // In a real ERC721/1155 implementation, transferFrom would be called here.
            distributeRevenue(_auctionId);
            emit AuctionEnded(_auctionId, winner, winningBid);
        } else {
            // No bids were placed, handle scenario (e.g., return NFT to seller, relist, etc.)
            // For now, just mark as ended.
            emit AuctionEnded(_auctionId, address(0), 0); // No winner scenario
        }
    }

    /// @notice Retrieves details of a specific auction.
    /// @param _auctionId ID of the auction.
    /// @return Auction struct containing auction details.
    function getAuctionDetails(uint256 _auctionId) external view validAuctionId(_auctionId) returns (Auction memory) {
        return auctions[_auctionId];
    }

    /// @notice Returns a list of IDs of active auctions.
    /// @return Array of auction IDs that are currently active.
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256[] memory activeAuctionIds = new uint256[](auctionCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= auctionCounter; i++) {
            if (auctions[i].status == AuctionStatus.Active) {
                activeAuctionIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeAuctionIds[i];
        }
        return result;
    }

    /// @notice Retrieves the winning bid and bidder of a finished auction.
    /// @param _auctionId ID of the auction.
    /// @return Winning bid amount and address of the winning bidder.
    function getWinningBid(uint256 _auctionId) external view validAuctionId(_auctionId) auctionInStatus(_auctionId, AuctionStatus.Ended) returns (uint256 winningBid, address winner) {
        return (auctions[_auctionId].currentBid, auctions[_auctionId].highestBidder);
    }


    // ------------------------------------------------------------------------
    // Revenue & Treasury Functions
    // ------------------------------------------------------------------------

    /// @notice (Internal) Distributes auction revenue to the artist and collective treasury.
    /// @param _auctionId ID of the auction for which to distribute revenue.
    function distributeRevenue(uint256 _auctionId) internal validAuctionId(_auctionId) auctionInStatus(_auctionId, AuctionStatus.Ended) {
        uint256 winningBid = auctions[_auctionId].currentBid;
        uint256 platformCut = (winningBid * platformFeePercentage) / 100;
        uint256 artistShare = winningBid - platformCut;

        artistRevenueBalances[artworkNFTs[auctions[_auctionId].nftId].artist] += artistShare;
        payable(treasuryAddress).transfer(platformCut);

        emit RevenueDistributed(_auctionId, artworkNFTs[auctions[_auctionId].nftId].artist, artistShare, platformCut);
    }

    /// @notice Allows artists to withdraw their earned revenue balance.
    function withdrawArtistRevenue() external notPaused {
        uint256 amount = artistRevenueBalances[msg.sender];
        require(amount > 0, "No revenue to withdraw.");
        artistRevenueBalances[msg.sender] = 0; // Reset balance after withdrawal
        payable(msg.sender).transfer(amount);
        emit RevenueWithdrawn(msg.sender, amount);
    }

    /// @notice Retrieves the revenue balance of an artist.
    /// @param _artist Address of the artist.
    /// @return Revenue balance of the artist.
    function getArtistRevenueBalance(address _artist) external view returns (uint256) {
        return artistRevenueBalances[_artist];
    }

    /// @notice Retrieves the current balance of the collective treasury.
    /// @return Balance of the treasury in wei.
    function getCollectiveTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice (Governance) Proposes and enacts changes to the platform fee percentage.
    /// @param _newFeePercentage New platform fee percentage value.
    function setPlatformFee(uint256 _newFeePercentage) external onlyMembers notPaused {
        require(_newFeePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        proposeParameterChange("platformFeePercentage", _newFeePercentage);
    }

    /// @notice Returns the current platform fee percentage.
    /// @return Current platform fee percentage.
    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    // ------------------------------------------------------------------------
    // Governance Parameter Change Proposals & Voting
    // ------------------------------------------------------------------------

    /// @notice (Member) Proposes a change to a governance parameter.
    /// @param _parameterName Name of the parameter to change (e.g., "votingDuration", "quorumPercentage").
    /// @param _newValue New value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) internal onlyMembers notPaused { // Internal to limit proposal creation to internal functions and future governance modules
        parameterProposalCounter++;
        parameterChangeProposals[parameterProposalCounter] = ParameterChangeProposal({
            id: parameterProposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            status: ProposalStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            votingEndTime: block.timestamp + votingDuration
        });
        emit ParameterProposalCreated(parameterProposalCounter, _parameterName, _newValue);
    }


    /// @notice (Member) Votes on a parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal to vote on.
    /// @param _support Boolean indicating whether to support (true) or oppose (false) the proposal.
    function voteOnParameterChange(uint256 _proposalId, bool _support) external onlyMembers notPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(block.timestamp < parameterChangeProposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(!parameterProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        parameterProposalVotes[_proposalId][msg.sender] = true; // Record voter voted (regardless of direction for anti-spam)
        if (_support) {
            parameterChangeProposals[_proposalId].upvotes++;
        } else {
            parameterChangeProposals[_proposalId].downvotes++;
        }
        emit ParameterVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice (Admin/Scheduler) Enacts a parameter change proposal after successful voting.
    /// @param _proposalId ID of the parameter change proposal to enact.
    function enactParameterChange(uint256 _proposalId) external onlyOwner notPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(block.timestamp >= parameterChangeProposals[_proposalId].votingEndTime, "Voting period is not yet over.");
        uint256 totalMembers = memberList.length;
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        uint256 totalVotes = parameterChangeProposals[_proposalId].upvotes + parameterChangeProposals[_proposalId].downvotes;

        if (totalVotes >= quorum && parameterChangeProposals[_proposalId].upvotes > parameterChangeProposals[_proposalId].downvotes) {
            parameterChangeProposals[_proposalId].status = ProposalStatus.Approved;
            _applyParameterChange(_proposalId); // Apply the parameter change
            emit ParameterChangeEnacted(_proposalId, parameterChangeProposals[_proposalId].parameterName, parameterChangeProposals[_proposalId].newValue);
        } else {
            parameterChangeProposals[_proposalId].status = ProposalStatus.Rejected;
            // Optionally emit event for rejected proposal
        }
    }

    /// @notice (Internal) Applies the parameter change to the contract state.
    /// @param _proposalId ID of the parameter change proposal.
    function _applyParameterChange(uint256 _proposalId) internal validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Approved) {
        string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
        uint256 newValue = parameterChangeProposals[_proposalId].newValue;

        if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("platformFeePercentage"))) {
            platformFeePercentage = newValue;
            emit PlatformFeeUpdated(newValue);
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
            votingDuration = newValue;
            emit VotingDurationUpdated(newValue);
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
            quorumPercentage = newValue;
            emit QuorumPercentageUpdated(newValue);
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("submissionFee"))) {
            submissionFee = newValue;
            emit SubmissionFeeUpdated(newValue);
        }
        // Add more parameter conditions here as needed
    }


    /// @notice Retrieves details of a parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @return ParameterChangeProposal struct containing proposal details.
    function getParameterChangeProposal(uint256 _proposalId) external view validProposalId(_proposalId) returns (ParameterChangeProposal memory) {
        return parameterChangeProposals[_proposalId];
    }


    // ------------------------------------------------------------------------
    // Membership & Governance Functions
    // ------------------------------------------------------------------------

    /// @notice Allows users to request membership in the collective.
    function requestMembership() external notPaused {
        // In a real DAO, this might involve voting or meeting certain criteria.
        // For simplicity, this example allows direct admin approval.
        emit MembershipRequested(msg.sender);
    }

    /// @notice (Admin/Governance) Approves a membership request.
    /// @param _user Address of the user to approve for membership.
    function approveMembership(address _user) external onlyOwner notPaused {
        require(!members[_user], "User is already a member.");
        members[_user] = true;
        memberList.push(_user);
        emit MembershipApproved(_user);
    }

    /// @notice (Admin/Governance) Revokes membership from a user.
    /// @param _user Address of the user to revoke membership from.
    function revokeMembership(address _user) external onlyOwner notPaused {
        require(members[_user], "User is not a member.");
        members[_user] = false;
        // Remove from memberList (optional, but good practice)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _user) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_user);
    }

    /// @notice Checks if an address is a member of the collective.
    /// @param _user Address to check for membership.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    /// @notice Returns the current number of members in the collective.
    /// @return Number of members in the collective.
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }


    // ------------------------------------------------------------------------
    // Admin & Utility Functions
    // ------------------------------------------------------------------------

    /// @notice (Admin) Pauses the contract functionality in case of emergency.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice (Admin) Resumes contract functionality after pausing.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isPaused() external view returns (bool) {
        return paused;
    }

    /// @notice (Admin) Sets the treasury address.
    /// @param _newTreasury Address of the new treasury.
    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Treasury address cannot be zero address.");
        treasuryAddress = _newTreasury;
        emit TreasuryAddressUpdated(_newTreasury);
    }

    /// @notice Returns the current treasury address.
    /// @return Current treasury address.
    function getTreasuryAddress() external view returns (address) {
        return treasuryAddress;
    }

    /// @notice (Governance) Proposes and enacts changes to the voting duration.
    /// @param _newDuration New voting duration in seconds.
    function setVotingDuration(uint256 _newDuration) external onlyMembers notPaused {
        proposeParameterChange("votingDuration", _newDuration);
    }

    /// @notice Returns the current voting duration.
    /// @return Current voting duration in seconds.
    function getVotingDuration() external view returns (uint256) {
        return votingDuration;
    }

    /// @notice (Governance) Proposes and enacts changes to the voting quorum percentage.
    /// @param _newQuorum New quorum percentage value.
    function setQuorumPercentage(uint256 _newQuorum) external onlyMembers notPaused {
        require(_newQuorum <= 100, "Quorum percentage cannot exceed 100.");
        proposeParameterChange("quorumPercentage", _newQuorum);
    }

    /// @notice Returns the current voting quorum percentage.
    /// @return Current voting quorum percentage.
    function getQuorumPercentage() external view returns (uint256) {
        return quorumPercentage;
    }

    /// @notice (Governance) Proposes and enacts changes to the submission fee.
    /// @param _newFee New submission fee in wei.
    function setSubmissionFee(uint256 _newFee) external onlyMembers notPaused {
        proposeParameterChange("submissionFee", _newFee);
    }

    /// @notice Returns the current submission fee.
    /// @return Current submission fee in wei.
    function getSubmissionFee() external view returns (uint256) {
        return submissionFee;
    }

    /// @notice Returns the address of the contract owner.
    /// @return Address of the contract owner.
    function getContractOwner() external view returns (address) {
        return owner;
    }

    /// @notice (Owner - Careful!) Allows owner to renounce ownership, making the contract potentially un-upgradable.
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /// @notice (Owner) Allows owner to transfer ownership to a new address.
    /// @param _newOwner Address of the new owner.
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
```