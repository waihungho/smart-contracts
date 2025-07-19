Okay, this is an exciting challenge! Creating something truly unique and advanced in Solidity, especially avoiding open-source duplication, requires combining several cutting-edge concepts.

My idea is **"AuraForge Protocol: Skill-Bound Dynamic NFTs with ZKP-Verified Progression & Contextual Yield"**.

This protocol aims to create NFTs that are not merely static assets but dynamically evolve based on a holder's proven skills and contributions within a decentralized ecosystem. These skills are verified using Zero-Knowledge Proofs (ZKPs) submitted by users, and the NFT's "Aura" (reputation score) directly influences its visual appearance, utility, and ability to generate contextual yield. It also incorporates elements of decentralized task networks and on-chain governance influenced by proven skill.

---

## AuraForge Protocol: Skill-Bound Dynamic NFTs

**Contract Name:** `AuraForgeNFT`

**Core Concept:**
Dynamic NFTs (`AuraForgeNFT`) evolve based on verifiable on-chain and off-chain contributions, proven via Zero-Knowledge Proofs (ZKPs). These proofs increment an NFT's "Aura Points," which dictate its "Aura Level." Higher Aura Levels unlock visual traits, increase contextual yield from a shared pool, and grant voting power in protocol governance. The system includes mechanisms for Aura decay, skill-tier progression, and a dispute resolution system for proofs.

**Advanced Concepts & Unique Features:**

1.  **ZK-Proof Verified Progression:** The core mechanism for NFT upgrades and Aura accrual is the submission and on-chain verification of Zero-Knowledge Proofs (ZKP). This allows users to prove complex off-chain computations, private data, or task completions without revealing the underlying information. (Note: A full ZKP verifier is a separate, complex contract; this contract will interface with a mock/placeholder verifier.)
2.  **Dynamic Aura & Reputation System:** NFTs accrue "Aura Points" which are subject to decay over time (preventing stagnation and encouraging continuous engagement). These points map to "Aura Levels," dynamically changing the NFT's properties and metadata.
3.  **Skill-Bound Contextual Yield:** The NFT's yield is not fixed but dynamically calculated based on its Aura Level, specific "Skill Tracks" it has unlocked, and potentially active contributions. This yield comes from a protocol-managed reward pool.
4.  **Decentralized Task Network Integration (Implicit):** While not a full task marketplace, the concept relies on users completing tasks (e.g., AI model training, data validation, scientific computation) whose completion can be attested via ZKPs.
5.  **Autonomous Agent "Proxy" NFTs:** NFTs can be registered as "Skill Agents" for specific automated tasks, and their Aura/Skill level can influence their effectiveness or reward share.
6.  **On-Chain Governable Traits & Levels:** Parameters like Aura decay rates, Aura Level thresholds, and their associated yield multipliers can be adjusted via protocol governance (using NFT Aura as voting power).
7.  **Dynamic Metadata Rendering:** The `tokenURI` will reflect the NFT's current Aura Level, unlocked Skill Tracks, and other dynamic attributes, necessitating an off-chain metadata renderer that queries the contract state.
8.  **Dispute Mechanism for ZKPs:** A way to challenge fraudulent ZK-proof submissions, introducing a layer of oversight.
9.  **Liquid Aura Staking:** Users can temporarily "stake" their NFT's Aura points to gain short-term boosts or access specific features, which might affect its decay rate or yield.

---

### Outline and Function Summary

