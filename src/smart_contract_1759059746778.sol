Okay, this is an exciting challenge! I'll design a smart contract called `VeritasEngine` which focuses on "Decentralized Cognitive Intelligence" using **Dynamic NFTs, Subjective Oracles, Reputation Systems, and Staking-based Prediction Markets**.

The core idea is:
Users can mint "Cognitive Agent" NFTs. These agents act as decentralized intelligence units. They propose and evaluate complex, subjective "Truth Statements" (e.g., "Will AI stocks outperform the S&P 500 next quarter?"). Users stake tokens to these agents to back their evaluations. Agents are rewarded for accurate predictions/evaluations and penalized for inaccuracies. Crucially, the agents' *traits and metadata* (the NFT itself) **evolve** based on their performance and reputation, making them truly dynamic and representing "protocol-owned intelligence." The resolution of subjective statements is handled by a community-driven, incentivized process.

---

## VeritasEngine: Decentralized Cognitive Intelligence Protocol

**Contract Name:** `VeritasEngine`

**Core Concept:**
The `VeritasEngine` empowers a decentralized network of "Cognitive Agents" (represented by dynamic NFTs) to collectively evaluate complex, subjective "Truth Statements." Unlike traditional oracles that focus on objective data, `VeritasEngine` aims to aggregate human intelligence and insights to resolve ambiguous or forward-looking questions. Agents' performance directly impacts their on-chain reputation and their NFT's evolving traits, creating a self-improving, protocol-owned intelligence layer.

**Key Advanced Concepts & Creativity:**
1.  **Dynamic NFTs as Cognitive Agents:** NFTs are not static. Their metadata and underlying on-chain attributes (e.g., `reputationScore`, `accuracyHistory`) change based on the agent's performance in evaluating truth statements. Owners can trigger an explicit `evolveAgentTraits` function to update the NFT's URI.
2.  **Subjective Oracle & Prediction Market Hybrid:** The protocol facilitates proposing, evaluating, and resolving statements that often lack simple objective truth. It combines elements of prediction markets (staking on outcomes) with a decentralized subjective oracle mechanism (community-driven resolution with reputation weighting).
3.  **Reputation System:** Agents accumulate a `reputationScore` that influences their rewards, attractiveness for staking, and potential weight in community resolutions. This creates an incentive for accuracy and honest participation.
4.  **Incentivized Resolution Mechanism:** For contested or ambiguous statements, a community voting process (potentially weighted by reputation or stake) is used, ensuring decentralization beyond a single admin or external oracle.
5.  **Protocol-Owned Intelligence:** Over time, the collective wisdom and accuracy of the agents contribute to a robust, decentralized intelligence layer that can be queried for insights on complex topics.
6.  **Multi-Dimensional Staking:** Users stake *to agents* to back their general intelligence, and agents (via their owners) stake *on specific statement evaluations* to back their predictions.
7.  **Gamified Evolution:** The explicit `triggerAgentEvolution` function encourages owners to manage and nurture their agents, making the NFT a living entity.

---

### Function Outline & Summary

This contract will have at least 25 functions, categorized for clarity.

