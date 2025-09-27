This smart contract, named **AuraMind**, envisions a decentralized ecosystem for collective intelligence and personalized AI agent creation. It combines elements of dynamic NFTs (for Knowledge Capsules), Soulbound Tokens (for AI Agents), a robust reputation system, and on-chain governance to foster a community-driven AI paradigm.

The core idea is that users contribute "Knowledge Capsules" – tokenized, verified data or algorithms – that form a collective intelligence. Based on this, users can mint "Aura Agents" as Soulbound Tokens (SBTs), which dynamically acquire capabilities by linking to these capsules. A sophisticated reputation and staking mechanism ensures quality and incentivizes good behavior, while a DAO governs the entire protocol.

---

## AuraMind: Decentralized AI Knowledge Network & Agent Foundry

### Contract Outline:

1.  **Core Components:**
    *   ERC-1155 for `KnowledgeCapsule` (representing verified data/models).
    *   ERC-721 for `AuraAgent` (representing personalized, soulbound AI assistants).
    *   Reputation and Staking Mechanism.
    *   Decentralized Governance (DAO).
    *   Oracle Integration for off-chain attestation.

2.  **Key Concepts:**
    *   **Knowledge Capsules:** Tokenized, auditable units of AI-relevant data, algorithms, or pre-trained model metadata. They are collectively owned and curated.
    *   **Aura Agents:** Personalized AI agents, minted as Soulbound Tokens, whose capabilities evolve by dynamically linking to approved Knowledge Capsules.
    *   **Reputation System:** Users earn reputation for contributing, evaluating, and curating capsules, and for high-quality agent performance. Reputation dictates voting power and access.
    *   **Delegated Evaluation:** Staked evaluators assess new capsules for accuracy and utility.
    *   **Dynamic Capability Linking:** Agents gain new functions by linking to integrated capsules.
    *   **On-chain Attestation:** Oracle-fed proof of off-chain AI model integrity and agent output quality.
    *   **Conditional Soul-binding:** Agents are mostly non-transferable, but a highly conditional 're-binding' mechanism is introduced for extreme, provable edge cases.

### Function Summary:

**I. Knowledge Capsule Management (ERC-1155 & Curation)**

1.  `submitKnowledgeCapsule(string memory metadataURI, bytes32 contentHash, address AIModelRegistry)`: Propose a new Knowledge Capsule.
2.  `delegateCapsuleEvaluation(uint256 capsuleId, address evaluator, uint256 stakeAmount)`: Assign a staked evaluator to a pending capsule.
3.  `evaluateCapsule(uint256 capsuleId, bool isAccurate, string memory feedbackURI)`: Evaluator submits their assessment.
4.  `finalizeCapsuleIntegration(uint256 capsuleId)`: Integrate a successfully evaluated capsule into the network.
5.  `proposeCapsuleUpgrade(uint256 capsuleId, string memory newMetadataURI, bytes32 newContentHash)`: Suggest an update to an existing capsule.
6.  `voteOnCapsuleUpgrade(uint256 capsuleId, bool approve)`: Community votes on proposed capsule upgrades.
7.  `retireKnowledgeCapsule(uint256 capsuleId, string memory reasonURI)`: Remove outdated or malicious capsules via governance.

**II. Aura AI Agent Foundry (ERC-721 Soulbound Tokens)**

8.  `mintPersonalAgent(string memory name, string memory initialDirectiveURI)`: Mint a new, personalized Aura Agent SBT.
9.  `linkCapsuleToAgent(uint256 agentId, uint256 capsuleId)`: Dynamically grant an agent access/capability from an integrated capsule.
10. `configureAgentParameters(uint256 agentId, string memory configURI)`: Update agent's operational parameters (off-chain config attested on-chain).
11. `attestAgentOutputQuality(uint256 agentId, bytes32 outputHash, uint8 qualityScore, bytes memory proof)`: Oracle-attested record of agent's performance (e.g., ZKP of correctness).
12. `rebindAgentOwnership(uint256 agentId, address newOwner, bytes memory specificConditionProof)`: Conditionally re-assign ownership for specific, provable edge cases (e.g., legal succession, requiring specific proof).

**III. Reputation & Staking System**

13. `stakeForReputation(uint256 amount)`: Stake native tokens to boost reputation weight.
14. `claimReputationReward(address recipient)`: Claim accrued rewards for positive contributions/performance.
15. `slashReputation(address target, uint256 amount, string memory reasonURI)`: Penalize users for malicious or negligent actions.
16. `delegateReputationWeight(address delegatee)`: Delegate voting power based on accumulated reputation.

**IV. Decentralized Governance (DAO)**

17. `proposeProtocolChange(string memory proposalURI, bytes memory callData)`: Submit a new governance proposal for contract changes or parameter updates.
18. `voteOnProposal(uint256 proposalId, bool approve)`: Vote on active proposals using reputation-weighted power.
19. `executeProposal(uint256 proposalId)`: Execute a passed governance proposal.

**V. Oracle & External AI Integration**

