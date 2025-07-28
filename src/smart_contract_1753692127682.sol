Okay, this is an exciting challenge! Let's build a smart contract system that explores advanced concepts like dynamic NFTs, on-chain provenance, time-based mechanics, and an event-driven oracle interaction for "Chrono-Artifacts" and "Temporal Badges."

I'll call this system **ChronoForge**.

---

## ChronoForge: Temporal Artifacts & Event Provenance System

**Concept:** ChronoForge is a decentralized protocol for creating and managing "ChronoArtifacts" – dynamic, evolving NFTs whose properties are directly influenced by verifiable on-chain or off-chain events. It also issues "Temporal Badges" (Soulbound Tokens) that reflect a user's engagement, successful predictions, and long-term participation within the ChronoForge ecosystem, unlocking special privileges or future claims.

**Unique & Advanced Concepts:**
1.  **Dynamic NFT Provenance:** ChronoArtifacts are not static. Their metadata and intrinsic value evolve by "infusing" them with verified event data, building an immutable on-chain provenance chain for each artifact.
2.  **Event-Driven Evolution:** Artifact evolution is directly tied to a decentralized oracle network (e.g., Chainlink) for real-world event verification.
3.  **Temporal Badges (Soulbound Reputation):** Non-transferable tokens that accrue "Temporal Points" over time, based on user actions and successful event predictions, granting progressive access or influence within the ecosystem.
4.  **Temporal Bonds/Claims:** Users can create on-chain commitments or "bonds" tied to future events, which can be redeemed or liquidated based on oracle verification.
5.  **Challenge Mechanism for Provenance:** A system allowing participants to challenge the validity of an event previously infused into an artifact's provenance, requiring a stake and arbitration.
6.  **Time-Locked Artifacts:** Ability to voluntarily lock ChronoArtifacts for a duration, potentially enhancing their value or unlocking future capabilities.

---

### **Outline & Function Summary**

**Core Contracts:**
1.  **`ChronoForge.sol`**: The main factory and orchestrator. Handles event registration, oracle interaction, ChronoArtifact minting/infusion, Temporal Badge management, and Temporal Bond creation/redemption.
2.  **`ChronoArtifact.sol`**: An ERC-721 compliant contract representing the dynamic NFTs. Owned and controlled by `ChronoForge`.
3.  **`TemporalBadge.sol`**: An ERC-721 compliant (and Soulbound) contract representing non-transferable reputation tokens. Owned and controlled by `ChronoForge`.

