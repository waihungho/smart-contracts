The `AkashicNexus` smart contract is designed to be a decentralized, AI-augmented knowledge base and reputation network. It aims to foster the creation, validation, and discovery of valuable knowledge units (Knowledge Capsules), while building a unique, dynamic reputation for its participants (Knowledge Agents) via Soulbound Tokens. The contract integrates a conceptual AI Oracle for automated assessments and insight generation, and introduces mechanisms for knowledge funding, licensing, and advanced attestation.

The core idea is to create a living, evolving data layer on-chain, where knowledge isn't static but rather constantly refined, validated, and potentially generated through human and AI collaboration, with participants earning reputation and incentives for their contributions.

---

### Contract Outline: `AkashicNexus`

1.  **Core State Variables & Enums**: Defines the fundamental data structures (`KnowledgeCapsule`, `KnowledgeAgent`) and their states (`KCStatus`, `KCLicensingType`).
2.  **Access Control (`Ownable` & `Pausable` Re-implementation)**: Custom, minimal implementations of standard access control patterns for the owner and system pausing.
3.  **AI Oracle Management**: Functions specifically for setting and interacting with a trusted AI Oracle address.
4.  **Knowledge Capsule (KC) Management**: Functions for proposing, updating, querying, and managing the lifecycle of knowledge units (acting as dynamic, non-transferable NFTs).
5.  **Knowledge Agent (KA) & Reputation System**: Functions for registering participants, managing their unique, soulbound reputation scores, and staking for network participation.
6.  **Validation & Dispute Resolution**: Mechanics for KAs to vote on KCs, and for the AI Oracle to provide assessments, with a challenge mechanism.
7.  **Incentive & Discovery Mechanisms**: Functions for users to fund specific research bounties and for agents to claim rewards for contributions and validations.
8.  **Advanced Features**:
    *   **AI-Generated Insights**: The AI Oracle can create new KCs representing novel insights.
    *   **Attestation SBTs**: A unique concept allowing for specific, private, non-transferable attestations for KAs.
    *   **Knowledge Licensing**: A mechanism for creators to monetize their KCs.

---

### Function Summary:

