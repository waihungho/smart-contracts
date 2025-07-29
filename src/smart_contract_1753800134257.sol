Okay, this is an exciting challenge! Let's design a smart contract system that integrates several advanced, creative, and trending concepts without directly duplicating existing open-source projects.

The core idea revolves around a **Decentralized Reputation & Skill Progression System** with **Adaptive Soulbound NFTs**, **Verifiable Actions**, and **AI-Driven Insights**.

---

## AuraWeave Protocol: Genesis Contract

**Concept Overview:**

The AuraWeave Protocol is a decentralized system designed to establish, track, and reward user reputation and skill progression within a decentralized ecosystem. It leverages **Adaptive Soulbound Emblems (ASEs)** – non-transferable NFTs that dynamically evolve based on a user's accumulated **Aura (reputation points)** and verified on-chain/off-chain actions. The protocol integrates **oracle-based verification** for diverse proof types and features an **"Insight Nexus"** for AI-driven analytics/guidance based on user profiles, as well as **"Aetheric Forges"** which are privilege-gated resource pools.

**Key Innovative Concepts:**

1.  **Adaptive Soulbound Emblems (ASEs):** NFTs that are non-transferable (`_beforeTokenTransfer` check) and whose visual/metadata attributes (tiers, colors, effects) *dynamically change* based on a user's Aura score and unlocked skills. This isn't just metadata updates; it implies a deeper programmatic evolution.
2.  **Verifiable Actions Framework:** A generalized system where users submit cryptographic proofs (e.g., ZKP hashes, signed attestations) for various off-chain or complex on-chain actions. Designated "Verifiers" (controlled by the protocol or DAOs) then validate these proofs via oracles, leading to Aura awards.
3.  **Aura Decay Mechanism:** To prevent "dead" reputation and encourage continuous engagement, Aura points slowly decay over time, requiring users to maintain activity to preserve their standing.
4.  **Insight Nexus (AI-Driven):** An interface for users to request AI-driven insights or analysis based on their on-chain profile (Aura, ASE attributes, skills). An oracle fulfills these requests, bringing back AI model outputs.
5.  **Aetheric Forges (Dynamic Privilege Gates):** Decentralized resource pools or privilege gates whose access is dynamically controlled by a user's Aura, ASE tier, and specific unlocked skills, rather than simple token ownership.
6.  **Gamified Skill Tree:** Users can unlock "Skill Nodes" within their ASEs by meeting Aura thresholds or performing specific verified actions, further enhancing their profile and unlocking new capabilities.
7.  **Decentralized Parameter Governance (Light):** A simple voting mechanism for the community to propose and approve changes to protocol parameters (e.g., Aura decay rate, ASE upgrade costs).

---

**Outline & Function Summary:**

