```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini AI (Conceptual Example)
 * @dev A smart contract for a decentralized art collective, showcasing advanced concepts
 * and trendy functionalities. This is a conceptual example and requires further security audits
 * and considerations for production use.
 *
 * **Outline and Function Summary:**
 *
 * **Core Collective Management:**
 * 1. `joinCollective(string _artistStatement)`: Allows artists to request membership in the collective with a statement.
 * 2. `approveArtist(address _artist)`: DAO-governed function to approve pending artist applications.
 * 3. `removeArtist(address _artist)`: DAO-governed function to remove an artist from the collective.
 * 4. `getArtistProfile(address _artist)`: Retrieves artist profile information including statement and approved status.
 * 5. `updateArtistStatement(string _newStatement)`: Allows artists to update their profile statement.
 * 6. `depositCollectiveFunds()`: Allows anyone to deposit ETH into the collective's treasury.
 * 7. `withdrawCollectiveFunds(uint256 _amount)`: DAO-governed function to withdraw funds from the treasury.
 * 8. `getCollectiveBalance()`: Returns the current balance of the collective's treasury.
 *
 * **Art Submission and Curation:**
 * 9. `submitArtProposal(string _artTitle, string _artDescription, string _ipfsHash, uint256 _value)`: Artists submit art proposals with details and a proposed value.
 * 10. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: DAO members vote on submitted art proposals.
 * 11. `executeArtProposal(uint256 _proposalId)`: Executes an approved art proposal, minting an NFT (conceptual).
 * 12. `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 * 13. `getAllArtProposals()`: Returns a list of all art proposal IDs.
 * 14. `purchaseArtNFT(uint256 _artId)`: Allows users to purchase art NFTs from the collective (conceptual).
 * 15. `listArtForSale(uint256 _artId, uint256 _price)`: DAO-governed function to list collective-owned art for sale.
 * 16. `delistArtForSale(uint256 _artId)`: DAO-governed function to delist art from sale.
 * 17. `getArtListingDetails(uint256 _artId)`: Retrieves listing details for a specific art NFT.
 *
 * **DAO Governance and Utilities:**
 * 18. `proposeNewParameter(string _parameterName, uint256 _newValue)`: DAO members propose changes to contract parameters (e.g., voting periods).
 * 19. `voteOnParameterProposal(uint256 _proposalId, bool _vote)`: DAO members vote on parameter change proposals.
 * 20. `executeParameterProposal(uint256 _proposalId)`: Executes an approved parameter change proposal.
 * 21. `getParameterProposalDetails(uint256 _proposalId)`: Retrieves details of a specific parameter change proposal.
 * 22. `getAllParameterProposals()`: Returns a list of all parameter change proposal IDs.
 * 23. `getCurrentVotingPeriod()`: Returns the current voting period duration.
 * 24. `setVotingPeriod(uint256 _newPeriod)`: Owner-only function to set the initial voting period (can be DAO-governed later).
 * 25. `pauseContract()`: Owner-only function to pause core functionalities in emergencies.
 * 26. `unpauseContract()`: Owner-only function to resume contract functionalities.
 */

