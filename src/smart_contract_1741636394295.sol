```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Inspired by user request)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate,
 * govern their collective, and showcase/sell their digital art.

 * **Outline & Function Summary:**

 * **Core Collective Functions:**
 * 1. `joinCollective(string _artistStatement)`: Allows artists to request membership with a statement.
 * 2. `leaveCollective()`: Allows members to leave the collective.
 * 3. `listMembers()`: Returns a list of current collective members.
 * 4. `getMemberDetails(address _member)`: Retrieves details of a specific member.
 * 5. `updateArtistStatement(string _newStatement)`: Allows members to update their artist statement.

 * **Governance & Voting Functions:**
 * 6. `proposeNewMember(address _potentialMember, string _rationale)`: Proposes a new artist for membership.
 * 7. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on active proposals.
 * 8. `executeProposal(uint256 _proposalId)`: Executes a passed proposal (e.g., adding a member).
 * 9. `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Allows members to propose changes to collective rules/parameters.
 * 10. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 * 11. `getActiveProposals()`: Returns a list of active proposal IDs.
 * 12. `getVotingPower(address _member)`: Returns the voting power of a member (initially 1, could be expanded).

 * **Art Management & Showcase Functions:**
 * 13. `submitArtwork(string _title, string _description, string _artworkCID, string _metadataCID)`: Allows members to submit their artwork for showcase.
 * 14. `listCollectiveArtworks()`: Returns a list of artwork IDs showcased by the collective.
 * 15. `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork.
 * 16. `curateArtwork(uint256 _artworkId)`: Allows members to curate (vote to feature) an artwork (governance based curation can be implemented).
 * 17. `getCuratedArtworks()`: Returns a list of artwork IDs that are currently curated/featured.

 * **Reputation & Contribution Functions (Advanced Concept):**
 * 18. `recordContribution(address _member, string _contributionType, string _details)`:  Allows recording of member contributions (e.g., artwork submission, governance participation).
 * 19. `getMemberReputation(address _member)`:  Returns a basic reputation score (could be based on contributions).

 * **Utility & Information Functions:**
 * 20. `getCollectiveName()`: Returns the name of the art collective.
 * 21. `getContractOwner()`: Returns the address of the contract owner (deployer).
 */

contract DecentralizedArtCollective {
    string public collectiveName;
    address public contractOwner;

    // Structs
    struct Member {
        address memberAddress;
        string artistStatement;
        bool isActive;
        uint256 joinTimestamp;
        uint256 reputationScore; // Basic reputation score, can be expanded
    }

    struct Artwork {
        uint256 artworkId;
        address artistAddress;
        string title;
        string description;
        string artworkCID; // IPFS CID for the actual artwork file
        string metadataCID; // IPFS CID for artwork metadata (optional but good practice)
        uint256 submissionTimestamp;
        bool isCurated;
        uint256 curationScore; // Simple curation score, could be based on votes
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        bytes calldataData; // Calldata for governance proposals
        uint256 creationTimestamp;
        uint256 votingDeadline;
        mapping(address => bool) votes; // Members who voted and their vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
        bool isPassed;
    }

    enum ProposalType {
        MEMBERSHIP,
        GOVERNANCE,
        ART_CURATION // Example, can be expanded
    }

    // State Variables
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount;

    mapping(uint256 => Artwork) public artworks;
    uint256[] public artworkList;
    uint256 public artworkCount;
    uint256 public curatedArtworkCount;
    uint256[] public curatedArtworkList;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256[] public activeProposals;

    uint256 public nextProposalId = 1;
    uint256 public nextArtworkId = 1;

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals


    // Events
    event MemberJoined(address memberAddress, string artistStatement);
    event MemberLeft(address memberAddress);
    event MemberStatementUpdated(address memberAddress, string newStatement);
    event NewMemberProposalCreated(uint256 proposalId, address potentialMember, string rationale);
    event GovernanceProposalCreated(uint256 proposalId, string title, string description);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string title);
    event ArtworkCurated(uint256 artworkId);
    event ContributionRecorded(address memberAddress, string contributionType, string details);


    // Modifiers
    modifier onlyMember() {
        require(members[msg.sender].isActive, "You are not a member of the collective.");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        require(!proposals[_proposalId].isExecuted, "Proposal has already been executed.");
        require(block.timestamp < proposals[_proposalId].votingDeadline, "Voting period has ended.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Artwork does not exist.");
        _;
    }


    // Constructor
    constructor(string memory _collectiveName) {
        collectiveName = _collectiveName;
        contractOwner = msg.sender;
    }

    // -------------------- Core Collective Functions --------------------

    /// @notice Allows artists to request membership with a statement.
    /// @param _artistStatement A statement from the artist explaining their interest in joining.
    function joinCollective(string memory _artistStatement) public {
        require(members[msg.sender].memberAddress == address(0), "You are already a member or have applied."); // Basic check, can be refined
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            artistStatement: _artistStatement,
            isActive: false, // Initially inactive, needs approval via proposal
            joinTimestamp: block.timestamp,
            reputationScore: 0 // Start with 0 reputation
        });
        emit MemberJoined(msg.sender, _artistStatement);
        // In a real application, this would trigger a membership proposal process.
        // For simplicity here, we'll assume membership needs to be proposed by existing members.
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() public onlyMember {
        members[msg.sender].isActive = false;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    /// @notice Returns a list of current collective members.
    function listMembers() public view returns (address[] memory) {
        return memberList;
    }

    /// @notice Retrieves details of a specific member.
    /// @param _member The address of the member.
    function getMemberDetails(address _member) public view returns (Member memory) {
        return members[_member];
    }

    /// @notice Allows members to update their artist statement.
    /// @param _newStatement The new artist statement.
    function updateArtistStatement(string memory _newStatement) public onlyMember {
        members[msg.sender].artistStatement = _newStatement;
        emit MemberStatementUpdated(msg.sender, _newStatement);
    }


    // -------------------- Governance & Voting Functions --------------------

    /// @notice Proposes a new artist for membership.
    /// @param _potentialMember The address of the artist to propose.
    /// @param _rationale The rationale for proposing this artist.
    function proposeNewMember(address _potentialMember, string memory _rationale) public onlyMember {
        require(members[_potentialMember].memberAddress != address(0), "Potential member has not applied to join.");
        require(!members[_potentialMember].isActive, "Potential member is already active.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.MEMBERSHIP,
            proposer: msg.sender,
            title: "Membership Proposal for " + string(abi.encodePacked(addressToString(_potentialMember))),
            description: _rationale,
            calldataData: abi.encodeWithSignature("addMember(address)", _potentialMember), // Example calldata - adapt to your needs
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false,
            isPassed: false
        });
        activeProposals.push(proposalId);
        proposalCount++;
        emit NewMemberProposalCreated(proposalId, _potentialMember, _rationale);
    }

    /// @notice Allows members to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyMember validProposal(_proposalId) proposalExists(_proposalId) {
        require(!proposals[_proposalId].votes[msg.sender], "You have already voted on this proposal.");
        proposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a passed proposal (e.g., adding a member).
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public proposalExists(_proposalId) {
        require(!proposals[_proposalId].isExecuted, "Proposal has already been executed.");
        require(block.timestamp >= proposals[_proposalId].votingDeadline, "Voting period has not ended.");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorumNeeded = (memberCount * quorumPercentage) / 100;
        bool quorumReached = totalVotes >= quorumNeeded;
        bool passed = quorumReached && proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes; // Simple majority

        proposals[_proposalId].isExecuted = true;
        proposals[_proposalId].isPassed = passed;

        if (passed) {
            (bool success, ) = address(this).call(proposals[_proposalId].calldataData);
            require(success, "Proposal execution failed."); // Handle execution failure appropriately
            if (proposals[_proposalId].proposalType == ProposalType.MEMBERSHIP) {
                address newMemberAddress = abi.decode(proposals[_proposalId].calldataData[4:], (address)); // Extract address from calldata
                addMember(newMemberAddress); // Execute membership addition
            }
        }

        // Remove from active proposals list
        for (uint256 i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == _proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }

        emit ProposalExecuted(_proposalId, passed);
    }

    /// @dev Internal function to add a member after a membership proposal passes.
    function addMember(address _memberAddress) internal {
        require(!members[_memberAddress].isActive, "Member is already active.");
        members[_memberAddress].isActive = true;
        memberList.push(_memberAddress);
        memberCount++;
    }

    /// @notice Allows members to propose changes to collective rules/parameters.
    /// @param _title Title of the governance proposal.
    /// @param _description Detailed description of the proposal.
    /// @param _calldata Calldata to execute if the proposal passes (e.g., function signature and parameters).
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) public onlyMember {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.GOVERNANCE,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldataData: _calldata,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false,
            isPassed: false
        });
        activeProposals.push(proposalId);
        proposalCount++;
        emit GovernanceProposalCreated(proposalId, _title, _description);
    }

    /// @notice Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns a list of active proposal IDs.
    function getActiveProposals() public view returns (uint256[] memory) {
        return activeProposals;
    }

    /// @notice Returns the voting power of a member (currently simple 1 vote per member).
    /// @param _member The address of the member.
    function getVotingPower(address _member) public view onlyMember returns (uint256) {
        // In a more advanced system, voting power could be based on reputation, artwork contribution, etc.
        return 1; // Simple 1 vote per member for now
    }


    // -------------------- Art Management & Showcase Functions --------------------

    /// @notice Allows members to submit their artwork for showcase.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _artworkCID IPFS CID for the actual artwork file.
    /// @param _metadataCID IPFS CID for artwork metadata (optional but recommended).
    function submitArtwork(string memory _title, string memory _description, string memory _artworkCID, string memory _metadataCID) public onlyMember {
        uint256 artworkId = nextArtworkId++;
        artworks[artworkId] = Artwork({
            artworkId: artworkId,
            artistAddress: msg.sender,
            title: _title,
            description: _description,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            submissionTimestamp: block.timestamp,
            isCurated: false,
            curationScore: 0
        });
        artworkList.push(artworkId);
        artworkCount++;
        emit ArtworkSubmitted(artworkId, msg.sender, _title);
    }

    /// @notice Returns a list of artwork IDs showcased by the collective.
    function listCollectiveArtworks() public view returns (uint256[] memory) {
        return artworkList;
    }

    /// @notice Retrieves details of a specific artwork.
    /// @param _artworkId The ID of the artwork.
    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice Allows members to curate (vote to feature) an artwork. (Basic version, can be improved with governance)
    /// @param _artworkId The ID of the artwork to curate.
    function curateArtwork(uint256 _artworkId) public onlyMember artworkExists(_artworkId) {
        require(!artworks[_artworkId].isCurated, "Artwork is already curated.");
        artworks[_artworkId].curationScore++; // Simple curation score, can be improved with voting system
        if (artworks[_artworkId].curationScore > (memberCount / 2)) { // Simple majority for curation
            artworks[_artworkId].isCurated = true;
            curatedArtworkList.push(_artworkId);
            curatedArtworkCount++;
            emit ArtworkCurated(_artworkId);
        }
    }

    /// @notice Returns a list of artwork IDs that are currently curated/featured.
    function getCuratedArtworks() public view returns (uint256[] memory) {
        return curatedArtworkList;
    }


    // -------------------- Reputation & Contribution Functions (Advanced Concept) --------------------

    /// @notice Allows recording of member contributions (e.g., artwork submission, governance participation).
    /// @param _member The address of the contributing member.
    /// @param _contributionType Type of contribution (e.g., "Artwork Submission", "Governance Vote", "Community Event").
    /// @param _details Details of the contribution (e.g., artwork ID, proposal ID).
    function recordContribution(address _member, string memory _contributionType, string memory _details) public onlyMember { // Only members can record contributions for now, admin role could be added
        members[_member].reputationScore++; // Simple reputation increment, could be more nuanced based on contribution type
        emit ContributionRecorded(_member, _contributionType, _details);
    }

    /// @notice Returns a basic reputation score for a member.
    /// @param _member The address of the member.
    function getMemberReputation(address _member) public view onlyMember returns (uint256) {
        return members[_member].reputationScore;
    }


    // -------------------- Utility & Information Functions --------------------

    /// @notice Returns the name of the art collective.
    function getCollectiveName() public view returns (string memory) {
        return collectiveName;
    }

    /// @notice Returns the address of the contract owner (deployer).
    function getContractOwner() public view returns (address) {
        return contractOwner;
    }


    // --- Utility function to convert address to string (for proposal titles, etc.) ---
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes memory str = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 byte = bytes1(uint8(uint256(_addr) / (2**(8*(19 - i)))));
            uint8 hi = uint8(byte) / 16;
            uint8 lo = uint8(byte) % 16;
            str[i*2] = hi < 10 ? byte(uint8('0') + hi) : byte(uint8('a') + hi - 10);
            str[i*2+1] = lo < 10 ? byte(uint8('0') + lo) : byte(uint8('a') + lo - 10);
        }
        return string(str);
    }
}
```