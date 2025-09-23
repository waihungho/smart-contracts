Here's a Solidity smart contract named `CognitoNexus`, designed to manage "Synergetic Agents" (SAs). This protocol allows SAs to accumulate verifiable data through "Attestations," propose and execute complex "Synergies" (multi-step collaborations potentially involving other SAs and ZK-proofs), and build an on-chain "Reputation" that dynamically unlocks new "Traits" and operational tiers.

This design combines several advanced, creative, and trendy concepts:
*   **Decentralized Agents/Identities**: SAs act as unique digital entities.
*   **On-chain Attestations**: Verifiable data attached to agents, akin to decentralized verifiable credentials.
*   **Multi-Agent Coordination/Synergies**: Complex, multi-step collaborations requiring stakes and approvals.
*   **ZK-Proof Interface**: Integrates the *requirement* and *submission* of ZK-proof hashes for off-chain computations, making the contract "ZK-enabled" without expensive on-chain verification.
*   **Dynamic NFTs/Traits (Conceptual)**: Agents can unlock "traits" based on their activity and reputation, making their functionality dynamic. (While not an ERC721 contract itself, the `agentId` could easily map to an NFT).
*   **Reputation System**: An on-chain score influencing an agent's capabilities and access to higher-tier operations.
*   **Escrow & Fee Mechanisms**: Staking for proposals and protocol fees.
*   **Role-Based Access Control**: For attestors and contract owner.
*   **On-chain Governance (Parametric)**: Owner can adjust key protocol parameters.

---

### Outline and Function Summary

This contract, `CognitoNexus`, establishes a sophisticated protocol for managing "Synergetic Agents" (SAs). SAs are decentralized entities that can accumulate verified data (Attestations), propose and execute complex multi-step collaborations (Synergies), and build an on-chain reputation that unlocks dynamic capabilities and "traits." It integrates concepts like ZK-proof interfaces, dynamic NFTs (implied), and advanced decentralized coordination.

**I. Core Agent Management**
1.  `registerSynergeticAgent`: Creates a new Synergetic Agent (SA) for the caller, assigning it a unique ID and initial metadata.
2.  `updateAgentMetadata`: Allows an SA owner to update their agent's metadata URI and description.
3.  `deactivateAgent`: Allows an SA owner to temporarily deactivate their agent, pausing its participation in certain protocol activities.
4.  `reactivateAgent`: Allows an SA owner to reactivate a previously deactivated agent.
5.  `transferAgentOwnership`: Transfers ownership of an SA to a new Ethereum address.

**II. Attestation & Knowledge Base**
6.  `issueAgentAttestation`: Records a verified piece of data (attestation) for an SA. This function is restricted to authorized attestors.
7.  `revokeAgentAttestation`: Allows an attestor to revoke an attestation they previously issued for an SA.
8.  `verifyAttestationValidity`: Checks if a given attestation is currently valid (not revoked and not expired).
9.  `delegateAttestorRole`: Grants an address the role of an attestor, enabling them to issue and revoke attestations. Only callable by the contract owner.
10. `revokeAttestorRole`: Revokes the attestor role from an address. Only callable by the contract owner.

**III. Synergy Proposals & Execution**
11. `proposeSynergy`: An SA proposes a new multi-step collaboration (Synergy), detailing its steps, required participants, conditions, and a proof schema. Requires an ETH stake for commitment.
12. `voteOnSynergyProposal`: Allows protocol participants (agents) to cast an approval or rejection vote on a pending synergy proposal.
13. `executeSynergyStep`: Executes a specific, approved step within an active synergy. This function can optionally require a ZK-proof hash to be submitted beforehand or concurrently.
14. `submitSynergyProofHash`: Submits a hash of an off-chain ZK-proof, providing verification for a specific synergy step's computation, separate from its execution trigger.
15. `finalizeSynergy`: Marks a synergy as complete, approved, or failed based on voting outcomes or step completion. It handles the distribution of rewards/penalties and releases the escrow stake.

**IV. Reputation & Evolution**
16. `_updateAgentReputation`: An internal function used to adjust an agent's reputation score. It takes an `int256` to allow for both positive (rewards) and negative (penalties) adjustments.
17. `unlockAgentTrait`: Allows an SA to unlock a new functional 'trait' if it meets specific reputation and/or attestation criteria, making the agent dynamically evolve.
18. `getAgentTier`: Determines and returns an SA's current operational tier (e.g., "Alpha", "Beta") based on its reputation score.

