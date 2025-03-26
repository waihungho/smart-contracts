```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that allows artists to submit art proposals,
 *      community members to vote on them, mint NFTs for approved artworks, manage a collective treasury,
 *      organize collaborative art projects, curate digital art exhibitions, and implement a reputation system for members.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Management & Art Proposals:**
 *    - `submitArtProposal(string _title, string _description, string _ipfsHash)`: Allows artists to submit art proposals with title, description, and IPFS hash.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members can vote on pending art proposals.
 *    - `mintNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal if the quorum is reached.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Standard NFT transfer function.
 *    - `burnNFT(uint256 _tokenId)`: Allows burning of NFTs (governance controlled).
 *    - `getNFTMetadata(uint256 _tokenId)`: Retrieves metadata (title, description, IPFS hash) of an NFT.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of an art proposal.
 *
 * **2. DAO Governance & Membership:**
 *    - `submitGovernanceProposal(string _description, bytes _calldata)`: Allows members to submit general governance proposals.
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Members vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Executes a successful governance proposal.
 *    - `addMember(address _newMember)`: Allows adding new members (governance or admin controlled).
 *    - `removeMember(address _member)`: Allows removing members (governance or admin controlled).
 *    - `isMember(address _account)`: Checks if an address is a member of the DAAC.
 *    - `setVotingPeriod(uint256 _newPeriod)`: Sets the voting period for proposals (governance controlled).
 *    - `setQuorum(uint256 _newQuorum)`: Sets the quorum for proposals (governance controlled).
 *
 * **3. Collective Treasury & Funding:**
 *    - `donateToCollective()`: Allows anyone to donate ETH to the collective treasury.
 *    - `proposeFundingDistribution(address _recipient, uint256 _amount, string _reason)`: Members can propose fund distribution from the treasury.
 *    - `voteOnFundingDistribution(uint256 _proposalId, bool _vote)`: Members vote on funding distribution proposals.
 *    - `executeFundingDistribution(uint256 _proposalId)`: Executes approved funding distribution proposals.
 *    - `getBalance()`: Returns the current balance of the collective treasury.
 *
 * **4. Collaborative Art Projects:**
 *    - `startCollaborationProject(string _projectName, string _description)`: Initiates a collaborative art project proposal.
 *    - `joinCollaborationProject(uint256 _projectId)`: Members can join an ongoing collaboration project.
 *    - `submitContributionToProject(uint256 _projectId, string _contributionDescription, string _ipfsHash)`: Members submit contributions to a project.
 *    - `voteOnProjectContribution(uint256 _projectId, uint256 _contributionId, bool _vote)`: Members vote on project contributions.
 *    - `finalizeCollaborationProject(uint256 _projectId)`: Finalizes a project, potentially distributing rewards or NFTs to contributors (governance controlled).
 *
 * **5. Digital Art Exhibitions (Conceptual):**
 *    - `createExhibition(string _exhibitionName, string _description, uint256[] _nftTokenIds)`: Propose and create a digital art exhibition featuring selected NFTs.
 *    - `voteOnExhibition(uint256 _exhibitionId, bool _vote)`: Members vote on exhibition proposals.
 *    - `startExhibition(uint256 _exhibitionId)`: Starts a approved exhibition (conceptual, might require off-chain rendering/display logic).
 *
 * **6. Reputation System (Basic):**
 *    - `upvoteMember(address _memberToUpvote)`: Members can upvote other members for positive contributions.
 *    - `downvoteMember(address _memberToDownvote)`: Members can downvote other members for negative contributions.
 *    - `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs ---

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool exists;
    }

    struct GovernanceProposal {
        string description;
        bytes calldata;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
        bool exists;
    }

    struct FundingDistributionProposal {
        address recipient;
        uint256 amount;
        string reason;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
        bool exists;
    }

    struct CollaborationProject {
        string name;
        string description;
        address initiator;
        bool active;
        bool exists;
    }

    struct ProjectContribution {
        string description;
        string ipfsHash;
        address contributor;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool exists;
    }

    struct ExhibitionProposal {
        string name;
        string description;
        uint256[] nftTokenIds;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool started;
        bool exists;
    }

    // --- State Variables ---

    Counters.Counter private _nftTokenIds;
    Counters.Counter private _artProposalIds;
    Counters.Counter private _governanceProposalIds;
    Counters.Counter private _fundingProposalIds;
    Counters.Counter private _collaborationProjectIds;
    Counters.Counter private _projectContributionIds;
    Counters.Counter private _exhibitionProposalIds;

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => FundingDistributionProposal) public fundingDistributionProposals;
    mapping(uint256 => CollaborationProject) public collaborationProjects;
    mapping(uint256 => mapping(uint256 => ProjectContribution)) public projectContributions; // projectId => contributionId => Contribution
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(address => bool) public members;
    mapping(address => int256) public memberReputation;

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorum = 50; // Default quorum percentage (50%)

    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event NFTMinted(uint256 tokenId, uint256 proposalId, address minter);
    event GovernanceProposalSubmitted(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event FundingProposalSubmitted(uint256 proposalId, address proposer, address recipient, uint256 amount, string reason);
    event FundingProposalVoted(uint256 proposalId, address voter, bool vote);
    event FundingDistributed(uint256 proposalId, address recipient, uint256 amount);
    event CollaborationProjectStarted(uint256 projectId, string projectName, address initiator);
    event CollaborationProjectJoined(uint256 projectId, address member);
    event ProjectContributionSubmitted(uint256 projectId, uint256 contributionId, address contributor, string description);
    event ProjectContributionVoted(uint256 projectId, uint256 contributionId, address voter, bool vote);
    event CollaborationProjectFinalized(uint256 projectId);
    event ExhibitionProposed(uint256 exhibitionId, string name);
    event ExhibitionVoted(uint256 exhibitionId, address voter, bool vote);
    event ExhibitionStarted(uint256 exhibitionId);
    event MemberUpvoted(address upvoter, address member);
    event MemberDownvoted(address downvoter, address member);

    // --- Modifiers ---

    modifier onlyMember() {
        require(isMember(msg.sender), "Not a member of the DAAC");
        _;
    }

    modifier onlyGovernanceProposalActive(uint256 _proposalId) {
        require(governanceProposals[_proposalId].exists, "Governance proposal does not exist");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed");
        _;
    }

    modifier onlyArtProposalActive(uint256 _proposalId) {
        require(artProposals[_proposalId].exists, "Art proposal does not exist");
        require(!artProposals[_proposalId].approved, "Art proposal already approved/rejected");
        _;
    }

    modifier onlyFundingProposalActive(uint256 _proposalId) {
        require(fundingDistributionProposals[_proposalId].exists, "Funding proposal does not exist");
        require(!fundingDistributionProposals[_proposalId].executed, "Funding proposal already executed");
        _;
    }

    modifier onlyCollaborationProjectActive(uint256 _projectId) {
        require(collaborationProjects[_projectId].exists, "Collaboration project does not exist");
        require(collaborationProjects[_projectId].active, "Collaboration project is not active");
        _;
    }

    modifier onlyExhibitionProposalActive(uint256 _exhibitionId) {
        require(exhibitionProposals[_exhibitionId].exists, "Exhibition proposal does not exist");
        require(!exhibitionProposals[_exhibitionId].approved, "Exhibition proposal already approved/rejected");
        require(!exhibitionProposals[_exhibitionId].started, "Exhibition already started");
        _;
    }


    // --- Constructor ---

    constructor() ERC721("DAAC NFT", "DAAC") {
        _nftTokenIds.increment(); // Start token IDs from 1
        _artProposalIds.increment(); // Start proposal IDs from 1
        _governanceProposalIds.increment(); // Start proposal IDs from 1
        _fundingProposalIds.increment(); // Start proposal IDs from 1
        _collaborationProjectIds.increment(); // Start project IDs from 1
        _exhibitionProposalIds.increment(); // Start exhibition IDs from 1
        _projectContributionIds.increment(); // Start project contribution IDs from 1

        members[msg.sender] = true; // Owner is initial member
        emit MemberAdded(msg.sender);
    }

    // --- 1. NFT Management & Art Proposals ---

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current();
        artProposals[proposalId] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            exists: true
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyMember onlyArtProposalActive(_proposalId) {
        require(artProposals[_proposalId].exists, "Art proposal does not exist");
        require(!artProposals[_proposalId].approved, "Art proposal voting already closed");

        if (_vote) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        _checkArtProposalApproval(_proposalId);
    }

    function _checkArtProposalApproval(uint256 _proposalId) private {
        uint256 totalVotes = artProposals[_proposalId].upvotes + artProposals[_proposalId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (artProposals[_proposalId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= quorum) {
                artProposals[_proposalId].approved = true;
            }
        }
    }

    function mintNFT(uint256 _proposalId) public onlyMember {
        require(artProposals[_proposalId].exists, "Art proposal does not exist");
        require(artProposals[_proposalId].approved, "Art proposal not approved");
        require(!_exists(_nftTokenIds.current()), "NFT already minted for this proposal"); // Prevent double minting

        _nftTokenIds.increment();
        uint256 tokenId = _nftTokenIds.current();
        _safeMint(artProposals[_proposalId].artist, tokenId);
        _setTokenURI(tokenId, artProposals[_proposalId].ipfsHash); // Set IPFS hash as token URI

        emit NFTMinted(tokenId, _proposalId, artProposals[_proposalId].artist);
    }

    function transferNFT(address _to, uint256 _tokenId) public payable virtual override {
        safeTransferFrom(_msgSender(), _to, _tokenId);
    }

    function burnNFT(uint256 _tokenId) public onlyGovernanceProposalActive(1) onlyMember { // Example: Governance proposal ID 1 to control NFT burning
        require(_exists(_tokenId), "NFT does not exist");
        _burn(_tokenId);
    }

    function getNFTMetadata(uint256 _tokenId) public view returns (string memory title, string memory description, string memory ipfsHash) {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 proposalId = _findProposalIdByTokenId(_tokenId); // Assuming 1:1 proposal to NFT for simplicity in this example. In a real scenario, you'd manage this more robustly.
        require(artProposals[proposalId].exists, "Associated art proposal not found");
        return (artProposals[proposalId].title, artProposals[proposalId].description, artProposals[proposalId].ipfsHash);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        require(artProposals[_proposalId].exists, "Art proposal does not exist");
        return artProposals[_proposalId];
    }

    function _findProposalIdByTokenId(uint256 _tokenId) private view returns (uint256) {
        // In a real-world application, you would likely need to store a mapping from tokenId to proposalId
        // For simplicity in this example, assuming tokenId increments with proposalId and starts from 1.
        return _tokenId; // Simplification: tokenId directly corresponds to proposalId for demonstration.
    }

    // --- 2. DAO Governance & Membership ---

    function submitGovernanceProposal(string memory _description, bytes memory _calldata) public onlyMember {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            description: _description,
            calldata: _calldata,
            upvotes: 0,
            downvotes: 0,
            executed: false,
            exists: true
        });
        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) public onlyMember onlyGovernanceProposalActive(_proposalId) {
        if (_vote) {
            governanceProposals[_proposalId].upvotes++;
        } else {
            governanceProposals[_proposalId].downvotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);

        _checkGovernanceProposalExecution(_proposalId);
    }

    function _checkGovernanceProposalExecution(uint256 _proposalId) private {
        uint256 totalVotes = governanceProposals[_proposalId].upvotes + governanceProposals[_proposalId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (governanceProposals[_proposalId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= quorum) {
                governanceProposals[_proposalId].executed = true;
            }
        }
    }

    function executeGovernanceProposal(uint256 _proposalId) public onlyMember onlyGovernanceProposalActive(_proposalId) {
        require(governanceProposals[_proposalId].executed, "Governance proposal not approved or quorum not reached");
        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldata);
        require(success, "Governance proposal execution failed");
        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    function addMember(address _newMember) public onlyGovernanceProposalActive(1) onlyMember { // Example: Governance proposal ID 1 to control membership changes
        members[_newMember] = true;
        emit MemberAdded(_newMember);
    }

    function removeMember(address _member) public onlyGovernanceProposalActive(1) onlyMember { // Example: Governance proposal ID 1 to control membership changes
        require(_member != owner(), "Cannot remove contract owner");
        members[_member] = false;
        emit MemberRemoved(_member);
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account];
    }

    function setVotingPeriod(uint256 _newPeriod) public onlyGovernanceProposalActive(1) onlyMember { // Example: Governance proposal ID 1 to control voting period changes
        votingPeriod = _newPeriod;
    }

    function setQuorum(uint256 _newQuorum) public onlyGovernanceProposalActive(1) onlyMember { // Example: Governance proposal ID 1 to control quorum changes
        require(_newQuorum <= 100, "Quorum cannot exceed 100%");
        quorum = _newQuorum;
    }


    // --- 3. Collective Treasury & Funding ---

    function donateToCollective() public payable {
        // Receive ETH donations
    }

    function proposeFundingDistribution(address _recipient, uint256 _amount, string memory _reason) public onlyMember {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        _fundingProposalIds.increment();
        uint256 proposalId = _fundingProposalIds.current();
        fundingDistributionProposals[proposalId] = FundingDistributionProposal({
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            upvotes: 0,
            downvotes: 0,
            executed: false,
            exists: true
        });
        emit FundingProposalSubmitted(proposalId, msg.sender, _recipient, _amount, _reason);
    }

    function voteOnFundingDistribution(uint256 _proposalId, bool _vote) public onlyMember onlyFundingProposalActive(_proposalId) {
        if (_vote) {
            fundingDistributionProposals[_proposalId].upvotes++;
        } else {
            fundingDistributionProposals[_proposalId].downvotes++;
        }
        emit FundingProposalVoted(_proposalId, msg.sender, _vote);

        _checkFundingProposalExecution(_proposalId);
    }

    function _checkFundingProposalExecution(uint256 _proposalId) private {
        uint256 totalVotes = fundingDistributionProposals[_proposalId].upvotes + fundingDistributionProposals[_proposalId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (fundingDistributionProposals[_proposalId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= quorum) {
                fundingDistributionProposals[_proposalId].executed = true;
            }
        }
    }

    function executeFundingDistribution(uint256 _proposalId) public onlyMember onlyFundingProposalActive(_proposalId) {
        require(fundingDistributionProposals[_proposalId].executed, "Funding proposal not approved or quorum not reached");
        uint256 amount = fundingDistributionProposals[_proposalId].amount;
        address recipient = fundingDistributionProposals[_proposalId].recipient;

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Funding distribution failed");

        fundingDistributionProposals[_proposalId].executed = true;
        emit FundingDistributed(_proposalId, recipient, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- 4. Collaborative Art Projects ---

    function startCollaborationProject(string memory _projectName, string memory _description) public onlyMember {
        _collaborationProjectIds.increment();
        uint256 projectId = _collaborationProjectIds.current();
        collaborationProjects[projectId] = CollaborationProject({
            name: _projectName,
            description: _description,
            initiator: msg.sender,
            active: true,
            exists: true
        });
        emit CollaborationProjectStarted(projectId, _projectName, msg.sender);
    }

    function joinCollaborationProject(uint256 _projectId) public onlyMember onlyCollaborationProjectActive(_projectId) {
        // Basic join function, can be expanded with roles/permissions if needed
        emit CollaborationProjectJoined(_projectId, msg.sender);
    }

    function submitContributionToProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash) public onlyMember onlyCollaborationProjectActive(_projectId) {
        _projectContributionIds.increment();
        uint256 contributionId = _projectContributionIds.current();
        projectContributions[_projectId][contributionId] = ProjectContribution({
            description: _contributionDescription,
            ipfsHash: _ipfsHash,
            contributor: msg.sender,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            exists: true
        });
        emit ProjectContributionSubmitted(_projectId, contributionId, msg.sender, _contributionDescription);
    }

    function voteOnProjectContribution(uint256 _projectId, uint256 _contributionId, bool _vote) public onlyMember onlyCollaborationProjectActive(_projectId) {
        require(projectContributions[_projectId][_contributionId].exists, "Project contribution does not exist");
        require(!projectContributions[_projectId][_contributionId].approved, "Project contribution voting already closed");

        if (_vote) {
            projectContributions[_projectId][_contributionId].upvotes++;
        } else {
            projectContributions[_projectId][_contributionId].downvotes++;
        }
        emit ProjectContributionVoted(_projectId, _contributionId, msg.sender, _vote);

        _checkProjectContributionApproval(_projectId, _contributionId);
    }

    function _checkProjectContributionApproval(uint256 _projectId, uint256 _contributionId) private {
        uint256 totalVotes = projectContributions[_projectId][_contributionId].upvotes + projectContributions[_projectId][_contributionId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (projectContributions[_projectId][_contributionId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= quorum) {
                projectContributions[_projectId][_contributionId].approved = true;
            }
        }
    }

    function finalizeCollaborationProject(uint256 _projectId) public onlyGovernanceProposalActive(1) onlyMember onlyCollaborationProjectActive(_projectId) { // Example: Governance proposal ID 1 to finalize projects
        collaborationProjects[_projectId].active = false;
        emit CollaborationProjectFinalized(_projectId);
        // In a more complex scenario, you could distribute rewards, mint collaborative NFTs, etc. here
    }


    // --- 5. Digital Art Exhibitions ---

    function createExhibition(string memory _exhibitionName, string memory _description, uint256[] memory _nftTokenIds) public onlyMember {
        require(_nftTokenIds.length > 0, "Exhibition must include at least one NFT");
        for (uint256 i = 0; i < _nftTokenIds.length; i++) {
            require(_exists(_nftTokenIds[i]), "Invalid NFT token ID in exhibition");
        }

        _exhibitionProposalIds.increment();
        uint256 exhibitionId = _exhibitionProposalIds.current();
        exhibitionProposals[exhibitionId] = ExhibitionProposal({
            name: _exhibitionName,
            description: _description,
            nftTokenIds: _nftTokenIds,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            started: false,
            exists: true
        });
        emit ExhibitionProposed(exhibitionId, _exhibitionName);
    }

    function voteOnExhibition(uint256 _exhibitionId, bool _vote) public onlyMember onlyExhibitionProposalActive(_exhibitionId) {
        if (_vote) {
            exhibitionProposals[_exhibitionId].upvotes++;
        } else {
            exhibitionProposals[_exhibitionId].downvotes++;
        }
        emit ExhibitionVoted(_exhibitionId, msg.sender, _vote);

        _checkExhibitionApproval(_exhibitionId);
    }

    function _checkExhibitionApproval(uint256 _exhibitionId) private {
        uint256 totalVotes = exhibitionProposals[_exhibitionId].upvotes + exhibitionProposals[_exhibitionId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (exhibitionProposals[_exhibitionId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= quorum) {
                exhibitionProposals[_exhibitionId].approved = true;
            }
        }
    }

    function startExhibition(uint256 _exhibitionId) public onlyGovernanceProposalActive(1) onlyMember onlyExhibitionProposalActive(_exhibitionId) { // Example: Governance proposal ID 1 to start exhibitions
        require(exhibitionProposals[_exhibitionId].approved, "Exhibition proposal not approved");
        exhibitionProposals[_exhibitionId].started = true;
        emit ExhibitionStarted(_exhibitionId);
        // In a real-world scenario, this would trigger off-chain actions to display the exhibition.
    }


    // --- 6. Reputation System ---

    function upvoteMember(address _memberToUpvote) public onlyMember {
        require(isMember(_memberToUpvote), "Cannot upvote non-member");
        require(_memberToUpvote != msg.sender, "Cannot upvote yourself");
        memberReputation[_memberToUpvote]++;
        emit MemberUpvoted(msg.sender, _memberToUpvote);
    }

    function downvoteMember(address _memberToDownvote) public onlyMember {
        require(isMember(_memberToDownvote), "Cannot downvote non-member");
        require(_memberToDownvote != msg.sender, "Cannot downvote yourself");
        memberReputation[_memberToDownvote]--;
        emit MemberDownvoted(msg.sender, _memberToDownvote);
    }

    function getMemberReputation(address _member) public view returns (int256) {
        return memberReputation[_member];
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```