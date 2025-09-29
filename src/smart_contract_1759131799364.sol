This smart contract, `CognitoNet`, presents a decentralized intent fulfillment network. Users post "Intents" (requests) with bounties, which are then claimed and fulfilled by "Agents." These Agents are unique NFTs with dynamic "Skill" and "Reputation" attributes that evolve based on their performance. The network introduces "Cognitive Resources" (CR), an internal fungible token that agents use to operate and earn as rewards, reflecting their processing capacity and attention within the system.

**Outline: CognitoNet - Decentralized Intent Fulfillment Network**

1.  **Introduction:**
    CognitoNet is a novel decentralized platform enabling users to post "Intents" (requests for services, computations, or outcomes) which are then fulfilled by a network of "Agents." These Agents are represented as unique Non-Fungible Tokens (NFTs) with dynamic "Skill" and "Reputation" attributes. The system facilitates a peer-to-peer ecosystem for task delegation and autonomous agent coordination, powered by an internal "Cognitive Resources" (CR) token.

2.  **Core Components:**
    *   **Intents:** Structured requests from users, including a bounty (paid in a specified ERC20 token).
    *   **Agents (NFTs):** Unique digital entities with evolving skills and reputation, responsible for fulfilling intents. They must be "staked" to participate.
    *   **Cognitive Resources (CR):** An internal fungible token representing an agent's processing capacity or attention. Agents consume CR to claim intents and earn CR upon successful fulfillment.
    *   **Reputation:** A dynamically adjusted score for agents, influencing their eligibility and rewards.
    *   **Skills:** Specific categories of expertise for agents, with adjustable weights that impact reputation.
    *   **Dispute Resolution:** A mechanism for resolving disagreements between intent issuers and agents regarding fulfillment.

3.  **Key Flows:**
    *   **Intent Lifecycle:** Post Intent -> Agent Claims -> Agent Submits Proof -> Issuer Verifies/Disputes -> Rewards/Dispute Resolution.
    *   **Agent Lifecycle:** Mint Agent -> Stake Agent -> Claim/Fulfill Intents -> Earn/Spend CR -> Evolve Skills/Reputation.
    *   **Dispute Resolution:** Initiated by the agent if their fulfillment is rejected, resolved by an authorized entity (e.g., contract owner, or a future DAO).

4.  **Advanced Concepts Highlighted:**
    *   **Intent-Based Architecture:** Users declare goals, not explicit function calls, allowing agents flexibility in fulfillment.
    *   **Dynamic NFT Attributes:** Agent NFTs possess evolving `skill` and `reputation` values stored on-chain, making them "living" assets.
    *   **Resource-Awareness:** `Cognitive Resources (CR)` token for agent operational costs (claiming intents) and incentivization (successful fulfillment).
    *   **Modular Intent Definition:** `Intent Templates` allow for standardized and extensible intent types, enabling diverse tasks.
    *   **Verifiable Fulfillment Hooks:** Placeholder for future integration with ZK-proofs or advanced off-chain verification mechanisms.
    *   **Decentralized Coordination (Foundation):** Laying groundwork for autonomous agent interaction and a decentralized workforce.

**Function Summary:**

**Agent Lifecycle & Management (6 functions):**
1.  `mintAgentNFT(string memory _name, string memory _uri)`: Mints a new unique AI agent NFT with initial attributes (name, metadata URI, base reputation, and initial CR tokens).
2.  `stakeAgent(uint256 _agentId)`: Stakes an Agent NFT, making it eligible to claim intents. Requires a CR token stake/fee from the owner.
3.  `unstakeAgent(uint256 _agentId)`: Unstakes an Agent NFT, removing it from active service and returning the CR stake.
4.  `updateAgentProfile(uint256 _agentId, string memory _newUri)`: Allows an agent owner to update their agent's metadata URI.
5.  `getAgentDetails(uint256 _agentId)`: Retrieves comprehensive information about a specific agent, including its skills and reputation.
6.  `transferAgentNFT(address _from, address _to, uint256 _agentId)`: Standard ERC721 function to transfer ownership of an Agent NFT, including approval checks.