**V. Protocol Governance & Utilities**
19. `setProtocolParameter`: Allows the contract owner to adjust various configurable parameters of the protocol, such as minimum reputation for proposals, voting periods, or fee percentages.
20. `withdrawProtocolFees`: Allows the contract owner to withdraw accumulated protocol fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary:
// This contract, CognitoNexus, establishes a sophisticated protocol for managing "Synergetic Agents" (SAs).
// SAs are decentralized entities that can accumulate verified data (Attestations), propose and execute
// complex multi-step collaborations (Synergies), and build an on-chain reputation that unlocks dynamic
// capabilities and "traits." It integrates concepts like ZK-proof interfaces, dynamic NFTs (implied),
// and advanced decentralized coordination.

// I. Core Agent Management
//    1. registerSynergeticAgent: Creates a new Synergetic Agent (SA) for the caller.
//    2. updateAgentMetadata: Allows an SA owner to update its metadata URI and description.
//    3. deactivateAgent: Allows an SA owner to temporarily deactivate their agent.
//    4. reactivateAgent: Allows an SA owner to reactivate a deactivated agent.
//    5. transferAgentOwnership: Transfers ownership of an SA to a new address.

// II. Attestation & Knowledge Base
//    6. issueAgentAttestation: Records a verified piece of data (attestation) for an SA from an authorized attestor.
//    7. revokeAgentAttestation: Allows an attestor to revoke an attestation they previously issued.
//    8. verifyAttestationValidity: Checks if a given attestation is currently valid (not revoked and not expired).
//    9. delegateAttestorRole: Grants an address the role of an attestor, allowing them to issue and revoke attestations.
//    10. revokeAttestorRole: Revokes the attestor role from an address.

// III. Synergy Proposals & Execution
//    11. proposeSynergy: An SA proposes a new multi-step collaboration (Synergy), detailing steps, participants,
//        and conditions, requiring an ETH stake for commitment.
//    12. voteOnSynergyProposal: Allows protocol participants to vote on pending synergy proposals.
//    13. executeSynergyStep: Executes a specific, approved step within an active synergy. Can optionally require a ZK-proof hash.
//    14. submitSynergyProofHash: Submits a hash of an off-chain ZK-proof, verifying a specific synergy step's computation.
//    15. finalizeSynergy: Marks a synergy as complete, distributes rewards/penalties, and releases the escrow stake.

// IV. Reputation & Evolution
//    16. _updateAgentReputation: Internal function to adjust an agent's reputation score (can be positive or negative).
//    17. unlockAgentTrait: Allows an SA to unlock a new functional 'trait' if it meets specific reputation or attestation criteria.
//    18. getAgentTier: Determines and returns an SA's current operational tier based on its reputation score.

// V. Protocol Governance & Utilities
//    19. setProtocolParameter: Allows the contract owner to adjust various configurable parameters of the protocol.
//    20. withdrawProtocolFees: Allows the contract owner to withdraw accumulated protocol fees.

