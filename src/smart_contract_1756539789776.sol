Here's a smart contract written in Solidity, incorporating advanced concepts, creative functions, and trendy ideas like AI agent reputation, dynamic pricing, commit-reveal challenges, and a form of delegated governance. It aims to be distinct from common open-source implementations by custom-fitting its token and core mechanisms.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CognitoNet: Decentralized Insight & AI Agent Network
 * @author Your Name / AI
 * @notice CognitoNet is an innovative smart contract platform designed to foster a decentralized marketplace for AI-generated insights.
 * It introduces a unique reputation system for AI agents, dynamic pricing for their insights, and a novel challenge-based
 * validation mechanism. Governance is enhanced through a delegated reputation voting model.
 *
 * This contract integrates its own utility token (CNET) for fees, rewards, and governance, offering a self-contained ecosystem.
 * Agents register their on-chain identities (NFT-like IDs), submit insights (hashes of off-chain content), and earn CNET
 * based on their reputation and the value of their contributions. Users can subscribe, access insights, and actively participate
 * in validating the network's knowledge base through a commit-reveal challenge system.
 *
 * Disclaimer: While designed to be advanced, this contract is a conceptual demonstration. Real-world applications
 * would require extensive auditing, gas optimization, and robust error handling beyond this scope.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---

// I. Core Infrastructure & CNET Token Management
//    - CNET is an internal utility token used for fees, rewards, and governance within CognitoNet.
//    1.  `constructor()`: Initializes the contract, sets the deployer as owner, and mints an initial supply of CNET.
//    2.  `_mint(address _to, uint256 _amount)`: Internal function to create new CNET tokens for an address. Restricted.
//    3.  `_burn(address _from, uint256 _amount)`: Internal function to destroy CNET tokens from an address. Restricted.
//    4.  `transfer(address _to, uint256 _amount)`: Allows users to transfer their CNET tokens.
//    5.  `balanceOf(address _account)`: Returns the CNET token balance of an address.
//    6.  `getTotalSupply()`: Returns the total circulating supply of CNET tokens.

// II. AI Agent Identity & Profile Management
//    - Agents represent AI models or entities that provide insights. Each agent gets a unique, non-transferable ID.
//    7.  `registerAgent(string calldata _name, bytes32[] calldata _categoryTags)`: Registers a new AI agent, assigning a unique ID.
//    8.  `updateAgentProfile(uint256 _agentId, string calldata _newName, bytes32[] calldata _newCategoryTags)`: Allows agent owner to update profile details.
//    9.  `deactivateAgent(uint256 _agentId)`: Allows agent owner to deactivate their agent, pausing insight submission and reputation updates.
//    10. `getAgentDetails(uint256 _agentId)`: Retrieves comprehensive details about a registered AI agent.
//    11. `getAgentReputation(uint256 _agentId)`: Returns the current reputation score of an agent (tied to its owner's CNET balance).

// III. Insight Submission, Dynamic Pricing & Access
//    - Agents submit hashes of their off-chain insights. Prices are dynamically adjusted.
//    12. `submitInsight(uint256 _agentId, bytes32 _categoryTag, bytes32 _insightHash, uint256 _basePrice)`: Agent submits a new insight hash with a base price.
//    13. `_calculateDynamicPrice(uint256 _agentId, uint256 _basePrice)`: Internal function to calculate an insight's dynamic price based on reputation and demand.
//    14. `getInsightPrice(bytes32 _insightHash)`: Returns the current dynamic price for a specific insight.
//    15. `subscribeToAgent(uint256 _agentId, uint256 _durationInDays)`: Allows users to subscribe for a period to all future insights from an agent.
//    16. `accessInsight(bytes32 _insightHash)`: Allows users to pay to access a specific insight if not subscribed.
//    17. `getLatestInsights(bytes32 _categoryTag, uint256 _limit)`: Fetches a list of the most recent insights for a given category.
//    18. `isSubscribed(address _user, uint256 _agentId)`: Checks if a user has an active subscription to an agent.

// IV. Insight Challenge & Reputation Validation System
//    - Users can challenge insights, with stakes, and the community votes using a commit-reveal scheme.
//    19. `challengeInsight(bytes32 _insightHash, string calldata _reason, uint256 _stake)`: Initiates a challenge against an insight, requiring a CNET stake.
//    20. `commitChallengeVote(uint256 _challengeId, bytes32 _hashedVote)`: Voters commit a hashed version of their vote to prevent front-running.
//    21. `revealChallengeVote(uint256 _challengeId, bool _isAccurate, bytes32 _salt)`: Voters reveal their actual vote and salt after the commit phase.
//    22. `resolveChallenge(uint256 _challengeId)`: Resolves the challenge, adjusts agent reputation, and distributes staked CNET.
//    23. `getChallengeDetails(uint256 _challengeId)`: Retrieves details about a specific challenge.

