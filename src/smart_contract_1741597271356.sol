```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Research Organization (DARO)
 * for funding, managing, and governing research projects in a decentralized manner.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *    - `requestMembership()`: Allows an address to request membership in the DARO.
 *    - `approveMembership(address _applicant)`: Admin function to approve a membership request.
 *    - `revokeMembership(address _member)`: Admin function to revoke membership.
 *    - `isMember(address _address)`: Checks if an address is a member of the DARO.
 *
 * **2. Research Proposal Management:**
 *    - `submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, string memory _researchPlan)`: Members can submit research proposals.
 *    - `reviewResearchProposal(uint256 _proposalId, string memory _review)`: Members can submit reviews for proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on research proposals.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific research proposal.
 *    - `getAllProposals()`: Retrieves a list of all proposal IDs.
 *    - `getProposalsByStatus(ProposalStatus _status)`: Retrieves a list of proposal IDs filtered by status.
 *
 * **3. Funding and Budget Management:**
 *    - `depositFunds()`: Allows anyone to deposit funds into the DARO contract.
 *    - `withdrawFunds(uint256 _amount)`: Admin function to withdraw funds from the contract.
 *    - `fundResearchProject(uint256 _proposalId)`: Admin function to allocate funds to an approved research project.
 *    - `getContractBalance()`: Returns the current balance of the contract.
 *    - `getProjectFundingStatus(uint256 _proposalId)`: Returns the funding status of a research project.
 *
 * **4. Governance and Decision Making:**
 *    - `createGovernanceProposal(string memory _title, string memory _description, bytes memory _actions)`: Members can create governance proposals (e.g., change rules).
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Members can vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Admin function to execute approved governance proposals.
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *
 * **5. Utility and Miscellaneous Functions:**
 *    - `pauseContract()`: Admin function to pause the contract.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `getContractStatus()`: Returns the current status of the contract (paused/unpaused).
 */

contract DecentralizedAutonomousResearchOrganization {

    // --- Enums and Structs ---

    enum ProposalStatus {
        PENDING_REVIEW,
        UNDER_VOTING,
        APPROVED,
        REJECTED,
        FUNDED,
        IN_PROGRESS,
        COMPLETED
    }

    struct ResearchProposal {
        uint256 id;
        string title;
        string description;
        uint256 fundingGoal;
        string researchPlan;
        address proposer;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
        mapping(address => string) reviews; // Reviewer address => Review text
        uint256 fundingAllocated;
    }

    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        bytes actions; // Encoded function calls or parameters for execution
        address proposer;
        uint256 upVotes;
        uint256 downVotes;
        bool executed;
    }

    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        bool isActive;
    }

    // --- State Variables ---

    address public admin;
    bool public paused;
    uint256 public nextProposalId;
    uint256 public nextGovernanceProposalId;
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => Member) public members;
    address[] public memberList;
    mapping(address => bool) public membershipRequested;
    uint256 public membershipFee; // Optional: For future implementation of membership fees

    // --- Events ---

    event MembershipRequested(address indexed applicant);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event ResearchProposalSubmitted(uint256 proposalId, address indexed proposer, string title);
    event ResearchProposalReviewed(uint256 proposalId, address indexed reviewer);
    event ResearchProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event ResearchProposalStatusUpdated(uint256 proposalId, ProposalStatus newStatus);
    event ResearchProjectFunded(uint256 proposalId, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, address indexed proposer, string title);
    event GovernanceProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        paused = false;
        nextProposalId = 1;
        nextGovernanceProposalId = 1;
        membershipFee = 0; // Initially set to 0, can be adjusted later via governance
    }

    // --- 1. Membership Management Functions ---

    /// @notice Allows an address to request membership in the DARO.
    function requestMembership() external whenNotPaused {
        require(!isMember(msg.sender), "Already a member");
        require(!membershipRequested[msg.sender], "Membership already requested");
        membershipRequested[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve a membership request.
    /// @param _applicant The address of the applicant to approve.
    function approveMembership(address _applicant) external onlyAdmin whenNotPaused {
        require(membershipRequested[_applicant], "Membership not requested");
        require(!isMember(_applicant), "Already a member");
        members[_applicant] = Member(_applicant, block.timestamp, true);
        memberList.push(_applicant);
        membershipRequested[_applicant] = false;
        emit MembershipApproved(_applicant);
    }

    /// @notice Admin function to revoke membership.
    /// @param _member The address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin whenNotPaused {
        require(isMember(_member), "Not a member");
        members[_member].isActive = false;
        // Optional: Remove from memberList for cleaner iteration if needed
        emit MembershipRevoked(_member);
    }

    /// @notice Checks if an address is a member of the DARO.
    /// @param _address The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _address) public view returns (bool) {
        return members[_address].isActive;
    }

    /// @notice Returns the list of active members.
    function getMemberList() external view returns (address[] memory) {
        address[] memory activeMembers = new address[](memberList.length);
        uint256 count = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].isActive) {
                activeMembers[count] = memberList[i];
                count++;
            }
        }
        // Resize the array to remove empty slots
        assembly {
            mstore(activeMembers, count) // Set the length of the dynamic array
        }
        return activeMembers;
    }


    // --- 2. Research Proposal Management Functions ---

    /// @notice Members can submit research proposals.
    /// @param _title The title of the research proposal.
    /// @param _description A brief description of the research proposal.
    /// @param _fundingGoal The funding goal for the research project.
    /// @param _researchPlan A detailed research plan.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _researchPlan
    ) external onlyMember whenNotPaused {
        require(_fundingGoal > 0, "Funding goal must be positive");
        researchProposals[nextProposalId] = ResearchProposal({
            id: nextProposalId,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            researchPlan: _researchPlan,
            proposer: msg.sender,
            status: ProposalStatus.PENDING_REVIEW,
            upVotes: 0,
            downVotes: 0,
            fundingAllocated: 0
        });
        emit ResearchProposalSubmitted(nextProposalId, msg.sender, _title);
        nextProposalId++;
    }

    /// @notice Members can submit reviews for proposals.
    /// @param _proposalId The ID of the research proposal to review.
    /// @param _review The review text.
    function reviewResearchProposal(uint256 _proposalId, string memory _review) external onlyMember whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        require(researchProposals[_proposalId].status == ProposalStatus.PENDING_REVIEW || researchProposals[_proposalId].status == ProposalStatus.UNDER_VOTING, "Proposal not in reviewable status");
        researchProposals[_proposalId].reviews[msg.sender] = _review;
        emit ResearchProposalReviewed(_proposalId, msg.sender);
    }

    /// @notice Members can vote on research proposals.
    /// @param _proposalId The ID of the research proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        require(researchProposals[_proposalId].status == ProposalStatus.PENDING_REVIEW || researchProposals[_proposalId].status == ProposalStatus.UNDER_VOTING, "Proposal not in votable status");
        require(researchProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on own proposal"); // Self-governance rule
        if (_vote) {
            researchProposals[_proposalId].upVotes++;
        } else {
            researchProposals[_proposalId].downVotes++;
        }
        emit ResearchProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Retrieves details of a specific research proposal.
    /// @param _proposalId The ID of the research proposal.
    /// @return ResearchProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (ResearchProposal memory) {
        require(researchProposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        return researchProposals[_proposalId];
    }

    /// @notice Retrieves a list of all proposal IDs.
    /// @return Array of proposal IDs.
    function getAllProposals() external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](nextProposalId - 1);
        for (uint256 i = 1; i < nextProposalId; i++) {
            proposalIds[i - 1] = i;
        }
        return proposalIds;
    }

    /// @notice Retrieves a list of proposal IDs filtered by status.
    /// @param _status The status to filter by.
    /// @return Array of proposal IDs with the specified status.
    function getProposalsByStatus(ProposalStatus _status) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (researchProposals[i].status == _status) {
                count++;
            }
        }
        uint256[] memory proposalIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (researchProposals[i].status == _status) {
                proposalIds[index] = i;
                index++;
            }
        }
        return proposalIds;
    }

    /// @notice Function to update proposal status (Admin or Governance driven)
    /// @param _proposalId The ID of the proposal to update.
    /// @param _newStatus The new status to set.
    function updateProposalStatus(uint256 _proposalId, ProposalStatus _newStatus) external onlyAdmin whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        researchProposals[_proposalId].status = _newStatus;
        emit ResearchProposalStatusUpdated(_proposalId, _newStatus);
    }


    // --- 3. Funding and Budget Management Functions ---

    /// @notice Allows anyone to deposit funds into the DARO contract.
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Admin function to withdraw funds from the contract.
    /// @param _amount The amount to withdraw.
    function withdrawFunds(uint256 _amount) external onlyAdmin whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        payable(admin).transfer(_amount);
        emit FundsWithdrawn(admin, _amount);
    }

    /// @notice Admin function to allocate funds to an approved research project.
    /// @param _proposalId The ID of the research proposal to fund.
    function fundResearchProject(uint256 _proposalId) external onlyAdmin whenNotPaused {
        require(researchProposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        require(researchProposals[_proposalId].status == ProposalStatus.APPROVED, "Proposal not approved for funding");
        require(researchProposals[_proposalId].fundingAllocated == 0, "Proposal already funded");
        require(address(this).balance >= researchProposals[_proposalId].fundingGoal, "Insufficient contract balance to fund proposal");

        researchProposals[_proposalId].fundingAllocated = researchProposals[_proposalId].fundingGoal;
        researchProposals[_proposalId].status = ProposalStatus.FUNDED;
        emit ResearchProjectFunded(_proposalId, researchProposals[_proposalId].fundingGoal);
        emit ResearchProposalStatusUpdated(_proposalId, ProposalStatus.FUNDED);

        // Optionally trigger transfer of funds to the proposer (consider multi-sig or milestones for larger projects)
        payable(researchProposals[_proposalId].proposer).transfer(researchProposals[_proposalId].fundingGoal);
    }

    /// @notice Returns the current balance of the contract.
    /// @return The contract balance in wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the funding status of a research project.
    /// @param _proposalId The ID of the research proposal.
    /// @return The funding allocated to the project.
    function getProjectFundingStatus(uint256 _proposalId) external view returns (uint256) {
        require(researchProposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        return researchProposals[_proposalId].fundingAllocated;
    }


    // --- 4. Governance and Decision Making Functions ---

    /// @notice Members can create governance proposals (e.g., change rules).
    /// @param _title The title of the governance proposal.
    /// @param _description A brief description of the governance proposal.
    /// @param _actions Encoded function calls or parameters for execution (advanced feature, needs careful implementation).
    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        bytes memory _actions
    ) external onlyMember whenNotPaused {
        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            id: nextGovernanceProposalId,
            title: _title,
            description: _description,
            actions: _actions,
            proposer: msg.sender,
            upVotes: 0,
            downVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(nextGovernanceProposalId, msg.sender, _title);
        nextGovernanceProposalId++;
    }

    /// @notice Members can vote on governance proposals.
    /// @param _proposalId The ID of the governance proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(governanceProposals[_proposalId].id == _proposalId, "Invalid governance proposal ID");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed");
        if (_vote) {
            governanceProposals[_proposalId].upVotes++;
        } else {
            governanceProposals[_proposalId].downVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Admin function to execute approved governance proposals.
    /// @dev  Currently simple majority vote for approval. More complex voting logic can be implemented.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external onlyAdmin whenNotPaused {
        require(governanceProposals[_proposalId].id == _proposalId, "Invalid governance proposal ID");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed");
        require(governanceProposals[_proposalId].upVotes > governanceProposals[_proposalId].downVotes, "Governance proposal not approved by majority");

        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);

        // Advanced: Execute actions encoded in governanceProposals[_proposalId].actions
        //  - This requires careful design to prevent vulnerabilities.
        //  - For simplicity in this example, we are not implementing action execution,
        //    but in a real-world scenario, you could use delegatecall or other mechanisms
        //    to execute encoded function calls.
        // Example (Conceptual - Needs secure implementation and encoding/decoding):
        // (bool success, bytes memory returnData) = address(this).delegatecall(governanceProposals[_proposalId].actions);
        // require(success, "Governance proposal execution failed");
    }

    /// @notice Retrieves details of a specific governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @return GovernanceProposal struct containing proposal details.
    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        require(governanceProposals[_proposalId].id == _proposalId, "Invalid governance proposal ID");
        return governanceProposals[_proposalId];
    }


    // --- 5. Utility and Miscellaneous Functions ---

    /// @notice Admin function to pause the contract.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Returns the current status of the contract (paused/unpaused).
    /// @return True if paused, false otherwise.
    function getContractStatus() external view returns (bool) {
        return paused;
    }

    /// @notice Fallback function to reject direct ether transfers to the contract (unless depositing via depositFunds).
    fallback() external payable {
        if (msg.data.length == 0) {
            revert("Direct ether transfers are not allowed, use depositFunds function");
        }
    }

    receive() external payable {
        if (msg.data.length == 0) {
            emit FundsDeposited(msg.sender, msg.value); // Allow receiving ether with empty calldata as deposit
        }
    }
}
```