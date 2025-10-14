Here's a Solidity smart contract, `ChronoForgeCollective`, designed with interesting, advanced, creative, and trendy functions. It integrates concepts like dynamic NFTs, AI oracle attestations, advanced DAO governance, temporal mechanics, and verifiable ephemeral data, while building upon foundational OpenZeppelin libraries.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline: ChronoForge Collective ---
//
// The ChronoForge Collective is a decentralized autonomous organization (DAO) designed to manage
// and evolve digital entities (ChronoEntities) using a native utility token (ChronoEssence).
// It explores advanced concepts like dynamic NFT attributes influenced by AI oracles,
// sophisticated governance combining token and NFT voting power, and temporal mechanics.
//
// I. Core Tokens & Assets
//    - ChronoEssence (ERC20): The native utility and governance token of the collective.
//    - ChronoEntities (Dynamic NFTs): Unique digital beings represented as NFTs,
//      possessing mutable attributes like 'AuraLevel', 'InsightScore', and 'AdaptabilityFactor'.
//
// II. ChronoEntity Lifecycle & Evolution
//    - Spawning (Minting): Creation of new ChronoEntities with initial attributes.
//    - DAO-Governed Evolution: Attributes can be updated through collective proposals and votes.
//    - AI Oracle-Driven Adaptation: Trusted off-chain AI systems can provide verifiable attestations
//      to dynamically update entity attributes, simulating real-world data influence.
//
// III. Collective Governance & Resource Management
//    - Proposal System: Enables members to propose entity evolutions, treasury spends,
//      protocol parameter changes, and AI oracle updates.
//    - Advanced Voting Mechanism: Voting power is derived from a combination of ChronoEssence
//      token holdings and the attributes of owned or delegated ChronoEntities, adding depth to governance.
//    - Delegation: Members can delegate their token and entity voting power to others, fostering expertise.
//    - DAO Treasury: Manages ChronoEssence for protocol operations, entity funding, or community initiatives.
//
// IV. Temporal & Advanced Mechanics
//    - Attribute Decay: Certain entity attributes (e.g., 'AuraLevel') can decay over time,
//      encouraging active engagement or resource allocation to maintain entities.
//    - Inter-Entity Operations ('Influence Fusion'): Allows owners to combine the essence
//      or attributes of multiple entities, leading to unique evolutionary paths.
//    - Ephemeral Insights: Non-transferable, time-bound attestations for entities, representing
//      temporary knowledge or achievements, revocable by the registrant.
//    - Dynamic Protocol Parameters: Core rules and thresholds of the collective can be adjusted
//      via DAO proposals, enabling flexible and adaptive governance.
//
// V. Oracle Integration
//    - AI Oracle: A designated external address responsible for submitting verifiable AI-driven
//      attestations that influence ChronoEntity attributes, bridging on-chain and off-chain intelligence.

