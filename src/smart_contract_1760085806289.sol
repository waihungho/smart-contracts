Here's a smart contract in Solidity called `AetherMindForge` that implements a decentralized AI model marketplace and evaluation system. It focuses on trustless model validation, fractional ownership of models, and on-chain inference request routing, all while aiming for creative, advanced concepts.

This contract uses OpenZeppelin's `AccessControl` for role management and `Pausable` for emergency control.

---

### Contract: `AetherMindForge`

**Outline:**

*   **I. Core Model Management & Tokenization:** Functions for registering AI models, minting, and managing fractional ownership shares (inspired by ERC-1155 principles).
*   **II. Inference Service Management:** Handles the lifecycle of AI model inference requests, from user payment to oracle result submission and model owner revenue claiming.
*   **III. Trustless Model Evaluation & Reputation:** Implements a sophisticated mechanism for users to stake tokens, evaluate model performance, submit reports, and challenge dubious evaluations, impacting the model's reputation.
*   **IV. Economic & Fee Mechanisms:** Manages protocol-level fees and their distribution.
*   **V. Governance & Administrative:** Includes Role-Based Access Control, Pausability for critical operations, and an emergency function for stuck tokens.
*   **VI. Utility & Querying:** Provides various view functions to retrieve detailed information about models, inference requests, and evaluation rounds.

**Function Summary (24 Functions):**

1.  `constructor()`: Initializes the contract, granting the deployer `DEFAULT_ADMIN_ROLE`, `INFERENCE_ORACLE_ROLE`, and `EVALUATION_ORACLE_ROLE`. Sets an initial protocol fee rate and recipient.
2.  `registerModel(string _name, string _description, string _ipfsHash, uint256 _inferencePricePerUnit, uint256 _totalShares)`: Registers a new AI model with its metadata, price, and total fractional shares. The shares are initially minted to the model owner.
3.  `mintModelShares(uint256 _modelId, address[] calldata _recipients, uint256[] calldata _amounts)`: Distributes existing fractional ownership shares from the model owner to multiple recipients.
4.  `safeTransferFromModelShares(uint256 _modelId, address _from, address _to, uint256 _amount)`: Transfers fractional shares of a specific model between addresses. (Simplified ERC-1155 `safeTransferFrom` equivalent).
5.  `setInferencePrice(uint256 _modelId, uint256 _newPricePerUnit)`: Allows the model owner to update the price for one unit of inference for their model.
6.  `requestInference(uint256 _modelId, string calldata _inputDataHash, uint256 _numUnits, address _paymentToken)`: A user requests `_numUnits` of inference from a model, paying with a specified ERC20 token. The payment is transferred to the contract, and a pending request is created.
7.  `submitInferenceResult(uint256 _requestId, string calldata _outputDataHash, string calldata _proof)`: An authorized `INFERENCE_ORACLE_ROLE` member submits the inference result and a cryptographic proof for a pending request.
8.  `claimInferenceRevenue(uint256 _modelId, address _tokenAddress)`: The model owner claims their accumulated revenue (net of protocol fees) from completed inferences in a specific ERC20 token.
9.  `stakeForEvaluation(uint256 _modelId, string calldata _testDatasetHash, uint256 _stakeAmount, address _stakeToken)`: A user stakes tokens to initiate or participate in an evaluation round for a model, providing a hash of the test dataset to be used.
10. `submitEvaluationReport(uint256 _evaluationId, uint256 _score, string calldata _reportHash)`: An evaluator (who has staked) submits their performance report (e.g., accuracy score) and a hash pointing to the detailed report for a specific evaluation round.
11. `challengeEvaluationReport(uint256 _evaluationId, uint256 _reportIndex, string calldata _reasonHash, uint256 _challengeStake)`: A user challenges an existing evaluation report, providing a reason and staking tokens, initiating a dispute resolution process.
12. `resolveEvaluationChallenge(uint256 _challengeId, bool _challengerWins, uint256 _modelId, int256 _reputationDelta)`: An authorized `EVALUATION_ORACLE_ROLE` member resolves a challenge. Stakes are distributed/slashed based on the outcome, and the model's reputation is adjusted.
13. `claimEvaluationReward(uint256 _evaluationId)`: An evaluator claims their initial stake back plus any rewards if their submitted report was accepted and not successfully challenged.
14. `_updateModelReputation(uint256 _modelId, int256 _reputationDelta)`: An internal helper function to adjust a model's reputation score.
15. `setProtocolFeeRate(uint256 _newFeeRate)`: Allows the `DEFAULT_ADMIN_ROLE` to update the percentage fee collected by the protocol (in basis points).
16. `distributeProtocolFees(address _tokenAddress)`: Allows the `DEFAULT_ADMIN_ROLE` to transfer accumulated protocol fees for a specific token to the designated `protocolFeeRecipient`.
17. `pause()`: Pauses core contract functionalities, preventing state changes (callable by `DEFAULT_ADMIN_ROLE`).
18. `unpause()`: Unpauses the contract (callable by `DEFAULT_ADMIN_ROLE`).
19. `grantRole(bytes32 role, address account)`: Grants a specified role to an account (callable by `DEFAULT_ADMIN_ROLE`).
20. `revokeRole(bytes32 role, address account)`: Revokes a specified role from an account (callable by `DEFAULT_ADMIN_ROLE`).
21. `withdrawStuckTokens(address _tokenAddress, uint256 _amount)`: Allows the `DEFAULT_ADMIN_ROLE` to withdraw any accidentally sent or stuck ERC20 tokens from the contract.
22. `getModelDetails(uint256 _modelId)`: A view function to retrieve comprehensive details about a registered AI model.
23. `getPendingInferenceRequest(uint256 _requestId)`: A view function to get details about a specific inference request.
24. `getEvaluationDetails(uint256 _evaluationId)`: A view function to retrieve summary details about an evaluation round.
25. `getModelShareBalance(uint256 _modelId, address _account)`: A view function to check an account's balance of fractional shares for a given model.
26. `getProtocolFeeRate()`: A view function to get the current protocol fee rate.
27. `getProtocolFeeBalance(address _tokenAddress)`: A view function to get the current protocol fee balance for a specific token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // For conceptual reference for shares, not fully implemented to avoid duplication

