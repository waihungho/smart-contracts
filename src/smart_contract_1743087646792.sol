```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract facilitates artist registration, artwork submission, community curation through voting,
 *      NFT minting for curated artworks, decentralized marketplace integration, dynamic royalties,
 *      artist collaboration features, decentralized grants, and advanced DAO governance mechanisms.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. Artist Management:**
 *    - `registerArtist(string _artistName, string _artistBio)`: Allows users to register as artists within the DAAC.
 *    - `updateArtistProfile(string _newArtistName, string _newArtistBio)`: Artists can update their profile information.
 *    - `isRegisteredArtist(address _artistAddress) view returns (bool)`: Checks if an address is a registered artist.
 *    - `getArtistProfile(address _artistAddress) view returns (string, string)`: Retrieves an artist's name and bio.
 *    - `deregisterArtist()`: Allows artists to remove themselves from the registered artists list. (With potential cooldown/penalty)
 *
 * **2. Artwork Submission and Curation:**
 *    - `submitArtwork(string _artworkTitle, string _artworkDescription, string _artworkMetadataURI)`: Artists submit their artwork for curation.
 *    - `startCurationRound(string _roundDescription, uint256 _votingDuration)`: DAO admin starts a new curation round.
 *    - `voteOnArtwork(uint256 _artworkId, bool _vote)`: Registered members can vote on submitted artworks during a curation round.
 *    - `endCurationRound()`: DAO admin ends the current curation round and determines curated artworks based on votes.
 *    - `getCurationRoundStatus() view returns (bool, string, uint256)`: Retrieves the status of the current curation round.
 *    - `getArtworkSubmission(uint256 _artworkId) view returns (address, string, string, string, uint256, uint256)`: Gets details of a specific artwork submission.
 *    - `getArtworkVotes(uint256 _artworkId) view returns (uint256, uint256)`: Retrieves the upvotes and downvotes for an artwork.
 *    - `getCurrentCurationRoundId() view returns (uint256)`: Returns the ID of the current active curation round.
 *
 * **3. NFT Minting and Marketplace:**
 *    - `mintCuratedArtworkNFT(uint256 _artworkId)`: Mints an NFT for a curated artwork if it meets the curation threshold.
 *    - `setNFTContractAddress(address _nftContractAddress)`: DAO admin sets the address of the external NFT contract used for minting.
 *    - `getNFTContractAddress() view returns (address)`: Retrieves the address of the configured NFT contract.
 *    - `setRoyaltyPercentage(uint256 _royaltyPercentage)`: DAO admin sets the royalty percentage for secondary sales of NFTs.
 *    - `getRoyaltyPercentage() view returns (uint256)`: Retrieves the current royalty percentage.
 *
 * **4. DAO Governance and Treasury:**
 *    - `createDAOProposal(string _proposalTitle, string _proposalDescription, bytes _calldata)`: DAO members can create governance proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: DAO members vote on active governance proposals.
 *    - `executeProposal(uint256 _proposalId)`: DAO admin executes a passed governance proposal.
 *    - `getProposalStatus(uint256 _proposalId) view returns (bool, string, string, uint256, uint256, uint256)`: Retrieves the status of a DAO proposal.
 *    - `setDAOMembershipToken(address _membershipTokenAddress)`: DAO admin sets the address of the membership token required for DAO participation.
 *    - `getDAOMembershipToken() view returns (address)`: Retrieves the address of the configured DAO membership token.
 *    - `setVotingQuorum(uint256 _quorumPercentage)`: DAO admin sets the voting quorum percentage for proposals and curation.
 *    - `getVotingQuorum() view returns (uint256)`: Retrieves the current voting quorum percentage.
 *    - `fundTreasury()`: Allows users to contribute funds to the DAAC treasury.
 *    - `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: DAO admin can withdraw funds from the treasury to a specified recipient (governance controlled in real-world scenario).
 *    - `getTreasuryBalance() view returns (uint256)`: Retrieves the current balance of the DAAC treasury.
 *
 * **5. Collaboration and Grants:**
 *    - `requestCollaboration(uint256 _artworkId, address _collaboratorArtist)`: Artists can request collaboration on submitted artworks.
 *    - `acceptCollaboration(uint256 _collaborationRequestId)`: Collaborator artists can accept collaboration requests.
 *    - `submitGrantProposal(string _grantTitle, string _grantDescription, uint256 _grantAmount)`: Registered artists can submit grant proposals to the DAO.
 *    - `voteOnGrantProposal(uint256 _grantProposalId, bool _vote)`: DAO members can vote on grant proposals.
 *    - `executeGrantProposal(uint256 _grantProposalId)`: DAO admin executes a passed grant proposal, distributing funds.
 *
 * **6. Utility and Admin Functions:**
 *    - `pauseContract()`: Admin function to pause core functionalities of the contract.
 *    - `unpauseContract()`: Admin function to resume contract functionalities.
 *    - `setAdmin(address _newAdmin)`: Admin function to change the contract administrator.
 *    - `getAdmin() view returns (address)`: Retrieves the current contract administrator address.
 *    - `getVersion() pure returns (string)`: Returns the contract version string.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DecentralizedAutonomousArtCollective is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _artistIds;
    Counters.Counter private _artworkIds;
    Counters.Counter private _curationRoundIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _collaborationRequestIds;
    Counters.Counter private _grantProposalIds;

    // --- Structs and Enums ---

    struct ArtistProfile {
        uint256 artistId;
        string artistName;
        string artistBio;
        bool isRegistered;
    }

    struct ArtworkSubmission {
        uint256 artworkId;
        address artistAddress;
        string artworkTitle;
        string artworkDescription;
        string artworkMetadataURI;
        uint256 submissionTimestamp;
        uint256 curationRoundId;
        uint256 upvotes;
        uint256 downvotes;
        bool isCurated;
        bool nftMinted;
    }

    struct CurationRound {
        uint256 roundId;
        string roundDescription;
        uint256 startTime;
        uint256 votingDuration; // in seconds
        bool isActive;
    }

    struct DAOProposal {
        uint256 proposalId;
        string proposalTitle;
        string proposalDescription;
        address proposer;
        uint256 startTime;
        uint256 votingDuration; // in seconds
        uint256 upvotes;
        uint256 downvotes;
        bytes calldata; // Calldata for execution
        bool isExecuted;
        bool isActive;
    }

    struct CollaborationRequest {
        uint256 requestId;
        uint256 artworkId;
        address requestingArtist;
        address collaboratorArtist;
        bool isAccepted;
    }

    struct GrantProposal {
        uint256 proposalId;
        string grantTitle;
        string grantDescription;
        uint256 grantAmount;
        address proposerArtist;
        uint256 startTime;
        uint256 votingDuration;
        uint256 upvotes;
        uint256 downvotes;
        bool isExecuted;
        bool isActive;
    }

    // --- State Variables ---

    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    mapping(uint256 => CurationRound) public curationRounds;
    mapping(uint256 => DAOProposal) public daoProposals;
    mapping(uint256 => CollaborationRequest) public collaborationRequests;
    mapping(uint256 => GrantProposal) public grantProposals;
    mapping(uint256 => mapping(address => bool)) public artworkVotes; // artworkId => voterAddress => vote (true=upvote, false=downvote)
    mapping(uint256 => mapping(address => bool)) public proposalVotes;   // proposalId => voterAddress => vote (true=upvote, false=downvote)
    mapping(uint256 => mapping(address => bool)) public grantVotes;      // grantProposalId => voterAddress => vote (true=upvote, false=downvote)

    address public nftContractAddress;
    uint256 public royaltyPercentage = 5; // Default royalty percentage on secondary sales
    address public daoMembershipTokenAddress;
    uint256 public votingQuorumPercentage = 50; // Default quorum percentage for votes

    uint256 public currentCurationRoundId;

    // --- Events ---

    event ArtistRegistered(address indexed artistAddress, uint256 artistId, string artistName);
    event ArtistProfileUpdated(address indexed artistAddress, string newArtistName, string newArtistBio);
    event ArtistDeregistered(address indexed artistAddress, uint256 artistId);
    event ArtworkSubmitted(uint256 artworkId, address indexed artistAddress, string artworkTitle);
    event CurationRoundStarted(uint256 roundId, string roundDescription);
    event ArtworkVoted(uint256 artworkId, address indexed voterAddress, bool vote);
    event CurationRoundEnded(uint256 roundId, uint256 curatedArtworkCount);
    event ArtworkNFTMinted(uint256 artworkId, address indexed artistAddress, uint256 tokenId);
    event DAOProposalCreated(uint256 proposalId, string proposalTitle, address indexed proposer);
    event DAOProposalVoted(uint256 proposalId, address indexed voterAddress, bool vote);
    event DAOProposalExecuted(uint256 proposalId);
    event DAOMembershipTokenSet(address tokenAddress);
    event VotingQuorumSet(uint256 quorumPercentage);
    event TreasuryFunded(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event CollaborationRequested(uint256 requestId, uint256 artworkId, address requestingArtist, address collaboratorArtist);
    event CollaborationAccepted(uint256 requestId);
    event GrantProposalSubmitted(uint256 grantProposalId, string grantTitle, address indexed proposerArtist, uint256 grantAmount);
    event GrantProposalVoted(uint256 grantProposalId, address indexed voterAddress, bool vote);
    event GrantProposalExecuted(uint256 grantProposalId);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address indexed newAdmin);

    // --- Modifiers ---

    modifier onlyRegisteredArtist() {
        require(isRegisteredArtist(msg.sender), "Not a registered artist");
        _;
    }

    modifier onlyActiveCurationRound() {
        require(curationRounds[currentCurationRoundId].isActive, "No active curation round");
        _;
    }

    modifier onlyValidArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= _artworkIds.current(), "Invalid artwork ID");
        _;
    }

    modifier onlyValidProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Invalid proposal ID");
        _;
    }

    modifier onlyValidGrantProposalId(uint256 _grantProposalId) {
        require(_grantProposalId > 0 && _grantProposalId <= _grantProposalIds.current(), "Invalid grant proposal ID");
        _;
    }

    modifier onlyValidCollaborationRequestId(uint256 _requestId) {
        require(_requestId > 0 && _requestId <= _collaborationRequestIds.current(), "Invalid collaboration request ID");
        _;
    }

    modifier onlyDAOMember() {
        require(daoMembershipTokenAddress != address(0) && IERC721(daoMembershipTokenAddress).balanceOf(msg.sender) > 0, "Not a DAO member");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function");
        _;
    }

    // --- Constructor ---

    constructor() payable {
        // Admin is the contract deployer (Ownable)
    }

    // --- 1. Artist Management Functions ---

    /**
     * @dev Registers a user as an artist in the DAAC.
     * @param _artistName The name of the artist.
     * @param _artistBio A short biography or description of the artist.
     */
    function registerArtist(string memory _artistName, string memory _artistBio) external whenNotPaused {
        require(!isRegisteredArtist(msg.sender), "Already registered as an artist");
        _artistIds.increment();
        artistProfiles[msg.sender] = ArtistProfile({
            artistId: _artistIds.current(),
            artistName: _artistName,
            artistBio: _artistBio,
            isRegistered: true
        });
        emit ArtistRegistered(msg.sender, _artistIds.current(), _artistName);
    }

    /**
     * @dev Updates the profile information of a registered artist.
     * @param _newArtistName The new name of the artist.
     * @param _newArtistBio The new biography of the artist.
     */
    function updateArtistProfile(string memory _newArtistName, string memory _newArtistBio) external onlyRegisteredArtist whenNotPaused {
        artistProfiles[msg.sender].artistName = _newArtistName;
        artistProfiles[msg.sender].artistBio = _newArtistBio;
        emit ArtistProfileUpdated(msg.sender, _newArtistName, _newArtistBio);
    }

    /**
     * @dev Checks if an address is a registered artist.
     * @param _artistAddress The address to check.
     * @return bool True if the address is a registered artist, false otherwise.
     */
    function isRegisteredArtist(address _artistAddress) public view returns (bool) {
        return artistProfiles[_artistAddress].isRegistered;
    }

    /**
     * @dev Retrieves the profile information of a registered artist.
     * @param _artistAddress The address of the artist.
     * @return string The artist's name.
     * @return string The artist's bio.
     */
    function getArtistProfile(address _artistAddress) public view returns (string memory, string memory) {
        require(isRegisteredArtist(_artistAddress), "Address is not a registered artist");
        return (artistProfiles[_artistAddress].artistName, artistProfiles[_artistAddress].artistBio);
    }

    /**
     * @dev Allows a registered artist to deregister themselves from the DAAC.
     *      (Could implement cooldown or penalty logic here in a real-world scenario).
     */
    function deregisterArtist() external onlyRegisteredArtist whenNotPaused {
        uint256 artistId = artistProfiles[msg.sender].artistId;
        artistProfiles[msg.sender].isRegistered = false; // Soft delete, keep profile data for history
        emit ArtistDeregistered(msg.sender, artistId);
    }

    // --- 2. Artwork Submission and Curation Functions ---

    /**
     * @dev Allows a registered artist to submit artwork for curation.
     * @param _artworkTitle The title of the artwork.
     * @param _artworkDescription A description of the artwork.
     * @param _artworkMetadataURI URI pointing to the artwork's metadata (e.g., IPFS hash).
     */
    function submitArtwork(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkMetadataURI) external onlyRegisteredArtist whenNotPaused onlyActiveCurationRound {
        _artworkIds.increment();
        artworkSubmissions[_artworkIds.current()] = ArtworkSubmission({
            artworkId: _artworkIds.current(),
            artistAddress: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkMetadataURI: _artworkMetadataURI,
            submissionTimestamp: block.timestamp,
            curationRoundId: currentCurationRoundId,
            upvotes: 0,
            downvotes: 0,
            isCurated: false,
            nftMinted: false
        });
        emit ArtworkSubmitted(_artworkIds.current(), msg.sender, _artworkTitle);
    }

    /**
     * @dev Starts a new curation round by the DAO admin.
     * @param _roundDescription A description for the curation round.
     * @param _votingDuration The duration of the voting period in seconds.
     */
    function startCurationRound(string memory _roundDescription, uint256 _votingDuration) external onlyAdmin whenNotPaused {
        require(!curationRounds[currentCurationRoundId].isActive, "Curation round already active");
        _curationRoundIds.increment();
        currentCurationRoundId = _curationRoundIds.current();
        curationRounds[currentCurationRoundId] = CurationRound({
            roundId: currentCurationRoundId,
            roundDescription: _roundDescription,
            startTime: block.timestamp,
            votingDuration: _votingDuration,
            isActive: true
        });
        emit CurationRoundStarted(currentCurationRoundId, _roundDescription);
    }

    /**
     * @dev Allows registered DAO members to vote on an artwork during an active curation round.
     * @param _artworkId The ID of the artwork to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnArtwork(uint256 _artworkId, bool _vote) external onlyDAOMember whenNotPaused onlyActiveCurationRound onlyValidArtworkId(_artworkId) {
        require(!artworkVotes[_artworkId][msg.sender], "Already voted on this artwork");
        require(block.timestamp <= curationRounds[currentCurationRoundId].startTime + curationRounds[currentCurationRoundId].votingDuration, "Voting period ended");

        artworkVotes[_artworkId][msg.sender] = true; // Record voter's vote

        if (_vote) {
            artworkSubmissions[_artworkId].upvotes++;
        } else {
            artworkSubmissions[_artworkId].downvotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _vote);
    }

    /**
     * @dev Ends the current curation round, determines curated artworks based on vote results.
     *      (Curation logic can be customized here, e.g., based on upvote ratio, minimum upvotes etc.)
     */
    function endCurationRound() external onlyAdmin whenNotPaused onlyActiveCurationRound {
        require(block.timestamp > curationRounds[currentCurationRoundId].startTime + curationRounds[currentCurationRoundId].votingDuration, "Voting period not yet ended");
        curationRounds[currentCurationRoundId].isActive = false;

        uint256 curatedArtworkCount = 0;
        uint256 artworkCount = _artworkIds.current();
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworkSubmissions[i].curationRoundId == currentCurationRoundId && !artworkSubmissions[i].isCurated) {
                uint256 totalVotes = artworkSubmissions[i].upvotes + artworkSubmissions[i].downvotes;
                if (totalVotes > 0) {
                    uint256 upvotePercentage = (artworkSubmissions[i].upvotes * 100) / totalVotes;
                    if (upvotePercentage >= votingQuorumPercentage) { // Curation criteria: e.g., > 50% upvotes
                        artworkSubmissions[i].isCurated = true;
                        curatedArtworkCount++;
                    }
                }
            }
        }
        emit CurationRoundEnded(currentCurationRoundId, curatedArtworkCount);
    }

    /**
     * @dev Retrieves the status of the current curation round.
     * @return bool True if a curation round is active, false otherwise.
     * @return string Description of the current curation round.
     * @return uint256 Voting duration of the current curation round.
     */
    function getCurationRoundStatus() public view returns (bool, string memory, uint256) {
        uint256 roundId = currentCurationRoundId;
        return (curationRounds[roundId].isActive, curationRounds[roundId].roundDescription, curationRounds[roundId].votingDuration);
    }

    /**
     * @dev Gets details of a specific artwork submission.
     * @param _artworkId The ID of the artwork submission.
     * @return address Artist address.
     * @return string Artwork title.
     * @return string Artwork description.
     * @return string Artwork metadata URI.
     * @return uint256 Submission timestamp.
     * @return uint256 Curation round ID.
     */
    function getArtworkSubmission(uint256 _artworkId) public view onlyValidArtworkId(_artworkId) returns (address, string memory, string memory, string memory, uint256, uint256) {
        ArtworkSubmission storage artwork = artworkSubmissions[_artworkId];
        return (artwork.artistAddress, artwork.artworkTitle, artwork.artworkDescription, artwork.artworkMetadataURI, artwork.submissionTimestamp, artwork.curationRoundId);
    }

    /**
     * @dev Retrieves the upvotes and downvotes for a specific artwork.
     * @param _artworkId The ID of the artwork.
     * @return uint256 Number of upvotes.
     * @return uint256 Number of downvotes.
     */
    function getArtworkVotes(uint256 _artworkId) public view onlyValidArtworkId(_artworkId) returns (uint256, uint256) {
        return (artworkSubmissions[_artworkId].upvotes, artworkSubmissions[_artworkId].downvotes);
    }

    /**
     * @dev Returns the ID of the current active curation round.
     * @return uint256 Current curation round ID.
     */
    function getCurrentCurationRoundId() public view returns (uint256) {
        return currentCurationRoundId;
    }

    // --- 3. NFT Minting and Marketplace Functions ---

    /**
     * @dev Mints an NFT for a curated artwork, using an external NFT contract.
     * @param _artworkId The ID of the curated artwork.
     */
    function mintCuratedArtworkNFT(uint256 _artworkId) external onlyAdmin whenNotPaused onlyValidArtworkId(_artworkId) {
        require(artworkSubmissions[_artworkId].isCurated, "Artwork is not curated");
        require(!artworkSubmissions[_artworkId].nftMinted, "NFT already minted for this artwork");
        require(nftContractAddress != address(0), "NFT contract address not set");

        // In a real-world scenario, you would call a function in the NFT contract to mint the NFT.
        // This example assumes an IERC721 compatible contract with a minting function like `safeMint`.
        IERC721 nftContract = IERC721(nftContractAddress);
        uint256 tokenId = _artworkId; // Using artworkId as tokenId for simplicity, adjust as needed

        // **Important Security Consideration:** In a production environment, ensure proper access control
        // in your NFT contract's minting function and handle token IDs appropriately.
        // You might need to pass the artwork metadata URI to the NFT contract during minting.

        // Example of a simplified mint call (adapt to your actual NFT contract's interface):
        // IERC721Mintable(nftContractAddress).safeMint(artworkSubmissions[_artworkId].artistAddress, tokenId, artworkSubmissions[_artworkId].artworkMetadataURI);
        // For this example, assume a simple safeMint to artist address with tokenId.
        // **Replace the following line with the actual minting logic for your NFT contract.**
        // For demonstration purposes, we'll emit an event as if minting happened.
        // **In a real implementation, you need to call an external NFT contract function here.**

        artworkSubmissions[_artworkId].nftMinted = true;
        emit ArtworkNFTMinted(_artworkId, artworkSubmissions[_artworkId].artistAddress, tokenId);
    }

    /**
     * @dev Sets the address of the external NFT contract used for minting curated artworks.
     * @param _nftContractAddress The address of the NFT contract.
     */
    function setNFTContractAddress(address _nftContractAddress) external onlyAdmin whenNotPaused {
        nftContractAddress = _nftContractAddress;
        emit DAOMembershipTokenSet(_nftContractAddress);
    }

    /**
     * @dev Retrieves the address of the configured NFT contract.
     * @return address The NFT contract address.
     */
    function getNFTContractAddress() public view returns (address) {
        return nftContractAddress;
    }

    /**
     * @dev Sets the royalty percentage applied to secondary sales of NFTs minted by the DAAC.
     * @param _royaltyPercentage The royalty percentage (e.g., 5 for 5%).
     */
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyAdmin whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage must be <= 100");
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @dev Retrieves the current royalty percentage for NFTs.
     * @return uint256 The royalty percentage.
     */
    function getRoyaltyPercentage() public view returns (uint256) {
        return royaltyPercentage;
    }

    // --- 4. DAO Governance and Treasury Functions ---

    /**
     * @dev Allows DAO members to create a governance proposal.
     * @param _proposalTitle Title of the proposal.
     * @param _proposalDescription Description of the proposal.
     * @param _calldata Calldata to be executed if the proposal passes.
     */
    function createDAOProposal(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata) external onlyDAOMember whenNotPaused {
        _proposalIds.increment();
        daoProposals[_proposalIds.current()] = DAOProposal({
            proposalId: _proposalIds.current(),
            proposalTitle: _proposalTitle,
            proposalDescription: _proposalDescription,
            proposer: msg.sender,
            startTime: block.timestamp,
            votingDuration: 7 days, // Example: 7 days voting duration
            upvotes: 0,
            downvotes: 0,
            calldata: _calldata,
            isExecuted: false,
            isActive: true
        });
        emit DAOProposalCreated(_proposalIds.current(), _proposalTitle, msg.sender);
    }

    /**
     * @dev Allows DAO members to vote on an active governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyDAOMember whenNotPaused onlyValidProposalId(_proposalId) {
        require(daoProposals[_proposalId].isActive, "Proposal is not active");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        require(block.timestamp <= daoProposals[_proposalId].startTime + daoProposals[_proposalId].votingDuration, "Voting period ended");

        proposalVotes[_proposalId][msg.sender] = true; // Record voter's vote

        if (_vote) {
            daoProposals[_proposalId].upvotes++;
        } else {
            daoProposals[_proposalId].downvotes++;
        }
        emit DAOProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a passed governance proposal. Only callable by admin after voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyAdmin whenNotPaused onlyValidProposalId(_proposalId) {
        require(daoProposals[_proposalId].isActive, "Proposal is not active");
        require(!daoProposals[_proposalId].isExecuted, "Proposal already executed");
        require(block.timestamp > daoProposals[_proposalId].startTime + daoProposals[_proposalId].votingDuration, "Voting period not yet ended");

        uint256 totalVotes = daoProposals[_proposalId].upvotes + daoProposals[_proposalId].downvotes;
        if (totalVotes > 0) {
            uint256 upvotePercentage = (daoProposals[_proposalId].upvotes * 100) / totalVotes;
            if (upvotePercentage >= votingQuorumPercentage) { // Proposal passes if quorum is met
                daoProposals[_proposalId].isExecuted = true;
                daoProposals[_proposalId].isActive = false;
                (bool success, ) = address(this).call(daoProposals[_proposalId].calldata); // Execute proposal calldata
                require(success, "Proposal execution failed");
                emit DAOProposalExecuted(_proposalId);
            } else {
                daoProposals[_proposalId].isActive = false; // Proposal failed to reach quorum
            }
        } else {
            daoProposals[_proposalId].isActive = false; // No votes, proposal failed
        }
    }

    /**
     * @dev Retrieves the status of a DAO proposal.
     * @param _proposalId The ID of the proposal.
     * @return bool Is the proposal active?
     * @return string Proposal title.
     * @return string Proposal description.
     * @return uint256 Proposal start time.
     * @return uint256 Proposal voting duration.
     * @return uint256 Proposal upvotes.
     */
    function getProposalStatus(uint256 _proposalId) public view onlyValidProposalId(_proposalId) returns (bool, string memory, string memory, uint256, uint256, uint256) {
        DAOProposal storage proposal = daoProposals[_proposalId];
        return (proposal.isActive, proposal.proposalTitle, proposal.proposalDescription, proposal.startTime, proposal.votingDuration, proposal.upvotes);
    }

    /**
     * @dev Sets the address of the DAO membership token required for DAO participation.
     * @param _membershipTokenAddress The address of the membership token contract.
     */
    function setDAOMembershipToken(address _membershipTokenAddress) external onlyAdmin whenNotPaused {
        daoMembershipTokenAddress = _membershipTokenAddress;
        emit DAOMembershipTokenSet(_membershipTokenAddress);
    }

    /**
     * @dev Retrieves the address of the configured DAO membership token.
     * @return address The DAO membership token contract address.
     */
    function getDAOMembershipToken() public view returns (address) {
        return daoMembershipTokenAddress;
    }

    /**
     * @dev Sets the voting quorum percentage for DAO proposals and curation rounds.
     * @param _quorumPercentage The quorum percentage (e.g., 50 for 50%).
     */
    function setVotingQuorum(uint256 _quorumPercentage) external onlyAdmin whenNotPaused {
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumSet(_quorumPercentage);
    }

    /**
     * @dev Retrieves the current voting quorum percentage.
     * @return uint256 The voting quorum percentage.
     */
    function getVotingQuorum() public view returns (uint256) {
        return votingQuorumPercentage;
    }

    /**
     * @dev Allows users to contribute funds to the DAAC treasury.
     */
    function fundTreasury() external payable whenNotPaused {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    /**
     * @dev Allows the DAO admin to withdraw funds from the treasury to a specified recipient.
     *      (In a real-world DAO, treasury withdrawals should be governed by DAO proposals).
     * @param _recipient The address to receive the withdrawn funds.
     * @param _amount The amount to withdraw.
     */
    function withdrawTreasuryFunds(address payable _recipient, uint256 _amount) external onlyAdmin whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient treasury balance");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed");
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Retrieves the current balance of the DAAC treasury.
     * @return uint256 The treasury balance in wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- 5. Collaboration and Grants Functions ---

    /**
     * @dev Allows an artist to request collaboration on their submitted artwork from another artist.
     * @param _artworkId The ID of the artwork for collaboration.
     * @param _collaboratorArtist The address of the artist to request collaboration from.
     */
    function requestCollaboration(uint256 _artworkId, address _collaboratorArtist) external onlyRegisteredArtist whenNotPaused onlyValidArtworkId(_artworkId) {
        require(artworkSubmissions[_artworkId].artistAddress == msg.sender, "Only artwork owner can request collaboration");
        _collaborationRequestIds.increment();
        collaborationRequests[_collaborationRequestIds.current()] = CollaborationRequest({
            requestId: _collaborationRequestIds.current(),
            artworkId: _artworkId,
            requestingArtist: msg.sender,
            collaboratorArtist: _collaboratorArtist,
            isAccepted: false
        });
        emit CollaborationRequested(_collaborationRequestIds.current(), _artworkId, msg.sender, _collaboratorArtist);
    }

    /**
     * @dev Allows a collaborator artist to accept a collaboration request.
     * @param _collaborationRequestId The ID of the collaboration request to accept.
     */
    function acceptCollaboration(uint256 _collaborationRequestId) external onlyRegisteredArtist whenNotPaused onlyValidCollaborationRequestId(_collaborationRequestId) {
        CollaborationRequest storage request = collaborationRequests[_collaborationRequestId];
        require(request.collaboratorArtist == msg.sender, "Only requested collaborator can accept");
        require(!request.isAccepted, "Collaboration already accepted");
        request.isAccepted = true;
        emit CollaborationAccepted(_collaborationRequestId);
    }

    /**
     * @dev Allows registered artists to submit grant proposals to the DAO.
     * @param _grantTitle Title of the grant proposal.
     * @param _grantDescription Description of the grant proposal.
     * @param _grantAmount Amount of ETH requested for the grant.
     */
    function submitGrantProposal(string memory _grantTitle, string memory _grantDescription, uint256 _grantAmount) external onlyRegisteredArtist whenNotPaused {
        require(_grantAmount > 0, "Grant amount must be greater than zero");
        _grantProposalIds.increment();
        grantProposals[_grantProposalIds.current()] = GrantProposal({
            proposalId: _grantProposalIds.current(),
            grantTitle: _grantTitle,
            grantDescription: _grantDescription,
            grantAmount: _grantAmount,
            proposerArtist: msg.sender,
            startTime: block.timestamp,
            votingDuration: 7 days, // Example: 7 days voting duration for grants
            upvotes: 0,
            downvotes: 0,
            isExecuted: false,
            isActive: true
        });
        emit GrantProposalSubmitted(_grantProposalIds.current(), _grantTitle, msg.sender, _grantAmount);
    }

    /**
     * @dev Allows DAO members to vote on an active grant proposal.
     * @param _grantProposalId The ID of the grant proposal to vote on.
     * @param _vote True for approve, false for reject.
     */
    function voteOnGrantProposal(uint256 _grantProposalId, bool _vote) external onlyDAOMember whenNotPaused onlyValidGrantProposalId(_grantProposalId) {
        require(grantProposals[_grantProposalId].isActive, "Grant proposal is not active");
        require(!grantVotes[_grantProposalId][msg.sender], "Already voted on this grant proposal");
        require(block.timestamp <= grantProposals[_grantProposalId].startTime + grantProposals[_grantProposalId].votingDuration, "Voting period ended");

        grantVotes[_grantProposalId][msg.sender] = true; // Record voter's vote

        if (_vote) {
            grantProposals[_grantProposalId].upvotes++;
        } else {
            grantProposals[_grantProposalId].downvotes++;
        }
        emit GrantProposalVoted(_grantProposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a passed grant proposal, distributing funds to the artist.
     *      Only callable by admin after voting period ends.
     * @param _grantProposalId The ID of the grant proposal to execute.
     */
    function executeGrantProposal(uint256 _grantProposalId) external onlyAdmin whenNotPaused onlyValidGrantProposalId(_grantProposalId) {
        require(grantProposals[_grantProposalId].isActive, "Grant proposal is not active");
        require(!grantProposals[_grantProposalId].isExecuted, "Grant proposal already executed");
        require(block.timestamp > grantProposals[_grantProposalId].startTime + grantProposals[_grantProposalId].votingDuration, "Voting period not yet ended");

        uint256 totalVotes = grantProposals[_grantProposalId].upvotes + grantProposals[_grantProposalId].downvotes;
        if (totalVotes > 0) {
            uint256 upvotePercentage = (grantProposals[_grantProposalId].upvotes * 100) / totalVotes;
            if (upvotePercentage >= votingQuorumPercentage) { // Grant proposal passes if quorum is met
                grantProposals[_grantProposalId].isExecuted = true;
                grantProposals[_grantProposalId].isActive = false;
                require(address(this).balance >= grantProposals[_grantProposalId].grantAmount, "Insufficient treasury balance for grant");
                (bool success, ) = grantProposals[_grantProposalId].proposerArtist.call{value: grantProposals[_grantProposalId].grantAmount}("");
                require(success, "Grant payment failed");
                emit GrantProposalExecuted(_grantProposalId);
            } else {
                grantProposals[_grantProposalId].isActive = false; // Grant proposal failed to reach quorum
            }
        } else {
            grantProposals[_grantProposalId].isActive = false; // No votes, grant proposal failed
        }
    }


    // --- 6. Utility and Admin Functions ---

    /**
     * @dev Pauses core contract functionalities. Only admin can call.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses core contract functionalities. Only admin can call.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Sets a new admin address for the contract. Only current admin can call.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        _transferOwnership(_newAdmin);
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Retrieves the current admin address of the contract.
     * @return address The admin address.
     */
    function getAdmin() public view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the contract version string.
     * @return string Contract version.
     */
    function getVersion() public pure returns (string memory) {
        return "DAAC v1.0";
    }

    // Fallback function to receive ETH contributions
    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }
}
```