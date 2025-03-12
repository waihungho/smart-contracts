```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (OpenAI)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * This contract enables collective art creation, ownership, and governance by a community.
 * It features advanced concepts like dynamic royalty splitting, collaborative NFT creation,
 * decentralized curation, and on-chain reputation system.
 *
 * Function Summary:
 *
 * --- Core Collective Functions ---
 * 1. joinCollective(string _artistStatement) - Allows artists to apply for membership in the collective.
 * 2. voteOnMembership(address _artistAddress, bool _approve) - Members vote on new artist membership applications.
 * 3. proposeNewProject(string _projectTitle, string _projectDescription, string _projectProposalIPFSHash, uint256 _contributionDeadline) - Members propose new collaborative art projects.
 * 4. voteOnProjectProposal(uint256 _projectId, bool _approve) - Members vote on proposed art projects.
 * 5. contributeToProject(uint256 _projectId, string _contributionIPFSHash) - Members contribute creative assets/ideas to an approved project.
 * 6. finalizeProject(uint256 _projectId, string _finalArtIPFSHash) - Admin/Project Lead finalizes a project after sufficient contributions are received.
 * 7. mintCollectiveNFT(uint256 _projectId) - Mints a collective NFT representing the completed art project.
 * 8. listNFTForSale(uint256 _nftId, uint256 _price) - Allows the collective to list a generated NFT for sale.
 * 9. buyNFT(uint256 _nftId) - Allows anyone to purchase a collective NFT.
 * 10. withdrawCollectiveFunds() - Allows authorized members to withdraw funds from the collective treasury.
 *
 * --- Advanced & Creative Functions ---
 * 11. delegateVotingPower(address _delegateAddress) - Members can delegate their voting power to another member.
 * 12. proposeRoyaltySplit(uint256 _projectId, address[] memory _recipients, uint256[] memory _percentages) - Propose a custom royalty split for a specific project.
 * 13. voteOnRoyaltySplit(uint256 _splitProposalId, bool _approve) - Members vote on proposed royalty splits.
 * 14. setCurator(address _curatorAddress) - Appoint a curator to manage art exhibitions and external collaborations.
 * 15. proposeExhibition(string _exhibitionTitle, string _exhibitionDescription, string _exhibitionDetailsIPFSHash, uint256 _exhibitionStartDate) - Propose an art exhibition (virtual or physical).
 * 16. voteOnExhibition(uint256 _exhibitionId, bool _approve) - Members vote on proposed exhibitions.
 * 17. reportMemberContribution(address _memberAddress, uint256 _projectId, uint256 _contributionScore) - Members can report and score contributions of other members to build reputation.
 * 18. redeemReputationPoints(uint256 _pointsToRedeem) - Members can redeem reputation points for benefits (e.g., increased voting weight, access to exclusive projects).
 * 19. emergencyWithdrawal(address _recipient, uint256 _amount) - Admin function for emergency fund withdrawal in exceptional circumstances (requires multi-sig).
 * 20. setProjectLead(uint256 _projectId, address _newLead) - Designate a project lead for specific projects to oversee contribution and finalization.
 * 21. changeVotingQuorum(uint256 _newQuorumPercentage) - Allows changing the voting quorum for proposals (governance function).
 * 22. setMembershipFee(uint256 _newFee) - Set or update a membership fee (if collective decides to implement one).
 * 23. proposeParameterChange(string _parameterName, uint256 _newValue) - Generic function to propose changes to contract parameters (e.g., voting periods, fees).
 * 24. voteOnParameterChange(uint256 _parameterChangeId, bool _approve) - Members vote on proposed parameter changes.
 */

contract DecentralizedAutonomousArtCollective {

    // --- State Variables ---

    address public admin; // Contract administrator (can be a multi-sig wallet)
    string public collectiveName;
    uint256 public membershipFee; // Optional membership fee
    uint256 public votingQuorumPercentage = 50; // Default voting quorum

    mapping(address => bool) public isMember;
    address[] public members;
    mapping(address => string) public artistStatements;

    uint256 public nextProjectId = 1;
    struct ArtProject {
        string title;
        string description;
        string proposalIPFSHash;
        uint256 contributionDeadline;
        bool isActive;
        bool isFinalized;
        string finalArtIPFSHash;
        address projectLead;
    }
    mapping(uint256 => ArtProject) public projects;
    mapping(uint256 => address[]) public projectContributors;
    mapping(uint256 => mapping(address => string[])) public memberContributions; // projectId -> memberAddress -> contributionIPFSHashes

    uint256 public nextNftId = 1;
    mapping(uint256 => uint256) public nftProjectId; // nftId -> projectId
    mapping(uint256 => address) public nftOwner; // nftId -> owner (contract initially, then buyer)
    mapping(uint256 => uint256) public nftPrice; // nftId -> price (0 if not for sale)

    uint256 public nextMembershipVoteId = 1;
    struct MembershipVote {
        address artistAddress;
        bool isOpen;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => MembershipVote) public membershipVotes;

    uint256 public nextProjectProposalVoteId = 1;
    struct ProjectProposalVote {
        uint256 projectId;
        bool isOpen;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ProjectProposalVote) public projectProposalVotes;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProjectProposal; // projectId -> memberAddress -> voted

    uint256 public nextRoyaltySplitProposalId = 1;
    struct RoyaltySplitProposal {
        uint256 projectId;
        address[] recipients;
        uint256[] percentages;
        bool isOpen;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => RoyaltySplitProposal) public royaltySplitProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnRoyaltySplit; // splitProposalId -> memberAddress -> voted
    mapping(uint256 => mapping(address => uint256)) public projectNftRoyalties; // nftId -> recipient -> percentage (basis points)

    address public curator; // Optional curator address

    uint256 public nextExhibitionProposalId = 1;
    struct ExhibitionProposal {
        string title;
        string description;
        string detailsIPFSHash;
        uint256 startDate;
        bool isOpen;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnExhibition; // exhibitionId -> memberAddress -> voted

    mapping(address => uint256) public reputationPoints; // Member address -> reputation points

    uint256 public nextParameterChangeProposalId = 1;
    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        bool isOpen;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnParameterChange; // parameterChangeId -> memberAddress -> voted

    uint256 public collectiveTreasuryBalance;

    // --- Events ---

    event MembershipRequested(address artistAddress);
    event MembershipApproved(address artistAddress);
    event MembershipRejected(address artistAddress);
    event ProjectProposed(uint256 projectId, string title, address proposer);
    event ProjectProposalVoteStarted(uint256 projectId);
    event ProjectProposalApproved(uint256 projectId);
    event ProjectProposalRejected(uint256 projectId);
    event ContributionMade(uint256 projectId, address contributor, string contributionIPFSHash);
    event ProjectFinalized(uint256 projectId, string finalArtIPFSHash);
    event NFTMinted(uint256 nftId, uint256 projectId);
    event NFTListedForSale(uint256 nftId, uint256 price);
    event NFTBought(uint256 nftId, address buyer, uint256 price);
    event FundsWithdrawn(address recipient, uint256 amount);
    event VotingPowerDelegated(address delegator, address delegate);
    event RoyaltySplitProposed(uint256 splitProposalId, uint256 projectId);
    event RoyaltySplitApproved(uint256 splitProposalId);
    event RoyaltySplitRejected(uint256 splitProposalId);
    event CuratorSet(address curatorAddress);
    event ExhibitionProposed(uint256 exhibitionId, string title, address proposer);
    event ExhibitionProposalVoteStarted(uint256 exhibitionId);
    event ExhibitionApproved(uint256 exhibitionId);
    event ExhibitionRejected(uint256 exhibitionId);
    event ContributionReported(address reporter, address member, uint256 projectId, uint256 score);
    event ReputationPointsRedeemed(address member, uint256 pointsRedeemed);
    event EmergencyWithdrawalMade(address recipient, uint256 amount);
    event ProjectLeadSet(uint256 projectId, address newLead);
    event VotingQuorumChanged(uint256 newQuorumPercentage);
    event MembershipFeeChanged(uint256 newFee);
    event ParameterChangeProposed(uint256 parameterChangeId, string parameterName);
    event ParameterChangeApproved(uint256 parameterChangeId);
    event ParameterChangeRejected(uint256 parameterChangeId);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier validProject(uint256 _projectId) {
        require(projects[_projectId].isActive, "Project is not active or does not exist.");
        _;
    }

    modifier projectNotFinalized(uint256 _projectId) {
        require(!projects[_projectId].isFinalized, "Project is already finalized.");
        _;
    }

    modifier validNFT(uint256 _nftId) {
        require(nftProjectId[_nftId] != 0, "Invalid NFT ID.");
        _;
    }

    modifier nftOwnedByCollective(uint256 _nftId) {
        require(nftOwner[_nftId] == address(this), "NFT is not owned by the collective.");
        _;
    }

    modifier votingOpen(uint256 _voteId, VoteType _voteType) {
        if (_voteType == VoteType.Membership) {
            require(membershipVotes[_voteId].isOpen, "Membership vote is not open.");
        } else if (_voteType == VoteType.ProjectProposal) {
            require(projectProposalVotes[_voteId].isOpen, "Project proposal vote is not open.");
        } else if (_voteType == VoteType.RoyaltySplit) {
            require(royaltySplitProposals[_voteId].isOpen, "Royalty split vote is not open.");
        } else if (_voteType == VoteType.Exhibition) {
            require(exhibitionProposals[_voteId].isOpen, "Exhibition vote is not open.");
        } else if (_voteType == VoteType.ParameterChange) {
            require(parameterChangeProposals[_voteId].isOpen, "Parameter change vote is not open.");
        }
        _;
    }

    modifier notAlreadyVoted(uint256 _voteId, VoteType _voteType) {
        if (_voteType == VoteType.ProjectProposal) {
            require(!hasVotedOnProjectProposal[_voteId][msg.sender], "Already voted on this project proposal.");
        } else if (_voteType == VoteType.RoyaltySplit) {
            require(!hasVotedOnRoyaltySplit[_voteId][msg.sender], "Already voted on this royalty split.");
        } else if (_voteType == VoteType.Exhibition) {
            require(!hasVotedOnExhibition[_voteId][msg.sender], "Already voted on this exhibition.");
        } else if (_voteType == VoteType.ParameterChange) {
            require(!hasVotedOnParameterChange[_voteId][msg.sender], "Already voted on this parameter change.");
        }
        _;
    }


    enum VoteType { Membership, ProjectProposal, RoyaltySplit, Exhibition, ParameterChange }


    // --- Constructor ---

    constructor(string memory _collectiveName) {
        admin = msg.sender;
        collectiveName = _collectiveName;
    }

    // --- Core Collective Functions ---

    function joinCollective(string memory _artistStatement) public payable {
        if (membershipFee > 0) {
            require(msg.value >= membershipFee, "Membership fee required.");
        }
        require(!isMember[msg.sender], "Already a member.");
        artistStatements[msg.sender] = _artistStatement;
        membershipVotes[nextMembershipVoteId] = MembershipVote({
            artistAddress: msg.sender,
            isOpen: true,
            yesVotes: 0,
            noVotes: 0
        });
        emit MembershipRequested(msg.sender);
        nextMembershipVoteId++;
    }

    function voteOnMembership(uint256 _voteId, bool _approve) public onlyMember votingOpen(_voteId, VoteType.Membership) {
        MembershipVote storage vote = membershipVotes[_voteId];
        require(vote.artistAddress != address(0), "Invalid membership vote ID.");
        require(vote.artistAddress != msg.sender, "Cannot vote on your own membership.");

        if (_approve) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }

        uint256 totalMembers = members.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        uint256 totalVotes = vote.yesVotes + vote.noVotes;

        if (totalVotes >= quorum) { // Simple quorum based on total members voting. Can be adjusted.
            vote.isOpen = false;
            if (vote.yesVotes > vote.noVotes) {
                isMember[vote.artistAddress] = true;
                members.push(vote.artistAddress);
                emit MembershipApproved(vote.artistAddress);
            } else {
                emit MembershipRejected(vote.artistAddress);
            }
        }
    }

    function proposeNewProject(
        string memory _projectTitle,
        string memory _projectDescription,
        string memory _projectProposalIPFSHash,
        uint256 _contributionDeadline
    ) public onlyMember {
        projects[nextProjectId] = ArtProject({
            title: _projectTitle,
            description: _projectDescription,
            proposalIPFSHash: _projectProposalIPFSHash,
            contributionDeadline: block.timestamp + _contributionDeadline,
            isActive: true,
            isFinalized: false,
            finalArtIPFSHash: "",
            projectLead: msg.sender // Proposer becomes default project lead initially
        });
        projectProposalVotes[nextProjectProposalVoteId] = ProjectProposalVote({
            projectId: nextProjectId,
            isOpen: true,
            yesVotes: 0,
            noVotes: 0
        });
        emit ProjectProposed(nextProjectId, _projectTitle, msg.sender);
        nextProjectId++;
        nextProjectProposalVoteId++;
    }

    function voteOnProjectProposal(uint256 _voteId, bool _approve) public onlyMember votingOpen(_voteId, VoteType.ProjectProposal) notAlreadyVoted(_voteId, VoteType.ProjectProposal) {
        ProjectProposalVote storage vote = projectProposalVotes[_voteId];
        require(vote.projectId != 0, "Invalid project proposal vote ID.");
        hasVotedOnProjectProposal[_voteId][msg.sender] = true;

        if (_approve) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }

        uint256 totalMembers = members.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        uint256 totalVotes = vote.yesVotes + vote.noVotes;

        if (totalVotes >= quorum) {
            vote.isOpen = false;
            if (vote.yesVotes > vote.noVotes) {
                emit ProjectProposalApproved(vote.projectId);
            } else {
                projects[vote.projectId].isActive = false; // Deactivate rejected project
                emit ProjectProposalRejected(vote.projectId);
            }
        }
    }

    function contributeToProject(uint256 _projectId, string memory _contributionIPFSHash) public onlyMember validProject(_projectId) projectNotFinalized(_projectId) {
        require(block.timestamp <= projects[_projectId].contributionDeadline, "Contribution deadline passed.");
        projectContributors[_projectId].push(msg.sender);
        memberContributions[_projectId][msg.sender].push(_contributionIPFSHash);
        emit ContributionMade(_projectId, msg.sender, _contributionIPFSHash);
    }

    function finalizeProject(uint256 _projectId, string memory _finalArtIPFSHash) public validProject(_projectId) projectNotFinalized(_projectId) {
        require(msg.sender == projects[_projectId].projectLead || msg.sender == admin, "Only project lead or admin can finalize.");
        projects[_projectId].isFinalized = true;
        projects[_projectId].finalArtIPFSHash = _finalArtIPFSHash;
        emit ProjectFinalized(_projectId, _finalArtIPFSHash);
    }

    function mintCollectiveNFT(uint256 _projectId) public onlyMember validProject(_projectId) projectNotFinalized(_projectId) {
        require(projects[_projectId].isFinalized, "Project must be finalized before minting NFT.");
        nftProjectId[nextNftId] = _projectId;
        nftOwner[nextNftId] = address(this); // Collective owns the NFT initially
        emit NFTMinted(nextNftId, _projectId);
        nextNftId++;
    }

    function listNFTForSale(uint256 _nftId, uint256 _price) public onlyMember validNFT(_nftId) nftOwnedByCollective(_nftId) {
        nftPrice[_nftId] = _price;
        emit NFTListedForSale(_nftId, _price);
    }

    function buyNFT(uint256 _nftId) public payable validNFT(_nftId) {
        require(nftPrice[_nftId] > 0, "NFT is not for sale.");
        require(msg.value >= nftPrice[_nftId], "Insufficient funds sent.");

        uint256 salePrice = nftPrice[_nftId];
        nftPrice[_nftId] = 0; // Remove from sale
        address previousOwner = nftOwner[_nftId];
        nftOwner[_nftId] = msg.sender;

        collectiveTreasuryBalance += salePrice;

        // Distribute royalties if a split is defined for this project's NFTs
        if (royaltySplitProposals[nftProjectId[_nftId]].isOpen == false && royaltySplitProposals[nftProjectId[_nftId]].yesVotes > royaltySplitProposals[nftProjectId[_nftId]].noVotes) {
            RoyaltySplitProposal storage split = royaltySplitProposals[nftProjectId[_nftId]];
            for (uint256 i = 0; i < split.recipients.length; i++) {
                uint256 royaltyAmount = (salePrice * split.percentages[i]) / 10000; // Percentages are in basis points
                payable(split.recipients[i]).transfer(royaltyAmount);
                collectiveTreasuryBalance -= royaltyAmount; // Deduct from collective balance
            }
        }


        emit NFTBought(_nftId, msg.sender, salePrice);

        // Refund any excess Ether sent
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    function withdrawCollectiveFunds() public onlyMember {
        // Basic withdrawal - can be made more complex with voting/governance
        uint256 amountToWithdraw = collectiveTreasuryBalance;
        collectiveTreasuryBalance = 0; // Reset balance after withdrawal
        payable(msg.sender).transfer(amountToWithdraw); // Withdraw to the member initiating (can be changed to a multi-sig or voting-based withdrawal)
        emit FundsWithdrawn(msg.sender, amountToWithdraw);
    }


    // --- Advanced & Creative Functions ---

    function delegateVotingPower(address _delegateAddress) public onlyMember {
        // In a more advanced implementation, this would impact voting weight in proposals.
        // For simplicity in this example, it just records the delegation.
        // Further logic would be needed to actually use delegated voting power in voting functions.
        // For now, this function serves as a placeholder and concept example.
        // In a real DAO, you'd likely use token-based voting or a more complex system.
        // This is a simplified example to illustrate the concept.
        emit VotingPowerDelegated(msg.sender, _delegateAddress);
    }

    function proposeRoyaltySplit(uint256 _projectId, address[] memory _recipients, uint256[] memory _percentages) public onlyMember validProject(_projectId) projectNotFinalized(_projectId) {
        require(_recipients.length == _percentages.length, "Recipients and percentages arrays must have the same length.");
        uint256 totalPercentage = 0;
        for (uint256 percentage in _percentages) {
            totalPercentage += percentage;
        }
        require(totalPercentage <= 10000, "Total royalty percentage cannot exceed 100% (10000 basis points)."); // Using basis points (10000 = 100%)

        royaltySplitProposals[nextRoyaltySplitProposalId] = RoyaltySplitProposal({
            projectId: _projectId,
            recipients: _recipients,
            percentages: _percentages,
            isOpen: true,
            yesVotes: 0,
            noVotes: 0
        });
        emit RoyaltySplitProposed(nextRoyaltySplitProposalId, _projectId);
        nextRoyaltySplitProposalId++;
    }

    function voteOnRoyaltySplit(uint256 _voteId, bool _approve) public onlyMember votingOpen(_voteId, VoteType.RoyaltySplit) notAlreadyVoted(_voteId, VoteType.RoyaltySplit) {
        RoyaltySplitProposal storage vote = royaltySplitProposals[_voteId];
        require(vote.projectId != 0, "Invalid royalty split vote ID.");
        hasVotedOnRoyaltySplit[_voteId][msg.sender] = true;

        if (_approve) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }

        uint256 totalMembers = members.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        uint256 totalVotes = vote.yesVotes + vote.noVotes;

        if (totalVotes >= quorum) {
            vote.isOpen = false;
            if (vote.yesVotes > vote.noVotes) {
                emit RoyaltySplitApproved(_voteId);
                // Royalty split is now active for NFTs minted from this project
            } else {
                emit RoyaltySplitRejected(_voteId);
            }
        }
    }

    function setCurator(address _curatorAddress) public onlyAdmin {
        curator = _curatorAddress;
        emit CuratorSet(_curatorAddress);
    }

    function proposeExhibition(
        string memory _exhibitionTitle,
        string memory _exhibitionDescription,
        string memory _exhibitionDetailsIPFSHash,
        uint256 _exhibitionStartDate
    ) public onlyMember {
        exhibitionProposals[nextExhibitionProposalId] = ExhibitionProposal({
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            detailsIPFSHash: _exhibitionDetailsIPFSHash,
            startDate: _exhibitionStartDate,
            isOpen: true,
            yesVotes: 0,
            noVotes: 0
        });
        emit ExhibitionProposed(nextExhibitionProposalId, _exhibitionTitle, msg.sender);
        nextExhibitionProposalId++;
    }

    function voteOnExhibition(uint256 _voteId, bool _approve) public onlyMember votingOpen(_voteId, VoteType.Exhibition) notAlreadyVoted(_voteId, VoteType.Exhibition) {
        ExhibitionProposal storage vote = exhibitionProposals[_voteId];
        require(vote.startDate != 0, "Invalid exhibition vote ID."); // Just a basic check, could be more robust
        hasVotedOnExhibition[_voteId][msg.sender] = true;

        if (_approve) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }

        uint256 totalMembers = members.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        uint256 totalVotes = vote.yesVotes + vote.noVotes;

        if (totalVotes >= quorum) {
            vote.isOpen = false;
            if (vote.yesVotes > vote.noVotes) {
                emit ExhibitionApproved(_voteId);
                // Exhibition is approved - further logic to manage exhibition setup would be needed
            } else {
                emit ExhibitionRejected(_voteId);
            }
        }
    }

    function reportMemberContribution(address _memberAddress, uint256 _projectId, uint256 _contributionScore) public onlyMember validProject(_projectId) {
        // Basic reputation scoring - can be expanded with more detailed scoring criteria, weighting, etc.
        // Could also add checks to prevent abuse (e.g., limit reports per member/project).
        require(isMember[_memberAddress], "Reported address is not a member.");
        require(_memberAddress != msg.sender, "Cannot report your own contribution.");

        reputationPoints[_memberAddress] += _contributionScore;
        emit ContributionReported(msg.sender, _memberAddress, _projectId, _contributionScore);
    }

    function redeemReputationPoints(uint256 _pointsToRedeem) public onlyMember {
        require(reputationPoints[msg.sender] >= _pointsToRedeem, "Insufficient reputation points.");
        require(_pointsToRedeem > 0, "Points to redeem must be greater than zero.");

        reputationPoints[msg.sender] -= _pointsToRedeem;
        // Implement benefits for redeeming points here - e.g., increased voting weight, access to exclusive projects, etc.
        // For now, just emitting an event to show redemption occurred.
        emit ReputationPointsRedeemed(msg.sender, _pointsToRedeem);
    }

    function emergencyWithdrawal(address _recipient, uint256 _amount) public onlyAdmin {
        // Use with extreme caution - should ideally be a multi-sig admin function.
        require(collectiveTreasuryBalance >= _amount, "Insufficient funds in treasury for emergency withdrawal.");
        collectiveTreasuryBalance -= _amount;
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawalMade(_recipient, _amount);
    }

    function setProjectLead(uint256 _projectId, address _newLead) public onlyMember validProject(_projectId) projectNotFinalized(_projectId) {
        require(msg.sender == projects[_projectId].projectLead || msg.sender == admin, "Only current project lead or admin can change lead.");
        projects[_projectId].projectLead = _newLead;
        emit ProjectLeadSet(_projectId, _newLead);
    }

    function changeVotingQuorum(uint256 _newQuorumPercentage) public onlyAdmin {
        require(_newQuorumPercentage <= 100 && _newQuorumPercentage > 0, "Quorum percentage must be between 1 and 100.");
        votingQuorumPercentage = _newQuorumPercentage;
        emit VotingQuorumChanged(_newQuorumPercentage);
    }

    function setMembershipFee(uint256 _newFee) public onlyAdmin {
        membershipFee = _newFee;
        emit MembershipFeeChanged(_newFee);
    }

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public onlyAdmin {
        parameterChangeProposals[nextParameterChangeProposalId] = ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            isOpen: true,
            yesVotes: 0,
            noVotes: 0
        });
        emit ParameterChangeProposed(nextParameterChangeProposalId, _parameterName);
        nextParameterChangeProposalId++;
    }

    function voteOnParameterChange(uint256 _voteId, bool _approve) public onlyMember votingOpen(_voteId, VoteType.ParameterChange) notAlreadyVoted(_voteId, VoteType.ParameterChange) {
        ParameterChangeProposal storage vote = parameterChangeProposals[_voteId];
        require(bytes(vote.parameterName).length > 0, "Invalid parameter change vote ID.");
        hasVotedOnParameterChange[_voteId][msg.sender] = true;

        if (_approve) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }

        uint256 totalMembers = members.length;
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        uint256 totalVotes = vote.yesVotes + vote.noVotes;

        if (totalVotes >= quorum) {
            vote.isOpen = false;
            if (vote.yesVotes > vote.noVotes) {
                emit ParameterChangeApproved(_voteId);
                // Apply the parameter change based on vote.parameterName and vote.newValue
                if (keccak256(bytes(vote.parameterName)) == keccak256(bytes("votingQuorumPercentage"))) {
                    votingQuorumPercentage = vote.newValue;
                } else if (keccak256(bytes(vote.parameterName)) == keccak256(bytes("membershipFee"))) {
                    membershipFee = vote.newValue;
                }
                // Add more parameter change logic here as needed.
            } else {
                emit ParameterChangeRejected(_voteId);
            }
        }
    }
}
```