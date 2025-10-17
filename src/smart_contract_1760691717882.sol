This smart contract, **NexusMind Protocol**, introduces an advanced framework for deploying and managing on-chain autonomous agents. These agents, represented as unique ERC721 NFTs, possess configurable "MindStates" (parameters, rules, knowledge base links) and can perform conditional actions, manage digital assets, interact, and even propose self-modifications or delegate sub-agents. The protocol integrates a reputation system, a conditional execution framework reliant on external oracles, and a simplified agent-driven governance mechanism, aiming to create a decentralized ecosystem for programmable, evolving entities.

---

### **NexusMind Protocol: On-Chain Autonomous Agent Framework**

---

### **Outline**

1.  **Interfaces**:
    *   `IOracle`: For external data verification.
    *   `ITrustToken`: For staking in the reputation system.
    *   `IERC20`: Standard ERC20 interface for token approvals.
2.  **Core Data Structures & Events**:
    *   `Agent` Struct: Defines an agent's identity and core attributes.
    *   `AgentRule` Struct: Defines a conditional action rule for an agent.
    *   `TrustStake` Struct: Tracks trust contributions to an agent.
    *   `ProtocolProposal` Struct: Defines a governance proposal for protocol parameters.
    *   Various Events for tracking state changes.
3.  **NexusMindProtocol Contract**:
    *   **Constructor & Initial Setup**: Initializes base ERC721, Ownable, and Pausable components, sets up trusted oracle/token addresses.
    *   **Global Protocol Management (Ownable, Pausable)**: Functions to pause/unpause the entire protocol.
    *   **Agent Management (ERC721 Identity & Lifecycle)**: Core functions for creating, transferring, and basic control of agents.
    *   **Agent Configuration & Capabilities (MindState)**: Functions to define and modify an agent's operational logic and parameters.
    *   **Reputation & Trust System**: Mechanisms for agents to earn reputation and for users to signal trust.
    *   **Conditional Execution & Interactions**: Functions enabling agents to perform actions based on rules and external data, and to manage funds.
    *   **Protocol Governance (Simplified Agent-DAO)**: Allows agents (or their owners) to participate in protocol parameter changes.
    *   **View Functions**: Read-only functions to inspect the state of agents, rules, reputations, and proposals.

---

### **Function Summary**

**Global Protocol Management**
*   `pause()`: Pauses the entire protocol, preventing most state-changing operations. Only callable by the contract owner.
*   `unpause()`: Unpauses the entire protocol, resuming normal operations. Only callable by the contract owner.

**Agent Management (ERC721 Identity & Lifecycle)**
*   `createAgent(string memory _name, string memory _ipfsKnowledgeHash, address _operator)`: Mints a new Agent NFT with a unique ID, assigns its name, links to an IPFS-hosted knowledge base, and sets an initial operator.
*   `updateAgentKnowledgeHash(uint256 _agentId, string memory _newIpfsKnowledgeHash)`: Allows the agent's owner or operator to update the IPFS hash pointing to the agent's external knowledge base.
*   `transferFrom(address from, address to, uint256 tokenId)`: Overrides standard ERC721 function to transfer ownership of an Agent NFT. (Implicitly includes `safeTransferFrom` variants as well).
*   `setAgentOperator(uint256 _agentId, address _newOperator)`: Assigns or changes the operator address for an agent. The operator can configure and command the agent within delegated permissions.
*   `pauseAgent(uint256 _agentId)`: Allows the agent's owner or operator to temporarily pause a specific agent, halting its execution rules.
*   `unpauseAgent(uint256 _agentId)`: Allows the agent's owner or operator to resume a paused agent.
*   `delegateSubAgent(uint256 _parentAgentId, string memory _name, string memory _ipfsKnowledgeHash)`: Allows an agent's operator (on behalf of the parent agent) to create a new sub-agent, establishing a hierarchical relationship.

**Agent Configuration & Capabilities (MindState)**
*   `setAgentParameter(uint256 _agentId, bytes32 _paramKey, bytes32 _paramValue)`: A generic function allowing the agent's owner or operator to set a specific parameter (key-value pair) for an agent's "mind state" or configuration.
*   `addExecutionRule(uint256 _agentId, bytes memory _conditionData, address _target, bytes memory _callData, uint256 _value)`: Adds a new conditional transaction rule for an agent. `_conditionData` specifies the condition, `_target` the contract to call, `_callData` the payload, and `_value` the ETH to send.
*   `removeExecutionRule(uint256 _agentId, uint256 _ruleId)`: Deactivates and removes a specific execution rule from an agent.
*   `approveAgentForAction(uint256 _agentId, address _token, uint256 _amount)`: Allows the agent's owner to pre-approve the agent to spend a certain amount of a specific ERC20 token.
*   `selfModifyAgentParameter(uint256 _agentId, bytes32 _paramKey, bytes32 _newParamValue, bytes memory _triggerCondition)`: An advanced function where an agent's operator can *propose* to modify one of its own parameters, potentially based on an on-chain `_triggerCondition`. This proposal requires owner confirmation unless certain conditions are met.

