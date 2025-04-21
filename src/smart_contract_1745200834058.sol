```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) where artists can collaborate,
 * propose art projects, vote on proposals, create collaborative NFTs, and manage a shared treasury.
 *
 * **Outline:**
 *
 * 1. **Initialization and Setup:**
 *    - `constructor`: Initializes the DAAC with initial parameters.
 *
 * 2. **Artist Membership Management:**
 *    - `requestArtistMembership()`: Allows artists to request membership.
 *    - `approveArtistMembership(address _artist)`: DAO controlled function to approve artist membership.
 *    - `revokeArtistMembership(address _artist)`: DAO controlled function to revoke artist membership.
 *    - `isArtist(address _artist)`: Checks if an address is a registered artist.
 *    - `getArtistList()`: Returns a list of registered artists.
 *
 * 3. **Art Project Proposal and Voting:**
 *    - `proposeArtProject(string memory _projectTitle, string memory _projectDescription, string memory _projectDetailsCID, uint256 _fundingGoal)`: Artists propose new art projects.
 *    - `voteOnProjectProposal(uint256 _proposalId, bool _vote)`: Registered artists vote on art project proposals.
 *    - `getProjectProposalDetails(uint256 _proposalId)`: Retrieves details of a specific project proposal.
 *    - `getProjectProposalStatus(uint256 _proposalId)`: Retrieves the current status of a project proposal (Pending, Approved, Rejected, Funded, Completed).
 *    - `getProjectProposalVoteCount(uint256 _proposalId)`: Retrieves the current vote count for a proposal.
 *
 * 4. **Project Funding and Treasury Management:**
 *    - `fundProject(uint256 _proposalId)`: Allows the DAO or treasury to fund approved projects.
 *    - `contributeToProjectTreasury() payable`: Allows anyone to contribute ETH to the DAAC's project treasury.
 *    - `getProjectTreasuryBalance()`: Returns the current balance of the project treasury.
 *    - `withdrawProjectFunds(uint256 _proposalId, uint256 _amount)`: DAO controlled function to withdraw funds from a funded project (e.g., for artist payouts).
 *
 * 5. **Collaborative NFT Creation and Management:**
 *    - `submitProjectCompletion(uint256 _proposalId, string memory _nftMetadataCID)`: Artist submits project completion with NFT metadata.
 *    - `mintCollaborativeNFT(uint256 _proposalId)`: DAO controlled function to mint a collaborative NFT upon project completion approval.
 *    - `setNFTBaseURI(string memory _baseURI)`: DAO controlled function to set the base URI for collaborative NFTs.
 *    - `tokenURI(uint256 _tokenId)` view returns (string memory)`: Returns the URI for a given NFT token ID.
 *    - `getNFTContractAddress()`: Returns the address of the deployed collaborative NFT contract.
 *
 * 6. **DAO Governance and Parameters:**
 *    - `setVotingDuration(uint256 _durationInBlocks)`: DAO controlled function to set the voting duration for proposals.
 *    - `setQuorumPercentage(uint256 _percentage)`: DAO controlled function to set the quorum percentage for proposals.
 *    - `getVotingDuration()`: Returns the current voting duration.
 *    - `getQuorumPercentage()`: Returns the current quorum percentage.
 *    - `getDAOAddress()`: Returns the address designated as the DAO controller.
 *    - `transferDAOControl(address _newDAOAddress)`: DAO controlled function to transfer DAO control to a new address.
 *
 * **Function Summary:**
 *
 * 1. `constructor(address _daoAddress, string memory _nftName, string memory _nftSymbol)`: Initialize DAAC with DAO address and NFT details.
 * 2. `requestArtistMembership()`: Artist requests to join the collective.
 * 3. `approveArtistMembership(address _artist)`: DAO approves artist membership requests.
 * 4. `revokeArtistMembership(address _artist)`: DAO revokes artist membership.
 * 5. `isArtist(address _artist)`: Check if an address is a registered artist.
 * 6. `getArtistList()`: Get list of registered artists.
 * 7. `proposeArtProject(string _projectTitle, string _projectDescription, string _projectDetailsCID, uint256 _fundingGoal)`: Artists propose new art projects.
 * 8. `voteOnProjectProposal(uint256 _proposalId, bool _vote)`: Artists vote on project proposals.
 * 9. `getProjectProposalDetails(uint256 _proposalId)`: Get details of a project proposal.
 * 10. `getProjectProposalStatus(uint256 _proposalId)`: Get status of a project proposal.
 * 11. `getProjectProposalVoteCount(uint256 _proposalId)`: Get vote count for a project proposal.
 * 12. `fundProject(uint256 _proposalId)`: DAO funds approved projects.
 * 13. `contributeToProjectTreasury() payable`: Contribute ETH to the treasury.
 * 14. `getProjectTreasuryBalance()`: Get treasury balance.
 * 15. `withdrawProjectFunds(uint256 _proposalId, uint256 _amount)`: DAO withdraws funds from projects.
 * 16. `submitProjectCompletion(uint256 _proposalId, string _nftMetadataCID)`: Artist submits project completion with NFT metadata.
 * 17. `mintCollaborativeNFT(uint256 _proposalId)`: DAO mints collaborative NFT for completed projects.
 * 18. `setNFTBaseURI(string _baseURI)`: DAO sets base URI for NFTs.
 * 19. `tokenURI(uint256 _tokenId)`: Get URI for an NFT token ID.
 * 20. `getNFTContractAddress()`: Get address of the NFT contract.
 * 21. `setVotingDuration(uint256 _durationInBlocks)`: DAO sets voting duration.
 * 22. `setQuorumPercentage(uint256 _percentage)`: DAO sets quorum percentage.
 * 23. `getVotingDuration()`: Get voting duration.
 * 24. `getQuorumPercentage()`: Get quorum percentage.
 * 25. `getDAOAddress()`: Get DAO address.
 * 26. `transferDAOControl(address _newDAOAddress)`: DAO transfers control to a new address.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtCollective is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    address public daoAddress; // Address of the DAO controller
    mapping(address => bool) public isRegisteredArtist; // Mapping to track registered artists
    address[] public artistList; // Array to store registered artists

    struct ArtProjectProposal {
        uint256 proposalId;
        string projectTitle;
        string projectDescription;
        string projectDetailsCID; // CID for detailed project information (e.g., IPFS)
        uint256 fundingGoal;
        uint256 voteCount;
        mapping(address => bool) votes; // Track votes per artist
        ProposalStatus status;
        address proposingArtist;
        string nftMetadataCID; // CID for NFT metadata, submitted upon completion
    }

    enum ProposalStatus { Pending, Approved, Rejected, Funded, Completed }

    mapping(uint256 => ArtProjectProposal) public projectProposals;
    Counters.Counter public proposalIdCounter;

    uint256 public votingDurationInBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 51; // Default quorum percentage for proposals (51%)

    uint256 public projectTreasuryBalance; // Treasury for project funding

    // --- NFT Contract Integration ---
    address public nftContractAddress;
    string public nftBaseURI;
    string public nftName;
    string public nftSymbol;

    // --- Events ---

    event ArtistMembershipRequested(address artist);
    event ArtistMembershipApproved(address artist);
    event ArtistMembershipRevoked(address artist);
    event ArtProjectProposed(uint256 proposalId, string projectTitle, address proposingArtist);
    event ProjectProposalVoted(uint256 proposalId, address artist, bool vote);
    event ProjectProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event ProjectFunded(uint256 proposalId, uint256 amount);
    event ProjectFundsWithdrawn(uint256 proposalId, uint256 amount);
    event ProjectCompletionSubmitted(uint256 proposalId, string nftMetadataCID);
    event CollaborativeNFTMinted(uint256 tokenId, uint256 proposalId);
    event NFTBaseURISet(string baseURI);
    event DAOControlTransferred(address newDAOAddress);


    // --- Constructor ---
    constructor(address _daoAddress, string memory _nftName, string memory _nftSymbol) Ownable() {
        require(_daoAddress != address(0), "DAO address cannot be zero address");
        daoAddress = _daoAddress;
        nftName = _nftName;
        nftSymbol = _nftSymbol;
        // Deploy the CollaborativeNFT contract during DAAC deployment
        CollaborativeNFT nftContract = new CollaborativeNFT(_nftName, _nftSymbol);
        nftContractAddress = address(nftContract);
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this function");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can call this function");
        _;
    }

    // --- Artist Membership Management ---

    function requestArtistMembership() public {
        require(!isRegisteredArtist[msg.sender], "Already a registered artist");
        emit ArtistMembershipRequested(msg.sender);
        // In a real DAO, this would trigger a voting process or similar.
        // For simplicity, we'll make it DAO-controlled approval in this example.
    }

    function approveArtistMembership(address _artist) public onlyDAO {
        require(!isRegisteredArtist[_artist], "Artist is already registered");
        isRegisteredArtist[_artist] = true;
        artistList.push(_artist);
        emit ArtistMembershipApproved(_artist);
    }

    function revokeArtistMembership(address _artist) public onlyDAO {
        require(isRegisteredArtist[_artist], "Artist is not registered");
        isRegisteredArtist[_artist] = false;
        // Remove from artistList (inefficient for large lists, consider alternative for production)
        for (uint256 i = 0; i < artistList.length; i++) {
            if (artistList[i] == _artist) {
                artistList[i] = artistList[artistList.length - 1];
                artistList.pop();
                break;
            }
        }
        emit ArtistMembershipRevoked(_artist);
    }

    function isArtist(address _artist) public view returns (bool) {
        return isRegisteredArtist[_artist];
    }

    function getArtistList() public view returns (address[] memory) {
        return artistList;
    }


    // --- Art Project Proposal and Voting ---

    function proposeArtProject(
        string memory _projectTitle,
        string memory _projectDescription,
        string memory _projectDetailsCID,
        uint256 _fundingGoal
    ) public onlyArtist {
        proposalIdCounter.increment();
        uint256 proposalId = proposalIdCounter.current();
        projectProposals[proposalId] = ArtProjectProposal({
            proposalId: proposalId,
            projectTitle: _projectTitle,
            projectDescription: _projectDescription,
            projectDetailsCID: _projectDetailsCID,
            fundingGoal: _fundingGoal,
            voteCount: 0,
            status: ProposalStatus.Pending,
            proposingArtist: msg.sender,
            nftMetadataCID: "" // Initially empty
        });
        emit ArtProjectProposed(proposalId, _projectTitle, msg.sender);
        emit ProjectProposalStatusUpdated(proposalId, ProposalStatus.Pending);
    }

    function voteOnProjectProposal(uint256 _proposalId, bool _vote) public onlyArtist {
        require(projectProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not in Pending status");
        require(!projectProposals[_proposalId].votes[msg.sender], "Artist has already voted");

        projectProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            projectProposals[_proposalId].voteCount++;
        }
        emit ProjectProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting is complete and update status
        if (block.number >= block.number + votingDurationInBlocks) { // Example of block-based duration
            _updateProposalStatus(_proposalId);
        }
    }

    function getProjectProposalDetails(uint256 _proposalId) public view returns (ArtProjectProposal memory) {
        require(_proposalId > 0 && _proposalId <= proposalIdCounter.current(), "Invalid proposal ID");
        return projectProposals[_proposalId];
    }

    function getProjectProposalStatus(uint256 _proposalId) public view returns (ProposalStatus) {
        require(_proposalId > 0 && _proposalId <= proposalIdCounter.current(), "Invalid proposal ID");
        return projectProposals[_proposalId].status;
    }

    function getProjectProposalVoteCount(uint256 _proposalId) public view returns (uint256) {
        require(_proposalId > 0 && _proposalId <= proposalIdCounter.current(), "Invalid proposal ID");
        return projectProposals[_proposalId].voteCount;
    }

    function _updateProposalStatus(uint256 _proposalId) internal {
        require(projectProposals[_proposalId].status == ProposalStatus.Pending, "Proposal status cannot be updated from current status");
        uint256 totalArtists = artistList.length;
        uint256 votesNeeded = (totalArtists * quorumPercentage) / 100;

        if (projectProposals[_proposalId].voteCount >= votesNeeded) {
            projectProposals[_proposalId].status = ProposalStatus.Approved;
            emit ProjectProposalStatusUpdated(_proposalId, ProposalStatus.Approved);
        } else {
            projectProposals[_proposalId].status = ProposalStatus.Rejected;
            emit ProjectProposalStatusUpdated(_proposalId, ProposalStatus.Rejected);
        }
    }

    // --- Project Funding and Treasury Management ---

    function fundProject(uint256 _proposalId) public onlyDAO {
        require(projectProposals[_proposalId].status == ProposalStatus.Approved, "Project proposal is not approved");
        require(projectTreasuryBalance >= projectProposals[_proposalId].fundingGoal, "Insufficient funds in treasury");

        projectTreasuryBalance -= projectProposals[_proposalId].fundingGoal;
        projectProposals[_proposalId].status = ProposalStatus.Funded;
        emit ProjectFunded(_proposalId, projectProposals[_proposalId].fundingGoal);
        emit ProjectProposalStatusUpdated(_proposalId, ProposalStatus.Funded);
    }

    function contributeToProjectTreasury() public payable {
        projectTreasuryBalance += msg.value;
    }

    function getProjectTreasuryBalance() public view returns (uint256) {
        return projectTreasuryBalance;
    }

    function withdrawProjectFunds(uint256 _proposalId, uint256 _amount) public onlyDAO {
        require(projectProposals[_proposalId].status == ProposalStatus.Funded || projectProposals[_proposalId].status == ProposalStatus.Completed, "Project is not funded or completed");
        require(_amount <= projectProposals[_proposalId].fundingGoal, "Withdrawal amount exceeds funding goal"); // Basic check, refine as needed
        require(address(this).balance >= _amount, "Contract has insufficient balance for withdrawal");

        payable(projectProposals[_proposalId].proposingArtist).transfer(_amount); // Example: Transfer to proposing artist
        emit ProjectFundsWithdrawn(_proposalId, _amount);
    }

    // --- Collaborative NFT Creation and Management ---

    function submitProjectCompletion(uint256 _proposalId, string memory _nftMetadataCID) public onlyArtist {
        require(projectProposals[_proposalId].status == ProposalStatus.Funded, "Project is not in Funded status");
        require(projectProposals[_proposalId].proposingArtist == msg.sender, "Only proposing artist can submit completion");
        require(bytes(_nftMetadataCID).length > 0, "NFT Metadata CID cannot be empty");

        projectProposals[_proposalId].nftMetadataCID = _nftMetadataCID;
        projectProposals[_proposalId].status = ProposalStatus.Completed; // Mark as completed pending NFT minting
        emit ProjectCompletionSubmitted(_proposalId, _nftMetadataCID);
        emit ProjectProposalStatusUpdated(_proposalId, ProposalStatus.Completed);
    }

    function mintCollaborativeNFT(uint256 _proposalId) public onlyDAO {
        require(projectProposals[_proposalId].status == ProposalStatus.Completed, "Project is not in Completed status");
        require(bytes(projectProposals[_proposalId].nftMetadataCID).length > 0, "NFT Metadata CID is missing");

        CollaborativeNFT nftContract = CollaborativeNFT(nftContractAddress);
        uint256 tokenId = nftContract.nextTokenIdCounter(); // Get next token ID
        nftContract.mintNFT(address(this), tokenId); // Mint to this contract (DAAC) initially, adjust as needed for ownership
        emit CollaborativeNFTMinted(tokenId, _proposalId);

        // Store the proposal ID in the NFT contract for potential reverse lookup or metadata association
        nftContract.setProjectProposalIdForToken(tokenId, _proposalId);

        projectProposals[_proposalId].status = ProposalStatus.Completed; // Keep as completed, or change to "NFTMinted" if needed
        emit ProjectProposalStatusUpdated(_proposalId, ProposalStatus.Completed); // Or emit a new status event
    }

    function setNFTBaseURI(string memory _baseURI) public onlyDAO {
        nftBaseURI = _baseURI;
        CollaborativeNFT(nftContractAddress).setBaseURI(_baseURI);
        emit NFTBaseURISet(_baseURI);
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return CollaborativeNFT(nftContractAddress).tokenURI(_tokenId);
    }

    function getNFTContractAddress() public view returns (address) {
        return nftContractAddress;
    }


    // --- DAO Governance and Parameters ---

    function setVotingDuration(uint256 _durationInBlocks) public onlyDAO {
        votingDurationInBlocks = _durationInBlocks;
    }

    function setQuorumPercentage(uint256 _percentage) public onlyDAO {
        require(_percentage <= 100, "Quorum percentage must be less than or equal to 100");
        quorumPercentage = _percentage;
    }

    function getVotingDuration() public view returns (uint256) {
        return votingDurationInBlocks;
    }

    function getQuorumPercentage() public view returns (uint256) {
        return quorumPercentage;
    }

    function getDAOAddress() public view returns (address) {
        return daoAddress;
    }

    function transferDAOControl(address _newDAOAddress) public onlyDAO {
        require(_newDAOAddress != address(0), "New DAO address cannot be zero address");
        emit DAOControlTransferred(_newDAOAddress);
        daoAddress = _newDAOAddress;
    }

    // --- Fallback function to receive ETH contributions ---
    receive() external payable {
        contributeToProjectTreasury();
    }
    fallback() external payable {
        contributeToProjectTreasury();
    }
}


// --- Collaborative NFT Contract (Separate Contract for better modularity) ---
contract CollaborativeNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string private _baseURI;
    mapping(uint256 => uint256) public tokenToProjectProposalId; // Map token ID to project proposal ID

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable() {
         _baseURI = ""; // Base URI can be set later by the DAO
    }

    function mintNFT(address recipient, uint256 tokenId) public onlyOwner {
        _tokenIdCounter.increment();
        _safeMint(recipient, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json")); // Example: baseURI/tokenId.json
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    function nextTokenIdCounter() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setProjectProposalIdForToken(uint256 tokenId, uint256 proposalId) public onlyOwner {
        tokenToProjectProposalId[tokenId] = proposalId;
    }

    function getProjectProposalIdForToken(uint256 tokenId) public view returns (uint256) {
        return tokenToProjectProposalId[tokenId];
    }
}
```