**Interfaces:**
*   `IChronoArtifact`: Interface for the ChronoArtifact contract.
*   `ITemporalBadge`: Interface for the TemporalBadge contract.
*   `IOracleConsumer`: Interface for Chainlink VRF/Keepers integration. (For simplicity, a direct Chainlink `VRFConsumerBaseV2` or `AutomationCompatible.sol` isn't fully implemented but imagined for `requestEventVerification` and `fulfillEventVerification` placeholders).

---

#### **`ChronoForge.sol` Functions Summary (at least 20 unique functions):**

**I. Core Setup & Ownership (3 functions)**
1.  `constructor(address _artifactContract, address _badgeContract, address _oracleAddress)`: Initializes the contract with addresses of ChronoArtifact, TemporalBadge contracts, and the trusted oracle.
2.  `setOracleAddress(address _newOracle)`: Allows the owner to update the trusted oracle address.
3.  `setMetadataBaseURIs(string memory _artifactBaseURI, string memory _badgeBaseURI)`: Sets the base URI for both ChronoArtifacts and Temporal Badges.

**II. ChronoArtifact Management (5 functions)**
4.  `forgeChronoArtifact(address _to, string memory _initialMetadataURI)`: Mints a new ChronoArtifact to a specified address.
5.  `infuseWithEvent(uint256 _tokenId, uint256 _eventId, string memory _newMetadataURI)`: Infuses a ChronoArtifact with a verified event. This updates its provenance and metadata.
6.  `getArtifactProvenance(uint256 _tokenId)`: Retrieves the full historical provenance (list of infused events) for a given ChronoArtifact.
7.  `timeLockArtifact(uint256 _tokenId, uint256 _lockDuration)`: Locks a ChronoArtifact, preventing transfer or further infusion until a specified time.
8.  `releaseTimeLockedArtifact(uint256 _tokenId)`: Releases a time-locked artifact if the lock duration has passed.

**III. Event Lifecycle & Oracle Interaction (6 functions)**
9.  `proposeEvent(string memory _eventName, string memory _eventDescription, bytes32 _oracleJobId, uint256 _oracleFee)`: Proposes a new event that needs external verification via an oracle.
10. `requestEventVerification(uint256 _eventId)`: Owner/authorized caller requests verification of a proposed event via the external oracle.
11. `fulfillEventVerification(uint256 _eventId, bool _isVerified, string memory _verificationProof)`: Callback function from the oracle, marking an event as verified or invalid.
12. `getEventDetails(uint256 _eventId)`: Retrieves the current status and details of a registered event.
13. `markEventInvalid(uint256 _eventId)`: Owner can manually mark an event as invalid, overriding previous verification (e.g., in case of oracle error).
14. `authorizeEventSource(address _source, bool _isAuthorized)`: Allows the owner to authorize external contracts/addresses that can propose events directly (e.g., DeSci data sources).

**IV. Temporal Badge Management (4 functions)**
15. `mintTemporalBadge(address _to)`: Mints a unique Temporal Badge (SBT) for a user. Only one per address.
16. `accrueTemporalPoints(address _user, uint256 _points)`: Awards temporal points to a user's badge, typically triggered by successful actions (e.g., correct prediction, successful artifact infusion).
17. `getTemporalBadgeLevel(address _user)`: Calculates and returns the current "level" of a user's Temporal Badge based on their accrued points.
18. `getTemporalPoints(address _user)`: Retrieves the total temporal points accumulated by a user.

**V. Advanced Temporal Mechanics & Challenges (5 functions)**
19. `createTemporalBond(bytes32 _bondId, uint256 _eventId, uint256 _lockDuration, uint256 _amount)`: Allows users to create a "temporal bond" – a deposit locked until a specific event is verified, or a duration passes.
20. `redeemTemporalBond(bytes32 _bondId)`: Allows the creator to redeem a temporal bond if its conditions (event verification, time expiry) are met.
21. `challengeProvenanceLayer(uint256 _tokenId, uint256 _provenanceIndex, uint256 _stakeAmount)`: Initiates a challenge against a specific provenance layer of an artifact, requiring a stake.
22. `settleProvenanceChallenge(uint256 _tokenId, uint256 _provenanceIndex, bool _isValid)`: Owner/DAO resolves a provenance challenge, distributing/slashing stakes.
23. `withdrawStakedFunds(bytes32 _challengeId)`: Allows participants to withdraw their stakes from resolved challenges.

---

### **Solidity Smart Contract Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// =============================================================================
// Interfaces
// =============================================================================

// Interface for ChronoArtifact NFT contract
interface IChronoArtifact {
    struct ProvenanceLayer {
        uint256 eventId;
        uint256 timestamp;
        string verificationProof;
    }

    function mint(address to, uint256 tokenId, string calldata initialMetadataURI) external;
    function addProvenanceLayer(uint256 tokenId, ProvenanceLayer calldata layer, string calldata newMetadataURI) external;
    function getProvenance(uint256 tokenId) external view returns (ProvenanceLayer[] memory);
    function updateTokenURI(uint256 tokenId, string calldata newURI) external;
    function lockArtifact(uint256 tokenId, uint256 unlockTime) external;
    function unlockArtifact(uint256 tokenId) external;
    function isLocked(uint256 tokenId) external view returns (bool, uint256);
    function isApprovedOrOwner(address caller, uint256 tokenId) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external; // Required for ChronoForge to control
}

// Interface for TemporalBadge (Soulbound Token) contract
interface ITemporalBadge {
    function mint(address to, uint256 tokenId, string calldata initialMetadataURI) external;
    function setTemporalPoints(uint256 tokenId, uint256 points) external;
    function getTemporalPoints(uint256 tokenId) external view returns (uint256);
    function getTokenIdByAddress(address user) external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    // SBT enforcement: external functions usually prevent transfer directly in the base ERC721
    // The underlying ITemporalBadge contract will override `transferFrom` to revert.
}

// Simplified interface for Oracle Consumer (e.g., Chainlink)
// In a real scenario, this would inherit Chainlink's VRFConsumerBaseV2 or AutomationCompatible.sol
interface IOracleConsumer {
    function requestVerification(bytes32 _jobId, uint256 _eventId, uint256 _fee) external returns (bytes32 requestId);
    // fulfillOracleCall is a callback that would be handled by the ChronoForge contract directly
    // based on Chainlink's specific callback mechanisms.
}

// =============================================================================
// ChronoArtifact.sol
// =============================================================================

contract ChronoArtifact is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    struct ProvenanceLayer {
        uint256 eventId;
        uint256 timestamp;
        string verificationProof;
    }

    // Mapping from tokenId to an array of its provenance layers
    mapping(uint256 => ProvenanceLayer[]) private _provenance;
    // Mapping from tokenId to its unlock time for time-locked artifacts
    mapping(uint256 => uint256) private _lockedUntil;

    event ProvenanceLayerAdded(uint256 indexed tokenId, uint256 eventId, uint256 timestamp);
    event ArtifactLocked(uint256 indexed tokenId, uint256 unlockTime);
    event ArtifactUnlocked(uint256 indexed tokenId);

    constructor(address _owner) ERC721("ChronoArtifact", "CRA") Ownable(_owner) {}

    modifier onlyChronoForge() {
        require(msg.sender == owner(), "ChronoArtifact: Only ChronoForge can call");
        _;
    }

    // --- External functions callable by ChronoForge only ---

    function mint(address to, uint256 tokenId, string calldata initialMetadataURI) external onlyChronoForge {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, initialMetadataURI);
    }

    function addProvenanceLayer(uint256 tokenId, ProvenanceLayer calldata layer, string calldata newMetadataURI) external onlyChronoForge {
        require(_exists(tokenId), "ChronoArtifact: Token does not exist");
        require(_lockedUntil[tokenId] < block.timestamp, "ChronoArtifact: Artifact is time-locked");

        _provenance[tokenId].push(layer);
        _setTokenURI(tokenId, newMetadataURI); // Update metadata to reflect new provenance
        emit ProvenanceLayerAdded(tokenId, layer.eventId, layer.timestamp);
    }

    function updateTokenURI(uint256 tokenId, string calldata newURI) external onlyChronoForge {
        require(_exists(tokenId), "ChronoArtifact: Token does not exist");
        _setTokenURI(tokenId, newURI);
    }

    function lockArtifact(uint256 tokenId, uint256 unlockTime) external onlyChronoForge {
        require(_exists(tokenId), "ChronoArtifact: Token does not exist");
        require(unlockTime > block.timestamp, "ChronoArtifact: Unlock time must be in the future");
        _lockedUntil[tokenId] = unlockTime;
        emit ArtifactLocked(tokenId, unlockTime);
    }

    function unlockArtifact(uint256 tokenId) external onlyChronoForge {
        require(_exists(tokenId), "ChronoArtifact: Token does not exist");
        require(_lockedUntil[tokenId] > 0, "ChronoArtifact: Artifact not locked");
        require(_lockedUntil[tokenId] <= block.timestamp, "ChronoArtifact: Lock period not yet expired");
        _lockedUntil[tokenId] = 0; // Set to 0 to indicate unlocked
        emit ArtifactUnlocked(tokenId);
    }

    // --- View functions ---

    function getProvenance(uint256 tokenId) external view returns (ProvenanceLayer[] memory) {
        return _provenance[tokenId];
    }

    function isLocked(uint256 tokenId) external view returns (bool, uint256) {
        return (_lockedUntil[tokenId] > block.timestamp, _lockedUntil[tokenId]);
    }

    function isApprovedOrOwner(address caller, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(caller, tokenId);
    }

    // Override transferFrom to ensure ChronoForge can control artifact movement
    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Allow transfer only if ChronoForge itself is the caller OR the artifact is not locked
        // and the regular ERC721 approval allows it.
        require(msg.sender == owner() || (_lockedUntil[tokenId] <= block.timestamp && _isApprovedOrOwner(msg.sender, tokenId)),
                "ChronoArtifact: Cannot transfer locked artifact or unauthorized");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(msg.sender == owner() || (_lockedUntil[tokenId] <= block.timestamp && _isApprovedOrOwner(msg.sender, tokenId)),
                "ChronoArtifact: Cannot transfer locked artifact or unauthorized");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(msg.sender == owner() || (_lockedUntil[tokenId] <= block.timestamp && _isApprovedOrOwner(msg.sender, tokenId)),
                "ChronoArtifact: Cannot transfer locked artifact or unauthorized");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// =============================================================================
