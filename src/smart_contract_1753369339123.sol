Here is a Solidity smart contract named `SynergyNet` that incorporates interesting, advanced, creative, and trendy concepts, fulfilling the requirement of at least 20 functions without directly duplicating existing open-source projects.

The core idea is a "Decentralized Collective Intelligence Network" where users collaborate to solve problems, contribute insights, validate solutions, and earn reputation and rewards. It features dynamic NFTs, a reputation system, a simplified DAO, and hooks for advanced concepts like ZK-proofs and oracles.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for some initial admin roles, but actual DAO will control critical functions.
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
    Contract Name: SynergyNet

    Outline & Function Summary:

    SynergyNet is a decentralized collective intelligence network designed to foster collaboration on complex, real-world problems.
    Participants, known as "Synthesizers" and "Resolvers," contribute insights, data, and computational validation,
    earning rewards and building reputation. The system incentivizes high-quality, validated contributions and
    enables the forging of comprehensive solutions. It integrates dynamic NFTs (CatalystCores) representing
    user expertise and operates under a decentralized autonomous organization (DAO) governance model.

    I. Core Setup & Initialization:
    1.  constructor(address _synTokenAddress, address _nftTokenAddress, address _daoAddress): Initializes the contract,
        setting addresses for the ERC-20 SYN token, ERC-721 CatalystCore NFT, and the DAO governance.
    2.  updateOracleAddress(address _newOracle): Allows the DAO to update the trusted oracle address for problem complexity and external data.
    3.  emergencyPause(): Allows the DAO or a designated admin to pause critical contract functions in an emergency.
    4.  unpause(): Allows the DAO or a designated admin to unpause the contract.

    II. Problem Lifecycle Management:
    5.  proposeProblem(string memory _problemTitle, string memory _problemDescription, uint256 _initialBounty, bytes32 _problemHash):
        Users propose new problems, staking an initial bounty. A hash of problem details ensures integrity.
    6.  fundProblemBounty(uint256 _problemId, uint256 _amount): Allows any user to add SYN tokens to an existing problem's bounty.
    7.  approveProblem(uint256 _problemId): DAO-exclusive function to officially approve a proposed problem, making it open for contributions.
        Requires oracle complexity assessment.
    8.  closeProblemForSubmissions(uint256 _problemId): Marks a problem as closed for new contributions, moving it to a solution-forging or review phase.
    9.  getProblemDetails(uint256 _problemId): Read-only function to retrieve all details about a specific problem.

    III. Contribution & Solution Workflow:
    10. submitContribution(uint256 _problemId, string memory _contributionHash, uint256 _stakeAmount):
        Users submit a hash of their off-chain contribution (e.g., data, model, analysis), staking SYN tokens.
    11. validateContribution(uint256 _problemId, uint256 _contributionId, bool _isValid, uint256 _stakeAmount):
        Users review and validate others' contributions, staking SYN tokens on their judgment.
    12. disputeContribution(uint256 _problemId, uint256 _contributionId, uint256 _validatorId, uint256 _stakeAmount):
        Allows a user to dispute a specific validation decision, escalating it for arbitration.
    13. forgeSolution(uint256 _problemId, uint256[] memory _contributorIds, uint256[] memory _contributionIds, string memory _solutionHash, uint256 _stakeAmount):
        A 'Synthesizer' combines multiple *validated* contributions into a cohesive solution, staking SYN.
    14. submitSolutionForReview(uint256 _problemId, uint256 _solutionId):
        Moves a forged solution into a community review phase, opening it up for final validation votes.
    15. validateSolution(uint256 _problemId, uint256 _solutionId, bool _isValid, uint256 _stakeAmount):
        Community members or elected experts vote on the final validity of a proposed solution.
    16. claimSolutionBounty(uint256 _problemId, uint256 _solutionId):
        Allows the creator of a successfully validated solution to claim the problem's bounty and their staked SYN.
    17. claimValidationReward(uint256 _problemId, uint256 _contributionId, address _validatorAddress):
        Allows successful contribution validators to claim their proportional reward and unstake their SYN.

    IV. Reputation (InsightScore) & Dynamic NFTs (CatalystCore):
    18. queryInsightScore(address _user): Returns a user's current InsightScore.
    19. mintCatalystCoreNFT(): Allows users meeting a specific InsightScore threshold to mint their unique CatalystCore NFT.
    20. evolveCatalystCoreNFT(uint256 _tokenId): Triggers an update to the CatalystCore NFT's metadata/attributes based on the owner's latest InsightScore and achievements.
    21. decayInactiveInsightScore(address _user): A callable function (can be triggered by a keeper or periodically by anyone)
        that initiates the decay of InsightScores for inactive users, promoting continuous engagement.

    V. Governance & System Parameters:
    22. submitGovernanceProposal(string memory _description, address _targetContract, bytes memory _callData):
        Allows users with sufficient staked SYN or InsightScore to propose protocol changes. (Simplified for this example)
    23. voteOnGovernanceProposal(uint256 _proposalId, bool _support): Users vote on active governance proposals.
    24. executeGovernanceProposal(uint256 _proposalId): Executes a governance proposal that has passed its voting period and met quorum.
    25. adjustStakingParameters(uint256 _minContributionStake, uint256 _minValidationStake, uint256 _minSolutionStake):
        DAO-controlled function to update staking requirements for various actions.
    26. updateRewardMultipliers(uint256 _contributionMultiplier, uint256 _validationMultiplier, uint256 _solutionMultiplier):
        DAO-controlled function to adjust how rewards are calculated for different roles.

    VI. Advanced Concepts & Utility:
    27. requestZKProofVerification(uint256 _problemId, uint256 _contributionId, bytes memory _zkProofData):
        Simulates an on-chain request to an off-chain ZK-proof verifier for a privacy-preserving contribution.
    28. receiveOracleCallback(uint256 _problemId, uint256 _complexityScore, bytes32 _queryId):
        Internal/external callback function for the oracle to return problem complexity data.
