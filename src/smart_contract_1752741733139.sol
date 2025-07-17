This smart contract, `AIEthos`, proposes a decentralized ecosystem for AI model co-creation, inference-as-a-service, and a reputation system. It combines concepts of dynamic NFTs, stake-based participation, decentralized governance, and a novel approach to verifiable AI inference orchestration on-chain.

**Concept: AIEthos - Decentralized AI Model Co-creation & NFT-bound Inference**

AIEthos creates a trustless environment where:
1.  **Model Contributors** stake tokens to participate in the network, providing computational resources off-chain for AI inference.
2.  The network maintains a **collective, evolving AI model**, governed by token holders who vote on proposed model upgrades.
3.  **Inference NFTs** serve as licenses, granting holders the right to request AI inferences from the decentralized network.
4.  **Inference Requests** are submitted by NFT holders, claimed by contributors, and results are submitted back on-chain.
5.  A **Reputation System** rewards honest and high-quality contributions while penalizing malicious or poor performance, ensuring the integrity of the AI service.

---

### **Outline and Function Summary**

**Contract Name:** `AIEthos`

**Purpose:** To establish a decentralized, community-governed platform for AI model development and AI inference services, leveraging NFTs as access licenses and a robust reputation system for contributors.

**Key Features:**
*   **Stake-Based Contributor System:** Participants stake an ERC-20 token to become active AI model contributors, earning rewards based on their service quality.
*   **Dynamic AI Model Governance:** A decentralized autonomous model evolution where token holders vote on proposed AI model upgrades. The active model version can change over time.
*   **NFT-Bound Inference Access:** Unique ERC-721 NFTs act as licenses, enabling their holders to request AI inferences from the network. These NFTs can have their "inference credits" topped up.
*   **Verifiable Inference Orchestration:** The contract facilitates the request, claiming, submission, and evaluation of AI inferences, with cryptographic hashes linking on-chain requests to off-chain data and computation.
*   **Reputation and Reward System:** Contributors earn fees per inference and epoch-based rewards. A dispute resolution mechanism and slashing ensure accountability and maintain network integrity.
*   **Decentralized Dispute Resolution:** A mechanism for requesters to dispute poor inference results, leading to review and potential slashing of contributors.

---

**Function Summary (20+ Unique Public Actions):**

**I. Core System & Admin Functions:**
1.  `constructor()`: Initializes the contract with an ERC-20 token address and initial parameters.
2.  `setContractParameters(uint256 _newMinStake, uint256 _newInferenceFee, uint256 _newEpochDuration, uint256 _newUnbondingPeriod, uint256 _newVotingPeriod)`: Allows the contract owner to update various system parameters.

**II. Model Contributor Management:**
3.  `registerContributor()`: Allows an address to stake tokens and become a registered AI model contributor.
4.  `deregisterContributor()`: Initiates the unbonding period for a contributor, after which they can withdraw their stake.
5.  `updateContributorHeartbeat()`: Contributors call this regularly to confirm their active status and readiness for tasks.
6.  `submitNewModelVersion(bytes32 _ipfsHashOfModelWeights)`: A registered contributor proposes a new AI model version by submitting its IPFS hash.

**III. AI Model Governance:**
7.  `voteOnModelUpgrade(uint256 _modelVersion, bool _for)`: Allows token holders to vote for or against a proposed AI model upgrade.
8.  `activateProposedModel(uint256 _modelVersion)`: Executed after a successful voting period to activate a new, community-approved AI model version.

**IV. Inference NFT (ERC-721) Management:**
9.  `mintInferenceNFT(uint256 _initialCredits)`: Mints a new `InferenceNFT` for the caller, granting initial inference credits.
10. `addInferenceCredits(uint256 _tokenId, uint256 _amount)`: Allows an NFT holder to purchase and add more inference credits to their specific NFT.

**V. Inference Request & Execution Flow:**
11. `requestInference(uint256 _tokenId, bytes32 _ipfsHashOfInput, bytes32 _ipfsHashOfExpectedOutput)`: An `InferenceNFT` holder requests an AI inference, specifying input data hash and an optional expected output hash for verification.
12. `claimInferenceRequest(uint256 _requestId)`: A registered, active contributor claims an available inference request to process off-chain.
13. `submitInferenceResult(uint256 _requestId, bytes32 _ipfsHashOfResult)`: The assigned contributor submits the IPFS hash of the computed inference result.
14. `submitInferenceEvaluation(uint256 _requestId, uint256 _score, string calldata _feedbackIpfsHash)`: The requester (or designated evaluators) provides a quality evaluation for a completed inference.
15. `disputeInferenceResult(uint256 _requestId, string calldata _reasonIpfsHash)`: Allows a requester to formally dispute an unsatisfactory inference result, triggering a review process.

