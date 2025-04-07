```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Research Organization (DARO).
 * It facilitates research proposal submissions, community funding, decentralized peer review,
 * intellectual property management, and incentivized research contributions.
 *
 * Function Summary:
 *
 * **Membership & Governance:**
 * 1. becomeMember(): Allows users to become members by paying a membership fee.
 * 2. revokeMembership(address _member): Allows contract owner to revoke membership.
 * 3. proposeGovernanceChange(string _proposalDescription, bytes _calldata): Allows members to propose changes to contract parameters.
 * 4. voteOnGovernanceChange(uint _proposalId, bool _support): Allows members to vote on governance change proposals.
 * 5. executeGovernanceChange(uint _proposalId): Executes a governance change if it passes voting.
 * 6. getMemberDetails(address _member): Retrieves details of a member (membership status, joined time).
 * 7. setMembershipFee(uint _newFee): Allows owner to change the membership fee.
 * 8. setVotingPeriod(uint _newPeriod): Allows owner to set the voting period for proposals.
 *
 * **Research Proposal Management:**
 * 9. submitResearchProposal(string _title, string _description, string _keywords, uint _fundingGoal, string _researchPlanCID): Submits a research proposal.
 * 10. getProposalDetails(uint _proposalId): Retrieves details of a research proposal.
 * 11. fundProposal(uint _proposalId): Allows members to fund a research proposal.
 * 12. withdrawProposalFunds(uint _proposalId): Allows researcher to withdraw funds for a funded proposal (with milestones).
 * 13. markProposalMilestoneComplete(uint _proposalId, uint _milestoneNumber, string _evidenceCID): Researcher marks a milestone as complete with evidence.
 * 14. approveMilestoneCompletion(uint _proposalId, uint _milestoneNumber): Members vote to approve a milestone completion.
 * 15. finalizeResearch(uint _proposalId, string _finalReportCID, string _researchDataCID): Researcher finalizes research with reports and data.
 * 16. claimResearcherReward(uint _proposalId): Researcher claims reward after successful research completion.
 * 17. getProposalFundingStatus(uint _proposalId): Retrieves funding status of a proposal.
 * 18. getProposalsByKeyword(string _keyword): Retrieves proposal IDs based on keywords.
 *
 * **Intellectual Property & Contribution:**
 * 19. registerResearchArtifact(uint _proposalId, string _artifactName, string _artifactCID, string _ipLicenseType): Registers a research artifact (e.g., paper, code).
 * 20. getResearchArtifactDetails(uint _artifactId): Retrieves details of a registered research artifact.
 * 21. contributeToResearch(uint _proposalId, string _contributionDescription, string _contributionCID): Allows members to contribute to ongoing research.
 * 22. getProposalContributions(uint _proposalId): Retrieves contributions made to a specific proposal.
 *
 * **Utility & Admin:**
 * 23. getContractBalance(): Returns the contract's ETH balance.
 * 24. pauseContract(): Pauses the contract functionality (owner only).
 * 25. unpauseContract(): Resumes the contract functionality (owner only).
 * 26. setArtifactRegistrationFee(uint _newFee): Allows owner to set the fee for registering research artifacts.
 */
contract DecentralizedAutonomousResearchOrganization {

    // State Variables

    address public owner;
    uint public membershipFee;
    uint public artifactRegistrationFee;
    uint public votingPeriod; // In blocks
    bool public paused;

    uint public nextProposalId;
    mapping(uint => Proposal) public proposals;
    mapping(string => uint[]) public proposalsByKeyword; // Keyword to proposal IDs

    uint public nextArtifactId;
    mapping(uint => ResearchArtifact) public researchArtifacts;

    uint public nextGovernanceProposalId;
    mapping(uint => GovernanceProposal) public governanceProposals;

    mapping(address => Member) public members;
    address[] public memberList;

    // Structs

    struct Proposal {
        uint id;
        address researcher;
        string title;
        string description;
        string[] keywords;
        uint fundingGoal;
        uint fundingRaised;
        string researchPlanCID;
        ProposalStatus status;
        uint milestonesCompleted;
        uint totalMilestones; // Placeholder for future milestone implementation
        mapping(uint => Milestone) milestones; // Milestone number to Milestone struct
        string finalReportCID;
        string researchDataCID;
        uint rewardAmount; // Placeholder for researcher reward mechanism
        uint finalizedTimestamp;
    }

    struct Milestone {
        bool completionRequested;
        bool completionApproved;
        string evidenceCID;
    }

    enum ProposalStatus {
        Pending,
        Funding,
        InProgress,
        MilestoneReview,
        Completed,
        Failed
    }

    struct ResearchArtifact {
        uint id;
        uint proposalId;
        address researcher;
        string name;
        string artifactCID;
        string ipLicenseType;
        uint registrationTimestamp;
    }

    struct GovernanceProposal {
        uint id;
        address proposer;
        string description;
        bytes calldataData; // Calldata to execute if proposal passes
        uint votingStartBlock;
        uint votingEndBlock;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }

    struct Member {
        address memberAddress;
        bool isActive;
        uint joinedTimestamp;
    }

    struct Contribution {
        address contributor;
        string description;
        string contributionCID;
        uint timestamp;
    }
    mapping(uint => Contribution[]) public proposalContributions; // Proposal ID to list of contributions

    // Events

    event MembershipJoined(address member);
    event MembershipRevoked(address member);
    event GovernanceChangeProposed(uint proposalId, address proposer, string description);
    event GovernanceVoteCast(uint proposalId, address voter, bool support);
    event GovernanceChangeExecuted(uint proposalId);
    event MembershipFeeChanged(uint newFee);
    event VotingPeriodChanged(uint newPeriod);

    event ResearchProposalSubmitted(uint proposalId, address researcher, string title);
    event ProposalFunded(uint proposalId, address funder, uint amount);
    event ProposalFundsWithdrawn(uint proposalId, address researcher, uint amount);
    event ProposalMilestoneCompletionRequested(uint proposalId, uint milestoneNumber);
    event ProposalMilestoneApproved(uint proposalId, uint milestoneNumber);
    event ResearchFinalized(uint proposalId, address researcher);
    event ResearcherRewardClaimed(uint proposalId, address researcher, uint amount);

    event ResearchArtifactRegistered(uint artifactId, uint proposalId, address researcher, string artifactName);
    event ArtifactRegistrationFeeChanged(uint newFee);
    event ResearchContributionMade(uint proposalId, address contributor, string description);

    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].isActive, "Only active members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validProposalId(uint _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier validArtifactId(uint _artifactId) {
        require(researchArtifacts[_artifactId].id == _artifactId, "Invalid artifact ID.");
        _;
    }

    modifier validGovernanceProposalId(uint _proposalId) {
        require(governanceProposals[_proposalId].id == _proposalId, "Invalid governance proposal ID.");
        _;
    }

    modifier proposalInStatus(uint _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }


    // Constructor

    constructor(uint _membershipFee, uint _artifactRegistrationFee, uint _votingPeriod) payable {
        owner = msg.sender;
        membershipFee = _membershipFee;
        artifactRegistrationFee = _artifactRegistrationFee;
        votingPeriod = _votingPeriod;
        paused = false;
        nextProposalId = 1;
        nextArtifactId = 1;
        nextGovernanceProposalId = 1;
    }

    // -------------------------------------------------------------------------
    // Membership & Governance Functions
    // -------------------------------------------------------------------------

    /// @notice Allows users to become members by paying a membership fee.
    function becomeMember() external payable whenNotPaused {
        require(msg.value >= membershipFee, "Membership fee is required.");
        require(!members[msg.sender].isActive, "Already a member.");
        members[msg.sender] = Member(msg.sender, true, block.timestamp);
        memberList.push(msg.sender);
        emit MembershipJoined(msg.sender);
    }

    /// @notice Allows contract owner to revoke membership.
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) external onlyOwner whenNotPaused {
        require(members[_member].isActive, "Not an active member.");
        members[_member].isActive = false;
        // Remove from memberList (optional - could be inefficient for large lists, consider alternative if needed)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    /// @notice Allows members to propose changes to contract parameters.
    /// @param _proposalDescription Description of the governance change proposal.
    /// @param _calldata Calldata to execute if the proposal passes.
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) external onlyMembers whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[nextGovernanceProposalId];
        proposal.id = nextGovernanceProposalId;
        proposal.proposer = msg.sender;
        proposal.description = _proposalDescription;
        proposal.calldataData = _calldata;
        proposal.votingStartBlock = block.number;
        proposal.votingEndBlock = block.number + votingPeriod;
        nextGovernanceProposalId++;
        emit GovernanceChangeProposed(proposal.id, msg.sender, _proposalDescription);
    }

    /// @notice Allows members to vote on governance change proposals.
    /// @param _proposalId ID of the governance proposal.
    /// @param _support True for yes, false for no.
    function voteOnGovernanceChange(uint _proposalId, bool _support) external onlyMembers whenNotPaused validGovernanceProposalId(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.number >= proposal.votingStartBlock && block.number <= proposal.votingEndBlock, "Voting period is not active.");
        require(!proposal.executed, "Governance proposal already executed.");

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance change if it passes voting (simple majority).
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceChange(uint _proposalId) external whenNotPaused validGovernanceProposalId(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.number > proposal.votingEndBlock, "Voting period is not over.");
        require(!proposal.executed, "Governance proposal already executed.");

        uint totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast on this proposal."); // Prevent division by zero
        require(proposal.yesVotes * 2 > totalVotes, "Governance proposal did not pass."); // Simple majority

        (bool success, ) = address(this).delegatecall(proposal.calldataData); // Use delegatecall for contract state changes
        require(success, "Governance change execution failed.");

        proposal.executed = true;
        emit GovernanceChangeExecuted(_proposalId);
    }

    /// @notice Retrieves details of a member.
    /// @param _member Address of the member.
    /// @return isActive Whether the member is active.
    /// @return joinedTimestamp Timestamp when the member joined.
    function getMemberDetails(address _member) external view returns (bool isActive, uint joinedTimestamp) {
        return (members[_member].isActive, members[_member].joinedTimestamp);
    }

    /// @notice Allows owner to change the membership fee. Governance controlled in real scenario.
    /// @param _newFee New membership fee.
    function setMembershipFee(uint _newFee) external onlyOwner whenNotPaused {
        membershipFee = _newFee;
        emit MembershipFeeChanged(_newFee);
    }

    /// @notice Allows owner to set the voting period for proposals. Governance controlled in real scenario.
    /// @param _newPeriod New voting period in blocks.
    function setVotingPeriod(uint _newPeriod) external onlyOwner whenNotPaused {
        votingPeriod = _newPeriod;
        emit VotingPeriodChanged(_newPeriod);
    }


    // -------------------------------------------------------------------------
    // Research Proposal Management Functions
    // -------------------------------------------------------------------------

    /// @notice Submits a research proposal.
    /// @param _title Title of the research proposal.
    /// @param _description Detailed description of the research.
    /// @param _keywords Keywords related to the research (comma-separated).
    /// @param _fundingGoal Funding goal in wei.
    /// @param _researchPlanCID CID of the research plan document (e.g., IPFS hash).
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        string memory _keywords,
        uint _fundingGoal,
        string memory _researchPlanCID
    ) external onlyMembers whenNotPaused {
        Proposal storage proposal = proposals[nextProposalId];
        proposal.id = nextProposalId;
        proposal.researcher = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.keywords = splitString(_keywords, ","); // Split keywords string into array
        proposal.fundingGoal = _fundingGoal;
        proposal.fundingRaised = 0;
        proposal.researchPlanCID = _researchPlanCID;
        proposal.status = ProposalStatus.Pending;
        nextProposalId++;

        // Index proposals by keywords
        for (uint i = 0; i < proposal.keywords.length; i++) {
            proposalsByKeyword[proposal.keywords[i]].push(proposal.id);
        }

        emit ResearchProposalSubmitted(proposal.id, msg.sender, _title);
    }

    /// @notice Retrieves details of a research proposal.
    /// @param _proposalId ID of the research proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Allows members to fund a research proposal.
    /// @param _proposalId ID of the research proposal to fund.
    function fundProposal(uint _proposalId) external payable onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.fundingRaised < proposal.fundingGoal, "Proposal funding goal already reached.");

        uint amountToFund = msg.value;
        if (proposal.fundingRaised + amountToFund > proposal.fundingGoal) {
            amountToFund = proposal.fundingGoal - proposal.fundingRaised;
            payable(msg.sender).transfer(msg.value - amountToFund); // Return excess funds
        }

        proposal.fundingRaised += amountToFund;
        emit ProposalFunded(_proposalId, msg.sender, amountToFund);

        if (proposal.fundingRaised >= proposal.fundingGoal) {
            proposal.status = ProposalStatus.Funding; // Change status to Funding (ready for execution) - could be InProgress directly
        }
    }

    /// @notice Allows researcher to withdraw funds for a funded proposal (with milestones).
    /// @dev For simplicity, basic withdrawal. Milestone implementation is complex and left as future enhancement.
    /// @param _proposalId ID of the research proposal.
    function withdrawProposalFunds(uint _proposalId) external onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Funding) { // Status could be Funding or InProgress
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.researcher, "Only researcher can withdraw funds.");
        require(proposal.fundingRaised > 0, "No funds to withdraw.");

        uint amountToWithdraw = proposal.fundingRaised; // For simplicity, withdraw all at once. Milestone based withdrawal is more advanced.
        proposal.fundingRaised = 0; // Set fundingRaised to 0 after withdrawal

        proposal.status = ProposalStatus.InProgress; // Move to InProgress after first withdrawal.
        payable(proposal.researcher).transfer(amountToWithdraw);
        emit ProposalFundsWithdrawn(_proposalId, proposal.researcher, amountToWithdraw);
    }

    /// @notice Researcher marks a milestone as complete with evidence.
    /// @dev Milestone approval is simplified for this example. Real implementation requires voting.
    /// @param _proposalId ID of the research proposal.
    /// @param _milestoneNumber Milestone number.
    /// @param _evidenceCID CID of the evidence for milestone completion.
    function markProposalMilestoneComplete(uint _proposalId, uint _milestoneNumber, string memory _evidenceCID) external onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.InProgress) {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.researcher, "Only researcher can mark milestones.");
        require(_milestoneNumber > 0, "Milestone number must be positive.");
        require(proposal.milestones[_milestoneNumber].completionRequested == false, "Milestone completion already requested.");

        proposal.milestones[_milestoneNumber].completionRequested = true;
        proposal.milestones[_milestoneNumber].evidenceCID = _evidenceCID;
        proposal.status = ProposalStatus.MilestoneReview; // Move to milestone review status.

        emit ProposalMilestoneCompletionRequested(_proposalId, _milestoneNumber);
    }

    /// @notice Members vote to approve a milestone completion. Simplified approval.
    /// @dev In a real DAO, this would be a voting process, not just any member approval.
    /// @param _proposalId ID of the research proposal.
    /// @param _milestoneNumber Milestone number to approve.
    function approveMilestoneCompletion(uint _proposalId, uint _milestoneNumber) external onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.MilestoneReview) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.milestones[_milestoneNumber].completionRequested, "Milestone completion not requested yet.");
        require(proposal.milestones[_milestoneNumber].completionApproved == false, "Milestone already approved.");

        proposal.milestones[_milestoneNumber].completionApproved = true;
        proposal.milestonesCompleted++;
        proposal.status = ProposalStatus.InProgress; // Back to InProgress for next milestones

        emit ProposalMilestoneApproved(_proposalId, _milestoneNumber);
    }


    /// @notice Researcher finalizes research with reports and data.
    /// @param _proposalId ID of the research proposal.
    /// @param _finalReportCID CID of the final research report.
    /// @param _researchDataCID CID of the research data.
    function finalizeResearch(uint _proposalId, string memory _finalReportCID, string memory _researchDataCID) external onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.InProgress) { // Status could be InProgress or MilestoneReview if last milestone
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.researcher, "Only researcher can finalize research.");
        require(proposal.finalizedTimestamp == 0, "Research already finalized."); // Prevent double finalization

        proposal.finalReportCID = _finalReportCID;
        proposal.researchDataCID = _researchDataCID;
        proposal.status = ProposalStatus.Completed;
        proposal.finalizedTimestamp = block.timestamp;

        // Placeholder for reward mechanism (e.g., based on success, milestones, etc.)
        proposal.rewardAmount = proposal.fundingGoal / 10; // Example: 10% of funding as reward

        emit ResearchFinalized(_proposalId, msg.sender);
    }

    /// @notice Researcher claims reward after successful research completion.
    /// @param _proposalId ID of the research proposal.
    function claimResearcherReward(uint _proposalId) external onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Completed) {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.researcher, "Only researcher can claim reward.");
        require(proposal.rewardAmount > 0, "No reward amount available.");

        uint reward = proposal.rewardAmount;
        proposal.rewardAmount = 0; // Prevent double claiming

        payable(proposal.researcher).transfer(reward);
        emit ResearcherRewardClaimed(_proposalId, proposal.researcher, reward);
    }

    /// @notice Retrieves funding status of a proposal.
    /// @param _proposalId ID of the research proposal.
    /// @return fundingGoal Funding goal.
    /// @return fundingRaised Current funding raised.
    function getProposalFundingStatus(uint _proposalId) external view validProposalId(_proposalId) returns (uint fundingGoal, uint fundingRaised) {
        return (proposals[_proposalId].fundingGoal, proposals[_proposalId].fundingRaised);
    }

    /// @notice Retrieves proposal IDs based on keywords.
    /// @param _keyword Keyword to search for.
    /// @return Proposal IDs matching the keyword.
    function getProposalsByKeyword(string memory _keyword) external view returns (uint[] memory) {
        return proposalsByKeyword[_keyword];
    }

    // -------------------------------------------------------------------------
    // Intellectual Property & Contribution Functions
    // -------------------------------------------------------------------------

    /// @notice Registers a research artifact (e.g., paper, code).
    /// @param _proposalId ID of the research proposal this artifact belongs to.
    /// @param _artifactName Name of the artifact.
    /// @param _artifactCID CID of the artifact (e.g., IPFS hash).
    /// @param _ipLicenseType Type of IP license (e.g., Creative Commons, MIT, etc.).
    function registerResearchArtifact(
        uint _proposalId,
        string memory _artifactName,
        string memory _artifactCID,
        string memory _ipLicenseType
    ) external payable onlyMembers whenNotPaused validProposalId(_proposalId) {
        require(msg.value >= artifactRegistrationFee, "Artifact registration fee is required.");
        ResearchArtifact storage artifact = researchArtifacts[nextArtifactId];
        artifact.id = nextArtifactId;
        artifact.proposalId = _proposalId;
        artifact.researcher = msg.sender;
        artifact.name = _artifactName;
        artifact.artifactCID = _artifactCID;
        artifact.ipLicenseType = _ipLicenseType;
        artifact.registrationTimestamp = block.timestamp;
        nextArtifactId++;

        emit ResearchArtifactRegistered(artifact.id, _proposalId, msg.sender, _artifactName);
    }

    /// @notice Retrieves details of a registered research artifact.
    /// @param _artifactId ID of the research artifact.
    /// @return ResearchArtifact struct containing artifact details.
    function getResearchArtifactDetails(uint _artifactId) external view validArtifactId(_artifactId) returns (ResearchArtifact memory) {
        return researchArtifacts[_artifactId];
    }

    /// @notice Allows members to contribute to ongoing research.
    /// @param _proposalId ID of the research proposal to contribute to.
    /// @param _contributionDescription Description of the contribution.
    /// @param _contributionCID CID of the contribution data (e.g., IPFS hash).
    function contributeToResearch(uint _proposalId, string memory _contributionDescription, string memory _contributionCID) external onlyMembers whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.InProgress) {
        Contribution memory contribution = Contribution({
            contributor: msg.sender,
            description: _contributionDescription,
            contributionCID: _contributionCID,
            timestamp: block.timestamp
        });
        proposalContributions[_proposalId].push(contribution);
        emit ResearchContributionMade(_proposalId, msg.sender, _contributionDescription);
    }

    /// @notice Retrieves contributions made to a specific proposal.
    /// @param _proposalId ID of the research proposal.
    /// @return Array of Contribution structs.
    function getProposalContributions(uint _proposalId) external view validProposalId(_proposalId) returns (Contribution[] memory) {
        return proposalContributions[_proposalId];
    }

    // -------------------------------------------------------------------------
    // Utility & Admin Functions
    // -------------------------------------------------------------------------

    /// @notice Returns the contract's ETH balance.
    /// @return Contract's ETH balance.
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    /// @notice Pauses the contract functionality (owner only).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes the contract functionality (owner only).
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows owner to set the fee for registering research artifacts.
    /// @param _newFee New artifact registration fee.
    function setArtifactRegistrationFee(uint _newFee) external onlyOwner whenNotPaused {
        artifactRegistrationFee = _newFee;
        emit ArtifactRegistrationFeeChanged(_newFee);
    }


    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @dev Splits a string by a delimiter and returns an array of strings.
    function splitString(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory bytesStr = bytes(_str);
        bytes memory bytesDelimiter = bytes(_delimiter);
        string[] memory splitArray = new string[](countOccurrences(_str, _delimiter) + 1);
        uint splitIndex = 0;
        uint lastSplitStart = 0;

        for (uint i = 0; i < bytesStr.length; i++) {
            bool delimiterFound = true;
            for (uint j = 0; j < bytesDelimiter.length; j++) {
                if (i + j >= bytesStr.length || bytesStr[i + j] != bytesDelimiter[j]) {
                    delimiterFound = false;
                    break;
                }
            }

            if (delimiterFound) {
                splitArray[splitIndex++] = string(slice(bytesStr, lastSplitStart, i));
                lastSplitStart = i + bytesDelimiter.length;
                i += bytesDelimiter.length - 1; // Skip delimiter
            }
        }

        splitArray[splitIndex] = string(slice(bytesStr, lastSplitStart, bytesStr.length));
        return splitArray;
    }

    /// @dev Counts the number of occurrences of a delimiter in a string.
    function countOccurrences(string memory _str, string memory _delimiter) internal pure returns (uint) {
        uint count = 0;
        bytes memory bytesStr = bytes(_str);
        bytes memory bytesDelimiter = bytes(_delimiter);

        for (uint i = 0; i <= bytesStr.length - bytesDelimiter.length; i++) {
            bool delimiterFound = true;
            for (uint j = 0; j < bytesDelimiter.length; j++) {
                if (bytesStr[i + j] != bytesDelimiter[j]) {
                    delimiterFound = false;
                    break;
                }
            }
            if (delimiterFound) {
                count++;
            }
        }
        return count;
    }

    /// @dev Slices a byte array.
    function slice(bytes memory _bytes, uint _start, uint _length) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) return bytes("");
        if (_start + _length > _bytes.length) _length = _bytes.length - _start;

        bytes memory tempBytes = new bytes(_length);

        for (uint i = 0; i < _length; i++) {
            tempBytes[i] = _bytes[_start + i];
        }
        return tempBytes;
    }
}
```