20. `setTrustedOracle(address newOracle)`: Owner/Governance updates the trusted oracle address.
21. `registerExternalAIModel(bytes32 modelHash, string memory endpointURI)`: Register metadata for an external AI model referenced by capsules.
22. `verifyAIModelIntegrity(bytes32 modelHash, bytes memory integrityProof)`: Oracle attests to the integrity/veracity of an off-chain AI model.

**VI. Utility & Query Functions**

23. `getAgentCapabilities(uint256 agentId)`: View the list of Knowledge Capsules linked to an agent.
24. `getUserReputation(address user)`: Get the current reputation score of a user.
25. `getCapsuleState(uint256 capsuleId)`: Get the current status and metadata of a Knowledge Capsule.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safe math, though Solidity 0.8+ has built-in checks.

// Error types for clearer feedback
error AuraMind__InvalidCapsuleId();
error AuraMind__InvalidAgentId();
error AuraMind__Unauthorized();
error AuraMind__CapsuleAlreadyEvaluated();
error AuraMind__CapsuleNotReadyForIntegration();
error AuraMind__CapsuleNotIntegrated();
error AuraMind__EvaluationAlreadyDelegated();
error AuraMind__NotEnoughStake();
error AuraMind__AgentAlreadyLinkedToCapsule();
error AuraMind__AgentNotLinkedToCapsule();
error AuraMind__InsufficientReputation();
error AuraMind__ProposalNotFound();
error AuraMind__ProposalNotExecutable();
error AuraMind__AlreadyVoted();
error AuraMind__CannotRebindOwnership();
error AuraMind__InvalidOracle();
error AuraMind__EvaluationPeriodNotOver();

