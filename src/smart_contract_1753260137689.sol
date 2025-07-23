The smart contract below, named "DARS Network" (Decentralized Autonomous Reputation & Skill Network), is designed to be an advanced, creative, and trendy platform. It integrates concepts like dynamic NFT profiles, a sophisticated on-chain reputation system, verifiable skills, a micro-tasking/gig economy model, AI oracle integration for task validation, decentralized dispute resolution, staking mechanisms, and DAO governance, all while incorporating an environmental (carbon offset) component.

The core idea is to build a self-sustaining ecosystem where users can build verifiable on-chain profiles, complete tasks, earn reputation, and contribute to a decentralized governance structure.

---

## DARS Network: Decentralized Autonomous Reputation & Skill Network

### Outline:

1.  **Introduction & Core Concept**: A decentralized platform for talent discovery and task fulfillment, powered by on-chain reputation, skill verification, AI-assisted validation, and community governance.
2.  **Key Features**:
    *   **Dynamic Profile NFTs (ERC721)**: User profiles are represented as NFTs, whose metadata (e.g., reputation, asserted skills) dynamically reflects their on-chain activity.
    *   **Reputation System**: A sophisticated algorithm to track and decay user reputation based on successful task completion, skill endorsements, and inactivity.
    *   **Skill Management**: Users can assert skills, and others can endorse them, contributing to a confidence score.
    *   **Micro-Tasking / Gig Economy**: A system for creating, proposing solutions for, and validating small, bounty-based tasks.
    *   **AI Oracle Integration**: Tasks can require validation by a trusted off-chain AI oracle, bridging the gap between on-chain execution and complex off-chain logic.
    *   **Decentralized Dispute Resolution**: A mechanism for resolving disagreements over task completion through community arbitration, incentivized by token staking.
    *   **Staking & Rewards**: Users stake tokens to participate, propose tasks, act as arbitrators, and earn rewards from network fees.
    *   **DAO Governance**: A basic governance module for evolving network parameters, upgrading contracts, and managing a community treasury.
    *   **Carbon Offset Integration**: A portion of network fees is automatically allocated to a dedicated carbon offset fund, promoting environmental responsibility.
3.  **Token Economy**: Utilizes a native utility token (`DARSToken`) for bounties, staking, governance voting power, and dispute resolution.

### Function Summary (24 Functions):

**I. Core Profile & Reputation Management (ERC721 Profiles)**
1.  `registerProfile(string _profileURI)`: Mints a unique Profile NFT for a new user, initializing their on-chain presence.
2.  `updateProfileURI(uint256 _profileId, string _newURI)`: Allows a profile owner to update their profile's external metadata URI.
3.  `decayReputation(uint256 _profileId)`: Publicly callable function (with a small incentive) to decay a profile's reputation based on last activity.
4.  `getProfileDetails(uint256 _profileId)`: Retrieves comprehensive details about a specific user's profile.

**II. Skill Management**
5.  `assertSkill(uint256 _profileId, bytes32 _skillHash, uint256 _initialConfidence)`: Allows a profile owner to declare a new skill with an initial confidence level.
6.  `endorseSkill(uint256 _profileId, bytes32 _skillHash)`: Enables other users to endorse a profile's asserted skill, boosting its confidence score.
7.  `getSkillConfidence(uint256 _profileId, bytes32 _skillHash)`: Queries the current confidence score for a specific skill on a profile.

**III. Task Management (Gig Economy)**
8.  `createTask(bytes32 _taskDescriptionHash, uint256 _bountyAmount, uint256 _deadline, bytes32[] _requiredSkills, ValidationMethod _validationMethod)`: Creates a new task, specifying requirements, bounty, and validation method.
9.  `proposeSolution(uint256 _taskId, uint256 _solverProfileId, bytes32 _solutionHash)`: A profile owner submits their solution for a task they wish to solve.
10. `acceptSolution(uint256 _taskId, uint256 _solverProfileId)`: The task creator accepts a proposed solution, releasing the bounty and updating reputation.
11. `rejectSolution(uint256 _taskId, uint256 _solverProfileId, string _reason)`: The task creator rejects a solution, optionally providing a reason.
12. `submitOracleValidation(uint256 _taskId, uint256 _solverProfileId, bytes _validationData, bool _isValid)`: Callable only by a designated AI Oracle to provide validation results for tasks requiring AI review.
13. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel an unfulfilled task, reclaiming the bounty.

**IV. Decentralized Dispute Resolution**
14. `requestDispute(uint256 _taskId, uint256 _solverProfileId, string _reason)`: Initiates a dispute over a task's outcome, freezing funds.
15. `stakeForArbitration(uint256 _amount)`: Allows users to stake tokens to become eligible arbitrators.
16. `voteOnDispute(uint256 _disputeId, bool _creatorWins)`: Arbitrators cast their vote on a dispute.
17. `finalizeDispute(uint256 _disputeId)`: Concludes a dispute after voting period, distributing funds and updating reputation based on outcome.

