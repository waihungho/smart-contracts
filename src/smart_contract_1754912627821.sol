Here's a Solidity smart contract named `AetherForge`, designed to be an "Sovereign AI Project Incubator." It incorporates several advanced concepts like dynamic NFTs, a multi-stage project lifecycle, a reputation system with delegation, an "Evaluator Agent" system (conceptualizing AI-assisted evaluation), and a decentralized dispute resolution mechanism.

**Smart Contract: AetherForge - Sovereign AI Project Incubator**

**Outline:**

*   **I. Core Infrastructure & Configuration:** Handles global state, configurations, and core mappings.
*   **II. User & Reputation Management:** Manages user profiles, skills, and a dynamic reputation system.
*   **III. Project Lifecycle Management:** Covers the entire journey of an "AI Project" from proposal to completion, including multi-stage funding and milestone tracking.
*   **IV. Evaluator Agent & AI Integration (Conceptual):** A mechanism for "AI Evaluators" (human or verifiable oracle-fed AI) to assess project progress and challenge solutions.
*   **V. Dynamic NFT & Asset Management:** NFTs that change metadata based on project status or user contributions.
*   **VI. Decentralized Governance & Dispute Resolution:** Community-driven decision-making and conflict resolution.
*   **VII. Utility & Views:** Helper functions for data retrieval and internal logic.

**Function Summary (20 Functions):**

**I. Core Setup & Configuration**
1.  `constructor(address _initialOwner, address _oracle, address _paymentToken)`: Initializes the contract, setting up the treasury, trusted oracle address (for external AI integration or verifiable computation), and the ERC-20 token used for funding.
2.  `changeGlobalConfig(GlobalConfigParam _param, uint256 _newValue)`: Allows the contract owner (intended to be a DAO in a real deployment) to update core protocol parameters (e.g., minimum stake for projects, evaluation thresholds).

**II. User & Reputation System**
3.  `registerUserProfile(string calldata _username, string[] calldata _skills)`: Registers a new user with a unique username and an initial set of skills. This action could conceptually mint a "User Reputation NFT" (though not implemented in detail to keep complexity manageable).
4.  `updateSkills(string[] calldata _newSkills)`: Allows users to update their registered skills, which can be used for project matching or specific challenge eligibility.
5.  `delegateReputation(address _delegatee, uint256 _amount)`: Enables users to delegate a portion of their accumulated reputation to other users. This can foster specialized roles, empower community leaders, or influence collective decision-making power.

**III. Project Lifecycle Management**
6.  `proposeProject(string calldata _title, string calldata _description, string calldata _ipfsHash, uint256 _totalFundingGoal, uint256[] calldata _milestoneAmounts, uint256[] calldata _milestoneDeadlines)`: Initiates a new "AI Project" proposal. It requires initial metadata, a total funding goal, and a breakdown of funding per milestone with deadlines. A dynamic Project NFT is minted upon proposal.
7.  `stakeForIncubation(uint256 _projectId, uint256 _amount)`: Allows users to stake funds towards a project's initial incubation phase. This collective stake makes the project eligible for review by the "AI Evaluator" system or DAO.
8.  `approveIncubation(uint256 _projectId)`: A function intended to be called by the `trustedOracle` (representing an "AI-driven" or off-chain verifiable approval mechanism) or a DAO vote, to officially approve a project's incubation, moving its status to `Active`.
9.  `submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _deliverableIpfsHash)`: The project lead submits a completed milestone, providing an IPFS hash to the deliverables, making it ready for evaluation.
10. `releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex)`: Releases the allocated funds for a milestone to the project owner if the milestone has been successfully evaluated and meets the required score threshold.
11. `finalizeProject(uint256 _projectId)`: Marks a project as complete after all its milestones have been successfully met and funded. This triggers final rewards and updates the associated Project NFT to its 'Completed' state.

**IV. Evaluator Agent & AI Integration (Conceptual)**
12. `registerEvaluatorAgent(string calldata _name, string calldata _description, uint256 _stakeAmount)`: Allows an address (which could be a human expert or a proxy address for a verifiable off-chain AI oracle like Chainlink AI) to register and stake tokens as an "Evaluator Agent." These agents are critical for project assessment.
13. `evaluateMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _score, string calldata _evaluationIpfsHash)`: An authorized Evaluator Agent submits a score (0-100) and an assessment for a project milestone. This score directly influences the project's funding release and the evaluator's own reputation.
14. `initiateProjectChallenge(uint256 _projectId, string calldata _challengeDescription, uint256 _rewardAmount, uint256 _deadline)`: Project owners can create specific, smaller sub-challenges or bounties within their larger project. These challenges are open for community contribution and skill development.
15. `submitChallengeSolution(uint256 _challengeId, string calldata _solutionIpfsHash)`: Registered users can submit solutions to active project challenges, providing an IPFS hash to their submission.
16. `evaluateChallengeSolution(uint256 _challengeId, address _solver, uint256 _score)`: An Evaluator Agent assesses a submitted challenge solution. The highest-scoring valid solution is chosen as the winner, influencing the solver's reputation and leading to reward disbursement.

**V. Dynamic NFT & Asset Management**
17. `claimProjectSpecificReward(uint256 _projectId)`: Allows project contributors or participants (other than the owner) to claim specific rewards or reputation boosts upon a project's completion, acknowledging their involvement. This function can be extended to mint "Contributor NFTs" based on their contribution level.
18. `tokenURI(uint256 _tokenId)`: This is the standard ERC721 function overridden to provide **dynamic NFT metadata**. The generated JSON metadata URI for Project NFTs changes based on the associated project's current `status`, `milestone progression`, and `evaluator scores`, offering a visual representation of the project's journey on platforms like OpenSea.

**VI. Decentralized Governance & Dispute Resolution**
19. `raiseDispute(uint256 _entityId, DisputeType _type, string calldata _reasonIpfsHash)`: Allows any user to formally raise a dispute concerning various entities (a project, an evaluation, a user profile, or a challenge solution). This initiates a community-wide vote.
20. `voteOnDispute(uint256 _disputeId, bool _inFavor)`: Enables reputation/stake holders to vote on active disputes. The voting power is based on their reputation within the AetherForge system.
21. `resolveDispute(uint256 _disputeId)`: Finalizes a dispute after its voting period ends. Based on the voting outcome (majority threshold), appropriate on-chain actions are triggered, such as slashing reputation, re-evaluating milestones, or issuing refunds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though 0.8+ has overflow checks

