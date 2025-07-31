Okay, this is an exciting challenge! I'll design a Solidity smart contract for a "Decentralized Cognitive Asset Network" (DCAN). This contract will manage dynamic, AI-influenced NFTs (Cognitive Assets) that evolve based on community interaction and simulated external "curation insights" (think of these as AI predictions or deep learning outputs from an off-chain oracle). It also introduces a "Cognitive Index" for users, enabling a reputation-based governance model and tiered access.

We will focus on the *mechanics* of how these assets and user reputations evolve and interact, without implementing a full-blown AI on-chain (which is prohibitively expensive and complex for Solidity). Instead, we'll simulate the *impact* of AI/oracle insights.

---

## Decentralized Cognitive Asset Network (DCAN) - Contract Outline & Function Summary

**Contract Name:** `CognitiveAssetNetwork`

**Purpose:** To establish a decentralized network for managing dynamic, AI-influenced "Cognitive Assets" (NFTs). These assets evolve based on collective intelligence (community attestations/challenges) and external "curation insights" (simulated AI predictions). The network also tracks a "Cognitive Index" (reputation) for users, enabling tiered access and participation in a unique governance model.

---

### **Outline:**

1.  **Introduction:** Contract overview and core principles.
2.  **Core Concepts:**
    *   **Cognitive Assets (CA):** NFTs with mutable metadata, `cognitionScore`, `evolutionStage`, `provenanceHistory`, and `affinityTraits`.
    *   **Cognition Score:** A numerical representation of an asset's perceived relevance, accuracy, or quality. Influenced by user interactions and AI insights.
    *   **Evolution Stage:** An enum representing the asset's development phase, derived from its `cognitionScore`.
    *   **Affinity Traits:** Dynamic, community-proposed tags describing an asset's characteristics.
    *   **Provenance History:** On-chain log of significant events for each asset.
    *   **Cognitive Index (CI):** A reputation score for users, influenced by their interactions within the network. Grants access to higher tiers.
    *   **Curator Oracle:** A designated address (simulating an off-chain AI or data provider) that submits "curation insights" to influence asset scores.
    *   **Curated Discovery Pool:** A dynamic list of highly-rated assets, promoting visibility and interaction.
    *   **Parameter Governance:** A unique DAO-like system where users with a high Cognitive Index can propose and vote on core network parameters.
3.  **Modules:**
    *   **ERC721 Base:** Standard NFT functionality.
    *   **Asset Lifecycle Management:** Creation, interaction, evolution.
    *   **User Reputation System:** Managing Cognitive Index.
    *   **Curator Integration:** Receiving insights.
    *   **Discovery & Visibility:** Curated Pool.
    *   **Governance Mechanism:** Parameter changes.
    *   **Pausability & Ownership:** Standard administrative controls.
4.  **Key Features:**
    *   Dynamic NFT metadata driven by on-chain logic.
    *   Community-driven curation and evolution of digital assets.
    *   AI/Oracle integration (simulated) for predictive influence.
    *   Reputation-based access control and governance.
    *   On-chain provenance tracking for NFTs.
    *   Decentralized parameter adjustment.

---

### **Function Summary (Total: 29 Functions):**

**I. Core ERC721 Compliance & Asset Management (8 Functions)**

1.  `constructor(string memory name, string memory symbol)`: Initializes the ERC721 contract with a name and symbol.
2.  `createCognitiveAsset(string memory _initialIpfsHash, string[] memory _initialAffinityTraits)`: Mints a new Cognitive Asset NFT, assigning initial metadata and a starting cognition score.
3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an asset.
4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Overloaded transfer function.
5.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific asset.
6.  `setApprovalForAll(address operator, bool approved)`: Sets or revokes approval for an operator to manage all assets.
7.  `getApproved(uint256 tokenId)`: Returns the approved address for a single asset.
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all assets of an owner.

**II. Cognitive Asset Dynamics & Evolution (7 Functions)**

9.  `attestKnowledge(uint256 _tokenId)`: Users can "attest" to an asset's value, increasing its `cognitionScore` and their own `cognitiveIndex`.
10. `challengeNarrative(uint256 _tokenId)`: Users can "challenge" an asset's perceived narrative, potentially decreasing its `cognitionScore` and requiring a fee.
11. `proposeAffinityTrait(uint256 _tokenId, string memory _trait)`: Allows any user to propose a new `affinityTrait` for an asset.
12. `acceptAffinityTrait(uint256 _tokenId, string memory _trait)`: A high-CI user or asset owner can accept a proposed `affinityTrait`, adding it to the asset.
13. `updateAssetCurationInsight(uint256 _tokenId, int256 _scoreModifier, string memory _insightHash)`: (Only `curatorOracle`) Updates an asset's `cognitionScore` based on external AI/oracle insights.
14. `getAssetEvolutionStage(uint256 _tokenId)`: Returns the current `EvolutionStage` of an asset based on its `cognitionScore`.
15. `getAssetProvenanceHistory(uint256 _tokenId)`: Retrieves the detailed provenance log for an asset.

