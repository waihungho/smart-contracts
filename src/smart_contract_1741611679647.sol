```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Conceptual and Not Audited)
 * @notice A smart contract for a decentralized autonomous art collective, enabling collaborative art creation,
 *         curation, fractional ownership, and community-driven exhibitions within the blockchain.
 *
 * Function Summary:
 *
 * 1.  `registerArtist(string memory artistName, string memory artistBio)`: Allows artists to register with the collective, providing a name and bio.
 * 2.  `submitArtProposal(string memory title, string memory description, string memory ipfsHash)`: Artists propose new art pieces for the collective, including title, description, and IPFS hash.
 * 3.  `voteOnArtProposal(uint256 proposalId, bool vote)`: Registered members can vote on submitted art proposals.
 * 4.  `executeArtProposal(uint256 proposalId)`: Executes an approved art proposal, minting fractional ownership tokens (Art Shares).
 * 5.  `purchaseArtShares(uint256 artId, uint256 amount)`: Allows members to purchase shares of a specific art piece, contributing to the artist and collective treasury.
 * 6.  `transferArtShares(uint256 artId, address recipient, uint256 amount)`: Allows share holders to transfer their art shares to other members.
 * 7.  `redeemArtShareRevenue(uint256 artId)`: Allows art share holders to redeem their share of revenue generated by the art piece.
 * 8.  `createExhibitionProposal(string memory exhibitionTitle, string memory exhibitionDescription, uint256[] memory artIds)`: Members propose exhibitions featuring selected art pieces from the collective.
 * 9.  `voteOnExhibitionProposal(uint256 exhibitionProposalId, bool vote)`: Registered members vote on exhibition proposals.
 * 10. `executeExhibitionProposal(uint256 exhibitionProposalId)`: Executes an approved exhibition proposal, potentially triggering exhibition events (off-chain).
 * 11. `setExhibitionTicketPrice(uint256 exhibitionProposalId, uint256 price)`:  Sets the ticket price for a specific exhibition.
 * 12. `purchaseExhibitionTicket(uint256 exhibitionProposalId)`: Allows members to purchase tickets for an exhibition.
 * 13. `withdrawExhibitionRevenue(uint256 exhibitionProposalId)`: Allows the exhibition proposer to withdraw revenue generated from ticket sales after an exhibition.
 * 14. `createCollectiveChallenge(string memory challengeTitle, string memory challengeDescription, uint256 rewardAmount)`:  Allows the collective to initiate art challenges with rewards for winning submissions.
 * 15. `submitChallengeEntry(uint256 challengeId, string memory title, string memory description, string memory ipfsHash)`: Artists submit entries for active collective challenges.
 * 16. `voteOnChallengeEntry(uint256 challengeId, uint256 entryId, bool vote)`: Registered members vote on challenge entries.
 * 17. `finalizeChallenge(uint256 challengeId)`: Finalizes a challenge after voting, selecting winners and distributing rewards.
 * 18. `setMembershipFee(uint256 feeAmount)`:  Allows the contract owner to set a membership fee for joining the collective.
 * 19. `joinCollective()`:  Allows users to join the collective by paying the membership fee.
 * 20. `withdrawCollectiveTreasury()`: Allows the contract owner to withdraw funds from the collective treasury (governance could be added for this in a real DAO).
 * 21. `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 * 22. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 23. `getArtDetails(uint256 artId)`: Retrieves details of a specific art piece.
 * 24. `getArtistDetails(address artistAddress)`: Retrieves details of a registered artist.
 * 25. `getProposalDetails(uint256 proposalId)`: Retrieves details of a specific art proposal.
 */

