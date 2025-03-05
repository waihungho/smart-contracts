```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective that allows artists to submit artwork proposals,
 *      community members to vote on proposals, mint approved artworks as NFTs, participate in collaborative
 *      art projects, and govern the collective through a DAO-like structure.
 *
 * **Outline and Function Summary:**
 *
 * **1. Initialization & Configuration:**
 *    - `constructor(string _collectiveName, address _admin)`: Initializes the contract with collective name and admin address.
 *    - `setVotingDuration(uint256 _duration)`: Allows admin to set the voting duration for proposals.
 *    - `setProposalDeposit(uint256 _deposit)`: Allows admin to set the deposit required to submit an art proposal.
 *    - `setCuratorFeePercentage(uint256 _percentage)`: Allows admin to set the curator fee percentage for NFT sales.
 *    - `setMaxCollaborators(uint256 _maxCollaborators)`: Allows admin to set the maximum number of collaborators for projects.
 *
 * **2. Art Proposal Submission & Curation:**
 *    - `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Artists submit art proposals with title, description, and IPFS hash (requires deposit).
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Community members vote on art proposals (only once per proposal).
 *    - `finalizeArtProposal(uint256 _proposalId)`: Admin finalizes an art proposal after voting period (mints NFT if approved).
 *    - `rejectArtProposal(uint256 _proposalId)`: Admin rejects an art proposal manually (refunds deposit).
 *    - `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *    - `getArtProposalStatus(uint256 _proposalId)`: Retrieves the status of a specific art proposal (Pending, Approved, Rejected).
 *
 * **3. Collaborative Art Projects:**
 *    - `createCollaborationProject(string memory _projectName, string memory _projectDescription, uint256 _maxParticipants)`: Initiates a collaborative art project (only admin).
 *    - `joinCollaborationProject(uint256 _projectId)`: Allows community members to join an open collaborative art project.
 *    - `submitProjectContribution(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash)`: Participants submit their contributions to a project.
 *    - `voteOnContribution(uint256 _projectId, uint256 _contributionId, bool _vote)`: Project participants vote on submitted contributions.
 *    - `finalizeCollaborationProject(uint256 _projectId)`: Admin finalizes a collaborative project after contribution voting.
 *    - `getCollaborationProjectDetails(uint256 _projectId)`: Retrieves details of a collaborative art project.
 *    - `getContributionDetails(uint256 _projectId, uint256 _contributionId)`: Retrieves details of a specific contribution to a project.
 *
 * **4. NFT Management & Sales:**
 *    - `purchaseNFT(uint256 _tokenId)`: Allows users to purchase minted art NFTs.
 *    - `setNFTBaseURI(string memory _baseURI)`: Allows admin to set the base URI for NFT metadata.
 *    - `getNFTMetadataURI(uint256 _tokenId)`: Retrieves the metadata URI for a specific NFT.
 *
 * **5. Governance & Community Features:**
 *    - `proposeGovernanceChange(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata)`: Allows community to propose governance changes via function calls (DAO-like).
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Community members vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Admin executes a governance proposal after successful voting.
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 *
 * **6. Utility & Admin Functions:**
 *    - `withdrawContractBalance(address payable _recipient)`: Allows admin to withdraw contract balance (e.g., curator fees).
 *    - `pauseContract()`: Allows admin to pause the contract (emergency stop).
 *    - `unpauseContract()`: Allows admin to unpause the contract.
 *    - `getContractName()`: Returns the name of the art collective.
 */
contract DecentralizedAutonomousArtCollective {
    string public collectiveName;
    address public admin;
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public proposalDeposit = 0.1 ether; // Default proposal deposit
    uint256 public curatorFeePercentage = 10; // Default curator fee percentage (10%)
    uint256 public maxCollaborators = 10; // Default max collaborators for projects
    string public nftBaseURI;

    uint256 public artProposalCounter = 0;
    uint256 public collaborationProjectCounter = 0;
    uint256 public governanceProposalCounter = 0;

    enum ProposalStatus { Pending, Approved, Rejected }

    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 depositAmount;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        mapping(address => bool) voters; // Track who voted
    }
    mapping(uint256 => ArtProposal) public artProposals;

    struct CollaborationProject {
        uint256 id;
        string name;
        string description;
        address initiator;
        uint256 maxParticipants;
        uint256 participantCount;
        mapping(address => bool) participants;
        uint256 contributionCounter;
        mapping(uint256 => Contribution) public contributions;
        bool isActive;
    }
    mapping(uint256 => CollaborationProject) public collaborationProjects;

    struct Contribution {
        uint256 id;
        address contributor;
        string description;
        string ipfsHash;
        uint256 yesVotes;
        uint256 noVotes;
        bool isApproved;
        mapping(address => bool) voters; // Track who voted
    }

    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        bytes calldataData; // Function call data
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voters; // Track who voted
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // NFT related
    uint256 public nftSupply = 0;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => uint256) public nftArtProposalId; // Link NFT to Art Proposal
    mapping(uint256 => bool) public nftExists;

    bool public paused = false;

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, ProposalStatus status);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event ArtProposalRejected(uint256 proposalId, address artist);

    event CollaborationProjectCreated(uint256 projectId, string projectName, address initiator);
    event CollaborationProjectJoined(uint256 projectId, address participant);
    event ContributionSubmitted(uint256 projectId, uint256 contributionId, address contributor);
    event ContributionVoted(uint256 projectId, uint256 contributionId, address voter, bool vote);
    event CollaborationProjectFinalized(uint256 projectId);

    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event CuratorFeePercentageChanged(uint256 newPercentage, address admin);
    event ProposalDepositChanged(uint256 newDeposit, address admin);
    event VotingDurationChanged(uint256 newDuration, address admin);
    event MaxCollaboratorsChanged(uint256 newMaxCollaborators, address admin);
    event NFTBaseURISet(string baseURI, address admin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    constructor(string memory _collectiveName, address _admin) {
        collectiveName = _collectiveName;
        admin = _admin;
    }

    // ------------------------------------------------------------
    // 1. Initialization & Configuration
    // ------------------------------------------------------------

    function setVotingDuration(uint256 _duration) public onlyAdmin {
        votingDuration = _duration;
        emit VotingDurationChanged(_duration, admin);
    }

    function setProposalDeposit(uint256 _deposit) public onlyAdmin {
        proposalDeposit = _deposit;
        emit ProposalDepositChanged(_deposit, admin);
    }

    function setCuratorFeePercentage(uint256 _percentage) public onlyAdmin {
        require(_percentage <= 100, "Curator fee percentage must be <= 100");
        curatorFeePercentage = _percentage;
        emit CuratorFeePercentageChanged(_percentage, admin);
    }

    function setMaxCollaborators(uint256 _maxCollaborators) public onlyAdmin {
        maxCollaborators = _maxCollaborators;
        emit MaxCollaboratorsChanged(_maxCollaborators, admin);
    }

    // ------------------------------------------------------------
    // 2. Art Proposal Submission & Curation
    // ------------------------------------------------------------

    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash
    ) public payable whenNotPaused {
        require(msg.value >= proposalDeposit, "Insufficient proposal deposit");
        artProposalCounter++;
        ArtProposal storage proposal = artProposals[artProposalCounter];
        proposal.id = artProposalCounter;
        proposal.title = _title;
        proposal.description = _description;
        proposal.ipfsHash = _ipfsHash;
        proposal.artist = msg.sender;
        proposal.depositAmount = msg.value;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + votingDuration;
        proposal.status = ProposalStatus.Pending;

        emit ArtProposalSubmitted(artProposalCounter, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal not in pending status");
        require(block.timestamp >= artProposals[_proposalId].voteStartTime && block.timestamp <= artProposals[_proposalId].voteEndTime, "Voting period is over");
        require(!artProposals[_proposalId].voters[msg.sender], "Already voted on this proposal");

        artProposals[_proposalId].voters[msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeArtProposal(uint256 _proposalId) public onlyAdmin whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal not in pending status");
        require(block.timestamp > artProposals[_proposalId].voteEndTime, "Voting period is not over yet");

        if (artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            _mintArtNFT(_proposalId, artProposals[_proposalId].artist);
            artProposals[_proposalId].status = ProposalStatus.Approved;
            // Refund deposit if approved (optional, can be kept for collective)
            payable(artProposals[_proposalId].artist).transfer(artProposals[_proposalId].depositAmount);
        } else {
            artProposals[_proposalId].status = ProposalStatus.Rejected;
            // Refund deposit if rejected
            payable(artProposals[_proposalId].artist).transfer(artProposals[_proposalId].depositAmount);
        }
        emit ArtProposalFinalized(_proposalId, artProposals[_proposalId].status);
    }

    function rejectArtProposal(uint256 _proposalId) public onlyAdmin whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal not in pending status");
        artProposals[_proposalId].status = ProposalStatus.Rejected;
        // Refund deposit on manual reject
        payable(artProposals[_proposalId].artist).transfer(artProposals[_proposalId].depositAmount);
        emit ArtProposalRejected(_proposalId, artProposals[_proposalId].artist);
        emit ArtProposalFinalized(_proposalId, ProposalStatus.Rejected);
    }

    function getArtProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getArtProposalStatus(uint256 _proposalId) public view returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    // ------------------------------------------------------------
    // 3. Collaborative Art Projects
    // ------------------------------------------------------------

    function createCollaborationProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _maxParticipants
    ) public onlyAdmin whenNotPaused {
        collaborationProjectCounter++;
        CollaborationProject storage project = collaborationProjects[collaborationProjectCounter];
        project.id = collaborationProjectCounter;
        project.name = _projectName;
        project.description = _projectDescription;
        project.initiator = msg.sender;
        project.maxParticipants = _maxParticipants;
        project.isActive = true;

        emit CollaborationProjectCreated(collaborationProjectCounter, _projectName, msg.sender);
    }

    function joinCollaborationProject(uint256 _projectId) public whenNotPaused {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(collaborationProjects[_projectId].participantCount < collaborationProjects[_projectId].maxParticipants, "Project is full");
        require(!collaborationProjects[_projectId].participants[msg.sender], "Already joined this project");

        collaborationProjects[_projectId].participants[msg.sender] = true;
        collaborationProjects[_projectId].participantCount++;
        emit CollaborationProjectJoined(_projectId, msg.sender);
    }

    function submitProjectContribution(
        uint256 _projectId,
        string memory _contributionDescription,
        string memory _ipfsHash
    ) public whenNotPaused {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(collaborationProjects[_projectId].participants[msg.sender], "Not a participant of this project");

        CollaborationProject storage project = collaborationProjects[_projectId];
        project.contributionCounter++;
        Contribution storage contribution = project.contributions[project.contributionCounter];
        contribution.id = project.contributionCounter;
        contribution.contributor = msg.sender;
        contribution.description = _contributionDescription;
        contribution.ipfsHash = _ipfsHash;

        emit ContributionSubmitted(_projectId, project.contributionCounter, msg.sender);
    }

    function voteOnContribution(uint256 _projectId, uint256 _contributionId, bool _vote) public whenNotPaused {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(collaborationProjects[_projectId].participants[msg.sender], "Only participants can vote");
        require(!collaborationProjects[_projectId].contributions[_contributionId].voters[msg.sender], "Already voted on this contribution");

        collaborationProjects[_projectId].contributions[_contributionId].voters[msg.sender] = true;
        if (_vote) {
            collaborationProjects[_projectId].contributions[_contributionId].yesVotes++;
        } else {
            collaborationProjects[_projectId].contributions[_contributionId].noVotes++;
        }
        emit ContributionVoted(_projectId, _contributionId, msg.sender, _vote);
    }

    function finalizeCollaborationProject(uint256 _projectId) public onlyAdmin whenNotPaused {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        collaborationProjects[_projectId].isActive = false;
        // Logic to handle approved contributions, rewards, etc. can be added here
        // For example, select top voted contributions, mint NFTs representing the collective work, etc.
        emit CollaborationProjectFinalized(_projectId);
    }

    function getCollaborationProjectDetails(uint256 _projectId) public view returns (CollaborationProject memory) {
        return collaborationProjects[_projectId];
    }

    function getContributionDetails(uint256 _projectId, uint256 _contributionId) public view returns (Contribution memory) {
        return collaborationProjects[_projectId].contributions[_contributionId];
    }

    // ------------------------------------------------------------
    // 4. NFT Management & Sales
    // ------------------------------------------------------------

    function purchaseNFT(uint256 _tokenId) public payable whenNotPaused {
        require(nftExists[_tokenId], "NFT does not exist");
        require(nftOwner[_tokenId] == address(this), "NFT is not for sale by collective");

        uint256 artProposalId = nftArtProposalId[_tokenId];
        uint256 price = getNFTPrice(_tokenId); // Example: price could be dynamic or fixed per proposal
        require(msg.value >= price, "Insufficient payment for NFT");

        // Transfer curator fee to admin
        uint256 curatorFee = (price * curatorFeePercentage) / 100;
        payable(admin).transfer(curatorFee);

        // Transfer remaining amount to artist (or collective treasury in more advanced versions)
        uint256 artistShare = price - curatorFee;
        payable(artProposals[artProposalId].artist).transfer(artistShare);

        nftOwner[_tokenId] = msg.sender;
        // Consider adding events for NFT sales, etc.
    }

    function setNFTBaseURI(string memory _baseURI) public onlyAdmin {
        nftBaseURI = _baseURI;
        emit NFTBaseURISet(_baseURI, admin);
    }

    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(nftExists[_tokenId], "NFT does not exist");
        return string(abi.encodePacked(nftBaseURI, Strings.toString(_tokenId))); // Example: baseURI/tokenId
    }

    // Internal function to mint NFT
    function _mintArtNFT(uint256 _proposalId, address _artist) internal {
        nftSupply++;
        uint256 tokenId = nftSupply;
        nftOwner[tokenId] = address(this); // Initially owned by contract (collective) until purchased
        nftArtProposalId[tokenId] = _proposalId;
        nftExists[tokenId] = true; // Mark NFT as existing
        emit ArtNFTMinted(tokenId, _proposalId, _artist);
    }

    // Example function to get NFT price (can be customized)
    function getNFTPrice(uint256 _tokenId) public view returns (uint256) {
        // Example: Fixed price for all NFTs for simplicity
        return 0.5 ether;
        // In a real application, price could be dynamic, based on proposal, etc.
    }


    // ------------------------------------------------------------
    // 5. Governance & Community Features
    // ------------------------------------------------------------

    function proposeGovernanceChange(
        string memory _proposalTitle,
        string memory _proposalDescription,
        bytes memory _calldata
    ) public whenNotPaused {
        governanceProposalCounter++;
        GovernanceProposal storage proposal = governanceProposals[governanceProposalCounter];
        proposal.id = governanceProposalCounter;
        proposal.title = _proposalTitle;
        proposal.description = _proposalDescription;
        proposal.proposer = msg.sender;
        proposal.calldataData = _calldata;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + votingDuration;

        emit GovernanceProposalCreated(governanceProposalCounter, _proposalTitle, msg.sender);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(governanceProposals[_proposalId].voteStartTime <= block.timestamp && block.timestamp <= governanceProposals[_proposalId].voteEndTime, "Voting period is over");
        require(!governanceProposals[_proposalId].voters[msg.sender], "Already voted on this proposal");

        governanceProposals[_proposalId].voters[msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceProposal(uint256 _proposalId) public onlyAdmin whenNotPaused {
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp > governanceProposals[_proposalId].voteEndTime, "Voting period is not over");
        require(governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes, "Governance proposal not approved");

        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataData);
        require(success, "Governance proposal execution failed");
        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    function getGovernanceProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }


    // ------------------------------------------------------------
    // 6. Utility & Admin Functions
    // ------------------------------------------------------------

    function withdrawContractBalance(address payable _recipient) public onlyAdmin {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    function getContractName() public view returns (string memory) {
        return collectiveName;
    }
}

// Helper library for converting uint to string
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```