// Outline:
// I. Core Model Management & Tokenization: Registering AI models, minting and managing fractional ownership shares.
// II. Inference Service Management: Requesting and fulfilling AI model inferences, handling payments.
// III. Trustless Model Evaluation & Reputation: Mechanism for users to evaluate model performance, stake tokens, and dispute reports.
// IV. Economic & Fee Mechanisms: Protocol fees, reward distribution for evaluators.
// V. Governance & Administrative: Role-Based Access Control, Pausability, Emergency functions.
// VI. Utility & Querying: Functions to retrieve detailed information about models, requests, and evaluations.

// Function Summary:
// 1.  constructor(): Initializes contract owner, sets up roles for oracles and administrators.
// 2.  registerModel(string _name, string _description, string _ipfsHash, uint256 _inferencePricePerUnit, uint256 _totalShares): Registers a new AI model, assigning it a unique ID and defining its initial parameters.
// 3.  mintModelShares(uint256 _modelId, address[] calldata _recipients, uint256[] calldata _amounts): Distributes fractional ownership shares of a specific model from the owner to multiple recipients.
// 4.  safeTransferFromModelShares(uint256 _modelId, address _from, address _to, uint256 _amount): Transfers fractional shares of a model from one address to another.
// 5.  setInferencePrice(uint256 _modelId, uint256 _newPricePerUnit): Model owner updates the price per unit of inference for their model.
// 6.  requestInference(uint256 _modelId, string calldata _inputDataHash, uint256 _numUnits, address _paymentToken): User requests a specific number of inference units for a model, paying with a specified ERC20 token.
// 7.  submitInferenceResult(uint256 _requestId, string calldata _outputDataHash, string calldata _proof): An authorized inference oracle submits the result and proof for a pending inference request.
// 8.  claimInferenceRevenue(uint256 _modelId, address _tokenAddress): Model owner claims accumulated revenue from completed inferences in a specific token.
// 9.  stakeForEvaluation(uint256 _modelId, string calldata _testDatasetHash, uint256 _stakeAmount, address _stakeToken): User stakes tokens to participate in evaluating a model's performance on a given test dataset.
// 10. submitEvaluationReport(uint256 _evaluationId, uint256 _score, string calldata _reportHash): An evaluator submits their performance report (score and hash of full report) for a specific evaluation round.
// 11. challengeEvaluationReport(uint256 _evaluationId, uint252 _reportIndex, string calldata _reasonHash, uint256 _challengeStake): A user challenges an existing evaluation report, providing a reason and a stake.
// 12. resolveEvaluationChallenge(uint256 _challengeId, bool _challengerWins, uint256 _modelId, int256 _reputationDelta): An authorized evaluation oracle resolves a challenge, adjusting stakes and model reputation.
// 13. claimEvaluationReward(uint256 _evaluationId): Evaluator claims their stake back plus any rewards if their report was accepted or they successfully challenged another.
// 14. _updateModelReputation(uint256 _modelId, int256 _reputationDelta): Internal helper to update model reputation.
// 15. setProtocolFeeRate(uint256 _newFeeRate): Admin function to update the percentage fee collected by the protocol on certain transactions.
// 16. distributeProtocolFees(address _tokenAddress): Distributes accumulated protocol fees (e.g., to a DAO treasury or designated stakers).
// 17. pause(): Pauses core contract functionalities (e.g., during upgrades or emergencies).
// 18. unpause(): Unpauses core contract functionalities.
// 19. grantRole(bytes32 role, address account): Admin function to grant specific roles (e.g., INFERENCE_ORACLE_ROLE, EVALUATION_ORACLE_ROLE).
// 20. revokeRole(bytes32 role, address account): Admin function to revoke roles.
// 21. withdrawStuckTokens(address _tokenAddress, uint256 _amount): Admin function to withdraw any accidentally sent or stuck ERC20 tokens.
// 22. getModelDetails(uint256 _modelId): Query function to get all details about a registered model.
// 23. getPendingInferenceRequest(uint256 _requestId): Query function for a specific pending inference request.
// 24. getEvaluationDetails(uint256 _evaluationId): Query function for details of an evaluation round.
// 25. getModelShareBalance(uint256 _modelId, address _account): Gets the balance of fractional shares for a model held by an account.
// 26. getProtocolFeeRate(): Gets the current protocol fee rate.
// 27. getProtocolFeeBalance(address _tokenAddress): Gets the current protocol fee balance for a specific token.


