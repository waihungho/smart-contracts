```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (Example - Conceptual Contract)
 * @notice This contract outlines a Decentralized Autonomous Research Organization (DARO) with advanced and creative functions.
 * It facilitates research proposal submission, community voting, funding, IP management through NFTs, and incentivized participation.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. `submitResearchProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _fundingGoal)`: Allows researchers to submit proposals with details, IPFS link, and funding goals.
 * 2. `getResearchProposalDetails(uint256 _proposalId)`: Retrieves detailed information about a specific research proposal.
 * 3. `startProposalVoting(uint256 _proposalId, uint256 _votingDuration)`: Starts a voting period for a research proposal, initiated by governance.
 * 4. `castVote(uint256 _proposalId, bool _support)`: Allows members to cast votes (support/reject) on a research proposal.
 * 5. `endProposalVoting(uint256 _proposalId)`: Ends the voting period and determines if a proposal is approved based on quorum and support.
 * 6. `fundResearchProposal(uint256 _proposalId)`: Allows anyone to contribute funds to an approved research proposal.
 * 7. `releaseMilestonePayment(uint256 _proposalId, uint256 _milestoneId)`: Releases funds for a specific milestone of a funded research project upon completion and governance approval.
 * 8. `reportResearchProgress(uint256 _proposalId, string memory _progressReport, string memory _ipfsReportHash)`: Allows researchers to submit progress reports with IPFS links.
 * 9. `getResearchProgressReports(uint256 _proposalId)`: Retrieves progress reports for a research proposal.
 * 10. `mintResearchNFT(uint256 _proposalId, string memory _nftMetadataURI)`: Mints an NFT representing the intellectual property of a completed and successful research project.
 * 11. `transferResearchNFT(uint256 _nftId, address _to)`: Allows transferring ownership of a research NFT.
 * 12. `burnResearchNFT(uint256 _nftId)`: Allows governance to burn (revoke) a research NFT under specific circumstances (e.g., plagiarism).
 *
 * **Governance & Membership:**
 * 13. `addMember(address _memberAddress)`: Allows governance to add new members to the DARO (e.g., researchers, reviewers, contributors).
 * 14. `removeMember(address _memberAddress)`: Allows governance to remove members from the DARO.
 * 15. `isMember(address _address)`: Checks if an address is a member of the DARO.
 * 16. `setVotingQuorum(uint256 _quorumPercentage)`: Allows governance to set the quorum percentage required for proposal approval.
 * 17. `setGovernanceAddress(address _newGovernance)`: Allows governance to change the governance address.
 *
 * **Incentives & Rewards:**
 * 18. `rewardContributor(address _contributorAddress, uint256 _rewardAmount)`: Allows governance to reward contributors (e.g., reviewers, community members) with tokens.
 * 19. `stakeTokens(uint256 _amount)`: Allows members to stake tokens to participate in governance and potentially earn rewards. (Conceptual, token contract interaction needed in real implementation).
 * 20. `withdrawStakedTokens()`: Allows members to withdraw their staked tokens. (Conceptual, token contract interaction needed in real implementation).
 * 21. `getMemberStake(address _memberAddress)`: Retrieves the staked token amount for a member. (Conceptual, token contract interaction needed in real implementation).
 * 22. `claimNFTRoyalty(uint256 _nftId)`: Allows the original researcher to claim royalties from secondary sales of their research NFT (Conceptual, requires NFT marketplace integration in real implementation).
 * 23. `setRoyaltyPercentage(uint256 _percentage)`: Allows governance to set the royalty percentage for research NFTs. (Conceptual, requires NFT marketplace integration in real implementation).
 */

contract DARO {
    // --- State Variables ---

    address public governanceAddress; // Address authorized for governance functions
    uint256 public proposalCounter; // Counter for research proposal IDs
    uint256 public nftCounter; // Counter for research NFT IDs
    uint256 public votingQuorumPercentage = 50; // Default quorum percentage for voting
    uint256 public royaltyPercentage = 5; // Default royalty percentage for research NFTs

    mapping(uint256 => ResearchProposal) public researchProposals; // Mapping of proposal IDs to proposal details
    mapping(uint256 => Vote[]) public proposalVotes; // Mapping of proposal IDs to votes
    mapping(address => bool) public members; // Mapping of member addresses to membership status
    mapping(uint256 => ResearchNFT) public researchNFTs; // Mapping of NFT IDs to NFT details
    mapping(address => uint256) public memberStakes; // Mapping of member address to their staked tokens (Conceptual)

    // --- Structs & Enums ---

    struct ResearchProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash; // IPFS hash for detailed proposal document
        uint256 fundingGoal;
        uint256 currentFunding;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        Milestone[] milestones;
        ProgressReport[] progressReports;
    }

    struct Milestone {
        uint256 id;
        string description;
        uint256 fundingAmount;
        bool isCompleted;
        bool paymentReleased;
    }

    struct ProgressReport {
        uint256 id;
        address reporter;
        uint256 timestamp;
        string report;
        string ipfsReportHash; // IPFS hash for detailed report document
    }

    struct Vote {
        address voter;
        bool support;
        uint256 timestamp;
    }

    struct ResearchNFT {
        uint256 id;
        uint256 proposalId;
        address creator;
        string metadataURI;
        bool burned;
    }

    enum ProposalStatus {
        Pending,
        Voting,
        Approved,
        Rejected,
        Funded,
        InProgress,
        Completed,
        Failed
    }

    // --- Events ---

    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalVotingStarted(uint256 proposalId, uint256 votingDuration);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalVotingEnded(uint256 proposalId, ProposalStatus status, uint256 yesVotes, uint256 noVotes);
    event ProposalFunded(uint256 proposalId, uint256 fundingAmount, uint256 currentFunding);
    event MilestonePaymentReleased(uint256 proposalId, uint256 milestoneId, uint256 amount);
    event ProgressReportSubmitted(uint256 proposalId, address reporter, string report);
    event ResearchNFTMinted(uint256 nftId, uint256 proposalId, address creator, string metadataURI);
    event ResearchNFTTransferred(uint256 nftId, address from, address to);
    event ResearchNFTBurned(uint256 nftId);
    event MemberAdded(address memberAddress);
    event MemberRemoved(address memberAddress);
    event ContributorRewarded(address contributorAddress, uint256 rewardAmount);
    event TokensStaked(address memberAddress, uint256 amount);
    event TokensWithdrawn(address memberAddress, uint256 amount);
    event RoyaltyClaimed(uint256 nftId, addressclaimer, uint256 amount);
    event RoyaltyPercentageSet(uint256 percentage);
    event VotingQuorumSet(uint256 percentage);
    event GovernanceAddressChanged(address newGovernanceAddress);


    // --- Modifiers ---

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(researchProposals[_proposalId].id != 0, "Proposal does not exist");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Proposal is not in the required status");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(researchProposals[_proposalId].status == ProposalStatus.Voting, "Voting is not active for this proposal");
        require(block.timestamp <= researchProposals[_proposalId].votingEndTime, "Voting period has ended");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        for (uint256 i = 0; i < proposalVotes[_proposalId].length; i++) {
            require(proposalVotes[_proposalId][i].voter != msg.sender, "You have already voted on this proposal");
        }
        _;
    }

    modifier nftExists(uint256 _nftId) {
        require(researchNFTs[_nftId].id != 0, "NFT does not exist");
        require(!researchNFTs[_nftId].burned, "NFT is burned");
        _;
    }

    modifier nftCreator(uint256 _nftId) {
        require(researchNFTs[_nftId].creator == msg.sender, "You are not the NFT creator");
        _;
    }


    // --- Constructor ---

    constructor(address _governanceAddress) {
        governanceAddress = _governanceAddress;
        proposalCounter = 0;
        nftCounter = 0;
    }

    // --- Core Functionality Functions ---

    /// @notice Allows researchers to submit proposals with details, IPFS link, and funding goals.
    /// @param _title Title of the research proposal.
    /// @param _description Brief description of the research proposal.
    /// @param _ipfsHash IPFS hash linking to a detailed document about the proposal.
    /// @param _fundingGoal Target funding amount for the research project.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _fundingGoal
    ) external onlyMember {
        proposalCounter++;
        researchProposals[proposalCounter] = ResearchProposal({
            id: proposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            milestones: new Milestone[](0), // Initialize with empty milestones array
            progressReports: new ProgressReport[](0) // Initialize with empty progress reports array
        });
        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /// @notice Retrieves detailed information about a specific research proposal.
    /// @param _proposalId ID of the research proposal.
    /// @return ResearchProposal struct containing proposal details.
    function getResearchProposalDetails(uint256 _proposalId)
        external
        view
        proposalExists(_proposalId)
        returns (ResearchProposal memory)
    {
        return researchProposals[_proposalId];
    }

    /// @notice Starts a voting period for a research proposal, initiated by governance.
    /// @param _proposalId ID of the research proposal to be voted on.
    /// @param _votingDuration Duration of the voting period in seconds.
    function startProposalVoting(uint256 _proposalId, uint256 _votingDuration)
        external
        onlyGovernance
        proposalExists(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Pending)
    {
        researchProposals[_proposalId].status = ProposalStatus.Voting;
        researchProposals[_proposalId].votingStartTime = block.timestamp;
        researchProposals[_proposalId].votingEndTime = block.timestamp + _votingDuration;
        emit ProposalVotingStarted(_proposalId, _votingDuration);
    }

    /// @notice Allows members to cast votes (support/reject) on a research proposal.
    /// @param _proposalId ID of the research proposal being voted on.
    /// @param _support Boolean indicating support (true) or rejection (false).
    function castVote(uint256 _proposalId, bool _support)
        external
        onlyMember
        proposalExists(_proposalId)
        votingActive(_proposalId)
        notVotedYet(_proposalId)
    {
        proposalVotes[_proposalId].push(Vote({
            voter: msg.sender,
            support: _support,
            timestamp: block.timestamp
        }));
        if (_support) {
            researchProposals[_proposalId].yesVotes++;
        } else {
            researchProposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Ends the voting period and determines if a proposal is approved based on quorum and support.
    /// @param _proposalId ID of the research proposal to end voting for.
    function endProposalVoting(uint256 _proposalId)
        external
        onlyGovernance
        proposalExists(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Voting)
    {
        require(block.timestamp > researchProposals[_proposalId].votingEndTime, "Voting period has not ended yet");

        uint256 totalVotes = proposalVotes[_proposalId].length;
        uint256 quorum = (membersCount() * votingQuorumPercentage) / 100; // Simplified quorum calculation based on member count
        bool isApproved = (totalVotes >= quorum) && (researchProposals[_proposalId].yesVotes > researchProposals[_proposalId].noVotes);

        if (isApproved) {
            researchProposals[_proposalId].status = ProposalStatus.Approved;
        } else {
            researchProposals[_proposalId].status = ProposalStatus.Rejected;
        }
        emit ProposalVotingEnded(
            _proposalId,
            researchProposals[_proposalId].status,
            researchProposals[_proposalId].yesVotes,
            researchProposals[_proposalId].noVotes
        );
    }

    /// @notice Allows anyone to contribute funds to an approved research proposal.
    /// @param _proposalId ID of the research proposal to fund.
    function fundResearchProposal(uint256 _proposalId)
        external
        payable
        proposalExists(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Approved)
    {
        require(researchProposals[_proposalId].currentFunding + msg.value <= researchProposals[_proposalId].fundingGoal, "Funding goal exceeded");
        researchProposals[_proposalId].currentFunding += msg.value;
        if (researchProposals[_proposalId].currentFunding == researchProposals[_proposalId].fundingGoal) {
            researchProposals[_proposalId].status = ProposalStatus.Funded;
        }
        emit ProposalFunded(_proposalId, msg.value, researchProposals[_proposalId].currentFunding);
    }

    /// @notice Releases funds for a specific milestone of a funded research project upon completion and governance approval.
    /// @param _proposalId ID of the research proposal.
    /// @param _milestoneId ID of the milestone to release payment for.
    function releaseMilestonePayment(uint256 _proposalId, uint256 _milestoneId)
        external
        onlyGovernance
        proposalExists(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Funded) // Or InProgress depending on workflow
    {
        require(_milestoneId < researchProposals[_proposalId].milestones.length, "Milestone does not exist");
        Milestone storage milestone = researchProposals[_proposalId].milestones[_milestoneId];
        require(!milestone.isCompleted, "Milestone already marked as completed");
        require(!milestone.paymentReleased, "Payment already released for this milestone");
        require(researchProposals[_proposalId].currentFunding >= milestone.fundingAmount, "Insufficient funds for milestone payment");

        milestone.isCompleted = true;
        milestone.paymentReleased = true;
        researchProposals[_proposalId].currentFunding -= milestone.fundingAmount;

        payable(researchProposals[_proposalId].proposer).transfer(milestone.fundingAmount); // Send payment to proposer

        emit MilestonePaymentReleased(_proposalId, _milestoneId, milestone.fundingAmount);

        // Update proposal status to InProgress if first milestone is paid
        if (researchProposals[_proposalId].status == ProposalStatus.Funded) {
            researchProposals[_proposalId].status = ProposalStatus.InProgress;
        }
    }


    /// @notice Report research progress for a funded project.
    /// @param _proposalId ID of the research proposal.
    /// @param _progressReport Textual progress report.
    /// @param _ipfsReportHash IPFS hash for a detailed report document.
    function reportResearchProgress(uint256 _proposalId, string memory _progressReport, string memory _ipfsReportHash)
        external
        onlyMember // Assuming only the proposer/researcher can report progress
        proposalExists(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.InProgress)
    {
        uint256 reportId = researchProposals[_proposalId].progressReports.length;
        researchProposals[_proposalId].progressReports.push(ProgressReport({
            id: reportId,
            reporter: msg.sender,
            timestamp: block.timestamp,
            report: _progressReport,
            ipfsReportHash: _ipfsReportHash
        }));
        emit ProgressReportSubmitted(_proposalId, msg.sender, _progressReport);
    }

    /// @notice Retrieves progress reports for a research proposal.
    /// @param _proposalId ID of the research proposal.
    /// @return Array of ProgressReport structs.
    function getResearchProgressReports(uint256 _proposalId)
        external
        view
        proposalExists(_proposalId)
        returns (ProgressReport[] memory)
    {
        return researchProposals[_proposalId].progressReports;
    }

    /// @notice Mints an NFT representing the intellectual property of a completed and successful research project.
    /// @param _proposalId ID of the research proposal that led to this NFT.
    /// @param _nftMetadataURI URI pointing to the NFT metadata (e.g., IPFS link to JSON).
    function mintResearchNFT(uint256 _proposalId, string memory _nftMetadataURI)
        external
        onlyGovernance // Minting NFTs is typically a governance action
        proposalExists(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Completed) // Or a status indicating successful completion
    {
        nftCounter++;
        researchNFTs[nftCounter] = ResearchNFT({
            id: nftCounter,
            proposalId: _proposalId,
            creator: researchProposals[_proposalId].proposer,
            metadataURI: _nftMetadataURI,
            burned: false
        });
        emit ResearchNFTMinted(nftCounter, _proposalId, researchProposals[_proposalId].proposer, _nftMetadataURI);
    }

    /// @notice Allows transferring ownership of a research NFT.
    /// @param _nftId ID of the research NFT to transfer.
    /// @param _to Address to transfer the NFT to.
    function transferResearchNFT(uint256 _nftId, address _to)
        external
        nftExists(_nftId)
        nftCreator(_nftId) // Assuming only creator can initially transfer, governance could have override
    {
        require(_to != address(0), "Invalid recipient address");
        researchNFTs[_nftId].creator = _to; // Simple owner update, in a real NFT contract, this would be more complex (ERC721 standard)
        emit ResearchNFTTransferred(_nftId, msg.sender, _to);
    }

    /// @notice Allows governance to burn (revoke) a research NFT under specific circumstances (e.g., plagiarism).
    /// @param _nftId ID of the research NFT to burn.
    function burnResearchNFT(uint256 _nftId)
        external
        onlyGovernance
        nftExists(_nftId)
    {
        researchNFTs[_nftId].burned = true;
        emit ResearchNFTBurned(_nftId);
    }


    // --- Governance & Membership Functions ---

    /// @notice Allows governance to add new members to the DARO.
    /// @param _memberAddress Address of the member to add.
    function addMember(address _memberAddress) external onlyGovernance {
        members[_memberAddress] = true;
        emit MemberAdded(_memberAddress);
    }

    /// @notice Allows governance to remove members from the DARO.
    /// @param _memberAddress Address of the member to remove.
    function removeMember(address _memberAddress) external onlyGovernance {
        members[_memberAddress] = false;
        emit MemberRemoved(_memberAddress);
    }

    /// @notice Checks if an address is a member of the DARO.
    /// @param _address Address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _address) external view returns (bool) {
        return members[_address];
    }

    /// @notice Allows governance to set the quorum percentage required for proposal approval.
    /// @param _quorumPercentage New quorum percentage value (e.g., 50 for 50%).
    function setVotingQuorum(uint256 _quorumPercentage) external onlyGovernance {
        require(_quorumPercentage <= 100, "Quorum percentage must be less than or equal to 100");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumSet(_quorumPercentage);
    }

    /// @notice Allows governance to change the governance address.
    /// @param _newGovernance New address to be set as the governance address.
    function setGovernanceAddress(address _newGovernance) external onlyGovernance {
        require(_newGovernance != address(0), "Invalid governance address");
        governanceAddress = _newGovernance;
        emit GovernanceAddressChanged(_newGovernance);
    }


    // --- Incentives & Rewards Functions ---

    /// @notice Allows governance to reward contributors (e.g., reviewers, community members) with tokens.
    /// @param _contributorAddress Address to reward.
    /// @param _rewardAmount Amount of tokens to reward.
    function rewardContributor(address _contributorAddress, uint256 _rewardAmount) external onlyGovernance {
        // **Conceptual:** In a real implementation, this would interact with a token contract.
        // For example, assuming a token contract 'daroToken' exists:
        // IERC20(daroToken).transfer(_contributorAddress, _rewardAmount);
        // For this example, we'll just emit an event.
        emit ContributorRewarded(_contributorAddress, _rewardAmount);
    }

    /// @notice Allows members to stake tokens to participate in governance and potentially earn rewards. (Conceptual).
    /// @param _amount Amount of tokens to stake.
    function stakeTokens(uint256 _amount) external onlyMember {
        // **Conceptual:** In a real implementation, this would interact with a token contract and staking mechanism.
        // For example, assuming a token contract 'daroToken' and a staking contract:
        // IDAROStaking(daroStakingContract).stake(msg.sender, _amount);
        // For this example, we'll simulate by updating a mapping.
        memberStakes[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows members to withdraw their staked tokens. (Conceptual).
    function withdrawStakedTokens() external onlyMember {
        // **Conceptual:** In a real implementation, this would interact with a token contract and staking mechanism.
        // For example, assuming a token contract 'daroToken' and a staking contract:
        // uint256 stakedAmount = memberStakes[msg.sender];
        // IDAROStaking(daroStakingContract).withdraw(msg.sender, stakedAmount);
        // For this example, we'll simulate by resetting the mapping.
        uint256 stakedAmount = memberStakes[msg.sender];
        memberStakes[msg.sender] = 0;
        emit TokensWithdrawn(msg.sender, stakedAmount);
    }

    /// @notice Retrieves the staked token amount for a member. (Conceptual).
    /// @param _memberAddress Address of the member.
    /// @return Amount of tokens staked by the member.
    function getMemberStake(address _memberAddress) external view onlyMember returns (uint256) {
        // **Conceptual:** In a real implementation, this would query a staking contract.
        // For example, assuming a staking contract:
        // return IDAROStaking(daroStakingContract).getStake(_memberAddress);
        // For this example, we'll return from our mapping.
        return memberStakes[_memberAddress];
    }

    /// @notice Allows the original researcher to claim royalties from secondary sales of their research NFT (Conceptual).
    /// @param _nftId ID of the research NFT.
    function claimNFTRoyalty(uint256 _nftId) external nftExists(_nftId) nftCreator(_nftId) {
        // **Conceptual:** In a real NFT marketplace integration, this would:
        // 1. Query a royalty registry or marketplace contract to get the royalty amount for this NFT.
        // 2. Transfer the royalty amount to the creator.
        // For this example, we'll simulate a fixed royalty amount (e.g., based on royaltyPercentage).
        // Assume a hypothetical NFT sale price retrieval: uint256 salePrice = getNftSalePriceFromMarketplace(_nftId);
        uint256 hypotheticalSalePrice = 1 ether; // Example - replace with actual marketplace data retrieval
        uint256 royaltyAmount = (hypotheticalSalePrice * royaltyPercentage) / 100;
        payable(researchNFTs[_nftId].creator).transfer(royaltyAmount);
        emit RoyaltyClaimed(_nftId, msg.sender, royaltyAmount);
    }

    /// @notice Allows governance to set the royalty percentage for research NFTs. (Conceptual).
    /// @param _percentage New royalty percentage value (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _percentage) external onlyGovernance {
        require(_percentage <= 100, "Royalty percentage must be less than or equal to 100");
        royaltyPercentage = _percentage;
        emit RoyaltyPercentageSet(_percentage);
    }

    // --- Utility Functions ---

    /// @notice Returns the total number of members in the DARO.
    function membersCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getMemberList();
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns a list of all addresses that have been added as members (regardless of current membership status).
    function getMemberList() public view returns (address[] memory) {
        address[] memory memberAddresses = new address[](members.length); // Approximating size, may need adjustment in real impl
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCounter + 1; i++) { // Iterate through proposal IDs as a proxy to find potential member addresses (not perfect, needs better indexing in real world)
            if (researchProposals[i].proposer != address(0) && members[researchProposals[i].proposer]) {
                 bool found = false;
                 for(uint256 j=0; j<index; j++){
                     if(memberAddresses[j] == researchProposals[i].proposer){
                         found = true;
                         break;
                     }
                 }
                 if(!found){
                     memberAddresses[index] = researchProposals[i].proposer;
                     index++;
                 }
            }
            for (uint256 j = 0; j < proposalVotes[i].length; j++) {
                 if (proposalVotes[i][j].voter != address(0) && members[proposalVotes[i][j].voter]) {
                     bool found = false;
                     for(uint256 k=0; k<index; k++){
                         if(memberAddresses[k] == proposalVotes[i][j].voter){
                             found = true;
                             break;
                         }
                     }
                     if(!found){
                         memberAddresses[index] = proposalVotes[i][j].voter;
                         index++;
                     }
                 }
            }
        }
        address[] memory finalMemberList = new address[](index);
        for(uint256 i=0; i<index; i++){
            finalMemberList[i] = memberAddresses[i];
        }
        return finalMemberList;
    }
}
```