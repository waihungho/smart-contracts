```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI (Example - please review and adapt for production)
 * @dev A smart contract for a decentralized autonomous art collective,
 * allowing artists to submit art proposals, community voting on art,
 * minting accepted art as NFTs, managing a collective treasury, and
 * enabling decentralized governance of the art collective.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 * 1. `applyForArtistMembership()`: Allows users to apply to become an artist member of the collective.
 * 2. `approveArtistApplication(address _applicant)`: Admin function to approve pending artist applications.
 * 3. `revokeArtistMembership(address _artist)`: Admin function to revoke an artist's membership.
 * 4. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Artists submit art proposals with title, description, and IPFS hash of the artwork.
 * 5. `startArtProposalVoting(uint256 _proposalId)`: Admin function to initiate voting for a specific art proposal.
 * 6. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members (artists and potentially others) can vote on art proposals.
 * 7. `tallyArtProposalVotes(uint256 _proposalId)`: Admin function to close voting and tally the results for an art proposal.
 * 8. `acceptArtProposal(uint256 _proposalId)`: Admin function to accept an art proposal if it passes the vote.
 * 9. `rejectArtProposal(uint256 _proposalId)`: Admin function to reject an art proposal if it fails the vote.
 * 10. `mintArtNFT(uint256 _proposalId)`: Mints an NFT representing the accepted artwork, transferring it to the artist.
 * 11. `setNFTPrice(uint256 _tokenId, uint256 _price)`: Artists can set the price for their minted NFTs.
 * 12. `buyArtNFT(uint256 _tokenId)`: Allows users to purchase NFTs from the collective.
 * 13. `withdrawArtistEarnings(uint256 _tokenId)`: Artists can withdraw earnings from the sale of their NFTs.

 * **Governance and Treasury:**
 * 14. `depositToTreasury()`: Allows anyone to deposit ETH into the collective treasury.
 * 15. `proposeTreasurySpending(string memory _description, address _recipient, uint256 _amount)`: Members can propose spending from the treasury.
 * 16. `startTreasurySpendingVote(uint256 _spendingProposalId)`: Admin function to start voting on a treasury spending proposal.
 * 17. `voteOnTreasurySpending(uint256 _spendingProposalId, bool _vote)`: Members vote on treasury spending proposals.
 * 18. `tallyTreasurySpendingVotes(uint256 _spendingProposalId)`: Admin function to tally votes for treasury spending proposals.
 * 19. `executeTreasurySpending(uint256 _spendingProposalId)`: Admin function to execute approved treasury spending proposals.

 * **Utility and Configuration:**
 * 20. `setVotingDuration(uint256 _durationInSeconds)`: Admin function to set the default voting duration.
 * 21. `setQuorumPercentage(uint8 _percentage)`: Admin function to set the quorum percentage for voting.
 * 22. `setPlatformFeePercentage(uint8 _percentage)`: Admin function to set the platform fee percentage on NFT sales.
 * 23. `getArtistList()`: Returns a list of artist addresses in the collective.
 * 24. `getArtProposalDetails(uint256 _proposalId)`: Returns details of a specific art proposal.
 * 25. `getNFTDetails(uint256 _tokenId)`: Returns details of a specific NFT minted by the collective.
 * 26. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 */
contract DecentralizedAutonomousArtCollective {
    // Admin address - can be a multi-sig wallet for enhanced security
    address public admin;

    // Artist membership management
    mapping(address => bool) public isArtist;
    address[] public artistList;
    mapping(address => bool) public pendingArtistApplications;

    // Art proposals
    uint256 public proposalCounter;
    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool votingActive;
        bool proposalAccepted;
        bool proposalRejected;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => votedYes

    // NFT Minting and Sales
    uint256 public nftCounter;
    mapping(uint256 => ArtNFT) public artNFTs;
    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        address artist;
        uint256 price; // in wei
        bool forSale;
        address owner;
    }
    mapping(uint256 => address) public nftOwners;
    mapping(uint256 => uint256) public artistEarnings; // tokenId => earnings in wei

    // Treasury management
    uint256 public treasuryBalance;

    // Treasury Spending Proposals
    uint256 public spendingProposalCounter;
    struct TreasurySpendingProposal {
        uint256 id;
        address proposer;
        string description;
        address recipient;
        uint256 amount;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool votingActive;
        bool proposalApproved;
        bool proposalRejected;
    }
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    mapping(uint256 => mapping(address => bool)) public spendingProposalVotes; // spendingProposalId => voter => votedYes

    // Configuration parameters
    uint256 public votingDuration = 7 days; // Default voting duration
    uint8 public quorumPercentage = 50; // Default quorum percentage for voting
    uint8 public platformFeePercentage = 5; // Percentage of NFT sale price taken as platform fee

    // Events
    event ArtistApplicationSubmitted(address applicant);
    event ArtistApplicationApproved(address artist);
    event ArtistMembershipRevoked(address artist);
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVotingStarted(uint256 proposalId);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalVotingTallied(uint256 proposalId, bool accepted);
    event ArtProposalAccepted(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event NFTPriceSet(uint256 tokenId, uint256 price);
    event NFTPurchased(uint256 tokenId, address buyer, uint256 price);
    event ArtistEarningsWithdrawn(uint256 tokenId, address artist, uint256 amount);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasurySpendingProposed(uint256 spendingProposalId, address proposer, string description, address recipient, uint256 amount);
    event TreasurySpendingVotingStarted(uint256 spendingProposalId);
    event TreasurySpendingVoted(uint256 spendingProposalId, address voter, bool vote);
    event TreasurySpendingVotingTallied(uint256 spendingProposalId, bool approved);
    event TreasurySpendingExecuted(uint256 spendingProposalId, address recipient, uint256 amount);
    event VotingDurationSet(uint256 durationInSeconds);
    event QuorumPercentageSet(uint8 percentage);
    event PlatformFeePercentageSet(uint8 percentage);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyArtist() {
        require(isArtist[msg.sender], "Only artists can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validSpendingProposalId(uint256 _spendingProposalId) {
        require(_spendingProposalId > 0 && _spendingProposalId <= spendingProposalCounter, "Invalid spending proposal ID.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId <= nftCounter, "Invalid token ID.");
        _;
    }

    modifier votingNotActive(uint256 _proposalId) {
        require(!artProposals[_proposalId].votingActive, "Voting is already active for this proposal.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(artProposals[_proposalId].votingActive, "Voting is not active for this proposal.");
        _;
    }

    modifier votingNotExpired(uint256 _proposalId) {
        require(block.timestamp <= artProposals[_proposalId].votingEndTime, "Voting period has expired.");
        _;
    }

    modifier spendingVotingNotActive(uint256 _spendingProposalId) {
        require(!treasurySpendingProposals[_spendingProposalId].votingActive, "Spending voting is already active.");
        _;
    }

    modifier spendingVotingActive(uint256 _spendingProposalId) {
        require(treasurySpendingProposals[_spendingProposalId].votingActive, "Spending voting is not active.");
        _;
    }

    modifier spendingVotingNotExpired(uint256 _spendingProposalId) {
        require(block.timestamp <= treasurySpendingProposals[_spendingProposalId].votingEndTime, "Spending voting period has expired.");
        _;
    }


    constructor() {
        admin = msg.sender;
    }

    /**
     * @dev Allows users to apply to become an artist member of the collective.
     */
    function applyForArtistMembership() public {
        require(!isArtist[msg.sender], "You are already an artist member.");
        require(!pendingArtistApplications[msg.sender], "Your application is already pending.");
        pendingArtistApplications[msg.sender] = true;
        emit ArtistApplicationSubmitted(msg.sender);
    }

    /**
     * @dev Admin function to approve pending artist applications.
     * @param _applicant The address of the applicant to approve.
     */
    function approveArtistApplication(address _applicant) public onlyAdmin {
        require(pendingArtistApplications[_applicant], "No pending application found for this address.");
        require(!isArtist[_applicant], "Applicant is already an artist.");
        isArtist[_applicant] = true;
        artistList.push(_applicant);
        pendingArtistApplications[_applicant] = false;
        emit ArtistApplicationApproved(_applicant);
    }

    /**
     * @dev Admin function to revoke an artist's membership.
     * @param _artist The address of the artist to revoke membership from.
     */
    function revokeArtistMembership(address _artist) public onlyAdmin {
        require(isArtist[_artist], "Address is not an artist member.");
        isArtist[_artist] = false;

        // Remove artist from artistList array - inefficient for large lists in production, consider alternative data structures
        for (uint256 i = 0; i < artistList.length; i++) {
            if (artistList[i] == _artist) {
                artistList[i] = artistList[artistList.length - 1];
                artistList.pop();
                break;
            }
        }
        emit ArtistMembershipRevoked(_artist);
    }

    /**
     * @dev Artists submit art proposals with title, description, and IPFS hash of the artwork.
     * @param _title The title of the artwork.
     * @param _description A brief description of the artwork.
     * @param _ipfsHash The IPFS hash of the artwork's metadata or file.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyArtist {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            id: proposalCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            votingStartTime: 0,
            votingEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            votingActive: false,
            proposalAccepted: false,
            proposalRejected: false
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Admin function to initiate voting for a specific art proposal.
     * @param _proposalId The ID of the art proposal to start voting for.
     */
    function startArtProposalVoting(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) votingNotActive(_proposalId) {
        artProposals[_proposalId].votingActive = true;
        artProposals[_proposalId].votingStartTime = block.timestamp;
        artProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        emit ArtProposalVotingStarted(_proposalId);
    }

    /**
     * @dev Members (artists and potentially others - currently only artists can vote) can vote on art proposals.
     * @param _proposalId The ID of the art proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyArtist validProposalId(_proposalId) votingActive(_proposalId) votingNotExpired(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true; // Record that voter has voted (regardless of yes/no)
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Admin function to close voting and tally the results for an art proposal.
     * @param _proposalId The ID of the art proposal to tally votes for.
     */
    function tallyArtProposalVotes(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) votingActive(_proposalId) votingNotExpired(_proposalId) {
        require(!artProposals[_proposalId].proposalAccepted && !artProposals[_proposalId].proposalRejected, "Proposal already processed.");
        artProposals[_proposalId].votingActive = false;

        uint256 totalVotes = artProposals[_proposalId].yesVotes + artProposals[_proposalId].noVotes;
        uint256 quorum = (artistList.length * quorumPercentage) / 100; // Quorum based on artist list size - adjust logic as needed

        bool accepted = false;
        if (totalVotes >= quorum && artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            accepted = true;
            artProposals[_proposalId].proposalAccepted = true;
            emit ArtProposalAccepted(_proposalId);
        } else {
            artProposals[_proposalId].proposalRejected = true;
            emit ArtProposalRejected(_proposalId);
        }
        emit ArtProposalVotingTallied(_proposalId, accepted);
    }

    /**
     * @dev Admin function to accept an art proposal manually (can be used if tallying is automated elsewhere).
     * @param _proposalId The ID of the art proposal to accept.
     */
    function acceptArtProposal(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        require(!artProposals[_proposalId].proposalAccepted && !artProposals[_proposalId].proposalRejected, "Proposal already processed.");
        artProposals[_proposalId].proposalAccepted = true;
        emit ArtProposalAccepted(_proposalId);
    }

    /**
     * @dev Admin function to reject an art proposal manually.
     * @param _proposalId The ID of the art proposal to reject.
     */
    function rejectArtProposal(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        require(!artProposals[_proposalId].proposalAccepted && !artProposals[_proposalId].proposalRejected, "Proposal already processed.");
        artProposals[_proposalId].proposalRejected = true;
        emit ArtProposalRejected(_proposalId);
    }

    /**
     * @dev Mints an NFT representing the accepted artwork, transferring it to the artist.
     * @param _proposalId The ID of the accepted art proposal.
     */
    function mintArtNFT(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        require(artProposals[_proposalId].proposalAccepted, "Proposal must be accepted to mint NFT.");
        require(artNFTs[nftCounter + 1].tokenId == 0, "NFT already minted for this proposal or token ID conflict."); // Basic check, can be improved

        nftCounter++;
        artNFTs[nftCounter] = ArtNFT({
            tokenId: nftCounter,
            proposalId: _proposalId,
            artist: artProposals[_proposalId].artist,
            price: 0, // Initial price is 0, artist can set later
            forSale: false,
            owner: artProposals[_proposalId].artist
        });
        nftOwners[nftCounter] = artProposals[_proposalId].artist;
        emit ArtNFTMinted(nftCounter, _proposalId, artProposals[_proposalId].artist);
    }

    /**
     * @dev Artists can set the price for their minted NFTs.
     * @param _tokenId The ID of the NFT.
     * @param _price The price in wei.
     */
    function setNFTPrice(uint256 _tokenId, uint256 _price) public onlyArtist validTokenId(_tokenId) {
        require(artNFTs[_tokenId].artist == msg.sender, "You are not the artist of this NFT.");
        artNFTs[_tokenId].price = _price;
        artNFTs[_tokenId].forSale = true;
        emit NFTPriceSet(_tokenId, _price);
    }

    /**
     * @dev Allows users to purchase NFTs from the collective.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyArtNFT(uint256 _tokenId) payable public validTokenId(_tokenId) {
        require(artNFTs[_tokenId].forSale, "NFT is not for sale.");
        require(msg.value >= artNFTs[_tokenId].price, "Insufficient funds sent.");

        uint256 artistShare = (artNFTs[_tokenId].price * (100 - platformFeePercentage)) / 100;
        uint256 platformFee = artNFTs[_tokenId].price - artistShare;

        artistEarnings[_tokenId] += artistShare;
        treasuryBalance += platformFee;
        nftOwners[_tokenId] = msg.sender;
        artNFTs[_tokenId].owner = msg.sender;
        artNFTs[_tokenId].forSale = false; // NFT is no longer for sale after purchase

        emit NFTPurchased(_tokenId, msg.sender, artNFTs[_tokenId].price);
        emit TreasuryDeposit(address(this), platformFee); // Treat platform fee as deposit to treasury
    }

    /**
     * @dev Artists can withdraw earnings from the sale of their NFTs.
     * @param _tokenId The ID of the NFT for which to withdraw earnings.
     */
    function withdrawArtistEarnings(uint256 _tokenId) public onlyArtist validTokenId(_tokenId) {
        require(artNFTs[_tokenId].artist == msg.sender, "You are not the artist of this NFT.");
        require(artistEarnings[_tokenId] > 0, "No earnings to withdraw for this NFT.");

        uint256 amount = artistEarnings[_tokenId];
        artistEarnings[_tokenId] = 0; // Reset earnings after withdrawal

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");
        emit ArtistEarningsWithdrawn(_tokenId, msg.sender, amount);
    }

    /**
     * @dev Allows anyone to deposit ETH into the collective treasury.
     */
    function depositToTreasury() payable public {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Members can propose spending from the treasury.
     * @param _description A description of the spending proposal.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount to spend in wei.
     */
    function proposeTreasurySpending(string memory _description, address _recipient, uint256 _amount) public onlyArtist { // For simplicity, only artists can propose - adjust as needed
        require(_amount > 0, "Spending amount must be greater than zero.");
        require(_recipient != address(0), "Invalid recipient address.");
        require(treasuryBalance >= _amount, "Treasury balance is insufficient for this spending.");

        spendingProposalCounter++;
        treasurySpendingProposals[spendingProposalCounter] = TreasurySpendingProposal({
            id: spendingProposalCounter,
            proposer: msg.sender,
            description: _description,
            recipient: _recipient,
            amount: _amount,
            votingStartTime: 0,
            votingEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            votingActive: false,
            proposalApproved: false,
            proposalRejected: false
        });
        emit TreasurySpendingProposed(spendingProposalCounter, msg.sender, _description, _recipient, _amount);
    }

    /**
     * @dev Admin function to start voting on a treasury spending proposal.
     * @param _spendingProposalId The ID of the treasury spending proposal to start voting for.
     */
    function startTreasurySpendingVote(uint256 _spendingProposalId) public onlyAdmin validSpendingProposalId(_spendingProposalId) spendingVotingNotActive(_spendingProposalId) {
        treasurySpendingProposals[_spendingProposalId].votingActive = true;
        treasurySpendingProposals[_spendingProposalId].votingStartTime = block.timestamp;
        treasurySpendingProposals[_spendingProposalId].votingEndTime = block.timestamp + votingDuration;
        emit TreasurySpendingVotingStarted(_spendingProposalId);
    }

    /**
     * @dev Members vote on treasury spending proposals.
     * @param _spendingProposalId The ID of the treasury spending proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnTreasurySpending(uint256 _spendingProposalId, bool _vote) public onlyArtist validSpendingProposalId(_spendingProposalId) spendingVotingActive(_spendingProposalId) spendingVotingNotExpired(_spendingProposalId) {
        require(!spendingProposalVotes[_spendingProposalId][msg.sender], "You have already voted on this spending proposal.");
        spendingProposalVotes[_spendingProposalId][msg.sender] = true;
        if (_vote) {
            treasurySpendingProposals[_spendingProposalId].yesVotes++;
        } else {
            treasurySpendingProposals[_spendingProposalId].noVotes++;
        }
        emit TreasurySpendingVoted(_spendingProposalId, msg.sender, _vote);
    }

    /**
     * @dev Admin function to tally votes for treasury spending proposals.
     * @param _spendingProposalId The ID of the treasury spending proposal to tally votes for.
     */
    function tallyTreasurySpendingVotes(uint256 _spendingProposalId) public onlyAdmin validSpendingProposalId(_spendingProposalId) spendingVotingActive(_spendingProposalId) spendingVotingNotExpired(_spendingProposalId) {
        require(!treasurySpendingProposals[_spendingProposalId].proposalApproved && !treasurySpendingProposals[_spendingProposalId].proposalRejected, "Spending proposal already processed.");
        treasurySpendingProposals[_spendingProposalId].votingActive = false;

        uint256 totalVotes = treasurySpendingProposals[_spendingProposalId].yesVotes + treasurySpendingProposals[_spendingProposalId].noVotes;
        uint256 quorum = (artistList.length * quorumPercentage) / 100;

        bool approved = false;
        if (totalVotes >= quorum && treasurySpendingProposals[_spendingProposalId].yesVotes > treasurySpendingProposals[_spendingProposalId].noVotes) {
            approved = true;
            treasurySpendingProposals[_spendingProposalId].proposalApproved = true;
            emit TreasurySpendingVotingTallied(_spendingProposalId, approved);
        } else {
            treasurySpendingProposals[_spendingProposalId].proposalRejected = true;
            emit TreasurySpendingVotingTallied(_spendingProposalId, approved);
        }
    }

    /**
     * @dev Admin function to execute approved treasury spending proposals.
     * @param _spendingProposalId The ID of the treasury spending proposal to execute.
     */
    function executeTreasurySpending(uint256 _spendingProposalId) public onlyAdmin validSpendingProposalId(_spendingProposalId) {
        require(treasurySpendingProposals[_spendingProposalId].proposalApproved, "Spending proposal must be approved to execute.");
        require(treasuryBalance >= treasurySpendingProposals[_spendingProposalId].amount, "Treasury balance is insufficient for execution.");

        uint256 amount = treasurySpendingProposals[_spendingProposalId].amount;
        address recipient = treasurySpendingProposals[_spendingProposalId].recipient;

        treasuryBalance -= amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Treasury spending execution failed.");

        emit TreasurySpendingExecuted(_spendingProposalId, recipient, amount);
    }

    /**
     * @dev Admin function to set the default voting duration.
     * @param _durationInSeconds The voting duration in seconds.
     */
    function setVotingDuration(uint256 _durationInSeconds) public onlyAdmin {
        votingDuration = _durationInSeconds;
        emit VotingDurationSet(_durationInSeconds);
    }

    /**
     * @dev Admin function to set the quorum percentage for voting.
     * @param _percentage The quorum percentage (0-100).
     */
    function setQuorumPercentage(uint8 _percentage) public onlyAdmin {
        require(_percentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _percentage;
        emit QuorumPercentageSet(_percentage);
    }

     /**
     * @dev Admin function to set the platform fee percentage on NFT sales.
     * @param _percentage The platform fee percentage (0-100).
     */
    function setPlatformFeePercentage(uint8 _percentage) public onlyAdmin {
        require(_percentage <= 100, "Platform fee percentage must be between 0 and 100.");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    /**
     * @dev Returns a list of artist addresses in the collective.
     * @return An array of artist addresses.
     */
    function getArtistList() public view returns (address[] memory) {
        return artistList;
    }

    /**
     * @dev Returns details of a specific art proposal.
     * @param _proposalId The ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Returns details of a specific NFT minted by the collective.
     * @param _tokenId The ID of the NFT.
     * @return ArtNFT struct containing NFT details.
     */
    function getNFTDetails(uint256 _tokenId) public view validTokenId(_tokenId) returns (ArtNFT memory) {
        return artNFTs[_tokenId];
    }

    /**
     * @dev Returns the current balance of the collective treasury.
     * @return The treasury balance in wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    // Fallback function to accept ETH deposits
    receive() external payable {
        depositToTreasury();
    }
}
```