```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Outline and Function Summary:
//
// Contract Name: EnigmaEngine
//
// This contract introduces a novel decentralized platform called "Enigma Engine"
// designed for emergent knowledge, reputation, and AI-assisted creative collaboration.
// It combines dynamic Soulbound NFTs, an ERC20 utility token, a concept proposal
// and curation system, and AI-assisted artifact generation via oracles.
// Access to exclusive "Revelation Archives" is gated by the dynamic reputation
// embedded within the Soulbound NFTs and a utility token burn mechanism.
//
// I. Core Setup & Ownership (Admin-controlled functions for contract management):
//    1. constructor(): Initializes the contract with an owner, and sets up ERC20 and ERC721 components.
//    2. setOracleAddress(address _oracle): Sets the address for the AI/data oracle, crucial for artifact generation.
//    3. setCuratorOracleAddress(address _curatorOracle): Designates an address (e.g., a DAO contract or trusted oracle)
//       responsible for awarding Enigma Shards based on contributions.
//    4. setFeeRecipient(address _recipient): Specifies the address that receives protocol fees (e.g., from concept proposals).
//    5. pauseContract(): Temporarily pauses certain user-facing functionalities (e.g., proposals, artifact generation) in emergencies.
//    6. unpauseContract(): Resumes paused functionalities.
//    7. withdrawETH(): Allows the contract owner to withdraw accumulated ETH fees.
//    8. withdrawERC20(address tokenAddress): Allows the contract owner to withdraw any accidentally sent ERC20 tokens.
//
// II. Enigma Shards (ERC20 Utility Token - $ENG)
//    This token facilitates interactions, rewards contributions, and is burned for access.
//    9. awardShardsForContribution(address _to, uint256 _amount, uint256 _conceptId): Awards Enigma Shards to a user
//       for approved contributions (e.g., high-quality concepts, valuable feedback). Callable only by `curatorOracle`.
//    10. burnShardsForAccess(uint256 _amount, uint256 _archiveId): Users burn Shards to access premium features or Revelation Archives.
//    11. getShardBalance(address _user): Retrieves the current Enigma Shard balance of a user.
//
// III. Conduit Glyphs (Dynamic Soulbound NFTs - Non-transferable ERC721)
//     These NFTs are unique to each user, non-transferable, and their metadata dynamically
//     updates based on the user's on-chain reputation.
//    12. mintConduitGlyph(): Allows a user to mint their initial Soulbound NFT. This is a one-time action per user
//        and typically requires a shard payment.
//    13. _updateConduitGlyphReputation(address _user, int256 _scoreChange): Internal function to adjust a user's
//        reputation score and potentially trigger an update to their Glyph's tier and metadata.
//    14. getConduitGlyphTier(uint256 _tokenId): Returns the current reputation tier of a specific Conduit Glyph.
//    15. hasConduitGlyph(address _user): Checks if a given address possesses a Conduit Glyph.
//    16. getConduitGlyphId(address _user): Retrieves the token ID of the Conduit Glyph owned by a specific user.
//    17. tokenURI(uint256 _tokenId): Overrides the standard ERC721 function to provide a dynamic metadata URI
//        for the Glyph, reflecting its current reputation tier.
//
// IV. Concept Proposal & Curation
//    Users can propose new ideas ("Concepts") and collectively curate them through voting.
//    18. proposeConcept(string memory _conceptTitle, string memory _conceptURI): Allows users to submit new ideas,
//        requiring a small shard fee.
//    19. curateConcept(uint256 _conceptId, bool _isUpvote): Users vote up or down on existing Concepts.
//        This action influences the proposer's reputation.
//    20. submitCuratorFeedback(uint256 _conceptId, string memory _feedbackURI): Users can provide more detailed,
//        off-chain feedback on a Concept, stored via URI on-chain.
//    21. updateConceptStatus(uint256 _conceptId, ConceptStatus _newStatus): Allows the `curatorOracle` to update
//        the formal status of a concept, impacting proposer's reputation and shard rewards.
//    22. getConceptDetails(uint256 _conceptId): Retrieves the title, proposer, and current vote count for a Concept.
//    23. getConceptStatus(uint256 _conceptId): Returns the current status of a Concept (e.g., pending, approved, rejected).
//
// V. Revelation Archives (Token-Gated Content)
//    Exclusive content accessible only to users meeting specific Conduit Glyph tier and shard burning requirements.
//    24. createRevelationArchive(string memory _title, string memory _contentURI, uint256 _requiredTier, uint256 _shardCost):
//        Admin function to create new token-gated archives with specified access requirements.
//    25. accessRevelationArchive(uint256 _archiveId): Allows users to attempt accessing an archive.
//        Checks Glyph tier and burns required Shards. Returns the content URI upon successful access.
//    26. getArchiveMetadata(uint256 _archiveId): Retrieves the title, content URI, required tier, and shard cost for an archive.
//
// VI. AI-Assisted Artifact Generation (Oracle Interaction)
//    Integrates with an AI oracle to generate "Artifacts" (e.g., text, code, images) based on approved Concepts.
//    27. requestArtifactGeneration(uint256 _conceptId, string memory _generationPrompt): Users request an AI-generated
//        Artifact for a specific Concept, requiring a shard payment. This triggers an off-chain oracle call.
//    28. fulfillArtifactGeneration(bytes32 _requestId, uint256 _conceptId, string memory _artifactURI, uint256 _rewardAmount):
//        Callback function for the AI oracle. It records the generated Artifact's URI and potentially rewards the requestor.
//    29. getLatestArtifactURI(uint256 _conceptId): Retrieves the URI of the most recently generated Artifact for a Concept.
//
// This contract aims to foster a dynamic, reputation-based ecosystem for decentralized creativity and knowledge.

contract EnigmaEngine is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Configuration Constants ---
    uint256 public constant INITIAL_REPUTATION = 100; // Starting reputation for a new glyph
    uint256 public constant MIN_REPUTATION = 0;      // Minimum possible reputation
    uint256 public constant MAX_REPUTATION = 1000;   // Maximum possible reputation

    // Tier thresholds and base URIs for Conduit Glyphs (reputation tiers)
    // Reputation scores map to these tiers:
    // 0-99: Tier 0 (Initiator)
    // 100-299: Tier 1 (Explorer)
    // 300-599: Tier 2 (Coder)
    // 600-899: Tier 3 (Visionary)
    // 900-1000: Tier 4 (Architect)
    uint256[] public glyphTierThresholds = [0, 100, 300, 600, 900];
    string[] public glyphTierBaseURIs = [
        "ipfs://Qmbn7B5p9a8d7c6b5a4f3e2d1c0b9a8s7d6f5g4h3j2k1l", // Tier 0: Initiator (Placeholder)
        "ipfs://QmWf4X3q2s1t0y9r8e7w6q5p4o3i2u1y0t9r8e7w6q5p4o", // Tier 1: Explorer (Placeholder)
        "ipfs://QmYh2Z1a0b9c8d7e6f5g4h3i2j1k0l9m8n7o6p5q4r3s2t", // Tier 2: Coder (Placeholder)
        "ipfs://QmVc9R7s6d5f4g3h2j1k0l9m8n7b6v5c4x3z2y1x0w9v8u", // Tier 3: Visionary (Placeholder)
        "ipfs://QmXp6W2e1r0t9y8u7i6o5p4a3s2d1f0g9h8j7k6l5m4n3b"  // Tier 4: Architect (Placeholder)
    ];

    // --- Core Contracts ---
    EnigmaShards public shards;
    ConduitGlyphs public glyphs;

    // --- Admin/Oracle Addresses ---
    address public oracleAddress; // For AI artifact generation
    address public curatorOracleAddress; // For awarding shards & concept status updates
    address public feeRecipient; // Receives protocol fees

    // --- Counters ---
    Counters.Counter private _conceptIdCounter;
    Counters.Counter private _archiveIdCounter;
    Counters.Counter private _glyphTokenIdCounter; // For ConduitGlyphs ERC721

    // --- Data Structures ---

    enum ConceptStatus { Pending, Approved, Rejected }

    struct Concept {
        uint256 id;
        address proposer;
        string title;
        string conceptURI; // Link to off-chain details of the concept
        int256 upvotes;
        int256 downvotes;
        ConceptStatus status;
        string latestArtifactURI; // Updated by fulfillArtifactGeneration
        mapping(address => bool) hasVoted; // For unique voting per user
    }
    mapping(uint256 => Concept) public concepts;
    mapping(bytes32 => uint256) public pendingArtifactRequests; // requestId -> conceptId
    mapping(bytes32 => address) public s_requestIdToRequester; // requestId -> original requester address

    struct RevelationArchive {
        uint256 id;
        string title;
        string contentURI;
        uint256 requiredTier;
        uint256 shardCost;
    }
    mapping(uint256 => RevelationArchive) public archives;

    // --- Mappings for Conduit Glyphs & Reputation ---
    mapping(address => uint256) private s_userToGlyphId; // Address -> Glyph Token ID
    mapping(uint256 => address) private s_glyphIdToUser; // Glyph Token ID -> Address
    mapping(uint256 => int256) private s_glyphIdToReputation; // Glyph Token ID -> Reputation Score

    // --- Events ---
    event OracleAddressSet(address indexed _newOracleAddress);
    event CuratorOracleAddressSet(address indexed _newCuratorOracleAddress);
    event FeeRecipientSet(address indexed _newFeeRecipient);
    event EnigmaShardsAwarded(address indexed _to, uint256 _amount, uint256 indexed _conceptId);
    event EnigmaShardsBurned(address indexed _burner, uint256 _amount, uint256 indexed _archiveId);
    event ConduitGlyphMinted(address indexed _owner, uint256 indexed _tokenId);
    event ConduitGlyphReputationUpdated(uint256 indexed _tokenId, int256 _newReputation, uint256 _newTier);
    event ConceptProposed(uint256 indexed _conceptId, address indexed _proposer, string _title, string _uri);
    event ConceptCurated(uint256 indexed _conceptId, address indexed _curator, bool _isUpvote, int256 _upvotes, int256 _downvotes);
    event ConceptFeedbackSubmitted(uint256 indexed _conceptId, address indexed _submitter, string _feedbackURI);
    event ConceptStatusUpdated(uint256 indexed _conceptId, ConceptStatus _newStatus);
    event RevelationArchiveCreated(uint256 indexed _archiveId, string _title, uint256 _requiredTier, uint256 _shardCost);
    event RevelationArchiveAccessed(uint256 indexed _archiveId, address indexed _accessor);
    event ArtifactGenerationRequested(uint256 indexed _conceptId, address indexed _requester, bytes32 _requestId, string _prompt);
    event ArtifactGenerationFulfilled(uint256 indexed _conceptId, string _artifactURI);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EnigmaEngine: Only callable by oracle");
        _;
    }

    modifier onlyCuratorOracle() {
        require(msg.sender == curatorOracleAddress, "EnigmaEngine: Only callable by curator oracle");
        _;
    }

    modifier mustHoldGlyph() {
        require(hasConduitGlyph(msg.sender), "EnigmaEngine: Caller must hold a Conduit Glyph");
        _;
    }

    // --- Constructor ---
    constructor(
        address _initialOwner,
        address _oracleAddress,
        address _curatorOracleAddress,
        address _feeRecipient
    ) Ownable(_initialOwner) {
        shards = new EnigmaShards();
        // Pass address(this) to ConduitGlyphs so it can restrict `setTokenURI` calls
        glyphs = new ConduitGlyphs(address(this)); 
        oracleAddress = _oracleAddress;
        curatorOracleAddress = _curatorOracleAddress;
        feeRecipient = _feeRecipient;

        emit OracleAddressSet(_oracleAddress);
        emit CuratorOracleAddressSet(_curatorOracleAddress);
        emit FeeRecipientSet(_feeRecipient);
    }

    // --- I. Core Setup & Ownership ---

    /// @notice Sets the address of the AI/data oracle.
    /// @param _oracle The new oracle address.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "EnigmaEngine: Invalid oracle address");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /// @notice Sets the address of the curator oracle/contract responsible for awarding shards.
    /// @param _curatorOracle The new curator oracle address.
    function setCuratorOracleAddress(address _curatorOracle) external onlyOwner {
        require(_curatorOracle != address(0), "EnigmaEngine: Invalid curator oracle address");
        curatorOracleAddress = _curatorOracle;
        emit CuratorOracleAddressSet(_curatorOracle);
    }

    /// @notice Sets the address to receive protocol fees.
    /// @param _recipient The new fee recipient address.
    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "EnigmaEngine: Invalid fee recipient address");
        feeRecipient = _recipient;
        emit FeeRecipientSet(_recipient);
    }

    /// @notice Pauses certain contract functionalities.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract functionalities.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Withdraws accumulated ETH fees from the contract.
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "EnigmaEngine: No ETH to withdraw");
        (bool success, ) = payable(feeRecipient).call{value: balance}("");
        require(success, "EnigmaEngine: ETH withdrawal failed");
    }

    /// @notice Withdraws any ERC20 tokens accidentally sent to the contract.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    function withdrawERC20(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(shards), "EnigmaEngine: Cannot withdraw native Enigma Shards");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "EnigmaEngine: No ERC20 tokens to withdraw");
        token.transfer(feeRecipient, balance);
    }

    // --- II. Enigma Shards (ERC20 Utility Token) ---

    /// @notice Awards Enigma Shards for a validated contribution. Only callable by the curator oracle.
    /// @param _to The recipient of the shards.
    /// @param _amount The amount of shards to award.
    /// @param _conceptId The concept related to this contribution (for tracking).
    function awardShardsForContribution(address _to, uint256 _amount, uint256 _conceptId) external onlyCuratorOracle {
        shards.mint(_to, _amount);
        emit EnigmaShardsAwarded(_to, _amount, _conceptId);
    }

    /// @notice Burns Enigma Shards from the caller to access premium features or archives.
    /// @param _amount The amount of shards to burn.
    /// @param _archiveId The archive ID related to the access (0 if not archive specific).
    function burnShardsForAccess(uint256 _amount, uint256 _archiveId) external mustHoldGlyph whenNotPaused {
        shards.burn(msg.sender, _amount);
        emit EnigmaShardsBurned(msg.sender, _amount, _archiveId);
    }

    /// @notice Retrieves the current Enigma Shard balance of a user.
    /// @param _user The address of the user.
    /// @return The shard balance.
    function getShardBalance(address _user) external view returns (uint256) {
        return shards.balanceOf(_user);
    }

    // --- III. Conduit Glyphs (Dynamic Soulbound NFTs) ---

    /// @notice Allows a user to mint their initial Soulbound NFT.
    /// Requires a shard payment and can only be called once per address.
    function mintConduitGlyph() external whenNotPaused {
        require(s_userToGlyphId[msg.sender] == 0, "EnigmaEngine: You already possess a Conduit Glyph.");

        // Define a small shard cost for minting, can be 0 or dynamic.
        uint256 mintCost = 10 * (10 ** shards.decimals()); // e.g., 10 Shards
        require(shards.balanceOf(msg.sender) >= mintCost, "EnigmaEngine: Insufficient Shards to mint Glyph.");

        shards.burn(msg.sender, mintCost); // Burn shards for minting

        _glyphTokenIdCounter.increment();
        uint256 newTokenId = _glyphTokenIdCounter.current();

        glyphs._mint(msg.sender, newTokenId);
        s_userToGlyphId[msg.sender] = newTokenId;
        s_glyphIdToUser[newTokenId] = msg.sender;
        s_glyphIdToReputation[newTokenId] = INITIAL_REPUTATION; // Set initial reputation

        // Update metadata based on initial reputation
        _updateConduitGlyphMetadata(newTokenId, _getGlyphTokenURI(newTokenId, INITIAL_REPUTATION));

        emit ConduitGlyphMinted(msg.sender, newTokenId);
        emit ConduitGlyphReputationUpdated(newTokenId, INITIAL_REPUTATION, _getTierFromReputation(INITIAL_REPUTATION));
    }

    /// @notice Internal function to adjust a user's reputation score and potentially trigger an update to their Glyph's tier and metadata.
    /// @param _user The address of the user whose reputation is to be updated.
    /// @param _scoreChange The change in reputation score (can be positive or negative).
    function _updateConduitGlyphReputation(address _user, int256 _scoreChange) internal {
        uint256 tokenId = s_userToGlyphId[_user];
        require(tokenId != 0, "EnigmaEngine: User does not have a Conduit Glyph.");

        int256 currentReputation = s_glyphIdToReputation[tokenId];
        int256 newReputation = currentReputation + _scoreChange;

        // Clamp reputation within min/max bounds
        if (newReputation < int256(MIN_REPUTATION)) newReputation = int256(MIN_REPUTATION);
        if (newReputation > int256(MAX_REPUTATION)) newReputation = int256(MAX_REPUTATION);

        s_glyphIdToReputation[tokenId] = newReputation;

        uint256 oldTier = _getTierFromReputation(currentReputation);
        uint256 newTier = _getTierFromReputation(newReputation);

        if (oldTier != newTier) {
            // Only update URI if tier changes
            _updateConduitGlyphMetadata(tokenId, _getGlyphTokenURI(tokenId, newReputation));
        }

        emit ConduitGlyphReputationUpdated(tokenId, newReputation, newTier);
    }

    /// @notice Internal function to determine the glyph tier based on reputation score.
    /// @param _reputation The reputation score.
    /// @return The tier number.
    function _getTierFromReputation(int256 _reputation) internal view returns (uint256) {
        for (uint256 i = glyphTierThresholds.length - 1; i >= 0; i--) {
            if (_reputation >= int256(glyphTierThresholds[i])) {
                return i;
            }
            if (i == 0) break; // Prevent underflow for i-1 (though loop condition handles it)
        }
        return 0; // Default to lowest tier if no threshold met (e.g., negative reputation)
    }

    /// @notice Internal function to construct the dynamic token URI.
    /// @param _tokenId The ID of the Glyph.
    /// @param _reputation The reputation score for that Glyph.
    /// @return The dynamic token URI.
    function _getGlyphTokenURI(uint256 _tokenId, int256 _reputation) internal view returns (string memory) {
        uint256 tier = _getTierFromReputation(_reputation);
        require(tier < glyphTierBaseURIs.length, "EnigmaEngine: Invalid tier for URI mapping.");

        // Concatenate base URI with token ID and .json for simple dynamic metadata structure
        return string(abi.encodePacked(glyphTierBaseURIs[tier], "/", _tokenId.toString(), ".json"));
    }

    /// @notice Allows the contract to update the NFT's metadata (e.g., based on reputation changes).
    /// @param _tokenId The ID of the Glyph to update.
    /// @param _newURI The new metadata URI.
    function _updateConduitGlyphMetadata(uint256 _tokenId, string memory _newURI) internal {
        // This calls the `setTokenURI` function on the ConduitGlyphs contract
        glyphs.setTokenURI(_tokenId, _newURI);
    }

    /// @notice Returns the current reputation tier of a glyph.
    /// @param _tokenId The ID of the Conduit Glyph.
    /// @return The tier number.
    function getConduitGlyphTier(uint256 _tokenId) external view returns (uint256) {
        require(glyphs.exists(_tokenId), "EnigmaEngine: Glyph does not exist.");
        return _getTierFromReputation(s_glyphIdToReputation[_tokenId]);
    }

    /// @notice Checks if a user possesses a Conduit Glyph.
    /// @param _user The address of the user.
    /// @return True if the user has a glyph, false otherwise.
    function hasConduitGlyph(address _user) public view returns (bool) {
        return s_userToGlyphId[_user] != 0;
    }

    /// @notice Returns the glyph ID for a user.
    /// @param _user The address of the user.
    /// @return The token ID of the user's Glyph, or 0 if none.
    function getConduitGlyphId(address _user) external view returns (uint256) {
        return s_userToGlyphId[_user];
    }

    /// @notice Overrides standard ERC721 tokenURI to provide dynamic metadata based on reputation tier.
    /// @param _tokenId The ID of the Glyph.
    /// @return The dynamic metadata URI.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return glyphs.tokenURI(_tokenId);
    }

    // --- IV. Concept Proposal & Curation ---

    /// @notice Users propose new ideas/concepts. Requires a small shard fee.
    /// @param _conceptTitle The title of the concept.
    /// @param _conceptURI Link to off-chain details of the concept (e.g., IPFS).
    function proposeConcept(string memory _conceptTitle, string memory _conceptURI) external mustHoldGlyph whenNotPaused returns (uint256) {
        require(bytes(_conceptTitle).length > 0, "EnigmaEngine: Concept title cannot be empty.");
        require(bytes(_conceptURI).length > 0, "EnigmaEngine: Concept URI cannot be empty.");

        // Concept proposal fee
        uint256 proposalFee = 5 * (10 ** shards.decimals()); // e.g., 5 Shards
        require(shards.balanceOf(msg.sender) >= proposalFee, "EnigmaEngine: Insufficient Shards for proposal fee.");

        shards.burn(msg.sender, proposalFee); // Burn fee

        _conceptIdCounter.increment();
        uint256 newConceptId = _conceptIdCounter.current();

        Concept storage newConcept = concepts[newConceptId];
        newConcept.id = newConceptId;
        newConcept.proposer = msg.sender;
        newConcept.title = _conceptTitle;
        newConcept.conceptURI = _conceptURI;
        newConcept.status = ConceptStatus.Pending;
        newConcept.upvotes = 0;
        newConcept.downvotes = 0;

        // Optionally, initial reputation boost for proposing a concept
        _updateConduitGlyphReputation(msg.sender, 5);

        emit ConceptProposed(newConceptId, msg.sender, _conceptTitle, _conceptURI);
        return newConceptId;
    }

    /// @notice Users vote on concepts. Influences proposer's reputation.
    /// @param _conceptId The ID of the concept to curate.
    /// @param _isUpvote True for an upvote, false for a downvote.
    function curateConcept(uint256 _conceptId, bool _isUpvote) external mustHoldGlyph whenNotPaused {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        require(concept.proposer != msg.sender, "EnigmaEngine: Cannot curate your own concept.");
        require(!concept.hasVoted[msg.sender], "EnigmaEngine: You have already voted on this concept.");

        if (_isUpvote) {
            concept.upvotes++;
            _updateConduitGlyphReputation(concept.proposer, 2); // Small boost for proposer
            _updateConduitGlyphReputation(msg.sender, 1);       // Small boost for curator
        } else {
            concept.downvotes++;
            _updateConduitGlyphReputation(concept.proposer, -2); // Small penalty for proposer
            // No penalty/reward for downvoting curator, could be added.
        }
        concept.hasVoted[msg.sender] = true;

        emit ConceptCurated(_conceptId, msg.sender, _isUpvote, concept.upvotes, concept.downvotes);
    }

    /// @notice Users provide detailed feedback (off-chain storage, URI on-chain).
    /// @param _conceptId The ID of the concept.
    /// @param _feedbackURI Link to off-chain feedback details.
    function submitCuratorFeedback(uint256 _conceptId, string memory _feedbackURI) external mustHoldGlyph whenNotPaused {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        require(bytes(_feedbackURI).length > 0, "EnigmaEngine: Feedback URI cannot be empty.");

        // A more advanced system might use the curatorOracle to validate feedback quality
        // and award shards for high-quality submissions. For simplicity, just recording the URI.

        emit ConceptFeedbackSubmitted(_conceptId, msg.sender, _feedbackURI);
    }

    /// @notice Allows the curator oracle to update the status of a concept.
    /// @param _conceptId The ID of the concept.
    /// @param _newStatus The new status for the concept.
    function updateConceptStatus(uint256 _conceptId, ConceptStatus _newStatus) external onlyCuratorOracle {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        require(concept.status != _newStatus, "EnigmaEngine: Concept already has this status.");

        concept.status = _newStatus;
        emit ConceptStatusUpdated(_conceptId, _newStatus);

        // Award proposer if concept is approved, penalize if rejected.
        if (_newStatus == ConceptStatus.Approved) {
            _updateConduitGlyphReputation(concept.proposer, 20); // Significant boost for approval
            shards.mint(concept.proposer, 50 * (10 ** shards.decimals())); // Reward shards
        } else if (_newStatus == ConceptStatus.Rejected) {
            _updateConduitGlyphReputation(concept.proposer, -10); // Penalty for rejection
        }
    }

    /// @notice Retrieves concept details.
    /// @param _conceptId The ID of the concept.
    /// @return title, proposer, conceptURI, upvotes, downvotes, status.
    function getConceptDetails(uint256 _conceptId) external view returns (string memory title, address proposer, string memory conceptURI, int256 upvotes, int256 downvotes, ConceptStatus status) {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        return (concept.title, concept.proposer, concept.conceptURI, concept.upvotes, concept.downvotes, concept.status);
    }

    /// @notice Retrieves the current status of a concept.
    /// @param _conceptId The ID of the concept.
    /// @return The status of the concept.
    function getConceptStatus(uint256 _conceptId) external view returns (ConceptStatus) {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        return concept.status;
    }

    // --- V. Revelation Archives (Token-Gated Content) ---

    /// @notice Admin creates new gated archives.
    /// @param _title The title of the archive.
    /// @param _contentURI Link to the exclusive content.
    /// @param _requiredTier The minimum Glyph tier required to access.
    /// @param _shardCost The amount of shards to burn for access.
    function createRevelationArchive(string memory _title, string memory _contentURI, uint256 _requiredTier, uint256 _shardCost) external onlyOwner {
        require(bytes(_title).length > 0, "EnigmaEngine: Archive title cannot be empty.");
        require(bytes(_contentURI).length > 0, "EnigmaEngine: Content URI cannot be empty.");
        require(_requiredTier < glyphTierThresholds.length, "EnigmaEngine: Invalid required tier.");

        _archiveIdCounter.increment();
        uint256 newArchiveId = _archiveIdCounter.current();

        RevelationArchive storage newArchive = archives[newArchiveId];
        newArchive.id = newArchiveId;
        newArchive.title = _title;
        newArchive.contentURI = _contentURI;
        newArchive.requiredTier = _requiredTier;
        newArchive.shardCost = _shardCost;

        emit RevelationArchiveCreated(newArchiveId, _title, _requiredTier, _shardCost);
    }

    /// @notice Users attempt to access an archive. Checks glyph tier and burns shards.
    /// @param _archiveId The ID of the archive to access.
    /// @return The content URI if access is granted.
    function accessRevelationArchive(uint256 _archiveId) external mustHoldGlyph whenNotPaused returns (string memory) {
        RevelationArchive storage archive = archives[_archiveId];
        require(archive.id != 0, "EnigmaEngine: Archive does not exist.");

        uint256 userGlyphId = s_userToGlyphId[msg.sender];
        uint256 userTier = _getTierFromReputation(s_glyphIdToReputation[userGlyphId]);

        require(userTier >= archive.requiredTier, "EnigmaEngine: Insufficient Glyph tier to access this archive.");
        require(shards.balanceOf(msg.sender) >= archive.shardCost, "EnigmaEngine: Insufficient Shards to access this archive.");

        shards.burn(msg.sender, archive.shardCost);
        emit RevelationArchiveAccessed(_archiveId, msg.sender);

        return archive.contentURI;
    }

    /// @notice Retrieves archive metadata (title, requirements).
    /// @param _archiveId The ID of the archive.
    /// @return title, contentURI, requiredTier, shardCost.
    function getArchiveMetadata(uint256 _archiveId) external view returns (string memory title, string memory contentURI, uint256 requiredTier, uint256 shardCost) {
        RevelationArchive storage archive = archives[_archiveId];
        require(archive.id != 0, "EnigmaEngine: Archive does not exist.");
        return (archive.title, archive.contentURI, archive.requiredTier, archive.shardCost);
    }

    // --- VI. AI-Assisted Artifact Generation (Oracle Interaction) ---

    /// @notice User requests an AI-generated artifact based on an approved concept.
    /// Requires shard payment. Triggers oracle call (simulated).
    /// @param _conceptId The ID of the concept to generate an artifact for.
    /// @param _generationPrompt The prompt/instruction for the AI.
    /// @return The unique request ID for tracking the oracle call.
    function requestArtifactGeneration(uint256 _conceptId, string memory _generationPrompt) external mustHoldGlyph whenNotPaused returns (bytes32) {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        require(concept.status == ConceptStatus.Approved, "EnigmaEngine: Only approved concepts can have artifacts generated.");
        require(bytes(_generationPrompt).length > 0, "EnigmaEngine: Generation prompt cannot be empty.");

        uint256 generationCost = 20 * (10 ** shards.decimals()); // e.g., 20 Shards
        require(shards.balanceOf(msg.sender) >= generationCost, "EnigmaEngine: Insufficient Shards for artifact generation.");

        shards.burn(msg.sender, generationCost);

        // Simulate a Chainlink-like request ID.
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _conceptId, _generationPrompt));
        pendingArtifactRequests[requestId] = _conceptId;
        s_requestIdToRequester[requestId] = msg.sender; // Store the original requester

        emit ArtifactGenerationRequested(_conceptId, msg.sender, requestId, _generationPrompt);

        // In a real Chainlink integration, this would call Chainlink's `requestBytes` or `requestString` function.
        // For this example, the oracle will directly call `fulfillArtifactGeneration` using this `requestId`.
        return requestId;
    }

    /// @notice Callback function for the AI oracle to fulfill an artifact generation request.
    /// @param _requestId The unique request ID.
    /// @param _conceptId The ID of the concept.
    /// @param _artifactURI The URI of the generated artifact (e.g., IPFS link).
    /// @param _rewardAmount The amount of shards to reward the original requestor.
    function fulfillArtifactGeneration(bytes32 _requestId, uint256 _conceptId, string memory _artifactURI, uint256 _rewardAmount) external onlyOracle {
        require(pendingArtifactRequests[_requestId] == _conceptId, "EnigmaEngine: Invalid request ID or concept ID mismatch.");
        
        address requester = s_requestIdToRequester[_requestId];
        require(requester != address(0), "EnigmaEngine: Original requester not found for this request ID.");

        Concept storage concept = concepts[_conceptId];
        concept.latestArtifactURI = _artifactURI;

        shards.mint(requester, _rewardAmount); // Reward the original requestor
        _updateConduitGlyphReputation(requester, 10); // Boost for successful artifact generation for the requester

        delete pendingArtifactRequests[_requestId]; // Clear the pending request
        delete s_requestIdToRequester[_requestId];  // Clear the requester mapping

        emit ArtifactGenerationFulfilled(_conceptId, _artifactURI);
    }

    /// @notice Retrieves the latest artifact URI for a concept.
    /// @param _conceptId The ID of the concept.
    /// @return The URI of the latest generated artifact.
    function getLatestArtifactURI(uint256 _conceptId) external view returns (string memory) {
        Concept storage concept = concepts[_conceptId];
        require(concept.id != 0, "EnigmaEngine: Concept does not exist.");
        return concept.latestArtifactURI;
    }
}

// --- Helper Contracts ---

// @title EnigmaShards
// @dev ERC20 token used as the utility token within the EnigmaEngine ecosystem.
// Minting and burning are controlled by the EnigmaEngine contract.
contract EnigmaShards is ERC20 {
    constructor() ERC20("Enigma Shards", "ENG") {
        // Mint an initial supply to the deployer for testing/initial distribution.
        _mint(msg.sender, 1_000_000 * 10**decimals()); 
    }

    /// @notice Mints new tokens to a specified address.
    /// @dev This function is intended to be called by the `EnigmaEngine` contract.
    /// The `EnigmaEngine` acts as the authorized minter.
    function mint(address to, uint256 amount) public virtual {
        // `msg.sender` inside this function will be the `EnigmaEngine` contract
        // when `EnigmaEngine` calls `shards.mint()`.
        // Add specific checks if needed, e.g., `require(msg.sender == address(enigmaEngineContract), "...");`
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address.
    /// @dev This function is intended to be called by the `EnigmaEngine` contract
    /// to facilitate burning for features, or by the token holder themselves.
    function burn(address from, uint256 amount) public virtual {
        // `msg.sender` will be `EnigmaEngine` when it calls `shards.burn()`.
        // If a user is burning their own tokens directly, they'd call `ERC20.burn(amount)`.
        // This `burn` variant is for the `EnigmaEngine` to act on behalf of the user after checks.
        _burn(from, amount);
    }
}

// @title ConduitGlyphs
// @dev An ERC721-compliant contract for Soulbound Tokens (SBTs) used in EnigmaEngine.
// These NFTs are non-transferable and their metadata URIs are dynamically set by the EnigmaEngine.
contract ConduitGlyphs is ERC721 {
    address private enigmaEngineAddress; // Store the address of the main EnigmaEngine contract

    // Internal mapping to store custom token URIs, allowing dynamic updates.
    mapping(uint256 => string) private _tokenURIs;

    constructor(address _enigmaEngineAddress) ERC721("Conduit Glyph", "CG") {
        enigmaEngineAddress = _enigmaEngineAddress;
    }

    /// @notice Restricts transfers, making the tokens soulbound.
    /// @dev Only allows minting (from address(0)) or burning (to address(0)).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(from == address(0) || to == address(0), "ConduitGlyphs: Soulbound tokens cannot be transferred.");
    }

    /// @notice Allows the EnigmaEngine to set the token URI for a specific Glyph.
    /// @dev This function is critical for the dynamic metadata aspect of Conduit Glyphs.
    /// @param tokenId The ID of the Glyph to update.
    /// @param uri The new metadata URI.
    function setTokenURI(uint256 tokenId, string memory uri) external {
        require(msg.sender == enigmaEngineAddress, "ConduitGlyphs: Only EnigmaEngine can set token URI.");
        require(_exists(tokenId), "ConduitGlyphs: Token does not exist.");
        _tokenURIs[tokenId] = uri;
    }

    /// @notice Overrides the default ERC721 `tokenURI` function to provide the custom, dynamically set URI.
    /// @param tokenId The ID of the Glyph.
    /// @return The metadata URI for the given Glyph.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ConduitGlyphs: Token does not exist.");
        string memory _tokenURI = _tokenURIs[tokenId];
        // If for some reason the URI hasn't been set by the engine, return an empty string
        // or a default URI. For this design, the engine is expected to always set it.
        return _tokenURI;
    }

    /// @notice Internal mint function for use by the EnigmaEngine.
    /// @dev This allows `EnigmaEngine` to mint new Glyphs, circumventing the `_beforeTokenTransfer` check for `from != address(0)`.
    /// @param to The address to mint the Glyph to.
    /// @param tokenId The ID of the new Glyph.
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
    }
}
```