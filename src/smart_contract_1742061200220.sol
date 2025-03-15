```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC)
 * that manages art submissions, curation, exhibitions, and community governance.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Functionality (Art & Curation):**
 *    - `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Allows members to submit art proposals with title, description, and IPFS hash.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members can vote on submitted art proposals (simple boolean vote).
 *    - `tallyArtProposalVotes(uint256 _proposalId)`: Tallies votes for an art proposal and determines if it's approved based on quorum and majority.
 *    - `mintArtNFT(uint256 _proposalId)`: Mints an NFT representing the approved art proposal. Only callable after proposal approval.
 *    - `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of an art proposal (title, description, IPFS hash, status, votes).
 *    - `getApprovedArtworks()`: Returns a list of IDs of approved artworks (NFTs minted).
 *
 * **2. Exhibition Management:**
 *    - `proposeExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256[] memory _artworkIds, uint256 _startTime, uint256 _endTime)`: Allows members to propose an art exhibition with a title, description, artworks, and time frame.
 *    - `voteOnExhibitionProposal(uint256 _exhibitionId, bool _vote)`: Members can vote on exhibition proposals.
 *    - `tallyExhibitionProposalVotes(uint256 _exhibitionId)`: Tallies votes for exhibition proposals and determines approval.
 *    - `scheduleExhibition(uint256 _exhibitionId)`: Schedules an approved exhibition, making it 'active'.
 *    - `endExhibition(uint256 _exhibitionId)`: Ends an active exhibition.
 *    - `getCurrentExhibition()`: Returns the ID of the currently active exhibition (if any).
 *    - `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of an exhibition (title, description, artworks, time, status, votes).
 *
 * **3. Membership & Governance:**
 *    - `joinCollective()`: Allows users to request membership in the DAAC. Requires approval from existing members.
 *    - `approveMembership(address _member)`: Allows existing members to approve pending membership requests.
 *    - `revokeMembership(address _member)`: Allows collective owners to revoke membership.
 *    - `delegateVote(address _delegate)`: Allows members to delegate their voting power to another member.
 *    - `updateVotingQuorum(uint256 _newQuorumPercentage)`: Allows collective owners to update the voting quorum percentage.
 *    - `getMemberDetails(address _member)`: Retrieves details of a member (membership status, delegated vote).
 *    - `getCollectiveMembers()`: Returns a list of addresses of current collective members.
 *
 * **4. Treasury & Funding (Basic):**
 *    - `depositFunds()` payable`: Allows anyone to deposit funds into the collective treasury.
 *    - `withdrawFunds(uint256 _amount)``: Allows collective owners to withdraw funds from the treasury for collective purposes.
 *    - `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 *
 * **5. Utility & Admin:**
 *    - `pauseContract()`: Pauses core functionalities of the contract (by owner).
 *    - `unpauseContract()`: Unpauses the contract (by owner).
 *    - `setVotingDuration(uint256 _durationInSeconds)`: Sets the default voting duration for proposals (by owner).
 *    - `getContractVersion()`: Returns the contract version string.
 *
 * **Advanced Concepts & Creativity:**
 * - **On-chain Curation & Governance:**  Fully decentralized process for art selection and exhibition planning.
 * - **Dynamic Membership:**  Membership requests and approvals managed by the collective.
 * - **Delegated Voting:**  Enables more active governance participation even for less frequent voters.
 * - **Basic Treasury Management:**  Foundation for future features like artist grants, exhibition funding, etc.
 * - **Pause Functionality:**  Emergency brake for critical situations.
 * - **Version Tracking:** Simple versioning for contract updates and transparency.
 * - **NFT Representation of Art:**  Leveraging NFTs for art ownership and provenance within the collective.
 * - **Exhibition Scheduling & Management:**  Organized approach to showcasing curated art.
 *
 * **No Open Source Duplication (to the best of my knowledge at time of writing):**
 * This contract aims to combine several common concepts (NFTs, voting, membership) in a unique way tailored to a Decentralized Autonomous Art Collective.  It is designed to be a specific implementation rather than a generic template.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public constant contractVersion = "1.0.0";

    // --- State Variables ---

    Counters.Counter private _artProposalIdCounter;
    Counters.Counter private _exhibitionIdCounter;
    Counters.Counter private _nftTokenIdCounter;

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingQuorumPercentage = 50; // Default quorum percentage for proposals (50%)

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 creationTime;
        bool isActive;
        bool isApproved;
        mapping(address => bool) votes; // Member address => vote (true=yes, false=no)
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ArtProposal) public artProposals;

    struct ExhibitionProposal {
        string title;
        string description;
        uint256[] artworkIds; // IDs of approved artworks to be exhibited
        uint256 startTime;
        uint256 endTime;
        address proposer;
        uint256 creationTime;
        bool isActive;
        bool isApproved;
        bool isScheduled;
        bool isEnded;
        mapping(address => bool) votes; // Member address => vote (true=yes, false=no)
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;

    uint256 public currentExhibitionId; // ID of the currently active exhibition, 0 if none

    mapping(address => bool) public collectiveMembers; // Address => isMember
    mapping(address => address) public voteDelegations; // Member address => delegate address
    mapping(address => bool) public pendingMembershipRequests; // Address => isPending

    // --- Events ---
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address minter);

    event ExhibitionProposalSubmitted(uint256 exhibitionId, address proposer, string title);
    event ExhibitionProposalVoted(uint256 exhibitionId, address voter, bool vote);
    event ExhibitionProposalApproved(uint256 exhibitionId);
    event ExhibitionScheduled(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);

    event MembershipRequested(address member);
    event MembershipApproved(address member, address approver);
    event MembershipRevoked(address member, address revoker);
    event VoteDelegated(address delegator, address delegate);
    event VotingQuorumUpdated(uint256 newQuorumPercentage);

    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);

    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Modifiers ---
    modifier onlyCollectiveMember() {
        require(collectiveMembers[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyProposalActive(uint256 _proposalId) {
        require(artProposals[_proposalId].isActive, "Proposal is not active");
        _;
    }

    modifier onlyExhibitionProposalActive(uint256 _exhibitionId) {
        require(exhibitionProposals[_exhibitionId].isActive, "Exhibition proposal is not active");
        _;
    }

    modifier onlyExhibitionScheduled(uint256 _exhibitionId) {
        require(exhibitionProposals[_exhibitionId].isScheduled, "Exhibition is not scheduled");
        _;
    }

    modifier onlyExhibitionNotEnded(uint256 _exhibitionId) {
        require(!exhibitionProposals[_exhibitionId].isEnded, "Exhibition is already ended");
        _;
    }

    modifier onlyExhibitionActive() {
        require(currentExhibitionId != 0, "No exhibition is currently active");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("DAAC Art NFT", "DAACArt") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner is admin
        _grantRole(OWNER_ROLE, msg.sender); // Owner role for specific owner functions
        collectiveMembers[msg.sender] = true; // Owner is initial member
    }

    // --- Pausable Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // --- Core Functionality (Art & Curation) ---

    /**
     * @dev Allows members to submit an art proposal.
     * @param _title Title of the art proposal.
     * @param _description Description of the art proposal.
     * @param _ipfsHash IPFS hash linking to the art data.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)
        external
        onlyCollectiveMember
        whenNotPaused
    {
        _artProposalIdCounter.increment();
        uint256 proposalId = _artProposalIdCounter.current();

        artProposals[proposalId] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            creationTime: block.timestamp,
            isActive: true,
            isApproved: false,
            yesVotes: 0,
            noVotes: 0
        });

        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on an active art proposal.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote)
        external
        onlyCollectiveMember
        onlyProposalActive(_proposalId)
        whenNotPaused
    {
        require(!artProposals[_proposalId].votes[msg.sender], "Member has already voted");
        require(artProposals[_proposalId].creationTime + votingDuration > block.timestamp, "Voting duration expired");

        artProposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }

        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Tallies votes for an art proposal and determines if it's approved.
     * @param _proposalId ID of the art proposal to tally votes for.
     */
    function tallyArtProposalVotes(uint256 _proposalId)
        external
        onlyCollectiveMember
        onlyProposalActive(_proposalId)
        whenNotPaused
    {
        require(artProposals[_proposalId].creationTime + votingDuration <= block.timestamp, "Voting duration not yet expired");
        require(!artProposals[_proposalId].isApproved, "Proposal already tallied and approved/rejected");

        uint256 totalMembers = getCollectiveMemberCount();
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;

        if (artProposals[_proposalId].yesVotes >= artProposals[_proposalId].noVotes && (artProposals[_proposalId].yesVotes + artProposals[_proposalId].noVotes) >= quorum) {
            artProposals[_proposalId].isApproved = true;
            emit ArtProposalApproved(_proposalId);
        }
        artProposals[_proposalId].isActive = false; // Deactivate proposal after tallying
    }

    /**
     * @dev Mints an NFT representing an approved art proposal.
     * @param _proposalId ID of the approved art proposal.
     */
    function mintArtNFT(uint256 _proposalId)
        external
        onlyCollectiveMember
        whenNotPaused
    {
        require(artProposals[_proposalId].isApproved, "Art proposal not approved");
        require(!artProposals[_proposalId].isActive, "Art proposal voting still active"); // Ensure proposal is finalized

        _nftTokenIdCounter.increment();
        uint256 tokenId = _nftTokenIdCounter.current();
        _mint(address(this), tokenId); // Mint to contract, collective owns it initially

        emit ArtNFTMinted(tokenId, _proposalId, msg.sender);
    }

    /**
     * @dev Retrieves details of an art proposal.
     * @param _proposalId ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId)
        external
        view
        returns (ArtProposal memory)
    {
        return artProposals[_proposalId];
    }

    /**
     * @dev Returns a list of IDs of approved artworks (NFTs minted).
     * @return Array of artwork IDs.
     */
    function getApprovedArtworks()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory approvedArtworks = new uint256[](_nftTokenIdCounter.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _artProposalIdCounter.current(); i++) {
            if (artProposals[i].isApproved) {
                approvedArtworks[count] = i; // Using proposal ID as artwork ID for simplicity
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(approvedArtworks, count)
        }
        return approvedArtworks;
    }


    // --- Exhibition Management ---

    /**
     * @dev Allows members to propose an art exhibition.
     * @param _exhibitionTitle Title of the exhibition.
     * @param _exhibitionDescription Description of the exhibition.
     * @param _artworkIds Array of artwork IDs (from approved proposals) to be exhibited.
     * @param _startTime Unix timestamp for exhibition start time.
     * @param _endTime Unix timestamp for exhibition end time.
     */
    function proposeExhibition(
        string memory _exhibitionTitle,
        string memory _exhibitionDescription,
        uint256[] memory _artworkIds,
        uint256 _startTime,
        uint256 _endTime
    )
        external
        onlyCollectiveMember
        whenNotPaused
    {
        require(_startTime < _endTime, "Start time must be before end time");
        require(_startTime > block.timestamp, "Start time must be in the future");
        require(_artworkIds.length > 0, "Exhibition must include at least one artwork");

        _exhibitionIdCounter.increment();
        uint256 exhibitionId = _exhibitionIdCounter.current();

        exhibitionProposals[exhibitionId] = ExhibitionProposal({
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            artworkIds: _artworkIds,
            startTime: _startTime,
            endTime: _endTime,
            proposer: msg.sender,
            creationTime: block.timestamp,
            isActive: true,
            isApproved: false,
            isScheduled: false,
            isEnded: false,
            yesVotes: 0,
            noVotes: 0
        });

        emit ExhibitionProposalSubmitted(exhibitionId, msg.sender, _exhibitionTitle);
    }

    /**
     * @dev Allows members to vote on an active exhibition proposal.
     * @param _exhibitionId ID of the exhibition proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnExhibitionProposal(uint256 _exhibitionId, bool _vote)
        external
        onlyCollectiveMember
        onlyExhibitionProposalActive(_exhibitionId)
        whenNotPaused
    {
        require(!exhibitionProposals[_exhibitionId].votes[msg.sender], "Member has already voted");
        require(exhibitionProposals[_exhibitionId].creationTime + votingDuration > block.timestamp, "Voting duration expired");

        exhibitionProposals[_exhibitionId].votes[msg.sender] = _vote;
        if (_vote) {
            exhibitionProposals[_exhibitionId].yesVotes++;
        } else {
            exhibitionProposals[_exhibitionId].noVotes++;
        }

        emit ExhibitionProposalVoted(_exhibitionId, msg.sender, _vote);
    }

    /**
     * @dev Tallies votes for an exhibition proposal and determines if it's approved.
     * @param _exhibitionId ID of the exhibition proposal to tally votes for.
     */
    function tallyExhibitionProposalVotes(uint256 _exhibitionId)
        external
        onlyCollectiveMember
        onlyExhibitionProposalActive(_exhibitionId)
        whenNotPaused
    {
        require(exhibitionProposals[_exhibitionId].creationTime + votingDuration <= block.timestamp, "Voting duration not yet expired");
        require(!exhibitionProposals[_exhibitionId].isApproved, "Exhibition proposal already tallied and approved/rejected");

        uint256 totalMembers = getCollectiveMemberCount();
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;

        if (exhibitionProposals[_exhibitionId].yesVotes >= exhibitionProposals[_exhibitionId].noVotes && (exhibitionProposals[_exhibitionId].yesVotes + exhibitionProposals[_exhibitionId].noVotes) >= quorum) {
            exhibitionProposals[_exhibitionId].isApproved = true;
            emit ExhibitionProposalApproved(_exhibitionId);
        }
        exhibitionProposals[_exhibitionId].isActive = false; // Deactivate proposal after tallying
    }

    /**
     * @dev Schedules an approved exhibition, making it 'active'.
     * @param _exhibitionId ID of the approved exhibition proposal.
     */
    function scheduleExhibition(uint256 _exhibitionId)
        external
        onlyCollectiveMember
        whenNotPaused
    {
        require(exhibitionProposals[_exhibitionId].isApproved, "Exhibition proposal not approved");
        require(!exhibitionProposals[_exhibitionId].isScheduled, "Exhibition already scheduled");
        require(currentExhibitionId == 0, "Another exhibition is already active"); // Only one at a time

        exhibitionProposals[_exhibitionId].isScheduled = true;
        currentExhibitionId = _exhibitionId;
        emit ExhibitionScheduled(_exhibitionId);
    }

    /**
     * @dev Ends an active exhibition.
     * @param _exhibitionId ID of the exhibition to end.
     */
    function endExhibition(uint256 _exhibitionId)
        external
        onlyCollectiveMember
        onlyExhibitionScheduled(_exhibitionId)
        onlyExhibitionNotEnded(_exhibitionId)
        whenNotPaused
    {
        require(currentExhibitionId == _exhibitionId, "Not the currently active exhibition");
        require(block.timestamp >= exhibitionProposals[_exhibitionId].endTime, "Exhibition end time not reached");

        exhibitionProposals[_exhibitionId].isEnded = true;
        currentExhibitionId = 0; // Reset current exhibition
        emit ExhibitionEnded(_exhibitionId);
    }

    /**
     * @dev Returns the ID of the currently active exhibition.
     * @return Exhibition ID, or 0 if no active exhibition.
     */
    function getCurrentExhibition()
        external
        view
        returns (uint256)
    {
        return currentExhibitionId;
    }

    /**
     * @dev Retrieves details of an exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @return ExhibitionProposal struct containing exhibition details.
     */
    function getExhibitionDetails(uint256 _exhibitionId)
        external
        view
        returns (ExhibitionProposal memory)
    {
        return exhibitionProposals[_exhibitionId];
    }


    // --- Membership & Governance ---

    /**
     * @dev Allows a user to request membership in the DAAC.
     */
    function joinCollective() external whenNotPaused {
        require(!collectiveMembers[msg.sender], "Already a member");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /**
     * @dev Allows existing members to approve a pending membership request.
     * @param _member Address of the member to approve.
     */
    function approveMembership(address _member) external onlyCollectiveMember whenNotPaused {
        require(pendingMembershipRequests[_member], "No membership request pending");
        require(!collectiveMembers[_member], "Already a member");
        collectiveMembers[_member] = true;
        pendingMembershipRequests[_member] = false;
        emit MembershipApproved(_member, msg.sender);
    }

    /**
     * @dev Allows collective owners to revoke membership.
     * @param _member Address of the member to revoke.
     */
    function revokeMembership(address _member) external onlyOwner whenNotPaused {
        require(collectiveMembers[_member], "Not a member");
        delete collectiveMembers[_member];
        delete voteDelegations[_member]; // Clear any delegation
        emit MembershipRevoked(_member, msg.sender);
    }

    /**
     * @dev Allows members to delegate their voting power to another member.
     * @param _delegate Address of the member to delegate vote to.
     */
    function delegateVote(address _delegate) external onlyCollectiveMember whenNotPaused {
        require(collectiveMembers[_delegate], "Delegate must be a collective member");
        require(_delegate != msg.sender, "Cannot delegate to self");
        voteDelegations[msg.sender] = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    /**
     * @dev Allows collective owners to update the voting quorum percentage.
     * @param _newQuorumPercentage New quorum percentage (0-100).
     */
    function updateVotingQuorum(uint256 _newQuorumPercentage) external onlyOwner whenNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        votingQuorumPercentage = _newQuorumPercentage;
        emit VotingQuorumUpdated(_newQuorumPercentage);
    }

    /**
     * @dev Retrieves details of a member.
     * @param _member Address of the member.
     * @return Membership status (bool), delegated vote address (address).
     */
    function getMemberDetails(address _member)
        external
        view
        returns (bool isMember, address delegate)
    {
        return (collectiveMembers[_member], voteDelegations[_member]);
    }

    /**
     * @dev Returns a list of addresses of current collective members.
     * @return Array of member addresses.
     */
    function getCollectiveMembers()
        external
        view
        returns (address[] memory)
    {
        address[] memory members = new address[](getCollectiveMemberCount());
        uint256 index = 0;
        for (uint256 i = 0; i < address(this).balance; i++) { // Iterate through potential addresses (inefficient, but works for demonstration)
            address memberAddress = address(uint160(i)); // Convert index to address (very simplified, not robust for real-world)
            if (collectiveMembers[memberAddress]) {
                members[index] = memberAddress;
                index++;
            }
            if (index == members.length) break; // Optimization: Stop if array is full
        }
        return members;
    }

    /**
     * @dev Helper function to count the number of collective members.
     * @return Number of collective members.
     */
    function getCollectiveMemberCount() public view returns (uint256) {
        uint256 memberCount = 0;
        for (uint256 i = 0; i < address(this).balance; i++) { // Iterate through potential addresses (inefficient, but works for demonstration)
            address memberAddress = address(uint160(i)); // Convert index to address (very simplified, not robust for real-world)
            if (collectiveMembers[memberAddress]) {
                memberCount++;
            }
        }
        return memberCount;
    }


    // --- Treasury & Funding (Basic) ---

    /**
     * @dev Allows anyone to deposit funds into the collective treasury.
     */
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows collective owners to withdraw funds from the treasury for collective purposes.
     * @param _amount Amount to withdraw.
     */
    function withdrawFunds(uint256 _amount) external onlyOwner whenNotPaused {
        payable(owner()).transfer(_amount); // Owner can withdraw to their address
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Returns the current balance of the collective treasury.
     * @return Treasury balance in wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- Utility & Admin ---

    /**
     * @dev Pauses core functionalities of the contract.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring functionalities.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Sets the default voting duration for proposals.
     * @param _durationInSeconds Voting duration in seconds.
     */
    function setVotingDuration(uint256 _durationInSeconds) external onlyOwner {
        votingDuration = _durationInSeconds;
    }

    /**
     * @dev Returns the contract version string.
     * @return Contract version.
     */
    function getContractVersion() external pure returns (string memory) {
        return contractVersion;
    }

    // --- Overrides for ERC721 ---
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://your_base_uri_here/"; // Replace with your base URI for metadata
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Customize token URI generation based on your metadata structure and storage
        // For example, if you store metadata for each proposal on IPFS:
        uint256 proposalId = tokenId; // Assuming tokenId is same as proposalId for simplicity here
        string memory ipfsHash = artProposals[proposalId].ipfsHash;
        return string(abi.encodePacked(_baseURI(), ipfsHash));
    }
}
```