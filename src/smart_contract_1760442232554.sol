Here's a smart contract written in Solidity, incorporating interesting, advanced, creative, and trendy concepts related to decentralized AI agents, dynamic NFTs, and soulbound reputation.

---

## CognitoNexus: Decentralized AI Agent & Insight Network

This contract establishes a platform for the decentralized governance, operation, and monetization of AI agents. It integrates several advanced concepts:

*   **DAO Governance:** For the lifecycle management of AI agents (proposal, approval, deprecation).
*   **Oracle Integration:** Enables off-chain AI agents to submit insights and results on-chain.
*   **Dynamic NFTs:** Features generative AI art NFTs whose parameters can be updated post-mint.
*   **Soulbound Reputation:** Implements a non-transferable reputation badge system for user contributions.
*   **Insight Marketplace:** Allows users to subscribe to AI insights or request custom ones, with built-in challenge mechanisms for quality assurance.
*   **Staking Mechanisms:** For both challenging and positively validating AI insights.
*   **Internal Accounting:** Manages user funds for subscriptions, requests, and staking.

### Outline:

1.  **Core Infrastructure & Governance (DAO-like)**
    *   Contract Initialization
    *   AI Agent Proposal & Voting System
    *   Governance Parameter Updates
    *   Voting Delegation
    *   Treasury Management
2.  **AI Agent Management & Operation**
    *   Oracle Registration for Agents
    *   AI Insight Submission
    *   Insight Challenge & Resolution Mechanism
    *   Agent Deprecation
3.  **Insight Marketplace & Subscription**
    *   Subscription Model for Insights
    *   Custom AI Insight Requests with Bounties
    *   Subscription Cancellation & Pro-Rata Refunds
    *   Agent Fund Claiming
4.  **Reputation & Dynamic NFTs**
    *   Soulbound Reputation Badges (Non-Transferable)
    *   Generative AI Art NFTs (ERC721-like, with mutable parameters)
    *   Staking for Positive Insight Validation
5.  **Utility & Read-Only Functions**
    *   User Fund Deposit & Withdrawal
    *   Data Retrieval for Agents, Insights, Proposals, Challenges, and NFTs

### Function Summary:

#### I. Core Infrastructure & Governance:

1.  `initializeContract(address _initialGovernor)`: Initializes the contract, setting the first governor. Callable only once.
2.  `proposeAgent(string _agentName, string _modelIPFSHash, string _description, uint256 _requiredStake)`: Allows a user to propose a new AI agent for DAO approval.
3.  `voteOnAgentProposal(uint256 _proposalId, bool _support)`: Allows a voter to cast a vote on an active agent proposal.
4.  `executeAgentProposal(uint256 _proposalId)`: Executes a passed agent proposal, registering the new AI agent.
5.  `updateGovernanceParameters(uint256 _newQuorumNumerator, uint256 _newVotingPeriodDays)`: Updates core DAO governance parameters like quorum and voting period.
6.  `delegateVote(address _delegate)`: Delegates voting power to another address.
7.  `revokeDelegate()`: Revokes any active voting delegation.
8.  `distributeTreasuryFunds(address _recipient, uint256 _amount)`: Allows the governor to distribute funds from the contract's treasury (conceptually, would require a DAO proposal).

#### II. AI Agent Management & Operation:

9.  `registerAgentOracle(uint256 _agentId, address _oracleAddress)`: Registers an oracle address responsible for submitting insights for a specific agent.
10. `submitAgentInsight(uint256 _agentId, bytes32 _insightHash, string _insightMetadataURI)`: An authorized oracle submits a new AI insight.
11. `challengeAgentInsight(uint256 _insightId, string _reasonURI, uint256 _stakeAmount)`: Allows a user to challenge the validity of an AI insight, staking funds.
12. `resolveInsightChallenge(uint256 _challengeId, bool _validChallenge)`: Governor (or DAO) resolves an insight challenge, distributing staked funds.
13. `deprecateAgent(uint256 _agentId)`: Initiates the process to mark an existing AI agent as inactive (governor-only for simplicity, could be DAO proposed).

#### III. Insight Marketplace & Subscription:

14. `subscribeToAgentInsights(uint256 _agentId, uint256 _durationInDays, uint256 _pricePerDay)`: Subscribes to an agent's insights for a specified duration using deposited funds.
15. `requestCustomInsight(uint256 _agentId, string _requestPromptURI, uint256 _bounty)`: Requests a custom insight from an agent with a bounty attached.
16. `cancelSubscription(uint256 _agentId)`: Cancels an active subscription to an agent's insights, with pro-rata refund.
17. `claimAgentSubscriptionFunds(uint256 _agentId)`: Allows the owner of an AI agent to claim accumulated subscription and bounty funds.

#### IV. Reputation & Dynamic NFTs:

18. `awardReputationBadge(address _recipient, uint256 _score, string _metadataURI)`: Awards or updates a soulbound reputation badge to a user based on their contributions (governor-only).
19. `updateReputationBadge(address _recipient, uint256 _newScore, string _newMetadataURI)`: Updates the score and metadata of an existing reputation badge (governor-only).
20. `createGenerativeAIArtNFT(uint256 _agentId, bytes32 _artParametersHash, string _artMetadataURI)`: Mints a new dynamic ERC721-like NFT representing AI-generated art.
21. `updateGenerativeAIArtNFTParameters(uint256 _tokenId, bytes32 _newParametersHash)`: Updates the parameters of an existing generative AI art NFT, allowing it to "evolve."
22. `stakeForInsightValidation(uint256 _insightId, uint256 _amount)`: Users can stake funds to positively validate an insight, showing support and confidence.

