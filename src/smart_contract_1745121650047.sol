```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a decentralized art gallery,
 *      incorporating advanced concepts like dynamic pricing, curated exhibitions,
 *      artist reputation, and DAO-governed features.
 *
 * Outline:
 * --------------------------------------------------------------------
 * 1.  **Core Data Structures:**
 *     - ArtPiece struct: Represents an artwork with metadata, pricing, and curation status.
 *     - Artist struct: Stores artist information, reputation score, and registration details.
 *     - Exhibition struct:  Defines curated exhibitions with specific themes and art selections.
 *     - GalleryUpgradeProposal struct:  For DAO-governed gallery feature upgrades.
 *
 * 2.  **Artist Management Functions:**
 *     - registerArtist(): Allows artists to register with the gallery.
 *     - submitArtPiece(): Artists submit their artwork for potential gallery inclusion.
 *     - adjustArtPrice(): Artists can dynamically adjust the price of their uncurated artwork.
 *     - withdrawArtistFunds(): Artists can withdraw their earnings from art sales.
 *     - updateArtMetadata(): Artists can update metadata of their submitted artwork (before curation).
 *     - reportArtPiece(): Users can report inappropriate or violating art pieces.
 *
 * 3.  **Gallery Curation and Exhibition Functions:**
 *     - proposeArtCuration():  DAO members propose art pieces for gallery curation.
 *     - voteOnCurationProposal(): DAO members vote on art curation proposals.
 *     - executeCuration(): Executes curation if proposal passes, marking art as 'curated'.
 *     - createExhibition(): DAO can create themed exhibitions, selecting curated art.
 *     - addArtToExhibition(): DAO can add curated art to existing exhibitions.
 *     - removeArtFromExhibition(): DAO can remove art from exhibitions.
 *     - viewExhibitionDetails(): View details of a specific exhibition.
 *     - listExhibitionArtPieces(): List all art pieces in a specific exhibition.
 *
 * 4.  **Art Purchase and Revenue Functions:**
 *     - purchaseArtPiece(): Users can purchase curated art pieces.
 *     - purchaseExhibitionPass(): Users can purchase a pass to access premium exhibitions (optional feature).
 *     - setGalleryFeePercentage(): DAO can set the gallery commission fee percentage.
 *     - setArtistRoyaltyPercentage(): DAO can set the artist royalty percentage on secondary sales.
 *     - withdrawGalleryFunds(): Gallery owner/DAO can withdraw accumulated gallery fees.
 *
 * 5.  **DAO Governance and Upgrade Functions:**
 *     - proposeGalleryUpgrade(): DAO members propose upgrades to gallery features or parameters.
 *     - voteOnUpgradeProposal(): DAO members vote on gallery upgrade proposals.
 *     - executeUpgrade(): Executes gallery upgrade if proposal passes.
 *     - setCurationThresholdPercentage(): DAO can set the percentage of votes required for curation.
 *     - setVotingDuration(): DAO can set the voting duration for proposals.
 *     - setTreasuryAddress(): DAO can change the treasury address for gallery funds.
 *
 * 6.  **Reputation and Moderation Functions:**
 *     - upvoteArtist(): DAO members can upvote artists to increase their reputation.
 *     - downvoteArtist(): DAO members can downvote artists (with moderation implications).
 *     - moderateReportedArt(): DAO can moderate reported art pieces (e.g., remove from gallery).
 *     - setModerationThreshold(): DAO can set the threshold for automatic moderation actions.
 *
 * 7.  **Utility and View Functions:**
 *     - getArtPieceDetails(): Retrieve detailed information about an art piece.
 *     - getArtistDetails(): Retrieve details about a registered artist.
 *     - getCuratedArtPieces(): List all currently curated art pieces.
 *     - getPendingCurationProposals(): List all pending art curation proposals.
 *     - getGalleryBalance(): View the current balance of the gallery contract.
 *     - getArtistBalance(): View the available balance for a specific artist.
 *     - isArtCurated(): Check if an art piece is curated.
 *     - isArtistRegistered(): Check if an address is a registered artist.
 *     - getExhibitionCount(): Get the total number of exhibitions.
 *     - getUpgradeProposalCount(): Get the total number of upgrade proposals.
 *
 * --------------------------------------------------------------------
 */

contract DecentralizedAutonomousArtGallery {
    // --- Structs ---

    struct ArtPiece {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash; // IPFS hash for the artwork data
        uint256 price; // Price in Wei
        bool isCurated;
        uint256 submissionTimestamp;
        uint256 lastPriceUpdateTimestamp;
        uint256 reportCount;
    }

    struct Artist {
        address artistAddress;
        string artistName;
        uint256 registrationTimestamp;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        uint256 creationTimestamp;
        uint256[] artPieceIds; // Array of curated art piece IDs in this exhibition
        bool isActive;
    }

    struct GalleryUpgradeProposal {
        uint256 id;
        string description;
        uint256 proposalTimestamp;
        uint256 voteCount;
        uint256 againstVoteCount;
        bool isExecuted;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    address public galleryOwner; // Address of the gallery owner (initially DAO controller)
    address public treasuryAddress; // Address to receive gallery fees
    address public daoTokenAddress; // Address of the DAO governance token (if applicable)

    mapping(uint256 => ArtPiece) public artPieces;
    mapping(address => Artist) public artists;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => GalleryUpgradeProposal) public galleryUpgradeProposals;

    uint256 public artPieceCounter;
    uint256 public artistCounter;
    uint256 public exhibitionCounter;
    uint256 public upgradeProposalCounter;

    uint256 public galleryFeePercentage = 5; // Default gallery fee percentage (5%)
    uint256 public artistRoyaltyPercentage = 10; // Default artist royalty on secondary sales (10%)
    uint256 public curationThresholdPercentage = 60; // Percentage of votes needed for curation (60%)
    uint256 public moderationThreshold = 5; // Number of reports needed for moderation consideration
    uint256 public votingDuration = 7 days; // Default voting duration for proposals

    bool public isGalleryActive = true; // Global gallery active/inactive state

    // --- Events ---

    event ArtistRegistered(address artistAddress, string artistName, uint256 timestamp);
    event ArtPieceSubmitted(uint256 artPieceId, address artist, string title, uint256 timestamp);
    event ArtPriceAdjusted(uint256 artPieceId, uint256 newPrice, address artist, uint256 timestamp);
    event ArtCurationProposed(uint256 proposalId, uint256 artPieceId, address proposer, uint256 timestamp);
    event CurationVoteCasted(uint256 proposalId, address voter, bool vote, uint256 timestamp);
    event ArtCurated(uint256 artPieceId, uint256 timestamp);
    event ArtPurchased(uint256 artPieceId, address buyer, uint256 price, address artist, uint256 galleryFee, uint256 artistEarning, uint256 timestamp);
    event ExhibitionCreated(uint256 exhibitionId, string name, uint256 timestamp);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artPieceId, uint256 timestamp);
    event GalleryUpgradeProposed(uint256 proposalId, string description, uint256 timestamp);
    event UpgradeVoteCasted(uint256 proposalId, address voter, bool vote, uint256 timestamp);
    event GalleryUpgraded(uint256 proposalId, uint256 timestamp);
    event ArtistUpvoted(address artistAddress, address upvoter, uint256 timestamp);
    event ArtistDownvoted(address artistAddress, address downvoter, uint256 timestamp);
    event ArtPieceReported(uint256 artPieceId, address reporter, uint256 timestamp);
    event ArtPieceModerated(uint256 artPieceId, uint256 timestamp);
    event GalleryFeePercentageUpdated(uint256 newFeePercentage, address daoAddress, uint256 timestamp);
    event ArtistRoyaltyPercentageUpdated(uint256 newRoyaltyPercentage, address daoAddress, uint256 timestamp);
    event CurationThresholdPercentageUpdated(uint256 newThresholdPercentage, address daoAddress, uint256 timestamp);
    event VotingDurationUpdated(uint256 newVotingDuration, address daoAddress, uint256 timestamp);
    event TreasuryAddressUpdated(address newTreasuryAddress, address daoAddress, uint256 timestamp);
    event GalleryStateChanged(bool isActive, address admin, uint256 timestamp);


    // --- Modifiers ---

    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artists[msg.sender].isRegistered, "Only registered artists can call this function.");
        _;
    }

    modifier onlyCuratedArt(uint256 _artPieceId) {
        require(artPieces[_artPieceId].isCurated, "Art piece must be curated to perform this action.");
        _;
    }

    modifier onlyPendingCuration(uint256 _proposalId) {
        require(!galleryUpgradeProposals[_proposalId].isExecuted, "Proposal already executed.");
        require(block.timestamp <= galleryUpgradeProposals[_proposalId].proposalTimestamp + votingDuration, "Voting duration expired.");
        _;
    }

    modifier onlyActiveGallery() {
        require(isGalleryActive, "Gallery is currently inactive.");
        _;
    }

    modifier isWithinVotingDuration(uint256 _proposalId) {
        require(block.timestamp <= galleryUpgradeProposals[_proposalId].proposalTimestamp + votingDuration, "Voting duration expired.");
        _;
    }


    // --- Constructor ---
    constructor(address _treasuryAddress) {
        galleryOwner = msg.sender; // Deployer is initial gallery owner (can be DAO later)
        treasuryAddress = _treasuryAddress;
    }

    // --- 1. Artist Management Functions ---

    /// @notice Registers a new artist in the gallery.
    /// @param _artistName The name of the artist.
    function registerArtist(string memory _artistName) external onlyActiveGallery {
        require(!artists[msg.sender].isRegistered, "Artist already registered.");
        artistCounter++;
        artists[msg.sender] = Artist({
            artistAddress: msg.sender,
            artistName: _artistName,
            registrationTimestamp: block.timestamp,
            reputationScore: 0,
            isRegistered: true
        });
        emit ArtistRegistered(msg.sender, _artistName, block.timestamp);
    }

    /// @notice Allows registered artists to submit their artwork for potential gallery inclusion.
    /// @param _title The title of the artwork.
    /// @param _description A brief description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's digital content.
    /// @param _price The initial price of the artwork in Wei.
    function submitArtPiece(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _price
    ) external onlyRegisteredArtist onlyActiveGallery {
        artPieceCounter++;
        artPieces[artPieceCounter] = ArtPiece({
            id: artPieceCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            price: _price,
            isCurated: false,
            submissionTimestamp: block.timestamp,
            lastPriceUpdateTimestamp: block.timestamp,
            reportCount: 0
        });
        emit ArtPieceSubmitted(artPieceCounter, msg.sender, _title, block.timestamp);
    }

    /// @notice Allows artists to adjust the price of their artwork before it is curated.
    /// @param _artPieceId The ID of the art piece to adjust.
    /// @param _newPrice The new price of the artwork in Wei.
    function adjustArtPrice(uint256 _artPieceId, uint256 _newPrice) external onlyRegisteredArtist onlyActiveGallery {
        require(artPieces[_artPieceId].artist == msg.sender, "You are not the artist of this piece.");
        require(!artPieces[_artPieceId].isCurated, "Cannot adjust price of curated artwork.");
        artPieces[_artPieceId].price = _newPrice;
        artPieces[_artPieceId].lastPriceUpdateTimestamp = block.timestamp;
        emit ArtPriceAdjusted(_artPieceId, _newPrice, msg.sender, block.timestamp);
    }

    /// @notice Allows artists to withdraw their earned funds from art sales.
    function withdrawArtistFunds() external onlyRegisteredArtist onlyActiveGallery {
        // In a real implementation, track artist balances separately and implement withdrawal logic.
        // For simplicity in this example, we assume direct payment on purchase.
        // This function would typically transfer funds from the contract to the artist.
        // Placeholder: Implement fund tracking and withdrawal logic here.
        revert("Withdrawal functionality not fully implemented in this example.");
    }

    /// @notice Allows artists to update the metadata (title, description, IPFS hash) of their submitted artwork before curation.
    /// @param _artPieceId The ID of the art piece to update.
    /// @param _newTitle The new title of the artwork.
    /// @param _newDescription The new description of the artwork.
    /// @param _newIpfsHash The new IPFS hash of the artwork's digital content.
    function updateArtMetadata(
        uint256 _artPieceId,
        string memory _newTitle,
        string memory _newDescription,
        string memory _newIpfsHash
    ) external onlyRegisteredArtist onlyActiveGallery {
        require(artPieces[_artPieceId].artist == msg.sender, "You are not the artist of this piece.");
        require(!artPieces[_artPieceId].isCurated, "Cannot update metadata of curated artwork.");
        artPieces[_artPieceId].title = _newTitle;
        artPieces[_artPieceId].description = _newDescription;
        artPieces[_artPieceId].ipfsHash = _newIpfsHash;
    }

    /// @notice Allows users to report an art piece for inappropriate content or policy violations.
    /// @param _artPieceId The ID of the art piece to report.
    function reportArtPiece(uint256 _artPieceId) external onlyActiveGallery {
        artPieces[_artPieceId].reportCount++;
        emit ArtPieceReported(_artPieceId, msg.sender, block.timestamp);
        if (artPieces[_artPieceId].reportCount >= moderationThreshold) {
            // Trigger moderation process (e.g., notify DAO for review).
            // For this example, we just emit an event.
            emit ArtPieceModerated(_artPieceId, block.timestamp);
            // In a real implementation, DAO would review and potentially remove the art piece from gallery etc.
        }
    }


    // --- 2. Gallery Curation and Exhibition Functions ---

    /// @notice Allows DAO members to propose an art piece for gallery curation.
    /// @param _artPieceId The ID of the art piece to propose for curation.
    function proposeArtCuration(uint256 _artPieceId) external onlyActiveGallery {
        require(!artPieces[_artPieceId].isCurated, "Art piece is already curated.");
        upgradeProposalCounter++; // Reuse upgrade proposal counter for curation proposals for simplicity
        galleryUpgradeProposals[upgradeProposalCounter] = GalleryUpgradeProposal({
            id: upgradeProposalCounter,
            description: string(abi.encodePacked("Curation Proposal for Art Piece ID: ", uint2str(_artPieceId))), // Simple description
            proposalTimestamp: block.timestamp,
            voteCount: 0,
            againstVoteCount: 0,
            isExecuted: false,
            hasVoted: mapping(address => bool)()
        });
        emit ArtCurationProposed(upgradeProposalCounter, _artPieceId, msg.sender, block.timestamp);
    }

    // Helper function to convert uint to string (basic implementation, consider libraries for production)
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }


    /// @notice Allows DAO members to vote on an art curation proposal.
    /// @param _proposalId The ID of the curation proposal.
    /// @param _vote Boolean value representing the vote (true for yes, false for no).
    function voteOnCurationProposal(uint256 _proposalId, bool _vote) external onlyActiveGallery isWithinVotingDuration(_proposalId) {
        require(!galleryUpgradeProposals[_proposalId].hasVoted[msg.sender], "Already voted on this proposal.");
        galleryUpgradeProposals[_proposalId].hasVoted[msg.sender] = true;
        if (_vote) {
            galleryUpgradeProposals[_proposalId].voteCount++;
        } else {
            galleryUpgradeProposals[_proposalId].againstVoteCount++;
        }
        emit CurationVoteCasted(_proposalId, msg.sender, _vote, block.timestamp);
    }

    /// @notice Executes a curation proposal if it has reached the required threshold.
    /// @param _proposalId The ID of the curation proposal to execute.
    /// @param _artPieceId The ID of the art piece being curated (retrieve from proposal description).
    function executeCuration(uint256 _proposalId, uint256 _artPieceId) external onlyActiveGallery onlyPendingCuration(_proposalId) {
        uint256 totalVotes = galleryUpgradeProposals[_proposalId].voteCount + galleryUpgradeProposals[_proposalId].againstVoteCount;
        require(totalVotes > 0, "No votes cast on this proposal.");
        uint256 curationPercentage = (galleryUpgradeProposals[_proposalId].voteCount * 100) / totalVotes;
        require(curationPercentage >= curationThresholdPercentage, "Curation proposal did not reach threshold.");
        require(!artPieces[_artPieceId].isCurated, "Art piece is already curated.");

        artPieces[_artPieceId].isCurated = true;
        galleryUpgradeProposals[_proposalId].isExecuted = true;
        emit ArtCurated(_artPieceId, block.timestamp);
    }


    /// @notice Allows DAO to create a themed exhibition of curated art pieces.
    /// @param _name The name of the exhibition.
    /// @param _description A description of the exhibition theme.
    function createExhibition(string memory _name, string memory _description) external onlyGalleryOwner onlyActiveGallery {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            id: exhibitionCounter,
            name: _name,
            description: _description,
            creationTimestamp: block.timestamp,
            artPieceIds: new uint256[](0), // Initialize with empty array
            isActive: true
        });
        emit ExhibitionCreated(exhibitionCounter, _name, block.timestamp);
    }

    /// @notice Allows DAO to add a curated art piece to an existing exhibition.
    /// @param _exhibitionId The ID of the exhibition to add art to.
    /// @param _artPieceId The ID of the curated art piece to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artPieceId) external onlyGalleryOwner onlyActiveGallery onlyCuratedArt(_artPieceId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artPieceIds.length; i++) {
            if (exhibitions[_exhibitionId].artPieceIds[i] == _artPieceId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "Art piece already in this exhibition.");

        exhibitions[_exhibitionId].artPieceIds.push(_artPieceId);
        emit ArtAddedToExhibition(_exhibitionId, _artPieceId, block.timestamp);
    }

    /// @notice Allows DAO to remove an art piece from an exhibition.
    /// @param _exhibitionId The ID of the exhibition to remove art from.
    /// @param _artPieceId The ID of the art piece to remove.
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artPieceId) external onlyGalleryOwner onlyActiveGallery {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        bool found = false;
        uint256 indexToRemove;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artPieceIds.length; i++) {
            if (exhibitions[_exhibitionId].artPieceIds[i] == _artPieceId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }
        require(found, "Art piece not found in this exhibition.");

        // Remove art piece ID from the array (shift elements to the left)
        for (uint256 i = indexToRemove; i < exhibitions[_exhibitionId].artPieceIds.length - 1; i++) {
            exhibitions[_exhibitionId].artPieceIds[i] = exhibitions[_exhibitionId].artPieceIds[i + 1];
        }
        exhibitions[_exhibitionId].artPieceIds.pop(); // Remove the last element (duplicate)
        // No event emitted for removal in this example, could be added.
    }

    /// @notice Allows anyone to view details of a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition to view.
    /// @return Exhibition struct containing exhibition details.
    function viewExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        require(exhibitions[_exhibitionId].id == _exhibitionId, "Exhibition not found."); // Basic check
        return exhibitions[_exhibitionId];
    }

    /// @notice Allows anyone to list all art pieces in a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Array of art piece IDs in the exhibition.
    function listExhibitionArtPieces(uint256 _exhibitionId) external view returns (uint256[] memory) {
        require(exhibitions[_exhibitionId].id == _exhibitionId, "Exhibition not found."); // Basic check
        return exhibitions[_exhibitionId].artPieceIds;
    }


    // --- 3. Art Purchase and Revenue Functions ---

    /// @notice Allows users to purchase a curated art piece.
    /// @param _artPieceId The ID of the curated art piece to purchase.
    function purchaseArtPiece(uint256 _artPieceId) external payable onlyActiveGallery onlyCuratedArt(_artPieceId) {
        require(msg.value >= artPieces[_artPieceId].price, "Insufficient funds sent.");
        uint256 galleryFee = (artPieces[_artPieceId].price * galleryFeePercentage) / 100;
        uint256 artistEarning = artPieces[_artPieceId].price - galleryFee;

        // Transfer funds
        payable(artPieces[_artPieceId].artist).transfer(artistEarning);
        payable(treasuryAddress).transfer(galleryFee); // Send gallery fee to treasury

        emit ArtPurchased(_artPieceId, msg.sender, artPieces[_artPieceId].price, artPieces[_artPieceId].artist, galleryFee, artistEarning, block.timestamp);
    }

    /// @notice Allows DAO to set the gallery commission fee percentage.
    /// @param _newPercentage The new gallery fee percentage (e.g., 5 for 5%).
    function setGalleryFeePercentage(uint256 _newPercentage) external onlyGalleryOwner onlyActiveGallery {
        require(_newPercentage <= 100, "Fee percentage cannot exceed 100%.");
        galleryFeePercentage = _newPercentage;
        emit GalleryFeePercentageUpdated(_newPercentage, msg.sender, block.timestamp);
    }

    /// @notice Allows DAO to set the artist royalty percentage on secondary sales (not implemented in this basic example).
    /// @param _newPercentage The new artist royalty percentage (e.g., 10 for 10%).
    function setArtistRoyaltyPercentage(uint256 _newPercentage) external onlyGalleryOwner onlyActiveGallery {
        require(_newPercentage <= 100, "Royalty percentage cannot exceed 100%.");
        artistRoyaltyPercentage = _newPercentage;
        emit ArtistRoyaltyPercentageUpdated(_newPercentage, msg.sender, block.timestamp);
    }

    /// @notice Allows gallery owner/DAO to withdraw accumulated gallery fees from the contract balance.
    function withdrawGalleryFunds() external onlyGalleryOwner onlyActiveGallery {
        uint256 balance = address(this).balance;
        payable(treasuryAddress).transfer(balance); // Transfer all contract balance to treasury
        // In a more robust system, track gallery earnings separately and allow partial withdrawals.
    }


    // --- 4. DAO Governance and Upgrade Functions ---

    /// @notice Allows DAO members to propose an upgrade to gallery features or parameters.
    /// @param _description A description of the proposed upgrade.
    function proposeGalleryUpgrade(string memory _description) external onlyGalleryOwner onlyActiveGallery { // Assuming only DAO controller can propose upgrades
        upgradeProposalCounter++;
        galleryUpgradeProposals[upgradeProposalCounter] = GalleryUpgradeProposal({
            id: upgradeProposalCounter,
            description: _description,
            proposalTimestamp: block.timestamp,
            voteCount: 0,
            againstVoteCount: 0,
            isExecuted: false,
            hasVoted: mapping(address => bool)()
        });
        emit GalleryUpgradeProposed(upgradeProposalCounter, _description, block.timestamp);
    }

    /// @notice Allows DAO members to vote on a gallery upgrade proposal.
    /// @param _proposalId The ID of the upgrade proposal.
    /// @param _vote Boolean value representing the vote (true for yes, false for no).
    function voteOnUpgradeProposal(uint256 _proposalId, bool _vote) external onlyGalleryOwner onlyActiveGallery isWithinVotingDuration(_proposalId) { // Assuming only DAO controller members can vote
        require(!galleryUpgradeProposals[_proposalId].hasVoted[msg.sender], "Already voted on this proposal.");
        galleryUpgradeProposals[_proposalId].hasVoted[msg.sender] = true;
        if (_vote) {
            galleryUpgradeProposals[_proposalId].voteCount++;
        } else {
            galleryUpgradeProposals[_proposalId].againstVoteCount++;
        }
        emit UpgradeVoteCasted(_proposalId, msg.sender, _vote, block.timestamp);
    }

    /// @notice Executes a gallery upgrade proposal if it has reached the required threshold.
    /// @param _proposalId The ID of the upgrade proposal to execute.
    function executeUpgrade(uint256 _proposalId) external onlyGalleryOwner onlyActiveGallery onlyPendingCuration(_proposalId) { // Reusing onlyPendingCuration modifier
        uint256 totalVotes = galleryUpgradeProposals[_proposalId].voteCount + galleryUpgradeProposals[_proposalId].againstVoteCount;
        require(totalVotes > 0, "No votes cast on this proposal.");
        uint256 upgradePercentage = (galleryUpgradeProposals[_proposalId].voteCount * 100) / totalVotes;
        require(upgradePercentage >= curationThresholdPercentage, "Upgrade proposal did not reach threshold."); // Reusing curation threshold for upgrade for simplicity

        galleryUpgradeProposals[_proposalId].isExecuted = true;
        emit GalleryUpgraded(_proposalId, block.timestamp);
        // Implement the actual upgrade logic here based on the proposal description.
        // Example upgrades could include changing parameters, adding features, etc.
        // For simplicity, no specific upgrade logic is implemented in this example, just marking as executed.
    }

    /// @notice Allows DAO to set the percentage of votes required for art curation proposals to pass.
    /// @param _newPercentage The new curation threshold percentage (e.g., 70 for 70%).
    function setCurationThresholdPercentage(uint256 _newPercentage) external onlyGalleryOwner onlyActiveGallery {
        require(_newPercentage <= 100, "Curation threshold cannot exceed 100%.");
        curationThresholdPercentage = _newPercentage;
        emit CurationThresholdPercentageUpdated(_newPercentage, msg.sender, block.timestamp);
    }

    /// @notice Allows DAO to set the voting duration for proposals (in seconds).
    /// @param _newDuration The new voting duration in seconds.
    function setVotingDuration(uint256 _newDuration) external onlyGalleryOwner onlyActiveGallery {
        votingDuration = _newDuration;
        emit VotingDurationUpdated(_newDuration, msg.sender, block.timestamp);
    }

    /// @notice Allows DAO to change the treasury address where gallery fees are sent.
    /// @param _newTreasuryAddress The new treasury address.
    function setTreasuryAddress(address _newTreasuryAddress) external onlyGalleryOwner onlyActiveGallery {
        require(_newTreasuryAddress != address(0), "Invalid treasury address.");
        treasuryAddress = _newTreasuryAddress;
        emit TreasuryAddressUpdated(_newTreasuryAddress, msg.sender, block.timestamp);
    }


    // --- 5. Reputation and Moderation Functions ---

    /// @notice Allows DAO members to upvote an artist, increasing their reputation score.
    /// @param _artistAddress The address of the artist to upvote.
    function upvoteArtist(address _artistAddress) external onlyGalleryOwner onlyActiveGallery { // Assuming only DAO members can upvote
        artists[_artistAddress].reputationScore++;
        emit ArtistUpvoted(_artistAddress, msg.sender, block.timestamp);
    }

    /// @notice Allows DAO members to downvote an artist, potentially decreasing their reputation score (with moderation implications).
    /// @param _artistAddress The address of the artist to downvote.
    function downvoteArtist(address _artistAddress) external onlyGalleryOwner onlyActiveGallery { // Assuming only DAO members can downvote
        artists[_artistAddress].reputationScore--; // Simple decrement, more complex moderation logic can be added
        emit ArtistDownvoted(_artistAddress, msg.sender, block.timestamp);
        // In a real system, downvotes might trigger moderation reviews, temporary bans etc.
    }

    /// @notice Allows DAO to manually moderate a reported art piece (e.g., remove it from the gallery, hide it).
    /// @param _artPieceId The ID of the art piece to moderate.
    function moderateReportedArt(uint256 _artPieceId) external onlyGalleryOwner onlyActiveGallery { // Assuming only DAO can moderate
        // Implement moderation logic here. For example, set artPiece as 'hidden' or remove from exhibitions.
        // For simplicity, we just reset report count and emit event in this example.
        artPieces[_artPieceId].reportCount = 0; // Reset report count after moderation
        emit ArtPieceModerated(_artPieceId, block.timestamp);
        // Real moderation might involve more complex actions and record keeping.
    }

    /// @notice Allows DAO to set the threshold for automatic moderation actions based on report count.
    /// @param _newThreshold The new moderation threshold (number of reports needed).
    function setModerationThreshold(uint256 _newThreshold) external onlyGalleryOwner onlyActiveGallery {
        moderationThreshold = _newThreshold;
        // emit event if needed
    }

    /// @notice Allows gallery owner to temporarily stop or resume gallery operations in emergency situations.
    /// @param _isActive Boolean value to set gallery activity state (true for active, false for inactive).
    function setGalleryActiveState(bool _isActive) external onlyGalleryOwner {
        isGalleryActive = _isActive;
        emit GalleryStateChanged(_isActive, msg.sender, block.timestamp);
    }


    // --- 6. Utility and View Functions ---

    /// @notice Retrieves detailed information about a specific art piece.
    /// @param _artPieceId The ID of the art piece.
    /// @return ArtPiece struct containing art piece details.
    function getArtPieceDetails(uint256 _artPieceId) external view returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    /// @notice Retrieves details about a registered artist.
    /// @param _artistAddress The address of the artist.
    /// @return Artist struct containing artist details.
    function getArtistDetails(address _artistAddress) external view returns (Artist memory) {
        return artists[_artistAddress];
    }

    /// @notice Lists all currently curated art pieces.
    /// @return Array of art piece IDs that are curated.
    function getCuratedArtPieces() external view returns (uint256[] memory) {
        uint256[] memory curatedArtIds = new uint256[](artPieceCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= artPieceCounter; i++) {
            if (artPieces[i].isCurated) {
                curatedArtIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of curated pieces
        assembly {
            mstore(curatedArtIds, count) // Update array length in memory
        }
        return curatedArtIds;
    }

    /// @notice Lists all pending art curation proposals.
    /// @return Array of proposal IDs for pending curation proposals.
    function getPendingCurationProposals() external view returns (uint256[] memory) {
        uint256[] memory pendingProposals = new uint256[](upgradeProposalCounter); // Max possible size (reuse counter)
        uint256 count = 0;
        for (uint256 i = 1; i <= upgradeProposalCounter; i++) {
            if (!galleryUpgradeProposals[i].isExecuted && block.timestamp <= galleryUpgradeProposals[i].proposalTimestamp + votingDuration) {
                pendingProposals[count] = i;
                count++;
            }
        }
        // Resize array
        assembly {
            mstore(pendingProposals, count)
        }
        return pendingProposals;
    }

    /// @notice Gets the current balance of the gallery contract.
    /// @return The contract balance in Wei.
    function getGalleryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the available balance for a specific artist (placeholder, needs actual balance tracking).
    /// @param _artistAddress The address of the artist.
    /// @return The artist's balance in Wei (placeholder 0 in this example).
    function getArtistBalance(address _artistAddress) external view returns (uint256) {
        // In a real implementation, track artist balances and return the balance here.
        // For this example, placeholder returning 0.
        return 0; // Placeholder
    }

    /// @notice Checks if an art piece is curated.
    /// @param _artPieceId The ID of the art piece.
    /// @return True if the art piece is curated, false otherwise.
    function isArtCurated(uint256 _artPieceId) external view returns (bool) {
        return artPieces[_artPieceId].isCurated;
    }

    /// @notice Checks if an address is a registered artist.
    /// @param _artistAddress The address to check.
    /// @return True if the address is a registered artist, false otherwise.
    function isArtistRegistered(address _artistAddress) external view returns (bool) {
        return artists[_artistAddress].isRegistered;
    }

    /// @notice Gets the total number of exhibitions created.
    /// @return The total exhibition count.
    function getExhibitionCount() external view returns (uint256) {
        return exhibitionCounter;
    }

    /// @notice Gets the total number of gallery upgrade proposals created.
    /// @return The total upgrade proposal count.
    function getUpgradeProposalCount() external view returns (uint256) {
        return upgradeProposalCounter;
    }
}
```