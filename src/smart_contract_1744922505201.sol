```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Art Collective.
 * It enables artists to mint NFTs, participate in community governance,
 * collaborate on projects, earn royalties, and engage in a decentralized art ecosystem.
 *
 * **Outline:**
 *
 * **1. Art NFT Management:**
 *    - mintArtNFT: Mint a new Art NFT.
 *    - setArtMetadata: Update the metadata URI of an Art NFT.
 *    - transferArtOwnership: Transfer ownership of an Art NFT.
 *    - burnArtNFT: Burn an Art NFT.
 *    - getArtDetails: Retrieve detailed information about an Art NFT.
 *
 * **2. Collective Governance & Membership:**
 *    - proposeNewMember: Propose a new artist to join the collective.
 *    - voteOnMembershipProposal: Vote on a membership proposal.
 *    - becomeCollectiveMember: Allow approved members to finalize joining.
 *    - removeCollectiveMember: Remove a member from the collective (governance vote).
 *    - getCollectiveMembers: Get a list of current collective members.
 *
 * **3. Collaborative Art Projects:**
 *    - proposeCollaborationProject: Propose a new collaborative art project.
 *    - contributeToProject: Artists contribute resources (NFTs, tokens) to a project.
 *    - voteOnProjectMilestoneCompletion: Vote on completion of project milestones.
 *    - distributeProjectRewards: Distribute rewards upon successful project completion.
 *    - getProjectDetails: Retrieve details about a collaborative project.
 *
 * **4. Exhibition and Gallery Features:**
 *    - proposeNewExhibition: Propose a new virtual art exhibition.
 *    - voteOnExhibitionProposal: Vote on an exhibition proposal.
 *    - addArtToExhibition: Add an Art NFT to an approved exhibition.
 *    - removeArtFromExhibition: Remove an Art NFT from an exhibition.
 *    - getExhibitionDetails: Get details about a specific exhibition.
 *    - listExhibitionArt: List Art NFTs in a specific exhibition.
 *
 * **5. Reputation and Artist Ranking:**
 *    - endorseArtist: Collective members endorse another artist's work/reputation.
 *    - getArtistEndorsements: View the number of endorsements an artist has received.
 *    - getTopArtists: Get a list of top-ranked artists based on endorsements.
 *
 * **6.  Financial and Royalty Management:**
 *    - setRoyaltyPercentage: Set the royalty percentage for Art NFTs (governance).
 *    - withdrawRoyalties: Artists can withdraw their accumulated royalties.
 *    - contributeToCollectiveFund: Members can contribute to a collective fund.
 *    - withdrawFromCollectiveFund: (Governance controlled) Withdraw funds for collective initiatives.
 *
 * **Function Summary:**
 *
 * **Art NFT Management:**
 *   - `mintArtNFT(address _artist, string memory _metadataURI)`: Allows collective members to mint Art NFTs, assigning artist and metadata.
 *   - `setArtMetadata(uint256 _tokenId, string memory _metadataURI)`: Allows the artist (or governance) to update NFT metadata.
 *   - `transferArtOwnership(uint256 _tokenId, address _to)`:  Standard NFT transfer, restricted to owner or approved operator.
 *   - `burnArtNFT(uint256 _tokenId)`: Allows the NFT owner to burn their Art NFT.
 *   - `getArtDetails(uint256 _tokenId)`: Returns details (artist, metadata URI) of a given Art NFT.
 *
 * **Collective Governance & Membership:**
 *   - `proposeNewMember(address _newMember)`:  Allows any member to propose a new artist for membership.
 *   - `voteOnMembershipProposal(uint256 _proposalId, bool _vote)`: Members vote on pending membership proposals.
 *   - `becomeCollectiveMember()`:  Approved members call this to finalize their membership.
 *   - `removeCollectiveMember(address _memberToRemove)`:  Propose removal of a member; requires governance voting.
 *   - `getCollectiveMembers()`:  Returns an array of addresses of current collective members.
 *
 * **Collaborative Art Projects:**
 *   - `proposeCollaborationProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, uint256 _milestoneCount)`: Members propose collaborative projects with details, funding goals, and milestones.
 *   - `contributeToProject(uint256 _projectId, uint256 _contributionAmount)`: Members contribute ETH to a project.  (Can be extended to NFTs or other tokens).
 *   - `voteOnProjectMilestoneCompletion(uint256 _projectId, uint256 _milestoneId, bool _vote)`: Members vote to approve project milestone completion.
 *   - `distributeProjectRewards(uint256 _projectId)`: Distributes project funds to contributors upon successful completion (all milestones approved).
 *   - `getProjectDetails(uint256 _projectId)`: Returns details of a collaborative project (name, description, funding, milestones, contributors).
 *
 * **Exhibition and Gallery Features:**
 *   - `proposeNewExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startDate, uint256 _endDate)`: Members propose new virtual exhibitions.
 *   - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Members vote on exhibition proposals.
 *   - `addArtToExhibition(uint256 _exhibitionId, uint256 _artTokenId)`:  Add approved Art NFTs to a specific exhibition.
 *   - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artTokenId)`: Remove Art NFTs from an exhibition.
 *   - `getExhibitionDetails(uint256 _exhibitionId)`: Returns details of an exhibition (name, description, dates, status).
 *   - `listExhibitionArt(uint256 _exhibitionId)`: Returns a list of Art NFT token IDs in a given exhibition.
 *
 * **Reputation and Artist Ranking:**
 *   - `endorseArtist(address _artistToEndorse)`:  Collective members can endorse other members to boost reputation.
 *   - `getArtistEndorsements(address _artist)`: Returns the endorsement count for a given artist.
 *   - `getTopArtists(uint256 _count)`: Returns a list of top artists ranked by endorsements.
 *
 * **Financial and Royalty Management:**
 *   - `setRoyaltyPercentage(uint256 _newRoyaltyPercentage)`:  Governance function to set the royalty percentage for secondary sales of Art NFTs.
 *   - `withdrawRoyalties()`: Artists can withdraw their accumulated royalties from secondary sales.
 *   - `contributeToCollectiveFund()`: Members can contribute ETH to a general collective fund.
 *   - `withdrawFromCollectiveFund(uint256 _amount)`: (Governance) Withdraw ETH from the collective fund for approved purposes.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _artTokenIds;
    Counters.Counter private _membershipProposalIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _exhibitionProposalIds;

    string public constant CONTRACT_NAME = "Decentralized Autonomous Art Collective";
    string public constant CONTRACT_SYMBOL = "DAAC";

    uint256 public royaltyPercentage = 5; // Default royalty percentage (5%)

    // --- Data Structures ---

    struct ArtNFT {
        address artist;
        string metadataURI;
    }
    mapping(uint256 => ArtNFT) public artNFTs;

    struct MembershipProposal {
        address proposer;
        address newMember;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }
    mapping(uint256 => MembershipProposal) public membershipProposals;
    Counters.Counter public membershipProposalCounter;

    mapping(address => bool) public isCollectiveMember;
    address[] public collectiveMembers;

    struct CollaborationProject {
        string projectName;
        string projectDescription;
        address proposer;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 milestoneCount;
        uint256 completedMilestones;
        mapping(address => uint256) contributors; // Address -> Contribution Amount
        bool isActive;
    }
    mapping(uint256 => CollaborationProject) public collaborationProjects;
    Counters.Counter public projectCounter;

    struct ExhibitionProposal {
        string exhibitionName;
        string exhibitionDescription;
        address proposer;
        uint256 startDate;
        uint256 endDate;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    Counters.Counter public exhibitionProposalCounter;

    struct Exhibition {
        string exhibitionName;
        string exhibitionDescription;
        uint256 startDate;
        uint256 endDate;
        address proposer;
        uint256 proposalId; // Link back to the proposal
        uint256[] artTokenIds;
        bool isActive;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    Counters.Counter public exhibitionCounter;

    mapping(address => uint256) public artistEndorsements;

    mapping(uint256 => uint256) public artTokenRoyalties; // Token ID -> Accumulated Royalties

    uint256 public collectiveFundBalance;

    // --- Events ---

    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtMetadataUpdated(uint256 tokenId, string metadataURI);
    event MembershipProposed(uint256 proposalId, address proposer, address newMember);
    event MembershipVoteCast(uint256 proposalId, address voter, bool vote);
    event MemberJoinedCollective(address member);
    event MemberRemovedFromCollective(address member);
    event CollaborationProjectProposed(uint256 projectId, string projectName, address proposer);
    event ProjectContributionMade(uint256 projectId, address contributor, uint256 amount);
    event MilestoneVoteCast(uint256 projectId, uint256 milestoneId, address voter, bool vote);
    event ProjectRewardsDistributed(uint256 projectId);
    event ExhibitionProposed(uint256 proposalId, string exhibitionName, address proposer);
    event ExhibitionVoteCast(uint256 proposalId, address voter, bool vote);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artTokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artTokenId);
    event ArtistEndorsed(address endorser, address endorsedArtist);
    event RoyaltyPercentageSet(uint256 newPercentage);
    event RoyaltiesWithdrawn(address artist, uint256 amount);
    event CollectiveFundContribution(address contributor, uint256 amount);
    event CollectiveFundWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyCollectiveMember() {
        require(isCollectiveMember[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId, ProposalType _proposalType) {
        address proposer;
        if (_proposalType == ProposalType.Membership) {
            proposer = membershipProposals[_proposalId].proposer;
        } else if (_proposalType == ProposalType.Exhibition) {
            proposer = exhibitionProposals[_proposalId].proposer;
        } else {
            revert("Invalid proposal type");
        }
        require(msg.sender == proposer, "Only proposal proposer can call this function");
        _;
    }

    enum ProposalType {
        Membership,
        Exhibition
    }

    // --- Constructor ---
    constructor() ERC721(CONTRACT_NAME, CONTRACT_SYMBOL) {
        // The contract deployer is the initial owner and collective member
        _transferOwnership(msg.sender);
        isCollectiveMember[msg.sender] = true;
        collectiveMembers.push(msg.sender);
    }

    // --- 1. Art NFT Management ---

    function mintArtNFT(address _artist, string memory _metadataURI) public onlyCollectiveMember returns (uint256) {
        _artTokenIds.increment();
        uint256 tokenId = _artTokenIds.current();
        _mint(_artist, tokenId);
        artNFTs[tokenId] = ArtNFT({artist: _artist, metadataURI: _metadataURI});
        emit ArtNFTMinted(tokenId, _artist, _metadataURI);
        return tokenId;
    }

    function setArtMetadata(uint256 _tokenId, string memory _metadataURI) public {
        require(_exists(_tokenId), "Token does not exist");
        require(msg.sender == artNFTs[_tokenId].artist || msg.sender == owner(), "Not artist or owner"); // Artist or governance can update
        artNFTs[_tokenId].metadataURI = _metadataURI;
        emit ArtMetadataUpdated(_tokenId, _metadataURI);
    }

    // Override transferFrom to implement royalty logic on secondary sales
    function transferFrom(address from, address to, uint256 tokenId) public override payable {
        super.transferFrom(from, to, tokenId);
        // Check if it's a secondary sale (from != original minter)
        if (from != artNFTs[tokenId].artist) {
            uint256 salePrice = msg.value; // Assuming sale price is sent with transfer
            uint256 royaltyAmount = salePrice.mul(royaltyPercentage).div(100);
            artTokenRoyalties[tokenId] = artTokenRoyalties[tokenId].add(royaltyAmount);
            payable(artNFTs[tokenId].artist).transfer(royaltyAmount); // Pay royalty to artist
        }
    }

    function burnArtNFT(uint256 _tokenId) public {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner or approved");
        _burn(_tokenId);
    }

    function getArtDetails(uint256 _tokenId) public view returns (address artist, string memory metadataURI) {
        require(_exists(_tokenId), "Token does not exist");
        return (artNFTs[_tokenId].artist, artNFTs[_tokenId].metadataURI);
    }

    // --- 2. Collective Governance & Membership ---

    function proposeNewMember(address _newMember) public onlyCollectiveMember {
        require(!isCollectiveMember[_newMember], "Address is already a member");
        _membershipProposalIds.increment();
        uint256 proposalId = _membershipProposalIds.current();
        membershipProposals[proposalId] = MembershipProposal({
            proposer: msg.sender,
            newMember: _newMember,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit MembershipProposed(proposalId, msg.sender, _newMember);
    }

    function voteOnMembershipProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember {
        require(membershipProposals[_proposalId].isActive, "Proposal is not active");
        require(membershipProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote"); // Proposer cannot vote
        require(!hasVotedOnProposal(_proposalId, msg.sender, ProposalType.Membership), "Already voted on this proposal");

        if (_vote) {
            membershipProposals[_proposalId].votesFor++;
        } else {
            membershipProposals[_proposalId].votesAgainst++;
        }
        emit MembershipVoteCast(_proposalId, msg.sender, _vote);

        // Check if proposal passes (simple majority for now)
        if (membershipProposals[_proposalId].votesFor > (getCollectiveMemberCount().div(2))) {
            membershipProposals[_proposalId].isActive = false; // Close proposal
        }
    }

    function becomeCollectiveMember() public {
        uint256 latestProposalId = _membershipProposalIds.current();
        require(membershipProposals[latestProposalId].newMember == msg.sender, "Not the proposed member");
        require(!isCollectiveMember[msg.sender], "Already a member");
        require(!membershipProposals[latestProposalId].isActive, "Membership proposal is still active"); // Proposal must have passed
        require(membershipProposals[latestProposalId].votesFor > (getCollectiveMemberCount().div(2)), "Membership proposal not approved");

        isCollectiveMember[msg.sender] = true;
        collectiveMembers.push(msg.sender);
        emit MemberJoinedCollective(msg.sender);
    }

    function removeCollectiveMember(address _memberToRemove) public onlyCollectiveMember {
        require(isCollectiveMember[_memberToRemove], "Address is not a member");
        require(_memberToRemove != owner(), "Cannot remove contract owner"); // Prevent removing owner without transferring ownership

        // Implementation for removing a member through governance vote would be more complex
        // (e.g., create a removal proposal, voting process similar to membership)
        // For simplicity, skipping the voting for removal in this basic example.
        // In a real DAO, member removal should be governed by a voting process.

        // Basic removal (without voting for simplicity in this example):
        for (uint256 i = 0; i < collectiveMembers.length; i++) {
            if (collectiveMembers[i] == _memberToRemove) {
                collectiveMembers[i] = collectiveMembers[collectiveMembers.length - 1];
                collectiveMembers.pop();
                break;
            }
        }
        isCollectiveMember[_memberToRemove] = false;
        emit MemberRemovedFromCollective(_memberToRemove);
    }

    function getCollectiveMembers() public view returns (address[] memory) {
        return collectiveMembers;
    }

    function getCollectiveMemberCount() public view returns (uint256) {
        return collectiveMembers.length;
    }

    // --- 3. Collaborative Art Projects ---

    function proposeCollaborationProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _fundingGoal,
        uint256 _milestoneCount
    ) public onlyCollectiveMember {
        _projectIds.increment();
        uint256 projectId = _projectIds.current();
        collaborationProjects[projectId] = CollaborationProject({
            projectName: _projectName,
            projectDescription: _projectDescription,
            proposer: msg.sender,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            milestoneCount: _milestoneCount,
            completedMilestones: 0,
            isActive: true
        });
        emit CollaborationProjectProposed(projectId, _projectName, msg.sender);
    }

    function contributeToProject(uint256 _projectId) public payable onlyCollectiveMember {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(collaborationProjects[_projectId].currentFunding < collaborationProjects[_projectId].fundingGoal, "Project funding goal reached");
        require(msg.value > 0, "Contribution amount must be greater than zero");

        collaborationProjects[_projectId].currentFunding = collaborationProjects[_projectId].currentFunding.add(msg.value);
        collaborationProjects[_projectId].contributors[msg.sender] = collaborationProjects[_projectId].contributors[msg.sender].add(msg.value);

        emit ProjectContributionMade(_projectId, msg.sender, msg.value);
    }

    function voteOnProjectMilestoneCompletion(uint256 _projectId, uint256 _milestoneId, bool _vote) public onlyCollectiveMember {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(_milestoneId <= collaborationProjects[_projectId].milestoneCount, "Invalid milestone ID");
        // Simple voting - for more robust voting, consider using a separate voting contract or library
        // For now, just increment completed milestones if vote is 'true' and majority votes

        // In a real system, you would track votes per milestone and have a voting period.
        // This is a simplified example.
        if (_vote) {
            collaborationProjects[_projectId].completedMilestones++;
            if (collaborationProjects[_projectId].completedMilestones >= collaborationProjects[_projectId].milestoneCount) {
                distributeProjectRewards(_projectId); // Automatically distribute rewards when all milestones are marked complete
            }
        }
        emit MilestoneVoteCast(_projectId, _milestoneId, msg.sender, _vote);
    }

    function distributeProjectRewards(uint256 _projectId) private {
        require(collaborationProjects[_projectId].isActive, "Project is not active");
        require(collaborationProjects[_projectId].completedMilestones == collaborationProjects[_projectId].milestoneCount, "Not all milestones completed");

        CollaborationProject storage project = collaborationProjects[_projectId];
        project.isActive = false; // Mark project as completed

        uint256 totalContributions = project.currentFunding;
        require(totalContributions > 0, "No contributions to distribute");

        // Simple proportional reward distribution based on contribution amount
        for (address contributor in getContributorAddresses(_projectId)) {
            uint256 contribution = project.contributors[contributor];
            uint256 rewardAmount = totalContributions.mul(contribution).div(totalContributions); // Proportional reward
            payable(contributor).transfer(rewardAmount);
        }
        emit ProjectRewardsDistributed(_projectId);
    }

    function getProjectDetails(uint256 _projectId) public view returns (
        string memory projectName,
        string memory projectDescription,
        address proposer,
        uint256 fundingGoal,
        uint256 currentFunding,
        uint256 milestoneCount,
        uint256 completedMilestones,
        bool isActive
    ) {
        CollaborationProject storage project = collaborationProjects[_projectId];
        return (
            project.projectName,
            project.projectDescription,
            project.proposer,
            project.fundingGoal,
            project.currentFunding,
            project.milestoneCount,
            project.completedMilestones,
            project.isActive
        );
    }

    function getContributorAddresses(uint256 _projectId) private view returns (address[] memory) {
        address[] memory contributors = new address[](collectiveMembers.length); // Max possible contributors
        uint256 contributorCount = 0;
        CollaborationProject storage project = collaborationProjects[_projectId];
        for (uint256 i = 0; i < collectiveMembers.length; i++) {
            if (project.contributors[collectiveMembers[i]] > 0) {
                contributors[contributorCount] = collectiveMembers[i];
                contributorCount++;
            }
        }
        address[] memory finalContributors = new address[](contributorCount);
        for (uint256 i = 0; i < contributorCount; i++) {
            finalContributors[i] = contributors[i];
        }
        return finalContributors;
    }


    // --- 4. Exhibition and Gallery Features ---

    function proposeNewExhibition(
        string memory _exhibitionName,
        string memory _exhibitionDescription,
        uint256 _startDate,
        uint256 _endDate
    ) public onlyCollectiveMember {
        _exhibitionProposalIds.increment();
        uint256 proposalId = _exhibitionProposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            exhibitionName: _exhibitionName,
            exhibitionDescription: _exhibitionDescription,
            proposer: msg.sender,
            startDate: _startDate,
            endDate: _endDate,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit ExhibitionProposed(proposalId, _exhibitionName, msg.sender);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember {
        require(exhibitionProposals[_proposalId].isActive, "Exhibition proposal is not active");
        require(exhibitionProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote"); // Proposer cannot vote
        require(!hasVotedOnProposal(_proposalId, msg.sender, ProposalType.Exhibition), "Already voted on this proposal");

        if (_vote) {
            exhibitionProposals[_proposalId].votesFor++;
        } else {
            exhibitionProposals[_proposalId].votesAgainst++;
        }
        emit ExhibitionVoteCast(_proposalId, msg.sender, _vote);

        // Check if proposal passes (simple majority for now)
        if (exhibitionProposals[_proposalId].votesFor > (getCollectiveMemberCount().div(2))) {
            exhibitionProposals[_proposalId].isActive = false; // Close proposal
            _createExhibition(_proposalId); // Create the exhibition if approved
        }
    }

    function _createExhibition(uint256 _proposalId) private {
        require(!exhibitionProposals[_proposalId].isActive, "Exhibition proposal is still active"); // Double check proposal is closed and passed
        require(exhibitionProposals[_proposalId].votesFor > (getCollectiveMemberCount().div(2)), "Exhibition proposal not approved");

        _exhibitionCounter.increment();
        uint256 exhibitionId = _exhibitionCounter.current();
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        exhibitions[exhibitionId] = Exhibition({
            exhibitionName: proposal.exhibitionName,
            exhibitionDescription: proposal.exhibitionDescription,
            startDate: proposal.startDate,
            endDate: proposal.endDate,
            proposer: proposal.proposer,
            proposalId: _proposalId,
            artTokenIds: new uint256[](0), // Initialize with empty array
            isActive: true
        });
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _artTokenId) public onlyCollectiveMember {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active");
        require(_exists(_artTokenId), "Art token does not exist");
        require(isCollectiveMember[artNFTs[_artTokenId].artist], "Art NFT artist is not a collective member"); // Ensure art is from a member

        exhibitions[_exhibitionId].artTokenIds.push(_artTokenId);
        emit ArtAddedToExhibition(_exhibitionId, _artTokenId);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artTokenId) public onlyCollectiveMember {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active");

        uint256[] storage artIds = exhibitions[_exhibitionId].artTokenIds;
        for (uint256 i = 0; i < artIds.length; i++) {
            if (artIds[i] == _artTokenId) {
                artIds[i] = artIds[artIds.length - 1];
                artIds.pop();
                emit ArtRemovedFromExhibition(_exhibitionId, _artTokenId);
                return;
            }
        }
        revert("Art token not found in exhibition");
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view returns (
        string memory exhibitionName,
        string memory exhibitionDescription,
        uint256 startDate,
        uint256 endDate,
        address proposer,
        bool isActive
    ) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        return (
            exhibition.exhibitionName,
            exhibition.exhibitionDescription,
            exhibition.startDate,
            exhibition.endDate,
            exhibition.proposer,
            exhibition.isActive
        );
    }

    function listExhibitionArt(uint256 _exhibitionId) public view returns (uint256[] memory) {
        return exhibitions[_exhibitionId].artTokenIds;
    }


    // --- 5. Reputation and Artist Ranking ---

    function endorseArtist(address _artistToEndorse) public onlyCollectiveMember {
        require(isCollectiveMember[_artistToEndorse], "Cannot endorse non-member");
        require(_artistToEndorse != msg.sender, "Cannot endorse yourself");

        artistEndorsements[_artistToEndorse]++;
        emit ArtistEndorsed(msg.sender, _artistToEndorse);
    }

    function getArtistEndorsements(address _artist) public view returns (uint256) {
        return artistEndorsements[_artist];
    }

    function getTopArtists(uint256 _count) public view returns (address[] memory) {
        address[] memory topArtists = new address[](_count);
        address[] memory allMembers = collectiveMembers; // Copy to avoid modifying original
        uint256 n = allMembers.length;

        // Basic bubble sort (can be optimized for larger member counts)
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (artistEndorsements[allMembers[j]] < artistEndorsements[allMembers[j + 1]]) {
                    // Swap
                    address temp = allMembers[j];
                    allMembers[j] = allMembers[j + 1];
                    allMembers[j + 1] = temp;
                }
            }
        }

        uint256 countToReturn = _count > n ? n : _count; // Return max available if _count is larger than member count
        for (uint256 i = 0; i < countToReturn; i++) {
            topArtists[i] = allMembers[i];
        }
        return topArtists;
    }

    // --- 6. Financial and Royalty Management ---

    function setRoyaltyPercentage(uint256 _newRoyaltyPercentage) public onlyOwner {
        require(_newRoyaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        royaltyPercentage = _newRoyaltyPercentage;
        emit RoyaltyPercentageSet(_newRoyaltyPercentage);
    }

    function withdrawRoyalties() public {
        uint256 artistRoyalties = 0;
        for (uint256 tokenId = 1; tokenId <= _artTokenIds.current(); tokenId++) {
            if (artNFTs[tokenId].artist == msg.sender) {
                artistRoyalties = artistRoyalties.add(artTokenRoyalties[tokenId]);
                artTokenRoyalties[tokenId] = 0; // Reset royalties after withdrawal
            }
        }
        require(artistRoyalties > 0, "No royalties to withdraw");
        payable(msg.sender).transfer(artistRoyalties);
        emit RoyaltiesWithdrawn(msg.sender, artistRoyalties);
    }

    function contributeToCollectiveFund() public payable onlyCollectiveMember {
        require(msg.value > 0, "Contribution amount must be greater than zero");
        collectiveFundBalance = collectiveFundBalance.add(msg.value);
        emit CollectiveFundContribution(msg.sender, msg.value);
    }

    function withdrawFromCollectiveFund(uint256 _amount) public onlyOwner {
        require(_amount <= collectiveFundBalance, "Insufficient collective fund balance");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        collectiveFundBalance = collectiveFundBalance.sub(_amount);
        payable(owner()).transfer(_amount); // Owner controlled withdrawal for collective purposes
        emit CollectiveFundWithdrawal(owner(), _amount);
    }

    // --- Helper function to check if an address has voted on a proposal ---
    function hasVotedOnProposal(uint256 _proposalId, address _voter, ProposalType _proposalType) private view returns (bool) {
        if (_proposalType == ProposalType.Membership) {
            MembershipProposal storage proposal = membershipProposals[_proposalId];
            // Simple check - for real voting, track voter addresses per proposal in a mapping or array
            // This basic example assumes each member can vote only once and doesn't store voter lists.
            return (proposal.votesFor > 0 || proposal.votesAgainst > 0) && (proposal.votesFor + proposal.votesAgainst) > 0; // Simple check if any votes have been cast.
        } else if (_proposalType == ProposalType.Exhibition) {
            ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
            return (proposal.votesFor > 0 || proposal.votesAgainst > 0) && (proposal.votesFor + proposal.votesAgainst) > 0;
        }
        return false; // Invalid proposal type.
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
    fallback() external payable {}
}
```