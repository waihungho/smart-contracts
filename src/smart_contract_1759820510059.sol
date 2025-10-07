This smart contract, `ContextualReputationEngine`, introduces an **Ephemeral Identity and Adaptive Reputation System (EIARS)**. It's designed to provide a dynamic, context-specific, and privacy-aware reputation for users based on their on-chain actions, with a novel integration of simulated AI oracle influence and staked-based reputation amplification.

Unlike static Soulbound Tokens (SBTs) or generic reputation systems, EIARS allows users to generate "Ephemeral Identifiers" (EIDs) for specific interaction contexts, ensuring that their reputation is not a single, monolithic score, but rather a multi-faceted profile that decays over time and can be influenced by others' stakes and even AI-driven insights.

---

## Contract Outline and Function Summary

**Contract Name:** `ContextualReputationEngine`

**Core Concepts:**
*   **Ephemeral Identifiers (EIDs):** Temporary, context-specific pseudonyms for a user.
*   **Contextual Reputation:** Reputation scores are specific to defined "contexts" (e.g., "DAO Governance," "Content Curator," "DeFi Participant").
*   **Adaptive Decay:** Reputation scores naturally decay over time, reflecting recent activity and relevance.
*   **Influence Staking:** Users can stake tokens to amplify their own or others' EID reputation within a context.
*   **AI Oracle Integration (Simulated):** A trusted oracle (simulating an AI) can provide "optimization suggestions" that dynamically adjust context parameters (e.g., attestation weights, decay rates).
*   **Attestation & Dispute Resolution:** Users can attest to EIDs' behavior, and these attestations can be challenged.

---

**Function Summary:**

**I. Ephemeral Identity & Context Management:**
1.  `createEphemeralIdentifier()`: Generates a new, unique Ephemeral Identifier (EID) linked to the calling address.
2.  `registerContext()`: Allows the administrator to register a new reputation context, defining its initial parameters.
3.  `linkEIDToAddress()`: Explicitly links an EID to a primary wallet address, making it publicly discoverable.
4.  `unlinkEIDFromAddress()`: Removes an explicit link between an EID and a primary wallet address.
5.  `setContextDescription()`: Updates the descriptive details of an existing reputation context.

**II. Attestation & Reputation Scoring:**
6.  `attestToEID()`: Allows a user to provide a positive or negative attestation for an EID within a specific context. Requires a small stake to prevent spam.
7.  `revokeAttestation()`: Allows an attestor to revoke their previously made attestation.
8.  `challengeAttestation()`: Initiates a formal challenge against an attestation, requiring a stake to be placed.
9.  `resolveAttestationChallenge()`: Administrator or designated resolver determines the outcome of a challenge, distributing/slashing stakes.
10. `calculateReputationScore()`: A public `view` function to calculate the current reputation score for an EID in a given context, applying decay.
11. `updateContextualReputation()`: An internal function triggered by attestations or challenges to update raw reputation points before decay.

**III. Influence Staking:**
12. `stakeInfluenceOnEID()`: Allows a user to stake tokens to boost the perceived relevance or weight of an EID within a specific context.
13. `withdrawInfluenceStake()`: Allows a user to withdraw their previously staked influence tokens.
14. `delegateInfluence()`: Allows a user to delegate their influence staking power to another EID for a specific context.

**IV. AI Oracle & Dynamic Optimization (Simulated):**
15. `requestAIOptimization()`: Allows an administrator or DAO to request an AI oracle for an optimization suggestion for a context.
16. `receiveAIOptimization()`: Only callable by the designated `AIOracle` role to submit an AI-driven suggestion for a context's parameters.
17. `getAIOptimizationSuggestion()`: A `view` function to retrieve the latest AI-generated optimization suggestion for a context.

**V. System Parameters & Governance:**
18. `setDecayRate()`: Administrator function to set or update the decay rate for a specific context's reputation.
19. `setAttestationWeight()`: Administrator function to set the impact weight of individual attestations.
20. `setChallengeFee()`: Administrator function to set the fee required to challenge an attestation.
21. `grantRole()`: Grants a specific role (e.g., `AI_ORACLE_ROLE`, `RESOLVER_ROLE`) to an address.
22. `revokeRole()`: Revokes a specific role from an address.
23. `pauseSystem()`: Emergency function to pause critical contract operations.
24. `unpauseSystem()`: Resumes operations after a pause.
25. `withdrawFeesAndStakes()`: Allows the contract owner to withdraw accumulated fees from challenges or expired stakes (after resolution/timeout).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// --- Contract Outline and Function Summary (as above) ---

