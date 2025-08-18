This smart contract, `AetherialOracle`, implements a sophisticated decentralized prediction market that integrates AI agents and builds a community-validated knowledge graph from resolved events. It features a dynamic oracle system, a robust dispute resolution mechanism, and DAO-based governance.

This design aims to be *interesting*, *advanced-concept*, *creative*, and *trendy* by combining:
*   **Prediction Markets:** Core functionality for staking on future events.
*   **Dynamic Oracle System:** Not just static oracles, but a multi-party system involving human resolvers and AI agents, with built-in dispute resolution.
*   **AI Agent Integration:** AI agents can register, submit consensus on market resolutions, and contribute to knowledge synthesis, incentivized by a reputation system. (Note: AI computation itself is off-chain, but its interactions and verifiable outputs are on-chain).
*   **Knowledge Graph:** An on-chain "truth registry" built from validated facts derived from resolved prediction markets, providing structured knowledge.
*   **Decentralized Autonomous Organization (DAO):** Community governance for key protocol parameters and actions.
*   **Reputation & Slashing:** Mechanisms to incentivize honest and accurate behavior for participants in critical roles.

This contract does not duplicate any single open-source project, but rather combines and extends various common DeFi and Web3 concepts into a unique integrated system.

---

## Outline: AetherialOracle - Decentralized AI-Assisted Knowledge & Prediction Network

**Contract Name:** `AetherialOracle`

**Description:**
A decentralized platform for prediction markets where event resolution is handled by a dynamic oracle system involving human resolvers and AI agents. It also facilitates the creation of a community-validated knowledge graph from resolved market outcomes, governed by a Decentralized Autonomous Organization (DAO).

**Key Concepts:**
1.  **Prediction Markets:** Users propose events and stake on their outcomes. Winnings are distributed based on the final, validated resolution.
2.  **Dynamic Oracle System:** A multi-layered resolution process. Registered human resolvers and AI agents submit their independent resolutions. A simple majority forms an initial consensus, which can then be challenged by anyone. Challenges trigger a voting period (weighted by governance token stake).
3.  **AI Agent Integration:** AI agents can register, stake tokens, and submit their computational "consensus" for market resolutions. Their accuracy influences their on-chain reputation.
4.  **Knowledge Graph:** Beyond just predictions, the system aims to synthesize and store validated facts (as subject-predicate-object triples) on-chain, derived from resolved prediction markets. These knowledge triples can also be challenged and validated.
5.  **Decentralized Autonomous Organization (DAO):** Token holders can deposit tokens to gain voting power, propose changes to protocol parameters (e.g., fees, stake amounts, challenge durations), and execute approved proposals.
6.  **Reputation & Slashing:** Mechanisms for incentivizing honest and penalizing dishonest behavior for resolvers, AI agents, and challengers through stake adjustments and reputation scores.

**Dependencies:**
*   `@openzeppelin/contracts/access/Ownable.sol`: For initial contract ownership and basic administrative control (though most parameter changes will be DAO-driven in a full implementation).
*   `@openzeppelin/contracts/token/ERC20/IERC20.sol`: For interaction with an external ERC-20 token used for staking and governance.
*   `@openzeppelin/contracts/utils/ReentrancyGuard.sol`: To prevent reentrancy attacks on critical functions involving token transfers.

---

## Function Summary (35 Functions)

### I. Core Market Management

1.  `proposeMarket(string _question, string[] _outcomes, uint256 _closeTime, uint256 _resolutionTime, uint256 _bondAmount)`:
    *   **Description:** Allows a user to propose a new prediction market, defining the question, possible outcomes, and crucial timestamps. Requires an initial bond from the proposer.
    *   **Concept:** Standard prediction market initiation.
2.  `stakeOnOutcome(uint256 _marketId, uint256 _outcomeIndex, uint256 _amount)`:
    *   **Description:** Enables users to stake their AO tokens on a specific outcome within an open market.
    *   **Concept:** Core prediction market participation.
3.  `claimWinnings(uint256 _marketId)`:
    *   **Description:** Allows participants who staked on the correctly resolved outcome to claim their share of the prize pool, after fees.
    *   **Concept:** Reward distribution.
4.  `reclaimBond(uint256 _marketId)`:
    *   **Description:** Enables the market proposer to reclaim their initial bond once the market has been successfully resolved and finalized.
    *   **Concept:** Proposer incentive and market finalization.

### II. Oracle & Resolution System

5.  `registerResolver(uint256 _stakeAmount)`:
    *   **Description:** Allows an address to register as a market resolver, requiring a minimum stake to ensure commitment and trustworthiness.
    *   **Concept:** Decentralized oracle participant registration.
6.  `submitResolution(uint256 _marketId, uint256 _resolvedOutcomeIndex, string _evidenceUri)`:
    *   **Description:** A registered resolver submits their proposed resolution for a market. The contract tracks and aggregates these submissions to determine a provisional majority.
    *   **Concept:** Multi-party oracle data submission.
7.  `challengeResolution(uint256 _marketId, uint256 _challengerStake)`:
    *   **Description:** Allows any user to challenge a provisional resolution, initiating a dispute and a subsequent voting period. Requires a stake from the challenger.
    *   **Concept:** Decentralized dispute resolution and challenge mechanism.
8.  `voteOnChallenge(uint256 _marketId, bool _supportsResolution)`:
    *   **Description:** Participants (governance token holders) vote on a challenged resolution, determining its validity. Votes are weighted by their governance deposit.
    *   **Concept:** Community-driven dispute resolution.
9.  `finalizeMarketResolution(uint256 _marketId)`:
    *   **Description:** Finalizes a market after the resolution or challenge period ends. This function checks consensus/vote outcomes, slashes incorrect parties, and sets the definitive market resolution.
    *   **Concept:** Market state progression and outcome finalization.
10. `_slashResolver(address _resolverAddress, uint256 _amount)`:
    *   **Description:** (Internal/DAO callable) Implements the slashing mechanism for resolvers or challengers who acted maliciously or incorrectly, reducing their stake and reputation.
    *   **Concept:** Incentivization and disincentivization for oracle participants.
11. `getMarketResolution(uint256 _marketId)`:
    *   **Description:** View function to retrieve the current resolved outcome index of a market.
    *   **Concept:** Public data access.

### III. AI Agent Integration & Knowledge Graph

12. `registerAIAgent(string _aiAgentName, string _aiAgentUri, uint256 _stakeAmount)`:
    *   **Description:** Allows an AI agent (represented by an address) to register with the platform, providing metadata and staking tokens.
    *   **Concept:** On-chain registration for off-chain AI entities.
13. `submitAIConsensus(uint256 _marketId, uint256 _aiSuggestedOutcome, string _aiEvidenceUri)`:
    *   **Description:** A registered AI agent submits their suggested resolution for a market. This contributes to a broader AI consensus and can influence the final human-verified resolution.
    *   **Concept:** AI contribution to decentralized oracle, reputation building for AIs.
14. `synthesizeKnowledge(uint256 _marketId, string _knowledgeTripleSubject, string _knowledgeTriplePredicate, string _knowledgeTripleObject, string _evidenceUri)`:
    *   **Description:** Allows a "knowledge synthesizer" (human or AI) to propose a structured knowledge triple (Subject-Predicate-Object) derived from a resolved market's outcome.
    *   **Concept:** On-chain knowledge creation from verified market data.
15. `challengeKnowledgeTriple(uint256 _knowledgeTripleId, uint256 _challengerStake)`:
    *   **Description:** Users can challenge a proposed knowledge triple, similar to market resolution challenges, initiating a validation dispute.
    *   **Concept:** Decentralized knowledge validation and dispute.
16. `voteOnKnowledgeChallenge(uint256 _knowledgeTripleId, bool _supportsKnowledge)`:
    *   **Description:** Participants vote on the validity of a challenged knowledge triple, ensuring the accuracy of the on-chain knowledge graph.
    *   **Concept:** Community consensus on factual data.
17. `finalizeKnowledgeTriple(uint256 _knowledgeTripleId)`:
    *   **Description:** Finalizes a knowledge triple after its challenge period or validation. If successful, it becomes a permanent part of the on-chain knowledge graph.
    *   **Concept:** Knowledge graph immutability and finalization.
