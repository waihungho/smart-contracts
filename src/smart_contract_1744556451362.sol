```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO).
 * It facilitates research project proposals, funding, peer review, data management, and reputation tracking,
 * all governed by token holders. This contract aims to provide a transparent, efficient, and community-driven
 * platform for scientific and technological research.
 *
 * **Outline and Function Summary:**
 *
 * **1. Governance Functions:**
 *    - `proposeParameterChange(string memory parameterName, uint256 newValue)`: Allows token holders to propose changes to contract parameters.
 *    - `voteOnProposal(uint256 proposalId, bool support)`: Allows token holders to vote on governance proposals.
 *    - `executeProposal(uint256 proposalId)`: Executes a governance proposal if it passes.
 *    - `setQuorum(uint256 newQuorumPercentage)`: Owner function to set the quorum percentage for proposals to pass.
 *    - `setVotingPeriod(uint256 newVotingPeriod)`: Owner function to set the voting period for proposals.
 *
 * **2. Research Project Management Functions:**
 *    - `submitResearchProposal(string memory title, string memory description, uint256 fundingGoal, string memory researchPlan)`: Allows researchers to submit research proposals.
 *    - `fundResearchProject(uint256 projectId, uint256 amount)`: Allows anyone to contribute funds to a research project.
 *    - `markMilestoneComplete(uint256 projectId, uint256 milestoneId)`: Researcher function to mark a milestone as completed.
 *    - `requestPeerReview(uint256 projectId, uint256 milestoneId)`: Researcher function to request peer review for a completed milestone.
 *    - `submitPeerReview(uint256 projectId, uint256 milestoneId, string memory reviewFeedback, bool isApproved)`: Designated peer reviewers to submit reviews.
 *    - `approveMilestone(uint256 projectId, uint256 milestoneId)`: Governance function to approve a milestone after successful peer review.
 *    - `withdrawProjectFunds(uint256 projectId)`: Researcher function to withdraw approved funds for completed milestones.
 *    - `cancelProject(uint256 projectId)`: Governance function to cancel a project if it fails to meet milestones or funding goals.
 *    - `addResearcherToProject(uint256 projectId, address researcherAddress)`: Owner/Governance function to add researchers to a project (for collaborative projects).
 *    - `removeResearcherFromProject(uint256 projectId, address researcherAddress)`: Owner/Governance function to remove researchers from a project.
 *
 * **3. Funding and Staking Functions:**
 *    - `stakeTokens(uint256 amount)`: Allows token holders to stake tokens to participate in governance and potentially earn rewards.
 *    - `unstakeTokens(uint256 amount)`: Allows token holders to unstake tokens.
 *    - `donateToDARO()`: Allows anyone to donate ETH/tokens to the DARO for general research funding.
 *    - `distributeStakingRewards()`: Function to distribute rewards to stakers (can be based on governance participation or donations).
 *
 * **4. Data and IP Management Functions:**
 *    - `storeResearchDataHash(uint256 projectId, uint256 milestoneId, string memory dataHash)`: Researcher function to store the hash of research data related to a milestone.
 *    - `retrieveResearchDataHash(uint256 projectId, uint256 milestoneId)`: Anyone can retrieve the data hash for a milestone.
 *    - `registerIntellectualProperty(uint256 projectId, string memory ipDescription, string memory ipHash)`: Researcher function to register intellectual property related to a project.
 *
 * **5. Reputation and Reward Functions:**
 *    - `increaseResearcherReputation(address researcherAddress, uint256 reputationPoints)`: Governance function to reward researchers with reputation points for successful projects and contributions.
 *    - `decreaseResearcherReputation(address researcherAddress, uint256 reputationPoints)`: Governance function to decrease researcher reputation for misconduct or project failure.
 *    - `rewardPeerReviewer(address reviewerAddress, uint256 projectId, uint256 milestoneId)`: Function to reward peer reviewers for their contributions (can be tokens or reputation).
 *
 * **6. Utility and Admin Functions:**
 *    - `getContractBalance()`: Returns the contract's ETH balance.
 *    - `pauseContract()`: Owner function to pause certain functionalities of the contract in case of emergency.
 *    - `unpauseContract()`: Owner function to unpause the contract.
 *    - `ownerWithdraw(uint256 amount)`: Owner function to withdraw excess ETH from the contract (for operational costs, etc.).
 */

contract DecentralizedAutonomousResearchOrganization {
    // --- State Variables ---
    address public owner;
    IERC20 public stakingToken; // Optional: Token for governance and staking. Can be set to address(0) for ETH governance.
    uint256 public minStakeAmount; // Minimum amount to stake for governance participation
    uint256 public quorumPercentage = 50; // Percentage of votes required to pass a proposal
    uint256 public votingPeriod = 7 days; // Default voting period in blocks

    uint256 public proposalCount = 0;
    mapping(uint256 => Proposal) public proposals;
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    struct Proposal {
        ProposalStatus status;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voters;
        function(uint256) external payable targetFunction; // Generic function call for proposals
        string parameterName; // Parameter to change (for parameter change proposals)
        uint256 newValue;      // New value for the parameter (for parameter change proposals)
    }

    uint256 public projectCount = 0;
    mapping(uint256 => ResearchProject) public researchProjects;
    enum ProjectStatus { Proposed, Funded, InProgress, MilestoneReview, Completed, Cancelled }
    struct ResearchProject {
        ProjectStatus status;
        address researcher; // Project lead researcher
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string researchPlan;
        uint256 milestoneCount;
        mapping(uint256 => Milestone) milestones;
        address[] researchers; // List of researchers involved in the project
    }

    struct Milestone {
        string description;
        uint256 fundingAmount;
        bool completed;
        bool peerReviewRequested;
        mapping(address => PeerReview) peerReviews;
        bool milestoneApproved;
        string dataHash; // Hash of research data for this milestone
        string ipHash;   // Hash of intellectual property registration (if applicable)
    }

    struct PeerReview {
        address reviewer;
        string feedback;
        bool approved;
        bool submitted;
    }

    mapping(address => uint256) public stakers; // Staked token balance for each address
    mapping(address => uint256) public researcherReputation; // Reputation score for researchers
    mapping(address => bool) public peerReviewers; // List of approved peer reviewers
    bool public contractPaused = false;

    // --- Events ---
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status);
    event QuorumUpdated(uint256 newQuorumPercentage);
    event VotingPeriodUpdated(uint256 newVotingPeriod);

    event ResearchProposalSubmitted(uint256 projectId, address researcher, string title);
    event ProjectFunded(uint256 projectId, address funder, uint256 amount);
    event MilestoneMarkedComplete(uint256 projectId, uint256 milestoneId);
    event PeerReviewRequested(uint256 projectId, uint256 milestoneId);
    event PeerReviewSubmitted(uint256 projectId, uint256 milestoneId, address reviewer, bool approved);
    event MilestoneApproved(uint256 projectId, uint256 milestoneId);
    event FundsWithdrawn(uint256 projectId, address researcher, uint256 amount);
    event ProjectCancelled(uint256 projectId);
    event ResearcherAddedToProject(uint256 projectId, address researcherAddress);
    event ResearcherRemovedFromProject(uint256 projectId, address researcherAddress);

    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address staker, uint256 amount);
    event DonationReceived(address donor, uint256 amount);
    event StakingRewardsDistributed(uint256 amount);

    event DataHashStored(uint256 projectId, uint256 milestoneId, string dataHash);
    event IPRegistered(uint256 projectId, string ipHash);

    event ReputationIncreased(address researcherAddress, uint256 reputationPoints);
    event ReputationDecreased(address researcherAddress, uint256 reputationPoints);
    event PeerReviewerRewarded(address reviewerAddress, uint256 projectId, uint256 milestoneId);

    event ContractPaused();
    event ContractUnpaused();
    event OwnerWithdrawal(uint256 amount, address owner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }

    modifier onlyStakers() {
        require(stakers[msg.sender] > 0, "You must stake tokens to participate in governance.");
        _;
    }

    modifier onlyProjectResearcher(uint256 _projectId) {
        require(researchProjects[_projectId].researcher == msg.sender || isResearcherInProject(_projectId, msg.sender), "Only project researcher can call this function.");
        _;
    }

    modifier onlyPeerReviewer() {
        require(peerReviewers[msg.sender], "Only approved peer reviewers can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier validProject(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= projectCount, "Invalid project ID.");
        _;
    }

    modifier validMilestone(uint256 _projectId, uint256 _milestoneId) {
        require(_milestoneId > 0 && _milestoneId <= researchProjects[_projectId].milestoneCount, "Invalid milestone ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }

    modifier projectInStatus(uint256 _projectId, ProjectStatus _status) {
        require(researchProjects[_projectId].status == _status, "Project is not in the required status.");
        _;
    }


    // --- Constructor ---
    constructor(address _stakingTokenAddress, uint256 _minStakeAmount) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingTokenAddress);
        minStakeAmount = _minStakeAmount;
    }

    // --- 1. Governance Functions ---

    /// @notice Allows token holders to propose changes to contract parameters.
    /// @param _parameterName The name of the parameter to change.
    /// @param _newValue The new value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue)
        external
        whenNotPaused
        onlyStakers
    {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            status: ProposalStatus.Pending,
            proposer: msg.sender,
            description: string(abi.encodePacked("Change parameter: ", _parameterName)),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            targetFunction: this.setParameter, // Example target, needs to be adapted for each parameter
            parameterName: _parameterName,
            newValue: _newValue
        });
        emit ParameterChangeProposed(proposalCount, _parameterName, _newValue, msg.sender);
    }

    function setParameter(uint256 _proposalId) private {
        // Example - Expand this based on parameters you want to govern
        if (keccak256(abi.encode(proposals[_proposalId].parameterName)) == keccak256(abi.encode("quorumPercentage"))) {
            setQuorum(proposals[_proposalId].newValue);
        } else if (keccak256(abi.encode(proposals[_proposalId].parameterName)) == keccak256(abi.encode("votingPeriod"))) {
            setVotingPeriod(proposals[_proposalId].newValue);
        } else if (keccak256(abi.encode(proposals[_proposalId].parameterName)) == keccak256(abi.encode("minStakeAmount"))) {
            setMinStakeAmount(proposals[_proposalId].newValue);
        }
        // Add more parameter checks here
    }

    function setMinStakeAmount(uint256 _newMinStakeAmount) private onlyOwner {
        minStakeAmount = _newMinStakeAmount;
    }


    /// @notice Allows token holders to vote on governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
        onlyStakers
        validProposal(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Pending)
    {
        require(!proposals[_proposalId].voters[msg.sender], "You have already voted on this proposal.");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended.");

        proposals[_proposalId].voters[msg.sender] = true;
        if (_support) {
            proposals[_proposalId].votesFor += stakers[msg.sender]; // Voting power based on staked tokens
        } else {
            proposals[_proposalId].votesAgainst += stakers[msg.sender];
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal if it passes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        validProposal(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Pending) // Can only execute pending proposals
    {
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period is not over yet.");
        uint256 totalStakedSupply = getTotalStakedSupply();
        require((proposals[_proposalId].votesFor * 100) / totalStakedSupply >= quorumPercentage, "Proposal does not meet quorum.");

        proposals[_proposalId].status = ProposalStatus.Passed;
        proposals[_proposalId].targetFunction(_proposalId); // Execute the target function defined in the proposal
        proposals[_proposalId].status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, ProposalStatus.Executed);
    }


    /// @notice Owner function to set the quorum percentage for proposals to pass.
    /// @param _newQuorumPercentage The new quorum percentage.
    function setQuorum(uint256 _newQuorumPercentage) external onlyOwner {
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumUpdated(_newQuorumPercentage);
    }

    /// @notice Owner function to set the voting period for proposals.
    /// @param _newVotingPeriod The new voting period in seconds.
    function setVotingPeriod(uint256 _newVotingPeriod) external onlyOwner {
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodUpdated(_newVotingPeriod);
    }


    // --- 2. Research Project Management Functions ---

    /// @notice Allows researchers to submit research proposals.
    /// @param _title The title of the research proposal.
    /// @param _description A brief description of the research.
    /// @param _fundingGoal The funding goal for the project.
    /// @param _researchPlan A detailed plan for the research.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _researchPlan
    ) external whenNotPaused {
        projectCount++;
        researchProjects[projectCount] = ResearchProject({
            status: ProjectStatus.Proposed,
            researcher: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            researchPlan: _researchPlan,
            milestoneCount: 0,
            researchers: new address[](1) // Initialize researchers array with the lead researcher
        });
        researchProjects[projectCount].researchers[0] = msg.sender;
        emit ResearchProposalSubmitted(projectCount, msg.sender, _title);
    }

    /// @notice Allows anyone to contribute funds to a research project.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount to contribute.
    function fundResearchProject(uint256 _projectId, uint256 _amount)
        external
        payable
        whenNotPaused
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.Proposed)
    {
        require(researchProjects[_projectId].currentFunding + _amount <= researchProjects[_projectId].fundingGoal, "Funding goal exceeded.");
        researchProjects[_projectId].currentFunding += _amount;
        if (researchProjects[_projectId].currentFunding >= researchProjects[_projectId].fundingGoal) {
            researchProjects[_projectId].status = ProjectStatus.Funded;
        }
        emit ProjectFunded(_projectId, msg.sender, _amount);
        // Optionally transfer ETH or tokens here if using a specific funding token instead of msg.value
    }

    /// @notice Researcher function to mark a milestone as completed.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    function markMilestoneComplete(uint256 _projectId, uint256 _milestoneId)
        external
        whenNotPaused
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        projectInStatus(_projectId, ProjectStatus.InProgress)
        onlyProjectResearcher(_projectId)
    {
        require(!researchProjects[_projectId].milestones[_milestoneId].completed, "Milestone already marked as complete.");
        researchProjects[_projectId].milestones[_milestoneId].completed = true;
        emit MilestoneMarkedComplete(_projectId, _milestoneId);
    }

    /// @notice Researcher function to request peer review for a completed milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    function requestPeerReview(uint256 _projectId, uint256 _milestoneId)
        external
        whenNotPaused
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        projectInStatus(_projectId, ProjectStatus.InProgress)
        onlyProjectResearcher(_projectId)
    {
        require(researchProjects[_projectId].milestones[_milestoneId].completed, "Milestone must be marked as complete before requesting peer review.");
        require(!researchProjects[_projectId].milestones[_milestoneId].peerReviewRequested, "Peer review already requested for this milestone.");
        researchProjects[_projectId].milestones[_milestoneId].peerReviewRequested = true;
        researchProjects[_projectId].status = ProjectStatus.MilestoneReview; // Update project status
        emit PeerReviewRequested(_projectId, _milestoneId);
    }

    /// @notice Designated peer reviewers to submit reviews.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    /// @param _reviewFeedback Feedback from the peer reviewer.
    /// @param _isApproved True if approved, false if rejected.
    function submitPeerReview(uint256 _projectId, uint256 _milestoneId, string memory _reviewFeedback, bool _isApproved)
        external
        whenNotPaused
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        projectInStatus(_projectId, ProjectStatus.MilestoneReview)
        onlyPeerReviewer()
    {
        require(researchProjects[_projectId].milestones[_milestoneId].peerReviewRequested, "Peer review was not requested for this milestone.");
        require(!researchProjects[_projectId].milestones[_milestoneId].peerReviews[msg.sender].submitted, "You have already submitted a review for this milestone.");

        researchProjects[_projectId].milestones[_milestoneId].peerReviews[msg.sender] = PeerReview({
            reviewer: msg.sender,
            feedback: _reviewFeedback,
            approved: _isApproved,
            submitted: true
        });
        emit PeerReviewSubmitted(_projectId, _milestoneId, msg.sender, _isApproved);
    }

    /// @notice Governance function to approve a milestone after successful peer review.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    function approveMilestone(uint256 _projectId, uint256 _milestoneId)
        external
        whenNotPaused
        onlyOwner // Governance can be DAO or owner initially
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        projectInStatus(_projectId, ProjectStatus.MilestoneReview)
    {
        require(researchProjects[_projectId].milestones[_milestoneId].peerReviewRequested, "Peer review must be requested first.");
        uint256 approvedReviews = 0;
        uint256 totalReviews = 0;
        for (uint256 i = 0; i < peerReviewers.length(); i++) { // Iterate through peer reviewers
            address reviewer = peerReviewers[i];
            if (researchProjects[_projectId].milestones[_milestoneId].peerReviews[reviewer].submitted) {
                totalReviews++;
                if (researchProjects[_projectId].milestones[_milestoneId].peerReviews[reviewer].approved) {
                    approvedReviews++;
                }
            }
        }
        require(approvedReviews > (totalReviews / 2), "Milestone not approved by peer review."); // Simple majority for approval
        researchProjects[_projectId].milestones[_milestoneId].milestoneApproved = true;
        emit MilestoneApproved(_projectId, _milestoneId);
    }

    /// @notice Researcher function to withdraw approved funds for completed milestones.
    /// @param _projectId The ID of the project.
    function withdrawProjectFunds(uint256 _projectId)
        external
        whenNotPaused
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.MilestoneReview) // Or InProgress after milestone approval
        onlyProjectResearcher(_projectId)
    {
        uint256 withdrawableAmount = 0;
        for (uint256 i = 1; i <= researchProjects[_projectId].milestoneCount; i++) {
            if (researchProjects[_projectId].milestones[i].milestoneApproved && !researchProjects[_projectId].milestones[i].dataHash.length() > 0) { // Funds can be withdrawn after milestone approval and data submission
                withdrawableAmount += researchProjects[_projectId].milestones[i].fundingAmount;
            }
        }
        require(withdrawableAmount > 0, "No funds available for withdrawal at this time.");
        require(researchProjects[_projectId].currentFunding >= withdrawableAmount, "Contract balance insufficient for withdrawal.");

        researchProjects[_projectId].currentFunding -= withdrawableAmount;
        payable(msg.sender).transfer(withdrawableAmount); // Transfer ETH for now, adjust for tokens if needed
        emit FundsWithdrawn(_projectId, msg.sender, withdrawableAmount);
    }

    /// @notice Governance function to cancel a project if it fails to meet milestones or funding goals.
    /// @param _projectId The ID of the project to cancel.
    function cancelProject(uint256 _projectId)
        external
        whenNotPaused
        onlyOwner // Governance function
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.InProgress) // Or other relevant statuses
    {
        researchProjects[_projectId].status = ProjectStatus.Cancelled;
        emit ProjectCancelled(_projectId);
        // Implement logic to return remaining funds to funders if needed.
    }

    /// @notice Owner/Governance function to add researchers to a project (for collaborative projects).
    /// @param _projectId The ID of the project.
    /// @param _researcherAddress The address of the researcher to add.
    function addResearcherToProject(uint256 _projectId, address _researcherAddress)
        external
        whenNotPaused
        onlyOwner // Or governance function
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.Proposed) // Can add researchers before funding or in progress
    {
        require(!isResearcherInProject(_projectId, _researcherAddress), "Researcher is already in the project.");
        researchProjects[_projectId].researchers.push(_researcherAddress);
        emit ResearcherAddedToProject(_projectId, _researcherAddress);
    }

    /// @notice Owner/Governance function to remove researchers from a project.
    /// @param _projectId The ID of the project.
    /// @param _researcherAddress The address of the researcher to remove.
    function removeResearcherFromProject(uint256 _projectId, address _researcherAddress)
        external
        whenNotPaused
        onlyOwner // Or governance function
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.Proposed) // Or other relevant statuses
    {
        require(isResearcherInProject(_projectId, _researcherAddress), "Researcher is not in the project.");
        address[] storage researchers = researchProjects[_projectId].researchers;
        for (uint256 i = 0; i < researchers.length; i++) {
            if (researchers[i] == _researcherAddress) {
                researchers[i] = researchers[researchers.length - 1];
                researchers.pop();
                emit ResearcherRemovedFromProject(_projectId, _researcherAddress);
                return;
            }
        }
    }


    // --- 3. Funding and Staking Functions ---

    /// @notice Allows token holders to stake tokens to participate in governance and potentially earn rewards.
    /// @param _amount The amount of tokens to stake.
    function stakeTokens(uint256 _amount) external whenNotPaused {
        require(_amount >= minStakeAmount, "Stake amount must be at least the minimum stake amount.");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
        stakers[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows token holders to unstake tokens.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) external whenNotPaused {
        require(stakers[msg.sender] >= _amount, "Insufficient staked tokens.");
        stakers[msg.sender] -= _amount;
        require(stakingToken.transfer(msg.sender, _amount), "Token transfer failed.");
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Allows anyone to donate ETH/tokens to the DARO for general research funding.
    function donateToDARO() external payable whenNotPaused {
        emit DonationReceived(msg.sender, msg.value); // For ETH donations
        // For token donations, implement a separate function or check token transfers here.
    }

    /// @notice Function to distribute rewards to stakers (can be based on governance participation or donations).
    function distributeStakingRewards() external onlyOwner whenNotPaused {
        // Example: Distribute a portion of contract balance as rewards
        uint256 contractBalance = address(this).balance;
        uint256 rewardAmount = contractBalance / 10; // Example: 10% of balance
        uint256 totalStaked = getTotalStakedSupply();
        require(rewardAmount > 0 && totalStaked > 0, "No rewards to distribute or no stakers.");

        for (address staker : getStakersList()) { // You'd need to maintain a list of stakers for efficient iteration in production
            uint256 stakerReward = (stakers[staker] * rewardAmount) / totalStaked;
            if (stakerReward > 0) {
                payable(staker).transfer(stakerReward);
                emit StakingRewardsDistributed(stakerReward); // More detailed event needed with receiver address
            }
        }
    }


    // --- 4. Data and IP Management Functions ---

    /// @notice Researcher function to store the hash of research data related to a milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    /// @param _dataHash The hash of the research data (e.g., IPFS hash).
    function storeResearchDataHash(uint256 _projectId, uint256 _milestoneId, string memory _dataHash)
        external
        whenNotPaused
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        projectInStatus(_projectId, ProjectStatus.MilestoneReview) // Or InProgress after milestone approval
        onlyProjectResearcher(_projectId)
    {
        require(researchProjects[_projectId].milestones[_milestoneId].milestoneApproved, "Milestone must be approved before storing data.");
        researchProjects[_projectId].milestones[_milestoneId].dataHash = _dataHash;
        emit DataHashStored(_projectId, _milestoneId, _dataHash);
    }

    /// @notice Anyone can retrieve the data hash for a milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneId The ID of the milestone.
    /// @return string The data hash.
    function retrieveResearchDataHash(uint256 _projectId, uint256 _milestoneId)
        external
        view
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        returns (string memory)
    {
        return researchProjects[_projectId].milestones[_milestoneId].dataHash;
    }

    /// @notice Researcher function to register intellectual property related to a project.
    /// @param _projectId The ID of the project.
    /// @param _ipDescription Description of the intellectual property.
    /// @param _ipHash Hash of the IP documentation or registration (e.g., IPFS hash).
    function registerIntellectualProperty(uint256 _projectId, string memory _ipDescription, string memory _ipHash)
        external
        whenNotPaused
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.InProgress) // Or Completed
        onlyProjectResearcher(_projectId)
    {
        // Implement logic to verify IP registration if needed, potentially integrate with IP registry contracts.
        for (uint256 i = 1; i <= researchProjects[_projectId].milestoneCount; i++) { // Register IP at project level for now, could be per milestone
            researchProjects[_projectId].milestones[i].ipHash = _ipHash;
        }
        emit IPRegistered(_projectId, _ipHash);
    }


    // --- 5. Reputation and Reward Functions ---

    /// @notice Governance function to reward researchers with reputation points for successful projects and contributions.
    /// @param _researcherAddress The address of the researcher to reward.
    /// @param _reputationPoints The number of reputation points to award.
    function increaseResearcherReputation(address _researcherAddress, uint256 _reputationPoints)
        external
        whenNotPaused
        onlyOwner // Or governance function
    {
        researcherReputation[_researcherAddress] += _reputationPoints;
        emit ReputationIncreased(_researcherAddress, _reputationPoints);
    }

    /// @notice Governance function to decrease researcher reputation for misconduct or project failure.
    /// @param _researcherAddress The address of the researcher to penalize.
    /// @param _reputationPoints The number of reputation points to deduct.
    function decreaseResearcherReputation(address _researcherAddress, uint256 _reputationPoints)
        external
        whenNotPaused
        onlyOwner // Or governance function
    {
        researcherReputation[_researcherAddress] -= _reputationPoints;
        emit ReputationDecreased(_researcherAddress, _reputationPoints);
    }

    /// @notice Function to reward peer reviewers for their contributions (can be tokens or reputation).
    /// @param _reviewerAddress The address of the peer reviewer to reward.
    /// @param _projectId The ID of the project reviewed.
    /// @param _milestoneId The ID of the milestone reviewed.
    function rewardPeerReviewer(address _reviewerAddress, uint256 _projectId, uint256 _milestoneId)
        external
        whenNotPaused
        onlyOwner // Or governance function
        validProject(_projectId)
        validMilestone(_projectId, _milestoneId)
        onlyPeerReviewer()
    {
        // Example: Reward with reputation points
        increaseResearcherReputation(_reviewerAddress, 10); // Example: 10 reputation points
        emit PeerReviewerRewarded(_reviewerAddress, _projectId, _milestoneId);
    }


    // --- 6. Utility and Admin Functions ---

    /// @notice Returns the contract's ETH balance.
    /// @return uint256 The contract's ETH balance.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Owner function to pause certain functionalities of the contract in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Owner function to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /// @notice Owner function to withdraw excess ETH from the contract (for operational costs, etc.).
    /// @param _amount The amount of ETH to withdraw.
    function ownerWithdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Contract balance insufficient.");
        payable(owner).transfer(_amount);
        emit OwnerWithdrawal(_amount, owner);
    }

    // --- Helper Functions ---

    /// @dev Function to add a new milestone to a research project.
    /// @param _projectId The ID of the project.
    /// @param _milestoneDescription Description of the milestone.
    /// @param _milestoneFundingAmount Funding allocated for this milestone.
    function addMilestoneToProject(uint256 _projectId, string memory _milestoneDescription, uint256 _milestoneFundingAmount)
        external
        whenNotPaused
        onlyProjectResearcher(_projectId) // Or governance/owner depending on design
        validProject(_projectId)
        projectInStatus(_projectId, ProjectStatus.Proposed) // Or Funded/InProgress as needed
    {
        require(researchProjects[_projectId].currentFunding + _milestoneFundingAmount <= researchProjects[_projectId].fundingGoal, "Adding this milestone exceeds the project funding goal.");
        researchProjects[_projectId].milestoneCount++;
        uint256 newMilestoneId = researchProjects[_projectId].milestoneCount;
        researchProjects[_projectId].milestones[newMilestoneId] = Milestone({
            description: _milestoneDescription,
            fundingAmount: _milestoneFundingAmount,
            completed: false,
            peerReviewRequested: false,
            milestoneApproved: false,
            dataHash: "",
            ipHash: ""
        });
        researchProjects[_projectId].fundingGoal += _milestoneFundingAmount; // Update funding goal if needed
    }

    /// @dev Function to check if an address is a researcher in a project.
    /// @param _projectId The ID of the project.
    /// @param _researcherAddress The address to check.
    /// @return bool True if the address is a researcher in the project, false otherwise.
    function isResearcherInProject(uint256 _projectId, address _researcherAddress)
        internal
        view
        validProject(_projectId)
        returns (bool)
    {
        for (uint256 i = 0; i < researchProjects[_projectId].researchers.length; i++) {
            if (researchProjects[_projectId].researchers[i] == _researcherAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev Function to get total staked token supply.
    /// @return uint256 Total staked tokens.
    function getTotalStakedSupply() public view returns (uint256) {
        uint256 totalStaked = 0;
        // Inefficient in production for large number of stakers. Use a list or other optimization.
        // Iterate through stakers mapping (requires knowing all staker addresses - not directly iterable in Solidity mappings)
        // For demonstration purposes, this is a simplified placeholder.
        // In a real application, maintain a list of stakers or use a more efficient data structure.
        // For now, assuming we can iterate through stakers for demonstration:
        address[] memory stakerAddresses = getStakersList(); // Placeholder - needs implementation for real use
        for (uint256 i = 0; i < stakerAddresses.length; i++) {
            totalStaked += stakers[stakerAddresses[i]];
        }
        return totalStaked;
    }

    // Placeholder for getStakersList - needs actual implementation for efficient iteration in production.
    // In a real application, you would maintain a list of staker addresses upon staking and unstaking.
    function getStakersList() private view returns (address[] memory) {
        address[] memory stakerList = new address[](0); // Placeholder - Replace with actual list management
        // In a real implementation, you would maintain a dynamic array of staker addresses
        // and update it when users stake/unstake.
        return stakerList;
    }
}

// --- Interface for ERC20 Token (if used for staking) ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```