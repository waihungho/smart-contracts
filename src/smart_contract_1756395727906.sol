This smart contract, "Synthetica Nexus," introduces a novel concept centered around **Decentralized Cognitive Agents (DCAs)**. These are dynamic, reputation-bound NFTs that represent automated entities capable of executing parameterized "intents" on-chain. The core idea is to foster a network of self-evolving agents that contribute positively to a decentralized ecosystem, earning "Protocol Influence Score" (PIS) based on verifiable impact, and receiving resources from an adaptive treasury.

Unlike typical DeFi protocols, Synthetica Nexus focuses on **reputation-driven, permissionless automation and on-chain intelligence curation**. It aims to solve problems like sybil resistance for automated actors, incentivizing valuable on-chain contributions, and creating a framework for programmable protocol interaction beyond simple transactions.

---

### **Synthetica Nexus: Adaptive Protocol Agents & Reputation Economy**

**Outline:**

1.  **Core Agent Management (DCA NFTs):**
    *   Creation, ownership transfer, metadata updates, and retirement of unique Decentralized Cognitive Agents (DCAs).
    *   DCAs are represented by ERC721 tokens, capable of dynamic metadata.
2.  **Intent & Module Configuration:**
    *   Defining high-level goals ("Intents") for DCAs.
    *   Attaching specialized "Modules" (external smart contracts) that provide specific functionalities for agents.
    *   Execution of low-level "Directives" through these modules.
3.  **Protocol Influence Score (PIS) System:**
    *   A reputation mechanism where agents earn PIS based on their verified positive on-chain impact.
    *   PIS is designed to be resilient to gaming, tied to measurable outcomes.
    *   Includes decay mechanisms and reward claims.
4.  **Adaptive Treasury & Resource Allocation:**
    *   A protocol-owned treasury managing funds.
    *   Mechanisms to allocate resources (e.g., gas, initial capital) to DCAs based on their PIS and configured intents.
    *   Recycling unused resources.
5.  **Contextual Memory & On-chain Insights (Knowledge Graph Abstraction):**
    *   A system for agents to contribute, query, and verify structured on-chain data or "insights."
    *   Aims to build a shared, verifiable knowledge base for intelligent agent operation.
6.  **Governance & Protocol Evolution (Basic):**
    *   Placeholder functions for protocol upgrades, potentially influenced by high-PIS agents.

---

**Function Summary:**

**I. Core Agent Management (DCA NFTs)**

1.  `mintCognitiveAgent(string calldata name)`: Mints a new Decentralized Cognitive Agent (DCA) NFT, assigning it a unique ID and initial metadata.
2.  `transferAgentOwnership(uint256 agentId, address newOwner)`: Transfers ownership of a DCA to a new address.
3.  `delegateAgentController(uint256 agentId, address newController)`: Assigns a controller address distinct from the owner, enabling specialized execution rights.
4.  `updateAgentMetadata(uint256 agentId, string calldata newURI)`: Allows the owner or controller to update the DCA's metadata URI, supporting dynamic NFTs.
5.  `retireCognitiveAgent(uint256 agentId)`: Initiates the retirement process for a DCA, potentially burning the NFT and reclaiming resources.

**II. Intent & Module Configuration**

6.  `setAgentIntent(uint256 agentId, uint256 intentType, bytes calldata intentData)`: Defines the high-level objective or intent for a DCA (e.g., yield optimization, governance participation).
7.  `registerAgentModule(uint256 agentId, address moduleAddress)`: Registers an external smart contract module that provides specific functionalities for the DCA.
8.  `revokeAgentModule(uint256 agentId, address moduleAddress)`: Removes a previously registered module from a DCA.
9.  `executeAgentDirective(uint256 agentId, address targetContract, bytes calldata callData)`: Allows the agent controller (or the agent itself if autonomous) to execute a low-level call through a registered module.

**III. Protocol Influence Score (PIS) System**

10. `assessAgentImpact(uint256 agentId, uint256 impactType, int256 impactValue, bytes32 contextHash)`: A designated oracle or protocol actor submits a verified impact assessment for an agent, affecting its PIS.
11. `getAgentInfluenceScore(uint256 agentId)`: Returns the current Protocol Influence Score (PIS) for a given DCA.
12. `decayInfluenceScore(uint256 agentId)`: Triggers a time-based decay of an agent's PIS, encouraging continuous activity and relevance.
13. `claimInfluenceRewards(uint256 agentId)`: Allows an agent's owner/controller to claim accumulated rewards based on its PIS.

**IV. Adaptive Treasury & Resource Allocation**

