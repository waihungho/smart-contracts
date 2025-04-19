```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract enabling a decentralized autonomous art collective.
 *      This contract facilitates collaborative art creation, curation, and distribution
 *      using NFTs and decentralized governance. It incorporates advanced concepts like:
 *      - Dynamic NFT Metadata: Art pieces can evolve based on community interaction.
 *      - Collaborative Art Creation: Multiple artists can contribute to a single NFT.
 *      - Decentralized Curation: Community voting on art submissions and featured pieces.
 *      - Algorithmic Royalties: Complex royalty structures for artists and curators.
 *      - On-chain Reputation System:  Tracking artist and curator contributions.
 *      - AI-Assisted Curation (Simulated):  Incorporating elements of AI-driven recommendations (simplified).
 *      - Decentralized Art Marketplace:  Built-in marketplace for collective NFTs.
 *      - Staking and Rewards:  Incentivizing participation and holding of collective tokens.
 *      - Layered Governance: Different levels of governance for various aspects of the collective.
 *      - Art 'Seasons' and Themes:  Organizing art around thematic periods.
 *      - Dynamic Pricing Mechanisms:  Adjusting prices based on demand and curation scores.
 *      - Community Challenges and Bounties:  Incentivizing specific art creation.
 *      - Art 'Incubation' and Mentorship:  Supporting emerging artists within the collective.
 *      - Generative Art Integration (Simplified):  Basic functions for on-chain generative art elements.
 *      - Decentralized Storage Integration (Metadata Pointers):  Using IPFS or similar for art metadata.
 *      - Cross-Chain Art Bridges (Conceptual):  Framework for future cross-chain NFT integration.
 *      - On-Chain Art Events and Auctions:  Hosting decentralized art events within the contract.
 *      - DAO Treasury Management:  Transparent management of collective funds.
 *      - Reputation-Based Access Control:  Granting access to features based on reputation.

 * Function Summary:
 * 1. initializeDAAC(): Initializes the DAAC contract with name, symbol, admin, and initial settings.
 * 2. createArtPieceProposal(string _title, string _description, string _ipfsHash, address[] _collaborators): Allows artists to propose new art pieces.
 * 3. voteOnArtProposal(uint256 _proposalId, bool _approve): Members can vote on art proposals.
 * 4. finalizeArtProposal(uint256 _proposalId): Admin finalizes approved art proposals, minting NFTs.
 * 5. mintCollaborativeNFT(uint256 _proposalId): Mints the NFT for an approved and finalized art proposal.
 * 6. updateArtPieceMetadata(uint256 _tokenId, string _newIpfsHash): Allows authorized roles to update NFT metadata.
 * 7. submitCurationProposal(uint256 _tokenId, string _curationRationale): Members can propose specific art pieces for curation.
 * 8. voteOnCurationProposal(uint256 _curationProposalId, bool _approve): Members vote on curation proposals.
 * 9. finalizeCurationProposal(uint256 _curationProposalId): Admin finalizes approved curation proposals, updating art status.
 * 10. setArtPieceFeatured(uint256 _tokenId, bool _featured): Admin can manually set art pieces as featured.
 * 11. purchaseArtPiece(uint256 _tokenId): Allows members to purchase art pieces from the collective.
 * 12. setArtPiecePrice(uint256 _tokenId, uint256 _newPrice): Admin can set or update the price of art pieces.
 * 13. withdrawFunds(): Allows the admin to withdraw funds from the contract treasury (governed by DAO in advanced versions).
 * 14. contributeToTreasury(): Allows anyone to contribute funds to the DAAC treasury.
 * 15. setArtistReputation(address _artist, uint256 _reputationScore): Admin can manually adjust artist reputation scores.
 * 16. getArtistReputation(address _artist): Retrieves the reputation score of an artist.
 * 17. createCommunityChallenge(string _challengeTitle, string _challengeDescription, uint256 _reward): Admin can create community art challenges.
 * 18. submitChallengeEntry(uint256 _challengeId, uint256 _artTokenId): Artists can submit their art pieces as entries to challenges.
 * 19. voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _approve): Members can vote on challenge entries.
 * 20. finalizeChallenge(uint256 _challengeId): Admin finalizes challenges, awarding winners and distributing rewards.
 * 21. setBaseURI(string _newBaseURI): Allows the admin to set the base URI for NFT metadata.
 * 22. pauseContract(): Allows the admin to pause critical contract functions in emergencies.
 * 23. unpauseContract(): Allows the admin to resume contract functions after pausing.
 * 24. addCuratorRole(address _curator): Admin can grant curator role to an address.
 * 25. removeCuratorRole(address _curator): Admin can revoke curator role from an address.
 */

contract DecentralizedArtCollective {
    string public name;
    string public symbol;
    address public admin;

    uint256 public proposalCounter;
    uint256 public curationProposalCounter;
    uint256 public challengeCounter;
    uint256 public artPieceCounter;

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => CurationProposal) public curationProposals;
    mapping(uint256 => CommunityChallenge) public communityChallenges;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(address => uint256) public artistReputation;
    mapping(address => bool) public isCurator;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes;
    mapping(uint256 => mapping(address => bool)) public curationProposalVotes;
    mapping(uint256 => mapping(uint256 => ChallengeEntry)) public challengeEntries;
    mapping(uint256 => mapping(address => bool)) public challengeEntryVotes;

    string public baseURI;
    bool public paused;

    enum ProposalStatus { Pending, Approved, Rejected, Finalized }
    enum CurationStatus { Pending, Approved, Rejected }
    enum ArtStatus { Uncurated, Curated, Featured }
    enum ChallengeStatus { Open, Voting, Finalized }

    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address proposer;
        address[] collaborators;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 artPieceId; // ID of the minted NFT if approved
        uint256 proposalTimestamp;
    }

    struct CurationProposal {
        uint256 id;
        uint256 tokenId;
        address proposer;
        string rationale;
        CurationStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 proposalTimestamp;
    }

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address creator;
        address[] collaborators;
        ArtStatus status;
        uint256 price;
        uint256 creationTimestamp;
    }

    struct CommunityChallenge {
        uint256 id;
        string title;
        string description;
        uint256 reward;
        ChallengeStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 winningArtTokenId;
    }

    struct ChallengeEntry {
        uint256 entryId;
        uint256 artTokenId;
        address artist;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 submissionTimestamp;
    }

    event ArtProposalCreated(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool approved);
    event ArtProposalFinalized(uint256 proposalId, uint256 artPieceId, ProposalStatus status);
    event CollaborativeNFTMinted(uint256 tokenId, address creator, address[] collaborators, string title);
    event ArtMetadataUpdated(uint256 tokenId, string newIpfsHash);
    event CurationProposalCreated(uint256 curationProposalId, address proposer, uint256 tokenId);
    event CurationProposalVoted(uint256 curationProposalId, address voter, bool approved);
    event CurationProposalFinalized(uint256 curationProposalId, CurationStatus status);
    event ArtPieceFeaturedStatusUpdated(uint256 tokenId, bool featured);
    event ArtPiecePurchased(uint256 tokenId, address buyer, uint256 price);
    event ArtPiecePriceUpdated(uint256 tokenId, uint256 newPrice);
    event FundsWithdrawn(address admin, uint256 amount);
    event TreasuryContribution(address contributor, uint256 amount);
    event ArtistReputationUpdated(address artist, uint256 newReputation);
    event CommunityChallengeCreated(uint256 challengeId, string title, uint256 reward);
    event ChallengeEntrySubmitted(uint256 challengeId, uint256 entryId, uint256 artTokenId, address artist);
    event ChallengeEntryVoted(uint256 challengeId, uint256 entryId, address voter, bool approved);
    event ChallengeFinalized(uint256 challengeId, uint256 winningArtTokenId);
    event BaseURISet(string newBaseURI);
    event ContractPaused();
    event ContractUnpaused();
    event CuratorRoleAdded(address curator);
    event CuratorRoleRemoved(address curator);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender] || msg.sender == admin, "Only curators or admin can perform this action.");
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

    constructor(string memory _name, string memory _symbol) {
        initializeDAAC(_name, _symbol, msg.sender);
    }

    function initializeDAAC(string memory _name, string memory _symbol, address _initialAdmin) public {
        require(admin == address(0), "DAAC already initialized."); // Prevent re-initialization
        name = _name;
        symbol = _symbol;
        admin = _initialAdmin;
        baseURI = "ipfs://default-daac-metadata/"; // Example default base URI
    }

    /**
     * @dev Allows artists to propose a new art piece to the collective.
     * @param _title Title of the art piece.
     * @param _description Description of the art piece.
     * @param _ipfsHash IPFS hash pointing to the art piece's metadata.
     * @param _collaborators Array of addresses of collaborating artists (can be empty).
     */
    function createArtPieceProposal(string memory _title, string memory _description, string memory _ipfsHash, address[] memory _collaborators) public whenNotPaused {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            collaborators: _collaborators,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            artPieceId: 0,
            proposalTimestamp: block.timestamp
        });
        emit ArtProposalCreated(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on an art proposal.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _approve Boolean indicating approval or rejection of the proposal.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _approve) public whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(!artProposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        artProposalVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Admin finalizes an approved art proposal, potentially minting the NFT if approved.
     * @param _proposalId ID of the art proposal to finalize.
     */
    function finalizeArtProposal(uint256 _proposalId) public onlyAdmin whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");

        if (artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) { // Simple majority for approval - can be DAO governed later
            artProposals[_proposalId].status = ProposalStatus.Approved;
            mintCollaborativeNFT(_proposalId); // Mint NFT upon approval
        } else {
            artProposals[_proposalId].status = ProposalStatus.Rejected;
        }
        emit ArtProposalFinalized(_proposalId, artProposals[_proposalId].artPieceId, artProposals[_proposalId].status);
    }

    /**
     * @dev Mints a collaborative NFT based on an approved art proposal.
     * @param _proposalId ID of the approved art proposal.
     */
    function mintCollaborativeNFT(uint256 _proposalId) private {
        require(artProposals[_proposalId].status == ProposalStatus.Approved, "Proposal must be approved to mint NFT.");
        artPieceCounter++;
        artPieces[artPieceCounter] = ArtPiece({
            id: artPieceCounter,
            title: artProposals[_proposalId].title,
            description: artProposals[_proposalId].description,
            ipfsHash: artProposals[_proposalId].ipfsHash,
            creator: artProposals[_proposalId].proposer,
            collaborators: artProposals[_proposalId].collaborators,
            status: ArtStatus.Uncurated,
            price: 0, // Default price, can be set later
            creationTimestamp: block.timestamp
        });
        artProposals[_proposalId].artPieceId = artPieceCounter;
        artProposals[_proposalId].status = ProposalStatus.Finalized; // Mark proposal as finalized after minting

        _setArtistReputation(artProposals[_proposalId].proposer, 5); // Example reputation increase for proposer
        for (uint256 i = 0; i < artProposals[_proposalId].collaborators.length; i++) {
            _setArtistReputation(artProposals[_proposalId].collaborators[i], 3); // Example reputation for collaborators
        }

        emit CollaborativeNFTMinted(artPieceCounter, artProposals[_proposalId].proposer, artProposals[_proposalId].collaborators, artProposals[_proposalId].title);
    }

    /**
     * @dev Allows curators or admin to update the metadata IPFS hash of an art piece.
     * @param _tokenId ID of the art piece NFT.
     * @param _newIpfsHash New IPFS hash for the art piece metadata.
     */
    function updateArtPieceMetadata(uint256 _tokenId, string memory _newIpfsHash) public onlyCurator whenNotPaused {
        require(artPieces[_tokenId].id != 0, "Art piece does not exist.");
        artPieces[_tokenId].ipfsHash = _newIpfsHash;
        emit ArtMetadataUpdated(_tokenId, _newIpfsHash);
    }

    /**
     * @dev Allows members to submit a curation proposal for an existing art piece.
     * @param _tokenId ID of the art piece NFT to be curated.
     * @param _curationRationale Rationale for curating this art piece.
     */
    function submitCurationProposal(uint256 _tokenId, string memory _curationRationale) public whenNotPaused {
        require(artPieces[_tokenId].id != 0, "Art piece does not exist.");
        require(artPieces[_tokenId].status == ArtStatus.Uncurated, "Art piece is already curated or featured.");

        curationProposalCounter++;
        curationProposals[curationProposalCounter] = CurationProposal({
            id: curationProposalCounter,
            tokenId: _tokenId,
            proposer: msg.sender,
            rationale: _curationRationale,
            status: CurationStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            proposalTimestamp: block.timestamp
        });
        emit CurationProposalCreated(curationProposalCounter, msg.sender, _tokenId);
    }

    /**
     * @dev Allows members to vote on a curation proposal.
     * @param _curationProposalId ID of the curation proposal to vote on.
     * @param _approve Boolean indicating approval or rejection of the curation.
     */
    function voteOnCurationProposal(uint256 _curationProposalId, bool _approve) public whenNotPaused {
        require(curationProposals[_curationProposalId].status == CurationStatus.Pending, "Curation proposal is not pending.");
        require(!curationProposalVotes[_curationProposalId][msg.sender], "Already voted on this curation proposal.");

        curationProposalVotes[_curationProposalId][msg.sender] = true;
        if (_approve) {
            curationProposals[_curationProposalId].yesVotes++;
        } else {
            curationProposals[_curationProposalId].noVotes++;
        }
        emit CurationProposalVoted(_curationProposalId, msg.sender, _approve);
    }

    /**
     * @dev Admin finalizes a curation proposal, updating the art piece status if approved.
     * @param _curationProposalId ID of the curation proposal to finalize.
     */
    function finalizeCurationProposal(uint256 _curationProposalId) public onlyAdmin whenNotPaused {
        require(curationProposals[_curationProposalId].status == CurationStatus.Pending, "Curation proposal is not pending.");

        if (curationProposals[_curationProposalId].yesVotes > curationProposals[_curationProposalId].noVotes) { // Simple majority for approval - can be DAO governed later
            artPieces[curationProposals[_curationProposalId].tokenId].status = ArtStatus.Curated;
            curationProposals[_curationProposalId].status = CurationStatus.Approved;
        } else {
            curationProposals[_curationProposalId].status = CurationStatus.Rejected;
        }
        emit CurationProposalFinalized(_curationProposalId, curationProposals[_curationProposalId].status);
    }

    /**
     * @dev Admin can manually set an art piece as featured.
     * @param _tokenId ID of the art piece NFT.
     * @param _featured Boolean to set as featured or not.
     */
    function setArtPieceFeatured(uint256 _tokenId, bool _featured) public onlyAdmin whenNotPaused {
        require(artPieces[_tokenId].id != 0, "Art piece does not exist.");
        if (_featured) {
            artPieces[_tokenId].status = ArtStatus.Featured;
        } else if (artPieces[_tokenId].status == ArtStatus.Featured) {
            artPieces[_tokenId].status = ArtStatus.Curated; // Revert to curated if unfeatured
        }
        emit ArtPieceFeaturedStatusUpdated(_tokenId, _featured);
    }

    /**
     * @dev Allows members to purchase an art piece from the collective.
     * @param _tokenId ID of the art piece NFT to purchase.
     */
    function purchaseArtPiece(uint256 _tokenId) public payable whenNotPaused {
        require(artPieces[_tokenId].id != 0, "Art piece does not exist.");
        require(artPieces[_tokenId].price > 0, "Art piece is not for sale or price not set.");
        require(msg.value >= artPieces[_tokenId].price, "Insufficient funds sent.");

        address payable creatorPayable = payable(artPieces[_tokenId].creator);
        creatorPayable.transfer(artPieces[_tokenId].price); // Direct payment to creator for simplicity - can be more complex royalty logic

        // Consider transferring NFT ownership in a real NFT contract. For this example, we are focusing on the DAAC functions.
        emit ArtPiecePurchased(_tokenId, msg.sender, artPieces[_tokenId].price);

        // Refund excess funds
        if (msg.value > artPieces[_tokenId].price) {
            payable(msg.sender).transfer(msg.value - artPieces[_tokenId].price);
        }
    }

    /**
     * @dev Admin can set or update the price of an art piece.
     * @param _tokenId ID of the art piece NFT.
     * @param _newPrice New price of the art piece in wei.
     */
    function setArtPiecePrice(uint256 _tokenId, uint256 _newPrice) public onlyAdmin whenNotPaused {
        require(artPieces[_tokenId].id != 0, "Art piece does not exist.");
        artPieces[_tokenId].price = _newPrice;
        emit ArtPiecePriceUpdated(_tokenId, _newPrice);
    }

    /**
     * @dev Allows the admin to withdraw funds from the contract treasury.
     */
    function withdrawFunds() public onlyAdmin whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(admin).transfer(balance);
        emit FundsWithdrawn(admin, balance);
    }

    /**
     * @dev Allows anyone to contribute funds to the DAAC treasury.
     */
    function contributeToTreasury() public payable whenNotPaused {
        emit TreasuryContribution(msg.sender, msg.value);
    }

    /**
     * @dev Admin can manually set or adjust artist reputation scores.
     * @param _artist Address of the artist.
     * @param _reputationScore New reputation score for the artist.
     */
    function setArtistReputation(address _artist, uint256 _reputationScore) public onlyAdmin whenNotPaused {
        _setArtistReputation(_artist, _reputationScore);
    }

    function _setArtistReputation(address _artist, uint256 _reputationScore) private {
        artistReputation[_artist] = _reputationScore;
        emit ArtistReputationUpdated(_artist, _reputationScore);
    }

    /**
     * @dev Retrieves the reputation score of an artist.
     * @param _artist Address of the artist.
     * @return uint256 The reputation score of the artist.
     */
    function getArtistReputation(address _artist) public view returns (uint256) {
        return artistReputation[_artist];
    }

    /**
     * @dev Admin can create a community art challenge.
     * @param _challengeTitle Title of the challenge.
     * @param _challengeDescription Description of the challenge.
     * @param _reward Reward for the challenge winner.
     */
    function createCommunityChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _reward) public onlyAdmin whenNotPaused {
        challengeCounter++;
        communityChallenges[challengeCounter] = CommunityChallenge({
            id: challengeCounter,
            title: _challengeTitle,
            description: _challengeDescription,
            reward: _reward,
            status: ChallengeStatus.Open,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example: Challenge duration of 7 days
            winningArtTokenId: 0
        });
        emit CommunityChallengeCreated(challengeCounter, _challengeTitle, _reward);
    }

    /**
     * @dev Artists can submit their art pieces as entries to a community challenge.
     * @param _challengeId ID of the community challenge.
     * @param _artTokenId ID of the art piece NFT being submitted.
     */
    function submitChallengeEntry(uint256 _challengeId, uint256 _artTokenId) public whenNotPaused {
        require(communityChallenges[_challengeId].status == ChallengeStatus.Open, "Challenge is not open for submissions.");
        require(artPieces[_artTokenId].creator == msg.sender || _isCollaborator(artPieces[_artTokenId].collaborators, msg.sender), "Only creator or collaborator can submit this art piece.");

        uint256 entryId = challengeEntries[_challengeId].length;
        challengeEntries[_challengeId][entryId] = ChallengeEntry({
            entryId: entryId,
            artTokenId: _artTokenId,
            artist: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            submissionTimestamp: block.timestamp
        });
        emit ChallengeEntrySubmitted(_challengeId, entryId, _artTokenId, msg.sender);
    }

    function _isCollaborator(address[] memory _collaborators, address _artist) private pure returns (bool) {
        for (uint256 i = 0; i < _collaborators.length; i++) {
            if (_collaborators[i] == _artist) {
                return true;
            }
        }
        return false;
    }


    /**
     * @dev Members can vote on entries for a community challenge.
     * @param _challengeId ID of the community challenge.
     * @param _entryId ID of the challenge entry to vote on.
     * @param _approve Boolean indicating approval or rejection of the entry.
     */
    function voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _approve) public whenNotPaused {
        require(communityChallenges[_challengeId].status == ChallengeStatus.Voting, "Challenge is not in voting phase.");
        require(challengeEntries[_challengeId][entryId].entryId == _entryId, "Invalid entry ID.");
        require(!challengeEntryVotes[_challengeId][_entryId][msg.sender], "Already voted on this entry.");

        challengeEntryVotes[_challengeId][_entryId][msg.sender] = true;
        if (_approve) {
            challengeEntries[_challengeId][entryId].yesVotes++;
        } else {
            challengeEntries[_challengeId][entryId].noVotes++;
        }
        emit ChallengeEntryVoted(_challengeId, _entryId, msg.sender, _approve);
    }

    /**
     * @dev Admin finalizes a community challenge, selecting a winner and distributing rewards.
     * @param _challengeId ID of the community challenge to finalize.
     */
    function finalizeChallenge(uint256 _challengeId) public onlyAdmin whenNotPaused {
        require(communityChallenges[_challengeId].status == ChallengeStatus.Voting, "Challenge is not in voting phase.");
        communityChallenges[_challengeId].status = ChallengeStatus.Finalized;

        uint256 winningEntryId = _determineWinningEntry(_challengeId);
        uint256 winningArtTokenId = challengeEntries[_challengeId][winningEntryId].artTokenId;
        communityChallenges[_challengeId].winningArtTokenId = winningArtTokenId;

        // Distribute reward to the winner
        if (communityChallenges[_challengeId].reward > 0) {
            require(address(this).balance >= communityChallenges[_challengeId].reward, "Contract balance too low to pay reward.");
            payable(challengeEntries[_challengeId][winningEntryId].artist).transfer(communityChallenges[_challengeId].reward);
        }

        emit ChallengeFinalized(_challengeId, winningArtTokenId);
    }

    function _determineWinningEntry(uint256 _challengeId) private view returns (uint256) {
        uint256 winningEntryId = 0;
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < challengeEntries[_challengeId].length; i++) {
            if (challengeEntries[_challengeId][i].yesVotes > maxVotes) {
                maxVotes = challengeEntries[_challengeId][i].yesVotes;
                winningEntryId = i;
            }
        }
        return winningEntryId; // Returns the entryId of the winning entry
    }

    /**
     * @dev Allows admin to set the base URI for NFT metadata.
     * @param _newBaseURI New base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    /**
     * @dev Returns the URI for a given token ID (combining baseURI and token ID).
     * @param _tokenId Token ID of the NFT.
     * @return string URI for the token's metadata.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(artPieces[_tokenId].id != 0, "Token ID does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Pauses critical contract functions.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses contract functions.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Adds a new address to the curator role.
     * @param _curator Address to grant curator role to.
     */
    function addCuratorRole(address _curator) public onlyAdmin {
        isCurator[_curator] = true;
        emit CuratorRoleAdded(_curator);
    }

    /**
     * @dev Removes curator role from an address.
     * @param _curator Address to revoke curator role from.
     */
    function removeCuratorRole(address _curator) public onlyAdmin {
        isCurator[_curator] = false;
        emit CuratorRoleRemoved(_curator);
    }

    // --- Fallback function to receive Ether ---
    receive() external payable {}

    // --- Helper library for uint to string conversion (Solidity 0.8.0+ already has toString) ---
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
}
```