The `ChronoGlyph` smart contract is designed to be an innovative, advanced-concept platform that merges decentralized generative art, a reputation system, and a lightweight DAO governance, all powered by collective intelligence. It aims to offer a novel approach to how on-chain systems can evolve and adapt based on community contributions and curation, all while providing dynamic, evolving NFTs that reflect a user's journey.

The core idea is that users contribute "inspirations" which are inputs (e.g., URIs to images, text prompts, or data sets) to an on-chain generative art "algorithm" (represented by evolving parameters). Through a collective feedback loop, these parameters adapt. User reputation, earned through quality contributions and accurate curation, is dynamically reflected in their unique "ChronoGlyph" NFT, which serves as a visual representation of their on-chain identity and influence.

---

## ChronoGlyph Smart Contract: Outline & Function Summary

**Contract Name:** `ChronoGlyph`

**Core Concepts:**
*   **Decentralized Collective Intelligence:** Generative art parameters evolve based on aggregated community contributions and curation feedback.
*   **Dynamic NFTs (ChronoGlyphs):** ERC-721 tokens whose metadata (visuals) dynamically change and reflect the minter's reputation, contributions, and the global generative art state. While the ERC-721 is transferable, the core *reputation and functional utility* remains tied to the original minter's address, offering a "soulbound-like" behavioral characteristic.
*   **Reputation System:** A quantifiable measure of a user's influence and trustworthiness within the ecosystem, earned through valuable inspirations and accurate attestations/curation.
*   **Commit-Reveal Scheme:** A privacy-preserving mechanism for submitting inspirations to prevent front-running or MEV exploits.
*   **Lightweight On-chain Governance:** A mechanism for high-reputation users or the owner to propose and vote on direct overrides to the generative art parameters or system configurations.

---

### Function Summary (At least 20 Functions):

**I. Core System & Epoch Management (The "Collective Intelligence"):**

1.  **`initializeEpoch()`**: Initiates a new creative epoch. Advances the system to a new phase for accepting contributions and preparing for parameter evolution.
2.  **`submitInspiration(string memory _inspirationURI, uint256 _category)`**: Allows users to contribute creative "inspirations" (e.g., IPFS/Arweave URIs of images, text prompts, or raw data) categorized by type. These serve as inputs to the generative model.
3.  **`triggerParameterEvolution()`**: Aggregates all inspirations and curation feedback from the *just-completed* epoch to evolve the `ChronoGlyph`'s global generative art parameters. This is the core "collective intelligence" mechanism.
4.  **`getCurrentGenerativeParameters()`**: Retrieves the current set of global parameters that external (off-chain) generative art rendering services would use to create artworks.
5.  **`getInspiredArtworkURI(uint256 _epochId)`**: Provides a URI that can be used off-chain to create art based on the parameters evolved during a specific historical epoch, linking epochs to their artistic output.

**II. Reputation & Dynamic Glyphs (NFTs):**

6.  **`mintChronoGlyph()`**: Mints a unique, dynamic ERC-721 "ChronoGlyph" NFT for the caller. This Glyph visually represents their accumulated reputation and contribution history, updated dynamically via its metadata.
7.  **`updateChronoGlyphMetadata(address _user)`**: Triggers an update of a user's ChronoGlyph's metadata URI, reflecting changes in their reputation, contributions, and the global generative parameters. This is how the Glyph "evolves".
8.  **`getReputationScore(address _user)`**: Returns the current reputation score of a specific user, reflecting their influence and impact within the system.
9.  **`attestContributionQuality(uint256 _inspirationId, uint256 _score)`**: Allows high-reputation users (or a designated committee) to formally attest to the quality and relevance of a submitted inspiration, directly influencing the contributor's reputation and the inspiration's weight.
10. **`delegateAttestationPower(address _delegatee, bool _enable)`**: Enables high-reputation users to delegate their power to attest to contribution quality to another trusted address.
11. **`getChronoGlyphData(address _user)`**: Retrieves detailed data associated with a user's ChronoGlyph, including its associated token ID, current reputation, and other relevant metrics.

**III. Curation & Feedback Loops:**

