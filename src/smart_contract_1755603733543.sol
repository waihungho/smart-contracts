The following smart contract, `AetherweaveAI`, introduces a novel concept: **Decentralized AI Agents as Dynamic NFTs that can evolve, perform services, and even "breed" based on verifiable on-chain performance attestations and a DAO-governed arbitration system.**

It aims to provide a framework for a future where AI models or agents can have on-chain representations, track their reputation, and offer their computational services in a transparent, decentralized manner.

---

## AetherweaveAI: Outline & Function Summary

**Core Concept:** AetherweaveAI is a platform for creating, managing, and utilizing AI Agents represented as dynamic Non-Fungible Tokens (NFTs). These agents can be listed for services, accrue performance reputation through verifiable attestations, evolve based on their history, and even be combined ("bred") to create new, potentially superior agents. A decentralized autonomous organization (DAO) governs core parameters and handles disputes.

**Key Advanced Concepts:**
*   **Dynamic NFTs:** Agents evolve (skill updates) and are generated via "breeding," changing their on-chain characteristics.
*   **Verifiable Computation Attestation (Simplified):** While full ZK-ML is complex for Solidity, the contract includes mechanisms for on-chain attestation of off-chain AI performance, with a dispute resolution system. `bytes` payloads allow for future integration of cryptographic proofs.
*   **Skill-Based Matching & Reputation:** Agents are tagged with skills, and their performance is tracked, enabling reputation-based selection for services.
*   **On-Chain "Genetics" (Abstracted):** The `breedAgents` function allows for a novel combination of existing agents to create new ones, mimicking genetic algorithms.
*   **Decentralized Arbitration:** Disputes over performance attestations and service completions are resolved via a DAO vote or a designated oracle.
*   **Service Marketplace:** Enables owners to list agents for specific tasks and users to request services, with escrowed payments.

---

### Function Summary (25 Functions):

**I. Core Agent Management (ERC721 & Agent Lifecycle)**
1.  `constructor(string _name, string _symbol)`: Initializes the ERC721 contract with a name and symbol.
2.  `createAgent(string _name, string _metadataURI, uint256 _initialSkillScore, bytes32[] _initialSkills)`: Mints a new AI Agent NFT with initial attributes.
3.  `updateAgentMetadata(uint256 _agentId, string _newMetadataURI)`: Allows the agent owner to update the associated metadata URI.
4.  `getAgentDetails(uint256 _agentId)`: Retrieves the comprehensive details of a specific AI Agent.
5.  `getAgentSkills(uint256 _agentId)`: Returns the array of skill hashes associated with an agent.
6.  `getTotalAgents()`: Returns the total number of AI Agents minted on the platform.

**II. Agent Evolution & Attestation**
7.  `attestAgentPerformance(uint256 _agentId, bytes32 _taskId, uint256 _performanceScore, bytes _attestationProof)`: A user/oracle provides an on-chain attestation of an agent's performance for a specific task.
8.  `challengeAttestation(uint256 _agentId, bytes32 _taskId)`: Initiates a dispute over a specific performance attestation.
9.  `resolveAttestationChallenge(uint256 _agentId, bytes32 _taskId, bool _attestationValid)`: DAO or designated oracle resolves a disputed attestation.
10. `evolveAgent(uint256 _agentId, uint256 _newSkillScore, bytes32[] _addedSkills, bytes32[] _removedSkills)`: Allows an agent owner to trigger an "evolution" (update skills/score) based on accumulated performance.
11. `breedAgents(uint256 _agentId1, uint256 _agentId2, string _newName, string _newMetadataURI)`: Creates a new "offspring" agent by combining the "DNA" (abstracted attributes) of two parent agents.

