```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (Example - Conceptual and for illustrative purposes)
 * @dev A smart contract implementing a Decentralized Autonomous Research Organization (DARO).
 * It facilitates research proposal submissions, community voting, funding, reputation management,
 * decentralized data storage references, and more, fostering collaborative and transparent research.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _ipfsHash)`: Allows researchers to submit research proposals with details, funding goals, and IPFS links to supplementary documents.
 * 2. `voteOnProposal(uint256 _proposalId, bool _support)`: Token holders can vote on research proposals, expressing support or opposition.
 * 3. `fundProposal(uint256 _proposalId)`: Allows anyone to contribute funds to a research proposal that has passed the voting phase.
 * 4. `finalizeProposal(uint256 _proposalId)`: After funding is reached, the proposal can be finalized, marking it as active and releasing funds to the researcher.
 * 5. `submitResearchReport(uint256 _proposalId, string _reportIpfsHash)`: Researchers can submit reports on their research progress, linked via IPFS.
 * 6. `reviewResearchReport(uint256 _proposalId, string _reviewIpfsHash, string _reviewComment)`: Reviewers can submit reviews on research reports, also using IPFS for the review document.
 * 7. `claimResearcherReputation(address _researcher, uint256 _amount)`: Allows the contract owner (or governance) to award reputation points to researchers based on successful projects.
 * 8. `claimReviewerReputation(address _reviewer, uint256 _amount)`: Allows the contract owner (or governance) to award reputation points to reviewers based on quality reviews.
 * 9. `withdrawProposalFunds(uint256 _proposalId)`: Researchers can withdraw funds from a finalized and funded proposal.
 * 10. `cancelProposal(uint256 _proposalId)`: Allows the contract owner or governance to cancel a proposal (e.g., due to ethical concerns or unforeseen issues).
 * 11. `refundDonation(uint256 _proposalId, address _donor)`: In case a proposal is cancelled or doesn't reach funding, donors can request a refund.
 *
 * **Governance & Administration:**
 * 12. `setVotingDuration(uint256 _durationInBlocks)`: Allows the contract owner to set the duration of voting periods for proposals.
 * 13. `setQuorumPercentage(uint256 _percentage)`: Allows the contract owner to set the required quorum percentage for proposals to pass.
 * 14. `addReviewer(address _reviewer)`: Allows the contract owner to add addresses to a list of authorized reviewers.
 * 15. `removeReviewer(address _reviewer)`: Allows the contract owner to remove addresses from the list of authorized reviewers.
 * 16. `pauseContract()`: Emergency function to pause most contract operations.
 * 17. `unpauseContract()`: Function to resume contract operations after pausing.
 * 18. `transferOwnership(address newOwner)`: Standard contract ownership transfer.
 *
 * **Utility & Information:**
 * 19. `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a specific research proposal.
 * 20. `getUserReputation(address _user)`: Returns the reputation score of a given user (researcher or reviewer).
 * 21. `getDAROBalance()`: Returns the total balance of the DARO contract.
 * 22. `getVotingStatus(uint256 _proposalId)`: Returns the current voting status of a proposal (active, passed, failed).
 * 23. `isReviewer(address _account)`: Checks if an address is registered as a reviewer.
 */
contract DecentralizedAutonomousResearchOrganization {
    // State Variables

    address public owner;
    bool public paused;
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 51; // Default quorum percentage for proposals to pass
    uint256 public proposalCounter;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public userReputation;
    mapping(address => bool) public isReviewerAccount;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => votedSupport

    struct Proposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string proposalIpfsHash;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        string researchReportIpfsHash;
        string reviewIpfsHash; // Optional - could be multiple reviews, but for simplicity, one reviewer's IPFS hash
        string reviewComment;
    }

    enum ProposalStatus {
        Pending,
        Voting,
        Funded,
        ActiveResearch,
        ResearchComplete,
        Cancelled,
        FailedVoting,
        FailedFunding
    }

    // Events
    event ProposalSubmitted(uint256 proposalId, address researcher, string title);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalFunded(uint256 proposalId, uint256 fundingAmount);
    event ProposalFinalized(uint256 proposalId);
    event ResearchReportSubmitted(uint256 proposalId, string reportIpfsHash);
    event ReviewSubmitted(uint256 proposalId, string reviewIpfsHash, string reviewComment);
    event ReputationAwarded(address user, uint256 amount, string reason);
    event ProposalCancelled(uint256 proposalId, string reason);
    event DonationRefunded(uint256 proposalId, address donor, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist.");
        _;
    }

    modifier onlyResearcher(uint256 _proposalId) {
        require(proposals[_proposalId].researcher == msg.sender, "Only researcher can call this function.");
        _;
    }

    modifier onlyReviewer() {
        require(isReviewerAccount[msg.sender], "Only authorized reviewers can call this function.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        paused = false;
        proposalCounter = 1; // Start proposal IDs from 1
    }

    // --- Core Functionality ---

    /// @notice Submit a research proposal.
    /// @param _title Title of the research proposal.
    /// @param _description Detailed description of the research proposal.
    /// @param _fundingGoal Funding goal in Wei for the research.
    /// @param _ipfsHash IPFS hash pointing to detailed proposal documents.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHash
    ) external whenNotPaused {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty.");

        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            researcher: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            proposalIpfsHash: _ipfsHash,
            voteStartTime: 0,
            voteEndTime: 0,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            researchReportIpfsHash: "",
            reviewIpfsHash: "",
            reviewComment: ""
        });

        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
        proposalCounter++;
    }

    /// @notice Start voting on a pending research proposal. Can be triggered by anyone or automated.
    /// @param _proposalId ID of the proposal to start voting for.
    function startVotingOnProposal(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        proposals[_proposalId].status = ProposalStatus.Voting;
        proposals[_proposalId].voteStartTime = block.number;
        proposals[_proposalId].voteEndTime = block.number + votingDurationBlocks;
    }


    /// @notice Vote on a research proposal.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support True for support, false for opposition.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Voting) {
        require(block.number <= proposals[_proposalId].voteEndTime, "Voting period has ended.");
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true; // Record that voter has voted

        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }

        emit VoteCast(_proposalId, msg.sender, _support);

        // Check if voting period ended and finalize if quorum is reached (or failed)
        if (block.number >= proposals[_proposalId].voteEndTime) {
            _finalizeVoting(_proposalId);
        }
    }

    /// @dev Internal function to finalize voting on a proposal after voting period ends.
    /// @param _proposalId ID of the proposal to finalize voting for.
    function _finalizeVoting(uint256 _proposalId) internal proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Voting) {
        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 quorum = (totalVotes * 100) / quorumPercentage; // Calculate quorum needed based on percentage

        if (totalVotes > 0 && (proposals[_proposalId].votesFor * 100) >= quorum) { // Proposal passed if votesFor meets quorum of total votes cast
            proposals[_proposalId].status = ProposalStatus.Funded;
        } else {
            proposals[_proposalId].status = ProposalStatus.FailedVoting;
        }
    }


    /// @notice Fund a research proposal that has passed voting.
    /// @param _proposalId ID of the proposal to fund.
    function fundProposal(uint256 _proposalId) external payable whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Funded) {
        require(proposals[_proposalId].currentFunding + msg.value <= proposals[_proposalId].fundingGoal, "Funding exceeds goal.");
        proposals[_proposalId].currentFunding += msg.value;
        emit ProposalFunded(_proposalId, msg.value);

        if (proposals[_proposalId].currentFunding >= proposals[_proposalId].fundingGoal) {
            proposals[_proposalId].status = ProposalStatus.ActiveResearch;
            emit ProposalFinalized(_proposalId);
        }
    }

    /// @notice Finalize a proposal manually if funding goal is reached (or other conditions met).
    /// @param _proposalId ID of the proposal to finalize.
    function finalizeProposal(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Funded) {
        require(proposals[_proposalId].currentFunding >= proposals[_proposalId].fundingGoal, "Funding goal not yet reached.");
        proposals[_proposalId].status = ProposalStatus.ActiveResearch;
        emit ProposalFinalized(_proposalId);
    }


    /// @notice Researcher submits a report on their research progress.
    /// @param _proposalId ID of the research proposal.
    /// @param _reportIpfsHash IPFS hash of the research report document.
    function submitResearchReport(uint256 _proposalId, string memory _reportIpfsHash) external whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.ActiveResearch) onlyResearcher(_proposalId) {
        require(bytes(_reportIpfsHash).length > 0, "Report IPFS hash cannot be empty.");
        proposals[_proposalId].researchReportIpfsHash = _reportIpfsHash;
        proposals[_proposalId].status = ProposalStatus.ResearchComplete; // Or a different status like 'ReportSubmitted'
        emit ResearchReportSubmitted(_proposalId, _reportIpfsHash);
    }

    /// @notice Reviewer submits a review for a research report.
    /// @param _proposalId ID of the research proposal.
    /// @param _reviewIpfsHash IPFS hash of the review document.
    /// @param _reviewComment Textual comment on the review.
    function reviewResearchReport(uint256 _proposalId, string memory _reviewIpfsHash, string memory _reviewComment) external whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.ResearchComplete) onlyReviewer {
        require(bytes(_reviewIpfsHash).length > 0, "Review IPFS hash cannot be empty.");
        proposals[_proposalId].reviewIpfsHash = _reviewIpfsHash;
        proposals[_proposalId].reviewComment = _reviewComment;
        emit ReviewSubmitted(_proposalId, _reviewIpfsHash, _reviewComment);
        // Potentially update proposal status or trigger reputation rewards here.
    }

    /// @notice Award reputation to a researcher. Only callable by the contract owner.
    /// @param _researcher Address of the researcher to award reputation to.
    /// @param _amount Amount of reputation points to award.
    function claimResearcherReputation(address _researcher, uint256 _amount) external onlyOwner whenNotPaused {
        userReputation[_researcher] += _amount;
        emit ReputationAwarded(_researcher, _amount, "Researcher reputation award");
    }

    /// @notice Award reputation to a reviewer. Only callable by the contract owner.
    /// @param _reviewer Address of the reviewer to award reputation to.
    /// @param _amount Amount of reputation points to award.
    function claimReviewerReputation(address _reviewer, uint256 _amount) external onlyOwner whenNotPaused {
        userReputation[_reviewer] += _amount;
        emit ReputationAwarded(_reviewer, _amount, "Reviewer reputation award");
    }

    /// @notice Researcher withdraws funds from a finalized and funded proposal.
    /// @param _proposalId ID of the proposal to withdraw funds from.
    function withdrawProposalFunds(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.ActiveResearch) onlyResearcher(_proposalId) {
        uint256 amountToWithdraw = proposals[_proposalId].currentFunding;
        require(amountToWithdraw > 0, "No funds available to withdraw.");
        proposals[_proposalId].currentFunding = 0; // Set contract balance for proposal to 0 after withdraw.
        payable(proposals[_proposalId].researcher).transfer(amountToWithdraw);
    }

    /// @notice Cancel a proposal. Only callable by the contract owner.
    /// @param _proposalId ID of the proposal to cancel.
    /// @param _reason Reason for cancellation.
    function cancelProposal(uint256 _proposalId, string memory _reason) external onlyOwner whenNotPaused proposalExists(_proposalId) {
        proposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, _reason);
    }

    /// @notice Donor requests a refund for their donation to a cancelled or failed proposal.
    /// @param _proposalId ID of the proposal.
    /// @param _donor Address of the donor requesting refund.
    function refundDonation(uint256 _proposalId, address _donor) external whenNotPaused proposalExists(_proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Cancelled || proposals[_proposalId].status == ProposalStatus.FailedVoting || proposals[_proposalId].status == ProposalStatus.FailedFunding, "Proposal is not eligible for refunds.");
        // In a real system, you'd need to track individual donations to refund specific amounts.
        // This is a simplified version for demonstration.
        // For simplicity, we assume all funds are refundable proportionally or handle refunds off-chain.
        // **In a more advanced contract, track donations per donor and refund accordingly.**

        // **Simplified refund - refunding all current funding back to donors proportionally would be complex here without donation tracking.**
        // **A simpler approach (less fair) could be to refund a portion of the contract balance to the donor if possible.**
        // **Or, for this example, just emit an event indicating a refund is due and handle off-chain.**
        emit DonationRefunded(_proposalId, _donor, 0); // Amount 0 for simplified example - handle refund logic off-chain.
        // **Important Note:** In a real-world scenario, implement proper donation tracking and refund logic.
    }


    // --- Governance & Administration ---

    /// @notice Set the voting duration for proposals. Only callable by the contract owner.
    /// @param _durationInBlocks Duration in Ethereum blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner whenNotPaused {
        require(_durationInBlocks > 0, "Voting duration must be greater than zero.");
        votingDurationBlocks = _durationInBlocks;
    }

    /// @notice Set the quorum percentage for proposals to pass. Only callable by the contract owner.
    /// @param _percentage Quorum percentage (e.g., 51 for 51%).
    function setQuorumPercentage(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage > 0 && _percentage <= 100, "Quorum percentage must be between 1 and 100.");
        quorumPercentage = _percentage;
    }

    /// @notice Add an address to the list of authorized reviewers. Only callable by the contract owner.
    /// @param _reviewer Address to add as a reviewer.
    function addReviewer(address _reviewer) external onlyOwner whenNotPaused {
        isReviewerAccount[_reviewer] = true;
    }

    /// @notice Remove an address from the list of authorized reviewers. Only callable by the contract owner.
    /// @param _reviewer Address to remove from reviewers.
    function removeReviewer(address _reviewer) external onlyOwner whenNotPaused {
        isReviewerAccount[_reviewer] = false;
    }

    /// @notice Pause the contract, halting most operations. Only callable by the contract owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
    }

    /// @notice Unpause the contract, resuming operations. Only callable by the contract owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
    }

    /// @notice Transfer contract ownership to a new address. Only callable by the current owner.
    /// @param newOwner Address of the new contract owner.
    function transferOwnership(address newOwner) external onlyOwner whenNotPaused {
        require(newOwner != address(0), "New owner address cannot be zero.");
        owner = newOwner;
    }


    // --- Utility & Information ---

    /// @notice Get details of a specific research proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Get the reputation score of a user.
    /// @param _user Address of the user.
    /// @return Reputation score of the user.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Get the total balance of the DARO contract.
    /// @return Balance of the contract in Wei.
    function getDAROBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Get the current voting status of a proposal.
    /// @param _proposalId ID of the proposal.
    /// @return ProposalStatus enum value representing the voting status.
    function getVotingStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    /// @notice Check if an address is registered as a reviewer.
    /// @param _account Address to check.
    /// @return True if the address is a reviewer, false otherwise.
    function isReviewer(address _account) external view returns (bool) {
        return isReviewerAccount[_account];
    }

    // Fallback function to receive Ether donations without explicit function call
    receive() external payable {}
    fallback() external payable {}
}
```