This smart contract system, named "Quantum Nexus: Adaptive Digital Sentinels" (QNDS), introduces a highly dynamic and interactive ecosystem. It leverages advanced concepts like **dynamic NFTs**, **adaptive tokenomics**, **simulated AI integration for protocol governance**, and **conceptual cross-chain interaction** through "Echo Portals". The core idea is to create a living, evolving digital asset that reacts to both user behavior and network-wide economic conditions, managed by a self-regulating "Quantum Resonance Engine".

The system is designed to be highly creative, avoiding direct duplication of existing open-source contracts by integrating these concepts into a unique and cohesive whole. OpenZeppelin libraries are used for standard ERC20, ERC721, AccessControl, and Pausable functionalities, which serve as foundational building blocks for the custom logic.

---

## Quantum Nexus: Adaptive Digital Sentinels (QNDS)

**Outline:**

The Quantum Nexus is a decentralized protocol built around two core components:
1.  **`QN_Sentinel` (ERC721 NFT):** Represents unique "Digital Sentinels." Each Sentinel possesses dynamic attributes: `ResonanceLevel` (influences ECHO token generation) and `IntegrityScore` (measures resilience against degradation). These attributes evolve based on user interactions, staking duration, and external "AI Insight Scores."
2.  **`ECHO_Token` (ERC20):** The primary utility token of the ecosystem. Users stake ECHO to activate their Sentinels. Active Sentinels then "synthesize" (mint) new ECHO tokens over time, with generation rates governed by their `ResonanceLevel` and the global `Quantum Resonance Engine` parameters.

**Key Advanced & Trendy Concepts:**

*   **Dynamic NFTs:** Sentinel attributes are not static. They change over time and in response to on-chain events and oracle-fed data.
*   **Adaptive Tokenomics:** The `Quantum Resonance Engine (QRE)` dynamically adjusts core economic parameters (ECHO synthesis rate, Sentinel decay rate) based on aggregated network health metrics and "AI Insight Scores." This creates a self-regulating and responsive token economy.
*   **Simulated AI Integration:** An `ORACLE_ROLE` can feed "AI Insight Scores" (representing external AI evaluations of user reputation, project contributions, etc.) into the system, influencing QRE adjustments and direct Sentinel attribute boosts.
*   **Gamified Progression & Incentives:** Users are incentivized to engage, stake, and accumulate positive attestations to evolve their Sentinels, maximize ECHO generation, and maintain Sentinel integrity.
*   **Conceptual Cross-Chain Readiness (Echo Portals):** A module that allows users to "lock" Sentinel attributes or ECHO tokens, simulating an intent for cross-chain activity. This action itself can trigger Sentinel evolution or provide future benefits.
*   **Reputation & Attestation System:** A module for recording validated attestations (verifiable credentials) about users, impacting their Sentinels and overall standing in the ecosystem.
*   **Role-Based Access Control & Pausability:** Robust administrative features for managing roles, pausing critical operations, and upgrading oracle addresses.

**Roles:**

*   **`DEFAULT_ADMIN_ROLE`:** The highest privilege. Can grant/revoke other roles, perform initial ECHO minting, pause/unpause the contract, and update the oracle address.
*   **`ORACLE_ROLE`:** A trusted entity (or multi-sig) responsible for updating the `NetworkHealthMetric`, setting `AIInsightScores` for users, submitting validated `Attestations`, and triggering `QRE` adjustments.
*   **`SENTINEL_MINDER_ROLE`:** Can mint and burn Sentinels (e.g., for specific game logic, maintenance, or as part of a future DAO governance decision). The `QuantumNexus` contract itself holds this role for automated Sentinel management.
*   **`MINTER_ROLE` (on `ECHO_Token`):** Held by the `QuantumNexus` contract to allow programmatic ECHO synthesis.
*   **`BURNER_ROLE` (on `ECHO_Token`):** Held by the `QuantumNexus` contract for specific burn mechanisms (e.g., in a decay scenario or for fee collection).

---

**Function Summary (Total: 31 Functions):**

**I. Core Infrastructure & Token Management (8 functions)**
1.  `constructor()`: Deploys and initializes the `QN_Sentinel` and `ECHO_Token` contracts, sets up initial roles, and configures base QRE parameters.
2.  `mintSentinel(address to)`: Mints a new `QN_Sentinel` NFT to a specified address, initializing its dynamic attributes. Requires `DEFAULT_ADMIN_ROLE`.
3.  `burnSentinel(uint256 tokenId)`: Burns a `QN_Sentinel` NFT. Requires `DEFAULT_ADMIN_ROLE` and ensures the Sentinel is inactive and not portal-locked.
4.  `getSentinelAttributes(uint256 tokenId)`: Retrieves the current dynamic `ResonanceLevel`, `IntegrityScore`, `isActive` status, staked amount, and `portalLockEndTime` of a Sentinel.
5.  `setSentinelURI(uint256 tokenId, string memory _tokenURI)`: Sets the metadata URI for a Sentinel NFT. Requires the Sentinel's owner or an approved address.
6.  `ECHO_initialMint(address to, uint256 amount)`: Admin-only function for initial minting of `ECHO_Token` to a specified address. Requires `DEFAULT_ADMIN_ROLE`.
7.  `ECHO_burn(address from, uint256 amount)`: Admin-only function for burning `ECHO_Token` from a specified address. Requires `DEFAULT_ADMIN_ROLE`.
8.  `ECHO_transfer(address recipient, uint256 amount)`: Proxies the standard ERC20 `transfer` function for `ECHO_Token`, adhering to the contract's pausable state.

**II. Sentinel Activation & Rewards (6 functions)**
9.  `stakeECHOForSentinel(uint256 tokenId, uint256 amount)`: Allows a Sentinel owner to stake `ECHO_Token` to a specific Sentinel, activating it and commencing `ECHO_Token` synthesis. Prevents re-staking an active Sentinel.
10. `unstakeECHOFromSentinel(uint256 tokenId)`: Allows a Sentinel owner to unstake their `ECHO_Token`, deactivating the Sentinel. Transfers back staked ECHO and any pending synthesized ECHO. Requires the Sentinel not to be portal-locked.
11. `claimSynthesizedECHO(uint256[] memory tokenIds)`: Enables a user to claim accumulated `ECHO_Token` from multiple active Sentinels they own.
12. `getPendingSynthesizedECHO(uint256 tokenId)`: Calculates and returns the amount of `ECHO_Token` that a specific Sentinel has synthesized but not yet claimed.
13. `_calculateAndStorePendingECHO(uint256 tokenId)`: Internal function to calculate and store pending ECHO for a Sentinel, updating its `lastUpdateTimestamp`.
14. `_forceDeactivateSentinel(uint256 tokenId)`: Internal function to forcibly deactivate a Sentinel (e.g., if `IntegrityScore` reaches zero). Returns staked ECHO but burns pending yield.

