This smart contract, **Chameleon Protocol**, introduces a sophisticated, dynamic reputation system using Soulbound Tokens (SBTs). It's designed for protocols or DAOs that require granular, adaptable, and context-dependent reputation to govern access, influence, and resource allocation.

The core idea is that an agent's reputation isn't a single static number but a collection of "traits" across various "contexts" (e.g., "DeFi Lender," "NFT Curator"). These traits are dynamic: they decay over time if not refreshed, can be boosted by attestations (verifiable claims) or proof-of-behavior, and jointly contribute to an overall "Wisdom Score." This reputation then gates an agent's ability to participate in various protocol functions or access specific resource pools, with the gate requirements themselves being adaptive and adjustable by governance.

---

## Chameleon Protocol: Adaptive Reputation & Dynamic Engagement Network

**Author:** Your Name / AI
**License:** MIT
**Solidity Version:** ^0.8.20

### Outline & Function Summary

**I. Core Structures & State Variables**
*   `Context`: Defines a reputation domain (e.g., "DeFi Lender"). Includes `id`, `name`, `description`, `decayRate`, `boostFactor`, `wisdomWeight`.
*   `AttestationRecord`: Stores details of a reputation modification, including `attester`, `scoreDelta`, `timestamp`, `proofURI`.
*   `Trait`: Represents an agent's dynamic reputation in a specific context. It's an SBT and includes `tokenId`, `agent`, `contextId`, `baseScore`, `lastUpdated` (for decay calculation), `expiresAt`, `attestations` history, and `active` status.
*   `EngagementGate`: Defines a condition for access/engagement based on specific `contextId` trait score and overall `minWisdomScore`.
*   `ContextPool`: Defines a resource pool (e.g., ETH) that requires specific contextual reputation to interact with.
*   Counters for `_contextIds`, `_traitIds`, `_gateIds`, `_poolIds`.
*   Mappings to store `contexts`, `traits`, `engagementGates`, `contextualPools`, and `agentContextToTraitId`.
*   `paused`: Boolean to control protocol pause state.

**II. Admin & Initialization (Inherits `Ownable`)**
1.  `constructor()`: Initializes the contract, sets the deployer as owner, and sets up initial counters.
2.  `registerContext(string calldata _name, string calldata _description)`: **Owner-only.** Creates a new reputation domain with default parameters.
3.  `updateContextParams(uint256 _contextId, uint256 _decayRate, uint256 _boostFactor, uint256 _wisdomWeight)`: **Owner-only.** Modifies the decay rate, boost factor, or wisdom score weight for an existing context.
4.  `grantAdminRole(address _newAdmin)`: **Owner-only.** (Illustrative, uses `transferOwnership` for simplicity if only `Ownable` is used).
5.  `revokeAdminRole(address _adminToRemove)`: **Owner-only.** (Illustrative, for multi-admin systems).

**III. Reputation Trait Management (Dynamic SBTs)**
6.  `issueTrait(address _agent, uint256 _contextId, uint256 _initialScore, uint256 _expiresAt)`: **Owner-only.** Mints a new, non-transferable reputation trait (ERC721 SBT) for an agent within a specified context.
7.  `attestTrait(address _agent, uint252 _contextId, int256 _attestationScoreDelta, string calldata _proofURI)`: **Owner-only.** Allows a trusted entity to adjust an agent's trait score (positive or negative) based on an attestation, storing a link to off-chain proof.
8.  `revokeAttestation(uint256 _traitId, uint256 _attestationIndex, string calldata _reason)`: **Owner-only.** Marks an attestation as revoked for transparency. Score correction requires a subsequent `attestTrait` call with a counter-delta.
9.  `refreshTrait(uint256 _traitId)`: **Agent-callable.** Allows an agent to refresh their trait, preventing decay and potentially applying a small boost to their current score.
10. `submitProofOfBehavior(address _agent, uint256 _contextId, bytes32 _proofHash, int256 _scoreImpact)`: **Agent-callable.** Allows an agent to submit verifiable proof of an action (e.g., from an oracle) to influence their trait score.
11. `getAgentTrait(address _agent, uint256 _contextId)`: **View.** Retrieves an agent's current *calculated* trait score (factoring in decay) and other trait details for a given context.
12. `getAgentWisdomScore(address _agent)`: **View.** Calculates an agent's aggregated, weighted reputation score across all active contexts.
13. `tokenURI(uint256 _tokenId)`: **View.** ERC721 override. Generates a dynamic data URI for a trait SBT, containing its current score, context, agent address, and overall wisdom score.