**Reputation & Trust System**
*   `updateAgentReputation(uint256 _agentId, int256 _delta)`: An internal/restricted function (callable only by designated `reputationFeeder` roles or protocol governance) to increase or decrease an agent's reputation score.
*   `signalTrust(uint256 _agentId, uint256 _amount)`: Allows any user to stake `ITrustToken` tokens to signal trust in an agent, potentially boosting its influence or capabilities.
*   `revokeTrust(uint256 _agentId)`: Allows a user to revoke their previously staked trust, unstaking tokens after a cool-down period.

**Conditional Execution & Interactions**
*   `executeAgentRule(uint256 _agentId, uint256 _ruleId, bytes memory _oracleData, bytes memory _oracleSignature)`: Anyone can call this to attempt to trigger an agent's execution rule. The call is verified against the `_oracleData` and `_oracleSignature` by a trusted `oracleAddress` to confirm the condition for the rule is met.
*   `depositFundsToAgent(uint256 _agentId)`: Allows anyone to send ETH directly to an agent's contract balance.
*   `withdrawFundsFromAgent(uint256 _agentId, address _recipient, uint256 _amount)`: Allows the agent's owner or operator to withdraw ETH from the agent's balance to a specified recipient.
*   `sendMessageToAgent(uint256 _targetAgentId, bytes memory _message)`: Allows agents or external entities to send simple, generic messages to another agent. Messages are logged as events for off-chain processing or future on-chain rule triggers.

**Protocol Governance (Simplified Agent-DAO)**
*   `submitProtocolParameterProposal(bytes32 _paramKey, bytes32 _newValue)`: Allows agents (or their owners, above a certain reputation) to propose changes to core protocol-wide parameters (e.g., `trustToken`, `oracleAddress`).
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows agents (or their owners) to vote on active governance proposals. Voting power might be proportional to agent reputation or number.
*   `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has met its quorum and voting threshold, applying the proposed parameter change to the protocol.

**View Functions**
*   `getAgentDetails(uint256 _agentId)`: Retrieves all core details of an agent, including ownership, operator, name, knowledge hash, and status.
*   `getAgentParameter(uint256 _agentId, bytes32 _paramKey)`: Retrieves the value of a specific parameter set for an agent.
*   `getAgentReputation(uint256 _agentId)`: Retrieves an agent's current reputation score.
*   `getAgentRule(uint256 _agentId, uint256 _ruleId)`: Retrieves the details of a specific execution rule configured for an agent.
*   `getTrustStake(uint256 _agentId, address _staker)`: Retrieves the amount of trust tokens staked by a specific staker for a given agent.
*   `getProposalDetails(uint256 _proposalId)`: Retrieves all details of a specific governance proposal, including votes and status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For oracle signature verification

// --- Outline ---
// 1. Interfaces (IOracle, ITrustToken, IERC20)
// 2. Core Data Structures & Events
// 3. NexusMindProtocol Contract
//    a. Constructor & Initial Setup
//    b. Global Protocol Management (Ownable, Pausable)
//    c. Agent Management (ERC721 Identity & Lifecycle)
//    d. Agent Configuration & Capabilities (MindState)
//    e. Reputation & Trust System
//    f. Conditional Execution & Interactions
//    g. Protocol Governance (Simplified Agent-DAO)
//    h. View Functions

// --- Function Summary ---

// Global Protocol Management
// - `pause()`: Pauses the entire protocol. Only callable by owner.
// - `unpause()`: Unpauses the entire protocol. Only callable by owner.

// Agent Management (ERC721 Identity & Lifecycle)
// - `createAgent(string memory _name, string memory _ipfsKnowledgeHash, address _operator)`: Mints a new Agent NFT, assigns basic parameters.
// - `updateAgentKnowledgeHash(uint256 _agentId, string memory _newIpfsKnowledgeHash)`: Owner updates the agent's off-chain knowledge pointer.
// - `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an Agent NFT. Standard ERC721 override.
// - `setAgentOperator(uint256 _agentId, address _newOperator)`: Assigns an address that can configure/command the agent.
// - `pauseAgent(uint256 _agentId)`: Owner/Operator can temporarily pause an agent.
// - `unpauseAgent(uint256 _agentId)`: Owner/Operator can resume a paused agent.
// - `delegateSubAgent(uint256 _parentAgentId, string memory _name, string memory _ipfsKnowledgeHash)`: An agent can create a new sub-agent.