// --- Function Summary (24 Functions) ---
//
// I. Core Setup and Asset Management:
// 1. constructor(): Initializes ChronoEssence (ERC20) and ChronoEntities (ERC721) tokens, and sets initial protocol parameters and AI oracle.
// 2. mintEssence(address _to, uint256 _amount): Mints new ChronoEssence tokens, initially restricted to the contract owner.
// 3. spawnChronoEntity(address _to, string memory _initialName): Mints a new ChronoEntity NFT for a given address, assigning initial mutable attributes and requiring a small ETH fee.
// 4. getEntityAttributes(uint256 _tokenId): Retrieves the 'AuraLevel', 'InsightScore', and 'AdaptabilityFactor' of a specified ChronoEntity.
//
// II. Entity Evolution & AI Integration:
// 5. proposeEvolutionTrigger(uint256 _tokenId, string memory _attributeKey, uint256 _targetValue, bytes32 _externalDataHash, string memory _description): Creates a DAO proposal to update a ChronoEntity's attribute to a target value, potentially referencing off-chain data.
// 6. executeEvolution(uint256 _proposalId): Executes a successfully passed entity evolution proposal, applying attribute changes.
// 7. submitOracleAIAttestation(uint256 _tokenId, string memory _attributeKey, uint256 _newValue, bytes32 _proofHash): Allows the designated AI Oracle to update an entity's attribute based on off-chain analysis and a verifiable proof.
// 8. requestAIAttestation(uint256 _tokenId, string memory _attributeKey): Signals an intent to request an AI attestation for a specific entity attribute, triggering potential off-chain processes.
//
// III. Governance & Treasury:
// 9. proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description): Initiates a DAO proposal to spend ChronoEssence from the collective's treasury.
// 10. setProtocolParameter(bytes32 _paramKey, uint256 _newValue): Allows the DAO to propose and vote on updating core protocol parameters (e.g., voting period, quorum).
// 11. setChronoForgeOracle(address _newOracle): Enables the DAO to propose and vote on changing the address of the trusted AI Oracle.
// 12. vote(uint256 _proposalId, ProposalType _type, bool _approve): A general function for eligible voters to cast a 'for' or 'against' vote on any proposal type.
// 13. voteOnEvolutionTrigger(uint256 _proposalId, bool _approve): Specific wrapper for voting on entity evolution proposals.
// 14. voteOnTreasurySpend(uint256 _proposalId, bool _approve): Specific wrapper for voting on treasury spend proposals.
// 15. executeProposal(uint256 _proposalId, ProposalType _type): A general function to execute any successfully passed proposal.
// 16. getVotingPower(address _voter): Calculates the total effective voting power for an address, considering their non-delegated ChronoEssence and owned/delegated ChronoEntities.
// 17. getProposalState(uint256 _proposalId, ProposalType _type): Retrieves the current state of a given proposal (e.g., Active, Passed, Failed, Canceled, Executed).
// 18. cancelProposal(uint256 _proposalId, ProposalType _type): Allows the proposer to cancel their own proposal if it has not yet been executed.
//
// IV. Advanced Mechanics:
// 19. delegateVotingPower(address _delegatee): Delegates the caller's ChronoEssence voting power to another address.
// 20. delegateEntityVotingPower(uint256 _tokenId, address _delegatee): Delegates the voting power associated with a specific ChronoEntity to another address.
// 21. triggerAuraDecay(uint256 _tokenId): Public function to apply the predefined decay logic to an entity's 'AuraLevel' based on elapsed time.
// 22. fuseEntityInfluence(uint256 _tokenId1, uint256 _tokenId2): Allows an entity owner to "fuse" the influence of two of their ChronoEntities, boosting one's attributes at the cost of the other's and a ChronoEssence fee.
// 23. registerEphemeralInsight(uint256 _tokenId, bytes32 _insightHash, uint256 _expirationTime): Registers a temporary, verifiable insight (SBT-like) for an entity, which expires after a set timestamp.
// 24. revokeEphemeralInsight(uint256 _tokenId, bytes32 _insightHash): Allows the original registrant to revoke an ephemeral insight before its expiration.