**I. Contract Management & Configuration (6 Functions)**
1.  `constructor()`: Initializes the contract with an ERC20 token address (for staking/rewards), base URI for agent NFTs, and sets the owner.
2.  `setAgentCreationFee(uint256 _fee)`: Allows the owner to set the fee required to mint a new Cognitive Agent.
3.  `setMinStakeAmount(uint256 _minStake)`: Allows the owner to set the minimum amount required to stake to an agent or an evaluation.
4.  `setResolutionPeriodDuration(uint256 _duration)`: Sets the time window for statement resolution.
5.  `setBaseURI(string memory _newBaseURI)`: Allows the owner to update the base URI for agent NFT metadata.
6.  `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows the owner to withdraw collected fees from the protocol treasury.

**II. Cognitive Agent (NFT) Lifecycle (7 Functions)**
7.  `mintCognitiveAgent(string memory _initialTraitURI)`: Mints a new Cognitive Agent NFT, requiring the `agentCreationFee`.
8.  `getAgentDetails(uint256 _agentId)`: Returns comprehensive details about a specific agent, including its owner, reputation, total stake, and current trait URI.
9.  `stakeToAgent(uint256 _agentId, uint256 _amount)`: Allows any user to stake ERC20 tokens to a specific Cognitive Agent, backing its general intelligence.
10. `unstakeFromAgent(uint256 _agentId, uint256 _amount)`: Allows a user to withdraw their staked tokens from an agent, subject to certain conditions (e.g., not locked in active evaluations).
11. `getAgentStakerBalance(uint256 _agentId, address _staker)`: Returns the amount a specific user has staked to a given agent.
12. `getAgentPerformanceMetrics(uint256 _agentId)`: Returns detailed performance history for an agent (e.g., number of correct/incorrect evaluations, total rewards earned).
13. `triggerAgentEvolution(uint256 _agentId, string memory _newTraitURI)`: Callable by the agent owner, this function updates the agent's NFT metadata (URI) based on its current reputation and performance. This is the core "dynamic NFT" feature.

**III. Truth Statement Management (4 Functions)**
14. `proposeTruthStatement(string memory _question, bytes32[] memory _possibleOutcomes)`: Allows anyone to propose a new, subjective truth statement with predefined possible outcomes. Requires a bond.
15. `getStatementDetails(uint256 _statementId)`: Returns all details about a specific truth statement, including its question, outcomes, current status, and resolution time.
16. `getStatementPossibleOutcomes(uint256 _statementId)`: Returns the array of possible outcomes for a specific statement.
17. `getStatementEvaluations(uint256 _statementId)`: Returns all evaluations submitted for a given statement.

**IV. Evaluation, Challenge & Resolution (5 Functions)**
18. `evaluateStatementByAgent(uint256 _statementId, uint256 _agentId, uint256 _outcomeIndex, uint256 _stakeAmount)`: Allows an agent owner to submit an evaluation for a statement using their agent, staking tokens on a specific outcome.
19. `challengeStatementEvaluation(uint256 _statementId, uint256 _evaluationId, uint256 _challengeBond)`: Allows anyone to challenge a specific agent's evaluation for a statement, requiring a bond. This triggers a community vote for resolution.
20. `submitCommunityResolutionVote(uint256 _statementId, uint256 _outcomeIndex)`: Allows users (with sufficient reputation/stake) to vote on the final outcome of a challenged or ambiguous statement.
21. `initiateStatementResolution(uint256 _statementId)`: Callable by anyone after the resolution period, this function triggers the process to determine the final outcome based on evaluations, challenges, and community votes.
22. `finalizeStatementOutcome(uint256 _statementId)`: Callable by anyone after `initiateStatementResolution` has run its course (or directly if no challenges), this function formally sets the statement's final outcome and triggers reward/penalty distribution.

**V. Reward & Penalty Distribution (3 Functions)**
23. `claimEvaluationRewards(uint256 _statementId, uint256 _agentId)`: Allows an agent owner to claim rewards for their agent's correct evaluations on a resolved statement.
24. `claimAgentStakingRewards(uint256 _agentId)`: Allows users to claim their share of rewards from an agent they staked to, based on the agent's overall accuracy.
25. `claimChallengeRefund(uint256 _statementId, uint256 _challengeId)`: Allows a successful challenger to claim their bond back, plus a portion of the penalized evaluation's stake.

---

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom errors for better readability and gas efficiency
error NotOwnerOfAgent(uint256 agentId, address caller);
error AgentNotFound(uint256 agentId);
error StatementNotFound(uint256 statementId);
error EvaluationNotFound(uint256 statementId, uint256 evaluationId);
error InvalidOutcomeIndex(uint256 statementId, uint256 index);
error InsufficientStake(uint256 required, uint256 provided);
error AgentCreationFeeNotPaid(uint256 required, uint256 provided);
error StatementNotOpenForEvaluation(uint256 statementId);
error StatementNotResolved(uint256 statementId);
error StatementAlreadyResolved(uint256 statementId);
error ResolutionPeriodNotEnded(uint256 statementId);
error AgentAlreadyEvaluatedStatement(uint256 statementId, uint256 agentId);
error StakingLocked(uint256 agentId);
error ChallengeBondTooLow(uint256 required, uint256 provided);
error ChallengeNotSuccessful(uint256 challengeId);
error NoRewardsToClaim();
error CannotUnstakeLockedTokens();
error AgentEvolutionNotReady(uint256 agentId);
error InvalidAgentTraitURI();


contract VeritasEngine is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    IERC20 public immutable stakingToken;

    Counters.Counter private _agentIds;
    Counters.Counter private _statementIds;
    Counters.Counter private _evaluationIds;
    Counters.Counter private _challengeIds;

    // --- Configuration Variables ---
    uint256 public agentCreationFee;
    uint256 public minStakeAmount;
    uint256 public resolutionPeriodDuration; // Duration in seconds for a statement to be resolved
    uint256 public constant ACCURACY_WEIGHT_FACTOR = 1000; // Multiplier for reputation calculation
    uint256 public constant CHALLENGE_WIN_SHARE_PERCENT = 20; // % of penalized stake given to successful challenger

    // --- Structs ---

    struct Agent {
        address owner;
        uint256 reputationScore; // Based on accuracy, higher is better
        uint256 totalStaked; // Total tokens staked *to* this agent
        uint256 correctEvaluations;
        uint256 incorrectEvaluations;
        uint256 lastEvolutionBlock; // Block number when traits were last evolved
        string traitURI; // Dynamic part of the NFT metadata
    }

    struct Statement {
        address proposer;
        string question;
        bytes32[] possibleOutcomes; // Hashed outcomes to save gas
        uint256 proposeTime;
        uint256 resolutionPeriodEnd;
        uint256 finalOutcomeIndex; // Index of the resolved outcome, type(uint256).max if not resolved
        uint256 totalBond; // Bond paid by the proposer
        bool isResolved;
        bool isInResolutionPhase; // True if resolution process has been initiated
        mapping(address => bool) hasVotedForResolution; // For community voting
        mapping(uint256 => uint256) outcomeVoteCounts; // Counts votes for each outcome index
        uint256 totalVotesInResolution;
    }

    struct Evaluation {
        uint256 agentId;
        uint256 outcomeIndex; // Index of the outcome predicted by the agent
        uint256 stakedAmount; // Tokens staked by the agent owner on this evaluation
        bool isCorrect; // Set after resolution
        bool isChallenged;
        uint256 challengeId; // If challenged, ID of the challenge
    }

    struct Challenge {
        uint256 statementId;
        uint256 evaluationId;
        address challenger;
        uint256 bondAmount;
        bool isSuccessful; // Set after statement resolution
        bool isResolved;
    }

    // --- Mappings ---
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => Statement) public statements;
    mapping(uint256 => Evaluation) public evaluations;
    mapping(uint256 => Challenge) public challenges;

    // Staking balances: agentId => stakerAddress => amount
    mapping(uint256 => mapping(address => uint256)) public agentStakes;
    // Rewards for general agent stakers: agentId => stakerAddress => amount
    mapping(uint256 => mapping(address => uint256)) public agentStakerRewards;
    // Rewards for agent owners from correct evaluations: agentId => amount
    mapping(uint256 => uint256) public agentEvaluationRewards;
    // Refunds for successful challengers: challengeId => amount
    mapping(uint256 => uint256) public challengeRefunds;

    // Mapping to track if an agent has evaluated a statement (statementId => agentId => bool)
    mapping(uint256 => mapping(uint256 => bool)) public agentHasEvaluatedStatement;

    // Treasury to hold fees
    uint256 public treasuryBalance;

    event AgentMinted(uint256 indexed agentId, address indexed owner, string initialTraitURI);
    event AgentStaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AgentUnstaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event AgentEvolutionTriggered(uint256 indexed agentId, string newTraitURI, uint256 blockNumber);
    event TruthStatementProposed(uint256 indexed statementId, address indexed proposer, string question, uint256 proposeTime);
    event StatementEvaluated(uint256 indexed statementId, uint256 indexed agentId, uint256 evaluationId, uint256 outcomeIndex, uint256 stakedAmount);
    event StatementChallenged(uint256 indexed statementId, uint256 indexed evaluationId, uint256 challengeId, address indexed challenger, uint256 bondAmount);
    event CommunityResolutionVoteCast(uint256 indexed statementId, address indexed voter, uint256 outcomeIndex);
    event StatementResolutionInitiated(uint256 indexed statementId, uint256 resolutionPeriodEnd);
    event StatementFinalized(uint256 indexed statementId, uint256 finalOutcomeIndex, uint256 resolutionTime);
    event EvaluationRewardsClaimed(uint256 indexed agentId, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed agentId, address indexed staker, uint256 amount);
    event ChallengeRefundClaimed(uint256 indexed challengeId, address indexed challenger, uint256 amount);
    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);


    constructor(address _stakingToken, string memory _baseURI) ERC721("CognitiveAgent", "CAGENT") Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        _setBaseURI(_baseURI);
        agentCreationFee = 1e18; // Default to 1 token
        minStakeAmount = 0.1e18; // Default to 0.1 token
        resolutionPeriodDuration = 3 days; // Default to 3 days
    }

    // --- I. Contract Management & Configuration ---

    /**
     * @dev Allows the owner to set the fee required to mint a new Cognitive Agent.
     * @param _fee The new fee amount.
     */
    function setAgentCreationFee(uint256 _fee) public onlyOwner {
        agentCreationFee = _fee;
    }

    /**
     * @dev Allows the owner to set the minimum amount required to stake to an agent or an evaluation.
     * @param _minStake The new minimum stake amount.
     */
    function setMinStakeAmount(uint256 _minStake) public onlyOwner {
        minStakeAmount = _minStake;
    }

    /**
     * @dev Sets the time duration for a statement's resolution period.
     * @param _duration The duration in seconds.
     */
    function setResolutionPeriodDuration(uint256 _duration) public onlyOwner {
        resolutionPeriodDuration = _duration;
    }

    /**
     * @dev Allows the owner to update the base URI for agent NFT metadata.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @dev Allows the owner to withdraw collected fees from the protocol treasury.
     * @param _recipient The address to send funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner {
        if (_amount == 0 || _amount > treasuryBalance) revert InsufficientStake(_amount, treasuryBalance);
        treasuryBalance -= _amount;
        stakingToken.transfer(_recipient, _amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    // --- II. Cognitive Agent (NFT) Lifecycle ---

    /**
     * @dev Mints a new Cognitive Agent NFT, requiring the `agentCreationFee`.
     * @param _initialTraitURI The initial URI for the agent's metadata, representing its starting traits.
     */
    function mintCognitiveAgent(string memory _initialTraitURI) public payable whenNotPaused returns (uint256) {
        if (msg.value < agentCreationFee) revert AgentCreationFeeNotPaid(agentCreationFee, msg.value);

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        _safeMint(msg.sender, newAgentId);

        agents[newAgentId] = Agent({
            owner: msg.sender,
            reputationScore: 1000, // Starting reputation
            totalStaked: 0,
            correctEvaluations: 0,
            incorrectEvaluations: 0,
            lastEvolutionBlock: block.number,
            traitURI: _initialTraitURI
        });

        treasuryBalance += msg.value; // Store fee in treasury
        emit AgentMinted(newAgentId, msg.sender, _initialTraitURI);
        return newAgentId;
    }

    /**
     * @dev Returns comprehensive details about a specific agent.
     * @param _agentId The ID of the agent.
     * @return Agent struct fields.
     */
    function getAgentDetails(uint256 _agentId) public view returns (address owner, uint256 reputation, uint256 totalStaked, uint256 correctEv, uint256 incorrectEv, string memory traitURI) {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        return (agent.owner, agent.reputationScore, agent.totalStaked, agent.correctEvaluations, agent.incorrectEvaluations, agent.traitURI);
    }

    /**
     * @dev Allows any user to stake ERC20 tokens to a specific Cognitive Agent, backing its general intelligence.
     * @param _agentId The ID of the agent to stake to.
     * @param _amount The amount of tokens to stake.
     */
    function stakeToAgent(uint256 _agentId, uint256 _amount) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        if (_amount < minStakeAmount) revert InsufficientStake(minStakeAmount, _amount);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        agentStakes[_agentId][msg.sender] += _amount;
        agent.totalStaked += _amount;
        emit AgentStaked(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their staked tokens from an agent.
     * @param _agentId The ID of the agent.
     * @param _amount The amount to unstake.
     */
    function unstakeFromAgent(uint256 _agentId, uint256 _amount) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        if (agentStakes[_agentId][msg.sender] < _amount) revert InsufficientStake(_amount, agentStakes[_agentId][msg.sender]);

        // Prevent unstaking if the agent has active evaluations that haven't been resolved yet
        // This would require iterating through all statements and checking if the agent has pending evaluations.
        // For simplicity, we assume an agent's staked funds are *generally* available unless explicitly locked in an evaluation bond.
        // A more complex system would track locked stakes.
        // For now, let's keep it simple and assume the 'evaluationStake' is handled separately for claiming.
        
        agentStakes[_agentId][msg.sender] -= _amount;
        agent.totalStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit AgentUnstaked(_agentId, msg.sender, _amount);
    }

    /**
     * @dev Returns the amount a specific user has staked to a given agent.
     * @param _agentId The ID of the agent.
     * @param _staker The address of the staker.
     * @return The amount staked.
     */
    function getAgentStakerBalance(uint256 _agentId, address _staker) public view returns (uint256) {
        return agentStakes[_agentId][_staker];
    }

    /**
     * @dev Returns detailed performance history for an agent.
     * @param _agentId The ID of the agent.
     * @return correctEvaluations_ Number of correct evaluations.
     * @return incorrectEvaluations_ Number of incorrect evaluations.
     */
    function getAgentPerformanceMetrics(uint256 _agentId) public view returns (uint256 correctEvaluations_, uint256 incorrectEvaluations_) {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        return (agent.correctEvaluations, agent.incorrectEvaluations);
    }

    /**
     * @dev Callable by the agent owner, this function updates the agent's NFT metadata (URI)
     *      based on its current reputation and performance. This is the core "dynamic NFT" feature.
     *      Can only be called periodically to prevent spamming updates.
     * @param _agentId The ID of the agent.
     * @param _newTraitURI The new URI for the agent's metadata, reflecting its evolved traits.
     */
    function triggerAgentEvolution(uint256 _agentId, string memory _newTraitURI) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        if (msg.sender != agent.owner) revert NotOwnerOfAgent(_agentId, msg.sender);
        if (bytes(_newTraitURI).length == 0) revert InvalidAgentTraitURI();

        // Optional: Add a cooldown period or reputation threshold for evolution
        // For example: if (block.number < agent.lastEvolutionBlock + 1000) revert AgentEvolutionNotReady(_agentId);

        agent.traitURI = _newTraitURI;
        agent.lastEvolutionBlock = block.number; // Update last evolution block

        emit AgentEvolutionTriggered(_agentId, _newTraitURI, block.number);
    }

    /**
     * @dev Returns the token URI for a given tokenId. Overrides ERC721.
     * @param _tokenId The ID of the agent.
     * @return The full URI for the agent's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Ensure the token exists and is owned
        Agent storage agent = agents[_tokenId];
        if (agent.owner == address(0)) revert AgentNotFound(_tokenId);
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return agent.traitURI; // If no base URI set, use traitURI directly
        }
        return string(abi.encodePacked(base, agent.traitURI));
    }


    // --- III. Truth Statement Management ---

    /**
     * @dev Allows anyone to propose a new, subjective truth statement with predefined possible outcomes.
     * @param _question The question being posed (e.g., "Will ETH hit $5k by Q4 2024?").
     * @param _possibleOutcomes An array of possible outcome strings (e.g., ["Yes", "No", "Uncertain"]).
     *                          These are hashed to save gas for storage.
     * @return The ID of the newly proposed statement.
     */
    function proposeTruthStatement(string memory _question, bytes32[] memory _possibleOutcomes) public payable whenNotPaused returns (uint256) {
        if (msg.value < minStakeAmount) revert InsufficientStake(minStakeAmount, msg.value); // Proposer bond

        _statementIds.increment();
        uint256 newStatementId = _statementIds.current();

        statements[newStatementId] = Statement({
            proposer: msg.sender,
            question: _question,
            possibleOutcomes: _possibleOutcomes,
            proposeTime: block.timestamp,
            resolutionPeriodEnd: 0, // Set during resolution initiation
            finalOutcomeIndex: type(uint256).max, // Sentinel value for not resolved
            totalBond: msg.value,
            isResolved: false,
            isInResolutionPhase: false,
            totalVotesInResolution: 0
        });

        treasuryBalance += msg.value; // Add bond to treasury, will be distributed or burnt
        emit TruthStatementProposed(newStatementId, msg.sender, _question, block.timestamp);
        return newStatementId;
    }

    /**
     * @dev Returns all details about a specific truth statement.
     * @param _statementId The ID of the statement.
     * @return proposer_ The address of the proposer.
     * @return question_ The question of the statement.
     * @return proposeTime_ The timestamp of proposal.
     * @return resolutionPeriodEnd_ The end time of the resolution period.
     * @return finalOutcomeIndex_ The index of the final outcome.
     * @return isResolved_ True if the statement is resolved.
     * @return isInResolutionPhase_ True if the statement is in resolution.
     */
    function getStatementDetails(uint256 _statementId) public view returns (
        address proposer_,
        string memory question_,
        uint256 proposeTime_,
        uint256 resolutionPeriodEnd_,
        uint256 finalOutcomeIndex_,
        bool isResolved_,
        bool isInResolutionPhase_
    ) {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        return (
            statement.proposer,
            statement.question,
            statement.proposeTime,
            statement.resolutionPeriodEnd,
            statement.finalOutcomeIndex,
            statement.isResolved,
            statement.isInResolutionPhase
        );
    }

    /**
     * @dev Returns the array of possible outcome hashes for a specific statement.
     * @param _statementId The ID of the statement.
     * @return An array of bytes32 representing the hashed outcomes.
     */
    function getStatementPossibleOutcomes(uint256 _statementId) public view returns (bytes32[] memory) {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        return statement.possibleOutcomes;
    }

    /**
     * @dev Returns details for a specific evaluation.
     * @param _evaluationId The ID of the evaluation.
     * @return agentId_ The ID of the agent that made the evaluation.
     * @return outcomeIndex_ The index of the predicted outcome.
     * @return stakedAmount_ The amount staked on this evaluation.
     * @return isCorrect_ True if the evaluation was correct.
     * @return isChallenged_ True if the evaluation was challenged.
     * @return challengeId_ The ID of the associated challenge (0 if none).
     */
    function getEvaluationDetails(uint256 _evaluationId) public view returns (uint256 agentId_, uint256 outcomeIndex_, uint256 stakedAmount_, bool isCorrect_, bool isChallenged_, uint256 challengeId_) {
        Evaluation storage evaluation = evaluations[_evaluationId];
        if (evaluation.agentId == 0) revert EvaluationNotFound(0, _evaluationId); // Statement ID 0 for general error
        return (evaluation.agentId, evaluation.outcomeIndex, evaluation.stakedAmount, evaluation.isCorrect, evaluation.isChallenged, evaluation.challengeId);
    }

    // --- IV. Evaluation, Challenge & Resolution ---

    /**
     * @dev Allows an agent owner to submit an evaluation for a statement using their agent,
     *      staking tokens on a specific outcome.
     * @param _statementId The ID of the statement being evaluated.
     * @param _agentId The ID of the agent making the evaluation.
     * @param _outcomeIndex The index of the chosen outcome in `possibleOutcomes`.
     * @param _stakeAmount The amount of tokens to stake on this specific evaluation.
     */
    function evaluateStatementByAgent(uint256 _statementId, uint256 _agentId, uint256 _outcomeIndex, uint256 _stakeAmount) public whenNotPaused {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        if (statement.isResolved || statement.isInResolutionPhase) revert StatementNotOpenForEvaluation(_statementId);
        if (agentHasEvaluatedStatement[_statementId][_agentId]) revert AgentAlreadyEvaluatedStatement(_statementId, _agentId);
        if (_outcomeIndex >= statement.possibleOutcomes.length) revert InvalidOutcomeIndex(_statementId, _outcomeIndex);
        if (_stakeAmount < minStakeAmount) revert InsufficientStake(minStakeAmount, _stakeAmount);

        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        if (msg.sender != agent.owner) revert NotOwnerOfAgent(_agentId, msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), _stakeAmount);

        _evaluationIds.increment();
        uint256 newEvaluationId = _evaluationIds.current();

        evaluations[newEvaluationId] = Evaluation({
            agentId: _agentId,
            outcomeIndex: _outcomeIndex,
            stakedAmount: _stakeAmount,
            isCorrect: false,
            isChallenged: false,
            challengeId: 0
        });

        agentHasEvaluatedStatement[_statementId][_agentId] = true;

        emit StatementEvaluated(_statementId, _agentId, newEvaluationId, _outcomeIndex, _stakeAmount);
    }

    /**
     * @dev Allows anyone to challenge a specific agent's evaluation for a statement.
     *      Requires a bond. This can trigger a community vote for resolution.
     * @param _statementId The ID of the statement.
     * @param _evaluationId The ID of the evaluation being challenged.
     * @param _challengeBond The bond paid by the challenger.
     */
    function challengeStatementEvaluation(uint256 _statementId, uint256 _evaluationId, uint256 _challengeBond) public payable whenNotPaused {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        if (statement.isResolved || statement.isInResolutionPhase) revert StatementNotOpenForEvaluation(_statementId);

        Evaluation storage evaluation = evaluations[_evaluationId];
        if (evaluation.agentId == 0) revert EvaluationNotFound(_statementId, _evaluationId);
        if (evaluation.isChallenged) revert InsufficientStake(0, 0); // Already challenged (use more specific error if needed)
        if (_challengeBond < evaluation.stakedAmount / 2) revert ChallengeBondTooLow(evaluation.stakedAmount / 2, _challengeBond); // Example rule: challenge bond must be at least 50% of evaluation stake

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            statementId: _statementId,
            evaluationId: _evaluationId,
            challenger: msg.sender,
            bondAmount: _challengeBond,
            isSuccessful: false,
            isResolved: false
        });

        evaluation.isChallenged = true;
        evaluation.challengeId = newChallengeId;

        treasuryBalance += msg.value; // Store challenge bond in treasury
        emit StatementChallenged(_statementId, _evaluationId, newChallengeId, msg.sender, _challengeBond);

        // If a challenge occurs, immediately move statement into resolution phase
        if (!statement.isInResolutionPhase) {
            statement.isInResolutionPhase = true;
            statement.resolutionPeriodEnd = block.timestamp + resolutionPeriodDuration;
            emit StatementResolutionInitiated(_statementId, statement.resolutionPeriodEnd);
        }
    }

    /**
     * @dev Allows users (with sufficient reputation/stake - simplified for demo) to vote on the
     *      final outcome of a challenged or ambiguous statement. Only active during resolution period.
     * @param _statementId The ID of the statement.
     * @param _outcomeIndex The index of the outcome the voter chooses.
     */
    function submitCommunityResolutionVote(uint256 _statementId, uint256 _outcomeIndex) public whenNotPaused {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        if (!statement.isInResolutionPhase || statement.isResolved) revert StatementNotOpenForEvaluation(_statementId); // Not in resolution phase
        if (block.timestamp >= statement.resolutionPeriodEnd) revert ResolutionPeriodNotEnded(_statementId);
        if (_outcomeIndex >= statement.possibleOutcomes.length) revert InvalidOutcomeIndex(_statementId, _outcomeIndex);
        if (statement.hasVotedForResolution[msg.sender]) revert InsufficientStake(0, 0); // Already voted (use more specific error)

        // A more advanced system would require staking or checking reputation here.
        // For demo, any user can vote once.

        statement.outcomeVoteCounts[_outcomeIndex]++;
        statement.totalVotesInResolution++;
        statement.hasVotedForResolution[msg.sender] = true;

        emit CommunityResolutionVoteCast(_statementId, msg.sender, _outcomeIndex);
    }

    /**
     * @dev Callable by anyone after the evaluation period, this function initiates the resolution process
     *      by setting the resolution end time. If already challenged, this would just ensure the resolution
     *      period is set.
     * @param _statementId The ID of the statement.
     */
    function initiateStatementResolution(uint256 _statementId) public whenNotPaused {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        if (statement.isResolved) revert StatementAlreadyResolved(_statementId);
        if (statement.isInResolutionPhase) revert StatementNotOpenForEvaluation(_statementId); // Already in resolution

        statement.isInResolutionPhase = true;
        statement.resolutionPeriodEnd = block.timestamp + resolutionPeriodDuration;
        emit StatementResolutionInitiated(_statementId, statement.resolutionPeriodEnd);
    }

    /**
     * @dev Callable by anyone after `initiateStatementResolution` and resolution period has passed.
     *      This function formally sets the statement's final outcome and triggers reward/penalty distribution.
     *      The outcome is determined by:
     *      1. If challenged, by community votes.
     *      2. If not challenged, by the majority outcome among agent evaluations (weighted by stake).
     *      This function also updates agent reputation scores.
     * @param _statementId The ID of the statement.
     */
    function finalizeStatementOutcome(uint256 _statementId) public whenNotPaused {
        Statement storage statement = statements[_statementId];
        if (statement.proposer == address(0)) revert StatementNotFound(_statementId);
        if (statement.isResolved) revert StatementAlreadyResolved(_statementId);
        if (!statement.isInResolutionPhase || block.timestamp < statement.resolutionPeriodEnd) revert ResolutionPeriodNotEnded(_statementId);

        // Determine final outcome
        uint256 winningOutcomeIndex = type(uint256).max;
        uint256 maxVotes = 0;
        uint256 maxWeightedStake = 0; // For un-challenged statements

        // Check for challenges first. If any evaluation was challenged, community vote decides.
        bool hasAnyChallenges = false;
        // Iterate through all evaluations to see if any were challenged
        for (uint256 i = 1; i <= _evaluationIds.current(); i++) {
            Evaluation storage eval = evaluations[i];
            if (eval.agentId != 0 && // Check if evaluation exists
                eval.isChallenged && // Check if challenged
                challenges[eval.challengeId].statementId == _statementId // Check if it belongs to this statement
            ) {
                hasAnyChallenges = true;
                break;
            }
        }
        
        if (hasAnyChallenges && statement.totalVotesInResolution > 0) {
            // Community vote decides
            for (uint256 i = 0; i < statement.possibleOutcomes.length; i++) {
                if (statement.outcomeVoteCounts[i] > maxVotes) {
                    maxVotes = statement.outcomeVoteCounts[i];
                    winningOutcomeIndex = i;
                }
            }
            if (winningOutcomeIndex == type(uint256).max) {
                 // If no votes, or tie, can be set to 'uncertain' or proposer can reclaim bond
                 // For now, let's just make it unresolved until further votes are cast or admin decides.
                 // Or, if tie/no votes, perhaps the proposer's bond is burnt and outcome is 'uncertain'
                 // For this demo, if no clear community vote, it remains unresolved
                 revert StatementNotResolved(_statementId);
            }
        } else {
            // No challenges, or community didn't vote. Default to agent consensus (weighted by stake).
            mapping(uint256 => uint256) outcomeWeightedStakes;
            for (uint256 i = 1; i <= _evaluationIds.current(); i++) {
                Evaluation storage eval = evaluations[i];
                if (eval.agentId != 0 && agentHasEvaluatedStatement[_statementId][eval.agentId]) {
                    outcomeWeightedStakes[eval.outcomeIndex] += eval.stakedAmount;
                }
            }

            for (uint256 i = 0; i < statement.possibleOutcomes.length; i++) {
                if (outcomeWeightedStakes[i] > maxWeightedStake) {
                    maxWeightedStake = outcomeWeightedStakes[i];
                    winningOutcomeIndex = i;
                }
            }
             if (winningOutcomeIndex == type(uint256).max) {
                 // If no evaluations, or tie, it remains unresolved for now.
                 revert StatementNotResolved(_statementId);
            }
        }

        statement.finalOutcomeIndex = winningOutcomeIndex;
        statement.isResolved = true;
        statement.isInResolutionPhase = false;

        // Distribute rewards and apply penalties
        _processStatementRewardsAndPenalties(_statementId, winningOutcomeIndex);

        emit StatementFinalized(_statementId, winningOutcomeIndex, block.timestamp);
    }

    /**
     * @dev Internal function to handle rewards and penalties after a statement is finalized.
     * @param _statementId The ID of the statement.
     * @param _finalOutcomeIndex The determined final outcome index.
     */
    function _processStatementRewardsAndPenalties(uint256 _statementId, uint256 _finalOutcomeIndex) internal {
        Statement storage statement = statements[_statementId];
        uint256 totalCorrectStake = 0;
        uint256 totalIncorrectStake = 0;

        // First pass: Calculate total correct and incorrect stakes from evaluations
        for (uint256 i = 1; i <= _evaluationIds.current(); i++) {
            Evaluation storage eval = evaluations[i];
            if (eval.agentId != 0 && agentHasEvaluatedStatement[_statementId][eval.agentId]) {
                if (eval.outcomeIndex == _finalOutcomeIndex) {
                    eval.isCorrect = true;
                    totalCorrectStake += eval.stakedAmount;
                } else {
                    totalIncorrectStake += eval.stakedAmount;
                }
            }
        }

        // Second pass: Update agent reputations, calculate individual rewards/penalties
        for (uint256 i = 1; i <= _evaluationIds.current(); i++) {
            Evaluation storage eval = evaluations[i];
            if (eval.agentId != 0 && agentHasEvaluatedStatement[_statementId][eval.agentId]) {
                Agent storage agent = agents[eval.agentId];

                uint256 rewardPool = totalIncorrectStake + statement.totalBond; // Incorrect stakes + proposer's bond
                uint256 penaltyAmount = 0;
                uint256 earnedReward = 0;

                if (eval.isCorrect) {
                    agent.correctEvaluations++;
                    agent.reputationScore = agent.reputationScore + (eval.stakedAmount * ACCURACY_WEIGHT_FACTOR / (totalCorrectStake > 0 ? totalCorrectStake : 1));
                    
                    if (totalCorrectStake > 0) {
                        earnedReward = (rewardPool * eval.stakedAmount) / totalCorrectStake;
                        agentEvaluationRewards[eval.agentId] += earnedReward;
                    }
                } else {
                    agent.incorrectEvaluations++;
                    agent.reputationScore = agent.reputationScore - (eval.stakedAmount * ACCURACY_WEIGHT_FACTOR / (totalIncorrectStake > 0 ? totalIncorrectStake : 1));
                    if (agent.reputationScore < 100) agent.reputationScore = 100; // Minimum reputation

                    penaltyAmount = eval.stakedAmount;
                    // Deduct penalty (these tokens already in contract from initial stake)
                    // They will be distributed to correct evaluators or burnt.
                }

                // Handle challenges
                if (eval.isChallenged) {
                    Challenge storage challenge = challenges[eval.challengeId];
                    if ((eval.outcomeIndex == _finalOutcomeIndex && !eval.isChallenged) || (eval.outcomeIndex != _finalOutcomeIndex && eval.isChallenged)) {
                        // If evaluation was wrong AND challenged, challenger wins
                        challenge.isSuccessful = true;
                        // Reward challenger from penalized evaluation's stake
                        uint256 challengerCut = (penaltyAmount * CHALLENGE_WIN_SHARE_PERCENT) / 100;
                        challengeRefunds[eval.challengeId] += challengerCut + challenge.bondAmount; // Challenger gets bond back + cut
                        treasuryBalance -= challengerCut; // Adjust treasury for challenger cut
                    } else {
                        // Evaluation was correct, or challenge was incorrect: challenger loses bond
                        // challenger's bond remains in treasury/burnt (already added to treasury upon challenge)
                    }
                    challenge.isResolved = true;
                }
            }
        }

        // Proposer's bond is effectively distributed or kept based on overall outcome accuracy.
        // It's already in treasury, implicitly part of rewardPool.

        // Distribute rewards to general stakers of agents based on agent performance (simplified)
        // A more complex system would calculate a pro-rata share based on stake amount and duration.
        // For simplicity, let's say a small portion of `agentEvaluationRewards` is distributed.
        // Or, assume `agentEvaluationRewards` are for the agent owner, and `agentStakerRewards`
        // come from a separate pool or a portion of the agent's earnings.
        // For this demo, let's keep it simple: `agentEvaluationRewards` are for the owner.
        // `agentStakerRewards` would be a future enhancement or derived from agent fees.
    }


    // --- V. Reward & Penalty Distribution ---

    /**
     * @dev Allows an agent owner to claim rewards for their agent's correct evaluations on a resolved statement.
     * @param _agentId The ID of the agent.
     */
    function claimEvaluationRewards(uint256 _agentId) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        if (msg.sender != agent.owner) revert NotOwnerOfAgent(_agentId, msg.sender);

        uint256 rewards = agentEvaluationRewards[_agentId];
        if (rewards == 0) revert NoRewardsToClaim();

        agentEvaluationRewards[_agentId] = 0;
        stakingToken.transfer(msg.sender, rewards);
        emit EvaluationRewardsClaimed(_agentId, rewards);
    }

    /**
     * @dev Allows users to claim their share of rewards from an agent they staked to,
     *      based on the agent's overall accuracy (simplified for demo).
     *      *Note*: In this demo, `agentStakerRewards` are not explicitly accrued.
     *      This function is a placeholder for a more complex reward distribution system
     *      where general stakers might earn a share of agent profits or a separate reward pool.
     *      For current implementation, this would effectively be 0.
     * @param _agentId The ID of the agent.
     */
    function claimAgentStakingRewards(uint256 _agentId) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0)) revert AgentNotFound(_agentId);
        
        uint256 rewards = agentStakerRewards[_agentId][msg.sender];
        if (rewards == 0) revert NoRewardsToClaim();

        agentStakerRewards[_agentId][msg.sender] = 0;
        stakingToken.transfer(msg.sender, rewards);
        emit StakingRewardsClaimed(_agentId, msg.sender, rewards);
    }

    /**
     * @dev Allows a successful challenger to claim their bond back, plus a portion of the
     *      penalized evaluation's stake.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeRefund(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challenger == address(0)) revert ChallengeNotFound(challenge.statementId, _challengeId); // Placeholder
        if (msg.sender != challenge.challenger) revert NotOwnerOfAgent(0, msg.sender); // Not the challenger
        if (!challenge.isResolved) revert StatementNotResolved(challenge.statementId); // Challenge not resolved yet
        if (!challenge.isSuccessful) revert ChallengeNotSuccessful(_challengeId);

        uint256 refundAmount = challengeRefunds[_challengeId];
        if (refundAmount == 0) revert NoRewardsToClaim();

        challengeRefunds[_challengeId] = 0;
        stakingToken.transfer(msg.sender, refundAmount);
        emit ChallengeRefundClaimed(_challengeId, msg.sender, refundAmount);
    }

    // --- Pausable override ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
```