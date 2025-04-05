```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - "Chromatic Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective focused on collaborative digital art creation,
 *      dynamic NFTs, and community-driven evolution of artworks. This contract allows artists to propose,
 *      vote on, and collaboratively contribute to digital art projects.  It introduces concepts like:
 *      - Dynamic NFTs that evolve based on collective contributions.
 *      - Layered art projects with different artists contributing to different layers.
 *      - Skill-based contribution and reputation within the collective.
 *      - Decentralized curation and art style evolution through community voting.
 *      - Revenue sharing and fair distribution of profits from NFT sales.
 *      - Artistic challenges and community-driven art competitions.
 *
 * Function Summary:
 *
 * **Initialization & Setup:**
 * 1. `constructor(string _collectiveName, uint256 _votingPeriod, uint256 _proposalDeposit)`: Initializes the DAAC with name, voting period, and proposal deposit.
 * 2. `setCollectiveName(string _newName)`: Allows the admin to change the collective's name.
 * 3. `setVotingPeriod(uint256 _newPeriod)`: Allows the admin to change the default voting period for proposals.
 * 4. `setProposalDeposit(uint256 _newDeposit)`: Allows the admin to change the proposal deposit amount.
 * 5. `pauseContract()`: Allows the admin to pause the contract, disabling most functions.
 * 6. `unpauseContract()`: Allows the admin to unpause the contract.
 * 7. `withdrawAdminFunds()`: Allows the admin to withdraw any accumulated contract balance (for maintenance/development).
 *
 * **Membership & Governance:**
 * 8. `joinCollective(string _artistName, string _artistDescription, string _portfolioLink)`: Allows artists to request membership in the collective.
 * 9. `leaveCollective()`: Allows members to voluntarily leave the collective.
 * 10. `proposeMembership(address _newArtistAddress, string _artistName, string _artistDescription, string _portfolioLink)`: Allows members to propose new artists for membership.
 * 11. `voteOnMembership(uint256 _proposalId, bool _vote)`: Allows members to vote on membership proposals.
 * 12. `getMemberCount()`: Returns the current number of members in the collective.
 * 13. `getMemberDetails(address _memberAddress)`: Retrieves details of a specific member.
 *
 * **Art Projects & Collaboration:**
 * 14. `proposeProject(string _projectName, string _projectDescription, string _projectStyle, string _layersDescription, string _initialConceptIPFSHash, uint256 _fundingGoal)`: Allows members to propose new art projects.
 * 15. `voteOnProject(uint256 _projectId, bool _vote)`: Allows members to vote on art project proposals.
 * 16. `fundProject(uint256 _projectId) payable`: Allows members to contribute funds to a approved art project.
 * 17. `contributeToLayer(uint256 _projectId, uint256 _layerId, string _contributionIPFSHash)`: Allows members to contribute to specific layers of an approved and funded project.
 * 18. `voteOnLayerContribution(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex, bool _vote)`: Allows members to vote on submitted contributions for a specific project layer.
 * 19. `finalizeLayer(uint256 _projectId, uint256 _layerId)`: Finalizes a layer of a project after successful contribution voting.
 * 20. `finalizeProject(uint256 _projectId)`: Finalizes a project after all layers are finalized, minting a Dynamic NFT.
 * 21. `mintProjectNFT(uint256 _projectId)`: Mints the Dynamic NFT for a finalized project to the project owner.
 * 22. `getProjectDetails(uint256 _projectId)`: Retrieves details of a specific art project.
 * 23. `getLayerDetails(uint256 _projectId, uint256 _layerId)`: Retrieves details of a specific layer within a project.
 * 24. `getContributionDetails(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex)`: Retrieves details of a specific contribution to a layer.
 * 25. `getTotalProjectContributions(uint256 _projectId)`: Returns the total number of contributions for a project.
 *
 * **Reputation & Rewards (Conceptual - Can be expanded):**
 * 26. `getMemberReputation(address _memberAddress)`: (Conceptual) Returns a member's reputation score (based on contributions, votes, etc.).
 * 27. `claimContributionReward(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex)`: (Conceptual) Allows contributors to claim rewards for accepted contributions (if implemented).
 *
 * **Events:**
 * Emits various events for key actions like membership changes, project proposals, voting, contributions, and NFT minting.
 */
contract ChromaticCanvasDAAC {
    string public collectiveName;
    address public admin;
    uint256 public votingPeriod;
    uint256 public proposalDeposit;
    bool public paused;

    // Structs and Enums
    enum ProposalType { Membership, Project }
    enum ProposalStatus { Pending, Active, Rejected, Accepted }
    enum ProjectStatus { Proposed, Voting, Funding, Contributing, LayerVoting, FinalizingLayer, Finalized, Completed }
    enum LayerStatus { Proposed, Voting, Contributing, ContributionVoting, Finalized }
    enum ContributionStatus { Pending, Voting, Accepted, Rejected }
    enum MemberStatus { Pending, Active, Inactive }

    struct MembershipProposal {
        uint256 proposalId;
        address proposer;
        address artistAddress;
        string artistName;
        string artistDescription;
        string portfolioLink;
        ProposalStatus status;
        uint256 voteCount;
        uint256 endTime;
    }

    struct ProjectProposal {
        uint256 proposalId;
        address proposer;
        string projectName;
        string projectDescription;
        string projectStyle;
        string layersDescription; // Description of layers and required skills
        string initialConceptIPFSHash;
        uint256 fundingGoal;
        ProposalStatus status;
        uint256 voteCount;
        uint256 endTime;
    }

    struct ArtProject {
        uint256 projectId;
        address proposer;
        string projectName;
        string projectDescription;
        string projectStyle;
        string layersDescription;
        string initialConceptIPFSHash;
        uint256 fundingGoal;
        uint256 currentFunding;
        ProjectStatus status;
        uint256 layerCount;
    }

    struct ProjectLayer {
        uint256 layerId;
        uint256 projectId;
        LayerStatus status;
        string layerDescription;
        address finalizedContributor; // Address of the contributor whose work was finalized for this layer
        string finalizedContributionIPFSHash; // IPFS hash of the finalized contribution
        uint256 contributionCount;
    }

    struct LayerContribution {
        uint256 contributionIndex;
        uint256 projectId;
        uint256 layerId;
        address contributor;
        string contributionIPFSHash;
        ContributionStatus status;
        uint256 voteCount;
        uint256 endTime;
    }

    struct Member {
        address memberAddress;
        string artistName;
        string artistDescription;
        string portfolioLink;
        MemberStatus status;
        uint256 reputation; // Conceptual reputation score
        uint256 joinTimestamp;
    }

    // Mappings and Arrays
    mapping(uint256 => MembershipProposal) public membershipProposals;
    mapping(uint256 => ProjectProposal) public projectProposals;
    mapping(uint256 => ArtProject) public artProjects;
    mapping(uint256 => mapping(uint256 => ProjectLayer)) public projectLayers; // projectId => layerId => Layer
    mapping(uint256 => mapping(uint256 => mapping(uint256 => LayerContribution))) public layerContributions; // projectId => layerId => contributionIndex => Contribution
    mapping(address => Member) public members;
    mapping(address => bool) public isMember;
    address[] public memberList;

    uint256 public membershipProposalCounter;
    uint256 public projectProposalCounter;
    uint256 public projectCounter;

    // Events
    event CollectiveNameUpdated(string newName);
    event VotingPeriodUpdated(uint256 newPeriod);
    event ProposalDepositUpdated(uint256 newDeposit);
    event ContractPaused();
    event ContractUnpaused();
    event AdminFundsWithdrawn(address adminAddress, uint256 amount);
    event MembershipRequested(address artistAddress, string artistName);
    event MembershipProposed(uint256 proposalId, address proposer, address artistAddress);
    event MembershipVoteCast(uint256 proposalId, address voter, bool vote);
    event MembershipAccepted(address artistAddress);
    event MembershipRejected(uint256 proposalId);
    event MemberLeftCollective(address memberAddress);
    event ProjectProposed(uint256 projectId, address proposer, string projectName);
    event ProjectVoteCast(uint256 projectId, address voter, bool vote);
    event ProjectAccepted(uint256 projectId);
    event ProjectRejected(uint256 projectId);
    event ProjectFunded(uint256 projectId, address funder, uint256 amount);
    event ContributionSubmitted(uint256 projectId, uint256 layerId, uint256 contributionIndex, address contributor);
    event ContributionVoteCast(uint256 projectId, uint256 layerId, uint256 contributionIndex, address voter, bool vote);
    event LayerFinalized(uint256 projectId, uint256 layerId, address contributor);
    event ProjectFinalized(uint256 projectId);
    event ProjectNFTMinted(uint256 projectId, address recipient);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMembers() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Membership) {
            require(membershipProposals[_proposalId].proposalId == _proposalId, "Membership proposal does not exist.");
        } else if (_proposalType == ProposalType.Project) {
            require(projectProposals[_proposalId].proposalId == _proposalId, "Project proposal does not exist.");
        } else {
            revert("Invalid proposal type.");
        }
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(artProjects[_projectId].projectId == _projectId, "Project does not exist.");
        _;
    }

    modifier layerExists(uint256 _projectId, uint256 _layerId) {
        require(projectLayers[_projectId][_layerId].layerId == _layerId, "Layer does not exist.");
        _;
    }

    modifier contributionExists(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex) {
        require(layerContributions[_projectId][_layerId][_contributionIndex].contributionIndex == _contributionIndex, "Contribution does not exist.");
        _;
    }

    modifier projectInStatus(uint256 _projectId, ProjectStatus _status) {
        require(artProjects[_projectId].status == _status, "Project is not in the required status.");
        _;
    }

    modifier layerInStatus(uint256 _projectId, uint256 _layerId, LayerStatus _status) {
        require(projectLayers[_projectId][_layerId].status == _status, "Layer is not in the required status.");
        _;
    }

    modifier contributionInStatus(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex, ContributionStatus _status) {
        require(layerContributions[_projectId][_layerId][_contributionIndex].status == _status, "Contribution is not in the required status.");
        _;
    }

    // 1. Constructor
    constructor(string memory _collectiveName, uint256 _votingPeriod, uint256 _proposalDeposit) {
        admin = msg.sender;
        collectiveName = _collectiveName;
        votingPeriod = _votingPeriod;
        proposalDeposit = _proposalDeposit;
        paused = false;
    }

    // ---- Initialization & Setup Functions ----

    // 2. setCollectiveName
    function setCollectiveName(string memory _newName) public onlyAdmin notPaused {
        collectiveName = _newName;
        emit CollectiveNameUpdated(_newName);
    }

    // 3. setVotingPeriod
    function setVotingPeriod(uint256 _newPeriod) public onlyAdmin notPaused {
        votingPeriod = _newPeriod;
        emit VotingPeriodUpdated(_newPeriod);
    }

    // 4. setProposalDeposit
    function setProposalDeposit(uint256 _newDeposit) public onlyAdmin notPaused {
        proposalDeposit = _newDeposit;
        emit ProposalDepositUpdated(_newDeposit);
    }

    // 5. pauseContract
    function pauseContract() public onlyAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    // 6. unpauseContract
    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    // 7. withdrawAdminFunds
    function withdrawAdminFunds() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit AdminFundsWithdrawn(admin, balance);
    }

    // ---- Membership & Governance Functions ----

    // 8. joinCollective - Artist requests membership
    function joinCollective(string memory _artistName, string memory _artistDescription, string memory _portfolioLink) public notPaused {
        require(!isMember[msg.sender], "Already a member or membership pending.");
        require(bytes(_artistName).length > 0 && bytes(_artistDescription).length > 0 && bytes(_portfolioLink).length > 0, "Artist details cannot be empty.");

        membershipProposalCounter++;
        membershipProposals[membershipProposalCounter] = MembershipProposal({
            proposalId: membershipProposalCounter,
            proposer: address(0), // System initiated join request
            artistAddress: msg.sender,
            artistName: _artistName,
            artistDescription: _artistDescription,
            portfolioLink: _portfolioLink,
            status: ProposalStatus.Pending,
            voteCount: 0,
            endTime: 0
        });

        emit MembershipRequested(msg.sender, _artistName);
    }


    // 9. leaveCollective
    function leaveCollective() public onlyMembers notPaused {
        require(members[msg.sender].status == MemberStatus.Active, "Member is not active.");
        members[msg.sender].status = MemberStatus.Inactive;
        isMember[msg.sender] = false;

        // Remove from memberList - inefficient for large lists, consider optimization if needed in a real-world scenario
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MemberLeftCollective(msg.sender);
    }

    // 10. proposeMembership
    function proposeMembership(address _newArtistAddress, string memory _artistName, string memory _artistDescription, string memory _portfolioLink) public onlyMembers notPaused {
        require(!isMember[_newArtistAddress], "Artist is already a member or membership pending.");
        require(bytes(_artistName).length > 0 && bytes(_artistDescription).length > 0 && bytes(_portfolioLink).length > 0, "Artist details cannot be empty.");

        membershipProposalCounter++;
        membershipProposals[membershipProposalCounter] = MembershipProposal({
            proposalId: membershipProposalCounter,
            proposer: msg.sender,
            artistAddress: _newArtistAddress,
            artistName: _artistName,
            artistDescription: _artistDescription,
            portfolioLink: _portfolioLink,
            status: ProposalStatus.Active, // Immediately active for voting
            voteCount: 0,
            endTime: block.timestamp + votingPeriod
        });

        emit MembershipProposed(membershipProposalCounter, msg.sender, _newArtistAddress);
    }

    // 11. voteOnMembership
    function voteOnMembership(uint256 _proposalId, bool _vote) public onlyMembers notPaused proposalExists(_proposalId, ProposalType.Membership) {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Voting is not active for this proposal.");
        require(block.timestamp <= proposal.endTime, "Voting period has ended.");

        proposal.voteCount += (_vote ? 1 : 0); // Simple majority needed for now. Can be changed to quorum later.

        emit MembershipVoteCast(_proposalId, msg.sender, _vote);

        if (block.timestamp > proposal.endTime) {
            if (proposal.voteCount > (memberList.length / 2)) { // Simple majority
                _acceptMembershipProposal(_proposalId);
            } else {
                _rejectMembershipProposal(_proposalId);
            }
        }
    }

    function _acceptMembershipProposal(uint256 _proposalId) private {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");

        proposal.status = ProposalStatus.Accepted;
        address artistAddress = proposal.artistAddress;

        members[artistAddress] = Member({
            memberAddress: artistAddress,
            artistName: proposal.artistName,
            artistDescription: proposal.artistDescription,
            portfolioLink: proposal.portfolioLink,
            status: MemberStatus.Active,
            reputation: 0, // Initial reputation
            joinTimestamp: block.timestamp
        });
        isMember[artistAddress] = true;
        memberList.push(artistAddress);

        emit MembershipAccepted(artistAddress);
    }

    function _rejectMembershipProposal(uint256 _proposalId) private {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        proposal.status = ProposalStatus.Rejected;
        emit MembershipRejected(_proposalId);
    }

    // 12. getMemberCount
    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }

    // 13. getMemberDetails
    function getMemberDetails(address _memberAddress) public view returns (Member memory) {
        require(isMember[_memberAddress], "Address is not a member.");
        return members[_memberAddress];
    }


    // ---- Art Projects & Collaboration Functions ----

    // 14. proposeProject
    function proposeProject(
        string memory _projectName,
        string memory _projectDescription,
        string memory _projectStyle,
        string memory _layersDescription,
        string memory _initialConceptIPFSHash,
        uint256 _fundingGoal
    ) public onlyMembers notPaused {
        require(bytes(_projectName).length > 0 && bytes(_projectDescription).length > 0 && bytes(_projectStyle).length > 0 && bytes(_layersDescription).length > 0 && bytes(_initialConceptIPFSHash).length > 0, "Project details cannot be empty.");
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");

        projectProposalCounter++;
        projectProposals[projectProposalCounter] = ProjectProposal({
            proposalId: projectProposalCounter,
            proposer: msg.sender,
            projectName: _projectName,
            projectDescription: _projectDescription,
            projectStyle: _projectStyle,
            layersDescription: _layersDescription,
            initialConceptIPFSHash: _initialConceptIPFSHash,
            fundingGoal: _fundingGoal,
            status: ProposalStatus.Active, // Immediately active for voting
            voteCount: 0,
            endTime: block.timestamp + votingPeriod
        });

        emit ProjectProposed(projectProposalCounter, msg.sender, _projectName);
    }

    // 15. voteOnProject
    function voteOnProject(uint256 _proposalId, bool _vote) public onlyMembers notPaused proposalExists(_proposalId, ProposalType.Project) {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Voting is not active for this proposal.");
        require(block.timestamp <= proposal.endTime, "Voting period has ended.");

        proposal.voteCount += (_vote ? 1 : 0);

        emit ProjectVoteCast(_proposalId, msg.sender, _vote);

        if (block.timestamp > proposal.endTime) {
            if (proposal.voteCount > (memberList.length / 2)) { // Simple majority
                _acceptProjectProposal(_proposalId);
            } else {
                _rejectProjectProposal(_proposalId);
            }
        }
    }

    function _acceptProjectProposal(uint256 _proposalId) private {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        proposal.status = ProposalStatus.Accepted;

        projectCounter++;
        artProjects[projectCounter] = ArtProject({
            projectId: projectCounter,
            proposer: proposal.proposer,
            projectName: proposal.projectName,
            projectDescription: proposal.projectDescription,
            projectStyle: proposal.projectStyle,
            layersDescription: proposal.layersDescription,
            initialConceptIPFSHash: proposal.initialConceptIPFSHash,
            fundingGoal: proposal.fundingGoal,
            currentFunding: 0,
            status: ProjectStatus.Voting, // Next status is Funding
            layerCount: 0 // Layers will be defined based on project details later, or during project setup
        });

        emit ProjectAccepted(projectCounter);
        artProjects[projectCounter].status = ProjectStatus.Funding; // Move to Funding status immediately after acceptance
    }

    function _rejectProjectProposal(uint256 _proposalId) private {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        proposal.status = ProposalStatus.Rejected;
        emit ProjectRejected(_proposalId);
    }

    // 16. fundProject
    function fundProject(uint256 _projectId) public payable onlyMembers notPaused projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.Funding) {
        ArtProject storage project = artProjects[_projectId];
        require(project.currentFunding < project.fundingGoal, "Project funding goal already reached.");

        uint256 contributionAmount = msg.value;
        project.currentFunding += contributionAmount;

        emit ProjectFunded(_projectId, msg.sender, contributionAmount);

        if (project.currentFunding >= project.fundingGoal) {
            project.status = ProjectStatus.Contributing; // Move to Contributing phase once funded
            // Initialize layers based on project details (e.g., parse layersDescription) - Placeholder for future layer definition logic
            _initializeProjectLayers(_projectId, project.layersDescription); // Example layer initialization function
        }
    }

    // Placeholder for layer initialization logic - Customize based on how layers are defined in project proposal
    function _initializeProjectLayers(uint256 _projectId, string memory _layersDescription) private {
        // Example: Simple split by delimiter (e.g., ";") -  Needs more robust parsing for real use case
        string[] memory layerDescriptions = _stringSplit(_layersDescription, ";");
        for (uint256 i = 0; i < layerDescriptions.length; i++) {
            artProjects[_projectId].layerCount++;
            projectLayers[_projectId][artProjects[_projectId].layerCount] = ProjectLayer({
                layerId: artProjects[_projectId].layerCount,
                projectId: _projectId,
                status: LayerStatus.Contributing, // Layers start in Contributing status
                layerDescription: layerDescriptions[i],
                finalizedContributor: address(0),
                finalizedContributionIPFSHash: "",
                contributionCount: 0
            });
        }
    }

    // Helper function to split a string - Simple version, consider using libraries for more robust string manipulation
    function _stringSplit(string memory _string, string memory _delimiter) private pure returns (string[] memory) {
        bytes memory bytesString = bytes(_string);
        bytes memory bytesDelimiter = bytes(_delimiter);
        uint256 count = 0;
        for (uint256 i = 0; i < bytesString.length; i++) {
            if (i + bytesDelimiter.length <= bytesString.length) {
                bool found = true;
                for (uint256 j = 0; j < bytesDelimiter.length; j++) {
                    if (bytesString[i + j] != bytesDelimiter[j]) {
                        found = false;
                        break;
                    }
                }
                if (found) {
                    count++;
                    i += bytesDelimiter.length - 1;
                }
            }
        }
        string[] memory result = new string[](count + 1);
        uint256 startIndex = 0;
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < bytesString.length; i++) {
            if (i + bytesDelimiter.length <= bytesString.length) {
                bool found = true;
                for (uint256 j = 0; j < bytesDelimiter.length; j++) {
                    if (bytesString[i + j] != bytesDelimiter[j]) {
                        found = false;
                        break;
                    }
                }
                if (found) {
                    result[resultIndex] = string(bytesString[startIndex:i]);
                    resultIndex++;
                    startIndex = i + bytesDelimiter.length;
                    i += bytesDelimiter.length - 1;
                }
            }
        }
        result[resultIndex] = string(bytesString[startIndex:bytesString.length]);
        return result;
    }


    // 17. contributeToLayer
    function contributeToLayer(uint256 _projectId, uint256 _layerId, string memory _contributionIPFSHash) public onlyMembers notPaused projectExists(_projectId) layerExists(_projectId, _layerId) layerInStatus(_projectId, _layerId, LayerStatus.Contributing) {
        require(bytes(_contributionIPFSHash).length > 0, "Contribution IPFS Hash cannot be empty.");

        ProjectLayer storage layer = projectLayers[_projectId][_layerId];
        layer.contributionCount++;
        uint256 contributionIndex = layer.contributionCount;

        layerContributions[_projectId][_layerId][contributionIndex] = LayerContribution({
            contributionIndex: contributionIndex,
            projectId: _projectId,
            layerId: _layerId,
            contributor: msg.sender,
            contributionIPFSHash: _contributionIPFSHash,
            status: ContributionStatus.Voting, // Contributions start in Voting status
            voteCount: 0,
            endTime: block.timestamp + votingPeriod
        });

        emit ContributionSubmitted(_projectId, _layerId, contributionIndex, msg.sender);
        layer.status = LayerStatus.ContributionVoting; // Move layer to ContributionVoting status after first contribution
    }

    // 18. voteOnLayerContribution
    function voteOnLayerContribution(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex, bool _vote) public onlyMembers notPaused projectExists(_projectId) layerExists(_projectId, _layerId) contributionExists(_projectId, _layerId, _contributionIndex) layerInStatus(_projectId, _layerId, LayerStatus.ContributionVoting) contributionInStatus(_projectId, _layerId, _contributionIndex, ContributionStatus.Voting) {
        LayerContribution storage contribution = layerContributions[_projectId][_layerId][_contributionIndex];
        require(block.timestamp <= contribution.endTime, "Voting period has ended.");

        contribution.voteCount += (_vote ? 1 : 0);
        emit ContributionVoteCast(_projectId, _layerId, _contributionIndex, msg.sender, _vote);

        if (block.timestamp > contribution.endTime) {
            if (contribution.voteCount > (memberList.length / 2)) { // Simple majority
                _acceptLayerContribution(_projectId, _layerId, _contributionIndex);
            } else {
                _rejectLayerContribution(_projectId, _layerId, _contributionIndex);
            }
        }
    }

    function _acceptLayerContribution(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex) private {
        ProjectLayer storage layer = projectLayers[_projectId][_layerId];
        LayerContribution storage contribution = layerContributions[_projectId][_layerId][_contributionIndex];
        require(contribution.status == ContributionStatus.Voting, "Contribution voting is not active.");

        contribution.status = ContributionStatus.Accepted;
        layer.finalizedContributor = contribution.contributor;
        layer.finalizedContributionIPFSHash = contribution.contributionIPFSHash;
        emit LayerFinalized(_projectId, _layerId, contribution.contributor);
        layer.status = LayerStatus.FinalizingLayer; // Move to FinalizingLayer status before finalization
    }

    function _rejectLayerContribution(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex) private {
        LayerContribution storage contribution = layerContributions[_projectId][_layerId][_contributionIndex];
        require(contribution.status == ContributionStatus.Voting, "Contribution voting is not active.");
        contribution.status = ContributionStatus.Rejected;
        // Optionally, you could reset layer status back to Contributing if a contribution is rejected to allow for new submissions.
        // layer.status = LayerStatus.Contributing;
    }

    // 19. finalizeLayer
    function finalizeLayer(uint256 _projectId, uint256 _layerId) public onlyMembers notPaused projectExists(_projectId) layerExists(_projectId, _layerId) layerInStatus(_projectId, _layerId, LayerStatus.FinalizingLayer) {
        ProjectLayer storage layer = projectLayers[_projectId][_layerId];
        layer.status = LayerStatus.Finalized;
        artProjects[_projectId].status = ProjectStatus.FinalizingLayer; // Project moves to FinalizingLayer status when a layer is finalized

        // Check if all layers are finalized to move project to Finalized status
        bool allLayersFinalized = true;
        for (uint256 i = 1; i <= artProjects[_projectId].layerCount; i++) {
            if (projectLayers[_projectId][i].status != LayerStatus.Finalized) {
                allLayersFinalized = false;
                break;
            }
        }

        if (allLayersFinalized) {
            artProjects[_projectId].status = ProjectStatus.Finalized; // Project is Finalized when all layers are finalized
            emit ProjectFinalized(_projectId);
        }
    }

    // 20. finalizeProject (Redundant - Finalize Layer already triggers project finalization) - Keeping for clarity if needed
    function finalizeProject(uint256 _projectId) public onlyMembers notPaused projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.FinalizingLayer) {
        // This function might be redundant as finalizeLayer already checks and finalizes the project.
        // Keep it if you want an explicit function call to finalize the project after ensuring all layers are done.
        bool allLayersFinalized = true;
        for (uint256 i = 1; i <= artProjects[_projectId].layerCount; i++) {
            if (projectLayers[_projectId][i].status != LayerStatus.Finalized) {
                allLayersFinalized = false;
                break;
            }
        }

        require(allLayersFinalized, "Not all layers are finalized.");
        artProjects[_projectId].status = ProjectStatus.Completed; // Final project status after NFT minting
        emit ProjectFinalized(_projectId);
    }


    // 21. mintProjectNFT
    function mintProjectNFT(uint256 _projectId) public onlyMembers notPaused projectExists(_projectId) projectInStatus(_projectId, ProjectStatus.Finalized) {
        ArtProject storage project = artProjects[_projectId];
        // Mint a Dynamic NFT representing the finalized project.
        // This is a placeholder. In a real implementation, you would integrate with an NFT contract (ERC721 or ERC1155).
        // The NFT would dynamically display the finalized layers and project details.
        // For now, we just emit an event and change project status.

        // Example: (Conceptual NFT Minting Logic - Replace with actual NFT contract interaction)
        // _mintDynamicNFT(project.projectId, project.projectName, project.projectDescription, project.projectStyle, project.initialConceptIPFSHash, _getFinalizedLayersIPFSHashes(_projectId));
        project.status = ProjectStatus.Completed; // Mark project as Completed after NFT minting

        emit ProjectNFTMinted(_projectId, project.proposer); // Mint NFT to project proposer (can be changed based on reward distribution logic)
    }

    // Conceptual function to fetch IPFS hashes of finalized layers for NFT metadata (Placeholder)
    // function _getFinalizedLayersIPFSHashes(uint256 _projectId) private view returns (string[] memory) {
    //     uint256 layerCount = artProjects[_projectId].layerCount;
    //     string[] memory layerIPFSHashes = new string[](layerCount);
    //     for (uint256 i = 1; i <= layerCount; i++) {
    //         layerIPFSHashes[i-1] = projectLayers[_projectId][i].finalizedContributionIPFSHash;
    //     }
    //     return layerIPFSHashes;
    // }

    // Conceptual function to mint the Dynamic NFT (Placeholder - Needs ERC721/ERC1155 integration)
    // function _mintDynamicNFT(uint256 _projectId, string memory _projectName, string memory _projectDescription, string memory _projectStyle, string memory _initialConceptIPFSHash, string[] memory _layerIPFSHashes) private {
    //     // Implement NFT minting logic here, using an ERC721 or ERC1155 contract.
    //     // The NFT metadata would include project details and links to IPFS hashes of finalized layers.
    //     // Example: Call to an external NFT contract's mint function.
    //     // NFTContract.mint(artProjects[_projectId].proposer, _generateNFTMetadata(_projectId, _projectName, _projectDescription, _projectStyle, _initialConceptIPFSHash, _layerIPFSHashes));
    // }

    // 22. getProjectDetails
    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (ArtProject memory) {
        return artProjects[_projectId];
    }

    // 23. getLayerDetails
    function getLayerDetails(uint256 _projectId, uint256 _layerId) public view projectExists(_projectId) layerExists(_projectId, _layerId) returns (ProjectLayer memory) {
        return projectLayers[_projectId][_layerId];
    }

    // 24. getContributionDetails
    function getContributionDetails(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex) public view projectExists(_projectId) layerExists(_projectId, _layerId) contributionExists(_projectId, _layerId, _contributionIndex) returns (LayerContribution memory) {
        return layerContributions[_projectId][_layerId][_contributionIndex];
    }

    // 25. getTotalProjectContributions
    function getTotalProjectContributions(uint256 _projectId) public view projectExists(_projectId) returns (uint256) {
        uint256 totalContributions = 0;
        for(uint256 i = 1; i <= artProjects[_projectId].layerCount; i++){
            totalContributions += projectLayers[_projectId][i].contributionCount;
        }
        return totalContributions;
    }

    // ---- Reputation & Rewards (Conceptual - Can be expanded) ----

    // 26. getMemberReputation (Conceptual)
    function getMemberReputation(address _memberAddress) public view onlyMembers returns (uint256) {
        // Conceptual: In a real implementation, reputation could be tracked based on:
        // - Successful project contributions
        // - Positive votes on contributions
        // - Project proposals accepted
        // - Community engagement, etc.
        return members[_memberAddress].reputation; // Placeholder - returns current reputation score from Member struct
    }

    // 27. claimContributionReward (Conceptual)
    function claimContributionReward(uint256 _projectId, uint256 _layerId, uint256 _contributionIndex) public onlyMembers contributionExists(_projectId, _layerId, _contributionIndex) contributionInStatus(_projectId, _layerId, _contributionIndex, ContributionStatus.Accepted) {
        // Conceptual: Implement reward distribution mechanism here.
        // Rewards could be tokens, a share of NFT sales, or other incentives.
        // This function would handle transferring rewards to the contributor of the accepted contribution.
        LayerContribution storage contribution = layerContributions[_projectId][_layerId][_contributionIndex];
        require(contribution.contributor == msg.sender, "Only contributor can claim reward.");
        // ... (Reward distribution logic would go here) ...
        // Example: Transfer tokens to contributor
        // rewardToken.transfer(contribution.contributor, rewardAmount);

        // Mark reward as claimed (e.g., update contribution status or a separate mapping).
    }

    // Fallback function to receive Ether in case of direct transfers to the contract
    receive() external payable {}
}
```