contract ChronoForgeCollective is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- ChronoEssence (ERC20 Token) ---
    ERC20Burnable public immutable essenceToken;

    // --- ChronoEntities (ERC721 Dynamic NFT) ---
    ERC721 public immutable entityNFT;
    Counters.Counter private _entityTokenIds;

    // --- AI Oracle ---
    address public chronoForgeOracle;

    // --- Core Protocol Parameters (DAO Governed) ---
    mapping(bytes32 => uint256) public protocolParameters;
    bytes32 public constant PARAM_VOTING_PERIOD = keccak256("VOTING_PERIOD"); // in seconds
    bytes32 public constant PARAM_QUORUM_PERCENT = keccak256("QUORUM_PERCENT"); // e.g., 4000 for 40% (40.00%)
    bytes32 public constant PARAM_PROPOSAL_THRESHOLD_ESSENCE = keccak256("PROPOSAL_THRESHOLD_ESSENCE"); // Min Essence to create a proposal
    bytes32 public constant PARAM_ENTITY_BASE_AURA = keccak256("ENTITY_BASE_AURA");
    bytes32 public constant PARAM_ENTITY_BASE_INSIGHT = keccak256("ENTITY_BASE_INSIGHT");
    bytes32 public constant PARAM_ENTITY_BASE_ADAPTABILITY = keccak256("ENTITY_BASE_ADAPTABILITY");
    bytes32 public constant PARAM_DEFAULT_AURA_DECAY_RATE = keccak256("DEFAULT_AURA_DECAY_RATE"); // Amount of aura to decay per 'decay period'
    bytes32 public constant PARAM_AURA_DECAY_PERIOD = keccak256("AURA_DECAY_PERIOD"); // In seconds, how often decay is applied
    bytes32 public constant PARAM_FUSION_ESSENCE_COST = keccak256("FUSION_ESSENCE_COST");

    // --- ChronoEntity Attributes ---
    // tokenId => attributeKey => value
    mapping(uint256 => mapping(string => uint256)) public entityAttributes;
    mapping(uint256 => uint256) public entityLastAuraUpdate; // For decay calculation timestamp

    // --- Ephemeral Insights (SBT-like concept) ---
    // tokenId => insightHash => { registrant, expirationTime }
    struct EphemeralInsight {
        address registrant;
        uint256 expirationTime;
    }
    mapping(uint256 => mapping(bytes32 => EphemeralInsight)) public ephemeralInsights;

    // --- Governance System ---
    enum ProposalType { EvolutionTrigger, TreasurySpend, ProtocolParameter, OracleUpdate }
    enum ProposalState { Pending, Active, Passed, Failed, Executed, Canceled }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled; // True if the proposer canceled the proposal
        bytes data; // Encoded call data for execution
        string description;
        mapping(address => bool) hasVoted; // Voter address => hasVoted for this specific proposal
    }

    mapping(uint256 => Proposal) public evolutionProposals; // Proposal ID => EvolutionTrigger Proposal
    mapping(uint256 => Proposal) public treasuryProposals; // Proposal ID => TreasurySpend Proposal
    mapping(uint256 => Proposal) public parameterProposals; // Proposal ID => ProtocolParameter Proposal
    mapping(uint256 => Proposal) public oracleProposals; // Proposal ID => OracleUpdate Proposal

    Counters.Counter private _proposalIds;

    // --- Delegation (for voting power) ---
    mapping(address => address) public essenceDelegates; // delegator => delegatee (who my essence votes for)
    mapping(uint256 => address) public entityDelegates; // tokenId => delegatee (who this specific entity votes for)

    // --- Events ---
    event ChronoEssenceMinted(address indexed to, uint256 amount);
    event ChronoEntitySpawned(uint256 indexed tokenId, address indexed owner, string initialName);
    event EntityAttributesUpdated(uint256 indexed tokenId, string attributeKey, uint256 oldValue, uint256 newValue, address indexed updater, string updateType);
    event EvolutionProposalCreated(uint256 indexed proposalId, uint256 indexed tokenId, string attributeKey, uint256 targetValue, bytes32 externalDataHash, address indexed proposer);
    event TreasurySpendProposalCreated(uint256 indexed proposalId, address indexed recipient, uint256 amount, address indexed proposer);
    event ProtocolParameterProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, address indexed proposer);
    event OracleUpdateProposalCreated(uint256 indexed proposalId, address newOracle, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, ProposalType pType, address indexed voter, bool approved, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, ProposalType pType, bool success);
    event ProposalCanceled(uint256 indexed proposalId, ProposalType pType, address indexed canceller);
    event OracleAIAttestationSubmitted(uint256 indexed tokenId, string attributeKey, uint256 newValue, bytes32 proofHash, address indexed oracle);
    event AIAttestationRequested(uint256 indexed tokenId, string attributeKey, address indexed requester);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event EntityVotingPowerDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event AuraDecayTriggered(uint256 indexed tokenId, uint256 oldAura, uint256 newAura);
    event EntityInfluenceFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 boostedTokenId, uint256 essenceCost);
    event EphemeralInsightRegistered(uint256 indexed tokenId, bytes32 insightHash, address indexed registrant, uint256 expirationTime);
    event EphemeralInsightRevoked(uint256 indexed tokenId, bytes32 insightHash, address indexed revoker);

    constructor(address initialOwner) Ownable(initialOwner) {
        essenceToken = new ERC20Burnable("ChronoEssence", "ESSENCE");
        entityNFT = new ERC721("ChronoEntity", "CHRONOE");

        chronoForgeOracle = initialOwner; // Initial oracle can be owner, then DAO changes it.

        // Initialize core protocol parameters
        protocolParameters[PARAM_VOTING_PERIOD] = 3 days;
        protocolParameters[PARAM_QUORUM_PERCENT] = 4000; // 40.00%
        protocolParameters[PARAM_PROPOSAL_THRESHOLD_ESSENCE] = 1000 * 10 ** 18; // 1000 ESSENCE
        protocolParameters[PARAM_ENTITY_BASE_AURA] = 100;
        protocolParameters[PARAM_ENTITY_BASE_INSIGHT] = 10;
        protocolParameters[PARAM_ENTITY_BASE_ADAPTABILITY] = 50;
        protocolParameters[PARAM_DEFAULT_AURA_DECAY_RATE] = 1; // 1 Aura point
        protocolParameters[PARAM_AURA_DECAY_PERIOD] = 1 days; // Every day
        protocolParameters[PARAM_FUSION_ESSENCE_COST] = 500 * 10 ** 18; // 500 ESSENCE for fusion
    }

    // --- I. Core Setup and Asset Management ---

    // 2. mintEssence: Mints new ChronoEssence tokens.
    function mintEssence(address _to, uint256 _amount) public onlyOwner { // Initially onlyOwner, later DAO could control this
        essenceToken.mint(_to, _amount);
        emit ChronoEssenceMinted(_to, _amount);
    }

    // 3. spawnChronoEntity: Mints a new ChronoEntity NFT.
    function spawnChronoEntity(address _to, string memory _initialName) public payable nonReentrant returns (uint256) {
        require(msg.value >= 0.01 ether, "ChronoForge: Requires a minimal ETH fee to spawn an entity."); // Simple fee for spawning
        _entityTokenIds.increment();
        uint256 newItemId = _entityTokenIds.current();
        entityNFT.safeMint(_to, newItemId);

        // Assign initial attributes
        // Storing hash of name for privacy/immutability, or can be a string URI for external metadata.
        entityAttributes[newItemId]["NameHash"] = uint256(keccak256(abi.encodePacked(_initialName)));
        entityAttributes[newItemId]["AuraLevel"] = protocolParameters[PARAM_ENTITY_BASE_AURA];
        entityAttributes[newItemId]["InsightScore"] = protocolParameters[PARAM_ENTITY_BASE_INSIGHT];
        entityAttributes[newItemId]["AdaptabilityFactor"] = protocolParameters[PARAM_ENTITY_BASE_ADAPTABILITY];
        entityLastAuraUpdate[newItemId] = block.timestamp;

        emit ChronoEntitySpawned(newItemId, _to, _initialName);
        return newItemId;
    }

    // 4. getEntityAttributes: Retrieves attributes of a ChronoEntity.
    function getEntityAttributes(uint256 _tokenId) public view returns (uint256 aura, uint256 insight, uint256 adaptability) {
        require(entityNFT.ownerOf(_tokenId) != address(0), "ChronoForge: Invalid entity ID or entity does not exist.");
        aura = entityAttributes[_tokenId]["AuraLevel"];
        insight = entityAttributes[_tokenId]["InsightScore"];
        adaptability = entityAttributes[_tokenId]["AdaptabilityFactor"];
        return (aura, insight, adaptability);
    }

    // --- II. Entity Evolution & AI Integration ---

    // Internal helper for proposal creation
    function _createProposal(address _proposer, bytes memory _data, string memory _description, ProposalType _type) internal returns (uint256) {
        require(essenceToken.balanceOf(_proposer) >= protocolParameters[PARAM_PROPOSAL_THRESHOLD_ESSENCE], "ChronoForge: Proposer needs sufficient ESSENCE balance.");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        Proposal storage proposal;

        if (_type == ProposalType.EvolutionTrigger) {
            proposal = evolutionProposals[proposalId];
        } else if (_type == ProposalType.TreasurySpend) {
            proposal = treasuryProposals[proposalId];
        } else if (_type == ProposalType.ProtocolParameter) {
            proposal = parameterProposals[proposalId];
        } else if (_type == ProposalType.OracleUpdate) {
            proposal = oracleProposals[proposalId];
        } else {
            revert("ChronoForge: Invalid proposal type");
        }

        proposal.id = proposalId;
        proposal.proposer = _proposer;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + protocolParameters[PARAM_VOTING_PERIOD];
        proposal.data = _data;
        proposal.description = _description;
        proposal.executed = false;
        proposal.canceled = false;

        return proposalId;
    }

    // 5. proposeEvolutionTrigger: Initiates a DAO proposal to update an entity's attribute.
    function proposeEvolutionTrigger(uint256 _tokenId, string memory _attributeKey, uint256 _targetValue, bytes32 _externalDataHash, string memory _description) public returns (uint256) {
        require(entityNFT.ownerOf(_tokenId) != address(0), "ChronoForge: Entity does not exist.");
        bytes memory data = abi.encode(_tokenId, _attributeKey, _targetValue, _externalDataHash);
        uint256 proposalId = _createProposal(msg.sender, data, _description, ProposalType.EvolutionTrigger);
        emit EvolutionProposalCreated(proposalId, _tokenId, _attributeKey, _targetValue, _externalDataHash, msg.sender);
        return proposalId;
    }

    // 6. executeEvolution: Executes a successfully passed entity evolution proposal.
    function executeEvolution(uint256 _proposalId) public {
        executeProposal(_proposalId, ProposalType.EvolutionTrigger);
    }

    // 7. submitOracleAIAttestation: AI Oracle updates entity attributes.
    function submitOracleAIAttestation(uint256 _tokenId, string memory _attributeKey, uint256 _newValue, bytes32 _proofHash) public {
        require(msg.sender == chronoForgeOracle, "ChronoForge: Only the designated AI Oracle can submit attestations.");
        require(entityNFT.ownerOf(_tokenId) != address(0), "ChronoForge: Entity does not exist.");

        uint256 oldValue = entityAttributes[_tokenId][_attributeKey];
        entityAttributes[_tokenId][_attributeKey] = _newValue;
        emit OracleAIAttestationSubmitted(_tokenId, _attributeKey, oldValue, _proofHash, msg.sender);
        emit EntityAttributesUpdated(_tokenId, _attributeKey, oldValue, _newValue, msg.sender, "AI_Attestation");
    }

    // 8. requestAIAttestation: User requests an AI attestation.
    function requestAIAttestation(uint256 _tokenId, string memory _attributeKey) public {
        require(entityNFT.ownerOf(_tokenId) != address(0), "ChronoForge: Entity does not exist.");
        // In a real system, this would trigger an off-chain AI computation and oracle submission.
        // For this contract, it merely logs the request.
        emit AIAttestationRequested(_tokenId, _attributeKey, msg.sender);
    }

    // --- III. Governance & Treasury ---

    // 9. proposeTreasurySpend: Creates a DAO proposal to spend ChronoEssence.
    function proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description) public returns (uint256) {
        require(_amount > 0, "ChronoForge: Amount must be greater than zero.");
        require(essenceToken.balanceOf(address(this)) >= _amount, "ChronoForge: Insufficient treasury balance.");
        bytes memory data = abi.encode(_recipient, _amount);
        uint256 proposalId = _createProposal(msg.sender, data, _description, ProposalType.TreasurySpend);
        emit TreasurySpendProposalCreated(proposalId, _recipient, _amount, msg.sender);
        return proposalId;
    }

    // 10. setProtocolParameter: DAO-governed function to update core protocol parameters.
    function setProtocolParameter(bytes32 _paramKey, uint256 _newValue) public returns (uint256) {
        bytes memory data = abi.encode(_paramKey, _newValue);
        uint256 proposalId = _createProposal(msg.sender, data, "Update protocol parameter", ProposalType.ProtocolParameter);
        emit ProtocolParameterProposalCreated(proposalId, _paramKey, _newValue, msg.sender);
        return proposalId;
    }

    // 11. setChronoForgeOracle: Allows the DAO to change the address of the trusted AI Oracle.
    function setChronoForgeOracle(address _newOracle) public returns (uint256) {
        require(_newOracle != address(0), "ChronoForge: New oracle address cannot be zero.");
        bytes memory data = abi.encode(_newOracle);
        uint256 proposalId = _createProposal(msg.sender, data, "Update AI Oracle address", ProposalType.OracleUpdate);
        emit OracleUpdateProposalCreated(proposalId, _newOracle, msg.sender);
        return proposalId;
    }

    // 12. vote: General function for casting a vote on any proposal type.
    function vote(uint256 _proposalId, ProposalType _type, bool _approve) public nonReentrant {
        Proposal storage proposal = _getProposal(_proposalId, _type);
        require(proposal.id != 0, "ChronoForge: Proposal does not exist.");
        require(getProposalState(_proposalId, _type) == ProposalState.Active, "ChronoForge: Proposal not in active voting period.");
        require(!proposal.hasVoted[msg.sender], "ChronoForge: Caller (or their delegate) already voted on this proposal.");

        uint256 votingPower = getVotingPower(msg.sender); // Calculate power for the actual caller
        require(votingPower > 0, "ChronoForge: No voting power.");

        if (_approve) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        proposal.hasVoted[msg.sender] = true; // Mark original caller as having voted
        emit ProposalVoted(_proposalId, _type, msg.sender, _approve, votingPower);
    }

    // 13. voteOnEvolutionTrigger: Specific wrapper for voting on entity evolution proposals.
    function voteOnEvolutionTrigger(uint256 _proposalId, bool _approve) public {
        vote(_proposalId, ProposalType.EvolutionTrigger, _approve);
    }

    // 14. voteOnTreasurySpend: Specific wrapper for voting on treasury spend proposals.
    function voteOnTreasurySpend(uint256 _proposalId, bool _approve) public {
        vote(_proposalId, ProposalType.TreasurySpend, _approve);
    }

    // 15. executeProposal: General function to execute any successfully passed proposal.
    function executeProposal(uint256 _proposalId, ProposalType _type) public nonReentrant {
        Proposal storage proposal = _getProposal(_proposalId, _type);
        require(proposal.id != 0, "ChronoForge: Proposal does not exist.");
        require(getProposalState(_proposalId, _type) == ProposalState.Passed, "ChronoForge: Proposal not passed.");
        require(!proposal.executed, "ChronoForge: Proposal already executed.");
        require(!proposal.canceled, "ChronoForge: Proposal has been canceled.");

        bool success = false;
        if (_type == ProposalType.EvolutionTrigger) {
            (uint256 tokenId, string memory attributeKey, uint256 targetValue, ) = abi.decode(proposal.data, (uint256, string, uint256, bytes32));
            uint256 oldValue = entityAttributes[tokenId][attributeKey];
            entityAttributes[tokenId][attributeKey] = targetValue;
            emit EntityAttributesUpdated(tokenId, attributeKey, oldValue, targetValue, address(this), "DAO_Evolution");
            success = true;
        } else if (_type == ProposalType.TreasurySpend) {
            (address recipient, uint256 amount) = abi.decode(proposal.data, (address, uint256));
            essenceToken.transfer(recipient, amount); // Transfer from this contract (treasury)
            success = true;
        } else if (_type == ProposalType.ProtocolParameter) {
            (bytes32 paramKey, uint256 newValue) = abi.decode(proposal.data, (bytes32, uint256));
            protocolParameters[paramKey] = newValue;
            success = true;
        } else if (_type == ProposalType.OracleUpdate) {
            (address newOracle) = abi.decode(proposal.data, (address));
            chronoForgeOracle = newOracle;
            success = true;
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, _type, success);
    }

    // 16. getVotingPower: Calculates total effective voting power for an address.
    // This function calculates the voting power of a given `_voter`.
    // It sums their own ChronoEssence balance (if not delegated away)
    // plus the power from ChronoEntities they own (if not delegated away)
    // or ChronoEntities that have been delegated TO them.
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 totalPower = 0;

        // Add _voter's own essence balance, IF they haven't delegated it away.
        // If _voter has delegated their essence (`essenceDelegates[_voter] != address(0)`),
        // then their own essence balance is considered "used" by their delegatee,
        // and doesn't count for _voter's direct voting power.
        if (essenceDelegates[_voter] == address(0)) { // If _voter has NOT delegated their essence
            totalPower += essenceToken.balanceOf(_voter);
        }

        // Add power from entities directly owned by _voter (if not delegated away)
        // or entities explicitly delegated TO _voter.
        for (uint256 i = 1; i <= _entityTokenIds.current(); i++) {
            address entityOwner = entityNFT.ownerOf(i);
            address entityDelegate = entityDelegates[i];

            if (entityOwner == _voter && entityDelegate == address(0)) { // Owned by _voter and not delegated away
                 (uint256 currentAura, uint256 currentInsight, ) = getEntityAttributes(i);
                 totalPower += (currentAura * currentInsight) / 100; // Dynamic boost
            } else if (entityDelegate == _voter) { // Delegated TO _voter
                 (uint256 currentAura, uint256 currentInsight, ) = getEntityAttributes(i);
                 totalPower += (currentAura * currentInsight) / 100; // Dynamic boost
            }
        }
        return totalPower;
    }

    // Internal helper to get a proposal by type and ID
    function _getProposal(uint256 _proposalId, ProposalType _type) internal view returns (Proposal storage) {
        if (_type == ProposalType.EvolutionTrigger) {
            return evolutionProposals[_proposalId];
        } else if (_type == ProposalType.TreasurySpend) {
            return treasuryProposals[_proposalId];
        } else if (_type == ProposalType.ProtocolParameter) {
            return parameterProposals[_proposalId];
        } else if (_type == ProposalType.OracleUpdate) {
            return oracleProposals[_proposalId];
        } else {
            revert("ChronoForge: Invalid proposal type for retrieval.");
        }
    }

    // 17. getProposalState: Retrieves the current state of a given proposal.
    function getProposalState(uint256 _proposalId, ProposalType _type) public view returns (ProposalState) {
        Proposal storage proposal = _getProposal(_proposalId, _type);
        require(proposal.id != 0, "ChronoForge: Proposal does not exist.");

        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        if (block.timestamp < proposal.startTime) {
            return ProposalState.Pending;
        }
        if (block.timestamp < proposal.endTime) {
            return ProposalState.Active;
        }

        // Voting period ended, check if passed or failed
        uint256 totalEssenceSupply = essenceToken.totalSupply();
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 quorumThreshold = totalEssenceSupply * protocolParameters[PARAM_QUORUM_PERCENT] / 10000;

        if (totalVotes < quorumThreshold) {
            return ProposalState.Failed; // Did not meet quorum
        }
        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalState.Passed;
        } else {
            return ProposalState.Failed;
        }
    }

    // 18. cancelProposal: Allows the proposer to cancel their own proposal.
    function cancelProposal(uint256 _proposalId, ProposalType _type) public {
        Proposal storage proposal = _getProposal(_proposalId, _type);
        require(proposal.id != 0, "ChronoForge: Proposal does not exist.");
        require(proposal.proposer == msg.sender, "ChronoForge: Only the proposer can cancel this proposal.");
        require(getProposalState(_proposalId, _type) != ProposalState.Executed && getProposalState(_proposalId, _type) != ProposalState.Passed, "ChronoForge: Cannot cancel an executed or passed proposal.");
        require(!proposal.canceled, "ChronoForge: Proposal already canceled.");

        proposal.canceled = true;
        emit ProposalCanceled(_proposalId, _type, msg.sender);
    }

    // --- IV. Advanced Mechanics ---

    // 19. delegateVotingPower: Delegates Essence voting power.
    function delegateVotingPower(address _delegatee) public {
        require(_delegatee != msg.sender, "ChronoForge: Cannot delegate to self.");
        essenceDelegates[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    // 20. delegateEntityVotingPower: Delegates a specific entity's voting power.
    function delegateEntityVotingPower(uint256 _tokenId, address _delegatee) public {
        require(entityNFT.ownerOf(_tokenId) == msg.sender, "ChronoForge: Caller is not the owner of this entity.");
        require(_delegatee != msg.sender, "ChronoForge: Cannot delegate to self.");
        entityDelegates[_tokenId] = _delegatee;
        emit EntityVotingPowerDelegated(_tokenId, msg.sender, _delegatee);
    }

    // 21. triggerAuraDecay: Applies decay logic to an entity's Aura.
    function triggerAuraDecay(uint256 _tokenId) public {
        require(entityNFT.ownerOf(_tokenId) != address(0), "ChronoForge: Entity does not exist.");

        uint256 lastUpdate = entityLastAuraUpdate[_tokenId];
        uint256 auraLevel = entityAttributes[_tokenId]["AuraLevel"];
        uint256 decayRate = protocolParameters[PARAM_DEFAULT_AURA_DECAY_RATE];
        uint256 decayPeriod = protocolParameters[PARAM_AURA_DECAY_PERIOD];

        if (block.timestamp > lastUpdate + decayPeriod) {
            uint256 periodsPassed = (block.timestamp - lastUpdate) / decayPeriod;
            uint256 decayedAmount = periodsPassed * decayRate;
            
            uint256 newAura = auraLevel - (decayedAmount > auraLevel ? auraLevel : decayedAmount); // Cap at 0
            
            entityAttributes[_tokenId]["AuraLevel"] = newAura;
            entityLastAuraUpdate[_tokenId] = lastUpdate + (periodsPassed * decayPeriod); // Update timestamp by whole periods decayed

            emit AuraDecayTriggered(_tokenId, auraLevel, newAura);
            emit EntityAttributesUpdated(_tokenId, "AuraLevel", auraLevel, newAura, msg.sender, "Aura_Decay");
        }
    }

    // 22. fuseEntityInfluence: Fuses influence from two entities.
    function fuseEntityInfluence(uint256 _tokenId1, uint256 _tokenId2) public nonReentrant {
        require(entityNFT.ownerOf(_tokenId1) == msg.sender, "ChronoForge: Caller not owner of first entity.");
        require(entityNFT.ownerOf(_tokenId2) == msg.sender, "ChronoForge: Caller not owner of second entity.");
        require(_tokenId1 != _tokenId2, "ChronoForge: Cannot fuse an entity with itself.");

        uint256 fusionCost = protocolParameters[PARAM_FUSION_ESSENCE_COST];
        essenceToken.transferFrom(msg.sender, address(this), fusionCost); // Pay essence cost to treasury

        // Get attributes for both entities
        (uint256 aura1, uint256 insight1, uint256 adaptability1) = getEntityAttributes(_tokenId1);
        (uint256 aura2, uint256 insight2, uint256 adaptability2) = getEntityAttributes(_tokenId2);

        // Simple fusion logic: Boost tokenId1 using a fraction of tokenId2's attributes.
        // The second entity's attributes are reduced.
        uint256 auraBoost = aura2 / 4; // 25% of second entity's aura
        uint256 insightBoost = insight2 / 2; // 50% of second entity's insight
        uint256 adaptabilityPenalty = adaptability2 / 10; // small penalty on second entity's adaptability

        // Apply boosts to _tokenId1
        entityAttributes[_tokenId1]["AuraLevel"] += auraBoost;
        entityAttributes[_tokenId1]["InsightScore"] += insightBoost;

        // Apply penalties/reductions to _tokenId2, ensuring attributes don't go below 0
        entityAttributes[_tokenId2]["AuraLevel"] = aura2 - (auraBoost > aura2 ? aura2 : auraBoost);
        entityAttributes[_tokenId2]["InsightScore"] = insight2 - (insightBoost > insight2 ? insight2 : insightBoost);
        entityAttributes[_tokenId2]["AdaptabilityFactor"] = adaptability2 - (adaptabilityPenalty > adaptability2 ? adaptability2 : adaptabilityPenalty);

        emit EntityInfluenceFused(_tokenId1, _tokenId2, _tokenId1, fusionCost);
        emit EntityAttributesUpdated(_tokenId1, "AuraLevel", aura1, entityAttributes[_tokenId1]["AuraLevel"], msg.sender, "Fusion_Boost");
        emit EntityAttributesUpdated(_tokenId1, "InsightScore", insight1, entityAttributes[_tokenId1]["InsightScore"], msg.sender, "Fusion_Boost");
        emit EntityAttributesUpdated(_tokenId2, "AuraLevel", aura2, entityAttributes[_tokenId2]["AuraLevel"], msg.sender, "Fusion_Penalty");
        emit EntityAttributesUpdated(_tokenId2, "InsightScore", insight2, entityAttributes[_tokenId2]["InsightScore"], msg.sender, "Fusion_Penalty");
        emit EntityAttributesUpdated(_tokenId2, "AdaptabilityFactor", adaptability2, entityAttributes[_tokenId2]["AdaptabilityFactor"], msg.sender, "Fusion_Penalty");
    }

    // 23. registerEphemeralInsight: Registers a temporary insight.
    function registerEphemeralInsight(uint256 _tokenId, bytes32 _insightHash, uint256 _expirationTime) public {
        require(entityNFT.ownerOf(_tokenId) == msg.sender, "ChronoForge: Caller is not the owner of this entity.");
        require(_expirationTime > block.timestamp, "ChronoForge: Expiration time must be in the future.");
        require(ephemeralInsights[_tokenId][_insightHash].registrant == address(0), "ChronoForge: Insight hash already registered.");

        ephemeralInsights[_tokenId][_insightHash] = EphemeralInsight({
            registrant: msg.sender,
            expirationTime: _expirationTime
        });

        emit EphemeralInsightRegistered(_tokenId, _insightHash, msg.sender, _expirationTime);
    }

    // 24. revokeEphemeralInsight: Revokes an insight before expiration.
    function revokeEphemeralInsight(uint256 _tokenId, bytes32 _insightHash) public {
        EphemeralInsight storage insight = ephemeralInsights[_tokenId][_insightHash];
        require(insight.registrant != address(0), "ChronoForge: Insight not registered.");
        require(insight.registrant == msg.sender, "ChronoForge: Only the registrant can revoke this insight.");
        require(insight.expirationTime > block.timestamp, "ChronoForge: Insight has already expired.");

        delete ephemeralInsights[_tokenId][_insightHash];
        emit EphemeralInsightRevoked(_tokenId, _insightHash, msg.sender);
    }

    // Fallback function to receive ETH for spawning fees
    receive() external payable {}
}

```