**III. Agent Service Marketplace**
12. `listAgentForService(uint256 _agentId, bytes32[] _serviceSkillsRequired, uint256 _pricePerTask, uint256 _availabilityDuration)`: Agent owner lists their agent for specific services with a price and duration.
13. `requestAgentService(uint256 _agentId, bytes _taskData)`: A user requests a service from a listed agent, paying the stipulated fee into escrow.
14. `confirmServiceCompletion(uint256 _serviceId, bytes _resultData)`: Agent owner confirms completion of a service and provides the result data. Releases funds from escrow.
15. `disputeServiceCompletion(uint256 _serviceId, string _reason)`: User disputes the completion or quality of a service.
16. `resolveServiceDispute(uint256 _serviceId, bool _serviceSuccessful)`: DAO or designated oracle resolves a service dispute, releasing funds accordingly.
17. `cancelServiceRequest(uint256 _serviceId)`: Allows the requester or agent owner to cancel an active service request under certain conditions.
18. `getAgentServiceListing(uint256 _agentId)`: Retrieves the current service listing details for an agent.
19. `getServiceRequestDetails(uint256 _serviceId)`: Retrieves the details of a specific service request.

**IV. Governance & Treasury (DAO-centric)**
20. `proposeGovernanceAction(bytes _calldata, string _description)`: Initiates a new governance proposal for changes to the contract or treasury allocation.
21. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible token holders (or reputation holders) to vote on an active proposal.
22. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed the voting phase.
23. `depositToTreasury()`: Allows anyone to deposit ETH into the AetherweaveAI treasury.
24. `allocateTreasuryFunds(address _recipient, uint256 _amount, string _reason)`: DAO-governed function to disburse funds from the treasury.
25. `setTrustedOracle(address _newOracleAddress)`: DAO-governed function to update the address of the trusted oracle for dispute resolution (if not fully DAO-managed).

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom error for common issues
error AetherweaveAI__AgentNotFound();
error AetherweaveAI__NotAgentOwner();
error AetherweaveAI__AgentNotActive();
error AetherweaveAI__AgentNotListed();
error AetherweaveAI__ListingNotFound();
error AetherweaveAI__ServiceRequestNotFound();
error AetherweaveAI__InvalidServiceStatus();
error AetherweaveAI__InsufficientFunds();
error AetherweaveAI__AttestationNotFound();
error AetherweaveAI__AttestationNotDisputed();
error AetherweaveAI__OnlyTrustedOracle();
error AetherweaveAI__ProposalNotFound();
error AetherweaveAI__ProposalNotActive();
error AetherweaveAI__ProposalAlreadyVoted();
error AetherweaveAI__QuorumNotMet();
error AetherweaveAI__VotingPeriodNotEnded();
error AetherweaveAI__VotingPeriodActive();
error AetherweaveAI__ProposalAlreadyExecuted();
error AetherweaveAI__InvalidSkillChange();
error AetherweaveAI__NotRequesterOrOwner();
error AetherweaveAI__Unauthorized(); // Generic for DAO/Oracle calls