**I. Core NFT Management (ERC721-like base)**
*   `constructor()`: Initializes the contract with base URI, ZK verifier, and owner.
*   `mintSkillboundNFT(address _to, string memory _initialMetadataSuffix)`: Mints a new NFT, potentially requiring an initial ZKP or a small fee.
*   `burnAuraForgeNFT(uint256 _tokenId)`: Allows the owner or an authorized party to burn an NFT (e.g., for non-compliance or if its Aura decays too low).
*   `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI reflecting the NFT's current state (Aura, Skill, etc.).
*   `setBaseURI(string memory _newBaseURI)`: Sets the base URI for metadata.

**II. Aura & Reputation System**
*   `getAuraPoints(uint256 _tokenId)`: Returns the current Aura points for an NFT, accounting for decay.
*   `getAuraLevel(uint256 _tokenId)`: Returns the current Aura Level based on calculated Aura points.
*   `_updateAura(uint256 _tokenId, int256 _amount)` (Internal): Helper to add/subtract Aura, updates `_lastAuraUpdateTimestamp`.
*   `proposeAuraDecayRate(uint256 _newDecayRatePerYear)`: Initiates a governance proposal to change the global Aura decay rate.
*   `setAuraLevelThresholds(uint256[] memory _thresholds, string[] memory _levelNames, uint256[] memory _yieldMultipliers)`: Allows governance to define Aura Level thresholds and their properties.

**III. ZK-Proof & Skill Progression**
*   `submitSkillProof(uint256 _tokenId, bytes memory _proof, bytes memory _publicInputs, uint256 _skillTrackId)`: User submits a ZKP to prove a skill/task completion for a specific NFT, triggering Aura increment.
*   `setZkVerifierContract(address _newVerifier)`: Sets the address of the on-chain ZKP verifier contract.
*   `_verifyZkProof(bytes memory _proof, bytes memory _publicInputs)` (Internal): Calls the external ZKP verifier contract.
*   `registerSkillTrack(uint256 _skillTrackId, string memory _name, uint256 _auraRewardOnProof, address _associatedOracle)`: Registers a new skill track with its associated Aura reward and an oracle for dispute.
*   `challengeSkillProof(uint256 _tokenId, bytes32 _proofHash, string memory _reason)`: Allows anyone to challenge a previously submitted ZKP for an NFT, potentially freezing its Aura and yield.
*   `resolveChallenge(uint256 _tokenId, bytes32 _proofHash, bool _isValid, string memory _resolutionNote)`: Only an authorized `_associatedOracle` (or governance) can resolve a challenge, restoring or penalizing Aura.

**IV. Contextual Yield & Reward Distribution**
*   `depositReward(uint256 _amount)`: Allows external entities (or the protocol) to deposit funds into the shared reward pool.
*   `getPendingYield(uint256 _tokenId)`: Calculates and returns the yield accrued for a specific NFT based on its Aura, skill tracks, and time.
*   `claimSkillYield(uint256 _tokenId)`: Allows the NFT owner to claim their accumulated yield.
*   `stakeAuraForBoost(uint256 _tokenId, uint256 _amountToStake)`: Allows users to temporarily "stake" a portion of their NFT's Aura for a short-term boost (e.g., higher yield, access to features). This might affect decay calculation.
*   `unstakeAuraForBoost(uint256 _tokenId)`: Unstakes previously staked Aura.

**V. Dynamic Properties & Agents**
*   `setTraitModifierURI(uint256 _auraLevel, string memory _traitSuffix)`: Allows governance to map Aura Levels to specific metadata suffixes for dynamic visual changes.
*   `registerSkillAgent(uint256 _tokenId, string memory _agentType, bytes memory _agentConfig)`: Registers an NFT as an "autonomous skill agent" for specific tasks, potentially unlocking specialized yield or roles.
*   `updateAgentConfig(uint256 _tokenId, bytes memory _newConfig)`: Updates configuration for a registered skill agent.

**VI. Governance & Protocol Administration**
*   `pauseContract()`: Pauses core contract functionalities in emergencies.
*   `unpauseContract()`: Unpauses the contract.
*   `emergencyWithdraw(address _tokenAddress, uint256 _amount)`: Allows emergency withdrawal of funds by owner (e.g., in case of a critical bug or exploit).
*   `proposeProtocolUpgrade(address _newImplementation)`: Initiates a governance proposal for a proxy contract upgrade. (Requires an external UUPS/Transparent Proxy for actual implementation).
*   `castAuraVote(uint256 _tokenId, bytes32 _proposalHash, bool _support)`: Allows an NFT holder to vote on proposals using their NFT's current Aura as voting power.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Mock interface for an external ZK Proof Verifier contract
// In a real scenario, this would be a specific verifier for Groth16, Plonk, etc.
interface IZKProofVerifier {
    function verify(
        bytes memory _proof,
        bytes memory _publicInputs
    ) external view returns (bool);
}

contract AuraForgeNFT is ERC721, Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for minting new NFTs

    // Aura Points: Raw points accumulated by an NFT
    mapping(uint256 => uint256) private _auraPoints;
    // Timestamp of the last Aura update or claim, used for decay calculation
    mapping(uint256 => uint256) private _lastAuraUpdateTimestamp;
    // Amount of Aura currently staked for boosts
    mapping(uint256 => uint256) private _stakedAuraAmount;

    // Aura Decay Rate: Points lost per year (scaled by 1e18 for precision)
    uint256 public auraDecayRatePerYear = 1e18 / 10; // Default: 10% decay per year

    // Aura Levels: Defines thresholds, names, and yield multipliers for each level
    struct AuraLevel {
        uint256 threshold;         // Minimum Aura points to reach this level
        string name;               // Name of the level (e.g., "Novice", "Expert")
        uint256 yieldMultiplier;   // Multiplier for yield calculation (scaled by 1e18)
        string metadataSuffix;     // Suffix for tokenURI to indicate visual trait
    }
    AuraLevel[] public auraLevels; // Array of AuraLevel structs, sorted by threshold

    // Skill Tracks: Defines how Aura is gained from proofs and associated oracles
    struct SkillTrack {
        string name;               // Name of the skill track (e.g., "AI Model Training", "Data Validation")
        uint256 auraRewardOnProof; // Aura points awarded upon successful proof verification
        address associatedOracle;  // Address of the trusted oracle or multi-sig for this track
        bool active;               // Whether the skill track is active
    }
    mapping(uint256 => SkillTrack) public skillTracks;
    uint256 private _nextSkillTrackId; // Counter for new skill tracks

    // ZK Proof Verification: External verifier contract
    IZKProofVerifier public zkVerifier;

    // Challenge System: For disputing ZK proofs
    struct Challenge {
        uint256 tokenId;
        bytes32 proofHash;
        string reason;
        address challenger;
        uint256 challengeTimestamp;
        bool resolved;
        bool isValidProof; // True if proof was deemed valid after resolution
        string resolutionNote;
    }
    // Mapping from proof hash to active challenge (only one challenge per proof hash)
    mapping(bytes32 => Challenge) public activeChallenges;
    // Mapping to track if a specific proof hash has ever been submitted
    mapping(bytes32 => bool) private _submittedProofHashes;

    // Protocol Reward Pool: Funds deposited here are distributed as yield
    uint256 public totalRewardPool;
    // Mapping to track accumulated yield for each NFT
    mapping(uint256 => uint256) private _pendingYield;
    // Timestamp of the last yield claim for each NFT
    mapping(uint256 => uint256) private _lastYieldClaimTimestamp;

    // Skill Agents: NFTs registered to act as autonomous agents
    struct SkillAgent {
        string agentType; // e.g., "DataValidatorBot", "AIResearcher"
        bytes config;     // Arbitrary configuration bytes for the agent
        bool registered;
    }
    mapping(uint256 => SkillAgent) public skillAgents;

    // Governance: Simple proposal tracking for Aura-based voting
    struct Proposal {
        bytes32 proposalHash;
        uint256 totalAuraVotesFor;
        uint256 totalAuraVotesAgainst;
        mapping(uint256 => bool) hasVoted; // tokenId => voted
        bool executed;
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
    }
    mapping(bytes32 => Proposal) public proposals;
    uint256 public votingPeriodDuration = 3 days; // Default voting period

    // --- Events ---

    event AuraPointsUpdated(uint256 indexed tokenId, int256 amount, uint256 newAuraPoints, string reason);
    event AuraLevelChanged(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel, string newLevelName);
    event SkillProofSubmitted(uint256 indexed tokenId, uint256 skillTrackId, bytes32 proofHash, uint256 auraAwarded);
    event AuraDecayRateProposed(uint256 newRate);
    event AuraDecayRateSet(uint256 newRate);
    event AuraLevelThresholdsSet(uint256[] thresholds);
    event RewardDeposited(address indexed depositor, uint256 amount);
    event YieldClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount);
    event SkillTrackRegistered(uint256 indexed skillTrackId, string name, uint256 auraReward, address associatedOracle);
    event SkillProofChallenge(uint256 indexed tokenId, bytes32 indexed proofHash, address indexed challenger, string reason);
    event ChallengeResolved(uint256 indexed tokenId, bytes32 indexed proofHash, bool isValid, string resolutionNote);
    event AuraStakedForBoost(uint256 indexed tokenId, uint256 amountStaked);
    event AuraUnstakedFromBoost(uint256 indexed tokenId, uint256 amountUnstaked);
    event SkillAgentRegistered(uint256 indexed tokenId, string agentType);
    event SkillAgentConfigUpdated(uint256 indexed tokenId);
    event ProtocolUpgradeProposed(address indexed newImplementation);
    event AuraVoteCast(uint256 indexed tokenId, bytes32 indexed proposalHash, bool support, uint256 auraVotingPower);

    // --- Modifiers ---

    modifier onlySkillTrackOracle(uint256 _skillTrackId) {
        require(skillTracks[_skillTrackId].active, "Skill track not active");
        require(msg.sender == skillTracks[_skillTrackId].associatedOracle, "Caller is not the associated oracle for this track");
        _;
    }

    modifier onlyZkVerifier() {
        require(msg.sender == address(zkVerifier), "Only ZK Verifier can call this");
        _;
    }

    // --- Constructor ---

    constructor(address _zkVerifierAddress, string memory _baseURI)
        ERC721("AuraForgeNFT", "AFNFT")
        Ownable(msg.sender)
    {
        require(_zkVerifierAddress != address(0), "ZK Verifier address cannot be zero");
        zkVerifier = IZKProofVerifier(_zkVerifierAddress);
        _setBaseURI(_baseURI);

        // Initialize default Aura levels (example)
        auraLevels.push(AuraLevel(0, "Initiate", 1e18, "lvl_init.json")); // 0 points, 1x yield
        auraLevels.push(AuraLevel(100, "Apprentice", 1_1e18, "lvl_app.json")); // 100 points, 1.1x yield
        auraLevels.push(AuraLevel(500, "Journeyman", 1_25e18, "lvl_jour.json")); // 500 points, 1.25x yield
        auraLevels.push(AuraLevel(1000, "Master", 1_5e18, "lvl_master.json")); // 1000 points, 1.5x yield
    }

    // --- Internal Helpers ---

    function _calculateAuraDecay(uint256 _tokenId) internal view returns (uint256) {
        if (_lastAuraUpdateTimestamp[_tokenId] == 0) return 0; // No decay for new NFTs
        uint256 timeElapsed = block.timestamp - _lastAuraUpdateTimestamp[_tokenId];
        uint256 currentAura = _auraPoints[_tokenId];
        // Decay formula: Aura * (1 - decayRate * timeElapsed / 1 year)
        // Scaled arithmetic for precision
        uint256 decayAmount = (currentAura * auraDecayRatePerYear * timeElapsed) / (1e18 * 1 years);
        return decayAmount;
    }

    function _getRawAuraPoints(uint256 _tokenId) internal view returns (uint256) {
        return _auraPoints[_tokenId];
    }

    function _updateAura(uint256 _tokenId, int256 _amount, string memory _reason) internal {
        uint256 currentAura = getAuraPoints(_tokenId); // Get current aura after decay
        uint256 oldLevel = getAuraLevel(_tokenId);

        // Apply _amount to the already decayed currentAura
        uint256 newRawAura;
        if (_amount < 0) {
            newRawAura = currentAura > uint256(-_amount) ? currentAura - uint256(-_amount) : 0;
        } else {
            newRawAura = currentAura + uint256(_amount);
        }

        _auraPoints[_tokenId] = newRawAura; // Update the raw points directly
        _lastAuraUpdateTimestamp[_tokenId] = block.timestamp; // Reset decay timer

        uint256 newLevel = getAuraLevel(_tokenId);
        emit AuraPointsUpdated(_tokenId, _amount, newRawAura, _reason);
        if (newLevel != oldLevel) {
            emit AuraLevelChanged(_tokenId, oldLevel, newLevel, auraLevels[newLevel].name);
            // Trigger metadata update (e.g., via IPFS CID change in tokenURI)
            _setTokenURI(_tokenId, tokenURI(_tokenId)); // This effectively signals a change
        }
    }

    // --- I. Core NFT Management ---

    function mintSkillboundNFT(address _to, string memory _initialMetadataSuffix)
        public
        whenNotPaused
        returns (uint256)
    {
        require(_to != address(0), "Mint to zero address");
        _nextTokenId++;
        uint256 tokenId = _nextTokenId;
        _safeMint(_to, tokenId);
        // Initial aura points can be zero or a small base
        _auraPoints[tokenId] = 0;
        _lastAuraUpdateTimestamp[tokenId] = block.timestamp; // Set initial timestamp
        _lastYieldClaimTimestamp[tokenId] = block.timestamp; // Set initial yield claim time
        emit AuraPointsUpdated(tokenId, 0, 0, "Initial Mint");
        _setTokenURI(tokenId, _baseURI() + tokenId.toString() + _initialMetadataSuffix + ".json");
        return tokenId;
    }

    function burnAuraForgeNFT(uint256 _tokenId)
        public
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _burn(_tokenId);
        // Clean up associated data
        delete _auraPoints[_tokenId];
        delete _lastAuraUpdateTimestamp[_tokenId];
        delete _stakedAuraAmount[_tokenId];
        delete _pendingYield[_tokenId];
        delete _lastYieldClaimTimestamp[_tokenId];
        if (skillAgents[_tokenId].registered) {
            delete skillAgents[_tokenId];
        }
        // Potentially remove from ongoing challenges if any (would need more complex logic)
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        uint256 currentAuraLevel = getAuraLevel(_tokenId);
        string memory levelSuffix = auraLevels[currentAuraLevel].metadataSuffix;

        // The actual URI would likely point to an off-chain renderer/gateway that
        // uses the token's on-chain state to dynamically generate JSON and image.
        // Example: https://auraforge.io/metadata/{tokenId}?level={currentAuraLevel}&skilltrack={unlockedSkillTracks}
        // For simplicity here, we concatenate base URI + token ID + level suffix.
        return string.concat(
            _baseURI(),
            _tokenId.toString(),
            "_",
            levelSuffix
        );
    }

    function setBaseURI(string memory _newBaseURI)
        public
        onlyOwner
    {
        _setBaseURI(_newBaseURI);
    }

    // --- II. Aura & Reputation System ---

    function getAuraPoints(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(_tokenId), "Token does not exist");
        if (activeChallenges[keccak256(abi.encodePacked(_tokenId))].resolved == false && activeChallenges[keccak256(abi.encodePacked(_tokenId))].tokenId == _tokenId) {
            // If there's an active challenge on this token, freeze its Aura calculation.
            // This is a simplified check; a real system might freeze specific proofs or the entire Aura.
            return _auraPoints[_tokenId];
        }

        uint256 rawAura = _auraPoints[_tokenId];
        uint256 decayAmount = _calculateAuraDecay(_tokenId);

        if (rawAura <= decayAmount) {
            return 0; // Aura cannot go negative
        }
        return rawAura - decayAmount;
    }

    function getAuraLevel(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 currentAura = getAuraPoints(_tokenId);
        uint256 currentLevel = 0;
        for (uint256 i = 0; i < auraLevels.length; i++) {
            if (currentAura >= auraLevels[i].threshold) {
                currentLevel = i;
            } else {
                break; // Levels are sorted, so we can stop
            }
        }
        return currentLevel;
    }

    function proposeAuraDecayRate(uint256 _newDecayRatePerYear)
        public
        onlyOwner // Can be replaced by full DAO logic
    {
        // In a full DAO, this would create a proposal that Aura-holding NFTs vote on.
        // For this example, owner directly proposes, and owner needs to execute.
        auraDecayRatePerYear = _newDecayRatePerYear; // Direct set for simplicity
        emit AuraDecayRateProposed(_newDecayRatePerYear);
    }

    function setAuraLevelThresholds(
        uint256[] memory _thresholds,
        string[] memory _levelNames,
        uint256[] memory _yieldMultipliers,
        string[] memory _metadataSuffixes
    )
        public
        onlyOwner // This would be a governance-controlled function in a real DAO
    {
        require(
            _thresholds.length == _levelNames.length &&
            _thresholds.length == _yieldMultipliers.length &&
            _thresholds.length == _metadataSuffixes.length,
            "Array lengths must match"
        );
        require(_thresholds.length > 0, "Must define at least one level");
        
        // Ensure thresholds are sorted ascending
        for (uint256 i = 0; i < _thresholds.length; i++) {
            if (i > 0) {
                require(_thresholds[i] > _thresholds[i-1], "Thresholds must be strictly increasing");
            }
        }

        delete auraLevels; // Clear existing levels
        for (uint256 i = 0; i < _thresholds.length; i++) {
            auraLevels.push(AuraLevel(_thresholds[i], _levelNames[i], _yieldMultipliers[i], _metadataSuffixes[i]));
        }
        emit AuraLevelThresholdsSet(_thresholds);
    }

    // --- III. ZK-Proof & Skill Progression ---

    function submitSkillProof(
        uint256 _tokenId,
        bytes memory _proof,
        bytes memory _publicInputs,
        uint256 _skillTrackId
    )
        public
        nonReentrant
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(_exists(_tokenId), "NFT does not exist");
        require(skillTracks[_skillTrackId].active, "Skill track not active or found");
        
        bytes32 proofHash = keccak256(abi.encodePacked(_proof, _publicInputs, _skillTrackId));
        require(!_submittedProofHashes[proofHash], "Proof already submitted or challenged");

        // Check for active challenges on this token
        require(activeChallenges[keccak256(abi.encodePacked(_tokenId))].resolved || activeChallenges[keccak256(abi.encodePacked(_tokenId))].tokenId == 0, "Token has an unresolved challenge");

        bool verified = zkVerifier.verify(_proof, _publicInputs);
        require(verified, "ZK Proof verification failed");

        _submittedProofHashes[proofHash] = true;
        _updateAura(_tokenId, int256(skillTracks[_skillTrackId].auraRewardOnProof), "Skill Proof Verified");
        emit SkillProofSubmitted(_tokenId, _skillTrackId, proofHash, skillTracks[_skillTrackId].auraRewardOnProof);
    }

    function setZkVerifierContract(address _newVerifier)
        public
        onlyOwner
    {
        require(_newVerifier != address(0), "New ZK Verifier address cannot be zero");
        zkVerifier = IZKProofVerifier(_newVerifier);
    }

    function registerSkillTrack(
        string memory _name,
        uint256 _auraRewardOnProof,
        address _associatedOracle
    )
        public
        onlyOwner // This would be governance-controlled in a real DAO
        returns (uint256)
    {
        _nextSkillTrackId++;
        skillTracks[_nextSkillTrackId] = SkillTrack({
            name: _name,
            auraRewardOnProof: _auraRewardOnProof,
            associatedOracle: _associatedOracle,
            active: true
        });
        emit SkillTrackRegistered(_nextSkillTrackId, _name, _auraRewardOnProof, _associatedOracle);
        return _nextSkillTrackId;
    }

    function deactivateSkillTrack(uint256 _skillTrackId) public onlyOwner {
        require(skillTracks[_skillTrackId].active, "Skill track already inactive");
        skillTracks[_skillTrackId].active = false;
    }

    function activateSkillTrack(uint256 _skillTrackId) public onlyOwner {
        require(!skillTracks[_skillTrackId].active, "Skill track already active");
        skillTracks[_skillTrackId].active = true;
    }

    function challengeSkillProof(uint256 _tokenId, bytes32 _proofHash, string memory _reason)
        public
        whenNotPaused
    {
        require(_exists(_tokenId), "NFT does not exist");
        require(_submittedProofHashes[_proofHash], "Proof hash not found or not submitted");
        require(activeChallenges[_proofHash].tokenId == 0, "Proof already under challenge"); // Check if this specific proof is challenged

        // Optional: Implement a bond requirement for challengers to prevent spam
        activeChallenges[_proofHash] = Challenge({
            tokenId: _tokenId,
            proofHash: _proofHash,
            reason: _reason,
            challenger: msg.sender,
            challengeTimestamp: block.timestamp,
            resolved: false,
            isValidProof: false, // Default to false until resolved
            resolutionNote: ""
        });
        
        // Temporarily freeze Aura recalculation for this token (checked in getAuraPoints)
        // A more granular system might just freeze the impact of the disputed proof.
        emit SkillProofChallenge(_tokenId, _proofHash, msg.sender, _reason);
    }

    function resolveChallenge(bytes32 _proofHash, bool _isValid, string memory _resolutionNote)
        public
        nonReentrant
        whenNotPaused
    {
        Challenge storage challenge = activeChallenges[_proofHash];
        require(challenge.tokenId != 0, "No active challenge found for this proof hash");
        require(!challenge.resolved, "Challenge already resolved");
        
        // Only the associated oracle of the skill track (or owner/governance) can resolve.
        // This requires getting the original skillTrackId from the proof data, which isn't
        // directly available from just the hash, so we'll simplify and say `onlyOwner`
        // or a specific `resolveOracle`.
        // For this example, let's assume `onlyOwner` resolves, or we need to pass skillTrackId to challenge
        // and resolve functions. Let's make it `onlyOwner` for simplicity given the constraints.
        require(msg.sender == owner(), "Only owner can resolve challenges");

        challenge.resolved = true;
        challenge.isValidProof = _isValid;
        challenge.resolutionNote = _resolutionNote;

        if (!_isValid) {
            // If proof is invalid, penalize Aura
            // This is complex: need to revert the specific Aura awarded by this proof
            // Simplification: Apply a general penalty or set Aura to zero if severe.
            uint256 tokenId = challenge.tokenId;
            // A more robust system would involve logging previous Aura additions and reverting specific ones.
            // For now, let's apply a fixed penalty or revert all Aura from that specific skill track.
            // Let's assume a fixed penalty for simplicity.
            uint256 penaltyAmount = 100; // Example fixed penalty
            if (getAuraPoints(tokenId) >= penaltyAmount) {
                 _updateAura(tokenId, -int256(penaltyAmount), "Penalty for Invalid Proof");
            } else {
                 _updateAura(tokenId, -int256(getAuraPoints(tokenId)), "Penalty for Invalid Proof (Set to 0)");
            }
        }
        
        emit ChallengeResolved(challenge.tokenId, _proofHash, _isValid, _resolutionNote);
        // Clear the challenge mapping after resolution
        delete activeChallenges[_proofHash];
    }

    // --- IV. Contextual Yield & Reward Distribution ---

    function depositReward(uint256 _amount)
        public
        payable
        whenNotPaused
    {
        require(msg.value == _amount, "ETH amount must match _amount");
        totalRewardPool += _amount;
        emit RewardDeposited(msg.sender, _amount);
    }

    function getPendingYield(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 currentAura = getAuraPoints(_tokenId);
        uint256 currentLevel = getAuraLevel(_tokenId);
        uint256 yieldMultiplier = auraLevels[currentLevel].yieldMultiplier;
        
        uint256 timeSinceLastClaim = block.timestamp - _lastYieldClaimTimestamp[_tokenId];

        // Yield calculation: Aura * Multiplier * Time / Fixed_Time_Unit / Total_Aura_In_System
        // This is a simplified proportional distribution. A real one might track
        // individual yield rates.
        uint256 totalActiveAuraInSystem = _getTotalActiveAura(); // Need to calculate this
        if (totalActiveAuraInSystem == 0) return 0;

        uint256 potentialYield = (currentAura * yieldMultiplier * timeSinceLastClaim) / (1e18 * 1 years); // Yield per year

        // Scale by share of total reward pool
        uint256 shareOfPool = (potentialYield * totalRewardPool) / totalActiveAuraInSystem;
        return _pendingYield[_tokenId] + shareOfPool; // Add already accumulated
    }

    function _getTotalActiveAura() internal view returns (uint256) {
        // This would be a gas-intensive loop if done over many NFTs.
        // A more scalable solution would be to update a global sum
        // whenever Aura changes for any NFT, or use a Merkle sum tree.
        // For this example, we'll assume a practical limit or off-chain aggregation.
        // Simplification: Just return a placeholder or sum up top few NFTs for demo
        return 1e22; // Placeholder for a dynamic sum of all active NFT Aura points
    }

    function claimSkillYield(uint256 _tokenId)
        public
        nonReentrant
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        uint256 amount = getPendingYield(_tokenId);
        require(amount > 0, "No yield to claim");
        
        _pendingYield[_tokenId] = 0; // Reset pending yield
        _lastYieldClaimTimestamp[_tokenId] = block.timestamp; // Update last claim time

        totalRewardPool -= amount; // Deduct from protocol pool
        payable(msg.sender).transfer(amount);
        emit YieldClaimed(_tokenId, msg.sender, amount);
    }

    function stakeAuraForBoost(uint256 _tokenId, uint256 _amountToStake)
        public
        nonReentrant
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        uint256 currentAura = getAuraPoints(_tokenId);
        require(_amountToStake > 0 && currentAura >= _amountToStake, "Insufficient Aura to stake");
        
        // Reduce effective Aura for decay calculation temporarily
        // This is a simplification; actual "boost" could be more complex.
        // For now, it just tracks staked amount.
        _stakedAuraAmount[_tokenId] += _amountToStake;
        _updateAura(_tokenId, -int256(_amountToStake), "Staking Aura for Boost"); // Deduct from active Aura for decay calculation
        emit AuraStakedForBoost(_tokenId, _amountToStake);
    }

    function unstakeAuraForBoost(uint256 _tokenId)
        public
        nonReentrant
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        uint256 staked = _stakedAuraAmount[_tokenId];
        require(staked > 0, "No Aura staked for boost");
        
        _stakedAuraAmount[_tokenId] = 0;
        _updateAura(_tokenId, int256(staked), "Unstaking Aura from Boost"); // Restore Aura
        emit AuraUnstakedFromBoost(_tokenId, staked);
    }

    // --- V. Dynamic Properties & Agents ---

    // `setTraitModifierURI` is covered by `setAuraLevelThresholds` which sets `metadataSuffix`.
    // Additional dynamic traits could be managed by extending the AuraLevel struct or
    // adding more mappings.

    function registerSkillAgent(uint256 _tokenId, string memory _agentType, bytes memory _agentConfig)
        public
        nonReentrant
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(!skillAgents[_tokenId].registered, "NFT already registered as a skill agent");
        require(getAuraPoints(_tokenId) >= 500, "Minimum Aura (500) required to register as agent"); // Example requirement

        skillAgents[_tokenId] = SkillAgent({
            agentType: _agentType,
            config: _agentConfig,
            registered: true
        });
        emit SkillAgentRegistered(_tokenId, _agentType);
    }

    function updateAgentConfig(uint256 _tokenId, bytes memory _newConfig)
        public
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(skillAgents[_tokenId].registered, "NFT is not a registered skill agent");

        skillAgents[_tokenId].config = _newConfig;
        emit SkillAgentConfigUpdated(_tokenId);
    }

    // --- VI. Governance & Protocol Administration ---

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
        nonReentrant
    {
        require(_tokenAddress != address(0), "Cannot withdraw to zero address");
        // For Ether, use `selfdestruct(owner())` or `call`
        if (_tokenAddress == address(0xEeeeeEeeeEeEeeEeEeEeEeEeEeEeEeEeEeE) ) { // ETH
            require(address(this).balance >= _amount, "Insufficient ETH balance");
            payable(owner()).transfer(_amount);
        } else {
            // For ERC20 tokens
            IERC20(_tokenAddress).transfer(owner(), _amount);
        }
    }

    // This is a placeholder for a proxy upgrade pattern (e.g., UUPS or Transparent)
    // The actual upgrade logic would be in a separate proxy contract.
    function proposeProtocolUpgrade(address _newImplementation)
        public
        onlyOwner // In a real DAO, this would be a governance proposal
    {
        require(_newImplementation != address(0), "New implementation cannot be zero");
        emit ProtocolUpgradeProposed(_newImplementation);
        // This would typically involve setting a pending upgrade address that governance votes on
        // and then the proxy contract's `upgradeTo` or `upgradeToAndCall` method is called.
    }

    function proposeAuraVote(bytes32 _proposalHash, uint256 _votingPeriodDuration)
        public
        onlyOwner // Can be expanded to be created by anyone with enough Aura
    {
        require(proposals[_proposalHash].creationTimestamp == 0, "Proposal already exists");
        proposals[_proposalHash] = Proposal({
            proposalHash: _proposalHash,
            totalAuraVotesFor: 0,
            totalAuraVotesAgainst: 0,
            hasVoted: new mapping(uint256 => bool), // Initialize empty map
            executed: false,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + _votingPeriodDuration
        });
        // Emit event for off-chain listeners to track the proposal
    }

    function castAuraVote(uint256 _tokenId, bytes32 _proposalHash, bool _support)
        public
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.creationTimestamp != 0, "Proposal does not exist");
        require(block.timestamp < proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[_tokenId], "NFT has already voted on this proposal");

        uint256 auraVotingPower = getAuraPoints(_tokenId);
        require(auraVotingPower > 0, "NFT has no Aura to vote with");

        proposal.hasVoted[_tokenId] = true;
        if (_support) {
            proposal.totalAuraVotesFor += auraVotingPower;
        } else {
            proposal.totalAuraVotesAgainst += auraVotingPower;
        }
        emit AuraVoteCast(_tokenId, _proposalHash, _support, auraVotingPower);
    }
}
```