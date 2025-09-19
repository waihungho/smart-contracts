The `AetherForge` smart contract introduces a novel decentralized protocol designed around **Soul-Bound Agent Cores**, **Reputation (Affinity) Systems**, **Programmable NFT Traits (Cognitive Modules)**, and **Intent-based Orchestration**. It aims to create a framework for verifiable digital identities, decentralized collaboration, and the coordination of tasks and contributions in the Web3 ecosystem.

Users mint a non-transferable "Agent Core" NFT which represents their on-chain persona. This core accumulates "Affinity" (reputation) based on verifiable attestations of their performance in fulfilling "Intents" (declarations of desired actions or contributions). As agents gain Affinity, they can unlock "Cognitive Modules" – programmable traits or abilities that grant them special permissions, increased voting power, or other protocol-specific advantages. The protocol facilitates the discovery, proposal, and confirmation of intent fulfillments, including a basic dispute resolution mechanism. A lightweight DAO layer allows the community of agents to evolve the protocol.

---

## `AetherForge` Smart Contract Outline and Function Summary

**I. Core Protocol Management (Owner/DAO Controlled)**
1.  **`constructor()`**: Initializes the contract, sets the `name` and `symbol` for the ERC721 Agent Cores.
2.  **`setAttestor(address _attestor, bool _canAttest)`**: Grants or revokes permission for an address to act as an attestor, allowing them to record Agent performance.
3.  **`setModuleCriteria(CognitiveModule _moduleId, bytes32 _criteriaType, uint256 _value)`**: Defines the conditions (e.g., `AFFINITY_THRESHOLD`) required to unlock specific Cognitive Modules.
4.  **`setGovernanceModuleEnabled(bool _enabled)`**: Globally enables or disables the protocol's governance module.
5.  **`renounceOwnership()`**: Standard function to transfer contract ownership to the zero address, typically used when a DAO takes full control.

**II. Agent Core Management (Soul-Bound NFT)**
6.  **`mintAgentCore()`**: Allows a new user to mint a unique, non-transferable Agent Core NFT, establishing their on-chain identity.
7.  **`updateAgentMetadataURI(uint256 _tokenId, string memory _newURI)`**: Enables an Agent Core owner to update the metadata URI associated with their core NFT (e.g., to change their avatar or description).
8.  **`burnAgentCore(uint256 _tokenId)`**: Allows an Agent Core owner to voluntarily destroy their core and associated data.
9.  **`getAgentCoreOwner(uint256 _tokenId)`**: Retrieves the blockchain address of the owner of a given Agent Core ID.
10. **`hasAgentCore(address _owner)`**: Checks if a given address currently owns an Agent Core NFT.

**III. Agent Affinity & Attestation (Reputation System)**
11. **`recordAffinityAction(uint256 _agentId, AffinityActionType _actionType, int256 _scoreDelta)`**: Internal function responsible for adjusting an Agent's affinity score based on specific actions (e.g., successful intent fulfillment, dispute resolution).
12. **`attestAgentPerformance(uint256 _agentId, bytes32 _actionIdentifier, bool _success)`**: Allows designated attestors to record an Agent's performance for a specific task or interaction, directly impacting their Affinity.
13. **`getAgentAffinity(uint256 _agentId)`**: Retrieves the current affinity (reputation) score of a specified Agent.
14. **`getAttestationsForAgent(uint256 _agentId)`**: Fetches a list of all recorded attestations for a given Agent Core.

**IV. Cognitive Modules (Programmable Traits)**
15. **`unlockCognitiveModule(uint256 _agentId, CognitiveModule _moduleId)`**: Allows an Agent to unlock a specific Cognitive Module if they meet the predefined criteria (e.g., a certain Affinity score).
16. **`isModuleUnlocked(uint256 _agentId, CognitiveModule _moduleId)`**: Checks whether a specific Cognitive Module has been unlocked for an Agent.
17. **`getAgentUnlockedModules(uint256 _agentId)`**: Retrieves an array of all Cognitive Modules that a given Agent has successfully unlocked.

**V. Agent Intent Management (Declarations of Desired Actions/Contributions)**
18. **`registerAgentIntent(uint256 _agentId, IntentType _intentType, string memory _intentURI, uint256 _expiration)`**: An Agent declares a new "Intent," specifying its type, a URI pointing to detailed off-chain information, and an expiration timestamp.
19. **`updateAgentIntent(uint256 _agentId, uint256 _intentId, string memory _newIntentURI, uint256 _newExpiration)`**: Allows an Agent to modify the details or expiration of an existing active Intent.
20. **`revokeAgentIntent(uint256 _agentId, uint256 _intentId)`**: An Agent can cancel or remove an active Intent they have previously registered.
21. **`getAgentIntents(uint256 _agentId)`**: Retrieves a list of all currently active Intents registered by a specific Agent.
22. **`discoverIntents(IntentType _intentType, uint256 _minAffinity, uint256 _maxResults)`**: Allows external parties to search for active Intents based on type, minimum required Agent Affinity, and a limit on the number of results.

