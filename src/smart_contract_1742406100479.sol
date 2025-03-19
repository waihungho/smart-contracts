```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative Art Creation
 * @author Bard (AI Assistant)
 * @dev This contract implements a DAO focused on collaborative art creation, leveraging NFTs,
 * governance, and innovative features to foster a decentralized artistic ecosystem.
 *
 * **Outline:**
 *
 * **I.  Core DAO Structure and Membership:**
 *     1.  `constructor()`: Initializes the DAO with admin and initial settings.
 *     2.  `joinDAO()`: Allows users to become DAO members (potentially with token/NFT gating).
 *     3.  `leaveDAO()`: Allows members to exit the DAO.
 *     4.  `isMember(address _user)`: Checks if an address is a DAO member.
 *     5.  `updateDAOParameters(...)`: Allows DAO governance to change core parameters (voting periods, thresholds, etc.).
 *     6.  `getDAOParameters()`: Returns current DAO parameters.
 *
 * **II. Collaborative Art Project Proposals and Voting:**
 *     7.  `submitArtProjectProposal(...)`: Members propose new collaborative art projects with details and goals.
 *     8.  `voteOnProposal(uint256 _proposalId, bool _vote)`: Members vote on active art project proposals.
 *     9.  `finalizeProposal(uint256 _proposalId)`:  After voting, finalizes the proposal based on vote outcome.
 *     10. `getProposalDetails(uint256 _proposalId)`:  Retrieves details of a specific art project proposal.
 *     11. `getActiveProposals()`: Returns a list of currently active art project proposals.
 *     12. `getCompletedProposals()`: Returns a list of completed art project proposals.
 *
 * **III.  Decentralized Art Contribution and Reward System:**
 *     13. `contributeToProject(uint256 _projectId, string _contributionData)`: Members contribute to approved art projects (data, assets, code, etc.).
 *     14. `recordProjectMilestone(uint256 _projectId, string _milestoneDescription)`: Project leads (or DAO vote) can record milestones reached in a project.
 *     15. `distributeProjectRewards(uint256 _projectId)`:  Distributes rewards (tokens, NFTs, etc.) to contributors of a completed project based on pre-defined rules or DAO vote.
 *     16. `setProjectRewardRules(uint256 _projectId, ...)`: Allows setting or updating reward distribution rules for a project (complex logic, potentially based on contribution type/level).
 *     17. `getProjectContributors(uint256 _projectId)`: Returns a list of contributors to a specific project.
 *
 * **IV.  NFT Minting and Art Ownership:**
 *     18. `mintCollaborativeNFT(uint256 _projectId)`: Mints an NFT representing the collaborative artwork upon project completion. Ownership can be fractionalized or shared among contributors.
 *     19. `setNFTMetadata(uint256 _nftId, string _metadataURI)`: Allows updating the metadata URI of a minted collaborative NFT.
 *     20. `getNFTDetails(uint256 _nftId)`: Retrieves details of a specific collaborative NFT.
 *
 * **V.   Advanced & Creative Features:**
 *     21. `delegateVotingPower(address _delegatee)`: Allows members to delegate their voting power to another member.
 *     22. `proposeParameterChange(...)`: Members can propose changes to DAO parameters, subject to voting.
 *     23. `emergencyPauseDAO()`: Admin function to pause critical DAO operations in case of emergency (security breach, exploit).
 *     24. `resumeDAO()`: Admin function to resume DAO operations after a pause.
 *     25. `withdrawTreasuryFunds(uint256 _amount, address _recipient)`:  DAO governed function to withdraw funds from the DAO treasury for project expenses or DAO operations.
 *
 * **Function Summary:**
 *
 * 1. **`constructor()`**:  Sets up the DAO admin and initial configuration.
 * 2. **`joinDAO()`**:  Allows users to become members of the DAO.
 * 3. **`leaveDAO()`**:  Allows members to exit the DAO.
 * 4. **`isMember()`**:  Checks if an address is a DAO member.
 * 5. **`updateDAOParameters()`**:  Governed function to modify DAO settings.
 * 6. **`getDAOParameters()`**:  Retrieves current DAO settings.
 * 7. **`submitArtProjectProposal()`**:  Members propose art projects for collaboration.
 * 8. **`voteOnProposal()`**:  Members vote on art project proposals.
 * 9. **`finalizeProposal()`**:  Finalizes a proposal based on voting results.
 * 10. **`getProposalDetails()`**:  Retrieves information about a specific proposal.
 * 11. **`getActiveProposals()`**:  Lists currently active proposals.
 * 12. **`getCompletedProposals()`**:  Lists completed proposals.
 * 13. **`contributeToProject()`**:  Members contribute to approved projects.
 * 14. **`recordProjectMilestone()`**:  Records milestones achieved in a project.
 * 15. **`distributeProjectRewards()`**:  Distributes rewards to project contributors.
 * 16. **`setProjectRewardRules()`**:  Sets or updates reward distribution rules for a project.
 * 17. **`getProjectContributors()`**:  Lists contributors to a project.
 * 18. **`mintCollaborativeNFT()`**:  Mints an NFT for a completed collaborative artwork.
 * 19. **`setNFTMetadata()`**:  Updates metadata for a collaborative NFT.
 * 20. **`getNFTDetails()`**:  Retrieves details of a collaborative NFT.
 * 21. **`delegateVotingPower()`**:  Allows members to delegate their voting rights.
 * 22. **`proposeParameterChange()`**:  Members can propose changes to DAO parameters.
 * 23. **`emergencyPauseDAO()`**:  Admin function to temporarily pause the DAO.
 * 24. **`resumeDAO()`**:  Admin function to resume DAO operations.
 * 25. **`withdrawTreasuryFunds()`**:  Governed function to withdraw funds from the DAO treasury.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CollaborativeArtDAO is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // DAO Parameters - can be updated via governance
    struct DAOParameters {
        uint256 proposalVotingPeriod; // in blocks
        uint256 proposalQuorumPercentage; // Percentage of members needed to vote for quorum
        uint256 proposalApprovalThresholdPercentage; // Percentage of votes needed to approve a proposal
        uint256 membershipFee; // Fee to join DAO (can be 0)
    }

    DAOParameters public daoParameters;

    // DAO Membership
    mapping(address => bool) public isMember;
    address[] public members;

    // Voting Delegation
    mapping(address => address) public votingDelegation;

    // Art Project Proposals
    struct ArtProjectProposal {
        uint256 proposalId;
        string title;
        string description;
        address proposer;
        uint256 submissionTime;
        uint256 votingEndTime;
        bool isActive;
        bool isApproved;
        mapping(address => bool) votes; // Member address => vote (true=yes, false=no)
        uint256 yesVotes;
        uint256 noVotes;
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => ArtProjectProposal) public artProposals;
    uint256[] public activeProposalIds;
    uint256[] public completedProposalIds;

    // Project Contributions
    struct ProjectContribution {
        address contributor;
        uint256 contributionTime;
        string contributionData; // Could be IPFS hash, link, etc.
    }
    mapping(uint256 => ProjectContribution[]) public projectContributions;

    // Project Milestones
    struct ProjectMilestone {
        uint256 milestoneId;
        uint256 milestoneTime;
        string description;
    }
    Counters.Counter private _milestoneIdCounter;
    mapping(uint256 => ProjectMilestone[]) public projectMilestones;

    // Project Reward Rules (Simplified for example, can be made more complex)
    mapping(uint256 => mapping(address => uint256)) public projectRewardShares; // projectId => (contributor => share percentage)

    // Collaborative NFTs
    Counters.Counter private _nftIdCounter;
    mapping(uint256 => string) public nftMetadataURIs; // nftId => metadata URI
    mapping(uint256 => uint256) public nftToProjectId; // nftId => projectId

    // DAO Treasury
    uint256 public treasuryBalance;

    // Paused State
    bool public paused;

    // Events
    event MemberJoined(address member);
    event MemberLeft(address member);
    event DAOParametersUpdated(DAOParameters newParameters);
    event ArtProjectProposed(uint256 proposalId, string title, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalFinalized(uint256 proposalId, bool isApproved);
    event ContributionMade(uint256 projectId, address contributor, string contributionData);
    event MilestoneRecorded(uint256 projectId, uint256 milestoneId, string description);
    event RewardsDistributed(uint256 projectId);
    event CollaborativeNFTMinted(uint256 nftId, uint256 projectId);
    event NFTMetadataUpdated(uint256 nftId, string metadataURI);
    event VotingPowerDelegated(address delegator, address delegatee);
    event DAOParameterChangeProposed(); // Add details if needed
    event DAOPaused();
    event DAOResumed();
    event TreasuryWithdrawal(uint256 amount, address recipient);

    constructor() ERC721("CollaborativeArtNFT", "CANFT") {
        _setOwner(_msgSender()); // Deployer is initial admin
        // Initialize default DAO parameters
        daoParameters = DAOParameters({
            proposalVotingPeriod: 100, // 100 blocks
            proposalQuorumPercentage: 30, // 30% quorum
            proposalApprovalThresholdPercentage: 60, // 60% approval
            membershipFee: 0 // No membership fee initially
        });
    }

    // --- I. Core DAO Structure and Membership ---

    function joinDAO() external payable {
        require(!isMember[_msgSender()], "Already a member");
        require(!paused, "DAO is currently paused");
        if (daoParameters.membershipFee > 0) {
            require(msg.value >= daoParameters.membershipFee, "Insufficient membership fee");
            treasuryBalance += daoParameters.membershipFee; // Deposit fee to treasury
            emit TreasuryWithdrawal(daoParameters.membershipFee, address(this)); // Technically an deposit, but using withdrawal event for treasury changes
        }
        isMember[_msgSender()] = true;
        members.push(_msgSender());
        emit MemberJoined(_msgSender());
    }

    function leaveDAO() external {
        require(isMember[_msgSender()], "Not a member");
        require(!paused, "DAO is currently paused");

        isMember[_msgSender()] = false;
        // Remove from members array (can be optimized for gas if needed for large memberships)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _msgSender()) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MemberLeft(_msgSender());
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function updateDAOParameters(
        uint256 _proposalVotingPeriod,
        uint256 _proposalQuorumPercentage,
        uint256 _proposalApprovalThresholdPercentage,
        uint256 _membershipFee
    ) external onlyOwner { // Example: Only admin can update initially, could be DAO vote later
        require(!paused, "DAO is currently paused");
        daoParameters = DAOParameters({
            proposalVotingPeriod: _proposalVotingPeriod,
            proposalQuorumPercentage: _proposalQuorumPercentage,
            proposalApprovalThresholdPercentage: _proposalApprovalThresholdPercentage,
            membershipFee: _membershipFee
        });
        emit DAOParametersUpdated(daoParameters);
    }

    function getDAOParameters() external view returns (DAOParameters memory) {
        return daoParameters;
    }

    // --- II. Collaborative Art Project Proposals and Voting ---

    function submitArtProjectProposal(string memory _title, string memory _description) external {
        require(isMember[_msgSender()], "Only members can submit proposals");
        require(!paused, "DAO is currently paused");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        ArtProjectProposal storage newProposal = artProposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposer = _msgSender();
        newProposal.submissionTime = block.number;
        newProposal.votingEndTime = block.number + daoParameters.proposalVotingPeriod;
        newProposal.isActive = true;

        activeProposalIds.push(proposalId); // Add to active proposals list

        emit ArtProjectProposed(proposalId, _title, _msgSender());
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external {
        require(isMember[_msgSender()], "Only members can vote");
        require(!paused, "DAO is currently paused");
        require(artProposals[_proposalId].isActive, "Proposal is not active");
        require(block.number <= artProposals[_proposalId].votingEndTime, "Voting period has ended");
        require(!artProposals[_proposalId].votes[_msgSender()], "Already voted on this proposal");

        address voter = votingDelegation[_msgSender()] != address(0) ? votingDelegation[_msgSender()] : _msgSender(); // Use delegated vote if set

        artProposals[_proposalId].votes[voter] = _vote;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, voter, _vote);
    }

    function finalizeProposal(uint256 _proposalId) external {
        require(artProposals[_proposalId].isActive, "Proposal is not active");
        require(block.number > artProposals[_proposalId].votingEndTime, "Voting period has not ended");
        require(!artProposals[_proposalId].isApproved, "Proposal already finalized"); // Prevent re-finalization

        artProposals[_proposalId].isActive = false; // Mark as inactive
        removeProposalFromActiveList(_proposalId);
        completedProposalIds.push(_proposalId); // Add to completed list

        uint256 totalMembersAtVote = members.length; // Consider only members at the time of voting start for quorum? Or current members? (Current for simplicity)
        uint256 quorumNeeded = (totalMembersAtVote * daoParameters.proposalQuorumPercentage) / 100;
        uint256 totalVotes = artProposals[_proposalId].yesVotes + artProposals[_proposalId].noVotes;

        if (totalVotes >= quorumNeeded) {
            uint256 approvalThreshold = (totalVotes * daoParameters.proposalApprovalThresholdPercentage) / 100;
            if (artProposals[_proposalId].yesVotes >= approvalThreshold) {
                artProposals[_proposalId].isApproved = true;
                // Proposal Approved - Can trigger further actions (e.g., project initiation) here if needed
            } else {
                artProposals[_proposalId].isApproved = false; // Proposal Rejected
            }
        } else {
            artProposals[_proposalId].isApproved = false; // Proposal Rejected due to lack of quorum
        }

        emit ProposalFinalized(_proposalId, artProposals[_proposalId].isApproved);
    }

    function getProposalDetails(uint256 _proposalId) external view returns (ArtProjectProposal memory) {
        return artProposals[_proposalId];
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        return activeProposalIds;
    }

    function getCompletedProposals() external view returns (uint256[] memory) {
        return completedProposalIds;
    }

    // --- III. Decentralized Art Contribution and Reward System ---

    function contributeToProject(uint256 _projectId, string memory _contributionData) external {
        require(isMember[_msgSender()], "Only members can contribute");
        require(!paused, "DAO is currently paused");
        require(artProposals[_projectId].isApproved, "Project proposal must be approved to contribute");

        ProjectContribution memory newContribution = ProjectContribution({
            contributor: _msgSender(),
            contributionTime: block.timestamp,
            contributionData: _contributionData
        });
        projectContributions[_projectId].push(newContribution);
        emit ContributionMade(_projectId, _msgSender(), _contributionData);
    }

    function recordProjectMilestone(uint256 _projectId, string memory _milestoneDescription) external onlyOwner { // Example: Only admin can record milestones, can be DAO vote or project lead later
        require(artProposals[_projectId].isApproved, "Project proposal must be approved");
        require(!paused, "DAO is currently paused");

        _milestoneIdCounter.increment();
        uint256 milestoneId = _milestoneIdCounter.current();

        ProjectMilestone memory newMilestone = ProjectMilestone({
            milestoneId: milestoneId,
            milestoneTime: block.timestamp,
            description: _milestoneDescription
        });
        projectMilestones[_projectId].push(newMilestone);
        emit MilestoneRecorded(_projectId, milestoneId, _milestoneDescription);
    }

    function distributeProjectRewards(uint256 _projectId) external onlyOwner { // Example: Admin initiates reward distribution, can be automated or DAO vote later
        require(artProposals[_projectId].isApproved, "Project proposal must be approved");
        require(!paused, "DAO is currently paused");
        // In a real application, implement more complex reward distribution logic here based on projectRewardShares[_projectId]
        // This is a simplified example:
        uint256 totalShares = 0;
        address[] memory contributors = getProjectContributors(_projectId);
        for (uint256 i = 0; i < contributors.length; i++) {
            totalShares += projectRewardShares[_projectId][contributors[i]];
        }

        // Example: Assume project has some funds in the contract (or treasury allocation)
        uint256 projectFunds = 1 ether; // Placeholder - replace with actual fund source and logic

        for (uint256 i = 0; i < contributors.length; i++) {
            uint256 rewardAmount = (projectFunds * projectRewardShares[_projectId][contributors[i]]) / totalShares;
            payable(contributors[i]).transfer(rewardAmount); // Transfer ETH as reward example
        }
        emit RewardsDistributed(_projectId);
    }

    function setProjectRewardRules(uint256 _projectId, address[] memory _contributors, uint256[] memory _shares) external onlyOwner { // Example: Admin sets rules, DAO vote later
        require(artProposals[_projectId].isApproved, "Project proposal must be approved");
        require(!paused, "DAO is currently paused");
        require(_contributors.length == _shares.length, "Contributors and shares arrays must have the same length");

        for (uint256 i = 0; i < _contributors.length; i++) {
            projectRewardShares[_projectId][_contributors[i]] = _shares[i];
        }
    }

    function getProjectContributors(uint256 _projectId) public view returns (address[] memory) {
        ProjectContribution[] memory contributions = projectContributions[_projectId];
        address[] memory contributors = new address[](contributions.length);
        for (uint256 i = 0; i < contributions.length; i++) {
            contributors[i] = contributions[i].contributor;
        }
        return uniqueAddresses(contributors); // Return only unique contributors
    }


    // --- IV. NFT Minting and Art Ownership ---

    function mintCollaborativeNFT(uint256 _projectId) external onlyOwner { // Example: Admin mints, could be automated after project completion
        require(artProposals[_projectId].isApproved, "Project proposal must be approved to mint NFT");
        require(!paused, "DAO is currently paused");

        _nftIdCounter.increment();
        uint256 nftId = _nftIdCounter.current();

        _safeMint(address(this), nftId); // Mint to contract initially - can transfer/fractionalize later
        nftToProjectId[nftId] = _projectId;

        emit CollaborativeNFTMinted(nftId, _projectId);
    }

    function setNFTMetadata(uint256 _nftId, string memory _metadataURI) external onlyOwner { // Example: Admin sets metadata, could be DAO vote or project lead later
        require(!paused, "DAO is currently paused");
        nftMetadataURIs[_nftId] = _metadataURI;
        emit NFTMetadataUpdated(_nftId, _metadataURI);
    }

    function getNFTDetails(uint256 _nftId) external view returns (string memory metadataURI, uint256 projectId) {
        return (nftMetadataURIs[_nftId], nftToProjectId[_nftId]);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory uri = nftMetadataURIs[tokenId];
        // If no specific metadata URI, can return a default or fallback URI
        if (bytes(uri).length == 0) {
            return "ipfs://default-art-metadata.json"; // Example default
        }
        return uri;
    }


    // --- V. Advanced & Creative Features ---

    function delegateVotingPower(address _delegatee) external {
        require(isMember[_msgSender()], "Only members can delegate voting power");
        require(!paused, "DAO is currently paused");
        require(isMember[_delegatee], "Delegatee must be a DAO member");
        require(_delegatee != _msgSender(), "Cannot delegate to self");

        votingDelegation[_msgSender()] = _delegatee;
        emit VotingPowerDelegated(_msgSender(), _delegatee);
    }

    function proposeParameterChange(
        uint256 _proposalVotingPeriod,
        uint256 _proposalQuorumPercentage,
        uint256 _proposalApprovalThresholdPercentage,
        uint256 _membershipFee
    ) external onlyOwner { // Example: Admin proposes, could be member proposal and voting later
        require(!paused, "DAO is currently paused");
        // In a real DAO, this would trigger a proposal and voting process for parameter changes
        // For this example, we will directly update (as onlyOwner function) - to demonstrate the concept of parameter change

        daoParameters = DAOParameters({
            proposalVotingPeriod: _proposalVotingPeriod,
            proposalQuorumPercentage: _proposalQuorumPercentage,
            proposalApprovalThresholdPercentage: _proposalApprovalThresholdPercentage,
            membershipFee: _membershipFee
        });
        emit DAOParametersUpdated(daoParameters);
        emit DAOParameterChangeProposed(); // More details in event if needed
    }


    function emergencyPauseDAO() external onlyOwner {
        require(!paused, "DAO is not paused");
        paused = true;
        emit DAOPaused();
    }

    function resumeDAO() external onlyOwner {
        require(paused, "DAO is paused");
        paused = false;
        emit DAOResumed();
    }

    function withdrawTreasuryFunds(uint256 _amount, address _recipient) external onlyOwner { // Example: Admin withdraws, should be DAO vote in real scenario
        require(!paused, "DAO is currently paused");
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_amount, _recipient);
    }


    // --- Internal Helper Functions ---

    function removeProposalFromActiveList(uint256 _proposalId) internal {
        for (uint256 i = 0; i < activeProposalIds.length; i++) {
            if (activeProposalIds[i] == _proposalId) {
                activeProposalIds[i] = activeProposalIds[activeProposalIds.length - 1];
                activeProposalIds.pop();
                break;
            }
        }
    }

    function uniqueAddresses(address[] memory _addresses) internal pure returns (address[] memory) {
        if (_addresses.length == 0) {
            return new address[](0);
        }
        address[] memory unique = new address[](_addresses.length);
        uint256 uniqueCount = 0;
        mapping(address => bool) seen;

        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!seen[_addresses[i]]) {
                unique[uniqueCount] = _addresses[i];
                uniqueCount++;
                seen[_addresses[i]] = true;
            }
        }
        address[] memory result = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            result[i] = unique[i];
        }
        return result;
    }

    receive() external payable {
        treasuryBalance += msg.value; // Accidental funds sent to contract go to treasury
        emit TreasuryWithdrawal(msg.value, address(this)); // Using withdrawal event for treasury changes
    }
}
```