**Intent Lifecycle & Fulfillment (8 functions):**
7.  `postIntent(uint256 _templateId, string memory _descriptionURI, uint256 _bountyAmount, address _bountyTokenAddress)`: Publishes a new intent, specifying its template, detailed description URI, bounty amount, and the ERC20 token for the bounty.
8.  `cancelIntent(uint256 _intentId)`: Allows the intent issuer to cancel an unfulfilled intent and reclaim the locked bounty.
9.  `claimIntent(uint256 _intentId, uint256 _agentId)`: An agent (owned by `msg.sender`) attempts to claim an available intent. Requires the agent to be staked and sufficient CR tokens.
10. `submitFulfillmentProof(uint256 _intentId, string memory _proofURI)`: The claiming agent submits a URI pointing to the proof of their intent fulfillment.
11. `verifyIntentFulfillment(uint256 _intentId, bool _success)`: Intent issuer reviews the submitted proof and confirms (`_success = true`) or rejects (`_success = false`) fulfillment. Triggers reward distribution or a potential dispute.
12. `initiateDispute(uint256 _intentId, string memory _reasonURI)`: Allows an agent to initiate a dispute if their fulfillment was rejected unfairly by the issuer.
13. `fundIntent(uint256 _intentId, uint256 _amount)`: Allows the intent issuer to add more bounty to an existing, open or claimed intent.
14. `getIntentDetails(uint256 _intentId)`: Retrieves all details associated with a specific intent.

**System & Configuration (6 functions):**
15. `addIntentTemplate(string memory _templateURI)`: Owner function to register a new structured intent template URI (e.g., a JSON schema on IPFS for intent parameters).
16. `addSkillCategory(string memory _name, string memory _description)`: Owner function to define a new skill category that agents can possess.
17. `adjustSkillWeights(uint256 _skillCategoryId, uint256 _newWeight)`: Owner function to modify the importance (weight) of a skill category in reputation calculations.
18. `resolveDispute(uint256 _intentId, bool _agentWins)`: Owner/Judge function to definitively resolve a dispute, determining if the agent or issuer is correct and applying respective rewards/penalties.
19. `withdrawPlatformFeesSpecificToken(address _bountyTokenAddress, address _to, uint256 _amount)`: Owner function to withdraw accumulated platform fees for a specific bounty token to a designated address.
20. `getAvailableIntents()`: Returns an array of intent IDs that are currently open and available for claiming by agents.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using for uint handling, though 0.8+ has overflow checks