**III. Dynamic Sentinel Evolution & Quantum Resonance Engine (QRE) (8 functions)**
15. `evolveSentinelResonance(uint256 tokenId, uint256 boostAmount)`: Increases a Sentinel's `ResonanceLevel`. Callable by the owner (e.g., as a reward for activity).
16. `degradeSentinelIntegrity(uint256 tokenId, uint256 decayAmount)`: Decreases a Sentinel's `IntegrityScore`. Callable by `ORACLE_ROLE` (e.g., as part of the QRE decay mechanism). Can trigger `_forceDeactivateSentinel` if integrity drops to zero.
17. `updateNetworkHealthMetric(uint256 newMetric)`: Updates the global `networkHealthMetric` (representing overall protocol activity). Callable by `ORACLE_ROLE`.
18. `setAIInsightScore(address user, uint256 score)`: Sets an AI-derived score for a specific user, contributing to the aggregated AI insights. Callable by `ORACLE_ROLE`.
19. `triggerQREAdjustment()`: Triggers the `Quantum Resonance Engine` to recalculate and adjust the `globalSynthesisRate` and `globalDecayRate` based on current network health and aggregated AI insights. Callable by `ORACLE_ROLE` at a defined interval.
20. `getGlobalSynthesisRate()`: Returns the current global rate at which Sentinels synthesize `ECHO_Token`.
21. `getGlobalDecayRate()`: Returns the current global rate at which Sentinel `IntegrityScore` degrades.
22. `_calculateQREAdjustments(uint256 currentHealth, uint256 aggregateAI)`: Internal pure function containing the adaptive logic for adjusting synthesis and decay rates based on input metrics.

**IV. Echo Portals (Conceptual Cross-Chain) & Advanced Interactions (4 functions)**
23. `initiateEchoPortalLock(uint256 tokenId, uint256 duration)`: Locks a Sentinel's `ResonanceLevel` for a specified duration, conceptually preparing it for a cross-chain transfer or interaction. Requires the Sentinel to be inactive.
24. `finalizeEchoPortalUnlock(uint256 tokenId)`: Unlocks a Sentinel after its conceptual cross-chain transfer or interaction is complete. Provides a small `ResonanceLevel` boost as a reward for completion.
25. `submitValidatedAttestation(address user, uint256 attestationId, bytes32 attestationHash)`: Allows the `ORACLE_ROLE` to submit a verifiable credential or attestation about a user. This action also provides a small `ResonanceLevel` boost to the user's active Sentinels.
26. `getUserAttestations(address user)`: Retrieves an array of attestation data (ID, hash, timestamp) for a specific user.

**V. Role Management & Protocol Control (5 functions)**
27. `grantRole(bytes32 role, address account)`: Grants a specified role to an account. Requires `DEFAULT_ADMIN_ROLE`.
28. `revokeRole(bytes32 role, address account)`: Revokes a specified role from an account. Requires `DEFAULT_ADMIN_ROLE`.
29. `pause()`: Pauses all pausable operations in the contract. Requires `DEFAULT_ADMIN_ROLE`.
30. `unpause()`: Unpauses the contract. Requires `DEFAULT_ADMIN_ROLE`.
31. `setOracleAddress(address newOracle)`: Updates the address assigned to the `ORACLE_ROLE`. Requires `DEFAULT_ADMIN_ROLE`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline: Quantum Nexus: Adaptive Digital Sentinels (QNDS)
//
// This smart contract system introduces a novel approach to dynamic NFTs,
// adaptive tokenomics, and simulated AI integration within a gamified
// ecosystem. It comprises an ERC721 NFT (QN_Sentinel) representing
// "Digital Sentinels" and an ERC20 utility token (ECHO_Token).
//
// Key Concepts:
// 1.  Dynamic Sentinels (ERC721): NFTs whose attributes (ResonanceLevel, IntegrityScore)
//     evolve based on user actions, staking duration, and oracle-fed "AI Insights."
// 2.  ECHO Token (ERC20): The utility token, staked to activate Sentinels. Active
//     Sentinels "synthesize" new ECHO tokens at dynamically adjusted rates.
// 3.  Quantum Resonance Engine (QRE): An adaptive mechanism that continuously
//     adjusts global ECHO synthesis and Sentinel decay rates based on aggregated
//     "Network Health Metrics" and "AI Insight Scores" provided by an oracle.
//     This creates a self-regulating economic environment.
// 4.  Echo Portals (Conceptual Cross-Chain): A module simulating the locking
//     of Sentinel attributes or ECHO tokens for hypothetical cross-chain
//     interactions, affecting Sentinel evolution.
// 5.  Attestation & Reputation: Users can submit validated attestations (via oracle)
//     that contribute to their overall reputation and potentially boost Sentinel attributes.
// 6.  Gamified Progression: Users are incentivized to engage with the protocol,
//     stake ECHO, and obtain positive attestations to evolve their Sentinels
//     and maximize ECHO synthesis.
//
// Roles:
// - DEFAULT_ADMIN_ROLE: Can grant/revoke other roles, pause/unpause, perform initial ECHO mint.
// - ORACLE_ROLE: Can update Network Health Metric, set AI Insight Scores, submit Attestations, trigger QRE adjustments.
// - SENTINEL_MINDER_ROLE: Can burn Sentinels (e.g., for maintenance or specific game logic).
//