contract CognitoNexus is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables & Data Structures ---

    Counters.Counter private _agentIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _synergyIds;

    // --- Agent Management ---
    struct SynergeticAgent {
        uint256 id;
        address owner;
        string metadataURI; // IPFS hash or similar for descriptive metadata (e.g., personality, goals)
        string description;
        bool isActive;
        uint256 reputationScore; // Influences agent tier and capabilities
        mapping(bytes32 => bool) unlockedTraits; // Hash of trait name -> true if unlocked
    }
    mapping(uint256 => SynergeticAgent) public agents;
    // For `ownerAgents`, simplifying: new agents are pushed. Old entries from transferred agents might remain,
    // requiring off-chain filtering or a more complex on-chain data structure for efficient removal.
    mapping(address => uint256[]) public ownerAgents; // Track agents by owner for easy lookup

    // --- Attestation System ---
    struct Attestation {
        uint256 id;
        uint256 agentId; // Agent this attestation pertains to
        address attestor;
        bytes32 schemaHash; // Hash of the attestation schema (e.g., "AI_Skill_Rating", "Verified_Data_Source")
        bytes32 dataHash; // Hash of the off-chain verifiable data
        uint256 issuanceTimestamp;
        uint256 expirationTimestamp; // 0 for no expiration
        bool revoked;
    }
    mapping(uint256 => Attestation) public attestations;
    mapping(address => bool) public isAttestor; // Role-based access for attestors

    // --- Synergy Protocol ---
    enum SynergyStatus { Proposed, Approved, Active, Completed, Failed, Canceled }

    struct SynergyStep {
        string description;
        address[] requiredParticipants; // Owners of agents required to participate in this step (can be empty)
        bytes32 requiredProofSchema; // If a ZK-proof is needed for this step, its schema hash (0x0 for none)
        bytes32 submittedProofHash; // Hash of the submitted ZK-proof for this step
        bool completed;
    }

    struct Synergy {
        uint256 id;
        uint256 proposerAgentId;
        string title;
        string description;
        uint256 stakeAmount; // ETH required as collateral for the synergy
        address stakeHolder; // Contract holds the ETH (address(this))
        uint256 creationTimestamp;
        SynergyStatus status;
        SynergyStep[] steps;
        uint256 currentStepIndex;
        mapping(uint256 => bool) votedOnProposal; // agentId => true if voted
        uint256 approvalVotes; // Number of agents approving this synergy
        uint252 rejectionVotes; // Number of agents rejecting this synergy
        uint256 requiredVotesForApproval; // e.g., a fixed number or 0 to use percentage
        uint256 completionTimestamp;
    }
    mapping(uint256 => Synergy) public synergies;

    // --- Protocol Parameters (Adjustable by Owner) ---
    uint256 public MIN_REPUTATION_FOR_SYNERGY_PROPOSAL = 100;
    uint256 public DEFAULT_SYNERGY_PROPOSAL_STAKE = 0.1 ether;
    uint256 public SYNERGY_VOTING_PERIOD = 3 days; // Time for agents to vote on a synergy proposal
    uint256 public SYNERGY_APPROVAL_THRESHOLD_PERCENT = 60; // 60% approval needed (if requiredVotesForApproval is 0)
    uint256 public PROTOCOL_FEE_PERCENT = 5; // 5% of synergy stake goes to protocol fees
    uint256 public protocolFeesAccumulated;

    // Reputation tiers (example thresholds, adjustable by owner)
    uint256 public TIER_ALPHA_REP = 1000;
    uint256 public TIER_BETA_REP = 500;
    uint256 public TIER_GAMMA_REP = 200;

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);
    event AgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI, string newDescription);
    event AgentStatusChanged(uint256 indexed agentId, bool newStatus);
    event AgentOwnershipTransferred(uint256 indexed agentId, address indexed oldOwner, address indexed newOwner);

    event AttestationIssued(uint256 indexed attestationId, uint256 indexed agentId, address indexed attestor, bytes32 schemaHash, bytes32 dataHash);
    event AttestationRevoked(uint256 indexed attestationId, uint256 indexed agentId, address indexed attestor);
    event AttestorRoleGranted(address indexed newAttestor);
    event AttestorRoleRevoked(address indexed oldAttestor);

    event SynergyProposed(uint256 indexed synergyId, uint256 indexed proposerAgentId, uint256 stakeAmount);
    event SynergyVoted(uint256 indexed synergyId, uint256 indexed voterAgentId, bool approved);
    event SynergyStatusUpdated(uint256 indexed synergyId, SynergyStatus oldStatus, SynergyStatus newStatus);
    event SynergyStepExecuted(uint256 indexed synergyId, uint256 stepIndex, bytes32 submittedProofHash);
    event SynergyFinalized(uint256 indexed synergyId, SynergyStatus finalStatus, uint256 completionTimestamp);

    event AgentReputationUpdated(uint256 indexed agentId, uint256 newReputation);
    event AgentTraitUnlocked(uint256 indexed agentId, bytes32 indexed traitHash);
    event ProtocolParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {}

    // --- Internal Helpers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(_agentId > 0 && _agentId <= _agentIds.current(), "CognitoNexus: Invalid agent ID");
        require(agents[_agentId].owner == msg.sender, "CognitoNexus: Not agent owner");
        _;
    }

    modifier onlyAttestor() {
        require(isAttestor[msg.sender], "CognitoNexus: Caller is not an attestor");
        _;
    }

    function _getAgentById(uint256 _agentId) internal view returns (SynergeticAgent storage) {
        require(_agentId > 0 && _agentId <= _agentIds.current(), "CognitoNexus: Invalid agent ID");
        return agents[_agentId];
    }

    // --- I. Core Agent Management ---

    /// @notice Registers a new Synergetic Agent (SA) for the caller.
    /// @param _metadataURI URI pointing to the agent's descriptive metadata (e.g., IPFS hash).
    /// @param _description A brief on-chain description of the agent.
    /// @return The ID of the newly registered agent.
    function registerSynergeticAgent(string calldata _metadataURI, string calldata _description) external returns (uint256) {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();
        
        agents[newAgentId] = SynergeticAgent({
            id: newAgentId,
            owner: msg.sender,
            metadataURI: _metadataURI,
            description: _description,
            isActive: true,
            reputationScore: 0
        });
        ownerAgents[msg.sender].push(newAgentId);

        emit AgentRegistered(newAgentId, msg.sender, _metadataURI);
        return newAgentId;
    }

    /// @notice Allows an SA owner to update its metadata URI and description.
    /// @param _agentId The ID of the agent to update.
    /// @param _newMetadataURI The new URI for the agent's metadata.
    /// @param _newDescription The new on-chain description.
    function updateAgentMetadata(uint256 _agentId, string calldata _newMetadataURI, string calldata _newDescription)
        external
        onlyAgentOwner(_agentId)
    {
        SynergeticAgent storage agent = _getAgentById(_agentId);
        agent.metadataURI = _newMetadataURI;
        agent.description = _newDescription;
        emit AgentMetadataUpdated(_agentId, _newMetadataURI, _newDescription);
    }

    /// @notice Allows an SA owner to temporarily deactivate their agent.
    /// @param _agentId The ID of the agent to deactivate.
    function deactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        SynergeticAgent storage agent = _getAgentById(_agentId);
        require(agent.isActive, "CognitoNexus: Agent is already inactive");
        agent.isActive = false;
        emit AgentStatusChanged(_agentId, false);
    }

    /// @notice Allows an SA owner to reactivate a deactivated agent.
    /// @param _agentId The ID of the agent to reactivate.
    function reactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        SynergeticAgent storage agent = _getAgentById(_agentId);
        require(!agent.isActive, "CognitoNexus: Agent is already active");
        agent.isActive = true;
        emit AgentStatusChanged(_agentId, true);
    }

    /// @notice Transfers ownership of an SA to a new address.
    /// @param _agentId The ID of the agent whose ownership to transfer.
    /// @param _newOwner The address of the new owner.
    function transferAgentOwnership(uint256 _agentId, address _newOwner) external onlyAgentOwner(_agentId) {
        require(_newOwner != address(0), "CognitoNexus: New owner cannot be zero address");
        SynergeticAgent storage agent = _getAgentById(_agentId);
        
        // Note on `ownerAgents`: For simplicity in this example, we push to the new owner's array.
        // Explicitly removing from the old owner's array is gas-expensive.
        // Off-chain indexing or a more advanced data structure would typically handle this efficiently.
        address oldOwner = agent.owner;
        agent.owner = _newOwner;
        ownerAgents[_newOwner].push(_agentId); 

        emit AgentOwnershipTransferred(_agentId, oldOwner, _newOwner);
    }

    // --- II. Attestation & Knowledge Base ---

    /// @notice Records a verified piece of data (attestation) for an SA from an authorized attestor.
    /// @param _agentId The ID of the agent receiving the attestation.
    /// @param _schemaHash Hash representing the schema/type of attestation (e.g., keccak256("AI_Skill_Rating")).
    /// @param _dataHash Hash of the verifiable off-chain data.
    /// @param _expirationTimestamp Optional: timestamp when the attestation expires (0 for no expiration).
    /// @return The ID of the newly issued attestation.
    function issueAgentAttestation(
        uint256 _agentId,
        bytes32 _schemaHash,
        bytes32 _dataHash,
        uint256 _expirationTimestamp
    ) external onlyAttestor returns (uint256) {
        require(_agentId > 0 && _agentId <= _agentIds.current(), "CognitoNexus: Invalid agent ID");
        require(_schemaHash != bytes32(0), "CognitoNexus: Schema hash cannot be empty");
        require(_dataHash != bytes32(0), "CognitoNexus: Data hash cannot be empty");
        if (_expirationTimestamp != 0) {
            require(_expirationTimestamp > block.timestamp, "CognitoNexus: Expiration must be in the future");
        }

        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            id: newAttestationId,
            agentId: _agentId,
            attestor: msg.sender,
            schemaHash: _schemaHash,
            dataHash: _dataHash,
            issuanceTimestamp: block.timestamp,
            expirationTimestamp: _expirationTimestamp,
            revoked: false
        });

        emit AttestationIssued(newAttestationId, _agentId, msg.sender, _schemaHash, _dataHash);
        return newAttestationId;
    }

    /// @notice Allows an attestor to revoke an attestation they previously issued.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAgentAttestation(uint256 _attestationId) external onlyAttestor {
        Attestation storage att = attestations[_attestationId];
        require(att.id != 0, "CognitoNexus: Attestation does not exist");
        require(att.attestor == msg.sender, "CognitoNexus: Only original attestor can revoke");
        require(!att.revoked, "CognitoNexus: Attestation already revoked");

        att.revoked = true;
        emit AttestationRevoked(_attestationId, att.agentId, msg.sender);
    }

    /// @notice Checks if a given attestation is currently valid (not revoked and not expired).
    /// @param _attestationId The ID of the attestation to verify.
    /// @return True if the attestation is valid, false otherwise.
    function verifyAttestationValidity(uint256 _attestationId) public view returns (bool) {
        Attestation storage att = attestations[_attestationId];
        if (att.id == 0 || att.revoked) {
            return false;
        }
        if (att.expirationTimestamp != 0 && att.expirationTimestamp < block.timestamp) {
            return false;
        }
        return true;
    }

    /// @notice Grants an address the role of an attestor. Only callable by the contract owner.
    /// @param _newAttestor The address to grant attestor role to.
    function delegateAttestorRole(address _newAttestor) external onlyOwner {
        require(_newAttestor != address(0), "CognitoNexus: Attestor address cannot be zero");
        require(!isAttestor[_newAttestor], "CognitoNexus: Address is already an attestor");
        isAttestor[_newAttestor] = true;
        emit AttestorRoleGranted(_newAttestor);
    }

    /// @notice Revokes the attestor role from an address. Only callable by the contract owner.
    /// @param _oldAttestor The address to revoke attestor role from.
    function revokeAttestorRole(address _oldAttestor) external onlyOwner {
        require(_oldAttestor != address(0), "CognitoNexus: Attestor address cannot be zero");
        require(isAttestor[_oldAttestor], "CognitoNexus: Address is not an attestor");
        isAttestor[_oldAttestor] = false;
        emit AttestorRoleRevoked(_oldAttestor);
    }

    // --- III. Synergy Proposals & Execution ---

    /// @notice An SA proposes a new multi-step collaboration (Synergy), detailing steps, participants,
    ///         and conditions, requiring an ETH stake for commitment.
    /// @param _proposerAgentId The ID of the agent proposing the synergy.
    /// @param _title A title for the synergy.
    /// @param _description A description of the synergy.
    /// @param _steps An array of SynergyStep structs defining the sequence of actions.
    /// @param _requiredVotesForApproval Number of votes required for approval (or 0 to use default percentage).
    /// @return The ID of the newly proposed synergy.
    function proposeSynergy(
        uint256 _proposerAgentId,
        string calldata _title,
        string calldata _description,
        SynergyStep[] calldata _steps,
        uint256 _requiredVotesForApproval
    ) external payable onlyAgentOwner(_proposerAgentId) returns (uint256) {
        SynergeticAgent storage proposerAgent = _getAgentById(_proposerAgentId);
        require(proposerAgent.isActive, "CognitoNexus: Proposing agent must be active");
        require(proposerAgent.reputationScore >= MIN_REPUTATION_FOR_SYNERGY_PROPOSAL, "CognitoNexus: Agent reputation too low to propose synergy");
        require(msg.value >= DEFAULT_SYNERGY_PROPOSAL_STAKE, "CognitoNexus: Sent ETH must meet minimum stake amount");
        require(_steps.length > 0, "CognitoNexus: Synergy must have at least one step");

        _synergyIds.increment();
        uint256 newSynergyId = _synergyIds.current();

        synergies[newSynergyId] = Synergy({
            id: newSynergyId,
            proposerAgentId: _proposerAgentId,
            title: _title,
            description: _description,
            stakeAmount: msg.value,
            stakeHolder: address(this), // Contract holds the stake
            creationTimestamp: block.timestamp,
            status: SynergyStatus.Proposed,
            steps: _steps, // Deep copy from calldata to storage
            currentStepIndex: 0,
            approvalVotes: 0,
            rejectionVotes: 0,
            requiredVotesForApproval: _requiredVotesForApproval,
            completionTimestamp: 0
        });

        emit SynergyProposed(newSynergyId, _proposerAgentId, msg.value);
        return newSynergyId;
    }

    /// @notice Allows protocol participants (agents) to vote on pending synergy proposals.
    /// @param _synergyId The ID of the synergy proposal to vote on.
    /// @param _voterAgentId The ID of the agent casting the vote.
    /// @param _approve True to approve, false to reject.
    function voteOnSynergyProposal(uint256 _synergyId, uint256 _voterAgentId, bool _approve)
        external
        onlyAgentOwner(_voterAgentId)
    {
        Synergy storage synergy = synergies[_synergyId];
        require(synergy.id != 0, "CognitoNexus: Synergy does not exist");
        require(synergy.status == SynergyStatus.Proposed, "CognitoNexus: Synergy is not in proposed status");
        require(block.timestamp <= synergy.creationTimestamp + SYNERGY_VOTING_PERIOD, "CognitoNexus: Voting period has ended");
        
        SynergeticAgent storage voterAgent = _getAgentById(_voterAgentId);
        require(voterAgent.isActive, "CognitoNexus: Voting agent must be active");
        require(!synergy.votedOnProposal[_voterAgentId], "CognitoNexus: Agent already voted on this proposal");

        synergy.votedOnProposal[_voterAgentId] = true;
        if (_approve) {
            synergy.approvalVotes++;
        } else {
            synergy.rejectionVotes++;
        }

        emit SynergyVoted(_synergyId, _voterAgentId, _approve);
    }

    /// @notice Executes a specific, approved step within an active synergy. Can optionally require a ZK-proof hash.
    ///         Callable by any participant of the step or the proposer's agent owner.
    /// @param _synergyId The ID of the synergy.
    /// @param _stepIndex The index of the step to execute.
    /// @param _submitterAgentId The ID of the agent performing/submitting the step.
    /// @param _proofHash Optional: The hash of an off-chain ZK-proof required for this step. 0x0 if not needed.
    function executeSynergyStep(
        uint256 _synergyId,
        uint256 _stepIndex,
        uint256 _submitterAgentId,
        bytes32 _proofHash
    ) external onlyAgentOwner(_submitterAgentId) { // Restrict to agent owners performing the step
        Synergy storage synergy = synergies[_synergyId];
        require(synergy.id != 0, "CognitoNexus: Synergy does not exist");
        require(synergy.status == SynergyStatus.Active, "CognitoNexus: Synergy is not active");
        require(_stepIndex == synergy.currentStepIndex, "CognitoNexus: Not the current step");
        require(_stepIndex < synergy.steps.length, "CognitoNexus: Invalid step index");

        SynergyStep storage currentStep = synergy.steps[_stepIndex];
        require(!currentStep.completed, "CognitoNexus: Step already completed");

        // Check if the _submitterAgentId's owner is a required participant for this step
        bool isRequiredParticipant = false;
        if (currentStep.requiredParticipants.length > 0) {
            address submitterOwner = agents[_submitterAgentId].owner;
            for (uint i = 0; i < currentStep.requiredParticipants.length; i++) {
                if (currentStep.requiredParticipants[i] == submitterOwner) {
                    isRequiredParticipant = true;
                    break;
                }
            }
            require(isRequiredParticipant, "CognitoNexus: Submitting agent's owner is not a required participant for this step");
        } else {
            // If no specific participants, any agent owner can execute it.
            // Or, could be restricted to proposer's agent owner if desired.
        }

        if (currentStep.requiredProofSchema != bytes32(0)) {
            require(_proofHash != bytes32(0), "CognitoNexus: ZK-proof hash is required for this step");
            // In a real system, an oracle or a dedicated ZK verifier contract would verify this hash against a schema.
            // For this contract, we simply record it.
            currentStep.submittedProofHash = _proofHash;
            emit SynergyStepExecuted(_synergyId, _stepIndex, _proofHash);
        } else {
            emit SynergyStepExecuted(_synergeticId, _stepIndex, bytes32(0));
        }
        
        currentStep.completed = true;
        synergy.currentStepIndex++;

        // If all steps are completed, finalize the synergy
        if (synergy.currentStepIndex == synergy.steps.length) {
            _finalizeSynergy(_synergyId, SynergyStatus.Completed);
        }
    }

    /// @notice Submits a hash of an off-chain ZK-proof, verifying a specific synergy step's computation.
    ///         This is an alternative or complementary way to `executeSynergyStep` if proof submission
    ///         is separate from execution trigger.
    /// @param _synergyId The ID of the synergy.
    /// @param _stepIndex The index of the step for which the proof is submitted.
    /// @param _proofHash The hash of the off-chain ZK-proof.
    function submitSynergyProofHash(
        uint256 _synergyId,
        uint256 _stepIndex,
        bytes32 _proofHash
    ) external {
        Synergy storage synergy = synergies[_synergyId];
        require(synergy.id != 0, "CognitoNexus: Synergy does not exist");
        require(synergy.status == SynergyStatus.Active, "CognitoNexus: Synergy is not active");
        require(_stepIndex < synergy.steps.length, "CognitoNexus: Invalid step index");
        require(_proofHash != bytes32(0), "CognitoNexus: Proof hash cannot be zero");

        SynergyStep storage step = synergy.steps[_stepIndex];
        require(step.requiredProofSchema != bytes32(0), "CognitoNexus: This step does not require a ZK-proof");
        require(step.submittedProofHash == bytes32(0), "CognitoNexus: Proof already submitted for this step");

        step.submittedProofHash = _proofHash;
        emit SynergyStepExecuted(_synergyId, _stepIndex, _proofHash);
    }

    /// @notice Marks a synergy as complete, distributes rewards/penalties, and releases the escrow stake.
    ///         Can be called by the proposer's agent owner after the voting period, or when all steps are done.
    /// @param _synergyId The ID of the synergy to finalize.
    function finalizeSynergy(uint256 _synergyId) external onlyAgentOwner(synergies[_synergyId].proposerAgentId) {
        Synergy storage synergy = synergies[_synergyId];
        require(synergy.id != 0, "CognitoNexus: Synergy does not exist");
        
        bool votingPeriodEnded = (block.timestamp > synergy.creationTimestamp + SYNERGY_VOTING_PERIOD);
        bool allStepsCompleted = (synergy.currentStepIndex == synergy.steps.length);

        if (synergy.status == SynergyStatus.Proposed && votingPeriodEnded) {
            uint256 totalVotes = synergy.approvalVotes + synergy.rejectionVotes;

            bool approvedByVotes = false;
            if (synergy.requiredVotesForApproval > 0) { // Fixed number of votes required
                approvedByVotes = synergy.approvalVotes >= synergy.requiredVotesForApproval;
            } else if (totalVotes > 0) { // Percentage based approval (if any votes cast)
                approvedByVotes = (synergy.approvalVotes * 100) / totalVotes >= SYNERGY_APPROVAL_THRESHOLD_PERCENT;
            } else { // No votes cast, implicitly assume not approved or needs owner decision
                // For simplicity, if no votes and voting period ended, it's failed.
                approvedByVotes = false;
            }

            if (approvedByVotes) {
                _updateSynergyStatus(_synergyId, SynergyStatus.Active);
                // If it becomes active, it needs to go through steps, cannot finalize immediately as 'Completed'
                revert("CognitoNexus: Synergy moved to Active, not yet completed. Call executeSynergyStep for each step.");
            } else {
                _finalizeSynergy(_synergyId, SynergyStatus.Failed);
            }
        } else if (synergy.status == SynergyStatus.Active && allStepsCompleted) {
            _finalizeSynergy(_synergyId, SynergyStatus.Completed);
        } else {
            revert("CognitoNexus: Synergy not in a state ready for finalization (e.g., voting still active or steps remaining)");
        }
    }

    /// @dev Internal function to handle the actual finalization logic.
    function _finalizeSynergy(uint256 _synergyId, SynergyStatus _finalStatus) internal {
        Synergy storage synergy = synergies[_synergyId];
        require(synergy.status != SynergyStatus.Completed && synergy.status != SynergyStatus.Failed && synergy.status != SynergyStatus.Canceled, "CognitoNexus: Synergy already finalized");

        synergy.status = _finalStatus;
        synergy.completionTimestamp = block.timestamp;

        uint256 stake = synergy.stakeAmount;
        uint256 protocolFee = (stake * PROTOCOL_FEE_PERCENT) / 100;
        uint256 remainingStake = stake - protocolFee;
        protocolFeesAccumulated += protocolFee;

        address proposerOwner = agents[synergy.proposerAgentId].owner;

        if (_finalStatus == SynergyStatus.Completed) {
            // Proposer gets stake back (minus fees)
            (bool success, ) = payable(proposerOwner).call{value: remainingStake}("");
            require(success, "CognitoNexus: Failed to refund proposer stake");
            _updateAgentReputation(synergy.proposerAgentId, 100); // Reward reputation
        } else { // Failed or Canceled
            // If failed, proposer loses stake (or a portion for penalty).
            // For this example, remaining stake is held by contract.
            _updateAgentReputation(synergy.proposerAgentId, -50); // Penalize reputation
        }
        
        emit SynergyFinalized(_synergyId, _finalStatus, block.timestamp);
    }

    /// @dev Internal function to update synergy status and emit event.
    function _updateSynergyStatus(uint256 _synergyId, SynergyStatus _newStatus) internal {
        Synergy storage synergy = synergies[_synergyId];
        SynergyStatus oldStatus = synergy.status;
        synergy.status = _newStatus;
        emit SynergyStatusUpdated(_synergyId, oldStatus, _newStatus);
    }

    // --- IV. Reputation & Evolution ---

    /// @notice Internal function to adjust an agent's reputation score.
    /// @param _agentId The ID of the agent whose reputation to update.
    /// @param _reputationChange The amount to add (if positive) or subtract (if negative) from reputation.
    function _updateAgentReputation(uint256 _agentId, int256 _reputationChange) internal {
        SynergeticAgent storage agent = _getAgentById(_agentId);
        uint256 currentScore = agent.reputationScore;

        if (_reputationChange > 0) {
            agent.reputationScore = currentScore + uint256(_reputationChange); // 0.8+ reverts on overflow
        } else if (_reputationChange < 0) {
            uint256 absChange = uint256(-_reputationChange);
            // Prevent underflow by capping at 0 or reverting
            require(currentScore >= absChange, "CognitoNexus: Agent reputation would drop below zero");
            agent.reputationScore = currentScore - absChange; // 0.8+ reverts on underflow if not checked
        }
        // If _reputationChange is 0, score remains unchanged

        emit AgentReputationUpdated(_agentId, agent.reputationScore);
    }

    /// @notice Allows an SA to unlock a new functional 'trait' if it meets specific reputation or attestation criteria.
    /// @param _agentId The ID of the agent attempting to unlock a trait.
    /// @param _traitHash The hash identifier of the trait to unlock (e.g., keccak256("Advanced_Data_Analysis")).
    /// @param _requiredReputation The minimum reputation score needed to unlock this trait.
    /// @param _requiredAttestationSchema Optional: A schema hash of an attestation required. 0x0 if none.
    function unlockAgentTrait(
        uint256 _agentId,
        bytes32 _traitHash,
        uint256 _requiredReputation,
        bytes32 _requiredAttestationSchema
    ) external onlyAgentOwner(_agentId) {
        SynergeticAgent storage agent = _getAgentById(_agentId);
        require(agent.reputationScore >= _requiredReputation, "CognitoNexus: Not enough reputation to unlock trait");
        require(!agent.unlockedTraits[_traitHash], "CognitoNexus: Trait already unlocked");

        if (_requiredAttestationSchema != bytes32(0)) {
            bool hasRequiredAttestation = false;
            // Iterate through all attestations. In production, an agent might track its attestations
            // more efficiently, or a mapping from (agentId, schemaHash) to attestationId would exist.
            for (uint i = 1; i <= _attestationIds.current(); i++) {
                Attestation storage att = attestations[i];
                if (att.agentId == _agentId && att.schemaHash == _requiredAttestationSchema && verifyAttestationValidity(i)) {
                    hasRequiredAttestation = true;
                    break;
                }
            }
            require(hasRequiredAttestation, "CognitoNexus: Missing required attestation for this trait");
        }

        agent.unlockedTraits[_traitHash] = true;
        emit AgentTraitUnlocked(_agentId, _traitHash);
    }

    /// @notice Determines and returns an SA's current operational tier based on its reputation score.
    /// @param _agentId The ID of the agent.
    /// @return A string representing the agent's tier (e.g., "Alpha", "Beta", "Gamma", "Standard").
    function getAgentTier(uint256 _agentId) public view returns (string memory) {
        SynergeticAgent storage agent = _getAgentById(_agentId);
        if (agent.reputationScore >= TIER_ALPHA_REP) {
            return "Alpha";
        } else if (agent.reputationScore >= TIER_BETA_REP) {
            return "Beta";
        } else if (agent.reputationScore >= TIER_GAMMA_REP) {
            return "Gamma";
        } else {
            return "Standard";
        }
    }

    // --- V. Protocol Governance & Utilities ---

    /// @notice Allows the contract owner to adjust various configurable parameters of the protocol.
    /// @param _parameterName The name of the parameter to update (e.g., "MIN_REP_SYNERGY", "PROTOCOL_FEE_PERCENT").
    /// @param _newValue The new value for the parameter.
    function setProtocolParameter(string calldata _parameterName, uint256 _newValue) external onlyOwner {
        bytes32 paramHash = keccak256(abi.encodePacked(_parameterName));
        uint256 oldValue;

        if (paramHash == keccak256(abi.encodePacked("MIN_REPUTATION_FOR_SYNERGY_PROPOSAL"))) {
            oldValue = MIN_REPUTATION_FOR_SYNERGY_PROPOSAL;
            MIN_REPUTATION_FOR_SYNERGY_PROPOSAL = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("DEFAULT_SYNERGY_PROPOSAL_STAKE"))) {
            oldValue = DEFAULT_SYNERGY_PROPOSAL_STAKE;
            DEFAULT_SYNERGY_PROPOSAL_STAKE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("SYNERGY_VOTING_PERIOD"))) {
            oldValue = SYNERGY_VOTING_PERIOD;
            SYNERGY_VOTING_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("SYNERGY_APPROVAL_THRESHOLD_PERCENT"))) {
            require(_newValue <= 100, "CognitoNexus: Threshold percent cannot exceed 100");
            oldValue = SYNERGY_APPROVAL_THRESHOLD_PERCENT;
            SYNERGY_APPROVAL_THRESHOLD_PERCENT = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PROTOCOL_FEE_PERCENT"))) {
            require(_newValue <= 100, "CognitoNexus: Fee percent cannot exceed 100");
            oldValue = PROTOCOL_FEE_PERCENT;
            PROTOCOL_FEE_PERCENT = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("TIER_ALPHA_REP"))) {
            oldValue = TIER_ALPHA_REP;
            TIER_ALPHA_REP = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("TIER_BETA_REP"))) {
            oldValue = TIER_BETA_REP;
            TIER_BETA_REP = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("TIER_GAMMA_REP"))) {
            oldValue = TIER_GAMMA_REP;
            TIER_GAMMA_REP = _newValue;
        } else {
            revert("CognitoNexus: Unknown protocol parameter");
        }

        emit ProtocolParameterUpdated(_parameterName, oldValue, _newValue);
    }

    /// @notice Allows the contract owner to withdraw accumulated protocol fees.
    /// @param _recipient The address to send the fees to.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolFees(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "CognitoNexus: Recipient cannot be zero address");
        require(_amount > 0, "CognitoNexus: Amount must be greater than zero");
        require(_amount <= protocolFeesAccumulated, "CognitoNexus: Insufficient accumulated fees");

        protocolFeesAccumulated -= _amount;
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "CognitoNexus: Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(_recipient, _amount);
    }

    // Fallback function to accept ETH (primarily for synergy stakes)
    receive() external payable {
        // This is necessary for synergies to accept stakes.
        // ETH sent directly without a function call will be received here.
        // It's assumed such ETH is part of a valid synergy stake based on external calls.
    }
}
```