// Dummy ERC20 for demonstration purposes, to be deployed separately and its address passed.
// In a real scenario, you'd deploy this Mock ERC20 or use an existing one.
contract ERC20Mock {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        _balances[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount); // Reduce allowance
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


contract CognitoNet is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly using SafeMath, though 0.8+ handles overflow/underflow by default

    // --- Events ---
    event AgentMinted(uint256 indexed agentId, address indexed owner, string name, string uri);
    event AgentStaked(uint256 indexed agentId);
    event AgentUnstaked(uint256 indexed agentId);
    event AgentProfileUpdated(uint256 indexed agentId, string newUri);
    event IntentPosted(uint256 indexed intentId, address indexed issuer, uint256 templateId, uint256 bountyAmount, address bountyTokenAddress);
    event IntentCancelled(uint256 indexed intentId);
    event IntentClaimed(uint256 indexed intentId, uint256 indexed agentId);
    event FulfillmentProofSubmitted(uint256 indexed intentId, uint256 indexed agentId, string proofURI);
    event IntentVerified(uint256 indexed intentId, uint256 indexed agentId, bool success);
    event DisputeInitiated(uint256 indexed intentId, uint256 indexed agentId, string reasonURI);
    event DisputeResolved(uint256 indexed intentId, bool agentWins);
    event IntentFunded(uint256 indexed intentId, uint256 addedAmount);
    event IntentTemplateAdded(uint256 indexed templateId, string templateURI);
    event SkillCategoryAdded(uint256 indexed skillId, string name);
    event SkillWeightAdjusted(uint256 indexed skillId, uint256 newWeight);
    event PlatformFeesWithdrawn(address indexed recipient, address indexed tokenAddress, uint256 amount);
    event CognitiveResourcesTransferred(address indexed from, address indexed to, uint256 amount);
    event CognitiveResourcesMinted(address indexed to, uint256 amount);
    event CognitiveResourcesBurned(address indexed from, uint256 amount);


    // --- Constants ---
    uint256 public constant INITIAL_AGENT_REPUTATION = 100;
    uint256 public constant AGENT_CR_STAKE_AMOUNT = 100 ether; // Example CR tokens consumed to stake an agent
    uint256 public constant CR_CLAIM_FEE = 10 ether; // CR tokens consumed to claim an intent
    uint256 public constant CR_FULFILLMENT_REWARD = 50 ether; // CR tokens earned on successful fulfillment
    uint256 public platformFeeRate = 50; // 50 = 5% (50/1000 basis points)
    uint256 public constant BASIS_POINTS_DENOMINATOR = 1000;

    // --- Data Structures ---

    enum IntentStatus { Open, Claimed, Fulfilled, Verified, Rejected, Disputed, Cancelled }

    struct Intent {
        uint256 id;
        address issuer;
        uint256 templateId;
        string descriptionURI; // URI to IPFS or other storage for detailed intent description
        uint256 bountyAmount;
        address bountyTokenAddress;
        uint256 claimedByAgentId; // 0 if not claimed
        string fulfillmentProofURI;
        IntentStatus status;
        uint256 postedTimestamp;
        uint256 resolutionTimestamp;
        bool hasDispute;
        string disputeReasonURI;
    }

    struct Agent {
        uint256 id;
        address owner;
        string name;
        string uri; // URI to IPFS for agent's detailed profile/metadata
        mapping(uint256 => uint256) skills; // skillCategoryId => score (e.g., 0-100)
        uint256 reputation;
        bool isStaked;
        uint256 lastActivityTimestamp;
    }

    struct SkillCategory {
        string name;
        string description;
        uint256 weight; // Importance in reputation calculation (e.g., 1 to 10)
    }

    struct IntentTemplate {
        string templateURI; // URI to IPFS for structured intent schema
    }

    // --- State Variables ---

    Counters.Counter private _intentIdCounter;
    Counters.Counter private _agentIdCounter;
    Counters.Counter private _skillIdCounter;
    Counters.Counter private _templateIdCounter;

    mapping(uint256 => Intent) public intents;
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => SkillCategory) public skillCategories;
    mapping(uint256 => IntentTemplate) public intentTemplates;

    // Agent NFT (minimal ERC721 implementation within this contract)
    mapping(uint256 => address) private _agentOwners; // AgentId -> Owner Address
    mapping(address => uint256) private _agentBalances; // Owner Address -> Number of agents
    mapping(uint256 => address) private _agentApprovals; // AgentId -> Approved Address
    mapping(address => mapping(address => bool)) private _agentOperatorApprovals; // Owner -> Operator -> Approved

    // Cognitive Resources (CR) Token (minimal ERC20 implementation within this contract)
    string public constant cr_name = "Cognitive Resources";
    string public constant cr_symbol = "CR";
    uint8 public constant cr_decimals = 18;
    mapping(address => uint256) private _crBalances;
    mapping(address => mapping(address => uint256)) private _crAllowances;

    // Accumulated platform fees by bounty token address
    mapping(address => uint256) public platformFees;

    constructor() Ownable(msg.sender) {}

    // --- Internal/Minimal ERC721 Implementations for Agents ---

    // Modifier to check if caller is owner, approved, or approved for all
    modifier _isApprovedOrOwner(address spender, uint256 agentId) {
        require(_agentOwners[agentId] != address(0), "ERC721: query for non-existent token");
        require(
            _agentOwners[agentId] == spender ||
            _agentApprovals[agentId] == spender ||
            _agentOperatorApprovals[_agentOwners[agentId]][spender],
            "ERC721: caller is not token owner nor approved"
        );
        _;
    }

    function _transferAgent(address from, address to, uint256 agentId) internal {
        require(_agentOwners[agentId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approveAgent(address(0), agentId); // Clear approval for the transferred token

        _agentBalances[from] = _agentBalances[from].sub(1, "ERC721: transfer of non-existent token");
        _agentBalances[to] = _agentBalances[to].add(1);
        _agentOwners[agentId] = to;

        // Update the agent struct owner
        agents[agentId].owner = to;
    }

    function _approveAgent(address to, uint256 agentId) internal {
        _agentApprovals[agentId] = to;
        // In a full ERC721, this would emit an Approval event.
    }

    // --- Public/External ERC721-like Functions for Agents ---
    // These functions provide minimal ERC721 interface for agent NFTs.

    function ownerOf(uint256 agentId) public view returns (address) {
        require(_agentOwners[agentId] != address(0), "ERC721: owner query for non-existent token");
        return _agentOwners[agentId];
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _agentBalances[owner];
    }

    function getApproved(uint256 agentId) public view returns (address) {
        require(_agentOwners[agentId] != address(0), "ERC721: approved query for non-existent token");
        return _agentApprovals[agentId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _agentOperatorApprovals[owner][operator];
    }

    function approve(address to, uint256 agentId) public {
        address owner_ = ownerOf(agentId);
        require(to != owner_, "ERC721: approval to current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approveAgent(to, agentId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _agentOperatorApprovals[msg.sender][operator] = approved;
        // In a full ERC721, this would emit an ApprovalForAll event.
    }

    // --- Internal/Minimal ERC20 Implementations for Cognitive Resources (CR) ---
    function _mintCR(address account, uint256 amount) internal {
        require(account != address(0), "CR: mint to the zero address");
        _crBalances[account] = _crBalances[account].add(amount);
        emit CognitiveResourcesMinted(account, amount);
        emit CognitiveResourcesTransferred(address(0), account, amount);
    }

    function _burnCR(address account, uint256 amount) internal {
        require(account != address(0), "CR: burn from the zero address");
        _crBalances[account] = _crBalances[account].sub(amount, "CR: burn amount exceeds balance");
        emit CognitiveResourcesBurned(account, amount);
        emit CognitiveResourcesTransferred(account, address(0), amount);
    }

    function _transferCR(address from, address to, uint256 amount) internal {
        require(from != address(0), "CR: transfer from the zero address");
        require(to != address(0), "CR: transfer to the zero address");
        _crBalances[from] = _crBalances[from].sub(amount, "CR: transfer amount exceeds balance");
        _crBalances[to] = _crBalances[to].add(amount);
        emit CognitiveResourcesTransferred(from, to, amount);
    }

    function _approveCR(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "CR: approve from the zero address");
        require(spender != address(0), "CR: approve to the zero address");
        _crAllowances[owner][spender] = amount;
        // In a full ERC20, this would emit an Approval event.
    }

    // --- Public/External ERC20-like Functions for Cognitive Resources (CR) ---
    function balanceOfCR(address account) public view returns (uint256) {
        return _crBalances[account];
    }

    function transferCRTokens(address to, uint256 amount) public returns (bool) {
        _transferCR(msg.sender, to, amount);
        return true;
    }

    function allowanceCR(address owner, address spender) public view returns (uint256) {
        return _crAllowances[owner][spender];
    }

    function approveCR(address spender, uint256 amount) public returns (bool) {
        _approveCR(msg.sender, spender, amount);
        return true;
    }

    function transferFromCR(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _crAllowances[from][msg.sender];
        require(currentAllowance >= amount, "CR: transfer amount exceeds allowance");
        _transferCR(from, to, amount);
        _approveCR(from, msg.sender, currentAllowance - amount);
        return true;
    }


    // --- Agent Lifecycle & Management (6 functions) ---

    /**
     * @notice Mints a new unique AI agent NFT.
     * @param _name The name of the agent.
     * @param _uri A URI pointing to the agent's detailed metadata (e.g., IPFS).
     * @return The ID of the newly minted agent.
     */
    function mintAgentNFT(string memory _name, string memory _uri) public returns (uint256) {
        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        Agent storage newAgent = agents[newAgentId];
        newAgent.id = newAgentId;
        newAgent.owner = msg.sender;
        newAgent.name = _name;
        newAgent.uri = _uri;
        newAgent.reputation = INITIAL_AGENT_REPUTATION;
        newAgent.isStaked = false;
        newAgent.lastActivityTimestamp = block.timestamp;

        _agentOwners[newAgentId] = msg.sender;
        _agentBalances[msg.sender] = _agentBalances[msg.sender].add(1);

        // Agents receive initial CR tokens upon minting to enable staking/claiming
        _mintCR(msg.sender, AGENT_CR_STAKE_AMOUNT.add(CR_CLAIM_FEE * 5)); // Initial CR tokens

        emit AgentMinted(newAgentId, msg.sender, _name, _uri);
        return newAgentId;
    }

    /**
     * @notice Stakes an Agent NFT, making it eligible to claim intents. Requires initial CR balance.
     * @param _agentId The ID of the agent to stake.
     */
    function stakeAgent(uint256 _agentId) public {
        require(agents[_agentId].id != 0, "Agent: Agent does not exist");
        require(agents[_agentId].owner == msg.sender, "Agent: Not agent owner");
        require(!agents[_agentId].isStaked, "Agent: Agent is already staked");
        require(balanceOfCR(msg.sender) >= AGENT_CR_STAKE_AMOUNT, "Agent: Insufficient CR balance to stake");

        _burnCR(msg.sender, AGENT_CR_STAKE_AMOUNT);

        agents[_agentId].isStaked = true;
        agents[_agentId].lastActivityTimestamp = block.timestamp;
        emit AgentStaked(_agentId);
    }

    /**
     * @notice Unstakes an Agent NFT, removing it from active service.
     * @param _agentId The ID of the agent to unstake.
     */
    function unstakeAgent(uint256 _agentId) public {
        require(agents[_agentId].id != 0, "Agent: Agent does not exist");
        require(agents[_agentId].owner == msg.sender, "Agent: Not agent owner");
        require(agents[_agentId].isStaked, "Agent: Agent is not staked");

        // Return CR stake
        _mintCR(msg.sender, AGENT_CR_STAKE_AMOUNT);

        agents[_agentId].isStaked = false;
        agents[_agentId].lastActivityTimestamp = block.timestamp;
        emit AgentUnstaked(_agentId);
    }

    /**
     * @notice Allows an agent owner to update their agent's metadata URI.
     * @param _agentId The ID of the agent to update.
     * @param _newUri The new URI for the agent's detailed metadata.
     */
    function updateAgentProfile(uint256 _agentId, string memory _newUri) public {
        require(agents[_agentId].id != 0, "Agent: Agent does not exist");
        require(agents[_agentId].owner == msg.sender, "Agent: Not agent owner");
        agents[_agentId].uri = _newUri;
        emit AgentProfileUpdated(_agentId, _newUri);
    }

    /**
     * @notice Retrieves comprehensive information about a specific agent.
     * @param _agentId The ID of the agent.
     * @return agentOwner The owner's address.
     * @return name The agent's name.
     * @return uri The agent's metadata URI.
     * @return reputation The agent's current reputation score.
     * @return isStaked Whether the agent is currently staked.
     * @return lastActivityTimestamp The timestamp of the agent's last major activity.
     */
    function getAgentDetails(uint256 _agentId) external view returns (
        address agentOwner,
        string memory name,
        string memory uri,
        uint256 reputation,
        bool isStaked,
        uint256 lastActivityTimestamp
    ) {
        require(agents[_agentId].id != 0, "Agent: Agent does not exist");
        Agent storage agent = agents[_agentId];
        return (
            agent.owner,
            agent.name,
            agent.uri,
            agent.reputation,
            agent.isStaked,
            agent.lastActivityTimestamp
        );
    }

    /**
     * @notice Standard ERC721 function to transfer ownership of an Agent NFT.
     * @param _from The current owner's address.
     * @param _to The recipient's address.
     * @param _agentId The ID of the Agent NFT to transfer.
     */
    function transferAgentNFT(address _from, address _to, uint256 _agentId) public _isApprovedOrOwner(msg.sender, _agentId) {
        require(ownerOf(_agentId) == _from, "ERC721: transfer from incorrect owner");
        _transferAgent(_from, _to, _agentId);
    }

    // --- Intent Lifecycle & Fulfillment (8 functions) ---

    /**
     * @notice Publishes a new intent, specifying the type, description, and bounty.
     * @param _templateId The ID of the intent template to use.
     * @param _descriptionURI A URI pointing to the detailed intent description (e.g., IPFS).
     * @param _bountyAmount The amount of bounty for fulfilling the intent.
     * @param _bountyTokenAddress The address of the ERC20 token used for the bounty.
     * @return The ID of the newly posted intent.
     */
    function postIntent(
        uint256 _templateId,
        string memory _descriptionURI,
        uint256 _bountyAmount,
        address _bountyTokenAddress
    ) public returns (uint256) {
        require(intentTemplates[_templateId].templateURI != "", "Intent: Invalid template ID");
        require(_bountyAmount > 0, "Intent: Bounty must be greater than zero");
        require(_bountyTokenAddress != address(0), "Intent: Bounty token address cannot be zero");

        // Transfer bounty from issuer to this contract
        IERC20(_bountyTokenAddress).transferFrom(msg.sender, address(this), _bountyAmount);

        _intentIdCounter.increment();
        uint256 newIntentId = _intentIdCounter.current();

        intents[newIntentId] = Intent({
            id: newIntentId,
            issuer: msg.sender,
            templateId: _templateId,
            descriptionURI: _descriptionURI,
            bountyAmount: _bountyAmount,
            bountyTokenAddress: _bountyTokenAddress,
            claimedByAgentId: 0,
            fulfillmentProofURI: "",
            status: IntentStatus.Open,
            postedTimestamp: block.timestamp,
            resolutionTimestamp: 0,
            hasDispute: false,
            disputeReasonURI: ""
        });

        emit IntentPosted(newIntentId, msg.sender, _templateId, _bountyAmount, _bountyTokenAddress);
        return newIntentId;
    }

    /**
     * @notice Allows the intent issuer to cancel an unfulfilled intent and reclaim the bounty.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(uint256 _intentId) public {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist");
        require(intent.issuer == msg.sender, "Intent: Not intent issuer");
        require(intent.status == IntentStatus.Open, "Intent: Intent is not open for cancellation");

        intent.status = IntentStatus.Cancelled;
        intent.resolutionTimestamp = block.timestamp;

        // Return bounty to issuer
        IERC20(intent.bountyTokenAddress).transfer(intent.issuer, intent.bountyAmount);

        emit IntentCancelled(_intentId);
    }

    /**
     * @notice An agent attempts to claim an available intent. Requires meeting certain criteria.
     * @param _intentId The ID of the intent to claim.
     * @param _agentId The ID of the agent claiming the intent.
     */
    function claimIntent(uint256 _intentId, uint256 _agentId) public {
        Intent storage intent = intents[_intentId];
        Agent storage agent = agents[_agentId];

        require(intent.id != 0, "Intent: Intent does not exist");
        require(agent.id != 0, "Agent: Agent does not exist");
        require(agent.owner == msg.sender, "Intent: Not agent owner");
        require(agent.isStaked, "Intent: Agent is not staked");
        require(intent.status == IntentStatus.Open, "Intent: Intent is not open for claiming");
        require(balanceOfCR(msg.sender) >= CR_CLAIM_FEE, "Intent: Insufficient CR to claim intent");
        // Additional checks: agent reputation, skill matching, etc. could be added here.
        // For example: require(agent.reputation >= MIN_REPUTATION_FOR_INTENT_TYPE, "Agent: Low reputation");

        // Deduct CR for claiming
        _burnCR(msg.sender, CR_CLAIM_FEE);

        intent.claimedByAgentId = _agentId;
        intent.status = IntentStatus.Claimed;
        agent.lastActivityTimestamp = block.timestamp; // Update agent activity

        emit IntentClaimed(_intentId, _agentId);
    }

    /**
     * @notice Agent submits a URI pointing to the proof of their intent fulfillment.
     * @param _intentId The ID of the intent.
     * @param _proofURI A URI pointing to the fulfillment proof (e.g., IPFS hash of results).
     */
    function submitFulfillmentProof(uint256 _intentId, string memory _proofURI) public {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist");
        require(intent.claimedByAgentId != 0, "Intent: Intent not claimed");
        require(agents[intent.claimedByAgentId].owner == msg.sender, "Intent: Not the claiming agent's owner");
        require(intent.status == IntentStatus.Claimed, "Intent: Intent is not in 'Claimed' status");

        intent.fulfillmentProofURI = _proofURI;
        intent.status = IntentStatus.Fulfilled; // Mark as fulfilled, awaiting issuer verification

        emit FulfillmentProofSubmitted(_intentId, intent.claimedByAgentId, _proofURI);
    }

    /**
     * @notice Intent issuer reviews the submitted proof and confirms or rejects fulfillment.
     * Triggers reward distribution or dispute phase.
     * @param _intentId The ID of the intent.
     * @param _success True if fulfillment is accepted, false if rejected.
     */
    function verifyIntentFulfillment(uint256 _intentId, bool _success) public {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist");
        require(intent.issuer == msg.sender, "Intent: Not intent issuer");
        require(intent.status == IntentStatus.Fulfilled, "Intent: Intent is not awaiting verification");
        require(intent.claimedByAgentId != 0, "Intent: Intent not claimed by an agent");

        intent.resolutionTimestamp = block.timestamp;
        Agent storage agent = agents[intent.claimedByAgentId];

        if (_success) {
            intent.status = IntentStatus.Verified;
            // Distribute bounty and CR rewards
            uint256 fee = intent.bountyAmount.mul(platformFeeRate).div(BASIS_POINTS_DENOMINATOR);
            uint256 rewardAmount = intent.bountyAmount.sub(fee);

            IERC20(intent.bountyTokenAddress).transfer(agent.owner, rewardAmount);
            platformFees[intent.bountyTokenAddress] = platformFees[intent.bountyTokenAddress].add(fee);

            _mintCR(agent.owner, CR_FULFILLMENT_REWARD); // Agent earns CR
            agent.reputation = agent.reputation.add(10); // Example: increase reputation
            agent.lastActivityTimestamp = block.timestamp; // Update agent activity

        } else {
            intent.status = IntentStatus.Rejected;
            agent.reputation = agent.reputation.sub(5); // Example: decrease reputation on rejection, can be disputed
            if (agent.reputation < 0) agent.reputation = 0; // Prevent negative reputation
        }

        emit IntentVerified(_intentId, intent.claimedByAgentId, _success);
    }

    /**
     * @notice Allows an agent to initiate a dispute if their fulfillment was rejected unfairly.
     * @param _intentId The ID of the intent under dispute.
     * @param _reasonURI A URI pointing to the detailed reason for the dispute.
     */
    function initiateDispute(uint256 _intentId, string memory _reasonURI) public {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist");
        require(intent.claimedByAgentId != 0, "Intent: Intent not claimed");
        require(agents[intent.claimedByAgentId].owner == msg.sender, "Intent: Not the claiming agent's owner");
        require(intent.status == IntentStatus.Rejected, "Intent: Intent is not in 'Rejected' status");
        require(!intent.hasDispute, "Intent: Dispute already initiated");

        intent.status = IntentStatus.Disputed;
        intent.hasDispute = true;
        intent.disputeReasonURI = _reasonURI;

        // Optionally, an agent could stake CR or another token to initiate a dispute.

        emit DisputeInitiated(_intentId, intent.claimedByAgentId, _reasonURI);
    }

    /**
     * @notice Allows the intent issuer to add more bounty to an existing intent.
     * @param _intentId The ID of the intent.
     * @param _amount The amount of additional bounty to add.
     */
    function fundIntent(uint256 _intentId, uint256 _amount) public {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist");
        require(intent.issuer == msg.sender, "Intent: Not intent issuer");
        require(intent.status == IntentStatus.Open || intent.status == IntentStatus.Claimed, "Intent: Intent cannot be funded in current status");
        require(_amount > 0, "Intent: Amount must be greater than zero");

        IERC20(intent.bountyTokenAddress).transferFrom(msg.sender, address(this), _amount);
        intent.bountyAmount = intent.bountyAmount.add(_amount);

        emit IntentFunded(_intentId, _amount);
    }

    /**
     * @notice Retrieves all details associated with a specific intent.
     * @param _intentId The ID of the intent.
     * @return Intent struct members.
     */
    function getIntentDetails(uint256 _intentId)
        external view returns (
            uint256 id,
            address issuer,
            uint256 templateId,
            string memory descriptionURI,
            uint256 bountyAmount,
            address bountyTokenAddress,
            uint256 claimedByAgentId,
            string memory fulfillmentProofURI,
            IntentStatus status,
            uint256 postedTimestamp,
            uint256 resolutionTimestamp,
            bool hasDispute,
            string memory disputeReasonURI
        )
    {
        require(intents[_intentId].id != 0, "Intent: Intent does not exist");
        Intent storage intent = intents[_intentId];
        return (
            intent.id,
            intent.issuer,
            intent.templateId,
            intent.descriptionURI,
            intent.bountyAmount,
            intent.bountyTokenAddress,
            intent.claimedByAgentId,
            intent.fulfillmentProofURI,
            intent.status,
            intent.postedTimestamp,
            intent.resolutionTimestamp,
            intent.hasDispute,
            intent.disputeReasonURI
        );
    }

    // --- System & Configuration (6 functions) ---

    /**
     * @notice Owner function to register a new structured intent template URI.
     * @param _templateURI A URI pointing to the intent's schema (e.g., JSON schema on IPFS).
     * @return The ID of the new intent template.
     */
    function addIntentTemplate(string memory _templateURI) public onlyOwner returns (uint256) {
        _templateIdCounter.increment();
        uint256 newTemplateId = _templateIdCounter.current();
        intentTemplates[newTemplateId] = IntentTemplate({ templateURI: _templateURI });
        emit IntentTemplateAdded(newTemplateId, _templateURI);
        return newTemplateId;
    }

    /**
     * @notice Owner function to define a new skill category for agents.
     * @param _name The name of the skill category (e.g., "AI_ModelTraining").
     * @param _description A description of the skill.
     * @return The ID of the new skill category.
     */
    function addSkillCategory(string memory _name, string memory _description) public onlyOwner returns (uint256) {
        _skillIdCounter.increment();
        uint256 newSkillId = _skillIdCounter.current();
        skillCategories[newSkillId] = SkillCategory({
            name: _name,
            description: _description,
            weight: 1 // Default weight, can be adjusted later
        });
        emit SkillCategoryAdded(newSkillId, _name);
        return newSkillId;
    }

    /**
     * @notice Owner function to modify the importance (weight) of a skill category in reputation calculations.
     * @param _skillCategoryId The ID of the skill category.
     * @param _newWeight The new weight to assign to the skill category.
     */
    function adjustSkillWeights(uint256 _skillCategoryId, uint256 _newWeight) public onlyOwner {
        require(skillCategories[_skillCategoryId].weight != 0, "Skill: Category does not exist");
        skillCategories[_skillCategoryId].weight = _newWeight;
        emit SkillWeightAdjusted(_skillCategoryId, _newWeight);
    }

    /**
     * @notice Owner/Judge function to definitively resolve a dispute.
     * @param _intentId The ID of the intent under dispute.
     * @param _agentWins True if the agent is found to be correct, false if the issuer is correct.
     */
    function resolveDispute(uint256 _intentId, bool _agentWins) public onlyOwner { // Can be extended to a DAO voting system or multi-sig
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "Intent: Intent does not exist");
        require(intent.status == IntentStatus.Disputed, "Dispute: Intent is not in 'Disputed' status");
        require(intent.claimedByAgentId != 0, "Dispute: No agent claimed this intent");

        Agent storage agent = agents[intent.claimedByAgentId];

        intent.resolutionTimestamp = block.timestamp;
        intent.hasDispute = false; // Dispute is resolved

        if (_agentWins) {
            intent.status = IntentStatus.Verified;
            // Distribute bounty and CR rewards (same logic as successful verification)
            uint256 fee = intent.bountyAmount.mul(platformFeeRate).div(BASIS_POINTS_DENOMINATOR);
            uint256 rewardAmount = intent.bountyAmount.sub(fee);

            IERC20(intent.bountyTokenAddress).transfer(agent.owner, rewardAmount);
            platformFees[intent.bountyTokenAddress] = platformFees[intent.bountyTokenAddress].add(fee);

            _mintCR(agent.owner, CR_FULFILLMENT_REWARD.mul(2)); // Agent gets extra CR for winning dispute
            agent.reputation = agent.reputation.add(20); // Significant reputation boost
            agent.lastActivityTimestamp = block.timestamp; // Update agent activity

        } else { // Issuer wins
            intent.status = IntentStatus.Rejected;
            // Bounty returned to issuer
            IERC20(intent.bountyTokenAddress).transfer(intent.issuer, intent.bountyAmount);
            agent.reputation = agent.reputation.sub(15); // Significant reputation penalty
            if (agent.reputation < 0) agent.reputation = 0; // Prevent negative reputation
        }
        emit DisputeResolved(_intentId, _agentWins);
    }

    /**
     * @notice Owner function to withdraw accumulated platform fees for a specific bounty token to a specified address.
     * @param _bountyTokenAddress The address of the bounty token for which fees are to be withdrawn.
     * @param _to The recipient of the fees.
     * @param _amount The amount to withdraw.
     */
    function withdrawPlatformFeesSpecificToken(address _bountyTokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_bountyTokenAddress != address(0), "Withdraw: Token address cannot be zero");
        require(_to != address(0), "Withdraw: Recipient cannot be zero address");
        require(platformFees[_bountyTokenAddress] >= _amount, "Withdraw: Insufficient fees accumulated for this token");

        platformFees[_bountyTokenAddress] = platformFees[_bountyTokenAddress].sub(_amount);
        IERC20(_bountyTokenAddress).transfer(_to, _amount);
        emit PlatformFeesWithdrawn(_to, _bountyTokenAddress, _amount);
    }

    /**
     * @notice Returns an array of intent IDs that are currently open for claiming by agents.
     * @return An array of open intent IDs.
     */
    function getAvailableIntents() public view returns (uint256[] memory) {
        uint256 currentMaxId = _intentIdCounter.current();
        uint256[] memory tempOpenIntentIds = new uint256[](currentMaxId); // Allocate max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= currentMaxId; i++) {
            if (intents[i].status == IntentStatus.Open) {
                tempOpenIntentIds[count] = i;
                count++;
            }
        }

        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempOpenIntentIds[i];
        }
        return result;
    }
}
```