// Function Summary:
//
// I. Core Infrastructure & Token Management:
// 1.  constructor(): Deploys and initializes QN_Sentinel and ECHO_Token, sets initial roles.
// 2.  mintSentinel(address to): Mints a new Sentinel NFT to a specified address.
// 3.  burnSentinel(uint256 tokenId): Burns a Sentinel NFT (requires DEFAULT_ADMIN_ROLE).
// 4.  getSentinelAttributes(uint256 tokenId): Retrieves the current dynamic attributes of a Sentinel.
// 5.  setSentinelURI(uint256 tokenId, string memory _tokenURI): Sets the metadata URI for a Sentinel (requires owner or approved).
// 6.  ECHO_initialMint(address to, uint256 amount): Admin-only initial minting for ECHO tokens.
// 7.  ECHO_burn(address from, uint256 amount): Admin-only burning of ECHO tokens.
// 8.  ECHO_transfer(address recipient, uint256 amount): Standard ERC20 transfer for ECHO tokens.
//
// II. Sentinel Activation & Rewards:
// 9.  stakeECHOForSentinel(uint256 tokenId, uint256 amount): Stakes ECHO for a Sentinel, activating it and starting ECHO synthesis.
// 10. unstakeECHOFromSentinel(uint256 tokenId): Unstakes ECHO, deactivating a Sentinel and stopping synthesis.
// 11. claimSynthesizedECHO(uint256[] memory tokenIds): Allows users to claim accumulated ECHO from multiple active Sentinels.
// 12. getPendingSynthesizedECHO(uint256 tokenId): Calculates the amount of ECHO pending for a specific Sentinel.
// 13. _calculateAndStorePendingECHO(uint256 tokenId): Internal function to capture pending ECHO before state changes.
// 14. _forceDeactivateSentinel(uint256 tokenId): Internal function to forcibly deactivate a Sentinel (e.g., due to 0 integrity).
//
// III. Dynamic Sentinel Evolution & Quantum Resonance Engine (QRE):
// 15. evolveSentinelResonance(uint256 tokenId, uint256 boostAmount): Increases a Sentinel's ResonanceLevel.
// 16. degradeSentinelIntegrity(uint256 tokenId, uint256 decayAmount): Decreases a Sentinel's IntegrityScore (requires ORACLE_ROLE).
// 17. updateNetworkHealthMetric(uint256 newMetric): Oracle updates the global network activity metric (requires ORACLE_ROLE).
// 18. setAIInsightScore(address user, uint256 score): Oracle provides an AI-derived score for a user (requires ORACLE_ROLE).
// 19. triggerQREAdjustment(): Oracle triggers the QRE to dynamically adjust global synthesis and decay rates (requires ORACLE_ROLE).
// 20. getGlobalSynthesisRate(): Returns the current global rate at which Sentinels synthesize ECHO.
// 21. getGlobalDecayRate(): Returns the current global rate at which Sentinel IntegrityScore degrades.
// 22. _calculateQREAdjustments(uint256 currentHealth, uint256 aggregateAI): Internal QRE logic for rate adjustment.
//
// IV. Echo Portals (Conceptual Cross-Chain) & Advanced Interactions:
// 23. initiateEchoPortalLock(uint256 tokenId, uint256 duration): Locks a Sentinel's Resonance for a conceptual cross-chain transfer.
// 24. finalizeEchoPortalUnlock(uint256 tokenId): Unlocks a Sentinel after a conceptual cross-chain transfer completion.
// 25. submitValidatedAttestation(address user, uint256 attestationId, bytes32 attestationHash): Oracle submits a verifiable credential (requires ORACLE_ROLE).
// 26. getUserAttestations(address user): Retrieves a list of attestation data for a specific user.
//
// V. Role Management & Protocol Control:
// 27. grantRole(bytes32 role, address account): Grants a specific role to an address (requires DEFAULT_ADMIN_ROLE).
// 28. revokeRole(bytes32 role, address account): Revokes a specific role from an address (requires DEFAULT_ADMIN_ROLE).
// 29. pause(): Pauses all pausable contract operations (requires DEFAULT_ADMIN_ROLE).
// 30. unpause(): Unpauses all pausable contract operations (requires DEFAULT_ADMIN_ROLE).
// 31. setOracleAddress(address newOracle): Updates the address of the ORACLE_ROLE (requires DEFAULT_ADMIN_ROLE).

// --- ERC721 for Sentinels ---
contract QN_Sentinel is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Sentinel Attributes:
    // ResonanceLevel: Determines ECHO synthesis rate.
    // IntegrityScore: Resistance to decay, impacts longevity.
    // Note: All attribute values are treated as base units (e.g., 100 means 100 units).
    // The actual impact on token decimals (1e18) is handled in QuantumNexus contract.
    struct SentinelData {
        uint256 resonanceLevel;
        uint256 integrityScore;
        uint256 lastUpdateTimestamp; // For decay/evolution calculations and ECHO synthesis
        bool isActive;
        uint256 stakedEchoAmount;
        uint256 stakedStartTime;
        uint256 pendingSynthesizedECHO; // ECHO calculated but not yet claimed
        uint256 portalLockEndTime; // Timestamp when locked for conceptual cross-chain. 0 if not locked.
        address owner; // Stores current owner for quick lookup
    }

    mapping(uint256 => SentinelData) public sentinels;
    mapping(address => uint256[]) public ownerToSentinels; // Keep track of sentinels per owner for quick iteration

    // Roles specific to the Sentinel contract
    bytes32 public constant SENTINEL_MINDER_ROLE = keccak256("SENTINEL_MINDER_ROLE");

    constructor(address defaultAdmin) ERC721("Quantum Nexus Sentinel", "QNS") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        // Grant the initial admin the Sentinel Minder role as well for full control
        _grantRole(SENTINEL_MINDER_ROLE, defaultAdmin);
    }

    // Base URI for Sentinel metadata
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://QN_Sentinel_Metadata/"; // Placeholder URI
    }

    /**
     * @dev Mints a new Sentinel NFT.
     * Only callable by addresses with DEFAULT_ADMIN_ROLE or SENTINEL_MINDER_ROLE.
     * Initializes Sentinel with base attributes.
     */
    function mint(address to) public virtual returns (uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(SENTINEL_MINDER_ROLE, msg.sender), "QNS: Not allowed to mint");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        // Initialize Sentinel with base attributes
        sentinels[newTokenId] = SentinelData({
            resonanceLevel: 100,  // Starting resonance level
            integrityScore: 1000, // Starting integrity score
            lastUpdateTimestamp: block.timestamp,
            isActive: false,
            stakedEchoAmount: 0,
            stakedStartTime: 0,
            pendingSynthesizedECHO: 0,
            portalLockEndTime: 0,
            owner: to
        });

        ownerToSentinels[to].push(newTokenId); // Add to owner's list
        return newTokenId;
    }

    /**
     * @dev Burns a Sentinel NFT, updating internal mappings.
     * Internal function, exposed via `burn` in the main QuantumNexus contract for role control.
     */
    function _burn(uint256 tokenId) internal override {
        address currentOwner = ownerOf(tokenId);
        super._burn(tokenId);
        delete sentinels[tokenId];

        // Remove from ownerToSentinels list
        uint256[] storage ownerSentinels = ownerToSentinels[currentOwner];
        for (uint256 i = 0; i < ownerSentinels.length; i++) {
            if (ownerSentinels[i] == tokenId) {
                ownerSentinels[i] = ownerSentinels[ownerSentinels.length - 1]; // Swap with last element
                ownerSentinels.pop(); // Remove last element
                break;
            }
        }
    }

    /**
     * @dev Custom burn function callable by SENTINEL_MINDER_ROLE.
     * The main QuantumNexus contract will hold this role and implement specific burning logic.
     */
    function burn(uint256 tokenId) public virtual {
        require(hasRole(SENTINEL_MINDER_ROLE, msg.sender), "QNS: Only Sentinel Minder can call this burn");
        // Additional check for owner or approval for safety, though Sentinel Minder implies authority.
        require(_isApprovedOrOwner(msg.sender, tokenId), "QNS: Caller is not owner nor approved for Sentinel burning");
        _burn(tokenId);
    }

    /**
     * @dev Retrieves the full SentinelData struct for a given token ID.
     */
    function getSentinelData(uint256 tokenId) public view returns (SentinelData memory) {
        return sentinels[tokenId];
    }

    /**
     * @dev Overrides ERC721's _transfer to update internal owner mappings and SentinelData.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(sentinels[tokenId].owner == from, "QN_Sentinel: owner mismatch in internal data");
        super._transfer(from, to, tokenId);
        sentinels[tokenId].owner = to; // Update internal owner reference

        // Update ownerToSentinels mapping
        uint256[] storage fromSentinels = ownerToSentinels[from];
        for (uint256 i = 0; i < fromSentinels.length; i++) {
            if (fromSentinels[i] == tokenId) {
                fromSentinels[i] = fromSentinels[fromSentinels.length - 1];
                fromSentinels.pop();
                break;
            }
        }
        ownerToSentinels[to].push(tokenId);
    }
}

// --- ERC20 for ECHO Token ---
contract ECHO_Token is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address defaultAdmin) ERC20("Echo Token", "ECHO") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(BURNER_ROLE, defaultAdmin);
    }

    /**
     * @dev Mints ECHO tokens to a specified address.
     * Only callable by addresses with MINTER_ROLE.
     */
    function mint(address to, uint256 amount) public virtual onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Burns ECHO tokens from a specified address.
     * Only callable by addresses with BURNER_ROLE.
     */
    function burn(address from, uint256 amount) public virtual onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}

