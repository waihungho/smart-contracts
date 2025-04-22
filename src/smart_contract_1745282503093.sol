```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a Decentralized Autonomous Art Collective, enabling artists to create,
 * collaborate, and govern a shared digital art space. It features advanced concepts like dynamic NFTs,
 * collaborative art pieces, community-driven curation, and decentralized governance.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Art NFT Functionality:**
 *    - `mintArtNFT(string memory _metadataURI)`: Allows approved artists to mint unique Art NFTs.
 *    - `transferArtNFT(address _to, uint256 _tokenId)`: Standard ERC721 transfer function.
 *    - `getArtNFTMetadata(uint256 _tokenId)`: Retrieves the metadata URI of an Art NFT.
 *    - `burnArtNFT(uint256 _tokenId)`: Allows NFT owners to burn their Art NFTs.
 *
 * **2. Collaborative Art Pieces:**
 *    - `createCollaborativeArt(string memory _title, string memory _description, address[] memory _collaborators)`: Initializes a collaborative art project.
 *    - `addContributorToCollaborativeArt(uint256 _collaborativeArtId, address _contributor)`: Allows existing collaborators to add new contributors.
 *    - `submitContribution(uint256 _collaborativeArtId, string memory _contributionData)`:  Allows approved contributors to submit their artistic contributions.
 *    - `finalizeCollaborativeArt(uint256 _collaborativeArtId, string memory _finalMetadataURI)`: Finalizes a collaborative piece, minting an NFT representing the collective work.
 *    - `viewCollaborativeArtDetails(uint256 _collaborativeArtId)`: Retrieves details of a collaborative art project.
 *
 * **3. Dynamic NFT Features:**
 *    - `setDynamicNFTData(uint256 _tokenId, string memory _newData)`: (Admin/Oracle function) Updates the dynamic data associated with a Dynamic Art NFT.
 *    - `getDynamicNFTData(uint256 _tokenId)`: Retrieves the dynamic data of a Dynamic Art NFT.
 *    - `toggleDynamicNFTState(uint256 _tokenId)`: Allows the NFT owner to toggle a state within their Dynamic NFT (e.g., interactive element).
 *
 * **4. Community Governance and Curation:**
 *    - `proposeNewExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription)`: Allows community members to propose new digital art exhibitions.
 *    - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`:  Allows token holders to vote on exhibition proposals.
 *    - `executeExhibition(uint256 _proposalId)`: Executes a successfully voted exhibition proposal (admin function).
 *    - `submitArtForExhibition(uint256 _exhibitionId, uint256 _artTokenId)`:  Artists can submit their Art NFTs for consideration in an exhibition.
 *    - `voteOnExhibitionSubmission(uint256 _exhibitionId, uint256 _submissionId, bool _vote)`: Community voting on submitted artworks for exhibitions.
 *    - `finalizeExhibitionCuration(uint256 _exhibitionId)`: Finalizes the curation process for an exhibition based on community votes (admin function).
 *    - `viewExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of an art exhibition.
 *
 * **5. Artist and Collective Management:**
 *    - `addApprovedArtist(address _artistAddress)`:  Adds an address to the list of approved artists (admin function).
 *    - `removeApprovedArtist(address _artistAddress)`: Removes an address from the approved artists list (admin function).
 *    - `isApprovedArtist(address _artistAddress)`: Checks if an address is an approved artist.
 *    - `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 *    - `withdrawCollectiveFunds(address _recipient, uint256 _amount)`: Allows the contract owner to withdraw funds from the collective's treasury (admin function).
 *
 * **Advanced Concepts Implemented:**
 * - **Dynamic NFTs:** Art NFTs can have data that is updated post-mint, enabling evolving art pieces.
 * - **Collaborative Art:** Facilitates the creation of art pieces by multiple artists, with shared recognition.
 * - **Decentralized Curation:** Community-driven selection of artworks for exhibitions, leveraging token holder voting.
 * - **DAO-lite Governance:**  Exhibition proposals and curation processes are governed by community voting, demonstrating basic decentralized decision-making.
 * - **Artist Approval System:**  Maintains a curated list of approved artists to control the quality and authenticity of minted NFTs within the collective.
 */
contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    address public owner;
    string public contractName = "Decentralized Autonomous Art Collective";
    uint256 public nextArtTokenId = 1;
    uint256 public nextCollaborativeArtId = 1;
    uint256 public nextExhibitionProposalId = 1;
    uint256 public nextExhibitionSubmissionId = 1;

    mapping(uint256 => ArtNFT) public artNFTs; // tokenId => ArtNFT details
    mapping(uint256 => CollaborativeArt) public collaborativeArts; // collaborativeArtId => CollaborativeArt details
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals; // proposalId => ExhibitionProposal details
    mapping(uint256 => mapping(uint256 => ExhibitionSubmission)) public exhibitionSubmissions; // exhibitionId => submissionId => Submission details

    mapping(address => bool) public approvedArtists; // address => isApproved
    mapping(uint256 => string) public dynamicNFTData; // tokenId => dynamic data for dynamic NFTs

    // --- Structs ---

    struct ArtNFT {
        uint256 tokenId;
        address artist;
        string metadataURI;
        bool isDynamic;
    }

    struct CollaborativeArt {
        uint256 collaborativeArtId;
        string title;
        string description;
        address[] collaborators;
        string[] contributions;
        bool isFinalized;
        uint256 finalNFTTokenId; // Token ID of the minted NFT after finalization
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    struct ExhibitionSubmission {
        uint256 submissionId;
        uint256 artTokenId;
        address submitter;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
    }

    // --- Events ---

    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtNFTTransferred(address from, address to, uint256 tokenId);
    event ArtNFTBurned(uint256 tokenId, address burner);
    event CollaborativeArtCreated(uint256 collaborativeArtId, string title, address[] collaborators);
    event ContributorAddedToCollaborativeArt(uint256 collaborativeArtId, address contributor);
    event ContributionSubmitted(uint256 collaborativeArtId, address contributor, string contributionData);
    event CollaborativeArtFinalized(uint256 collaborativeArtId, uint256 finalNFTTokenId, string finalMetadataURI);
    event DynamicNFTDataUpdated(uint256 tokenId, string newData);
    event DynamicNFTStateToggled(uint256 tokenId, address owner);
    event ExhibitionProposalCreated(uint256 proposalId, address proposer, string title);
    event VoteCastOnExhibitionProposal(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 proposalId);
    event ArtSubmittedForExhibition(uint256 exhibitionId, uint256 submissionId, uint256 artTokenId, address submitter);
    event VoteCastOnExhibitionSubmission(uint256 exhibitionId, uint256 submissionId, address voter, bool vote);
    event ExhibitionCurationFinalized(uint256 exhibitionId, uint256[] curatedTokenIds);
    event ArtistApproved(address artistAddress);
    event ArtistRemoved(address artistAddress);
    event DonationReceived(address donor, uint256 amount);
    event FundsWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyApprovedArtist() {
        require(approvedArtists[msg.sender], "Only approved artists can call this function.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- 1. Core Art NFT Functionality ---

    /**
     * @dev Mints a new Art NFT for an approved artist.
     * @param _metadataURI URI pointing to the metadata of the NFT.
     */
    function mintArtNFT(string memory _metadataURI) public onlyApprovedArtist {
        uint256 tokenId = nextArtTokenId++;
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            artist: msg.sender,
            metadataURI: _metadataURI,
            isDynamic: false // Default is not dynamic, can be extended for dynamic NFTs later
        });
        emit ArtNFTMinted(tokenId, msg.sender, _metadataURI);
    }

    /**
     * @dev Transfers an Art NFT to another address. Standard ERC721 transfer.
     * @param _to Address to transfer the NFT to.
     * @param _tokenId ID of the NFT to transfer.
     */
    function transferArtNFT(address _to, uint256 _tokenId) public {
        // Basic ownership check - in a real ERC721, more complex approval logic would be needed
        require(artNFTs[_tokenId].artist == msg.sender, "You are not the owner of this NFT (simple ownership check)."); // Replace with proper ERC721 ownership logic
        require(_to != address(0), "Transfer to the zero address is not allowed.");

        // In a full ERC721, you'd update owner mappings here. For simplicity, this example uses artist as owner.
        artNFTs[_tokenId].artist = _to; // In a real ERC721, this would be more complex.
        emit ArtNFTTransferred(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Retrieves the metadata URI of an Art NFT.
     * @param _tokenId ID of the Art NFT.
     * @return metadataURI String representing the metadata URI.
     */
    function getArtNFTMetadata(uint256 _tokenId) public view returns (string memory metadataURI) {
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist.");
        return artNFTs[_tokenId].metadataURI;
    }

    /**
     * @dev Allows the owner of an Art NFT to burn it, effectively destroying it.
     * @param _tokenId ID of the Art NFT to burn.
     */
    function burnArtNFT(uint256 _tokenId) public {
        require(artNFTs[_tokenId].artist == msg.sender, "You are not the owner of this NFT."); // Simple ownership check
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist.");

        delete artNFTs[_tokenId]; // Remove the NFT data. In a real ERC721, you'd update ownership mappings too.
        emit ArtNFTBurned(_tokenId, msg.sender);
    }


    // --- 2. Collaborative Art Pieces ---

    /**
     * @dev Initializes a new collaborative art project.
     * @param _title Title of the collaborative art piece.
     * @param _description Description of the project.
     * @param _collaborators Array of initial collaborator addresses.
     */
    function createCollaborativeArt(string memory _title, string memory _description, address[] memory _collaborators) public onlyApprovedArtist {
        uint256 collaborativeArtId = nextCollaborativeArtId++;
        collaborativeArts[collaborativeArtId] = CollaborativeArt({
            collaborativeArtId: collaborativeArtId,
            title: _title,
            description: _description,
            collaborators: _collaborators,
            contributions: new string[](0), // Initialize with empty contributions array
            isFinalized: false,
            finalNFTTokenId: 0
        });
        emit CollaborativeArtCreated(collaborativeArtId, _title, _collaborators);
    }

    /**
     * @dev Allows an existing collaborator to add a new contributor to a collaborative art project.
     * @param _collaborativeArtId ID of the collaborative art project.
     * @param _contributor Address of the new contributor to add.
     */
    function addContributorToCollaborativeArt(uint256 _collaborativeArtId, address _contributor) public {
        require(collaborativeArts[_collaborativeArtId].collaborativeArtId != 0, "Collaborative art project does not exist.");
        bool isCollaborator = false;
        for (uint256 i = 0; i < collaborativeArts[_collaborativeArtId].collaborators.length; i++) {
            if (collaborativeArts[_collaborativeArtId].collaborators[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "Only existing collaborators can add new contributors.");

        // Check if contributor is already in the list
        bool alreadyContributor = false;
        for (uint256 i = 0; i < collaborativeArts[_collaborativeArtId].collaborators.length; i++) {
            if (collaborativeArts[_collaborativeArtId].collaborators[i] == _contributor) {
                alreadyContributor = true;
                break;
            }
        }
        require(!alreadyContributor, "Contributor is already part of this collaborative art project.");

        collaborativeArts[_collaborativeArtId].collaborators.push(_contributor);
        emit ContributorAddedToCollaborativeArt(_collaborativeArtId, _contributor);
    }

    /**
     * @dev Allows approved contributors to submit their artistic contributions to a collaborative project.
     * @param _collaborativeArtId ID of the collaborative art project.
     * @param _contributionData String data representing the contribution (e.g., URI, text, etc.).
     */
    function submitContribution(uint256 _collaborativeArtId, string memory _contributionData) public {
        require(collaborativeArts[_collaborativeArtId].collaborativeArtId != 0, "Collaborative art project does not exist.");
        bool isCollaborator = false;
        for (uint256 i = 0; i < collaborativeArts[_collaborativeArtId].collaborators.length; i++) {
            if (collaborativeArts[_collaborativeArtId].collaborators[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "Only collaborators can submit contributions.");
        require(!collaborativeArts[_collaborativeArtId].isFinalized, "Collaborative art is already finalized.");

        collaborativeArts[_collaborativeArtId].contributions.push(_contributionData);
        emit ContributionSubmitted(_collaborativeArtId, msg.sender, _contributionData);
    }

    /**
     * @dev Finalizes a collaborative art piece and mints an NFT representing the collective work.
     * @param _collaborativeArtId ID of the collaborative art project.
     * @param _finalMetadataURI URI pointing to the metadata of the finalized collaborative NFT.
     */
    function finalizeCollaborativeArt(uint256 _collaborativeArtId, string memory _finalMetadataURI) public onlyApprovedArtist {
        require(collaborativeArts[_collaborativeArtId].collaborativeArtId != 0, "Collaborative art project does not exist.");
        require(!collaborativeArts[_collaborativeArtId].isFinalized, "Collaborative art is already finalized.");

        uint256 tokenId = nextArtTokenId++;
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            artist: address(this), // Contract is the "artist" for collaborative pieces
            metadataURI: _finalMetadataURI,
            isDynamic: false
        });
        collaborativeArts[_collaborativeArtId].isFinalized = true;
        collaborativeArts[_collaborativeArtId].finalNFTTokenId = tokenId;

        emit CollaborativeArtFinalized(_collaborativeArtId, tokenId, _finalMetadataURI);
        emit ArtNFTMinted(tokenId, address(this), _finalMetadataURI); // Emit NFT mint event for the finalized piece
    }

    /**
     * @dev Retrieves details of a collaborative art project.
     * @param _collaborativeArtId ID of the collaborative art project.
     * @return title, description, collaborators, contributions, isFinalized, finalNFTTokenId
     */
    function viewCollaborativeArtDetails(uint256 _collaborativeArtId) public view returns (
        string memory title,
        string memory description,
        address[] memory collaborators,
        string[] memory contributions,
        bool isFinalized,
        uint256 finalNFTTokenId
    ) {
        require(collaborativeArts[_collaborativeArtId].collaborativeArtId != 0, "Collaborative art project does not exist.");
        CollaborativeArt memory art = collaborativeArts[_collaborativeArtId];
        return (art.title, art.description, art.collaborators, art.contributions, art.isFinalized, art.finalNFTTokenId);
    }

    // --- 3. Dynamic NFT Features ---

    /**
     * @dev (Admin/Oracle function) Updates the dynamic data associated with a Dynamic Art NFT.
     *      Only the contract owner can call this function (acting as an oracle or admin).
     * @param _tokenId ID of the Dynamic Art NFT.
     * @param _newData String data to update the dynamic NFT data with.
     */
    function setDynamicNFTData(uint256 _tokenId, string memory _newData) public onlyOwner {
        require(artNFTs[_tokenId].tokenId != 0, "Dynamic Art NFT does not exist.");
        artNFTs[_tokenId].isDynamic = true; // Mark it as dynamic if not already
        dynamicNFTData[_tokenId] = _newData;
        emit DynamicNFTDataUpdated(_tokenId, _newData);
    }

    /**
     * @dev Retrieves the dynamic data of a Dynamic Art NFT.
     * @param _tokenId ID of the Dynamic Art NFT.
     * @return dynamicData String representing the dynamic data.
     */
    function getDynamicNFTData(uint256 _tokenId) public view returns (string memory dynamicData) {
        require(artNFTs[_tokenId].tokenId != 0, "Dynamic Art NFT does not exist.");
        return dynamicNFTData[_tokenId];
    }

    /**
     * @dev Allows the NFT owner to toggle a state within their Dynamic NFT (e.g., interactive element).
     *      This is a simple example of making NFTs interactive. The actual functionality is defined by how
     *      the metadata and external rendering engine interpret this "toggled" state.
     * @param _tokenId ID of the Dynamic Art NFT.
     */
    function toggleDynamicNFTState(uint256 _tokenId) public {
        require(artNFTs[_tokenId].artist == msg.sender, "You are not the owner of this Dynamic NFT."); // Simple ownership check
        require(artNFTs[_tokenId].tokenId != 0, "Dynamic Art NFT does not exist.");
        require(artNFTs[_tokenId].isDynamic, "NFT is not a Dynamic NFT.");

        // Example: Simple toggle logic - you could store more complex state if needed
        if (keccak256(bytes(dynamicNFTData[_tokenId])) == keccak256(bytes("toggled_off"))) {
            dynamicNFTData[_tokenId] = "toggled_on";
        } else {
            dynamicNFTData[_tokenId] = "toggled_off";
        }
        emit DynamicNFTStateToggled(_tokenId, msg.sender);
        emit DynamicNFTDataUpdated(_tokenId, dynamicNFTData[_tokenId]); // Optional: Emit data update event after toggle
    }


    // --- 4. Community Governance and Curation ---

    /**
     * @dev Allows community members to propose new digital art exhibitions.
     * @param _exhibitionTitle Title of the exhibition proposal.
     * @param _exhibitionDescription Description of the exhibition proposal.
     */
    function proposeNewExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription) public {
        uint256 proposalId = nextExhibitionProposalId++;
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            votingEndTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ExhibitionProposalCreated(proposalId, msg.sender, _exhibitionTitle);
    }

    /**
     * @dev Allows token holders to vote on exhibition proposals.
     *      In a real DAO, voting power would be based on token holdings.
     *      For simplicity, this example assumes each address has 1 vote.
     * @param _proposalId ID of the exhibition proposal to vote on.
     * @param _vote True for Yes, False for No.
     */
    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public {
        require(exhibitionProposals[_proposalId].proposalId != 0, "Exhibition proposal does not exist.");
        require(block.timestamp < exhibitionProposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(!exhibitionProposals[_proposalId].executed, "Proposal already executed.");

        // Basic voting - in a real DAO, voting power would be based on token balance/delegation
        if (_vote) {
            exhibitionProposals[_proposalId].yesVotes++;
        } else {
            exhibitionProposals[_proposalId].noVotes++;
        }
        emit VoteCastOnExhibitionProposal(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a successfully voted exhibition proposal. Only the contract owner can execute.
     *      In a real DAO, execution could be permissionless or governed by a timelock.
     * @param _proposalId ID of the exhibition proposal to execute.
     */
    function executeExhibition(uint256 _proposalId) public onlyOwner {
        require(exhibitionProposals[_proposalId].proposalId != 0, "Exhibition proposal does not exist.");
        require(block.timestamp >= exhibitionProposals[_proposalId].votingEndTime, "Voting period is still active.");
        require(!exhibitionProposals[_proposalId].executed, "Proposal already executed.");
        require(exhibitionProposals[_proposalId].yesVotes > exhibitionProposals[_proposalId].noVotes, "Proposal did not pass.");

        exhibitionProposals[_proposalId].executed = true;
        // In a real implementation, you would trigger actions based on the proposal (e.g., create an exhibition entity).
        emit ExhibitionProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows artists to submit their Art NFTs for consideration in an exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @param _artTokenId ID of the Art NFT to submit.
     */
    function submitArtForExhibition(uint256 _exhibitionId, uint256 _artTokenId) public onlyApprovedArtist {
        require(exhibitionProposals[_exhibitionId].proposalId != 0, "Exhibition does not exist.");
        require(!exhibitionProposals[_exhibitionId].executed, "Exhibition proposal has not been executed yet."); // Or check if exhibition is in "submission" phase.
        require(artNFTs[_artTokenId].artist == msg.sender, "You are not the owner of this Art NFT."); // Simple ownership check
        require(artNFTs[_artTokenId].tokenId != 0, "Art NFT does not exist.");

        uint256 submissionId = nextExhibitionSubmissionId++;
        exhibitionSubmissions[_exhibitionId][_submissionId] = ExhibitionSubmission({
            submissionId: submissionId,
            artTokenId: _artTokenId,
            submitter: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            approved: false
        });
        emit ArtSubmittedForExhibition(_exhibitionId, submissionId, _artTokenId, msg.sender);
    }

    /**
     * @dev Community voting on submitted artworks for exhibitions.
     *      Similar to proposal voting, simplified voting power.
     * @param _exhibitionId ID of the exhibition.
     * @param _submissionId ID of the artwork submission.
     * @param _vote True for Yes (include in exhibition), False for No (reject).
     */
    function voteOnExhibitionSubmission(uint256 _exhibitionId, uint256 _submissionId, bool _vote) public {
        require(exhibitionProposals[_exhibitionId].proposalId != 0, "Exhibition does not exist.");
        require(exhibitionSubmissions[_exhibitionId][_submissionId].submissionId != 0, "Art submission does not exist.");
        // Add time limit for submission voting if needed

        if (_vote) {
            exhibitionSubmissions[_exhibitionId][_submissionId].yesVotes++;
        } else {
            exhibitionSubmissions[_exhibitionId][_submissionId].noVotes++;
        }
        emit VoteCastOnExhibitionSubmission(_exhibitionId, _submissionId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes the curation process for an exhibition based on community votes. Admin function.
     * @param _exhibitionId ID of the exhibition.
     */
    function finalizeExhibitionCuration(uint256 _exhibitionId) public onlyOwner {
        require(exhibitionProposals[_exhibitionId].proposalId != 0, "Exhibition does not exist.");
        require(exhibitionProposals[_exhibitionId].executed, "Exhibition proposal must be executed first.");

        uint256 submissionCount = 0;
        uint256 curatedCount = 0;
        uint256[] memory curatedTokenIds = new uint256[](0);

        // Iterate through submissions and determine which are curated based on votes
        for (uint256 submissionId = 1; submissionId <= nextExhibitionSubmissionId; submissionId++) { // Simple iteration, might be better to track submission IDs more efficiently
            if (exhibitionSubmissions[_exhibitionId][submissionId].submissionId != 0) {
                submissionCount++;
                if (exhibitionSubmissions[_exhibitionId][submissionId].yesVotes > exhibitionSubmissions[_exhibitionId][submissionId].noVotes) {
                    exhibitionSubmissions[_exhibitionId][submissionId].approved = true;
                    curatedCount++;
                    curatedTokenIds.push(exhibitionSubmissions[_exhibitionId][submissionId].artTokenId);
                } else {
                    exhibitionSubmissions[_exhibitionId][submissionId].approved = false;
                }
            }
        }

        emit ExhibitionCurationFinalized(_exhibitionId, curatedTokenIds);
        // In a real implementation, you would now display the curated NFTs in the exhibition.
    }

    /**
     * @dev Retrieves details of an art exhibition.
     * @param _exhibitionId ID of the art exhibition.
     * @return title, description, proposalExecuted, curatedArtTokenIds
     */
    function viewExhibitionDetails(uint256 _exhibitionId) public view returns (
        string memory title,
        string memory description,
        bool proposalExecuted,
        uint256[] memory curatedArtTokenIds
    ) {
        require(exhibitionProposals[_exhibitionId].proposalId != 0, "Exhibition does not exist.");
        ExhibitionProposal memory proposal = exhibitionProposals[_exhibitionId];
        uint256[] memory curatedTokenIds = new uint256[](0);

        for (uint256 submissionId = 1; submissionId <= nextExhibitionSubmissionId; submissionId++) {
            if (exhibitionSubmissions[_exhibitionId][submissionId].submissionId != 0 && exhibitionSubmissions[_exhibitionId][submissionId].approved) {
                curatedTokenIds.push(exhibitionSubmissions[_exhibitionId][submissionId].artTokenId);
            }
        }

        return (proposal.title, proposal.description, proposal.executed, curatedTokenIds);
    }


    // --- 5. Artist and Collective Management ---

    /**
     * @dev Adds an address to the list of approved artists. Only contract owner can call.
     * @param _artistAddress Address to approve as an artist.
     */
    function addApprovedArtist(address _artistAddress) public onlyOwner {
        approvedArtists[_artistAddress] = true;
        emit ArtistApproved(_artistAddress);
    }

    /**
     * @dev Removes an address from the list of approved artists. Only contract owner can call.
     * @param _artistAddress Address to remove from approved artists.
     */
    function removeApprovedArtist(address _artistAddress) public onlyOwner {
        approvedArtists[_artistAddress] = false;
        emit ArtistRemoved(_artistAddress);
    }

    /**
     * @dev Checks if an address is an approved artist.
     * @param _artistAddress Address to check.
     * @return isApproved True if the address is an approved artist, false otherwise.
     */
    function isApprovedArtist(address _artistAddress) public view returns (bool isApproved) {
        return approvedArtists[_artistAddress];
    }

    /**
     * @dev Allows anyone to donate ETH to the collective's treasury.
     */
    function donateToCollective() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allows the contract owner to withdraw funds from the collective's treasury.
     * @param _recipient Address to send the funds to.
     * @param _amount Amount of ETH to withdraw.
     */
    function withdrawCollectiveFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- Fallback and Receive (optional - for receiving ETH) ---

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```