**I. Core Infrastructure & Admin (Inherits `Ownable`, `Pausable`, `AccessControl`)**
*   `constructor()`: Initializes roles, sets base parameters.
*   `pauseContract()`: Pauses core functionality in emergencies.
*   `unpauseContract()`: Resumes core functionality.
*   `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle contract for external data.
*   `addAuthorizedVerifier(address _verifier)`: Grants the `VERIFIER_ROLE` to an address.
*   `removeAuthorizedVerifier(address _verifier)`: Revokes the `VERIFIER_ROLE`.
*   `DEFAULT_ADMIN_ROLE`: Standard OpenZeppelin role for contract ownership/major configuration.
*   `VERIFIER_ROLE`: Custom role for entities authorized to award/deduct Aura based on verified actions.
*   `ORACLE_ROLE`: Custom role for the oracle service that fulfills insight requests and verifies external proofs.

**II. User & Profile Management**
*   `registerUser(string calldata _username)`: Registers a new user profile with a unique username.
*   `updateUserProfile(string calldata _newUsername, string calldata _newBioHash)`: Allows users to update their profile information.
*   `getUserProfile(address _user)`: Retrieves a user's profile details.

**III. Adaptive Soulbound Emblems (ASEs) - ERC721 Non-Transferable**
*   `mintAdaptiveSoulboundEmblem()`: Mints a new ASE for a user (one per user, non-transferable).
*   `getASEAttributes(address _user)`: Retrieves the current dynamic attributes (tier, color, effects) of a user's ASE.
*   `_updateASEBasedOnAura(address _user, uint256 _newAura)`: *Internal function* that recalculates and updates an ASE's dynamic attributes based on the new Aura score. Triggered by `awardAura` and `deductAura`.

**IV. Aura (Reputation) Management & Decay**
*   `getAuraBalance(address _user)`: Returns the current Aura balance for a user.
*   `awardAura(address _user, uint256 _amount, bytes32 _proofHash)`: Award Aura to a user after a verified action (only by `VERIFIER_ROLE`). Triggers ASE update.
*   `deductAura(address _user, uint256 _amount, string calldata _reason)`: Deduct Aura from a user (e.g., for negative behavior, by `VERIFIER_ROLE`). Triggers ASE update.
*   `setAuraDecayRate(uint256 _ratePerSecond)`: Sets the global Aura decay rate (Admin/Governance).
*   `processAuraDecay(address _user)`: Allows any user to trigger Aura decay for a specific user, incentivized by a small gas refund or reward.

**V. Verifiable Actions & Proof Framework**
*   `submitProofOfAction(bytes32 _proofHash, uint256 _actionType)`: User submits a cryptographic proof hash for an action.
*   `requestProofVerification(address _prover, bytes32 _proofHash, uint256 _actionType)`: A `VERIFIER_ROLE` requests the oracle to verify a submitted proof.
*   `fulfillProofVerification(bytes32 _proofHash, bool _isValid, uint256 _auraAmount, address _prover)`: Oracle callback confirming proof validity and triggering Aura award (only by `ORACLE_ROLE`).

**VI. Skill Tree Progression**
*   `unlockSkillNode(uint256 _nodeId)`: Allows a user to unlock a skill node if they meet the Aura/skill prerequisites.
*   `getSkillNodeStatus(address _user, uint256 _nodeId)`: Checks if a user has a specific skill node unlocked.
*   `defineSkillNode(uint256 _nodeId, uint256 _requiredAura, uint256[] calldata _prerequisiteNodes)`: Admin/Governance function to define new skill nodes and their prerequisites.

**VII. Insight Nexus (AI Integration)**
*   `requestInsightFromNexus(string calldata _queryType, bytes calldata _contextData)`: User requests an AI-driven insight, providing context data.
*   `fulfillInsightRequest(uint256 _requestId, string calldata _insightData)`: Oracle callback delivering AI insight results (only by `ORACLE_ROLE`).
*   `getInsightHistory(address _user, uint256 _requestId)`: Retrieves a past insight request and its result.

**VIII. Aetheric Forges (Privilege Gates)**
*   `createAethericForge(string calldata _name, string calldata _description, uint256 _minAuraRequired, uint256 _minASETierRequired, uint256[] calldata _requiredSkillNodes)`: Admin/Governance function to define a new Aetheric Forge and its access requirements.
*   `checkForgeAccess(address _user, uint256 _forgeId)`: Checks if a user meets the requirements to access a specific Aetheric Forge.
*   `grantForgeAccessManual(address _user, uint256 _forgeId)`: Admin override to grant manual access to a forge (e.g., for specific events).

**IX. Decentralized Protocol Parameter Governance (Light)**
*   `proposeProtocolParameterChange(uint256 _parameterId, uint256 _newValue, string calldata _description)`: Users with sufficient Aura can propose changes to certain protocol parameters.
*   `voteOnParameterChange(uint256 _proposalId, bool _support)`: Users with sufficient Aura can vote on active proposals.
*   `executeParameterChange(uint256 _proposalId)`: Executable by anyone after a proposal passes the voting threshold and grace period.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary:
//
// I. Core Infrastructure & Admin (Inherits Ownable, Pausable, AccessControl)
//    - constructor(): Initializes roles, sets base parameters.
//    - pauseContract(): Pauses core functionality in emergencies (DEFAULT_ADMIN_ROLE).
//    - unpauseContract(): Resumes core functionality (DEFAULT_ADMIN_ROLE).
//    - setOracleAddress(address _oracle): Sets the address of the trusted oracle contract for external data (DEFAULT_ADMIN_ROLE).
//    - addAuthorizedVerifier(address _verifier): Grants the VERIFIER_ROLE to an address (DEFAULT_ADMIN_ROLE).
//    - removeAuthorizedVerifier(address _verifier): Revokes the VERIFIER_ROLE (DEFAULT_ADMIN_ROLE).
//    - DEFAULT_ADMIN_ROLE: Standard OpenZeppelin role for contract ownership/major configuration.
//    - VERIFIER_ROLE: Custom role for entities authorized to award/deduct Aura based on verified actions.
//    - ORACLE_ROLE: Custom role for the oracle service that fulfills insight requests and verifies external proofs.
//
// II. User & Profile Management
//    - registerUser(string calldata _username): Registers a new user profile with a unique username.
//    - updateUserProfile(string calldata _newUsername, string calldata _newBioHash): Allows users to update their profile information.
//    - getUserProfile(address _user): Retrieves a user's profile details.
//
// III. Adaptive Soulbound Emblems (ASEs) - ERC721 Non-Transferable
//    - mintAdaptiveSoulboundEmblem(): Mints a new ASE for a user (one per user, non-transferable).
//    - getASEAttributes(address _user): Retrieves the current dynamic attributes (tier, color, effects) of a user's ASE.
//    - _updateASEBasedOnAura(address _user, uint256 _newAura): *Internal function* that recalculates and updates an ASE's dynamic attributes based on the new Aura score. Triggered by awardAura and deductAura.
//
// IV. Aura (Reputation) Management & Decay
//    - getAuraBalance(address _user): Returns the current Aura balance for a user.
//    - awardAura(address _user, uint256 _amount, bytes32 _proofHash): Award Aura to a user after a verified action (only by VERIFIER_ROLE). Triggers ASE update.
//    - deductAura(address _user, uint256 _amount, string calldata _reason): Deduct Aura from a user (e.g., for negative behavior, by VERIFIER_ROLE). Triggers ASE update.
//    - setAuraDecayRate(uint256 _ratePerSecond): Sets the global Aura decay rate (Admin/Governance).
//    - processAuraDecay(address _user): Allows any user to trigger Aura decay for a specific user, incentivized by a small gas refund or reward.
//
// V. Verifiable Actions & Proof Framework
//    - submitProofOfAction(bytes32 _proofHash, uint256 _actionType): User submits a cryptographic proof hash for an action.
//    - requestProofVerification(address _prover, bytes32 _proofHash, uint256 _actionType): A VERIFIER_ROLE requests the oracle to verify a submitted proof.
//    - fulfillProofVerification(bytes32 _proofHash, bool _isValid, uint256 _auraAmount, address _prover): Oracle callback confirming proof validity and triggering Aura award (only by ORACLE_ROLE).
//
// VI. Skill Tree Progression
//    - unlockSkillNode(uint256 _nodeId): Allows a user to unlock a skill node if they meet the Aura/skill prerequisites.
//    - getSkillNodeStatus(address _user, uint256 _nodeId): Checks if a user has a specific skill node unlocked.
//    - defineSkillNode(uint256 _nodeId, uint256 _requiredAura, uint256[] calldata _prerequisiteNodes): Admin/Governance function to define new skill nodes and their prerequisites.
//
// VII. Insight Nexus (AI Integration)
//    - requestInsightFromNexus(string calldata _queryType, bytes calldata _contextData): User requests an AI-driven insight, providing context data.
//    - fulfillInsightRequest(uint256 _requestId, string calldata _insightData): Oracle callback delivering AI insight results (only by ORACLE_ROLE).
//    - getInsightHistory(address _user, uint256 _requestId): Retrieves a past insight request and its result.
//
// VIII. Aetheric Forges (Privilege Gates)
//    - createAethericForge(string calldata _name, string calldata _description, uint256 _minAuraRequired, uint256 _minASETierRequired, uint256[] calldata _requiredSkillNodes): Admin/Governance function to define a new Aetheric Forge and its access requirements.
//    - checkForgeAccess(address _user, uint256 _forgeId): Checks if a user meets the requirements to access a specific Aetheric Forge.
//    - grantForgeAccessManual(address _user, uint256 _forgeId): Admin override to grant manual access to a forge (e.g., for specific events).
//
// IX. Decentralized Protocol Parameter Governance (Light)
//    - proposeProtocolParameterChange(uint256 _parameterId, uint256 _newValue, string calldata _description): Users with sufficient Aura can propose changes to certain protocol parameters.
//    - voteOnParameterChange(uint256 _proposalId, bool _support): Users with sufficient Aura can vote on active proposals.
//    - executeParameterChange(uint256 _proposalId): Executable by anyone after a proposal passes the voting threshold and grace period.


contract AuraWeaveProtocol is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- I. Core Infrastructure & Admin ---
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    address public oracleAddress;
    uint256 private _auraDecayRatePerSecond; // Aura points decayed per second

    // --- Data Structures ---

    // User Profiles
    struct UserProfile {
        string username;
        string bioHash; // Hash of off-chain bio content (e.g., IPFS hash)
        bool registered;
        uint256 lastAuraDecayProcessTime; // Timestamp of the last decay processing for this user
    }
    mapping(address => UserProfile) private _userProfiles;
    mapping(address => uint256) private _userAura; // User's current Aura points

    // Adaptive Soulbound Emblems (ASEs) - Non-transferable ERC721
    // ASEs are dynamically updated, their 'tier' and 'attributes' map to specific Aura ranges.
    struct ASEAttributes {
        uint256 tokenId;
        uint256 tier; // 0 (unminted), 1 (basic), 2, 3, ...
        string color; // Hex color, e.g., "#FFFFFF"
        string effect; // Descriptive effect, e.g., "Faint Glow", "Radiant Shimmer"
    }
    mapping(address => ASEAttributes) private _userASEs;
    mapping(uint256 => uint256) private _aseTierThresholds; // Tier -> min Aura required for that tier
    mapping(uint256 => string) private _aseTierColors;
    mapping(uint256 => string) private _aseTierEffects;
    Counters.Counter private _tokenIdCounter; // For ERC721 minting

    // Verifiable Actions
    struct ProofSubmission {
        address prover;
        bytes32 proofHash;
        uint256 actionType; // Categorization of the action (e.g., 1 for "community contribution", 2 for "bug bounty")
        uint256 submissionTime;
        bool verified;
        uint256 awardedAura;
    }
    mapping(bytes32 => ProofSubmission) private _proofSubmissions; // ProofHash -> ProofSubmission
    mapping(uint256 => bytes32[]) private _userProofs; // user's ID -> list of proof hashes (for tracking)

    // Skill Tree Progression
    struct SkillNode {
        uint256 nodeId;
        string name;
        uint256 requiredAura;
        uint256[] prerequisiteNodes; // Node IDs that must be unlocked first
        bool defined; // True if node exists
    }
    mapping(uint256 => SkillNode) private _skillNodes; // nodeId -> SkillNode details
    mapping(address => mapping(uint256 => bool)) private _userSkillNodes; // user -> nodeId -> unlocked status
    Counters.Counter private _skillNodeCounter;

    // Insight Nexus (AI Integration)
    struct InsightRequest {
        uint256 requestId;
        address requester;
        string queryType;
        bytes contextData; // Data relevant to the query (e.g., hash of private data for ZKP query)
        string insightResult; // Result provided by the oracle
        uint256 requestTime;
        bool fulfilled;
    }
    mapping(uint256 => InsightRequest) private _insightRequests;
    Counters.Counter private _insightRequestIdCounter;

    // Aetheric Forges (Privilege Gates)
    struct AethericForge {
        uint256 forgeId;
        string name;
        string description;
        uint256 minAuraRequired;
        uint256 minASETierRequired;
        uint256[] requiredSkillNodes; // Array of skill node IDs required for access
        bool defined;
    }
    mapping(uint256 => AethericForge) private _aetherForges;
    mapping(address => mapping(uint256 => bool)) private _manualForgeAccess; // For manual overrides
    Counters.Counter private _forgeIdCounter;

    // Decentralized Protocol Parameter Governance (Light)
    struct ParameterProposal {
        uint256 proposalId;
        uint256 parameterId; // Identifier for the parameter being changed
        uint256 newValue;
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User has voted on this proposal
        bool executed;
    }
    mapping(uint256 => ParameterProposal) private _proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public constant MIN_AURA_TO_PROPOSE = 1000;
    uint256 public constant MIN_AURA_TO_VOTE = 100;
    uint256 public constant VOTING_PERIOD_SECONDS = 7 days;
    uint256 public constant PROPOSAL_EXECUTION_GRACE_PERIOD_SECONDS = 1 days;
    uint256 public constant REQUIRED_VOTE_RATIO_BP = 6000; // 60% (6000 basis points)

    // Parameter IDs for governance
    uint256 public constant PARAM_AURA_DECAY_RATE = 1;
    uint256 public constant PARAM_MIN_AURA_TO_PROPOSE = 2;
    uint256 public constant PARAM_MIN_AURA_TO_VOTE = 3;

    // --- Events ---
    event UserRegistered(address indexed user, string username, uint256 timestamp);
    event UserProfileUpdated(address indexed user, string newUsername, string newBioHash);
    event ASEMinted(address indexed user, uint256 tokenId);
    event ASEAttributesUpdated(address indexed user, uint256 tokenId, uint256 newTier, string newColor, string newEffect);
    event AuraAwarded(address indexed user, uint256 amount, uint256 newBalance, bytes32 proofHash);
    event AuraDeducted(address indexed user, uint256 amount, uint256 newBalance, string reason);
    event AuraDecayed(address indexed user, uint256 oldBalance, uint256 newBalance, uint256 decayedAmount);
    event ProofOfActionSubmitted(address indexed user, bytes32 proofHash, uint256 actionType, uint256 submissionTime);
    event ProofVerificationRequested(address indexed verifier, address indexed prover, bytes32 proofHash, uint256 actionType);
    event ProofVerificationFulfilled(bytes32 proofHash, bool isValid, uint256 awardedAura, address indexed prover);
    event SkillNodeDefined(uint256 nodeId, string name, uint256 requiredAura);
    event SkillNodeUnlocked(address indexed user, uint256 nodeId);
    event InsightRequestMade(uint256 requestId, address indexed requester, string queryType);
    event InsightRequestFulfilled(uint256 requestId, string insightResult);
    event AethericForgeCreated(uint256 forgeId, string name, uint256 minAura, uint256 minTier);
    event ForgeAccessGranted(address indexed user, uint256 forgeId, bool manualOverride);
    event ParameterChangeProposed(uint256 proposalId, uint256 parameterId, uint256 newValue, address indexed proposer);
    event ParameterVoteCast(uint256 proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 proposalId, uint256 parameterId, uint256 newValue);
    event OracleAddressSet(address indexed newOracleAddress);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _auraDecayRatePerSecond = 0; // Default to no decay
        _skillNodeCounter.increment(); // Initialize counter for skill nodes
        _forgeIdCounter.increment(); // Initialize counter for forges
        _insightRequestIdCounter.increment(); // Initialize counter for insight requests
        _proposalIdCounter.increment(); // Initialize counter for proposals

        // Define initial ASE tiers
        _aseTierThresholds[1] = 0; // Base tier, no aura needed
        _aseTierColors[1] = "#A9A9A9"; // Dim Gray
        _aseTierEffects[1] = "Dormant";

        _aseTierThresholds[2] = 500; // Tier 2
        _aseTierColors[2] = "#FDD2B0"; // Light Gold
        _aseTierEffects[2] = "Faint Glow";

        _aseTierThresholds[3] = 2000; // Tier 3
        _aseTierColors[3] = "#B0E0E6"; // Powder Blue
        _aseTierEffects[3] = "Subtle Shimmer";

        _aseTierThresholds[4] = 5000; // Tier 4
        _aseTierColors[4] = "#D8BFD8"; // Thistle
        _aseTierEffects[4] = "Luminescent Bloom";

        _aseTierThresholds[5] = 10000; // Tier 5 (Highest)
        _aseTierColors[5] = "#FFD700"; // Gold
        _aseTierEffects[5] = "Radiant Aura";
    }

    // --- I. Core Infrastructure & Admin Functions ---

    function pauseContract() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseContract() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setOracleAddress(address _oracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_oracle != address(0), "AuraWeave: Invalid oracle address");
        oracleAddress = _oracle;
        _grantRole(ORACLE_ROLE, _oracle); // Grant the ORACLE_ROLE to the new oracle
        emit OracleAddressSet(_oracle);
    }

    function addAuthorizedVerifier(address _verifier) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_verifier != address(0), "AuraWeave: Invalid verifier address");
        _grantRole(VERIFIER_ROLE, _verifier);
        emit VerifierAdded(_verifier);
    }

    function removeAuthorizedVerifier(address _verifier) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_verifier != address(0), "AuraWeave: Invalid verifier address");
        _revokeRole(VERIFIER_ROLE, _verifier);
        emit VerifierRemoved(_verifier);
    }

    // --- II. User & Profile Management ---

    function registerUser(string calldata _username) public whenNotPaused {
        require(!_userProfiles[msg.sender].registered, "AuraWeave: User already registered");
        require(bytes(_username).length > 0, "AuraWeave: Username cannot be empty");

        _userProfiles[msg.sender] = UserProfile({
            username: _username,
            bioHash: "", // Empty bio initially
            registered: true,
            lastAuraDecayProcessTime: block.timestamp // Initialize decay time
        });
        emit UserRegistered(msg.sender, _username, block.timestamp);
    }

    function updateUserProfile(string calldata _newUsername, string calldata _newBioHash) public whenNotPaused {
        require(_userProfiles[msg.sender].registered, "AuraWeave: User not registered");
        require(bytes(_newUsername).length > 0, "AuraWeave: Username cannot be empty");

        _userProfiles[msg.sender].username = _newUsername;
        _userProfiles[msg.sender].bioHash = _newBioHash;
        emit UserProfileUpdated(msg.sender, _newUsername, _newBioHash);
    }

    function getUserProfile(address _user) public view returns (UserProfile memory) {
        require(_userProfiles[_user].registered, "AuraWeave: User not registered");
        return _userProfiles[_user];
    }

    // --- III. Adaptive Soulbound Emblems (ASEs) - ERC721 Non-Transferable ---

    function mintAdaptiveSoulboundEmblem() public whenNotPaused {
        require(_userProfiles[msg.sender].registered, "AuraWeave: User not registered");
        require(_userASEs[msg.sender].tokenId == 0, "AuraWeave: User already has an ASE");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        
        _safeMint(msg.sender, newTokenId); // Mint ERC721 token
        _userASEs[msg.sender] = ASEAttributes({
            tokenId: newTokenId,
            tier: 1, // Start at base tier
            color: _aseTierColors[1],
            effect: _aseTierEffects[1]
        });
        emit ASEMinted(msg.sender, newTokenId);

        // Immediately update ASE attributes based on current Aura (which is 0 initially)
        _updateASEBasedOnAura(msg.sender, 0);
    }

    function getASEAttributes(address _user) public view returns (uint256 tokenId, uint256 tier, string memory color, string memory effect) {
        require(_userASEs[_user].tokenId != 0, "AuraWeave: User does not have an ASE");
        ASEAttributes storage ase = _userASEs[_user];
        return (ase.tokenId, ase.tier, ase.color, ase.effect);
    }

    // Prevents ERC721 transfers, making it Soulbound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Only allow minting (from address(0)) and burning (to address(0))
        require(from == address(0) || to == address(0), "AuraWeave: ASEs are soulbound and cannot be transferred.");
    }

    function _updateASEBasedOnAura(address _user, uint256 _newAura) internal {
        if (_userASEs[_user].tokenId == 0) { // Only update if an ASE exists
            return;
        }

        uint256 currentTier = _userASEs[_user].tier;
        uint256 newTier = 1; // Default to base tier

        // Determine new tier based on Aura thresholds
        for (uint256 i = 5; i >= 1; i--) { // Iterate from highest tier downwards
            if (_newAura >= _aseTierThresholds[i]) {
                newTier = i;
                break;
            }
        }

        // Update if tier has changed
        if (newTier != currentTier) {
            _userASEs[_user].tier = newTier;
            _userASEs[_user].color = _aseTierColors[newTier];
            _userASEs[_user].effect = _aseTierEffects[newTier];
            
            // Optionally update ERC721 metadata URI here by calling a `_setTokenURI` function
            // This would typically involve off-chain generation of metadata based on current attributes
            // _setTokenURI(_userASEs[_user].tokenId, _generateTokenURI(_user, newTier)); 
            
            emit ASEAttributesUpdated(_user, _userASEs[_user].tokenId, newTier, _aseTierColors[newTier], _aseTierEffects[newTier]);
        }
    }

    // --- IV. Aura (Reputation) Management & Decay ---

    function getAuraBalance(address _user) public view returns (uint256) {
        // Calculate potential decay before returning balance
        if (_userProfiles[_user].registered && _auraDecayRatePerSecond > 0 && _userAura[_user] > 0) {
            uint256 timeElapsed = block.timestamp.sub(_userProfiles[_user].lastAuraDecayProcessTime);
            uint256 decayAmount = timeElapsed.mul(_auraDecayRatePerSecond);
            return _userAura[_user].sub(decayAmount > _userAura[_user] ? _userAura[_user] : decayAmount);
        }
        return _userAura[_user];
    }

    function awardAura(address _user, uint256 _amount, bytes32 _proofHash) public virtual onlyRole(VERIFIER_ROLE) whenNotPaused {
        require(_userProfiles[_user].registered, "AuraWeave: User not registered");
        require(_amount > 0, "AuraWeave: Aura amount must be positive");
        require(_proofSubmissions[_proofHash].verified, "AuraWeave: Proof not yet verified");
        require(_proofSubmissions[_proofHash].awardedAura == 0, "AuraWeave: Aura already awarded for this proof");
        require(_proofSubmissions[_proofHash].prover == _user, "AuraWeave: Proof belongs to different user");

        _processAuraDecayInternal(_user); // Process decay before awarding
        uint256 currentAura = _userAura[_user];
        _userAura[_user] = currentAura.add(_amount);
        
        _proofSubmissions[_proofHash].awardedAura = _amount; // Mark as awarded

        _updateASEBasedOnAura(_user, _userAura[_user]);
        emit AuraAwarded(_user, _amount, _userAura[_user], _proofHash);
    }

    function deductAura(address _user, uint256 _amount, string calldata _reason) public virtual onlyRole(VERIFIER_ROLE) whenNotPaused {
        require(_userProfiles[_user].registered, "AuraWeave: User not registered");
        require(_amount > 0, "AuraWeave: Aura amount must be positive");
        require(_userAura[_user] >= _amount, "AuraWeave: Not enough Aura to deduct");

        _processAuraDecayInternal(_user); // Process decay before deducting
        uint256 currentAura = _userAura[_user];
        _userAura[_user] = currentAura.sub(_amount);

        _updateASEBasedOnAura(_user, _userAura[_user]);
        emit AuraDeducted(_user, _amount, _userAura[_user], _reason);
    }

    function setAuraDecayRate(uint256 _ratePerSecond) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _auraDecayRatePerSecond = _ratePerSecond;
    }

    function processAuraDecay(address _user) public whenNotPaused {
        require(_userProfiles[_user].registered, "AuraWeave: User not registered");
        _processAuraDecayInternal(_user);
    }

    function _processAuraDecayInternal(address _user) internal {
        if (_auraDecayRatePerSecond == 0 || _userAura[_user] == 0) {
            _userProfiles[_user].lastAuraDecayProcessTime = block.timestamp;
            return; // No decay or no aura to decay
        }

        uint256 lastProcessed = _userProfiles[_user].lastAuraDecayProcessTime;
        uint256 timeElapsed = block.timestamp.sub(lastProcessed);
        
        uint256 decayAmount = timeElapsed.mul(_auraDecayRatePerSecond);
        uint256 oldAura = _userAura[_user];

        if (decayAmount >= oldAura) {
            _userAura[_user] = 0; // Aura fully decayed
        } else {
            _userAura[_user] = oldAura.sub(decayAmount);
        }

        _userProfiles[_user].lastAuraDecayProcessTime = block.timestamp;
        emit AuraDecayed(_user, oldAura, _userAura[_user], decayAmount);
        _updateASEBasedOnAura(_user, _userAura[_user]); // Update ASE after decay
    }

    // --- V. Verifiable Actions & Proof Framework ---

    function submitProofOfAction(bytes32 _proofHash, uint256 _actionType) public whenNotPaused {
        require(_userProfiles[msg.sender].registered, "AuraWeave: User not registered");
        require(_proofSubmissions[_proofHash].prover == address(0), "AuraWeave: Proof already submitted");

        _proofSubmissions[_proofHash] = ProofSubmission({
            prover: msg.sender,
            proofHash: _proofHash,
            actionType: _actionType,
            submissionTime: block.timestamp,
            verified: false,
            awardedAura: 0
        });
        _userProofs[msg.sender].push(_proofHash); // Track proofs per user
        emit ProofOfActionSubmitted(msg.sender, _proofHash, _actionType, block.timestamp);
    }

    function requestProofVerification(bytes32 _proofHash) public onlyRole(VERIFIER_ROLE) whenNotPaused {
        require(_proofSubmissions[_proofHash].prover != address(0), "AuraWeave: Proof not found");
        require(!_proofSubmissions[_proofHash].verified, "AuraWeave: Proof already verified");
        
        // This function would typically trigger an off-chain oracle service
        // The oracle service would then call fulfillProofVerification back.
        // For demonstration, we'll assume the oracle directly verifies and calls back.
        emit ProofVerificationRequested(msg.sender, _proofSubmissions[_proofHash].prover, _proofHash, _proofSubmissions[_proofHash].actionType);
    }

    function fulfillProofVerification(bytes32 _proofHash, bool _isValid, uint256 _auraAmount, address _prover) public virtual onlyRole(ORACLE_ROLE) whenNotPaused {
        require(_proofSubmissions[_proofHash].prover != address(0), "AuraWeave: Proof not found");
        require(!_proofSubmissions[_proofHash].verified, "AuraWeave: Proof already verified");
        require(_proofSubmissions[_proofHash].prover == _prover, "AuraWeave: Prover address mismatch");

        _proofSubmissions[_proofHash].verified = true;
        
        if (_isValid) {
            awardAura(_prover, _auraAmount, _proofHash); // Use the internal awardAura
        } else {
            // Optionally, handle invalid proofs (e.g., mark for review)
        }
        emit ProofVerificationFulfilled(_proofHash, _isValid, _auraAmount, _prover);
    }

    // --- VI. Skill Tree Progression ---

    function defineSkillNode(uint256 _nodeId, string calldata _name, uint256 _requiredAura, uint256[] calldata _prerequisiteNodes) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_skillNodes[_nodeId].defined, "AuraWeave: Skill node already defined");
        _skillNodes[_nodeId] = SkillNode({
            nodeId: _nodeId,
            name: _name,
            requiredAura: _requiredAura,
            prerequisiteNodes: _prerequisiteNodes,
            defined: true
        });
        emit SkillNodeDefined(_nodeId, _name, _requiredAura);
    }

    function unlockSkillNode(uint256 _nodeId) public whenNotPaused {
        require(_userProfiles[msg.sender].registered, "AuraWeave: User not registered");
        require(_userASEs[msg.sender].tokenId != 0, "AuraWeave: User must have an ASE");
        require(_skillNodes[_nodeId].defined, "AuraWeave: Skill node not defined");
        require(!_userSkillNodes[msg.sender][_nodeId], "AuraWeave: Skill node already unlocked");

        // Process Aura decay before checking requirements
        _processAuraDecayInternal(msg.sender); 

        require(_userAura[msg.sender] >= _skillNodes[_nodeId].requiredAura, "AuraWeave: Insufficient Aura to unlock skill");

        // Check prerequisites
        for (uint256 i = 0; i < _skillNodes[_nodeId].prerequisiteNodes.length; i++) {
            require(_userSkillNodes[msg.sender][_skillNodes[_nodeId].prerequisiteNodes[i]], "AuraWeave: Prerequisite skill node not unlocked");
        }

        _userSkillNodes[msg.sender][_nodeId] = true;
        emit SkillNodeUnlocked(msg.sender, _nodeId);
    }

    function getSkillNodeStatus(address _user, uint256 _nodeId) public view returns (bool unlocked) {
        return _userSkillNodes[_user][_nodeId];
    }

    // --- VII. Insight Nexus (AI Integration) ---

    function requestInsightFromNexus(string calldata _queryType, bytes calldata _contextData) public whenNotPaused returns (uint256 requestId) {
        require(_userProfiles[msg.sender].registered, "AuraWeave: User not registered");
        require(oracleAddress != address(0), "AuraWeave: Oracle address not set");

        _insightRequestIdCounter.increment();
        uint256 newRequestId = _insightRequestIdCounter.current();

        _insightRequests[newRequestId] = InsightRequest({
            requestId: newRequestId,
            requester: msg.sender,
            queryType: _queryType,
            contextData: _contextData,
            insightResult: "", // Will be filled by oracle
            requestTime: block.timestamp,
            fulfilled: false
        });
        emit InsightRequestMade(newRequestId, msg.sender, _queryType);
        return newRequestId;
    }

    function fulfillInsightRequest(uint256 _requestId, string calldata _insightData) public onlyRole(ORACLE_ROLE) whenNotPaused {
        require(_insightRequests[_requestId].requester != address(0), "AuraWeave: Insight request not found");
        require(!_insightRequests[_requestId].fulfilled, "AuraWeave: Insight request already fulfilled");

        _insightRequests[_requestId].insightResult = _insightData;
        _insightRequests[_requestId].fulfilled = true;
        emit InsightRequestFulfilled(_requestId, _insightData);
    }

    function getInsightHistory(uint256 _requestId) public view returns (InsightRequest memory) {
        require(_insightRequests[_requestId].requester == msg.sender, "AuraWeave: Not your insight request");
        require(_insightRequests[_requestId].requester != address(0), "AuraWeave: Insight request not found");
        return _insightRequests[_requestId];
    }

    // --- VIII. Aetheric Forges (Privilege Gates) ---

    function createAethericForge(
        string calldata _name,
        string calldata _description,
        uint256 _minAuraRequired,
        uint256 _minASETierRequired,
        uint256[] calldata _requiredSkillNodes
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _forgeIdCounter.increment();
        uint256 newForgeId = _forgeIdCounter.current();

        _aetherForges[newForgeId] = AethericForge({
            forgeId: newForgeId,
            name: _name,
            description: _description,
            minAuraRequired: _minAuraRequired,
            minASETierRequired: _minASETierRequired,
            requiredSkillNodes: _requiredSkillNodes,
            defined: true
        });
        emit AethericForgeCreated(newForgeId, _name, _minAuraRequired, _minASETierRequired);
    }

    function checkForgeAccess(address _user, uint256 _forgeId) public view returns (bool hasAccess) {
        require(_aetherForges[_forgeId].defined, "AuraWeave: Forge not defined");
        require(_userProfiles[_user].registered, "AuraWeave: User not registered");
        require(_userASEs[_user].tokenId != 0, "AuraWeave: User must have an ASE");

        // Manual override always grants access
        if (_manualForgeAccess[_user][_forgeId]) {
            return true;
        }

        // Check Aura requirement
        if (getAuraBalance(_user) < _aetherForges[_forgeId].minAuraRequired) {
            return false;
        }

        // Check ASE Tier requirement
        if (_userASEs[_user].tier < _aetherForges[_forgeId].minASETierRequired) {
            return false;
        }

        // Check Skill Node requirements
        for (uint256 i = 0; i < _aetherForges[_forgeId].requiredSkillNodes.length; i++) {
            if (!_userSkillNodes[_user][_aetherForges[_forgeId].requiredSkillNodes[i]]) {
                return false;
            }
        }

        return true;
    }

    function grantForgeAccessManual(address _user, uint256 _forgeId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_aetherForges[_forgeId].defined, "AuraWeave: Forge not defined");
        require(_userProfiles[_user].registered, "AuraWeave: User not registered");
        _manualForgeAccess[_user][_forgeId] = true;
        emit ForgeAccessGranted(_user, _forgeId, true);
    }

    // --- IX. Decentralized Protocol Parameter Governance (Light) ---

    function proposeProtocolParameterChange(
        uint256 _parameterId,
        uint256 _newValue,
        string calldata _description
    ) public whenNotPaused returns (uint256 proposalId) {
        _processAuraDecayInternal(msg.sender); // Process Aura decay before checking balance
        require(_userAura[msg.sender] >= MIN_AURA_TO_PROPOSE, "AuraWeave: Insufficient Aura to propose");
        
        // Basic validation for parameter ID
        require(_parameterId == PARAM_AURA_DECAY_RATE || _parameterId == PARAM_MIN_AURA_TO_PROPOSE || _parameterId == PARAM_MIN_AURA_TO_VOTE, "AuraWeave: Invalid parameter ID");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        _proposals[newProposalId] = ParameterProposal({
            proposalId: newProposalId,
            parameterId: _parameterId,
            newValue: _newValue,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(VOTING_PERIOD_SECONDS),
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ParameterChangeProposed(newProposalId, _parameterId, _newValue, msg.sender);
        return newProposalId;
    }

    function voteOnParameterChange(uint256 _proposalId, bool _support) public whenNotPaused {
        _processAuraDecayInternal(msg.sender); // Process Aura decay before checking balance
        require(_userAura[msg.sender] >= MIN_AURA_TO_VOTE, "AuraWeave: Insufficient Aura to vote");
        require(_proposals[_proposalId].creationTime != 0, "AuraWeave: Proposal does not exist");
        require(block.timestamp <= _proposals[_proposalId].votingEndTime, "AuraWeave: Voting period has ended");
        require(!_proposals[_proposalId].hasVoted[msg.sender], "AuraWeave: Already voted on this proposal");

        if (_support) {
            _proposals[_proposalId].votesFor = _proposals[_proposalId].votesFor.add(1);
        } else {
            _proposals[_proposalId].votesAgainst = _proposals[_proposalId].votesAgainst.add(1);
        }
        _proposals[_proposalId].hasVoted[msg.sender] = true;
        emit ParameterVoteCast(_proposalId, msg.sender, _support);
    }

    function executeParameterChange(uint256 _proposalId) public whenNotPaused {
        ParameterProposal storage proposal = _proposals[_proposalId];
        require(proposal.creationTime != 0, "AuraWeave: Proposal does not exist");
        require(!proposal.executed, "AuraWeave: Proposal already executed");
        require(block.timestamp > proposal.votingEndTime, "AuraWeave: Voting period not ended");
        require(block.timestamp <= proposal.votingEndTime.add(PROPOSAL_EXECUTION_GRACE_PERIOD_SECONDS), "AuraWeave: Execution grace period ended");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "AuraWeave: No votes cast for this proposal");

        uint256 supportRatio = proposal.votesFor.mul(10000).div(totalVotes); // Basis points
        require(supportRatio >= REQUIRED_VOTE_RATIO_BP, "AuraWeave: Proposal did not meet required support ratio");

        // Execute the parameter change
        if (proposal.parameterId == PARAM_AURA_DECAY_RATE) {
            _auraDecayRatePerSecond = proposal.newValue;
        } else if (proposal.parameterId == PARAM_MIN_AURA_TO_PROPOSE) {
            MIN_AURA_TO_PROPOSE = proposal.newValue;
        } else if (proposal.parameterId == PARAM_MIN_AURA_TO_VOTE) {
            MIN_AURA_TO_VOTE = proposal.newValue;
        } else {
            revert("AuraWeave: Unknown parameter for execution");
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(proposal.proposalId, proposal.parameterId, proposal.newValue);
    }

    // --- Helper for ERC721 metadata (off-chain) ---
    // This function would typically generate a URI pointing to off-chain JSON metadata
    // that describes the ASE's current attributes.
    function _baseURI() internal pure override returns (string memory) {
        return "https://auraweave.io/ase/metadata/"; // Base URI for ASE metadata
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address owner = ownerOf(tokenId);
        ASEAttributes storage ase = _userASEs[owner];

        // This is a placeholder. In a real application, you'd compose a dynamic URI
        // or a URI that triggers an off-chain service to generate dynamic metadata.
        // Example: "https://auraweave.io/ase/metadata/1?tier=3&color=B0E0E6&effect=Shimmer"
        return string(abi.encodePacked(_baseURI(), tokenId.toString(),
            "?tier=", ase.tier.toString(),
            "&color=", ase.color,
            "&effect=", ase.effect
        ));
    }
}
```