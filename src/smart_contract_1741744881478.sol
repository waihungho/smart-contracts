```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A unique smart contract for a Decentralized Autonomous Art Collective (DAAC)
 *      that goes beyond typical DAO functionalities. It focuses on collaborative art creation,
 *      dynamic NFT ownership, reputation-based governance, and innovative incentive mechanisms.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `applyForArtistMembership(string memory _artistName, string memory _artistStatement)`: Allows users to apply for artist membership within the collective.
 * 2. `approveArtistApplication(address _applicant, bool _approve)`: DAO-controlled function to approve or reject artist membership applications.
 * 3. `revokeArtistMembership(address _artist)`: DAO-controlled function to revoke artist membership.
 * 4. `submitArtworkProposal(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkIPFSHash)`: Approved artists can submit artwork proposals to the collective.
 * 5. `voteOnArtworkProposal(uint256 _proposalId, bool _vote)`: Members (artists and potentially other stakeholders) can vote on artwork proposals.
 * 6. `acceptArtworkProposal(uint256 _proposalId)`: DAO-controlled function to accept an artwork proposal after successful voting.
 * 7. `rejectArtworkProposal(uint256 _proposalId)`: DAO-controlled function to reject an artwork proposal after unsuccessful voting.
 * 8. `mintCollectiveNFT(uint256 _artworkId)`: Mints a collective NFT for an accepted artwork proposal, ownership initially held by the collective.
 * 9. `transferNFTFractionalOwnership(uint256 _artworkId, address[] memory _recipients, uint256[] memory _shares)`: Distributes fractional ownership of a collective NFT to artists or contributors based on DAO approval.
 * 10. `proposeCollaborativeProject(string memory _projectName, string memory _projectDescription)`: Artists can propose collaborative art projects within the collective.
 * 11. `voteOnCollaborationProject(uint256 _projectId, bool _vote)`: Members vote on proposed collaborative projects.
 * 12. `startCollaborationProject(uint256 _projectId)`: DAO-controlled function to start a collaborative project after voting.
 * 13. `contributeToProject(uint256 _projectId, string memory _contributionDetails, string memory _contributionIPFSHash)`: Artists can contribute to active collaborative projects.
 * 14. `finalizeCollaborationProject(uint256 _projectId)`: DAO-controlled function to finalize a collaborative project after contributions are complete.
 * 15. `distributeProjectRewards(uint256 _projectId)`: Distributes rewards (tokens, NFT shares) to contributors of a finalized project based on DAO-determined contribution weights.
 * 16. `proposeCollectiveParameterChange(string memory _parameterName, uint256 _newValue)`: DAO members can propose changes to collective parameters (voting durations, thresholds, etc.).
 * 17. `voteOnParameterChange(uint256 _parameterChangeId, bool _vote)`: Members vote on proposed parameter changes.
 * 18. `enactParameterChange(uint256 _parameterChangeId)`: DAO-controlled function to enact approved parameter changes.
 * 19. `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 * 20. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: DAO-controlled function to withdraw funds from the collective treasury for approved purposes (artist grants, project funding, etc.).
 * 21. `getArtistProfile(address _artist)`: Retrieves artist profile information.
 * 22. `getArtworkProposalDetails(uint256 _proposalId)`: Retrieves details of an artwork proposal.
 * 23. `getCollaborationProjectDetails(uint256 _projectId)`: Retrieves details of a collaborative project.
 * 24. `getCollectiveTreasuryBalance()`: Returns the current ETH balance of the collective treasury.
 * 25. `listActiveProjects()`: Returns a list of active collaborative project IDs.
 * 26. `listCollectiveArtworks()`: Returns a list of IDs of accepted collective artworks.
 * 27. `getNFTContractAddress(uint256 _artworkId)`: Returns the address of the NFT contract associated with a collective artwork (if fractionalized).
 * 28. `getMyVotingPower(address _voter)`: (Future Enhancement - Reputation-based voting) -  Calculates the voting power of a member (currently simple 1-vote per member).
 */

