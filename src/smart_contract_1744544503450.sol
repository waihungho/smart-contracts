```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A sophisticated smart contract for a decentralized autonomous art gallery,
 *      incorporating advanced concepts of governance, dynamic NFTs, fractional ownership,
 *      and community-driven curation. This contract aims to provide a novel and engaging
 *      experience for artists, collectors, and art enthusiasts in the Web3 space.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Art Management:**
 *    - `submitArt(string _title, string _description, string _ipfsHash, uint256 _initialPrice)`: Artists submit their artwork for consideration.
 *    - `approveArt(uint256 _artId)`: Curators (or governance) approve submitted artwork for exhibition.
 *    - `rejectArt(uint256 _artId)`: Curators (or governance) reject submitted artwork.
 *    - `purchaseArt(uint256 _artId)`: Users purchase artwork directly from the gallery.
 *    - `transferArtOwnership(uint256 _artId, address _newOwner)`: Owner of an art piece can transfer full ownership.
 *
 * **2. Exhibition and Curation:**
 *    - `createExhibition(string _exhibitionName, string _exhibitionDescription, uint256 _startTime, uint256 _endTime)`: Create a new art exhibition.
 *    - `addArtToExhibition(uint256 _exhibitionId, uint256 _artId)`: Add approved art to a specific exhibition.
 *    - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId)`: Remove art from an exhibition.
 *    - `startExhibitionVote(uint256 _exhibitionId)`: Initiate a community vote to decide if an exhibition should start.
 *    - `voteOnExhibition(uint256 _exhibitionId, bool _support)`: Users vote on starting an exhibition.
 *    - `finalizeExhibition(uint256 _exhibitionId)`: Finalize the exhibition based on vote results (if vote is enabled).
 *
 * **3. Dynamic NFT and Evolution:**
 *    - `evolveArt(uint256 _artId, string _newMetadataIPFSHash)`: Allows artists to evolve their art, updating metadata (dynamic NFT aspect).
 *    - `requestArtEvolutionVote(uint256 _artId, string _newMetadataIPFSHash)`: Request community vote for art evolution (optional governance).
 *    - `voteOnArtEvolution(uint256 _artId, bool _support)`: Users vote on art evolution proposals.
 *    - `finalizeArtEvolution(uint256 _artId)`: Finalize art evolution based on vote results.
 *
 * **4. Fractional Ownership (Experimental):**
 *    - `fractionalizeArt(uint256 _artId, uint256 _numberOfFractions)`: Artists (or owners) can fractionalize their art into ERC20 tokens.
 *    - `redeemArtFraction(uint256 _artId, uint256 _fractionAmount)`: Fraction holders can potentially redeem fractions to claim collective ownership benefits (concept).
 *
 * **5. Governance and Community Features:**
 *    - `proposeGalleryParameterChange(string _parameterName, uint256 _newValue)`: Users can propose changes to gallery parameters (e.g., fees, voting thresholds).
 *    - `voteOnParameterChange(uint256 _proposalId, bool _support)`: Users vote on gallery parameter change proposals.
 *    - `finalizeParameterChange(uint256 _proposalId)`: Finalize and implement parameter changes based on vote results.
 *    - `donateToGallery()`: Users can donate ETH to support the gallery operations.
 *
 * **Advanced Concepts Implemented:**
 *    - **Decentralized Governance:**  Voting mechanisms for exhibitions, art evolution, and gallery parameters.
 *    - **Dynamic NFTs:**  Art can evolve and change metadata over time, driven by artists or community votes.
 *    - **Fractional Ownership (Conceptual):**  Exploration of art fractionalization for shared ownership and community engagement.
 *    - **Community Curation:**  Potentially involving community in art approval and exhibition decisions.
 *    - **Exhibition Management:**  Structured way to organize and present art in themed exhibitions.
 */

