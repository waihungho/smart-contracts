```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) Smart Contract
 * @author Your Name or Organization Name
 * @notice This contract implements a decentralized autonomous art gallery where artists can submit their artwork (NFTs),
 *         the community can vote on submissions, and accepted artworks are showcased in the gallery.
 *         The contract also features decentralized curation, exhibition management, artist rewards, and community governance
 *         through proposals and voting, going beyond basic NFT marketplaces and incorporating DAO principles.
 *
 * **Outline:**
 * ------------------------------------------------------------------------------------------------------
 * **1. NFT Management & Artwork Submission:**
 *    - `submitArtwork(string _artworkURI)`: Artists submit artwork NFTs with metadata URI for review.
 *    - `getSubmittedArtwork(uint256 _submissionId)`: Retrieve details of a submitted artwork.
 *    - `getSubmittedArtworkCount()`: Get the total number of artwork submissions.
 *
 * **2. Decentralized Curation & Voting:**
 *    - `startArtworkVoting(uint256 _submissionId, uint256 _votingDuration)`: Start voting for a submitted artwork.
 *    - `voteForArtwork(uint256 _submissionId, bool _approve)`: Voters cast their vote (approve/reject) for an artwork.
 *    - `endArtworkVoting(uint256 _submissionId)`: End the voting period and process results.
 *    - `getVotingStatus(uint256 _submissionId)`: Check the current voting status of an artwork.
 *    - `getVoteCount(uint256 _submissionId)`: Get the current vote counts (approve/reject) for an artwork.
 *
 * **3. Gallery Management & Exhibition:**
 *    - `addArtworkToGallery(uint256 _submissionId)`: Add an approved artwork to the gallery.
 *    - `removeArtworkFromGallery(uint256 _artworkId)`: Remove an artwork from the gallery (governance-controlled).
 *    - `startExhibition(string _exhibitionName, uint256[] _artworkIds, uint256 _exhibitionDuration)`: Start a curated exhibition with selected artworks.
 *    - `endExhibition(uint256 _exhibitionId)`: End a running exhibition.
 *    - `getActiveExhibition()`: Get details of the currently active exhibition.
 *    - `getGalleryArtworkIds()`: Get a list of artwork IDs currently in the gallery.
 *    - `getExhibitionArtworkIds(uint256 _exhibitionId)`: Get artwork IDs for a specific exhibition.
 *
 * **4. Artist & Community Rewards:**
 *    - `setArtworkSalePrice(uint256 _artworkId, uint256 _price)`: Artist sets a sale price for their artwork in the gallery.
 *    - `purchaseArtwork(uint256 _artworkId)`: Purchase an artwork from the gallery, rewarding the artist and gallery.
 *    - `withdrawArtistEarnings()`: Artists can withdraw their earnings from artwork sales.
 *
 * **5. Decentralized Governance & Proposals:**
 *    - `createGovernanceProposal(string _proposalDescription, bytes _calldata)`: Community members can create governance proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Community members vote on governance proposals.
 *    - `executeProposal(uint256 _proposalId)`: Execute a successful governance proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: Check the status of a governance proposal.
 *    - `getProposalVoteCount(uint256 _proposalId)`: Get vote counts for a proposal.
 *
 * **Function Summary:**
 * ------------------------------------------------------------------------------------------------------
 * - **Artwork Submission & Retrieval:** Functions for artists to submit their artwork NFTs and retrieve submission details.
 * - **Decentralized Curation:** Functions to initiate and participate in voting processes for artwork acceptance into the gallery.
 * - **Gallery & Exhibition Management:** Functions to manage the gallery's artworks, create and manage exhibitions with curated selections.
 * - **Artist Rewards & Sales:** Functions for artists to set sale prices, enable artwork purchases, and withdraw earnings.
 * - **Decentralized Governance:** Functions for community-driven governance through proposals, voting, and execution of changes.
 * ------------------------------------------------------------------------------------------------------
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedAutonomousArtGallery is Ownable, ERC721Holder, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs & Enums ---
    struct ArtworkSubmission {
        uint256 submissionId;
        address artist;
        string artworkURI;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 approveVotes;
        uint256 rejectVotes;
        bool votingActive;
        bool approved;
        bool inGallery;
    }

    struct GalleryArtwork {
        uint256 artworkId; // Unique ID within the gallery, not NFT token ID
        uint256 submissionId; // ID of the original submission
        address artist;
        string artworkURI;
        uint256 salePrice;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionName;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256[] artworkIds; // GalleryArtwork IDs in this exhibition
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 supportVotes;
        uint256 againstVotes;
        bool votingActive;
        bool executed;
        bytes calldataData; // Calldata to execute if proposal passes
    }

    // --- State Variables ---
    Counters.Counter private _submissionCounter;
    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    uint256[] public submittedArtworkIds; // Track all submission IDs

    Counters.Counter private _galleryArtworkCounter;
    mapping(uint256 => GalleryArtwork) public galleryArtworks;
    uint256[] public galleryArtworkIds; // Track artwork IDs in the gallery

    Counters.Counter private _exhibitionCounter;
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public activeExhibitionId;

    Counters.Counter private _proposalCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256[] public proposalIds;

    mapping(uint256 => mapping(address => bool)) public artworkVotes; // submissionId => voter => approved?
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => supported?

    mapping(address => uint256) public artistEarnings;

    uint256 public votingDuration = 7 days; // Default voting duration for artwork submissions
    uint256 public proposalVotingDuration = 14 days; // Default voting duration for governance proposals
    uint256 public galleryCommissionPercentage = 5; // Percentage commission on artwork sales (e.g., 5% of sale price)

    event ArtworkSubmitted(uint256 submissionId, address artist, string artworkURI);
    event ArtworkVotingStarted(uint256 submissionId, uint256 endTime);
    event ArtworkVoted(uint256 submissionId, address voter, bool approved);
    event ArtworkVotingEnded(uint256 submissionId, bool approved, uint256 approveVotes, uint256 rejectVotes);
    event ArtworkAddedToGallery(uint256 artworkId, uint256 submissionId);
    event ArtworkRemovedFromGallery(uint256 artworkId);
    event ExhibitionStarted(uint256 exhibitionId, string exhibitionName, uint256 startTime, uint256 endTime);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtworkSale(uint256 artworkId, address buyer, uint256 price, address artist, uint256 galleryCommission);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool supported);
    event GovernanceProposalExecuted(uint256 proposalId);

    // --- Modifiers ---
    modifier onlyArtist() {
        require(isArtist(msg.sender), "Only artists can perform this action.");
        _;
    }

    modifier onlyVoter() {
        require(isVoter(msg.sender), "Only voters can perform this action.");
        _;
    }

    modifier onlyGalleryAdmin() {
        require(msg.sender == owner(), "Only gallery admin can perform this action.");
        _;
    }

    modifier submissionExists(uint256 _submissionId) {
        require(artworkSubmissions[_submissionId].submissionId == _submissionId, "Submission does not exist.");
        _;
    }

    modifier artworkInGallery(uint256 _artworkId) {
        require(galleryArtworks[_artworkId].artworkId == _artworkId, "Artwork is not in the gallery.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier votingActiveForSubmission(uint256 _submissionId) {
        require(artworkSubmissions[_submissionId].votingActive, "Voting is not active for this submission.");
        _;
    }

    modifier votingNotActiveForSubmission(uint256 _submissionId) {
        require(!artworkSubmissions[_submissionId].votingActive, "Voting is still active for this submission.");
        _;
    }

    modifier votingActiveForProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].votingActive, "Voting is not active for this proposal.");
        _;
    }

    modifier votingNotActiveForProposal(uint256 _proposalId) {
        require(!governanceProposals[_proposalId].votingActive, "Voting is still active for this proposal.");
        _;
    }


    // --- Artist Role (Simple Example - Can be expanded with more complex logic) ---
    mapping(address => bool) public isArtistRole;

    function addArtistRole(address _artist) external onlyOwner {
        isArtistRole[_artist] = true;
    }

    function removeArtistRole(address _artist) external onlyOwner {
        isArtistRole[_artist] = false;
    }

    function isArtist(address _address) public view returns (bool) {
        return isArtistRole[_address];
    }

    // --- Voter Role (Simple Example - Can be expanded with staking, NFT holding, etc.) ---
    mapping(address => bool) public isVoterRole;

    function addVoterRole(address _voter) external onlyOwner {
        isVoterRole[_voter] = true;
    }

    function removeVoterRole(address _voter) external onlyOwner {
        isVoterRole[_voter] = false;
    }

    function isVoter(address _address) public view returns (bool) {
        return isVoterRole[_address] = true; // Everyone is voter for simplicity, change to isVoterRole[_address] for role-based voting
    }


    // ------------------------------------------------------------------------------------------------------
    // 1. NFT Management & Artwork Submission
    // ------------------------------------------------------------------------------------------------------

    /**
     * @dev Allows artists to submit their artwork for review.
     * @param _artworkURI URI pointing to the artwork's metadata (e.g., IPFS link).
     */
    function submitArtwork(string memory _artworkURI) external onlyArtist {
        _submissionCounter.increment();
        uint256 submissionId = _submissionCounter.current();

        artworkSubmissions[submissionId] = ArtworkSubmission({
            submissionId: submissionId,
            artist: msg.sender,
            artworkURI: _artworkURI,
            votingStartTime: 0,
            votingEndTime: 0,
            approveVotes: 0,
            rejectVotes: 0,
            votingActive: false,
            approved: false,
            inGallery: false
        });
        submittedArtworkIds.push(submissionId);

        emit ArtworkSubmitted(submissionId, msg.sender, _artworkURI);
    }

    /**
     * @dev Retrieves details of a submitted artwork by its submission ID.
     * @param _submissionId The ID of the artwork submission.
     * @return ArtworkSubmission struct containing the submission details.
     */
    function getSubmittedArtwork(uint256 _submissionId) external view submissionExists(_submissionId) returns (ArtworkSubmission memory) {
        return artworkSubmissions[_submissionId];
    }

    /**
     * @dev Returns the total number of artwork submissions received.
     * @return Total count of artwork submissions.
     */
    function getSubmittedArtworkCount() external view returns (uint256) {
        return _submissionCounter.current();
    }


    // ------------------------------------------------------------------------------------------------------
    // 2. Decentralized Curation & Voting
    // ------------------------------------------------------------------------------------------------------

    /**
     * @dev Starts the voting process for a submitted artwork. Only gallery admin can initiate voting.
     * @param _submissionId The ID of the artwork submission to be voted on.
     * @param _votingDuration The duration of the voting period in seconds.
     */
    function startArtworkVoting(uint256 _submissionId, uint256 _votingDuration) external onlyGalleryAdmin submissionExists(_submissionId) votingNotActiveForSubmission(_submissionId) {
        require(!artworkSubmissions[_submissionId].inGallery, "Artwork is already in the gallery.");
        artworkSubmissions[_submissionId].votingActive = true;
        artworkSubmissions[_submissionId].votingStartTime = block.timestamp;
        artworkSubmissions[_submissionId].votingEndTime = block.timestamp + _votingDuration;
        emit ArtworkVotingStarted(_submissionId, artworkSubmissions[_submissionId].votingEndTime);
    }

    /**
     * @dev Allows voters to cast their vote (approve or reject) for a submitted artwork.
     * @param _submissionId The ID of the artwork submission.
     * @param _approve True to approve the artwork, false to reject.
     */
    function voteForArtwork(uint256 _submissionId, bool _approve) external onlyVoter submissionExists(_submissionId) votingActiveForSubmission(_submissionId) {
        require(!artworkVotes[_submissionId][msg.sender], "Voter has already voted for this artwork.");
        artworkVotes[_submissionId][msg.sender] = true; // Mark voter as voted

        if (_approve) {
            artworkSubmissions[_submissionId].approveVotes++;
        } else {
            artworkSubmissions[_submissionId].rejectVotes++;
        }
        emit ArtworkVoted(_submissionId, msg.sender, _approve);
    }

    /**
     * @dev Ends the voting period for a submitted artwork and processes the results.
     *      If approved, the artwork can be added to the gallery by the gallery admin.
     * @param _submissionId The ID of the artwork submission.
     */
    function endArtworkVoting(uint256 _submissionId) external onlyGalleryAdmin submissionExists(_submissionId) votingActiveForSubmission(_submissionId) {
        require(block.timestamp >= artworkSubmissions[_submissionId].votingEndTime, "Voting period is not over yet.");
        artworkSubmissions[_submissionId].votingActive = false;

        if (artworkSubmissions[_submissionId].approveVotes > artworkSubmissions[_submissionId].rejectVotes) {
            artworkSubmissions[_submissionId].approved = true;
        } else {
            artworkSubmissions[_submissionId].approved = false;
        }
        emit ArtworkVotingEnded(_submissionId, artworkSubmissions[_submissionId].approved, artworkSubmissions[_submissionId].approveVotes, artworkSubmissions[_submissionId].rejectVotes);
    }

    /**
     * @dev Checks the current voting status of a submitted artwork.
     * @param _submissionId The ID of the artwork submission.
     * @return True if voting is active, false otherwise.
     */
    function getVotingStatus(uint256 _submissionId) external view submissionExists(_submissionId) returns (bool) {
        return artworkSubmissions[_submissionId].votingActive;
    }

    /**
     * @dev Gets the current approve and reject vote counts for a submitted artwork.
     * @param _submissionId The ID of the artwork submission.
     * @return approveCount The number of approve votes.
     * @return rejectCount The number of reject votes.
     */
    function getVoteCount(uint256 _submissionId) external view submissionExists(_submissionId) returns (uint256 approveCount, uint256 rejectCount) {
        return (artworkSubmissions[_submissionId].approveVotes, artworkSubmissions[_submissionId].rejectVotes);
    }


    // ------------------------------------------------------------------------------------------------------
    // 3. Gallery Management & Exhibition
    // ------------------------------------------------------------------------------------------------------

    /**
     * @dev Adds an approved artwork to the gallery. Only gallery admin can perform this action.
     * @param _submissionId The ID of the approved artwork submission.
     */
    function addArtworkToGallery(uint256 _submissionId) external onlyGalleryAdmin submissionExists(_submissionId) {
        require(artworkSubmissions[_submissionId].approved, "Artwork submission is not approved.");
        require(!artworkSubmissions[_submissionId].inGallery, "Artwork is already in the gallery.");

        _galleryArtworkCounter.increment();
        uint256 artworkId = _galleryArtworkCounter.current();

        galleryArtworks[artworkId] = GalleryArtwork({
            artworkId: artworkId,
            submissionId: _submissionId,
            artist: artworkSubmissions[_submissionId].artist,
            artworkURI: artworkSubmissions[_submissionId].artworkURI,
            salePrice: 0 // Initial sale price can be set by artist later
        });
        galleryArtworkIds.push(artworkId);
        artworkSubmissions[_submissionId].inGallery = true;

        emit ArtworkAddedToGallery(artworkId, _submissionId);
    }

    /**
     * @dev Removes an artwork from the gallery. Can be triggered by governance proposal (example for decentralization).
     *      For simplicity, currently only gallery admin can remove.
     * @param _artworkId The ID of the artwork in the gallery to be removed.
     */
    function removeArtworkFromGallery(uint256 _artworkId) external onlyGalleryAdmin artworkInGallery(_artworkId) {
        // In a real DAO, this could be triggered by a successful governance proposal
        for (uint256 i = 0; i < galleryArtworkIds.length; i++) {
            if (galleryArtworkIds[i] == _artworkId) {
                galleryArtworkIds[i] = galleryArtworkIds[galleryArtworkIds.length - 1];
                galleryArtworkIds.pop();
                break;
            }
        }
        delete galleryArtworks[_artworkId];
        emit ArtworkRemovedFromGallery(_artworkId);
    }

    /**
     * @dev Starts a curated exhibition with a selection of artworks from the gallery.
     * @param _exhibitionName Name of the exhibition.
     * @param _artworkIds Array of gallery artwork IDs to include in the exhibition.
     * @param _exhibitionDuration Duration of the exhibition in seconds.
     */
    function startExhibition(string memory _exhibitionName, uint256[] memory _artworkIds, uint256 _exhibitionDuration) external onlyGalleryAdmin {
        require(activeExhibitionId == 0 || !exhibitions[activeExhibitionId].isActive, "An exhibition is already active.");
        _exhibitionCounter.increment();
        uint256 exhibitionId = _exhibitionCounter.current();

        exhibitions[exhibitionId] = Exhibition({
            exhibitionId: exhibitionId,
            exhibitionName: _exhibitionName,
            startTime: block.timestamp,
            endTime: block.timestamp + _exhibitionDuration,
            isActive: true,
            artworkIds: _artworkIds
        });
        activeExhibitionId = exhibitionId;
        emit ExhibitionStarted(exhibitionId, _exhibitionName, exhibitions[exhibitionId].startTime, exhibitions[exhibitionId].endTime);
    }

    /**
     * @dev Ends the currently active exhibition.
     * @param _exhibitionId The ID of the exhibition to end.
     */
    function endExhibition(uint256 _exhibitionId) external onlyGalleryAdmin {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(block.timestamp >= exhibitions[_exhibitionId].endTime, "Exhibition end time not reached.");
        exhibitions[_exhibitionId].isActive = false;
        activeExhibitionId = 0; // Reset active exhibition
        emit ExhibitionEnded(_exhibitionId);
    }

    /**
     * @dev Gets details of the currently active exhibition.
     * @return Exhibition struct of the active exhibition, or default struct if no active exhibition.
     */
    function getActiveExhibition() external view returns (Exhibition memory) {
        if (activeExhibitionId != 0 && exhibitions[activeExhibitionId].isActive) {
            return exhibitions[activeExhibitionId];
        } else {
            return Exhibition({exhibitionId: 0, exhibitionName: "", startTime: 0, endTime: 0, isActive: false, artworkIds: new uint256[](0)}); // Return default if no active exhibition
        }
    }

    /**
     * @dev Returns a list of artwork IDs currently in the gallery.
     * @return Array of gallery artwork IDs.
     */
    function getGalleryArtworkIds() external view returns (uint256[] memory) {
        return galleryArtworkIds;
    }

    /**
     * @dev Returns a list of artwork IDs included in a specific exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @return Array of gallery artwork IDs in the exhibition.
     */
    function getExhibitionArtworkIds(uint256 _exhibitionId) external view returns (uint256[] memory) {
        return exhibitions[_exhibitionId].artworkIds;
    }


    // ------------------------------------------------------------------------------------------------------
    // 4. Artist & Community Rewards
    // ------------------------------------------------------------------------------------------------------

    /**
     * @dev Allows artists to set a sale price for their artwork in the gallery.
     * @param _artworkId The ID of the artwork in the gallery.
     * @param _price The sale price in wei.
     */
    function setArtworkSalePrice(uint256 _artworkId, uint256 _price) external onlyArtist artworkInGallery(_artworkId) {
        require(galleryArtworks[_artworkId].artist == msg.sender, "Only the artist can set the sale price.");
        galleryArtworks[_artworkId].salePrice = _price;
    }

    /**
     * @dev Allows anyone to purchase an artwork from the gallery.
     *      Transfers funds to the artist and takes a gallery commission.
     * @param _artworkId The ID of the artwork in the gallery to purchase.
     */
    function purchaseArtwork(uint256 _artworkId) external payable nonReentrant artworkInGallery(_artworkId) {
        require(galleryArtworks[_artworkId].salePrice > 0, "Artwork is not for sale.");
        require(msg.value >= galleryArtworks[_artworkId].salePrice, "Insufficient funds sent.");

        uint256 salePrice = galleryArtworks[_artworkId].salePrice;
        uint256 galleryCommission = (salePrice * galleryCommissionPercentage) / 100;
        uint256 artistPayout = salePrice - galleryCommission;

        artistEarnings[galleryArtworks[_artworkId].artist] += artistPayout;

        payable(galleryArtworks[_artworkId].artist).transfer(artistPayout);
        payable(owner()).transfer(galleryCommission); // Gallery commission goes to contract owner (admin)

        emit ArtworkSale(_artworkId, msg.sender, salePrice, galleryArtworks[_artworkId].artist, galleryCommission);
    }

    /**
     * @dev Allows artists to withdraw their accumulated earnings from artwork sales.
     */
    function withdrawArtistEarnings() external onlyArtist nonReentrant {
        uint256 earnings = artistEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");

        artistEarnings[msg.sender] = 0; // Reset earnings to 0 after withdrawal
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(msg.sender, earnings);
    }


    // ------------------------------------------------------------------------------------------------------
    // 5. Decentralized Governance & Proposals
    // ------------------------------------------------------------------------------------------------------

    /**
     * @dev Allows community members to create governance proposals.
     * @param _proposalDescription Description of the proposal.
     * @param _calldata Calldata to execute if the proposal passes (e.g., function call, parameters).
     */
    function createGovernanceProposal(string memory _proposalDescription, bytes memory _calldata) external onlyVoter {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVotingDuration,
            supportVotes: 0,
            againstVotes: 0,
            votingActive: true,
            executed: false,
            calldataData: _calldata
        });
        proposalIds.push(proposalId);
        emit GovernanceProposalCreated(proposalId, _proposalDescription, msg.sender);
    }

    /**
     * @dev Allows voters to cast their vote (support or oppose) for a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True to support the proposal, false to oppose.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyVoter proposalExists(_proposalId) votingActiveForProposal(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Voter has already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true; // Mark voter as voted

        if (_support) {
            governanceProposals[_proposalId].supportVotes++;
        } else {
            governanceProposals[_proposalId].againstVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successful governance proposal if it has passed the voting and voting period is over.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyGalleryAdmin proposalExists(_proposalId) votingNotActiveForProposal(_proposalId) {
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= governanceProposals[_proposalId].endTime, "Voting period is not over yet.");
        require(governanceProposals[_proposalId].supportVotes > governanceProposals[_proposalId].againstVotes, "Proposal did not pass.");

        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataData);
        require(success, "Proposal execution failed.");
        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Checks the current status of a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return True if voting is active, false otherwise.
     */
    function getProposalStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (bool) {
        return governanceProposals[_proposalId].votingActive;
    }

    /**
     * @dev Gets the current support and against vote counts for a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return supportCount The number of support votes.
     * @return againstCount The number of against votes.
     */
    function getProposalVoteCount(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 supportCount, uint256 againstCount) {
        return (governanceProposals[_proposalId].supportVotes, governanceProposals[_proposalId].againstVotes);
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```