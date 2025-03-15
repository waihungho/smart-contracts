```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective.
 *      This contract allows members to join, contribute art, vote on art curation,
 *      manage a treasury, and participate in collective decision-making regarding art
 *      creation, sales, and future directions. It introduces concepts like dynamic art
 *      royalty distribution based on contribution, collaborative generative art projects,
 *      and on-chain reputation system within the art collective.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *   - `joinCollective(string _artistName, string _artistStatement)`: Allows artists to request membership with name and statement.
 *   - `approveMembership(address _artistAddress)`: Admin function to approve pending membership requests.
 *   - `rejectMembership(address _artistAddress)`: Admin function to reject pending membership requests.
 *   - `leaveCollective()`: Allows members to voluntarily leave the collective.
 *   - `proposeExpulsion(address _memberAddress, string _reason)`: Members can propose expulsion of another member with a reason.
 *   - `voteOnExpulsion(address _memberAddress, bool _vote)`: Members vote on proposed expulsions.
 *   - `getMemberInfo(address _memberAddress) view returns (string name, string statement, bool isActive, uint reputationScore, uint joinTimestamp)`: Retrieves member information.
 *   - `getMemberList() view returns (address[] memberList)`: Returns a list of active member addresses.
 *
 * **2. Art Contribution and Management:**
 *   - `submitArtProposal(string _artTitle, string _artDescription, string _artHash)`: Members propose new artwork with title, description, and IPFS hash.
 *   - `voteOnArtProposal(uint _proposalId, bool _vote)`: Members vote on submitted art proposals.
 *   - `mintArtNFT(uint _proposalId)`: Admin/approved members can mint an NFT for an approved art proposal.
 *   - `setArtNFTMetadata(uint _artId, string _newMetadataHash)`: Allows updating NFT metadata (e.g., after curation).
 *   - `getArtProposalInfo(uint _proposalId) view returns (proposal details)`: Retrieves information about an art proposal.
 *   - `getArtNFTInfo(uint _artId) view returns (NFT details)`: Retrieves information about a minted art NFT.
 *   - `listArtForSale(uint _artId, uint _price)`: Allows the collective to list an approved NFT for sale.
 *   - `delistArtForSale(uint _artId)`: Allows the collective to delist an NFT from sale.
 *   - `buyArtNFT(uint _artId) payable`: Allows anyone to purchase a listed art NFT.
 *
 * **3. Collaborative Generative Art Project (Example - Concept):**
 *   - `startGenerativeArtProject(string _projectName, string _projectDescription, string _initialSeed)`:  Admin/members can initiate a collaborative generative art project with parameters.
 *   - `contributeToGenerativeArt(uint _projectId, string _contributionData)`: Members contribute data or parameters to a generative art project. (Concept - specific data structure needs design).
 *   - `finalizeGenerativeArtProject(uint _projectId)`: Admin/approved members finalize a generative art project, potentially minting NFTs based on collective input.
 *
 * **4. Treasury and Revenue Distribution:**
 *   - `depositFunds() payable`: Allows anyone to deposit funds into the collective's treasury.
 *   - `withdrawFunds(uint _amount)`: Admin-controlled function to withdraw funds from the treasury (governance vote could be added for more decentralization).
 *   - `distributeArtRoyalties(uint _artId)`: Distributes royalties from art sales to contributors based on a dynamic contribution model.
 *   - `getTreasuryBalance() view returns (uint balance)`: Returns the current treasury balance.
 *
 * **5. Reputation and Governance (Basic Example):**
 *   - `increaseReputation(address _memberAddress, uint _amount)`: Admin function to manually increase member reputation (for exceptional contributions - more robust reputation system can be designed).
 *   - `decreaseReputation(address _memberAddress, uint _amount)`: Admin function to decrease member reputation.
 *   - `proposeParameterChange(string _parameterName, uint _newValue)`: Members propose changes to contract parameters (e.g., voting durations, royalty splits - example).
 *   - `voteOnParameterChange(uint _proposalId, bool _vote)`: Members vote on proposed parameter changes.
 *
 * **6. Utility/Information:**
 *   - `getCollectiveName() view returns (string name)`: Returns the name of the collective.
 *   - `getContractAdmin() view returns (address admin)`: Returns the address of the contract administrator.
 *   - `getVotingDuration() view returns (uint duration)`: Returns the default voting duration.
 *
 */
contract DecentralizedAutonomousArtCollective {
    string public collectiveName = "DAAAC - Genesis Collective";
    address public contractAdmin;
    uint public votingDuration = 7 days; // Default voting duration

    // --- Structs ---
    struct Member {
        string artistName;
        string artistStatement;
        bool isActive;
        uint reputationScore;
        uint joinTimestamp;
    }

    struct ArtProposal {
        string artTitle;
        string artDescription;
        string artHash; // IPFS hash of the artwork
        address proposer;
        uint upvotes;
        uint downvotes;
        bool isApproved;
        bool isMinted;
        uint proposalTimestamp;
    }

    struct ArtNFT {
        uint artProposalId;
        string metadataHash; // IPFS hash of NFT metadata
        address owner;
        uint salePrice;
        bool isListedForSale;
    }

    struct ExpulsionProposal {
        address memberAddress;
        string reason;
        address proposer;
        uint upvotes;
        uint downvotes;
        bool isApproved;
        uint proposalTimestamp;
    }

    struct ParameterChangeProposal {
        string parameterName;
        uint newValue;
        address proposer;
        uint upvotes;
        uint downvotes;
        bool isApproved;
        uint proposalTimestamp;
    }

    struct GenerativeArtProject {
        string projectName;
        string projectDescription;
        string initialSeed;
        address initiator;
        uint contributionCount;
        bool isFinalized;
        uint projectTimestamp;
        // Add more fields as needed for generative art parameters and contributions
    }


    // --- State Variables ---
    mapping(address => Member) public members;
    mapping(uint => ArtProposal) public artProposals;
    mapping(uint => ArtNFT) public artNFTs;
    mapping(uint => ExpulsionProposal) public expulsionProposals;
    mapping(uint => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint => GenerativeArtProject) public generativeArtProjects;

    uint public nextArtProposalId = 1;
    uint public nextArtNFTId = 1;
    uint public nextExpulsionProposalId = 1;
    uint public nextParameterChangeProposalId = 1;
    uint public nextGenerativeArtProjectId = 1;

    address[] public pendingMembershipRequests;
    address[] public memberList;

    // --- Events ---
    event MembershipRequested(address artistAddress, string artistName);
    event MembershipApproved(address artistAddress);
    event MembershipRejected(address artistAddress);
    event MemberLeftCollective(address artistAddress);
    event MemberExpulsionProposed(uint proposalId, address memberAddress, string reason, address proposer);
    event MemberExpelled(address memberAddress);

    event ArtProposalSubmitted(uint proposalId, string artTitle, address proposer);
    event ArtProposalApproved(uint proposalId);
    event ArtProposalRejected(uint proposalId);
    event ArtNFTMinted(uint artId, uint proposalId, address minter);
    event ArtNFTMetadataUpdated(uint artId, string newMetadataHash);
    event ArtNFTListedForSale(uint artId, uint price);
    event ArtNFTDelistedFromSale(uint artId);
    event ArtNFTSold(uint artId, address buyer, uint price);

    event FundsDeposited(address depositor, uint amount);
    event FundsWithdrawn(address withdrawer, uint amount);
    event RoyaltiesDistributed(uint artId, address[] recipients, uint[] shares);

    event ParameterChangeProposed(uint proposalId, string parameterName, uint newValue, address proposer);
    event ParameterChangeApproved(uint proposalId, string parameterName, uint newValue);

    event GenerativeArtProjectStarted(uint projectId, string projectName, address initiator);
    event GenerativeArtContribution(uint projectId, address contributor);
    event GenerativeArtProjectFinalized(uint projectId);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == contractAdmin, "Only admin can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].isActive, "Only active members can call this function.");
        _;
    }

    modifier validProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId < nextArtProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validArtId(uint _artId) {
        require(_artId > 0 && _artId < nextArtNFTId, "Invalid Art NFT ID.");
        _;
    }

    modifier validExpulsionProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId < nextExpulsionProposalId, "Invalid expulsion proposal ID.");
        _;
    }

    modifier validParameterChangeProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId < nextParameterChangeProposalId, "Invalid parameter change proposal ID.");
        _;
    }

    modifier validGenerativeArtProjectId(uint _projectId) {
        require(_projectId > 0 && _projectId < nextGenerativeArtProjectId, "Invalid generative art project ID.");
        _;
    }


    // --- Constructor ---
    constructor() {
        contractAdmin = msg.sender;
    }

    // --- 1. Membership Management ---

    function joinCollective(string memory _artistName, string memory _artistStatement) public {
        require(!members[msg.sender].isActive, "Already a member or membership pending.");
        members[msg.sender] = Member({
            artistName: _artistName,
            artistStatement: _artistStatement,
            isActive: false, // Initially pending
            reputationScore: 0,
            joinTimestamp: block.timestamp
        });
        pendingMembershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender, _artistName);
    }

    function approveMembership(address _artistAddress) public onlyAdmin {
        require(!members[_artistAddress].isActive && !isAddressInArray(pendingMembershipRequests, _artistAddress), "Not a pending membership request.");
        members[_artistAddress].isActive = true;
        memberList.push(_artistAddress);
        removeAddressFromArray(pendingMembershipRequests, _artistAddress); // Remove from pending list
        emit MembershipApproved(_artistAddress);
    }

    function rejectMembership(address _artistAddress) public onlyAdmin {
        require(!members[_artistAddress].isActive && !isAddressInArray(pendingMembershipRequests, _artistAddress), "Not a pending membership request.");
        delete members[_artistAddress]; // Remove member entry completely if rejected
        removeAddressFromArray(pendingMembershipRequests, _artistAddress); // Remove from pending list
        emit MembershipRejected(_artistAddress);
    }

    function leaveCollective() public onlyMembers {
        members[msg.sender].isActive = false;
        removeAddressFromArray(memberList, msg.sender);
        emit MemberLeftCollective(msg.sender);
    }

    function proposeExpulsion(address _memberAddress, string memory _reason) public onlyMembers {
        require(members[_memberAddress].isActive && _memberAddress != msg.sender, "Invalid member for expulsion.");
        ExpulsionProposal storage proposal = expulsionProposals[nextExpulsionProposalId];
        proposal.memberAddress = _memberAddress;
        proposal.reason = _reason;
        proposal.proposer = msg.sender;
        proposal.proposalTimestamp = block.timestamp;
        nextExpulsionProposalId++;
        emit MemberExpulsionProposed(nextExpulsionProposalId -1, _memberAddress, _reason, msg.sender);
    }

    function voteOnExpulsion(uint _proposalId, bool _vote) public onlyMembers validExpulsionProposalId(_proposalId) {
        ExpulsionProposal storage proposal = expulsionProposals[_proposalId];
        require(!proposal.isApproved, "Expulsion proposal already finalized.");
        require(block.timestamp < proposal.proposalTimestamp + votingDuration, "Voting period expired.");

        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }

        if (proposal.upvotes > (memberList.length / 2)) { // Simple majority for expulsion
            proposal.isApproved = true;
            members[proposal.memberAddress].isActive = false;
            removeAddressFromArray(memberList, proposal.memberAddress);
            emit MemberExpelled(proposal.memberAddress);
        }
    }

    function getMemberInfo(address _memberAddress) public view returns (string memory name, string memory statement, bool isActive, uint reputationScore, uint joinTimestamp) {
        require(members[_memberAddress].isActive || !isAddressInArray(pendingMembershipRequests, _memberAddress), "Address is not associated with any membership."); //Allow info for pending requests as well
        return (
            members[_memberAddress].artistName,
            members[_memberAddress].artistStatement,
            members[_memberAddress].isActive,
            members[_memberAddress].reputationScore,
            members[_memberAddress].joinTimestamp
        );
    }

    function getMemberList() public view returns (address[] memory) {
        return memberList;
    }


    // --- 2. Art Contribution and Management ---

    function submitArtProposal(string memory _artTitle, string memory _artDescription, string memory _artHash) public onlyMembers {
        ArtProposal storage proposal = artProposals[nextArtProposalId];
        proposal.artTitle = _artTitle;
        proposal.artDescription = _artDescription;
        proposal.artHash = _artHash;
        proposal.proposer = msg.sender;
        proposal.proposalTimestamp = block.timestamp;
        nextArtProposalId++;
        emit ArtProposalSubmitted(nextArtProposalId - 1, _artTitle, msg.sender);
    }

    function voteOnArtProposal(uint _proposalId, bool _vote) public onlyMembers validProposalId(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.isApproved && !proposal.isRejected, "Art proposal already finalized.");
        require(block.timestamp < proposal.proposalTimestamp + votingDuration, "Voting period expired.");

        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }

        if (proposal.upvotes > (memberList.length / 2)) { // Simple majority to approve
            proposal.isApproved = true;
            emit ArtProposalApproved(_proposalId);
        } else if (proposal.downvotes > (memberList.length / 2)) {
            proposal.isRejected = true;
            emit ArtProposalRejected(_proposalId);
        }
    }

    function mintArtNFT(uint _proposalId) public onlyAdmin validProposalId(_proposalId) { //Admin or designated minter role
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.isApproved && !proposal.isMinted, "Art proposal not approved or already minted.");

        ArtNFT storage artNFT = artNFTs[nextArtNFTId];
        artNFT.artProposalId = _proposalId;
        artNFT.metadataHash = proposal.artHash; //Initial metadata hash is proposal hash
        artNFT.owner = address(this); // Collective owns initially
        proposal.isMinted = true;

        emit ArtNFTMinted(nextArtNFTId, _proposalId, msg.sender);
        nextArtNFTId++;
    }

    function setArtNFTMetadata(uint _artId, string memory _newMetadataHash) public onlyAdmin validArtId(_artId) {
        ArtNFT storage artNFT = artNFTs[_artId];
        artNFT.metadataHash = _newMetadataHash;
        emit ArtNFTMetadataUpdated(_artId, _newMetadataHash);
    }

    function getArtProposalInfo(uint _proposalId) public view validProposalId(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getArtNFTInfo(uint _artId) public view validArtId(_artId) returns (ArtNFT memory) {
        return artNFTs[_artId];
    }

    function listArtForSale(uint _artId, uint _price) public onlyAdmin validArtId(_artId) { // Admin or governance can list
        ArtNFT storage artNFT = artNFTs[_artId];
        require(artNFT.owner == address(this), "Collective does not own this NFT.");
        artNFT.salePrice = _price;
        artNFT.isListedForSale = true;
        emit ArtNFTListedForSale(_artId, _price);
    }

    function delistArtForSale(uint _artId) public onlyAdmin validArtId(_artId) {
        ArtNFT storage artNFT = artNFTs[_artId];
        require(artNFT.owner == address(this), "Collective does not own this NFT.");
        artNFT.isListedForSale = false;
        emit ArtNFTDelistedFromSale(_artId);
    }

    function buyArtNFT(uint _artId) public payable validArtId(_artId) {
        ArtNFT storage artNFT = artNFTs[_artId];
        require(artNFT.isListedForSale, "Art NFT is not listed for sale.");
        require(msg.value >= artNFT.salePrice, "Insufficient funds sent.");

        address previousOwner = artNFT.owner;
        artNFT.owner = msg.sender;
        artNFT.isListedForSale = false;
        uint saleAmount = artNFT.salePrice;
        artNFT.salePrice = 0; // Reset sale price

        // Transfer funds to treasury
        payable(address(this)).transfer(saleAmount);
        emit ArtNFTSold(_artId, msg.sender, saleAmount);

        // Distribute royalties (example - simple split, can be more complex)
        distributeArtRoyalties(_artId);
    }


    function distributeArtRoyalties(uint _artId) private {
        ArtNFT storage artNFT = artNFTs[_artId];
        ArtProposal storage proposal = artProposals[artNFT.artProposalId];

        uint totalSaleValue = artNFT.salePrice;
        uint artistShare = totalSaleValue * 70 / 100; // 70% to artist/proposer (example)
        uint collectiveShare = totalSaleValue * 30 / 100; // 30% to collective (example)

        // Simple royalty distribution - proposer gets artist share for now.
        // In a real system, contribution tracking and more complex logic would be needed.
        payable(proposal.proposer).transfer(artistShare);

        // Collective share remains in the contract treasury.
        emit RoyaltiesDistributed(_artId, [proposal.proposer, address(this)], [artistShare, collectiveShare]);
    }


    // --- 3. Collaborative Generative Art Project (Example - Concept) ---

    function startGenerativeArtProject(string memory _projectName, string memory _projectDescription, string memory _initialSeed) public onlyAdmin { // Or governed initiation
        GenerativeArtProject storage project = generativeArtProjects[nextGenerativeArtProjectId];
        project.projectName = _projectName;
        project.projectDescription = _projectDescription;
        project.initialSeed = _initialSeed;
        project.initiator = msg.sender;
        project.projectTimestamp = block.timestamp;
        emit GenerativeArtProjectStarted(nextGenerativeArtProjectId, _projectName, msg.sender);
        nextGenerativeArtProjectId++;
    }

    function contributeToGenerativeArt(uint _projectId, string memory _contributionData) public onlyMembers validGenerativeArtProjectId(_projectId) {
        GenerativeArtProject storage project = generativeArtProjects[_projectId];
        require(!project.isFinalized, "Generative art project is already finalized.");
        // Store contribution data - can be more structured based on project needs
        // e.g., project.contributions[msg.sender].push(_contributionData);
        project.contributionCount++; // Simple contribution counter
        emit GenerativeArtContribution(_projectId, msg.sender);
    }

    function finalizeGenerativeArtProject(uint _projectId) public onlyAdmin validGenerativeArtProjectId(_projectId) { // Or governed finalization
        GenerativeArtProject storage project = generativeArtProjects[_projectId];
        require(!project.isFinalized, "Generative art project is already finalized.");
        project.isFinalized = true;
        emit GenerativeArtProjectFinalized(_projectId);
        // Logic to generate and mint NFTs based on collective contributions would go here
        // (complex, depends on generative art method and data structure).
    }


    // --- 4. Treasury and Revenue Distribution ---

    function depositFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint _amount) public onlyAdmin { // Governance could be added for withdrawal approval
        require(address(this).balance >= _amount, "Insufficient funds in treasury.");
        payable(contractAdmin).transfer(_amount); // Admin withdraws for collective purposes
        emit FundsWithdrawn(contractAdmin, _amount);
    }

    function getTreasuryBalance() public view returns (uint) {
        return address(this).balance;
    }


    // --- 5. Reputation and Governance (Basic Example) ---

    function increaseReputation(address _memberAddress, uint _amount) public onlyAdmin {
        members[_memberAddress].reputationScore += _amount;
    }

    function decreaseReputation(address _memberAddress, uint _amount) public onlyAdmin {
        members[_memberAddress].reputationScore -= _amount;
    }

    function proposeParameterChange(string memory _parameterName, uint _newValue) public onlyMembers {
        ParameterChangeProposal storage proposal = parameterChangeProposals[nextParameterChangeProposalId];
        proposal.parameterName = _parameterName;
        proposal.newValue = _newValue;
        proposal.proposer = msg.sender;
        proposal.proposalTimestamp = block.timestamp;
        nextParameterChangeProposalId++;
        emit ParameterChangeProposed(nextParameterChangeProposalId - 1, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChange(uint _proposalId, bool _vote) public onlyMembers validParameterChangeProposalId(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.isApproved, "Parameter change proposal already finalized.");
        require(block.timestamp < proposal.proposalTimestamp + votingDuration, "Voting period expired.");

        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }

        if (proposal.upvotes > (memberList.length / 2)) { // Simple majority to approve
            proposal.isApproved = true;
            // Apply parameter change (example - only votingDuration for now)
            if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
                votingDuration = proposal.newValue;
            }
            emit ParameterChangeApproved(_proposalId, proposal.parameterName, proposal.newValue);
        }
    }


    // --- 6. Utility/Information ---

    function getCollectiveName() public view returns (string memory) {
        return collectiveName;
    }

    function getContractAdmin() public view returns (address) {
        return contractAdmin;
    }

    function getVotingDuration() public view returns (uint) {
        return votingDuration;
    }


    // --- Internal Utility Functions ---
    function isAddressInArray(address[] memory _array, address _address) internal pure returns (bool) {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function removeAddressFromArray(address[] storage _array, address _address) internal {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _address) {
                // Shift elements to overwrite the removed element
                for (uint j = i; j < _array.length - 1; j++) {
                    _array[j] = _array[j + 1];
                }
                _array.pop(); // Remove the last element (duplicate from shifting)
                break; // Address found and removed, exit loop
            }
        }
    }

    // Fallback function to receive Ether (for treasury deposits)
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```