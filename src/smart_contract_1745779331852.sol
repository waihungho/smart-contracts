Okay, here is a Solidity smart contract concept for a **Decentralized AI Model Marketplace with Verified Evaluation and Staking**.

This contract aims to provide a platform where AI model developers can list their models, users can purchase access/licenses, and a staked network of evaluators can verify the performance of models through an off-chain process, with on-chain dispute resolution.

It includes concepts like:
*   Model Listing & Purchasing
*   Staking for Evaluators
*   Off-chain Evaluation Referencing
*   On-chain Dispute Resolution for Evaluations
*   Reputation Scoring (basic implementation)
*   Marketplace Fees & Revenue Distribution
*   Versioning & Retirement

---

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import Ownable, Pausable.
2.  **Enums:** Define states for Evaluations and Disputes.
3.  **Structs:** Define data structures for `Model`, `Evaluation`, `Dispute`, and `User`.
4.  **State Variables:** Mappings, counters, fees, addresses.
5.  **Events:** Declare events for key actions.
6.  **Modifiers:** Access control and state modifiers.
7.  **Constructor:** Initialize owner.
8.  **Model Management Functions:** Register, update, list, unlist, retire, get details.
9.  **Marketplace Functions:** Buy model, withdraw earnings, set fees, withdraw fees.
10. **Evaluator Staking & Management Functions:** Stake, increase/decrease stake, register/remove approved evaluators, get stake.
11. **Evaluation Process Functions:** Request evaluation, submit results, get evaluation details.
12. **Dispute Resolution Functions:** Challenge evaluation, resolve dispute, get dispute details.
13. **Reputation Functions:** Get user reputation (logic mostly internal to dispute resolution).
14. **Utility/View Functions:** Get total models, listed models, user details.
15. **Admin Functions:** Pause/unpause contract, set various parameters.

---

**Function Summary:**

*   `registerModel`: Registers a new version of an AI model. Requires model metadata hash (e.g., IPFS).
*   `updateModelDetails`: Allows the model owner to update metadata (hash, description) for a specific version.
*   `updateModelPrice`: Allows the model owner to update the price of a listed model version.
*   `listModel`: Lists a registered model version for sale on the marketplace.
*   `unlistModel`: Removes a listed model version from the marketplace.
*   `retireModel`: Marks a model version as retired, preventing new purchases but potentially allowing continued access for prior buyers.
*   `buyModel`: Allows a user to purchase access/license for a listed model version by paying the required price.
*   `withdrawModelEarnings`: Allows a model owner to withdraw funds earned from model sales (after marketplace fees).
*   `stakeAsEvaluator`: Allows a user to stake tokens to become eligible to be an approved evaluator.
*   `increaseStake`: Allows an existing staker to increase their staked amount.
*   `decreaseStake`: Allows an existing staker to decrease their stake (might require a cooldown period in a real system, omitted here for brevity).
*   `registerApprovedEvaluator`: Owner (or governance) approves a staked address to become an official evaluator.
*   `removeApprovedEvaluator`: Owner (or governance) removes an approved evaluator.
*   `requestEvaluation`: Allows a model owner or potentially a buyer to request an official performance evaluation for a model version, paying a fee.
*   `submitEvaluationResult`: Allows an approved evaluator to submit the result (e.g., score based on predefined metrics) of an off-chain evaluation for a specific request.
*   `challengeEvaluation`: Allows a user to dispute the result of a submitted evaluation, requiring a dispute stake.
*   `resolveDispute`: Owner (or governance) resolves an open dispute, determining the validity of the evaluation and challenge, and handling stakes/reputation.
*   `setMarketplaceFee`: Owner sets the percentage fee taken by the marketplace on sales.
*   `setEvaluationFee`: Owner sets the fee required to request a model evaluation.
*   `setMinimumEvaluatorStake`: Owner sets the minimum stake required to be considered for evaluator approval.
*   `setDisputeStake`: Owner sets the stake required to challenge an evaluation.
*   `setDisputeResolutionPeriod`: Owner sets the time limit for resolving a dispute.
*   `pauseContract`: Owner can pause contract sensitive operations (e.g., buying, staking changes).
*   `unpauseContract`: Owner can unpause the contract.
*   `getModelDetails`: View function to retrieve details of a specific model version.
*   `getUserModels`: View function to list model versions owned by a user.
*   `getEvaluationDetails`: View function to retrieve details of a specific evaluation request.
*   `getDisputeDetails`: View function to retrieve details of a specific dispute.
*   `getUserStake`: View function to check an address's current evaluator stake.
*   `getUserReputation`: View function to check an address's reputation score (simplified).
*   `getListedModels`: View function to list all model versions currently listed for sale.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A smart contract for a decentralized marketplace for AI models
 *      featuring model listing, purchasing, staked evaluation, and dispute resolution.
 */
