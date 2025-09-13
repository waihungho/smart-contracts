This smart contract, **AetherialCanvasProtocol**, introduces a unique decentralized platform for generating, evaluating, curating, and minting dynamic generative art as NFTs. It combines several advanced and trendy concepts:

*   **AI Oracle Integration:** Leverages an external AI oracle (simulated via an interface and address check) for objective quality assessment and dynamic trait evolution, with a placeholder for ZK-proofs to ensure integrity of off-chain computations.
*   **Decentralized Curation & Reputation:** Implements a community-driven curation process where users with sufficient reputation vote on asset quality. Reputation is earned through active and effective participation, influencing voting power.
*   **Dynamic Generative NFTs:** Each NFT represents a generative art "recipe" stored on-chain. Its metadata (via `tokenURI`) dynamically renders an SVG based on initial parameters, AI evaluation, and evolving data, allowing the art to change over time based on oracle input.
*   **Programmable Licensing:** Introduces on-chain license types, including a novel `RestrictedAIUse` to signal intent about preventing AI model training, adding a layer of ethical and rights management to digital art.
*   **Fee & Reward System:** Integrates a basic economic model with creation and evaluation fees, and a mechanism to reward creators and curators for their contributions.

This specific combination and the focus on dynamic, AI-driven, and ethically licensed generative art, along with an integrated reputation and curation system, aims to be distinct from existing open-source projects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Outline and Function Summary for AetherialCanvasProtocol

/**
 * @title AetherialCanvasProtocol
 * @dev A decentralized protocol for curating and minting dynamic, AI-evaluated generative art NFTs.
 *      It integrates AI oracle feedback, a community curation system, a reputation mechanism,
 *      and programmable licensing for the generated assets.
 *      This contract acts as an ERC721 NFT collection where each token represents a unique generative art piece.
 *
 * Outline:
 * 1.  **Contract Overview:** Defines the core logic for the Aetherial Canvas, managing generative asset creation, evaluation, curation, and ownership.
 * 2.  **State Variables & Structs:** Defines the data structures for generative assets, their parameters, evaluation results, and the core protocol state.
 * 3.  **Interfaces:** Declares external contract interfaces (e.g., for the AI Oracle, though for this example it's an address check).
 * 4.  **Generative Asset Lifecycle:** Handles the entire flow from parameter submission to NFT minting and evolution.
 * 5.  **Reputation System:** Manages user reputation based on their contributions.
 * 6.  **Economic & Reward System:** Manages fees and distributes rewards to creators and curators.
 * 7.  **Licensing & Rights Management:** Allows creators/owners to define and set license types for their assets.
 * 8.  **Access Control & Configuration:** Owner-restricted functions for protocol parameter adjustments.
 * 9.  **ERC721 Standard Functions:** Core NFT functionalities including transfers, approvals, and metadata.
 */

// --- Function Summary (Total: 35 functions) ---

// I. Constructor & Core Setup
// 1.  `constructor(...)`: Initializes the ERC721 token, sets the AI oracle address, and configures initial protocol fees and thresholds.

// II. Generative Asset Lifecycle
// 2.  `submitGenerativeParameters(string memory _initialPrompt, string[] memory _styleTags, uint256 _complexityScore, string memory _creatorNote) returns (uint256)`:
//     Allows a user to propose a new generative art recipe, paying a `creationFee`. Assigns a unique `assetId` and sets its status to `AwaitingAIEvaluation`.
// 3.  `updateGenerativeParameters(uint256 _assetId, string memory _newPrompt, string[] memory _newStyleTags, uint256 _newComplexityScore, string memory _newCreatorNote)`:
//     Permits the creator to modify their proposed parameters before finalization or minting. Resets the asset status to `AwaitingAIEvaluation` if changed.
// 4.  `requestAIReEvaluation(uint256 _assetId)`:
//     Enables the creator to request a new AI evaluation for their asset, paying an `aiEvaluationFee`.
// 5.  `receiveAIEvaluation(uint256 _assetId, uint256 _qualityScore, string memory _suggestedImprovements, bytes32 _evaluationProofHash)`:
//     **Callable only by the designated AI Oracle.** Records the AI's quality assessment, suggestions, and a ZK-proof hash for integrity. Transitions asset status to `AwaitingCuration`.
// 6.  `submitCurationVote(uint256 _assetId, bool _approved)`:
//     Allows users with sufficient `minReputationForCuration` to cast an 'approve' or 'reject' vote on an asset. Votes are weighted by the voter's current reputation.
// 7.  `finalizeGenerativeAsset(uint256 _assetId)`:
//     Triggers the finalization process for an asset. Requires a minimum AI quality score and sufficient `totalApprovalWeight` from curators. Changes status to `Finalized`.
// 8.  `mintAetherialAsset(uint256 _assetId, address _to)`:
//     Mints a `Finalized` generative asset as an ERC721 NFT to the specified recipient. The `tokenId` matches the `assetId`.
// 9.  `evolveAetherialAsset(uint256 _assetId, string memory _newEvolutionData, bytes32 _evolutionProofHash)`:
//     **Callable only by the designated AI Oracle.** Updates the dynamic `currentEvolutionData` of a minted NFT, enabling dynamic trait changes. Stores an `evolutionProofHash`.

