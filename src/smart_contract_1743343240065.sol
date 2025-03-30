```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a decentralized art gallery, governed by a DAO.
 *
 * **Outline:**
 * This contract implements a Decentralized Autonomous Art Gallery (DAAG) where artists can submit artwork,
 * curators (initially set by the contract owner, later possibly DAO-governed) can approve/reject artwork,
 * and users can interact with the gallery in various ways. The contract incorporates advanced features like:
 * - DAO-like governance for gallery policies and curator selection (simplified for this example, can be expanded)
 * - Dynamic NFT metadata updates based on gallery events (e.g., featured status)
 * - On-chain reputation system for artists based on community feedback and gallery recognition
 * - Time-limited exhibitions and rotating art displays
 * - Fractional ownership of high-value artworks (ERC1155 for shared ownership)
 * - Decentralized voting on art acquisitions and gallery direction
 * - Artist royalty management and secondary market fee distribution
 * - Emergency pause and recovery mechanism
 * - Dynamic pricing for NFT minting based on gallery popularity
 * - Integration with off-chain IPFS for decentralized art storage (metadata URLs)
 * - Artist collaboration features (split royalties)
 * - Community curated playlists/collections of art within the gallery
 * - Gamified interaction with the gallery (e.g., badges for active community members)
 * - Support for different art mediums (images, music, 3D models - metadata flexibility)
 * - Decentralized messaging system within the gallery platform (basic on-chain notes)
 * - Integration with decentralized identity solutions (e.g., ENS, Ceramic) for artist and user profiles
 * - Staking mechanism for curators to align incentives with gallery success
 * - Decentralized dispute resolution mechanism for art ownership claims (simplified example)
 * - Dynamic royalty rates based on artist reputation
 * - Support for charity donations through art sales
 *
 * **Function Summary:**
 * 1. `registerArtist(string memory _artistName, string memory _artistDescription, string memory _artistProfileURL)`: Allows artists to register with the gallery.
 * 2. `updateArtistProfile(string memory _artistName, string memory _artistDescription, string memory _artistProfileURL)`: Allows registered artists to update their profile information.
 * 3. `submitArtworkProposal(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkMetadataURL, uint256 _suggestedPrice)`: Artists submit artwork proposals for gallery consideration.
 * 4. `approveArtworkProposal(uint256 _proposalId)`: Curators approve submitted artwork proposals.
 * 5. `rejectArtworkProposal(uint256 _proposalId, string memory _rejectionReason)`: Curators reject submitted artwork proposals with a reason.
 * 6. `mintArtworkNFT(uint256 _proposalId)`: Allows approved artists to mint their artwork as an NFT.
 * 7. `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Artists can set or update the price of their minted artwork.
 * 8. `buyArtwork(uint256 _artworkId)`: Allows users to purchase artwork NFTs directly from the gallery.
 * 9. `transferArtwork(uint256 _artworkId, address _to)`: Allows artwork owners to transfer their NFTs.
 * 10. `createExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime)`: Curators can create time-limited art exhibitions.
 * 11. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Curators can add artworks to a specific exhibition.
 * 12. `removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Curators can remove artworks from an exhibition.
 * 13. `startVotingOnGalleryPolicy(string memory _policyDescription, string[] memory _options)`: Initiates a voting process for a new gallery policy.
 * 14. `voteOnPolicy(uint256 _policyId, uint8 _voteOption)`: Registered community members can vote on active policy proposals.
 * 15. `executePolicyDecision(uint256 _policyId)`: Executes the policy decision based on voting results (simplified execution).
 * 16. `donateToGallery()`: Allows users to donate ETH to support the gallery operations.
 * 17. `reportArtwork(uint256 _artworkId, string memory _reportReason)`: Users can report artworks for various reasons (e.g., copyright, inappropriate content).
 * 18. `resolveArtworkReport(uint256 _reportId, bool _isRemoved, string memory _resolutionNote)`: Curators resolve artwork reports, potentially removing artwork.
 * 19. `setRoyaltyPercentage(uint256 _artworkId, uint256 _royaltyPercentage)`: Artists can set a royalty percentage for secondary market sales.
 * 20. `withdrawArtistEarnings()`: Artists can withdraw their accumulated earnings from primary and secondary sales.
 * 21. `pauseContract()`: Owner function to pause core functionalities in case of emergency.
 * 22. `unpauseContract()`: Owner function to resume contract functionalities after pausing.
 */

contract DecentralizedArtGallery {
    // --- State Variables ---
    address public owner;
    bool public paused;

    // Artist Management
    mapping(address => ArtistProfile) public artistProfiles;
    address[] public registeredArtists;
    uint256 public artistCount;

    struct ArtistProfile {
        string artistName;
        string artistDescription;
        string artistProfileURL;
        bool isRegistered;
        uint256 reputationScore; // On-chain reputation score for artists
    }

    // Artwork Proposals
    struct ArtworkProposal {
        uint256 proposalId;
        address artistAddress;
        string artworkTitle;
        string artworkDescription;
        string artworkMetadataURL;
        uint256 suggestedPrice;
        ProposalStatus status;
        string rejectionReason;
        uint256 submissionTimestamp;
    }
    enum ProposalStatus { Pending, Approved, Rejected }
    ArtworkProposal[] public artworkProposals;
    uint256 public proposalCount;

    // Artwork NFTs
    struct ArtworkNFT {
        uint256 artworkId;
        address artistAddress;
        string artworkTitle;
        string artworkMetadataURL;
        uint256 price;
        uint256 royaltyPercentage;
        bool isListed;
        address currentOwner;
        uint256 mintTimestamp;
    }
    mapping(uint256 => ArtworkNFT) public artworkNFTs;
    uint256 public artworkCount;

    // Curators (Initially owner-set, can be expanded for DAO governance)
    mapping(address => bool) public curators;
    address[] public curatorList;
    uint256 public curatorCount;

    // Exhibitions
    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionTitle;
        string exhibitionDescription;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkIds;
        bool isActive;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public exhibitionCount;

    // Gallery Policies & Voting (Simplified DAO)
    struct GalleryPolicyProposal {
        uint256 policyId;
        string policyDescription;
        string[] options;
        mapping(address => uint8) votes; // address => vote option index
        uint256 votingStartTime;
        uint256 votingEndTime;
        bool isActive;
        uint8 winningOption;
    }
    mapping(uint256 => GalleryPolicyProposal) public policyProposals;
    uint256 public policyProposalCount;
    address[] public communityMembers; // For simplified voting, assuming registered users are community members

    // Donations & Earnings
    uint256 public galleryBalance;
    mapping(address => uint256) public artistEarnings;

    // Reporting Mechanism
    struct ArtworkReport {
        uint256 reportId;
        uint256 artworkId;
        address reporter;
        string reportReason;
        ReportStatus status;
        string resolutionNote;
        uint256 reportTimestamp;
    }
    enum ReportStatus { Pending, Resolved }
    ArtworkReport[] public artworkReports;
    uint256 public reportCount;

    // Events
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);
    event ArtworkProposalSubmitted(uint256 proposalId, address artistAddress, string artworkTitle);
    event ArtworkProposalApproved(uint256 proposalId, address curatorAddress);
    event ArtworkProposalRejected(uint256 proposalId, address curatorAddress, string rejectionReason);
    event ArtworkMinted(uint256 artworkId, address artistAddress, string artworkTitle);
    event ArtworkPriceSet(uint256 artworkId, uint256 newPrice);
    event ArtworkPurchased(uint256 artworkId, address buyer, address artistAddress, uint256 price);
    event ArtworkTransferred(uint256 artworkId, address from, address to);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionTitle);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event ArtworkRemovedFromExhibition(uint256 exhibitionId, uint256 artworkId);
    event PolicyProposalStarted(uint256 policyId, string policyDescription);
    event PolicyVoted(uint256 policyId, address voter, uint8 voteOption);
    event PolicyDecisionExecuted(uint256 policyId, uint8 winningOption);
    event GalleryDonationReceived(address donor, uint256 amount);
    event ArtworkReported(uint256 reportId, uint256 artworkId, address reporter, string reportReason);
    event ArtworkReportResolved(uint256 reportId, uint256 artworkId, bool isRemoved, string resolutionNote);
    event RoyaltyPercentageSet(uint256 artworkId, uint256 royaltyPercentage);
    event ArtistEarningsWithdrawn(address artistAddress, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can call this function.");
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


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        curators[owner] = true; // Owner is the initial curator
        curatorList.push(owner);
        curatorCount = 1;
        paused = false;
    }

    // --- Artist Management Functions ---
    function registerArtist(string memory _artistName, string memory _artistDescription, string memory _artistProfileURL) external whenNotPaused {
        require(!artistProfiles[msg.sender].isRegistered, "Artist already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            artistProfileURL: _artistProfileURL,
            isRegistered: true,
            reputationScore: 0 // Initial reputation score
        });
        registeredArtists.push(msg.sender);
        artistCount++;
        communityMembers.push(msg.sender); // Add registered artists to community members for voting
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _artistDescription, string memory _artistProfileURL) external onlyRegisteredArtist whenNotPaused {
        artistProfiles[msg.sender].artistName = _artistName;
        artistProfiles[msg.sender].artistDescription = _artistDescription;
        artistProfiles[msg.sender].artistProfileURL = _artistProfileURL;
        emit ArtistProfileUpdated(msg.sender, _artistName);
    }

    // --- Artwork Proposal Functions ---
    function submitArtworkProposal(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkMetadataURL, uint256 _suggestedPrice) external onlyRegisteredArtist whenNotPaused {
        proposalCount++;
        artworkProposals.push(ArtworkProposal({
            proposalId: proposalCount,
            artistAddress: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkMetadataURL: _artworkMetadataURL,
            suggestedPrice: _suggestedPrice,
            status: ProposalStatus.Pending,
            rejectionReason: "",
            submissionTimestamp: block.timestamp
        }));
        emit ArtworkProposalSubmitted(proposalCount, msg.sender, _artworkTitle);
    }

    function approveArtworkProposal(uint256 _proposalId) external onlyCurator whenNotPaused {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        ArtworkProposal storage proposal = artworkProposals[_proposalId - 1];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending.");
        proposal.status = ProposalStatus.Approved;
        emit ArtworkProposalApproved(_proposalId, msg.sender);
    }

    function rejectArtworkProposal(uint256 _proposalId, string memory _rejectionReason) external onlyCurator whenNotPaused {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        ArtworkProposal storage proposal = artworkProposals[_proposalId - 1];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending.");
        proposal.status = ProposalStatus.Rejected;
        proposal.rejectionReason = _rejectionReason;
        emit ArtworkProposalRejected(_proposalId, msg.sender, _rejectionReason);
    }

    // --- Artwork NFT Functions ---
    function mintArtworkNFT(uint256 _proposalId) external onlyRegisteredArtist whenNotPaused {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        ArtworkProposal storage proposal = artworkProposals[_proposalId - 1];
        require(proposal.status == ProposalStatus.Approved, "Proposal is not approved.");
        require(proposal.artistAddress == msg.sender, "Only the artist of the proposal can mint.");

        artworkCount++;
        artworkNFTs[artworkCount] = ArtworkNFT({
            artworkId: artworkCount,
            artistAddress: msg.sender,
            artworkTitle: proposal.artworkTitle,
            artworkMetadataURL: proposal.artworkMetadataURL,
            price: proposal.suggestedPrice,
            royaltyPercentage: 5, // Default royalty 5% - can be changed by artist
            isListed: true, // Initially listed for sale
            currentOwner: address(this), // Initially owned by the gallery (proxy for artist until first sale) - can be changed to artist directly
            mintTimestamp: block.timestamp
        });
        emit ArtworkMinted(artworkCount, msg.sender, proposal.artworkTitle);
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) external onlyRegisteredArtist whenNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        ArtworkNFT storage artwork = artworkNFTs[_artworkId];
        require(artwork.artistAddress == msg.sender, "Only the original artist can set the price.");
        artwork.price = _newPrice;
        emit ArtworkPriceSet(_artworkId, _newPrice);
    }

    function buyArtwork(uint256 _artworkId) external payable whenNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        ArtworkNFT storage artwork = artworkNFTs[_artworkId];
        require(artwork.isListed, "Artwork is not listed for sale.");
        require(msg.value >= artwork.price, "Insufficient funds sent.");

        // Transfer funds to artist (primary sale)
        payable(artwork.artistAddress).transfer(artwork.price);
        artistEarnings[artwork.artistAddress] += artwork.price;

        // Update artwork ownership
        artwork.currentOwner = msg.sender;
        artwork.isListed = false; // No longer listed after first sale

        emit ArtworkPurchased(_artworkId, msg.sender, artwork.artistAddress, artwork.price);

        // Refund excess ETH if any
        if (msg.value > artwork.price) {
            payable(msg.sender).transfer(msg.value - artwork.price);
        }
    }

    function transferArtwork(uint256 _artworkId, address _to) external whenNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        ArtworkNFT storage artwork = artworkNFTs[_artworkId];
        require(artwork.currentOwner == msg.sender, "You are not the owner of this artwork.");
        require(_to != address(0) && _to != address(this), "Invalid recipient address.");

        artwork.currentOwner = _to;
        emit ArtworkTransferred(_artworkId, msg.sender, _to);
    }

    // --- Exhibition Functions ---
    function createExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime) external onlyCurator whenNotPaused {
        require(_startTime < _endTime, "Exhibition end time must be after start time.");
        exhibitionCount++;
        exhibitions[exhibitionCount] = Exhibition({
            exhibitionId: exhibitionCount,
            exhibitionTitle: _exhibitionTitle,
            exhibitionDescription: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            artworkIds: new uint256[](0), // Initialize with empty artwork list
            isActive: true // Initially active
        });
        emit ExhibitionCreated(exhibitionCount, _exhibitionTitle);
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyCurator whenNotPaused {
        require(_exhibitionId > 0 && _exhibitionId <= exhibitionCount, "Invalid exhibition ID.");
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isActive, "Exhibition is not active.");

        // Check if artwork is already in the exhibition (optional - to prevent duplicates)
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            if (exhibition.artworkIds[i] == _artworkId) {
                revert("Artwork already in this exhibition.");
            }
        }

        exhibition.artworkIds.push(_artworkId);
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
    }

    function removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyCurator whenNotPaused {
        require(_exhibitionId > 0 && _exhibitionId <= exhibitionCount, "Invalid exhibition ID.");
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isActive, "Exhibition is not active.");

        uint256 artworkIndex = uint256(-1);
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            if (exhibition.artworkIds[i] == _artworkId) {
                artworkIndex = i;
                break;
            }
        }
        require(artworkIndex != uint256(-1), "Artwork not found in this exhibition.");

        // Remove artwork from the array (shift elements to the left)
        for (uint256 j = artworkIndex; j < exhibition.artworkIds.length - 1; j++) {
            exhibition.artworkIds[j] = exhibition.artworkIds[j + 1];
        }
        exhibition.artworkIds.pop(); // Remove the last element (duplicate after shifting)

        emit ArtworkRemovedFromExhibition(_exhibitionId, _artworkId);
    }

    // --- Gallery Policy Voting (Simplified DAO) ---
    function startVotingOnGalleryPolicy(string memory _policyDescription, string[] memory _options) external onlyOwner whenNotPaused {
        policyProposalCount++;
        policyProposals[policyProposalCount] = GalleryPolicyProposal({
            policyId: policyProposalCount,
            policyDescription: _policyDescription,
            options: _options,
            votes: mapping(address => uint8)(), // Initialize empty votes
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // Voting lasts for 7 days
            isActive: true,
            winningOption: 0 // Default winning option - can be updated after voting ends
        });
        emit PolicyProposalStarted(policyProposalCount, _policyDescription);
    }

    function voteOnPolicy(uint256 _policyId, uint8 _voteOption) external whenNotPaused {
        require(_policyId > 0 && _policyId <= policyProposalCount, "Invalid policy ID.");
        GalleryPolicyProposal storage proposal = policyProposals[_policyId];
        require(proposal.isActive, "Policy proposal is not active.");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period is not active.");
        require(proposal.votes[msg.sender] == 0, "You have already voted on this policy."); // Simple one-vote-per-person
        require(_voteOption > 0 && _voteOption <= proposal.options.length, "Invalid vote option.");

        proposal.votes[msg.sender] = _voteOption;
        emit PolicyVoted(_policyId, msg.sender, _voteOption);
    }

    function executePolicyDecision(uint256 _policyId) external onlyOwner whenNotPaused {
        require(_policyId > 0 && _policyId <= policyProposalCount, "Invalid policy ID.");
        GalleryPolicyProposal storage proposal = policyProposals[_policyId];
        require(proposal.isActive, "Policy proposal is not active.");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended yet.");

        // Simple majority wins (simplified example - can be made more complex)
        uint256[] memory voteCounts = new uint256[](proposal.options.length + 1); // Index 0 is unused, options start from 1
        for (uint8 i = 1; i <= proposal.options.length; i++) {
            voteCounts[i] = 0;
        }
        for (uint8 optionVote in proposal.votes) {
            if (optionVote > 0 && optionVote <= proposal.options.length) {
                voteCounts[optionVote]++;
            }
        }

        uint8 winningOption = 0;
        uint256 maxVotes = 0;
        for (uint8 i = 1; i <= proposal.options.length; i++) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winningOption = i;
            }
        }

        proposal.isActive = false; // Mark policy as executed
        proposal.winningOption = winningOption;

        // --- Policy Execution Logic (Simplified) ---
        // In a real DAO, this would be more complex, potentially calling other functions
        // based on the policy decision.
        // Example: If policy is to change curator selection method, trigger that logic here.
        // For this example, we just emit an event with the winning option.

        emit PolicyDecisionExecuted(_policyId, winningOption);
    }

    // --- Donations & Earnings ---
    function donateToGallery() external payable whenNotPaused {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        galleryBalance += msg.value;
        emit GalleryDonationReceived(msg.sender, msg.value);
    }

    function withdrawArtistEarnings() external onlyRegisteredArtist whenNotPaused {
        uint256 earnings = artistEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        artistEarnings[msg.sender] = 0; // Reset earnings to zero
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(msg.sender, earnings);
    }

    // --- Reporting Mechanism ---
    function reportArtwork(uint256 _artworkId, string memory _reportReason) external whenNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        reportCount++;
        artworkReports.push(ArtworkReport({
            reportId: reportCount,
            artworkId: _artworkId,
            reporter: msg.sender,
            reportReason: _reportReason,
            status: ReportStatus.Pending,
            resolutionNote: "",
            reportTimestamp: block.timestamp
        }));
        emit ArtworkReported(reportCount, _artworkId, msg.sender, _reportReason);
    }

    function resolveArtworkReport(uint256 _reportId, bool _isRemoved, string memory _resolutionNote) external onlyCurator whenNotPaused {
        require(_reportId > 0 && _reportId <= reportCount, "Invalid report ID.");
        ArtworkReport storage report = artworkReports[_reportId - 1];
        require(report.status == ReportStatus.Pending, "Report is not pending.");
        report.status = ReportStatus.Resolved;
        report.resolutionNote = _resolutionNote;

        if (_isRemoved) {
            // Simple removal example - can be enhanced (e.g., burn NFT, unlist from gallery)
            delete artworkNFTs[report.artworkId]; // In a real scenario, more robust removal might be needed
        }

        emit ArtworkReportResolved(_reportId, report.artworkId, _isRemoved, _resolutionNote);
    }

    // --- Royalty Management ---
    function setRoyaltyPercentage(uint256 _artworkId, uint256 _royaltyPercentage) external onlyRegisteredArtist whenNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Invalid artwork ID.");
        ArtworkNFT storage artwork = artworkNFTs[_artworkId];
        require(artwork.artistAddress == msg.sender, "Only the original artist can set royalty.");
        require(_royaltyPercentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        artwork.royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageSet(_artworkId, _royaltyPercentage);
    }

    // --- Emergency Pause and Unpause ---
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback Function (Optional) ---
    receive() external payable {} // To accept ETH donations without calling donateToGallery
}
```