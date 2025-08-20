Here's a Solidity smart contract named `AetherForge` that incorporates several advanced concepts: AI Oracle integration for content evaluation, a dynamic and soulbound NFT reputation system, and gamified content curation mechanics. It's designed to be creative, trendy, and avoid direct duplication of existing large open-source projects by combining these concepts in a novel application.

The contract focuses on a decentralized content creation and curation platform where:
*   Users submit content "fragments" (references to off-chain data).
*   An *off-chain* AI model (via a trusted oracle) provides an initial quality score.
*   The community then curates and validates the AI's assessment.
*   Users earn non-transferable "Node Points" based on their contributions and curation accuracy.
*   These points determine a user's "Node Tier," unlocking dynamic "AetherMind" NFTs whose metadata evolves with the user's reputation.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary:
// Contract: AetherForge
// Core Concept: AetherForge is a decentralized creative content curation and reputation system.
// It leverages an off-chain AI oracle for initial content evaluation, which is then refined and
// validated by community curation. Users earn non-transferable "Node Points" based on their
// contributions and curation accuracy, advancing through "Node Tiers." These tiers unlock
// dynamic, Soulbound NFTs called "AetherMinds" that visually represent a user's on-chain
// creative journey and influence. The system aims to foster high-quality content generation
// and discerning community engagement through gamified reputation mechanics and AI integration.

// Modules & Functions:

// I. Core Infrastructure & Configuration (Ownable, Oracle Management)
//    - constructor(): Initializes the contract with an admin and default Node Tier thresholds.
//    - registerAIOracle(address _oracleAddress): Grants an address permission to submit AI evaluations.
//    - revokeAIOracle(address _oracleAddress): Revokes AI oracle permission.
//    - isAIOracle(address _address): Checks if an address is a registered AI oracle.
//    - setNodeTierThreshold(uint256 _tier, uint256 _newThreshold): Sets Node Point requirements for a specific tier.
//    - setEvaluationWeights(uint256 _aiWeight, uint256 _communityWeight): Defines influence of AI vs. community in Node Point calculation (conceptually, not directly used in NP here).

// II. Content Submission & Management (AetherFragments)
//    - submitAetherFragment(string calldata _contentURI, string calldata _category): Allows users to submit a URI referencing off-chain content.
//    - getAetherFragment(uint256 _fragmentId): Retrieves details of a submitted content fragment.
//    - updateFragmentURI(uint256 _fragmentId, string calldata _newURI): Allows the creator to update their content's URI within a limited time window and before AI evaluation.
//    - archiveFragment(uint256 _fragmentId): Marks a fragment as archived by its creator or contract owner.

// III. AI Evaluation & Integration
//    - submitAIEvaluation(uint256 _fragmentId, uint256 _aiScore, string calldata _evaluationHash): Only callable by registered AI oracles to post an AI-generated score for a fragment.
//    - getAIEvaluation(uint256 _fragmentId): Retrieves the AI score and hash for a given fragment.
//    - getAverageAIScore(): Returns the average AI score across all evaluated fragments.

// IV. Community Curation & Validation
//    - voteOnAIEvaluation(uint256 _fragmentId, bool _agreesWithAI): Users vote to agree or disagree with the AI's assessment of a fragment.
//    - submitQualitativeReviewHash(uint256 _fragmentId, string calldata _reviewHash): Allows users to submit a hash of an off-chain qualitative review.
//    - getVoteCounts(uint256 _fragmentId): Returns the number of 'agree' and 'disagree' votes for a fragment's AI evaluation.
//    - getReviewHashesCount(uint256 _fragmentId): Returns the count of qualitative review hashes submitted for a fragment.

// V. Reputation & Node Tier System (AetherNode)
//    - calculateNodePoints(address _user): Calculates and returns the total Node Points for a user based on their activities.
//    - getNodeTier(address _user): Returns the current Node Tier of a user based on their Node Points.
//    - getTierUnlockThreshold(uint256 _tier): Retrieves the Node Point threshold required to reach a specific tier.
//    - getNodePointsForFragment(uint256 _fragmentId): Returns the Node Points that were awarded to the creator for a specific fragment.
//    - getNodePointsForCuration(address _user): Returns Node Points earned specifically from curation activities for a user.

