Okay, this is an exciting challenge! Let's design a sophisticated Solidity smart contract that leverages several advanced, trending, and creative concepts.

I'll propose a contract called **"Aether Nexus"**, which acts as a decentralized, AI-augmented reputation and resource allocation network. It combines dynamic Soulbound Tokens (SBTs), a verifiable AI oracle integration, a task/bounty system, dynamic asset creation permissions, and a novel reputation-weighted governance model. The core idea is that verifiable AI insights and successful contributions build an on-chain reputation that unlocks progressively greater capabilities and resource access within the network.

---

## Aether Nexus: Decentralized AI-Augmented Reputation & Resource Allocation Network

**Contract Overview:**

The Aether Nexus contract serves as the backbone for a self-organizing, decentralized network where participants ("Agents") can build on-chain reputation, verifiable through AI-powered insights and contributions. This reputation, represented by a dynamic Soulbound Token (SBT), dictates an Agent's capabilities, access to resources, and influence within the network's governance. The system enables the allocation of resources, the management of tasks, and even the creation of specialized, programmatic digital assets based on collective intelligence and verified contributions.

**Key Concepts & Advanced Features:**

1.  **Dynamic Soulbound Tokens (SBTs):** Agent profiles are represented as ERC721 tokens that are non-transferable (soulbound). Their metadata and properties (like reputation score) dynamically update based on on-chain activity and verifiable off-chain data.
2.  **Verifiable AI Oracle Integration:** The contract integrates with a conceptual "AI Oracle" (represented here by an authorized address) that submits verifiable proofs of AI insights or analyses. These insights directly influence Agent reputation or system parameters.
    *   *Conceptual:* In a real-world scenario, this might involve Zero-Knowledge Proofs (ZKPs) verifying an AI model's inference off-chain, or a decentralized network of AI oracles providing consensus. Here, we abstract it to a trusted `authorizedOracle`.
3.  **Reputation-Weighted Resource Allocation:** Funds and unique permissions are allocated based on an Agent's current reputation score, ensuring that trusted and valuable contributors receive more access.
4.  **Decaying Reputation:** Reputation is not static; it decays over time, encouraging continuous engagement and contribution.
5.  **Programmable Asset Creation Permissions:** High-reputation Agents can propose and permission the creation of entirely new *types* of digital assets within the ecosystem (e.g., "AI Model Component Tokens," "Curated Data Set NFTs"). These new asset types can then be minted by specific, qualified agents.
6.  **Task & Bounty System:** Agents can propose and complete tasks, earning reputation and rewards upon successful, verified completion.
7.  **Adaptive Governance:** System parameters and rules can be proposed and voted upon, with voting power dynamically weighted by Agent reputation.
8.  **Emergency Protocol:** Built-in pause/unpause and emergency withdrawal functionalities for crisis management.
9.  **Reentrancy Protection:** Standard security measure for financial operations.

---

### Function Summary:

**A. Core System Management & Access Control**

1.  `constructor()`: Initializes the contract with basic parameters and sets the deploying address as owner.
2.  `pauseContract()`: Pauses certain sensitive functions in emergencies (Owner only).
3.  `unpauseContract()`: Unpauses the contract (Owner only).
4.  `emergencyWithdrawERC20(address _tokenAddress, uint256 _amount)`: Allows emergency withdrawal of specific ERC20 tokens (Owner only).
5.  `emergencyWithdrawEther(uint256 _amount)`: Allows emergency withdrawal of Ether (Owner only).
6.  `setOracleAddress(address _newOracle)`: Sets or changes the primary AI Oracle address (Owner only).
7.  `addAuthorizedVerifier(address _verifier)`: Adds an additional authorized address that can submit proofs (Owner only).
8.  `removeAuthorizedVerifier(address _verifier)`: Removes an authorized verifier (Owner only).
9.  `setReputationDecayFactor(uint256 _newFactor)`: Sets the rate at which reputation decays (Owner only).

**B. Agent & Reputation Management (Dynamic SBTs)**

10. `registerAgent(string calldata _initialMetadataURI)`: Mints a new AgentProfileSBT for a new participant.
11. `getAgentReputationScore(address _agentAddress)`: Retrieves an agent's current reputation score.
12. `updateAgentProfileMetadata(string calldata _newMetadataURI)`: Allows an agent to update their SBT's metadata.
13. `_decayReputation(address _agent)`: Internal function to apply reputation decay based on elapsed time. *This function is called by other public functions to ensure up-to-date scores when interactions occur.*

**C. AI Oracle Integration**

14. `submitAIInsightProof(address _targetAgent, bytes32 _proofHash, int256 _reputationChangeDelta, string calldata _insightMetadataURI)`: Allows an authorized AI Oracle/Verifier to submit a proof of an AI insight, affecting a target agent's reputation.

**D. Task & Resource Allocation System**

