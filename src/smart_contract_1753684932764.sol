Okay, this is an exciting challenge! Creating a sophisticated, non-duplicated smart contract with advanced concepts requires combining multiple trendy functionalities in a novel way.

I'll propose a concept called **"Aetheria Nexus: Decentralized Cognitive Agent Network"**.

**Core Idea:** A platform for registering, validating, and orchestrating decentralized AI/cognitive agents, complete with a reputation system, verifiable computation, and dynamic task management. It combines elements of:
1.  **Dynamic NFTs:** Agents are represented as NFTs, and their metadata (reputation, capabilities) evolves.
2.  **Verifiable Computation (ZK-inspired):** Agents can submit proofs of their computations or capabilities (simulated ZK proof hashes).
3.  **Reputation System:** A decentralized, on-chain reputation score for agents based on performance and verifiable task completion.
4.  **Decentralized Task Orchestration:** Users can propose tasks, and agents can be assigned/complete them, with on-chain verification and rewards.
5.  **DAO Governance (Light):** Community/stakeholder-driven updates or dispute resolution.
6.  **Oracle Integration (Simulated):** For external data or verification needed for agent operations.

---

## Aetheria Nexus: Decentralized Cognitive Agent Network

This contract establishes a decentralized network for autonomous cognitive agents (e.g., AI models, specialized bots). Each agent is represented by a unique NFT, and its on-chain identity includes dynamic attributes like verifiable capabilities, a performance-based reputation score, and a history of completed tasks. The system allows for the trustless orchestration of tasks between users and agents, with mechanisms for verifiable execution and dispute resolution.

**Contract Name:** `AetheriaNexus`

**Key Features & Concepts:**

*   **ERC-721 Compliant Agents:** Each agent is an NFT, providing unique ownership and transferability.
*   **Dynamic Metadata:** Agent reputation and verified capabilities are on-chain, influencing their potential and value.
*   **ZK-Proof Hashing (Simulated):** Agents declare capabilities and submit cryptographic proof hashes (representing ZK-SNARKs or STARKs) to verify their computations without revealing underlying data. An oracle/governance verifies these hashes.
*   **Reputation Mechanics:** Agents gain or lose reputation based on task completion, user feedback, and dispute outcomes. Reputation can be staked.
*   **Decentralized Task Marketplace:** Users propose tasks with associated rewards. Agents can claim/be assigned tasks, submit verifiable completion proofs, and receive rewards.
*   **Dispute Resolution:** Mechanisms for users to dispute task outcomes or reputation reports, resolved via a (simulated) governance or oracle process.
*   **Permissioned Oracle:** A trusted entity (or multi-sig) provides external data or validates off-chain proofs.
*   **Simple Governance:** A basic proposal and voting system for critical updates or rule changes.

---

### Outline and Function Summary

