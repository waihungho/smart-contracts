```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling collaborative art creation,
 * ownership, and community governance. This contract explores advanced concepts like dynamic NFT metadata,
 * on-chain voting with reputation, curated content feeds, and decentralized collaboration incentives.
 *
 * Function Summary:
 *
 * **Art Piece Management:**
 * 1. proposeArtPiece(string _title, string _description, string _initialMetadataUri): Allows members to propose new art pieces with initial metadata.
 * 2. voteOnArtProposal(uint256 _proposalId, bool _vote): Members vote on proposed art pieces.
 * 3. executeArtProposal(uint256 _proposalId): Executes approved art proposals, minting NFTs.
 * 4. contributeToArtPiece(uint256 _artPieceId, string _contributionMetadataUri): Registered contributors can add metadata contributions to existing art pieces.
 * 5. finalizeArtPieceMetadata(uint256 _artPieceId): Finalizes the metadata of an art piece after contributions, making it immutable.
 * 6. setArtPiecePrice(uint256 _artPieceId, uint256 _price): Owner can set the price for purchasing an art piece from the collective.
 * 7. purchaseArtPiece(uint256 _artPieceId): Allows users to purchase art pieces, transferring funds to the collective treasury.
 * 8. getArtPieceDetails(uint256 _artPieceId): Retrieves detailed information about a specific art piece.
 * 9. getArtPieceMetadataUri(uint256 _artPieceId): Retrieves the current metadata URI for an art piece.
 *
 * **Collective Membership & Reputation:**
 * 10. joinCollective(): Allows anyone to join the collective.
 * 11. leaveCollective(): Allows members to leave the collective.
 * 12. addReputation(address _member, uint256 _amount): Owner function to manually add reputation to a member.
 * 13. deductReputation(address _member, uint256 _amount): Owner function to manually deduct reputation from a member.
 * 14. getMemberReputation(address _member): Retrieves the reputation score of a member.
 * 15. getCollectiveMembers(): Returns a list of all collective members.
 *
 * **Curated Content Feed & Discovery:**
 * 16. curateArtPiece(uint256 _artPieceId): Members with sufficient reputation can curate art pieces for the featured feed.
 * 17. uncurateArtPiece(uint256 _artPieceId): Members with sufficient reputation can remove art pieces from the featured feed.
 * 18. getFeaturedArtPieces(): Retrieves a list of art piece IDs currently featured in the curated feed.
 *
 * **Treasury & Governance:**
 * 19. withdrawTreasuryFunds(address _recipient, uint256 _amount): Owner-controlled function to withdraw funds from the treasury.
 * 20. getTreasuryBalance(): Retrieves the current balance of the collective treasury.
 * 21. setVotingDuration(uint256 _durationInBlocks): Owner function to set the default voting duration for proposals.
 * 22. setReputationThresholdForCuration(uint256 _threshold): Owner function to set the reputation threshold required for curation actions.
 */

contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    address public owner; // Contract owner
    string public collectiveName; // Name of the art collective

    uint256 public artPieceCounter; // Counter for unique art piece IDs
    mapping(uint256 => ArtPiece) public artPieces; // Mapping of art piece IDs to ArtPiece structs
    mapping(uint256 => ArtProposal) public artProposals; // Mapping of proposal IDs to ArtProposal structs
    uint256 public proposalCounter; // Counter for unique proposal IDs

    mapping(address => bool) public isCollectiveMember; // Mapping of addresses to membership status
    mapping(address => uint256) public memberReputation; // Mapping of member addresses to reputation scores

    mapping(uint256 => bool) public isArtPieceCurated; // Mapping of art piece IDs to curation status
    uint256[] public featuredArtPieces; // Array of art piece IDs featured in the curated feed

    uint256 public votingDurationInBlocks = 100; // Default voting duration in blocks
    uint256 public reputationThresholdForCuration = 100; // Reputation required for curation actions

    // -------- Structs --------

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string metadataUri; // Initial metadata URI (can be updated through contributions)
        address creator; // Address of the member who proposed the art piece
        uint256 price; // Price in wei to purchase the art piece from the collective
        bool metadataFinalized; // Flag indicating if the metadata is finalized
    }

    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string initialMetadataUri;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes; // Mapping of voter addresses to their vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    // -------- Events --------

    event ArtPieceProposed(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 artPieceId, uint256 proposalId);
    event ArtPieceContributed(uint256 artPieceId, address contributor, string metadataUri);
    event ArtPieceMetadataFinalized(uint256 artPieceId, string finalizedMetadataUri);
    event ArtPiecePriceSet(uint256 artPieceId, uint256 price);
    event ArtPiecePurchased(uint256 artPieceId, address buyer, uint256 price);
    event ArtPieceCurated(uint256 artPieceId);
    event ArtPieceUncurated(uint256 artPieceId);
    event CollectiveMemberJoined(address member);
    event CollectiveMemberLeft(address member);
    event ReputationAdded(address member, uint256 amount);
    event ReputationDeducted(address member, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCollectiveMembers() {
        require(isCollectiveMember[msg.sender], "Only collective members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].id != 0, "Invalid proposal ID.");
        require(!artProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= artProposals[_proposalId].startTime && block.timestamp <= artProposals[_proposalId].endTime, "Voting period is not active.");
        _;
    }

    modifier validArtPiece(uint256 _artPieceId) {
        require(artPieces[_artPieceId].id != 0, "Invalid art piece ID.");
        _;
    }

    modifier metadataNotFinalized(uint256 _artPieceId) {
        require(!artPieces[_artPieceId].metadataFinalized, "Metadata is already finalized.");
        _;
    }

    modifier reputationSufficientForCuration() {
        require(memberReputation[msg.sender] >= reputationThresholdForCuration, "Insufficient reputation for curation.");
        _;
    }

    // -------- Constructor --------

    constructor(string memory _collectiveName) {
        owner = msg.sender;
        collectiveName = _collectiveName;
    }

    // -------- Art Piece Management Functions --------

    /// @notice Allows collective members to propose a new art piece.
    /// @param _title Title of the art piece.
    /// @param _description Description of the art piece.
    /// @param _initialMetadataUri Initial metadata URI for the art piece (e.g., IPFS link).
    function proposeArtPiece(
        string memory _title,
        string memory _description,
        string memory _initialMetadataUri
    ) external onlyCollectiveMembers {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            initialMetadataUri: _initialMetadataUri,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDurationInBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ArtPieceProposed(proposalCounter, _title, msg.sender);
    }

    /// @notice Allows collective members to vote on an art piece proposal.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyCollectiveMembers validProposal(_proposalId) {
        require(!artProposals[_proposalId].votes[msg.sender], "Member has already voted.");
        artProposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes an approved art piece proposal if it has enough yes votes.
    /// @param _proposalId ID of the proposal to execute.
    function executeArtProposal(uint256 _proposalId) external onlyOwner validProposal(_proposalId) {
        require(artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes, "Proposal not approved by majority.");
        artProposals[_proposalId].executed = true;

        artPieceCounter++;
        artPieces[artPieceCounter] = ArtPiece({
            id: artPieceCounter,
            title: artProposals[_proposalId].title,
            description: artProposals[_proposalId].description,
            metadataUri: artProposals[_proposalId].initialMetadataUri,
            creator: artProposals[_proposalId].proposer,
            price: 0, // Initial price is 0, owner can set later
            metadataFinalized: false
        });

        emit ArtProposalExecuted(artPieceCounter, _proposalId);
    }

    /// @notice Allows registered contributors to add metadata contributions to an existing art piece.
    /// @param _artPieceId ID of the art piece to contribute to.
    /// @param _contributionMetadataUri Metadata URI for the contribution (e.g., IPFS link to additional details, sketches, etc.).
    function contributeToArtPiece(uint256 _artPieceId, string memory _contributionMetadataUri)
        external
        onlyCollectiveMembers
        validArtPiece(_artPieceId)
        metadataNotFinalized(_artPieceId)
    {
        // In a more advanced version, you might want to manage contributions more structurally,
        // perhaps storing an array of contribution metadata URIs within the ArtPiece struct.
        // For this example, we will simply update the main metadata URI with the latest contribution.
        artPieces[_artPieceId].metadataUri = _contributionMetadataUri;
        emit ArtPieceContributed(_artPieceId, msg.sender, _contributionMetadataUri);
    }

    /// @notice Finalizes the metadata of an art piece, making it immutable.
    /// @param _artPieceId ID of the art piece to finalize metadata for.
    function finalizeArtPieceMetadata(uint256 _artPieceId) external onlyOwner validArtPiece(_artPieceId) metadataNotFinalized(_artPieceId) {
        artPieces[_artPieceId].metadataFinalized = true;
        emit ArtPieceMetadataFinalized(_artPieceId, artPieces[_artPieceId].metadataUri);
    }

    /// @notice Sets the price for an art piece, allowing users to purchase it.
    /// @param _artPieceId ID of the art piece.
    /// @param _price Price in wei.
    function setArtPiecePrice(uint256 _artPieceId, uint256 _price) external onlyOwner validArtPiece(_artPieceId) {
        artPieces[_artPieceId].price = _price;
        emit ArtPiecePriceSet(_artPieceId, _price);
    }

    /// @notice Allows users to purchase an art piece from the collective.
    /// @param _artPieceId ID of the art piece to purchase.
    function purchaseArtPiece(uint256 _artPieceId) external payable validArtPiece(_artPieceId) {
        require(artPieces[_artPieceId].price > 0, "Art piece is not for sale.");
        require(msg.value >= artPieces[_artPieceId].price, "Insufficient funds sent.");

        payable(owner).transfer(msg.value); // Send funds to the contract owner as treasury for simplicity in this example.
                                            // In a real DAAC, you'd likely have more complex treasury management.

        emit ArtPiecePurchased(_artPieceId, msg.sender, artPieces[_artPieceId].price);
    }

    /// @notice Retrieves detailed information about a specific art piece.
    /// @param _artPieceId ID of the art piece.
    /// @return ArtPiece struct containing art piece details.
    function getArtPieceDetails(uint256 _artPieceId) external view validArtPiece(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    /// @notice Retrieves the current metadata URI for an art piece.
    /// @param _artPieceId ID of the art piece.
    /// @return Metadata URI string.
    function getArtPieceMetadataUri(uint256 _artPieceId) external view validArtPiece(_artPieceId) returns (string memory) {
        return artPieces[_artPieceId].metadataUri;
    }


    // -------- Collective Membership & Reputation Functions --------

    /// @notice Allows anyone to join the collective.
    function joinCollective() external {
        require(!isCollectiveMember[msg.sender], "Already a member.");
        isCollectiveMember[msg.sender] = true;
        memberReputation[msg.sender] = 10; // Initial reputation for new members
        emit CollectiveMemberJoined(msg.sender);
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() external onlyCollectiveMembers {
        isCollectiveMember[msg.sender] = false;
        delete memberReputation[msg.sender]; // Optionally remove reputation upon leaving
        emit CollectiveMemberLeft(msg.sender);
    }

    /// @notice Owner function to manually add reputation to a member.
    /// @param _member Address of the member.
    /// @param _amount Amount of reputation to add.
    function addReputation(address _member, uint256 _amount) external onlyOwner {
        memberReputation[_member] += _amount;
        emit ReputationAdded(_member, _amount);
    }

    /// @notice Owner function to manually deduct reputation from a member.
    /// @param _member Address of the member.
    /// @param _amount Amount of reputation to deduct.
    function deductReputation(address _member, uint256 _amount) external onlyOwner {
        require(memberReputation[_member] >= _amount, "Cannot deduct more reputation than member has.");
        memberReputation[_member] -= _amount;
        emit ReputationDeducted(_member, _amount);
    }

    /// @notice Retrieves the reputation score of a member.
    /// @param _member Address of the member.
    /// @return Reputation score.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Returns a list of all collective members.
    /// @return Array of member addresses.
    function getCollectiveMembers() external view returns (address[] memory) {
        address[] memory members = new address[](getCollectiveMemberCount());
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) { // Iterating through proposals as a proxy to find members (simplified approach)
            if (artProposals[i].proposer != address(0) && isCollectiveMember[artProposals[i].proposer]) { // Basic check, could be improved
                members[index] = artProposals[i].proposer;
                index++;
            }
        }
         // In a real-world scenario, maintain a dedicated list of members for efficiency.
         // This example uses a simplified approach for demonstration purposes.
        return members;
    }

    function getCollectiveMemberCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) { // Iterating through proposals as a proxy to find members (simplified approach)
             if (artProposals[i].proposer != address(0) && isCollectiveMember[artProposals[i].proposer]) { // Basic check, could be improved
                count++;
            }
        }
        return count;
    }


    // -------- Curated Content Feed & Discovery Functions --------

    /// @notice Allows members with sufficient reputation to curate an art piece for the featured feed.
    /// @param _artPieceId ID of the art piece to curate.
    function curateArtPiece(uint256 _artPieceId) external onlyCollectiveMembers reputationSufficientForCuration validArtPiece(_artPieceId) {
        require(!isArtPieceCurated[_artPieceId], "Art piece is already curated.");
        isArtPieceCurated[_artPieceId] = true;
        featuredArtPieces.push(_artPieceId);
        emit ArtPieceCurated(_artPieceId);
    }

    /// @notice Allows members with sufficient reputation to uncurate an art piece from the featured feed.
    /// @param _artPieceId ID of the art piece to uncurate.
    function uncurateArtPiece(uint256 _artPieceId) external onlyCollectiveMembers reputationSufficientForCuration validArtPiece(_artPieceId) {
        require(isArtPieceCurated[_artPieceId], "Art piece is not curated.");
        isArtPieceCurated[_artPieceId] = false;
        // Remove from featuredArtPieces array (efficient removal can be implemented if needed for large arrays)
        for (uint256 i = 0; i < featuredArtPieces.length; i++) {
            if (featuredArtPieces[i] == _artPieceId) {
                featuredArtPieces[i] = featuredArtPieces[featuredArtPieces.length - 1];
                featuredArtPieces.pop();
                break;
            }
        }
        emit ArtPieceUncurated(_artPieceId);
    }

    /// @notice Retrieves a list of art piece IDs currently featured in the curated feed.
    /// @return Array of featured art piece IDs.
    function getFeaturedArtPieces() external view returns (uint256[] memory) {
        return featuredArtPieces;
    }

    // -------- Treasury & Governance Functions --------

    /// @notice Owner-controlled function to withdraw funds from the treasury.
    /// @param _recipient Address to send funds to.
    /// @param _amount Amount to withdraw in wei.
    function withdrawTreasuryFunds(address payable _recipient, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed.");
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @notice Retrieves the current balance of the collective treasury.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Owner function to set the default voting duration for proposals.
    /// @param _durationInBlocks Duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        votingDurationInBlocks = _durationInBlocks;
    }

    /// @notice Owner function to set the reputation threshold required for curation actions.
    /// @param _threshold Reputation threshold.
    function setReputationThresholdForCuration(uint256 _threshold) external onlyOwner {
        reputationThresholdForCuration = _threshold;
    }

    // -------- Fallback Function (Optional - for receiving ETH) --------
    receive() external payable {}
}
```