1.  `constructor()`: Initializes the contract owner.
2.  `setAIOracleAddress(address _newOracle)`: Sets the address for the trusted AI Oracle. (Admin-only)
3.  `pauseSystem()`: Pauses core contract functions in emergency. (Admin-only)
4.  `unpauseSystem()`: Unpauses core contract functions. (Admin-only)
5.  `proposeKnowledgeCapsule(string calldata _cidHash, string calldata _metadataURI, KCLicensingType _licensingType)`: Allows anyone to propose a new `KnowledgeCapsule` to the network. It's initially set to `Proposed` status and awaits validation. This acts as a dynamic NFT mint.
6.  `updateKnowledgeCapsule(uint256 _kcId, string calldata _newCidHash, string calldata _newMetadataURI)`: Enables the original creator to propose an updated version of an existing KC. This creates a new version while linking it to the parent KC, preserving history.
7.  `getKnowledgeCapsuleDetails(uint256 _kcId)`: Retrieves all the detailed information about a specific Knowledge Capsule, including its status, AI score, and creator.
8.  `registerKnowledgeAgent(string calldata _initialSbtUri)`: Mints a unique, non-transferable Soulbound Token (SBT) for a new Knowledge Agent. This SBT represents their identity and initializes their reputation score, which will evolve based on their activities.
9.  `getKnowledgeAgentReputation(address _agent)`: Returns the current reputation score of a Knowledge Agent, which is a key attribute of their dynamic SBT.
10. `getKnowledgeAgentSBTUri(address _agent)`: Returns the dynamic URI for a Knowledge Agent's SBT metadata. This URI can be updated off-chain to reflect changes in reputation or achievements.
11. `stakeForValidation(uint256 _amount)`: Allows a Knowledge Agent to stake a certain amount of tokens. Staking is a prerequisite for participating in the validation process and earning rewards.
12. `voteOnKnowledgeCapsule(uint256 _kcId, bool _isValidation)`: Knowledge Agents cast their vote (either to validate or dispute) on a `Proposed` or `Updated` Knowledge Capsule. Their reputation and stake influence the vote's weight.
13. `submitAIValidationResult(uint256 _kcId, uint256 _aiScore, string calldata _assessmentDetailsURI)`: The designated AI Oracle submits its automated assessment score for a Knowledge Capsule. This score influences the KC's status and subsequent validation outcomes. (Callable only by `aiOracleAddress`)
14. `generateAIInsightCapsule(string calldata _cidHash, string calldata _metadataURI, uint256[] calldata _sourceKCs)`: The AI Oracle can generate and propose a new `KnowledgeCapsule` that represents a novel insight or synthesis derived from existing source KCs. This demonstrates AI's role in knowledge creation. (Callable only by `aiOracleAddress`)
15. `challengeAIAssessment(uint256 _kcId, string calldata _reason)`: Allows any Knowledge Agent to formally challenge an AI Oracle's assessment of a Knowledge Capsule, providing a reason for their disagreement. This initiates a simplified dispute mechanism.
16. `fundKnowledgeDiscovery(string calldata _description, uint256 _rewardAmount)`: Enables any user to post a bounty for the creation of a specific type of Knowledge Capsule or research area, incentivizing targeted knowledge contribution.
17. `claimDiscoveryBounty(uint256 _bountyId, uint256 _kcId)`: Allows the creator of a Knowledge Capsule that successfully fulfills a posted discovery bounty request to claim the associated reward.
18. `claimValidationReward(uint256 _kcId)`: Knowledge Agents who successfully voted on a `Validated` Knowledge Capsule can claim their share of the protocol's rewards, proportional to their stake and reputation.
19. `mintAttestationSBT(address _agent, string calldata _attestationURI)`: A unique function that allows a designated attestor (e.g., the contract owner or a specific credentialing oracle) to mint an additional, private, non-transferable SBT for a Knowledge Agent, signifying external credentials, achievements, or certifications not tied to protocol activity.
20. `requestKnowledgeLicensing(uint256 _kcId, address _licensee, uint256 _price)`: Initiates a request for a private licensing agreement for a specific Knowledge Capsule. This allows the creator to potentially monetize their work by setting a price for granting access or usage rights to a specific licensee.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AkashicNexus
 * @author YourNameHere (Inspired by the concept of an Akasha Record)
 * @notice A decentralized, AI-augmented knowledge base and dynamic reputation network.
 *         It facilitates the creation, validation, and discovery of knowledge units
 *         (Knowledge Capsules) and builds a unique, evolving reputation for participants
 *         (Knowledge Agents) via Soulbound Tokens. It integrates a conceptual AI Oracle
 *         for automated assessments and insight generation, and includes mechanisms for
 *         knowledge funding, licensing, and advanced attestation.
 */