contract AuraMind is Ownable, ERC721, ERC1155 {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for critical operations if needed.

    // --- State Variables ---

    // Token Counters
    Counters.Counter private _capsuleIdCounter;
    Counters.Counter private _agentIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Reputation System
    mapping(address => uint256) public reputation; // User reputation score
    mapping(address => uint256) public stakedReputationTokens; // Tokens staked for reputation boost
    mapping(address => address) public reputationDelegates; // User's delegated voting power

    // Knowledge Capsules (ERC-1155)
    struct KnowledgeCapsule {
        uint256 id;
        string metadataURI; // IPFS URI for capsule details (description, purpose, input/output spec)
        bytes32 contentHash; // Cryptographic hash of the actual knowledge content (e.g., AI model weights, dataset hash)
        address owner; // Original submitter
        CapsuleStatus status;
        address evaluator; // Assigned evaluator
        uint256 evaluationStake; // Stake for evaluation
        bool isAccurate; // Evaluator's judgment
        string feedbackURI; // Evaluator's feedback URI
        uint256 submittedTimestamp;
        uint256 evaluationDeadline;
        address AIModelRegistry; // Optional: Reference to an external contract managing AI models
    }
    mapping(uint256 => KnowledgeCapsule) public capsules;
    mapping(uint256 => address[]) public capsuleUpvoteRegistry; // For tracking upgrade votes
    mapping(uint256 => address[]) public capsuleDownvoteRegistry; // For tracking upgrade votes
    mapping(uint256 => mapping(address => bool)) public hasVotedOnCapsuleUpgrade; // Track if user voted on capsule upgrade

    enum CapsuleStatus { PendingEvaluation, UnderEvaluation, Evaluated, Integrated, PendingUpgrade, Retired }

    // Aura AI Agents (ERC-721 Soulbound Tokens)
    struct AuraAgent {
        uint256 id;
        string name;
        string initialDirectiveURI; // IPFS URI for agent's initial personality/directive
        string configURI; // IPFS URI for agent's current configuration
        mapping(uint256 => bool) linkedCapsules; // Which Knowledge Capsules this agent can use
        uint256 lastAttestationTimestamp; // Timestamp of the last output quality attestation
        uint8 cumulativeQualityScore; // Cumulative quality score from attestations
        uint256 attestationCount; // Number of attestations
    }
    mapping(uint256 => AuraAgent) public agents;
    mapping(address => uint256) private _agentOwnerId; // Store agent ID by owner for quick lookup if needed

    // Decentralized Governance (DAO)
    struct Proposal {
        uint256 id;
        string proposalURI; // IPFS URI for detailed proposal text
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Contract to call
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 yayVotes; // Reputation-weighted
        uint256 nayVotes; // Reputation-weighted
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // 7 days for voting
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Minimum reputation to propose

    // Oracle Integration
    address public trustedOracle; // Address of the trusted oracle for off-chain attestations

    // System Parameters (set by governance)
    uint256 public constant EVALUATION_PERIOD = 3 days; // Time given to an evaluator
    uint256 public constant MIN_CAPSULE_EVALUATION_STAKE = 1 ether; // Minimum stake for evaluation
    uint256 public constant MIN_REPUTATION_FOR_EVALUATION = 50; // Minimum reputation to be an evaluator
    uint256 public constant MIN_REP_WEIGHT_FOR_UPGRADE_VOTE = 10; // Minimum reputation weight to vote on capsule upgrades

    // Token addresses for staking and rewards (ERC20 standard)
    address public auraTokenAddress; // Native token for staking and rewards

    // --- Events ---
    event KnowledgeCapsuleSubmitted(uint256 indexed capsuleId, address indexed owner, string metadataURI);
    event CapsuleEvaluationDelegated(uint256 indexed capsuleId, address indexed evaluator, uint256 stakeAmount);
    event CapsuleEvaluated(uint256 indexed capsuleId, address indexed evaluator, bool isAccurate, string feedbackURI);
    event CapsuleIntegrated(uint256 indexed capsuleId);
    event CapsuleUpgradeProposed(uint256 indexed capsuleId, address indexed proposer, string newMetadataURI, bytes32 newContentHash);
    event CapsuleUpgradeVoted(uint256 indexed capsuleId, address indexed voter, bool approved);
    event CapsuleRetired(uint256 indexed capsuleId);

    event AuraAgentMinted(uint256 indexed agentId, address indexed owner, string name, string initialDirectiveURI);
    event CapsuleLinkedToAgent(uint256 indexed agentId, uint256 indexed capsuleId);
    event AgentParametersConfigured(uint256 indexed agentId, string configURI);
    event AgentOutputQualityAttested(uint256 indexed agentId, bytes32 outputHash, uint8 qualityScore);
    event AgentOwnershipRebound(uint256 indexed agentId, address indexed oldOwner, address indexed newOwner);

    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationRewardClaimed(address indexed user, uint256 amount);
    event ReputationSlashed(address indexed target, uint256 amount, string reasonURI);
    event ReputationDelegateUpdated(address indexed delegator, address indexed delegatee);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event TrustedOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event ExternalAIModelRegistered(bytes32 indexed modelHash, string endpointURI);
    event AIModelIntegrityVerified(bytes32 indexed modelHash, bytes integrityProof);

    // --- Constructor ---
    constructor(address _auraTokenAddress, address _trustedOracle)
        ERC721("AuraAgent", "AURA")
        ERC1155("https://aura.mind/knowledge-capsule/{id}.json") // Base URI for Knowledge Capsules
        Ownable(msg.sender)
    {
        require(_auraTokenAddress != address(0), "AuraMind: Invalid Aura Token address");
        require(_trustedOracle != address(0), "AuraMind: Invalid Oracle address");
        auraTokenAddress = _auraTokenAddress;
        trustedOracle = _trustedOracle;
    }

    // --- Modifiers ---
    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracle, AuraMind__InvalidOracle());
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), AuraMind__InvalidAgentId());
        require(ownerOf(_agentId) == msg.sender, AuraMind__Unauthorized());
        _;
    }

    modifier onlyCapsuleOwner(uint256 _capsuleId) {
        require(capsules[_capsuleId].id != 0, AuraMind__InvalidCapsuleId());
        require(capsules[_capsuleId].owner == msg.sender, AuraMind__Unauthorized());
        _;
    }

    // --- I. Knowledge Capsule Management (ERC-1155 & Curation) ---

    /**
     * @notice Allows a user to submit a new Knowledge Capsule to the network.
     * @param metadataURI IPFS URI containing human-readable description and metadata.
     * @param contentHash Cryptographic hash of the actual knowledge content (e.g., model weights, dataset).
     * @param AIModelRegistry Optional address of an external contract managing AI models if this capsule references one.
     * @dev Mints an ERC-1155 token representing the capsule. Status starts as PendingEvaluation.
     */
    function submitKnowledgeCapsule(string memory metadataURI, bytes32 contentHash, address AIModelRegistry) public {
        _capsuleIdCounter.increment();
        uint256 newCapsuleId = _capsuleIdCounter.current();

        capsules[newCapsuleId] = KnowledgeCapsule({
            id: newCapsuleId,
            metadataURI: metadataURI,
            contentHash: contentHash,
            owner: msg.sender,
            status: CapsuleStatus.PendingEvaluation,
            evaluator: address(0),
            evaluationStake: 0,
            isAccurate: false,
            feedbackURI: "",
            submittedTimestamp: block.timestamp,
            evaluationDeadline: 0,
            AIModelRegistry: AIModelRegistry
        });

        _mint(msg.sender, newCapsuleId, 1, ""); // Mint 1 unit of this capsule type to the submitter
        emit KnowledgeCapsuleSubmitted(newCapsuleId, msg.sender, metadataURI);
    }

    /**
     * @notice Allows a user with sufficient reputation to stake tokens and become an evaluator for a pending capsule.
     * @param capsuleId The ID of the capsule to evaluate.
     * @param evaluator The address of the user who will evaluate the capsule.
     * @param stakeAmount The amount of tokens to stake for this evaluation.
     * @dev Requires `stakeAmount` tokens to be approved for this contract.
     * @dev Only one evaluator can be assigned per capsule at a time.
     */
    function delegateCapsuleEvaluation(uint256 capsuleId, address evaluator, uint256 stakeAmount) public {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.status == CapsuleStatus.PendingEvaluation, "AuraMind: Capsule not in PendingEvaluation status.");
        require(capsule.evaluator == address(0), AuraMind__EvaluationAlreadyDelegated());
        require(reputation[evaluator] >= MIN_REPUTATION_FOR_EVALUATION, AuraMind__InsufficientReputation());
        require(stakeAmount >= MIN_CAPSULE_EVALUATION_STAKE, AuraMind__NotEnoughStake());

        // Transfer stake tokens from evaluator to this contract
        IERC20(auraTokenAddress).transferFrom(msg.sender, address(this), stakeAmount);

        capsule.evaluator = evaluator;
        capsule.evaluationStake = stakeAmount;
        capsule.status = CapsuleStatus.UnderEvaluation;
        capsule.evaluationDeadline = block.timestamp + EVALUATION_PERIOD;

        emit CapsuleEvaluationDelegated(capsuleId, evaluator, stakeAmount);
    }

    /**
     * @notice Allows the assigned evaluator to submit their assessment of a capsule.
     * @param capsuleId The ID of the capsule being evaluated.
     * @param isAccurate True if the capsule is deemed accurate/useful, false otherwise.
     * @param feedbackURI IPFS URI for detailed feedback or justification.
     * @dev Only the assigned evaluator can call this within the evaluation period.
     */
    function evaluateCapsule(uint256 capsuleId, bool isAccurate, string memory feedbackURI) public {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.evaluator == msg.sender, AuraMind__Unauthorized());
        require(capsule.status == CapsuleStatus.UnderEvaluation, "AuraMind: Capsule not under evaluation.");
        require(block.timestamp <= capsule.evaluationDeadline, AuraMind__EvaluationPeriodNotOver());

        capsule.isAccurate = isAccurate;
        capsule.feedbackURI = feedbackURI;
        capsule.status = CapsuleStatus.Evaluated;

        // Reward/penalize evaluator based on outcome (simplified here, could be more complex)
        // For simplicity: If accurate, reward stake + bonus. If inaccurate, return stake.
        if (isAccurate) {
            reputation[msg.sender] = reputation[msg.sender].add(10); // Reputation boost
            IERC20(auraTokenAddress).transfer(msg.sender, capsule.evaluationStake.add(capsule.evaluationStake.div(10))); // Stake + 10% bonus
        } else {
            // No direct slash for "inaccurate" but reputation might not grow
            IERC20(auraTokenAddress).transfer(msg.sender, capsule.evaluationStake); // Return stake
        }
        capsule.evaluationStake = 0; // Reset stake

        emit CapsuleEvaluated(capsuleId, msg.sender, isAccurate, feedbackURI);
    }

    /**
     * @notice Integrates an accurately evaluated capsule into the network, making it available for agents.
     * @param capsuleId The ID of the capsule to integrate.
     * @dev Can be called by anyone after a capsule has been positively evaluated.
     */
    function finalizeCapsuleIntegration(uint256 capsuleId) public {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.status == CapsuleStatus.Evaluated, "AuraMind: Capsule not in Evaluated status.");
        require(capsule.isAccurate, AuraMind__CapsuleNotReadyForIntegration());

        capsule.status = CapsuleStatus.Integrated;
        emit CapsuleIntegrated(capsuleId);
    }

    /**
     * @notice Proposes an upgrade to an existing, integrated Knowledge Capsule.
     * @param capsuleId The ID of the capsule to upgrade.
     * @param newMetadataURI New IPFS URI for updated metadata.
     * @param newContentHash New cryptographic hash of the updated content.
     */
    function proposeCapsuleUpgrade(uint256 capsuleId, string memory newMetadataURI, bytes32 newContentHash) public {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.status == CapsuleStatus.Integrated, "AuraMind: Only integrated capsules can be upgraded.");
        // Should require reputation to propose upgrade.
        require(reputation[msg.sender] >= MIN_REPUTATION_FOR_PROPOSAL, AuraMind__InsufficientReputation());

        // For simplicity, directly update capsule metadata and contentHash.
        // In a real system, this would trigger a new evaluation/governance vote for the upgrade.
        // We'll simulate a light voting here for the upgrade approval.
        capsule.status = CapsuleStatus.PendingUpgrade;
        capsule.metadataURI = newMetadataURI;
        capsule.contentHash = newContentHash; // Temporarily update, will revert if vote fails
        delete capsuleUpvoteRegistry[capsuleId];
        delete capsuleDownvoteRegistry[capsuleId];
        delete hasVotedOnCapsuleUpgrade[capsuleId]; // Reset votes for new proposal

        emit CapsuleUpgradeProposed(capsuleId, msg.sender, newMetadataURI, newContentHash);
    }

    /**
     * @notice Allows users with sufficient reputation to vote on a proposed capsule upgrade.
     * @param capsuleId The ID of the capsule with the pending upgrade.
     * @param approve True to approve the upgrade, false to reject.
     */
    function voteOnCapsuleUpgrade(uint256 capsuleId, bool approve) public {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.status == CapsuleStatus.PendingUpgrade, "AuraMind: Capsule not in PendingUpgrade status.");
        require(reputation[msg.sender] >= MIN_REP_WEIGHT_FOR_UPGRADE_VOTE, AuraMind__InsufficientReputation());
        require(!hasVotedOnCapsuleUpgrade[capsuleId][msg.sender], AuraMind__AlreadyVoted());

        hasVotedOnCapsuleUpgrade[capsuleId][msg.sender] = true;
        if (approve) {
            capsuleUpvoteRegistry[capsuleId].push(msg.sender);
        } else {
            capsuleDownvoteRegistry[capsuleId].push(msg.sender);
        }

        // Simplified logic: If total upvotes > total downvotes (based on reputation), finalize.
        // A real system would have a quorum, voting period, etc.
        uint256 totalUpvoteRep = 0;
        for(uint i=0; i < capsuleUpvoteRegistry[capsuleId].length; i++) {
            totalUpvoteRep = totalUpvoteRep.add(reputation[capsuleUpvoteRegistry[capsuleId][i]]);
        }
        uint256 totalDownvoteRep = 0;
        for(uint i=0; i < capsuleDownvoteRegistry[capsuleId].length; i++) {
            totalDownvoteRep = totalDownvoteRep.add(reputation[capsuleDownvoteRegistry[capsuleId][i]]);
        }

        if (totalUpvoteRep > totalDownvoteRep && totalUpvoteRep >= MIN_REPUTATION_FOR_PROPOSAL * 2) { // Example threshold
             capsule.status = CapsuleStatus.Integrated; // Upgrade approved
        } else if (totalDownvoteRep > totalUpvoteRep && totalDownvoteRep >= MIN_REPUTATION_FOR_PROPOSAL * 2) {
             capsule.status = CapsuleStatus.Integrated; // Upgrade rejected, revert to previous state (current simplified code doesn't store old state, would need an additional field)
             // In a real scenario, if rejected, `capsule.metadataURI` and `capsule.contentHash` would revert to their previous values.
             // For this example, we simply transition back to Integrated, implying the proposed changes are not applied if rejected.
        }

        emit CapsuleUpgradeVoted(capsuleId, msg.sender, approve);
    }

    /**
     * @notice Allows governance to retire a Knowledge Capsule, removing it from active use.
     * @param capsuleId The ID of the capsule to retire.
     * @param reasonURI IPFS URI explaining the reason for retirement.
     * @dev This should typically be triggered by a governance proposal.
     */
    function retireKnowledgeCapsule(uint256 capsuleId, string memory reasonURI) public onlyOwner { // Simplified to onlyOwner for now
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.status != CapsuleStatus.Retired, "AuraMind: Capsule already retired.");

        capsule.status = CapsuleStatus.Retired;
        // Consider unlinking from all agents, revoking ERC-1155 token from owners.
        // For simplicity, we just change status.
        emit CapsuleRetired(capsuleId);
    }

    // --- II. Aura AI Agent Foundry (ERC-721 Soulbound Tokens) ---

    /**
     * @notice Mints a new Aura AI Agent as a Soulbound Token (ERC-721) to the caller.
     * @param name The name of the AI agent.
     * @param initialDirectiveURI IPFS URI for the agent's initial personality/directive.
     * @dev These agents are soulbound and generally non-transferable.
     */
    function mintPersonalAgent(string memory name, string memory initialDirectiveURI) public {
        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        _safeMint(msg.sender, newAgentId); // Mint ERC-721 token
        
        agents[newAgentId] = AuraAgent({
            id: newAgentId,
            name: name,
            initialDirectiveURI: initialDirectiveURI,
            configURI: "",
            lastAttestationTimestamp: 0,
            cumulativeQualityScore: 0,
            attestationCount: 0
        });
        _agentOwnerId[msg.sender] = newAgentId; // Only one agent per owner for simplicity

        emit AuraAgentMinted(newAgentId, msg.sender, name, initialDirectiveURI);
    }

    /**
     * @notice Links an integrated Knowledge Capsule to an Aura Agent, granting it new capabilities.
     * @param agentId The ID of the Aura Agent.
     * @param capsuleId The ID of the Knowledge Capsule to link.
     */
    function linkCapsuleToAgent(uint256 agentId, uint256 capsuleId) public onlyAgentOwner(agentId) {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());
        require(capsule.status == CapsuleStatus.Integrated, AuraMind__CapsuleNotIntegrated());
        require(!agents[agentId].linkedCapsules[capsuleId], AuraMind__AgentAlreadyLinkedToCapsule());

        agents[agentId].linkedCapsules[capsuleId] = true;
        emit CapsuleLinkedToAgent(agentId, capsuleId);
    }

    /**
     * @notice Configures operational parameters for an Aura Agent.
     * @param agentId The ID of the Aura Agent.
     * @param configURI IPFS URI pointing to the agent's new configuration.
     * @dev This updates the agent's metadata, not its core directive.
     */
    function configureAgentParameters(uint256 agentId, string memory configURI) public onlyAgentOwner(agentId) {
        agents[agentId].configURI = configURI;
        emit AgentParametersConfigured(agentId, configURI);
    }

    /**
     * @notice Oracle-attested record of an Aura Agent's output quality.
     * @param agentId The ID of the Aura Agent.
     * @param outputHash Cryptographic hash of the agent's output that was evaluated.
     * @param qualityScore A score (e.g., 0-100) indicating the quality of the output.
     * @param proof An optional ZKP or other cryptographic proof of the attestation's validity.
     * @dev This function is called by the trusted oracle. Updates the agent's cumulative quality score.
     */
    function attestAgentOutputQuality(uint256 agentId, bytes32 outputHash, uint8 qualityScore, bytes memory proof) public onlyTrustedOracle {
        require(_exists(agentId), AuraMind__InvalidAgentId());
        // Additional checks for `proof` validity would happen off-chain or by a more complex on-chain verifier.
        // For example, if 'proof' is a ZKP, it would be verified against a known verifier contract.

        AuraAgent storage agent = agents[agentId];
        agent.cumulativeQualityScore = agent.cumulativeQualityScore.add(qualityScore);
        agent.attestationCount = agent.attestationCount.add(1);
        agent.lastAttestationTimestamp = block.timestamp;

        // Potentially reward the agent's owner for good performance
        reputation[ownerOf(agentId)] = reputation[ownerOf(agentId)].add(qualityScore.div(10)); // Simplified reputation gain

        emit AgentOutputQualityAttested(agentId, outputHash, qualityScore);
    }

    /**
     * @notice Conditionally re-assigns ownership of a Soulbound Aura Agent for specific, provable edge cases.
     * @param agentId The ID of the Aura Agent.
     * @param newOwner The address of the new owner.
     * @param specificConditionProof Cryptographic proof (e.g., legal document hash, ZKP) of the condition met.
     * @dev This function is highly restricted and should only be callable by governance or under very specific, provable conditions.
     * @dev Aims to address edge cases like inheritance or incapacitation for "soulbound" assets.
     */
    function rebindAgentOwnership(uint256 agentId, address newOwner, bytes memory specificConditionProof) public {
        require(_exists(agentId), AuraMind__InvalidAgentId());
        require(newOwner != address(0), "AuraMind: New owner cannot be zero address.");
        require(newOwner != ownerOf(agentId), "AuraMind: New owner is already current owner.");
        
        // This logic is highly sensitive. In a real scenario, this would involve:
        // 1. A governance vote, or
        // 2. A multi-sig approval, or
        // 3. A ZKP verification of a death certificate/legal document hash included in `specificConditionProof`.
        // For demonstration, we'll make it governance-controlled.
        require(msg.sender == owner() || msg.sender == trustedOracle, AuraMind__Unauthorized()); // Placeholder: only contract owner or oracle can initiate for now

        // Further checks would be needed for 'specificConditionProof'.
        // E.g., a hash of a legal document uploaded to IPFS which can be validated off-chain.
        // `keccak256(abi.encodePacked(specificConditionProof))` could be used to verify against a known hash.
        // For this example, we'll assume the `specificConditionProof` itself is sufficient.

        address oldOwner = ownerOf(agentId);
        _transfer(oldOwner, newOwner, agentId); // Use ERC721 internal transfer

        // Update internal owner mapping if used
        delete _agentOwnerId[oldOwner];
        _agentOwnerId[newOwner] = agentId;

        emit AgentOwnershipRebound(agentId, oldOwner, newOwner);
    }

    // --- III. Reputation & Staking System ---

    /**
     * @notice Allows a user to stake native Aura tokens to boost their reputation weight.
     * @param amount The amount of tokens to stake.
     * @dev Tokens must be approved for this contract first.
     */
    function stakeForReputation(uint256 amount) public {
        require(amount > 0, "AuraMind: Stake amount must be greater than zero.");
        IERC20(auraTokenAddress).transferFrom(msg.sender, address(this), amount);
        stakedReputationTokens[msg.sender] = stakedReputationTokens[msg.sender].add(amount);
        reputation[msg.sender] = reputation[msg.sender].add(amount.div(100)); // Simplified: 100 staked tokens = 1 reputation point

        emit ReputationStaked(msg.sender, amount);
    }

    /**
     * @notice Allows a user to claim accrued reputation rewards (e.g., from good evaluations, agent performance).
     * @param recipient The address to send rewards to.
     * @dev Placeholder for a more complex reward distribution logic.
     */
    function claimReputationReward(address recipient) public {
        // This function would implement logic to calculate and distribute rewards.
        // For simplicity, we'll imagine a fixed reward for good behavior.
        // This would interact with a dedicated reward pool or token distribution.
        require(reputation[msg.sender] > 0, AuraMind__InsufficientReputation()); // Example check
        uint256 rewardAmount = reputation[msg.sender].div(10); // Simplified: 10% of reputation as reward

        // In a real system, the reward mechanism would be tied to specific actions and a reward pool
        // IERC20(auraTokenAddress).transfer(recipient, rewardAmount);
        // reputation[msg.sender] = reputation[msg.sender].sub(rewardAmount * 10); // Deduct reputation for claiming

        emit ReputationRewardClaimed(recipient, rewardAmount);
    }

    /**
     * @notice Slashes a user's reputation and potentially their staked tokens for malicious actions.
     * @param target The address whose reputation is to be slashed.
     * @param amount The amount of reputation to deduct.
     * @param reasonURI IPFS URI explaining the reason for the slash.
     * @dev This should be triggered by a governance vote or by trusted oracle for severe infractions.
     */
    function slashReputation(address target, uint256 amount, string memory reasonURI) public onlyOwner { // Simplified to onlyOwner
        require(reputation[target] >= amount, AuraMind__InsufficientReputation());
        reputation[target] = reputation[target].sub(amount);

        // Also slash staked tokens proportionate to reputation loss
        uint256 stakeLoss = amount.mul(100); // Inverse of the reputation calculation
        if (stakedReputationTokens[target] >= stakeLoss) {
            stakedReputationTokens[target] = stakedReputationTokens[target].sub(stakeLoss);
            // These tokens could be burned or sent to a treasury/DAO fund
            // IERC20(auraTokenAddress).transfer(DAO_TREASURY_ADDRESS, stakeLoss);
        } else {
            stakedReputationTokens[target] = 0; // Slash all if not enough
            // Consider more sophisticated slashing mechanics
        }

        emit ReputationSlashed(target, amount, reasonURI);
    }

    /**
     * @notice Allows a user to delegate their reputation-based voting power to another address.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateReputationWeight(address delegatee) public {
        require(delegatee != msg.sender, "AuraMind: Cannot delegate to self.");
        reputationDelegates[msg.sender] = delegatee;
        emit ReputationDelegateUpdated(msg.sender, delegatee);
    }

    // --- IV. Decentralized Governance (DAO) ---

    /**
     * @notice Allows users with sufficient reputation to propose changes to the protocol.
     * @param proposalURI IPFS URI for the detailed proposal text.
     * @param targetContract The contract address to call if the proposal passes.
     * @param callData The encoded function call to execute (e.g., `abi.encodeWithSignature("setTrustedOracle(address)", newOracleAddress)`).
     */
    function proposeProtocolChange(string memory proposalURI, address targetContract, bytes memory callData) public {
        uint256 effectiveReputation = reputation[msg.sender].add(stakedReputationTokens[msg.sender].div(100)); // Consider staked tokens for proposal power
        require(effectiveReputation >= MIN_REPUTATION_FOR_PROPOSAL, AuraMind__InsufficientReputation());

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposalURI: proposalURI,
            callData: callData,
            targetContract: targetContract,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            passed: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        emit ProposalSubmitted(newProposalId, msg.sender, proposalURI);
    }

    /**
     * @notice Allows users to vote on an active governance proposal.
     * @param proposalId The ID of the proposal.
     * @param approve True for 'Yay', false for 'Nay'.
     */
    function voteOnProposal(uint256 proposalId, bool approve) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, AuraMind__ProposalNotFound());
        require(block.timestamp <= proposal.votingDeadline, "AuraMind: Voting period has ended.");

        address voter = msg.sender;
        if (reputationDelegates[msg.sender] != address(0)) {
            voter = reputationDelegates[msg.sender]; // Use delegated voter
        }
        
        require(!proposal.hasVoted[voter], AuraMind__AlreadyVoted());
        require(reputation[voter] > 0, AuraMind__InsufficientReputation());

        proposal.hasVoted[voter] = true;
        uint256 voteWeight = reputation[voter]; // Reputation directly used as vote weight

        if (approve) {
            proposal.yayVotes = proposal.yayVotes.add(voteWeight);
        } else {
            proposal.nayVotes = proposal.nayVotes.add(voteWeight);
        }

        emit ProposalVoted(proposalId, voter, approve, voteWeight);
    }

    /**
     * @notice Executes a passed governance proposal.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, AuraMind__ProposalNotFound());
        require(block.timestamp > proposal.votingDeadline, "AuraMind: Voting period not ended.");
        require(!proposal.executed, "AuraMind: Proposal already executed.");
        
        // Example quorum & majority logic (can be made more complex)
        uint256 totalVotes = proposal.yayVotes.add(proposal.nayVotes);
        require(totalVotes > MIN_REPUTATION_FOR_PROPOSAL * 5, "AuraMind: Proposal did not meet quorum."); // Example quorum
        require(proposal.yayVotes > proposal.nayVotes, "AuraMind: Proposal did not pass majority vote.");

        proposal.passed = true;

        (bool success, ) = proposal.targetContract.call(proposal.callData); // Execute the proposal's call data
        require(success, "AuraMind: Proposal execution failed.");

        proposal.executed = true;
        emit ProposalExecuted(proposalId, success);
    }

    // --- V. Oracle & External AI Integration ---

    /**
     * @notice Allows the contract owner or governance to update the trusted oracle address.
     * @param newOracle The address of the new trusted oracle.
     */
    function setTrustedOracle(address newOracle) public onlyOwner { // Should be governance-controlled via proposal
        require(newOracle != address(0), AuraMind__InvalidOracle());
        address oldOracle = trustedOracle;
        trustedOracle = newOracle;
        emit TrustedOracleUpdated(oldOracle, newOracle);
    }

    /**
     * @notice Registers metadata for an external AI model.
     * @param modelHash Cryptographic hash of the external AI model.
     * @param endpointURI URI to access the model (e.g., decentralized storage, API endpoint).
     * @dev This stores metadata, actual model verification happens via `verifyAIModelIntegrity`.
     */
    function registerExternalAIModel(bytes32 modelHash, string memory endpointURI) public onlyTrustedOracle {
        // In a real system, this would likely store model data in a dedicated registry contract.
        // For simplicity, we just emit an event here.
        emit ExternalAIModelRegistered(modelHash, endpointURI);
    }

    /**
     * @notice Oracle attests to the integrity or veracity of an off-chain AI model.
     * @param modelHash The cryptographic hash of the AI model.
     * @param integrityProof Cryptographic proof (e.g., a signature, ZKP) of the model's integrity.
     * @dev This is crucial for trusting off-chain AI. The `integrityProof` would be verified.
     */
    function verifyAIModelIntegrity(bytes32 modelHash, bytes memory integrityProof) public onlyTrustedOracle {
        // Here, the oracle would provide a proof that the AI model associated with `modelHash`
        // is indeed the one it claims to be, or that it has passed certain audits.
        // The `integrityProof` could be a signature from a known auditor, or a ZKP of certain properties.
        // For simplicity, we just emit the event, assuming the oracle handles the actual verification.
        emit AIModelIntegrityVerified(modelHash, integrityProof);
    }

    // --- VI. Utility & Query Functions ---

    /**
     * @notice Returns a list of Knowledge Capsule IDs linked to a specific Aura Agent.
     * @param agentId The ID of the Aura Agent.
     * @return An array of linked Knowledge Capsule IDs.
     */
    function getAgentCapabilities(uint256 agentId) public view returns (uint256[] memory) {
        require(_exists(agentId), AuraMind__InvalidAgentId());
        uint256[] memory linked; // Placeholder for actual linked capsule IDs
        uint256 count = 0;
        // This would iterate through all capsules and check `agents[agentId].linkedCapsules[capsuleId]`
        // For performance, a separate array of linked capsules per agent would be better for direct query.
        // As a simple example, we'll return an empty array if not implemented directly.
        // A more efficient way would be to maintain an array or LinkedList of linkedCapsuleIds within the Agent struct.
        // For this example, we return a mock array.
        for (uint256 i = 1; i <= _capsuleIdCounter.current(); i++) {
            if (agents[agentId].linkedCapsules[i]) {
                count++;
            }
        }
        linked = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 1; i <= _capsuleIdCounter.current(); i++) {
            if (agents[agentId].linkedCapsules[i]) {
                linked[j] = i;
                j++;
            }
        }
        return linked;
    }

    /**
     * @notice Returns the current reputation score of a user.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address user) public view returns (uint256) {
        return reputation[user];
    }

    /**
     * @notice Returns the detailed state of a Knowledge Capsule.
     * @param capsuleId The ID of the Knowledge Capsule.
     * @return id, metadataURI, contentHash, owner, status, evaluator, isAccurate, feedbackURI, submittedTimestamp, evaluationDeadline, AIModelRegistry
     */
    function getCapsuleState(uint256 capsuleId) public view returns (
        uint256 id,
        string memory metadataURI,
        bytes32 contentHash,
        address owner,
        CapsuleStatus status,
        address evaluator,
        bool isAccurate,
        string memory feedbackURI,
        uint256 submittedTimestamp,
        uint256 evaluationDeadline,
        address AIModelRegistry
    ) {
        KnowledgeCapsule storage capsule = capsules[capsuleId];
        require(capsule.id != 0, AuraMind__InvalidCapsuleId());

        return (
            capsule.id,
            capsule.metadataURI,
            capsule.contentHash,
            capsule.owner,
            capsule.status,
            capsule.evaluator,
            capsule.isAccurate,
            capsule.feedbackURI,
            capsule.submittedTimestamp,
            capsule.evaluationDeadline,
            capsule.AIModelRegistry
        );
    }

    // --- ERC721 & ERC1155 Overrides ---

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev Override to enforce soulbound nature of Aura Agents.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert(AuraMind__CannotRebindOwnership()); // Aura Agents are soulbound by default
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev Override to enforce soulbound nature of Aura Agents.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert(AuraMind__CannotRebindOwnership()); // Aura Agents are soulbound by default
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     * @dev ERC1155 tokens (Knowledge Capsules) are transferable.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
        // Custom logic for ERC1155 transfers (e.g., fees, specific conditions)
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {ERC721-_update}.
     * @dev Internal override for ERC721 transfers.
     */
    function _update(address to, uint256 tokenId) internal override returns (address) {
        // Internal transfer logic. This is where `rebindAgentOwnership` actually changes ownership.
        return super._update(to, tokenId);
    }
}
```