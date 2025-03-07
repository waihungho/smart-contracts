```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Gemini AI
 * @dev This contract implements a decentralized autonomous art gallery with advanced features.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `submitArt(string memory _title, string memory _description, string memory _ipfsHash, uint256 _initialPrice)`: Allows artists to submit their artwork for gallery consideration.
 * 2. `voteOnArtSubmission(uint256 _submissionId, bool _vote)`: Gallery members can vote on submitted artwork for acceptance.
 * 3. `acceptArt(uint256 _submissionId)`: Admin/Curators can accept artwork that passes voting threshold into the gallery.
 * 4. `rejectArt(uint256 _submissionId)`: Admin/Curators can reject artwork submissions.
 * 5. `listArtForSale(uint256 _artId, uint256 _price)`: Artists can list their accepted artwork for sale in the gallery.
 * 6. `buyArt(uint256 _artId)`: Users can purchase artwork listed in the gallery.
 * 7. `removeArtFromSale(uint256 _artId)`: Artists can remove their artwork from sale.
 * 8. `transferArt(uint256 _artId, address _to)`: Art owners can transfer their artwork to another address.
 * 9. `burnArt(uint256 _artId)`: Allows the current owner to burn (destroy) their artwork.
 * 10. `viewArtDetails(uint256 _artId)`: Allows anyone to view detailed information about a specific artwork.
 * 11. `getGalleryCommissionRate()`: Returns the current gallery commission rate.
 * 12. `setGalleryCommissionRate(uint256 _newRate)`: Admin function to change the gallery commission rate.
 *
 * **Artist and User Management:**
 * 13. `registerArtist(string memory _artistName, string memory _artistBio)`: Allows users to register as artists with a profile.
 * 14. `updateArtistProfile(string memory _newBio)`: Artists can update their profile bio.
 * 15. `getUserProfile(address _user)`: Allows viewing of user profiles (artists or members).
 *
 * **Governance and Community Features:**
 * 16. `proposeParameterChange(string memory _description, string memory _parameterName, uint256 _newValue)`:  Allows members to propose changes to gallery parameters (e.g., commission rate, voting threshold).
 * 17. `voteOnParameterChange(uint256 _proposalId, bool _vote)`: Members can vote on parameter change proposals.
 * 18. `executeParameterChange(uint256 _proposalId)`: Admin/Curators can execute approved parameter change proposals.
 * 19. `delegateVotingPower(address _delegatee)`: Members can delegate their voting power to another address.
 * 20. `stakeTokensForVotingPower(uint256 _amount)`: Members can stake tokens to increase their voting power.
 * 21. `withdrawStakedTokens(uint256 _amount)`: Members can withdraw staked tokens.
 * 22. `getVotingPower(address _voter)`: Returns the voting power of a given address (including staked power).
 *
 * **Advanced & Creative Features:**
 * 23. `createArtCollaboration(uint256 _artId, address[] memory _collaborators, uint256[] memory _shares)`: Allows the original artist to create a collaboration for an existing artwork, splitting future sales.
 * 24. `splitRoyaltiesOnSecondarySale(uint256 _artId)`: Automatically splits royalties on secondary sales to collaborators (if applicable).
 * 25. `auctionArt(uint256 _artId, uint256 _startingBid, uint256 _auctionDuration)`: Allows artists to auction their artwork.
 * 26. `bidOnAuction(uint256 _auctionId)`: Users can bid on active auctions.
 * 27. `finalizeAuction(uint256 _auctionId)`: Finalizes an auction after the duration, transferring art and funds.
 * 28. `reportArt(uint256 _artId, string memory _reason)`: Members can report potentially inappropriate or infringing artwork for review.
 * 29. `censorArt(uint256 _artId)`: Admin/Curators can censor reported artwork (making it unavailable in the gallery).
 * 30. `mintCollectibleBadge(address _recipient, string memory _badgeName, string memory _badgeDescription, string memory _badgeIPFSHash)`: Admin/Curators can mint collectible badges for active members/contributors.
 */

contract DecentralizedAutonomousArtGallery {

    // Enums
    enum ArtStatus { SUBMITTED, ACCEPTED, REJECTED, LISTED_FOR_SALE, SOLD, CENSORED }
    enum ProposalStatus { PENDING, APPROVED, REJECTED, EXECUTED }

    // Structs
    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        ArtStatus status;
        uint256 price; // Sale price
        address owner;
        uint256 submissionTimestamp;
        uint256 acceptedTimestamp;
        address[] collaborators; // Addresses of collaborators
        uint256[] collaborationShares; // Shares of collaborators in percentages (sum to 100)
    }

    struct ArtistProfile {
        address artistAddress;
        string artistName;
        string artistBio;
        uint256 registrationTimestamp;
    }

    struct UserProfile {
        address userAddress;
        uint256 registrationTimestamp;
    }

    struct ArtSubmission {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 initialPrice;
        uint256 submissionTimestamp;
        uint256 upVotes;
        uint256 downVotes;
        bool finalized; // To prevent double processing after voting
    }

    struct ParameterChangeProposal {
        uint256 id;
        string description;
        string parameterName;
        uint256 newValue;
        uint256 proposalTimestamp;
        uint256 upVotes;
        uint256 downVotes;
        ProposalStatus status;
    }

    struct Auction {
        uint256 id;
        uint256 artId;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool finalized;
    }

    struct CollectibleBadge {
        uint256 id;
        string badgeName;
        string badgeDescription;
        string badgeIPFSHash;
        uint256 mintTimestamp;
    }

    // State Variables
    address public admin;
    uint256 public artCounter;
    uint256 public submissionCounter;
    uint256 public proposalCounter;
    uint256 public auctionCounter;
    uint256 public badgeCounter;
    uint256 public galleryCommissionRate = 5; // Percentage, e.g., 5 for 5%
    uint256 public votingThreshold = 50; // Percentage for passing votes (e.g., 50 for 50%)
    uint256 public votingDuration = 7 days; // Default voting duration for submissions and proposals
    uint256 public auctionDurationDefault = 3 days; // Default auction duration

    mapping(uint256 => ArtPiece) public artPieces;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => CollectibleBadge) public collectibleBadges;
    mapping(uint256 => mapping(address => bool)) public artSubmissionVotes; // submissionId => voter => voted (true=upvote, false=downvote)
    mapping(uint256 => mapping(address => bool)) public parameterProposalVotes; // proposalId => voter => voted (true=upvote, false=downvote)
    mapping(address => address) public votingDelegations; // Delegator => Delegatee
    mapping(address => uint256) public stakedTokens; // User => Staked Amount (Placeholder - for advanced token staking integration)

    // Events
    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtAccepted(uint256 artId, address artist, string title);
    event ArtRejected(uint256 artId, address artist, string title);
    event ArtListedForSale(uint256 artId, uint256 price);
    event ArtSold(uint256 artId, address buyer, uint256 price);
    event ArtTransferred(uint256 artId, address from, address to);
    event ArtBurned(uint256 artId, address owner);
    event ArtistRegistered(address artist, string artistName);
    event ArtistProfileUpdated(address artist);
    event ParameterChangeProposed(uint256 proposalId, string description, string parameterName, uint256 newValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event VotingPowerDelegated(address delegator, address delegatee);
    event TokensStaked(address staker, uint256 amount);
    event TokensWithdrawn(address withdrawer, uint256 amount);
    event ArtAuctionCreated(uint256 auctionId, uint256 artId, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 finalPrice);
    event ArtReported(uint256 artId, address reporter, string reason);
    event ArtCensored(uint256 artId);
    event CollectibleBadgeMinted(uint256 badgeId, address recipient, string badgeName);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyArtist(uint256 _artId) {
        require(artPieces[_artId].artist == msg.sender, "Only the artist of this artwork can perform this action.");
        _;
    }

    modifier onlyArtOwner(uint256 _artId) {
        require(artPieces[_artId].owner == msg.sender, "Only the owner of this artwork can perform this action.");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(_artId > 0 && _artId <= artCounter && artPieces[_artId].id == _artId, "Invalid Art ID.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= submissionCounter && artSubmissions[_submissionId].id == _submissionId && !artSubmissions[_submissionId].finalized, "Invalid or finalized Submission ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && parameterChangeProposals[_proposalId].id == _proposalId && parameterChangeProposals[_proposalId].status == ProposalStatus.PENDING, "Invalid or finalized Proposal ID.");
        _;
    }

    modifier validAuctionId(uint256 _auctionId) {
        require(_auctionId > 0 && _auctionId <= auctionCounter && auctions[_auctionId].id == _auctionId && !auctions[_auctionId].finalized, "Invalid or finalized Auction ID.");
        _;
    }

    // Constructor
    constructor() {
        admin = msg.sender;
        artCounter = 0;
        submissionCounter = 0;
        proposalCounter = 0;
        auctionCounter = 0;
        badgeCounter = 0;
    }

    // 1. Submit Art
    function submitArt(string memory _title, string memory _description, string memory _ipfsHash, uint256 _initialPrice) public {
        submissionCounter++;
        artSubmissions[submissionCounter] = ArtSubmission({
            id: submissionCounter,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            initialPrice: _initialPrice,
            submissionTimestamp: block.timestamp,
            upVotes: 0,
            downVotes: 0,
            finalized: false
        });
        emit ArtSubmitted(submissionCounter, msg.sender, _title);
    }

    // 2. Vote on Art Submission
    function voteOnArtSubmission(uint256 _submissionId, bool _vote) public validSubmissionId(_submissionId) {
        require(!artSubmissionVotes[_submissionId][msg.sender], "You have already voted on this submission.");
        artSubmissionVotes[_submissionId][msg.sender] = true; // Record vote
        if (_vote) {
            artSubmissions[_submissionId].upVotes++;
        } else {
            artSubmissions[_submissionId].downVotes++;
        }

        // Check if voting period is over or threshold is reached (simplified auto-acceptance for demonstration)
        if (block.timestamp >= artSubmissions[_submissionId].submissionTimestamp + votingDuration) {
            finalizeArtSubmission(_submissionId);
        } else {
            uint256 totalVotes = artSubmissions[_submissionId].upVotes + artSubmissions[_submissionId].downVotes;
            if (totalVotes > 0) {
                uint256 approvalPercentage = (artSubmissions[_submissionId].upVotes * 100) / totalVotes;
                if (approvalPercentage >= votingThreshold) {
                    finalizeArtSubmission(_submissionId); // Auto-accept if threshold reached early
                }
            }
        }
    }

    // Internal function to finalize art submission based on voting
    function finalizeArtSubmission(uint256 _submissionId) internal validSubmissionId(_submissionId) {
        artSubmissions[_submissionId].finalized = true; // Prevent further actions
        uint256 totalVotes = artSubmissions[_submissionId].upVotes + artSubmissions[_submissionId].downVotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (artSubmissions[_submissionId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= votingThreshold) {
                acceptArt(_submissionId); // Auto-accept based on voting
            } else {
                rejectArt(_submissionId); // Auto-reject based on voting
            }
        } else {
            rejectArt(_submissionId); // Reject if no votes after duration (default reject)
        }
    }


    // 3. Accept Art
    function acceptArt(uint256 _submissionId) public onlyAdmin validSubmissionId(_submissionId) {
        artSubmissions[_submissionId].finalized = true;
        artCounter++;
        artPieces[artCounter] = ArtPiece({
            id: artCounter,
            title: artSubmissions[_submissionId].title,
            description: artSubmissions[_submissionId].description,
            ipfsHash: artSubmissions[_submissionId].ipfsHash,
            artist: artSubmissions[_submissionId].artist,
            status: ArtStatus.ACCEPTED,
            price: artSubmissions[_submissionId].initialPrice,
            owner: artSubmissions[_submissionId].artist, // Initial owner is the artist
            submissionTimestamp: artSubmissions[_submissionId].submissionTimestamp,
            acceptedTimestamp: block.timestamp,
            collaborators: new address[](0), // Initialize empty collaborators array
            collaborationShares: new uint256[](0) // Initialize empty shares array
        });
        emit ArtAccepted(artCounter, artSubmissions[_submissionId].artist, artSubmissions[_submissionId].title);
    }

    // 4. Reject Art
    function rejectArt(uint256 _submissionId) public onlyAdmin validSubmissionId(_submissionId) {
        artSubmissions[_submissionId].finalized = true;
        emit ArtRejected(_submissionId, artSubmissions[_submissionId].artist, artSubmissions[_submissionId].title);
    }

    // 5. List Art For Sale
    function listArtForSale(uint256 _artId, uint256 _price) public onlyArtist(_artId) validArtId(_artId) {
        require(artPieces[_artId].status == ArtStatus.ACCEPTED || artPieces[_artId].status == ArtStatus.LISTED_FOR_SALE, "Artwork must be accepted to be listed for sale.");
        artPieces[_artId].status = ArtStatus.LISTED_FOR_SALE;
        artPieces[_artId].price = _price;
        emit ArtListedForSale(_artId, _price);
    }

    // 6. Buy Art
    function buyArt(uint256 _artId) public payable validArtId(_artId) {
        require(artPieces[_artId].status == ArtStatus.LISTED_FOR_SALE, "Artwork is not listed for sale.");
        require(msg.value >= artPieces[_artId].price, "Insufficient funds sent.");

        uint256 commissionAmount = (artPieces[_artId].price * galleryCommissionRate) / 100;
        uint256 artistPayout = artPieces[_artId].price - commissionAmount;

        // Pay artist and commission
        payable(artPieces[_artId].artist).transfer(artistPayout);
        payable(admin).transfer(commissionAmount); // Gallery commission goes to admin (can be DAO treasury in real case)

        // Update art ownership and status
        artPieces[_artId].owner = msg.sender;
        artPieces[_artId].status = ArtStatus.SOLD;
        artPieces[_artId].price = 0; // Reset price after sale

        // Handle Royalty Split for Collaborations on Secondary Sale
        splitRoyaltiesOnSecondarySale(_artId);

        emit ArtSold(_artId, msg.sender, artPieces[_artId].price);

        // Return change if any
        if (msg.value > artPieces[_artId].price) {
            payable(msg.sender).transfer(msg.value - artPieces[_artId].price);
        }
    }

    // 24. Split Royalties on Secondary Sale (Internal function called in buyArt)
    function splitRoyaltiesOnSecondarySale(uint256 _artId) internal validArtId(_artId) {
        if (artPieces[_artId].collaborators.length > 0) {
            for (uint256 i = 0; i < artPieces[_artId].collaborators.length; i++) {
                uint256 royaltyAmount = (artPieces[_artId].price * artPieces[_artId].collaborationShares[i]) / 100;
                payable(artPieces[_artId].collaborators[i]).transfer(royaltyAmount);
                // Reduce artist payout by royalty amount (already handled in buyArt calculation conceptually, but good to note)
            }
        }
    }


    // 7. Remove Art From Sale
    function removeArtFromSale(uint256 _artId) public onlyArtist(_artId) validArtId(_artId) {
        require(artPieces[_artId].status == ArtStatus.LISTED_FOR_SALE, "Artwork is not listed for sale.");
        artPieces[_artId].status = ArtStatus.ACCEPTED; // Back to accepted status
        artPieces[_artId].price = 0; // Reset price
        emit ArtListedForSale(_artId, 0); // Emit event with price 0 to indicate removal
    }

    // 8. Transfer Art
    function transferArt(uint256 _artId, address _to) public onlyArtOwner(_artId) validArtId(_artId) {
        require(_to != address(0) && _to != address(this), "Invalid recipient address.");
        artPieces[_artId].owner = _to;
        emit ArtTransferred(_artId, msg.sender, _to);
    }

    // 9. Burn Art
    function burnArt(uint256 _artId) public onlyArtOwner(_artId) validArtId(_artId) {
        emit ArtBurned(_artId, msg.sender);
        delete artPieces[_artId]; // Remove from storage. Warning: irreversible.
    }

    // 10. View Art Details
    function viewArtDetails(uint256 _artId) public view validArtId(_artId) returns (ArtPiece memory) {
        return artPieces[_artId];
    }

    // 11. Get Gallery Commission Rate
    function getGalleryCommissionRate() public view returns (uint256) {
        return galleryCommissionRate;
    }

    // 12. Set Gallery Commission Rate
    function setGalleryCommissionRate(uint256 _newRate) public onlyAdmin {
        require(_newRate <= 100, "Commission rate cannot exceed 100%.");
        galleryCommissionRate = _newRate;
    }

    // 13. Register Artist
    function registerArtist(string memory _artistName, string memory _artistBio) public {
        require(artistProfiles[msg.sender].artistAddress == address(0), "Artist profile already exists.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistAddress: msg.sender,
            artistName: _artistName,
            artistBio: _artistBio,
            registrationTimestamp: block.timestamp
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    // 14. Update Artist Profile
    function updateArtistProfile(string memory _newBio) public {
        require(artistProfiles[msg.sender].artistAddress != address(0), "Artist profile does not exist. Register first.");
        artistProfiles[msg.sender].artistBio = _newBio;
        emit ArtistProfileUpdated(msg.sender);
    }

    // 15. Get User Profile (Generic User Profile - can be extended)
    function getUserProfile(address _user) public view returns (UserProfile memory) {
        if (userProfiles[_user].userAddress == address(0)) {
            // Create a default user profile on-the-fly if it doesn't exist
            return UserProfile({
                userAddress: _user,
                registrationTimestamp: 0 // Indicate not registered
            });
        }
        return userProfiles[_user];
    }

    // 23. Create Art Collaboration
    function createArtCollaboration(uint256 _artId, address[] memory _collaborators, uint256[] memory _shares) public onlyArtist(_artId) validArtId(_artId) {
        require(_collaborators.length == _shares.length, "Number of collaborators and shares must be the same.");
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        require(totalShares == 100, "Total collaboration shares must equal 100%.");

        artPieces[_artId].collaborators = _collaborators;
        artPieces[_artId].collaborationShares = _shares;
    }

    // 16. Propose Parameter Change
    function proposeParameterChange(string memory _description, string memory _parameterName, uint256 _newValue) public {
        proposalCounter++;
        parameterChangeProposals[proposalCounter] = ParameterChangeProposal({
            id: proposalCounter,
            description: _description,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            upVotes: 0,
            downVotes: 0,
            status: ProposalStatus.PENDING
        });
        emit ParameterChangeProposed(proposalCounter, _description, _parameterName, _newValue);
    }

    // 17. Vote on Parameter Change
    function voteOnParameterChange(uint256 _proposalId, bool _vote) public validProposalId(_proposalId) {
        require(!parameterProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        parameterProposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            parameterChangeProposals[_proposalId].upVotes++;
        } else {
            parameterChangeProposals[_proposalId].downVotes++;
        }

        // Check if voting period is over or threshold is reached (simplified auto-execution for demonstration)
        if (block.timestamp >= parameterChangeProposals[_proposalId].proposalTimestamp + votingDuration) {
            finalizeParameterProposal(_proposalId);
        } else {
            uint256 totalVotes = parameterChangeProposals[_proposalId].upVotes + parameterChangeProposals[_proposalId].downVotes;
            if (totalVotes > 0) {
                uint256 approvalPercentage = (parameterChangeProposals[_proposalId].upVotes * 100) / totalVotes;
                if (approvalPercentage >= votingThreshold) {
                    finalizeParameterProposal(_proposalId); // Auto-execute if threshold reached early
                }
            }
        }
    }

    // Internal function to finalize parameter proposal
    function finalizeParameterProposal(uint256 _proposalId) internal validProposalId(_proposalId) {
        uint256 totalVotes = parameterChangeProposals[_proposalId].upVotes + parameterChangeProposals[_proposalId].downVotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (parameterChangeProposals[_proposalId].upVotes * 100) / totalVotes;
            if (approvalPercentage >= votingThreshold) {
                executeParameterChange(_proposalId); // Auto-execute if approved
            } else {
                parameterChangeProposals[_proposalId].status = ProposalStatus.REJECTED; // Reject if not approved
            }
        } else {
            parameterChangeProposals[_proposalId].status = ProposalStatus.REJECTED; // Reject if no votes after duration
        }
    }

    // 18. Execute Parameter Change
    function executeParameterChange(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.status = ProposalStatus.EXECUTED;
        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("galleryCommissionRate"))) {
            setGalleryCommissionRate(proposal.newValue);
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("votingThreshold"))) {
            votingThreshold = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
            votingDuration = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("auctionDurationDefault"))) {
            auctionDurationDefault = proposal.newValue;
        } else {
            revert("Unknown parameter name to change.");
        }
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue);
    }

    // 19. Delegate Voting Power
    function delegateVotingPower(address _delegatee) public {
        require(_delegatee != address(0) && _delegatee != msg.sender, "Invalid delegatee address.");
        votingDelegations[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    // 20. Stake Tokens For Voting Power (Placeholder - needs token integration)
    function stakeTokensForVotingPower(uint256 _amount) public {
        // In a real scenario, you would integrate with an ERC20 token and transfer tokens to this contract.
        // For this example, we just simulate staking by tracking the amount.
        stakedTokens[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    // 21. Withdraw Staked Tokens (Placeholder - needs token integration)
    function withdrawStakedTokens(uint256 _amount) public {
        require(stakedTokens[msg.sender] >= _amount, "Insufficient staked tokens.");
        stakedTokens[msg.sender] -= _amount;
        // In a real scenario, you would transfer ERC20 tokens back to the user.
        emit TokensWithdrawn(msg.sender, _amount);
    }

    // 22. Get Voting Power
    function getVotingPower(address _voter) public view returns (uint256) {
        // Base voting power (e.g., 1, can be based on token holdings in a real scenario)
        uint256 basePower = 1;
        // Add staked tokens to voting power (placeholder logic)
        uint256 stakedPower = stakedTokens[_voter] / 1000; // Example: 1 token = 0.001 voting power
        return basePower + stakedPower;
    }

    // 25. Auction Art
    function auctionArt(uint256 _artId, uint256 _startingBid, uint256 _auctionDuration) public onlyArtist(_artId) validArtId(_artId) {
        require(artPieces[_artId].status == ArtStatus.ACCEPTED || artPieces[_artId].status == ArtStatus.LISTED_FOR_SALE, "Artwork must be accepted to be auctioned.");
        require(_startingBid > 0, "Starting bid must be greater than zero.");
        require(_auctionDuration > 0, "Auction duration must be greater than zero.");

        auctionCounter++;
        auctions[auctionCounter] = Auction({
            id: auctionCounter,
            artId: _artId,
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            finalized: false
        });
        artPieces[_artId].status = ArtStatus.LISTED_FOR_SALE; // Change status to listed for sale during auction
        emit ArtAuctionCreated(auctionCounter, _artId, _startingBid, auctions[auctionCounter].endTime);
    }

    // 26. Bid On Auction
    function bidOnAuction(uint256 _auctionId) public payable validAuctionId(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value >= auction.startingBid, "Bid must be at least the starting bid.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous highest bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    // 27. Finalize Auction
    function finalizeAuction(uint256 _auctionId) public validAuctionId(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");
        require(!auction.finalized, "Auction already finalized.");
        auction.finalized = true;

        if (auction.highestBidder != address(0)) {
            // Pay artist and commission (similar to buyArt)
            uint256 commissionAmount = (auction.highestBid * galleryCommissionRate) / 100;
            uint256 artistPayout = auction.highestBid - commissionAmount;

            payable(artPieces[auction.artId].artist).transfer(artistPayout);
            payable(admin).transfer(commissionAmount);

            // Update art ownership
            artPieces[auction.artId].owner = auction.highestBidder;
            artPieces[auction.artId].status = ArtStatus.SOLD;
            artPieces[auction.artId].price = 0; // Reset price

            // Handle Royalty Split on Secondary Sale after Auction End
            splitRoyaltiesOnSecondarySale(auction.artId);

            emit AuctionFinalized(_auctionId, auction.highestBidder, auction.highestBid);
            emit ArtSold(auction.artId, auction.highestBidder, auction.highestBid);
            emit ArtTransferred(auction.artId, artPieces[auction.artId].artist, auction.highestBidder); // Explicit transfer event for auction winner
        } else {
            // No bids, revert art status back to accepted (or artist decides what to do)
            artPieces[auction.artId].status = ArtStatus.ACCEPTED;
            emit AuctionFinalized(_auctionId, address(0), 0); // Indicate no winner
        }
    }

    // 28. Report Art
    function reportArt(uint256 _artId, string memory _reason) public validArtId(_artId) {
        emit ArtReported(_artId, msg.sender, _reason);
        // In a real application, you would have admin review process triggered by this event.
    }

    // 29. Censor Art
    function censorArt(uint256 _artId) public onlyAdmin validArtId(_artId) {
        artPieces[_artId].status = ArtStatus.CENSORED;
        emit ArtCensored(_artId);
    }

    // 30. Mint Collectible Badge
    function mintCollectibleBadge(address _recipient, string memory _badgeName, string memory _badgeDescription, string memory _badgeIPFSHash) public onlyAdmin {
        badgeCounter++;
        collectibleBadges[badgeCounter] = CollectibleBadge({
            id: badgeCounter,
            badgeName: _badgeName,
            badgeDescription: _badgeDescription,
            badgeIPFSHash: _badgeIPFSHash,
            mintTimestamp: block.timestamp
        });
        emit CollectibleBadgeMinted(badgeCounter, _recipient, _badgeName);
        // In a real application, you might want to associate these badges with user profiles or use an NFT standard for badges.
    }

    // Fallback function to receive Ether (for gallery commission and art purchases)
    receive() external payable {}
    fallback() external payable {}
}
```