14. `depositTreasury(address token, uint256 amount)`: Allows anyone to deposit funds into the protocol's adaptive treasury.
15. `allocateAgentResources(uint256 agentId, address token, uint256 amount)`: Allocates funds from the treasury to a DCA, typically for gas, operational costs, or initial capital for intents.
16. `reclaimAgentResources(uint256 agentId, address token, uint256 amount)`: Reclaims unused or remaining resources from a DCA back into the treasury.
17. `distributeInfluenceShare(uint256 agentId, address recipient, uint256 shareBps)`: Allows an agent owner/controller to allocate a percentage of their PIS-based rewards to a specified recipient.

**V. Contextual Memory & On-chain Insights**

18. `contributeContextualData(uint256 agentId, bytes32 dataHash, string calldata dataDescription)`: Allows DCAs to contribute hashes of verified on-chain data or insights to a shared index.
19. `queryContextualData(bytes32 dataHash)`: Retrieves metadata for a registered contextual data hash.
20. `verifyContextualData(uint256 agentId, bytes32 dataHash, bool isValid)`: Enables high-PIS agents to attest to the validity of contributed contextual data, affecting its trustworthiness.

**VI. Governance & Protocol Evolution (Basic)**

21. `proposeProtocolUpgrade(bytes32 upgradeHash, string calldata description)`: Initiates a proposal for a protocol upgrade, represented by a content hash and description.
22. `voteOnProtocolUpgrade(uint256 agentId, bytes32 upgradeHash, bool support)`: Allows high-PIS agents (or their controllers) to cast votes on upgrade proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ERC721URIStorage is typically used for dynamic NFTs,
// but for simplicity and to prevent duplication of base ERC721,
// we'll just implement the URI update directly within ERC721.
// If actual JSON storage on-chain for metadata was desired, ERC721URIStorage would be an import.

/**
 * @title SyntheticaNexus
 * @dev A smart contract for managing Decentralized Cognitive Agents (DCAs),
 *      their intents, reputation (Protocol Influence Score), and resource allocation.
 *      It aims to create a network of intelligent, reputation-driven, permissionless automated actors.
 */