12. **`curateGeneratedArt(uint256 _epochId, bytes32 _artPieceHash, uint8 _rating)`**: Allows users to rate off-chain generated art pieces (identified by a cryptographic hash) that were produced using the parameters of a specific epoch. These ratings feed back into future parameter evolution.
13. **`reportMaliciousContent(uint256 _inspirationId, string memory _reason)`**: Provides a mechanism for users to flag inspirations deemed inappropriate, harmful, or malicious, initiating a moderation process.
14. **`resolveReport(uint256 _inspirationId, bool _isValid)`**: A moderated function (e.g., by the contract owner or DAO) to review and resolve reported content, applying penalties (e.g., reputation reduction) or clearing flags as necessary.

**IV. Advanced Mechanisms & Utility:**

15. **`submitSealedInspiration(bytes32 _hashOfInspiration, uint256 _category)`**: A commit-reveal mechanism allowing users to commit to an inspiration privately first (by submitting its hash), preventing front-running before revealing the full content.
16. **`revealSealedInspiration(string memory _inspirationURI, uint256 _category, bytes32 _nonce)`**: Reveals a previously committed inspiration. The contract verifies that the revealed content's hash matches the initial commitment, and then processes the inspiration.
17. **`proposeParameterOverride(uint256 _paramIndex, int256 _newValue, string memory _rationale)`**: Enables users (with sufficient standing) to propose direct, immediate overrides to specific generative parameters, subject to governance approval.
18. **`voteOnParameterOverride(uint256 _proposalId, bool _support)`**: Allows high-reputation users or DAO members to vote on proposed parameter overrides, with voting power potentially weighted by their reputation.
19. **`claimEpochReward()`**: Allows users to claim rewards (e.g., in native tokens or a designated ERC-20) for their positive contributions and effective curation within a completed epoch, based on their accumulated reputation and activity.
20. **`setSystemParameters(uint256 _newEpochDuration, uint256 _minReputationForAttestation)`**: An administrative/DAO function to adjust core system configurations, such as the duration of each creative epoch and the minimum reputation required to participate in attestation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Dummy interface for an ERC20 reward token (optional, if rewards are in ERC20)
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title ChronoGlyph
 * @dev A Decentralized AI-Powered Generative Art & Reputation Engine.
 *      This contract orchestrates a system where users contribute "inspirations"
 *      to an evolving on-chain generative art model. Their contributions and
 *      curation activities build reputation, which is dynamically reflected
 *      in unique, evolving "ChronoGlyph" NFTs. The "AI" aspect is a collective
 *      intelligence mechanism where generative parameters evolve based on
 *      aggregated user input and feedback loops. It incorporates concepts like
 *      dynamic NFTs, a reputation system, commit-reveal for privacy, and a
 *      lightweight on-chain governance for parameter overrides.
 */