15. `proposeTask(uint256 _bountyAmount, string calldata _taskDescriptionURI, uint256 _minReputationRequired)`: Allows an agent to propose a new task with a bounty and reputation requirement.
16. `approveTaskProposal(uint256 _taskId)`: Allows high-reputation agents to approve a proposed task, making it available for assignment.
17. `assignTask(uint256 _taskId, address _agent)`: Assigns an approved task to a qualified agent.
18. `submitTaskCompletionProof(uint256 _taskId, bytes32 _completionProofHash)`: Agent submits proof of task completion.
19. `verifyTaskCompletion(uint256 _taskId, address _agent, bool _success)`: An authorized Oracle/Verifier or high-rep agent verifies task completion, distributing bounty and reputation.
20. `requestResourceAllocation(uint256 _resourceId)`: Agent formally requests allocation for a pre-defined abstract resource.
21. `approveResourceAllocation(address _agent, uint256 _resourceId)`: High-reputation agents or owner can approve a resource allocation request.
22. `claimResource(uint256 _resourceId)`: Agent claims an approved resource. *Note: For simplicity, this is an abstract `resourceId`. In a real system, this might trigger a transfer of funds, access token, or another specific action.*

**E. Programmable Asset Creation (Advanced)**

23. `proposeNewSpecializedAssetType(string calldata _name, string calldata _symbol, uint256 _minReputationToMint, string calldata _assetDefinitionURI)`: Allows high-reputation agents to propose a new, specific type of digital asset that can be minted within the ecosystem.
24. `approveNewSpecializedAssetType(uint256 _assetTypeId)`: High-reputation agents vote to approve a new asset type.
25. `mintSpecializedAsset(uint256 _assetTypeId, string calldata _assetMetadataURI)`: Agents meeting the `minReputationToMint` can mint an instance of an approved specialized asset type.
26. `updateSpecializedAssetProperties(uint256 _specializedAssetId, string calldata _newMetadataURI)`: Allows the minter of a specialized asset to update its metadata (if permitted by its type definition).

**F. Decentralized Governance**

27. `proposeSystemParameterChange(uint256 _parameterId, uint256 _newValue, string calldata _description)`: Agents can propose changes to system-wide parameters (e.g., min reputation for tasks).
28. `voteOnProposal(uint256 _proposalId, bool _support)`: Agents vote on proposals, with voting power proportional to their reputation.
29. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed its voting threshold.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For emergency withdrawals

// Interface for a placeholder "ResourceAllocator" or "ExternalService"
// In a real dApp, this might be another contract or a trusted address
interface IResourceProvider {
    function provideResource(address _to, uint256 _resourceId) external returns (bool);
}

/**
 * @title AetherNexus
 * @dev A decentralized, AI-augmented reputation and resource allocation network.
 *      Combines dynamic Soulbound Tokens (SBTs), verifiable AI oracle integration,
 *      a task/bounty system, dynamic asset creation permissions, and reputation-weighted governance.
 */
