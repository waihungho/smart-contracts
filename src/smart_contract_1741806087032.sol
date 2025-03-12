```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Conceptual Contract)
 * @dev A smart contract for a decentralized art collective, enabling collaborative art creation,
 * curation, fractional ownership, dynamic NFTs, and community governance.
 *
 * **Contract Outline:**
 * 1. **Membership & Governance:**
 *    - Join/Leave Collective, Propose/Vote on Proposals, Reputation System
 * 2. **Art Submission & Curation:**
 *    - Submit Artwork Proposals, Community Voting on Submissions, Curation by Experts
 * 3. **NFT Minting & Management:**
 *    - Mint NFTs for Approved Artworks, Set Metadata, Fractionalization, Dynamic NFT Features
 * 4. **Collaborative Art Creation:**
 *    - On-chain Collaborative Canvases, Shared Ownership of Collaborative Pieces
 * 5. **Exhibitions & Galleries:**
 *    - Create Virtual Exhibitions, Curate Galleries, Auction/Sale Features
 * 6. **Treasury & Revenue Sharing:**
 *    - Collective Treasury Management, Revenue Distribution from Sales/Auctions, Artist Rewards
 * 7. **Dynamic NFT Features:**
 *    - Evolving Art based on Community Interaction, Rarity based on Votes, On-chain Generative Art Integration
 * 8. **Community Interaction & Social Features:**
 *    - On-chain Forum/Discussion, Bounties for Art-Related Tasks, Community Challenges
 * 9. **Advanced Features:**
 *    - AI-Assisted Curation (Conceptual), Cross-Chain Art Bridges (Conceptual), On-chain Art Storage (Conceptual)
 *
 * **Function Summary:**
 * 1. `joinCollective()`: Allows users to request membership in the art collective.
 * 2. `leaveCollective()`: Allows members to leave the collective.
 * 3. `proposeNewMember(address _newMember)`: Members can propose new addresses to join the collective.
 * 4. `voteOnMembershipProposal(uint _proposalId, bool _vote)`: Members can vote on pending membership proposals.
 * 5. `submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Members submit artwork proposals with metadata and IPFS link.
 * 6. `voteOnArtworkProposal(uint _proposalId, bool _vote)`: Members vote on submitted artwork proposals.
 * 7. `curateArtwork(uint _artworkId)`: Designated curators can manually curate and approve artworks.
 * 8. `mintArtworkNFT(uint _artworkId)`: Mints an NFT for an approved artwork, only callable after curation.
 * 9. `setArtworkMetadata(uint _artworkId, string memory _newMetadata)`: Allows the artist to update artwork metadata (within limits).
 * 10. `fractionalizeNFT(uint _artworkId, uint _numberOfFractions)`: Allows fractionalizing an artwork NFT for shared ownership.
 * 11. `buyFraction(uint _artworkId, uint _fractionAmount)`: Allows users to buy fractions of a fractionalized NFT.
 * 12. `startCollaborativeCanvas(string memory _canvasName, string memory _initialState)`: Initiates a collaborative on-chain canvas.
 * 13. `contributeToCanvas(uint _canvasId, string memory _contributionData)`: Members can contribute data to an ongoing collaborative canvas.
 * 14. `createExhibition(string memory _exhibitionName, string memory _description)`: Creates a virtual art exhibition.
 * 15. `addArtworkToExhibition(uint _exhibitionId, uint _artworkId)`: Adds approved artworks to an exhibition.
 * 16. `startExhibition(uint _exhibitionId)`: Starts a created exhibition, making it publicly viewable.
 * 17. `purchaseArtworkFromExhibition(uint _exhibitionId, uint _artworkId)`: Allows users to purchase artworks listed in an exhibition (if for sale).
 * 18. `depositToTreasury()`: Allows collective members to deposit funds into the collective treasury.
 * 19. `proposeTreasurySpending(address _recipient, uint _amount, string memory _reason)`: Members can propose spending from the collective treasury.
 * 20. `voteOnTreasurySpending(uint _proposalId, bool _vote)`: Members vote on treasury spending proposals.
 * 21. `distributeExhibitionRevenue(uint _exhibitionId)`: Distributes revenue generated from an exhibition to artists and the collective.
 * 22. `awardReputation(address _member, uint _reputationPoints, string memory _reason)`: Admins can award reputation points to members for contributions.
 * 23. `redeemReputationForBenefit(uint _reputationPoints)`: Members can redeem reputation points for certain benefits (e.g., early access, voting power boost).
 * 24. `createCommunityChallenge(string memory _challengeTitle, string memory _description, uint _rewardAmount)`: Admins can create community art challenges with rewards.
 * 25. `submitChallengeEntry(uint _challengeId, uint _artworkId)`: Members can submit existing artworks as entries for a community challenge.
 */