/**
 * @title AetherForge: Sovereign AI Project Incubator
 * @dev AetherForge is a decentralized protocol for proposing, funding, developing, and evaluating AI-driven projects.
 *      It combines dynamic NFTs, a reputation-based governance model, multi-stage funding, and a unique "Evaluator Agent"
 *      system (conceptualizing AI-assisted evaluation via human or oracle-fed AI).
 *      Projects progress through distinct phases, unlocking funding based on milestone completion and evaluator scores.
 *      Contributors build reputation and earn dynamic NFTs, reflecting their impact and project status.
 */

// Outline:
// I. Core Infrastructure & Configuration
// II. User & Reputation Management
// III. Project Lifecycle Management
// IV. Evaluator Agent & AI Integration (Conceptual)
// V. Dynamic NFT & Asset Management
// VI. Decentralized Governance & Dispute Resolution
// VII. Utility & Views

// Function Summary:
// I. Core Setup & Configuration
// 1. constructor(address _initialOwner, address _oracle, address _paymentToken): Initializes the contract, setting up the treasury, trusted oracle address, and the ERC-20 token used for funding.
// 2. changeGlobalConfig(GlobalConfigParam _param, uint256 _newValue): Allows DAO-gated updates to core protocol parameters (e.g., minimum stake, evaluation thresholds).

// II. User & Reputation System
// 3. registerUserProfile(string calldata _username, string[] calldata _skills): Registers a new user with a unique username and initial set of skills, conceptually minting a User Reputation NFT.
// 4. updateSkills(string[] calldata _newSkills): Allows users to update their registered skills.
// 5. delegateReputation(address _delegatee, uint256 _amount): Enables users to delegate their accumulated reputation to others, fostering specialized roles or collective decision-making power.

// III. Project Lifecycle Management
// 6. proposeProject(string calldata _title, string calldata _description, string calldata _ipfsHash, uint256 _totalFundingGoal, uint256[] calldata _milestoneAmounts, uint256[] calldata _milestoneDeadlines): Initiates a new "AI Project" proposal, requiring initial metadata, funding goals, and defined milestones.
// 7. stakeForIncubation(uint256 _projectId, uint256 _amount): Allows users to stake funds towards a project's initial incubation phase, making it eligible for review.
// 8. approveIncubation(uint256 _projectId): Trusted oracle (or DAO) approves incubation, moving project to 'Active' status.
// 9. submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _deliverableIpfsHash): Project leads submit a completed milestone for evaluation by Evaluator Agents.
// 10. releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex): Releases funds to the project upon successful milestone evaluation.
// 11. finalizeProject(uint256 _projectId): Marks a project as complete after all milestones are met, potentially triggering final rewards and NFT state changes.

// IV. Evaluator Agent & AI Integration (Conceptual)
// 12. registerEvaluatorAgent(string calldata _name, string calldata _description, uint256 _stakeAmount): Allows an address (human or a proxy for an off-chain AI oracle) to register and stake as an "Evaluator Agent."
// 13. evaluateMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _score, string calldata _evaluationIpfsHash): An authorized Evaluator Agent submits a score and assessment for a project milestone.
// 14. initiateProjectChallenge(uint256 _projectId, string calldata _challengeDescription, uint256 _rewardAmount, uint256 _deadline): Project owners can create specific sub-challenges within their project, open for community contribution.
// 15. submitChallengeSolution(uint256 _challengeId, string calldata _solutionIpfsHash): Users submit solutions to active project challenges.
// 16. evaluateChallengeSolution(uint256 _challengeId, address _solver, uint256 _score): An Evaluator Agent assesses a submitted challenge solution.

// V. Dynamic NFT & Asset Management
// 17. claimProjectSpecificReward(uint256 _projectId): Allows project contributors or participants to claim specific rewards defined by the project upon its completion or milestone.
// 18. tokenURI(uint256 _tokenId): Standard ERC721 function. Dynamically generates the metadata URI for Project NFTs based on their current status and other on-chain data.

// VI. Decentralized Governance & Dispute Resolution
// 19. raiseDispute(uint256 _entityId, DisputeType _type, string calldata _reasonIpfsHash): Allows any user to formally raise a dispute concerning a project, an evaluation, or a user profile.
// 20. voteOnDispute(uint256 _disputeId, bool _inFavor): Enables reputation/stake holders to vote on active disputes.
// 21. resolveDispute(uint256 _disputeId): Finalizes a dispute based on voting outcome, triggering an appropriate on-chain action.