**I. Core Infrastructure & ERC-721 (Agent NFTs)**
*   `constructor()`: Initializes the contract, sets the deployer as owner.
*   `supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)`: ERC-165 support.
*   `balanceOf(address owner) public view override returns (uint256)`: Returns agent count for an address.
*   `ownerOf(uint256 tokenId) public view override returns (address)`: Returns owner of an agent NFT.
*   `approve(address to, uint256 tokenId) public override`: Approves an address to manage an agent.
*   `getApproved(uint256 tokenId) public view override returns (address)`: Gets approved address.
*   `setApprovalForAll(address operator, bool approved) public override`: Sets operator for all agents.
*   `isApprovedForAll(address owner, address operator) public view override returns (bool)`: Checks operator approval.
*   `transferFrom(address from, address to, uint256 tokenId) public override`: Transfers agent ownership.
*   `safeTransferFrom(address from, address to, uint256 tokenId) public override`: Safe transfer.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override`: Safe transfer with data.

**II. Agent Lifecycle Management**
*   `registerCognitiveAgent(string calldata _name, string calldata _ipfsMetadataURI) external returns (uint256)`: Mints a new Agent NFT, registers it in the network with initial metadata.
*   `updateAgentMetadata(uint256 _agentId, string calldata _newIpfsMetadataURI) external`: Allows agent owner to update its off-chain metadata URI.
*   `deactivateAgent(uint256 _agentId) external`: Temporarily sets an agent's status to inactive (cannot participate in tasks).
*   `reactivateAgent(uint256 _agentId) external`: Reactivates a previously deactivated agent.
*   `getAgentDetails(uint256 _agentId) public view returns (Agent memory)`: Retrieves all on-chain details of a registered agent.
*   `getTotalRegisteredAgents() public view returns (uint256)`: Returns the total number of agents registered.

**III. Verifiable Capabilities & Proofs (ZK-inspired)**
*   `declareAgentCapability(uint256 _agentId, string calldata _capabilityDescription) external`: Agent owner declares a new capability for their agent.
*   `submitCapabilityProofHash(uint256 _agentId, uint256 _capabilityIndex, bytes32 _proofHash) external`: Agent owner submits a cryptographic hash (representing a ZK-proof) for a declared capability.
*   `verifyAgentCapability(uint256 _agentId, uint256 _capabilityIndex, address _verifier) external onlyOracle`: An authorized oracle or governance verifies a submitted capability proof hash.
*   `revokeAgentCapability(uint256 _agentId, uint256 _capabilityIndex) external`: Revokes a previously declared or verified capability.
*   `getAgentCapabilities(uint256 _agentId) public view returns (Capability[] memory)`: Retrieves all declared capabilities for an agent.

**IV. Reputation System**
*   `submitAgentPerformanceReport(uint256 _agentId, int256 _scoreImpact, string calldata _reason) external`: Allows a user (e.g., task proposer) to submit a performance report impacting an agent's reputation.
*   `disputePerformanceReport(uint256 _agentId, uint256 _reportIndex, string calldata _disputeReason) external`: Agent owner disputes a negative performance report.
*   `resolveReputationDispute(uint256 _agentId, uint256 _reportIndex, bool _isValidReport, string calldata _resolutionDetails) external onlyOracle`: An authorized oracle or governance resolves a reputation dispute, adjusting the score as necessary.
*   `getAgentReputationScore(uint256 _agentId) public view returns (int256)`: Returns the current aggregate reputation score of an agent.
*   `getAgentReputationHistory(uint256 _agentId) public view returns (ReputationReport[] memory)`: Retrieves the history of reputation adjustments for an agent.

**V. Decentralized Task Orchestration**
*   `proposeCognitiveTask(string calldata _taskDescription, uint256 _rewardAmount, uint256 _requiredReputation) external payable returns (uint256)`: Proposes a new task, attaching an ETH reward and specifying minimum agent reputation.
*   `assignTaskToAgent(uint256 _taskId, uint256 _agentId) external`: Task proposer assigns a task to a specific agent meeting reputation criteria.
*   `submitTaskCompletionProof(uint256 _taskId, uint256 _agentId, bytes32 _completionProofHash) external`: Agent submits a cryptographic hash as proof of task completion.
*   `verifyTaskCompletion(uint256 _taskId, uint256 _agentId, bool _isSuccessful, string calldata _verificationDetails) external onlyOracle`: An authorized oracle verifies the task completion proof and marks the task as successful or failed.
*   `rewardAgentForTask(uint256 _taskId) external`: Transfers the reward to the agent after successful task verification.
*   `rateCompletedTask(uint256 _taskId, uint256 _rating) external`: Task proposer rates the agent's performance on a completed task (e.g., 1-5 stars, influencing reputation).
*   `getTaskDetails(uint256 _taskId) public view returns (Task memory)`: Retrieves all details of a specific task.

**VI. Governance & Administration**
*   `setOracleAddress(address _newOracle) external onlyOwner`: Sets the address for the authorized oracle.
*   `submitGovernanceProposal(string calldata _description, bytes calldata _callData) external`: Submits a proposal for system changes (e.g., updating parameters, resolving major disputes).
*   `voteOnProposal(uint256 _proposalId, bool _for) external`: Allows participants (e.g., agent owners, staked addresses) to vote on a proposal.
*   `executeProposal(uint256 _proposalId) external`: Executes a passed governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For potential on-chain SVG or metadata generation

/**
 * @title Aetheria Nexus: Decentralized Cognitive Agent Network
 * @author Your Name/Pseudonym
 * @notice This contract establishes a decentralized network for autonomous cognitive agents.
 *         Each agent is a dynamic NFT, with on-chain verifiable capabilities, a reputation score,
 *         and participation in a task orchestration marketplace. It integrates simulated ZK-proofs
 *         for verifiable computation and a basic governance/oracle system for trust.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & ERC-721 (Agent NFTs)
 *    - constructor(): Initializes the contract, sets the deployer as owner.
 *    - supportsInterface(bytes4 interfaceId): ERC-165 support.
 *    - balanceOf(address owner): Returns agent count for an address.
 *    - ownerOf(uint256 tokenId): Returns owner of an agent NFT.
 *    - approve(address to, uint256 tokenId): Approves an address to manage an agent.
 *    - getApproved(uint256 tokenId): Gets approved address.
 *    - setApprovalForAll(address operator, bool approved): Sets operator for all agents.
 *    - isApprovedForAll(address owner, address operator): Checks operator approval.
 *    - transferFrom(address from, address to, uint256 tokenId): Transfers agent ownership.
 *    - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
 *    - safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Safe transfer with data.
 *
 * II. Agent Lifecycle Management
 *    - registerCognitiveAgent(string calldata _name, string calldata _ipfsMetadataURI): Mints a new Agent NFT, registers it.
 *    - updateAgentMetadata(uint256 _agentId, string calldata _newIpfsMetadataURI): Agent owner updates off-chain metadata URI.
 *    - deactivateAgent(uint256 _agentId): Temporarily sets agent's status to inactive.
 *    - reactivateAgent(uint256 _agentId): Reactivates a deactivated agent.
 *    - getAgentDetails(uint256 _agentId): Retrieves all on-chain details of a registered agent.
 *    - getTotalRegisteredAgents(): Returns total number of agents registered.
 *
 * III. Verifiable Capabilities & Proofs (ZK-inspired)
 *    - declareAgentCapability(uint256 _agentId, string calldata _capabilityDescription): Agent declares a new capability.
 *    - submitCapabilityProofHash(uint256 _agentId, uint256 _capabilityIndex, bytes32 _proofHash): Agent submits a cryptographic hash for a declared capability.
 *    - verifyAgentCapability(uint256 _agentId, uint256 _capabilityIndex, address _verifier): Authorized oracle/governance verifies a proof hash.
 *    - revokeAgentCapability(uint256 _agentId, uint256 _capabilityIndex): Revokes a capability.
 *    - getAgentCapabilities(uint256 _agentId): Retrieves all declared capabilities for an agent.
 *
 * IV. Reputation System
 *    - submitAgentPerformanceReport(uint256 _agentId, int256 _scoreImpact, string calldata _reason): User submits a performance report.
 *    - disputePerformanceReport(uint256 _agentId, uint256 _reportIndex, string calldata _disputeReason): Agent owner disputes a report.
 *    - resolveReputationDispute(uint256 _agentId, uint256 _reportIndex, bool _isValidReport, string calldata _resolutionDetails): Oracle/governance resolves a dispute.
 *    - getAgentReputationScore(uint256 _agentId): Returns current aggregate reputation score.
 *    - getAgentReputationHistory(uint256 _agentId): Retrieves history of reputation adjustments.
 *
 * V. Decentralized Task Orchestration
 *    - proposeCognitiveTask(string calldata _taskDescription, uint256 _rewardAmount, uint256 _requiredReputation): Proposes a new task with ETH reward.
 *    - assignTaskToAgent(uint256 _taskId, uint256 _agentId): Task proposer assigns task to an agent.
 *    - submitTaskCompletionProof(uint256 _taskId, uint256 _agentId, bytes32 _completionProofHash): Agent submits completion proof hash.
 *    - verifyTaskCompletion(uint256 _taskId, uint256 _agentId, bool _isSuccessful, string calldata _verificationDetails): Oracle verifies task completion.
 *    - rewardAgentForTask(uint256 _taskId): Transfers reward to agent after verification.
 *    - rateCompletedTask(uint256 _taskId, uint256 _rating): Task proposer rates agent's performance (1-5 stars).
 *    - getTaskDetails(uint256 _taskId): Retrieves details of a specific task.
 *
 * VI. Governance & Administration
 *    - setOracleAddress(address _newOracle): Sets the authorized oracle address.
 *    - submitGovernanceProposal(string calldata _description, bytes calldata _callData): Submits a proposal for system changes.
 *    - voteOnProposal(uint256 _proposalId, bool _for): Allows participants to vote on a proposal.
 *    - executeProposal(uint256 _proposalId): Executes a passed governance proposal.
 */
contract AetheriaNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    address public oracleAddress; // Address authorized to perform oracle tasks (e.g., ZK proof verification, task verification)

    enum AgentState { Active, Inactive, Deactivated }
    enum TaskStatus { Proposed, Assigned, CompletionPending, Completed, Failed, Disputed }
    enum ProposalState { Active, Succeeded, Failed, Executed }

    struct Agent {
        uint256 agentId;
        address owner;
        string name;
        string ipfsMetadataURI; // Link to detailed metadata, image, etc.
        AgentState state;
        int256 reputationScore;
        uint256 registeredAt;
    }

    struct Capability {
        string description; // e.g., "Image Recognition", "Natural Language Processing"
        bytes32 proofHash;   // Hash of the ZK-proof output (e.g., proof.publicInputsHash)
        address verifiedBy;  // Address of the oracle/governance that verified it
        uint256 verifiedAt;
        bool isVerified;     // True if the proof hash has been verified by an oracle
    }

    struct ReputationReport {
        address reporter;
        int256 scoreImpact; // Positive for good, negative for bad
        string reason;
        uint256 timestamp;
        bool isDisputed;
        bool resolved;
    }

    struct Task {
        uint256 taskId;
        address proposer;
        uint256 assignedAgentId;
        string description;
        uint256 rewardAmount; // in wei
        uint256 requiredReputation;
        bytes32 completionProofHash; // Hash representing proof of task completion
        TaskStatus status;
        uint256 proposedAt;
        uint256 assignedAt;
        uint256 completedAt;
        uint256 verifiedAt;
        uint256 userRating; // 1-5 stars for completed tasks
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData;       // Encoded function call to execute if proposal passes
        uint255 votesFor;
        uint255 votesAgainst;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        ProposalState state;
        mapping(address => bool) hasVoted; // Check if an address has voted
    }

    // Mappings for storing contract data
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => Capability[]) public agentCapabilities; // agentId => list of capabilities
    mapping(uint256 => ReputationReport[]) public agentReputationHistory; // agentId => list of reports
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, string ipfsMetadataURI, uint256 timestamp);
    event AgentMetadataUpdated(uint256 indexed agentId, string newIpfsMetadataURI);
    event AgentStateChanged(uint256 indexed agentId, AgentState newState);
    event CapabilityDeclared(uint256 indexed agentId, uint256 capabilityIndex, string description);
    event CapabilityProofSubmitted(uint256 indexed agentId, uint256 capabilityIndex, bytes32 proofHash);
    event CapabilityVerified(uint256 indexed agentId, uint256 capabilityIndex, address indexed verifier);
    event CapabilityRevoked(uint256 indexed agentId, uint256 capabilityIndex);
    event ReputationReportSubmitted(uint256 indexed agentId, address indexed reporter, int256 scoreImpact, uint256 reportIndex);
    event ReputationDisputeInitiated(uint256 indexed agentId, uint256 indexed reportIndex, string reason);
    event ReputationDisputeResolved(uint256 indexed agentId, uint256 indexed reportIndex, bool isValidReport, int256 newReputationScore);
    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, uint256 requiredReputation);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed agentId);
    event TaskCompletionProofSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 proofHash);
    event TaskCompletionVerified(uint256 indexed taskId, uint256 indexed agentId, bool success);
    event TaskRewarded(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardAmount);
    event TaskRated(uint256 indexed taskId, uint256 indexed agentId, uint256 rating);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner == msg.sender, "AetheriaNexus: Not agent owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetheriaNexus: Only authorized oracle can call this function");
        _;
    }

    modifier onlyProposer(uint256 _taskId) {
        require(tasks[_taskId].proposer == msg.sender, "AetheriaNexus: Only task proposer can call this function");
        _;
    }

    // Constructor
    constructor(address _oracleAddress) ERC721("AetheriaNexusCognitiveAgent", "AXCA") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "AetheriaNexus: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    // --- I. Core Infrastructure & ERC-721 (Agent NFTs) ---
    // ERC721 functions are inherited directly from OpenZeppelin, no need to re-implement

    // --- II. Agent Lifecycle Management ---

    /**
     * @notice Registers a new cognitive agent as an NFT.
     * @param _name The name of the agent.
     * @param _ipfsMetadataURI A URI pointing to the agent's off-chain metadata (e.g., IPFS).
     * @return The ID of the newly registered agent.
     */
    function registerCognitiveAgent(string calldata _name, string calldata _ipfsMetadataURI)
        external
        returns (uint256)
    {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        Agent storage newAgent = agents[newAgentId];
        newAgent.agentId = newAgentId;
        newAgent.owner = msg.sender;
        newAgent.name = _name;
        newAgent.ipfsMetadataURI = _ipfsMetadataURI;
        newAgent.state = AgentState.Active;
        newAgent.reputationScore = 0; // Initial reputation
        newAgent.registeredAt = block.timestamp;

        _safeMint(msg.sender, newAgentId);

        emit AgentRegistered(newAgentId, msg.sender, _name, _ipfsMetadataURI, block.timestamp);
        return newAgentId;
    }

    /**
     * @notice Allows the agent owner to update its off-chain metadata URI.
     * @param _agentId The ID of the agent.
     * @param _newIpfsMetadataURI The new URI for the agent's metadata.
     */
    function updateAgentMetadata(uint256 _agentId, string calldata _newIpfsMetadataURI)
        external
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].state != AgentState.Deactivated, "Agent is deactivated");
        agents[_agentId].ipfsMetadataURI = _newIpfsMetadataURI;
        emit AgentMetadataUpdated(_agentId, _newIpfsMetadataURI);
    }

    /**
     * @notice Temporarily deactivates an agent, preventing it from participating in new tasks.
     * @param _agentId The ID of the agent to deactivate.
     */
    function deactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        require(agents[_agentId].state == AgentState.Active, "Agent must be active to deactivate");
        agents[_agentId].state = AgentState.Deactivated;
        emit AgentStateChanged(_agentId, AgentState.Deactivated);
    }

    /**
     * @notice Reactivates a previously deactivated agent.
     * @param _agentId The ID of the agent to reactivate.
     */
    function reactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        require(agents[_agentId].state == AgentState.Deactivated, "Agent must be deactivated to reactivate");
        agents[_agentId].state = AgentState.Active;
        emit AgentStateChanged(_agentId, AgentState.Active);
    }

    /**
     * @notice Retrieves all on-chain details of a registered agent.
     * @param _agentId The ID of the agent.
     * @return The Agent struct containing all its details.
     */
    function getAgentDetails(uint256 _agentId) public view returns (Agent memory) {
        return agents[_agentId];
    }

    /**
     * @notice Returns the total number of agents registered in the network.
     * @return The total count of registered agents.
     */
    function getTotalRegisteredAgents() public view returns (uint256) {
        return _agentIds.current();
    }

    // --- III. Verifiable Capabilities & Proofs (ZK-inspired) ---

    /**
     * @notice Agent owner declares a new capability for their agent.
     * @param _agentId The ID of the agent.
     * @param _capabilityDescription A description of the capability (e.g., "Image Classification v2.1").
     */
    function declareAgentCapability(uint256 _agentId, string calldata _capabilityDescription)
        external
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].state == AgentState.Active, "Agent must be active to declare capabilities");
        agentCapabilities[_agentId].push(
            Capability({
                description: _capabilityDescription,
                proofHash: 0x0, // Initial empty hash
                verifiedBy: address(0),
                verifiedAt: 0,
                isVerified: false
            })
        );
        emit CapabilityDeclared(_agentId, agentCapabilities[_agentId].length - 1, _capabilityDescription);
    }

    /**
     * @notice Agent owner submits a cryptographic hash (representing a ZK-proof) for a declared capability.
     *         This hash would typically be generated off-chain after running the agent's computation with a ZK-SNARK circuit.
     * @param _agentId The ID of the agent.
     * @param _capabilityIndex The index of the capability in the agent's capability array.
     * @param _proofHash The hash of the ZK-proof's public inputs/output, to be verified by an oracle.
     */
    function submitCapabilityProofHash(uint256 _agentId, uint256 _capabilityIndex, bytes32 _proofHash)
        external
        onlyAgentOwner(_agentId)
    {
        require(_capabilityIndex < agentCapabilities[_agentId].length, "AetheriaNexus: Invalid capability index");
        agentCapabilities[_agentId][_capabilityIndex].proofHash = _proofHash;
        agentCapabilities[_agentId][_capabilityIndex].isVerified = false; // Reset verification status
        emit CapabilityProofSubmitted(_agentId, _capabilityIndex, _proofHash);
    }

    /**
     * @notice An authorized oracle or governance verifies a submitted capability proof hash.
     *         In a real ZK system, this would involve a complex on-chain verification function,
     *         but here it's simulated by an oracle confirming the proof.
     * @param _agentId The ID of the agent.
     * @param _capabilityIndex The index of the capability to verify.
     * @param _verifier The address of the entity performing the verification (typically the oracle).
     */
    function verifyAgentCapability(uint256 _agentId, uint256 _capabilityIndex, address _verifier)
        external
        onlyOracle // Or could be a governance vote/multi-sig
    {
        require(_capabilityIndex < agentCapabilities[_agentId].length, "AetheriaNexus: Invalid capability index");
        require(agentCapabilities[_agentId][_capabilityIndex].proofHash != 0x0, "AetheriaNexus: No proof hash submitted");

        agentCapabilities[_agentId][_capabilityIndex].isVerified = true;
        agentCapabilities[_agentId][_capabilityIndex].verifiedBy = _verifier;
        agentCapabilities[_agentId][_capabilityIndex].verifiedAt = block.timestamp;

        emit CapabilityVerified(_agentId, _capabilityIndex, _verifier);
    }

    /**
     * @notice Revokes a previously declared or verified capability for an agent.
     * @param _agentId The ID of the agent.
     * @param _capabilityIndex The index of the capability to revoke.
     */
    function revokeAgentCapability(uint256 _agentId, uint256 _capabilityIndex)
        external
        onlyAgentOwner(_agentId)
    {
        require(_capabilityIndex < agentCapabilities[_agentId].length, "AetheriaNexus: Invalid capability index");
        // Simple removal: copy last element to current position and pop. Order doesn't strictly matter for capabilities.
        if (_capabilityIndex != agentCapabilities[_agentId].length - 1) {
            agentCapabilities[_agentId][_capabilityIndex] = agentCapabilities[_agentId][agentCapabilities[_agentId].length - 1];
        }
        agentCapabilities[_agentId].pop();
        emit CapabilityRevoked(_agentId, _capabilityIndex);
    }

    /**
     * @notice Retrieves all declared capabilities for an agent.
     * @param _agentId The ID of the agent.
     * @return An array of Capability structs.
     */
    function getAgentCapabilities(uint256 _agentId) public view returns (Capability[] memory) {
        return agentCapabilities[_agentId];
    }

    // --- IV. Reputation System ---

    /**
     * @notice Allows a user (e.g., task proposer) to submit a performance report impacting an agent's reputation.
     *         Positive scoreImpact for good performance, negative for bad.
     * @param _agentId The ID of the agent being reported on.
     * @param _scoreImpact The integer impact on the reputation score (e.g., +100, -50).
     * @param _reason A description for the report.
     */
    function submitAgentPerformanceReport(uint256 _agentId, int256 _scoreImpact, string calldata _reason)
        external
    {
        require(agents[_agentId].registeredAt != 0, "AetheriaNexus: Agent does not exist");
        ReputationReport memory newReport = ReputationReport({
            reporter: msg.sender,
            scoreImpact: _scoreImpact,
            reason: _reason,
            timestamp: block.timestamp,
            isDisputed: false,
            resolved: false
        });
        agentReputationHistory[_agentId].push(newReport);

        // Directly apply score unless it's a strongly negative report (e.g., more than -100) that might need dispute
        // For simplicity, we apply directly and allow dispute. More complex systems might hold scores in escrow.
        agents[_agentId].reputationScore += _scoreImpact;

        emit ReputationReportSubmitted(_agentId, msg.sender, _scoreImpact, agentReputationHistory[_agentId].length - 1);
    }

    /**
     * @notice Allows an agent owner to dispute a performance report.
     * @param _agentId The ID of the agent.
     * @param _reportIndex The index of the report in the agent's history to dispute.
     * @param _disputeReason The reason for disputing the report.
     */
    function disputePerformanceReport(uint256 _agentId, uint256 _reportIndex, string calldata _disputeReason)
        external
        onlyAgentOwner(_agentId)
    {
        require(_reportIndex < agentReputationHistory[_agentId].length, "AetheriaNexus: Invalid report index");
        ReputationReport storage report = agentReputationHistory[_agentId][_reportIndex];
        require(!report.isDisputed, "AetheriaNexus: Report already disputed");
        require(!report.resolved, "AetheriaNexus: Report already resolved");

        report.isDisputed = true;
        // Revert the initial score impact until resolved
        agents[_agentId].reputationScore -= report.scoreImpact;

        emit ReputationDisputeInitiated(_agentId, _reportIndex, _disputeReason);
    }

    /**
     * @notice An authorized oracle or governance resolves a reputation dispute.
     *         If _isValidReport is true, the original score impact is reapplied. If false, it's dismissed.
     * @param _agentId The ID of the agent.
     * @param _reportIndex The index of the disputed report.
     * @param _isValidReport True if the original report was valid, false if invalid.
     * @param _resolutionDetails Details of the resolution.
     */
    function resolveReputationDispute(uint256 _agentId, uint256 _reportIndex, bool _isValidReport, string calldata _resolutionDetails)
        external
        onlyOracle // Can be expanded to governance voting
    {
        require(_reportIndex < agentReputationHistory[_agentId].length, "AetheriaNexus: Invalid report index");
        ReputationReport storage report = agentReputationHistory[_agentId][_reportIndex];
        require(report.isDisputed, "AetheriaNexus: Report is not disputed");
        require(!report.resolved, "AetheriaNexus: Report already resolved");

        report.resolved = true;
        if (_isValidReport) {
            agents[_agentId].reputationScore += report.scoreImpact; // Reapply the original impact
        } else {
            // If the report was invalid, the score impact remains reverted (from dispute action)
        }

        emit ReputationDisputeResolved(_agentId, _reportIndex, _isValidReport, agents[_agentId].reputationScore);
    }

    /**
     * @notice Returns the current aggregate reputation score of an agent.
     * @param _agentId The ID of the agent.
     * @return The agent's current reputation score.
     */
    function getAgentReputationScore(uint256 _agentId) public view returns (int256) {
        return agents[_agentId].reputationScore;
    }

    /**
     * @notice Retrieves the history of reputation adjustments for an agent.
     * @param _agentId The ID of the agent.
     * @return An array of ReputationReport structs.
     */
    function getAgentReputationHistory(uint256 _agentId) public view returns (ReputationReport[] memory) {
        return agentReputationHistory[_agentId];
    }

    // --- V. Decentralized Task Orchestration ---

    /**
     * @notice Proposes a new cognitive task with an associated ETH reward.
     * @param _taskDescription A detailed description of the task.
     * @param _rewardAmount The ETH reward for completing the task (in wei).
     * @param _requiredReputation The minimum reputation score an agent must have to be assigned this task.
     * @return The ID of the newly proposed task.
     */
    function proposeCognitiveTask(string calldata _taskDescription, uint256 _rewardAmount, uint256 _requiredReputation)
        external
        payable
        returns (uint256)
    {
        require(msg.value == _rewardAmount, "AetheriaNexus: ETH sent must match reward amount");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            taskId: newTaskId,
            proposer: msg.sender,
            assignedAgentId: 0, // No agent assigned initially
            description: _taskDescription,
            rewardAmount: _rewardAmount,
            requiredReputation: _requiredReputation,
            completionProofHash: 0x0,
            status: TaskStatus.Proposed,
            proposedAt: block.timestamp,
            assignedAt: 0,
            completedAt: 0,
            verifiedAt: 0,
            userRating: 0
        });

        emit TaskProposed(newTaskId, msg.sender, _rewardAmount, _requiredReputation);
        return newTaskId;
    }

    /**
     * @notice Task proposer assigns a proposed task to a specific agent.
     * @param _taskId The ID of the task to assign.
     * @param _agentId The ID of the agent to assign the task to.
     */
    function assignTaskToAgent(uint256 _taskId, uint256 _agentId)
        external
        onlyProposer(_taskId)
    {
        require(tasks[_taskId].status == TaskStatus.Proposed, "AetheriaNexus: Task is not in Proposed status");
        require(agents[_agentId].state == AgentState.Active, "AetheriaNexus: Agent must be active");
        require(agents[_agentId].reputationScore >= int256(tasks[_taskId].requiredReputation), "AetheriaNexus: Agent does not meet required reputation");

        tasks[_taskId].assignedAgentId = _agentId;
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignedAt = block.timestamp;

        emit TaskAssigned(_taskId, _agentId);
    }

    /**
     * @notice Agent submits a cryptographic hash as proof of task completion.
     *         This hash might represent a verifiable output or a ZK-proof of computation.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent completing the task.
     * @param _completionProofHash The hash representing the proof of completion.
     */
    function submitTaskCompletionProof(uint256 _taskId, uint256 _agentId, bytes32 _completionProofHash)
        external
        onlyAgentOwner(_agentId)
    {
        require(tasks[_taskId].assignedAgentId == _agentId, "AetheriaNexus: Task not assigned to this agent");
        require(tasks[_taskId].status == TaskStatus.Assigned, "AetheriaNexus: Task is not in Assigned status");
        require(_completionProofHash != 0x0, "AetheriaNexus: Completion proof hash cannot be zero");

        tasks[_taskId].completionProofHash = _completionProofHash;
        tasks[_taskId].status = TaskStatus.CompletionPending;
        tasks[_taskId].completedAt = block.timestamp;

        emit TaskCompletionProofSubmitted(_taskId, _agentId, _completionProofHash);
    }

    /**
     * @notice An authorized oracle verifies the task completion proof and marks the task as successful or failed.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent who submitted the proof.
     * @param _isSuccessful True if the task was successfully completed, false otherwise.
     * @param _verificationDetails Details of the verification outcome.
     */
    function verifyTaskCompletion(uint256 _taskId, uint256 _agentId, bool _isSuccessful, string calldata _verificationDetails)
        external
        onlyOracle
    {
        require(tasks[_taskId].assignedAgentId == _agentId, "AetheriaNexus: Task not assigned to this agent");
        require(tasks[_taskId].status == TaskStatus.CompletionPending, "AetheriaNexus: Task not awaiting completion verification");
        require(tasks[_taskId].completionProofHash != 0x0, "AetheriaNexus: No completion proof submitted yet");

        tasks[_taskId].verifiedAt = block.timestamp;

        if (_isSuccessful) {
            tasks[_taskId].status = TaskStatus.Completed;
        } else {
            tasks[_taskId].status = TaskStatus.Failed;
            // Optionally, penalize agent reputation or return funds to proposer
            // For simplicity, we just mark as failed. A robust system might trigger dispute.
        }

        emit TaskCompletionVerified(_taskId, _agentId, _isSuccessful);
    }

    /**
     * @notice Transfers the reward to the agent after successful task verification.
     *         Can only be called by the task proposer once the task is marked as Completed.
     * @param _taskId The ID of the task.
     */
    function rewardAgentForTask(uint256 _taskId) external onlyProposer(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Completed, "AetheriaNexus: Task not marked as Completed");
        require(tasks[_taskId].rewardAmount > 0, "AetheriaNexus: No reward outstanding or already claimed");

        uint256 reward = tasks[_taskId].rewardAmount;
        uint256 agentId = tasks[_taskId].assignedAgentId;
        address agentOwner = agents[agentId].owner;

        tasks[_taskId].rewardAmount = 0; // Prevent double claim

        (bool success, ) = payable(agentOwner).call{value: reward}("");
        require(success, "AetheriaNexus: Failed to send reward to agent owner");

        // Reward positive reputation for successful task completion
        agents[agentId].reputationScore += 10; // Example static reward
        emit ReputationReportSubmitted(agentId, address(this), 10, agentReputationHistory[agentId].length);
        agentReputationHistory[agentId].push(
            ReputationReport({
                reporter: address(this),
                scoreImpact: 10,
                reason: "Task completed successfully",
                timestamp: block.timestamp,
                isDisputed: false,
                resolved: true
            })
        );


        emit TaskRewarded(_taskId, agentId, reward);
    }

    /**
     * @notice Task proposer rates the agent's performance on a completed task.
     *         This rating directly influences the agent's reputation.
     * @param _taskId The ID of the task.
     * @param _rating The rating (e.g., 1 to 5 stars).
     */
    function rateCompletedTask(uint256 _taskId, uint256 _rating) external onlyProposer(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Completed, "AetheriaNexus: Task not completed");
        require(_rating >= 1 && _rating <= 5, "AetheriaNexus: Rating must be between 1 and 5");
        require(tasks[_taskId].userRating == 0, "AetheriaNexus: Task already rated");

        tasks[_taskId].userRating = _rating;

        // Adjust agent reputation based on rating
        uint256 agentId = tasks[_taskId].assignedAgentId;
        int256 scoreChange = 0;
        string memory reason = "Task rating: ";
        if (_rating == 5) {
            scoreChange = 25; reason = string.concat(reason, "5 stars - Excellent");
        } else if (_rating == 4) {
            scoreChange = 10; reason = string.concat(reason, "4 stars - Good");
        } else if (_rating == 3) {
            scoreChange = 0; reason = string.concat(reason, "3 stars - Neutral");
        } else if (_rating == 2) {
            scoreChange = -10; reason = string.concat(reason, "2 stars - Poor");
        } else if (_rating == 1) {
            scoreChange = -25; reason = string.concat(reason, "1 star - Very Poor");
        }
        
        agents[agentId].reputationScore += scoreChange;
        emit ReputationReportSubmitted(agentId, msg.sender, scoreChange, agentReputationHistory[agentId].length);
        agentReputationHistory[agentId].push(
            ReputationReport({
                reporter: msg.sender,
                scoreImpact: scoreChange,
                reason: reason,
                timestamp: block.timestamp,
                isDisputed: false,
                resolved: true
            })
        );

        emit TaskRated(_taskId, agentId, _rating);
    }

    /**
     * @notice Retrieves all details of a specific task.
     * @param _taskId The ID of the task.
     * @return The Task struct containing all its details.
     */
    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    // --- VI. Governance & Administration ---

    /**
     * @notice Sets the address for the authorized oracle. Only callable by the contract owner.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AetheriaNexus: Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /**
     * @notice Submits a proposal for system changes (e.g., updating parameters, resolving major disputes).
     *         For simplicity, voting power is 1 vote per call, but could be weighted by agent count or staked tokens.
     * @param _description A description of the proposal.
     * @param _callData The encoded function call to execute if the proposal passes.
     */
    function submitGovernanceProposal(string calldata _description, bytes calldata _callData) external {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + 7 days, // Example: 7-day voting period
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize inner mapping
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _description);
    }

    /**
     * @notice Allows participants (e.g., agent owners, staked addresses) to vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "AetheriaNexus: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "AetheriaNexus: Proposal is not active for voting");
        require(block.timestamp < proposal.votingPeriodEnd, "AetheriaNexus: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetheriaNexus: You have already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, _for);
    }

    /**
     * @notice Executes a passed governance proposal. Callable by anyone after the voting period ends and if conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "AetheriaNexus: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "AetheriaNexus: Proposal is not active");
        require(block.timestamp >= proposal.votingPeriodEnd, "AetheriaNexus: Voting period has not ended yet");

        // Define success condition (e.g., simple majority)
        bool passed = proposal.votesFor > proposal.votesAgainst; // Simple majority
        // Could add quorum: require(proposal.votesFor + proposal.votesAgainst >= minVoteCount, "AetheriaNexus: Quorum not met");

        if (passed) {
            proposal.state = ProposalState.Succeeded;
            // Execute the payload (e.g., call a function on this contract or another)
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "AetheriaNexus: Proposal execution failed");
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    // Fallback and Receive functions if needed for direct ETH transfers (not explicitly used by functions above)
    receive() external payable {}
    fallback() external payable {}
}
```