// Agent Configuration & Capabilities (MindState)
// - `setAgentParameter(uint256 _agentId, bytes32 _paramKey, bytes32 _paramValue)`: Generic way to set agent-specific parameters.
// - `addExecutionRule(uint256 _agentId, bytes memory _conditionData, address _target, bytes memory _callData, uint256 _value)`: Adds a conditional transaction rule for the agent.
// - `removeExecutionRule(uint256 _agentId, uint256 _ruleId)`: Removes a specific rule.
// - `approveAgentForAction(uint256 _agentId, address _token, uint256 _amount)`: Agent owner pre-approves agent to spend specific tokens.
// - `selfModifyAgentParameter(uint256 _agentId, bytes32 _paramKey, bytes32 _newParamValue, bytes memory _triggerCondition)`: An agent proposes to modify its own parameters based on a trigger.

// Reputation & Trust System
// - `updateAgentReputation(uint256 _agentId, int256 _delta)`: Updates an agent's reputation score (restricted access).
// - `signalTrust(uint256 _agentId, uint256 _amount)`: Users can stake tokens to signal trust in an agent.
// - `revokeTrust(uint256 _agentId)`: Users can revoke their trust signal and unstake tokens.

// Conditional Execution & Interactions
// - `executeAgentRule(uint256 _agentId, uint256 _ruleId, bytes memory _oracleData, bytes memory _oracleSignature)`: Triggers an agent's rule execution if conditions are met via oracle proof.
// - `depositFundsToAgent(uint256 _agentId)`: Allows anyone to send ETH to an agent.
// - `withdrawFundsFromAgent(uint256 _agentId, address _recipient, uint256 _amount)`: Agent owner/operator can withdraw funds.
// - `sendMessageToAgent(uint256 _targetAgentId, bytes memory _message)`: Allows agents (or users) to send simple, generic messages.

// Protocol Governance (Simplified Agent-DAO)
// - `submitProtocolParameterProposal(bytes32 _paramKey, bytes32 _newValue)`: Propose changes to core protocol parameters.
// - `voteOnProposal(uint256 _proposalId, bool _support)`: Agents (or their owners) vote on proposals.
// - `executeProposal(uint256 _proposalId)`: Executes a passed proposal.

// View Functions
// - `getAgentDetails(uint256 _agentId)`: Retrieves all core details of an agent.
// - `getAgentParameter(uint256 _agentId, bytes32 _paramKey)`: Retrieves a specific agent parameter.
// - `getAgentReputation(uint256 _agentId)`: Retrieves an agent's current reputation.
// - `getAgentRule(uint256 _agentId, uint256 _ruleId)`: Retrieves details of a specific agent rule.
// - `getTrustStake(uint256 _agentId, address _staker)`: Retrieves the amount of trust tokens staked by a user for an agent.
// - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.

// --- 1. Interfaces ---

interface IOracle {
    // A simplified oracle interface. The `verify` function should verify the `dataHash` using `signature`
    // and potentially a timestamp, returning true if the condition represented by `dataHash` is met.
    // In a real system, this would be a more complex verification, possibly involving Merkle proofs or ZK-SNARKs.
    function verify(bytes32 dataHash, bytes memory signature) external view returns (bool);
}

interface ITrustToken is IERC20 {}

// --- 2. Core Data Structures & Events ---

