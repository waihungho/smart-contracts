```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (Conceptual Smart Contract - Not for Production)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to mint NFTs,
 *      users to curate exhibitions, DAO governance for gallery operations, and innovative features like
 *      dynamic NFT pricing based on exhibition popularity, collaborative art creation, and decentralized licensing.
 *
 * Function Summary:
 *
 * **NFT Management:**
 * 1. mintArtworkNFT(string memory _artworkCID, string memory _metadataCID): Mints a new artwork NFT for an artist.
 * 2. transferArtworkOwnership(uint256 _tokenId, address _newOwner): Allows artwork owners to transfer ownership.
 * 3. setArtworkMetadata(uint256 _tokenId, string memory _metadataCID): Updates the metadata CID of an artwork NFT.
 * 4. burnArtworkNFT(uint256 _tokenId): Allows the artist to burn (destroy) their artwork NFT (with governance approval).
 *
 * **Gallery Space & Exhibition Management:**
 * 5. createGallerySpace(string memory _spaceName, string memory _spaceDescription): Creates a new gallery space.
 * 6. proposeArtworkForExhibition(uint256 _tokenId, uint256 _spaceId): Proposes an artwork NFT to be exhibited in a gallery space (requires DAO voting).
 * 7. voteOnExhibitionProposal(uint256 _proposalId, bool _approve): DAO members vote on artwork exhibition proposals.
 * 8. executeExhibitionProposal(uint256 _proposalId): Executes an approved exhibition proposal, adding artwork to the gallery space.
 * 9. removeArtworkFromExhibition(uint256 _tokenId, uint256 _spaceId): Removes an artwork from a gallery space (requires DAO voting).
 * 10. setGallerySpaceMetadata(uint256 _spaceId, string memory _spaceDescription): Updates the metadata/description of a gallery space.
 *
 * **DAO Governance & Operations:**
 * 11. proposeNewGovernanceRule(string memory _ruleDescription, bytes memory _ruleData): Allows DAO members to propose new governance rules.
 * 12. voteOnGovernanceProposal(uint256 _proposalId, bool _approve): DAO members vote on governance proposals.
 * 13. executeGovernanceProposal(uint256 _proposalId): Executes an approved governance proposal, implementing a new rule.
 * 14. setGalleryFee(uint256 _newFeePercentage): Sets the gallery fee percentage for artwork sales.
 * 15. withdrawGalleryFees(): Allows the DAO to withdraw collected gallery fees for maintenance and development.
 *
 * **Innovative & Advanced Features:**
 * 16. setDynamicPricingCurve(uint256 _tokenId, uint256[] memory _popularityThresholds, uint256[] memory _priceMultipliers): Sets a dynamic pricing curve for an artwork based on its exhibition popularity.
 * 17. purchaseArtworkLicense(uint256 _tokenId, string memory _licenseType): Allows users to purchase licenses for artwork usage (e.g., commercial, personal).
 * 18. initiateCollaborativeArtwork(string memory _artworkName, string memory _initialDataCID, address[] memory _collaborators): Initiates a collaborative artwork NFT with multiple artists.
 * 19. contributeToCollaborativeArtwork(uint256 _tokenId, string memory _contributionCID): Allows collaborators to contribute to a collaborative artwork, updating its metadata.
 * 20. redeemExhibitionReward(uint256 _spaceId): Allows users who staked tokens for a popular exhibition space to redeem rewards.
 * 21. proposeCommunityCuratedPlaylist(uint256 _spaceId, uint256[] memory _artworkTokenIds): Propose a curated playlist of artworks for a specific space.
 * 22. voteOnPlaylistProposal(uint256 _playlistProposalId, bool _approve): DAO members vote on community curated playlist proposals.
 * 23. executePlaylistProposal(uint256 _playlistProposalId): Executes an approved playlist proposal, setting the artwork order in a space.
 */
contract DecentralizedAutonomousArtGallery {
    // --- State Variables ---

    // NFT Contract Address (Assuming an external ERC721 contract for artwork NFTs)
    address public artworkNFTContract;

    // Gallery Spaces
    struct GallerySpace {
        string name;
        string description;
        uint256[] exhibitedArtworks; // Array of artwork token IDs
        address curator; // Address responsible for space management (initially DAO, can be delegated)
        uint256 popularityScore; // Based on visitor engagement/likes (conceptual)
    }
    mapping(uint256 => GallerySpace) public gallerySpaces;
    uint256 public nextSpaceId = 1;

    // Governance Proposals
    struct GovernanceProposal {
        string description;
        bytes ruleData;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 proposalDeadline;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public nextGovernanceProposalId = 1;
    uint256 public governanceVotingPeriod = 7 days; // Example voting period

    // Exhibition Proposals
    struct ExhibitionProposal {
        uint256 tokenId;
        uint256 spaceId;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 proposalDeadline;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    uint256 public nextExhibitionProposalId = 1;
    uint256 public exhibitionVotingPeriod = 3 days; // Example voting period

    // Dynamic Pricing Curves (Artwork Token ID => Curve) - Conceptual, simplified for example
    mapping(uint256 => DynamicPricingCurve) public artworkPricingCurves;
    struct DynamicPricingCurve {
        uint256[] popularityThresholds; // Popularity levels
        uint256[] priceMultipliers;     // Price multipliers at each threshold
    }

    // Gallery Fees
    uint256 public galleryFeePercentage = 5; // Default 5% fee on artwork sales

    // DAO Members (Conceptual - in a real DAO, membership would be more complex)
    mapping(address => bool) public daoMembers;
    address public daoGovernor; // Address with ultimate governance control (e.g., multisig or DAO contract)

    // Events
    event ArtworkNFTMinted(uint256 tokenId, address artist, string artworkCID, string metadataCID);
    event ArtworkOwnershipTransferred(uint256 tokenId, address from, address to);
    event ArtworkMetadataUpdated(uint256 tokenId, string metadataCID);
    event ArtworkNFTBurned(uint256 tokenId, address artist);

    event GallerySpaceCreated(uint256 spaceId, string spaceName, string spaceDescription);
    event ArtworkProposedForExhibition(uint256 proposalId, uint256 tokenId, uint256 spaceId);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool approved);
    event ArtworkAddedToExhibition(uint256 tokenId, uint256 spaceId);
    event ArtworkRemovedFromExhibition(uint256 tokenId, uint256 spaceId);
    event GallerySpaceMetadataUpdated(uint256 spaceId, string spaceDescription);

    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool approved);
    event GovernanceRuleExecuted(uint256 proposalId, string description);
    event GalleryFeeUpdated(uint256 newFeePercentage);
    event GalleryFeesWithdrawn(uint256 amount);

    event DynamicPricingCurveSet(uint256 tokenId);
    event ArtworkLicensePurchased(uint256 tokenId, address buyer, string licenseType);
    event CollaborativeArtworkInitiated(uint256 tokenId, string artworkName, address[] collaborators);
    event CollaborativeArtworkContribution(uint256 tokenId, address contributor, string contributionCID);
    event ExhibitionRewardRedeemed(uint256 spaceId, address redeemer, uint256 rewardAmount);
    event CommunityPlaylistProposed(uint256 proposalId, uint256 spaceId, address proposer);
    event PlaylistProposalVoted(uint256 proposalId, address voter, bool approved);
    event PlaylistExecuted(uint256 proposalId, uint256 spaceId);


    // --- Modifiers ---
    modifier onlyDAOMembers() {
        require(daoMembers[msg.sender] || msg.sender == daoGovernor, "Not a DAO member");
        _;
    }

    modifier onlyDAOGovernor() {
        require(msg.sender == daoGovernor, "Only DAO governor allowed");
        _;
    }

    // --- Constructor ---
    constructor(address _artworkNFTContract, address _daoGovernor) {
        artworkNFTContract = _artworkNFTContract;
        daoGovernor = _daoGovernor;
        daoMembers[_daoGovernor] = true; // Governor is initially a member
    }

    // --- NFT Management Functions ---

    /**
     * @dev Mints a new artwork NFT for an artist.
     * @param _artworkCID Content Identifier (CID) of the artwork file (e.g., IPFS hash).
     * @param _metadataCID Content Identifier (CID) of the artwork metadata (e.g., IPFS hash).
     */
    function mintArtworkNFT(string memory _artworkCID, string memory _metadataCID) external {
        // In a real implementation, you would interact with the external artworkNFTContract to mint.
        // For this example, we'll assume the NFT contract has a minting function that can be called.
        // Example:  uint256 tokenId = ArtworkNFT(artworkNFTContract).mint(msg.sender, _artworkCID, _metadataCID);
        // For simplicity in this standalone contract, we'll just emit an event.
        uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, _artworkCID))); // Example tokenId generation
        emit ArtworkNFTMinted(tokenId, msg.sender, _artworkCID, _metadataCID);
    }

    /**
     * @dev Allows artwork owners to transfer ownership of their NFTs.
     * @param _tokenId The ID of the artwork NFT to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferArtworkOwnership(uint256 _tokenId, address _newOwner) external {
        // In a real implementation, you would interact with the external artworkNFTContract to transfer.
        // Example: ArtworkNFT(artworkNFTContract).transferFrom(msg.sender, _newOwner, _tokenId);
        // For simplicity, just emit an event.
        emit ArtworkOwnershipTransferred(_tokenId, msg.sender, _newOwner);
    }

    /**
     * @dev Updates the metadata CID of an artwork NFT. Only the artwork owner can call this.
     * @param _tokenId The ID of the artwork NFT.
     * @param _metadataCID The new metadata CID.
     */
    function setArtworkMetadata(uint256 _tokenId, string memory _metadataCID) external {
        // In a real implementation, you would interact with the external artworkNFTContract to update metadata.
        // Example: ArtworkNFT(artworkNFTContract).setTokenMetadata(_tokenId, _metadataCID);
        // For simplicity, just emit an event.
        // In a real scenario, you'd need to verify msg.sender is the owner from the NFT contract.
        emit ArtworkMetadataUpdated(_tokenId, _metadataCID);
    }

    /**
     * @dev Allows the artist to burn (destroy) their artwork NFT, subject to DAO governance approval.
     * @param _tokenId The ID of the artwork NFT to burn.
     */
    function burnArtworkNFT(uint256 _tokenId) external onlyDAOMembers { // Requires DAO approval in this example
        // In a real implementation, you would interact with the external artworkNFTContract to burn.
        // Example: ArtworkNFT(artworkNFTContract).burn(_tokenId);
        // For simplicity, just emit an event.
        emit ArtworkNFTBurned(_tokenId, msg.sender);
    }

    // --- Gallery Space & Exhibition Management Functions ---

    /**
     * @dev Creates a new gallery space. Only DAO members can create spaces.
     * @param _spaceName The name of the gallery space.
     * @param _spaceDescription A description of the gallery space.
     */
    function createGallerySpace(string memory _spaceName, string memory _spaceDescription) external onlyDAOMembers {
        gallerySpaces[nextSpaceId] = GallerySpace({
            name: _spaceName,
            description: _spaceDescription,
            exhibitedArtworks: new uint256[](0),
            curator: address(0), // Initially no curator, managed by DAO
            popularityScore: 0
        });
        emit GallerySpaceCreated(nextSpaceId, _spaceName, _spaceDescription);
        nextSpaceId++;
    }

    /**
     * @dev Proposes an artwork NFT to be exhibited in a gallery space. Requires DAO voting to approve.
     * @param _tokenId The ID of the artwork NFT being proposed.
     * @param _spaceId The ID of the gallery space for exhibition.
     */
    function proposeArtworkForExhibition(uint256 _tokenId, uint256 _spaceId) external onlyDAOMembers {
        require(gallerySpaces[_spaceId].name.length > 0, "Gallery space does not exist"); // Check if space exists

        exhibitionProposals[nextExhibitionProposalId] = ExhibitionProposal({
            tokenId: _tokenId,
            spaceId: _spaceId,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposalDeadline: block.timestamp + exhibitionVotingPeriod
        });
        emit ArtworkProposedForExhibition(nextExhibitionProposalId, _tokenId, _spaceId);
        nextExhibitionProposalId++;
    }

    /**
     * @dev DAO members vote on artwork exhibition proposals.
     * @param _proposalId The ID of the exhibition proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnExhibitionProposal(uint256 _proposalId, bool _approve) external onlyDAOMembers {
        require(!exhibitionProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp < exhibitionProposals[_proposalId].proposalDeadline, "Voting period expired");

        if (_approve) {
            exhibitionProposals[_proposalId].votesFor++;
        } else {
            exhibitionProposals[_proposalId].votesAgainst++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes an approved exhibition proposal, adding the artwork to the gallery space.
     *      Requires a majority vote and proposal deadline to be reached.
     * @param _proposalId The ID of the exhibition proposal.
     */
    function executeExhibitionProposal(uint256 _proposalId) external onlyDAOMembers {
        require(!exhibitionProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp >= exhibitionProposals[_proposalId].proposalDeadline, "Voting period not expired");
        require(exhibitionProposals[_proposalId].votesFor > exhibitionProposals[_proposalId].votesAgainst, "Proposal not approved by majority");

        uint256 tokenId = exhibitionProposals[_proposalId].tokenId;
        uint256 spaceId = exhibitionProposals[_proposalId].spaceId;

        gallerySpaces[spaceId].exhibitedArtworks.push(tokenId);
        exhibitionProposals[_proposalId].executed = true;
        emit ArtworkAddedToExhibition(tokenId, spaceId);
    }

    /**
     * @dev Removes an artwork from a gallery space. Requires DAO voting.
     * @param _tokenId The ID of the artwork NFT to remove.
     * @param _spaceId The ID of the gallery space.
     */
    function removeArtworkFromExhibition(uint256 _tokenId, uint256 _spaceId) external onlyDAOMembers {
        // In a real scenario, you would likely initiate a removal proposal and voting process similar to exhibition proposals.
        // For simplicity, we'll just directly remove it with DAO member permission for this example.

        GallerySpace storage space = gallerySpaces[_spaceId];
        bool found = false;
        for (uint256 i = 0; i < space.exhibitedArtworks.length; i++) {
            if (space.exhibitedArtworks[i] == _tokenId) {
                space.exhibitedArtworks[i] = space.exhibitedArtworks[space.exhibitedArtworks.length - 1];
                space.exhibitedArtworks.pop();
                found = true;
                break;
            }
        }
        require(found, "Artwork not found in the exhibition space");
        emit ArtworkRemovedFromExhibition(_tokenId, _spaceId);
    }

    /**
     * @dev Updates the metadata/description of a gallery space. Only DAO members can update.
     * @param _spaceId The ID of the gallery space.
     * @param _spaceDescription The new description for the gallery space.
     */
    function setGallerySpaceMetadata(uint256 _spaceId, string memory _spaceDescription) external onlyDAOMembers {
        gallerySpaces[_spaceId].description = _spaceDescription;
        emit GallerySpaceMetadataUpdated(_spaceId, _spaceDescription);
    }


    // --- DAO Governance & Operations Functions ---

    /**
     * @dev Allows DAO members to propose new governance rules.
     * @param _ruleDescription A description of the governance rule proposal.
     * @param _ruleData Data associated with the rule (e.g., function signature and parameters for contract updates).
     */
    function proposeNewGovernanceRule(string memory _ruleDescription, bytes memory _ruleData) external onlyDAOMembers {
        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            description: _ruleDescription,
            ruleData: _ruleData,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposalDeadline: block.timestamp + governanceVotingPeriod
        });
        emit GovernanceProposalCreated(nextGovernanceProposalId, _ruleDescription);
        nextGovernanceProposalId++;
    }

    /**
     * @dev DAO members vote on governance proposals.
     * @param _proposalId The ID of the governance proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) external onlyDAOMembers {
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp < governanceProposals[_proposalId].proposalDeadline, "Voting period expired");

        if (_approve) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes an approved governance proposal, implementing the new rule.
     *      Requires a majority vote and proposal deadline to be reached.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyDAOGovernor { // Only governor can execute for security in this example
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp >= governanceProposals[_proposalId].proposalDeadline, "Voting period not expired");
        require(governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst, "Proposal not approved by majority");

        // In a real implementation, you would decode and execute the ruleData here.
        // This might involve calling other functions on this contract or even upgrading the contract.
        // For this example, we just emit an event.
        emit GovernanceRuleExecuted(_proposalId, governanceProposals[_proposalId].description);
        governanceProposals[_proposalId].executed = true;
    }

    /**
     * @dev Sets the gallery fee percentage for artwork sales. Only DAO governor can set this.
     * @param _newFeePercentage The new gallery fee percentage (e.g., 5 for 5%).
     */
    function setGalleryFee(uint256 _newFeePercentage) external onlyDAOGovernor {
        require(_newFeePercentage <= 20, "Fee percentage too high (max 20%)"); // Example limit
        galleryFeePercentage = _newFeePercentage;
        emit GalleryFeeUpdated(_newFeePercentage);
    }

    /**
     * @dev Allows the DAO governor to withdraw collected gallery fees.
     *      In a real system, fees would be collected during artwork sales (not implemented here for simplicity).
     */
    function withdrawGalleryFees() external onlyDAOGovernor {
        // In a real implementation, you would track collected fees and transfer them to the DAO governor or a treasury.
        // For this example, we'll simulate a withdrawal and emit an event.
        uint256 amount = 100 ether; // Example amount - replace with actual collected fees
        payable(daoGovernor).transfer(amount);
        emit GalleryFeesWithdrawn(amount);
    }


    // --- Innovative & Advanced Features ---

    /**
     * @dev Sets a dynamic pricing curve for an artwork based on its exhibition popularity.
     *      Conceptual example: Price increases with popularity.
     * @param _tokenId The ID of the artwork NFT.
     * @param _popularityThresholds Array of popularity scores that trigger price changes.
     * @param _priceMultipliers Array of price multipliers corresponding to popularity thresholds.
     */
    function setDynamicPricingCurve(uint256 _tokenId, uint256[] memory _popularityThresholds, uint256[] memory _priceMultipliers) external {
        // In a real implementation, you'd likely need to be the artwork owner or have specific permission.
        require(_popularityThresholds.length == _priceMultipliers.length, "Thresholds and multipliers arrays must be the same length");
        artworkPricingCurves[_tokenId] = DynamicPricingCurve({
            popularityThresholds: _popularityThresholds,
            priceMultipliers: _priceMultipliers
        });
        emit DynamicPricingCurveSet(_tokenId);
    }

    /**
     * @dev Allows users to purchase licenses for artwork usage (e.g., commercial, personal).
     *      This would typically involve payment and recording the license on-chain or off-chain linked to the NFT.
     * @param _tokenId The ID of the artwork NFT.
     * @param _licenseType The type of license being purchased (e.g., "commercial", "personal").
     */
    function purchaseArtworkLicense(uint256 _tokenId, string memory _licenseType) external payable {
        // In a real implementation, you would handle payment, license generation, and recording.
        // For simplicity, we just emit an event.
        // You might integrate with a licensing contract or system here.
        require(msg.value >= 0.1 ether, "Minimum license fee is 0.1 ETH"); // Example fee
        emit ArtworkLicensePurchased(_tokenId, msg.sender, _licenseType);
    }

    /**
     * @dev Initiates a collaborative artwork NFT with multiple artists.
     * @param _artworkName Name of the collaborative artwork.
     * @param _initialDataCID Initial content CID for the artwork.
     * @param _collaborators Array of addresses of collaborating artists.
     */
    function initiateCollaborativeArtwork(string memory _artworkName, string memory _initialDataCID, address[] memory _collaborators) external {
        // In a real implementation, you would mint a special type of NFT for collaborative artworks
        // and manage permissions for collaborators to contribute.
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_artworkName, block.timestamp, msg.sender))); // Example tokenId
        emit CollaborativeArtworkInitiated(tokenId, _artworkName, _collaborators);
    }

    /**
     * @dev Allows collaborators to contribute to a collaborative artwork, updating its metadata.
     * @param _tokenId The ID of the collaborative artwork NFT.
     * @param _contributionCID CID of the contribution (e.g., updated artwork file or metadata).
     */
    function contributeToCollaborativeArtwork(uint256 _tokenId, string memory _contributionCID) external {
        // In a real implementation, you would verify that msg.sender is a collaborator and update the NFT metadata.
        // For simplicity, we just emit an event.
        emit CollaborativeArtworkContribution(_tokenId, msg.sender, _contributionCID);
    }

    /**
     * @dev Allows users who staked tokens for a popular exhibition space to redeem rewards.
     *      Conceptual feature - reward mechanism not fully defined.
     * @param _spaceId The ID of the gallery space.
     */
    function redeemExhibitionReward(uint256 _spaceId) external {
        // In a real implementation, you would track user staking for spaces and calculate rewards based on popularity.
        // For simplicity, we'll just simulate a reward and emit an event.
        uint256 rewardAmount = 0.05 ether; // Example reward
        payable(msg.sender).transfer(rewardAmount);
        emit ExhibitionRewardRedeemed(_spaceId, msg.sender, rewardAmount);
    }

    /**
     * @dev Propose a community curated playlist of artworks for a specific space.
     * @param _spaceId The ID of the gallery space.
     * @param _artworkTokenIds Array of artwork token IDs to be included in the playlist.
     */
    function proposeCommunityCuratedPlaylist(uint256 _spaceId, uint256[] memory _artworkTokenIds) external onlyDAOMembers {
        require(gallerySpaces[_spaceId].name.length > 0, "Gallery space does not exist"); // Check if space exists

        playlistProposals[nextPlaylistProposalId] = PlaylistProposal({
            spaceId: _spaceId,
            artworkTokenIds: _artworkTokenIds,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposalDeadline: block.timestamp + exhibitionVotingPeriod // Reuse exhibition voting period for playlist
        });
        emit CommunityPlaylistProposed(nextPlaylistProposalId, _spaceId, msg.sender);
        nextPlaylistProposalId++;
    }

    struct PlaylistProposal {
        uint256 spaceId;
        uint256[] artworkTokenIds;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 proposalDeadline;
    }
    mapping(uint256 => PlaylistProposal) public playlistProposals;
    uint256 public nextPlaylistProposalId = 1;

    /**
     * @dev DAO members vote on community curated playlist proposals.
     * @param _playlistProposalId The ID of the playlist proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnPlaylistProposal(uint256 _playlistProposalId, bool _approve) external onlyDAOMembers {
        require(!playlistProposals[_playlistProposalId].executed, "Playlist proposal already executed");
        require(block.timestamp < playlistProposals[_playlistProposalId].proposalDeadline, "Voting period expired");

        if (_approve) {
            playlistProposals[_playlistProposalId].votesFor++;
        } else {
            playlistProposals[_playlistProposalId].votesAgainst++;
        }
        emit PlaylistProposalVoted(_playlistProposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes an approved playlist proposal, setting the artwork order in a space.
     * @param _playlistProposalId The ID of the playlist proposal.
     */
    function executePlaylistProposal(uint256 _playlistProposalId) external onlyDAOMembers {
        require(!playlistProposals[_playlistProposalId].executed, "Playlist proposal already executed");
        require(block.timestamp >= playlistProposals[_playlistProposalId].proposalDeadline, "Voting period not expired");
        require(playlistProposals[_playlistProposalId].votesFor > playlistProposals[_playlistProposalId].votesAgainst, "Playlist proposal not approved by majority");

        uint256 spaceId = playlistProposals[_playlistProposalId].spaceId;
        uint256[] storage artworkPlaylist = gallerySpaces[spaceId].exhibitedArtworks;

        // Clear existing artworks and set the new playlist
        delete gallerySpaces[spaceId].exhibitedArtworks; // Clear array in storage
        gallerySpaces[spaceId].exhibitedArtworks = playlistProposals[_playlistProposalId].artworkTokenIds;


        playlistProposals[_playlistProposalId].executed = true;
        emit PlaylistExecuted(_playlistProposalId, spaceId);
    }

    // --- Fallback and Receive (Optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```