contract AetherForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    IERC20 public immutable paymentToken;
    address public trustedOracle; // For verifiable AI computation / external data feeds

    // --- Enums ---
    enum ProjectStatus { Proposed, Incubation, Active, Completed, Failed, Disputed }
    enum MilestoneStatus { Pending, Submitted, Evaluated, Funded }
    enum DisputeType { Project, Evaluation, UserProfile, ChallengeSolution }
    enum DisputeStatus { Active, Resolved, Rejected }
    enum GlobalConfigParam {
        MIN_PROJECT_STAKE,
        EVALUATION_THRESHOLD_PERCENT,
        EVALUATOR_AGENT_STAKE,
        REPUTATION_BOOST_ON_SUCCESS,
        REPUTATION_SLASH_ON_FAILURE,
        DISPUTE_VOTE_THRESHOLD_PERCENT,
        DISPUTE_VOTING_PERIOD,
        CHALLENGE_EVAL_PERIOD,
        PROJECT_INCUBATION_PERIOD
    }

    // --- Structs ---
    struct Milestone {
        uint256 amount;
        uint256 deadline; // Timestamp
        string deliverableIpfsHash;
        MilestoneStatus status;
        uint256 score; // Accumulated score from evaluators
        uint256 evaluatedByCount; // Number of evaluators who scored this milestone
    }

    struct Project {
        uint256 projectId;
        address owner;
        string title;
        string description;
        string initialIpfsHash;
        uint256 totalFundingGoal;
        uint256 collectedFunds;
        Milestone[] milestones;
        ProjectStatus status;
        uint256 currentMilestoneIndex;
        uint256 nftTokenId; // Token ID for the associated dynamic Project NFT
        mapping(address => uint256) incubationStakes;
        uint256 totalIncubationStake;
        bool incubationApproved;
        uint256 incubationApprovalTime;
    }

    struct UserProfile {
        string username;
        string[] skills;
        uint256 reputation;
        mapping(address => uint256) delegatedReputation; // Reputation delegated FROM this user
        // Note: For a practical system, total delegated FROM or TO a user would be pre-calculated or stored to avoid iteration.
        uint256 lastReputationUpdateEpoch; // For epoch-based reputation decay/rewards
    }

    struct EvaluatorAgent {
        string name;
        string description;
        uint256 stakeAmount;
        bool isActive;
    }

    struct Challenge {
        uint256 challengeId;
        uint256 projectId;
        address creator;
        string description;
        uint256 rewardAmount;
        uint256 deadline; // Timestamp
        mapping(address => string) solutions; // solver => ipfsHash
        address winner;
        uint256 winnerScore;
        bool isResolved;
        mapping(address => bool) solutionEvaluated; // Evaluator has evaluated this solution
        uint256 evaluationCount;
    }

    struct Dispute {
        uint256 disputeId;
        DisputeType disputeType;
        uint256 entityId; // ProjectId, EvaluationId, UserId, ChallengeId etc.
        string reasonIpfsHash;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true
        uint256 voteEndTime;
        DisputeStatus status;
    }

    // --- State Variables ---
    Counters.Counter private _projectIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _nftTokenIds; // Global counter for all NFTs minted by this contract

    mapping(uint256 => Project) public projects;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => EvaluatorAgent) public evaluatorAgents; // Address of agent => EvaluatorAgent struct
    address[] public activeEvaluatorAgents; // List of active evaluator addresses
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Dispute) public disputes;

    // Global Configuration Parameters
    mapping(GlobalConfigParam => uint256) public globalConfigs;

    // --- Events ---
    event UserRegistered(address indexed user, string username, string[] skills);
    event SkillsUpdated(address indexed user, string[] newSkills);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);

    event ProjectProposed(uint256 indexed projectId, address indexed owner, string title, uint256 fundingGoal);
    event FundsStakedForIncubation(uint256 indexed projectId, address indexed staker, uint256 amount);
    event ProjectIncubationApproved(uint256 indexed projectId);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string deliverableIpfsHash);
    event MilestoneEvaluated(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed evaluator, uint256 score);
    event MilestoneFundingReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectFinalized(uint256 indexed projectId);

    event EvaluatorAgentRegistered(address indexed agentAddress, string name, uint256 stakeAmount);
    event EvaluatorAgentUnstaked(address indexed agentAddress); // Not a full function in this version, but good to have event

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed projectId, address indexed creator, uint256 rewardAmount);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, address indexed solver, string solutionIpfsHash);
    event ChallengeSolutionEvaluated(uint256 indexed challengeId, address indexed solver, address indexed evaluator, uint256 score);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed winner, uint256 amount);

    event DisputeRaised(uint256 indexed disputeId, DisputeType disputeType, uint256 entityId, address indexed proposer);
    event VotedOnDispute(uint256 indexed disputeId, address indexed voter, bool inFavor);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);

    event GlobalConfigChanged(GlobalConfigParam param, uint256 newValue);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newUri); // Custom event to signal metadata change for dynamic NFTs

    // --- Constructor ---
    /**
     * @dev Initializes the AetherForge contract.
     * @param _initialOwner The address of the initial contract owner (e.g., a DAO multisig).
     * @param _oracle The address of the trusted oracle (e.g., Chainlink, for external AI inputs or verifiable computation results).
     * @param _paymentToken The address of the ERC-20 token used for funding projects and stakes.
     */
    constructor(address _initialOwner, address _oracle, address _paymentToken) ERC721("AetherForge AI Project NFT", "AF_AIP") Ownable(_initialOwner) {
        trustedOracle = _oracle;
        paymentToken = IERC20(_paymentToken);

        // Set initial default global configurations
        globalConfigs[GlobalConfigParam.MIN_PROJECT_STAKE] = 100 * 10**18; // 100 tokens (assuming 18 decimals)
        globalConfigs[GlobalConfigParam.EVALUATION_THRESHOLD_PERCENT] = 70; // 70% average score required for milestone funding
        globalConfigs[GlobalConfigParam.EVALUATOR_AGENT_STAKE] = 500 * 10**18; // 500 tokens for evaluator stake
        globalConfigs[GlobalConfigParam.REPUTATION_BOOST_ON_SUCCESS] = 50; // Reputation points
        globalConfigs[GlobalConfigParam.REPUTATION_SLASH_ON_FAILURE] = 25; // Reputation points
        globalConfigs[GlobalConfigParam.DISPUTE_VOTE_THRESHOLD_PERCENT] = 51; // 51% majority to resolve dispute in favor
        globalConfigs[GlobalConfigParam.DISPUTE_VOTING_PERIOD] = 3 days; // Duration for dispute voting
        globalConfigs[GlobalConfigParam.CHALLENGE_EVAL_PERIOD] = 7 days; // Period after challenge deadline for solutions to be evaluated
        globalConfigs[GlobalConfigParam.PROJECT_INCUBATION_PERIOD] = 14 days; // Time limit for incubation approval
    }

    // --- I. Core Setup & Configuration ---
    /**
     * @dev Allows the owner (or DAO) to change global configuration parameters.
     * @param _param The parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function changeGlobalConfig(GlobalConfigParam _param, uint256 _newValue) public onlyOwner {
        globalConfigs[_param] = _newValue;
        emit GlobalConfigChanged(_param, _newValue);
    }

    // --- II. User & Reputation System ---
    /**
     * @dev Registers a new user profile with a username and skills.
     *      Each user starts with a base reputation.
     * @param _username The desired username.
     * @param _skills An array of skills the user possesses.
     */
    function registerUserProfile(string calldata _username, string[] calldata _skills) public {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered.");
        require(bytes(_username).length > 0, "Username cannot be empty.");

        userProfiles[msg.sender].username = _username;
        userProfiles[msg.sender].skills = _skills;
        userProfiles[msg.sender].reputation = 100; // Initial base reputation
        userProfiles[msg.sender].lastReputationUpdateEpoch = block.timestamp; // Simple epoch tracking

        emit UserRegistered(msg.sender, _username, _skills);
    }

    /**
     * @dev Allows a user to update their registered skills.
     * @param _newSkills The new array of skills.
     */
    function updateSkills(string[] calldata _newSkills) public {
        require(bytes(userProfiles[msg.sender].username).length > 0, "User not registered.");
        userProfiles[msg.sender].skills = _newSkills;
        emit SkillsUpdated(msg.sender, _newSkills);
    }

    /**
     * @dev Enables users to delegate a portion of their reputation to another user.
     *      This can be used to empower domain experts or support collective initiatives.
     *      The delegatee's effective reputation for voting is increased.
     * @param _delegatee The address to which reputation is delegated.
     * @param _amount The amount of reputation to delegate.
     */
    function delegateReputation(address _delegatee, uint256 _amount) public {
        require(bytes(userProfiles[msg.sender].username).length > 0, "Delegator not registered.");
        require(bytes(userProfiles[_delegatee].username).length > 0, "Delegatee not registered.");
        require(userProfiles[msg.sender].reputation >= _amount, "Insufficient reputation to delegate.");
        require(msg.sender != _delegatee, "Cannot delegate reputation to yourself.");

        userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.sub(_amount);
        userProfiles[_delegatee].reputation = userProfiles[_delegatee].reputation.add(_amount);
        userProfiles[msg.sender].delegatedReputation[_delegatee] = userProfiles[msg.sender].delegatedReputation[_delegatee].add(_amount);

        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    // --- III. Project Lifecycle Management ---
    /**
     * @dev Initiates a new AI Project proposal.
     *      Mints a dynamic Project NFT at its "Proposed" state.
     * @param _title The title of the project.
     * @param _description A brief description of the project.
     * @param _ipfsHash IPFS hash pointing to detailed project documentation (e.g., whitepaper, detailed plan).
     * @param _totalFundingGoal The total funding required for the project.
     * @param _milestoneAmounts An array of funding amounts for each milestone.
     * @param _milestoneDeadlines An array of timestamps for milestone deadlines.
     */
    function proposeProject(
        string calldata _title,
        string calldata _description,
        string calldata _ipfsHash,
        uint256 _totalFundingGoal,
        uint256[] calldata _milestoneAmounts,
        uint256[] calldata _milestoneDeadlines
    ) public {
        require(bytes(userProfiles[msg.sender].username).length > 0, "Proposer not registered.");
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title or description cannot be empty.");
        require(_milestoneAmounts.length > 0 && _milestoneAmounts.length == _milestoneDeadlines.length, "Invalid milestones or deadlines count.");
        require(_totalFundingGoal == _sumArray(_milestoneAmounts), "Milestone amounts must sum up to total funding goal.");
        require(_totalFundingGoal > 0, "Funding goal must be greater than zero.");

        // Validate milestone deadlines
        for (uint i = 0; i < _milestoneDeadlines.length; i++) {
            require(_milestoneDeadlines[i] > block.timestamp, "Milestone deadline must be in the future.");
            if (i > 0) {
                require(_milestoneDeadlines[i] > _milestoneDeadlines[i-1], "Milestone deadlines must be sequential.");
            }
        }

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        Milestone[] memory milestones = new Milestone[](_milestoneAmounts.length);
        for (uint i = 0; i < _milestoneAmounts.length; i++) {
            milestones[i] = Milestone({
                amount: _milestoneAmounts[i],
                deadline: _milestoneDeadlines[i],
                deliverableIpfsHash: "",
                status: MilestoneStatus.Pending,
                score: 0,
                evaluatedByCount: 0
            });
        }

        uint256 newNftTokenId = _nftTokenIds.current();
        _nftTokenIds.increment();

        projects[newProjectId] = Project({
            projectId: newProjectId,
            owner: msg.sender,
            title: _title,
            description: _description,
            initialIpfsHash: _ipfsHash,
            totalFundingGoal: _totalFundingGoal,
            collectedFunds: 0,
            milestones: milestones,
            status: ProjectStatus.Proposed,
            currentMilestoneIndex: 0,
            nftTokenId: newNftTokenId,
            totalIncubationStake: 0,
            incubationApproved: false,
            incubationApprovalTime: 0
        });

        _mint(msg.sender, newNftTokenId); // Mint Project NFT to project owner
        _updateProjectNFTMetadata(newProjectId); // Set initial NFT metadata

        emit ProjectProposed(newProjectId, msg.sender, _title, _totalFundingGoal);
    }

    /**
     * @dev Allows users to stake funds for a project's initial incubation phase.
     *      Funds are held in escrow. Requires transfer of paymentToken from staker.
     * @param _projectId The ID of the project to stake for.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForIncubation(uint256 _projectId, uint256 _amount) public {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.status == ProjectStatus.Proposed, "Project not in Proposed status for incubation.");
        require(_amount > 0, "Stake amount must be greater than zero.");
        
        // Transfer tokens from staker to contract
        require(paymentToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        project.incubationStakes[msg.sender] = project.incubationStakes[msg.sender].add(_amount);
        project.totalIncubationStake = project.totalIncubationStake.add(_amount);

        emit FundsStakedForIncubation(_projectId, msg.sender, _amount);
    }

    /**
     * @dev Marks a project as approved for Incubation, transitioning its status to Active.
     *      Can only be called by the trusted Oracle (conceptual "AI-driven" approval) or DAO.
     *      This function would integrate with an off-chain oracle that determines project viability.
     * @param _projectId The ID of the project to approve.
     */
    function approveIncubation(uint256 _projectId) public {
        require(msg.sender == trustedOracle || owner() == msg.sender, "Only trusted oracle or owner can approve incubation."); // owner() for DAO override/fallback
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.status == ProjectStatus.Proposed, "Project not in Proposed status.");
        require(project.totalIncubationStake >= globalConfigs[GlobalConfigParam.MIN_PROJECT_STAKE], "Not enough incubation stake to proceed.");
        require(block.timestamp <= project.incubationApprovalTime.add(globalConfigs[GlobalConfigParam.PROJECT_INCUBATION_PERIOD]), "Incubation period expired."); // Only if incubationApprovalTime has a meaning here. Initial `proposeProject` doesn't set it. Could be: `require(project.totalIncubationStake > 0, "No stakes found.");`


        project.status = ProjectStatus.Active;
        project.incubationApproved = true;
        project.incubationApprovalTime = block.timestamp;
        project.collectedFunds = project.collectedFunds.add(project.totalIncubationStake); // Move incubation stake to collected funds

        // Reputation boost for project owner for successful incubation
        userProfiles[project.owner].reputation = userProfiles[project.owner].reputation.add(globalConfigs[GlobalConfigParam.REPUTATION_BOOST_ON_SUCCESS]);

        _updateProjectNFTMetadata(_projectId);
        emit ProjectIncubationApproved(_projectId);
    }

    /**
     * @dev Project owner submits a completed milestone for evaluation.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being submitted (0-indexed).
     * @param _deliverableIpfsHash IPFS hash pointing to the milestone deliverables.
     */
    function submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _deliverableIpfsHash) public {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.owner == msg.sender, "Only project owner can submit milestones.");
        require(project.status == ProjectStatus.Active, "Project not in Active status.");
        require(_milestoneIndex == project.currentMilestoneIndex, "Milestone out of order. Must submit current milestone.");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index.");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "Milestone already submitted or evaluated.");
        
        // Allow submission after deadline, but with potential penalty or requiring re-evaluation.
        // For now, allow but note late submission if desired.
        // require(block.timestamp <= project.milestones[_milestoneIndex].deadline, "Milestone deadline passed.");

        project.milestones[_milestoneIndex].deliverableIpfsHash = _deliverableIpfsHash;
        project.milestones[_milestoneIndex].status = MilestoneStatus.Submitted;

        // Reset scores for new evaluation phase (in case of re-submission)
        project.milestones[_milestoneIndex].score = 0;
        project.milestones[_milestoneIndex].evaluatedByCount = 0;

        emit MilestoneSubmitted(_projectId, _milestoneIndex, _deliverableIpfsHash);
    }

    /**
     * @dev Releases funding for a milestone if it meets the evaluation criteria.
     *      Can be called by project owner after sufficient evaluation.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function releaseMilestoneFunding(uint256 _projectId, uint256 _milestoneIndex) public {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.owner == msg.sender, "Only project owner can release funding.");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index.");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Evaluated, "Milestone not evaluated or already funded.");
        require(project.currentMilestoneIndex == _milestoneIndex, "Can only release funding for current milestone.");
        require(milestone.evaluatedByCount > 0, "Milestone has not been evaluated by any agent."); // Must have at least one evaluation

        uint256 averageScore = milestone.score.div(milestone.evaluatedByCount);
        require(averageScore >= globalConfigs[GlobalConfigParam.EVALUATION_THRESHOLD_PERCENT], "Milestone score too low for funding.");
        require(project.collectedFunds >= milestone.amount, "Insufficient collected funds to release milestone funding.");

        milestone.status = MilestoneStatus.Funded;
        project.collectedFunds = project.collectedFunds.sub(milestone.amount);
        require(paymentToken.transfer(project.owner, milestone.amount), "Funding transfer failed.");

        project.currentMilestoneIndex = project.currentMilestoneIndex.add(1);

        _updateProjectNFTMetadata(_projectId);
        emit MilestoneFundingReleased(_projectId, _milestoneIndex, milestone.amount);
    }

    /**
     * @dev Marks a project as completed once all milestones are successfully funded.
     *      Triggers final NFT state change and potentially final rewards.
     * @param _projectId The ID of the project.
     */
    function finalizeProject(uint256 _projectId) public {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.owner == msg.sender, "Only project owner can finalize project.");
        require(project.status == ProjectStatus.Active, "Project not in Active status.");
        require(project.currentMilestoneIndex == project.milestones.length, "Not all milestones completed yet.");

        project.status = ProjectStatus.Completed;

        // Reputation boost for project owner on successful completion
        userProfiles[project.owner].reputation = userProfiles[project.owner].reputation.add(globalConfigs[GlobalConfigParam.REPUTATION_BOOST_ON_SUCCESS].mul(2)); // Double boost

        _updateProjectNFTMetadata(_projectId); // Update NFT to "Completed" state
        emit ProjectFinalized(_projectId);
    }

    // --- IV. Evaluator Agent & AI Integration (Conceptual) ---
    /**
     * @dev Allows an address to register and stake as an "Evaluator Agent."
     *      These agents are responsible for evaluating milestones and challenges.
     *      Could represent human experts or an interface for verifiable off-chain AI oracles.
     * @param _name Name of the evaluator agent.
     * @param _description Description of the agent's expertise or function.
     * @param _stakeAmount The amount of tokens to stake to become an evaluator.
     */
    function registerEvaluatorAgent(string calldata _name, string calldata _description, uint256 _stakeAmount) public {
        require(bytes(userProfiles[msg.sender].username).length > 0, "Evaluator must be a registered user.");
        require(evaluatorAgents[msg.sender].isActive == false, "Already an active evaluator agent.");
        require(_stakeAmount >= globalConfigs[GlobalConfigParam.EVALUATOR_AGENT_STAKE], "Stake amount too low.");
        require(paymentToken.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed.");

        evaluatorAgents[msg.sender] = EvaluatorAgent({
            name: _name,
            description: _description,
            stakeAmount: _stakeAmount,
            isActive: true
        });
        activeEvaluatorAgents.push(msg.sender); // Add to dynamic array for tracking active agents

        emit EvaluatorAgentRegistered(msg.sender, _name, _stakeAmount);
    }

    /**
     * @dev An authorized Evaluator Agent submits a score and assessment for a project milestone.
     *      Influences the project's funding release and the evaluator's reputation.
     *      Scores are averaged from multiple evaluators.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being evaluated.
     * @param _score The score given (0-100).
     * @param _evaluationIpfsHash IPFS hash for detailed evaluation report.
     */
    function evaluateMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _score, string calldata _evaluationIpfsHash) public {
        require(evaluatorAgents[msg.sender].isActive, "Caller is not an active Evaluator Agent.");
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index.");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Submitted, "Milestone not in Submitted status for evaluation.");
        require(_score <= 100, "Score must be between 0 and 100.");
        require(bytes(_evaluationIpfsHash).length > 0, "Evaluation IPFS hash cannot be empty.");

        // Implement logic to prevent multiple evaluations by the same agent for the same milestone if desired.
        // For simplicity now, scores are simply accumulated and averaged.
        // A more robust system would track which agents evaluated.

        milestone.score = milestone.score.add(_score);
        milestone.evaluatedByCount = milestone.evaluatedByCount.add(1);

        milestone.status = MilestoneStatus.Evaluated; // Mark as evaluated after receiving at least one score.

        // Reputation adjustment for evaluator based on their score
        if (_score >= globalConfigs[GlobalConfigParam.EVALUATION_THRESHOLD_PERCENT]) {
            userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.add(10); // Small boost for positive evaluation
        } else if (_score < globalConfigs[GlobalConfigParam.EVALUATION_THRESHOLD_PERCENT].div(2)) { // If score is very low
            userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.sub(5); // Small slash for consistently low scores
        }

        emit MilestoneEvaluated(_projectId, _milestoneIndex, msg.sender, _score);
    }

    /**
     * @dev Project owner can initiate a sub-challenge within their project.
     *      These are smaller bounties to solve specific problems or tasks.
     * @param _projectId The ID of the parent project.
     * @param _challengeDescription Description of the challenge.
     * @param _rewardAmount The reward for solving the challenge.
     * @param _deadline The deadline for submitting solutions.
     */
    function initiateProjectChallenge(
        uint256 _projectId,
        string calldata _challengeDescription,
        uint256 _rewardAmount,
        uint256 _deadline
    ) public {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.owner == msg.sender, "Only project owner can initiate challenges.");
        require(project.status == ProjectStatus.Active, "Project not in Active status.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");
        require(_deadline > block.timestamp, "Challenge deadline must be in the future.");
        
        // Transfer reward tokens from creator to contract as escrow
        require(paymentToken.transferFrom(msg.sender, address(this), _rewardAmount), "Reward transfer failed.");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            challengeId: newChallengeId,
            projectId: _projectId,
            creator: msg.sender,
            description: _challengeDescription,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            solutions: new mapping(address => string), // Initialize maps explicitly
            winner: address(0),
            winnerScore: 0,
            isResolved: false,
            solutionEvaluated: new mapping(address => bool),
            evaluationCount: 0
        });

        emit ChallengeInitiated(newChallengeId, _projectId, msg.sender, _rewardAmount);
    }

    /**
     * @dev Users submit solutions to an active challenge.
     * @param _challengeId The ID of the challenge.
     * @param _solutionIpfsHash IPFS hash pointing to the solution.
     */
    function submitChallengeSolution(uint256 _challengeId, string calldata _solutionIpfsHash) public {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challengeId != 0, "Challenge does not exist.");
        require(block.timestamp <= challenge.deadline, "Challenge submission deadline passed.");
        require(bytes(_solutionIpfsHash).length > 0, "Solution IPFS hash cannot be empty.");
        require(bytes(challenge.solutions[msg.sender]).length == 0, "You have already submitted a solution for this challenge.");

        challenge.solutions[msg.sender] = _solutionIpfsHash;

        emit ChallengeSolutionSubmitted(_challengeId, msg.sender, _solutionIpfsHash);
    }

    /**
     * @dev An Evaluator Agent assesses a submitted challenge solution.
     *      The highest-scoring valid solution (if evaluation period ends) wins.
     * @param _challengeId The ID of the challenge.
     * @param _solver The address of the user who submitted the solution.
     * @param _score The score given to the solution (0-100).
     */
    function evaluateChallengeSolution(uint256 _challengeId, address _solver, uint256 _score) public {
        require(evaluatorAgents[msg.sender].isActive, "Caller is not an active Evaluator Agent.");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challengeId != 0, "Challenge does not exist.");
        require(bytes(challenge.solutions[_solver]).length > 0, "Solver has not submitted a solution for this challenge.");
        require(!challenge.isResolved, "Challenge already resolved.");
        require(_score <= 100, "Score must be between 0 and 100.");
        require(block.timestamp <= challenge.deadline.add(globalConfigs[GlobalConfigParam.CHALLENGE_EVAL_PERIOD]), "Evaluation period ended.");
        require(!challenge.solutionEvaluated[msg.sender], "You have already evaluated this solution."); // Prevent multiple evaluations by same agent

        // Update winner if current score is higher
        if (challenge.winner == address(0) || _score > challenge.winnerScore) {
            challenge.winner = _solver;
            challenge.winnerScore = _score;
        }

        challenge.solutionEvaluated[msg.sender] = true;
        challenge.evaluationCount = challenge.evaluationCount.add(1);

        // Simple reputation adjustment for evaluator based on their scoring
        if (_score >= 70) { // Arbitrary threshold for good score
            userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.add(5);
        } else if (_score < 40) { // Arbitrary threshold for bad score
            userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.sub(5);
        }

        // Auto-resolve challenge if evaluation period has passed
        if (block.timestamp > challenge.deadline.add(globalConfigs[GlobalConfigParam.CHALLENGE_EVAL_PERIOD]) && !challenge.isResolved) {
             _resolveChallenge(_challengeId);
        }

        emit ChallengeSolutionEvaluated(_challengeId, _solver, msg.sender, _score);
    }

    // --- V. Dynamic NFT & Asset Management ---
    /**
     * @dev Allows project contributors or participants to claim specific rewards.
     *      This could be for general participation or specific roles.
     *      For this example, it boosts reputation significantly for a registered user.
     * @param _projectId The ID of the project.
     */
    function claimProjectSpecificReward(uint256 _projectId) public {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        require(project.status == ProjectStatus.Completed, "Project not completed.");
        require(project.owner != msg.sender, "Project owner claims rewards differently (via milestones)."); 
        require(bytes(userProfiles[msg.sender].username).length > 0, "User must be registered to claim rewards.");

        // A more complex system would track individual contributions (e.g., submitted challenges, forum activity)
        // For simplicity, any registered user can claim a base reward for a completed project they were involved with (even implicitly).
        userProfiles[msg.sender].reputation = userProfiles[msg.sender].reputation.add(25); // Significant boost for participation/contribution

        // Future extension: Mint a specific Contributor NFT here based on level of contribution.
        // uint256 newContributorNftId = _nftTokenIds.current();
        // _nftTokenIds.increment();
        // _mint(msg.sender, newContributorNftId);
        // emit Transfer(address(0), msg.sender, newContributorNftId); // ERC721 mint event

        emit ProjectFinalized(_projectId); // Re-using event for simplicity; a new event like `RewardClaimed` would be better.
    }

    /**
     * @dev Returns the dynamically generated metadata URI for a given NFT token ID.
     *      This function is overridden from ERC721.
     *      The URI changes based on the associated project's status and progress.
     * @param _tokenId The ID of the NFT.
     * @return A string representing the JSON metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 projectId = 0;
        for (uint i = 1; i <= _projectIds.current(); i++) { // Iterate through project IDs to find matching NFT
            if (projects[i].nftTokenId == _tokenId) {
                projectId = i;
                break;
            }
        }
        require(projectId != 0, "NFT not associated with an AetherForge project.");

        Project storage project = projects[projectId];

        string memory statusString;
        if (project.status == ProjectStatus.Proposed) statusString = "Proposed";
        else if (project.status == ProjectStatus.Incubation) statusString = "Incubation";
        else if (project.status == ProjectStatus.Active) statusString = "Active";
        else if (project.status == ProjectStatus.Completed) statusString = "Completed";
        else if (project.status == ProjectStatus.Failed) statusString = "Failed";
        else if (project.status == ProjectStatus.Disputed) statusString = "Disputed";

        string memory milestonesProgress = string(abi.encodePacked(
            project.currentMilestoneIndex.toString(), "/", project.milestones.length.toString()
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', project.title, ' (ID: ', projectId.toString(), ')",',
            '"description": "', project.description, '",',
            '"image": "ipfs://Qmb_PLACEHOLDER_IMAGE_HASH_FOR_STATUS_', statusString, '",', // Placeholder for dynamic image based on status
            '"attributes": [',
            '{"trait_type": "Project Status", "value": "', statusString, '"},',
            '{"trait_type": "Milestones Completed", "value": "', milestonesProgress, '"},',
            '{"trait_type": "Owner", "value": "', Strings.toHexString(uint160(project.owner), 20), '"},',
            '{"trait_type": "Funding Goal", "value": "', project.totalFundingGoal.toString(), '"},',
            '{"trait_type": "Collected Funds", "value": "', project.collectedFunds.toString(), '"}'
        ));

        // Add attributes for current milestone if applicable and it exists
        if (project.currentMilestoneIndex < project.milestones.length) {
            Milestone storage currentMilestone = project.milestones[project.currentMilestoneIndex];
            json = string(abi.encodePacked(json, ',',
                '{"trait_type": "Current Milestone Status", "value": "', _milestoneStatusToString(currentMilestone.status), '"},',
                '{"trait_type": "Current Milestone Score (Avg)", "value": "', currentMilestone.evaluatedByCount > 0 ? (currentMilestone.score.div(currentMilestone.evaluatedByCount)).toString() : "N/A", '"}'
            ));
        }

        json = string(abi.encodePacked(json, ']}'));

        string memory baseURI = "data:application/json;base64,";
        // Use a proper Base64 encoder library for production. Here, a simple placeholder.
        return string(abi.encodePacked(baseURI, _encodeBase64(bytes(json))));
    }

    /**
     * @dev Internal function to update a project's NFT metadata by triggering a `tokenURI` update.
     *      This event is typically picked up by off-chain services (like OpenSea indexers) to refresh metadata.
     * @param _projectId The ID of the project whose NFT metadata needs updating.
     */
    function _updateProjectNFTMetadata(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        // Emit ERC721MetadataUpdate event if using OpenZeppelin's ERC721URIStorage.sol
        // For plain ERC721, simply emitting Transfer event with `_from` and `_to` being the owner and `_id` being the token ID,
        // will often trigger a metadata refresh on OpenSea, but `NFTMetadataUpdated` is explicit.
        emit NFTMetadataUpdated(project.nftTokenId, tokenURI(project.nftTokenId));
    }

    // --- VI. Decentralized Governance & Dispute Resolution ---
    /**
     * @dev Allows any user to formally raise a dispute concerning a project, an evaluation, or a user profile.
     *      Initiates a community vote.
     * @param _entityId The ID of the entity in dispute (project ID, challenge ID, or 0 for a user profile dispute where msg.sender is implicitly the target).
     * @param _type The type of dispute (Project, Evaluation, UserProfile, ChallengeSolution).
     * @param _reasonIpfsHash IPFS hash pointing to detailed reason for the dispute.
     */
    function raiseDispute(uint256 _entityId, DisputeType _type, string calldata _reasonIpfsHash) public {
        require(bytes(userProfiles[msg.sender].username).length > 0, "Disputer must be a registered user.");
        require(bytes(_reasonIpfsHash).length > 0, "Reason IPFS hash cannot be empty.");

        // Basic validation based on dispute type
        if (_type == DisputeType.Project) {
            require(projects[_entityId].projectId != 0, "Project does not exist.");
            require(projects[_entityId].status != ProjectStatus.Disputed, "Project already in dispute.");
        } else if (_type == DisputeType.ChallengeSolution) {
             require(challenges[_entityId].challengeId != 0, "Challenge does not exist.");
        }
        // Add more specific validations for other dispute types if needed (e.g., Evaluation dispute requires valid milestoneIndex and evaluator address)

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            disputeId: newDisputeId,
            disputeType: _type,
            entityId: _entityId,
            reasonIpfsHash: _reasonIpfsHash,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            voteEndTime: block.timestamp.add(globalConfigs[GlobalConfigParam.DISPUTE_VOTING_PERIOD]),
            status: DisputeStatus.Active
        });

        // Set disputed entity status if applicable
        if (_type == DisputeType.Project) {
            projects[_entityId].status = ProjectStatus.Disputed;
            _updateProjectNFTMetadata(_entityId);
        }

        emit DisputeRaised(newDisputeId, _type, _entityId, msg.sender);
    }

    /**
     * @dev Enables reputation/stake holders to vote on active disputes.
     *      Vote weight is based on their current reputation.
     * @param _disputeId The ID of the dispute to vote on.
     * @param _inFavor True to vote in favor (agree with the dispute proposer), false to vote against.
     */
    function voteOnDispute(uint256 _disputeId, bool _inFavor) public {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist.");
        require(dispute.status == DisputeStatus.Active, "Dispute is not active.");
        require(block.timestamp < dispute.voteEndTime, "Voting period has ended.");
        require(!dispute.hasVoted[msg.sender], "You have already voted on this dispute.");
        require(bytes(userProfiles[msg.sender].username).length > 0, "Voter must be a registered user.");

        uint256 voteWeight = userProfiles[msg.sender].reputation;
        require(voteWeight > 0, "Voter has no reputation to cast a vote.");

        if (_inFavor) {
            dispute.votesFor = dispute.votesFor.add(voteWeight);
        } else {
            dispute.votesAgainst = dispute.votesAgainst.add(voteWeight);
        }
        dispute.hasVoted[msg.sender] = true;

        emit VotedOnDispute(_disputeId, msg.sender, _inFavor);
    }

    /**
     * @dev Finalizes a dispute based on voting outcome.
     *      Triggers appropriate on-chain actions (e.g., slashing reputation, re-evaluating, or refunding).
     *      Can be called by anyone after the voting period ends.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) public {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist.");
        require(dispute.status == DisputeStatus.Active, "Dispute is not active.");
        require(block.timestamp >= dispute.voteEndTime, "Voting period has not ended yet.");

        uint256 totalVotes = dispute.votesFor.add(dispute.votesAgainst);
        require(totalVotes > 0, "No votes cast for this dispute. Cannot resolve."); 

        uint256 forPercentage = dispute.votesFor.mul(100).div(totalVotes);

        if (forPercentage >= globalConfigs[GlobalConfigParam.DISPUTE_VOTE_THRESHOLD_PERCENT]) {
            // Dispute resolution in favor of the proposer (meaning the dispute was valid)
            dispute.status = DisputeStatus.Resolved;
            _applyDisputeResolution(_disputeId, true); 
        } else {
            // Dispute rejected (meaning the dispute was not valid)
            dispute.status = DisputeStatus.Rejected;
            _applyDisputeResolution(_disputeId, false); 
        }
        emit DisputeResolved(_disputeId, dispute.status);
    }

    // --- VII. Utility & Views (Internal/Helper Functions) ---

    /**
     * @dev Internal function to resolve a challenge and award the winner.
     *      Called internally once evaluation period for a challenge ends or enough evaluations are done.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function _resolveChallenge(uint256 _challengeId) internal {
        Challenge storage challenge = challenges[_challengeId];
        require(!challenge.isResolved, "Challenge already resolved.");
        require(challenge.winner != address(0), "No valid winner found yet for challenge.");

        challenge.isResolved = true;
        // Transfer reward from contract to winner
        require(paymentToken.transfer(challenge.winner, challenge.rewardAmount), "Challenge reward transfer failed.");

        // Reputation boost for the winner
        userProfiles[challenge.winner].reputation = userProfiles[challenge.winner].reputation.add(globalConfigs[GlobalConfigParam.REPUTATION_BOOST_ON_SUCCESS]);

        emit ChallengeRewardClaimed(_challengeId, challenge.winner, challenge.rewardAmount);
    }

    /**
     * @dev Internal function to apply the consequences of a resolved dispute.
     * @param _disputeId The ID of the resolved dispute.
     * @param _isApproved True if dispute was resolved in favor of the 'for' votes (meaning the dispute was valid), false otherwise.
     */
    function _applyDisputeResolution(uint256 _disputeId, bool _isApproved) internal {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputeType == DisputeType.Project) {
            Project storage project = projects[dispute.entityId];
            if (_isApproved) {
                // Dispute was valid, project was at fault. Mark failed, slash owner reputation.
                project.status = ProjectStatus.Failed;
                userProfiles[project.owner].reputation = userProfiles[project.owner].reputation.sub(globalConfigs[GlobalConfigParam.REPUTATION_SLASH_ON_FAILURE]);
                // Potentially refund incubation stakers if the project fails due to dispute.
                // This would require iterating through `project.incubationStakes` which is a mapping and not iterable directly.
                // A `withdrawFailedIncubationStake` function would be needed for stakers to claim back.
            } else {
                // Dispute was invalid, project is cleared. Restore status to Active. Slash proposer reputation.
                project.status = ProjectStatus.Active; // Or whatever status it was before dispute
                userProfiles[dispute.proposer].reputation = userProfiles[dispute.proposer].reputation.sub(globalConfigs[GlobalConfigParam.REPUTATION_SLASH_ON_FAILURE]);
            }
            _updateProjectNFTMetadata(dispute.entityId);
        } else if (dispute.disputeType == DisputeType.Evaluation) {
            // For an Evaluation dispute, the `entityId` would need to encode both project ID and milestone index.
            // Simplified: if _isApproved (evaluation was bad), reputation of evaluator is slashed, and milestone could be reverted to 'Submitted' for re-evaluation.
            // If not approved, reputation of dispute proposer is slashed.
        } else if (dispute.disputeType == DisputeType.UserProfile) {
            // If _isApproved (user was indeed problematic), apply reputation slash to user.
            // If not approved, slash proposer.
            address disputedUser = address(uint160(dispute.entityId)); // Reconstruct address from entityId
            if (_isApproved) {
                 userProfiles[disputedUser].reputation = userProfiles[disputedUser].reputation.sub(globalConfigs[GlobalConfigParam.REPUTATION_SLASH_ON_FAILURE].mul(2));
            } else {
                 userProfiles[dispute.proposer].reputation = userProfiles[dispute.proposer].reputation.sub(globalConfigs[GlobalConfigParam.REPUTATION_SLASH_ON_FAILURE]);
            }
        } else if (dispute.disputeType == DisputeType.ChallengeSolution) {
            // If _isApproved, potentially trigger a re-evaluation or award a different winner, or slash the initial evaluator's reputation.
            // If not approved, slash the dispute proposer.
        }
    }

    /**
     * @dev Returns the details of a specific project.
     * @param _projectId The ID of the project.
     * @return A tuple containing comprehensive project details.
     */
    function getProjectDetails(uint256 _projectId) public view returns (
        uint256 projectId,
        address owner,
        string memory title,
        string memory description,
        string memory initialIpfsHash,
        uint256 totalFundingGoal,
        uint256 collectedFunds,
        Milestone[] memory milestones,
        ProjectStatus status,
        uint256 currentMilestoneIndex,
        uint256 nftTokenId,
        uint256 totalIncubationStake,
        bool incubationApproved
    ) {
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "Project does not exist.");
        return (
            project.projectId,
            project.owner,
            project.title,
            project.description,
            project.initialIpfsHash,
            project.totalFundingGoal,
            project.collectedFunds,
            project.milestones,
            project.status,
            project.currentMilestoneIndex,
            project.nftTokenId,
            project.totalIncubationStake,
            project.incubationApproved
        );
    }

    /**
     * @dev Returns a user's profile details.
     * @param _userAddress The address of the user.
     * @return A tuple containing user profile information.
     */
    function getUserProfile(address _userAddress) public view returns (
        string memory username,
        string[] memory skills,
        uint256 reputation,
        uint256 currentDelegatedReputation // Placeholder, actual value requires design change
    ) {
        UserProfile storage profile = userProfiles[_userAddress];
        require(bytes(profile.username).length > 0, "User not registered.");
        return (
            profile.username,
            profile.skills,
            profile.reputation,
            0 // Placeholder: calculating delegated reputation from a mapping is not efficient.
              // In a real system, you'd store `totalDelegatedOut` in the struct or handle off-chain.
        );
    }

    /**
     * @dev Internal helper to sum up an array of uint256.
     */
    function _sumArray(uint256[] memory _arr) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint i = 0; i < _arr.length; i++) {
            sum = sum.add(_arr[i]);
        }
        return sum;
    }

    /**
     * @dev Internal helper to convert MilestoneStatus enum to string for NFT metadata.
     */
    function _milestoneStatusToString(MilestoneStatus _status) internal pure returns (string memory) {
        if (_status == MilestoneStatus.Pending) return "Pending";
        if (_status == MilestoneStatus.Submitted) return "Submitted";
        if (_status == MilestoneStatus.Evaluated) return "Evaluated";
        if (_status == MilestoneStatus.Funded) return "Funded";
        return "Unknown"; // Should not happen with proper enum handling
    }

    /**
     * @dev Internal helper function to encode bytes to Base64.
     *      This is a basic implementation. For production, consider using a gas-optimized library
     *      like OpenZeppelin's `utils/Base64.sol` if direct on-chain Base64 encoding is strictly required.
     *      Alternatively, metadata generation can happen off-chain and only the URI stored on-chain.
     */
    function _encodeBase64(bytes memory data) internal pure returns (string memory) {
        // This is a simplified Base64 encoder suitable for small strings.
        // For production, use a battle-tested library or off-chain metadata generation.
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        bytes memory table = new bytes(64);
        for (uint i = 0; i < 64; i++) {
            table[i] = alphabet[i];
        }

        bytes memory encoded = new bytes(((data.length + 2) / 3) * 4);
        uint j = 0;
        for (uint i = 0; i < data.length; i += 3) {
            uint val = uint(data[i]) << 16;
            if (i + 1 < data.length) val |= uint(data[i+1]) << 8;
            if (i + 2 < data.length) val |= uint(data[i+2]);

            encoded[j++] = table[(val >> 18) & 0x3F];
            encoded[j++] = table[(val >> 12) & 0x3F];
            if (i + 1 < data.length) encoded[j++] = table[(val >> 6) & 0x3F];
            else encoded[j++] = '=';
            if (i + 2 < data.length) encoded[j++] = table[val & 0x3F];
            else encoded[j++] = '=';
        }
        return string(encoded);
    }
}
```