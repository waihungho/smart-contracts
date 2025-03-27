```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, incorporating advanced concepts like dynamic NFTs,
 *      curation voting, fractional ownership, generative art integration, and community-driven evolution.

 * **Outline:**

 * **Data Structures:**
 *   - Artwork: Struct to store artwork details (NFT, artist, metadata, curation status, ownership, generative parameters).
 *   - Proposal: Struct for governance proposals (type, proposer, parameters, votes, status).
 *   - GalleryParameters: Struct to hold configurable gallery settings (curation thresholds, fees, etc.).
 *   - UserProfile: Struct to store user information (optional, for future extensions).

 * **State Variables:**
 *   - artworks: Mapping to store artwork details by NFT ID.
 *   - proposals: Mapping to store governance proposals by proposal ID.
 *   - galleryParameters: Struct to store gallery-wide settings.
 *   - nextArtworkId: Counter for unique artwork IDs.
 *   - nextProposalId: Counter for unique proposal IDs.
 *   - curatorRegistry: Mapping to track registered curators.
 *   - fractionalOwnershipRegistry: Mapping to track fractional ownership of artworks.
 *   - displayedArtworks: Array to keep track of artworks currently on display.
 *   - galleryToken: Address of the governance/utility token (if applicable).

 * **Modifiers:**
 *   - onlyCurator: Modifier to restrict function access to registered curators.
 *   - onlyGalleryOwner: Modifier to restrict function access to the gallery owner.
 *   - proposalActive: Modifier to check if a proposal is in an active voting state.
 *   - artworkExists: Modifier to check if an artwork with a given ID exists.
 *   - notNullAddress: Modifier to ensure an address is not zero address.

 * **Events:**
 *   - ArtworkSubmitted: Emitted when a new artwork is submitted.
 *   - ArtworkMinted: Emitted when an artwork NFT is minted.
 *   - CurationProposalCreated: Emitted when a new curation proposal is created.
 *   - CurationProposalVoted: Emitted when a vote is cast on a curation proposal.
 *   - CurationProposalExecuted: Emitted when a curation proposal is executed.
 *   - ArtworkDisplayed: Emitted when an artwork is placed on display.
 *   - ArtworkRemovedFromDisplay: Emitted when an artwork is removed from display.
 *   - GalleryParameterUpdated: Emitted when gallery parameters are updated.
 *   - CuratorRegistered: Emitted when a curator is registered.
 *   - FractionalOwnershipCreated: Emitted when fractional ownership for an artwork is initiated.
 *   - FractionalOwnershipTransferred: Emitted when fractional ownership is transferred.
 *   - GenerativeParametersUpdated: Emitted when generative parameters for an artwork are updated.
 *   - DynamicNFTMetadataUpdated: Emitted when dynamic NFT metadata is updated based on conditions.
 *   - ArtworkReported: Emitted when an artwork is reported for inappropriate content.
 *   - CommunityChallengeCreated: Emitted when a community challenge is created.
 *   - CommunityChallengeVoteCast: Emitted when a vote is cast in a community challenge.
 *   - CommunityChallengeExecuted: Emitted when a community challenge is executed.

 * **Function Summary:**

 * **Artwork Management:**
 *   1. `submitArtwork(string memory _metadataURI, address _artist, bytes memory _generativeParams)`: Allows artists to submit artwork with metadata and optional generative parameters.
 *   2. `mintNFT(uint256 _artworkId)`: Mints an NFT for a submitted artwork (can be permissioned or open, based on gallery parameters).
 *   3. `setArtworkOnDisplay(uint256 _artworkId)`: Puts a curated artwork on display in the gallery.
 *   4. `removeArtworkFromDisplay(uint256 _artworkId)`: Removes an artwork from display.
 *   5. `getArtworkDetails(uint256 _artworkId) view returns (Artwork memory)`: Retrieves detailed information about an artwork.
 *   6. `reportArtwork(uint256 _artworkId, string memory _reportReason)`: Allows users to report artwork for policy violations.
 *   7. `updateGenerativeParameters(uint256 _artworkId, bytes memory _newParams)`: Allows the artist (or curators with governance) to update generative parameters of an artwork (for dynamic art).
 *   8. `triggerDynamicNFTMetadataUpdate(uint256 _artworkId)`: Manually triggers an update of dynamic NFT metadata based on predefined conditions (e.g., time, external events).

 * **Curation & Governance:**
 *   9. `proposeArtworkForCuration(uint256 _artworkId, string memory _proposalDescription)`: Allows curators to propose submitted artworks for curation review.
 *   10. `voteOnCurationProposal(uint256 _proposalId, bool _vote)`: Registered curators can vote on curation proposals.
 *   11. `executeCurationProposal(uint256 _proposalId)`: Executes a curation proposal after voting is complete (if approved).
 *   12. `registerCurator(address _curatorAddress)`: Allows the gallery owner to register curators.
 *   13. `removeCurator(address _curatorAddress)`: Allows the gallery owner to remove curators.
 *   14. `updateCurationThreshold(uint256 _newThreshold)`: Allows the gallery owner (or governance if implemented) to update the curation approval threshold.
 *   15. `createCommunityChallenge(string memory _challengeDescription, uint256 _votingDuration)`: Allows curators to create community challenges (e.g., theme-based exhibitions, artwork selection).
 *   16. `voteOnCommunityChallenge(uint256 _challengeId, uint256 _choiceIndex)`: Users can vote on choices in a community challenge.
 *   17. `executeCommunityChallenge(uint256 _challengeId)`: Executes the outcome of a community challenge based on voting results.

 * **Fractional Ownership:**
 *   18. `initiateFractionalOwnership(uint256 _artworkId, uint256 _totalShares)`: Allows the artwork owner (or gallery with artist consent) to initiate fractional ownership.
 *   19. `transferFractionalOwnership(uint256 _artworkId, uint256 _shareId, address _to)`: Allows fractional owners to transfer their shares.
 *   20. `purchaseFractionalOwnership(uint256 _artworkId, uint256 _shareId)`: (Optional, if marketplace integration) Allows users to purchase fractional ownership shares.
 *   21. `redeemFractionalOwnershipBenefits(uint256 _artworkId)`: (Future, could be for shared revenue or voting rights based on fractional ownership).

 * **Gallery Management & Utility:**
 *   22. `setGalleryParameters(GalleryParameters memory _newParameters)`: Allows the gallery owner to update gallery-wide settings.
 *   23. `withdrawGalleryFees()`: Allows the gallery owner to withdraw collected fees (if any, from sales or services).
 *   24. `pauseGallery()`: (Emergency function) Allows the gallery owner to pause critical functions in case of issues.
 *   25. `unpauseGallery()`: Resumes gallery functionality after pausing.

 * **Advanced/Trendy Concepts Implemented:**
 *   - **Dynamic NFTs:**  `updateGenerativeParameters` and `triggerDynamicNFTMetadataUpdate` enable artworks to evolve over time or react to external conditions, making them more engaging and collectible.
 *   - **Decentralized Curation:**  `proposeArtworkForCuration`, `voteOnCurationProposal`, and curator registry create a community-driven curation process, reducing central control and promoting diverse perspectives.
 *   - **Fractional Ownership:** `initiateFractionalOwnership` and related functions explore the trend of democratizing art ownership, allowing broader access and investment.
 *   - **Community Governance/Challenges:** `createCommunityChallenge`, `voteOnCommunityChallenge` allow the community to actively shape the gallery's direction, exhibitions, and focus.
 *   - **Report Mechanism:** `reportArtwork` addresses content moderation in a decentralized context, relying on community reporting and curator review.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtGallery {
    // --- Data Structures ---
    struct Artwork {
        uint256 id;
        string metadataURI; // IPFS URI or similar
        address artist;
        uint256 mintTimestamp;
        bool isCurated;
        bool onDisplay;
        bytes generativeParameters; // Optional parameters for generative art
        string reportReason; // Reason for report, if reported
        uint256 reportCount;
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 artworkId; // Relevant artwork ID for curation proposals
        string description;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        mapping(address => bool) votesCast; // Track votes per address to prevent double voting
    }

    enum ProposalType {
        CURATION,
        PARAMETER_UPDATE,
        COMMUNITY_CHALLENGE,
        OTHER
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        REJECTED,
        APPROVED,
        EXECUTED
    }

    struct GalleryParameters {
        uint256 curationThresholdPercentage; // Percentage of yes votes needed for curation approval
        uint256 curationVotingDuration; // Duration of curation voting in seconds
        uint256 communityChallengeVotingDuration; // Duration of community challenge voting
        address galleryOwner;
        address galleryFeeWallet; // Wallet to collect gallery fees (if applicable)
        bool galleryPaused;
    }

    struct FractionalOwnership {
        uint256 totalShares;
        uint256 sharesMinted;
        mapping(uint256 => address) shareOwners; // Share ID to owner address
        mapping(address => uint256[]) ownerShares; // Owner address to array of share IDs
    }


    // --- State Variables ---
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => Proposal) public proposals;
    GalleryParameters public galleryParameters;
    uint256 public nextArtworkId = 1;
    uint256 public nextProposalId = 1;
    mapping(address => bool) public curatorRegistry;
    mapping(uint256 => FractionalOwnership) public fractionalOwnershipRegistry;
    uint256[] public displayedArtworks;
    address public galleryToken; // Optional governance/utility token address

    // --- Modifiers ---
    modifier onlyCurator() {
        require(curatorRegistry[msg.sender], "Only registered curators can perform this action.");
        _;
    }

    modifier onlyGalleryOwner() {
        require(msg.sender == galleryParameters.galleryOwner, "Only gallery owner can perform this action.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        _;
    }

    modifier notNullAddress(address _address) {
        require(_address != address(0), "Address cannot be the zero address.");
        _;
    }

    modifier galleryNotPaused() {
        require(!galleryParameters.galleryPaused, "Gallery is currently paused.");
        _;
    }


    // --- Events ---
    event ArtworkSubmitted(uint256 artworkId, string metadataURI, address artist);
    event ArtworkMinted(uint256 artworkId);
    event CurationProposalCreated(uint256 proposalId, uint256 artworkId, address proposer, string description);
    event CurationProposalVoted(uint256 proposalId, address voter, bool vote);
    event CurationProposalExecuted(uint256 proposalId, ProposalStatus status);
    event ArtworkDisplayed(uint256 artworkId);
    event ArtworkRemovedFromDisplay(uint256 artworkId);
    event GalleryParameterUpdated(string parameterName);
    event CuratorRegistered(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event FractionalOwnershipCreated(uint256 artworkId, uint256 totalShares);
    event FractionalOwnershipTransferred(uint256 artworkId, uint256 shareId, address from, address to);
    event GenerativeParametersUpdated(uint256 artworkId);
    event DynamicNFTMetadataUpdated(uint256 artworkId);
    event ArtworkReported(uint256 artworkId, address reporter, string reportReason);
    event CommunityChallengeCreated(uint256 challengeId, string description, uint256 votingDuration);
    event CommunityChallengeVoteCast(uint256 challengeId, address voter, uint256 choiceIndex);
    event CommunityChallengeExecuted(uint256 challengeId);
    event GalleryPaused();
    event GalleryUnpaused();


    constructor(uint256 _curationThresholdPercentage, uint256 _curationVotingDuration, uint256 _communityChallengeVotingDuration, address _galleryFeeWallet) {
        galleryParameters = GalleryParameters({
            curationThresholdPercentage: _curationThresholdPercentage,
            curationVotingDuration: _curationVotingDuration,
            communityChallengeVotingDuration: _communityChallengeVotingDuration,
            galleryOwner: msg.sender,
            galleryFeeWallet: _galleryFeeWallet,
            galleryPaused: false
        });
    }

    // --- Artwork Management Functions ---
    function submitArtwork(string memory _metadataURI, address _artist, bytes memory _generativeParams) external galleryNotPaused {
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");
        require(_artist != address(0), "Artist address cannot be zero.");

        uint256 artworkId = nextArtworkId++;
        artworks[artworkId] = Artwork({
            id: artworkId,
            metadataURI: _metadataURI,
            artist: _artist,
            mintTimestamp: block.timestamp,
            isCurated: false,
            onDisplay: false,
            generativeParameters: _generativeParams,
            reportReason: "",
            reportCount: 0
        });

        emit ArtworkSubmitted(artworkId, _metadataURI, _artist);
    }

    function mintNFT(uint256 _artworkId) external galleryNotPaused artworkExists(_artworkId) {
        // In a real implementation, this would mint an actual NFT (ERC721/ERC1155)
        // Here, we'll just mark it as "minted" and trigger an event.
        emit ArtworkMinted(_artworkId);
        // In a real scenario, you would integrate with an NFT contract and mint tokens
        // associated with `_artworkId`.
    }

    function setArtworkOnDisplay(uint256 _artworkId) external onlyCurator galleryNotPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].isCurated, "Artwork must be curated to be displayed.");
        require(!artworks[_artworkId].onDisplay, "Artwork is already on display.");

        artworks[_artworkId].onDisplay = true;
        displayedArtworks.push(_artworkId);
        emit ArtworkDisplayed(_artworkId);
    }

    function removeArtworkFromDisplay(uint256 _artworkId) external onlyCurator galleryNotPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].onDisplay, "Artwork is not currently on display.");

        artworks[_artworkId].onDisplay = false;
        // Remove from displayedArtworks array (inefficient for large arrays, consider optimization if needed)
        for (uint256 i = 0; i < displayedArtworks.length; i++) {
            if (displayedArtworks[i] == _artworkId) {
                displayedArtworks[i] = displayedArtworks[displayedArtworks.length - 1];
                displayedArtworks.pop();
                break;
            }
        }
        emit ArtworkRemovedFromDisplay(_artworkId);
    }

    function getArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function reportArtwork(uint256 _artworkId, string memory _reportReason) external galleryNotPaused artworkExists(_artworkId) {
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty.");
        artworks[_artworkId].reportReason = _reportReason;
        artworks[_artworkId].reportCount++;
        emit ArtworkReported(_artworkId, msg.sender, _reportReason);
        // In a real system, you might trigger curator review based on report count or severity.
    }

    function updateGenerativeParameters(uint256 _artworkId, bytes memory _newParams) external galleryNotPaused artworkExists(_artworkId) {
        // In a real scenario, you might have access control to allow only artist or curators to update.
        // For simplicity, allowing artist and curators for now.
        require(msg.sender == artworks[_artworkId].artist || curatorRegistry[msg.sender] || msg.sender == galleryParameters.galleryOwner, "Only artist, curator or gallery owner can update parameters.");
        artworks[_artworkId].generativeParameters = _newParams;
        emit GenerativeParametersUpdated(_artworkId);
        emit DynamicNFTMetadataUpdated(_artworkId); // Trigger metadata update after parameter change
    }

    function triggerDynamicNFTMetadataUpdate(uint256 _artworkId) external galleryNotPaused artworkExists(_artworkId) {
        // Logic to update the NFT metadata based on current state or external data.
        // This is a placeholder. Actual implementation depends on how dynamic NFTs are managed (off-chain service, etc.)
        emit DynamicNFTMetadataUpdated(_artworkId); // Just emit an event to indicate update triggered.
    }


    // --- Curation & Governance Functions ---
    function proposeArtworkForCuration(uint256 _artworkId, string memory _proposalDescription) external onlyCurator galleryNotPaused artworkExists(_artworkId) {
        require(!artworks[_artworkId].isCurated, "Artwork is already curated.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.CURATION,
            proposer: msg.sender,
            artworkId: _artworkId,
            description: _proposalDescription,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + galleryParameters.curationVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.ACTIVE,
            votesCast: {}
        });

        emit CurationProposalCreated(proposalId, _artworkId, msg.sender, _proposalDescription);
    }

    function voteOnCurationProposal(uint256 _proposalId, bool _vote) external onlyCurator galleryNotPaused proposalActive(_proposalId) {
        require(!proposals[_proposalId].votesCast[msg.sender], "Curator has already voted on this proposal.");

        proposals[_proposalId].votesCast[msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit CurationProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeCurationProposal(uint256 _proposalId) external onlyCurator galleryNotPaused proposalActive(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].votingEndTime, "Voting is still active.");
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active."); // Re-check status

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 requiredYesVotes = (totalVotes * galleryParameters.curationThresholdPercentage) / 100;

        if (proposals[_proposalId].yesVotes >= requiredYesVotes) {
            artworks[proposals[_proposalId].artworkId].isCurated = true;
            proposals[_proposalId].status = ProposalStatus.APPROVED;
        } else {
            proposals[_proposalId].status = ProposalStatus.REJECTED;
        }

        proposals[_proposalId].status = ProposalStatus.EXECUTED; // Mark as executed regardless of outcome.
        emit CurationProposalExecuted(_proposalId, proposals[_proposalId].status);
    }

    function registerCurator(address _curatorAddress) external onlyGalleryOwner galleryNotPaused notNullAddress(_curatorAddress) {
        require(!curatorRegistry[_curatorAddress], "Curator address is already registered.");
        curatorRegistry[_curatorAddress] = true;
        emit CuratorRegistered(_curatorAddress);
    }

    function removeCurator(address _curatorAddress) external onlyGalleryOwner galleryNotPaused notNullAddress(_curatorAddress) {
        require(curatorRegistry[_curatorAddress], "Curator address is not registered.");
        delete curatorRegistry[_curatorAddress];
        emit CuratorRemoved(_curatorAddress);
    }

    function updateCurationThreshold(uint256 _newThreshold) external onlyGalleryOwner galleryNotPaused {
        require(_newThreshold <= 100, "Curation threshold percentage cannot exceed 100.");
        galleryParameters.curationThresholdPercentage = _newThreshold;
        emit GalleryParameterUpdated("curationThresholdPercentage");
    }

    function createCommunityChallenge(string memory _challengeDescription, uint256 _votingDuration) external onlyCurator galleryNotPaused {
        require(bytes(_challengeDescription).length > 0, "Challenge description cannot be empty.");
        require(_votingDuration > 0, "Voting duration must be positive.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.COMMUNITY_CHALLENGE,
            proposer: msg.sender,
            artworkId: 0, // Not relevant for community challenge
            description: _challengeDescription,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + _votingDuration,
            yesVotes: 0, // Yes votes repurposed for choice counting in community challenge
            noVotes: 0,  // No votes repurposed for choice counting in community challenge
            status: ProposalStatus.ACTIVE,
            votesCast: {}
        });
        emit CommunityChallengeCreated(proposalId, _challengeDescription, _votingDuration);
    }

    function voteOnCommunityChallenge(uint256 _challengeId, uint256 _choiceIndex) external galleryNotPaused proposalActive(_challengeId) {
        require(!proposals[_challengeId].votesCast[msg.sender], "User has already voted on this challenge.");
        require(_choiceIndex < 2, "Choice index out of range (only 0 and 1 supported for simplicity - extend for more choices)"); // Example for 2 choices (Yes/No, Option A/Option B, etc.)

        proposals[_challengeId].votesCast[msg.sender] = true;
        if (_choiceIndex == 0) {
            proposals[_challengeId].yesVotes++; // Using yesVotes as counter for choice 0
        } else if (_choiceIndex == 1) {
            proposals[_challengeId].noVotes++;  // Using noVotes as counter for choice 1
        }
        emit CommunityChallengeVoteCast(_challengeId, msg.sender, _choiceIndex);
    }

    function executeCommunityChallenge(uint256 _challengeId) external onlyCurator galleryNotPaused proposalActive(_challengeId) {
        require(block.timestamp >= proposals[_challengeId].votingEndTime, "Voting is still active.");
        require(proposals[_challengeId].status == ProposalStatus.ACTIVE, "Challenge is not active.");

        proposals[_challengeId].status = ProposalStatus.EXECUTED;
        emit CommunityChallengeExecuted(_challengeId);
        // Here, you would implement logic based on the challenge outcome (e.g., select artworks based on votes, update gallery parameters, etc.)
        // The outcome logic is specific to the challenge type and needs to be defined separately.
    }


    // --- Fractional Ownership Functions ---
    function initiateFractionalOwnership(uint256 _artworkId, uint256 _totalShares) external galleryNotPaused artworkExists(_artworkId) {
        require(fractionalOwnershipRegistry[_artworkId].totalShares == 0, "Fractional ownership already initiated for this artwork.");
        require(_totalShares > 0, "Total shares must be greater than zero.");

        fractionalOwnershipRegistry[_artworkId] = FractionalOwnership({
            totalShares: _totalShares,
            sharesMinted: 0,
            shareOwners: {},
            ownerShares: {}
        });
        emit FractionalOwnershipCreated(_artworkId, _totalShares);
    }

    function transferFractionalOwnership(uint256 _artworkId, uint256 _shareId, address _to) external galleryNotPaused artworkExists(_artworkId) {
        require(fractionalOwnershipRegistry[_artworkId].totalShares > 0, "Fractional ownership not initiated for this artwork.");
        address currentOwner = fractionalOwnershipRegistry[_artworkId].shareOwners[_shareId];
        require(currentOwner == msg.sender, "You are not the owner of this share.");
        require(_to != address(0), "Cannot transfer to zero address.");

        fractionalOwnershipRegistry[_artworkId].shareOwners[_shareId] = _to;
        // Update ownerShares mapping (remove from old owner, add to new owner) - more complex logic needed for robust implementation.
        emit FractionalOwnershipTransferred(_artworkId, _shareId, msg.sender, _to);
    }

    // --- Gallery Management & Utility Functions ---
    function setGalleryParameters(GalleryParameters memory _newParameters) external onlyGalleryOwner galleryNotPaused {
        require(_newParameters.curationThresholdPercentage <= 100, "Curation threshold percentage cannot exceed 100.");
        require(_newParameters.curationVotingDuration > 0, "Curation voting duration must be positive.");
        require(_newParameters.communityChallengeVotingDuration > 0, "Community challenge voting duration must be positive.");
        require(_newParameters.galleryOwner != address(0), "Gallery owner address cannot be zero.");
        require(_newParameters.galleryFeeWallet != address(0), "Gallery fee wallet address cannot be zero.");

        galleryParameters = _newParameters;
        emit GalleryParameterUpdated("allParameters"); // Generic event for parameter update. Consider more specific events.
    }

    function withdrawGalleryFees() external onlyGalleryOwner galleryNotPaused {
        // Example: Assuming gallery collects fees in ETH.
        payable(galleryParameters.galleryFeeWallet).transfer(address(this).balance);
        // In a real system, you would track fees collected and implement more sophisticated withdrawal logic.
    }

    function pauseGallery() external onlyGalleryOwner galleryNotPaused {
        require(!galleryParameters.galleryPaused, "Gallery is already paused.");
        galleryParameters.galleryPaused = true;
        emit GalleryPaused();
    }

    function unpauseGallery() external onlyGalleryOwner {
        require(galleryParameters.galleryPaused, "Gallery is not paused.");
        galleryParameters.galleryPaused = false;
        emit GalleryUnpaused();
    }

    // --- Fallback & Receive (Optional, for ETH reception if needed) ---
    receive() external payable {}
    fallback() external payable {}
}
```