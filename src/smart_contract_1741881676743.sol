```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Studio (DACS)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized creative studio, enabling collaborative content creation,
 * intellectual property management, and community governance.

 * **Outline & Function Summary:**

 * **1. Membership & Governance:**
 *    - `requestMembership()`: Allows users to request membership to the DACS.
 *    - `approveMembership(address _member)`: Owner-only function to approve membership requests.
 *    - `revokeMembership(address _member)`: Owner-only function to revoke membership.
 *    - `isMember(address _user)`: Checks if an address is a member.
 *    - `proposeGovernanceChange(string _proposalDetails)`: Members can propose changes to DACS parameters.
 *    - `voteOnGovernanceChange(uint _proposalId, bool _vote)`: Members can vote on governance proposals.
 *    - `executeGovernanceChange(uint _proposalId)`: Owner-only function to execute approved governance proposals.

 * **2. Project Management:**
 *    - `createProject(string _projectName, string _projectDescription, uint _targetBudget)`: Members can create new creative projects.
 *    - `contributeToProject(uint _projectId) payable`: Members can contribute funds to projects.
 *    - `requestProjectFunds(uint _projectId, uint _amount, string _reason)`: Project leads can request funds from project budget.
 *    - `approveProjectFundsRequest(uint _projectId, uint _requestId)`: Owner-only function to approve project fund requests.
 *    - `markProjectStage(uint _projectId, ProjectStage _stage)`: Project leads can update project stage.
 *    - `completeProject(uint _projectId)`: Project leads can mark a project as completed.
 *    - `distributeProjectRewards(uint _projectId)`: Owner-only function to distribute rewards to project contributors after completion.

 * **3. Intellectual Property (IP) & Licensing:**
 *    - `registerCreativeWork(string _workName, string _workDescription, string _ipfsHash)`: Members can register their creative works and associate IPFS hash.
 *    - `requestLicense(uint _workId, LicenseType _licenseType, address _licensee)`: Users can request licenses for registered creative works.
 *    - `approveLicense(uint _workId, uint _licenseRequestId)`: Owner-only function to approve license requests.
 *    - `getLicenseDetails(uint _workId, uint _licenseRequestId)`: View function to get details of a specific license request.

 * **4. Reputation & Skill System:**
 *    - `endorseMemberSkill(address _member, string _skill)`: Members can endorse other members for specific skills.
 *    - `getMemberSkills(address _member)`: View function to get skills endorsed for a member.

 * **5. Treasury & Financial Management:**
 *    - `depositToTreasury() payable`: Allows anyone to deposit ETH into the DACS treasury.
 *    - `withdrawFromTreasury(address _recipient, uint _amount)`: Owner-only function to withdraw ETH from the treasury.
 *    - `getTreasuryBalance()`: View function to get the current treasury balance.

 * **6. Events:**
 *    - Emits various events for key actions like membership changes, project updates, fund transfers, IP registration, etc.
 */

contract DecentralizedCreativeStudio {

    // --- Enums and Structs ---

    enum ProjectStage {
        PROPOSAL,
        FUNDING,
        IN_PROGRESS,
        COMPLETED,
        ARCHIVED
    }

    enum LicenseType {
        COMMERCIAL,
        NON_COMMERCIAL,
        CREATIVE_COMMONS // Example, can expand with specific CC licenses
    }

    struct Project {
        string projectName;
        string projectDescription;
        address projectLead;
        ProjectStage stage;
        uint targetBudget;
        uint currentBudget;
        uint startTime;
        mapping(uint => FundRequest) fundRequests; // requestId => FundRequest
        uint nextFundRequestId;
        bool completed;
    }

    struct FundRequest {
        uint amount;
        string reason;
        address requester;
        bool approved;
    }

    struct CreativeWork {
        string workName;
        string workDescription;
        string ipfsHash;
        address creator;
        uint registrationTime;
        mapping(uint => LicenseRequest) licenseRequests; // requestId => LicenseRequest
        uint nextLicenseRequestId;
    }

    struct LicenseRequest {
        LicenseType licenseType;
        address licensee;
        bool approved;
        uint requestTime;
    }

    struct GovernanceProposal {
        string proposalDetails;
        address proposer;
        uint startTime;
        uint endTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }

    struct Member {
        bool isActive;
        uint joinTime;
        mapping(string => bool) skills; // skillName => endorsed
    }


    // --- State Variables ---

    address public owner;
    mapping(address => Member) public members;
    address[] public pendingMembershipRequests;
    mapping(uint => Project) public projects;
    uint public nextProjectId;
    mapping(uint => CreativeWork) public creativeWorks;
    uint public nextWorkId;
    mapping(uint => GovernanceProposal) public governanceProposals;
    uint public nextProposalId;
    uint public governanceVoteDuration = 7 days; // Default vote duration, can be changed by governance
    uint public treasuryBalance; // Keep track of treasury balance for view function efficiency

    // --- Events ---

    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member, address indexed approvedBy);
    event MembershipRevoked(address indexed member, address indexed revokedBy);
    event ProjectCreated(uint indexed projectId, string projectName, address indexed projectLead);
    event ProjectContribution(uint indexed projectId, address indexed contributor, uint amount);
    event ProjectFundsRequested(uint indexed projectId, uint requestId, uint amount, string reason, address indexed requester);
    event ProjectFundsRequestApproved(uint indexed projectId, uint requestId, address indexed approver);
    event ProjectStageUpdated(uint indexed projectId, ProjectStage stage);
    event ProjectCompleted(uint indexed projectId);
    event ProjectRewardsDistributed(uint indexed projectId);
    event CreativeWorkRegistered(uint indexed workId, string workName, address indexed creator, string ipfsHash);
    event LicenseRequested(uint indexed workId, uint requestId, LicenseType licenseType, address indexed licensee);
    event LicenseApproved(uint indexed workId, uint requestId, address indexed approver);
    event GovernanceProposalCreated(uint indexed proposalId, string proposalDetails, address indexed proposer);
    event GovernanceVoteCast(uint indexed proposalId, address indexed voter, bool vote);
    event GovernanceProposalExecuted(uint indexed proposalId);
    event SkillEndorsed(address indexed member, address indexed endorser, string skill);
    event TreasuryDeposit(address indexed depositor, uint amount);
    event TreasuryWithdrawal(address indexed recipient, uint amount, address indexed withdrawer);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier validProjectId(uint _projectId) {
        require(_projectId < nextProjectId, "Invalid project ID.");
        _;
    }

    modifier validWorkId(uint _workId) {
        require(_workId < nextWorkId, "Invalid work ID.");
        _;
    }

    modifier validProposalId(uint _proposalId) {
        require(_proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier projectLeadOnly(uint _projectId) {
        require(projects[_projectId].projectLead == msg.sender, "Only project lead can call this function.");
        _;
    }

    modifier fundRequestExists(uint _projectId, uint _requestId) {
        require(projects[_projectId].fundRequests[_requestId].requester != address(0), "Invalid fund request ID.");
        _;
    }

    modifier licenseRequestExists(uint _workId, uint _requestId) {
        require(creativeWorks[_workId].licenseRequests[_requestId].licensee != address(0), "Invalid license request ID.");
        _;
    }

    modifier governanceProposalActive(uint _proposalId) {
        require(block.timestamp >= governanceProposals[_proposalId].startTime && block.timestamp <= governanceProposals[_proposalId].endTime, "Governance proposal is not active.");
        _;
    }

    modifier governanceProposalNotExecuted(uint _proposalId) {
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }


    // --- 1. Membership & Governance ---

    function requestMembership() external {
        require(!isMember(msg.sender), "Already a member.");
        require(!isPendingMember(msg.sender), "Membership request already pending.");
        pendingMembershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyOwner {
        require(isPendingMember(_member), "No pending membership request for this address.");
        members[_member] = Member({isActive: true, joinTime: block.timestamp});
        // Remove from pending requests
        for (uint i = 0; i < pendingMembershipRequests.length; i++) {
            if (pendingMembershipRequests[i] == _member) {
                pendingMembershipRequests[i] = pendingMembershipRequests[pendingMembershipRequests.length - 1];
                pendingMembershipRequests.pop();
                break;
            }
        }
        emit MembershipApproved(_member, msg.sender);
    }

    function revokeMembership(address _member) external onlyOwner {
        require(isMember(_member), "Not a member.");
        members[_member].isActive = false;
        emit MembershipRevoked(_member, msg.sender);
    }

    function isMember(address _user) public view returns (bool) {
        return members[_user].isActive;
    }

    function isPendingMember(address _user) private view returns (bool) {
        for (uint i = 0; i < pendingMembershipRequests.length; i++) {
            if (pendingMembershipRequests[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function proposeGovernanceChange(string _proposalDetails) external onlyMember {
        GovernanceProposal storage proposal = governanceProposals[nextProposalId];
        proposal.proposalDetails = _proposalDetails;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + governanceVoteDuration;
        proposal.yesVotes = 0;
        proposal.noVotes = 0;
        proposal.executed = false;
        nextProposalId++;
        emit GovernanceProposalCreated(nextProposalId - 1, _proposalDetails, msg.sender);
    }

    function voteOnGovernanceChange(uint _proposalId, bool _vote) external onlyMember validProposalId(_proposalId) governanceProposalActive(_proposalId) governanceProposalNotExecuted(_proposalId) {
        require(governanceProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal."); // Optional: Prohibit proposer voting
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceChange(uint _proposalId) external onlyOwner validProposalId(_proposalId) governanceProposalNotExecuted(_proposalId) {
        require(block.timestamp > governanceProposals[_proposalId].endTime, "Voting period not ended.");
        uint totalVotes = governanceProposals[_proposalId].yesVotes + governanceProposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast."); // Prevent division by zero
        uint yesPercentage = (governanceProposals[_proposalId].yesVotes * 100) / totalVotes; // Calculate percentage of yes votes

        if (yesPercentage > 50) { // Simple majority rule, can be configurable via governance itself
            // Example: If proposal is to change governance vote duration
            if (keccak256(abi.encodePacked(governanceProposals[_proposalId].proposalDetails)) == keccak256(abi.encodePacked("Change governance vote duration to 14 days"))) { // Very basic example, more robust parsing needed for real use
                governanceVoteDuration = 14 days;
            }
            // Add more conditions here based on proposal details to execute different changes

            governanceProposals[_proposalId].executed = true;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            revert("Governance proposal failed to pass.");
        }
    }


    // --- 2. Project Management ---

    function createProject(string _projectName, string _projectDescription, uint _targetBudget) external onlyMember {
        require(_targetBudget > 0, "Target budget must be greater than zero.");
        Project storage newProject = projects[nextProjectId];
        newProject.projectName = _projectName;
        newProject.projectDescription = _projectDescription;
        newProject.projectLead = msg.sender;
        newProject.stage = ProjectStage.PROPOSAL;
        newProject.targetBudget = _targetBudget;
        newProject.currentBudget = 0;
        newProject.startTime = block.timestamp;
        newProject.completed = false;
        newProject.nextFundRequestId = 0;
        nextProjectId++;
        emit ProjectCreated(nextProjectId - 1, _projectName, msg.sender);
    }

    function contributeToProject(uint _projectId) external payable validProjectId(_projectId) onlyMember {
        require(projects[_projectId].stage != ProjectStage.COMPLETED && projects[_projectId].stage != ProjectStage.ARCHIVED, "Project is not accepting contributions.");
        require(projects[_projectId].currentBudget + msg.value <= projects[_projectId].targetBudget, "Contribution exceeds target budget.");
        projects[_projectId].currentBudget += msg.value;
        treasuryBalance += msg.value; // Update treasury balance
        emit ProjectContribution(_projectId, msg.sender, msg.value);
    }

    function requestProjectFunds(uint _projectId, uint _amount, string _reason) external onlyMember validProjectId(_projectId) projectLeadOnly(_projectId) {
        require(_amount > 0, "Fund request amount must be greater than zero.");
        require(projects[_projectId].currentBudget >= _amount, "Project budget insufficient for this request.");
        FundRequest storage newRequest = projects[_projectId].fundRequests[projects[_projectId].nextFundRequestId];
        newRequest.amount = _amount;
        newRequest.reason = _reason;
        newRequest.requester = msg.sender;
        newRequest.approved = false;
        projects[_projectId].nextFundRequestId++;
        emit ProjectFundsRequested(_projectId, projects[_projectId].nextFundRequestId - 1, _amount, _reason, msg.sender);
    }

    function approveProjectFundsRequest(uint _projectId, uint _requestId) external onlyOwner validProjectId(_projectId) fundRequestExists(_projectId, _requestId) {
        require(!projects[_projectId].fundRequests[_requestId].approved, "Fund request already approved.");
        require(projects[_projectId].currentBudget >= projects[_projectId].fundRequests[_requestId].amount, "Insufficient project budget.");

        projects[_projectId].fundRequests[_requestId].approved = true;
        uint amountToTransfer = projects[_projectId].fundRequests[_requestId].amount;
        address recipient = projects[_projectId].fundRequests[_requestId].requester;

        // Update project budget and treasury balance
        projects[_projectId].currentBudget -= amountToTransfer;
        treasuryBalance -= amountToTransfer; // Update treasury balance

        (bool success, ) = recipient.call{value: amountToTransfer}(""); // Transfer funds to requester
        require(success, "Fund transfer failed.");

        emit ProjectFundsRequestApproved(_projectId, _requestId, msg.sender);
    }

    function markProjectStage(uint _projectId, ProjectStage _stage) external onlyMember validProjectId(_projectId) projectLeadOnly(_projectId) {
        projects[_projectId].stage = _stage;
        emit ProjectStageUpdated(_projectId, _stage);
    }

    function completeProject(uint _projectId) external onlyMember validProjectId(_projectId) projectLeadOnly(_projectId) {
        require(projects[_projectId].stage == ProjectStage.IN_PROGRESS, "Project must be in progress to be completed.");
        projects[_projectId].stage = ProjectStage.COMPLETED;
        projects[_projectId].completed = true;
        emit ProjectCompleted(_projectId);
    }

    function distributeProjectRewards(uint _projectId) external onlyOwner validProjectId(_projectId) {
        require(projects[_projectId].completed, "Project must be completed before rewards can be distributed.");
        // In a real scenario, reward distribution logic would be more complex,
        // potentially based on contribution, roles, governance, etc.
        // For this example, we'll just transfer remaining project budget to project lead.
        uint remainingBudget = projects[_projectId].currentBudget;
        projects[_projectId].currentBudget = 0; // Reset project budget after distribution

        if (remainingBudget > 0) {
            (bool success, ) = projects[_projectId].projectLead.call{value: remainingBudget}("");
            require(success, "Reward transfer failed.");
            treasuryBalance -= remainingBudget; // Update treasury balance
            emit ProjectRewardsDistributed(_projectId);
        }
        projects[_projectId].stage = ProjectStage.ARCHIVED; // Move to archived stage after distribution
    }


    // --- 3. Intellectual Property (IP) & Licensing ---

    function registerCreativeWork(string _workName, string _workDescription, string _ipfsHash) external onlyMember {
        require(bytes(_workName).length > 0 && bytes(_ipfsHash).length > 0, "Work name and IPFS hash are required.");
        CreativeWork storage newWork = creativeWorks[nextWorkId];
        newWork.workName = _workName;
        newWork.workDescription = _workDescription;
        newWork.ipfsHash = _ipfsHash;
        newWork.creator = msg.sender;
        newWork.registrationTime = block.timestamp;
        newWork.nextLicenseRequestId = 0;
        nextWorkId++;
        emit CreativeWorkRegistered(nextWorkId - 1, _workName, msg.sender, _ipfsHash);
    }

    function requestLicense(uint _workId, LicenseType _licenseType, address _licensee) external validWorkId(_workId) {
        require(_licensee != address(0), "Licensee address cannot be zero.");
        LicenseRequest storage newRequest = creativeWorks[_workId].licenseRequests[creativeWorks[_workId].nextLicenseRequestId];
        newRequest.licenseType = _licenseType;
        newRequest.licensee = _licensee;
        newRequest.approved = false;
        newRequest.requestTime = block.timestamp;
        creativeWorks[_workId].nextLicenseRequestId++;
        emit LicenseRequested(_workId, creativeWorks[_workId].nextLicenseRequestId - 1, _licenseType, _licensee);
    }

    function approveLicense(uint _workId, uint _licenseRequestId) external onlyOwner validWorkId(_workId) licenseRequestExists(_workId, _licenseRequestId) {
        require(!creativeWorks[_workId].licenseRequests[_licenseRequestId].approved, "License already approved.");
        creativeWorks[_workId].licenseRequests[_licenseRequestId].approved = true;
        emit LicenseApproved(_workId, _licenseRequestId, msg.sender);
    }

    function getLicenseDetails(uint _workId, uint _licenseRequestId) external view validWorkId(_workId) licenseRequestExists(_workId, _licenseRequestId) returns (LicenseRequest memory) {
        return creativeWorks[_workId].licenseRequests[_licenseRequestId];
    }


    // --- 4. Reputation & Skill System ---

    function endorseMemberSkill(address _member, string _skill) external onlyMember {
        require(isMember(_member), "Target address is not a member.");
        require(bytes(_skill).length > 0, "Skill cannot be empty.");
        members[_member].skills[_skill] = true;
        emit SkillEndorsed(_member, msg.sender, _skill);
    }

    function getMemberSkills(address _member) external view onlyMember returns (string[] memory) {
        require(isMember(_member), "Target address is not a member.");
        string[] memory skillList = new string[](0);
        uint skillCount = 0;
        for (uint i = 0; i < 100; i++) { // Limit to avoid unbounded loop - consider better iteration if scale is large
            if (skillCount >= 100) break; // Safety break
            string memory skillName = ""; // Placeholder, need a way to iterate mapping keys efficiently - Solidity limitations here
            // In a real app, consider storing skills in an array or using a more efficient data structure for iteration.
            // For this example, we'll skip proper iteration and just demonstrate the concept.

            // Example hardcoded skill names for demonstration (replace with dynamic approach in real implementation)
            if (i == 0 && members[_member].skills["Painting"]) skillName = "Painting";
            if (i == 1 && members[_member].skills["3D Modeling"]) skillName = "3D Modeling";
            if (i == 2 && members[_member].skills["Music Composition"]) skillName = "Music Composition";
            // ... add more example skills as needed

            if (bytes(skillName).length > 0) {
                skillList = _arrayPush(skillList, skillName);
                skillCount++;
            }
        }
        return skillList;
    }

    // Helper function to push to dynamic array (due to Solidity limitations)
    function _arrayPush(string[] memory _arr, string memory _value) private pure returns (string[] memory) {
        string[] memory newArr = new string[](_arr.length + 1);
        for (uint i = 0; i < _arr.length; i++) {
            newArr[i] = _arr[i];
        }
        newArr[_arr.length] = _value;
        return newArr;
    }


    // --- 5. Treasury & Financial Management ---

    function depositToTreasury() external payable {
        treasuryBalance += msg.value; // Update treasury balance
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(address _recipient, uint _amount) external onlyOwner {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");
        treasuryBalance -= _amount; // Update treasury balance

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed.");
        emit TreasuryWithdrawal(_recipient, _amount, msg.sender);
    }

    function getTreasuryBalance() public view returns (uint) {
        return treasuryBalance;
    }

    // --- Fallback and Receive functions for direct ETH transfers (optional for treasury) ---
    receive() external payable {
        treasuryBalance += msg.value; // Accept direct ETH deposits to treasury
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        treasuryBalance += msg.value; // Accept direct ETH deposits to treasury
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```