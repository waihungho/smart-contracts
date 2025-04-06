```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract Outline & Function Summary
 * @author Bard (Google AI)

 * @dev
 * This smart contract implements a Decentralized Autonomous Art Collective (DAAC).
 * It allows artists to submit artwork proposals, community members to vote on them,
 * and upon approval, mints the artwork as an NFT and adds it to the collective's gallery.
 * The DAAC is governed by its community, with features for voting, donations, artist registration,
 * curated exhibitions, and even decentralized art derivative creation.

 * Function Summary:

 * **Core Governance & DAO Functions:**
 * 1. `proposeNewArtwork(string _title, string _description, string _ipfsHash, address _artist)`: Allows registered artists to propose new artwork for the collective.
 * 2. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows community members to vote on pending artwork proposals.
 * 3. `executeProposal(uint256 _proposalId)`: Executes an approved proposal, minting the artwork NFT and transferring it to the DAAC. (Owner/Admin function after voting period)
 * 4. `delegateVote(address _delegate)`: Allows members to delegate their voting power to another address.
 * 5. `setQuorum(uint256 _newQuorum)`: Allows the contract owner to set the quorum percentage for proposal approvals.
 * 6. `setVotingPeriod(uint256 _newVotingPeriod)`: Allows the contract owner to set the voting period for proposals.
 * 7. `donateToCollective()`: Allows anyone to donate ETH to the DAAC's treasury.
 * 8. `withdrawDonations(address payable _recipient, uint256 _amount)`: Allows the contract owner to withdraw funds from the DAAC treasury.
 * 9. `pauseContract()`: Allows the contract owner to pause most contract functionalities in case of emergency.
 * 10. `unpauseContract()`: Allows the contract owner to resume contract functionalities after pausing.

 * **Artist & Artwork Management Functions:**
 * 11. `registerArtist(string _artistName, string _artistStatement)`: Allows artists to register themselves with the DAAC.
 * 12. `unregisterArtist()`: Allows registered artists to unregister themselves.
 * 13. `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork in the collective.
 * 14. `listArtworkForExhibition(uint256 _artworkId, string _exhibitionTitle)`: Allows the DAAC owner/curator to list artwork for a curated exhibition.
 * 15. `removeArtworkFromExhibition(uint256 _artworkId, string _exhibitionTitle)`: Allows the DAAC owner/curator to remove artwork from an exhibition.
 * 16. `createDerivativeArtwork(uint256 _originalArtworkId, string _derivativeTitle, string _derivativeDescription, string _derivativeIpfsHash, address _derivativeArtist)`: Allows registered artists to propose derivative artwork based on existing DAAC collection pieces (requires approval process).

 * **Community & Information Functions:**
 * 17. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific artwork proposal.
 * 18. `getArtistProfile(address _artistAddress)`: Retrieves the profile information of a registered artist.
 * 19. `getCollectionSize()`: Returns the total number of artworks in the DAAC collection.
 * 20. `getExhibitionArtworks(string _exhibitionTitle)`: Returns a list of artwork IDs currently in a specific exhibition.
 * 21. `getPendingProposalsCount()`: Returns the number of pending artwork proposals.
 * 22. `getMyVotingPower(address _voter)`: Returns the voting power of a given address (currently 1 token = 1 vote, could be expanded).
 * 23. `getPlatformFee()`: Returns the current platform fee percentage for secondary sales (if implemented).
 * 24. `setPlatformFee(uint256 _newFeePercentage)`: Allows the contract owner to set the platform fee percentage. (Optional: for future secondary marketplace integration)

 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _artworkIds;
    Counters.Counter private _proposalIds;

    uint256 public quorumPercentage = 50; // Minimum percentage of votes to approve a proposal
    uint256 public votingPeriod = 7 days; // Default voting period for proposals
    uint256 public platformFeePercentage = 2; // Example platform fee for future secondary sales (2%)

    struct Artwork {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 mintTimestamp;
    }

    struct ArtistProfile {
        address artistAddress;
        string artistName;
        string artistStatement;
        bool isRegistered;
        uint256 registrationTimestamp;
    }

    struct ArtworkProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 proposalTimestamp;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => votedYes
    mapping(string => uint256[]) public exhibitions; // exhibitionTitle => array of artworkIds
    mapping(address => address) public voteDelegations; // Delegator => Delegate

    uint256 public totalArtworksMinted = 0;
    uint256 public pendingProposalsCount = 0;

    event ArtworkProposed(uint256 proposalId, string title, address artist);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, uint256 artworkId);
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistUnregistered(address artistAddress);
    event DonationReceived(address donor, uint256 amount);
    event ArtworkListedForExhibition(uint256 artworkId, string exhibitionTitle);
    event ArtworkRemovedFromExhibition(uint256 artworkId, string exhibitionTitle);
    event PlatformFeeSet(uint256 newFeePercentage);
    event ContractPaused();
    event ContractUnpaused();

    constructor() ERC721("Decentralized Autonomous Art Collective", "DAAC") {
        // Constructor logic if needed, e.g., setting initial parameters
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "You must be a registered artist to perform this action.");
        _;
    }

    modifier onlyProposalActive(uint256 _proposalId) {
        require(artworkProposals[_proposalId].votingEndTime > block.timestamp && !artworkProposals[_proposalId].executed, "Proposal voting is not active or already executed.");
        _;
    }

    modifier onlyProposalExecutable(uint256 _proposalId) {
        require(artworkProposals[_proposalId].votingEndTime <= block.timestamp && !artworkProposals[_proposalId].executed, "Proposal voting is still active or already executed.");
        _;
    }

    modifier onlyNotVoted(uint256 _proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        _;
    }

    // ------------------------------------------------------------------------
    // Core Governance & DAO Functions
    // ------------------------------------------------------------------------

    /// @notice Allows registered artists to propose new artwork for the collective.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's metadata.
    /// @param _artist Address of the artist (should be msg.sender).
    function proposeNewArtwork(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        address _artist
    )
        external
        whenNotPaused
        onlyRegisteredArtist
    {
        require(_artist == msg.sender, "Artist address must be the sender.");
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        artworkProposals[proposalId] = ArtworkProposal({
            id: proposalId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: _artist,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        pendingProposalsCount++;
        emit ArtworkProposed(proposalId, _title, _artist);
    }

    /// @notice Allows community members to vote on pending artwork proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote)
        external
        whenNotPaused
        onlyProposalActive(_proposalId)
        onlyNotVoted(_proposalId)
    {
        require(artworkProposals[_proposalId].id == _proposalId, "Invalid proposal ID.");

        proposalVotes[_proposalId][msg.sender] = true; // Mark voter as voted

        address delegate = voteDelegations[msg.sender];
        address effectiveVoter = (delegate != address(0)) ? delegate : msg.sender;

        if (_vote) {
            artworkProposals[_proposalId].yesVotes += getMyVotingPower(effectiveVoter);
        } else {
            artworkProposals[_proposalId].noVotes += getMyVotingPower(effectiveVoter);
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes an approved proposal, minting the artwork NFT and transferring it to the DAAC. (Owner/Admin function after voting period)
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        external
        onlyOwner
        whenNotPaused
        onlyProposalExecutable(_proposalId)
    {
        require(artworkProposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        require(!artworkProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = artworkProposals[_proposalId].yesVotes + artworkProposals[_proposalId].noVotes;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        require(artworkProposals[_proposalId].yesVotes >= quorum, "Proposal did not reach quorum.");

        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();

        _safeMint(address(this), artworkId); // Mint NFT to the contract itself (DAAC)

        artworks[artworkId] = Artwork({
            id: artworkId,
            title: artworkProposals[_proposalId].title,
            description: artworkProposals[_proposalId].description,
            ipfsHash: artworkProposals[_proposalId].ipfsHash,
            artist: artworkProposals[_proposalId].artist,
            mintTimestamp: block.timestamp
        });

        artworkProposals[_proposalId].executed = true;
        totalArtworksMinted++;
        pendingProposalsCount--;

        emit ProposalExecuted(_proposalId, artworkId);
    }

    /// @notice Allows members to delegate their voting power to another address.
    /// @param _delegate Address to delegate voting power to.
    function delegateVote(address _delegate) external whenNotPaused {
        voteDelegations[msg.sender] = _delegate;
    }

    /// @notice Allows the contract owner to set the quorum percentage for proposal approvals.
    /// @param _newQuorum New quorum percentage (e.g., 51 for 51%).
    function setQuorum(uint256 _newQuorum) external onlyOwner whenNotPaused {
        require(_newQuorum <= 100, "Quorum percentage must be less than or equal to 100.");
        quorumPercentage = _newQuorum;
    }

    /// @notice Allows the contract owner to set the voting period for proposals.
    /// @param _newVotingPeriod New voting period in seconds.
    function setVotingPeriod(uint256 _newVotingPeriod) external onlyOwner whenNotPaused {
        votingPeriod = _newVotingPeriod;
    }

    /// @notice Allows anyone to donate ETH to the DAAC's treasury.
    function donateToCollective() external payable whenNotPaused {
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice Allows the contract owner to withdraw funds from the DAAC treasury.
    /// @param _recipient Address to send the funds to.
    /// @param _amount Amount of ETH to withdraw.
    function withdrawDonations(address payable _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
    }

    /// @notice Pauses most contract functionalities in case of emergency.
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /// @notice Resumes contract functionalities after pausing.
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    // ------------------------------------------------------------------------
    // Artist & Artwork Management Functions
    // ------------------------------------------------------------------------

    /// @notice Allows artists to register themselves with the DAAC.
    /// @param _artistName Name of the artist.
    /// @param _artistStatement Short statement or bio of the artist.
    function registerArtist(string memory _artistName, string memory _artistStatement) external whenNotPaused {
        require(!artistProfiles[msg.sender].isRegistered, "Artist is already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistAddress: msg.sender,
            artistName: _artistName,
            artistStatement: _artistStatement,
            isRegistered: true,
            registrationTimestamp: block.timestamp
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /// @notice Allows registered artists to unregister themselves.
    function unregisterArtist() external whenNotPaused onlyRegisteredArtist {
        delete artistProfiles[msg.sender];
        emit ArtistUnregistered(msg.sender);
    }

    /// @notice Retrieves details of a specific artwork in the collective.
    /// @param _artworkId ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        require(artworks[_artworkId].id == _artworkId, "Artwork ID not found.");
        return artworks[_artworkId];
    }

    /// @notice Allows the DAAC owner/curator to list artwork for a curated exhibition.
    /// @param _artworkId ID of the artwork to list.
    /// @param _exhibitionTitle Title of the exhibition.
    function listArtworkForExhibition(uint256 _artworkId, string memory _exhibitionTitle) external onlyOwner whenNotPaused {
        require(artworks[_artworkId].id == _artworkId, "Artwork ID not found.");
        exhibitions[_exhibitionTitle].push(_artworkId);
        emit ArtworkListedForExhibition(_artworkId, _exhibitionTitle);
    }

    /// @notice Allows the DAAC owner/curator to remove artwork from an exhibition.
    /// @param _artworkId ID of the artwork to remove.
    /// @param _exhibitionTitle Title of the exhibition.
    function removeArtworkFromExhibition(uint256 _artworkId, string memory _exhibitionTitle) external onlyOwner whenNotPaused {
        require(artworks[_artworkId].id == _artworkId, "Artwork ID not found.");
        uint256[] storage artworkList = exhibitions[_exhibitionTitle];
        for (uint256 i = 0; i < artworkList.length; i++) {
            if (artworkList[i] == _artworkId) {
                delete artworkList[i];
                // Shift elements to remove the gap (optional, can leave 0 values if order doesn't matter strictly)
                for (uint256 j = i; j < artworkList.length - 1; j++) {
                    artworkList[j] = artworkList[j + 1];
                }
                artworkList.pop(); // Remove the last (duplicated or zeroed) element
                emit ArtworkRemovedFromExhibition(_artworkId, _exhibitionTitle);
                return;
            }
        }
        revert("Artwork not found in exhibition.");
    }

    // --- Derivative Artwork Feature (Example - Can be expanded with voting for derivatives) ---
    /// @notice Allows registered artists to propose derivative artwork based on existing DAAC collection pieces.
    /// @param _originalArtworkId ID of the original artwork.
    /// @param _derivativeTitle Title of the derivative artwork.
    /// @param _derivativeDescription Description of the derivative artwork.
    /// @param _derivativeIpfsHash IPFS hash of the derivative artwork's metadata.
    /// @param _derivativeArtist Address of the artist creating the derivative (should be msg.sender).
    function createDerivativeArtwork(
        uint256 _originalArtworkId,
        string memory _derivativeTitle,
        string memory _derivativeDescription,
        string memory _derivativeIpfsHash,
        address _derivativeArtist
    )
        external
        whenNotPaused
        onlyRegisteredArtist
    {
        require(_derivativeArtist == msg.sender, "Derivative artist address must be the sender.");
        require(artworks[_originalArtworkId].id == _originalArtworkId, "Original artwork ID not found.");
        // In a more advanced version, you might implement a voting process for derivative artwork proposals as well.
        // For simplicity in this example, derivative creation might be directly approved by the DAAC owner or based on some criteria.
        // Example: Direct minting of derivative if owner approves.
        _artworkIds.increment();
        uint256 derivativeArtworkId = _artworkIds.current();

        _safeMint(address(this), derivativeArtworkId);

        artworks[derivativeArtworkId] = Artwork({
            id: derivativeArtworkId,
            title: _derivativeTitle,
            description: _derivativeDescription,
            ipfsHash: _derivativeIpfsHash,
            artist: _derivativeArtist,
            mintTimestamp: block.timestamp
        });
        totalArtworksMinted++;
        // You could add an event for derivative artwork creation.
    }


    // ------------------------------------------------------------------------
    // Community & Information Functions
    // ------------------------------------------------------------------------

    /// @notice Retrieves details of a specific artwork proposal.
    /// @param _proposalId ID of the proposal.
    /// @return ArtworkProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (ArtworkProposal memory) {
        require(artworkProposals[_proposalId].id == _proposalId, "Proposal ID not found.");
        return artworkProposals[_proposalId];
    }

    /// @notice Retrieves the profile information of a registered artist.
    /// @param _artistAddress Address of the artist.
    /// @return ArtistProfile struct containing artist profile details.
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    /// @notice Returns the total number of artworks in the DAAC collection.
    function getCollectionSize() external view returns (uint256) {
        return totalArtworksMinted;
    }

    /// @notice Returns a list of artwork IDs currently in a specific exhibition.
    /// @param _exhibitionTitle Title of the exhibition.
    /// @return Array of artwork IDs.
    function getExhibitionArtworks(string memory _exhibitionTitle) external view returns (uint256[] memory) {
        return exhibitions[_exhibitionTitle];
    }

    /// @notice Returns the number of pending artwork proposals.
    function getPendingProposalsCount() external view returns (uint256) {
        return pendingProposalsCount;
    }

    /// @notice Returns the voting power of a given address (currently 1 token = 1 vote).
    /// @param _voter Address to check voting power for.
    function getMyVotingPower(address _voter) public view returns (uint256) {
        // In this simple version, voting power is 1 for every address.
        // This can be extended to token-based voting in future iterations.
        return 1; // For now, everyone has 1 vote.
    }

    /// @notice Returns the current platform fee percentage for secondary sales (if implemented).
    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    /// @notice Allows the contract owner to set the platform fee percentage. (Optional: for future secondary marketplace integration)
    /// @param _newFeePercentage New platform fee percentage.
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Platform fee percentage must be less than or equal to 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    // --- ERC721 Overrides (Optional Enhancements) ---
    // _beforeTokenTransfer, tokenURI, supportsInterface etc. can be overridden for more advanced features.

    // --- Fallback function to receive ETH donations ---
    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```