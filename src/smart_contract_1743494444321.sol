```solidity
/**
 * @title Decentralized Autonomous Creative Agency (DACA) - Smart Contract
 * @author Bard (Example Smart Contract - Educational Purposes Only)
 * @notice This contract outlines a Decentralized Autonomous Creative Agency (DACA)
 *         on the blockchain. It facilitates the connection between clients needing
 *         creative services and creators, governed by a DAO mechanism.
 *
 * Function Summary:
 * -----------------
 *
 * **Agency Management & Governance:**
 * 1.  `setAgencyName(string _name)`: Sets the name of the DACA. (Governance)
 * 2.  `setAgencyFee(uint256 _feePercentage)`: Sets the agency fee percentage. (Governance)
 * 3.  `addCategory(string _categoryName)`: Adds a new creative category (e.g., 'Logo Design', 'Web Development'). (Governance)
 * 4.  `removeCategory(uint256 _categoryId)`: Removes a creative category. (Governance)
 * 5.  `submitGovernanceProposal(string _title, string _description, bytes _calldata)`: Allows members to submit governance proposals. (Governance)
 * 6.  `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on governance proposals. (Governance)
 * 7.  `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal. (Governance)
 * 8.  `addGovernor(address _governor)`: Adds a new governor to the DACA. (Governance)
 * 9.  `removeGovernor(address _governor)`: Removes a governor from the DACA. (Governance)
 *
 * **Client & Project Management:**
 * 10. `createProjectRequest(string _title, string _description, uint256 _budget, uint256 _categoryId, string[] _requiredSkills)`: Clients create project requests.
 * 11. `depositProjectBudget(uint256 _projectId)`: Clients deposit funds for a project.
 * 12. `selectCreatorForProject(uint256 _projectId, address _creatorAddress)`: Clients select a creator for their project.
 * 13. `approveMilestone(uint256 _projectId, uint256 _milestoneId)`: Clients approve a milestone completion.
 * 14. `finalizeProject(uint256 _projectId)`: Clients finalize a project after all milestones are approved.
 * 15. `cancelProject(uint256 _projectId)`: Clients can cancel a project under certain conditions.
 * 16. `submitFeedback(uint256 _projectId, string _feedback)`: Clients submit feedback for a completed project and creator.
 *
 * **Creator & Portfolio Management:**
 * 17. `registerCreatorProfile(string _name, string _portfolioLink, string[] _skills, uint256[] _categoryIds)`: Creators register their profiles.
 * 18. `updateCreatorProfile(string _name, string _portfolioLink, string[] _skills, uint256[] _categoryIds)`: Creators update their profiles.
 * 19. `bidOnProject(uint256 _projectId, string _bidDetails)`: Creators bid on open projects.
 * 20. `submitMilestoneWork(uint256 _projectId, uint256 _milestoneId, string _workSubmissionLink)`: Creators submit work for a project milestone.
 * 21. `requestMilestonePayment(uint256 _projectId, uint256 _milestoneId)`: Creators request payment for a completed milestone.
 * 22. `withdrawEarnings()`: Creators withdraw their earned funds from the agency.
 *
 * **Utility & Information Retrieval:**
 * 23. `getProjectDetails(uint256 _projectId)`: Retrieves detailed information about a specific project.
 * 24. `getCreatorProfileDetails(address _creatorAddress)`: Retrieves details of a creator's profile.
 * 25. `getCategoryName(uint256 _categoryId)`: Retrieves the name of a category.
 * 26. `getAgencyBalance()`: Retrieves the current balance of the DACA smart contract.
 * 27. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedCreativeAgency is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Agency-Level Variables
    string public agencyName = "Decentralized Creative Agency";
    uint256 public agencyFeePercentage = 5; // Percentage of project budget taken as agency fee
    address[] public governors; // Addresses authorized to govern the agency

    // Category Management
    Counters.Counter private _categoryCounter;
    mapping(uint256 => string) public categories;
    mapping(string => uint256) public categoryNameToId;

    // Creator Profiles
    struct CreatorProfile {
        string name;
        string portfolioLink;
        string[] skills;
        uint256[] categoryIds;
        address creatorAddress;
        uint256 reputationScore; // Example: Could be based on client feedback (simplified)
        bool isActive;
    }
    mapping(address => CreatorProfile) public creatorProfiles;
    address[] public registeredCreators;

    // Project Management
    struct Project {
        uint256 projectId;
        address clientAddress;
        string title;
        string description;
        uint256 budget;
        uint256 categoryId;
        string[] requiredSkills;
        address creatorAddress; // Assigned creator for the project
        Status projectStatus;
        Milestone[] milestones;
        uint256 fundsDeposited;
        uint256 fundsReleased;
        string feedback;
    }

    enum Status { Open, CreatorSelected, InProgress, MilestonePendingApproval, Completed, Cancelled, Dispute }
    struct Milestone {
        uint256 milestoneId;
        string description;
        uint256 percentageOfBudget; // Percentage of total budget for this milestone
        Status milestoneStatus; // Pending, Submitted, Approved, Rejected
        string workSubmissionLink;
    }

    Counters.Counter private _projectCounter;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => address[]) public projectBids; // Project ID to array of bidder addresses

    // Governance Proposals
    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        bytes calldata; // Function call data to execute if proposal passes
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
    }
    Counters.Counter private _proposalCounter;
    mapping(uint256 => GovernanceProposal) public proposals;

    // Events
    event AgencyNameUpdated(string newName);
    event AgencyFeeUpdated(uint256 newFeePercentage);
    event CategoryAdded(uint256 categoryId, string categoryName);
    event CategoryRemoved(uint256 categoryId);
    event CreatorRegistered(address creatorAddress, string name);
    event CreatorProfileUpdated(address creatorAddress);
    event ProjectCreated(uint256 projectId, address clientAddress, string title);
    event ProjectBudgetDeposited(uint256 projectId, uint256 amount);
    event CreatorSelected(uint256 projectId, address creatorAddress);
    event MilestoneSubmitted(uint256 projectId, uint256 milestoneId);
    event MilestoneApproved(uint256 projectId, uint256 milestoneId);
    event ProjectFinalized(uint256 projectId);
    event ProjectCancelled(uint256 projectId);
    event FeedbackSubmitted(uint256 projectId, string feedback);
    event BidSubmitted(uint256 projectId, address creatorAddress);
    event GovernanceProposalSubmitted(uint256 proposalId, string title);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernorAdded(address governorAddress);
    event GovernorRemoved(address governorAddress);
    event EarningsWithdrawn(address creatorAddress, uint256 amount);

    // Modifiers
    modifier onlyGovernor() {
        bool isGovernor = false;
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _msgSender()) {
                isGovernor = true;
                break;
            }
        }
        require(isGovernor || _msgSender() == owner(), "Caller is not a governor or owner");
        _;
    }

    modifier onlyClient(uint256 _projectId) {
        require(projects[_projectId].clientAddress == _msgSender(), "Caller is not the client for this project");
        _;
    }

    modifier onlyCreator(uint256 _projectId) {
        require(projects[_projectId].creatorAddress == _msgSender(), "Caller is not the assigned creator for this project");
        _;
    }

    modifier validProject(uint256 _projectId) {
        require(projects[_projectId].projectId != 0, "Invalid project ID");
        _;
    }

    modifier validCategory(uint256 _categoryId) {
        require(bytes(categories[_categoryId]).length > 0, "Invalid category ID");
        _;
    }

    modifier validMilestone(uint256 _projectId, uint256 _milestoneId) {
        require(_milestoneId < projects[_projectId].milestones.length, "Invalid milestone ID");
        _;
    }

    modifier projectInStatus(uint256 _projectId, Status _status) {
        require(projects[_projectId].projectStatus == _status, "Project is not in the required status");
        _;
    }


    constructor() payable {
        governors.push(_msgSender()); // Initial governor is contract deployer
    }

    // ------------------------------------------------------------------------
    // Agency Management & Governance Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Sets the name of the Decentralized Creative Agency.
     * @param _name The new name for the agency.
     */
    function setAgencyName(string memory _name) external onlyGovernor {
        agencyName = _name;
        emit AgencyNameUpdated(_name);
    }

    /**
     * @dev Sets the percentage fee the agency takes from project budgets.
     * @param _feePercentage The new agency fee percentage (0-100).
     */
    function setAgencyFee(uint256 _feePercentage) external onlyGovernor {
        require(_feePercentage <= 100, "Agency fee percentage must be between 0 and 100");
        agencyFeePercentage = _feePercentage;
        emit AgencyFeeUpdated(_feePercentage);
    }

    /**
     * @dev Adds a new category to the agency's service offerings.
     * @param _categoryName The name of the new category.
     */
    function addCategory(string memory _categoryName) external onlyGovernor {
        require(categoryNameToId[_categoryName] == 0, "Category already exists");
        _categoryCounter.increment();
        uint256 categoryId = _categoryCounter.current();
        categories[categoryId] = _categoryName;
        categoryNameToId[_categoryName] = categoryId;
        emit CategoryAdded(categoryId, _categoryName);
    }

    /**
     * @dev Removes a category from the agency's service offerings.
     * @param _categoryId The ID of the category to remove.
     */
    function removeCategory(uint256 _categoryId) external onlyGovernor validCategory(_categoryId) {
        string memory categoryName = categories[_categoryId];
        delete categories[_categoryId];
        delete categoryNameToId[categoryName];
        emit CategoryRemoved(_categoryId);
    }

    /**
     * @dev Submits a governance proposal for voting.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _calldata The encoded function call to execute if the proposal passes.
     */
    function submitGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) external onlyGovernor {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();
        proposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            title: _title,
            description: _description,
            calldata: _calldata,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // Example: 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        emit GovernanceProposalSubmitted(proposalId, _title);
    }

    /**
     * @dev Allows governors to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernor {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.votingEndTime > block.timestamp, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a governance proposal if it has passed the voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyGovernor {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.votingEndTime <= block.timestamp, "Voting period is still ongoing");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) { // Simple majority for passing (can be adjusted)
            proposal.passed = true;
            (bool success, ) = address(this).call(proposal.calldata);
            require(success, "Governance proposal execution failed");
            proposal.executed = true;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.executed = true; // Mark as executed even if failed to prevent re-execution
        }
    }

    /**
     * @dev Adds a new address to the list of governors.
     * @param _governor The address to add as a governor.
     */
    function addGovernor(address _governor) external onlyGovernor {
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                revert("Governor already exists");
            }
        }
        governors.push(_governor);
        emit GovernorAdded(_governor);
    }

    /**
     * @dev Removes an address from the list of governors.
     * @param _governor The address to remove from governors.
     */
    function removeGovernor(address _governor) external onlyGovernor {
        require(_governor != owner(), "Cannot remove contract owner from governors using this function");
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                delete governors[i];
                // Compact the array (optional, for gas optimization in very large governor lists, otherwise could just set to address(0))
                address[] memory tempGovernors = new address[](governors.length - 1);
                uint256 tempIndex = 0;
                for(uint256 j=0; j<governors.length; j++){
                    if(governors[j] != address(0) && governors[j] != _governor){
                        tempGovernors[tempIndex] = governors[j];
                        tempIndex++;
                    }
                }
                governors = tempGovernors;

                emit GovernorRemoved(_governor);
                return;
            }
        }
        revert("Governor not found");
    }


    // ------------------------------------------------------------------------
    // Client & Project Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Clients create a new project request.
     * @param _title The title of the project.
     * @param _description A detailed description of the project requirements.
     * @param _budget The total budget allocated for the project in wei.
     * @param _categoryId The ID of the category the project belongs to.
     * @param _requiredSkills An array of skills required for the project.
     */
    function createProjectRequest(
        string memory _title,
        string memory _description,
        uint256 _budget,
        uint256 _categoryId,
        string[] memory _requiredSkills
    ) external validCategory(_categoryId) {
        _projectCounter.increment();
        uint256 projectId = _projectCounter.current();
        projects[projectId] = Project({
            projectId: projectId,
            clientAddress: _msgSender(),
            title: _title,
            description: _description,
            budget: _budget,
            categoryId: _categoryId,
            requiredSkills: _requiredSkills,
            creatorAddress: address(0), // Initially no creator assigned
            projectStatus: Status.Open,
            milestones: new Milestone[](0), // Initially no milestones defined
            fundsDeposited: 0,
            fundsReleased: 0,
            feedback: ""
        });
        emit ProjectCreated(projectId, _msgSender(), _title);
    }

    /**
     * @dev Clients deposit the budget for a project into the contract.
     * @param _projectId The ID of the project to deposit funds for.
     */
    function depositProjectBudget(uint256 _projectId) external payable validProject(_projectId) onlyClient(_projectId) projectInStatus(_projectId, Status.Open) {
        Project storage project = projects[_projectId];
        require(msg.value == project.budget, "Deposited amount must equal project budget");
        project.fundsDeposited = msg.value;
        emit ProjectBudgetDeposited(_projectId, msg.value);
    }

    /**
     * @dev Clients select a creator from the bidders for their project.
     * @param _projectId The ID of the project.
     * @param _creatorAddress The address of the creator selected for the project.
     */
    function selectCreatorForProject(uint256 _projectId, address _creatorAddress) external validProject(_projectId) onlyClient(_projectId) projectInStatus(_projectId, Status.Open) {
        require(projectBids[_projectId].length > 0, "No bids received for this project yet."); // Or check if _creatorAddress bid
        bool creatorBid = false;
        for(uint256 i=0; i<projectBids[_projectId].length; i++){
            if(projectBids[_projectId][i] == _creatorAddress){
                creatorBid = true;
                break;
            }
        }
        require(creatorBid, "Creator has not bid on this project.");
        projects[_projectId].creatorAddress = _creatorAddress;
        projects[_projectId].projectStatus = Status.CreatorSelected;
        emit CreatorSelected(_projectId, _creatorAddress);
    }

    /**
     * @dev Clients approve the completion of a specific milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone to approve.
     */
    function approveMilestone(uint256 _projectId, uint256 _milestoneId) external validProject(_projectId) onlyClient(_projectId) projectInStatus(_projectId, Status.MilestonePendingApproval) validMilestone(_projectId, _milestoneId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.milestoneStatus == Milestone.Status.Submitted, "Milestone is not submitted for approval");

        milestone.milestoneStatus = Milestone.Status.Approved;
        uint256 paymentAmount = (project.budget * milestone.percentageOfBudget) / 100;
        uint256 agencyFee = (paymentAmount * agencyFeePercentage) / 100;
        uint256 creatorPayment = paymentAmount - agencyFee;

        (bool success, ) = payable(project.creatorAddress).call{value: creatorPayment}("");
        require(success, "Payment to creator failed");
        project.fundsReleased += creatorPayment;

        // Agency fee handling (example - send to contract owner as agency treasury)
        (success, ) = payable(owner()).call{value: agencyFee}("");
        require(success, "Agency fee transfer failed");
        project.fundsReleased += agencyFee; // Technically, funds released from project budget context

        emit MilestoneApproved(_projectId, _milestoneId);

        bool allMilestonesApproved = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].milestoneStatus != Milestone.Status.Approved) {
                allMilestonesApproved = false;
                break;
            }
        }

        if (allMilestonesApproved) {
            project.projectStatus = Status.Completed;
            emit ProjectFinalized(_projectId);
        } else {
            project.projectStatus = Status.InProgress; // Back to in progress if not all are approved but some are.
        }
    }

    /**
     * @dev Clients finalize the project after all milestones are approved. (Could be implicit after last milestone approval).
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProject(uint256 _projectId) external validProject(_projectId) onlyClient(_projectId) projectInStatus(_projectId, Status.Completed) {
        // In this implementation, project becomes 'Completed' status automatically after last milestone approval.
        // This function could be for additional actions like releasing remaining funds (if any - in this example, budget is fully distributed per milestones).
        // Or just for clarity/explicit finalization.
        projects[_projectId].projectStatus = Status.Completed; // Redundant in current flow but kept for potential future logic.
        emit ProjectFinalized(_projectId);
    }

    /**
     * @dev Clients can cancel a project under specific conditions (e.g., before creator selection).
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) external validProject(_projectId) onlyClient(_projectId) projectInStatus(_projectId, Status.Open) {
        Project storage project = projects[_projectId];
        require(project.creatorAddress == address(0), "Cannot cancel project after creator is selected."); // Example condition

        uint256 refundAmount = project.fundsDeposited;
        project.fundsDeposited = 0;
        project.projectStatus = Status.Cancelled;

        (bool success, ) = payable(project.clientAddress).call{value: refundAmount}("");
        require(success, "Refund to client failed");

        emit ProjectCancelled(_projectId);
    }

    /**
     * @dev Clients submit feedback for a completed project and creator.
     * @param _projectId The ID of the project.
     * @param _feedback The feedback string.
     */
    function submitFeedback(uint256 _projectId, string memory _feedback) external validProject(_projectId) onlyClient(_projectId) projectInStatus(_projectId, Status.Completed) {
        projects[_projectId].feedback = _feedback;
        // In a more advanced system, could update creator reputation here based on feedback.
        emit FeedbackSubmitted(_projectId, _feedback);
    }


    // ------------------------------------------------------------------------
    // Creator & Portfolio Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Creators register their profile with the agency.
     * @param _name Creator's display name.
     * @param _portfolioLink Link to the creator's online portfolio.
     * @param _skills An array of skills the creator possesses.
     * @param _categoryIds An array of category IDs the creator specializes in.
     */
    function registerCreatorProfile(
        string memory _name,
        string memory _portfolioLink,
        string[] memory _skills,
        uint256[] memory _categoryIds
    ) external {
        require(creatorProfiles[_msgSender()].creatorAddress == address(0), "Profile already registered");
        require(_categoryIds.length > 0, "Must select at least one category");
        for(uint256 i=0; i<_categoryIds.length; i++){
            require(bytes(categories[_categoryIds[i]]).length > 0, "Invalid category ID in list");
        }

        creatorProfiles[_msgSender()] = CreatorProfile({
            name: _name,
            portfolioLink: _portfolioLink,
            skills: _skills,
            categoryIds: _categoryIds,
            creatorAddress: _msgSender(),
            reputationScore: 0, // Initial reputation
            isActive: true
        });
        registeredCreators.push(_msgSender());
        emit CreatorRegistered(_msgSender(), _name);
    }

    /**
     * @dev Creators update their profile information.
     * @param _name New display name.
     * @param _portfolioLink New portfolio link.
     * @param _skills Updated skills list.
     * @param _categoryIds Updated category IDs.
     */
    function updateCreatorProfile(
        string memory _name,
        string memory _portfolioLink,
        string[] memory _skills,
        uint256[] memory _categoryIds
    ) external {
        require(creatorProfiles[_msgSender()].creatorAddress != address(0), "Profile not registered yet");
         require(_categoryIds.length > 0, "Must select at least one category");
        for(uint256 i=0; i<_categoryIds.length; i++){
            require(bytes(categories[_categoryIds[i]]).length > 0, "Invalid category ID in list");
        }

        CreatorProfile storage profile = creatorProfiles[_msgSender()];
        profile.name = _name;
        profile.portfolioLink = _portfolioLink;
        profile.skills = _skills;
        profile.categoryIds = _categoryIds;
        emit CreatorProfileUpdated(_msgSender());
    }

    /**
     * @dev Creators bid on an open project.
     * @param _projectId The ID of the project to bid on.
     * @param _bidDetails Optional details about the bid (e.g., proposal, pricing adjustments).
     */
    function bidOnProject(uint256 _projectId, string memory _bidDetails) external validProject(_projectId) projectInStatus(_projectId, Status.Open) {
        require(creatorProfiles[_msgSender()].creatorAddress != address(0), "Creator profile must be registered to bid");
        bool alreadyBid = false;
        for(uint256 i = 0; i < projectBids[_projectId].length; i++){
            if(projectBids[_projectId][i] == _msgSender()){
                alreadyBid = true;
                break;
            }
        }
        require(!alreadyBid, "Already bid on this project.");

        projectBids[_projectId].push(_msgSender());
        emit BidSubmitted(_projectId, _msgSender());
    }

    /**
     * @dev Creators submit their work for a specific milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _workSubmissionLink Link to where the completed work can be accessed.
     */
    function submitMilestoneWork(uint256 _projectId, uint256 _milestoneId, string memory _workSubmissionLink) external validProject(_projectId) onlyCreator(_projectId) projectInStatus(_projectId, Status.InProgress) validMilestone(_projectId, _milestoneId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.milestoneStatus == Milestone.Status.Pending, "Milestone is not in 'Pending' status.");

        milestone.workSubmissionLink = _workSubmissionLink;
        milestone.milestoneStatus = Milestone.Status.Submitted;
        project.projectStatus = Status.MilestonePendingApproval;
        emit MilestoneSubmitted(_projectId, _milestoneId);
    }

    /**
     * @dev Creators request payment for a completed milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone for which payment is requested.
     */
    function requestMilestonePayment(uint256 _projectId, uint256 _milestoneId) external validProject(_projectId) onlyCreator(_projectId) projectInStatus(_projectId, Status.MilestonePendingApproval) validMilestone(_projectId, _milestoneId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.milestoneStatus == Milestone.Status.Submitted, "Milestone is not submitted for approval");
        // Payment is triggered by client approval in `approveMilestone()` function.
        // This function might be kept for record keeping or to trigger notifications (off-chain).
        // In this simplified example, it primarily flags for the client to review and approve.
        project.projectStatus = Status.MilestonePendingApproval; // Redundant - already set in `submitMilestoneWork`, but kept for clarity if separate workflow desired.
        emit MilestoneSubmitted(_projectId, _milestoneId); // Re-emit, or create new event if needed.
    }

    /**
     * @dev Creators withdraw their accumulated earnings from the agency.
     */
    function withdrawEarnings() external nonReentrant {
        // In this simplified example, earnings are directly sent to creator during milestone approval.
        // In a more complex system, earnings could be tracked within the creator profile and withdrawn separately.
        // For this example, we will assume creators directly receive payments upon milestone approval and this function is not needed in this specific flow.
        revert("Earnings are paid out upon milestone approval. No separate withdrawal needed in this implementation.");
        // In a different system, you might have:
        // uint256 withdrawableAmount = creatorProfiles[_msgSender()].earningsBalance;
        // require(withdrawableAmount > 0, "No earnings to withdraw");
        // creatorProfiles[_msgSender()].earningsBalance = 0;
        // (bool success, ) = payable(_msgSender()).call{value: withdrawableAmount}("");
        // require(success, "Withdrawal failed");
        // emit EarningsWithdrawn(_msgSender(), withdrawableAmount);
    }


    // ------------------------------------------------------------------------
    // Utility & Information Retrieval Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Retrieves detailed information about a specific project.
     * @param _projectId The ID of the project.
     * @return Project struct containing project details.
     */
    function getProjectDetails(uint256 _projectId) external view validProject(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    /**
     * @dev Retrieves details of a creator's profile.
     * @param _creatorAddress The address of the creator.
     * @return CreatorProfile struct containing creator details.
     */
    function getCreatorProfileDetails(address _creatorAddress) external view returns (CreatorProfile memory) {
        return creatorProfiles[_creatorAddress];
    }

    /**
     * @dev Retrieves the name of a category given its ID.
     * @param _categoryId The ID of the category.
     * @return The name of the category.
     */
    function getCategoryName(uint256 _categoryId) external view validCategory(_categoryId) returns (string memory) {
        return categories[_categoryId];
    }

    /**
     * @dev Retrieves the current balance of the DACA smart contract.
     * @return The balance of the contract in wei.
     */
    function getAgencyBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves details of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return GovernanceProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return proposals[_proposalId];
    }

    // Fallback function to receive ether (if needed for any reason)
    receive() external payable {}
}
```