contract AetherweaveAI is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum AgentStatus {
        Active,          // Ready for services or breeding
        ServiceListed,   // Currently listed on the marketplace
        InService,       // Currently performing a requested service
        Challenged,      // Has a disputed attestation or service
        Bred,            // Has been used for breeding and is now 'inactive' for services
        Retired          // Permanently retired
    }

    enum ServiceStatus {
        Requested,       // Service requested, payment escrowed
        Completed,       // Service confirmed completed by agent owner
        Disputed,        // Service completion disputed by requester
        ResolvedSuccess, // Dispute resolved in favor of agent owner
        ResolvedFailure, // Dispute resolved in favor of requester
        Cancelled        // Service cancelled before completion/dispute
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---

    struct Agent {
        uint256 id;
        address owner;
        string name;
        string metadataURI;
        uint256 currentSkillScore; // Aggregate score based on performance
        bytes32[] skills;          // Hashed identifiers for specific AI capabilities
        AgentStatus status;
        uint256 lastEvolutionTime;
        uint256 totalTasksCompleted;
        uint256 totalPerformanceScoreSum; // Sum for average calculation
        // Future: could add parent IDs for breeding lineage
        uint256 parent1Id;
        uint256 parent2Id;
    }

    struct AgentServiceListing {
        uint256 agentId;
        address agentOwner;
        bytes32[] serviceSkillsRequired; // Skills needed for this specific service type
        uint256 pricePerTask; // Price in WEI
        uint256 listingStartTime;
        uint256 listingDuration; // Duration in seconds
        bool active;
    }

    struct ServiceRequest {
        uint256 id;
        uint256 agentId;
        address requester;
        bytes taskData; // Data payload for the AI task (e.g., input parameters)
        uint256 price;
        ServiceStatus status;
        bytes resultData; // Data payload for the AI task result
        string disputeReason;
        uint256 requestTime;
    }

    struct Attestation {
        uint256 agentId;
        bytes32 taskId; // Identifier for the specific task attested
        address attester;
        uint256 performanceScore; // Score assigned (e.g., 0-100)
        bytes attestationProof; // Placeholder for cryptographic proof or signed data
        uint256 timestamp;
        bool disputed;
        bool resolvedValid; // True if dispute resolved valid, false if invalid
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks unique voters
    }

    // --- State Variables ---

    Counters.Counter private _agentIds;
    Counters.Counter private _serviceRequestIds;
    Counters.Counter private _proposalIds;

    // Mappings for data retrieval
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => AgentServiceListing) public agentListings;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => Attestation) public attestations; // agentId => taskId => Attestation (no, needs unique ID)
    mapping(uint256 => mapping(bytes32 => Attestation)) private agentTaskAttestations; // agentId -> taskId -> latest attestation
    mapping(uint256 => GovernanceProposal) public proposals;

    address public trustedOracle; // Address of a trusted oracle for dispute resolution if not fully DAO
    uint256 public constant VOTING_PERIOD_SECONDS = 3 days;
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 51; // 51% of total governance token supply (conceptual for now)

    // Treasury to collect fees or donations
    address public treasuryAddress;

    // --- Events ---

    event AgentCreated(uint256 indexed agentId, address indexed owner, string name, string metadataURI);
    event AgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI);
    event AgentEvolved(uint256 indexed agentId, uint256 newSkillScore, bytes32[] addedSkills, bytes32[] removedSkills);
    event AgentsBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newAgentId);

    event AgentListedForService(uint256 indexed agentId, uint256 pricePerTask, bytes32[] serviceSkills);
    event ServiceRequested(uint256 indexed serviceId, uint256 indexed agentId, address indexed requester, uint256 price);
    event ServiceCompleted(uint256 indexed serviceId, uint256 indexed agentId, bytes resultData);
    event ServiceDisputed(uint256 indexed serviceId, address indexed disputer, string reason);
    event ServiceDisputeResolved(uint256 indexed serviceId, bool successful);
    event ServiceCancelled(uint256 indexed serviceId, address indexed initiator);

    event AgentPerformanceAttested(uint256 indexed agentId, bytes32 indexed taskId, address indexed attester, uint256 score);
    event AttestationChallenged(uint256 indexed agentId, bytes32 indexed taskId, address indexed challenger);
    event AttestationChallengeResolved(uint256 indexed agentId, bytes32 indexed taskId, bool attestationValid);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryAllocated(address indexed recipient, uint256 amount, string reason);
    event TrustedOracleSet(address indexed newOracleAddress);

    // --- Constructor & Initial Setup ---

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Initial owner can be set as a multisig or another contract for DAO governance later
        // For simplicity, we assume `owner()` initially is the deployer, which will then transfer to DAO.
        treasuryAddress = address(this); // Funds are held in this contract initially
    }

    // Function to transfer ownership to a DAO multisig or governance contract
    function transferOwnershipToDAO(address _daoAddress) public onlyOwner {
        transferOwnership(_daoAddress);
    }

    // Set trusted oracle. Can be updated by DAO after ownership transfer.
    function setTrustedOracle(address _newOracleAddress) public onlyOwner {
        trustedOracle = _newOracleAddress;
        emit TrustedOracleSet(_newOracleAddress);
    }

    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _agentId) {
        if (agents[_agentId].owner != _msgSender()) {
            revert AetherweaveAI__NotAgentOwner();
        }
        _;
    }

    // Assumes `owner()` is now the DAO or a specific trusted address.
    modifier onlyDaoOrOracle() {
        if (_msgSender() != owner() && _msgSender() != trustedOracle) {
            revert AetherweaveAI__Unauthorized();
        }
        _;
    }

    // --- I. Core Agent Management ---

    function createAgent(
        string memory _name,
        string memory _metadataURI,
        uint256 _initialSkillScore,
        bytes32[] memory _initialSkills
    ) public nonReentrant returns (uint256) {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        Agent storage newAgent = agents[newAgentId];
        newAgent.id = newAgentId;
        newAgent.owner = _msgSender();
        newAgent.name = _name;
        newAgent.metadataURI = _metadataURI;
        newAgent.currentSkillScore = _initialSkillScore;
        newAgent.skills = _initialSkills;
        newAgent.status = AgentStatus.Active;
        newAgent.lastEvolutionTime = block.timestamp;
        newAgent.totalTasksCompleted = 0;
        newAgent.totalPerformanceScoreSum = 0;
        newAgent.parent1Id = 0; // 0 indicates no parent
        newAgent.parent2Id = 0;

        _safeMint(_msgSender(), newAgentId);
        emit AgentCreated(newAgentId, _msgSender(), _name, _metadataURI);
        return newAgentId;
    }

    function updateAgentMetadata(uint256 _agentId, string memory _newMetadataURI)
        public
        onlyAgentOwner(_agentId)
    {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AetherweaveAI__AgentNotFound();
        agent.metadataURI = _newMetadataURI;
        emit AgentMetadataUpdated(_agentId, _newMetadataURI);
    }

    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            uint256 id,
            address owner,
            string memory name,
            string memory metadataURI,
            uint256 currentSkillScore,
            AgentStatus status,
            uint256 totalTasksCompleted,
            uint256 totalPerformanceScoreSum,
            uint256 parent1Id,
            uint256 parent2Id
        )
    {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AetherweaveAI__AgentNotFound();
        return (
            agent.id,
            agent.owner,
            agent.name,
            agent.metadataURI,
            agent.currentSkillScore,
            agent.status,
            agent.totalTasksCompleted,
            agent.totalPerformanceScoreSum,
            agent.parent1Id,
            agent.parent2Id
        );
    }

    function getAgentSkills(uint256 _agentId) public view returns (bytes32[] memory) {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AetherweaveAI__AgentNotFound();
        return agent.skills;
    }

    function getTotalAgents() public view returns (uint256) {
        return _agentIds.current();
    }

    // --- II. Agent Evolution & Attestation ---

    function attestAgentPerformance(
        uint256 _agentId,
        bytes32 _taskId,
        uint256 _performanceScore,
        bytes memory _attestationProof
    ) public nonReentrant {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AetherweaveAI__AgentNotFound();

        // Overwrite previous attestation for the same task, or create new
        Attestation storage newAttestation = agentTaskAttestations[_agentId][_taskId];
        newAttestation.agentId = _agentId;
        newAttestation.taskId = _taskId;
        newAttestation.attester = _msgSender();
        newAttestation.performanceScore = _performanceScore;
        newAttestation.attestationProof = _attestationProof;
        newAttestation.timestamp = block.timestamp;
        newAttestation.disputed = false;
        newAttestation.resolvedValid = false; // Default until resolved

        // Update agent's aggregate performance (simplified)
        agent.totalPerformanceScoreSum += _performanceScore;
        agent.totalTasksCompleted++;
        agent.currentSkillScore = agent.totalPerformanceScoreSum / agent.totalTasksCompleted;

        emit AgentPerformanceAttested(_agentId, _taskId, _msgSender(), _performanceScore);
    }

    function challengeAttestation(uint256 _agentId, bytes32 _taskId) public {
        Attestation storage attestation = agentTaskAttestations[_agentId][_taskId];
        if (attestation.agentId == 0) revert AetherweaveAI__AttestationNotFound();
        if (attestation.disputed) revert AetherweaveAI__AttestationNotDisputed(); // Already challenged

        attestation.disputed = true;
        // Optionally, change agent status to Challenged
        agents[_agentId].status = AgentStatus.Challenged;
        emit AttestationChallenged(_agentId, _taskId, _msgSender());
    }

    function resolveAttestationChallenge(
        uint256 _agentId,
        bytes32 _taskId,
        bool _attestationValid
    ) public onlyDaoOrOracle {
        Attestation storage attestation = agentTaskAttestations[_agentId][_taskId];
        if (attestation.agentId == 0) revert AetherweaveAI__AttestationNotFound();
        if (!attestation.disputed) revert AetherweaveAI__AttestationNotDisputed();

        attestation.disputed = false;
        attestation.resolvedValid = _attestationValid;

        // Revert skill score update if attestation was invalid
        if (!_attestationValid) {
            Agent storage agent = agents[_agentId];
            agent.totalPerformanceScoreSum -= attestation.performanceScore;
            agent.totalTasksCompleted--;
            if (agent.totalTasksCompleted > 0) {
                agent.currentSkillScore = agent.totalPerformanceScoreSum / agent.totalTasksCompleted;
            } else {
                agent.currentSkillScore = 0;
            }
        }
        agents[_agentId].status = AgentStatus.Active; // Restore status after resolution

        emit AttestationChallengeResolved(_agentId, _taskId, _attestationValid);
    }

    function evolveAgent(
        uint256 _agentId,
        uint256 _newSkillScore,
        bytes32[] memory _addedSkills,
        bytes32[] memory _removedSkills
    ) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AetherweaveAI__AgentNotFound();
        if (agent.status != AgentStatus.Active) revert AetherweaveAI__AgentNotActive();

        // Basic check: new skill score must be higher than current,
        // or evolution requires substantial tasks completed since last.
        // Complex evolution logic would be off-chain.
        if (_newSkillScore <= agent.currentSkillScore && agent.totalTasksCompleted < 10) {
            revert AetherweaveAI__InvalidSkillChange(); // Example: Requires more tasks or higher score
        }

        agent.currentSkillScore = _newSkillScore;

        // Add new skills
        for (uint256 i = 0; i < _addedSkills.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < agent.skills.length; j++) {
                if (agent.skills[j] == _addedSkills[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                agent.skills.push(_addedSkills[i]);
            }
        }

        // Remove skills
        for (uint256 i = 0; i < _removedSkills.length; i++) {
            for (uint256 j = 0; j < agent.skills.length; j++) {
                if (agent.skills[j] == _removedSkills[i]) {
                    agent.skills[j] = agent.skills[agent.skills.length - 1];
                    agent.skills.pop();
                    break;
                }
            }
        }
        agent.lastEvolutionTime = block.timestamp;

        emit AgentEvolved(_agentId, _newSkillScore, _addedSkills, _removedSkills);
    }

    function breedAgents(
        uint256 _agentId1,
        uint256 _agentId2,
        string memory _newName,
        string memory _newMetadataURI
    ) public nonReentrant returns (uint256) {
        Agent storage agent1 = agents[_agentId1];
        Agent storage agent2 = agents[_agentId2];

        if (agent1.id == 0 || agent2.id == 0) revert AetherweaveAI__AgentNotFound();
        if (agent1.owner != _msgSender() || agent2.owner != _msgSender()) revert AetherweaveAI__NotAgentOwner();
        if (agent1.status != AgentStatus.Active || agent2.status != AgentStatus.Active) revert AetherweaveAI__AgentNotActive();
        // Prevent re-breeding too quickly (e.g., within 30 days)
        // if (block.timestamp < agent1.lastEvolutionTime + 30 days || block.timestamp < agent2.lastEvolutionTime + 30 days) {
        //     revert AetherweaveAI__CannotBreedYet();
        // }

        // Mark parents as 'Bred' (optional, or 'Locked')
        agent1.status = AgentStatus.Bred;
        agent2.status = AgentStatus.Bred;

        // Simple aggregation for new agent's initial score and skills
        uint256 newSkillScore = (agent1.currentSkillScore + agent2.currentSkillScore) / 2;
        bytes32[] memory newSkills = new bytes32[](agent1.skills.length + agent2.skills.length);
        uint256 k = 0;
        for (uint256 i = 0; i < agent1.skills.length; i++) {
            newSkills[k++] = agent1.skills[i];
        }
        for (uint256 i = 0; i < agent2.skills.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < agent1.skills.length; j++) {
                if (agent2.skills[i] == agent1.skills[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                newSkills[k++] = agent2.skills[i];
            }
        }
        // Resize newSkills array to actual unique skill count
        assembly {
            mstore(newSkills, k)
        }

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        Agent storage newAgent = agents[newAgentId];
        newAgent.id = newAgentId;
        newAgent.owner = _msgSender();
        newAgent.name = _newName;
        newAgent.metadataURI = _newMetadataURI;
        newAgent.currentSkillScore = newSkillScore;
        newAgent.skills = newSkills;
        newAgent.status = AgentStatus.Active;
        newAgent.lastEvolutionTime = block.timestamp;
        newAgent.totalTasksCompleted = 0;
        newAgent.totalPerformanceScoreSum = 0;
        newAgent.parent1Id = _agentId1;
        newAgent.parent2Id = _agentId2;

        _safeMint(_msgSender(), newAgentId);
        emit AgentsBred(_agentId1, _agentId2, newAgentId);
        return newAgentId;
    }

    // --- III. Agent Service Marketplace ---

    function listAgentForService(
        uint256 _agentId,
        bytes32[] memory _serviceSkillsRequired,
        uint256 _pricePerTask,
        uint256 _availabilityDuration
    ) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.id == 0) revert AetherweaveAI__AgentNotFound();
        if (agent.status != AgentStatus.Active) revert AetherweaveAI__AgentNotActive(); // Must be active to list

        agentListings[_agentId] = AgentServiceListing({
            agentId: _agentId,
            agentOwner: _msgSender(),
            serviceSkillsRequired: _serviceSkillsRequired,
            pricePerTask: _pricePerTask,
            listingStartTime: block.timestamp,
            listingDuration: _availabilityDuration,
            active: true
        });

        agent.status = AgentStatus.ServiceListed;
        emit AgentListedForService(_agentId, _pricePerTask, _serviceSkillsRequired);
    }

    function requestAgentService(uint256 _agentId, bytes memory _taskData) public payable nonReentrant {
        AgentServiceListing storage listing = agentListings[_agentId];
        if (!listing.active || listing.agentId == 0) revert AetherweaveAI__AgentNotListed();
        if (listing.pricePerTask > msg.value) revert AetherweaveAI__InsufficientFunds();
        if (block.timestamp > listing.listingStartTime + listing.listingDuration) {
            revert AetherweaveAI__ListingNotFound(); // Listing expired
        }

        _serviceRequestIds.increment();
        uint256 newServiceId = _serviceRequestIds.current();

        serviceRequests[newServiceId] = ServiceRequest({
            id: newServiceId,
            agentId: _agentId,
            requester: _msgSender(),
            taskData: _taskData,
            price: listing.pricePerTask,
            status: ServiceStatus.Requested,
            resultData: "",
            disputeReason: "",
            requestTime: block.timestamp
        });

        // Update agent status to InService
        agents[_agentId].status = AgentStatus.InService;
        listing.active = false; // Delist once service is requested

        // Funds are held in this contract (treasuryAddress)
        // No explicit transfer to agent owner yet, it's escrowed.

        emit ServiceRequested(newServiceId, _agentId, _msgSender(), listing.pricePerTask);
    }

    function confirmServiceCompletion(uint256 _serviceId, bytes memory _resultData)
        public
        nonReentrant
        onlyAgentOwner(serviceRequests[_serviceId].agentId)
    {
        ServiceRequest storage request = serviceRequests[_serviceId];
        if (request.id == 0) revert AetherweaveAI__ServiceRequestNotFound();
        if (request.status != ServiceStatus.Requested) revert AetherweaveAI__InvalidServiceStatus();

        request.status = ServiceStatus.Completed;
        request.resultData = _resultData;

        // Transfer funds to agent owner
        // Using `call` for safer external calls
        (bool success, ) = request.requester.call{value: request.price}(""); // Return excess ETH to requester
        require(success, "Failed to return excess ETH to requester");

        (success, ) = agents[request.agentId].owner.call{value: request.price}(""); // Send service price to agent owner
        require(success, "Failed to send funds to agent owner");

        // Set agent status back to active after service completion
        agents[request.agentId].status = AgentStatus.Active;

        emit ServiceCompleted(_serviceId, request.agentId, _resultData);
    }

    function disputeServiceCompletion(uint256 _serviceId, string memory _reason) public nonReentrant {
        ServiceRequest storage request = serviceRequests[_serviceId];
        if (request.id == 0) revert AetherweaveAI__ServiceRequestNotFound();
        if (request.requester != _msgSender()) revert AetherweaveAI__Unauthorized(); // Only requester can dispute
        if (request.status != ServiceStatus.Completed) revert AetherweaveAI__InvalidServiceStatus();

        request.status = ServiceStatus.Disputed;
        request.disputeReason = _reason;

        agents[request.agentId].status = AgentStatus.Challenged; // Mark agent as challenged
        emit ServiceDisputed(_serviceId, _msgSender(), _reason);
    }

    function resolveServiceDispute(uint256 _serviceId, bool _serviceSuccessful) public onlyDaoOrOracle {
        ServiceRequest storage request = serviceRequests[_serviceId];
        if (request.id == 0) revert AetherweaveAI__ServiceRequestNotFound();
        if (request.status != ServiceStatus.Disputed) revert AetherweaveAI__InvalidServiceStatus();

        if (_serviceSuccessful) {
            request.status = ServiceStatus.ResolvedSuccess;
            // Transfer funds to agent owner
            (bool success, ) = agents[request.agentId].owner.call{value: request.price}("");
            require(success, "Failed to resolve dispute (success)");
        } else {
            request.status = ServiceStatus.ResolvedFailure;
            // Refund funds to requester
            (bool success, ) = request.requester.call{value: request.price}("");
            require(success, "Failed to resolve dispute (failure)");
        }

        // Restore agent status to active
        agents[request.agentId].status = AgentStatus.Active;

        emit ServiceDisputeResolved(_serviceId, _serviceSuccessful);
    }

    function cancelServiceRequest(uint256 _serviceId) public nonReentrant {
        ServiceRequest storage request = serviceRequests[_serviceId];
        if (request.id == 0) revert AetherweaveAI__ServiceRequestNotFound();
        if (request.requester != _msgSender() && agents[request.agentId].owner != _msgSender()) {
            revert AetherweaveAI__NotRequesterOrOwner();
        }
        if (request.status != ServiceStatus.Requested) revert AetherweaveAI__InvalidServiceStatus();

        // Refund funds to requester
        (bool success, ) = request.requester.call{value: request.price}("");
        require(success, "Failed to refund on cancel");

        request.status = ServiceStatus.Cancelled;
        agents[request.agentId].status = AgentStatus.Active; // Return agent to active

        emit ServiceCancelled(_serviceId, _msgSender());
    }

    function getAgentServiceListing(uint256 _agentId)
        public
        view
        returns (
            uint256 agentId,
            address agentOwner,
            bytes32[] memory serviceSkillsRequired,
            uint256 pricePerTask,
            uint256 listingStartTime,
            uint256 listingDuration,
            bool active
        )
    {
        AgentServiceListing storage listing = agentListings[_agentId];
        if (listing.agentId == 0 || !listing.active || block.timestamp > listing.listingStartTime + listing.listingDuration) {
            revert AetherweaveAI__ListingNotFound();
        }
        return (
            listing.agentId,
            listing.agentOwner,
            listing.serviceSkillsRequired,
            listing.pricePerTask,
            listing.listingStartTime,
            listing.listingDuration,
            listing.active
        );
    }

    function getServiceRequestDetails(uint256 _serviceId)
        public
        view
        returns (
            uint256 id,
            uint256 agentId,
            address requester,
            uint256 price,
            ServiceStatus status,
            uint256 requestTime
        )
    {
        ServiceRequest storage request = serviceRequests[_serviceId];
        if (request.id == 0) revert AetherweaveAI__ServiceRequestNotFound();
        return (
            request.id,
            request.agentId,
            request.requester,
            request.price,
            request.status,
            request.requestTime
        );
    }

    // --- IV. Governance & Treasury (DAO-centric) ---

    // Note: For a real DAO, `_msgSender()` would be checked against governance token balance/reputation.
    // Here, `onlyOwner` (the DAO contract itself) is used as a placeholder for proposal creation and voting.
    // In a full DAO, this would be `public` and checked by a separate governance token/voting contract.

    function proposeGovernanceAction(bytes memory _calldata, string memory _description) public onlyOwner {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        GovernanceProposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = _msgSender();
        newProposal.description = _description;
        newProposal.callData = _calldata;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + VOTING_PERIOD_SECONDS;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.status = ProposalStatus.Active;

        emit ProposalCreated(newProposalId, _msgSender(), _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyOwner { // Simplified for demo
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AetherweaveAI__ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert AetherweaveAI__ProposalNotActive();
        if (block.timestamp >= proposal.votingEndTime) revert AetherweaveAI__VotingPeriodEnded();
        if (proposal.hasVoted[_msgSender()]) revert AetherweaveAI__ProposalAlreadyVoted();

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[_msgSender()] = true; // Mark voter

        // In a real DAO, `getTotalSupply()` would be total governance tokens, and `_msgSender()` would be the voter's token balance.
        // For this demo, let's assume `owner()` represents the "DAO" and it just votes once.
        // A more complex DAO would require a separate governance token contract or reputation system.
        // if (proposal.votesFor * 100 / totalGovernanceTokens() >= PROPOSAL_QUORUM_PERCENT) { ... }

        emit VoteCast(_proposalId, _msgSender(), _support);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner { // Simplified for demo
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AetherweaveAI__ProposalNotFound();
        if (proposal.status == ProposalStatus.Executed) revert AetherweaveAI__ProposalAlreadyExecuted();
        if (block.timestamp < proposal.votingEndTime) revert AetherweaveAI__VotingPeriodActive();

        // Simplified quorum check: if votesFor > votesAgainst (requires more robust quorum in real DAO)
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.status = ProposalStatus.Failed;
            revert AetherweaveAI__QuorumNotMet();
        }

        // Execute the call data
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    function depositToTreasury() public payable {
        // Funds automatically sent to this contract address (treasuryAddress)
    }

    function allocateTreasuryFunds(address _recipient, uint256 _amount, string memory _reason) public onlyOwner nonReentrant {
        // This function would typically be called via a successful governance proposal
        if (address(this).balance < _amount) revert AetherweaveAI__InsufficientFunds();

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to allocate treasury funds");

        emit TreasuryAllocated(_recipient, _amount, _reason);
    }

    // --- ERC721 Overrides ---
    function _transfer(address from, address to, uint256 tokenId) internal override {
        // Additional logic if transferring an agent should change its status
        Agent storage agent = agents[tokenId];
        if (agent.id != 0) {
            agent.owner = to; // Update agent's owner in our custom struct
        }
        super._transfer(from, to, tokenId);
    }

    // The following functions are standard ERC721 functions, but listed for clarity that they exist
    // and would be used to manage NFT ownership:
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override
    // function transferFrom(address from, address to, uint256 tokenId) public override
    // function approve(address to, uint256 tokenId) public override
    // function getApproved(uint256 tokenId) public view override
    // function setApprovalForAll(address operator, bool approved) public override
    // function isApprovedForAll(address owner, address operator) public view override
    // function balanceOf(address owner) public view override
    // function ownerOf(uint256 tokenId) public view override
    // function supportsInterface(bytes4 interfaceId) public view override
}
```