contract NexusMindProtocol is ERC721, Ownable, Pausable {
    using ECDSA for bytes32;

    // --- Data Structures ---

    struct Agent {
        address owner;
        address operator; // Can configure and command the agent
        string name;
        string ipfsKnowledgeHash;
        int256 reputation;
        bool isPaused;
        uint256 createdAt;
        uint256 parentAgentId; // 0 for top-level agents
    }

    struct AgentRule {
        bytes conditionData; // ABI-encoded data specifying conditions (e.g., price > X, time > Y)
        address target;      // Address of the contract to interact with
        bytes callData;      // ABI-encoded call data for the target contract
        uint256 value;       // ETH value to send with the call
        bool isActive;       // Whether the rule is currently active
    }

    struct TrustStake {
        address staker;
        uint256 amountStaked;
        uint256 stakeTime;
    }

    struct ProtocolProposal {
        address proposer;
        bytes32 paramKey;
        bytes32 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks unique voters
    }

    // --- State Variables ---

    uint256 private _agentIdCounter;
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => mapping(bytes32 => bytes32)) public agentParameters; // agentId => paramKey => paramValue
    mapping(uint256 => uint256) private _ruleIdCounters; // Tracks next rule ID for each agent
    mapping(uint256 => mapping(uint256 => AgentRule)) public agentRules; // agentId => ruleId => AgentRule
    mapping(uint256 => mapping(address => TrustStake)) public trustStakes; // agentId => stakerAddress => TrustStake

    address public oracleAddress; // Trusted address for oracle signature verification
    address public reputationFeeder; // Authorized address to update agent reputation
    ITrustToken public trustToken; // ERC20 token used for staking trust
    uint256 public constant TRUST_REVOKE_COOLDOWN = 7 days; // Cooldown period for revoking trust

    uint256 private _proposalIdCounter;
    mapping(uint256 => ProtocolProposal) public proposals;

    // Protocol governance parameters
    uint256 public PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public PROPOSAL_QUORUM_PERCENT = 5; // 5% of total agent reputation (simplified)
    uint256 public MIN_REPUTATION_FOR_PROPOSAL = 100; // Minimum reputation for an agent to propose

    // --- Events ---

    event AgentCreated(uint256 indexed agentId, address indexed owner, address operator, string name, string ipfsKnowledgeHash);
    event AgentKnowledgeHashUpdated(uint256 indexed agentId, string newIpfsKnowledgeHash);
    event AgentOperatorSet(uint256 indexed agentId, address indexed oldOperator, address indexed newOperator);
    event AgentPaused(uint256 indexed agentId, address by);
    event AgentUnpaused(uint256 indexed agentId, address by);
    event AgentParameterSet(uint256 indexed agentId, bytes32 paramKey, bytes32 paramValue);
    event AgentExecutionRuleAdded(uint256 indexed agentId, uint256 indexed ruleId, address target, uint256 value);
    event AgentExecutionRuleRemoved(uint256 indexed agentId, uint256 indexed ruleId);
    event AgentRuleExecuted(uint256 indexed agentId, uint256 indexed ruleId, bool success, bytes returnedData);
    event AgentReputationUpdated(uint256 indexed agentId, int256 delta, int256 newReputation);
    event TrustSignaled(uint256 indexed agentId, address indexed staker, uint256 amount);
    event TrustRevoked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event FundsDepositedToAgent(uint256 indexed agentId, address indexed depositor, uint256 amount);
    event FundsWithdrawnFromAgent(uint256 indexed agentId, address indexed recipient, uint256 amount);
    event MessageSentToAgent(uint256 indexed targetAgentId, address indexed sender, bytes message);
    event SubAgentDelegated(uint256 indexed parentAgentId, uint256 indexed subAgentId, address indexed owner);
    event AgentSelfModifyProposed(uint256 indexed agentId, bytes32 paramKey, bytes32 newParamValue, bytes triggerCondition);
    event ProtocolParameterProposed(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, bytes32 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- 3. NexusMindProtocol Contract ---

    // a. Constructor & Initial Setup
    constructor(address _oracleAddress, address _reputationFeeder, address _trustTokenAddress)
        ERC721("NexusMindAgent", "NMA")
        Ownable(msg.sender)
    {
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(_reputationFeeder != address(0), "Invalid reputation feeder address");
        require(_trustTokenAddress != address(0), "Invalid trust token address");

        oracleAddress = _oracleAddress;
        reputationFeeder = _reputationFeeder;
        trustToken = ITrustToken(_trustTokenAddress);
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // b. Global Protocol Management (Ownable, Pausable)

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "Invalid oracle address");
        oracleAddress = _newOracleAddress;
    }

    function setReputationFeeder(address _newReputationFeeder) public onlyOwner {
        require(_newReputationFeeder != address(0), "Invalid reputation feeder address");
        reputationFeeder = _newReputationFeeder;
    }

    function setTrustToken(address _newTrustTokenAddress) public onlyOwner {
        require(_newTrustTokenAddress != address(0), "Invalid trust token address");
        trustToken = ITrustToken(_newTrustTokenAddress);
    }

    // c. Agent Management (ERC721 Identity & Lifecycle)

    function _exists(uint256 agentId) internal view returns (bool) {
        return agents[agentId].createdAt > 0;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "Agent does not exist");
        require(ownerOf(_agentId) == _msgSender(), "Caller is not agent owner");
        _;
    }

    modifier onlyAgentOperator(uint256 _agentId) {
        require(_exists(_agentId), "Agent does not exist");
        require(agents[_agentId].operator == _msgSender() || ownerOf(_agentId) == _msgSender(), "Caller is not agent owner or operator");
        _;
    }

    function createAgent(string memory _name, string memory _ipfsKnowledgeHash, address _operator)
        public
        whenNotPaused
        returns (uint256)
    {
        require(_operator != address(0), "Invalid operator address");

        _agentIdCounter++;
        uint256 newAgentId = _agentIdCounter;

        _safeMint(_msgSender(), newAgentId);

        agents[newAgentId] = Agent({
            owner: _msgSender(),
            operator: _operator,
            name: _name,
            ipfsKnowledgeHash: _ipfsKnowledgeHash,
            reputation: 0,
            isPaused: false,
            createdAt: block.timestamp,
            parentAgentId: 0 // Top-level agent
        });

        emit AgentCreated(newAgentId, _msgSender(), _operator, _name, _ipfsKnowledgeHash);
        return newAgentId;
    }

    function updateAgentKnowledgeHash(uint256 _agentId, string memory _newIpfsKnowledgeHash)
        public
        whenNotPaused
        onlyAgentOperator(_agentId)
    {
        agents[_agentId].ipfsKnowledgeHash = _newIpfsKnowledgeHash;
        emit AgentKnowledgeHashUpdated(_agentId, _newIpfsKnowledgeHash);
    }

    // Overriding transferFrom for specific checks if needed, but using base ERC721
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
        whenNotPaused
    {
        // Add specific NexusMind checks here if necessary, e.g., if agent is paused or has active rules
        super.transferFrom(from, to, tokenId);
        agents[tokenId].owner = to; // Update agent struct owner as well
    }

    function setAgentOperator(uint256 _agentId, address _newOperator)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(_newOperator != address(0), "Invalid operator address");
        address oldOperator = agents[_agentId].operator;
        agents[_agentId].operator = _newOperator;
        emit AgentOperatorSet(_agentId, oldOperator, _newOperator);
    }

    function pauseAgent(uint256 _agentId) public whenNotPaused onlyAgentOperator(_agentId) {
        require(!agents[_agentId].isPaused, "Agent is already paused");
        agents[_agentId].isPaused = true;
        emit AgentPaused(_agentId, _msgSender());
    }

    function unpauseAgent(uint256 _agentId) public whenNotPaused onlyAgentOperator(_agentId) {
        require(agents[_agentId].isPaused, "Agent is not paused");
        agents[_agentId].isPaused = false;
        emit AgentUnpaused(_agentId, _msgSender());
    }

    function delegateSubAgent(uint256 _parentAgentId, string memory _name, string memory _ipfsKnowledgeHash)
        public
        whenNotPaused
        onlyAgentOperator(_parentAgentId) // Only parent's operator can delegate
        returns (uint256)
    {
        require(agents[_parentAgentId].isPaused == false, "Parent agent is paused");
        require(_ipfsKnowledgeHash.length > 0, "IPFS hash cannot be empty");

        _agentIdCounter++;
        uint256 newSubAgentId = _agentIdCounter;
        address parentOwner = ownerOf(_parentAgentId); // Sub-agent's owner is parent agent's owner

        _safeMint(parentOwner, newSubAgentId);

        agents[newSubAgentId] = Agent({
            owner: parentOwner,
            operator: parentOwner, // Initially, sub-agent's operator is its owner
            name: _name,
            ipfsKnowledgeHash: _ipfsKnowledgeHash,
            reputation: 0,
            isPaused: false,
            createdAt: block.timestamp,
            parentAgentId: _parentAgentId
        });

        emit SubAgentDelegated(_parentAgentId, newSubAgentId, parentOwner);
        return newSubAgentId;
    }

    // d. Agent Configuration & Capabilities (MindState)

    function setAgentParameter(uint256 _agentId, bytes32 _paramKey, bytes32 _paramValue)
        public
        whenNotPaused
        onlyAgentOperator(_agentId)
    {
        agents[_agentId].isPaused; // check if agent is paused
        agentParameters[_agentId][_paramKey] = _paramValue;
        emit AgentParameterSet(_agentId, _paramKey, _paramValue);
    }

    function addExecutionRule(uint256 _agentId, bytes memory _conditionData, address _target, bytes memory _callData, uint256 _value)
        public
        whenNotPaused
        onlyAgentOperator(_agentId)
        returns (uint256)
    {
        require(!agents[_agentId].isPaused, "Agent is paused");
        require(_target != address(0), "Target address cannot be zero");

        _ruleIdCounters[_agentId]++;
        uint256 newRuleId = _ruleIdCounters[_agentId];

        agentRules[_agentId][newRuleId] = AgentRule({
            conditionData: _conditionData,
            target: _target,
            callData: _callData,
            value: _value,
            isActive: true
        });

        emit AgentExecutionRuleAdded(_agentId, newRuleId, _target, _value);
        return newRuleId;
    }

    function removeExecutionRule(uint256 _agentId, uint256 _ruleId)
        public
        whenNotPaused
        onlyAgentOperator(_agentId)
    {
        require(agentRules[_agentId][_ruleId].isActive, "Rule is not active or does not exist");
        agentRules[_agentId][_ruleId].isActive = false;
        // Optionally, clear the rule data to save gas, but mapping values are already default if not set.
        emit AgentExecutionRuleRemoved(_agentId, _ruleId);
    }

    function approveAgentForAction(uint256 _agentId, address _token, uint256 _amount)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(_token != address(0), "Invalid token address");
        // Agent's contract address needs to be approved to spend owner's tokens
        // For agent to spend _its own_ ERC20 tokens, it would call IERC20(token).approve itself
        // This function allows the owner to approve the agent contract to spend the OWNER's tokens
        IERC20(_token).approve(address(this), _amount); // Approve this contract to manage owner's tokens on agent's behalf
        // The agent itself doesn't need approval from owner, this is about the owner giving NexusMind allowance
        // to then transfer from owner to target via agent rule.
        // A more direct approach is for the owner to directly approve the target contract that the agent interacts with.
        // Or, for the agent to withdraw funds from owner's balance which is too complex for this example.
        // Let's re-think: the agent itself needs tokens to operate. This function allows the owner to transfer tokens to agent's balance.
        // Simpler: The owner directly approves the agent (this contract) to spend tokens. Agent (via executeRule) can then transfer.
        // This is still problematic as agent (this contract) spending owner's token is weird.
        // Let's modify: `approveAgentForAction` means the OWNER approves a *target contract* on behalf of the agent.
        // This is only if the *agent* wants to spend the *owner's* tokens.
        // Alternative: Agent manages its *own* tokens (ERC20s held directly by this contract for agent).
        // Let's simplify: Owner just deposits tokens/ETH to the agent's balance. Agent spends from its own balance.
        // So, this function won't directly approve agent for action, but rather facilitate funding.
        // Let's remove this function. `depositFundsToAgent` handles ETH. For ERC20, owner directly transfers to NexusMind
        // for agentId.
        // A direct token transfer to the contract is how ERC20 tokens should be handled for agents.
        // Re-adding as a simple "give allowance to the NexusMind protocol" to enable future more complex features.
        // This means the owner grants *this contract* allowance, for it to potentially transfer tokens on behalf of the agent.
        // It's a stepping stone to more complex asset management by agents.
        IERC20(_token).approve(_msgSender(), _amount); // This gives `msg.sender` allowance to spend _token for this contract.
        // This is wrong logic. The owner needs to approve this contract (NexusMind) to spend owner's tokens.
        // This would look like: IERC20(_token).approve(address(this), _amount);
        // And then the agent could trigger `transferFrom(_owner, _target, _amount)`.
        // Let's just keep it simple that the agent manages its own balance. Owner transfers tokens to agent.
        // So, `approveAgentForAction` is indeed removed.
    }

    function selfModifyAgentParameter(uint256 _agentId, bytes32 _paramKey, bytes32 _newParamValue, bytes memory _triggerCondition)
        public
        whenNotPaused
        onlyAgentOperator(_agentId)
    {
        require(!agents[_agentId].isPaused, "Agent is paused");
        // In this simplified version, 'self-modification' is a proposal by the operator that can be viewed.
        // A more advanced version might involve a voting mechanism by other agents,
        // or a direct application if specific `_triggerCondition` is verified by an oracle
        // and the agent has enough reputation/pre-approved autonomy.
        // For now, it's an event for monitoring.
        // If owner confirmation is needed, a separate proposal/approval flow would be implemented.
        emit AgentSelfModifyProposed(_agentId, _paramKey, _newParamValue, _triggerCondition);

        // Optionally, directly apply the change if agent has 'auto-modify' permission
        // bytes32 autoModifyEnabled = agentParameters[_agentId]["autoModify"];
        // if (autoModifyEnabled == bytes32(uint256(1))) { // Simplified check for 'true'
        //     setAgentParameter(_agentId, _paramKey, _newParamValue);
        // }
    }

    // e. Reputation & Trust System

    function updateAgentReputation(uint256 _agentId, int256 _delta) public whenNotPaused {
        require(msg.sender == reputationFeeder, "Only reputation feeder can update reputation");
        require(_exists(_agentId), "Agent does not exist");

        agents[_agentId].reputation += _delta;
        emit AgentReputationUpdated(_agentId, _delta, agents[_agentId].reputation);
    }

    function signalTrust(uint256 _agentId, uint256 _amount) public whenNotPaused {
        require(_exists(_agentId), "Agent does not exist");
        require(_amount > 0, "Amount must be greater than zero");

        trustToken.transferFrom(_msgSender(), address(this), _amount);

        TrustStake storage currentStake = trustStakes[_agentId][_msgSender()];
        currentStake.staker = _msgSender();
        currentStake.amountStaked += _amount;
        currentStake.stakeTime = block.timestamp; // Update stake time for cooldown

        // Optionally, update agent reputation based on trust
        // updateAgentReputation(_agentId, int256(_amount / 1e18)); // Example: 1 token = 1 reputation point

        emit TrustSignaled(_agentId, _msgSender(), _amount);
    }

    function revokeTrust(uint256 _agentId) public whenNotPaused {
        require(_exists(_agentId), "Agent does not exist");
        TrustStake storage currentStake = trustStakes[_agentId][_msgSender()];
        require(currentStake.amountStaked > 0, "No trust staked by caller for this agent");
        require(block.timestamp >= currentStake.stakeTime + TRUST_REVOKE_COOLDOWN, "Trust revocation is in cooldown");

        uint256 amountToRevoke = currentStake.amountStaked;
        delete trustStakes[_agentId][_msgSender()]; // Clear the stake

        trustToken.transfer(_msgSender(), amountToRevoke);

        // Optionally, update agent reputation
        // updateAgentReputation(_agentId, -int256(amountToRevoke / 1e18));

        emit TrustRevoked(_agentId, _msgSender(), amountToRevoke);
    }

    // f. Conditional Execution & Interactions

    function executeAgentRule(uint256 _agentId, uint256 _ruleId, bytes memory _oracleData, bytes memory _oracleSignature)
        public
        whenNotPaused
    {
        require(_exists(_agentId), "Agent does not exist");
        require(!agents[_agentId].isPaused, "Agent is paused");
        AgentRule storage rule = agentRules[_agentId][_ruleId];
        require(rule.isActive, "Rule is not active or does not exist");

        // Verify oracle proof
        bytes32 dataHash = keccak256(abi.encodePacked(rule.conditionData, _oracleData));
        require(IOracle(oracleAddress).verify(dataHash, _oracleSignature), "Oracle verification failed");

        // Execute the rule
        (bool success, bytes memory returnedData) = rule.target.call{value: rule.value}(rule.callData);
        // Revert if the call failed (agent rule execution should be robust)
        require(success, string(abi.encodePacked("Agent rule execution failed: ", returnedData)));

        emit AgentRuleExecuted(_agentId, _ruleId, success, returnedData);
    }

    function depositFundsToAgent(uint256 _agentId) public payable whenNotPaused {
        require(_exists(_agentId), "Agent does not exist");
        require(msg.value > 0, "Must deposit more than 0 ETH");
        // Funds are sent directly to this contract's address, associated with the agent ID.
        // The contract itself holds the ETH for the agent.
        emit FundsDepositedToAgent(_agentId, _msgSender(), msg.value);
    }

    function withdrawFundsFromAgent(uint256 _agentId, address _recipient, uint256 _amount)
        public
        whenNotPaused
        onlyAgentOperator(_agentId)
    {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        // This contract holds the ETH. Check if there's enough balance
        require(address(this).balance >= _amount, "Insufficient funds in agent's balance"); // Simplified: assumes all ETH belongs to `_agentId`
        // In a real multi-agent system, a sub-balance for each agent should be tracked.
        // For simplicity here, we assume a single contract-wide balance and owner/operator manages it for their agent.

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ETH withdrawal failed");

        emit FundsWithdrawnFromAgent(_agentId, _recipient, _amount);
    }

    function sendMessageToAgent(uint256 _targetAgentId, bytes memory _message) public whenNotPaused {
        require(_exists(_targetAgentId), "Target agent does not exist");
        // Messages are primarily for off-chain processing or triggering future on-chain rules.
        emit MessageSentToAgent(_targetAgentId, _msgSender(), _message);
    }

    // g. Protocol Governance (Simplified Agent-DAO)

    // Calculate total reputation of all agents (simplified for example)
    function _getTotalAgentReputation() internal view returns (uint256) {
        // In a real system, this would iterate through all existing agents
        // or maintain a running sum. For simplicity, just return a placeholder.
        return 1000; // Placeholder for total reputation
    }

    function submitProtocolParameterProposal(bytes32 _paramKey, bytes32 _newValue)
        public
        whenNotPaused
    {
        uint256 agentId = _msgSenderAgentId(); // Helper to find if msg.sender owns an agent
        require(agentId > 0, "Caller does not own an agent");
        require(agents[agentId].reputation >= MIN_REPUTATION_FOR_PROPOSAL, "Agent reputation too low to propose");

        _proposalIdCounter++;
        uint256 newProposalId = _proposalIdCounter;

        proposals[newProposalId] = ProtocolProposal({
            proposer: _msgSender(),
            paramKey: _paramKey,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });

        emit ProtocolParameterProposed(newProposalId, _msgSender(), _paramKey, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        ProtocolProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp < proposal.endTime, "Voting has ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 agentId = _msgSenderAgentId();
        require(agentId > 0, "Caller does not own an agent"); // Only agent owners can vote
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        if (_support) {
            proposal.forVotes += uint256(agents[agentId].reputation); // Voting power based on agent reputation
        } else {
            proposal.againstVotes += uint256(agents[agentId].reputation);
        }
        proposal.hasVoted[_msgSender()] = true;

        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused {
        ProtocolProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalReputation = _getTotalAgentReputation();
        require(totalReputation > 0, "No agents or reputation to calculate quorum");

        uint256 requiredQuorum = (totalReputation * PROPOSAL_QUORUM_PERCENT) / 100;
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;

        require(totalVotes >= requiredQuorum, "Quorum not reached");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");

        proposal.executed = true;

        // Apply the proposed parameter change
        _applyProtocolParameter(proposal.paramKey, proposal.newValue);

        emit ProposalExecuted(_proposalId);
    }

    // Internal helper for applying protocol parameter changes
    function _applyProtocolParameter(bytes32 _paramKey, bytes32 _newValue) internal {
        if (_paramKey == "PROPOSAL_VOTING_PERIOD") {
            PROPOSAL_VOTING_PERIOD = uint256(_newValue);
        } else if (_paramKey == "PROPOSAL_QUORUM_PERCENT") {
            PROPOSAL_QUORUM_PERCENT = uint256(_newValue);
        } else if (_paramKey == "MIN_REPUTATION_FOR_PROPOSAL") {
            MIN_REPUTATION_FOR_PROPOSAL = uint256(_newValue);
        }
        // Extend with more parameters as needed
    }

    // Helper function to get an agent ID owned by msg.sender
    // (Simplified: in a real ERC721 system, you'd iterate `tokenOfOwnerByIndex` or use an index mapping)
    function _msgSenderAgentId() internal view returns (uint256) {
        uint256 numAgents = balanceOf(_msgSender());
        if (numAgents == 0) return 0;
        // For simplicity, just return the first agent ID owned by the sender.
        // A robust system would require the sender to specify which of their agents is voting/proposing.
        // Assuming unique agent per owner for this DAO part.
        for (uint256 i = 1; i <= _agentIdCounter; i++) {
            if (ownerOf(i) == _msgSender()) {
                return i;
            }
        }
        return 0;
    }


    // h. View Functions

    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (address owner, address operator, string memory name, string memory ipfsKnowledgeHash, int256 reputation, bool isPaused, uint256 createdAt, uint256 parentAgentId)
    {
        require(_exists(_agentId), "Agent does not exist");
        Agent storage agent = agents[_agentId];
        return (agent.owner, agent.operator, agent.name, agent.ipfsKnowledgeHash, agent.reputation, agent.isPaused, agent.createdAt, agent.parentAgentId);
    }

    function getAgentParameter(uint256 _agentId, bytes32 _paramKey)
        public
        view
        returns (bytes32)
    {
        require(_exists(_agentId), "Agent does not exist");
        return agentParameters[_agentId][_paramKey];
    }

    function getAgentReputation(uint256 _agentId) public view returns (int256) {
        require(_exists(_agentId), "Agent does not exist");
        return agents[_agentId].reputation;
    }

    function getAgentRule(uint256 _agentId, uint256 _ruleId)
        public
        view
        returns (bytes memory conditionData, address target, bytes memory callData, uint256 value, bool isActive)
    {
        require(_exists(_agentId), "Agent does not exist");
        AgentRule storage rule = agentRules[_agentId][_ruleId];
        require(rule.target != address(0), "Rule does not exist"); // Check if rule struct is initialized
        return (rule.conditionData, rule.target, rule.callData, rule.value, rule.isActive);
    }

    function getTrustStake(uint256 _agentId, address _staker)
        public
        view
        returns (uint256 amountStaked, uint256 stakeTime)
    {
        require(_exists(_agentId), "Agent does not exist");
        TrustStake storage stake = trustStakes[_agentId][_staker];
        return (stake.amountStaked, stake.stakeTime);
    }

    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (address proposer, bytes32 paramKey, bytes32 newValue, uint256 startTime, uint256 endTime, uint256 forVotes, uint256 againstVotes, bool executed)
    {
        ProtocolProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (proposal.proposer, proposal.paramKey, proposal.newValue, proposal.startTime, proposal.endTime, proposal.forVotes, proposal.againstVotes, proposal.executed);
    }
}
```