// VI. Dynamic Soulbound NFT (AetherMind)
//    - mintAetherMindNFT(): Allows a user to mint their unique, non-transferable AetherMind NFT once they reach a qualifying Node Tier (e.g., Tier 1).
//    - tokenURI(uint256 _tokenId): Standard ERC721 function to retrieve the metadata URI for an AetherMind NFT. The metadata will dynamically reflect the owner's Node Tier (via off-chain resolver).
//    - getAetherMindOwner(uint256 _tokenId): Standard ERC721 function to get the owner of a given AetherMind NFT.
//    - getAetherMindTokenId(address _owner): Retrieves the tokenId of the AetherMind NFT owned by a specific address.

contract AetherForge is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // I. Core Infrastructure & Configuration
    mapping(address => bool) private _aiOracles;
    mapping(uint256 => uint256) public nodeTierThresholds; // Tier => Node Points needed
    uint256 public aiEvaluationWeight = 60; // Percentage weight for AI score in Node Point calculation (conceptual parameter)
    uint256 public communityEvaluationWeight = 40; // Percentage weight for community consensus (conceptual parameter)

    // II. Content Submission & Management (AetherFragments)
    struct AetherFragment {
        address creator;
        string contentURI;
        string category;
        uint256 submittedTimestamp;
        bool isArchived;
        // AI Evaluation
        uint256 aiScore; // 0-100 scale
        string aiEvaluationHash;
        bool aiEvaluated;
        // Community Curation
        uint256 agreeVotes;
        uint256 disagreeVotes;
        uint256 reviewHashesCount;
        uint256 creatorPointsEarnedFromFragment; // Points gained by creator for THIS specific fragment
    }
    Counters.Counter private _fragmentIds;
    mapping(uint256 => AetherFragment) public aetherFragments;
    mapping(uint256 => mapping(address => bool)) private _userVotedOnFragmentAI; // Track if a user voted on AI evaluation
    mapping(uint256 => mapping(address => bool)) private _userSubmittedReviewHash; // Track if a user submitted a review hash

    // III. AI Evaluation Tracking
    uint256 private _totalAIEvaluatedScores;
    uint256 private _totalEvaluatedFragments;

    // V. Reputation & Node Tier System (AetherNode)
    mapping(address => uint256) public userFragmentNodePoints; // Points from content creation (sum of creatorPointsEarnedFromFragment across all user's fragments)
    mapping(address => uint256) public userCurationNodePoints; // Points from curation activities

    // VI. Dynamic Soulbound NFT (AetherMind)
    Counters.Counter private _aetherMindTokenIds;
    mapping(address => uint256) private _userAetherMindTokenId; // Stores the tokenId for a user's AetherMind NFT
    string private _baseAetherMindURI = "https://aetherforge.xyz/api/mind/"; // Base URI for dynamic metadata resolver

    // --- Events ---
    event AetherFragmentSubmitted(uint256 indexed fragmentId, address indexed creator, string contentURI, string category);
    event AIEvaluationSubmitted(uint256 indexed fragmentId, address indexed oracle, uint256 aiScore, string evaluationHash);
    event CommunityVoteRecorded(uint256 indexed fragmentId, address indexed voter, bool agreesWithAI);
    event QualitativeReviewHashSubmitted(uint256 indexed fragmentId, address indexed submitter, string reviewHash);
    event NodePointsUpdated(address indexed user, uint256 newTotalPoints, uint256 newTier);
    event AetherMindMinted(uint256 indexed tokenId, address indexed owner, uint256 tier);
    event AIOracleRegistered(address indexed oracleAddress);
    event AIOracleRevoked(address indexed oracleAddress);
    event NodeTierThresholdSet(uint256 indexed tier, uint256 newThreshold);
    event EvaluationWeightsSet(uint256 aiWeight, uint256 communityWeight);
    event FragmentURIUpdated(uint256 indexed fragmentId, string newURI);
    event FragmentArchived(uint256 indexed fragmentId);

    // --- Constructor ---
    constructor(address initialOwner) ERC721("AetherMindNFT", "AETHERMIND") Ownable(initialOwner) {
        // Initialize some default tier thresholds
        nodeTierThresholds[0] = 0;    // Tier 0: "Apprentice" (default)
        nodeTierThresholds[1] = 100;  // Tier 1: "Novice"
        nodeTierThresholds[2] = 500;  // Tier 2: "Artisan"
        nodeTierThresholds[3] = 2000; // Tier 3: "Innovator"
        nodeTierThresholds[4] = 5000; // Tier 4: "Master Forger"
        nodeTierThresholds[5] = 10000; // Tier 5: "Aether Weaver"
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(_aiOracles[msg.sender], "AetherForge: Caller is not a registered AI oracle");
        _;
    }

    // --- I. Core Infrastructure & Configuration ---

    /// @notice Registers an address as an authorized AI oracle. Only callable by the contract owner.
    /// @param _oracleAddress The address to register.
    function registerAIOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AetherForge: Invalid address");
        _aiOracles[_oracleAddress] = true;
        emit AIOracleRegistered(_oracleAddress);
    }

    /// @notice Revokes an address's authorization as an AI oracle. Only callable by the contract owner.
    /// @param _oracleAddress The address to revoke.
    function revokeAIOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AetherForge: Invalid address");
        _aiOracles[_oracleAddress] = false;
        emit AIOracleRevoked(_oracleAddress);
    }

    /// @notice Checks if an address is a registered AI oracle.
    /// @param _address The address to check.
    /// @return True if the address is an AI oracle, false otherwise.
    function isAIOracle(address _address) public view returns (bool) {
        return _aiOracles[_address];
    }

    /// @notice Sets the Node Point threshold required to reach a specific tier. Only callable by the contract owner.
    /// @param _tier The tier number (e.g., 1 for Novice).
    /// @param _newThreshold The new Node Point threshold for this tier.
    function setNodeTierThreshold(uint256 _tier, uint256 _newThreshold) public onlyOwner {
        require(_tier >= 0 && _tier <= 5, "AetherForge: Tier out of bounds (0-5)"); // Assuming 0-5 tiers
        if (_tier > 0) {
            // Ensure tiers are progressively harder (thresholds increase)
            require(_newThreshold >= nodeTierThresholds[_tier - 1], "AetherForge: Threshold must be equal to or higher than previous tier");
        }
        nodeTierThresholds[_tier] = _newThreshold;
        emit NodeTierThresholdSet(_tier, _newThreshold);
    }

    /// @notice Sets the percentage weights for AI and community evaluations in Node Point calculation.
    ///         These weights are conceptual parameters that could influence a more complex future NP system.
    /// @param _aiWeight The new weight for AI evaluation (0-100).
    /// @param _communityWeight The new weight for community evaluation (0-100).
    function setEvaluationWeights(uint256 _aiWeight, uint256 _communityWeight) public onlyOwner {
        require(_aiWeight <= 100 && _communityWeight <= 100, "AetherForge: Weights must be between 0 and 100");
        require(_aiWeight + _communityWeight == 100, "AetherForge: Weights must sum to 100%");
        aiEvaluationWeight = _aiWeight;
        communityEvaluationWeight = _communityWeight;
        emit EvaluationWeightsSet(_aiWeight, _communityWeight);
    }

    // --- II. Content Submission & Management (AetherFragments) ---

    /// @notice Allows users to submit a URI referencing off-chain content, initiating the evaluation process.
    /// @param _contentURI The URI pointing to the content (e.g., IPFS hash, URL).
    /// @param _category The category of the content (e.g., "Art", "Code", "Research").
    /// @return The ID of the newly submitted Aether Fragment.
    function submitAetherFragment(string calldata _contentURI, string calldata _category) public returns (uint256) {
        _fragmentIds.increment();
        uint256 newId = _fragmentIds.current();

        AetherFragment storage fragment = aetherFragments[newId];
        fragment.creator = msg.sender;
        fragment.contentURI = _contentURI;
        fragment.category = _category;
        fragment.submittedTimestamp = block.timestamp;
        fragment.isArchived = false;
        fragment.aiEvaluated = false;
        // creatorPointsEarnedFromFragment will be set upon AI evaluation

        emit AetherFragmentSubmitted(newId, msg.sender, _contentURI, _category);
        return newId;
    }

    /// @notice Retrieves details of a submitted content fragment.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @return creator, contentURI, category, submittedTimestamp, isArchived, aiScore, aiEvaluationHash, aiEvaluated, agreeVotes, disagreeVotes, reviewHashesCount, creatorPointsEarnedFromFragment.
    function getAetherFragment(uint256 _fragmentId) public view returns (
        address creator,
        string memory contentURI,
        string memory category,
        uint256 submittedTimestamp,
        bool isArchived,
        uint256 aiScore,
        string memory aiEvaluationHash,
        bool aiEvaluated,
        uint256 agreeVotes,
        uint256 disagreeVotes,
        uint256 reviewHashesCount,
        uint256 creatorPointsEarnedFromFragment
    ) {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");

        return (
            fragment.creator,
            fragment.contentURI,
            fragment.category,
            fragment.submittedTimestamp,
            fragment.isArchived,
            fragment.aiScore,
            fragment.aiEvaluationHash,
            fragment.aiEvaluated,
            fragment.agreeVotes,
            fragment.disagreeVotes,
            fragment.reviewHashesCount,
            fragment.creatorPointsEarnedFromFragment
        );
    }

    /// @notice Allows the creator to update their content's URI within a limited window (e.g., 24 hours)
    ///         and only before an AI evaluation has been submitted.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @param _newURI The new URI for the content.
    function updateFragmentURI(uint256 _fragmentId, string calldata _newURI) public {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        require(fragment.creator == msg.sender, "AetherForge: Only creator can update URI");
        require(block.timestamp < fragment.submittedTimestamp + 1 days, "AetherForge: Update window expired (24 hours)");
        require(!fragment.aiEvaluated, "AetherForge: Cannot update after AI evaluation");

        fragment.contentURI = _newURI;
        emit FragmentURIUpdated(_fragmentId, _newURI);
    }

    /// @notice Marks a fragment as archived. Can be called by the creator or the contract owner.
    /// @param _fragmentId The ID of the Aether Fragment.
    function archiveFragment(uint256 _fragmentId) public {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        require(fragment.creator == msg.sender || owner() == msg.sender, "AetherForge: Not authorized to archive fragment");
        require(!fragment.isArchived, "AetherForge: Fragment already archived");

        fragment.isArchived = true;
        emit FragmentArchived(_fragmentId);
    }

    // --- III. AI Evaluation & Integration ---

    /// @notice Only callable by registered AI oracles to post an AI-generated score for a fragment.
    ///         Upon evaluation, the creator receives Node Points for their submission.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @param _aiScore The AI-generated score (0-100).
    /// @param _evaluationHash A hash referencing off-chain detailed AI evaluation data (e.g., IPFS hash of a JSON report).
    function submitAIEvaluation(uint256 _fragmentId, uint256 _aiScore, string calldata _evaluationHash) public onlyAIOracle {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        require(!fragment.aiEvaluated, "AetherForge: Fragment already AI evaluated");
        require(_aiScore <= 100, "AetherForge: AI score must be <= 100");

        fragment.aiScore = _aiScore;
        fragment.aiEvaluationHash = _evaluationHash;
        fragment.aiEvaluated = true;

        _totalAIEvaluatedScores += _aiScore;
        _totalEvaluatedFragments++;

        // Award Node Points to creator upon AI evaluation
        // Base points + score-based bonus (e.g., 10 base + 1 point per 5 AI score)
        uint256 pointsEarned = 10 + (_aiScore / 5);
        fragment.creatorPointsEarnedFromFragment = pointsEarned;
        userFragmentNodePoints[fragment.creator] += pointsEarned;

        emit NodePointsUpdated(fragment.creator, calculateNodePoints(fragment.creator), getNodeTier(fragment.creator));
        emit AIEvaluationSubmitted(_fragmentId, msg.sender, _aiScore, _evaluationHash);
    }

    /// @notice Retrieves the AI score and hash for a given fragment.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @return aiScore, aiEvaluationHash, aiEvaluated status.
    function getAIEvaluation(uint256 _fragmentId) public view returns (uint256 aiScore, string memory aiEvaluationHash, bool aiEvaluated) {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        return (fragment.aiScore, fragment.aiEvaluationHash, fragment.aiEvaluated);
    }

    /// @notice Returns the average AI score across all evaluated fragments.
    /// @return The average AI score. Returns 0 if no fragments have been evaluated.
    function getAverageAIScore() public view returns (uint256) {
        if (_totalEvaluatedFragments == 0) {
            return 0;
        }
        return _totalAIEvaluatedScores / _totalEvaluatedFragments;
    }

    // --- IV. Community Curation & Validation ---

    /// @notice Users vote to agree or disagree with the AI's assessment of a fragment.
    ///         Users cannot vote on their own fragments.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @param _agreesWithAI True if the user agrees with the AI, false otherwise.
    function voteOnAIEvaluation(uint256 _fragmentId, bool _agreesWithAI) public {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        require(fragment.aiEvaluated, "AetherForge: Fragment not yet AI evaluated");
        require(msg.sender != fragment.creator, "AetherForge: Creator cannot vote on own fragment");
        require(!_userVotedOnFragmentAI[_fragmentId][msg.sender], "AetherForge: Already voted on this fragment's AI evaluation");

        _userVotedOnFragmentAI[_fragmentId][msg.sender] = true;

        if (_agreesWithAI) {
            fragment.agreeVotes++;
        } else {
            fragment.disagreeVotes++;
        }

        // Award a small amount of Node Points for participation in curation.
        // A more advanced system could award more points if their vote aligns with eventual consensus.
        userCurationNodePoints[msg.sender] += 1;
        emit NodePointsUpdated(msg.sender, calculateNodePoints(msg.sender), getNodeTier(msg.sender));
        emit CommunityVoteRecorded(_fragmentId, msg.sender, _agreesWithAI);
    }

    /// @notice Allows users to submit a hash of an off-chain qualitative review.
    ///         Users cannot review their own fragments.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @param _reviewHash A cryptographic hash (e.g., Keccak256) of the off-chain review content.
    function submitQualitativeReviewHash(uint256 _fragmentId, string calldata _reviewHash) public {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        require(msg.sender != fragment.creator, "AetherForge: Creator cannot submit review hash for own fragment");
        require(!_userSubmittedReviewHash[_fragmentId][msg.sender], "AetherForge: Already submitted review hash for this fragment");

        _userSubmittedReviewHash[_fragmentId][msg.sender] = true;
        fragment.reviewHashesCount++;

        // Award more Node Points for detailed review submission.
        userCurationNodePoints[msg.sender] += 2;
        emit NodePointsUpdated(msg.sender, calculateNodePoints(msg.sender), getNodeTier(msg.sender));
        emit QualitativeReviewHashSubmitted(_fragmentId, msg.sender, _reviewHash);
    }

    /// @notice Returns the number of 'agree' and 'disagree' votes for a fragment's AI evaluation.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @return agreeVotes, disagreeVotes.
    function getVoteCounts(uint256 _fragmentId) public view returns (uint256 agreeVotes, uint256 disagreeVotes) {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        return (fragment.agreeVotes, fragment.disagreeVotes);
    }

    /// @notice Returns the count of qualitative review hashes submitted for a fragment.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @return The number of review hashes.
    function getReviewHashesCount(uint256 _fragmentId) public view returns (uint256) {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        return fragment.reviewHashesCount;
    }

    // --- V. Reputation & Node Tier System (AetherNode) ---

    /// @notice Calculates the total Node Points for a user based on their activities (content creation + curation).
    /// @param _user The address of the user.
    /// @return The total Node Points.
    function calculateNodePoints(address _user) public view returns (uint256) {
        return userFragmentNodePoints[_user] + userCurationNodePoints[_user];
    }

    /// @notice Returns the current Node Tier of a user based on their Node Points.
    /// @param _user The address of the user.
    /// @return The current Node Tier.
    function getNodeTier(address _user) public view returns (uint256) {
        uint256 totalPoints = calculateNodePoints(_user);
        uint256 currentTier = 0;
        // Iterate from highest possible tier down to find the highest tier the user qualifies for
        for (uint256 i = 5; i >= 0; i--) {
            if (nodeTierThresholds[i] <= totalPoints) {
                currentTier = i;
                break;
            }
        }
        return currentTier;
    }

    /// @notice Retrieves the Node Point threshold required to reach a specific tier.
    /// @param _tier The tier number.
    /// @return The Node Point threshold.
    function getTierUnlockThreshold(uint256 _tier) public view returns (uint256) {
        require(_tier >= 0 && _tier <= 5, "AetherForge: Tier out of bounds (0-5)"); // Assuming 0-5 tiers
        return nodeTierThresholds[_tier];
    }

    /// @notice Returns the Node Points specifically awarded to the creator for a given fragment.
    /// @param _fragmentId The ID of the Aether Fragment.
    /// @return The Node Points earned by the creator for this specific fragment. Returns 0 if not yet evaluated by AI.
    function getNodePointsForFragment(uint256 _fragmentId) public view returns (uint256) {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.creator != address(0), "AetherForge: Fragment does not exist");
        return fragment.creatorPointsEarnedFromFragment;
    }

    /// @notice Returns Node Points earned specifically from curation activities for a user.
    /// @param _user The address of the user.
    /// @return The Node Points from curation.
    function getNodePointsForCuration(address _user) public view returns (uint256) {
        return userCurationNodePoints[_user];
    }

    // --- VI. Dynamic Soulbound NFT (AetherMind) ---

    /// @notice Allows a user to mint their unique, non-transferable AetherMind NFT once they reach a qualifying Node Tier.
    ///         The NFT's metadata will dynamically reflect the owner's Node Tier and achievements.
    function mintAetherMindNFT() public {
        require(_userAetherMindTokenId[msg.sender] == 0, "AetherForge: You already own an AetherMind NFT");
        require(getNodeTier(msg.sender) >= 1, "AetherForge: Must reach at least Tier 1 to mint AetherMind");

        _aetherMindTokenIds.increment();
        uint256 newItemId = _aetherMindTokenIds.current();
        _mint(msg.sender, newItemId);
        _userAetherMindTokenId[msg.sender] = newItemId;

        emit AetherMindMinted(newItemId, msg.sender, getNodeTier(msg.sender));
    }

    /// @notice Overrides ERC721's _beforeTokenTransfer hook to enforce soulbound property for AetherMind NFTs.
    /// @dev This function prevents any transfers of AetherMind NFTs after they are minted.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfers if the token is already minted (from is not address(0))
        // and it's not a burn (to is not address(0)).
        if (from != address(0) && to != address(0)) {
            // Check if this token is an AetherMind NFT.
            // All AetherMind NFTs are sequentially minted from _aetherMindTokenIds counter.
            // If tokenId is within the range of minted AetherMind tokens, revert.
            if (tokenId > 0 && tokenId <= _aetherMindTokenIds.current()) {
                 revert("AetherForge: AetherMind NFTs are soulbound and cannot be transferred.");
            }
        }
    }

    /// @notice Returns the metadata URI for an AetherMind NFT. The URI is dynamic, pointing to an off-chain service
    ///         that generates metadata based on the owner's current Node Tier.
    /// @param _tokenId The ID of the AetherMind NFT.
    /// @return The URI pointing to the dynamic metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        address ownerAddress = ownerOf(_tokenId);
        uint256 currentTier = getNodeTier(ownerAddress);
        // The off-chain API `_baseAetherMindURI` would resolve this URL to dynamic JSON metadata.
        // Example: https://aetherforge.xyz/api/mind/123?tier=3
        return string(abi.encodePacked(_baseAetherMindURI, _tokenId.toString(), "?tier=", currentTier.toString()));
    }

    /// @notice Retrieves the tokenId of the AetherMind NFT owned by a specific address.
    /// @param _owner The address of the NFT owner.
    /// @return The tokenId of the AetherMind NFT, or 0 if none exists.
    function getAetherMindTokenId(address _owner) public view returns (uint256) {
        return _userAetherMindTokenId[_owner];
    }
}
```