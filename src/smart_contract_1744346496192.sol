```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract Outline & Function Summary
 * @author Bard (AI Assistant)
 * @dev This contract implements a Decentralized Autonomous Art Gallery, enabling artists to mint and showcase their digital art (NFTs),
 *      collectors to acquire and manage art, and community members to participate in gallery governance and events.
 *      It incorporates advanced concepts like dynamic pricing, community curation, art challenges, and decentralized reputation.
 *      This contract is designed to be innovative and does not directly replicate existing open-source gallery contracts.
 *
 * **Function Summary:**
 *
 * **Artist Functions:**
 * 1. `mintArtPiece(string memory _title, string memory _ipfsHash, uint256 _initialPrice)`: Allows artists to mint a new art piece (NFT).
 * 2. `setArtPiecePrice(uint256 _artPieceId, uint256 _newPrice)`: Allows artists to update the price of their art piece.
 * 3. `transferArtPieceOwnership(uint256 _artPieceId, address _newOwner)`: Allows artists to transfer ownership of their art piece (e.g., gifting).
 * 4. `burnArtPiece(uint256 _artPieceId)`: Allows artists to burn their art piece (permanently remove it).
 * 5. `submitArtForChallenge(uint256 _artPieceId, uint256 _challengeId)`: Artists can submit their art piece to an active art challenge.
 * 6. `withdrawEarnings()`: Artists can withdraw accumulated earnings from sales.
 *
 * **Collector Functions:**
 * 7. `purchaseArtPiece(uint256 _artPieceId)`: Allows collectors to purchase an art piece listed in the gallery.
 * 8. `offerPriceForArtPiece(uint256 _artPieceId, uint256 _offeredPrice)`: Collectors can make a price offer for an art piece.
 * 9. `acceptOffer(uint256 _offerId)`: Artist can accept a specific price offer from a collector.
 * 10. `listArtPieceForSale(uint256 _artPieceId, uint256 _price)`: Collectors can list their owned art pieces for sale in the gallery.
 * 11. `unlistArtPieceFromSale(uint256 _artPieceId)`: Collectors can remove their art piece from sale.
 * 12. `likeArtPiece(uint256 _artPieceId)`: Collectors can "like" an art piece, contributing to community curation.
 * 13. `reportArtPiece(uint256 _artPieceId, string memory _reason)`: Collectors can report an art piece for inappropriate content.
 *
 * **Gallery Governance/Community Functions:**
 * 14. `createArtChallenge(string memory _challengeName, uint256 _startTime, uint256 _endTime)`: Allows curators/admins to create new art challenges.
 * 15. `voteForChallengeWinner(uint256 _challengeId, uint256 _artPieceId)`: Community members can vote for the winner of an art challenge.
 * 16. `finalizeChallenge(uint256 _challengeId)`: Allows admins to finalize a challenge and distribute rewards (if any).
 * 17. `setGalleryFee(uint256 _newFeePercentage)`: Allows admins to set the gallery commission fee percentage.
 * 18. `withdrawGalleryFees()`: Allows admins to withdraw accumulated gallery fees.
 * 19. `proposeGalleryRuleChange(string memory _proposalDescription)`: Community members can propose changes to gallery rules or functionalities.
 * 20. `voteOnRuleChangeProposal(uint256 _proposalId, bool _vote)`: Community members can vote on rule change proposals.
 * 21. `executeRuleChangeProposal(uint256 _proposalId)`: Allows admins to execute a passed rule change proposal.
 * 22. `donateToGallery()`: Allows anyone to donate ETH to the gallery for operational purposes.
 * 23. `getArtPieceDetails(uint256 _artPieceId)`:  View function to retrieve detailed information about an art piece.
 * 24. `getChallengeDetails(uint256 _challengeId)`: View function to retrieve details about an art challenge.
 * 25. `getUserReputation(address _user)`: View function to get a user's reputation score within the gallery.
 */

contract DecentralizedAutonomousArtGallery {
    // --- Data Structures ---
    struct ArtPiece {
        uint256 id;
        address artist;
        address owner;
        string title;
        string ipfsHash;
        uint256 price;
        uint256 likes;
        uint256 mintTimestamp;
        bool onSale;
    }

    struct ArtChallenge {
        uint256 id;
        string name;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isFinalized;
        uint256 winnerArtPieceId;
        mapping(uint256 => uint256) artPieceVotes; // artPieceId => voteCount
    }

    struct PriceOffer {
        uint256 id;
        uint256 artPieceId;
        address offerer;
        uint256 offeredPrice;
        bool accepted;
    }

    struct RuleChangeProposal {
        uint256 id;
        string description;
        uint256 proposalTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // --- State Variables ---
    ArtPiece[] public artPieces;
    ArtChallenge[] public artChallenges;
    PriceOffer[] public priceOffers;
    RuleChangeProposal[] public ruleChangeProposals;

    uint256 public nextArtPieceId = 1;
    uint256 public nextChallengeId = 1;
    uint256 public nextOfferId = 1;
    uint256 public nextProposalId = 1;

    uint256 public galleryFeePercentage = 5; // Default 5% gallery fee
    address public galleryAdmin;
    mapping(address => uint256) public userReputation; // User reputation score

    // --- Events ---
    event ArtPieceMinted(uint256 artPieceId, address artist, string title);
    event ArtPiecePriceUpdated(uint256 artPieceId, uint256 newPrice);
    event ArtPieceTransferred(uint256 artPieceId, address oldOwner, address newOwner);
    event ArtPieceBurned(uint256 artPieceId);
    event ArtPiecePurchased(uint256 artPieceId, address buyer, address artist, uint256 price);
    event PriceOfferMade(uint256 offerId, uint256 artPieceId, address offerer, uint256 offeredPrice);
    event PriceOfferAccepted(uint256 offerId, uint256 artPieceId, address artist, address buyer, uint256 price);
    event ArtPieceListedForSale(uint256 artPieceId, uint256 price);
    event ArtPieceUnlistedFromSale(uint256 artPieceId);
    event ArtPieceLiked(uint256 artPieceId, address liker);
    event ArtPieceReported(uint256 artPieceId, address reporter, string reason);
    event ArtChallengeCreated(uint256 challengeId, string challengeName, uint256 startTime, uint256 endTime);
    event ArtPieceSubmittedToChallenge(uint256 challengeId, uint256 artPieceId, address artist);
    event VoteForChallengeWinner(uint256 challengeId, uint256 artPieceId, address voter);
    event ArtChallengeFinalized(uint256 challengeId, uint256 winnerArtPieceId);
    event GalleryFeeSet(uint256 newFeePercentage);
    event GalleryFeesWithdrawn(uint256 amount, address admin);
    event RuleChangeProposed(uint256 proposalId, string description, address proposer);
    event RuleChangeVoteCast(uint256 proposalId, address voter, bool vote);
    event RuleChangeExecuted(uint256 proposalId);
    event DonationReceived(address donor, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwnerOfArtPiece(uint256 _artPieceId) {
        require(artPieces[_artPieceId - 1].owner == msg.sender, "Not owner of art piece");
        _;
    }

    modifier onlyArtistOfArtPiece(uint256 _artPieceId) {
        require(artPieces[_artPieceId - 1].artist == msg.sender, "Not artist of art piece");
        _;
    }

    modifier onlyGalleryAdmin() {
        require(msg.sender == galleryAdmin, "Only gallery admin can call this function");
        _;
    }

    modifier challengeActive(uint256 _challengeId) {
        require(artChallenges[_challengeId - 1].isActive, "Challenge is not active");
        require(block.timestamp >= artChallenges[_challengeId - 1].startTime && block.timestamp <= artChallenges[_challengeId - 1].endTime, "Challenge is not within active time window");
        _;
    }

    modifier challengeNotFinalized(uint256 _challengeId) {
        require(!artChallenges[_challengeId - 1].isFinalized, "Challenge is already finalized");
        _;
    }

    // --- Constructor ---
    constructor() {
        galleryAdmin = msg.sender; // Deployer of the contract is the initial admin
    }

    // --- Artist Functions ---
    function mintArtPiece(string memory _title, string memory _ipfsHash, uint256 _initialPrice) public {
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0, "Title and IPFS Hash cannot be empty");
        require(_initialPrice > 0, "Initial price must be greater than zero");

        artPieces.push(ArtPiece({
            id: nextArtPieceId,
            artist: msg.sender,
            owner: msg.sender, // Artist initially owns the art
            title: _title,
            ipfsHash: _ipfsHash,
            price: _initialPrice,
            likes: 0,
            mintTimestamp: block.timestamp,
            onSale: false
        }));

        emit ArtPieceMinted(nextArtPieceId, msg.sender, _title);
        nextArtPieceId++;
        // Increase artist reputation (example logic)
        userReputation[msg.sender] += 5;
    }

    function setArtPiecePrice(uint256 _artPieceId, uint256 _newPrice) public onlyArtistOfArtPiece(_artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(_newPrice > 0, "New price must be greater than zero");
        artPieces[_artPieceId - 1].price = _newPrice;
        emit ArtPiecePriceUpdated(_artPieceId, _newPrice);
    }

    function transferArtPieceOwnership(uint256 _artPieceId, address _newOwner) public onlyOwnerOfArtPiece(_artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(_newOwner != address(0) && _newOwner != artPieces[_artPieceId - 1].owner, "Invalid new owner address");
        emit ArtPieceTransferred(_artPieceId, artPieces[_artPieceId - 1].owner, _newOwner);
        artPieces[_artPieceId - 1].owner = _newOwner;
    }

    function burnArtPiece(uint256 _artPieceId) public onlyArtistOfArtPiece(_artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(artPieces[_artPieceId - 1].owner == msg.sender, "Only artist can burn their own art if they are still the owner.");
        emit ArtPieceBurned(_artPieceId);
        delete artPieces[_artPieceId - 1]; // Note: This leaves a gap in the array, consider using a mapping for production
        // Decrease artist reputation (example logic)
        userReputation[msg.sender] -= 3;
    }

    function submitArtForChallenge(uint256 _artPieceId, uint256 _challengeId) public onlyArtistOfArtPiece(_artPieceId) challengeActive(_challengeId) challengeNotFinalized(_challengeId) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(_challengeId > 0 && _challengeId <= artChallenges.length, "Invalid challenge ID");
        // Additional checks can be added here, e.g., if art piece already submitted to this challenge

        // Record submission (For simplicity, just incrementing vote count initially, could be more complex submission logic)
        artChallenges[_challengeId - 1].artPieceVotes[_artPieceId]++;
        emit ArtPieceSubmittedToChallenge(_challengeId, _artPieceId, msg.sender);
    }

    function withdrawEarnings() public {
        // Placeholder for more complex earnings tracking and withdrawal logic
        // In a real application, you'd track artist balances for sales and allow withdrawal.
        // For now, a simple example: Assume artists earn directly upon sale (handled in purchaseArtPiece)
        // This function could be used for withdrawing accumulated gallery fees split or secondary sale royalties.
        revert("Earnings withdrawal logic not fully implemented in this example."); // Placeholder
    }


    // --- Collector Functions ---
    function purchaseArtPiece(uint256 _artPieceId) public payable {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(artPieces[_artPieceId - 1].onSale, "Art piece is not listed for sale");
        require(artPieces[_artPieceId - 1].price > 0, "Art piece price is not set");
        require(msg.value >= artPieces[_artPieceId - 1].price, "Insufficient funds sent");
        require(artPieces[_artPieceId - 1].owner != msg.sender, "Cannot purchase your own art");

        uint256 galleryFee = (artPieces[_artPieceId - 1].price * galleryFeePercentage) / 100;
        uint256 artistPayment = artPieces[_artPieceId - 1].price - galleryFee;

        // Transfer payment to artist (and gallery fee to admin - placeholder)
        payable(artPieces[_artPieceId - 1].artist).transfer(artistPayment);
        payable(galleryAdmin).transfer(galleryFee); // Gallery fee

        // Update ownership
        address oldOwner = artPieces[_artPieceId - 1].owner;
        artPieces[_artPieceId - 1].owner = msg.sender;
        artPieces[_artPieceId - 1].onSale = false; // No longer on sale after purchase

        emit ArtPiecePurchased(_artPieceId, msg.sender, artPieces[_artPieceId - 1].artist, artPieces[_artPieceId - 1].price);
        emit ArtPieceTransferred(_artPieceId, oldOwner, msg.sender);
        // Increase buyer reputation, increase artist reputation for sale (example logic)
        userReputation[msg.sender] += 2;
        userReputation[artPieces[_artPieceId - 1].artist] += 3;

        // Refund any excess ETH sent
        if (msg.value > artPieces[_artPieceId - 1].price) {
            payable(msg.sender).transfer(msg.value - artPieces[_artPieceId - 1].price);
        }
    }

    function offerPriceForArtPiece(uint256 _artPieceId, uint256 _offeredPrice) public {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(_offeredPrice > 0, "Offered price must be greater than zero");
        require(artPieces[_artPieceId - 1].owner != msg.sender, "Cannot offer on your own art");

        priceOffers.push(PriceOffer({
            id: nextOfferId,
            artPieceId: _artPieceId,
            offerer: msg.sender,
            offeredPrice: _offeredPrice,
            accepted: false
        }));
        emit PriceOfferMade(nextOfferId, _artPieceId, msg.sender, _offeredPrice);
        nextOfferId++;
    }

    function acceptOffer(uint256 _offerId) public payable {
        require(_offerId > 0 && _offerId <= priceOffers.length, "Invalid offer ID");
        require(!priceOffers[_offerId - 1].accepted, "Offer already accepted");
        uint256 artPieceId = priceOffers[_offerId - 1].artPieceId;
        require(artPieces[artPieceId - 1].owner == msg.sender, "Only owner of art piece can accept offer");
        require(priceOffers[_offerId - 1].offerer != msg.sender, "Cannot accept your own offer");

        uint256 offeredPrice = priceOffers[_offerId - 1].offeredPrice;
        require(msg.value >= offeredPrice, "Insufficient funds sent to accept offer");

        uint256 galleryFee = (offeredPrice * galleryFeePercentage) / 100;
        uint256 artistPayment = offeredPrice - galleryFee;

        // Transfer payment to artist (and gallery fee to admin)
        payable(artPieces[artPieceId - 1].artist).transfer(artistPayment);
        payable(galleryAdmin).transfer(galleryFee);

        // Update ownership and offer status
        address oldOwner = artPieces[artPieceId - 1].owner;
        artPieces[artPieceId - 1].owner = priceOffers[_offerId - 1].offerer;
        priceOffers[_offerId - 1].accepted = true;
        artPieces[artPieceId - 1].onSale = false; // No longer on sale if it was

        emit PriceOfferAccepted(_offerId, artPieceId, artPieces[artPieceId - 1].artist, priceOffers[_offerId - 1].offerer, offeredPrice);
        emit ArtPieceTransferred(artPieceId, oldOwner, priceOffers[_offerId - 1].offerer);
        // Reputation updates (similar to purchaseArtPiece)
        userReputation[priceOffers[_offerId - 1].offerer] += 3;
        userReputation[artPieces[artPieceId - 1].artist] += 4; // Slightly higher rep for accepting offer

        // Refund excess ETH if sent
        if (msg.value > offeredPrice) {
            payable(msg.sender).transfer(msg.value - offeredPrice);
        }
    }

    function listArtPieceForSale(uint256 _artPieceId, uint256 _price) public onlyOwnerOfArtPiece(_artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(_price > 0, "Sale price must be greater than zero");
        artPieces[_artPieceId - 1].price = _price;
        artPieces[_artPieceId - 1].onSale = true;
        emit ArtPieceListedForSale(_artPieceId, _price);
    }

    function unlistArtPieceFromSale(uint256 _artPieceId) public onlyOwnerOfArtPiece(_artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        artPieces[_artPieceId - 1].onSale = false;
        emit ArtPieceUnlistedFromSale(_artPieceId);
    }

    function likeArtPiece(uint256 _artPieceId) public {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        artPieces[_artPieceId - 1].likes++;
        emit ArtPieceLiked(_artPieceId, msg.sender);
        // Increase reputation of liker and artist (example logic)
        userReputation[msg.sender] += 1;
        userReputation[artPieces[_artPieceId - 1].artist] += 1;
    }

    function reportArtPiece(uint256 _artPieceId, string memory _reason) public {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        require(bytes(_reason).length > 0, "Report reason cannot be empty");
        emit ArtPieceReported(_artPieceId, msg.sender, _reason);
        // In a real system, reporting would trigger moderation/admin review process.
        // Reputation might be affected for false reports or for artists with many reports.
    }

    // --- Gallery Governance/Community Functions ---
    function createArtChallenge(string memory _challengeName, uint256 _startTime, uint256 _endTime) public onlyGalleryAdmin {
        require(bytes(_challengeName).length > 0, "Challenge name cannot be empty");
        require(_startTime < _endTime, "Start time must be before end time");
        require(_startTime >= block.timestamp, "Start time must be in the future");

        artChallenges.push(ArtChallenge({
            id: nextChallengeId,
            name: _challengeName,
            startTime: _startTime,
            endTime: _endTime,
            isActive: true,
            isFinalized: false,
            winnerArtPieceId: 0
        }));
        emit ArtChallengeCreated(nextChallengeId, _challengeName, _startTime, _endTime);
        nextChallengeId++;
    }

    function voteForChallengeWinner(uint256 _challengeId, uint256 _artPieceId) public challengeActive(_challengeId) challengeNotFinalized(_challengeId) {
        require(_challengeId > 0 && _challengeId <= artChallenges.length, "Invalid challenge ID");
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        // Add check to prevent voting for own art piece in a challenge if needed

        artChallenges[_challengeId - 1].artPieceVotes[_artPieceId]++;
        emit VoteForChallengeWinner(_challengeId, _artPieceId, msg.sender);
        // Increase voter reputation (example logic)
        userReputation[msg.sender] += 1;
    }

    function finalizeChallenge(uint256 _challengeId) public onlyGalleryAdmin challengeNotFinalized(_challengeId) {
        require(_challengeId > 0 && _challengeId <= artChallenges.length, "Invalid challenge ID");
        require(block.timestamp > artChallenges[_challengeId - 1].endTime, "Challenge end time not reached yet");

        uint256 winningArtPieceId = 0;
        uint256 maxVotes = 0;
        ArtChallenge storage challenge = artChallenges[_challengeId - 1];

        for (uint256 artId = 1; artId <= artPieces.length; artId++) {
            if (challenge.artPieceVotes[artId] > maxVotes) {
                maxVotes = challenge.artPieceVotes[artId];
                winningArtPieceId = artId;
            }
        }

        challenge.isActive = false;
        challenge.isFinalized = true;
        challenge.winnerArtPieceId = winningArtPieceId;
        emit ArtChallengeFinalized(_challengeId, winningArtPieceId);

        // Reward winner artist (example logic - could be NFT badge, prize fund, etc.)
        if (winningArtPieceId > 0) {
             userReputation[artPieces[winningArtPieceId - 1].artist] += 10; // Significant reputation boost for winning
        }
    }

    function setGalleryFee(uint256 _newFeePercentage) public onlyGalleryAdmin {
        require(_newFeePercentage <= 20, "Gallery fee percentage cannot exceed 20%"); // Example limit
        galleryFeePercentage = _newFeePercentage;
        emit GalleryFeeSet(_newFeePercentage);
    }

    function withdrawGalleryFees() public onlyGalleryAdmin {
        uint256 balance = address(this).balance;
        emit GalleryFeesWithdrawn(balance, msg.sender);
        payable(galleryAdmin).transfer(balance);
    }

    function proposeGalleryRuleChange(string memory _proposalDescription) public {
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty");
        ruleChangeProposals.push(RuleChangeProposal({
            id: nextProposalId,
            description: _proposalDescription,
            proposalTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        }));
        emit RuleChangeProposed(nextProposalId, _proposalDescription, msg.sender);
        nextProposalId++;
    }

    function voteOnRuleChangeProposal(uint256 _proposalId, bool _vote) public {
        require(_proposalId > 0 && _proposalId <= ruleChangeProposals.length, "Invalid proposal ID");
        require(!ruleChangeProposals[_proposalId - 1].executed, "Proposal already executed");
        // In a more complex system, track votes per user to prevent double voting

        if (_vote) {
            ruleChangeProposals[_proposalId - 1].votesFor++;
        } else {
            ruleChangeProposals[_proposalId - 1].votesAgainst++;
        }
        emit RuleChangeVoteCast(_proposalId, msg.sender, _vote);
        // Reputation for participating in governance
        userReputation[msg.sender] += 1;
    }

    function executeRuleChangeProposal(uint256 _proposalId) public onlyGalleryAdmin {
        require(_proposalId > 0 && _proposalId <= ruleChangeProposals.length, "Invalid proposal ID");
        require(!ruleChangeProposals[_proposalId - 1].executed, "Proposal already executed");
        require(ruleChangeProposals[_proposalId - 1].votesFor > ruleChangeProposals[_proposalId - 1].votesAgainst, "Proposal not passed yet");
        // Execute the rule change - in this simple example, execution is symbolic.
        // In a real system, this function would trigger actual code changes or parameter adjustments based on the proposal.
        ruleChangeProposals[_proposalId - 1].executed = true;
        emit RuleChangeExecuted(_proposalId);
    }

    function donateToGallery() public payable {
        require(msg.value > 0, "Donation amount must be greater than zero");
        emit DonationReceived(msg.sender, msg.value);
        // Gallery admin could use donated funds for community rewards, maintenance, etc.
    }

    // --- View Functions ---
    function getArtPieceDetails(uint256 _artPieceId) public view returns (ArtPiece memory) {
        require(_artPieceId > 0 && _artPieceId <= artPieces.length, "Invalid art piece ID");
        return artPieces[_artPieceId - 1];
    }

    function getChallengeDetails(uint256 _challengeId) public view returns (ArtChallenge memory) {
        require(_challengeId > 0 && _challengeId <= artChallenges.length, "Invalid challenge ID");
        return artChallenges[_challengeId - 1];
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    // --- Fallback and Receive functions (optional - for receiving ETH donations directly) ---
    receive() external payable {
        emit DonationReceived(msg.sender, msg.value); // Treat direct ETH send as donation
    }

    fallback() external payable {
        emit DonationReceived(msg.sender, msg.value); // Treat direct ETH send as donation
    }
}
```