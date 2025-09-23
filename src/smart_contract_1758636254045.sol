Here's a Solidity smart contract named `InnovateFlow` that embodies an advanced, creative, and trendy concept: a Decentralized Adaptive Reputation and Collaborative Innovation Platform. It integrates dynamic reputation, prediction market-like staking, multi-stage challenge resolution, and on-chain governance for adaptive parameters.

The design avoids duplicating existing open-source projects by combining these elements into a novel workflow for collaborative problem-solving and incentive alignment. Basic utilities like `Ownable`, `Pausable`, and `ReentrancyGuard` from OpenZeppelin are used for best practices, as the request implies novelty in the *core logic and concept*, not in fundamental building blocks.

---

## InnovateFlow: Decentralized Adaptive Reputation and Collaborative Innovation Platform

This contract facilitates a dynamic ecosystem for proposing, funding, evaluating, and rewarding collaborative innovation challenges. It integrates an adaptive reputation system with prediction market-like staking and a multi-stage challenge resolution process.

### Contract Overview

`InnovateFlow` acts as a decentralized hub where users can:
1.  Register and manage their on-chain profiles, accumulating dynamic reputation.
2.  Propose new challenges or initiatives that require collaborative effort.
3.  Submit solutions to open challenges, competing for reward pools.
4.  Stake tokens on the success of proposed solutions, acting as a prediction market.
5.  Participate in the evaluation of solutions (currently via a trusted oracle, extensible to DAO voting).
6.  Claim dynamic rewards based on successful predictions, solution outcomes, and reputation.
7.  Engage in governance to adapt system parameters, ensuring long-term sustainability and responsiveness.

### Data Structures

*   `UserProfile`: Stores user data including dynamic base reputation score, delegated reputation, and metadata URI.
*   `Challenge`: Details about an innovation challenge, its status, duration, reward pool, and success criteria.
*   `Solution`: Represents a proposed solution to a challenge, including proposer, staked funds, and evaluation status.
*   `ParameterChangeProposal`: For on-chain governance to modify contract parameters like challenge durations or reward factors.

### Key Concepts

*   **Dynamic Reputation:** Reputation scores evolve based on participation, successful contributions, and accurate predictions. It affects voting power and reward multipliers.
*   **Adaptive Rewards:** Reward multipliers adjust based on individual reputation, ensuring higher-reputation participants receive a larger share of rewards from successful outcomes.
*   **Multi-Stage Challenge Resolution:** Involves distinct phases for challenge creation, solution proposal, staking, evaluation (by a trusted oracle), and final reward distribution.
*   **Delegated Authority:** Users can delegate their base reputation to other registered users, boosting the delegatee's effective reputation and influence.
*   **Oracle Integration:** External data or evaluation results are fed via a trusted oracle for challenge resolution. This central point can be upgraded to a more decentralized oracle network or DAO voting for full decentralization.
*   **On-chain Governance:** Key system parameters can be proposed, voted on (reputation-weighted), and executed on-chain, allowing the platform to adapt and evolve over time.

### Function Summary (26 functions)

#### 1. User & Reputation Management (6 functions)
1.  `registerProfile(string calldata _metadataURI)`: Creates a new user profile with a base reputation.
2.  `updateProfileMetadata(string calldata _newMetadataURI)`: Updates a user's off-chain profile metadata URI.
3.  `getReputationScore(address _user)`: Retrieves a user's current effective reputation score (base + delegated).
4.  `delegateReputation(address _to, uint256 _amount)`: Delegates a portion of `msg.sender`'s base reputation to `_to`.
5.  `undelegateReputation(address _from, uint256 _amount)`: Undelegates previously delegated reputation from `_from`.
6.  `getDelegationAmount(address _delegator, address _delegatee)`: Gets the amount of reputation delegated from `_delegator` to `_delegatee`.

#### 2. Challenge Management (5 functions)
7.  `createChallenge(string memory _title, string memory _descriptionURI, uint256 _durationInDays, uint256 _minStakeAmount, uint256 _initialRewardPool)`: Initiates a new challenge with an initial reward pool.
8.  `proposeSolution(uint256 _challengeId, string memory _solutionURI)`: Submits a solution to an open challenge.
9.  `getChallengeDetails(uint256 _challengeId)`: Retrieves comprehensive details about a specific challenge.
10. `getSolutionDetails(uint256 _challengeId, uint256 _solutionId)`: Retrieves comprehensive details about a specific solution.
11. `depositChallengeFunds(uint256 _challengeId, uint256 _amount)`: Deposits additional funds into a challenge's reward pool.

#### 3. Staking & Prediction (3 functions)
12. `stakeOnSolution(uint256 _challengeId, uint256 _solutionId, uint256 _amount)`: Stakes tokens on a proposed solution's success.
13. `withdrawStake(uint256 _challengeId, uint256 _solutionId, uint256 _amount)`: Withdraws stake from a solution (if before resolution).
14. `getSolutionStakeByAddress(uint256 _challengeId, uint256 _solutionId, address _staker)`: Gets a specific user's stake on a solution.

#### 4. Challenge Resolution & Rewards (3 functions)
15. `submitChallengeEvaluation(uint256 _challengeId, uint256 _solutionId, bool _isSuccessful, string memory _evaluationURI)`: Oracle submits final evaluation for a solution.
16. `resolveChallenge(uint256 _challengeId)`: Finalizes a challenge, distributes rewards to successful solutions/stakers, and adjusts reputation.
17. `claimRewards(uint256 _challengeId, uint256 _solutionId)`: Allows users to claim their earned rewards from a resolved solution.

