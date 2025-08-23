Here's a Solidity smart contract, `VeritasPersonaCore`, designed with advanced, creative, and trendy concepts. It focuses on building a decentralized, self-sovereign identity system where users accumulate verifiable knowledge, reputation, and skills. It incorporates elements of Soulbound Tokens (SBTs), dynamic NFTs, decentralized reputation, skill-based access control, and a mechanism to facilitate privacy-preserving attestations via zero-knowledge proofs.

---

## VeritasPersonaCore Smart Contract

This contract establishes `VeritasPersonaCore` – a system for managing dynamic, soulbound identities that accrue verifiable skills, reputation, and knowledge points through on-chain and oracle-verified contributions. It acts as a foundational layer for a decentralized meritocracy, enabling advanced governance, skill-based access control, and a privacy-preserving reputation system.

### Outline

1.  **Contract Header & SPDX License**
2.  **Imports:** OpenZeppelin's `ERC721`, `ERC721URIStorage`, `AccessControl`, `ReentrancyGuard`, `Ownable` (for initial setup of `DEFAULT_ADMIN_ROLE`).
3.  **Error Definitions:** Custom errors for clarity and gas efficiency.
4.  **Events:** For all significant state changes and record-keeping.
5.  **Constants & Role Definitions:** Defines specific roles within the system (e.g., Fact Validators, Skill Auditors, System Keepers).
6.  **Structs:**
    *   `Persona`: Holds the core attributes of an identity (owner, bio, KPs, Reputation, last decay timestamp, etc.).
    *   `SkillCategory`: Defines a skill's name and description.
    *   `ActionReward`: Configures KP and Reputation rewards for various actions.
7.  **Core Contract `VeritasPersonaCore`**
    *   **State Variables:** Mappings to store personas, skill proficiencies, skill categories, action rewards, challenge details, and system parameters.
    *   **Constructor:** Initializes ERC721, AccessControl, and sets the deployer as the default admin.
    *   **Modifiers:** `onlyPersonaOwner`, `onlyRole`.
    *   **Internal Functions:** `_mint`, `_burn`, `_beforeTokenTransfer` (implements Soulbound logic).
    *   **I. Core Persona Management (5 functions)**
        *   `mintPersona`: Mints a new soulbound persona.
        *   `updatePersonaBio`: Allows owner to update their public bio.
        *   `burnPersona`: Allows owner to burn their persona (self-sovereignty).
        *   `getPersonaDetails`: Retrieves all public persona details.
        *   `getPersonaTokenId`: Retrieves the persona ID for a given owner address.
    *   **II. Dynamic Attributes & Accrual (5 functions)**
        *   `registerFactContribution`: Rewards a persona for a verified fact contribution (called by `FACT_VALIDATOR_ROLE`).
        *   `submitPeerReview`: Records a peer review, rewarding the reviewer (called by `REVIEWER_ROLE`).
        *   `completeAlgorithmicChallenge`: Rewards a persona for solving an on-chain challenge.
        *   `curateKnowledgeModule`: Rewards a persona for knowledge module curation (called by `CURATOR_ROLE`).
        *   `decayPersonaScores`: Periodically decays ReputationScore and SkillProficiencies.
    *   **III. Skill Proficiencies & Advancement (5 functions)**
        *   `attestSkillProficiency`: Increases a persona's skill proficiency (called by `SKILL_AUDITOR_ROLE`).
        *   `getSkillProficiency`: Retrieves a persona's specific skill level.
        *   `registerNewSkillCategory`: Defines a new skill category (called by `ADMIN_ROLE`).
        *   `getOverallPersonaRank`: Calculates a persona's aggregate rank.
        *   `getUnlockedTraits`: Returns a list of traits a persona has unlocked.
    *   **IV. Access Control & System Configuration (7 functions)**
        *   `grantRole`: Grants a specified role to an account.
        *   `revokeRole`: Revokes a specified role from an account.
        *   `hasRole`: Checks if an account possesses a specific role.
        *   `configureRewardSystem`: Sets KP and Reputation rewards for different actions.
        *   `setDecayParameters`: Configures the reputation/skill decay mechanism.
        *   `setChallengeDetails`: Sets up a new algorithmic challenge.
        *   `queryPersonaStateHash`: Provides a hash of the persona's verifiable state for ZK-proof generation.

### Function Summary

**I. Core Persona Management**