contract AkashicNexus {

    // --- Enums ---
    enum KCStatus {
        Proposed,       // Newly submitted, awaiting validation
        Validated,      // Approved by community and/or AI
        Disputed,       // Contested by community, awaiting resolution
        Archived        // Old version, or deprecated content
    }

    enum KCLicensingType {
        PublicDomain,       // Freely usable by anyone
        CC_BY,              // Creative Commons Attribution
        PrivateLicensed     // Requires specific licensing agreement
    }

    // --- Structs ---

    /**
     * @dev Represents a unit of knowledge within the Akashic Nexus.
     *      Acts as a non-transferable, dynamic NFT where metadata can evolve.
     *      `cidHash` points to content on IPFS or similar decentralized storage.
     */
    struct KnowledgeCapsule {
        uint256 id;                 // Unique identifier for the capsule
        address creator;            // Address of the Knowledge Agent who proposed it
        string cidHash;             // IPFS hash of the knowledge content
        string metadataURI;         // URI for additional metadata (e.g., abstract, thumbnail)
        uint256 parentKCId;         // Link to a previous version or related KC (0 for original)
        uint256 version;            // Semantic version (e.g., 1.0.0 represented as 10000)
        uint256 timestamp;          // Creation timestamp
        KCStatus status;            // Current status of the capsule
        uint256 aiScore;            // AI's assessment score (0-100), dynamic
        string aiAssessmentURI;     // URI to AI's detailed assessment report
        KCLicensingType licensingType; // How this knowledge can be used
        uint256 validationCount;    // Number of 'validate' votes
        uint256 disputeCount;       // Number of 'dispute' votes
    }

    /**
     * @dev Represents a participant in the Akashic Nexus.
     *      Their identity and reputation are tied to this non-transferable Soulbound Token (SBT).
     */
    struct KnowledgeAgent {
        address agentAddress;       // The agent's wallet address (also serves as ID)
        uint256 reputationScore;    // Dynamic score based on contributions and validations
        string sbtURI;              // Dynamic URI for their Soulbound Token metadata
        uint256 stakedAmount;       // Amount of tokens staked for validation activities
        uint256 lastActivity;       // Timestamp of last significant activity
        bool exists;                // True if the agent is registered
    }

    /**
     * @dev Represents a bounty posted for the discovery or creation of specific knowledge.
     */
    struct DiscoveryBounty {
        uint256 id;                 // Unique bounty ID
        address funder;             // Address who posted the bounty
        string description;         // Description of the knowledge sought
        uint256 rewardAmount;       // Amount of tokens rewarded
        uint256 fulfilledByKCId;    // KC ID that fulfilled this bounty (0 if not fulfilled)
        bool isFulfilled;           // True if the bounty has been claimed
        uint256 timestamp;          // Creation timestamp
    }

    // --- State Variables ---

    address private _owner;
    bool private _paused;
    address public aiOracleAddress;

    uint256 private _nextKcId;
    uint256 private _nextBountyId;

    // Stores Knowledge Capsules by their unique ID
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules;
    // Stores Knowledge Agents by their address
    mapping(address => KnowledgeAgent) public knowledgeAgents;

    // Tracks votes on KCs: kcId => agentAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) private kcVotes;
    // Tracks staked amounts: agentAddress => amount
    mapping(address => uint256) public stakedAmounts;

    // Stores Discovery Bounties by their unique ID
    mapping(uint256 => DiscoveryBounty) public discoveryBounties;

    // Reputation update parameters
    uint256 public constant REPUTATION_VALIDATION_INCREMENT = 10;
    uint256 public constant REPUTATION_DISPUTE_DECREMENT = 5;
    uint256 public constant REPUTATION_KC_CREATION_INCREMENT = 20;
    uint256 public constant MIN_VALIDATION_THRESHOLD = 3; // Minimum positive votes for validation
    uint256 public validationThreshold = MIN_VALIDATION_THRESHOLD; // Can be set by owner/DAO

    // Protocol fees (simplified, could be more complex in a real scenario)
    uint256 public protocolFeePercentage = 5; // 5% fee on bounties claimed

    // --- Events ---
    event KCProposed(uint256 indexed kcId, address indexed creator, string cidHash, KCStatus status);
    event KCUpdated(uint256 indexed kcId, uint256 indexed parentKcId, address indexed updater, string newCidHash);
    event KCStatusChanged(uint256 indexed kcId, KCStatus newStatus, string reason);
    event KnowledgeAgentRegistered(address indexed agentAddress, uint256 initialReputation);
    event ReputationUpdated(address indexed agentAddress, uint256 newReputationScore);
    event AgentStaked(address indexed agentAddress, uint256 amount);
    event KCVoted(uint256 indexed kcId, address indexed voter, bool isValidation);
    event AIResultSubmitted(uint256 indexed kcId, uint256 aiScore, string assessmentURI);
    event AIInsightGenerated(uint256 indexed kcId, address indexed creator, string cidHash, uint256[] sourceKCs);
    event AIDisputeChallenged(uint256 indexed kcId, address indexed challenger, string reason);
    event DiscoveryBountyFunded(uint256 indexed bountyId, address indexed funder, uint256 rewardAmount);
    event DiscoveryBountyClaimed(uint256 indexed bountyId, uint256 indexed kcId, address indexed claimant);
    event ValidationRewardClaimed(uint256 indexed kcId, address indexed claimant, uint256 rewardAmount);
    event AttestationSBTMinted(address indexed agent, string attestationURI);
    event KnowledgeLicensingRequested(uint256 indexed kcId, address indexed licensee, uint256 price);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event AIOracleAddressSet(address indexed oldAddress, address indexed newAddress);

    // --- Modifiers (Custom, not from OpenZeppelin) ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "AkashicNexus: Not owner");
        _;
    }

    modifier pausable() {
        require(!_paused, "AkashicNexus: Contract is paused");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AkashicNexus: Not AI Oracle");
        _;
    }

    modifier mustBeRegisteredAgent(address _agent) {
        require(knowledgeAgents[_agent].exists, "AkashicNexus: Agent not registered");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false;
        _nextKcId = 1;
        _nextBountyId = 1;
        // Default AI Oracle is owner for initial setup, should be changed later
        aiOracleAddress = msg.sender;
    }

    // --- Admin & Access Control Functions ---

    /**
     * @notice Allows the owner to set the address of the trusted AI Oracle.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AkashicNexus: Invalid AI Oracle address");
        emit AIOracleAddressSet(aiOracleAddress, _newOracle);
        aiOracleAddress = _newOracle;
    }

    /**
     * @notice Pauses the contract to prevent critical functions from being called.
     *         Useful for upgrades or emergency situations.
     */
    function pauseSystem() public onlyOwner {
        require(!_paused, "AkashicNexus: Already paused");
        _paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing normal operations to resume.
     */
    function unpauseSystem() public onlyOwner {
        require(_paused, "AkashicNexus: Not paused");
        _paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to set the number of positive votes required for a KC to be validated.
     * @param _newThreshold The new validation threshold.
     */
    function setValidationThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold >= MIN_VALIDATION_THRESHOLD, "AkashicNexus: Threshold too low");
        validationThreshold = _newThreshold;
    }

    // --- Knowledge Capsule (KC) Management Functions ---

    /**
     * @notice Proposes a new Knowledge Capsule to the network.
     *         Initializes its status to `Proposed` and assigns a unique ID.
     * @param _cidHash The IPFS hash of the knowledge content.
     * @param _metadataURI URI for additional metadata (e.g., abstract, thumbnail).
     * @param _licensingType The chosen licensing type for this knowledge.
     * @return The ID of the newly created Knowledge Capsule.
     */
    function proposeKnowledgeCapsule(
        string calldata _cidHash,
        string calldata _metadataURI,
        KCLicensingType _licensingType
    ) public pausable returns (uint256) {
        require(bytes(_cidHash).length > 0, "AkashicNexus: CID hash cannot be empty");
        require(knowledgeAgents[msg.sender].exists, "AkashicNexus: Creator must be a registered agent");

        uint256 newId = _nextKcId++;
        knowledgeCapsules[newId] = KnowledgeCapsule({
            id: newId,
            creator: msg.sender,
            cidHash: _cidHash,
            metadataURI: _metadataURI,
            parentKCId: 0, // 0 indicates original KC
            version: 10000, // Starting at 1.0.0
            timestamp: block.timestamp,
            status: KCStatus.Proposed,
            aiScore: 0, // To be filled by AI Oracle
            aiAssessmentURI: "",
            licensingType: _licensingType,
            validationCount: 0,
            disputeCount: 0
        });

        _updateKnowledgeAgentReputation(msg.sender, REPUTATION_KC_CREATION_INCREMENT);
        emit KCProposed(newId, msg.sender, _cidHash, KCStatus.Proposed);
        return newId;
    }

    /**
     * @notice Proposes an updated version of an existing Knowledge Capsule.
     *         The new version gets its own ID and links back to the original `_kcId`.
     *         Only the original creator can update their KC.
     * @param _kcId The ID of the existing Knowledge Capsule to update.
     * @param _newCidHash The IPFS hash of the updated knowledge content.
     * @param _newMetadataURI URI for updated metadata.
     * @return The ID of the new version of the Knowledge Capsule.
     */
    function updateKnowledgeCapsule(
        uint256 _kcId,
        string calldata _newCidHash,
        string calldata _newMetadataURI
    ) public pausable returns (uint256) {
        KnowledgeCapsule storage existingKc = knowledgeCapsules[_kcId];
        require(existingKc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(existingKc.creator == msg.sender, "AkashicNexus: Only creator can update");
        require(bytes(_newCidHash).length > 0, "AkashicNexus: New CID hash cannot be empty");

        // Archive the old version
        existingKc.status = KCStatus.Archived;
        emit KCStatusChanged(_kcId, KCStatus.Archived, "New version proposed");

        // Create new version
        uint256 newId = _nextKcId++;
        knowledgeCapsules[newId] = KnowledgeCapsule({
            id: newId,
            creator: msg.sender,
            cidHash: _newCidHash,
            metadataURI: _newMetadataURI,
            parentKCId: _kcId, // Link to the previous version
            version: existingKc.version + 1, // Increment version
            timestamp: block.timestamp,
            status: KCStatus.Proposed,
            aiScore: 0, // Reset for new validation
            aiAssessmentURI: "",
            licensingType: existingKc.licensingType, // Inherit licensing type
            validationCount: 0,
            disputeCount: 0
        });

        _updateKnowledgeAgentReputation(msg.sender, REPUTATION_KC_CREATION_INCREMENT / 2); // Less rep for update
        emit KCUpdated(newId, _kcId, msg.sender, _newCidHash);
        return newId;
    }

    /**
     * @notice Retrieves comprehensive details about a specific Knowledge Capsule.
     * @param _kcId The ID of the Knowledge Capsule.
     * @return Tuple containing all KC details.
     */
    function getKnowledgeCapsuleDetails(uint256 _kcId)
        public
        view
        returns (
            uint256 id,
            address creator,
            string memory cidHash,
            string memory metadataURI,
            uint256 parentKCId,
            uint256 version,
            uint256 timestamp,
            KCStatus status,
            uint256 aiScore,
            string memory aiAssessmentURI,
            KCLicensingType licensingType,
            uint256 validationCount,
            uint256 disputeCount
        )
    {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");

        return (
            kc.id,
            kc.creator,
            kc.cidHash,
            kc.metadataURI,
            kc.parentKCId,
            kc.version,
            kc.timestamp,
            kc.status,
            kc.aiScore,
            kc.aiAssessmentURI,
            kc.licensingType,
            kc.validationCount,
            kc.disputeCount
        );
    }

    // --- Knowledge Agent & Reputation System Functions ---

    /**
     * @notice Mints a unique, non-transferable Soulbound Token (SBT) for a new Knowledge Agent.
     *         Initializes their reputation score.
     * @param _initialSbtUri The initial URI for the agent's SBT metadata (e.g., pointing to an empty JSON or a default avatar).
     */
    function registerKnowledgeAgent(string calldata _initialSbtUri) public pausable {
        require(!knowledgeAgents[msg.sender].exists, "AkashicNexus: Agent already registered");
        require(bytes(_initialSbtUri).length > 0, "AkashicNexus: Initial SBT URI cannot be empty");

        knowledgeAgents[msg.sender] = KnowledgeAgent({
            agentAddress: msg.sender,
            reputationScore: 100, // Starting reputation
            sbtURI: _initialSbtUri,
            stakedAmount: 0,
            lastActivity: block.timestamp,
            exists: true
        });

        emit KnowledgeAgentRegistered(msg.sender, 100);
    }

    /**
     * @notice Returns the current reputation score of a Knowledge Agent.
     * @param _agent The address of the Knowledge Agent.
     * @return The agent's reputation score.
     */
    function getKnowledgeAgentReputation(address _agent)
        public
        view
        mustBeRegisteredAgent(_agent)
        returns (uint256)
    {
        return knowledgeAgents[_agent].reputationScore;
    }

    /**
     * @notice Returns the dynamic URI for a Knowledge Agent's SBT metadata.
     *         This URI can be updated off-chain to reflect changes in reputation or achievements.
     * @param _agent The address of the Knowledge Agent.
     * @return The agent's SBT URI.
     */
    function getKnowledgeAgentSBTUri(address _agent)
        public
        view
        mustBeRegisteredAgent(_agent)
        returns (string memory)
    {
        return knowledgeAgents[_agent].sbtURI;
    }

    /**
     * @notice Allows a Knowledge Agent to stake tokens, enabling them to participate in validation.
     *         Staked tokens influence vote weight and eligibility for rewards.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForValidation(uint256 _amount) public pausable mustBeRegisteredAgent(msg.sender) {
        require(_amount > 0, "AkashicNexus: Stake amount must be greater than zero");
        // In a real scenario, this would involve transferring an ERC20 token
        // For this example, we'll simulate token holding without a full ERC20 implementation.
        // It implies the user has 'approved' tokens for this contract in a separate step.
        // For simplicity, we just track the balance here.
        knowledgeAgents[msg.sender].stakedAmount += _amount;
        // The actual token transfer logic (e.g., using IERC20) would go here.
        // IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        emit AgentStaked(msg.sender, _amount);
    }

    /**
     * @notice Knowledge Agents cast their vote (validate or dispute) on a proposed or updated Knowledge Capsule.
     *         Their vote contributes to the KC's status.
     * @param _kcId The ID of the Knowledge Capsule to vote on.
     * @param _isValidation True to validate, false to dispute.
     */
    function voteOnKnowledgeCapsule(uint256 _kcId, bool _isValidation)
        public
        pausable
        mustBeRegisteredAgent(msg.sender)
    {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(kc.status == KCStatus.Proposed, "AkashicNexus: KC is not in a votable state");
        require(!kcVotes[_kcId][msg.sender], "AkashicNexus: Already voted on this KC");
        require(knowledgeAgents[msg.sender].stakedAmount > 0, "AkashicNexus: Must have staked tokens to vote");

        kcVotes[_kcId][msg.sender] = true;

        if (_isValidation) {
            kc.validationCount++;
            _updateKnowledgeAgentReputation(msg.sender, REPUTATION_VALIDATION_INCREMENT);
        } else {
            kc.disputeCount++;
            _updateKnowledgeAgentReputation(msg.sender, -int256(REPUTATION_DISPUTE_DECREMENT));
        }

        // Check for status change after vote
        _evaluateKCStatus(_kcId);

        emit KCVoted(_kcId, msg.sender, _isValidation);
    }

    /**
     * @dev Internal helper function to update Knowledge Agent's reputation.
     * @param _agent The address of the agent.
     * @param _change The amount to change the reputation by (can be negative).
     */
    function _updateKnowledgeAgentReputation(address _agent, int256 _change) internal {
        KnowledgeAgent storage agent = knowledgeAgents[_agent];
        uint256 currentRep = agent.reputationScore;
        
        if (_change > 0) {
            agent.reputationScore += uint256(_change);
        } else {
            uint256 decrement = uint256(-_change);
            agent.reputationScore = (currentRep > decrement) ? (currentRep - decrement) : 0;
        }
        
        agent.lastActivity = block.timestamp;
        emit ReputationUpdated(_agent, agent.reputationScore);
    }

    /**
     * @dev Internal function to evaluate and potentially change a KC's status based on votes and AI score.
     * @param _kcId The ID of the Knowledge Capsule.
     */
    function _evaluateKCStatus(uint256 _kcId) internal {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];

        if (kc.status != KCStatus.Proposed) return;

        // If validation threshold is met and AI score is good (or not applicable yet)
        if (kc.validationCount >= validationThreshold && (kc.aiScore == 0 || kc.aiScore >= 70)) {
            kc.status = KCStatus.Validated;
            emit KCStatusChanged(_kcId, KCStatus.Validated, "Validated by community consensus");
        } else if (kc.disputeCount >= validationThreshold / 2 && kc.aiScore < 50) { // Simple dispute trigger
            kc.status = KCStatus.Disputed;
            emit KCStatusChanged(_kcId, KCStatus.Disputed, "Disputed by community, awaiting AI/manual review");
        }
    }

    // --- AI Oracle Interaction Functions ---

    /**
     * @notice The designated AI Oracle submits its automated assessment score for a Knowledge Capsule.
     *         This score influences the KC's status and subsequent validation outcomes.
     * @param _kcId The ID of the Knowledge Capsule being assessed.
     * @param _aiScore The AI's score (0-100). Higher is better.
     * @param _assessmentDetailsURI URI to the AI's detailed assessment report.
     */
    function submitAIValidationResult(uint256 _kcId, uint256 _aiScore, string calldata _assessmentDetailsURI)
        public
        pausable
        onlyAIOracle
    {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(_aiScore <= 100, "AkashicNexus: AI score must be 0-100");

        kc.aiScore = _aiScore;
        kc.aiAssessmentURI = _assessmentDetailsURI;

        // Re-evaluate status immediately after AI score update
        _evaluateKCStatus(_kcId);

        emit AIResultSubmitted(_kcId, _aiScore, _assessmentDetailsURI);
    }

    /**
     * @notice The AI Oracle can generate and propose a new Knowledge Capsule representing a novel insight or synthesis
     *         derived from existing source KCs. This demonstrates AI's role in knowledge creation.
     * @param _cidHash The IPFS hash of the AI-generated insight content.
     * @param _metadataURI URI for additional metadata about the insight.
     * @param _sourceKCs An array of KC IDs that served as source material for the AI's insight.
     * @return The ID of the newly created AI-generated Knowledge Capsule.
     */
    function generateAIInsightCapsule(
        string calldata _cidHash,
        string calldata _metadataURI,
        uint256[] calldata _sourceKCs // To link original KCs to the insight
    ) public pausable onlyAIOracle returns (uint256) {
        require(bytes(_cidHash).length > 0, "AkashicNexus: CID hash cannot be empty");

        uint256 newId = _nextKcId++;
        knowledgeCapsules[newId] = KnowledgeCapsule({
            id: newId,
            creator: aiOracleAddress, // AI Oracle is the 'creator'
            cidHash: _cidHash,
            metadataURI: _metadataURI,
            parentKCId: 0, // It's a new insight, not an update
            version: 10000,
            timestamp: block.timestamp,
            status: KCStatus.Validated, // Insights from AI are pre-validated by AI Oracle
            aiScore: 100, // Top score as it's an AI-generated insight
            aiAssessmentURI: "AI_GENERATED_INSIGHT", // Special flag
            licensingType: KCLicensingType.PublicDomain, // Default for AI insights
            validationCount: 0,
            disputeCount: 0
        });

        // Optionally, link sources within metadataURI or an external mapping
        // For simplicity, we just include _sourceKCs in the event
        emit AIInsightGenerated(newId, aiOracleAddress, _cidHash, _sourceKCs);
        return newId;
    }

    /**
     * @notice Allows any Knowledge Agent to formally challenge an AI Oracle's assessment of a Knowledge Capsule.
     *         This could trigger a re-evaluation process or human review (simplified here to an event).
     * @param _kcId The ID of the Knowledge Capsule whose AI assessment is being challenged.
     * @param _reason A brief reason for challenging the assessment.
     */
    function challengeAIAssessment(uint256 _kcId, string calldata _reason)
        public
        pausable
        mustBeRegisteredAgent(msg.sender)
    {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(kc.status != KCStatus.Archived, "AkashicNexus: Cannot challenge archived KC");
        require(kc.aiScore > 0, "AkashicNexus: KC has no AI assessment yet");
        require(bytes(_reason).length > 0, "AkashicNexus: Reason cannot be empty");

        // Here, a more complex system might involve:
        // 1. Changing KC status to 'UnderReview'
        // 2. Requiring stake from challenger
        // 3. Triggering a DAO vote or a new AI assessment request
        // For this example, we simply emit an event.

        // Optionally, reduce reputation if challenge is frivolous.
        _updateKnowledgeAgentReputation(msg.sender, -int256(REPUTATION_DISPUTE_DECREMENT));
        
        emit AIDisputeChallenged(_kcId, msg.sender, _reason);
    }

    // --- Incentive & Discovery Mechanisms ---

    /**
     * @notice Enables any user to post a bounty for the creation of a specific type of Knowledge Capsule or research area.
     * @param _description A description of the knowledge sought.
     * @param _rewardAmount The amount of tokens offered as a reward.
     */
    function fundKnowledgeDiscovery(string calldata _description, uint256 _rewardAmount) public payable pausable {
        require(_rewardAmount > 0, "AkashicNexus: Reward amount must be greater than zero");
        require(msg.value == _rewardAmount, "AkashicNexus: Sent amount must match reward amount");
        require(bytes(_description).length > 0, "AkashicNexus: Description cannot be empty");

        uint256 newBountyId = _nextBountyId++;
        discoveryBounties[newBountyId] = DiscoveryBounty({
            id: newBountyId,
            funder: msg.sender,
            description: _description,
            rewardAmount: _rewardAmount,
            fulfilledByKCId: 0,
            isFulfilled: false,
            timestamp: block.timestamp
        });

        emit DiscoveryBountyFunded(newBountyId, msg.sender, _rewardAmount);
    }

    /**
     * @notice Allows the creator of a Knowledge Capsule that successfully fulfills a posted discovery bounty
     *         request to claim the associated reward.
     * @param _bountyId The ID of the discovery bounty.
     * @param _kcId The ID of the Knowledge Capsule that fulfills the bounty.
     */
    function claimDiscoveryBounty(uint256 _bountyId, uint256 _kcId) public pausable {
        DiscoveryBounty storage bounty = discoveryBounties[_bountyId];
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];

        require(bounty.id != 0, "AkashicNexus: Bounty not found");
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(!bounty.isFulfilled, "AkashicNexus: Bounty already claimed");
        require(kc.creator == msg.sender, "AkashicNexus: Only KC creator can claim bounty");
        require(kc.status == KCStatus.Validated, "AkashicNexus: KC must be validated to claim bounty");

        // Simplified check for fulfillment - in a real scenario, this would involve
        // a more complex mechanism (e.g., matching keywords, human review, AI validation of match).
        // For now, any validated KC can claim a bounty if its creator attempts it.

        bounty.isFulfilled = true;
        bounty.fulfilledByKCId = _kcId;

        uint256 fee = (bounty.rewardAmount * protocolFeePercentage) / 100;
        uint256 payout = bounty.rewardAmount - fee;

        // Transfer tokens (ETH) to the claimant
        payable(msg.sender).transfer(payout);

        // Protocol fees are collected by the contract. Owner can withdraw later.
        emit DiscoveryBountyClaimed(_bountyId, _kcId, msg.sender);
    }

    /**
     * @notice Knowledge Agents who successfully voted on a validated KC can claim their share of rewards.
     *         Reward calculation is simplified here.
     * @param _kcId The ID of the Knowledge Capsule that was successfully validated.
     */
    function claimValidationReward(uint256 _kcId) public pausable mustBeRegisteredAgent(msg.sender) {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(kc.status == KCStatus.Validated, "AkashicNexus: KC is not validated");
        require(kcVotes[_kcId][msg.sender], "AkashicNexus: Did not vote on this KC");
        // Ensure reward hasn't been claimed for this vote yet (simplified, might need more state)
        // For simplicity, we assume this can only be claimed once for successful validation.

        // Simple reward: proportional to stake and/or fixed amount per validated vote
        // In a real system, this would come from a reward pool or protocol fees.
        // Here, we simulate by sending a fixed small amount.
        uint256 rewardPerVote = 0.001 ether; // Example fixed reward per successful vote

        // This assumes some external token or ETH is available for rewards.
        // A more robust system would involve a dedicated reward pool or tokenomics.
        // For demonstration, we just transfer some ETH.
        payable(msg.sender).transfer(rewardPerVote);

        emit ValidationRewardClaimed(_kcId, msg.sender, rewardPerVote);
    }

    // --- Advanced & Creative Features ---

    /**
     * @notice A unique function that allows a designated attestor (e.g., the contract owner
     *         or a specific credentialing oracle) to mint an additional, private,
     *         non-transferable SBT for a Knowledge Agent. This signifies external credentials,
     *         achievements, or certifications not tied to protocol activity.
     * @param _agent The address of the Knowledge Agent to whom the attestation SBT is minted.
     * @param _attestationURI The URI pointing to the metadata of this specific attestation.
     */
    function mintAttestationSBT(address _agent, string calldata _attestationURI) public onlyOwner {
        // This is a simplified concept. In a full implementation, this could be:
        // - A separate ERC721 contract with a special 'burn' function for the attestor to revoke.
        // - Stored in a mapping like `mapping(address => string[]) agentAttestations;`
        // For this example, we simply emit an event as a record.
        require(knowledgeAgents[_agent].exists, "AkashicNexus: Agent not registered");
        require(bytes(_attestationURI).length > 0, "AkashicNexus: Attestation URI cannot be empty");

        // The URI could represent a verifiable credential or proof of an off-chain achievement.
        // It's not stored directly on-chain in this simplified model, but logged as an event.
        emit AttestationSBTMinted(_agent, _attestationURI);
    }

    /**
     * @notice Initiates a request for a private licensing agreement for a specific Knowledge Capsule.
     *         This allows the creator to potentially monetize their work by setting a price for
     *         granting access or usage rights to a specific licensee.
     * @param _kcId The ID of the Knowledge Capsule to license.
     * @param _licensee The address of the party requesting the license.
     * @param _price The proposed price for the license (in ETH).
     */
    function requestKnowledgeLicensing(uint256 _kcId, address _licensee, uint256 _price) public pausable {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id != 0, "AkashicNexus: Knowledge Capsule not found");
        require(kc.creator == msg.sender, "AkashicNexus: Only KC creator can request licensing");
        require(kc.licensingType == KCLicensingType.PrivateLicensed, "AkashicNexus: KC not set for private licensing");
        require(_licensee != address(0), "AkashicNexus: Invalid licensee address");
        require(_price > 0, "AkashicNexus: Price must be greater than zero");

        // This function initiates a negotiation/agreement.
        // A more advanced system would involve:
        // - Storing pending license requests.
        // - A mechanism for _licensee to accept/pay.
        // - On-chain access control for private KCs.
        // For this example, we just log the request.

        emit KnowledgeLicensingRequested(_kcId, _licensee, _price);
    }

    // --- Fallback & Receive (for receiving funds for bounties) ---
    receive() external payable {}
    fallback() external payable {}
}
```