**IV. Dynamic Engagement Gates**
14. `defineEngagementGate(string calldata _name, uint256 _contextId, uint256 _requiredScore, uint256 _minWisdomScore)`: **Owner-only.** Creates a new access gate requiring specific contextual trait scores and/or a minimum overall Wisdom Score.
15. `updateEngagementGate(uint256 _gateId, uint256 _newRequiredScore, uint256 _newMinWisdomScore)`: **Owner-only.** Modifies the reputation requirements for an existing engagement gate.
16. `checkEngagementAccess(address _agent, uint256 _gateId)`: **View.** Checks if a given agent meets the reputation requirements for a specified gate.
17. `executeGatedAction(uint256 _gateId, bytes calldata _data)`: **Agent-callable.** An example function illustrating how protocol-specific actions can be gated by reputation requirements.

**V. Contextual Resource Pools**
18. `createContextPool(string calldata _name, uint256 _contextId, uint256 _minRequiredScore)`: **Owner-only.** Establishes a new resource pool where interaction (deposit/withdraw) is restricted to agents meeting a specific contextual trait score.
19. `depositIntoContextPool(uint256 _poolId)`: **Agent-callable (payable).** Allows eligible agents to deposit ETH into a contextual pool.
20. `withdrawFromContextPool(uint252 _poolId, uint256 _amount)`: **Agent-callable.** Allows eligible agents to withdraw ETH from a contextual pool.

**VI. Protocol Control & Emergency**
21. `pauseProtocol()`: **Owner-only.** Pauses most state-changing functions in an emergency.
22. `unpauseProtocol()`: **Owner-only.** Unpauses the protocol.
23. `emergencyWithdrawERC20(address _token, uint256 _amount)`: **Owner-only.** Allows the owner to withdraw specific ERC20 tokens in an emergency.
24. `emergencyWithdrawETH(uint256 _amount)`: **Owner-only.** Allows the owner to withdraw ETH from the contract in an emergency.
25. `setWisdomScoreWeights(uint256[] calldata _contextIds, uint256[] calldata _weights)`: **Owner-only.** Adjusts how much each context contributes to the overall Wisdom Score, allowing governance to prioritize reputation domains.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For robust math
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/Base64.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/math/Math.sol"; // For Math.max/min
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For emergencyWithdrawERC20

/**
 * @title Chameleon Protocol: Adaptive Reputation & Dynamic Engagement Network
 * @author Your Name / AI
 * @notice This contract implements a novel, multi-faceted reputation system using dynamic Soulbound Tokens (SBTs)
 *         and integrates this reputation to create adaptive engagement gates and contextual resource pools.
 *         The core idea is that an agent's reputation is not monolithic but varies across defined "contexts"
 *         or "domains," decaying over time but refreshable by new actions or attestations. This dynamic,
 *         contextual reputation directly governs an agent's access, influence, and eligibility within the protocol.
 *
 * @dev Key concepts:
 *      - Contexts: Different domains where an agent can accumulate reputation (e.g., "DeFi Lender", "NFT Curator").
 *      - Reputation Traits (SBTs): Non-transferable ERC721 tokens representing an agent's score within a specific context.
 *        These traits are dynamic, decaying over time but can be boosted by attestations or proof-of-behavior.
 *      - Attestations: Verifiable claims made by other agents or trusted sources that modify an agent's trait score.
 *      - Wisdom Score: An aggregated, weighted score across all contexts, representing an agent's overall standing.
 *      - Engagement Gates: Protocol functions or access points that require agents to meet specific
 *        contextual trait scores or a minimum Wisdom Score. These gates are adaptive and their requirements
 *        can be modified by governance.
 *      - Contextual Pools: Resource pools (e.g., funding, data access) that are only accessible to agents
 *        possessing specific reputation traits and scores.
 *      - Proof-of-Behavior: Mechanism to integrate verifiable on-chain actions to influence reputation.
 */