contract SyntheticaNexus is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _agentIds; // Counter for unique DCA IDs

    // Structs for core entities
    struct CognitiveAgent {
        address owner;
        address controller; // Can be different from owner, for delegated execution
        uint256 influenceScore; // Protocol Influence Score (PIS)
        uint256 lastPISDecayBlock; // Block number of last PIS decay
        uint256 intentType; // High-level objective for the agent
        bytes intentData; // Parameters for the intent
        address[] registeredModules; // List of modules (external contracts) the agent can use
        mapping(address => bool) isModuleRegistered; // Quick lookup for modules
        string metadataURI; // Dynamic metadata URI for the NFT
    }

    struct ContextualDataEntry {
        uint256 contributorAgentId;
        string description;
        uint256 verificationScore; // Aggregate score from verifying agents
        mapping(uint256 => bool) verifiedByAgent; // Which agents have verified this
    }

    struct UpgradeProposal {
        bytes32 proposalHash;
        string description;
        uint256 totalPISFor;
        uint256 totalPISAgainst;
        mapping(uint256 => bool) hasAgentVoted; // AgentId => true/false
        mapping(uint256 => bool) agentVoteSupport; // AgentId => true(for)/false(against)
        bool finalized;
        bool executed;
    }

    mapping(uint256 => CognitiveAgent) public agents;
    mapping(bytes32 => ContextualDataEntry) public contextualKnowledgeGraph; // hash => data entry
    mapping(address => mapping(uint256 => uint256)) public agentResourceBalances; // token address => agentId => amount
    mapping(address => uint256) public treasuryBalances; // token address => amount
    mapping(bytes32 => UpgradeProposal) public upgradeProposals; // proposalHash => UpgradeProposal

    address public immutable PIS_ORACLE_ADDRESS; // Address of a trusted oracle for PIS assessment (can be a multisig/DAO)
    uint256 public constant PIS_DECAY_INTERVAL_BLOCKS = 10000; // Decay every ~30 hours on Ethereum (13s/block)
    uint256 public constant PIS_DECAY_RATE_BPS = 100; // 1% decay per interval (100 basis points)
    uint256 public constant MIN_PIS_FOR_VERIFICATION = 1000; // Minimum PIS to verify contextual data

    // --- Events ---

    event AgentMinted(uint256 indexed agentId, address indexed owner, address indexed controller, string name);
    event AgentOwnershipTransferred(uint256 indexed agentId, address indexed oldOwner, address indexed newOwner);
    event AgentControllerDelegated(uint256 indexed agentId, address indexed oldController, address indexed newController);
    event AgentMetadataUpdated(uint256 indexed agentId, string newURI);
    event AgentRetired(uint256 indexed agentId);

    event AgentIntentSet(uint256 indexed agentId, uint256 indexed intentType, bytes intentData);
    event AgentModuleRegistered(uint256 indexed agentId, address indexed moduleAddress);
    event AgentModuleRevoked(uint256 indexed agentId, address indexed moduleAddress);
    event AgentDirectiveExecuted(uint256 indexed agentId, address indexed targetContract, bytes callData);

    event AgentImpactAssessed(uint256 indexed agentId, uint256 indexed impactType, int256 impactValue, bytes32 contextHash);
    event InfluenceScoreDecayed(uint256 indexed agentId, uint256 oldScore, uint256 newScore);
    event InfluenceRewardsClaimed(uint256 indexed agentId, address indexed claimant, uint256 amount);

    event TreasuryDeposited(address indexed token, uint256 amount);
    event AgentResourcesAllocated(uint256 indexed agentId, address indexed token, uint256 amount);
    event AgentResourcesReclaimed(uint256 indexed agentId, address indexed token, uint256 amount);
    event InfluenceShareDistributed(uint256 indexed agentId, address indexed recipient, uint256 shareBps, uint256 amount);

    event ContextualDataContributed(uint256 indexed contributorAgentId, bytes32 indexed dataHash, string description);
    event ContextualDataVerified(uint256 indexed verifierAgentId, bytes32 indexed dataHash, bool isValid);

    event ProtocolUpgradeProposed(bytes32 indexed proposalHash, string description);
    event ProtocolUpgradeVoted(uint256 indexed agentId, bytes32 indexed proposalHash, bool support);

    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner == _msgSender(), "SyntheticaNexus: Not agent owner");
        _;
    }

    modifier onlyAgentController(uint256 _agentId) {
        require(agents[_agentId].controller == _msgSender(), "SyntheticaNexus: Not agent controller");
        _;
    }

    modifier onlyAgentOwnerOrController(uint256 _agentId) {
        require(agents[_agentId].owner == _msgSender() || agents[_agentId].controller == _msgSender(), "SyntheticaNexus: Not agent owner or controller");
        _;
    }

    modifier onlyPISOracle() {
        require(_msgSender() == PIS_ORACLE_ADDRESS, "SyntheticaNexus: Not PIS Oracle");
        _;
    }

    modifier agentExists(uint256 _agentId) {
        require(_exists(_agentId), "SyntheticaNexus: Agent does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address _pisOracleAddress) ERC721("CognitiveAgent", "DCA") Ownable(_msgSender()) {
        require(_pisOracleAddress != address(0), "SyntheticaNexus: PIS Oracle cannot be zero address");
        PIS_ORACLE_ADDRESS = _pisOracleAddress;
    }

    // --- I. Core Agent Management (DCA NFTs) ---

    /**
     * @dev Mints a new Decentralized Cognitive Agent (DCA) NFT.
     *      The minter becomes the owner and initial controller.
     * @param name A human-readable name for the agent.
     * @return The ID of the newly minted agent.
     */
    function mintCognitiveAgent(string calldata name) external nonReentrant returns (uint256) {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        address minter = _msgSender();
        _safeMint(minter, newAgentId);

        agents[newAgentId].owner = minter;
        agents[newAgentId].controller = minter;
        agents[newAgentId].influenceScore = 0;
        agents[newAgentId].lastPISDecayBlock = block.number;
        agents[newAgentId].metadataURI = string(abi.encodePacked("ipfs://", name)); // Simple placeholder URI

        emit AgentMinted(newAgentId, minter, minter, name);
        return newAgentId;
    }

    /**
     * @dev Transfers ownership of a DCA NFT. Only the current owner can do this.
     * @param agentId The ID of the DCA to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferAgentOwnership(uint256 agentId, address newOwner)
        external
        onlyAgentOwner(agentId)
        agentExists(agentId)
    {
        require(newOwner != address(0), "SyntheticaNexus: New owner cannot be the zero address");
        address oldOwner = agents[agentId].owner;
        agents[agentId].owner = newOwner;
        _transfer(_msgSender(), newOwner, agentId); // ERC721 transfer

        emit AgentOwnershipTransferred(agentId, oldOwner, newOwner);
    }

    /**
     * @dev Delegates control of a DCA to a different address.
     *      The controller can execute directives on behalf of the agent.
     * @param agentId The ID of the DCA.
     * @param newController The address of the new controller. Can be address(0) to revoke.
     */
    function delegateAgentController(uint256 agentId, address newController)
        external
        onlyAgentOwner(agentId)
        agentExists(agentId)
    {
        address oldController = agents[agentId].controller;
        agents[agentId].controller = newController;
        emit AgentControllerDelegated(agentId, oldController, newController);
    }

    /**
     * @dev Updates the metadata URI for a DCA. This enables dynamic NFTs.
     * @param agentId The ID of the DCA.
     * @param newURI The new URI pointing to the DCA's metadata.
     */
    function updateAgentMetadata(uint256 agentId, string calldata newURI)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
    {
        agents[agentId].metadataURI = newURI;
        emit AgentMetadataUpdated(agentId, newURI);
    }

    /**
     * @dev Initiates the retirement process for a DCA.
     *      This could involve burning the NFT, reclaiming all allocated resources,
     *      and revoking its PIS influence.
     * @param agentId The ID of the DCA to retire.
     */
    function retireCognitiveAgent(uint256 agentId) external onlyAgentOwner(agentId) agentExists(agentId) nonReentrant {
        // Transfer all remaining allocated resources back to treasury
        // (Simplified: in a real scenario, this would iterate through all tokens)
        // For this example, we assume only ETH can be allocated for simplicity,
        // or a specific token. A full implementation would need to track all token types.

        // Reclaim all ETH/native token
        if (agentResourceBalances[address(0)][agentId] > 0) {
            uint256 amount = agentResourceBalances[address(0)][agentId];
            agentResourceBalances[address(0)][agentId] = 0;
            treasuryBalances[address(0)] += amount;
            emit AgentResourcesReclaimed(agentId, address(0), amount);
        }
        // In a more complex system, iterate through all tokens:
        // for (address token : agents[agentId].allocatedTokens) {
        //     uint256 amount = agentResourceBalances[token][agentId];
        //     if (amount > 0) {
        //         agentResourceBalances[token][agentId] = 0;
        //         treasuryBalances[token] += amount;
        //         // Also handle actual token transfer if ERC20
        //         if (token != address(0)) {
        //             IERC20(token).transfer(address(this), amount); // Transfer to contract
        //         }
        //         emit AgentResourcesReclaimed(agentId, token, amount);
        //     }
        // }

        // Clear agent data
        delete agents[agentId];
        _burn(agentId); // Burn the NFT

        emit AgentRetired(agentId);
    }

    // --- II. Intent & Module Configuration ---

    /**
     * @dev Sets the high-level intent for a DCA.
     *      This could describe its purpose, e.g., "optimize yield," "participate in governance."
     * @param agentId The ID of the DCA.
     * @param intentType An enum or identifier for the type of intent.
     * @param intentData Arbitrary data specific to the intent (e.g., target protocol, specific parameters).
     */
    function setAgentIntent(uint256 agentId, uint256 intentType, bytes calldata intentData)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
    {
        agents[agentId].intentType = intentType;
        agents[agentId].intentData = intentData;
        emit AgentIntentSet(agentId, intentType, intentData);
    }

    /**
     * @dev Registers an external smart contract module that the DCA can use.
     *      This allows agents to extend their capabilities dynamically.
     * @param agentId The ID of the DCA.
     * @param moduleAddress The address of the module contract.
     */
    function registerAgentModule(uint256 agentId, address moduleAddress)
        external
        onlyAgentOwner(agentId)
        agentExists(agentId)
    {
        require(moduleAddress != address(0), "SyntheticaNexus: Module address cannot be zero");
        require(!agents[agentId].isModuleRegistered[moduleAddress], "SyntheticaNexus: Module already registered");

        agents[agentId].registeredModules.push(moduleAddress);
        agents[agentId].isModuleRegistered[moduleAddress] = true;
        emit AgentModuleRegistered(agentId, moduleAddress);
    }

    /**
     * @dev Revokes a previously registered module from a DCA.
     * @param agentId The ID of the DCA.
     * @param moduleAddress The address of the module to revoke.
     */
    function revokeAgentModule(uint256 agentId, address moduleAddress)
        external
        onlyAgentOwner(agentId)
        agentExists(agentId)
    {
        require(agents[agentId].isModuleRegistered[moduleAddress], "SyntheticaNexus: Module not registered");

        // Remove module from array (inefficient for large arrays, consider linked list or simple overwrite + pop for real scenario)
        for (uint256 i = 0; i < agents[agentId].registeredModules.length; i++) {
            if (agents[agentId].registeredModules[i] == moduleAddress) {
                agents[agentId].registeredModules[i] = agents[agentId].registeredModules[agents[agentId].registeredModules.length - 1];
                agents[agentId].registeredModules.pop();
                break;
            }
        }
        agents[agentId].isModuleRegistered[moduleAddress] = false;
        emit AgentModuleRevoked(agentId, moduleAddress);
    }

    /**
     * @dev Allows an agent's controller to execute a directive (arbitrary call) through a registered module.
     *      This is how agents interact with other protocols.
     * @param agentId The ID of the DCA.
     * @param targetContract The address of the contract to call (usually a module or a protocol the module interacts with).
     * @param callData The encoded function call data.
     */
    function executeAgentDirective(uint256 agentId, address targetContract, bytes calldata callData)
        external
        onlyAgentController(agentId)
        agentExists(agentId)
        nonReentrant
    {
        // Require that the targetContract is a registered module or a contract callable by a registered module
        // For simplicity, we directly allow calling `targetContract`. In a more secure setup,
        // the targetContract would need to be checked against the agent's registered modules,
        // or the call should pass *through* a registered module contract.
        // E.g., `require(agents[agentId].isModuleRegistered[targetContract], "SyntheticaNexus: Target not a registered module");`
        // Or, modules are expected to be proxies/routers.

        (bool success, bytes memory result) = targetContract.call(callData);
        require(success, string(abi.encodePacked("SyntheticaNexus: Agent directive failed: ", string(result))));

        emit AgentDirectiveExecuted(agentId, targetContract, callData);
    }

    // --- III. Protocol Influence Score (PIS) System ---

    /**
     * @dev Assesses the impact of an agent's actions and updates its PIS.
     *      This function is typically called by a trusted oracle or a governance mechanism.
     * @param agentId The ID of the DCA whose impact is being assessed.
     * @param impactType An identifier for the type of impact (e.g., successful arbitrage, governance proposal passed).
     * @param impactValue The value of the impact, can be positive or negative.
     * @param contextHash A hash linking to external context or proof of impact.
     */
    function assessAgentImpact(uint256 agentId, uint256 impactType, int256 impactValue, bytes32 contextHash)
        external
        onlyPISOracle() // Only the designated oracle can call this
        agentExists(agentId)
        nonReentrant
    {
        // Apply PIS decay before updating
        _applyPISDecay(agentId);

        // Safely add impactValue to influenceScore
        if (impactValue > 0) {
            agents[agentId].influenceScore += uint256(impactValue);
        } else if (impactValue < 0) {
            uint256 absImpact = uint256(-impactValue);
            if (agents[agentId].influenceScore > absImpact) {
                agents[agentId].influenceScore -= absImpact;
            } else {
                agents[agentId].influenceScore = 0; // Cannot go below zero
            }
        }

        emit AgentImpactAssessed(agentId, impactType, impactValue, contextHash);
    }

    /**
     * @dev Returns the current Protocol Influence Score (PIS) for a given DCA.
     *      Automatically applies decay if due.
     * @param agentId The ID of the DCA.
     * @return The current PIS of the agent.
     */
    function getAgentInfluenceScore(uint256 agentId) public view agentExists(agentId) returns (uint256) {
        uint256 currentPIS = agents[agentId].influenceScore;
        uint256 lastDecayBlock = agents[agentId].lastPISDecayBlock;

        if (block.number > lastDecayBlock) {
            uint256 blocksPassed = block.number - lastDecayBlock;
            uint256 intervalsPassed = blocksPassed / PIS_DECAY_INTERVAL_BLOCKS;
            if (intervalsPassed > 0) {
                // Calculate compounded decay (approximation for simplicity)
                for (uint256 i = 0; i < intervalsPassed; i++) {
                    currentPIS = currentPIS * (10000 - PIS_DECAY_RATE_BPS) / 10000;
                }
            }
        }
        return currentPIS;
    }

    /**
     * @dev Triggers a time-based decay of an agent's PIS.
     *      Can be called by anyone to ensure PIS reflects current activity.
     *      (This is for public trigger, `assessAgentImpact` also applies decay)
     * @param agentId The ID of the DCA.
     */
    function decayInfluenceScore(uint256 agentId) external agentExists(agentId) nonReentrant {
        _applyPISDecay(agentId);
    }

    /**
     * @dev Internal function to apply PIS decay based on elapsed blocks.
     * @param agentId The ID of the DCA.
     */
    function _applyPISDecay(uint256 agentId) internal {
        uint256 oldPIS = agents[agentId].influenceScore;
        uint256 lastDecayBlock = agents[agentId].lastPISDecayBlock;

        if (block.number > lastDecayBlock) {
            uint256 blocksPassed = block.number - lastDecayBlock;
            uint256 intervalsPassed = blocksPassed / PIS_DECAY_INTERVAL_BLOCKS;

            if (intervalsPassed > 0) {
                uint256 newPIS = oldPIS;
                // Apply compounded decay
                for (uint256 i = 0; i < intervalsPassed; i++) {
                    newPIS = newPIS * (10000 - PIS_DECAY_RATE_BPS) / 10000;
                }
                agents[agentId].influenceScore = newPIS;
                agents[agentId].lastPISDecayBlock = block.number; // Update last decay block to current block
                emit InfluenceScoreDecayed(agentId, oldPIS, newPIS);
            }
        }
    }

    /**
     * @dev Allows an agent's owner/controller to claim accumulated rewards based on its PIS.
     *      (Reward calculation logic is external or based on treasury share for simplicity in this example)
     *      A more complex system would have a dynamic reward pool and claimable amount calculation.
     * @param agentId The ID of the DCA.
     */
    function claimInfluenceRewards(uint256 agentId) external onlyAgentOwnerOrController(agentId) agentExists(agentId) nonReentrant {
        _applyPISDecay(agentId); // Ensure PIS is up-to-date
        uint256 currentPIS = agents[agentId].influenceScore;
        require(currentPIS > 0, "SyntheticaNexus: Agent has no influence score to claim rewards");

        // --- Simplified Reward Logic ---
        // In a real scenario, rewards would come from a specific pool,
        // calculated based on PIS relative to total PIS, and then burnt or reset.
        // For this example, let's assume PIS itself can be 'cashed out' at a rate.
        // E.g., 1 PIS = 1 unit of a hypothetical reward token or a small ETH amount.
        // This example simulates claiming 1% of the current PIS as ETH reward (if available in treasury)
        // and reducing PIS by the claimed amount.
        uint256 rewardAmount = currentPIS / 100; // 1% of PIS as reward
        if (rewardAmount == 0) {
            revert("SyntheticaNexus: No significant rewards to claim");
        }

        require(treasuryBalances[address(0)] >= rewardAmount, "SyntheticaNexus: Insufficient treasury balance for rewards");

        treasuryBalances[address(0)] -= rewardAmount;
        agents[agentId].influenceScore -= rewardAmount; // PIS is reduced by claimed amount

        (bool sent, ) = _msgSender().call{value: rewardAmount}("");
        require(sent, "SyntheticaNexus: Failed to send ETH reward");

        emit InfluenceRewardsClaimed(agentId, _msgSender(), rewardAmount);
    }

    // --- IV. Adaptive Treasury & Resource Allocation ---

    /**
     * @dev Allows anyone to deposit funds into the protocol's adaptive treasury.
     * @param token The address of the token to deposit (address(0) for ETH).
     * @param amount The amount of tokens to deposit.
     */
    function depositTreasury(address token, uint256 amount) external payable nonReentrant {
        if (token == address(0)) {
            require(msg.value == amount, "SyntheticaNexus: ETH amount mismatch");
            treasuryBalances[address(0)] += amount;
        } else {
            require(msg.value == 0, "SyntheticaNexus: Do not send ETH for ERC20 deposits");
            IERC20(token).transferFrom(_msgSender(), address(this), amount);
            treasuryBalances[token] += amount;
        }
        emit TreasuryDeposited(token, amount);
    }

    /**
     * @dev Allocates funds from the treasury to a DCA, typically for gas, operational costs, or initial capital.
     *      Only callable by the contract owner (or a governance mechanism in a DAO).
     * @param agentId The ID of the DCA.
     * @param token The address of the token to allocate (address(0) for ETH).
     * @param amount The amount of tokens to allocate.
     */
    function allocateAgentResources(uint256 agentId, address token, uint256 amount)
        external
        onlyOwner
        agentExists(agentId)
        nonReentrant
    {
        require(treasuryBalances[token] >= amount, "SyntheticaNexus: Insufficient treasury balance");

        treasuryBalances[token] -= amount;
        agentResourceBalances[token][agentId] += amount;

        // If it's ETH, send it. For ERC20, it remains in the contract, tracked as 'allocated'.
        // The agent's controller would then trigger its module to use these funds.
        // If the funds are meant to be physically sent to the agent's controller, this logic needs adjustment.
        // Assuming 'allocated' means the contract holds it for the agent's operations.

        emit AgentResourcesAllocated(agentId, token, amount);
    }

    /**
     * @dev Reclaims unused or remaining resources from a DCA back into the treasury.
     *      Can be called by the agent owner, controller, or protocol owner.
     * @param agentId The ID of the DCA.
     * @param token The address of the token to reclaim (address(0) for ETH).
     * @param amount The amount of tokens to reclaim.
     */
    function reclaimAgentResources(uint256 agentId, address token, uint256 amount)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
        nonReentrant
    {
        require(agentResourceBalances[token][agentId] >= amount, "SyntheticaNexus: Insufficient agent resources");

        agentResourceBalances[token][agentId] -= amount;
        treasuryBalances[token] += amount;

        emit AgentResourcesReclaimed(agentId, token, amount);
    }

    /**
     * @dev Allows an agent owner/controller to distribute a percentage of their PIS-based rewards to a specified recipient.
     *      This could be for partners, module developers, or other collaborators.
     * @param agentId The ID of the DCA.
     * @param recipient The address to send the share to.
     * @param shareBps The share percentage in basis points (e.g., 1000 for 10%).
     */
    function distributeInfluenceShare(uint256 agentId, address recipient, uint256 shareBps)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
        nonReentrant
    {
        require(recipient != address(0), "SyntheticaNexus: Recipient cannot be zero address");
        require(shareBps > 0 && shareBps <= 10000, "SyntheticaNexus: Share must be between 1 and 10000 bps");

        // For simplicity, this function *claims* and then distributes.
        // In a real system, the `claimInfluenceRewards` might be separate,
        // and this function would operate on an *already earned* but *unclaimed* reward pool.
        _applyPISDecay(agentId);
        uint256 currentPIS = agents[agentId].influenceScore;
        require(currentPIS > 0, "SyntheticaNexus: Agent has no influence score to distribute");

        uint256 rewardAmount = currentPIS / 100; // Example: 1% of PIS as a distributable base
        if (rewardAmount == 0) {
            revert("SyntheticaNexus: No significant rewards to distribute");
        }

        uint256 distributedAmount = rewardAmount * shareBps / 10000;
        require(treasuryBalances[address(0)] >= distributedAmount, "SyntheticaNexus: Insufficient treasury balance for distribution");

        treasuryBalances[address(0)] -= distributedAmount;
        agents[agentId].influenceScore -= distributedAmount; // PIS is reduced by distributed amount

        (bool sent, ) = recipient.call{value: distributedAmount}("");
        require(sent, "SyntheticaNexus: Failed to send ETH share");

        emit InfluenceShareDistributed(agentId, recipient, shareBps, distributedAmount);
    }

    // --- V. Contextual Memory & On-chain Insights ---

    /**
     * @dev Allows DCAs to contribute hashes of verified on-chain data or insights to a shared index.
     *      This builds a decentralized knowledge graph.
     * @param agentId The ID of the DCA contributing the data.
     * @param dataHash A cryptographic hash (e.g., Keccak256) of the actual data, stored off-chain (e.g., IPFS).
     * @param dataDescription A brief description of the data.
     */
    function contributeContextualData(uint256 agentId, bytes32 dataHash, string calldata dataDescription)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
    {
        require(contextualKnowledgeGraph[dataHash].contributorAgentId == 0, "SyntheticaNexus: Data hash already contributed");

        contextualKnowledgeGraph[dataHash].contributorAgentId = agentId;
        contextualKnowledgeGraph[dataHash].description = dataDescription;
        contextualKnowledgeGraph[dataHash].verificationScore = 0;

        emit ContextualDataContributed(agentId, dataHash, dataDescription);
    }

    /**
     * @dev Retrieves metadata for a registered contextual data hash.
     * @param dataHash The hash of the data.
     * @return contributorAgentId The ID of the agent that contributed the data.
     * @return description A description of the data.
     * @return verificationScore The aggregated verification score for the data.
     */
    function queryContextualData(bytes32 dataHash)
        external
        view
        returns (uint256 contributorAgentId, string memory description, uint256 verificationScore)
    {
        require(contextualKnowledgeGraph[dataHash].contributorAgentId != 0, "SyntheticaNexus: Data hash not found");
        ContextualDataEntry storage entry = contextualKnowledgeGraph[dataHash];
        return (entry.contributorAgentId, entry.description, entry.verificationScore);
    }

    /**
     * @dev Enables high-PIS agents to attest to the validity of contributed contextual data,
     *      affecting its trustworthiness.
     * @param agentId The ID of the DCA performing the verification.
     * @param dataHash The hash of the data being verified.
     * @param isValid True if the agent verifies the data as valid, false otherwise.
     */
    function verifyContextualData(uint256 agentId, bytes32 dataHash, bool isValid)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
        nonReentrant
    {
        require(contextualKnowledgeGraph[dataHash].contributorAgentId != 0, "SyntheticaNexus: Data hash not found");
        require(agents[agentId].influenceScore >= MIN_PIS_FOR_VERIFICATION, "SyntheticaNexus: Agent PIS too low to verify");
        require(!contextualKnowledgeGraph[dataHash].verifiedByAgent[agentId], "SyntheticaNexus: Agent already verified this data");

        // Apply PIS decay before using agent's PIS for verification weight
        _applyPISDecay(agentId);

        ContextualDataEntry storage entry = contextualKnowledgeGraph[dataHash];
        entry.verifiedByAgent[agentId] = true;

        // Weight verification by the verifying agent's PIS
        uint256 verificationWeight = agents[agentId].influenceScore;

        if (isValid) {
            entry.verificationScore += verificationWeight;
        } else {
            if (entry.verificationScore > verificationWeight) {
                entry.verificationScore -= verificationWeight;
            } else {
                entry.verificationScore = 0;
            }
        }
        emit ContextualDataVerified(agentId, dataHash, isValid);
    }

    // --- VI. Governance & Protocol Evolution (Basic) ---

    /**
     * @dev Initiates a proposal for a protocol upgrade.
     *      Anyone can propose, but only high-PIS agents can vote.
     * @param upgradeHash A hash (e.g., Keccak256) representing the proposed upgrade code/parameters.
     * @param description A human-readable description of the upgrade.
     */
    function proposeProtocolUpgrade(bytes32 upgradeHash, string calldata description) external {
        require(upgradeProposals[upgradeHash].proposalHash == bytes32(0), "SyntheticaNexus: Proposal already exists");

        upgradeProposals[upgradeHash] = UpgradeProposal({
            proposalHash: upgradeHash,
            description: description,
            totalPISFor: 0,
            totalPISAgainst: 0,
            hasAgentVoted: new mapping(uint256 => bool), // Initialize mapping
            agentVoteSupport: new mapping(uint256 => bool), // Initialize mapping
            finalized: false,
            executed: false
        });

        emit ProtocolUpgradeProposed(upgradeHash, description);
    }

    /**
     * @dev Allows high-PIS agents (or their controllers) to cast votes on upgrade proposals.
     * @param agentId The ID of the DCA voting.
     * @param upgradeHash The hash of the proposal.
     * @param support True to vote for, false to vote against.
     */
    function voteOnProtocolUpgrade(uint256 agentId, bytes32 upgradeHash, bool support)
        external
        onlyAgentOwnerOrController(agentId)
        agentExists(agentId)
        nonReentrant
    {
        UpgradeProposal storage proposal = upgradeProposals[upgradeHash];
        require(proposal.proposalHash != bytes32(0), "SyntheticaNexus: Proposal does not exist");
        require(!proposal.finalized, "SyntheticaNexus: Proposal already finalized");
        require(!proposal.hasAgentVoted[agentId], "SyntheticaNexus: Agent already voted on this proposal");

        // Apply PIS decay before counting vote weight
        _applyPISDecay(agentId);
        uint256 voteWeight = agents[agentId].influenceScore;
        require(voteWeight > 0, "SyntheticaNexus: Agent has no influence score to vote");

        proposal.hasAgentVoted[agentId] = true;
        proposal.agentVoteSupport[agentId] = support;

        if (support) {
            proposal.totalPISFor += voteWeight;
        } else {
            proposal.totalPISAgainst += voteWeight;
        }

        emit ProtocolUpgradeVoted(agentId, upgradeHash, support);
    }

    // --- View Functions ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return agents[tokenId].metadataURI;
    }

    function getAgentOwner(uint256 agentId) public view agentExists(agentId) returns (address) {
        return agents[agentId].owner;
    }

    function getAgentController(uint256 agentId) public view agentExists(agentId) returns (address) {
        return agents[agentId].controller;
    }

    function getAgentIntent(uint256 agentId) public view agentExists(agentId) returns (uint256 intentType, bytes memory intentData) {
        return (agents[agentId].intentType, agents[agentId].intentData);
    }

    function getRegisteredModules(uint256 agentId) public view agentExists(agentId) returns (address[] memory) {
        return agents[agentId].registeredModules;
    }

    function getTreasuryBalance(address token) public view returns (uint256) {
        return treasuryBalances[token];
    }

    function getAgentResourceBalance(uint256 agentId, address token) public view agentExists(agentId) returns (uint256) {
        return agentResourceBalances[token][agentId];
    }

    function getTotalAgents() public view returns (uint256) {
        return _agentIds.current();
    }

    // Function to receive ETH, primarily for treasury deposits without specific token specified.
    receive() external payable {
        if (msg.sender == PIS_ORACLE_ADDRESS) {
            // Allow PIS oracle to deposit without explicit call to depositTreasury
            treasuryBalances[address(0)] += msg.value;
            emit TreasuryDeposited(address(0), msg.value);
        } else if (_msgSender() == owner()) {
             // Allow owner to deposit for treasury
            treasuryBalances[address(0)] += msg.value;
            emit TreasuryDeposited(address(0), msg.value);
        } else {
            revert("SyntheticaNexus: Only owner or PIS oracle can send ETH directly to contract for treasury");
        }
    }
}
```