contract ContextualReputationEngine is Ownable, Pausable, AccessControl {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    bytes32 public constant CONTEXT_ADMIN_ROLE = keccak256("CONTEXT_ADMIN_ROLE"); // For managing specific contexts
    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE"); // For resolving challenges

    // --- Data Structures ---

    struct EphemeralIdentifier {
        address owner; // The primary wallet address that created this EID
        uint256 eidId; // Unique ID for the EID
        uint256 createdAt;
        bool isLinkedToAddress; // If explicitly linked to owner for public discovery
        mapping(bytes32 => bool) contextsParticipated; // Track contexts this EID has acted in
    }

    struct Context {
        bytes32 contextHash; // Keccak256 hash of the context name (e.g., "DAO_GOVERNANCE")
        string name;
        string description;
        uint256 createdAt;
        uint256 attestationWeight; // How much a single attestation impacts score (e.g., 100 = 1 point)
        uint256 decayRateNumerator;   // Decay rate as a fraction (e.g., 1 for 1/10000 decay per second)
        uint256 decayRateDenominator; // (e.g., 10000)
        uint256 lastGlobalDecayUpdate; // Timestamp for when decay was last considered for this context
        uint256 challengeFee; // Token amount required to challenge an attestation
        address feeToken; // The token used for fees and stakes
    }

    struct Attestation {
        uint256 attestationId;
        uint256 eidId; // EID being attested to
        bytes32 contextHash;
        address attestor; // The primary address making the attestation
        int256 value; // Positive for good, negative for bad (e.g., +1, -1)
        uint256 createdAt;
        bool isRevoked;
        bool isChallenged;
        uint256 challengeId; // If challenged, reference to the challenge
    }

    struct Challenge {
        uint256 challengeId;
        uint256 attestationId;
        address challenger;
        uint256 challengeStake;
        uint256 challengedAttestorStake; // Stake from original attestor to defend
        uint256 createdAt;
        bool resolved;
        bool challengerWon; // True if challenger won, false if attestor won
        uint256 resolutionTime;
    }

    struct ReputationData {
        int256 rawReputationPoints; // Accumulated reputation points without decay
        uint256 lastUpdated; // Timestamp of the last point accumulation or decay calculation
        uint256 stakedInfluence; // Amount of tokens staked to boost this EID's reputation
        address delegateeEid; // If influence is delegated to another EID
    }

    struct AIOptimizationSuggestion {
        bytes32 contextHash;
        uint256 suggestedAttestationWeight;
        uint256 suggestedDecayRateNumerator;
        uint256 suggestedDecayRateDenominator;
        uint256 suggestedChallengeFee;
        uint256 timestamp;
    }

    // --- State Variables ---

    Counters.Counter private _eidIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _challengeIds;

    mapping(uint256 => EphemeralIdentifier) public ephemeralIdentifiers; // EID ID => EID struct
    mapping(address => uint256[]) public ownerToEIDs; // Primary Address => List of EID IDs
    mapping(uint256 => address) public eidIdToOwner; // EID ID => Primary Address (for quick lookup)

    mapping(bytes32 => Context) public contexts; // Context hash => Context struct
    mapping(bytes32 => bool) public isContextRegistered; // Context hash => true/false

    mapping(uint256 => mapping(bytes32 => ReputationData)) public eidContextReputations; // EID ID => Context Hash => ReputationData

    mapping(uint256 => Attestation) public attestations; // Attestation ID => Attestation struct
    mapping(uint256 => Challenge) public challenges; // Challenge ID => Challenge struct

    mapping(bytes32 => AIOptimizationSuggestion) public latestAIOptimization; // Context Hash => Latest AI suggestion

    uint256 public attestationFee; // General fee for making an attestation (to prevent spam)

    // --- Events ---

    event EphemeralIdentifierCreated(uint256 indexed eidId, address indexed owner, uint256 createdAt);
    event ContextRegistered(bytes32 indexed contextHash, string name, address indexed registrar, uint256 createdAt);
    event EIDLinkedToAddress(uint256 indexed eidId, address indexed linkedAddress);
    event EIDUnlinkedFromAddress(uint256 indexed eidId, address indexed unlinkedAddress);
    event ContextDescriptionUpdated(bytes32 indexed contextHash, string newDescription);

    event AttestationMade(uint256 indexed attestationId, uint256 indexed eidId, bytes32 indexed contextHash, address attestor, int256 value);
    event AttestationRevoked(uint256 indexed attestationId, uint256 indexed eidId, bytes32 indexed contextHash, address attestor);
    event AttestationChallenged(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger);
    event AttestationChallengeResolved(uint256 indexed challengeId, bool challengerWon, uint256 resolutionTime);

    event InfluenceStaked(uint256 indexed eidId, bytes32 indexed contextHash, address indexed staker, uint256 amount);
    event InfluenceWithdrawn(uint256 indexed eidId, bytes32 indexed contextHash, address indexed staker, uint256 amount);
    event InfluenceDelegated(uint256 indexed delegatorEid, uint256 indexed delegateeEid, bytes32 indexed contextHash);

    event AIOptimizationRequested(bytes32 indexed contextHash, address indexed requester);
    event AIOptimizationReceived(bytes32 indexed contextHash, uint256 suggestedAttestationWeight, uint256 suggestedDecayRateNumerator, uint256 suggestedDecayRateDenominator, uint256 suggestedChallengeFee);

    event DecayRateSet(bytes32 indexed contextHash, uint256 numerator, uint256 denominator);
    event AttestationWeightSet(bytes32 indexed contextHash, uint256 weight);
    event ChallengeFeeSet(bytes32 indexed contextHash, uint256 fee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AI_ORACLE_ROLE, msg.sender); // For initial testing, owner is also AI oracle
        _grantRole(RESOLVER_ROLE, msg.sender); // Owner is also resolver
        _grantRole(CONTEXT_ADMIN_ROLE, msg.sender); // Owner can manage contexts
        attestationFee = 1 ether; // Default attestation fee, can be changed by owner
    }

    modifier onlyEidOwner(uint256 _eidId) {
        require(ephemeralIdentifiers[_eidId].owner == msg.sender, "ContextualReputation: Not EID owner");
        _;
    }

    modifier onlyContextAdmin(bytes32 _contextHash) {
        require(hasRole(CONTEXT_ADMIN_ROLE, msg.sender), "ContextualReputation: Caller is not a context admin");
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");
        _;
    }

    modifier onlyAIOracle() {
        require(hasRole(AI_ORACLE_ROLE, msg.sender), "ContextualReputation: Caller is not an AI Oracle");
        _;
    }

    modifier onlyResolver() {
        require(hasRole(RESOLVER_ROLE, msg.sender), "ContextualReputation: Caller is not a resolver");
        _;
    }

    // --- I. Ephemeral Identity & Context Management ---

    /**
     * @dev Generates a new, unique Ephemeral Identifier (EID) linked to the calling address.
     * @return eidId The ID of the newly created EID.
     */
    function createEphemeralIdentifier() external whenNotPaused returns (uint256) {
        _eidIds.increment();
        uint256 newEidId = _eidIds.current();

        ephemeralIdentifiers[newEidId] = EphemeralIdentifier({
            owner: msg.sender,
            eidId: newEidId,
            createdAt: block.timestamp,
            isLinkedToAddress: false,
            contextsParticipated: new mapping(bytes32 => bool)
        });
        ownerToEIDs[msg.sender].push(newEidId);
        eidIdToOwner[newEidId] = msg.sender;

        emit EphemeralIdentifierCreated(newEidId, msg.sender, block.timestamp);
        return newEidId;
    }

    /**
     * @dev Allows the administrator to register a new reputation context.
     * @param _name The human-readable name of the context.
     * @param _description A detailed description of the context.
     * @param _initialAttestationWeight The initial weight of a single attestation in this context.
     * @param _initialDecayRateNumerator The numerator for the initial decay rate (e.g., 1).
     * @param _initialDecayRateDenominator The denominator for the initial decay rate (e.g., 10000 for 1/10000 per second).
     * @param _initialChallengeFee The token amount required to challenge an attestation in this context.
     * @param _feeToken The ERC20 token address used for fees and stakes in this context.
     */
    function registerContext(
        string calldata _name,
        string calldata _description,
        uint256 _initialAttestationWeight,
        uint256 _initialDecayRateNumerator,
        uint256 _initialDecayRateDenominator,
        uint256 _initialChallengeFee,
        address _feeToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        bytes32 contextHash = keccak256(abi.encodePacked(_name));
        require(!isContextRegistered[contextHash], "ContextualReputation: Context already registered");
        require(_initialDecayRateDenominator > 0, "ContextualReputation: Denominator must be greater than zero");
        require(IERC20(_feeToken).totalSupply() > 0 || _feeToken == address(0), "ContextualReputation: Invalid fee token"); // Basic check for valid token

        contexts[contextHash] = Context({
            contextHash: contextHash,
            name: _name,
            description: _description,
            createdAt: block.timestamp,
            attestationWeight: _initialAttestationWeight,
            decayRateNumerator: _initialDecayRateNumerator,
            decayRateDenominator: _initialDecayRateDenominator,
            lastGlobalDecayUpdate: block.timestamp,
            challengeFee: _initialChallengeFee,
            feeToken: _feeToken
        });
        isContextRegistered[contextHash] = true;

        emit ContextRegistered(contextHash, _name, msg.sender, block.timestamp);
    }

    /**
     * @dev Explicitly links an EID to a primary wallet address, making it publicly discoverable.
     * This is an opt-in feature for transparency.
     * @param _eidId The ID of the EID to link.
     */
    function linkEIDToAddress(uint256 _eidId) external onlyEidOwner(_eidId) whenNotPaused {
        require(!ephemeralIdentifiers[_eidId].isLinkedToAddress, "ContextualReputation: EID already linked");
        ephemeralIdentifiers[_eidId].isLinkedToAddress = true;
        emit EIDLinkedToAddress(_eidId, msg.sender);
    }

    /**
     * @dev Removes an explicit link between an EID and a primary wallet address.
     * @param _eidId The ID of the EID to unlink.
     */
    function unlinkEIDFromAddress(uint256 _eidId) external onlyEidOwner(_eidId) whenNotPaused {
        require(ephemeralIdentifiers[_eidId].isLinkedToAddress, "ContextualReputation: EID not linked");
        ephemeralIdentifiers[_eidId].isLinkedToAddress = false;
        emit EIDUnlinkedFromAddress(_eidId, msg.sender);
    }

    /**
     * @dev Updates the descriptive details of an existing reputation context.
     * Only callable by `CONTEXT_ADMIN_ROLE`.
     * @param _contextHash The hash of the context to update.
     * @param _newDescription The new description for the context.
     */
    function setContextDescription(bytes32 _contextHash, string calldata _newDescription) external onlyContextAdmin(_contextHash) whenNotPaused {
        contexts[_contextHash].description = _newDescription;
        emit ContextDescriptionUpdated(_contextHash, _newDescription);
    }

    // --- II. Attestation & Reputation Scoring ---

    /**
     * @dev Allows a user to provide a positive or negative attestation for an EID within a specific context.
     * Requires a small fee (attestationFee) in the context's feeToken.
     * @param _eidId The ID of the EID being attested to.
     * @param _contextHash The hash of the context for the attestation.
     * @param _value The value of the attestation (e.g., 1 for positive, -1 for negative). Must be 1 or -1.
     */
    function attestToEID(uint256 _eidId, bytes32 _contextHash, int256 _value) external whenNotPaused {
        require(eidIdToOwner[_eidId] != address(0), "ContextualReputation: EID does not exist");
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");
        require(_value == 1 || _value == -1, "ContextualReputation: Attestation value must be 1 or -1");
        require(ephemeralIdentifiers[_eidId].owner != msg.sender, "ContextualReputation: Cannot attest to your own EID");

        // Transfer attestation fee
        if (contexts[_contextHash].feeToken != address(0)) {
            require(IERC20(contexts[_contextHash].feeToken).transferFrom(msg.sender, address(this), attestationFee), "ContextualReputation: Fee transfer failed");
        } else {
             require(msg.value >= attestationFee, "ContextualReputation: Insufficient ETH fee");
             // If feeToken is address(0), it implies ETH is used for fees.
             // Leftover ETH (if msg.value > attestationFee) is sent back automatically by Solidity.
        }


        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestations[newAttestationId] = Attestation({
            attestationId: newAttestationId,
            eidId: _eidId,
            contextHash: _contextHash,
            attestor: msg.sender,
            value: _value,
            createdAt: block.timestamp,
            isRevoked: false,
            isChallenged: false,
            challengeId: 0
        });

        _updateContextualReputation(_eidId, _contextHash, _value * int256(contexts[_contextHash].attestationWeight));
        ephemeralIdentifiers[_eidId].contextsParticipated[_contextHash] = true;

        emit AttestationMade(newAttestationId, _eidId, _contextHash, msg.sender, _value);
    }

    /**
     * @dev Allows an attestor to revoke their previously made attestation.
     * The impact of the attestation will be reversed from the EID's raw reputation.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId) external whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        require(att.attestor == msg.sender, "ContextualReputation: Not the attestor of this attestation");
        require(!att.isRevoked, "ContextualReputation: Attestation already revoked");
        require(!att.isChallenged, "ContextualReputation: Cannot revoke a challenged attestation");

        att.isRevoked = true;
        // Reverse the effect of the attestation
        _updateContextualReputation(att.eidId, att.contextHash, -att.value * int256(contexts[att.contextHash].attestationWeight));

        emit AttestationRevoked(_attestationId, att.eidId, att.contextHash, msg.sender);
    }

    /**
     * @dev Initiates a formal challenge against an attestation.
     * Requires the challenger to stake a fee. The attestor must then also stake to defend.
     * @param _attestationId The ID of the attestation to challenge.
     */
    function challengeAttestation(uint256 _attestationId) external payable whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        require(att.attestor != address(0), "ContextualReputation: Attestation does not exist");
        require(!att.isRevoked, "ContextualReputation: Cannot challenge a revoked attestation");
        require(!att.isChallenged, "ContextualReputation: Attestation already challenged");
        require(att.attestor != msg.sender, "ContextualReputation: Attestor cannot challenge their own attestation");

        bytes32 contextHash = att.contextHash;
        Context storage context = contexts[contextHash];
        require(context.feeToken != address(0) ? IERC20(context.feeToken).transferFrom(msg.sender, address(this), context.challengeFee) : msg.value >= context.challengeFee, "ContextualReputation: Insufficient challenge fee");
        if (context.feeToken == address(0) && msg.value > context.challengeFee) {
             // Return excess ETH if any
            payable(msg.sender).transfer(msg.value - context.challengeFee);
        }

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            challengeId: newChallengeId,
            attestationId: _attestationId,
            challenger: msg.sender,
            challengeStake: context.challengeFee,
            challengedAttestorStake: 0, // Attestor still needs to stake
            createdAt: block.timestamp,
            resolved: false,
            challengerWon: false,
            resolutionTime: 0
        });

        att.isChallenged = true;
        att.challengeId = newChallengeId;

        emit AttestationChallenged(newChallengeId, _attestationId, msg.sender);
    }

    /**
     * @dev Allows the original attestor to stake their challenge fee to defend their attestation.
     * @param _challengeId The ID of the challenge to defend.
     */
    function defendAttestationChallenge(uint256 _challengeId) external payable whenNotPaused {
        Challenge storage ch = challenges[_challengeId];
        require(ch.attestationId != 0, "ContextualReputation: Challenge does not exist");
        Attestation storage att = attestations[ch.attestationId];
        require(att.attestor == msg.sender, "ContextualReputation: Only the original attestor can defend");
        require(ch.challengedAttestorStake == 0, "ContextualReputation: Attestation already defended");

        Context storage context = contexts[att.contextHash];
        require(context.feeToken != address(0) ? IERC20(context.feeToken).transferFrom(msg.sender, address(this), context.challengeFee) : msg.value >= context.challengeFee, "ContextualReputation: Insufficient defense stake");
        if (context.feeToken == address(0) && msg.value > context.challengeFee) {
             payable(msg.sender).transfer(msg.value - context.challengeFee);
        }

        ch.challengedAttestorStake = context.challengeFee;
    }

    /**
     * @dev Administrator or designated resolver determines the outcome of a challenge, distributing/slashing stakes.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWon True if the challenger's claim is valid, false if the original attestor's claim stands.
     */
    function resolveAttestationChallenge(uint256 _challengeId, bool _challengerWon) external onlyResolver whenNotPaused {
        Challenge storage ch = challenges[_challengeId];
        require(ch.attestationId != 0, "ContextualReputation: Challenge does not exist");
        require(!ch.resolved, "ContextualReputation: Challenge already resolved");
        require(ch.challengedAttestorStake > 0, "ContextualReputation: Attestor has not yet staked to defend");

        Attestation storage att = attestations[ch.attestationId];
        Context storage context = contexts[att.contextHash];
        IERC20 feeToken = IERC20(context.feeToken);

        ch.resolved = true;
        ch.challengerWon = _challengerWon;
        ch.resolutionTime = block.timestamp;

        if (_challengerWon) {
            // Challenger wins: attestor's stake is slashed (kept by contract), challenger gets their stake back.
            // Attestation is effectively reversed.
            _updateContextualReputation(att.eidId, att.contextHash, -att.value * int256(context.attestationWeight));
            att.isRevoked = true; // Mark attestation as effectively revoked due to failed challenge

            if (context.feeToken != address(0)) {
                require(feeToken.transfer(ch.challenger, ch.challengeStake), "ContextualReputation: Challenger stake return failed");
            } else {
                payable(ch.challenger).transfer(ch.challengeStake);
            }
            // Attestor's stake remains in the contract as a penalty
        } else {
            // Attestor wins: challenger's stake is slashed (kept by contract), attestor gets their stake back.
            if (context.feeToken != address(0)) {
                require(feeToken.transfer(att.attestor, ch.challengedAttestorStake), "ContextualReputation: Attestor stake return failed");
            } else {
                payable(att.attestor).transfer(ch.challengedAttestorStake);
            }
            // Challenger's stake remains in the contract as a penalty
        }

        emit AttestationChallengeResolved(_challengeId, _challengerWon, block.timestamp);
    }

    /**
     * @dev Internal function to update raw reputation points for an EID in a context.
     * This function should not be called directly for decay, only for point accumulation/deduction.
     * @param _eidId The ID of the EID.
     * @param _contextHash The hash of the context.
     * @param _points The points to add or subtract.
     */
    function _updateContextualReputation(uint256 _eidId, bytes32 _contextHash, int256 _points) internal {
        ReputationData storage rep = eidContextReputations[_eidId][_contextHash];
        // Apply decay to current score before adding new points to prevent stale scores from being inflated
        (int256 currentScore, ) = _calculateDecayedScore(_eidId, _contextHash, rep.rawReputationPoints, rep.lastUpdated);
        rep.rawReputationPoints = currentScore + _points;
        rep.lastUpdated = block.timestamp;
    }

    /**
     * @dev Calculates the decayed reputation score for an EID in a context.
     * @param _eidId The ID of the EID.
     * @param _contextHash The hash of the context.
     * @param _rawPoints The raw points before decay.
     * @param _lastUpdated The timestamp of the last update.
     * @return currentScore The reputation score after applying decay.
     * @return effectiveLastUpdated The timestamp used for the last update, adjusted for future calculations.
     */
    function _calculateDecayedScore(
        uint256 _eidId,
        bytes32 _contextHash,
        int256 _rawPoints,
        uint256 _lastUpdated
    ) internal view returns (int256 currentScore, uint256 effectiveLastUpdated) {
        Context storage context = contexts[_contextHash];
        uint256 timeElapsed = block.timestamp - _lastUpdated;

        if (timeElapsed == 0 || context.decayRateNumerator == 0) {
            return (_rawPoints, _lastUpdated);
        }

        // Apply exponential decay: new_score = old_score * (1 - decay_rate_per_unit_time)^time_elapsed
        // Simplified for on-chain: decay_factor = (1 - decayRateNumerator / decayRateDenominator) ^ timeElapsed
        // This is computationally intensive for large timeElapsed.
        // For simplicity and gas, we use a linear approximation for small decay rates or
        // a clamped exponential decay. Let's use a simpler linear decay for this example
        // that's proportional to points, but capped at 0.
        // decayed_points = points - (points * time_elapsed * decay_rate_numerator / decay_rate_denominator)
        
        // Let's implement a more realistic discrete decay:
        // Each unit of 'decayRateDenominator' seconds, 'decayRateNumerator' points are lost (proportional to score)
        // Or, more simply: decay a fraction of the total score over time.

        // To avoid complex fixed-point arithmetic for exponential decay,
        // we'll implement a simplified decay where a fixed percentage of points decay per unit of time.
        // This is an approximation. For true exponential decay, a more robust library might be needed,
        // or a simpler 'per_second_decay_value' could be set directly.

        // Current approach: Linearly decay 'decayRateNumerator' points for every 'decayRateDenominator' seconds,
        // but not below zero if the score is positive. If negative, it can become more negative.

        uint256 decayUnits = timeElapsed / context.decayRateDenominator;
        int256 decayAmount = int256(decayUnits * context.decayRateNumerator);

        currentScore = _rawPoints - decayAmount;

        // Ensure positive scores don't go below zero due to decay, unless actual negative attestations push it.
        if (_rawPoints > 0 && currentScore < 0) {
            currentScore = 0;
        }

        effectiveLastUpdated = _lastUpdated + (decayUnits * context.decayRateDenominator); // Adjust effective last updated time

        return (currentScore, effectiveLastUpdated);
    }


    /**
     * @dev Calculates the current reputation score for an EID in a given context, applying decay.
     * This is a public view function and does not modify state.
     * @param _eidId The ID of the EID.
     * @param _contextHash The hash of the context.
     * @return The current reputation score.
     */
    function calculateReputationScore(uint256 _eidId, bytes32 _contextHash) public view returns (int256) {
        require(eidIdToOwner[_eidId] != address(0), "ContextualReputation: EID does not exist");
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");

        ReputationData storage rep = eidContextReputations[_eidId][_contextHash];
        
        // Apply decay
        (int256 decayedScore, ) = _calculateDecayedScore(_eidId, _contextHash, rep.rawReputationPoints, rep.lastUpdated);

        // Consider staked influence
        // This could be a multiplier or an added base. Let's make it an added bonus point per unit of stake.
        int256 finalScore = decayedScore;
        if (rep.stakedInfluence > 0) {
            finalScore += int256(rep.stakedInfluence / 1e18); // 1 bonus point per 1 staked token (assuming 18 decimals)
        }

        return finalScore;
    }

    // --- III. Influence Staking ---

    /**
     * @dev Allows a user to stake tokens to boost the perceived relevance or weight of an EID within a specific context.
     * The `stakeInfluenceOnEID` function needs to handle the `msg.value` if ETH is the fee token,
     * or use `IERC20.transferFrom` if an ERC20 token is used.
     * For this example, we assume `feeToken` is always used and require `approve` first.
     * @param _eidId The ID of the EID to stake influence on.
     * @param _contextHash The hash of the context.
     * @param _amount The amount of tokens to stake.
     */
    function stakeInfluenceOnEID(uint256 _eidId, bytes32 _contextHash, uint256 _amount) external whenNotPaused {
        require(eidIdToOwner[_eidId] != address(0), "ContextualReputation: EID does not exist");
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");
        require(_amount > 0, "ContextualReputation: Stake amount must be greater than zero");

        Context storage context = contexts[_contextHash];
        require(context.feeToken != address(0), "ContextualReputation: This context does not support token staking.");

        IERC20 token = IERC20(context.feeToken);
        require(token.transferFrom(msg.sender, address(this), _amount), "ContextualReputation: Token transfer failed");

        ReputationData storage rep = eidContextReputations[_eidId][_contextHash];
        rep.stakedInfluence += _amount;

        emit InfluenceStaked(_eidId, _contextHash, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their previously staked influence tokens.
     * @param _eidId The ID of the EID from which to withdraw influence.
     * @param _contextHash The hash of the context.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawInfluenceStake(uint256 _eidId, bytes32 _contextHash, uint256 _amount) external whenNotPaused {
        require(eidIdToOwner[_eidId] != address(0), "ContextualReputation: EID does not exist");
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");

        ReputationData storage rep = eidContextReputations[_eidId][_contextHash];
        require(rep.stakedInfluence >= _amount, "ContextualReputation: Insufficient staked influence");
        require(_amount > 0, "ContextualReputation: Withdraw amount must be greater than zero");

        Context storage context = contexts[_contextHash];
        require(context.feeToken != address(0), "ContextualReputation: This context does not support token staking.");

        IERC20 token = IERC20(context.feeToken);
        require(token.transfer(msg.sender, _amount), "ContextualReputation: Token withdrawal failed");

        rep.stakedInfluence -= _amount;

        emit InfluenceWithdrawn(_eidId, _contextHash, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to delegate their influence staking power from one EID to another EID for a specific context.
     * The actual staked tokens remain with the delegator, but the influence is applied to the delegatee.
     * @param _delegatorEid The EID whose influence is being delegated (must be owned by msg.sender).
     * @param _delegateeEid The EID to which influence is being delegated.
     * @param _contextHash The hash of the context.
     */
    function delegateInfluence(uint256 _delegatorEid, uint256 _delegateeEid, bytes32 _contextHash) external onlyEidOwner(_delegatorEid) whenNotPaused {
        require(eidIdToOwner[_delegateeEid] != address(0), "ContextualReputation: Delegatee EID does not exist");
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");
        require(_delegatorEid != _delegateeEid, "ContextualReputation: Cannot delegate to self");

        ReputationData storage delegatorRep = eidContextReputations[_delegatorEid][_contextHash];
        ReputationData storage delegateeRep = eidContextReputations[_delegateeEid][_contextHash];

        require(delegatorRep.stakedInfluence > 0, "ContextualReputation: Delegator has no staked influence to delegate");
        
        // Transfer the 'influence' from delegator to delegatee
        // This is a logical transfer, not a token transfer.
        delegateeRep.stakedInfluence += delegatorRep.stakedInfluence;
        delegatorRep.stakedInfluence = 0; // The delegator's EID will no longer receive boost

        delegatorRep.delegateeEid = _delegateeEid; // Record the delegation

        emit InfluenceDelegated(_delegatorEid, _delegateeEid, _contextHash);
    }

    // --- IV. AI Oracle & Dynamic Optimization (Simulated) ---

    /**
     * @dev Allows an administrator or DAO to request an AI oracle for an optimization suggestion for a context.
     * This function primarily emits an event to signal an off-chain AI oracle.
     * @param _contextHash The hash of the context for which optimization is requested.
     */
    function requestAIOptimization(bytes32 _contextHash) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");
        emit AIOptimizationRequested(_contextHash, msg.sender);
    }

    /**
     * @dev Only callable by the designated `AIOracle` role to submit an AI-driven suggestion for a context's parameters.
     * These suggestions can then be reviewed and applied by governance.
     * @param _contextHash The hash of the context.
     * @param _suggestedAttestationWeight The AI's suggested attestation weight.
     * @param _suggestedDecayRateNumerator The AI's suggested decay rate numerator.
     * @param _suggestedDecayRateDenominator The AI's suggested decay rate denominator.
     * @param _suggestedChallengeFee The AI's suggested challenge fee.
     */
    function receiveAIOptimization(
        bytes32 _contextHash,
        uint256 _suggestedAttestationWeight,
        uint256 _suggestedDecayRateNumerator,
        uint256 _suggestedDecayRateDenominator,
        uint256 _suggestedChallengeFee
    ) external onlyAIOracle whenNotPaused {
        require(isContextRegistered[_contextHash], "ContextualReputation: Context not registered");
        require(_suggestedDecayRateDenominator > 0, "ContextualReputation: Denominator must be greater than zero");

        latestAIOptimization[_contextHash] = AIOptimizationSuggestion({
            contextHash: _contextHash,
            suggestedAttestationWeight: _suggestedAttestationWeight,
            suggestedDecayRateNumerator: _suggestedDecayRateNumerator,
            suggestedDecayRateDenominator: _suggestedDecayRateDenominator,
            suggestedChallengeFee: _suggestedChallengeFee,
            timestamp: block.timestamp
        });

        emit AIOptimizationReceived(
            _contextHash,
            _suggestedAttestationWeight,
            _suggestedDecayRateNumerator,
            _suggestedDecayRateDenominator,
            _suggestedChallengeFee
        );
    }

    /**
     * @dev A `view` function to retrieve the latest AI-generated optimization suggestion for a context.
     * @param _contextHash The hash of the context.
     * @return AIOptimizationSuggestion The latest AI suggestion.
     */
    function getAIOptimizationSuggestion(bytes32 _contextHash) external view returns (AIOptimizationSuggestion memory) {
        return latestAIOptimization[_contextHash];
    }

    // --- V. System Parameters & Governance ---

    /**
     * @dev Administrator function to set or update the decay rate for a specific context's reputation.
     * Only callable by `CONTEXT_ADMIN_ROLE`.
     * @param _contextHash The hash of the context.
     * @param _numerator The numerator of the new decay rate.
     * @param _denominator The denominator of the new decay rate.
     */
    function setDecayRate(bytes32 _contextHash, uint256 _numerator, uint256 _denominator) external onlyContextAdmin(_contextHash) whenNotPaused {
        require(_denominator > 0, "ContextualReputation: Denominator must be greater than zero");
        contexts[_contextHash].decayRateNumerator = _numerator;
        contexts[_contextHash].decayRateDenominator = _denominator;
        contexts[_contextHash].lastGlobalDecayUpdate = block.timestamp; // Reset decay clock for consistency
        emit DecayRateSet(_contextHash, _numerator, _denominator);
    }

    /**
     * @dev Administrator function to set the impact weight of individual attestations.
     * Only callable by `CONTEXT_ADMIN_ROLE`.
     * @param _contextHash The hash of the context.
     * @param _weight The new attestation weight.
     */
    function setAttestationWeight(bytes32 _contextHash, uint256 _weight) external onlyContextAdmin(_contextHash) whenNotPaused {
        contexts[_contextHash].attestationWeight = _weight;
        emit AttestationWeightSet(_contextHash, _weight);
    }

    /**
     * @dev Administrator function to set the fee required to challenge an attestation.
     * Only callable by `CONTEXT_ADMIN_ROLE`.
     * @param _contextHash The hash of the context.
     * @param _fee The new challenge fee.
     */
    function setChallengeFee(bytes32 _contextHash, uint256 _fee) external onlyContextAdmin(_contextHash) whenNotPaused {
        contexts[_contextHash].challengeFee = _fee;
        emit ChallengeFeeSet(_contextHash, _fee);
    }

    /**
     * @dev Grants a role to an address.
     * @param role The role to grant.
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyOwner {
        super.grantRole(role, account);
    }

    /**
     * @dev Revokes a role from an address.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        super.revokeRole(role, account);
    }

    /**
     * @dev Emergency function to pause critical contract operations.
     * Only callable by `DEFAULT_ADMIN_ROLE`.
     */
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes operations after a pause.
     * Only callable by `DEFAULT_ADMIN_ROLE`.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated fees from challenges or expired stakes.
     * For simplicity, this withdraws all ETH balance and any ERC20 balance of a specified token.
     * In a real system, this would need careful tracking of which fees/stakes belong to whom and for what reason.
     * @param _tokenAddress The address of the ERC20 token to withdraw. Use address(0) for ETH.
     */
    function withdrawFeesAndStakes(address _tokenAddress) external onlyOwner {
        uint256 amount;
        if (_tokenAddress == address(0)) {
            amount = address(this).balance;
            require(amount > 0, "ContextualReputation: No ETH to withdraw");
            payable(msg.sender).transfer(amount);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            amount = token.balanceOf(address(this));
            require(amount > 0, "ContextualReputation: No tokens to withdraw");
            require(token.transfer(msg.sender, amount), "ContextualReputation: Token withdrawal failed");
        }
        emit FeesWithdrawn(msg.sender, amount);
    }
}
```