contract DecentralizedArtCollective {
    // --- State Variables ---

    address public owner;
    uint256 public membershipFee;
    bool public paused;

    uint256 public nextArtistId;
    mapping(address => Artist) public artists;
    address[] public registeredArtists;

    uint256 public nextArtId;
    mapping(uint256 => ArtPiece) public artPieces;
    uint256[] public collectiveArtIds;

    uint256 public nextProposalId;
    mapping(uint256 => ArtProposal) public artProposals;

    uint256 public nextExhibitionProposalId;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;

    uint256 public nextChallengeId;
    mapping(uint256 => ArtChallenge) public artChallenges;

    uint256 public collectiveTreasury;

    uint256 public votingDuration = 7 days; // Default voting duration

    struct Artist {
        uint256 artistId;
        string artistName;
        string artistBio;
        bool isRegistered;
    }

    struct ArtPiece {
        uint256 artId;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 totalShares;
        uint256 sharesSupply;
        uint256 revenueBalance; // Revenue accumulated from shares
        bool isApproved;
    }

    struct ArtProposal {
        uint256 proposalId;
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalStartTime;
        bool isExecuted;
    }

    struct ExhibitionProposal {
        uint256 exhibitionProposalId;
        string exhibitionTitle;
        string exhibitionDescription;
        address proposer;
        uint256[] artIds;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalStartTime;
        bool isExecuted;
        uint256 ticketPrice;
        uint256 ticketsSold;
        uint256 exhibitionRevenue;
    }

    struct ArtChallenge {
        uint256 challengeId;
        string challengeTitle;
        string challengeDescription;
        uint256 rewardAmount;
        uint256 challengeStartTime;
        uint256 challengeEndTime;
        bool isActive;
        mapping(uint256 => ChallengeEntry) challengeEntries;
        uint256 nextEntryId;
    }

    struct ChallengeEntry {
        uint256 entryId;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    mapping(uint256 => mapping(address => uint256)) public artShareBalances; // artId => (memberAddress => shareBalance)
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => (voterAddress => hasVoted)
    mapping(uint256 => mapping(address => bool)) public exhibitionProposalVotes; // exhibitionProposalId => (voterAddress => hasVoted)
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public challengeEntryVotes; // challengeId => entryId => (voterAddress => hasVoted)
    mapping(address => bool) public collectiveMembers;


    // --- Events ---

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId, uint256 artId);
    event ArtSharesPurchased(uint256 artId, address buyer, uint256 amount);
    event ArtSharesTransferred(uint256 artId, address from, address to, uint256 amount);
    event ArtShareRevenueRedeemed(uint256 artId, address redeemer, uint256 amount);
    event ExhibitionProposalSubmitted(uint256 exhibitionProposalId, string title, address proposer);
    event ExhibitionProposalVoted(uint256 exhibitionProposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 exhibitionProposalId);
    event ExhibitionTicketPurchased(uint256 exhibitionProposalId, address buyer);
    event ExhibitionRevenueWithdrawn(uint256 exhibitionProposalId, address withdrawer, uint256 amount);
    event CollectiveChallengeCreated(uint256 challengeId, string title, uint256 rewardAmount);
    event ChallengeEntrySubmitted(uint256 challengeId, uint256 entryId, address artist);
    event ChallengeEntryVoted(uint256 challengeId, uint256 entryId, address voter, bool vote);
    event ChallengeFinalized(uint256 challengeId, uint256 winnerEntryId);
    event MembershipFeeSet(uint256 feeAmount);
    event CollectiveMemberJoined(address memberAddress);
    event ContractPaused();
    event ContractUnpaused();
    event TreasuryWithdrawal(uint256 amount, address withdrawnBy);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyRegisteredArtist() {
        require(artists[msg.sender].isRegistered, "Only registered artists can call this function.");
        _;
    }

    modifier onlyCollectiveMember() {
        require(collectiveMembers[msg.sender], "Only collective members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= nextProposalId && !artProposals[_proposalId].isExecuted, "Invalid or executed proposal ID.");
        _;
    }

    modifier validExhibitionProposal(uint256 _exhibitionProposalId) {
        require(_exhibitionProposalId > 0 && _exhibitionProposalId <= nextExhibitionProposalId && !exhibitionProposals[_exhibitionProposalId].isExecuted, "Invalid or executed exhibition proposal ID.");
        _;
    }

    modifier validChallenge(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= nextChallengeId && artChallenges[_challengeId].isActive, "Invalid or inactive challenge ID.");
        _;
    }

    modifier validChallengeEntry(uint256 _challengeId, uint256 _entryId) {
        require(validChallenge(_challengeId), "Invalid challenge ID.");
        require(_entryId > 0 && _entryId <= artChallenges[_challengeId].nextEntryId, "Invalid challenge entry ID.");
        _;
    }

    modifier notVotedOnProposal(uint256 _proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        _;
    }

    modifier notVotedOnExhibitionProposal(uint256 _exhibitionProposalId) {
        require(!exhibitionProposalVotes[_exhibitionProposalId][msg.sender], "Already voted on this exhibition proposal.");
        _;
    }

    modifier notVotedOnChallengeEntry(uint256 _challengeId, uint256 _entryId) {
        require(!challengeEntryVotes[_challengeId][_entryId][msg.sender], "Already voted on this challenge entry.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        membershipFee = 0.1 ether; // Initial membership fee
        paused = false;
        nextArtistId = 1;
        nextArtId = 1;
        nextProposalId = 1;
        nextExhibitionProposalId = 1;
        nextChallengeId = 1;
    }


    // --- Artist Registration ---

    function registerArtist(string memory _artistName, string memory _artistBio) external whenNotPaused onlyCollectiveMember {
        require(!artists[msg.sender].isRegistered, "Artist is already registered.");
        artists[msg.sender] = Artist({
            artistId: nextArtistId,
            artistName: _artistName,
            artistBio: _artistBio,
            isRegistered: true
        });
        registeredArtists.push(msg.sender);
        nextArtistId++;
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function getArtistDetails(address _artistAddress) external view returns (Artist memory) {
        return artists[_artistAddress];
    }


    // --- Art Proposal & Curation ---

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external whenNotPaused onlyRegisteredArtist {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Invalid proposal details.");
        artProposals[nextProposalId] = ArtProposal({
            proposalId: nextProposalId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            proposalStartTime: block.timestamp,
            isExecuted: false
        });
        emit ArtProposalSubmitted(nextProposalId, _title, msg.sender);
        nextProposalId++;
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external whenNotPaused onlyCollectiveMember validProposal(_proposalId) notVotedOnProposal(_proposalId) {
        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeArtProposal(uint256 _proposalId) external whenNotPaused onlyOwner validProposal(_proposalId) {
        require(block.timestamp >= artProposals[_proposalId].proposalStartTime + votingDuration, "Voting period not ended.");
        require(artProposals[_proposalId].votesFor > artProposals[_proposalId].votesAgainst, "Proposal not approved.");

        ArtProposal storage proposal = artProposals[_proposalId];
        artPieces[nextArtId] = ArtPiece({
            artId: nextArtId,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            artist: proposal.proposer,
            totalShares: 1000, // Example: 1000 shares per artwork
            sharesSupply: 1000,
            revenueBalance: 0,
            isApproved: true
        });
        collectiveArtIds.push(nextArtId);
        proposal.isExecuted = true;
        emit ArtProposalExecuted(_proposalId, nextArtId);
        nextArtId++;
    }

    function getProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getArtDetails(uint256 _artId) external view returns (ArtPiece memory) {
        return artPieces[_artId];
    }


    // --- Art Shares Management ---

    function purchaseArtShares(uint256 _artId, uint256 _amount) external payable whenNotPaused onlyCollectiveMember {
        require(_artId > 0 && _artId <= nextArtId && artPieces[_artId].isApproved, "Invalid art ID or art not approved.");
        require(_amount > 0 && _amount <= artPieces[_artId].sharesSupply, "Invalid share amount or insufficient supply.");

        uint256 sharePrice = 0.01 ether; // Example share price - can be dynamic or set per artwork
        uint256 purchaseCost = sharePrice * _amount;
        require(msg.value >= purchaseCost, "Insufficient payment for shares.");

        ArtPiece storage art = artPieces[_artId];
        artShareBalances[_artId][msg.sender] += _amount;
        art.sharesSupply -= _amount;
        art.revenueBalance += purchaseCost; // Revenue goes to the art piece balance
        collectiveTreasury += purchaseCost; // Portion goes to collective treasury (can adjust split)

        // Transfer remaining value back to buyer if overpaid
        if (msg.value > purchaseCost) {
            payable(msg.sender).transfer(msg.value - purchaseCost);
        }

        emit ArtSharesPurchased(_artId, msg.sender, _amount);
    }

    function transferArtShares(uint256 _artId, address _recipient, uint256 _amount) external whenNotPaused onlyCollectiveMember {
        require(_artId > 0 && _artId <= nextArtId && artPieces[_artId].isApproved, "Invalid art ID or art not approved.");
        require(_recipient != address(0) && _recipient != msg.sender, "Invalid recipient address.");
        require(_amount > 0 && artShareBalances[_artId][msg.sender] >= _amount, "Insufficient shares to transfer.");

        artShareBalances[_artId][msg.sender] -= _amount;
        artShareBalances[_artId][_recipient] += _amount;
        emit ArtSharesTransferred(_artId, msg.sender, _recipient, _amount);
    }

    function redeemArtShareRevenue(uint256 _artId) external whenNotPaused onlyCollectiveMember {
        require(_artId > 0 && _artId <= nextArtId && artPieces[_artId].isApproved, "Invalid art ID or art not approved.");
        require(artShareBalances[_artId][msg.sender] > 0, "You do not own shares of this art.");

        ArtPiece storage art = artPieces[_artId];
        uint256 userShares = artShareBalances[_artId][msg.sender];
        uint256 totalShares = art.totalShares;
        uint256 availableRevenue = art.revenueBalance;

        uint256 redeemableAmount = (availableRevenue * userShares) / totalShares;
        require(redeemableAmount > 0, "No revenue to redeem for your shares.");

        art.revenueBalance -= redeemableAmount;
        payable(msg.sender).transfer(redeemableAmount);
        emit ArtShareRevenueRedeemed(_artId, msg.sender, redeemableAmount);
    }


    // --- Exhibition Proposals ---

    function createExhibitionProposal(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256[] memory _artIds) external whenNotPaused onlyCollectiveMember {
        require(bytes(_exhibitionTitle).length > 0 && bytes(_exhibitionDescription).length > 0 && _artIds.length > 0, "Invalid exhibition details.");
        // Add checks to ensure artIds are valid and part of the collective if needed

        exhibitionProposals[nextExhibitionProposalId] = ExhibitionProposal({
            exhibitionProposalId: nextExhibitionProposalId,
            exhibitionTitle: _exhibitionTitle,
            exhibitionDescription: _exhibitionDescription,
            proposer: msg.sender,
            artIds: _artIds,
            votesFor: 0,
            votesAgainst: 0,
            proposalStartTime: block.timestamp,
            isExecuted: false,
            ticketPrice: 0, // Ticket price initially 0, can be set later
            ticketsSold: 0,
            exhibitionRevenue: 0
        });
        emit ExhibitionProposalSubmitted(nextExhibitionProposalId, _exhibitionTitle, msg.sender);
        nextExhibitionProposalId++;
    }

    function voteOnExhibitionProposal(uint256 _exhibitionProposalId, bool _vote) external whenNotPaused onlyCollectiveMember validExhibitionProposal(_exhibitionProposalId) notVotedOnExhibitionProposal(_exhibitionProposalId) {
        exhibitionProposalVotes[_exhibitionProposalId][msg.sender] = true;
        if (_vote) {
            exhibitionProposals[_exhibitionProposalId].votesFor++;
        } else {
            exhibitionProposals[_exhibitionProposalId].votesAgainst++;
        }
        emit ExhibitionProposalVoted(_exhibitionProposalId, msg.sender, _vote);
    }

    function executeExhibitionProposal(uint256 _exhibitionProposalId) external whenNotPaused onlyOwner validExhibitionProposal(_exhibitionProposalId) {
        require(block.timestamp >= exhibitionProposals[_exhibitionProposalId].proposalStartTime + votingDuration, "Voting period not ended.");
        require(exhibitionProposals[_exhibitionProposalId].votesFor > exhibitionProposals[_exhibitionProposalId].votesAgainst, "Exhibition proposal not approved.");

        exhibitionProposals[_exhibitionProposalId].isExecuted = true;
        emit ExhibitionProposalExecuted(_exhibitionProposalId);
        // Additional logic can be added here to trigger off-chain exhibition setup/events
    }

    function setExhibitionTicketPrice(uint256 _exhibitionProposalId, uint256 _price) external whenNotPaused onlyOwner validExhibitionProposal(_exhibitionProposalId) {
        require(_price >= 0, "Ticket price cannot be negative.");
        exhibitionProposals[_exhibitionProposalId].ticketPrice = _price;
    }

    function purchaseExhibitionTicket(uint256 _exhibitionProposalId) external payable whenNotPaused onlyCollectiveMember validExhibitionProposal(_exhibitionProposalId) {
        ExhibitionProposal storage exhibition = exhibitionProposals[_exhibitionProposalId];
        require(exhibition.ticketPrice > 0, "Ticket price not set for this exhibition yet.");
        require(msg.value >= exhibition.ticketPrice, "Insufficient ticket payment.");

        exhibition.ticketsSold++;
        exhibition.exhibitionRevenue += exhibition.ticketPrice;

        // Transfer remaining value back to buyer if overpaid
        if (msg.value > exhibition.ticketPrice) {
            payable(msg.sender).transfer(msg.value - exhibition.ticketPrice);
        }
        emit ExhibitionTicketPurchased(_exhibitionProposalId, msg.sender);
    }

    function withdrawExhibitionRevenue(uint256 _exhibitionProposalId) external whenNotPaused onlyCollectiveMember validExhibitionProposal(_exhibitionProposalId) {
        ExhibitionProposal storage exhibition = exhibitionProposals[_exhibitionProposalId];
        require(msg.sender == exhibition.proposer, "Only exhibition proposer can withdraw revenue.");
        require(exhibition.exhibitionRevenue > 0, "No revenue to withdraw.");

        uint256 amountToWithdraw = exhibition.exhibitionRevenue;
        exhibition.exhibitionRevenue = 0; // Reset exhibition revenue after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        emit ExhibitionRevenueWithdrawn(_exhibitionProposalId, msg.sender, amountToWithdraw);
    }


    // --- Collective Challenges ---

    function createCollectiveChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _rewardAmount) external whenNotPaused onlyOwner {
        require(bytes(_challengeTitle).length > 0 && bytes(_challengeDescription).length > 0 && _rewardAmount > 0, "Invalid challenge details.");
        require(_rewardAmount <= collectiveTreasury, "Insufficient funds in treasury for reward.");

        artChallenges[nextChallengeId] = ArtChallenge({
            challengeId: nextChallengeId,
            challengeTitle: _challengeTitle,
            challengeDescription: _challengeDescription,
            rewardAmount: _rewardAmount,
            challengeStartTime: block.timestamp,
            challengeEndTime: block.timestamp + 30 days, // Example challenge duration - 30 days
            isActive: true,
            nextEntryId: 1
        });
        collectiveTreasury -= _rewardAmount; // Reserve reward from treasury
        emit CollectiveChallengeCreated(nextChallengeId, _challengeTitle, _rewardAmount);
        nextChallengeId++;
    }

    function submitChallengeEntry(uint256 _challengeId, string memory _title, string memory _description, string memory _ipfsHash) external whenNotPaused onlyRegisteredArtist validChallenge(_challengeId) {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Invalid entry details.");
        require(block.timestamp <= artChallenges[_challengeId].challengeEndTime, "Challenge entry period ended.");

        ArtChallenge storage challenge = artChallenges[_challengeId];
        challenge.challengeEntries[challenge.nextEntryId] = ChallengeEntry({
            entryId: challenge.nextEntryId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            votesFor: 0,
            votesAgainst: 0
        });
        emit ChallengeEntrySubmitted(_challengeId, challenge.nextEntryId, msg.sender);
        challenge.nextEntryId++;
    }

    function voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _vote) external whenNotPaused onlyCollectiveMember validChallengeEntry(_challengeId, _entryId) notVotedOnChallengeEntry(_challengeId, _entryId) {
        challengeEntryVotes[_challengeId][_entryId][msg.sender] = true;
        if (_vote) {
            artChallenges[_challengeId].challengeEntries[_entryId].votesFor++;
        } else {
            artChallenges[_challengeId].challengeEntries[_entryId].votesAgainst++;
        }
        emit ChallengeEntryVoted(_challengeId, _entryId, msg.sender, _vote);
    }

    function finalizeChallenge(uint256 _challengeId) external whenNotPaused onlyOwner validChallenge(_challengeId) {
        require(block.timestamp >= artChallenges[_challengeId].challengeEndTime, "Challenge voting period not ended.");
        artChallenges[_challengeId].isActive = false; // Deactivate the challenge

        uint256 winningEntryId = 0;
        uint256 maxVotes = 0;

        ArtChallenge storage challenge = artChallenges[_challengeId];
        for (uint256 entryId = 1; entryId < challenge.nextEntryId; entryId++) {
            if (challenge.challengeEntries[entryId].votesFor > maxVotes) {
                maxVotes = challenge.challengeEntries[entryId].votesFor;
                winningEntryId = entryId;
            }
        }

        if (winningEntryId > 0) {
            address winnerAddress = challenge.challengeEntries[winningEntryId].artist;
            uint256 rewardAmount = challenge.rewardAmount;
            payable(winnerAddress).transfer(rewardAmount);
            emit ChallengeFinalized(_challengeId, winningEntryId);
        } else {
            // Handle case with no winner (e.g., return reward to treasury)
            collectiveTreasury += challenge.rewardAmount; // Return reward if no winner
            emit ChallengeFinalized(_challengeId, 0); // 0 indicates no winner
        }
    }


    // --- Collective Membership ---

    function setMembershipFee(uint256 _feeAmount) external onlyOwner {
        membershipFee = _feeAmount;
        emit MembershipFeeSet(_feeAmount);
    }

    function joinCollective() external payable whenNotPaused {
        require(!collectiveMembers[msg.sender], "Already a collective member.");
        require(msg.value >= membershipFee, "Insufficient membership fee payment.");
        collectiveMembers[msg.sender] = true;
        collectiveTreasury += membershipFee;

        // Transfer remaining value back if overpaid
        if (msg.value > membershipFee) {
            payable(msg.sender).transfer(msg.value - membershipFee);
        }
        emit CollectiveMemberJoined(msg.sender);
    }


    // --- Treasury Management ---

    function withdrawCollectiveTreasury() external onlyOwner {
        require(collectiveTreasury > 0, "No funds in treasury to withdraw.");
        uint256 amountToWithdraw = collectiveTreasury;
        collectiveTreasury = 0; // Empty the treasury for simplicity - in a real DAO, governance would be needed
        payable(owner).transfer(amountToWithdraw);
        emit TreasuryWithdrawal(amountToWithdraw, owner);
    }


    // --- Pausable Functionality ---

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback and Receive Functions (Optional - for receiving ETH directly) ---

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```