1.  `mintPersona(string _bio)`: Mints a new `VeritasPersona` (an ERC721 Soulbound Token) for `msg.sender` with an initial biography.
2.  `updatePersonaBio(uint256 _tokenId, string _newBio)`: Allows the owner of a persona to update their public biography string associated with their `tokenId`.
3.  `burnPersona(uint256 _tokenId)`: Enables the owner of a persona to irrevocably burn their `VeritasPersona`, emphasizing self-sovereignty over their digital identity.
4.  `getPersonaDetails(uint256 _tokenId)`: Retrieves all publicly accessible details (owner, bio, knowledge points, reputation, skills) for a given `tokenId`.
5.  `getPersonaTokenId(address _owner)`: Returns the `tokenId` associated with a specific address, or 0 if no persona exists for that address.

**II. Dynamic Attributes & Accrual**

6.  `registerFactContribution(uint256 _tokenId, bytes32 _factHash, uint256 _kpReward)`: **(Role: `FACT_VALIDATOR_ROLE`)** Rewards a persona with Knowledge Points (KPs) and Reputation Score for submitting a verifiably true fact, where `_factHash` represents the unique, immutable data.
7.  `submitPeerReview(uint256 _reviewerTokenId, uint256 _reviewedTokenId, bool _isApproved, bytes32 _reviewContentHash)`: **(Role: `REVIEWER_ROLE`)** Records a peer review action, potentially rewarding the `_reviewerTokenId` persona based on their existing reputation and increasing/decreasing `_reviewedTokenId`'s reputation.
8.  `completeAlgorithmicChallenge(uint256 _tokenId, uint256 _challengeId, bytes32 _solutionHash)`: Rewards a persona with KPs and Reputation for successfully completing an algorithmic challenge by providing a correct `_solutionHash` to a predefined `_challengeId`.
9.  `curateKnowledgeModule(uint256 _tokenId, uint256 _moduleId, bytes32 _moduleHash)`: **(Role: `CURATOR_ROLE`)** Rewards a persona for effective knowledge module curation, where `_moduleHash` identifies the curated content.
10. `decayPersonaScores()`: **(Role: `SYSTEM_KEEPER_ROLE`)** A system function designed to be called periodically (e.g., by a decentralized keeper network) to gradually reduce inactive personas' `ReputationScore` and `SkillProficiencies` to encourage continuous engagement.

**III. Skill Proficiencies & Advancement**

11. `attestSkillProficiency(uint256 _tokenId, uint8 _skillId, uint16 _scoreIncrease, bytes32 _attestationProof)`: **(Role: `SKILL_AUDITOR_ROLE`)** Allows an authorized `SkillAuditor` to increase a persona's proficiency in a specific `_skillId`, providing `_scoreIncrease` and an optional `_attestationProof` hash for off-chain verifiable credentials.
12. `getSkillProficiency(uint256 _tokenId, uint8 _skillId)`: Returns the current proficiency level (`uint16`) of a specified `_skillId` for a given `_tokenId`.
13. `registerNewSkillCategory(string _name, string _description)`: **(Role: `DEFAULT_ADMIN_ROLE` or `GOVERNANCE_ROLE`)** Defines and registers a new skill category within the system, assigning it a unique `_skillId`.
14. `getOverallPersonaRank(uint256 _tokenId)`: Calculates and returns a weighted aggregate rank for a persona, combining `KnowledgePoints`, `ReputationScore`, and `SkillProficiencies` into a single, comparative score.
15. `getUnlockedTraits(uint256 _tokenId)`: Identifies and returns a list of unique 'traits' (e.g., "Researcher Tier 1", "Code Artisan") that a persona has unlocked based on meeting specific thresholds in their accumulated scores and proficiencies.

**IV. Access Control & System Configuration**