contract ChameleonProtocol is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- I. Core Structures & State Variables ---

    // Constants
    uint256 public constant MIN_SCORE = 0; // Minimum allowed trait score
    uint256 public constant MAX_SCORE = 10_000; // Maximum allowed trait score (e.g., 100 * 100 for percentage with two decimals)
    uint256 public constant WISDOM_SCORE_PRECISION = 10_000; // For wisdom score calculations (e.g., 100.00% as 10000)

    // State Counters
    Counters.Counter private _contextIds;
    Counters.Counter private _traitIds; // ERC721 tokenId for traits
    Counters.Counter private _gateIds;
    Counters.Counter private _poolIds;

    // 1. `Context`: Defines a reputation domain.
    struct Context {
        uint256 id;
        string name;
        string description;
        uint256 decayRate; // Score decay per unit time (e.g., per block)
        uint256 boostFactor; // How much a refresh/attestation boosts score (e.g., percentage out of 10000)
        uint256 wisdomWeight; // Weight for this context in the overall Wisdom Score calculation (e.g., 10000 for 1x, 5000 for 0.5x)
        bool exists; // To check if contextId is valid
    }
    mapping(uint256 => Context) public contexts;

    // 2. `AttestationRecord`: Stores details of a reputation attestation.
    struct AttestationRecord {
        address attester;
        int256 scoreDelta; // Can be positive or negative
        uint256 timestamp;
        string proofURI; // URI to off-chain proof or explanation
    }

    // 3. `Trait`: Represents an agent's dynamic reputation in a specific context (SBT data).
    struct Trait {
        uint256 tokenId; // ERC721 tokenId
        address agent; // Owner of the SBT
        uint256 contextId;
        uint256 baseScore; // Score without decay calculation
        uint256 lastUpdated; // Timestamp of last score modification (attestation, refresh, issue)
        uint256 expiresAt; // Absolute timestamp, after which trait becomes inactive (0 for never)
        AttestationRecord[] attestations; // History of attestations for transparency
        bool active; // If the trait is currently active
    }
    mapping(uint256 => Trait) public traits; // tokenId => Trait
    mapping(address => mapping(uint256 => uint256)) public agentContextToTraitId; // agent => contextId => tokenId

    // 4. `EngagementGate`: Defines a condition for access/engagement.
    struct EngagementGate {
        uint256 id;
        string name;
        uint256 contextId; // The primary context to check
        uint256 requiredScore; // Minimum score in primary context
        uint256 minWisdomScore; // Minimum overall wisdom score
        bool active;
    }
    mapping(uint256 => EngagementGate) public engagementGates;

    // 5. `ContextPool`: Defines a resource pool with reputation requirements.
    struct ContextPool {
        uint256 id;
        string name;
        uint256 contextId;
        uint256 minRequiredScore; // Minimum score in the specified context to interact
        uint256 ethBalance; // ETH balance of the pool
        bool active;
    }
    mapping(uint256 => ContextPool) public contextualPools;

    // Protocol pause state
    bool public paused;

    // Event definitions
    event ContextRegistered(uint256 indexed contextId, string name, string description);
    event ContextParamsUpdated(uint256 indexed contextId, uint256 decayRate, uint256 boostFactor, uint256 wisdomWeight);
    event TraitIssued(uint256 indexed tokenId, address indexed agent, uint256 indexed contextId, uint256 initialScore, uint256 expiresAt);
    event TraitAttested(uint256 indexed tokenId, address indexed attester, int256 scoreDelta, uint256 newBaseScore, string proofURI);
    event AttestationRevoked(uint256 indexed tokenId, uint256 indexed attestationIndex, string reason);
    event TraitRefreshed(uint256 indexed tokenId, uint256 newBaseScore);
    event ProofOfBehaviorSubmitted(address indexed agent, uint256 indexed contextId, bytes32 proofHash, int256 scoreImpact, uint256 newBaseScore);
    event EngagementGateDefined(uint256 indexed gateId, string name, uint256 indexed contextId, uint256 requiredScore, uint256 minWisdomScore);
    event EngagementGateUpdated(uint256 indexed gateId, uint256 newRequiredScore, uint256 newMinWisdomScore);
    event ContextPoolCreated(uint256 indexed poolId, string name, uint256 indexed contextId, uint256 minRequiredScore);
    event ContextPoolDeposited(uint256 indexed poolId, address indexed depositor, uint256 amount);
    event ContextPoolWithdrawn(uint256 indexed poolId, address indexed withdrawer, uint256 amount);
    event GatedActionExecuted(address indexed agent, uint256 indexed gateId, bytes data);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event WisdomWeightsUpdated(uint256[] contextIds, uint256[] weights);

    modifier whenNotPaused() {
        require(!paused, "Protocol is paused");
        _;
    }

    // --- II. Admin & Initialization (Ownable inherited) ---

    constructor() ERC721("ChameleonReputationTrait", "CHRMT") Ownable(msg.sender) {
        paused = false;
        // The first context ID will be 1
        _contextIds.increment();
    }

    /**
     * @dev Registers a new reputation context (e.g., "DeFi Lender", "NFT Curator").
     * @param _name The name of the context.
     * @param _description A brief description of the context.
     * @return The ID of the newly registered context.
     */
    function registerContext(string calldata _name, string calldata _description) external onlyOwner returns (uint256) {
        uint256 newContextId = _contextIds.current();
        contexts[newContextId] = Context({
            id: newContextId,
            name: _name,
            description: _description,
            decayRate: 1, // Default decay rate (e.g., 1 score point per block)
            boostFactor: 1000, // Default boost factor (e.g., 10% of current score, 1000/10000)
            wisdomWeight: WISDOM_SCORE_PRECISION, // Default 1x weight
            exists: true
        });
        _contextIds.increment();
        emit ContextRegistered(newContextId, _name, _description);
        return newContextId;
    }

    /**
     * @dev Updates the parameters of an existing context.
     * @param _contextId The ID of the context to update.
     * @param _decayRate New decay rate (e.g., 1 score point per block).
     * @param _boostFactor New boost factor (e.g., 1000 for 10% of current score).
     * @param _wisdomWeight New weight for Wisdom Score calculation (e.g., 10000 for 1x).
     */
    function updateContextParams(
        uint256 _contextId,
        uint256 _decayRate,
        uint256 _boostFactor,
        uint256 _wisdomWeight
    ) external onlyOwner {
        require(contexts[_contextId].exists, "Context does not exist");
        contexts[_contextId].decayRate = _decayRate;
        contexts[_contextId].boostFactor = _boostFactor;
        contexts[_contextId].wisdomWeight = _wisdomWeight;
        emit ContextParamsUpdated(_contextId, _decayRate, _boostFactor, _wisdomWeight);
    }

    // Note on `grantAdminRole` and `revokeAdminRole`:
    // As this contract inherits `Ownable`, there's only one owner.
    // `grantAdminRole` would effectively be `transferOwnership`.
    // `revokeAdminRole` would require transferring ownership *away* from `_adminToRemove`
    // to someone else, or a more complex `AccessControl` pattern with multiple roles.
    // For simplicity, we stick to the `Ownable` single-admin model,
    // and thus these functions are conceptual unless a multi-role system (like OpenZeppelin's `AccessControl`)
    // is explicitly implemented.

    // --- III. Reputation Trait Management (Dynamic SBTs) ---

    /**
     * @dev Mints a new reputation trait SBT for an agent in a specific context.
     *      Callable by owner, or a designated "issuer" role if using AccessControl.
     *      This SBT is non-transferable by design (no `_transfer` function is exposed).
     * @param _agent The address of the agent to issue the trait to.
     * @param _contextId The ID of the context for this trait.
     * @param _initialScore The initial score for this trait (clamped between MIN_SCORE and MAX_SCORE).
     * @param _expiresAt An absolute timestamp when this trait expires (0 for never).
     */
    function issueTrait(
        address _agent,
        uint256 _contextId,
        uint256 _initialScore,
        uint256 _expiresAt
    ) external onlyOwner whenNotPaused returns (uint256) {
        require(contexts[_contextId].exists, "Context does not exist");
        require(agentContextToTraitId[_agent][_contextId] == 0, "Agent already has a trait for this context");
        require(_initialScore >= MIN_SCORE && _initialScore <= MAX_SCORE, "Initial score out of bounds");

        _traitIds.increment();
        uint256 newTraitId = _traitIds.current();

        Trait storage newTrait = traits[newTraitId];
        newTrait.tokenId = newTraitId;
        newTrait.agent = _agent;
        newTrait.contextId = _contextId;
        newTrait.baseScore = _initialScore;
        newTrait.lastUpdated = block.timestamp;
        newTrait.expiresAt = _expiresAt;
        newTrait.active = true;

        agentContextToTraitId[_agent][_contextId] = newTraitId;
        _mint(_agent, newTraitId); // Mint the ERC721 SBT
        _setTokenURI(newTraitId, ""); // Token URI will be generated dynamically

        emit TraitIssued(newTraitId, _agent, _contextId, _initialScore, _expiresAt);
        return newTraitId;
    }

    /**
     * @dev Prevents transfer of Soulbound Tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Only allow minting (from == address(0)) or burning (to == address(0))
        require(from == address(0) || to == address(0), "ChameleonProtocol: Traits are Soulbound and cannot be transferred");
    }

    /**
     * @dev Calculates the current decayed score of a trait.
     * @param _traitId The ID of the trait.
     * @return The current calculated score.
     */
    function _calculateCurrentScore(uint256 _traitId) internal view returns (uint256) {
        Trait storage trait = traits[_traitId];
        Context storage context = contexts[trait.contextId];

        if (!trait.active || (trait.expiresAt != 0 && block.timestamp >= trait.expiresAt)) {
            return MIN_SCORE;
        }

        uint256 timeElapsed = block.timestamp.sub(trait.lastUpdated);
        uint256 decayAmount = timeElapsed.mul(context.decayRate);

        if (trait.baseScore <= decayAmount) {
            return MIN_SCORE;
        }
        return trait.baseScore.sub(decayAmount);
    }

    /**
     * @dev Internal helper to update a trait's base score and last updated timestamp.
     *      Applies the score delta to the *current decayed score* and sets that as the new base score.
     * @param _traitId The ID of the trait to update.
     * @param _scoreDelta The actual delta applied.
     */
    function _applyScoreDelta(uint256 _traitId, int256 _scoreDelta) internal {
        Trait storage trait = traits[_traitId];
        // Calculate the score with decay before applying delta
        uint256 currentDecayedScore = _calculateCurrentScore(_traitId);

        // Apply delta to the current decayed score
        int256 effectiveScore;
        if (_scoreDelta > 0) {
            effectiveScore = int256(currentDecayedScore).add(_scoreDelta);
        } else {
            effectiveScore = int256(currentDecayedScore).sub(int256(uint256(-_scoreDelta)));
        }

        // Clamp the new score to MIN_SCORE and MAX_SCORE
        uint256 finalBaseScore = uint256(Math.max(MIN_SCORE, Math.min(MAX_SCORE, effectiveScore)));

        trait.baseScore = finalBaseScore;
        trait.lastUpdated = block.timestamp; // Reset decay timer
    }

    /**
     * @dev Allows trusted entities (currently owner) to attest to an agent's trait score.
     *      This updates the base score of the trait, based on its current decayed value.
     * @param _agent The agent whose trait is being attested.
     * @param _contextId The context of the trait.
     * @param _attestationScoreDelta The positive or negative change to the trait's score.
     * @param _proofURI URI to off-chain proof or explanation.
     */
    function attestTrait(
        address _agent,
        uint256 _contextId,
        int256 _attestationScoreDelta,
        string calldata _proofURI
    ) external onlyOwner whenNotPaused { // Can be extended to trusted attester roles.
        uint256 traitId = agentContextToTraitId[_agent][_contextId];
        require(traitId != 0, "Agent does not have a trait for this context");
        Trait storage trait = traits[traitId];
        require(trait.active, "Trait is inactive or expired");

        _applyScoreDelta(traitId, _attestationScoreDelta);

        trait.attestations.push(AttestationRecord({
            attester: msg.sender,
            scoreDelta: _attestationScoreDelta,
            timestamp: block.timestamp,
            proofURI: _proofURI
        }));

        emit TraitAttested(traitId, msg.sender, _attestationScoreDelta, trait.baseScore, _proofURI);
    }

    /**
     * @dev Admin can revoke a specific attestation. This function primarily serves for transparency.
     *      To correct the score impact of a revoked attestation, the owner would need to issue a new
     *      `attestTrait` call with a negative score delta to counteract the original attestation.
     * @param _traitId The ID of the trait.
     * @param _attestationIndex The index of the attestation in the `attestations` array.
     * @param _reason Reason for revocation.
     */
    function revokeAttestation(uint256 _traitId, uint256 _attestationIndex, string calldata _reason) external onlyOwner whenNotPaused {
        Trait storage trait = traits[_traitId];
        require(trait.tokenId == _traitId, "Invalid trait ID");
        require(_attestationIndex < trait.attestations.length, "Attestation index out of bounds");

        // For simplicity, we just emit an event. A more robust system might update a flag
        // within AttestationRecord or prune the array (gas-intensive for large arrays).
        emit AttestationRevoked(_traitId, _attestationIndex, _reason);
    }

    /**
     * @dev Allows an agent to "refresh" their trait, preventing immediate decay and potentially boosting it slightly.
     *      This resets `lastUpdated` and applies a boost factor to the *current decayed score*.
     * @param _traitId The ID of the trait to refresh.
     */
    function refreshTrait(uint256 _traitId) external whenNotPaused {
        Trait storage trait = traits[_traitId];
        require(trait.tokenId == _traitId && trait.agent == msg.sender, "Caller is not the agent of this trait");
        require(trait.active, "Trait is inactive or expired");

        // Calculate current score with decay
        uint256 currentScore = _calculateCurrentScore(_traitId);
        Context storage context = contexts[trait.contextId];

        // Apply a boost factor on the current score
        uint256 boostAmount = currentScore.mul(context.boostFactor).div(WISDOM_SCORE_PRECISION); // e.g., 10% boost
        int256 scoreDelta = int256(boostAmount);

        _applyScoreDelta(_traitId, scoreDelta);

        emit TraitRefreshed(_traitId, trait.baseScore);
    }

    /**
     * @dev Allows an agent to submit verifiable proof of behavior (e.g., from an oracle or registered source)
     *      to influence a specific reputation trait. The `_proofHash` would typically be verified off-chain
     *      or by another contract (e.g., ZK verifier).
     * @param _agent The agent submitting the proof.
     * @param _contextId The context ID for which the proof is relevant.
     * @param _proofHash A hash representing the verifiable proof (e.g., a hash of a ZK proof, or a signature).
     * @param _scoreImpact The positive or negative score change.
     */
    function submitProofOfBehavior(
        address _agent,
        uint256 _contextId,
        bytes32 _proofHash,
        int256 _scoreImpact
    ) external whenNotPaused {
        // In a real system, this function would typically be called by a trusted oracle or
        // a dedicated verifier contract *after* validating the proof.
        // For this example, we'll allow `msg.sender` to be the agent themselves, acting as a "self-attestation"
        // or assuming an external process ensures proof validity before the call.
        require(msg.sender == _agent, "Only the agent can submit proof of behavior for themselves");

        uint256 traitId = agentContextToTraitId[_agent][_contextId];
        require(traitId != 0, "Agent does not have a trait for this context");
        Trait storage trait = traits[traitId];
        require(trait.active, "Trait is inactive or expired");

        _applyScoreDelta(traitId, _scoreImpact);

        trait.attestations.push(AttestationRecord({
            attester: address(0), // Special address for self-submitted proof/system verified
            scoreDelta: _scoreImpact,
            timestamp: block.timestamp,
            proofURI: string(abi.encodePacked("proof://", Strings.toHexString(uint256(_proofHash)))) // Example URI
        }));

        emit ProofOfBehaviorSubmitted(_agent, _contextId, _proofHash, _scoreImpact, trait.baseScore);
    }


    /**
     * @dev Retrieves an agent's current calculated trait score and details for a context.
     * @param _agent The address of the agent.
     * @param _contextId The ID of the context.
     * @return Trait struct details.
     */
    function getAgentTrait(address _agent, uint256 _contextId) external view returns (Trait memory) {
        uint256 traitId = agentContextToTraitId[_agent][_contextId];
        if (traitId == 0) {
            return Trait({
                tokenId: 0, agent: _agent, contextId: _contextId, baseScore: MIN_SCORE,
                lastUpdated: 0, expiresAt: 0, attestations: new AttestationRecord[](0), active: false
            });
        }
        Trait storage trait = traits[traitId];
        Trait memory currentTrait = trait; // Create a memory copy
        currentTrait.baseScore = _calculateCurrentScore(traitId); // Update score with decay
        return currentTrait;
    }

    /**
     * @dev Calculates an agent's aggregated, weighted reputation score across all active contexts.
     * @param _agent The address of the agent.
     * @return The calculated Wisdom Score.
     */
    function getAgentWisdomScore(address _agent) public view returns (uint256) {
        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;

        // Iterate through all registered contexts (starting from 1 as 0 is not used by _contextIds.increment())
        for (uint256 i = 1; i < _contextIds.current(); i++) {
            if (contexts[i].exists) {
                uint256 traitId = agentContextToTraitId[_agent][i];
                if (traitId != 0) {
                    uint256 currentTraitScore = _calculateCurrentScore(traitId);
                    totalWeightedScore = totalWeightedScore.add(currentTraitScore.mul(contexts[i].wisdomWeight));
                    totalWeight = totalWeight.add(contexts[i].wisdomWeight);
                }
            }
        }

        if (totalWeight == 0) {
            return MIN_SCORE;
        }
        // Normalize by total weight, considering WISDOM_SCORE_PRECISION to maintain the scale
        return totalWeightedScore.div(totalWeight);
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata for the SBTs.
     *      This will generate a JSON blob on-the-fly, Base64 encoded.
     * @param _tokenId The ID of the trait SBT.
     * @return A data URI containing the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        Trait storage trait = traits[_tokenId];
        Context storage context = contexts[trait.contextId];

        uint256 currentScore = _calculateCurrentScore(_tokenId);
        uint256 wisdomScore = getAgentWisdomScore(trait.agent);

        string memory json = string(abi.encodePacked(
            '{"name": "', context.name, ' Trait #', Strings.toString(_tokenId),
            '", "description": "Reputation trait for ', context.name, ' context.",',
            '"image": "ipfs://QmbFf1tE1B4Z2yM2dJ3P7B2D6C5A9H8G7F6E5D4C3B2A1",', // Example image URL for metadata
            '"attributes": [',
            '{"trait_type": "Context", "value": "', context.name, '"},',
            '{"trait_type": "Current Score", "value": ', Strings.toString(currentScore), '},',
            '{"trait_type": "Base Score (last recorded)", "value": ', Strings.toString(trait.baseScore), '},',
            '{"trait_type": "Last Updated (timestamp)", "value": ', Strings.toString(trait.lastUpdated), '},',
            '{"trait_type": "Expires At (timestamp)", "value": ', Strings.toString(trait.expiresAt), '},',
            '{"trait_type": "Agent Address", "value": "', Strings.toHexString(uint160(trait.agent), 20), '"},',
            '{"trait_type": "Wisdom Score (Overall)", "value": ', Strings.toString(wisdomScore), '}',
            ']}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- IV. Dynamic Engagement Gates ---

    /**
     * @dev Defines a new engagement gate with specific reputation requirements.
     * @param _name The name of the gate (e.g., "Premium Access").
     * @param _contextId The ID of the primary context to check.
     * @param _requiredScore The minimum score required in the primary context.
     * @param _minWisdomScore The minimum overall Wisdom Score required.
     * @return The ID of the newly defined engagement gate.
     */
    function defineEngagementGate(
        string calldata _name,
        uint256 _contextId,
        uint256 _requiredScore,
        uint256 _minWisdomScore
    ) external onlyOwner whenNotPaused returns (uint256) {
        require(contexts[_contextId].exists, "Context does not exist for gate");
        require(_requiredScore >= MIN_SCORE && _requiredScore <= MAX_SCORE, "Required score out of bounds");
        require(_minWisdomScore >= MIN_SCORE && _minWisdomScore <= MAX_SCORE, "Min wisdom score out of bounds");

        _gateIds.increment();
        uint256 newGateId = _gateIds.current();

        engagementGates[newGateId] = EngagementGate({
            id: newGateId,
            name: _name,
            contextId: _contextId,
            requiredScore: _requiredScore,
            minWisdomScore: _minWisdomScore,
            active: true
        });

        emit EngagementGateDefined(newGateId, _name, _contextId, _requiredScore, _minWisdomScore);
        return newGateId;
    }

    /**
     * @dev Modifies the requirements of an existing engagement gate.
     * @param _gateId The ID of the gate to update.
     * @param _newRequiredScore The new minimum score for the primary context.
     * @param _newMinWisdomScore The new minimum overall Wisdom Score.
     */
    function updateEngagementGate(
        uint256 _gateId,
        uint256 _newRequiredScore,
        uint256 _newMinWisdomScore
    ) external onlyOwner whenNotPaused {
        EngagementGate storage gate = engagementGates[_gateId];
        require(gate.active, "Engagement gate is inactive or does not exist");
        require(_newRequiredScore >= MIN_SCORE && _newRequiredScore <= MAX_SCORE, "Required score out of bounds");
        require(_newMinWisdomScore >= MIN_SCORE && _newMinWisdomScore <= MAX_SCORE, "Min wisdom score out of bounds");

        gate.requiredScore = _newRequiredScore;
        gate.minWisdomScore = _newMinWisdomScore;

        emit EngagementGateUpdated(_gateId, _newRequiredScore, _newMinWisdomScore);
    }

    /**
     * @dev Checks if an agent meets the reputation requirements for a specific gate.
     * @param _agent The address of the agent to check.
     * @param _gateId The ID of the engagement gate.
     * @return True if the agent has access, false otherwise.
     */
    function checkEngagementAccess(address _agent, uint256 _gateId) public view returns (bool) {
        EngagementGate storage gate = engagementGates[_gateId];
        require(gate.active, "Engagement gate is inactive or does not exist");

        // Check contextual trait score
        uint256 agentContextTraitId = agentContextToTraitId[_agent][gate.contextId];
        if (agentContextTraitId == 0) return false;

        uint256 currentContextScore = _calculateCurrentScore(agentContextTraitId);
        if (currentContextScore < gate.requiredScore) return false;

        // Check overall Wisdom Score
        uint256 agentWisdomScore = getAgentWisdomScore(_agent);
        if (agentWisdomScore < gate.minWisdomScore) return false;

        return true;
    }

    /**
     * @dev Example function that requires an agent to pass an engagement gate.
     *      Actual logic for the "action" would be implemented here or in a separate contract.
     * @param _gateId The ID of the engagement gate to check.
     * @param _data Arbitrary data for the gated action.
     */
    function executeGatedAction(uint256 _gateId, bytes calldata _data) external whenNotPaused {
        require(checkEngagementAccess(msg.sender, _gateId), "Agent does not meet requirements for this gate");

        // --- Insert actual gated action logic here ---
        // For example:
        // if (someCondition) { doSomething(); }
        // If this contract manages a resource, it would allocate it here.
        // If it's a proxy, it would call another contract.
        // For demonstration, let's just emit an event.
        emit GatedActionExecuted(msg.sender, _gateId, _data);
        // ---------------------------------------------
    }

    // --- V. Contextual Resource Pools ---

    /**
     * @dev Creates a new resource pool that is only accessible to agents with certain contextual reputation.
     * @param _name The name of the pool.
     * @param _contextId The context ID for the required trait.
     * @param _minRequiredScore The minimum score needed in that context to interact with the pool.
     * @return The ID of the newly created contextual pool.
     */
    function createContextPool(
        string calldata _name,
        uint256 _contextId,
        uint256 _minRequiredScore
    ) external onlyOwner whenNotPaused returns (uint256) {
        require(contexts[_contextId].exists, "Context does not exist for pool");
        require(_minRequiredScore >= MIN_SCORE && _minRequiredScore <= MAX_SCORE, "Min required score out of bounds");

        _poolIds.increment();
        uint256 newPoolId = _poolIds.current();

        contextualPools[newPoolId] = ContextPool({
            id: newPoolId,
            name: _name,
            contextId: _contextId,
            minRequiredScore: _minRequiredScore,
            ethBalance: 0,
            active: true
        });

        emit ContextPoolCreated(newPoolId, _name, _contextId, _minRequiredScore);
        return newPoolId;
    }

    /**
     * @dev Allows eligible agents to deposit ETH into a contextual pool.
     * @param _poolId The ID of the pool to deposit into.
     */
    function depositIntoContextPool(uint256 _poolId) external payable whenNotPaused {
        ContextPool storage pool = contextualPools[_poolId];
        require(pool.active, "Context pool is inactive or does not exist");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // Check eligibility
        uint256 agentContextTraitId = agentContextToTraitId[msg.sender][pool.contextId];
        require(agentContextTraitId != 0, "Agent does not have trait for this pool's context");
        require(_calculateCurrentScore(agentContextTraitId) >= pool.minRequiredScore, "Agent does not meet required score for this pool");

        pool.ethBalance = pool.ethBalance.add(msg.value);
        emit ContextPoolDeposited(_poolId, msg.sender, msg.value);
    }

    /**
     * @dev Allows eligible agents to withdraw ETH from a contextual pool.
     * @param _poolId The ID of the pool to withdraw from.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFromContextPool(uint256 _poolId, uint256 _amount) external whenNotPaused {
        ContextPool storage pool = contextualPools[_poolId];
        require(pool.active, "Context pool is inactive or does not exist");
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(pool.ethBalance >= _amount, "Insufficient funds in pool");

        // Check eligibility
        uint256 agentContextTraitId = agentContextToTraitId[msg.sender][pool.contextId];
        require(agentContextTraitId != 0, "Agent does not have trait for this pool's context");
        require(_calculateCurrentScore(agentContextTraitId) >= pool.minRequiredScore, "Agent does not meet required score for this pool");

        pool.ethBalance = pool.ethBalance.sub(_amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed");

        emit ContextPoolWithdrawn(_poolId, msg.sender, _amount);
    }

    // --- VI. Protocol Control & Emergency ---

    /**
     * @dev Pauses the protocol, preventing most state-changing operations.
     */
    function pauseProtocol() external onlyOwner {
        require(!paused, "Protocol is already paused");
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol, allowing operations to resume.
     */
    function unpauseProtocol() external onlyOwner {
        require(paused, "Protocol is not paused");
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw arbitrary ERC20 tokens in case of emergency.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        // Ensure the contract actually has the tokens. This check helps prevent accidental calls.
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance in contract");
        token.transfer(owner(), _amount);
    }

    /**
     * @dev Allows the owner to withdraw ETH from the contract in case of emergency.
     * @param _amount The amount of ETH to withdraw.
     */
    function emergencyWithdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient ETH balance in contract");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Admin can adjust the weights of contexts for Wisdom Score calculation.
     *      This allows governance to prioritize certain reputation domains.
     * @param _contextIds An array of context IDs.
     * @param _weights An array of corresponding weights (e.g., 10000 for 1x).
     */
    function setWisdomScoreWeights(uint256[] calldata _contextIds, uint256[] calldata _weights) external onlyOwner {
        require(_contextIds.length == _weights.length, "Arrays must have same length");
        for (uint256 i = 0; i < _contextIds.length; i++) {
            uint256 contextId = _contextIds[i];
            require(contexts[contextId].exists, "Context does not exist");
            contexts[contextId].wisdomWeight = _weights[i];
        }
        emit WisdomWeightsUpdated(_contextIds, _weights);
    }
}
```