contract DecentralizedAutonomousArtCollective {

    // --- State Variables ---

    address public daoController; // Address of the DAO controller (e.g., multisig wallet, governance contract)
    uint256 public artistApplicationFee; // Fee to apply for artist membership (optional)
    uint256 public artworkProposalVotingDuration; // Duration for artwork proposal voting
    uint256 public collaborationProjectVotingDuration; // Duration for collaborative project voting
    uint256 public parameterChangeVotingDuration; // Duration for parameter change voting
    uint256 public votingQuorumPercentage; // Percentage of votes needed to pass a proposal

    uint256 public nextArtistId;
    uint256 public nextArtworkProposalId;
    uint256 public nextCollaborationProjectId;
    uint256 public nextParameterChangeId;

    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    mapping(uint256 => CollaborationProject) public collaborationProjects;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => address) public artworkNFTContracts; // Map artworkId to NFT contract address (if fractionalized)
    mapping(address => bool) public isApprovedArtist;
    mapping(address => bool) public hasAppliedForMembership;

    address[] public approvedArtists;
    uint256[] public activeCollaborationProjects;
    uint256[] public collectiveArtworks;


    // --- Structs ---

    struct ArtistProfile {
        uint256 artistId;
        string artistName;
        string artistStatement;
        uint256 joinTimestamp;
        bool isActive;
    }

    struct ArtworkProposal {
        uint256 proposalId;
        address proposer;
        string artworkTitle;
        string artworkDescription;
        string artworkIPFSHash;
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isAccepted;
        bool isRejected;
        bool votingActive;
    }

    struct CollaborationProject {
        uint256 projectId;
        string projectName;
        string projectDescription;
        address proposer;
        uint256 proposalTimestamp;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isFinalized;
        bool votingActive;
        mapping(address => Contribution) contributions; // Artist address to their contribution details
        address[] contributors;
    }

    struct Contribution {
        string contributionDetails;
        string contributionIPFSHash;
        uint256 contributionTimestamp;
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        address proposer;
        string parameterName;
        uint256 newValue;
        uint256 proposalTimestamp;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isEnacted;
        bool votingActive;
    }


    // --- Events ---

    event ArtistApplicationSubmitted(address applicant, string artistName);
    event ArtistApplicationApproved(address artist);
    event ArtistApplicationRejected(address applicant);
    event ArtistMembershipRevoked(address artist);
    event ArtworkProposalSubmitted(uint256 proposalId, address proposer, string artworkTitle);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtworkProposalAccepted(uint256 proposalId);
    event ArtworkProposalRejected(uint256 proposalId);
    event CollectiveNFTMinted(uint256 artworkId, address nftContractAddress);
    event NFTFractionalOwnershipTransferred(uint256 artworkId, address[] recipients, uint256[] shares);
    event CollaborationProjectProposed(uint256 projectId, string projectName, address proposer);
    event CollaborationProjectVoted(uint256 projectId, address voter, bool vote);
    event CollaborationProjectStarted(uint256 projectId);
    event ContributionSubmitted(uint256 projectId, address contributor);
    event CollaborationProjectFinalized(uint256 projectId);
    event ProjectRewardsDistributed(uint256 projectId);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeEnacted(uint256 proposalId, string parameterName, uint256 newValue);
    event DonationReceived(address donor, uint256 amount);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyDAOController() {
        require(msg.sender == daoController, "Only DAO controller can call this function");
        _;
    }

    modifier onlyApprovedArtist() {
        require(isApprovedArtist[msg.sender], "Only approved artists can call this function");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= nextArtworkProposalId, "Invalid Artwork Proposal ID");
        _;
    }

    modifier validProjectId(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= nextCollaborationProjectId, "Invalid Collaboration Project ID");
        _;
    }

    modifier validParameterChangeId(uint256 _parameterChangeId) {
        require(_parameterChangeId > 0 && _parameterChangeId <= nextParameterChangeId, "Invalid Parameter Change Proposal ID");
        _;
    }

    modifier votingIsActive(uint256 _endTime) {
        require(block.timestamp <= _endTime, "Voting has ended");
        _;
    }

    modifier votingIsNotActive(uint256 _endTime) {
        require(block.timestamp > _endTime, "Voting is still active");
        _;
    }

    modifier proposalVotingActive(uint256 _proposalId) {
        require(artworkProposals[_proposalId].votingActive, "Proposal voting is not active");
        require(!artworkProposals[_proposalId].isAccepted && !artworkProposals[_proposalId].isRejected, "Proposal already decided");
        _;
    }

    modifier projectVotingActive(uint256 _projectId) {
        require(collaborationProjects[_projectId].votingActive, "Project voting is not active");
        require(!collaborationProjects[_projectId].isActive && !collaborationProjects[_projectId].isFinalized, "Project already decided");
        _;
    }

    modifier parameterChangeVotingActive(uint256 _parameterChangeId) {
        require(parameterChangeProposals[_parameterChangeId].votingActive, "Parameter change voting is not active");
        require(!parameterChangeProposals[_parameterChangeId].isEnacted, "Parameter change already decided");
        _;
    }

    modifier proposalVotingEnded(uint256 _proposalId) {
        require(artworkProposals[_proposalId].votingActive, "Proposal voting is not active");
        require(block.timestamp > artworkProposals[_proposalId].votingEndTime, "Voting is still active");
        _;
    }

    modifier projectVotingEnded(uint256 _projectId) {
        require(collaborationProjects[_projectId].votingActive, "Project voting is not active");
        require(block.timestamp > collaborationProjects[_projectId].votingEndTime, "Voting is still active");
        _;
    }

    modifier parameterChangeVotingEnded(uint256 _parameterChangeId) {
        require(parameterChangeProposals[_parameterChangeId].votingActive, "Parameter change voting is not active");
        require(block.timestamp > parameterChangeProposals[_parameterChangeId].votingEndTime, "Voting is still active");
        _;
    }


    // --- Constructor ---

    constructor(address _daoController) {
        daoController = _daoController;
        artistApplicationFee = 0 ether; // Set default application fee
        artworkProposalVotingDuration = 7 days; // Default voting duration for artwork proposals
        collaborationProjectVotingDuration = 5 days; // Default voting for collaboration projects
        parameterChangeVotingDuration = 3 days; // Default voting for parameter changes
        votingQuorumPercentage = 50; // Default quorum percentage
        nextArtistId = 1;
        nextArtworkProposalId = 1;
        nextCollaborationProjectId = 1;
        nextParameterChangeId = 1;
    }


    // --- Artist Membership Functions ---

    function applyForArtistMembership(string memory _artistName, string memory _artistStatement) public payable {
        require(!isApprovedArtist[msg.sender], "Already an approved artist");
        require(!hasAppliedForMembership[msg.sender], "Application already submitted");
        require(msg.value >= artistApplicationFee, "Insufficient application fee"); // Optional fee

        artistProfiles[msg.sender] = ArtistProfile({
            artistId: 0, // Assigned upon approval
            artistName: _artistName,
            artistStatement: _artistStatement,
            joinTimestamp: 0, // Set on approval
            isActive: false
        });
        hasAppliedForMembership[msg.sender] = true;

        emit ArtistApplicationSubmitted(msg.sender, _artistName);
    }

    function approveArtistApplication(address _applicant, bool _approve) public onlyDAOController {
        require(hasAppliedForMembership[_applicant], "No application found for this address");
        require(!isApprovedArtist[_applicant], "Applicant is already an approved artist");

        if (_approve) {
            isApprovedArtist[_applicant] = true;
            artistProfiles[_applicant].artistId = nextArtistId++;
            artistProfiles[_applicant].joinTimestamp = block.timestamp;
            artistProfiles[_applicant].isActive = true;
            approvedArtists.push(_applicant);
            hasAppliedForMembership[_applicant] = false; // Reset application status
            emit ArtistApplicationApproved(_applicant);
        } else {
            hasAppliedForMembership[_applicant] = false; // Reset application status
            emit ArtistApplicationRejected(_applicant);
        }
    }

    function revokeArtistMembership(address _artist) public onlyDAOController {
        require(isApprovedArtist[_artist], "Not an approved artist");

        isApprovedArtist[_artist] = false;
        artistProfiles[_artist].isActive = false;
        // Remove from approvedArtists array (implementation might need to be optimized for gas in production if array is very large)
        for (uint256 i = 0; i < approvedArtists.length; i++) {
            if (approvedArtists[i] == _artist) {
                approvedArtists[i] = approvedArtists[approvedArtists.length - 1];
                approvedArtists.pop();
                break;
            }
        }
        emit ArtistMembershipRevoked(_artist);
    }

    function getArtistProfile(address _artist) public view returns (ArtistProfile memory) {
        return artistProfiles[_artist];
    }


    // --- Artwork Proposal Functions ---

    function submitArtworkProposal(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkIPFSHash) public onlyApprovedArtist {
        uint256 proposalId = nextArtworkProposalId++;
        artworkProposals[proposalId] = ArtworkProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkIPFSHash: _artworkIPFSHash,
            submissionTimestamp: block.timestamp,
            votingEndTime: block.timestamp + artworkProposalVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            isAccepted: false,
            isRejected: false,
            votingActive: true
        });

        emit ArtworkProposalSubmitted(proposalId, msg.sender, _artworkTitle);
    }

    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) public onlyApprovedArtist validProposalId(_proposalId) proposalVotingActive(_proposalId) {
        require(block.timestamp <= artworkProposals[_proposalId].votingEndTime, "Voting has ended"); // Redundant check, but good practice

        if (_vote) {
            artworkProposals[_proposalId].yesVotes++;
        } else {
            artworkProposals[_proposalId].noVotes++;
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _vote);
    }

    function acceptArtworkProposal(uint256 _proposalId) public onlyDAOController validProposalId(_proposalId) proposalVotingEnded(_proposalId) {
        require(!artworkProposals[_proposalId].isAccepted && !artworkProposals[_proposalId].isRejected, "Proposal already decided");

        uint256 totalVotes = artworkProposals[_proposalId].yesVotes + artworkProposals[_proposalId].noVotes;
        uint256 quorumNeeded = (totalVotes * votingQuorumPercentage) / 100;

        if (artworkProposals[_proposalId].yesVotes >= quorumNeeded) {
            artworkProposals[_proposalId].isAccepted = true;
            artworkProposals[_proposalId].votingActive = false;
            collectiveArtworks.push(_proposalId);
            emit ArtworkProposalAccepted(_proposalId);
        } else {
            artworkProposals[_proposalId].isRejected = true;
            artworkProposals[_proposalId].votingActive = false;
            emit ArtworkProposalRejected(_proposalId);
        }
    }

    function rejectArtworkProposal(uint256 _proposalId) public onlyDAOController validProposalId(_proposalId) proposalVotingEnded(_proposalId) {
        require(!artworkProposals[_proposalId].isAccepted && !artworkProposals[_proposalId].isRejected, "Proposal already decided");
        artworkProposals[_proposalId].isRejected = true;
        artworkProposals[_proposalId].votingActive = false;
        emit ArtworkProposalRejected(_proposalId);
    }

    function getArtworkProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }

    function listCollectiveArtworks() public view returns (uint256[] memory) {
        return collectiveArtworks;
    }


    // --- Collective NFT Minting & Fractional Ownership ---

    function mintCollectiveNFT(uint256 _artworkId) public onlyDAOController validProposalId(_artworkId) {
        require(artworkProposals[_artworkId].isAccepted, "Artwork proposal must be accepted to mint NFT");
        require(artworkNFTContracts[_artworkId] == address(0), "NFT already minted for this artwork");

        // ---  **Advanced Concept: Dynamic NFT Contract Deployment** ---
        // In a real-world scenario, you would deploy a new NFT contract (e.g., ERC721 or ERC1155)
        // specifically for this artwork, potentially with unique metadata and features.
        // For simplicity in this example, we'll just record a placeholder address.
        address nftContractAddress = address(this); // Placeholder - Replace with actual NFT contract deployment logic

        artworkNFTContracts[_artworkId] = nftContractAddress;
        emit CollectiveNFTMinted(_artworkId, nftContractAddress);
    }

    function transferNFTFractionalOwnership(uint256 _artworkId, address[] memory _recipients, uint256[] memory _shares) public onlyDAOController validProposalId(_artworkId) {
        require(artworkNFTContracts[_artworkId] != address(0), "NFT must be minted before transferring ownership");
        require(_recipients.length == _shares.length, "Recipients and shares arrays must have the same length");

        // --- **Advanced Concept: Fractional NFT Ownership Distribution** ---
        // This is a simplified example. In a real implementation, you would interact with the deployed NFT contract
        // (ERC1155 or a fractionalization contract) to distribute fractional ownership based on _shares.
        // This might involve minting ERC1155 tokens representing fractions and transferring them to recipients.

        emit NFTFractionalOwnershipTransferred(_artworkId, _recipients, _shares);
    }

    function getNFTContractAddress(uint256 _artworkId) public view validProposalId(_artworkId) returns (address) {
        return artworkNFTContracts[_artworkId];
    }


    // --- Collaborative Project Functions ---

    function proposeCollaborationProject(string memory _projectName, string memory _projectDescription) public onlyApprovedArtist {
        uint256 projectId = nextCollaborationProjectId++;
        collaborationProjects[projectId] = CollaborationProject({
            projectId: projectId,
            projectName: _projectName,
            projectDescription: _projectDescription,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + collaborationProjectVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: false,
            isFinalized: false,
            votingActive: true,
            contributions: mapping(address => Contribution)(),
            contributors: new address[](0)
        });
        emit CollaborationProjectProposed(projectId, _projectName, msg.sender);
    }

    function voteOnCollaborationProject(uint256 _projectId, bool _vote) public onlyApprovedArtist validProjectId(_projectId) projectVotingActive(_projectId) {
        if (_vote) {
            collaborationProjects[_projectId].yesVotes++;
        } else {
            collaborationProjects[_projectId].noVotes++;
        }
        emit CollaborationProjectVoted(_projectId, msg.sender, _vote);
    }

    function startCollaborationProject(uint256 _projectId) public onlyDAOController validProjectId(_projectId) projectVotingEnded(_projectId) {
        require(!collaborationProjects[_projectId].isActive && !collaborationProjects[_projectId].isFinalized, "Project already decided");

        uint256 totalVotes = collaborationProjects[_projectId].yesVotes + collaborationProjects[_projectId].noVotes;
        uint256 quorumNeeded = (totalVotes * votingQuorumPercentage) / 100;

        if (collaborationProjects[_projectId].yesVotes >= quorumNeeded) {
            collaborationProjects[_projectId].isActive = true;
            collaborationProjects[_projectId].votingActive = false;
            activeCollaborationProjects.push(_projectId);
            emit CollaborationProjectStarted(_projectId);
        } else {
            collaborationProjects[_projectId].votingActive = false;
            collaborationProjects[_projectId].isFinalized = true; // Mark as finalized even if not started due to vote
            emit CollaborationProjectFinalized(_projectId); // Still emit finalized event to indicate end of proposal process
        }
    }

    function contributeToProject(uint256 _projectId, string memory _contributionDetails, string memory _contributionIPFSHash) public onlyApprovedArtist validProjectId(_projectId) {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(collaborationProjects[_projectId].contributions[msg.sender].contributionTimestamp == 0, "Artist already contributed to this project"); // One contribution per artist for simplicity

        collaborationProjects[_projectId].contributions[msg.sender] = Contribution({
            contributionDetails: _contributionDetails,
            contributionIPFSHash: _contributionIPFSHash,
            contributionTimestamp: block.timestamp
        });
        collaborationProjects[_projectId].contributors.push(msg.sender); // Keep track of contributors
        emit ContributionSubmitted(_projectId, msg.sender);
    }

    function finalizeCollaborationProject(uint256 _projectId) public onlyDAOController validProjectId(_projectId) {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(!collaborationProjects[_projectId].isFinalized, "Project already finalized");

        collaborationProjects[_projectId].isActive = false;
        collaborationProjects[_projectId].isFinalized = true;
        // In a real scenario, you would add logic here for:
        // 1. Reviewing contributions
        // 2. Determining rewards/shares for contributors (potentially based on DAO vote or pre-defined rules)
        // 3. Distributing rewards (using `distributeProjectRewards` function below, or similar)

        // For simplicity, just emit finalized event
        emit CollaborationProjectFinalized(_projectId);
    }

    function distributeProjectRewards(uint256 _projectId) public onlyDAOController validProjectId(_projectId) {
        require(collaborationProjects[_projectId].isFinalized, "Project must be finalized before distributing rewards");
        // --- **Advanced Concept: Dynamic Reward Distribution** ---
        // This is a placeholder. In a real implementation, you would:
        // 1. Have a mechanism to determine reward distribution (e.g., DAO vote, predefined contribution weights, etc.)
        // 2. Distribute tokens, NFT fractions, or other rewards to contributors based on the determined distribution.
        // 3. This could involve transferring tokens from the treasury or interacting with the NFT contracts.

        emit ProjectRewardsDistributed(_projectId);
    }

    function getCollaborationProjectDetails(uint256 _projectId) public view validProjectId(_projectId) returns (CollaborationProject memory) {
        return collaborationProjects[_projectId];
    }

    function listActiveProjects() public view returns (uint256[] memory) {
        return activeCollaborationProjects;
    }


    // --- Collective Parameter Change Proposals ---

    function proposeCollectiveParameterChange(string memory _parameterName, uint256 _newValue) public onlyDAOController {
        uint256 proposalId = nextParameterChangeId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + parameterChangeVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            isEnacted: false,
            votingActive: true
        });
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChange(uint256 _parameterChangeId, bool _vote) public onlyDAOController validParameterChangeId(_parameterChangeId) parameterChangeVotingActive(_parameterChangeId) {
        if (_vote) {
            parameterChangeProposals[_parameterChangeId].yesVotes++;
        } else {
            parameterChangeProposals[_parameterChangeId].noVotes++;
        }
        emit ParameterChangeVoted(_parameterChangeId, msg.sender, _vote);
    }

    function enactParameterChange(uint256 _parameterChangeId) public onlyDAOController validParameterChangeId(_parameterChangeId) parameterChangeVotingEnded(_parameterChangeId) {
        require(!parameterChangeProposals[_parameterChangeId].isEnacted, "Parameter change already enacted");

        uint256 totalVotes = parameterChangeProposals[_parameterChangeId].yesVotes + parameterChangeProposals[_parameterChangeId].noVotes;
        uint256 quorumNeeded = (totalVotes * votingQuorumPercentage) / 100;

        if (parameterChangeProposals[_parameterChangeId].yesVotes >= quorumNeeded) {
            parameterChangeProposals[_parameterChangeId].isEnacted = true;
            parameterChangeProposals[_parameterChangeId].votingActive = false;

            // --- Enact the parameter change based on _parameterName ---
            string memory paramName = parameterChangeProposals[_parameterChangeId].parameterName;
            uint256 newValue = parameterChangeProposals[_parameterChangeId].newValue;

            if (keccak256(bytes(paramName)) == keccak256(bytes("artistApplicationFee"))) {
                artistApplicationFee = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("artworkProposalVotingDuration"))) {
                artworkProposalVotingDuration = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("collaborationProjectVotingDuration"))) {
                collaborationProjectVotingDuration = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("parameterChangeVotingDuration"))) {
                parameterChangeVotingDuration = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("votingQuorumPercentage"))) {
                votingQuorumPercentage = newValue;
            } else {
                revert("Invalid parameter name"); // Or handle unknown parameters differently
            }

            emit ParameterChangeEnacted(_parameterChangeId, paramName, newValue);
        } else {
            parameterChangeProposals[_parameterChangeId].votingActive = false;
        }
    }


    // --- Treasury Functions ---

    function donateToCollective() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyDAOController {
        require(address(this).balance >= _amount, "Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    function getCollectiveTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Future Enhancement: Reputation-based voting ---
    // function getMyVotingPower(address _voter) public view returns (uint256) {
    //     // Example: Simple 1-vote per approved artist for now.
    //     // In a more advanced system, voting power could be based on artist reputation, contributions, etc.
    //     if (isApprovedArtist[_voter]) {
    //         return 1;
    //     }
    //     return 0;
    // }

    // --- Fallback Function (Optional) ---
    receive() external payable {
        emit DonationReceived(msg.sender, msg.value); // Allow direct ETH donations to contract address
    }
}
```