```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Contract Name: AetherForge
// Description: A Decentralized Adaptive Learning & Reputation System (DALRS)
//              AetherForge introduces Soulbound NFTs (ASBNFTs) that dynamically
//              evolve their traits based on a combination of on-chain contributions,
//              peer reviews, and sophisticated off-chain AI-driven assessments
//              verified by a trusted oracle. This system aims to provide a robust,
//              non-transferable reputation for individuals in various decentralized
//              ecosystems, enabling trait-gated access to features,
//              and advanced delegation of influence.

// Outline:
// I. Core ASBNFT Management (Soulbound & Dynamic Traits)
// II. AI Oracle Integration & Trait Evolution
// III. Contribution & Peer Review System
// IV. Reputation-Gated Access & Delegation
// V. System Configuration & Maintenance

// Function Summary:
// I. Core ASBNFT Management:
//    1. constructor(): Initializes the contract, sets up roles (ADMIN, AI_ORACLE), NFT details, and default traits.
//    2. registerProfile(): Allows a unique address to mint their initial, non-transferable Adaptive Soulbound NFT (ASBNFT).
//    3. getProfileDetails(address _owner): Retrieves an address's ASBNFT ID, metadata URI, and current trait scores.
//    4. updateProfileMetadata(string memory _newURI): Enables an ASBNFT holder to update the off-chain metadata URI associated with their profile.
//    5. _mintASBNFT(address _to, uint256 _initialScore): Internal function for initial ASBNFT minting, setting base scores.
//    6. _burnASBNFT(uint256 _tokenId): Internal/Admin-only. Facilitates the removal of an ASBNFT in extreme cases (e.g., policy violation).
//    7. getTraitScores(uint256 _tokenId): Public view function to fetch the current values of all traits for a specific ASBNFT.

// II. AI Oracle Integration & Trait Evolution:
//    8. setAIAssessmentOracle(address _oracleAddress): Admin function to assign or change the address of the trusted AI assessment oracle.
//    9. receiveAIAssessment(uint256 _tokenId, uint256[] memory _traitUpdates, bytes32 _proof): Oracle-only. Updates ASBNFT traits based on AI model outputs, requiring an off-chain cryptographic proof for integrity.
//    10. requestAIAssessment(uint256 _tokenId, string memory _contextURI): Allows an ASBNFT holder to formally request an AI assessment on a specific contribution or action, providing a URI for analysis.
//    11. decayTraitScores(uint256 _tokenId, uint256[] memory _decayAmounts): Admin/System/Oracle. Applies a configurable decay to ASBNFT trait scores over time, promoting continuous engagement.
//    12. getLatestAIAssessmentRequest(uint256 _tokenId): Retrieves the details of the most recent AI assessment request made for an ASBNFT.

// III. Contribution & Peer Review System:
//    13. proposeContribution(string memory _contributionURI, string memory _category, uint256 _requiredReviewers): Submits a new contribution for community review, specifying its category and the minimum number of reviews needed.
//    14. reviewContribution(uint256 _contributionId, uint256 _reviewerTokenId, uint256[] memory _reviewScores, string memory _reviewURI): An ASBNFT holder (reviewer) submits a peer review for a proposed contribution, including scores for various aspects and a URI to the detailed review.
//    15. getContributionDetails(uint256 _contributionId): Public view function to inspect the status, metadata, and collected reviews for a specific contribution.
//    16. finalizeContributionReview(uint256 _contributionId): Admin/Automated. Processes all submitted reviews, calculates an aggregate score, potentially triggers AI assessment for the contribution, and updates both contributor and reviewer ASBNFTs.
//    17. markContributionAsDisputed(uint256 _contributionId): Enables an ASBNFT holder to flag a contribution's review outcome as disputed, potentially triggering a re-evaluation or arbitration process.

// IV. Reputation-Gated Access & Delegation:
//    18. setAccessRequirements(bytes32 _featureIdentifier, uint256[] memory _minTraitScores): Admin function to define minimum trait score requirements for access to specific on-chain features or roles (identified by a unique hash).
//    19. isEligibleForFeature(uint256 _tokenId, bytes32 _featureIdentifier): Checks if a given ASBNFT meets the defined trait score thresholds for a particular feature or access gate.
//    20. delegateTraitVotingPower(uint256 _tokenId, address _delegatee): Allows an ASBNFT holder to delegate their ASBNFT's effective trait scores (and thus influence) to another address.
//    21. revokeTraitVotingPower(uint256 _tokenId): Revokes any existing trait delegation for a specific ASBNFT.
//    22. getEffectiveTraitScores(address _addr): Returns the aggregated trait scores that an address effectively controls, accounting for both their own ASBNFT and any delegated scores.

// V. System Configuration & Maintenance:
//    23. updateTraitDefinitions(string[] memory _newTraitNames): Admin function to update the display names of the core traits. (Note: The number and order of traits are typically fixed).
//    24. pause(): Admin function to temporarily halt critical contract functionalities during emergencies or upgrades.
//    25. unpause(): Admin function to resume contract operations after a pause.
//    26. transferOwnership(address _newOwner): Standard OpenZeppelin function to transfer the `DEFAULT_ADMIN_ROLE` (contract ownership).

contract AetherForge is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;

    // --- Custom Errors ---
    error AetherForge__NotASBNFTHolder();
    error AetherForge__AlreadyRegistered();
    error AetherForge__InvalidTraitCount();
    error AetherForge__InvalidTraitIndex();
    error AetherForge__TraitScoresOutOfBounds();
    error AetherForge__ContributionNotFound();
    error AetherForge__AlreadyReviewed();
    error AetherForge__InsufficientReviewers();
    error AetherForge__ContributionNotFinalized();
    error AetherForge__ContributionAlreadyFinalized();
    error AetherForge__UnauthorizedOracle();
    error AetherForge__ASBNFTNotFound();
    error AetherForge__NotEligibleForFeature();
    error AetherForge__SelfDelegationNotAllowed();
    error AetherForge__ProfileNotRegistered(address _addr);

    // --- Roles ---
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    bytes32 public constant SYSTEM_ADMIN_ROLE = DEFAULT_ADMIN_ROLE; // Renaming for clarity

    // --- ASBNFT Data ---
    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) private s_addressToTokenId;
    mapping(uint256 => uint256[]) public s_traitScores; // tokenId => [score1, score2, ...]
    mapping(uint256 => string) public s_tokenURIs; // tokenId => metadataURI

    // --- Traits Configuration ---
    string[] public traitNames;
    uint256 public constant TRAIT_COUNT = 4; // Example traits: TechnicalProficiency, CollaborationScore, InnovationImpact, CommunityLeadership
    uint256 public constant MAX_TRAIT_SCORE = 1000;
    uint256 public constant MIN_TRAIT_SCORE = 0;

    // --- AI Assessment Requests ---
    struct AIAssessmentRequest {
        uint256 tokenId;
        string contextURI;
        uint256 timestamp;
        bool fulfilled;
    }
    Counters.Counter private _aiRequestCounter;
    mapping(uint256 => AIAssessmentRequest) public aiAssessmentRequests; // requestId => AIAssessmentRequest
    mapping(uint256 => uint256) public latestAiRequestByTokenId; // tokenId => latest requestId

    // --- Contribution & Review System ---
    enum ContributionStatus { Proposed, InReview, Finalized, Disputed }
    struct Contribution {
        uint256 id;
        uint256 contributorTokenId;
        string contributionURI;
        string category;
        uint256 requiredReviewers;
        uint256 submissionTimestamp;
        ContributionStatus status;
        uint256[] avgReviewScores; // Average scores after finalization
        mapping(uint256 => Review) reviews; // reviewerTokenId => Review
        uint256 reviewCount;
        uint256[] reviewScoresSum; // Sum of all review scores for averaging
        address[] reviewersDone;
    }
    struct Review {
        uint256 reviewerTokenId;
        uint256[] scores; // Specific scores for this review
        string reviewURI; // Link to off-chain detailed review
        uint256 timestamp;
    }
    Counters.Counter private _contributionCounter;
    mapping(uint256 => Contribution) public contributions;

    // --- Trait-Gated Access Control ---
    // featureIdentifier (bytes32 hash of feature name/description) => minTraitScores
    mapping(bytes32 => uint256[]) public s_featureAccessRequirements;

    // --- Delegation of Trait Power ---
    mapping(uint256 => address) public s_delegates; // tokenId => delegateeAddress
    mapping(address => uint256) public s_delegatedFrom; // delegateeAddress => tokenId being delegated from (simplified: only one delegation per delegatee)

    // --- Events ---
    event ASBNFTRegistered(address indexed owner, uint256 indexed tokenId);
    event ProfileMetadataUpdated(uint256 indexed tokenId, string newURI);
    event AIAssessmentOracleSet(address indexed oracleAddress);
    event AIAssessmentRequested(uint256 indexed tokenId, uint256 indexed requestId, string contextURI);
    event AIAssessmentReceived(uint256 indexed tokenId, uint256 indexed requestId, uint256[] traitUpdates);
    event TraitScoresDecayed(uint256 indexed tokenId, uint256[] decayAmounts);
    event ContributionProposed(uint256 indexed contributionId, uint256 indexed contributorTokenId, string category);
    event ContributionReviewed(uint256 indexed contributionId, uint256 indexed reviewerTokenId);
    event ContributionFinalized(uint256 indexed contributionId, uint256[] finalAvgScores);
    event ContributionDisputed(uint256 indexed contributionId);
    event AccessRequirementsSet(bytes32 indexed featureIdentifier, uint256[] minTraitScores);
    event TraitPowerDelegated(uint256 indexed tokenId, address indexed delegatee);
    event TraitPowerRevoked(uint256 indexed tokenId, address indexed previousDelegatee);
    event TraitDefinitionsUpdated(string[] newTraitNames);

    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _aiOracle
    ) ERC721(_name, _symbol) {
        _grantRole(SYSTEM_ADMIN_ROLE, _admin);
        _grantRole(AI_ORACLE_ROLE, _aiOracle);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin); // OpenZeppelin's default admin role

        // Initialize trait names
        traitNames = new string[](TRAIT_COUNT);
        traitNames[0] = "TechnicalProficiency";
        traitNames[1] = "CollaborationScore";
        traitNames[2] = "InnovationImpact";
        traitNames[3] = "CommunityLeadership";
    }

    // --- I. Core ASBNFT Management ---

    /**
     * @notice Prevents transfer of ASBNFTs, making them soulbound.
     * @dev This internal function is overridden from ERC721.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(from == address(0) || to == address(0), "AetherForge: ASBNFTs are soulbound and cannot be transferred");
    }

    /**
     * @notice Registers a new profile by minting an initial ASBNFT for the caller.
     * @dev Only callable once per address. Sets initial trait scores to 100.
     */
    function registerProfile() external whenNotPaused {
        require(s_addressToTokenId[msg.sender] == 0, "AetherForge: You already have an ASBNFT.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        s_addressToTokenId[msg.sender] = newTokenId;

        // Set initial trait scores (e.g., 100 out of MAX_TRAIT_SCORE)
        uint256[] memory initialScores = new uint256[](TRAIT_COUNT);
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            initialScores[i] = 100;
        }
        _mintASBNFT(msg.sender, newTokenId, initialScores);

        emit ASBNFTRegistered(msg.sender, newTokenId);
    }

    /**
     * @notice Retrieves basic ASBNFT information and current trait scores for a given address.
     * @param _owner The address to query.
     * @return tokenId The ASBNFT ID.
     * @return tokenURI The metadata URI.
     * @return scores The current trait scores.
     */
    function getProfileDetails(address _owner) external view returns (uint256 tokenId, string memory tokenURI, uint256[] memory scores) {
        tokenId = s_addressToTokenId[_owner];
        if (tokenId == 0) {
            revert AetherForge__ProfileNotRegistered(_owner);
        }
        tokenURI = s_tokenURIs[tokenId];
        scores = s_traitScores[tokenId];
    }

    /**
     * @notice Allows an ASBNFT holder to update their associated off-chain metadata URI.
     * @param _newURI The new URI for the ASBNFT metadata.
     */
    function updateProfileMetadata(string memory _newURI) external whenNotPaused {
        uint256 tokenId = s_addressToTokenId[msg.sender];
        if (tokenId == 0) {
            revert AetherForge__NotASBNFTHolder();
        }
        s_tokenURIs[tokenId] = _newURI;
        emit ProfileMetadataUpdated(tokenId, _newURI);
    }

    /**
     * @notice Internal function to mint a new ASBNFT.
     * @dev Handles the actual ERC-721 minting and initializes trait scores.
     * @param _to The recipient address.
     * @param _tokenId The ID of the token to mint.
     * @param _initialScores The initial trait scores for the new ASBNFT.
     */
    function _mintASBNFT(address _to, uint256 _tokenId, uint256[] memory _initialScores) internal {
        if (_initialScores.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount();
        }
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            if (_initialScores[i] > MAX_TRAIT_SCORE) {
                revert AetherForge__TraitScoresOutOfBounds();
            }
        }
        _safeMint(_to, _tokenId);
        s_traitScores[_tokenId] = _initialScores;
        s_tokenURIs[_tokenId] = string(abi.encodePacked("ipfs://default_aetherforge_metadata/", Strings.toString(_tokenId)));
    }

    /**
     * @notice Internal function to burn an ASBNFT.
     * @dev Can be used for disciplinary actions or profile reset (if allowed).
     * @param _tokenId The ID of the token to burn.
     */
    function _burnASBNFT(uint256 _tokenId) internal {
        require(_exists(_tokenId), "ERC721: token not minted");
        address owner = ownerOf(_tokenId);
        _burn(_tokenId);
        delete s_addressToTokenId[owner];
        delete s_traitScores[_tokenId];
        delete s_tokenURIs[_tokenId];
        delete s_delegates[_tokenId]; // Clear delegation if it existed
        delete s_delegatedFrom[owner]; // Clear any incoming delegation if owner was a delegatee
    }

    /**
     * @notice Retrieves the current trait scores for a specific ASBNFT.
     * @param _tokenId The ID of the ASBNFT.
     * @return The array of trait scores.
     */
    function getTraitScores(uint256 _tokenId) public view returns (uint256[] memory) {
        if (!_exists(_tokenId)) {
            revert AetherForge__ASBNFTNotFound();
        }
        return s_traitScores[_tokenId];
    }

    // --- II. AI Oracle Integration & Trait Evolution ---

    /**
     * @notice Sets or updates the address of the trusted AI assessment oracle.
     * @dev Only callable by an account with the SYSTEM_ADMIN_ROLE.
     * @param _oracleAddress The new address for the AI oracle.
     */
    function setAIAssessmentOracle(address _oracleAddress) external onlyRole(SYSTEM_ADMIN_ROLE) {
        require(_oracleAddress != address(0), "AetherForge: Oracle address cannot be zero.");
        _grantRole(AI_ORACLE_ROLE, _oracleAddress);
        emit AIAssessmentOracleSet(_oracleAddress);
    }

    /**
     * @notice Oracle-only function to update ASBNFT traits based on AI analysis.
     * @dev Requires an off-chain proof (e.g., signature, ZK proof hash) to ensure data integrity.
     * @param _tokenId The ID of the ASBNFT to update.
     * @param _traitUpdates An array of new trait scores. Must match TRAIT_COUNT.
     * @param _proof Cryptographic proof from the oracle (e.g., signature hash, ZK proof hash).
     */
    function receiveAIAssessment(uint256 _tokenId, uint256[] memory _traitUpdates, bytes32 _proof) external onlyRole(AI_ORACLE_ROLE) whenNotPaused {
        // In a real system, _proof would be verified against a known oracle signature or ZK verification key.
        // For this example, its presence signifies the intent of verifiable off-chain computation.
        require(_proof != bytes32(0), "AetherForge: Proof is required for AI assessment."); // Basic check
        if (!_exists(_tokenId)) {
            revert AetherForge__ASBNFTNotFound();
        }
        if (_traitUpdates.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount();
        }

        // Update traits
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            s_traitScores[_tokenId][i] = _traitUpdates[i] > MAX_TRAIT_SCORE ? MAX_TRAIT_SCORE : _traitUpdates[i];
            s_traitScores[_tokenId][i] = s_traitScores[_tokenId][i] < MIN_TRAIT_SCORE ? MIN_TRAIT_SCORE : s_traitScores[_tokenId][i];
        }

        uint256 reqId = latestAiRequestByTokenId[_tokenId];
        if (reqId != 0 && aiAssessmentRequests[reqId].tokenId == _tokenId) { // Check if request belongs to this token
            aiAssessmentRequests[reqId].fulfilled = true;
        }

        emit AIAssessmentReceived(_tokenId, reqId, _traitUpdates);
    }

    /**
     * @notice Allows an ASBNFT holder to request an AI assessment for their profile or a specific contribution.
     * @dev The oracle is expected to pick up this request and call `receiveAIAssessment`.
     * @param _tokenId The ID of the ASBNFT requesting the assessment.
     * @param _contextURI A URI pointing to the data to be assessed (e.g., code repository, research paper, activity log).
     */
    function requestAIAssessment(uint256 _tokenId, string memory _contextURI) external whenNotPaused {
        require(s_addressToTokenId[msg.sender] == _tokenId, "AetherForge: Can only request for your own ASBNFT.");
        if (!_exists(_tokenId)) {
            revert AetherForge__ASBNFTNotFound();
        }

        _aiRequestCounter.increment();
        uint256 requestId = _aiRequestCounter.current();
        aiAssessmentRequests[requestId] = AIAssessmentRequest({
            tokenId: _tokenId,
            contextURI: _contextURI,
            timestamp: block.timestamp,
            fulfilled: false
        });
        latestAiRequestByTokenId[_tokenId] = requestId; // Track the latest request for this token

        emit AIAssessmentRequested(_tokenId, requestId, _contextURI);
    }

    /**
     * @notice Applies a decay to trait scores to encourage continuous engagement.
     * @dev Callable by SYSTEM_ADMIN_ROLE or AI_ORACLE_ROLE. Designed to be called periodically (e.g., by a keeper bot).
     * @param _tokenId The ID of the ASBNFT to decay.
     * @param _decayAmounts An array specifying the amount to decay each trait.
     */
    function decayTraitScores(uint256 _tokenId, uint256[] memory _decayAmounts) external onlyRole(SYSTEM_ADMIN_ROLE) whenNotPaused {
        if (!_exists(_tokenId)) {
            revert AetherForge__ASBNFTNotFound();
        }
        if (_decayAmounts.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount();
        }

        uint256[] storage currentScores = s_traitScores[_tokenId];
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            if (currentScores[i] > _decayAmounts[i]) {
                currentScores[i] -= _decayAmounts[i];
            } else {
                currentScores[i] = MIN_TRAIT_SCORE;
            }
        }
        emit TraitScoresDecayed(_tokenId, _decayAmounts);
    }

    /**
     * @notice Retrieves the details of the last AI assessment request made for an ASBNFT.
     * @param _tokenId The ID of the ASBNFT.
     * @return request AIAssessmentRequest struct containing request details.
     */
    function getLatestAIAssessmentRequest(uint256 _tokenId) external view returns (AIAssessmentRequest memory) {
        uint256 requestId = latestAiRequestByTokenId[_tokenId];
        if (requestId == 0) {
            revert AetherForge__ASBNFTNotFound(); // No request found for this token
        }
        return aiAssessmentRequests[requestId];
    }

    // --- III. Contribution & Peer Review System ---

    /**
     * @notice Proposes a new contribution for community review.
     * @dev Any ASBNFT holder can propose.
     * @param _contributionURI A URI pointing to the contribution content (e.g., IPFS hash of a document).
     * @param _category The category of the contribution (e.g., "Code", "Research", "Documentation").
     * @param _requiredReviewers The minimum number of reviewers needed before finalization.
     * @return contributionId The ID of the newly created contribution.
     */
    function proposeContribution(string memory _contributionURI, string memory _category, uint256 _requiredReviewers) external whenNotPaused returns (uint256 contributionId) {
        uint256 contributorTokenId = s_addressToTokenId[msg.sender];
        if (contributorTokenId == 0) {
            revert AetherForge__NotASBNFTHolder();
        }
        require(_requiredReviewers > 0, "AetherForge: At least one reviewer is required.");

        _contributionCounter.increment();
        contributionId = _contributionCounter.current();

        contributions[contributionId].id = contributionId;
        contributions[contributionId].contributorTokenId = contributorTokenId;
        contributions[contributionId].contributionURI = _contributionURI;
        contributions[contributionId].category = _category;
        contributions[contributionId].requiredReviewers = _requiredReviewers;
        contributions[contributionId].submissionTimestamp = block.timestamp;
        contributions[contributionId].status = ContributionStatus.Proposed;
        contributions[contributionId].reviewScoresSum = new uint256[](TRAIT_COUNT); // Initialize sums for averaging

        emit ContributionProposed(contributionId, contributorTokenId, _category);
        return contributionId;
    }

    /**
     * @notice Submits a peer review for a proposed contribution.
     * @dev Any ASBNFT holder can review a contribution (except the contributor).
     * @param _contributionId The ID of the contribution being reviewed.
     * @param _reviewerTokenId The ASBNFT ID of the reviewer.
     * @param _reviewScores An array of scores (e.g., 1-100) for different aspects of the contribution.
     * @param _reviewURI A URI pointing to the detailed off-chain review document.
     */
    function reviewContribution(uint256 _contributionId, uint256 _reviewerTokenId, uint256[] memory _reviewScores, string memory _reviewURI) external whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0) {
            revert AetherForge__ContributionNotFound();
        }
        if (s_addressToTokenId[msg.sender] == 0 || s_addressToTokenId[msg.sender] != _reviewerTokenId) {
            revert AetherForge__NotASBNFTHolder();
        }
        if (contribution.contributorTokenId == _reviewerTokenId) {
            revert AetherForge: Cannot review your own contribution.";
        }
        if (contribution.reviews[_reviewerTokenId].reviewerTokenId != 0) {
            revert AetherForge__AlreadyReviewed();
        }
        if (contribution.status != ContributionStatus.Proposed && contribution.status != ContributionStatus.InReview) {
            revert AetherForge__ContributionAlreadyFinalized();
        }
        if (_reviewScores.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount(); // Assuming reviews correspond to traits
        }

        contribution.reviews[_reviewerTokenId] = Review({
            reviewerTokenId: _reviewerTokenId,
            scores: _reviewScores,
            reviewURI: _reviewURI,
            timestamp: block.timestamp
        });
        contribution.reviewCount++;
        contribution.reviewersDone.push(msg.sender);

        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            contribution.reviewScoresSum[i] += _reviewScores[i];
        }

        if (contribution.reviewCount >= contribution.requiredReviewers) {
            contribution.status = ContributionStatus.InReview; // Ready for finalization
        }

        emit ContributionReviewed(_contributionId, _reviewerTokenId);
    }

    /**
     * @notice Retrieves details of a specific contribution, including its status and collected reviews.
     * @param _contributionId The ID of the contribution.
     * @return contribution struct containing all details.
     */
    function getContributionDetails(uint256 _contributionId) external view returns (Contribution memory) {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0) {
            revert AetherForge__ContributionNotFound();
        }
        // Return a copy to avoid stack too deep for mapping inside struct
        Contribution memory _contribution = contribution;
        _contribution.reviews = null; // Clear mapping to allow return via memory
        return _contribution;
    }

    /**
     * @notice Finalizes the review process for a contribution, calculating average scores and updating ASBNFTs.
     * @dev Callable by SYSTEM_ADMIN_ROLE or an automated process. Requires `requiredReviewers` to be met.
     * @param _contributionId The ID of the contribution to finalize.
     */
    function finalizeContributionReview(uint256 _contributionId) external onlyRole(SYSTEM_ADMIN_ROLE) whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0) {
            revert AetherForge__ContributionNotFound();
        }
        if (contribution.status == ContributionStatus.Finalized) {
            revert AetherForge__ContributionAlreadyFinalized();
        }
        if (contribution.reviewCount < contribution.requiredReviewers) {
            revert AetherForge__InsufficientReviewers();
        }

        uint256[] memory finalAvgScores = new uint256[](TRAIT_COUNT);
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            finalAvgScores[i] = contribution.reviewScoresSum[i] / contribution.reviewCount;
        }
        contribution.avgReviewScores = finalAvgScores;
        contribution.status = ContributionStatus.Finalized;

        // --- Update Contributor's ASBNFT ---
        // This is a simplified example. In a real system, AI might analyze the final review scores
        // and context URI, then provide a more nuanced update. For now, we'll directly update.
        // Or, we could trigger an AI assessment request for the contributor here.
        // For direct update, let's add an internal update function for admin/system.
        _updateTraitScoresDirectly(contribution.contributorTokenId, finalAvgScores, true); // true to add scores

        // --- Update Reviewers' ASBNFTs (e.g., for collaboration score) ---
        // Reviewers also get a small boost for their participation and quality of review.
        uint256[] memory reviewerBoost = new uint256[](TRAIT_COUNT);
        reviewerBoost[1] = 10; // Small boost to CollaborationScore for participating in review
        for (uint256 i = 0; i < contribution.reviewersDone.length; i++) {
            uint256 reviewerTokenId = s_addressToTokenId[contribution.reviewersDone[i]];
            if (reviewerTokenId != 0) {
                _updateTraitScoresDirectly(reviewerTokenId, reviewerBoost, true);
            }
        }

        emit ContributionFinalized(_contributionId, finalAvgScores);
    }

    /**
     * @dev Internal helper function to update trait scores, used by system/admin functions.
     * @param _tokenId The ASBNFT ID.
     * @param _scoresToApply The scores to add or subtract.
     * @param _add If true, scores are added; if false, they are subtracted.
     */
    function _updateTraitScoresDirectly(uint256 _tokenId, uint256[] memory _scoresToApply, bool _add) internal {
        if (!_exists(_tokenId)) {
            revert AetherForge__ASBNFTNotFound();
        }
        if (_scoresToApply.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount();
        }

        uint256[] storage currentScores = s_traitScores[_tokenId];
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            if (_add) {
                currentScores[i] = currentScores[i] + _scoresToApply[i] > MAX_TRAIT_SCORE ? MAX_TRAIT_SCORE : currentScores[i] + _scoresToApply[i];
            } else {
                currentScores[i] = currentScores[i] > _scoresToApply[i] ? currentScores[i] - _scoresToApply[i] : MIN_TRAIT_SCORE;
            }
        }
    }


    /**
     * @notice Allows an ASBNFT holder to dispute the outcome or finalization of a contribution review.
     * @dev This marks the contribution as 'Disputed', requiring manual intervention or re-evaluation.
     * @param _contributionId The ID of the contribution to dispute.
     */
    function markContributionAsDisputed(uint256 _contributionId) external whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        if (contribution.id == 0) {
            revert AetherForge__ContributionNotFound();
        }
        if (contribution.contributorTokenId != s_addressToTokenId[msg.sender]) {
            revert AetherForge__NotASBNFTHolder(); // Only the contributor can dispute
        }
        if (contribution.status == ContributionStatus.Disputed) {
            return; // Already disputed
        }
        contribution.status = ContributionStatus.Disputed;
        emit ContributionDisputed(_contributionId);
    }

    // --- IV. Reputation-Gated Access & Delegation ---

    /**
     * @notice Sets the minimum trait scores required for a specific on-chain feature or access gate.
     * @dev Callable by SYSTEM_ADMIN_ROLE.
     * @param _featureIdentifier A unique bytes32 hash identifying the feature (e.g., keccak256("PremiumAccess")).
     * @param _minTraitScores An array of minimum scores required for each trait.
     */
    function setAccessRequirements(bytes32 _featureIdentifier, uint256[] memory _minTraitScores) external onlyRole(SYSTEM_ADMIN_ROLE) {
        if (_minTraitScores.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount();
        }
        s_featureAccessRequirements[_featureIdentifier] = _minTraitScores;
        emit AccessRequirementsSet(_featureIdentifier, _minTraitScores);
    }

    /**
     * @notice Checks if an ASBNFT holder meets the trait requirements for a given feature.
     * @param _tokenId The ID of the ASBNFT to check.
     * @param _featureIdentifier The bytes32 hash identifying the feature.
     * @return True if the ASBNFT is eligible, false otherwise.
     */
    function isEligibleForFeature(uint256 _tokenId, bytes32 _featureIdentifier) public view returns (bool) {
        if (!_exists(_tokenId)) {
            revert AetherForge__ASBNFTNotFound();
        }
        uint256[] memory requiredScores = s_featureAccessRequirements[_featureIdentifier];
        if (requiredScores.length == 0) { // No requirements set for this feature
            return true;
        }
        uint256[] memory currentScores = s_traitScores[_tokenId];
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            if (currentScores[i] < requiredScores[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Allows an ASBNFT holder to delegate their effective trait scores to another address.
     * @dev This allows others to act on their behalf with their accumulated reputation.
     * @param _tokenId The ID of the ASBNFT delegating power.
     * @param _delegatee The address to delegate power to.
     */
    function delegateTraitVotingPower(uint256 _tokenId, address _delegatee) external whenNotPaused {
        require(s_addressToTokenId[msg.sender] == _tokenId, "AetherForge: Can only delegate your own ASBNFT's power.");
        require(_delegatee != address(0), "AetherForge: Delegatee cannot be zero address.");
        if (ownerOf(_tokenId) == _delegatee) {
             revert AetherForge__SelfDelegationNotAllowed();
        }
        // Ensure the delegatee isn't already delegated power by someone else (simplified for this example)
        require(s_delegatedFrom[_delegatee] == 0, "AetherForge: Delegatee already has power delegated to them.");

        address currentDelegatee = s_delegates[_tokenId];
        if (currentDelegatee != address(0)) {
            delete s_delegatedFrom[currentDelegatee]; // Clear previous delegation
        }

        s_delegates[_tokenId] = _delegatee;
        s_delegatedFrom[_delegatee] = _tokenId;
        emit TraitPowerDelegated(_tokenId, _delegatee);
    }

    /**
     * @notice Revokes any existing trait delegation for a specific ASBNFT.
     * @param _tokenId The ID of the ASBNFT to revoke delegation from.
     */
    function revokeTraitVotingPower(uint256 _tokenId) external whenNotPaused {
        require(s_addressToTokenId[msg.sender] == _tokenId, "AetherForge: Can only revoke your own ASBNFT's delegation.");
        address currentDelegatee = s_delegates[_tokenId];
        require(currentDelegatee != address(0), "AetherForge: No active delegation to revoke.");

        delete s_delegates[_tokenId];
        delete s_delegatedFrom[currentDelegatee];
        emit TraitPowerRevoked(_tokenId, currentDelegatee);
    }

    /**
     * @notice Returns the aggregated trait scores that an address effectively controls (either their own ASBNFT's, or delegated).
     * @param _addr The address to query for effective trait scores.
     * @return The array of effective trait scores.
     */
    function getEffectiveTraitScores(address _addr) public view returns (uint256[] memory) {
        uint256 tokenId = s_addressToTokenId[_addr];
        if (tokenId != 0) {
            // Own ASBNFT
            return s_traitScores[tokenId];
        } else {
            // Check if this address is a delegatee
            uint256 delegatedFromTokenId = s_delegatedFrom[_addr];
            if (delegatedFromTokenId != 0) {
                return s_traitScores[delegatedFromTokenId];
            }
        }
        revert AetherForge__ProfileNotRegistered(_addr);
    }

    // --- V. System Configuration & Maintenance ---

    /**
     * @notice Updates the display names of the core traits.
     * @dev Callable by SYSTEM_ADMIN_ROLE. The number and order of traits are fixed (TRAIT_COUNT).
     * @param _newTraitNames An array of new names for the traits. Must match TRAIT_COUNT.
     */
    function updateTraitDefinitions(string[] memory _newTraitNames) external onlyRole(SYSTEM_ADMIN_ROLE) {
        if (_newTraitNames.length != TRAIT_COUNT) {
            revert AetherForge__InvalidTraitCount();
        }
        for (uint256 i = 0; i < TRAIT_COUNT; i++) {
            traitNames[i] = _newTraitNames[i];
        }
        emit TraitDefinitionsUpdated(_newTraitNames);
    }

    /**
     * @notice Pauses critical contract functionalities.
     * @dev Callable by SYSTEM_ADMIN_ROLE. Inherited from Pausable.
     */
    function pause() public onlyRole(SYSTEM_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses critical contract functionalities.
     * @dev Callable by SYSTEM_ADMIN_ROLE. Inherited from Pausable.
     */
    function unpause() public onlyRole(SYSTEM_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Transfers the `DEFAULT_ADMIN_ROLE` (contract ownership).
     * @dev This effectively transfers the primary administrative control of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOwner != address(0), "AetherForge: New owner cannot be zero address.");
        _transferRole(DEFAULT_ADMIN_ROLE, msg.sender, _newOwner);
    }

    // The following functions are required by ERC721 but effectively disabled due to _beforeTokenTransfer override
    function approve(address to, uint256 tokenId) public pure override {
        revert("AetherForge: ASBNFTs cannot be approved for transfer.");
    }
    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("AetherForge: ASBNFTs cannot be approved for transfer.");
    }
}
```