// --- Main Quantum Nexus Contract ---
contract QuantumNexus is Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using Strings for uint256;

    QN_Sentinel public qnSentinel; // Instance of the Sentinel NFT contract
    ECHO_Token public echoToken;   // Instance of the ECHO utility token contract

    // Roles for QuantumNexus specific operations
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // Quantum Resonance Engine (QRE) parameters
    // globalSynthesisRate: Amount of ECHO (scaled by 1e18) synthesized per ResonanceLevel per second.
    // Example: If rate is 10, a Sentinel with Resonance 100 generates 100 * 10 * 1e18 ECHO per second.
    uint256 public globalSynthesisRate;
    // globalDecayRate: Amount of IntegrityScore lost per second per active Sentinel.
    // Example: If rate is 1, a Sentinel loses 1 IntegrityScore per second.
    uint256 public globalDecayRate;
    uint256 public lastQREAdjustmentTime; // Timestamp of the last QRE adjustment
    uint256 public qreAdjustmentInterval = 1 days; // Frequency of QRE recalculations (e.g., every 24 hours)

    // Network Health and AI Insights
    uint256 public networkHealthMetric; // Aggregated on-chain activity, updated by ORACLE_ROLE
    mapping(address => uint256) public userAIInsightScore; // AI-derived score for user reputation, updated by ORACLE_ROLE

    // Attestation System (conceptual for Verifiable Credentials/Reputation)
    struct Attestation {
        uint256 id;
        bytes32 attestationHash; // Hash of off-chain verified data or ZK proof
        uint256 timestamp;
    }
    mapping(address => Attestation[]) public userAttestations; // Stores attestations for each user
    Counters.Counter private _attestationIdCounter; // Counter for unique attestation IDs

    // Events to log important actions and state changes
    event SentinelMinted(uint256 indexed tokenId, address indexed owner);
    event SentinelBurned(uint256 indexed tokenId, address indexed owner);
    event ECHOStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ECHOUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ECHOClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount);
    event SentinelResonanceEvolved(uint256 indexed tokenId, uint256 oldResonance, uint256 newResonance, uint256 boostAmount);
    event SentinelIntegrityDegraded(uint256 indexed tokenId, uint256 oldIntegrity, uint256 newIntegrity, uint256 decayAmount);
    event NetworkHealthUpdated(uint256 newMetric, uint256 timestamp);
    event AIInsightScoreUpdated(address indexed user, uint256 score, uint256 timestamp);
    event QREAdjusted(uint256 oldSynthesisRate, uint256 newSynthesisRate, uint256 oldDecayRate, uint256 newDecayRate, uint256 timestamp);
    event EchoPortalLockInitiated(uint256 indexed tokenId, address indexed owner, uint256 duration);
    event EchoPortalUnlockFinalized(uint256 indexed tokenId, address indexed owner);
    event AttestationSubmitted(address indexed user, uint256 indexed attestationId, bytes32 attestationHash);

    // Modifier to restrict calls to the owner of a specific Sentinel
    modifier onlySentinelOwner(uint256 tokenId) {
        require(qnSentinel.ownerOf(tokenId) == msg.sender, "QN: Not owner of Sentinel");
        _;
    }

    /**
     * @dev Constructor to deploy and initialize the Quantum Nexus system.
     * Deploys child ERC721 (QN_Sentinel) and ERC20 (ECHO_Token) contracts.
     * Sets up initial roles and QRE parameters.
     * @param _initialAdmin The address to be granted DEFAULT_ADMIN_ROLE and ORACLE_ROLE.
     */
    constructor(address _initialAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(ORACLE_ROLE, _initialAdmin); // Initial admin also serves as oracle

        qnSentinel = new QN_Sentinel(_initialAdmin); // Deploy QN_Sentinel contract
        echoToken = new ECHO_Token(_initialAdmin);   // Deploy ECHO_Token contract

        // Grant Nexus contract necessary roles on child contracts
        // Nexus needs to mint/burn Sentinels (e.g., for system events)
        qnSentinel.grantRole(qnSentinel.SENTINEL_MINDER_ROLE(), address(this));
        // Nexus needs to mint ECHO (for synthesis) and burn ECHO (for penalties/fees)
        echoToken.grantRole(echoToken.MINTER_ROLE(), address(this));
        echoToken.grantRole(echoToken.BURNER_ROLE(), address(this));

        // Initial QRE parameters: Rates are considered as base units.
        // For example, 10 units * 1e18 for ECHO synthesis, 1 unit for integrity decay.
        globalSynthesisRate = 10; // Default: 10 ECHO units per ResonanceLevel per second
        globalDecayRate = 1;      // Default: 1 IntegrityScore loss per second
        lastQREAdjustmentTime = block.timestamp;
    }

    // --- I. Core Infrastructure & Token Management ---

    // 1. constructor: (Handled above)

    /**
     * @dev 2. mintSentinel: Mints a new Sentinel NFT to a specified address.
     * Requires DEFAULT_ADMIN_ROLE. Pausable.
     * @param to The recipient address for the new Sentinel.
     * @return The tokenId of the newly minted Sentinel.
     */
    function mintSentinel(address to) public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused returns (uint256) {
        uint256 tokenId = qnSentinel.mint(to);
        emit SentinelMinted(tokenId, to);
        return tokenId;
    }

    /**
     * @dev 3. burnSentinel: Burns a Sentinel NFT.
     * Requires DEFAULT_ADMIN_ROLE. Pausable.
     * Sentinel must not be active (staked) or locked in a portal.
     * @param tokenId The ID of the Sentinel to burn.
     */
    function burnSentinel(uint256 tokenId) public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        address owner = qnSentinel.ownerOf(tokenId);
        QN_Sentinel.SentinelData memory sentinelData = qnSentinel.getSentinelData(tokenId);
        require(!sentinelData.isActive, "QN: Cannot burn an active (staked) Sentinel");
        require(sentinelData.portalLockEndTime < block.timestamp, "QN: Cannot burn a Sentinel locked in an Echo Portal");

        qnSentinel.burn(tokenId); // Delegate to QN_Sentinel's burn function
        emit SentinelBurned(tokenId, owner);
    }

    /**
     * @dev 4. getSentinelAttributes: Retrieves dynamic attributes of a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return resonanceLevel Current ResonanceLevel.
     * @return integrityScore Current IntegrityScore.
     * @return isActive True if the Sentinel is currently active (staked).
     * @return stakedAmount The amount of ECHO staked for this Sentinel.
     * @return portalLockEndTime Timestamp until which the Sentinel is locked in a portal.
     */
    function getSentinelAttributes(uint256 tokenId) public view returns (uint256 resonanceLevel, uint256 integrityScore, bool isActive, uint256 stakedAmount, uint256 portalLockEndTime) {
        QN_Sentinel.SentinelData memory data = qnSentinel.getSentinelData(tokenId);
        return (data.resonanceLevel, data.integrityScore, data.isActive, data.stakedEchoAmount, data.portalLockEndTime);
    }

    /**
     * @dev 5. setSentinelURI: Sets the metadata URI for a Sentinel.
     * Only callable by the Sentinel's owner. Pausable.
     * @param tokenId The ID of the Sentinel.
     * @param _tokenURI The new URI for the metadata.
     */
    function setSentinelURI(uint256 tokenId, string memory _tokenURI) public onlySentinelOwner(tokenId) whenNotPaused {
        qnSentinel.setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev 6. ECHO_initialMint: Admin-only initial minting for ECHO tokens.
     * This is for initial distribution, not for ongoing synthesis.
     * Requires DEFAULT_ADMIN_ROLE. Pausable.
     * @param to The recipient address.
     * @param amount The amount of ECHO to mint (in base units, e.g., 1 ECHO = 1e18).
     */
    function ECHO_initialMint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        echoToken.mint(to, amount);
    }

    /**
     * @dev 7. ECHO_burn: Admin-only burning of ECHO tokens from a specific address.
     * Requires DEFAULT_ADMIN_ROLE. Pausable.
     * @param from The address from which to burn tokens.
     * @param amount The amount of ECHO to burn.
     */
    function ECHO_burn(address from, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        echoToken.burn(from, amount);
    }

    /**
     * @dev 8. ECHO_transfer: Proxies the standard ERC20 transfer for ECHO tokens.
     * Adheres to the contract's pausable state.
     * @param recipient The recipient of the transfer.
     * @param amount The amount of ECHO to transfer.
     * @return True if the transfer was successful.
     */
    function ECHO_transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        return echoToken.transfer(recipient, amount);
    }

    // --- II. Sentinel Activation & Rewards ---

    /**
     * @dev 9. stakeECHOForSentinel: Stakes ECHO for a specific Sentinel, activating it.
     * The staked amount enhances the Sentinel's status, potentially influencing future attributes (not directly implemented here, but for expandability).
     * Requires the Sentinel's owner. Pausable. Non-reentrant.
     * @param tokenId The ID of the Sentinel to stake for.
     * @param amount The amount of ECHO to stake.
     */
    function stakeECHOForSentinel(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused onlySentinelOwner(tokenId) {
        require(amount > 0, "QN: Stake amount must be greater than zero");
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
        require(!sentinel.isActive, "QN: Sentinel is already active; unstake first to change stake");

        // Transfer ECHO from user to this contract
        echoToken.transferFrom(msg.sender, address(this), amount);

        // Update Sentinel state
        sentinel.isActive = true;
        sentinel.stakedEchoAmount = amount;
        sentinel.stakedStartTime = block.timestamp;
        sentinel.lastUpdateTimestamp = block.timestamp; // Reset for synthesis/decay calculations
        sentinel.pendingSynthesizedECHO = 0; // Clear any old pending if somehow existed

        emit ECHOStaked(tokenId, msg.sender, amount);
    }

    /**
     * @dev 10. unstakeECHOFromSentinel: Unstakes ECHO, deactivating a Sentinel.
     * Transfers back the original staked amount and any pending synthesized ECHO.
     * Requires the Sentinel's owner. Pausable. Non-reentrant.
     * @param tokenId The ID of the Sentinel to unstake.
     */
    function unstakeECHOFromSentinel(uint256 tokenId) public nonReentrant whenNotPaused onlySentinelOwner(tokenId) {
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
        require(sentinel.isActive, "QN: Sentinel is not active");
        require(sentinel.portalLockEndTime < block.timestamp, "QN: Cannot unstake while Sentinel is portal-locked");

        uint256 stakedAmount = sentinel.stakedEchoAmount;
        uint256 pending = _calculateAndStorePendingECHO(tokenId); // Calculate any remaining pending ECHO

        // Reset Sentinel state
        sentinel.isActive = false;
        sentinel.stakedEchoAmount = 0;
        sentinel.stakedStartTime = 0;
        sentinel.pendingSynthesizedECHO = 0; // Claimed now

        // Transfer staked ECHO back to user
        if (stakedAmount > 0) {
            echoToken.transfer(msg.sender, stakedAmount);
        }
        // Mint and transfer synthesized ECHO to user
        if (pending > 0) {
            echoToken.mint(msg.sender, pending);
        }

        emit ECHOUnstaked(tokenId, msg.sender, stakedAmount);
        if (pending > 0) {
            emit ECHOClaimed(tokenId, msg.sender, pending);
        }
    }

    /**
     * @dev 11. claimSynthesizedECHO: Allows users to claim accumulated ECHO from multiple active Sentinels.
     * Requires the Sentinels' owner. Pausable. Non-reentrant.
     * @param tokenIds An array of Sentinel IDs from which to claim ECHO.
     */
    function claimSynthesizedECHO(uint256[] memory tokenIds) public nonReentrant whenNotPaused {
        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(qnSentinel.ownerOf(tokenId) == msg.sender, "QN: Not owner of Sentinel");

            QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
            require(sentinel.isActive, "QN: Sentinel not active for claiming");

            uint256 pending = _calculateAndStorePendingECHO(tokenId);
            if (pending > 0) {
                echoToken.mint(msg.sender, pending);
                totalClaimed = totalClaimed.add(pending);
                sentinel.pendingSynthesizedECHO = 0; // Reset after claim
                emit ECHOClaimed(tokenId, msg.sender, pending);
            }
        }
        require(totalClaimed > 0, "QN: No ECHO to claim from specified Sentinels or they are not active");
    }

    /**
     * @dev 12. getPendingSynthesizedECHO: Calculates the amount of ECHO pending for a specific Sentinel.
     * This is a view function that calculates real-time pending ECHO without altering state.
     * @param tokenId The ID of the Sentinel.
     * @return The total amount of ECHO pending for the Sentinel (including accumulated and newly synthesized).
     */
    function getPendingSynthesizedECHO(uint256 tokenId) public view returns (uint256) {
        QN_Sentinel.SentinelData memory sentinel = qnSentinel.sentinels[tokenId];
        if (!sentinel.isActive || sentinel.resonanceLevel == 0) {
            return sentinel.pendingSynthesizedECHO;
        }

        uint256 elapsed = block.timestamp.sub(sentinel.lastUpdateTimestamp);
        if (elapsed == 0) {
            return sentinel.pendingSynthesizedECHO;
        }
        // Calculate newly synthesized ECHO: ResonanceLevel * globalSynthesisRate * elapsed
        // globalSynthesisRate is scaled by 1e18 internally for ECHO token decimals.
        uint256 newlySynthesized = sentinel.resonanceLevel.mul(globalSynthesisRate).mul(elapsed);
        return sentinel.pendingSynthesizedECHO.add(newlySynthesized);
    }

    /**
     * @dev 13. _calculateAndStorePendingECHO: Internal helper to capture accumulated yield.
     * This function is crucial to be called before any state change that might
     * affect `lastUpdateTimestamp` or `isActive` status (e.g., evolution, unstaking).
     * It ensures pending ECHO is accurately recorded up to the current block.
     * @param tokenId The ID of the Sentinel.
     * @return The amount of ECHO newly calculated and added to pending.
     */
    function _calculateAndStorePendingECHO(uint256 tokenId) internal returns (uint256) {
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
        if (!sentinel.isActive || sentinel.resonanceLevel == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp.sub(sentinel.lastUpdateTimestamp);
        if (elapsed == 0) {
            return 0;
        }

        uint256 newlySynthesized = sentinel.resonanceLevel.mul(globalSynthesisRate).mul(elapsed);

        sentinel.pendingSynthesizedECHO = sentinel.pendingSynthesizedECHO.add(newlySynthesized);
        sentinel.lastUpdateTimestamp = block.timestamp; // Update timestamp after calculation
        return newlySynthesized;
    }

    /**
     * @dev 14. _forceDeactivateSentinel: Internal function to forcibly deactivate a Sentinel.
     * Used when integrity reaches zero. Staked ECHO is returned, but pending yield is burned.
     * @param tokenId The ID of the Sentinel to deactivate.
     */
    function _forceDeactivateSentinel(uint256 tokenId) internal {
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
        if (!sentinel.isActive) return;

        uint256 stakedAmount = sentinel.stakedEchoAmount;
        // Pending ECHO is not transferred; it's effectively burned as a penalty for full decay.

        // Reset Sentinel state
        sentinel.isActive = false;
        sentinel.stakedEchoAmount = 0;
        sentinel.stakedStartTime = 0;
        sentinel.pendingSynthesizedECHO = 0; // Burned

        // Transfer staked ECHO back to owner
        if (stakedAmount > 0) {
            echoToken.transfer(qnSentinel.ownerOf(tokenId), stakedAmount);
        }

        emit ECHOUnstaked(tokenId, qnSentinel.ownerOf(tokenId), stakedAmount);
        // No ECHOClaimed event for pending, as it's burned.
    }

    // --- III. Dynamic Sentinel Evolution & Quantum Resonance Engine (QRE) ---

    /**
     * @dev 15. evolveSentinelResonance: Increases a Sentinel's ResonanceLevel.
     * Requires the Sentinel's owner. Pausable.
     * Ensures pending ECHO is calculated before the change to avoid losing yield.
     * @param tokenId The ID of the Sentinel to evolve.
     * @param boostAmount The amount by which to increase the ResonanceLevel.
     */
    function evolveSentinelResonance(uint256 tokenId, uint256 boostAmount) public whenNotPaused onlySentinelOwner(tokenId) {
        require(boostAmount > 0, "QN: Boost amount must be positive");
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];

        _calculateAndStorePendingECHO(tokenId); // Capture any pending ECHO before attribute change
        uint256 oldResonance = sentinel.resonanceLevel;
        sentinel.resonanceLevel = sentinel.resonanceLevel.add(boostAmount);
        emit SentinelResonanceEvolved(tokenId, oldResonance, sentinel.resonanceLevel, boostAmount);
    }

    /**
     * @dev 16. degradeSentinelIntegrity: Decreases a Sentinel's IntegrityScore.
     * Typically called by the ORACLE_ROLE as part of the QRE decay mechanism. Pausable.
     * If IntegrityScore drops to zero, the Sentinel is forcibly deactivated.
     * @param tokenId The ID of the Sentinel to degrade.
     * @param decayAmount The amount by which to decrease the IntegrityScore.
     */
    function degradeSentinelIntegrity(uint256 tokenId, uint256 decayAmount) public whenNotPaused onlyRole(ORACLE_ROLE) {
        require(decayAmount > 0, "QN: Decay amount must be positive");
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];

        _calculateAndStorePendingECHO(tokenId); // Capture any pending ECHO before attribute change
        uint256 oldIntegrity = sentinel.integrityScore;

        if (sentinel.integrityScore > decayAmount) {
            sentinel.integrityScore = sentinel.integrityScore.sub(decayAmount);
        } else {
            sentinel.integrityScore = 0; // Sentinel completely degraded
            if (sentinel.isActive) {
                _forceDeactivateSentinel(tokenId); // Forcibly deactivate if integrity reaches zero
            }
        }
        emit SentinelIntegrityDegraded(tokenId, oldIntegrity, sentinel.integrityScore, decayAmount);
    }

    /**
     * @dev 17. updateNetworkHealthMetric: Updates the global network activity metric.
     * Callable by `ORACLE_ROLE`. Pausable.
     * This metric is a key input for the QRE's adaptive adjustments.
     * @param newMetric The new value for the network health metric.
     */
    function updateNetworkHealthMetric(uint256 newMetric) public onlyRole(ORACLE_ROLE) whenNotPaused {
        networkHealthMetric = newMetric;
        emit NetworkHealthUpdated(newMetric, block.timestamp);
    }

    /**
     * @dev 18. setAIInsightScore: Oracle provides an AI-derived score for a user.
     * This score reflects off-chain reputation or contribution, influencing QRE and Sentinel evolution.
     * Callable by `ORACLE_ROLE`. Pausable.
     * @param user The address of the user whose AI insight score is being set.
     * @param score The new AI insight score for the user.
     */
    function setAIInsightScore(address user, uint256 score) public onlyRole(ORACLE_ROLE) whenNotPaused {
        userAIInsightScore[user] = score;
        emit AIInsightScoreUpdated(user, score, block.timestamp);
    }

    /**
     * @dev 19. triggerQREAdjustment: Triggers the Quantum Resonance Engine to recalculate and adjust global rates.
     * Callable by `ORACLE_ROLE`. Pausable.
     * Can only be called after `qreAdjustmentInterval` has passed since the last adjustment.
     */
    function triggerQREAdjustment() public onlyRole(ORACLE_ROLE) whenNotPaused {
        require(block.timestamp >= lastQREAdjustmentTime.add(qreAdjustmentInterval), "QN: QRE adjustment too frequent");

        uint256 oldSynthesisRate = globalSynthesisRate;
        uint256 oldDecayRate = globalDecayRate;

        // In a more complex system, _getAggregateAIInsightScore could iterate through users.
        // For simplicity, it might be an oracle-provided aggregate or a fixed value in demo.
        uint256 aggregateAI = _getAggregateAIInsightScore();
        (globalSynthesisRate, globalDecayRate) = _calculateQREAdjustments(networkHealthMetric, aggregateAI);

        lastQREAdjustmentTime = block.timestamp;
        emit QREAdjusted(oldSynthesisRate, globalSynthesisRate, oldDecayRate, globalDecayRate, block.timestamp);
    }

    /**
     * @dev _getAggregateAIInsightScore: Internal helper for aggregating AI scores.
     * In a full system, this would gather data from `userAIInsightScore` mapping
     * or be provided directly as an aggregated value by the oracle.
     * @return A simplified aggregate AI insight score.
     */
    function _getAggregateAIInsightScore() internal view returns (uint256) {
        // For demonstration, let's return a simple placeholder value.
        // A real system would implement logic to sum/average/weight scores from active users.
        // Or the ORACLE_ROLE could pass this aggregate directly.
        return 500; // Placeholder aggregate AI score
    }

    /**
     * @dev 20. getGlobalSynthesisRate: Returns the current global rate at which Sentinels synthesize ECHO.
     * @return The current global synthesis rate.
     */
    function getGlobalSynthesisRate() public view returns (uint256) {
        return globalSynthesisRate;
    }

    /**
     * @dev 21. getGlobalDecayRate: Returns the current global rate at which Sentinel IntegrityScore degrades.
     * @return The current global decay rate.
     */
    function getGlobalDecayRate() public view returns (uint256) {
        return globalDecayRate;
    }

    /**
     * @dev 22. _calculateQREAdjustments: Internal pure function containing the adaptive logic.
     * This is the core of the dynamic tokenomics, adjusting rates based on input metrics.
     * This example uses simple linear adjustments for demonstration.
     * @param currentHealth The current `networkHealthMetric`.
     * @param aggregateAI An aggregated AI insight score.
     * @return newSynthesisRate The calculated new global ECHO synthesis rate.
     * @return newDecayRate The calculated new global Sentinel integrity decay rate.
     */
    function _calculateQREAdjustments(uint256 currentHealth, uint256 aggregateAI) internal pure returns (uint256 newSynthesisRate, uint256 newDecayRate) {
        // --- Tuning Constants (can be made configurable by governance) ---
        uint256 baseSynthesis = 10; // Baseline ECHO per Resonance per sec (scaled by 1e18)
        uint256 baseDecay = 1;      // Baseline Integrity loss per sec
        uint256 healthMultiplier = 5; // How much health affects rates
        uint256 aiMultiplier = 3;     // How much AI score affects rates
        uint256 maxSynthesis = 1000;
        uint256 minSynthesis = 1;
        uint256 maxDecay = 100;
        uint256 minDecay = 1;

        // --- Synthesis Rate Adjustment ---
        // Higher network health and AI score should increase synthesis.
        uint256 healthImpact = currentHealth.div(healthMultiplier);
        uint256 aiImpact = aggregateAI.div(aiMultiplier);

        newSynthesisRate = baseSynthesis.add(healthImpact).add(aiImpact);
        // Apply bounds
        if (newSynthesisRate > maxSynthesis) newSynthesisRate = maxSynthesis;
        if (newSynthesisRate < minSynthesis) newSynthesisRate = minSynthesis;

        // --- Decay Rate Adjustment ---
        // Higher network health and AI score should decrease decay.
        // Decay rate is inversely related to positive network metrics.
        newDecayRate = baseDecay;
        if (healthImpact > 0) newDecayRate = newDecayRate.sub(healthImpact.div(2)); // Health reduces decay
        if (aiImpact > 0) newDecayRate = newDecayRate.sub(aiImpact.div(4));     // AI reduces decay further

        // Apply bounds
        if (newDecayRate > maxDecay) newDecayRate = maxDecay;
        if (newDecayRate < minDecay) newDecayRate = minDecay;

        return (newSynthesisRate, newDecayRate);
    }

    // --- IV. Echo Portals (Conceptual Cross-Chain) & Advanced Interactions ---

    /**
     * @dev 23. initiateEchoPortalLock: Locks a Sentinel's Resonance for a conceptual cross-chain transfer.
     * This simulates a commitment to future cross-chain activity.
     * Requires the Sentinel's owner. Pausable.
     * Requires the Sentinel to be inactive (unstaked).
     * @param tokenId The ID of the Sentinel to lock.
     * @param duration The duration (in seconds) for which the Sentinel's portal will be locked.
     */
    function initiateEchoPortalLock(uint256 tokenId, uint256 duration) public whenNotPaused onlySentinelOwner(tokenId) {
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
        require(duration > 0, "QN: Lock duration must be positive");
        require(sentinel.portalLockEndTime < block.timestamp, "QN: Sentinel is already locked in a portal");
        require(!sentinel.isActive, "QN: Sentinel must be inactive (unstaked) to initiate portal lock");

        sentinel.portalLockEndTime = block.timestamp.add(duration);
        emit EchoPortalLockInitiated(tokenId, msg.sender, duration);
    }

    /**
     * @dev 24. finalizeEchoPortalUnlock: Unlocks a Sentinel after a conceptual cross-chain transfer completion.
     * Provides a small `ResonanceLevel` boost as a reward for successful "cross-chain" participation.
     * Requires the Sentinel's owner. Pausable.
     * @param tokenId The ID of the Sentinel to unlock.
     */
    function finalizeEchoPortalUnlock(uint256 tokenId) public whenNotPaused onlySentinelOwner(tokenId) {
        QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[tokenId];
        require(sentinel.portalLockEndTime >= block.timestamp, "QN: Sentinel was not locked or lock has expired");

        sentinel.portalLockEndTime = 0; // Unlock the Sentinel
        // Grant a small resonance boost for completing the portal interaction
        evolveSentinelResonance(tokenId, 50); // Boost by 50 Resonance units
        emit EchoPortalUnlockFinalized(tokenId, msg.sender);
    }

    /**
     * @dev 25. submitValidatedAttestation: Oracle submits a verifiable credential (attestation) about a user.
     * This allows off-chain reputation or achievements to impact on-chain assets.
     * Also provides a small `ResonanceLevel` boost to the user's active Sentinels.
     * Callable by `ORACLE_ROLE`. Pausable.
     * @param user The address of the user the attestation is for.
     * @param attestationId A unique ID for the attestation.
     * @param attestationHash A hash representing the verified off-chain data/proof.
     */
    function submitValidatedAttestation(address user, uint256 attestationId, bytes32 attestationHash) public onlyRole(ORACLE_ROLE) whenNotPaused {
        _attestationIdCounter.increment();
        Attestation memory newAttestation = Attestation({
            id: _attestationIdCounter.current(),
            attestationHash: attestationHash,
            timestamp: block.timestamp
        });
        userAttestations[user].push(newAttestation);

        // If the user has active Sentinels, provide a small Resonance boost
        uint256[] memory usersSentinels = qnSentinel.ownerToSentinels[user];
        for(uint256 i = 0; i < usersSentinels.length; i++) {
            QN_Sentinel.SentinelData storage sentinel = qnSentinel.sentinels[usersSentinels[i]];
            if (sentinel.isActive) {
                _calculateAndStorePendingECHO(usersSentinels[i]); // Update pending ECHO before boosting
                uint256 oldResonance = sentinel.resonanceLevel;
                sentinel.resonanceLevel = sentinel.resonanceLevel.add(10); // Small boost of 10 Resonance units
                emit SentinelResonanceEvolved(usersSentinels[i], oldResonance, sentinel.resonanceLevel, 10);
            }
        }
        emit AttestationSubmitted(user, newAttestation.id, attestationHash);
    }

    /**
     * @dev 26. getUserAttestations: Retrieves a list of attestation data for a specific user.
     * @param user The address of the user.
     * @return An array of `Attestation` structs associated with the user.
     */
    function getUserAttestations(address user) public view returns (Attestation[] memory) {
        return userAttestations[user];
    }

    // --- V. Role Management & Protocol Control ---

    /**
     * @dev 27. grantRole: Grants a specific role to an address.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param role The keccak256 hash of the role name.
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev 28. revokeRole: Revokes a specific role from an address.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param role The keccak256 hash of the role name.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev 29. pause: Pauses all pausable contract operations.
     * Requires DEFAULT_ADMIN_ROLE.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev 30. unpause: Unpauses the contract.
     * Requires DEFAULT_ADMIN_ROLE.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev 31. setOracleAddress: Updates the address for the ORACLE_ROLE.
     * This function revokes the ORACLE_ROLE from the current holder and grants it to the new address.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param newOracle The new address to be designated as the Oracle.
     */
    function setOracleAddress(address newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Revoke role from the old oracle(s) if applicable, for simplicity assuming only one oracle role holder.
        // A more robust system might iterate through current oracle holders if multiple are allowed.
        // For this example, we'll just grant the new role and assume the old one will be manually revoked if needed.
        // A better pattern: (1) renounceRole by old oracle, (2) grantRole by admin to new.
        // Or, for admin control:
        address currentOracle = getRoleMember(ORACLE_ROLE, 0); // Assuming one oracle for simplicity
        if (currentOracle != address(0)) {
            _revokeRole(ORACLE_ROLE, currentOracle);
        }
        _grantRole(ORACLE_ROLE, newOracle);
    }
}
```