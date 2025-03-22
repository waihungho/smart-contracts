```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for managing a decentralized research organization.
 * It incorporates advanced concepts like decentralized governance, reputation systems,
 * dynamic funding mechanisms, IP protection, and collaborative research tools.
 *
 * Function Summary:
 * -----------------
 * **Core Research Proposal Management:**
 * 1. submitResearchProposal(title, description, fundingGoal, milestonesDescription): Allows researchers to submit new research proposals with milestones.
 * 2. voteOnProposal(proposalId, vote): Researchers can vote on research proposals (Approve/Reject).
 * 3. finalizeProposalVoting(proposalId):  Closes voting for a proposal and updates its status based on quorum and votes.
 * 4. fundProposal(proposalId) payable:  Allows anyone to contribute funds to a research proposal.
 * 5. withdrawProposalFunds(proposalId): Allows the proposer to withdraw funds for a funded proposal, only after milestones are approved.
 * 6. submitResearchMilestone(proposalId, milestoneId, milestoneDescription, ipfsDataHash): Researchers submit completed milestones with IPFS data hashes for verification.
 * 7. approveMilestone(proposalId, milestoneId): Reviewers/Researchers can vote to approve a submitted research milestone.
 * 8. rejectMilestone(proposalId, milestoneId): Reviewers/Researchers can vote to reject a submitted research milestone.
 * 9. finalizeMilestoneVoting(proposalId, milestoneId): Finalizes milestone voting and updates milestone status based on votes.
 * 10. emergencyStopProposal(proposalId): Admin function to halt a proposal in case of critical issues.
 *
 * **Researcher Reputation and Roles Management:**
 * 11. addResearcherRole(researcherAddress, role): Admin function to assign roles (e.g., Reviewer, Core Researcher) to addresses.
 * 12. removeResearcherRole(researcherAddress, role): Admin function to remove roles from addresses.
 * 13. getResearcherRole(researcherAddress): View function to check the role of a researcher.
 * 14. getResearcherReputation(researcherAddress): View function to retrieve a researcher's reputation score. (Potentially based on proposal success, milestone approvals, etc.) - Placeholder for advanced reputation logic.
 * 15. updateResearcherReputation(researcherAddress, reputationChange): Internal function to adjust researcher reputation (Admin or contract logic triggered).
 *
 * **Data and IP Management (Conceptual - IPFS Integration):**
 * 16. uploadResearchData(proposalId, ipfsDataHash, accessCost): Researchers can upload research data (via IPFS hash) and set access cost.
 * 17. purchaseResearchDataAccess(proposalId): Users can pay to access research data associated with a proposal (Conceptual - payment and access logic).
 * 18. viewResearchData(proposalId):  Allows authorized users (purchasers, researchers) to view research data (Conceptual - IPFS retrieval logic outside contract).
 *
 * **Governance and Utility Functions:**
 * 19. setQuorum(newQuorum): Admin function to change the voting quorum for proposals and milestones.
 * 20. setVotingDuration(newDuration): Admin function to adjust the voting duration for proposals and milestones.
 * 21. getProposalDetails(proposalId): View function to retrieve detailed information about a research proposal.
 * 22. getMilestoneDetails(proposalId, milestoneId): View function to retrieve details of a specific milestone.
 * 23. getContractBalance(): View function to check the contract's ETH balance.
 * 24. getResearcherProposals(researcherAddress): View function to get a list of proposal IDs associated with a researcher.
 * 25. getFundedProposals(): View function to get a list of IDs of funded proposals.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Optional: If you want to use a specific token for funding/rewards

contract DARO is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalCounter;
    Counters.Counter private _milestoneCounter;

    // Define Researcher Roles (Extendable)
    enum ResearcherRole { NONE, REVIEWER, CORE_RESEARCHER, ADMIN }

    // Struct to represent a Research Proposal
    struct ResearchProposal {
        uint256 proposalId;
        string title;
        string description;
        address proposer;
        uint256 fundingGoal;
        uint256 currentFunding;
        ProposalStatus status;
        Milestone[] milestones;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 votingEndTime;
        mapping(address => Vote) proposalVotes; // Mapping of voter address to their vote
        uint256 dataAccessCost; // Cost to access research data (conceptual)
        string ipfsDataHash; // IPFS hash for research data (conceptual)
        address[] researchers; // List of researchers involved in the proposal
    }

    // Struct to represent a Research Milestone
    struct Milestone {
        uint256 milestoneId;
        string description;
        MilestoneStatus status;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 votingEndTime;
        mapping(address => Vote) milestoneVotes; // Mapping of voter address to their vote
        string ipfsDataHash; // IPFS hash for milestone data (conceptual)
        address submitter;
        uint256 submissionTimestamp;
    }

    // Struct to represent a Vote
    struct Vote {
        bool approved; // true for approve, false for reject
        address voter;
    }

    // Proposal Status Enum
    enum ProposalStatus { PENDING, VOTING, FUNDING, IN_PROGRESS, COMPLETED, REJECTED, STOPPED }

    // Milestone Status Enum
    enum MilestoneStatus { PENDING_SUBMISSION, SUBMITTED, VOTING, APPROVED, REJECTED }

    // State Variables
    mapping(uint256 => ResearchProposal) public proposals; // Mapping proposalId to ResearchProposal struct
    mapping(uint256 => Milestone) public milestones; // Mapping milestoneId to Milestone struct (consider nested mapping if needed based on proposalId)
    mapping(address => ResearcherRole) public researcherRoles; // Mapping address to ResearcherRole
    mapping(address => uint256) public researcherReputation; // Mapping address to Reputation Score (Placeholder)
    uint256 public proposalVotingDuration = 7 days; // Default proposal voting duration
    uint256 public milestoneVotingDuration = 3 days; // Default milestone voting duration
    uint256 public proposalQuorum = 50; // Percentage quorum for proposal voting (e.g., 50 for 50%)
    uint256 public milestoneQuorum = 60; // Percentage quorum for milestone voting (e.g., 60 for 60%)
    IERC20 public daroToken; // Optional: For future token integration (e.g., rewards, governance)

    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalVoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalVotingFinalized(uint256 proposalId, ProposalStatus status);
    event ProposalFunded(uint256 proposalId, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address receiver, uint256 amount);
    event MilestoneSubmitted(uint256 proposalId, uint256 milestoneId, address submitter);
    event MilestoneVoteCast(uint256 proposalId, uint256 milestoneId, address voter, bool vote);
    event MilestoneVotingFinalized(uint256 proposalId, uint256 milestoneId, MilestoneStatus status);
    event ProposalStopped(uint256 proposalId, address admin);
    event ResearcherRoleAssigned(address researcher, ResearcherRole role, address admin);
    event ResearcherRoleRemoved(address researcher, ResearcherRole role, address admin);
    event ReputationUpdated(address researcher, uint256 newReputation);
    event DataUploaded(uint256 proposalId, string ipfsDataHash, uint256 accessCost);
    event DataAccessPurchased(uint256 proposalId, address purchaser);

    constructor() payable {
        _proposalCounter.increment(); // Start proposal IDs from 1
        _milestoneCounter.increment(); // Start milestone IDs from 1
        researcherRoles[msg.sender] = ResearcherRole.ADMIN; // Set contract deployer as Admin
    }

    modifier onlyResearcher() {
        require(researcherRoles[msg.sender] != ResearcherRole.NONE, "Caller is not a registered researcher.");
        _;
    }

    modifier onlyReviewerOrResearcher() {
        require(researcherRoles[msg.sender] == ResearcherRole.REVIEWER || researcherRoles[msg.sender] == ResearcherRole.CORE_RESEARCHER || researcherRoles[msg.sender] == ResearcherRole.ADMIN, "Caller is not a reviewer or core researcher.");
        _;
    }

    modifier onlyAdmin() {
        require(researcherRoles[msg.sender] == ResearcherRole.ADMIN, "Caller is not an admin.");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].proposalId == proposalId, "Proposal does not exist.");
        _;
    }

    modifier milestoneExists(uint256 proposalId, uint256 milestoneId) {
        require(proposals[proposalId].milestones.length > milestoneId && proposals[proposalId].milestones[milestoneId].milestoneId == milestoneId, "Milestone does not exist for this proposal.");
        _;
    }

    modifier proposalInStatus(uint256 proposalId, ProposalStatus status) {
        require(proposals[proposalId].status == status, "Proposal is not in the required status.");
        _;
    }

    modifier milestoneInStatus(uint256 proposalId, uint256 milestoneId, MilestoneStatus status) {
        require(proposals[proposalId].milestones[milestoneId].status == status, "Milestone is not in the required status.");
        _;
    }

    // 1. submitResearchProposal
    function submitResearchProposal(
        string memory title,
        string memory description,
        uint256 fundingGoal,
        string memory milestonesDescription // Consider using an array of milestone descriptions for more structured milestones
    ) public onlyResearcher {
        require(bytes(title).length > 0 && bytes(description).length > 0, "Title and description cannot be empty.");
        require(fundingGoal > 0, "Funding goal must be greater than zero.");

        uint256 proposalId = _proposalCounter.current();
        _proposalCounter.increment();

        ResearchProposal storage newProposal = proposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.proposer = msg.sender;
        newProposal.fundingGoal = fundingGoal;
        newProposal.status = ProposalStatus.PENDING; // Initial status
        newProposal.votingEndTime = block.timestamp + proposalVotingDuration;
        newProposal.researchers.push(msg.sender); // Add proposer as initial researcher

        // Create initial milestones (basic example - could be more complex)
        Milestone memory initialMilestone; // Consider allowing multiple initial milestones
        initialMilestone.milestoneId = _milestoneCounter.current();
        _milestoneCounter.increment();
        initialMilestone.description = milestonesDescription; // Basic single milestone description
        initialMilestone.status = MilestoneStatus.PENDING_SUBMISSION; // Initial milestone status
        newProposal.milestones.push(initialMilestone);

        emit ProposalSubmitted(proposalId, msg.sender, title);
    }

    // 2. voteOnProposal
    function voteOnProposal(uint256 proposalId, bool vote) public onlyReviewerOrResearcher proposalExists(proposalId) proposalInStatus(proposalId, ProposalStatus.PENDING) {
        require(proposals[proposalId].votingEndTime > block.timestamp, "Voting for this proposal has ended.");
        require(proposals[proposalId].proposalVotes[msg.sender].voter == address(0), "You have already voted on this proposal."); // Prevent double voting

        proposals[proposalId].proposalVotes[msg.sender] = Vote({approved: vote, voter: msg.sender});
        if (vote) {
            proposals[proposalId].voteCountApprove++;
        } else {
            proposals[proposalId].voteCountReject++;
        }
        emit ProposalVoteCast(proposalId, msg.sender, vote);
    }

    // 3. finalizeProposalVoting
    function finalizeProposalVoting(uint256 proposalId) public onlyAdmin proposalExists(proposalId) proposalInStatus(proposalId, ProposalStatus.PENDING) {
        require(proposals[proposalId].votingEndTime <= block.timestamp, "Voting is still ongoing.");

        uint256 totalVotes = proposals[proposalId].voteCountApprove + proposals[proposalId].voteCountReject;
        uint256 quorumReachedVotes = (totalVotes * proposalQuorum) / 100; // Calculate quorum threshold

        ProposalStatus newStatus;
        if (proposals[proposalId].voteCountApprove >= quorumReachedVotes && proposals[proposalId].voteCountApprove > proposals[proposalId].voteCountReject) {
            newStatus = ProposalStatus.VOTING; // Change to FUNDING if you want to fund directly after approval, or VOTING to move to funding stage explicitly
            proposals[proposalId].status = ProposalStatus.FUNDING; // Changed to FUNDING
        } else {
            newStatus = ProposalStatus.REJECTED;
            proposals[proposalId].status = ProposalStatus.REJECTED;
        }
        emit ProposalVotingFinalized(proposalId, newStatus);
    }

    // 4. fundProposal
    function fundProposal(uint256 proposalId) payable public proposalExists(proposalId) proposalInStatus(proposalId, ProposalStatus.FUNDING) {
        require(msg.value > 0, "Funding amount must be greater than zero.");
        proposals[proposalId].currentFunding += msg.value;
        emit ProposalFunded(proposalId, msg.value);
    }

    // 5. withdrawProposalFunds
    function withdrawProposalFunds(uint256 proposalId) public onlyResearcher proposalExists(proposalId) proposalInStatus(proposalId, ProposalStatus.IN_PROGRESS) {
        require(proposals[proposalId].proposer == msg.sender, "Only the proposer can withdraw funds.");
        require(proposals[proposalId].currentFunding > 0, "No funds to withdraw.");
        require(proposals[proposalId].milestones[0].status == MilestoneStatus.APPROVED, "Initial milestone must be approved before withdrawal."); // Basic milestone approval check

        uint256 amountToWithdraw = proposals[proposalId].currentFunding;
        proposals[proposalId].currentFunding = 0; // Set current funding to 0 after withdrawal

        (bool success, ) = payable(proposals[proposalId].proposer).call{value: amountToWithdraw}("");
        require(success, "Funds withdrawal failed.");
        emit FundsWithdrawn(proposalId, proposals[proposalId].proposer, amountToWithdraw);
    }

    // 6. submitResearchMilestone
    function submitResearchMilestone(uint256 proposalId, uint256 milestoneId, string memory milestoneDescription, string memory ipfsDataHash) public onlyResearcher proposalExists(proposalId) milestoneExists(proposalId, milestoneId) milestoneInStatus(proposalId, milestoneId, MilestoneStatus.PENDING_SUBMISSION) {
        require(proposals[proposalId].researchers.length > 0 && proposals[proposalId].researchers[0] == msg.sender, "Only researchers involved in the proposal can submit milestones."); // Basic researcher check - improve as needed
        require(bytes(milestoneDescription).length > 0, "Milestone description cannot be empty.");
        require(bytes(ipfsDataHash).length > 0, "IPFS data hash cannot be empty."); // Optional: you can remove this requirement if IPFS hash is not always mandatory

        proposals[proposalId].milestones[milestoneId].description = milestoneDescription;
        proposals[proposalId].milestones[milestoneId].ipfsDataHash = ipfsDataHash;
        proposals[proposalId].milestones[milestoneId].status = MilestoneStatus.SUBMITTED;
        proposals[proposalId].milestones[milestoneId].submitter = msg.sender;
        proposals[proposalId].milestones[milestoneId].submissionTimestamp = block.timestamp;
        proposals[proposalId].milestones[milestoneId].votingEndTime = block.timestamp + milestoneVotingDuration;
        emit MilestoneSubmitted(proposalId, milestoneId, msg.sender);
    }

    // 7. approveMilestone
    function approveMilestone(uint256 proposalId, uint256 milestoneId) public onlyReviewerOrResearcher proposalExists(proposalId) milestoneExists(proposalId, milestoneId) milestoneInStatus(proposalId, milestoneId, MilestoneStatus.SUBMITTED) {
        require(proposals[proposalId].milestones[milestoneId].votingEndTime > block.timestamp, "Voting for this milestone has ended.");
        require(proposals[proposalId].milestones[milestoneId].milestoneVotes[msg.sender].voter == address(0), "You have already voted on this milestone."); // Prevent double voting

        proposals[proposalId].milestones[milestoneId].milestoneVotes[msg.sender] = Vote({approved: true, voter: msg.sender});
        proposals[proposalId].milestones[milestoneId].voteCountApprove++;
        emit MilestoneVoteCast(proposalId, milestoneId, msg.sender, true);
    }

    // 8. rejectMilestone
    function rejectMilestone(uint256 proposalId, uint256 milestoneId) public onlyReviewerOrResearcher proposalExists(proposalId) milestoneExists(proposalId, milestoneId) milestoneInStatus(proposalId, milestoneId, MilestoneStatus.SUBMITTED) {
        require(proposals[proposalId].milestones[milestoneId].votingEndTime > block.timestamp, "Voting for this milestone has ended.");
        require(proposals[proposalId].milestones[milestoneId].milestoneVotes[msg.sender].voter == address(0), "You have already voted on this milestone."); // Prevent double voting

        proposals[proposalId].milestones[milestoneId].milestoneVotes[msg.sender] = Vote({approved: false, voter: msg.sender});
        proposals[proposalId].milestones[milestoneId].voteCountReject++;
        emit MilestoneVoteCast(proposalId, milestoneId, msg.sender, false);
    }

    // 9. finalizeMilestoneVoting
    function finalizeMilestoneVoting(uint256 proposalId, uint256 milestoneId) public onlyAdmin proposalExists(proposalId) milestoneExists(proposalId, milestoneId) milestoneInStatus(proposalId, milestoneId, MilestoneStatus.SUBMITTED) {
        require(proposals[proposalId].milestones[milestoneId].votingEndTime <= block.timestamp, "Voting is still ongoing.");

        uint256 totalVotes = proposals[proposalId].milestones[milestoneId].voteCountApprove + proposals[proposalId].milestones[milestoneId].voteCountReject;
        uint256 quorumReachedVotes = (totalVotes * milestoneQuorum) / 100; // Calculate quorum threshold

        MilestoneStatus newStatus;
        if (proposals[proposalId].milestones[milestoneId].voteCountApprove >= quorumReachedVotes && proposals[proposalId].milestones[milestoneId].voteCountApprove > proposals[proposalId].milestones[milestoneId].voteCountReject) {
            newStatus = MilestoneStatus.APPROVED;
            proposals[proposalId].milestones[milestoneId].status = MilestoneStatus.APPROVED;
            if (proposals[proposalId].status == ProposalStatus.FUNDING) {
                proposals[proposalId].status = ProposalStatus.IN_PROGRESS; // Move proposal to in-progress after first milestone approval
            }
        } else {
            newStatus = MilestoneStatus.REJECTED;
            proposals[proposalId].milestones[milestoneId].status = MilestoneStatus.REJECTED;
        }
        emit MilestoneVotingFinalized(proposalId, milestoneId, newStatus);
    }

    // 10. emergencyStopProposal
    function emergencyStopProposal(uint256 proposalId) public onlyAdmin proposalExists(proposalId) {
        proposals[proposalId].status = ProposalStatus.STOPPED;
        emit ProposalStopped(proposalId, msg.sender);
    }

    // 11. addResearcherRole
    function addResearcherRole(address researcherAddress, ResearcherRole role) public onlyAdmin {
        researcherRoles[researcherAddress] = role;
        emit ResearcherRoleAssigned(researcherAddress, role, msg.sender);
    }

    // 12. removeResearcherRole
    function removeResearcherRole(address researcherAddress, ResearcherRole role) public onlyAdmin {
        researcherRoles[researcherAddress] = ResearcherRole.NONE; // Set to NONE to effectively remove the role
        emit ResearcherRoleRemoved(researcherAddress, role, msg.sender);
    }

    // 13. getResearcherRole
    function getResearcherRole(address researcherAddress) public view returns (ResearcherRole) {
        return researcherRoles[researcherAddress];
    }

    // 14. getResearcherReputation - Placeholder (Advanced Reputation Logic Needed)
    function getResearcherReputation(address researcherAddress) public view returns (uint256) {
        return researcherReputation[researcherAddress]; // Basic retrieval - implement reputation logic
    }

    // 15. updateResearcherReputation - Placeholder (Advanced Reputation Logic Needed)
    function updateResearcherReputation(address researcherAddress, int256 reputationChange) internal onlyAdmin { // Example - can be triggered by contract logic too
        // Example Reputation Update Logic (Basic - needs more sophistication)
        if (int256(researcherReputation[researcherAddress]) + reputationChange >= 0) {
            researcherReputation[researcherAddress] = uint256(int256(researcherReputation[researcherAddress]) + reputationChange);
        } else {
            researcherReputation[researcherAddress] = 0; // Reputation cannot be negative (or handle differently)
        }
        emit ReputationUpdated(researcherAddress, researcherReputation[researcherAddress]);
    }

    // 16. uploadResearchData (Conceptual - IPFS)
    function uploadResearchData(uint256 proposalId, string memory ipfsDataHash, uint256 accessCost) public onlyResearcher proposalExists(proposalId) proposalInStatus(proposalId, ProposalStatus.IN_PROGRESS) {
        require(proposals[proposalId].researchers.length > 0 && proposals[proposalId].researchers[0] == msg.sender, "Only researchers involved in the proposal can upload data."); // Basic researcher check
        require(bytes(ipfsDataHash).length > 0, "IPFS data hash cannot be empty.");
        proposals[proposalId].ipfsDataHash = ipfsDataHash;
        proposals[proposalId].dataAccessCost = accessCost;
        emit DataUploaded(proposalId, ipfsDataHash, accessCost);
    }

    // 17. purchaseResearchDataAccess (Conceptual - Payment & Access)
    function purchaseResearchDataAccess(uint256 proposalId) payable public proposalExists(proposalId) proposalInStatus(proposalId, ProposalStatus.COMPLETED) { // Assuming COMPLETED status for data access
        require(proposals[proposalId].dataAccessCost > 0, "Data access is not available for purchase or is free.");
        require(msg.value >= proposals[proposalId].dataAccessCost, "Insufficient payment for data access.");
        // Transfer payment to the proposer or contract (depending on desired model)
        (bool success, ) = payable(proposals[proposalId].proposer).call{value: proposals[proposalId].dataAccessCost}(""); // Example: send to proposer
        require(success, "Payment transfer failed.");
        emit DataAccessPurchased(proposalId, msg.sender);
        // In a real application, you would manage access control to the IPFS data here (e.g., store purchaser list, use encryption, etc. - outside of smart contract scope usually)
    }

    // 18. viewResearchData (Conceptual - IPFS Retrieval - Off-chain)
    function viewResearchData(uint256 proposalId) public view proposalExists(proposalId) returns (string memory ipfsHash) {
        // In a real application, access control logic would be checked here (e.g., has purchaser paid? is user a researcher?).
        // This function primarily returns the IPFS hash. Actual data retrieval from IPFS is an off-chain process.
        return proposals[proposalId].ipfsDataHash;
    }

    // 19. setQuorum
    function setQuorum(uint256 newQuorum) public onlyAdmin {
        require(newQuorum <= 100, "Quorum cannot be greater than 100.");
        proposalQuorum = newQuorum;
        milestoneQuorum = newQuorum; // Or you can have separate quorums if needed
    }

    // 20. setVotingDuration
    function setVotingDuration(uint256 newDuration) public onlyAdmin {
        proposalVotingDuration = newDuration;
        milestoneVotingDuration = newDuration; // Or separate durations
    }

    // 21. getProposalDetails
    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (ResearchProposal memory) {
        return proposals[proposalId];
    }

    // 22. getMilestoneDetails
    function getMilestoneDetails(uint256 proposalId, uint256 milestoneId) public view proposalExists(proposalId) milestoneExists(proposalId, milestoneId) returns (Milestone memory) {
        return proposals[proposalId].milestones[milestoneId];
    }

    // 23. getContractBalance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 24. getResearcherProposals (Basic Example - needs more efficient indexing for large datasets)
    function getResearcherProposals(address researcherAddress) public view returns (uint256[] memory) {
        uint256[] memory researcherProposalIds = new uint256[](0); // Initialize empty array
        for (uint256 i = 1; i < _proposalCounter.current(); i++) {
            if (proposals[i].proposalId == i && proposals[i].proposer == researcherAddress) { // Basic check - can be improved with indexing
                uint256[] memory tempArray = new uint256[](researcherProposalIds.length + 1);
                for(uint256 j=0; j<researcherProposalIds.length; j++){
                    tempArray[j] = researcherProposalIds[j];
                }
                tempArray[researcherProposalIds.length] = i;
                researcherProposalIds = tempArray;
            }
        }
        return researcherProposalIds;
    }

    // 25. getFundedProposals (Basic Example - needs more efficient indexing for large datasets)
    function getFundedProposals() public view returns (uint256[] memory) {
        uint256[] memory fundedProposalIds = new uint256[](0); // Initialize empty array
        for (uint256 i = 1; i < _proposalCounter.current(); i++) {
            if (proposals[i].proposalId == i && proposals[i].status == ProposalStatus.FUNDING) { // Basic check - can be improved with indexing
                uint256[] memory tempArray = new uint256[](fundedProposalIds.length + 1);
                for(uint256 j=0; j<fundedProposalIds.length; j++){
                    tempArray[j] = fundedProposalIds[j];
                }
                tempArray[fundedProposalIds.length] = i;
                fundedProposalIds = tempArray;
            }
        }
        return fundedProposalIds;
    }

    // Optional: Function to set DARO token contract address (for future token integration)
    function setDAROTokenAddress(address tokenAddress) public onlyAdmin {
        daroToken = IERC20(tokenAddress);
    }

    // Fallback function to accept ETH
    receive() external payable {}
}
```