#### V. Utility & Read-Only Functions:

23. `depositFunds()`: Allows users to deposit ETH into their internal contract balance for marketplace activities.
24. `withdrawFunds(uint256 _amount)`: Allows users to withdraw their available internal contract balance.
25. `getAgentInsight(uint256 _insightId)`: Returns the details of a specific AI insight.
26. `getAgentDetails(uint256 _agentId)`: Returns the details of a specific AI agent.
27. `getAgentProposal(uint256 _proposalId)`: Returns the details of an agent proposal.
28. `getInsightChallenge(uint256 _challengeId)`: Returns the details of an insight challenge.
29. `ownerOfGenerativeArtNFT(uint256 _tokenId)`: Returns the owner of a generative art NFT.
30. `tokenURIGenerativeArtNFT(uint256 _tokenId)`: Returns the token URI of a generative art NFT.
31. `totalSupplyGenerativeArtNFTs()`: Returns the total count of minted generative art NFTs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contract is a concept for a "CognitoNexus: Decentralized AI Agent & Insight Network".
// It aims to create a platform where AI agents (off-chain models) can be proposed, governed,
// and monetized, with their insights submitted on-chain via oracles.
// It incorporates DAO governance, dynamic NFTs for AI-generated art, and a simple
// soulbound token (SBT) like mechanism for user reputation.

// Outline:
// 1.  Core Infrastructure & Governance (DAO-like)
//     - Contract Initialization
//     - Agent Proposal & Voting
//     - Governance Parameter Updates
//     - Voting Delegation
//     - Treasury Management
// 2.  AI Agent Management & Operation
//     - Oracle Registration
//     - Insight Submission
//     - Insight Challenge & Resolution
//     - Agent Deprecation
// 3.  Insight Marketplace & Subscription
//     - Subscription to Insights
//     - Custom Insight Requests
//     - Subscription Cancellation & Fund Claim
// 4.  Reputation & Dynamic NFTs
//     - Soulbound Reputation Badges
//     - Generative AI Art NFTs (ERC721-like)
//     - Staking for Validation
// 5.  Utility & Read-Only Functions
//     - Fund Management (Deposit/Withdraw)
//     - Data Retrieval Functions

// Function Summary:
//
// I. Core Infrastructure & Governance:
// 1.  initializeContract(address _initialGovernor): Initializes the contract, setting the first governor. Callable once.
// 2.  proposeAgent(string _agentName, string _modelIPFSHash, string _description, uint256 _requiredStake): Allows a user to propose a new AI agent to the DAO.
// 3.  voteOnAgentProposal(uint256 _proposalId, bool _support): Allows a voter to cast a vote on an active agent proposal.
// 4.  executeAgentProposal(uint256 _proposalId): Executes a passed agent proposal, registering the new agent.
// 5.  updateGovernanceParameters(uint256 _newQuorumNumerator, uint256 _newVotingPeriodDays): Updates core DAO governance parameters.
// 6.  delegateVote(address _delegate): Delegates voting power to another address.
// 7.  revokeDelegate(): Revokes any active voting delegation.
// 8.  distributeTreasuryFunds(address _recipient, uint256 _amount): Allows the governor to distribute funds from the contract's treasury (conceptually, would require a DAO proposal).
//
// II. AI Agent Management & Operation:
// 9.  registerAgentOracle(uint256 _agentId, address _oracleAddress): Registers an oracle address responsible for submitting insights for a specific agent.
// 10. submitAgentInsight(uint256 _agentId, bytes32 _insightHash, string _insightMetadataURI): An authorized oracle submits a new AI insight.
// 11. challengeAgentInsight(uint256 _insightId, string _reasonURI, uint256 _stakeAmount): Allows a user to challenge the validity of an AI insight, staking funds.
// 12. resolveInsightChallenge(uint256 _challengeId, bool _validChallenge): Governor/DAO resolves an insight challenge, distributing staked funds.
// 13. deprecateAgent(uint256 _agentId): Initiates the process to mark an existing AI agent as inactive (governor-only for simplicity, could be DAO proposed).
//
// III. Insight Marketplace & Subscription:
// 14. subscribeToAgentInsights(uint256 _agentId, uint256 _durationInDays, uint256 _pricePerDay): Subscribes to an agent's insights for a specified duration using deposited funds.
// 15. requestCustomInsight(uint256 _agentId, string _requestPromptURI, uint256 _bounty): Requests a custom insight from an agent with a bounty attached.
// 16. cancelSubscription(uint256 _agentId): Cancels an active subscription to an agent's insights, with pro-rata refund.
// 17. claimAgentSubscriptionFunds(uint256 _agentId): Allows the owner of an AI agent to claim accumulated subscription funds.
//
// IV. Reputation & Dynamic NFTs:
// 18. awardReputationBadge(address _recipient, uint256 _score, string _metadataURI): Awards or updates a soulbound reputation badge to a user based on their contributions (governor-only).
// 19. updateReputationBadge(address _recipient, uint256 _newScore, string _newMetadataURI): Updates the score and metadata of an existing reputation badge (governor-only).
// 20. createGenerativeAIArtNFT(uint256 _agentId, bytes32 _artParametersHash, string _artMetadataURI): Mints a new dynamic ERC721-like NFT representing AI-generated art.
// 21. updateGenerativeAIArtNFTParameters(uint256 _tokenId, bytes32 _newParametersHash): Updates the parameters of an existing generative AI art NFT, allowing it to "evolve."
// 22. stakeForInsightValidation(uint256 _insightId, uint256 _amount): Users can stake funds to positively validate an insight, showing support and confidence.
//
// V. Utility & Read-Only Functions:
// 23. depositFunds(): Allows users to deposit ETH into their internal contract balance.
// 24. withdrawFunds(uint256 _amount): Allows users to withdraw their available balance.
// 25. getAgentInsight(uint256 _insightId): Returns the details of a specific AI insight.
// 26. getAgentDetails(uint256 _agentId): Returns the details of a specific AI agent.
// 27. getAgentProposal(uint256 _proposalId): Returns the details of an agent proposal.
// 28. getInsightChallenge(uint256 _challengeId): Returns the details of an insight challenge.
// 29. ownerOfGenerativeArtNFT(uint256 _tokenId): Returns the owner of a generative art NFT.
// 30. tokenURIGenerativeArtNFT(uint256 _tokenId): Returns the token URI of a generative art NFT.
// 31. totalSupplyGenerativeArtNFTs(): Returns the total count of minted generative art NFTs.