contract DecentralizedArtCollective {
    // --- State Variables ---

    address public owner; // Contract owner, initially the deployer
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public proposalCounter = 0; // Counter for proposals
    uint256 public artCounter = 0; // Counter for art pieces

    mapping(address => ArtistProfile) public artistProfiles; // Artist profiles
    mapping(uint256 => ArtProposal) public artProposals; // Art proposals
    mapping(uint256 => ParameterProposal) public parameterProposals; // Parameter change proposals
    mapping(uint256 => ArtNFT) public artNFTs; // Conceptual Art NFTs managed by collective
    mapping(uint256 => ArtListing) public artListings; // Art listings for sale

    address[] public pendingArtists; // List of artists pending approval
    address[] public collectiveArtists; // List of approved collective artists

    bool public paused = false; // Contract pause status

    struct ArtistProfile {
        string artistStatement;
        bool isApproved;
    }

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string artTitle;
        string artDescription;
        string ipfsHash;
        uint256 value; // Proposed value for the art
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 votingEndTime;
    }

    struct ParameterProposal {
        uint256 proposalId;
        address proposer;
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 votingEndTime;
    }

    struct ArtNFT {
        uint256 artId;
        string artTitle;
        string artDescription;
        string ipfsHash;
        address owner; // Initially collective, can be sold
    }

    struct ArtListing {
        uint256 artId;
        uint256 price;
        bool isListed;
    }


    // --- Events ---

    event ArtistApplicationSubmitted(address artist, string statement);
    event ArtistApproved(address artist);
    event ArtistRemoved(address artist);
    event ArtistStatementUpdated(address artist, string newStatement);
    event CollectiveFundsDeposited(address sender, uint256 amount);
    event CollectiveFundsWithdrawn(address recipient, uint256 amount);
    event ArtProposalCreated(uint256 proposalId, address proposer, string artTitle);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId, uint256 artId);
    event ArtNFTMinted(uint256 artId, string artTitle, address owner);
    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event ArtListedForSale(uint256 artId, uint256 price);
    event ArtDelistedFromSale(uint256 artId);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCollectiveArtist() {
        require(artistProfiles[msg.sender].isApproved, "Only approved artists can call this function.");
        _;
    }

    modifier onlyDAO() { // Simple DAO check - in real world, more robust governance needed
        require(isDAOMember(msg.sender), "Only DAO members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && (_proposalId <= proposalCounter), "Proposal does not exist.");
        _;
    }

    modifier artProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && (_proposalId <= proposalCounter && artProposals[_proposalId].proposalId == _proposalId), "Art proposal does not exist.");
        _;
        require(!artProposals[_proposalId].executed, "Art proposal already executed."); // Prevent re-execution
        require(block.timestamp < artProposals[_proposalId].votingEndTime, "Voting period has ended."); // Voting period still active
        _;
    }

    modifier parameterProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && (_proposalId <= proposalCounter && parameterProposals[_proposalId].proposalId == _proposalId), "Parameter proposal does not exist.");
        _;
        require(!parameterProposals[_proposalId].executed, "Parameter proposal already executed."); // Prevent re-execution
        require(block.timestamp < parameterProposals[_proposalId].votingEndTime, "Voting period has ended."); // Voting period still active
        _;
    }

    modifier artExists(uint256 _artId) {
        require(_artId > 0 && (_artId <= artCounter && artNFTs[_artId].artId == _artId), "Art NFT does not exist.");
        _;
    }

    modifier artNotListed(uint256 _artId) {
        require(!artListings[_artId].isListed, "Art is already listed for sale.");
        _;
    }

    modifier artIsListed(uint256 _artId) {
        require(artListings[_artId].isListed, "Art is not listed for sale.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Core Collective Management Functions ---

    /// @dev Allows artists to request membership in the collective.
    /// @param _artistStatement A statement from the artist about their work and intentions.
    function joinCollective(string memory _artistStatement) external notPaused {
        require(!artistProfiles[msg.sender].isApproved, "Artist is already a member or pending.");
        artistProfiles[msg.sender] = ArtistProfile({artistStatement: _artistStatement, isApproved: false});
        pendingArtists.push(msg.sender);
        emit ArtistApplicationSubmitted(msg.sender, _artistStatement);
    }

    /// @dev DAO-governed function to approve pending artist applications.
    /// @param _artist Address of the artist to approve.
    function approveArtist(address _artist) external onlyDAO notPaused {
        require(!artistProfiles[_artist].isApproved, "Artist is already approved.");
        artistProfiles[_artist].isApproved = true;
        collectiveArtists.push(_artist);
        // Remove from pending list (inefficient for large lists, consider better data structure for production)
        for (uint256 i = 0; i < pendingArtists.length; i++) {
            if (pendingArtists[i] == _artist) {
                pendingArtists[i] = pendingArtists[pendingArtists.length - 1];
                pendingArtists.pop();
                break;
            }
        }
        emit ArtistApproved(_artist);
    }

    /// @dev DAO-governed function to remove an artist from the collective.
    /// @param _artist Address of the artist to remove.
    function removeArtist(address _artist) external onlyDAO notPaused {
        require(artistProfiles[_artist].isApproved, "Artist is not a member.");
        artistProfiles[_artist].isApproved = false;
        // Remove from collective artists list (inefficient for large lists, consider better data structure for production)
        for (uint256 i = 0; i < collectiveArtists.length; i++) {
            if (collectiveArtists[i] == _artist) {
                collectiveArtists[i] = collectiveArtists[collectiveArtists.length - 1];
                collectiveArtists.pop();
                break;
            }
        }
        emit ArtistRemoved(_artist);
    }

    /// @dev Retrieves artist profile information.
    /// @param _artist Address of the artist.
    /// @return artistStatement Artist's statement.
    /// @return isApproved Approval status of the artist.
    function getArtistProfile(address _artist) external view returns (string memory artistStatement, bool isApproved) {
        return (artistProfiles[_artist].artistStatement, artistProfiles[_artist].isApproved);
    }

    /// @dev Allows artists to update their profile statement.
    /// @param _newStatement The new artist statement.
    function updateArtistStatement(string memory _newStatement) external onlyCollectiveArtist notPaused {
        artistProfiles[msg.sender].artistStatement = _newStatement;
        emit ArtistStatementUpdated(msg.sender, _newStatement);
    }

    /// @dev Allows anyone to deposit ETH into the collective's treasury.
    function depositCollectiveFunds() external payable notPaused {
        emit CollectiveFundsDeposited(msg.sender, msg.value);
    }

    /// @dev DAO-governed function to withdraw funds from the treasury.
    /// @param _amount Amount of ETH to withdraw.
    function withdrawCollectiveFunds(uint256 _amount) external onlyDAO notPaused {
        require(address(this).balance >= _amount, "Insufficient collective balance.");
        payable(msg.sender).transfer(_amount); // Simple withdrawal to the DAO member initiating
        emit CollectiveFundsWithdrawn(msg.sender, _amount);
    }

    /// @dev Returns the current balance of the collective's treasury.
    /// @return balance The collective's ETH balance.
    function getCollectiveBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }

    // --- Art Submission and Curation Functions ---

    /// @dev Artists submit art proposals.
    /// @param _artTitle Title of the artwork.
    /// @param _artDescription Description of the artwork.
    /// @param _ipfsHash IPFS hash pointing to the artwork file.
    /// @param _value Proposed value for the artwork (in ETH - conceptual).
    function submitArtProposal(
        string memory _artTitle,
        string memory _artDescription,
        string memory _ipfsHash,
        uint256 _value
    ) external onlyCollectiveArtist notPaused {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            proposalId: proposalCounter,
            proposer: msg.sender,
            artTitle: _artTitle,
            artDescription: _artDescription,
            ipfsHash: _ipfsHash,
            value: _value,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit ArtProposalCreated(proposalCounter, msg.sender, _artTitle);
    }

    /// @dev DAO members vote on submitted art proposals.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote True for approval, false for rejection.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyDAO artProposalExists(_proposalId) notPaused {
        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes an approved art proposal if it passes voting.
    /// @param _proposalId ID of the art proposal to execute.
    function executeArtProposal(uint256 _proposalId) external onlyDAO artProposalExists(_proposalId) notPaused {
        require(artProposals[_proposalId].votesFor > artProposals[_proposalId].votesAgainst, "Proposal not approved by DAO."); // Simple majority
        artProposals[_proposalId].executed = true;
        artCounter++;
        artNFTs[artCounter] = ArtNFT({
            artId: artCounter,
            artTitle: artProposals[_proposalId].artTitle,
            artDescription: artProposals[_proposalId].artDescription,
            ipfsHash: artProposals[_proposalId].ipfsHash,
            owner: address(this) // Collective initially owns the NFT
        });
        emit ArtProposalExecuted(_proposalId, artCounter);
        emit ArtNFTMinted(artCounter, artProposals[_proposalId].artTitle, address(this));
    }

    /// @dev Retrieves details of a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @dev Returns a list of all art proposal IDs.
    /// @return proposalIds Array of art proposal IDs.
    function getAllArtProposals() external view returns (uint256[] memory proposalIds) {
        uint256[] memory ids = new uint256[](proposalCounter);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (artProposals[i].proposalId == i) { // Check if proposal exists (to handle potential gaps if proposals were removed - not implemented here)
                ids[index] = i;
                index++;
            }
        }
        assembly { // Efficiently resize the array to remove extra slots
            mstore(ids, index)
        }
        return ids;
    }

    /// @dev Allows users to purchase art NFTs from the collective (conceptual - simple transfer).
    /// @param _artId ID of the art NFT to purchase.
    function purchaseArtNFT(uint256 _artId) external payable artExists(_artId) artIsListed(_artId) notPaused {
        require(msg.value >= artListings[_artId].price, "Insufficient payment.");
        artNFTs[_artId].owner = msg.sender; // Transfer ownership - conceptual, more complex NFT logic needed in real world
        artListings[_artId].isListed = false; // Delist after purchase
        // Transfer funds to collective treasury (already handled by msg.value)
        emit ArtPurchased(_artId, msg.sender, artListings[_artId].price);
    }

    /// @dev DAO-governed function to list collective-owned art for sale.
    /// @param _artId ID of the art NFT to list.
    /// @param _price Price in ETH for the art.
    function listArtForSale(uint256 _artId, uint256 _price) external onlyDAO artExists(_artId) artNotListed(_artId) notPaused {
        require(artNFTs[_artId].owner == address(this), "Collective does not own this art."); // Ensure collective ownership
        artListings[_artId] = ArtListing({artId: _artId, price: _price, isListed: true});
        emit ArtListedForSale(_artId, _price);
    }

    /// @dev DAO-governed function to delist art from sale.
    /// @param _artId ID of the art NFT to delist.
    function delistArtForSale(uint256 _artId) external onlyDAO artExists(_artId) artIsListed(_artId) notPaused {
        artListings[_artId].isListed = false;
        emit ArtDelistedFromSale(_artId);
    }

    /// @dev Retrieves listing details for a specific art NFT.
    /// @param _artId ID of the art NFT.
    /// @return ArtListing struct containing listing details.
    function getArtListingDetails(uint256 _artId) external view artExists(_artId) returns (ArtListing memory) {
        return artListings[_artId];
    }


    // --- DAO Governance and Utilities Functions ---

    /// @dev DAO members propose changes to contract parameters.
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeNewParameter(string memory _parameterName, uint256 _newValue) external onlyDAO notPaused {
        proposalCounter++;
        parameterProposals[proposalCounter] = ParameterProposal({
            proposalId: proposalCounter,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit ParameterProposalCreated(proposalCounter, _parameterName, _newValue);
    }

    /// @dev DAO members vote on parameter change proposals.
    /// @param _proposalId ID of the parameter proposal to vote on.
    /// @param _vote True for approval, false for rejection.
    function voteOnParameterProposal(uint256 _proposalId, bool _vote) external onlyDAO parameterProposalExists(_proposalId) notPaused {
        if (_vote) {
            parameterProposals[_proposalId].votesFor++;
        } else {
            parameterProposals[_proposalId].votesAgainst++;
        }
        emit ParameterProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes an approved parameter change proposal if it passes voting.
    /// @param _proposalId ID of the parameter proposal to execute.
    function executeParameterProposal(uint256 _proposalId) external onlyDAO parameterProposalExists(_proposalId) notPaused {
        require(parameterProposals[_proposalId].votesFor > parameterProposals[_proposalId].votesAgainst, "Proposal not approved by DAO."); // Simple majority
        parameterProposals[_proposalId].executed = true;

        if (keccak256(abi.encodePacked(parameterProposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("votingPeriod"))) {
            votingPeriod = parameterProposals[_proposalId].newValue;
        } else {
            revert("Unknown parameter name for execution."); // Add more parameter types as needed
        }
        emit ParameterProposalExecuted(_proposalId, parameterProposals[_proposalId].parameterName, parameterProposals[_proposalId].newValue);
    }

    /// @dev Retrieves details of a specific parameter change proposal.
    /// @param _proposalId ID of the parameter proposal.
    /// @return ParameterProposal struct containing proposal details.
    function getParameterProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ParameterProposal memory) {
        return parameterProposals[_proposalId];
    }

    /// @dev Returns a list of all parameter change proposal IDs.
    /// @return proposalIds Array of parameter proposal IDs.
    function getAllParameterProposals() external view returns (uint256[] memory proposalIds) {
        uint256[] memory ids = new uint256[](proposalCounter);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (parameterProposals[i].proposalId == i) { // Check if proposal exists
                ids[index] = i;
                index++;
            }
        }
        assembly { // Efficiently resize the array
            mstore(ids, index)
        }
        return ids;
    }

    /// @dev Returns the current voting period duration.
    /// @return period The voting period in seconds.
    function getCurrentVotingPeriod() external view returns (uint256 period) {
        return votingPeriod;
    }

    /// @dev Owner-only function to set the initial voting period.
    /// @param _newPeriod The new voting period duration in seconds.
    function setVotingPeriod(uint256 _newPeriod) external onlyOwner {
        votingPeriod = _newPeriod;
    }

    /// @dev Owner-only function to pause core functionalities in emergencies.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Owner-only function to resume contract functionalities.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }


    // --- Utility Functions ---

    /// @dev Simple check if an address is considered a DAO member (for this example, all approved artists).
    /// @param _address Address to check.
    /// @return True if DAO member, false otherwise.
    function isDAOMember(address _address) internal view returns (bool) {
        return artistProfiles[_address].isApproved; // In a real DAO, membership might be more complex
    }

    /// @dev Fallback function to accept ETH deposits.
    receive() external payable {}
    fallback() external payable {}
}
```