**VI. Reward, Penalty, & Withdrawal Systems:**
16. `resolveInferenceDispute(uint256 _requestId)`: Callable by a governance entity (e.g., owner or DAO) to officially resolve a disputed inference, potentially leading to slashing or reward adjustment.
17. `claimContributorInferenceFee(uint256 _requestId)`: Allows a contributor to claim the direct fee for a successfully completed and evaluated inference.
18. `claimEpochRewards()`: Allows active contributors to claim their share of collective rewards accumulated during the current/past epochs based on reputation.
19. `withdrawStakedTokens()`: Allows a contributor who has completed their unbonding period to withdraw their initial staked tokens.
20. `emergencyWithdrawTokens(address _tokenAddress, address _to, uint256 _amount)`: Admin function to withdraw any accidentally sent or stuck tokens from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Error definitions for gas efficiency and clarity
error AIEthos__NotEnoughStake();
error AIEthos__ContributorAlreadyRegistered();
error AIEthos__ContributorNotRegistered();
error AIEthos__ContributorActive();
error AIEthos__UnbondingPeriodNotElapsed();
error AIEthos__NoActiveModel();
error AIEthos__InvalidNFT();
error AIEthos__NotNFTOwner();
error AIEthos__NoInferenceCredits();
error AIEthos__InferenceRequestNotFound();
error AIEthos__InvalidStatusForClaim();
error AIEthos__NotAssignedContributor();
error AIEthos__InferenceAlreadySubmitted();
error AIEthos__InferenceAlreadyEvaluated();
error AIEthos__UnauthorizedEvaluation();
error AIEthos__InferenceNotSubmitted();
error AIEthos__InferenceNotEvaluated();
error AIEthos__ModelNotFound();
error AIEthos__VotingPeriodNotEnded();
error AIEthos__VotingThresholdNotMet();
error AIEthos__ModelAlreadyActive();
error AIEthos__AlreadyVoted();
error AIEthos__SelfClaimForbidden();
error AIEthos__OnlyRequesterCanEvaluate();
error AIEthos__DisputeAlreadyExists();
error AIEthos__DisputeNotFound();
error AIEthos__IncorrectEpoch();
error AIEthos__NoRewardsToClaim();
error AIEthos__NothingToWithdraw();

