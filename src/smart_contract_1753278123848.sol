This smart contract, "ChronoForge," envisions a unique decentralized protocol where users (Chronosmiths) forge powerful, evolving digital artifacts (ChronoArtifacts) through a series of time-bound challenges and resource commitments. It incorporates concepts of dynamic NFTs, on-chain reputation (Temporal Insight), a lightweight governance model, and a novel approach to asset evolution driven by user interaction and temporal progression.

---

## ChronoForge: Temporal Artifact Forging Protocol

**A Smart Contract for Dynamic NFT Evolution and On-Chain Reputation**

### Outline and Function Summary

**Core Concepts:**

*   **ChronoArtifacts (NFTs):** Dynamically evolving ERC-721 tokens that progress through distinct "Epochs." Their properties can change and be "attuned" by Chronosmiths.
*   **Chronosmiths (Users):** Participants who register and accrue "Temporal Insight" (reputation) by successfully forging artifacts and completing challenges.
*   **Temporal Insight (Reputation):** An on-chain score for Chronosmiths, unlocking higher "Temporal Powers" (special roles/privileges) within the protocol.
*   **Temporal Challenges:** On-chain quests or conditions that Chronosmiths can propose, vote on, and complete to earn rewards and advance artifacts.
*   **Forging Process:** A multi-stage process where users commit resources (ETH/time) to advance an artifact through its epochs.

---

### Function Summary

**I. Core Protocol Management (Admin/Owner/Manager Roles)**

1.  **`constructor()`**: Initializes the contract, sets the deployer as `DEFAULT_ADMIN_ROLE`.
2.  **`pause()`**: Pauses all core protocol functions in emergencies.
3.  **`unpause()`**: Unpauses the protocol.
4.  **`grantTemporalPower(address _chronosmith, bytes32 _role)`**: Grants a specific `AccessControl` role (Temporal Power) to a Chronosmith. Requires `DEFAULT_ADMIN_ROLE`.
5.  **`revokeTemporalPower(address _chronosmith, bytes32 _role)`**: Revokes a specific `AccessControl` role. Requires `DEFAULT_ADMIN_ROLE`.
6.  **`updateCoreParameter(bytes32 _paramName, uint256 _newValue)`**: Updates a core protocol parameter (e.g., base epoch duration, forging fees). Requires `ADMIN_ROLE`.
7.  **`setEpochAdvanceFee(uint256 _epoch, uint256 _fee)`**: Sets the ETH fee required to advance an artifact to a specific epoch. Requires `ADMIN_ROLE`.
8.  **`setChallengeReward(uint256 _challengeId, uint256 _rewardAmount)`**: Sets the `TemporalInsight` reward for completing a specific challenge. Requires `ADMIN_ROLE`.
9.  **`withdrawProtocolFunds(address _to, uint256 _amount)`**: Allows an admin to withdraw collected ETH fees from the protocol treasury. Requires `ADMIN_ROLE`.

**II. Chronosmith (User) Management**

10. **`registerChronosmith(string calldata _bioUri)`**: Allows a user to register as a Chronosmith, creating their on-chain profile.
11. **`updateChronosmithBio(string calldata _newBioUri)`**: Allows a Chronosmith to update their profile's metadata URI.
12. **`claimTemporalInsightReward(uint256 _amount)`**: Allows a Chronosmith to claim earned `TemporalInsight` into their profile. This would typically be called by the protocol after successful actions.
13. **`delegateTemporalInsight(address _delegatee)`**: Allows a Chronosmith to delegate their `TemporalInsight` voting power to another address.
14. **`revokeTemporalInsightDelegation()`**: Revokes any active `TemporalInsight` delegation.

**III. ChronoArtifact Forging & Evolution**