contract CognitoNexus {

    // --- Events ---
    event Initialized(address indexed initialGovernor);
    event AgentProposed(uint256 indexed proposalId, address indexed proposer, string agentName, uint256 requiredStake);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event AgentRegistered(uint256 indexed agentId, string agentName, address indexed owner);
    event GovernanceParametersUpdated(uint256 newQuorumNumerator, uint256 newVotingPeriod);
    event AgentDeprecated(uint256 indexed agentId);

    event OracleRegistered(uint256 indexed agentId, address indexed oracleAddress);
    event InsightSubmitted(uint256 indexed insightId, uint256 indexed agentId, bytes32 insightHash);
    event InsightChallenged(uint256 indexed challengeId, uint256 indexed insightId, address indexed challenger, uint256 stakedAmount);
    event InsightChallengeResolved(uint256 indexed challengeId, uint256 indexed insightId, bool validChallenge, uint256 rewardAmount);

    event SubscriptionCreated(uint256 indexed agentId, address indexed subscriber, uint256 durationInDays, uint256 totalCost);
    event SubscriptionCancelled(uint256 indexed agentId, address indexed subscriber);
    event CustomInsightRequested(uint256 indexed agentId, uint256 indexed requestId, address indexed requester, uint256 bounty);
    event AgentFundsClaimed(uint256 indexed agentId, address indexed agentOwner, uint256 amount);

    event ReputationBadgeAwarded(address indexed recipient, uint256 newScore, string metadataURI);
    event ReputationBadgeUpdated(address indexed recipient, uint256 newScore, string newMetadataURI);
    event GenerativeArtNFTMinted(uint256 indexed tokenId, uint256 indexed agentId, address indexed owner, bytes32 artParametersHash);
    event GenerativeArtNFTParametersUpdated(uint256 indexed tokenId, bytes32 newParametersHash);
    event InsightValidationStaked(uint256 indexed insightId, address indexed validator, uint256 amount);

    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event TreasuryDistributed(address indexed recipient, uint256 amount);

    // --- Errors ---
    error AlreadyInitialized();
    error NotInitialized();
    error Unauthorized();
    error AgentNotFound();
    error ProposalNotFound();
    error NotEnoughVotes();
    error ProposalNotApproved();
    error ProposalExpiredOrNotReady();
    error InvalidVotingPeriod();
    error AlreadyVoted();
    error NoActiveSubscription();
    error SubscriptionStillActive();
    error InsufficientFunds();
    error AgentAlreadyRegistered(); // Not used directly, but good to have
    error OracleAlreadyRegistered();
    error NotAgentOwnerOrOracle();
    error InsightNotFound();
    error ChallengeNotFound();
    error ChallengeAlreadyResolved();
    error AgentNotActive();
    error ReputationBadgeNotFound();
    error NFTNotFound();
    error NotNFTOwner();
    error AgentHasNoFundsToClaim();
    error NoDepositToWithdraw();
    error NotGovernor();

    // --- State Variables ---

    bool private _isInitialized;
    address public governor; // The current governor, can be updated by DAO.
    uint256 public totalAgents;
    uint256 public totalAgentProposals;
    uint256 public totalInsights;
    uint256 public totalChallenges;
    uint256 public totalGenerativeArtNFTs;
    uint256 public constant QUORUM_DENOMINATOR = 10000; // E.g., 5000 means 50% quorum for 50%.

    uint256 public quorumNumerator; // Example: 5000 for 50%
    uint256 public votingPeriodDays; // Example: 7 days

    // Internal accounting for user balances
    mapping(address => uint256) public userBalances;

    // DAO Voting
    mapping(address => address) public delegates; // Voter => Delegatee
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => bool (tracks effective voter)
    mapping(address => uint256) public votes; // Address => current voting power (simple model: 1 vote per address, or delegated)

    // Structs
    struct Agent {
        uint256 id;
        string name;
        string modelIPFSHash; // Content hash of the AI model's parameters or executable.
        string description;
        address owner;
        address oracle; // Address authorized to submit insights for this agent.
        uint256 requiredStake; // Stake required from agent owner upon registration.
        uint256 createdAt;
        bool isActive; // Can be deprecated by DAO.
        uint256 accumulatedSubscriptionFunds; // Funds accumulated from subscriptions and bounties.
    }

    struct AgentProposal {
        uint256 id;
        address proposer;
        string name;
        string modelIPFSHash;
        string description;
        uint256 requiredStake;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        bool approved;
    }

    struct Insight {
        uint256 id;
        uint256 agentId;
        address oracle;
        bytes32 insightHash; // Hash of the actual insight data (e.g., from IPFS/Arweave).
        string metadataURI; // URI to additional metadata or a small description.
        uint256 submittedAt;
        bool challenged; // True if an active challenge exists.
        bool validatedByStaking; // True if it has received positive validation stakes.
        uint256 totalValidationStake; // Total amount staked in support of this insight.
    }

    struct InsightChallenge {
        uint256 id;
        uint256 insightId;
        address challenger;
        string reasonURI; // URI to explanation of the challenge.
        uint256 stakedAmount;
        uint256 challengeStartBlock;
        uint256 challengeEndBlock; // Time for resolution by governor/DAO.
        bool resolved;
        bool validChallenge; // True if challenge was successful.
    }

    struct Subscription {
        uint256 agentId;
        address subscriber;
        uint256 startTime;
        uint256 endTime;
        uint256 pricePerDay;
        bool active;
    }

    // Reputation Badge (Soulbound-like concept, non-transferable)
    struct ReputationBadge {
        uint256 score;
        string metadataURI; // URI to visual badge or additional info.
        uint256 lastUpdated;
    }

    // Generative AI Art NFT (ERC721-like minimal implementation)
    struct GenerativeArtNFT {
        uint256 tokenId;
        uint256 agentId; // The AI agent that generated this art.
        address owner;
        bytes32 artParametersHash; // Hash of parameters that generate the art (can be updated).
        string metadataURI; // URI pointing to the NFT's metadata, potentially including a viewer.
        uint256 createdAt;
        bool exists; // To check if token ID is valid.
    }

    mapping(uint256 => Agent) public agents;
    mapping(uint256 => AgentProposal) public agentProposals;
    mapping(uint256 => Insight) public insights;
    mapping(uint256 => InsightChallenge) public insightChallenges;
    mapping(uint256 => address) public agentOracles; // agentId => oracleAddress (redundant with agent.oracle but can be useful for quick lookup)
    mapping(uint256 => mapping(address => Subscription)) public agentSubscriptions; // agentId => subscriber => Subscription
    mapping(address => ReputationBadge) public userReputationBadges; // address => ReputationBadge

    // For Generative AI Art NFTs (minimal ERC721)
    mapping(uint256 => GenerativeArtNFT) public generativeArtNFTs;
    mapping(uint256 => address) private _nftOwners; // tokenId => owner (private to enforce consistency with struct)
    mapping(uint256 => string) private _nftTokenURIs; // tokenId => metadata URI (private)

    // Request for custom insights
    struct CustomInsightRequest {
        uint256 id;
        uint256 agentId;
        address requester;
        string requestPromptURI;
        uint256 bounty;
        uint256 requestedAt;
        bool fulfilled;
    }
    uint256 public totalCustomInsightRequests;
    mapping(uint256 => CustomInsightRequest) public customInsightRequests;

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) revert NotGovernor();
        _;
    }

    modifier onlyInitialized() {
        if (!_isInitialized) revert NotInitialized();
        _;
    }

    modifier notInitialized() {
        if (_isInitialized) revert AlreadyInitialized();
        _;
    }

    // --- Constructor ---
    // Note: A proxy pattern would use an initializer function instead of a constructor for upgradeability.
    // For this example, we'll use a constructor for simplicity to set the initial state.
    constructor() {
        // No-op constructor for upgradeability if deployed via proxy.
        // Initialize will be called separately.
    }

    // --- Functions ---

    // I. Core Infrastructure & Governance

    /// @notice Initializes the contract with an initial governor. Callable only once.
    /// @param _initialGovernor The address that will initially control governance functions.
    function initializeContract(address _initialGovernor) external notInitialized {
        governor = _initialGovernor;
        _isInitialized = true;
        // Default governance parameters
        quorumNumerator = 5000; // 50%
        votingPeriodDays = 7; // 7 days
        emit Initialized(_initialGovernor);
    }

    /// @notice Proposes a new AI agent to be governed by the DAO.
    /// @param _agentName The name of the AI agent.
    /// @param _modelIPFSHash A content hash (e.g., IPFS hash) of the AI model's parameters or executable.
    /// @param _description A description of the agent's purpose and capabilities.
    /// @param _requiredStake The amount of tokens (in wei) required to be staked by the agent owner.
    function proposeAgent(
        string memory _agentName,
        string memory _modelIPFSHash,
        string memory _description,
        uint256 _requiredStake
    ) external onlyInitialized {
        totalAgentProposals++;
        uint256 proposalId = totalAgentProposals;
        // Approx. blocks per day = (24*60*60)/12 seconds block time (assuming 12 sec block time)
        uint256 votingPeriodBlocks = votingPeriodDays * 24 * 60 * 60 / 12;

        agentProposals[proposalId] = AgentProposal({
            id: proposalId,
            proposer: msg.sender,
            name: _agentName,
            modelIPFSHash: _modelIPFSHash,
            description: _description,
            requiredStake: _requiredStake,
            votesFor: 0,
            votesAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + votingPeriodBlocks,
            executed: false,
            approved: false
        });
        emit AgentProposed(proposalId, msg.sender, _agentName, _requiredStake);
    }

    /// @notice Casts a vote on an active agent proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against'.
    function voteOnAgentProposal(uint256 _proposalId, bool _support) external onlyInitialized {
        AgentProposal storage proposal = agentProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.number < proposal.startBlock || block.number > proposal.endBlock) revert InvalidVotingPeriod();

        // Simple voting power model: 1 address = 1 vote.
        // For advanced DAO, this would involve token-weighted voting.
        address effectiveVoter = delegates[msg.sender] != address(0) ? delegates[msg.sender] : msg.sender;
        if (hasVoted[_proposalId][effectiveVoter]) revert AlreadyVoted();

        // For simplicity, voting power is 1. In a real DAO, it would query a token balance.
        uint256 voterPower = 1;

        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        hasVoted[_proposalId][effectiveVoter] = true;

        emit VoteCast(_proposalId, effectiveVoter, _support, voterPower);
    }

    /// @notice Executes a passed agent proposal, registering the new agent.
    /// @param _proposalId The ID of the proposal to execute.
    function executeAgentProposal(uint256 _proposalId) external onlyInitialized {
        AgentProposal storage proposal = agentProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.number <= proposal.endBlock) revert ProposalExpiredOrNotReady(); // Ensure voting period is over
        if (proposal.executed) revert ProposalNotApproved(); // Already executed

        // Calculate total votes for quorum
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // In a simple 1-person-1-vote model, total voting power could be the count of unique voters or a fixed supply.
        // For this example, we assume `totalVotes` is sufficient for quorum calculation based on actual participation.
        // A more robust DAO would track total eligible voting power.
        uint256 totalEligibleVotingPower = totalAgents + totalAgentProposals; // Example placeholder for total possible votes
        if (totalEligibleVotingPower == 0) totalEligibleVotingPower = 1; // Prevent division by zero

        uint256 requiredQuorum = (totalEligibleVotingPower * quorumNumerator) / QUORUM_DENOMINATOR;


        // Check for quorum and majority (minimum votes cast AND votesFor > votesAgainst)
        if (totalVotes < requiredQuorum) revert NotEnoughVotes();
        if (proposal.votesFor <= proposal.votesAgainst) revert ProposalNotApproved();

        // Mark proposal as approved and executed
        proposal.approved = true;
        proposal.executed = true;

        totalAgents++;
        uint256 agentId = totalAgents;
        agents[agentId] = Agent({
            id: agentId,
            name: proposal.name,
            modelIPFSHash: proposal.modelIPFSHash,
            description: proposal.description,
            owner: proposal.proposer, // Proposer becomes agent owner
            oracle: address(0), // Oracle needs to be registered separately
            requiredStake: proposal.requiredStake,
            createdAt: block.timestamp,
            isActive: true,
            accumulatedSubscriptionFunds: 0
        });

        emit AgentRegistered(agentId, proposal.name, proposal.proposer);
    }

    /// @notice Updates core DAO governance parameters. Only callable by the current governor.
    /// @param _newQuorumNumerator The new numerator for quorum calculation (e.g., 5000 for 50%).
    /// @param _newVotingPeriodDays The new voting period in days.
    function updateGovernanceParameters(uint256 _newQuorumNumerator, uint256 _newVotingPeriodDays) external onlyGovernor onlyInitialized {
        quorumNumerator = _newQuorumNumerator;
        votingPeriodDays = _newVotingPeriodDays;
        emit GovernanceParametersUpdated(_newQuorumNumerator, _newVotingPeriodDays);
    }

    /// @notice Delegates voting power to another address.
    /// @param _delegate The address to delegate voting power to.
    function delegateVote(address _delegate) external onlyInitialized {
        delegates[msg.sender] = _delegate;
        // Simple increment, in a real DAO this would handle token-weighted voting power
        if (_delegate != address(0)) {
            votes[_delegate]++;
        }
    }

    /// @notice Revokes any active voting delegation.
    function revokeDelegate() external onlyInitialized {
        if (delegates[msg.sender] != address(0)) {
            votes[delegates[msg.sender]]--;
            delegates[msg.sender] = address(0);
        }
    }

    /// @notice Allows the governor to distribute funds from the contract's treasury.
    ///         In a full DAO, this would require a governance proposal and vote.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount of funds (in wei) to distribute.
    function distributeTreasuryFunds(address _recipient, uint256 _amount) external onlyGovernor onlyInitialized {
        if (address(this).balance < _amount) revert InsufficientFunds();
        (bool success, ) = _recipient.call{value: _amount}("");
        if (!success) revert Unauthorized(); // Simpler than custom error, indicates transfer failure
        emit TreasuryDistributed(_recipient, _amount);
    }

    // II. AI Agent Management & Operation

    /// @notice Registers an oracle address for an approved AI agent. Only agent owner can set.
    /// @param _agentId The ID of the agent.
    /// @param _oracleAddress The address of the oracle responsible for this agent.
    function registerAgentOracle(uint256 _agentId, address _oracleAddress) external onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();
        if (agent.owner != msg.sender) revert Unauthorized();
        if (agent.oracle != address(0)) revert OracleAlreadyRegistered();

        agent.oracle = _oracleAddress;
        agentOracles[_agentId] = _oracleAddress; // Redundant map, but could be useful if agent.oracle field is removed.
        emit OracleRegistered(_agentId, _oracleAddress);
    }

    /// @notice An authorized oracle submits an AI's insight to the blockchain.
    /// @param _agentId The ID of the agent.
    /// @param _insightHash A content hash (e.g., IPFS hash) of the actual insight data.
    /// @param _insightMetadataURI URI pointing to metadata or a description of the insight.
    function submitAgentInsight(uint256 _agentId, bytes32 _insightHash, string memory _insightMetadataURI) external onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();
        if (agent.oracle != msg.sender) revert NotAgentOwnerOrOracle(); // Only registered oracle can submit

        totalInsights++;
        uint256 insightId = totalInsights;
        insights[insightId] = Insight({
            id: insightId,
            agentId: _agentId,
            oracle: msg.sender,
            insightHash: _insightHash,
            metadataURI: _insightMetadataURI,
            submittedAt: block.timestamp,
            challenged: false,
            validatedByStaking: false,
            totalValidationStake: 0
        });
        emit InsightSubmitted(insightId, _agentId, _insightHash);
    }

    /// @notice Allows a user to challenge the validity or accuracy of an AI insight.
    /// @param _insightId The ID of the insight to challenge.
    /// @param _reasonURI URI pointing to the detailed reason for the challenge.
    /// @param _stakeAmount Amount of funds (in wei) to stake as part of the challenge.
    function challengeAgentInsight(uint256 _insightId, string memory _reasonURI, uint256 _stakeAmount) external onlyInitialized {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();
        if (insight.challenged) revert Unauthorized(); // Insight already challenged

        if (userBalances[msg.sender] < _stakeAmount) revert InsufficientFunds();
        userBalances[msg.sender] -= _stakeAmount;
        // The staked amount is held by the contract, awaiting resolution.

        totalChallenges++;
        uint256 challengeId = totalChallenges;
        // Approx. blocks per day = (24*60*60)/12 seconds block time (assuming 12 sec block time)
        uint256 resolutionPeriodBlocks = 3 * 24 * 60 * 60 / 12; // 3 days for resolution

        insightChallenges[challengeId] = InsightChallenge({
            id: challengeId,
            insightId: _insightId,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            stakedAmount: _stakeAmount,
            challengeStartBlock: block.number,
            challengeEndBlock: block.number + resolutionPeriodBlocks,
            resolved: false,
            validChallenge: false
        });
        insight.challenged = true;
        emit InsightChallenged(challengeId, _insightId, msg.sender, _stakeAmount);
    }

    /// @notice Governor (or DAO post-transition) resolves an insight challenge.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _validChallenge True if the challenge is deemed valid, false otherwise.
    function resolveInsightChallenge(uint256 _challengeId, bool _validChallenge) external onlyGovernor onlyInitialized {
        InsightChallenge storage challenge = insightChallenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        if (challenge.resolved) revert ChallengeAlreadyResolved();
        if (block.number < challenge.challengeEndBlock) revert ProposalExpiredOrNotReady(); // Wait for resolution period to end

        challenge.resolved = true;
        challenge.validChallenge = _validChallenge;

        Insight storage insight = insights[challenge.insightId];
        Agent storage agent = agents[insight.agentId];

        uint256 rewardAmount = challenge.stakedAmount;

        if (_validChallenge) {
            // Challenger wins: get stake back + small reward (e.g., from treasury or agent's stake)
            userBalances[challenge.challenger] += rewardAmount; // Challenger gets their stake back
            // For simplicity, agent loses a small amount from their accumulated funds.
            if (agent.accumulatedSubscriptionFunds >= rewardAmount / 2) {
                agent.accumulatedSubscriptionFunds -= rewardAmount / 2;
            } else {
                agent.accumulatedSubscriptionFunds = 0;
            }
        } else {
            // Challenger loses: staked amount is lost (e.g., added to treasury or given to agent owner)
            agent.accumulatedSubscriptionFunds += rewardAmount; // Staked amount goes to agent owner
        }

        emit InsightChallengeResolved(_challengeId, challenge.insightId, _validChallenge, rewardAmount);
    }

    /// @notice Initiates the process to mark an existing AI agent as inactive.
    ///         For simplicity, this is `onlyGovernor` for now, but in a full DAO, it would be a proposal.
    /// @param _agentId The ID of the agent to deprecate.
    function deprecateAgent(uint256 _agentId) external onlyGovernor onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();

        agent.isActive = false; // Mark as inactive
        emit AgentDeprecated(_agentId);
    }

    // III. Insight Marketplace & Subscription

    /// @notice Subscribes to an agent's insights for a specified duration.
    /// @param _agentId The ID of the agent to subscribe to.
    /// @param _durationInDays The duration of the subscription in days.
    /// @param _pricePerDay The daily price for the subscription (in wei).
    function subscribeToAgentInsights(uint256 _agentId, uint256 _durationInDays, uint256 _pricePerDay) external onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();
        if (_durationInDays == 0 || _pricePerDay == 0) revert Unauthorized(); // Invalid input

        uint256 totalCost = _pricePerDay * _durationInDays;
        if (userBalances[msg.sender] < totalCost) revert InsufficientFunds();

        userBalances[msg.sender] -= totalCost;
        agent.accumulatedSubscriptionFunds += totalCost;

        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + (_durationInDays * 24 * 60 * 60); // Convert days to seconds

        agentSubscriptions[_agentId][msg.sender] = Subscription({
            agentId: _agentId,
            subscriber: msg.sender,
            startTime: currentTime,
            endTime: endTime,
            pricePerDay: _pricePerDay,
            active: true
        });

        emit SubscriptionCreated(_agentId, msg.sender, _durationInDays, totalCost);
    }

    /// @notice Allows a user to request a custom insight from an AI agent.
    /// @param _agentId The ID of the agent to request from.
    /// @param _requestPromptURI URI pointing to the detailed prompt for the custom insight.
    /// @param _bounty The bounty amount (in wei) offered for this custom insight.
    function requestCustomInsight(uint256 _agentId, string memory _requestPromptURI, uint256 _bounty) external onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();
        if (userBalances[msg.sender] < _bounty) revert InsufficientFunds();

        userBalances[msg.sender] -= _bounty;
        agent.accumulatedSubscriptionFunds += _bounty; // Bounty goes to agent owner initially

        totalCustomInsightRequests++;
        uint256 requestId = totalCustomInsightRequests;
        customInsightRequests[requestId] = CustomInsightRequest({
            id: requestId,
            agentId: _agentId,
            requester: msg.sender,
            requestPromptURI: _requestPromptURI,
            bounty: _bounty,
            requestedAt: block.timestamp,
            fulfilled: false
        });

        emit CustomInsightRequested(_agentId, requestId, msg.sender, _bounty);
    }

    /// @notice Cancels an active subscription to an agent's insights.
    ///         Remaining pro-rata funds are returned to the user.
    /// @param _agentId The ID of the agent for which to cancel the subscription.
    function cancelSubscription(uint256 _agentId) external onlyInitialized {
        Subscription storage sub = agentSubscriptions[_agentId][msg.sender];
        if (!sub.active) revert NoActiveSubscription();
        if (block.timestamp >= sub.endTime) revert NoActiveSubscription(); // Already expired

        sub.active = false;
        uint256 durationInSeconds = sub.endTime - sub.startTime;
        uint256 elapsedSeconds = block.timestamp - sub.startTime;

        if (elapsedSeconds >= durationInSeconds) { // If subscription effectively ended (due to block.timestamp being slightly ahead)
            emit SubscriptionCancelled(_agentId, msg.sender);
            return;
        }

        uint256 totalPaid = (durationInSeconds / (24 * 60 * 60)) * sub.pricePerDay; // Total cost
        uint256 usedAmount = (elapsedSeconds / (24 * 60 * 60)) * sub.pricePerDay; // Cost for used days
        uint256 refundAmount = totalPaid - usedAmount;

        if (refundAmount > 0) {
            userBalances[msg.sender] += refundAmount;
            agents[_agentId].accumulatedSubscriptionFunds -= refundAmount;
        }

        emit SubscriptionCancelled(_agentId, msg.sender);
    }

    /// @notice Allows the owner of an AI agent to claim their accumulated subscription funds.
    /// @param _agentId The ID of the agent whose funds are to be claimed.
    function claimAgentSubscriptionFunds(uint256 _agentId) external onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();
        if (agent.owner != msg.sender) revert Unauthorized();
        if (agent.accumulatedSubscriptionFunds == 0) revert AgentHasNoFundsToClaim();

        uint256 amountToClaim = agent.accumulatedSubscriptionFunds;
        agent.accumulatedSubscriptionFunds = 0; // Reset funds

        (bool success, ) = msg.sender.call{value: amountToClaim}("");
        if (!success) revert Unauthorized(); // Indicate transfer failure

        emit AgentFundsClaimed(_agentId, msg.sender, amountToClaim);
    }

    // IV. Reputation & Dynamic NFTs

    /// @notice Awards or updates a soulbound-like reputation badge to a user. Only governor can call.
    /// @param _recipient The address of the user to award/update the badge.
    /// @param _score The new reputation score.
    /// @param _metadataURI URI pointing to the badge's metadata (e.g., visual representation).
    function awardReputationBadge(address _recipient, uint256 _score, string memory _metadataURI) external onlyGovernor onlyInitialized {
        userReputationBadges[_recipient] = ReputationBadge({
            score: _score,
            metadataURI: _metadataURI,
            lastUpdated: block.timestamp
        });
        emit ReputationBadgeAwarded(_recipient, _score, _metadataURI);
    }

    /// @notice Updates the score and metadata of an existing reputation badge. Only governor can call.
    /// @param _recipient The address whose badge is to be updated.
    /// @param _newScore The updated reputation score.
    /// @param _newMetadataURI The updated URI for the badge's metadata.
    function updateReputationBadge(address _recipient, uint256 _newScore, string memory _newMetadataURI) external onlyGovernor onlyInitialized {
        ReputationBadge storage badge = userReputationBadges[_recipient];
        if (badge.lastUpdated == 0) revert ReputationBadgeNotFound(); // Check if badge exists

        badge.score = _newScore;
        badge.metadataURI = _newMetadataURI;
        badge.lastUpdated = block.timestamp;
        emit ReputationBadgeUpdated(_recipient, _newScore, _newMetadataURI);
    }

    /// @notice Mints a new dynamic ERC721-like NFT representing AI-generated art.
    ///         Only an approved agent's oracle (or agent owner) can trigger this.
    /// @param _agentId The ID of the agent that generated the art.
    /// @param _artParametersHash A hash of the parameters that define the generative art.
    /// @param _artMetadataURI URI pointing to the NFT's metadata (could include a link to a viewer).
    function createGenerativeAIArtNFT(uint256 _agentId, bytes32 _artParametersHash, string memory _artMetadataURI) external onlyInitialized {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0 || !agent.isActive) revert AgentNotFound();
        if (agent.oracle != msg.sender && agent.owner != msg.sender) revert NotAgentOwnerOrOracle(); // Only agent oracle or owner

        totalGenerativeArtNFTs++;
        uint256 tokenId = totalGenerativeArtNFTs;

        generativeArtNFTs[tokenId] = GenerativeArtNFT({
            tokenId: tokenId,
            agentId: _agentId,
            owner: msg.sender, // Minter becomes owner
            artParametersHash: _artParametersHash,
            metadataURI: _artMetadataURI,
            createdAt: block.timestamp,
            exists: true
        });
        _nftOwners[tokenId] = msg.sender;
        _nftTokenURIs[tokenId] = _artMetadataURI; // Initial token URI

        emit GenerativeArtNFTMinted(tokenId, _agentId, msg.sender, _artParametersHash);
    }

    /// @notice Updates the generative parameters of an existing AI Art NFT, making it "evolve".
    ///         Only the NFT owner can update its parameters.
    /// @param _tokenId The ID of the generative art NFT.
    /// @param _newParametersHash The new hash of generative parameters.
    function updateGenerativeAIArtNFTParameters(uint256 _tokenId, bytes32 _newParametersHash) external onlyInitialized {
        GenerativeArtNFT storage nft = generativeArtNFTs[_tokenId];
        if (!nft.exists) revert NFTNotFound();
        if (_nftOwners[_tokenId] != msg.sender) revert NotNFTOwner();

        nft.artParametersHash = _newParametersHash;
        // The metadata URI could also be updated here if the parameter change implies new visual representation.
        // For example: _nftTokenURIs[_tokenId] = "new_uri_based_on_new_parameters";
        emit GenerativeArtNFTParametersUpdated(_tokenId, _newParametersHash);
    }

    /// @notice Allows users to stake funds to positively validate an insight, showing support.
    ///         This could incentivize good AI outputs and honest validation.
    /// @param _insightId The ID of the insight to validate.
    /// @param _amount The amount of funds (in wei) to stake for validation.
    function stakeForInsightValidation(uint256 _insightId, uint256 _amount) external onlyInitialized {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();
        if (userBalances[msg.sender] < _amount) revert InsufficientFunds();
        if (_amount == 0) revert InsufficientFunds();

        userBalances[msg.sender] -= _amount;
        insight.totalValidationStake += _amount;
        insight.validatedByStaking = true; // Mark as having received validation stake

        // Funds are held in the contract. Could be distributed as rewards later,
        // or burned, or used for treasury. For now, they contribute to the insight's "score."

        emit InsightValidationStaked(_insightId, msg.sender, _amount);
    }

    // V. Utility & Read-Only Functions

    /// @notice Allows users to deposit ETH into their internal contract balance.
    function depositFunds() external payable onlyInitialized {
        if (msg.value == 0) revert InsufficientFunds();
        userBalances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows users to withdraw their available internal contract balance.
    /// @param _amount The amount of funds (in wei) to withdraw.
    function withdrawFunds(uint256 _amount) external onlyInitialized {
        if (userBalances[msg.sender] < _amount) revert InsufficientFunds();
        if (_amount == 0) revert NoDepositToWithdraw();

        userBalances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) revert Unauthorized(); // Indicating transfer failure

        emit FundsWithdrawn(msg.sender, _amount);
    }

    /// @notice Returns the details of a specific AI insight.
    /// @param _insightId The ID of the insight.
    /// @return The Insight struct details.
    function getAgentInsight(uint256 _insightId) external view onlyInitialized returns (Insight memory) {
        Insight storage insight = insights[_insightId];
        if (insight.id == 0) revert InsightNotFound();
        return insight;
    }

    /// @notice Returns the details of a specific AI agent.
    /// @param _agentId The ID of the agent.
    /// @return The Agent struct details.
    function getAgentDetails(uint256 _agentId) external view onlyInitialized returns (Agent memory) {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AgentNotFound();
        return agent;
    }

    /// @notice Returns the details of an agent proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The AgentProposal struct details.
    function getAgentProposal(uint256 _proposalId) external view onlyInitialized returns (AgentProposal memory) {
        AgentProposal storage proposal = agentProposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        return proposal;
    }

    /// @notice Returns the details of an insight challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return The InsightChallenge struct details.
    function getInsightChallenge(uint256 _challengeId) external view onlyInitialized returns (InsightChallenge memory) {
        InsightChallenge storage challenge = insightChallenges[_challengeId];
        if (challenge.id == 0) revert ChallengeNotFound();
        return challenge;
    }

    /// @notice Returns the owner of a generative art NFT. (Minimal ERC721)
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function ownerOfGenerativeArtNFT(uint256 _tokenId) external view onlyInitialized returns (address) {
        GenerativeArtNFT storage nft = generativeArtNFTs[_tokenId]; // Ensure it exists via `exists` field
        if (!nft.exists) revert NFTNotFound();
        return _nftOwners[_tokenId];
    }

    /// @notice Returns the token URI of a generative art NFT. (Minimal ERC721)
    /// @param _tokenId The ID of the NFT.
    /// @return The URI string.
    function tokenURIGenerativeArtNFT(uint256 _tokenId) external view onlyInitialized returns (string memory) {
        GenerativeArtNFT storage nft = generativeArtNFTs[_tokenId]; // Ensure it exists via `exists` field
        if (!nft.exists) revert NFTNotFound();
        return _nftTokenURIs[_tokenId]; // Return the stored URI
    }

    /// @notice Returns the total supply of generative art NFTs.
    function totalSupplyGenerativeArtNFTs() external view returns (uint256) {
        return totalGenerativeArtNFTs;
    }
}
```