contract DecentralizedAutonomousArtGallery {

    // ** Structs and Enums **

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 initialPrice;
        uint256 currentPrice;
        address owner;
        bool isApproved;
        bool isEvolving; // Flag for art evolution process
        string currentMetadataIPFSHash; // To track dynamic metadata
    }

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool voteActive; // Flag for exhibition vote
        mapping(address => bool) votes; // Track votes for exhibition start
        uint256 votesFor;
        uint256 votesAgainst;
        bool votePassed;
    }

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        bool isActive;
        mapping(address => bool) votes;
        uint256 votesFor;
        uint256 votesAgainst;
        bool votePassed;
    }

    struct ArtEvolutionProposal {
        uint256 id;
        uint256 artId;
        string newMetadataIPFSHash;
        bool isActive;
        mapping(address => bool) votes;
        uint256 votesFor;
        uint256 votesAgainst;
        bool votePassed;
    }


    // ** State Variables **

    ArtPiece[] public artPieces;
    Exhibition[] public exhibitions;
    ParameterChangeProposal[] public parameterChangeProposals;
    ArtEvolutionProposal[] public artEvolutionProposals;

    uint256 public artCounter;
    uint256 public exhibitionCounter;
    uint256 public proposalCounter;
    uint256 public artEvolutionProposalCounter;

    address public galleryOwner;
    uint256 public galleryFeePercentage = 5; // 5% gallery fee on sales
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingThresholdPercentage = 50; // Percentage for vote to pass

    mapping(uint256 => address[]) public artInExhibition; // Track art pieces in each exhibition
    mapping(address => bool) public curators; // Addresses designated as curators

    // ** Events **

    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtApproved(uint256 artId, address curator);
    event ArtRejected(uint256 artId, address curator);
    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event ArtOwnershipTransferred(uint256 artId, address oldOwner, address newOwner);
    event ExhibitionCreated(uint256 exhibitionId, string name);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionVoteStarted(uint256 exhibitionId);
    event ExhibitionVoteCast(uint256 exhibitionId, address voter, bool support);
    event ExhibitionFinalized(uint256 exhibitionId, bool isActive);
    event ArtEvolved(uint256 artId, string newMetadataIPFSHash);
    event ArtEvolutionVoteRequested(uint256 proposalId, uint256 artId, string newMetadataIPFSHash);
    event ArtEvolutionVoteCast(uint256 proposalId, address voter, bool support);
    event ArtEvolutionFinalized(uint256 artId, string newMetadataIPFSHash);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoteCast(uint256 proposalId, address voter, bool support);
    event ParameterChangeFinalized(uint256 proposalId, string parameterName, uint256 newValue);
    event DonationReceived(address donor, uint256 amount);

    // ** Modifiers **

    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender] || msg.sender == galleryOwner, "Only curators or gallery owner can call this function.");
        _;
    }

    modifier artExists(uint256 _artId) {
        require(_artId < artPieces.length, "Art piece does not exist.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(_exhibitionId < exhibitions.length, "Exhibition does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < parameterChangeProposals.length, "Proposal does not exist.");
        _;
    }

    modifier artEvolutionProposalExists(uint256 _proposalId) {
        require(_proposalId < artEvolutionProposals.length, "Art evolution proposal does not exist.");
        _;
    }

    modifier isArtOwner(uint256 _artId) {
        require(artPieces[_artId].owner == msg.sender, "You are not the owner of this art piece.");
        _;
    }

    modifier isArtist(uint256 _artId) {
        require(artPieces[_artId].artist == msg.sender, "You are not the original artist of this art piece.");
        _;
    }

    modifier isNotApprovedArt(uint256 _artId) {
        require(!artPieces[_artId].isApproved, "Art is already approved.");
        _;
    }

    modifier isApprovedArt(uint256 _artId) {
        require(artPieces[_artId].isApproved, "Art is not approved yet.");
        _;
    }

    modifier isExhibitionVoteActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].voteActive, "Exhibition vote is not active.");
        _;
    }

    modifier isExhibitionVoteNotActive(uint256 _exhibitionId) {
        require(!exhibitions[_exhibitionId].voteActive, "Exhibition vote is already active.");
        _;
    }

    modifier isExhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        _;
    }

    modifier isExhibitionNotActive(uint256 _exhibitionId) {
        require(!exhibitions[_exhibitionId].isActive, "Exhibition is already active or finalized.");
        _;
    }

    modifier isArtEvolutionNotActive(uint256 _artId) {
        require(!artPieces[_artId].isEvolving, "Art evolution process is already active.");
        _;
    }

    modifier isArtEvolutionVoteActive(uint256 _proposalId) {
        require(artEvolutionProposals[_proposalId].isActive, "Art evolution vote is not active.");
        _;
    }

    modifier isArtEvolutionVoteNotActive(uint256 _proposalId) {
        require(!artEvolutionProposals[_proposalId].isActive, "Art evolution vote is already active.");
        _;
    }

    modifier isParameterChangeVoteActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Parameter change vote is not active.");
        _;
    }

    modifier isParameterChangeVoteNotActive(uint256 _proposalId) {
        require(!parameterChangeProposals[_proposalId].isActive, "Parameter change vote is already active.");
        _;
    }

    // ** Constructor **

    constructor() {
        galleryOwner = msg.sender;
    }

    // ** 1. Core Art Management Functions **

    /// @notice Artists submit their artwork for gallery consideration.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's metadata.
    /// @param _initialPrice Initial price of the artwork in Wei.
    function submitArt(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _initialPrice
    ) public {
        artPieces.push(ArtPiece({
            id: artCounter,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            initialPrice: _initialPrice,
            currentPrice: _initialPrice,
            owner: address(0), // Gallery initially owns it
            isApproved: false,
            isEvolving: false,
            currentMetadataIPFSHash: _ipfsHash
        }));
        emit ArtSubmitted(artCounter, msg.sender, _title);
        artCounter++;
    }

    /// @notice Curators approve submitted artwork for exhibition.
    /// @param _artId ID of the artwork to approve.
    function approveArt(uint256 _artId) public onlyCurator artExists(_artId) isNotApprovedArt(_artId) {
        artPieces[_artId].isApproved = true;
        emit ArtApproved(_artId, msg.sender);
    }

    /// @notice Curators reject submitted artwork.
    /// @param _artId ID of the artwork to reject.
    function rejectArt(uint256 _artId) public onlyCurator artExists(_artId) isNotApprovedArt(_artId) {
        // In this example, rejected art just remains unapproved.
        // More complex logic (e.g., removal, artist notification) could be added.
        emit ArtRejected(_artId, msg.sender);
    }

    /// @notice Users purchase approved artwork from the gallery.
    /// @param _artId ID of the artwork to purchase.
    function purchaseArt(uint256 _artId) public payable artExists(_artId) isApprovedArt(_artId) {
        require(artPieces[_artId].owner == address(0), "Art is not available for purchase from gallery.");
        require(msg.value >= artPieces[_artId].currentPrice, "Insufficient funds sent.");

        uint256 galleryFee = (artPieces[_artId].currentPrice * galleryFeePercentage) / 100;
        uint256 artistPayout = artPieces[_artId].currentPrice - galleryFee;

        // Transfer funds
        payable(artPieces[_artId].artist).transfer(artistPayout);
        payable(galleryOwner).transfer(galleryFee); // Gallery owner receives the fee

        // Update ownership
        artPieces[_artId].owner = msg.sender;
        emit ArtPurchased(_artId, msg.sender, artPieces[_artId].currentPrice);
    }

    /// @notice Owner of an art piece can transfer full ownership.
    /// @param _artId ID of the artwork to transfer.
    /// @param _newOwner Address of the new owner.
    function transferArtOwnership(uint256 _artId, address _newOwner) public artExists(_artId) isArtOwner(_artId) {
        require(_newOwner != address(0), "Invalid new owner address.");
        address oldOwner = artPieces[_artId].owner;
        artPieces[_artId].owner = _newOwner;
        emit ArtOwnershipTransferred(_artId, oldOwner, _newOwner);
    }

    // ** 2. Exhibition and Curation Functions **

    /// @notice Create a new art exhibition.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _exhibitionDescription Description of the exhibition.
    /// @param _startTime Unix timestamp for exhibition start time.
    /// @param _endTime Unix timestamp for exhibition end time.
    function createExhibition(
        string memory _exhibitionName,
        string memory _exhibitionDescription,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyCurator {
        exhibitions.push(Exhibition({
            id: exhibitionCounter,
            name: _exhibitionName,
            description: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            isActive: false,
            voteActive: false,
            votes: mapping(address => bool)(),
            votesFor: 0,
            votesAgainst: 0,
            votePassed: false
        }));
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName);
        exhibitionCounter++;
    }

    /// @notice Add approved art to a specific exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _artId ID of the artwork to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artId) public onlyCurator exhibitionExists(_exhibitionId) artExists(_artId) isApprovedArt(_artId) isExhibitionNotActive(_exhibitionId) {
        artInExhibition[_exhibitionId].push(address(uint160(_artId))); // Store artId as address for mapping compatibility (can be improved)
        emit ArtAddedToExhibition(_exhibitionId, _artId);
    }

    /// @notice Remove art from an exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _artId ID of the artwork to remove.
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId) public onlyCurator exhibitionExists(_exhibitionId) artExists(_artId) isExhibitionNotActive(_exhibitionId) {
        address[] storage exhibitionArt = artInExhibition[_exhibitionId];
        for (uint256 i = 0; i < exhibitionArt.length; i++) {
            if (exhibitionArt[i] == address(uint160(_artId))) {
                exhibitionArt[i] = exhibitionArt[exhibitionArt.length - 1];
                exhibitionArt.pop();
                emit ArtRemovedFromExhibition(_exhibitionId, _artId);
                return;
            }
        }
        revert("Art piece not found in this exhibition.");
    }

    /// @notice Initiate a community vote to decide if an exhibition should start.
    /// @param _exhibitionId ID of the exhibition to vote on.
    function startExhibitionVote(uint256 _exhibitionId) public onlyCurator exhibitionExists(_exhibitionId) isExhibitionNotActive(_exhibitionId) isExhibitionVoteNotActive(_exhibitionId) {
        exhibitions[_exhibitionId].voteActive = true;
        emit ExhibitionVoteStarted(_exhibitionId);
        // In a real DAO, voting would be time-bound and involve token holders.
        // This is a simplified example where anyone can vote.
    }

    /// @notice Users vote on starting an exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _support True for supporting, false for opposing.
    function voteOnExhibition(uint256 _exhibitionId, bool _support) public exhibitionExists(_exhibitionId) isExhibitionVoteActive(_exhibitionId) {
        require(!exhibitions[_exhibitionId].votes[msg.sender], "You have already voted.");
        exhibitions[_exhibitionId].votes[msg.sender] = true;
        if (_support) {
            exhibitions[_exhibitionId].votesFor++;
        } else {
            exhibitions[_exhibitionId].votesAgainst++;
        }
        emit ExhibitionVoteCast(_exhibitionId, msg.sender, _support);
    }

    /// @notice Finalize the exhibition based on vote results.
    /// @param _exhibitionId ID of the exhibition to finalize.
    function finalizeExhibition(uint256 _exhibitionId) public onlyCurator exhibitionExists(_exhibitionId) isExhibitionVoteActive(_exhibitionId) {
        require(block.timestamp > exhibitions[_exhibitionId].startTime, "Exhibition start time has not been reached yet."); // Ensure time constraint

        exhibitions[_exhibitionId].voteActive = false; // End voting
        uint256 totalVotes = exhibitions[_exhibitionId].votesFor + exhibitions[_exhibitionId].votesAgainst;
        uint256 percentageFor = 0;
        if (totalVotes > 0) {
            percentageFor = (exhibitions[_exhibitionId].votesFor * 100) / totalVotes;
        }

        if (percentageFor >= votingThresholdPercentage) {
            exhibitions[_exhibitionId].isActive = true;
            exhibitions[_exhibitionId].votePassed = true;
            emit ExhibitionFinalized(_exhibitionId, true);
        } else {
            exhibitions[_exhibitionId].isActive = false;
            exhibitions[_exhibitionId].votePassed = false;
            emit ExhibitionFinalized(_exhibitionId, false);
        }
    }

    // ** 3. Dynamic NFT and Evolution Functions **

    /// @notice Allows artists to evolve their art, updating metadata (dynamic NFT aspect).
    /// @param _artId ID of the artwork to evolve.
    /// @param _newMetadataIPFSHash New IPFS hash for updated metadata.
    function evolveArt(uint256 _artId, string memory _newMetadataIPFSHash) public isArtist(_artId) artExists(_artId) isArtEvolutionNotActive(_artId) {
        artPieces[_artId].isEvolving = true; // Mark art as evolving
        artPieces[_artId].currentMetadataIPFSHash = _newMetadataIPFSHash; // Update metadata
        artPieces[_artId].isEvolving = false; // Reset evolving flag
        emit ArtEvolved(_artId, _newMetadataIPFSHash);
    }

    /// @notice Request community vote for art evolution (optional governance).
    /// @param _artId ID of the artwork to evolve.
    /// @param _newMetadataIPFSHash New IPFS hash for updated metadata.
    function requestArtEvolutionVote(uint256 _artId, string memory _newMetadataIPFSHash) public isArtist(_artId) artExists(_artId) isArtEvolutionNotActive(_artId) {
        artEvolutionProposals.push(ArtEvolutionProposal({
            id: artEvolutionProposalCounter,
            artId: _artId,
            newMetadataIPFSHash: _newMetadataIPFSHash,
            isActive: true,
            votes: mapping(address => bool)(),
            votesFor: 0,
            votesAgainst: 0,
            votePassed: false
        }));
        emit ArtEvolutionVoteRequested(artEvolutionProposalCounter, _artId, _newMetadataIPFSHash);
        artEvolutionProposalCounter++;
    }

    /// @notice Users vote on art evolution proposals.
    /// @param _proposalId ID of the art evolution proposal.
    /// @param _support True for supporting, false for opposing evolution.
    function voteOnArtEvolution(uint256 _proposalId, bool _support) public artEvolutionProposalExists(_proposalId) isArtEvolutionVoteActive(_proposalId) {
        require(!artEvolutionProposals[_proposalId].votes[msg.sender], "You have already voted.");
        artEvolutionProposals[_proposalId].votes[msg.sender] = true;
        if (_support) {
            artEvolutionProposals[_proposalId].votesFor++;
        } else {
            artEvolutionProposals[_proposalId].votesAgainst++;
        }
        emit ArtEvolutionVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Finalize art evolution based on vote results.
    /// @param _proposalId ID of the art evolution proposal.
    function finalizeArtEvolution(uint256 _proposalId) public onlyCurator artEvolutionProposalExists(_proposalId) isArtEvolutionVoteActive(_proposalId) {
        ArtEvolutionProposal storage proposal = artEvolutionProposals[_proposalId];
        proposal.isActive = false; // End voting

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 percentageFor = 0;
        if (totalVotes > 0) {
            percentageFor = (proposal.votesFor * 100) / totalVotes;
        }

        if (percentageFor >= votingThresholdPercentage) {
            artPieces[proposal.artId].currentMetadataIPFSHash = proposal.newMetadataIPFSHash;
            proposal.votePassed = true;
            emit ArtEvolutionFinalized(proposal.artId, proposal.newMetadataIPFSHash);
        } else {
            proposal.votePassed = false;
        }
    }

    // ** 4. Fractional Ownership (Conceptual) Functions **

    // --- Conceptual Functions ---
    // Note: Implementing full fractional ownership requires ERC20 token contract
    // and more complex logic, which is beyond the scope of a single smart contract example.
    // These are placeholder functions to demonstrate the concept.

    /// @notice Artists (or owners) can fractionalize their art into ERC20 tokens.
    /// @param _artId ID of the artwork to fractionalize.
    /// @param _numberOfFractions Number of ERC20 fractions to create.
    function fractionalizeArt(uint256 _artId, uint256 _numberOfFractions) public isArtOwner(_artId) artExists(_artId) {
        // --- Conceptual ---
        // In a real implementation:
        // 1. Deploy a new ERC20 token contract representing fractions of the art.
        // 2. Mint _numberOfFractions tokens and distribute them (e.g., to the artist initially).
        // 3. Potentially lock the original NFT to represent fractional ownership.
        // --- Conceptual ---
        // For this example, we'll just emit an event to show the intent.
        emit ArtFractionalizedConcept(_artId, _numberOfFractions); // Custom event for conceptual feature
    }
    event ArtFractionalizedConcept(uint256 artId, uint256 numberOfFractions); // Conceptual event

    /// @notice Fraction holders can potentially redeem fractions to claim collective ownership benefits (concept).
    /// @param _artId ID of the artwork.
    /// @param _fractionAmount Amount of fractions to redeem.
    function redeemArtFraction(uint256 _artId, uint256 _fractionAmount) public {
        // --- Conceptual ---
        // In a real implementation:
        // 1. Check if msg.sender holds enough ERC20 fractions for _artId.
        // 2. Based on the number of fractions redeemed, grant certain rights or benefits
        //    related to the art piece (e.g., voting rights, access to exclusive content).
        // 3. Burn the redeemed fractions or mark them as used.
        // --- Conceptual ---
        // For this example, we'll just emit an event to show the intent.
        emit ArtFractionRedeemedConcept(_artId, _fractionAmount, msg.sender); // Custom event
    }
    event ArtFractionRedeemedConcept(uint256 artId, uint256 fractionAmount, address redeemer); // Conceptual event


    // ** 5. Governance and Community Features Functions **

    /// @notice Users can propose changes to gallery parameters (e.g., fees, voting thresholds).
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue) public {
        parameterChangeProposals.push(ParameterChangeProposal({
            id: proposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            isActive: true,
            votes: mapping(address => bool)(),
            votesFor: 0,
            votesAgainst: 0,
            votePassed: false
        }));
        emit ParameterChangeProposed(proposalCounter, _parameterName, _newValue);
        proposalCounter++;
    }

    /// @notice Users vote on gallery parameter change proposals.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _support True for supporting, false for opposing the change.
    function voteOnParameterChange(uint256 _proposalId, bool _support) public proposalExists(_proposalId) isParameterChangeVoteActive(_proposalId) {
        require(!parameterChangeProposals[_proposalId].votes[msg.sender], "You have already voted.");
        parameterChangeProposals[_proposalId].votes[msg.sender] = true;
        if (_support) {
            parameterChangeProposals[_proposalId].votesFor++;
        } else {
            parameterChangeProposals[_proposalId].votesAgainst++;
        }
        emit ParameterChangeVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Finalize and implement parameter changes based on vote results.
    /// @param _proposalId ID of the parameter change proposal.
    function finalizeParameterChange(uint256 _proposalId) public onlyGalleryOwner proposalExists(_proposalId) isParameterChangeVoteActive(_proposalId) { // Owner finalizes for now, could be DAO in future
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.isActive = false; // End voting

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 percentageFor = 0;
        if (totalVotes > 0) {
            percentageFor = (proposal.votesFor * 100) / totalVotes;
        }

        if (percentageFor >= votingThresholdPercentage) {
            proposal.votePassed = true;
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("galleryFeePercentage"))) {
                galleryFeePercentage = proposal.newValue;
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("votingDuration"))) {
                votingDuration = proposal.newValue;
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("votingThresholdPercentage"))) {
                votingThresholdPercentage = proposal.newValue;
            } else {
                revert("Unknown parameter name.");
            }
            emit ParameterChangeFinalized(_proposalId, proposal.parameterName, proposal.newValue);
        } else {
            proposal.votePassed = false;
        }
    }

    /// @notice Users can donate ETH to support the gallery operations.
    function donateToGallery() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    // ** Admin Functions (Owner Only) **

    /// @notice Set a new gallery owner.
    /// @param _newOwner Address of the new gallery owner.
    function setGalleryOwner(address _newOwner) public onlyGalleryOwner {
        require(_newOwner != address(0), "Invalid new owner address.");
        galleryOwner = _newOwner;
    }

    /// @notice Add a new curator.
    /// @param _curator Address of the curator to add.
    function addCurator(address _curator) public onlyGalleryOwner {
        curators[_curator] = true;
    }

    /// @notice Remove a curator.
    /// @param _curator Address of the curator to remove.
    function removeCurator(address _curator) public onlyGalleryOwner {
        curators[_curator] = false;
    }

    /// @notice Set the gallery fee percentage.
    /// @param _feePercentage New gallery fee percentage (e.g., 5 for 5%).
    function setGalleryFeePercentage(uint256 _feePercentage) public onlyGalleryOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        galleryFeePercentage = _feePercentage;
    }

    /// @notice Set the default voting duration.
    /// @param _durationInSeconds Voting duration in seconds.
    function setVotingDuration(uint256 _durationInSeconds) public onlyGalleryOwner {
        votingDuration = _durationInSeconds;
    }

    /// @notice Set the voting threshold percentage for proposals to pass.
    /// @param _thresholdPercentage Voting threshold percentage (e.g., 50 for 50%).
    function setVotingThresholdPercentage(uint256 _thresholdPercentage) public onlyGalleryOwner {
        require(_thresholdPercentage <= 100, "Voting threshold cannot exceed 100%.");
        votingThresholdPercentage = _thresholdPercentage;
    }

    // ** Fallback and Receive Functions **

    receive() external payable {
        donateToGallery(); // Allow direct ETH donations to the contract
    }

    fallback() external {}
}
```