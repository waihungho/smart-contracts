```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Agency (DACA)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Creative Agency (DACA).
 *      This contract allows clients to commission creative projects, creatives to submit proposals and work,
 *      and a decentralized governance mechanism to manage agency rules and resolve disputes.
 *
 * **Outline:**
 *
 * **Agency Management:**
 *   1. `initializeAgency(string _agencyName, address[] _initialOwners, uint256 _proposalFee, uint256 _platformFee)`: Initializes the agency with name, owners, fees.
 *   2. `changeAgencyName(string _newName)`: Allows agency owners to change the agency name.
 *   3. `addAgencyOwner(address _newOwner)`: Allows agency owners to add new owners.
 *   4. `removeAgencyOwner(address _ownerToRemove)`: Allows agency owners to remove owners.
 *   5. `setProposalFee(uint256 _newFee)`: Allows agency owners to change the proposal fee.
 *   6. `setPlatformFee(uint256 _newFee)`: Allows agency owners to change the platform fee.
 *   7. `withdrawPlatformFees()`: Allows agency owners to withdraw accumulated platform fees.
 *   8. `pauseAgency()`: Allows agency owners to pause core agency functionalities.
 *   9. `unpauseAgency()`: Allows agency owners to unpause core agency functionalities.
 *   10. `defineAgencyRule(string _ruleName, string _ruleDescription, bytes32 _ruleHash)`: Agency owners can define new agency rules and store their hashes.
 *   11. `updateAgencyRule(bytes32 _ruleHash, string _newRuleDescription, bytes32 _newRuleHash)`: Agency owners can update existing agency rules.
 *
 * **Client Management:**
 *   12. `createProject(string _projectName, string _projectBrief, uint256 _budget, uint256 _deadline)`: Clients create a new creative project.
 *   13. `cancelProject(uint256 _projectId)`: Clients can cancel their projects before a creative is selected.
 *   14. `approveCreativeProposal(uint256 _projectId, uint256 _proposalId)`: Clients approve a creative proposal and start the project.
 *   15. `requestRevision(uint256 _projectId, string _revisionRequest)`: Clients can request revisions from the creative.
 *   16. `markProjectComplete(uint256 _projectId)`: Clients mark a project as complete after satisfaction.
 *
 * **Creative Management:**
 *   17. `registerCreativeProfile(string _creativeName, string _portfolioLink, string _skills)`: Creatives register their profile with the agency.
 *   18. `submitCreativeProposal(uint256 _projectId, string _proposalDescription, uint256 _feeEstimate, bytes32 _contentHash)`: Creatives submit proposals for projects, paying a proposal fee.
 *   19. `submitWork(uint256 _projectId, bytes32 _workHash)`: Creatives submit their work for a project.
 *   20. `acceptRevisionRequest(uint256 _projectId)`: Creatives acknowledge and accept a revision request.
 *   21. `disputeProject(uint256 _projectId, string _disputeReason)`: Creatives can initiate a dispute for a project if needed.
 *
 * **Governance & Dispute Resolution (Basic - can be extended with DAO principles):**
 *   22. `resolveDispute(uint256 _projectId, address _winner)`: Agency owners can resolve disputes (basic resolution - could be expanded to voting).
 *
 * **Utility/View Functions:**
 *   23. `getAgencyName()`: Returns the agency name.
 *   24. `getAgencyOwners()`: Returns the list of agency owners.
 *   25. `getProposalFee()`: Returns the current proposal fee.
 *   26. `getPlatformFee()`: Returns the current platform fee.
 *   27. `getProjectDetails(uint256 _projectId)`: Returns details of a specific project.
 *   28. `getCreativeProfile(address _creativeAddress)`: Returns the profile of a registered creative.
 *   29. `getProposalDetails(uint256 _projectId, uint256 _proposalId)`: Returns details of a specific proposal.
 *   30. `getAgencyRuleDescription(bytes32 _ruleHash)`: Retrieves the description of an agency rule by its hash.
 */
contract DecentralizedAutonomousCreativeAgency {
    string public agencyName;
    address[] public agencyOwners;
    uint256 public proposalFee; // Fee for creatives to submit proposals
    uint256 public platformFee; // Percentage fee on project budgets for the platform
    bool public paused;

    uint256 public projectCounter;
    uint256 public proposalCounter;
    mapping(uint256 => Project) public projects;
    mapping(address => CreativeProfile) public creativeProfiles;
    mapping(bytes32 => AgencyRule) public agencyRules;
    mapping(uint256 => mapping(uint256 => CreativeProposal)) public proposals; // projectId => proposalId => Proposal

    uint256 public platformFeesBalance;

    enum ProjectStatus { Open, ProposalSubmitted, CreativeSelected, WorkInProgress, RevisionRequested, Completed, Cancelled, Disputed }
    enum ProposalStatus { Submitted, Approved, Rejected }

    struct AgencyRule {
        string description;
        bytes32 ruleHash;
    }

    struct Project {
        uint256 projectId;
        string projectName;
        string projectBrief;
        address client;
        uint256 budget;
        uint256 deadline; // Timestamp
        ProjectStatus status;
        uint256 selectedProposalId;
        address selectedCreative;
        bytes32 submittedWorkHash;
        string revisionRequest;
        string disputeReason;
        uint256 creationTimestamp;
    }

    struct CreativeProfile {
        string creativeName;
        string portfolioLink;
        string skills;
        bool registered;
        uint256 registrationTimestamp;
    }

    struct CreativeProposal {
        uint256 proposalId;
        uint256 projectId;
        address creative;
        string proposalDescription;
        uint256 feeEstimate;
        ProposalStatus status;
        bytes32 contentHash; // Hash of the proposal content (e.g., PDF, document)
        uint256 submissionTimestamp;
    }

    event AgencyInitialized(string agencyName, address[] owners, uint256 _proposalFee, uint256 _platformFee);
    event AgencyNameChanged(string newName);
    event AgencyOwnerAdded(address newOwner);
    event AgencyOwnerRemoved(address removedOwner);
    event ProposalFeeChanged(uint256 newFee);
    event PlatformFeeChanged(uint256 newFee);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event AgencyPaused();
    event AgencyUnpaused();
    event AgencyRuleDefined(string ruleName, bytes32 ruleHash);
    event AgencyRuleUpdated(bytes32 ruleHash, string newDescription, bytes32 newRuleHash);

    event ProjectCreated(uint256 projectId, address client, string projectName);
    event ProjectCancelled(uint256 projectId);
    event CreativeProposalSubmitted(uint256 projectId, uint256 proposalId, address creative);
    event CreativeProposalApproved(uint256 projectId, uint256 proposalId, address creative);
    event RevisionRequested(uint256 projectId, string revisionRequest, address client);
    event RevisionRequestAccepted(uint256 projectId, address creative);
    event WorkSubmitted(uint256 projectId, bytes32 workHash, address creative);
    event ProjectCompleted(uint256 projectId, address client);
    event ProjectDisputed(uint256 projectId, string disputeReason, address disputer);
    event DisputeResolved(uint256 projectId, address winner, address resolver);

    event CreativeProfileRegistered(address creative, string creativeName);

    modifier onlyAgencyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < agencyOwners.length; i++) {
            if (agencyOwners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Only agency owners can perform this action.");
        _;
    }

    modifier onlyClient(uint256 _projectId) {
        require(projects[_projectId].client == msg.sender, "Only the client of this project can perform this action.");
        _;
    }

    modifier onlyCreative(uint256 _projectId) {
        require(projects[_projectId].selectedCreative == msg.sender, "Only the selected creative for this project can perform this action.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(projects[_projectId].projectId != 0, "Project does not exist.");
        _;
    }

    modifier proposalExists(uint256 _projectId, uint256 _proposalId) {
        require(proposals[_projectId][_proposalId].proposalId != 0, "Proposal does not exist.");
        _;
    }

    modifier projectStatusIs(uint256 _projectId, ProjectStatus _status) {
        require(projects[_projectId].status == _status, "Project status is not the required status.");
        _;
    }

    modifier agencyNotPaused() {
        require(!paused, "Agency is currently paused.");
        _;
    }

    constructor() {
        // Contract is deployed, ready to be initialized.
    }

    /// -------------------- Agency Management Functions --------------------

    /**
     * @dev Initializes the agency with a name, initial owners, proposal fee, and platform fee.
     * @param _agencyName The name of the agency.
     * @param _initialOwners An array of initial agency owner addresses.
     * @param _proposalFee The fee in wei for creatives to submit proposals.
     * @param _platformFee The percentage fee (e.g., 5 for 5%) taken from project budgets.
     */
    function initializeAgency(string memory _agencyName, address[] memory _initialOwners, uint256 _proposalFee, uint256 _platformFee) public {
        require(agencyOwners.length == 0, "Agency already initialized.");
        require(_initialOwners.length > 0, "At least one initial owner is required.");
        agencyName = _agencyName;
        agencyOwners = _initialOwners;
        proposalFee = _proposalFee;
        platformFee = _platformFee;
        emit AgencyInitialized(_agencyName, _initialOwners, _proposalFee, _platformFee);
    }

    /**
     * @dev Allows agency owners to change the agency name.
     * @param _newName The new name for the agency.
     */
    function changeAgencyName(string memory _newName) public onlyAgencyOwner {
        agencyName = _newName;
        emit AgencyNameChanged(_newName);
    }

    /**
     * @dev Allows agency owners to add a new agency owner.
     * @param _newOwner The address of the new agency owner.
     */
    function addAgencyOwner(address _newOwner) public onlyAgencyOwner {
        for (uint256 i = 0; i < agencyOwners.length; i++) {
            if (agencyOwners[i] == _newOwner) {
                revert("Address is already an owner.");
            }
        }
        agencyOwners.push(_newOwner);
        emit AgencyOwnerAdded(_newOwner);
    }

    /**
     * @dev Allows agency owners to remove an existing agency owner.
     * @param _ownerToRemove The address of the agency owner to remove.
     */
    function removeAgencyOwner(address _ownerToRemove) public onlyAgencyOwner {
        require(agencyOwners.length > 1, "At least one owner must remain.");
        bool removed = false;
        for (uint256 i = 0; i < agencyOwners.length; i++) {
            if (agencyOwners[i] == _ownerToRemove) {
                delete agencyOwners[i];
                removed = true;
                // Shift elements to remove the gap
                for (uint256 j = i; j < agencyOwners.length - 1; j++) {
                    agencyOwners[j] = agencyOwners[j + 1];
                }
                agencyOwners.pop(); // Remove the last element (which is now a duplicate or zero address)
                emit AgencyOwnerRemoved(_ownerToRemove);
                break;
            }
        }
        require(removed, "Owner address not found.");
    }

    /**
     * @dev Allows agency owners to set a new proposal fee.
     * @param _newFee The new proposal fee in wei.
     */
    function setProposalFee(uint256 _newFee) public onlyAgencyOwner {
        proposalFee = _newFee;
        emit ProposalFeeChanged(_newFee);
    }

    /**
     * @dev Allows agency owners to set a new platform fee percentage.
     * @param _newFee The new platform fee percentage (e.g., 5 for 5%).
     */
    function setPlatformFee(uint256 _newFee) public onlyAgencyOwner {
        platformFee = _newFee;
        emit PlatformFeeChanged(_newFee);
    }

    /**
     * @dev Allows agency owners to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyAgencyOwner {
        uint256 amountToWithdraw = platformFeesBalance;
        platformFeesBalance = 0;
        payable(agencyOwners[0]).transfer(amountToWithdraw); // Transfer to the first owner for simplicity - can be adjusted
        emit PlatformFeesWithdrawn(amountToWithdraw, agencyOwners[0]);
    }

    /**
     * @dev Pauses core agency functionalities (e.g., project creation, proposal submissions).
     */
    function pauseAgency() public onlyAgencyOwner {
        paused = true;
        emit AgencyPaused();
    }

    /**
     * @dev Unpauses core agency functionalities.
     */
    function unpauseAgency() public onlyAgencyOwner {
        paused = false;
        emit AgencyUnpaused();
    }

    /**
     * @dev Defines a new agency rule by storing its hash and description.
     * @param _ruleName A descriptive name for the rule.
     * @param _ruleDescription A human-readable description of the rule.
     * @param _ruleHash The keccak256 hash of the full rule document/content.
     */
    function defineAgencyRule(string memory _ruleName, string memory _ruleDescription, bytes32 _ruleHash) public onlyAgencyOwner {
        agencyRules[_ruleHash] = AgencyRule({
            description: _ruleDescription,
            ruleHash: _ruleHash
        });
        emit AgencyRuleDefined(_ruleName, _ruleHash);
    }

    /**
     * @dev Updates the description of an existing agency rule.
     * @param _ruleHash The hash of the rule to update.
     * @param _newRuleDescription The new human-readable description of the rule.
     * @param _newRuleHash The new hash if the rule content itself is updated.
     */
    function updateAgencyRule(bytes32 _ruleHash, string memory _newRuleDescription, bytes32 _newRuleHash) public onlyAgencyOwner {
        require(agencyRules[_ruleHash].ruleHash == _ruleHash, "Rule not found.");
        agencyRules[_newRuleHash] = AgencyRule({
            description: _newRuleDescription,
            ruleHash: _newRuleHash
        });
        delete agencyRules[_ruleHash]; // Remove old rule entry
        emit AgencyRuleUpdated(_ruleHash, _newRuleDescription, _newRuleHash);
    }


    /// -------------------- Client Management Functions --------------------

    /**
     * @dev Allows clients to create a new creative project.
     * @param _projectName The name of the project.
     * @param _projectBrief A brief description of the project requirements.
     * @param _budget The budget allocated for the project in wei.
     * @param _deadline A Unix timestamp representing the project deadline.
     */
    function createProject(string memory _projectName, string memory _projectBrief, uint256 _budget, uint256 _deadline) public agencyNotPaused {
        projectCounter++;
        projects[projectCounter] = Project({
            projectId: projectCounter,
            projectName: _projectName,
            projectBrief: _projectBrief,
            client: msg.sender,
            budget: _budget,
            deadline: _deadline,
            status: ProjectStatus.Open,
            selectedProposalId: 0,
            selectedCreative: address(0),
            submittedWorkHash: bytes32(0),
            revisionRequest: "",
            disputeReason: "",
            creationTimestamp: block.timestamp
        });
        emit ProjectCreated(projectCounter, msg.sender, _projectName);
    }

    /**
     * @dev Allows clients to cancel their project if no creative has been selected yet.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) public onlyClient(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.Open) {
        projects[_projectId].status = ProjectStatus.Cancelled;
        emit ProjectCancelled(_projectId);
    }

    /**
     * @dev Allows clients to approve a creative proposal and select a creative for the project.
     * @param _projectId The ID of the project.
     * @param _proposalId The ID of the creative proposal to approve.
     */
    function approveCreativeProposal(uint256 _projectId, uint256 _proposalId) public onlyClient(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.ProposalSubmitted) proposalExists(_projectId, _proposalId) {
        require(proposals[_projectId][_proposalId].projectId == _projectId, "Proposal is not for this project.");
        require(proposals[_projectId][_proposalId].status == ProposalStatus.Submitted, "Proposal status is not Submitted.");

        projects[_projectId].status = ProjectStatus.CreativeSelected;
        projects[_projectId].selectedProposalId = _proposalId;
        projects[_projectId].selectedCreative = proposals[_projectId][_proposalId].creative;
        proposals[_projectId][_proposalId].status = ProposalStatus.Approved;

        // Reject other submitted proposals for this project (optional - depends on desired workflow)
        for (uint256 i = 1; i <= proposalCounter; i++) { // Iterate through all proposals - could be optimized for project-specific proposals later
            if (proposals[_projectId][i].projectId == _projectId && proposals[_projectId][i].proposalId != _proposalId && proposals[_projectId][i].status == ProposalStatus.Submitted) {
                proposals[_projectId][i].status = ProposalStatus.Rejected;
            }
        }

        emit CreativeProposalApproved(_projectId, _proposalId, proposals[_projectId][_proposalId].creative);
    }

    /**
     * @dev Allows clients to request a revision from the selected creative.
     * @param _projectId The ID of the project.
     * @param _revisionRequest A description of the revision requested.
     */
    function requestRevision(uint256 _projectId, string memory _revisionRequest) public onlyClient(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.WorkInProgress) {
        projects[_projectId].status = ProjectStatus.RevisionRequested;
        projects[_projectId].revisionRequest = _revisionRequest;
        emit RevisionRequested(_projectId, _revisionRequest, msg.sender);
    }

    /**
     * @dev Allows clients to mark a project as complete after being satisfied with the work.
     *      This would typically trigger payment release (implementation not included in this example for simplicity).
     * @param _projectId The ID of the project to mark as complete.
     */
    function markProjectComplete(uint256 _projectId) public onlyClient(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.WorkInProgress) { // Could also allow completion after revision
        projects[_projectId].status = ProjectStatus.Completed;

        // Transfer platform fee to platformFeesBalance
        uint256 platformFeeAmount = (projects[_projectId].budget * platformFee) / 100;
        platformFeesBalance += platformFeeAmount;

        // Transfer remaining budget to creative (Implementation of escrow/payment release would go here)
        uint256 creativePayout = projects[_projectId].budget - platformFeeAmount;
        payable(projects[_projectId].selectedCreative).transfer(creativePayout); // Basic transfer - Escrow and more complex payment logic needed in real application.

        emit ProjectCompleted(_projectId, msg.sender);
    }


    /// -------------------- Creative Management Functions --------------------

    /**
     * @dev Allows creatives to register their profile with the agency.
     * @param _creativeName The name of the creative.
     * @param _portfolioLink A link to the creative's online portfolio.
     * @param _skills A description of the creative's skills and expertise.
     */
    function registerCreativeProfile(string memory _creativeName, string memory _portfolioLink, string memory _skills) public agencyNotPaused {
        require(!creativeProfiles[msg.sender].registered, "Creative profile already registered.");
        creativeProfiles[msg.sender] = CreativeProfile({
            creativeName: _creativeName,
            portfolioLink: _portfolioLink,
            skills: _skills,
            registered: true,
            registrationTimestamp: block.timestamp
        });
        emit CreativeProfileRegistered(msg.sender, _creativeName);
    }

    /**
     * @dev Allows registered creatives to submit a proposal for an open project.
     * @param _projectId The ID of the project to submit a proposal for.
     * @param _proposalDescription A description of the creative's approach and proposal.
     * @param _feeEstimate The estimated fee for the project in wei.
     * @param _contentHash Hash of the proposal document/content.
     */
    function submitCreativeProposal(uint256 _projectId, string memory _proposalDescription, uint256 _feeEstimate, bytes32 _contentHash) public payable agencyNotPaused projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.Open) {
        require(creativeProfiles[msg.sender].registered, "Creative profile must be registered to submit proposals.");
        require(msg.value >= proposalFee, "Insufficient proposal fee.");

        proposalCounter++;
        proposals[_projectId][proposalCounter] = CreativeProposal({
            proposalId: proposalCounter,
            projectId: _projectId,
            creative: msg.sender,
            proposalDescription: _proposalDescription,
            feeEstimate: _feeEstimate,
            status: ProposalStatus.Submitted,
            contentHash: _contentHash,
            submissionTimestamp: block.timestamp
        });
        projects[_projectId].status = ProjectStatus.ProposalSubmitted; // Move project status to ProposalSubmitted
        emit CreativeProposalSubmitted(_projectId, proposalCounter, msg.sender);

        // Refund excess fee if paid more than proposalFee
        if (msg.value > proposalFee) {
            uint256 refundAmount = msg.value - proposalFee;
            payable(msg.sender).transfer(refundAmount);
        }
    }

    /**
     * @dev Allows the selected creative to submit their work for a project.
     * @param _projectId The ID of the project.
     * @param _workHash The hash of the submitted work (e.g., IPFS hash, file hash).
     */
    function submitWork(uint256 _projectId, bytes32 _workHash) public onlyCreative(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.CreativeSelected) {
        projects[_projectId].status = ProjectStatus.WorkInProgress;
        projects[_projectId].submittedWorkHash = _workHash;
        emit WorkSubmitted(_projectId, _workHash, msg.sender);
    }

    /**
     * @dev Allows creatives to accept a revision request from the client.
     * @param _projectId The ID of the project.
     */
    function acceptRevisionRequest(uint256 _projectId) public onlyCreative(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.RevisionRequested) {
        projects[_projectId].status = ProjectStatus.WorkInProgress; // Back to work in progress after accepting revision
        projects[_projectId].revisionRequest = ""; // Clear revision request
        emit RevisionRequestAccepted(_projectId, msg.sender);
    }

    /**
     * @dev Allows creatives to initiate a dispute for a project if there are issues (e.g., payment, scope creep).
     * @param _projectId The ID of the project.
     * @param _disputeReason A description of the reason for the dispute.
     */
    function disputeProject(uint256 _projectId, string memory _disputeReason) public onlyCreative(_projectId) projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.WorkInProgress) { // Disputes can be initiated during work in progress for now
        projects[_projectId].status = ProjectStatus.Disputed;
        projects[_projectId].disputeReason = _disputeReason;
        emit ProjectDisputed(_projectId, _disputeReason, msg.sender);
    }


    /// -------------------- Governance & Dispute Resolution Functions --------------------

    /**
     * @dev Allows agency owners to resolve a project dispute by selecting a winner (client or creative).
     *      This is a basic dispute resolution - a more advanced system could involve voting or mediation.
     * @param _projectId The ID of the disputed project.
     * @param _winner The address of the winner of the dispute (client or creative).
     */
    function resolveDispute(uint256 _projectId, address _winner) public onlyAgencyOwner projectExists(_projectId) projectStatusIs(_projectId, ProjectStatus.Disputed) {
        require(_winner == projects[_projectId].client || _winner == projects[_projectId].selectedCreative, "Winner must be either client or creative of this project.");

        if (_winner == projects[_projectId].client) {
            projects[_projectId].status = ProjectStatus.Cancelled; // Client wins - project cancelled (funds returned to client - not implemented here)
            // Refund logic would be needed here if funds were held in escrow.
        } else if (_winner == projects[_projectId].selectedCreative) {
            projects[_projectId].status = ProjectStatus.Completed; // Creative wins - project completed, payment released.
            // Payment release logic (similar to markProjectComplete) would be needed here.

            // Transfer platform fee to platformFeesBalance
            uint256 platformFeeAmount = (projects[_projectId].budget * platformFee) / 100;
            platformFeesBalance += platformFeeAmount;

            // Transfer remaining budget to creative
            uint256 creativePayout = projects[_projectId].budget - platformFeeAmount;
            payable(projects[_projectId].selectedCreative).transfer(creativePayout);
        }

        emit DisputeResolved(_projectId, _winner, msg.sender);
    }


    /// -------------------- Utility/View Functions --------------------

    /**
     * @dev Returns the name of the agency.
     * @return The agency name string.
     */
    function getAgencyName() public view returns (string memory) {
        return agencyName;
    }

    /**
     * @dev Returns the list of agency owner addresses.
     * @return An array of agency owner addresses.
     */
    function getAgencyOwners() public view returns (address[] memory) {
        return agencyOwners;
    }

    /**
     * @dev Returns the current proposal fee.
     * @return The proposal fee in wei.
     */
    function getProposalFee() public view returns (uint256) {
        return proposalFee;
    }

    /**
     * @dev Returns the current platform fee percentage.
     * @return The platform fee percentage.
     */
    function getPlatformFee() public view returns (uint256) {
        return platformFee;
    }

    /**
     * @dev Returns details of a specific project.
     * @param _projectId The ID of the project.
     * @return A Project struct containing project details.
     */
    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    /**
     * @dev Returns the profile of a registered creative.
     * @param _creativeAddress The address of the creative.
     * @return A CreativeProfile struct containing creative profile details.
     */
    function getCreativeProfile(address _creativeAddress) public view returns (CreativeProfile memory) {
        return creativeProfiles[_creativeAddress];
    }

    /**
     * @dev Returns details of a specific proposal.
     * @param _projectId The ID of the project.
     * @param _proposalId The ID of the proposal.
     * @return A CreativeProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _projectId, uint256 _proposalId) public view proposalExists(_projectId, _proposalId) returns (CreativeProposal memory) {
        return proposals[_projectId][_proposalId];
    }

    /**
     * @dev Retrieves the description of an agency rule by its hash.
     * @param _ruleHash The hash of the agency rule.
     * @return The description of the agency rule.
     */
    function getAgencyRuleDescription(bytes32 _ruleHash) public view returns (string memory) {
        return agencyRules[_ruleHash].description;
    }
}
```