18. `queryKnowledgeGraph(string _subject, string _predicate)`:
    *   **Description:** View function to retrieve validated knowledge triples based on a given subject and predicate. (Note: Full graph traversal on-chain is limited; this is a simplified lookup, requiring off-chain indexing for complex queries).
    *   **Concept:** Accessing structured on-chain knowledge.

### IV. Governance (DAO) System

19. `depositForGovernance(uint256 _amount)`:
    *   **Description:** Users deposit their AO tokens into the contract to gain voting power for governance proposals.
    *   **Concept:** DAO participation and voting power assignment.
20. `withdrawFromGovernance(uint256 _amount)`:
    *   **Description:** Allows users to withdraw their deposited governance tokens.
    *   **Concept:** Flexibility for DAO participants.
21. `createGovernanceProposal(string _description, address _targetContract, bytes _callData)`:
    *   **Description:** Token holders can create new governance proposals, detailing the proposed change and the on-chain action to be executed if it passes.
    *   **Concept:** Decentralized protocol evolution.
22. `voteOnProposal(uint256 _proposalId, bool _support)`:
    *   **Description:** Users vote on active governance proposals with their deposited governance power.
    *   **Concept:** Token-weighted voting.
23. `executeProposal(uint256 _proposalId)`:
    *   **Description:** Executes a governance proposal that has successfully passed the voting period, meeting quorum and threshold requirements.
    *   **Concept:** On-chain governance execution.

### V. Parameter & Utility Functions

24. `updateMinimumStake(uint252 _newStake)`:
    *   **Description:** (DAO-controlled in a full implementation, `onlyOwner` for this example) Updates the minimum stake required for market proposers, resolvers, and AI agents.
    *   **Concept:** Adjustable protocol parameters.
25. `setMarketFee(uint256 _newFeeBps)`:
    *   **Description:** (DAO-controlled in a full implementation, `onlyOwner` for this example) Sets the percentage fee (in basis points) taken from market winnings.
    *   **Concept:** Dynamic protocol economics.
26. `setChallengePeriod(uint256 _newPeriod)`:
    *   **Description:** (DAO-controlled in a full implementation, `onlyOwner` for this example) Sets the duration for the challenge period after a resolution or knowledge triple proposal.
    *   **Concept:** Protocol timing adjustments.
27. `getMarketDetails(uint256 _marketId)`:
    *   **Description:** View function to retrieve comprehensive details about a specific market.
    *   **Concept:** Public data access.
28. `getOutcomePool(uint256 _marketId, uint256 _outcomeIndex)`:
    *   **Description:** View function to get the total amount staked on a particular outcome within a market.
    *   **Concept:** Transparency of market data.
29. `getUserStake(uint256 _marketId, address _user)`:
    *   **Description:** View function to get a user's total stake across all outcomes in a given market.
    *   **Concept:** User-specific data access.
30. `getResolverStatus(address _resolverAddress)`:
    *   **Description:** View function to check the registration status, current stake, and reputation score of a resolver.
    *   **Concept:** Public reputation and status monitoring.
31. `getAIAgentDetails(address _aiAgentAddress)`:
    *   **Description:** View function to get details (name, URI, stake, reputation) about a registered AI agent.
    *   **Concept:** Public AI agent registry.
32. `getKnowledgeTriple(uint256 _knowledgeTripleId)`:
    *   **Description:** View function to retrieve all details of a specific knowledge triple, including its status and challenge data.
    *   **Concept:** Accessing structured knowledge data.
33. `getTotalMarkets()`:
    *   **Description:** View function to get the total number of markets created on the platform.
    *   **Concept:** Protocol statistics.
34. `getTotalProposals()`:
    *   **Description:** View function to get the total number of governance proposals created.
    *   **Concept:** DAO activity monitoring.
35. `getGovernanceBalance(address _user)`:
    *   **Description:** View function to get a user's deposited governance token balance, representing their voting power.
    *   **Concept:** DAO participation transparency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline: AetherialOracle - Decentralized AI-Assisted Knowledge & Prediction Network ---
//
// This contract implements a sophisticated decentralized prediction market that integrates
// AI agents and builds a community-validated knowledge graph from resolved events.
// It features a dynamic oracle system, a robust dispute resolution mechanism, and DAO-based governance.
//
// Key Concepts:
// 1.  Prediction Markets: Users stake on outcomes of future events.
// 2.  Dynamic Oracle System: A multi-resolver system (human and AI) for event resolution,
//     with a challenging and voting mechanism for dispute resolution.
// 3.  AI Agent Integration: AI agents can propose markets, contribute to resolutions, and
//     synthesize knowledge, incentivized by the platform.
// 4.  Knowledge Graph: A public, on-chain repository of validated facts derived from resolved
//     prediction markets. This aims to create a "truth registry".
// 5.  Decentralized Autonomous Organization (DAO): Governance is community-driven through token voting.
// 6.  Reputation & Slashing: Mechanisms to incentivize honest and accurate participation for resolvers and AI agents.
//
// --- Function Summary (35+ Functions) ---
//
// I. Core Market Management:
// 1.  `proposeMarket(string _question, string[] _outcomes, uint256 _closeTime, uint256 _resolutionTime, uint256 _bondAmount)`:
//     Allows a user to propose a new prediction market, requiring a bond.
// 2.  `stakeOnOutcome(uint256 _marketId, uint256 _outcomeIndex, uint256 _amount)`:
//     Users stake tokens on a specific outcome of a market.
// 3.  `claimWinnings(uint256 _marketId)`:
//     Allows participants who staked on the correct outcome to claim their share of the prize pool.
// 4.  `reclaimBond(uint256 _marketId)`:
//     Allows the market proposer to reclaim their initial bond after successful market resolution.
//
// II. Oracle & Resolution System:
// 5.  `registerResolver(uint256 _stakeAmount)`:
//     Allows an address to register as a market resolver, requiring a stake.
// 6.  `submitResolution(uint256 _marketId, uint256 _resolvedOutcomeIndex, string _evidenceUri)`:
//     A registered resolver submits their proposed resolution for a market.
// 7.  `challengeResolution(uint256 _marketId, uint256 _challengerStake)`:
//     Allows any user to challenge a submitted resolution, initiating a dispute.
// 8.  `voteOnChallenge(uint256 _marketId, bool _supportsResolution)`:
//     Participants (governance token holders or resolvers) vote on a challenged resolution.
// 9.  `finalizeMarketResolution(uint256 _marketId)`:
//     Finalizes a market after the resolution or challenge period, distributing rewards.
// 10. `_slashResolver(address _resolverAddress, uint256 _amount)`:
//     (Internal/DAO callable) Slashing mechanism for misbehaving resolvers/challengers.
// 11. `getMarketResolution(uint256 _marketId)`:
//     View function to retrieve the current resolved outcome of a market.
//
// III. AI Agent Integration & Knowledge Graph:
// 12. `registerAIAgent(string _aiAgentName, string _aiAgentUri, uint256 _stakeAmount)`:
//     Allows an AI agent to register with the platform, requiring a stake and providing metadata.
// 13. `submitAIConsensus(uint256 _marketId, uint256 _aiSuggestedOutcome, string _aiEvidenceUri)`:
//     A registered AI agent submits their suggested resolution for a market, influencing consensus.
// 14. `synthesizeKnowledge(uint256 _marketId, string _knowledgeTripleSubject, string _knowledgeTriplePredicate, string _knowledgeTripleObject, string _evidenceUri)`:
//     Allows a "knowledge synthesizer" (human or AI) to propose a structured knowledge triple based on a resolved market.
// 15. `challengeKnowledgeTriple(uint256 _knowledgeTripleId, uint256 _challengerStake)`:
//     Users can challenge a proposed knowledge triple, initiating a validation dispute.
// 16. `voteOnKnowledgeChallenge(uint256 _knowledgeTripleId, bool _supportsKnowledge)`:
//     Participants vote on the validity of a challenged knowledge triple.
// 17. `finalizeKnowledgeTriple(uint256 _knowledgeTripleId)`:
//     Finalizes a knowledge triple after its validation period or challenge, adding it to the graph.
// 18. `queryKnowledgeGraph(string _subject, string _predicate)`:
//     View function to retrieve validated knowledge triples based on subject and predicate.
//
// IV. Governance (DAO) System:
// 19. `depositForGovernance(uint256 _amount)`:
//     Users deposit tokens to gain voting power for governance proposals.
// 20. `withdrawFromGovernance(uint256 _amount)`:
//     Users withdraw their deposited tokens from governance.
// 21. `createGovernanceProposal(string _description, address _targetContract, bytes _callData)`:
//     Token holders can create new governance proposals to modify protocol parameters or actions.
// 22. `voteOnProposal(uint256 _proposalId, bool _support)`:
//     Users vote on active governance proposals.
// 23. `executeProposal(uint256 _proposalId)`:
//     Executes a governance proposal that has successfully passed.
//
// V. Parameter & Utility Functions (Admin/DAO controlled):
// 24. `updateMinimumStake(uint256 _newStake)`:
//     DAO-controlled function to update the minimum stake required for various roles.
// 25. `setMarketFee(uint256 _newFeeBps)`:
//     DAO-controlled function to set the market fee percentage (in basis points).
// 26. `setChallengePeriod(uint256 _newPeriod)`:
//     DAO-controlled function to set the duration of the challenge period.
// 27. `getMarketDetails(uint256 _marketId)`:
//     View function to retrieve comprehensive details about a specific market.
// 28. `getOutcomePool(uint256 _marketId, uint256 _outcomeIndex)`:
//     View function to get the total amount staked on a particular outcome.
// 29. `getUserStake(uint256 _marketId, address _user)`:
//     View function to get a user's total stake across all outcomes in a market.
// 30. `getResolverStatus(address _resolverAddress)`:
//     View function to check the registration status and reputation of a resolver.
// 31. `getAIAgentDetails(address _aiAgentAddress)`:
//     View function to get details about a registered AI agent.
// 32. `getKnowledgeTriple(uint256 _knowledgeTripleId)`:
//     View function to retrieve details of a specific knowledge triple.
// 33. `getTotalMarkets()`:
//     View function to get the total number of markets created.
// 34. `getTotalProposals()`:
//     View function to get the total number of governance proposals.
// 35. `getGovernanceBalance(address _user)`:
//     View function to get a user's deposited governance token balance.