16. `grantRole(address _account, bytes32 _role)`: **(Role: `DEFAULT_ADMIN_ROLE`)** Grants a specified role (e.g., `FACT_VALIDATOR_ROLE`, `SKILL_AUDITOR_ROLE`) to an account.
17. `revokeRole(address _account, bytes32 _role)`: **(Role: `DEFAULT_ADMIN_ROLE`)** Revokes a specified role from an account.
18. `hasRole(bytes32 _role, address _account)`: Checks if a given `_account` possesses a specific `_role`. (OpenZeppelin's `AccessControl` standard function).
19. `configureRewardSystem(bytes32 _actionType, uint256 _kpReward, uint256 _reputationReward)`: **(Role: `DEFAULT_ADMIN_ROLE`)** Configures the `KnowledgePoint` and `ReputationScore` rewards for various predefined actions within the system (e.g., `ACTION_FACT_CONTRIBUTION`).
20. `setDecayParameters(uint256 _decayInterval, uint256 _decayFactorNumerator, uint256 _decayFactorDenominator)`: **(Role: `DEFAULT_ADMIN_ROLE`)** Sets the interval (`_decayInterval`) and the fractional decay rate (`_decayFactorNumerator` / `_decayFactorDenominator`) used by the `decayPersonaScores` function.
21. `setChallengeDetails(uint256 _challengeId, bytes32 _expectedSolutionHash, uint256 _kpReward)`: **(Role: `DEFAULT_ADMIN_ROLE`)** Sets up a new algorithmic challenge by defining its unique `_challengeId`, the `_expectedSolutionHash`, and the `_kpReward` for successful completion.
22. `queryPersonaStateHash(uint256 _tokenId)`: Returns a `bytes32` hash representing the current verifiable state of a persona's dynamic attributes (KPs, reputation, skills). This hash serves as a public commitment that can be used off-chain by zero-knowledge provers to prove specific properties about the persona's state without revealing all underlying data.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for DEFAULT_ADMIN_ROLE initial setup

/**
 * @title VeritasPersonaCore
 * @dev A self-sovereign, evolving knowledge and reputation identity system.
 *      This contract manages dynamic, soulbound identities that accrue verifiable skills,
 *      reputation, and knowledge points through on-chain and oracle-verified contributions.
 *      It acts as a foundational layer for a decentralized meritocracy, enabling advanced
 *      governance, skill-based access control, and a privacy-preserving reputation system.
 */
contract VeritasPersonaCore is ERC721URIStorage, AccessControl, ReentrancyGuard, Ownable {

    // --- Custom Errors ---
    error PersonaDoesNotExist(uint256 tokenId);
    error SenderNotPersonaOwner(uint256 tokenId, address sender);
    error PersonaAlreadyExists(address owner);
    error SkillCategoryDoesNotExist(uint8 skillId);
    error ChallengeDoesNotExist(uint256 challengeId);
    error InvalidSolutionHash(uint256 challengeId);
    error InvalidDecayParameters();
    error DecayIntervalNotReached(uint256 lastDecay, uint256 interval);
    error ActionRewardNotConfigured(bytes32 actionType);

    // --- Events ---
    event PersonaMinted(uint256 indexed tokenId, address indexed owner, string bio);
    event PersonaBurned(uint256 indexed tokenId, address indexed owner);
    event PersonaBioUpdated(uint256 indexed tokenId, string newBio);
    event KnowledgePointsRewarded(uint256 indexed tokenId, bytes32 indexed actionType, uint256 amount);
    event ReputationScoreUpdated(uint256 indexed tokenId, bytes32 indexed actionType, int256 change);
    event SkillProficiencyAttested(uint256 indexed tokenId, uint8 indexed skillId, uint16 scoreIncrease, bytes32 attestationProof);
    event SkillCategoryRegistered(uint8 indexed skillId, string name, string description);
    event ChallengeCompleted(uint256 indexed tokenId, uint256 indexed challengeId, bytes32 solutionHash);
    event RewardsConfigured(bytes32 indexed actionType, uint256 kpReward, uint256 reputationReward);
    event DecayParametersSet(uint256 decayInterval, uint256 decayFactorNumerator, uint256 decayFactorDenominator);
    event PersonaScoresDecayed(uint256 indexed tokenId, uint256 oldReputation, uint256 newReputation);

    // --- Constants & Role Definitions ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant FACT_VALIDATOR_ROLE = keccak256("FACT_VALIDATOR_ROLE");
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant SKILL_AUDITOR_ROLE = keccak256("SKILL_AUDITOR_ROLE");
    bytes32 public constant SYSTEM_KEEPER_ROLE = keccak256("SYSTEM_KEEPER_ROLE"); // For triggering periodic functions

    // Action types for reward configuration
    bytes32 public constant ACTION_FACT_CONTRIBUTION = keccak256("FACT_CONTRIBUTION");
    bytes32 public constant ACTION_PEER_REVIEW = keccak256("PEER_REVIEW");
    bytes32 public constant ACTION_ALGORITHMIC_CHALLENGE = keccak256("ALGORITHMIC_CHALLENGE");
    bytes32 public constant ACTION_KNOWLEDGE_CURATION = keccak256("KNOWLEDGE_CURATION");

    // --- Structs ---

    struct Persona {
        address owner;
        string bio;
        uint256 knowledgePoints; // Accumulated KPs
        int256 reputationScore;   // Dynamic reputation, can decrease
        uint256 lastDecayTimestamp; // Timestamp of last decay application
        mapping(uint8 => uint16) skillProficiencies; // skillId => proficiency score
    }

    struct SkillCategory {
        string name;
        string description;
    }

    struct ActionReward {
        uint256 kpReward;
        int256 reputationReward; // Can be negative for penalization
    }

    struct AlgorithmicChallenge {
        bytes32 expectedSolutionHash;
        uint256 kpReward;
        int256 reputationReward;
        bool exists;
    }

    // --- State Variables ---

    uint256 private _nextTokenId;
    mapping(address => uint256) private _personaByOwner; // owner address -> persona tokenId
    mapping(uint256 => Persona) private _personas;       // persona tokenId -> Persona struct

    mapping(uint8 => SkillCategory) private _skillCategories; // skillId -> SkillCategory
    uint8 private _nextSkillId;

    mapping(bytes32 => ActionReward) private _actionRewards; // actionType -> ActionReward

    mapping(uint256 => AlgorithmicChallenge) private _challenges; // challengeId -> AlgorithmicChallenge

    uint256 public decayInterval;              // Time in seconds between decay applications
    uint256 public decayFactorNumerator;       // Numerator for decay calculation (e.g., 90 for 90%)
    uint256 public decayFactorDenominator;     // Denominator for decay calculation (e.g., 100)

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender) // Initialize Ownable for DEFAULT_ADMIN_ROLE
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Grant deployer DEFAULT_ADMIN_ROLE
        _nextTokenId = 1;
        _nextSkillId = 1;

        // Initialize decay parameters to sensible defaults (e.g., 10% decay every 30 days)
        decayInterval = 30 days;
        decayFactorNumerator = 90;
        decayFactorDenominator = 100;
    }

    // --- Modifiers ---
    modifier onlyPersonaOwner(uint256 tokenId) {
        if (_personaByOwner[msg.sender] != tokenId) {
            revert SenderNotPersonaOwner(tokenId, msg.sender);
        }
        _;
    }

    // --- Internal Functions (ERC721 Overrides for Soulbound Behavior) ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent all transfers except initial minting (from address 0) and burning (to address 0)
        if (from != address(0) && to != address(0)) {
            revert ERC721NonTransferable("Persona tokens are soulbound and cannot be transferred.");
        }
    }

    // --- I. Core Persona Management ---

    /**
     * @dev Mints a new soulbound persona for msg.sender.
     * @param _bio The initial biography for the persona.
     * @return The tokenId of the newly minted persona.
     */
    function mintPersona(string memory _bio)
        public
        nonReentrant
        returns (uint256)
    {
        if (_personaByOwner[msg.sender] != 0) {
            revert PersonaAlreadyExists(msg.sender);
        }

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _personaByOwner[msg.sender] = tokenId;

        Persona storage newPersona = _personas[tokenId];
        newPersona.owner = msg.sender;
        newPersona.bio = _bio;
        newPersona.knowledgePoints = 0;
        newPersona.reputationScore = 0;
        newPersona.lastDecayTimestamp = block.timestamp; // Initialize last decay timestamp

        emit PersonaMinted(tokenId, msg.sender, _bio);
        return tokenId;
    }

    /**
     * @dev Allows the owner of a persona to update their public bio.
     * @param _tokenId The ID of the persona to update.
     * @param _newBio The new biography string.
     */
    function updatePersonaBio(uint256 _tokenId, string memory _newBio)
        public
        nonReentrant
        onlyPersonaOwner(_tokenId)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        _personas[_tokenId].bio = _newBio;
        emit PersonaBioUpdated(_tokenId, _newBio);
    }

    /**
     * @dev Allows the owner of a persona to burn it, emphasizing self-sovereignty.
     * @param _tokenId The ID of the persona to burn.
     */
    function burnPersona(uint256 _tokenId)
        public
        nonReentrant
        onlyPersonaOwner(_tokenId)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }

        address owner = _personas[_tokenId].owner;
        delete _personaByOwner[owner]; // Remove mapping from owner to tokenId
        delete _personas[_tokenId];     // Clear persona data

        _burn(_tokenId); // Burn the ERC721 token
        emit PersonaBurned(_tokenId, owner);
    }

    /**
     * @dev Retrieves comprehensive details of a persona by its ID.
     * @param _tokenId The ID of the persona.
     * @return owner The address of the persona's owner.
     * @return bio The public biography of the persona.
     * @return knowledgePoints The accumulated Knowledge Points.
     * @return reputationScore The current Reputation Score.
     */
    function getPersonaDetails(uint256 _tokenId)
        public
        view
        returns (address owner, string memory bio, uint256 knowledgePoints, int256 reputationScore)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        Persona storage p = _personas[_tokenId];
        return (p.owner, p.bio, p.knowledgePoints, p.reputationScore);
    }

    /**
     * @dev Retrieves the persona ID for a given owner address.
     * @param _owner The address of the persona owner.
     * @return The tokenId, or 0 if no persona exists for the owner.
     */
    function getPersonaTokenId(address _owner)
        public
        view
        returns (uint256)
    {
        return _personaByOwner[_owner];
    }

    // --- II. Dynamic Attributes & Accrual ---

    /**
     * @dev Rewards a persona for a verified fact contribution.
     *      Only callable by FACT_VALIDATOR_ROLE.
     * @param _tokenId The ID of the persona to reward.
     * @param _factHash A unique hash identifying the verified fact.
     * @param _kpReward The Knowledge Points to reward.
     */
    function registerFactContribution(uint256 _tokenId, bytes32 _factHash, uint256 _kpReward)
        public
        nonReentrant
        onlyRole(FACT_VALIDATOR_ROLE)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }

        // Use reward config if available, else use direct _kpReward
        ActionReward storage rewards = _actionRewards[ACTION_FACT_CONTRIBUTION];
        uint256 actualKpReward = (rewards.kpReward > 0) ? rewards.kpReward : _kpReward;
        int256 actualRepReward = rewards.reputationReward;

        _personas[_tokenId].knowledgePoints += actualKpReward;
        _personas[_tokenId].reputationScore += actualRepReward;

        emit KnowledgePointsRewarded(_tokenId, ACTION_FACT_CONTRIBUTION, actualKpReward);
        emit ReputationScoreUpdated(_tokenId, ACTION_FACT_CONTRIBUTION, actualRepReward);
    }

    /**
     * @dev Records a peer review action, potentially rewarding the reviewer and updating reviewed's reputation.
     *      Only callable by REVIEWER_ROLE.
     * @param _reviewerTokenId The persona ID of the reviewer.
     * @param _reviewedTokenId The persona ID being reviewed.
     * @param _isApproved True if the review is positive, false for negative.
     * @param _reviewContentHash A hash of the review content for off-chain verification.
     */
    function submitPeerReview(uint256 _reviewerTokenId, uint256 _reviewedTokenId, bool _isApproved, bytes32 _reviewContentHash)
        public
        nonReentrant
        onlyRole(REVIEWER_ROLE)
    {
        if (_personas[_reviewerTokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_reviewerTokenId);
        }
        if (_personas[_reviewedTokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_reviewedTokenId);
        }

        // Reward reviewer based on their current reputation score (more reputable reviews have more weight)
        // Simple example: reviewer gets a base reward plus a bonus based on their reputation.
        // Reviewed persona's reputation changes based on _isApproved and reviewer's reputation.

        ActionReward storage baseRewards = _actionRewards[ACTION_PEER_REVIEW];
        uint256 reviewerKpReward = baseRewards.kpReward;
        int256 reviewerRepReward = baseRewards.reputationReward;

        // Apply dynamic weighting for reviewer's reward/impact
        int256 reviewerReputation = _personas[_reviewerTokenId].reputationScore;
        if (reviewerReputation > 0) {
            reviewerKpReward += reviewerReputation / 100; // Small bonus
        }

        _personas[_reviewerTokenId].knowledgePoints += reviewerKpReward;
        _personas[_reviewerTokenId].reputationScore += reviewerRepReward;
        emit KnowledgePointsRewarded(_reviewerTokenId, ACTION_PEER_REVIEW, reviewerKpReward);
        emit ReputationScoreUpdated(_reviewerTokenId, ACTION_PEER_REVIEW, reviewerRepReward);

        int256 reviewedRepChange = (reviewerReputation / 100); // Impact based on reviewer's reputation
        if (_isApproved) {
            _personas[_reviewedTokenId].reputationScore += reviewedRepChange;
            emit ReputationScoreUpdated(_reviewedTokenId, ACTION_PEER_REVIEW, reviewedRepChange);
        } else {
            _personas[_reviewedTokenId].reputationScore -= reviewedRepChange;
            emit ReputationScoreUpdated(_reviewedTokenId, ACTION_PEER_REVIEW, -reviewedRepChange);
        }
        // No event for _reviewContentHash, assume external system tracks this.
    }

    /**
     * @dev Rewards a persona for successfully completing an algorithmic challenge.
     * @param _tokenId The ID of the persona completing the challenge.
     * @param _challengeId The ID of the challenge.
     * @param _solutionHash The hash of the submitted solution.
     */
    function completeAlgorithmicChallenge(uint256 _tokenId, uint256 _challengeId, bytes32 _solutionHash)
        public
        nonReentrant
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        AlgorithmicChallenge storage challenge = _challenges[_challengeId];
        if (!challenge.exists) {
            revert ChallengeDoesNotExist(_challengeId);
        }
        if (challenge.expectedSolutionHash != _solutionHash) {
            revert InvalidSolutionHash(_challengeId);
        }

        _personas[_tokenId].knowledgePoints += challenge.kpReward;
        _personas[_tokenId].reputationScore += challenge.reputationReward;

        emit KnowledgePointsRewarded(_tokenId, ACTION_ALGORITHMIC_CHALLENGE, challenge.kpReward);
        emit ReputationScoreUpdated(_tokenId, ACTION_ALGORITHMIC_CHALLENGE, challenge.reputationReward);
        emit ChallengeCompleted(_tokenId, _challengeId, _solutionHash);

        // Optionally, prevent re-solving the same challenge or only reward once.
        // For simplicity, this implementation allows multiple completions, which might be okay for some challenges.
    }

    /**
     * @dev Rewards a persona for effective knowledge module curation.
     *      Only callable by CURATOR_ROLE.
     * @param _tokenId The ID of the persona curating.
     * @param _moduleId The ID of the knowledge module.
     * @param _moduleHash A hash of the curated content.
     */
    function curateKnowledgeModule(uint256 _tokenId, uint256 _moduleId, bytes32 _moduleHash)
        public
        nonReentrant
        onlyRole(CURATOR_ROLE)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }

        ActionReward storage rewards = _actionRewards[ACTION_KNOWLEDGE_CURATION];
        if (rewards.kpReward == 0 && rewards.reputationReward == 0) {
            revert ActionRewardNotConfigured(ACTION_KNOWLEDGE_CURATION);
        }

        _personas[_tokenId].knowledgePoints += rewards.kpReward;
        _personas[_tokenId].reputationScore += rewards.reputationReward;

        emit KnowledgePointsRewarded(_tokenId, ACTION_KNOWLEDGE_CURATION, rewards.kpReward);
        emit ReputationScoreUpdated(_tokenId, ACTION_KNOWLEDGE_CURATION, rewards.reputationReward);
        // No specific event for _moduleHash, assume external system tracks this.
    }

    /**
     * @dev A system keeper function to periodically decay ReputationScore and SkillProficiencies.
     *      Only callable by SYSTEM_KEEPER_ROLE.
     *      Iterates through a batch of personas to decay scores.
     *      This function requires external triggering (e.g., via a decentralized keeper network).
     * @param _startTokenId The starting tokenId for batch processing.
     * @param _batchSize The number of personas to process in this call.
     */
    function decayPersonaScores(uint256 _startTokenId, uint256 _batchSize)
        public
        nonReentrant
        onlyRole(SYSTEM_KEEPER_ROLE)
    {
        if (decayInterval == 0 || decayFactorDenominator == 0) {
            revert InvalidDecayParameters();
        }

        uint256 endTokenId = _startTokenId + _batchSize;
        if (endTokenId > _nextTokenId) {
            endTokenId = _nextTokenId;
        }

        for (uint256 i = _startTokenId; i < endTokenId; i++) {
            if (_personas[i].owner != address(0)) { // Check if persona exists
                Persona storage p = _personas[i];

                if (block.timestamp >= p.lastDecayTimestamp + decayInterval) {
                    // Decay Reputation Score
                    int256 oldReputation = p.reputationScore;
                    p.reputationScore = (p.reputationScore * int256(decayFactorNumerator)) / int256(decayFactorDenominator);
                    emit PersonaScoresDecayed(i, uint256(oldReputation), uint256(p.reputationScore)); // Cast for event

                    // Decay Skill Proficiencies (e.g., all skills decay)
                    // For simplicity, we just iterate up to max 255 skills here. A more optimized approach
                    // would involve tracking active skills or iterating through a linked list.
                    for (uint8 skillId = 1; skillId <= _nextSkillId - 1; skillId++) {
                        if (p.skillProficiencies[skillId] > 0) {
                            p.skillProficiencies[skillId] = uint16((p.skillProficiencies[skillId] * decayFactorNumerator) / decayFactorDenominator);
                        }
                    }

                    p.lastDecayTimestamp = block.timestamp; // Update last decay timestamp
                }
            }
        }
    }

    // --- III. Skill Proficiencies & Advancement ---

    /**
     * @dev Allows an authorized SkillAuditor to increase a persona's proficiency in a specific skill.
     * @param _tokenId The ID of the persona whose skill is being attested.
     * @param _skillId The ID of the skill category.
     * @param _scoreIncrease The amount to increase the skill proficiency by.
     * @param _attestationProof A hash representing an off-chain attestation proof.
     */
    function attestSkillProficiency(uint256 _tokenId, uint8 _skillId, uint16 _scoreIncrease, bytes32 _attestationProof)
        public
        nonReentrant
        onlyRole(SKILL_AUDITOR_ROLE)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        if (_skillCategories[_skillId].name == "") {
            revert SkillCategoryDoesNotExist(_skillId);
        }

        // Cap skill proficiency at a max value (e.g., 65535 for uint16) to prevent overflow
        _personas[_tokenId].skillProficiencies[_skillId] = _personas[_tokenId].skillProficiencies[_skillId] + _scoreIncrease > type(uint16).max
            ? type(uint16).max
            : _personas[_tokenId].skillProficiencies[_skillId] + _scoreIncrease;

        emit SkillProficiencyAttested(_tokenId, _skillId, _scoreIncrease, _attestationProof);
    }

    /**
     * @dev Retrieves the current proficiency level for a specific skill of a persona.
     * @param _tokenId The ID of the persona.
     * @param _skillId The ID of the skill.
     * @return The proficiency score (uint16).
     */
    function getSkillProficiency(uint256 _tokenId, uint8 _skillId)
        public
        view
        returns (uint16)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        if (_skillCategories[_skillId].name == "") {
            revert SkillCategoryDoesNotExist(_skillId);
        }
        return _personas[_tokenId].skillProficiencies[_skillId];
    }

    /**
     * @dev Allows an authorized role (e.g., ADMIN) to define a new skill category.
     * @param _name The name of the new skill category.
     * @param _description A description of the skill category.
     * @return The ID of the newly registered skill.
     */
    function registerNewSkillCategory(string memory _name, string memory _description)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint8)
    {
        uint8 skillId = _nextSkillId++;
        _skillCategories[skillId] = SkillCategory(_name, _description);
        emit SkillCategoryRegistered(skillId, _name, _description);
        return skillId;
    }

    /**
     * @dev Calculates and returns a weighted aggregate rank for a persona.
     *      This is a simplified example; a real-world rank would involve more complex algorithms.
     * @param _tokenId The ID of the persona.
     * @return A uint256 representing the persona's rank. Higher is better.
     */
    function getOverallPersonaRank(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        Persona storage p = _personas[_tokenId];

        uint256 rank = p.knowledgePoints / 100; // 1 KP = 0.01 rank point
        rank += uint256(p.reputationScore > 0 ? p.reputationScore : 0) / 50; // 1 positive Rep = 0.02 rank point

        // Sum up skill proficiencies, weighted more heavily
        uint256 totalSkillProficiency = 0;
        for (uint8 skillId = 1; skillId < _nextSkillId; skillId++) {
            totalSkillProficiency += p.skillProficiencies[skillId];
        }
        rank += totalSkillProficiency / 10; // 1 skill point = 0.1 rank point

        return rank;
    }

    /**
     * @dev Identifies and returns a list of unique 'traits' a persona has unlocked.
     *      This is a conceptual function; actual trait definitions and criteria would be more extensive.
     * @param _tokenId The ID of the persona.
     * @return An array of strings representing unlocked traits.
     */
    function getUnlockedTraits(uint256 _tokenId)
        public
        view
        returns (string[] memory)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        Persona storage p = _personas[_tokenId];
        string[] memory traits = new string[](0);

        // Example trait conditions
        if (p.knowledgePoints >= 1000) {
            string[] memory newTraits = new string[](traits.length + 1);
            for (uint i = 0; i < traits.length; i++) newTraits[i] = traits[i];
            newTraits[traits.length] = "Knowledge Seeker I";
            traits = newTraits;
        }
        if (p.reputationScore >= 500) {
            string[] memory newTraits = new string[](traits.length + 1);
            for (uint i = 0; i < traits.length; i++) newTraits[i] = traits[i];
            newTraits[traits.length] = "Reputable Contributor I";
            traits = newTraits;
        }
        if (p.skillProficiencies[1] >= 100) { // Assuming skillId 1 is "Research"
            string[] memory newTraits = new string[](traits.length + 1);
            for (uint i = 0; i < traits.length; i++) newTraits[i] = traits[i];
            newTraits[traits.length] = "Basic Researcher";
            traits = newTraits;
        }

        return traits;
    }

    // --- IV. Access Control & System Configuration ---

    /**
     * @dev Grants a specified role to an account.
     *      Only callable by DEFAULT_ADMIN_ROLE.
     * @param _account The address to grant the role to.
     * @param _role The role (bytes32 hash) to grant.
     */
    function grantRole(address _account, bytes32 _role)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(_role, _account);
    }

    /**
     * @dev Revokes a specified role from an account.
     *      Only callable by DEFAULT_ADMIN_ROLE.
     * @param _account The address to revoke the role from.
     * @param _role The role (bytes32 hash) to revoke.
     */
    function revokeRole(address _account, bytes32 _role)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(_role, _account);
    }

    /**
     * @dev Checks if an account possesses a specific role.
     * @param _role The role (bytes32 hash) to check.
     * @param _account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    // hasRole function is already available from AccessControl via inheritance.
    // function hasRole(bytes32 _role, address _account) public view returns (bool) {
    //     return AccessControl.hasRole(_role, _account);
    // }

    /**
     * @dev Configures the KnowledgePoint and ReputationScore rewards for different action types.
     *      Only callable by DEFAULT_ADMIN_ROLE.
     * @param _actionType The bytes32 identifier of the action (e.g., ACTION_FACT_CONTRIBUTION).
     * @param _kpReward The Knowledge Points to reward for this action.
     * @param _reputationReward The Reputation Score change for this action (can be negative).
     */
    function configureRewardSystem(bytes32 _actionType, uint256 _kpReward, int256 _reputationReward)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _actionRewards[_actionType] = ActionReward(_kpReward, _reputationReward);
        emit RewardsConfigured(_actionType, _kpReward, _reputationReward);
    }

    /**
     * @dev Sets the parameters controlling the decayPersonaScores function.
     *      Only callable by DEFAULT_ADMIN_ROLE.
     * @param _decayInterval The new decay interval in seconds.
     * @param _decayFactorNumerator The numerator of the decay factor (e.g., 90 for 90%).
     * @param _decayFactorDenominator The denominator of the decay factor (e.g., 100). Must be > 0.
     */
    function setDecayParameters(uint256 _decayInterval, uint252 _decayFactorNumerator, uint252 _decayFactorDenominator)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_decayInterval == 0 || _decayFactorDenominator == 0) {
            revert InvalidDecayParameters();
        }
        decayInterval = _decayInterval;
        decayFactorNumerator = _decayFactorNumerator;
        decayFactorDenominator = _decayFactorDenominator;
        emit DecayParametersSet(_decayInterval, _decayFactorNumerator, _decayFactorDenominator);
    }

    /**
     * @dev Sets up a new algorithmic challenge with its expected solution and reward.
     *      Only callable by DEFAULT_ADMIN_ROLE.
     * @param _challengeId The unique ID for the new challenge.
     * @param _expectedSolutionHash The keccak256 hash of the correct solution.
     * @param _kpReward The Knowledge Points awarded for solving.
     * @param _reputationReward The Reputation Score change for solving.
     */
    function setChallengeDetails(uint256 _challengeId, bytes32 _expectedSolutionHash, uint256 _kpReward, int256 _reputationReward)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _challenges[_challengeId] = AlgorithmicChallenge(_expectedSolutionHash, _kpReward, _reputationReward, true);
        // Event for challenge setup could be added if needed.
    }

    /**
     * @dev Returns a unique hash representing the current verifiable state of a persona's
     *      dynamic attributes (KPs, reputation, skills). This hash serves as a public commitment
     *      that can be used off-chain by zero-knowledge provers to prove specific properties
     *      about the persona's state without revealing all underlying data.
     * @param _tokenId The ID of the persona.
     * @return A bytes32 hash of the persona's verifiable state.
     */
    function queryPersonaStateHash(uint256 _tokenId)
        public
        view
        returns (bytes32)
    {
        if (_personas[_tokenId].owner == address(0)) {
            revert PersonaDoesNotExist(_tokenId);
        }
        Persona storage p = _personas[_tokenId];

        bytes memory encodedSkills;
        // Deterministically encode all active skill proficiencies
        for (uint8 skillId = 1; skillId < _nextSkillId; skillId++) {
            if (p.skillProficiencies[skillId] > 0) {
                encodedSkills = abi.encodePacked(encodedSkills, skillId, p.skillProficiencies[skillId]);
            }
        }

        return keccak256(
            abi.encodePacked(
                _tokenId,
                p.owner,
                p.knowledgePoints,
                p.reputationScore,
                encodedSkills // Hash of all skill proficiencies
            )
        );
    }
}
```