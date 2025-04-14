```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Gemini AI (Hypothetical AI Assistant Example)
 * @dev A smart contract for a decentralized autonomous art gallery, showcasing advanced concepts.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Art NFT Functionality:**
 *    - `mintArtNFT(string memory _metadataURI)`: Allows artists to mint unique Art NFTs.
 *    - `transferArtNFT(address _to, uint256 _tokenId)`: Standard NFT transfer function.
 *    - `burnArtNFT(uint256 _tokenId)`: Allows NFT owner to destroy their Art NFT.
 *    - `getArtNFTMetadataURI(uint256 _tokenId)`: Retrieves the metadata URI for a given Art NFT.
 *    - `setArtNFTMetadataURI(uint256 _tokenId, string memory _metadataURI)`: Allows NFT owner to update metadata URI (if allowed by gallery).
 *
 * **2. Gallery Curation & Exhibition System:**
 *    - `submitArtForExhibition(uint256 _tokenId)`: Artists submit their Art NFTs for gallery exhibition consideration.
 *    - `voteOnExhibitionSubmission(uint256 _submissionId, bool _vote)`: Registered gallery members vote on submitted artworks for exhibition.
 *    - `setExhibitionDuration(uint256 _durationInDays)`: Gallery admin sets the duration of an exhibition cycle.
 *    - `startNewExhibitionCycle()`: Gallery admin initiates a new exhibition cycle, selecting artworks based on votes.
 *    - `getCurrentExhibition()`: Returns a list of Art NFT token IDs currently on exhibition.
 *    - `rewardExhibitingArtists(uint256 _tokenId)`: Distributes rewards (e.g., gallery tokens) to artists whose NFTs are exhibited.
 *
 * **3. Dynamic Art NFT Features:**
 *    - `evolveArtNFT(uint256 _tokenId, string memory _evolutionData)`: Allows Art NFTs to evolve based on certain criteria (e.g., votes, time, external data - placeholder for complex logic).
 *    - `checkArtNFTProvenance(uint256 _tokenId)`: Verifies the ownership history and authenticity of an Art NFT (basic provenance tracking).
 *    - `setArtNFTInteractiveElement(uint256 _tokenId, string memory _elementData)`: Allows adding interactive elements to the NFT metadata, making them dynamic.
 *
 * **4. Artist and Gallery Membership:**
 *    - `registerAsArtist()`: Allows users to register as artists in the gallery.
 *    - `registerAsGalleryMember()`: Allows users to register as gallery members to participate in curation and governance.
 *    - `getArtistProfile(address _artistAddress)`: Retrieves profile information for a registered artist.
 *    - `getGalleryMemberProfile(address _memberAddress)`: Retrieves profile information for a registered gallery member.
 *
 * **5. Gallery Governance & Utility:**
 *    - `proposeGalleryRuleChange(string memory _proposalDescription)`: Registered gallery members can propose changes to gallery rules.
 *    - `voteOnRuleChangeProposal(uint256 _proposalId, bool _vote)`: Registered gallery members vote on rule change proposals.
 *    - `executeRuleChange(uint256 _proposalId)`: Gallery admin executes approved rule changes.
 *    - `setGalleryName(string memory _galleryName)`: Gallery admin sets the name of the decentralized art gallery.
 *    - `withdrawGalleryFees()`: Allows gallery admin to withdraw collected fees (e.g., from minting or secondary sales - placeholder for fee logic).
 *    - `pauseContract()`: Gallery admin can pause the contract in case of emergency.
 *    - `unpauseContract()`: Gallery admin can unpause the contract.
 */

contract DecentralizedAutonomousArtGallery {
    // --- State Variables ---

    string public galleryName = "Genesis Art Gallery"; // Default gallery name
    address public galleryAdmin; // Address of the gallery administrator
    uint256 public exhibitionDurationDays = 7; // Default exhibition duration
    uint256 public currentExhibitionCycle = 0;
    bool public paused = false;

    uint256 public artNFTCounter = 0; // Counter for unique Art NFT IDs
    mapping(uint256 => string) public artNFTMetadataURIs; // Token ID to Metadata URI
    mapping(uint256 => address) public artNFTOwner; // Token ID to Owner
    mapping(uint256 => address) public artNFTCreator; // Token ID to Creator (Artist)
    mapping(uint256 => uint256[]) public artNFTProvenance; // Token ID to Ownership History (timestamps)

    mapping(uint256 => ExhibitionSubmission) public exhibitionSubmissions;
    uint256 public submissionCounter = 0;
    mapping(uint256 => mapping(address => bool)) public submissionVotes; // Submission ID -> Voter Address -> Voted (true/false)

    uint256 public ruleChangeProposalCounter = 0;
    mapping(uint256 => RuleChangeProposal) public ruleChangeProposals;
    mapping(uint256 => mapping(address => bool)) public ruleChangeVotes; // Proposal ID -> Voter Address -> Voted (true/false)

    mapping(address => ArtistProfile) public artistProfiles;
    mapping(address => GalleryMemberProfile) public galleryMemberProfiles;
    mapping(address => bool) public isRegisteredArtist;
    mapping(address => bool) public isRegisteredGalleryMember;

    uint256[] public currentExhibitionArtNFTs; // Token IDs of NFTs currently in exhibition

    // --- Structs ---

    struct ArtNFT {
        uint256 tokenId;
        string metadataURI;
        address creator;
        address owner;
        uint256[] provenance; // Timestamps of ownership changes
    }

    struct ExhibitionSubmission {
        uint256 submissionId;
        uint256 tokenId;
        address artist;
        uint256 voteCount;
        bool onExhibition;
    }

    struct RuleChangeProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 voteCount;
        bool executed;
    }

    struct ArtistProfile {
        string artistName;
        string artistBio;
        // Add more artist profile details as needed
    }

    struct GalleryMemberProfile {
        string memberName;
        string memberBio;
        // Add more member profile details as needed
    }

    // --- Events ---

    event ArtNFTMinted(uint256 tokenId, address creator, string metadataURI);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtNFTBurned(uint256 tokenId, address owner);
    event ArtNFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ArtSubmittedForExhibition(uint256 submissionId, uint256 tokenId, address artist);
    event ExhibitionVoteCast(uint256 submissionId, address voter, bool vote);
    event ExhibitionCycleStarted(uint256 cycleId, uint256[] exhibitedTokenIds);
    event ArtistRewarded(uint256 tokenId, address artist, uint256 rewardAmount); // Placeholder for reward logic
    event ArtistRegistered(address artistAddress);
    event GalleryMemberRegistered(address memberAddress);
    event GalleryRuleChangeProposed(uint256 proposalId, string description, address proposer);
    event GalleryRuleChangeVoteCast(uint256 proposalId, address voter, bool vote);
    event GalleryRuleChangeExecuted(uint256 proposalId);
    event GalleryNameUpdated(string newGalleryName);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---

    modifier onlyGalleryAdmin() {
        require(msg.sender == galleryAdmin, "Only gallery admin can perform this action.");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can perform this action.");
        _;
    }

    modifier onlyGalleryMember() {
        require(isRegisteredGalleryMember[msg.sender], "Only registered gallery members can perform this action.");
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(artNFTOwner[_tokenId] != address(0), "Art NFT does not exist.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(artNFTOwner[_tokenId] == msg.sender, "You are not the owner of this Art NFT.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    // --- Constructor ---

    constructor() {
        galleryAdmin = msg.sender; // Set the deployer as the initial gallery admin
    }

    // --- 1. Core Art NFT Functionality ---

    /// @notice Mints a new unique Art NFT. Only registered artists can mint.
    /// @param _metadataURI URI pointing to the metadata of the Art NFT (e.g., IPFS link).
    function mintArtNFT(string memory _metadataURI) external onlyArtist notPaused {
        artNFTCounter++;
        uint256 newTokenId = artNFTCounter;

        artNFTMetadataURIs[newTokenId] = _metadataURI;
        artNFTOwner[newTokenId] = msg.sender;
        artNFTCreator[newTokenId] = msg.sender;
        artNFTProvenance[newTokenId].push(block.timestamp); // Record initial minting timestamp

        emit ArtNFTMinted(newTokenId, msg.sender, _metadataURI);
    }

    /// @notice Transfers ownership of an Art NFT to another address.
    /// @param _to Address to which the Art NFT will be transferred.
    /// @param _tokenId ID of the Art NFT to transfer.
    function transferArtNFT(address _to, uint256 _tokenId) external tokenExists(_tokenId) onlyTokenOwner(_tokenId) notPaused {
        require(_to != address(0), "Invalid recipient address.");
        address from = msg.sender;

        artNFTOwner[_tokenId] = _to;
        artNFTProvenance[_tokenId].push(block.timestamp); // Record transfer timestamp

        emit ArtNFTTransferred(_tokenId, from, _to);
    }

    /// @notice Allows the owner of an Art NFT to burn (destroy) it.
    /// @param _tokenId ID of the Art NFT to burn.
    function burnArtNFT(uint256 _tokenId) external tokenExists(_tokenId) onlyTokenOwner(_tokenId) notPaused {
        address owner = msg.sender;

        delete artNFTMetadataURIs[_tokenId];
        delete artNFTOwner[_tokenId];
        delete artNFTCreator[_tokenId];
        delete artNFTProvenance[_tokenId];

        emit ArtNFTBurned(_tokenId, owner);
    }

    /// @notice Retrieves the metadata URI for a given Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @return string The metadata URI of the Art NFT.
    function getArtNFTMetadataURI(uint256 _tokenId) external view tokenExists(_tokenId) returns (string memory) {
        return artNFTMetadataURIs[_tokenId];
    }

    /// @notice Allows the owner of an Art NFT to update its metadata URI. (Gallery can decide if this is allowed)
    /// @param _tokenId ID of the Art NFT to update.
    /// @param _metadataURI New metadata URI for the Art NFT.
    function setArtNFTMetadataURI(uint256 _tokenId, string memory _metadataURI) external tokenExists(_tokenId) onlyTokenOwner(_tokenId) notPaused {
        artNFTMetadataURIs[_tokenId] = _metadataURI;
        emit ArtNFTMetadataUpdated(_tokenId, _metadataURI);
    }

    // --- 2. Gallery Curation & Exhibition System ---

    /// @notice Allows artists to submit their Art NFTs for exhibition consideration.
    /// @param _tokenId ID of the Art NFT to submit.
    function submitArtForExhibition(uint256 _tokenId) external onlyArtist tokenExists(_tokenId) onlyTokenOwner(_tokenId) notPaused {
        require(artNFTCreator[_tokenId] == msg.sender, "Only the creator of the Art NFT can submit it for exhibition."); // Only creator can submit
        submissionCounter++;
        exhibitionSubmissions[submissionCounter] = ExhibitionSubmission({
            submissionId: submissionCounter,
            tokenId: _tokenId,
            artist: msg.sender,
            voteCount: 0,
            onExhibition: false
        });
        emit ArtSubmittedForExhibition(submissionCounter, _tokenId, msg.sender);
    }

    /// @notice Allows registered gallery members to vote on submitted artworks for exhibition.
    /// @param _submissionId ID of the exhibition submission.
    /// @param _vote True for approval, false for disapproval.
    function voteOnExhibitionSubmission(uint256 _submissionId, bool _vote) external onlyGalleryMember notPaused {
        require(exhibitionSubmissions[_submissionId].submissionId == _submissionId, "Invalid submission ID.");
        require(!submissionVotes[_submissionId][msg.sender], "You have already voted on this submission.");

        submissionVotes[_submissionId][msg.sender] = true; // Mark as voted
        if (_vote) {
            exhibitionSubmissions[_submissionId].voteCount++;
        } else {
            // Optionally handle negative votes if needed for more complex logic
        }
        emit ExhibitionVoteCast(_submissionId, msg.sender, _vote);
    }

    /// @notice Gallery admin sets the duration of an exhibition cycle in days.
    /// @param _durationInDays Duration of the exhibition in days.
    function setExhibitionDuration(uint256 _durationInDays) external onlyGalleryAdmin notPaused {
        require(_durationInDays > 0 && _durationInDays <= 365, "Invalid exhibition duration."); // Reasonable duration limit
        exhibitionDurationDays = _durationInDays;
    }

    /// @notice Gallery admin initiates a new exhibition cycle, selecting artworks based on votes.
    function startNewExhibitionCycle() external onlyGalleryAdmin notPaused {
        currentExhibitionCycle++;
        currentExhibitionArtNFTs = new uint256[](0); // Clear previous exhibition

        uint256 bestSubmissionsCount = 0; // Number of top voted submissions to exhibit (can be configurable)
        if (submissionCounter > 0 ) {
            bestSubmissionsCount = submissionCounter < 5 ? submissionCounter : 5; // Example: Exhibit top 5 or fewer if less submissions
        }


        uint256[] memory topSubmissionIds = getTopVotedSubmissions(bestSubmissionsCount);

        for (uint256 i = 0; i < topSubmissionIds.length; i++) {
            uint256 tokenId = exhibitionSubmissions[topSubmissionIds[i]].tokenId;
            currentExhibitionArtNFTs.push(tokenId);
            exhibitionSubmissions[topSubmissionIds[i]].onExhibition = true; // Mark as on exhibition

            // Example reward system (can be more sophisticated)
            rewardExhibitingArtists(tokenId);
        }

        emit ExhibitionCycleStarted(currentExhibitionCycle, currentExhibitionArtNFTs);

        // Reset submissions and votes for the next cycle (optional - could keep history)
        submissionCounter = 0;
        delete exhibitionSubmissions;
        delete submissionVotes;
    }

    /// @dev Helper function to get top voted submissions (simplified selection for example)
    function getTopVotedSubmissions(uint256 _count) private view returns (uint256[] memory) {
        uint256[] memory topSubmissions = new uint256[](_count);
        uint256 currentTopIndex = 0;
        uint256[] memory submissionIds = new uint256[](submissionCounter);
        uint256 submissionIndex = 0;
        for (uint256 i = 1; i <= submissionCounter; i++) {
            submissionIds[submissionIndex] = i;
            submissionIndex++;
        }

        // Simple sorting (can be optimized for large number of submissions)
        for (uint256 i = 0; i < submissionIds.length; i++) {
            for (uint256 j = i + 1; j < submissionIds.length; j++) {
                if (exhibitionSubmissions[submissionIds[i]].voteCount < exhibitionSubmissions[submissionIds[j]].voteCount) {
                    uint256 temp = submissionIds[i];
                    submissionIds[i] = submissionIds[j];
                    submissionIds[j] = temp;
                }
            }
        }

        for (uint256 i = 0; i < submissionIds.length && currentTopIndex < _count; i++) {
            topSubmissions[currentTopIndex] = submissionIds[i];
            currentTopIndex++;
        }

        return topSubmissions;
    }


    /// @notice Returns a list of Art NFT token IDs currently on exhibition.
    /// @return uint256[] Array of token IDs.
    function getCurrentExhibition() external view returns (uint256[] memory) {
        return currentExhibitionArtNFTs;
    }

    /// @notice Rewards artists whose NFTs are exhibited (example reward system).
    /// @param _tokenId ID of the exhibited Art NFT.
    function rewardExhibitingArtists(uint256 _tokenId) private {
        address artist = artNFTCreator[_tokenId];
        // Example: Mint and transfer a gallery utility token to the artist as a reward
        // (Requires implementation of a utility token contract and integration)
        // For now, just emit an event as a placeholder.
        uint256 rewardAmount = 10; // Example reward amount
        emit ArtistRewarded(_tokenId, artist, rewardAmount);
    }

    // --- 3. Dynamic Art NFT Features ---

    /// @notice Allows Art NFTs to evolve based on certain criteria (placeholder - needs complex logic).
    /// @param _tokenId ID of the Art NFT to evolve.
    /// @param _evolutionData Data representing the evolution criteria or parameters.
    function evolveArtNFT(uint256 _tokenId, string memory _evolutionData) external tokenExists(_tokenId) onlyTokenOwner(_tokenId) notPaused {
        // --- Complex logic for NFT evolution would go here ---
        // This could involve:
        // 1. Reading data from oracles (e.g., weather, market data, on-chain events)
        // 2. Applying transformation logic based on _evolutionData and current metadata
        // 3. Updating the artNFTMetadataURIs[_tokenId] with a new URI pointing to evolved metadata
        // 4. Potentially changing visual representation based on metadata changes (off-chain)

        // For this example, let's just append the _evolutionData to the metadata URI as a demonstration.
        string memory currentMetadataURI = artNFTMetadataURIs[_tokenId];
        string memory newMetadataURI = string(abi.encodePacked(currentMetadataURI, "?evolved=", _evolutionData));
        artNFTMetadataURIs[_tokenId] = newMetadataURI;

        emit ArtNFTMetadataUpdated(_tokenId, newMetadataURI);
    }

    /// @notice Checks the ownership history and authenticity of an Art NFT (basic provenance tracking).
    /// @param _tokenId ID of the Art NFT to check.
    /// @return uint256[] Array of timestamps representing ownership changes.
    function checkArtNFTProvenance(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256[] memory) {
        return artNFTProvenance[_tokenId];
    }

    /// @notice Allows adding interactive elements to the NFT metadata, making them dynamic (placeholder).
    /// @param _tokenId ID of the Art NFT to add interactive element to.
    /// @param _elementData Data representing the interactive element (e.g., JSON, link to interactive script).
    function setArtNFTInteractiveElement(uint256 _tokenId, string memory _elementData) external tokenExists(_tokenId) onlyTokenOwner(_tokenId) notPaused {
        // --- Logic to update metadata with interactive elements ---
        // This might involve:
        // 1. Parsing _elementData (e.g., validate JSON format)
        // 2. Modifying the artNFTMetadataURIs[_tokenId] to include this interactive data
        // 3. Front-end application would need to interpret this data to render interactive elements

        // Example: Just append the element data to the metadata URI (simple demonstration)
        string memory currentMetadataURI = artNFTMetadataURIs[_tokenId];
        string memory newMetadataURI = string(abi.encodePacked(currentMetadataURI, "?interactive=", _elementData));
        artNFTMetadataURIs[_tokenId] = newMetadataURI;

        emit ArtNFTMetadataUpdated(_tokenId, newMetadataURI);
    }

    // --- 4. Artist and Gallery Membership ---

    /// @notice Allows a user to register as an artist in the gallery.
    function registerAsArtist() external notPaused {
        require(!isRegisteredArtist[msg.sender], "Already registered as an artist.");
        isRegisteredArtist[msg.sender] = true;
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: "New Artist", // Default name, can be updated later
            artistBio: "Welcome to the gallery!" // Default bio, can be updated later
        });
        emit ArtistRegistered(msg.sender);
    }

    /// @notice Allows a user to register as a gallery member to participate in curation and governance.
    function registerAsGalleryMember() external notPaused {
        require(!isRegisteredGalleryMember[msg.sender], "Already registered as a gallery member.");
        isRegisteredGalleryMember[msg.sender] = true;
        galleryMemberProfiles[msg.sender] = GalleryMemberProfile({
            memberName: "New Member", // Default name, can be updated later
            memberBio: "Excited to be part of the gallery community!" // Default bio
        });
        emit GalleryMemberRegistered(msg.sender);
    }

    /// @notice Retrieves profile information for a registered artist.
    /// @param _artistAddress Address of the artist.
    /// @return ArtistProfile Struct containing artist profile details.
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        require(isRegisteredArtist[_artistAddress], "Address is not a registered artist.");
        return artistProfiles[_artistAddress];
    }

    /// @notice Retrieves profile information for a registered gallery member.
    /// @param _memberAddress Address of the gallery member.
    /// @return GalleryMemberProfile Struct containing gallery member profile details.
    function getGalleryMemberProfile(address _memberAddress) external view returns (GalleryMemberProfile memory) {
        require(isRegisteredGalleryMember[_memberAddress], "Address is not a registered gallery member.");
        return galleryMemberProfiles[_memberAddress];
    }

    // --- 5. Gallery Governance & Utility ---

    /// @notice Allows registered gallery members to propose changes to gallery rules.
    /// @param _proposalDescription Description of the rule change proposal.
    function proposeGalleryRuleChange(string memory _proposalDescription) external onlyGalleryMember notPaused {
        ruleChangeProposalCounter++;
        ruleChangeProposals[ruleChangeProposalCounter] = RuleChangeProposal({
            proposalId: ruleChangeProposalCounter,
            description: _proposalDescription,
            proposer: msg.sender,
            voteCount: 0,
            executed: false
        });
        emit GalleryRuleChangeProposed(ruleChangeProposalCounter, _proposalDescription, msg.sender);
    }

    /// @notice Allows registered gallery members to vote on rule change proposals.
    /// @param _proposalId ID of the rule change proposal.
    /// @param _vote True for approval, false for disapproval.
    function voteOnRuleChangeProposal(uint256 _proposalId, bool _vote) external onlyGalleryMember notPaused {
        require(ruleChangeProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!ruleChangeVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        require(!ruleChangeProposals[_proposalId].executed, "Proposal has already been executed.");

        ruleChangeVotes[_proposalId][msg.sender] = true; // Mark as voted
        if (_vote) {
            ruleChangeProposals[_proposalId].voteCount++;
        } else {
            // Optionally handle negative votes
        }
        emit GalleryRuleChangeVoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Gallery admin executes approved rule changes (e.g., based on vote threshold).
    /// @param _proposalId ID of the rule change proposal to execute.
    function executeRuleChange(uint256 _proposalId) external onlyGalleryAdmin notPaused {
        require(ruleChangeProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!ruleChangeProposals[_proposalId].executed, "Proposal already executed.");

        // Example: Simple majority vote threshold (can be more complex)
        uint256 totalMembers = 0; // In a real DAO, track active members
        for (uint256 i = 1; i <= galleryMemberProfiles.length; i++) { // Very inefficient iteration, needs better member tracking
            totalMembers++; //  Placeholder, improve member tracking in real implementation
        }
        if (totalMembers == 0) totalMembers = 1; // Avoid division by zero if no members

        if (ruleChangeProposals[_proposalId].voteCount > (totalMembers / 2)) { // Simple majority
            ruleChangeProposals[_proposalId].executed = true;
            // --- Implement the actual rule change logic here based on proposal description ---
            // This is highly dependent on what rules are meant to be changed in your gallery.
            // Examples: Change voting thresholds, update exhibition duration logic, modify reward mechanisms, etc.

            emit GalleryRuleChangeExecuted(_proposalId);
        } else {
            revert("Rule change proposal not approved by majority vote.");
        }
    }

    /// @notice Gallery admin sets the name of the decentralized art gallery.
    /// @param _galleryName New name for the gallery.
    function setGalleryName(string memory _galleryName) external onlyGalleryAdmin notPaused {
        require(bytes(_galleryName).length > 0 && bytes(_galleryName).length <= 100, "Gallery name must be between 1 and 100 characters.");
        galleryName = _galleryName;
        emit GalleryNameUpdated(_galleryName);
    }

    /// @notice Allows gallery admin to withdraw collected fees (placeholder - fee logic not implemented).
    function withdrawGalleryFees() external onlyGalleryAdmin notPaused {
        // --- Logic to collect and withdraw gallery fees would go here ---
        // This could involve:
        // 1. Implementing fee collection on minting, secondary sales, etc.
        // 2. Storing collected fees in the contract balance.
        // 3. This function would then transfer contract balance to the admin's address or a treasury.

        // For now, just a placeholder function.
        payable(galleryAdmin).transfer(address(this).balance);
    }

    /// @notice Gallery admin can pause the contract in case of emergency.
    function pauseContract() external onlyGalleryAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Gallery admin can unpause the contract to resume normal operations.
    function unpauseContract() external onlyGalleryAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback function to receive Ether (if needed for fee collection, donations, etc.) ---
    receive() external payable {}
}
```