Okay, here is a smart contract concept focusing on a Decentralized AI Model Registry with advanced features like performance tracking, licensing, and a challenge system. This aims to be creative by integrating multiple decentralized aspects related to managing off-chain AI models on-chain.

It avoids directly copying standard OpenZeppelin contracts by implementing basic ownership and pausing logic manually, and the core logic around model registration, performance metrics, licensing, and challenges is custom to this concept.

---

**Outline and Function Summary**

**Contract Name:** DecentralizedAIModelRegistry

**Description:** A smart contract platform for registering, tracking performance, licensing access to, and challenging decentralized AI models. Developers can register models, evaluators can submit performance metrics, users can purchase licenses, and challengers can initiate and resolve disputes or propose improvements.

**Core Concepts:**
*   **Model Registration:** Developers formally list their off-chain AI models on-chain.
*   **Performance Tracking:** Mechanisms to record and verify performance metrics submitted by evaluators.
*   **Licensing:** On-chain management of model access licenses, potentially linked to payment.
*   **Challenge System:** A structured process for disputing model claims or proposing superior alternatives, involving stakes and evaluation.
*   **Economics:** Handling of fees, stakes, rewards, and developer payouts.
*   **Access Control:** Differentiated roles for Owner, Developers, Trusted Evaluators, and Users.

**Data Structures:**
*   `Model`: Represents a registered AI model.
*   `PerformanceMetric`: Stores a specific performance data point for a model.
*   `License`: Tracks an active license for a user to access a model.
*   `Challenge`: Details of an ongoing or resolved challenge against a model.
*   `ChallengeEvaluation`: Records an evaluation result for a specific challenge.

**Events:**
*   `ModelRegistered`
*   `ModelUpdated`
*   `PerformanceMetricSubmitted`
*   `LicensePurchased`
*   `LicenseRevoked`
*   `ChallengeInitiated`
*   `ChallengeEvaluationSubmitted`
*   `ChallengeResolved`
*   `FundsWithdrawn`
*   `TrustedEvaluatorAdded`
*   `TrustedEvaluatorRemoved`
*   `ContractPaused`
*   `ContractUnpaused`
*   `ProtocolFeeUpdated`

**Modifiers:**
*   `onlyOwner`: Restricts function access to the contract owner.
*   `whenNotPaused`: Prevents function execution when the contract is paused.
*   `whenPaused`: Allows function execution only when the contract is paused.
*   `onlyDeveloper`: Restricts function access to the owner of a specific model.
*   `onlyTrustedEvaluator`: Restricts function access to addresses designated as trusted evaluators.

**Function Summary (27 Functions):**