**VI. Intent Fulfillment & Dispute Resolution**
23. **`proposeIntentFulfillment(uint256 _intentId, string memory _fulfillmentDetailsURI, uint256 _collateral)`**: An external party (proposer) offers to fulfill an Agent's declared Intent, providing a URI for details and optional collateral.
24. **`acceptIntentFulfillment(uint256 _intentId, uint256 _fulfillmentProposalId)`**: The Agent whose Intent is being addressed accepts a specific fulfillment proposal.
25. **`confirmIntentFulfillment(uint256 _intentId, uint256 _fulfillmentProposalId)`**: The Agent confirms that their Intent has been successfully fulfilled, triggering affinity updates for both parties and releasing collateral.
26. **`disputeIntentFulfillment(uint256 _intentId, uint256 _fulfillmentProposalId, string memory _disputeReasonURI)`**: If fulfillment is unsatisfactory or incomplete, the Agent can formally dispute it.
27. **`resolveDispute(uint256 _intentId, uint256 _fulfillmentProposalId, address _winner, uint256 _penaltyRatio)`**: An administrative or DAO function to resolve a disputed intent fulfillment, determining the winner and applying penalties.

**VII. Protocol Governance (Lightweight DAO for Evolution)**
28. **`submitProtocolProposal(string memory _proposalURI, bytes memory _executionCalldata)`**: Agents (who have unlocked the Governance module) can submit proposals for protocol upgrades or parameter changes. `_executionCalldata` can represent calls to be made by the contract itself if the proposal passes.
29. **`voteOnProtocolProposal(uint256 _proposalId, bool _support)`**: Agents vote on active protocol proposals, with voting power potentially influenced by their Affinity and unlocked modules.
30. **`executeProtocolProposal(uint256 _proposalId)`**: Executes a protocol proposal that has successfully passed the voting period and threshold.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title AetherForge
/// @author Your Name/AI
/// @notice A protocol for Soul-Bound Agent Cores, Reputation (Affinity), Programmable NFT Traits (Cognitive Modules),
///         and Intent-based Orchestration for decentralized contributions.
/// @dev This contract combines ERC721 (non-transferable), reputation, intent management, and lightweight governance.
contract AetherForge is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Events ---
    event AgentCoreMinted(uint256 indexed tokenId, address indexed owner, string uri);
    event AgentCoreBurned(uint256 indexed tokenId, address indexed owner);
    event AgentMetadataUpdated(uint256 indexed tokenId, string newURI);
    event AffinityRecorded(uint256 indexed agentId, AffinityActionType indexed actionType, int256 scoreDelta, uint256 newAffinity);
    event AttestationRecorded(uint256 indexed agentId, address indexed attestor, bytes32 actionIdentifier, bool success);
    event CognitiveModuleUnlocked(uint256 indexed agentId, CognitiveModule indexed moduleId);
    event IntentRegistered(uint256 indexed agentId, uint256 indexed intentId, IntentType indexed intentType, string intentURI, uint256 expiration);
    event IntentUpdated(uint256 indexed agentId, uint256 indexed intentId, string newIntentURI, uint256 newExpiration);
    event IntentRevoked(uint256 indexed agentId, uint256 indexed intentId);
    event FulfillmentProposed(uint256 indexed intentId, uint256 indexed proposalId, address indexed proposer, string detailsURI, uint256 collateral);
    event FulfillmentAccepted(uint256 indexed intentId, uint256 indexed proposalId);
    event FulfillmentConfirmed(uint256 indexed intentId, uint256 indexed proposalId, uint256 reward);
    event FulfillmentDisputed(uint256 indexed intentId, uint256 indexed proposalId, string disputeReasonURI);
    event DisputeResolved(uint256 indexed intentId, uint256 indexed proposalId, address winner, uint256 penaltyAmount);
    event ProtocolProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event ProtocolVoted(uint256 indexed proposalId, uint256 indexed agentId, bool support);
    event ProtocolProposalExecuted(uint256 indexed proposalId);
    event AttestorSet(address indexed attestor, bool canAttest);
    event ModuleCriteriaSet(CognitiveModule indexed moduleId, bytes32 criteriaType, uint256 value);
    event GovernanceModuleEnabledSet(bool enabled);

    // --- Enums and Structs ---

    enum AffinityActionType {
        IntentFulfillmentConfirmed,
        IntentFulfillmentDisputed,
        AttestationPositive,
        AttestationNegative,
        ProtocolVoteCast
    }

    enum CognitiveModule {
        None,             // Default, no module
        Governance,       // Grants voting rights on protocol proposals
        AdvancedDiscovery, // Enables more powerful intent discovery filters
        IntentDelegation, // Allows agent to delegate sub-tasks from their intents
        DisputeMediator   // Allows agent to mediate certain disputes
    }

    enum IntentType {
        Contribution,      // Agent seeks to contribute to a project
        Collaboration,     // Agent seeks collaborators for a project
        ServiceOffer,      // Agent offers a specific service
        ServiceRequest,    // Agent requests a specific service
        ResearchGrant      // Agent proposes research seeking funding
    }

    struct AgentCoreData {
        address owner;
        int256 affinity; // Reputation score
        mapping(CognitiveModule => bool) unlockedModules;
        Counters.Counter intentIdCounter; // Counter for intents registered by this agent
    }

    struct Intent {
        uint256 agentId;
        IntentType intentType;
        string intentURI;
        uint256 expiration;
        bool active;
        Counters.Counter fulfillmentProposalIdCounter; // Counter for proposals to fulfill this intent
    }

    struct FulfillmentProposal {
        uint256 intentId;
        address proposer;
        string fulfillmentDetailsURI;
        uint256 collateral; // Collateral provided by the proposer
        bool accepted;
        bool confirmed;
        bool disputed;
    }

    struct ProtocolProposal {
        address proposer;
        string proposalURI;
        bytes executionCalldata; // Calldata to execute on AetherForge if passed
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yeas;
        uint256 nays;
        mapping(uint256 => bool) hasVoted; // agentId => voted
        bool executed;
    }

    struct ModuleCriteria {
        bytes32 criteriaType; // e.g., "AFFINITY_THRESHOLD", "INTERACTION_COUNT"
        uint256 value;
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _intentIdCounter;
    Counters.Counter private _protocolProposalIdCounter;

    mapping(uint256 => AgentCoreData) private _agentCores; // tokenId => AgentCoreData
    mapping(address => uint256) private _agentCoreByOwner; // owner address => tokenId (for single agent core per owner)

    mapping(uint256 => Intent) private _intents; // intentId => Intent
    mapping(uint256 => mapping(uint256 => FulfillmentProposal)) private _fulfillmentProposals; // intentId => proposalId => FulfillmentProposal

    mapping(address => bool) private _attestors; // address => canAttest

    mapping(uint256 => ProtocolProposal) private _protocolProposals; // proposalId => ProtocolProposal

    mapping(CognitiveModule => ModuleCriteria) private _moduleUnlockCriteria;

    bool private _isGovernanceModuleEnabled; // Global switch for DAO functionality

    // --- Constructor ---

    constructor() ERC721("AetherForge Agent Core", "AFAC") Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyAgentOwner(uint256 _tokenId) {
        require(_agentCores[_tokenId].owner == msg.sender, "AetherForge: Only agent owner can perform this action.");
        _;
    }

    modifier onlyAttestor() {
        require(_attestors[msg.sender], "AetherForge: Caller is not a registered attestor.");
        _;
    }

    modifier onlyAgentWithModule(uint256 _agentId, CognitiveModule _moduleId) {
        require(_agentCores[_agentId].unlockedModules[_moduleId], "AetherForge: Agent does not have this module unlocked.");
        _;
    }

    // --- I. Core Protocol Management ---

    /// @notice Sets whether an address can act as an attestor.
    /// @dev Only callable by the contract owner.
    /// @param _attestor The address to set as an attestor.
    /// @param _canAttest True to grant permission, false to revoke.
    function setAttestor(address _attestor, bool _canAttest) public onlyOwner {
        _attestors[_attestor] = _canAttest;
        emit AttestorSet(_attestor, _canAttest);
    }

    /// @notice Defines the criteria for unlocking a specific Cognitive Module.
    /// @dev Only callable by the contract owner.
    /// @param _moduleId The CognitiveModule to configure.
    /// @param _criteriaType The type of criteria (e.g., "AFFINITY_THRESHOLD").
    /// @param _value The value associated with the criteria.
    function setModuleCriteria(
        CognitiveModule _moduleId,
        bytes32 _criteriaType,
        uint256 _value
    ) public onlyOwner {
        require(_moduleId != CognitiveModule.None, "AetherForge: Cannot set criteria for None module.");
        _moduleUnlockCriteria[_moduleId] = ModuleCriteria(_criteriaType, _value);
        emit ModuleCriteriaSet(_moduleId, _criteriaType, _value);
    }

    /// @notice Globally enables or disables the protocol's governance module.
    /// @dev Only callable by the contract owner.
    /// @param _enabled True to enable, false to disable.
    function setGovernanceModuleEnabled(bool _enabled) public onlyOwner {
        _isGovernanceModuleEnabled = _enabled;
        emit GovernanceModuleEnabledSet(_enabled);
    }

    // `renounceOwnership` is inherited from Ownable and requires no modification here.

    // --- II. Agent Core Management (Soul-Bound NFT) ---

    /// @notice Mints a new non-transferable Agent Core NFT for the caller.
    /// @dev Each address can only mint one Agent Core.
    /// @return The tokenId of the newly minted Agent Core.
    function mintAgentCore() public nonReentrant returns (uint256) {
        require(_agentCoreByOwner[msg.sender] == 0, "AetherForge: Caller already owns an Agent Core.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, ""); // URI can be updated later

        AgentCoreData storage agentData = _agentCores[newTokenId];
        agentData.owner = msg.sender;
        agentData.affinity = 0; // Initialize affinity
        agentData.unlockedModules[CognitiveModule.None] = true; // Default module
        _agentCoreByOwner[msg.sender] = newTokenId;

        emit AgentCoreMinted(newTokenId, msg.sender, "");
        return newTokenId;
    }

    /// @notice Allows an Agent Core owner to update their NFT's metadata URI.
    /// @param _tokenId The ID of the Agent Core NFT.
    /// @param _newURI The new URI for the metadata.
    function updateAgentMetadataURI(uint256 _tokenId, string memory _newURI) public onlyAgentOwner(_tokenId) {
        _setTokenURI(_tokenId, _newURI);
        emit AgentMetadataUpdated(_tokenId, _newURI);
    }

    /// @notice Allows an Agent Core owner to destroy their core and associated data.
    /// @dev This action is irreversible.
    /// @param _tokenId The ID of the Agent Core NFT to burn.
    function burnAgentCore(uint256 _tokenId) public onlyAgentOwner(_tokenId) nonReentrant {
        _burn(_tokenId);
        delete _agentCores[_tokenId];
        delete _agentCoreByOwner[msg.sender];
        emit AgentCoreBurned(_tokenId, msg.sender);
    }

    /// @notice Retrieves the owner of a given Agent Core ID.
    /// @param _tokenId The ID of the Agent Core NFT.
    /// @return The address of the owner.
    function getAgentCoreOwner(uint256 _tokenId) public view returns (address) {
        return _agentCores[_tokenId].owner;
    }

    /// @notice Checks if a given address currently owns an Agent Core NFT.
    /// @param _owner The address to check.
    /// @return True if the address owns an Agent Core, false otherwise.
    function hasAgentCore(address _owner) public view returns (bool) {
        return _agentCoreByOwner[_owner] != 0;
    }

    /// @dev Overrides `_beforeTokenTransfer` to enforce non-transferability (SBT behavior).
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param tokenId The ID of the token being transferred.
    /// @param batchSize This parameter is not used in ERC721 but is part of the ERC1155 interface, retained for compatibility.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize // Kept for compatibility with base ERC721 definition, but not used.
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfers of Agent Cores once minted.
        // Allowed operations: minting (from address(0) to user) or burning (from user to address(0)).
        if (from != address(0) && to != address(0)) {
            revert("AetherForge: Agent Cores are non-transferable (SBT).");
        }
    }

    // The following functions are required for ERC721 and ERC721Enumerable, but their usage for this SBT might be limited.
    // They are left as inherited but `_beforeTokenTransfer` effectively makes `transferFrom`, `safeTransferFrom` unusable for actual transfers.
    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        revert("AetherForge: Agent Cores cannot be approved for transfer.");
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal override(ERC721) {
        revert("AetherForge: Agent Cores cannot be approved for transfer.");
    }

    // --- III. Agent Affinity & Attestation (Reputation System) ---

    /// @notice Internal function to adjust an Agent's affinity score.
    /// @dev This function should only be called internally or by trusted attestors via `attestAgentPerformance`.
    /// @param _agentId The ID of the Agent whose affinity is being adjusted.
    /// @param _actionType The type of action leading to the affinity change.
    /// @param _scoreDelta The change in affinity score (can be positive or negative).
    function recordAffinityAction(
        uint256 _agentId,
        AffinityActionType _actionType,
        int256 _scoreDelta
    ) internal {
        AgentCoreData storage agentData = _agentCores[_agentId];
        require(agentData.owner != address(0), "AetherForge: Agent does not exist.");

        // Safe add/subtract for int256
        if (_scoreDelta > 0) {
            agentData.affinity = agentData.affinity.add(uint256(_scoreDelta));
        } else {
            agentData.affinity = agentData.affinity.sub(uint256(-_scoreDelta));
        }

        emit AffinityRecorded(_agentId, _actionType, _scoreDelta, uint256(agentData.affinity));
    }

    /// @notice Allows designated attestors to record an Agent's performance for a specific task.
    /// @dev This directly impacts the Agent's Affinity score.
    /// @param _agentId The ID of the Agent being attested.
    /// @param _actionIdentifier A unique identifier for the specific action/task (e.g., hash of intentId+fulfillmentId).
    /// @param _success True if the performance was successful, false otherwise.
    function attestAgentPerformance(
        uint256 _agentId,
        bytes32 _actionIdentifier,
        bool _success
    ) public onlyAttestor nonReentrant {
        int256 scoreDelta = _success ? 100 : -50; // Example: +100 for success, -50 for failure
        recordAffinityAction(_agentId, _success ? AffinityActionType.AttestationPositive : AffinityActionType.AttestationNegative, scoreDelta);
        emit AttestationRecorded(_agentId, msg.sender, _actionIdentifier, _success);
    }

    /// @notice Retrieves the current affinity (reputation) score of a specified Agent.
    /// @param _agentId The ID of the Agent.
    /// @return The Agent's current affinity score.
    function getAgentAffinity(uint256 _agentId) public view returns (int256) {
        return _agentCores[_agentId].affinity;
    }

    /// @notice Fetches a list of all recorded attestations for a given Agent Core.
    /// @dev For simplicity, this returns a placeholder; a real implementation might store attestations in an array or a more complex structure.
    /// @param _agentId The ID of the Agent.
    /// @return An array of (attestor, actionIdentifier, success) tuples.
    function getAttestationsForAgent(uint256 _agentId) public view returns (address[] memory attestors, bytes32[] memory actionIdentifiers, bool[] memory successes) {
        // Placeholder implementation. A real system would require mapping from agentId to an array of attestations.
        // This is omitted for brevity to keep the contract under size limits, as it would require significant storage.
        // For production, consider storing attestation IDs and allowing retrieval of individual attestations by ID.
        // Or, use an off-chain indexing solution for querying historical events.
        return (new address[](0), new bytes32[](0), new bool[](0));
    }

    // --- IV. Cognitive Modules (Programmable Traits) ---

    /// @notice Allows an Agent to unlock a specific Cognitive Module if they meet the predefined criteria.
    /// @dev Module unlock criteria are set by the contract owner via `setModuleCriteria`.
    /// @param _agentId The ID of the Agent.
    /// @param _moduleId The CognitiveModule to unlock.
    function unlockCognitiveModule(uint256 _agentId, CognitiveModule _moduleId) public onlyAgentOwner(_agentId) {
        require(_moduleId != CognitiveModule.None, "AetherForge: Cannot unlock None module.");
        require(!_agentCores[_agentId].unlockedModules[_moduleId], "AetherForge: Module already unlocked.");

        ModuleCriteria storage criteria = _moduleUnlockCriteria[_moduleId];
        require(criteria.criteriaType != bytes32(0), "AetherForge: No criteria defined for this module.");

        // Example criteria check: AFFINITY_THRESHOLD
        if (criteria.criteriaType == "AFFINITY_THRESHOLD") {
            require(uint256(_agentCores[_agentId].affinity) >= criteria.value, "AetherForge: Affinity too low to unlock module.");
        }
        // Extend with more criteria types as needed (e.g., INTERACTION_COUNT)

        _agentCores[_agentId].unlockedModules[_moduleId] = true;
        emit CognitiveModuleUnlocked(_agentId, _moduleId);
    }

    /// @notice Checks if a specific Cognitive Module has been unlocked for an Agent.
    /// @param _agentId The ID of the Agent.
    /// @param _moduleId The CognitiveModule to check.
    /// @return True if the module is unlocked, false otherwise.
    function isModuleUnlocked(uint256 _agentId, CognitiveModule _moduleId) public view returns (bool) {
        return _agentCores[_agentId].unlockedModules[_moduleId];
    }

    /// @notice Retrieves an array of all Cognitive Modules that a given Agent has successfully unlocked.
    /// @dev This iterates through all possible module types.
    /// @param _agentId The ID of the Agent.
    /// @return An array of unlocked CognitiveModules.
    function getAgentUnlockedModules(uint256 _agentId) public view returns (CognitiveModule[] memory) {
        require(_agentCores[_agentId].owner != address(0), "AetherForge: Agent does not exist.");

        uint256 moduleCount = 0;
        // Max enum value is 4 for CognitiveModule.DisputeMediator
        for (uint256 i = 1; i <= uint256(CognitiveModule.DisputeMediator); i++) {
            if (_agentCores[_agentId].unlockedModules[CognitiveModule(i)]) {
                moduleCount++;
            }
        }

        CognitiveModule[] memory unlocked = new CognitiveModule[](moduleCount);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= uint256(CognitiveModule.DisputeMediator); i++) {
            if (_agentCores[_agentId].unlockedModules[CognitiveModule(i)]) {
                unlocked[currentIdx] = CognitiveModule(i);
                currentIdx++;
            }
        }
        return unlocked;
    }

    // --- V. Agent Intent Management ---

    /// @notice An Agent declares a new Intent.
    /// @param _agentId The ID of the Agent.
    /// @param _intentType The type of intent (e.g., Contribution, ServiceRequest).
    /// @param _intentURI A URI pointing to detailed off-chain information about the intent.
    /// @param _expiration The timestamp when the intent expires.
    /// @return The ID of the newly registered intent.
    function registerAgentIntent(
        uint256 _agentId,
        IntentType _intentType,
        string memory _intentURI,
        uint256 _expiration
    ) public onlyAgentOwner(_agentId) nonReentrant returns (uint256) {
        require(_expiration > block.timestamp, "AetherForge: Intent expiration must be in the future.");

        _intents[_intentIdCounter.current()].intentIdCounter.increment(); // Ensure counter is initialized if first intent for agent
        _intentIdCounter.increment();
        uint256 newIntentId = _intentIdCounter.current();

        Intent storage newIntent = _intents[newIntentId];
        newIntent.agentId = _agentId;
        newIntent.intentType = _intentType;
        newIntent.intentURI = _intentURI;
        newIntent.expiration = _expiration;
        newIntent.active = true;

        emit IntentRegistered(_agentId, newIntentId, _intentType, _intentURI, _expiration);
        return newIntentId;
    }

    /// @notice An Agent updates an existing Intent.
    /// @param _agentId The ID of the Agent.
    /// @param _intentId The ID of the intent to update.
    /// @param _newIntentURI The new URI for the intent's details.
    /// @param _newExpiration The new expiration timestamp.
    function updateAgentIntent(
        uint256 _agentId,
        uint256 _intentId,
        string memory _newIntentURI,
        uint256 _newExpiration
    ) public onlyAgentOwner(_agentId) {
        Intent storage intent = _intents[_intentId];
        require(intent.agentId == _agentId, "AetherForge: Intent not owned by this agent.");
        require(intent.active, "AetherForge: Intent is not active.");
        require(_newExpiration > block.timestamp, "AetherForge: New expiration must be in the future.");

        intent.intentURI = _newIntentURI;
        intent.expiration = _newExpiration;

        emit IntentUpdated(_agentId, _intentId, _newIntentURI, _newExpiration);
    }

    /// @notice An Agent revokes an active Intent.
    /// @param _agentId The ID of the Agent.
    /// @param _intentId The ID of the intent to revoke.
    function revokeAgentIntent(uint256 _agentId, uint256 _intentId) public onlyAgentOwner(_agentId) {
        Intent storage intent = _intents[_intentId];
        require(intent.agentId == _agentId, "AetherForge: Intent not owned by this agent.");
        require(intent.active, "AetherForge: Intent is already inactive.");

        intent.active = false;
        // Optionally, handle active fulfillment proposals related to this intent.

        emit IntentRevoked(_agentId, _intentId);
    }

    /// @notice Retrieves all active Intents registered by a specific Agent.
    /// @dev This function iterates through all intents, which can be gas-intensive for many intents.
    ///      Consider an off-chain indexer for production.
    /// @param _agentId The ID of the Agent.
    /// @return An array of Intent IDs.
    function getAgentIntents(uint256 _agentId) public view returns (uint256[] memory) {
        require(_agentCores[_agentId].owner != address(0), "AetherForge: Agent does not exist.");

        uint256[] memory agentIntents = new uint256[](_intentIdCounter.current()); // Max possible size
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= _intentIdCounter.current(); i++) {
            if (_intents[i].agentId == _agentId && _intents[i].active && _intents[i].expiration > block.timestamp) {
                agentIntents[currentIdx] = i;
                currentIdx++;
            }
        }

        uint256[] memory filteredIntents = new uint256[](currentIdx);
        for (uint256 i = 0; i < currentIdx; i++) {
            filteredIntents[i] = agentIntents[i];
        }
        return filteredIntents;
    }

    /// @notice Allows external parties to query active Intents based on criteria.
    /// @dev This function iterates through all intents, which can be gas-intensive for many intents.
    ///      Consider an off-chain indexer for production.
    /// @param _intentType The type of intent to search for (use IntentType(0) for any type).
    /// @param _minAffinity The minimum affinity an Agent must have to be included.
    /// @param _maxResults The maximum number of results to return.
    /// @return An array of matching Intent IDs.
    function discoverIntents(
        IntentType _intentType,
        uint256 _minAffinity,
        uint256 _maxResults
    ) public view returns (uint256[] memory) {
        require(_maxResults > 0, "AetherForge: Max results must be greater than zero.");

        uint256[] memory discovered = new uint256[](_maxResults);
        uint256 currentCount = 0;

        for (uint256 i = 1; i <= _intentIdCounter.current(); i++) {
            Intent storage intent = _intents[i];
            if (intent.active && intent.expiration > block.timestamp) {
                if (_intentType == IntentType(0) || intent.intentType == _intentType) {
                    if (uint256(_agentCores[intent.agentId].affinity) >= _minAffinity) {
                        if (currentCount < _maxResults) {
                            discovered[currentCount] = i;
                            currentCount++;
                        } else {
                            break; // Max results reached
                        }
                    }
                }
            }
        }

        uint256[] memory filteredDiscovered = new uint256[](currentCount);
        for (uint256 i = 0; i < currentCount; i++) {
            filteredDiscovered[i] = discovered[i];
        }
        return filteredDiscovered;
    }

    // --- VI. Intent Fulfillment & Dispute Resolution ---

    /// @notice An external party (proposer) offers to fulfill an Agent's declared Intent.
    /// @param _intentId The ID of the Intent to fulfill.
    /// @param _fulfillmentDetailsURI A URI pointing to detailed off-chain information about the proposed fulfillment.
    /// @param _collateral Optional ETH collateral provided by the proposer.
    /// @return The ID of the newly created fulfillment proposal.
    function proposeIntentFulfillment(
        uint256 _intentId,
        string memory _fulfillmentDetailsURI,
        uint256 _collateral
    ) public payable nonReentrant returns (uint256) {
        Intent storage intent = _intents[_intentId];
        require(intent.active && intent.expiration > block.timestamp, "AetherForge: Intent is not active or expired.");
        require(msg.value == _collateral, "AetherForge: Sent ETH must match collateral value.");

        intent.fulfillmentProposalIdCounter.increment();
        uint256 newProposalId = intent.fulfillmentProposalIdCounter.current();

        FulfillmentProposal storage proposal = _fulfillmentProposals[_intentId][newProposalId];
        proposal.intentId = _intentId;
        proposal.proposer = msg.sender;
        proposal.fulfillmentDetailsURI = _fulfillmentDetailsURI;
        proposal.collateral = _collateral;
        proposal.accepted = false;
        proposal.confirmed = false;
        proposal.disputed = false;

        emit FulfillmentProposed(_intentId, newProposalId, msg.sender, _fulfillmentDetailsURI, _collateral);
        return newProposalId;
    }

    /// @notice The Agent whose Intent is being addressed accepts a specific fulfillment proposal.
    /// @param _intentId The ID of the Intent.
    /// @param _fulfillmentProposalId The ID of the fulfillment proposal to accept.
    function acceptIntentFulfillment(uint256 _intentId, uint256 _fulfillmentProposalId) public onlyAgentOwner(_intents[_intentId].agentId) {
        Intent storage intent = _intents[_intentId];
        FulfillmentProposal storage proposal = _fulfillmentProposals[_intentId][_fulfillmentProposalId];

        require(intent.active && intent.expiration > block.timestamp, "AetherForge: Intent is not active or expired.");
        require(proposal.intentId == _intentId, "AetherForge: Invalid fulfillment proposal for this intent.");
        require(!proposal.accepted, "AetherForge: Proposal already accepted.");
        require(!proposal.disputed, "AetherForge: Proposal is in dispute.");

        proposal.accepted = true;

        emit FulfillmentAccepted(_intentId, _fulfillmentProposalId);
    }

    /// @notice The Agent confirms that their Intent has been successfully fulfilled.
    /// @dev This triggers affinity updates for both parties and releases collateral (if any).
    /// @param _intentId The ID of the Intent.
    /// @param _fulfillmentProposalId The ID of the confirmed fulfillment proposal.
    function confirmIntentFulfillment(uint256 _intentId, uint256 _fulfillmentProposalId) public onlyAgentOwner(_intents[_intentId].agentId) nonReentrant {
        Intent storage intent = _intents[_intentId];
        FulfillmentProposal storage proposal = _fulfillmentProposals[_intentId][_fulfillmentProposalId];

        require(intent.active, "AetherForge: Intent is not active.");
        require(proposal.accepted, "AetherForge: Proposal not accepted yet.");
        require(!proposal.confirmed, "AetherForge: Fulfillment already confirmed.");
        require(!proposal.disputed, "AetherForge: Fulfillment is in dispute.");

        proposal.confirmed = true;
        intent.active = false; // Intent is considered fulfilled and becomes inactive

        // Reward logic: Proposer gets their collateral back, plus maybe a bonus from the agent (not implemented here)
        uint256 payout = proposal.collateral;
        if (payout > 0) {
            (bool sent, ) = payable(proposal.proposer).call{value: payout}("");
            require(sent, "AetherForge: Failed to send collateral to proposer.");
        }

        // Update affinity for both agent (positive for successful fulfillment) and proposer (positive for success)
        recordAffinityAction(intent.agentId, AffinityActionType.IntentFulfillmentConfirmed, 50); // Agent
        recordAffinityAction(_agentCoreByOwner[proposal.proposer], AffinityActionType.IntentFulfillmentConfirmed, 75); // Proposer

        emit FulfillmentConfirmed(_intentId, _fulfillmentProposalId, payout);
    }

    /// @notice If fulfillment is unsatisfactory or incomplete, the Agent can formally dispute it.
    /// @param _intentId The ID of the Intent.
    /// @param _fulfillmentProposalId The ID of the disputed fulfillment proposal.
    /// @param _disputeReasonURI A URI pointing to detailed off-chain information about the dispute.
    function disputeIntentFulfillment(
        uint256 _intentId,
        uint256 _fulfillmentProposalId,
        string memory _disputeReasonURI
    ) public onlyAgentOwner(_intents[_intentId].agentId) {
        Intent storage intent = _intents[_intentId];
        FulfillmentProposal storage proposal = _fulfillmentProposals[_intentId][_fulfillmentProposalId];

        require(intent.active, "AetherForge: Intent is not active.");
        require(proposal.accepted, "AetherForge: Proposal not accepted yet.");
        require(!proposal.confirmed, "AetherForge: Fulfillment already confirmed.");
        require(!proposal.disputed, "AetherForge: Fulfillment already in dispute.");

        proposal.disputed = true;

        // Apply a small negative affinity as a temporary measure until resolution
        recordAffinityAction(intent.agentId, AffinityActionType.IntentFulfillmentDisputed, -10); // Agent for dispute
        recordAffinityAction(_agentCoreByOwner[proposal.proposer], AffinityActionType.IntentFulfillmentDisputed, -20); // Proposer for being disputed

        emit FulfillmentDisputed(_intentId, _fulfillmentProposalId, _disputeReasonURI);
    }

    /// @notice An administrative or DAO function to resolve a disputed intent fulfillment.
    /// @dev This function transfers collateral and adjusts affinity based on the dispute outcome.
    /// @param _intentId The ID of the Intent.
    /// @param _fulfillmentProposalId The ID of the disputed fulfillment proposal.
    /// @param _winner The address of the party deemed to have won the dispute (Agent owner or Proposer).
    /// @param _penaltyRatio The percentage of collateral to be penalized from the loser (e.g., 5000 for 50%).
    function resolveDispute(
        uint256 _intentId,
        uint256 _fulfillmentProposalId,
        address _winner,
        uint256 _penaltyRatio
    ) public onlyOwner nonReentrant { // Can be made callable by DAO if Governance module active
        Intent storage intent = _intents[_intentId];
        FulfillmentProposal storage proposal = _fulfillmentProposals[_intentId][_fulfillmentProposalId];

        require(proposal.disputed, "AetherForge: Fulfillment is not in dispute.");
        require(_penaltyRatio <= 10000, "AetherForge: Penalty ratio cannot exceed 100%");

        address agentOwner = _agentCores[intent.agentId].owner;
        address proposer = proposal.proposer;

        require(_winner == agentOwner || _winner == proposer, "AetherForge: Winner must be the agent owner or proposer.");

        uint256 collateralToTransfer = proposal.collateral;
        uint256 penaltyAmount = collateralToTransfer.mul(_penaltyRatio).div(10000); // e.g. 5000/10000 = 0.5

        address loser;
        address recipient;
        int256 winnerAffinityDelta;
        int256 loserAffinityDelta;

        if (_winner == agentOwner) {
            // Agent wins: Proposer loses penalty, Agent gets their due
            loser = proposer;
            recipient = agentOwner;
            winnerAffinityDelta = 75; // Agent affinity boost
            loserAffinityDelta = -100; // Proposer affinity penalty
        } else { // _winner == proposer
            // Proposer wins: Agent loses penalty, Proposer gets collateral back
            loser = agentOwner;
            recipient = proposer;
            winnerAffinityDelta = 75; // Proposer affinity boost
            loserAffinityDelta = -100; // Agent affinity penalty
        }

        // Transfer collateral, applying penalty
        uint256 winnerShare = collateralToTransfer.sub(penaltyAmount);
        uint256 loserPenaltyProceeds = penaltyAmount; // This could go to a DAO treasury or be burned

        if (winnerShare > 0) {
            (bool sent, ) = payable(recipient).call{value: winnerShare}("");
            require(sent, "AetherForge: Failed to transfer winner's share.");
        }
        // LoserPenaltyProceeds are not sent anywhere for simplicity, remain in contract.
        // In a real system, they might go to a DAO treasury, a burning mechanism, or the mediator.

        recordAffinityAction(_agentCoreByOwner[_winner], AffinityActionType.IntentFulfillmentConfirmed, winnerAffinityDelta); // Winner
        recordAffinityAction(_agentCoreByOwner[loser], AffinityActionType.IntentFulfillmentDisputed, loserAffinityDelta); // Loser

        proposal.disputed = false;
        proposal.confirmed = true; // Dispute resolved, consider it confirmed/finalized
        intent.active = false; // Intent is closed after dispute

        emit DisputeResolved(_intentId, _fulfillmentProposalId, _winner, loserPenaltyProceeds);
    }

    // --- VII. Protocol Governance (Lightweight DAO for Evolution) ---

    /// @notice Allows Agents with the Governance module to submit proposals for protocol changes.
    /// @dev Proposals have a voting period of 3 days.
    /// @param _proposalURI A URI pointing to detailed off-chain information about the proposal.
    /// @param _executionCalldata The calldata to execute if the proposal passes (e.g., to call `setAttestor`).
    /// @return The ID of the newly submitted proposal.
    function submitProtocolProposal(string memory _proposalURI, bytes memory _executionCalldata) public nonReentrant returns (uint256) {
        uint256 agentId = _agentCoreByOwner[msg.sender];
        require(agentId != 0, "AetherForge: Caller does not own an Agent Core.");
        require(_agentCores[agentId].unlockedModules[CognitiveModule.Governance], "AetherForge: Agent does not have Governance module unlocked.");
        require(_isGovernanceModuleEnabled, "AetherForge: Governance module is currently disabled.");

        _protocolProposalIdCounter.increment();
        uint256 newProposalId = _protocolProposalIdCounter.current();

        _protocolProposals[newProposalId] = ProtocolProposal({
            proposer: msg.sender,
            proposalURI: _proposalURI,
            executionCalldata: _executionCalldata,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + 3 days, // Example: 3 days voting period
            yeas: 0,
            nays: 0,
            executed: false
        });

        emit ProtocolProposalSubmitted(newProposalId, msg.sender, _proposalURI);
        return newProposalId;
    }

    /// @notice Allows Agents to vote on active protocol proposals.
    /// @dev Voting power could be influenced by affinity or other modules (not implemented in this simple version).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'yay' vote, false for a 'nay' vote.
    function voteOnProtocolProposal(uint256 _proposalId, bool _support) public nonReentrant {
        ProtocolProposal storage proposal = _protocolProposals[_proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist.");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "AetherForge: Voting is not active.");

        uint256 agentId = _agentCoreByOwner[msg.sender];
        require(agentId != 0, "AetherForge: Caller does not own an Agent Core.");
        require(_agentCores[agentId].unlockedModules[CognitiveModule.Governance], "AetherForge: Agent does not have Governance module unlocked.");
        require(!proposal.hasVoted[agentId], "AetherForge: Agent has already voted on this proposal.");

        if (_support) {
            proposal.yeas++;
        } else {
            proposal.nays++;
        }
        proposal.hasVoted[agentId] = true;

        recordAffinityAction(agentId, AffinityActionType.ProtocolVoteCast, 5); // Small affinity boost for voting

        emit ProtocolVoted(_proposalId, agentId, _support);
    }

    /// @notice Executes a protocol proposal that has successfully passed the voting period and threshold.
    /// @dev Example threshold: 51% 'yeas' and minimum 10 votes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProtocolProposal(uint256 _proposalId) public nonReentrant {
        ProtocolProposal storage proposal = _protocolProposals[_proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist.");
        require(block.timestamp > proposal.voteEndTime, "AetherForge: Voting period is not over.");
        require(!proposal.executed, "AetherForge: Proposal already executed.");

        uint256 totalVotes = proposal.yeas.add(proposal.nays);
        uint256 minVotesRequired = 5; // Example: Minimum number of votes
        uint256 passingThresholdNumerator = 51; // Example: 51% to pass
        uint256 passingThresholdDenominator = 100;

        require(totalVotes >= minVotesRequired, "AetherForge: Not enough votes to reach quorum.");
        require(proposal.yeas.mul(passingThresholdDenominator) > totalVotes.mul(passingThresholdNumerator), "AetherForge: Proposal did not pass.");

        proposal.executed = true;

        // Execute the calldata specified in the proposal
        (bool success, ) = address(this).call(proposal.executionCalldata);
        require(success, "AetherForge: Proposal execution failed.");

        emit ProtocolProposalExecuted(_proposalId);
    }

    // --- ERC721Enumerable and ERC721URIStorage overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return "ipfs://baseuri/"; // A placeholder base URI
    }
}
```