// TemporalBadge.sol
// =============================================================================

// ERC721-compliant Soulbound Token (SBT)
contract TemporalBadge is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    // Mapping from tokenId to accrued temporal points
    mapping(uint256 => uint256) private _temporalPoints;
    // Mapping from user address to their tokenId (since it's 1:1 and non-transferable)
    mapping(address => uint256) private _userBadgeTokenId;
    // Mapping to track if a user has already received a badge
    mapping(address => bool) private _hasBadge;

    event TemporalPointsUpdated(address indexed user, uint256 indexed tokenId, uint256 newPoints);
    event BadgeMinted(address indexed user, uint256 indexed tokenId);

    constructor(address _owner) ERC721("TemporalBadge", "TBG") Ownable(_owner) {}

    modifier onlyChronoForge() {
        require(msg.sender == owner(), "TemporalBadge: Only ChronoForge can call");
        _;
    }

    // --- External functions callable by ChronoForge only ---

    function mint(address to, uint256 tokenId, string calldata initialMetadataURI) external onlyChronoForge {
        require(!_hasBadge[to], "TemporalBadge: User already has a badge");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, initialMetadataURI);
        _userBadgeTokenId[to] = tokenId;
        _hasBadge[to] = true;
        emit BadgeMinted(to, tokenId);
    }

    function setTemporalPoints(uint256 tokenId, uint256 points) external onlyChronoForge {
        require(_exists(tokenId), "TemporalBadge: Token does not exist");
        _temporalPoints[tokenId] = points;
        emit TemporalPointsUpdated(ownerOf(tokenId), tokenId, points);
    }

    // --- View functions ---

    function getTemporalPoints(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "TemporalBadge: Token does not exist");
        return _temporalPoints[tokenId];
    }

    function getTokenIdByAddress(address user) external view returns (uint256) {
        return _userBadgeTokenId[user];
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // --- Soulbound Enforcement: Override transfer functions to prevent transfer ---
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("TemporalBadge: Badges are soulbound and cannot be transferred");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("TemporalBadge: Badges are soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("TemporalBadge: Badges are soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("TemporalBadge: Badges are soulbound and cannot be transferred");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("TemporalBadge: Badges are soulbound and cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("TemporalBadge: Badges are soulbound and cannot be approved for all");
    }
}


// =============================================================================
// ChronoForge.sol
// =============================================================================

contract ChronoForge is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Contract References ---
    IChronoArtifact public immutable chronoArtifact;
    ITemporalBadge public immutable temporalBadge;
    IOracleConsumer public oracle;

    // --- Counters for unique IDs ---
    Counters.Counter private _artifactTokenIds;
    Counters.Counter private _eventIds;
    Counters.Counter private _badgeTokenIds; // For TemporalBadges

    // --- Data Structures ---

    enum EventStatus { Proposed, PendingVerification, Verified, Invalid }

    struct EventDetails {
        string name;
        string description;
        bytes32 oracleJobId; // For Chainlink job ID or similar
        uint256 oracleFee;
        EventStatus status;
        address proposer;
        uint256 verificationRequestId; // Store Chainlink requestId
        string verificationProof; // Proof provided by oracle
    }

    struct TemporalBond {
        address creator;
        uint256 amount;
        uint256 eventId;         // Event that needs to be verified for redemption
        uint256 lockUntil;       // Timestamp when bond can be redeemed if event not verified
        bool redeemed;
        bool liquidated;
    }

    struct ProvenanceChallenge {
        address challenger;
        uint256 stake;
        uint256 tokenId;
        uint256 provenanceIndex;
        bool resolved;
        bool isValidated; // true if challenged layer found valid, false if invalid
    }

    // --- Mappings ---
    mapping(uint256 => EventDetails) public events;
    mapping(bytes32 => uint256) private _oracleRequestToEventId; // Map Chainlink request ID to our internal event ID
    mapping(bytes32 => TemporalBond) public temporalBonds;
    mapping(bytes32 => ProvenanceChallenge) public provenanceChallenges; // Unique ID for each challenge
    mapping(address => bool) private _authorizedEventSources; // Addresses that can propose events directly without owner approval (for future DAO use)

    // --- Configuration ---
    uint256 public constant MIN_TEMPORAL_POINTS_FOR_LEVEL1 = 100;
    uint256 public constant TEMPORAL_POINTS_PER_LEVEL = 50; // Points needed for each subsequent level
    uint256 public constant MIN_CHALLENGE_STAKE = 0.1 ether; // Example stake

    // --- Events ---
    event ArtifactForged(address indexed to, uint256 indexed tokenId, string initialMetadataURI);
    event EventProposed(uint256 indexed eventId, string name, address indexed proposer);
    event EventVerificationRequested(uint256 indexed eventId, bytes32 indexed requestId);
    event EventVerified(uint256 indexed eventId, string verificationProof);
    event EventInvalidated(uint256 indexed eventId);
    event InfusionAddedToArtifact(uint256 indexed tokenId, uint256 indexed eventId);
    event TemporalPointsAccrued(address indexed user, uint256 indexed newPoints);
    event TemporalBadgeMinted(address indexed user, uint256 indexed tokenId);
    event ArtifactLockedStatus(uint256 indexed tokenId, bool locked, uint256 until);
    event TemporalBondCreated(bytes32 indexed bondId, address indexed creator, uint256 amount, uint256 eventId);
    event TemporalBondRedeemed(bytes32 indexed bondId);
    event ProvenanceChallengeInitiated(bytes32 indexed challengeId, uint256 indexed tokenId, uint256 provenanceIndex, address indexed challenger);
    event ProvenanceChallengeResolved(bytes32 indexed challengeId, bool isValidated);

    constructor(address _artifactContract, address _badgeContract, address _oracleAddress) Ownable(msg.sender) {
        require(_artifactContract != address(0), "ChronoForge: Invalid artifact contract address");
        require(_badgeContract != address(0), "ChronoForge: Invalid badge contract address");
        require(_oracleAddress != address(0), "ChronoForge: Invalid oracle address");

        chronoArtifact = IChronoArtifact(_artifactContract);
        temporalBadge = ITemporalBadge(_badgeContract);
        oracle = IOracleConsumer(_oracleAddress);
    }

    // =========================================================================
    // I. Core Setup & Ownership
    // =========================================================================

    /**
     * @dev Allows the owner to update the trusted oracle address.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "ChronoForge: New oracle address cannot be zero");
        oracle = IOracleConsumer(_newOracle);
    }

    /**
     * @dev Sets the base URI for both ChronoArtifacts and Temporal Badges.
     *      This is useful for dApps to resolve metadata.
     * @param _artifactBaseURI The new base URI for ChronoArtifacts.
     * @param _badgeBaseURI The new base URI for Temporal Badges.
     */
    function setMetadataBaseURIs(string memory _artifactBaseURI, string memory _badgeBaseURI) external onlyOwner {
        // Note: Actual implementation would call `_setBaseURI` on `chronoArtifact` and `temporalBadge`
        // Requires these external contracts to expose such a function callable by `owner()`.
        // For this example, we'll assume they have a `setBaseURI(string)` callable by `ChronoForge`.
        // If these methods were public in IChronoArtifact and ITemporalBadge, one could call them here.
        // As they are `_setBaseURI` in openzeppelin, this logic needs to be handled in the respective contract constructors or via separate calls.
        // For simplicity, this function acts as a placeholder signaling the *intent*.
        // A direct call might look like: `chronoArtifact.setBaseURI(_artifactBaseURI);`
        // if `setBaseURI` was exposed by ChronoArtifact and TemporalBadge.
    }


    // =========================================================================
    // II. ChronoArtifact Management
    // =========================================================================

    /**
     * @dev Mints a new ChronoArtifact to a specified address.
     * @param _to The recipient of the new ChronoArtifact.
     * @param _initialMetadataURI The initial metadata URI for the artifact.
     */
    function forgeChronoArtifact(address _to, string memory _initialMetadataURI) external onlyOwner {
        _artifactTokenIds.increment();
        uint256 newId = _artifactTokenIds.current();
        chronoArtifact.mint(_to, newId, _initialMetadataURI);
        emit ArtifactForged(_to, newId, _initialMetadataURI);
    }

    /**
     * @dev Infuses a ChronoArtifact with a verified event. This updates its provenance and metadata.
     * @param _tokenId The ID of the ChronoArtifact to infuse.
     * @param _eventId The ID of the verified event to infuse.
     * @param _newMetadataURI The updated metadata URI reflecting the new provenance.
     *                        This is crucial for dynamic NFT rendering.
     */
    function infuseWithEvent(uint256 _tokenId, uint256 _eventId, string memory _newMetadataURI) external {
        require(chronoArtifact.isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to infuse this artifact");
        (bool locked, ) = chronoArtifact.isLocked(_tokenId);
        require(!locked, "ChronoForge: Artifact is time-locked and cannot be infused");
        require(events[_eventId].status == EventStatus.Verified, "ChronoForge: Event not verified or does not exist");

        IChronoArtifact.ProvenanceLayer memory layer = IChronoArtifact.ProvenanceLayer({
            eventId: _eventId,
            timestamp: block.timestamp,
            verificationProof: events[_eventId].verificationProof
        });
        chronoArtifact.addProvenanceLayer(_tokenId, layer, _newMetadataURI);
        emit InfusionAddedToArtifact(_tokenId, _eventId);

        // Optionally, accrue temporal points to the user who infused the artifact
        if (temporalBadge.getTokenIdByAddress(msg.sender) != 0) {
            accrueTemporalPoints(msg.sender, 5); // Example: 5 points for a successful infusion
        }
    }

    /**
     * @dev Retrieves the full historical provenance (list of infused events) for a given ChronoArtifact.
     * @param _tokenId The ID of the ChronoArtifact.
     * @return An array of ProvenanceLayer structs.
     */
    function getArtifactProvenance(uint256 _tokenId) external view returns (IChronoArtifact.ProvenanceLayer[] memory) {
        return chronoArtifact.getProvenance(_tokenId);
    }

    /**
     * @dev Locks a ChronoArtifact, preventing transfer or further infusion until a specified time.
     * @param _tokenId The ID of the ChronoArtifact to lock.
     * @param _lockDuration The duration in seconds for which the artifact will be locked.
     */
    function timeLockArtifact(uint256 _tokenId, uint256 _lockDuration) external {
        require(chronoArtifact.ownerOf(_tokenId) == msg.sender, "ChronoForge: Not owner of artifact");
        require(_lockDuration > 0, "ChronoForge: Lock duration must be positive");
        uint256 unlockTime = block.timestamp + _lockDuration;
        chronoArtifact.lockArtifact(_tokenId, unlockTime);
        emit ArtifactLockedStatus(_tokenId, true, unlockTime);
    }

    /**
     * @dev Releases a time-locked artifact if the lock duration has passed.
     * @param _tokenId The ID of the ChronoArtifact to release.
     */
    function releaseTimeLockedArtifact(uint256 _tokenId) external {
        require(chronoArtifact.ownerOf(_tokenId) == msg.sender, "ChronoForge: Not owner of artifact");
        chronoArtifact.unlockArtifact(_tokenId);
        emit ArtifactLockedStatus(_tokenId, false, 0);
    }

    // =========================================================================
    // III. Event Lifecycle & Oracle Interaction
    // =========================================================================

    /**
     * @dev Proposes a new event that needs external verification via an oracle.
     *      Only owner or authorized sources can propose events.
     * @param _eventName A descriptive name for the event.
     * @param _eventDescription A detailed description of the event.
     * @param _oracleJobId The specific job ID for the oracle request (e.g., Chainlink job ID).
     * @param _oracleFee The fee to pay the oracle for verification.
     */
    function proposeEvent(
        string memory _eventName,
        string memory _eventDescription,
        bytes32 _oracleJobId,
        uint256 _oracleFee
    ) external onlyOwner { // For initial version, only owner. Can be extended to _authorizedEventSources
        _eventIds.increment();
        uint256 newId = _eventIds.current();
        events[newId] = EventDetails({
            name: _eventName,
            description: _eventDescription,
            oracleJobId: _oracleJobId,
            oracleFee: _oracleFee,
            status: EventStatus.Proposed,
            proposer: msg.sender,
            verificationRequestId: 0, // No request sent yet
            verificationProof: ""
        });
        emit EventProposed(newId, _eventName, msg.sender);
    }

    /**
     * @dev Requests verification of a proposed event via the external oracle.
     *      Only callable by owner/authorized sources to prevent spamming oracle requests.
     * @param _eventId The ID of the event to request verification for.
     */
    function requestEventVerification(uint256 _eventId) external onlyOwner { // Or `onlyAuthorizedEventSource`
        EventDetails storage event_ = events[_eventId];
        require(event_.status == EventStatus.Proposed || event_.status == EventStatus.Invalid, "ChronoForge: Event not in proposed or invalid state");
        require(event_.oracleJobId != bytes32(0), "ChronoForge: Oracle job ID not set for this event");
        require(event_.oracleFee > 0, "ChronoForge: Oracle fee must be greater than zero");

        event_.status = EventStatus.PendingVerification;
        bytes32 requestId = oracle.requestVerification(event_.oracleJobId, _eventId, event_.oracleFee);
        event_.verificationRequestId = uint256(requestId); // Store for future reference
        _oracleRequestToEventId[requestId] = _eventId;
        emit EventVerificationRequested(_eventId, requestId);
    }

    /**
     * @dev Callback function for the oracle to fulfill a verification request.
     *      This function must be designed to be callable only by the trusted oracle.
     *      In a real Chainlink integration, this would use `fulfillRandomWords` or `checkUpkeep` patterns.
     * @param _requestId The ID of the oracle request.
     * @param _isVerified True if the event is verified, false otherwise.
     * @param _verificationProof A string proof from the oracle (e.g., URL, hash).
     */
    function fulfillEventVerification(bytes32 _requestId, bool _isVerified, string memory _verificationProof) external {
        // In a real Chainlink setup, this would be an `onlyConsumer` or `onlyVRFCoordinator` check.
        // For this example, we'll assume the oracle contract calls this directly.
        // require(msg.sender == address(oracle), "ChronoForge: Only trusted oracle can fulfill requests");

        uint256 eventId = _oracleRequestToEventId[_requestId];
        require(eventId != 0, "ChronoForge: Unknown oracle request ID");
        require(events[eventId].status == EventStatus.PendingVerification, "ChronoForge: Event not in pending verification state");

        if (_isVerified) {
            events[eventId].status = EventStatus.Verified;
            events[eventId].verificationProof = _verificationProof;
            emit EventVerified(eventId, _verificationProof);
        } else {
            events[eventId].status = EventStatus.Invalid;
            events[eventId].verificationProof = "Verification Failed"; // Clear proof if verification failed
            emit EventInvalidated(eventId);
        }
        delete _oracleRequestToEventId[_requestId]; // Clean up
    }

    /**
     * @dev Retrieves the current status and details of a registered event.
     * @param _eventId The ID of the event.
     * @return EventDetails struct containing all information about the event.
     */
    function getEventDetails(uint256 _eventId) external view returns (EventDetails memory) {
        require(_eventId <= _eventIds.current() && _eventId > 0, "ChronoForge: Event does not exist");
        return events[_eventId];
    }

    /**
     * @dev Owner can manually mark an event as invalid, overriding previous verification (e.g., in case of oracle error or dispute).
     * @param _eventId The ID of the event to invalidate.
     */
    function markEventInvalid(uint256 _eventId) external onlyOwner {
        require(events[_eventId].status != EventStatus.Proposed, "ChronoForge: Cannot invalidate a proposed event directly");
        require(events[_eventId].status != EventStatus.Invalid, "ChronoForge: Event is already invalid");
        events[_eventId].status = EventStatus.Invalid;
        events[_eventId].verificationProof = "Manually Invalidated by Owner";
        emit EventInvalidated(_eventId);
    }

    /**
     * @dev Allows the owner to authorize external contracts/addresses that can propose events directly
     *      without requiring `onlyOwner` for `proposeEvent`. This enables decentralized event sources.
     * @param _source The address to authorize/de-authorize.
     * @param _isAuthorized True to authorize, false to de-authorize.
     */
    function authorizeEventSource(address _source, bool _isAuthorized) external onlyOwner {
        require(_source != address(0), "ChronoForge: Cannot authorize zero address");
        _authorizedEventSources[_source] = _isAuthorized;
    }


    // =========================================================================
    // IV. Temporal Badge Management
    // =========================================================================

    /**
     * @dev Mints a unique Temporal Badge (SBT) for a user. Only one per address.
     * @param _to The address to mint the Temporal Badge for.
     */
    function mintTemporalBadge(address _to) external {
        require(msg.sender == _to || msg.sender == owner(), "ChronoForge: Can only mint for self or by owner");
        require(temporalBadge.getTokenIdByAddress(_to) == 0, "ChronoForge: User already has a badge");

        _badgeTokenIds.increment();
        uint256 newId = _badgeTokenIds.current();
        temporalBadge.mint(_to, newId, "ipfs://QmbadgeURI/initial"); // Example URI
        emit TemporalBadgeMinted(_to, newId);
    }

    /**
     * @dev Awards temporal points to a user's badge. Typically triggered by successful actions
     *      (e.g., correct prediction, successful artifact infusion).
     * @param _user The user's address whose badge points should be updated.
     * @param _points The number of points to accrue.
     */
    function accrueTemporalPoints(address _user, uint256 _points) public {
        // Can be called by owner or implicitly by other successful functions (e.g., infuseWithEvent)
        uint256 badgeId = temporalBadge.getTokenIdByAddress(_user);
        require(badgeId != 0, "ChronoForge: User does not have a temporal badge");

        uint256 currentPoints = temporalBadge.getTemporalPoints(badgeId);
        temporalBadge.setTemporalPoints(badgeId, currentPoints + _points);
        emit TemporalPointsAccrued(_user, currentPoints + _points);
    }

    /**
     * @dev Calculates and returns the current "level" of a user's Temporal Badge based on their accrued points.
     * @param _user The user's address.
     * @return The calculated badge level.
     */
    function getTemporalBadgeLevel(address _user) external view returns (uint256) {
        uint256 badgeId = temporalBadge.getTokenIdByAddress(_user);
        if (badgeId == 0) return 0; // No badge, no level

        uint256 points = temporalBadge.getTemporalPoints(badgeId);
        if (points < MIN_TEMPORAL_POINTS_FOR_LEVEL1) return 0;
        return 1 + (points - MIN_TEMPORAL_POINTS_FOR_LEVEL1) / TEMPORAL_POINTS_PER_LEVEL;
    }

    /**
     * @dev Retrieves the total temporal points accumulated by a user.
     * @param _user The user's address.
     * @return The total temporal points.
     */
    function getTemporalPoints(address _user) external view returns (uint256) {
        uint256 badgeId = temporalBadge.getTokenIdByAddress(_user);
        if (badgeId == 0) return 0;
        return temporalBadge.getTemporalPoints(badgeId);
    }

    // =========================================================================
    // V. Advanced Temporal Mechanics & Challenges
    // =========================================================================

    /**
     * @dev Allows users to create a "temporal bond" – a deposit locked until a specific event is verified,
     *      or a duration passes, providing a mechanism for on-chain future claims or predictions.
     * @param _bondId A unique identifier for this bond (e.g., hash of parameters).
     * @param _eventId The ID of the event that needs to be verified for redemption.
     * @param _lockDuration The duration in seconds after which the bond can be liquidated if the event isn't verified.
     * @param _amount The amount of ETH to deposit for the bond.
     */
    function createTemporalBond(
        bytes32 _bondId,
        uint256 _eventId,
        uint256 _lockDuration,
        uint256 _amount
    ) external payable {
        require(msg.value == _amount, "ChronoForge: ETH sent must match bond amount");
        require(temporalBonds[_bondId].creator == address(0), "ChronoForge: Bond ID already exists");
        require(events[_eventId].status != EventStatus.Verified && events[_eventId].status != EventStatus.Invalid, "ChronoForge: Event already resolved");
        require(_lockDuration > 0, "ChronoForge: Lock duration must be positive");

        temporalBonds[_bondId] = TemporalBond({
            creator: msg.sender,
            amount: _amount,
            eventId: _eventId,
            lockUntil: block.timestamp + _lockDuration,
            redeemed: false,
            liquidated: false
        });
        emit TemporalBondCreated(_bondId, msg.sender, _amount, _eventId);
    }

    /**
     * @dev Allows the creator to redeem a temporal bond if its conditions (event verification, time expiry) are met.
     *      If the event is verified as true, they get their bond back.
     *      If the event is false or not verified by `lockUntil`, the bond can be redeemed.
     * @param _bondId The unique identifier of the bond.
     */
    function redeemTemporalBond(bytes32 _bondId) external {
        TemporalBond storage bond = temporalBonds[_bondId];
        require(bond.creator == msg.sender, "ChronoForge: Not the bond creator");
        require(!bond.redeemed && !bond.liquidated, "ChronoForge: Bond already redeemed or liquidated");

        EventDetails storage event_ = events[bond.eventId];

        bool canRedeem = false;
        if (event_.status == EventStatus.Verified) {
            canRedeem = true; // Bond is fulfilled, creator can redeem
            accrueTemporalPoints(msg.sender, 20); // Reward for successful prediction/claim
        } else if (block.timestamp >= bond.lockUntil && event_.status != EventStatus.Verified) {
            // If lock time passed and event isn't verified, it can be liquidated/redeemed
            // This logic depends on exact bond type (e.g., if it's a "yes" prediction, then no verification means failure)
            // For simplicity, let's say after lockUntil, it can be redeemed if not verified.
            canRedeem = true;
            bond.liquidated = true; // Mark as liquidated instead of redeemed if it's based on time-out
        }

        require(canRedeem, "ChronoForge: Bond conditions not met for redemption yet");

        bond.redeemed = true;
        (bool success, ) = payable(bond.creator).call{value: bond.amount}("");
        require(success, "ChronoForge: Failed to transfer bond amount");
        emit TemporalBondRedeemed(_bondId);
    }

    /**
     * @dev Initiates a challenge against a specific provenance layer of an artifact.
     *      Requires a stake from the challenger.
     * @param _tokenId The ID of the ChronoArtifact.
     * @param _provenanceIndex The index of the provenance layer in the artifact's history to challenge.
     * @param _stakeAmount The amount of ETH to stake for the challenge.
     */
    function challengeProvenanceLayer(uint256 _tokenId, uint256 _provenanceIndex, uint256 _stakeAmount) external payable {
        require(msg.value == _stakeAmount, "ChronoForge: ETH sent must match stake amount");
        require(_stakeAmount >= MIN_CHALLENGE_STAKE, "ChronoForge: Stake amount too low");

        IChronoArtifact.ProvenanceLayer[] memory provenance = chronoArtifact.getProvenance(_tokenId);
        require(_provenanceIndex < provenance.length, "ChronoForge: Invalid provenance index");

        bytes32 challengeId = keccak256(abi.encodePacked(_tokenId, _provenanceIndex, block.timestamp, msg.sender));
        require(provenanceChallenges[challengeId].challenger == address(0), "ChronoForge: Challenge already initiated with this ID");

        provenanceChallenges[challengeId] = ProvenanceChallenge({
            challenger: msg.sender,
            stake: _stakeAmount,
            tokenId: _tokenId,
            provenanceIndex: _provenanceIndex,
            resolved: false,
            isValidated: false
        });
        emit ProvenanceChallengeInitiated(challengeId, _tokenId, _provenanceIndex, msg.sender);
    }

    /**
     * @dev Owner/DAO resolves a provenance challenge, determining if the challenged layer is valid or not.
     *      Distributes/slashes stakes based on the resolution.
     * @param _challengeId The unique ID of the challenge.
     * @param _isValid True if the challenged provenance layer is deemed valid, false if invalid.
     */
    function settleProvenanceChallenge(bytes32 _challengeId, bool _isValid) external onlyOwner {
        ProvenanceChallenge storage challenge = provenanceChallenges[_challengeId];
        require(challenge.challenger != address(0), "ChronoForge: Challenge does not exist");
        require(!challenge.resolved, "ChronoForge: Challenge already resolved");

        challenge.resolved = true;
        challenge.isValidated = _isValid;

        // If challenge.isValidated is TRUE, challenger loses stake. If FALSE, challenger wins stake.
        if (_isValid) { // Challenger was wrong, layer is valid
            // Challenger's stake can be burned, sent to treasury, or part of a DAO-controlled fund
            // For simplicity, the stake remains in the contract, and can be managed by owner.
            // In a real system, slashing and rewarding would be more complex (e.g., rewarding resolvers).
        } else { // Challenger was right, layer is invalid
            (bool success, ) = payable(challenge.challenger).call{value: challenge.stake}("");
            require(success, "ChronoForge: Failed to refund challenger's stake");
            // Optionally: a penalty could be applied to the party who added the invalid provenance.
            // This would require more complex state tracking in ChronoArtifact.
        }
        emit ProvenanceChallengeResolved(_challengeId, _isValid);
    }

    /**
     * @dev Allows participants to withdraw their stakes from resolved challenges if they won.
     *      (More nuanced: this assumes winning stake is sent immediately, or specific withdrawal after resolution).
     *      In the `settleProvenanceChallenge`, we already send if won. This function is more for a 'claim' system if stakes were pooled.
     *      For direct send on win, this function might not be strictly needed based on `settleProvenanceChallenge`'s current logic.
     *      Let's re-purpose it for a general "withdraw from contract" for any owed funds (e.g., if a bond payout failed initially).
     *      This is a common admin/owner function.
     */
    function withdrawStakedFunds(bytes32 _challengeId) external {
        ProvenanceChallenge storage challenge = provenanceChallenges[_challengeId];
        require(challenge.resolved, "ChronoForge: Challenge not resolved");
        // This function would be more complex if stakes weren't immediately transferred.
        // As currently implemented, `settleProvenanceChallenge` sends winning stake.
        // This function can be a fallback for owner to withdraw residual.
        if (msg.sender == owner()) {
            uint256 contractBalance = address(this).balance;
            (bool success, ) = payable(owner()).call{value: contractBalance}("");
            require(success, "ChronoForge: Failed to withdraw balance");
        }
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}
```