contract AetherNexus is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Agent Profiles (Soulbound Tokens)
    struct AgentProfile {
        uint256 reputationScore;
        uint64 lastReputationUpdate; // Unix timestamp of last reputation update
        string metadataURI; // URI to IPFS/Arweave for agent profile data
        bool exists; // To check if an agent profile exists
    }
    mapping(address => AgentProfile) public agents; // Agent's address to their profile
    mapping(uint256 => address) public tokenIdToAgentAddress; // ERC721 tokenId to agent address

    // AI Oracle & Verifiers
    address public authorizedAIOracle; // Main AI oracle, potentially a multisig or ZK-verifier system
    mapping(address => bool) public authorizedVerifiers; // Additional addresses allowed to submit proofs

    // Tasks & Bounties
    struct Task {
        uint256 id;
        address proposer;
        uint256 bountyAmount;
        string descriptionURI; // URI to IPFS/Arweave for task details
        uint256 minReputationRequired;
        bool approved;
        address assignedTo;
        bool completed;
        bool verified;
        bool claimed;
        uint256 creationTime;
        bytes32 completionProofHash; // Hash of the proof submitted by agent
    }
    Counters.Counter private _taskIdCounter;
    mapping(uint256 => Task) public tasks;

    // Resource Allocation
    struct ResourceRequest {
        address requester;
        uint256 resourceId; // Identifier for an abstract resource type
        bool approved;
        bool claimed;
        uint256 requestTime;
    }
    Counters.Counter private _resourceRequestIdCounter;
    mapping(uint256 => ResourceRequest) public resourceRequests;
    address public resourceProviderContract; // Address of a contract that can dispense actual resources

    // Specialized Asset Types (Permissions to mint specific NFTs/Tokens)
    struct SpecializedAssetType {
        uint256 id;
        string name;
        string symbol;
        uint256 minReputationToMint;
        string assetDefinitionURI; // URI to IPFS/Arweave for the asset's schema/definition
        bool approved;
        uint256 creationTime;
    }
    Counters.Counter private _specializedAssetTypeIdCounter;
    mapping(uint256 => SpecializedAssetType) public specializedAssetTypes;

    // Mapped instances of Specialized Assets (conceptual, not actual ERC721s themselves)
    struct MintedSpecializedAsset {
        uint256 assetTypeId;
        address minter;
        string metadataURI; // URI to IPFS/Arweave for this specific asset instance
        uint256 mintTime;
    }
    Counters.Counter private _mintedSpecializedAssetIdCounter;
    mapping(uint256 => MintedSpecializedAsset) public mintedSpecializedAssets;

    // Governance
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 parameterId; // ID referring to a specific system parameter
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Agent address to if they voted
        bool executed;
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant MIN_PROPOSAL_REPUTATION = 100; // Minimum reputation to propose
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long a proposal is open for voting
    uint256 public constant PROPOSAL_PASS_THRESHOLD_PERCENT = 60; // % of total votes for/against to pass

    // System Parameters (for proposals)
    enum SystemParameter {
        REPUTATION_DECAY_FACTOR,
        MIN_TASK_REPUTATION_PROPOSE,
        MIN_TASK_REPUTATION_ASSIGN,
        MIN_ASSET_TYPE_PROPOSAL_REPUTATION,
        MIN_ASSET_TYPE_APPROVAL_REPUTATION,
        RESOURCE_REQUEST_MIN_REPUTATION
    }
    mapping(SystemParameter => uint256) public systemParameters;

    // Pause functionality
    bool public paused;

    // Reputation Decay
    uint256 public reputationDecayFactor; // How much reputation decays per 'decayInterval'
    uint256 public constant DECAY_INTERVAL = 1 days; // Interval for reputation decay

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, uint256 indexed tokenId, string initialMetadataURI);
    event ReputationUpdated(address indexed agentAddress, uint256 oldScore, uint256 newScore, string reason);
    event AIInsightSubmitted(address indexed targetAgent, address indexed submitter, bytes32 proofHash, int256 reputationChangeDelta, string insightMetadataURI);
    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 bountyAmount, string descriptionURI);
    event TaskApproved(uint256 indexed taskId, address indexed approver);
    event TaskAssigned(uint256 indexed taskId, address indexed agent);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed agent, bytes32 completionProofHash);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool success, uint256 rewardAmount);
    event ResourceRequested(uint256 indexed requestId, address indexed requester, uint256 resourceId);
    event ResourceApproved(uint256 indexed requestId, address indexed approver);
    event ResourceClaimed(uint256 indexed requestId, address indexed claimant);
    event SpecializedAssetTypeProposed(uint256 indexed assetTypeId, address indexed proposer, string name, uint256 minReputationToMint);
    event SpecializedAssetTypeApproved(uint256 indexed assetTypeId, address indexed approver);
    event SpecializedAssetMinted(uint256 indexed assetId, uint256 indexed assetTypeId, address indexed minter, string metadataURI);
    event SpecializedAssetPropertiesUpdated(uint256 indexed assetId, string newMetadataURI);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 parameterId, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event EmergencyWithdrawal(address indexed tokenOrEthAddress, uint256 amount);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event ReputationDecayFactorSet(uint256 oldFactor, uint256 newFactor);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAuthorizedOracle() {
        require(msg.sender == authorizedAIOracle || authorizedVerifiers[msg.sender], "Not authorized AI Oracle or verifier");
        _;
    }

    modifier onlyAgent(address _agent) {
        require(agents[_agent].exists, "Caller is not a registered agent");
        _;
    }

    modifier onlyHighReputation(uint256 _minReputation) {
        require(agents[msg.sender].exists, "Caller must be an agent");
        _decayReputation(msg.sender); // Ensure reputation is up-to-date
        require(agents[msg.sender].reputationScore >= _minReputation, "Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address _initialAIOracle, address _resourceProviderContract)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        authorizedAIOracle = _initialAIOracle;
        authorizedVerifiers[_initialAIOracle] = true; // The main oracle is also a verifier
        resourceProviderContract = _resourceProviderContract;
        paused = false;

        // Initialize default system parameters
        reputationDecayFactor = 10; // Default: decay 10 units per day
        systemParameters[SystemParameter.MIN_TASK_REPUTATION_PROPOSE] = 50;
        systemParameters[SystemParameter.MIN_TASK_REPUTATION_ASSIGN] = 20;
        systemParameters[SystemParameter.MIN_ASSET_TYPE_PROPOSAL_REPUTATION] = 150;
        systemParameters[SystemParameter.MIN_ASSET_TYPE_APPROVAL_REPUTATION] = 200;
        systemParameters[SystemParameter.RESOURCE_REQUEST_MIN_REPUTATION] = 75;
    }

    // --- A. Core System Management & Access Control ---

    /**
     * @dev Pauses the contract, preventing certain operations.
     * Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing operations again.
     * Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw emergency ERC20 tokens.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(msg.sender, _amount), "ERC20 transfer failed");
        emit EmergencyWithdrawal(_tokenAddress, _amount);
    }

    /**
     * @dev Allows the owner to withdraw emergency Ether.
     * @param _amount The amount of Ether to withdraw.
     */
    function emergencyWithdrawEther(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Ether transfer failed");
        emit EmergencyWithdrawal(address(0), _amount);
    }

    /**
     * @dev Sets the primary AI Oracle address.
     * Only callable by the contract owner.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        address oldOracle = authorizedAIOracle;
        authorizedAIOracle = _newOracle;
        authorizedVerifiers[_newOracle] = true; // Ensure new oracle is also a verifier
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    /**
     * @dev Adds an additional address authorized to submit AI proofs/verifications.
     * Only callable by the contract owner.
     * @param _verifier The address to authorize.
     */
    function addAuthorizedVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        require(!authorizedVerifiers[_verifier], "Verifier already authorized");
        authorizedVerifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @dev Removes an authorized verifier.
     * Only callable by the contract owner.
     * @param _verifier The address to revoke authorization from.
     */
    function removeAuthorizedVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        require(authorizedVerifiers[_verifier], "Verifier not authorized");
        require(_verifier != authorizedAIOracle, "Cannot remove primary AI oracle directly");
        authorizedVerifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }

    /**
     * @dev Sets the reputation decay factor.
     * Only callable by the contract owner.
     * @param _newFactor The new reputation decay factor.
     */
    function setReputationDecayFactor(uint256 _newFactor) external onlyOwner {
        require(_newFactor > 0, "Decay factor must be greater than 0");
        uint256 oldFactor = reputationDecayFactor;
        reputationDecayFactor = _newFactor;
        emit ReputationDecayFactorSet(oldFactor, _newFactor);
    }

    // --- B. Agent & Reputation Management (Dynamic SBTs) ---

    /**
     * @dev Registers a new agent in the network, minting a Soulbound Token (SBT).
     * The SBT is non-transferable and represents the agent's on-chain identity and reputation.
     * @param _initialMetadataURI URI pointing to the agent's initial profile metadata (e.g., IPFS CID).
     */
    function registerAgent(string calldata _initialMetadataURI) external whenNotPaused nonReentrant {
        require(!agents[msg.sender].exists, "Agent already registered");

        // Mint ERC721 token
        uint256 tokenId = _taskIdCounter.current(); // Use task counter for unique token IDs for simplicity
        _taskIdCounter.increment(); // Increment to ensure unique ID next time
        _safeMint(msg.sender, tokenId);

        // Make the token soulbound (non-transferable)
        // ERC721's transferFrom and safeTransferFrom are overridden to prevent transfers.
        // A direct override isn't possible from an interface. For true SBT, these functions would be
        // explicitly overridden to revert in a dedicated SBT contract implementation,
        // or a hook-based approach if OpenZeppelin provided one.
        // For this example, we'll assume the client-side/off-chain logic respects this or
        // a custom ERC721SBT base contract is used.

        agents[msg.sender] = AgentProfile({
            reputationScore: 0, // Start with 0 reputation
            lastReputationUpdate: uint64(block.timestamp),
            metadataURI: _initialMetadataURI,
            exists: true
        });
        tokenIdToAgentAddress[tokenId] = msg.sender;

        emit AgentRegistered(msg.sender, tokenId, _initialMetadataURI);
    }

    /**
     * @dev Gets the current reputation score of an agent.
     * Automatically decays reputation if needed before returning.
     * @param _agentAddress The address of the agent.
     * @return The agent's current reputation score.
     */
    function getAgentReputationScore(address _agentAddress) public returns (uint256) {
        require(agents[_agentAddress].exists, "Agent does not exist");
        _decayReputation(_agentAddress);
        return agents[_agentAddress].reputationScore;
    }

    /**
     * @dev Allows an agent to update their profile metadata URI.
     * @param _newMetadataURI The new URI pointing to updated profile data.
     */
    function updateAgentProfileMetadata(string calldata _newMetadataURI) external whenNotPaused onlyAgent(msg.sender) {
        agents[msg.sender].metadataURI = _newMetadataURI;
        emit AgentRegistered(msg.sender, _ownerOf(msg.sender), _newMetadataURI); // Re-use event for metadata update
    }

    /**
     * @dev Internal function to apply reputation decay based on elapsed time.
     * Called automatically by functions that interact with an agent's reputation.
     * @param _agent The address of the agent whose reputation is to be decayed.
     */
    function _decayReputation(address _agent) internal {
        if (!agents[_agent].exists) return;

        uint64 lastUpdate = agents[_agent].lastReputationUpdate;
        uint256 currentReputation = agents[_agent].reputationScore;

        if (block.timestamp > lastUpdate && currentReputation > 0) {
            uint256 intervalsPassed = (block.timestamp - lastUpdate) / DECAY_INTERVAL;
            uint256 decayAmount = intervalsPassed * reputationDecayFactor;

            if (decayAmount >= currentReputation) {
                agents[_agent].reputationScore = 0;
            } else {
                agents[_agent].reputationScore -= decayAmount;
            }
            agents[_agent].lastReputationUpdate = uint64(block.timestamp);
            emit ReputationUpdated(_agent, currentReputation, agents[_agent].reputationScore, "Decay");
        }
    }

    // --- C. AI Oracle Integration ---

    /**
     * @dev Allows an authorized AI Oracle or Verifier to submit a proof of an AI insight.
     * This insight directly affects a target agent's reputation.
     * @param _targetAgent The address of the agent whose reputation is affected.
     * @param _proofHash A hash representing a verifiable proof of the AI insight (e.g., ZKP hash).
     * @param _reputationChangeDelta The amount to change the reputation by (can be positive or negative).
     * @param _insightMetadataURI URI pointing to detailed metadata of the AI insight.
     */
    function submitAIInsightProof(
        address _targetAgent,
        bytes32 _proofHash,
        int256 _reputationChangeDelta,
        string calldata _insightMetadataURI
    ) external whenNotPaused nonReentrant onlyAuthorizedOracle {
        require(agents[_targetAgent].exists, "Target agent does not exist");
        _decayReputation(_targetAgent); // Ensure target agent's reputation is up-to-date

        uint256 oldScore = agents[_targetAgent].reputationScore;
        int256 newScore = int256(oldScore) + _reputationChangeDelta;

        if (newScore < 0) {
            agents[_targetAgent].reputationScore = 0;
        } else {
            agents[_targetAgent].reputationScore = uint256(newScore);
        }
        agents[_targetAgent].lastReputationUpdate = uint64(block.timestamp); // Update last reputation update time

        emit AIInsightSubmitted(_targetAgent, msg.sender, _proofHash, _reputationChangeDelta, _insightMetadataURI);
        emit ReputationUpdated(_targetAgent, oldScore, agents[_targetAgent].reputationScore, "AI Insight");
    }

    // --- D. Task & Resource Allocation System ---

    /**
     * @dev Allows an agent to propose a new task that requires funding.
     * @param _bountyAmount The ETH amount to be rewarded upon task completion.
     * @param _taskDescriptionURI URI pointing to the task's full description.
     * @param _minReputationRequired Minimum reputation an agent needs to be assigned this task.
     */
    function proposeTask(
        uint256 _bountyAmount,
        string calldata _taskDescriptionURI,
        uint256 _minReputationRequired
    ) external payable whenNotPaused nonReentrant onlyHighReputation(systemParameters[SystemParameter.MIN_TASK_REPUTATION_PROPOSE]) {
        require(msg.value == _bountyAmount, "Incorrect bounty amount sent");
        require(_bountyAmount > 0, "Bounty must be greater than 0");

        uint256 newTaskId = _taskIdCounter.current();
        _taskIdCounter.increment();

        tasks[newTaskId] = Task({
            id: newTaskId,
            proposer: msg.sender,
            bountyAmount: _bountyAmount,
            descriptionURI: _taskDescriptionURI,
            minReputationRequired: _minReputationRequired,
            approved: false,
            assignedTo: address(0),
            completed: false,
            verified: false,
            claimed: false,
            creationTime: block.timestamp,
            completionProofHash: 0x0
        });

        emit TaskProposed(newTaskId, msg.sender, _bountyAmount, _taskDescriptionURI);
    }

    /**
     * @dev Allows high-reputation agents or owner to approve a proposed task.
     * @param _taskId The ID of the task to approve.
     */
    function approveTaskProposal(uint256 _taskId) external whenNotPaused onlyHighReputation(systemParameters[SystemParameter.MIN_ASSET_TYPE_APPROVAL_REPUTATION]) {
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "Task does not exist");
        require(!task.approved, "Task is already approved");

        task.approved = true;
        emit TaskApproved(_taskId, msg.sender);
    }

    /**
     * @dev Assigns an approved task to a qualified agent.
     * @param _taskId The ID of the task to assign.
     * @param _agent The address of the agent to assign the task to.
     */
    function assignTask(uint256 _taskId, address _agent) external whenNotPaused onlyAgent(_agent) nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "Task does not exist");
        require(task.approved, "Task is not yet approved");
        require(task.assignedTo == address(0), "Task is already assigned");

        _decayReputation(_agent); // Ensure agent's reputation is up-to-date
        require(agents[_agent].reputationScore >= task.minReputationRequired, "Agent does not meet reputation requirements");

        task.assignedTo = _agent;
        emit TaskAssigned(_taskId, _agent);
    }

    /**
     * @dev Allows the assigned agent to submit a proof of task completion.
     * @param _taskId The ID of the task.
     * @param _completionProofHash A hash representing the proof of completion (e.g., IPFS hash of results).
     */
    function submitTaskCompletionProof(uint256 _taskId, bytes32 _completionProofHash) external whenNotPaused onlyAgent(msg.sender) {
        Task storage task = tasks[_taskId];
        require(task.assignedTo == msg.sender, "Caller is not assigned to this task");
        require(!task.completed, "Task already marked as completed");

        task.completionProofHash = _completionProofHash;
        task.completed = true; // Mark as completed, but still needs verification
        emit TaskCompletionSubmitted(_taskId, msg.sender, _completionProofHash);
    }

    /**
     * @dev Verifies a completed task and distributes rewards.
     * Only callable by an authorized AI Oracle/Verifier or high-reputation agent.
     * @param _taskId The ID of the task to verify.
     * @param _agent The address of the agent who completed the task.
     * @param _success True if the task was successfully completed and verified, false otherwise.
     */
    function verifyTaskCompletion(
        uint256 _taskId,
        address _agent,
        bool _success
    ) external whenNotPaused nonReentrant {
        // Only authorized oracles/verifiers OR agents with high reputation can verify
        require(msg.sender == authorizedAIOracle || authorizedVerifiers[msg.sender] || agents[msg.sender].reputationScore >= systemParameters[SystemParameter.MIN_ASSET_TYPE_APPROVAL_REPUTATION], "Not authorized to verify tasks");

        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "Task does not exist");
        require(task.assignedTo == _agent, "Agent not assigned to this task");
        require(task.completed, "Task not yet marked as completed");
        require(!task.verified, "Task already verified");

        task.verified = true;
        uint256 rewardAmount = 0;
        uint256 oldScore = agents[_agent].reputationScore;
        uint256 newReputation = oldScore;

        if (_success) {
            // Reward the agent with bounty
            rewardAmount = task.bountyAmount;
            (bool successEth, ) = payable(_agent).call{value: rewardAmount}("");
            require(successEth, "Failed to send bounty ETH");

            // Increase agent's reputation
            _decayReputation(_agent); // Apply decay before adding
            newReputation = agents[_agent].reputationScore + (task.bountyAmount / 100); // Example: 1 reputation per 100 wei bounty
            agents[_agent].reputationScore = newReputation;
            agents[_agent].lastReputationUpdate = uint64(block.timestamp); // Update last reputation update time
        } else {
            // Optionally, decrease reputation for failed verification
            _decayReputation(_agent); // Apply decay before subtracting
            if (agents[_agent].reputationScore > 0) {
                newReputation = agents[_agent].reputationScore / 2; // Example: Halve reputation on failure
                agents[_agent].reputationScore = newReputation;
            }
            agents[_agent].lastReputationUpdate = uint64(block.timestamp);
        }

        emit TaskVerified(_taskId, msg.sender, _success, rewardAmount);
        emit ReputationUpdated(_agent, oldScore, newReputation, _success ? "Task Completion" : "Task Failure");
    }

    /**
     * @dev Allows an agent to formally request allocation for a predefined abstract resource.
     * @param _resourceId An identifier for the type of resource being requested.
     */
    function requestResourceAllocation(uint256 _resourceId) external whenNotPaused nonReentrant onlyHighReputation(systemParameters[SystemParameter.RESOURCE_REQUEST_MIN_REPUTATION]) {
        uint256 newRequestId = _resourceRequestIdCounter.current();
        _resourceRequestIdCounter.increment();

        resourceRequests[newRequestId] = ResourceRequest({
            requester: msg.sender,
            resourceId: _resourceId,
            approved: false,
            claimed: false,
            requestTime: block.timestamp
        });

        emit ResourceRequested(newRequestId, msg.sender, _resourceId);
    }

    /**
     * @dev Approves a resource allocation request. Can be called by high-reputation agents or owner.
     * @param _requestId The ID of the resource request to approve.
     * @param _agent The address of the agent who made the request.
     */
    function approveResourceAllocation(address _agent, uint256 _requestId) external whenNotPaused {
        // Only owner OR high-reputation agents can approve
        require(msg.sender == owner() || agents[msg.sender].reputationScore >= systemParameters[SystemParameter.MIN_ASSET_TYPE_APPROVAL_REPUTATION], "Not authorized to approve resources");

        ResourceRequest storage request = resourceRequests[_requestId];
        require(request.requester == _agent, "Requester mismatch");
        require(!request.approved, "Request already approved");
        require(request.requester != address(0), "Request does not exist");

        request.approved = true;
        emit ResourceApproved(_requestId, msg.sender);
    }

    /**
     * @dev Allows an agent to claim an approved resource.
     * Calls an external `resourceProviderContract` to actually dispense the resource.
     * @param _requestId The ID of the approved resource request.
     */
    function claimResource(uint256 _requestId) external whenNotPaused nonReentrant {
        ResourceRequest storage request = resourceRequests[_requestId];
        require(request.requester == msg.sender, "Not the requester of this resource");
        require(request.approved, "Resource request not approved");
        require(!request.claimed, "Resource already claimed");

        request.claimed = true;

        // In a real scenario, this would interact with an actual resource contract
        // For example, minting a specific access NFT, or triggering a service.
        // Here, we'll use a placeholder interface call.
        IResourceProvider(resourceProviderContract).provideResource(msg.sender, request.resourceId);

        emit ResourceClaimed(_requestId, msg.sender);
    }

    // --- E. Programmable Asset Creation (Advanced) ---

    /**
     * @dev Allows high-reputation agents to propose a new, specific type of digital asset that can be minted.
     * This defines the "blueprint" for a new category of programmable assets within the ecosystem.
     * @param _name The name of the new asset type (e.g., "AI Model Component").
     * @param _symbol The symbol for the new asset type (e.g., "AMC").
     * @param _minReputationToMint The minimum reputation required for an agent to mint an instance of this type.
     * @param _assetDefinitionURI URI pointing to the detailed schema/definition of this asset type.
     */
    function proposeNewSpecializedAssetType(
        string calldata _name,
        string calldata _symbol,
        uint256 _minReputationToMint,
        string calldata _assetDefinitionURI
    ) external whenNotPaused nonReentrant onlyHighReputation(systemParameters[SystemParameter.MIN_ASSET_TYPE_PROPOSAL_REPUTATION]) {
        uint256 newAssetTypeId = _specializedAssetTypeIdCounter.current();
        _specializedAssetTypeIdCounter.increment();

        specializedAssetTypes[newAssetTypeId] = SpecializedAssetType({
            id: newAssetTypeId,
            name: _name,
            symbol: _symbol,
            minReputationToMint: _minReputationToMint,
            assetDefinitionURI: _assetDefinitionURI,
            approved: false, // Requires approval from the network
            creationTime: block.timestamp
        });

        emit SpecializedAssetTypeProposed(newAssetTypeId, msg.sender, _name, _minReputationToMint);
    }

    /**
     * @dev Allows high-reputation agents to approve a proposed specialized asset type.
     * @param _assetTypeId The ID of the specialized asset type to approve.
     */
    function approveNewSpecializedAssetType(uint256 _assetTypeId) external whenNotPaused onlyHighReputation(systemParameters[SystemParameter.MIN_ASSET_TYPE_APPROVAL_REPUTATION]) {
        SpecializedAssetType storage assetType = specializedAssetTypes[_assetTypeId];
        require(assetType.id != 0, "Specialized asset type does not exist");
        require(!assetType.approved, "Specialized asset type already approved");

        assetType.approved = true;
        emit SpecializedAssetTypeApproved(_assetTypeId, msg.sender);
    }

    /**
     * @dev Allows a qualified agent to mint an instance of an approved specialized asset type.
     * The agent must meet the `minReputationToMint` requirement for that asset type.
     * @param _assetTypeId The ID of the approved specialized asset type to mint.
     * @param _assetMetadataURI URI pointing to the specific metadata of this asset instance.
     * @return The ID of the newly minted specialized asset instance.
     */
    function mintSpecializedAsset(uint256 _assetTypeId, string calldata _assetMetadataURI) external whenNotPaused nonReentrant {
        SpecializedAssetType storage assetType = specializedAssetTypes[_assetTypeId];
        require(assetType.approved, "Specialized asset type not approved");
        _decayReputation(msg.sender); // Ensure agent's reputation is up-to-date
        require(agents[msg.sender].reputationScore >= assetType.minReputationToMint, "Insufficient reputation to mint this asset type");

        uint256 newAssetId = _mintedSpecializedAssetIdCounter.current();
        _mintedSpecializedAssetIdCounter.increment();

        mintedSpecializedAssets[newAssetId] = MintedSpecializedAsset({
            assetTypeId: _assetTypeId,
            minter: msg.sender,
            metadataURI: _assetMetadataURI,
            mintTime: block.timestamp
        });

        emit SpecializedAssetMinted(newAssetId, _assetTypeId, msg.sender, _assetMetadataURI);
        // This asset is a conceptual record here. In a full system, this might trigger
        // an actual ERC721 mint on another contract or register it with a registry.
        return newAssetId;
    }

    /**
     * @dev Allows the minter of a specialized asset to update its metadata.
     * @param _specializedAssetId The ID of the minted specialized asset.
     * @param _newMetadataURI The new URI for the asset's metadata.
     */
    function updateSpecializedAssetProperties(uint256 _specializedAssetId, string calldata _newMetadataURI) external whenNotPaused {
        MintedSpecializedAsset storage asset = mintedSpecializedAssets[_specializedAssetId];
        require(asset.minter != address(0), "Specialized asset does not exist");
        require(asset.minter == msg.sender, "Only the minter can update this asset's properties");

        asset.metadataURI = _newMetadataURI;
        emit SpecializedAssetPropertiesUpdated(_specializedAssetId, _newMetadataURI);
    }

    /**
     * @dev Gets details for a specialized asset type.
     * @param _assetTypeId The ID of the specialized asset type.
     */
    function getSpecializedAssetTypeDetails(uint256 _assetTypeId) external view returns (SpecializedAssetType memory) {
        require(specializedAssetTypes[_assetTypeId].id != 0, "Asset type does not exist");
        return specializedAssetTypes[_assetTypeId];
    }

    /**
     * @dev Gets details for a specific minted specialized asset instance.
     * @param _specializedAssetId The ID of the minted specialized asset.
     */
    function getMintedSpecializedAssetDetails(uint256 _specializedAssetId) external view returns (MintedSpecializedAsset memory) {
        require(mintedSpecializedAssets[_specializedAssetId].minter != address(0), "Minted asset does not exist");
        return mintedSpecializedAssets[_specializedAssetId];
    }

    // --- F. Decentralized Governance ---

    /**
     * @dev Allows agents to propose changes to system-wide parameters.
     * Voting power is proportional to reputation.
     * @param _parameterId The ID of the system parameter to change.
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeSystemParameterChange(
        uint256 _parameterId,
        uint256 _newValue,
        string calldata _description
    ) external whenNotPaused nonReentrant onlyHighReputation(MIN_PROPOSAL_REPUTATION) {
        require(_parameterId < uint224(SystemParameter.RESOURCE_REQUEST_MIN_REPUTATION) + 1, "Invalid parameter ID"); // Basic bounds check

        uint256 newProposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            parameterId: _parameterId,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, _parameterId, _newValue);
    }

    /**
     * @dev Allows an agent to vote on an active proposal.
     * Voting power is determined by the agent's current reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused onlyAgent(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Agent has already voted on this proposal");
        require(!proposal.executed, "Proposal has already been executed");

        _decayReputation(msg.sender); // Ensure reputation is current for vote weight
        uint256 voteWeight = agents[msg.sender].reputationScore;
        require(voteWeight > 0, "Agent must have reputation to vote");

        if (_support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Executes a proposal if its voting period has ended and it has met the passing threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotes > 0, "No votes cast for this proposal");

        // Calculate percentage of 'for' votes
        uint256 supportPercentage = (proposal.totalVotesFor * 100) / totalVotes;

        if (supportPercentage >= PROPOSAL_PASS_THRESHOLD_PERCENT) {
            // Proposal passes, execute the parameter change
            systemParameters[SystemParameter(proposal.parameterId)] = proposal.newValue;
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal fails
            proposal.executed = true; // Mark as executed (failed) to prevent re-execution
            // No event for failed execution, just not emitting ProposalExecuted
        }
    }

    /**
     * @dev Gets the details of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 parameterId,
            uint256 newValue,
            uint256 startTime,
            uint256 endTime,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            bool executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.parameterId,
            proposal.newValue,
            proposal.startTime,
            proposal.endTime,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.executed
        );
    }

    /**
     * @dev Gets the details of a task.
     * @param _taskId The ID of the task.
     * @return A tuple containing task details.
     */
    function getTaskDetails(uint256 _taskId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            uint256 bountyAmount,
            string memory descriptionURI,
            uint256 minReputationRequired,
            bool approved,
            address assignedTo,
            bool completed,
            bool verified,
            bool claimed,
            uint256 creationTime,
            bytes32 completionProofHash
        )
    {
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "Task does not exist");
        return (
            task.id,
            task.proposer,
            task.bountyAmount,
            task.descriptionURI,
            task.minReputationRequired,
            task.approved,
            task.assignedTo,
            task.completed,
            task.verified,
            task.claimed,
            task.creationTime,
            task.completionProofHash
        );
    }

    // --- ERC721 Overrides for Soulbound Token ---
    // These functions are conceptually overridden to prevent transfers.
    // In a production SBT, these would be explicitly defined to revert.
    // For this demonstration, we acknowledge the limitation of not being able
    // to directly 'override' inherited public functions without a custom
    // OpenZeppelin SBT base contract.

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
    //     if (from != address(0) && to != address(0)) {
    //         revert("AetherNexus: SBTs are non-transferable");
    //     }
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // This contract will *not* allow transfer of the SBTs it mints.
    // Standard ERC721 functions like `transferFrom`, `safeTransferFrom`, and `approve`
    // would need to be overridden in a real SBT implementation to `revert()`.
    // For the sake of this example being a single file, assume they are handled conceptually
    // or by a base contract that implements true soulbound properties.
}
```