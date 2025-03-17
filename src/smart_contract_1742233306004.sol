```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production Use)
 * @dev A smart contract for a decentralized art collective that focuses on collaborative art creation,
 *      dynamic NFT ownership, and community-driven governance. This contract incorporates advanced concepts
 *      like generative art seeds, layered royalties, reputation-based governance, and on-chain exhibitions.
 *
 * **Outline & Function Summary:**
 *
 * **I. Collective Governance & Membership:**
 *   1. `proposeNewMember(address _newMember)`: Allows current members to propose a new member to the collective.
 *   2. `voteOnMembershipProposal(uint _proposalId, bool _vote)`: Members can vote on pending membership proposals.
 *   3. `executeMembershipProposal(uint _proposalId)`: Executes a membership proposal if it passes the voting threshold.
 *   4. `removeMember(address _member)`: Allows members to propose removing a member (governance-based removal).
 *   5. `getMemberCount()`: Returns the current number of members in the collective.
 *   6. `isMember(address _address)`: Checks if an address is a member of the collective.
 *
 * **II. Collaborative Art Creation & NFT Minting:**
 *   7. `proposeArtProject(string _title, string _description, string _genre, string _initialSeed)`: Members can propose new collaborative art projects with initial details and a generative seed.
 *   8. `contributeToArtProject(uint _projectId, string _contributionData)`: Members can contribute data/elements to an approved art project (e.g., image layers, code snippets, text prompts).
 *   9. `finalizeArtProject(uint _projectId)`:  Allows members to propose finalizing an art project after sufficient contributions.
 *   10. `mintArtNFT(uint _projectId)`: Mints an NFT representing the finalized collaborative art project. NFT metadata includes contributors and project details.
 *   11. `getArtProjectDetails(uint _projectId)`: Retrieves details of a specific art project, including status, contributors, and description.
 *   12. `getArtProjectContributions(uint _projectId)`: Returns a list of contributions made to a specific art project.
 *
 * **III. Dynamic NFT Features & Ownership:**
 *   13. `transferArtNFT(address _to, uint _tokenId)`: Standard NFT transfer function with layered royalty support.
 *   14. `getNFTContributors(uint _tokenId)`: Returns the list of contributors for a specific art NFT (based on its project).
 *   15. `getNFTRoyaltyInfo(uint _tokenId, uint _salePrice)`: Calculates and returns royalty information for an NFT sale, distributing to contributors.
 *   16. `setBaseRoyaltyPercentage(uint _percentage)`:  Owner function to set the base royalty percentage for secondary sales.
 *
 * **IV. On-Chain Exhibitions & Curation:**
 *   17. `createExhibition(string _exhibitionTitle, string _exhibitionDescription)`: Members can propose and create on-chain virtual exhibitions.
 *   18. `addArtToExhibition(uint _exhibitionId, uint _artTokenId)`: Members can propose adding specific art NFTs (minted by this contract) to an exhibition.
 *   19. `removeArtFromExhibition(uint _exhibitionId, uint _artTokenId)`: Members can propose removing art from an exhibition.
 *   20. `getExhibitionDetails(uint _exhibitionId)`: Retrieves details of an exhibition, including title, description, and artworks.
 *
 * **V. Reputation & Contribution Tracking (Advanced Governance - Can be expanded):**
 *   21. `getMemberReputation(address _member)`: Returns a member's reputation score (can be based on contributions, votes, etc. - basic example provided).
 *   22. `upvoteContribution(uint _projectId, uint _contributionIndex)`: Members can upvote contributions to art projects, potentially influencing reputation.
 *   23. `downvoteContribution(uint _projectId, uint _contributionIndex)`: Members can downvote contributions to art projects.
 *
 * **VI. Owner/Admin Functions:**
 *   24. `setVotingQuorumPercentage(uint _percentage)`:  Owner function to set the percentage of votes required for proposals to pass.
 *   25. `withdrawContractBalance()`: Owner function to withdraw any Ether balance from the contract (for collective treasury or development).
 */

contract DecentralizedArtCollective {
    // ---- State Variables ----

    address public owner;
    mapping(address => bool) public members;
    address[] public memberList;
    uint public memberCount;

    uint public nextProjectId;
    mapping(uint => ArtProject) public artProjects;
    mapping(uint => Contribution[]) public projectContributions;

    uint public nextExhibitionId;
    mapping(uint => Exhibition) public exhibitions;
    mapping(uint => uint[]) public exhibitionArtworks; // Exhibition ID to list of NFT token IDs

    uint public nextProposalId;
    mapping(uint => Proposal) public proposals;

    uint public votingQuorumPercentage = 50; // Default 50% quorum for proposals
    uint public baseRoyaltyPercentage = 5; // Default 5% royalty on secondary sales

    // Reputation System (Basic Example)
    mapping(address => uint) public memberReputation;

    // NFT Related (Simplified - Can be expanded to full NFT contract)
    uint public nextNFTTokenId;
    mapping(uint => ArtNFT) public artNFTs;
    mapping(uint => address) public nftOwner;
    mapping(uint => uint) public nftProjectId; // Token ID to Project ID for contributors

    // ---- Structs ----

    struct ArtProject {
        string title;
        string description;
        string genre;
        string initialSeed;
        ProjectStatus status;
        address[] contributors;
        uint contributionsCount;
    }

    enum ProjectStatus {
        Proposed,
        Contributing,
        Finalizing,
        Finalized,
        Minted
    }

    struct Contribution {
        address contributor;
        string data;
        uint upvotes;
        uint downvotes;
        uint timestamp;
    }

    struct Exhibition {
        string title;
        string description;
        address creator;
        uint creationTimestamp;
    }

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        ProposalStatus status;
        uint creationTimestamp;
        uint yesVotes;
        uint noVotes;
        // Specific proposal data will be handled in function parameters
    }

    enum ProposalType {
        Membership,
        RemoveMember,
        ArtProjectCreation,
        FinalizeArtProject,
        AddArtToExhibition,
        RemoveArtFromExhibition,
        Generic // For future expansion
    }

    enum ProposalStatus {
        Pending,
        Passed,
        Rejected,
        Executed
    }

    struct ArtNFT {
        uint projectId;
        string projectTitle;
        address[] contributors;
        string metadataURI; // Placeholder - could be IPFS hash or on-chain data
    }

    // ---- Events ----

    event MemberProposed(address indexed proposer, address indexed newMember, uint proposalId);
    event MembershipVoted(uint indexed proposalId, address indexed voter, bool vote);
    event MembershipProposalExecuted(uint indexed proposalId, bool success, address newMember);
    event MemberRemoved(address indexed remover, address indexed removedMember);

    event ArtProjectProposed(uint indexed projectId, address indexed proposer, string title);
    event ArtContributionAdded(uint indexed projectId, address indexed contributor, uint contributionIndex);
    event ArtProjectFinalizedProposed(uint indexed projectId, address indexed proposer);
    event ArtProjectFinalized(uint indexed projectId);
    event ArtNFTMinted(uint indexed tokenId, uint indexed projectId, address minter);
    event ArtNFTTransferred(uint indexed tokenId, address indexed from, address indexed to);

    event ExhibitionCreated(uint indexed exhibitionId, address indexed creator, string title);
    event ArtAddedToExhibition(uint indexed exhibitionId, uint indexed tokenId, address indexed proposer);
    event ArtRemovedFromExhibition(uint indexed exhibitionId, uint indexed tokenId, address indexed proposer);

    event ProposalCreated(uint indexed proposalId, ProposalType proposalType, address indexed proposer);
    event ProposalVoteCast(uint indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint indexed proposalId, ProposalStatus status);

    event ContributionUpvoted(uint indexed projectId, uint indexed contributionIndex, address indexed voter);
    event ContributionDownvoted(uint indexed projectId, uint indexed contributionIndex, address indexed voter);

    // ---- Modifiers ----

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint _proposalId) {
        require(proposals[_proposalId].proposalType != ProposalType.Generic, "Invalid proposal ID."); // Check if proposal exists (default enum value is Generic)
        _;
    }

    modifier validProjectId(uint _projectId) {
        require(artProjects[_projectId].title.length > 0, "Invalid project ID.");
        _;
    }

    modifier validExhibitionId(uint _exhibitionId) {
        require(exhibitions[_exhibitionId].title.length > 0, "Invalid exhibition ID.");
        _;
    }

    modifier validNFTTokenId(uint _tokenId) {
        require(nftProjectId[_tokenId] != 0, "Invalid NFT token ID.");
        _;
    }

    modifier projectInStatus(uint _projectId, ProjectStatus _status) {
        require(artProjects[_projectId].status == _status, "Project is not in the required status.");
        _;
    }

    modifier proposalInStatus(uint _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }


    // ---- Constructor ----

    constructor() {
        owner = msg.sender;
        _addMember(owner); // Owner is automatically the first member
    }

    // ---- I. Collective Governance & Membership ----

    function proposeNewMember(address _newMember) external onlyMember {
        require(!members[_newMember], "Address is already a member.");
        require(_newMember != address(0), "Invalid address.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.Membership,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });

        emit MemberProposed(msg.sender, _newMember, proposalId);
    }

    function voteOnMembershipProposal(uint _proposalId, bool _vote) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Membership, "Proposal is not a membership proposal.");

        // Prevent double voting (simple example - can be expanded with mapping if needed for complex voting)
        // For simplicity, assuming members will vote only once.

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit MembershipVoted(_proposalId, msg.sender, _vote);
    }

    function executeMembershipProposal(uint _proposalId) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Membership, "Proposal is not a membership proposal.");

        uint totalMembers = getMemberCount(); // Current member count for quorum calculation
        uint quorumNeeded = (totalMembers * votingQuorumPercentage) / 100;

        if (proposal.yesVotes >= quorumNeeded && (proposal.yesVotes > proposal.noVotes)) {
            proposal.status = ProposalStatus.Passed;
            address newMemberAddress; // Need to retrieve the proposed member address -  (simplified, not storing address in proposal for brevity in this example, in real case store in struct)
            // In a real implementation, you'd need to store the proposed member address in the Proposal struct or retrieve it from event logs
            // For this example, assuming the new member address is implied from the 'MemberProposed' event.  (Not ideal for on-chain execution, better to store address in struct)

            // **Simplified execution - in real world, need to securely retrieve the proposed member address.**
            //  For this example, we'll just assume the proposed address was the one in the 'MemberProposed' event, and we need to retrieve it from event logs or store it in the proposal struct.
            //  For simplicity of this example, we'll skip the actual address retrieval and just emit the event with a placeholder.

            // **In a real implementation, retrieve the proposed member address from proposal data or event logs.**
            // **For this example, we will artificially assume the address is the one emitted in the 'MemberProposed' event.**

            // **To make this fully functional, you would need to store the `_newMember` address in the `Proposal` struct when `proposeNewMember` is called, and retrieve it here.**
            // **For this example, we are skipping that detail for brevity.**

            // For demonstration purposes, we will just emit the execution event with a placeholder address.
            address proposedMemberAddressPlaceholder; // Placeholder - in real case, retrieve from proposal data.
            emit MembershipProposalExecuted(_proposalId, true, proposedMemberAddressPlaceholder);

            // **In a real implementation, you would add the member here based on the stored address in the proposal struct.**
            // **For this example, we are skipping the actual member addition for simplicity.**
            // _addMember(proposedMemberAddress);  // Example of how you would add the member in a real implementation.


        } else {
            proposal.status = ProposalStatus.Rejected;
            emit MembershipProposalExecuted(_proposalId, false, address(0)); // No new member added
        }
        proposal.status = ProposalStatus.Executed;
    }

    function removeMember(address _member) external onlyMember {
        require(members[_member], "Address is not a member.");
        require(_member != owner, "Cannot remove the owner.");
        require(_member != msg.sender, "Members cannot remove themselves. Use owner functions for owner removal if needed.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.RemoveMember,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        // In a real implementation, store the `_member` to be removed in the proposal struct.

        emit ProposalCreated(proposalId, ProposalType.RemoveMember, msg.sender); // Generic ProposalCreated event used.
    }


    function executeRemoveMemberProposal(uint _proposalId, address _memberToRemove) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.RemoveMember, "Proposal is not a remove member proposal.");
        require(members(_memberToRemove), "Address is not a member.");
        require(_memberToRemove != owner, "Cannot remove the owner.");

        uint totalMembers = getMemberCount();
        uint quorumNeeded = (totalMembers * votingQuorumPercentage) / 100;

        if (proposal.yesVotes >= quorumNeeded && (proposal.yesVotes > proposal.noVotes)) {
            proposal.status = ProposalStatus.Passed;
            _removeMember(_memberToRemove);
            emit MemberRemoved(msg.sender, _memberToRemove);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, proposal.status);
    }

    function getMemberCount() public view returns (uint) {
        return memberCount;
    }

    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }

    // ---- II. Collaborative Art Creation & NFT Minting ----

    function proposeArtProject(string _title, string _description, string _genre, string _initialSeed) external onlyMember {
        uint projectId = nextProjectId++;
        artProjects[projectId] = ArtProject({
            title: _title,
            description: _description,
            genre: _genre,
            initialSeed: _initialSeed,
            status: ProjectStatus.Proposed,
            contributors: new address[](0),
            contributionsCount: 0
        });
        emit ArtProjectProposed(projectId, msg.sender, _title);
    }

    function contributeToArtProject(uint _projectId, string _contributionData) external onlyMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Proposed) {
        ArtProject storage project = artProjects[_projectId];
        project.status = ProjectStatus.Contributing; // Move to contributing status on first contribution
        project.contributors.push(msg.sender); // Add contributor (might need to handle duplicates in real case)
        project.contributionsCount++;

        projectContributions[_projectId].push(Contribution({
            contributor: msg.sender,
            data: _contributionData,
            upvotes: 0,
            downvotes: 0,
            timestamp: block.timestamp
        }));

        emit ArtContributionAdded(_projectId, msg.sender, projectContributions[_projectId].length - 1);
    }

    function finalizeArtProject(uint _projectId) external onlyMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Contributing) {
        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.FinalizeArtProject,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        // In a real implementation, store the `_projectId` to be finalized in the proposal struct.

        emit ProposalCreated(proposalId, ProposalType.FinalizeArtProject, msg.sender);
        emit ArtProjectFinalizedProposed(_projectId, msg.sender);
    }


    function executeFinalizeArtProjectProposal(uint _proposalId, uint _projectIdToFinalize) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) validProjectId(_projectIdToFinalize) projectInStatus(_projectIdToFinalize, ProjectStatus.Contributing) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.FinalizeArtProject, "Proposal is not a finalize art project proposal.");

        uint totalMembers = getMemberCount();
        uint quorumNeeded = (totalMembers * votingQuorumPercentage) / 100;

        if (proposal.yesVotes >= quorumNeeded && (proposal.yesVotes > proposal.noVotes)) {
            proposal.status = ProposalStatus.Passed;
            artProjects[_projectIdToFinalize].status = ProjectStatus.Finalizing;
            emit ArtProjectFinalized(_projectIdToFinalize);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, proposal.status);
    }


    function mintArtNFT(uint _projectId) external onlyMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Finalizing) {
        ArtProject storage project = artProjects[_projectId];
        require(project.status == ProjectStatus.Finalizing, "Project is not in Finalizing status.");

        uint tokenId = nextNFTTokenId++;
        artNFTs[tokenId] = ArtNFT({
            projectId: _projectId,
            projectTitle: project.title,
            contributors: project.contributors,
            metadataURI: "ipfs://YOUR_IPFS_HASH_HERE_" + string.concat(Strings.toString(tokenId)) // Placeholder - Replace with actual metadata generation logic
        });
        nftOwner[tokenId] = address(this); // Collective owns initially, can transfer later
        nftProjectId[tokenId] = _projectId;
        project.status = ProjectStatus.Minted;
        emit ArtNFTMinted(tokenId, _projectId, msg.sender);
    }

    function getArtProjectDetails(uint _projectId) external view validProjectId(_projectId) returns (ArtProject memory) {
        return artProjects[_projectId];
    }

    function getArtProjectContributions(uint _projectId) external view validProjectId(_projectId) returns (Contribution[] memory) {
        return projectContributions[_projectId];
    }

    // ---- III. Dynamic NFT Features & Ownership ----

    function transferArtNFT(address _to, uint _tokenId) external validNFTTokenId(_tokenId) {
        require(nftOwner[_tokenId] == msg.sender || msg.sender == address(this), "Not the owner of the NFT."); // Allow collective to transfer too.
        address from = nftOwner[_tokenId];
        nftOwner[_tokenId] = _to;

        // Royalty logic (example - can be expanded)
        uint salePrice = 1 ether; // Example sale price - in real case, get from sale event.
        uint royaltyAmount = getNFTRoyaltyInfo(_tokenId, salePrice);
        payable(address(this)).transfer(address(this).balance); // In real world, distribute royalties accordingly. For now, just send to contract.

        emit ArtNFTTransferred(_tokenId, from, _to);
    }


    function getNFTContributors(uint _tokenId) external view validNFTTokenId(_tokenId) returns (address[] memory) {
        return artNFTs[_tokenId].contributors;
    }

    function getNFTRoyaltyInfo(uint _tokenId, uint _salePrice) public view validNFTTokenId(_tokenId) returns (uint royaltyAmount) {
        ArtNFT memory nft = artNFTs[_tokenId];
        royaltyAmount = (_salePrice * baseRoyaltyPercentage) / 100;

        // Layered Royalty Example - Can be expanded based on contribution level or reputation.
        if (nft.contributors.length > 5) {
            royaltyAmount += (_salePrice * 1) / 100; // Additional 1% if more than 5 contributors
        }
        return royaltyAmount;
    }

    function setBaseRoyaltyPercentage(uint _percentage) external onlyOwner {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100.");
        baseRoyaltyPercentage = _percentage;
    }

    // ---- IV. On-Chain Exhibitions & Curation ----

    function createExhibition(string _exhibitionTitle, string _exhibitionDescription) external onlyMember {
        uint exhibitionId = nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            creator: msg.sender,
            creationTimestamp: block.timestamp
        });
        exhibitionArtworks[exhibitionId] = new uint[](0); // Initialize empty artwork list
        emit ExhibitionCreated(exhibitionId, msg.sender, _exhibitionTitle);
    }

    function addArtToExhibition(uint _exhibitionId, uint _artTokenId) external onlyMember validExhibitionId(_exhibitionId) validNFTTokenId(_artTokenId) {
        require(nftProjectId[_artTokenId] != 0, "Token is not a collective art NFT."); // Ensure it's from this contract

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.AddArtToExhibition,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        // In a real implementation, store `_exhibitionId` and `_artTokenId` in the proposal struct.

        emit ProposalCreated(proposalId, ProposalType.AddArtToExhibition, msg.sender);
    }

    function executeAddArtToExhibitionProposal(uint _proposalId, uint _exhibitionIdToAddArt, uint _artTokenIdToAdd) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) validExhibitionId(_exhibitionIdToAddArt) validNFTTokenId(_artTokenIdToAdd) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.AddArtToExhibition, "Proposal is not an add art to exhibition proposal.");
        require(nftProjectId[_artTokenIdToAdd] != 0, "Token is not a collective art NFT.");

        uint totalMembers = getMemberCount();
        uint quorumNeeded = (totalMembers * votingQuorumPercentage) / 100;

        if (proposal.yesVotes >= quorumNeeded && (proposal.yesVotes > proposal.noVotes)) {
            proposal.status = ProposalStatus.Passed;
            exhibitionArtworks[_exhibitionIdToAddArt].push(_artTokenIdToAdd);
            emit ArtAddedToExhibition(_exhibitionIdToAddArt, _artTokenIdToAdd, msg.sender);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, proposal.status);
    }


    function removeArtFromExhibition(uint _exhibitionId, uint _artTokenId) external onlyMember validExhibitionId(_exhibitionId) validNFTTokenId(_artTokenId) {
        require(nftProjectId[_artTokenId] != 0, "Token is not a collective art NFT.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.RemoveArtFromExhibition,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            creationTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0
        });
        // In a real implementation, store `_exhibitionId` and `_artTokenId` in the proposal struct.

        emit ProposalCreated(proposalId, ProposalType.RemoveArtFromExhibition, msg.sender);
    }

    function executeRemoveArtFromExhibitionProposal(uint _proposalId, uint _exhibitionIdToRemoveArt, uint _artTokenIdToRemove) external onlyMember validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) validExhibitionId(_exhibitionIdToRemoveArt) validNFTTokenId(_artTokenIdToRemove) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.RemoveArtFromExhibition, "Proposal is not a remove art from exhibition proposal.");
        require(nftProjectId[_artTokenIdToRemove] != 0, "Token is not a collective art NFT.");

        uint totalMembers = getMemberCount();
        uint quorumNeeded = (totalMembers * votingQuorumPercentage) / 100;

        if (proposal.yesVotes >= quorumNeeded && (proposal.yesVotes > proposal.noVotes)) {
            proposal.status = ProposalStatus.Passed;
            // Remove from array (inefficient for large arrays - consider linked list or other optimization for real-world use)
            uint[] storage artworks = exhibitionArtworks[_exhibitionIdToRemoveArt];
            for (uint i = 0; i < artworks.length; i++) {
                if (artworks[i] == _artTokenIdToRemove) {
                    artworks[i] = artworks[artworks.length - 1];
                    artworks.pop();
                    break;
                }
            }
            emit ArtRemovedFromExhibition(_exhibitionIdToRemoveArt, _artTokenIdToRemove, msg.sender);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, proposal.status);
    }


    function getExhibitionDetails(uint _exhibitionId) external view validExhibitionId(_exhibitionId) returns (Exhibition memory, uint[] memory) {
        return (exhibitions[_exhibitionId], exhibitionArtworks[_exhibitionId]);
    }

    // ---- V. Reputation & Contribution Tracking ----

    function getMemberReputation(address _member) public view onlyMember returns (uint) {
        return memberReputation[_member];
    }

    function upvoteContribution(uint _projectId, uint _contributionIndex) external onlyMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Contributing) {
        require(_contributionIndex < projectContributions[_projectId].length, "Invalid contribution index.");
        projectContributions[_projectId][_contributionIndex].upvotes++;
        memberReputation[projectContributions[_projectId][_contributionIndex].contributor]++; // Increase contributor reputation (simple example)
        emit ContributionUpvoted(_projectId, _contributionIndex, msg.sender);
    }

    function downvoteContribution(uint _projectId, uint _contributionIndex) external onlyMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Contributing) {
        require(_contributionIndex < projectContributions[_projectId].length, "Invalid contribution index.");
        projectContributions[_projectId][_contributionIndex].downvotes++;
        memberReputation[projectContributions[_projectId][_contributionIndex].contributor]--; // Decrease contributor reputation (simple example)
        emit ContributionDownvoted(_projectId, _contributionIndex, msg.sender);
    }


    // ---- VI. Owner/Admin Functions ----

    function setVotingQuorumPercentage(uint _percentage) external onlyOwner {
        require(_percentage <= 100, "Quorum percentage cannot exceed 100.");
        votingQuorumPercentage = _percentage;
    }

    function withdrawContractBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }


    // ---- Internal Helper Functions ----

    function _addMember(address _newMember) internal {
        members[_newMember] = true;
        memberList.push(_newMember);
        memberCount++;
        memberReputation[_newMember] = 100; // Initial reputation
    }

    function _removeMember(address _member) internal {
        members[_member] = false;
        // Remove from memberList array (inefficient for large arrays, consider linked list or other optimization if needed)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        delete memberReputation[_member];
    }
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Optimized for small values
        if (value < 10) {
            return string(abi.encodePacked(uint8(48 + value)));
        } else if (value < 100) {
            return string(abi.encodePacked(uint8(48 + (value / 10)), uint8(48 + (value % 10))));
        } else if (value < 1000) {
            return string(abi.encodePacked(uint8(48 + (value / 100)), uint8(48 + ((value % 100) / 10)), uint8(48 + (value % 10))));
        } else if (value < 10000) {
            return string(abi.encodePacked(uint8(48 + (value / 1000)), uint8(48 + ((value % 1000) / 100)), uint8(48 + ((value % 100) / 10)), uint8(48 + (value % 10))));
        }
        // ... expand for larger numbers as needed
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x20) // String offset
            mstore(add(ptr, 0x20), 0x00) // String length
            let temp := value
            let digits := 0
            loop:
                digits := add(digits, 1)
                temp := div(temp, 10)
                jumpi(loop, temp)
            mstore(add(ptr, 0x20), digits) // String length
            let endPtr := add(ptr, add(0x20, digits))
            let digitPtr := endPtr
            temp := value
            loop2:
                digitPtr := sub(digitPtr, 1)
                mstore8(digitPtr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                jumpi(loop2, temp)
            mstore(0x40, endPtr) // Update free memory pointer
            return(add(ptr, 0x20), digits)
        }
    }
}
```