**V. Staking & Rewards**
18. `stakeForParticipation(uint256 _amount)`: Allows users to stake `DARSToken` to gain network participation rights (e.g., proposing tasks, voting).
19. `unstake(uint256 _amount)`: Initiates the unstaking process after an unbonding period.
20. `claimStakingRewards()`: Allows stakers to claim accumulated rewards from network fees and successful arbitration.

**VI. DAO Governance**
21. `proposeGovernanceAction(bytes _callData, address _targetAddress, string _description)`: Allows token holders to propose changes to contract parameters or upgrades.
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables token holders to vote for or against an active proposal.
23. `executeProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal.

**VII. System Parameters & Utilities**
24. `setOracleAddress(address _newOracleAddress)`: DAO-controlled function to update the address of the trusted AI Oracle.
25. `withdrawCarbonOffsetFunds(uint256 _amount)`: Allows the DAO to withdraw funds from the carbon offset treasury to a designated off-chain entity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces for external contracts (mocked for simplicity) ---
// In a real scenario, these would be separate deployed contracts.

interface IDARSToken is IERC20 {
    // Standard ERC20 functions are inherited from IERC20
    // No special functions needed for this example beyond standard transfers
}

interface IProfileNFT is ERC721 {
    // Constructor would be internal or take _name, _symbol
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    // Custom function to mint a new profile NFT
    function mint(address _to, string memory _tokenURI) external returns (uint256);

    // Custom function to update the profile's URI
    function updateTokenURI(uint256 _tokenId, string memory _newURI) external;
}


// --- Main DARS Network Contract ---

contract DARSNetwork is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Token and NFT Contract Addresses (Set in constructor, changeable by DAO)
    IDARSToken public immutable DARSToken;
    IProfileNFT public immutable ProfileNFT;
    address public trustedAIOracle; // Address of the AI oracle for validation

    // System Parameters (Changeable by DAO governance)
    uint256 public reputationDecayRatePerDay = 10; // Points per day of inactivity
    uint256 public minReputationForTaskCreation = 100;
    uint256 public minStakeForArbitration = 5000 * (10 ** 18); // Example: 5000 DARSTokens
    uint256 public unbondingPeriodSeconds = 7 * 24 * 60 * 60; // 7 days for unstaking
    uint256 public platformFeeRate = 50; // 0.5% (50 basis points) of bounty
    uint256 public carbonOffsetFeeRate = 10; // 0.1% (10 basis points) of bounty

    // Counters for unique IDs
    Counters.Counter private _profileIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _proposalIds;

    // --- Data Structures ---

    // Profile representation
    struct Profile {
        address owner;
        uint256 reputationScore;
        uint256 lastActiveTimestamp;
        // Mapping of skill hash to confidence score (0-1000, 1000 = 100%)
        mapping(bytes32 => uint256) skills;
    }
    mapping(uint256 => Profile) public profiles; // profileId => Profile

    // Skill endorsement tracking
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public skillEndorsedBy; // profileId => skillHash => endorser => bool

    // Task enumeration for validation method
    enum ValidationMethod { MANUAL, AI_ORACLE, COMMUNITY_VOTE }

    // Task representation
    enum TaskStatus { PENDING, SOLUTION_PROPOSED, ACCEPTED, REJECTED, DISPUTED, CANCELLED, COMPLETED }
    struct Task {
        uint256 creatorProfileId;
        uint256 solverProfileId;
        uint256 bountyAmount; // In DARSToken
        bytes32 descriptionHash; // IPFS hash or similar for task description
        bytes32 solutionHash;    // IPFS hash or similar for solution
        bytes32[] requiredSkills; // Array of skill hashes
        uint256 deadline;
        TaskStatus status;
        ValidationMethod validationMethod;
        uint256 disputeId; // 0 if no dispute
    }
    mapping(uint256 => Task) public tasks; // taskId => Task

    // Dispute enumeration for status
    enum DisputeStatus { PENDING_VOTES, RESOLVED_CREATOR_WINS, RESOLVED_SOLVER_WINS, CANCELED }
    struct Dispute {
        uint256 taskId;
        uint256 creatorProfileId;
        uint256 solverProfileId;
        uint256 creationTime;
        uint256 votingEndsTime;
        uint256 votesForCreator;
        uint256 votesForSolver;
        DisputeStatus status;
        mapping(address => bool) hasVoted; // arbitrator address => bool
    }
    mapping(uint256 => Dispute) public disputes; // disputeId => Dispute

    // Staking information
    struct Staker {
        uint256 stakedAmount;
        uint256 unbondingStartTime; // 0 if not unbonding
    }
    mapping(address => Staker) public stakers; // user address => Staker

    // Governance Proposals
    enum ProposalStatus { PENDING, ACTIVE, SUCCEEDED, FAILED, EXECUTED }
    struct Proposal {
        address proposer;
        address targetAddress;
        bytes callData;
        string description;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // voter address => bool
    }
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal

    uint256 public totalStakedTokens;
    uint256 public carbonOffsetTreasury; // Funds for carbon offset initiatives

    // --- Events ---

    event ProfileRegistered(uint256 indexed profileId, address indexed owner, string profileURI);
    event ProfileURIUpdated(uint256 indexed profileId, string newURI);
    event ReputationUpdated(uint256 indexed profileId, uint256 newReputation);
    event SkillAsserted(uint256 indexed profileId, bytes32 indexed skillHash, uint256 confidence);
    event SkillEndorsed(uint256 indexed profileId, bytes32 indexed skillHash, address indexed endorser);

    event TaskCreated(uint256 indexed taskId, uint256 indexed creatorProfileId, uint256 bounty, ValidationMethod validationMethod);
    event SolutionProposed(uint256 indexed taskId, uint256 indexed solverProfileId, bytes32 solutionHash);
    event SolutionAccepted(uint256 indexed taskId, uint256 indexed solverProfileId);
    event SolutionRejected(uint256 indexed taskId, uint256 indexed solverProfileId, string reason);
    event TaskCancelled(uint256 indexed taskId);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed solverProfileId, uint256 finalBounty);

    event OracleValidationSubmitted(uint256 indexed taskId, uint256 indexed solverProfileId, bool isValid);

    event DisputeRequested(uint256 indexed disputeId, uint256 indexed taskId, uint256 creatorProfileId, uint256 solverProfileId);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool supportCreator);
    event DisputeFinalized(uint256 indexed disputeId, DisputeStatus status, uint256 winningProfileId);

    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    event CarbonOffsetFundsWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressUpdated(address oldOracle, address newOracle);
    event ParameterUpdated(string paramName, uint256 newValue);

    // --- Modifiers ---

    modifier onlyProfileOwner(uint256 _profileId) {
        require(profiles[_profileId].owner == msg.sender, "DARS: Not profile owner");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(profiles[tasks[_taskId].creatorProfileId].owner == msg.sender, "DARS: Not task creator");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedAIOracle, "DARS: Not the trusted AI oracle");
        _;
    }

    modifier isStaker() {
        require(stakers[msg.sender].stakedAmount >= minStakeForArbitration, "DARS: Insufficient stake for action");
        _;
    }

    // --- Constructor ---

    constructor(address _darsTokenAddress, address _profileNFTAddress, address _initialOracle) Ownable(msg.sender) {
        require(_darsTokenAddress != address(0), "DARS: Token address cannot be zero");
        require(_profileNFTAddress != address(0), "DARS: NFT address cannot be zero");
        require(_initialOracle != address(0), "DARS: Oracle address cannot be zero");

        DARSToken = IDARSToken(_darsTokenAddress);
        ProfileNFT = IProfileNFT(_profileNFTAddress);
        trustedAIOracle = _initialOracle;
    }

    // --- I. Core Profile & Reputation Management ---

    /**
     * @notice Registers a new user profile by minting a unique Profile NFT.
     * @param _profileURI The URI pointing to off-chain metadata for the profile.
     * @return profileId The ID of the newly minted profile NFT.
     */
    function registerProfile(string calldata _profileURI) external nonReentrant returns (uint256) {
        require(ProfileNFT.balanceOf(msg.sender) == 0, "DARS: User already has a profile NFT");

        _profileIds.increment();
        uint256 newProfileId = _profileIds.current();

        // Mint a new Profile NFT
        ProfileNFT.mint(msg.sender, _profileURI);

        profiles[newProfileId] = Profile({
            owner: msg.sender,
            reputationScore: 100, // Starting reputation
            lastActiveTimestamp: block.timestamp,
            // skills mapping is implicitly initialized
        });

        emit ProfileRegistered(newProfileId, msg.sender, _profileURI);
        return newProfileId;
    }

    /**
     * @notice Allows a profile owner to update their profile's external metadata URI.
     * @param _profileId The ID of the profile NFT to update.
     * @param _newURI The new URI for the profile's off-chain metadata.
     */
    function updateProfileURI(uint256 _profileId, string calldata _newURI)
        external
        onlyProfileOwner(_profileId)
    {
        ProfileNFT.updateTokenURI(_profileId, _newURI);
        emit ProfileURIUpdated(_profileId, _newURI);
    }

    /**
     * @notice Publicly callable function to decay a profile's reputation based on inactivity.
     *         Anyone can call this, encouraging maintenance of "fresh" scores.
     * @param _profileId The ID of the profile to decay reputation for.
     */
    function decayReputation(uint256 _profileId) external {
        Profile storage profile = profiles[_profileId];
        require(profile.owner != address(0), "DARS: Profile does not exist");

        uint256 daysInactive = (block.timestamp - profile.lastActiveTimestamp) / 1 days;
        if (daysInactive > 0) {
            uint256 decayAmount = daysInactive.mul(reputationDecayRatePerDay);
            if (profile.reputationScore > decayAmount) {
                profile.reputationScore = profile.reputationScore.sub(decayAmount);
            } else {
                profile.reputationScore = 0;
            }
            profile.lastActiveTimestamp = block.timestamp; // Reset last active
            emit ReputationUpdated(_profileId, profile.reputationScore);

            // Optional: Reward the caller for triggering decay (e.g., small fee from treasury)
            // DARSToken.transfer(msg.sender, 1); // Example, need to manage treasury
        }
    }

    /**
     * @notice Retrieves comprehensive details about a specific user's profile.
     * @param _profileId The ID of the profile.
     * @return owner The owner address of the profile.
     * @return reputationScore The current reputation score.
     * @return lastActiveTimestamp The last timestamp the profile was active.
     */
    function getProfileDetails(uint256 _profileId)
        external
        view
        returns (address owner, uint256 reputationScore, uint256 lastActiveTimestamp)
    {
        Profile storage profile = profiles[_profileId];
        require(profile.owner != address(0), "DARS: Profile does not exist");
        return (profile.owner, profile.reputationScore, profile.lastActiveTimestamp);
    }

    // --- II. Skill Management ---

    /**
     * @notice Allows a profile owner to declare a new skill with an initial confidence level.
     * @param _profileId The ID of the profile asserting the skill.
     * @param _skillHash A unique identifier (e.g., keccak256 hash) for the skill.
     * @param _initialConfidence The initial confidence level (0-1000).
     */
    function assertSkill(uint256 _profileId, bytes32 _skillHash, uint256 _initialConfidence)
        external
        onlyProfileOwner(_profileId)
    {
        require(_initialConfidence <= 1000, "DARS: Initial confidence must be <= 1000");
        Profile storage profile = profiles[_profileId];
        profile.skills[_skillHash] = _initialConfidence;
        profile.lastActiveTimestamp = block.timestamp; // Mark profile active
        emit SkillAsserted(_profileId, _skillHash, _initialConfidence);
    }

    /**
     * @notice Enables other users to endorse a profile's asserted skill, boosting its confidence score.
     * @param _profileId The ID of the profile whose skill is being endorsed.
     * @param _skillHash The hash of the skill being endorsed.
     */
    function endorseSkill(uint256 _profileId, bytes32 _skillHash) external {
        require(profiles[_profileId].owner != address(0), "DARS: Profile does not exist");
        require(profiles[_profileId].skills[_skillHash] > 0, "DARS: Skill not asserted by this profile");
        require(!skillEndorsedBy[_profileId][_skillHash][msg.sender], "DARS: Already endorsed this skill");
        require(profiles[_profileId].owner != msg.sender, "DARS: Cannot endorse your own skill");

        Profile storage profile = profiles[_profileId];
        // Increase confidence by a fixed amount, cap at 1000
        profile.skills[_skillHash] = profile.skills[_skillHash].add(50); // Example: +5% confidence
        if (profile.skills[_skillHash] > 1000) {
            profile.skills[_skillHash] = 1000;
        }

        skillEndorsedBy[_profileId][_skillHash][msg.sender] = true;
        profile.lastActiveTimestamp = block.timestamp; // Mark profile active
        emit SkillEndorsed(_profileId, _skillHash, msg.sender);
    }

    /**
     * @notice Queries the current confidence score for a specific skill on a profile.
     * @param _profileId The ID of the profile.
     * @param _skillHash The hash of the skill.
     * @return The confidence score (0-1000).
     */
    function getSkillConfidence(uint256 _profileId, bytes32 _skillHash) external view returns (uint256) {
        return profiles[_profileId].skills[_skillHash];
    }

    // --- III. Task Management (Gig Economy) ---

    /**
     * @notice Creates a new task, specifying requirements, bounty, and validation method.
     *         Requires the creator to have minimum reputation and the bounty approved.
     * @param _taskDescriptionHash IPFS hash or similar for task description.
     * @param _bountyAmount The reward for completing the task (in DARSToken).
     * @param _deadline Timestamp by which the task must be completed.
     * @param _requiredSkills An array of skill hashes required for the task.
     * @param _validationMethod How the task solution will be validated (MANUAL, AI_ORACLE, COMMUNITY_VOTE).
     * @return taskId The ID of the newly created task.
     */
    function createTask(
        bytes32 _taskDescriptionHash,
        uint256 _bountyAmount,
        uint256 _deadline,
        bytes32[] calldata _requiredSkills,
        ValidationMethod _validationMethod
    ) external nonReentrant returns (uint256) {
        uint256 creatorProfileId = ProfileNFT.tokenOfOwnerByIndex(msg.sender, 0); // Assuming one profile per owner
        require(profiles[creatorProfileId].reputationScore >= minReputationForTaskCreation, "DARS: Creator reputation too low");
        require(_bountyAmount > 0, "DARS: Bounty must be greater than zero");
        require(_deadline > block.timestamp, "DARS: Deadline must be in the future");
        if (_validationMethod == ValidationMethod.AI_ORACLE) {
            require(trustedAIOracle != address(0), "DARS: AI Oracle not configured");
        }

        // Calculate fees
        uint256 platformFee = _bountyAmount.mul(platformFeeRate).div(10000); // 10000 basis points
        uint256 carbonOffsetFee = _bountyAmount.mul(carbonOffsetFeeRate).div(10000);
        uint256 totalAmount = _bountyAmount.add(platformFee).add(carbonOffsetFee);

        require(DARSToken.transferFrom(msg.sender, address(this), totalAmount), "DARS: Token transfer failed for bounty + fees");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creatorProfileId: creatorProfileId,
            solverProfileId: 0, // No solver yet
            bountyAmount: _bountyAmount,
            descriptionHash: _taskDescriptionHash,
            solutionHash: 0,
            requiredSkills: _requiredSkills,
            deadline: _deadline,
            status: TaskStatus.PENDING,
            validationMethod: _validationMethod,
            disputeId: 0
        });

        carbonOffsetTreasury = carbonOffsetTreasury.add(carbonOffsetFee);

        profiles[creatorProfileId].lastActiveTimestamp = block.timestamp; // Mark profile active
        emit TaskCreated(newTaskId, creatorProfileId, _bountyAmount, _validationMethod);
        return newTaskId;
    }

    /**
     * @notice A profile owner submits their solution for a task they wish to solve.
     * @param _taskId The ID of the task.
     * @param _solverProfileId The ID of the profile submitting the solution.
     * @param _solutionHash The IPFS hash or similar for the solution.
     */
    function proposeSolution(uint256 _taskId, uint256 _solverProfileId, bytes32 _solutionHash)
        external
        nonReentrant
        onlyProfileOwner(_solverProfileId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.PENDING, "DARS: Task not in pending state");
        require(task.deadline > block.timestamp, "DARS: Task deadline passed");
        require(task.creatorProfileId != _solverProfileId, "DARS: Cannot solve your own task");

        // Basic skill check (can be expanded to check confidence)
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            require(profiles[_solverProfileId].skills[task.requiredSkills[i]] > 0, "DARS: Missing required skill");
        }

        task.solverProfileId = _solverProfileId;
        task.solutionHash = _solutionHash;
        task.status = TaskStatus.SOLUTION_PROPOSED;

        profiles[_solverProfileId].lastActiveTimestamp = block.timestamp; // Mark profile active
        emit SolutionProposed(_taskId, _solverProfileId, _solutionHash);
    }

    /**
     * @notice The task creator accepts a proposed solution, releasing the bounty and updating reputation.
     * @param _taskId The ID of the task.
     * @param _solverProfileId The ID of the solver whose solution is accepted.
     */
    function acceptSolution(uint256 _taskId, uint256 _solverProfileId)
        external
        nonReentrant
        onlyTaskCreator(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.SOLUTION_PROPOSED, "DARS: Task not awaiting manual review");
        require(task.solverProfileId == _solverProfileId, "DARS: Solver ID mismatch");
        require(task.validationMethod == ValidationMethod.MANUAL, "DARS: Task requires different validation method");

        _completeTask(_taskId, _solverProfileId, true);
    }

    /**
     * @notice The task creator rejects a solution, optionally providing a reason.
     * @param _taskId The ID of the task.
     * @param _solverProfileId The ID of the solver whose solution is rejected.
     * @param _reason The reason for rejection.
     */
    function rejectSolution(uint256 _taskId, uint256 _solverProfileId, string calldata _reason)
        external
        nonReentrant
        onlyTaskCreator(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.SOLUTION_PROPOSED, "DARS: Task not awaiting manual review");
        require(task.solverProfileId == _solverProfileId, "DARS: Solver ID mismatch");
        require(task.validationMethod == ValidationMethod.MANUAL, "DARS: Task requires different validation method");

        task.status = TaskStatus.REJECTED; // Revert to rejected state
        task.solverProfileId = 0; // Clear solver, allow others to propose or original solver to resubmit
        task.solutionHash = 0; // Clear solution
        profiles[task.creatorProfileId].lastActiveTimestamp = block.timestamp; // Mark creator active
        emit SolutionRejected(_taskId, _solverProfileId, _reason);
    }

    /**
     * @notice Callable only by a designated AI Oracle to provide validation results for tasks requiring AI review.
     * @param _taskId The ID of the task.
     * @param _solverProfileId The ID of the solver.
     * @param _validationData Any relevant data from the oracle.
     * @param _isValid True if the solution is valid, false otherwise.
     */
    function submitOracleValidation(uint256 _taskId, uint256 _solverProfileId, bytes calldata _validationData, bool _isValid)
        external
        nonReentrant
        onlyOracle()
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.SOLUTION_PROPOSED, "DARS: Task not in proposed state");
        require(task.solverProfileId == _solverProfileId, "DARS: Solver ID mismatch");
        require(task.validationMethod == ValidationMethod.AI_ORACLE, "DARS: Task does not require AI Oracle validation");
        require(task.deadline > block.timestamp, "DARS: Task deadline passed for validation");

        if (_isValid) {
            _completeTask(_taskId, _solverProfileId, true);
        } else {
            task.status = TaskStatus.REJECTED;
            task.solverProfileId = 0;
            task.solutionHash = 0;
            emit SolutionRejected(_taskId, _solverProfileId, "AI Oracle deemed solution invalid");
        }
        emit OracleValidationSubmitted(_taskId, _solverProfileId, _isValid);
    }

    /**
     * @notice Allows the task creator to cancel an unfulfilled task, reclaiming the bounty.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external nonReentrant onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.PENDING || task.status == TaskStatus.REJECTED, "DARS: Task cannot be cancelled in its current state");
        require(task.disputeId == 0, "DARS: Task is currently in dispute");

        // Refund the creator (bounty + platform fee + carbon offset fee)
        uint256 totalRefundAmount = task.bountyAmount.add(task.bountyAmount.mul(platformFeeRate).div(10000)).add(task.bountyAmount.mul(carbonOffsetFeeRate).div(10000));
        require(DARSToken.transfer(profiles[task.creatorProfileId].owner, totalRefundAmount), "DARS: Token refund failed");

        task.status = TaskStatus.CANCELLED;
        profiles[task.creatorProfileId].lastActiveTimestamp = block.timestamp; // Mark creator active
        emit TaskCancelled(_taskId);
    }

    // Internal function to handle task completion
    function _completeTask(uint256 _taskId, uint256 _solverProfileId, bool _success) internal {
        Task storage task = tasks[_taskId];
        Profile storage solverProfile = profiles[_solverProfileId];
        Profile storage creatorProfile = profiles[task.creatorProfileId];

        task.status = TaskStatus.COMPLETED;

        if (_success) {
            // Transfer bounty to solver
            require(DARSToken.transfer(solverProfile.owner, task.bountyAmount), "DARS: Bounty transfer failed");

            // Update reputation: boost solver, neutral for creator
            solverProfile.reputationScore = solverProfile.reputationScore.add(10); // Example: +10 rep for successful task
            creatorProfile.reputationScore = creatorProfile.reputationScore.add(1); // Small boost for successful task completion experience

            emit TaskCompleted(_taskId, _solverProfileId, task.bountyAmount);
        } else {
            // Task failed (e.g., in dispute resolution), creator gets bounty back, solver loses rep
            uint256 totalAmount = task.bountyAmount.add(task.bountyAmount.mul(platformFeeRate).div(10000)); // Excludes carbon offset as it's already deducted
            require(DARSToken.transfer(creatorProfile.owner, totalAmount), "DARS: Creator bounty refund failed");

            solverProfile.reputationScore = solverProfile.reputationScore.sub(20); // Example: -20 rep for failed task
            if (solverProfile.reputationScore < 0) solverProfile.reputationScore = 0;
            emit SolutionRejected(_taskId, _solverProfileId, "Dispute resulted in creator winning");
        }

        solverProfile.lastActiveTimestamp = block.timestamp;
        creatorProfile.lastActiveTimestamp = block.timestamp;
        emit ReputationUpdated(_solverProfileId, solverProfile.reputationScore);
        emit ReputationUpdated(task.creatorProfileId, creatorProfile.reputationScore);
    }


    // --- IV. Decentralized Dispute Resolution ---

    /**
     * @notice Initiates a dispute over a task's outcome, freezing funds and starting a voting period.
     * @param _taskId The ID of the task in dispute.
     * @param _solverProfileId The ID of the solver involved.
     * @param _reason The reason for the dispute.
     */
    function requestDispute(uint256 _taskId, uint256 _solverProfileId, string calldata _reason) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.SOLUTION_PROPOSED || task.status == TaskStatus.REJECTED, "DARS: Task not in a disputable state");
        require(task.solverProfileId == _solverProfileId, "DARS: Solver ID mismatch");
        require(task.disputeId == 0, "DARS: Task already in dispute");
        require(profiles[task.creatorProfileId].owner == msg.sender || profiles[task.solverProfileId].owner == msg.sender, "DARS: Only creator or solver can request dispute");

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            taskId: _taskId,
            creatorProfileId: task.creatorProfileId,
            solverProfileId: task.solverProfileId,
            creationTime: block.timestamp,
            votingEndsTime: block.timestamp + 3 days, // 3 days for voting
            votesForCreator: 0,
            votesForSolver: 0,
            status: DisputeStatus.PENDING_VOTES,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        task.status = TaskStatus.DISPUTED;
        task.disputeId = newDisputeId;

        emit DisputeRequested(newDisputeId, _taskId, task.creatorProfileId, task.solverProfileId);
    }

    /**
     * @notice Arbitrators cast their vote on a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _creatorWins True if voting for the creator, false for the solver.
     */
    function voteOnDispute(uint256 _disputeId, bool _creatorWins) external nonReentrant isStaker {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.PENDING_VOTES, "DARS: Dispute not active for voting");
        require(block.timestamp < dispute.votingEndsTime, "DARS: Voting period has ended");
        require(!dispute.hasVoted[msg.sender], "DARS: Already voted on this dispute");
        require(profiles[dispute.creatorProfileId].owner != msg.sender, "DARS: Creator cannot vote on own dispute");
        require(profiles[dispute.solverProfileId].owner != msg.sender, "DARS: Solver cannot vote on own dispute");

        uint256 votingPower = stakers[msg.sender].stakedAmount; // Voting power based on staked tokens
        require(votingPower > 0, "DARS: Must have stake to vote");

        if (_creatorWins) {
            dispute.votesForCreator = dispute.votesForCreator.add(votingPower);
        } else {
            dispute.votesForSolver = dispute.votesForSolver.add(votingPower);
        }
        dispute.hasVoted[msg.sender] = true;
        emit DisputeVoted(_disputeId, msg.sender, _creatorWins);
    }

    /**
     * @notice Concludes a dispute after the voting period, distributing funds and updating reputation.
     *         Callable by anyone once voting ends.
     * @param _disputeId The ID of the dispute to finalize.
     */
    function finalizeDispute(uint256 _disputeId) external nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.PENDING_VOTES, "DARS: Dispute not in pending votes state");
        require(block.timestamp >= dispute.votingEndsTime, "DARS: Voting period not ended yet");

        Task storage task = tasks[dispute.taskId];
        uint256 winningProfileId;

        if (dispute.votesForCreator > dispute.votesForSolver) {
            dispute.status = DisputeStatus.RESOLVED_CREATOR_WINS;
            winningProfileId = dispute.creatorProfileId;
            _completeTask(dispute.taskId, dispute.solverProfileId, false); // Solver loses, creator gets bounty back
        } else if (dispute.votesForSolver > dispute.votesForCreator) {
            dispute.status = DisputeStatus.RESOLVED_SOLVER_WINS;
            winningProfileId = dispute.solverProfileId;
            _completeTask(dispute.taskId, dispute.solverProfileId, true); // Solver wins, gets bounty
        } else {
            // Tie or no votes - refund both, neutral reputation change
            dispute.status = DisputeStatus.CANCELED;
            uint256 totalAmount = task.bountyAmount.add(task.bountyAmount.mul(platformFeeRate).div(10000)).add(task.bountyAmount.mul(carbonOffsetFeeRate).div(10000));
            require(DARSToken.transfer(profiles[task.creatorProfileId].owner, totalAmount), "DARS: Bounty refund to creator failed on tie");
            emit TaskCancelled(dispute.taskId); // Treat as cancelled
        }

        // Distribute arbitration rewards (simplified: small portion of platform fees to voters)
        // This could be more complex, e.g., prorated by voting power
        // For simplicity, this example just demonstrates the core dispute resolution.
        // Actual reward distribution would require tracking total fees accumulated.

        emit DisputeFinalized(_disputeId, dispute.status, winningProfileId);
    }


    // --- V. Staking & Rewards ---

    /**
     * @notice Allows users to stake `DARSToken` to gain network participation rights.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForParticipation(uint256 _amount) external nonReentrant {
        require(_amount > 0, "DARS: Stake amount must be greater than zero");
        require(DARSToken.transferFrom(msg.sender, address(this), _amount), "DARS: Token transfer failed for staking");

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(_amount);
        totalStakedTokens = totalStakedTokens.add(_amount);

        // Reset unbonding if re-staking
        stakers[msg.sender].unbondingStartTime = 0;
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @notice Initiates the unstaking process, subject to an unbonding period.
     * @param _amount The amount of tokens to unstake.
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "DARS: Unstake amount must be greater than zero");
        require(stakers[msg.sender].stakedAmount >= _amount, "DARS: Not enough staked tokens");
        require(stakers[msg.sender].unbondingStartTime == 0, "DARS: Already in unbonding period");

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.sub(_amount);
        stakers[msg.sender].unbondingStartTime = block.timestamp;
        totalStakedTokens = totalStakedTokens.sub(_amount); // Decrement immediately

        // Transfer funds back after unbonding (caller will need to call claim function)
        // For simplicity, directly transfer here
        require(DARSToken.transfer(msg.sender, _amount), "DARS: Unstake transfer failed"); // Simplified: no actual unbonding queue, just time lock

        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Allows stakers to claim accumulated rewards from network fees and successful arbitration.
     *         (Simplified: In a real system, rewards would accumulate over time).
     *         Here, it just simulates claiming a pre-defined reward for illustration.
     */
    function claimStakingRewards() external nonReentrant {
        // In a real system, rewards would be calculated based on accumulated fees and staker's share/activity.
        // For this example, let's assume a dummy reward logic or integrate with a proper reward system.
        uint256 rewardsAvailable = stakers[msg.sender].stakedAmount / 100; // Example: 1% of current stake as reward
        if (rewardsAvailable > 0) {
            require(DARSToken.transfer(msg.sender, rewardsAvailable), "DARS: Reward transfer failed");
            // Deduct claimed rewards from a theoretical "reward pool" if it existed
            emit StakingRewardsClaimed(msg.sender, rewardsAvailable);
        } else {
            revert("DARS: No rewards available to claim.");
        }
    }


    // --- VI. DAO Governance ---

    /**
     * @notice Allows token holders to propose changes to contract parameters or upgrades.
     *         Requires a minimum stake to propose.
     * @param _callData The encoded function call data for the proposal.
     * @param _targetAddress The address of the contract to call (e.g., this contract for parameter changes).
     * @param _description A description of the proposal.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeGovernanceAction(bytes calldata _callData, address _targetAddress, string calldata _description)
        external
        isStaker
        returns (uint256)
    {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            targetAddress: _targetAddress,
            callData: _callData,
            description: _description,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + 7 days, // 7 days for voting
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.ACTIVE,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /**
     * @notice Enables token holders to vote for or against an active proposal.
     *         Voting power is proportional to staked tokens.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for", false for "against".
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external isStaker {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "DARS: Proposal not active for voting");
        require(block.timestamp < proposal.votingDeadline, "DARS: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DARS: Already voted on this proposal");

        uint256 votingPower = stakers[msg.sender].stakedAmount;
        require(votingPower > 0, "DARS: Must have stake to vote");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a successfully passed governance proposal.
     *         Callable by anyone once voting ends and threshold met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "DARS: Proposal not active");
        require(block.timestamp >= proposal.votingDeadline, "DARS: Voting period not ended");
        require(proposal.votesFor > proposal.votesAgainst, "DARS: Proposal not passed");
        require(proposal.votesFor.add(proposal.votesAgainst) >= totalStakedTokens.div(10), "DARS: Quorum not met (e.g., 10% of total stake)"); // Example quorum: 10% of total staked tokens

        proposal.status = ProposalStatus.SUCCEEDED; // Mark as succeeded before execution

        // Execute the proposed action
        (bool success, ) = proposal.targetAddress.call(proposal.callData);
        require(success, "DARS: Proposal execution failed");

        proposal.status = ProposalStatus.EXECUTED; // Mark as executed after successful call
        emit ProposalExecuted(_proposalId);
    }

    // --- VII. System Parameters & Utilities ---

    /**
     * @notice DAO-controlled function to update the address of the trusted AI Oracle.
     *         This function would typically be called via a governance proposal.
     * @param _newOracleAddress The new address for the AI Oracle.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner { // Should be callable by DAO in a real system
        require(_newOracleAddress != address(0), "DARS: New oracle address cannot be zero");
        address oldOracle = trustedAIOracle;
        trustedAIOracle = _newOracleAddress;
        emit OracleAddressUpdated(oldOracle, _newOracleAddress);
    }

    /**
     * @notice DAO-controlled function to update the reputation decay rate.
     * @param _newRate The new decay rate (points per day).
     */
    function setReputationDecayRate(uint256 _newRate) public onlyOwner { // Should be callable by DAO
        reputationDecayRatePerDay = _newRate;
        emit ParameterUpdated("reputationDecayRate", _newRate);
    }

    /**
     * @notice DAO-controlled function to update the minimum reputation for task creation.
     * @param _newMinReputation The new minimum reputation score.
     */
    function setMinReputationForTaskCreation(uint256 _newMinReputation) public onlyOwner { // Should be callable by DAO
        minReputationForTaskCreation = _newMinReputation;
        emit ParameterUpdated("minReputationForTaskCreation", _newMinReputation);
    }

    /**
     * @notice DAO-controlled function to update the minimum stake for arbitration.
     * @param _newMinStake The new minimum stake amount.
     */
    function setMinStakeForArbitration(uint256 _newMinStake) public onlyOwner { // Should be callable by DAO
        minStakeForArbitration = _newMinStake;
        emit ParameterUpdated("minStakeForArbitration", _newMinStake);
    }

    /**
     * @notice DAO-controlled function to update the unbonding period for staking.
     * @param _newPeriodSeconds The new unbonding period in seconds.
     */
    function setUnbondingPeriod(uint256 _newPeriodSeconds) public onlyOwner { // Should be callable by DAO
        unbondingPeriodSeconds = _newPeriodSeconds;
        emit ParameterUpdated("unbondingPeriodSeconds", _newPeriodSeconds);
    }

    /**
     * @notice DAO-controlled function to update the platform fee rate.
     * @param _newRate The new rate in basis points (e.g., 50 for 0.5%).
     */
    function setPlatformFeeRate(uint256 _newRate) public onlyOwner { // Should be callable by DAO
        require(_newRate <= 1000, "DARS: Platform fee rate too high (max 10%)"); // Max 10%
        platformFeeRate = _newRate;
        emit ParameterUpdated("platformFeeRate", _newRate);
    }

    /**
     * @notice DAO-controlled function to update the carbon offset fee rate.
     * @param _newRate The new rate in basis points (e.g., 10 for 0.1%).
     */
    function setCarbonOffsetFeeRate(uint256 _newRate) public onlyOwner { // Should be callable by DAO
        require(_newRate <= 100, "DARS: Carbon offset fee rate too high (max 1%)"); // Max 1%
        carbonOffsetFeeRate = _newRate;
        emit ParameterUpdated("carbonOffsetFeeRate", _newRate);
    }

    /**
     * @notice Allows the DAO to withdraw accumulated funds from the carbon offset treasury.
     *         This would typically send funds to a verified carbon offset project address.
     * @param _amount The amount to withdraw.
     */
    function withdrawCarbonOffsetFunds(uint256 _amount) external onlyOwner { // Should be callable by DAO
        require(_amount > 0, "DARS: Amount must be greater than zero");
        require(carbonOffsetTreasury >= _amount, "DARS: Insufficient funds in carbon offset treasury");

        carbonOffsetTreasury = carbonOffsetTreasury.sub(_amount);
        // This address would be a pre-approved, audited carbon offset project contract or multisig.
        // For this example, sending to owner, but in reality, it's a dedicated fund.
        require(DARSToken.transfer(owner(), _amount), "DARS: Carbon offset fund withdrawal failed");
        emit CarbonOffsetFundsWithdrawn(owner(), _amount);
    }
}
```