1.  `constructor()`: Initializes the contract owner.
2.  `pauseContract()`: Pauses critical contract functions (only owner).
3.  `unpauseContract()`: Unpauses the contract (only owner).
4.  `registerModel(string memory name, string memory description, string memory modelURI, uint256 initialLicenseType)`: Registers a new AI model (anyone can register, becomes the model's developer).
5.  `updateModelURI(uint256 modelId, string memory newModelURI)`: Updates the storage URI of a registered model (only developer).
6.  `updateModelDescription(uint256 modelId, string memory newDescription)`: Updates the description of a model (only developer).
7.  `updateModelParameters(uint256 modelId, bytes memory newParameters)`: Updates model-specific configuration parameters (only developer).
8.  `updateModelLicenseType(uint256 modelId, uint256 newLicenseType)`: Changes the primary license type offered for a model (only developer).
9.  `getModelDetails(uint256 modelId)`: Retrieves detailed information about a model.
10. `listModelsByDeveloper(address developer)`: Lists all model IDs owned by a specific developer.
11. `submitPerformanceMetric(uint256 modelId, string memory metricType, int256 value, string memory proofURI)`: Submits a performance metric for a model (anyone, potentially with future reputation/staking).
12. `getPerformanceMetricCount(uint256 modelId)`: Gets the total number of performance metrics submitted for a model.
13. `getPerformanceMetricAtIndex(uint256 modelId, uint256 index)`: Retrieves a specific performance metric by index.
14. `setLicenseTerms(uint256 modelId, uint256 licenseType, uint256 price, uint256 duration)`: Defines or updates the terms for a specific license type for a model (only developer).
15. `getLicenseTerms(uint256 modelId, uint256 licenseType)`: Retrieves the terms for a specific license type.
16. `purchaseLicense(uint256 modelId, uint256 licenseType)`: Purchases a license for a model (payable, user becomes licensee).
17. `getUserLicenseStatus(uint256 modelId, address user)`: Checks if a user holds a valid, active license for a model.
18. `revokeLicense(uint256 modelId, address user)`: Revokes an active license for a user (only developer, terms for this capability would be defined off-chain or in license data).
19. `initiateChallenge(uint256 modelId, string memory challengeDetailsURI, uint256 stakeAmount)`: Initiates a challenge against a model, requiring a stake (payable).
20. `submitChallengeEvaluation(uint256 challengeId, bool isValid, string memory evaluationProofURI)`: A trusted evaluator submits their assessment of a challenge.
21. `resolveChallenge(uint256 challengeId)`: Resolves a challenge based on the evaluations received (owner or automated after threshold/time). Distributes/slashes stakes.
22. `getChallengeDetails(uint256 challengeId)`: Retrieves details about a specific challenge.
23. `listChallengesForModel(uint256 modelId)`: Lists all challenge IDs associated with a model.
24. `addTrustedEvaluator(address evaluator)`: Adds an address to the list of trusted evaluators for challenges (only owner).
25. `removeTrustedEvaluator(address evaluator)`: Removes an address from the trusted evaluators list (only owner).
26. `withdrawDeveloperFunds(uint256 modelId)`: Allows a model developer to withdraw earned revenue from licenses (only developer).
27. `withdrawProtocolFees()`: Allows the contract owner to withdraw collected protocol fees (only owner).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelRegistry
 * @dev A smart contract for registering, tracking performance, licensing, and challenging AI models.
 *
 * Outline:
 * - Basic ownership and pausable logic (manual implementation)
 * - Data structures for Models, Performance Metrics, Licenses, Challenges
 * - Events for state changes
 * - Modifiers for access control
 * - Core functions for registration, updates, queries
 * - Performance tracking submission and retrieval
 * - Licensing purchase and management
 * - Challenge initiation, evaluation, and resolution
 * - Economic functions for withdrawals
 * - Admin functions for trusted evaluators and pausing
 *
 * Function Summary:
 * - constructor(): Sets contract owner.
 * - pauseContract(): Pauses critical functions.
 * - unpauseContract(): Unpauses functions.
 * - registerModel(): Registers a new model.
 * - updateModelURI(): Updates model URI.
 * - updateModelDescription(): Updates model description.
 * - updateModelParameters(): Updates model parameters.
 * - updateModelLicenseType(): Updates model license type.
 * - getModelDetails(): Get model details.
 * - listModelsByDeveloper(): List models by developer.
 * - submitPerformanceMetric(): Submit model performance data.
 * - getPerformanceMetricCount(): Get count of metrics for a model.
 * - getPerformanceMetricAtIndex(): Get a specific metric entry.
 * - setLicenseTerms(): Define license terms for a model.
 * - getLicenseTerms(): Get license terms.
 * - purchaseLicense(): Buy a model license (payable).
 * - getUserLicenseStatus(): Check if a user has a valid license.
 * - revokeLicense(): Revoke a user's license.
 * - initiateChallenge(): Start a challenge against a model (payable).
 * - submitChallengeEvaluation(): Submit evaluation for a challenge (only trusted evaluator).
 * - resolveChallenge(): Finalize a challenge.
 * - getChallengeDetails(): Get challenge details.
 * - listChallengesForModel(): List challenges for a model.
 * - addTrustedEvaluator(): Add trusted evaluator (only owner).
 * - removeTrustedEvaluator(): Remove trusted evaluator (only owner).
 * - withdrawDeveloperFunds(): Developer withdraws earnings.
 * - withdrawProtocolFees(): Owner withdraws protocol fees.
 */
contract DecentralizedAIModelRegistry {

    address private _owner;
    bool private _paused;

    uint256 private _modelCounter;
    uint256 private _challengeCounter;

    // --- Data Structures ---

    enum LicenseType {
        Free,
        PaidPerUse,
        PaidSubscription,
        Custom
    }

    enum ChallengeOutcome {
        Pending,
        Valid,
        Invalid,
        ResolvedValid,
        ResolvedInvalid
    }

    struct Model {
        address developer;
        string name;
        string description;
        string modelURI; // URI pointing to model details, code, documentation off-chain
        bytes parameters; // General purpose field for model config
        LicenseType primaryLicenseType;
        uint256 registeredTimestamp;
    }

    struct PerformanceMetric {
        uint256 modelId;
        address submitter;
        string metricType; // e.g., "accuracy", "latency", "f1-score"
        int256 value; // Metric value (scaled if needed, e.g., percentage * 100)
        string proofURI; // URI pointing to evaluation results, dataset, code
        uint256 submittedTimestamp;
    }

    struct LicenseTerms {
        uint256 price; // Price in wei
        uint256 duration; // Duration in seconds (for subscription types)
        string termsURI; // URI pointing to detailed off-chain terms
    }

    struct License {
        uint256 modelId;
        address licensee;
        LicenseType licenseType;
        uint256 purchaseTimestamp;
        uint256 expirationTimestamp; // 0 for non-expiring (like PaidPerUse initial grant)
        bool active; // Can be set false on revocation
    }

    struct Challenge {
        uint256 modelId;
        address challenger;
        uint256 stakeAmount; // Amount staked by challenger
        string detailsURI; // URI pointing to challenge specifics, evidence
        uint256 initiatedTimestamp;
        ChallengeOutcome outcome;
        uint256 resolutionTimestamp;
        uint256 totalEvaluations; // Count of submitted evaluations
        uint256 validEvaluations; // Count of evaluations marking challenge as valid
    }

    struct ChallengeEvaluation {
        uint256 challengeId;
        address evaluator;
        bool isValid; // Evaluator's assessment
        string proofURI; // URI pointing to evaluation details, methodology
        uint256 submittedTimestamp;
    }

    // --- State Variables ---

    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) private _developerModels; // Developer address to list of model IDs

    mapping(uint256 => PerformanceMetric[]) private _modelPerformanceMetrics; // Model ID to list of metrics
    mapping(uint256 => mapping(string => PerformanceMetric[])) private _modelMetricsByType; // Model ID to metric type to list of metrics (alternative access)

    mapping(uint256 => mapping(uint256 => LicenseTerms)) private _modelLicenseTerms; // Model ID to LicenseType to terms
    mapping(uint256 => mapping(address => License)) private _userModelLicense; // Model ID to user address to active license (simplified: only one active license per user per model)

    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => ChallengeEvaluation[]) private _challengeEvaluations; // Challenge ID to list of evaluations
    mapping(uint256 => uint256[]) private _modelChallenges; // Model ID to list of challenge IDs

    mapping(address => bool) private _trustedEvaluators; // Addresses allowed to submit challenge evaluations

    mapping(address => uint256) private _developerBalances; // Funds earned by developers
    uint256 private _protocolFeePercentage; // e.g., 500 = 5% (stored as basis points)
    uint256 private _protocolFeeBalance; // Funds collected as protocol fees

    // --- Events ---

    event ModelRegistered(uint256 modelId, address developer, string name, string modelURI, uint256 timestamp);
    event ModelUpdated(uint256 modelId, address developer, string field, string value, uint256 timestamp); // Generic update event
    event PerformanceMetricSubmitted(uint256 modelId, address submitter, string metricType, int256 value, uint256 timestamp);
    event LicenseTermsUpdated(uint256 modelId, uint256 licenseType, uint256 price, uint256 duration);
    event LicensePurchased(uint256 modelId, address licensee, uint256 licenseType, uint256 purchaseTimestamp, uint256 expirationTimestamp, uint256 pricePaid);
    event LicenseRevoked(uint256 modelId, address revokedBy, address licensee, uint256 timestamp);
    event ChallengeInitiated(uint256 challengeId, uint256 modelId, address challenger, uint256 stakeAmount, uint256 timestamp);
    event ChallengeEvaluationSubmitted(uint256 challengeId, address evaluator, bool isValid, uint256 timestamp);
    event ChallengeResolved(uint256 challengeId, ChallengeOutcome outcome, uint256 resolutionTimestamp, uint256 redistributedAmount);
    event FundsWithdrawn(address recipient, uint256 amount, uint256 timestamp);
    event TrustedEvaluatorAdded(address evaluator);
    event TrustedEvaluatorRemoved(address evaluator);
    event ContractPaused(uint256 timestamp);
    event ContractUnpaused(uint256 timestamp);
    event ProtocolFeeUpdated(uint256 newPercentage);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyDeveloper(uint256 modelId) {
        require(models[modelId].developer != address(0), "Model does not exist");
        require(msg.sender == models[modelId].developer, "Only model developer can call");
        _;
    }

    modifier onlyTrustedEvaluator() {
        require(_trustedEvaluators[msg.sender], "Only trusted evaluators can call");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _paused = false;
        _modelCounter = 0;
        _challengeCounter = 0;
        _protocolFeePercentage = 0; // Initially no fee
    }

    // --- Admin Functions ---

    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit ContractPaused(block.timestamp);
    }

    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit ContractUnpaused(block.timestamp);
    }

    function addTrustedEvaluator(address evaluator) external onlyOwner whenNotPaused {
        require(evaluator != address(0), "Evaluator address cannot be zero");
        _trustedEvaluators[evaluator] = true;
        emit TrustedEvaluatorAdded(evaluator);
    }

    function removeTrustedEvaluator(address evaluator) external onlyOwner whenNotPaused {
        require(evaluator != address(0), "Evaluator address cannot be zero");
        _trustedEvaluators[evaluator] = false;
        emit TrustedEvaluatorRemoved(evaluator);
    }

    function isTrustedEvaluator(address evaluator) external view returns (bool) {
        return _trustedEvaluators[evaluator];
    }

    function setProtocolFeePercentage(uint256 percentageBasisPoints) external onlyOwner whenNotPaused {
        require(percentageBasisPoints <= 10000, "Fee percentage cannot exceed 100%"); // 10000 basis points = 100%
        _protocolFeePercentage = percentageBasisPoints;
        emit ProtocolFeeUpdated(percentageBasisPoints);
    }

    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = _protocolFeeBalance;
        _protocolFeeBalance = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FundsWithdrawn(msg.sender, amount, block.timestamp);
    }


    // --- Model Registration & Management Functions ---

    function registerModel(string memory name, string memory description, string memory modelURI, uint256 initialLicenseType)
        external
        whenNotPaused
        returns (uint256 modelId)
    {
        _modelCounter++;
        modelId = _modelCounter;

        models[modelId] = Model({
            developer: msg.sender,
            name: name,
            description: description,
            modelURI: modelURI,
            parameters: "", // Initially empty, developer can update
            primaryLicenseType: LicenseType(initialLicenseType),
            registeredTimestamp: block.timestamp
        });

        _developerModels[msg.sender].push(modelId);

        emit ModelRegistered(modelId, msg.sender, name, modelURI, block.timestamp);
    }

    function updateModelURI(uint256 modelId, string memory newModelURI) external onlyDeveloper(modelId) whenNotPaused {
        models[modelId].modelURI = newModelURI;
        emit ModelUpdated(modelId, msg.sender, "modelURI", newModelURI, block.timestamp);
    }

    function updateModelDescription(uint256 modelId, string memory newDescription) external onlyDeveloper(modelId) whenNotPaused {
        models[modelId].description = newDescription;
        emit ModelUpdated(modelId, msg.sender, "description", newDescription, block.timestamp);
    }

    function updateModelParameters(uint256 modelId, bytes memory newParameters) external onlyDeveloper(modelId) whenNotPaused {
        models[modelId].parameters = newParameters;
        emit ModelUpdated(modelId, msg.sender, "parameters", "bytes updated", block.timestamp); // Cannot log bytes value easily
    }

    function updateModelLicenseType(uint256 modelId, uint256 newLicenseType) external onlyDeveloper(modelId) whenNotPaused {
        require(newLicenseType <= uint256(LicenseType.Custom), "Invalid license type");
        models[modelId].primaryLicenseType = LicenseType(newLicenseType);
        emit ModelUpdated(modelId, msg.sender, "primaryLicenseType", uint256(LicenseType(newLicenseType)).toString(), block.timestamp); // uint256 to string requires helper/library
    }

    // Helper function to convert uint to string for logging - basic implementation
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Performance Tracking Functions ---

    function submitPerformanceMetric(uint256 modelId, string memory metricType, int256 value, string memory proofURI)
        external
        whenNotPaused
    {
        require(models[modelId].developer != address(0), "Model does not exist");

        PerformanceMetric memory newMetric = PerformanceMetric({
            modelId: modelId,
            submitter: msg.sender,
            metricType: metricType,
            value: value,
            proofURI: proofURI,
            submittedTimestamp: block.timestamp
        });

        _modelPerformanceMetrics[modelId].push(newMetric);
        _modelMetricsByType[modelId][metricType].push(newMetric); // Store by type as well

        emit PerformanceMetricSubmitted(modelId, msg.sender, metricType, value, block.timestamp);

        // Future improvement: Add logic here for rewarding submitters, reputation, data verification
    }

    function getPerformanceMetricCount(uint256 modelId) external view returns (uint256) {
        return _modelPerformanceMetrics[modelId].length;
    }

     // Get count of metrics for a specific type
    function getPerformanceMetricCountByType(uint256 modelId, string memory metricType) external view returns (uint256) {
        return _modelMetricsByType[modelId][metricType].length;
    }

    function getPerformanceMetricAtIndex(uint256 modelId, uint256 index)
        external
        view
        returns (
            address submitter,
            string memory metricType,
            int256 value,
            string memory proofURI,
            uint256 submittedTimestamp
        )
    {
        require(index < _modelPerformanceMetrics[modelId].length, "Index out of bounds");
        PerformanceMetric storage metric = _modelPerformanceMetrics[modelId][index];
        return (metric.submitter, metric.metricType, metric.value, metric.proofURI, metric.submittedTimestamp);
    }

     // Get a specific metric of a specific type by index
     function getPerformanceMetricByTypeAtIndex(uint256 modelId, string memory metricType, uint256 index)
        external
        view
        returns (
            address submitter,
            string memory mType, // Renamed to avoid name clash
            int256 value,
            string memory proofURI,
            uint256 submittedTimestamp
        )
    {
        require(index < _modelMetricsByType[modelId][metricType].length, "Index out of bounds for type");
        PerformanceMetric storage metric = _modelMetricsByType[modelId][metricType][index];
        return (metric.submitter, metric.metricType, metric.value, metric.proofURI, metric.submittedTimestamp);
    }


    // --- Licensing Functions ---

    function setLicenseTerms(uint256 modelId, uint256 licenseType, uint256 price, uint256 duration, string memory termsURI)
        external
        onlyDeveloper(modelId)
        whenNotPaused
    {
        require(licenseType <= uint256(LicenseType.Custom), "Invalid license type");
        require(price > 0 || LicenseType(licenseType) == LicenseType.Free, "Price must be > 0 for paid licenses");
        require(duration > 0 || LicenseType(licenseType) != LicenseType.PaidSubscription, "Duration must be > 0 for subscription licenses");

        _modelLicenseTerms[modelId][licenseType] = LicenseTerms({
            price: price,
            duration: duration,
            termsURI: termsURI
        });

        emit LicenseTermsUpdated(modelId, licenseType, price, duration);
    }

    function getLicenseTerms(uint256 modelId, uint256 licenseType)
        external
        view
        returns (uint256 price, uint256 duration, string memory termsURI)
    {
        require(models[modelId].developer != address(0), "Model does not exist");
        require(licenseType <= uint256(LicenseType.Custom), "Invalid license type");
        LicenseTerms storage terms = _modelLicenseTerms[modelId][licenseType];
        return (terms.price, terms.duration, terms.termsURI);
    }

    function purchaseLicense(uint256 modelId, uint256 licenseType)
        external
        payable
        whenNotPaused
    {
        require(models[modelId].developer != address(0), "Model does not exist");
        require(licenseType <= uint256(LicenseType.Custom), "Invalid license type");

        LicenseTerms storage terms = _modelLicenseTerms[modelId][licenseType];
        require(msg.value >= terms.price, "Insufficient payment");

        // Calculate protocol fee
        uint256 protocolFee = (msg.value * _protocolFeePercentage) / 10000;
        uint256 developerRevenue = msg.value - protocolFee;

        // Distribute funds
        _developerBalances[models[modelId].developer] += developerRevenue;
        _protocolFeeBalance += protocolFee;

        uint256 expiration = 0;
        if (LicenseType(licenseType) == LicenseType.PaidSubscription && terms.duration > 0) {
            expiration = block.timestamp + terms.duration;
        }
        // For Free/PaidPerUse, expiration is effectively 0 or managed off-chain/by revocation

        _userModelLicense[modelId][msg.sender] = License({
            modelId: modelId,
            licensee: msg.sender,
            licenseType: LicenseType(licenseType),
            purchaseTimestamp: block.timestamp,
            expirationTimestamp: expiration,
            active: true
        });

        emit LicensePurchased(modelId, msg.sender, licenseType, block.timestamp, expiration, msg.value);

        // Refund excess if any
        if (msg.value > terms.price) {
             (bool success, ) = msg.sender.call{value: msg.value - terms.price}("");
             require(success, "Refund failed"); // Consider alternative error handling
        }
    }

    function getUserLicenseStatus(uint256 modelId, address user) external view returns (bool isActive, uint256 expirationTimestamp) {
        require(models[modelId].developer != address(0), "Model does not exist");
        License storage license = _userModelLicense[modelId][user];

        if (license.modelId == modelId && license.active) {
            if (license.expirationTimestamp == 0) {
                // Non-expiring license type (e.g., Free, PaidPerUse grant)
                return (true, 0);
            } else if (block.timestamp < license.expirationTimestamp) {
                // Subscription license still active
                return (true, license.expirationTimestamp);
            } else {
                // Subscription license expired
                return (false, license.expirationTimestamp);
            }
        }
        // License not found or not active
        return (false, license.expirationTimestamp); // Return stored expiration even if inactive for context
    }

    function revokeLicense(uint256 modelId, address user) external onlyDeveloper(modelId) whenNotPaused {
        License storage license = _userModelLicense[modelId][user];
        require(license.modelId == modelId && license.active, "User does not have an active license for this model");

        license.active = false; // Mark as inactive

        emit LicenseRevoked(modelId, msg.sender, user, block.timestamp);

        // Note: Terms of revocation (e.g., refunds) would likely be off-chain based on the termsURI
    }

     // Retrieve developer's current balance from license sales
    function getDeveloperBalance(address developer) external view returns (uint256) {
        return _developerBalances[developer];
    }

    // Developer withdraws accumulated funds
    function withdrawDeveloperFunds(uint256 modelId) external onlyDeveloper(modelId) {
        address developer = models[modelId].developer; // Ensure developer address comes from the model struct
        uint256 amount = _developerBalances[developer];
        require(amount > 0, "No balance to withdraw");

        _developerBalances[developer] = 0;

        (bool success, ) = payable(developer).call{value: amount}("");
        require(success, "Withdrawal failed"); // Consider alternative error handling on failure

        emit FundsWithdrawn(developer, amount, block.timestamp);
    }


    // --- Challenge System Functions ---

    function initiateChallenge(uint256 modelId, string memory challengeDetailsURI)
        external
        payable
        whenNotPaused
        returns (uint256 challengeId)
    {
        require(models[modelId].developer != address(0), "Model does not exist");
        require(msg.value > 0, "Challenge requires a non-zero stake");

        _challengeCounter++;
        challengeId = _challengeCounter;

        challenges[challengeId] = Challenge({
            modelId: modelId,
            challenger: msg.sender,
            stakeAmount: msg.value,
            detailsURI: challengeDetailsURI,
            initiatedTimestamp: block.timestamp,
            outcome: ChallengeOutcome.Pending,
            resolutionTimestamp: 0,
            totalEvaluations: 0,
            validEvaluations: 0
        });

        _modelChallenges[modelId].push(challengeId);

        emit ChallengeInitiated(challengeId, modelId, msg.sender, msg.value, block.timestamp);
    }

    function submitChallengeEvaluation(uint256 challengeId, bool isValid, string memory evaluationProofURI)
        external
        onlyTrustedEvaluator
        whenNotPaused
    {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.modelId != 0, "Challenge does not exist");
        require(challenge.outcome == ChallengeOutcome.Pending, "Challenge is not pending");

        // Prevent duplicate evaluations from the same evaluator for the same challenge
        // This simple implementation requires iterating - could be optimized with a mapping if many evaluators
        for (uint i = 0; i < _challengeEvaluations[challengeId].length; i++) {
            require(_challengeEvaluations[challengeId][i].evaluator != msg.sender, "Evaluator already submitted for this challenge");
        }


        _challengeEvaluations[challengeId].push(ChallengeEvaluation({
            challengeId: challengeId,
            evaluator: msg.sender,
            isValid: isValid,
            proofURI: evaluationProofURI,
            submittedTimestamp: block.timestamp
        }));

        challenge.totalEvaluations++;
        if (isValid) {
            challenge.validEvaluations++;
        }

        emit ChallengeEvaluationSubmitted(challengeId, msg.sender, isValid, block.timestamp);

        // Future Improvement: Add logic here for minimum required evaluations before resolution is possible
    }

    function resolveChallenge(uint256 challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.modelId != 0, "Challenge does not exist");
        require(challenge.outcome == ChallengeOutcome.Pending, "Challenge is not pending");
        // Require a minimum number of evaluations before resolution
        require(challenge.totalEvaluations >= 1, "Not enough evaluations to resolve"); // Placeholder: requires at least 1 eval

        // Determine outcome based on evaluations (simple majority rule example)
        bool challengeDeemedValid = (challenge.validEvaluations * 2) > challenge.totalEvaluations;

        uint256 amountToRedistribute = challenge.stakeAmount;
        address recipient = address(0); // Placeholder for recipient address

        if (challengeDeemedValid) {
            challenge.outcome = ChallengeOutcome.ResolvedValid;
            // Reward trusted evaluators? Sslash developer? Promote challenger's model?
            // Simple: Challenger gets stake back + potentially reward from slashing (not implemented)
            // Developer's model might be flagged or require updates off-chain
             recipient = challenge.challenger; // Return stake to challenger
        } else {
            challenge.outcome = ChallengeOutcome.ResolvedInvalid;
            // Challenger loses stake? Redistribute to evaluators or protocol?
            // Simple: Protocol keeps the stake
             _protocolFeeBalance += amountToRedistribute;
             amountToRedistribute = 0; // Stake goes to protocol, nothing redistributed directly
        }

        challenge.resolutionTimestamp = block.timestamp;

        if (amountToRedistribute > 0 && recipient != address(0)) {
            (bool success, ) = payable(recipient).call{value: amountToRedistribute}("");
             // Log failure but don't revert the challenge state change
            if(!success) {
                 // Handle failure - e.g., send to a safe fallback or log for manual intervention
                 // For this example, we'll just require success
                 revert("Stake redistribution failed");
            }
        }


        emit ChallengeResolved(challengeId, challenge.outcome, block.timestamp, amountToRedistribute);

        // Future Improvement: More complex stake distribution, slashing logic,
        // potential on-chain flags/state changes to the challenged model based on outcome.
    }

    function getChallengeDetails(uint256 challengeId)
        external
        view
        returns (
            uint256 modelId,
            address challenger,
            uint256 stakeAmount,
            string memory detailsURI,
            uint256 initiatedTimestamp,
            ChallengeOutcome outcome,
            uint256 resolutionTimestamp,
            uint256 totalEvaluations,
            uint256 validEvaluations
        )
    {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.modelId != 0, "Challenge does not exist");
        return (
            challenge.modelId,
            challenge.challenger,
            challenge.stakeAmount,
            challenge.detailsURI,
            challenge.initiatedTimestamp,
            challenge.outcome,
            challenge.resolutionTimestamp,
            challenge.totalEvaluations,
            challenge.validEvaluations
        );
    }

    function listChallengesForModel(uint256 modelId) external view returns (uint256[] memory) {
        require(models[modelId].developer != address(0), "Model does not exist");
        return _modelChallenges[modelId];
    }

    function getChallengeEvaluationCount(uint256 challengeId) external view returns (uint256) {
        return _challengeEvaluations[challengeId].length;
    }

     function getChallengeEvaluationAtIndex(uint256 challengeId, uint256 index)
        external
        view
        returns (
            address evaluator,
            bool isValid,
            string memory proofURI,
            uint256 submittedTimestamp
        )
    {
         require(index < _challengeEvaluations[challengeId].length, "Index out of bounds");
         ChallengeEvaluation storage eval = _challengeEvaluations[challengeId][index];
         return (eval.evaluator, eval.isValid, eval.proofURI, eval.submittedTimestamp);
     }


    // --- Utility/View Functions ---

    function getOwner() external view returns (address) {
        return _owner;
    }

    function isPaused() external view returns (bool) {
        return _paused;
    }

    function getProtocolFeePercentage() external view returns (uint256) {
        return _protocolFeePercentage;
    }

    function getProtocolFeeBalance() external view returns (uint256) {
        return _protocolFeeBalance;
    }

    // Exposing the list of trusted evaluators might be gas-intensive if the list is large.
    // Returning count and individual access is better.
    // Example: getTrustedEvaluatorCount(), getTrustedEvaluatorAtIndex()
    // For simplicity here, we'll just keep the mapping lookup `isTrustedEvaluator`

    // Get all model IDs (can be gas-intensive for many models)
    // In practice, indexers would track events to build this list off-chain
    // Adding a simple counter or a limited list retrieval pattern is better for production.
    // Let's add a model counter but don't expose a full list function for gas reasons.
    function getTotalModels() external view returns (uint256) {
        return _modelCounter;
    }

    function getTotalChallenges() external view returns (uint256) {
        return _challengeCounter;
    }
}
```