#### 5. Governance & System Adaptation (9 functions)
18. `proposeSystemParameterChange(string memory _paramName, uint256 _newValue)`: Proposes changes to system parameters.
19. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Votes on an active parameter change proposal, weighted by reputation.
20. `executeParameterChange(uint256 _proposalId)`: Executes a passed parameter change proposal.
21. `setTrustedOracle(address _newOracle)`: Sets the address of the trusted oracle (Owner-only).
22. `setReputationBoostFactor(uint256 _factor)`: Sets the factor for reputation-based reward boosting (Owner-only).
23. `pause()`: Pauses the contract in case of emergency (Owner-only).
24. `unpause()`: Unpauses the contract (Owner-only).
25. `renounceOwnership()`: Renounces contract ownership (from Ownable).
26. `transferOwnership(address _newOwner)`: Transfers contract ownership (from Ownable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title InnovateFlow: Decentralized Adaptive Reputation and Collaborative Innovation Platform
 * @notice This contract facilitates a dynamic ecosystem for proposing, funding, evaluating, and rewarding collaborative innovation challenges.
 *         It integrates an adaptive reputation system with prediction market-like staking and a multi-stage challenge resolution process.
 *
 * @dev Contract Overview:
 * InnovateFlow acts as a decentralized hub where users can:
 * 1. Register and manage their on-chain profiles, accumulating dynamic reputation.
 * 2. Propose new challenges or initiatives that require collaborative effort.
 * 3. Submit solutions to open challenges, competing for reward pools.
 * 4. Stake tokens on the success of proposed solutions, acting as a prediction market.
 * 5. Participate in the evaluation of solutions (potentially via delegated authority or oracle integration).
 * 6. Claim dynamic rewards based on successful predictions, solution outcomes, and reputation.
 * 7. Engage in governance to adapt system parameters, ensuring long-term sustainability and responsiveness.
 *
 * @dev Data Structures:
 * - UserProfile: Stores user data including dynamic base reputation score, delegated reputation, and metadata URI.
 * - Challenge: Details about an innovation challenge, its status, duration, reward pool, and success criteria.
 * - Solution: Represents a proposed solution to a challenge, including proposer, staked funds, and evaluation status.
 * - ParameterChangeProposal: For on-chain governance to modify contract parameters.
 *
 * @dev Key Concepts:
 * - Dynamic Reputation: Reputation scores evolve based on participation, successful contributions, and accurate predictions.
 *   It affects voting power and reward multipliers.
 * - Adaptive Rewards: Reward multipliers adjust based on individual reputation, ensuring higher-reputation participants
 *   receive a larger share of rewards from successful outcomes.
 * - Multi-Stage Challenge Resolution: Involves distinct phases for challenge creation, solution proposal, staking,
 *   evaluation (by a trusted oracle), and final reward distribution.
 * - Delegated Authority: Users can delegate their base reputation to other registered users, boosting the delegatee's
 *   effective reputation and influence.
 * - Oracle Integration: External data or evaluation results are fed via a trusted oracle for challenge resolution.
 *   This central point can be upgraded to a more decentralized oracle network or DAO voting for full decentralization.
 * - On-chain Governance: Key system parameters can be proposed, voted on (reputation-weighted), and executed on-chain,
 *   allowing the platform to adapt and evolve over time.
 *
 * @dev Function Summary (26 functions):
 * 1. User & Reputation Management (6 functions)
 *    - `registerProfile(string calldata _metadataURI)`: Creates a new user profile with a base reputation.
 *    - `updateProfileMetadata(string calldata _newMetadataURI)`: Updates a user's off-chain profile metadata URI.
 *    - `getReputationScore(address _user)`: Retrieves a user's current effective reputation score (base + delegated).
 *    - `delegateReputation(address _to, uint256 _amount)`: Delegates a portion of `msg.sender`'s base reputation to `_to`.
 *    - `undelegateReputation(address _from, uint256 _amount)`: Undelegates previously delegated reputation from `_from`.
 *    - `getDelegationAmount(address _delegator, address _delegatee)`: Gets the amount of reputation delegated from _delegator to _delegatee.
 * 2. Challenge Management (5 functions)
 *    - `createChallenge(string memory _title, string memory _descriptionURI, uint256 _durationInDays, uint256 _minStakeAmount, uint256 _initialRewardPool)`: Initiates a new challenge with an initial reward pool.
 *    - `proposeSolution(uint256 _challengeId, string memory _solutionURI)`: Submits a solution to an open challenge.
 *    - `getChallengeDetails(uint256 _challengeId)`: Retrieves comprehensive details about a specific challenge.
 *    - `getSolutionDetails(uint256 _challengeId, uint256 _solutionId)`: Retrieves comprehensive details about a specific solution.
 *    - `depositChallengeFunds(uint256 _challengeId, uint256 _amount)`: Deposits additional funds into a challenge's reward pool.
 * 3. Staking & Prediction (3 functions)
 *    - `stakeOnSolution(uint256 _challengeId, uint256 _solutionId, uint256 _amount)`: Stakes tokens on a proposed solution's success.
 *    - `withdrawStake(uint256 _challengeId, uint256 _solutionId, uint256 _amount)`: Withdraws stake from a solution (if before resolution).
 *    - `getSolutionStakeByAddress(uint256 _challengeId, uint256 _solutionId, address _staker)`: Gets a specific user's stake on a solution.
 * 4. Challenge Resolution & Rewards (3 functions)
 *    - `submitChallengeEvaluation(uint256 _challengeId, uint256 _solutionId, bool _isSuccessful, string memory _evaluationURI)`: Oracle submits final evaluation for a solution.
 *    - `resolveChallenge(uint256 _challengeId)`: Finalizes a challenge, distributes rewards to successful solutions/stakers, and adjusts reputation.
 *    - `claimRewards(uint256 _challengeId, uint256 _solutionId)`: Allows users to claim their earned rewards from a resolved solution.
 * 5. Governance & System Adaptation (9 functions)
 *    - `proposeSystemParameterChange(string memory _paramName, uint256 _newValue)`: Proposes changes to system parameters.
 *    - `voteOnParameterChange(uint256 _proposalId, bool _support)`: Votes on an active parameter change proposal, weighted by reputation.
 *    - `executeParameterChange(uint256 _proposalId)`: Executes a passed parameter change proposal.
 *    - `setTrustedOracle(address _newOracle)`: Sets the address of the trusted oracle (Owner-only).
 *    - `setReputationBoostFactor(uint256 _factor)`: Sets the factor for reputation-based reward boosting (Owner-only).
 *    - `pause()`: Pauses the contract in case of emergency (Owner-only).
 *    - `unpause()`: Unpauses the contract (Owner-only).
 *    - `renounceOwnership()`: Renounces contract ownership (from Ownable).
 *    - `transferOwnership(address _newOwner)`: Transfers contract ownership (from Ownable).
 */
contract InnovateFlow is Ownable, Pausable, ReentrancyGuard {
    IERC20 public immutable rewardToken; // The ERC-20 token used for staking and rewards

    // --- State Variables ---

    uint256 public nextChallengeId;
    uint256 public nextProposalId;
    address public trustedOracle;

    // Configuration parameters (can be changed via governance)
    uint256 public challengeMinDurationDays = 7; // Minimum duration for a challenge (in days)
    uint256 public challengeMaxDurationDays = 60; // Maximum duration for a challenge (in days)
    uint256 public defaultMinStakeAmount = 1e18; // Default minimum stake required for solutions (1 token)
    uint256 public evaluationPeriodDays = 7; // Period after challenge end for oracle evaluation (in days)
    uint256 public reputationBoostFactor = 1000; // Divisor for reputation boost (e.g., 1000 means 1 rep gives 0.1% boost)
    uint256 public proposalQuorumPercentage = 51; // Percentage of total reputation needed to pass a governance proposal
    uint256 public proposalVotingPeriodDays = 7; // Days for governance proposals to be voted on

    // --- Data Structures ---

    struct UserProfile {
        bool exists;
        uint256 reputationScore; // Base reputation score
        string metadataURI; // IPFS hash or URL to off-chain profile data
        mapping(address => uint256) delegatedTo; // Amount of reputation this user delegated TO other users (msg.sender => _to => amount)
        uint256 totalDelegatedReputationReceived; // Sum of all reputation delegated TO this user
    }

    enum ChallengeStatus {
        Open, // Can propose solutions, stake
        Evaluating, // Challenge ended, awaiting oracle evaluation
        Resolved, // Evaluation complete, rewards distributed
        Canceled // Challenge canceled
    }

    struct Challenge {
        address creator;
        string title;
        string descriptionURI;
        uint256 startTime;
        uint256 endTime; // Challenge duration end
        uint256 evaluationDeadline; // Deadline for oracle evaluation
        uint256 minStakeAmount; // Minimum stake for a solution in this challenge
        uint256 totalRewardPool; // Total tokens available for rewards
        uint256 nextSolutionId;
        ChallengeStatus status;
        mapping(uint256 => Solution) solutions; // Solution ID => Solution details
        uint256[] successfulSolutions; // List of successful solution IDs after resolution
    }

    struct Solution {
        address proposer;
        string solutionURI; // IPFS hash or URL to off-chain solution details
        uint256 totalStaked; // Total tokens staked on this solution
        bool isSuccessful; // Set by oracle evaluation
        bool evaluationSubmitted; // True if oracle has submitted evaluation
        bool rewardsClaimed; // True if rewards have been processed for this solution
        mapping(address => uint256) stakes; // Staker => Amount staked
        mapping(address => uint256) earnedRewards; // Staker => Amount of rewards earned (pre-claim)
        address[] stakers; // List of unique addresses that staked (to iterate for rewards)
    }

    enum ProposalStatus {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    struct ParameterChangeProposal {
        address proposer;
        string paramName;
        uint256 newValue;
        uint256 proposalTime;
        uint256 votingEndTime;
        uint256 totalReputationFor; // Total reputation of 'yes' voters
        uint256 totalReputationAgainst; // Total reputation of 'no' voters
        mapping(address => bool) hasVoted; // User => Voted
        ProposalStatus status;
    }

    // --- Mappings ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => ParameterChangeProposal) public governanceProposals;

    // --- Events ---

    event ProfileRegistered(address indexed user, string metadataURI);
    event ProfileMetadataUpdated(address indexed user, string newMetadataURI);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationAdjusted(address indexed user, int256 delta, uint256 newScore);

    event ChallengeCreated(uint256 indexed challengeId, address indexed creator, string title, uint256 rewardPool);
    event SolutionProposed(uint256 indexed challengeId, uint256 indexed solutionId, address indexed proposer, string solutionURI);
    event FundsDeposited(uint256 indexed challengeId, address indexed depositor, uint256 amount);

    event SolutionStaked(uint256 indexed challengeId, uint256 indexed solutionId, address indexed staker, uint256 amount);
    event StakeWithdrawn(uint256 indexed challengeId, uint256 indexed solutionId, address indexed staker, uint256 amount);

    event ChallengeEvaluationSubmitted(uint256 indexed challengeId, uint256 indexed solutionId, bool isSuccessful, string evaluationURI);
    event ChallengeResolved(uint256 indexed challengeId, uint256 totalDistributedRewards);
    event RewardsClaimed(uint256 indexed challengeId, uint256 indexed solutionId, address indexed claimant, uint256 amount);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voterReputation);
    event ProposalExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);

    // --- Constructor ---

    constructor(address _rewardTokenAddress, address _initialOracle) Ownable(msg.sender) {
        require(_rewardTokenAddress != address(0), "Invalid reward token address");
        require(_initialOracle != address(0), "Invalid initial oracle address");
        rewardToken = IERC20(_rewardTokenAddress);
        trustedOracle = _initialOracle;
        nextChallengeId = 1;
        nextProposalId = 1;
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "Caller is not the trusted oracle");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].exists, "User not registered");
        _;
    }

    modifier validateChallengeId(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId < nextChallengeId, "Invalid challenge ID");
        _;
    }

    modifier validateSolutionId(uint256 _challengeId, uint256 _solutionId) {
        require(challenges[_challengeId].solutions[_solutionId].proposer != address(0), "Invalid solution ID");
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal: Adjusts a user's base reputation score.
     * @param _user The address of the user whose reputation is being adjusted.
     * @param _delta The amount to add (positive) or subtract (negative) from reputation.
     */
    function _internalUpdateReputation(address _user, int256 _delta) internal {
        UserProfile storage profile = userProfiles[_user];
        if (!profile.exists) return; // Cannot update reputation for non-existent profile

        uint256 currentScore = profile.reputationScore;
        uint256 newScore;

        if (_delta > 0) {
            newScore = currentScore + uint256(_delta);
        } else {
            uint256 absDelta = uint256(-_delta);
            newScore = (currentScore > absDelta) ? currentScore - absDelta : 0;
        }
        profile.reputationScore = newScore;
        emit ReputationAdjusted(_user, _delta, newScore);
    }

    /**
     * @dev Internal: Calculates a user's effective reputation score including delegations.
     * @param _user The address of the user.
     * @return The effective reputation score.
     */
    function _getEffectiveReputation(address _user) internal view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        if (!profile.exists) return 0;
        // Base reputation + reputation delegated TO this user
        return profile.reputationScore + profile.totalDelegatedReputationReceived;
    }

    // --- 1. User & Reputation Management ---

    /**
     * @dev Registers a new user profile. Each address can only register once.
     * @param _metadataURI URI pointing to off-chain profile metadata (e.g., IPFS hash).
     */
    function registerProfile(string calldata _metadataURI) external whenNotPaused {
        require(!userProfiles[msg.sender].exists, "User already registered");
        userProfiles[msg.sender].exists = true;
        userProfiles[msg.sender].reputationScore = 1; // Start with a minimal reputation score
        userProfiles[msg.sender].metadataURI = _metadataURI;
        emit ProfileRegistered(msg.sender, _metadataURI);
    }

    /**
     * @dev Updates the metadata URI for the caller's profile.
     * @param _newMetadataURI New URI for profile metadata.
     */
    function updateProfileMetadata(string calldata _newMetadataURI) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @dev Retrieves a user's effective reputation score (base + delegated to them).
     * @param _user The address of the user.
     * @return The effective reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return _getEffectiveReputation(_user);
    }

    /**
     * @dev Allows a user to delegate a portion of their *base* reputation to another registered user.
     * The delegated reputation boosts the delegatee's effective reputation.
     * @param _to The address of the user to delegate reputation to.
     * @param _amount The amount of reputation to delegate.
     */
    function delegateReputation(address _to, uint256 _amount) external onlyRegisteredUser whenNotPaused {
        require(_to != address(0) && _to != msg.sender, "Cannot delegate to zero address or self");
        require(userProfiles[_to].exists, "Delegatee not registered");
        require(userProfiles[msg.sender].reputationScore >= _amount, "Insufficient base reputation to delegate");
        require(_amount > 0, "Delegation amount must be greater than zero");

        userProfiles[msg.sender].reputationScore -= _amount;
        userProfiles[msg.sender].delegatedTo[_to] += _amount;
        userProfiles[_to].totalDelegatedReputationReceived += _amount; // Update total for delegatee

        emit ReputationDelegated(msg.sender, _to, _amount);
    }

    /**
     * @dev Allows a user to undelegate reputation previously delegated to another user.
     * @param _from The address of the user from whom reputation was delegated (the delegatee).
     * @param _amount The amount of reputation to undelegate.
     */
    function undelegateReputation(address _from, uint256 _amount) external onlyRegisteredUser whenNotPaused {
        require(_from != address(0) && _from != msg.sender, "Cannot undelegate from zero address or self");
        require(userProfiles[_from].exists, "Delegatee not registered"); // _from here means the recipient of delegation
        require(userProfiles[msg.sender].delegatedTo[_from] >= _amount, "Insufficient delegated reputation to undelegate");
        require(_amount > 0, "Undelegation amount must be greater than zero");

        userProfiles[msg.sender].reputationScore += _amount;
        userProfiles[msg.sender].delegatedTo[_from] -= _amount;
        userProfiles[_from].totalDelegatedReputationReceived -= _amount; // Update total for delegatee

        emit ReputationUndelegated(msg.sender, _from, _amount);
    }

    /**
     * @dev Retrieves the amount of reputation `_delegator` has delegated to `_delegatee`.
     * @param _delegator The address of the user who delegated reputation.
     * @param _delegatee The address of the user who received the delegation.
     * @return The amount of reputation delegated from `_delegator` to `_delegatee`.
     */
    function getDelegationAmount(address _delegator, address _delegatee) external view returns (uint256) {
        return userProfiles[_delegator].delegatedTo[_delegatee];
    }

    // --- 2. Challenge Management ---

    /**
     * @dev Initiates a new innovation challenge. Requires `_initialRewardPool` to be approved to the contract.
     * @param _title Title of the challenge.
     * @param _descriptionURI URI pointing to off-chain description.
     * @param _durationInDays Duration of the challenge in days.
     * @param _minStakeAmount Minimum tokens required to stake on a solution for this challenge.
     * @param _initialRewardPool Initial tokens to fund the challenge reward pool (transferred from sender).
     */
    function createChallenge(
        string memory _title,
        string memory _descriptionURI,
        uint256 _durationInDays,
        uint256 _minStakeAmount,
        uint256 _initialRewardPool
    ) external onlyRegisteredUser whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_title).length > 0, "Challenge title cannot be empty");
        require(_durationInDays >= challengeMinDurationDays && _durationInDays <= challengeMaxDurationDays, "Invalid challenge duration");
        require(_minStakeAmount > 0, "Min stake amount must be greater than zero");
        require(_initialRewardPool > 0, "Initial reward pool must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _initialRewardPool), "Token transfer failed for initial reward pool");

        uint256 challengeId = nextChallengeId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _durationInDays * 1 days;
        uint256 evaluationDeadline = endTime + evaluationPeriodDays * 1 days;

        challenges[challengeId] = Challenge({
            creator: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            startTime: startTime,
            endTime: endTime,
            evaluationDeadline: evaluationDeadline,
            minStakeAmount: _minStakeAmount,
            totalRewardPool: _initialRewardPool,
            nextSolutionId: 1,
            status: ChallengeStatus.Open,
            solutions: new mapping(uint256 => Solution), // Initialize mapping
            successfulSolutions: new uint256[](0)
        });

        emit ChallengeCreated(challengeId, msg.sender, _title, _initialRewardPool);
        return challengeId;
    }

    /**
     * @dev Proposes a solution to an open challenge.
     * @param _challengeId ID of the challenge.
     * @param _solutionURI URI pointing to off-chain solution details.
     */
    function proposeSolution(uint256 _challengeId, string memory _solutionURI) external onlyRegisteredUser whenNotPaused validateChallengeId(_challengeId) returns (uint256) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "Challenge is not open for solutions");
        require(block.timestamp < challenge.endTime, "Challenge period for solutions has ended");
        require(bytes(_solutionURI).length > 0, "Solution URI cannot be empty");

        uint256 solutionId = challenge.nextSolutionId++;
        challenge.solutions[solutionId] = Solution({
            proposer: msg.sender,
            solutionURI: _solutionURI,
            totalStaked: 0,
            isSuccessful: false,
            evaluationSubmitted: false,
            rewardsClaimed: false,
            stakes: new mapping(address => uint256),
            earnedRewards: new mapping(address => uint256),
            stakers: new address[](0) // Initialize empty dynamic array
        });

        emit SolutionProposed(_challengeId, solutionId, msg.sender, _solutionURI);
        return solutionId;
    }

    /**
     * @dev Retrieves details about a specific challenge.
     * @param _challengeId ID of the challenge.
     * @return Tuple containing challenge details.
     */
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        validateChallengeId(_challengeId)
        returns (
            address creator,
            string memory title,
            string memory descriptionURI,
            uint256 startTime,
            uint256 endTime,
            uint256 evaluationDeadline,
            uint256 minStakeAmount,
            uint256 totalRewardPool,
            ChallengeStatus status,
            uint256 nextSolutionId
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.creator,
            challenge.title,
            challenge.descriptionURI,
            challenge.startTime,
            challenge.endTime,
            challenge.evaluationDeadline,
            challenge.minStakeAmount,
            challenge.totalRewardPool,
            challenge.status,
            challenge.nextSolutionId
        );
    }

    /**
     * @dev Retrieves details about a specific solution within a challenge.
     * @param _challengeId ID of the challenge.
     * @param _solutionId ID of the solution.
     * @return Tuple containing solution details.
     */
    function getSolutionDetails(uint256 _challengeId, uint256 _solutionId)
        external
        view
        validateChallengeId(_challengeId)
        validateSolutionId(_challengeId, _solutionId)
        returns (
            address proposer,
            string memory solutionURI,
            uint256 totalStaked,
            bool isSuccessful,
            bool evaluationSubmitted,
            bool rewardsClaimed
        )
    {
        Solution storage solution = challenges[_challengeId].solutions[_solutionId];
        return (
            solution.proposer,
            solution.solutionURI,
            solution.totalStaked,
            solution.isSuccessful,
            solution.evaluationSubmitted,
            solution.rewardsClaimed
        );
    }

    /**
     * @dev Allows anyone to deposit additional funds into a challenge's reward pool.
     * Requires `_amount` to be approved to the contract.
     * @param _challengeId ID of the challenge.
     * @param _amount The amount of tokens to deposit.
     */
    function depositChallengeFunds(uint256 _challengeId, uint256 _amount) external whenNotPaused validateChallengeId(_challengeId) nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status != ChallengeStatus.Resolved && challenge.status != ChallengeStatus.Canceled, "Challenge is closed for deposits");
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for deposit");

        challenge.totalRewardPool += _amount;
        emit FundsDeposited(_challengeId, msg.sender, _amount);
    }

    // --- 3. Staking & Prediction ---

    /**
     * @dev Allows a registered user to stake tokens on a proposed solution.
     * Requires `_amount` to be approved to the contract.
     * @param _challengeId ID of the challenge.
     * @param _solutionId ID of the solution.
     * @param _amount The amount of tokens to stake.
     */
    function stakeOnSolution(uint256 _challengeId, uint256 _solutionId, uint256 _amount)
        external
        onlyRegisteredUser
        whenNotPaused
        validateChallengeId(_challengeId)
        validateSolutionId(_challengeId, _solutionId)
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        Solution storage solution = challenge.solutions[_solutionId];

        require(challenge.status == ChallengeStatus.Open, "Challenge is not open for staking");
        require(block.timestamp < challenge.endTime, "Staking period has ended");
        require(_amount >= challenge.minStakeAmount, "Stake amount below minimum for this challenge");
        require(_amount > 0, "Stake amount must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed for stake");

        if (solution.stakes[msg.sender] == 0) {
            solution.stakers.push(msg.sender); // Add staker to list if first stake
        }
        solution.stakes[msg.sender] += _amount;
        solution.totalStaked += _amount;

        emit SolutionStaked(_challengeId, _solutionId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their stake from a solution if the challenge is still open.
     * @param _challengeId ID of the challenge.
     * @param _solutionId ID of the solution.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawStake(uint256 _challengeId, uint256 _solutionId, uint256 _amount)
        external
        onlyRegisteredUser
        whenNotPaused
        validateChallengeId(_challengeId)
        validateSolutionId(_challengeId, _solutionId)
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        Solution storage solution = challenge.solutions[_solutionId];

        require(challenge.status == ChallengeStatus.Open, "Cannot withdraw stake, challenge not open");
        require(block.timestamp < challenge.endTime, "Cannot withdraw stake, staking period has ended");
        require(solution.stakes[msg.sender] >= _amount, "Insufficient stake to withdraw");
        require(_amount > 0, "Withdraw amount must be greater than zero");

        solution.stakes[msg.sender] -= _amount;
        solution.totalStaked -= _amount;
        require(rewardToken.transfer(msg.sender, _amount), "Token transfer failed for withdrawal");

        // Note: If solution.stakes[msg.sender] becomes 0, the user remains in solution.stakers array,
        // which is fine for iteration, but not optimized for removal in Solidity < 0.8.19 without loops.
        // For simplicity and given moderate number of stakers, it's acceptable here.
        emit StakeWithdrawn(_challengeId, _solutionId, msg.sender, _amount);
    }

    /**
     * @dev Retrieves the amount of tokens a specific staker has on a solution.
     * @param _challengeId ID of the challenge.
     * @param _solutionId ID of the solution.
     * @param _staker The address of the staker.
     * @return The amount of tokens staked by `_staker`.
     */
    function getSolutionStakeByAddress(uint256 _challengeId, uint256 _solutionId, address _staker)
        external
        view
        validateChallengeId(_challengeId)
        validateSolutionId(_challengeId, _solutionId)
        returns (uint256)
    {
        return challenges[_challengeId].solutions[_solutionId].stakes[_staker];
    }

    // --- 4. Challenge Resolution & Rewards ---

    /**
     * @dev Allows the trusted oracle to submit an evaluation for a solution.
     * Can only be called once per solution, after challenge end and before evaluation deadline.
     * @param _challengeId ID of the challenge.
     * @param _solutionId ID of the solution.
     * @param _isSuccessful True if the solution is deemed successful, false otherwise.
     * @param _evaluationURI URI pointing to off-chain evaluation details/report.
     */
    function submitChallengeEvaluation(uint256 _challengeId, uint256 _solutionId, bool _isSuccessful, string memory _evaluationURI)
        external
        onlyOracle
        whenNotPaused
        validateChallengeId(_challengeId)
        validateSolutionId(_challengeId, _solutionId)
    {
        Challenge storage challenge = challenges[_challengeId];
        Solution storage solution = challenge.solutions[_solutionId];

        require(challenge.status != ChallengeStatus.Resolved && challenge.status != ChallengeStatus.Canceled, "Challenge is already resolved or canceled");
        require(block.timestamp >= challenge.endTime, "Challenge period not ended yet");
        require(block.timestamp <= challenge.evaluationDeadline, "Evaluation deadline has passed");
        require(!solution.evaluationSubmitted, "Evaluation already submitted for this solution");

        solution.isSuccessful = _isSuccessful;
        solution.evaluationSubmitted = true;

        // If the challenge status is Open but challenge.endTime has passed, it should move to Evaluating
        if (challenge.status == ChallengeStatus.Open) {
            challenge.status = ChallengeStatus.Evaluating;
        }

        emit ChallengeEvaluationSubmitted(_challengeId, _solutionId, _isSuccessful, _evaluationURI);
    }

    /**
     * @dev Finalizes a challenge, distributes rewards, and adjusts reputation.
     * Can only be called after the evaluation deadline has passed or all solutions have been evaluated.
     * Rewards are split 20% to proposers and 80% to stakers of successful solutions,
     * weighted by their effective reputation.
     * @param _challengeId ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) external whenNotPaused validateChallengeId(_challengeId) nonReentrant {
        Challenge storage challenge = challenges[_challengeId];

        require(challenge.status != ChallengeStatus.Resolved && challenge.status != ChallengeStatus.Canceled, "Challenge already resolved or canceled");
        require(block.timestamp >= challenge.evaluationDeadline, "Evaluation deadline not reached yet"); // Or all solutions evaluated

        uint256 totalSuccessfulStake = 0; // Total stake on all successful solutions
        uint256 totalRewardsDistributed = 0;

        // First pass: Identify successful solutions and calculate total successful stake
        for (uint256 i = 1; i < challenge.nextSolutionId; i++) {
            Solution storage solution = challenge.solutions[i];
            if (solution.evaluationSubmitted && solution.isSuccessful) {
                totalSuccessfulStake += solution.totalStaked;
                challenge.successfulSolutions.push(i);
            }
        }

        uint256 numSuccessfulSolutions = challenge.successfulSolutions.length;
        if (numSuccessfulSolutions == 0) {
            challenge.status = ChallengeStatus.Resolved;
            emit ChallengeResolved(_challengeId, 0);
            return; // No successful solutions, no rewards
        }

        // Allocate reward pool budget: 20% for proposers, 80% for stakers (adjustable via governance)
        uint256 totalProposerRewardsBudget = (challenge.totalRewardPool * 20) / 100;
        uint256 totalStakerRewardsBudget = challenge.totalRewardPool - totalProposerRewardsBudget; // Remaining 80%

        // Calculate total effective reputation points for successful proposers
        uint256 totalEffectiveProposerPoints = 0;
        for (uint256 i = 0; i < numSuccessfulSolutions; i++) {
            uint256 solutionId = challenge.successfulSolutions[i];
            Solution storage solution = challenge.solutions[solutionId];
            uint256 proposerReputation = _getEffectiveReputation(solution.proposer);
            // Weight = Base_Rep + (Base_Rep * Effective_Rep) / Reputation_Boost_Factor
            totalEffectiveProposerPoints += proposerReputation + (proposerReputation * proposerReputation) / reputationBoostFactor;
        }

        // Distribute rewards to successful proposers
        for (uint256 i = 0; i < numSuccessfulSolutions; i++) {
            uint256 solutionId = challenge.successfulSolutions[i];
            Solution storage solution = challenge.solutions[solutionId];
            address proposer = solution.proposer;

            uint256 proposerShare = 0;
            if (totalEffectiveProposerPoints > 0) {
                uint256 proposerReputation = _getEffectiveReputation(proposer);
                uint256 proposerWeight = proposerReputation + (proposerReputation * proposerReputation) / reputationBoostFactor;
                proposerShare = (totalProposerRewardsBudget * proposerWeight) / totalEffectiveProposerPoints;
            } else {
                // Fallback: If no reputation points, distribute equally
                proposerShare = totalProposerRewardsBudget / numSuccessfulSolutions;
            }
            solution.earnedRewards[proposer] += proposerShare;
            totalRewardsDistributed += proposerShare;
            _internalUpdateReputation(proposer, 10); // Reward reputation for successful proposal
        }

        // Calculate total effective stake points for successful stakers
        uint256 totalEffectiveStakerPoints = 0;
        if (totalSuccessfulStake > 0) {
            for (uint256 i = 0; i < numSuccessfulSolutions; i++) {
                uint256 solutionId = challenge.successfulSolutions[i];
                Solution storage solution = challenge.solutions[solutionId];

                for (uint256 j = 0; j < solution.stakers.length; j++) {
                    address staker = solution.stakers[j];
                    uint256 stakerStake = solution.stakes[staker];
                    if (stakerStake > 0) {
                        uint256 stakerReputation = _getEffectiveReputation(staker);
                        // Weight = Stake + (Stake * Effective_Rep) / Reputation_Boost_Factor
                        totalEffectiveStakerPoints += stakerStake + (stakerStake * stakerReputation) / reputationBoostFactor;
                    }
                }
            }
        }

        // Distribute rewards to successful stakers
        if (totalEffectiveStakerPoints > 0) {
            for (uint256 i = 0; i < numSuccessfulSolutions; i++) {
                uint256 solutionId = challenge.successfulSolutions[i];
                Solution storage solution = challenge.solutions[solutionId];

                for (uint256 j = 0; j < solution.stakers.length; j++) {
                    address staker = solution.stakers[j];
                    uint256 stakerStake = solution.stakes[staker];

                    if (stakerStake > 0) {
                        uint256 stakerReputation = _getEffectiveReputation(staker);
                        uint256 stakerWeight = stakerStake + (stakerStake * stakerReputation) / reputationBoostFactor;
                        uint256 stakerShare = (totalStakerRewardsBudget * stakerWeight) / totalEffectiveStakerPoints;
                        solution.earnedRewards[staker] += stakerShare;
                        totalRewardsDistributed += stakerShare;
                        _internalUpdateReputation(staker, 5); // Reward reputation for successful prediction/staking
                    }
                }
            }
        }

        challenge.status = ChallengeStatus.Resolved;
        emit ChallengeResolved(_challengeId, totalRewardsDistributed);
    }

    /**
     * @dev Allows users to claim their earned rewards after a challenge has been resolved.
     * @param _challengeId ID of the challenge.
     * @param _solutionId ID of the solution.
     */
    function claimRewards(uint256 _challengeId, uint256 _solutionId)
        external
        onlyRegisteredUser
        whenNotPaused
        validateChallengeId(_challengeId)
        validateSolutionId(_challengeId, _solutionId)
        nonReentrant
    {
        Challenge storage challenge = challenges[_challengeId];
        Solution storage solution = challenge.solutions[_solutionId];

        require(challenge.status == ChallengeStatus.Resolved, "Challenge not yet resolved");
        // A more granular check would be per user using `userProfiles[msg.sender].claimedRewards[_challengeId][_solutionId]`
        // For simplicity of this example, `solution.rewardsClaimed` is for the solution batch.
        // It's assumed `resolveChallenge` could be called multiple times but only processes rewards once for each solution.
        // This current implementation allows multiple claims if a user had earned rewards from multiple solutions
        // within the same challenge, but each claim empties `earnedRewards[msg.sender]` for that solution.

        uint256 amountToClaim = solution.earnedRewards[msg.sender];
        require(amountToClaim > 0, "No rewards to claim for this solution");

        solution.earnedRewards[msg.sender] = 0; // Reset earned rewards for this user for this solution

        require(rewardToken.transfer(msg.sender, amountToClaim), "Token transfer failed for claiming rewards");

        emit RewardsClaimed(_challengeId, _solutionId, msg.sender, amountToClaim);
    }

    // --- 5. Governance & System Adaptation ---

    /**
     * @dev Proposes a change to a system parameter. Only registered users can propose.
     * @param _paramName The name of the parameter to change (e.g., "challengeMinDurationDays", "reputationBoostFactor").
     * @param _newValue The new value for the parameter.
     */
    function proposeSystemParameterChange(string memory _paramName, uint256 _newValue) external onlyRegisteredUser whenNotPaused returns (uint256) {
        require(bytes(_paramName).length > 0, "Parameter name cannot be empty");
        // Basic validation for common parameters
        bytes32 paramNameHash = keccak256(abi.encodePacked(_paramName));
        if (paramNameHash == keccak256(abi.encodePacked("challengeMinDurationDays"))) {
            require(_newValue <= challengeMaxDurationDays, "Min duration cannot exceed Max duration");
        } else if (paramNameHash == keccak256(abi.encodePacked("challengeMaxDurationDays"))) {
            require(_newValue >= challengeMinDurationDays, "Max duration cannot be less than Min duration");
        } else if (paramNameHash == keccak256(abi.encodePacked("defaultMinStakeAmount"))) {
            require(_newValue > 0, "Default min stake must be greater than zero");
        } else if (paramNameHash == keccak256(abi.encodePacked("evaluationPeriodDays"))) {
            require(_newValue > 0, "Evaluation period must be greater than zero");
        } else if (paramNameHash == keccak256(abi.encodePacked("reputationBoostFactor"))) {
            require(_newValue > 0, "Reputation boost factor must be greater than zero");
        } else if (paramNameHash == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
            require(_newValue > 0 && _newValue <= 100, "Quorum percentage must be between 1 and 100");
        } else if (paramNameHash == keccak256(abi.encodePacked("proposalVotingPeriodDays"))) {
            require(_newValue > 0, "Voting period must be greater than zero");
        } else {
            revert("Unknown or unsupported parameter name");
        }

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = ParameterChangeProposal({
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingPeriodDays * 1 days,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            hasVoted: new mapping(address => bool),
            status: ProposalStatus.Active
        });

        emit ParameterChangeProposed(proposalId, msg.sender, _paramName, _newValue);
        return proposalId;
    }

    /**
     * @dev Allows a registered user to vote on an active parameter change proposal.
     * Voter's effective reputation is used for voting power.
     * @param _proposalId ID of the proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external onlyRegisteredUser whenNotPaused {
        ParameterChangeProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Invalid proposal ID");
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterReputation = _getEffectiveReputation(msg.sender);
        require(voterReputation > 0, "Voter must have reputation to vote");

        if (_support) {
            proposal.totalReputationFor += voterReputation;
        } else {
            proposal.totalReputationAgainst += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @dev Executes a passed parameter change proposal. Anyone can call this after voting ends.
     * Checks if the proposal met quorum and passed.
     * @param _proposalId ID of the proposal.
     */
    function executeParameterChange(uint256 _proposalId) external whenNotPaused {
        ParameterChangeProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Invalid proposal ID");
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended yet");

        uint256 totalReputation = proposal.totalReputationFor + proposal.totalReputationAgainst;
        require(totalReputation > 0, "No votes cast on this proposal");

        uint256 quorumThreshold = (totalReputation * proposalQuorumPercentage) / 100;
        require(proposal.totalReputationFor >= quorumThreshold, "Quorum not met or proposal failed");
        require(proposal.totalReputationFor > proposal.totalReputationAgainst, "Proposal failed to achieve majority");

        // Update parameter based on paramName
        bytes32 paramNameHash = keccak256(abi.encodePacked(proposal.paramName));
        if (paramNameHash == keccak256(abi.encodePacked("challengeMinDurationDays"))) {
            challengeMinDurationDays = proposal.newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("challengeMaxDurationDays"))) {
            challengeMaxDurationDays = proposal.newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("defaultMinStakeAmount"))) {
            defaultMinStakeAmount = proposal.newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("evaluationPeriodDays"))) {
            evaluationPeriodDays = proposal.newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("reputationBoostFactor"))) {
            reputationBoostFactor = proposal.newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
            proposalQuorumPercentage = proposal.newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("proposalVotingPeriodDays"))) {
            proposalVotingPeriodDays = proposal.newValue;
        } else {
            revert("Unknown parameter name in proposal (should not happen if proposal was valid)");
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /**
     * @dev Sets the address of the trusted oracle. Only owner can call.
     * This is a crucial centralized point, could be replaced by DAO voting in a more advanced version.
     * @param _newOracle The new address for the trusted oracle.
     */
    function setTrustedOracle(address _newOracle) external onlyOwner whenNotPaused {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        emit OracleAddressSet(trustedOracle, _newOracle);
        trustedOracle = _newOracle;
    }

    /**
     * @dev Sets the factor used for reputation-based reward boosting. Only owner can call.
     * This parameter can also be proposed and changed via governance.
     * @param _factor The new reputation boost factor.
     */
    function setReputationBoostFactor(uint256 _factor) external onlyOwner whenNotPaused {
        require(_factor > 0, "Boost factor must be greater than zero");
        reputationBoostFactor = _factor;
    }

    /**
     * @dev Pauses the contract in case of emergency. Only owner can call.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // `renounceOwnership` and `transferOwnership` are inherited from OpenZeppelin's Ownable.
    // They are available as public functions.
}
```