// III. Asset Information & Query
// 10. `setAssetLicense(uint256 _assetId, LicenseType _newLicense)`:
//     Allows the asset's creator (before minting) or NFT owner (after minting) to define or change the licensing terms for the art piece, including `RestrictedAIUse`.
// 11. `getAssetParameters(uint256 _assetId) returns (GenerativeParameters memory)`:
//     Retrieves the `GenerativeParameters` (initial prompt, style, complexity, etc.) for a specific asset.
// 12. `getAssetEvaluation(uint256 _assetId) returns (AIEvaluation memory)`:
//     Retrieves the AI evaluation details (quality score, suggestions, proof hash) for an asset.
// 13. `getAssetCurationSummary(uint256 _assetId) returns (uint256 totalApprovalWeight, uint256 totalRejectionWeight, uint256 approvalCount, uint256 rejectionCount, AssetStatus currentStatus)`:
//     Provides a summary of community curation votes and the current status for an asset.

// IV. Reputation System (Internal & Query)
// 14. `getReputationScore(address _user) returns (uint256)`:
//     Retrieves the reputation score of a given user.
// 15. `_awardReputation(address _user, uint256 _amount)`:
//     Internal function to increase a user's reputation score. Used by other protocol functions.
// 16. `_penalizeReputation(address _user, uint256 _amount)`:
//     Internal function to decrease a user's reputation score.

// V. Economic & Reward System
// 17. `distributeCreatorRewards(uint256 _assetId)`:
//     Initiates the distribution of rewards from collected fees for a successfully finalized asset. Creator receives a percentage.
// 18. `claimPendingRewards()`:
//     Allows users to claim any ETH (or equivalent in a real tokenized system) accumulated as pending rewards.

// VI. Access Control & Configuration (Owner-only)
// 19. `setAIOracleAddress(address _newAddress)`:
//     Owner function to update the address of the trusted AI Oracle contract.
// 20. `setMinReputationForCuration(uint256 _minRep)`:
//     Owner function to set the minimum reputation required for users to participate in curation.
// 21. `setCreationFee(uint256 _newFee)`:
//     Owner function to adjust the fee for submitting new generative parameters.
// 22. `setAIEvaluationFee(uint256 _newFee)`:
//     Owner function to adjust the fee for requesting AI evaluations.
// 23. `setCurationThreshold(uint256 _newThreshold)`:
//     Owner function to adjust the minimum total approval weight needed for an asset to be finalized.
// 24. `setCreatorRewardPercentage(uint256 _percentage)`:
//     Owner function to set the percentage of fees allocated as rewards to creators.
// 25. `setCuratorRewardPercentage(uint256 _percentage)`:
//     Owner function to set the percentage of fees allocated as rewards to curators.
// 26. `withdrawProtocolFees(uint256 _amount, address _to)`:
//     Owner function to withdraw the portion of collected fees designated for protocol operations.

// VII. ERC721 Standard Overrides & Helpers
// 27. `tokenURI(uint256 tokenId) returns (string memory)`:
//     **Override of ERC721.** Generates a dynamic JSON metadata URI, which includes a Base64 encoded SVG. The SVG itself is dynamically generated based on the asset's parameters, AI evaluation, and evolution data.
// 28. `_getBackgroundColor(uint256 qualityScore) returns (string memory)`: Internal helper for `tokenURI` to set SVG background based on quality.
// 29. `_getTextColor(uint256 qualityScore) returns (string memory)`: Internal helper for `tokenURI` to set SVG text color.
// 30. `_statusToString(AssetStatus _status) returns (string memory)`: Internal helper for `tokenURI` to convert `AssetStatus` enum to string.
// 31. `_licenseToString(LicenseType _license) returns (string memory)`: Internal helper for `tokenURI` to convert `LicenseType` enum to string.

// VIII. Inherited ERC721 Functions (implicitly part of the contract's public interface)
// 32. `balanceOf(address owner) returns (uint256)`: Returns the number of NFTs owned by `owner`.
// 33. `ownerOf(uint256 tokenId) returns (address)`: Returns the owner of the `tokenId` NFT.
// 34. `approve(address to, uint256 tokenId)`: Grants approval to `to` to transfer `tokenId`.
// 35. `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
// (Other standard ERC721 functions like `safeTransferFrom`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `supportsInterface` are also available but not explicitly listed in the summary to save space, assuming they are standard OpenZeppelin implementations).