contract AIEthos is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IERC20 public immutable i_stakingToken;

    // --- Configuration Parameters ---
    uint256 public minStakeAmount; // Minimum tokens required to be a contributor
    uint256 public inferenceFeePerCredit; // Cost per inference credit in staking token
    uint256 public contributorInferencePayoutRatio = 8000; // 80% payout (8000/10000) of inferenceFee to contributor, rest to rewards pool
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public unbondingPeriod; // Time in seconds before a deregistered contributor can withdraw stake
    uint256 public modelVotingPeriod; // Duration in seconds for model voting

    // --- State Variables ---
    Counters.Counter private _inferenceRequestIdCounter;
    Counters.Counter private _modelVersionCounter;
    Counters.Counter private _nftTokenIdCounter;

    uint256 public currentEpoch;
    uint256 public lastEpochUpdateTime; // Timestamp of the last epoch update or contract deployment

    uint256 public totalProtocolFeesCollected; // Accumulates fees for DAO/Protocol use
    uint256 public totalRewardsPool; // Accumulates rewards for epoch distribution

    // --- Data Structures ---

    enum InferenceStatus { Pending, Claimed, Submitted, Evaluated, Disputed, Resolved }

    struct ModelContributor {
        uint256 stakeAmount;
        uint256 reputationScore; // Based on successful inferences, quality scores. Higher is better.
        uint256 lastHeartbeat; // Timestamp of last activity check-in
        bool isActive; // True if within heartbeat window
        bool isRegistered; // True if ever registered
        uint256 unbondingStartTime; // Timestamp when deregistration started
        uint256 lastEpochClaimed; // Last epoch for which rewards were claimed
        uint256 successfulInferences;
        uint256 failedInferences;
    }

    struct AIModelMetadata {
        uint256 modelVersion; // Sequential ID for the model
        address contributor; // Who proposed this version
        bytes32 ipfsHashOfModelWeights; // Cryptographic hash of the AI model's weights/binary
        uint256 proposalTimestamp;
        uint256 votingEndTime; // When voting for this model ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive; // True if this is the currently active model for inferences
        bool isProposed; // True if it's awaiting vote/activation
        bool passedVote; // True if it passed the vote
    }

    struct InferenceRequest {
        uint256 requestId;
        address requester;
        uint256 modelUsedVersion; // Which model version was intended for this inference
        bytes32 ipfsHashOfInput; // Hash of input data for inference
        bytes32 ipfsHashOfExpectedOutput; // Optional: If a reference output is known for testing
        bytes32 ipfsHashOfResult; // Hash of the actual output from contributor
        address assignedContributor;
        InferenceStatus status;
        uint256 requestTimestamp;
        uint256 submissionTimestamp;
        uint256 evaluationTimestamp;
        uint256 feePaid; // Fee paid by the requester for this specific inference
        uint256 evaluationScore; // Score given by evaluator
        string evaluationFeedbackIpfsHash;
        string disputeReasonIpfsHash;
    }

    struct InferenceNFT {
        uint256 tokenId;
        uint256 activeModelVersionAllowed; // What model version this NFT can use (e.g., current active)
        uint256 inferenceCredits; // Number of inferences allowed
    }

    // --- Mappings ---
    mapping(address => ModelContributor) public contributors;
    mapping(uint256 => AIModelMetadata) public modelVersions; // modelVersionId => AIModelMetadata
    mapping(uint256 => mapping(address => bool)) public hasVotedOnModel; // modelVersionId => voterAddress => voted
    mapping(uint256 => InferenceRequest) public inferenceRequests; // requestId => InferenceRequest
    mapping(uint256 => InferenceNFT) public inferenceNFTs; // tokenId => InferenceNFT (ERC721 built-in mapping)

    uint256 public activeModelVersion; // Currently active model version ID

    // --- Events ---
    event ParametersUpdated(uint256 minStake, uint256 inferenceFee, uint256 epochDuration, uint256 unbondingPeriod, uint256 votingPeriod);
    event ContributorRegistered(address indexed contributor, uint256 stakeAmount);
    event ContributorDeregistered(address indexed contributor, uint256 unbondingStartTime);
    event ContributorHeartbeat(address indexed contributor, uint256 timestamp);
    event ModelVersionProposed(uint256 indexed modelVersion, address indexed proposer, bytes32 ipfsHash);
    event ModelVoteCast(uint256 indexed modelVersion, address indexed voter, bool _for);
    event ModelVersionActivated(uint256 indexed modelVersion);
    event InferenceNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialCredits);
    event InferenceCreditsAdded(uint256 indexed tokenId, uint256 amount);
    event InferenceRequested(uint256 indexed requestId, uint256 indexed tokenId, address indexed requester, bytes32 ipfsHashInput);
    event InferenceClaimed(uint256 indexed requestId, address indexed contributor);
    event InferenceResultSubmitted(uint256 indexed requestId, address indexed contributor, bytes32 ipfsHashResult);
    event InferenceEvaluated(uint256 indexed requestId, address indexed evaluator, uint256 score);
    event InferenceDisputed(uint256 indexed requestId, address indexed disputer, string reasonIpfsHash);
    event InferenceDisputeResolved(uint256 indexed requestId, address indexed resolver, bool contributorSlashing);
    event ContributorInferenceFeeClaimed(uint256 indexed requestId, address indexed contributor, uint256 amount);
    event ContributorEpochRewardsClaimed(address indexed contributor, uint256 epoch, uint256 amount);
    event StakedTokensWithdrawn(address indexed contributor, uint256 amount);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);

    constructor(address _stakingTokenAddress) ERC721("AIEthosInferenceNFT", "AEI") Ownable(msg.sender) {
        require(_stakingTokenAddress != address(0), "AIEthos: Invalid token address");
        i_stakingToken = IERC20(_stakingTokenAddress);

        // Initial default parameters (can be updated by owner)
        minStakeAmount = 1000 * (10 ** 18); // Example: 1000 tokens
        inferenceFeePerCredit = 10 * (10 ** 18); // Example: 10 tokens per inference
        epochDuration = 7 days; // Example: 7 days
        unbondingPeriod = 14 days; // Example: 14 days
        modelVotingPeriod = 5 days; // Example: 5 days
        lastEpochUpdateTime = block.timestamp;
    }

    modifier onlyRegisteredContributor() {
        if (!contributors[msg.sender].isRegistered) revert AIEthos__ContributorNotRegistered();
        _;
    }

    modifier onlyActiveContributor() {
        if (!contributors[msg.sender].isActive) revert AIEthos__ContributorNotRegistered(); // Also implies not registered
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert AIEthos__NotNFTOwner();
        _;
    }

    // --- I. Core System & Admin Functions ---

    /**
     * @notice Allows the contract owner to update various system parameters.
     * @param _newMinStake New minimum stake amount for contributors.
     * @param _newInferenceFee New fee charged per inference credit.
     * @param _newEpochDuration New duration for an epoch in seconds.
     * @param _newUnbondingPeriod New unbonding period for deregistering contributors.
     * @param _newVotingPeriod New duration for model voting.
     */
    function setContractParameters(
        uint256 _newMinStake,
        uint256 _newInferenceFee,
        uint256 _newEpochDuration,
        uint256 _newUnbondingPeriod,
        uint256 _newVotingPeriod
    ) external onlyOwner {
        minStakeAmount = _newMinStake;
        inferenceFeePerCredit = _newInferenceFee;
        epochDuration = _newEpochDuration;
        unbondingPeriod = _newUnbondingPeriod;
        modelVotingPeriod = _newVotingPeriod;
        emit ParametersUpdated(_newMinStake, _newInferenceFee, _newEpochDuration, _newUnbondingPeriod, _newVotingPeriod);
    }

    // --- II. Model Contributor Management ---

    /**
     * @notice Allows an address to stake tokens and become a registered AI model contributor.
     * @dev Requires caller to have approved `minStakeAmount` tokens to this contract.
     */
    function registerContributor() external nonReentrant {
        if (contributors[msg.sender].isRegistered) revert AIEthos__ContributorAlreadyRegistered();
        if (i_stakingToken.balanceOf(msg.sender) < minStakeAmount) revert AIEthos__NotEnoughStake();
        
        i_stakingToken.transferFrom(msg.sender, address(this), minStakeAmount);

        contributors[msg.sender] = ModelContributor({
            stakeAmount: minStakeAmount,
            reputationScore: 0, // Initial reputation
            lastHeartbeat: block.timestamp,
            isActive: true,
            isRegistered: true,
            unbondingStartTime: 0,
            lastEpochClaimed: currentEpoch, // Can claim rewards from next epoch
            successfulInferences: 0,
            failedInferences: 0
        });

        emit ContributorRegistered(msg.sender, minStakeAmount);
    }

    /**
     * @notice Initiates the unbonding period for a contributor, after which they can withdraw their stake.
     * @dev Contributor cannot have active claims or pending submissions.
     */
    function deregisterContributor() external nonReentrant onlyRegisteredContributor {
        ModelContributor storage contributor = contributors[msg.sender];
        if (contributor.unbondingStartTime != 0) revert AIEthos__ContributorActive(); // Already deregistering
        // Add check if contributor has any outstanding claims/submissions before allowing deregistration. (Complex, omitted for brevity)

        contributor.isActive = false;
        contributor.unbondingStartTime = block.timestamp;

        emit ContributorDeregistered(msg.sender, block.timestamp);
    }

    /**
     * @notice Contributors call this regularly to confirm their active status and readiness for tasks.
     * @dev Keeps the contributor `isActive` and ensures eligibility for rewards.
     */
    function updateContributorHeartbeat() external onlyRegisteredContributor {
        ModelContributor storage contributor = contributors[msg.sender];
        if (contributor.unbondingStartTime != 0) revert AIEthos__ContributorActive(); // Cannot heartbeat if unbonding
        
        contributor.lastHeartbeat = block.timestamp;
        contributor.isActive = true; // Mark as active (for a predefined period)
        emit ContributorHeartbeat(msg.sender, block.timestamp);
    }

    /**
     * @notice A registered contributor proposes a new AI model version by submitting its IPFS hash.
     * @param _ipfsHashOfModelWeights Cryptographic hash of the AI model's weights/binary.
     * @dev This initiates a voting process for the new model.
     */
    function submitNewModelVersion(bytes32 _ipfsHashOfModelWeights) external onlyRegisteredContributor {
        _modelVersionCounter.increment();
        uint256 newVersion = _modelVersionCounter.current();

        modelVersions[newVersion] = AIModelMetadata({
            modelVersion: newVersion,
            contributor: msg.sender,
            ipfsHashOfModelWeights: _ipfsHashOfModelWeights,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + modelVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            isActive: false,
            isProposed: true,
            passedVote: false
        });

        emit ModelVersionProposed(newVersion, msg.sender, _ipfsHashOfModelWeights);
    }

    // --- III. AI Model Governance ---

    /**
     * @notice Allows token holders to vote for or against a proposed AI model upgrade.
     * @dev Voting power could be based on token balance or another reputation system (simplified here to 1 vote per address).
     * @param _modelVersion The ID of the model version being voted on.
     * @param _for True to vote for the model, false to vote against.
     */
    function voteOnModelUpgrade(uint256 _modelVersion, bool _for) external {
        AIModelMetadata storage model = modelVersions[_modelVersion];
        if (!model.isProposed) revert AIEthos__ModelNotFound();
        if (block.timestamp >= model.votingEndTime) revert AIEthos__VotingPeriodNotEnded();
        if (hasVotedOnModel[_modelVersion][msg.sender]) revert AIEthos__AlreadyVoted();

        if (_for) {
            model.votesFor++;
        } else {
            model.votesAgainst++;
        }
        hasVotedOnModel[_modelVersion][msg.sender] = true;

        emit ModelVoteCast(_modelVersion, msg.sender, _for);
    }

    /**
     * @notice Executed after a successful voting period to activate a new, community-approved AI model version.
     * @dev Requires the voting period to have ended and a positive vote outcome (e.g., votesFor > votesAgainst).
     * @param _modelVersion The ID of the model version to activate.
     */
    function activateProposedModel(uint256 _modelVersion) external nonReentrant {
        AIModelMetadata storage model = modelVersions[_modelVersion];
        if (!model.isProposed) revert AIEthos__ModelNotFound();
        if (block.timestamp < model.votingEndTime) revert AIEthos__VotingPeriodNotEnded();
        if (model.isActive) revert AIEthos__ModelAlreadyActive();

        // Simple majority vote for now. Could be more complex (e.g., quorum, token-weighted).
        if (model.votesFor <= model.votesAgainst) revert AIEthos__VotingThresholdNotMet();

        // Deactivate previous active model, if any
        if (activeModelVersion != 0) {
            modelVersions[activeModelVersion].isActive = false;
        }

        model.isActive = true;
        model.passedVote = true;
        activeModelVersion = _modelVersion;

        emit ModelVersionActivated(_modelVersion);
    }

    // --- IV. Inference NFT (ERC-721) Management ---

    /**
     * @notice Mints a new InferenceNFT for the caller, granting initial inference credits.
     * @param _initialCredits The number of inference credits to assign to the new NFT.
     * @dev Mints an ERC721 token and associates it with inference credits.
     */
    function mintInferenceNFT(uint256 _initialCredits) external nonReentrant {
        if (activeModelVersion == 0) revert AIEthos__NoActiveModel();
        
        _nftTokenIdCounter.increment();
        uint256 newItemId = _nftTokenIdCounter.current();
        _mint(msg.sender, newItemId);

        inferenceNFTs[newItemId] = InferenceNFT({
            tokenId: newItemId,
            activeModelVersionAllowed: activeModelVersion, // NFT tied to current active model
            inferenceCredits: _initialCredits
        });

        emit InferenceNFTMinted(newItemId, msg.sender, _initialCredits);
    }

    /**
     * @notice Allows an NFT holder to purchase and add more inference credits to their specific NFT.
     * @dev Requires caller to be the NFT owner and approve tokens to the contract.
     * @param _tokenId The ID of the InferenceNFT.
     * @param _amount The number of additional inference credits to add.
     */
    function addInferenceCredits(uint256 _tokenId, uint256 _amount) external nonReentrant onlyNFTOwner(_tokenId) {
        InferenceNFT storage nft = inferenceNFTs[_tokenId];
        uint256 cost = _amount * inferenceFeePerCredit;

        i_stakingToken.transferFrom(msg.sender, address(this), cost);
        nft.inferenceCredits += _amount;
        totalProtocolFeesCollected += (cost * (10000 - contributorInferencePayoutRatio)) / 10000;
        totalRewardsPool += (cost * contributorInferencePayoutRatio) / 10000;


        emit InferenceCreditsAdded(_tokenId, _amount);
    }

    // --- V. Inference Request & Execution Flow ---

    /**
     * @notice An InferenceNFT holder requests an AI inference, specifying input data hash and an optional expected output hash for verification.
     * @param _tokenId The ID of the InferenceNFT to use.
     * @param _ipfsHashOfInput The IPFS hash of the input data for the AI model.
     * @param _ipfsHashOfExpectedOutput Optional: IPFS hash of an expected output for comparison/testing.
     */
    function requestInference(
        uint256 _tokenId,
        bytes32 _ipfsHashOfInput,
        bytes32 _ipfsHashOfExpectedOutput
    ) external nonReentrant onlyNFTOwner(_tokenId) {
        InferenceNFT storage nft = inferenceNFTs[_tokenId];
        if (nft.inferenceCredits == 0) revert AIEthos__NoInferenceCredits();
        if (activeModelVersion == 0) revert AIEthos__NoActiveModel();

        nft.inferenceCredits--;
        _inferenceRequestIdCounter.increment();
        uint256 newRequestId = _inferenceRequestIdCounter.current();

        inferenceRequests[newRequestId] = InferenceRequest({
            requestId: newRequestId,
            requester: msg.sender,
            modelUsedVersion: activeModelVersion,
            ipfsHashOfInput: _ipfsHashOfInput,
            ipfsHashOfExpectedOutput: _ipfsHashOfExpectedOutput,
            ipfsHashOfResult: 0,
            assignedContributor: address(0),
            status: InferenceStatus.Pending,
            requestTimestamp: block.timestamp,
            submissionTimestamp: 0,
            evaluationTimestamp: 0,
            feePaid: inferenceFeePerCredit,
            evaluationScore: 0,
            evaluationFeedbackIpfsHash: "",
            disputeReasonIpfsHash: ""
        });

        emit InferenceRequested(newRequestId, _tokenId, msg.sender, _ipfsHashOfInput);
    }

    /**
     * @notice A registered, active contributor claims an available inference request to process off-chain.
     * @param _requestId The ID of the inference request to claim.
     */
    function claimInferenceRequest(uint256 _requestId) external nonReentrant onlyActiveContributor {
        InferenceRequest storage req = inferenceRequests[_requestId];
        if (req.requestId == 0) revert AIEthos__InferenceRequestNotFound();
        if (req.status != InferenceStatus.Pending) revert AIEthos__InvalidStatusForClaim();
        if (req.requester == msg.sender) revert AIEthos__SelfClaimForbidden(); // Prevent requester from claiming their own request

        req.assignedContributor = msg.sender;
        req.status = InferenceStatus.Claimed;

        emit InferenceClaimed(_requestId, msg.sender);
    }

    /**
     * @notice The assigned contributor submits the IPFS hash of the computed inference result.
     * @param _requestId The ID of the inference request.
     * @param _ipfsHashOfResult The IPFS hash of the AI inference output.
     */
    function submitInferenceResult(uint256 _requestId, bytes32 _ipfsHashOfResult) external nonReentrant onlyActiveContributor {
        InferenceRequest storage req = inferenceRequests[_requestId];
        if (req.requestId == 0) revert AIEthos__InferenceRequestNotFound();
        if (req.assignedContributor != msg.sender) revert AIEthos__NotAssignedContributor();
        if (req.status != InferenceStatus.Claimed) revert AIEthos__InferenceAlreadySubmitted(); // Or wrong status

        req.ipfsHashOfResult = _ipfsHashOfResult;
        req.submissionTimestamp = block.timestamp;
        req.status = InferenceStatus.Submitted;

        emit InferenceResultSubmitted(_requestId, msg.sender, _ipfsHashOfResult);
    }

    /**
     * @notice The requester (or designated evaluators) provides a quality evaluation for a completed inference.
     * @param _requestId The ID of the inference request.
     * @param _score The evaluation score (e.g., 0-100).
     * @param _feedbackIpfsHash Optional IPFS hash of detailed feedback.
     */
    function submitInferenceEvaluation(uint256 _requestId, uint256 _score, string calldata _feedbackIpfsHash) external nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        if (req.requestId == 0) revert AIEthos__InferenceRequestNotFound();
        if (req.status != InferenceStatus.Submitted) revert AIEthos__InferenceNotSubmitted();
        if (req.requester != msg.sender) revert AIEthos__OnlyRequesterCanEvaluate(); // Only requester can evaluate for now. Could be extended.

        req.evaluationScore = _score;
        req.evaluationFeedbackIpfsHash = _feedbackIpfsHash;
        req.evaluationTimestamp = block.timestamp;
        req.status = InferenceStatus.Evaluated;

        // Update contributor reputation (simplified)
        ModelContributor storage contributor = contributors[req.assignedContributor];
        if (_score >= 70) { // Example: Good score
            contributor.reputationScore += 10;
            contributor.successfulInferences++;
        } else { // Example: Poor score
            contributor.reputationScore = contributor.reputationScore > 5 ? contributor.reputationScore - 5 : 0;
            contributor.failedInferences++;
        }

        emit InferenceEvaluated(_requestId, msg.sender, _score);
    }

    /**
     * @notice Allows a requester to formally dispute an unsatisfactory inference result, triggering a review process.
     * @param _requestId The ID of the inference request to dispute.
     * @param _reasonIpfsHash IPFS hash of the detailed reason for the dispute.
     */
    function disputeInferenceResult(uint256 _requestId, string calldata _reasonIpfsHash) external nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        if (req.requestId == 0) revert AIEthos__InferenceRequestNotFound();
        if (req.requester != msg.sender) revert AIEthos__UnauthorizedEvaluation(); // Only requester can dispute
        if (req.status != InferenceStatus.Evaluated) revert AIEthos__InferenceNotEvaluated();
        if (bytes(req.disputeReasonIpfsHash).length > 0) revert AIEthos__DisputeAlreadyExists(); // Already disputed

        req.disputeReasonIpfsHash = _reasonIpfsHash;
        req.status = InferenceStatus.Disputed;

        emit InferenceDisputed(_requestId, msg.sender, _reasonIpfsHash);
    }

    // --- VI. Reward, Penalty, & Withdrawal Systems ---

    /**
     * @notice Callable by a governance entity (e.g., owner or DAO) to officially resolve a disputed inference.
     * @dev Based on review (off-chain), this function updates contributor reputation and potentially slashes stake.
     * @param _requestId The ID of the disputed inference request.
     */
    function resolveInferenceDispute(uint256 _requestId) external nonReentrant onlyOwner {
        InferenceRequest storage req = inferenceRequests[_requestId];
        if (req.requestId == 0) revert AIEthos__InferenceRequestNotFound();
        if (req.status != InferenceStatus.Disputed) revert AIEthos__DisputeNotFound();

        ModelContributor storage contributor = contributors[req.assignedContributor];

        // This is a placeholder for actual dispute resolution logic.
        // In a real system, this would involve a DAO vote, or expert review.
        // For demonstration, let's say the owner decides if contributor was malicious.
        bool contributorWasMalicious = false; // This decision comes from off-chain governance/review
        if (req.evaluationScore < 50) { // Example: If score was very low, assume malicious
            contributorWasMalicious = true;
        }

        if (contributorWasMalicious) {
            uint256 slashAmount = contributor.stakeAmount / 10; // Example: Slash 10% of stake
            if (slashAmount > 0) {
                contributor.stakeAmount -= slashAmount;
                // Tokens are slashed, maybe burned or sent to a treasury
                // For this example, they remain in the contract but are effectively locked from contributor
            }
            contributor.reputationScore = contributor.reputationScore > 50 ? contributor.reputationScore - 50 : 0; // Significant reputation loss
            contributor.failedInferences++;
        } else {
            // Contributor was not malicious, maybe requester was unfair, or just a bad task.
            // Adjust reputation or re-evaluate. For now, no action.
        }

        req.status = InferenceStatus.Resolved;
        emit InferenceDisputeResolved(_requestId, msg.sender, contributorWasMalicious);
    }

    /**
     * @notice Allows a contributor to claim the direct fee for a successfully completed and evaluated inference.
     * @param _requestId The ID of the inference request.
     */
    function claimContributorInferenceFee(uint256 _requestId) external nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        if (req.requestId == 0) revert AIEthos__InferenceRequestNotFound();
        if (req.assignedContributor != msg.sender) revert AIEthos__NotAssignedContributor();
        if (req.status != InferenceStatus.Evaluated && req.status != InferenceStatus.Resolved) revert AIEthos__InferenceNotEvaluated(); // Must be evaluated or resolved

        // Prevent double claiming
        if (req.feePaid == 0) return; // Already claimed or no fee

        uint256 payoutAmount = (req.feePaid * contributorInferencePayoutRatio) / 10000;
        uint256 protocolShare = req.feePaid - payoutAmount;

        i_stakingToken.transfer(msg.sender, payoutAmount);
        // The protocolShare already accumulates in totalProtocolFeesCollected/totalRewardsPool when addInferenceCredits is called.
        // So, no further transfer out of 'req.feePaid' is needed here, just the payout to contributor.
        req.feePaid = 0; // Mark as claimed

        emit ContributorInferenceFeeClaimed(_requestId, msg.sender, payoutAmount);
    }

    /**
     * @notice Allows active contributors to claim their share of collective rewards accumulated during the current/past epochs based on reputation.
     * @dev Rewards are distributed based on reputation score relative to total reputation in the epoch.
     */
    function claimEpochRewards() external nonReentrant onlyRegisteredContributor {
        ModelContributor storage contributor = contributors[msg.sender];
        if (contributor.unbondingStartTime != 0) revert AIEthos__ContributorActive(); // Cannot claim if unbonding

        // Update epoch if necessary
        _updateEpoch();

        // No rewards to claim for current epoch yet if it just started
        if (contributor.lastEpochClaimed >= currentEpoch) revert AIEthos__NoRewardsToClaim();

        uint256 totalActiveReputation = _getTotalActiveReputation();
        if (totalActiveReputation == 0) revert AIEthos__NoRewardsToClaim(); // No active contributors with reputation

        uint256 rewardsToDistributeThisEpoch = totalRewardsPool; // Simplification: all pooled rewards are distributed
        if (rewardsToDistributeThisEpoch == 0) revert AIEthos__NoRewardsToClaim();

        uint256 share = (contributor.reputationScore * rewardsToDistributeThisEpoch) / totalActiveReputation;
        
        if (share == 0) revert AIEthos__NoRewardsToClaim(); // No meaningful share

        // Transfer share to contributor
        i_stakingToken.transfer(msg.sender, share);
        totalRewardsPool -= share; // Deduct from the pool

        contributor.lastEpochClaimed = currentEpoch; // Mark rewards for this epoch as claimed
        emit ContributorEpochRewardsClaimed(msg.sender, currentEpoch, share);
    }

    /**
     * @notice Allows a contributor who has completed their unbonding period to withdraw their initial staked tokens.
     */
    function withdrawStakedTokens() external nonReentrant {
        ModelContributor storage contributor = contributors[msg.sender];
        if (!contributor.isRegistered || contributor.unbondingStartTime == 0) revert AIEthos__ContributorNotRegistered();
        if (block.timestamp < contributor.unbondingStartTime + unbondingPeriod) revert AIEthos__UnbondingPeriodNotElapsed();
        if (contributor.stakeAmount == 0) revert AIEthos__NothingToWithdraw();

        uint256 amount = contributor.stakeAmount;
        contributor.stakeAmount = 0;
        contributor.isRegistered = false; // Full deregistration
        contributor.isActive = false;

        i_stakingToken.transfer(msg.sender, amount);
        emit StakedTokensWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Admin function to withdraw any accidentally sent or stuck tokens from the contract.
     * @param _tokenAddress The address of the token to withdraw (use address(0) for native ETH, though this contract won't hold ETH directly).
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawTokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) {
            // In case ETH is sent, but this contract primarily deals with ERC20
            // payable(_to).transfer(_amount); // Not applicable for this contract as it's ERC20 based
        } else {
            IERC20(_tokenAddress).transfer(_to, _amount);
        }
        emit EmergencyWithdrawal(_tokenAddress, _to, _amount);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to update the current epoch if epochDuration has passed.
     */
    function _updateEpoch() internal {
        uint256 elapsed = block.timestamp - lastEpochUpdateTime;
        if (elapsed >= epochDuration) {
            uint256 epochsPassed = elapsed / epochDuration;
            currentEpoch += epochsPassed;
            lastEpochUpdateTime += epochsPassed * epochDuration;
            // Potentially distribute pending rewards or adjust state for new epoch
        }
    }

    /**
     * @dev Calculates the total reputation score of all currently active contributors.
     * @return totalReputation The sum of reputation scores of all active contributors.
     * @notice This iterates over all known contributors. For a very large number of contributors,
     *         this could become gas-expensive. A more scalable solution would involve
     *         a reputation accumulator updated incrementally or a Merkle tree approach.
     */
    function _getTotalActiveReputation() internal view returns (uint256 totalReputation) {
        // This is a naive implementation and would be very gas-expensive for many contributors.
        // In a production system, this would need a more sophisticated, gas-efficient way
        // to aggregate reputation (e.g., using a Merkle tree or an on-chain accumulator updated by keepers).
        // For the sake of this example and demonstrating the concept, we'll keep it simple.
        // It iterates over a subset of addresses (e.g. all who ever registered).
        // A robust solution might have a separate mapping of "active contributors by epoch".
        
        // This function would typically require iterating through active contributors.
        // Since we don't have an iterable mapping, this is a placeholder.
        // A production-ready contract would use an array of active contributors or a linked list.
        // For now, let's assume a simplified total for demonstration.
        // In a real scenario, this would likely be calculated off-chain by a keeper
        // and submitted on-chain or derived from a reputation-weighted pool.
        
        // Example placeholder: Summing all registered contributors' reputation
        // This would require iterating over all keys in the `contributors` map, which is impossible directly.
        // A proper solution would require a list or dynamic array of registered contributors.
        // For now, assume a pre-calculated or approximate value.
        // Let's return a dummy value or make it dependent on some known state.
        
        // As a conceptual example, if we had a dynamic array `address[] public activeContributorAddresses;`
        // we could do:
        // for (uint i = 0; i < activeContributorAddresses.length; i++) {
        //     address addr = activeContributorAddresses[i];
        //     if (contributors[addr].isActive && contributors[addr].stakeAmount >= minStakeAmount) {
        //         totalReputation += contributors[addr].reputationScore;
        //     }
        // }
        // For this contract, let's just return a placeholder, or assume a maximum for simplicity.
        return 1000; // Placeholder: In a real contract, compute sum of active contributor reputations.
    }

    // --- Query Functions (Views) ---

    function getContributorInfo(address _contributor) public view returns (
        uint256 stakeAmount,
        uint256 reputationScore,
        uint256 lastHeartbeat,
        bool isActive,
        bool isRegistered,
        uint256 unbondingStartTime,
        uint256 lastEpochClaimed,
        uint256 successfulInferences,
        uint256 failedInferences
    ) {
        ModelContributor storage c = contributors[_contributor];
        return (c.stakeAmount, c.reputationScore, c.lastHeartbeat, c.isActive, c.isRegistered, c.unbondingStartTime, c.lastEpochClaimed, c.successfulInferences, c.failedInferences);
    }

    function getModelMetadata(uint256 _modelVersion) public view returns (
        uint256 modelVersion,
        address contributor,
        bytes32 ipfsHashOfModelWeights,
        uint256 proposalTimestamp,
        uint256 votingEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        bool isActive,
        bool isProposed,
        bool passedVote
    ) {
        AIModelMetadata storage m = modelVersions[_modelVersion];
        return (m.modelVersion, m.contributor, m.ipfsHashOfModelWeights, m.proposalTimestamp, m.votingEndTime, m.votesFor, m.votesAgainst, m.isActive, m.isProposed, m.passedVote);
    }

    function getInferenceRequestStatus(uint256 _requestId) public view returns (
        uint256 requestId,
        address requester,
        uint256 modelUsedVersion,
        bytes32 ipfsHashOfInput,
        bytes32 ipfsHashOfResult,
        address assignedContributor,
        InferenceStatus status,
        uint256 feePaid,
        uint256 evaluationScore
    ) {
        InferenceRequest storage r = inferenceRequests[_requestId];
        return (r.requestId, r.requester, r.modelUsedVersion, r.ipfsHashOfInput, r.ipfsHashOfResult, r.assignedContributor, r.status, r.feePaid, r.evaluationScore);
    }

    function getNFTDetails(uint256 _tokenId) public view returns (
        uint256 tokenId,
        uint256 activeModelVersionAllowed,
        uint256 inferenceCredits
    ) {
        InferenceNFT storage n = inferenceNFTs[_tokenId];
        return (n.tokenId, n.activeModelVersionAllowed, n.inferenceCredits);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch + (block.timestamp - lastEpochUpdateTime) / epochDuration;
    }
}
```