contract DecentralizedArtCollective {
    // -------- State Variables --------

    address public admin; // Contract administrator
    mapping(address => bool) public members; // Mapping of members in the collective
    address[] public memberList; // List of members for iteration

    uint public nextMembershipProposalId;
    mapping(uint => MembershipProposal) public membershipProposals;
    struct MembershipProposal {
        address proposer;
        address newMember;
        bool active;
        mapping(address => bool) votes;
        uint voteCount;
        uint deadline;
    }

    uint public nextArtworkProposalId;
    mapping(uint => ArtworkProposal) public artworkProposals;
    struct ArtworkProposal {
        address proposer;
        string title;
        string description;
        string ipfsHash;
        bool approved;
        bool curated;
        bool rejected;
        mapping(address => bool) votes;
        uint voteCount;
        uint deadline;
    }

    uint public nextArtworkId;
    mapping(uint => Artwork) public artworks;
    struct Artwork {
        address artist;
        string title;
        string description;
        string ipfsHash;
        string metadata;
        bool isNFTMinted;
        bool isFractionalized;
        uint fractionsMinted;
    }

    mapping(uint => mapping(address => uint)) public nftFractionsBalances; // artworkId => (owner => balance)

    uint public nextCanvasId;
    mapping(uint => CollaborativeCanvas) public collaborativeCanvases;
    struct CollaborativeCanvas {
        string name;
        address creator;
        string currentState;
        bool isActive;
    }

    uint public nextExhibitionId;
    mapping(uint => Exhibition) public exhibitions;
    struct Exhibition {
        string name;
        string description;
        address curator;
        uint[] artworkIds;
        bool isActive;
        bool isStarted;
        bool isEnded;
    }

    mapping(uint => bool) public artworkInExhibition; // artworkId => exhibitionId (to prevent duplicates in exhibitions)

    uint public treasuryBalance;

    uint public nextTreasuryProposalId;
    mapping(uint => TreasuryProposal) public treasuryProposals;
    struct TreasuryProposal {
        address proposer;
        address recipient;
        uint amount;
        string reason;
        bool approved;
        bool rejected;
        mapping(address => bool) votes;
        uint voteCount;
        uint deadline;
    }

    mapping(address => uint) public memberReputation;

    uint public nextChallengeId;
    mapping(uint => CommunityChallenge) public communityChallenges;
    struct CommunityChallenge {
        string title;
        string description;
        uint rewardAmount;
        bool isActive;
        uint deadline;
    }
    mapping(uint => uint[]) public challengeEntries; // challengeId => array of artworkIds

    uint public membershipFee; // Fee to join the collective (optional)
    uint public artworkProposalFee; // Fee to submit an artwork proposal (optional)
    uint public fractionalizationFee; // Fee to fractionalize an NFT (optional)

    // -------- Events --------
    event MemberJoined(address member);
    event MemberLeft(address member);
    event MembershipProposed(uint proposalId, address proposer, address newMember);
    event MembershipVoteCast(uint proposalId, address voter, bool vote);
    event MembershipProposalExecuted(uint proposalId, address newMember, bool approved);

    event ArtworkProposed(uint proposalId, address proposer, string title);
    event ArtworkVoteCast(uint proposalId, address voter, bool vote);
    event ArtworkCurated(uint artworkId, address curator);
    event ArtworkMinted(uint artworkId, address artist, uint tokenId); // tokenId could be artworkId for simplicity
    event ArtworkFractionalized(uint artworkId, uint numberOfFractions);
    event FractionBought(uint artworkId, address buyer, uint amount);
    event ArtworkMetadataUpdated(uint artworkId, string newMetadata);

    event CanvasStarted(uint canvasId, string canvasName, address creator);
    event CanvasContribution(uint canvasId, address contributor, string contributionData);

    event ExhibitionCreated(uint exhibitionId, string exhibitionName, address curator);
    event ArtworkAddedToExhibition(uint exhibitionId, uint artworkId);
    event ExhibitionStarted(uint exhibitionId);
    event ArtworkPurchasedFromExhibition(uint exhibitionId, uint artworkId, address buyer, uint price);
    event ExhibitionRevenueDistributed(uint exhibitionId, uint totalRevenue);

    event TreasuryDeposit(address depositor, uint amount);
    event TreasurySpendingProposed(uint proposalId, address proposer, address recipient, uint amount, string reason);
    event TreasuryVoteCast(uint proposalId, address voter, bool vote);
    event TreasurySpendingExecuted(uint proposalId, address recipient, uint amount, bool approved);

    event ReputationAwarded(address member, uint reputationPoints, string reason);
    event ReputationRedeemed(address member, uint reputationPoints, string benefit);

    event ChallengeCreated(uint challengeId, string title, address admin, uint rewardAmount);
    event ChallengeEntrySubmitted(uint challengeId, uint artworkId, address submitter);

    // -------- Modifiers --------
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validProposal(uint _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Membership) {
            require(membershipProposals[_proposalId].active, "Membership proposal is not active.");
        } else if (_proposalType == ProposalType.Artwork) {
            require(!artworkProposals[_proposalId].approved && !artworkProposals[_proposalId].rejected, "Artwork proposal is not active.");
        } else if (_proposalType == ProposalType.Treasury) {
            require(!treasuryProposals[_proposalId].approved && !treasuryProposals[_proposalId].rejected, "Treasury proposal is not active.");
        }
        _;
    }

    modifier proposalDeadlineNotReached(uint _proposalId, ProposalType _proposalType) {
        uint deadline;
        if (_proposalType == ProposalType.Membership) {
            deadline = membershipProposals[_proposalId].deadline;
        } else if (_proposalType == ProposalType.Artwork) {
            deadline = artworkProposals[_proposalId].deadline;
        } else if (_proposalType == ProposalType.Treasury) {
            deadline = treasuryProposals[_proposalId].deadline;
        }
        require(block.timestamp < deadline, "Proposal deadline reached.");
        _;
    }

    enum ProposalType { Membership, Artwork, Treasury }

    // -------- Constructor --------
    constructor() {
        admin = msg.sender;
        members[admin] = true; // Admin is automatically a member
        memberList.push(admin);
    }

    // -------- Membership & Governance Functions --------

    function joinCollective() public payable {
        // Optional: Implement membership fee if membershipFee > 0
        // require(msg.value >= membershipFee, "Insufficient membership fee.");
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        memberList.push(msg.sender);
        emit MemberJoined(msg.sender);
    }

    function leaveCollective() public onlyMember {
        require(msg.sender != admin, "Admin cannot leave.");
        delete members[msg.sender];
        // Remove from memberList (less efficient, consider alternative if list iteration is frequent)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberLeft(msg.sender);
    }

    function proposeNewMember(address _newMember) public onlyMember {
        require(!members[_newMember], "Address is already a member.");
        require(_newMember != address(0), "Invalid address.");

        uint proposalId = nextMembershipProposalId++;
        membershipProposals[proposalId] = MembershipProposal({
            proposer: msg.sender,
            newMember: _newMember,
            active: true,
            voteCount: 0,
            deadline: block.timestamp + 7 days // 7 days voting period
        });

        emit MembershipProposed(proposalId, msg.sender, _newMember);
    }

    function voteOnMembershipProposal(uint _proposalId, bool _vote)
        public
        onlyMember
        validProposal(_proposalId, ProposalType.Membership)
        proposalDeadlineNotReached(_proposalId, ProposalType.Membership)
    {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted.");

        proposal.votes[msg.sender] = true;
        if (_vote) {
            proposal.voteCount++;
        }
        emit MembershipVoteCast(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.deadline) {
            _executeMembershipProposal(_proposalId);
        }
    }

    function _executeMembershipProposal(uint _proposalId) private {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        if (!proposal.active) return; // Prevent re-execution

        proposal.active = false; // Deactivate proposal

        uint requiredVotes = (memberList.length / 2) + 1; // Simple majority
        bool approved = proposal.voteCount >= requiredVotes;

        if (approved) {
            members[proposal.newMember] = true;
            memberList.push(proposal.newMember);
            emit MemberJoined(proposal.newMember);
        }
        emit MembershipProposalExecuted(_proposalId, proposal.newMember, approved);
    }


    // -------- Artwork Submission & Curation Functions --------

    function submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember payable {
        // Optional: Implement artwork proposal fee if artworkProposalFee > 0
        // require(msg.value >= artworkProposalFee, "Insufficient artwork proposal fee.");
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0, "Title and IPFS Hash are required.");

        uint proposalId = nextArtworkProposalId++;
        artworkProposals[proposalId] = ArtworkProposal({
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            approved: false,
            curated: false,
            rejected: false,
            voteCount: 0,
            deadline: block.timestamp + 7 days // 7 days voting period
        });

        emit ArtworkProposed(proposalId, msg.sender, _title);
    }

    function voteOnArtworkProposal(uint _proposalId, bool _vote)
        public
        onlyMember
        validProposal(_proposalId, ProposalType.Artwork)
        proposalDeadlineNotReached(_proposalId, ProposalType.Artwork)
    {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted.");

        proposal.votes[msg.sender] = true;
        if (_vote) {
            proposal.voteCount++;
        }
        emit ArtworkVoteCast(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.deadline) {
            _executeArtworkProposal(_proposalId);
        }
    }

    function _executeArtworkProposal(uint _proposalId) private {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        if (proposal.approved || proposal.rejected) return; // Prevent re-execution

        uint requiredVotes = (memberList.length / 2) + 1; // Simple majority
        bool approved = proposal.voteCount >= requiredVotes;

        if (approved) {
            proposal.approved = true;
        } else {
            proposal.rejected = true; // Explicitly reject if not enough votes
        }
    }

    function curateArtwork(uint _artworkProposalId) public onlyAdmin {
        ArtworkProposal storage proposal = artworkProposals[_artworkProposalId];
        require(proposal.approved && !proposal.curated && !proposal.rejected, "Artwork proposal not approved or already curated/rejected.");
        proposal.curated = true;
        emit ArtworkCurated(_artworkProposalId, msg.sender);
    }


    // -------- NFT Minting & Management Functions --------

    function mintArtworkNFT(uint _artworkProposalId) public onlyAdmin {
        ArtworkProposal storage proposal = artworkProposals[_artworkProposalId];
        require(proposal.curated && !artworkProposals[_artworkProposalId].rejected, "Artwork must be curated and not rejected to mint NFT.");

        uint artworkId = nextArtworkId++;
        artworks[artworkId] = Artwork({
            artist: proposal.proposer,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            metadata: "", // Initial metadata can be set later
            isNFTMinted: true,
            isFractionalized: false,
            fractionsMinted: 0
        });
        emit ArtworkMinted(artworkId, proposal.proposer, artworkId); // tokenId = artworkId for simplicity
    }

    function setArtworkMetadata(uint _artworkId, string memory _newMetadata) public {
        require(artworks[_artworkId].artist == msg.sender || msg.sender == admin, "Only artist or admin can set metadata.");
        artworks[_artworkId].metadata = _newMetadata;
        emit ArtworkMetadataUpdated(_artworkId, _newMetadata);
    }

    function fractionalizeNFT(uint _artworkId, uint _numberOfFractions) public onlyMember payable {
        // Optional: Implement fractionalization fee if fractionalizationFee > 0
        // require(msg.value >= fractionalizationFee, "Insufficient fractionalization fee.");
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isNFTMinted && !artwork.isFractionalized, "Artwork must be minted and not already fractionalized.");
        require(artwork.artist == msg.sender || msg.sender == admin, "Only artist or admin can fractionalize.");
        require(_numberOfFractions > 1 && _numberOfFractions <= 10000, "Number of fractions must be between 2 and 10000.");

        artwork.isFractionalized = true;
        artwork.fractionsMinted = _numberOfFractions;
        nftFractionsBalances[_artworkId][msg.sender] = _numberOfFractions; // Artist initially holds all fractions
        emit ArtworkFractionalized(_artworkId, _numberOfFractions);
    }

    function buyFraction(uint _artworkId, uint _fractionAmount) public payable {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isFractionalized, "Artwork is not fractionalized.");
        require(nftFractionsBalances[_artworkId][artwork.artist] >= _fractionAmount, "Not enough fractions available for sale by the artist.");
        require(_fractionAmount > 0, "Fraction amount must be positive.");

        // Example price calculation (can be more sophisticated)
        uint pricePerFraction = 0.01 ether; // Example: 0.01 ETH per fraction
        uint totalPrice = pricePerFraction * _fractionAmount;
        require(msg.value >= totalPrice, "Insufficient funds.");

        nftFractionsBalances[_artworkId][artwork.artist] -= _fractionAmount;
        nftFractionsBalances[_artworkId][msg.sender] += _fractionAmount;

        // Transfer funds to artist (or treasury, depending on the model)
        payable(artwork.artist).transfer(totalPrice); // Or send to treasury if collective benefits more
        emit FractionBought(_artworkId, msg.sender, _fractionAmount);
    }


    // -------- Collaborative Art Creation Functions --------

    function startCollaborativeCanvas(string memory _canvasName, string memory _initialState) public onlyMember {
        require(bytes(_canvasName).length > 0, "Canvas name is required.");

        uint canvasId = nextCanvasId++;
        collaborativeCanvases[canvasId] = CollaborativeCanvas({
            name: _canvasName,
            creator: msg.sender,
            currentState: _initialState,
            isActive: true
        });
        emit CanvasStarted(canvasId, _canvasName, msg.sender);
    }

    function contributeToCanvas(uint _canvasId, string memory _contributionData) public onlyMember {
        CollaborativeCanvas storage canvas = collaborativeCanvases[_canvasId];
        require(canvas.isActive, "Canvas is not active.");
        require(bytes(_contributionData).length > 0, "Contribution data is required.");

        // Example: Simple string concatenation, could be more complex data structure or on-chain storage interaction
        canvas.currentState = string(abi.encodePacked(canvas.currentState, _contributionData));
        emit CanvasContribution(_canvasId, msg.sender, _contributionData);
    }


    // -------- Exhibitions & Galleries Functions --------

    function createExhibition(string memory _exhibitionName, string memory _description) public onlyMember {
        require(bytes(_exhibitionName).length > 0, "Exhibition name is required.");

        uint exhibitionId = nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            name: _exhibitionName,
            description: _description,
            curator: msg.sender,
            artworkIds: new uint[](0),
            isActive: false,
            isStarted: false,
            isEnded: false
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, msg.sender);
    }

    function addArtworkToExhibition(uint _exhibitionId, uint _artworkId) public onlyMember {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.curator == msg.sender || msg.sender == admin, "Only curator or admin can add artworks.");
        require(artworks[_artworkId].isNFTMinted, "Artwork must be minted to be added to an exhibition.");
        require(!artworkInExhibition[_artworkId], "Artwork already in an exhibition."); // Prevent duplicates

        exhibition.artworkIds.push(_artworkId);
        artworkInExhibition[_artworkId] = true;
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
    }

    function startExhibition(uint _exhibitionId) public onlyMember {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.curator == msg.sender || msg.sender == admin, "Only curator or admin can start exhibition.");
        require(!exhibition.isStarted && !exhibition.isEnded, "Exhibition already started or ended.");
        exhibition.isStarted = true;
        exhibition.isActive = true;
        emit ExhibitionStarted(_exhibitionId);
    }

    function purchaseArtworkFromExhibition(uint _exhibitionId, uint _artworkId) public payable {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isStarted && !exhibition.isEnded, "Exhibition must be active to purchase artwork.");
        require(artworkInExhibition[_artworkId], "Artwork not in this exhibition.");
        require(artworks[_artworkId].isNFTMinted, "Artwork must be minted to be purchased.");
        // Add logic for artwork sale price and transfer (e.g., fixed price, auction, etc.)
        uint artworkPrice = 1 ether; // Example fixed price
        require(msg.value >= artworkPrice, "Insufficient funds to purchase artwork.");

        // Transfer NFT ownership (simplified, assuming direct transfer, could use ERC721/1155 standard)
        // In a real implementation, you'd likely be integrating with an NFT contract.
        // For this example, we'll just mark ownership change conceptually.
        address originalArtist = artworks[_artworkId].artist;
        artworks[_artworkId].artist = msg.sender;

        // Distribute revenue (artist and collective treasury split - example)
        uint artistShare = (artworkPrice * 80) / 100; // 80% to artist
        uint collectiveShare = artworkPrice - artistShare; // 20% to collective

        treasuryBalance += collectiveShare;
        payable(originalArtist).transfer(artistShare);

        emit ArtworkPurchasedFromExhibition(_exhibitionId, _artworkId, msg.sender, artworkPrice);
    }

    function distributeExhibitionRevenue(uint _exhibitionId) public onlyAdmin {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isStarted && !exhibition.isEnded, "Exhibition must be started and not ended.");
        require(!exhibition.isActive, "Exhibition revenue already distributed or still active."); // Prevent re-distribution
        exhibition.isActive = false; // Mark as inactive after distribution
        exhibition.isEnded = true; // Mark as ended

        uint totalRevenue = 0; // Calculate total revenue from sales within this exhibition
        // In a real implementation, track sales per exhibition and sum up the revenue.
        // For this example, we'll assume a fixed amount for demonstration purposes.
        totalRevenue = 10 ether; // Example total exhibition revenue

        // Distribution logic (example - could be more complex based on artwork sales, etc.)
        uint collectiveShare = (totalRevenue * 30) / 100; // 30% to collective treasury
        uint artistShare = totalRevenue - collectiveShare; // 70% to be distributed among artists (proportional to artworks in exhibition - simplified example)

        treasuryBalance += collectiveShare;
        // In a real implementation, distribute artistShare proportionally to artists based on their artwork sales in the exhibition.
        // For this example, we just demonstrate the treasury share.

        emit ExhibitionRevenueDistributed(_exhibitionId, totalRevenue);
    }


    // -------- Treasury & Revenue Sharing Functions --------

    function depositToTreasury() public payable onlyMember {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function proposeTreasurySpending(address _recipient, uint _amount, string memory _reason) public onlyMember {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0 && _amount <= treasuryBalance, "Invalid spending amount or insufficient treasury balance.");
        require(bytes(_reason).length > 0, "Spending reason is required.");

        uint proposalId = nextTreasuryProposalId++;
        treasuryProposals[proposalId] = TreasuryProposal({
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            approved: false,
            rejected: false,
            voteCount: 0,
            deadline: block.timestamp + 7 days // 7 days voting period
        });

        emit TreasurySpendingProposed(proposalId, msg.sender, _recipient, _amount, _reason);
    }

    function voteOnTreasurySpending(uint _proposalId, bool _vote)
        public
        onlyMember
        validProposal(_proposalId, ProposalType.Treasury)
        proposalDeadlineNotReached(_proposalId, ProposalType.Treasury)
    {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted.");

        proposal.votes[msg.sender] = true;
        if (_vote) {
            proposal.voteCount++;
        }
        emit TreasuryVoteCast(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.deadline) {
            _executeTreasuryProposal(_proposalId);
        }
    }

    function _executeTreasuryProposal(uint _proposalId) private {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        if (proposal.approved || proposal.rejected) return; // Prevent re-execution

        uint requiredVotes = (memberList.length / 2) + 1; // Simple majority
        bool approved = proposal.voteCount >= requiredVotes;

        if (approved) {
            proposal.approved = true;
            payable(proposal.recipient).transfer(proposal.amount);
            treasuryBalance -= proposal.amount;
        } else {
            proposal.rejected = true; // Explicitly reject if not enough votes
        }
        emit TreasurySpendingExecuted(_proposalId, proposal.recipient, proposal.amount, approved);
    }


    // -------- Reputation & Community Features --------

    function awardReputation(address _member, uint _reputationPoints, string memory _reason) public onlyAdmin {
        require(members[_member], "Address is not a member.");
        require(_reputationPoints > 0, "Reputation points must be positive.");
        memberReputation[_member] += _reputationPoints;
        emit ReputationAwarded(_member, _reputationPoints, _reason);
    }

    function redeemReputationForBenefit(uint _reputationPoints) public onlyMember {
        require(memberReputation[msg.sender] >= _reputationPoints, "Insufficient reputation points.");
        require(_reputationPoints > 0, "Reputation points to redeem must be positive.");

        // Example benefit: Increased voting power (can be more creative)
        // In a real implementation, manage voting power dynamically based on reputation.
        // For this example, just emit an event indicating redemption.

        memberReputation[msg.sender] -= _reputationPoints;
        emit ReputationRedeemed(msg.sender, _reputationPoints, "Voting Power Boost (Example)");
    }

    function createCommunityChallenge(string memory _challengeTitle, string memory _description, uint _rewardAmount) public onlyAdmin {
        require(bytes(_challengeTitle).length > 0 && bytes(_description).length > 0, "Title and description are required.");
        require(_rewardAmount > 0 && treasuryBalance >= _rewardAmount, "Invalid reward amount or insufficient treasury balance.");

        uint challengeId = nextChallengeId++;
        communityChallenges[challengeId] = CommunityChallenge({
            title: _challengeTitle,
            description: _description,
            rewardAmount: _rewardAmount,
            isActive: true,
            deadline: block.timestamp + 30 days // 30 days challenge period
        });
        treasuryBalance -= _rewardAmount; // Reserve reward from treasury
        emit ChallengeCreated(challengeId, _challengeTitle, admin, _rewardAmount);
    }

    function submitChallengeEntry(uint _challengeId, uint _artworkId) public onlyMember {
        CommunityChallenge storage challenge = communityChallenges[_challengeId];
        require(challenge.isActive, "Challenge is not active.");
        require(block.timestamp < challenge.deadline, "Challenge deadline reached.");
        require(artworks[_artworkId].artist == msg.sender, "Only artist of the artwork can submit.");
        require(artworks[_artworkId].isNFTMinted, "Artwork must be minted to be submitted.");

        challengeEntries[_challengeId].push(_artworkId);
        emit ChallengeEntrySubmitted(_challengeId, _artworkId, msg.sender);
        // In a real scenario, you might want to implement voting/judging for challenge entries to award the reward.
    }


    // -------- Admin Functions --------

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
    }

    function setMembershipFee(uint _newFee) public onlyAdmin {
        membershipFee = _newFee;
    }

    function setArtworkProposalFee(uint _newFee) public onlyAdmin {
        artworkProposalFee = _newFee;
    }

    function setFractionalizationFee(uint _newFee) public onlyAdmin {
        fractionalizationFee = _newFee;
    }

    // -------- View Functions --------

    function getMemberCount() public view returns (uint) {
        return memberList.length;
    }

    function getArtworkDetails(uint _artworkId) public view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getExhibitionDetails(uint _exhibitionId) public view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function getTreasuryBalance() public view returns (uint) {
        return treasuryBalance;
    }

    function getMemberReputation(address _member) public view returns (uint) {
        return memberReputation[_member];
    }

    function getChallengeDetails(uint _challengeId) public view returns (CommunityChallenge memory) {
        return communityChallenges[_challengeId];
    }

    function getChallengeEntryCount(uint _challengeId) public view returns (uint) {
        return challengeEntries[_challengeId].length;
    }

    function getMembershipProposalDetails(uint _proposalId) public view returns (MembershipProposal memory) {
        return membershipProposals[_proposalId];
    }

    function getArtworkProposalDetails(uint _proposalId) public view returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }

    function getTreasuryProposalDetails(uint _proposalId) public view returns (TreasuryProposal memory) {
        return treasuryProposals[_proposalId];
    }
}
```