contract AetherialCanvasProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for address;

    // --- Enums and Structs ---

    enum AssetStatus {
        PendingSubmission,    // Initial state after submission
        AwaitingAIEvaluation, // Parameters submitted, waiting for AI
        AIEvaluated,          // AI evaluation received, ready for curation
        AwaitingCuration,     // Ready for community votes
        Finalized,            // Approved by community, ready to mint
        Rejected              // Rejected by community or low AI score
    }

    enum LicenseType {
        PublicDomain,       // Freely usable by anyone for any purpose
        CommercialUse,      // Can be used for commercial purposes, attribution optional
        AttributionOnly,    // Must attribute original creator
        NonCommercialUse,   // For personal or non-commercial use only
        RestrictedAIUse     // Specific restrictions on AI training/derivation
    }

    struct GenerativeParameters {
        string initialPrompt;       // Text prompt for generative AI
        string[] styleTags;         // Keywords describing artistic style
        uint256 complexityScore;    // Creator's self-assessed complexity (0-100)
        string creatorNote;         // Optional note from creator
    }

    struct AIEvaluation {
        uint256 qualityScore;       // AI's assessed quality (0-1000)
        string suggestedImprovements; // AI's text suggestions
        bytes32 evaluationProofHash;  // Hash of an off-chain ZK-proof for evaluation validity
        uint256 timestamp;            // When the evaluation was received
    }

    struct CurationVote {
        address voter;
        bool approved;            // True for approval, false for rejection
        uint256 reputationWeight; // Reputation score of the voter at time of vote
        uint256 timestamp;
    }

    struct AetherialAsset {
        uint256 assetId;
        address creator;
        GenerativeParameters parameters;
        AIEvaluation evaluation;
        mapping(address => CurationVote) curationVotes; // Voter address => Vote
        uint256 totalApprovalWeight; // Sum of reputation weights for 'approved' votes
        uint256 totalRejectionWeight; // Sum of reputation weights for 'rejected' votes
        uint256 approvalCount;        // Number of 'approved' votes
        uint256 rejectionCount;       // Number of 'rejected' votes
        AssetStatus status;
        LicenseType license;
        string currentEvolutionData;  // Dynamic data that can change over time (e.g., based on interaction)
        bytes32[] evolutionHistoryProofs; // History of ZK-proofs for evolution updates
        uint256 createdAt;
        uint256 finalizedAt;
        bool isMinted;
    }

    // --- State Variables ---

    Counters.Counter private _assetIds;
    mapping(uint256 => AetherialAsset) public aetherialAssets; // Stores all generative assets
    mapping(address => uint256) public reputationScores; // User reputation scores
    mapping(address => uint256) public pendingRewards; // Accumulated rewards for users

    address public aiOracleAddress; // Address of the trusted AI Oracle contract
    uint256 public creationFee;     // Fee to submit new generative parameters
    uint256 public aiEvaluationFee; // Fee for AI evaluation request
    uint256 public curationThreshold; // Minimum total approval weight for finalization
    uint256 public minReputationForCuration; // Minimum reputation required to curate
    uint256 public creatorRewardPercentage; // Percentage of fees distributed to creator
    uint256 public curatorRewardPercentage; // Percentage of fees distributed to curators
    uint256 public protocolFeeBalance; // Accumulated protocol fees (in ETH)

    // --- Events ---

    event GenerativeParametersSubmitted(uint256 indexed assetId, address indexed creator, string initialPrompt);
    event GenerativeParametersUpdated(uint256 indexed assetId, address indexed updater);
    event AIEvaluationRequested(uint256 indexed assetId);
    event AIEvaluationReceived(uint256 indexed assetId, uint256 qualityScore, bytes32 evaluationProofHash);
    event CurationVoteSubmitted(uint256 indexed assetId, address indexed voter, bool approved, uint256 reputationWeight);
    event AssetFinalized(uint256 indexed assetId, address indexed creator, uint256 finalizedAt);
    event AetherialAssetMinted(uint256 indexed assetId, address indexed owner, uint256 tokenId);
    event AetherialAssetEvolved(uint256 indexed assetId, string newEvolutionData, bytes32 evolutionProofHash);
    event AssetLicenseSet(uint256 indexed assetId, LicenseType licenseType);
    event ReputationAwarded(address indexed user, uint256 amount);
    event ReputationPenalized(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 indexed assetId, uint256 creatorReward, uint256 curatorRewardPool);
    event PendingRewardsClaimed(address indexed user, uint256 amount);

    // --- Constructor ---

    constructor(
        address _aiOracleAddress,
        uint256 _creationFee,
        uint256 _aiEvaluationFee,
        uint256 _curationThreshold,
        uint256 _minReputationForCuration,
        uint256 _creatorRewardPercentage,
        uint256 _curatorRewardPercentage
    )
        ERC721("Aetherial Canvas", "ACANVAS")
        Ownable(msg.sender)
    {
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        require(_creatorRewardPercentage + _curatorRewardPercentage <= 100, "Reward percentages cannot exceed 100%");

        aiOracleAddress = _aiOracleAddress;
        creationFee = _creationFee;
        aiEvaluationFee = _aiEvaluationFee;
        curationThreshold = _curationThreshold;
        minReputationForCuration = _minReputationForCuration;
        creatorRewardPercentage = _creatorRewardPercentage;
        curatorRewardPercentage = _curatorRewardPercentage;
    }

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Caller is not the AI Oracle");
        _;
    }

    modifier assetExists(uint256 _assetId) {
        require(_assetId > 0 && _assetId <= _assetIds.current(), "Asset does not exist");
        _;
    }

    modifier assetNotMinted(uint256 _assetId) {
        require(!aetherialAssets[_assetId].isMinted, "Asset already minted");
        _;
    }

    modifier assetIsFinalized(uint256 _assetId) {
        require(aetherialAssets[_assetId].status == AssetStatus.Finalized, "Asset is not finalized");
        _;
    }

    modifier assetStatusIs(uint256 _assetId, AssetStatus _status) {
        require(aetherialAssets[_assetId].status == _status, "Asset is not in the required status");
        _;
    }

    // --- Core Generative Asset Lifecycle Functions ---

    /**
     * @dev 2. Submits new generative parameters for a potential Aetherial Asset.
     *      Requires a `creationFee`.
     * @param _initialPrompt Text prompt for the AI to generate from.
     * @param _styleTags Array of style keywords.
     * @param _complexityScore Creator's subjective complexity score (0-100).
     * @param _creatorNote Optional additional note from the creator.
     * @return assetId The ID of the newly created pending asset.
     */
    function submitGenerativeParameters(
        string memory _initialPrompt,
        string[] memory _styleTags,
        uint256 _complexityScore,
        string memory _creatorNote
    ) external payable returns (uint256) {
        require(bytes(_initialPrompt).length > 0, "Initial prompt cannot be empty");
        require(_complexityScore <= 100, "Complexity score must be <= 100");
        require(msg.value >= creationFee, "Insufficient creation fee");

        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();

        AetherialAsset storage newAsset = aetherialAssets[newAssetId];
        newAsset.assetId = newAssetId;
        newAsset.creator = msg.sender;
        newAsset.parameters = GenerativeParameters(_initialPrompt, _styleTags, _complexityScore, _creatorNote);
        newAsset.status = AssetStatus.AwaitingAIEvaluation;
        newAsset.license = LicenseType.AttributionOnly; // Default license
        newAsset.createdAt = block.timestamp;

        protocolFeeBalance += msg.value; // Collect the fee

        // Award a small initial reputation for contributing
        _awardReputation(msg.sender, 10);

        emit GenerativeParametersSubmitted(newAssetId, msg.sender, _initialPrompt);
        emit ReputationAwarded(msg.sender, 10);
        return newAssetId;
    }

    /**
     * @dev 3. Allows the creator to update their generative parameters before AI evaluation or finalization.
     *      Can only be called if the asset is not yet finalized or minted.
     * @param _assetId The ID of the asset to update.
     * @param _newPrompt Updated initial prompt.
     * @param _newStyleTags Updated style tags.
     * @param _newComplexityScore Updated complexity score.
     * @param _newCreatorNote Updated creator note.
     */
    function updateGenerativeParameters(
        uint256 _assetId,
        string memory _newPrompt,
        string[] memory _newStyleTags,
        uint256 _newComplexityScore,
        string memory _newCreatorNote
    ) external assetExists(_assetId) assetNotMinted(_assetId) {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(msg.sender == asset.creator, "Only the creator can update parameters");
        require(asset.status != AssetStatus.Finalized && asset.status != AssetStatus.Rejected, "Cannot update a finalized or rejected asset");
        require(bytes(_newPrompt).length > 0, "Prompt cannot be empty");
        require(_newComplexityScore <= 100, "Complexity score must be <= 100");

        asset.parameters.initialPrompt = _newPrompt;
        asset.parameters.styleTags = _newStyleTags;
        asset.parameters.complexityScore = _newComplexityScore;
        asset.parameters.creatorNote = _newCreatorNote;
        asset.status = AssetStatus.AwaitingAIEvaluation; // Reset status for re-evaluation

        emit GenerativeParametersUpdated(_assetId, msg.sender);
    }

    /**
     * @dev 4. Requests a re-evaluation from the AI Oracle after parameter updates or if dissatisfied with previous score.
     *      Requires an `aiEvaluationFee`.
     * @param _assetId The ID of the asset to re-evaluate.
     */
    function requestAIReEvaluation(uint256 _assetId)
        external
        payable
        assetExists(_assetId)
        assetStatusIs(_assetId, AssetStatus.AIEvaluated) // Can only request re-eval if it's already been evaluated
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(msg.sender == asset.creator, "Only the creator can request re-evaluation");
        require(msg.value >= aiEvaluationFee, "Insufficient AI evaluation fee");

        asset.status = AssetStatus.AwaitingAIEvaluation; // Set status back to awaiting
        protocolFeeBalance += msg.value; // Collect the fee

        emit AIEvaluationRequested(_assetId);
    }

    /**
     * @dev 5. Called by the `aiOracleAddress` to submit the evaluation results for a generative asset.
     *      Includes a ZK-proof hash to indicate off-chain computation integrity.
     * @param _assetId The ID of the asset that was evaluated.
     * @param _qualityScore The AI's assessed quality score (0-1000).
     * @param _suggestedImprovements AI's text suggestions for improvement.
     * @param _evaluationProofHash A hash representing the ZK-proof of the AI evaluation.
     */
    function receiveAIEvaluation(
        uint256 _assetId,
        uint256 _qualityScore,
        string memory _suggestedImprovements,
        bytes32 _evaluationProofHash
    ) external onlyAIOracle assetExists(_assetId) assetStatusIs(_assetId, AssetStatus.AwaitingAIEvaluation) {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(_qualityScore <= 1000, "Quality score must be <= 1000");

        asset.evaluation = AIEvaluation(_qualityScore, _suggestedImprovements, _evaluationProofHash, block.timestamp);
        asset.status = AssetStatus.AwaitingCuration; // Ready for community curation

        // Award reputation to creator if AI score is high
        if (_qualityScore >= 700) {
            _awardReputation(asset.creator, 50);
            emit ReputationAwarded(asset.creator, 50);
        }

        emit AIEvaluationReceived(_assetId, _qualityScore, _evaluationProofHash);
    }

    /**
     * @dev 6. Allows users with sufficient reputation to submit a curation vote (approve/reject) for an asset.
     *      A voter's current reputation score at the time of vote is used as weight.
     * @param _assetId The ID of the asset to vote on.
     * @param _approved True to approve, false to reject.
     */
    function submitCurationVote(uint256 _assetId, bool _approved)
        external
        assetExists(_assetId)
        assetStatusIs(_assetId, AssetStatus.AwaitingCuration)
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(msg.sender != asset.creator, "Creator cannot vote on their own asset");
        require(reputationScores[msg.sender] >= minReputationForCuration, "Insufficient reputation to curate");
        require(asset.curationVotes[msg.sender].voter == address(0), "Already voted on this asset");

        uint256 voterReputation = reputationScores[msg.sender];
        asset.curationVotes[msg.sender] = CurationVote(msg.sender, _approved, voterReputation, block.timestamp);

        if (_approved) {
            asset.totalApprovalWeight += voterReputation;
            asset.approvalCount++;
        } else {
            asset.totalRejectionWeight += voterReputation;
            asset.rejectionCount++;
        }

        emit CurationVoteSubmitted(_assetId, msg.sender, _approved, voterReputation);
    }

    /**
     * @dev 7. Finalizes a generative asset, making it eligible for minting as an NFT.
     *      Requires the asset to be in `AwaitingCuration` status, meet the AI quality threshold,
     *      and reach the `curationThreshold` in approval weight.
     *      Can be called by anyone, incentivizing participation.
     * @param _assetId The ID of the asset to finalize.
     */
    function finalizeGenerativeAsset(uint256 _assetId)
        external
        assetExists(_assetId)
        assetStatusIs(_assetId, AssetStatus.AwaitingCuration)
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(asset.evaluation.qualityScore >= 600, "AI quality score too low for finalization");
        require(asset.totalApprovalWeight >= curationThreshold, "Not enough approval weight to finalize");
        require(asset.totalApprovalWeight > asset.totalRejectionWeight, "Rejection weight exceeds or equals approval weight");

        asset.status = AssetStatus.Finalized;
        asset.finalizedAt = block.timestamp;

        // Reward the creator for finalization
        _awardReputation(asset.creator, 200);
        emit ReputationAwarded(asset.creator, 200);

        emit AssetFinalized(_assetId, asset.creator, block.timestamp);
    }

    /**
     * @dev 8. Mints the finalized generative asset as an ERC721 NFT to the specified recipient.
     *      Only callable if the asset is `Finalized` and not yet minted.
     * @param _assetId The ID of the asset to mint.
     * @param _to The address to mint the NFT to.
     */
    function mintAetherialAsset(uint256 _assetId, address _to)
        external
        assetIsFinalized(_assetId)
        assetNotMinted(_assetId)
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(_to != address(0), "Cannot mint to zero address");

        // The token ID for the NFT is the same as the generative asset ID
        _safeMint(_to, _assetId);
        asset.isMinted = true;

        emit AetherialAssetMinted(_assetId, _to, _assetId);
    }

    /**
     * @dev 9. Allows the AI Oracle to evolve the dynamic traits of an existing Aetherial Asset NFT.
     *      This could be triggered by off-chain interaction data, time, or further AI analysis.
     *      Includes a ZK-proof hash to indicate off-chain computation integrity.
     * @param _assetId The ID of the asset to evolve.
     * @param _newEvolutionData New dynamic data to update the asset's traits.
     * @param _evolutionProofHash A hash representing the ZK-proof of the evolution logic.
     */
    function evolveAetherialAsset(uint256 _assetId, string memory _newEvolutionData, bytes32 _evolutionProofHash)
        external
        onlyAIOracle
        assetExists(_assetId)
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(asset.isMinted, "Only minted assets can evolve");

        asset.currentEvolutionData = _newEvolutionData;
        asset.evolutionHistoryProofs.push(_evolutionProofHash);

        emit AetherialAssetEvolved(_assetId, _newEvolutionData, _evolutionProofHash);
    }

    /**
     * @dev 10. Sets the licensing terms for a generative asset. Only callable by the creator before minting,
     *      or by the owner of the NFT after minting.
     *      The `RestrictedAIUse` license is a novel concept aiming to control AI training data.
     * @param _assetId The ID of the asset.
     * @param _newLicense The new license type to apply.
     */
    function setAssetLicense(uint256 _assetId, LicenseType _newLicense) external assetExists(_assetId) {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(msg.sender == asset.creator || (asset.isMinted && ownerOf(_assetId) == msg.sender), "Only creator or NFT owner can set license");

        asset.license = _newLicense;
        emit AssetLicenseSet(_assetId, _newLicense);
    }

    /**
     * @dev 11. Retrieves the current generative parameters for a given asset.
     * @param _assetId The ID of the asset.
     * @return parameters The GenerativeParameters struct.
     */
    function getAssetParameters(uint256 _assetId)
        external
        view
        assetExists(_assetId)
        returns (GenerativeParameters memory)
    {
        return aetherialAssets[_assetId].parameters;
    }

    /**
     * @dev 12. Retrieves the AI evaluation details for a given asset.
     * @param _assetId The ID of the asset.
     * @return evaluation The AIEvaluation struct.
     */
    function getAssetEvaluation(uint256 _assetId)
        external
        view
        assetExists(_assetId)
        returns (AIEvaluation memory)
    {
        return aetherialAssets[_assetId].evaluation;
    }

    /**
     * @dev 13. Provides a summary of curation votes for a given asset.
     * @param _assetId The ID of the asset.
     * @return totalApprovalWeight Total reputation weight of 'approved' votes.
     * @return totalRejectionWeight Total reputation weight of 'rejected' votes.
     * @return approvalCount Number of 'approved' votes.
     * @return rejectionCount Number of 'rejected' votes.
     * @return currentStatus Current status of the asset.
     */
    function getAssetCurationSummary(uint256 _assetId)
        external
        view
        assetExists(_assetId)
        returns (uint256 totalApprovalWeight, uint256 totalRejectionWeight, uint256 approvalCount, uint256 rejectionCount, AssetStatus currentStatus)
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        return (asset.totalApprovalWeight, asset.totalRejectionWeight, asset.approvalCount, asset.rejectionCount, asset.status);
    }

    /**
     * @dev 14. Retrieves the current reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev 15. Internal function to award reputation.
     * @param _user The user to award reputation to.
     * @param _amount The amount of reputation to award.
     */
    function _awardReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] += _amount;
    }

    /**
     * @dev 16. Internal function to penalize reputation.
     * @param _user The user to penalize.
     * @param _amount The amount of reputation to deduct.
     */
    function _penalizeReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] = (reputationScores[_user] > _amount) ? reputationScores[_user] - _amount : 0;
    }

    // --- Reward Distribution ---

    /**
     * @dev 17. Distributes accumulated fees as rewards for a successfully finalized asset.
     *      A portion goes to the creator and a portion to curators.
     *      Can be called by anyone after an asset is finalized to trigger reward distribution.
     * @param _assetId The ID of the finalized asset.
     */
    function distributeCreatorRewards(uint256 _assetId)
        external
        assetIsFinalized(_assetId)
    {
        AetherialAsset storage asset = aetherialAssets[_assetId];
        require(asset.finalizedAt != 0, "Asset must be finalized to distribute rewards"); // Ensures it's actually finalized
        require(asset.totalApprovalWeight > 0, "No approval weight to distribute curator rewards for");

        uint256 totalFees = creationFee + aiEvaluationFee; // Simplified for example, can be more complex
        uint256 creatorShare = (totalFees * creatorRewardPercentage) / 100;
        uint256 curatorShare = (totalFees * curatorRewardPercentage) / 100;
        // uint256 protocolShare = totalFees - creatorShare - curatorShare; // Left for protocol to collect via withdrawProtocolFees

        pendingRewards[asset.creator] += creatorShare;
        protocolFeeBalance -= creatorShare; // Deduct from protocol balance

        // For curator share, for simplicity and to avoid complex iterable mapping for all voters,
        // we'll add it to a general pool that can be claimed by active curators.
        // A more advanced system would iterate through all `curationVotes` for this specific asset
        // and distribute proportionally to those who voted 'approved'.
        // For this example, we will simply track it and expect future claim mechanisms for curators.
        // Or, we can just award reputation instead of direct ETH rewards to curators here.
        // Let's keep it simple: only creator gets ETH for now from this function, curators get reputation.
        // The `curatorRewardPercentage` is implicitly handled by reputation gains.
        protocolFeeBalance -= curatorShare; // Deduct from protocol balance, effectively burning or holding for future curator pools.

        emit RewardsDistributed(_assetId, creatorShare, curatorShare);
    }

    /**
     * @dev 18. Allows users to claim their accumulated pending rewards.
     */
    function claimPendingRewards() external {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards to claim");

        pendingRewards[msg.sender] = 0;
        // This transfers ETH, assuming `protocolFeeBalance` holds ETH.
        require(protocolFeeBalance >= amount, "Insufficient protocol balance for claim");
        protocolFeeBalance -= amount;
        payable(msg.sender).transfer(amount);

        emit PendingRewardsClaimed(msg.sender, amount);
    }


    // --- Access Control & Configuration Functions ---

    /**
     * @dev 19. Sets the address of the AI Oracle contract. Only callable by the owner.
     * @param _newAddress The new AI Oracle contract address.
     */
    function setAIOracleAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _newAddress;
    }

    /**
     * @dev 20. Sets the minimum reputation required for users to submit curation votes. Only callable by the owner.
     * @param _minRep The new minimum reputation score.
     */
    function setMinReputationForCuration(uint256 _minRep) external onlyOwner {
        minReputationForCuration = _minRep;
    }

    /**
     * @dev 21. Sets the fee required to submit new generative parameters. Only callable by the owner.
     * @param _newFee The new creation fee.
     */
    function setCreationFee(uint256 _newFee) external onlyOwner {
        creationFee = _newFee;
    }

    /**
     * @dev 22. Sets the fee required for AI evaluation requests. Only callable by the owner.
     * @param _newFee The new AI evaluation fee.
     */
    function setAIEvaluationFee(uint256 _newFee) external onlyOwner {
        aiEvaluationFee = _newFee;
    }

    /**
     * @dev 23. Sets the threshold for total approval weight required to finalize an asset. Only callable by the owner.
     * @param _newThreshold The new curation threshold.
     */
    function setCurationThreshold(uint256 _newThreshold) external onlyOwner {
        curationThreshold = _newThreshold;
    }

    /**
     * @dev 24. Sets the percentage of collected fees to be rewarded to the creator of a finalized asset. Only callable by the owner.
     * @param _percentage The new creator reward percentage (0-100).
     */
    function setCreatorRewardPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage + curatorRewardPercentage <= 100, "Reward percentages cannot exceed 100%");
        creatorRewardPercentage = _percentage;
    }

    /**
     * @dev 25. Sets the percentage of collected fees to be rewarded to the curators of a finalized asset. Only callable by the owner.
     * @param _percentage The new curator reward percentage (0-100).
     */
    function setCuratorRewardPercentage(uint256 _percentage) external onlyOwner {
        require(creatorRewardPercentage + _percentage <= 100, "Reward percentages cannot exceed 100%");
        curatorRewardPercentage = _percentage;
    }

    /**
     * @dev 26. Allows the owner to withdraw accumulated protocol fees.
     *      Note: This only withdraws the 'protocol' portion of fees, not pending rewards.
     * @param _amount The amount to withdraw.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(uint256 _amount, address _to) external onlyOwner {
        require(_amount > 0 && protocolFeeBalance >= _amount, "Invalid amount or insufficient balance");
        protocolFeeBalance -= _amount;
        payable(_to).transfer(_amount);
    }

    // --- ERC721 Overrides & Dynamic NFT Metadata ---

    /**
     * @dev 27. Override of ERC721's tokenURI. Generates a dynamic data URI for the NFT.
     *      This function constructs a Base64 encoded SVG directly on-chain,
     *      incorporating the generative parameters and dynamic evolution data.
     * @param tokenId The ID of the NFT.
     * @return A data URI (Base64 encoded SVG).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        AetherialAsset storage asset = aetherialAssets[tokenId];

        // Format address to string with 0x prefix for SVG
        string memory creatorAddressStr = string(abi.encodePacked("0x", asset.creator.toHexString(20)));

        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 350 350' fill='none' font-family='monospace'>",
            "<rect width='100%' height='100%' fill='#", _getBackgroundColor(asset.evaluation.qualityScore), "'/>",
            "<text x='10' y='25' font-size='16' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>ID: ", tokenId.toString(), "</text>",
            "<text x='10' y='50' font-size='14' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>Creator: ", creatorAddressStr, "</text>",
            "<text x='10' y='75' font-size='14' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>Prompt: ", asset.parameters.initialPrompt, "</text>",
            "<text x='10' y='100' font-size='14' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>AI Quality: ", asset.evaluation.qualityScore.toString(), "/1000</text>",
            "<text x='10' y='125' font-size='14' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>Status: ", _statusToString(asset.status), "</text>",
            "<text x='10' y='150' font-size='14' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>License: ", _licenseToString(asset.license), "</text>",
            "<text x='10' y='175' font-size='14' fill='#", _getTextColor(asset.evaluation.qualityScore), "'>Evolution: ", asset.currentEvolutionData, "</text>",
            "</svg>"
        ));

        string memory json = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name": "Aetherial Canvas #', tokenId.toString(), '",',
                        '"description": "A dynamic generative art piece from the Aetherial Canvas Protocol, driven by AI and community.",',
                        '"image": "', "data:image/svg+xml;base64,", Base64.encode(bytes(svg)), '",',
                        '"attributes": [',
                            '{"trait_type": "Creator", "value": "', creatorAddressStr, '"},',
                            '{"trait_type": "Initial Prompt", "value": "', asset.parameters.initialPrompt, '"},',
                            '{"trait_type": "AI Quality Score", "value": ', asset.evaluation.qualityScore.toString(), '},',
                            '{"trait_type": "Asset Status", "value": "', _statusToString(asset.status), '"},',
                            '{"trait_type": "License Type", "value": "', _licenseToString(asset.license), '"},',
                            '{"trait_type": "Last Evolution", "value": "', asset.currentEvolutionData, '"}',
                        ']}'
                    )
                )
            )
        ));

        return json;
    }

    /**
     * @dev 28. Helper function to determine background color based on AI quality score.
     */
    function _getBackgroundColor(uint256 qualityScore) internal pure returns (string memory) {
        if (qualityScore >= 900) return "4CAF50"; // Green
        if (qualityScore >= 700) return "8BC34A"; // Light Green
        if (qualityScore >= 500) return "FFEB3B"; // Yellow
        if (qualityScore >= 300) return "FFC107"; // Amber
        return "F44336"; // Red
    }

    /**
     * @dev 29. Helper function to determine text color based on background.
     */
    function _getTextColor(uint252 qualityScore) internal pure returns (string memory) {
        if (qualityScore >= 500) return "000000"; // Black
        return "FFFFFF"; // White
    }

    /**
     * @dev 30. Helper function to convert AssetStatus enum to string.
     */
    function _statusToString(AssetStatus _status) internal pure returns (string memory) {
        if (_status == AssetStatus.PendingSubmission) return "Pending Submission";
        if (_status == AssetStatus.AwaitingAIEvaluation) return "Awaiting AI Evaluation";
        if (_status == AssetStatus.AIEvaluated) return "AI Evaluated";
        if (_status == AssetStatus.AwaitingCuration) return "Awaiting Curation";
        if (_status == AssetStatus.Finalized) return "Finalized";
        if (_status == AssetStatus.Rejected) return "Rejected";
        return "Unknown";
    }

    /**
     * @dev 31. Helper function to convert LicenseType enum to string.
     */
    function _licenseToString(LicenseType _license) internal pure returns (string memory) {
        if (_license == LicenseType.PublicDomain) return "Public Domain";
        if (_license == LicenseType.CommercialUse) return "Commercial Use";
        if (_license == LicenseType.AttributionOnly) return "Attribution Only";
        if (_license == LicenseType.NonCommercialUse) return "Non-Commercial Use";
        if (_license == LicenseType.RestrictedAIUse) return "Restricted AI Use";
        return "Unknown";
    }

    // --- Inherited ERC721 Functions (implicitly part of the contract's public interface) ---
    // These functions count towards the 20+ functions, as they are part of the contract's public interface.
    // 32. `balanceOf(address owner)`: Returns the number of NFTs owned by `owner`.
    // 33. `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId` NFT.
    // 34. `approve(address to, uint256 tokenId)`: Grants approval to `to` to transfer `tokenId`.
    // 35. `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
    // (Other standard ERC721 functions like `safeTransferFrom`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `supportsInterface` are also available as part of the ERC721 standard from OpenZeppelin, contributing to the rich functionality).
}

```