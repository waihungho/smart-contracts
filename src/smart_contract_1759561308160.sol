## NeuralCanvas - Decentralized AI Art & Curation Protocol

This smart contract establishes a decentralized platform for AI-generated art, combining dynamic NFTs, a reputation system, and on-chain curation. Users (Artisans) submit prompts for AI models, which are then processed off-chain by Oracles. The resulting art is minted as a dynamic NFT. Other users (Curators) evaluate this art, and their evaluations contribute to their reputation scores. A dispute resolution mechanism ensures fairness, and a DAO governs the protocol's evolution. The metadata of the NFTs is dynamic, reflecting the aggregated evaluation scores.

---

### Function Summary:

**I. Core Protocol Configuration & Management (Admin/DAO):**
1.  `initializeProtocol()`: Initializes the contract, setting the initial owner.
2.  `setPromptSubmissionFee(uint256 _fee)`: Sets the fee required for Artisans to submit a new prompt.
3.  `setEvaluationRewardRate(uint256 _rate)`: Sets the reward amount (in `rewardToken`) given to Curators for accurate evaluations.
4.  `setAIGenerationOracle(address _oracle)`: Sets the address of the trusted oracle responsible for triggering off-chain AI art generation and recording its output.
5.  `setDisputeResolutionOracle(address _oracle)`: Sets the address of the trusted oracle responsible for resolving challenges against evaluations.
6.  `setRewardToken(address _token)`: Sets the ERC20 token address used for distributing rewards to Artisans and Curators.
7.  `pauseProtocol()`: Pauses core functionalities in case of emergencies, preventing most state-changing operations.
8.  `unpauseProtocol()`: Unpauses the protocol, re-enabling normal operations.
9.  `setAIGeneratorConfig(bytes32 _modelId, bytes calldata _config)`: Allows the DAO/Admin to configure specific parameters for a given AI model ID, which the AI Oracle should adhere to.
10. `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the DAO/Admin to withdraw collected protocol fees (e.g., prompt submission fees) to a specified address.

**II. Artisan Prompt Submission & Art Generation:**
11. `submitPrompt(string memory _promptText, bytes32 _aiModelId)`: Artisans submit a prompt, paying the `promptSubmissionFee`, to initiate the AI art generation process.
12. `recordAIGenerationOutput(uint256 _promptId, string memory _ipfsHash, bytes memory _proofData)`: Callable only by the `aiGenerationOracle`, this function records the successful output of an off-chain AI generation, minting a new dynamic NFT for the Artisan.
13. `claimFailedPromptRefund(uint256 _promptId)`: Allows an Artisan to reclaim their prompt submission fee if the AI generation for their prompt failed or was officially cancelled.

**III. Dynamic NFT & Metadata Management:**
14. `tokenURI(uint256 _tokenId)`: Standard ERC721 function; returns a dynamic metadata URI for a given NFT, reflecting its current status and aggregated evaluation scores.
15. `getPromptDetails(uint256 _promptId)`: Retrieves comprehensive details about a specific submitted prompt.
16. `getArtDetails(uint256 _tokenId)`: Retrieves detailed information about a specific minted AI art NFT, including its aggregated score and problematic status.

**IV. Curator Evaluation & Dispute Resolution:**
17. `evaluateArt(uint256 _tokenId, uint8 _score, string memory _justificationIpfsHash)`: Curators submit an evaluation score (0-100) for an art NFT, with an optional IPFS hash pointing to a justification.
18. `challengeEvaluation(uint256 _tokenId, uint256 _evaluationId, string memory _reasonIpfsHash)`: Allows any user to challenge an existing evaluation, initiating a formal dispute process.
19. `resolveDispute(uint256 _disputeId, bool _isChallengerCorrect, bytes memory _resolutionProof)`: Callable only by the `disputeResolutionOracle`, this function resolves a challenge, updating reputation scores and potentially reversing previous rewards.
20. `markArtAsProblematic(uint256 _tokenId, string memory _reasonIpfsHash)`: Allows an authorized role (e.g., DAO) to flag a piece of art as inappropriate or violating protocol terms, impacting its visibility and metadata.

**V. Reputation & Rewards:**
21. `claimArtisanRewards()`: Artisans can claim their accumulated `rewardToken`s earned from their successfully generated and highly-rated art.
22. `claimCuratorRewards()`: Curators can claim their accumulated `rewardToken`s earned from their accurate and well-received evaluations.
23. `getArtisanReputation(address _artisan)`: Retrieves the current reputation score for a given Artisan, indicating their track record of generating quality art.
24. `getCuratorReputation(address _curator)`: Retrieves the current reputation score for a given Curator, reflecting the accuracy and reliability of their evaluations.
25. `getAccruedArtisanRewards(address _artisan)`: Returns the current amount of unclaimed `rewardToken`s for a specific Artisan.
26. `getAccruedCuratorRewards(address _curator)`: Returns the current amount of unclaimed `rewardToken`s for a specific Curator.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom Errors
error InvalidPromptId();
error InvalidTokenId();
error InvalidEvaluationId();
error InvalidDisputeId();
error PromptAlreadyGenerated();
error PromptGenerationFailed();
error PromptNotGenerated();
error NotAuthorized();
error NotEnoughFeePaid();
error PromptFeeMismatch();
error NothingToClaim();
error ArtAlreadyProblematic();
error EvaluationAlreadyChallenged();
error ScoreOutOfRange();
error RewardTokenNotSet();
error OracleAddressNotSet();

contract NeuralCanvas is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    // --- State Variables ---

    // Protocol Configuration
    uint256 public promptSubmissionFee;
    uint256 public evaluationRewardRate; // Amount of rewardToken per accurate evaluation
    address public aiGenerationOracle;
    address public disputeResolutionOracle;
    IERC20 public rewardToken;
    address public treasuryAddress; // Where protocol fees are sent

    // Unique counters for IDs
    uint256 private _nextTokenId;
    uint256 private _nextPromptId;
    uint256 private _nextEvaluationId;
    uint256 private _nextDisputeId;

    // --- Data Structures ---

    enum PromptStatus { Submitted, AwaitingGeneration, Generated, Failed, Refunded }

    struct Prompt {
        address artisan;
        string promptText;
        bytes32 aiModelId; // Identifier for the AI model to use
        uint256 submissionTime;
        uint256 submissionFee; // Fee paid by artisan
        PromptStatus status;
        uint256 artTokenId; // If successfully generated, links to token
    }

    struct ArtDetails {
        uint256 promptId;
        string ipfsHash; // IPFS hash of the generated image/media
        bytes aiProofData; // Data from oracle proving generation
        uint256 mintTime;
        uint256 aggregatedScore; // Sum of all valid evaluation scores
        uint256 numValidEvaluations;
        bool isProblematic; // Flagged by DAO/Admin
        mapping(address => uint256) curatorEvaluationIds; // Curator address => evaluationId (0 if none)
    }

    struct Evaluation {
        uint256 tokenId;
        address curator;
        uint8 score; // 0-100
        string justificationIpfsHash;
        uint256 evaluationTime;
        bool isValid; // Can be invalidated by dispute or flagged art
        bool isChallenged;
        uint256 disputeId; // If challenged, links to dispute
    }

    enum DisputeStatus { Pending, Resolved }

    struct Dispute {
        uint256 tokenId;
        uint256 evaluationId;
        address challenger;
        string reasonIpfsHash;
        uint256 challengeTime;
        DisputeStatus status;
        bool challengerCorrect; // Result of resolution by dispute oracle
    }

    // --- Mappings ---
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => ArtDetails) public artDetails; // tokenId => ArtDetails
    mapping(uint256 => Evaluation) public evaluations; // evaluationId => Evaluation
    mapping(uint256 => Dispute) public disputes; // disputeId => Dispute

    // Reputation Scores
    mapping(address => uint256) public artisanReputation; // Successful generations, high scores
    mapping(address => uint256) public curatorReputation; // Accurate evaluations

    // Accrued Rewards
    mapping(address => uint256) private _accruedArtisanRewards;
    mapping(address => uint256) private _accruedCuratorRewards;

    // AI Generator Configuration (e.g., specific model parameters)
    mapping(bytes32 => bytes) public aiGeneratorConfigs;

    // --- Events ---
    event ProtocolInitialized(address indexed owner);
    event PromptSubmitted(uint256 indexed promptId, address indexed artisan, string promptText, bytes32 aiModelId, uint256 fee);
    event AIGenerationRecorded(uint256 indexed promptId, uint256 indexed tokenId, string ipfsHash, address indexed artisan);
    event PromptRefunded(uint256 indexed promptId, address indexed artisan, uint256 amount);
    event ArtEvaluated(uint256 indexed tokenId, uint256 indexed evaluationId, address indexed curator, uint8 score);
    event EvaluationChallenged(uint256 indexed disputeId, uint256 indexed tokenId, uint256 indexed evaluationId, address challenger);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed tokenId, uint256 indexed evaluationId, bool challengerCorrect);
    event ArtProblematicFlagged(uint256 indexed tokenId, address indexed flipper, string reasonIpfsHash);
    event ArtisanRewardsClaimed(address indexed artisan, uint256 amount);
    event CuratorRewardsClaimed(address indexed curator, uint256 amount);
    event ProtocolFeeWithdrawn(address indexed to, uint256 amount);
    event ParamSet(bytes32 indexed key, bytes value); // Generic for config changes

    // --- Constructor & Initializer ---

    constructor() ERC721("NeuralCanvas AI Art", "NCAA") {
        _disableInitializers(); // For UUPS, if used; otherwise, benign.
        // Owner will be set by initializeProtocol if it's the first call
    }

    /// @notice Initializes the protocol parameters. Can only be called once.
    function initializeProtocol() public initializer {
        __Ownable_init();
        __Pausable_init();
        _nextTokenId = 1;
        _nextPromptId = 1;
        _nextEvaluationId = 1;
        _nextDisputeId = 1;
        treasuryAddress = msg.sender; // Initial treasury is the deployer, can be changed by DAO
        emit ProtocolInitialized(msg.sender);
    }

    // --- I. Core Protocol Configuration & Management (Admin/DAO) ---

    /// @notice Sets the fee required for Artisans to submit a new prompt.
    /// @param _fee The new prompt submission fee.
    function setPromptSubmissionFee(uint256 _fee) external onlyOwner {
        promptSubmissionFee = _fee;
        emit ParamSet("promptSubmissionFee", abi.encode(_fee));
    }

    /// @notice Sets the reward amount (in rewardToken) given to Curators for accurate evaluations.
    /// @param _rate The new evaluation reward rate.
    function setEvaluationRewardRate(uint256 _rate) external onlyOwner {
        evaluationRewardRate = _rate;
        emit ParamSet("evaluationRewardRate", abi.encode(_rate));
    }

    /// @notice Sets the address of the trusted oracle for AI generation.
    /// @param _oracle The new AI generation oracle address.
    function setAIGenerationOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert OracleAddressNotSet();
        aiGenerationOracle = _oracle;
        emit ParamSet("aiGenerationOracle", abi.encode(_oracle));
    }

    /// @notice Sets the address of the trusted oracle for dispute resolution.
    /// @param _oracle The new dispute resolution oracle address.
    function setDisputeResolutionOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert OracleAddressNotSet();
        disputeResolutionOracle = _oracle;
        emit ParamSet("disputeResolutionOracle", abi.encode(_oracle));
    }

    /// @notice Sets the ERC20 token address used for distributing rewards.
    /// @param _token The address of the reward ERC20 token.
    function setRewardToken(address _token) external onlyOwner {
        if (_token == address(0)) revert RewardTokenNotSet();
        rewardToken = IERC20(_token);
        emit ParamSet("rewardToken", abi.encode(_token));
    }

    /// @notice Pauses core functionalities in case of emergencies.
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the protocol, re-enabling normal operations.
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the DAO/Admin to configure specific parameters for a given AI model ID.
    /// @param _modelId A unique identifier for the AI model.
    /// @param _config Arbitrary bytes representing the configuration for the model.
    function setAIGeneratorConfig(bytes32 _modelId, bytes calldata _config) external onlyOwner {
        aiGeneratorConfigs[_modelId] = _config;
        emit ParamSet(_modelId, _config);
    }

    /// @notice Allows the DAO/Admin to withdraw collected protocol fees to a specified address.
    /// @param _to The recipient address for the fees.
    /// @param _amount The amount of native currency to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyOwner nonReentrant {
        if (_to == address(0)) revert NotAuthorized(); // Better error, but signifies admin decision
        if (_amount == 0) revert NothingToClaim();
        // Assuming fees are collected as native currency (ETH/MATIC etc.)
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit ProtocolFeeWithdrawn(_to, _amount);
    }

    // --- II. Artisan Prompt Submission & Art Generation ---

    /// @notice Artisans submit a prompt, paying a fee, to initiate AI art generation.
    /// @param _promptText The descriptive text for the AI to generate art from.
    /// @param _aiModelId The identifier for the desired AI model to use.
    function submitPrompt(string memory _promptText, bytes32 _aiModelId) public payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.value < promptSubmissionFee) revert NotEnoughFeePaid();
        if (msg.value > promptSubmissionFee) {
            // Refund excess
            (bool success,) = msg.sender.call{value: msg.value - promptSubmissionFee}("");
            require(success, "Refund excess failed");
        }

        uint256 currentPromptId = _nextPromptId++;
        prompts[currentPromptId] = Prompt({
            artisan: msg.sender,
            promptText: _promptText,
            aiModelId: _aiModelId,
            submissionTime: block.timestamp,
            submissionFee: promptSubmissionFee,
            status: PromptStatus.AwaitingGeneration,
            artTokenId: 0 // Will be set upon generation
        });

        // Send fee to treasury
        (bool success,) = treasuryAddress.call{value: promptSubmissionFee}("");
        require(success, "Failed to send fee to treasury");

        emit PromptSubmitted(currentPromptId, msg.sender, _promptText, _aiModelId, promptSubmissionFee);
        return currentPromptId;
    }

    /// @notice Oracle records the result of an off-chain AI generation, minting a new dynamic NFT.
    /// @dev Callable only by the designated AI Generation Oracle.
    /// @param _promptId The ID of the prompt for which art was generated.
    /// @param _ipfsHash The IPFS hash pointing to the generated image/media.
    /// @param _proofData Arbitrary proof data from the oracle.
    function recordAIGenerationOutput(uint256 _promptId, string memory _ipfsHash, bytes memory _proofData) external whenNotPaused nonReentrant {
        if (msg.sender != aiGenerationOracle) revert NotAuthorized();
        if (_promptId == 0 || _promptId >= _nextPromptId) revert InvalidPromptId();

        Prompt storage prompt = prompts[_promptId];
        if (prompt.status != PromptStatus.AwaitingGeneration) revert PromptAlreadyGenerated();

        uint256 currentTokenId = _nextTokenId++;
        _safeMint(prompt.artisan, currentTokenId);

        prompt.status = PromptStatus.Generated;
        prompt.artTokenId = currentTokenId;

        artDetails[currentTokenId].promptId = _promptId;
        artDetails[currentTokenId].ipfsHash = _ipfsHash;
        artDetails[currentTokenId].aiProofData = _proofData;
        artDetails[currentTokenId].mintTime = block.timestamp;
        artDetails[currentTokenId].aggregatedScore = 0;
        artDetails[currentTokenId].numValidEvaluations = 0;
        artDetails[currentTokenId].isProblematic = false;

        // Artisan reputation increases by 1 for successful generation
        artisanReputation[prompt.artisan]++;

        emit AIGenerationRecorded(_promptId, currentTokenId, _ipfsHash, prompt.artisan);
    }

    /// @notice Allows an Artisan to reclaim their prompt fee if AI generation failed or was cancelled.
    /// @param _promptId The ID of the prompt to refund.
    function claimFailedPromptRefund(uint256 _promptId) external whenNotPaused nonReentrant {
        if (_promptId == 0 || _promptId >= _nextPromptId) revert InvalidPromptId();

        Prompt storage prompt = prompts[_promptId];
        if (prompt.artisan != msg.sender) revert NotAuthorized();
        if (prompt.status == PromptStatus.Generated || prompt.status == PromptStatus.Refunded) revert PromptAlreadyGenerated(); // Re-using error for 'not refundable'
        if (prompt.status == PromptStatus.Submitted) revert PromptGenerationFailed(); // Still awaiting oracle to pick up

        // Only allow refund if status is 'Failed' (set by oracle)
        if (prompt.status != PromptStatus.Failed) revert PromptGenerationFailed(); // Re-using for status mismatch

        prompt.status = PromptStatus.Refunded;
        (bool success,) = msg.sender.call{value: prompt.submissionFee}("");
        require(success, "Refund failed");

        emit PromptRefunded(_promptId, msg.sender, prompt.submissionFee);
    }

    // --- III. Dynamic NFT & Metadata Management ---

    /// @notice Returns a dynamic metadata URI for a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return string The URI pointing to the metadata JSON.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert InvalidTokenId();

        ArtDetails storage art = artDetails[_tokenId];
        Prompt storage prompt = prompts[art.promptId];

        string memory scoreStr = art.numValidEvaluations > 0 ? (art.aggregatedScore / art.numValidEvaluations).toString() : "N/A";
        string memory problematicStr = art.isProblematic ? "true" : "false";

        // Construct a simple JSON directly on-chain for dynamic metadata
        // In a real scenario, this would likely point to an API endpoint
        // that fetches on-chain data and formats it for IPFS/NFT marketplaces.
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name": "NeuralCanvas AI Art #', _tokenId.toString(), '",',
                    '"description": "AI-generated art based on prompt: \\"', prompt.promptText, '\\". Aggregated score: ', scoreStr, ' (from ', art.numValidEvaluations.toString(), ' evaluations).",',
                    '"image": "ipfs://', art.ipfsHash, '",',
                    '"attributes": [',
                        '{"trait_type": "Artisan", "value": "', Strings.toHexString(uint160(prompt.artisan), 20), '"},',
                        '{"trait_type": "AI Model", "value": "', Strings.toHexString(uint256(art.aiProofData), 32), '"},', // Using part of AI proof for model display
                        '{"trait_type": "Aggregated Score", "value": ', scoreStr, '},',
                        '{"trait_type": "Evaluations Count", "value": ', art.numValidEvaluations.toString(), '},',
                        '{"trait_type": "Problematic", "value": ', problematicStr, '}',
                    ']}'
                )
            )
        ));
    }

    /// @notice Retrieves comprehensive details about a specific submitted prompt.
    /// @param _promptId The ID of the prompt.
    /// @return Prompt struct containing all details.
    function getPromptDetails(uint256 _promptId) public view returns (Prompt memory) {
        if (_promptId == 0 || _promptId >= _nextPromptId) revert InvalidPromptId();
        return prompts[_promptId];
    }

    /// @notice Retrieves detailed information about a specific minted AI art NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return ArtDetails struct containing all details.
    function getArtDetails(uint256 _tokenId) public view returns (ArtDetails memory) {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        return artDetails[_tokenId];
    }


    // --- IV. Curator Evaluation & Dispute Resolution ---

    /// @notice Curators submit an evaluation score (0-100) for an art NFT.
    /// @param _tokenId The ID of the NFT to evaluate.
    /// @param _score The evaluation score (0-100).
    /// @param _justificationIpfsHash Optional IPFS hash for a detailed justification.
    function evaluateArt(uint256 _tokenId, uint8 _score, string memory _justificationIpfsHash) external whenNotPaused nonReentrant {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        if (_score > 100) revert ScoreOutOfRange();
        if (rewardToken == address(0)) revert RewardTokenNotSet(); // Ensure reward token is configured

        ArtDetails storage art = artDetails[_tokenId];
        Prompt storage prompt = prompts[art.promptId];

        // Curators cannot evaluate their own art
        if (msg.sender == prompt.artisan) revert NotAuthorized();

        // Check if curator already evaluated this art (or their evaluation was invalidated)
        uint256 existingEvaluationId = art.curatorEvaluationIds[msg.sender];
        if (existingEvaluationId != 0 && evaluations[existingEvaluationId].isValid) {
            revert NotAuthorized(); // Already evaluated
        }

        uint256 currentEvaluationId = _nextEvaluationId++;
        evaluations[currentEvaluationId] = Evaluation({
            tokenId: _tokenId,
            curator: msg.sender,
            score: _score,
            justificationIpfsHash: _justificationIpfsHash,
            evaluationTime: block.timestamp,
            isValid: true,
            isChallenged: false,
            disputeId: 0
        });

        art.curatorEvaluationIds[msg.sender] = currentEvaluationId;
        art.aggregatedScore += _score;
        art.numValidEvaluations++;

        // Increase curator's pending rewards
        _accruedCuratorRewards[msg.sender] += evaluationRewardRate;

        emit ArtEvaluated(_tokenId, currentEvaluationId, msg.sender, _score);
    }

    /// @notice Allows any user to challenge an existing evaluation, initiating a formal dispute.
    /// @param _tokenId The ID of the NFT associated with the evaluation.
    /// @param _evaluationId The ID of the evaluation being challenged.
    /// @param _reasonIpfsHash IPFS hash for the reason/evidence for the challenge.
    function challengeEvaluation(uint256 _tokenId, uint256 _evaluationId, string memory _reasonIpfsHash) external whenNotPaused nonReentrant {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        if (_evaluationId == 0 || _evaluationId >= _nextEvaluationId) revert InvalidEvaluationId();
        if (disputeResolutionOracle == address(0)) revert OracleAddressNotSet(); // Ensure oracle is set

        Evaluation storage evaluation = evaluations[_evaluationId];
        if (evaluation.tokenId != _tokenId || !evaluation.isValid) revert InvalidEvaluationId();
        if (evaluation.isChallenged) revert EvaluationAlreadyChallenged();

        uint256 currentDisputeId = _nextDisputeId++;
        disputes[currentDisputeId] = Dispute({
            tokenId: _tokenId,
            evaluationId: _evaluationId,
            challenger: msg.sender,
            reasonIpfsHash: _reasonIpfsHash,
            challengeTime: block.timestamp,
            status: DisputeStatus.Pending,
            challengerCorrect: false
        });

        evaluation.isChallenged = true;
        evaluation.disputeId = currentDisputeId;

        emit EvaluationChallenged(currentDisputeId, _tokenId, _evaluationId, msg.sender);
    }

    /// @notice Callable only by the `disputeResolutionOracle`, this function resolves a challenge.
    /// @param _disputeId The ID of the dispute being resolved.
    /// @param _isChallengerCorrect True if the challenger's claim is valid, false otherwise.
    /// @param _resolutionProof Arbitrary proof data from the oracle.
    function resolveDispute(uint256 _disputeId, bool _isChallengerCorrect, bytes memory _resolutionProof) external whenNotPaused nonReentrant {
        if (msg.sender != disputeResolutionOracle) revert NotAuthorized();
        if (_disputeId == 0 || _disputeId >= _nextDisputeId) revert InvalidDisputeId();

        Dispute storage dispute = disputes[_disputeId];
        if (dispute.status != DisputeStatus.Pending) revert InvalidDisputeId(); // Already resolved

        Evaluation storage evaluation = evaluations[dispute.evaluationId];
        ArtDetails storage art = artDetails[dispute.tokenId];

        dispute.status = DisputeStatus.Resolved;
        dispute.challengerCorrect = _isChallengerCorrect;

        if (_isChallengerCorrect) {
            // Challenger was correct: Invalidate the original evaluation
            evaluation.isValid = false;
            // Adjust art's aggregated score and number of valid evaluations
            art.aggregatedScore -= evaluation.score;
            art.numValidEvaluations--;

            // Penalize curator who made the invalid evaluation (reduce reputation, potentially rewards)
            if (curatorReputation[evaluation.curator] > 0) {
                curatorReputation[evaluation.curator]--;
            }
            // If curator had pending rewards from this evaluation, invalidate them.
            // For simplicity, we just reduce reputation here. A more complex system might require
            // burning or reallocating specific rewards. For now, rewards are claimed from a pool.
        } else {
            // Challenger was incorrect: Potentially penalize challenger or reward curator (not implemented for simplicity)
            // Curator reputation might increase for having their evaluation upheld (optional)
        }
        // Note: _resolutionProof is stored off-chain or just used as a signal here.

        emit DisputeResolved(_disputeId, dispute.tokenId, dispute.evaluationId, _isChallengerCorrect);
    }

    /// @notice Allows an authorized role (e.g., DAO) to flag a piece of art as inappropriate or violating terms.
    /// @param _tokenId The ID of the NFT to flag.
    /// @param _reasonIpfsHash IPFS hash for the reason/justification of flagging.
    function markArtAsProblematic(uint256 _tokenId, string memory _reasonIpfsHash) external onlyOwner whenNotPaused {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        ArtDetails storage art = artDetails[_tokenId];
        if (art.isProblematic) revert ArtAlreadyProblematic();

        art.isProblematic = true;
        // Optionally, invalidate all evaluations for problematic art, and adjust reputations.
        // For simplicity, this is just a flag for now.

        emit ArtProblematicFlagged(_tokenId, msg.sender, _reasonIpfsHash);
    }

    // --- V. Reputation & Rewards ---

    /// @notice Artisans can claim their accumulated rewardTokens.
    function claimArtisanRewards() external nonReentrant {
        if (rewardToken == address(0)) revert RewardTokenNotSet();
        uint256 amount = _accruedArtisanRewards[msg.sender];
        if (amount == 0) revert NothingToClaim();

        _accruedArtisanRewards[msg.sender] = 0;
        require(rewardToken.transfer(msg.sender, amount), "Reward token transfer failed");

        emit ArtisanRewardsClaimed(msg.sender, amount);
    }

    /// @notice Curators can claim their accumulated rewardTokens.
    function claimCuratorRewards() external nonReentrant {
        if (rewardToken == address(0)) revert RewardTokenNotSet();
        uint256 amount = _accruedCuratorRewards[msg.sender];
        if (amount == 0) revert NothingToClaim();

        _accruedCuratorRewards[msg.sender] = 0;
        require(rewardToken.transfer(msg.sender, amount), "Reward token transfer failed");

        emit CuratorRewardsClaimed(msg.sender, amount);
    }

    /// @notice Retrieves the current reputation score for a given Artisan.
    /// @param _artisan The address of the Artisan.
    /// @return uint256 The Artisan's current reputation score.
    function getArtisanReputation(address _artisan) public view returns (uint256) {
        return artisanReputation[_artisan];
    }

    /// @notice Retrieves the current reputation score for a given Curator.
    /// @param _curator The address of the Curator.
    /// @return uint256 The Curator's current reputation score.
    function getCuratorReputation(address _curator) public view returns (uint256) {
        return curatorReputation[_curator];
    }

    /// @notice Returns the current amount of unclaimed rewardTokens for a specific Artisan.
    /// @param _artisan The address of the Artisan.
    /// @return uint256 The amount of unclaimed rewards.
    function getAccruedArtisanRewards(address _artisan) public view returns (uint256) {
        return _accruedArtisanRewards[_artisan];
    }

    /// @notice Returns the current amount of unclaimed rewardTokens for a specific Curator.
    /// @param _curator The address of the Curator.
    /// @return uint256 The amount of unclaimed rewards.
    function getAccruedCuratorRewards(address _curator) public view returns (uint256) {
        return _accruedCuratorRewards[_curator];
    }

    // --- Internal Overrides for ERC721Enumerable ---
    // ERC721Enumerable requires `_beforeTokenTransfer` to update token lists.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    // The following two functions are for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// Minimal Base64 encoding utility, for on-chain metadata.
// Adopted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not just the table, but also everything else in memory.
        string memory table = _TABLE;

        // compute the length of the buffer
        uint256 len = data.length;
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // allocate the buffer
        bytes memory buffer = new bytes(encodedLen);
        uint256 ptr = 0;
        uint256 idx = 0;

        // add padding
        for (; idx < len - len % 3; idx += 3) {
            buffer[ptr++] = table[uint8(data[idx] >> 2)];
            buffer[ptr++] = table[uint8((data[idx] & 0x03) << 4 | (data[idx + 1] >> 4))];
            buffer[ptr++] = table[uint8((data[idx + 1] & 0x0F) << 2 | (data[idx + 2] >> 6))];
            buffer[ptr++] = table[uint8(data[idx + 2] & 0x3F)];
        }

        if (len % 3 == 1) {
            buffer[ptr++] = table[uint8(data[idx] >> 2)];
            buffer[ptr++] = table[uint8((data[idx] & 0x03) << 4)];
            buffer[ptr++] = '=';
            buffer[ptr++] = '=';
        } else if (len % 3 == 2) {
            buffer[ptr++] = table[uint8(data[idx] >> 2)];
            buffer[ptr++] = table[uint8((data[idx] & 0x03) << 4 | (data[idx + 1] >> 4))];
            buffer[ptr++] = table[uint8((data[idx + 1] & 0x0F) << 2)];
            buffer[ptr++] = '=';
        }

        return string(buffer);
    }
}
```