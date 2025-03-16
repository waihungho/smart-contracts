```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *
 * Outline & Function Summary:
 *
 * 1.  **Membership Management:**
 *     - registerArtist(): Allows users to register as artists in the collective.
 *     - registerCollector(): Allows users to register as collectors to support artists.
 *     - grantAdminRole(address _user): Grants admin role to a user (admin-only).
 *     - revokeAdminRole(address _user): Revokes admin role from a user (admin-only).
 *     - isArtist(address _user): Checks if an address is a registered artist.
 *     - isCollector(address _user): Checks if an address is a registered collector.
 *     - isAdmin(address _user): Checks if an address has admin role.
 *
 * 2.  **Art Submission & Curation:**
 *     - submitArtwork(string memory _artworkCID, string memory _metadataCID): Artists submit artwork with content and metadata CIDs.
 *     - upvoteArtwork(uint256 _artworkId): Collectors can upvote submitted artworks.
 *     - downvoteArtwork(uint256 _artworkId): Collectors can downvote submitted artworks.
 *     - curateArtwork(uint256 _artworkId): Admin curates an artwork based on community votes (admin-only).
 *     - rejectArtwork(uint256 _artworkId): Admin can reject an artwork (admin-only).
 *     - getArtworkDetails(uint256 _artworkId): Retrieves details of a specific artwork.
 *     - getCuratedArtworkIds(): Returns a list of IDs of curated artworks.
 *     - getPendingArtworkIds(): Returns a list of IDs of pending artworks.
 *
 * 3.  **NFT Minting & Marketplace (Basic):**
 *     - mintArtworkNFT(uint256 _artworkId): Mints an NFT for a curated artwork (artist-only for their artwork).
 *     - setArtworkPrice(uint256 _artworkId, uint256 _price): Artist sets the price for their curated artwork NFT (artist-only for their artwork).
 *     - buyArtworkNFT(uint256 _artworkId): Allows collectors to buy curated artwork NFTs.
 *     - withdrawArtistEarnings(): Artists can withdraw their earnings from NFT sales.
 *
 * 4.  **Collective Treasury & Governance (Simple):**
 *     - contributeToTreasury(): Allows anyone to contribute ETH to the collective treasury.
 *     - requestTreasuryFunding(string memory _proposalDescription, uint256 _amount): Artists can request funding from the treasury for art projects.
 *     - voteOnFundingProposal(uint256 _proposalId, bool _approve): Members (Artists & Collectors) can vote on funding proposals.
 *     - executeFundingProposal(uint256 _proposalId): Admin executes approved funding proposals (admin-only).
 *     - getTreasuryBalance(): Returns the current balance of the collective treasury.
 *     - getFundingProposalDetails(uint256 _proposalId): Retrieves details of a funding proposal.
 *
 * 5.  **Reputation & Incentives (Conceptual - can be expanded):**
 *     - rewardActiveCollector(address _collector, string memory _reason): Admin can reward active collectors (conceptual reputation system).
 *     - getCollectorReputation(address _collector): Returns conceptual collector reputation (placeholder - could be more complex).
 */
contract DecentralizedArtCollective {

    // -------- State Variables --------

    address public admin; // Contract admin address
    uint256 public artworkCount;
    uint256 public proposalCount;

    mapping(address => bool) public isRegisteredArtist;
    mapping(address => bool) public isRegisteredCollector;
    mapping(address => bool) public isAdminRole;

    struct Artwork {
        uint256 id;
        address artist;
        string artworkCID;       // Content Identifier for the artwork (e.g., IPFS CID)
        string metadataCID;      // Content Identifier for artwork metadata
        uint256 upvotes;
        uint256 downvotes;
        bool isCurated;
        bool isRejected;
        bool isMinted;
        uint256 price;         // Price in wei for the NFT
    }
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => mapping(address => bool)) public hasVotedArtwork; // artworkId => voter => voted

    struct FundingProposal {
        uint256 id;
        address proposer;        // Artist who proposed the funding
        string description;
        uint256 requestedAmount;
        uint256 upvotes;
        uint256 downvotes;
        bool isExecuted;
    }
    mapping(uint256 => FundingProposal) public fundingProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedProposal; // proposalId => voter => voted

    mapping(address => uint256) public artistEarnings; // Artist address => earnings

    // -------- Events --------

    event ArtistRegistered(address artistAddress);
    event CollectorRegistered(address collectorAddress);
    event AdminRoleGranted(address adminAddress, address grantedTo);
    event AdminRoleRevoked(address adminAddress, address revokedFrom);
    event ArtworkSubmitted(uint256 artworkId, address artist, string artworkCID, string metadataCID);
    event ArtworkUpvoted(uint256 artworkId, address voter);
    event ArtworkDownvoted(uint256 artworkId, address voter);
    event ArtworkCurated(uint256 artworkId);
    event ArtworkRejected(uint256 artworkId);
    event ArtworkNFTMinted(uint256 artworkId, address artist, uint256 price);
    event ArtworkNFTSold(uint256 artworkId, address buyer, uint256 price);
    event TreasuryContribution(address contributor, uint256 amount);
    event FundingProposalCreated(uint256 proposalId, address proposer, string description, uint256 amount);
    event FundingProposalVoted(uint256 proposalId, address voter, bool approved);
    event FundingProposalExecuted(uint256 proposalId, address executor);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event CollectorRewarded(address collector, string reason);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin can perform this action");
        _;
    }

    modifier onlyArtist() {
        require(isArtist(msg.sender), "Only registered artists can perform this action");
        _;
    }

    modifier onlyCollector() {
        require(isCollector(msg.sender), "Only registered collectors can perform this action");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Artwork does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        _;
    }

    modifier notAlreadyVotedArtwork(uint256 _artworkId) {
        require(!hasVotedArtwork[_artworkId][msg.sender], "Already voted on this artwork");
        _;
    }

    modifier notAlreadyVotedProposal(uint256 _proposalId) {
        require(!hasVotedProposal[_proposalId][msg.sender], "Already voted on this proposal");
        _;
    }

    modifier isArtworkArtist(uint256 _artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "You are not the artist of this artwork");
        _;
    }

    modifier isArtworkCurated(uint256 _artworkId) {
        require(artworks[_artworkId].isCurated, "Artwork is not yet curated");
        _;
    }

    modifier isArtworkNotMinted(uint256 _artworkId) {
        require(!artworks[_artworkId].isMinted, "Artwork NFT already minted");
        _;
    }

    modifier isFundingProposalNotExecuted(uint256 _proposalId) {
        require(!fundingProposals[_proposalId].isExecuted, "Funding proposal already executed");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        isAdminRole[admin] = true; // Creator of the contract is the initial admin
        artworkCount = 0;
        proposalCount = 0;
    }

    // -------- 1. Membership Management --------

    function registerArtist() public {
        require(!isRegisteredArtist[msg.sender], "Already registered as an artist");
        isRegisteredArtist[msg.sender] = true;
        emit ArtistRegistered(msg.sender);
    }

    function registerCollector() public {
        require(!isRegisteredCollector[msg.sender], "Already registered as a collector");
        isRegisteredCollector[msg.sender] = true;
        emit CollectorRegistered(msg.sender);
    }

    function grantAdminRole(address _user) public onlyAdmin {
        isAdminRole[_user] = true;
        emit AdminRoleGranted(admin, _user);
    }

    function revokeAdminRole(address _user) public onlyAdmin {
        require(_user != admin, "Cannot revoke admin role from the contract creator"); // Prevent removing initial admin accidentally
        isAdminRole[_user] = false;
        emit AdminRoleRevoked(admin, _user);
    }

    function isArtist(address _user) public view returns (bool) {
        return isRegisteredArtist[_user];
    }

    function isCollector(address _user) public view returns (bool) {
        return isRegisteredCollector[_user];
    }

    function isAdmin(address _user) public view returns (bool) {
        return isAdminRole[_user];
    }

    // -------- 2. Art Submission & Curation --------

    function submitArtwork(string memory _artworkCID, string memory _metadataCID) public onlyArtist {
        artworkCount++;
        artworks[artworkCount] = Artwork({
            id: artworkCount,
            artist: msg.sender,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            upvotes: 0,
            downvotes: 0,
            isCurated: false,
            isRejected: false,
            isMinted: false,
            price: 0
        });
        emit ArtworkSubmitted(artworkCount, msg.sender, _artworkCID, _metadataCID);
    }

    function upvoteArtwork(uint256 _artworkId) public onlyCollector artworkExists(_artworkId) notAlreadyVotedArtwork(_artworkId) {
        require(!artworks[_artworkId].isCurated && !artworks[_artworkId].isRejected, "Artwork is already processed");
        artworks[_artworkId].upvotes++;
        hasVotedArtwork[_artworkId][msg.sender] = true;
        emit ArtworkUpvoted(_artworkId, msg.sender);
    }

    function downvoteArtwork(uint256 _artworkId) public onlyCollector artworkExists(_artworkId) notAlreadyVotedArtwork(_artworkId) {
        require(!artworks[_artworkId].isCurated && !artworks[_artworkId].isRejected, "Artwork is already processed");
        artworks[_artworkId].downvotes++;
        hasVotedArtwork[_artworkId][msg.sender] = true;
        emit ArtworkDownvoted(_artworkId, msg.sender);
    }

    function curateArtwork(uint256 _artworkId) public onlyAdmin artworkExists(_artworkId) {
        require(!artworks[_artworkId].isCurated && !artworks[_artworkId].isRejected, "Artwork is already processed");
        artworks[_artworkId].isCurated = true;
        emit ArtworkCurated(_artworkId);
    }

    function rejectArtwork(uint256 _artworkId) public onlyAdmin artworkExists(_artworkId) {
        require(!artworks[_artworkId].isCurated && !artworks[_artworkId].isRejected, "Artwork is already processed");
        artworks[_artworkId].isRejected = true;
        emit ArtworkRejected(_artworkId);
    }

    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getCuratedArtworkIds() public view returns (uint256[] memory) {
        uint256[] memory curatedIds = new uint256[](artworkCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworks[i].isCurated) {
                curatedIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of curated artworks
        assembly {
            mstore(curatedIds, count) // Update the length of the array
        }
        return curatedIds;
    }

    function getPendingArtworkIds() public view returns (uint256[] memory) {
        uint256[] memory pendingIds = new uint256[](artworkCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (!artworks[i].isCurated && !artworks[i].isRejected) {
                pendingIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of pending artworks
        assembly {
            mstore(pendingIds, count) // Update the length of the array
        }
        return pendingIds;
    }

    // -------- 3. NFT Minting & Marketplace (Basic) --------

    function mintArtworkNFT(uint256 _artworkId) public onlyArtist artworkExists(_artworkId) isArtworkArtist(_artworkId) isArtworkCurated(_artworkId) isArtworkNotMinted(_artworkId) {
        artworks[_artworkId].isMinted = true;
        emit ArtworkNFTMinted(_artworkId, msg.sender, artworks[_artworkId].price);
        // In a real NFT implementation, you would mint an actual NFT here.
        // This is a simplified example; you'd typically integrate with an ERC721/ERC1155 contract.
        // For simplicity, we're just marking it as minted and setting a price.
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _price) public onlyArtist artworkExists(_artworkId) isArtworkArtist(_artworkId) isArtworkCurated(_artworkId) {
        require(artworks[_artworkId].price == 0, "Price already set, cannot change in this version (can be extended)"); // Simple restriction
        artworks[_artworkId].price = _price;
    }

    function buyArtworkNFT(uint256 _artworkId) public payable onlyCollector artworkExists(_artworkId) isArtworkCurated(_artworkId) {
        require(artworks[_artworkId].isMinted, "NFT not yet minted");
        require(artworks[_artworkId].price > 0, "NFT price not set");
        require(msg.value >= artworks[_artworkId].price, "Insufficient funds sent");

        address artist = artworks[_artworkId].artist;
        uint256 price = artworks[_artworkId].price;

        artistEarnings[artist] += price; // Credit artist earnings
        payable(artist).transfer(price); // Direct transfer for simplicity (consider more robust methods in production)

        emit ArtworkNFTSold(_artworkId, msg.sender, price);
    }

    function withdrawArtistEarnings() public onlyArtist {
        uint256 earnings = artistEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw");
        artistEarnings[msg.sender] = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(msg.sender, earnings);
    }

    // -------- 4. Collective Treasury & Governance (Simple) --------

    function contributeToTreasury() public payable {
        emit TreasuryContribution(msg.sender, msg.value);
    }

    function requestTreasuryFunding(string memory _proposalDescription, uint256 _amount) public onlyArtist {
        proposalCount++;
        fundingProposals[proposalCount] = FundingProposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _proposalDescription,
            requestedAmount: _amount,
            upvotes: 0,
            downvotes: 0,
            isExecuted: false
        });
        emit FundingProposalCreated(proposalCount, msg.sender, _proposalDescription, _amount);
    }

    function voteOnFundingProposal(uint256 _proposalId, bool _approve) public proposalExists(_proposalId) notAlreadyVotedProposal(_proposalId) {
        require(!fundingProposals[_proposalId].isExecuted, "Proposal already executed");
        require(isRegisteredArtist[msg.sender] || isRegisteredCollector[msg.sender], "Only registered members can vote");

        if (_approve) {
            fundingProposals[_proposalId].upvotes++;
        } else {
            fundingProposals[_proposalId].downvotes++;
        }
        hasVotedProposal[_proposalId][msg.sender] = true;
        emit FundingProposalVoted(_proposalId, msg.sender, _approve);
    }

    function executeFundingProposal(uint256 _proposalId) public onlyAdmin proposalExists(_proposalId) isFundingProposalNotExecuted(_proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.upvotes > proposal.downvotes, "Proposal not approved by majority"); // Simple majority for example
        require(address(this).balance >= proposal.requestedAmount, "Insufficient treasury funds");

        proposal.isExecuted = true;
        payable(proposal.proposer).transfer(proposal.requestedAmount);
        emit FundingProposalExecuted(_proposalId, msg.sender);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getFundingProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (FundingProposal memory) {
        return fundingProposals[_proposalId];
    }

    // -------- 5. Reputation & Incentives (Conceptual) --------

    uint256 public collectorReputationPoints = 100; // Example base points

    function rewardActiveCollector(address _collector, string memory _reason) public onlyAdmin onlyCollector() {
        // This is a very basic example. A real reputation system would be much more complex.
        // For instance, track reputation points per collector, with different reward tiers, etc.
        // For this example, just emit an event.
        emit CollectorRewarded(_collector, _reason);
    }

    function getCollectorReputation(address _collector) public view onlyCollector() returns (uint256) {
        // Placeholder - in a real system, this would calculate reputation based on various factors
        // like voting participation, artwork purchases, community contributions, etc.
        // For now, it just returns a fixed base point.
        return collectorReputationPoints;
    }

    // -------- Fallback & Receive --------
    receive() external payable {
        emit TreasuryContribution(msg.sender, msg.value); // Allow direct ETH contributions to treasury
    }

    fallback() external {} // Optional fallback function
}
```