contract DecentralizedAIModelMarketplace is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---

    enum EvaluationStatus {
        Pending,    // Evaluation requested, waiting for evaluator submission
        Submitted,  // Evaluator submitted results, waiting for potential challenge
        Disputed,   // Evaluation results challenged, waiting for resolution
        Resolved,   // Dispute resolved
        Completed   // Evaluation complete and not disputed, or dispute resolved favorably
    }

    enum DisputeStatus {
        Open,        // Dispute is active
        ResolvedValid, // Dispute resolved, challenge upheld (evaluation was incorrect)
        ResolvedInvalid // Dispute resolved, challenge denied (evaluation was correct)
    }

    // --- Structs ---

    struct Model {
        uint256 id;
        address owner;
        bytes32 ipfsHash;       // Hash pointing to model files & detailed metadata on IPFS
        string name;
        string description;
        uint256 version;        // Model version number
        uint256 price;          // Price in wei
        bool isListed;          // True if currently available for sale
        bool isRetired;         // True if model version is retired (no new sales)
        uint256 latestEvaluationId; // Reference to the latest completed/resolved evaluation
        // Basic aggregation for potential average rating (more complex logic needed for robust system)
        uint256 totalRatingsValue; // Sum of scores from completed, undisputed evaluations
        uint256 ratingCount;       // Number of such evaluations
    }

    struct Evaluation {
        uint256 id;
        uint256 modelId;        // Reference to the model being evaluated
        address requester;      // Address that requested the evaluation
        address evaluator;      // Approved evaluator assigned/who submitted the result
        bytes32 dataIpfsHash;   // Hash pointing to dataset used for evaluation
        int256 score;           // The submitted performance score (e.g., accuracy %) - allow negative for flexibility
        EvaluationStatus status;
        uint256 submittedTimestamp; // Timestamp when results were submitted
        uint256 disputeId;      // Reference to an active dispute, if any
        bool scoreFinalized;    // True if the score has passed challenge period or dispute
    }

    struct Dispute {
        uint256 id;
        uint256 evaluationId;    // Reference to the evaluation being disputed
        address challenger;      // Address that initiated the dispute
        uint256 challengerStake; // Stake required and held for the dispute
        DisputeStatus status;
        uint256 disputeRaisedTimestamp;
        uint256 resolutionTimestamp;
        // More complex resolution details would be needed in a real system
    }

    struct User {
        uint256 stakedAmount;     // Amount staked for potential evaluator role
        int256 reputationScore;   // Basic reputation score (positive/negative)
    }

    // --- State Variables ---

    uint256 public nextModelId = 1;
    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) public userModels; // Models owned by an address

    uint256 public nextEvaluationId = 1;
    mapping(uint256 => Evaluation) public evaluations;
    mapping(uint256 => uint256[]) public modelEvaluations; // Evaluations for a specific model

    uint256 public nextDisputeId = 1;
    mapping(uint256 => Dispute) public disputes;

    mapping(address => User) public users;

    mapping(address => bool) public approvedEvaluators; // Addresses approved to submit evaluations
    address[] public approvedEvaluatorList; // List of approved evaluators

    uint256 public marketplaceFeeBasisPoints; // Fee as a percentage, e.g., 500 for 5% (500/10000)
    uint256 public evaluationFee;             // Fee in wei to request an evaluation
    uint256 public minimumEvaluatorStake;    // Minimum stake required to be approved evaluator
    uint256 public disputeStake;              // Stake required to challenge an evaluation
    uint256 public disputeResolutionPeriod;   // Time in seconds for dispute resolution

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed owner, bytes32 ipfsHash, uint256 version, string name);
    event ModelUpdated(uint256 indexed modelId, bytes32 newIpfsHash, string newName, string newDescription);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 oldPrice, uint256 newPrice);
    event ModelListed(uint256 indexed modelId, uint256 price);
    event ModelUnlisted(uint256 indexed modelId);
    event ModelRetired(uint256 indexed modelId);
    event ModelPurchased(uint256 indexed modelId, address indexed buyer, uint256 pricePaid);
    event ModelEarningsWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);

    event EvaluatorStaked(address indexed evaluator, uint256 amount);
    event EvaluatorStakeIncreased(address indexed evaluator, uint256 newAmount);
    event EvaluatorStakeDecreased(address indexed evaluator, uint256 newAmount);
    event EvaluatorApproved(address indexed evaluator);
    event EvaluatorRemoved(address indexed evaluator);

    event EvaluationRequested(uint256 indexed evaluationId, uint256 indexed modelId, address indexed requester, bytes32 dataIpfsHash);
    event EvaluationSubmitted(uint256 indexed evaluationId, address indexed evaluator, int256 score);
    event EvaluationCompleted(uint256 indexed evaluationId, int256 finalScore); // Once challenge period passes or dispute resolved
    event EvaluationChallenged(uint256 indexed evaluationId, address indexed challenger, uint256 disputeId);

    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);

    // --- Constructor ---

    constructor(uint256 _marketplaceFeeBasisPoints, uint256 _evaluationFee, uint256 _minimumEvaluatorStake, uint256 _disputeStake, uint256 _disputeResolutionPeriod) Ownable(msg.sender) {
        require(_marketplaceFeeBasisPoints <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = _marketplaceFeeBasisPoints;
        evaluationFee = _evaluationFee;
        minimumEvaluatorStake = _minimumEvaluatorStake;
        disputeStake = _disputeStake;
        disputeResolutionPeriod = _disputeResolutionPeriod;
    }

    // --- Modifiers ---

    modifier onlyApprovedEvaluator() {
        require(approvedEvaluators[msg.sender], "Not an approved evaluator");
        _;
    }

    // --- Model Management Functions ---

    /**
     * @dev Registers a new AI model version on the marketplace.
     * @param _ipfsHash IPFS hash pointing to the model's metadata and files.
     * @param _name Model name.
     * @param _description Model description.
     * @param _version Model version number.
     * @param _price Initial price in wei (can be 0).
     */
    function registerModel(
        bytes32 _ipfsHash,
        string calldata _name,
        string calldata _description,
        uint256 _version,
        uint256 _price
    ) external whenNotPaused nonReentrant {
        uint256 modelId = nextModelId++;
        models[modelId] = Model({
            id: modelId,
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            name: _name,
            description: _description,
            version: _version,
            price: _price,
            isListed: false, // Not listed for sale by default
            isRetired: false,
            latestEvaluationId: 0,
            totalRatingsValue: 0,
            ratingCount: 0
        });
        userModels[msg.sender].push(modelId);

        emit ModelRegistered(modelId, msg.sender, _ipfsHash, _version, _name);
    }

    /**
     * @dev Allows the model owner to update metadata of an existing model version.
     * @param _modelId The ID of the model to update.
     * @param _ipfsHash New IPFS hash.
     * @param _description New description.
     */
    function updateModelDetails(uint256 _modelId, bytes32 _ipfsHash, string calldata _description) external whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(!model.isRetired, "Cannot update retired model");

        model.ipfsHash = _ipfsHash;
        model.description = _description;

        emit ModelUpdated(_modelId, _ipfsHash, model.name, _description);
    }

     /**
     * @dev Allows the model owner to update the price of an existing model version.
     * @param _modelId The ID of the model to update.
     * @param _newPrice New price in wei.
     */
    function updateModelPrice(uint256 _modelId, uint256 _newPrice) external whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(!model.isRetired, "Cannot update retired model");

        uint256 oldPrice = model.price;
        model.price = _newPrice;

        emit ModelPriceUpdated(_modelId, oldPrice, _newPrice);
    }

    /**
     * @dev Lists a registered model version for sale on the marketplace.
     * @param _modelId The ID of the model to list.
     */
    function listModel(uint256 _modelId) external whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(!model.isListed, "Model already listed");
        require(!model.isRetired, "Cannot list retired model");
        require(model.price > 0, "Price must be greater than 0 to list");

        model.isListed = true;

        emit ModelListed(_modelId, model.price);
    }

    /**
     * @dev Removes a listed model version from the marketplace.
     * @param _modelId The ID of the model to unlist.
     */
    function unlistModel(uint256 _modelId) external whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(model.isListed, "Model not listed");

        model.isListed = false;

        emit ModelUnlisted(_modelId);
    }

    /**
     * @dev Marks a model version as retired. Prevents new sales.
     * @param _modelId The ID of the model to retire.
     */
    function retireModel(uint256 _modelId) external whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Not model owner");
        require(!model.isRetired, "Model already retired");

        model.isListed = false; // Cannot be listed if retired
        model.isRetired = true;

        emit ModelRetired(_modelId);
    }

    // --- Marketplace Functions ---

    /**
     * @dev Allows a user to purchase access/license for a listed model version.
     * @param _modelId The ID of the model to purchase.
     */
    function buyModel(uint256 _modelId) external payable whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.isListed, "Model not listed for sale");
        require(model.price > 0, "Model price is zero");
        require(msg.value == model.price, "Incorrect payment amount");
        require(model.owner != msg.sender, "Cannot buy your own model");

        // Calculate fees
        uint256 marketplaceFee = (msg.value * marketplaceFeeBasisPoints) / 10000;
        uint256 ownerPayment = msg.value - marketplaceFee;

        // Transfer funds - nonReentrant guard helps protect against reentrancy
        (bool successOwner, ) = payable(model.owner).call{value: ownerPayment}("");
        require(successOwner, "Payment to owner failed");

        // Marketplace fees remain in contract balance, withdrawn by owner via withdrawMarketplaceFees

        // In a real system, this would grant access (e.g., via role, NFT, or access key delivery off-chain).
        // For this contract, we just record the purchase.
        // A mapping like `mapping(uint256 => mapping(address => bool)) public modelBuyers;` could track buyers.
        // modelBuyers[_modelId][msg.sender] = true; // Example if tracking buyers is needed on-chain

        model.isListed = false; // Models are 1-time sale licenses in this example (can be modified)

        emit ModelPurchased(_modelId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a model owner to withdraw their accumulated earnings.
     * @param _recipient The address to send the funds to.
     */
    function withdrawModelEarnings(address payable _recipient) external whenNotPaused nonReentrant {
        // This function requires a more complex tracking of earnings per model owner.
        // For simplicity here, funds paid to owners in buyModel are sent directly.
        // A production system would use a pull-based system with balances:
        // mapping(address => uint256) public ownerBalances;
        // In buyModel: ownerBalances[model.owner] += ownerPayment;
        // Here:
        // uint256 balance = ownerBalances[msg.sender];
        // require(balance > 0, "No earnings to withdraw");
        // ownerBalances[msg.sender] = 0;
        // (bool success, ) = _recipient.call{value: balance}("");
        // require(success, "Withdrawal failed");
        // emit ModelEarningsWithdrawn(0, msg.sender, balance); // ModelId 0 implies total earnings
        revert("Withdrawal system not implemented in this simplified version. Earnings are sent directly in buyModel."); // Placeholder
    }

    /**
     * @dev Allows the owner to withdraw collected marketplace fees.
     * @param _recipient The address to send the fees to.
     */
    function withdrawMarketplaceFees(address payable _recipient) external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        // This assumes all balance *not* explicitly sent to owners is marketplace fee.
        // A real system should track fee balance separately.
        // For this example, we'll just send the *entire* contract balance.
        // NOTE: This is overly simplistic and would include stakes etc.
        // A real system needs `uint256 public marketplaceFeeBalance;` updated in `buyModel`.
        // require(marketplaceFeeBalance > 0, "No fees to withdraw");
        // uint256 amount = marketplaceFeeBalance;
        // marketplaceFeeBalance = 0;
        // (bool success, ) = _recipient.call{value: amount}("");
        // require(success, "Fee withdrawal failed");
        // emit ModelEarningsWithdrawn(0, address(this), amount); // Use earnings event for simplicity, recipient is marketplace
        revert("Fee withdrawal system not implemented in this simplified version."); // Placeholder
    }

    // --- Evaluator Staking & Management Functions ---

    /**
     * @dev Allows a user to stake tokens to become eligible as an evaluator candidate.
     */
    function stakeAsEvaluator() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Must stake a positive amount");
        users[msg.sender].stakedAmount += msg.value;
        emit EvaluatorStaked(msg.sender, msg.value);
    }

    /**
     * @dev Allows an existing staker to increase their staked amount.
     */
    function increaseStake() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Must stake a positive amount");
        require(users[msg.sender].stakedAmount > 0, "Not an existing staker"); // Ensure they have staked before
        users[msg.sender].stakedAmount += msg.value;
        emit EvaluatorStakeIncreased(msg.sender, users[msg.sender].stakedAmount);
    }

     /**
     * @dev Allows an existing staker to decrease their stake.
     * @param _amount The amount to decrease the stake by.
     * @notice In a production system, this would likely involve a cooldown period.
     */
    function decreaseStake(uint256 _amount) external whenNotPaused nonReentrant {
        User storage user = users[msg.sender];
        require(user.stakedAmount >= _amount, "Insufficient staked amount");
        require(_amount > 0, "Cannot decrease by zero");

        // Cannot decrease below minimum if currently approved
        if (approvedEvaluators[msg.sender]) {
             require(user.stakedAmount - _amount >= minimumEvaluatorStake, "Cannot decrease stake below minimum for approved evaluators");
        }

        user.stakedAmount -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Stake withdrawal failed");

        if (user.stakedAmount == 0) {
             // Potentially remove from approved list if stake hits zero, or handle during removal.
             // For now, just update stake amount.
        }

        emit EvaluatorStakeDecreased(msg.sender, user.stakedAmount);
    }


    /**
     * @dev Owner approves a staked address to become an official evaluator.
     * @param _evaluator The address to approve.
     */
    function registerApprovedEvaluator(address _evaluator) external onlyOwner {
        require(users[_evaluator].stakedAmount >= minimumEvaluatorStake, "Evaluator does not meet minimum stake");
        require(!approvedEvaluators[_evaluator], "Address is already an approved evaluator");

        approvedEvaluators[_evaluator] = true;
        approvedEvaluatorList.push(_evaluator);

        emit EvaluatorApproved(_evaluator);
    }

    /**
     * @dev Owner removes an approved evaluator. Can be used if reputation is too low, etc.
     * @param _evaluator The address to remove.
     */
    function removeApprovedEvaluator(address _evaluator) external onlyOwner {
        require(approvedEvaluators[_evaluator], "Address is not an approved evaluator");

        approvedEvaluators[_evaluator] = false;

        // Simple list removal (inefficient for large lists, consider a different structure)
        for (uint i = 0; i < approvedEvaluatorList.length; i++) {
            if (approvedEvaluatorList[i] == _evaluator) {
                approvedEvaluatorList[i] = approvedEvaluatorList[approvedEvaluatorList.length - 1];
                approvedEvaluatorList.pop();
                break;
            }
        }

        // Optional: Slash stake or require withdrawal
        // If their stake falls below the minimum after removal, they can decrease it fully.

        emit EvaluatorRemoved(_evaluator);
    }

    // --- Evaluation Process Functions ---

    /**
     * @dev Requests an official performance evaluation for a model version.
     * @param _modelId The ID of the model version to evaluate.
     * @param _dataIpfsHash IPFS hash pointing to the dataset used for evaluation.
     */
    function requestEvaluation(uint256 _modelId, bytes32 _dataIpfsHash) external payable whenNotPaused nonReentrant {
        Model storage model = models[_modelId];
        require(model.id != 0, "Model does not exist"); // Check if model exists
        require(msg.value == evaluationFee, "Incorrect evaluation fee amount");
        // Add checks if the requester is the owner or a buyer, based on rules

        uint256 evaluationId = nextEvaluationId++;
        evaluations[evaluationId] = Evaluation({
            id: evaluationId,
            modelId: _modelId,
            requester: msg.sender,
            evaluator: address(0), // Evaluator assigned/submits later
            dataIpfsHash: _dataIpfsHash,
            score: 0, // Score submitted later
            status: EvaluationStatus.Pending,
            submittedTimestamp: 0, // Submitted timestamp later
            disputeId: 0,
            scoreFinalized: false
        });
        modelEvaluations[_modelId].push(evaluationId);

        // Potentially assign an evaluator here, or rely on evaluators picking up 'Pending' tasks off-chain.
        // For simplicity, we rely on off-chain processes to pick up the task and call submitEvaluationResult.

        emit EvaluationRequested(evaluationId, _modelId, msg.sender, _dataIpfsHash);
    }

    /**
     * @dev Allows an approved evaluator to submit the result of an evaluation.
     * @param _evaluationId The ID of the evaluation request.
     * @param _score The performance score obtained (e.g., accuracy * 100).
     */
    function submitEvaluationResult(uint256 _evaluationId, int256 _score) external onlyApprovedEvaluator whenNotPaused nonReentrant {
        Evaluation storage evaluation = evaluations[_evaluationId];
        require(evaluation.id != 0, "Evaluation does not exist");
        require(evaluation.status == EvaluationStatus.Pending, "Evaluation is not in Pending status");

        evaluation.evaluator = msg.sender;
        evaluation.score = _score;
        evaluation.submittedTimestamp = block.timestamp;
        evaluation.status = EvaluationStatus.Submitted;

        // Start a timer off-chain for the challenge period. After the period, if no challenge, mark as Completed.
        // This transition isn't handled automatically on-chain without keeper/oracle or manual trigger.
        // A simple approach could be a function `finalizeEvaluation(uint256 _evaluationId)` callable after period ends.

        emit EvaluationSubmitted(_evaluationId, msg.sender, _score);
    }

    // function finalizeEvaluation(uint256 _evaluationId) external nonReentrant {
    //     Evaluation storage evaluation = evaluations[_evaluationId];
    //     require(evaluation.id != 0, "Evaluation does not exist");
    //     require(evaluation.status == EvaluationStatus.Submitted, "Evaluation not in Submitted status");
    //     // require(block.timestamp >= evaluation.submittedTimestamp + challengePeriod, "Challenge period not over");
    //     require(evaluation.disputeId == 0, "Evaluation is under dispute");

    //     evaluation.status = EvaluationStatus.Completed;
    //     evaluation.scoreFinalized = true;

    //     // Update model's aggregate rating (simplified)
    //     Model storage model = models[evaluation.modelId];
    //     model.totalRatingsValue += uint256(evaluation.score); // Caution: converting int256 to uint256 - needs careful handling for negative scores
    //     model.ratingCount++;
    //     model.latestEvaluationId = _evaluationId;

    //     emit EvaluationCompleted(_evaluationId, evaluation.score);
    // }


    // --- Dispute Resolution Functions ---

    /**
     * @dev Allows a user to challenge a submitted evaluation result.
     * Requires staking a certain amount.
     * @param _evaluationId The ID of the evaluation to challenge.
     */
    function challengeEvaluation(uint256 _evaluationId) external payable whenNotPaused nonReentrant {
        Evaluation storage evaluation = evaluations[_evaluationId];
        require(evaluation.id != 0, "Evaluation does not exist");
        require(evaluation.status == EvaluationStatus.Submitted, "Evaluation is not in Submitted status (must be submitted and not yet disputed)");
        require(msg.value == disputeStake, "Incorrect dispute stake amount");
        // require(block.timestamp < evaluation.submittedTimestamp + challengePeriod, "Challenge period has ended"); // Needs challenge period logic

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            evaluationId: _evaluationId,
            challenger: msg.sender,
            challengerStake: msg.value,
            status: DisputeStatus.Open,
            disputeRaisedTimestamp: block.timestamp,
            resolutionTimestamp: 0,
             // resolutionOutcome: "" // Requires storing outcome description
        });

        evaluation.status = EvaluationStatus.Disputed;
        evaluation.disputeId = disputeId;

        // Evaluator stake might also be locked here depending on system design
        // users[evaluation.evaluator].stakedAmount -= evaluation.stakeLockedForDispute; // Example

        emit EvaluationChallenged(_evaluationId, msg.sender, disputeId);
    }

    /**
     * @dev Owner (or future governance) resolves an open dispute.
     * This is a critical function affecting stakes and reputation.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolutionOutcome Integer representing the resolution: 0=Invalid Challenge, 1=Valid Challenge.
     */
    function resolveDispute(uint256 _disputeId, uint256 _resolutionOutcome) external onlyOwner nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");
        require(block.timestamp >= dispute.disputeRaisedTimestamp + disputeResolutionPeriod, "Dispute resolution period not over"); // Example: must wait a period

        Evaluation storage evaluation = evaluations[dispute.evaluationId];
        address evaluator = evaluation.evaluator;
        address challenger = dispute.challenger;

        dispute.resolutionTimestamp = block.timestamp;
        evaluation.scoreFinalized = true; // Score is finalized after dispute

        if (_resolutionOutcome == 0) { // Invalid Challenge
            dispute.status = DisputeStatus.ResolvedInvalid;
            evaluation.status = EvaluationStatus.Completed; // Evaluator's score is upheld

            // Slash challenger's stake (or a portion) and/or reward evaluator/marketplace
            uint256 penalty = dispute.challengerStake; // Simple slash all
            users[challenger].stakedAmount -= penalty; // This assumes stake was held. If stake was sent to contract balance, handle transfer.
            // e.g., (bool success, ) = payable(address(this)).call{value: penalty}(""); // if stake was sent to contract initially

            // Optional: Reward evaluator from slashed stake or fee pool
            // (bool successReward, ) = payable(evaluator).call{value: rewardAmount}("");

            // Update reputation: Increase evaluator rep, decrease challenger rep
            users[evaluator].reputationScore += 10; // Example points
            users[challenger].reputationScore -= 10; // Example points

            emit DisputeResolved(_disputeId, DisputeStatus.ResolvedInvalid);

        } else if (_resolutionOutcome == 1) { // Valid Challenge
            dispute.status = DisputeStatus.ResolvedValid;
            evaluation.status = EvaluationStatus.Resolved; // Evaluation marked as resolved (invalid)

            // Slash evaluator's stake (or a portion) and/or reward challenger/marketplace
            // Needs stake tracking for evaluators during evaluation/dispute
            // users[evaluator].stakedAmount -= penaltyAmount; // Example

            // Return challenger's stake
            (bool successReturn, ) = payable(challenger).call{value: dispute.challengerStake}("");
            require(successReturn, "Challenger stake return failed");

            // Update reputation: Decrease evaluator rep, increase challenger rep
            users[evaluator].reputationScore -= 10; // Example points
            users[challenger].reputationScore += 10; // Example points

            emit DisputeResolved(_disputeId, DisputeStatus.ResolvedValid);

        } else {
            revert("Invalid resolution outcome");
        }

        // Update model's aggregate rating if the evaluation result was upheld (ResolvedInvalid case)
        if (dispute.status == DisputeStatus.ResolvedInvalid) {
            Model storage model = models[evaluation.modelId];
            // Add score carefully if int256 was used, considering negatives
             if (evaluation.score >= 0) {
                model.totalRatingsValue += uint256(evaluation.score);
            } else {
                // Handle negative scores affecting the sum differently, e.g., subtract magnitude
                // model.totalRatingsValue -= uint256(-evaluation.score); // Or just skip/cap negative ratings
            }
            model.ratingCount++;
            model.latestEvaluationId = dispute.evaluationId; // Reference the upheld evaluation
            emit EvaluationCompleted(dispute.evaluationId, evaluation.score); // Emit completion for the upheld evaluation
        } else {
             // If challenge was valid, the evaluation is not considered "Completed" successfully for rating aggregation
             emit EvaluationCompleted(dispute.evaluationId, 0); // Or some other indicator that score is invalid/discarded
        }
    }

    // --- Reputation Functions ---

    /**
     * @dev Gets the basic reputation score for a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (int256) {
        return users[_user].reputationScore;
    }

    // --- Utility/View Functions ---

    /**
     * @dev Gets details of a specific model version.
     * @param _modelId The ID of the model.
     * @return Model struct data.
     */
    function getModelDetails(uint256 _modelId) external view returns (Model memory) {
        return models[_modelId];
    }

    /**
     * @dev Gets a list of model IDs owned by a user.
     * @param _owner The address of the owner.
     * @return An array of model IDs.
     */
    function getUserModels(address _owner) external view returns (uint256[] memory) {
        return userModels[_owner];
    }

    /**
     * @dev Gets details of a specific evaluation request.
     * @param _evaluationId The ID of the evaluation.
     * @return Evaluation struct data.
     */
    function getEvaluationDetails(uint256 _evaluationId) external view returns (Evaluation memory) {
        return evaluations[_evaluationId];
    }

     /**
     * @dev Gets details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct data.
     */
    function getDisputeDetails(uint256 _disputeId) external view returns (Dispute memory) {
        return disputes[_disputeId];
    }


    /**
     * @dev Gets the current staked amount for a user.
     * @param _user The address of the user.
     * @return The staked amount in wei.
     */
    function getUserStake(address _user) external view returns (uint256) {
        return users[_user].stakedAmount;
    }

    /**
     * @dev Gets the total number of models registered.
     * @return The total count of models.
     */
    function getTotalModels() external view returns (uint256) {
        return nextModelId - 1;
    }

    /**
     * @dev Gets a list of all currently listed model IDs.
     * @notice This can be gas intensive if many models are listed. Better to use off-chain indexing.
     * @return An array of listed model IDs.
     */
    function getListedModels() external view returns (uint256[] memory) {
        uint256[] memory listedModels;
        uint256 count = 0;
        // First pass to count
        for (uint256 i = 1; i < nextModelId; i++) {
            if (models[i].isListed) {
                count++;
            }
        }

        // Second pass to populate
        listedModels = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 1; i < nextModelId; i++) {
            if (models[i].isListed) {
                listedModels[index] = i;
                index++;
            }
        }
        return listedModels;
    }


    // --- Admin Functions ---

    /**
     * @dev Sets the marketplace fee percentage.
     * @param _feeBasisPoints Fee as basis points (e.g., 100 = 1%). Max 10000.
     */
    function setMarketplaceFee(uint256 _feeBasisPoints) external onlyOwner {
        require(_feeBasisPoints <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = _feeBasisPoints;
    }

    /**
     * @dev Sets the fee required to request a model evaluation.
     * @param _fee Fee amount in wei.
     */
    function setEvaluationFee(uint256 _fee) external onlyOwner {
        evaluationFee = _fee;
    }

    /**
     * @dev Sets the minimum stake required for an address to be approved as an evaluator.
     * @param _stake Amount in wei.
     */
    function setMinimumEvaluatorStake(uint256 _stake) external onlyOwner {
        minimumEvaluatorStake = _stake;
    }

     /**
     * @dev Sets the stake required to challenge an evaluation result.
     * @param _stake Amount in wei.
     */
    function setDisputeStake(uint256 _stake) external onlyOwner {
        disputeStake = _stake;
    }

     /**
     * @dev Sets the period (in seconds) for dispute resolution by the owner/governance.
     * @param _period Time in seconds.
     */
    function setDisputeResolutionPeriod(uint256 _period) external onlyOwner {
        disputeResolutionPeriod = _period;
    }


    // --- Pausable Functions ---
    // Inherited from Pausable: pause(), unpause()
    // Add `whenNotPaused` modifier to functions affected by pausing.

    // Note: This contract requires significant off-chain components (IPFS for data/models,
    // evaluation runners, potentially dispute arbiters or decentralized governance).
    // The on-chain contract manages state, payments, staking, evaluation requests, and dispute outcomes.
    // The complexity of dispute resolution (slashing logic, evidence handling, oracle integration)
    // is simplified here but would be crucial in a production system.
}
```