contract AetherMindForge is AccessControl, Pausable {
    bytes32 public constant INFERENCE_ORACLE_ROLE = keccak256("INFERENCE_ORACLE_ROLE");
    bytes32 public constant EVALUATION_ORACLE_ROLE = keccak256("EVALUATION_ORACLE_ROLE");

    // --- Structs ---

    struct Model {
        address owner;
        string name;
        string description;
        string ipfsHash; // Hash pointing to the model's metadata and access instructions
        uint256 inferencePricePerUnit; // Price in WEI or smallest unit of payment token
        uint256 totalShares; // Total fractional shares for this model
        uint256 reputation; // Reputation score, starts at 0, updated by evaluations
        uint256 registeredAt;
        mapping(address => uint256) revenueByToken; // Accumulated revenue for the model, per token
    }

    struct InferenceRequest {
        uint256 modelId;
        address requester;
        address paymentToken;
        uint256 numUnits;
        string inputDataHash; // Hash pointing to input data for inference
        uint256 paidAmount;
        string outputDataHash; // Hash pointing to output data (submitted by oracle)
        string proof; // Proof of computation (submitted by oracle)
        uint256 requestedAt;
        uint256 completedAt;
        bool isCompleted;
    }

    struct EvaluationReport {
        address evaluator;
        uint256 score; // e.g., accuracy percentage * 100
        string reportHash; // Hash pointing to detailed evaluation report
        uint256 submittedAt;
        bool isChallenged;
        bool isAccepted; // True if not challenged or challenge failed
    }

    struct Evaluation {
        uint256 modelId;
        address creator; // Who initiated the evaluation round (first staker)
        string testDatasetHash; // Hash pointing to the dataset used for evaluation
        uint256 stakeAmount; // Amount staked by each evaluator
        address stakeToken; // Token used for staking
        uint256 startedAt;
        uint256 endedAt; // Expected end time for submissions
        EvaluationReport[] reports;
        mapping(address => bool) hasSubmittedReport; // Tracks if an address has submitted a report
        mapping(address => bool) hasClaimedReward; // Tracks if an address has claimed reward for this evaluation
    }

    struct Challenge {
        uint256 evaluationId;
        uint256 reportIndex; // Index of the challenged report in Evaluation.reports array
        address challenger;
        string reasonHash; // Hash pointing to the challenge reason/evidence
        uint256 challengeStake;
        address challengeStakeToken;
        uint256 challengedAt;
        bool isResolved;
        bool challengerWins; // True if challenger's claim is upheld
    }

    // --- State Variables ---

    uint256 public nextModelId;
    uint256 public nextInferenceRequestId;
    uint256 public nextEvaluationId;
    uint256 public nextChallengeId;
    uint256 public protocolFeeRate; // e.g., 100 for 1%, 500 for 5% (max 10,000 for 100%)
    address public protocolFeeRecipient; // Address where protocol fees are collected

    mapping(uint256 => Model) public models;
    mapping(uint256 => mapping(address => uint256)) public modelShares; // modelId => owner => balance
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    mapping(uint256 => Evaluation) public evaluations;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => mapping(address => uint256)) public protocolFeeBalanceByToken; // token => balance

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 totalShares);
    event ModelSharesMinted(uint256 indexed modelId, address indexed minter, address indexed recipient, uint256 amount);
    event ModelSharesTransferred(uint256 indexed modelId, address indexed from, address indexed to, uint256 amount);
    event InferencePriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, uint256 numUnits, uint256 paidAmount);
    event InferenceResultSubmitted(uint256 indexed requestId, uint256 indexed modelId, address indexed oracle, string outputDataHash);
    event InferenceRevenueClaimed(uint256 indexed modelId, address indexed owner, address indexed token, uint256 amount);
    event EvaluationStaked(uint256 indexed evaluationId, uint256 indexed modelId, address indexed evaluator, uint256 stakeAmount);
    event EvaluationReportSubmitted(uint256 indexed evaluationId, address indexed evaluator, uint256 score);
    event EvaluationReportChallenged(uint256 indexed challengeId, uint256 indexed evaluationId, address indexed challenger, uint256 reportIndex);
    event EvaluationChallengeResolved(uint256 indexed challengeId, uint256 indexed evaluationId, bool challengerWins);
    event EvaluationRewardClaimed(uint256 indexed evaluationId, address indexed claimant, uint256 amount);
    event ModelReputationUpdated(uint256 indexed modelId, int256 reputationDelta, uint256 newReputation);
    event ProtocolFeeRateUpdated(uint256 newRate);
    event ProtocolFeesDistributed(address indexed token, uint256 amount);
    event StuckTokensWithdrawn(address indexed token, address indexed recipient, uint256 amount);

    // --- Constructor ---

    constructor(address _protocolFeeRecipient) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant deployer the initial oracle roles for testing or bootstrapping
        _grantRole(INFERENCE_ORACLE_ROLE, msg.sender);
        _grantRole(EVALUATION_ORACLE_ROLE, msg.sender);

        protocolFeeRate = 100; // 1% (100 basis points)
        protocolFeeRecipient = _protocolFeeRecipient;
        require(protocolFeeRecipient != address(0), "Invalid fee recipient");
    }

    // --- I. Core Model Management & Tokenization ---

    /**
     * @dev Registers a new AI model on the platform.
     * Assigns a unique modelId and sets initial parameters.
     * Mints the total specified shares to the model owner.
     * @param _name The name of the AI model.
     * @param _description A brief description of the model.
     * @param _ipfsHash IPFS hash pointing to the model's metadata, architecture, and deployment instructions.
     * @param _inferencePricePerUnit The price for one unit of inference using this model.
     * @param _totalShares The total number of fractional ownership shares for this model.
     */
    function registerModel(
        string calldata _name,
        string calldata _description,
        string calldata _ipfsHash,
        uint256 _inferencePricePerUnit,
        uint256 _totalShares
    ) external whenNotPaused returns (uint256) {
        require(_totalShares > 0, "Total shares must be positive");
        require(_inferencePricePerUnit > 0, "Inference price must be positive");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        uint256 modelId = nextModelId++;
        models[modelId] = Model({
            owner: msg.sender,
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            inferencePricePerUnit: _inferencePricePerUnit,
            totalShares: _totalShares,
            reputation: 0, // Initial reputation
            registeredAt: block.timestamp
        });

        // Mint all shares to the model owner initially
        modelShares[modelId][msg.sender] = _totalShares;

        emit ModelRegistered(modelId, msg.sender, _name, _totalShares);
        return modelId;
    }

    /**
     * @dev Mints fractional ownership shares of a specific model to multiple recipients.
     * Only the model owner can distribute shares from their initial allocation.
     * This function effectively transfers shares from the owner's balance to other recipients.
     * @param _modelId The ID of the model.
     * @param _recipients An array of addresses to receive shares.
     * @param _amounts An array of amounts corresponding to each recipient.
     */
    function mintModelShares(
        uint256 _modelId,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external whenNotPaused {
        require(models[_modelId].owner == msg.sender, "Only model owner can distribute shares");
        require(_recipients.length == _amounts.length, "Recipient and amount arrays must match length");

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Cannot distribute to zero address");
            totalDistributed += _amounts[i];
            modelShares[_modelId][_recipients[i]] += _amounts[i];
            emit ModelSharesMinted(_modelId, msg.sender, _recipients[i], _amounts[i]);
        }

        require(modelShares[_modelId][msg.sender] >= totalDistributed, "Insufficient owner shares to distribute");
        modelShares[_modelId][msg.sender] -= totalDistributed;
        emit ModelSharesTransferred(_modelId, msg.sender, address(0), totalDistributed); // Indicate shares moved from owner's pool
    }

    /**
     * @dev Transfers fractional shares of a model from one address to another.
     * Behaves like ERC-1155 `safeTransferFrom` but custom for model shares.
     * @param _modelId The ID of the model whose shares are being transferred.
     * @param _from The sender of the shares.
     * @param _to The recipient of the shares.
     * @param _amount The amount of shares to transfer.
     */
    function safeTransferFromModelShares(
        uint256 _modelId,
        address _from,
        address _to,
        uint256 _amount
    ) external whenNotPaused {
        require(_from != address(0), "Cannot transfer from zero address");
        require(_to != address(0), "Cannot transfer to zero address");
        require(modelShares[_modelId][_from] >= _amount, "Insufficient shares");
        require(msg.sender == _from || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller not owner or admin"); // Simple approval mechanism

        modelShares[_modelId][_from] -= _amount;
        modelShares[_modelId][_to] += _amount;

        emit ModelSharesTransferred(_modelId, _from, _to, _amount);
    }

    // --- II. Inference Service Management ---

    /**
     * @dev Model owner updates the price per unit of inference for their model.
     * @param _modelId The ID of the model.
     * @param _newPricePerUnit The new price per unit of inference.
     */
    function setInferencePrice(uint256 _modelId, uint256 _newPricePerUnit) external whenNotPaused {
        require(models[_modelId].owner == msg.sender, "Only model owner can set inference price");
        require(_newPricePerUnit > 0, "Price must be positive");
        models[_modelId].inferencePricePerUnit = _newPricePerUnit;
        emit InferencePriceUpdated(_modelId, _newPricePerUnit);
    }

    /**
     * @dev User requests a specific number of inference units for a model, paying with a specified ERC20 token.
     * The payment is transferred to the contract, and a pending request is created.
     * @param _modelId The ID of the model to request inference from.
     * @param _inputDataHash IPFS hash pointing to the input data for the inference.
     * @param _numUnits The number of inference units requested.
     * @param _paymentToken The ERC20 token address used for payment.
     */
    function requestInference(
        uint256 _modelId,
        string calldata _inputDataHash,
        uint256 _numUnits,
        address _paymentToken
    ) external whenNotPaused returns (uint256) {
        require(models[_modelId].owner != address(0), "Model does not exist");
        require(_numUnits > 0, "Number of units must be positive");
        require(bytes(_inputDataHash).length > 0, "Input data hash cannot be empty");
        require(_paymentToken != address(0), "Payment token cannot be zero address");

        uint256 price = models[_modelId].inferencePricePerUnit;
        uint256 totalCost = price * _numUnits;

        // Transfer payment from user to contract
        IERC20(_paymentToken).transferFrom(msg.sender, address(this), totalCost);

        uint256 requestId = nextInferenceRequestId++;
        inferenceRequests[requestId] = InferenceRequest({
            modelId: _modelId,
            requester: msg.sender,
            paymentToken: _paymentToken,
            numUnits: _numUnits,
            inputDataHash: _inputDataHash,
            paidAmount: totalCost,
            outputDataHash: "",
            proof: "",
            requestedAt: block.timestamp,
            completedAt: 0,
            isCompleted: false
        });

        // Store revenue for the model owner (net of protocol fee) and protocol fees
        uint256 protocolFee = (totalCost * protocolFeeRate) / 10000; // protocolFeeRate is in basis points
        uint256 ownerRevenue = totalCost - protocolFee;

        models[_modelId].revenueByToken[_paymentToken] += ownerRevenue;
        protocolFeeBalanceByToken[_paymentToken] += protocolFee;

        emit InferenceRequested(requestId, _modelId, msg.sender, _numUnits, totalCost);
        return requestId;
    }

    /**
     * @dev An authorized inference oracle submits the result and proof for a pending inference request.
     * @param _requestId The ID of the inference request.
     * @param _outputDataHash IPFS hash pointing to the output data from the inference.
     * @param _proof Cryptographic proof of computation (e.g., ZK-proof hash, signed attestation).
     */
    function submitInferenceResult(
        uint256 _requestId,
        string calldata _outputDataHash,
        string calldata _proof
    ) external onlyRole(INFERENCE_ORACLE_ROLE) whenNotPaused {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.modelId != 0, "Inference request does not exist");
        require(!request.isCompleted, "Inference request already completed");
        require(bytes(_outputDataHash).length > 0, "Output data hash cannot be empty");
        require(bytes(_proof).length > 0, "Proof cannot be empty");

        request.outputDataHash = _outputDataHash;
        request.proof = _proof;
        request.completedAt = block.timestamp;
        request.isCompleted = true;

        emit InferenceResultSubmitted(_requestId, request.modelId, msg.sender, _outputDataHash);
    }

    /**
     * @dev Model owner claims accumulated revenue from completed inferences in a specific token.
     * @param _modelId The ID of the model.
     * @param _tokenAddress The ERC20 token address for which revenue is to be claimed.
     */
    function claimInferenceRevenue(uint256 _modelId, address _tokenAddress) external whenNotPaused {
        require(models[_modelId].owner == msg.sender, "Only model owner can claim revenue");
        require(_tokenAddress != address(0), "Token address cannot be zero");

        uint256 amount = models[_modelId].revenueByToken[_tokenAddress];
        require(amount > 0, "No revenue to claim for this token");

        models[_modelId].revenueByToken[_tokenAddress] = 0; // Reset before transfer to prevent re-entrancy
        IERC20(_tokenAddress).transfer(msg.sender, amount);

        emit InferenceRevenueClaimed(_modelId, msg.sender, _tokenAddress, amount);
    }

    // --- III. Trustless Model Evaluation & Reputation ---

    /**
     * @dev User stakes tokens to participate in evaluating a model's performance on a given test dataset.
     * @param _modelId The ID of the model to evaluate.
     * @param _testDatasetHash IPFS hash pointing to the standardized test dataset.
     * @param _stakeAmount The amount of tokens to stake for this evaluation.
     * @param _stakeToken The ERC20 token address used for staking.
     */
    function stakeForEvaluation(
        uint256 _modelId,
        string calldata _testDatasetHash,
        uint256 _stakeAmount,
        address _stakeToken
    ) external whenNotPaused returns (uint256) {
        require(models[_modelId].owner != address(0), "Model does not exist");
        require(models[_modelId].owner != msg.sender, "Model owner cannot directly evaluate their own model");
        require(_stakeAmount > 0, "Stake amount must be positive");
        require(bytes(_testDatasetHash).length > 0, "Test dataset hash cannot be empty");
        require(_stakeToken != address(0), "Stake token cannot be zero address");

        // Transfer stake from user to contract
        IERC20(_stakeToken).transferFrom(msg.sender, address(this), _stakeAmount);

        uint256 evaluationId = nextEvaluationId++;
        evaluations[evaluationId] = Evaluation({
            modelId: _modelId,
            creator: msg.sender, // The one who initiates the round by staking first
            testDatasetHash: _testDatasetHash,
            stakeAmount: _stakeAmount,
            stakeToken: _stakeToken,
            startedAt: block.timestamp,
            endedAt: block.timestamp + 7 days, // Example: 7 days for evaluations
            reports: new EvaluationReport[](0)
        });
        evaluations[evaluationId].hasSubmittedReport[msg.sender] = true; // Mark creator as having staked and thus can submit
        evaluations[evaluationId].hasClaimedReward[msg.sender] = false;

        emit EvaluationStaked(evaluationId, _modelId, msg.sender, _stakeAmount);
        return evaluationId;
    }

    /**
     * @dev An evaluator submits their performance report for a specific evaluation round.
     * Requires the evaluator to have previously staked for this evaluation.
     * @param _evaluationId The ID of the evaluation round.
     * @param _score The performance score (e.g., accuracy percentage * 100).
     * @param _reportHash IPFS hash pointing to the detailed evaluation report.
     */
    function submitEvaluationReport(
        uint256 _evaluationId,
        uint256 _score,
        string calldata _reportHash
    ) external whenNotPaused {
        Evaluation storage evaluation = evaluations[_evaluationId];
        require(evaluation.modelId != 0, "Evaluation does not exist");
        require(block.timestamp <= evaluation.endedAt, "Evaluation period has ended");
        require(evaluation.hasSubmittedReport[msg.sender], "Evaluator must first stake for this round");
        // Ensure evaluator hasn't already submitted a report for this evaluation (first check if it's new logic)
        // If hasSubmittedReport[msg.sender] is just for staking, we need to iterate reports to ensure no double submission
        bool alreadySubmittedReport = false;
        for (uint i = 0; i < evaluation.reports.length; i++) {
            if (evaluation.reports[i].evaluator == msg.sender) {
                alreadySubmittedReport = true;
                break;
            }
        }
        require(!alreadySubmittedReport, "Evaluator has already submitted a report for this round");
        
        require(_score <= 10000, "Score cannot exceed 100% (10000)"); // Max 100%
        require(bytes(_reportHash).length > 0, "Report hash cannot be empty");

        evaluation.reports.push(EvaluationReport({
            evaluator: msg.sender,
            score: _score,
            reportHash: _reportHash,
            submittedAt: block.timestamp,
            isChallenged: false,
            isAccepted: true // Initially accepted unless challenged
        }));

        emit EvaluationReportSubmitted(_evaluationId, msg.sender, _score);
    }

    /**
     * @dev A user challenges an existing evaluation report, providing a reason and a stake.
     * This initiates a dispute resolution process.
     * @param _evaluationId The ID of the evaluation round.
     * @param _reportIndex The index of the report in the `reports` array to challenge.
     * @param _reasonHash IPFS hash pointing to the detailed reason and evidence for the challenge.
     * @param _challengeStake The amount of tokens to stake for this challenge.
     */
    function challengeEvaluationReport(
        uint256 _evaluationId,
        uint256 _reportIndex,
        string calldata _reasonHash,
        uint256 _challengeStake
    ) external whenNotPaused returns (uint256) {
        Evaluation storage evaluation = evaluations[_evaluationId];
        require(evaluation.modelId != 0, "Evaluation does not exist");
        require(_reportIndex < evaluation.reports.length, "Invalid report index");
        require(!evaluation.reports[_reportIndex].isChallenged, "Report already challenged");
        require(evaluation.reports[_reportIndex].evaluator != msg.sender, "Cannot challenge your own report");
        require(_challengeStake > 0, "Challenge stake must be positive");
        require(bytes(_reasonHash).length > 0, "Reason hash cannot be empty");

        // Transfer challenge stake to contract
        IERC20(evaluation.stakeToken).transferFrom(msg.sender, address(this), _challengeStake);

        evaluation.reports[_reportIndex].isChallenged = true;

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            evaluationId: _evaluationId,
            reportIndex: _reportIndex,
            challenger: msg.sender,
            reasonHash: _reasonHash,
            challengeStake: _challengeStake,
            challengeStakeToken: evaluation.stakeToken,
            challengedAt: block.timestamp,
            isResolved: false,
            challengerWins: false
        });

        emit EvaluationReportChallenged(challengeId, _evaluationId, msg.sender, _reportIndex);
        return challengeId;
    }

    /**
     * @dev An authorized evaluation oracle resolves a challenge, adjusting stakes and model reputation.
     * If challenger wins: challenged evaluator's stake is slashed, challenger gets reward.
     * If challenged report is upheld: challenger's stake is slashed, challenged evaluator gets reward.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger's claim is upheld, false otherwise.
     * @param _modelId The ID of the model related to the challenge. Required for reputation update.
     * @param _reputationDelta The change in reputation for the model, based on resolution.
     */
    function resolveEvaluationChallenge(
        uint252 _challengeId,
        bool _challengerWins,
        uint252 _modelId,
        int256 _reputationDelta
    ) external onlyRole(EVALUATION_ORACLE_ROLE) whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.evaluationId != 0, "Challenge does not exist");
        require(!challenge.isResolved, "Challenge already resolved");

        Evaluation storage evaluation = evaluations[challenge.evaluationId];
        EvaluationReport storage challengedReport = evaluation.reports[challenge.reportIndex];
        require(evaluation.modelId == _modelId, "Model ID mismatch for challenge resolution");

        challenge.isResolved = true;
        challenge.challengerWins = _challengerWins;

        address challengedEvaluator = challengedReport.evaluator;
        address challenger = challenge.challenger;
        address stakeToken = evaluation.stakeToken; // Both stakes are in the same token

        uint256 challengedEvaluatorStake = evaluation.stakeAmount; // Original stake by evaluator
        uint252 challengerStake = challenge.challengeStake;

        if (_challengerWins) {
            challengedReport.isAccepted = false; // Mark report as invalid
            // Challenger wins: Gets back their stake + challenged evaluator's stake
            IERC20(stakeToken).transfer(challenger, challengerStake + challengedEvaluatorStake);
            // Evaluator's original stake is implicitly lost to the challenger.
        } else {
            // Challenger loses: challenged report is upheld
            // Challenged evaluator gets back their stake + challenger's stake
            IERC20(stakeToken).transfer(challengedEvaluator, challengedEvaluatorStake + challengerStake);
            // Challenger's stake is implicitly lost to the challenged evaluator.
        }

        // Update model reputation
        _updateModelReputation(_modelId, _reputationDelta);

        emit EvaluationChallengeResolved(_challengeId, challenge.evaluationId, _challengerWins);
        emit ModelReputationUpdated(_modelId, _reputationDelta, models[_modelId].reputation);
    }

    /**
     * @dev Internal function to update a model's reputation score.
     * Can be called by resolution of evaluations or challenges.
     * @param _modelId The ID of the model whose reputation is being updated.
     * @param _reputationDelta The amount to add or subtract from the reputation score.
     */
    function _updateModelReputation(uint252 _modelId, int256 _reputationDelta) internal {
        if (_reputationDelta > 0) {
            models[_modelId].reputation += uint256(_reputationDelta);
        } else {
            // Ensure reputation doesn't go below zero
            models[_modelId].reputation = models[_modelId].reputation > uint256(-_reputationDelta)
                ? models[_modelId].reputation - uint256(-_reputationDelta)
                : 0;
        }
    }

    /**
     * @dev Evaluator claims their stake back plus any rewards if their report was accepted or they successfully challenged another.
     * This function primarily handles the return of stake for *unchallenged, accepted reports*.
     * Rewards from successful challenges are handled directly in `resolveEvaluationChallenge`.
     * @param _evaluationId The ID of the evaluation round.
     */
    function claimEvaluationReward(uint252 _evaluationId) external whenNotPaused {
        Evaluation storage evaluation = evaluations[_evaluationId];
        require(evaluation.modelId != 0, "Evaluation does not exist");
        require(evaluation.hasSubmittedReport[msg.sender], "Caller did not participate in this evaluation");
        require(!evaluation.hasClaimedReward[msg.sender], "Rewards already claimed for this evaluation");

        uint252 totalReward = 0;
        bool isEligibleForBaseStakeReturn = false;

        // Check if the caller submitted an ACCEPTED report for this evaluation
        for (uint256 i = 0; i < evaluation.reports.length; i++) {
            if (evaluation.reports[i].evaluator == msg.sender) {
                if (evaluation.reports[i].isAccepted) {
                    isEligibleForBaseStakeReturn = true; // Report was accepted (either not challenged or challenge failed)
                }
                break;
            }
        }

        if (isEligibleForBaseStakeReturn) {
            totalReward += evaluation.stakeAmount; // Return original stake
        }

        require(totalReward > 0, "No rewards or stake to claim (report not accepted or already claimed)");
        evaluation.hasClaimedReward[msg.sender] = true;
        IERC20(evaluation.stakeToken).transfer(msg.sender, totalReward);

        emit EvaluationRewardClaimed(_evaluationId, msg.sender, totalReward);
    }

    // --- IV. Economic & Fee Mechanisms ---

    /**
     * @dev Admin function to update the percentage fee collected by the protocol on certain transactions.
     * Fee rate is in basis points (e.g., 100 for 1%, 500 for 5%). Max 10,000 (100%).
     * @param _newFeeRate The new protocol fee rate in basis points.
     */
    function setProtocolFeeRate(uint252 _newFeeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newFeeRate <= 10000, "Fee rate cannot exceed 100%");
        protocolFeeRate = _newFeeRate;
        emit ProtocolFeeRateUpdated(_newFeeRate);
    }

    /**
     * @dev Distributes accumulated protocol fees from a specific token to the designated fee recipient.
     * @param _tokenAddress The ERC20 token address from which fees are to be distributed.
     */
    function distributeProtocolFees(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenAddress != address(0), "Token address cannot be zero");

        uint252 amount = protocolFeeBalanceByToken[_tokenAddress];
        require(amount > 0, "No protocol fees to distribute for this token");

        protocolFeeBalanceByToken[_tokenAddress] = 0; // Reset before transfer
        IERC20(_tokenAddress).transfer(protocolFeeRecipient, amount);

        emit ProtocolFeesDistributed(_tokenAddress, amount);
    }

    // --- V. Governance & Administrative ---

    /**
     * @dev Pauses core contract functionalities. Can only be called by an authorized pauser (admin role).
     * Useful during upgrades or emergency situations to prevent further state changes.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses core contract functionalities. Can only be called by an authorized pauser (admin role).
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows the default admin to grant specific roles to accounts.
     * Roles include INFERENCE_ORACLE_ROLE, EVALUATION_ORACLE_ROLE.
     * @param role The role to grant.
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Allows the default admin to revoke specific roles from accounts.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Allows the default admin to withdraw any accidentally sent or stuck ERC20 tokens from the contract.
     * This is an emergency function and should be used with extreme caution.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawStuckTokens(address _tokenAddress, uint252 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenAddress != address(0), "Cannot withdraw zero address token");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Insufficient stuck token balance");

        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        emit StuckTokensWithdrawn(_tokenAddress, msg.sender, _amount);
    }

    // --- VI. Utility & Querying ---

    /**
     * @dev Query function to get all details about a registered model.
     * @param _modelId The ID of the model.
     * @return Model struct data.
     */
    function getModelDetails(uint252 _modelId)
        external
        view
        returns (
            address owner,
            string memory name,
            string memory description,
            string memory ipfsHash,
            uint252 inferencePricePerUnit,
            uint252 totalShares,
            uint252 reputation,
            uint252 registeredAt
        )
    {
        Model storage model = models[_modelId];
        require(model.owner != address(0), "Model does not exist");
        return (
            model.owner,
            model.name,
            model.description,
            model.ipfsHash,
            model.inferencePricePerUnit,
            model.totalShares,
            model.reputation,
            model.registeredAt
        );
    }

    /**
     * @dev Query function for a specific pending inference request.
     * @param _requestId The ID of the inference request.
     * @return InferenceRequest struct data.
     */
    function getPendingInferenceRequest(uint252 _requestId)
        external
        view
        returns (
            uint252 modelId,
            address requester,
            address paymentToken,
            uint252 numUnits,
            string memory inputDataHash,
            uint252 paidAmount,
            string memory outputDataHash,
            string memory proof,
            uint252 requestedAt,
            uint252 completedAt,
            bool isCompleted
        )
    {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.modelId != 0, "Inference request does not exist");
        return (
            request.modelId,
            request.requester,
            request.paymentToken,
            request.numUnits,
            request.inputDataHash,
            request.paidAmount,
            request.outputDataHash,
            request.proof,
            request.requestedAt,
            request.completedAt,
            request.isCompleted
        );
    }

    /**
     * @dev Query function for details of an evaluation round.
     * Returns a summary, not individual reports/challenges.
     * @param _evaluationId The ID of the evaluation round.
     * @return Evaluation struct summary data.
     */
    function getEvaluationDetails(uint252 _evaluationId)
        external
        view
        returns (
            uint252 modelId,
            address creator,
            string memory testDatasetHash,
            uint252 stakeAmount,
            address stakeToken,
            uint252 startedAt,
            uint252 endedAt,
            uint252 numReports
        )
    {
        Evaluation storage evaluation = evaluations[_evaluationId];
        require(evaluation.modelId != 0, "Evaluation does not exist");
        return (
            evaluation.modelId,
            evaluation.creator,
            evaluation.testDatasetHash,
            evaluation.stakeAmount,
            evaluation.stakeToken,
            evaluation.startedAt,
            evaluation.endedAt,
            evaluation.reports.length
        );
    }

    /**
     * @dev Gets the balance of fractional shares for a model held by an account.
     * @param _modelId The ID of the model.
     * @param _account The address of the account.
     * @return The balance of shares.
     */
    function getModelShareBalance(uint252 _modelId, address _account) external view returns (uint252) {
        return modelShares[_modelId][_account];
    }

    /**
     * @dev Gets the current protocol fee rate.
     * @return The protocol fee rate in basis points.
     */
    function getProtocolFeeRate() external view returns (uint252) {
        return protocolFeeRate;
    }

    /**
     * @dev Gets the current protocol fee balance for a specific token.
     * @param _tokenAddress The address of the ERC20 token.
     * @return The balance of protocol fees.
     */
    function getProtocolFeeBalance(address _tokenAddress) external view returns (uint252) {
        return protocolFeeBalanceByToken[_tokenAddress];
    }
}
```