contract AetherialOracle is Ownable, ReentrancyGuard {
    IERC20 public immutable aoToken; // Aetherial Oracle Token

    // --- Configuration Parameters (Adjustable by DAO via proposals) ---
    uint256 public minMarketProposerBond = 100 ether; // Minimum bond to propose a market
    uint256 public minResolverStake = 500 ether;      // Minimum stake for resolvers
    uint256 public minAIAgentStake = 1000 ether;      // Minimum stake for AI agents
    uint256 public challengePeriodDuration = 3 days;  // Duration for challenging resolutions/knowledge
    uint256 public votingPeriodDuration = 5 days;     // Duration for governance/challenge voting
    uint256 public marketFeeBps = 500;                // 5% fee (500 basis points) on winnings
    uint256 public governanceQuorumBps = 1000;        // 10% quorum for governance proposals (of total governance supply)
    uint256 public governanceVoteThresholdBps = 5000; // 50% + 1 threshold for proposals (of cast votes)

    // --- Enums ---
    enum MarketState {
        Open,                 // Market is open for staking
        Closed,               // Staking is closed, awaiting resolution
        AwaitingResolution,   // Resolvers are expected to submit outcomes
        ChallengedResolution, // A resolution has been challenged, voting is open
        Resolved,             // A final resolution has been reached
        Finalized             // Winnings have been claimed and bond reclaimed
    }

    enum ProposalState {
        Pending,   // Proposal created, not yet active (or just created)
        Active,    // Voting is open
        Succeeded, // Passed quorum and threshold
        Failed,    // Did not pass
        Executed   // Successfully executed
    }

    enum KnowledgeStatus {
        Proposed,   // Knowledge triple proposed, open for challenge
        Challenged, // Knowledge triple challenged, voting is open
        Validated   // Knowledge triple validated (finalized and accepted)
    }

    // --- Structs ---

    // Market details
    struct Market {
        string question;
        string[] outcomes;
        uint256 closeTime;       // When staking closes (timestamp)
        uint256 resolutionTime;  // Target resolution time (timestamp)
        uint256 proposerBond;    // Amount proposer staked
        address proposer;
        MarketState state;
        uint256 resolvedOutcomeIndex; // Index of the winning outcome (type(uint256).max if not resolved)
        uint256 totalStaked;
        mapping(uint256 => uint256) outcomeStakes; // outcomeIndex => total staked on this outcome
        mapping(address => mapping(uint256 => uint256)) userOutcomeStakes; // user => outcomeIndex => amount staked by user
        mapping(address => bool) hasClaimedWinnings; // user => bool

        // For resolution challenge
        uint256 challengeEndTime; // When challenge/voting period ends
        uint256 challengeTotalVotesFor; // Sum of governance power supporting initial resolution
        uint256 challengeTotalVotesAgainst; // Sum of governance power opposing initial resolution
        address currentChallenger; // Address of the current active challenger (address(0) if none)
        uint256 challengeStake; // Stake amount from the current challenger
        mapping(address => bool) hasVotedOnChallenge; // user => bool (to prevent double voting in challenge)

        // For resolver consensus
        address[] submittedResolvers; // List of resolvers who submitted for this market
        mapping(address => uint256) resolverSubmissions; // resolver => outcomeIndex they submitted
        mapping(uint256 => uint256) outcomeResolutionCounts; // outcomeIndex => count of resolvers voting for it
        uint256 majorityResolutionOutcome; // The outcome with the most resolver votes (provisional)

        // For AI Consensus
        uint256 aiConsensusOutcome; // Outcome suggested by AI consensus (if applicable)
        uint256 aiConsensusCount; // Number of AI agents supporting this outcome
    }

    // Resolver details
    struct Resolver {
        uint256 stake;
        uint256 lastActive; // Timestamp of last resolution submission or reputation activity
        int256 reputationScore; // Can be negative for slashing, affects future rewards/penalties
        bool isRegistered;
    }

    // AI Agent details
    struct AIAgent {
        string name;
        string uri; // URI pointing to AI agent details/documentation (e.g., IPFS hash)
        uint256 stake;
        int256 reputationScore; // Reputation for AI agents
        bool isRegistered;
    }

    // Knowledge Triple details (for the knowledge graph)
    struct KnowledgeTriple {
        uint256 marketId; // The market from which this knowledge was derived
        string subject;
        string predicate;
        string object;
        string evidenceUri; // URI pointing to supporting evidence (e.g., market resolution, external data)
        KnowledgeStatus status;
        address proposer; // Address of the entity (human/AI) that proposed this triple

        // For knowledge challenge
        uint256 challengeEndTime;
        uint256 challengeTotalVotesFor;
        uint256 challengeTotalVotesAgainst;
        address currentChallenger;
        uint256 challengeStake;
        mapping(address => bool) hasVotedOnChallenge; // user => bool
    }

    // Governance Proposal details
    struct Proposal {
        string description;      // Human-readable description of the proposal
        address targetContract;  // The contract address to call if the proposal passes
        bytes callData;          // The encoded function call (method + args) for the targetContract
        uint256 voteCountFor;    // Total governance power (tokens) voting "for"
        uint256 voteCountAgainst; // Total governance power (tokens) voting "against"
        uint256 startBlock;      // The block number when voting starts
        uint256 endBlock;        // The block number when voting ends
        ProposalState state;
        address proposer;
        mapping(address => bool) hasVoted; // User => bool (to prevent double voting)
    }

    // --- Mappings ---
    uint256 public nextMarketId; // Counter for unique market IDs
    mapping(uint256 => Market) public markets; // marketId => Market struct
    mapping(address => Resolver) public resolvers; // resolverAddress => Resolver struct
    mapping(address => AIAgent) public aiAgents; // aiAgentAddress => AIAgent struct

    uint256 public nextKnowledgeTripleId; // Counter for unique knowledge triple IDs
    mapping(uint256 => KnowledgeTriple) public knowledgeGraph; // tripleId => KnowledgeTriple struct

    uint256 public nextProposalId; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal struct
    mapping(address => uint256) public governanceDeposits; // User => deposited governance tokens (voting power)

    // --- Events ---
    event MarketProposed(uint256 indexed marketId, address indexed proposer, string question, uint256 closeTime);
    event Staked(uint256 indexed marketId, address indexed staker, uint256 outcomeIndex, uint256 amount);
    event WinningsClaimed(uint256 indexed marketId, address indexed claimant, uint256 amount);
    event BondReclaimed(uint256 indexed marketId, address indexed proposer, uint256 amount);
    event MarketResolved(uint256 indexed marketId, uint256 indexed resolvedOutcomeIndex);

    event ResolverRegistered(address indexed resolverAddress, uint256 stake);
    event ResolutionSubmitted(uint256 indexed marketId, address indexed resolver, uint256 outcomeIndex);
    event ResolutionChallenged(uint256 indexed marketId, address indexed challenger, uint256 stake);
    event ChallengeVote(uint256 indexed marketId, address indexed voter, bool support);
    event ResolverSlashed(address indexed resolverAddress, uint256 amount);

    event AIAgentRegistered(address indexed aiAgentAddress, string name, uint256 stake);
    event AIConsensusSubmitted(uint256 indexed marketId, address indexed aiAgent, uint256 suggestedOutcome);
    event KnowledgeTripleProposed(uint256 indexed tripleId, uint256 indexed marketId, address indexed proposer);
    event KnowledgeTripleChallenged(uint256 indexed tripleId, address indexed challenger, uint256 stake);
    event KnowledgeTripleVote(uint256 indexed tripleId, address indexed voter, bool support);
    event KnowledgeTripleValidated(uint256 indexed tripleId, uint256 indexed marketId);

    event GovernanceDeposit(address indexed user, uint256 amount);
    event GovernanceWithdrawal(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVote(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event ProtocolParameterUpdated(string parameterName, uint256 newValue);

    // --- Constructor ---
    /// @notice Constructs the AetherialOracle contract, setting the AO Token address.
    /// @param _aoTokenAddress The address of the ERC-20 Aetherial Oracle Token.
    constructor(address _aoTokenAddress) Ownable(msg.sender) {
        require(_aoTokenAddress != address(0), "Invalid AO Token address");
        aoToken = IERC20(_aoTokenAddress);
    }

    // --- Modifiers ---
    /// @dev Requires the caller to be a registered and sufficiently staked resolver.
    modifier onlyRegisteredResolver() {
        require(resolvers[msg.sender].isRegistered, "Caller not a registered resolver");
        require(resolvers[msg.sender].stake >= minResolverStake, "Resolver stake too low");
        _;
    }

    /// @dev Requires the caller to be a registered and sufficiently staked AI agent.
    modifier onlyRegisteredAIAgent() {
        require(aiAgents[msg.sender].isRegistered, "Caller not a registered AI agent");
        require(aiAgents[msg.sender].stake >= minAIAgentStake, "AI Agent stake too low");
        _;
    }

    /// @dev Requires the caller to be the proposer of the given market.
    modifier onlyMarketProposer(uint256 _marketId) {
        require(markets[_marketId].proposer == msg.sender, "Not the market proposer");
        _;
    }

    /// @dev Requires the market to be in the 'Open' state for staking.
    modifier isMarketOpen(uint256 _marketId) {
        require(markets[_marketId].state == MarketState.Open, "Market not open for staking");
        _;
    }

    /// @dev Requires the market to be in a state where resolution is possible (Closed or AwaitingResolution).
    modifier isMarketResolvable(uint256 _marketId) {
        Market storage market = markets[_marketId];
        require(market.state == MarketState.Closed || market.state == MarketState.AwaitingResolution, "Market not in resolvable state");
        require(block.timestamp >= market.closeTime, "Market staking still open");
        _;
    }

    /// @dev Requires the caller to have a non-zero governance token deposit.
    modifier hasGovernancePower(address _user) {
        require(governanceDeposits[_user] > 0, "User has no governance power");
        _;
    }

    // --- I. Core Market Management ---

    /// @notice Allows a user to propose a new prediction market. Requires a bond.
    /// @param _question The question for the market (e.g., "Will ETH reach $5000 by 2024 end?").
    /// @param _outcomes An array of possible outcomes (e.g., ["Yes", "No"]).
    /// @param _closeTime Timestamp when staking for this market closes.
    /// @param _resolutionTime Target timestamp for when the market should be resolved.
    /// @param _bondAmount The amount of AO tokens to bond as a proposer.
    /// @return marketId The unique ID of the newly created market.
    function proposeMarket(
        string memory _question,
        string[] memory _outcomes,
        uint256 _closeTime,
        uint256 _resolutionTime,
        uint256 _bondAmount
    ) external nonReentrant returns (uint256) {
        require(_outcomes.length >= 2, "At least two outcomes required");
        require(_closeTime > block.timestamp, "Close time must be in the future");
        require(_resolutionTime > _closeTime, "Resolution time must be after close time");
        require(_bondAmount >= minMarketProposerBond, "Proposer bond too low");

        aoToken.transferFrom(msg.sender, address(this), _bondAmount);

        uint256 marketId = nextMarketId++;
        Market storage newMarket = markets[marketId];
        newMarket.question = _question;
        newMarket.outcomes = _outcomes;
        newMarket.closeTime = _closeTime;
        newMarket.resolutionTime = _resolutionTime;
        newMarket.proposerBond = _bondAmount;
        newMarket.proposer = msg.sender;
        newMarket.state = MarketState.Open;
        newMarket.resolvedOutcomeIndex = type(uint256).max; // Indicates not resolved

        emit MarketProposed(marketId, msg.sender, _question, _closeTime);
        return marketId;
    }

    /// @notice Users stake tokens on a specific outcome of a market.
    /// @param _marketId The ID of the market to stake on.
    /// @param _outcomeIndex The index of the outcome to stake on.
    /// @param _amount The amount of AO tokens to stake.
    function stakeOnOutcome(uint256 _marketId, uint256 _outcomeIndex, uint256 _amount)
        external
        nonReentrant
        isMarketOpen(_marketId)
    {
        Market storage market = markets[_marketId];
        require(_outcomeIndex < market.outcomes.length, "Invalid outcome index");
        require(block.timestamp < market.closeTime, "Staking period has ended");
        require(_amount > 0, "Stake amount must be greater than zero");

        aoToken.transferFrom(msg.sender, address(this), _amount);

        market.outcomeStakes[_outcomeIndex] += _amount;
        market.userOutcomeStakes[msg.sender][_outcomeIndex] += _amount;
        market.totalStaked += _amount;

        emit Staked(_marketId, msg.sender, _outcomeIndex, _amount);
    }

    /// @notice Allows participants who staked on the correct outcome to claim their share of the prize pool.
    /// @param _marketId The ID of the market to claim winnings from.
    function claimWinnings(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.state == MarketState.Resolved, "Market not yet resolved");
        require(!market.hasClaimedWinnings[msg.sender], "Winnings already claimed");
        require(market.resolvedOutcomeIndex != type(uint256).max, "Market resolution not set");

        uint256 userStakeOnWinningOutcome = market.userOutcomeStakes[msg.sender][market.resolvedOutcomeIndex];
        require(userStakeOnWinningOutcome > 0, "No stake on winning outcome");

        uint256 totalStakeOnWinningOutcome = market.outcomeStakes[market.resolvedOutcomeIndex];
        require(totalStakeOnWinningOutcome > 0, "No total stake on winning outcome (should not happen if resolved)");

        // Calculate winnings: (userStake / totalStakeOnWinningOutcome) * totalStakedInMarket * (1 - marketFee)
        // This distributes the entire pool (minus fees) proportionally among winners.
        uint256 totalPoolAfterFees = (market.totalStaked * (10000 - marketFeeBps)) / 10000;
        uint256 winnings = (userStakeOnWinningOutcome * totalPoolAfterFees) / totalStakeOnWinningOutcome;

        market.hasClaimedWinnings[msg.sender] = true;
        aoToken.transfer(msg.sender, winnings);

        emit WinningsClaimed(_marketId, msg.sender, winnings);
    }

    /// @notice Allows the market proposer to reclaim their initial bond after successful market resolution.
    /// @param _marketId The ID of the market whose bond to reclaim.
    function reclaimBond(uint256 _marketId) external nonReentrant onlyMarketProposer(_marketId) {
        Market storage market = markets[_marketId];
        require(market.state == MarketState.Resolved || market.state == MarketState.Finalized, "Market not resolved or finalized");
        require(market.proposerBond > 0, "Proposer bond already reclaimed or never set"); // Check if bond exists and not reclaimed

        uint256 bondAmount = market.proposerBond;
        market.proposerBond = 0; // Set to 0 to prevent re-claiming

        aoToken.transfer(msg.sender, bondAmount);
        market.state = MarketState.Finalized; // Mark as finalized after bond reclaim
        emit BondReclaimed(_marketId, msg.sender, bondAmount);
    }

    // --- II. Oracle & Resolution System ---

    /// @notice Allows an address to register as a market resolver, requiring a stake.
    /// @param _stakeAmount The amount of AO tokens to stake as a resolver.
    function registerResolver(uint256 _stakeAmount) external nonReentrant {
        require(!resolvers[msg.sender].isRegistered, "Already a registered resolver");
        require(_stakeAmount >= minResolverStake, "Stake amount too low");

        aoToken.transferFrom(msg.sender, address(this), _stakeAmount);

        Resolver storage resolver = resolvers[msg.sender];
        resolver.stake = _stakeAmount;
        resolver.lastActive = block.timestamp;
        resolver.reputationScore = 0; // Initialize reputation
        resolver.isRegistered = true;

        emit ResolverRegistered(msg.sender, _stakeAmount);
    }

    /// @notice A registered resolver submits their proposed resolution for a market.
    /// Resolvers can only submit once. If multiple submit, a simple majority wins, else challenge.
    /// @param _marketId The ID of the market to resolve.
    /// @param _resolvedOutcomeIndex The index of the outcome the resolver believes is correct.
    /// @param _evidenceUri URI pointing to off-chain evidence supporting the resolution.
    function submitResolution(uint256 _marketId, uint256 _resolvedOutcomeIndex, string memory _evidenceUri)
        external
        nonReentrant
        onlyRegisteredResolver
    {
        Market storage market = markets[_marketId];
        require(_resolvedOutcomeIndex < market.outcomes.length, "Invalid outcome index");
        require(market.state == MarketState.Closed || market.state == MarketState.AwaitingResolution, "Market not in resolvable state");
        require(block.timestamp >= market.closeTime, "Market staking still open");
        require(market.state != MarketState.Resolved && market.state != MarketState.Finalized, "Market already resolved or finalized");

        // Check if this resolver has already submitted
        for (uint256 i = 0; i < market.submittedResolvers.length; i++) {
            require(market.submittedResolvers[i] != msg.sender, "Resolver already submitted for this market");
        }

        market.submittedResolvers.push(msg.sender);
        market.resolverSubmissions[msg.sender] = _resolvedOutcomeIndex;
        market.outcomeResolutionCounts[_resolvedOutcomeIndex]++;

        // Update resolver's last active time
        resolvers[msg.sender].lastActive = block.timestamp;

        // Simple majority check for provisional resolution
        // Requires at least 3 resolvers for an initial consensus, or more for complex cases
        if (market.submittedResolvers.length >= 3) {
            uint256 currentMaxCount = 0;
            uint256 potentialMajorityOutcome = type(uint256).max;
            bool isTie = false;
            for (uint224 i = 0; i < market.outcomes.length; i++) {
                if (market.outcomeResolutionCounts[i] > currentMaxCount) {
                    currentMaxCount = market.outcomeResolutionCounts[i];
                    potentialMajorityOutcome = i;
                    isTie = false;
                } else if (market.outcomeResolutionCounts[i] == currentMaxCount && currentMaxCount > 0) {
                    isTie = true; // Indicate tie
                }
            }
            if (!isTie && potentialMajorityOutcome != type(uint256).max) {
                market.majorityResolutionOutcome = potentialMajorityOutcome;
                market.resolvedOutcomeIndex = potentialMajorityOutcome; // Provisional outcome
                market.state = MarketState.Resolved; // Move to Resolved, awaiting challenge period
                market.challengeEndTime = block.timestamp + challengePeriodDuration;
            } else {
                market.state = MarketState.AwaitingResolution; // Still in limbo if tie or not enough submissions
            }
        } else {
            market.state = MarketState.AwaitingResolution; // Needs more resolver submissions
        }

        emit ResolutionSubmitted(_marketId, msg.sender, _resolvedOutcomeIndex);
    }

    /// @notice Allows any user to challenge a submitted resolution, initiating a dispute.
    /// @param _marketId The ID of the market with the challenged resolution.
    /// @param _challengerStake The amount of AO tokens to stake as a challenger.
    function challengeResolution(uint256 _marketId, uint256 _challengerStake) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.state == MarketState.Resolved, "Market not in provisional resolved state");
        require(block.timestamp < market.challengeEndTime, "Challenge period has ended");
        require(_challengerStake > 0, "Challenger stake must be greater than zero");
        require(market.currentChallenger == address(0), "Resolution already challenged"); // Only one active challenge per market

        aoToken.transferFrom(msg.sender, address(this), _challengerStake);

        market.state = MarketState.ChallengedResolution;
        market.currentChallenger = msg.sender;
        market.challengeStake = _challengerStake;
        market.challengeEndTime = block.timestamp + votingPeriodDuration; // New voting period for challenge
        market.challengeTotalVotesFor = 0;
        market.challengeTotalVotesAgainst = 0;
        // Reset hasVotedOnChallenge for all relevant participants for this specific challenge
        // This is a simplified approach; a real system might use a separate challenge ID or clear more broadly.
        // For simplicity, we assume this is called once per resolution challenge.
        delete market.hasVotedOnChallenge[msg.sender]; // Clear for current challenger
        delete market.hasVotedOnChallenge[market.proposer]; // Clear for market proposer (can also vote)

        emit ResolutionChallenged(_marketId, msg.sender, _challengerStake);
    }

    /// @notice Participants (governance token holders) vote on a challenged resolution.
    /// @param _marketId The ID of the market with the challenge.
    /// @param _supportsResolution True if the voter supports the initially proposed resolution, false otherwise.
    function voteOnChallenge(uint256 _marketId, bool _supportsResolution) external nonReentrant hasGovernancePower(msg.sender) {
        Market storage market = markets[_marketId];
        require(market.state == MarketState.ChallengedResolution, "Market not in challenge state");
        require(block.timestamp < market.challengeEndTime, "Voting period has ended");
        require(!market.hasVotedOnChallenge[msg.sender], "Already voted on this challenge");

        market.hasVotedOnChallenge[msg.sender] = true;
        if (_supportsResolution) {
            market.challengeTotalVotesFor += governanceDeposits[msg.sender];
        } else {
            market.challengeTotalVotesAgainst += governanceDeposits[msg.sender];
        }

        emit ChallengeVote(_marketId, msg.sender, _supportsResolution);
    }

    /// @notice Finalizes a market after the resolution or challenge period, distributing rewards.
    /// Can be called by anyone, but security is ensured by state checks.
    /// @param _marketId The ID of the market to finalize.
    function finalizeMarketResolution(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.state != MarketState.Finalized, "Market already finalized");

        if (market.state == MarketState.Open) {
            require(block.timestamp >= market.closeTime, "Staking period not over");
            market.state = MarketState.Closed;
            // Market needs resolvers to submit. State transitions to AwaitingResolution upon submission.
            return;
        }

        // If state is Closed and no resolution was reached by enough resolvers
        if (market.state == MarketState.Closed && block.timestamp >= market.resolutionTime + challengePeriodDuration) {
            // If resolution time passed and no consensus after potential extensions, then default to AwaitingResolution
            // or a mechanism to refund all stakes (not implemented for brevity here).
            market.state = MarketState.AwaitingResolution; // Stays awaiting resolution indefinitely
            return;
        }

        if (market.state == MarketState.Resolved) {
            // This means a provisional majority resolution was found and it's awaiting challenge period end.
            require(block.timestamp >= market.challengeEndTime, "Challenge period not over");
            // If it reaches here, challenge period ended without a valid challenge or the challenge failed (no votes).
            emit MarketResolved(_marketId, market.resolvedOutcomeIndex);
            // Funds are now ready to be claimed by stakers on the resolved outcome.
            return;
        }

        if (market.state == MarketState.ChallengedResolution) {
            require(block.timestamp >= market.challengeEndTime, "Voting period not over");

            uint256 totalVotes = market.challengeTotalVotesFor + market.challengeTotalVotesAgainst;

            if (totalVotes == 0 || market.challengeTotalVotesFor >= market.challengeTotalVotesAgainst) {
                // Initial resolution supported by majority vote OR no votes were cast (default to original)
                market.resolvedOutcomeIndex = market.majorityResolutionOutcome;
                market.state = MarketState.Resolved;
                // Slashing challenger if they lost or no votes cast
                if (market.challengeStake > 0 && totalVotes > 0) { // Only slash if votes were cast and challenger lost
                    _slashResolver(market.currentChallenger, market.challengeStake);
                }
            } else {
                // Initial resolution rejected by majority vote
                market.resolvedOutcomeIndex = type(uint256).max; // Nullify resolution
                market.state = MarketState.AwaitingResolution; // Revert for new resolution submissions

                // Reward challenger if they won
                if (market.challengeStake > 0) {
                    aoToken.transfer(market.currentChallenger, market.challengeStake); // Challenger gets stake back
                    // Optionally, add a reward for successful challenge
                }

                // Slashing resolvers who contributed to the rejected majority resolution
                for (uint256 i = 0; i < market.submittedResolvers.length; i++) {
                    address resolverAddr = market.submittedResolvers[i];
                    if (market.resolverSubmissions[resolverAddr] == market.majorityResolutionOutcome) {
                         // Simple proportional slashing: e.g., 10% of minResolverStake for each incorrect resolver
                        _slashResolver(resolverAddr, minResolverStake / 10);
                    }
                }
            }
            market.currentChallenger = address(0); // Clear challenger after resolution
            market.challengeStake = 0; // Clear stake

            emit MarketResolved(_marketId, market.resolvedOutcomeIndex);
        }
    }

    /// @notice (Internal/DAO callable) Slashing mechanism for misbehaving resolvers or failed challengers.
    /// @param _resolverAddress The address of the resolver/challenger to slash.
    /// @param _amount The amount of AO tokens to slash.
    function _slashResolver(address _resolverAddress, uint256 _amount) internal {
        Resolver storage resolver = resolvers[_resolverAddress];
        require(resolver.isRegistered, "Address not a registered resolver for slashing purposes");
        // We use resolver struct for general slashing, even if it's an AI agent or a regular user staking for challenge.
        // A more complex system might have separate structs for challenger stakes.
        require(resolver.stake >= _amount, "Slash amount exceeds resolver stake");

        resolver.stake -= _amount;
        resolver.reputationScore -= 10; // Decrease reputation

        // Slashed funds are transferred to the contract owner (acting as a treasury in this example).
        aoToken.transfer(owner(), _amount);

        emit ResolverSlashed(_resolverAddress, _amount);
    }

    // --- III. AI Agent Integration & Knowledge Graph ---

    /// @notice Allows an AI agent to register with the platform, requiring a stake and providing metadata.
    /// @param _aiAgentName The name of the AI agent.
    /// @param _aiAgentUri URI pointing to AI agent details/documentation (e.g., IPFS hash of a description).
    /// @param _stakeAmount The amount of AO tokens to stake as an AI agent.
    function registerAIAgent(string memory _aiAgentName, string memory _aiAgentUri, uint256 _stakeAmount) external nonReentrant {
        require(!aiAgents[msg.sender].isRegistered, "Already a registered AI agent");
        require(_stakeAmount >= minAIAgentStake, "Stake amount too low");
        require(bytes(_aiAgentName).length > 0, "AI Agent name cannot be empty");
        require(bytes(_aiAgentUri).length > 0, "AI Agent URI cannot be empty");

        aoToken.transferFrom(msg.sender, address(this), _stakeAmount);

        AIAgent storage agent = aiAgents[msg.sender];
        agent.name = _aiAgentName;
        agent.uri = _aiAgentUri;
        agent.stake = _stakeAmount;
        agent.reputationScore = 0; // Initialize reputation
        agent.isRegistered = true;

        emit AIAgentRegistered(msg.sender, _aiAgentName, _stakeAmount);
    }

    /// @notice A registered AI agent submits their suggested resolution for a market, influencing consensus.
    /// @param _marketId The ID of the market.
    /// @param _aiSuggestedOutcome The outcome index suggested by the AI.
    /// @param _aiEvidenceUri URI pointing to evidence generated by the AI.
    function submitAIConsensus(uint256 _marketId, uint256 _aiSuggestedOutcome, string memory _aiEvidenceUri)
        external
        nonReentrant
        onlyRegisteredAIAgent
        isMarketResolvable(_marketId)
    {
        Market storage market = markets[_marketId];
        require(_aiSuggestedOutcome < market.outcomes.length, "Invalid outcome index");
        require(market.state != MarketState.Resolved && market.state != MarketState.Finalized, "Market already resolved or finalized");

        // Simple aggregation logic: The first AI to submit for a market sets the AI consensus outcome.
        // Subsequent AIs increment a counter if they agree, or decrease reputation if they disagree.
        // In a real system, a more sophisticated AI consensus (e.g., weighted by reputation, multiple rounds)
        // and verification of AI computation (e.g., ZK proofs) would be necessary.
        if (market.aiConsensusCount == 0) {
            market.aiConsensusOutcome = _aiSuggestedOutcome;
            market.aiConsensusCount = 1;
            aiAgents[msg.sender].reputationScore += 1; // Initial reward for setting consensus
        } else {
            if (market.aiConsensusOutcome == _aiSuggestedOutcome) {
                market.aiConsensusCount++;
                aiAgents[msg.sender].reputationScore += 1; // Reward for agreeing with existing consensus
            } else {
                aiAgents[msg.sender].reputationScore -= 1; // Penalize for disagreeing with existing consensus
            }
        }
        // The _aiEvidenceUri could be stored but is omitted from Market struct for gas/size.

        emit AIConsensusSubmitted(_marketId, msg.sender, _aiSuggestedOutcome);
    }

    /// @notice Allows a "knowledge synthesizer" (human or AI) to propose a structured knowledge triple based on a resolved market.
    /// This is for creating verifiable facts based on resolved predictions.
    /// @param _marketId The ID of the market this knowledge is derived from.
    /// @param _knowledgeTripleSubject The subject of the knowledge triple (e.g., "Ethereum").
    /// @param _knowledgeTriplePredicate The predicate (e.g., "priceAtYearEnd").
    /// @param _knowledgeTripleObject The object (e.g., "$5000").
    /// @param _evidenceUri URI to external evidence or a reference to the market's resolution.
    function synthesizeKnowledge(
        uint256 _marketId,
        string memory _knowledgeTripleSubject,
        string memory _knowledgeTriplePredicate,
        string memory _knowledgeTripleObject,
        string memory _evidenceUri
    ) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.state == MarketState.Resolved, "Knowledge can only be synthesized from resolved markets");
        require(bytes(_knowledgeTripleSubject).length > 0, "Subject cannot be empty");
        require(bytes(_knowledgeTriplePredicate).length > 0, "Predicate cannot be empty");
        require(bytes(_knowledgeTripleObject).length > 0, "Object cannot be empty");

        uint256 tripleId = nextKnowledgeTripleId++;
        KnowledgeTriple storage newTriple = knowledgeGraph[tripleId];
        newTriple.marketId = _marketId;
        newTriple.subject = _knowledgeTripleSubject;
        newTriple.predicate = _knowledgeTriplePredicate;
        newTriple.object = _knowledgeTripleObject;
        newTriple.evidenceUri = _evidenceUri;
        newTriple.status = KnowledgeStatus.Proposed;
        newTriple.proposer = msg.sender;
        newTriple.challengeEndTime = block.timestamp + challengePeriodDuration;

        // Optionally, require a bond for proposing knowledge triples, similar to markets.

        emit KnowledgeTripleProposed(tripleId, _marketId, msg.sender);
    }

    /// @notice Users can challenge a proposed knowledge triple, initiating a validation dispute.
    /// @param _knowledgeTripleId The ID of the knowledge triple to challenge.
    /// @param _challengerStake The amount of AO tokens to stake for the challenge.
    function challengeKnowledgeTriple(uint256 _knowledgeTripleId, uint256 _challengerStake) external nonReentrant {
        KnowledgeTriple storage triple = knowledgeGraph[_knowledgeTripleId];
        require(triple.status == KnowledgeStatus.Proposed, "Knowledge triple not in proposed state");
        require(block.timestamp < triple.challengeEndTime, "Challenge period has ended");
        require(_challengerStake > 0, "Challenger stake must be greater than zero");
        require(triple.currentChallenger == address(0), "Knowledge triple already challenged");

        aoToken.transferFrom(msg.sender, address(this), _challengerStake);

        triple.status = KnowledgeStatus.Challenged;
        triple.currentChallenger = msg.sender;
        triple.challengeStake = _challengerStake;
        triple.challengeEndTime = block.timestamp + votingPeriodDuration; // New voting period for challenge
        triple.challengeTotalVotesFor = 0;
        triple.challengeTotalVotesAgainst = 0;
        // Clear votes for this specific challenge instance
        delete triple.hasVotedOnChallenge[msg.sender];
        delete triple.hasVotedOnChallenge[triple.proposer]; // Proposer can also vote

        emit KnowledgeTripleChallenged(_knowledgeTripleId, msg.sender, _challengerStake);
    }

    /// @notice Participants vote on the validity of a challenged knowledge triple.
    /// @param _knowledgeTripleId The ID of the knowledge triple under challenge.
    /// @param _supportsKnowledge True if the voter supports the proposed knowledge, false otherwise.
    function voteOnKnowledgeChallenge(uint256 _knowledgeTripleId, bool _supportsKnowledge) external nonReentrant hasGovernancePower(msg.sender) {
        KnowledgeTriple storage triple = knowledgeGraph[_knowledgeTripleId];
        require(triple.status == KnowledgeStatus.Challenged, "Knowledge triple not in challenge state");
        require(block.timestamp < triple.challengeEndTime, "Voting period has ended");
        require(!triple.hasVotedOnChallenge[msg.sender], "Already voted on this challenge");

        triple.hasVotedOnChallenge[msg.sender] = true;
        if (_supportsKnowledge) {
            triple.challengeTotalVotesFor += governanceDeposits[msg.sender];
        } else {
            triple.challengeTotalVotesAgainst += governanceDeposits[msg.sender];
        }

        emit KnowledgeTripleVote(_knowledgeTripleId, msg.sender, _supportsKnowledge);
    }

    /// @notice Finalizes a knowledge triple after its validation period or challenge, adding it to the graph.
    /// Can be called by anyone.
    /// @param _knowledgeTripleId The ID of the knowledge triple to finalize.
    function finalizeKnowledgeTriple(uint256 _knowledgeTripleId) external nonReentrant {
        KnowledgeTriple storage triple = knowledgeGraph[_knowledgeTripleId];
        require(triple.status != KnowledgeStatus.Validated, "Knowledge triple already validated");

        if (triple.status == KnowledgeStatus.Proposed) {
            require(block.timestamp >= triple.challengeEndTime, "Challenge period not over");
            triple.status = KnowledgeStatus.Validated;
            emit KnowledgeTripleValidated(_knowledgeTripleId, triple.marketId);
            // Optionally, reward proposer here if a bond was required and it passed.
            return;
        }

        if (triple.status == KnowledgeStatus.Challenged) {
            require(block.timestamp >= triple.challengeEndTime, "Voting period not over");

            uint256 totalVotes = triple.challengeTotalVotesFor + triple.challengeTotalVotesAgainst;

            if (totalVotes == 0 || triple.challengeTotalVotesFor >= triple.challengeTotalVotesAgainst) {
                // Knowledge supported by majority or no votes cast (default to proposed being valid)
                triple.status = KnowledgeStatus.Validated;
                // Challenger loses stake if they failed or no votes
                if (triple.challengeStake > 0 && totalVotes > 0) {
                    // Use resolver slash for general slashing, assuming proposer/challenger has a Resolver entry
                    _slashResolver(triple.currentChallenger, triple.challengeStake);
                }
            } else {
                // Knowledge rejected by majority vote
                triple.status = KnowledgeStatus.Proposed; // Revert to proposed, needs new synthesis or correction
                // Challenger wins stake back
                if (triple.challengeStake > 0) {
                    aoToken.transfer(triple.currentChallenger, triple.challengeStake);
                    // Optionally, reward challenger for successful challenge
                }
            }
            triple.currentChallenger = address(0);
            triple.challengeStake = 0;
            emit KnowledgeTripleValidated(_knowledgeTripleId, triple.marketId);
        }
    }

    /// @notice View function to retrieve validated knowledge triples based on subject and predicate.
    /// Note: On-chain query for complex graph traversal is limited. This is a simplified lookup.
    /// For a real knowledge graph, off-chain indexing is necessary for efficient and complex queries.
    /// @param _subject The subject to query for.
    /// @param _predicate The predicate to query for.
    /// @return An array of objects matching the subject and predicate.
    function queryKnowledgeGraph(string memory _subject, string memory _predicate)
        public
        view
        returns (string[] memory objects)
    {
        uint256 count = 0;
        // Count how many matching validated triples exist
        for (uint256 i = 0; i < nextKnowledgeTripleId; i++) {
            KnowledgeTriple storage triple = knowledgeGraph[i];
            if (triple.status == KnowledgeStatus.Validated &&
                keccak256(abi.encodePacked(triple.subject)) == keccak256(abi.encodePacked(_subject)) &&
                keccak256(abi.encodePacked(triple.predicate)) == keccak256(abi.encodePacked(_predicate)))
            {
                count++;
            }
        }

        objects = new string[](count);
        uint256 currentIdx = 0;
        // Populate the array with matching objects
        for (uint256 i = 0; i < nextKnowledgeTripleId; i++) {
            KnowledgeTriple storage triple = knowledgeGraph[i];
            if (triple.status == KnowledgeStatus.Validated &&
                keccak256(abi.encodePacked(triple.subject)) == keccak256(abi.encodePacked(_subject)) &&
                keccak256(abi.encodePacked(triple.predicate)) == keccak256(abi.encodePacked(_predicate)))
            {
                objects[currentIdx] = triple.object;
                currentIdx++;
            }
        }
        return objects;
    }

    // --- IV. Governance (DAO) System ---

    /// @notice Users deposit tokens to gain voting power for governance proposals.
    /// @param _amount The amount of AO tokens to deposit.
    function depositForGovernance(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Deposit amount must be greater than zero");
        aoToken.transferFrom(msg.sender, address(this), _amount);
        governanceDeposits[msg.sender] += _amount;
        emit GovernanceDeposit(msg.sender, _amount);
    }

    /// @notice Users withdraw their deposited tokens from governance.
    /// @param _amount The amount of AO tokens to withdraw.
    function withdrawFromGovernance(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(governanceDeposits[msg.sender] >= _amount, "Insufficient governance balance");
        governanceDeposits[msg.sender] -= _amount;
        aoToken.transfer(msg.sender, _amount);
        emit GovernanceWithdrawal(msg.sender, _amount);
    }

    /// @notice Token holders can create new governance proposals to modify protocol parameters or actions.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract to call if the proposal passes.
    /// @param _callData The calldata to send to the target contract.
    /// @return proposalId The unique ID of the newly created proposal.
    function createGovernanceProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external nonReentrant hasGovernancePower(msg.sender) returns (uint256) {
        require(governanceDeposits[msg.sender] > 0, "Must have governance power to propose");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.description = _description;
        newProposal.targetContract = _targetContract;
        newProposal.callData = _callData;
        newProposal.startBlock = block.number;
        // Approx blocks per second (e.g., 13s/block on Ethereum mainnet)
        newProposal.endBlock = block.number + (votingPeriodDuration / 13);
        newProposal.state = ProposalState.Active;
        newProposal.proposer = msg.sender;

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /// @notice Users vote on active governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "yes" (support), false for "no" (against).
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant hasGovernancePower(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterWeight = governanceDeposits[msg.sender];
        require(voterWeight > 0, "No governance power to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.voteCountFor += voterWeight;
        } else {
            proposal.voteCountAgainst += voterWeight;
        }

        emit ProposalVote(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal that has successfully passed.
    /// Can be called by anyone, validity checked internally.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number > proposal.endBlock, "Voting period not over");
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        uint256 totalGovernanceSupply = aoToken.balanceOf(address(this)); // Total tokens held by contract for governance
        // For a more precise quorum, sum all values in `governanceDeposits` mapping.
        // `aoToken.balanceOf(address(this))` represents all tokens sent to the contract, including market stakes.
        // A dedicated `totalGovernanceDeposits` variable or iteration would be needed for absolute precision.
        // Using `balanceOf` is a common but imperfect proxy for total voting power.

        uint224 totalVotesCast = proposal.voteCountFor + proposal.voteCountAgainst;
        require(totalGovernanceSupply > 0, "No total governance supply to calculate quorum against");

        uint256 requiredQuorum = (totalGovernanceSupply * governanceQuorumBps) / 10000;

        if (totalVotesCast < requiredQuorum) {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
            revert("Quorum not met");
        }

        // Calculate vote threshold against cast votes
        require(totalVotesCast > 0, "No votes cast to calculate threshold");
        uint256 thresholdPercentage = (proposal.voteCountFor * 10000) / totalVotesCast;
        if (thresholdPercentage < governanceVoteThresholdBps) {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
            revert("Vote threshold not met");
        }

        // Proposal passed
        proposal.state = ProposalState.Succeeded;
        emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);

        // Execute the proposal by calling the target contract with the specified calldata
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    // --- V. Parameter & Utility Functions ---

    /// @notice Updates the minimum stake required for market proposers, resolvers, and AI agents.
    /// In a full DAO, this function would be callable only via a successful governance proposal.
    /// For this example, it's set to `onlyOwner` for demonstration purposes.
    /// @param _newStake The new minimum stake amount.
    function updateMinimumStake(uint256 _newStake) external onlyOwner {
        require(_newStake > 0, "New stake must be greater than zero");
        minMarketProposerBond = _newStake;
        minResolverStake = _newStake;
        minAIAgentStake = _newStake;
        emit ProtocolParameterUpdated("minStake", _newStake);
    }

    /// @notice Sets the market fee percentage (in basis points).
    /// In a full DAO, this function would be callable only via a successful governance proposal.
    /// For this example, it's set to `onlyOwner` for demonstration purposes.
    /// @param _newFeeBps The new fee in basis points (e.g., 500 for 5%).
    function setMarketFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%"); // 10000 bps = 100%
        marketFeeBps = _newFeeBps;
        emit ProtocolParameterUpdated("marketFeeBps", _newFeeBps);
    }

    /// @notice Sets the duration of the challenge period (for market resolutions and knowledge triples).
    /// In a full DAO, this function would be callable only via a successful governance proposal.
    /// For this example, it's set to `onlyOwner` for demonstration purposes.
    /// @param _newPeriod The new duration in seconds.
    function setChallengePeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "Period must be positive");
        challengePeriodDuration = _newPeriod;
        emit ProtocolParameterUpdated("challengePeriodDuration", _newPeriod);
    }

    /// @notice View function to retrieve comprehensive details about a specific market.
    /// @param _marketId The ID of the market.
    /// @return marketDetails A tuple containing all relevant market data.
    function getMarketDetails(uint256 _marketId)
        public
        view
        returns (
            string memory question,
            string[] memory outcomes,
            uint256 closeTime,
            uint256 resolutionTime,
            uint256 proposerBond,
            address proposer,
            MarketState state,
            uint256 resolvedOutcomeIndex,
            uint256 totalStaked,
            uint256 challengeEndTime,
            uint256 challengeTotalVotesFor,
            uint256 challengeTotalVotesAgainst,
            address currentChallenger,
            uint256 challengeStake,
            uint256 majorityResolutionOutcome,
            uint256 aiConsensusOutcome,
            uint256 aiConsensusCount
        )
    {
        Market storage market = markets[_marketId];
        return (
            market.question,
            market.outcomes,
            market.closeTime,
            market.resolutionTime,
            market.proposerBond,
            market.proposer,
            market.state,
            market.resolvedOutcomeIndex,
            market.totalStaked,
            market.challengeEndTime,
            market.challengeTotalVotesFor,
            market.challengeTotalVotesAgainst,
            market.currentChallenger,
            market.challengeStake,
            market.majorityResolutionOutcome,
            market.aiConsensusOutcome,
            market.aiConsensusCount
        );
    }

    /// @notice View function to get the total amount staked on a particular outcome.
    /// @param _marketId The ID of the market.
    /// @param _outcomeIndex The index of the outcome.
    /// @return The total amount staked on that outcome.
    function getOutcomePool(uint256 _marketId, uint256 _outcomeIndex) public view returns (uint256) {
        return markets[_marketId].outcomeStakes[_outcomeIndex];
    }

    /// @notice View function to get a user's total stake across all outcomes in a market.
    /// @param _marketId The ID of the market.
    /// @param _user The address of the user.
    /// @return The total amount the user staked in the market.
    function getUserStake(uint256 _marketId, address _user) public view returns (uint256 totalUserStake) {
        Market storage market = markets[_marketId];
        // Iterate through all possible outcomes to sum up user's stakes
        for (uint256 i = 0; i < market.outcomes.length; i++) {
            totalUserStake += market.userOutcomeStakes[_user][i];
        }
        return totalUserStake;
    }

    /// @notice View function to check the registration status and reputation of a resolver.
    /// @param _resolverAddress The address of the resolver.
    /// @return isRegistered Whether the resolver is registered.
    /// @return stake The resolver's current stake.
    /// @return reputationScore The resolver's reputation score.
    function getResolverStatus(address _resolverAddress)
        public
        view
        returns (bool isRegistered, uint256 stake, int256 reputationScore)
    {
        Resolver storage resolver = resolvers[_resolverAddress];
        return (resolver.isRegistered, resolver.stake, resolver.reputationScore);
    }

    /// @notice View function to get details about a registered AI agent.
    /// @param _aiAgentAddress The address of the AI agent.
    /// @return name The AI agent's name.
    /// @return uri The AI agent's URI.
    /// @return stake The AI agent's current stake.
    /// @return reputationScore The AI agent's reputation score.
    function getAIAgentDetails(address _aiAgentAddress)
        public
        view
        returns (string memory name, string memory uri, uint256 stake, int256 reputationScore)
    {
        AIAgent storage agent = aiAgents[_aiAgentAddress];
        return (agent.name, agent.uri, agent.stake, agent.reputationScore);
    }

    /// @notice View function to retrieve details of a specific knowledge triple.
    /// @param _knowledgeTripleId The ID of the knowledge triple.
    /// @return tripleDetails A tuple containing all knowledge triple data.
    function getKnowledgeTriple(uint256 _knowledgeTripleId)
        public
        view
        returns (
            uint256 marketId,
            string memory subject,
            string memory predicate,
            string memory object,
            string memory evidenceUri,
            KnowledgeStatus status,
            address proposer,
            uint256 challengeEndTime,
            uint256 challengeTotalVotesFor,
            uint256 challengeTotalVotesAgainst,
            address currentChallenger,
            uint256 challengeStake
        )
    {
        KnowledgeTriple storage triple = knowledgeGraph[_knowledgeTripleId];
        return (
            triple.marketId,
            triple.subject,
            triple.predicate,
            triple.object,
            triple.evidenceUri,
            triple.status,
            triple.proposer,
            triple.challengeEndTime,
            triple.challengeTotalVotesFor,
            triple.challengeTotalVotesAgainst,
            triple.currentChallenger,
            triple.challengeStake
        );
    }

    /// @notice View function to get the total number of markets created.
    /// @return The total number of markets.
    function getTotalMarkets() public view returns (uint256) {
        return nextMarketId;
    }

    /// @notice View function to get the total number of governance proposals.
    /// @return The total number of proposals.
    function getTotalProposals() public view returns (uint256) {
        return nextProposalId;
    }

    /// @notice View function to get a user's deposited governance token balance.
    /// @param _user The address of the user.
    /// @return The amount of tokens deposited for governance.
    function getGovernanceBalance(address _user) public view returns (uint256) {
        return governanceDeposits[_user];
    }
}

// Minimal IERC20 Interface for compilation demonstration.
// In a real project, import from @openzeppelin/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
```