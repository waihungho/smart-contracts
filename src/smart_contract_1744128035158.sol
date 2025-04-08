```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, incorporating advanced concepts like generative art seeds,
 *      dynamic reputation, collaborative projects, and decentralized governance.
 *
 * **Outline and Function Summary:**
 *
 * **1. Artist Management:**
 *    - `addArtist(address _artist, string _artistName)`: Allows admin to add new artists to the collective.
 *    - `removeArtist(address _artist)`: Allows admin to remove an artist from the collective.
 *    - `getArtistName(address _artist)`: Retrieves the name of an artist.
 *    - `isArtist(address _artist)`: Checks if an address is a registered artist.
 *
 * **2. Generative Art Seed Management:**
 *    - `requestNewSeed()`: Artists can request a new unique seed for generative art creation.
 *    - `getLastSeedRequestTime(address _artist)`: Get the timestamp of the last seed request by an artist (rate limiting).
 *    - `getCurrentSeed(uint256 _seedId)`: Retrieves a specific generative art seed.
 *    - `getTotalSeedsRequested()`: Returns the total number of seeds requested.
 *
 * **3. Art Proposal and Submission:**
 *    - `submitArtProposal(string _title, string _description, string _ipfsHash, uint256 _seedId)`: Artists submit art proposals with details and associated generative seed.
 *    - `approveArtProposal(uint256 _proposalId)`: Admin/Curators can approve art proposals.
 *    - `rejectArtProposal(uint256 _proposalId, string _reason)`: Admin/Curators can reject art proposals with a reason.
 *    - `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: Gets the status of an art proposal (Pending, Approved, Rejected).
 *
 * **4. Collaborative Art Projects:**
 *    - `createCollaborativeProject(string _projectName, string _projectDescription)`: Artists can initiate collaborative art projects.
 *    - `joinCollaborativeProject(uint256 _projectId)`: Artists can join existing collaborative projects.
 *    - `leaveCollaborativeProject(uint256 _projectId)`: Artists can leave collaborative projects they joined.
 *    - `getProjectDetails(uint256 _projectId)`: Retrieves details of a collaborative project.
 *    - `isProjectMember(uint256 _projectId, address _artist)`: Checks if an artist is a member of a project.
 *    - `contributeToProject(uint256 _projectId, string _contributionDescription, string _ipfsHash)`: Project members can submit contributions to a project.
 *    - `getProjectContributions(uint256 _projectId)`: Retrieves all contributions for a specific project.
 *
 * **5. Reputation and Rewards (Basic Example):**
 *    - `upvoteContribution(uint256 _projectId, uint256 _contributionId)`: Artists can upvote contributions within collaborative projects.
 *    - `getContributionUpvotes(uint256 _projectId, uint256 _contributionId)`: Retrieves the upvote count for a contribution.
 *    - `distributeProjectRewards(uint256 _projectId)`: (Simplified) Admin function to distribute rewards to project members based on contribution upvotes (basic example, can be expanded).
 *
 * **6. Decentralized Governance (Simple Example):**
 *    - `proposeGovernanceChange(string _proposalTitle, string _proposalDescription, string _ipfsHash)`: Artists can propose governance changes.
 *    - `voteOnGovernanceChange(uint256 _proposalId, bool _vote)`: Artists can vote on governance change proposals.
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 *    - `getGovernanceProposalStatus(uint256 _proposalId)`: Gets the status of a governance proposal (Pending, Approved, Rejected).
 *    - `executeGovernanceChange(uint256 _proposalId)`: Admin can execute approved governance changes (example, can be expanded).
 *
 * **7. Utility and Admin Functions:**
 *    - `setAdmin(address _newAdmin)`: Allows current admin to set a new admin.
 *    - `getAdmin()`: Returns the current admin address.
 *    - `pauseContract()`: Admin function to pause certain functionalities of the contract (e.g., submissions, minting).
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `isContractPaused()`: Checks if the contract is currently paused.
 */
contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    address public admin;
    mapping(address => string) public artistNames;
    mapping(address => bool) public isRegisteredArtist;
    address[] public artistList;

    uint256 public seedCounter;
    mapping(uint256 => uint256) public generativeSeeds; // seedId => seedValue
    mapping(address => uint256) public lastSeedRequestTime;
    uint256 public seedRequestCooldown = 1 hours; // Cooldown period for seed requests

    uint256 public artProposalCounter;
    struct ArtProposal {
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 seedId;
        ProposalStatus status;
        string rejectionReason;
        uint256 submissionTimestamp;
    }
    enum ProposalStatus { Pending, Approved, Rejected }
    mapping(uint256 => ArtProposal) public artProposals;

    uint256 public collaborativeProjectCounter;
    struct CollaborativeProject {
        string projectName;
        string projectDescription;
        address creator;
        address[] members;
        uint256 creationTimestamp;
    }
    mapping(uint256 => CollaborativeProject) public projects;
    mapping(uint256 => mapping(address => bool)) public projectMembers; // projectId => artist => isMember

    uint256 public contributionCounter;
    struct Contribution {
        address artist;
        uint256 projectId;
        string description;
        string ipfsHash;
        uint256 upvotes;
        uint256 timestamp;
    }
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => mapping(uint256 => bool)) public contributionUpvotedByArtist; // projectId => contributionId => artist => hasUpvoted

    uint256 public governanceProposalCounter;
    struct GovernanceProposal {
        string title;
        string description;
        string ipfsHash;
        ProposalStatus status;
        mapping(address => bool) votes; // artist => vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        uint256 submissionTimestamp;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    bool public paused;

    // -------- Events --------

    event ArtistAdded(address artist, string artistName);
    event ArtistRemoved(address artist);
    event SeedRequested(address artist, uint256 seedId, uint256 seedValue);
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId, string reason);
    event CollaborativeProjectCreated(uint256 projectId, string projectName, address creator);
    event ProjectJoined(uint256 projectId, address artist);
    event ProjectLeft(uint256 projectId, address artist);
    event ContributionSubmitted(uint256 contributionId, uint256 projectId, address artist);
    event ContributionUpvoted(uint256 projectId, uint256 contributionId, address artist);
    event GovernanceProposalCreated(uint256 proposalId, string title);
    event GovernanceVoteCasted(uint256 proposalId, address artist, bool vote);
    event GovernanceProposalApproved(uint256 proposalId);
    event GovernanceProposalRejected(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can perform this action");
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

    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
    }

    // -------- 1. Artist Management --------

    function addArtist(address _artist, string memory _artistName) external onlyAdmin {
        require(!isRegisteredArtist[_artist], "Artist is already registered");
        isRegisteredArtist[_artist] = true;
        artistNames[_artist] = _artistName;
        artistList.push(_artist);
        emit ArtistAdded(_artist, _artistName);
    }

    function removeArtist(address _artist) external onlyAdmin {
        require(isRegisteredArtist[_artist], "Artist is not registered");
        isRegisteredArtist[_artist] = false;
        delete artistNames[_artist];

        // Remove from artistList (inefficient for large lists, but okay for example)
        for (uint256 i = 0; i < artistList.length; i++) {
            if (artistList[i] == _artist) {
                artistList[i] = artistList[artistList.length - 1];
                artistList.pop();
                break;
            }
        }
        emit ArtistRemoved(_artist);
    }

    function getArtistName(address _artist) external view returns (string memory) {
        return artistNames[_artist];
    }

    function isArtist(address _artist) external view returns (bool) {
        return isRegisteredArtist[_artist];
    }

    // -------- 2. Generative Art Seed Management --------

    function requestNewSeed() external onlyArtist whenNotPaused {
        require(block.timestamp >= lastSeedRequestTime[msg.sender] + seedRequestCooldown, "Seed request cooldown not elapsed");
        seedCounter++;
        uint256 newSeed = block.timestamp + seedCounter + uint256(keccak256(abi.encode(msg.sender, block.number))); // Example seed generation - improve security for production
        generativeSeeds[seedCounter] = newSeed;
        lastSeedRequestTime[msg.sender] = block.timestamp;
        emit SeedRequested(msg.sender, seedCounter, newSeed);
    }

    function getLastSeedRequestTime(address _artist) external view returns (uint256) {
        return lastSeedRequestTime[_artist];
    }

    function getCurrentSeed(uint256 _seedId) external view returns (uint256) {
        require(generativeSeeds[_seedId] != 0, "Seed ID does not exist");
        return generativeSeeds[_seedId];
    }

    function getTotalSeedsRequested() external view returns (uint256) {
        return seedCounter;
    }

    // -------- 3. Art Proposal and Submission --------

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _seedId) external onlyArtist whenNotPaused {
        require(_seedId <= seedCounter && generativeSeeds[_seedId] != 0, "Invalid seed ID"); // Ensure seed exists
        artProposalCounter++;
        artProposals[artProposalCounter] = ArtProposal({
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            seedId: _seedId,
            status: ProposalStatus.Pending,
            rejectionReason: "",
            submissionTimestamp: block.timestamp
        });
        emit ArtProposalSubmitted(artProposalCounter, msg.sender, _title);
    }

    function approveArtProposal(uint256 _proposalId) external onlyAdmin whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending");
        artProposals[_proposalId].status = ProposalStatus.Approved;
        emit ArtProposalApproved(_proposalId);
    }

    function rejectArtProposal(uint256 _proposalId, string memory _reason) external onlyAdmin whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending");
        artProposals[_proposalId].status = ProposalStatus.Rejected;
        artProposals[_proposalId].rejectionReason = _reason;
        emit ArtProposalRejected(_proposalId, _reason);
    }

    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        require(artProposals[_proposalId].artist != address(0), "Proposal ID does not exist");
        return artProposals[_proposalId];
    }

    function getProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        require(artProposals[_proposalId].artist != address(0), "Proposal ID does not exist");
        return artProposals[_proposalId].status;
    }

    // -------- 4. Collaborative Art Projects --------

    function createCollaborativeProject(string memory _projectName, string memory _projectDescription) external onlyArtist whenNotPaused {
        collaborativeProjectCounter++;
        projects[collaborativeProjectCounter] = CollaborativeProject({
            projectName: _projectName,
            projectDescription: _projectDescription,
            creator: msg.sender,
            members: new address[](0),
            creationTimestamp: block.timestamp
        });
        projectMembers[collaborativeProjectCounter][msg.sender] = true; // Creator is automatically a member
        projects[collaborativeProjectCounter].members.push(msg.sender);
        emit CollaborativeProjectCreated(collaborativeProjectCounter, _projectName, msg.sender);
    }

    function joinCollaborativeProject(uint256 _projectId) external onlyArtist whenNotPaused {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        require(!projectMembers[_projectId][msg.sender], "Already a member of this project");
        projectMembers[_projectId][msg.sender] = true;
        projects[_projectId].members.push(msg.sender);
        emit ProjectJoined(_projectId, msg.sender);
    }

    function leaveCollaborativeProject(uint256 _projectId) external onlyArtist whenNotPaused {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        require(projectMembers[_projectId][msg.sender], "Not a member of this project");
        require(projects[_projectId].creator != msg.sender, "Project creator cannot leave, must dissolve project (not implemented here)"); // Basic protection for creator leaving

        projectMembers[_projectId][msg.sender] = false;
        // Remove from members array (inefficient for large arrays, but okay for example)
        address[] storage members = projects[_projectId].members;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit ProjectLeft(_projectId, msg.sender);
    }

    function getProjectDetails(uint256 _projectId) external view returns (CollaborativeProject memory) {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        return projects[_projectId];
    }

    function isProjectMember(uint256 _projectId, address _artist) external view returns (bool) {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        return projectMembers[_projectId][_artist];
    }

    function contributeToProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsHash) external onlyArtist whenNotPaused {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        require(projectMembers[_projectId][msg.sender], "Must be a member of the project to contribute");
        contributionCounter++;
        contributions[contributionCounter] = Contribution({
            artist: msg.sender,
            projectId: _projectId,
            description: _contributionDescription,
            ipfsHash: _ipfsHash,
            upvotes: 0,
            timestamp: block.timestamp
        });
        emit ContributionSubmitted(contributionCounter, _projectId, msg.sender);
    }

    function getProjectContributions(uint256 _projectId) external view returns (Contribution[] memory) {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        uint256 count = 0;
        for (uint256 i = 1; i <= contributionCounter; i++) {
            if (contributions[i].projectId == _projectId) {
                count++;
            }
        }
        Contribution[] memory projectContributions = new Contribution[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= contributionCounter; i++) {
            if (contributions[i].projectId == _projectId) {
                projectContributions[index] = contributions[i];
                index++;
            }
        }
        return projectContributions;
    }

    // -------- 5. Reputation and Rewards (Basic Example) --------

    function upvoteContribution(uint256 _projectId, uint256 _contributionId) external onlyArtist whenNotPaused {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        require(contributions[_contributionId].projectId == _projectId, "Contribution not in this project");
        require(projectMembers[_projectId][msg.sender], "Must be a project member to upvote");
        require(!contributionUpvotedByArtist[_projectId][_contributionId][msg.sender], "Artist has already upvoted this contribution");

        contributions[_contributionId].upvotes++;
        contributionUpvotedByArtist[_projectId][_contributionId][msg.sender] = true;
        emit ContributionUpvoted(_projectId, _contributionId, msg.sender);
    }

    function getContributionUpvotes(uint256 _projectId, uint256 _contributionId) external view returns (uint256) {
        require(contributions[_contributionId].projectId == _projectId, "Contribution not found");
        return contributions[_contributionId].upvotes;
    }

    function distributeProjectRewards(uint256 _projectId) external onlyAdmin whenNotPaused {
        require(projects[_projectId].creator != address(0), "Project ID does not exist");
        // **Simplified Reward Distribution Example:**
        // In a real system, this would be much more complex, potentially involving tokens,
        // more sophisticated reputation algorithms, and treasury management.
        // This example just logs the upvotes per artist.

        mapping(address => uint256) artistUpvoteCounts;
        for (uint256 i = 1; i <= contributionCounter; i++) {
            if (contributions[i].projectId == _projectId) {
                artistUpvoteCounts[contributions[i].artist] += contributions[i].upvotes;
            }
        }

        // Example logging - in a real system, you'd distribute tokens or other rewards.
        for (uint256 i = 0; i < projects[_projectId].members.length; i++) {
            address member = projects[_projectId].members[i];
            uint256 upvotes = artistUpvoteCounts[member];
            // In a real system, you would use 'upvotes' to calculate and distribute rewards here.
            // For example, mint tokens and transfer to each member proportionally to their upvotes.
            // Or update a reputation score based on upvotes.
            // For this example, we'll just log it (in a real system, use events for off-chain processing).
            // console.log(string(abi.encodePacked("Artist ", artistNames[member], " in Project ", projects[_projectId].projectName, " received ", upvotes, " upvotes.")));
            // (Solidity doesn't have console.log, this is just for conceptual illustration)
            // Emit an event for reward distribution details.
        }
    }


    // -------- 6. Decentralized Governance (Simple Example) --------

    function proposeGovernanceChange(string memory _proposalTitle, string memory _proposalDescription, string memory _ipfsHash) external onlyArtist whenNotPaused {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            title: _proposalTitle,
            description: _proposalDescription,
            ipfsHash: _ipfsHash,
            status: ProposalStatus.Pending,
            votes: mapping(address => bool)(), // Initialize empty votes mapping
            yesVotes: 0,
            noVotes: 0,
            submissionTimestamp: block.timestamp
        });
        emit GovernanceProposalCreated(governanceProposalCounter, _proposalTitle);
    }

    function voteOnGovernanceChange(uint256 _proposalId, bool _vote) external onlyArtist whenNotPaused {
        require(governanceProposals[_proposalId].status == ProposalStatus.Pending, "Governance proposal is not pending");
        require(!governanceProposals[_proposalId].votes[msg.sender], "Artist has already voted");

        governanceProposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceVoteCasted(_proposalId, msg.sender, _vote);
    }

    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        require(governanceProposals[_proposalId].title.length > 0, "Governance proposal ID does not exist"); // Basic check if proposal exists
        return governanceProposals[_proposalId];
    }

    function getGovernanceProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        require(governanceProposals[_proposalId].title.length > 0, "Governance proposal ID does not exist");
        return governanceProposals[_proposalId].status;
    }

    function executeGovernanceChange(uint256 _proposalId) external onlyAdmin whenNotPaused {
        require(governanceProposals[_proposalId].status == ProposalStatus.Pending, "Governance proposal is not pending");
        uint256 totalArtists = artistList.length;
        uint256 requiredVotes = (totalArtists * 50) / 100; // Example: 50% quorum
        if (governanceProposals[_proposalId].yesVotes > requiredVotes) {
            governanceProposals[_proposalId].status = ProposalStatus.Approved;
            emit GovernanceProposalApproved(_proposalId);
            // **Governance Action Implementation Here:**
            //  This is where you would implement the actual change proposed.
            //  For example, if the proposal was to change the seedRequestCooldown:
            //  // Example: if proposal description contains "change seed cooldown to X hours":
            //  //  uint256 newCooldownHours = extractHoursFromDescription(governanceProposals[_proposalId].description);
            //  //  seedRequestCooldown = newCooldownHours * 1 hours;
            //  //  emit SeedCooldownChanged(seedRequestCooldown);
            //  **Important:** Governance execution needs to be carefully designed and tested.
        } else {
            governanceProposals[_proposalId].status = ProposalStatus.Rejected;
            emit GovernanceProposalRejected(_proposalId);
        }
    }


    // -------- 7. Utility and Admin Functions --------

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(oldAdmin, _newAdmin);
    }

    function getAdmin() external view returns (address) {
        return admin;
    }

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    function isContractPaused() external view returns (bool) {
        return paused;
    }
}
```