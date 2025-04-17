```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that facilitates
 * artist onboarding, art submission and curation, NFT minting, collaborative art projects,
 * decentralized exhibitions, artist funding, governance, and more.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Artist Onboarding:**
 *    - `joinCollective()`: Allows users to request membership to the collective.
 *    - `approveMembership(address _member)`: (Admin/Curator) Approves a pending membership request.
 *    - `rejectMembership(address _member)`: (Admin/Curator) Rejects a pending membership request.
 *    - `revokeMembership(address _member)`: (Admin/Curator) Revokes an existing membership.
 *    - `isMember(address _user)`: Checks if an address is a member of the collective.
 *
 * **2. Art Submission & Curation:**
 *    - `submitArt(string memory _title, string memory _description, string memory _ipfsHash)`: Members submit their artwork for curation.
 *    - `voteOnArt(uint256 _submissionId, bool _approve)`: Members vote to approve or reject submitted artwork.
 *    - `finalizeArtCuration(uint256 _submissionId)`: (Admin/Curator) Finalizes the curation process after voting period.
 *    - `getArtSubmissionDetails(uint256 _submissionId)`: Retrieves details of a specific art submission.
 *    - `getCurationStatus(uint256 _submissionId)`: Gets the current curation status of a submission.
 *
 * **3. NFT Minting & Management:**
 *    - `mintArtNFT(uint256 _submissionId)`: (Admin/Curator) Mints an NFT for approved artwork.
 *    - `transferArtNFT(uint256 _nftId, address _recipient)`: Allows the collective to transfer ownership of an Art NFT.
 *    - `getArtNFTOwner(uint256 _nftId)`: Retrieves the current owner of a specific Art NFT.
 *    - `getArtNFTMetadataURI(uint256 _nftId)`: Gets the metadata URI for a specific Art NFT.
 *
 * **4. Collaborative Art Projects:**
 *    - `createCollaborativeProject(string memory _projectName, string memory _projectDescription, uint256 _maxCollaborators)`: Members propose a collaborative art project.
 *    - `joinCollaborativeProject(uint256 _projectId)`: Members can join an open collaborative project.
 *    - `submitContributionToProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash)`: Members submit contributions to a project.
 *    - `voteOnProjectContribution(uint256 _projectId, uint256 _contributionId, bool _approve)`: Project collaborators vote on submitted contributions.
 *    - `finalizeCollaborativeProject(uint256 _projectId)`: (Admin/Curator) Finalizes a collaborative project after contributions are curated.
 *
 * **5. Decentralized Exhibitions:**
 *    - `createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime)`: (Admin/Curator) Creates a decentralized art exhibition.
 *    - `addArtToExhibition(uint256 _exhibitionId, uint256 _nftId)`: (Admin/Curator) Adds Art NFTs to an exhibition.
 *    - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _nftId)`: (Admin/Curator) Removes Art NFTs from an exhibition.
 *    - `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition.
 *
 * **6. Artist Funding & Treasury:**
 *    - `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 *    - `proposeArtistGrant(address _artist, uint256 _amount, string memory _grantReason)`: Members can propose grants for artists.
 *    - `voteOnGrantProposal(uint256 _proposalId, bool _approve)`: Members vote on grant proposals.
 *    - `finalizeGrantProposal(uint256 _proposalId)`: (Admin/Curator) Finalizes a grant proposal after voting period.
 *    - `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: (Admin/Curator) Withdraws funds from the treasury.
 *    - `getTreasuryBalance()`: Retrieves the current balance of the collective's treasury.
 *
 * **7. Governance & Administration:**
 *    - `proposeNewRule(string memory _ruleDescription, string memory _ruleDetails)`: Members can propose new rules for the collective.
 *    - `voteOnRuleProposal(uint256 _proposalId, bool _approve)`: Members vote on rule proposals.
 *    - `finalizeRuleProposal(uint256 _proposalId)`: (Admin/Curator) Finalizes a rule proposal after voting period.
 *    - `setCurator(address _newCurator)`: (Admin) Changes the curator address.
 *    - `renounceCuratorship()`: Allows the current curator to renounce their role.
 *    - `getCurator()`: Retrieves the current curator address.
 */
contract DecentralizedAutonomousArtCollective {

    // -------- State Variables --------

    address public curator; // Address of the curator/administrator of the contract
    uint256 public membershipFee = 0.01 ether; // Fee to request membership (can be 0)

    // Membership Management
    mapping(address => bool) public members; // Mapping to track members
    mapping(address => bool) public pendingMemberships; // Mapping to track pending membership requests

    // Art Submission & Curation
    struct ArtSubmission {
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 submissionTime;
        uint256 voteEndTime;
        uint256 upvotes;
        uint256 downvotes;
        bool finalized;
        bool approved;
    }
    mapping(uint256 => ArtSubmission) public artSubmissions;
    uint256 public nextSubmissionId = 1;
    uint256 public curationVoteDuration = 7 days; // Duration for art curation votes
    mapping(uint256 => mapping(address => bool)) public artVotes; // Track votes per submission per member

    // Art NFT Minting & Management
    struct ArtNFT {
        uint256 nftId;
        uint256 submissionId;
        address owner;
        string metadataURI;
    }
    mapping(uint256 => ArtNFT) public artNFTs;
    uint256 public nextNFTId = 1;
    string public baseMetadataURI = "ipfs://daac_art_metadata/"; // Base URI for NFT metadata

    // Collaborative Art Projects
    struct CollaborativeProject {
        uint256 projectId;
        string projectName;
        string projectDescription;
        address creator;
        uint256 maxCollaborators;
        uint256 numCollaborators;
        uint256 projectStartTime;
        uint256 projectEndTime;
        bool finalized;
        mapping(address => bool) collaborators; // Track collaborators in the project
        Contribution[] contributions; // Array to store contributions
    }
    struct Contribution {
        uint256 contributionId;
        address contributor;
        string contributionDescription;
        string ipfsHash;
        uint256 submissionTime;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
    }
    mapping(uint256 => CollaborativeProject) public collaborativeProjects;
    uint256 public nextProjectId = 1;
    uint256 public contributionVoteDuration = 3 days; // Duration for contribution votes

    // Decentralized Exhibitions
    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionName;
        string exhibitionDescription;
        uint256 startTime;
        uint256 endTime;
        mapping(uint256 => bool) displayedArtNFTs; // Track NFTs displayed in the exhibition
    }
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public nextExhibitionId = 1;

    // Artist Funding & Treasury
    uint256 public treasuryBalance; // Contract's ETH balance
    struct GrantProposal {
        uint256 proposalId;
        address artist;
        uint256 amount;
        string grantReason;
        uint256 voteEndTime;
        uint256 upvotes;
        uint256 downvotes;
        bool finalized;
        bool approved;
    }
    mapping(uint256 => GrantProposal) public grantProposals;
    uint256 public nextGrantProposalId = 1;
    uint256 public grantVoteDuration = 5 days; // Duration for grant proposal votes
    mapping(uint256 => mapping(address => bool)) public grantVotes; // Track votes per grant proposal per member

    // Governance & Rules
    struct RuleProposal {
        uint256 proposalId;
        string ruleDescription;
        string ruleDetails;
        uint256 voteEndTime;
        uint256 upvotes;
        uint256 downvotes;
        bool finalized;
        bool approved;
    }
    mapping(uint256 => RuleProposal) public ruleProposals;
    uint256 public nextRuleProposalId = 1;
    uint256 public ruleVoteDuration = 10 days; // Duration for rule proposal votes
    mapping(uint256 => mapping(address => bool)) public ruleVotes; // Track votes per rule proposal per member


    // -------- Events --------

    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed member);
    event MembershipRevoked(address indexed member);

    event ArtSubmitted(uint256 indexed submissionId, address indexed artist, string title);
    event ArtVotedOn(uint256 indexed submissionId, address indexed voter, bool approve);
    event ArtCurationFinalized(uint256 indexed submissionId, bool approved);
    event ArtNFTMinted(uint256 indexed nftId, uint256 indexed submissionId, address indexed owner);
    event ArtNFTTransferred(uint256 indexed nftId, address indexed from, address indexed to);

    event CollaborativeProjectCreated(uint256 indexed projectId, string projectName, address indexed creator);
    event ProjectJoined(uint256 indexed projectId, address indexed collaborator);
    event ContributionSubmitted(uint256 indexed projectId, uint256 indexed contributionId, address indexed contributor);
    event ContributionVotedOn(uint256 indexed projectId, uint256 indexed contributionId, address indexed voter, bool approve);
    event CollaborativeProjectFinalized(uint256 indexed projectId);

    event ExhibitionCreated(uint256 indexed exhibitionId, string exhibitionName);
    event ArtAddedToExhibition(uint256 indexed exhibitionId, uint256 indexed nftId);
    event ArtRemovedFromExhibition(uint256 indexed exhibitionId, uint256 indexed nftId);

    event DonationReceived(address indexed donor, uint256 amount);
    event GrantProposalCreated(uint256 indexed proposalId, address indexed artist, uint256 amount);
    event GrantProposalVotedOn(uint256 indexed proposalId, address indexed voter, bool approve);
    event GrantProposalFinalized(uint256 indexed proposalId, bool approved, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    event RuleProposalCreated(uint256 indexed proposalId, string ruleDescription);
    event RuleProposalVotedOn(uint256 indexed proposalId, address indexed voter, bool approve);
    event RuleProposalFinalized(uint256 indexed proposalId, bool approved);
    event CuratorChanged(address indexed newCurator, address indexed oldCurator);
    event CuratorshipRenounced(address indexed oldCurator);


    // -------- Modifiers --------

    modifier onlyCurator() {
        require(msg.sender == curator, "Only curator can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId < nextSubmissionId, "Invalid submission ID");
        _;
    }

    modifier validNFTId(uint256 _nftId) {
        require(_nftId > 0 && _nftId < nextNFTId, "Invalid NFT ID");
        _;
    }

    modifier validProjectId(uint256 _projectId) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid exhibition ID");
        _;
    }

    modifier validGrantProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextGrantProposalId, "Invalid grant proposal ID");
        _;
    }

    modifier validRuleProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextRuleProposalId, "Invalid rule proposal ID");
        _;
    }

    modifier notFinalizedSubmission(uint256 _submissionId) {
        require(!artSubmissions[_submissionId].finalized, "Submission already finalized");
        _;
    }

    modifier notFinalizedProject(uint256 _projectId) {
        require(!collaborativeProjects[_projectId].finalized, "Project already finalized");
        _;
    }

    modifier notFinalizedGrantProposal(uint256 _proposalId) {
        require(!grantProposals[_proposalId].finalized, "Grant proposal already finalized");
        _;
    }

    modifier notFinalizedRuleProposal(uint256 _proposalId) {
        require(!ruleProposals[_proposalId].finalized, "Rule proposal already finalized");
        _;
    }

    modifier votingPeriodActive(uint256 _endTime) {
        require(block.timestamp < _endTime, "Voting period has ended");
        _;
    }

    modifier votingPeriodEnded(uint256 _endTime) {
        require(block.timestamp >= _endTime, "Voting period is still active");
        _;
    }


    // -------- Constructor --------

    constructor() {
        curator = msg.sender; // Initial curator is the contract deployer
    }


    // -------- 1. Membership & Artist Onboarding --------

    function setMembershipFee(uint256 _fee) external onlyCurator {
        membershipFee = _fee;
    }

    function joinCollective() external payable {
        require(!members[msg.sender], "Already a member");
        require(!pendingMemberships[msg.sender], "Membership request already pending");
        require(msg.value >= membershipFee, "Membership fee required");
        pendingMemberships[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyCurator {
        require(pendingMemberships[_member], "No pending membership request");
        members[_member] = true;
        pendingMemberships[_member] = false;
        emit MembershipApproved(_member);
    }

    function rejectMembership(address _member) external onlyCurator {
        require(pendingMemberships[_member], "No pending membership request");
        pendingMemberships[_member] = false;
        emit MembershipRejected(_member);
    }

    function revokeMembership(address _member) external onlyCurator {
        require(members[_member], "Not a member");
        members[_member] = false;
        emit MembershipRevoked(_member);
    }

    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }


    // -------- 2. Art Submission & Curation --------

    function submitArt(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Invalid submission details");
        artSubmissions[nextSubmissionId] = ArtSubmission({
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            submissionTime: block.timestamp,
            voteEndTime: block.timestamp + curationVoteDuration,
            upvotes: 0,
            downvotes: 0,
            finalized: false,
            approved: false
        });
        emit ArtSubmitted(nextSubmissionId, msg.sender, _title);
        nextSubmissionId++;
    }

    function voteOnArt(uint256 _submissionId, bool _approve) external onlyMember validSubmissionId(_submissionId) notFinalizedSubmission(_submissionId) votingPeriodActive(artSubmissions[_submissionId].voteEndTime) {
        require(!artVotes[_submissionId][msg.sender], "Already voted on this submission");
        artVotes[_submissionId][msg.sender] = true;
        if (_approve) {
            artSubmissions[_submissionId].upvotes++;
        } else {
            artSubmissions[_submissionId].downvotes++;
        }
        emit ArtVotedOn(_submissionId, msg.sender, _approve);
    }

    function finalizeArtCuration(uint256 _submissionId) external onlyCurator validSubmissionId(_submissionId) notFinalizedSubmission(_submissionId) votingPeriodEnded(artSubmissions[_submissionId].voteEndTime) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        submission.finalized = true;
        if (submission.upvotes > submission.downvotes) { // Simple majority for approval
            submission.approved = true;
            emit ArtCurationFinalized(_submissionId, true);
        } else {
            submission.approved = false;
            emit ArtCurationFinalized(_submissionId, false);
        }
    }

    function getArtSubmissionDetails(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtSubmission memory) {
        return artSubmissions[_submissionId];
    }

    function getCurationStatus(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (bool finalized, bool approved, uint256 upvotes, uint256 downvotes, uint256 voteEndTime) {
        ArtSubmission memory submission = artSubmissions[_submissionId];
        return (submission.finalized, submission.approved, submission.upvotes, submission.downvotes, submission.voteEndTime);
    }


    // -------- 3. NFT Minting & Management --------

    function mintArtNFT(uint256 _submissionId) external onlyCurator validSubmissionId(_submissionId) {
        require(artSubmissions[_submissionId].approved && artSubmissions[_submissionId].finalized, "Art not approved or curation not finalized");
        ArtSubmission memory submission = artSubmissions[_submissionId];
        string memory metadataURI = string(abi.encodePacked(baseMetadataURI, Strings.toString(_submissionId), ".json")); // Construct metadata URI (example)

        artNFTs[nextNFTId] = ArtNFT({
            nftId: nextNFTId,
            submissionId: _submissionId,
            owner: submission.artist, // Artist is the initial owner
            metadataURI: metadataURI
        });
        emit ArtNFTMinted(nextNFTId, _submissionId, submission.artist);
        nextNFTId++;
    }

    function transferArtNFT(uint256 _nftId, address _recipient) external onlyCurator validNFTId(_nftId) {
        require(_recipient != address(0), "Invalid recipient address");
        ArtNFT storage nft = artNFTs[_nftId];
        address currentOwner = nft.owner;
        nft.owner = _recipient;
        emit ArtNFTTransferred(_nftId, currentOwner, _recipient);
    }

    function getArtNFTOwner(uint256 _nftId) external view validNFTId(_nftId) returns (address) {
        return artNFTs[_nftId].owner;
    }

    function getArtNFTMetadataURI(uint256 _nftId) external view validNFTId(_nftId) returns (string memory) {
        return artNFTs[_nftId].metadataURI;
    }


    // -------- 4. Collaborative Art Projects --------

    function createCollaborativeProject(string memory _projectName, string memory _projectDescription, uint256 _maxCollaborators) external onlyMember {
        require(bytes(_projectName).length > 0 && bytes(_projectDescription).length > 0 && _maxCollaborators > 0, "Invalid project details");
        collaborativeProjects[nextProjectId] = CollaborativeProject({
            projectId: nextProjectId,
            projectName: _projectName,
            projectDescription: _projectDescription,
            creator: msg.sender,
            maxCollaborators: _maxCollaborators,
            numCollaborators: 1, // Creator is the first collaborator
            projectStartTime: block.timestamp,
            projectEndTime: 0, // Set when finalized
            finalized: false,
            collaborators: mapping(address => bool)(msg.sender), // Add creator as collaborator
            contributions: new Contribution[](0)
        });
        emit CollaborativeProjectCreated(nextProjectId, _projectName, msg.sender);
        nextProjectId++;
    }

    function joinCollaborativeProject(uint256 _projectId) external onlyMember validProjectId(_projectId) notFinalizedProject(_projectId) {
        CollaborativeProject storage project = collaborativeProjects[_projectId];
        require(!project.collaborators[msg.sender], "Already a collaborator");
        require(project.numCollaborators < project.maxCollaborators, "Project is full");
        project.collaborators[msg.sender] = true;
        project.numCollaborators++;
        emit ProjectJoined(_projectId, msg.sender);
    }

    function submitContributionToProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash) external onlyMember validProjectId(_projectId) notFinalizedProject(_projectId) {
        CollaborativeProject storage project = collaborativeProjects[_projectId];
        require(project.collaborators[msg.sender], "Not a collaborator in this project");
        require(bytes(_contributionDescription).length > 0 && bytes(_ipfsHash).length > 0, "Invalid contribution details");

        Contribution memory newContribution = Contribution({
            contributionId: project.contributions.length, // Index as contribution ID
            contributor: msg.sender,
            contributionDescription: _contributionDescription,
            ipfsHash: _ipfsHash,
            submissionTime: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            approved: false
        });
        project.contributions.push(newContribution);
        emit ContributionSubmitted(_projectId, newContribution.contributionId, msg.sender);
    }

    function voteOnProjectContribution(uint256 _projectId, uint256 _contributionId, bool _approve) external onlyMember validProjectId(_projectId) notFinalizedProject(_projectId) {
        CollaborativeProject storage project = collaborativeProjects[_projectId];
        require(project.collaborators[msg.sender], "Not a collaborator in this project");
        require(_contributionId < project.contributions.length, "Invalid contribution ID");
        Contribution storage contribution = project.contributions[_contributionId];
        // Simple voting, collaborators vote on contributions
        // In a real-world scenario, more sophisticated voting might be needed, preventing self-voting etc.
        if (_approve) {
            contribution.upvotes++;
        } else {
            contribution.downvotes++;
        }
        emit ContributionVotedOn(_projectId, _contributionId, msg.sender, _approve);
    }

    function finalizeCollaborativeProject(uint256 _projectId) external onlyCurator validProjectId(_projectId) notFinalizedProject(_projectId) {
        CollaborativeProject storage project = collaborativeProjects[_projectId];
        project.finalized = true;
        project.projectEndTime = block.timestamp;
        // Logic to determine which contributions are considered "approved" based on votes can be added here.
        // For example, contributions with more upvotes than downvotes could be marked as approved.
        for (uint256 i = 0; i < project.contributions.length; i++) {
            if (project.contributions[i].upvotes > project.contributions[i].downvotes) {
                project.contributions[i].approved = true;
            }
        }
        emit CollaborativeProjectFinalized(_projectId);
    }


    // -------- 5. Decentralized Exhibitions --------

    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime) external onlyCurator {
        require(bytes(_exhibitionName).length > 0 && bytes(_exhibitionDescription).length > 0 && _startTime < _endTime, "Invalid exhibition details");
        exhibitions[nextExhibitionId] = Exhibition({
            exhibitionId: nextExhibitionId,
            exhibitionName: _exhibitionName,
            exhibitionDescription: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            displayedArtNFTs: mapping(uint256 => bool)()
        });
        emit ExhibitionCreated(nextExhibitionId, _exhibitionName);
        nextExhibitionId++;
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _nftId) external onlyCurator validExhibitionId(_exhibitionId) validNFTId(_nftId) {
        require(artNFTs[_nftId].owner != address(0), "NFT does not exist"); // Basic check if NFT exists in our system
        exhibitions[_exhibitionId].displayedArtNFTs[_nftId] = true;
        emit ArtAddedToExhibition(_exhibitionId, _nftId);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _nftId) external onlyCurator validExhibitionId(_exhibitionId) validNFTId(_nftId) {
        delete exhibitions[_exhibitionId].displayedArtNFTs[_nftId];
        emit ArtRemovedFromExhibition(_exhibitionId, _nftId);
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }


    // -------- 6. Artist Funding & Treasury --------

    function donateToCollective() external payable {
        treasuryBalance += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function proposeArtistGrant(address _artist, uint256 _amount, string memory _grantReason) external onlyMember {
        require(_artist != address(0) && _amount > 0 && bytes(_grantReason).length > 0, "Invalid grant proposal details");
        require(treasuryBalance >= _amount, "Insufficient funds in treasury for grant");
        grantProposals[nextGrantProposalId] = GrantProposal({
            proposalId: nextGrantProposalId,
            artist: _artist,
            amount: _amount,
            grantReason: _grantReason,
            voteEndTime: block.timestamp + grantVoteDuration,
            upvotes: 0,
            downvotes: 0,
            finalized: false,
            approved: false
        });
        emit GrantProposalCreated(nextGrantProposalId, _artist, _amount);
        nextGrantProposalId++;
    }

    function voteOnGrantProposal(uint256 _proposalId, bool _approve) external onlyMember validGrantProposalId(_proposalId) notFinalizedGrantProposal(_proposalId) votingPeriodActive(grantProposals[_proposalId].voteEndTime) {
        require(!grantVotes[_proposalId][msg.sender], "Already voted on this grant proposal");
        grantVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            grantProposals[_proposalId].upvotes++;
        } else {
            grantProposals[_proposalId].downvotes++;
        }
        emit GrantProposalVotedOn(_proposalId, msg.sender, _approve);
    }

    function finalizeGrantProposal(uint256 _proposalId) external onlyCurator validGrantProposalId(_proposalId) notFinalizedGrantProposal(_proposalId) votingPeriodEnded(grantProposals[_proposalId].voteEndTime) {
        GrantProposal storage proposal = grantProposals[_proposalId];
        proposal.finalized = true;
        if (proposal.upvotes > proposal.downvotes) { // Simple majority for approval
            proposal.approved = true;
            payable(proposal.artist).transfer(proposal.amount); // Transfer ETH to artist
            treasuryBalance -= proposal.amount;
            emit GrantProposalFinalized(_proposalId, true, proposal.amount);
        } else {
            proposal.approved = false;
            emit GrantProposalFinalized(_proposalId, false, 0);
        }
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyCurator {
        require(_recipient != address(0) && _amount > 0 && treasuryBalance >= _amount, "Invalid withdrawal request");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }


    // -------- 7. Governance & Administration --------

    function proposeNewRule(string memory _ruleDescription, string memory _ruleDetails) external onlyMember {
        require(bytes(_ruleDescription).length > 0 && bytes(_ruleDetails).length > 0, "Invalid rule proposal details");
        ruleProposals[nextRuleProposalId] = RuleProposal({
            proposalId: nextRuleProposalId,
            ruleDescription: _ruleDescription,
            ruleDetails: _ruleDetails,
            voteEndTime: block.timestamp + ruleVoteDuration,
            upvotes: 0,
            downvotes: 0,
            finalized: false,
            approved: false
        });
        emit RuleProposalCreated(nextRuleProposalId, _ruleDescription);
        nextRuleProposalId++;
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _approve) external onlyMember validRuleProposalId(_proposalId) notFinalizedRuleProposal(_proposalId) votingPeriodActive(ruleProposals[_proposalId].voteEndTime) {
        require(!ruleVotes[_proposalId][msg.sender], "Already voted on this rule proposal");
        ruleVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            ruleProposals[_proposalId].upvotes++;
        } else {
            ruleProposals[_proposalId].downvotes++;
        }
        emit RuleProposalVotedOn(_proposalId, msg.sender, _approve);
    }

    function finalizeRuleProposal(uint256 _proposalId) external onlyCurator validRuleProposalId(_proposalId) notFinalizedRuleProposal(_proposalId) votingPeriodEnded(ruleProposals[_proposalId].voteEndTime) {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        proposal.finalized = true;
        if (proposal.upvotes > proposal.downvotes) { // Simple majority for approval
            proposal.approved = true;
            emit RuleProposalFinalized(_proposalId, true);
            // Logic to implement the new rule based on `proposal.ruleDetails` would be added here
            // This could involve modifying contract parameters, logic, etc. (complex and depends on the rule).
            // For simplicity, this example just marks the proposal as approved.
        } else {
            proposal.approved = false;
            emit RuleProposalFinalized(_proposalId, false);
        }
    }

    function setCurator(address _newCurator) external onlyCurator {
        require(_newCurator != address(0), "Invalid new curator address");
        address oldCurator = curator;
        curator = _newCurator;
        emit CuratorChanged(_newCurator, oldCurator);
    }

    function renounceCuratorship() external onlyCurator {
        address oldCurator = curator;
        curator = address(0); // Set curator to address(0) - no curator, or could set to a DAO address in a real scenario
        emit CuratorshipRenounced(oldCurator);
    }

    function getCurator() external view returns (address) {
        return curator;
    }
}

// --- Helper library for string conversion ---
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Assembly implementation for gas efficiency
        assembly {
            // Get the pointer to memory for temporary space
            let ptr := mload(0x40)

            // Store the value at the memory pointer
            mstore(ptr, value)

            // Convert the value to a string representation
            let stringPtr := add(ptr, 32) // Offset by 32 bytes for the uint256 value
            let length := 0

            // Count digits and store in reverse order
            loop:
                let rem := mod(value, 10)
                value := div(value, 10)

                mstore(add(stringPtr, length), add(0x30, rem)) // Convert digit to ASCII character
                length := add(length, 1)

                jumpi(loop, value) // Continue if value is not zero

            // Allocate memory for the string
            let resultPtr := mload(0x40)
            mstore(0x40, add(resultPtr, add(length, 32))) // Update free memory pointer
            mstore(resultPtr, length) // Store string length

            // Reverse the string in memory
            reverseLoop:
                let i := 0
                let j := sub(length, 1)
                loopCondition:
                    jumpi(reverseLoopEnd, iszero(lt(i, j)))

                    let temp := mload(add(stringPtr, i))
                    mstore(add(stringPtr, i), mload(add(stringPtr, j)))
                    mstore(add(stringPtr, j), temp)

                    i := add(i, 1)
                    j := sub(j, 1)
                    jump(loopCondition)
                reverseLoopEnd:

            // Copy the string to the allocated memory
            let stringDataPtr := add(resultPtr, 32)
            calldatacopy(stringDataPtr, stringPtr, length)

            // Return the string
            mstore(0, resultPtr)
            return(0, add(length, 32))
        }
    }
}
```