**III. User Cognitive Index (Reputation) & Tiers (3 Functions)**

16. `getCognitiveIndex(address _user)`: Returns a user's current `cognitiveIndex`.
17. `getTierByCognitiveIndex(address _user)`: Returns the user's current `CognitiveTier` based on their `cognitiveIndex`.
18. `redeemCognitiveIndexForBenefit()`: An example function where users can "redeem" a portion of their CI for a hypothetical benefit (e.g., protocol tokens, discounted fees).

**IV. Curated Discovery Pool (3 Functions)**

19. `submitForCuratedDiscovery(uint256 _tokenId)`: Allows high-CI users or highly cognitive assets to be submitted to the `curatedDiscoveryPool`.
20. `removeFromCuratedDiscovery(uint256 _tokenId)`: Allows the owner or an admin to remove an asset from the discovery pool.
21. `getCuratedDiscoveryPool()`: Returns the list of token IDs currently in the `curatedDiscoveryPool`.

**V. Parameter Governance (5 Functions)**

22. `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: Users in `Tier.Adaptive` or higher can propose changes to core contract parameters.
23. `voteOnParameterChange(bytes32 _proposalId, bool _voteYes)`: Users in `Tier.Adaptive` or higher can vote on active proposals.
24. `executeParameterChange(bytes32 _proposalId)`: Executes a passed proposal after the voting period ends and quorum is met.
25. `getProposalDetails(bytes32 _proposalId)`: Returns the details of a specific parameter change proposal.
26. `getVotingPower(address _voter)`: Returns the voting power of a user based on their cognitive index.

**VI. Administrative & Utility (3 Functions)**

27. `setCuratorOracleAddress(address _newOracleAddress)`: (Only owner) Sets the address allowed to submit `curationInsights`.
28. `pause()`: (Only owner) Pauses contract functionality in case of emergency.
29. `unpause()`: (Only owner) Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Decentralized Cognitive Asset Network (DCAN)
/// @notice A smart contract managing dynamic, AI-influenced NFTs (Cognitive Assets)
///         that evolve based on community interaction and simulated external "curation insights."
///         It also introduces a "Cognitive Index" for users, enabling a reputation-based
///         governance model and tiered access.
/// @dev This contract simulates AI interaction by allowing a designated "Curator Oracle"
///      to submit insights. It does not implement AI on-chain directly.

contract CognitiveAssetNetwork is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // --- Configuration Parameters (Governance controlled) ---
    uint256 public constant MAX_COGNITION_SCORE = 10000;
    uint256 public constant MIN_COGNITION_SCORE = 0;

    uint256 public attestationScoreBoost = 50; // Score added to asset & user CI on attestation
    uint256 public challengeScorePenalty = 75; // Score removed from asset on challenge
    uint256 public challengeCost = 0.01 ether; // Cost to challenge an asset

    uint256 public curatorInsightWeight = 100; // Multiplier for curator insights

    // Evolution stage thresholds
    uint256 public larvalThreshold = 0; // 0-2500
    uint256 public emergentThreshold = 2500; // 2500-5000
    uint256 public adaptiveThreshold = 5000; // 5000-7500
    uint256 public sentientThreshold = 7500; // 7500-10000

    // Cognitive Index (CI) Tier thresholds
    uint256 public ciTier1Threshold = 0; // Larval: 0-1000
    uint256 public ciTier2Threshold = 1000; // Emergent: 1000-2500
    uint256 public ciTier3Threshold = 2500; // Adaptive: 2500-5000
    uint256 public ciTier4Threshold = 5000; // Sentient: 5000+

    // Governance parameters
    uint256 public proposalQuorumPercentage = 51; // % of total CI needed to pass
    uint256 public votingPeriodDuration = 3 days; // Duration for voting on proposals
    uint256 public minCognitiveIndexForProposal = ciTier3Threshold; // Tier.Adaptive

    // --- Enums ---

    enum EvolutionStage { Larval, Emergent, Adaptive, Sentient }
    enum CognitiveTier { Larval, Emergent, Adaptive, Sentient }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct ProvenanceEvent {
        uint256 timestamp;
        address actor;
        string eventType; // e.g., "Created", "Attested", "Challenged", "Transferred", "CurationInsight"
        string details;
    }

    struct CognitiveAsset {
        uint256 id;
        string ipfsHash;
        uint256 cognitionScore; // 0 to 10000
        uint256 lastUpdateTimestamp;
        address creator;
        string[] affinityTraits; // Dynamic tags
        ProvenanceEvent[] provenanceHistory;
        uint256 lastCurationInsightTimestamp;
    }

    struct ParameterChangeProposal {
        bytes32 proposalId;
        string parameterName;
        uint256 proposedValue;
        uint256 creationTime;
        mapping(address => bool) hasVoted; // Check if user has voted
        uint256 yayVotes; // Sum of CI from 'yes' voters
        uint256 nayVotes; // Sum of CI from 'no' voters
        ProposalState state;
        string description; // Optional description for the proposal
    }

    // --- Mappings ---

    mapping(uint256 => CognitiveAsset) private _idToAsset;
    mapping(uint256 => string) private _tokenURIs; // Store base URI
    mapping(address => uint256) private _ownerToCognitiveIndex; // User reputation score
    mapping(bytes32 => ParameterChangeProposal) public parameterProposals;
    bytes32[] public activeProposals; // List of active proposal IDs

    uint256[] public curatedDiscoveryPool; // List of token IDs in the discovery pool
    mapping(uint256 => bool) public isCurated; // Tracks if asset is in discovery pool

    address public curatorOracleAddress; // Address allowed to submit AI insights

    // --- Events ---

    event AssetCreated(uint256 indexed tokenId, address indexed creator, string ipfsHash);
    event KnowledgeAttested(uint256 indexed tokenId, address indexed attester, uint256 newCognitionScore, uint256 attesterCognitiveIndex);
    event NarrativeChallenged(uint256 indexed tokenId, address indexed challenger, uint256 newCognitionScore);
    event AssetEvolved(uint256 indexed tokenId, EvolutionStage newStage, uint256 newScore);
    event AffinityTraitProposed(uint256 indexed tokenId, address indexed proposer, string trait);
    event AffinityTraitAccepted(uint256 indexed tokenId, address indexed acceptor, string trait);
    event CognitiveIndexUpdated(address indexed user, uint256 newIndex);
    event CurationInsightApplied(uint256 indexed tokenId, int256 scoreModifier, uint256 newCognitionScore, string insightHash);
    event AssetSubmittedForDiscovery(uint256 indexed tokenId, address indexed submitter);
    event AssetRemovedFromDiscovery(uint256 indexed tokenId, address indexed remover);
    event ParameterChangeProposed(bytes32 indexed proposalId, string parameterName, uint256 proposedValue, address indexed proposer);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool voteYes, uint256 votingPower);
    event ProposalExecuted(bytes32 indexed proposalId, bool success);

    // --- Modifiers ---

    modifier onlyCuratorOracle() {
        require(msg.sender == curatorOracleAddress, "CAN: Not the designated curator oracle");
        _;
    }

    modifier requireCognitiveIndexTier(CognitiveTier _requiredTier) {
        require(_ownerToCognitiveIndex[msg.sender] >= getMinScoreForTier(_requiredTier), "CAN: Insufficient Cognitive Index tier");
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {
        curatorOracleAddress = owner(); // Initially set owner as oracle, can be changed
    }

    // --- I. Core ERC721 Compliance & Asset Management ---

    /// @notice Creates a new Cognitive Asset NFT.
    /// @param _initialIpfsHash The IPFS hash pointing to the initial asset metadata.
    /// @param _initialAffinityTraits An array of initial descriptive traits for the asset.
    function createCognitiveAsset(string memory _initialIpfsHash, string[] memory _initialAffinityTraits)
        public
        whenNotPaused
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        require(bytes(_initialIpfsHash).length > 0, "CAN: Initial IPFS hash cannot be empty");

        _safeMint(msg.sender, newItemId);

        _idToAsset[newItemId] = CognitiveAsset({
            id: newItemId,
            ipfsHash: _initialIpfsHash,
            cognitionScore: (MIN_COGNITION_SCORE + MAX_COGNITION_SCORE) / 2, // Start in middle
            lastUpdateTimestamp: block.timestamp,
            creator: msg.sender,
            affinityTraits: _initialAffinityTraits,
            provenanceHistory: new ProvenanceEvent[](0),
            lastCurationInsightTimestamp: block.timestamp
        });

        _addProvenanceEvent(newItemId, msg.sender, "Created", "Asset minted by creator.");
        _updateCognitiveIndex(msg.sender, attestationScoreBoost); // Creator gets a small boost

        emit AssetCreated(newItemId, msg.sender, _initialIpfsHash);
        return newItemId;
    }

    /// @notice Overrides ERC721's tokenURI to provide dynamic metadata.
    /// @param tokenId The ID of the token.
    /// @return A string representing the URI to the token's metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        CognitiveAsset storage asset = _idToAsset[tokenId];

        // This is a simplified example. In a real dApp, you'd use a dedicated metadata service
        // that takes these parameters and generates a JSON file on the fly (e.g., via IPFS or a gateway).
        // The IPFS hash would point to a base JSON, and the dynamic parts would be appended/overwritten.

        string memory evolutionStageStr;
        EvolutionStage currentStage = getAssetEvolutionStage(tokenId);
        if (currentStage == EvolutionStage.Larval) evolutionStageStr = "Larval";
        else if (currentStage == EvolutionStage.Emergent) evolutionStageStr = "Emergent";
        else if (currentStage == EvolutionStage.Adaptive) evolutionStageStr = "Adaptive";
        else if (currentStage == EvolutionStage.Sentient) evolutionStageStr = "Sentient";

        string memory traits = "";
        for (uint256 i = 0; i < asset.affinityTraits.length; i++) {
            traits = string(abi.encodePacked(traits, asset.affinityTraits[i]));
            if (i < asset.affinityTraits.length - 1) {
                traits = string(abi.encodePacked(traits, ", "));
            }
        }

        // Constructing a simple "pseudo-URI" here to demonstrate dynamic data.
        // In reality, this would be a URL to a metadata service: `ipfs://{base_hash}?score={score}&stage={stage}...`
        return string(abi.encodePacked(
            "ipfs://", asset.ipfsHash,
            "?name=CognitiveAsset-", tokenId.toString(),
            "&creator=", Strings.toHexString(uint160(asset.creator), 20),
            "&score=", asset.cognitionScore.toString(),
            "&stage=", evolutionStageStr,
            "&traits=", traits
        ));
    }

    // ERC721 standard functions (already inherited and implemented by OpenZeppelin's ERC721)
    // safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll
    // balanceOf, ownerOf implicitly handled by ERC721's internal _owners mapping.

    // --- II. Cognitive Asset Dynamics & Evolution ---

    /// @notice Allows a user to "attest" to the value or accuracy of a Cognitive Asset.
    /// @dev Increases the asset's `cognitionScore` and the attester's `cognitiveIndex`.
    /// @param _tokenId The ID of the Cognitive Asset.
    function attestKnowledge(uint256 _tokenId) public payable whenNotPaused {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        CognitiveAsset storage asset = _idToAsset[_tokenId];

        // Apply score boost, cap at MAX_COGNITION_SCORE
        uint256 newScore = asset.cognitionScore + attestationScoreBoost;
        asset.cognitionScore = newScore > MAX_COGNITION_SCORE ? MAX_COGNITION_SCORE : newScore;

        _addProvenanceEvent(_tokenId, msg.sender, "Attested", "Knowledge attested by user.");
        _updateCognitiveIndex(msg.sender, attestationScoreBoost);
        asset.lastUpdateTimestamp = block.timestamp;

        EvolutionStage oldStage = getAssetEvolutionStage(_tokenId);
        EvolutionStage newStage = _updateEvolutionStage(_tokenId);

        emit KnowledgeAttested(_tokenId, msg.sender, asset.cognitionScore, _ownerToCognitiveIndex[msg.sender]);
        if (newStage != oldStage) {
            emit AssetEvolved(_tokenId, newStage, asset.cognitionScore);
        }
    }

    /// @notice Allows a user to "challenge" the narrative or accuracy of a Cognitive Asset.
    /// @dev Decreases the asset's `cognitionScore` and requires a fee.
    /// @param _tokenId The ID of the Cognitive Asset.
    function challengeNarrative(uint256 _tokenId) public payable whenNotPaused {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        require(msg.value >= challengeCost, "CAN: Insufficient challenge cost provided.");

        CognitiveAsset storage asset = _idToAsset[_tokenId];

        // Apply score penalty, floor at MIN_COGNITION_SCORE
        int256 newScore = int256(asset.cognitionScore) - int256(challengeScorePenalty);
        asset.cognitionScore = newScore < int256(MIN_COGNITION_SCORE) ? MIN_COGNITION_SCORE : uint256(newScore);

        // Funds collected in the contract, can be withdrawn by owner or distributed later
        // Potentially, a portion could be burned or used for protocol incentives.

        _addProvenanceEvent(_tokenId, msg.sender, "Challenged", "Narrative challenged by user. Cost: " + challengeCost.toString() + " WEI.");
        // Challenger's CI might slightly decrease or remain neutral, depending on protocol design.
        // For simplicity, we won't adjust CI for challenges in this version, or consider it a neutral action.
        asset.lastUpdateTimestamp = block.timestamp;

        EvolutionStage oldStage = getAssetEvolutionStage(_tokenId);
        EvolutionStage newStage = _updateEvolutionStage(_tokenId);

        emit NarrativeChallenged(_tokenId, msg.sender, asset.cognitionScore);
        if (newStage != oldStage) {
            emit AssetEvolved(_tokenId, newStage, asset.cognitionScore);
        }
    }

    /// @notice Allows any user to propose a new `affinityTrait` for an asset.
    /// @dev The trait is not immediately added; it needs to be accepted.
    /// @param _tokenId The ID of the Cognitive Asset.
    /// @param _trait The new trait string to propose.
    function proposeAffinityTrait(uint256 _tokenId, string memory _trait) public whenNotPaused {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        require(bytes(_trait).length > 0, "CAN: Trait cannot be empty.");

        // In a more complex system, this might involve a vote or more complex logic
        // For now, it's just a proposal to be accepted by owner/high-CI user.
        _addProvenanceEvent(_tokenId, msg.sender, "TraitProposed", "Trait '" + _trait + "' proposed by user.");
        emit AffinityTraitProposed(_tokenId, msg.sender, _trait);
    }

    /// @notice Allows the asset owner or a high-CI user to accept a proposed `affinityTrait`.
    /// @param _tokenId The ID of the Cognitive Asset.
    /// @param _trait The trait string to accept.
    function acceptAffinityTrait(uint256 _tokenId, string memory _trait) public whenNotPaused {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        CognitiveAsset storage asset = _idToAsset[_tokenId];
        address assetOwner = ownerOf(_tokenId);

        // Only asset owner or a high-CI user can accept
        require(msg.sender == assetOwner || _ownerToCognitiveIndex[msg.sender] >= ciTier3Threshold, // Tier.Adaptive
                "CAN: Only asset owner or Adaptive+ tier can accept traits.");

        // Check if trait already exists to prevent duplication
        for (uint256 i = 0; i < asset.affinityTraits.length; i++) {
            if (keccak256(abi.encodePacked(asset.affinityTraits[i])) == keccak256(abi.encodePacked(_trait))) {
                revert("CAN: Trait already exists for this asset.");
            }
        }

        asset.affinityTraits.push(_trait);
        _addProvenanceEvent(_tokenId, msg.sender, "TraitAccepted", "Trait '" + _trait + "' accepted.");
        asset.lastUpdateTimestamp = block.timestamp;
        emit AffinityTraitAccepted(_tokenId, msg.sender, _trait);
    }

    /// @notice (Only Curator Oracle) Updates an asset's `cognitionScore` based on external AI/oracle insights.
    /// @param _tokenId The ID of the Cognitive Asset.
    /// @param _scoreModifier The amount by which to modify the score (can be positive or negative).
    /// @param _insightHash A hash or identifier for the off-chain insight data.
    function updateAssetCurationInsight(uint256 _tokenId, int256 _scoreModifier, string memory _insightHash)
        public
        onlyCuratorOracle
        whenNotPaused
    {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        CognitiveAsset storage asset = _idToAsset[_tokenId];

        int256 effectiveModifier = _scoreModifier * int256(curatorInsightWeight) / 100; // Apply weight
        int256 newScore = int256(asset.cognitionScore) + effectiveModifier;

        if (newScore > int256(MAX_COGNITION_SCORE)) {
            asset.cognitionScore = MAX_COGNITION_SCORE;
        } else if (newScore < int256(MIN_COGNITION_SCORE)) {
            asset.cognitionScore = MIN_COGNITION_SCORE;
        } else {
            asset.cognitionScore = uint256(newScore);
        }

        _addProvenanceEvent(_tokenId, msg.sender, "CurationInsight", "Insight applied. Modifier: " + effectiveModifier.toString() + ". Insight Hash: " + _insightHash);
        asset.lastUpdateTimestamp = block.timestamp;
        asset.lastCurationInsightTimestamp = block.timestamp;

        EvolutionStage oldStage = getAssetEvolutionStage(_tokenId);
        EvolutionStage newStage = _updateEvolutionStage(_tokenId);

        emit CurationInsightApplied(_tokenId, effectiveModifier, asset.cognitionScore, _insightHash);
        if (newStage != oldStage) {
            emit AssetEvolved(_tokenId, newStage, asset.cognitionScore);
        }
    }

    /// @notice Returns the current `EvolutionStage` of an asset based on its `cognitionScore`.
    /// @param _tokenId The ID of the Cognitive Asset.
    /// @return The EvolutionStage enum value.
    function getAssetEvolutionStage(uint256 _tokenId) public view returns (EvolutionStage) {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        uint256 score = _idToAsset[_tokenId].cognitionScore;

        if (score >= sentientThreshold) {
            return EvolutionStage.Sentient;
        } else if (score >= adaptiveThreshold) {
            return EvolutionStage.Adaptive;
        } else if (score >= emergentThreshold) {
            return EvolutionStage.Emergent;
        } else {
            return EvolutionStage.Larval;
        }
    }

    /// @notice Retrieves the detailed provenance log for an asset.
    /// @param _tokenId The ID of the Cognitive Asset.
    /// @return An array of ProvenanceEvent structs.
    function getAssetProvenanceHistory(uint256 _tokenId) public view returns (ProvenanceEvent[] memory) {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        return _idToAsset[_tokenId].provenanceHistory;
    }

    // --- III. User Cognitive Index (Reputation) & Tiers ---

    /// @notice Returns a user's current `cognitiveIndex`.
    /// @param _user The address of the user.
    /// @return The user's cognitive index score.
    function getCognitiveIndex(address _user) public view returns (uint256) {
        return _ownerToCognitiveIndex[_user];
    }

    /// @notice Returns the user's current `CognitiveTier` based on their `cognitiveIndex`.
    /// @param _user The address of the user.
    /// @return The CognitiveTier enum value.
    function getTierByCognitiveIndex(address _user) public view returns (CognitiveTier) {
        uint256 ci = _ownerToCognitiveIndex[_user];
        if (ci >= ciTier4Threshold) {
            return CognitiveTier.Sentient;
        } else if (ci >= ciTier3Threshold) {
            return CognitiveTier.Adaptive;
        } else if (ci >= ciTier2Threshold) {
            return CognitiveTier.Emergent;
        } else {
            return CognitiveTier.Larval;
        }
    }

    /// @notice An example function where users can "redeem" a portion of their CI for a hypothetical benefit.
    /// @dev This function would need to be expanded to define actual benefits. For demonstration, it just reduces CI.
    function redeemCognitiveIndexForBenefit() public whenNotPaused requireCognitiveIndexTier(CognitiveTier.Emergent) {
        uint256 currentCI = _ownerToCognitiveIndex[msg.sender];
        uint256 redeemAmount = currentCI / 10; // Example: redeem 10%
        require(redeemAmount > 0, "CAN: Not enough Cognitive Index to redeem.");

        _updateCognitiveIndex(msg.sender, -int256(redeemAmount)); // Reduce CI
        // Add logic here for what benefit the user receives (e.g., mint a governance token, unlock a feature).
        // This is a placeholder for actual redemption mechanics.

        // Example: Transfer a hypothetical 'ProtocolToken'
        // IProtocolToken(protocolTokenAddress).transfer(msg.sender, redeemAmount * X);
    }

    // --- IV. Curated Discovery Pool ---

    /// @notice Allows high-CI users or highly cognitive assets to be submitted to the `curatedDiscoveryPool`.
    /// @dev Requires the submitting user to be in `Tier.Adaptive` or higher, or the asset itself to be `Adaptive` or `Sentient`.
    /// @param _tokenId The ID of the Cognitive Asset to submit.
    function submitForCuratedDiscovery(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        require(!isCurated[_tokenId], "CAN: Asset already in curated discovery pool.");

        EvolutionStage assetStage = getAssetEvolutionStage(_tokenId);
        CognitiveTier userTier = getTierByCognitiveIndex(msg.sender);

        require(userTier >= CognitiveTier.Adaptive || assetStage >= EvolutionStage.Adaptive,
                "CAN: Submitter needs Adaptive+ CI OR asset needs to be Adaptive+.");

        curatedDiscoveryPool.push(_tokenId);
        isCurated[_tokenId] = true;

        _addProvenanceEvent(_tokenId, msg.sender, "SubmittedToDiscovery", "Asset submitted to curated discovery pool.");
        emit AssetSubmittedForDiscovery(_tokenId, msg.sender);
    }

    /// @notice Allows the owner or an admin to remove an asset from the discovery pool.
    /// @param _tokenId The ID of the Cognitive Asset to remove.
    function removeFromCuratedDiscovery(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "CAN: Asset does not exist.");
        require(isCurated[_tokenId], "CAN: Asset not in curated discovery pool.");
        require(msg.sender == ownerOf(_tokenId) || msg.sender == owner(), "CAN: Only asset owner or contract owner can remove from discovery.");

        // Find and remove from the array (inefficient for very large arrays, consider using a linked list or mapping for O(1) removal)
        for (uint256 i = 0; i < curatedDiscoveryPool.length; i++) {
            if (curatedDiscoveryPool[i] == _tokenId) {
                curatedDiscoveryPool[i] = curatedDiscoveryPool[curatedDiscoveryPool.length - 1];
                curatedDiscoveryPool.pop();
                break;
            }
        }
        isCurated[_tokenId] = false;

        _addProvenanceEvent(_tokenId, msg.sender, "RemovedFromDiscovery", "Asset removed from curated discovery pool.");
        emit AssetRemovedFromDiscovery(_tokenId, msg.sender);
    }

    /// @notice Returns the list of token IDs currently in the `curatedDiscoveryPool`.
    /// @return An array of token IDs.
    function getCuratedDiscoveryPool() public view returns (uint256[] memory) {
        return curatedDiscoveryPool;
    }

    // --- V. Parameter Governance ---

    /// @notice Allows users in `Tier.Adaptive` or higher to propose changes to core contract parameters.
    /// @param _parameterName The name of the parameter to change (e.g., "attestationScoreBoost").
    /// @param _newValue The new value for the parameter.
    /// @param _description A brief description of the proposal.
    /// @return The unique ID of the created proposal.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue, string memory _description)
        public
        whenNotPaused
        requireCognitiveIndexTier(CognitiveTier.Adaptive)
        returns (bytes32)
    {
        // Simple check for valid parameter names (can be expanded to an enum or whitelist)
        require(
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("attestationScoreBoost")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("challengeScorePenalty")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("challengeCost")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("curatorInsightWeight")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("larvalThreshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("emergentThreshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("adaptiveThreshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("sentientThreshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("ciTier1Threshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("ciTier2Threshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("ciTier3Threshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("ciTier4Threshold")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("proposalQuorumPercentage")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("votingPeriodDuration")) ||
            keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minCognitiveIndexForProposal")),
            "CAN: Invalid parameter name."
        );
        require(_ownerToCognitiveIndex[msg.sender] >= minCognitiveIndexForProposal, "CAN: Insufficient CI to propose.");

        bytes32 proposalId = keccak256(abi.encodePacked(msg.sender, _parameterName, _newValue, block.timestamp));
        require(parameterProposals[proposalId].state == ProposalState.Pending, "CAN: Proposal already exists.");

        parameterProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            proposedValue: _newValue,
            creationTime: block.timestamp,
            yayVotes: 0,
            nayVotes: 0,
            state: ProposalState.Active,
            description: _description,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });
        activeProposals.push(proposalId);

        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, msg.sender);
        return proposalId;
    }

    /// @notice Allows users in `Tier.Adaptive` or higher to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _voteYes True for a 'yes' vote, false for a 'no' vote.
    function voteOnParameterChange(bytes32 _proposalId, bool _voteYes)
        public
        whenNotPaused
        requireCognitiveIndexTier(CognitiveTier.Adaptive)
    {
        ParameterChangeProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "CAN: Proposal is not active.");
        require(block.timestamp < proposal.creationTime + votingPeriodDuration, "CAN: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "CAN: Already voted on this proposal.");

        uint256 voterCI = _ownerToCognitiveIndex[msg.sender];
        require(voterCI > 0, "CAN: Voter must have a positive Cognitive Index.");

        proposal.hasVoted[msg.sender] = true;
        if (_voteYes) {
            proposal.yayVotes += voterCI;
        } else {
            proposal.nayVotes += voterCI;
        }

        emit VoteCast(_proposalId, msg.sender, _voteYes, voterCI);
    }

    /// @notice Executes a passed proposal after the voting period ends and quorum is met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeParameterChange(bytes32 _proposalId) public whenNotPaused {
        ParameterChangeProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "CAN: Proposal not active.");
        require(block.timestamp >= proposal.creationTime + votingPeriodDuration, "CAN: Voting period has not ended.");

        uint256 totalCognitiveIndex = 0;
        // In a real system, `totalCognitiveIndex` would be a global cumulative sum
        // or derived from total token supply in a governance token scenario.
        // For this demo, we'll assume a fixed or calculated total.
        // For simplicity, let's use a placeholder `totalPossibleVotingPower`.
        // A more robust system would track the sum of all CI, or use a specific governance token supply.
        // For demonstration, let's just make sure yay votes exceed nay votes and a minimum threshold.
        uint256 totalVotesCast = proposal.yayVotes + proposal.nayVotes;
        // This quorum implementation is simplified. A real one might need to know the total 'active' CI.
        // Here, we'll just check against a direct sum and percentage of 'votes cast'.
        bool passed = false;
        if (totalVotesCast > 0) { // Ensure at least some votes were cast
            if ((proposal.yayVotes * 100) / totalVotesCast >= proposalQuorumPercentage) {
                 passed = true;
            }
        }

        if (passed) {
            _applyParameterChange(proposal.parameterName, proposal.proposedValue);
            proposal.state = ProposalState.Succeeded;
            emit ProposalExecuted(_proposalId, true);
        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalExecuted(_proposalId, false);
        }

        // Remove from active proposals list
        for (uint256 i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == _proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }
    }

    /// @notice Returns the details of a specific parameter change proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getProposalDetails(bytes32 _proposalId)
        public
        view
        returns (
            bytes32 proposalId,
            string memory parameterName,
            uint256 proposedValue,
            uint256 creationTime,
            uint256 yayVotes,
            uint256 nayVotes,
            ProposalState state,
            string memory description
        )
    {
        ParameterChangeProposal storage proposal = parameterProposals[_proposalId];
        return (
            proposal.proposalId,
            proposal.parameterName,
            proposal.proposedValue,
            proposal.creationTime,
            proposal.yayVotes,
            proposal.nayVotes,
            proposal.state,
            proposal.description
        );
    }

    /// @notice Returns the voting power of a user based on their cognitive index.
    /// @dev In this simplified model, voting power is directly proportional to CI.
    /// @param _voter The address of the voter.
    /// @return The voting power (Cognitive Index) of the user.
    function getVotingPower(address _voter) public view returns (uint256) {
        return _ownerToCognitiveIndex[_voter];
    }

    // --- VI. Administrative & Utility ---

    /// @notice (Only owner) Sets the address allowed to submit `curationInsights`.
    /// @param _newOracleAddress The new address for the Curator Oracle.
    function setCuratorOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "CAN: New oracle address cannot be zero.");
        curatorOracleAddress = _newOracleAddress;
    }

    /// @notice Pauses contract functionality in case of emergency.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the contract owner to withdraw accumulated challenge fees.
    /// @dev In a more decentralized system, these funds might be managed by a DAO treasury.
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CAN: No fees to withdraw.");
        payable(owner()).transfer(balance);
    }

    // --- Internal & Private Helper Functions ---

    /// @dev Internal function to add a provenance event to an asset's history.
    function _addProvenanceEvent(uint256 _tokenId, address _actor, string memory _eventType, string memory _details) internal {
        CognitiveAsset storage asset = _idToAsset[_tokenId];
        asset.provenanceHistory.push(ProvenanceEvent({
            timestamp: block.timestamp,
            actor: _actor,
            eventType: _eventType,
            details: _details
        }));
    }

    /// @dev Internal function to update a user's cognitive index. Handles positive and negative adjustments.
    /// @param _user The address of the user.
    /// @param _change The amount to change the index by (can be negative).
    function _updateCognitiveIndex(address _user, int256 _change) internal {
        int256 currentCI = int256(_ownerToCognitiveIndex[_user]);
        int256 newCI = currentCI + _change;

        // Ensure CI doesn't go below zero
        _ownerToCognitiveIndex[_user] = newCI < 0 ? 0 : uint256(newCI);
        emit CognitiveIndexUpdated(_user, _ownerToCognitiveIndex[_user]);
    }

    /// @dev Internal function to update the evolution stage of an asset.
    /// @param _tokenId The ID of the Cognitive Asset.
    /// @return The new EvolutionStage of the asset.
    function _updateEvolutionStage(uint256 _tokenId) internal returns (EvolutionStage) {
        CognitiveAsset storage asset = _idToAsset[_tokenId];
        EvolutionStage newStage = getAssetEvolutionStage(_tokenId);
        // If current stage is different, update and emit event
        if (asset.evolutionStage != newStage) {
            asset.evolutionStage = newStage;
            emit AssetEvolved(_tokenId, newStage, asset.cognitionScore);
        }
        return newStage;
    }

    /// @dev Internal helper to get minimum score for a given CI tier.
    function getMinScoreForTier(CognitiveTier _tier) internal view returns (uint256) {
        if (_tier == CognitiveTier.Larval) return ciTier1Threshold;
        if (_tier == CognitiveTier.Emergent) return ciTier2Threshold;
        if (_tier == CognitiveTier.Adaptive) return ciTier3Threshold;
        if (_tier == CognitiveTier.Sentient) return ciTier4Threshold;
        return 0; // Should not happen
    }

    /// @dev Internal function to apply parameter changes based on governance proposals.
    function _applyParameterChange(string memory _parameterName, uint256 _newValue) internal {
        bytes32 paramHash = keccak256(abi.encodePacked(_parameterName));

        if (paramHash == keccak256(abi.encodePacked("attestationScoreBoost"))) {
            attestationScoreBoost = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("challengeScorePenalty"))) {
            challengeScorePenalty = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("challengeCost"))) {
            challengeCost = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("curatorInsightWeight"))) {
            curatorInsightWeight = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("larvalThreshold"))) {
            larvalThreshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("emergentThreshold"))) {
            emergentThreshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("adaptiveThreshold"))) {
            adaptiveThreshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("sentientThreshold"))) {
            sentientThreshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("ciTier1Threshold"))) {
            ciTier1Threshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("ciTier2Threshold"))) {
            ciTier2Threshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("ciTier3Threshold"))) {
            ciTier3Threshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("ciTier4Threshold"))) {
            ciTier4Threshold = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
            require(_newValue <= 100, "CAN: Quorum percentage must be <= 100.");
            proposalQuorumPercentage = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("votingPeriodDuration"))) {
            votingPeriodDuration = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minCognitiveIndexForProposal"))) {
            minCognitiveIndexForProposal = _newValue;
        } else {
            revert("CAN: Unknown parameter for update.");
        }
    }
}
```