*/

contract SynergyNet is Ownable, Pausable, ReentrancyGuard {

    // --- Immutable Token Addresses ---
    IERC20 public immutable SYN_TOKEN; // ERC-20 token for utility, governance, and rewards
    IERC721 public immutable CATALYST_CORE_NFT; // ERC-721 token representing dynamic user reputation/expertise

    // --- Core System Addresses ---
    address public daoAddress;   // Address of the DAO contract that manages governance over key parameters
    address public oracleAddress; // Address of the trusted oracle for fetching external data or problem complexity

    // --- Configuration Parameters (Adjustable by DAO via governance proposals) ---
    uint256 public minProblemBounty = 100 ether;       // Minimum SYN required to propose a problem
    uint256 public minContributionStake = 10 ether;    // Minimum SYN required to submit a contribution
    uint256 public minValidationStake = 5 ether;       // Minimum SYN required to validate a contribution/solution
    uint256 public minSolutionStake = 50 ether;        // Minimum SYN required to forge a solution

    uint256 public minInsightScoreForNFT = 1000;       // InsightScore required to mint a CatalystCore NFT
    uint256 public insightScoreDecayRate = 10;         // Percentage decay (e.g., 10 for 10%) for inactivity
    uint256 public insightScoreDecayPeriod = 30 days;  // Time period after which inactivity decay is applied

    // Reward multipliers (e.g., 100 = 1x, 150 = 1.5x of base reward based on complexity)
    uint256 public contributionRewardMultiplier = 100;
    uint256 public validationRewardMultiplier = 100;
    uint256 public solutionRewardMultiplier = 200;

    // --- Enums for Status Management ---
    enum ProblemStatus { Proposed, Approved, ClosedForSubmissions, SolutionReview, Solved, Deactivated }
    enum ContributionStatus { Submitted, Validated, Invalidated, Disputed }
    enum SolutionStatus { Forged, Reviewing, Validated, Rejected }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // --- Structs for On-chain Data Representation ---

    struct Problem {
        uint256 id;
        string title;
        string description;   // Reference to off-chain content (e.g., IPFS CID, URL)
        bytes32 problemHash;  // Cryptographic hash of full problem details for integrity
        uint256 bounty;       // Total SYN tokens allocated for solving this problem
        address proposer;
        uint256 createdAt;
        uint256 closedAt;
        ProblemStatus status;
        uint256 complexityScore; // Assessed by oracle, influences rewards and validation thresholds
        uint256 winningSolutionId; // ID of the successfully validated solution
        uint256 submissionClosedAt; // Timestamp when problem closes for new contributions
    }

    struct Contribution {
        uint256 id;
        uint256 problemId;
        address contributor;
        string contributionHash; // Reference to off-chain content (e.g., IPFS CID for data, model, analysis)
        uint256 stakedAmount;
        uint256 submittedAt;
        ContributionStatus status;
        uint256 validVotes;       // Count of 'valid' votes from validators
        uint256 invalidVotes;     // Count of 'invalid' votes from validators
        uint256 disputeVotes;     // Count of votes to dispute a validation decision
        bool isZKVerified;        // Indicates if an associated ZK-proof has been verified off-chain
        address[] validators;     // List of addresses who participated in validation
        mapping(address => bool) hasValidated; // Tracks if a user has already validated this contribution
        mapping(address => bool) hasDisputed;  // Tracks if a user has already disputed this contribution
    }

    struct Solution {
        uint256 id;
        uint256 problemId;
        address creator;
        string solutionHash; // Reference to off-chain combined solution (e.g., IPFS CID)
        uint256 stakedAmount;
        uint256 submittedAt;
        SolutionStatus status;
        uint256[] linkedContributionIds; // IDs of validated contributions incorporated into this solution
        uint256 validVotes;       // Count of 'valid' votes from solution validators
        uint256 invalidVotes;     // Count of 'invalid' votes from solution validators
        mapping(address => bool) hasValidated; // Tracks if a user has already validated this solution
    }

    struct GovernanceProposal {
        uint256 id;
        string description;    // Description of the proposed change
        address proposer;
        address targetContract; // Contract address the proposal intends to interact with
        bytes callData;         // Encoded function call data for the target contract
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;     // Block number when voting period starts
        uint256 endBlock;       // Block number when voting period ends
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables (Mappings and Counters) ---
    uint256 public nextProblemId = 1;
    uint256 public nextContributionId = 1;
    uint256 public nextSolutionId = 1;
    uint256 public nextProposalId = 1;

    mapping(uint256 => Problem) public problems;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => Solution) public solutions;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    mapping(address => uint256) public insightScores;      // User's on-chain reputation score
    mapping(address => uint256) public lastActivityTime;   // Last timestamp a user made a significant action
    mapping(address => uint256) public stakedSYN;          // User's total SYN balance staked within this contract

    // Separate mappings for tracking specific stakes per action (for easier retrieval and management)
    mapping(address => mapping(uint256 => uint256)) public problemStakes;      // user => problemId => amount
    mapping(address => mapping(uint256 => uint256)) public contributionStakes; // user => contributionId => amount
    mapping(address => mapping(uint256 => uint256)) public solutionStakes;     // user => solutionId => amount

    // --- Events for Off-chain Monitoring ---
    event ProblemProposed(uint256 problemId, address indexed proposer, uint256 initialBounty, string title);
    event ProblemApproved(uint256 problemId, uint256 complexityScore);
    event ProblemBountyFunded(uint256 problemId, address indexed funder, uint256 amount);
    event ProblemClosedForSubmissions(uint256 problemId);
    event ContributionSubmitted(uint256 problemId, uint256 contributionId, address indexed contributor, string contributionHash);
    event ContributionValidated(uint256 problemId, uint256 contributionId, address indexed validator, bool isValid);
    event ContributionDisputed(uint256 problemId, uint256 contributionId, uint256 validatorId, address indexed disputer);
    event SolutionForged(uint256 problemId, uint256 solutionId, address indexed creator, string solutionHash);
    event SolutionSubmittedForReview(uint256 problemId, uint256 solutionId);
    event SolutionValidated(uint256 problemId, uint256 solutionId, address indexed validator, bool isValid);
    event SolutionBountyClaimed(uint256 problemId, uint256 solutionId, address indexed claimant, uint256 amount);
    event ValidationRewardClaimed(uint256 problemId, uint256 contributionId, address indexed claimant, uint256 amount);
    event InsightScoreUpdated(address indexed user, uint256 newScore, uint256 oldScore);
    event CatalystCoreMinted(address indexed owner, uint256 tokenId);
    event CatalystCoreEvolved(address indexed owner, uint256 tokenId);
    event InsightScoreDecayed(address indexed user, uint256 newScore, uint256 decayedAmount);
    event GovernanceProposalSubmitted(uint256 proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ParametersAdjusted(string paramName, uint256 newValue);
    event ZKProofVerificationRequested(uint256 problemId, uint256 contributionId, bytes zkProofData);
    event OracleCallbackReceived(uint256 problemId, uint256 complexityScore);


    // --- Constructor ---
    /**
     * @dev Initializes the SynergyNet contract with addresses for the SYN token, CatalystCore NFT, and the DAO.
     * @param _synTokenAddress The address of the deployed ERC-20 SYN token contract.
     * @param _nftTokenAddress The address of the deployed ERC-721 CatalystCore NFT contract.
     * @param _daoAddress The address of the DAO contract responsible for governance.
     */
    constructor(address _synTokenAddress, address _nftTokenAddress, address _daoAddress) Ownable(msg.sender) {
        require(_synTokenAddress != address(0), "SYN token address cannot be zero");
        require(_nftTokenAddress != address(0), "NFT token address cannot be zero");
        require(_daoAddress != address(0), "DAO address cannot be zero");

        SYN_TOKEN = IERC20(_synTokenAddress);
        CATALYST_CORE_NFT = IERC721(_nftTokenAddress);
        daoAddress = _daoAddress;
        // For simulation, set oracle to DAO address. In a real application, this would be a dedicated oracle contract (e.g., Chainlink).
        oracleAddress = _daoAddress; 
    }

    // --- Modifiers ---
    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Caller is not the DAO");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the Oracle");
        _;
    }

    // A combined modifier for emergency controls
    modifier onlyOwnerOrDAO() {
        require(msg.sender == owner() || msg.sender == daoAddress, "Caller is not owner or DAO");
        _;
    }

    // Updates user's last activity timestamp for InsightScore decay calculation
    modifier updateActivityTime() {
        lastActivityTime[msg.sender] = block.timestamp;
        _;
    }

    // --- I. Core Setup & Initialization ---

    /**
     * @dev Allows the DAO to update the trusted oracle address.
     * @param _newOracle The new address of the oracle contract.
     */
    function updateOracleAddress(address _newOracle) external onlyDAO {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        oracleAddress = _newOracle;
        // Emit event for off-chain listeners to track parameter changes
        emit ParametersAdjusted("OracleAddress", uint256(uint160(_newOracle))); 
    }

    /**
     * @dev Pauses the contract, preventing critical operations. Only callable by DAO or owner.
     * Useful for emergency upgrades or bug fixes.
     */
    function emergencyPause() external onlyOwnerOrDAO {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming operations. Only callable by DAO or owner.
     */
    function unpause() external onlyOwnerOrDAO {
        _unpause();
    }

    // --- II. Problem Lifecycle Management ---

    /**
     * @dev Allows a user to propose a new problem to the SynergyNet.
     * Requires an initial SYN bounty to be transferred to the contract.
     * The `_problemHash` allows verification of off-chain problem details.
     * @param _problemTitle The title of the problem.
     * @param _problemDescription A reference to the full problem details (e.g., IPFS CID, URL).
     * @param _initialBounty The initial SYN bounty for the problem.
     * @param _problemHash A cryptographic hash (e.g., keccak256) of the full off-chain problem details.
     */
    function proposeProblem(
        string memory _problemTitle,
        string memory _problemDescription,
        uint256 _initialBounty,
        bytes32 _problemHash
    ) external nonReentrant pausable updateActivityTime {
        require(_initialBounty >= minProblemBounty, "Initial bounty too low");
        require(bytes(_problemTitle).length > 0, "Problem title cannot be empty");
        require(bytes(_problemDescription).length > 0, "Problem description cannot be empty");
        require(_problemHash != bytes32(0), "Problem hash cannot be zero");
        
        // Transfer initial bounty from proposer to contract
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _initialBounty), "SYN transfer failed for bounty");

        uint256 id = nextProblemId++;
        problems[id] = Problem({
            id: id,
            title: _problemTitle,
            description: _problemDescription,
            problemHash: _problemHash,
            bounty: _initialBounty,
            proposer: msg.sender,
            createdAt: block.timestamp,
            closedAt: 0,
            status: ProblemStatus.Proposed,
            complexityScore: 0, // Set by oracle upon approval
            winningSolutionId: 0,
            submissionClosedAt: 0
        });
        // The proposer's stake in the problem (their bounty contribution) is recorded.
        problemStakes[msg.sender][id] = _initialBounty;

        // In a real system, an oracle request would be made here to get complexity.
        // For this example, we assume `receiveOracleCallback` is called separately to set complexity before approval.

        emit ProblemProposed(id, msg.sender, _initialBounty, _problemTitle);
    }

    /**
     * @dev Allows any user to add more SYN tokens to an existing problem's bounty.
     * This can increase the incentive for problem solvers.
     * @param _problemId The ID of the problem to fund.
     * @param _amount The amount of SYN tokens to add to the bounty.
     */
    function fundProblemBounty(uint256 _problemId, uint256 _amount) external nonReentrant pausable updateActivityTime {
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        require(problem.status == ProblemStatus.Proposed || problem.status == ProblemStatus.Approved, "Problem not in funding state");
        require(_amount > 0, "Amount must be greater than zero");
        
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _amount), "SYN transfer failed for bounty funding");

        problem.bounty += _amount;
        emit ProblemBountyFunded(_problemId, msg.sender, _amount);
    }

    /**
     * @dev DAO-exclusive function to officially approve a proposed problem.
     * A problem can only be approved after an oracle has provided its complexity score.
     * Once approved, the problem is open for contributions.
     * @param _problemId The ID of the problem to approve.
     */
    function approveProblem(uint256 _problemId) external onlyDAO pausable {
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        require(problem.status == ProblemStatus.Proposed, "Problem is not in Proposed status");
        require(problem.complexityScore > 0, "Problem complexity not yet set by oracle"); // Ensure oracle has provided data

        problem.status = ProblemStatus.Approved;
        emit ProblemApproved(_problemId, problem.complexityScore);
    }

    /**
     * @dev Closes a problem for new contribution submissions.
     * This moves the problem into a phase where solutions can be forged or reviewed.
     * Can only be called by the problem proposer or the DAO.
     * @param _problemId The ID of the problem to close for submissions.
     */
    function closeProblemForSubmissions(uint256 _problemId) external nonReentrant pausable {
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        require(problem.status == ProblemStatus.Approved, "Problem not in Approved status");
        require(msg.sender == problem.proposer || msg.sender == daoAddress, "Only proposer or DAO can close submissions");

        problem.status = ProblemStatus.ClosedForSubmissions;
        problem.submissionClosedAt = block.timestamp;
        emit ProblemClosedForSubmissions(_problemId);
    }

    /**
     * @dev Read-only function to retrieve all relevant details about a specific problem.
     * @param _problemId The ID of the problem.
     * @return A tuple containing problem details.
     */
    function getProblemDetails(uint256 _problemId)
        external view
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 bounty,
            address proposer,
            uint256 createdAt,
            ProblemStatus status,
            uint256 complexityScore,
            uint256 winningSolutionId
        )
    {
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        return (
            problem.id,
            problem.title,
            problem.description,
            problem.bounty,
            problem.proposer,
            problem.createdAt,
            problem.status,
            problem.complexityScore,
            problem.winningSolutionId
        );
    }

    // --- III. Contribution & Solution Workflow ---

    /**
     * @dev Allows a user to submit a contribution hash for an active problem.
     * The `_contributionHash` refers to off-chain content like data, code, or analysis.
     * Requires staking a minimum amount of SYN tokens, promoting commitment and preventing spam.
     * @param _problemId The ID of the problem for which the contribution is being submitted.
     * @param _contributionHash A hash of the off-chain contribution content (e.g., IPFS CID).
     * @param _stakeAmount The amount of SYN tokens to stake for this contribution.
     */
    function submitContribution(
        uint256 _problemId,
        string memory _contributionHash,
        uint256 _stakeAmount
    ) external nonReentrant pausable updateActivityTime {
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        require(problem.status == ProblemStatus.Approved, "Problem is not open for contributions");
        require(_stakeAmount >= minContributionStake, "Stake amount too low for contribution");
        require(bytes(_contributionHash).length > 0, "Contribution hash cannot be empty");
        
        // Transfer stake from contributor to contract
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "SYN transfer failed for contribution stake");

        uint256 id = nextContributionId++;
        contributions[id] = Contribution({
            id: id,
            problemId: _problemId,
            contributor: msg.sender,
            contributionHash: _contributionHash,
            stakedAmount: _stakeAmount,
            submittedAt: block.timestamp,
            status: ContributionStatus.Submitted,
            validVotes: 0,
            invalidVotes: 0,
            disputeVotes: 0,
            isZKVerified: false,
            validators: new address[](0)
        });
        contributionStakes[msg.sender][id] = _stakeAmount;
        _increaseInsightScore(msg.sender, problem.complexityScore / 100); // Base InsightScore gain

        emit ContributionSubmitted(_problemId, id, msg.sender, _contributionHash);
    }

    /**
     * @dev Allows users to validate or invalidate a submitted contribution.
     * Validators stake SYN tokens on their judgment, risking it if their validation is later proven wrong.
     * @param _problemId The ID of the problem.
     * @param _contributionId The ID of the contribution to validate.
     * @param _isValid True if the contribution is deemed valid, false otherwise.
     * @param _stakeAmount The amount of SYN tokens to stake for this validation.
     */
    function validateContribution(
        uint256 _problemId,
        uint256 _contributionId,
        bool _isValid,
        uint256 _stakeAmount
    ) external nonReentrant pausable updateActivityTime {
        Contribution storage contribution = contributions[_contributionId];
        Problem storage problem = problems[_problemId];

        require(contribution.id == _contributionId, "Contribution does not exist");
        require(contribution.problemId == _problemId, "Contribution does not belong to this problem");
        require(contribution.status == ContributionStatus.Submitted, "Contribution is not in Submitted status");
        require(msg.sender != contribution.contributor, "Cannot validate your own contribution");
        require(!contribution.hasValidated[msg.sender], "Already validated this contribution");
        require(_stakeAmount >= minValidationStake, "Stake amount too low for validation");
        
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "SYN transfer failed for validation stake");

        if (_isValid) {
            contribution.validVotes++;
            _increaseInsightScore(msg.sender, 5); // Small InsightScore gain for valid vote
        } else {
            contribution.invalidVotes++;
            _decreaseInsightScore(msg.sender, 2); // Small InsightScore penalty for invalid vote (can be tuned)
        }
        contribution.hasValidated[msg.sender] = true;
        contribution.validators.push(msg.sender);
        contributionStakes[msg.sender][_contributionId] += _stakeAmount; // Add to existing stake or create new

        // Simple auto-validation/invalidation logic based on vote count and problem complexity
        // More robust systems could use quadratic voting, reputation-weighted votes, etc.
        if (contribution.validVotes >= problem.complexityScore / 10 && contribution.validVotes > contribution.invalidVotes) {
            contribution.status = ContributionStatus.Validated;
        } else if (contribution.invalidVotes >= problem.complexityScore / 10 && contribution.invalidVotes > contribution.validVotes) {
            contribution.status = ContributionStatus.Invalidated;
        }

        emit ContributionValidated(_problemId, _contributionId, msg.sender, _isValid);
    }

    /**
     * @dev Allows a user to dispute a specific validation decision.
     * This moves the contribution into a disputed state, potentially triggering an arbitration process.
     * NOTE: For a real system, `_validatorId` would need to be replaced with a robust way to identify the specific validation instance,
     * likely including the validator's address and a proof of their validation action. This is a simplified placeholder.
     * @param _problemId The ID of the problem.
     * @param _contributionId The ID of the contribution being disputed.
     * @param _validatorId The (simplified) identifier of the validator whose decision is disputed.
     * @param _stakeAmount The amount of SYN tokens to stake for this dispute.
     */
    function disputeContribution(
        uint256 _problemId,
        uint256 _contributionId,
        uint256 _validatorId, // Simplified: needs robust lookup for specific validation in production
        uint256 _stakeAmount
    ) external nonReentrant pausable updateActivityTime {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.id == _contributionId, "Contribution does not exist");
        require(contribution.problemId == _problemId, "Contribution does not belong to this problem");
        require(contribution.status != ContributionStatus.Disputed, "Contribution is already under dispute");
        require(contribution.status != ContributionStatus.Invalidated, "Cannot dispute an invalidated contribution");
        require(_stakeAmount >= minValidationStake, "Stake amount too low for dispute");
        
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "SYN transfer failed for dispute stake");
        require(!contribution.hasDisputed[msg.sender], "Already disputed this contribution");
        require(_validatorId < contribution.validators.length, "Invalid validator ID provided"); // Basic check

        contribution.disputeVotes++;
        contribution.status = ContributionStatus.Disputed; // Set status to disputed, awaiting arbitration
        contribution.hasDisputed[msg.sender] = true;
        
        _increaseInsightScore(msg.sender, 10); // Reward for initiating a dispute (represents commitment to network integrity)

        emit ContributionDisputed(_problemId, _contributionId, _validatorId, msg.sender);
    }

    /**
     * @dev Allows a 'Synthesizer' to combine multiple *validated* contributions into a comprehensive solution.
     * The `_solutionHash` refers to the off-chain combined solution content.
     * Requires staking a minimum amount of SYN tokens.
     * @param _problemId The ID of the problem.
     * @param _contributorIds An array of contributor IDs whose contributions are used (for potential future tracking/splits).
     * @param _contributionIds An array of validated contribution IDs that form this solution.
     * @param _solutionHash A hash of the off-chain combined solution (e.g., IPFS CID).
     * @param _stakeAmount The amount of SYN tokens to stake for this solution.
     */
    function forgeSolution(
        uint256 _problemId,
        uint256[] memory _contributorIds, // Included for potential future complex reward distribution
        uint256[] memory _contributionIds,
        string memory _solutionHash,
        uint256 _stakeAmount
    ) external nonReentrant pausable updateActivityTime {
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        require(problem.status == ProblemStatus.ClosedForSubmissions, "Problem is not in solution forging phase");
        require(_stakeAmount >= minSolutionStake, "Stake amount too low for solution forging");
        require(bytes(_solutionHash).length > 0, "Solution hash cannot be empty");
        require(_contributionIds.length > 0, "A solution must include at least one contribution");
        
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "SYN transfer failed for solution stake");

        // Verify all linked contributions are validated and belong to this problem
        for (uint256 i = 0; i < _contributionIds.length; i++) {
            Contribution storage c = contributions[_contributionIds[i]];
            require(c.id == _contributionIds[i], "Linked contribution does not exist");
            require(c.problemId == _problemId, "Linked contribution does not belong to this problem");
            require(c.status == ContributionStatus.Validated, "Only validated contributions can be used in a solution");
        }

        uint256 id = nextSolutionId++;
        solutions[id] = Solution({
            id: id,
            problemId: _problemId,
            creator: msg.sender,
            solutionHash: _solutionHash,
            stakedAmount: _stakeAmount,
            submittedAt: block.timestamp,
            status: SolutionStatus.Forged,
            linkedContributionIds: _contributionIds,
            validVotes: 0,
            invalidVotes: 0
        });
        solutionStakes[msg.sender][id] = _stakeAmount;
        _increaseInsightScore(msg.sender, problem.complexityScore); // Significant InsightScore gain for forging

        emit SolutionForged(_problemId, id, msg.sender, _solutionHash);
    }

    /**
     * @dev Moves a forged solution into a community review phase, making it available for final validation votes.
     * Can only be called by the solution creator after the solution has been forged.
     * @param _problemId The ID of the problem.
     * @param _solutionId The ID of the solution to submit for review.
     */
    function submitSolutionForReview(uint256 _problemId, uint256 _solutionId) external nonReentrant pausable {
        Problem storage problem = problems[_problemId];
        Solution storage solution = solutions[_solutionId];

        require(problem.id == _problemId, "Problem does not exist");
        require(solution.id == _solutionId, "Solution does not exist");
        require(solution.problemId == _problemId, "Solution does not belong to this problem");
        require(solution.creator == msg.sender, "Only solution creator can submit for review");
        require(solution.status == SolutionStatus.Forged, "Solution is not in Forged status");
        require(problem.status == ProblemStatus.ClosedForSubmissions, "Problem not ready for solution review");

        solution.status = SolutionStatus.Reviewing;
        problem.status = ProblemStatus.SolutionReview; // Update problem status to reflect active review
        emit SolutionSubmittedForReview(_problemId, _solutionId);
    }

    /**
     * @dev Allows community members or elected experts to vote on the final validity of a proposed solution.
     * Validators stake SYN tokens on their judgment.
     * @param _problemId The ID of the problem.
     * @param _solutionId The ID of the solution to validate.
     * @param _isValid True if the solution is valid, false otherwise.
     * @param _stakeAmount The amount of SYN tokens to stake for this validation.
     */
    function validateSolution(
        uint256 _problemId,
        uint256 _solutionId,
        bool _isValid,
        uint256 _stakeAmount
    ) external nonReentrant pausable updateActivityTime {
        Solution storage solution = solutions[_solutionId];
        Problem storage problem = problems[_problemId];

        require(solution.id == _solutionId, "Solution does not exist");
        require(problem.id == _problemId, "Problem does not exist");
        require(solution.problemId == _problemId, "Solution does not belong to this problem");
        require(solution.status == SolutionStatus.Reviewing, "Solution is not in Reviewing status");
        require(problem.status == ProblemStatus.SolutionReview, "Problem is not in Solution Review status");
        require(msg.sender != solution.creator, "Cannot validate your own solution");
        require(!solution.hasValidated[msg.sender], "Already validated this solution");
        require(_stakeAmount >= minValidationStake, "Stake amount too low for solution validation");
        
        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "SYN transfer failed for solution validation stake");

        if (_isValid) {
            solution.validVotes++;
            _increaseInsightScore(msg.sender, 20); // Higher InsightScore gain for solution validation
        } else {
            solution.invalidVotes++;
            _decreaseInsightScore(msg.sender, 10); // Higher InsightScore penalty
        }
        solution.hasValidated[msg.sender] = true;
        solutionStakes[msg.sender][_solutionId] += _stakeAmount; // Add to existing stake or create new

        // If sufficient votes are cast, finalize solution status
        uint256 totalVotes = solution.validVotes + solution.invalidVotes;
        // Threshold for finalization based on problem complexity
        if (totalVotes >= problem.complexityScore / 5) {
            if (solution.validVotes > solution.invalidVotes) {
                solution.status = SolutionStatus.Validated;
                problem.status = ProblemStatus.Solved;
                problem.winningSolutionId = _solutionId;
            } else {
                solution.status = SolutionStatus.Rejected;
                // A rejected solution might open up the problem for new solution forging or mark it unresolved.
            }
        }
        emit SolutionValidated(_problemId, _solutionId, msg.sender, _isValid);
    }

    /**
     * @dev Allows the creator of a successfully validated solution to claim the problem's bounty.
     * Also returns their staked SYN. Distributes a portion of the bounty to contributors.
     * @param _problemId The ID of the problem.
     * @param _solutionId The ID of the solution.
     */
    function claimSolutionBounty(uint256 _problemId, uint256 _solutionId) external nonReentrant pausable {
        Problem storage problem = problems[_problemId];
        Solution storage solution = solutions[_solutionId];

        require(problem.id == _problemId, "Problem does not exist");
        require(solution.id == _solutionId, "Solution does not exist");
        require(solution.problemId == _problemId, "Solution does not belong to this problem");
        require(solution.creator == msg.sender, "Only the solution creator can claim bounty");
        require(solution.status == SolutionStatus.Validated, "Solution is not validated");
        require(problem.winningSolutionId == _solutionId, "This is not the winning solution for the problem");

        uint256 totalReward = problem.bounty + solution.stakedAmount; // Bounty + creator's stake
        problem.bounty = 0; // Clear problem bounty
        solution.stakedAmount = 0; // Clear creator's stake

        require(SYN_TOKEN.transfer(msg.sender, totalReward), "Failed to transfer bounty and stake");

        // Reward InsightScore based on problem complexity and bounty value
        _increaseInsightScore(msg.sender, (problem.complexityScore * solutionRewardMultiplier) / 100);

        // Distribute portion of bounty to contributors whose contributions were linked (simplified to 50% split)
        if (solution.linkedContributionIds.length > 0) {
            uint256 contributorShare = totalReward / 2;
            uint256 perContributorShare = contributorShare / solution.linkedContributionIds.length;
            for (uint256 i = 0; i < solution.linkedContributionIds.length; i++) {
                Contribution storage c = contributions[solution.linkedContributionIds[i]];
                if (c.contributor != address(0) && perContributorShare > 0) {
                    require(SYN_TOKEN.transfer(c.contributor, perContributorShare), "Failed to transfer contributor share");
                    _increaseInsightScore(c.contributor, problem.complexityScore / 2); // Reward for contributing
                }
            }
        }
        emit SolutionBountyClaimed(_problemId, _solutionId, msg.sender, totalReward);
    }

    /**
     * @dev Allows successful contribution validators to claim their proportional reward and unstake their SYN.
     * This can only be called after the problem is solved and the linked solution is validated.
     * @param _problemId The ID of the problem.
     * @param _contributionId The ID of the contribution that was validated.
     * @param _validatorAddress The address of the validator claiming the reward.
     */
    function claimValidationReward(uint256 _problemId, uint256 _contributionId, address _validatorAddress) external nonReentrant pausable {
        Problem storage problem = problems[_problemId];
        Contribution storage contribution = contributions[_contributionId];

        require(problem.id == _problemId, "Problem does not exist");
        require(contribution.id == _contributionId, "Contribution does not exist");
        require(problem.status == ProblemStatus.Solved, "Problem is not yet solved");
        require(contribution.problemId == _problemId, "Contribution does not belong to this problem");
        require(contribution.status == ContributionStatus.Validated, "Contribution was not successfully validated");
        require(contribution.hasValidated[_validatorAddress], "Validator did not validate this contribution");
        require(_validatorAddress == msg.sender, "Only the validator can claim their reward");

        uint256 stake = contributionStakes[_validatorAddress][_contributionId];
        require(stake > 0, "No stake to claim for this validation");

        // Calculate proportional reward based on complexity and multiplier
        uint256 reward = (problem.complexityScore * validationRewardMultiplier) / 100;

        // Unlock stake and send reward
        contributionStakes[_validatorAddress][_contributionId] = 0; // Clear stake
        require(SYN_TOKEN.transfer(msg.sender, stake + reward), "Failed to transfer validation reward and stake");

        emit ValidationRewardClaimed(_problemId, _contributionId, msg.sender, stake + reward);
    }

    // --- IV. Reputation (InsightScore) & Dynamic NFTs (CatalystCore) ---

    /**
     * @dev Returns a user's current InsightScore.
     * @param _user The address of the user.
     * @return The InsightScore of the user.
     */
    function queryInsightScore(address _user) external view returns (uint256) {
        return insightScores[_user];
    }

    /**
     * @dev Allows users meeting a specific InsightScore threshold to mint their unique CatalystCore NFT.
     * This NFT would visually evolve based on the user's continued contributions and reputation.
     * (Assumes the CatalystCore NFT contract handles the actual minting logic and uniqueness).
     */
    function mintCatalystCoreNFT() external nonReentrant pausable updateActivityTime {
        require(insightScores[msg.sender] >= minInsightScoreForNFT, "InsightScore too low to mint CatalystCore NFT");
        // In a real implementation, you'd check if the user already owns an NFT (e.g., CATALYST_CORE_NFT.balanceOf(msg.sender) == 0)
        // This line is a placeholder for the actual call to the NFT contract's mint function.
        // E.g., `CATALYST_CORE_NFT.mint(msg.sender, nextAvailableTokenId);`
        // For demonstration, we simply emit an event and give a small InsightScore bonus.
        uint256 dummyNewTokenId = CATALYST_CORE_NFT.balanceOf(msg.sender) + 1; // Placeholder for new token ID
        
        _increaseInsightScore(msg.sender, 50); // Small bonus for minting
        emit CatalystCoreMinted(msg.sender, dummyNewTokenId);
    }

    /**
     * @dev Triggers an update to the CatalystCore NFT's metadata/attributes based on the owner's latest InsightScore and achievements.
     * This function would typically interact with an off-chain service that manages NFT metadata URIs,
     * or an on-chain dynamic NFT contract capable of updating its internal attributes.
     * @param _tokenId The ID of the CatalystCore NFT to evolve.
     */
    function evolveCatalystCoreNFT(uint256 _tokenId) external nonReentrant pausable updateActivityTime {
        require(CATALYST_CORE_NFT.ownerOf(_tokenId) == msg.sender, "Not the owner of this NFT");
        
        // This function would typically signal an off-chain service or trigger a call to the NFT contract
        // to update its metadata URI or internal attributes based on the user's `insightScores[msg.sender]`.
        // Example: `ICatalystCoreNFT(address(CATALYST_CORE_NFT)).updateAttributes(_tokenId, insightScores[msg.sender]);` (pseudo code)

        emit CatalystCoreEvolved(msg.sender, _tokenId);
    }

    /**
     * @dev Initiates the decay of InsightScores for inactive users.
     * This function can be called by anyone (e.g., a keeper bot) to keep scores fresh and promote continuous engagement.
     * It prevents scores from inflating indefinitely for inactive participants.
     * @param _user The user whose InsightScore is to be decayed.
     */
    function decayInactiveInsightScore(address _user) external nonReentrant {
        uint256 currentScore = insightScores[_user];
        uint256 lastActive = lastActivityTime[_user];

        // Ensure there's a score to decay, user has recorded activity, and enough time has passed
        if (currentScore == 0 || lastActive == 0 || block.timestamp < lastActive + insightScoreDecayPeriod) {
            return;
        }

        uint256 periodsElapsed = (block.timestamp - lastActive) / insightScoreDecayPeriod;
        uint256 decayAmount = (currentScore * insightScoreDecayRate * periodsElapsed) / 100;
        uint256 newScore = currentScore > decayAmount ? currentScore - decayAmount : 0;

        insightScores[_user] = newScore;
        lastActivityTime[_user] = block.timestamp; // Reset activity time after decay, only applying decay once per period
        emit InsightScoreDecayed(_user, newScore, decayAmount);
    }

    /**
     * @dev Internal function to increase a user's InsightScore.
     * @param _user The address of the user.
     * @param _amount The amount to increase the score by.
     */
    function _increaseInsightScore(address _user, uint256 _amount) internal {
        uint256 oldScore = insightScores[_user];
        insightScores[_user] += _amount;
        emit InsightScoreUpdated(_user, insightScores[_user], oldScore);
    }

    /**
     * @dev Internal function to decrease a user's InsightScore.
     * @param _user The address of the user.
     * @param _amount The amount to decrease the score by.
     */
    function _decreaseInsightScore(address _user, uint256 _amount) internal {
        uint256 oldScore = insightScores[_user];
        insightScores[_user] = insightScores[_user] > _amount ? insightScores[_user] - _amount : 0;
        emit InsightScoreUpdated(_user, insightScores[_user], oldScore);
    }

    // --- V. Governance & System Parameters (Simplified DAO logic) ---
    // Note: A full DAO would typically be a separate, more complex contract managing voting power
    // (e.g., token-weighted, NFT-weighted), quorum, and time-locked execution.
    // This section provides a basic conceptual framework within this contract.

    /**
     * @dev Allows users with sufficient engagement (via staked SYN or InsightScore, though not explicitly checked here)
     * to propose protocol changes.
     * @param _description A detailed description of the proposed change.
     * @param _targetContract The address of the contract the proposal intends to interact with (e.g., this SynergyNet contract).
     * @param _callData The encoded function call data for the target contract (e.g., `abi.encodeWithSignature("adjustStakingParameters(uint256,uint256,uint256)", 100, 50, 200)`).
     */
    function submitGovernanceProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external pausable updateActivityTime {
        // In a real system: require(stakedSYN[msg.sender] >= minProposalStake || insightScores[msg.sender] >= minProposalInsightScore)
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_targetContract != address(0), "Target contract cannot be zero address");
        require(_callData.length > 0, "Call data cannot be empty");

        uint256 id = nextProposalId++;
        governanceProposals[id] = GovernanceProposal({
            id: id,
            description: _description,
            proposer: msg.sender,
            targetContract: _targetContract,
            callData: _callData,
            votesFor: 0,
            votesAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + 1000, // Fixed voting period of 1000 blocks (approx. 4 hours on Ethereum)
            status: ProposalStatus.Pending
        });

        emit GovernanceProposalSubmitted(id, msg.sender, _description);
    }

    /**
     * @dev Users vote on active governance proposals.
     * Voting power in a real DAO might be proportional to staked SYN, InsightScore, or other metrics.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external pausable updateActivityTime {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not open for voting");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a governance proposal that has passed its voting period and met quorum.
     * Only callable by the DAO address, ensuring decentralized control over protocol changes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyDAO pausable {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in Pending status");
        require(block.number > proposal.endBlock, "Voting period has not ended");

        // Simple quorum (any votes) and majority check. A real DAO would have explicit quorum thresholds.
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast for this proposal");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority vote");

        // Execute the call to the target contract
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev DAO-controlled function to adjust staking requirements for various actions.
     * This provides flexibility for the community to tune economic parameters.
     * @param _minContributionStake_ The new minimum stake for contributions.
     * @param _minValidationStake_ The new minimum stake for validations.
     * @param _minSolutionStake_ The new minimum stake for solutions.
     */
    function adjustStakingParameters(
        uint256 _minContributionStake_,
        uint256 _minValidationStake_,
        uint256 _minSolutionStake_
    ) external onlyDAO {
        minContributionStake = _minContributionStake_;
        minValidationStake = _minValidationStake_;
        minSolutionStake = _minSolutionStake_;
        emit ParametersAdjusted("minContributionStake", _minContributionStake_);
        emit ParametersAdjusted("minValidationStake", _minValidationStake_);
        emit ParametersAdjusted("minSolutionStake", _minSolutionStake_);
    }

    /**
     * @dev DAO-controlled function to adjust how rewards are calculated for different roles.
     * This allows the community to incentivize specific behaviors or roles.
     * @param _contributionMultiplier_ The new multiplier for contribution rewards.
     * @param _validationMultiplier_ The new multiplier for validation rewards.
     * @param _solutionMultiplier_ The new multiplier for solution rewards.
     */
    function updateRewardMultipliers(
        uint256 _contributionMultiplier_,
        uint256 _validationMultiplier_,
        uint256 _solutionMultiplier_
    ) external onlyDAO {
        contributionRewardMultiplier = _contributionMultiplier_;
        validationRewardMultiplier = _validationMultiplier_;
        solutionRewardMultiplier = _solutionMultiplier_;
        emit ParametersAdjusted("contributionRewardMultiplier", _contributionMultiplier_);
        emit ParametersAdjusted("validationRewardMultiplier", _validationMultiplier_);
        emit ParametersAdjusted("solutionRewardMultiplier", _solutionMultiplier_);
    }

    // --- VI. Advanced Concepts & Utility ---

    /**
     * @dev Simulates an on-chain request to an off-chain Zero-Knowledge Proof (ZK-proof) verifier
     * for a privacy-preserving contribution.
     * This function doesn't perform actual ZK-proof verification on-chain (which is too gas intensive).
     * Instead, it logs the request and potentially marks the contribution for later off-chain verification.
     * A trusted callback (e.g., from an oracle or DAO) would then update `isZKVerified`.
     * @param _problemId The ID of the problem.
     * @param _contributionId The ID of the contribution to be verified.
     * @param _zkProofData The raw ZK-proof data submitted by the user.
     */
    function requestZKProofVerification(
        uint256 _problemId,
        uint256 _contributionId,
        bytes memory _zkProofData
    ) external pausable updateActivityTime {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.id == _contributionId, "Contribution does not exist");
        require(contribution.problemId == _problemId, "Contribution does not belong to this problem");
        require(contribution.contributor == msg.sender, "Only the contributor can request ZK verification");
        require(!contribution.isZKVerified, "Contribution already ZK-verified");
        require(bytes(_zkProofData).length > 0, "ZK proof data cannot be empty");

        // In a real system, this would trigger an external call to a ZK verifier service
        // (e.g., via Chainlink external adapters or a dedicated off-chain component).
        // For simulation, we just emit an event.
        // Once verified off-chain, a trusted callback (similar to `receiveOracleCallback`)
        // would need to set `contribution.isZKVerified = true;` and reward InsightScore.

        emit ZKProofVerificationRequested(_problemId, _contributionId, _zkProofData);
        // For a full mock, you could temporarily set `contribution.isZKVerified = true;` here,
        // but it's best to keep the separation for conceptual clarity.
    }

    /**
     * @dev Mock function to simulate an oracle callback, typically used to set external data or problem complexity scores.
     * In a real system, this would be callable only by the trusted `oracleAddress`.
     * @param _problemId The ID of the problem for which the complexity score is received.
     * @param _complexityScore The complexity score provided by the oracle (e.g., derived from problem attributes).
     * @param _queryId An identifier from the oracle query (for tracking purposes, if applicable).
     */
    function receiveOracleCallback(uint256 _problemId, uint256 _complexityScore, bytes32 _queryId) external onlyOracle {
        // _queryId would be used to match the specific request initiated earlier (e.g., within `proposeProblem`).
        Problem storage problem = problems[_problemId];
        require(problem.id == _problemId, "Problem does not exist");
        require(problem.status == ProblemStatus.Proposed, "Problem not in Proposed status for complexity update");
        require(_complexityScore > 0, "Complexity score must be positive");

        problem.complexityScore = _complexityScore;
        emit OracleCallbackReceived(_problemId, _complexityScore);
    }
}

```