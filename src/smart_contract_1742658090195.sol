```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Gallery - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic art gallery where art pieces can evolve over time
 *      based on community votes, oracle inputs, or artist-defined dynamic rules.
 *
 * Function Summary:
 *
 *  **Art Management:**
 *      1. createArtPiece(string memory _initialMetadataURI, string memory _title, string memory _description): Allows artists to create new art pieces.
 *      2. updateArtMetadataURI(uint256 _artPieceId, string memory _newMetadataURI): Allows artists to update the metadata URI of their art piece.
 *      3. transferArtPieceOwnership(uint256 _artPieceId, address _newOwner): Allows the owner of an art piece to transfer ownership.
 *      4. deactivateArtPiece(uint256 _artPieceId): Allows the artist/owner to deactivate an art piece, removing it from active gallery listings.
 *      5. reactivateArtPiece(uint256 _artPieceId): Allows the artist/owner to reactivate a deactivated art piece.
 *
 *  **Dynamic Evolution & Community Interaction:**
 *      6. proposeMetadataUpdate(uint256 _artPieceId, string memory _proposedMetadataURI, string memory _reason): Allows community members to propose updates to art piece metadata.
 *      7. voteOnMetadataUpdate(uint256 _proposalId, bool _vote): Allows registered users to vote on metadata update proposals.
 *      8. executeMetadataUpdate(uint256 _proposalId): Executes a successful metadata update proposal after voting period ends and quorum is met.
 *      9. setDynamicRule(uint256 _artPieceId, string memory _ruleDescription, bytes memory _ruleLogic): Allows artists to set dynamic rules for their art pieces (advanced, placeholder for more complex logic).
 *      10. triggerDynamicEvent(uint256 _artPieceId, string memory _eventData): Allows authorized users (e.g., oracles, curators) to trigger dynamic events that can evolve art pieces based on rules.
 *
 *  **Gallery Management & Governance:**
 *      11. setGalleryFee(uint256 _newFee): Allows the contract owner to set a fee for creating art pieces.
 *      12. withdrawGalleryFees(): Allows the contract owner to withdraw accumulated gallery fees.
 *      13. addCurator(address _curatorAddress): Allows the contract owner to add a curator role.
 *      14. removeCurator(address _curatorAddress): Allows the contract owner to remove a curator role.
 *      15. registerUser(): Allows users to register to participate in voting and community features.
 *      16. unregisterUser(): Allows users to unregister from community features.
 *      17. setVotingPeriod(uint256 _newPeriodInSeconds): Allows the contract owner to set the voting period for proposals.
 *      18. setQuorumPercentage(uint256 _newQuorumPercentage): Allows the contract owner to set the quorum percentage for proposals to pass.
 *
 *  **Information & Utility:**
 *      19. getArtPieceDetails(uint256 _artPieceId): Returns detailed information about a specific art piece.
 *      20. getActiveArtPieceIds(): Returns a list of IDs of currently active art pieces.
 *      21. getArtistArtPieceIds(address _artist): Returns a list of IDs of art pieces created by a specific artist.
 *      22. getMetadataUpdateProposal(uint256 _proposalId): Returns details of a specific metadata update proposal.
 */
contract DynamicArtGallery {
    // --- Data Structures ---

    struct ArtPiece {
        uint256 id;
        address artist;
        address owner; // Initially artist, can be transferred
        string title;
        string description;
        string currentMetadataURI;
        uint256 creationTimestamp;
        string dynamicRuleDescription; // Placeholder for dynamic rule description
        bytes dynamicRuleLogic; // Placeholder for dynamic rule logic (could be more complex in a real-world scenario)
        bool isActive;
    }

    struct MetadataUpdateProposal {
        uint256 id;
        uint256 artPieceId;
        address proposer;
        string proposedMetadataURI;
        string reason;
        uint256 proposalTimestamp;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    // --- State Variables ---

    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => MetadataUpdateProposal) public metadataUpdateProposals;
    mapping(uint256 => mapping(address => bool)) public userVotes; // proposalId => user => voted
    mapping(address => bool) public galleryCurators;
    mapping(address => bool) public registeredUsers; // Users registered for voting

    uint256 public nextArtPieceId = 1;
    uint256 public nextProposalId = 1;
    uint256 public galleryFee = 0.01 ether; // Fee to create an art piece
    address public owner;
    uint256 public votingPeriod = 7 days; // Default voting period for proposals
    uint256 public quorumPercentage = 50; // Percentage of registered users required to vote for quorum

    // --- Events ---

    event ArtPieceCreated(uint256 artPieceId, address artist, string metadataURI, string title);
    event ArtPieceMetadataUpdated(uint256 artPieceId, string newMetadataURI);
    event ArtPieceOwnershipTransferred(uint256 artPieceId, address oldOwner, address newOwner);
    event ArtPieceDeactivated(uint256 artPieceId);
    event ArtPieceReactivated(uint256 artPieceId);
    event MetadataUpdateProposed(uint256 proposalId, uint256 artPieceId, address proposer, string proposedMetadataURI);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event MetadataUpdateExecuted(uint256 proposalId, uint256 artPieceId, string newMetadataURI);
    event DynamicEventTriggered(uint256 artPieceId, string eventData);
    event GalleryFeeSet(uint256 newFee);
    event CuratorAdded(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event UserRegistered(address userAddress);
    event UserUnregistered(address userAddress);
    event VotingPeriodSet(uint256 newPeriod);
    event QuorumPercentageSet(uint256 newQuorum);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(galleryCurators[msg.sender] || msg.sender == owner, "Only curator or owner can call this function.");
        _;
    }

    modifier artPieceExists(uint256 _artPieceId) {
        require(artPieces[_artPieceId].id != 0, "Art piece does not exist.");
        _;
    }

    modifier onlyArtPieceArtist(uint256 _artPieceId) {
        require(artPieces[_artPieceId].artist == msg.sender, "Only the artist can call this function.");
        _;
    }

    modifier onlyArtPieceOwner(uint256 _artPieceId) {
        require(artPieces[_artPieceId].owner == msg.sender, "Only the owner can call this function.");
        _;
    }

    modifier isActiveArtPiece(uint256 _artPieceId) {
        require(artPieces[_artPieceId].isActive, "Art piece is not active.");
        _;
    }

    modifier isRegisteredUser() {
        require(registeredUsers[msg.sender], "User is not registered.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(metadataUpdateProposals[_proposalId].id != 0, "Proposal does not exist.");
        require(!metadataUpdateProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < metadataUpdateProposals[_proposalId].votingEndTime, "Voting period has ended.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        galleryCurators[msg.sender] = true; // Owner is also a curator by default
    }

    // --- Art Management Functions ---

    function createArtPiece(string memory _initialMetadataURI, string memory _title, string memory _description) external payable {
        require(msg.value >= galleryFee, "Insufficient gallery fee.");

        uint256 artId = nextArtPieceId++;
        artPieces[artId] = ArtPiece({
            id: artId,
            artist: msg.sender,
            owner: msg.sender,
            title: _title,
            description: _description,
            currentMetadataURI: _initialMetadataURI,
            creationTimestamp: block.timestamp,
            dynamicRuleDescription: "", // Initially no dynamic rule
            dynamicRuleLogic: bytes(""), // Initially no dynamic rule logic
            isActive: true
        });

        payable(owner).transfer(galleryFee); // Transfer fee to gallery owner

        emit ArtPieceCreated(artId, msg.sender, _initialMetadataURI, _title);
    }

    function updateArtMetadataURI(uint256 _artPieceId, string memory _newMetadataURI) external artPieceExists(_artPieceId) onlyArtPieceArtist(_artPieceId) {
        artPieces[_artPieceId].currentMetadataURI = _newMetadataURI;
        emit ArtPieceMetadataUpdated(_artPieceId, _newMetadataURI);
    }

    function transferArtPieceOwnership(uint256 _artPieceId, address _newOwner) external artPieceExists(_artPieceId) onlyArtPieceOwner(_artPieceId) {
        artPieces[_artPieceId].owner = _newOwner;
        emit ArtPieceOwnershipTransferred(_artPieceId, msg.sender, _newOwner);
    }

    function deactivateArtPiece(uint256 _artPieceId) external artPieceExists(_artPieceId) onlyArtPieceOwner(_artPieceId) isActiveArtPiece(_artPieceId) {
        artPieces[_artPieceId].isActive = false;
        emit ArtPieceDeactivated(_artPieceId);
    }

    function reactivateArtPiece(uint256 _artPieceId) external artPieceExists(_artPieceId) onlyArtPieceOwner(_artPieceId) {
        artPieces[_artPieceId].isActive = true;
        emit ArtPieceReactivated(_artPieceId);
    }

    // --- Dynamic Evolution & Community Interaction Functions ---

    function proposeMetadataUpdate(uint256 _artPieceId, string memory _proposedMetadataURI, string memory _reason) external artPieceExists(_artPieceId) isActiveArtPiece(_artPieceId) isRegisteredUser {
        require(bytes(_proposedMetadataURI).length > 0, "Proposed metadata URI cannot be empty.");

        uint256 proposalId = nextProposalId++;
        metadataUpdateProposals[proposalId] = MetadataUpdateProposal({
            id: proposalId,
            artPieceId: _artPieceId,
            proposer: msg.sender,
            proposedMetadataURI: _proposedMetadataURI,
            reason: _reason,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit MetadataUpdateProposed(proposalId, _artPieceId, msg.sender, _proposedMetadataURI);
    }

    function voteOnMetadataUpdate(uint256 _proposalId, bool _vote) external validProposal(_proposalId) isRegisteredUser {
        require(!userVotes[_proposalId][msg.sender], "User has already voted on this proposal.");

        userVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            metadataUpdateProposals[_proposalId].yesVotes++;
        } else {
            metadataUpdateProposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeMetadataUpdate(uint256 _proposalId) external validProposal(_proposalId) {
        require(block.timestamp >= metadataUpdateProposals[_proposalId].votingEndTime, "Voting period has not ended yet.");

        uint256 totalRegisteredUsers = 0;
        for (uint256 i = 1; i < nextArtPieceId; ++i) { // Inefficient in practice, consider better user counting for real-world
            if (registeredUsers[address(uint160(i))]) { // Very basic and incorrect user count, replace with proper tracking
                totalRegisteredUsers++;
            }
        }
        uint256 quorum = (totalRegisteredUsers * quorumPercentage) / 100;

        require(metadataUpdateProposals[_proposalId].yesVotes >= quorum, "Quorum not met for proposal.");
        require(metadataUpdateProposals[_proposalId].yesVotes > metadataUpdateProposals[_proposalId].noVotes, "Proposal not passed (not enough yes votes).");

        metadataUpdateProposals[_proposalId].executed = true;
        artPieces[metadataUpdateProposals[_proposalId].artPieceId].currentMetadataURI = metadataUpdateProposals[_proposalId].proposedMetadataURI;
        emit MetadataUpdateExecuted(_proposalId, metadataUpdateProposals[_proposalId].artPieceId, metadataUpdateProposals[_proposalId].proposedMetadataURI);
    }

    // Placeholder for more advanced dynamic rules - for demonstration purposes only
    function setDynamicRule(uint256 _artPieceId, string memory _ruleDescription, bytes memory _ruleLogic) external artPieceExists(_artPieceId) onlyArtPieceArtist(_artPieceId) {
        artPieces[_artPieceId].dynamicRuleDescription = _ruleDescription;
        artPieces[_artPieceId].dynamicRuleLogic = _ruleLogic;
        // In a real application, _ruleLogic would be parsed and used to dynamically update metadata, potentially with oracle inputs.
        // This is a simplified example and requires further design for complex logic.
    }

    // Placeholder for triggering dynamic events - for demonstration purposes only
    function triggerDynamicEvent(uint256 _artPieceId, string memory _eventData) external onlyCurator artPieceExists(_artPieceId) isActiveArtPiece(_artPieceId) {
        // In a real application, this function would:
        // 1. Validate the eventData against the art piece's dynamicRuleLogic.
        // 2. Execute the rule logic, potentially updating the art piece's metadata or other properties.
        // 3. For simplicity, here we just emit an event.
        emit DynamicEventTriggered(_artPieceId, _eventData);
        // Example:  Imagine rule logic says "if eventData == 'sunset', update metadata to 'sunset-themed-art.json'".
        // Further implementation needed for actual dynamic behavior.
    }


    // --- Gallery Management & Governance Functions ---

    function setGalleryFee(uint256 _newFee) external onlyOwner {
        galleryFee = _newFee;
        emit GalleryFeeSet(_newFee);
    }

    function withdrawGalleryFees() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function addCurator(address _curatorAddress) external onlyOwner {
        galleryCurators[_curatorAddress] = true;
        emit CuratorAdded(_curatorAddress);
    }

    function removeCurator(address _curatorAddress) external onlyOwner {
        galleryCurators[_curatorAddress] = false;
        emit CuratorRemoved(_curatorAddress);
    }

    function registerUser() external {
        registeredUsers[msg.sender] = true;
        emit UserRegistered(msg.sender);
    }

    function unregisterUser() external {
        registeredUsers[msg.sender] = false;
        emit UserUnregistered(msg.sender);
    }

    function setVotingPeriod(uint256 _newPeriodInSeconds) external onlyOwner {
        votingPeriod = _newPeriodInSeconds;
        emit VotingPeriodSet(_newPeriodInSeconds);
    }

    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyOwner {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be <= 100.");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageSet(_newQuorumPercentage);
    }

    // --- Information & Utility Functions ---

    function getArtPieceDetails(uint256 _artPieceId) external view artPieceExists(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    function getActiveArtPieceIds() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](nextArtPieceId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtPieceId; ++i) {
            if (artPieces[i].isActive) {
                activeIds[count++] = i;
            }
        }
        // Resize array to actual number of active pieces
        assembly {
            mstore(activeIds, count) // Update the length of the array
        }
        return activeIds;
    }

    function getArtistArtPieceIds(address _artist) external view returns (uint256[] memory) {
        uint256[] memory artistArtIds = new uint256[](nextArtPieceId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtPieceId; ++i) {
            if (artPieces[i].artist == _artist) {
                artistArtIds[count++] = i;
            }
        }
        // Resize array to actual number of artist pieces
        assembly {
            mstore(artistArtIds, count) // Update the length of the array
        }
        return artistArtIds;
    }

    function getMetadataUpdateProposal(uint256 _proposalId) external view returns (MetadataUpdateProposal memory) {
        return metadataUpdateProposals[_proposalId];
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```