contract ChronoGlyph is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // --- Core System Parameters & State ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _inspirationIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public currentEpochId;
    uint256 public epochDuration; // Duration in seconds for each epoch
    uint256 public lastEpochStartTime;

    // Generative art parameters: Simplified as a mapping for demonstration.
    // In a real system, these would be more complex (e.g., structs, dynamic arrays).
    // Mapping: Parameter ID => Current Value
    mapping(uint256 => int256) public generativeParameters;
    uint256 public constant TOTAL_GENERATIVE_PARAMETERS = 10; // Example: 10 parameters (color palettes, shapes, styles)

    // URI pointing to the off-chain generative script or base art data
    string public baseGenerativeScriptURI;

    // --- Inspirations & Contributions ---
    struct Inspiration {
        uint256 id;
        address contributor;
        string inspirationURI; // IPFS/Arweave URI for the actual content
        uint256 category; // e.g., 0: text, 1: image, 2: raw_data
        uint256 epochId;
        uint256 aggregatedQualityScore; // Sum of quality scores from attestations
        uint256 numAttestations;
        bool isReported;
        bool isRevealed; // For commit-reveal scheme
    }
    mapping(uint256 => Inspiration) public inspirations;
    // Mapping: hashOfInspiration => InspirationId (for commit-reveal validation)
    mapping(bytes32 => uint256) public sealedInspirations; // Stores inspiration ID for committed hashes

    // --- Reputation System ---
    mapping(address => uint256) public reputationScores;
    uint256 public minReputationForAttestation; // Min reputation to attest contribution quality

    // For delegation of attestation power: delegatee => delegator
    mapping(address => address) public attestationDelegation; // Delegatee => Original Attestor

    // --- Curation & Feedback ---
    // Mapping: epochId => artPieceHash => aggregatedRating => numRatings
    mapping(uint256 => mapping(bytes32 => mapping(uint8 => uint256))) public artPieceRatings;

    // --- DAO/Governance (Lightweight) ---
    struct ParameterOverrideProposal {
        uint256 proposalId;
        uint256 paramIndex;
        int256 newValue;
        string rationale;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => Voted status
        bool executed;
        bool approved;
    }
    mapping(uint256 => ParameterOverrideProposal) public parameterOverrideProposals;

    // --- Rewards (Optional) ---
    IERC20 public rewardToken; // Address of an ERC20 reward token (can be zero address if ETH is used)

    // Mapping: epochId => contributor/curator address => earned reward amount
    mapping(uint256 => mapping(address => uint256)) public epochRewards;
    mapping(address => uint256) public claimedEpochRewards;

    // --- ChronoGlyph NFT specific mappings (for "soulbound-like" behavior) ---
    mapping(address => uint256) private _minterAddressToTokenId; // Stores tokenId for minter
    mapping(uint256 => address) private _tokenIdToMinterAddress; // Stores minter address for tokenId

    /* ========== EVENTS ========== */
    event EpochInitialized(uint256 indexed epochId, uint256 startTime, uint256 duration);
    event InspirationSubmitted(uint256 indexed inspirationId, address indexed contributor, uint256 category, string inspirationURI);
    event InspirationSealed(uint256 indexed inspirationId, address indexed contributor, bytes32 hashOfInspiration, uint256 category);
    event InspirationRevealed(uint256 indexed inspirationId, address indexed contributor, string inspirationURI);
    event ParametersEvolved(uint256 indexed epochId, bytes32 newParametersHash);
    event ChronoGlyphMinted(address indexed owner, uint256 indexed tokenId);
    event ChronoGlyphMetadataUpdated(address indexed owner, uint256 indexed tokenId, string newURI);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ContributionAttested(uint256 indexed inspirationId, address indexed attestor, uint256 score);
    event AttestationPowerDelegated(address indexed delegator, address indexed delegatee);
    event ArtCurated(uint256 indexed epochId, bytes32 indexed artPieceHash, address indexed curator, uint8 rating);
    event ContentReported(uint256 indexed inspirationId, address indexed reporter, string reason);
    event ReportResolved(uint256 indexed inspirationId, bool isValid, address indexed resolver);
    event ParameterOverrideProposed(uint256 indexed proposalId, uint256 paramIndex, int256 newValue, string rationale);
    event ParameterOverrideVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterOverrideExecuted(uint256 indexed proposalId, uint256 paramIndex, int256 newValue);
    event EpochRewardClaimed(address indexed claimant, uint256 indexed epochId, uint256 amount);
    event SystemParametersSet(uint256 newEpochDuration, uint256 minReputationForAttestation);

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory _name, string memory _symbol, uint256 _initialEpochDuration, uint256 _minRepForAttestation, string memory _baseGenerativeScriptURI)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_initialEpochDuration > 0, "Epoch duration must be positive");
        epochDuration = _initialEpochDuration; // e.g., 7 days in seconds
        minReputationForAttestation = _minRepForAttestation; // e.g., 100 for a start
        baseGenerativeScriptURI = _baseGenerativeScriptURI;

        // Initialize some dummy generative parameters
        for (uint256 i = 0; i < TOTAL_GENERATIVE_PARAMETERS; i++) {
            generativeParameters[i] = int256(i * 10); // Simple initial values
        }

        // Initialize the first epoch
        lastEpochStartTime = block.timestamp;
        currentEpochId = 1;
        emit EpochInitialized(currentEpochId, lastEpochStartTime, epochDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyHighReputation() {
        require(reputationScores[_msgSender()] >= minReputationForAttestation, "Caller does not have sufficient reputation.");
        _;
    }

    /* ========== EXTERNAL FUNCTIONS (20+ functions) ========== */

    /**
     * @dev 1. Initializes a new creative epoch. Callable by anyone, but only when the current epoch has ended.
     *      Advances the system to a new phase for contributions and parameter evolution.
     */
    function initializeEpoch() external {
        require(block.timestamp >= lastEpochStartTime.add(epochDuration), "Current epoch not yet ended.");
        
        // This implicitly concludes the previous epoch (currentEpochId), and prepares for the next.
        // Reward calculation for the just-ended epoch should happen here or be triggered from here.
        currentEpochId = currentEpochId.add(1);
        lastEpochStartTime = block.timestamp;
        
        emit EpochInitialized(currentEpochId, lastEpochStartTime, epochDuration);
    }

    /**
     * @dev 2. Allows users to submit creative "inspirations" to the system.
     *      These inspirations (e.g., IPFS URIs of images, text prompts, raw data)
     *      feed the generative model.
     * @param _inspirationURI IPFS/Arweave URI pointing to the inspiration content.
     * @param _category Categorization of the inspiration (e.g., 0: text, 1: image, 2: raw_data).
     */
    function submitInspiration(string memory _inspirationURI, uint256 _category) external {
        require(bytes(_inspirationURI).length > 0, "Inspiration URI cannot be empty");
        _inspirationIdCounter.increment();
        uint256 newId = _inspirationIdCounter.current();

        inspirations[newId] = Inspiration({
            id: newId,
            contributor: _msgSender(),
            inspirationURI: _inspirationURI,
            category: _category,
            epochId: currentEpochId,
            aggregatedQualityScore: 0,
            numAttestations: 0,
            isReported: false,
            isRevealed: true // Direct submission means it's immediately revealed
        });

        emit InspirationSubmitted(newId, _msgSender(), _category, _inspirationURI);
    }

    /**
     * @dev 3. Aggregates inspirations and curation feedback from the current epoch
     *      to evolve the `ChronoGlyph`'s global generative art parameters.
     *      This is the core "collective intelligence" mechanism. Callable by anyone
     *      after an epoch has passed and before a new one initializes.
     */
    function triggerParameterEvolution() external {
        require(block.timestamp >= lastEpochStartTime.add(epochDuration), "Epoch not yet ended for evolution.");

        // In a real system, this logic would be complex:
        // 1. Iterate through inspirations from the *just completed* epoch (currentEpochId - 1).
        // 2. Weight inspirations by their aggregatedQualityScore and numAttestations.
        // 3. Incorporate art curation feedback (artPieceRatings) to fine-tune parameters.
        // 4. Apply a simplified "learning" algorithm to adjust generativeParameters.
        // For demonstration, let's just make a dummy change based on epoch ID and some arbitrary factors:
        for (uint256 i = 0; i < TOTAL_GENERATIVE_PARAMETERS; i++) {
            // Dummy evolution: slightly adjust parameters based on epoch and inspiration count
            // In a real scenario, this would aggregate `aggregatedQualityScore` from inspirations
            // and `artPieceRatings` to influence parameter changes more intelligently.
            // Example: parameters[i] = (parameters[i] * old_weight + new_input * new_weight) / (old_weight + new_weight)
            generativeParameters[i] = generativeParameters[i].add(int256(currentEpochId));
        }

        emit ParametersEvolved(currentEpochId, keccak256(abi.encodePacked(generativeParameters)));
    }

    /**
     * @dev 4. Retrieves the current set of global parameters used for off-chain art generation.
     * @return _params A dynamic array of parameter values.
     */
    function getCurrentGenerativeParameters() external view returns (int256[] memory _params) {
        _params = new int256[](TOTAL_GENERATIVE_PARAMETERS);
        for (uint256 i = 0; i < TOTAL_GENERATIVE_PARAMETERS; i++) {
            _params[i] = generativeParameters[i];
        }
    }

    /**
     * @dev 5. Provides a URI (e.g., to a generative script or dataset) that can be used
     *      off-chain to create art based on the parameters evolved during a specific epoch.
     * @param _epochId The ID of the epoch for which to retrieve the generative art URI.
     * @return The URI for the generative art parameters/script of that epoch.
     */
    function getInspiredArtworkURI(uint256 _epochId) external view returns (string memory) {
        // In a real system, this might return a URI that includes the hash of parameters
        // for a specific epoch, allowing off-chain renderers to fetch precise state.
        // For simplicity, we return a base URI plus the epoch.
        return string(abi.encodePacked(baseGenerativeScriptURI, "?epoch=", Strings.toString(_epochId)));
    }

    /**
     * @dev 6. Mints a unique, dynamic ERC-721 "ChronoGlyph" NFT for the caller.
     *      This Glyph visually represents their accumulated reputation and contribution history,
     *      and its metadata will be dynamically updated.
     *      A user can only mint one ChronoGlyph.
     */
    function mintChronoGlyph() external {
        require(_minterAddressToTokenId[_msgSender()] == 0, "You already own a ChronoGlyph.");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newItemId);

        // Link the ChronoGlyph to the minter's reputation
        // Initial reputation can be 0 or a small positive value
        if (reputationScores[_msgSender()] == 0) {
            reputationScores[_msgSender()] = 1; // Give a tiny starting reputation
        }
        
        // This Glyph's URI will reflect the minter's reputation, not necessarily the current owner's if transferred.
        emit ChronoGlyphMinted(_msgSender(), newItemId);
        _updateChronoGlyphMetadata(_msgSender()); // Update metadata right after mint
    }

    /**
     * @dev 7. Updates the ChronoGlyph's metadata URI, reflecting changes in the user's
     *      reputation, contributions, and the global generative parameters.
     *      This function can be called by the minter to trigger a metadata refresh
     *      for off-chain services.
     * @param _user The address of the ChronoGlyph's original minter whose metadata needs update.
     */
    function updateChronoGlyphMetadata(address _user) external {
        require(_minterAddressToTokenId[_user] != 0, "User does not own a ChronoGlyph (or is not the minter).");
        _updateChronoGlyphMetadata(_user);
    }

    /**
     * @dev Internal function to handle the actual metadata update logic.
     *      This is where the dynamic nature of the NFT comes to life.
     * @param _user The address of the original minter whose reputation dictates metadata.
     */
    function _updateChronoGlyphMetadata(address _user) internal {
        uint256 tokenId = _minterAddressToTokenId[_user];
        
        // Construct a dynamic URI based on user's reputation and current epoch/parameters
        // This URI would point to an off-chain API/service that generates JSON metadata
        // and potentially a dynamic image based on these parameters.
        string memory newURI = string(abi.encodePacked(
            baseGenerativeScriptURI, "/metadata/", Strings.toString(tokenId),
            "?reputation=", Strings.toString(reputationScores[_user]),
            "&epoch=", Strings.toString(currentEpochId),
            "&paramsHash=", Strings.toHexString(uint256(keccak256(abi.encodePacked(generativeParameters))), 32)
        ));
        
        // For a dynamic NFT, typically you override the `tokenURI` getter.
        // An event is emitted here so off-chain services can re-cache the new metadata.
        emit ChronoGlyphMetadataUpdated(_user, tokenId, newURI);
    }

    /**
     * @dev 8. Returns the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev 9. High-reputation users (or a DAO) can attest to the quality of a submitted inspiration.
     *      This directly influences the contributor's reputation and the weight of that inspiration
     *      in parameter evolution.
     * @param _inspirationId The ID of the inspiration to attest.
     * @param _score The quality score (e.g., 1-100).
     */
    function attestContributionQuality(uint256 _inspirationId, uint256 _score) external onlyHighReputation {
        require(inspirations[_inspirationId].contributor != address(0), "Inspiration does not exist.");
        require(inspirations[_inspirationId].isRevealed, "Inspiration must be revealed to be attested.");
        require(_score > 0 && _score <= 100, "Score must be between 1 and 100.");
        require(inspirations[_inspirationId].contributor != _msgSender(), "Cannot attest your own inspiration.");

        // Identify the actual attestor (could be a delegator or themselves)
        address actualAttestor = attestationDelegation[_msgSender()] != address(0) ? attestationDelegation[_msgSender()] : _msgSender();
        require(reputationScores[actualAttestor] >= minReputationForAttestation, "Delegated attestor does not have sufficient reputation.");

        inspirations[_inspirationId].aggregatedQualityScore = inspirations[_inspirationId].aggregatedQualityScore.add(_score);
        inspirations[_inspirationId].numAttestations = inspirations[_inspirationId].numAttestations.add(1);

        // Simple reputation update: contributor gains reputation, attestor gains a bit for valid attestation
        reputationScores[inspirations[_inspirationId].contributor] = reputationScores[inspirations[_inspirationId].contributor].add(_score.div(10)); // Example: 10% of score
        reputationScores[actualAttestor] = reputationScores[actualAttestor].add(1); // Small reward for attesting

        emit ContributionAttested(_inspirationId, _msgSender(), _score);
        emit ReputationUpdated(inspirations[_inspirationId].contributor, reputationScores[inspirations[_inspirationId].contributor]);
        emit ReputationUpdated(actualAttestor, reputationScores[actualAttestor]);

        _updateChronoGlyphMetadata(inspirations[_inspirationId].contributor);
        _updateChronoGlyphMetadata(actualAttestor);
    }

    /**
     * @dev 10. Allows high-reputation users to delegate their power to attest to contribution quality
     *      to another address (until revoked).
     * @param _delegatee The address to delegate attestation power to.
     * @param _enable True to enable delegation, false to disable.
     */
    function delegateAttestationPower(address _delegatee, bool _enable) external onlyHighReputation {
        require(_delegatee != address(0), "Delegatee cannot be zero address.");
        require(_delegatee != _msgSender(), "Cannot delegate to yourself.");

        if (_enable) {
            attestationDelegation[_delegatee] = _msgSender();
            emit AttestationPowerDelegated(_msgSender(), _delegatee);
        } else {
            require(attestationDelegation[_delegatee] == _msgSender(), "Only the delegator can revoke this delegation.");
            delete attestationDelegation[_delegatee];
            emit AttestationPowerDelegated(_msgSender(), address(0)); // Signifies revocation
        }
    }

    /**
     * @dev 11. Retrieves detailed data associated with a user's ChronoGlyph, including its state
     *      derived from reputation.
     * @param _user The address of the user.
     * @return _tokenId The token ID of the user's Glyph.
     * @return _reputation The user's current reputation.
     * @return _inspirationCount The number of inspirations contributed by the user (placeholder).
     * @return _attestationCount The number of attestations made by the user (placeholder).
     */
    function getChronoGlyphData(address _user) external view returns (uint256 _tokenId, uint256 _reputation, uint256 _inspirationCount, uint256 _attestationCount) {
        _tokenId = _minterAddressToTokenId[_user];
        require(_tokenId != 0, "User does not own a ChronoGlyph.");

        _reputation = reputationScores[_user];
        
        // These counts would require iterating through inspirations or maintaining separate
        // aggregate counters per user, which can be gas-expensive. Left as placeholders for now.
        _inspirationCount = 0; 
        _attestationCount = 0; 
    }
    
    // Override _safeMint to track minter's token ID
    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        _minterAddressToTokenId[to] = tokenId;
        _tokenIdToMinterAddress[tokenId] = to; // Track minter for this ID
    }

    // ERC721 `tokenURI` override to provide dynamic metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address minterAddress = _tokenIdToMinterAddress[tokenId]; // Get the original minter address
        require(minterAddress != address(0), "Token not minted or minter not tracked.");

        // Construct the dynamic URI based on the minter's reputation and current system state
        // This ensures the NFT's visuals/metadata reflect the original contributor's journey.
        string memory uri = string(abi.encodePacked(
            baseGenerativeScriptURI, "/metadata/", Strings.toString(tokenId),
            "?reputation=", Strings.toString(reputationScores[minterAddress]),
            "&epoch=", Strings.toString(currentEpochId),
            "&paramsHash=", Strings.toHexString(uint256(keccak256(abi.encodePacked(generativeParameters))), 32)
        ));
        return uri;
    }

    /**
     * @dev 12. Users rate off-chain generated art pieces (identified by a hash)
     *      that were created using the parameters of a specific epoch. These ratings
     *      feedback into future parameter evolution.
     * @param _epochId The ID of the epoch the art piece was generated from.
     * @param _artPieceHash A hash uniquely identifying the generated art piece.
     * @param _rating The rating given to the art piece (e.g., 1-5 stars).
     */
    function curateGeneratedArt(uint256 _epochId, bytes32 _artPieceHash, uint8 _rating) external {
        require(_epochId <= currentEpochId, "Cannot curate art from a future epoch.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        // Store aggregated rating. This data will be used by `triggerParameterEvolution`.
        artPieceRatings[_epochId][_artPieceHash][_rating] = artPieceRatings[_epochId][_artPieceHash][_rating].add(1);

        // Optionally, reward curator or increase reputation for active participation
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(1); // Small reward for active curation
        emit ArtCurated(_epochId, _artPieceHash, _msgSender(), _rating);
        emit ReputationUpdated(_msgSender(), reputationScores[_msgSender()]);
    }

    /**
     * @dev 13. Allows users to flag inspirations deemed inappropriate or malicious.
     *      This can lead to reputation penalties for the contributor or removal of the inspiration.
     * @param _inspirationId The ID of the inspiration to report.
     * @param _reason A string describing the reason for the report.
     */
    function reportMaliciousContent(uint256 _inspirationId, string memory _reason) external {
        require(inspirations[_inspirationId].contributor != address(0), "Inspiration does not exist.");
        require(inspirations[_inspirationId].isRevealed, "Cannot report unrevealed inspiration.");
        require(inspirations[_inspirationId].contributor != _msgSender(), "Cannot report your own inspiration.");
        require(!inspirations[_inspirationId].isReported, "Inspiration already reported.");

        inspirations[_inspirationId].isReported = true; // Mark as reported
        // A more complex system would store multiple reports, reasons, and require majority vote
        // or a dedicated moderation committee.
        
        emit ContentReported(_inspirationId, _msgSender(), _reason);
    }

    /**
     * @dev 14. A moderated function (e.g., by DAO or trusted committee, here by owner)
     *      to review and resolve reported content, applying penalties or clearing flags.
     * @param _inspirationId The ID of the inspiration to resolve.
     * @param _isValid True if the report is valid (content is indeed malicious/inappropriate), false otherwise.
     */
    function resolveReport(uint256 _inspirationId, bool _isValid) external onlyOwner {
        require(inspirations[_inspirationId].contributor != address(0), "Inspiration does not exist.");
        require(inspirations[_inspirationId].isReported, "Inspiration not reported.");

        if (_isValid) {
            // Apply penalty to contributor's reputation
            reputationScores[inspirations[_inspirationId].contributor] = reputationScores[inspirations[_inspirationId].contributor].div(2); // Halve reputation
            // Mark inspiration as potentially "disabled" or "removed" if needed
            inspirations[_inspirationId].inspirationURI = ""; // Clear URI as a form of removal/disabling
        } else {
            inspirations[_inspirationId].isReported = false; // Clear flag
            // Optionally, reward the reporter for valid reports or penalize for false ones
        }
        emit ReportResolved(_inspirationId, _isValid, _msgSender());
        emit ReputationUpdated(inspirations[_inspirationId].contributor, reputationScores[inspirations[_inspirationId].contributor]);
        _updateChronoGlyphMetadata(inspirations[_inspirationId].contributor);
    }

    /**
     * @dev 15. Allows users to commit to an inspiration privately first (by submitting its hash),
     *      then reveal it later. This is a simple privacy-preserving mechanism to prevent front-running.
     *      The original hash should be `keccak256(abi.encodePacked(_inspirationURI, _category, _nonce))`.
     * @param _hashOfInspiration The keccak256 hash of the full inspiration data + a nonce.
     * @param _category Categorization of the inspiration.
     */
    function submitSealedInspiration(bytes32 _hashOfInspiration, uint256 _category) external {
        require(sealedInspirations[_hashOfInspiration] == 0, "Commitment already exists or invalid hash.");
        _inspirationIdCounter.increment();
        uint256 newId = _inspirationIdCounter.current();

        inspirations[newId] = Inspiration({
            id: newId,
            contributor: _msgSender(),
            inspirationURI: "", // URI is empty until revealed
            category: _category,
            epochId: currentEpochId,
            aggregatedQualityScore: 0,
            numAttestations: 0,
            isReported: false,
            isRevealed: false // Mark as not revealed yet
        });
        sealedInspirations[_hashOfInspiration] = newId;

        emit InspirationSealed(newId, _msgSender(), _hashOfInspiration, _category);
    }

    /**
     * @dev 16. Reveals a previously committed inspiration. The contract verifies the hash
     *      matches the initial commitment.
     * @param _inspirationURI The actual URI of the inspiration.
     * @param _category The category, must match the committed category.
     * @param _nonce A unique nonce used in the original hashing for commit-reveal.
     */
    function revealSealedInspiration(string memory _inspirationURI, uint256 _category, bytes32 _nonce) external {
        bytes32 computedHash = keccak256(abi.encodePacked(_inspirationURI, _category, _nonce));
        uint256 inspirationId = sealedInspirations[computedHash];

        require(inspirationId != 0, "No sealed inspiration found for this hash.");
        require(inspirations[inspirationId].contributor == _msgSender(), "Only the committer can reveal.");
        require(!inspirations[inspirationId].isRevealed, "Inspiration already revealed.");
        require(inspirations[inspirationId].category == _category, "Category mismatch with commitment.");

        inspirations[inspirationId].inspirationURI = _inspirationURI;
        inspirations[inspirationId].isRevealed = true;
        
        // Clear the commitment mapping to prevent re-revealing and save gas
        delete sealedInspirations[computedHash];

        emit InspirationRevealed(inspirationId, _msgSender(), _inspirationURI);
    }

    /**
     * @dev 17. Users can propose direct overrides to specific generative parameters.
     *      These proposals require DAO (or owner) approval.
     * @param _paramIndex The index of the generative parameter to override.
     * @param _newValue The proposed new value for the parameter.
     * @param _rationale A string explaining the reason for the proposed change.
     */
    function proposeParameterOverride(uint256 _paramIndex, int256 _newValue, string memory _rationale) external {
        require(_paramIndex < TOTAL_GENERATIVE_PARAMETERS, "Invalid parameter index.");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        parameterOverrideProposals[proposalId] = ParameterOverrideProposal({
            proposalId: proposalId,
            paramIndex: _paramIndex,
            newValue: _newValue,
            rationale: _rationale,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            approved: false
        });
        // Initial vote by proposer, weighted by their reputation
        voteOnParameterOverride(proposalId, true);

        emit ParameterOverrideProposed(proposalId, _paramIndex, _newValue, _rationale);
    }

    /**
     * @dev 18. Allows DAO members (or token holders with voting power) to vote on
     *      proposed parameter overrides. Requires sufficient reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnParameterOverride(uint256 _proposalId, bool _support) external onlyHighReputation {
        ParameterOverrideProposal storage proposal = parameterOverrideProposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist.");
        require(!proposal.executed, "Proposal already executed.");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal.");

        proposal.hasVoted[_msgSender()] = true;
        uint256 voteWeight = reputationScores[_msgSender()]; // Vote weight by reputation
        
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }

        // Simple approval logic: if votesFor > votesAgainst by a margin and a minimum quorum of votes is met.
        // For demonstration, let's say if votesFor > votesAgainst and total votes (by reputation) > (minReputationForAttestation * 5).
        if (proposal.votesFor > proposal.votesAgainst && (proposal.votesFor.add(proposal.votesAgainst)) >= (minReputationForAttestation.mul(5))) {
            proposal.approved = true;
            if (!proposal.executed) {
                generativeParameters[proposal.paramIndex] = proposal.newValue;
                proposal.executed = true;
                emit ParameterOverrideExecuted(_proposalId, proposal.paramIndex, proposal.newValue);
                emit ParametersEvolved(currentEpochId, keccak256(abi.encodePacked(generativeParameters)));
            }
        }
        emit ParameterOverrideVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev 19. Allows users to claim rewards for their positive contributions and effective curation
     *      within a completed epoch, based on their reputation gain or contribution score.
     *      Assumes rewards are calculated at epoch end or on demand.
     *      This function currently only records the claim. Actual token transfer logic needs to be added.
     *      For demonstration, let's make it claim rewards from the *previous* completed epoch.
     */
    function claimEpochReward() external {
        uint256 claimableEpoch = currentEpochId.sub(1); // Rewards for the previous epoch
        require(claimableEpoch > 0, "No previous epoch for rewards.");
        
        // This is a placeholder for reward calculation logic.
        // In a real system, `epochRewards[claimableEpoch][_msgSender()]` would be populated
        // based on user's contribution quality, curation activity, and reputation gain in that epoch.
        // For simplicity, let's just assume a small dummy reward for being active.
        uint256 rewardAmount = reputationScores[_msgSender()].div(10); 
        require(rewardAmount > 0, "No rewards to claim for this epoch or already claimed.");
        
        // Ensure rewards are only claimed once per epoch per user
        require(epochRewards[claimableEpoch][_msgSender()] == 0, "Rewards for this epoch already calculated/claimed.");
        
        epochRewards[claimableEpoch][_msgSender()] = rewardAmount; // Store as claimable

        // Transfer actual tokens (ETH or ERC20)
        // If ETH: payable(_msgSender()).transfer(rewardAmount);
        // If ERC20: require(rewardToken.transfer(_msgSender(), rewardAmount), "Token transfer failed.");
        
        claimedEpochRewards[_msgSender()] = claimedEpochRewards[_msgSender()].add(rewardAmount); // Track total claimed
        emit EpochRewardClaimed(_msgSender(), claimableEpoch, rewardAmount);
    }

    /**
     * @dev 20. Admin/DAO function to adjust core system configurations.
     * @param _newEpochDuration The new duration for each epoch in seconds.
     * @param _minReputationForAttestation The new minimum reputation required for attestation.
     */
    function setSystemParameters(uint256 _newEpochDuration, uint256 _minReputationForAttestation) external onlyOwner {
        require(_newEpochDuration > 0, "Epoch duration must be positive.");
        epochDuration = _newEpochDuration;
        minReputationForAttestation = _minRepReputationForAttestation;
        emit SystemParametersSet(_newEpochDuration, _minReputationForAttestation);
    }
}
```