// V. Decentralized Governance (Reputation-Based & Delegated)
//    - Governance relies on the reputation earned within the network, with options for delegating voting authority.
//    24. `delegateReputation(address _delegatee)`: Allows users to delegate their CNET-based voting authority to another address.
//    25. `revokeDelegation()`: Allows users to revoke their current reputation delegation.
//    26. `submitProposal(string calldata _description, address[] calldata _targets, bytes[] calldata _calldatas)`: Submits a new governance proposal for voting.
//    27. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users (who haven't delegated) to vote on an active proposal.
//    28. `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal.

contract CognitoNet {
    // --- State Variables ---

    // CNET Token Details
    string public constant name = "CognitoNet Token";
    string public constant symbol = "CNET";
    uint8 public constant decimals = 18; // Standard for most ERC-20 tokens
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances; // CNET balances, also serving as reputation

    // Governance
    address public owner; // Contract deployer, initial admin
    uint256 public constant MIN_REPUTATION_FOR_GOVERNANCE = 1000 * (10**uint256(decimals)); // CNET required to propose/vote
    uint256 public constant VOTING_PERIOD = 3 days; // For challenges and proposals
    uint256 public constant REVEAL_PERIOD = 1 days; // For commit-reveal challenges

    // Agent Management
    struct Agent {
        address owner;
        string name;
        // Reputation score is dynamically fetched from _balances[owner]
        bytes32[] categoryTags;
        uint256 lastInsightTimestamp;
        bool isActive;
        uint256 agentId; // Self-referential unique ID
        uint256 totalInsightsSubmitted;
        uint256 totalSubscriptions; // Tracks demand for dynamic pricing
    }
    mapping(uint256 => Agent) public agents;
    uint256 public nextAgentId; // Counter for agent IDs

    // Insight Management
    struct Insight {
        uint256 agentId;
        bytes32 categoryTag;
        bytes32 insightHash; // IPFS hash, Merkle root, or similar link to off-chain data
        uint256 timestamp;
        uint256 basePrice; // CNET tokens
        uint256 challengeCount;
        bool isChallenged;
        bool isValidated; // True if never challenged or successfully defended/voted accurate
    }
    mapping(bytes32 => Insight) public insights;
    mapping(bytes32 => bytes32[]) public insightsByCategory; // Stores insights by category for efficient retrieval

    // Subscription Management
    struct Subscription {
        uint256 endTime;
        uint256 paidAmount; // Total CNET paid for this specific subscription
    }
    mapping(address => mapping(uint256 => Subscription)) public subscriptions; // user => agentId => Subscription

    // Challenge System (Commit-Reveal)
    enum ChallengeStatus {
        PendingCommit, // Challenge initiated, commit phase active
        PendingReveal, // Commit phase over, reveal phase active
        Resolved // Challenge resolved
    }
    struct Challenge {
        bytes32 insightHash;
        address challenger;
        uint256 agentId;
        uint256 stake; // CNET tokens staked by challenger (burned on initiation)
        ChallengeStatus status;
        uint256 commitDeadline;
        uint256 revealDeadline;
        uint256 totalYesVotes; // Votes for "insight is accurate" (against challenge)
        uint256 totalNoVotes; // Votes for "insight is inaccurate" (for challenge)
        mapping(address => bytes32) committedVotes; // voter => keccak256(isAccurate, salt)
        mapping(address => bool) hasRevealedVote; // To prevent double revealing
        bool challengeSuccessful; // True if challenge succeeds (insight is inaccurate)
    }
    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId;

    // Governance System
    struct Proposal {
        string description;
        address proposer;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 yesVotes; // Total CNET voting power in favor
        uint256 noVotes; // Total CNET voting power against
        bool executed;
        bool passed;
        address[] targets; // Addresses to call during execution
        bytes[] calldatas; // Calldata for target calls
        mapping(address => bool) hasVoted; // To prevent double voting by a single address
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // Delegated Voting Authority (Simplified: authority transfer, not power aggregation)
    mapping(address => address) public delegates; // user => delegatee (address to whom user delegates their voting authority)

    // Events
    event CNETTransferred(address indexed from, address indexed to, uint256 amount);
    event CNETMinted(address indexed to, uint256 amount);
    event CNETBurned(address indexed from, uint256 amount);
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name);
    event AgentProfileUpdated(uint256 indexed agentId, string newName, bytes32[] newCategoryTags);
    event AgentDeactivated(uint256 indexed agentId);
    event InsightSubmitted(uint256 indexed agentId, bytes32 indexed insightHash, bytes32 categoryTag, uint256 price);
    event InsightAccessed(address indexed user, bytes32 indexed insightHash, uint256 paidAmount);
    event AgentSubscribed(address indexed user, uint256 indexed agentId, uint256 duration);
    event ChallengeInitiated(uint256 indexed challengeId, bytes32 indexed insightHash, address indexed challenger, uint256 stake);
    event ChallengeVoteCommitted(uint256 indexed challengeId, address indexed voter, bytes32 hashedVote);
    event ChallengeVoteRevealed(uint256 indexed challengeId, address indexed voter, bool isAccurate);
    event ChallengeResolved(uint256 indexed challengeId, bool challengeSuccessful, int256 reputationChange);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event DelegationRevoked(address indexed delegator);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner != address(0), "CognitoNet: Agent does not exist.");
        require(agents[_agentId].owner == msg.sender, "CognitoNet: caller is not agent owner");
        _;
    }

    modifier onlyRegisteredActiveAgent(uint256 _agentId) {
        require(agents[_agentId].owner != address(0), "CognitoNet: Agent does not exist.");
        require(agents[_agentId].isActive, "CognitoNet: Agent is not active.");
        require(agents[_agentId].owner == msg.sender, "CognitoNet: caller is not active registered agent");
        _;
    }

    modifier canVote() {
        require(delegates[msg.sender] == address(0), "CognitoNet: Delegator cannot vote directly.");
        require(_balances[msg.sender] >= MIN_REPUTATION_FOR_GOVERNANCE, "CognitoNet: Insufficient CNET for voting.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _totalSupply = 0; // Will be minted internally
        nextAgentId = 1;
        nextChallengeId = 1;
        nextProposalId = 1;

        // Mint initial supply to the owner to bootstrap the ecosystem.
        // In a real scenario, this might be a DAO treasury or a more complex distribution.
        _mint(msg.sender, 100_000_000 * (10**uint256(decimals))); // 100 Million CNET
    }

    // --- I. Core Infrastructure & CNET Token Management ---

    /**
     * @notice Internal function to mint CNET tokens. Restricted to internal logic.
     * @param _to The address to receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "CNET: mint to the zero address");
        _totalSupply += _amount;
        _balances[_to] += _amount;
        emit CNETMinted(_to, _amount);
    }

    /**
     * @notice Internal function to burn CNET tokens. Restricted to internal logic.
     * @param _from The address from which tokens are burned.
     * @param _amount The amount of tokens to burn.
     */
    function _burn(address _from, uint256 _amount) internal {
        require(_from != address(0), "CNET: burn from the zero address");
        require(_balances[_from] >= _amount, "CNET: burn amount exceeds balance"); // Check for underflow
        _balances[_from] -= _amount;
        _totalSupply -= _amount;
        emit CNETBurned(_from, _amount);
    }

    /**
     * @notice Allows users to transfer CNET tokens.
     * @param _to The recipient address.
     * @param _amount The amount of tokens to transfer.
     * @return A boolean indicating if the transfer was successful.
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0), "CNET: transfer to the zero address");
        require(_balances[msg.sender] >= _amount, "CNET: transfer amount exceeds balance");

        _balances[msg.sender] -= _amount;
        _balances[_to] += _amount;
        emit CNETTransferred(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Returns the CNET token balance of an account.
     * @param _account The address to query the balance of.
     * @return The amount of tokens owned by `_account`.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    /**
     * @notice Returns the total supply of CNET tokens.
     * @return The total number of tokens in existence.
     */
    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // --- II. AI Agent Identity & Profile Management ---

    /**
     * @notice Registers a new AI agent with a unique ID. Each agent is owned by an address.
     * @param _name The desired name for the agent.
     * @param _categoryTags The categories of insights the agent specializes in.
     * @return The unique ID assigned to the registered agent.
     */
    function registerAgent(string calldata _name, bytes32[] calldata _categoryTags) public returns (uint256) {
        uint256 agentId = nextAgentId++;
        agents[agentId] = Agent({
            owner: msg.sender,
            name: _name,
            // reputationScore: fetched dynamically from _balances[msg.sender]
            categoryTags: _categoryTags,
            lastInsightTimestamp: block.timestamp,
            isActive: true,
            agentId: agentId,
            totalInsightsSubmitted: 0,
            totalSubscriptions: 0
        });
        emit AgentRegistered(agentId, msg.sender, _name);
        return agentId;
    }

    /**
     * @notice Allows an agent owner to update their agent's profile details.
     * @param _agentId The ID of the agent to update.
     * @param _newName The new name for the agent.
     * @param _newCategoryTags The new categories for the agent.
     */
    function updateAgentProfile(uint256 _agentId, string calldata _newName, bytes32[] calldata _newCategoryTags)
        public
        onlyAgentOwner(_agentId)
    {
        Agent storage agent = agents[_agentId];
        agent.name = _newName;
        agent.categoryTags = _newCategoryTags;
        emit AgentProfileUpdated(_agentId, _newName, _newCategoryTags);
    }

    /**
     * @notice Allows an agent owner to deactivate their agent.
     *         Deactivated agents cannot submit new insights, and their reputation is frozen.
     * @param _agentId The ID of the agent to deactivate.
     */
    function deactivateAgent(uint256 _agentId) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        require(agent.isActive, "CognitoNet: Agent is already deactivated.");
        agent.isActive = false;
        emit AgentDeactivated(_agentId);
    }

    /**
     * @notice Retrieves the full details of a registered AI agent.
     * @param _agentId The ID of the agent.
     * @return owner The address of the agent's owner.
     * @return name The name of the agent.
     * @return reputationScore The current reputation score of the agent (owner's CNET balance).
     * @return categoryTags The categories the agent specializes in.
     * @return isActive Whether the agent is currently active.
     * @return totalInsightsSubmitted Total number of insights submitted.
     * @return totalSubscriptions Total number of active subscriptions.
     */
    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            address owner,
            string memory name,
            uint256 reputationScore,
            bytes32[] memory categoryTags,
            bool isActive,
            uint256 totalInsightsSubmitted,
            uint256 totalSubscriptions
        )
    {
        Agent storage agent = agents[_agentId];
        require(agent.owner != address(0), "CognitoNet: Agent does not exist.");
        return (
            agent.owner,
            agent.name,
            _balances[agent.owner], // Dynamic reputation score
            agent.categoryTags,
            agent.isActive,
            agent.totalInsightsSubmitted,
            agent.totalSubscriptions
        );
    }

    /**
     * @notice Returns the current reputation score of an agent (tied to its owner's CNET balance).
     * @param _agentId The ID of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(uint256 _agentId) public view returns (uint256) {
        require(agents[_agentId].owner != address(0), "CognitoNet: Agent does not exist.");
        return _balances[agents[_agentId].owner];
    }

    // --- III. Insight Submission, Dynamic Pricing & Access ---

    /**
     * @notice Allows a registered and active agent to submit a new insight hash.
     *         The actual insight data is expected to be stored off-chain (e.g., IPFS).
     * @param _agentId The ID of the submitting agent.
     * @param _categoryTag The category of the insight.
     * @param _insightHash A unique hash linking to the off-chain insight data.
     * @param _basePrice The base price (in CNET) for accessing this insight.
     */
    function submitInsight(uint256 _agentId, bytes32 _categoryTag, bytes32 _insightHash, uint256 _basePrice)
        public
        onlyRegisteredActiveAgent(_agentId)
    {
        require(insights[_insightHash].agentId == 0, "CognitoNet: Insight hash already exists.");
        require(_basePrice > 0, "CognitoNet: Base price must be greater than zero.");

        insights[_insightHash] = Insight({
            agentId: _agentId,
            categoryTag: _categoryTag,
            insightHash: _insightHash,
            timestamp: block.timestamp,
            basePrice: _basePrice,
            challengeCount: 0,
            isChallenged: false,
            isValidated: true // Assumed valid until challenged
        });

        agents[_agentId].lastInsightTimestamp = block.timestamp;
        agents[_agentId].totalInsightsSubmitted++;
        insightsByCategory[_categoryTag].push(_insightHash);

        uint256 dynamicPrice = _calculateDynamicPrice(_agentId, _basePrice);
        emit InsightSubmitted(_agentId, _insightHash, _categoryTag, dynamicPrice);
    }

    /**
     * @notice Internal function to calculate the dynamic price for an insight.
     *         Price increases with reputation and demand, decreases with low reputation/demand, and age.
     * @param _agentId The ID of the agent.
     * @param _basePrice The base price set by the agent.
     * @return The dynamically adjusted price for the insight.
     */
    function _calculateDynamicPrice(uint256 _agentId, uint256 _basePrice) internal view returns (uint256) {
        Agent storage agent = agents[_agentId];
        uint256 agentReputation = _balances[agent.owner];

        if (agentReputation == 0 && agent.totalSubscriptions == 0) {
            return _basePrice; // Return base price if no reputation/demand yet
        }

        // Reputation factor: scales price based on reputation. (1 + reputation / BASE_REP_UNIT)
        // Ensure non-zero reputation for division, using a minimal value
        uint256 reputationFactor = (agentReputation / (10**uint256(decimals)) + 10) / 10; // CNET tokens (base unit, e.g., if 10 CNET = 1x factor)
        if (reputationFactor == 0) reputationFactor = 1; // Minimum 1x

        // Demand factor: scales price based on subscriptions. (1 + totalSubscriptions / BASE_SUB_UNIT)
        uint256 demandFactor = (agent.totalSubscriptions / 10 + 10) / 10; // 10 subscriptions = 1x factor
        if (demandFactor == 0) demandFactor = 1; // Minimum 1x

        // Age factor: price slightly decreases over time. (1 - (age_in_days / MAX_AGE_DAYS_DECAY))
        // For simplicity, not fully implemented for dynamic calculation here; typically applied on retrieval.
        // For dynamic price, a simpler multiplicative factor.
        
        uint256 dynamicPrice = (_basePrice * reputationFactor * demandFactor) / (100); // Scale down by base factor (10*10)

        // Cap dynamic price to avoid extreme values (e.g., 50% to 300% of base price)
        uint256 minPrice = (_basePrice * 50) / 100;
        uint256 maxPrice = (_basePrice * 300) / 100;

        if (dynamicPrice < minPrice) return minPrice;
        if (dynamicPrice > maxPrice) return maxPrice;

        return dynamicPrice;
    }

    /**
     * @notice Returns the current dynamic price for a specific insight.
     * @param _insightHash The hash of the insight.
     * @return The current price in CNET tokens.
     */
    function getInsightPrice(bytes32 _insightHash) public view returns (uint256) {
        Insight storage insight = insights[_insightHash];
        require(insight.agentId != 0, "CognitoNet: Insight not found.");
        return _calculateDynamicPrice(insight.agentId, insight.basePrice);
    }

    /**
     * @notice Allows a user to subscribe to an agent for a specified duration, gaining access to all its insights.
     * @param _agentId The ID of the agent to subscribe to.
     * @param _durationInDays The duration of the subscription in days.
     */
    function subscribeToAgent(uint256 _agentId, uint256 _durationInDays) public {
        Agent storage agent = agents[_agentId];
        require(agent.owner != address(0), "CognitoNet: Agent does not exist.");
        require(agent.isActive, "CognitoNet: Agent is not active.");
        require(_durationInDays > 0 && _durationInDays <= 365, "CognitoNet: Invalid subscription duration (max 365 days).");

        uint256 baseSubscriptionFee = 10 * (10**uint256(decimals)); // Base 10 CNET per 10 days
        uint256 reputationInfluence = _balances[agent.owner] / (1000 * (10**uint256(decimals))); // 0.1% of reputation per day, simplified
        
        uint256 dailyFee = (baseSubscriptionFee + reputationInfluence) / 10; // Fee per day
        uint256 totalSubscriptionFee = dailyFee * _durationInDays;

        require(_balances[msg.sender] >= totalSubscriptionFee, "CNET: Insufficient balance for subscription.");

        // Fee distribution: 70% burned, 30% to agent owner for simplicity
        uint256 agentShare = (totalSubscriptionFee * 30) / 100;
        uint256 burnedAmount = totalSubscriptionFee - agentShare;

        _burn(msg.sender, burnedAmount);
        _mint(agent.owner, agentShare); // Reward agent owner

        Subscription storage currentSub = subscriptions[msg.sender][_agentId];
        uint256 newEndTime = block.timestamp + _durationInDays * 1 days;

        if (currentSub.endTime > block.timestamp) {
            currentSub.endTime = newEndTime > currentSub.endTime ? newEndTime : currentSub.endTime;
            currentSub.paidAmount += totalSubscriptionFee;
        } else {
            currentSub.endTime = newEndTime;
            currentSub.paidAmount = totalSubscriptionFee;
            agent.totalSubscriptions++; // Increment only for newly active subscriptions
        }

        emit AgentSubscribed(msg.sender, _agentId, _durationInDays);
    }

    /**
     * @notice Allows a user to pay to access a specific insight's hash.
     * @param _insightHash The hash of the insight to access.
     */
    function accessInsight(bytes32 _insightHash) public {
        Insight storage insight = insights[_insightHash];
        require(insight.agentId != 0, "CognitoNet: Insight not found.");
        require(!insight.isChallenged || insight.isValidated, "CognitoNet: Insight is currently under challenge or invalidated.");

        // Check if already subscribed to the agent
        if (isSubscribed(msg.sender, insight.agentId)) {
            emit InsightAccessed(msg.sender, _insightHash, 0); // No fee for subscribed users
            return;
        }

        uint256 price = _calculateDynamicPrice(insight.agentId, insight.basePrice);
        require(_balances[msg.sender] >= price, "CNET: Insufficient balance to access insight.");

        // Fee distribution: 70% burned, 30% to agent owner
        uint256 agentShare = (price * 30) / 100;
        uint256 burnedAmount = price - agentShare;

        _burn(msg.sender, burnedAmount); // Burn the CNET for access
        _mint(agents[insight.agentId].owner, agentShare); // Reward agent owner

        emit InsightAccessed(msg.sender, _insightHash, price);
    }

    /**
     * @notice Retrieves a list of the most recent insights for a given category.
     * @param _categoryTag The category to query.
     * @param _limit The maximum number of insights to return.
     * @return An array of insight hashes.
     */
    function getLatestInsights(bytes32 _categoryTag, uint256 _limit) public view returns (bytes32[] memory) {
        bytes32[] storage categoryInsights = insightsByCategory[_categoryTag];
        uint256 total = categoryInsights.length;
        if (total == 0) {
            return new bytes32[](0);
        }

        uint256 numToReturn = total < _limit ? total : _limit;
        bytes32[] memory result = new bytes32[](numToReturn);

        for (uint256 i = 0; i < numToReturn; i++) {
            result[i] = categoryInsights[total - 1 - i]; // Most recent first
        }
        return result;
    }

    /**
     * @notice Checks if a user has an active subscription to a specific agent.
     * @param _user The address of the user.
     * @param _agentId The ID of the agent.
     * @return True if the user is actively subscribed, false otherwise.
     */
    function isSubscribed(address _user, uint256 _agentId) public view returns (bool) {
        return subscriptions[_user][_agentId].endTime > block.timestamp;
    }

    // --- IV. Insight Challenge & Reputation Validation System ---

    /**
     * @notice Allows a user to challenge the accuracy or quality of an insight.
     *         Requires a CNET stake, which is at risk.
     * @param _insightHash The hash of the insight being challenged.
     * @param _reason A string describing the reason for the challenge. (Off-chain or event for context)
     * @param _stake The amount of CNET to stake for the challenge.
     * @return The ID of the initiated challenge.
     */
    function challengeInsight(bytes32 _insightHash, string calldata _reason, uint256 _stake) public returns (uint256) {
        Insight storage insight = insights[_insightHash];
        require(insight.agentId != 0, "CognitoNet: Insight not found.");
        require(insight.agentId != 0, "CognitoNet: Cannot challenge non-existent agent's insight."); // Should be covered by agentId != 0
        require(insight.timestamp + 7 days > block.timestamp, "CognitoNet: Insight is too old to challenge (max 7 days).");
        require(!insight.isChallenged, "CognitoNet: Insight is already under challenge."); // Only one challenge at a time
        require(_balances[msg.sender] >= _stake, "CNET: Insufficient balance for challenge stake.");
        require(_stake > 0, "CognitoNet: Challenge stake must be greater than zero.");
        
        insight.challengeCount++;
        insight.isChallenged = true;
        insight.isValidated = false; // Invalidated until resolved

        _burn(msg.sender, _stake); // Burn the stake from the challenger's balance

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            insightHash: _insightHash,
            challenger: msg.sender,
            agentId: insight.agentId,
            stake: _stake,
            status: ChallengeStatus.PendingCommit,
            commitDeadline: block.timestamp + VOTING_PERIOD,
            revealDeadline: 0, // Set after commit phase ends
            totalYesVotes: 0,
            totalNoVotes: 0,
            challengeSuccessful: false,
            hasRevealedVote: new mapping(address => bool) // Initialize empty mapping
        });

        emit ChallengeInitiated(challengeId, _insightHash, msg.sender, _stake);
        return challengeId;
    }

    /**
     * @notice Voters commit a hashed version of their vote (`_isAccurate`, `_salt`).
     *         Prevents front-running and vote manipulation in the reveal phase.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _hashedVote The keccak256 hash of (isAccurate, salt).
     */
    function commitChallengeVote(uint256 _challengeId, bytes32 _hashedVote) public canVote {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightHash != bytes32(0), "CognitoNet: Challenge not found.");
        require(challenge.status == ChallengeStatus.PendingCommit, "CognitoNet: Challenge not in commit phase.");
        require(block.timestamp <= challenge.commitDeadline, "CognitoNet: Commit phase has ended.");
        require(challenge.committedVotes[msg.sender] == bytes32(0), "CognitoNet: Already committed a vote.");

        challenge.committedVotes[msg.sender] = _hashedVote;
        emit ChallengeVoteCommitted(_challengeId, msg.sender, _hashedVote);
    }

    /**
     * @notice Voters reveal their actual vote and the salt used in the commit phase.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _isAccurate True if the insight is considered accurate, false otherwise.
     * @param _salt The salt used during the commit phase.
     */
    function revealChallengeVote(uint256 _challengeId, bool _isAccurate, bytes32 _salt) public canVote {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightHash != bytes32(0), "CognitoNet: Challenge not found.");
        require(challenge.status == ChallengeStatus.PendingCommit || challenge.status == ChallengeStatus.PendingReveal, "CognitoNet: Challenge not in reveal phase.");
        require(block.timestamp > challenge.commitDeadline, "CognitoNet: Reveal phase has not started yet.");
        
        // If commit phase just ended, transition status and set reveal deadline
        if (challenge.status == ChallengeStatus.PendingCommit) {
            challenge.status = ChallengeStatus.PendingReveal;
            challenge.revealDeadline = challenge.commitDeadline + REVEAL_PERIOD;
        }

        require(block.timestamp <= challenge.revealDeadline, "CognitoNet: Reveal phase has ended.");
        require(challenge.committedVotes[msg.sender] != bytes32(0), "CognitoNet: No committed vote found for this address.");
        require(challenge.hasRevealedVote[msg.sender] == false, "CognitoNet: Already revealed vote for this challenge.");

        bytes32 expectedHash = keccak256(abi.encodePacked(_isAccurate, _salt));
        require(challenge.committedVotes[msg.sender] == expectedHash, "CognitoNet: Invalid vote reveal (hash mismatch).");

        uint256 voterPower = _balances[msg.sender]; // Direct CNET balance for voting power

        if (_isAccurate) {
            challenge.totalYesVotes += voterPower;
        } else {
            challenge.totalNoVotes += voterPower;
        }
        challenge.hasRevealedVote[msg.sender] = true;
        challenge.committedVotes[msg.sender] = bytes32(1); // Mark as revealed (any non-zero value indicates revealed)

        emit ChallengeVoteRevealed(_challengeId, msg.sender, _isAccurate);
    }

    /**
     * @notice Resolves a challenge after the reveal period, adjusting agent reputation and stakes.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) public {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightHash != bytes32(0), "CognitoNet: Challenge not found.");
        require(challenge.status == ChallengeStatus.PendingReveal || challenge.status == ChallengeStatus.PendingCommit, "CognitoNet: Challenge already resolved or in invalid state.");
        require(block.timestamp > challenge.revealDeadline, "CognitoNet: Reveal period not over."); // Ensure reveal period is over
        
        challenge.status = ChallengeStatus.Resolved;
        Insight storage insight = insights[challenge.insightHash];
        Agent storage agent = agents[challenge.agentId];

        int256 reputationChange = 0; // Can be positive or negative CNET for agent owner

        if (challenge.totalNoVotes > challenge.totalYesVotes) {
            // Challenge successful: Insight is deemed inaccurate
            challenge.challengeSuccessful = true;
            insight.isValidated = false; // Mark insight as invalid
            insight.isChallenged = false; // Reset challenge status
            
            // Agent owner loses reputation (burned CNET)
            reputationChange = - (challenge.stake); // Agent loses equivalent to challenger's stake

            // Challenger gets back stake + bonus (minted CNET)
            _mint(challenge.challenger, challenge.stake + (challenge.stake / 2)); // 50% bonus for successful challenge (example)
        } else {
            // Challenge unsuccessful: Insight is deemed accurate or no clear majority
            challenge.challengeSuccessful = false;
            insight.isValidated = true; // Insight remains or becomes valid
            insight.isChallenged = false; // Reset challenge status

            // Agent owner gains reputation (minted CNET)
            reputationChange = challenge.stake; // Agent gains reputation equal to challenger's stake
            // Challenger's initial stake (burned in challengeInsight) is lost.
        }
        
        // Apply reputation change to agent owner's CNET balance
        if (reputationChange > 0) {
             _mint(agent.owner, uint256(reputationChange));
        } else if (reputationChange < 0) {
            uint256 burnAmount = uint256(reputationChange * -1);
            if (_balances[agent.owner] < burnAmount) {
                _burn(agent.owner, _balances[agent.owner]); // Burn all available if not enough
            } else {
                _burn(agent.owner, burnAmount);
            }
        }
        // agent.reputationScore is now implicitly updated through _balances[agent.owner]

        emit ChallengeResolved(_challengeId, challenge.challengeSuccessful, reputationChange);
    }

    /**
     * @notice Retrieves the details of a specific insight challenge.
     * @param _challengeId The ID of the challenge.
     * @return insightHash The hash of the challenged insight.
     * @return challenger The address of the user who initiated the challenge.
     * @return agentId The ID of the agent whose insight was challenged.
     * @return stake The CNET stake involved in the challenge.
     * @return status The current status of the challenge.
     * @return commitDeadline The deadline for committing votes.
     * @return revealDeadline The deadline for revealing votes.
     * @return totalYesVotes Total voting power for "accurate".
     * @return totalNoVotes Total voting power for "inaccurate".
     * @return challengeSuccessful Final outcome (only valid after resolution).
     */
    function getChallengeDetails(uint256 _challengeId)
        public
        view
        returns (
            bytes32 insightHash,
            address challenger,
            uint256 agentId,
            uint256 stake,
            ChallengeStatus status,
            uint256 commitDeadline,
            uint256 revealDeadline,
            uint256 totalYesVotes,
            uint256 totalNoVotes,
            bool challengeSuccessful
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.insightHash != bytes32(0), "CognitoNet: Challenge not found.");
        return (
            challenge.insightHash,
            challenge.challenger,
            challenge.agentId,
            challenge.stake,
            challenge.status,
            challenge.commitDeadline,
            challenge.revealDeadline,
            challenge.totalYesVotes,
            challenge.totalNoVotes,
            challenge.challengeSuccessful
        );
    }

    // --- V. Decentralized Governance (Reputation-Based & Delegated) ---

    /**
     * @notice Allows a user to delegate their voting authority to another address.
     *         The delegator will no longer be able to vote directly, and their vote weight
     *         is effectively transferred to the delegatee (who must then explicitly vote).
     *         Note: This is an "authority delegation" model for simplicity, where the delegatee
     *         votes using their own power, but the delegator foregoes their vote. A more complex
     *         "liquid delegated power" model (like Compound's) would aggregate CNET balances,
     *         which is gas-intensive without specific ERC-20 extensions.
     * @param _delegatee The address to delegate voting authority to.
     */
    function delegateReputation(address _delegatee) public {
        require(_delegatee != address(0), "CognitoNet: Delegatee cannot be the zero address.");
        require(_delegatee != msg.sender, "CognitoNet: Cannot delegate to self.");
        
        delegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Allows a user to revoke their current voting delegation.
     *         The user will regain their direct voting authority.
     */
    function revokeDelegation() public {
        require(delegates[msg.sender] != address(0), "CognitoNet: No active delegation to revoke.");
        
        delegates[msg.sender] = address(0);
        emit DelegationRevoked(msg.sender);
    }

    /**
     * @notice Submits a new governance proposal.
     * @param _description A description of the proposal.
     * @param _targets An array of target addresses for the proposal's execution.
     * @param _calldatas An array of calldatas for the target addresses.
     *                  Must match the length of _targets.
     * @return The ID of the created proposal.
     */
    function submitProposal(string calldata _description, address[] calldata _targets, bytes[] calldata _calldatas)
        public
        canVote
        returns (uint256)
    {
        require(_targets.length == _calldatas.length, "CognitoNet: Target and calldata length mismatch.");
        require(bytes(_description).length > 0, "CognitoNet: Proposal description cannot be empty.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            description: _description,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false,
            targets: _targets,
            calldatas: _calldatas,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @notice Casts a vote on an active governance proposal.
     *         Only users who have not delegated their authority can vote directly.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public canVote {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitoNet: Proposal not found.");
        require(block.timestamp <= proposal.votingDeadline, "CognitoNet: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "CognitoNet: Already voted on this proposal.");
        
        uint256 voterPower = _balances[msg.sender]; // Direct CNET balance as voting power

        if (_support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @notice Executes a successfully passed governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitoNet: Proposal not found.");
        require(block.timestamp > proposal.votingDeadline, "CognitoNet: Voting period not over.");
        require(!proposal.executed, "CognitoNet: Proposal already executed.");

        // Simple majority vote: yes > no and minimum quorum (e.g., total votes >= 10x MIN_REPUTATION)
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        proposal.passed = (proposal.yesVotes > proposal.noVotes) && (totalVotes >= MIN_REPUTATION_FOR_GOVERNANCE * 10); 

        require(proposal.passed, "CognitoNet: Proposal did not pass or quorum not met.");

        proposal.executed = true;

        for (uint252 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call(proposal.calldatas[i]);
            require(success, "CognitoNet: Proposal execution failed for one or more targets.");
        }

        emit ProposalExecuted(_proposalId);
    }
}
```