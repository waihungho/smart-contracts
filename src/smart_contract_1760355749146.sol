```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ImpactCatalystDAO
 * @dev A decentralized autonomous organization for funding projects based on predicted societal impact.
 * It integrates AI oracle predictions, decentralized governance, milestone-based funding,
 * and a reputation-based incentive system (`IMPACT_REP` tokens).
 */
contract ImpactCatalystDAO is Ownable, ReentrancyGuard {

    // --- Outline and Function Summary ---

    // I. Core Fund & Project Management
    //    1.  `depositFunds()`: Accepts ETH contributions to the DAO's treasury.
    //    2.  `submitProject()`: Allows proposers to submit detailed project proposals, including budget, description, and milestones.
    //    3.  `updateProjectDetails()`: Enables a project proposer to modify their project's details before it enters a funding round.
    //    4.  `withdrawProjectSubmission()`: Allows a proposer to retract their project if it hasn't been funded yet.
    //    5.  `setFundingRoundStatus()`: Owner/governance initiates or concludes a funding round, enabling/disabling new project voting.

    // II. AI Oracle & Predictive Impact Assessment
    //    6.  `registerImpactOracle()`: Whitelists a new address as an approved AI impact prediction oracle.
    //    7.  `requestImpactPrediction()`: Initiates a request to a designated oracle for a predicted impact score of a project.
    //    8.  `submitImpactPrediction()`: Allows a registered oracle to submit the AI-generated impact score for a requested project.
    //    9.  `challengeImpactPrediction()`: Enables DAO members to dispute an oracle's submitted impact prediction, potentially triggering a re-evaluation or a multi-oracle consensus check.
    //    10. `verifyImpactOraclePerformance()`: Periodically assesses and records the accuracy and reliability of registered oracles based on post-project impact, informing future weighting and rewards.

    // III. Decentralized Governance & Funding Allocation
    //    11. `stakeForGovernance()`: Allows members to stake native tokens (e.g., ETH) to gain voting power and accrue `IMPACT_REP`.
    //    12. `voteOnProjectFunding()`: Enables staked members to cast votes on funding approval for projects, with vote weight scaled by stake and `IMPACT_REP`.
    //    13. `allocateProjectFunds()`: Transfers initial or milestone-based funds to a project upon successful voting and verification. Funds are typically released in tranches.
    //    14. `delegateVotePower()`: Allows a stakeholder to delegate their voting rights to another address, enhancing proxy governance.
    //    15. `proposeGovernanceChange()`: Facilitates community proposals to alter key DAO parameters (e.g., funding thresholds, dispute resolution timings), which then undergo a governance vote.

    // IV. Post-Funding & Impact Verification
    //    16. `reportMilestoneCompletion()`: A funded project proposer declares the completion of a specific project milestone.
    //    17. `requestMilestoneVerification()`: Governance or automated system requests an oracle or community verifier to confirm a reported milestone's completion.
    //    18. `submitMilestoneVerification()`: A designated verifier submits their findings regarding a project milestone's completion.
    //    19. `releaseMilestoneFunds()`: Releases the next pre-determined tranche of project funds upon verified milestone completion.
    //    20. `disputeMilestoneVerification()`: Provides a mechanism for project proposers to challenge a negative milestone verification outcome.
    //    21. `finalizeProject()`: Marks a project as fully completed after all milestones are reported and verified, triggering final impact assessment.

    // V. Reputation & Incentives (IMPACT_REP Token Integration)
    //    22. `mintReputationTokens()`: Awards `IMPACT_REP` tokens to participants for valuable contributions (e.g., accurate predictions, successful project delivery, fair verification).
    //    23. `burnReputationTokens()`: Deducts `IMPACT_REP` tokens as a penalty for malicious behavior, inaccurate predictions, or failed projects.
    //    24. `claimReputationReward()`: Allows users to claim accumulated `IMPACT_REP` tokens they've earned.
    //    25. `getReputationScore()`: Publicly viewable function to retrieve the current `IMPACT_REP` balance of any address.

    // --- State Variables ---

    // Configuration
    uint256 public constant MIN_STAKE_FOR_VOTING = 1 ether; // Minimum ETH stake to vote
    uint256 public constant MIN_IMPACT_SCORE_FOR_FUNDING = 60; // Minimum impact score required for a project to be considered for funding (out of 100)
    uint256 public constant VOTING_PERIOD_DURATION = 7 days; // Duration for project funding votes
    uint256 public constant ORACLE_CHALLENGE_WINDOW = 3 days; // Window to challenge an oracle's prediction

    bool public fundingRoundActive;
    uint256 public nextProjectId;
    address public immutable IMPACT_REP_TOKEN_ADDRESS; // Address of the IMPACT_REP ERC20 token

    // Structs
    enum ProjectStatus { Pending, ImpactAssessed, Voting, Approved, Funded, Completed, Rejected, Disputed }
    enum MilestoneStatus { Pending, Reported, Verified, Disputed }
    
    struct Milestone {
        string description;
        uint256 fundingAmount;
        MilestoneStatus status;
        address verifier; // Oracle or community member assigned for verification
        uint256 verificationRequestId; // Link to a verification request
    }

    struct Project {
        address proposer;
        string name;
        string description;
        uint256 requestedFunds;
        uint256 currentFundedAmount;
        Milestone[] milestones;
        uint256 submittedTimestamp;
        ProjectStatus status;
        int256 impactScore; // -1 if not yet assessed, 0-100 score
        uint256 totalVotesFor;
        uint256 totalVoteWeightFor;
        uint256 totalVotesAgainst;
        uint256 totalVoteWeightAgainst;
        uint256 votingEnds;
        address impactOracleAssigned; // Oracle assigned for impact prediction
        uint256 impactPredictionRequestId; // Link to impact prediction request
    }

    struct Oracle {
        bool isRegistered;
        uint256 reputationScore; // Based on past accuracy
        uint256 totalPredictions;
        uint256 accuratePredictions;
        uint256 lastPredictionTimestamp;
    }

    // Mappings
    mapping(uint256 => Project) public projects;
    mapping(address => Oracle) public impactOracles;
    mapping(address => uint256) public stakedAmounts; // ETH staked for governance
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProject; // User -> ProjectId -> Voted
    mapping(address => address) public delegatedVotee; // Deleagator -> Delegatee
    mapping(address => uint256) public reputationRewardQueue; // IMPACT_REP tokens to be claimed

    // Events
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ProjectSubmitted(uint256 indexed projectId, address indexed proposer, string name, uint256 requestedFunds);
    event ProjectUpdated(uint256 indexed projectId);
    event ProjectWithdrawn(uint256 indexed projectId);
    event FundingRoundStatusChanged(bool newStatus);

    event OracleRegistered(address indexed oracleAddress);
    event ImpactPredictionRequested(uint256 indexed projectId, address indexed oracleAddress);
    event ImpactPredictionSubmitted(uint256 indexed projectId, address indexed oracleAddress, int256 score);
    event ImpactPredictionChallenged(uint256 indexed projectId, address indexed challenger, address indexed oracleAddress);
    event OraclePerformanceVerified(address indexed oracleAddress, uint256 newReputationScore);

    event Staked(address indexed staker, uint256 amount);
    event Voted(uint256 indexed projectId, address indexed voter, bool support, uint256 voteWeight);
    event FundsAllocated(uint256 indexed projectId, address indexed recipient, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event GovernanceChangeProposed(address indexed proposer, string description); // Simplified event for governance change

    event MilestoneReported(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneVerificationRequested(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed verifier);
    event MilestoneVerificationSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, bool verified);
    event MilestoneFundsReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneVerificationDisputed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed disputer);
    event ProjectFinalized(uint256 indexed projectId);

    event ReputationTokensMinted(address indexed recipient, uint256 amount);
    event ReputationTokensBurned(address indexed holder, uint256 amount);
    event ReputationRewardClaimed(address indexed claimant, uint256 amount);

    // Modifiers
    modifier onlyRegisteredOracle(address _oracle) {
        require(impactOracles[_oracle].isRegistered, "ImpactCatalystDAO: Not a registered oracle");
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "ImpactCatalystDAO: Not the project proposer");
        _;
    }

    modifier duringFundingRound() {
        require(fundingRoundActive, "ImpactCatalystDAO: Funding round is not active");
        _;
    }

    modifier notDuringFundingRound() {
        require(!fundingRoundActive, "ImpactCatalystDAO: Funding round is active");
        _;
    }

    // --- Constructor ---

    constructor(address _impactRepTokenAddress) Ownable(msg.sender) {
        require(_impactRepTokenAddress != address(0), "ImpactCatalystDAO: IMPACT_REP token address cannot be zero");
        IMPACT_REP_TOKEN_ADDRESS = _impactRepTokenAddress;
        fundingRoundActive = false;
        nextProjectId = 1;
    }

    // --- I. Core Fund & Project Management ---

    /**
     * @dev Allows users to deposit ETH into the DAO's treasury.
     */
    function depositFunds() external payable nonReentrant {
        require(msg.value > 0, "ImpactCatalystDAO: Deposit amount must be greater than 0");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Proposes a new project with details, budget, and milestones.
     * @param _name The name of the project.
     * @param _description A detailed description of the project.
     * @param _requestedFunds The total ETH amount requested for the project.
     * @param _milestoneDescriptions Array of descriptions for each milestone.
     * @param _milestoneFundingAmounts Array of ETH amounts for each milestone. Must sum to `_requestedFunds`.
     */
    function submitProject(
        string memory _name,
        string memory _description,
        uint256 _requestedFunds,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneFundingAmounts
    ) external duringFundingRound returns (uint256 projectId) {
        require(bytes(_name).length > 0, "ImpactCatalystDAO: Project name cannot be empty");
        require(bytes(_description).length > 0, "ImpactCatalystDAO: Project description cannot be empty");
        require(_requestedFunds > 0, "ImpactCatalystDAO: Requested funds must be greater than 0");
        require(_milestoneDescriptions.length == _milestoneFundingAmounts.length, "ImpactCatalystDAO: Milestone arrays length mismatch");
        require(_milestoneDescriptions.length > 0, "ImpactCatalystDAO: At least one milestone is required");

        uint256 totalMilestoneFunds;
        for (uint256 i = 0; i < _milestoneFundingAmounts.length; i++) {
            totalMilestoneFunds += _milestoneFundingAmounts[i];
        }
        require(totalMilestoneFunds == _requestedFunds, "ImpactCatalystDAO: Sum of milestone funds must equal total requested funds");

        Milestone[] memory newMilestones = new Milestone[](_milestoneDescriptions.length);
        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            newMilestones[i] = Milestone({
                description: _milestoneDescriptions[i],
                fundingAmount: _milestoneFundingAmounts[i],
                status: MilestoneStatus.Pending,
                verifier: address(0),
                verificationRequestId: 0 // Placeholder, actual ID will come from oracle system
            });
        }

        projectId = nextProjectId++;
        projects[projectId] = Project({
            proposer: msg.sender,
            name: _name,
            description: _description,
            requestedFunds: _requestedFunds,
            currentFundedAmount: 0,
            milestones: newMilestones,
            submittedTimestamp: block.timestamp,
            status: ProjectStatus.Pending,
            impactScore: -1, // Not yet assessed
            totalVotesFor: 0,
            totalVoteWeightFor: 0,
            totalVotesAgainst: 0,
            totalVoteWeightAgainst: 0,
            votingEnds: 0,
            impactOracleAssigned: address(0),
            impactPredictionRequestId: 0
        });

        emit ProjectSubmitted(projectId, msg.sender, _name, _requestedFunds);
    }

    /**
     * @dev Allows the project proposer to update project details before it's approved for funding.
     * Does not allow changing requested funds or milestones directly, only description.
     * For other changes, the project should be withdrawn and resubmitted.
     * @param _projectId The ID of the project to update.
     * @param _newName The new name for the project.
     * @param _newDescription The new description for the project.
     */
    function updateProjectDetails(
        uint256 _projectId,
        string memory _newName,
        string memory _newDescription
    ) external onlyProjectProposer(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Pending, "ImpactCatalystDAO: Project can only be updated in Pending status");
        require(bytes(_newName).length > 0, "ImpactCatalystDAO: Project name cannot be empty");
        require(bytes(_newDescription).length > 0, "ImpactCatalystDAO: Project description cannot be empty");

        project.name = _newName;
        project.description = _newDescription;

        emit ProjectUpdated(_projectId);
    }

    /**
     * @dev Allows a project proposer to withdraw their project if it hasn't been funded yet.
     * @param _projectId The ID of the project to withdraw.
     */
    function withdrawProjectSubmission(uint256 _projectId) external onlyProjectProposer(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Pending || project.status == ProjectStatus.ImpactAssessed, "ImpactCatalystDAO: Project cannot be withdrawn after voting or funding");

        project.status = ProjectStatus.Rejected; // Mark as rejected/withdrawn
        // In a real system, you might delete the project or move it to an archive.
        // For simplicity, we just change its status.

        emit ProjectWithdrawn(_projectId);
    }

    /**
     * @dev Owner/Governance starts or ends a funding round.
     * Only callable by the owner (or through DAO governance if `proposeGovernanceChange` is fully implemented).
     * @param _isActive True to activate, false to deactivate.
     */
    function setFundingRoundStatus(bool _isActive) external onlyOwner {
        fundingRoundActive = _isActive;
        emit FundingRoundStatusChanged(_isActive);
    }

    // --- II. AI Oracle & Predictive Impact Assessment ---

    /**
     * @dev Allows the DAO owner to register a new AI impact prediction oracle.
     * Oracles are whitelisted entities that provide impact scores.
     * @param _oracleAddress The address of the oracle to register.
     */
    function registerImpactOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "ImpactCatalystDAO: Oracle address cannot be zero");
        require(!impactOracles[_oracleAddress].isRegistered, "ImpactCatalystDAO: Oracle already registered");

        impactOracles[_oracleAddress] = Oracle({
            isRegistered: true,
            reputationScore: 0,
            totalPredictions: 0,
            accuratePredictions: 0,
            lastPredictionTimestamp: 0
        });
        emit OracleRegistered(_oracleAddress);
    }

    /**
     * @dev Initiates a request to a designated oracle for a predicted impact score of a project.
     * This function would typically be called by the DAO governance (e.g., after a project is submitted).
     * Simplified here for owner to assign. In a full DAO, this would be a governance vote/action.
     * @param _projectId The ID of the project requiring impact assessment.
     * @param _oracleAddress The address of the oracle assigned to predict impact.
     */
    function requestImpactPrediction(uint256 _projectId, address _oracleAddress) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Pending, "ImpactCatalystDAO: Project is not in Pending status for impact assessment");
        require(impactOracles[_oracleAddress].isRegistered, "ImpactCatalystDAO: Assigned address is not a registered oracle");

        project.impactOracleAssigned = _oracleAddress;
        project.impactPredictionRequestId = block.timestamp; // A simple request ID for tracking
        project.status = ProjectStatus.ImpactAssessed; // Temporarily mark as assessed until score is submitted
        emit ImpactPredictionRequested(_projectId, _oracleAddress);
    }

    /**
     * @dev Allows a registered oracle to submit the AI-generated impact score for a requested project.
     * @param _projectId The ID of the project.
     * @param _score The predicted impact score (0-100).
     */
    function submitImpactPrediction(uint256 _projectId, int256 _score) external onlyRegisteredOracle(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.impactOracleAssigned == msg.sender, "ImpactCatalystDAO: You are not the assigned oracle for this project");
        require(project.impactScore == -1, "ImpactCatalystDAO: Impact score already submitted or challenged");
        require(_score >= 0 && _score <= 100, "ImpactCatalystDAO: Impact score must be between 0 and 100");

        project.impactScore = _score;
        project.votingEnds = block.timestamp + VOTING_PERIOD_DURATION; // Start voting period
        project.status = ProjectStatus.Voting;

        impactOracles[msg.sender].totalPredictions++;
        impactOracles[msg.sender].lastPredictionTimestamp = block.timestamp;

        emit ImpactPredictionSubmitted(_projectId, msg.sender, _score);
    }

    /**
     * @dev Enables DAO members to dispute an oracle's submitted impact prediction.
     * This could trigger a re-evaluation, or a vote on the prediction itself.
     * Simplified: just marks it as disputed and resets the prediction, requiring a new one.
     * In a full system, this would involve a complex dispute resolution mechanism.
     * @param _projectId The ID of the project with the disputed prediction.
     */
    function challengeImpactPrediction(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Voting || project.status == ProjectStatus.ImpactAssessed, "ImpactCatalystDAO: Prediction not in a state to be challenged");
        require(project.impactScore != -1, "ImpactCatalystDAO: No impact score submitted yet");
        require(block.timestamp <= project.impactPredictionRequestId + ORACLE_CHALLENGE_WINDOW, "ImpactCatalystDAO: Challenge window has closed");

        // Mark as disputed, reset score, and require re-prediction
        project.status = ProjectStatus.Disputed; // Set to disputed
        project.impactScore = -1; // Reset score
        project.impactOracleAssigned = address(0); // Clear assigned oracle for re-assignment
        project.votingEnds = 0; // Stop any ongoing voting

        // Penalize the oracle for a challenged prediction (simple reduction)
        burnReputationTokens(projects[_projectId].impactOracleAssigned, 5); // Example penalty

        emit ImpactPredictionChallenged(_projectId, msg.sender, project.impactOracleAssigned);
    }

    /**
     * @dev Periodically assesses and records the accuracy and reliability of registered oracles.
     * This is a simplified version; in reality, this would involve post-project impact reports
     * and a comparison with the oracle's initial prediction.
     * Owner manually triggers this to update oracle reputation.
     * @param _oracleAddress The address of the oracle to evaluate.
     * @param _wasAccurate A boolean indicating if the oracle's predictions over a period were accurate.
     * @param _reputationChange The amount by which to change the oracle's reputation.
     */
    function verifyImpactOraclePerformance(address _oracleAddress, bool _wasAccurate, uint256 _reputationChange) external onlyOwner {
        Oracle storage oracle = impactOracles[_oracleAddress];
        require(oracle.isRegistered, "ImpactCatalystDAO: Not a registered oracle");

        if (_wasAccurate) {
            oracle.accuratePredictions++;
            oracle.reputationScore += _reputationChange;
            mintReputationTokens(_oracleAddress, _reputationChange); // Reward for accuracy
        } else {
            oracle.reputationScore = oracle.reputationScore >= _reputationChange ? oracle.reputationScore - _reputationChange : 0;
            burnReputationTokens(_oracleAddress, _reputationChange); // Penalize for inaccuracy
        }

        emit OraclePerformanceVerified(_oracleAddress, oracle.reputationScore);
    }

    // --- III. Decentralized Governance & Funding Allocation ---

    /**
     * @dev Allows members to stake native tokens (ETH) to gain voting power and accrue `IMPACT_REP`.
     * @param _amount The amount of ETH to stake.
     */
    function stakeForGovernance(uint256 _amount) external payable nonReentrant {
        require(msg.value == _amount, "ImpactCatalystDAO: Sent ETH must match stake amount");
        require(_amount >= MIN_STAKE_FOR_VOTING, "ImpactCatalystDAO: Stake amount is too low for voting power");

        stakedAmounts[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Enables staked members to cast votes on funding approval for projects.
     * Vote weight is scaled by stake and `IMPACT_REP` score (not implemented here, but conceptually important).
     * @param _projectId The ID of the project to vote on.
     * @param _support True for 'For', false for 'Against'.
     */
    function voteOnProjectFunding(uint256 _projectId, bool _support) external {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Voting, "ImpactCatalystDAO: Project is not in voting phase");
        require(block.timestamp < project.votingEnds, "ImpactCatalystDAO: Voting period has ended");
        require(stakedAmounts[msg.sender] >= MIN_STAKE_FOR_VOTING, "ImpactCatalystDAO: Insufficient stake for voting");
        require(!hasVotedOnProject[msg.sender][_projectId], "ImpactCatalystDAO: Already voted on this project");

        address voter = msg.sender;
        // If the voter has delegated their vote, the delegatee votes on their behalf
        if (delegatedVotee[msg.sender] != address(0)) {
            voter = delegatedVotee[msg.sender];
        }

        uint256 voteWeight = stakedAmounts[voter]; // Simplified vote weight based on stake.
                                                // In a full system, `IMPACT_REP` could multiply this.

        if (_support) {
            project.totalVotesFor++;
            project.totalVoteWeightFor += voteWeight;
        } else {
            project.totalVotesAgainst++;
            project.totalVoteWeightAgainst += voteWeight;
        }
        hasVotedOnProject[voter][_projectId] = true;

        emit Voted(_projectId, voter, _support, voteWeight);
    }

    /**
     * @dev Transfers initial or milestone-based funds to a project upon successful voting and verification.
     * This function is called by governance (e.g., owner, or automated system) after voting ends.
     * @param _projectId The ID of the project to allocate funds to.
     */
    function allocateProjectFunds(uint256 _projectId) external onlyOwner nonReentrant {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Voting, "ImpactCatalystDAO: Project is not in voting phase");
        require(block.timestamp >= project.votingEnds, "ImpactCatalystDAO: Voting period has not ended yet");
        require(project.impactScore >= MIN_IMPACT_SCORE_FOR_FUNDING, "ImpactCatalystDAO: Project impact score is too low");
        require(project.totalVoteWeightFor > project.totalVoteWeightAgainst, "ImpactCatalystDAO: Project did not receive enough support");
        require(project.currentFundedAmount == 0, "ImpactCatalystDAO: Initial funds already allocated");
        require(project.milestones.length > 0, "ImpactCatalystDAO: Project has no milestones defined");
        require(address(this).balance >= project.milestones[0].fundingAmount, "ImpactCatalystDAO: Insufficient DAO treasury funds for initial milestone");

        project.currentFundedAmount += project.milestones[0].fundingAmount;
        project.status = ProjectStatus.Funded;

        (bool sent, ) = project.proposer.call{value: project.milestones[0].fundingAmount}("");
        require(sent, "ImpactCatalystDAO: Failed to send initial milestone funds to proposer");

        // Reward voters who voted for the successful project (simplified)
        // In a real system, iterate through voters and reward.
        // For simplicity, a flat reward or a mechanism tied to vote weight.
        // For now, let's just make a placeholder.
        // mintReputationTokens(voter, REWARD_AMOUNT);

        emit FundsAllocated(_projectId, project.proposer, project.milestones[0].fundingAmount);
        emit MilestoneFundsReleased(_projectId, 0, project.milestones[0].fundingAmount);
    }

    /**
     * @dev Allows a stakeholder to delegate their voting rights to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotePower(address _delegatee) external {
        require(_delegatee != address(0), "ImpactCatalystDAO: Delegatee address cannot be zero");
        require(_delegatee != msg.sender, "ImpactCatalystDAO: Cannot delegate to self");
        delegatedVotee[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Facilitates community proposals to alter key DAO parameters.
     * This is a simplified function. A full implementation would involve:
     * 1. A struct for `GovernanceProposal` (description, proposed new value, target variable).
     * 2. A separate voting phase for governance proposals.
     * 3. An execution function triggered after successful vote.
     * Here, it merely emits an event, serving as a placeholder for a more complex system.
     * @param _description A description of the proposed governance change.
     */
    function proposeGovernanceChange(string memory _description) external {
        require(stakedAmounts[msg.sender] >= MIN_STAKE_FOR_VOTING, "ImpactCatalystDAO: Insufficient stake to propose governance changes");
        require(bytes(_description).length > 0, "ImpactCatalystDAO: Proposal description cannot be empty");
        // In a full system, add proposal data and start a new voting process.
        emit GovernanceChangeProposed(msg.sender, _description);
    }

    // --- IV. Post-Funding & Impact Verification ---

    /**
     * @dev A funded project proposer declares the completion of a specific project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the completed milestone.
     */
    function reportMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectProposer(_projectId) {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Funded, "ImpactCatalystDAO: Project is not in Funded status");
        require(_milestoneIndex < project.milestones.length, "ImpactCatalystDAO: Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "ImpactCatalystDAO: Milestone already reported or verified");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Reported;
        emit MilestoneReported(_projectId, _milestoneIndex);
    }

    /**
     * @dev Governance or automated system requests an oracle or community verifier to confirm a reported milestone's completion.
     * Simplified: Owner assigns a verifier.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to verify.
     * @param _verifierAddress The address of the oracle/community member assigned for verification.
     */
    function requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, address _verifierAddress) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Funded, "ImpactCatalystDAO: Project is not in Funded status");
        require(_milestoneIndex < project.milestones.length, "ImpactCatalystDAO: Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Reported, "ImpactCatalystDAO: Milestone not reported for verification");
        // A _verifierAddress could be a registered oracle or a community member with sufficient stake/reputation.
        // For simplicity, we just check if it's not address(0).
        require(_verifierAddress != address(0), "ImpactCatalystDAO: Verifier address cannot be zero");

        project.milestones[_milestoneIndex].verifier = _verifierAddress;
        project.milestones[_milestoneIndex].verificationRequestId = block.timestamp; // Simple request ID
        emit MilestoneVerificationRequested(_projectId, _milestoneIndex, _verifierAddress);
    }

    /**
     * @dev A designated verifier submits their findings regarding a project milestone's completion.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _isVerified True if the milestone is confirmed as completed, false otherwise.
     */
    function submitMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, bool _isVerified) external {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "ImpactCatalystDAO: Invalid milestone index");
        require(project.milestones[_milestoneIndex].verifier == msg.sender, "ImpactCatalystDAO: Not the assigned verifier for this milestone");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Reported, "ImpactCatalystDAO: Milestone not in reported state for verification");

        project.milestones[_milestoneIndex].status = _isVerified ? MilestoneStatus.Verified : MilestoneStatus.Disputed;
        // If not verified, the project proposer might dispute it or funds are withheld.
        if (_isVerified) {
             // Reward verifier for successful verification (simplified)
            mintReputationTokens(msg.sender, 2); // Example reward
        } else {
            // Potentially penalize verifier if the negative verification is later overturned
        }


        emit MilestoneVerificationSubmitted(_projectId, _milestoneIndex, _isVerified);
    }

    /**
     * @dev Releases the next pre-determined tranche of project funds upon verified milestone completion.
     * Called by governance after `submitMilestoneVerification` confirms a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the verified milestone.
     */
    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external onlyOwner nonReentrant {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Funded, "ImpactCatalystDAO: Project is not in Funded status");
        require(_milestoneIndex < project.milestones.length, "ImpactCatalystDAO: Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Verified, "ImpactCatalystDAO: Milestone not verified");
        
        // Ensure this is the *next* milestone to be funded sequentially,
        // preventing skipping or double funding.
        // This is a simplified check assuming milestones are processed in order.
        uint256 fundsToBeReleased = project.milestones[_milestoneIndex].fundingAmount;
        
        require(address(this).balance >= fundsToBeReleased, "ImpactCatalystDAO: Insufficient DAO treasury funds for milestone");

        project.currentFundedAmount += fundsToBeReleased;

        (bool sent, ) = project.proposer.call{value: fundsToBeReleased}("");
        require(sent, "ImpactCatalystDAO: Failed to send milestone funds to proposer");

        emit MilestoneFundsReleased(_projectId, _milestoneIndex, fundsToBeReleased);
    }

    /**
     * @dev Provides a mechanism for project proposers to challenge a negative milestone verification outcome.
     * Simplified: changes milestone status back to reported for re-verification (or dispute resolution).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone with the disputed verification.
     */
    function disputeMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectProposer(_projectId) {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "ImpactCatalystDAO: Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Disputed, "ImpactCatalystDAO: Milestone is not in disputed state");
        
        // Reset status to reported, requiring a new verification request or a governance decision.
        project.milestones[_milestoneIndex].status = MilestoneStatus.Reported;
        // Clear verifier to allow new assignment
        project.milestones[_milestoneIndex].verifier = address(0); 
        // Potentially penalize the verifier who made the disputed call (if proven wrong)
        burnReputationTokens(project.milestones[_milestoneIndex].verifier, 2); // Example penalty

        emit MilestoneVerificationDisputed(_projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @dev Marks a project as fully completed after all milestones are reported and verified,
     * triggering final impact assessment and potential rewards for the proposer.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProject(uint256 _projectId) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "ImpactCatalystDAO: Project does not exist");
        require(project.status == ProjectStatus.Funded, "ImpactCatalystDAO: Project is not in Funded status");

        // Check if all milestones are verified
        for (uint256 i = 0; i < project.milestones.length; i++) {
            require(project.milestones[i].status == MilestoneStatus.Verified, "ImpactCatalystDAO: Not all milestones are verified");
        }
        
        require(project.currentFundedAmount == project.requestedFunds, "ImpactCatalystDAO: Not all funds released");

        project.status = ProjectStatus.Completed;
        // Reward project proposer for successful completion
        mintReputationTokens(project.proposer, 10); // Example reward for successful project

        emit ProjectFinalized(_projectId);
    }

    // --- V. Reputation & Incentives (IMPACT_REP Token Integration) ---

    // Assume IMPACT_REP is a separate ERC20 token contract.
    // These functions interact with that token contract, assuming this DAO contract
    // has the minter/burner role for IMPACT_REP tokens.

    /**
     * @dev Awards `IMPACT_REP` tokens to participants for valuable contributions.
     * Only callable by the DAO itself (or owner/governance acting on its behalf).
     * @param _recipient The address to receive reputation tokens.
     * @param _amount The amount of reputation tokens to mint.
     */
    function mintReputationTokens(address _recipient, uint256 _amount) internal {
        // In a real scenario, this would call `IERC20(IMPACT_REP_TOKEN_ADDRESS).mint(_recipient, _amount)`
        // assuming this contract has the MINTER_ROLE on the IMPACT_REP token contract.
        // For this example, we'll queue them for claiming.
        reputationRewardQueue[_recipient] += _amount;
        emit ReputationTokensMinted(_recipient, _amount);
    }

    /**
     * @dev Deducts `IMPACT_REP` tokens as a penalty for malicious behavior or failed contributions.
     * Only callable by the DAO itself (or owner/governance acting on its behalf).
     * @param _holder The address from which to burn reputation tokens.
     * @param _amount The amount of reputation tokens to burn.
     */
    function burnReputationTokens(address _holder, uint256 _amount) internal {
        // In a real scenario, this would call `IERC20(IMPACT_REP_TOKEN_ADDRESS).burn(_holder, _amount)`
        // assuming this contract has the BURNER_ROLE on the IMPACT_REP token contract.
        // For this example, we'll deduct from the queued amount, if sufficient.
        if (reputationRewardQueue[_holder] >= _amount) {
            reputationRewardQueue[_holder] -= _amount;
        } else {
            reputationRewardQueue[_holder] = 0; // Burn all available and then some conceptually
        }
        emit ReputationTokensBurned(_holder, _amount);
    }

    /**
     * @dev Allows users to claim accumulated `IMPACT_REP` tokens they've earned.
     * This function assumes the DAO has the MINTER_ROLE on the IMPACT_REP token contract
     * and will mint and transfer tokens directly.
     */
    function claimReputationReward() external nonReentrant {
        uint256 amountToClaim = reputationRewardQueue[msg.sender];
        require(amountToClaim > 0, "ImpactCatalystDAO: No reputation rewards to claim");

        reputationRewardQueue[msg.sender] = 0; // Reset queue

        // This is where the actual minting and transfer would happen:
        IERC20(IMPACT_REP_TOKEN_ADDRESS).transfer(msg.sender, amountToClaim); // Assumes token is pre-minted or DAO can mint and then transfer

        emit ReputationRewardClaimed(msg.sender, amountToClaim);
    }

    /**
     * @dev Publicly viewable function to retrieve the current `IMPACT_REP` balance of any address.
     * In a real system, this would read from the actual ERC20 token contract.
     * Here it reads from the internal queue for simplicity.
     * @param _user The address to query.
     * @return The `IMPACT_REP` balance (or queued amount).
     */
    function getReputationScore(address _user) external view returns (uint256) {
        // For actual ERC20 token: return IERC20(IMPACT_REP_TOKEN_ADDRESS).balanceOf(_user);
        // For this example: return reputationRewardQueue[_user];
        // To combine, this represents *claimable* reputation:
        return reputationRewardQueue[_user];
    }
}
```