15. **`initiateArtifactForge(string calldata _initialUri)`**: Starts the forging process for a new ChronoArtifact, minting a new NFT in its initial epoch. Requires a small ETH deposit.
16. **`advanceArtifactEpoch(uint256 _artifactId)`**: Advances a ChronoArtifact to its next epoch if all conditions (time elapsed, fees paid) are met.
17. **`attuneTemporalProperty(uint256 _artifactId, string calldata _propertyKey, string calldata _propertyValue)`**: Allows the artifact owner to set or update a dynamic "temporal property" for their artifact. This can only be done during certain epochs or by Chronosmiths with specific `TemporalPowers`.
18. **`catalyzeArtifactEvolution(uint256 _artifactId)`**: Allows an owner to pay an additional fee to instantly advance an artifact to its next epoch, bypassing the time-lock.
19. **`bondArtifactToSoul(uint256 _artifactId)`**: Makes a ChronoArtifact "Soul-Bound" (non-transferable and tied to the current owner's address). This is a permanent action.
20. **`retireArtifact(uint256 _artifactId)`**: Allows an artifact owner to "retire" (burn) their fully evolved artifact, potentially claiming a final reward or unlocking a specific on-chain achievement.
21. **`retrieveForgingCollateral(uint256 _artifactId)`**: Allows the owner to retrieve initial ETH collateral if forging is cancelled or fails (e.g., if a time limit is missed for an epoch).

**IV. Temporal Challenges & On-Chain Quests**

22. **`proposeTemporalChallenge(string calldata _challengeUri, uint256 _insightReward)`**: Allows Chronosmiths with sufficient `TemporalInsight` or `CHALLENGE_PROPOSER_ROLE` to propose new on-chain challenges.
23. **`voteOnChallengeProposal(uint256 _challengeId, bool _approve)`**: Allows Chronosmiths (weighted by `TemporalInsight`) to vote on proposed challenges.
24. **`completeTemporalChallenge(uint256 _challengeId)`**: Allows a Chronosmith to mark a challenge as completed and claim rewards, provided the challenge's on-chain conditions are met (this function would typically be called by an authorized `CHALLENGE_VALIDATOR_ROLE` or trigger self-validation).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checks if needed, though >=0.8.0 handles overflow by default.

/// @title ChronoForge
/// @dev A smart contract for dynamic NFT evolution, on-chain reputation, and time-bound challenges.
///      This contract enables users (Chronosmiths) to forge unique, evolving digital artifacts (ChronoArtifacts).
///      It incorporates concepts of dynamic NFTs, on-chain reputation (Temporal Insight), a lightweight governance model,
///      and a novel approach to asset evolution driven by user interaction and temporal progression.

contract ChronoForge is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Best practice for clarity even if 0.8.x handles overflow.

    /* ====================================================================================================
                                            I. Core Protocol Roles & Identifiers
    ==================================================================================================== */

    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant ARTIFACT_FORGE_ROLE = keccak256("ARTIFACT_FORGE_ROLE"); // Role for initiating complex forges
    bytes32 public constant CHALLENGE_PROPOSER_ROLE = keccak256("CHALLENGE_PROPOSER_ROLE"); // Role for proposing challenges
    bytes32 public constant CHALLENGE_VALIDATOR_ROLE = keccak256("CHALLENGE_VALIDATOR_ROLE"); // Role for validating challenge completion

    /* ====================================================================================================
                                            II. Data Structures
    ==================================================================================================== */

    // ChronoArtifact Epochs (Stages of Evolution)
    enum ArtifactEpoch {
        RAW_ESSENCE,    // Initial state
        TEMPORAL_SEED,  // First stage of forging
        CHRONAL_HEART,  // Second stage
        ASTRAL_CORE,    // Third stage
        ETERNAL_FORGE   // Fully evolved
    }

    // Temporal Challenge Status
    enum ChallengeStatus {
        PROPOSED,
        VOTING,
        ACTIVE,
        COMPLETED,
        REJECTED
    }

    // Struct for a Chronosmith's profile
    struct ChronosmithProfile {
        bool registered;
        string bioUri; // URI pointing to off-chain metadata for Chronosmith profile
        uint256 temporalInsight; // On-chain reputation/XP
        address insightDelegation; // Address to which Temporal Insight is delegated for voting
    }

    // Struct for a ChronoArtifact (ERC-721 token)
    struct ChronoArtifact {
        uint256 tokenId;
        address owner;
        ArtifactEpoch currentEpoch;
        uint256 epochStartTime; // Timestamp when current epoch began
        string tokenUri; // Base URI for NFT metadata
        mapping(string => string) temporalProperties; // Dynamic properties of the artifact
        bool isSoulBound; // If true, NFT is non-transferable
        uint256 initialCollateral; // ETH committed during initiation
    }

    // Struct for a Temporal Challenge
    struct TemporalChallenge {
        uint256 id;
        string challengeUri; // URI pointing to off-chain details of the challenge
        address proposer;
        uint256 insightReward; // Temporal Insight awarded upon completion
        ChallengeStatus status;
        uint256 proposalTimestamp;
        uint256 requiredInsightToPropose; // Minimum insight needed to propose
        uint256 completionTimestamp; // When the challenge was completed
        // For simple voting:
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this challenge
    }

    /* ====================================================================================================
                                            III. State Variables
    ==================================================================================================== */

    Counters.Counter private _chronosmithIdCounter;
    Counters.Counter private _artifactIdCounter;
    Counters.Counter private _challengeIdCounter;

    mapping(address => ChronosmithProfile) public chronosmiths;
    mapping(uint256 => ChronoArtifact) public chronoArtifacts;
    mapping(uint256 => TemporalChallenge) public temporalChallenges;

    // Protocol Parameters (updatable by ADMIN_ROLE)
    mapping(bytes32 => uint256) public protocolParameters;
    mapping(uint256 => uint256) public epochAdvanceFees; // epoch => ETH fee

    /* ====================================================================================================
                                            IV. Events
    ==================================================================================================== */

    event ChronosmithRegistered(address indexed chronosmithAddress, string bioUri);
    event ChronosmithProfileUpdated(address indexed chronosmithAddress, string newBioUri);
    event TemporalInsightClaimed(address indexed chronosmithAddress, uint256 amount);
    event InsightDelegated(address indexed delegator, address indexed delegatee);
    event InsightDelegationRevoked(address indexed delegator);

    event ArtifactForgeInitiated(uint256 indexed artifactId, address indexed owner, string initialUri);
    event ArtifactEpochAdvanced(uint256 indexed artifactId, ArtifactEpoch newEpoch, uint256 timestamp);
    event TemporalPropertyAttuned(uint256 indexed artifactId, string propertyKey, string propertyValue);
    event ArtifactCatalyzed(uint256 indexed artifactId, uint256 oldEpoch, uint256 newEpoch);
    event ArtifactBondedToSoul(uint256 indexed artifactId, address indexed owner);
    event ArtifactRetired(uint256 indexed artifactId, address indexed owner);
    event ForgingCollateralRetrieved(uint256 indexed artifactId, address indexed owner, uint256 amount);

    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string challengeUri, uint256 insightReward);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, bool approved, uint256 totalVotesFor, uint256 totalVotesAgainst);
    event ChallengeCompleted(uint256 indexed challengeId, address indexed completer, uint256 insightReward);

    event CoreParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event EpochAdvanceFeeSet(uint256 indexed epoch, uint256 fee);
    event ProtocolFundsWithdrawn(address indexed to, uint256 amount);

    /* ====================================================================================================
                                            V. Constructor & Modifiers
    ==================================================================================================== */

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender); // Grant deployer PAUSER_ROLE
        _grantRole(ARTIFACT_FORGE_ROLE, msg.sender); // Deployer can initiate complex forges
        _grantRole(CHALLENGE_PROPOSER_ROLE, msg.sender); // Deployer can propose challenges
        _grantRole(CHALLENGE_VALIDATOR_ROLE, msg.sender); // Deployer can validate challenges

        // Set initial protocol parameters
        protocolParameters[keccak256("BASE_EPOCH_DURATION")] = 1 days; // Default duration for an epoch
        protocolParameters[keccak256("MIN_CHALLENGE_INSIGHT_PROPOSAL")] = 100; // Min insight to propose a challenge
        protocolParameters[keccak256("CHALLENGE_VOTING_PERIOD")] = 3 days; // Duration for challenge voting

        // Set initial epoch advance fees (example values)
        epochAdvanceFees[uint256(ArtifactEpoch.TEMPORAL_SEED)] = 0.01 ether;
        epochAdvanceFees[uint256(ArtifactEpoch.CHRONAL_HEART)] = 0.05 ether;
        epochAdvanceFees[uint256(ArtifactEpoch.ASTRAL_CORE)] = 0.1 ether;
        epochAdvanceFees[uint256(ArtifactEpoch.ETERNAL_FORGE)] = 0.2 ether;
    }

    modifier onlyChronosmith() {
        require(chronosmiths[msg.sender].registered, "CF: Not a registered Chronosmith");
        _;
    }

    modifier onlyArtifactOwner(uint256 _artifactId) {
        require(_exists(_artifactId), "CF: Artifact does not exist");
        require(ownerOf(_artifactId) == msg.sender, "CF: Not artifact owner");
        _;
    }

    // Override `_authorizeMint` for ERC721 to integrate with `whenNotPaused` and `AccessControl`
    function _authorizeMint(address to) internal virtual override {
        require(!paused(), "CF: Protocol is paused");
        // Add specific roles if needed for minting beyond `initiateArtifactForge`
    }

    /* ====================================================================================================
                                            VI. Core Protocol Management (Admin/Owner/Manager Roles)
    ==================================================================================================== */

    /// @dev Pauses the contract, preventing certain state-changing functions.
    /// @custom:function_id 1
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev Unpauses the contract, allowing functions to resume.
    /// @custom:function_id 2
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Grants a specific role (Temporal Power) to a Chronosmith.
    /// @param _chronosmith The address of the Chronosmith to grant the role to.
    /// @param _role The role to grant (e.g., `ARTIFACT_FORGE_ROLE`).
    /// @custom:function_id 3
    function grantTemporalPower(address _chronosmith, bytes32 _role) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(chronosmiths[_chronosmith].registered, "CF: Target not a registered Chronosmith");
        _grantRole(_role, _chronosmith);
    }

    /// @dev Revokes a specific role from a Chronosmith.
    /// @param _chronosmith The address of the Chronosmith to revoke the role from.
    /// @param _role The role to revoke.
    /// @custom:function_id 4
    function revokeTemporalPower(address _chronosmith, bytes32 _role) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(chronosmiths[_chronosmith].registered, "CF: Target not a registered Chronosmith");
        require(hasRole(_role, _chronosmith), "CF: Chronosmith does not have this role");
        _revokeRole(_role, _chronosmith);
    }

    /// @dev Updates a core protocol parameter.
    /// @param _paramName The keccak256 hash of the parameter name (e.g., `keccak256("BASE_EPOCH_DURATION")`).
    /// @param _newValue The new value for the parameter.
    /// @custom:function_id 5
    function updateCoreParameter(bytes32 _paramName, uint256 _newValue) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        protocolParameters[_paramName] = _newValue;
        emit CoreParameterUpdated(_paramName, _newValue);
    }

    /// @dev Sets the ETH fee required to advance an artifact to a specific epoch.
    /// @param _epoch The target epoch (as its `uint256` enum value).
    /// @param _fee The ETH fee in Wei.
    /// @custom:function_id 6
    function setEpochAdvanceFee(uint256 _epoch, uint256 _fee) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_epoch <= uint256(ArtifactEpoch.ETERNAL_FORGE), "CF: Invalid epoch");
        epochAdvanceFees[_epoch] = _fee;
        emit EpochAdvanceFeeSet(_epoch, _fee);
    }

    /// @dev Sets the Temporal Insight reward for completing a specific challenge.
    /// @param _challengeId The ID of the challenge.
    /// @param _rewardAmount The amount of Temporal Insight to reward.
    /// @custom:function_id 7
    function setChallengeReward(uint256 _challengeId, uint256 _rewardAmount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(_challengeId > 0 && _challengeId <= _challengeIdCounter.current(), "CF: Invalid challenge ID");
        temporalChallenges[_challengeId].insightReward = _rewardAmount;
        // Optionally add an event
    }

    /// @dev Allows an admin to withdraw collected ETH fees from the protocol treasury.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of ETH (in Wei) to withdraw.
    /// @custom:function_id 8
    function withdrawProtocolFunds(address _to, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "CF: Amount must be greater than zero");
        require(address(this).balance >= _amount, "CF: Insufficient contract balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "CF: ETH transfer failed");
        emit ProtocolFundsWithdrawn(_to, _amount);
    }

    /* ====================================================================================================
                                            VII. Chronosmith (User) Management
    ==================================================================================================== */

    /// @dev Allows a user to register as a Chronosmith.
    /// @param _bioUri URI pointing to off-chain metadata for Chronosmith profile.
    /// @custom:function_id 9
    function registerChronosmith(string calldata _bioUri) public whenNotPaused {
        require(!chronosmiths[msg.sender].registered, "CF: Already a registered Chronosmith");
        chronosmiths[msg.sender] = ChronosmithProfile({
            registered: true,
            bioUri: _bioUri,
            temporalInsight: 0,
            insightDelegation: address(0) // No delegation initially
        });
        _chronosmithIdCounter.increment(); // Not strictly needed, but tracks count
        emit ChronosmithRegistered(msg.sender, _bioUri);
    }

    /// @dev Allows a Chronosmith to update their profile's metadata URI.
    /// @param _newBioUri The new URI for the Chronosmith profile.
    /// @custom:function_id 10
    function updateChronosmithBio(string calldata _newBioUri) public onlyChronosmith whenNotPaused {
        chronosmiths[msg.sender].bioUri = _newBioUri;
        emit ChronosmithProfileUpdated(msg.sender, _newBioUri);
    }

    /// @dev Allows a Chronosmith to claim earned Temporal Insight.
    ///      This would typically be called by the protocol after successful actions (e.g., challenge completion).
    /// @param _amount The amount of Temporal Insight to claim.
    /// @custom:function_id 11
    function claimTemporalInsightReward(uint256 _amount) public onlyChronosmith whenNotPaused {
        require(_amount > 0, "CF: Amount must be greater than zero");
        chronosmiths[msg.sender].temporalInsight = chronosmiths[msg.sender].temporalInsight.add(_amount);
        emit TemporalInsightClaimed(msg.sender, _amount);
    }

    /// @dev Allows a Chronosmith to delegate their Temporal Insight voting power to another address.
    /// @param _delegatee The address to delegate voting power to.
    /// @custom:function_id 12
    function delegateTemporalInsight(address _delegatee) public onlyChronosmith whenNotPaused {
        require(_delegatee != address(0), "CF: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "CF: Cannot delegate to self");
        chronosmiths[msg.sender].insightDelegation = _delegatee;
        emit InsightDelegated(msg.sender, _delegatee);
    }

    /// @dev Revokes any active Temporal Insight delegation.
    /// @custom:function_id 13
    function revokeTemporalInsightDelegation() public onlyChronosmith whenNotPaused {
        require(chronosmiths[msg.sender].insightDelegation != address(0), "CF: No active delegation to revoke");
        chronosmiths[msg.sender].insightDelegation = address(0);
        emit InsightDelegationRevoked(msg.sender);
    }

    /* ====================================================================================================
                                            VIII. ChronoArtifact Forging & Evolution
    ==================================================================================================== */

    /// @dev Initiates the forging process for a new ChronoArtifact, minting a new NFT.
    ///      Requires a small ETH deposit as initial collateral.
    /// @param _initialUri The initial URI for the NFT metadata.
    /// @custom:function_id 14
    function initiateArtifactForge(string calldata _initialUri) public payable onlyChronosmith whenNotPaused returns (uint256) {
        uint256 newArtifactId = _artifactIdCounter.current().add(1);
        require(msg.value >= protocolParameters[keccak256("MIN_FORGE_COLLATERAL")], "CF: Insufficient initial collateral"); // Example parameter

        _artifactIdCounter.increment();
        _safeMint(msg.sender, newArtifactId);
        _setTokenURI(newArtifactId, _initialUri);

        chronoArtifacts[newArtifactId] = ChronoArtifact({
            tokenId: newArtifactId,
            owner: msg.sender,
            currentEpoch: ArtifactEpoch.RAW_ESSENCE,
            epochStartTime: block.timestamp,
            tokenUri: _initialUri,
            isSoulBound: false,
            initialCollateral: msg.value
        });
        // Set initial temporal properties if desired
        chronoArtifacts[newArtifactId].temporalProperties["creationTimestamp"] = Strings.toString(block.timestamp);
        chronoArtifacts[newArtifactId].temporalProperties["creator"] = Strings.toHexString(uint160(msg.sender), 20);

        emit ArtifactForgeInitiated(newArtifactId, msg.sender, _initialUri);
        return newArtifactId;
    }

    /// @dev Advances a ChronoArtifact to its next epoch if all conditions are met.
    ///      Conditions typically include time elapsed and payment of the epoch advance fee.
    /// @param _artifactId The ID of the ChronoArtifact to advance.
    /// @custom:function_id 15
    function advanceArtifactEpoch(uint256 _artifactId) public payable onlyArtifactOwner(_artifactId) whenNotPaused {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        require(artifact.currentEpoch < ArtifactEpoch.ETERNAL_FORGE, "CF: Artifact is already fully evolved");

        uint256 nextEpoch = uint256(artifact.currentEpoch) + 1;
        uint256 requiredDuration = protocolParameters[keccak256("BASE_EPOCH_DURATION")]; // Can make this epoch-specific
        uint256 requiredFee = epochAdvanceFees[nextEpoch];

        require(block.timestamp >= artifact.epochStartTime.add(requiredDuration), "CF: Epoch duration not yet met");
        require(msg.value >= requiredFee, "CF: Insufficient ETH to advance epoch");

        artifact.currentEpoch = ArtifactEpoch(nextEpoch);
        artifact.epochStartTime = block.timestamp; // Reset timer for next epoch
        // Update URI or dynamic properties based on new epoch
        artifact.temporalProperties["lastEpochAdvanceTimestamp"] = Strings.toString(block.timestamp);
        artifact.temporalProperties["currentEpochName"] = _getEpochName(ArtifactEpoch(nextEpoch));
        _setTokenURI(_artifactId, _generateArtifactURI(_artifactId)); // Update token URI to reflect new state

        emit ArtifactEpochAdvanced(_artifactId, artifact.currentEpoch, block.timestamp);
    }

    /// @dev Allows the artifact owner to set or update a dynamic "temporal property" for their artifact.
    ///      This can only be done during certain epochs or by Chronosmiths with specific Temporal Powers.
    /// @param _artifactId The ID of the ChronoArtifact.
    /// @param _propertyKey The key of the temporal property (e.g., "color", "element", "powerLevel").
    /// @param _propertyValue The value of the temporal property.
    /// @custom:function_id 16
    function attuneTemporalProperty(uint256 _artifactId, string calldata _propertyKey, string calldata _propertyValue) public onlyArtifactOwner(_artifactId) whenNotPaused {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        // Example logic: Only allowed for artifacts in CHRONAL_HEART epoch or by specific role
        require(artifact.currentEpoch >= ArtifactEpoch.CHRONAL_HEART || hasRole(ARTIFACT_FORGE_ROLE, msg.sender),
                "CF: Artifact not in attunable epoch or missing ARTIFACT_FORGE_ROLE");
        require(bytes(_propertyKey).length > 0 && bytes(_propertyValue).length > 0, "CF: Key or value cannot be empty");

        artifact.temporalProperties[_propertyKey] = _propertyValue;
        _setTokenURI(_artifactId, _generateArtifactURI(_artifactId)); // Update token URI to reflect new state

        emit TemporalPropertyAttuned(_artifactId, _propertyKey, _propertyValue);
    }

    /// @dev Allows an owner to pay an additional fee to instantly advance an artifact to its next epoch, bypassing the time-lock.
    /// @param _artifactId The ID of the ChronoArtifact.
    /// @custom:function_id 17
    function catalyzeArtifactEvolution(uint256 _artifactId) public payable onlyArtifactOwner(_artifactId) whenNotPaused {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        require(artifact.currentEpoch < ArtifactEpoch.ETERNAL_FORGE, "CF: Artifact is already fully evolved");

        uint256 nextEpoch = uint256(artifact.currentEpoch) + 1;
        uint256 requiredFee = epochAdvanceFees[nextEpoch].mul(protocolParameters[keccak256("CATALYST_FEE_MULTIPLIER")]); // Example: 2x fee
        require(msg.value >= requiredFee, "CF: Insufficient ETH for catalysis");

        ArtifactEpoch oldEpoch = artifact.currentEpoch;
        artifact.currentEpoch = ArtifactEpoch(nextEpoch);
        artifact.epochStartTime = block.timestamp; // Reset timer for next epoch
        artifact.temporalProperties["lastEpochAdvanceTimestamp"] = Strings.toString(block.timestamp);
        artifact.temporalProperties["currentEpochName"] = _getEpochName(ArtifactEpoch(nextEpoch));
        _setTokenURI(_artifactId, _generateArtifactURI(_artifactId));

        emit ArtifactCatalyzed(_artifactId, oldEpoch, artifact.currentEpoch);
    }

    /// @dev Makes a ChronoArtifact "Soul-Bound" (non-transferable and tied to the current owner's address).
    ///      This is a permanent action.
    /// @param _artifactId The ID of the ChronoArtifact.
    /// @custom:function_id 18
    function bondArtifactToSoul(uint256 _artifactId) public onlyArtifactOwner(_artifactId) whenNotPaused {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        require(!artifact.isSoulBound, "CF: Artifact is already Soul-Bound");
        // Optional: require certain epoch or Chronosmith insight level
        // require(artifact.currentEpoch >= ArtifactEpoch.ASTRAL_CORE, "CF: Artifact not mature enough for soul-binding");

        artifact.isSoulBound = true;
        emit ArtifactBondedToSoul(_artifactId, msg.sender);
    }

    /// @dev Allows an artifact owner to "retire" (burn) their fully evolved artifact,
    ///      potentially claiming a final reward or unlocking an on-chain achievement.
    /// @param _artifactId The ID of the ChronoArtifact to retire.
    /// @custom:function_id 19
    function retireArtifact(uint256 _artifactId) public onlyArtifactOwner(_artifactId) whenNotPaused {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        require(artifact.currentEpoch == ArtifactEpoch.ETERNAL_FORGE, "CF: Artifact not fully evolved for retirement");

        // Optional: Provide a final reward, e.g., transfer some ETH or mint a special token
        // (bool success, ) = msg.sender.call{value: artifact.initialCollateral.mul(2)}(""); // Example: 2x initial collateral
        // require(success, "CF: Reward transfer failed");

        _burn(_artifactId);
        delete chronoArtifacts[_artifactId]; // Clean up storage
        emit ArtifactRetired(_artifactId, msg.sender);
    }

    /// @dev Allows the owner to retrieve initial ETH collateral if forging is cancelled or fails.
    ///      Conditions could include not meeting epoch advancement deadlines.
    /// @param _artifactId The ID of the ChronoArtifact.
    /// @custom:function_id 20
    function retrieveForgingCollateral(uint256 _artifactId) public onlyArtifactOwner(_artifactId) whenNotPaused {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        require(artifact.initialCollateral > 0, "CF: No collateral to retrieve");
        // Example condition: If artifact hasn't advanced from RAW_ESSENCE within a week
        require(artifact.currentEpoch == ArtifactEpoch.RAW_ESSENCE && block.timestamp > artifact.epochStartTime.add(7 days),
                "CF: Collateral can only be retrieved if forging stalled at RAW_ESSENCE");

        uint256 amountToRetrieve = artifact.initialCollateral;
        artifact.initialCollateral = 0; // Prevent re-retrieval
        (bool success, ) = msg.sender.call{value: amountToRetrieve}("");
        require(success, "CF: Collateral transfer failed");
        emit ForgingCollateralRetrieved(_artifactId, msg.sender, amountToRetrieve);
    }

    /* ====================================================================================================
                                            IX. Temporal Challenges & On-Chain Quests
    ==================================================================================================== */

    /// @dev Allows Chronosmiths with sufficient Temporal Insight or CHALLENGE_PROPOSER_ROLE to propose new challenges.
    /// @param _challengeUri URI pointing to off-chain details of the challenge.
    /// @param _insightReward The Temporal Insight reward upon completion.
    /// @custom:function_id 21
    function proposeTemporalChallenge(string calldata _challengeUri, uint256 _insightReward) public onlyChronosmith whenNotPaused returns (uint256) {
        require(chronosmiths[msg.sender].temporalInsight >= protocolParameters[keccak256("MIN_CHALLENGE_INSIGHT_PROPOSAL")] ||
                hasRole(CHALLENGE_PROPOSER_ROLE, msg.sender),
                "CF: Insufficient Temporal Insight or missing CHALLENGE_PROPOSER_ROLE to propose");

        uint256 newChallengeId = _challengeIdCounter.current().add(1);
        _challengeIdCounter.increment();

        temporalChallenges[newChallengeId] = TemporalChallenge({
            id: newChallengeId,
            challengeUri: _challengeUri,
            proposer: msg.sender,
            insightReward: _insightReward,
            status: ChallengeStatus.VOTING, // Challenges start in voting phase
            proposalTimestamp: block.timestamp,
            requiredInsightToPropose: protocolParameters[keccak256("MIN_CHALLENGE_INSIGHT_PROPOSAL")],
            completionTimestamp: 0,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        emit ChallengeProposed(newChallengeId, msg.sender, _challengeUri, _insightReward);
        return newChallengeId;
    }

    /// @dev Allows Chronosmiths (weighted by Temporal Insight) to vote on proposed challenges.
    /// @param _challengeId The ID of the challenge proposal.
    /// @param _approve True for approval, false for rejection.
    /// @custom:function_id 22
    function voteOnChallengeProposal(uint256 _challengeId, bool _approve) public onlyChronosmith whenNotPaused {
        TemporalChallenge storage challenge = temporalChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.VOTING, "CF: Challenge not in voting phase");
        require(block.timestamp <= challenge.proposalTimestamp.add(protocolParameters[keccak256("CHALLENGE_VOTING_PERIOD")]), "CF: Voting period ended");
        require(!challenge.hasVoted[msg.sender], "CF: Already voted on this challenge");

        uint256 voterInsight = chronosmiths[msg.sender].temporalInsight;
        if (chronosmiths[msg.sender].insightDelegation != address(0)) {
            voterInsight = chronosmiths[chronosmiths[msg.sender].insightDelegation].temporalInsight;
        }
        require(voterInsight > 0, "CF: Must have Temporal Insight to vote");

        if (_approve) {
            challenge.votesFor = challenge.votesFor.add(voterInsight);
        } else {
            challenge.votesAgainst = challenge.votesAgainst.add(voterInsight);
        }
        challenge.hasVoted[msg.sender] = true;

        emit ChallengeVoted(_challengeId, msg.sender, _approve, challenge.votesFor, challenge.votesAgainst);

        // Simple majority voting to decide status after voting period or if enough votes
        if (block.timestamp > challenge.proposalTimestamp.add(protocolParameters[keccak256("CHALLENGE_VOTING_PERIOD")]) ||
            (challenge.votesFor.add(challenge.votesAgainst) >= protocolParameters[keccak256("MIN_VOTES_TO_CLOSE")]) // Example parameter
            ) {
            if (challenge.votesFor > challenge.votesAgainst) {
                challenge.status = ChallengeStatus.ACTIVE;
            } else {
                challenge.status = ChallengeStatus.REJECTED;
            }
        }
    }

    /// @dev Allows a Chronosmith to mark a challenge as completed and claim rewards.
    ///      This function would typically require proof of completion (e.g., meeting on-chain conditions,
    ///      or verification by a CHALLENGE_VALIDATOR_ROLE).
    /// @param _challengeId The ID of the challenge to complete.
    /// @custom:function_id 23
    function completeTemporalChallenge(uint256 _challengeId) public onlyChronosmith whenNotPaused {
        TemporalChallenge storage challenge = temporalChallenges[_challengeId];
        require(challenge.status == ChallengeStatus.ACTIVE, "CF: Challenge is not active");

        // ---
        // IMPORTANT: This is a placeholder for actual challenge completion logic.
        // Real-world challenges would involve:
        // 1. On-chain proof verification (e.g., user holding a specific NFT, burning a token, reaching a certain score).
        // 2. Or, requiring CHALLENGE_VALIDATOR_ROLE to call this function after off-chain verification.
        // For this example, we'll assume a `CHALLENGE_VALIDATOR_ROLE` is needed to mark it completed.
        require(hasRole(CHALLENGE_VALIDATOR_ROLE, msg.sender), "CF: Only a Challenge Validator can complete this");
        // ---

        challenge.status = ChallengeStatus.COMPLETED;
        challenge.completionTimestamp = block.timestamp;

        // Reward the completer with Temporal Insight
        chronosmiths[msg.sender].temporalInsight = chronosmiths[msg.sender].temporalInsight.add(challenge.insightReward);

        emit ChallengeCompleted(_challengeId, msg.sender, challenge.insightReward);
    }

    /* ====================================================================================================
                                            X. View Functions
    ==================================================================================================== */

    /// @dev Returns the details of a Chronosmith profile.
    /// @param _chronosmithAddress The address of the Chronosmith.
    /// @return A tuple containing the profile details.
    function getChronosmithProfile(address _chronosmithAddress) public view returns (bool registered, string memory bioUri, uint256 temporalInsight, address insightDelegation) {
        ChronosmithProfile storage profile = chronosmiths[_chronosmithAddress];
        return (profile.registered, profile.bioUri, profile.temporalInsight, profile.insightDelegation);
    }

    /// @dev Returns the details of a ChronoArtifact.
    /// @param _artifactId The ID of the ChronoArtifact.
    /// @return A tuple containing the artifact details.
    function getArtifactDetails(uint256 _artifactId) public view returns (uint256 tokenId, address owner, ArtifactEpoch currentEpoch, uint256 epochStartTime, string memory tokenUri, bool isSoulBound, uint256 initialCollateral) {
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        require(_exists(_artifactId), "CF: Artifact does not exist");
        return (artifact.tokenId, artifact.owner, artifact.currentEpoch, artifact.epochStartTime, artifact.tokenUri, artifact.isSoulBound, artifact.initialCollateral);
    }

    /// @dev Returns a specific temporal property of an artifact.
    /// @param _artifactId The ID of the ChronoArtifact.
    /// @param _propertyKey The key of the property.
    /// @return The value of the property.
    function getArtifactTemporalProperty(uint256 _artifactId, string memory _propertyKey) public view returns (string memory) {
        require(_exists(_artifactId), "CF: Artifact does not exist");
        return chronoArtifacts[_artifactId].temporalProperties[_propertyKey];
    }

    /// @dev Returns the details of a Temporal Challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return A tuple containing the challenge details.
    function getChallengeDetails(uint256 _challengeId) public view returns (uint256 id, string memory challengeUri, address proposer, uint256 insightReward, ChallengeStatus status, uint256 proposalTimestamp, uint256 completionTimestamp, uint256 votesFor, uint256 votesAgainst) {
        TemporalChallenge storage challenge = temporalChallenges[_challengeId];
        require(_challengeId > 0 && _challengeId <= _challengeIdCounter.current(), "CF: Invalid challenge ID");
        return (challenge.id, challenge.challengeUri, challenge.proposer, challenge.insightReward, challenge.status, challenge.proposalTimestamp, challenge.completionTimestamp, challenge.votesFor, challenge.votesAgainst);
    }

    /// @dev Internal helper to generate a dynamic token URI based on artifact properties.
    ///      This would typically point to an API endpoint that renders JSON metadata.
    /// @param _artifactId The ID of the artifact.
    /// @return The generated token URI.
    function _generateArtifactURI(uint256 _artifactId) internal view returns (string memory) {
        // In a real dApp, this would fetch attributes and construct a JSON, then base64 encode it, or point to an IPFS/HTTP endpoint.
        // For simplicity, we just append current epoch and some property to a base URI.
        ChronoArtifact storage artifact = chronoArtifacts[_artifactId];
        string memory base = artifact.tokenUri; // Assuming tokenUri holds a base prefix like "ipfs://..."
        string memory epochName = _getEpochName(artifact.currentEpoch);
        // Example: "ipfs://baseUri/123_ETERNAL_FORGE.json?color=red"
        return string(abi.encodePacked(base, Strings.toString(_artifactId), "_", epochName, ".json"));
    }

    /// @dev Internal helper to get the string representation of an ArtifactEpoch.
    /// @param _epoch The ArtifactEpoch enum value.
    /// @return The string name of the epoch.
    function _getEpochName(ArtifactEpoch _epoch) internal pure returns (string memory) {
        if (_epoch == ArtifactEpoch.RAW_ESSENCE) return "RAW_ESSENCE";
        if (_epoch == ArtifactEpoch.TEMPORAL_SEED) return "TEMPORAL_SEED";
        if (_epoch == ArtifactEpoch.CHRONAL_HEART) return "CHRONAL_HEART";
        if (_epoch == ArtifactEpoch.ASTRAL_CORE) return "ASTRAL_CORE";
        if (_epoch == ArtifactEpoch.ETERNAL_FORGE) return "ETERNAL_FORGE";
        return "UNKNOWN_EPOCH";
    }

    /// @dev Overrides `_beforeTokenTransfer` to implement Soul-Bound logic.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (chronoArtifacts[tokenId].isSoulBound) {
            require(from == address(0) || to == address(0), "CF: Soul-bound artifacts are non-transferable."); // Allow minting (from 0) and burning (to 0)
        }
    }

    /// @dev Overrides `tokenURI` to provide dynamic URI based on artifact state.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId); // Ensure the token exists
        return _generateArtifactURI(tokenId);
    }

    /// @dev Fallback function to receive ETH for fees/collateral.
    receive() external payable {}
    fallback() external payable {}
}
```